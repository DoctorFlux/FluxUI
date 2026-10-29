--[[
    Restock/Core/Tiers/FluxRestockTiers_Match.lua

    Classify + effective restore matching / counting via FluxConsumableBest.
]]

local Tiers = FluxRestockTiers
local P = Tiers._Private

local function NumericItemID(value)
    local n = tonumber(value)
    if n and n > 0 then
        return n
    end
    local Secrets = _G.Flux and _G.Flux.Secrets
    if Secrets and Secrets.SafeGetNumber then
        n = Secrets.SafeGetNumber(value, 0)
        if n and n > 0 then
            return n
        end
    end
    return nil
end

local function NumericCount(value)
    local n = tonumber(value)
    if n and n > 0 then
        return n
    end
    local Secrets = _G.Flux and _G.Flux.Secrets
    if Secrets and Secrets.SafeGetNumber then
        n = Secrets.SafeGetNumber(value, 0)
        if n and n > 0 then
            return n
        end
    end
    return 0
end

-- C_Item.GetItemCount, bypassing snapshot + IsReliable. Restock need must
-- see stacks already in bags even when Syndicator has not flushed.
local function LiveBagCount(inv, itemID)
    itemID = NumericItemID(itemID)
    if not itemID then
        return 0
    end
    if inv and inv.GetLiveCount then
        local n = NumericCount(inv.GetLiveCount(itemID, {
            bags = true,
            bank = false,
            warband = false,
            charges = false,
        }))
        if n > 0 then
            return n
        end
    end
    local Item = _G.Flux and _G.Flux.Item
    if Item and Item.GetCount then
        local n = NumericCount(Item.GetCount(itemID, false, false, false, false))
        if n > 0 then
            return n
        end
    end
    if C_Item and C_Item.GetItemCount then
        local ok, raw = pcall(C_Item.GetItemCount, itemID, false, false, false, false)
        if ok then
            local n = NumericCount(raw)
            if n > 0 then
                return n
            end
        end
    end
    if inv and inv.GetCount then
        return NumericCount(inv.GetCount(itemID, {
            bags = true,
            bank = false,
            warband = false,
        }))
    end
    return 0
end

local function ForEachUniqueBagStack(inv, fn)
    if not inv or type(fn) ~= "function" then
        return 0
    end
    local unique = inv.Bags and inv.Bags.GetUniqueItems and inv.Bags.GetUniqueItems()
    if type(unique) ~= "table" and inv.GetUniqueItems then
        unique = inv.GetUniqueItems({ bags = true, bank = false, warband = false })
    end
    if type(unique) ~= "table" then
        return 0
    end
    local stacks = 0
    for itemID, rec in pairs(unique) do
        itemID = NumericItemID(itemID) or NumericItemID(rec and rec.itemID)
        local n = rec and NumericCount(rec.count) or 0
        if n <= 0 and type(rec) == "number" then
            n = NumericCount(rec)
        end
        if itemID and n > 0 then
            stacks = stacks + 1
            fn(itemID, n)
        end
    end
    return stacks
end

-- Live container walk (not snapshot ForEachLocation). Used when unique-map
-- totals are 0 because Syndicator/builtin snapshots have not flushed yet.
local function ForEachLiveBagStack(inv, fn)
    if not inv or type(fn) ~= "function" then
        return
    end
    if inv.GetBagContainerIDs and inv.GetContainerItemInfo then
        for _, bag in ipairs(inv.GetBagContainerIDs()) do
            local numSlots = inv.GetContainerNumSlots and inv.GetContainerNumSlots(bag) or 0
            for slot = 1, numSlots do
                local info = inv.GetContainerItemInfo(bag, slot)
                local itemID = info and NumericItemID(info.itemID)
                local n = info and NumericCount(info.count or info.stackCount) or 0
                if itemID and n > 0 then
                    fn(itemID, n, info and (info.hyperlink or info.link))
                end
            end
        end
        return
    end
    if inv.ForEachLocation then
        inv.ForEachLocation(function(loc)
            local itemID = NumericItemID(loc and loc.itemID)
            local n = loc and NumericCount(loc.count) or 0
            if itemID and n > 0 then
                fn(itemID, n, loc and loc.link)
            end
        end, { bags = true, bank = false, warband = false, equipped = false })
    end
