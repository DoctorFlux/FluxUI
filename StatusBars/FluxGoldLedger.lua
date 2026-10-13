-- FluxUI account gold ledger.
--
-- Rewritten to use one simple stable row per character:
--   FluxUIGoldLedger.chars["Name-NormalizedRealm"] = { m = copper, ... }
--
-- The old FluxUIGoldLedger.c table is migrated once, then removed. If
-- Syndicator is loaded, its character money is imported as a recovery source.

_G.FluxGoldLedger = _G.FluxGoldLedger or {}
local G = _G.FluxGoldLedger

local DB_VERSION = 4
local TOOLTIP_LIMIT = 12

local function Now()
    if type(time) == "function" then
        return time()
    end
    return 0
end

local function CleanName(name)
    if name == nil then
        return nil
    end
    -- Forever first+last may use a space in some APIs; collapse to the hyphen form.
    -- Do not strip spaces entirely (that would turn "First Last" into "FirstLast").
    local s = tostring(name):gsub("%s+", "-")
    if s == "" or s == "?" then
        return nil
    end
    return s
end

local function CleanRealm(realm)
    if realm == nil then
        return nil
    end
    local s = tostring(realm):gsub("%s+", ""):gsub("%-+", "")
    if s == "" or s == "?" then
        return nil
    end
    return s
end

local function NormName(name)
    return string.lower(CleanName(name) or "")
end

local function NormRealm(realm)
    return string.lower(CleanRealm(realm) or "")
end

local function MakeKey(name, realm)
    name = CleanName(name)
    realm = CleanRealm(realm)
    if not name or not realm then
        return nil
    end
    return name .. "-" .. realm
end

local function SplitKey(key)
    if type(key) ~= "string" then
        return nil, nil
    end
    local PN = _G.Flux and _G.Flux.PlayerName
    local name, realm
    if PN and PN.SplitCharKey then
        name, realm = PN.SplitCharKey(key)
    else
        name, realm = key:match("^(.+)%-([^-]+)$")
    end
    return CleanName(name), CleanRealm(realm)
end

local function GetNormalizedRealm()
    local PN = _G.Flux and _G.Flux.PlayerName
    if PN and PN.GetRealmToken then
        local realm = PN.GetRealmToken()
        if CleanRealm(realm) then
            return CleanRealm(realm)
        end
    end
    if type(GetNormalizedRealmName) == "function" then
        local ok, realm = pcall(GetNormalizedRealmName)
        if ok and CleanRealm(realm) then
            return CleanRealm(realm)
        end
    end
    if type(GetRealmName) == "function" then
        return CleanRealm(GetRealmName())
    end
    return nil
end

local function GetPlayerContext()
    local PN = _G.Flux and _G.Flux.PlayerName
    local name, realmN, realmDisplay
    if PN and PN.GetFullName then
        name = PN.GetFullName("player")
        realmN = PN.GetRealmToken and PN.GetRealmToken()
        realmDisplay = PN.GetRealmDisplay and PN.GetRealmDisplay()
    end
    if not CleanName(name) and type(UnitName) == "function" then
        name = UnitName("player")
    end

    realmN = CleanRealm(realmN) or GetNormalizedRealm()
    if type(GetRealmName) == "function" then
        realmDisplay = GetRealmName() or realmDisplay
    end
    realmDisplay = realmDisplay or realmN

    local faction = "Neutral"
    if type(UnitFactionGroup) == "function" then
        local a, b = UnitFactionGroup("player")
        faction = tostring(a or b or "Neutral")
    end

    return CleanName(name), realmDisplay, realmN, faction
end

function G:LedgerKey(name, realmRaw)
    return MakeKey(name, realmRaw) or "?"
end

function G:CharKeyForPlayer()
    local name, _realm, realmN = GetPlayerContext()
    return MakeKey(name, realmN) or "?"
end

local function MoneyValue(row)
    if type(row) ~= "table" then
        return nil
    end
    local v = row.m
    if v == nil then
        v = row.money
    end
    if v == nil then
        v = row.copper
    end
    if v == nil then
        v = row.amount
    end
    if type(v) == "number" then
        return math.max(0, math.floor(v))
    end
    if type(v) == "string" then
        local n = tonumber(v)
        if n then
            return math.max(0, math.floor(n))
        end
    end
    return nil
end

local function Useful(value)
    return value ~= nil and tostring(value) ~= "" and tostring(value) ~= "?"
end

local function CopyField(dst, src, key, force)
    if type(src) ~= "table" then
        return
    end
    if Useful(src[key]) and (force or not Useful(dst[key])) then
        dst[key] = src[key]
    end
end

local function StampKeyMetadata(row, key)
    local keyName, keyRealm = SplitKey(key)
    if keyName and not Useful(row.name) then
        row.name = keyName
    end
    if keyRealm and not Useful(row.realmN) then
        row.realmN = keyRealm
    end
    if keyRealm and not Useful(row.realm) then
        row.realm = keyRealm
    end
end

