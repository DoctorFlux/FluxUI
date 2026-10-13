--[[
    Restock/Core/FluxRestockList.lua

    The unified restock target list. Sources ("providers"):
      * manual items        settings.restockItems[itemID].targetQuantity
      * consumable presets  FluxNCConsumables preset restock targets (soft-guarded)
      * spell reagents      FluxInv.Spells (spell book reagent map)

    Provides the FluxVendorAuto restock API surface used by the options tab,
    the merchant UI, and the panels, plus:
      * FluxRestockItemRegistry (bank-restock provider registry + charge info)
      * FluxRestock (spell-reagent compat: reagent map, tooltip append, prices)
]]

FluxRestockList = FluxRestockList or {}
local List = FluxRestockList
local FV = FluxVendorAuto

local function Inv() return _G.FluxRestock and _G.FluxRestock.Inv end
local function Bank()
    local inv = Inv()
    return inv and inv.Bank
end
local function IC() return _G.FluxItemClass end
local function Settings() return FluxRestockSettings.Get() end

-- ---------------------------------------------------------------------------
-- MANUAL RESTOCK ITEMS
-- ---------------------------------------------------------------------------

function FV.AddRestockItem(itemID, quantity, skipNotify)
    itemID = tonumber(itemID)
    if not itemID then return end
    local s = Settings()
    local entry = s.restockItems[itemID]
    if type(entry) ~= "table" then
        entry = {}
        s.restockItems[itemID] = entry
    end
    entry.targetQuantity = math.max(0, math.min(999, tonumber(quantity) or 1))
    entry.dismissed = nil
    if IC() then IC().RequestLoad(itemID) end
    if FV.InvalidateRestockOptionsPanelCache then
        FV.InvalidateRestockOptionsPanelCache()
    end
    local FJ = _G.FluxJunk
    if FJ and FJ.OnManualRestockChanged then
        FJ.OnManualRestockChanged(itemID)
    end
    if not skipNotify then
        FV.NotifyVendorSettingsChanged()
    end
end

function FV.RemoveRestockItem(itemID, skipNotify)
    itemID = tonumber(itemID)
    if not itemID then return end
    Settings().restockItems[itemID] = nil
    if FV.InvalidateRestockOptionsPanelCache then
        FV.InvalidateRestockOptionsPanelCache()
    end
    local FJ = _G.FluxJunk
    if FJ and FJ.OnManualRestockChanged then
        FJ.OnManualRestockChanged(itemID)
    end
    if not skipNotify then
        FV.NotifyVendorSettingsChanged()
    end
end

function FV.SetRestockTarget(itemID, quantity, skipNotify)
    itemID = tonumber(itemID)
    if not itemID then return end
    quantity = math.max(0, math.min(999, tonumber(quantity) or 0))
    local s = Settings()
    local entry = s.restockItems[itemID]
    if type(entry) ~= "table" then
        if quantity <= 0 then return end
        entry = {}
        s.restockItems[itemID] = entry
    end
    entry.targetQuantity = quantity
    if quantity > 0 then
        entry.dismissed = nil
    end
    local FJ = _G.FluxJunk
    if FJ and FJ.OnManualRestockChanged then
        FJ.OnManualRestockChanged(itemID)
    end
    if not skipNotify then
        FV.NotifyVendorSettingsChanged()
    end
end

function FV.GetRestockTargetForItem(itemID)
    itemID = tonumber(itemID)
    local entry = itemID and Settings().restockItems[itemID]
    return (entry and tonumber(entry.targetQuantity)) or 0
end

function FV.GetRestockItemFlags(itemID)
    itemID = tonumber(itemID)
    local entry = itemID and Settings().restockItems[itemID]
    if type(entry) ~= "table" then
        return {}
    end
    return {
        countBank = entry.countBank == true,
        bankRestock = entry.bankRestock == true,
        dismissed = entry.dismissed == true,
    }
end

function FV.SetRestockItemFlag(itemID, flag, value, skipNotify)
    itemID = tonumber(itemID)
    if not itemID or type(flag) ~= "string" then return end
    local s = Settings()
    local entry = s.restockItems[itemID]
    if type(entry) ~= "table" then
        entry = { targetQuantity = 0 }
        s.restockItems[itemID] = entry
    end
    entry[flag] = value and true or nil
    -- Drop empty flag-only shells so they cannot resurface as Manual @ 0.
    if (tonumber(entry.targetQuantity) or 0) <= 0
        and not entry.countBank and not entry.bankRestock and not entry.bankStash
        and not entry.dismissed then
        s.restockItems[itemID] = nil
    end
    if not skipNotify then
        FV.NotifyVendorSettingsChanged()
    end
end

function FV.DismissRestockReagent(itemID, skipNotify)
    itemID = tonumber(itemID)
    if not itemID then return end
    local s = Settings()
    local entry = s.restockItems[itemID]
    if type(entry) ~= "table" then
        entry = { targetQuantity = 0 }
        s.restockItems[itemID] = entry
    end
    entry.dismissed = true
    entry.targetQuantity = 0
    if not skipNotify then
        FV.NotifyVendorSettingsChanged()
    end
end

function FV.GetRestockShowNotSold()
    return Settings().restockShowNotSold == true
end

function FV.SetRestockShowNotSold(value)
    Settings().restockShowNotSold = value and true or false
    FV.NotifyVendorSettingsChanged()
end

-- ---------------------------------------------------------------------------
-- TIER RESTOCK FACADE (FluxRestockTiers on FluxConsumableBest)
-- ---------------------------------------------------------------------------

local TIER_KINDS = { "food", "water", "bandage", "healPotion", "manaPotion" }
local TIER_LABEL = {
    food = "Food",
    water = "Water",
    bandage = "Bandage",
    healPotion = "Healing potion",
    manaPotion = "Mana potion",
}

local function Tiers()
    return _G.FluxRestockTiers
end

local function GetTierIcon(kind)
    local T = Tiers()
    if T and T.GetTierIcon then
        return T.GetTierIcon(kind)
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function IsCombatTierKind(kind)
    return kind == "bandage" or kind == "healPotion" or kind == "manaPotion"
end

function FV.SetRestockFoodWaterTarget(kind, quantity, skipNotify)
    local T = Tiers()
    if T and T.SetTarget and (kind == "food" or kind == "water") then
        T.SetTarget(kind, quantity, skipNotify)
    end
end

function FV.SetRestockCombatTarget(kind, quantity, skipNotify)
    local T = Tiers()
    if T and T.SetTarget and IsCombatTierKind(kind) then
        T.SetTarget(kind, quantity, skipNotify)
    end