end

local function AxisFromClassify(kind, cls)
    if not cls then
        return 0
    end
    if kind == "water" or kind == "manaPotion" then
        return tonumber(cls.mana or cls.effective) or 0
    end
    return tonumber(cls.health or cls.effective) or 0
end

--- Classify item into a tier kind record, or nil.
function P.ClassifyItem(itemID, itemLink)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    local Classify = P.ClassifyMod()
    if Classify and Classify.Classify then
        local cls = Classify.Classify(itemID, itemLink)
        if cls and P.KIND_FIELDS[cls.kind] then
            local Score = P.Best() and P.Best().Score
            local effective = cls.effective or 0
            if Score and Score.EffectiveFromClassify then
                effective = Score.EffectiveFromClassify(cls)
            end
            return {
                kind = cls.kind,
                health = cls.health or 0,
                mana = cls.mana or 0,
                effective = effective,
                isPercent = cls.isPercent and true or false,
                isConjured = cls.isConjured and true or false,
                wellFed = cls.wellFed and true or false,
                bandage = cls.kind == "bandage",
            }
        end
    end
    -- Fallback: FluxItemClass.ClassifyConsumable multi-axis
    local IC = P.IC()
    if IC and IC.ClassifyConsumable then
        local rec = IC.ClassifyConsumable(itemID, itemLink)
        if not rec then
            return nil
        end
        if (rec.bandage or 0) > 0 then
            return { kind = "bandage", health = rec.bandage, mana = 0, effective = rec.bandage, isConjured = false }
        end
        if (rec.healPotion or 0) > 0 then
            return { kind = "healPotion", health = rec.healPotion, mana = 0, effective = rec.healPotion, isConjured = false }
        end
        if (rec.manaPotion or 0) > 0 then
            return { kind = "manaPotion", health = 0, mana = rec.manaPotion, effective = rec.manaPotion, isConjured = false }
        end
        if (rec.food or 0) > 0 then
            return {
                kind = "food", health = rec.food, mana = rec.water or 0, effective = rec.food,
                isConjured = rec.conjured == true, wellFed = rec.wellFed == true,
            }
        end
        if (rec.water or 0) > 0 then
            return {
                kind = "water", health = 0, mana = rec.water, effective = rec.water,
                isConjured = rec.conjured == true, wellFed = false,
            }
        end
    end
    return nil
end

function P.ClassificationForTierCount(kind, itemID, itemLink)
    local cls = P.ClassifyItem(itemID, itemLink)
    if not cls then
        return nil
    end
    -- Combo food+water: food kind uses health; water kind only pure water (not combo).
    if kind == "water" and cls.kind == "food" and (cls.mana or 0) > 0 and (cls.health or 0) > 0 then
        return nil
    end
    if kind == "water" and cls.kind == "food" and (cls.mana or 0) > 0 and (cls.health or 0) <= 0 then
        cls = {
            kind = "water",
            health = 0,
            mana = cls.mana,
            effective = cls.mana,
            isConjured = cls.isConjured,
            wellFed = false,
        }
    end
    if cls.kind ~= kind then
        -- Allow food classify with mana-only for water handled above.
        return nil
    end
    return cls
end

function P.TierAxisValue(kind, cls)
    return AxisFromClassify(kind, cls)
end

function Tiers.Classify(itemID, itemLink)
    return P.ClassifyItem(itemID, itemLink)
end