local function MergeRow(db, key, src, exactMoney)
    if type(db) ~= "table" or type(db.chars) ~= "table" or type(src) ~= "table" then
        return false
    end
    if type(key) ~= "string" or key == "" or key == "?" then
        return false
    end
    if db.deleted and db.deleted[key] then
        return false
    end

    local money = MoneyValue(src)
    if money == nil then
        money = 0
    end

    local dst = db.chars[key]
    if type(dst) ~= "table" then
        dst = {}
        db.chars[key] = dst
    end

    local oldMoney = MoneyValue(dst)
    if oldMoney == nil then
        oldMoney = -1
    end

    local srcTime = (type(src.t) == "number" and src.t) or 0
    local dstTime = (type(dst.t) == "number" and dst.t) or 0
    local useSrc = exactMoney or money > oldMoney or (money == oldMoney and srcTime >= dstTime)

    if exactMoney then
        dst.m = money
    else
        dst.m = math.max(oldMoney, money, 0)
    end
    dst.t = math.max(dstTime, srcTime, 0)

    CopyField(dst, src, "name", useSrc)
    CopyField(dst, src, "realm", useSrc)
    CopyField(dst, src, "realmN", useSrc)
    CopyField(dst, src, "faction", useSrc)
    CopyField(dst, src, "class", useSrc)
    CopyField(dst, src, "classFile", useSrc)
    CopyField(dst, src, "race", useSrc)
    CopyField(dst, src, "raceFile", useSrc)
    CopyField(dst, src, "rid", useSrc)
    CopyField(dst, src, "sex", useSrc)
    CopyField(dst, src, "source", false)
    StampKeyMetadata(dst, key)
    return true
end

local function BadRealmForName(name, realm)
    local n = NormName(name)
    local r = NormRealm(realm)
    return r == "" or r == n
end

local function BuildRealmHints(c)
    local hints, ambiguous = {}, {}
    local function remember(name, realm)
        local n = NormName(name)
        local r = NormRealm(realm)
        if n == "" or r == "" or BadRealmForName(name, realm) then
            return
        end
        if hints[n] and hints[n] ~= r then
            hints[n] = nil
            ambiguous[n] = true
        elseif not ambiguous[n] then
            hints[n] = r
        end
    end

    for key, row in pairs(c or {}) do
        if type(row) == "table" then
            remember(row.name, row.realmN or row.realm)
            if type(key) == "string" then
                local a, b = key:match("^([^@]+)@(.+)$")
                if a and b then
                    remember(a, b)
                else
                    local p1, p2 = key:match("^([^\0]+)\0([^\0]+)$")
                    if p1 and p2 then
                        if Useful(row.name) and NormName(row.name) == NormName(p1) then
                            remember(row.name, p2)
                        elseif Useful(row.name) and NormName(row.name) == NormName(p2) then
                            remember(row.name, p1)
                        end
                    else
                        local n, r = SplitKey(key)
                        remember(n, r)
                    end
                end
            end
        end
    end
    return hints
end

local function KeyFromOldEntry(key, row, hints)
    local name = CleanName(row and row.name)
    local realm = CleanRealm(row and (row.realmN or row.realm))

    if name and realm and not BadRealmForName(name, realm) then
        return MakeKey(name, realm)
    end

    if type(key) == "string" then
        local a, b = key:match("^([^@]+)@(.+)$")
        if a and b then
            name = name or CleanName(a)
            realm = realm or CleanRealm(b)
        else
            local p1, p2 = key:match("^([^\0]+)\0([^\0]+)$")
            if p1 and p2 then
                if name and NormName(name) == NormName(p1) then
                    realm = realm or CleanRealm(p2)
                elseif name and NormName(name) == NormName(p2) then
                    realm = realm or CleanRealm(p1)
                elseif realm and NormRealm(realm) == NormRealm(p1) then
                    name = name or CleanName(p2)
                elseif realm and NormRealm(realm) == NormRealm(p2) then
                    name = name or CleanName(p1)
                else
                    name = name or CleanName(p1)
                    realm = realm or CleanRealm(p2)
                end
            else
                local n, r = SplitKey(key)
                name = name or n
                realm = realm or r
            end
        end
    end

    if name and (not realm or BadRealmForName(name, realm)) then
        realm = hints and hints[NormName(name)] or realm
    end
    return MakeKey(name, realm)
end

local function MigrateOldFluxRows(db)
    if type(db) ~= "table" or type(db.c) ~= "table" or db._fluxGoldLedgerV4Migrated then
        return
    end
    db.chars = type(db.chars) == "table" and db.chars or {}
    db.deleted = type(db.deleted) == "table" and db.deleted or {}

    local hints = BuildRealmHints(db.c)
    local moved = 0
    for key, row in pairs(db.c) do
        if type(row) == "table" then
            local newKey = KeyFromOldEntry(key, row, hints)
            if newKey and MergeRow(db, newKey, row, false) then
                moved = moved + 1
            end
        end
    end

    db.c = nil
    db._fluxGoldLedgerV4Migrated = true
    db._fluxGoldLedgerV4MigratedAt = Now()
    db._fluxGoldLedgerV4MigratedRows = moved
end

