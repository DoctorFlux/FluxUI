-- Bars/Init.lua — 19-column action strip: Flux hosts, SHIFT/CTRL minis, form paging.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars or {}
Flux.Bars = Bars

Bars.NUM_COLUMNS = 19
Bars.NUM_NATIVE = 12

-- Backup parity: FluxActionBar_Config (44 / 0 / 4 / 1.24 / yOffset 4) and the
-- SmartLayout -2 height tweak that keeps the border off the screen edge.
Bars.CONFIG = {
	buttonSize = 44,
	padding = 0,
	margin = 4,
	scale = 1.24,
	yOffset = 4,
	heightTweak = -2,
	strata = "MEDIUM",
	level = 5,
	rangeInterval = 0.25,
}

Bars.COLOR = {
	usable = { 1, 1, 1 },
	unusable = { 0.4, 0.4, 0.4 },
	mana = { 0.5, 0.5, 1.0 },
	outOfRange = { 0.8, 0.1, 0.1 },
}

--- column -> { column, main, sec, tert, bindingCommand, pages }
Bars.hosts = {}
Bars.started = false
Bars.secureReady = false

function Bars.GetHost(column)
	return Bars.hosts[column]
end

function Bars.GetMain(column)
	local col = Bars.hosts[column]
	return col and col.main
end

function Bars.ForEach(fn)
	local hosts = Bars.hosts
	for i = 1, Bars.NUM_COLUMNS do
		local col = hosts[i]
		if col then
			fn(col, i)
		end
	end
end

--- Every click surface: 19 mains + 38 minis.
function Bars.ForEachHost(fn)
	local hosts = Bars.hosts
	for i = 1, Bars.NUM_COLUMNS do
		local col = hosts[i]
		if col then
			if col.main then
				fn(col.main, i, "main")
			end
			if col.sec then
				fn(col.sec, i, "sec")
			end
			if col.tert then
				fn(col.tert, i, "tert")
			end
		end
	end
end

--- Alias: all surfaces are Flux-owned now.
function Bars.ForEachStatic(fn)
	Bars.ForEachHost(fn)
end

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

-- Paging and single-slot edits cannot re-show a leftover Blizzard bar, and the
-- secure driver already marks the hosts whose action moved, so they skip the
-- stock-frame sweep and the full 57-host repaint. Anything else keeps both.
local CHEAP_REASON = {
	page = true,
	slot = true,
}
local DRAG_REASON = {
	cursor = true,
	drag = true,
	drag_end = true,
	showgrid = true,
	hidegrid = true,
}

local pendingStructural = false
local pendingFullPaint = false
local pendingDragPaint = false
local pendingNonHover = false
local pendingSlotLayout = false
local layoutQueued = false
local stockSweepQueued = false

local function RunQueuedLayout()
	layoutQueued = false
	local layout = Bars.Layout
	if pendingDragPaint and not pendingNonHover and layout and layout.HasPendingDragPose
		and not layout.HasPendingDragPose() then
		-- The cursor already returned to the applied pose in this frame.
		pendingDragPaint = false
		return
	end
	Bars.ApplyLayout()
end

function Bars.RequestLayout(reason)
	if not Bars.started then
		return
	end
	if reason ~= "drag" then pendingNonHover = true end
	if reason == "slot" then pendingSlotLayout = true end
	if not CHEAP_REASON[reason or "smart"] then
		-- Dragging can reveal placeholders that need a full paint. Native
		-- grid events suppress stock buttons through their lightweight pass.
		if DRAG_REASON[reason] then
			pendingDragPaint = true
		else
			pendingStructural = true
			pendingFullPaint = true
		end
	end
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.layout", function()
				Bars.RequestLayout(reason or "post_combat")
			end)
		end
		return
	end
	if Flux.Scheduler and Flux.Scheduler.Request then
		-- ApplyLayout consumes the pending flags, so one run per frame covers
		-- every request made before it.
		if not layoutQueued then
			layoutQueued = true
			Flux.Scheduler.Request("layout", "bars", RunQueuedLayout, reason)
		end
		return
	end
	Bars.ApplyLayout()
end

local function RunStockSweep()
	stockSweepQueued = false
	if InLockdown() then
		Bars.RequestStockSweep()
		return
	end
	-- A queued structural layout runs the same sweep.
	if layoutQueued and pendingStructural then
		return
	end
	if Bars.Blizzard and Bars.Blizzard.QuietGrid then
		Bars.Blizzard.QuietGrid()
	end
