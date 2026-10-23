-- ExtraButtonSystem/Engine/Watch.lua — events → dirty lanes (ButtonForge cadence)
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS

local Watch = {}
EBS.Watch = Watch

local started = false
local ASSIST_KEY = "ebs.assistant"
local assistAccum = 0
local hopCheckedHeld = false
local armHopRelease

local function RequestEval(token)
	if Flux.Scheduler and Flux.Scheduler.Request then
		Flux.Scheduler.Request("eval", token or "ebs")
	end
end

local function RequestLanes(...)
	local n = select("#", ...)
	for i = 1, n do
		local token = select(i, ...)
		if token == "ebs.checked" then
			if EBS.Paint and EBS.Paint.RequestChecked then
				EBS.Paint.RequestChecked()
			else
				RequestEval(token)
			end
		elseif token == "ebs.icon" then
			if EBS.Paint and EBS.Paint.RequestIcon then
				EBS.Paint.RequestIcon()
			else
				RequestEval(token)
			end
		else
			RequestEval(token)
		end
	end
end

-- Cooldowns used to own a private OnUpdate because a coalesced eval could be
-- dropped behind a layout pass. The scheduler now defers eval past layout
-- instead of dropping it, so a cooldown event is one flush with the other
-- lanes rather than a second full walk of EBS.buttons in the same frame.
local function RequestCooldown()
	RequestEval("ebs.cooldown")
end

local function OnCVar(_, cvarName)
	if cvarName == "ActionButtonUseKeyDown" or cvarName == "empowerTapControls" then
		if EBS.Widget and EBS.Widget.SyncCVars then
			if Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown() then
				Flux.Combat.Defer("ebs.cvar", EBS.Widget.SyncCVars)
			else
				EBS.Widget.SyncCVars()
			end
		end
	end
end

	local function RequestChecked()
		local R = Flux.Range
		if R and R.IsHopBurst and R.IsHopBurst() then
			hopCheckedHeld = true
			if armHopRelease then
				armHopRelease()
			end
			return
		end
		local FS = Flux.FormStorm
		if FS and FS.IsSettling and FS.IsSettling() then
			return
		end
		if EBS.Paint and EBS.Paint.RequestChecked then
			EBS.Paint.RequestChecked()
		else
			RequestEval("ebs.checked")
		end
	end

local function RequestCheckedSettle()
	if EBS.Paint and EBS.Paint.RequestCheckedSettle then
		EBS.Paint.RequestCheckedSettle()
	else
		RequestChecked()
	end
end

	local function RequestIcon()
		if EBS.Paint and EBS.Paint.RequestIcon then
			EBS.Paint.RequestIcon()
		else
			RequestEval("ebs.icon")
		end
	end

local function RegisterMany(Ev, token, events)
	for i = 1, #events do
		Ev.Register(events[i], function()
			if token == "ebs.checked" then
				RequestChecked()
			elseif token == "ebs.icon" then
				RequestIcon()
			else
				RequestEval(token)
			end
		end)
	end
end

local function AnyAssistant()
	local list = EBS.buttons
	if not list then
		return false
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.IsAssistedCombat then
			return true
		end
	end
	return false
end

local function AssistantUpdateRate()
	local barWatch = Flux.Bars and Flux.Bars.Watch
	if barWatch and barWatch.GetAssistantManagerRate then
		local rate = barWatch.GetAssistantManagerRate()
		if type(rate) == "number" then
			return math.max(0.05, rate)
		end
	else
		local mgr = _G.AssistedCombatManager
		if mgr and mgr.GetUpdateRate then
			local ok, rate = pcall(mgr.GetUpdateRate, mgr)
			if ok and type(rate) == "number" then
				if rate < 0.05 then
					return 0.05
				end
				return rate
			end
		end
	end
	if GetCVar then
		local ok, v = pcall(GetCVar, "assistedCombatIconUpdateRate")
		v = ok and tonumber(v) or nil
		if v then
			if v < 0.05 then
				return 0.05
			end
			return v
		end
	end
	return 0.1
end