--- Merchant hyperlink from index meta (slot or cached link).
function P.MerchantItemLink(meta)
    if type(meta) ~= "table" then
        return nil
    end
    if meta.link then
        return meta.link
    end
    if meta.slot and GetMerchantItemLink then
        return GetMerchantItemLink(meta.slot)
    end
    return nil
end

--- Classify a merchant row for a tier kind (link + restore warm).
function P.ClassifyMerchantItem(kind, itemID, meta)
    itemID = tonumber(itemID)
    if not itemID or not P.KIND_FIELDS[kind] then
        return nil
    end
    local link = P.MerchantItemLink(meta)
    local cls = P.ClassificationForTierCount(kind, itemID, link)
    if cls then
        return cls
    end
    local IC = P.IC()
    if not IC then
        return nil
    end
    if link and IC.GetRestore then
        local restore = IC.GetRestore(itemID, link)
        if restore and restore.ready and not restore.wellFed and not restore.bandage then
            if kind == "food" and restore.isFoodWater and (restore.health or 0) > 0 then
                return {
                    kind = "food",
                    health = restore.health or 0,
                    mana = restore.mana or 0,
                    effective = restore.health or 0,
                    isConjured = restore.conjured == true,
                    wellFed = false,
                }
            end
            if kind == "water" and restore.isFoodWater and (restore.mana or 0) > 0
                and (restore.health or 0) <= 0 then
                return {
                    kind = "water",
                    health = 0,
                    mana = restore.mana or 0,
                    effective = restore.mana or 0,
                    isConjured = restore.conjured == true,
                    wellFed = false,
                }
            end
        end
        if restore and restore.ready and restore.bandage and kind == "bandage" and (restore.health or 0) > 0 then
            return {
                kind = "bandage",
                health = restore.health or 0,
                mana = 0,
                effective = restore.health or 0,
                isConjured = false,
                wellFed = false,
                bandage = true,
            }
        end
    end
    if link and IC.ClassifyConsumable then
        local rec = IC.ClassifyConsumable(itemID, link)
        if not rec then
            return nil
        end
        if kind == "bandage" and (rec.bandage or 0) > 0 then
            return { kind = "bandage", health = rec.bandage, mana = 0, effective = rec.bandage, isConjured = false }
        end
        if kind == "healPotion" and (rec.healPotion or 0) > 0 then
            return { kind = "healPotion", health = rec.healPotion, mana = 0, effective = rec.healPotion, isConjured = false }
        end
        if kind == "manaPotion" and (rec.manaPotion or 0) > 0 then
            return { kind = "manaPotion", health = 0, mana = rec.manaPotion, effective = rec.manaPotion, isConjured = false }
        end
        if kind == "food" and (rec.food or 0) > 0 then
            return {
                kind = "food", health = rec.food, mana = rec.water or 0, effective = rec.food,
                isConjured = rec.conjured == true, wellFed = rec.wellFed == true,
            }
        end
        if kind == "water" and (rec.water or 0) > 0 and (rec.food or 0) <= 0 then
            return {
                kind = "water", health = 0, mana = rec.water, effective = rec.water,
                isConjured = rec.conjured == true, wellFed = false,
            }
        end
    end
    return nil
end

--- Best purchasable vendor restore for kind. Returns best, bestItemID, bestMeta.
function P.ScanVendorBestPurchasable(kind, merchantIndex)
    merchantIndex = P.ResolveMerchantIndex and P.ResolveMerchantIndex(merchantIndex) or merchantIndex
    if type(merchantIndex) ~= "table" then
        local FV = _G.FluxVendorBuy or _G.FluxVendorAuto
        merchantIndex = FV and FV.GetMerchantItemIndex and FV.GetMerchantItemIndex(false) or nil
    end
    if type(merchantIndex) ~= "table" then
        return 0, nil, nil
    end
    local best, bestID, bestMeta = 0, nil, nil
    for itemID, meta in pairs(merchantIndex) do
        itemID = tonumber(itemID) or (type(meta) == "table" and tonumber(meta.itemID))
        if itemID and type(meta) == "table" and meta.isPurchasable ~= false
            and P.IsTierItemUsable(kind, itemID, { vendor = true }) then
            local cls = P.ClassifyMerchantItem(kind, itemID, meta)
            if cls and not cls.wellFed then
                local v = P.RoundTier(P.TierAxisValue(kind, cls))
                if v > best then
                    best, bestID, bestMeta = v, itemID, meta
                end
            end
        end
    end
    return best, bestID, bestMeta
