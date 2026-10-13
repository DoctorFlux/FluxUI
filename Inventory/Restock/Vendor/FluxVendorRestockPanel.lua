-- FluxVendorRestockPanel.lua
-- Merchant Restock tab: manage all restock targets with drag/drop and inline editing
local addonName, ns = ...

FluxVendorRestockPanel = FluxVendorRestockPanel or {}

local Panel = FluxVendorRestockPanel
local FV = _G.FluxVendorAuto
local FVID = _G.FluxVendorItemDisplay

local panelFrame
local scrollFrame
local scrollChild
local listButtons = {}
local cachedList = nil
local spinner
local merchantTab
local bagEventsRegistered = false
local QueryItems

local ROW_HEIGHT = 28
local COUNT_COL_W = 78
local VISIBLE_ROWS = 17
local FOOTER_RESERVE = 52
local hideNotSoldCheck -- Show-items-not-sold-here toggle (unchecked = sold-only list)

local function GetItemInfoCompat(id)
    if C_Item and C_Item.GetItemInfo then
        local info = C_Item.GetItemInfo(id)
        if type(info) == "table" then
            return info.itemName or info.name, info.itemLink, info.itemQuality or info.quality,
                info.itemLevel, info.itemMinLevel, info.itemType, info.itemSubType,
                info.stackCount or info.itemStackCount, info.equipLoc or info.itemEquipLoc,
                info.iconFileID or info.itemIcon or info.iconID, info.sellPrice
        end
        return info
    end
    return GetItemInfo(id)
end

local function IsItemInfoLoaded(id)
    if C_Item and C_Item.GetItemInfo then
        local info = C_Item.GetItemInfo(id)
        if type(info) == "table" then
            return (info.itemName or info.name) ~= nil
        end
        return info ~= nil
    end
    return GetItemInfo(id) ~= nil
end

local function GetItemIdFromCursor()
    if _G.FluxVendorJunk and _G.FluxVendorJunk.GetItemIdFromCursor then
        return _G.FluxVendorJunk.GetItemIdFromCursor()
    end
    if _G.FluxItemCurrencyTracking and _G.FluxItemCurrencyTracking.GetItemIdFromCursor then
        return _G.FluxItemCurrencyTracking.GetItemIdFromCursor()
    end
    local cursorType, itemID = GetCursorInfo()
    if cursorType == "item" then
        return tonumber(itemID)
    end
end

local function GetRestockCountColor(bagCount, target)
    if bagCount >= target then
        return 0.1, 1, 0.1
    elseif bagCount == 0 then
        return 1, 0.2, 0.2
    end
    return 1, 0.82, 0
end

local function FormatCountText(bagCount, target)
    local r, g, b = GetRestockCountColor(bagCount, target)
    return string.format(
        "|cff%02x%02x%02x%d|r / %d",
        math.floor(r * 255),
        math.floor(g * 255),
        math.floor(b * 255),
        bagCount,
        target
    )
end