local function OnAssistantTick(elapsed)
	assistAccum = assistAccum + (elapsed or 0)
	local rate = AssistantUpdateRate()
	if assistAccum < rate then
		return
	end
	assistAccum = 0
	if EBS.Action and EBS.Action.PaintAssistantButtons then
		EBS.Action.PaintAssistantButtons()
	else
		RequestEval("ebs")
	end
end

function Watch.SyncAssistantTicker()
	if not Flux.Ticker then
		return
	end
	local Cap = Flux.Cap
	local supported = Cap and Cap.ClientSupportsSingleButtonAssistant
		and Cap.ClientSupportsSingleButtonAssistant()
	if not supported or not AnyAssistant() then
		if Flux.Ticker.Remove then
			Flux.Ticker.Remove(ASSIST_KEY)
		end
		assistAccum = 0
		return
	end
	if Flux.Ticker.Add then
		Flux.Ticker.Add(ASSIST_KEY, OnAssistantTick)
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

	local function AnyMacros()
		local list = EBS.buttons
		if not list then
			return false
		end
		for i = 1, #list do
			local btn = list[i]
			if btn and (btn.ActionType == "macro" or btn.ActionType == "macrotext") then
				return true
			end
		end
		return false
	end

	local function RefreshMacros()
		if AnyMacros() then
			if EBS.Action and EBS.Action.RequestMacroDisplay then
				EBS.Action.RequestMacroDisplay()
			elseif EBS.Action and EBS.Action.RefreshMacroDisplay then
				EBS.Action.RefreshMacroDisplay()
			end
		end
	end

	local function RequestCond(kind)
		local PF = Flux.Bars and Flux.Bars.ProgramFace
		if PF and PF.Request then
			PF.Request(kind or "all")
			return
		end
		RefreshMacros()
	end

	local function ContextOwnsDisplay()
		local C = Flux.Context
		return C and C.HasSubscribers and C.HasSubscribers() and true or false
	end

	local function InHopBurst()
		local R = Flux.Range
		return (R and R.IsHopBurst and R.IsHopBurst()) and true or false
	end

	local function InFormWindow()
		local FS = Flux.FormStorm
		return (FS and FS.IsSettling and FS.IsSettling()) and true or false
	end

	local usableHeld = false
	local cooldownHeld = false
	local formUsableHeld = false
	local formCooldownHeld = false
	local formIconHeld = false
	local formCountHeld = false
	local burstReleasePending = false
	local burstDueAt = 0
	local function ArmUsableRelease()
		burstDueAt = ((GetTime and GetTime()) or 0) + 0.2
		if burstReleasePending then
			return
		end
		burstReleasePending = true
		local function fire()
			local now = (GetTime and GetTime()) or 0
			if now < burstDueAt then
				if C_Timer and C_Timer.After then
					C_Timer.After(burstDueAt - now, fire)
				end
				return
			end
			burstReleasePending = false
			if usableHeld then
				usableHeld = false
				RequestEval("ebs.usable")
			end
			if cooldownHeld then
				cooldownHeld = false
				RequestCooldown()
			end
			if hopCheckedHeld then
				hopCheckedHeld = false
				if EBS.Paint and EBS.Paint.RequestChecked then
					EBS.Paint.RequestChecked()
				else
					RequestEval("ebs.checked")
				end
			end
		end
		if C_Timer and C_Timer.After then
			C_Timer.After(0.2, fire)
		end
	end
	armHopRelease = ArmUsableRelease

	local function OnUsableEvent()
		if InFormWindow() then
			formUsableHeld = true
			return
		end
		if InHopBurst() then
			usableHeld = true
			ArmUsableRelease()
			return
		end
		RequestEval("ebs.usable")
	end
	Ev.Register("ACTIONBAR_UPDATE_USABLE", OnUsableEvent)
	Ev.Register("SPELL_UPDATE_USABLE", OnUsableEvent)
	RegisterMany(Ev, "ebs.usable", {
		"MOUNT_JOURNAL_USABILITY_CHANGED",
	})
	local function OnControlUsable()
		if InFormWindow() then
			formUsableHeld = true
			return
		end
		RequestEval("ebs.usable")
	end
	Ev.Register("PLAYER_CONTROL_LOST", OnControlUsable)
	Ev.Register("PLAYER_CONTROL_GAINED", OnControlUsable)
	Ev.Register("VEHICLE_UPDATE", function()
		if InFormWindow() then
			formUsableHeld = true
			return
		end
		RequestEval("ebs.usable")
	end)
	-- Vehicle / override edges also open a FormStorm burst whose OnForm below
	-- already requests ebs.usable, so a direct registration here dispatched
	-- the same event twice. Keep the direct lane only without FormStorm.
	if not (Flux.FormStorm and Flux.FormStorm.OnBurst) then
		RegisterMany(Ev, "ebs.usable", {
			"UPDATE_OVERRIDE_ACTIONBAR",
			"UPDATE_VEHICLE_ACTIONBAR",
		})
	end

	-- The event bus appends handlers, so registering the same event from two
	-- places runs both. Zone edges drive the usable lane and the [indoors]
	-- conditional bucket, so they take one handler that asks for both.
	local function OnZoneEdge()
		RequestEval("ebs.usable")
		RequestCond("combat")
	end
	Ev.Register("MINIMAP_UPDATE_ZOOM", OnZoneEdge)
	Ev.Register("ZONE_CHANGED", OnZoneEdge)
	Ev.Register("ZONE_CHANGED_INDOORS", OnZoneEdge)
	Ev.Register("ZONE_CHANGED_NEW_AREA", OnZoneEdge)

	-- Mouseover hops re-emit ACTIONBAR_UPDATE_COOLDOWN for conditional slots.
	-- Hold until the hop goes quiet so a GCD swipe is one paint, not one per hop.
	local function OnCooldownEvent()
		if InFormWindow() then
			formCooldownHeld = true
			return
		end
		if InHopBurst() then
			cooldownHeld = true
			ArmUsableRelease()
			return
		end
		RequestCooldown()
	end
	Ev.Register("SPELL_UPDATE_COOLDOWN", OnCooldownEvent)
	Ev.Register("ACTIONBAR_UPDATE_COOLDOWN", OnCooldownEvent)
	Ev.Register("BAG_UPDATE_COOLDOWN", OnCooldownEvent)
	Ev.Register("UPDATE_SHAPESHIFT_COOLDOWN", OnCooldownEvent)

	-- Page / override / vehicle arrive as part of the form burst and are
	-- handled once by the FormStorm subscription below.
	RegisterMany(Ev, "ebs.checked", {
		"ACTIONBAR_UPDATE_STATE",
		"TRADE_SKILL_SHOW",
		"TRADE_SKILL_CLOSE",
		"PLAYER_ENTER_COMBAT",
		"PLAYER_LEAVE_COMBAT",
	})

	local function OnCheckedSettle()
		if InFormWindow() then
			formIconHeld = true
			return
		end
		RequestCheckedSettle()
		RequestIcon()
	end
	Ev.Register("CURRENT_SPELL_CAST_CHANGED", function()
		if InFormWindow() then
			formIconHeld = true
			return
		end
		OnCheckedSettle()
		RequestCond("combat")
	end)
	Ev.Register("PLAYER_MOUNT_DISPLAY_CHANGED", function()
		if InFormWindow() then
			return
		end
		OnCheckedSettle()
		RequestCond("combat")
	end)
	Ev.Register("START_AUTOREPEAT_SPELL", OnCheckedSettle)
	Ev.Register("STOP_AUTOREPEAT_SPELL", OnCheckedSettle)
	Ev.Register("PET_BATTLE_PET_CHANGED", OnCheckedSettle)

	-- SUCCEEDED also settles cooldowns and the assistant face. One handler, so
	-- a cast edge does not walk EBS.buttons twice.
	local function OnPlayerCastEnd(event, unit, _, spellId)
		if InFormWindow() then
			formIconHeld = true
			formCooldownHeld = true
			if EBS.Paint and EBS.Paint.NotePlayerCast then
				EBS.Paint.NotePlayerCast(spellId)
			end
			return
		end
		OnCheckedSettle()
		RequestCooldown()
		if EBS.Action and EBS.Action.PaintAssistantButtons then
			EBS.Action.PaintAssistantButtons()
		end
		if EBS.Paint and EBS.Paint.NotePlayerCast then
			EBS.Paint.NotePlayerCast(spellId)
		end
	end
	if Ev.RegisterUnit then
		Ev.RegisterUnit("UNIT_SPELLCAST_SUCCEEDED", "player", OnPlayerCastEnd)
		Ev.RegisterUnit("UNIT_SPELLCAST_STOP", "player", OnCheckedSettle)
		Ev.RegisterUnit("UNIT_SPELLCAST_INTERRUPTED", "player", OnCheckedSettle)
	else
		local function OnPlayerCast(_, unit)
			if unit and unit ~= "player" then
				return
			end
			OnCheckedSettle()
		end
		Ev.Register("UNIT_SPELLCAST_SUCCEEDED", function(event, unit, castGUID, spellId)
			if unit and unit ~= "player" then
				return
			end
			OnPlayerCastEnd(event, unit, castGUID, spellId)
		end)
		Ev.Register("UNIT_SPELLCAST_STOP", OnPlayerCast)
		Ev.Register("UNIT_SPELLCAST_INTERRUPTED", OnPlayerCast)
	end

	Ev.Register("SPELL_UPDATE_ICON", function()
		if InFormWindow() then
			formIconHeld = true
			return
		end
		if EBS.Paint and EBS.Paint.InvalidateSpellCaches then
			EBS.Paint.InvalidateSpellCaches()
		end
		RequestIcon()
		RefreshMacros()
	end)

	Ev.Register("SPELL_UPDATE_CHARGES", function()
		if InFormWindow() then
			formUsableHeld = true
			formCooldownHeld = true
			formCountHeld = true
			return
		end
		RequestEval("ebs.count")
		RequestCooldown()
		RequestEval("ebs.usable")
	end)

	Ev.Register("PLAYER_EQUIPMENT_CHANGED", function()
		RequestEval("ebs.equipped")
		RequestCond("all")
	end)

	local function OnLife()
		RequestLanes("ebs.usable", "ebs.checked")
		RequestCond("all")
	end
	Ev.Register("PLAYER_DEAD", OnLife)
	Ev.Register("PLAYER_ALIVE", OnLife)
	Ev.Register("PLAYER_UNGHOST", OnLife)

	Ev.Register("UPDATE_MACROS", function()
		if EBS.Action and EBS.Action.OnMacrosUpdated then
			EBS.Action.OnMacrosUpdated()
		end
	end)

	-- A form change can swap a face without SPELLS_CHANGED (the stance wisp),
	-- so drop the live-face cache — but not the flyout cache. Do not walk
	-- every extra button: combat food / teleport icons cannot change on Bear.
	-- Form-conditional macros reparse via Context/TranslateMatching; shapeshift
	-- extras get a visual pass. Held USABLE/ICON/CD flush once on settle.
	local function PaintFormSensitiveExtras()
		local Paint = EBS.Paint
		if not Paint then
			return
		end
		local PF = Flux.Bars and Flux.Bars.ProgramFace
		if PF and PF.Needs and PF.Needs("form") and PF.EachExtraMatching then
			PF.EachExtraMatching({ form = true }, function(btn)
				if btn and btn._fluxIsPresetGrid then
					return
				end
				if Paint.IsParked and Paint.IsParked(btn) then
					return
				end
				if Paint.Update then
					Paint.Update(btn)
				end
			end)
		end
		local list = EBS.buttons
		if not list then
			return
		end
		for i = 1, #list do
			local btn = list[i]
			if btn and btn.ActionType == "shapeshift" and not btn._fluxIsPresetGrid then
				if not (Paint.IsParked and Paint.IsParked(btn)) and Paint.Update then
					Paint.Update(btn)
				end
			end
		end
	end

	local function PaintExtrasUsable()
		local Paint = EBS.Paint
		if not (Paint and Paint.UpdateUsable) then
			return
		end
		local list = EBS.buttons
		if not list then
			return
		end
		for i = 1, #list do
			local btn = list[i]
			if btn and not btn._fluxIsPresetGrid then
				if not (Paint.IsParked and Paint.IsParked(btn)) then
					Paint.UpdateUsable(btn)
				end
			end
		end
	end

	local function ReleaseFormHeld()
		-- Do not FlushEval the whole extra + badge list. Burst already painted
		-- form-sensitive faces; usable-only on extra-window buttons covers
		-- power-type swaps (UNIT_DISPLAYPOWER) without touching badges/grids.
		-- Count is the exception: a charge that appeared during the window
		-- was not in that burst paint, including a quiet settle.
		local needUsable = formUsableHeld
		local needVisual = formIconHeld or formCooldownHeld
		local needCount = formCountHeld
		formUsableHeld = false
		formCooldownHeld = false
		formIconHeld = false
		formCountHeld = false
		if needCount then
			RequestEval("ebs.count")
		end
		if needVisual then
			PaintFormSensitiveExtras()
		end
		if needUsable then
			PaintExtrasUsable()
		end
	end

	local function OnForm()
		if Flux.Spell and Flux.Spell.ClearLiveFaceCache then
			Flux.Spell.ClearLiveFaceCache()
		end
		PaintFormSensitiveExtras()
	end

	local FormStorm = Flux.FormStorm
	if FormStorm and FormStorm.OnBurst then
		FormStorm.OnBurst("ebs.form", OnForm)
		FormStorm.OnSettled("ebs.form", function(quiet)
			ReleaseFormHeld()
			if quiet then
				return
			end
			PaintFormSensitiveExtras()
		end)
	else
		Ev.Register("UPDATE_SHAPESHIFT_FORM", OnForm)
		Ev.Register("UPDATE_BONUS_ACTIONBAR", OnForm)
		Ev.Register("UPDATE_STEALTH", OnForm)
	end

	local displayPowerQueued = false
	Ev.Register("UNIT_DISPLAYPOWER", function(_, unit)
		if unit and unit ~= "player" then
			return
		end
		if InFormWindow() then
			formUsableHeld = true
			return
		end
		-- Shapeshift often emits this before UPDATE_SHAPESHIFT_FORM. One-tick
		-- defer: if a form window opened this frame, skip the full walk.
		if displayPowerQueued then
			return
		end
		displayPowerQueued = true
		local function run()
			displayPowerQueued = false
			if InFormWindow() then
				formUsableHeld = true
				return
			end
			RequestEval("ebs.usable")
		end
		if Flux.Timer and Flux.Timer.Defer then
			Flux.Timer.Defer(run)
		elseif C_Timer and C_Timer.After then
			C_Timer.After(0, run)
		else
			run()
		end
	end)

	-- The SpellBook bus debounces and signature-gates the form/vehicle
	-- SPELLS_CHANGED spam, so the flyout cache wipe here only runs when the
	-- book actually changed.
	local function OnSpellBookChanged()
		if EBS.Paint and EBS.Paint.InvalidateSpellCaches then
			EBS.Paint.InvalidateSpellCaches()
		end
		if EBS.Action and EBS.Action.RefreshAssistantIdentity then
			EBS.Action.RefreshAssistantIdentity()
		end
		if EBS.Action and EBS.Action.PaintAssistantButtons then
			EBS.Action.PaintAssistantButtons()
		end
		RequestIcon()
		RefreshMacros()
	end
	if Flux.SpellBook and Flux.SpellBook.OnChanged then
		Flux.SpellBook.OnChanged("ebs.watch", OnSpellBookChanged)
	else
		Ev.Register("SPELLS_CHANGED", OnSpellBookChanged)
	end

	Ev.Register("GET_ITEM_INFO_RECEIVED", function()
		if EBS.Paint and EBS.Paint.HasPendingIcon and not EBS.Paint.HasPendingIcon() then
			return
		end
		RequestIcon()
	end)
	if C_TransmogOutfitInfo and C_TransmogOutfitInfo.GetOutfitsInfo then
		Ev.Register("TRANSMOG_OUTFITS_CHANGED", function()
			if EBS.Action and EBS.Action.RefreshOutfits then EBS.Action.RefreshOutfits() end
			RequestLanes("ebs.icon", "ebs.usable", "ebs.checked")
		end)
		Ev.Register("TRANSMOG_DISPLAYED_OUTFIT_CHANGED", function()
			RequestLanes("ebs.checked", "ebs.usable")
		end)
	end

	local function After(delay, fn)
		if FluxBtn and FluxBtn.Compat and FluxBtn.Compat.After then
			FluxBtn.Compat.After(delay, fn)
		elseif C_Timer and C_Timer.After then
			C_Timer.After(delay, fn)
		end
	end

	local function AnyMountUnresolved()
		local list = EBS.buttons
		if not list then
			return false
		end
		for i = 1, #list do
			local btn = list[i]
			if btn and btn.ActionType == "mount" and btn.MountId then
				if not btn.MountSpellId or not btn.MountName then
					return true
				end
			end
		end
		return false
	end

	local function HydrateMounts()
		if EBS.Action and EBS.Action.RefreshMounts then
			EBS.Action.RefreshMounts()
		end
		RequestLanes("ebs.icon", "ebs.usable")
		RequestCheckedSettle()
	end

	Ev.Register("PLAYER_ENTERING_WORLD", HydrateMounts)
	Ev.Register("COMPANION_UPDATE", function()
		if AnyMountUnresolved() then
			HydrateMounts()
		else
			RequestCheckedSettle()
		end
	end)
	Ev.Register("COMPANION_LEARNED", HydrateMounts)
	Ev.Register("NEW_MOUNT_ADDED", HydrateMounts)
	Ev.Register("PET_JOURNAL_LIST_UPDATE", function()
		RequestIcon()
		RequestCheckedSettle()
	end)
	Ev.Register("UNIT_PET", function(_, unit)
		if unit and unit ~= "player" then
			return
		end
		RequestCheckedSettle()
		RequestCond("target")
	end)
	Ev.Register("PET_BAR_UPDATE", RequestCheckedSettle)
	After(0.5, HydrateMounts)
	After(2, HydrateMounts)
	After(5, HydrateMounts)

	Ev.Register("CVAR_UPDATE", OnCVar)
	Ev.Register("PLAYER_TARGET_CHANGED", function()
		-- Range.Invalidate on class change covers Extra's sweep. Flags are
		-- ActionType/MacroMode, not which unit is targeted.
		if ContextOwnsDisplay() then
			return
		end
		local PF = Flux.Bars and Flux.Bars.ProgramFace
		if PF and PF.RequestTarget then
			PF.RequestTarget()
		else
			RequestCond("target")
		end
	end)
	Ev.Register("PLAYER_FOCUS_CHANGED", function()
		if EBS.Range and EBS.Range.RefreshFlags then
			EBS.Range.RefreshFlags()
		end
		if ContextOwnsDisplay() then
			return
		end
		RequestCond("target")
	end)

	-- Page / override / vehicle open a FormStorm burst, which already asks for
	-- an "all" translate. Registering them here too parsed every Extra macro a
	-- second time on the same edge.
	local function OnMacroConditional()
		RequestCond("all")
	end
	Ev.Register("MODIFIER_STATE_CHANGED", function()
		if ContextOwnsDisplay() then
			return
		end
		RequestCond("mod")
	end)
	if not (FormStorm and FormStorm.OnBurst) then
		Ev.Register("UPDATE_OVERRIDE_ACTIONBAR", OnMacroConditional)
		Ev.Register("UPDATE_VEHICLE_ACTIONBAR", OnMacroConditional)
		Ev.Register("ACTIONBAR_PAGE_CHANGED", OnMacroConditional)
	end
	Ev.Register("ACTIVE_TALENT_GROUP_CHANGED", OnMacroConditional)
	Ev.Register("PLAYER_SPECIALIZATION_CHANGED", OnMacroConditional)
	Ev.Register("GROUP_ROSTER_UPDATE", function()
		RequestCond("combat")
	end)

	local function OnPlayerUnit(_, unit)
		if unit and unit ~= "player" then
			return
		end
		RequestCond("combat")
	end
	Ev.Register("UNIT_SPELLCAST_CHANNEL_START", OnPlayerUnit)
	Ev.Register("UNIT_SPELLCAST_CHANNEL_STOP", OnPlayerUnit)
	Ev.Register("UNIT_ENTERED_VEHICLE", OnPlayerUnit)
	Ev.Register("UNIT_EXITED_VEHICLE", OnPlayerUnit)

	Ev.Register("PLAYER_UPDATE_RESTING", function()
		RequestCond("combat")
	end)
	Ev.Register("PLAYER_TALENT_UPDATE", OnMacroConditional)

	local function OnUnitConditional(_, unit)
		-- Bars Watch already Request("target"); SameKind drops the duplicate.
		if Flux.Bars and Flux.Bars.ProgramFace and Flux.Bars.ProgramFace.Request then
			return
		end
		if unit == "player" or unit == "target" or unit == "focus" or unit == "pet" then
			RequestCond("target")
		end
	end
	Ev.Register("UNIT_FLAGS", OnUnitConditional)
	Ev.Register("UNIT_FACTION", OnUnitConditional)
	Ev.Register("UNIT_TARGET", OnUnitConditional)

	After(2, function()
		if EBS.Action and EBS.Action.ForceMacrosLoaded then
			EBS.Action.ForceMacrosLoaded()
		end
	end)
	After(3, function()
		if EBS.Action and EBS.Action.EnableMacroPrune then
			EBS.Action.EnableMacroPrune()
		end
	end)

	local G = Flux.ButtonFX and Flux.ButtonFX.Glow
	if G then
		if G.Start then
			G.Start()
		end
		if G.OnChange then
			G.OnChange(function()
				RequestEval("ebs.glow")
			end)
		end
	end
	local F = Flux.ButtonFX and Flux.ButtonFX.Flash
	if F then
		if F.Start then
			F.Start()
		end
		if F.OnChange then
			F.OnChange(function()
				if EBS.Paint and EBS.Paint.FlushFlash then
					EBS.Paint.FlushFlash()
				end
			end)
		end
	end

	-- One combat edge, one handler: checked lane, conditional bucket and the
	-- assistant face used to be three separate registrations on this event.
	local function OnRegenEdge()
		RequestChecked()
		if not ContextOwnsDisplay() then
			RequestCond("combat")
		end
		if EBS.Action and EBS.Action.RefreshAssistantChrome then
			EBS.Action.RefreshAssistantChrome()
		end
		if EBS.Action and EBS.Action.PaintAssistantButtons then
			EBS.Action.PaintAssistantButtons()
		end
		Watch.SyncAssistantTicker()
		if EBS.Action and EBS.Action.RebindAssistant then
			EBS.Action.RebindAssistant()
		end
	end
	Ev.Register("PLAYER_REGEN_DISABLED", OnRegenEdge)
	Ev.Register("PLAYER_REGEN_ENABLED", OnRegenEdge)
	Ev.Register("UPDATE_BINDINGS", function()
		if EBS.Action and EBS.Action.RebindAssistant then
			EBS.Action.RebindAssistant()
		end
	end)
	Ev.Register("PLAYER_ENTERING_WORLD", function()
		RequestCooldown()
		if EBS.Action and EBS.Action.RefreshAssistantIdentity then
			EBS.Action.RefreshAssistantIdentity()
		end
		if EBS.Action and EBS.Action.RebindAssistant then
			EBS.Action.RebindAssistant()
		end
		Watch.SyncAssistantTicker()
	end)

	local registry = _G.EventRegistry
	if registry and registry.RegisterCallback then
		pcall(registry.RegisterCallback, registry, "AssistedCombatManager.OnSetActionSpell", function()
			if EBS.Action and EBS.Action.RefreshAssistantIdentity then
				EBS.Action.RefreshAssistantIdentity()
			end
			if EBS.Action and EBS.Action.PaintAssistantButtons then
				EBS.Action.PaintAssistantButtons()
			end
			Watch.SyncAssistantTicker()
			if EBS.Action and EBS.Action.RebindAssistant then
				EBS.Action.RebindAssistant()
			end
		end, Watch)
		pcall(registry.RegisterCallback, registry, "AssistedCombatManager.RotationSpellsUpdated", function()
			if EBS.Action and EBS.Action.RefreshAssistantIdentity then
				EBS.Action.RefreshAssistantIdentity()
			end
			if EBS.Action and EBS.Action.PaintAssistantButtons then
				EBS.Action.PaintAssistantButtons()
			end
			Watch.SyncAssistantTicker()
		end, Watch)
	end

	Watch.SyncAssistantTicker()
	if EBS.Action and EBS.Action.RebindAssistant then
		EBS.Action.RebindAssistant()
	end
end
