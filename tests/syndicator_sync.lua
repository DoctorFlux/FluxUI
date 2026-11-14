-- Real synchronization module; synthetic plain SavedVariables model separate reloads.
-- Desktop timings do not establish native FPS, serialization or secure-client safety.
local source = arg[1] or "Inventory/Syndicator/Sync.lua"
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}; seen[value] = result
    for key, child in pairs(value) do result[copy(key, seen)] = copy(child, seen) end
    return result
end
local function count(row) return row and (row.count or row.itemCount) end
local function link(row) return row and (row.link or row.itemLink) end
local function setCount(row, value)
    if row.count ~= nil then row.count = value else row.itemCount = value end
end
local function item(id, n)
    return {itemID = id, itemCount = n or 1, itemLink = "item:" .. id,
        iconTexture = 9000 + id, quality = 3, isBound = false, futureMetadata = "keep"}
end
local function slots(id, n) return {item(id, n), {}, {}, {}} end
local function constants(modern, warband)
    return {AllBagIndexes = {0, 1, -2, 2}, AllBankIndexes = modern and {6, 7, 8} or {-1, 5},
        AllWarbandIndexes = warband and {12, 13} or {}, CharacterBankTabsActive = modern,
        EquippedInventorySlotOffset = 1, WarbandBankActive = warband}
end
local function character(name, cons)
    local result = {bags = {slots(101, 2), slots(102, 3), {{}, {}, {}, {}}, {{}, {}, {}, {}}},
        bank = {}, bankTabs = {}, mail = {item(201, 5)}, auctions = {item(301, 6)},
        equipped = {item(401)}, void = {{item(501)}}, currencies = {[200] = 17}, money = 345,
        containerInfo = {bags = {item(601)}}, currencyByHeader = {Tokens = {200}},
        details = {character = name, realm = "Realm", realmNormalized = "Realm", class = 8,
            className = "MAGE", faction = "Alliance", show = {inventory = true, gold = true}},
        futureEntityMetadata = {preserve = true}}
    result.mail[1].expirationTime = 90000
    result.auctions[1].auctionID, result.auctions[1].expirationTime = 700, 100000
    if cons.CharacterBankTabsActive then
        result.bankTabs = {{slots = slots(701, 7), name = "First", iconTexture = 7001, depositFlags = 3},
            {slots = slots(702, 8), name = "Second", iconTexture = 7002, depositFlags = 4}}
    else result.bank = {slots(701, 7), slots(702, 8)} end
    return result
end
local function database(cons)
    return {Version = 2, Characters = {['Current-Realm'] = character("Current", cons),
        ['Alt-Realm'] = character("Alt", cons), ['Deleted-Realm'] = character("Deleted", cons)},
        Guilds = {['Guild-Realm'] = {bank = {{slots = slots(801, 9), name = "Guild tab", iconTexture = 8001}},
            money = 100, details = {guild = "Guild", realm = "Realm", visited = true,
                show = {inventory = true, gold = false}}}},
        Warband = {{bank = {{slots = slots(901, 10), name = "Account tab", iconTexture = 9001}},
            money = 1000, details = {gold = true, inventory = true}}}, futureRoot = {keep = true}}
end
local function localDB()
    return {Version = 1, Characters = {}, Guilds = {}, Warband = {{bank = {}, money = 0}},
        Pending = {Characters = {}, Guilds = {}, Warband = false},
        Summaries = {Characters = {ByRealm = {}}, Guilds = {ByRealm = {}},
            Warband = {Summary = {}, Pending = true}}}