local function Ensure()
    if type(FluxUIGoldLedger) ~= "table" then
        _G.FluxUIGoldLedger = {}
    end
    local db = _G.FluxUIGoldLedger
    db.version = DB_VERSION
    db.chars = type(db.chars) == "table" and db.chars or {}
    db.deleted = type(db.deleted) == "table" and db.deleted or {}
    MigrateOldFluxRows(db)
    return db
end

local function RowFromSyndicator(fullName, data)
    if type(fullName) ~= "string" or type(data) ~= "table" then
        return nil, nil
    end
    local details = type(data.details) == "table" and data.details or {}
    local parsedName, parsedRealm = SplitKey(fullName)
    local name = CleanName(details.character) or parsedName
    local realmN = CleanRealm(details.realmNormalized) or parsedRealm
    local key = MakeKey(name, realmN)
    if not key then
        return nil, nil
    end

    local classFile = details.className
    if type(classFile) ~= "string" then
        classFile = nil
    end

    return key, {
        m = MoneyValue(data) or 0,
        name = name,
        realm = details.realm or realmN,
        realmN = realmN,
        faction = details.faction,
        classFile = classFile,
        raceFile = details.race,
        sex = details.sex,
        t = Now(),
        source = "Syndicator",
    }
end

local function ImportSyndicatorGold()
    local db = Ensure()
    local data = _G.SYNDICATOR_DATA
    if type(data) ~= "table" or type(data.Characters) ~= "table" then
        return 0
    end

    local imported = 0
    local currentKey = G:CharKeyForPlayer()
    for fullName, charData in pairs(data.Characters) do
        local key, row = RowFromSyndicator(fullName, charData)
        if key and row and key ~= currentKey and MergeRow(db, key, row, false) then
            imported = imported + 1
        end
    end
    db.lastSyndicatorImport = Now()
    db.lastSyndicatorImportRows = imported
    return imported
end

function G:FormatCopper(copper)
    copper = tonumber(copper) or 0
    if copper < 0 then
        copper = 0
    end
    if type(_G.GetMoneyString) == "function" then
        local ok, text = pcall(_G.GetMoneyString, copper, true)
        if ok and text and text ~= "" then
            return text
        end
    end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local c = math.floor(copper % 100)
    if gold > 0 and type(_G.BreakUpLargeNumbers) == "function" then
        gold = BreakUpLargeNumbers(gold)
    end
    return tostring(gold) .. "g " .. tostring(silver) .. "s " .. tostring(c) .. "c"
end

local function IsRetailProject()
    return _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE
end

local RACE_ATLAS_CORR = {
    scourge = "undead",
    zandalaritroll = "zandalari",
    highmountaintauren = "highmountain",
    lightforgeddraenei = "lightforged",
    earthendwarf = "earthen",
    harronir = "haranir",
}

local function ClassFileNorm(classFile)
    if not Useful(classFile) then
        return nil
    end
    local s = tostring(classFile)
    if _G.RAID_CLASS_COLORS and RAID_CLASS_COLORS[s:upper()] then
        return s:upper()
    end
    return s
end

local function ClassColorWrapName(name, classFile)
    name = tostring(name or "?")
    classFile = ClassFileNorm(classFile)
    if not classFile then
        return "|cFFFFFFFF" .. name .. "|r"
    end
    if _G.C_ClassColor and C_ClassColor.GetClassColor then
        local ok, c = pcall(C_ClassColor.GetClassColor, classFile)
        if ok and c and c.WrapTextInColorCode then
            local wrapped = c:WrapTextInColorCode(name)
            if type(wrapped) == "string" and wrapped ~= "" then
                return wrapped
            end
        end
    end
    local color = (_G.CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFile])
        or (_G.RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile])
    if color and type(color.colorStr) == "string" and color.colorStr ~= "" then
        local s = color.colorStr
        if s:sub(1, 2) == "|c" then
            return s .. name .. "|r"
        end
        if s:len() == 8 then
            return "|c" .. s .. name .. "|r"
        end
        if s:len() == 6 then
            return "|cFF" .. s .. name .. "|r"
        end
    end
    return "|cFFFFFFFF" .. name .. "|r"
end

local function ClassIconMarkup(classFile)
    classFile = ClassFileNorm(classFile)
    if not classFile then
        return ""
    end
    if IsRetailProject() then
        return string.format("|A:groupfinder-icon-class-%s:14:14|a", string.lower(classFile))
    end
    local coords = _G.CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
    if coords then
        return string.format(
            "|TInterface/TargetingFrame/UI-Classes-Circles:0:0:0:0:256:256:%.3f:%.3f:%.3f:%.3f|t",
            coords[1] * 256,
            coords[2] * 256,
            coords[3] * 256,
            coords[4] * 256
        )
    end
    return ""
end

local function RaceIconMarkup(raceFile, sex)
    if not Useful(raceFile) then
        return ""
    end
    local race = tostring(raceFile):gsub("%s+", "")
    race = RACE_ATLAS_CORR[string.lower(race)] or string.lower(race)
    local gender = ({ "unknown", "male", "female" })[tonumber(sex) or 2] or "male"
    local prefix = IsRetailProject() and "raceicon128" or "raceicon"
    return string.format("|A:%s-%s-%s:14:14|a", prefix, race, gender)
end