local function FormatItemCountLines(entry, bagCount, target)
    if not entry or not entry.countBank then
        return FormatCountText(bagCount, target), nil
    end
    local bankCount = entry.bankCount or 0
    local combined = bagCount + bankCount
    local r, g, b = GetRestockCountColor(combined, target)
    local hc = string.format("|cff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    if bankCount > 0 then
        return hc .. tostring(bagCount) .. "|r|cff7fbfff+" .. tostring(bankCount) .. "|r",
            "|cff888888/ " .. tostring(target) .. "|r"
    end
    return string.format(
        "%s%d|r / %d",
        hc,
        bagCount,
        target
    ), nil
end

local function ApplyRowCountText(row, entry, bagCount, target)
    if not row or not row.countText then
        return
    end
    local line1, line2 = FormatItemCountLines(entry, bagCount, target)
    if line2 then
        row.countText:SetText(line1 .. "\n" .. line2)
    else
        row.countText:SetText(line1)
    end
end

-- Count text that optionally folds in the player's bank stock. When the
-- per-item "count bank" toggle is on, the bank count contributes toward the
-- target and is shown as bags+bank on one line, target on the next.
local function FormatItemCountText(entry, bagCount, target)
    local line1, line2 = FormatItemCountLines(entry, bagCount, target)
    if line2 then
        return line1 .. "\n" .. line2
    end
    return line1
end

local function FormatTierCountText(entry, bagCount, target)
    local tierKind = entry and entry.tierKind
    local Tiers = _G.FluxRestockTiers
    if tierKind and Tiers and Tiers.IsTierCountPending and Tiers.IsTierCountPending(tierKind) then
        if entry and entry.countBank and (entry.bankCount or 0) > 0 then
            return "|cff888888...|r|cff7fbfff+" .. tostring(entry.bankCount or 0) .. "|r\n|cff888888/ " .. tostring(target) .. "|r"
        end
        return string.format("|cff888888...|r / %d", target)
    end
    return FormatItemCountText(entry, bagCount, target)
end

local function ApplyTierVendorNameStyle(nameText, entry)
    local displayName = entry.name or "Restock tier"
    if not entry.merchantChecked then
        nameText:SetText(displayName)
        return
    end
    if entry.vendorNotSold then
        nameText:SetText("|cff888888" .. displayName .. " (not sold here)|r")
    elseif entry.vendorLowerTierOnly then
        nameText:SetText("|cffd9d066" .. displayName .. " (lower tier only)|r")
    elseif entry.vendorHasStock then
        nameText:SetText("|cff00ff00" .. displayName .. "|r")
    else
        nameText:SetText(displayName)
    end
end

local function ApplyItemVendorNameStyle(nameText, entry, fallbackName)
    local displayName = fallbackName or entry.name or ("Item " .. tostring(entry.itemID))
    if not entry.merchantChecked then
        nameText:SetText(displayName)
        return
    end
    if entry.vendorNotSold then
        nameText:SetText("|cff888888" .. displayName .. " (not sold here)|r")
    elseif entry.vendorSold then
        nameText:SetText("|cff00ff00" .. displayName .. "|r")
    else
        nameText:SetText(displayName)
    end
end

local TIER_VENDOR_LABEL = {
    food = "food",
    water = "water",
    bandage = "bandages",
    healPotion = "healing potions",
    manaPotion = "mana potions",
}

local function AppendTierVendorTooltipLines(entry)
    if not entry or not entry.tierKind then
        return
    end
    local FJ = _G.FluxVendorJunk
    if FJ and FJ.AppendTierReferenceRestoreLines then
        FJ.AppendTierReferenceRestoreLines(GameTooltip, entry.tierKind)
    end
    if not entry.merchantChecked then
        return
    end
    local kindLabel = TIER_VENDOR_LABEL[entry.tierKind] or string.lower(entry.name or "items")
    if entry.vendorNotSold then
        GameTooltip:AddLine(
            "This vendor does not sell " .. kindLabel .. ".",
            1, 0.35, 0.35, true
        )
    elseif entry.vendorLowerTierOnly then
        GameTooltip:AddLine(
            "This vendor only sells lower-tier " .. kindLabel .. " — restock will not buy them.",
            1, 0.82, 0.35, true
        )
    elseif entry.vendorHasStock then
        GameTooltip:AddLine(
            "This vendor sells matching " .. kindLabel .. " for auto-restock.",
            0.35, 1, 0.35, true
        )
    end
end

local function BuildRestockList()
    FV = _G.FluxVendorAuto
    if FV and FV.EnsureSettings then
        FV.EnsureSettings()
    end
    local inv = _G.FluxRestock and _G.FluxRestock.Inv
    if inv and inv.Spells and inv.Spells.Refresh then
        pcall(inv.Spells.Refresh)
    end
    if FV and FV.GetRestockTargetItems then
        local merchantOpen = MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown()
        -- forOptionsPanel: include zero-target management rows.
        -- Do NOT pass forOptionsPanel into FilterRestockListForVendor — that flag
        -- disables sold-only filtering (options tab wants all rows; merchant does not).
        local list = FV.GetRestockTargetItems({
            merchantAware = true,
            forOptionsPanel = true,
            forceRefresh = true,
        })
        if merchantOpen and FV.SortRestockEntriesByVendorAvailability then
            FV.SortRestockEntriesByVendorAvailability(list)
        end
        if FV.FilterRestockListForVendor then
            return FV.FilterRestockListForVendor(list, {
                merchantAware = merchantOpen,
            })
        end
        return list
    end
    return {}
end

local function GetRestockList(forceRebuild)
    if cachedList and not forceRebuild then
        return cachedList
    end
    cachedList = BuildRestockList()
    return cachedList
end

function Panel.InvalidateListCache()
    cachedList = nil
end

function Panel.RefreshCountsOnly()
    if not panelFrame or not panelFrame:IsShown() then
        return
    end
    if not cachedList then
        Panel:RefreshList()
        return
    end
    FV = FV or _G.FluxVendorAuto
    local merchantIndex = FV and FV.GetMerchantItemIndex and FV.GetMerchantItemIndex(false) or nil
    if FV and FV.RefreshRestockCacheEntries then
        FV.RefreshRestockCacheEntries(cachedList, merchantIndex)
    end
    RefreshScrollList()
end

local function GetItemCountCompat(itemID)
    -- Prefer FluxInv via FluxGetItemCount when present; Blizzard fallback for merchant without FluxInv.
    if _G.FluxGetItemCount then
        return _G.FluxGetItemCount(itemID, { includeBank = false, charges = true }) or 0
    end
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID, false, true, true) or 0
    end
    if GetItemCount then
        return GetItemCount(itemID, false, true, true) or 0
    end
    return 0
end

local function IsChargeItem(itemId)
    local Reg = _G.FluxRestockItemRegistry
    if Reg and Reg.IsChargeItem then
        return Reg.IsChargeItem(itemId)
    end
    local Cons = _G.FluxNCConsumables
    if Cons and Cons.IsWeaponEnchantItem then
        return Cons.IsWeaponEnchantItem(itemId)
    end
    return false
end