end
local function boot(db, remote, cons, current, moduleText)
    local h = {calls = {frames = 0, timers = 0, events = 0, callbacks = 0, scans = 0, pairs = 0}, emissions = {}}
    local env = setmetatable({}, {__index = _G}); env._G = env
    env.FluxUIInventoryDB, env.SYNDICATOR_DATA = db, remote
    env.SYNDICATOR_SUMMARIES = {Version = 5, Characters = {ByRealm = {}, Pending = {}},
        Guilds = {ByRealm = {}, Pending = {}}, Warband = {Summary = {}, Pending = {}}}
    env.pairs = function(t) h.calls.pairs = h.calls.pairs + 1; return pairs(t) end
    env.CreateFrame = function() h.calls.frames = h.calls.frames + 1; error("sync creates a frame") end
    env.C_Timer = {After = function() h.calls.timers = h.calls.timers + 1; error("sync schedules a timer") end}
    env.UnitName = function() return "Current" end
    env.GetNormalizedRealmName = function() return "Realm" end
    env.GetTime = function() return 100 end
    env.time = function() return 100000 end
    local inv = {Syndicator = {}, source = "builtin", snapshots = {}}
    inv.Store = {GetCurrentCharacterName = function() return current or "Current-Realm" end,
        GetCharacterFullName = function() return current or "Current-Realm", "Current", "Realm" end,
        GetDB = function() return db end}
    inv.Containers = {GetCarriedBagIDs = function() return cons.AllBagIndexes end,
        GetCharacterBankIDs = function() return cons.AllBankIndexes end,
        GetWarbandBankIDs = function() return cons.AllWarbandIndexes end}
    local flux = {Inventory = inv, Cap = {}, Timer = env.C_Timer,
        Events = {Register = function() h.calls.events = h.calls.events + 1; error("sync registers an event") end},
        Scheduler = {Request = function() error("sync requests recurring inventory work") end}}
    env.Syndicator = {Constants = cons, API = {GetCurrentCharacter = inv.Store.GetCurrentCharacterName},
        CallbackRegistry = {TriggerEvent = function(_, event, name, updates)
            local summary = env.SYNDICATOR_SUMMARIES
            local section = summary and summary[event:match("^Warband") and "Warband" or "Characters"]
            h.emissions[#h.emissions + 1] = {event = event, name = name, updates = updates,
                pendingAtDelivery = section and section.Pending and section.Pending[name]}
        end, RegisterCallback = function()
            h.calls.callbacks = h.calls.callbacks + 1; error("sync registers a cache callback")
        end}}
    if moduleText then assert(load(moduleText, "@syndicator-sync-control", "t", env))("_FluxUI", {Flux = flux})
    else assert(loadfile(source, "t", env))("_FluxUI", {Flux = flux}) end
    h.sync, h.env, h.inv = assert(inv.Syndicator.Sync), env, inv
    h.flux = flux
    return h
end

local clients = {{"era", false, false}, {"anniversary", false, false}, {"mists", false, false},
    {"forever", true, false}, {"retail", true, true}}
