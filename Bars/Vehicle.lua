-- Bars/Vehicle.lua — Flux strip stays shown in vehicle/override and pages
-- those slots. Blizzard OverrideActionBar stays Blizzard-owned AND visible
-- (never Hide / SetParent / SetAlpha / EnableMouse / OnShow / hooksecurefunc).
-- Work on the vehicle event itself taints UIParent_ManageFramePositions
-- (RightManagedFrameContainer:SetSize). Leftover alpha runs on the next tick.
--
-- ActionBarButtonEventsFrame / ActionBarActionEventsFrame walk leftover
-- ActionButton1-12 and OverrideActionBarButtonN. Flux has written those
-- frames tables (nil leftovers / Sweep), so every later dispatch is tainted:
--   ACTIONBAR_SLOT_CHANGED → Update → SetAttribute (combat block)
--   ACTIONBAR_UPDATE_COOLDOWN / SPELL_UPDATE_ICON → SetCooldown secrets
-- PLAYER_REGEN_DISABLED loses the race with SLOT_CHANGED on the same frame,
-- so drop the protected events at file load and never re-register.
-- OverrideActionBar:Setup still updates those buttons from Blizzard's own
-- UNIT_ENTERED_VEHICLE. Do not re-arm the collectors: that registration is
-- ours and would taint Setup → ValidateActionBarTransition → SetShownBase.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Vehicle = {}
Bars.Vehicle = Vehicle

local applyQueued = false
local pendingCombatApply = false
local pendingForceRestamp = false
local lastApplySig = nil

local CAB = C_ActionBar or {}
local HasVehicleActionBar = CAB.HasVehicleActionBar or _G.HasVehicleActionBar
local HasOverrideActionBar = CAB.HasOverrideActionBar or _G.HasOverrideActionBar
local HasTempShapeshiftActionBar = CAB.HasTempShapeshiftActionBar or _G.HasTempShapeshiftActionBar
local HasBonusActionBar = CAB.HasBonusActionBar or _G.HasBonusActionBar
local IsPossessBarVisible = CAB.IsPossessBarVisible or _G.IsPossessBarVisible
local GetVehicleBarIndex = CAB.GetVehicleBarIndex or _G.GetVehicleBarIndex
local GetOverrideBarIndex = CAB.GetOverrideBarIndex or _G.GetOverrideBarIndex
local GetTempShapeshiftBarIndex = CAB.GetTempShapeshiftBarIndex or _G.GetTempShapeshiftBarIndex
local GetBonusBarIndex = CAB.GetBonusBarIndex or _G.GetBonusBarIndex

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local function Bit(fn)
	if type(fn) ~= "function" then
		return 0
	end
	local ok, v = pcall(fn)
	return (ok and v) and 1 or 0
end

local function Num(fn)
	if type(fn) ~= "function" then
		return 0
	end
	local ok, v = pcall(fn)
	if not ok then
		return 0
	end
	return tonumber(v) or 0
end

-- Same precedence as the secure page resolver, including bonus-page possession
-- (Mind Control / Chess on Forever) and temporary shapeshifts.
local function ControlPage()
	if Bit(HasVehicleActionBar) == 1 then return Num(GetVehicleBarIndex) end
	if Bit(HasOverrideActionBar) == 1 then return Num(GetOverrideBarIndex) end
	if Bit(HasTempShapeshiftActionBar) == 1 then return Num(GetTempShapeshiftBarIndex) end
	if Bit(HasBonusActionBar) == 1 then return Num(GetBonusBarIndex) end
	if Bit(IsPossessBarVisible) == 1 then return 11 end
	return 0
end

local function DriverAlreadyPaged()
	local State = Bars.State
	if not (State and State.GetCurrentPage) then
		return false
	end
	local page = State.GetCurrentPage()
	local active = ControlPage()
	if active > 0 then return page == active end
	return page < 11
end

--- Possession can change without either vehicle/override bit changing. Keep it
--- in the snapshot so UPDATE_POSSESS_BAR refreshes both entry and exit; repeat
--- notifications within an unchanged state still skip the full restamp.
local function VehicleSig()
	return Bit(HasVehicleActionBar) .. Bit(HasOverrideActionBar)
		.. Bit(HasTempShapeshiftActionBar) .. Bit(HasBonusActionBar)
		.. Bit(IsPossessBarVisible) .. ":" .. ControlPage()
end

local function HoldCollectorEvents()
	-- A fresh combat login must retain Blizzard's working input/update path
	-- until Flux has finished its protected replacements.
	if Bars.secureReady == false then return end
	-- Forever's native controller must still receive possession/exit updates.
	-- Its Flux hosts do not enter these shared collectors.
	if Flux.Action and Flux.Action.LeaveBlizzardCollector and Flux.Action.LeaveBlizzardCollector() then return end
	local buttonEvents = _G.ActionBarButtonEventsFrame
	if type(buttonEvents) == "table" and buttonEvents.UnregisterEvent then
		pcall(buttonEvents.UnregisterEvent, buttonEvents, "ACTIONBAR_SLOT_CHANGED")
		pcall(buttonEvents.UnregisterEvent, buttonEvents, "ACTIONBAR_UPDATE_COOLDOWN")
		pcall(buttonEvents.UnregisterEvent, buttonEvents, "PLAYER_ENTERING_WORLD")
	end
	-- SPELL_UPDATE_ICON / PET_STABLE_* / vehicle unit events all call mixin
	-- Update → ActionButton_ApplyCooldown. UnregisterAllEvents: never re-register
	-- (addon RegisterEvent would keep the dispatch tainted).
	local actionEvents = _G.ActionBarActionEventsFrame
	if type(actionEvents) == "table" and actionEvents.UnregisterAllEvents then
		pcall(actionEvents.UnregisterAllEvents, actionEvents)
	end
