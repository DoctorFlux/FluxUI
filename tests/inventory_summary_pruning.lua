-- Real Store/Summaries modules; saved data and native identity APIs isolated.
-- Optional argument: alternate Inventory/Summaries.lua for baseline replay.
local source = arg[1] or "Inventory/Summaries.lua"
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end

local function fixture()
    local env = setmetatable({}, {__index = _G}); env._G = env
    local ns = {Flux = {Inventory = {snapshots = {}}}}
    env.UnitName = function() return "Main" end
    env.GetNormalizedRealmName = function() return "Realm" end
    env.UnitFactionGroup = function() return "Alliance" end
    env.GetAutoCompleteRealms = function() return {"Realm"} end
    local visits = 0
    env.pairs = function(tbl)
        local db = env.FluxUIInventoryDB
        local main = db and db.Summaries.Characters.ByRealm.Realm
        local summary = main and main.Main
        local iter, state, key = pairs(tbl)
        if tbl ~= summary then return iter, state, key end
        return function(st, previous)
            local k, value = iter(st, previous)
            if k ~= nil then visits = visits + 1 end
            return k, value
        end, state, key
    end
    assert(loadfile("Inventory/Store.lua", "t", env))("_FluxUI", ns)
    assert(loadfile(source, "t", env))("_FluxUI", ns)
    local store, summaries = ns.Flux.Inventory.Store, ns.Flux.Inventory.Summaries
    local db = store.GetDB()
    local function character(name, realm, faction)
        local char = {details = {character = name, realmNormalized = realm,
            faction = faction or "Alliance", show = {inventory = true}},
            bags = {}, bank = {}, mail = {}, equipped = {}, void = {}, auctions = {}}
        db.Characters[name .. "-" .. realm] = char
        return char
    end
    local function item(id, count)
        return {itemID = id, link = "item:" .. id, count = count or 1}
    end
    local function generate(name, mode, id)
        store.MarkPending(name or "Main-Realm", mode or "bags")
        return summaries.GetTooltipInfoByItemID(id or 1)
    end
    local function rows(name, realm)
        local byRealm = db.Summaries.Characters.ByRealm[realm or "Realm"]
        return byRealm and byRealm[name or "Main"] or {}
    end
    return {env = env, store = store, summaries = summaries, db = db,
        character = character, item = item, generate = generate, rows = rows,
        visits = function() return visits end}
end

local function rowCounts(rows)
    local retained, zero = 0, 0
    for _, row in pairs(rows) do
        retained = retained + 1
        local empty = true
        for _, count in pairs(row) do
            if count ~= 0 then empty = false; break end
        end
        if empty then zero = zero + 1 end
    end
    return retained, zero
end

-- One changing carried slot and a tooltip read after each real pending flush.
-- Count the production summary traversals, not assertions or fixture scans.
local burst = fixture()
local main = burst.character("Main", "Realm")
burst.db.Summaries.Characters.ByRealm.Realm = {Main = {}}
for id = 1, 2000 do
    main.bags[0] = {[1] = burst.item(id, id % 7 + 1)}
    local info = burst.generate(nil, "bags", id)
    if id % 100 == 0 then
        check(info.characters[1] and info.characters[1].bags == id % 7 + 1, "current replacement count " .. id)
        check(rowCounts(burst.rows()) == 1, "replacement history does not retain empty rows " .. id)
    end
end
local retained, zero = rowCounts(burst.rows())
local walks = burst.visits()
check(retained == 1 and zero == 0, "summary retains only currently represented item")
check(walks <= 6000, "replacement summary traversal remains linear")
local current = burst.rows()["item:2000"]
main.bags[0][1].count = 9
burst.generate(nil, "bags", 2000)
check(burst.rows()["item:2000"] == current and current.bags == 9, "count-only refresh preserves live row identity")
local missing = burst.summaries.GetTooltipInfoByItemID(1)
check(type(missing.characters) == "table" and #missing.characters == 0
    and type(missing.guilds) == "table" and #missing.guilds == 0
    and type(missing.warband) == "table" and missing.warband[1] == 0,
    "removed bag-only key has the same zero-result shape as a fresh absent key")