for _, client in ipairs(clients) do
    local label, cons = client[1], constants(client[2], client[3])
    local db, remote = localDB(), database(cons)
    local h = boot(db, remote, cons)
    h.sync.Bind(db, remote, cons, "Current-Realm")
    check(db.SyndicatorSync and db.SyndicatorSync.data == remote, label .. " live mirror aliases provider data")
    check(db.SyndicatorSync.active == true, label .. " persisted handoff marker")
    check(db.SyndicatorSync.constants ~= cons, label .. " mapping is detached from exported constants")
    check(#h.emissions == 0, label .. " initial alias import emits no cache notifications")

    -- No synchronization calls follow these provider mutations. The alias must
    -- preserve remote alts, unfiltered mail, metadata, root replacement and deletion.
    local pairReads = h.calls.pairs
    for i = 1, 10000 do remote.Characters['Alt-Realm'].mail[1].itemCount = i end
    remote.Characters['Alt-Realm'].bags[1][1].itemCount = 11
    remote.Characters['Alt-Realm'].void[1][1].itemCount = 12
    remote.Guilds['Guild-Realm'].bank[1].slots[1].itemCount = 13
    remote.Characters['Temporary-Realm'] = character("Temporary", cons)
    remote.Characters['Temporary-Realm'] = nil
    remote.futureRoot.keep = "later"
    check(db.SyndicatorSync.data.Characters['Alt-Realm'].mail[1].itemCount == 10000,
        label .. " alt mail mutations retained without a callback")
    check(db.SyndicatorSync.data.Guilds['Guild-Realm'].bank[1].slots[1].itemCount == 13,
        label .. " guild snapshot tracks provider without changing its callbacks")
    check(db.SyndicatorSync.data.futureRoot.keep == "later" and h.calls.pairs == pairReads,
        label .. " ten thousand updates add no mirror traversals")
    check(#h.emissions == 0, label .. " continuous provider updates emit no synchronization notifications")

    -- Serialize the addon roots independently, as on separate sessions.
    local staleRemote = copy(remote)
    db = copy(db)
    h = boot(db, nil, cons)
    h.sync.Restore(db)
    local cur, alt = db.Characters['Current-Realm'], db.Characters['Alt-Realm']
    local firstBank, secondBank = cons.AllBankIndexes[1], cons.AllBankIndexes[2]
    check(cur and cur.bags[0] and count(cur.bags[0][1]) == 2, label .. " native bag keys hydrated")
    check(cur.bank[firstBank] and count(cur.bank[firstBank][1]) == 7, label .. " native bank keys hydrated")
    check(cur.equipped[0] and count(cur.equipped[0]) == 1, label .. " equipment offset hydrated")
    check(count(alt.mail[1]) == 10000 and count(alt.void[1][1]) == 12,
        label .. " disabled provider retains latest alt mail and void")
    check(alt.mail[1].expirationTime == 90000 and alt.auctions[1].auctionID == 700
        and alt.auctions[1].expirationTime == 100000, label .. " publication metadata survives provider removal")
    check(cur.details.className == "MAGE" and cur.details.show.gold == true,
        label .. " details and display policy preserved")
    check(cur.bags ~= db.SyndicatorSync.data.Characters['Current-Realm'].bags
        and cur.bags[0][1] ~= db.SyndicatorSync.data.Characters['Current-Realm'].bags[1][1],
        label .. " builtin records cannot mutate frozen ancestor")
    check(not db.SyndicatorSync.active, label .. " restore consumes transition marker")
    check(db.Pending.Characters['Current-Realm'] ~= nil, label .. " local summaries invalidated")
    if client[3] then
        check(db.Warband[1].bank[12] and count(db.Warband[1].bank[12][1]) == 10,
            label .. " account-bank mapping hydrated")
    end

    setCount(cur.bags[0][1], 20)
    setCount(cur.bags[1][1], 27)
    setCount(cur.bank[firstBank][1], 21)
    setCount(cur.equipped[0], 2)
    cur.mail = {}
    cur.auctions[1] = {itemID = 301, count = 22, link = "item:301"}
    cur.money, cur.currencies[200] = 888, 88
    setCount(alt.bags[0][1], 23)
    setCount(alt.bank[firstBank][1], 24)
    setCount(alt.bank[secondBank][1], 25)
    alt.mail = {{itemID = 2201, count = 4}}
    alt.auctions[1].auctionID, alt.auctions[1].expirationTime = 900, 100500
    alt.money, alt.currencies[200] = 777, 77
    db.Guilds['Guild-Realm'].money = 0
    if client[3] then setCount(db.Warband[1].bank[12][1], 26) end
    h.sync.NoteCapacity(0, 6)
    h.sync.NoteCapacity(1, 1)
    h.sync.NoteCapacity(-2, 0)
    h.sync.NoteCapacity(2, 6)
    if client[2] then cur.bank[8] = {} end
    local frozen = db.SyndicatorSync.data.Characters['Current-Realm']
    check(frozen.bags[1][1].itemCount == 2 and frozen.mail[1].itemCount == 5,
        label .. " builtin changes leave original remote comparison intact")
    h.sync.Restore(db)
    check(count(db.Characters['Current-Realm'].bags[0][1]) == 20, label .. " repeated Restore is inert")
    db = copy(db); h = boot(db, nil, cons); h.sync.Restore(db)
    check(count(db.Characters['Current-Realm'].bags[0][1]) == 20,
        label .. " absent-provider reload does not replay stale mirror")

    -- Remote independently changes one bank tab and tokens; conflict recency is
    -- unknowable without provider timestamps. Preserve those remote changes,
    -- but recover local edits to an unchanged tab and other independent fields.
    local remoteBank = client[2] and staleRemote.Characters['Alt-Realm'].bankTabs[2].slots
        or staleRemote.Characters['Alt-Realm'].bank[2]
    remoteBank[1].itemCount = 35
    staleRemote.Characters['Alt-Realm'].currencies[200] = 37
    staleRemote.Characters['Current-Realm'].money = 999
    staleRemote.Characters['Current-Realm'].currencies[200] = 99
    staleRemote.Characters['Deleted-Realm'] = nil
    staleRemote.Characters['Fresh-Realm'] = character("Fresh", cons)
    db.Characters['Local-Realm'] = {bags = {[0] = {[1] = {itemID = 1101, count = 3, link = "item:1101"}}},
        bank = {[firstBank] = {{itemID = 1201, count = 4, link = "item:1201"}}},
        mail = {{itemID = 1301, count = 5, link = "item:1301"}},
        auctions = {{itemID = 1401, count = 6, link = "item:1401"}},
        equipped = {[0] = {itemID = 1501, count = 1, link = "item:1501"}},
        void = {{{itemID = 1601, count = 1, link = "item:1601"}}}, currencies = {[200] = 7}, money = 10,
        details = {character = "Local", realm = "Realm", realmNormalized = "Realm",
            class = "Mage", className = "MAGE", show = {inventory = true, gold = true}}}
    db.Guilds['NewGuild-Realm'] = {money = 3,
        bank = {{slots = {{itemID = 2301, count = 5, link = "item:2301"}},
            name = "New guild tab", iconTexture = 2300, isViewable = true}},
        details = {guild = "NewGuild", realm = "Realm", visited = true, show = {inventory = true, gold = false}}}
    local rootRef, curRef, detailRef = staleRemote, staleRemote.Characters['Current-Realm'],
        staleRemote.Characters['Current-Realm'].details
    h = boot(db, staleRemote, cons)
    local summaryRef = h.env.SYNDICATOR_SUMMARIES
    h.sync.Bind(db, staleRemote, cons, "Current-Realm")
    local after, afterAlt = staleRemote.Characters['Current-Realm'], staleRemote.Characters['Alt-Realm']
    local bankAfter = client[2] and after.bankTabs[1].slots or after.bank[1]
    local altFirst = client[2] and afterAlt.bankTabs[1].slots or afterAlt.bank[1]
    local altSecond = client[2] and afterAlt.bankTabs[2].slots or afterAlt.bank[2]
    check(staleRemote == rootRef and after == curRef and after.details == detailRef,
        label .. " external root/entity/details references preserved")
    check(after.bags[1][1].itemCount == 20 and after.equipped[1].itemCount == 2,
        label .. " newer builtin bags/equipment restore stale provider")
    check(bankAfter[1].itemCount == 21 and afterAlt.bags[1][1].itemCount == 23,
        label .. " newer bank and offline alt bags restored")
    check(altFirst[1].itemCount == 24 and altSecond[1].itemCount == 35,
        label .. " independent bank-tab updates merge without lost fresh remote data")
    check(next(after.mail) == nil and after.auctions[1].itemCount == 22,
        label .. " complete empty mail and auction updates restore stale provider")
    check(after.money == 999 and after.currencies[200] == 99,
        label .. " provider current live money/tokens survive startup merge")
    check(afterAlt.money == 777 and afterAlt.currencies[200] == 37,
        label .. " alt unchanged money restores while token conflict preserves remote")
    local recoveredMailLink = afterAlt.mail[1].itemLink
    check(afterAlt.mail[1].itemCount == 4 and type(recoveredMailLink) == "string"
        and recoveredMailLink:match("|H([^:]+):") == "item"
        and recoveredMailLink:match("|Hitem:(%d+)") == "2201",
        label .. " linkless native mail exports a hyperlink parsed by provider summaries")
    check(afterAlt.auctions[1].itemCount == 6 and afterAlt.auctions[1].auctionID == 900
        and afterAlt.auctions[1].expirationTime == 100500,
        label .. " auction ID and expiry edits publish with unchanged item/count")
    check(after.bags[1][1].iconTexture == 9101 and after.bags[1][1].futureMetadata == "keep",
        label .. " compatible item metadata survives quantity edits")
    check(type(after.bags[1][2]) == "table" and next(after.bags[1][2]) == nil,
        label .. " exported sparse bags retain dense empty slots")
    check(#after.bags[1] == 6, label .. " captured capacity includes trailing empty slots")
    check(#after.bags[2] == 1 and after.bags[2][1].itemCount == 27,
        label .. " smaller replacement bag shrinks stale dense capacity")
    check(#after.bags[3] == 0 and #after.bags[4] == 6,
        label .. " identical empty contents still publish removed and resized capacity")
    check(after.containerInfo.bags[1].itemID == 601 and after.futureEntityMetadata.preserve,
        label .. " provider-specific and unknown entity metadata preserved")
    if client[2] then
        check(after.bankTabs[1].name == "First" and after.bankTabs[1].iconTexture == 7001
            and after.bankTabs[1].depositFlags == 3, label .. " tab metadata retained")
        check(after.bankTabs[3] == nil, label .. " absent empty bank map does not purchase a phantom tab")
    end
    check(staleRemote.Characters['Deleted-Realm'] == nil,
        label .. " removed external character is not resurrected")
    check(staleRemote.Characters['Fresh-Realm'] ~= nil and staleRemote.Characters['Local-Realm'] ~= nil,
        label .. " independent missing entities retained in both directions")
    check(staleRemote.Characters['Local-Realm'].bags[1][1].itemCount == 3
        and link(staleRemote.Characters['Local-Realm'].bags[1][1]) == "item:1101",
        label .. " new local-only alt receives provider item schema")
    local seeded = staleRemote.Characters['Local-Realm']
    local seedBank = client[2] and seeded.bankTabs[1].slots or seeded.bank[1]
    check(seedBank[1].itemID == 1201 and seedBank[1].itemCount == 4
        and seeded.equipped[1].itemID == 1501 and seeded.equipped[1].itemCount == 1,
        label .. " complete local-only alt seeds bank/equipment coordinates")
    check(seeded.mail[1].itemCount == 5 and seeded.auctions[1].itemCount == 6
        and seeded.void[1][1].itemID == 1601 and seeded.currencies[200] == 7 and seeded.money == 10,
        label .. " complete local-only alt seeds all remaining facts")
    check(type(seeded.containerInfo) == "table" and type(seeded.currencyByHeader) == "table"
        and seeded.details.class == nil and seeded.details.className == "MAGE"
        and seeded.details.realmNormalized == "Realm", label .. " new alt has safe provider metadata shape")
    check(staleRemote.Guilds['Guild-Realm'].money == 0, label .. " zero guild money is meaningful")
    local seededGuild = staleRemote.Guilds['NewGuild-Realm']
    check(seededGuild.bank[1].slots[1].itemCount == 5
        and seededGuild.bank[1].name == "New guild tab" and seededGuild.bank[1].isViewable == true
        and seededGuild.bank[1].iconTexture == 2300,
        label .. " new local guild retains tab visibility/name/icon")
    check(h.env.SYNDICATOR_SUMMARIES == summaryRef
        and summaryRef.Characters.Pending['Current-Realm'] == 1,
        label .. " external full-character summary invalidation uses numeric All")
    check(summaryRef.Guilds.Pending['Guild-Realm'] == true, label .. " affected guild summary invalidated")
    if client[3] then
        check(staleRemote.Warband[1].bank[1].slots[1].itemCount == 26
            and staleRemote.Warband[1].bank[1].name == "Account tab",
            label .. " account inventory restores with tab metadata")
        check(summaryRef.Warband.Pending[1] == true, label .. " account summary invalidated")
    end
    check(db.SyndicatorSync.data == staleRemote and db.SyndicatorSync.active,
        label .. " active alias reattached after independently serialized roots")
    local emitted, eventShape, forbidden, pendingAtDelivery = {}, nil, false, true
    for _, row in ipairs(h.emissions) do
        local key = row.event .. ":" .. row.name
        emitted[key] = (emitted[key] or 0) + 1
        if row.event == "BagCacheUpdate" and row.name == "Current-Realm" then eventShape = row.updates end
        if row.event == "GuildCacheUpdate" or row.event == "VoidCacheUpdate"
            or (row.event == "BagCacheUpdate" and row.name ~= "Current-Realm") then forbidden = true end
        pendingAtDelivery = pendingAtDelivery and (row.pendingAtDelivery == 1 or row.pendingAtDelivery == true)
    end
    check(emitted['BagCacheUpdate:Current-Realm'] == 1 and emitted['EquippedCacheUpdate:Current-Realm'] == 1
        and emitted['CurrencyCacheUpdate:Current-Realm'] == 1 and emitted['MailCacheUpdate:Current-Realm'] == 1,
        label .. " merged current character broadcasts one bounded refresh per consumer cache")
    check(eventShape and type(eventShape.bags) == "table" and type(eventShape.bank) == "table"
        and eventShape.containerBags.bags == true and eventShape.containerBags.bank == true,
        label .. " current bag notification retains native full-container payload shape")
    check(emitted['MailCacheUpdate:Alt-Realm'] == 1 and emitted['MailCacheUpdate:Local-Realm'] == 1
        and emitted['MailCacheUpdate:Fresh-Realm'] == nil and not forbidden,
        label .. " only changed alts refresh account search without live bag/guild/void events")
    check(pendingAtDelivery, label .. " summary invalidation precedes cache notification delivery")
    if client[3] then
        local warbandShape
        for _, row in ipairs(h.emissions) do if row.event == "WarbandBankCacheUpdate" then warbandShape = row.updates end end
        check(emitted['WarbandBankCacheUpdate:1'] == 1 and emitted['WarbandCurrencyCacheUpdate:1'] == 1
            and warbandShape.tabInfo == true and warbandShape.bags[12] and warbandShape.bags[13],
            label .. " changed account bank broadcasts compatible bounded refresh")
    else
        check(emitted['WarbandBankCacheUpdate:1'] == nil and emitted['WarbandCurrencyCacheUpdate:1'] == nil,
            label .. " unchanged unsupported account bank broadcasts no refresh")
    end
    local emissions, traversals = #h.emissions, h.calls.pairs
    h.sync.Bind(db, staleRemote, cons, "Current-Realm")
    check(#h.emissions == emissions and h.calls.pairs == traversals,
        label .. " duplicate attachment emits no notifications or additional traversal")
    check(h.calls.frames + h.calls.timers + h.calls.events + h.calls.callbacks == 0,
        label .. " synchronization adds no driver, polling or callback subscriptions")

    -- The next disabled-provider session must see the reconciled and subsequently
    -- updated provider data, not a stale conversion left from the earlier session.
    staleRemote.Characters['Current-Realm'].bags[1][1].itemCount = 40
    check(#h.emissions == emissions, label .. " later native updates add no synchronization notification")
    db = copy(db); h = boot(db, nil, cons); h.sync.Restore(db)
    check(count(db.Characters['Current-Realm'].bags[0][1]) == 40
        and not db.Characters['Deleted-Realm'], label .. " second transition keeps latest provider data/deletions")
end

-- Guild tab metadata has its own freshness decisions: updating a title or
-- permission must not require an item move, and item moves must not roll back
-- a tab title independently changed by the external provider.
do
    local cons = constants(false, false)
    local function guildTransition(edit)
        local db, remote = localDB(), database(cons)
        remote.Guilds['Guild-Realm'].bank[1].isViewable = true
        local h = boot(db, remote, cons); h.sync.Bind(db, remote, cons, "Current-Realm")
        db, remote = copy(db), copy(remote)
        h = boot(db, nil, cons); h.sync.Restore(db)
        edit(db.Guilds['Guild-Realm'].bank[1], remote.Guilds['Guild-Realm'].bank[1])
        h = boot(db, remote, cons); h.sync.Bind(db, remote, cons, "Current-Realm")
        return remote.Guilds['Guild-Realm'].bank[1], h
    end
    local tab, h = guildTransition(function(localTab)
        localTab.name, localTab.iconTexture, localTab.isViewable = "Offline rename", 8010, false
    end)
    check(tab.name == "Offline rename" and tab.iconTexture == 8010 and tab.isViewable == false
        and tab.slots[1].itemCount == 9 and h.env.SYNDICATOR_SUMMARIES.Guilds.Pending['Guild-Realm'] == true
        and #h.emissions == 0,
        "guild metadata-only changes restore stale provider without guild callbacks or item changes")
    tab, h = guildTransition(function(localTab, remoteTab)
        setCount(localTab.slots[1], 15)
        localTab.name, remoteTab.name = "Offline rename", "Independent remote rename"
    end)
    check(tab.slots[1].itemCount == 15 and tab.name == "Independent remote rename"
        and h.env.SYNDICATOR_SUMMARIES.Guilds.Pending['Guild-Realm'] == true and #h.emissions == 0,
        "local guild quantity change preserves independently newer external tab name")
end

-- Native bag IDs and void page numbers overlap numerically, but their
-- capacities have different owners and must never affect each other.
do
    local cons = constants(false, false)
    local db, remote = localDB(), database(cons)
    local h = boot(db, remote, cons); h.sync.Bind(db, remote, cons, "Current-Realm")
    db, remote = copy(db), copy(remote)
    h = boot(db, nil, cons); h.sync.Restore(db); h.sync.NoteCapacity(1, 16)
    local voidPage = remote.Characters['Current-Realm'].void[1]
    h = boot(db, remote, cons); h.sync.Bind(db, remote, cons, "Current-Realm")
    check(#remote.Characters['Current-Realm'].bags[2] == 16
        and remote.Characters['Current-Realm'].void[1] == voidPage
        and #voidPage == 1 and voidPage[1].itemID == 501 and voidPage[2] == nil,
        "bag capacity never resizes the same-numbered unchanged void page")
end

-- Exercise the real Store and Adapter integration, including a provider that
-- arrives late and emits Ready while IsReady still returns false.
do
    local cons = constants(true, true)
    local db, remote = localDB(), database(cons)
    local h = boot(db, remote, cons)
    h.sync.Bind(db, remote, cons, "Current-Realm")
    db, remote = copy(db), copy(remote)
    h = boot(db, remote, cons)
    assert(loadfile("Inventory/Store.lua", "t", h.env))("_FluxUI", {Flux = h.flux})
    local store = h.inv.Store
    store.EnsureCurrentCharacter()
    check(count(store.GetCharacter('Current-Realm').bags[0][1]) == 2,
        "real Store restores prior provider before binding native tables")
    store.GetCharacter('Current-Realm').bags[0][1].count = 52
    local callbacks, requests, rebuildCount = {}, {}, nil
    h.inv.Containers.NewItemSetLog = function() return {} end
    h.inv.HasWarband = function() return true end
    h.flux.Scheduler.Request = function(_, token) requests[token] = true end
    local provider = h.env.Syndicator
    provider.API.IsReady = function() return false end
    provider.API.GetCharacter = function(name) return remote.Characters[name] end
    provider.CallbackRegistry.RegisterCallback = function(_, key, fn) callbacks[key] = fn end
    assert(loadfile("Inventory/Syndicator/Adapter.lua", "t", h.env))("_FluxUI", {Flux = h.flux})
    h.inv.Syndicator.RebuildAll = function()
        rebuildCount = remote.Characters['Current-Realm'].bags[1][1].itemCount
    end
    h.env.Syndicator = nil
    check(h.inv.Syndicator.Start() == false and h.inv.source == "builtin",
        "absent provider remains retryable without losing builtin ownership")
    h.env.Syndicator = provider
    h.inv.Syndicator.Start()
    check(callbacks.Ready and not store.UsesSyndicator(), "late provider waits on native Ready callback")
    callbacks.Ready()
    check(rebuildCount == 52 and h.inv.source == "syndicator" and store.UsesSyndicator(),
        "real Ready reconciliation precedes external snapshot handoff")
    check(store.GetCharacter('Current-Realm') == remote.Characters['Current-Realm']
        and store.GetDB() == nil and store.GetSyncDB() == db,
        "delegated Store retains public proxy and private synchronization root")
    check(db.SyndicatorSync.data == remote and requests.bags and requests.mail and requests.warband,
        "real adapter attaches live mirror and keeps existing region publications")
end

-- First encounter cannot date two existing caches. Keep external data, and
-- never attach or write an unsupported external schema.
do
    local cons = constants(true, true)
    local db, remote = localDB(), database(cons)
    db.Characters['Current-Realm'] = {bags = {[0] = {{itemID = 101, count = 999, link = "item:101"}}},
        money = 999, currencies = {[200] = 999}, details = {character = "Current", realmNormalized = "Realm"}}
    local h = boot(db, remote, cons); h.sync.Bind(db, remote, cons, "Current-Realm")
    check(remote.Characters['Current-Realm'].bags[1][1].itemCount == 2,
        "first encounter preserves external cache when relative age is unknown")
    db, remote = localDB(), database(cons); remote.Version = 99
    h = boot(db, remote, cons); h.sync.Bind(db, remote, cons, "Current-Realm")
    check(db.SyndicatorSync == nil and remote.Version == 99
        and remote.Characters['Current-Realm'].bags[1][1].itemCount == 2,
        "unsupported provider schema remains untouched")
    db = localDB(); db.SyndicatorSync = {Version = 99, active = true, data = database(cons), constants = cons}
    h = boot(db, nil, cons); h.sync.Restore(db)
    check(next(db.Characters) == nil and db.SyndicatorSync.active,
        "unsupported mirror metadata never imports or consumes data")
    local unsupportedState = db.SyndicatorSync
    remote = database(cons)
    local ok = h.sync.Bind(db, remote, cons, "Current-Realm")
    check(ok == false and db.SyndicatorSync == unsupportedState and #h.emissions == 0,
        "unsupported owned metadata prevents destructive attachment and notifications")
end

-- Negative controls prove that this regression rejects the old handoff-only
-- behavior, a detached snapshot and an unsafe overwrite of fresh remote data.
do
    local file = assert(io.open(source, "rb")); local text = file:read("*a"); file:close()
    local function observesLiveMirror(control)
        local cons = constants(false, false)
        local db, remote = localDB(), database(cons)
        local h = boot(db, remote, cons)
        control(h, db, remote)
        h.sync.Bind(db, remote, cons, "Current-Realm")
        remote.Characters['Alt-Realm'].mail[1].itemCount = 100
        return db.SyndicatorSync and db.SyndicatorSync.data
            and db.SyndicatorSync.data.Characters['Alt-Realm'].mail[1].itemCount == 100
    end
    check(not observesLiveMirror(function(h) h.sync.Bind = function() end end),
        "historical handoff-only/no-sync control rejected by persisted live updates")
    check(not observesLiveMirror(function(h, db, remote)
        local bind = h.sync.Bind
        h.sync.Bind = function(...)
            bind(...); db.SyndicatorSync.data = copy(remote)
        end
    end), "detached mirror control rejected by latest external changes")
    local blind, replaced = text:gsub("return not Equal%(localValue, base%) and Equal%(remote, base%)",
        "return not Equal(localValue, remote)", 1)
    check(replaced == 1, "freshness-control mutation selects actual conflict decision")
    local cons = constants(false, false)
    local db, remote = localDB(), database(cons)
    local h = boot(db, remote, cons)
    h.sync.Bind(db, remote, cons, "Current-Realm")
    db, remote = copy(db), copy(remote)
    h = boot(db, nil, cons, nil, blind); h.sync.Restore(db)
    setCount(db.Characters['Alt-Realm'].bags[0][1], 60)
    remote.Characters['Alt-Realm'].bags[1][1].itemCount = 70
    h = boot(db, remote, cons, nil, blind); h.sync.Bind(db, remote, cons, "Current-Realm")
    check(remote.Characters['Alt-Realm'].bags[1][1].itemCount ~= 70,
        "unsafe local-wins control rejected by independently updated remote snapshot")
end

-- Repeat a representative larger account to expose accidental event-driven
-- account copies. Report raw desktop startup timings without native claims.
local measurements = {}
for repeatIndex = 1, 5 do
    local cons = constants(true, true)
    local db, remote = localDB(), database(cons)
    for i = 1, 100 do
        local char = character("Large" .. i, cons)
        for slot = 1, 72 do char.bags[1][slot] = item(10000 + slot, i) end
        remote.Characters['Large' .. i .. '-Realm'] = char
    end
    local started = os.clock()
    local h = boot(db, remote, cons); h.sync.Bind(db, remote, cons, "Current-Realm")
    local bound = os.clock()
    local persistedRemote = copy(remote); db = copy(db)
    local serialized = os.clock()
    h = boot(db, nil, cons); h.sync.Restore(db)
    local restored = os.clock()
    check(count(db.Characters['Large100-Realm'].bags[0][72]) == 100,
        "large account complete across repeated provider transitions " .. repeatIndex)
    setCount(db.Characters['Large100-Realm'].bags[0][72], 200)
    local mergeStart = os.clock()
    h = boot(db, persistedRemote, cons); h.sync.Bind(db, persistedRemote, cons, "Current-Realm")
    local merged = os.clock()
    check(persistedRemote.Characters['Large100-Realm'].bags[1][72].itemCount == 200,
        "large account stale provider receives standalone edit " .. repeatIndex)
    measurements[#measurements + 1] = string.format("%.6f/%.6f/%.6f/%.6f",
        bound - started, serialized - bound, restored - serialized, merged - mergeStart)
end
print("syndicator_sync: " .. checks .. " checks, " .. failures .. " failures")
print("desktop initial-bind/serialization/restore/reconcile seconds (five samples): " .. table.concat(measurements, ", "))
os.exit(failures == 0 and 0 or 1)
