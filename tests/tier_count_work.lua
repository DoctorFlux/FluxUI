-- Real bag/bank tier counts over the existing tier fixture; no native tooltip VM.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local source, measure = "Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua", false
for i, value in ipairs(arg or {}) do
    if value == "--source" then source = assert(arg[i + 1]) end
    if value == "--measure" then measure = true end
end
local before = read("tests/fixtures/tier_count_match_before.txt")
local fixture = read("tests/idle_tiers.lua")
fixture = fixture:sub(1, assert(fixture:find("local function exercise(", 1, true)) - 1)
local Boot = assert(load(fixture .. "\nreturn fixture", "@existing-tier-fixture", "t", _G))()
local kinds = { "food", "water", "bandage", "healPotion", "manaPotion" }
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function boot(body, branch, configure)
    local s = Boot("local function wipe(t) for k in pairs(t) do t[k] = nil end end\n" .. body, branch, configure)
    local p, inv = s.tiers._Private, s.inv
    s.generation, s.threshold, s.inferior, s.bankReads = 1, 0, {}, 0
    s.bank, s.war = {}, {}
    for id = 1, 150 do s.bank[id] = 2 end
    if branch == "live" or branch == "forever" then
        for id = 121, 180 do s.war[id] = 3 end
        s.war[6] = 4 -- same item in both stores must count once with merged quantity
        s.cls[151] = { kind = "healPotion", health = 400, mana = 0, effective = 400 }
    end
    inv.Bank = {
        GetCharacterCounts = function() return s.bank end,
        GetWarbandCounts = function() return s.war end,
        GetCount = function(id) s.bankReads = s.bankReads + 1; return (s.bank[id] or 0) + (s.war[id] or 0) end,
    }
    if branch ~= "live" and branch ~= "forever" then inv.Bank.GetWarbandCounts = nil end
    inv.GetCount = function(id)
        local total, any = 0, false
        for _, slots in pairs(s.live) do for _, item in ipairs(slots) do
            any = true
            if item.itemID == id then total = total + (item.stackCount or item.count or 0) end
        end end
        return any and total or (s.unique[id] and s.unique[id].count or 0)
    end
    p.countCache = { kinds = {}, bagGen = -1 }
    p.FOOD_WATER_KINDS = { food = true, water = true }
    p.GetBagCacheGen = function() return s.generation end
    p.GetMerchantCacheGen = function() return s.generation end
    p.GetTierRestockThreshold = function() return s.threshold end
    p.ResolveMerchantIndex = function(index) return index end
    p.FJ = function() return { IsUpgradeInferior = function(id) return s.inferior[id] end } end
    return s
end
for _, branch in ipairs({ "classic_era", "classic_anniversary", "classic", "live", "forever" }) do
    local a, b = boot(before, branch), boot(read(source), branch)
    local function compare(index)
        a.generation, b.generation = a.generation + 1, b.generation + 1
        for _, kind in ipairs(kinds) do
            check(a.tiers.GetTierCount(kind, index or {}) == b.tiers.GetTierCount(kind, index or {}),
                branch .. " bag quantity parity " .. kind)
            check(a.tiers.GetBankCountForKind(kind, index or {}) == b.tiers.GetBankCountForKind(kind, index or {}),
                branch .. " cached bank/warband quantity parity " .. kind)
        end
    end
    a.calls, b.calls = 0, 0; compare()
    local firstA, firstB = a.calls, b.calls
    check(firstB < firstA / 10, branch .. " initial counts skip unrelated usability")
    a.calls, b.calls = 0, 0
    for _ = 1, 25 do compare() end
    print(("METRIC %s initial_checks=%d repeat_checks=%d bank_reads=%d")
        :format(branch, firstB, b.calls, b.bankReads))
    check(b.calls < a.calls / 10, branch .. " 25 reconciliations skip unrelated usability")
    -- All matching live gates and existing selection/accounting rules still apply.
    for _, s in ipairs({ a, b }) do
        s.blocked[2], s.blocked[5] = false, true
        s.threshold = 200; s.inferior[9] = true
        s.bank[1], s.bank[6] = 7, 9
    end
    compare()
    for _, s in ipairs({ a, b }) do
        s.cls[11] = { kind = "food", health = 300, mana = 0, effective = 300 }
        s.unique[11], s.bank[11] = { count = 4 }, 5
    end
    compare()
    -- Vendor-first records and snapshot/live bags must never double-credit a SKU.
    compare({ [1] = { slot = 1, link = "item:1" }, [11] = { slot = 2, link = "item:11" } })
    for _, s in ipairs({ a, b }) do
        s.unique = {}
        s.live[0] = { { itemID = 1, count = 2 }, { itemID = 11, stackCount = 3 } }
        s.live[1] = { { itemID = 5, count = 1 }, { itemID = 7, count = 2 } }
        s.inferior[9], s.threshold = nil, 0
    end
    compare()
    -- Unresolved facts retry after arrival; zero answers remain uncached.
    for _, s in ipairs({ a, b }) do s.cls[11] = nil end
    compare()
    for _, s in ipairs({ a, b }) do
        s.cls[11] = { kind = "food", health = 300, mana = 0, effective = 300 }
    end
    compare()
    for _, s in ipairs({ a, b }) do s.inv.Bank = nil end
    compare()
    for _, s in ipairs({ a, b }) do
        s.inv.Bags, s.inv.GetBagContainerIDs, s.inv.GetContainerItemInfo = nil, nil, nil
        s.live = {}
    end
    compare()