local function GetChargeAwareCount(itemId)
    if IsChargeItem(itemId) then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.GetItemChargeCount then
            return Cons.GetItemChargeCount(itemId)
        end
        local BC = _G.FluxRestockBankCompat
        if BC and BC.CountItemInBags then
            return BC.CountItemInBags(itemId)
        end
    end
    return GetItemCountCompat(itemId)
end

local function IsSpellReagentItem(itemID)
    FV = FV or _G.FluxVendorAuto
    if FV and FV.IsSpellReagentItem then
        return FV.IsSpellReagentItem(itemID)
    end
    return FV and FV.IsKnownSpellReagentItem and FV.IsKnownSpellReagentItem(itemID) or false
end

local function IsConsumablePresetItem(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local Cons = _G.FluxNCConsumables
    if not Cons or not Cons.GetRestockUIItemIDs then
        return false
    end
    local ok, ids = pcall(Cons.GetRestockUIItemIDs)
    if not ok or type(ids) ~= "table" then
        return false
    end
    for _, id in ipairs(ids) do
        if tonumber(id) == itemID then
            return true
        end
    end
    return false
end

local function ResolveRestockSource(itemID, restockSource)
    if restockSource == "consumable" or restockSource == "spellReagent" or restockSource == "manual" then
        return restockSource
    end
    if IsConsumablePresetItem(itemID) then
        return "consumable"
    end
    if IsSpellReagentItem(itemID) then
        return "spellReagent"
    end
    return "manual"
end

local function GetItemRestockTarget(itemID, restockSource)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local source = ResolveRestockSource(itemID, restockSource)
    if source == "consumable" then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.GetPresetRestockTarget then
            return Cons.GetPresetRestockTarget(itemID) or 0
        end
    end
    FV = FV or _G.FluxVendorAuto
    if FV and FV.GetRestockTargetForItem then
        return FV.GetRestockTargetForItem(itemID)
    end
    return 0
end

local function ClearRestockTarget(itemID, restockSource)
    FV = FV or _G.FluxVendorAuto
    if not FV or not itemID then
        return
    end
    local source = ResolveRestockSource(itemID, restockSource)
    if source == "consumable" then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.SetPresetRestockTarget then
            Cons.SetPresetRestockTarget(itemID, 0)
        end
        return
    end
    if source == "spellReagent" then
        if FV.SetRestockTarget then
            FV.SetRestockTarget(itemID, 0)
        end
        return
    end
    if FV.RemoveRestockItem then
        FV.RemoveRestockItem(itemID)
    end
end

local function SetItemRestockTarget(itemID, value, restockSource)
    itemID = tonumber(itemID)
    if not itemID then
        return
    end
    value = math.max(0, math.min(999, tonumber(value) or 0))
    local source = ResolveRestockSource(itemID, restockSource)
    if source == "consumable" then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.SetPresetRestockTarget then
            Cons.SetPresetRestockTarget(itemID, value)
            return
        end
    end
    FV = FV or _G.FluxVendorAuto
    if not FV then
        return
    end
    if source == "spellReagent" then
        if value > 0 and FV.SetRestockTarget then
            FV.SetRestockTarget(itemID, value)
        elseif FV.DismissRestockReagent then
            FV.DismissRestockReagent(itemID)
        elseif FV.SetRestockTarget then
            FV.SetRestockTarget(itemID, 0)
        end
        return
    end
    if value > 0 and FV.AddRestockItem then
        FV.AddRestockItem(itemID, value)
    else
        ClearRestockTarget(itemID, restockSource)
    end
end

local function DismissFromRestockList(itemID, restockSource)
    FV = FV or _G.FluxVendorAuto
    if not FV or not itemID then
        return
    end
    local source = ResolveRestockSource(itemID, restockSource)
    if source == "consumable" then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.SetPresetRestockTarget then
            Cons.SetPresetRestockTarget(itemID, 0)
        end
        return
    end
    if source == "spellReagent" then
        if FV.DismissRestockReagent then
            FV.DismissRestockReagent(itemID)
        end
        return
    end
    if FV.RemoveRestockItem then
        FV.RemoveRestockItem(itemID)
    end
end

local function CommitTargetEdit(row, itemID)
    local editBox = row.editBox
    if not editBox or not itemID then
        return
    end
    local value = tonumber(editBox:GetText()) or 0
    SetItemRestockTarget(itemID, value, row and row.restockSource)
    editBox:Hide()
    row.countText:Show()
    QueryItems()
end

local function IsCombatTierKind(kind)
    return kind == "bandage" or kind == "healPotion" or kind == "manaPotion"
end

local function IsFoodWaterTierKind(kind)
    return kind == "food" or kind == "water"
end

local function CommitTierTargetEdit(row, tierKind)
    local editBox = row.editBox
    if not editBox or not tierKind then
        return
    end
    local value = tonumber(editBox:GetText()) or 0
    FV = FV or _G.FluxVendorAuto
    if FV then
        if IsFoodWaterTierKind(tierKind) and FV.SetRestockFoodWaterTarget then
            FV.SetRestockFoodWaterTarget(tierKind, value)
        elseif IsCombatTierKind(tierKind) and FV.SetRestockCombatTarget then
            FV.SetRestockCombatTarget(tierKind, value)
        end
    end
    editBox:Hide()
    row.countText:Show()
    QueryItems()
end

local function ShowTierTargetEdit(row, tierKind)
    if not row or not row.editBox or not tierKind then
        return
    end
    local target = 0
    if IsFoodWaterTierKind(tierKind) then
        FV = FV or _G.FluxVendorAuto
        if FV and FV.EnsureSettings then
            local s = FV.EnsureSettings()
            local fw = s and s.restockFoodWater
            if fw then
                if tierKind == "food" then
                    target = fw.foodTarget or 0
                elseif tierKind == "water" then
                    target = fw.waterTarget or 0
                end
            end
        end
    elseif IsCombatTierKind(tierKind) then
        local FC = _G.FluxCombatItemRestock
        target = FC and FC.GetTarget and FC.GetTarget(tierKind) or 0
    end
    row.countText:Hide()
    row.editBox:SetText(tostring(target))
    row.editBox:Show()
    row.editBox:SetFocus()
    row.editBox:HighlightText()
end

local function ShowTargetEdit(row, itemID)
    if not row or not row.editBox then
        return
    end
    local target = GetItemRestockTarget(itemID, row.restockSource)
    row.countText:Hide()
    row.editBox:SetText(tostring(target))
    row.editBox:Show()
    row.editBox:SetFocus()
    row.editBox:HighlightText()
end

local function AppendItemActionTooltipLines(row)
    local itemID = row and row.itemID
    if row and row.countBank then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(
            string.format("In bank: %d (counted toward target)", row.bankCount or 0),
            0.5, 0.75, 1
        )
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: Edit target amount.", 0.7, 0.7, 0.7)
    if IsSpellReagentItem(itemID) then
        GameTooltip:AddLine("Right-click: Hide from list.", 0.7, 0.7, 0.7)
    else
        GameTooltip:AddLine("Right-click: Remove from list.", 0.7, 0.7, 0.7)
    end
    if row and row.countBank then
        GameTooltip:AddLine("Shift-right-click: Stop counting bank stock.", 0.7, 0.7, 0.7)
    else
        GameTooltip:AddLine("Shift-right-click: Count bank stock toward target.", 0.7, 0.7, 0.7)
    end
    GameTooltip:AddLine("Drag items here to add.", 0.7, 0.7, 0.7)
end

local function CreateListButton(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetColorTexture(1, 1, 1, 0.08)
    row.stripe:Hide()

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(15, 15)
    row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)

    row.countText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.countText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.countText:SetWidth(COUNT_COL_W)
    row.countText:SetJustifyH("RIGHT")
    row.countText:SetJustifyV("MIDDLE")

    row.editBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.editBox:SetSize(56, 18)
    row.editBox:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.editBox:SetFontObject("GameFontHighlightSmall")
    row.editBox:SetJustifyH("RIGHT")
    row.editBox:SetAutoFocus(false)
    row.editBox:SetNumeric(true)
    row.editBox:SetMaxLetters(4)
    row.editBox:Hide()

    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
    row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.nameText:SetPoint("RIGHT", row.countText, "LEFT", -6, 0)
    row.nameText:SetJustifyH("LEFT")

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.35)

    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, button)
        if self.tierKind then
            if button == "RightButton" and IsShiftKeyDown() then
                FV = FV or _G.FluxVendorAuto
                if FV and FV.GetTierCountBankFlag and FV.SetTierCountBankFlag then
                    FV.SetTierCountBankFlag(self.tierKind, not FV.GetTierCountBankFlag(self.tierKind))
                    QueryItems()
                end
                return
            end
            if button == "LeftButton" then
                ShowTierTargetEdit(self, self.tierKind)
            end
            return
        end
        if not self.itemID then
            return
        end
        if button == "RightButton" then
            if IsShiftKeyDown() then
                FV = FV or _G.FluxVendorAuto
                if FV and FV.GetRestockItemFlags and FV.SetRestockItemFlag then
                    local flags = FV.GetRestockItemFlags(self.itemID)
                    FV.SetRestockItemFlag(self.itemID, "countBank", not flags.countBank)
                    QueryItems()
                end
                return
            end
            DismissFromRestockList(self.itemID, self.restockSource)
            QueryItems()
        else
            ShowTargetEdit(self, self.itemID)
        end
    end)

    row.editBox:SetScript("OnEnterPressed", function(box)
        local parentRow = box:GetParent()
        if parentRow and parentRow.tierKind then
            CommitTierTargetEdit(parentRow, parentRow.tierKind)
        else
            CommitTargetEdit(parentRow, parentRow and parentRow.itemID)
        end
        box:ClearFocus()
    end)

    row.editBox:SetScript("OnEscapePressed", function(box)
        box:Hide()
        local parentRow = box:GetParent()
        if parentRow and parentRow.countText then
            parentRow.countText:Show()
        end
        box:ClearFocus()
    end)

    row.editBox:SetScript("OnEditFocusLost", function(box)
        if not box:IsShown() then
            return
        end
        local parentRow = box:GetParent()
        if parentRow and parentRow.tierKind then
            CommitTierTargetEdit(parentRow, parentRow.tierKind)
        else
            CommitTargetEdit(parentRow, parentRow and parentRow.itemID)
        end
        box:ClearFocus()
    end)

    row:SetScript("OnEnter", function(self)
        if self.tierKind then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.nameText:GetText() or "Restock", 1, 1, 1)
            if IsFoodWaterTierKind(self.tierKind) then
                GameTooltip:AddLine("Counts stacks at your best restore tier (including conjured).", 0.7, 0.7, 0.7, true)
                GameTooltip:AddLine("Conjured stacks count toward target.", 0.7, 0.7, 0.7, true)
                GameTooltip:AddLine("Well Fed buff food is excluded. Inferior tiers do not count.", 0.7, 0.7, 0.7, true)
                AppendTierVendorTooltipLines(self)
            elseif IsCombatTierKind(self.tierKind) then
                GameTooltip:AddLine("Counts best-tier stacks in your bags.", 0.7, 0.7, 0.7, true)
                GameTooltip:AddLine("Bank restock pulls matching items from the bank.", 0.7, 0.7, 0.7, true)
                AppendTierVendorTooltipLines(self)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Left-click: Edit stack target.", 0.7, 0.7, 0.7)
            if self.countBank then
                GameTooltip:AddLine(
                    string.format("In bank: %d (counted toward target)", self.bankCount or 0),
                    0.5, 0.75, 1
                )
                GameTooltip:AddLine("Shift-right-click: Stop counting bank stock.", 0.7, 0.7, 0.7)
            else
                GameTooltip:AddLine("Shift-right-click: Count bank stock toward target.", 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
            return
        end
        if not self.itemID then
            return
        end
        if FVID and FVID.ShowTooltip then
            FVID.ShowTooltip(self, self.itemID, self.link, function()
                local FR = _G.FluxRestock
                if FR and FR.AppendSpellsUsingReagentToTooltip then
                    FR.AppendSpellsUsingReagentToTooltip(GameTooltip, self.itemID)
                end
                if self.merchantChecked then
                    GameTooltip:AddLine(" ")
                    if self.vendorNotSold then
                        GameTooltip:AddLine("This vendor does not sell this item.", 1, 0.35, 0.35, true)
                    elseif self.vendorSold then
                        GameTooltip:AddLine("This vendor sells this item.", 0.35, 1, 0.35, true)
                    end
                end
                AppendItemActionTooltipLines(self)
            end)
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetItemByID then
            pcall(GameTooltip.SetItemByID, GameTooltip, self.itemID)
        elseif self.link then
            GameTooltip:SetHyperlink(self.link)
        else
            GameTooltip:SetText(self.nameText:GetText() or "", 1, 1, 1)
        end
        local FR = _G.FluxRestock
        if FR and FR.AppendSpellsUsingReagentToTooltip then
            FR.AppendSpellsUsingReagentToTooltip(GameTooltip, self.itemID)
        end
        if self.merchantChecked then
            GameTooltip:AddLine(" ")
            if self.vendorNotSold then
                GameTooltip:AddLine("This vendor does not sell this item.", 1, 0.35, 0.35, true)
            elseif self.vendorSold then
                GameTooltip:AddLine("This vendor sells this item.", 0.35, 1, 0.35, true)
            end
        end
        AppendItemActionTooltipLines(self)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)

    return row
