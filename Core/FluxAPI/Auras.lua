-- Auras.lua — aura and unit health/power helpers (modern clients only)
local addonName, ns = ...
local H = ns._FluxAPICompat
local _type = H.type
local _strfind = H.strfind
local _issecretvalue = H.issecretvalue

ns.API.UnitAuraHasDiffPayload = FLUX_API.isRetail and (FLUX_API.majorVersion >= 10)

function SafeUnitHealth(unit)
    return UnitHealth(unit)
end

function SafeUnitHealthMax(unit)
    return UnitHealthMax(unit)
end

function SafeUnitPower(unit, powerType)
    return UnitPower(unit, powerType)
end

function SafeUnitPowerMax(unit, powerType)
    return UnitPowerMax(unit, powerType)
end

function SafeUnitGetIncomingHeals(unit, healerType)
    if not unit then return 0 end
    if UnitGetIncomingHeals then
        return UnitGetIncomingHeals(unit, healerType) or 0
    end
    return 0
end

function SafeUnitGetTotalAbsorbs(unit)
    if not unit then return 0 end
    if UnitGetTotalAbsorbs then
        local ok, val = pcall(UnitGetTotalAbsorbs, unit)
        if ok then return val or 0 end
    end
    return 0
end

function SafeUnitGetTotalHealAbsorbs(unit)
    if not unit then return 0 end
    if UnitGetTotalHealAbsorbs then
        local ok, val = pcall(UnitGetTotalHealAbsorbs, unit)
        if ok then return val or 0 end
    end
    return 0
end

function SafeGetAuraSlots(unit, filter)
    if not unit then
        return {}, true
    end
    local S = ns.Flux and ns.Flux.Secrets
    if S and S.CanAccessSecrets and not S.CanAccessSecrets() then
        return nil, false
    end
    if FLUX_API.hasC_UnitAuras_GetAuraSlots then
        local packed = { pcall(C_UnitAuras.GetAuraSlots, unit, filter) }
        if not packed[1] then
            return nil, false
        end
        if type(packed[2]) == "table" then
            if S and ((S.IsSecretTable and S.IsSecretTable(packed[2])) or (S.CanAccessTable and not S.CanAccessTable(packed[2]))) then
                return nil, false
            end
            return packed[2], true
        end
        -- packed[1]=ok; remainder is continuationToken, slot, slot, ...
        -- Unit frames iterate from index 2 (same shape as { GetAuraSlots() }).
        local slots = {}
        for i = 2, #packed do
            slots[#slots + 1] = packed[i]
        end
        return slots, true
    end
    return {}, true
end

function SafeGetAuraDataBySlot(unit, slot, filter)
    if not unit then
        return nil
    end
    local Aura = ns.Flux and ns.Flux.Aura
    if Aura and Aura.GetDataBySlot and FLUX_API.hasC_UnitAuras_GetAuraDataBySlot then
        return Aura.GetDataBySlot(unit, slot)
    end
    if FLUX_API.hasC_UnitAuras_GetAuraDataBySlot then
        local ok, data = pcall(C_UnitAuras.GetAuraDataBySlot, unit, slot)
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
        nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, _timeMod =
        pcall(UnitAura, unit, slot, filter)
    if not ok or not name then return nil end
    return {
        name = name,
        icon = icon,
        applications = count or 0,
        dispelName = dispelType,
        duration = duration or 0,
        expirationTime = expirationTime or 0,
        sourceUnit = source,
        isStealable = isStealable,
        nameplateShowPersonal = nameplateShowPersonal,
        spellId = spellId,
        canApplyAura = canApplyAura,
        isBossAura = isBossDebuff,
        isFromPlayerOrPlayerPet = castByPlayer,
        nameplateShowAll = nameplateShowAll,
        auraInstanceID = slot,
        isHarmfulAura = (filter == "HARMFUL"),
        isHelpfulAura = (filter == "HELPFUL"),
    }
end

function SafeUnitTokenAllowsC_UnitAuras(unit)
    if _type(unit) ~= "string" then
        return false
    end
    if unit ~= "target" and _strfind(unit, "target", 1, true) then
        return false
    end
    return true
end

function SafeGetAuraDataByIndex(unit, index, filter)
    if not unit or not index then return nil end
    if FLUX_API.hasC_UnitAuras_GetAuraDataByIndex and SafeUnitTokenAllowsC_UnitAuras(unit) then
        local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if ok then
            return auraData
        end
    end
    if FLUX_API.isRetail and UnitAuraSlots and FLUX_API.hasC_UnitAuras_GetAuraDataBySlot then
        local r = { pcall(UnitAuraSlots, unit, filter, index) }
        if r[1] then
            local slot = r[index + 2]
            if slot then
                local ok2, auraData = pcall(C_UnitAuras.GetAuraDataBySlot, unit, slot)
                if ok2 then
                    return auraData
                end
            end
        end
    end
    return nil
end

function SafeGetAuraDataByAuraInstanceID(unit, auraInstanceID)
    if not unit or not auraInstanceID then return nil end
    if _issecretvalue and _issecretvalue(auraInstanceID) then
        return nil
    end
    local Aura = ns.Flux and ns.Flux.Aura
    if Aura and Aura.GetDataByInstanceID then
        return Aura.GetDataByInstanceID(unit, auraInstanceID)
    end
    if FLUX_API.hasC_UnitAuras_GetAuraDataByAuraInstanceID then
        local ok, data = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, unit, auraInstanceID)
        if ok then
            return data
        end
        return nil
    end
    for i = 1, 40 do
        local data = SafeGetAuraDataBySlot(unit, i, nil)
        if data then
            local aid = data.auraInstanceID
            if aid and not (_issecretvalue and _issecretvalue(aid)) then
                local same = ns.API.SafeCompare and ns.API.SafeCompare(aid, auraInstanceID, "==")
                if same then
                    return data
                end
            end
        end
    end
    return nil