local function LeftText(row)
    return RaceIconMarkup(row.raceFile, row.sex)
        .. ClassIconMarkup(row.classFile)
        .. ClassColorWrapName(row.name or "?", row.classFile)
end

local function FactionInScope(rowFaction, currentFaction)
    if not Useful(rowFaction) then
        return true
    end
    local a = string.lower(tostring(rowFaction):gsub("%s+", ""))
    local b = string.lower(tostring(currentFaction or ""):gsub("%s+", ""))
    return a == b or a == "neutral" or b == "neutral"
end

local function IsAccountWide()
    local api = _G.FLUX_API
    if api and api.useAccountWideGoldLedger ~= nil then
        return api.useAccountWideGoldLedger and true or false
    end
    if api and api.isRetail and api.isPostDF then
        return true
    end
    return false
end

local function GetConnectedRealmSet()
    local set = {}
    local function add(realm)
        local r = NormRealm(realm)
        if r ~= "" then
            set[r] = true
        end
    end
    if type(GetAutoCompleteRealms) == "function" then
        local ok, realms = pcall(GetAutoCompleteRealms)
        if ok and type(realms) == "table" then
            for i = 1, #realms do
                add(realms[i])
            end
            for _k, v in pairs(realms) do
                add(v)
            end
        end
    end
    add(GetNormalizedRealm())
    return set
end

local function RowInScope(row, currentRealmN, currentFaction, accountWide, connected)
    if type(row) ~= "table" then
        return false
    end
    if accountWide then
        return true
    end
    if not FactionInScope(row.faction, currentFaction) then
        return false
    end
    local r = NormRealm(row.realmN or row.realm)
    if r == "" then
        return false
    end
    return r == NormRealm(currentRealmN) or (connected and connected[r]) or false
end

local function PlayerNameAPI()
    return _G.Flux and _G.Flux.PlayerName
end

local function UniqueNames()
    local PN = PlayerNameAPI()
    return PN and PN.UsesRegionalUniqueNames and PN.UsesRegionalUniqueNames() or false
end

local function NamesMatch(a, b)
    if not Useful(a) or not Useful(b) then
        return false
    end
    local PN = PlayerNameAPI()
    if PN and PN.NamesEqual then
        return PN.NamesEqual(a, b)
    end
    local na, nb = NormName(a), NormName(b)
    return na ~= "" and na == nb
end

local function RealmsMatch(a, b)
    local ra, rb = NormRealm(a), NormRealm(b)
    if ra ~= "" and rb ~= "" then
        return ra == rb
    end
    if ra == rb then
        return true
    end
    -- Forever Syndicator rows often have an empty realm next to Flux's token.
    return UniqueNames()
end

local function RowNameRealm(key, row)
    local name = row and row.name
    local realm = row and (row.realmN or row.realm)
    if not Useful(name) or not Useful(realm) then
        local kn, kr = SplitKey(key)
        if not Useful(name) then
            name = kn
        end
        if not Useful(realm) then
            realm = kr
        end
    end
    return name, realm
end

local function NormIdentity(key, row)
    local name, realm = RowNameRealm(key, row)
    name = CleanName(name)
    realm = CleanRealm(realm)
    if not name then
        return nil
    end
    return string.lower(name) .. "@" .. string.lower(realm or "")
end