end

function FV.GetTierCountBankFlag(kind)
    local T = Tiers()
    return T and T.GetCountBankFlag and T.GetCountBankFlag(kind) or false
end

function FV.SetTierCountBankFlag(kind, on, skipNotify)
    local T = Tiers()
    if T and T.SetCountBankFlag then
        T.SetCountBankFlag(kind, on, skipNotify)
    end
end

function FV.ResetTierReference(kind, skipNotify)
    local T = Tiers()
    if T and T.ResetTierReference then
        T.ResetTierReference(kind, skipNotify)
    end
end

local function BuildTierEntry(kind, merchantIndex, opts)
    local T = Tiers()
    if not T then
        return nil
    end
    if T.IsTierEligible and not T.IsTierEligible(kind) then
        return nil
    end
    local target = T.GetTarget(kind) or 0
    if target <= 0 and not (opts and (opts.forOptionsPanel or opts.merchantAware)) then
        return nil
    end
    -- Options always show eligible kinds (even target 0).
    if opts and opts.forOptionsPanel and target < 0 then
        return nil
    end
    local countBank = T.GetCountBankFlag and T.GetCountBankFlag(kind) or false
    local bagCount = T.GetTierCount and T.GetTierCount(kind, merchantIndex) or 0
    local bankCount = T.GetBankCountForKind and T.GetBankCountForKind(kind, merchantIndex) or 0
    local entry = {
        isTierRestock = true,
        tierKind = kind,
        isCombatRestock = IsCombatTierKind(kind),
        name = (T.GetKindLabel and T.GetKindLabel(kind)) or TIER_LABEL[kind] or kind,
        texture = GetTierIcon(kind),
        target = target,
        bagCount = bagCount,
        countBank = countBank,
        bankCount = bankCount,
        restockSource = "tier",
    }
    if merchantIndex then
        local status = T.GetVendorTierStatus and T.GetVendorTierStatus(kind, merchantIndex) or {}
        entry.merchantChecked = true
        entry.vendorHasStock = status.hasStock == true
        entry.vendorLowerTierOnly = status.lowerTierOnly == true
        entry.vendorNotSold = not status.hasStock and not status.lowerTierOnly
        -- Only at-threshold (or better) stock is buyable; never restock lower tiers.
        if status.hasStock then
            entry.merchantSlot = status.bestSlot
            entry.merchantItemID = status.bestItemID
            entry.unitPrice = status.bestPrice
        end
    end
    return entry
end

-- ---------------------------------------------------------------------------
-- SPELL REAGENTS (SoT: FluxInv.Spells tooltip scan — no hardcoded reagent table)
-- ---------------------------------------------------------------------------

local function Spells()
    local inv = Inv()
    return inv and inv.Spells
end

