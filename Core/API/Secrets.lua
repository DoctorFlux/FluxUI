-- Secrets.lua — public secret-value helpers on every client.
-- Flavor files replace the backend. Do not put IsSecret on _G (collides / taints).
local addonName, ns = ...
local Flux = ns.Flux

local Secrets = {}
Flux.Secrets = Secrets
Flux.API = Flux.API or {}
Flux.API.Secrets = Secrets

-- Default until Secrets_Midnight / Secrets_Classic runs: Classic-safe (always accessible).
ns._secretsBackend = ns._secretsBackend or {
	CanAccessValue = function()
		return true
	end,
	IsSecretValue = function()
		return false
	end,
	CanAccessSecrets = function()
		return true
	end,
	IsSecretTable = function()
		return false
	end,
	CanAccessTable = function()
		return true
	end,
}

function Secrets.CanAccessValue(value)
	return ns._secretsBackend.CanAccessValue(value)
end

function Secrets.IsSecretValue(value)
	return ns._secretsBackend.IsSecretValue(value)
end

Secrets.IsSecret = Secrets.IsSecretValue

function Secrets.CanAccessSecrets()
	return ns._secretsBackend.CanAccessSecrets()
end

-- True when aura APIs will generally refuse or secret their returns.
-- Do not use CanAccessSecrets() for this: tainted addons are often always false.
-- Classic / live with HasSecretRestrictions() == false stay open unless Midnight
-- combat still hides RequiresNonSecretAura results.
function Secrets.AurasRestricted()
	local C = C_Secrets
	if C and C.ShouldAurasBeSecret then
		local ok, secret = pcall(C.ShouldAurasBeSecret)
		if ok then
			return secret and true or false
		end
	end
	if C and C.HasSecretRestrictions then
		local ok, rest = pcall(C.HasSecretRestrictions)
		if ok and rest == false then
			local Client = Flux.Client
			if Client and Client.isMidnight then
				if Flux.Combat and Flux.Combat.InLockdown then
					return Flux.Combat.InLockdown() and true or false
				end
				if InCombatLockdown then
					return InCombatLockdown() and true or false
				end
			end
			return false
		end
	end
	local Client = Flux.Client
	if Client and Client.isMidnight then
		if Flux.Combat and Flux.Combat.InLockdown then
			return Flux.Combat.InLockdown() and true or false
		end
		if InCombatLockdown then
			return InCombatLockdown() and true or false
		end
	end
	return false
end

function Secrets.IsSecretTable(value)
	local backend = ns._secretsBackend
	if backend.IsSecretTable then
		return backend.IsSecretTable(value)
	end
	return false
end

function Secrets.CanAccessTable(value)
	local backend = ns._secretsBackend
	if backend.CanAccessTable then
		return backend.CanAccessTable(value)
	end
	return true
end

function Secrets.SafeAccessibleString(value)
	if value == nil then
		return nil
	end
	-- canaccessvalue can be true for secret strings; they still cannot be table keys.
	if Secrets.IsSecretValue(value) then
		return nil
	end
	if not Secrets.CanAccessValue(value) then
		return nil
	end
	return value
end

function Secrets.SafeGetNumber(value, default)
	default = default or 0
	if value == nil then
		return default
	end
	-- canaccessvalue can be true for secret combat numbers; still unusable in tainted compares.
	if Secrets.IsSecretValue(value) then
		return default
	end
	if not Secrets.CanAccessValue(value) then
		return default
	end
	local ok, num = pcall(tonumber, value)
	if not ok or num == nil then
		return default
	end
	if Secrets.IsSecretValue(num) then
		return default
	end
	return num
end

-- Accessible number, else last cached plain number, else fallback.
-- Never uses SafeGetNumber's 0 default (that would freeze swing/speed caches).
function Secrets.KeepLastNumber(value, last, fallback)
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
	if Secrets.IsSecretValue(value) then
		return useLast()
	end
	if not Secrets.CanAccessValue(value) then
		return useLast()
	end
	local ok, num = pcall(tonumber, value)
	if not ok or num == nil then
		return useLast()
	end
	if Secrets.IsSecretValue(num) then
		return useLast()
	end
	return num
end

function Secrets.CoerceNumberLoose(value, default)
	default = default or 0
	if value == nil then
		return default
	end
	local ok, n = pcall(function()
		return (value + 0)
	end)
	if ok and type(n) == "number" and n == n and n < math.huge and n > -math.huge then
		return n
	end
	return default
end

function Secrets.SafeCompare(a, b, operator)
	if Secrets.IsSecretValue(a) or Secrets.IsSecretValue(b) then
		return nil
	end
	if not Secrets.CanAccessValue(a) or not Secrets.CanAccessValue(b) then
		return nil
	end
	local ok, res = pcall(function()
		if operator == "~=" then
			return a ~= b
		elseif operator == "==" then
			return a == b
		elseif operator == ">" then
			return a > b
		elseif operator == "<" then
			return a < b
		elseif operator == ">=" then
			return a >= b
		elseif operator == "<=" then
			return a <= b
		end
		return nil
	end)
	if not ok then
		return nil
	end
	return res
end

function Secrets.SafeEqualForCache(a, b)
	local cmp = Secrets.SafeCompare(a, b, "==")
	if cmp ~= nil then
		return cmp
	end
	local ok, res = pcall(function()
		return a == b
	end)
	return ok and res or false
end

