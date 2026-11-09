-- FormStorm.lua — one coalescer for the shapeshift / stance / bonus-bar burst.
--
-- A single shift emits UPDATE_SHAPESHIFT_FORM + UPDATE_BONUS_ACTIONBAR +
-- ACTIONBAR_PAGE_CHANGED (+ UPDATE_STEALTH), and every module used to answer
-- all of them separately, so one shift ran the same relayout and repaint three
-- to five times. Modules subscribe here instead:
--
--   OnBurst(key, fn)    fn runs once, next frame, however many events landed
--   OnSettled(key, fn)  fn runs once after the burst goes quiet; receives one
--                       boolean arg `quiet` — true means no trailing event /
--                       edge landed after the burst flushed (skip re-work)
--
-- Repeat events carrying an unchanged form index / bonus offset / page are
-- ignored outright (ButtonForge Classic does the same), so Blizzard's idle
-- UPDATE_SHAPESHIFT_FORM spam costs nothing at all.
local addonName, ns = ...
local Flux = ns.Flux

local FormStorm = {}
Flux.FormStorm = FormStorm
Flux.Engine = Flux.Engine or {}
Flux.Engine.FormStorm = FormStorm

local pcall = pcall
local tonumber = tonumber
local type = type

--- Quiet time before the burst counts as finished. Long enough to cover the
--- trailing slot-changed / usable / cooldown tail, short enough to feel instant.
local SETTLE = 0.25

local burstQueued = false
local settleArmed = false
local settleUntil = 0
local trailing = false
local reason
local last = {}

local burstHandlers, burstOrder = {}, {}
local settleHandlers, settleOrder = {}, {}

local function Now()
	return (GetTime and GetTime()) or 0
end

local function Run(handlers, order, arg)
	for i = 1, #order do
		local fn = handlers[order[i]]
		if fn then
			Flux.Safecall(fn, arg)
		end
	end
end

local function RunBurst()
	burstQueued = false
	-- Anything landing from here on is trailing: the settle pass owns it.
	trailing = false
	if Flux.Perf then
		Flux.Perf.Count("formstorm.burst")
	end
	Run(burstHandlers, burstOrder)
end

local function RunSettle()
	local now = Now()
	if now < settleUntil then
		Flux.Timer.After(settleUntil - now, RunSettle)
		return
	end
	settleArmed = false
	if burstQueued then
		-- Burst flush has not run yet; let it own this window.
		RunBurst()
	end
	local quiet = not trailing
	trailing = false
	if Flux.Perf then
		Flux.Perf.Count("formstorm.settle")
		if quiet then
			Flux.Perf.Count("formstorm.settle.quiet")
		end
	end
	Run(settleHandlers, settleOrder, quiet)
	reason = nil
end

--- Open or extend the window. Safe to call from an event handler.
function FormStorm.Open(why)
	reason = why or reason or "form"
	-- Burst already flushed this window: this event is trailing change.
	if settleArmed and not burstQueued then
		trailing = true
	end
	settleUntil = Now() + SETTLE
	if Flux.Perf then
		Flux.Perf.Count("formstorm.open")
	end
	if not burstQueued then
		burstQueued = true
		Flux.Timer.Defer(RunBurst)
	end
	if not settleArmed then
		settleArmed = true
		Flux.Timer.After(SETTLE, RunSettle)
	end
end

--- True while burst handlers have not yet run (events still coalescing).
function FormStorm.IsBursting()
	return burstQueued
end

--- True while the burst window is open. Mid-burst work should be texture-only.
--- Extra Buttons / Binding must use this (or IsBursting) instead of FluxButtonEvents.
function FormStorm.IsSettling()
	return Now() < settleUntil
end

--- Last form / bonus / page / stealth snapshot. Repeat events with no change
--- never open a burst.
function FormStorm.GetSnapshot()
	return last.form, last.bonus, last.page, last.stealth
end

function FormStorm.Reason()
	return reason
end

