-- Full production Name/Secrets modules plus the real watched-unit decision.
-- Desktop Lua cannot model secret booleans' native branch errors. Sentinels and
-- an environment-local type adapter instead expose unsafe data-flow/results.
local namePath = (arg and arg[1]) or "Core/API/Name.lua"
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a"):gsub("\r\n", "\n"); file:close(); return source
end
local function fixture(withService, regional, client)
    client = client or "forever"
    local s = { same = false, surname = false, unique = regional, rawUnit = false,
        reads = { same = 0, nativeSurname = 0, cvar = 0, legacyCvar = 0,
            regional = 0, unitName = 0, formatted = 0 } }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local function forbidden() error("restricted value must not be inspected or coerced") end
    local boolSecret = setmetatable({}, { __tostring = forbidden, __concat = forbidden })
    local stringSecret = setmetatable({}, { __tostring = forbidden, __concat = forbidden, __len = forbidden })
    s.boolSecret, s.stringSecret = boolSecret, stringSecret
    local function isSecret(value) return rawequal(value, boolSecret) or rawequal(value, stringSecret) end
    env.type = function(value)
        if rawequal(value, boolSecret) then return "boolean" end
        if rawequal(value, stringSecret) then return "string" end
        return type(value)
    end
    env.issecretvalue, env.IsSecretValue = isSecret, isSecret
    env.canaccessvalue = function(value) return not isSecret(value) or s.secretAccessible == true end
    env.Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = " " } }
    env.RegionalUniqueNamesEnabled = function()
        s.reads.regional = s.reads.regional + 1
        if s.uniqueError then error("regional API not ready") end
        return s.unique
    end
    env.UnitNameUnmodified = function(unit)
        s.reads.unitName = s.reads.unitName + 1
        if s.rawUnit then return s.rawUnit end
        if unit == "player" then return "Alpha", regional and "Beta" or "RealmB" end
        return "Other", regional and "Surname" or "RealmB"
    end
    env.UnitName = env.UnitNameUnmodified
    env.UnitFullName = function() return "Alpha", "RealmB" end
    env.GetRealmName = function() return "Realm A" end
    env.GetNormalizedRealmName = function() return "RealmA" end
    env.GetUnitName = function(unit) return unit == "player" and "Alpha-RealmB" or "Other-RealmB" end
    env.UnitIsUnit = function()
        s.reads.same = s.reads.same + 1
        if s.sameError then error("identity unavailable") end
        return s.same
    end
    env.NameUtil = {
        FormatUnitNameForDisplay = function(unit)
            s.reads.formatted = s.reads.formatted + 1
            if s.rawUnit then return s.rawUnit end
            return unit == "player" and "Alpha Beta" or "Other Surname"
        end,
        GetFullNameWithoutRealm = function(first, surname) return first .. " " .. surname end,
    }
    env.C_PlayerInfo = { ShouldDisplaySurname = function()
        s.reads.nativeSurname = s.reads.nativeSurname + 1
        if s.surnameError then error("surname API unavailable") end
        return s.surname
    end }
    env.C_CVar = { GetCVarBool = function()
        s.reads.cvar = s.reads.cvar + 1; return s.cvar
    end, SetCVar = function(key, value) s.lastWrite = { key, value } end }
    env.GetCVarBool = function() s.reads.legacyCvar = s.reads.legacyCvar + 1; return s.legacyCvar end
    local ns = { Flux = { Client = { isRetail = client == "retail", isCamelot = client == "forever",
        isEra = client == "era", isAnniversary = client == "anniversary" } } }
    if withService then
        assert(loadfile("Core/API/Secrets.lua", "t", env))("_FluxUI", ns)
        local backend = (client == "retail" or client == "forever") and "Midnight" or "Classic"
        assert(loadfile("Core/API/Secrets_" .. backend .. ".lua", "t", env))("_FluxUI", ns)
    end
    assert(loadfile(namePath, "t", env))("_FluxUI", ns)
    s.name, s.env, s.ns = ns.Flux.PlayerName, env, ns
    return s
end

if arg and arg[2] == "--measure" then
    for _, client in ipairs({ "retail", "forever", "era", "anniversary", "classic" }) do
        local s = fixture(true, client == "forever", client)
        local function run()
            s.same = true
            local own = s.name.GetDisplayName("player")
            s.same = false
            return own, s.name.GetDisplayName("target", true),
                s.name.GetCharKey("inventory"), s.name.GetCharKey("profile")
        end
        for _ = 1, 100 do run() end
        for key in pairs(s.reads) do s.reads[key] = 0 end
        local started = os.clock()
        local own, other, inventory, profile
        for _ = 1, 5000 do own, other, inventory, profile = run() end
        print("PUBLIC", client, own, other, inventory, profile,
            s.reads.same, s.reads.nativeSurname, s.reads.cvar, s.reads.legacyCvar,
            s.reads.regional, s.reads.unitName, s.reads.formatted)
        print("HOST_CLOCK_MS", client, (os.clock() - started) * 1000)
    end
    return
end