end

function SafeGetAuraDuration(unit, auraInstanceID)
    if not unit or not auraInstanceID then return nil end
    if _issecretvalue and _issecretvalue(auraInstanceID) then
        return nil
    end
    if FLUX_API.hasC_UnitAuras_GetAuraDuration then
        local ok, duration = pcall(C_UnitAuras.GetAuraDuration, unit, auraInstanceID)
        if ok then
            return duration
        end
        return nil
    end
    local data = SafeGetAuraDataByAuraInstanceID(unit, auraInstanceID)
    if data and data.duration and data.expirationTime then
        return {
            duration = data.duration,
            expirationTime = data.expirationTime,
            isFromPlayerOrPlayerPet = data.isFromPlayerOrPlayerPet,
        }
    end
    return nil
end

function SafeGetAuraApplicationDisplayCount(unit, auraInstanceID, minCount, maxCount)
    if not auraInstanceID then return "" end
    local data = SafeGetAuraDataByAuraInstanceID(unit, auraInstanceID)
    if not data then return "" end
    local count = SafeGetNumber(data.applications or 0, 0)
    if count < (minCount or 2) then return "" end
    if count > (maxCount or 999) then return "*" end
    return tostring(count)
end

-- ---------------------------------------------------------------------------
-- Refreshable / treat-as-mine harmful auras (no spell-ID hardcoding)
-- canApplyAura is often false for talent-proc shared uniques (Winter's Chill).
-- Fallbacks: engine refresh prediction, CLEU-learned shared refresh, player/pet source.
-- ---------------------------------------------------------------------------
local sharedRefreshableSpellIds = {}
local seenHarmfulAuraSources = {} -- [destGuid] = { [spellId] = sourceGuid }
local refreshableLearnFrame

local function SafeSpellId(value)
    if value == nil then
        return nil
    end
    if ns.API.IsSecretValue and ns.API.IsSecretValue(value) then
        return nil
    end
    if type(value) ~= "number" then
        return nil
    end
    return value
end

function RememberSharedRefreshableSpell(spellId)
    spellId = SafeSpellId(spellId)
    if not spellId then
        return
    end
    sharedRefreshableSpellIds[spellId] = true
end

function IsSharedRefreshableSpell(spellId)
    spellId = SafeSpellId(spellId)
    return spellId and sharedRefreshableSpellIds[spellId] or false
end

local function NoteHarmfulAuraSource(destGuid, spellId, sourceGuid)
    if not destGuid or not spellId then
        return
    end
    local bySpell = seenHarmfulAuraSources[destGuid]
    if not bySpell then
        bySpell = {}
        seenHarmfulAuraSources[destGuid] = bySpell
    end
    bySpell[spellId] = sourceGuid
end

local function OnPlayerHarmfulAuraCombatEvent(destGuid, spellId, sourceGuid, subevent)
    spellId = SafeSpellId(spellId)
    if not spellId or not destGuid then
        return
    end
    local prior = seenHarmfulAuraSources[destGuid] and seenHarmfulAuraSources[destGuid][spellId]
    -- Reapplied over someone else's instance → shared unique; show as personal on plates.
    if prior and sourceGuid and prior ~= sourceGuid then
        RememberSharedRefreshableSpell(spellId)
    elseif (subevent == "SPELL_AURA_REFRESH" or subevent == "SPELL_AURA_APPLIED_DOSE")
        and (not prior or prior ~= sourceGuid) then
        -- Refresh of an existing debuff we didn't previously own (or never tracked).
        RememberSharedRefreshableSpell(spellId)
    end
    NoteHarmfulAuraSource(destGuid, spellId, sourceGuid)
end

--- True when C_UnitAuras predicts a refresh would produce a duration (player can refresh).
function AuraDataHasRefreshPrediction(unit, data)
    if not unit or not data then
        return false
    end
    if not FLUX_API.hasC_UnitAuras_GetRefreshExtendedDuration then
        return false
    end
    local aid = data.auraInstanceID or data.auraInstanceId
    if not aid or (ns.API.IsSecretValue and ns.API.IsSecretValue(aid)) then
        return false
    end
    local ok, newDuration = pcall(C_UnitAuras.GetRefreshExtendedDuration, unit, aid)
    if not ok or type(newDuration) ~= "number" then
        return false
    end
    if ns.API.IsSecretValue and ns.API.IsSecretValue(newDuration) then
        return false
    end
    return newDuration > 0
end

function AuraDataCanApplyAsOwn(data)
    if not data then
        return false
    end
    local can = data.canApplyAura
    if can == nil or (ns.API.IsSecretValue and ns.API.IsSecretValue(can)) then
        return false
    end
    return can and true or false
end

function AuraDataSourceIsPlayerOrPet(data)
    if not data then
        return false
    end
    local sourceUnit = data.sourceUnit
    if not sourceUnit or (ns.API.IsSecretValue and ns.API.IsSecretValue(sourceUnit)) then
        return false
    end
    if sourceUnit == "player" or sourceUnit == "pet" or sourceUnit == "vehicle" then
        return true
    end
    if UnitIsUnit and (UnitIsUnit(sourceUnit, "player") or UnitIsUnit(sourceUnit, "pet")
        or (UnitExists("vehicle") and UnitIsUnit(sourceUnit, "vehicle"))) then
        return true
    end
    return false
end

--- Harmful aura the player owns, can apply, can refresh, or previously shared-refreshed.
function AuraDataTreatAsPlayerHarmful(unit, data)
    if not data then
        return false
    end
    if AuraDataSourceIsPlayerOrPet(data) then
        return true
    end
    if AuraDataCanApplyAsOwn(data) then
        return true
    end
    local spellId = SafeSpellId(data.spellId)
    if spellId and sharedRefreshableSpellIds[spellId] then
        return true
    end
    if AuraDataHasRefreshPrediction(unit, data) then
        return true
    end
    return false
end

--- True when this aura should appear on Blizzard nameplates as a personal debuff
--- even if sourceUnit is not the player (CLEU-learned shared reapply only).
function AuraDataIsSharedRefreshableForNameplate(data)
    if not data then
        return false
    end
    local spellId = SafeSpellId(data.spellId)
    if not spellId or not sharedRefreshableSpellIds[spellId] then
        return false
    end
    if C_Spell and C_Spell.IsSpellCrowdControl then
        local ok, isCC = pcall(C_Spell.IsSpellCrowdControl, spellId)
        if ok and isCC then
            return false
        end
    end
    return true
end

local function EnsureRefreshableLearnEvents()
    if refreshableLearnFrame then
        return
    end
    -- Midnight (12.0+): RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") is forbidden for addons.
    -- Shared-refresh learning degrades to canApplyAura / refresh-prediction heuristics only.
    if (FLUX_API and FLUX_API.isV12) or (ns.API and ns.API.isV12) then
        return
    end
    if type(CombatLogGetCurrentEventInfo) ~= "function" then
        return
    end
    refreshableLearnFrame = CreateFrame("Frame")
    local okCLEU = pcall(refreshableLearnFrame.RegisterEvent, refreshableLearnFrame, "COMBAT_LOG_EVENT_UNFILTERED")
    if not okCLEU then
        refreshableLearnFrame = nil
        return
    end
    refreshableLearnFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    refreshableLearnFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            wipe(seenHarmfulAuraSources)
            -- Keep sharedRefreshableSpellIds for the session (learned reapply capability).
            return
        end
        if not CombatLogGetCurrentEventInfo then
            return
        end
        local _, subevent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, _, _, auraType =
            CombatLogGetCurrentEventInfo()
        if auraType ~= "DEBUFF" then
            return
        end
        if subevent ~= "SPELL_AURA_APPLIED" and subevent ~= "SPELL_AURA_REFRESH"
            and subevent ~= "SPELL_AURA_APPLIED_DOSE" then
            return
        end
        local playerGUID = UnitGUID and UnitGUID("player")
        local petGUID = UnitGUID and UnitGUID("pet")
        if not sourceGUID or (sourceGUID ~= playerGUID and sourceGUID ~= petGUID) then
            -- Track other casters so a later player refresh can mark shared.
            if destGUID and spellId then
                NoteHarmfulAuraSource(destGUID, spellId, sourceGUID)
            end
            return
        end
        OnPlayerHarmfulAuraCombatEvent(destGUID, spellId, sourceGUID, subevent)
    end)
