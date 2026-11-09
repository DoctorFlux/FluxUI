-- Bars/Watch.lua — one dispatcher for paint lanes, range ticker + EnableActionRangeCheck.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Watch = {}
Bars.Watch = Watch

local ASSIST_KEY = "bars.assistant"
local started = false
local assistAccum = 0
local rangedSlots = {}
local rangeRegistered = false
local lastUmuAt = 0
local usableHeld = false
local cooldownHeld = false
local checkedHeld = false
local burstReleasePending = false
local burstDueAt = 0
local actionUsableMin = 0
local lastUsableAt = 0
local usableRetryPending = false
local formUsableHeld = false
local formCooldownHeld = false
local formIconHeld = false
local formCountHeld = false
local formCheckedHeld = false

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local function After(delay, fn)
	local T = Flux.Timer
	if T and T.After then
		T.After(delay, fn)
		return
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(delay, fn)
	end
end

--- Cursor unit↔gap hops. Range stamps lastMoAt; this also stamps so usable
--- handlers in the same frame do not depend on listener order.
local function InHopBurst()
	local now = (GetTime and GetTime()) or 0
	if lastUmuAt > 0 and (now - lastUmuAt) < 0.2 then
		return true
	end
	local R = Flux.Range
	return (R and R.IsHopBurst and R.IsHopBurst()) and true or false
end

--- Whole form/vehicle window, including after the burst flushed. Companion
--- SLOT_CHANGED / USABLE / ICON / CD storms must not 57-host paint here.
local function InFormWindow()
	local FS = Flux.FormStorm
	return (FS and FS.IsSettling and FS.IsSettling()) and true or false
end

local function ArmBurstRelease()
	burstDueAt = ((GetTime and GetTime()) or 0) + 0.2
	if burstReleasePending then
		return
	end
	burstReleasePending = true
	local function fire()
		local now = (GetTime and GetTime()) or 0
		if now < burstDueAt then
			After(burstDueAt - now, fire)
			return
		end
		burstReleasePending = false
		if usableHeld then
			usableHeld = false
			Bars.RequestPaint("bars.usable")
		end
		if cooldownHeld then
			cooldownHeld = false
			Bars.RequestPaint("bars.cooldown")
		end
		if checkedHeld then
			checkedHeld = false
			Bars.RequestPaint("bars.checked")
		end
	end
	After(0.2, fire)
end

-- Asked five times a second. ForEachStatic has no early exit, so this used to
-- probe all 57 surfaces even when column 1 already answered it.
local function AnyNeedsRange()
	local hosts = Bars.hosts
	local NeedsRange = Bars.Paint.NeedsRange
	for i = 1, Bars.NUM_COLUMNS do
		local col = hosts[i]
		if col then
			if (col.main and NeedsRange(col.main))
				or (col.sec and NeedsRange(col.sec))
				or (col.tert and NeedsRange(col.tert))
			then
				return true
			end
		end
	end
	return false
end

local function EnableRangeAPI()
	return C_ActionBar and C_ActionBar.EnableActionRangeCheck
end

--- Blizzard's per-slot checker re-runs on every mouseover hop when a slot
--- still has unit=mouseover (or leftover attr). Flux.Range already covers
--- display; keep EnableActionRangeCheck only for plain target-range.
local function BlizzardRangeBlocked()
	local MC = Flux.MouseoverCast
	if MC and MC.IsEnabled and MC.IsEnabled() then
		return true
	end
	local PF = Bars.ProgramFace
	if PF and PF.ProbeFlags then
		local f = PF.ProbeFlags()
		if f and f.mouseover then
			return true
		end
	end
	return false
end

function Watch.SyncRangeSlots()
	if not EnableRangeAPI() then
		return
	end
	if BlizzardRangeBlocked() then
		for slot in pairs(rangedSlots) do
			pcall(C_ActionBar.EnableActionRangeCheck, slot, false)
			rangedSlots[slot] = nil
		end
		return
	end
	local seen = {}
	Bars.ForEachHost(function(host)
		local slot = host.slot
		if slot and HasAction and HasAction(slot) then
			seen[slot] = true
			if not rangedSlots[slot] then
				pcall(C_ActionBar.EnableActionRangeCheck, slot, true)
				rangedSlots[slot] = true
			end
		end
	end)
	for slot in pairs(rangedSlots) do
		if not seen[slot] then
			pcall(C_ActionBar.EnableActionRangeCheck, slot, false)
			rangedSlots[slot] = nil
		end
	end