end

local function EnsureListButtons(count)
    for i = 1, count do
        if not listButtons[i] then
            listButtons[i] = CreateListButton(scrollChild, i)
        end
        listButtons[i]:Show()
    end
    for i = count + 1, #listButtons do
        listButtons[i]:Hide()
    end
end

local function RefreshScrollList()
    if not scrollFrame or not scrollChild then
        return
    end
    local list = GetRestockList()
    local offset = math.floor((scrollFrame:GetVerticalScroll() or 0) / ROW_HEIGHT + 0.5)
    local childHeight = math.max(#list * ROW_HEIGHT, ROW_HEIGHT)
    scrollChild:SetHeight(childHeight)

    EnsureListButtons(VISIBLE_ROWS)
    for i = 1, VISIBLE_ROWS do
        local index = i + offset
        local entry = list[index]
        local row = listButtons[i]
        if entry then
            if entry.isTierRestock and entry.tierKind then
                row.tierKind = entry.tierKind
                row.itemID = nil
                row.link = nil
                row.vendorUnavailable = entry.vendorUnavailable == true
                row.vendorHasStock = entry.vendorHasStock == true
                row.vendorNotSold = entry.vendorNotSold == true
                row.vendorLowerTierOnly = entry.vendorLowerTierOnly == true
                row.merchantChecked = entry.merchantChecked == true
                row.countBank = entry.countBank == true
                row.bankCount = entry.bankCount or 0
                ApplyTierVendorNameStyle(row.nameText, entry)
                local bagCount = entry.bagCount or 0
                local target = entry.comboTarget or entry.target or 0
                row.countText:SetText(FormatTierCountText(entry, bagCount, target))
                row.icon:SetTexture(entry.texture or "Interface\\Icons\\INV_Misc_Food_08")
                if index % 2 == 0 then
                    row.stripe:Show()
                else
                    row.stripe:Hide()
                end
                if not row.editBox:IsShown() then
                    row.countText:Show()
                end
                row:Show()
            else
                row.tierKind = nil
                local id = entry.itemID
                local name, link, quality, icon
                if FVID and FVID.GetItemFields then
                    name, link, quality, icon = FVID.GetItemFields(id)
                else
                    name, link, quality = GetItemInfoCompat(id)
                end
                local bagCount = entry.bagCount or GetChargeAwareCount(id)
                local target = entry.target or 0
                row.itemID = id
                row.link = link or entry.texture
                row.tierKind = nil
                row.restockSource = entry.restockSource
                row.vendorSold = entry.vendorSold == true
                row.vendorNotSold = entry.vendorNotSold == true
                row.merchantChecked = entry.merchantChecked == true
                row.countBank = entry.countBank == true
                row.bankCount = entry.bankCount or 0
                local displayName = name or entry.name or ("Item " .. id)
                if FVID and FVID.ApplyNameFontString then
                    FVID.ApplyNameFontString(row.nameText, id, displayName)
                    if entry.merchantChecked then
                        ApplyItemVendorNameStyle(row.nameText, entry, displayName)
                    end
                else
                    ApplyItemVendorNameStyle(row.nameText, entry, displayName)
                end
                row.countText:SetText(FormatItemCountText(entry, bagCount, target))
                if C_Item and C_Item.GetItemIconByID then
                    row.icon:SetTexture(icon or C_Item.GetItemIconByID(id))
                else
                    row.icon:SetTexture(entry.texture or icon or select(10, GetItemInfoCompat(id)))
                end
                if index % 2 == 0 then
                    row.stripe:Show()
                else
                    row.stripe:Hide()
                end
                if not row.editBox:IsShown() then
                    row.countText:Show()
                end
                row:Show()
            end
        else
            row.itemID = nil
            row.tierKind = nil
            row.restockSource = nil
            row.link = nil
            row:Hide()
        end
    end
end

function Panel:RefreshList()
    RefreshScrollList()
end

local function UpdateScrollChildWidth()
    if not scrollChild or not scrollFrame then
        return
    end
    local width = scrollFrame:GetWidth()
    if not width or width <= 0 then
        local inset = panelFrame and (panelFrame.Inset or panelFrame)
        width = inset and inset.GetWidth and inset:GetWidth()
    end
    scrollChild:SetWidth((width and width > 0) and width or 300)
end

QueryItems = function()
    if not panelFrame or not panelFrame:IsShown() then
        return
    end
    UpdateScrollChildWidth()
    local list = GetRestockList(true)
    local ready = true
    local FFWR = _G.FluxVendorFoodWaterRestock
    local List = _G.FluxRestockList
    for _, entry in ipairs(list) do
        if entry.isTierRestock and entry.tierKind then
            if entry.isCombatRestock then
                local FC = _G.FluxCombatItemRestock
                if FC and FC.GetCurrentCount then
                    entry.bagCount = FC.GetCurrentCount(entry.tierKind, true)
                end
                if FC and FC.ApplyVendorTierStatusToEntry and MerchantFrame and MerchantFrame:IsShown() then
                    FC.ApplyVendorTierStatusToEntry(entry, entry.tierKind)
                end
            else
                if FFWR and FFWR.GetTierCount then
                    entry.bagCount = FFWR.GetTierCount(entry.tierKind, true)
                end
                if FFWR and FFWR.ApplyVendorTierStatusToEntry and MerchantFrame and MerchantFrame:IsShown() then
                    FFWR.ApplyVendorTierStatusToEntry(entry, entry.tierKind)
                end
            end
            local Tiers = _G.FluxRestockTiers
            if entry.countBank then
                entry.bankCount = Tiers.GetBankCountForKind(entry.tierKind, true)
            end
            if List and List.EntryNeed and not entry.vendorUnavailable then
                entry.needed = List.EntryNeed(entry)
            end
        elseif entry.itemID and not IsItemInfoLoaded(entry.itemID) then
            if C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(entry.itemID)
            end
            ready = false
        end
    end
    if FFWR and FFWR.RefreshSharedComboNeededOnEntries then
        FFWR.RefreshSharedComboNeededOnEntries(list)
    end
    if spinner then
        spinner:SetShown(not ready)
    end
    Panel:RefreshList()
    if not ready and C_Timer and C_Timer.After then
        C_Timer.After(0.2, QueryItems)
    end
end

function Panel:OnTabSelected()
    Panel.InvalidateListCache()
    FV = _G.FluxVendorAuto
    if FV and FV.EnsureSettings then
        FV.EnsureSettings()
    end
    if hideNotSoldCheck and FV and FV.GetRestockShowNotSold then
        hideNotSoldCheck:SetChecked(FV.GetRestockShowNotSold())
    end
    if scrollFrame then
        scrollFrame:SetVerticalScroll(0)
    end
    local function refresh()
        if panelFrame and panelFrame:IsShown() then
            QueryItems()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, refresh)
    else
        refresh()
    end