for _, withService in ipairs({ true, false }) do
    local s = fixture(withService, true)
    local pn = s.name
    s.same = s.boolSecret
    check(pn.GetDisplayName("target") == "Other Surname",
        "unreadable alias identity never takes the self-only surname path")
    check(pn.IsUnitPlayer("target") == false, "unreadable alias identity is a plain false")
    check(pn.IsUnitPlayer("player") == true and pn.GetDisplayName("player") == "Alpha",
        "known player token still honors the own-surname setting")
    s.same = true
    check(pn.IsUnitPlayer("target") and pn.GetDisplayName("target") == "Other",
        "readable self alias still honors the own-surname setting")
    s.same = false
    check(not pn.IsUnitPlayer("target") and pn.GetDisplayName("target") == "Other Surname",
        "other unit retains its ordinary formatted name")
    s.sameError = true
    check(not pn.IsUnitPlayer("target") and pn.GetDisplayName("target") == "Other Surname",
        "failed optional identity API retains ordinary formatting")
    s.env.UnitIsUnit = nil
    check(pn.IsUnitPlayer("player") and not pn.IsUnitPlayer("target"), "missing identity API keeps known player token")
    check(not pn.IsUnitPlayer(nil) and not pn.IsUnitPlayer(""), "invalid tokens are not self")

    s.surname, s.cvar, s.legacyCvar = s.boolSecret, false, true
    check(pn.ShouldDisplaySurname() == false and s.reads.cvar > 0 and s.reads.legacyCvar == 0,
        "unreadable native surname setting falls through to public CVar false")
    s.cvar = s.boolSecret
    check(pn.ShouldDisplaySurname() == true and s.reads.legacyCvar > 0,
        "unreadable modern CVar falls through to public legacy CVar")
    s.legacyCvar = s.boolSecret
    check(pn.ShouldDisplaySurname() == true, "unreadable settings retain the established true default")
    s.surname = true
    check(pn.ShouldDisplaySurname() == true, "readable true setting remains true")
    s.surname = false
    check(pn.ShouldDisplaySurname() == false, "readable false setting remains false")
    s.unique = s.boolSecret
    check(pn.UsesRegionalUniqueNames() == false, "unreadable regional capability is not branched on")
    s.uniqueError = true
    check(pn.UsesRegionalUniqueNames() == false, "unavailable regional capability is false")
    s.uniqueError, s.unique = false, true
    s.rawUnit, s.secretAccessible = s.stringSecret, true
    check(pn.GetFullName("target") == nil and pn.GetDisplayName("target") == nil,
        "secret names are not exposed even when canaccessvalue reports true")
    s.rawUnit = nil
    check(pn.GetCharKey("inventory") == "Alpha Beta-RealmA"
        and pn.GetCharKey("acedb") == "Alpha Beta - Realm A"
        and pn.GetCharKey("profile") == "Char - Alpha Beta - Realm A"
        and pn.GetCharKey("professions") == "Realm A-Alpha Beta",
        "all regional identity key formats stay unchanged")
    check(pn.NamesEqual("Alpha Beta", "alpha-beta") and pn.NamesEqual("Alpha", "Alpha Beta")
        and not pn.NamesEqual("Alpha Beta", "Other Beta"), "regional comparison behavior stays unchanged")
    check(pn.SetDisplaySurname(false) and s.lastWrite[1] == "UnitSurnameOwn" and s.lastWrite[2] == "0",
        "surname setting writes preserve the same CVar and value")
end

for _, client in ipairs({ "retail", "forever", "era", "anniversary", "classic" }) do
    local public = fixture(true, client == "forever", client)
    public.same = false
    check(public.name.GetDisplayName("target") == (client == "forever" and "Other Surname" or "Other"),
        client .. ": public display contract preserved")
    check(public.name.GetCharKey("inventory") == (client == "forever" and "Alpha Beta-RealmA" or "Alpha-RealmA"),
        client .. ": public saved identity contract preserved")
end

local classic = fixture(true, false, "classic")
check(classic.name.GetDisplayName("player") == "Alpha"
    and classic.name.GetDisplayName("player", true) == "Alpha-RealmB",
    "nonregional clients preserve given-name and realm display")
check(classic.name.GetCharKey("profile") == "Char - Alpha - RealmB"
    and classic.name.GetCharKey("inventory") == "Alpha-RealmA",
    "nonregional saved keys preserve full-name realm and normalized inventory realm")
check(not classic.name.ShouldDisplaySurname()
    and not classic.name.NamesEqual("Alpha-RealmA", "Alpha-RealmB"),
    "nonregional surname and cross-realm comparison defaults stay unchanged")

-- Replay the actual decision used by target/focus click-target updates.
local s = fixture(true, true)
s.same, s.rawUnit = s.boolSecret, s.stringSecret
local shared = read("UnitFrames/FluxUnitFrames_Shared.lua")
local a = assert(shared:find("local function UnitDisplayName(unit, showRealm)", 1, true))
local b = assert(shared:find("local function SetWatchedFrameClickable(frame, enabled)", a, true))
local uf = {}
local api = { UnitExistsSafe = function() return true end,
    SafeAccessibleString = s.ns.Flux.Secrets.SafeAccessibleString }
s.env.ns, s.env.UF, s.env.API, s.env.UNKNOWNOBJECT = s.ns, uf, api, "Unknown"
assert(load(shared:sub(a, b - 1), "@real-watched-unit-name-decision", "t", s.env))()
for _, unit in ipairs({ "target", "focus" }) do
    check(uf.UnitTokenIsResolved(unit) and uf.ShouldShowWatchedUnitFrame({unit=unit}),
        unit .. ": existing unit remains shown when its name is restricted")
end
s.rawUnit = "Unknown"
for _, unit in ipairs({ "target", "focus" }) do
    check(not uf.UnitTokenIsResolved(unit) and not uf.ShouldShowWatchedUnitFrame({unit=unit}),
        unit .. ": accessible unknown-name unit remains unresolved")
end
print("Player name secrets: " .. checks .. " checks passed; native secret VM and visibility checks remain pending")
