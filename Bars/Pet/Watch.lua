-- Bars/Pet/Watch.lua — event split: full paint vs usable vs cooldown. No aura full rebuild.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Pet = Bars.Pet or {}
Bars.Pet = Pet

local Watch = {}
Pet.Watch = Watch

local started = false
local fullPending = false
local lastPetExists

local function After0(fn)
	if Flux.Timer and Flux.Timer.Defer then
		Flux.Timer.Defer(fn)
	elseif C_Timer and C_Timer.After then
		C_Timer.After(0, fn)
	else
		fn()
	end
end

local function FlushFull()
	fullPending = false
	if Pet.ForAll then
		Pet.ForAll("Update")
	end
end

local function ScheduleFull()
	if fullPending then
		return
	end
	fullPending = true
	After0(FlushFull)
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

	local function OnFull()
		ScheduleFull()
	end

	Ev.Register("PET_BAR_UPDATE", OnFull)
	Ev.Register("PET_UI_UPDATE", OnFull)
	Ev.Register("PLAYER_FARSIGHT_FOCUS_CHANGED", OnFull)
	Ev.Register("PLAYER_MOUNT_DISPLAY_CHANGED", OnFull)
	Ev.Register("UNIT_FLAGS", function(_, unit)
		if unit == "pet" then
			ScheduleFull()
		end
	end)
	Ev.Register("UNIT_PET", function(_, unit)
		if unit ~= "player" then
			return
		end
		local exists = UnitExists and UnitExists("pet") or false
		if lastPetExists == nil or lastPetExists ~= exists then
			lastPetExists = exists
			ScheduleFull()
			if Pet.UpdatePosition then
				Pet.UpdatePosition()
			end
		elseif Pet.ForAll then
			Pet.ForAll("UpdateUsable")
		end
	end)

	local function OnUsable()
		if Pet.ForAll then
			Pet.ForAll("UpdateUsable")
		end
	end
	Ev.Register("PET_BAR_UPDATE_USABLE", OnUsable)
	Ev.Register("PLAYER_TARGET_CHANGED", OnUsable)
	Ev.Register("UPDATE_VEHICLE_ACTIONBAR", OnUsable)
	Ev.Register("PLAYER_CONTROL_LOST", OnUsable)
	Ev.Register("PLAYER_CONTROL_GAINED", OnUsable)

	if Ev.RegisterUnit then
		Ev.RegisterUnit("UNIT_AURA", "pet", function()
			if Pet.ForAll then
				Pet.ForAll("UpdateUsable")
			end
		end)
	end

	Ev.Register("PET_BAR_UPDATE_COOLDOWN", function()
		if Pet.ForAll then
			Pet.ForAll("UpdateCooldown")
		end
	end)
	Ev.Register("PET_BAR_SHOWGRID", function()
		if Pet.ForAll then
			Pet.ForAll("ShowGrid")
		end
	end)
	Ev.Register("PET_BAR_HIDEGRID", function()
		if Pet.ForAll then
			Pet.ForAll("HideGrid")
		end
	end)
	Ev.Register("UPDATE_BINDINGS", function()
		if Pet.SetupKeybindings then
			Pet.SetupKeybindings()
		end
	end)
	Ev.Register("PLAYER_ENTERING_WORLD", function()
		ScheduleFull()
		if Pet.UpdatePosition then
			Pet.UpdatePosition()
		end
		if Pet.SetupKeybindings then
			Pet.SetupKeybindings()
		end
	end)
	Ev.Register("PLAYER_REGEN_ENABLED", function()
		if Pet.FlushBindingModePending then
			Pet.FlushBindingModePending()
		end
	end)
end