end

-- The strip no longer owns a range ticker. Flux.Range drives one pass for the
-- strip, Extra buttons and badges together, so a spell sitting on the main row,
-- a mini row and a badge is probed once instead of four times.
function Watch.SyncRange()
	Watch.SyncRangeSlots()
	local R = Flux.Range
	if not R then
		return
	end
	if not rangeRegistered then
		rangeRegistered = true
		R.RegisterSweep("bars", AnyNeedsRange, function()
			Bars.RequestPaint("bars.range")
		end)
		if R.Start then
			R.Start()
		end
		return
	end
	R.Sync()
end

function Watch.SetActionUsableMinInterval(sec)
	sec = tonumber(sec)
	if not sec then
		actionUsableMin = 0
		return
	end
	if sec < 0 then
		sec = 0
	elseif sec > 0.5 then
		sec = 0.5
	end
	actionUsableMin = sec
end

function Watch.IsRangeArmed()
	local R = Flux.Range
	return (R and R.IsArmed and R.IsArmed()) and true or false
end

local assistantRateTick, assistantRateManager, assistantManagerRate

-- Both strip and Extra subscribers run in the same shared ticker. Sample the
-- manager once per dispatch while retaining each consumer's paint cadence.
function Watch.GetAssistantManagerRate()
	local mgr = _G.AssistedCombatManager
	local ticker = Flux.Ticker
	local tick = ticker and ticker.Ticks and ticker.Ticks()
	if tick ~= nil and tick == assistantRateTick and mgr == assistantRateManager then
		return assistantManagerRate
	end
	assistantRateTick, assistantRateManager = tick, mgr
	assistantManagerRate = nil
	if mgr and mgr.GetUpdateRate then
		local ok, r = pcall(mgr.GetUpdateRate, mgr)
		if ok and type(r) == "number" then
			assistantManagerRate = r
		end
	end
	return assistantManagerRate
end

local function AssistantUpdateRate()
	local rate = Watch.GetAssistantManagerRate() or 0.1
	if GetCVar then
		if type(rate) ~= "number" or rate <= 0 then
			local ok, v = pcall(GetCVar, "assistedCombatIconUpdateRate")
			v = ok and tonumber(v) or nil
			if v then
				rate = v
			end
		end
	end
	if type(rate) ~= "number" or rate ~= rate or rate < 0 then
		rate = 0.1
	end
	if rate < 0.05 then
		rate = 0.05
	end
	return rate
end

local function HighlightActive()
	local A = Flux.Action
	return A and A.IsAssistedHighlightActive and A.IsAssistedHighlightActive() and true or false
end

local function AnyAssistedHost()
	local found = false
	local A = Flux.Action
	if not (A and A.IsAssistedCombat) then
		return false
	end
	Bars.ForEachHost(function(host)
		if not found and host.slot and A.IsAssistedCombat(host.slot) then
			found = true
		end
	end)
	return found
end

local function PaintAssistNow()
	local P = Bars.Paint
	if not P then
		return
	end
	if P.PaintAssistedHosts then
		P.PaintAssistedHosts()
	end
	if P.PaintAssistedHighlights then
		P.PaintAssistedHighlights()
	end
end

local function OnAssistantTick(elapsed)
	assistAccum = assistAccum + (elapsed or 0)
	if assistAccum < AssistantUpdateRate() then
		return
	end
	assistAccum = 0
	PaintAssistNow()
end

function Watch.SyncAssistantTicker()
	if not Flux.Ticker then
		return
	end
	local Cap = Flux.Cap
	local supported = Cap and Cap.ClientSupportsSingleButtonAssistant
		and Cap.ClientSupportsSingleButtonAssistant()
	if not supported or not (AnyAssistedHost() or HighlightActive()) then
		if Flux.Ticker.Remove then
			Flux.Ticker.Remove(ASSIST_KEY)
		end
		assistAccum = 0
		if Bars.Paint and Bars.Paint.PaintAssistedHighlights then
			Bars.Paint.PaintAssistedHighlights()
		end
		return
	end
	if Flux.Ticker.Add then
		Flux.Ticker.Add(ASSIST_KEY, OnAssistantTick)
	end
end