end

function Tiers.GetItemTierValue(kind, itemID)
    local cls = P.ClassificationForTierCount(kind, itemID)
    return P.RoundTier(P.TierAxisValue(kind, cls))
end

--- Best non-conjured restore actually sitting in bags (never vendor memory / Best.ref).
function Tiers.GetBagOwnedTier(kind)
    local inv = P.Inv()
    local bestV, bestID = 0, nil
    local function consider(itemID, n)
        if n <= 0 then
            return
        end
        local cls = P.ClassificationForTierCount(kind, itemID)
        -- Only matching non-conjured restores can win this ladder. Avoid
        -- usability/tooltips for every unrelated bag item for every kind.
        -- Keep the live usable gate for every candidate; cache no verdict.
        if cls and not cls.isConjured and not cls.wellFed then
            local v = P.RoundTier(P.TierAxisValue(kind, cls))
            if v > bestV and P.IsTierItemUsable(kind, itemID) then
                bestV, bestID = v, itemID
            end
        end
    end
    -- Unique snapshot or live walk, not both. Live is only for empty/unflushed snapshots.
    local stacks = ForEachUniqueBagStack(inv, consider)
    if stacks == 0 then
        ForEachLiveBagStack(inv, consider)
    end
    return bestV, bestID
end

--- Reference restore bar from Best (non-conjured) + bag scan.
--- Best.GetBest may be vendor-sourced (count 0); only trust it when truly owned.
function Tiers.GetOwnedTier(kind)
    local Best = P.Best()
    local best = Best and Best.GetBest and Best.GetBest(kind)
    if best and best.itemID and not best.isConjured and (best.effective or 0) > 0 then
        local count = tonumber(best.count) or 0
        if count <= 0 then
            count = LiveBagCount(P.Inv(), best.itemID)
        end
        if count > 0 and P.IsTierItemUsable(kind, best.itemID) then
            return P.RoundTier(best.effective), best.itemID
        end
    end
    return Tiers.GetBagOwnedTier(kind)
end

local function TierRefCacheKey(kind, merchantIndex)
    return tostring(kind) .. ":" .. tostring(merchantIndex or "")
end

local function TakeTierRefCache(bucket, key)
    local cache = P.tierRefCache
    if not cache then
        return nil
    end
    local bagGen = P.GetBagCacheGen()
    local merchantGen = P.GetMerchantCacheGen()
    if cache.bagGen ~= bagGen or cache.merchantGen ~= merchantGen then
        cache.bagGen = bagGen
        cache.merchantGen = merchantGen
        wipe(cache.effective)
        wipe(cache.inferior)
    end
    return cache[bucket][key]
end

local function StoreTierRefCache(bucket, key, value)
    local cache = P.tierRefCache
    if cache and cache[bucket] then
        cache[bucket][key] = value
    end
    return value
end