end

--- Grid events re-show stock action buttons (ActionBarMixin:SetShowGrid) while
--- the strip itself stays put: neutralise them again without a layout or paint.
function Bars.RequestStockSweep()
	if not Bars.started then
		return
	end
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.stock", Bars.RequestStockSweep)
		end
		return
	end
	if stockSweepQueued then
		return
	end
	stockSweepQueued = true
	if Flux.Timer and Flux.Timer.After then
		Flux.Timer.After(0, RunStockSweep)
		return
	end
	RunStockSweep()
end

function Bars.RequestPaint(token)
	if not Bars.started then
		return
	end
	if Flux.Scheduler and Flux.Scheduler.Request then
		Flux.Scheduler.Request("eval", token or "bars")
		return
	end
	if Bars.Paint and Bars.Paint.Flush then
		Bars.Paint.Flush(nil)
	end
end

local function HasBarsToken(tokens)
	if not tokens then
		return false
	end
	for key in pairs(tokens) do
		if key == "bars" or (type(key) == "string" and string.sub(key, 1, 5) == "bars.") then
			return true
		end
	end
	return false
end

local schedulerHooked = false

local function HookScheduler()
	if schedulerHooked or not (Flux.Scheduler and Flux.Scheduler.Register) then
		return
	end
	Flux.Scheduler.Register("eval", function(tokens)
		-- ProgramFace TOC-loads after this file, so look it up at eval time.
		-- Cond translate must run before Paint.Flush in the same bucket.
		local PF = Bars.ProgramFace
		if PF and PF.FlushPending and tokens and tokens["flux.cond"] then
			PF.FlushPending(tokens)
		end
		if not HasBarsToken(tokens) then
			return
		end
		if Bars.Paint and Bars.Paint.Flush then
			Bars.Paint.Flush(tokens)
		end
	end)
	schedulerHooked = true
end

function Bars.ApplyLayout()
	if InLockdown() then
		Bars.RequestLayout("lockdown")
		return
	end
	local structural = pendingStructural
	local fullPaint = pendingFullPaint
	local dragPaint = pendingDragPaint
	local hoverOnly = not pendingNonHover
	local slotLayout = pendingSlotLayout and not structural
	pendingStructural = false
	pendingFullPaint = false
	pendingDragPaint = false
	pendingNonHover = false
	pendingSlotLayout = false

	local Perf = Flux.Perf
	if Flux.Startup then Flux.Startup.Count("action_layout_passes") end
	if Perf then
		Perf.Begin("bars.layout")
	end
	-- Neutralising ~100 leftover stock frames belongs to setup, not to paging.
	if structural and Bars.Blizzard and Bars.Blizzard.Reassert then
		Bars.Blizzard.Reassert()
	end
	local moved = true
	local layoutFaces
	local dragHover = hoverOnly and dragPaint
	if Bars.Layout and Bars.Layout.Apply then
		moved, layoutFaces = Bars.Layout.Apply(dragHover, slotLayout)
	elseif Bars.Strip and Bars.Strip.Layout then
		Bars.Strip.Layout()
	end
	if Bars.Hosts and Bars.Hosts.RefreshKeys then
		if Bars.Hosts.RefreshKeys(dragHover) == false then return false end
	elseif Bars.Clicks and Bars.Clicks.RefreshKeys then
		if Bars.Clicks.RefreshKeys(dragHover) == false then return false end
	end
	-- Paging does not full-paint: the secure driver rewrites "action", which
	-- fires OnActionAttribute and marks exactly the hosts whose slot moved.
	-- Those dirty hosts, plus whichever lanes the event asked for, run in this
	-- same scheduler flush.
	-- Settle both hover edges before painting. A held-cursor crossing only
	-- repaints changed faces and pending slot paints. Other drag events can
	-- change button contents without moving their frames.
	if (fullPaint or dragPaint and moved) and Bars.Paint and Bars.Paint.Flush then
		Bars.Paint.Flush(nil, hoverOnly and not fullPaint and layoutFaces or nil)
	end
	if Perf then
		Perf.Stop("bars.layout")
	end
	return true
end