local function IsBlacklistedReagentID(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return true
    end
    local S = Spells()
    if S and S.IsBlacklistedReagent then
        return S.IsBlacklistedReagent(itemId) == true
    end
    return false
end

--- Pull spell-book reagent itemIDs from FluxInv (SoT).
local function GetPlayerReagentItemIDs(opts)
    opts = type(opts) == "table" and opts or {}
    local reagentIDs = {}
    local S = Spells()
    if S then
        -- Refresh so options / merchant see the current spell book.
        if S.Refresh then
            S.Refresh()
        elseif S.ScheduleWarm then
            S.ScheduleWarm()
        end
        -- Merchant / bags may have just taught us name→ID for Classic tooltips.
        if S.OnVisibleItemsChanged then
            S.OnVisibleItemsChanged()
        end
        local set = (S.GetReagentItemIDSet and S.GetReagentItemIDSet()) or {}
        for id in pairs(set) do
            id = tonumber(id)
            if id and not IsBlacklistedReagentID(id) then
                reagentIDs[id] = true
            end
        end
    end
    return reagentIDs
end

function List.CancelSpellReagentCacheWarm()
end

function List.InvalidateSpellReagentCache()
    local S = Spells()
    if S and S.Invalidate then
        S.Invalidate()
    end
    if FV.InvalidateRestockOptionsPanelCache then
        FV.InvalidateRestockOptionsPanelCache()
    end
    local ui = _G.FluxVendorAutoMerchantUI
    if ui and ui.ScheduleMerchantUpdate and MerchantFrame and MerchantFrame:IsShown() then
        pcall(ui.ScheduleMerchantUpdate, "data")
    end
    if _G.FluxRestockPanel_OnSpellReagentCacheReady then
        pcall(_G.FluxRestockPanel_OnSpellReagentCacheReady)
    elseif (_G.FluxRestockPanel_IsTabVisible and _G.FluxRestockPanel_IsTabVisible()
            or _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive())
        and _G.FluxRestockPanel_RequestRefresh then
        pcall(_G.FluxRestockPanel_RequestRefresh)
    end
end

--- Soft UI refresh after max-rank finalize (does NOT invalidate spell scan — avoids loops).
local function NotifyRestockReagentUI()
    if FV.InvalidateRestockOptionsPanelCache then
        FV.InvalidateRestockOptionsPanelCache()
    end
    local ui = _G.FluxVendorAutoMerchantUI
    if ui and ui.ScheduleMerchantUpdate and MerchantFrame and MerchantFrame:IsShown() then
        pcall(ui.ScheduleMerchantUpdate, "data")
    end
    if _G.FluxRestockPanel_OnSpellReagentCacheReady then
        pcall(_G.FluxRestockPanel_OnSpellReagentCacheReady)
    elseif (_G.FluxRestockPanel_IsTabVisible and _G.FluxRestockPanel_IsTabVisible()
            or _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive())
        and _G.FluxRestockPanel_RequestRefresh then
        pcall(_G.FluxRestockPanel_RequestRefresh)
    end
end

--- Called from FluxInv.Spells.FinalizeActiveReagents when the reagent warm completes.
--- migrations: { { family, maxSpellID, activeIDs = {id,...}, obsoleteIDs = { [id]=true } }, ... }
function List.OnActiveReagentsFinalized(migrations)
    local changed = false
    local FJ = _G.FluxJunk

    if type(migrations) == "table" then
        for i = 1, #migrations do
            local mig = migrations[i]
            if type(mig) == "table" then
                local activeList = mig.activeIDs
                local obsolete = mig.obsoleteIDs
                local singleNew = (type(activeList) == "table" and #activeList == 1) and tonumber(activeList[1]) or nil

                if type(obsolete) == "table" then
                    for oldID in pairs(obsolete) do
                        oldID = tonumber(oldID)
                        if oldID then
                            local protected = FJ and FJ.IsExplicitUseful and FJ.IsExplicitUseful(oldID)
                            local qty = FV.GetRestockTargetForItem(oldID) or 0
                            if qty > 0 then
                                if singleNew then
                                    local newQty = FV.GetRestockTargetForItem(singleNew) or 0
                                    FV.SetRestockTarget(singleNew, math.max(newQty, qty), true)
                                end
                                FV.DismissRestockReagent(oldID, true)
                                changed = true
                            end
                            -- Mark superseded reagent junk unless user protected it.
                            if not protected and FJ and FJ.AddJunk then
                                if not (FJ.IsExplicitJunk and FJ.IsExplicitJunk(oldID)) then
                                    FJ.AddJunk(oldID)
                                    changed = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if changed then
        FV.NotifyVendorSettingsChanged()
    end
    NotifyRestockReagentUI()
end

--- Legacy no-op: reagents are discovered from the spell book, not a static ID table.
function FV.IsStaticSpellReagentItem(itemId)
    return false
end

function FV.IsKnownSpellReagentItem(itemId)
    local n = tonumber(itemId)
    if not n or IsBlacklistedReagentID(n) then return false end
    local S = Spells()
    if S and S.IsReagentItem and S.IsReagentItem(n) then
        return true
    end
    local reagentIDs = GetPlayerReagentItemIDs({})
    return reagentIDs[n] == true
end

function FV.IsSpellReagentItem(itemId)
    return FV.IsKnownSpellReagentItem(itemId)
end

local function GetSpellsUsingReagentItem(itemId)
    local target = tonumber(itemId)
    if not target then return {} end
    local S = Spells()
    if S and S.GetSpellsUsingReagentLabeled then
        return S.GetSpellsUsingReagentLabeled(target) or {}
    end
    return {}
end

local function AppendSpellsUsingReagentToTooltip(tooltip, itemId)
    if not tooltip or not itemId then return end
    local rows = GetSpellsUsingReagentItem(itemId)
    if #rows == 0 then return end
    tooltip:AddLine(" ")
    tooltip:AddLine("Used by:", 1, 0.82, 0.35)
    local n = math.min(#rows, 28)
    for i = 1, n do
        local row = rows[i]
        local tex
        if C_Spell and C_Spell.GetSpellTexture then
            tex = C_Spell.GetSpellTexture(row.spellID)
        elseif GetSpellTexture then
            tex = GetSpellTexture(row.spellID)
        end
        local iconTag = tex and string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t ", tostring(tex)) or ""
        -- label already includes Rank N from Spells.GetSpellsUsingReagentLabeled
        tooltip:AddLine("  " .. iconTag .. (row.label or ("Spell " .. tostring(row.spellID))), 0.88, 0.9, 0.95, true)
    end
    if #rows > n then
        tooltip:AddLine(("  |cff888888(+%d more)|r"):format(#rows - n), 0.6, 0.6, 0.6, true)
    end
end

-- ---------------------------------------------------------------------------
-- VENDOR PRICES (per character, fresh store)
-- ---------------------------------------------------------------------------

local function GetPriceStore()
    local s = Settings()
    s.itemPrices = s.itemPrices or {}
    return s.itemPrices
end

--- Record unit prices from a built merchant index (FluxVendorBuy calls this).
function List.RecordMerchantPrices(merchantIndex)
    if type(merchantIndex) ~= "table" then return end
    local prices = GetPriceStore()
    for itemID, meta in pairs(merchantIndex) do
        if meta.unitPrice and meta.unitPrice > 0 then
            prices[itemID] = meta.unitPrice
        end
    end
end

function List.GetItemUnitPrice(itemID)
    itemID = tonumber(itemID)
    if not itemID then return 0 end
    if MerchantFrame and MerchantFrame:IsShown() and FV.GetMerchantItemIndex then
        local index = FV.GetMerchantItemIndex(false)
        local meta = index and index[itemID]
        if meta and meta.unitPrice and meta.unitPrice > 0 then
            GetPriceStore()[itemID] = meta.unitPrice
            return meta.unitPrice
        end
    end
    local saved = GetPriceStore()[itemID]
    if saved and saved > 0 then
        return saved
    end
    return 0
end

-- Compat APIs for FluxSpellbookReagent / TeleportPortal tooltips.
-- Merge onto the existing FluxRestock table. FluxRestock_Inv.lua already
-- attached .Inv (live bank walk / UseContainerItem). Replacing the table
-- drops Inv and bank restock cannot find bag:slot.
FluxRestock = _G.FluxRestock or FluxRestock or {}
FluxRestock.GetItemUnitPrice = List.GetItemUnitPrice
FluxRestock.GetTargetQuantity = function(itemID) return FV.GetRestockTargetForItem(itemID) end
FluxRestock.SetTargetQuantity = function(itemID, qty) FV.SetRestockTarget(itemID, qty) end
FluxRestock.GetRestockCost = function(itemID)
    local target = FV.GetRestockTargetForItem(itemID)
    if target <= 0 then return 0 end
    local inv = Inv()
    local have = 0
    if inv then
        if inv.GetLiveCount then
            have = tonumber(inv.GetLiveCount(itemID, { bags = true, bank = false, warband = false })) or 0
        end
        if have <= 0 and inv.GetCount then
            have = inv.GetCount(itemID) or 0
        end
    end
    local needed = math.max(0, target - have)
    return needed * List.GetItemUnitPrice(itemID)
end
FluxRestock.IsKnownSpellReagentItem = function(itemID) return FV.IsKnownSpellReagentItem(itemID) end
FluxRestock.IsStaticSpellReagentItem = function(itemID) return FV.IsStaticSpellReagentItem(itemID) end
FluxRestock.IsSpellReagentItem = function(itemID) return FV.IsSpellReagentItem(itemID) end
FluxRestock.InvalidateSpellReagentCache = function() List.InvalidateSpellReagentCache() end
FluxRestock.GetSpellsUsingReagentItem = GetSpellsUsingReagentItem
FluxRestock.AppendSpellsUsingReagentToTooltip = AppendSpellsUsingReagentToTooltip
_G.FluxRestock = FluxRestock

-- ---------------------------------------------------------------------------
-- TARGET LIST (options panel + merchant restock button + panels)
-- ---------------------------------------------------------------------------

local function GetItemNameIcon(itemID)
    local ic = IC()
    if not ic then
        return "Item " .. tostring(itemID), "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    local name = ic.GetName(itemID)
    return name or ("Item " .. tostring(itemID)), ic.GetIcon(itemID)
end

local function CoerceCount(value)
    local n = tonumber(value)
    if n then
        return n
    end
    local Secrets = _G.Flux and _G.Flux.Secrets
    if Secrets and Secrets.SafeGetNumber then
        return Secrets.SafeGetNumber(value, 0)
    end
    return 0
end

local function GetBagCountFor(itemID, isCharge)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local opts = {
        charges = isCharge and true or false,
        bags = true,
        bank = false,
        warband = false,
        equipped = false,
    }
    local inv = Inv()
    local n = 0
    if inv then
        if inv.GetLiveCount then
            n = CoerceCount(inv.GetLiveCount(itemID, opts))
        end
        if n <= 0 and inv.GetCount then
            n = CoerceCount(inv.GetCount(itemID, opts))
        end
    end
    if n <= 0 and C_Item and C_Item.GetItemCount then
        local ok, raw = pcall(C_Item.GetItemCount, itemID, false, isCharge and true or false, false, false)
        if ok then
            n = CoerceCount(raw)
        end
    end
    return n
end

local function IsChargeRestockItem(itemID)
    local Registry = _G.FluxRestockItemRegistry
    if Registry and Registry.IsChargeItem and Registry.IsChargeItem(itemID) then
        return true
    end
    local Cons = _G.FluxNCConsumables
    return Cons and Cons.IsWeaponEnchantItem and Cons.IsWeaponEnchantItem(itemID) or false
end

local function EnrichItemEntryBankCounts(entry)
    if not entry or not entry.itemID or entry.isTierRestock then
        return
    end
    local flags = FV.GetRestockItemFlags(entry.itemID)
    entry.countBank = flags.countBank == true
    local Cons = _G.FluxNCConsumables
    local bank = Bank()
    if entry.isChronoboon and Cons and Cons.GetChronoboonBankCount then
        entry.bankCount = Cons.GetChronoboonBankCount()
    elseif IsChargeRestockItem(entry.itemID) and bank then
        entry.bankCount = bank.GetCount(entry.itemID, { charges = true })
    elseif bank then
        entry.bankCount = bank.GetCount(entry.itemID)
    else
        entry.bankCount = 0
    end
end


local function ApplyMerchantAvailability(entry, merchantIndex)
    if not merchantIndex then return end
    entry.merchantChecked = true
    local meta = merchantIndex[entry.itemID]
    if meta then
        entry.vendorSold = true
        entry.vendorNotSold = false
        entry.unitPrice = meta.unitPrice
        entry.merchantSlot = meta.slot
    else
        entry.vendorSold = false
        entry.vendorNotSold = true
    end
end

local function ShouldShowInRestockUI(opts, target)
    opts = type(opts) == "table" and opts or {}
    if opts.forOptionsPanel or opts.merchantAware then
        return true
    end
    if (tonumber(target) or 0) > 0 then
        return true
    end
    return false
end


--- The full target list. opts = { merchantAware, forOptionsPanel }.
--- Entry kinds:
---   tier entries: isTierRestock/tierKind/... (one per active tier kind)
---   item entries: itemID + restockSource ("consumable"|"spellReagent"|"manual")
local optionsPanelCache
local optionsPanelCacheTime = 0
local OPTIONS_PANEL_CACHE_SEC = 0.5

function FV.InvalidateRestockOptionsPanelCache()
    optionsPanelCache = nil
    optionsPanelCacheTime = 0
end

function FV.GetRestockTargetItems(opts)
    opts = type(opts) == "table" and opts or {}
    if not opts.forceRefresh and not opts.merchantAware and not opts.forOptionsPanel then
        local t = GetTime and GetTime() or 0
        if optionsPanelCache and (t - optionsPanelCacheTime) < OPTIONS_PANEL_CACHE_SEC then
            return optionsPanelCache
        end
    end
    -- Options / merchant management always pull a fresh FluxInv spell reagent set.
    if opts.forOptionsPanel or opts.forceRefresh then
        optionsPanelCache = nil
        optionsPanelCacheTime = 0
        local S = Spells()
        if S and S.Refresh then
            pcall(S.Refresh)
        end
    end
    local merchantIndex = nil
    if opts.merchantAware and FV.GetMerchantItemIndex then
        merchantIndex = FV.GetMerchantItemIndex(false)
    end

    local list = {}
    local seen = {}

    -- Tier targets first (food/water/bandage/pots via FluxConsumableBest).
    for _, kind in ipairs(TIER_KINDS) do
        local entry = BuildTierEntry(kind, merchantIndex, opts)
        if entry then
            list[#list + 1] = entry
        end
    end

    local Registry = _G.FluxRestockItemRegistry
    local Cons = _G.FluxNCConsumables

    -- Consumable preset items.
    if Cons and Cons.GetRestockUIItemIDs then
        local ok, ids = pcall(Cons.GetRestockUIItemIDs)
        if ok and type(ids) == "table" then
            for _, itemID in ipairs(ids) do
                itemID = tonumber(itemID)
                if itemID and not seen[itemID] then
                    seen[itemID] = true
                    local isChronoboon = Cons.IsChronoboonItem and Cons.IsChronoboonItem(itemID) or false
                    local target = (Cons.GetPresetRestockTarget and Cons.GetPresetRestockTarget(itemID)) or 0
                    if ShouldShowInRestockUI(opts, target) then
                        local name, texture = GetItemNameIcon(itemID)
                        local isCharge = IsChargeRestockItem(itemID)
                        local entry = {
                            itemID = itemID,
                            name = name,
                            texture = texture,
                            target = target,
                            bagCount = isChronoboon and Cons.GetChronoboonBagCount and Cons.GetChronoboonBagCount()
                                or (isCharge and Cons.GetItemChargeCount and Cons.GetItemChargeCount(itemID))
                                or GetBagCountFor(itemID, isCharge),
                            restockSource = "consumable",
                            isChronoboon = isChronoboon,
                        }
                        ApplyMerchantAvailability(entry, merchantIndex)
                        EnrichItemEntryBankCounts(entry)
                        list[#list + 1] = entry
                    end
                end
            end
        end
    end

    -- Spell reagents from known max-rank spells (FluxInv.Spells).
    local reagentIDs = GetPlayerReagentItemIDs(opts)
    local s = Settings()
    for itemID in pairs(reagentIDs) do
        if not seen[itemID] then
            seen[itemID] = true
            local data = s.restockItems[itemID]
            local dismissed = data and data.dismissed == true
            local target = (data and tonumber(data.targetQuantity)) or 0
            if not dismissed and ShouldShowInRestockUI(opts, target) then
                local name, texture = GetItemNameIcon(itemID)
                local entry = {
                    itemID = itemID,
                    name = name,
                    texture = texture,
                    target = target,
                    bagCount = GetBagCountFor(itemID, false),
                    restockSource = "spellReagent",
                    isSpellReagent = true,
                }
                ApplyMerchantAvailability(entry, merchantIndex)
                EnrichItemEntryBankCounts(entry)
                list[#list + 1] = entry
            end
        end
    end

    -- Manual items.
    for itemID, data in pairs(s.restockItems) do
        itemID = tonumber(itemID)
        if itemID and FV.IsSpellReagentItem(itemID) and not seen[itemID] and type(data) == "table" and not data.dismissed then
            local target = tonumber(data.targetQuantity) or 0
            if ShouldShowInRestockUI(opts, target) then
                seen[itemID] = true
                local name, texture = GetItemNameIcon(itemID)
                local entry = {
                    itemID = itemID,
                    name = name,
                    texture = texture,
                    target = target,
                    bagCount = GetBagCountFor(itemID, false),
                    restockSource = "spellReagent",
                    isSpellReagent = true,
                }
                ApplyMerchantAvailability(entry, merchantIndex)
                EnrichItemEntryBankCounts(entry)
                list[#list + 1] = entry
            end
        elseif itemID and not seen[itemID] and type(data) == "table" and not data.dismissed then
            local target = tonumber(data.targetQuantity) or 0
            -- Flag-only restockItems rows (SetRestockItemFlag creates
            -- { targetQuantity = 0, countBank = ... }) must not appear as Manual.
            -- Consumable bank-count toggles plant these; they stay hidden while the
            -- item is on the active preset (seen above) and used to leak into
            -- "Manual restock @ 0" after a preset switch.
            if target > 0 and ShouldShowInRestockUI(opts, target) then
                seen[itemID] = true
                local name, texture = GetItemNameIcon(itemID)
                local Registry2 = _G.FluxRestockItemRegistry
                local isCharge = IsChargeRestockItem(itemID)
                local entry = {
                    itemID = itemID,
                    name = name,
                    texture = texture,
                    target = target,
                    bagCount = GetBagCountFor(itemID, isCharge),
                    restockSource = "manual",
                }
                ApplyMerchantAvailability(entry, merchantIndex)
                EnrichItemEntryBankCounts(entry)
                list[#list + 1] = entry
            end
        end
    end

    if not opts.merchantAware then
        optionsPanelCache = list
        optionsPanelCacheTime = GetTime and GetTime() or 0
    end

    return list
end

function FV.HasAnyRestockTargets()
    local T = Tiers()
    if T then
        for _, kind in ipairs(TIER_KINDS) do
            if T.IsTierEligible and T.IsTierEligible(kind) and (T.GetTarget(kind) or 0) > 0 then
                return true
            end
        end
    end
    for _, data in pairs(Settings().restockItems) do
        if type(data) == "table" and (tonumber(data.targetQuantity) or 0) > 0 then
            return true
        end
    end
    local Cons = _G.FluxNCConsumables
    if Cons and Cons.GetRestockUIItemIDs and Cons.GetPresetRestockTarget then
        local ok, ids = pcall(Cons.GetRestockUIItemIDs)
        if ok and type(ids) == "table" then
            for _, itemID in ipairs(ids) do
                if (Cons.GetPresetRestockTarget(itemID) or 0) > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function FV.IsRestockEntrySoldAtVendor(entry)
    if not entry then return false end
    if entry.isTierRestock then
        -- Lower-tier-only vendors are informational, not buyable.
        return entry.vendorHasStock == true
    end
    return entry.vendorSold == true
end

local function ShouldFilterToVendorSoldOnly(opts)
    opts = type(opts) == "table" and opts or {}
    if opts.forceVendorFilter then
        return true
    end
    if opts.forOptionsPanel then
        return false
    end
    return opts.merchantAware and not FV.GetRestockShowNotSold()
end

--- Remove rows the open merchant does not sell (management UI skips when forOptionsPanel).
function FV.FilterRestockListForVendor(list, opts)
    if type(list) ~= "table" then
        return list
    end
    if not ShouldFilterToVendorSoldOnly(opts) then
        return list
    end
    local filtered = {}
    for i = 1, #list do
        local entry = list[i]
        if FV.IsRestockEntrySoldAtVendor(entry) then
            filtered[#filtered + 1] = entry
        end
    end
    return filtered
end

function FV.SortRestockEntriesByVendorAvailability(list)
    if type(list) ~= "table" then return list end
    table.sort(list, function(a, b)
        local soldA = FV.IsRestockEntrySoldAtVendor(a) and 0 or 1
        local soldB = FV.IsRestockEntrySoldAtVendor(b) and 0 or 1
        if soldA ~= soldB then
            return soldA < soldB
        end
        local tierA = a.isTierRestock and 0 or 1
        local tierB = b.isTierRestock and 0 or 1
        if tierA ~= tierB then
            return tierA < tierB
        end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

--- Entries the merchant Restock button cares about (vendor-buyable, needed).
function FV.GetRestockVendorItems(merchantIndex)
    local list = FV.GetRestockTargetItems({ merchantAware = true })
    local out = {}
    for _, entry in ipairs(list) do
        if entry.target and entry.target > 0 then
            out[#out + 1] = entry
        end
    end
    FV.SortRestockEntriesByVendorAvailability(out)
    return FV.FilterRestockListForVendor(out, { forceVendorFilter = true })
end

function FV.RefreshRestockCacheEntries(items, merchantIndex)
    if type(items) ~= "table" then return end
    for _, entry in ipairs(items) do
        if entry.itemID then
            local Registry = _G.FluxRestockItemRegistry
            local isCharge = Registry and Registry.IsChargeItem and Registry.IsChargeItem(entry.itemID)
            entry.bagCount = GetBagCountFor(entry.itemID, isCharge)
            if entry.restockSource == "consumable" then
                local Cons = _G.FluxNCConsumables
                entry.target = (Cons and Cons.GetPresetRestockTarget and Cons.GetPresetRestockTarget(entry.itemID)) or entry.target
            else
                entry.target = FV.GetRestockTargetForItem(entry.itemID)
            end
            EnrichItemEntryBankCounts(entry)
        end
    end
end

local function EntryNeed(entry)
    if not entry or not entry.target or entry.target <= 0 then
        return 0
    end
    local have = entry.bagCount or 0
    if entry.countBank then
        have = have + (entry.bankCount or 0)
    end
    return math.max(0, entry.target - have)
end
List.EntryNeed = EntryNeed

function FV.HasRestockNeeded(list)
    if type(list) ~= "table" then return false end
    for _, entry in ipairs(list) do
        if EntryNeed(entry) > 0 and FV.IsRestockEntrySoldAtVendor(entry) then
            return true
        end
    end
    return false
end

function FV.GetRestockTotalCost(list)
    if type(list) ~= "table" then return 0 end
    local total = 0
    for _, entry in ipairs(list) do
        local need = EntryNeed(entry)
        if need > 0 and entry.unitPrice and FV.IsRestockEntrySoldAtVendor(entry) then
            total = total + need * entry.unitPrice
        end
    end
    return total
end

-- ---------------------------------------------------------------------------
-- SETTINGS-CHANGED FAN-OUT (options tab <-> merchant UI <-> panels)
-- ---------------------------------------------------------------------------

function FV.RefreshMerchantOptionsCheckboxes(opts)
    opts = type(opts) == "table" and opts or {}
    if not opts.skipRestockPanelRebuild and FV.InvalidateRestockOptionsPanelCache then
        FV.InvalidateRestockOptionsPanelCache()
    end
    local ui = _G.FluxVendorAutoMerchantUI
    if ui then
        if ui.RefreshAllToggles then pcall(ui.RefreshAllToggles) end
        if ui.MarkRestockSettingsDirty then pcall(ui.MarkRestockSettingsDirty) end
        if MerchantFrame and MerchantFrame:IsShown() and ui.ScheduleMerchantUpdate then
            pcall(ui.ScheduleMerchantUpdate, "data")
        end
    end
    local panel = _G.FluxVendorRestockPanel
    if panel then
        if panel.InvalidateListCache then
            pcall(panel.InvalidateListCache)
        end
        if panel.RefreshList then
            pcall(function() panel:RefreshList() end)
        end
    end
    if not opts.skipRestockPanelRebuild and _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive()
        and _G.FluxRestockPanel_RequestRefresh then
        pcall(_G.FluxRestockPanel_RequestRefresh)
    end
    if _G.FluxBankRestockButton and _G.FluxBankRestockButton.Refresh then
        pcall(_G.FluxBankRestockButton.Refresh)
    end
    if not opts.skipOptionsNotify then
        local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
        if AceConfigRegistry then
            pcall(function() AceConfigRegistry:NotifyChange("FluxUI") end)
        end
    end
end

FV.NotifyVendorSettingsChanged = FV.RefreshMerchantOptionsCheckboxes

-- ---------------------------------------------------------------------------
-- BANK TARGET REGISTRY (providers merged for FluxBankRestock)
-- ---------------------------------------------------------------------------

local Registry = {}
local providers = {}
local providerKeys = {}
local bankTargetListCache = nil
local bankTargetCacheDirty = true

function Registry.InvalidateBankTargetsCache()
    bankTargetCacheDirty = true
    bankTargetListCache = nil
end

function Registry.RegisterProvider(key, fn)
    if type(key) ~= "string" or type(fn) ~= "function" then return end
    if not providers[key] then
        providerKeys[#providerKeys + 1] = key
    end
    providers[key] = fn
end

function Registry.UnregisterProvider(key)
    if not providers[key] then return end
    providers[key] = nil
    for i = #providerKeys, 1, -1 do
        if providerKeys[i] == key then
            table.remove(providerKeys, i)
        end
    end
end

local function MergeEntry(out, entry)
    local itemID = tonumber(entry.itemID)
    local target = tonumber(entry.target) or 0
    if not itemID or itemID <= 0 then return end
    local existing = out[itemID]
    if not existing then
        out[itemID] = {
            itemID = itemID,
            target = target,
            mode = entry.mode or "stack",
            maxStack = tonumber(entry.maxStack),
            restock = (entry.restock ~= false),
            isChronoboon = (entry.isChronoboon == true),
            tierKind = entry.tierKind,
            isTierBankEntry = (entry.isTierBankEntry == true),
            tierWithdraw = tonumber(entry.tierWithdraw),
            tierBankCount = tonumber(entry.tierBankCount),
        }
        return
    end
    if target > existing.target then existing.target = target end
    if entry.mode == "charge" then existing.mode = "charge" end
    if entry.maxStack and (not existing.maxStack or entry.maxStack < existing.maxStack) then
        existing.maxStack = entry.maxStack
    end
    if entry.restock ~= false then existing.restock = true end
    if entry.isChronoboon == true then existing.isChronoboon = true end
    if entry.tierKind and not existing.tierKind then existing.tierKind = entry.tierKind end
    if entry.isTierBankEntry == true then
        existing.isTierBankEntry = true
        local tw = tonumber(entry.tierWithdraw) or 0
        if tw > (tonumber(existing.tierWithdraw) or 0) then
            existing.tierWithdraw = tw
        end
        local tb = tonumber(entry.tierBankCount) or 0
        if tb > (tonumber(existing.tierBankCount) or 0) then
            existing.tierBankCount = tb
        end
    end
end

function Registry.GetBankTargets()
    local out = {}
    for i = 1, #providerKeys do
        local fn = providers[providerKeys[i]]
        if fn then
            local ok, entries = pcall(fn)
            if ok and type(entries) == "table" then
                for _, entry in ipairs(entries) do
                    if type(entry) == "table" then
                        MergeEntry(out, entry)
                    end
                end
            end
        end
    end
    return out
end

function Registry.GetBankTargetList()
    if not bankTargetCacheDirty and bankTargetListCache then
        return bankTargetListCache
    end
    local map = Registry.GetBankTargets()
    local list = {}
    for _, entry in pairs(map) do
        list[#list + 1] = entry
    end
    table.sort(list, function(a, b)
        return a.itemID < b.itemID
    end)
    bankTargetListCache = list
    bankTargetCacheDirty = false
    return list
end

function Registry.GetItemMaxStack(itemID)
    if C_Item and C_Item.GetItemMaxStackSizeByID then
        local ok, n = pcall(C_Item.GetItemMaxStackSizeByID, itemID)
        if ok and type(n) == "number" and n > 0 then
            return n
        end
    end
    local ic = IC()
    return ic and ic.GetStackSize(itemID) or nil
end

function Registry.CountItemInBank(itemID)
    local bank = Bank()
    if not bank then return 0 end
    if Registry.IsChargeItem(itemID) then
        return bank.GetCount(itemID, { charges = true })
    end
    return bank.GetCount(itemID)
end

-- ---------------------------------------------------------------------------
-- CHARGE ITEM DETECTION (ported: weapon oils and other charge-carrying items)
-- ---------------------------------------------------------------------------

local function BuildChargePatterns()
    local patterns = {}
    local function add(fmt)
        if type(fmt) ~= "string" then return end
        local p = fmt:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        p = p:gsub("%%%%d", "(%%d+)")
        patterns[#patterns + 1] = p:lower()
    end
    add(_G.ITEM_SPELL_CHARGES_P1)
    add(_G.ITEM_SPELL_CHARGES_P2)
    add(_G.ITEM_SPELL_CHARGES)
    patterns[#patterns + 1] = "(%d+)%s*charges?"
    patterns[#patterns + 1] = "charges?%s*:?%s*(%d+)"
    patterns[#patterns + 1] = "(%d+)%s*uses?%s*remaining"
    patterns[#patterns + 1] = "uses?%s*remaining%s*:?%s*(%d+)"
    patterns[#patterns + 1] = "uses?%s*:?%s*(%d+)"
    return patterns
end
local chargePatterns = nil

local chargeScanTip
local function EnsureChargeScanTooltip()
    if chargeScanTip then return chargeScanTip end
    chargeScanTip = CreateFrame("GameTooltip", "FluxRestockChargeScanTooltip", UIParent, "GameTooltipTemplate")
    chargeScanTip:SetOwner(UIParent, "ANCHOR_NONE")
    return chargeScanTip
end

local function ParseChargesFromLines(getLineText, numLines)
    if not chargePatterns then
        chargePatterns = BuildChargePatterns()
    end
    for i = 1, numLines do
        local t = getLineText(i)
        if t and t ~= "" then
            t = t:lower()
            for _, p in ipairs(chargePatterns) do
                local n = t:match(p)
                if n then
                    n = tonumber(n)
                    if n and n > 0 then
                        return n
                    end
                end
            end
        end
    end
    return nil
end

local function ScanTooltipMaxCharges(itemID)
    local ic = IC()
    local link = (ic and ic.GetLink(itemID)) or ("item:" .. tostring(itemID))
    local tip = EnsureChargeScanTooltip()
    tip:ClearLines()
    local ok = pcall(function() tip:SetHyperlink(link) end)
    if not ok then return nil end
    return ParseChargesFromLines(function(i)
        local left = _G["FluxRestockChargeScanTooltipTextLeft" .. i]
        return left and left:GetText()
    end, tip:NumLines())
end

local chargeInfoCache = {}
local function GetChargeCacheStore()
    local sv = _G._FluxUI_CharSavedVars
    if not sv then return nil end
    sv.RestockChargeInfo = sv.RestockChargeInfo or {}
    return sv.RestockChargeInfo
end

local function StoreChargeResult(itemID, isCharge, maxCharges)
    local result = { resolved = true, isCharge = isCharge, maxCharges = maxCharges }
    chargeInfoCache[itemID] = result
    local store = GetChargeCacheStore()
    if store then
        store[itemID] = result
    end
    return isCharge, maxCharges
end

local function HasApiChargeSignal(itemID)
    local getCount = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not getCount then return false end
    local bagItems = getCount(itemID, false, false, true) or 0
    local bagUses = getCount(itemID, false, true, true) or 0
    if bagUses > bagItems then return true end
    -- includeBank + reagent + account/warband when probing owned uses
    local allItems = getCount(itemID, true, false, true, true) or 0
    local allUses = getCount(itemID, true, true, true, true) or 0
    return allUses > allItems
end

function Registry.GetSlotCharges(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return nil
    end
    local bankMain = _G.BANK_CONTAINER or -1
    local Cap = _G.Flux and _G.Flux.Cap
    local reagentBank = Cap and Cap.GetReagentBankContainerID and Cap.GetReagentBankContainerID()
    local enumBank = Enum and Enum.BagIndex and Enum.BagIndex.Bank
    local isLegacyMainBank = (bag == bankMain) or (enumBank and bag == enumBank)
    if Cap and Cap.HasUnifiedBankUI and Cap.HasUnifiedBankUI() then
        isLegacyMainBank = false
    end
    if Cap and Cap.IsBankTabSentinel and Cap.IsBankTabSentinel(bag) then
        isLegacyMainBank = false
        reagentBank = nil
    end

    if C_TooltipInfo then
        local data
        if isLegacyMainBank and _G.BankButtonIDToInvSlotID and C_TooltipInfo.GetInventoryItem then
            local ok, d = pcall(C_TooltipInfo.GetInventoryItem, "player", _G.BankButtonIDToInvSlotID(slot))
            if ok then data = d end
        elseif bag == reagentBank and _G.ReagentBankButtonIDToInvSlotID and C_TooltipInfo.GetInventoryItem then
            local ok, d = pcall(C_TooltipInfo.GetInventoryItem, "player", _G.ReagentBankButtonIDToInvSlotID(slot))
            if ok then data = d end
        elseif C_TooltipInfo.GetBagItem then
            -- Modern character/warband bank tabs and classic bank bags all use bag+slot.
            local ok, d = pcall(C_TooltipInfo.GetBagItem, bag, slot)
            if ok then data = d end
        end
        if data and data.lines then
            if TooltipUtil and TooltipUtil.SurfaceArgs then
                for _, line in ipairs(data.lines) do
                    pcall(TooltipUtil.SurfaceArgs, line)
                end
            end
            local n = ParseChargesFromLines(function(i)
                local line = data.lines[i]
                return line and line.leftText
            end, #data.lines)
            if n then return n end
        end
    end

    local tip = EnsureChargeScanTooltip()
    tip:ClearLines()
    local ok
    if isLegacyMainBank and _G.BankButtonIDToInvSlotID then
        ok = pcall(function() tip:SetInventoryItem("player", _G.BankButtonIDToInvSlotID(slot)) end)
    elseif bag == reagentBank and _G.ReagentBankButtonIDToInvSlotID then
        ok = pcall(function() tip:SetInventoryItem("player", _G.ReagentBankButtonIDToInvSlotID(slot)) end)
    else
        ok = pcall(function() tip:SetBagItem(bag, slot) end)
    end
    if not ok then return nil end
    return ParseChargesFromLines(function(i)
        local left = _G["FluxRestockChargeScanTooltipTextLeft" .. i]
        return left and left:GetText()
    end, tip:NumLines())
end

local function ScanOwnedMaxCharges(itemID)
    local inv = Inv()
    if not inv then return nil end
    local maxSeen = nil
    local function consider(bag, slot, slotItemID)
        if slotItemID == itemID then
            local c = Registry.GetSlotCharges(bag, slot)
            if c and c > 0 and (not maxSeen or c > maxSeen) then
                maxSeen = c
            end
        end
    end
    inv.ForEachBagSlot(function(bag, slot, slotItemID)
        consider(bag, slot, slotItemID)
    end)
    local bank = Bank()
    if bank and bank.IsOpen() then
        bank.ForEachSlot(function(bag, slot, info)
            consider(bag, slot, info.itemID)
        end)
    end
    return maxSeen
end

function Registry.GetChargeInfo(itemID)
    itemID = tonumber(itemID)
    if not itemID then return false, nil end
    local cached = chargeInfoCache[itemID]
    if not cached then
        local store = GetChargeCacheStore()
        if store and store[itemID] then
            cached = store[itemID]
            chargeInfoCache[itemID] = cached
        end
    end

    local apiCharge = HasApiChargeSignal(itemID)

    if cached and cached.resolved then
        if cached.isCharge == true then
            if not cached.maxCharges then
                local mc = ScanTooltipMaxCharges(itemID)
                if mc then
                    cached.maxCharges = mc
                    local store = GetChargeCacheStore()
                    if store and store[itemID] then
                        store[itemID].maxCharges = mc
                    end
                end
            end
            return true, cached.maxCharges
        end
        if not apiCharge then
            return false, cached.maxCharges
        end
    end

    local Cons = _G.FluxNCConsumables
    local isWeaponEnchant = Cons and Cons.IsWeaponEnchantItem and Cons.IsWeaponEnchantItem(itemID) or false

    local maxStack = Registry.GetItemMaxStack(itemID)
    if not maxStack then
        if IC() then IC().RequestLoad(itemID) end
        if isWeaponEnchant or apiCharge then
            return StoreChargeResult(itemID, true, ScanTooltipMaxCharges(itemID) or ScanOwnedMaxCharges(itemID))
        end
        if cached then
            return cached.isCharge == true, cached.maxCharges
        end
        return false, nil
    end

    local maxCharges = ScanTooltipMaxCharges(itemID)
    local ownedMax = nil
    if maxStack == 1 and not maxCharges then
        ownedMax = ScanOwnedMaxCharges(itemID)
    end
    local isCharge = isWeaponEnchant or apiCharge or (maxStack == 1 and (maxCharges ~= nil or ownedMax ~= nil))

    if not isCharge and not Cons then
        return false, nil
    end
    return StoreChargeResult(itemID, isCharge, maxCharges or ownedMax)
end

function Registry.IsChargeItem(itemID)
    local isCharge = Registry.GetChargeInfo(itemID)
    return isCharge == true
end

function Registry.GetItemMaxCharges(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    local _, maxCharges = Registry.GetChargeInfo(itemID)
    if maxCharges and maxCharges > 0 then
        return maxCharges
    end
    local maxSeen = ScanOwnedMaxCharges(itemID)
    if maxSeen and maxSeen > 0 then
        return maxSeen
    end
    local stack = Registry.GetItemMaxStack(itemID)
    if stack and stack > 1 then
        return stack
    end
    return nil
end

function Registry.GetChargeAwareCount(itemID, includeBank)
    itemID = tonumber(itemID)
    if not itemID then return 0 end
    includeBank = includeBank == true
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID, includeBank, true, includeBank, includeBank) or 0
    elseif GetItemCount then
        return GetItemCount(itemID, includeBank, true, includeBank) or 0
    end
    return 0
end

-- Providers.
Registry.RegisterProvider("vendorRestockItems", function()
    local s = Settings()
    local out = {}
    for itemID, data in pairs(s.restockItems) do
        if type(data) == "table" then
            local numericID = tonumber(itemID)
            local target = tonumber(data.targetQuantity) or 0
            if numericID and target > 0 then
                local isCharge = Registry.IsChargeItem(numericID)
                out[#out + 1] = {
                    itemID = numericID,
                    target = target,
                    mode = isCharge and "charge" or "stack",
                    maxStack = isCharge and Registry.GetItemMaxCharges(numericID)
                        or Registry.GetItemMaxStack(numericID),
                    restock = true,
                }
            end
        end
    end
    return out
end)

Registry.RegisterProvider("tierTargets", function()
    local T = Tiers()
    if T and T.GetBankRestockEntries then
        return T.GetBankRestockEntries() or {}
    end
    return {}
end)


-- The consumables provider registers itself (FluxNCConsumables) using the same
-- Registry.RegisterProvider("consumables", ...) contract as before.

local function HookBankTargetCacheInvalidation()
    if Registry._bankTargetCacheHooked then
        return
    end
    Registry._bankTargetCacheHooked = true
    local bank = Bank()
    if bank then
        bank.RegisterBankClose("FluxRestockItemRegistry", function()
            Registry.InvalidateBankTargetsCache()
        end)
    end
    local inv = Inv()
    if inv and inv.RegisterListener then
        inv.RegisterListener("BankTargets_FluxRestockItemRegistry", function(ctx)
            local regions = ctx and ctx.regions
            if not regions or not (regions.bank or regions.warband or regions.bags) then
                return
            end
            Registry.InvalidateBankTargetsCache()
        end, { tier = "light", deferHeavy = true })
    end
end
HookBankTargetCacheInvalidation()

FluxRestockItemRegistry = Registry

-- ---------------------------------------------------------------------------
-- EVENTS
-- ---------------------------------------------------------------------------

-- Spell-book reagents: FluxInv owns SPELLS_CHANGED / warm; Restock listens.
do
    local inv = Inv()
    if inv and inv.RegisterListener then
        inv.RegisterListener("RestockSpellReagents", function(ctx)
            local regions = ctx and ctx.regions
            if regions and regions.spells then
                List.InvalidateSpellReagentCache()
            end
        end, { tier = "scan", regions = { "spells" } })
    end
    local loginFrame = CreateFrame("Frame")
    loginFrame:RegisterEvent("PLAYER_LOGIN")
    loginFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        local S = Spells()
        if S and S.ScheduleWarm then
            S.ScheduleWarm()
        end
        -- Ensure options panel refreshes once FluxInv finishes the first scan.
        if C_Timer and C_Timer.After then
            C_Timer.After(2.0, function()
                List.InvalidateSpellReagentCache()
            end)
        end
    end)
end

_G.FluxRestockList = List
_G.FluxRestockItemRegistry = Registry
_G.FluxRestock = FluxRestock
return List