function Tiers.GetEffectiveReferenceTier(kind)
    local cacheKey = TierRefCacheKey(kind)
    local cached = TakeTierRefCache("effective", cacheKey)
    if cached ~= nil then
        return cached
    end
    local saved = P.GetSavedTier(kind)
    local owned = Tiers.GetOwnedTier(kind)
    local Best = P.Best()
    local ref = Best and Best.GetBestRef and Best.GetBestRef(kind)
    local refV = ref and P.RoundTier(ref.effective) or 0
    local live = math.max(owned, refV)
    -- Drop saved bars that were ratcheted from items we cannot use yet.
    if saved > live then
        local inv = P.Inv()
        local inflated = false
        if inv and inv.Bags and inv.Bags.GetUniqueItems then
            local Score = Best and Best.Score
            for itemID, rec in pairs(inv.Bags.GetUniqueItems()) do
                if (rec.count or 0) > 0 then
                    itemID = tonumber(itemID)
                    if itemID and Score and Score.IsKnownUnusable and Score.IsKnownUnusable(itemID, kind) then
                        local cls = P.ClassificationForTierCount(kind, itemID)
                        local v = P.RoundTier(P.TierAxisValue(kind, cls))
                        if v >= saved then
                            inflated = true
                            break
                        end
                    end
                end
            end
        end
        if inflated or (live > 0 and not ref) then
            -- Only clamp when unusable stock explains the gap, or ref was scrubbed.
            if inflated then
                P.SetSavedTier(kind, live)
                saved = live
            end
        end
    end
    return StoreTierRefCache("effective", cacheKey, math.max(saved, owned, refV))
end

function Tiers.GetReferenceTier(kind)
    local owned = Tiers.GetOwnedTier(kind)
    local saved = P.GetSavedTier(kind)
    if owned > saved then
        P.SetSavedTier(kind, owned)
        return owned
    end
    return math.max(saved, owned)
end

function Tiers.RememberOwnedTiers()
    for _, kind in ipairs(P.KINDS) do
        if Tiers.IsTierEligible(kind) then
            Tiers.GetReferenceTier(kind)
        end
    end
end

function Tiers.ResetTierReference(kind, skipNotify)
    if not P.KIND_FIELDS[kind] then
        return
    end
    P.SetSavedTier(kind, 0)
    local Best = P.Best()
    if Best and Best.Persist and Best.Persist.GetRoot then
        local root = Best.Persist.GetRoot()
        if root and root.refs then
            root.refs[kind] = nil
        end
    end
    Tiers.InvalidateTooltipDisplayCache(kind)
    if Tiers.RequestRecompute then
        Tiers.RequestRecompute({ force = true })
    end
    if not skipNotify and FluxVendorAuto and FluxVendorAuto.NotifyVendorSettingsChanged then
        FluxVendorAuto.NotifyVendorSettingsChanged()
    end
end

function P.GetVendorBestTier(kind, merchantIndex)
    local best, bestID = P.ScanVendorBestPurchasable(kind, merchantIndex)
    return best, bestID
end

function Tiers.GetInferiorReferenceTier(kind, merchantIndex)
    local cacheKey = TierRefCacheKey(kind, merchantIndex)
    local cached = TakeTierRefCache("inferior", cacheKey)
    if cached ~= nil then
        return cached
    end
    local eff = Tiers.GetEffectiveReferenceTier(kind)
    local vendorBest = P.GetVendorBestTier(kind, merchantIndex)
    local conjure = 0
    if P.FOOD_WATER_KINDS[kind] then
        local Spells = P.Inv() and P.Inv().Spells
        if Spells and Spells.HasCreateKind then
            if kind == "food" and (Spells.HasConjureFood and Spells.HasConjureFood() or Spells.HasCreateKind("food")) then
                local best = P.Best() and P.Best().GetBest and P.Best().GetBest(kind)
                if best and best.isConjured then
                    conjure = P.RoundTier(best.effective)
                end
            elseif kind == "water" and (Spells.HasConjureWater and Spells.HasConjureWater() or Spells.HasCreateKind("water")) then
                local best = P.Best() and P.Best().GetBest and P.Best().GetBest(kind)
                if best and best.isConjured then
                    conjure = P.RoundTier(best.effective)
                end
            end
        end
    end
    return StoreTierRefCache("inferior", cacheKey, math.max(eff or 0, vendorBest or 0, conjure or 0))
