-- Perf.lua — idle-driver counters, pass timing, and form/page burst capture.
-- Counters are plain table increments; call them per pass, never per button.
local addonName, ns = ...
local Flux = ns.Flux

local Perf = {}
Flux.Perf = Perf
Flux.Engine = Flux.Engine or {}
Flux.Engine.Perf = Perf

local profilestop = debugprofilestop
local pairs = pairs
local type = type

local extra = {}
local passMs = {}
local passCalls = {}
local openPass = {}

function Perf.Count(key, amount)
	extra[key] = (extra[key] or 0) + (amount or 1)
end

--- Wall time of one pass, in ms. Begin/Stop pairs may not nest on the same key.
function Perf.Begin(key)
	if not profilestop then
		return
	end
	openPass[key] = profilestop()
end

function Perf.Stop(key)
	local started = openPass[key]
	if not started then
		return 0
	end
	openPass[key] = nil
	local ms = profilestop() - started
	passMs[key] = (passMs[key] or 0) + ms
	passCalls[key] = (passCalls[key] or 0) + 1
	return ms
end

-- ---------------------------------------------------------------------------
-- Burst capture
--
-- One shapeshift emits form + bonusbar + page + a dozen slot-changed events and
-- trails paint work for up to a second. Snapshot the counters when the first
-- event lands, diff them once it goes quiet: that difference is the cost of the
-- shift, separate from lifetime totals.
-- ---------------------------------------------------------------------------

local BURST_QUIET = 1.0

local burst
local lastBurst
local burstArmed = false

local function SnapshotInto(target)
	for key, value in pairs(extra) do
		target[key] = value
	end
end

local function SnapshotMsInto(target)
	for key, value in pairs(passMs) do
		target[key] = value
	end
end

local function Diff(now, before)
	local out = {}
	for key, value in pairs(now) do
		local delta = value - (before[key] or 0)
		if delta ~= 0 then
			out[key] = delta
		end
	end
	return out
end

local function CloseBurst()
	burstArmed = false
	if not burst then
		return
	end
	local now = (GetTime and GetTime()) or 0
	if now < burst.deadline then
		burstArmed = true
		Flux.Timer.After(burst.deadline - now, CloseBurst)
		return
	end
	lastBurst = {
		reason = burst.reason,
		events = burst.events,
		seconds = now - burst.opened,
		counts = Diff(extra, burst.counts),
		ms = Diff(passMs, burst.ms),
		calls = Diff(passCalls, burst.calls),
	}
	burst = nil
	if Perf.verbose then
		Perf.PrintLastBurst()
	end
end

--- Open (or extend) a measurement window. Cheap enough for an event handler.
function Perf.BeginBurst(reason)
	local now = (GetTime and GetTime()) or 0
	if not burst then
		burst = {
			reason = reason or "burst",
			opened = now,
			events = 0,
			counts = {},
			ms = {},
			calls = {},
		}
		SnapshotInto(burst.counts)
		SnapshotMsInto(burst.ms)
		for key, value in pairs(passCalls) do
			burst.calls[key] = value
		end
	end
	burst.events = burst.events + 1
	burst.deadline = now + BURST_QUIET
	if not burstArmed then
		burstArmed = true
		Flux.Timer.After(BURST_QUIET, CloseBurst)
	end
end

--- Keep an open burst alive for `seconds` more, for deferred work that belongs
--- to it (inventory settle pulse, budgeted queue). Does not open one.
function Perf.ExtendBurst(seconds)
	if not burst then
		return
	end
	local untilTime = ((GetTime and GetTime()) or 0) + (tonumber(seconds) or BURST_QUIET)
	if untilTime > burst.deadline then
		burst.deadline = untilTime
	end
end

function Perf.IsBursting()
	return burst ~= nil
end

function Perf.LastBurst()
	return lastBurst
end

function Perf.Reset()
	for key in pairs(extra) do
		extra[key] = nil
	end
	for key in pairs(passMs) do
		passMs[key] = nil
	end
	for key in pairs(passCalls) do
		passCalls[key] = nil
	end
	burst = nil
	lastBurst = nil
	if Perf.Regen and Perf.Regen.Reset then
		Perf.Regen.Reset()
	end
end

local function SortedKeys(tbl)
	local keys = {}
	for key in pairs(tbl) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