end
Vehicle.OnReplacementsReady = function()
	HoldCollectorEvents()
	if Vehicle.QueueApply then Vehicle.QueueApply(true) end
end

-- File load: collectors already registered these in OnLoad.
HoldCollectorEvents()

local function SweepCollectorsOOC()
	if InLockdown() then
		return
	end
	if Flux.Action and Flux.Action.SweepFluxFromCollectors then
		Flux.Action.SweepFluxFromCollectors()
	end
end

local function ShowFluxStrip()
	if Bars.Strip and Bars.Strip.SyncVisibility then
		Bars.Strip.SyncVisibility()
	end
end

function Vehicle.Apply()
	if Bars.secureReady == false then return false end
	SweepCollectorsOOC()
	ShowFluxStrip()
	-- Paging in combat is RegisterStateDriver only. Execute from this
	-- insecure tick blocks SecureHandlersUpdateFrame:SetAttribute and
	-- kills SHIFT/CTRL swap until reload. Do not assign widget.bar: mixin
	-- UpdateFlyout calls bar:GetSpellFlyoutDirection() and a Flux header
	-- is not an ActionBar (UseAction taint).
	local force = pendingForceRestamp or pendingCombatApply
	pendingForceRestamp = false
	if not InLockdown() then
		pendingCombatApply = false
		if force or not DriverAlreadyPaged() then
			if Bars.State and Bars.State.ForceApply then
				Bars.State.ForceApply()
			end
		end
	end
	-- FormStorm burst owns strip paint. Do not 57-host RequestPaint here.
	if Bars.Blizzard and Bars.Blizzard.QueueLeftoverMouse then
		Bars.Blizzard.QueueLeftoverMouse()
	end
	lastApplySig = VehicleSig()
	if Bars.State and Bars.State.IndexLiveSlots then Bars.State.IndexLiveSlots() end
	if Bars.RequestPaint then Bars.RequestPaint("bars.dirty") end
end

function Vehicle.QueueApply(forceRestamp)
	if forceRestamp then
		pendingForceRestamp = true
	end
	if InLockdown() then
		pendingCombatApply = true
	end
	if applyQueued then
		return
	end
	applyQueued = true
	local function run()
		applyQueued = false
		Vehicle.Apply()
	end
	if Flux.Timer and Flux.Timer.Defer then
		Flux.Timer.Defer(run)
	elseif C_Timer and C_Timer.After then
		C_Timer.After(0, run)
	else
		run()
	end
end

local function OnVehicleEvent(_, unit)
	if unit and unit ~= "player" then
		return
	end
	-- Undeferred: vehicle SLOT_CHANGED / SPELL_UPDATE_ICON can land here.
	HoldCollectorEvents()
	-- Snapshot unchanged since the last apply: nothing to restamp. A pending
	-- combat apply must still queue so the regen flush has work to pick up.
	if not pendingCombatApply and lastApplySig and VehicleSig() == lastApplySig then
		return
	end
	Vehicle.QueueApply()
end

function Vehicle.Start()
	if Vehicle.started then
		return
	end
	Vehicle.started = true

	HoldCollectorEvents()

	local Ev = Flux.Events
	if Ev and Ev.Register then
		Ev.Register("UNIT_ENTERED_VEHICLE", OnVehicleEvent)
		Ev.Register("UNIT_EXITED_VEHICLE", OnVehicleEvent)
		Ev.Register("UPDATE_VEHICLE_ACTIONBAR", OnVehicleEvent)
		Ev.Register("UPDATE_OVERRIDE_ACTIONBAR", OnVehicleEvent)
		Ev.Register("UPDATE_POSSESS_BAR", OnVehicleEvent)
		Ev.Register("UPDATE_BONUS_ACTIONBAR", function() Vehicle.QueueApply() end)
		Ev.Register("PLAYER_CONTROL_LOST", function() Vehicle.QueueApply() end)
		Ev.Register("PLAYER_CONTROL_GAINED", function() Vehicle.QueueApply() end)
		-- Entering world flushes unconditionally: a loading screen can change
		-- slot contents behind an unchanged vehicle signature.
		Ev.Register("PLAYER_ENTERING_WORLD", function()
			HoldCollectorEvents()
			Vehicle.QueueApply(true)
		end)
		Ev.Register("VEHICLE_UPDATE", OnVehicleEvent)
		Ev.Register("PLAYER_REGEN_DISABLED", HoldCollectorEvents)
		Ev.Register("ADDON_LOADED", function(_, name)
			if name == "Blizzard_ActionBar" then
				HoldCollectorEvents()
			end
		end)
		Ev.Register("PLAYER_REGEN_ENABLED", function()
			HoldCollectorEvents()
			if pendingCombatApply then
				Vehicle.QueueApply()
			end
		end)
	end

	Vehicle.QueueApply(true)
end