end

function P.GetTierRestockThreshold(kind, merchantIndex)
    if Tiers.IsMarkInferiorEnabled(kind) then
        return P.RoundTier(Tiers.GetInferiorReferenceTier(kind, merchantIndex))
    end
    local eff = Tiers.GetEffectiveReferenceTier(kind)
    local owned = Tiers.GetOwnedTier(kind)
    local vendorBest = P.GetVendorBestTier(kind, merchantIndex)
    local t = eff
    if owned > 0 then
        t = math.min(t > 0 and t or owned, owned)
    end
    if vendorBest > 0 and t > 0 then
        t = math.min(t, vendorBest)
    elseif vendorBest > 0 and t <= 0 then
        t = vendorBest
    end
    return P.RoundTier(t > 0 and t or math.max(eff, owned, vendorBest))
end

--- opts.vendor: use vendor-tolerant usable gate (cold merchant IDs allowed).
function P.IsTierItemUsable(kind, itemID, opts)
    local Score = P.Best() and P.Best().Score
    if not Score then
        return true
    end
    if opts and opts.vendor and Score.IsUsableForVendor then
        return Score.IsUsableForVendor(itemID, kind)
    end
    if Score.IsUsable then
        return Score.IsUsable(itemID, kind)
    end
    return true
end

function P.ItemMatchesTier(kind, cls, threshold)
    if not cls then
        return false
    end
    if cls.wellFed then
        return false
    end
    -- Vendor bag accounting: exclude conjured food/water
    if P.FOOD_WATER_KINDS[kind] and cls.isConjured then
        return false
    end
    local v = P.RoundTier(P.TierAxisValue(kind, cls))
    if v <= 0 then
        return false
    end
    if threshold <= 0 then
        return true
    end
    return v >= threshold
end

function P.ItemMatchesTierForBank(kind, cls, ref)
    if not cls or cls.wellFed then
        return false
    end
    local v = P.RoundTier(P.TierAxisValue(kind, cls))
    if v <= 0 or ref <= 0 then
        return false
    end
    return v >= ref
end

function P.ItemMatchesTierLooseForBank(kind, cls)
    if not cls or cls.wellFed then
        return false
    end
    if kind == "water" and cls.kind == "food" and (cls.health or 0) > 0 then
        return false
    end
    return P.RoundTier(P.TierAxisValue(kind, cls)) > 0
end

function Tiers.ItemMatchesRestockKind(kind, itemID)
    itemID = tonumber(itemID)
    if not itemID or not P.IsTierItemUsable(kind, itemID) then
        return false
    end
    local fj = P.FJ()
    if fj and fj.IsUpgradeInferior and fj.IsUpgradeInferior(itemID) then
        return false
    end
    local cls = P.ClassificationForTierCount(kind, itemID)
    return P.ItemMatchesTierLooseForBank(kind, cls)
end

function Tiers.StackMatchesBankRestockKind(kind, itemID, itemLink)
    itemID = tonumber(itemID)
    if not itemID or not P.IsTierItemUsable(kind, itemID) then
        return false
    end
    local ref = P.GetTierRestockThreshold(kind)
    if ref <= 0 then
        return false
    end
    local cls = P.ClassificationForTierCount(kind, itemID, itemLink)
    return P.ItemMatchesTierForBank(kind, cls, ref)
end

local function SumUniqueMap(countsOrUnique, kind, matcher)
    local total = 0
    if type(countsOrUnique) ~= "table" then
        return 0
    end
    for itemID, rec in pairs(countsOrUnique) do
        itemID = tonumber(itemID)
        local n = type(rec) == "table" and (tonumber(rec.count) or 0) or (tonumber(rec) or 0)
        if itemID and n > 0 and matcher(kind, itemID) then
            total = total + n
        end
    end
    return total
end