function FormStorm.OnBurst(key, fn)
	if type(key) ~= "string" or type(fn) ~= "function" then
		return
	end
	if burstHandlers[key] == nil then
		burstOrder[#burstOrder + 1] = key
	end
	burstHandlers[key] = fn
end

function FormStorm.OnSettled(key, fn)
	if type(key) ~= "string" or type(fn) ~= "function" then
		return
	end
	if settleHandlers[key] == nil then
		settleOrder[#settleOrder + 1] = key
	end
	settleHandlers[key] = fn
end

-- ---------------------------------------------------------------------------
-- Edge detection
-- ---------------------------------------------------------------------------

local function Num(fn)
	if type(fn) ~= "function" then
		return 0
	end
	local ok, value = pcall(fn)
	if not ok then
		return 0
	end
	return tonumber(value) or 0
end

local function ReadForm()
	return Num(GetShapeshiftForm)
end

local function ReadBonus()
	return Num(GetBonusBarOffset)
end

local function ReadPage()
	if C_ActionBar and C_ActionBar.GetActionBarPage then
		return Num(C_ActionBar.GetActionBarPage)
	end
	return Num(GetActionBarPage)
end

local function ReadStealth()
	if type(IsStealthed) ~= "function" then
		return 0
	end
	local ok, value = pcall(IsStealthed)
	return (ok and value) and 1 or 0
end

local function Bit(fn)
	if type(fn) ~= "function" then
		return 0
	end
	local ok, value = pcall(fn)
	return (ok and value) and 1 or 0
end

--- has-vehicle .. has-override .. resolved possess page. Repeat vehicle /
--- override fires while sitting in the same vehicle carry the same signature.
local function ReadVehicle()
	local hasVeh = Bit(HasVehicleActionBar)
	local hasOv = Bit(HasOverrideActionBar)
	local page = 0
	if hasVeh == 1 then
		page = Num(GetVehicleBarIndex)
	elseif hasOv == 1 then
		page = Num(GetOverrideBarIndex)
	end
	return hasVeh .. hasOv .. tostring(page)
end

local EDGES = {
	{ event = "UPDATE_SHAPESHIFT_FORM", key = "form", read = ReadForm },
	{ event = "UPDATE_BONUS_ACTIONBAR", key = "bonus", read = ReadBonus },
	{ event = "ACTIONBAR_PAGE_CHANGED", key = "page", read = ReadPage },
	{ event = "UPDATE_STEALTH", key = "stealth", read = ReadStealth },
	-- Vehicle / override swaps page the same way a form does; both events
	-- share one signature so neither reopens a burst without a real change.
	{ event = "UPDATE_OVERRIDE_ACTIONBAR", key = "vehicle", read = ReadVehicle },
	{ event = "UPDATE_VEHICLE_ACTIONBAR", key = "vehicle", read = ReadVehicle },
	-- These often land before UPDATE_VEHICLE_ACTIONBAR; same signature so a
	-- later bar event does not reopen. Opens the window in time to hold
	-- UNIT_DISPLAYPOWER / SPELL_UPDATE_USABLE companions.
	{ event = "VEHICLE_UPDATE", key = "vehicle", read = ReadVehicle },
	{ event = "UNIT_ENTERED_VEHICLE", key = "vehicle", read = ReadVehicle, player = true },
	{ event = "UNIT_EXITED_VEHICLE", key = "vehicle", read = ReadVehicle, player = true },
}

function FormStorm.Sync()
	for i = 1, #EDGES do
		local edge = EDGES[i]
		last[edge.key] = edge.read()
	end
end

Flux.AfterLoad(function()
	local Ev = Flux.Events
	if not Ev or not Ev.Register then
		return
	end
	FormStorm.Sync()

	for i = 1, #EDGES do
		local edge = EDGES[i]
		Ev.Register(edge.event, function(event, unit)
			if edge.player and unit and unit ~= "player" then
				return
			end
			local value = edge.read()
			if last[edge.key] == value then
				if Flux.Perf then
					Flux.Perf.Count("formstorm.ignored")
				end
				return
			end
			last[edge.key] = value
			FormStorm.Open(event)
		end)
	end

	Ev.Register("PLAYER_ENTERING_WORLD", FormStorm.Sync)
end)
