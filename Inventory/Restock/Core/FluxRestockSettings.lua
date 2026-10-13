--[[
    Restock/Core/FluxRestockSettings.lua

    Fresh per-character settings store for the rewritten junk/restock system:
    _FluxUI_CharSavedVars.Restock. Field names intentionally match the old
    VendorAuto schema so the options tab and merchant UI read/write unchanged.

    Also defines the FluxVendorAuto global TABLE early (files loaded later
    attach their functions to it; UI files capture the table at file scope).

    The old stores (_FluxUI_CharSavedVars.VendorAuto / bankSnapshot and the
    account-wide FluxRestockDB) are deleted on load - deliberate fresh start.
]]

FluxRestockSettings = FluxRestockSettings or {}
local S = FluxRestockSettings

-- Base global tables for the new engine; later files attach functions.
FluxVendorAuto = FluxVendorAuto or {}

local function ApplyDefaults(t)
    t.autoRepair = (t.autoRepair == true)
    t.autoRestock = (t.autoRestock == true)
    t.autoSellGray = (t.autoSellGray == true)
    t.autoBankRestock = (t.autoBankRestock == true)
    t.repairPriority = t.repairPriority or "personal"
    t.restockItems = t.restockItems or {}
    if t.restockShowNotSold == nil then t.restockShowNotSold = false end

    -- Consumable-tier restock stores (food/water/bandage/potion).
    if type(t.restockFoodWater) ~= "table" then
        t.restockFoodWater = {}
    end
    local fw = t.restockFoodWater
    if fw.foodTarget == nil then fw.foodTarget = 0 end
    if fw.waterTarget == nil then fw.waterTarget = 0 end
    if fw.markInferiorFood == nil then fw.markInferiorFood = true end
    if fw.markInferiorWater == nil then fw.markInferiorWater = true end

    if type(t.restockCombat) ~= "table" then
        t.restockCombat = {}
    end
    local rc = t.restockCombat
    if rc.bandageTarget == nil then rc.bandageTarget = 0 end
    if rc.healPotionTarget == nil then rc.healPotionTarget = 0 end
    if rc.manaPotionTarget == nil then rc.manaPotionTarget = 0 end
    if rc.markInferiorBandage == nil then rc.markInferiorBandage = true end
    if rc.markInferiorHealPotion == nil then rc.markInferiorHealPotion = true end
    if rc.markInferiorManaPotion == nil then rc.markInferiorManaPotion = true end

    if type(t.pendingVendorTierSell) ~= "table" then
        t.pendingVendorTierSell = { kinds = {} }
    end
    t.pendingVendorTierSell.kinds = t.pendingVendorTierSell.kinds or {}

    t.junkList = t.junkList or {}
    t.junkFilters = t.junkFilters or {}
    local jf = t.junkFilters
    if jf.consumable == nil then jf.consumable = true end
    if jf.unusable == nil then jf.unusable = true end
    if jf.destroy == nil then jf.destroy = true end
    if jf.safe == nil then jf.safe = true end
    jf.consumableLvl = tonumber(jf.consumableLvl) or 0.15
    if jf.conjureInferiorFoodWater == nil then jf.conjureInferiorFoodWater = true end

    t.junkDisplay = t.junkDisplay or {}
    if t.junkDisplay.glow == nil then t.junkDisplay.glow = true end
    if t.junkDisplay.icons == nil then t.junkDisplay.icons = true end

    t.alreadyKnown = t.alreadyKnown or {}
    local ak = t.alreadyKnown
    if ak.enabled == nil then ak.enabled = true end
    if ak.r == nil then ak.r = 0 end
    if ak.g == nil then ak.g = 1 end
    if ak.b == nil then ak.b = 0 end
    if ak.monochrome == nil then ak.monochrome = false end
    if ak.debug == nil then ak.debug = false end
    if ak.exclude == nil then ak.exclude = false end

    return t
end

--- The per-character Restock settings table (defaults applied). Never cache
--- the returned table across loading screens; re-fetch per use.
function S.Get()
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    local t = _FluxUI_CharSavedVars.Restock
    if not t then
        t = {}
        _FluxUI_CharSavedVars.Restock = t
    end
    if not t._defaultsApplied then
        ApplyDefaults(t)
        t._defaultsApplied = true
    end
    return t
end

local function DropLegacyStores()
    if _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars.VendorAuto = nil
        _FluxUI_CharSavedVars.bankSnapshot = nil
        _FluxUI_CharSavedVars.bankSnapshotTime = nil
        -- The bank snapshot moved out of Restock into its own FluxBank-owned
        -- table (_FluxUI_CharSavedVars.Bank) as part of the bank rewrite.
        local restock = _FluxUI_CharSavedVars.Restock
        if restock then
            restock.bankSnapshot = nil
            restock.bankSnapshotTime = nil
        end
    end
    -- Account-wide legacy store (mage rune targets / vendor prices).
    _G.FluxRestockDB = nil
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= "_FluxUI" then return end
    self:UnregisterEvent("ADDON_LOADED")
    DropLegacyStores()
    local t = _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.Restock
    if t then
        t._defaultsApplied = nil
    end
    S.Get()
end)

-- FluxVendorAuto settings surface (options tab + merchant UI contract).
function FluxVendorAuto.EnsureSettings()
    return S.Get()
end

function FluxVendorAuto.GetSettings()
    return S.Get()
end

_G.FluxRestockSettings = S
return S