end

EnsureRefreshableLearnEvents()

function SafeBooleanTest(value, default)
    local S = ns.Flux and ns.Flux.Secrets
    if S and S.SafeBooleanTest then
        return S.SafeBooleanTest(value, default)
    end
    if ns.API.SafeBooleanTest and ns.API.SafeBooleanTest ~= SafeBooleanTest then
        return ns.API.SafeBooleanTest(value, default)
    end
    if value == nil then
        return default
    end
    if _issecretvalue and _issecretvalue(value) then
        if type(value) == "boolean" then
            return default
        end
        return true
    end
    local ok, truthy = pcall(function()
        if value then
            return true
        end
        return false
    end)
    if not ok then
        return default
    end
    return truthy
end

function SafeHealthPercent(unit)
    if UnitHealthPercent then
        local p = UnitHealthPercent(unit)
        if type(p) == "number" then return p end
    end
    local health = ns.API.SafeGetNumber(UnitHealth(unit))
    local healthMax = ns.API.SafeGetNumber(UnitHealthMax(unit))
    if healthMax <= 0 then healthMax = 1 end
    return health / healthMax
end

function SafePowerPercent(unit, powerType)
    if UnitPowerPercent then
        local p = UnitPowerPercent(unit, powerType)
        if type(p) == "number" then return p end
    end
    local power = ns.API.SafeGetNumber(UnitPower(unit, powerType))
    local powerMax = ns.API.SafeGetNumber(UnitPowerMax(unit, powerType))
    if powerMax <= 0 then powerMax = 1 end
    return power / powerMax
