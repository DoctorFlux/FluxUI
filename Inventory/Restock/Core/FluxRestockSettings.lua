--[[
    Restock/Core/FluxRestockSettings.lua

    Fresh per-character settings store for the rewritten junk/restock system:
    _FluxUI_CharSavedVars.Restock. Field names intentionally match the old
    VendorAuto schema so the options tab and merchant UI read/write unchanged.

    Also defines the FluxVendorAuto global TABLE early (files loaded later
    attach their functions to it; UI files capture the table at file scope).

    Legacy stores remain available for recovery and compatibility consumers.
    A versioned migration imports validated preferences only when no current
    Restock store exists; it never merges stale legacy values over current data.
]]

FluxRestockSettings = FluxRestockSettings or {}
local S = FluxRestockSettings

-- Base global tables for the new engine; later files attach functions.
FluxVendorAuto = FluxVendorAuto or {}

local function Copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, entry in pairs(value) do
        result[Copy(key, seen)] = Copy(entry, seen)
    end
    return result
end

local function IsNumber(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge and value >= 0
end

local function CopyFields(source, schema)
    local result = {}
    if type(source) ~= "table" then return result end
    for key, kind in pairs(schema) do
        local value = source[key]
        if (kind == "boolean" and type(value) == "boolean")
            or (kind == "number" and IsNumber(value)) then
            result[key] = value
        end
    end
    return result
end

local LEGACY_BOOLEANS = {
    autoRepair = "boolean", autoRestock = "boolean", autoSellGray = "boolean",
    autoBankRestock = "boolean", restockShowNotSold = "boolean",
}
local LEGACY_GROUPS = {
    restockFoodWater = {
        foodTarget = "number", waterTarget = "number",
        markInferiorFood = "boolean", markInferiorWater = "boolean",
    },
    restockCombat = {
        bandageTarget = "number", healPotionTarget = "number", manaPotionTarget = "number",
        markInferiorBandage = "boolean", markInferiorHealPotion = "boolean", markInferiorManaPotion = "boolean",
    },
    junkFilters = {
        consumable = "boolean", unusable = "boolean", destroy = "boolean", safe = "boolean",
        conjureInferiorFoodWater = "boolean", consumableLvl = "number",
    },
    junkDisplay = { glow = "boolean", icons = "boolean" },
    alreadyKnown = {
        enabled = "boolean", monochrome = "boolean", debug = "boolean", exclude = "boolean",
        r = "number", g = "number", b = "number",
    },
}
local RESTOCK_ITEM_FIELDS = {
    targetQuantity = "number", countBank = "boolean", bankRestock = "boolean",
    bankStash = "boolean", dismissed = "boolean",
}

local function ImportLegacySettings(source)
    local result = CopyFields(source, LEGACY_BOOLEANS)
    if source.repairPriority == "personal" or source.repairPriority == "guild" then
        result.repairPriority = source.repairPriority
    end
    for key, schema in pairs(LEGACY_GROUPS) do
        if type(source[key]) == "table" then
            result[key] = CopyFields(source[key], schema)
        end
    end
    result.restockItems = {}
    if type(source.restockItems) == "table" then
        for key, entry in pairs(source.restockItems) do
            local id = tonumber(key)
            if id and IsNumber(id) and id > 0 and id % 1 == 0 and type(entry) == "table" then
                -- Prefer the numeric entry if an old store contains both forms.
                if type(key) == "number" or result.restockItems[id] == nil then
                    result.restockItems[id] = CopyFields(entry, RESTOCK_ITEM_FIELDS)
                end
            end
        end
    end
    result.junkList = {}
    if type(source.junkList) == "table" then
        for key, value in pairs(source.junkList) do
            local id = tonumber(key)
            if id and IsNumber(id) and id > 0 and id % 1 == 0 and type(value) == "boolean" then
                if type(key) == "number" or result.junkList[id] == nil then
                    result.junkList[id] = value
                end
            end
        end
    end
    -- Bank snapshots need a live topology refresh, and pending vendor work must
    -- not be replayed as part of a preferences upgrade. Their originals survive.
    return result
end

local function MigrateLegacyStores()
    local root = _FluxUI_CharSavedVars
    local checkpoint = root._restockMigrationV1
    if type(checkpoint) == "table" and checkpoint.version == 1 then return end

    local current = root.Restock
    local legacy = root.VendorAuto
    local replacement
    if current == nil and type(legacy) == "table" then
        replacement = ImportLegacySettings(legacy)
    elseif current ~= nil and type(current) ~= "table" then
        replacement = {}
    end
    -- Prepare rollback data before publishing anything. VendorAuto and all bank
    -- snapshots stay in place, including fields not understood by this version.
    checkpoint = {
        version = 1,
        imported = current == nil and replacement ~= nil,
        hadRestock = current ~= nil,
    }
    if replacement and current ~= nil then checkpoint.previousRestock = Copy(current) end
    -- FluxRestockDB is no longer TOC-declared. Archive it inside the declared
    -- character root so an old account store also survives a subsequent reload.
    if _G.FluxRestockDB ~= nil then checkpoint.legacyAccount = Copy(_G.FluxRestockDB) end
    if replacement then root.Restock = replacement end
    root._restockMigrationV1 = checkpoint
end

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
    MigrateLegacyStores()
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

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= "_FluxUI" then return end
    self:UnregisterEvent("ADDON_LOADED")
    local t = _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.Restock
    if type(t) == "table" then
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