function Bars.Start()
	if Bars.started then
		return true
	end
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.start", Bars.Start)
		end
		return false
	end
	HookScheduler()
	if Bars.Vehicle and Bars.Vehicle.Start then
		Bars.Vehicle.Start()
	end
	if Bars.Strip and Bars.Strip.Create then
		Bars.Strip.Create()
	end
	if Bars.State and Bars.State.Create then
		Bars.State.Create()
	end
	if Bars.Hosts and Bars.Hosts.Build then
		if Bars.Hosts.Build() == false then return false end
	end
	if Bars.Minis and Bars.Minis.Build then
		if Bars.Minis.Build() == false then return false end
	end
	for i = 1, Bars.NUM_COLUMNS do
		local col = Bars.hosts[i]
		if not (col and col.main and col.main.widget and col.sec and col.sec.widget and col.tert and col.tert.widget) then
			return false
		end
	end
	if Bars.Clicks and Bars.Clicks.Start then
		if Bars.Clicks.Start() == false then return false end
	end
	if Bars.State and Bars.State.RegisterDrivers then
		if Bars.State.RegisterDrivers() == false then return false end
	end
	if Bars.Watch and Bars.Watch.Start then
		Bars.Watch.Start()
	end
	if Bars.ProgramFace and Bars.ProgramFace.Start then
		Bars.ProgramFace.Start()
	end
	if Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.Start then
		Flux.ButtonFX.Cast.Start()
	end
	if Bars.Layout and Bars.Layout.Start then
		Bars.Layout.Start()
	end
	-- Apply the saved layout once, after all hosts and state drivers exist.
	pendingStructural = true
	pendingFullPaint = true
	if Bars.ApplyLayout() == false then return false end
	if Bars.State and Bars.State.ForceApply then
		Bars.State.ForceApply()
	end
	if Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.RefreshFromOptions then
		Flux.ButtonFX.Cast.RefreshFromOptions()
	end
	Bars.ApplyPerformanceSettings()
	if Bars.Strip and Bars.Strip.WatchGamepad then
		Bars.Strip.WatchGamepad()
	end
	Bars.secureReady = true
	local committed, reason = pcall(function()
		if Bars.Strip and Bars.Strip.SyncVisibility then Bars.Strip.SyncVisibility() end
		if Bars.Vehicle and Bars.Vehicle.OnReplacementsReady then Bars.Vehicle.OnReplacementsReady() end
		if Bars.Blizzard and Bars.Blizzard.Prepare then Bars.Blizzard.Prepare() end
	end)
	if not committed then
		Bars.secureReady = false
		error(reason)
	end
	Bars.started = true
	if Flux.Startup then
		Flux.Startup.Mark("secure_action_infrastructure_ready")
		local strip = Bars.Strip and Bars.Strip.frame
		local visible = strip and (strip.IsVisible and strip:IsVisible() or (not strip.IsVisible and strip.IsShown and strip:IsShown()))
		if visible then Flux.Startup.Mark("action_buttons_visible") end
	end
	return true
end

local function ActionbarsDB()
	local fo = _G.FluxOptions
	if fo and fo.GetActionbarsDB then
		local ok, t = pcall(fo.GetActionbarsDB, fo)
		if ok then
			return t
		end
	end
	return nil
end

function Bars.ApplyPerformanceSettings()
	local t = ActionbarsDB()
	if not t then
		return
	end
	local R = Flux.Range
	if R then
		if R.SetInterval then
			R.SetInterval(t.rangeCheckInterval or 0.25)
		end
		if R.SetExtraInterval then
			R.SetExtraInterval(t.extraButtonRangeCheckInterval or 0.18)
		end
	end
	if Bars.ProgramFace then
		if Bars.ProgramFace.SetMouseoverPollInterval then
			Bars.ProgramFace.SetMouseoverPollInterval(t.mouseoverUpdateInterval or 0.07)
		end
		if Bars.ProgramFace.SetMinFlushInterval then
			Bars.ProgramFace.SetMinFlushInterval(t.macroUsableMinInterval or 0.05)
		end
	end
	if Bars.Watch and Bars.Watch.SetActionUsableMinInterval then
		Bars.Watch.SetActionUsableMinInterval(t.actionUsableMinInterval or 0)
	end
end

function Bars.ApplyActionbarsOptions()
	if Bars.RequestLayout then
		Bars.RequestLayout("options")
	end
	if Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.RefreshFromOptions then
		Flux.ButtonFX.Cast.RefreshFromOptions()
	end
	Bars.ApplyPerformanceSettings()