end

local function OnItemDrop()
    local itemID = GetItemIdFromCursor()
    if not itemID or not FV then
        return
    end
    ClearCursor()
    local s = FV.EnsureSettings and FV.EnsureSettings()
    if s and s.restockItems and s.restockItems[itemID] then
        QueryItems()
        return
    end
    FV.AddRestockItem(itemID, 1)
    QueryItems()
end

local function SetupDragDrop(frame)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnReceiveDrag", OnItemDrop)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and select(1, GetCursorInfo()) == "item" then
            OnItemDrop()
        end
    end)
end

-- Coalesce bag-driven refreshes. A merchant-aware RefreshList rebuilds the full
-- restock list (merchant availability per entry), so firing it synchronously on
-- every BAG_UPDATE_DELAYED during a sell/buy burst stacks heavy passes.
local RESTOCK_REFRESH_DEBOUNCE_IDLE = 0.2
local RESTOCK_REFRESH_DEBOUNCE_BURST = 0.35
local refreshDebounceTimer = nil
local pendingRefreshAfterStorm = false
local purchaseStormPanelHooked = false

local function IsVendorBurstActive()
    return FluxVendorSession and FluxVendorSession.IsBurstActive and FluxVendorSession.IsBurstActive()
end

local function ShouldDeferHeavyPanelRefresh()
    local VS = FluxVendorSession
    return VS and VS.ShouldDeferHeavyBagWork and VS.ShouldDeferHeavyBagWork()
