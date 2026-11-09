--[[
    Restock/Core/Tiers/FluxRestockTiers_Init.lua

    Slim tier restock engine on FluxConsumableBest: kinds, labels, SV field map.
]]

FluxRestockTiers = FluxRestockTiers or {}
local Tiers = FluxRestockTiers
Tiers._Private = Tiers._Private or {}
local P = Tiers._Private

P.KINDS = { "food", "water", "bandage", "healPotion", "manaPotion" }
P.COMBAT_KINDS = { bandage = true, healPotion = true, manaPotion = true }
P.FOOD_WATER_KINDS = { food = true, water = true }
P.KIND_LABEL = {
    food = "Food",
    water = "Water",
    bandage = "Bandage",
    healPotion = "Healing potion",
    manaPotion = "Mana potion",
}
P.TIER_ICON = {
    food = "Interface\\Icons\\INV_Misc_Fork&Knife",
    water = "Interface\\Icons\\INV_Drink_07",
    bandage = "Interface\\Icons\\INV_Misc_Bandage_01",
    healPotion = "Interface\\Icons\\INV_Potion_54",
    manaPotion = "Interface\\Icons\\INV_Potion_76",
}

P.KIND_FIELDS = {
    food = {
        store = "restockFoodWater", target = "foodTarget", countBank = "foodCountBank",
        mark = "markInferiorFood", saved = "savedFoodTier",
    },
    water = {
        store = "restockFoodWater", target = "waterTarget", countBank = "waterCountBank",
        mark = "markInferiorWater", saved = "savedWaterTier",
    },
    bandage = {
        store = "restockCombat", target = "bandageTarget", countBank = "bandageCountBank",
        mark = "markInferiorBandage", saved = "savedBandageTier",
    },
    healPotion = {
        store = "restockCombat", target = "healPotionTarget", countBank = "healPotionCountBank",
        mark = "markInferiorHealPotion", saved = "savedHealPotionTier",
    },
    manaPotion = {
        store = "restockCombat", target = "manaPotionTarget", countBank = "manaPotionCountBank",
        mark = "markInferiorManaPotion", saved = "savedManaPotionTier",
    },
}

function Tiers.GetTierIcon(kind)
    return P.TIER_ICON[kind]
end

function Tiers.GetKindLabel(kind)
    return P.KIND_LABEL[kind] or kind
end

function P.Settings()
    return FluxRestockSettings and FluxRestockSettings.Get and FluxRestockSettings.Get() or {}
end

function P.KindStore(kind)
    local fields = P.KIND_FIELDS[kind]
    if not fields then
        return nil, nil
    end
    local s = P.Settings()
    local store = s[fields.store]
    if type(store) ~= "table" then
        store = {}
        s[fields.store] = store
    end
    return store, fields
end

function P.RoundTier(v)
    v = tonumber(v)
    if not v or v <= 0 then
        return 0
    end
    return math.floor(v + 0.5)
end
Tiers.RoundTier = P.RoundTier

function P.After(delay, fn)
    if FluxAPICompat and FluxAPICompat.After then
        FluxAPICompat.After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

function P.Inv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

function P.IC()
    return _G.FluxItemClass
end

function P.Best()
    return _G.FluxConsumableBest
end

function P.ClassifyMod()
    return _G.FluxConsumableClassify
end

function P.FJ()
    return _G.FluxVendorJunk or _G.FluxJunk
end

function P.GetSavedTier(kind)
    local store, fields = P.KindStore(kind)
    if not store then
        return 0
    end
    return tonumber(store[fields.saved]) or 0
end

function P.SetSavedTier(kind, value)
    local store, fields = P.KindStore(kind)
    if not store then
        return
    end
    store[fields.saved] = P.RoundTier(value)
end

-- Lightweight caches
P.countCache = { bagGen = -1, merchantGen = -1, kinds = {} }
P.tierRefCache = { bagGen = -1, merchantGen = -1, effective = {}, inferior = {} }
P.bankCountCache = { bagGen = -1, merchantGen = -1, kinds = {} }
P.vendorStatusCache = { bagGen = -1, merchantGen = -1, kinds = {} }
P.pendingVendorUpgrade = { kinds = {} }
P.tierCountPending = {}
P.recomputePending = false
P.vendorInferiorSnapshot = { bagGen = nil, merchantGen = nil }
P.vendorTierRefresh = { pending = false, gen = 0, attempts = 0 }
P.VENDOR_TIER_REFRESH_MAX = 24
P.merchantWarmItemIDs = {}
P.merchantWarmIndex = nil
P.merchantWarmSnapshotGen = nil
P.merchantWarmChunkGen = 0

function P.GetBagCacheGen()
    local inv = P.Inv()
    if inv and inv.Bags and inv.Bags.GetGeneration then
        return inv.Bags.GetGeneration() or 0
    end
    return 0
end

function P.GetMerchantCacheGen()
    local FV = _G.FluxVendorBuy or _G.FluxVendorAuto
    if FV and FV.GetMerchantIndexGeneration then
        return FV.GetMerchantIndexGeneration() or 0
    end
    return 0
end

function P.IsMerchantFrameOpen()
    return MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown()
end

function Tiers.InvalidateTierQueryCache()
    P.countCache.bagGen = -1
    P.bankCountCache.bagGen = -1
    P.vendorStatusCache.bagGen = -1
    wipe(P.countCache.kinds)
    wipe(P.bankCountCache.kinds)
    wipe(P.vendorStatusCache.kinds)
    if P.tierRefCache then
        P.tierRefCache.bagGen = -1
        P.tierRefCache.merchantGen = -1
        wipe(P.tierRefCache.effective)
        wipe(P.tierRefCache.inferior)
    end
end

function Tiers.InvalidateTooltipDisplayCache(kind)
    if kind then
        P.tierCountPending[kind] = nil
    else
        wipe(P.tierCountPending)
    end
    Tiers.InvalidateTierQueryCache()
end

function Tiers.IsTierCountPending(kind)
    return P.tierCountPending[kind] == true
end

function Tiers.FlushTierCountRefresh()
    -- no-op placeholder; counts are sync via FluxInv
end

function Tiers.CancelPendingRecompute()
    P.recomputePending = false
end

function Tiers.CancelBackgroundWork()
    P.recomputePending = false
    P.vendorTierRefresh.gen = (P.vendorTierRefresh.gen or 0) + 1
    P.vendorTierRefresh.pending = false
    P.vendorTierRefresh.attempts = 0
    P.merchantWarmSnapshotGen = nil
    if Tiers.CancelInferiorPass then
        Tiers.CancelInferiorPass()
    end
end

_G.FluxRestockTiers = Tiers
return Tiers