function Perf.PrintLastBurst()
	local report = lastBurst
	if not report then
		Flux.Print("no burst recorded yet — shift form, change page, or move an item, then run this again")
		return
	end
	Flux.Print("Last " .. tostring(report.reason) .. " burst")
	print(string.format("  events: %d over %.2fs", report.events or 0, report.seconds or 0))
	local msKeys = SortedKeys(report.ms)
	if #msKeys == 0 then
		print("  no timed passes")
	else
		local total = 0
		for i = 1, #msKeys do
			local key = msKeys[i]
			local ms = report.ms[key]
			total = total + ms
			print(string.format("  %-22s %7.2f ms  x%d", key, ms, report.calls[key] or 0))
		end
		print(string.format("  %-22s %7.2f ms", "TOTAL", total))
	end
	local countKeys = SortedKeys(report.counts)
	for i = 1, #countKeys do
		local key = countKeys[i]
		print(string.format("  %-22s %7d", key, report.counts[key]))
	end
end

function Perf.IsIdle()
	local tickerArmed = Flux.Ticker and Flux.Ticker.IsArmed()
	local timerPending = Flux.Timer and Flux.Timer.HasPendingPolyfill and Flux.Timer.HasPendingPolyfill()
	local schedPending = Flux.Scheduler and Flux.Scheduler.HasPending and Flux.Scheduler.HasPending()
	return (not tickerArmed) and (not timerPending) and (not schedPending)
end

-- ---------------------------------------------------------------------------
-- Regen capture
--
-- Always records the last PLAYER_REGEN_ENABLED: named samples during the
-- event tick vs the next-frame After(0) cascade. Dump with /fluxperf regen.
-- ---------------------------------------------------------------------------

local Regen = {}
Perf.Regen = Regen

local regenCapture
local regenBucket
local lastRegen

local function RegenAdd(name, ms)
	if not regenBucket or not name then
		return
	end
	local row = regenBucket[name]
	if not row then
		row = { ms = 0, n = 0 }
		regenBucket[name] = row
	end
	row.ms = row.ms + (ms or 0)
	row.n = row.n + 1
end

function Regen.Active()
	return regenBucket ~= nil
end

function Regen.OnRegen()
	local t0 = profilestop and profilestop() or 0
	regenCapture = {
		t0 = t0,
		keys = {},
		tick = {},
		after0 = {},
	}
	regenBucket = regenCapture.tick
	lastRegen = regenCapture
	local after = (Flux.Timer and Flux.Timer.After) or (C_Timer and C_Timer.After)
	if not after then
		return
	end
	after(0, function()
		if not regenCapture then
			return
		end
		regenCapture.tickWall = (profilestop and (profilestop() - regenCapture.t0)) or 0
		regenBucket = regenCapture.after0
		local t1 = profilestop and profilestop() or 0
		after(0, function()
			if not regenCapture then
				return
			end
			regenCapture.after0Wall = (profilestop and (profilestop() - t1)) or 0
			regenBucket = nil
		end)
	end)
end

function Regen.NoteFlushKeys(keys)
	if not regenCapture or regenBucket ~= regenCapture.tick then
		return
	end
	regenCapture.keys = keys or regenCapture.keys
end

function Regen.Begin(name)
	if not regenBucket or not profilestop then
		return nil
	end
	local t0 = profilestop()
	return function()
		RegenAdd(name, profilestop() - t0)
	end
end

function Regen.Time(name, fn, ...)
	if type(fn) ~= "function" then
		return
	end
	if not regenBucket or not profilestop then
		return fn(...)
	end
	local t0 = profilestop()
	local a, b, c, d = fn(...)
	RegenAdd(name, profilestop() - t0)
	return a, b, c, d
end

function Regen.Last()
	return lastRegen
end

function Regen.Reset()
	regenCapture = nil
	regenBucket = nil
	lastRegen = nil
end

local function PrintBucket(label, bucket, wall)
	print(string.format("  %s:", label))
	if type(bucket) ~= "table" then
		print("    (empty)")
		return
	end
	local keys = SortedKeys(bucket)
	if #keys == 0 then
		print("    (empty)")
	else
		local total = 0
		for i = 1, #keys do
			local key = keys[i]
			local row = bucket[key]
			local ms = row.ms or 0
			total = total + ms
			print(string.format("    %-28s %7.2f ms  x%d", key, ms, row.n or 0))
		end
		print(string.format("    %-28s %7.2f ms", "named total", total))
	end
	if wall then
		print(string.format("    %-28s %7.2f ms", "wall", wall))
	end
end

function Regen.Print()
	local report = lastRegen
	if not report then
		Flux.Print("no regen recorded yet — leave combat, then /fluxperf regen")
		return
	end
	local keys = report.keys or {}
	Flux.Print("Last PLAYER_REGEN_ENABLED")
	if #keys == 0 then
		print("  flush keys: (none)")
	else
		print("  flush keys: " .. table.concat(keys, ", "))
	end
	PrintBucket("same-tick", report.tick, report.tickWall)
	PrintBucket("next-frame", report.after0, report.after0Wall)
