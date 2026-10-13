-- Range.lua — one range service for the action strip, Extra buttons and badges.
--
-- Before this there were two independent loops: Bars/Watch.lua polled 57 hosts
-- with a unit-less IsActionInRange, and ExtraButtonSystem/Engine/Range.lua
-- polled every EBS button (including every corner badge) 50ms out of phase.
-- Both re-resolved the same spells against the same unit dozens of times per
-- tick. This owns the single ticker and a shared memo so a spell that sits on
-- the main row, a mini row and two badges is probed once, not four times.
--
-- Surfaces keep their own walk (their button tables differ) and register it as
-- a sweep. Probes go through Range.CheckSpell / CheckItem / CheckAction so they
-- share the memo.
local addonName, ns = ...
local Flux = ns.Flux

local Range = {}
Flux.Range = Range
Flux.Engine = Flux.Engine or {}
Flux.Engine.Range = Range

local INTERVAL = 0.25
local extraInterval = 0.18
local TICKER_KEY = "flux.range"
local MOUSEOVER_BURST = 0.2

local sweeps = {}
local sweepOrder = {}
local armed = false
local accum = 0
local extraAccum = 0
local lastTargetReaction = nil
local lastMoAt = 0

local function ClampInterval(sec, lo, hi, fallback)
	sec = tonumber(sec)
	if not sec then
		return fallback
	end
	if sec < lo then
		return lo
	end
	if sec > hi then
		return hi
	end
	return sec
end

function Range.SetInterval(sec)
	INTERVAL = ClampInterval(sec, 0.1, 1.0, INTERVAL)
end

function Range.GetInterval()
	return INTERVAL
end

function Range.SetExtraInterval(sec)
	extraInterval = ClampInterval(sec, 0.1, 1.0, extraInterval)
end

function Range.GetExtraInterval()
	return extraInterval
end

-- Memo lives for one frame. A sweep only requests a paint, so the probes land
-- later in the same frame; keying on GetTime() is what lets the strip, the mini
-- rows and the badges share one answer no matter who asks first.
-- A spell that reports nil against a friendly unit can report a number against
-- a hostile one, so "this spell has no range" is never cached across frames.
local memo = {}
local memoFrame = nil
local NILV = {}

local ueMemo = {}
local ueFrame = nil

local function UnitExistsSafe(unit)
	if not unit or not UnitExists then
		return false
	end
	local now = GetTime and GetTime() or 0
	if now ~= ueFrame then
		ueFrame = now
		if wipe then wipe(ueMemo) else ueMemo = {} end
	end
	local cached = ueMemo[unit]
	if cached ~= nil then
		return cached
	end
	local ok, exists = pcall(UnitExists, unit)
	local res = ok and exists and true or false
	ueMemo[unit] = res
	return res
end

local function Normalize(v)
	local S = Flux.Secrets
	if S and S.NormalizeTriBool then
		return S.NormalizeTriBool(v)
	end
	if v == true or v == 1 then
		return true
	end
	if v == false or v == 0 then
		return false
	end
	return nil
end

-- ---------------------------------------------------------------------------
-- Unit resolution — the one rule every surface follows
-- ---------------------------------------------------------------------------

local function MouseoverCastOn()
	local MC = Flux.MouseoverCast
	return MC and MC.IsEnabled and MC.IsEnabled() and true or false
end

--- Mouseover is a range unit only when the global toggle is on, or when this
--- button's own macro / binding actually resolved `@mouseover`. A leftover
--- secure `unit` from the toggle being on last session must not paint OOR
--- on a plain spell once the toggle is off.
local function AllowUnit(unit, macroUnit)
	if type(unit) ~= "string" or unit == "" or unit == "player" or unit == "cursor" then
		return nil
	end
	if string.lower(unit) ~= "mouseover" then
		return unit
	end
	if MouseoverCastOn() then
		return unit
	end
	if type(macroUnit) == "string" and string.lower(macroUnit) == "mouseover" then
		return unit
	end
	return nil
end

--- A compiled macro / overlay already chose its `@unit`. That wins over a
--- live or leftover mouseover-cast `unit` on the same widget, because the
--- click follows the body, not the hub. Callers pass `widget = nil` for
--- macros so a leftover hub unit cannot tint them. Plain spells pass
--- `macroUnit = nil` and use the widget attribute, gated so leftover
--- `unit=mouseover` is ignored while the toggle is off.
--- `player` / `cursor` are not range-checkable, so they fall through.
function Range.ResolveUnit(widget, macroUnit)
	local mu = AllowUnit(macroUnit, macroUnit)
	if mu then
		return mu
	end
	if widget and widget.GetAttribute then
		local ok, u = pcall(widget.GetAttribute, widget, "unit")
		if ok then
			u = AllowUnit(u, nil)
			if u and UnitExistsSafe(u) then
				return u
			end
		end
	end
	-- Toggle on, plain spell/item (callers pass the widget), hub unit not
	-- landed yet: range cursor unit during unit frame hovercast. Not during
	-- 3D world hop storms — flipping all 57 buttons on world mouseover is the Paint hitch.
	local peeking = Flux.Context and Flux.Context.IsUfPeek and Flux.Context.IsUfPeek()
	if widget and MouseoverCastOn() and peeking and not Range.IsHopBurst() and UnitExistsSafe("mouseover") then
		return "mouseover"
	end
	return "target"