end

local function EnsureStormPanelHook()
    if purchaseStormPanelHooked then
        return
    end
    local VS = FluxVendorSession
    if not VS or not VS.OnPurchaseStormSettled then
        return
    end
    purchaseStormPanelHooked = true
    VS.OnPurchaseStormSettled(function()
        purchaseStormPanelHooked = false
        if not pendingRefreshAfterStorm then
            return
        end
        if ShouldDeferHeavyPanelRefresh() then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.15, EnsureStormPanelHook)
            else
                EnsureStormPanelHook()
            end
            return
        end
        pendingRefreshAfterStorm = false
        if panelFrame and panelFrame:IsShown() then
            Panel.RefreshCountsOnly()
        end
    end)
end

local function ScheduleRefreshList()
    if ShouldDeferHeavyPanelRefresh() then
        pendingRefreshAfterStorm = true
        EnsureStormPanelHook()
        return
    end
    if refreshDebounceTimer then
        return
    end
    if not (C_Timer and C_Timer.After) then
        if panelFrame and panelFrame:IsShown() then
            Panel:RefreshList()
        end
        return
    end
    local delay = IsVendorBurstActive() and RESTOCK_REFRESH_DEBOUNCE_BURST or RESTOCK_REFRESH_DEBOUNCE_IDLE
    refreshDebounceTimer = true
    C_Timer.After(delay, function()
        refreshDebounceTimer = nil
        if panelFrame and panelFrame:IsShown() then
            Panel.RefreshCountsOnly()
        end
    end)
