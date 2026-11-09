-- Secrets.lua — secret-value helpers (modern clients only)
local addonName, ns = ...

function ns.API.CanAccessValue(value)
    if canaccessvalue then
        local ok, res = pcall(canaccessvalue, value)
        return ok and res or false
    end
    return true
end

function ns.API.SafeAccessibleString(value)
    if value == nil then
        return nil
    end
    -- canaccessvalue can be true for secret strings; they still cannot be table keys.
    if ns.API.IsSecretValue(value) then
        return nil
    end
    if not ns.API.CanAccessValue(value) then
        return nil
    end
    return value
end

function ns.API.CanAccessSecrets()
    if canaccesssecrets then
        return canaccesssecrets()
    end
    return true
end

function ns.API.IsSecretValue(value)
    if issecretvalue then
        return issecretvalue(value)
    end
    return false
end

-- Keep secret helpers on ns.API only — do not put IsSecret in _G (collides / taints).
ns.API.IsSecret = ns.API.IsSecretValue

function ns.API.SafeGetNumber(value, default)
    default = default or 0
    if value == nil then return default end
    -- canaccessvalue can be true for secret combat numbers; still unusable in tainted compares.
    if ns.API.IsSecretValue(value) then
        return default
    end
    if not ns.API.CanAccessValue(value) then
        return default
    end
    local ok, num = pcall(tonumber, value)
    if not ok or num == nil then
        return default
    end
    if ns.API.IsSecretValue(num) then
        return default
    end
    return num
end

function ns.API.KeepLastNumber(value, last, fallback)
    local S = ns.Flux and ns.Flux.Secrets
    if S and S.KeepLastNumber then
        return S.KeepLastNumber(value, last, fallback)
    end
    fallback = fallback or 0
    local function useLast()
        if type(last) == "number" then
            return last
        end
        return fallback
    end
    if value == nil then
        return useLast()
    end
    if ns.API.IsSecretValue(value) then
        return useLast()
    end
    if not ns.API.CanAccessValue(value) then
        return useLast()
    end
    local ok, num = pcall(tonumber, value)
    if not ok or num == nil then
        return useLast()
    end
    if ns.API.IsSecretValue(num) then
        return useLast()
    end
    return num
end

function ns.API.CoerceNumberLoose(value, default)
    default = default or 0
    if value == nil then return default end
    local ok, n = pcall(function()
        return (value + 0)
    end)
    if ok and type(n) == "number" and n == n and n < math.huge and n > -math.huge then
        return n
    end
    return default
end

function ns.API.SafeCompare(a, b, operator)
    local S = ns.Flux and ns.Flux.Secrets
    if S and S.SafeCompare then
        return S.SafeCompare(a, b, operator)
    end
    if ns.API.IsSecretValue and (ns.API.IsSecretValue(a) or ns.API.IsSecretValue(b)) then
        return nil
    end
    if not ns.API.CanAccessValue(a) or not ns.API.CanAccessValue(b) then
        return nil
    end
    local ok, res = pcall(function()
        if operator == "~=" then return a ~= b
        elseif operator == "==" then return a == b
        elseif operator == ">" then return a > b
        elseif operator == "<" then return a < b
        elseif operator == ">=" then return a >= b
        elseif operator == "<=" then return a <= b
        end
        return nil
    end)
    if not ok then
        return nil
    end
    return res
end

function ns.API.SafeEqualForCache(a, b)
    local cmp = ns.API.SafeCompare(a, b, "==")
    if cmp ~= nil then
        return cmp
    end
    local ok, res = pcall(function()
        return a == b
    end)
    return ok and res or false
end

function ns.API.SafeGUIDsEqual(a, b)
    if a == nil and b == nil then
        return true
    end
    if a == nil or b == nil then
        return false
    end
    return ns.API.SafeCompare(a, b, "==")
end

function ns.API.SafeGUIDChangedForRefresh(prev, next)
    local eq = ns.API.SafeGUIDsEqual(prev, next)
    if eq == true then
        return false
    end
    return true
end

function ns.API.AccessibleGUIDForUnit(unit)
    if not UnitGUID or not unit then
        return nil
    end
    if UnitExists and not UnitExists(unit) then
        return nil
    end
    local guid = UnitGUID(unit)
    if guid == nil then
        return nil
    end
    if ns.API.IsSecretValue and ns.API.IsSecretValue(guid) then
        return nil
    end
    if not ns.API.CanAccessValue(guid) then
        return nil
    end
    return guid
end

function ns.API.SafeBooleanTest(value, default)
    local S = ns.Flux and ns.Flux.Secrets
    if S and S.SafeBooleanTest then
        return S.SafeBooleanTest(value, default)
    end
    if value == nil then
        return default
    end
    if ns.API.IsSecretValue and ns.API.IsSecretValue(value) then
        if type(value) == "boolean" then
            return default
        end
        return true
    end
    if not ns.API.CanAccessValue(value) then
        return default
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

function SafeGetNumber(value, default)
    local _issecretvalue = ns._FluxAPICompat.issecretvalue
    if _issecretvalue and _issecretvalue(value) then
        return default or 0
    end
    local num = tonumber(value)
    if num then return num end
    return default or 0
end

function SafeNumber(value, default)
    return SafeGetNumber(value, default)
end

function SafeCompareValues(a, b, operator)
    local numA = tonumber(a)
    local numB = tonumber(b)
    if numA == nil or numB == nil then
        return nil
    end
    if operator == "==" then return numA == numB
    elseif operator == "~=" then return numA ~= numB
    elseif operator == ">" then return numA > numB
    elseif operator == "<" then return numA < numB
    elseif operator == ">=" then return numA >= numB
    elseif operator == "<=" then return numA <= numB
    end
    return nil
end

_G.SafeGetNumber = SafeGetNumber

function IsWoWLegacyClient()
    return FLUX_API.isLegacyClient
end

function IsWoWModernClient()
    return FLUX_API.isModernClient
end

function IsTalentTreeClient()
    return FLUX_API.hasTalentTreeSpec
end

WOW_VERSION = WOW_VERSION or {}
WOW_VERSION.isModernClient = FLUX_API.isModernClient
WOW_VERSION.isLegacyClient = FLUX_API.isLegacyClient
WOW_VERSION.isRetail = FLUX_API.isRetail
WOW_VERSION.isClassic = FLUX_API.isClassic
WOW_VERSION.isWrath = FLUX_API.isWrath
WOW_VERSION.isCata = FLUX_API.isCata
WOW_VERSION.isV12 = FLUX_API.isV12