end
do
    local function configure(s, env)
        s.rawSlots, s.slotReads = {}, { 0, 0, 0, 0 }
        local ns = { Flux = {
            Inventory = {
                IsReliable = function() return not s.unreliable end,
                GetBagGeneration = function() return s.generation end,
            },
            Container = { GetItemInfo = function(_, slot)
                s.slotReads[slot] = s.slotReads[slot] + 1
                return s.rawSlots[slot]
            end },
        } }
        assert(load(read("Inventory/Restock/FluxRestock_Inv.lua"), "@restock-inv", "t", env))("_FluxUI", ns)
        local inv = env.FluxRestock.Inv
        inv.GetBagContainerIDs = function() return { 0 } end
        inv.GetContainerNumSlots = function() return 4 end
        inv.Bags.GetUniqueItems = function() return s.unique end
        s.tiers._Private.Inv = function() return inv end
        s.inv = inv
        return ns
    end
    local s = boot(read(source), "live-tier-slots", configure)
    local p, tiers, scratch = s.tiers._Private, s.tiers, {}
    s.unique = {}
    s.rawSlots[1] = { itemID = 5, stackCount = 2, hyperlink = "item:5" }
    s.rawSlots[3] = { itemID = 1, hyperlink = "item:1" }
    s.rawSlots[4] = { itemID = 6, stackCount = 2 }
    check(p.GetTierCountForRestockList("healPotion", {}, scratch) == 0, "cold traversal with resolved merchant index")
    s.rawSlots[2] = { itemID = 10, stackCount = 3, hyperlink = "item:10" }
    s.rawSlots[3].stackCount = 7
    s.rawSlots[4].hyperlink = "item:6"
    check(p.GetTierCountForRestockList("water", {}, scratch) == 5, "newly occupied slot is read live")
    check(table.concat(s.slotReads, ",") == "1,2,2,2", "only complete original slot is reused")
    check(p.GetTierCountForRestockList("food", {}, scratch) == 7, "newly available raw count overrides default one")
    check(table.concat(s.slotReads, ",") == "1,2,2,2", "completed slots become reusable within the build")
    s.generation = s.generation + 1
    s.rawSlots[4].stackCount = 9
    check(p.GetTierCountForRestockList("bandage", {}, scratch) == 9, "bag generation change invalidates reused slots")
    check(table.concat(s.slotReads, ",") == "2,3,3,3", "new generation reads every addressed slot")
    local normal = s.inv.GetContainerItemInfo
    local calls = 0
    s.inv.GetContainerItemInfo = function(...)
        calls = calls + 1
        return normal(...)
    end
    check(p.GetTierCountForRestockList("manaPotion", {}, scratch) == 0 and calls == 4, "replaced restock slot provider retains traversal")
    tiers.GetTierCount = function() return 42 end
    check(p.GetTierCountForRestockList("water", {}, scratch) == 42, "replaced public tier owner keeps authority")
end
do
    local s = boot(read(source), "tier-classification-filter")
    local p = s.tiers._Private
    check(p.ClassifyItem(1).kind == "food", "unfiltered item query still returns the original kind")
    check(not p.ClassificationForTierCount("bandage", 1), "unrelated owned classification is rejected")
    check(not p.ClassificationForTierCount("water", 9), "combination food is not pure water")
    local water = p.ClassificationForTierCount("water", 10)
    check(water and water.kind == "water" and water.mana == 150, "mana-only food still counts as water")

    local calls = 0
    p.ClassifyItem = function(itemID, itemLink, ...)
        calls = calls + 1
        check(itemID == 1 and itemLink == "item:1" and select("#", ...) == 0, "replacement classifier receives two original arguments")
        return { kind = "bandage", health = 30 }
    end
    local bandage = p.ClassificationForTierCount("bandage", 1, "item:1")
    check(bandage and bandage.health == 30 and calls == 1, "replacement classifier retains authority")