end

local function SetupBagEvents()
    if bagEventsRegistered or not panelFrame then
        return
    end
    bagEventsRegistered = true
    panelFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    panelFrame:SetScript("OnEvent", function(_, event)
        if event == "BAG_UPDATE_DELAYED" and panelFrame:IsShown() then
            ScheduleRefreshList()
        end
    end)
end

local function CreatePanelFrame()
    if panelFrame then
        return panelFrame
    end

    panelFrame = CreateFrame("Frame", "FluxVendorRestockPanelFrame", MerchantFrame, "ButtonFrameTemplate")
    if _G.FluxVendorItemDisplay and _G.FluxVendorItemDisplay.IsPostDragonflight
        and _G.FluxVendorItemDisplay.IsPostDragonflight() then
        panelFrame:SetFrameStrata("HIGH")
    end
    panelFrame:Hide()
    local merchantUI = _G.FluxVendorAutoMerchantUI
    if merchantUI and merchantUI.HookPanelCloseButton then
        merchantUI.HookPanelCloseButton(panelFrame)
    end

    if panelFrame.TitleText then
        panelFrame.TitleText:SetText("RestockList")
    elseif panelFrame.TitleContainer and panelFrame.TitleContainer.TitleText then
        panelFrame.TitleContainer.TitleText:SetText("RestockList")
    end

    local portrait
    local portraitContainer
    if panelFrame.PortraitContainer and panelFrame.PortraitContainer.portrait then
        portraitContainer = panelFrame.PortraitContainer
        portrait = panelFrame.PortraitContainer.portrait
    elseif panelFrame.portrait then
        portrait = panelFrame.portrait
        portraitContainer = panelFrame
    end
    if portrait then
        local merchantUI = _G.FluxVendorAutoMerchantUI
        if merchantUI and merchantUI.ApplyRestockPortraitIcon then
            merchantUI.ApplyRestockPortraitIcon(portrait, portraitContainer or panelFrame)
        else
            portrait:SetTexture("Interface/Icons/INV_Misc_Bag_08")
        end
    end

    scrollFrame = CreateFrame("ScrollFrame", nil, panelFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panelFrame.Inset or panelFrame, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", panelFrame.Inset or panelFrame, "BOTTOMRIGHT", -28, FOOTER_RESERVE)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() or 300)
    scrollChild:SetHeight(ROW_HEIGHT * VISIBLE_ROWS)
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local step = ROW_HEIGHT * 3
        local list = GetRestockList()
        local maxScroll = math.max(0, (#list * ROW_HEIGHT) - self:GetHeight())
        local newScroll = math.min(maxScroll, math.max(0, current - delta * step))
        self:SetVerticalScroll(newScroll)
        RefreshScrollList()
    end)

    scrollFrame:SetScript("OnScrollRangeChanged", function()
        RefreshScrollList()
    end)

    local hint = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", panelFrame.Inset or panelFrame, "BOTTOMLEFT", 8, 10)
    hint:SetPoint("BOTTOMRIGHT", panelFrame.Inset or panelFrame, "BOTTOMRIGHT", -8, 10)
    hint:SetWordWrap(true)
    hint:SetNonSpaceWrap(false)
    hint:SetJustifyH("CENTER")
    hint:SetText("Drag to add. Left-click sets target. Right-click clears target or removes items.")

    hideNotSoldCheck = CreateFrame("CheckButton", nil, panelFrame, "UICheckButtonTemplate")
    hideNotSoldCheck:SetSize(22, 22)
    hideNotSoldCheck:SetPoint("BOTTOMLEFT", panelFrame.Inset or panelFrame, "BOTTOMLEFT", 6, 28)
    hideNotSoldCheck.text = hideNotSoldCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hideNotSoldCheck.text:SetPoint("LEFT", hideNotSoldCheck, "RIGHT", 4, 0)
    hideNotSoldCheck.text:SetText("Show items not sold here")
    hideNotSoldCheck:SetScript("OnClick", function(self)
        FV = FV or _G.FluxVendorAuto
        if FV and FV.SetRestockShowNotSold then
            FV.SetRestockShowNotSold(self:GetChecked())
        end
        Panel.InvalidateListCache()
        QueryItems()
    end)
    hideNotSoldCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Show items not sold here", 1, 1, 1)
        GameTooltip:AddLine(
            "When checked, restock rows the current vendor does not sell are shown below sold rows.",
            0.7, 0.7, 0.7, true
        )
        GameTooltip:Show()
    end)
    hideNotSoldCheck:SetScript("OnLeave", GameTooltip_Hide)
    FV = FV or _G.FluxVendorAuto
    if FV and FV.GetRestockShowNotSold then
        hideNotSoldCheck:SetChecked(FV.GetRestockShowNotSold())
    end

    if LoadingSpinnerTemplate then
        spinner = CreateFrame("Frame", nil, panelFrame, "LoadingSpinnerTemplate")
        spinner:SetPoint("CENTER", panelFrame.Inset or panelFrame, "CENTER", 0, 0)
        if spinner.Anim then
            spinner.Anim:Play()
        end
        spinner:Hide()
    end

    SetupDragDrop(panelFrame)
    SetupDragDrop(scrollFrame)
    SetupDragDrop(scrollChild)
    SetupBagEvents()

    panelFrame:SetScript("OnShow", function()
        Panel:OnTabSelected()
    end)

    panelFrame:SetScript("OnSizeChanged", function()
        UpdateScrollChildWidth()
        if panelFrame:IsShown() then
            Panel:RefreshList()
        end
    end)

    panelFrame:SetScript("OnHide", function()
        for i = 1, #listButtons do
            local row = listButtons[i]
            if row and row.editBox and row.editBox:IsShown() then
                row.editBox:Hide()
                if row.countText then
                    row.countText:Show()
                end
            end
        end
    end)

    return panelFrame
end

function Panel:Init()
    if not MerchantFrame then
        return
    end
    FV = FV or _G.FluxVendorAuto
    CreatePanelFrame()

    if panelFrame and _G.FluxVendorItemDisplay and _G.FluxVendorItemDisplay.IsPreDragonflight
        and _G.FluxVendorItemDisplay.IsPreDragonflight() then
        panelFrame:SetFrameStrata(MerchantFrame:GetFrameStrata())
    end

    if panelFrame then
        if panelFrame.TitleText then
            panelFrame.TitleText:SetText("RestockList")
        elseif panelFrame.TitleContainer and panelFrame.TitleContainer.TitleText then
            panelFrame.TitleContainer.TitleText:SetText("RestockList")
        end
    end

    if not merchantTab then
        merchantTab = LibStub("SecureTabs-2.0"):Add(MerchantFrame)
        merchantTab.frame = panelFrame
    end
    merchantTab.OnSelect = function()
        if FluxVendorAutoMerchantUI and FluxVendorAutoMerchantUI.OnBuyTabHidden then
            FluxVendorAutoMerchantUI.OnBuyTabHidden()
        end
        Panel:OnTabSelected()
    end
    merchantTab:SetText("Restock")
    local FVID = _G.FluxVendorItemDisplay
    if FVID and FVID.ApplyPreDFMerchantSecureTabLayers then
        FVID.ApplyPreDFMerchantSecureTabLayers(MerchantFrame)
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if MerchantFrame then
            Panel:Init()
        end
    end
end)