end

Flux.Module.Register("ActionBars", {
	phase = "secure",
	priority = 20,
	protected = true,
	clients = { era = true, anniversary = true, classic = true, midnight = true },
	OnEnable = function()
		return Bars.Start()
	end,
})

local function yn(v)
	return v and "yes" or "no"
end

local function DescribeSurface(host, row)
	if not host or not host.widget then
		print("  " .. row .. ": missing")
		return
	end
	local w = host.widget
	local key = "-"
	if host.bindingCommand and GetBindingKey then
		key = GetBindingKey(host.bindingCommand) or "-"
	end
	print(string.format("  %-4s shown=%s scale=%.2f action=%s mouse=%s parked=%s key=%s",
		row,
		yn(w:IsShown()),
		w:GetScale() or 1,
		tostring(w:GetAttribute("action")),
		yn(w.IsMouseEnabled and w:IsMouseEnabled()),
		yn(w._fluxParked),
		tostring(key)))
	-- The click-time paging sets. CalculateAction reads these through
	-- SecureButton_GetModifiedAttribute, so a SHIFT press that fires the wrong
	-- spell shows up here as a stale or missing shift-action*. The bare action
	-- above is only the live face and no longer decides what a click casts.
	local parent = w.GetParent and w:GetParent()
	print(string.format("       nomod=%s/%s shift=%s/%s ctrl=%s/%s",
		tostring(w:GetAttribute("action*")),
		tostring(w:GetAttribute("type*")),
		tostring(w:GetAttribute("shift-action*")),
		tostring(w:GetAttribute("shift-type*")),
		tostring(w:GetAttribute("ctrl-action*")),
		tostring(w:GetAttribute("ctrl-type*"))))
	print(string.format("       applied=%s/%s liveOcc=%s/%s",
		tostring(w:GetAttribute("flux-applied")),
		tostring(w:GetAttribute("flux-applied-mods")),
		tostring(w:GetAttribute("flux-live-sec")),
		tostring(w:GetAttribute("flux-live-tert"))))
	print(string.format("       type=%s hasSec=%s hasTert=%s promoted=%s id=%s parent=%s",
		tostring(w:GetAttribute("type")),
		tostring(w:GetAttribute("flux-has-sec")),
		tostring(w:GetAttribute("flux-has-tert")),
		tostring(w:GetAttribute("flux-promoted")),
		tostring(w.GetID and w:GetID()),
		tostring(parent and parent.GetName and parent:GetName())))
end

--- Secure paging chain at a glance. Safe to run in combat, which is the only
--- way to tell a dead snippet from a stale slot.
local function DescribePaging()
	local State = Bars.State
	Flux.Print("Action strip paging")
	local R = Flux.Restricted
	print("  snippets=" .. yn(R and R.Works and R.Works())
		.. " lockdown=" .. yn(InLockdown())
		.. " page=" .. tostring(State and State.GetCurrentPage and State.GetCurrentPage())
		.. " swap=" .. tostring(State and State.CurrentSwap and State.CurrentSwap()))
	print("  securePaging=" .. yn(State and State.UsesSecurePaging and State.UsesSecurePaging())
		.. " (Forever keeps v8 mouse-up and key-down input)")
	local hub = State and State.hub
	if hub then
		print("  hub state-mod=" .. tostring(hub:GetAttribute("state-mod")))
	else
		print("  hub missing")
	end
	local headers = State and State.headers
	if not headers then
		print("  headers missing")
		return
	end
	for _, name in ipairs({ "main", "sec", "tert", "staticMain", "staticSec", "staticTert" }) do
		local h = headers[name]
		if h then
			print(string.format("  %-10s state=%s swap=%s native=%s page=%s actionpage=%s children=%d",
				name,
				tostring(h:GetAttribute("state")),
				tostring(h:GetAttribute("state-swap")),
				tostring(h:GetAttribute("state-native")),
				tostring(h:GetAttribute("state-page")),
				tostring(h:GetAttribute("actionpage")),
				select("#", h:GetChildren())))
		end
	end
end

-- Explicit read-only recovery probe: compare the documented main row with the
-- native click calculation and effective key route. Never place/clear actions.
local function AuditValue(value)
	local S = Flux.Secrets
	if (issecretvalue and issecretvalue(value))
		or (S and S.CanAccessValue and not S.CanAccessValue(value)) then return "<private>" end
	return tostring(value)