end
do
    local s = Boot(read(source), "owned-closed-bank-classifier", function(profile, env)
        local p = profile.tiers._Private
        local itemClass = {
            GetStatic = function(id) return { classID = id == 6 and 0 or 2 } end,
            ClassifyConsumable = function() end,
        }
        local classifier = { Classify = function(id) return profile.cls[id] end }
        p.IC = function() return itemClass end
        p.ClassifyMod = function() return classifier end
        profile.bankReads = 0
        profile.inv.Bank = {
            GetCount = function(id)
                profile.bankReads = profile.bankReads + 1
                return id == 6 and 2 or 1
            end,
            GetCharacterCounts = function() return { [6] = 2, [99] = 1 } end,
            IsOpen = function() return false end,
            IsLive = function() return false end,
            GetGeneration = function() return 1 end,
        }
        env.wipe = function(values) for key in pairs(values) do values[key] = nil end end
        return { Flux = {
            Inventory = {
                GetSnapshotGeneration = function() return 1 end,
                GetBagGeneration = function() return 1 end,
                IsReliable = function() return true end,
            },
            Item = { GetCount = function() return 0 end },
        } }
    end)
    local closedCounts = {}
    local p = s.tiers._Private
    p.GetTierRestockThreshold = function() return 1 end
    local count = p.GetBankCountForRestockList("bandage", nil, closedCounts)
    check(count == 2 and closedCounts[99] == false and s.bankReads == 1,
        "owned closed-bank classifier excludes equipment and retains actual bandages")
end
do
    local s = Boot(read(source), "owned-bank-tier-kind", function(profile, env)
        local p = profile.tiers._Private
        local classifier = { Classify = function(id) return profile.cls[id] end }
        local itemClass = { GetStatic = function() return { classID = 0 } end, ClassifyConsumable = function() end }
        local junk = { IsUpgradeInferior = function() return false end }
        profile.usable = {}
        local score = { IsUsable = function(id)
            profile.usable[id] = (profile.usable[id] or 0) + 1
            return true
        end }
        local best = { Score = score }
        profile.score = score
        p.ClassifyMod = function() return classifier end
        p.IC = function() return itemClass end
        p.Best = function() return best end
        p.FJ = function() return junk end
        local function count(id) return profile.unique[id] and profile.unique[id].count or 0 end
        profile.inv.GetLiveCount, profile.inv.GetCount = count, count
        env.wipe = function(values) for key in pairs(values) do values[key] = nil end end
        return {
            Flux = { Inventory = { GetLiveCount = count, Index = { GetLiveCount = count, GetCount = count },
                GetBagGeneration = function() return 1 end, IsReliable = function() return true end },
                Item = { GetCount = count } },
            ConsumableRejectedCacheQuery = { owner = classifier, classify = classifier.Classify,
                settledKind = function(id)
                    local c = profile.cls[id]
                    return c and c.kind
                end },
        }
    end)
    local tiers, p = s.tiers, s.tiers._Private
    local counts = {}
    s.unique = { [1] = { count = 1 }, [6] = { count = 2 }, [10] = { count = 3 }, [11] = { count = 4 } }
    check(p.GetBankTierBagTotal("bandage", counts) == 2, "bank builder keeps available bandages")
    check(s.usable[1] == nil and s.usable[10] == nil and s.usable[6] == 1 and s.usable[11] == 1,
        "only a settled different kind skips the usability checks")
    check(p.GetBankTierBagTotal("water", counts) == 3, "mana-only food still counts as water in bank targets")
    s.cls[11] = { kind = "bandage", health = 100 }
    check(p.GetBankTierBagTotal("bandage", counts) == 6, "a formerly unknown kind contributes without a bag change")
    local isUsable = s.score.IsUsable
    s.score.IsUsable = function(id) return isUsable(id) end
    s.usable = {}
    check(p.GetBankTierBagTotal("bandage", counts) == 6 and s.usable[1] == 1,
        "a replaced usability callback still receives unrelated items")
    s.score.IsUsable = isUsable
    local matches = tiers.ItemMatchesRestockKind
    tiers.ItemMatchesRestockKind = function(kind, id) return id == 1 or matches(kind, id) end
    check(p.GetBankTierBagTotal("bandage", counts) == 7, "a replaced tier matcher still owns the result")
end
print(("Tier count work: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