end

-- ---------------------------------------------------------------------------
-- Memoized probes
-- ---------------------------------------------------------------------------

local function Memo(key, fn)
	local now = GetTime and GetTime() or nil
	if now ~= memoFrame then
		memoFrame = now
		if wipe then
			wipe(memo)
		else
			memo = {}
		end
	end
	local cached = memo[key]
	if cached ~= nil then
		if cached == NILV then
			return nil
		end
		return cached
	end
	local r = fn()
	memo[key] = (r == nil) and NILV or r
	return r
end

function Range.CheckSpell(ident, unit)
	if ident == nil or ident == "" or not unit then
		return nil
	end
	if not UnitExistsSafe(unit) then
		return nil
	end
	return Memo("s\1" .. tostring(ident) .. "\1" .. unit, function()
		local S = Flux.Spell
		if not (S and S.IsInRange) then
			return nil
		end
		local ok, r = pcall(S.IsInRange, ident, unit)
		if not ok then
			return nil
		end
		return r
	end)
end

--- Second return true means "cannot check right now, keep the last result"
--- (combat blocks friendly item range).
function Range.CheckItem(itemId, unit)
	if not itemId or not unit then
		return nil
	end
	if not UnitExistsSafe(unit) then
		return nil
	end
	local I = Flux.Item
	if not (I and I.IsInRange) then
		return nil
	end
	if I.CanCheckRange and not I.CanCheckRange(unit) then
		return nil, true
	end
	return Memo("i\1" .. tostring(itemId) .. "\1" .. unit, function()
		local ok, r = pcall(I.IsInRange, itemId, unit)
		if not ok then
			return nil
		end
		return r
	end)
end

function Range.CheckAction(slot, unit)
	slot = tonumber(slot)
	if not slot then
		return nil
	end
	unit = unit or "target"
	if not UnitExistsSafe(unit) then
		return nil
	end
	return Memo("a\1" .. slot .. "\1" .. unit, function()
		if not IsActionInRange then
			return nil
		end
		-- Passing the unit matters: the no-arg form always answers for "target",
		-- which is wrong for mouseover-cast and for an @mouseover overlay.
		local ok, r = pcall(IsActionInRange, slot, unit)
		if not ok then
			return nil
		end
		return Normalize(r)
	end)
end

-- ---------------------------------------------------------------------------
-- Sweeps
-- ---------------------------------------------------------------------------