main.bags = {}
burst.generate(nil, "bags", 2000)
check(next(burst.rows()) == nil, "last carried item leaves no zero summary")
check(#burst.summaries.GetTooltipInfoByLink("item:2000").characters == 0, "link query removes stale owner after empty bags")

-- Preserve facts from every other character location through partial bag work.
local f = fixture()
main = f.character("Main", "Realm")
main.bags = {[0] = {[1] = f.item(10, 2), [2] = f.item(20, 1)}}
main.bank = {[-1] = {[1] = f.item(10, 3), [2] = f.item(21, 2)}}
main.mail = {[1] = f.item(10, 4), [2] = f.item(22, 3)}
main.equipped = {[1] = f.item(10, 5), [2] = f.item(23, 4)}
main.void = {[1] = {[1] = f.item(10, 6), [2] = f.item(24, 5)}}
main.auctions = {[1] = f.item(10, 7), [2] = f.item(25, 6)}
f.generate(nil, "all", 10)
local shared = f.rows()["item:10"]
for _, field in ipairs({"bags", "bank", "mail", "equipped", "void", "auctions"}) do
    check(shared[field] == ({bags=2,bank=3,mail=4,equipped=5,void=6,auctions=7})[field], "full summary populates " .. field)
end
main.bags = {[0] = {[1] = f.item(30, 8)}}
f.generate(nil, "bags", 10)
check(f.rows()["item:10"] == shared and shared.bags == 0, "partial refresh retains nonbag row identity")
for _, field in ipairs({"bank", "mail", "equipped", "void", "auctions"}) do
    check(shared[field] == ({bank=3,mail=4,equipped=5,void=6,auctions=7})[field], "partial refresh keeps " .. field)
end
for id = 21, 25 do check(f.rows()["item:"..id] ~= nil, "location-only key retained " .. id) end
check(f.rows()["item:20"] == nil and f.rows()["item:30"].bags == 8, "only vanished bag-only key is pruned")
f.rows()["item:31"] = {bags = 0, futureCount = 2}
main.bags = {}
f.generate(nil, "bags", 10)
check(f.rows()["item:31"].futureCount == 2, "unknown nonzero location fields are conservatively retained")
check(f.rows()["item:30"] == nil and f.rows()["item:10"].bank == 3, "empty bags preserve real nonbag facts")

-- Full rebuild still removes obsolete nonbag facts using current source data.
main.bank, main.mail, main.equipped, main.void, main.auctions = {}, {}, {}, {}, {}
main.bags = {[0] = {[1] = f.item(40, 2)}}
f.generate(nil, "all", 40)
check(rowCounts(f.rows()) == 1 and f.rows()["item:40"].bags == 2, "full refresh replaces all old location facts")

-- Another character, guild and warband records must not be pruned with Main.
local alt = f.character("Alt", "Realm")
alt.mail = {[1] = f.item(40, 11)}
f.generate("Alt-Realm", "all", 40)
local guild = {details = {guild = "Guild", realm = "Realm", faction = "Alliance", show = {inventory = true}},
    bank = {[1] = {isViewable = true, slots = {[1] = f.item(40, 12)}}}}
f.db.Guilds["Guild-Realm"] = guild
f.db.Warband[1].bank = {[1] = {slots = {[1] = f.item(40, 13)}}}
f.store.MarkGuildPending("Guild-Realm"); f.store.MarkWarbandPending()
local info = f.summaries.GetTooltipInfoByItemID(40)
check(#info.characters == 2 and #info.guilds == 1 and info.guilds[1].bank == 12
    and info.warband[1] == 13, "shared query includes character/guild/warband facts")
main.bags = {}; f.generate(nil, "bags", 40)
info = f.summaries.GetTooltipInfoByItemID(40)
check(#info.characters == 1 and info.characters[1].character == "Alt"
    and info.characters[1].mail == 11, "main empty refresh preserves offline character ownership")
check(info.guilds[1].bank == 12 and info.warband[1] == 13, "character pruning leaves guild and warband summaries intact")
check(f.rows("Alt")["item:40"].mail == 11, "offline cache unchanged")
alt.mail = {}; f.generate("Alt-Realm", "all", 40)
info = f.summaries.GetTooltipInfoByItemID(40)
check(#info.characters == 0 and #info.guilds == 1 and info.warband[1] == 13, "offline full refresh also preserves zero-result shape")

-- Existing filtering and optional external-provider handoff remain unchanged.
main.bags = {[0] = {[1] = f.item(50, 2)}}
alt.bags = {[0] = {[1] = f.item(50, 3)}}
alt.details.faction = "Horde"
local remote = f.character("Remote", "Other")
remote.bags = {[0] = {[1] = f.item(50, 4)}}
f.generate(nil, "all", 50); f.generate("Alt-Realm", "all", 50); f.generate("Remote-Other", "all", 50)
check(#f.summaries.GetTooltipInfoByItemID(50).characters == 3, "unfiltered ownership remains complete")
check(#f.summaries.GetTooltipInfoByItemID(50, true, false).characters == 2, "connected realm filter retained")
check(#f.summaries.GetTooltipInfoByItemID(50, false, true).characters == 2, "faction filter retained")
alt.details.show.inventory = false
check(#f.summaries.GetTooltipInfoByItemID(50).characters == 2, "hidden character setting retained")
local sentinel = {characters = {{character = "External", bags = 77}}, guilds = {}, warband = {0}}
local externalCalls = 0
f.env.Syndicator = {API = {GetInventoryInfoByItemID = function(id, connected, faction)
    externalCalls = externalCalls + 1
    check(id == 50 and connected and faction, "external query flags retained")
    return sentinel
end}}
main.bags = {[0] = {[1] = f.item(60, 6)}}
f.store.MarkPending("Main-Realm", "bags")
f.store.SetUsesSyndicator(true)
check(f.summaries.GetTooltipInfoByItemID(50, true, true) == sentinel and externalCalls == 1,
    "external provider owns query without rebuilding builtin summaries")
check(f.rows()["item:50"].bags == 2, "delegated query leaves builtin cache intact")
f.store.SetUsesSyndicator(false)
info = f.summaries.GetTooltipInfoByItemID(60)
check(f.rows()["item:50"] == nil and info.characters[1].bags == 6, "builtin handoff processes pending facts and prunes departed bags")
local empty = f.summaries.GetTooltipInfo(nil)
check(#empty.characters == 0 and #empty.guilds == 0 and empty.warband[1] == 0, "nil key keeps empty API result shape")

print(string.format("inventory summary pruning: %d checks, %d failures; replacement rows=%d zero=%d row walks=%d",
    checks, failures, retained, zero, walks))
if failures > 0 then os.exit(1) end
