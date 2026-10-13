-- Name.lua — character identity for SavedVariables, display, and comparisons.
-- Forever regional unique names: UnitName's second return is a surname, not a realm.
-- Live / Era / Anniversary stay single given name + realm. Feature-detect only.
local addonName, ns = ...
local Flux = ns.Flux

local PlayerName = {}
Flux.PlayerName = PlayerName
Flux.API = Flux.API or {}
Flux.API.PlayerName = PlayerName

local REALMLESS_TOKEN = "Forever"
local DEFAULT_SEP = "-"

local function SafeStr(value)
	local S = Flux.Secrets
	if S and S.SafeAccessibleString then
		return S.SafeAccessibleString(value)
	end
	if type(value) ~= "string" or value == "" then
		return nil
	end
	return value
end

local function PCallStr(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, a, b = pcall(fn, ...)
	if not ok then
		return nil
	end
	return a, b
end

function PlayerName.GetSurnameSeparator()
	local consts = rawget(_G, "Constants")
	local sep = consts and consts.CharacterNameSeparatorConsts and consts.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR
	if type(sep) == "string" and sep ~= "" then
		return sep
	end
	return DEFAULT_SEP
end

function PlayerName.UsesRegionalUniqueNames()
	if type(RegionalUniqueNamesEnabled) ~= "function" then
		return false
	end
	local ok, enabled = pcall(RegionalUniqueNamesEnabled)
	return ok and enabled and true or false
end

local function SplitOnSep(full, sep)
	if type(full) ~= "string" or type(sep) ~= "string" or sep == "" then
		return nil, nil
	end
	if sep == "-" then
		return string.match(full, "^([^-]+)%-(.*)$")
	end
	local a, b = string.match(full, "^(.-)" .. sep .. "(.*)$")
	return a, b
end

function PlayerName.GetUnitNameParts(unit)
	unit = unit or "player"
	local name, second = PCallStr(UnitNameUnmodified, unit)
	if not SafeStr(name) then
		name, second = PCallStr(UnitName, unit)
	end
	name = SafeStr(name)
	second = SafeStr(second)
	if not name then
		return nil, nil, false
	end

	local unique = PlayerName.UsesRegionalUniqueNames()
	if unique then
		local sep = PlayerName.GetSurnameSeparator()
		local first, stuffed = SplitOnSep(name, sep)
		if first and stuffed and stuffed ~= "" then
			return first, second or stuffed, true
		end
		return name, second, true
	end
	return name, second, false
end

function PlayerName.GetFirstName(unit)
	unit = unit or "player"
	if PlayerName.UsesRegionalUniqueNames() then
		local util = rawget(_G, "NameUtil")
		if util and type(util.GetUnitFirstName) == "function" then
			local first = SafeStr(PCallStr(util.GetUnitFirstName, unit))
			if first then
				return first
			end
		end
	end
	local first = PlayerName.GetUnitNameParts(unit)
	return first
end

function PlayerName.GetFullName(unit)
	unit = unit or "player"
	local first, second, secondIsSurname = PlayerName.GetUnitNameParts(unit)
	if not first then
		return nil
	end
	if secondIsSurname then
		local util = rawget(_G, "NameUtil")
		if util and type(util.GetFullNameWithoutRealm) == "function" then
			local joined = SafeStr(PCallStr(util.GetFullNameWithoutRealm, first, second))
			if joined then
				return joined
			end
		end
		if second and second ~= "" then
			local sep = PlayerName.GetSurnameSeparator()
			if first:find(sep, 1, true) then
				return first
			end
			return first .. sep .. second
		end
	end
	return first
end

PlayerName.SURNAME_OWN_CVAR = "UnitSurnameOwn"

function PlayerName.ShouldDisplaySurname()
	if not PlayerName.UsesRegionalUniqueNames() then
		return false
	end
	local info = C_PlayerInfo
	if info and type(info.ShouldDisplaySurname) == "function" then
		local ok, display = pcall(info.ShouldDisplaySurname)
		if ok and type(display) == "boolean" then
			return display
		end
	end
	if C_CVar and type(C_CVar.GetCVarBool) == "function" then
		local ok, display = pcall(C_CVar.GetCVarBool, PlayerName.SURNAME_OWN_CVAR)
		if ok and type(display) == "boolean" then
			return display
		end
	end
	if type(GetCVarBool) == "function" then
		local ok, display = pcall(GetCVarBool, PlayerName.SURNAME_OWN_CVAR)
		if ok and type(display) == "boolean" then
			return display
		end
	end
	return true
end

function PlayerName.SetDisplaySurname(enabled)
	local value = enabled and "1" or "0"
	if C_CVar and type(C_CVar.SetCVar) == "function" then
		local ok = pcall(C_CVar.SetCVar, PlayerName.SURNAME_OWN_CVAR, value)
		if ok then
			return true
		end
	end
	if type(SetCVar) == "function" then
		local ok = pcall(SetCVar, PlayerName.SURNAME_OWN_CVAR, value)
		return ok and true or false
	end
	return false
end

function PlayerName.GetDisplayName(unit, showRealm)
	unit = unit or "player"
	if PlayerName.UsesRegionalUniqueNames() then
		if UnitIsUnit then
			local okSame, isMe = pcall(UnitIsUnit, unit, "player")
			if okSame and isMe and PlayerName.ShouldDisplaySurname() == false then
				return PlayerName.GetFirstName(unit) or PlayerName.GetFullName(unit)
			end
		end
		local util = rawget(_G, "NameUtil")
		if util and type(util.FormatUnitNameForDisplay) == "function" then
			local shown = SafeStr(PCallStr(util.FormatUnitNameForDisplay, unit, showRealm))
			if shown then
				return shown
			end
		end
		return PlayerName.GetFullName(unit)
	end
	if showRealm and GetUnitName then
		local shown = SafeStr(PCallStr(GetUnitName, unit, true))
		if shown then
			return shown
		end
	end
	return PlayerName.GetFirstName(unit)
end

function PlayerName.GetRealmDisplay()
	-- Never take UnitName's second return when unique names are on (that is a surname).
	local realm = SafeStr(PCallStr(GetRealmName))
	if realm then
		return realm
	end
	realm = SafeStr(PCallStr(GetNormalizedRealmName))
	if realm then
		return realm
	end
	if PlayerName.UsesRegionalUniqueNames() then
		return REALMLESS_TOKEN
	end
	return nil
end

function PlayerName.GetRealmToken()
	local realm = SafeStr(PCallStr(GetNormalizedRealmName))
	if realm then
		return realm
	end
	local display = PlayerName.GetRealmDisplay()
	if display and display ~= REALMLESS_TOKEN then
		local compact = display:gsub("%s+", "")
		if compact ~= "" then
			return compact
		end
	end
	if PlayerName.UsesRegionalUniqueNames() then
		return REALMLESS_TOKEN
	end
	return display
end

function PlayerName.IsCharacterIdentityReady()
	local name = PlayerName.GetFullName("player")
	if not name then
		return false
	end
	if PlayerName.UsesRegionalUniqueNames() then
		return PlayerName.GetRealmDisplay() ~= nil
	end
	local realm = SafeStr(PCallStr(GetRealmName))
	return realm ~= nil
end

function PlayerName.GetCharKey(style)
	style = style or "hyphen"
	local full = PlayerName.GetFullName("player")
	if not full then
		return nil
	end
	if style == "inventory" then
		local realm = PlayerName.GetRealmToken()
		if not realm then
			return nil
		end
		return full .. "-" .. realm
	end
	local realm
	if style == "profile" and not PlayerName.UsesRegionalUniqueNames() then
		-- Live/classic Char-* profiles historically used UnitFullName's realm.
		local _n, fullRealm = PCallStr(UnitFullName, "player")
		realm = SafeStr(fullRealm)
	end
	realm = realm or PlayerName.GetRealmDisplay()
	if not realm then
		return nil
	end
	if style == "acedb" then
		return full .. " - " .. realm
	end
	if style == "professions" then
		return realm .. "-" .. full
	end
	if style == "profile" then
		return "Char - " .. full .. " - " .. realm
	end
	return full .. "-" .. realm
end

function PlayerName.SplitCharKey(key)
	if type(key) ~= "string" then
		return nil, nil
	end
	return string.match(key, "^(.+)%-([^-]+)$")
end

local function FoldName(name)
	name = SafeStr(name)
	if not name then
		return nil
	end
	return string.lower((name:gsub("%s+", "-")))
end

function PlayerName.NamesEqual(a, b)
	a, b = SafeStr(a), SafeStr(b)
	if not a or not b then
		return false
	end
	if a == b then
		return true
	end
	local na, nb = FoldName(a), FoldName(b)
	if not na or not nb then
		return false
	end
	if na == nb then
		return true
	end
	if not PlayerName.UsesRegionalUniqueNames() then
		return false
	end
	local a1, a2 = SplitOnSep(na, "-")
	if not a1 then
		a1 = na
	end
	local b1, b2 = SplitOnSep(nb, "-")
	if not b1 then
		b1 = nb
	end
	if a1 ~= b1 then
		return false
	end
	if not a2 or a2 == "" or not b2 or b2 == "" then
		return true
	end
	return a2 == b2
end

function PlayerName.IsUnitPlayer(unit)
	if type(unit) ~= "string" or unit == "" or not UnitIsUnit then
		return false
	end
	local ok, same = pcall(UnitIsUnit, unit, "player")
	return ok and same and true or false
end

function PlayerName.MigrateKeyedTable(tbl, oldKey, newKey)
	if type(tbl) ~= "table" or type(oldKey) ~= "string" or type(newKey) ~= "string" then
		return false
	end
	if oldKey == newKey then
		return false
	end
	local old = tbl[oldKey]
	if old == nil then
		return false
	end
	if tbl[newKey] == nil then
		tbl[newKey] = old
		tbl[oldKey] = nil
		return true
	end
	return false
end

local function AddKey(list, seen, key)
	if type(key) ~= "string" or key == "" or seen[key] then
		return
	end
	seen[key] = true
	list[#list + 1] = key
end

local function CompactName(name)
	if type(name) ~= "string" then
		return nil
	end
	local s = name:gsub("%s+", "")
	if s == "" then
		return nil
	end
	return s
end

--- Possible pre-helper keys for the current character (Forever first-name-only / surname-as-realm).
function PlayerName.GetLegacyCharKeys(style)
	if not PlayerName.UsesRegionalUniqueNames() then
		return nil
	end
	local first = PlayerName.GetFirstName("player")
	local _, surname = PlayerName.GetUnitNameParts("player")
	local realmDisplay = SafeStr(PCallStr(GetRealmName))
	local realmNorm = SafeStr(PCallStr(GetNormalizedRealmName))
	if not first then
		return nil
	end

	local names = {}
	local seenNames = {}
	AddKey(names, seenNames, first)
	AddKey(names, seenNames, CompactName(first))

	local realms = {}
	local seenRealms = {}
	AddKey(realms, seenRealms, realmDisplay)
	AddKey(realms, seenRealms, realmNorm)
	AddKey(realms, seenRealms, surname)
	AddKey(realms, seenRealms, CompactName(realmDisplay))
	AddKey(realms, seenRealms, CompactName(realmNorm))

	local keys = {}
	local seen = {}
	for i = 1, #names do
		local n = names[i]
		if style == "acedb" then
			for r = 1, #realms do
				AddKey(keys, seen, n .. " - " .. realms[r])
			end
		elseif style == "profile" then
			for r = 1, #realms do
				AddKey(keys, seen, "Char - " .. n .. " - " .. realms[r])
			end
		elseif style == "professions" then
			for r = 1, #realms do
				AddKey(keys, seen, realms[r] .. "-" .. n)
			end
		elseif style == "inventory" then
			for r = 1, #realms do
				local compact = CompactName(realms[r]) or realms[r]
				AddKey(keys, seen, n .. "-" .. compact)
				AddKey(keys, seen, n .. "-" .. realms[r])
			end
		else
			for r = 1, #realms do
				AddKey(keys, seen, n .. "-" .. realms[r])
			end
		end
	end
	return keys
end

function PlayerName.MigrateCurrentCharacterKeys(tbl, style)
	if type(tbl) ~= "table" then
		return
	end
	local newKey = PlayerName.GetCharKey(style)
	local olds = PlayerName.GetLegacyCharKeys(style)
	if not newKey or not olds then
		return
	end
	for i = 1, #olds do
		PlayerName.MigrateKeyedTable(tbl, olds[i], newKey)
	end
end

function PlayerName.MigrateCurrentCharacterAccountData()
	if not PlayerName.UsesRegionalUniqueNames() then
		return
	end
	if not PlayerName.IsCharacterIdentityReady() then
		return
	end

	local db = rawget(_G, "FluxUI_DB")
	if type(db) == "table" then
		if type(db.characters) ~= "table" then
			db.characters = {}
		end
		PlayerName.MigrateCurrentCharacterKeys(db.characters, "hyphen")
	end

	local options = rawget(_G, "FluxUI_Options")
	if type(options) == "table" then
		if type(options.profileKeys) == "table" then
			PlayerName.MigrateCurrentCharacterKeys(options.profileKeys, "acedb")
		end
		if type(options.char) == "table" then
			PlayerName.MigrateCurrentCharacterKeys(options.char, "acedb")
		end
		if type(options.profiles) == "table" then
			PlayerName.MigrateCurrentCharacterKeys(options.profiles, "profile")
		end
	end

	local gold = rawget(_G, "FluxUIGoldLedger")
	if type(gold) == "table" and type(gold.chars) == "table" then
		PlayerName.MigrateCurrentCharacterKeys(gold.chars, "inventory")
	end
	if type(gold) == "table" and type(gold.deleted) == "table" then
		PlayerName.MigrateCurrentCharacterKeys(gold.deleted, "inventory")
	end

	local inv = rawget(_G, "FluxUIInventoryDB")
	if type(inv) == "table" and type(inv.Characters) == "table" then
		PlayerName.MigrateCurrentCharacterKeys(inv.Characters, "inventory")
	end
	if type(inv) == "table" and inv.Pending and type(inv.Pending.Characters) == "table" then
		PlayerName.MigrateCurrentCharacterKeys(inv.Pending.Characters, "inventory")
	end

	local fluxInv = rawget(_G, "FluxInvDB")
	if type(fluxInv) == "table" and type(fluxInv.professions) == "table" then
		PlayerName.MigrateCurrentCharacterKeys(fluxInv.professions, "professions")
	end

	local favorites = rawget(_G, "FluxFlyoutFavorites_Data")
	if type(favorites) == "table" then
		PlayerName.MigrateCurrentCharacterKeys(favorites, "hyphen")
	end

	local ncg = rawget(_G, "FluxNonCombatGridDB")
	if type(ncg) == "table" then
		PlayerName.MigrateCurrentCharacterKeys(ncg, "hyphen")
	end
end

if Flux.AfterLoad then
	Flux.AfterLoad(PlayerName.MigrateCurrentCharacterAccountData)
end
if Flux.AfterLogin then
	Flux.AfterLogin(PlayerName.MigrateCurrentCharacterAccountData)
end