--- need() answers "does this surface have anything to range right now".
--- sweep() repaints it.
function Range.RegisterSweep(key, needFn, sweepFn)
	if type(key) ~= "string" or type(needFn) ~= "function" or type(sweepFn) ~= "function" then
		return
	end
	if not sweeps[key] then
		sweepOrder[#sweepOrder + 1] = key
	end
	sweeps[key] = { need = needFn, sweep = sweepFn }
	Range.Sync()
end

local function AnyNeed()
	for i = 1, #sweepOrder do
		local rec = sweeps[sweepOrder[i]]
		if rec then
			local ok, need = pcall(rec.need)
			if ok and need then
				return true
			end
		end
	end
	return false
end

local function RunSweeps(runBars, runExtra)
	if runBars == nil then
		runBars = true
	end
	if runExtra == nil then
		runExtra = true
	end
	for i = 1, #sweepOrder do
		local key = sweepOrder[i]
		local rec = sweeps[key]
		if rec then
			if key == "ebs" then
				if runExtra then
					pcall(rec.sweep)
				end
			elseif runBars then
				pcall(rec.sweep)
			end
		end
	end
end

local function OnTick(elapsed)
	-- Every client: do not walk strip+Extra+badges while the cursor is hopping.
	local now = (GetTime and GetTime()) or 0
	if lastMoAt > 0 and (now - lastMoAt) < MOUSEOVER_BURST then
		return
	end
	elapsed = elapsed or 0
	accum = accum + elapsed
	extraAccum = extraAccum + elapsed
	local barsDue = accum >= INTERVAL
	local extraDue = extraAccum >= extraInterval
	if not barsDue and not extraDue then
		return
	end
	if barsDue then
		accum = 0
	end
	if extraDue then
		extraAccum = 0
	end
	if not AnyNeed() then
		-- One last pass so a button that went out of scope drops its red tint,
		-- then disarm. The old strip loop returned here without repainting,
		-- which is how a stale out-of-range tint could stick after a detarget.
		RunSweeps(true, true)
		Range.Sync()
		return
	end
	RunSweeps(barsDue, extraDue)
end

function Range.Sync()
	local need = AnyNeed()
	if need and not armed then
		armed = true
		accum = INTERVAL
		if Flux.Ticker and Flux.Ticker.Add then
			Flux.Ticker.Add(TICKER_KEY, OnTick)
		end
	elseif (not need) and armed then
		armed = false
		accum = 0
		if Flux.Ticker and Flux.Ticker.Remove then
			Flux.Ticker.Remove(TICKER_KEY)
		end
	end
end

function Range.IsArmed()
	return armed and true or false
end

--- True while the cursor is hopping unit↔gap. Watch/Paint must not treat
--- ACTIONBAR_SLOT_CHANGED / UPDATE_USABLE storms from that as real slot edits.
function Range.IsHopBurst(window)
	window = tonumber(window) or MOUSEOVER_BURST
	if lastMoAt <= 0 then
		return false
	end
	local now = (GetTime and GetTime()) or 0
	return (now - lastMoAt) < window
end

--- Resample now instead of waiting up to 200ms. This is the rapid target-swap
--- path: the tint must land on the frame the target changed, not a tick later.
function Range.Invalidate()
	accum = 0
	RunSweeps()
	Range.Sync()
end

function Range.InvalidateSweep(key)
	local rec = key and sweeps[key]
	if rec then
		pcall(rec.sweep)
	end
	Range.Sync()
end

-- ---------------------------------------------------------------------------
-- Mouseover coalescing
-- ---------------------------------------------------------------------------

function Range.UnitReactionClass(unit)
	unit = unit or "target"
	if not UnitExistsSafe(unit) then
		return "-"
	end
	if UnitIsDead and UnitIsDead(unit) then
		return "d"
	end
	if UnitCanAttack and UnitCanAttack("player", unit) then
		return "e"
	end
	if UnitCanAssist and UnitCanAssist("player", unit) then
		return "f"
	end
	return "o"
end

local function MouseoverReactionClass()
	return Range.UnitReactionClass("mouseover")
end

Range.MouseoverReactionClass = MouseoverReactionClass

function Range.TargetReactionClass()
	return Range.UnitReactionClass("target")
end

local function NeedsMouseoverRange()
	if MouseoverCastOn() then
		return true
	end
	local PF = Flux.Bars and Flux.Bars.ProgramFace
	return (PF and PF.Needs and PF.Needs("mouseover")) and true or false
end

local function MouseoverBurst()
	local now = (GetTime and GetTime()) or 0
	if (now - lastMoAt) < MOUSEOVER_BURST then
		return true
	end
	return UnitExistsSafe("mouseover") and NeedsMouseoverRange()
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

local started = false

function Range.Start()
	if started then
		return
	end
	started = true
	local Ev = Flux.Events
	if not (Ev and Ev.Register) then
		return
	end
	Ev.Register("PLAYER_TARGET_CHANGED", function()
		local class = Range.TargetReactionClass()
		if class == lastTargetReaction then
			return
		end
		lastTargetReaction = class
		Range.Invalidate()
	end)
	Ev.Register("PLAYER_FOCUS_CHANGED", function()
		Range.Invalidate()
	end)
	-- Stamp only. Fast unit↔gap sweeps fire this dozens of times a second;
	-- walking 57 hosts here is the hitch. Distance stays on the 0.2s ticker.
	Ev.Register("UPDATE_MOUSEOVER_UNIT", function()
		lastMoAt = (GetTime and GetTime()) or 0
	end)
	Ev.Register("ACTION_RANGE_CHECK_UPDATE", function(_, slot, isInRange, checksRange)
		if MouseoverBurst() then
			return
		end
		local Bars = Flux.Bars
		if Bars and Bars.Paint and Bars.Paint.ApplySlotRange then
			Bars.Paint.ApplySlotRange(slot, isInRange, checksRange)
			return
		end
		Range.Invalidate()
	end)
	Ev.Register("PLAYER_ENTERING_WORLD", function()
		lastMoAt = 0
		lastTargetReaction = nil
		Range.Sync()
	end)
	-- Talent / form swaps re-point override spells, so the next pass must not
	-- reuse anything resolved from the old face.
	local function Refresh()
		lastMoAt = 0
		Range.Sync()
	end
	Ev.Register("SPELLS_CHANGED", Refresh)
	Ev.Register("PLAYER_SPECIALIZATION_CHANGED", Refresh)
	Ev.Register("TRAIT_CONFIG_UPDATED", Refresh)
	Ev.Register("UPDATE_SHAPESHIFT_FORM", Refresh)
end