end

function GetHealthPercent100(unit)
    if UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
        return UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
    end
    if UnitPercentHealthFromGUID and UnitGUID then
        local guid = UnitGUID(unit)
        if guid then
            return UnitPercentHealthFromGUID(guid)
        end
    end
    local p = SafeHealthPercent(unit)
    if not ns.API.IsSecretValue(p) and type(p) == "number" then
        return p * 100
    end
    return p
end

function GetPowerPercent100(unit, powerType)
    if UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100 then
        return UnitPowerPercent(unit, powerType, true, CurveConstants.ScaleTo100)
    end
    local p = SafePowerPercent(unit, powerType)
    if not ns.API.IsSecretValue(p) and type(p) == "number" then
        return p * 100
    end
    return p
end

ns.API.SafeUnitHealth = SafeUnitHealth
ns.API.SafeUnitHealthMax = SafeUnitHealthMax
ns.API.SafeUnitPower = SafeUnitPower
ns.API.SafeUnitPowerMax = SafeUnitPowerMax
ns.API.SafeUnitGetIncomingHeals = SafeUnitGetIncomingHeals
ns.API.SafeUnitGetTotalAbsorbs = SafeUnitGetTotalAbsorbs
ns.API.SafeUnitGetTotalHealAbsorbs = SafeUnitGetTotalHealAbsorbs
ns.API.SafeBooleanTest = SafeBooleanTest
ns.API.SafeGetAuraSlots = SafeGetAuraSlots
ns.API.SafeGetAuraDataBySlot = SafeGetAuraDataBySlot
ns.API.SafeUnitTokenAllowsC_UnitAuras = SafeUnitTokenAllowsC_UnitAuras
ns.API.SafeGetAuraDataByIndex = SafeGetAuraDataByIndex
ns.API.SafeGetAuraDataByAuraInstanceID = SafeGetAuraDataByAuraInstanceID
ns.API.SafeGetAuraDuration = SafeGetAuraDuration
ns.API.SafeGetAuraApplicationDisplayCount = SafeGetAuraApplicationDisplayCount
ns.API.RememberSharedRefreshableSpell = RememberSharedRefreshableSpell
ns.API.IsSharedRefreshableSpell = IsSharedRefreshableSpell
ns.API.AuraDataCanApplyAsOwn = AuraDataCanApplyAsOwn
ns.API.AuraDataSourceIsPlayerOrPet = AuraDataSourceIsPlayerOrPet
ns.API.AuraDataHasRefreshPrediction = AuraDataHasRefreshPrediction
ns.API.AuraDataTreatAsPlayerHarmful = AuraDataTreatAsPlayerHarmful
ns.API.AuraDataIsSharedRefreshableForNameplate = AuraDataIsSharedRefreshableForNameplate
ns.API.IsSecretValue = IsSecretValue or issecretvalue or function() return false end
ns.API.CreateUnitHealPredictionCalculator = CreateUnitHealPredictionCalculator
ns.API.UnitGetDetailedHealPrediction = UnitGetDetailedHealPrediction
ns.API.SafeHealthPercent = SafeHealthPercent
ns.API.SafePowerPercent = SafePowerPercent
ns.API.GetHealthPercent100 = GetHealthPercent100
ns.API.GetPowerPercent100 = GetPowerPercent100

