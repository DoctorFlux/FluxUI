--[[
    Restock/Core/Tiers/FluxRestockTiers_Settings.lua
]]

local Tiers = FluxRestockTiers
local P = Tiers._Private

function Tiers.GetTarget(kind)
    local store, fields = P.KindStore(kind)
    if not store then
        return 0
    end
    return tonumber(store[fields.target]) or 0
end

function Tiers.SetTarget(kind, quantity, skipNotify)
    local store, fields = P.KindStore(kind)
    if not store then
        return
    end
    local prev = tonumber(store[fields.target]) or 0
    local nextVal = math.max(0, math.min(9999, tonumber(quantity) or 0))
    store[fields.target] = nextVal
    if prev ~= nextVal and Tiers.InvalidateTooltipDisplayCache then
        Tiers.InvalidateTooltipDisplayCache(kind)
    end
    if not skipNotify and FluxVendorAuto and FluxVendorAuto.NotifyVendorSettingsChanged then
        FluxVendorAuto.NotifyVendorSettingsChanged()
    end
    if Tiers.RequestRecompute then
        Tiers.RequestRecompute({ force = true, scope = "structure", notify = true })
    end
end

function Tiers.GetCountBankFlag(kind)
    local store, fields = P.KindStore(kind)
    if not store then
        return false
    end
    return store[fields.countBank] == true
end

function Tiers.SetCountBankFlag(kind, on, skipNotify)
    local store, fields = P.KindStore(kind)
    if not store then
        return
    end
    store[fields.countBank] = on and true or nil
    if not skipNotify and FluxVendorAuto and FluxVendorAuto.NotifyVendorSettingsChanged then
        FluxVendorAuto.NotifyVendorSettingsChanged()
    end
end

function Tiers.IsMarkInferiorEnabled(kind)
    local store, fields = P.KindStore(kind)
    if not store then
        return false
    end
    return store[fields.mark] ~= false
end

function Tiers.SetMarkInferiorEnabled(kind, enabled)
    local store, fields = P.KindStore(kind)
    if not store then
        return
    end
    store[fields.mark] = enabled and true or false
    Tiers.RequestRecompute({ force = true })
end

function Tiers.IsTierEligible(kind)
    if not P.KIND_FIELDS[kind] then
        return false
    end
    local Best = P.Best()
    if Best and Best.IsManaKindRelevant then
        return Best.IsManaKindRelevant(kind)
    end
    if kind == "water" or kind == "manaPotion" then
        local api = _G.FluxAPICompat
        if api and api.GetPlayerHasMana then
            return api.GetPlayerHasMana() == true
        end
    end
    return true
end

function Tiers.NeedsTierRestockTargets()
    for _, kind in ipairs(P.KINDS) do
        if Tiers.IsTierEligible(kind) and Tiers.GetTarget(kind) > 0 then
            return true
        end
    end
    return false
end

function Tiers.EnsureStores()
    local s = P.Settings()
    if type(s.restockFoodWater) ~= "table" then
        s.restockFoodWater = {}
    end
    local fw = s.restockFoodWater
    if fw.foodTarget == nil then fw.foodTarget = 0 end
    if fw.waterTarget == nil then fw.waterTarget = 0 end
    if fw.markInferiorFood == nil then fw.markInferiorFood = true end
    if fw.markInferiorWater == nil then fw.markInferiorWater = true end

    if type(s.restockCombat) ~= "table" then
        s.restockCombat = {}
    end
    local c = s.restockCombat
    if c.bandageTarget == nil then c.bandageTarget = 0 end
    if c.healPotionTarget == nil then c.healPotionTarget = 0 end
    if c.manaPotionTarget == nil then c.manaPotionTarget = 0 end
    if c.markInferiorBandage == nil then c.markInferiorBandage = true end
    if c.markInferiorHealPotion == nil then c.markInferiorHealPotion = true end
    if c.markInferiorManaPotion == nil then c.markInferiorManaPotion = true end

    local jf = s.junkFilters
    if type(jf) ~= "table" then
        jf = {}
        s.junkFilters = jf
    end
    if jf.conjureInferiorFoodWater == nil then
        jf.conjureInferiorFoodWater = true
    end
    if type(s.pendingVendorTierSell) ~= "table" then
        s.pendingVendorTierSell = { kinds = {} }
    end
    s.pendingVendorTierSell.kinds = s.pendingVendorTierSell.kinds or {}
end

_G.FluxRestockTiers = Tiers
return Tiers
