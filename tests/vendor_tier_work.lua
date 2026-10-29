-- Production merchant events/index, tier seed/status and live Score usability.
-- Classification facts and native widgets/APIs are modeled; native timing is unverified.
local baseline, measure = false, false
for _, value in ipairs(arg or {}) do
    if value == "--baseline" then baseline = true end
    if value == "--measure" then measure = true end
end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close()
    return s:gsub("\r\n", "\n")
end
local bootSource = read("tests/vendor_slot_identity.lua")
bootSource = bootSource:sub(1, assert(bootSource:find("\nif not stockOnly then", 1, true)) - 1)
local Boot = assert(load(bootSource .. "\nreturn boot", "@merchant-fixture", "t",
    setmetatable({ arg = {} }, { __index = _G })))()
local kinds = { "food", "water", "bandage", "healPotion", "manaPotion" }
local checks, failures = 0, 0
local function check(value, message)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. message) end
end
local function fixture(modern, size)
    local h = Boot(modern, false, size, false)
    local env = h.env
    env.wipe = function(t) for key in pairs(t) do t[key] = nil end end
    local s = { info = 0, owned = 0, classify = 0, level = 60, minLevel = {}, missing = {},
        facts = {}, saved = {}, threshold = {}, generation = 1, index = nil }
    env.UnitLevel = function() return s.level end
    env.UnitHealthMax, env.UnitPowerMax = function() return 1000 end, function() return 1000 end
    env.Flux = { Inventory = { GetCount = function() s.owned = s.owned + 1; return 0 end } }
    local ic = {
        GetInfo = function(id)
            s.info = s.info + 1
            if s.missing[id] then return nil end
            return { name = "Item", minLevel = s.minLevel[id] or 1 }
        end,
        RequestLoad = function() end,
        GetRestore = function() return nil end,
        ClassifyConsumable = function() return nil end,
    }
    env.FluxItemClass = ic
    env.FluxConsumableBest = { IsManaKind = function(kind) return kind == "water" or kind == "manaPotion" end,
        IsManaKindRelevant = function() return true end }
    assert(loadfile("Inventory/FluxConsumableBest/Score.lua", "t", env))()
    local score = env.FluxConsumableBest.Score
    local p = { KINDS = kinds, KIND_FIELDS = {}, FOOD_WATER_KINDS = { food = true, water = true },
        vendorStatusCache = { kinds = {} }, merchantWarmItemIDs = {},
        IC = function() return ic end,
        Inv = function() return { Bags = { GetUniqueItems = function() return {} end } } end,
        Best = function() return env.FluxConsumableBest end,
        ClassifyMod = function() return { Classify = function(id)
            s.classify = s.classify + 1; return s.facts[id]
        end } end,
        GetSavedTier = function(kind) return s.saved[kind] or 0 end,
        SetSavedTier = function(kind, value) s.saved[kind] = value end,
        RoundTier = function(value) return math.floor((value or 0) + 0.5) end,
        GetTierRestockThreshold = function(kind) return s.threshold[kind] or 0 end,
        GetBagCacheGen = function() return s.generation end,
        GetMerchantCacheGen = function() return s.generation end,
        Settings = function() return { pendingVendorTierSell = { kinds = {} } } end,
    }
    for _, kind in ipairs(kinds) do p.KIND_FIELDS[kind] = true end
    local tiers = { _Private = p, IsTierEligible = function() return true end,
        IsMarkInferiorEnabled = function() return false end,
        HasPendingVendorUpgradeRestock = function() return false end,
        InvalidateTierQueryCache = function() s.generation = s.generation + 1 end }
    env.FluxRestockTiers = tiers
    local matchPath = baseline and "tests/fixtures/vendor_tier_match_before.txt" or
        "Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua"
    local vendorPath = baseline and "tests/fixtures/vendor_tier_status_before.txt" or
        "Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua"
    assert(loadfile(matchPath, "t", env))()
    assert(loadfile(vendorPath, "t", env))()
    p.GetTierRestockThreshold = function(kind) return s.threshold[kind] or 0 end
    for i, kind in ipairs(kinds) do
        for n = 1, 2 do
            local id = 100000 + (i - 1) * 2 + n
            s.facts[id] = { kind = kind, health = (i == 2 or i == 5) and 0 or n * 100,
                mana = (i == 2 or i == 5) and n * 100 or 0, effective = n * 100 }
        end
    end
    s.h, s.env, s.p, s.tiers, s.score = h, env, p, tiers, score
    function s:status()
        self.generation = self.generation + 1
        for i, kind in ipairs(kinds) do
            local v, id = p.ScanVendorBestPurchasable(kind, self.index)
            local status = tiers.GetVendorTierStatus(kind, self.index)
            check(v == 200 and id == 100000 + i * 2, "best restore/ID unchanged " .. kind)
            check(status.hasStock and status.bestValue == v and status.bestItemID == id,
                "status selection matches best " .. kind)
        end
    end
    h.fv.RegisterMerchantIndexListener(function(index)
        s.index = index
        tiers.InvalidateTierQueryCache()
    end)
    -- Reopen to measure real merchant-driven seed work on a fresh reference store.
    h:event("MERCHANT_CLOSED"); h.merchant = true; h:event("MERCHANT_SHOW")
    s.info, s.owned, s.classify = 0, 0, 0
    h:event("MERCHANT_UPDATE"); h:advance(1)
    local seedInfo, seedOwned, seedClassify = s.info, s.owned, s.classify
    for _, kind in ipairs(kinds) do check(s.saved[kind] == 200, "vendor still seeds reference " .. kind) end
    s.info, s.owned, s.classify = 0, 0, 0
    s:status()
    print(("METRIC %s_%d seed_info=%d seed_owned=%d status_info=%d status_owned=%d seed_classify=%d status_classify=%d")
        :format(modern and "modern" or "legacy", size, seedInfo, seedOwned, s.info, s.owned, seedClassify, s.classify))
    check(seedInfo <= 10 and seedOwned <= 10, "seed checks usability only for matching contenders")
    check(s.info <= 20 and s.owned <= 20, "best/status check usability only for matching contenders")
    return s