function Secrets.SafeGUIDsEqual(a, b)
	if a == nil and b == nil then
		return true
	end
	if a == nil or b == nil then
		return false
	end
	return Secrets.SafeCompare(a, b, "==")
end

function Secrets.SafeGUIDChangedForRefresh(prev, nextGUID)
	local eq = Secrets.SafeGUIDsEqual(prev, nextGUID)
	if eq == true then
		return false
	end
	return true
end

function Secrets.AccessibleGUIDForUnit(unit)
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
	if Secrets.IsSecretValue(guid) then
		return nil
	end
	if not Secrets.CanAccessValue(guid) then
		return nil
	end
	return guid
end

-- Secret booleans cannot be if-tested while tainted. Non-boolean secrets are
-- always truthy if non-nil (wiki exception). Never `if value then` on a secret boolean.
function Secrets.SafeBooleanTest(value, default)
	if value == nil then
		return default
	end
	if Secrets.IsSecretValue(value) then
		if type(value) == "boolean" then
			return default
		end
		return true
	end
	if not Secrets.CanAccessValue(value) then
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

-- true / false / nil. 1 and 0 (Classic IsSpellInRange / IsItemInRange) count as booleans.
function Secrets.NormalizeTriBool(value)
	if value == nil then
		return nil
	end
	if Secrets.IsSecretValue(value) then
		if type(value) == "boolean" then
			return nil
		end
		local okOne, isOne = pcall(function()
			return value == 1
		end)
		if okOne and isOne then
			return true
		end
		local okZero, isZero = pcall(function()
			return value == 0
		end)
		if okZero and isZero then
			return false
		end
		return nil
	end
	local okAccess, accessible = pcall(Secrets.CanAccessValue, value)
	if okAccess and not accessible then
		return nil
	end
	local ok, isTrue = pcall(function()
		return value == true or value == 1
	end)
	if ok and isTrue then
		return true
	end
	local okFalse, isFalse = pcall(function()
		return value == false or value == 0
	end)
	if okFalse and isFalse then
		return false
	end
	return Secrets.SafeBooleanTest(value, nil)
end

-- pcall the function with the value, never a fresh closure: SafeCountKey runs
-- on every count paint of every button.
local function EqualsEmptyString(value)
	return value == ""
end

-- Public count cache key. nil = secret/inaccessible (skip cache and SetText).
-- "" = hide count. Never tostring+compare a secret.
function Secrets.SafeCountKey(value)
	if value == nil then
		return ""
	end
	if Secrets.IsSecretValue(value) then
		return nil
	end
	local okAccess, accessible = pcall(Secrets.CanAccessValue, value)
	if okAccess and not accessible then
		return nil
	end
	local okEmpty, empty = pcall(EqualsEmptyString, value)
	if okEmpty and empty then
		return ""
	end
	local ok, text = pcall(tostring, value)
	if not ok or type(text) ~= "string" then
		return nil
	end
	if Secrets.IsSecretValue(text) then
		return nil
	end
	return text
end

-- true = nil or "". false = has content OR secret (pass through to SetText).
-- Never ==-compares a secret string.
function Secrets.SafeLooksEmpty(value)
	if value == nil then
		return true
	end
	if Secrets.IsSecretValue(value) then
		return false
	end
	local ok, empty = pcall(EqualsEmptyString, value)
	if ok and empty then
		return true
	end
	return false
end

-- UNIT_AURA payload: true when a non-full update has no added/removed/updated
-- work and is safe to skip. Secret/unreadable payloads are never skipable.
function Secrets.AuraUpdateInfoIsNoop(info)
	if type(info) ~= "table" then
		return false
	end
	if Secrets.IsSecretTable(info) or not Secrets.CanAccessTable(info) then
		return false
	end
	local full = info.isFullUpdate
	if Secrets.IsSecretValue(full) then
		return false
	end
	if Secrets.SafeBooleanTest(full, true) then
		return false
	end
	local function listHas(t)
		if t == nil then
			return false
		end
		if Secrets.IsSecretValue(t) or Secrets.IsSecretTable(t) or not Secrets.CanAccessTable(t) then
			return true
		end
		local ok, n = pcall(function()
			return #t
		end)
		if not ok then
			return true
		end
		return n > 0
	end
	if listHas(info.addedAuras) or listHas(info.removedAuraInstanceIDs) or listHas(info.updatedAuraInstanceIDs) then
		return false
	end
	return true
end

-- True when Blizzard must not if-test isFullUpdate or ipairs secret aura lists.
-- Tainted GetAuraSlots also fails for these payloads — skip the refresh.
function Secrets.AuraUpdateInfoHasSecrets(info)
	if info == nil then
		return false
	end
	if Secrets.IsSecretValue(info) then
		return true
	end
	if type(info) ~= "table" then
		return false
	end
	if Secrets.IsSecretTable(info) or not Secrets.CanAccessTable(info) then
		return true
	end
	if Secrets.IsSecretValue(info.isFullUpdate) then
		return true
	end
	local function fieldSecret(v)
		if v == nil then
			return false
		end
		if Secrets.IsSecretValue(v) then
			return true
		end
		if type(v) == "table" and (Secrets.IsSecretTable(v) or not Secrets.CanAccessTable(v)) then
			return true
		end
		return false
	end
	return fieldSecret(info.addedAuras)
		or fieldSecret(info.removedAuraInstanceIDs)
		or fieldSecret(info.updatedAuraInstanceIDs)
end
