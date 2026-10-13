-- Shared target/focus own-debuff policy for the Lua painter and AuraContainer engine.
-- Identify "mine" with HARMFUL|PLAYER (you / pet / vehicle). Do not use
-- isFromPlayerOrPlayerPet (any player) or shared-refresh heuristics for size.
local addonName, ns = ...
ns.UnitFrames = ns.UnitFrames or {}
local UF = ns.UnitFrames

local AuraOwn = {}
UF.AuraOwn = AuraOwn

--- ~1.38× configured debuff size (42/35, plus 1.15 emphasis).
AuraOwn.BOOST = (42 / 35) * 1.15
AuraOwn.PLAYER_HARMFUL_FILTER = "HARMFUL|PLAYER"
AuraOwn.OTHER_HARMFUL_FILTER = "HARMFUL|!PLAYER"
AuraOwn.HARMFUL_FILTER = "HARMFUL"

local function AuraFilters()
    return AuraUtil and AuraUtil.AuraFilters
end

local function FilterToken(filters, key, fallback)
    if filters and filters[key] then
        return filters[key]
    end
    return fallback
end

local function JoinFilter(...)
    if AuraUtil and AuraUtil.CreateFilterString then
        local ok, s = pcall(AuraUtil.CreateFilterString, ...)
        if ok and type(s) == "string" and s ~= "" then
            return s
        end
    end
    return table.concat({ ... }, "|")
end

function AuraOwn.IsSecretValue(value)
    local S = ns.Flux and ns.Flux.Secrets
    if S and S.IsSecretValue then
        return S.IsSecretValue(value) and true or false
    end
    local API = ns.API
    if API and API.IsSecretValue then
        return API.IsSecretValue(value) and true or false
    end
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        return ok and secret and true or false
    end
    return false
end

function AuraOwn.IsAccessible(value)
    if value == nil then
        return false
    end
    if AuraOwn.IsSecretValue(value) then
        return false
    end
    local S = ns.Flux and ns.Flux.Secrets
    if S and S.CanAccessValue and not S.CanAccessValue(value) then
        return false
    end
    return true
end

function AuraOwn.HasPackedAuraAPI()
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.hasC_UnitAuras_GetAuraDataByIndex then
        return true
    end
    if FLUX_API and FLUX_API.hasC_UnitAuras_GetAuraDataByIndex then
        return true
    end
    return C_UnitAuras ~= nil and C_UnitAuras.GetAuraDataByIndex ~= nil
end

function AuraOwn.HasFilterNegation()
    local prefix = AuraUtil and AuraUtil.AuraFilterNegationPrefix
    return type(prefix) == "string" and prefix ~= ""
end

--- HARMFUL, plus INCLUDE_NAME_PLATE_ONLY when this client has that token.
--- Blizzard target frames use this so the lead nameplate debuff is not dropped.
function AuraOwn.GetHarmfulFilter()
    local filters = AuraFilters()
    local harmful = FilterToken(filters, "Harmful", "HARMFUL")
    local nameplateOnly = filters and filters.IncludeNameplateOnly
    if nameplateOnly then
        return JoinFilter(harmful, nameplateOnly)
    end
    return harmful
end

--- Full harmful list restricted to you / pet / vehicle.
function AuraOwn.GetOwnHarmfulFilter()
    local filters = AuraFilters()
    local harmful = FilterToken(filters, "Harmful", "HARMFUL")
    local player = FilterToken(filters, "Player", "PLAYER")
    local nameplateOnly = filters and filters.IncludeNameplateOnly
    if nameplateOnly then
        return JoinFilter(harmful, player, nameplateOnly)
    end
    return JoinFilter(harmful, player)
end

--- Full harmful list excluding you / pet / vehicle. Nil when "!" filters do not exist,
--- so the caller can show one HARMFUL group instead of a player-only list.
function AuraOwn.GetOtherHarmfulFilter()
    if not AuraOwn.HasFilterNegation() then
        return nil
    end
    local filters = AuraFilters()
    local harmful = FilterToken(filters, "Harmful", "HARMFUL")
    local player = FilterToken(filters, "Player", "PLAYER")
    local prefix = AuraUtil.AuraFilterNegationPrefix
    local nameplateOnly = filters and filters.IncludeNameplateOnly
    if nameplateOnly then
        return JoinFilter(harmful, prefix .. player, nameplateOnly)
    end
    return JoinFilter(harmful, prefix .. player)
end

AuraOwn.HARMFUL_FILTER = AuraOwn.GetHarmfulFilter()
AuraOwn.PLAYER_HARMFUL_FILTER = AuraOwn.GetOwnHarmfulFilter()
AuraOwn.OTHER_HARMFUL_FILTER = AuraOwn.GetOtherHarmfulFilter() or AuraOwn.OTHER_HARMFUL_FILTER

function AuraOwn.ClampMinScale(minScale)
    minScale = tonumber(minScale)
    if type(minScale) ~= "number" or minScale ~= minScale then
        minScale = 1
    end
    if minScale > 1 then
        minScale = 1
    elseif minScale < 0.5 then
        minScale = 0.5
    end
    return minScale
end