end
for _, modern in ipairs({ false, true }) do
    for _, size in ipairs({ 20, 200 }) do
        local s = fixture(modern, size)
        local p, tiers, index = s.p, s.tiers, s.index
        -- Live required-level changes must still reject a stronger matching item.
        s.minLevel[100002] = 61; s.generation = s.generation + 1
        local v, id = p.ScanVendorBestPurchasable("food", index)
        check(v == 100 and id == 100001, "higher-level food rejected")
        local status = tiers.GetVendorTierStatus("food", index)
        check(status.bestValue == 100 and status.bestItemID == 100001, "status honors changed level")
        s.level = 61; s.generation = s.generation + 1
        check(p.ScanVendorBestPurchasable("food", index) == 200, "live player level unlocks stronger item")
        s.threshold.food = 250; s.generation = s.generation + 1
        status = tiers.GetVendorTierStatus("food", index)
        check(status.lowerTierOnly and not status.hasStock and status.bestValue == 200,
            "lower-tier-only status retained")
        s.threshold.food = 0; s.facts[100002].wellFed = true; s.generation = s.generation + 1
        check(p.ScanVendorBestPurchasable("food", index) == 100, "Well Fed cannot win food")
        check(tiers.GetVendorTierStatus("food", index).bestValue == 100, "Well Fed status excluded")
        index[100001].isPurchasable = false; s.generation = s.generation + 1
        check(p.ScanVendorBestPurchasable("food", index) == 0, "unavailable listing excluded")
        check(not tiers.GetVendorTierStatus("food", index).hasStock, "unavailable status excluded")
        index[100001].isPurchasable = true; s.facts[100002].wellFed = nil
        s.missing[100002] = true; s.generation = s.generation + 1
        check(p.ScanVendorBestPurchasable("food", index) == 200, "cold vendor item retains tolerant level gate")
        -- Exercise the actual live gate on every matching candidate without caching it.
        local usable = s.score.IsUsableForVendor
        local blocked = false
        s.score.IsUsableForVendor = function(itemID, kind)
            return not (blocked and itemID == 100002) and usable(itemID, kind)
        end
        blocked = true; check(p.ScanVendorBestPurchasable("food", index) == 100, "live skill change rejected")
        blocked = false; check(p.ScanVendorBestPurchasable("food", index) == 200, "live skill recovery retried")
        s.missing[100002] = nil
        -- Late classification, equal-value price tie, and food+water convention.
        s.facts[100002] = nil; check(p.ScanVendorBestPurchasable("food", index) == 100, "missing classification retries later")
        s.facts[100002] = { kind = "food", health = 100, mana = 100, effective = 100 }
        index[100002].unitPrice = 1; s.generation = s.generation + 1
        status = tiers.GetVendorTierStatus("food", index)
        check(status.bestItemID == 100002 and status.bestPrice == 1, "equal-value cheaper item retained")
        check(p.ScanVendorBestPurchasable("water", index) == 200, "combo food does not replace pure water")
        check(#s.h.calls == 0, "opening/scanning alone never purchases")
        check(#s.h.frames == 1, "existing buyer event frame reused")
    end
end
print(("Vendor tier work: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