end

local regenHooksInstalled = false

local function HookRegen(obj, method, name)
	if not obj or type(obj[method]) ~= "function" then
		return
	end
	local orig = obj[method]
	obj[method] = function(...)
		return Regen.Time(name, orig, ...)
	end
end

function Regen.InstallHooks()
	if regenHooksInstalled then
		return
	end
	regenHooksInstalled = true
	local Bars = Flux.Bars
	if Bars then
		HookRegen(Bars.State, "ForceApply", "bars.ForceApply")
		HookRegen(Bars.Clicks, "ApplyRegistration", "bars.ApplyRegistration")
		HookRegen(Bars.Clicks, "ReassertEmpower", "bars.ReassertEmpower")
		HookRegen(Bars.Vehicle, "Apply", "bars.Vehicle.Apply")
	end
	HookRegen(_G.FluxCombatManager, "FinalizeLayout", "combat.FinalizeLayout")
	HookRegen(_G.FluxNCUtilitySlotsManager, "UpdateBindings", "utility.UpdateBindings")
	HookRegen(_G.FluxUnifiedBorder, "UpdateBorder", "unified.UpdateBorder")
	if type(_G.FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled) == "function" then
		local orig = _G.FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled
		_G.FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled = function(...)
			return Regen.Time("uf.SuppressBlizzard", orig, ...)
		end
	end
	if type(_G.FluxUnitFrames_UpdateAllEmulatedHorizontalSqueeze) == "function" then
		local orig = _G.FluxUnitFrames_UpdateAllEmulatedHorizontalSqueeze
		_G.FluxUnitFrames_UpdateAllEmulatedHorizontalSqueeze = function(...)
			return Regen.Time("uf.Squeeze", orig, ...)
		end
	end
end

function Perf.Snapshot()
	local ticker = Flux.Ticker
	local scheduler = Flux.Scheduler
	local combat = Flux.Combat
	local stats = scheduler and scheduler.Stats and scheduler.Stats() or {}
	return {
		idle = Perf.IsIdle(),
		tickerArmed = ticker and ticker.IsArmed() or false,
		tickerCount = ticker and ticker.Count() or 0,
		tickerTicks = ticker and ticker.Ticks() or 0,
		timerPolyfill = Flux.Timer and Flux.Timer.HasPendingPolyfill and Flux.Timer.HasPendingPolyfill() or false,
		schedulerPending = scheduler and scheduler.HasPending and scheduler.HasPending() or false,
		paging = scheduler and scheduler.IsPaging and scheduler.IsPaging() or false,
		combatLockdown = combat and combat.InLockdown and combat.InLockdown() or false,
		combatPending = combat and combat.PendingCount and combat.PendingCount() or 0,
		scheduler = stats,
		extra = extra,
		passMs = passMs,
		passCalls = passCalls,
		burst = lastBurst,
		regen = lastRegen,
	}
end

Flux.AfterLoad(function()
	if Flux.Scheduler then
		-- Dummy listeners: record flushes only. Feature work registers separately.
		local function count(tier)
			return function()
				Perf.Count("listener." .. tier)
			end
		end
		Flux.Scheduler.Register("layout", count("layout"))
		Flux.Scheduler.Register("eval", count("eval"))
		Flux.Scheduler.Register("structural", count("structural"))
		Flux.Scheduler.Register("inventory", count("inventory"))
	end

	-- Measure the shift independently of whoever coalesces it.
	local Ev = Flux.Events
	if Ev and Ev.Register then
		local function open(event)
			Perf.Count("event." .. event)
			Perf.BeginBurst("form/page")
		end
		Ev.Register("UPDATE_SHAPESHIFT_FORM", function(event)
			open(event)
		end)
		Ev.Register("UPDATE_BONUS_ACTIONBAR", function(event)
			open(event)
		end)
		Ev.Register("ACTIONBAR_PAGE_CHANGED", function(event)
			open(event)
		end)
		Ev.Register("UPDATE_STEALTH", function(event)
			open(event)
		end)
		Ev.Register("ACTIONBAR_SLOT_CHANGED", function()
			Perf.Count("event.ACTIONBAR_SLOT_CHANGED")
		end)
		-- Item drags: pickup and drop fire CURSOR_CHANGED, the drop fires the
		-- bag events, and the inventory settle pulse extends the same window.
		local function openDrag(event)
			Perf.Count("event." .. event)
			Perf.BeginBurst("bag/drag")
		end
		Ev.Register("CURSOR_CHANGED", openDrag)
		Ev.Register("BAG_UPDATE", openDrag)
		Ev.Register("PLAYERBANKSLOTS_CHANGED", openDrag)
	end
	Regen.InstallHooks()
end)