function Tiers.GetTierCount(kind, merchantIndex)
    if not Tiers.IsTierEligible(kind) then
        return 0
    end
    merchantIndex = P.ResolveMerchantIndex and P.ResolveMerchantIndex(merchantIndex) or merchantIndex
    local bagGen = P.GetBagCacheGen()
    local merchantGen = P.GetMerchantCacheGen()
    local cacheKey = tostring(kind) .. ":" .. tostring(merchantIndex and true or false)
    if P.countCache.bagGen == bagGen and P.countCache.merchantGen == merchantGen then
        local cached = P.countCache.kinds[cacheKey]
        -- Never reuse a cached 0: empty Syndicator snapshots and pending
        -- classify both store 0 while bags still hold the restock item.
        if cached and cached > 0 then
            return cached
        end
    else
        P.countCache.bagGen = bagGen
        P.countCache.merchantGen = merchantGen
        wipe(P.countCache.kinds)
    end

    local threshold = P.GetTierRestockThreshold(kind, merchantIndex)
    local fj = P.FJ()
    local inv = P.Inv()
    local counted = {}
    local total = 0

    local function consider(itemID, n, link, cls, vendorOk)
        itemID = NumericItemID(itemID)
        n = NumericCount(n)
        if not itemID or n <= 0 or counted[itemID] then
            return 0
        end
        if not P.IsTierItemUsable(kind, itemID, vendorOk and { vendor = true } or nil) then
            return 0
        end
        if fj and fj.IsUpgradeInferior and fj.IsUpgradeInferior(itemID) then
            return 0
        end
        cls = cls or P.ClassificationForTierCount(kind, itemID, link)
        if P.ItemMatchesTier(kind, cls, threshold) then
            counted[itemID] = true
            return n
        end
        return 0
    end

    -- Vendor SKUs first: merchant tooltips classify even when bag tooltips
    -- are over budget / not loaded. Count via live GetItemCount.
    if type(merchantIndex) == "table" then
        for itemID, meta in pairs(merchantIndex) do
            itemID = NumericItemID(itemID) or (type(meta) == "table" and NumericItemID(meta.itemID))
            if itemID and type(meta) == "table" then
                local cls = P.ClassifyMerchantItem(kind, itemID, meta)
                total = total + consider(itemID, LiveBagCount(inv, itemID), P.MerchantItemLink(meta), cls, true)
            end
        end
    end

    local Best = P.Best()
    local best = Best and Best.GetBest and Best.GetBest(kind)
    if best and best.itemID and not best.isConjured then
        local cls = P.ClassificationForTierCount(kind, best.itemID, best.link)
        total = total + consider(best.itemID, LiveBagCount(inv, best.itemID), best.link, cls)
    end

    ForEachUniqueBagStack(inv, function(itemID, n)
        if counted[itemID] then
            return
        end
        total = total + consider(itemID, n)
    end)
    ForEachLiveBagStack(inv, function(itemID, n, link)
        if counted[itemID] then
            return
        end
        total = total + consider(itemID, n, link)
    end)

    if total > 0 then
        P.countCache.kinds[cacheKey] = total
    end
    return total
end

function Tiers.GetSnapshotTierCount(kind)
    return Tiers.GetTierCount(kind, nil)
end