end

local function AuditRead(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, a, b = pcall(fn, ...)
	if ok then return a, b end
	return "<unavailable>"
end

local function AuditNumber(value)
	if AuditValue(value) == "<private>" then return nil end
	return type(value) == "number" and value or nil
end

-- Explicit native evidence for a reported modifier route. This never clicks,
-- casts, changes attributes or stores private macro bodies in SavedVariables.
local TRACE_PREFIXES = { "", "shift-", "ctrl-", "ctrl-shift-", "alt-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }
local function TraceBody(body)
	if AuditValue(body) == "<private>" then return "<private>" end
	if type(body) ~= "string" then return AuditValue(body) end
	return body:gsub("[\r\n]+", " | "):sub(1, 220)
end

function Bars.TraceColumn(column)
	if InLockdown() then Flux.Print("Action route trace: leave combat first."); return false end
	column = tonumber(column)
	local host = column and Bars.GetMain(column)
	if not host or not host.widget then Flux.Print("Action route trace: choose a column from 1 to 19."); return false end
	local w, State, SM = host.widget, Bars.State, Bars.SlotMath
	local proxy = _G["FluxActionStripKey" .. column]
	local key = host.bindingCommand and AuditRead(GetBindingKey, host.bindingCommand)
	local page = State and AuditNumber(AuditRead(State.GetCurrentPage))
	local opts = { promoted = AuditNumber(AuditRead(w.GetAttribute, w, "flux-promoted")) or 0,
		hasSec = AuditNumber(AuditRead(w.GetAttribute, w, "flux-has-sec")) == 1,
		hasTert = AuditNumber(AuditRead(w.GetAttribute, w, "flux-has-tert")) == 1 }
	Flux.Print("Action route trace r2: column=" .. column .. " page=" .. AuditValue(page)
		.. " key=" .. AuditValue(key) .. " held=" .. AuditValue(AuditRead(SecureButton_GetModifierPrefix, proxy or w)))
	print("  live=" .. AuditValue(host.slot) .. " main=" .. AuditValue(AuditRead(w.GetAttribute, w, "action"))
		.. " mouse=" .. AuditValue(AuditRead(w.CalculateAction, w, "LeftButton"))
		.. " keyClick=" .. AuditValue(proxy and AuditRead(proxy.CalculateAction, proxy, "LeftButton")))
	for _, prefix in ipairs(TRACE_PREFIXES) do
		local swap = prefix:find("shift-", 1, true) and 1 or (prefix:find("ctrl-", 1, true) and 2 or 0)
		local expected = page and SM and SM.Resolve(column, "main", page, swap, opts)
		local chord = type(key) == "string" and prefix:upper() .. key or nil
		print("  " .. (prefix == "" and "nomod" or prefix) .. " expected=" .. AuditValue(expected)
			.. " binding=" .. AuditValue(chord and AuditRead(GetBindingAction, chord, true)))
		for i = 1, (proxy and 2 or 1) do
			local frame = i == 1 and w or proxy
			local typ = AuditRead(SecureButton_GetModifiedAttribute, frame, "type", "LeftButton", prefix, "1")
			local slot = AuditRead(SecureButton_GetModifiedAttribute, frame, "action", "LeftButton", prefix, "1")
			local delegate = AuditRead(SecureButton_GetModifiedAttribute, frame, "clickbutton", "LeftButton", prefix, "1")
			local text = AuditRead(SecureButton_GetModifiedAttribute, frame, "macrotext", "LeftButton", prefix, "1")
			local delegateName
			if AuditValue(delegate) ~= "<private>" and (type(delegate) == "table" or type(delegate) == "userdata") then
				delegateName = AuditRead(delegate.GetName, delegate)
				if AuditValue(typ) == "click" then text = AuditRead(delegate.GetAttribute, delegate, "macrotext") end
			end
			print("    " .. (i == 1 and "host" or "key") .. " type=" .. AuditValue(typ) .. " action=" .. AuditValue(slot)
				.. " delegate=" .. AuditValue(delegateName) .. " body=" .. TraceBody(text))
		end
	end
	return true
end

-- Opt-in observation through the existing push-effect PreClick hooks. The
-- callback disappears after one input (or timeout); no new frame hook/poll.
function Bars.TraceNextKey(column)
	if InLockdown() then Flux.Print("Action input trace: leave combat first."); return false end
	if not (C_Timer and C_Timer.After) then Flux.Print("Action input trace: timer unavailable."); return false end
	column = tonumber(column)
	local host = column and Bars.GetMain(column)
	if not host or not host.widget then Flux.Print("Action input trace: choose a column from 1 to 19."); return false end
	local capture
	capture = function(actualColumn, frame, button, down)
		if actualColumn ~= column then return end
		Bars.TraceKeyClick = nil
		local prefix = AuditRead(SecureButton_GetModifierPrefix, frame)
		local mapped = button == "KeyBind" and "LeftButton" or button
		local typ = AuditRead(SecureButton_GetModifiedAttribute, frame, "type", mapped, prefix)
		local slot = AuditRead(SecureButton_GetModifiedAttribute, frame, "action", mapped, prefix)
		local macro = AuditRead(SecureButton_GetModifiedAttribute, frame, "macro", mapped, prefix)
		local text = AuditRead(SecureButton_GetModifiedAttribute, frame, "macrotext", mapped, prefix)
		local release = AuditRead(SecureButton_GetModifiedAttribute, frame, "typerelease", mapped, prefix)
		local unit = AuditRead(SecureButton_GetModifiedAttribute, frame, "unit", mapped, prefix)
		local parsedMods = AuditRead(SecureCmdOptionParse, "[mod:ctrl,mod:shift]both;[mod:shift]shift;[mod:ctrl]ctrl;nomod")
		Flux.Print("Action input r3: column=" .. column .. " frame=" .. AuditValue(AuditRead(frame.GetName, frame))
			.. " button=" .. AuditValue(button) .. " down=" .. AuditValue(down) .. " held=" .. AuditValue(prefix))
		print("  shown=" .. AuditValue(host.slot) .. " type=" .. AuditValue(typ) .. " action=" .. AuditValue(slot)
			.. " macro=" .. AuditValue(macro) .. " release=" .. AuditValue(release) .. " unit=" .. AuditValue(unit)
			.. " keyDown=" .. AuditValue(AuditRead(frame.GetAttribute, frame, "useOnKeyDown"))
			.. " hold=" .. AuditValue(AuditRead(frame.GetAttribute, frame, "pressAndHoldAction"))
			.. " macroMods=" .. AuditValue(parsedMods)
			.. " rawShift=" .. AuditValue(AuditRead(IsShiftKeyDown)) .. " rawCtrl=" .. AuditValue(AuditRead(IsControlKeyDown))
			.. " body=" .. TraceBody(text))
	end
	Bars.TraceKeyClick = capture
	if C_Timer and C_Timer.After then
		C_Timer.After(12, function()
			if Bars.TraceKeyClick == capture then
				Bars.TraceKeyClick = nil
				Flux.Print("Action input trace expired: no input observed on this column.")
			end
		end)
	end
	Flux.Print("Action input trace armed for column " .. column .. "; press its key once with the reported modifier.")
	return true
end

function Bars.AuditMainRow()
	if InLockdown() then Flux.Print("Main-row audit: leave combat first."); return end
	if (IsShiftKeyDown and IsShiftKeyDown()) or (IsControlKeyDown and IsControlKeyDown()) then
		Flux.Print("Main-row audit: release Shift and Ctrl first."); return
	end
	local State, SM, A = Bars.State, Bars.SlotMath, Flux.Action
	local page = State and State.GetCurrentPage and State.GetCurrentPage() or 1
	page = AuditNumber(page)
	if not page then Flux.Print("Main-row audit: page is unavailable."); return end
	Flux.Print("Main-row audit: page=" .. AuditValue(page) .. "; columns 13-19 stay on their fixed slots.")
	for column = 1, Bars.NUM_COLUMNS do
		local host = Bars.GetMain(column)
		local w = host and host.widget
		if not w then
			print(string.format("  %02d missing", column))
		else
			local opts = { promoted = AuditNumber(w:GetAttribute("flux-promoted")) or 0,
				hasSec = AuditNumber(w:GetAttribute("flux-has-sec")) == 1,
				hasTert = AuditNumber(w:GetAttribute("flux-has-tert")) == 1 }
			local expected = SM and SM.Resolve(column, "main", page, 0, opts)
			local click = AuditRead(w.CalculateAction, w, "LeftButton")
			local proxy = _G["FluxActionStripKey" .. column]
			local keySlot = proxy and AuditRead(proxy.CalculateAction, proxy, "LeftButton")
				or AuditRead(w.CalculateAction, w, "KeyBind")
			local key = host.bindingCommand and AuditRead(GetBindingKey, host.bindingCommand)
			local route = key and AuditRead(GetBindingAction, key, true)
			local kind, id = AuditRead(A and A.GetInfo or GetActionInfo, expected)
			local name
			if AuditValue(kind) == "spell" and AuditNumber(id) and Flux.Spell then
				name = AuditRead(Flux.Spell.GetName, id)
			end
			local icon = host.WIcon or w.icon or w.Icon
			local shown = icon and AuditRead(icon.GetTexture, icon)
			local native = AuditRead(A and A.GetTexture or GetActionTexture, expected)
			print(string.format("  %02d expected=%s host=%s attr=%s click=%s keyClick=%s key=%s route=%s action=%s/%s %s icon=%s/%s",
				column, AuditValue(expected), AuditValue(host.slot), AuditValue(w:GetAttribute("action")),
				AuditValue(click), AuditValue(keySlot), AuditValue(key), AuditValue(route), AuditValue(kind),
				AuditValue(id), name and AuditValue(name) or "", AuditValue(shown), AuditValue(native)))
		end
	end
end

-- Explicit OOC recovery of our widgets and override routes. Native action-slot
-- contents and saved profiles remain owned by their existing services.
local RECOVERY_MODIFIERS = { "", "shift-", "ctrl-" }
function Bars.RestoreMainRow()
	if InLockdown() then Flux.Print("Main-row restore: leave combat first."); return false end
	if (IsShiftKeyDown and IsShiftKeyDown()) or (IsControlKeyDown and IsControlKeyDown()) then
		Flux.Print("Main-row restore: release Shift and Ctrl first."); return false
	end
	local State, Layout, Clicks = Bars.State, Bars.Layout, Bars.Clicks
	if not Bars.started or not State or not State.Attach or not State.HeaderFor or not State.ForceApply or not State.IndexLiveSlots
		or not Layout or not Layout.InvalidateMappings or not Layout.ApplyMappings
		or not Clicks or not Clicks.InvalidateKeys or not Clicks.RefreshKeys then
		Flux.Print("Main-row restore: action-bar initialization is incomplete."); return false
	end
	-- Check the complete row before modifying any widget.
	for column = 1, Bars.NUM_COLUMNS do
		local host = Bars.GetMain(column)
		if not host or not host.widget or not State.HeaderFor(column, "main") then
			Flux.Print("Main-row restore: a main button or header is missing."); return false
		end
	end
	for column = 1, Bars.NUM_COLUMNS do
		local host = Bars.GetMain(column)
		host.column, host.row = column, "main"
		State.Attach(State.HeaderFor(column, "main"), host.widget, column, "main")
		local proxy = _G["FluxActionStripKey" .. column]
		-- A legacy mouse-specific value outranks our documented action* set.
		-- Hidden key proxies own no slots: they inherit them from this widget.
		for _, prefix in ipairs(RECOVERY_MODIFIERS) do
			host.widget:SetAttribute(prefix .. "action1", nil)
			if proxy then
				proxy:SetAttribute(prefix .. "action", nil)
				proxy:SetAttribute(prefix .. "action*", nil)
				proxy:SetAttribute(prefix .. "action1", nil)
			end
		end
		host.widget:SetAttribute("*action1", nil)
		if proxy then
			proxy:SetID(0)
			proxy:SetParent(host.widget)
			proxy:SetAttribute("*action1", nil)
			proxy:SetAttribute("useparent-action", true)
		end
	end
	-- Attach resets occupancy flags; discard the mapping cache before rebuilding
	-- them so promotion and populated minirows retain their real contents.
	Layout.InvalidateMappings()
	Layout.ApplyMappings()
	Clicks.InvalidateKeys()
	if Clicks.RefreshKeys() == false or State.ForceApply() == false then
		Flux.Print("Main-row restore: routing refresh is incomplete."); return false
	end
	-- Secure ForceApply can leave action unchanged, so OnAttributeChanged need
	-- not repair a stale host.slot. Reindex before paint/tooltips use that cache.
	State.IndexLiveSlots()
	local Binding = _G.FluxBinding
	if Binding and Binding.NotifyBarReady then Binding.NotifyBarReady("main-row-restore") end
	local Paint = Bars.Paint
	if Paint then
		if Paint.ClearCache then
			for column = 1, Bars.NUM_COLUMNS do Paint.ClearCache(Bars.GetMain(column)) end
		end
		if Paint.Flush then Paint.Flush(nil) end
	end
	Flux.Print("Main-row routing rebuilt for buttons 1-19; placed actions preserved.")
	return true
end

SLASH_FLUXBARS1 = "/fluxbars"
SlashCmdList["FLUXBARS"] = function(msg)
	msg = msg and msg:match("^%s*(.-)%s*$") or ""
	if msg == "audit" then Bars.AuditMainRow(); return end
	if msg == "restore" then Bars.RestoreMainRow(); return end
	local traceColumn = msg:match("^trace%s+(%d+)$")
	if traceColumn then Bars.TraceColumn(traceColumn); return end
	local inputColumn = msg:match("^input%s+(%d+)$")
	if inputColumn then Bars.TraceNextKey(inputColumn); return end
	if msg == "mo" or msg == "mouseover" then
		local MC = Flux.MouseoverCast or _G.FluxMouseoverCast
		if MC and MC.DebugDump then
			MC.DebugDump()
		else
			Flux.Print("mouseover debug missing")
		end
		return
	end
	if msg == "page" or msg == "paging" then
		DescribePaging()
		return
	end
	if msg == "smoke" then
		local mathMod = Bars.SlotMath
		if not mathMod or not mathMod.SelfTest then
			Flux.Print("Action strip smoke: SlotMath missing")
			return
		end
		local failures = mathMod.SelfTest()
		if #failures == 0 then
			Flux.Print("Action strip smoke: slot math OK")
		else
			Flux.Print("Action strip smoke: " .. tostring(#failures) .. " failures")
			for i = 1, math.min(#failures, 12) do
				print("  " .. failures[i])
			end
		end
		return
	end
	local column = tonumber(msg and msg:match("%d+"))
	if column then
		local col = Bars.hosts[column]
		Flux.Print("Action strip column " .. column)
		if not col then
			print("  no such column")
			return
		end
		DescribeSurface(col.main, "main")
		DescribeSurface(col.sec, "sec")
		DescribeSurface(col.tert, "tert")
		if Bars.Layout then
			print("  empty=" .. yn(Bars.Layout.IsColumnEmpty(column))
				.. " mainFace=" .. yn(Bars.Layout.HasContentOnMain and Bars.Layout.HasContentOnMain(column))
				.. " promoted=" .. tostring(Bars.Layout.GetPromotedMode(column))
				.. " expanding=" .. yn(Bars.Layout.IsExpanding()))
		end
		return
	end

	local mains, minis, missing = 0, 0, 0
	Bars.ForEachHost(function(host, _, row)
		if not host.widget then
			missing = missing + 1
		elseif row == "main" then
			mains = mains + 1
		else
			minis = minis + 1
		end
	end)
	Flux.Print("Action strip")
	print("  started=" .. yn(Bars.started)
		.. " columns=" .. tostring(Bars.NUM_COLUMNS)
		.. " mains=" .. tostring(mains)
		.. " minis=" .. tostring(minis)
		.. " missing=" .. tostring(missing))
	local strip = Bars.Strip and Bars.Strip.frame
	if strip then
		print("  strip=" .. string.format("%.1f x %.1f", strip:GetWidth() or 0, strip:GetHeight() or 0)
			.. " shown=" .. yn(strip:IsShown())
			.. " y=" .. string.format("%.1f", (Bars.Strip.GetBottomScreenOffset and Bars.Strip.GetBottomScreenOffset()) or 0)
			.. " extra=" .. string.format("%.2f", Bars.Strip.extraScale or 1)
			.. " squeeze=" .. string.format("%.2f", Bars.Strip.xFactor or 1))
	end
	print("  rangeTicker=" .. yn(Bars.Watch and Bars.Watch.IsRangeArmed and Bars.Watch.IsRangeArmed()))
	print("  /fluxbars <column> for per-surface detail")
	print("  /fluxbars page for the secure paging chain (combat-safe)")
	print("  /fluxbars smoke for slot-math self-test")
end
