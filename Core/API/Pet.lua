-- Pet.lua — GetPetAction* pass-through. Do not compare secret numbers.
local addonName, ns = ...
local Flux = ns.Flux

local Pet = {}
Flux.Pet = Pet
Flux.API = Flux.API or {}
Flux.API.Pet = Pet

local function UnpackInfo(a, b, c, d, e, f, g)
	if type(a) == "table" then
		local t = a
		return t.name, t.texture, t.isToken, t.isActive, t.autoCastAllowed, t.autoCastEnabled, t.spellID or t.spellId
	end
	return a, b, c, d, e, f, g
end

local function UnpackCooldown(a, b, c)
	if type(a) == "table" then
		return a.startTime or a.start, a.duration, a.isEnabled or a.enable
	end
	return a, b, c
end

function Pet.GetActionInfo(slot)
	if not slot or not GetPetActionInfo then
		return nil
	end
	local ok, a, b, c, d, e, f, g = pcall(GetPetActionInfo, slot)
	if not ok then
		return nil
	end
	return UnpackInfo(a, b, c, d, e, f, g)
end

function Pet.GetActionCooldown(slot)
	if not slot or not GetPetActionCooldown then
		return 0, 0, 0
	end
	local ok, a, b, c = pcall(GetPetActionCooldown, slot)
	if not ok then
		return 0, 0, 0
	end
	return UnpackCooldown(a, b, c)
end

function Pet.IsSlotUsable(slot)
	if slot and GetPetActionSlotUsable then
		local ok, usable = pcall(GetPetActionSlotUsable, slot)
		if ok then
			return usable and true or false
		end
	end
	if GetPetActionsUsable then
		local ok, usable = pcall(GetPetActionsUsable)
		if ok then
			return usable and true or false
		end
	end
	return true
end

function Pet.IsAttackAction(slot)
	if not slot or not IsPetAttackAction then
		return false
	end
	local ok, v = pcall(IsPetAttackAction, slot)
	return ok and v and true or false
end