_G.SafeUnitHealth = SafeUnitHealth
_G.SafeUnitHealthMax = SafeUnitHealthMax
_G.SafeUnitPower = SafeUnitPower
_G.SafeUnitPowerMax = SafeUnitPowerMax
_G.SafeUnitGetIncomingHeals = SafeUnitGetIncomingHeals
_G.SafeUnitGetTotalAbsorbs = SafeUnitGetTotalAbsorbs
_G.SafeUnitGetTotalHealAbsorbs = SafeUnitGetTotalHealAbsorbs
_G.SafeBooleanTest = SafeBooleanTest
_G.SafeGetAuraSlots = SafeGetAuraSlots
_G.SafeGetAuraDataBySlot = SafeGetAuraDataBySlot
_G.SafeGetAuraDataByIndex = SafeGetAuraDataByIndex
_G.SafeGetAuraDataByAuraInstanceID = SafeGetAuraDataByAuraInstanceID
_G.SafeGetAuraDuration = SafeGetAuraDuration
_G.SafeGetAuraApplicationDisplayCount = SafeGetAuraApplicationDisplayCount
_G.SafeHealthPercent = SafeHealthPercent
_G.SafePowerPercent = SafePowerPercent
_G.GetHealthPercent100 = GetHealthPercent100
_G.GetPowerPercent100 = GetPowerPercent100
