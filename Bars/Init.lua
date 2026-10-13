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

local pendingStructural = false
local pendingFullPaint = false
local layoutQueued = false
local stockSweepQueued = false

local function RunQueuedLayout()
	layoutQueued = false
	Bars.ApplyLayout()
end

function Bars.RequestLayout(reason)
	if not Bars.started then
		return
	end
	if not CHEAP_REASON[reason or "smart"] then
		pendingStructural = true
		pendingFullPaint = true
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
	schedulerHooked = true
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
end

function Bars.ApplyLayout()
	if InLockdown() then
		Bars.RequestLayout("lockdown")
		return
	end
	local structural = pendingStructural
	local fullPaint = pendingFullPaint
	pendingStructural = false
	pendingFullPaint = false

	local Perf = Flux.Perf
	if Perf then
		Perf.Begin("bars.layout")
	end
	-- Neutralising ~100 leftover stock frames belongs to setup, not to paging.
	if structural and Bars.Blizzard and Bars.Blizzard.Reassert then
		Bars.Blizzard.Reassert()
	end
	if Bars.Layout and Bars.Layout.Apply then
		Bars.Layout.Apply()
	elseif Bars.Strip and Bars.Strip.Layout then
		Bars.Strip.Layout()
	end
	if Bars.Hosts and Bars.Hosts.RefreshKeys then
		Bars.Hosts.RefreshKeys()
	elseif Bars.Clicks and Bars.Clicks.RefreshKeys then
		Bars.Clicks.RefreshKeys()
	end
	-- Paging does not full-paint: the secure driver rewrites "action", which
	-- fires OnActionAttribute and marks exactly the hosts whose slot moved.
	-- Those dirty hosts, plus whichever lanes the event asked for, run in this
	-- same scheduler flush.
	if fullPaint and Bars.Paint and Bars.Paint.Flush then
		Bars.Paint.Flush(nil)
	end
	if Perf then
		Perf.Stop("bars.layout")
	end
end

function Bars.Start()
	if Bars.started then
		return
	end
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.start", Bars.Start)
		end
		return
	end
	Bars.started = true
	HookScheduler()

	if Bars.Blizzard and Bars.Blizzard.Prepare then
		Bars.Blizzard.Prepare()
	end
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
		Bars.Hosts.Build()
	end
	if Bars.Minis and Bars.Minis.Build then
		Bars.Minis.Build()
	end
	if Bars.Clicks and Bars.Clicks.Start then
		Bars.Clicks.Start()
	end
	if Bars.State and Bars.State.RegisterDrivers then
		Bars.State.RegisterDrivers()
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
	Bars.ApplyLayout()
	if Bars.State and Bars.State.ForceApply then
		Bars.State.ForceApply()
	end
	Bars.ApplyActionbarsOptions()
	if Bars.Strip and Bars.Strip.WatchGamepad then
		Bars.Strip.WatchGamepad()
	end
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
	clients = { era = true, anniversary = true, classic = true, midnight = true },
	OnEnable = function()
		Bars.Start()
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

SLASH_FLUXBARS1 = "/fluxbars"
SlashCmdList["FLUXBARS"] = function(msg)
	msg = msg and msg:match("^%s*(.-)%s*$") or ""
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
