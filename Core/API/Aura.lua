-- Aura.lua — C_UnitAuras vs UnitAura (UnitAura is gone on Midnight)
local addonName, ns = ...
local Flux = ns.Flux

local Aura = {}
Flux.Aura = Aura
Flux.API = Flux.API or {}
Flux.API.Aura = Aura

local Cap = Flux.Cap

local function SecretsAccessible()
	local S = Flux.Secrets
	if S and S.CanAccessSecrets and not S.CanAccessSecrets() then
		return false
	end
	return true
end

function Aura.GetSlots(unit, filter)
	if not unit then
		return {}, true
	end
	if not SecretsAccessible() then
		return nil, false
	end
	if not Cap.hasC_UnitAuras_GetAuraSlots then
		return {}, true
	end
	local packed = { pcall(C_UnitAuras.GetAuraSlots, unit, filter) }
	if not packed[1] then
		return nil, false
	end
	if type(packed[2]) == "table" then
		local S = Flux.Secrets
		if S and ((S.IsSecretTable and S.IsSecretTable(packed[2])) or (S.CanAccessTable and not S.CanAccessTable(packed[2]))) then
			return nil, false
		end
		return packed[2], true
	end
	-- continuationToken, slot, slot, ...
	local slots = {}
	for i = 3, #packed do
		slots[#slots + 1] = packed[i]
	end
	return slots, true
end

function Aura.GetDataBySlot(unit, slot)
	if not unit then
		return nil
	end
	if not SecretsAccessible() then
		return nil
	end
	if Cap.hasC_UnitAuras_GetAuraDataBySlot then
		local ok, data = pcall(C_UnitAuras.GetAuraDataBySlot, unit, slot)
		if ok then
			return data
		end
		return nil
	end
	return nil
end

function Aura.GetDataByIndex(unit, index, filter)
	if not unit then
		return nil
	end
	if not SecretsAccessible() then
		return nil
	end
	if Cap.hasC_UnitAuras_GetAuraDataByIndex then
		local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
		if ok then
			return data
		end
		return nil
	end
	-- UnitAura was removed on Midnight (12.0+); only use when still present.
	if not UnitAura then
		return nil
	end
	local ok, name, icon, count, dispelType, duration, expirationTime, source, isStealable,
		nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod =
		pcall(UnitAura, unit, index, filter)
	if not ok or not name then
		return nil
	end
	return {
		name = name,
		icon = icon,
		applications = count,
		dispelName = dispelType,
		duration = duration,
		expirationTime = expirationTime,
		sourceUnit = source,
		isStealable = isStealable,
		nameplateShowPersonal = nameplateShowPersonal,
		spellId = spellId,
		canApplyAura = canApplyAura,
		isBossAura = isBossDebuff,
		isFromPlayerOrPlayerPet = castByPlayer,
		nameplateShowAll = nameplateShowAll,
		timeMod = timeMod,
	}
end

function Aura.GetDataByInstanceID(unit, auraInstanceID)
	if not unit or not Cap.hasC_UnitAuras_GetAuraDataByAuraInstanceID then
		return nil
	end
	if not SecretsAccessible() then
		return nil
	end
	local ok, data = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, unit, auraInstanceID)
	if ok then
		return data
	end
	return nil
end

-- AllowedWhenTainted + RequiresNonSecretAura: returns nil instead of a secret
-- table. Do not gate on CanAccessSecrets (that is the tainted combat default).
function Aura.GetPlayerAuraBySpellID(spellId)
	spellId = tonumber(spellId)
	if not spellId then
		return nil
	end
	if Cap.hasC_UnitAuras_GetPlayerAuraBySpellID or (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then
		local ok, data = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellId)
		if ok then
			return data
		end
	end
	return nil
end

-- Maps a cast/spell id to the self-buff used for an action-button aura swipe.
function Aura.GetCooldownAuraBySpellID(spellId)
	spellId = tonumber(spellId)
	if not spellId then
		return nil
	end
	if Cap.hasC_UnitAuras_GetCooldownAuraBySpellID or (C_UnitAuras and C_UnitAuras.GetCooldownAuraBySpellID) then
		local ok, id = pcall(C_UnitAuras.GetCooldownAuraBySpellID, spellId)
		if not ok or id == nil then
			return nil
		end
		local n = tonumber(id)
		if n and n ~= 0 then
			return n
		end
	end
	return nil
end

-- LuaDurationObject for SetCooldownFromDurationObject. Instance id must be a
-- public number; secret ids cannot be passed while tainted.
function Aura.GetAuraDuration(unit, auraInstanceID)
	if not unit or auraInstanceID == nil then
		return nil
	end
	local S = Flux.Secrets
	if S and S.IsSecretValue and S.IsSecretValue(auraInstanceID) then
		return nil
	end
	if S and S.CanAccessValue and not S.CanAccessValue(auraInstanceID) then
		return nil
	end
	if Cap.hasC_UnitAuras_GetAuraDuration or (C_UnitAuras and C_UnitAuras.GetAuraDuration) then
		local ok, duration = pcall(C_UnitAuras.GetAuraDuration, unit, auraInstanceID)
		if ok then
			return duration
		end
	end
	return nil
end

-- Display wrappers. Do not branch combat decisions on these values on Midnight.
function Aura.UnitHealth(unit)
	return UnitHealth(unit)
end

function Aura.UnitHealthMax(unit)
	return UnitHealthMax(unit)
end

function Aura.UnitPower(unit, powerType)
	return UnitPower(unit, powerType)
end

function Aura.UnitPowerMax(unit, powerType)
	return UnitPowerMax(unit, powerType)
end