--- Engine cell multiplier: lock => full boost; unlock => boost * minScale.
function AuraOwn.GetOwnSizeMultiplier(lockOwn, minScale)
    if lockOwn == nil or lockOwn then
        return AuraOwn.BOOST
    end
    return AuraOwn.BOOST * AuraOwn.ClampMinScale(minScale)
end

--- Lua fit scale for an own icon: lock => 1; unlock => max(fitMult, minScale).
function AuraOwn.GetOwnFitScale(lockOwn, minScale, fitMult)
    if lockOwn then
        return 1
    end
    fitMult = tonumber(fitMult) or 1
    local minS = AuraOwn.ClampMinScale(minScale)
    if fitMult < minS then
        return minS
    end
    return fitMult
end

--- otherW, otherH, ownW, ownH, spacing
function AuraOwn.GetIconSizes(base, spacing, lockOwn, minScale, xSqueeze, slotHeight)
    base = tonumber(base) or 35
    spacing = tonumber(spacing) or 2
    local xF = tonumber(xSqueeze)
    if not xF or xF ~= xF or xF <= 0 then
        xF = 1
    end
    local otherH = tonumber(slotHeight) or base
    local otherW = base * xF
    local ownH = base * AuraOwn.GetOwnSizeMultiplier(lockOwn, minScale)
    local ownW = ownH * xF
    return otherW, otherH, ownW, ownH, spacing
end

function AuraOwn.GetAuraInstanceID(data)
    if not data then
        return nil
    end
    local aid = data.auraInstanceID or data.auraInstanceId
    if aid and not AuraOwn.IsSecretValue(aid) then
        return aid
    end
    return nil
end

local function GetAuraDataByIndex(unit, index, filter)
    local API = ns.API
    if API and API.SafeGetAuraDataByIndex then
        return API.SafeGetAuraDataByIndex(unit, index, filter)
    end
    local Aura = ns.Flux and ns.Flux.Aura
    if Aura and Aura.GetDataByIndex then
        return Aura.GetDataByIndex(unit, index, filter)
    end
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if ok then
            return data
        end
    end
    return nil
end

function AuraOwn.BuildPlayerDebuffInstanceSet(unit, maxDebuffs)
    local set = {}
    if not unit or not UnitExists(unit) then
        return set
    end
    if not AuraOwn.HasPackedAuraAPI() then
        return set
    end
    local limit = math.max(tonumber(maxDebuffs) or 16, 40)
    local filter = AuraOwn.GetOwnHarmfulFilter and AuraOwn.GetOwnHarmfulFilter() or AuraOwn.PLAYER_HARMFUL_FILTER
    for i = 1, limit do
        local ad = GetAuraDataByIndex(unit, i, filter)
        if not ad then
            break
        end
        local aid = AuraOwn.GetAuraInstanceID(ad)
        if aid then
            set[aid] = true
        end
    end
    return set
end

function AuraOwn.SourceIsPlayerPetOrVehicle(sourceUnit)
    if not AuraOwn.IsAccessible(sourceUnit) then
        return false
    end
    if sourceUnit == "player" or sourceUnit == "pet" or sourceUnit == "vehicle" then
        return true
    end
    if UnitIsUnit then
        if UnitIsUnit(sourceUnit, "player") or UnitIsUnit(sourceUnit, "pet") then
            return true
        end
        if UnitExists and UnitExists("vehicle") and UnitIsUnit(sourceUnit, "vehicle") then
            return true
        end
    end
    if UnitIsOwnerOrControllerOfUnit then
        local ok, owned = pcall(UnitIsOwnerOrControllerOfUnit, "player", sourceUnit)
        if ok and owned then
            return true
        end
    end
    return false
end

--- True when this harmful aura should use own-debuff size/sort.
--- instanceSet comes from HARMFUL|PLAYER (never-secret auraInstanceIDs).
function AuraOwn.IsOwnHarmful(unit, data, instanceSet)
    if not data then
        return false
    end
    local aid = AuraOwn.GetAuraInstanceID(data)
    if instanceSet and aid then
        local ok, hit = pcall(function()
            return instanceSet[aid]
        end)
        if ok and hit then
            return true
        end
    end
    local sourceUnit = data.sourceUnit
    if AuraOwn.IsAccessible(sourceUnit) then
        return AuraOwn.SourceIsPlayerPetOrVehicle(sourceUnit)
    end
    -- Caster secret/missing: TPerl nameplateShowPersonal only when it is a real boolean.
    local npsp = data.nameplateShowPersonal
    if npsp ~= nil and not AuraOwn.IsSecretValue(npsp) and type(npsp) == "boolean" then
        return npsp and true or false
    end
    return false
end

function AuraOwn.SortDebuffsOwnFirst(unit, list, instanceSet)
    if not list or #list < 2 then
        return
    end
    table.sort(list, function(a, b)
        local ap = AuraOwn.IsOwnHarmful(unit, a, instanceSet)
        local bp = AuraOwn.IsOwnHarmful(unit, b, instanceSet)
        if ap ~= bp then
            return ap
        end
        return (a._fluxCollectOrder or 0) < (b._fluxCollectOrder or 0)
    end)
end
