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
local function boot(body, branch)
    local s = Boot("local function wipe(t) for k in pairs(t) do t[k] = nil end end\n" .. body, branch)
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
print(("Tier count work: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