local STAMPS = { "flux-applied", "flux-applied-mods", "flux-live-sec", "flux-live-tert" }

--- Drop the CHILDUPDATE guards and the cached minirow occupancy probe for every
--- surface in a column, so the next pass is a full restamp of all three click
--- sets. OOC only: insecure SetAttribute on a protected frame is blocked in
--- combat, and slot content cannot change mid fight anyway.
function Watch.InvalidateColumnStamps(column)
	if InLockdown() then
		return
	end
	local col = column and Bars.hosts[column]
	if not col then
		return
	end
	for _, row in ipairs({ "main", "sec", "tert" }) do
		local host = col[row]
		local widget = host and host.widget
		if widget and widget.SetAttribute then
			for i = 1, #STAMPS do
				widget:SetAttribute(STAMPS[i], nil)
			end
		end
	end
end

local function RegisterMany(Ev, token, events)
	for i = 1, #events do
		Ev.Register(events[i], function()
			Bars.RequestPaint(token)
		end)
	end
end

function Watch.Start()
	if started then
		return
	end
	local Ev = Flux.Events
	if not Ev or not Ev.Register then
		return
	end
	started = true

	-- ACTIONBAR_UPDATE_COOLDOWN storms with UMU the same way usable does:
	-- mouseover-conditional slots re-emit cooldown for the new unit. Hold
	-- until the hop goes quiet so a GCD swipe is one paint, not one per hop.
	-- Form/vehicle: hold for the whole FormStorm window, release on settle.
	local function OnCooldownEvent()
		if InFormWindow() then
			formCooldownHeld = true
			return
		end
		if InHopBurst() then
			cooldownHeld = true
			ArmBurstRelease()
			return
		end
		Bars.RequestPaint("bars.cooldown")
	end
	Ev.Register("ACTIONBAR_UPDATE_COOLDOWN", OnCooldownEvent)
	Ev.Register("SPELL_UPDATE_COOLDOWN", OnCooldownEvent)
	Ev.Register("BAG_UPDATE_COOLDOWN", OnCooldownEvent)

	-- ACTIONBAR_UPDATE_USABLE storms on every world hop when any slot still
	-- looks like a mouseover-conditional action. Do not 57-host Paint.Flush.
	local function OnUsableEvent()
		if InFormWindow() then
			formUsableHeld = true
			return
		end
		if InHopBurst() then
			usableHeld = true
			ArmBurstRelease()
			return
		end
		if actionUsableMin > 0 then
			local now = (GetTime and GetTime()) or 0
			if lastUsableAt > 0 and (now - lastUsableAt) < actionUsableMin then
				if not usableRetryPending then
					usableRetryPending = true
					After(actionUsableMin - (now - lastUsableAt), function()
						usableRetryPending = false
						lastUsableAt = (GetTime and GetTime()) or 0
						Bars.RequestPaint("bars.usable")
					end)
				end
				return
			end
			lastUsableAt = now
		end
		Bars.RequestPaint("bars.usable")
	end
	Ev.Register("ACTIONBAR_UPDATE_USABLE", OnUsableEvent)
	Ev.Register("SPELL_UPDATE_USABLE", OnUsableEvent)
	Ev.Register("PLAYER_CONTROL_LOST", function()
		if InFormWindow() then
			formUsableHeld = true
			return
		end
		Bars.RequestPaint("bars.usable")
	end)
	Ev.Register("PLAYER_CONTROL_GAINED", function()
		if InFormWindow() then
			formUsableHeld = true
			return
		end
		Bars.RequestPaint("bars.usable")
	end)

	-- [harm]/[help] macros re-emit ACTIONBAR_UPDATE_STATE on every world hop.
	local function OnCheckedEvent()
		if InFormWindow() then
			formCheckedHeld = true
			return
		end
		if InHopBurst() then
			checkedHeld = true
			ArmBurstRelease()
			return
		end
		Bars.RequestPaint("bars.checked")
	end
	Ev.Register("ACTIONBAR_UPDATE_STATE", OnCheckedEvent)
	Ev.Register("CURRENT_SPELL_CAST_CHANGED", OnCheckedEvent)
	Ev.Register("START_AUTOREPEAT_SPELL", OnCheckedEvent)
	Ev.Register("STOP_AUTOREPEAT_SPELL", OnCheckedEvent)
	Ev.Register("TRADE_SKILL_SHOW", OnCheckedEvent)
	Ev.Register("TRADE_SKILL_CLOSE", OnCheckedEvent)
	Ev.Register("PLAYER_ENTER_COMBAT", OnCheckedEvent)
	Ev.Register("PLAYER_LEAVE_COMBAT", OnCheckedEvent)
	Ev.Register("PLAYER_MOUNT_DISPLAY_CHANGED", OnCheckedEvent)

	-- Overlay [mod]/[form]/[combat] faces: one coalesced cond pass, then paint.
	local function RequestCond(kind)
		local PF = Bars.ProgramFace
		if PF and PF.Request then
			PF.Request(kind or "all")
		elseif PF and PF.RequestConditionalRefresh then
			PF.RequestConditionalRefresh()
		elseif PF and PF.TranslateAll then
			PF.TranslateAll()
		end
	end

	local function ContextOwnsDisplay()
		local C = Flux.Context
		return C and C.HasSubscribers and C.HasSubscribers() and true or false
	end

	-- Extra Watch used to be the only [combat]/[harm]/[@mouseover] fan-out.
	-- The strip must not depend on Extra window macros being registered.
	-- When Context is subscribed, hops ride the display bus — not eval.
	Ev.Register("PLAYER_TARGET_CHANGED", function()
		if ContextOwnsDisplay() then
			return
		end
		local PF = Bars.ProgramFace
		if PF and PF.RequestTarget then
			PF.RequestTarget()
		else
			RequestCond("target")
		end
	end)
	Ev.Register("PLAYER_FOCUS_CHANGED", function()
		if ContextOwnsDisplay() then
			return
		end
		RequestCond("target")
	end)
	-- Cond translate only when a body has @mouseover. Range is Flux.Range (70ms).
	-- Extra Watch does not own UMU: this is the single cond listener.
	Ev.Register("UPDATE_MOUSEOVER_UNIT", function()
		lastUmuAt = (GetTime and GetTime()) or 0
		local C = Flux.Context
		if C and C.HasSubscribers and C.HasSubscribers() then
			return
		end
		local PF = Bars.ProgramFace
		if PF and PF.NoteMouseoverEvent then
			PF.NoteMouseoverEvent()
		end
	end)
	-- Combat edges are picked up by the single regen handler further down; the
	-- bus runs every registration, so a second one here doubled the work.
	Ev.Register("PLAYER_UPDATE_RESTING", function()
		RequestCond("combat")
	end)
	Ev.Register("GROUP_ROSTER_UPDATE", function()
		RequestCond("combat")
	end)
	Ev.Register("PLAYER_MOUNT_DISPLAY_CHANGED", function()
		RequestCond("combat")
	end)
	local function OnUnitConditional(_, unit)
		-- mouseover is owned by the UMU coalescer. UNIT_FACTION/FLAGS/TARGET
		-- fire on every hover hop and must not escalate to a [harm] parse.
		if InHopBurst() then
			return
		end
		if ContextOwnsDisplay() then
			return
		end
		if unit == "player" or unit == "target" or unit == "focus" or unit == "pet" then
			RequestCond("target")
		end
	end
	Ev.Register("UNIT_FLAGS", OnUnitConditional)
	Ev.Register("UNIT_FACTION", OnUnitConditional)
	Ev.Register("UNIT_TARGET", OnUnitConditional)

	local function SyncNativeHostSlots()
		local State = Bars.State
		if not (State and State.GetCurrentPage and State.GetMainSlot) then
			return
		end
		local page = State.GetCurrentPage()
		local hosts = Bars.hosts
		for col = 1, Bars.NUM_NATIVE do
			local hostRecord = hosts[col]
			local mainHost = hostRecord and hostRecord.main
			if mainHost and (not mainHost._fluxPromoted or page >= 11) then
				local newSlot = State.GetMainSlot(col, page)
				local moved = newSlot and newSlot ~= mainHost.slot
				if moved then
					Bars.Hosts.IndexSlot(mainHost, newSlot)
					local SP = Bars.SlotProgram
					if SP and SP.ApplyLiveType then
						SP.ApplyLiveType(mainHost)
					end
				end
				-- Always dirty the 12 paged mains. OnAttributeChanged may have
				-- IndexSlot already (moved=false) while host._icon is still the
				-- previous form. Flush UpdateAlls dirty hosts only — not all 57.
				if Bars.Paint and Bars.Paint.Dirty then
					Bars.Paint.Dirty(mainHost)
				end
			end
		end
	end

	-- Form / bonus bar / page all arrive together. FormStorm collapses them to
	-- one burst, so this runs once per shift instead of three to five times.
	-- Flush UpdateAlls dirty hosts (icon/usable/cd/checked); not all 57.
	local function OnPageOrForm()
		local State = Bars.State
		if not (State and State.UsesSecurePaging and State.UsesSecurePaging()) then
			local State = Bars.State
			if State and State.ApplySlotsInsecure then
				State.ApplySlotsInsecure()
			end
		else
			SyncNativeHostSlots()
		end
		-- Overlay [form] faces must parse on the burst, not 0.25s settle.
		-- FormStorm already proved the form changed; do not force-refresh.
		local C = Flux.Context
		if ContextOwnsDisplay() and C and C.Request then
			C.Request(false, { form = true })
		else
			RequestCond("form")
		end
		-- The one real badge-vis pass per storm; every later caller dedupes.
		local BadgeHost = Bars.BadgeHost or _G.FluxBadgeHost
		if BadgeHost and BadgeHost.RefreshFormVisibility then
			BadgeHost.RefreshFormVisibility()
		end
		-- Promotion is any-state: a form cannot change the occupancy hash.
		-- UpdateAll on dirty hosts covers icon/checked/usable/cd; do not
		-- schedule a second strip paint on the next frame.
		Bars.RequestPaint("bars.dirty")
		Bars.RequestPaint("bars.icon")
		Bars.RequestPaint("bars.checked")
	end

	local FormStorm = Flux.FormStorm
	if FormStorm and FormStorm.OnBurst then
		FormStorm.OnBurst("bars.page", OnPageOrForm)
		-- Trailing pass: only when something landed after the burst flushed.
		-- Quiet settle: the burst already ran cond + paints + badge vis.
		FormStorm.OnSettled("bars.page", function(quiet)
			Watch.SyncRange()
			local needCount = formCountHeld
			local needUsable = formUsableHeld
			local needCooldown = formCooldownHeld
			local needIcon = formIconHeld
			local needChecked = formCheckedHeld
			formUsableHeld = false
			formCooldownHeld = false
			formIconHeld = false
			formCountHeld = false
			formCheckedHeld = false
			-- Companion events can land after the burst paint without opening
			-- another form edge. Replay only the held lanes, even on a quiet
			-- settle, so unrelated static slots do not retain stale values.
			if needCount then
				Bars.RequestPaint("bars.count")
			end
			if needUsable then
				Bars.RequestPaint("bars.usable")
			end
			if needCooldown then
				Bars.RequestPaint("bars.cooldown")
			end
			if needIcon then
				Bars.RequestPaint("bars.icon")
			end
			if needChecked then
				Bars.RequestPaint("bars.checked")
			end
			if quiet then
				return
			end
			local C = Flux.Context
			if ContextOwnsDisplay() and C and C.Request then
				C.Request(false, { form = true })
			else
				RequestCond("form")
			end
			local BadgeHost = Bars.BadgeHost or _G.FluxBadgeHost
			if BadgeHost and BadgeHost.RefreshFormVisibility then
				BadgeHost.RefreshFormVisibility()
			end
		end)
	else
		Ev.Register("ACTIONBAR_PAGE_CHANGED", OnPageOrForm)
		Ev.Register("UPDATE_BONUS_ACTIONBAR", OnPageOrForm)
		Ev.Register("UPDATE_SHAPESHIFT_FORM", OnPageOrForm)
		Ev.Register("UPDATE_STEALTH", OnPageOrForm)
	end

	Ev.Register("SPELL_UPDATE_CHARGES", function()
		if InFormWindow() then
			formUsableHeld = true
			formCooldownHeld = true
			formCountHeld = true
			return
		end
		Bars.RequestPaint("bars.count")
		Bars.RequestPaint("bars.cooldown")
		Bars.RequestPaint("bars.usable")
	end)

	local function OnIconEvent()
		if InFormWindow() then
			formIconHeld = true
			return
		end
		Bars.RequestPaint("bars.icon")
	end
	Ev.Register("CURRENT_SPELL_CAST_CHANGED", OnIconEvent)
	Ev.Register("SPELL_UPDATE_ICON", OnIconEvent)
	Ev.Register("SPELLS_CHANGED", OnIconEvent)
	Ev.Register("UPDATE_MACROS", function()
		local PF = Bars.ProgramFace
		if PF and PF.InvalidateIndex then
			PF.InvalidateIndex()
		end
		Bars.RequestPaint("bars.icon")
		RequestCond("all")
	end)

	RegisterMany(Ev, "bars.equipped", {
		"PLAYER_EQUIPMENT_CHANGED",
	})

	-- ACTION_RANGE_CHECK_UPDATE is owned by Flux.Range, which invalidates the
	-- shared memo before fanning out to every surface's sweep.

	-- Blizzard sends one ACTIONBAR_SLOT_CHANGED per slot, so a form change
	-- delivers a dozen. Answering each one separately meant a dozen 57-host
	-- range scans and assistant probes in a single frame. Collect the slots,
	-- sync range and the assistant ticker once.
	local slotDirty = {}
	local slotAll = false
	local slotQueued = false

	local function FlushSlotChanged()
		slotQueued = false
		local all = slotAll
		slotAll = false
		local touched = {}
		for slot in pairs(slotDirty) do
			touched[#touched + 1] = slot
			slotDirty[slot] = nil
		end
		local hopping = InHopBurst()
		-- slot=0 during a nameplate sweep is a texture storm, not a bar rewrite.
		if hopping and all then
			all = false
			if #touched == 0 then
				if _G.FluxActionBarConsumeAllOccupancyDirty then
					_G.FluxActionBarConsumeAllOccupancyDirty()
				end
				return
			end
		end
		-- Mouseover-conditional macros re-fire one SLOT_CHANGED per slot per hop.
		-- Occupancy peek: identity unchanged → do not Dirty/Layout/cond/paint.
		-- occupancyDirty survives Extra's earlier peek + After(0) wave wipe.
		local peek = _G.FluxActionBarPeekSlotOccupancyChanged
		local consume = _G.FluxActionBarConsumeOccupancyDirty
		local consumeAll = _G.FluxActionBarConsumeAllOccupancyDirty
		local function consumeTouched()
			if consumeAll and all then
				consumeAll()
				return
			end
			if not consume then
				return
			end
			for i = 1, #touched do
				consume(touched[i])
			end
		end
		if not all then
			local changed = {}
			local same = {}
			for i = 1, #touched do
				local slot = touched[i]
				if not peek or peek(slot) then
					changed[#changed + 1] = slot
				else
					same[#same + 1] = slot
				end
			end
			-- Identity unchanged (healthstone create, stack 1→2) still needs
			-- the digit. Not a Dirty/layout/Binding pass, and not during a
			-- hop or form storm.
			if #same > 0 and not hopping then
				local storm = Flux.FormStorm
				local forming = storm and ((storm.IsBursting and storm.IsBursting()) or (storm.IsSettling and storm.IsSettling()))
				if not forming and Bars.Paint and Bars.Hosts and Bars.Hosts.ForSlot then
					for i = 1, #same do
						local list = Bars.Hosts.ForSlot(same[i])
						if list then
							for h = 1, #list do
								local host = list[h]
								if Bars.Paint.UpdateCount then
									Bars.Paint.UpdateCount(host)
								end
								if Bars.Paint.UpdateUsable then
									Bars.Paint.UpdateUsable(host)
								end
							end
						end
					end
				end
			end
			if #changed == 0 then
				return
			end
			touched = changed
		end
		local occAll = all
		if not occAll then
			for i = 1, #touched do
				local list = Bars.Hosts and Bars.Hosts.ForSlot and Bars.Hosts.ForSlot(touched[i])
				if list and #list > 0 then
					for h = 1, #list do
						if Bars.Paint.Dirty then
							Bars.Paint.Dirty(list[h])
						else
							Bars.Paint.ClearCache(list[h])
						end
						-- Whole column, not just the indexed host: a main-row
						-- host caches its column's minirow occupancy, and while
						-- no modifier is held it is not indexed at the mini slot
						-- that just changed. A slot whose content changed needs
						-- the next ChildUpdate to redo overlay type and empower
						-- rather than early-out on an unchanged slot number.
						Watch.InvalidateColumnStamps(list[h].column)
					end
				else
					occAll = true
				end
			end
		end
		-- Occupancy change already Paint.Dirty'd the hosts. A bars.icon lane
		-- here walked every live surface on each hop. Layout / cond / Apply
		-- are the hitch; Dirty is enough for the new face.
		if hopping then
			consumeTouched()
			return
		end
		local FS = Flux.FormStorm
		if FS and ((FS.IsBursting and FS.IsBursting()) or (FS.IsSettling and FS.IsSettling())) then
			consumeTouched()
			return
		end
		if occAll then
			Bars.RequestPaint("bars")
		end
		if Bars.Layout and Bars.Layout.Request then
			Bars.Layout.Request("slot")
		end
		Watch.SyncRange()
		Watch.SyncAssistantTicker()
		Bars.RequestPaint("bars.icon")
		local FB = _G.FluxBinding
		local BadgeHost = Bars.BadgeHost or _G.FluxBadgeHost
		if occAll then
			if FB and FB.NotifyBarSlotsChanged then
				FB.NotifyBarSlotsChanged()
			end
		else
			for i = 1, #touched do
				local slot = touched[i]
				if BadgeHost and BadgeHost.RefreshOccupancyVisibility then
					BadgeHost.RefreshOccupancyVisibility(slot)
				end
			end
			if FB and FB.NotifyOccupancyChanged then
				FB.NotifyOccupancyChanged(touched)
			elseif FB and FB.NotifyBarSlotChanged then
				for i = 1, #touched do
					FB.NotifyBarSlotChanged(touched[i])
				end
			end
		end
		consumeTouched()
	end

	Ev.Register("ACTIONBAR_SLOT_CHANGED", function(_, slot)
		local n = tonumber(slot)
		if n and n ~= 0 then
			slotDirty[n] = true
		else
			slotAll = true
		end
		if not slotQueued then
			slotQueued = true
			Flux.Timer.Defer(FlushSlotChanged)
		end
	end)

	Ev.Register("MODIFIER_STATE_CHANGED", function()
		-- Combat: index host.slot for paint / VFX / badges. Clicks already
		-- resolve against the pre-stamped nomod / shift- / ctrl- sets.
		-- Never RequestLayout (holding a modifier must not restamp).
		local State = Bars.State
		if State then
			if InLockdown() then
				if State.IndexLiveSlots then
					State.IndexLiveSlots()
				end
			else
				if not (State.UsesSecurePaging and State.UsesSecurePaging()) then
					if State.ApplySlotsInsecure then
						State.ApplySlotsInsecure()
					end
				end
			end
		end
		-- Re-parse only when some overlay/Extra/slot-macro body has [mod].
		-- ButtonForge: the event only sets RefConditional. Do not 6-lane
		-- every host — TranslateHost FullRefreshs only a changed face.
		-- Hotkey still needs S-/C- on the main row; swapped hosts Dirty
		-- themselves from OnAttributeChanged.
		-- Context owns [mod] display. NotifyModifierPaging here defers a
		-- 57-host walk that then skips the post-translate pass.
		if not ContextOwnsDisplay() then
			RequestCond("mod")
			local BadgeHost = Bars.BadgeHost or _G.FluxBadgeHost
			if BadgeHost and BadgeHost.NotifyModifierPaging then
				BadgeHost.NotifyModifierPaging()
			end
		end
		-- Swapped hosts MarkDirty without RequestPaint so this one eval
		-- merges with Context display in the same scheduler flush.
		Bars.RequestPaint("bars.dirty")
		Bars.RequestPaint("bars.hotkey")
		Bars.RequestPaint("bars.count")
		Bars.RequestPaint("bars.cooldown")
	end)

	Ev.Register("UPDATE_BINDINGS", function()
		if Bars.Clicks and Bars.Clicks.InvalidateKeys then
			Bars.Clicks.InvalidateKeys()
		elseif Bars.Hosts and Bars.Hosts.InvalidateKeys then
			Bars.Hosts.InvalidateKeys()
		end
		Bars.RequestPaint("bars.hotkey")
		if InLockdown() then
			Flux.Combat.Defer("bars.keys", function()
				if Bars.Clicks and Bars.Clicks.RefreshKeys then
					Bars.Clicks.RefreshKeys()
				else
					Bars.Hosts.RefreshKeys()
				end
			end)
			return
		end
		if Bars.Clicks and Bars.Clicks.RefreshKeys then
			Bars.Clicks.RefreshKeys()
		else
			Bars.Hosts.RefreshKeys()
		end
	end)

	-- Vehicle/override enter: Bars.Vehicle owns the deferred apply (strip,
	-- leftover, OOC ForceApply, paints). Do not Sweep collectors here —
	-- writing ActionBarButtonEventsFrame.frames in combat taints OverrideActionBar
	-- Update → SetAttribute. RightManagedFrameContainer:SetSize also rides
	-- Sweep/Show on the vehicle event itself.

	Ev.Register("PLAYER_ENTERING_WORLD", function()
		if Bars.State and Bars.State.ForceApply then
			if InLockdown() then
				Flux.Combat.Defer("bars.state", Bars.State.ForceApply)
			else
				Bars.State.ForceApply()
			end
		end
		if Bars.Clicks and Bars.Clicks.ReassertEmpower then
			if InLockdown() then
				Flux.Combat.Defer("bars.empower", Bars.Clicks.ReassertEmpower)
			else
				Bars.Clicks.ReassertEmpower()
			end
		end
		Bars.RequestLayout("entering_world")
		Watch.SyncRange()
		Watch.SyncAssistantTicker()
		PaintAssistNow()
	end)

	local function OnAssistantCast(event, unit, _, spellId)
		if unit and unit ~= "player" then
			return
		end
		PaintAssistNow()
		if event == "UNIT_SPELLCAST_SUCCEEDED" and Bars.Paint and Bars.Paint.NotePlayerCast then
			Bars.Paint.NotePlayerCast(spellId)
		end
	end
	Ev.Register("UNIT_SPELLCAST_SUCCEEDED", OnAssistantCast)
	Ev.Register("UNIT_SPELLCAST_STOP", OnAssistantCast)
	Ev.Register("UNIT_SPELLCAST_INTERRUPTED", OnAssistantCast)

	local function OnAssistantRegen()
		if Flux.Action and Flux.Action.SweepFluxFromCollectors then
			Flux.Action.SweepFluxFromCollectors()
		end
		Watch.SyncAssistantTicker()
		PaintAssistNow()
	end
	Ev.Register("PLAYER_REGEN_DISABLED", function()
		RequestCond("combat")
		OnAssistantRegen()
	end)

	Ev.Register("PLAYER_REGEN_ENABLED", function()
		RequestCond("combat")
		if Bars.Strip.ApplyGamepadHud then
			Bars.Strip.ApplyGamepadHud()
		else
			Bars.Strip.SyncVisibility()
		end
		OnAssistantRegen()
	end)

	local registry = _G.EventRegistry
	if registry and registry.RegisterCallback then
		pcall(registry.RegisterCallback, registry, "AssistedCombatManager.OnSetActionSpell", function()
			Watch.SyncAssistantTicker()
			PaintAssistNow()
		end, Watch)
		pcall(registry.RegisterCallback, registry, "AssistedCombatManager.RotationSpellsUpdated", function()
			Watch.SyncAssistantTicker()
			PaintAssistNow()
		end, Watch)
		pcall(registry.RegisterCallback, registry, "AssistedCombatManager.OnAssistedHighlightSpellChange", function()
			Watch.SyncAssistantTicker()
			PaintAssistNow()
		end, Watch)
		pcall(registry.RegisterCallback, registry, "AssistedCombatManager.OnSetUseAssistedHighlight", function()
			Watch.SyncAssistantTicker()
			PaintAssistNow()
		end, Watch)
	end

	if Flux.Inventory and Flux.Inventory.Register then
		Flux.Inventory.Register("bars", function(ctx)
			local regions = ctx and ctx.regions
			if regions and not regions.bags and not regions.equipped then
				return
			end
			Bars.RequestPaint("bars.count")
			Bars.RequestPaint("bars.usable")
			Bars.RequestPaint("bars.equipped")
		end, {
			tier = "scan",
			regions = { "bags", "equip" },
			-- 0→1 is identityChanged. deferHeavy would queue that first digit
			-- behind the heavy debounce. Count text stays on the bag frame.
			sync = true,
		})
	end

	if Bars.Effects and Bars.Effects.Start then
		Bars.Effects.Start()
	end
	Watch.SyncRange()
	Watch.SyncAssistantTicker()
end