function Tiers.GetTierBagTotalForBankRestock(kind)
    local inv = P.Inv()
    local totals = {}
    local function add(itemID, n)
        itemID = NumericItemID(itemID)
        n = NumericCount(n)
        if not itemID then
            return
        end
        local live = LiveBagCount(inv, itemID)
        n = math.max(n, live)
        if n <= 0 then
            return
        end
        totals[itemID] = math.max(totals[itemID] or 0, n)
    end
    ForEachUniqueBagStack(inv, add)
    local Best = P.Best()
    local known = {}
    if Best then
        local rec = Best.GetBest and Best.GetBest(kind)
        if rec and rec.itemID then
            local id = NumericItemID(rec.itemID)
            if id then
                known[id] = true
                add(id, 0)
            end
        end
        local owned = Best.GetBestOwned and Best.GetBestOwned(kind)
        if owned and owned.itemID then
            local id = NumericItemID(owned.itemID)
            if id then
                known[id] = true
                add(id, 0)
            end
        end
        local ref = Best.GetBestRef and Best.GetBestRef(kind)
        if ref and ref.itemID then
            local id = NumericItemID(ref.itemID)
            if id then
                known[id] = true
                add(id, 0)
            end
        end
    end
    local S = _G.FluxRestockSettings
    local settings = S and S.Get and S.Get()
    if settings and type(settings.restockItems) == "table" then
        for itemID in pairs(settings.restockItems) do
            add(itemID, 0)
        end
    end
    local counted = {}
    local total = 0
    local function credit(itemID, n)
        itemID = NumericItemID(itemID)
        n = NumericCount(n)
        if not itemID or n <= 0 or counted[itemID] then
            return
        end
        counted[itemID] = true
        total = total + n
    end
    for itemID, n in pairs(totals) do
        if known[itemID] or Tiers.ItemMatchesRestockKind(kind, itemID) then
            credit(itemID, n)
        end
    end
    if total <= 0 then
        ForEachLiveBagStack(inv, function(itemID, n)
            if n > 0 and (known[itemID] or Tiers.ItemMatchesRestockKind(kind, itemID)) then
                credit(itemID, n)
            end
        end)
    end
    return total
end

function Tiers.GetBankCountForKind(kind, merchantIndex)
    if not Tiers.IsTierEligible(kind) then
        return 0
    end
    local inv = P.Inv()
    if not inv or not inv.Bank then
        return 0
    end
    local ref = P.GetTierRestockThreshold(kind, merchantIndex)
    local strict, loose = 0, 0
    local function consider(itemID, n, itemLink)
        itemID = tonumber(itemID)
        n = tonumber(n) or 0
        if not itemID or n <= 0 or not P.IsTierItemUsable(kind, itemID) then
            return
        end
        local cls = P.ClassificationForTierCount(kind, itemID, itemLink)
        if P.ItemMatchesTierForBank(kind, cls, ref) then
            strict = strict + n
        elseif P.ItemMatchesTierLooseForBank(kind, cls) then
            loose = loose + n
        end
    end
    -- IDs from last bank walk / SV. Do not ForEachLiveStack here: idle CanRun
    -- used to classify every bank slot and freeze on open.
    local seen = {}
    local char = inv.Bank.GetCharacterCounts and inv.Bank.GetCharacterCounts({ allowCached = true }) or {}
    for itemID in pairs(char) do
        itemID = tonumber(itemID)
        if itemID then
            seen[itemID] = true
        end
    end
    if inv.Bank.GetWarbandCounts then
        local war = inv.Bank.GetWarbandCounts({ allowCached = true }) or {}
        for itemID in pairs(war) do
            itemID = tonumber(itemID)
            if itemID then
                seen[itemID] = true
            end
        end
    end
    for itemID in pairs(seen) do
        consider(itemID, inv.Bank.GetCount(itemID, { bank = true, warband = true }) or 0)
    end
    if strict > 0 then
        return strict + loose
    end
    return loose
end

function Tiers.GetCachedTooltipReferenceTier(kind)
    return Tiers.GetEffectiveReferenceTier(kind)
end

function Tiers.GetTooltipDisplay(kind)
    return {
        count = Tiers.GetTierCount(kind),
        target = Tiers.GetTarget(kind),
        reference = Tiers.GetEffectiveReferenceTier(kind),
    }
end

function Tiers.KindsTouchedByItemID(itemID)
    local cls = P.ClassifyItem(itemID)
    if cls and cls.kind then
        return { [cls.kind] = true }
    end
    return {}
end

_G.FluxRestockTiers = Tiers
return Tiers