local function SurnameLooksLikeRealm(name, realm)
    name, realm = NormName(name), NormRealm(realm)
    if name == "" or realm == "" then
        return false
    end
    if name == realm then
        return true
    end
    return name:sub(-(#realm + 1)) == "-" .. realm
end

local function SameGoldCharacter(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    if type(a.key) == "string" and a.key ~= "" and a.key == b.key then
        return true
    end
    local idA, idB = NormIdentity(a.key, a), NormIdentity(b.key, b)
    if idA and idA == idB then
        return true
    end
    local nA, rA = RowNameRealm(a.key, a)
    local nB, rB = RowNameRealm(b.key, b)
    if not NamesMatch(nA, nB) then
        return false
    end
    if RealmsMatch(rA, rB) then
        return true
    end
    -- Forever used to store surname as the realm half of Name-Realm.
    return UniqueNames()
        and (
            SurnameLooksLikeRealm(nA, rA)
            or SurnameLooksLikeRealm(nB, rB)
            or SurnameLooksLikeRealm(nA, rB)
            or SurnameLooksLikeRealm(nB, rA)
        )
end

local function NameCompleteness(name)
    name = tostring(name or "")
    local score = #name
    if name:find("-", 1, true) or name:find("%s") then
        score = score + 100
    end
    return score
end

local function IsBareGivenName(name)
    name = tostring(name or "")
    return name ~= "" and not name:find("-", 1, true) and not name:find("%s")
end

local function IsCurrentGoldRow(key, row, currentKey, playerName, realmN)
    if type(key) == "string" and key ~= "" and key == currentKey then
        return true
    end
    local name, realm = RowNameRealm(key, row)
    return NamesMatch(name, playerName) and RealmsMatch(realm, realmN)
end

local function RicherGoldRow(a, b)
    if not a then
        return b
    end
    if not b then
        return a
    end
    local out = {}
    for k, v in pairs(a) do
        out[k] = v
    end
    local bBetterName = NameCompleteness(b.name) > NameCompleteness(a.name)
    if bBetterName then
        out.name = b.name
        if Useful(b.key) then
            out.key = b.key
        end
        if Useful(b.k) then
            out.k = b.k
        end
        if Useful(b.n) then
            out.n = b.n
        end
    end
    local function take(field)
        if not Useful(out[field]) and Useful(b[field]) then
            out[field] = b[field]
        end
    end
    take("realm")
    take("realmN")
    take("r")
    take("faction")
    take("classFile")
    take("raceFile")
    take("sex")
    out.m = math.max(tonumber(a.m) or 0, tonumber(b.m) or 0)
    out.isCurrent = a.isCurrent or b.isCurrent
    return out
end

-- One tooltip/config row per character. Same person can be stored as
-- "First Last-Realm" and "First-Last-Realm", or Forever first-name vs first-last.
local function CollapseGoldRows(rows)
    local n = #rows
    if n < 2 then
        local total = 0
        for i = 1, n do
            total = total + (tonumber(rows[i].m) or 0)
        end
        return rows, total
    end

    local drop = {}
    local byId = {}
    for i = 1, n do
        local id = NormIdentity(rows[i].key, rows[i]) or ("#" .. i)
        local keep = byId[id]
        if keep then
            rows[keep] = RicherGoldRow(rows[keep], rows[i])
            drop[i] = true
        else
            byId[id] = i
        end
    end

    for i = 1, n do
        if not drop[i] and IsBareGivenName(rows[i].name) then
            local hits, last = 0, nil
            for j = 1, n do
                if i ~= j and not drop[j] and SameGoldCharacter(rows[i], rows[j]) then
                    hits = hits + 1
                    last = j
                end
            end
            if hits >= 1 then
                if hits == 1 then
                    rows[last] = RicherGoldRow(rows[last], rows[i])
                end
                drop[i] = true
            end
        end
    end

    for i = 1, n do
        if not drop[i] then
            for j = i + 1, n do
                if not drop[j] and SameGoldCharacter(rows[i], rows[j]) then
                    rows[i] = RicherGoldRow(rows[i], rows[j])
                    drop[j] = true
                end
            end
        end
    end

    local out, total = {}, 0
    for i = 1, n do
        if not drop[i] then
            out[#out + 1] = rows[i]
            total = total + (tonumber(rows[i].m) or 0)
        end
    end
    return out, total
end

local function InventoryGoldRows()
	local FluxNS = _G.Flux
	local Ledger = FluxNS and FluxNS.Inventory and FluxNS.Inventory.Ledger
	if Ledger and Ledger.GetGoldRows then
		return Ledger.GetGoldRows()
	end
	return nil
end

local function BuildRows(skipZero)
	local db = Ensure()
	local playerName, _realmDisplay, realmN, faction = GetPlayerContext()
	local accountWide = IsAccountWide()
	local connected = accountWide and nil or GetConnectedRealmSet()
	local currentKey = G:CharKeyForPlayer()
	local liveMoney = 0
	if type(GetMoney) == "function" then
		local ok, n = pcall(GetMoney)
		if ok and type(n) == "number" then
			liveMoney = n
		end
	end

	local source = InventoryGoldRows()
	if not source then
		ImportSyndicatorGold()
	end

	local rows = {}
	local function consider(key, row)
		if type(row) ~= "table" then
			return
		end
		if db.deleted and db.deleted[key] then
			return
		end
		local money = MoneyValue(row)
		local isCurrent = IsCurrentGoldRow(key, row, currentKey, playerName, realmN)
		if isCurrent then
			money = liveMoney
			row.m = liveMoney
		end
		if money and (not skipZero or money > 0) and RowInScope(row, realmN, faction, accountWide, connected) then
			local name, realm = RowNameRealm(key, row)
			rows[#rows + 1] = {
				key = key,
				name = name or "?",
				realm = row.realm or realm,
				realmN = row.realmN or realm,
				faction = row.faction,
				classFile = row.classFile or row.className,
				raceFile = row.raceFile or row.race,
				sex = row.sex,
				m = money,
				isCurrent = isCurrent,
			}
		end
	end

	if type(source) == "table" then
		for i = 1, #source do
			local row = source[i]
			if row then
				consider(row.key, row)
			end
		end
	else
		for key, row in pairs(db.chars or {}) do
			consider(key, row)
		end
	end

	local total
	rows, total = CollapseGoldRows(rows)

	table.sort(rows, function(a, b)
		if (a.m or 0) ~= (b.m or 0) then
			return (a.m or 0) > (b.m or 0)
		end
		return tostring(a.name or ""):lower() < tostring(b.name or ""):lower()
	end)

	return rows, total, accountWide, playerName, realmN, faction
end

function G:SaveCurrentMoney()
    if type(GetMoney) ~= "function" then
        return false
    end
    local name, realmDisplay, realmN, faction = GetPlayerContext()
    local key = MakeKey(name, realmN)
    if not key then
        return false
    end
    local ok, money = pcall(GetMoney)
    if not ok or type(money) ~= "number" then
        return false
    end
    money = math.max(0, math.floor(money))

    local db = Ensure()
    local existing = db.chars[key]
    if
        money == 0
        and type(existing) == "table"
        and (MoneyValue(existing) or 0) > 0
        and G._pewTime
        and type(GetTime) == "function"
        and (GetTime() - G._pewTime) < 30
    then
        return false
    end

    if db.deleted then
        db.deleted[key] = nil
    end

    local row = {
        m = money,
        name = name,
        realm = realmDisplay,
        realmN = realmN,
        faction = faction,
        t = Now(),
        source = "FluxUI",
    }
    if type(UnitClass) == "function" then
        local classLocalized, classFile = UnitClass("player")
        row.class = classLocalized
        row.classFile = classFile
    end
    if type(UnitRace) == "function" then
        local raceLocalized, raceFile, raceID = UnitRace("player")
        row.race = raceLocalized
        row.raceFile = raceFile
        row.rid = raceID
    end
    if type(UnitSex) == "function" then
        row.sex = UnitSex("player")
    end

    MergeRow(db, key, row, true)
    -- Drop leftover keys for this character (space vs hyphen, first-name vs first-last).
    local currentRow = { key = key, name = name, realm = realmDisplay, realmN = realmN }
    local stale = {}
    for otherKey, other in pairs(db.chars) do
        if otherKey ~= key and type(other) == "table" then
            if SameGoldCharacter(currentRow, {
                key = otherKey,
                name = other.name,
                realm = other.realm,
                realmN = other.realmN,
            }) then
                MergeRow(db, key, other, false)
                stale[#stale + 1] = otherKey
            end
        end
    end
    for i = 1, #stale do
        db.chars[stale[i]] = nil
    end
    self._lastSaveMoney = money
    self._forceResave = nil
    local FluxNS = _G.Flux
    local Store = FluxNS and FluxNS.Inventory and FluxNS.Inventory.Store
    if Store and Store.SetCurrentMoney then
        Store.SetCurrentMoney(money)
    end
    return true
end

function G:InvalidateCache()
    self._lastSaveMoney = nil
    self._forceResave = true
end

function G:ShowAccountGoldTooltip(anchor)
    if not anchor or not (GameTooltip and GameTooltip.SetOwner) then
        return
    end
    pcall(function()
        self:SaveCurrentMoney()
    end)

    local rows, total, accountWide = BuildRows(true)
    pcall(function()
        GameTooltip:Hide()
        if GameTooltip.ClearLines then
            GameTooltip:ClearLines()
        end
        GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT", 0, 0)
    end)

    if GameTooltip.SetText then
        GameTooltip:SetText("Account gold (FluxUI)", 0.8, 0.75, 0.3)
    elseif GameTooltip.AddLine then
        GameTooltip:AddLine("Account gold (FluxUI)", 0.8, 0.75, 0.3)
    end
    if GameTooltip.AddLine then
        local sub = accountWide and "All characters on this account (saved gold)" or "Connected realm + your faction (saved gold)"
        GameTooltip:AddLine(sub, 0.5, 0.55, 0.6, true)
    end

    if #rows == 0 then
        if GameTooltip.AddLine then
            GameTooltip:AddLine("No saved gold yet. Log in or open a bag addon cache once.", 0.45, 0.5, 0.55, true)
        end
    else
        for i = 1, math.min(TOOLTIP_LIMIT, #rows) do
            local row = rows[i]
            if GameTooltip.AddDoubleLine then
                GameTooltip:AddDoubleLine(LeftText(row), G:FormatCopper(row.m), 1, 1, 1, 1, 0.85, 0.1)
            elseif GameTooltip.AddLine then
                GameTooltip:AddLine(LeftText(row) .. "   " .. G:FormatCopper(row.m), 1, 1, 1, true)
            end
        end
        if #rows > TOOLTIP_LIMIT and GameTooltip.AddLine then
            GameTooltip:AddLine("(" .. tostring(#rows - TOOLTIP_LIMIT) .. " more not shown)", 0.45, 0.5, 0.55, true)
        end
    end

    local carried = 0
    pcall(function()
        carried = GetMoney() or 0
    end)
    if GameTooltip.AddLine then
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("Total (in scope): " .. G:FormatCopper(total), 1, 0.85, 0.1, false)
        GameTooltip:AddLine("Carried (this character now): " .. G:FormatCopper(carried), 0.2, 1, 0.2, true)
    end
    pcall(function()
        if GameTooltip.SetMinimumWidth then
            GameTooltip:SetMinimumWidth(200)
        end
        GameTooltip:Show()
    end)
end

function G:GetSummedContext()
    pcall(function()
        self:SaveCurrentMoney()
    end)
    local rows, total, accountWide, playerName, realmN, faction = BuildRows(true)
    return total, #rows, realmN, faction, accountWide, playerName
end

function G:GetSortedRowsInScope()
    pcall(function()
        self:SaveCurrentMoney()
    end)
    local rows, total = BuildRows(false)
    local out = {}
    for i, row in ipairs(rows) do
        out[i] = { m = row.m, name = row.name, realm = row.realm or row.realmN, n = row.m, k = row.key }
    end
    return out, total
end

function G:OnAfterGoldBarUpdate()
    self:SaveCurrentMoney()
end

local COIN_BUTTON_KEYS = { "GoldButton", "SilverButton", "CopperButton" }

-- Forever's gamepad bag is Blizzard's alone.
local function ForeverGamepadUI()
    return _G.FluxUI_IsForeverGamepadUI and _G.FluxUI_IsForeverGamepadUI() or false
end

function G:AttachBagMoneyTooltip(moneyFrame)
    if not moneyFrame or moneyFrame.FluxLedgerHooked or ForeverGamepadUI() then
        return
    end
    moneyFrame.FluxLedgerHooked = true
    local function showLedger(anchor)
        if ForeverGamepadUI() then
            return
        end
        G:ShowAccountGoldTooltip(anchor)
    end
    local function hideLedger()
        if GameTooltip and GameTooltip.Hide then
            pcall(GameTooltip.Hide, GameTooltip)
        end
    end
    local function hookButton(button)
        if not button or button.FluxLedgerBtn or not button.HookScript then
            return
        end
        button.FluxLedgerBtn = true
        button:HookScript("OnEnter", showLedger)
        button:HookScript("OnLeave", hideLedger)
    end
    hookButton(moneyFrame)
    for i = 1, #COIN_BUTTON_KEYS do
        hookButton(moneyFrame[COIN_BUTTON_KEYS[i]])
    end
    local name = moneyFrame.GetName and moneyFrame:GetName()
    if name then
        for i = 1, #COIN_BUTTON_KEYS do
            hookButton(_G[name .. COIN_BUTTON_KEYS[i]])
        end
    end
    if moneyFrame.GetChildren then
        local kids = { moneyFrame:GetChildren() }
        for i = 1, #kids do
            local kid = kids[i]
            local kidName = kid and kid.GetName and kid:GetName() or ""
            if kidName:find("Gold", 1, true) or kidName:find("Silver", 1, true) or kidName:find("Copper", 1, true) then
                hookButton(kid)
            end
        end
    end
end

local function FluxOwnsBagGold()
    if _G.FluxUI_UsesAlternativeBagUI and FluxUI_UsesAlternativeBagUI() then
        return false
    end
    return not ForeverGamepadUI()
end

local function AttachShownBagMoney()
    if not FluxOwnsBagGold() then
        return
    end
    local combined = _G.ContainerFrameCombinedBags
    if combined then
        G:AttachBagMoneyTooltip(combined.MoneyFrame)
        if not combined.FluxLedgerShowHook and combined.HookScript then
            combined.FluxLedgerShowHook = true
            combined:HookScript("OnShow", function(self)
                G:AttachBagMoneyTooltip(self.MoneyFrame)
            end)
        end
    end
    local fluxBags = _G.FluxCombinedBags
    if fluxBags and not fluxBags.FluxLedgerShowHook and fluxBags.HookScript then
        fluxBags.FluxLedgerShowHook = true
        fluxBags:HookScript("OnShow", AttachShownBagMoney)
    end
    local n = _G.NUM_CONTAINER_FRAMES or 13
    for i = 1, n do
        local frame = _G["ContainerFrame" .. i]
        if frame and frame.GetID and frame:GetID() == 0 then
            local money = frame.MoneyFrame
            if not money and frame.GetName then
                money = _G[frame:GetName() .. "MoneyFrame"]
            end
            G:AttachBagMoneyTooltip(money)
        end
    end
end

local function TruncateForDrop(value, maxLen)
    local s = tostring(value or "?")
    if #s <= maxLen then
        return s
    end
    return s:sub(1, maxLen - 1) .. "..."
end

local function ConfigAbbrevCopper(money)
    money = tonumber(money) or 0
    if money < 1 then
        return "0c"
    end
    local gold = math.floor(money / 10000)
    if gold >= 1 then
        if gold >= 1000 and type(_G.BreakUpLargeNumbers) == "function" then
            return BreakUpLargeNumbers(gold) .. "g"
        end
        return tostring(gold) .. "g"
    end
    local silver = math.floor((money % 10000) / 100)
    if silver >= 1 then
        return tostring(silver) .. "s"
    end
    return tostring(money % 100) .. "c"
end

function G:GetConfigLedgerIndex()
    local db = Ensure()
    local currentKey = self:CharKeyForPlayer()
    local arr = {}
    local source = InventoryGoldRows()
    local playerName, _realmDisplay, realmN = GetPlayerContext()
    local function add(key, row)
        if type(row) ~= "table" then
            return
        end
        if db.deleted and db.deleted[key] then
            return
        end
        local name, realm = RowNameRealm(key, row)
        name = name or "?"
        realm = realm or "?"
        local money = MoneyValue(row) or 0
        arr[#arr + 1] = {
            key = key,
            k = key,
            n = name,
            name = name,
            r = realm,
            realm = row.realm or realm,
            realmN = row.realmN or realm,
            m = money,
            isCurrent = IsCurrentGoldRow(key, row, currentKey, playerName, realmN),
        }
    end
    if type(source) == "table" then
        for i = 1, #source do
            local row = source[i]
            if row then
                add(row.key, row)
            end
        end
    else
        ImportSyndicatorGold()
        for key, row in pairs(db.chars or {}) do
            add(key, row)
        end
    end

    arr = CollapseGoldRows(arr)
    for i = 1, #arr do
        local e = arr[i]
        e.k = e.key or e.k
        e.n = e.name or e.n
        e.r = e.realm or e.realmN or e.r
        e.label = (e.isCurrent and "* " or "")
            .. TruncateForDrop(e.n, 25)
            .. " - "
            .. TruncateForDrop(e.r, 10)
            .. " - "
            .. ConfigAbbrevCopper(e.m)
    end

    table.sort(arr, function(a, b)
        local an = tostring(a.n or ""):lower()
        local bn = tostring(b.n or ""):lower()
        if an ~= bn then
            return an < bn
        end
        return tostring(a.r or ""):lower() < tostring(b.r or ""):lower()
    end)
    return arr
end

function G:DeleteLedgerEntryByKey(key)
    if type(key) ~= "string" or key == "" then
        return false
    end
    local db = Ensure()
    local removed = false
    if db.chars and db.chars[key] then
        db.chars[key] = nil
        removed = true
    end
    if db.c and db.c[key] then
        db.c[key] = nil
        removed = true
    end
    local FluxNS = _G.Flux
    local Store = FluxNS and FluxNS.Inventory and FluxNS.Inventory.Store
    if Store then
        if Store.GetCharacter and Store.GetCharacter(key) then
            removed = true
        end
        if Store.SetGoldHidden then
            Store.SetGoldHidden(key, true)
        end
    end
    db.deleted = type(db.deleted) == "table" and db.deleted or {}
    db.deleted[key] = true
    self:InvalidateCache()
    return true
end

function G:ConsolidateDuplicateGoldLedger()
    local db = Ensure()
    ImportSyndicatorGold()
    local chars = db.chars
    if type(chars) ~= "table" then
        return db
    end

    local buckets, order = {}, {}
    for key, row in pairs(chars) do
        if type(key) == "string" and type(row) == "table" then
            local id = NormIdentity(key, row) or key
            if not buckets[id] then
                order[#order + 1] = id
                buckets[id] = {}
            end
            buckets[id][#buckets[id] + 1] = key
        end
    end

    for i = 1, #order do
        local group = buckets[order[i]]
        if group and #group > 1 then
            local keepRow = chars[group[1]]
            local canon = MakeKey(keepRow and keepRow.name, keepRow and (keepRow.realmN or keepRow.realm)) or group[1]
            for g = 1, #group do
                local k = group[g]
                local src = chars[k]
                if src then
                    MergeRow(db, canon, src, false)
                    if k ~= canon then
                        chars[k] = nil
                    end
                end
            end
        end
    end
    return db
end

local function RefreshConfig()
    local acr = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if acr then
        pcall(acr.NotifyChange, acr, "FluxUI")
    end
end

if type(CreateFrame) == "function" then
    local frame = CreateFrame("Frame", "FluxGoldLedgerFrame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(_, event, addonName)
        if event == "PLAYER_ENTERING_WORLD" then
            if type(GetTime) == "function" then
                G._pewTime = GetTime()
            else
                G._pewTime = nil
            end
            G:ConsolidateDuplicateGoldLedger()
            G:InvalidateCache()
            AttachShownBagMoney()
            if C_Timer and C_Timer.After then
                C_Timer.After(3, function()
                    if G and G.SaveCurrentMoney then
                        pcall(function()
                            G:SaveCurrentMoney()
                        end)
                    end
                end)
                C_Timer.After(10, function()
                    if G and G.SaveCurrentMoney then
                        pcall(function()
                            G:SaveCurrentMoney()
                        end)
                    end
                end)
            end
        elseif event == "PLAYER_LOGOUT" then
            G:InvalidateCache()
            G:SaveCurrentMoney()
        elseif event == "ADDON_LOADED" and (addonName == "Syndicator" or addonName == "_FluxUI") then
            G:ConsolidateDuplicateGoldLedger()
            RefreshConfig()
        end
    end)
end

if type(hooksecurefunc) == "function" and type(_G.ContainerFrame_OnShow) == "function" then
    hooksecurefunc("ContainerFrame_OnShow", function(frame)
        if frame and frame.GetID and frame:GetID() == 0 then
            AttachShownBagMoney()
        end
    end)
end
AttachShownBagMoney()

do
    local function OnInvCurrency()
        G:InvalidateCache()
        G:SaveCurrentMoney()
        if _G.UpdateGoldBar then
            pcall(_G.UpdateGoldBar)
        end
    end
    local function TryRegister()
        local inv = _G.Flux and _G.Flux.Inventory
        if inv and inv.Register then
            inv.Register("FluxGoldLedger", function()
                OnInvCurrency()
            end, {
                tier = "instant",
                regions = { "currencies" },
                sync = true,
            })
            return true
        end
        return false
    end
    if not TryRegister() then
        local boot = CreateFrame("Frame")
        boot:RegisterEvent("PLAYER_LOGIN")
        boot:SetScript("OnEvent", function(self)
            if TryRegister() then
                self:UnregisterAllEvents()
            end
        end)
    end
end
