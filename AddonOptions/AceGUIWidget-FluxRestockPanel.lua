-- AceGUI: icon grid for vendor restock targets (Vendor & restock tab). No scroll - grid grows with content.

local Type, Version = "FluxRestockPanel", 31
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
    return
end

local function Inv()
    return (_G.FluxRestock and _G.FluxRestock.Inv) or _G.FluxInv
end

local function GetGridUI()
    return _G.FluxConsumablesGridUI
end

local GridUI = GetGridUI()
local CELL_MIN = (GridUI and GridUI.CELL_MIN) or 48
local CELL_MAX = (GridUI and GridUI.CELL_MAX) or 80
local CELL = (GridUI and GridUI.CELL) or CELL_MIN
local TEX = (GridUI and GridUI.TEX) or 28
local ROW_H = (GridUI and GridUI.ROW_H) or 58
local GAP = 0
local SECTION_GAP = 10
local GRID_INSET = 7
local MIN_DROP_H = 46
local PRESET_ROW_H = 24
local THRESHOLD_ROW_H = 24
local CONSUMABLES_BTN_W = 50
local CONSUMABLES_EDIT_W = 40
local DEFAULT_CONTENT_W = 420
local BAG_REFRESH_DEBOUNCE = 0.25
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
local wipe = table.wipe or wipe
local Timer = C_Timer
local DROP_BACKDROP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local activeWidget
local pendingGridRebuild = false
local pendingStructureRefresh = false
local pendingRebuildWidget
local panelRebuildQueued = false
local gridRebuildTimer
local bagRefreshTimerHandle
local pendingBagCellAfterStorm = false
local pendingBagCellAfterBankOrganize = false
local purchaseStormBagCellHooked = false
local bankOrganizeBagCellHooked = false
local bankRestockBagCellHooked = false
local WIDTH_REBUILD_COOLDOWN = 0.5
local lastFullBuildTime = 0
local panelEngaged = false
local INVENTORY_LISTENER_KEY = "FluxRestockOptionsPanel"
local cellsByItemId = {}
local cellsByTierKind = {}
local pendingCountRefreshCtx = nil
local optionsListForceRefresh = false

local function ProfInc(key, n)
    local prof = _G.FluxBagLagProf
    if prof and prof.Inc then
        prof.Inc(key, n)
    end
end

local function IsOptionsWindowOpen()
    local f = _G.FluxUIOptionsFrame or _G.FluxUIConfigFrame
    return f and f.IsShown and f:IsShown()
end

local function IsPanelAttached(widget)
    widget = widget or activeWidget
    return panelEngaged and widget ~= nil and activeWidget == widget
end

local function IsPanelActive(widget)
    if not IsPanelAttached(widget) then
        return false
    end
    if not IsOptionsWindowOpen() then
        return false
    end
    widget = widget or activeWidget
    if not widget or not widget.frame then
        return false
    end
    return widget.frame:IsVisible()
end

local function IsPanelOpenInOptions(widget)
    return IsPanelAttached(widget) and IsOptionsWindowOpen()
end

local function InvalidateOptionsListCache()
    local FV = _G.FluxVendorAuto
    if FV and FV.InvalidateRestockOptionsPanelCache then
        FV.InvalidateRestockOptionsPanelCache()
    end
end

local function ClearCellMaps()
    wipe(cellsByItemId)
    wipe(cellsByTierKind)
end

local function RegisterCellInMaps(cell)
    if not cell then
        return
    end
    if cell._itemId then
        cellsByItemId[cell._itemId] = cell
    end
    if cell._tierKind then
        cellsByTierKind[cell._tierKind] = cell
    end
end

local RefreshPanel
local RequestParentLayout
local ScheduleBagCellRefresh
local SchedulePanelRebuild

local function UnregisterInventoryListener()
    local inv = Inv()
    if inv and inv.UnregisterListener then
        pcall(inv.UnregisterListener, INVENTORY_LISTENER_KEY)
    end
end

local function OnRestockOptionsCountPulse(ctx)
    if not IsPanelActive() then
        return
    end
    pendingCountRefreshCtx = ctx
    local regions = ctx and ctx.regions
    if regions and regions.spells then
        optionsListForceRefresh = true
        pendingStructureRefresh = true
        SchedulePanelRebuild(activeWidget, 0)
        return
    end
    ScheduleBagCellRefresh()
end

local function EnsureInventoryListener()
    local inv = Inv()
    if not inv or not inv.RegisterListener then
        return
    end
    inv.RegisterListener(INVENTORY_LISTENER_KEY, OnRestockOptionsCountPulse, {
        tier = "light",
        regions = { "bags", "bank", "warband", "spells" },
    })
end

local function ShouldDeferBankOrganizeBagCellRefresh()
    local BR = _G.FluxBankRestock
    if BR and BR.IsRunning and BR.IsRunning() then
        return true
    end
    local BC = _G.FluxRestockBankCompat
    return BC and BC.IsBankOrganizeSilenceActive and BC.IsBankOrganizeSilenceActive()
end

local function EnsureBankRestockBagCellHook()
    if bankRestockBagCellHooked then
        return
    end
    local BC = _G.FluxRestockBankCompat
    if not BC or not BC.OnBankRestockSessionEnd then
        return
    end
    bankRestockBagCellHooked = true
    BC.OnBankRestockSessionEnd(function()
        if pendingBagCellAfterBankOrganize and IsPanelActive() and _G.FluxRestockPanel_RefreshCellData then
            pendingBagCellAfterBankOrganize = false
            pcall(_G.FluxRestockPanel_RefreshCellData)
        end
    end)
end

local function EnsureBankOrganizeBagCellHook()
    if bankOrganizeBagCellHooked then
        return
    end
    local BC = _G.FluxRestockBankCompat
    if not BC or not BC.OnBankOrganizeSettled then
        return
    end
    bankOrganizeBagCellHooked = true
    BC.OnBankOrganizeSettled(function()
        if pendingBagCellAfterBankOrganize and IsPanelActive() and _G.FluxRestockPanel_RefreshCellData then
            pendingBagCellAfterBankOrganize = false
            pcall(_G.FluxRestockPanel_RefreshCellData)
        end
    end)
end

local function ShouldDeferHeavyBagCellRefresh()
    if ShouldDeferBankOrganizeBagCellRefresh() then
        return true
    end
    local VS = _G.FluxVendorSession
    return VS and VS.ShouldDeferHeavyBagWork and VS.ShouldDeferHeavyBagWork()
end

local function EnsureStormBagCellHook()
    if purchaseStormBagCellHooked then
        return
    end
    local VS = _G.FluxVendorSession
    if not VS or not VS.OnPurchaseStormSettled then
        return
    end
    purchaseStormBagCellHooked = true
    VS.OnPurchaseStormSettled(function()
        if pendingBagCellAfterStorm and IsPanelActive() and _G.FluxRestockPanel_RefreshCellData then
            pendingBagCellAfterStorm = false
            pcall(_G.FluxRestockPanel_RefreshCellData)
        end
    end)
end

local TIER_KIND_LABELS = {
    food = "Food",
    water = "Water",
    bandage = "Bandage",
    healPotion = "Healing potion",
    manaPotion = "Mana potion",
}

local ConfirmResetTierReference

local function IsAnyCellEditing(widget)
    widget = widget or activeWidget
    if not widget or not widget._cells then
        return false
    end
    for i = 1, #widget._cells do
        local cell = widget._cells[i]
        if cell.editBox and cell.editBox:IsShown() then
            return true
        end
    end
    return false
end

local function IsSpellReagentItem(itemId)
    local FV = _G.FluxVendorAuto
    if FV and FV.IsSpellReagentItem then
        return FV.IsSpellReagentItem(itemId)
    end
    return FV and FV.IsKnownSpellReagentItem and FV.IsKnownSpellReagentItem(itemId) or false
end

local function IsRightClick(button)
    return button == "RightButton" or button == "RightButtonUp"
end

local function CancelPanelTimers()
    if gridRebuildTimer then
        pcall(function()
            gridRebuildTimer:Cancel()
        end)
        gridRebuildTimer = nil
    end
    if bagRefreshTimerHandle then
        pcall(function()
            bagRefreshTimerHandle:Cancel()
        end)
        bagRefreshTimerHandle = nil
    end
    pendingGridRebuild = false
    pendingStructureRefresh = false
    pendingRebuildWidget = nil
    panelRebuildQueued = false
    pendingCountRefreshCtx = nil
end

local function OnPanelHiddenCleanup(fullClose)
    CancelPanelTimers()
    if fullClose then
        panelEngaged = false
        activeWidget = nil
        pendingStructureRefresh = false
        pendingRebuildWidget = nil
        panelRebuildQueued = false
        ClearCellMaps()
    end
    UnregisterInventoryListener()
    local List = _G.FluxRestockList
    if List and List.CancelSpellReagentCacheWarm then
        pcall(List.CancelSpellReagentCacheWarm)
    end
    local FT = _G.FluxRestockTiers
    if FT and FT.CancelBackgroundWork then
        pcall(FT.CancelBackgroundWork)
    end
end

function _G.FluxRestockPanel_OnOptionsClosed()
    OnPanelHiddenCleanup(true)
end

local function IsWidgetLive(widget)
    if not widget or not widget._content then
        return false
    end
    if AceGUI and AceGUI.IsReleasing and AceGUI:IsReleasing(widget) then
        return false
    end
    return panelEngaged and activeWidget == widget
end

local function RunPanelRebuild(widget)
    widget = widget or activeWidget or pendingRebuildWidget
    if not widget then
        pendingStructureRefresh = true
        return false
    end
    if not IsWidgetLive(widget) then
        pendingStructureRefresh = true
        pendingRebuildWidget = widget
        return false
    end
    if IsAnyCellEditing(widget) then
        pendingGridRebuild = true
        pendingRebuildWidget = widget
        return false
    end
    if pendingStructureRefresh then
        optionsListForceRefresh = true
        InvalidateOptionsListCache()
    end
    pendingGridRebuild = false
    pendingStructureRefresh = false
    pendingRebuildWidget = nil
    ProfInc("restockPanel:ScheduleBuildGrid", 1)
    RefreshPanel(widget)
    RequestParentLayout(widget)
    return true
end

function SchedulePanelRebuild(widget, delay)
    widget = widget or activeWidget or pendingRebuildWidget
    if not widget then
        pendingStructureRefresh = true
        return
    end
    pendingRebuildWidget = widget
    if IsAnyCellEditing(widget) then
        pendingGridRebuild = true
        return
    end
    if gridRebuildTimer then
        pcall(function()
            gridRebuildTimer:Cancel()
        end)
        gridRebuildTimer = nil
    end
    local function run()
        gridRebuildTimer = nil
        panelRebuildQueued = false
        RunPanelRebuild(pendingRebuildWidget or widget)
    end
    delay = tonumber(delay) or 0
    if delay > 0 and Timer and Timer.NewTimer then
        gridRebuildTimer = Timer.NewTimer(delay, run)
        return
    end
    if Timer and Timer.After then
        if panelRebuildQueued then
            return
        end
        panelRebuildQueued = true
        Timer.After(0, run)
        return
    end
    run()
end

local ScheduleBuildGrid = SchedulePanelRebuild

RequestParentLayout = function(widget)
    if not widget or not Timer or not Timer.After or widget._fluxParentLayoutPending then
        return
    end
    widget._fluxParentLayoutPending = true
    Timer.After(0, function()
        widget._fluxParentLayoutPending = nil
        if not widget.parent then
            return
        end
        local p = widget.parent
        local depth = 0
        while p and depth < 16 do
            if p.DoLayout then
                pcall(p.DoLayout, p)
                return
            end
            p = p.parent
            depth = depth + 1
        end
    end)
end

local function ApplyWidgetLayoutHeight(widget, contentHeight)
    if not widget then
        return
    end
    contentHeight = math.max(tonumber(contentHeight) or MIN_DROP_H, MIN_DROP_H)
    local totalH = contentHeight + 4
    if widget._fluxLastContentHeight == totalH then
        return
    end
    widget._fluxLastContentHeight = totalH
    widget._fluxInternalLayout = true
    widget:SetHeight(totalH)
    if widget.frame then
        widget.frame:SetHeight(totalH)
    end
    widget._fluxInternalLayout = nil
    RequestParentLayout(widget)
end

local function GetEffectiveContentWidth(widget)
    local f = widget and widget.frame
    if not f then
        return DEFAULT_CONTENT_W
    end
    local w = f.width or f:GetWidth() or 0
    if not w or w <= 0 then
        w = DEFAULT_CONTENT_W
    end
    return math.max(w - 16, 220)
end

local function GetItemCountCompat(itemId)
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemId, false, true, true) or 0
    end
    if GetItemCount then
        return GetItemCount(itemId, false, true, true) or 0
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

local function GetSnapshotBagCount(itemId)
    local inv = Inv()
    if not inv or not inv.GetCount then
        return GetItemCountCompat(itemId)
    end
    if IsChargeItem(itemId) then
        return inv.GetCount(itemId, {
            charges = true,
            bags = true,
            bank = false,
            warband = false,
            equipped = false,
        }) or 0
    end
    return inv.GetCount(itemId) or 0
end

local function GetChargeAwareCount(itemId)
    if IsChargeItem(itemId) then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.GetItemChargeCount then
            return Cons.GetItemChargeCount(itemId)
        end
    end
    return GetSnapshotBagCount(itemId)
end

local function ResolveRestockSource(itemId, cell)
    if cell and cell._isChronoboon then
        return "consumable"
    end
    if cell and cell._restockSource then
        return cell._restockSource
    end
    local Cons = _G.FluxNCConsumables
    if Cons and Cons.IsRestockUIItem and Cons.IsRestockUIItem(itemId) then
        return "consumable"
    end
    if IsSpellReagentItem(itemId) then
        return "spellReagent"
    end
    return "manual"
end

local function GetRestockTarget(itemId, cell)
    itemId = tonumber(itemId)
    if not itemId then
        return 0
    end
    local source = ResolveRestockSource(itemId, cell)
    if source == "consumable" then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.GetPresetRestockTarget then
            return Cons.GetPresetRestockTarget(itemId) or 0
        end
        return 0
    end
    local FV = _G.FluxVendorAuto
    if not FV or not FV.EnsureSettings then
        return 0
    end
    local s = FV.EnsureSettings()
    local d = s.restockItems and s.restockItems[itemId]
    return (d and d.targetQuantity) or 0
end

local function GetFoodWaterRestockTarget(tierKind)
    local FV = _G.FluxVendorAuto
    if not FV or not FV.EnsureSettings then
        return 0
    end
    local s = FV.EnsureSettings()
    local fw = s.restockFoodWater or {}
    if tierKind == "food" then
        return tonumber(fw.foodTarget) or 0
    elseif tierKind == "water" then
        return tonumber(fw.waterTarget) or 0
    end
    return 0
end

local function IsCombatTierKind(tierKind)
    return tierKind == "bandage" or tierKind == "healPotion" or tierKind == "manaPotion"
end

local function GetTierRestockTarget(tierKind)
    if tierKind == "food" or tierKind == "water" then
        return GetFoodWaterRestockTarget(tierKind)
    end
    if IsCombatTierKind(tierKind) then
        local FC = _G.FluxCombatItemRestock
        return FC and FC.GetTarget and FC.GetTarget(tierKind) or 0
    end
    return 0
end

local function CommitFoodWaterRestockTarget(tierKind, quantity)
    local FV = _G.FluxVendorAuto
    if FV and FV.SetRestockFoodWaterTarget then
        FV.SetRestockFoodWaterTarget(tierKind, quantity, true)
    end
end

local function CommitTierRestockTarget(tierKind, quantity)
    if tierKind == "food" or tierKind == "water" then
        CommitFoodWaterRestockTarget(tierKind, quantity)
        return
    end
    local FV = _G.FluxVendorAuto
    if IsCombatTierKind(tierKind) and FV and FV.SetRestockCombatTarget then
        FV.SetRestockCombatTarget(tierKind, quantity, true)
    end
end

local function LayoutGrid(box, slots, cols)
    local gridUI = GetGridUI()
    if gridUI and gridUI.LayoutFlowGrid then
        return gridUI.LayoutFlowGrid(box, slots)
    end
    local boxW = box:GetWidth()
    if not boxW or boxW <= 0 then
        boxW = DEFAULT_CONTENT_W
    end
    local innerW = math.max(boxW - GRID_INSET * 2, CELL_MIN)
    local x = GRID_INSET
    local y = -GRID_INSET
    local rowMaxH = ROW_H
    for _, cell in ipairs(slots) do
        local w = cell._layoutWidth or CELL_MIN
        local h = cell._layoutHeight or ROW_H
        if x > GRID_INSET and (x - GRID_INSET + w) > innerW then
            y = y - rowMaxH
            x = GRID_INSET
            rowMaxH = h
        else
            rowMaxH = math.max(rowMaxH, h)
        end
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", box, "TOPLEFT", x, y)
        cell:SetHeight(h)
        x = x + w + GAP
    end
    if #slots == 0 then
        return MIN_DROP_H
    end
    return math.max(MIN_DROP_H, math.abs(y) + rowMaxH + GRID_INSET)
end

local function GetTierBankCount(tierKind)
    if tierKind == "food" or tierKind == "water" then
        local FFWR = _G.FluxVendorFoodWaterRestock
        if FFWR and FFWR.CountBankForRestockKind then
            local n = FFWR.CountBankForRestockKind(tierKind, 0) or 0
            if n > 0 then
                return n
            end
        end
    elseif IsCombatTierKind(tierKind) then
        local FC = _G.FluxCombatItemRestock
        if FC and FC.GetBankCountForKind then
            local n = FC.GetBankCountForKind(tierKind) or 0
            if n > 0 then
                return n
            end
        end
    end
    local T = _G.FluxRestockTiers
    if T and T.GetBankCountForKind then
        return T.GetBankCountForKind(tierKind) or 0
    end
    return 0
end

local function GetRestockCountColor(combined, target)
    if target <= 0 then
        return 1, 1, 1
    end
    if combined == 0 then
        return 1, 0.27, 0.27
    end
    if combined < target then
        return 1, 1, 0
    end
    return 0, 1, 0
end

local function FormatCellCountText(have, bankCount, tgt, countBank)
    local gridUI = GetGridUI()
    if gridUI and gridUI.FormatCellCountText then
        return gridUI.FormatCellCountText(have, bankCount, tgt, countBank)
    end
    local combined = have + (bankCount or 0)
    local r, g, b = GetRestockCountColor(combined, tgt)
    local hc = string.format("|cff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    local tc = "|cff888888"
    local main = hc .. tostring(have) .. "|r" .. tc .. "/" .. tostring(tgt) .. "|r"
    if countBank or (tonumber(bankCount) or 0) > 0 then
        return main .. "\n|cff7fbfff+" .. tostring(bankCount or 0) .. "|r"
    end
    return main
end

local function FormatTierCellCountText(have, bankCount, tgt, countBank, tierKind)
    local gridUI = GetGridUI()
    if gridUI and gridUI.FormatTierCellCountText then
        return gridUI.FormatTierCellCountText(have, bankCount, tgt, countBank, tierKind)
    end
    local Tiers = _G.FluxRestockTiers
    if tierKind and Tiers and Tiers.IsTierCountPending and Tiers.IsTierCountPending(tierKind) then
        local tc = "|cff888888"
        local main = "|cff888888...|r" .. tc .. "/" .. tostring(tgt) .. "|r"
        if countBank or (tonumber(bankCount) or 0) > 0 then
            return main .. "\n|cff7fbfff+" .. tostring(bankCount or 0) .. "|r"
        end
        return main
    end
    return FormatCellCountText(have, bankCount, tgt, countBank)
end

local function RelayoutCellSection(cell, width)
    local section = cell and (cell._fluxSection or cell._relayoutSection)
    if not section then
        return
    end
    local gridUI = GetGridUI()
    if gridUI and gridUI.RelayoutSection then
        gridUI.RelayoutSection(section, width)
    else
        SetBoxItems(section, width or DEFAULT_CONTENT_W)
    end
end

local function GetChargeAwareBankCount(itemId)
    local gridUI = GetGridUI()
    if gridUI and gridUI.GetChargeAwareBankCount then
        return gridUI.GetChargeAwareBankCount(itemId)
    end
    itemId = tonumber(itemId)
    if not itemId then
        return 0
    end
    local chargeOpts = IsChargeItem(itemId) and { charges = true } or nil
    local bank = Inv() and Inv().Bank
    if bank and bank.GetCount then
        return bank.GetCount(itemId, chargeOpts) or 0
    end
    local BC = _G.FluxRestockBankCompat
    return (BC and BC.GetCachedBankCount and BC.GetCachedBankCount(itemId)) or 0
end

local function ApplyCellCountsFromEntry(cell, entry)
    if not cell or not cell._countStr or not entry then
        return false
    end
    local have = entry.bagCount
    if cell._itemId and not cell._tierKind then
        have = GetChargeAwareCount(cell._itemId)
    elseif have == nil then
        return false
    end
    local tgt = tonumber(entry.target)
    if tgt == nil then
        if cell._tierKind then
            tgt = GetTierRestockTarget(cell._tierKind)
        elseif cell._itemId then
            tgt = GetRestockTarget(cell._itemId, cell)
        else
            tgt = 0
        end
    end
    local countBank = entry.countBank == true
    local bankCount = 0
    if cell._isChronoboon then
        local Cons = _G.FluxNCConsumables
        bankCount = (Cons and Cons.GetChronoboonBankCount and Cons.GetChronoboonBankCount()) or 0
    elseif cell._tierKind then
        bankCount = GetTierBankCount(cell._tierKind)
    elseif cell._itemId then
        bankCount = GetChargeAwareBankCount(cell._itemId)
    else
        bankCount = tonumber(entry.bankCount) or 0
    end
    cell._countBank = countBank
    local gridUI = GetGridUI()
    if gridUI and gridUI.FitCellCountDisplay then
        gridUI.FitCellCountDisplay(cell, have, bankCount, tgt, countBank, cell._tierKind)
    elseif gridUI and gridUI.ApplyCellCountDisplay then
        gridUI.ApplyCellCountDisplay(cell, have, bankCount, tgt, countBank, cell._tierKind)
    else
        cell._countStr:SetText(FormatTierCellCountText(have, bankCount, tgt, countBank, cell._tierKind))
    end
    if cell._refreshBankBtn then
        cell._refreshBankBtn()
    end
    return true
end

local function RefreshOneCell(cell, fullTierCounts, skipRelayout)
    if not cell._countStr then
        return
    end
    local have, tgt, countBank, bankCount = 0, 0, false, 0
    if cell._tierKind then
        if fullTierCounts then
            if cell._tierKind == "food" or cell._tierKind == "water" then
                local FFWR = _G.FluxVendorFoodWaterRestock
                have = FFWR and FFWR.GetTierCount and FFWR.GetTierCount(cell._tierKind, false) or 0
            elseif IsCombatTierKind(cell._tierKind) then
                local FC = _G.FluxCombatItemRestock
                have = FC and FC.GetCurrentCount and FC.GetCurrentCount(cell._tierKind) or 0
            end
        else
            local FT = _G.FluxRestockTiers
            if FT and FT.GetTooltipDisplay then
                have = FT.GetTooltipDisplay(cell._tierKind).count or 0
            end
        end
        tgt = GetTierRestockTarget(cell._tierKind)
        local FV = _G.FluxVendorAuto
        countBank = FV and FV.GetTierCountBankFlag and FV.GetTierCountBankFlag(cell._tierKind) == true
        bankCount = GetTierBankCount(cell._tierKind)
        cell._countBank = countBank
    elseif cell._itemId then
        local Cons = _G.FluxNCConsumables
        if cell._isChronoboon and Cons and Cons.GetChronoboonBagCount then
            have = Cons.GetChronoboonBagCount()
        else
            have = GetChargeAwareCount(cell._itemId)
        end
        tgt = GetRestockTarget(cell._itemId, cell)
        local FV = _G.FluxVendorAuto
        if FV and FV.GetRestockItemFlags then
            countBank = FV.GetRestockItemFlags(cell._itemId).countBank == true
        end
        if cell._isChronoboon and Cons and Cons.GetChronoboonBankCount then
            bankCount = Cons.GetChronoboonBankCount()
        else
            bankCount = GetChargeAwareBankCount(cell._itemId)
        end
        cell._countBank = countBank
    else
        return
    end
    local gridUI = GetGridUI()
    if gridUI and gridUI.FitCellCountDisplay then
        gridUI.FitCellCountDisplay(cell, have, bankCount, tgt, countBank, cell._tierKind)
    elseif gridUI and gridUI.ApplyCellCountDisplay then
        gridUI.ApplyCellCountDisplay(cell, have, bankCount, tgt, countBank, cell._tierKind)
    else
        cell._countStr:SetText(FormatTierCellCountText(have, bankCount, tgt, countBank, cell._tierKind))
    end
    if cell._refreshBankBtn then
        cell._refreshBankBtn()
    end
    if not skipRelayout then
        RelayoutCellSection(cell)
    end
end

local function ReleaseCellFrame(cell)
    if not cell then
        return
    end
    cell:SetScript("OnEnter", nil)
    cell:SetScript("OnLeave", nil)
    cell:SetScript("OnClick", nil)
    cell:SetScript("OnReceiveDrag", nil)
    cell:SetScript("OnMouseUp", nil)
    if cell.editBox then
        cell.editBox:SetScript("OnEnterPressed", nil)
        cell.editBox:SetScript("OnEscapePressed", nil)
        cell.editBox:SetScript("OnEditFocusLost", nil)
    end
    if cell._bankBtn then
        cell._bankBtn:SetScript("OnClick", nil)
        cell._bankBtn:SetScript("OnEnter", nil)
        cell._bankBtn:SetScript("OnLeave", nil)
    end
    if cell._resetBtn then
        cell._resetBtn:SetScript("OnClick", nil)
        cell._resetBtn:SetScript("OnEnter", nil)
        cell._resetBtn:SetScript("OnLeave", nil)
    end
    cell:SetParent(nil)
    cell:Hide()
end

local function ClearSectionCells(section)
    if not section or not section.cells then
        return
    end
    for i = 1, #section.cells do
        ReleaseCellFrame(section.cells[i])
    end
    wipe(section.cells)
end

local function FlushPendingGridRebuild()
    if pendingGridRebuild or pendingStructureRefresh then
        SchedulePanelRebuild(pendingRebuildWidget or activeWidget, 0)
    end
end

local function CommitRestockTarget(itemId, quantity, cell)
    itemId = tonumber(itemId)
    if not itemId then
        return
    end
    quantity = tonumber(quantity) or 0
    local source = ResolveRestockSource(itemId, cell)
    if source == "consumable" then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.SetPresetRestockTarget then
            Cons.SetPresetRestockTarget(itemId, quantity, true)
        end
        return
    end
    local FV = _G.FluxVendorAuto
    if not FV then
        return
    end
    if source == "spellReagent" then
        if FV.SetRestockTarget then
            FV.SetRestockTarget(itemId, quantity, true)
        end
        return
    end
    if quantity > 0 then
        if FV.AddRestockItem then
            FV.AddRestockItem(itemId, quantity, true)
        end
        return
    end
    if FV.RemoveRestockItem then
        FV.RemoveRestockItem(itemId, true)
    end
end

local function CallMerchantRefresh(opts)
    local FV = _G.FluxVendorAuto
    if FV and FV.RefreshMerchantOptionsCheckboxes then
        pcall(FV.RefreshMerchantOptionsCheckboxes, opts)
    end
    if _G.FluxNCTeleportPortal and _G.FluxNCTeleportPortal.RefreshAllReagentDisplays then
        pcall(_G.FluxNCTeleportPortal.RefreshAllReagentDisplays)
    end
end

local function NotifyRestockDataChanged()
    if not IsPanelActive() then
        CallMerchantRefresh({
            skipRestockPanelRebuild = true,
            skipOptionsNotify = true,
        })
        return
    end
    if _G.FluxRestockPanel_RefreshCellData then
        pcall(_G.FluxRestockPanel_RefreshCellData)
    end
    CallMerchantRefresh({
        skipRestockPanelRebuild = true,
        skipOptionsNotify = true,
    })
end

if StaticPopupDialogs and not StaticPopupDialogs["FLUX_RESTOCK_RESET_TIER"] then
    StaticPopupDialogs["FLUX_RESTOCK_RESET_TIER"] = {
        text = "Forget the saved tier baseline for %s and clear auto-junk marks for that category? Restock target and bank count are unchanged.",
        button1 = YES,
        button2 = NO,
        OnAccept = function(self)
            local tierKind = self.data
            local FV = _G.FluxVendorAuto
            if tierKind and FV and FV.ResetTierReference then
                FV.ResetTierReference(tierKind, true)
            end
            NotifyRestockDataChanged()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function ConfirmResetTierReference(tierKind)
    if not tierKind or not StaticPopup_Show then
        return
    end
    local label = TIER_KIND_LABELS[tierKind] or tierKind
    StaticPopup_Show("FLUX_RESTOCK_RESET_TIER", label, nil, tierKind)
end

local function NotifyRestockStructureChanged(widget)
    optionsListForceRefresh = true
    SchedulePanelRebuild(widget, 0)
    CallMerchantRefresh({
        skipRestockPanelRebuild = true,
        skipOptionsNotify = true,
    })
end

local function RemoveNonSpellRestock(itemId, cell)
    itemId = tonumber(itemId)
    if not itemId then
        return
    end
    local source = ResolveRestockSource(itemId, cell)
    if source == "consumable" then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.SetPresetRestockTarget then
            Cons.SetPresetRestockTarget(itemId, 0)
        end
        NotifyRestockDataChanged()
    elseif source == "spellReagent" then
        local FV = _G.FluxVendorAuto
        if FV and FV.DismissRestockReagent then
            FV.DismissRestockReagent(itemId)
        elseif FV and FV.SetRestockTarget then
            FV.SetRestockTarget(itemId, 0, true)
        end
        NotifyRestockStructureChanged()
    else
        local FV = _G.FluxVendorAuto
        if FV and FV.RemoveRestockItem then
            FV.RemoveRestockItem(itemId, true)
        end
        NotifyRestockStructureChanged()
    end
end

local function AppendRestockTooltipHints(itemId, cell, entry)
    GameTooltip:AddLine(" ")
    local source = ResolveRestockSource(itemId, cell)
    if source == "spellReagent" or source == "consumable" then
        GameTooltip:AddLine("|cffaaaaaaClick:|r set restock target", 0.65, 0.7, 0.75, true)
        if source == "consumable" then
            GameTooltip:AddLine("|cffaaaaaaRight-click:|r remove from preset", 0.65, 0.7, 0.75, true)
            GameTooltip:AddLine("|cffaaaaaaDrag:|r reorder priority", 0.65, 0.7, 0.75, true)
        end
    else
        GameTooltip:AddLine("|cffaaaaaaLeft-click:|r set target", 0.65, 0.7, 0.75, true)
        GameTooltip:AddLine("|cffaaaaaaRight-click:|r remove", 0.65, 0.7, 0.75, true)
    end
    if entry and entry.merchantChecked then
        GameTooltip:AddLine(" ")
        if entry.vendorNotSold then
            GameTooltip:AddLine("This vendor does not sell this item.", 1, 0.35, 0.35, true)
        elseif entry.vendorSold then
            GameTooltip:AddLine("This vendor sells this item.", 0.35, 1, 0.35, true)
        end
    end
end

local function AppendSpellReagentTooltipLines(owner, itemId)
    if not IsSpellReagentItem(itemId) then
        return
    end
    local FR = _G.FluxRestock
    if not FR or not FR.AppendSpellsUsingReagentToTooltip then
        return
    end
    local function append()
        if owner and GameTooltip.GetOwner and GameTooltip:GetOwner() ~= owner then
            return
        end
        FR.AppendSpellsUsingReagentToTooltip(GameTooltip, itemId)
        GameTooltip:Show()
    end
    if Timer and Timer.After then
        Timer.After(0, append)
    else
        append()
    end
end

local function ShowCellTooltip(cell, entry, itemId)
    if not GameTooltip then
        return
    end
    local FVID = _G.FluxVendorItemDisplay
    if FVID and FVID.ShowTooltip then
        FVID.ShowTooltip(cell, itemId, nil, function()
            AppendRestockTooltipHints(itemId, cell, entry)
            AppendSpellReagentTooltipLines(cell, itemId)
        end)
        return
    end
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
    if GameTooltip.SetItemByID then
        pcall(GameTooltip.SetItemByID, GameTooltip, itemId)
    else
        GameTooltip:SetText(entry.name or ("Item " .. itemId), 1, 1, 1)
    end
    AppendRestockTooltipHints(itemId, cell, entry)
    GameTooltip:Show()
    AppendSpellReagentTooltipLines(cell, itemId)
end

local function AppendTierReferenceLinesDeferred(owner, tierKind)
    if not tierKind or not GameTooltip then
        return
    end
    local function append()
        if owner and GameTooltip.GetOwner and GameTooltip:GetOwner() ~= owner then
            return
        end
        local FJ = _G.FluxVendorJunk
        if FJ and FJ.AppendTierReferenceRestoreLines then
            FJ.AppendTierReferenceRestoreLines(GameTooltip, tierKind)
        end
        GameTooltip:Show()
    end
    if Timer and Timer.After then
        Timer.After(0, append)
    else
        append()
    end
end

local function ShowTierCellTooltip(cell, entry, tierKind)
    if not GameTooltip then
        return
    end
    GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
    GameTooltip:SetText(entry.name or tierKind or "Restock", 1, 1, 1)
    if tierKind == "food" or tierKind == "water" then
        GameTooltip:AddLine(
            "Counts stacks at your best restore tier, including conjured (flat or % of your bars).",
            0.7, 0.7, 0.7, true
        )
        GameTooltip:AddLine("Conjured stacks count toward target.", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("Well Fed buff food is excluded. Inferior tiers do not count.", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("Auto-restock buys any vendor item at that tier.", 0.7, 0.7, 0.7, true)
    elseif IsCombatTierKind(tierKind) then
        GameTooltip:AddLine("Counts best-tier stacks in your bags.", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("Bank restock pulls matching items from the bank.", 0.7, 0.7, 0.7, true)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffaaaaaaClick:|r set stack target", 0.65, 0.7, 0.75, true)
    GameTooltip:AddLine("|cffaaaaaaTop-right:|r reset saved tier and auto-junk marks", 0.65, 0.7, 0.75, true)
    if entry and entry.merchantChecked then
        GameTooltip:AddLine(" ")
        if entry.vendorNotSold then
            GameTooltip:AddLine("This vendor does not sell this item.", 1, 0.35, 0.35, true)
        elseif entry.vendorLowerTierOnly then
            GameTooltip:AddLine("This vendor only sells lower-tier items.", 1, 0.82, 0.35, true)
        elseif entry.vendorHasStock ~= false then
            GameTooltip:AddLine("This vendor sells matching stock for auto-restock.", 0.35, 1, 0.35, true)
        end
    end
    GameTooltip:Show()
    AppendTierReferenceLinesDeferred(cell, tierKind)
end

local function ToggleCellEditBox(cell, itemId, tierKind)
    local editBox = cell.editBox
    if not editBox or not cell._countStr then
        return
    end
    local gridUI = GetGridUI()
    local function setLabelsVisible(visible)
        if gridUI and gridUI.SetCellCountLabelsVisible then
            gridUI.SetCellCountLabelsVisible(cell, visible)
        elseif cell._countStr then
            if visible then
                cell._countStr:Show()
            else
                cell._countStr:Hide()
            end
            if cell._bankCountStr then
                if visible and cell._countBank then
                    cell._bankCountStr:Show()
                else
                    cell._bankCountStr:Hide()
                end
            end
        end
    end
    if editBox:IsShown() then
        editBox:ClearFocus()
        editBox:Hide()
        setLabelsVisible(true)
        FlushPendingGridRebuild()
    else
        editBox:Show()
        editBox._fluxRestockEnterCommit = nil
        editBox._fluxRestockEscapeCancel = nil
        if tierKind then
            editBox:SetText(tostring(GetTierRestockTarget(tierKind)))
        else
            editBox:SetText(tostring(GetRestockTarget(itemId, cell)))
        end
        editBox:HighlightText(0, 0)
        editBox:SetFocus()
        setLabelsVisible(false)
    end
end

local function GetCursorItemID()
    local FJ = _G.FluxVendorJunk
    if FJ and FJ.GetItemIdFromCursor then
        local id = FJ.GetItemIdFromCursor()
        if id then
            return tonumber(id)
        end
    end
    local cursorType, itemID = GetCursorInfo()
    if cursorType == "item" then
        return tonumber(itemID)
    end
    return nil
end

local function TryAcceptCursorItemToPreset()
    local itemID = GetCursorItemID()
    if not itemID then
        return false
    end
    if not IsSpellReagentItem(itemID) then
        return false
    end
    ClearCursor()
    local FV = _G.FluxVendorAuto
    if FV and FV.AddRestockItem then
        FV.AddRestockItem(itemID, 1, true)
        NotifyRestockStructureChanged()
        return true
    end
    return false
end

local function TryAcceptCursorItemToManual()
    local itemID = GetCursorItemID()
    if not itemID then
        return false
    end
    if IsSpellReagentItem(itemID) then
        return TryAcceptCursorItemToPreset()
    end
    ClearCursor()
    local FV = _G.FluxVendorAuto
    if FV and FV.AddRestockItem then
        FV.AddRestockItem(itemID, 1, true)
        NotifyRestockStructureChanged()
        return true
    end
    return false
end

local function TryAcceptCursorItemToConsumables()
    local itemID = GetCursorItemID()
    if not itemID then
        return false
    end
    local Cons = _G.FluxNCConsumables
    if not Cons or not Cons.AddItem then
        return false
    end
    if Cons.IsChronoboonItem and Cons.IsChronoboonItem(itemID) then
        return false
    end
    ClearCursor()
    if Cons.AddItem(itemID) then
        if Cons.ForceUpdate then
            pcall(Cons.ForceUpdate)
        end
        NotifyRestockStructureChanged()
        return true
    end
    return false
end

local function FinishConsumableDragReorder(widget, toIndex)
    local fromIndex = widget and widget._consumableDragFrom
    widget._consumableDragFrom = nil
    if not fromIndex or not toIndex then
        return false
    end
    local Cons = _G.FluxNCConsumables
    if not Cons or not Cons.MoveItem then
        return false
    end
    if fromIndex == toIndex then
        return false
    end
    if Cons.MoveItem(fromIndex, toIndex) then
        if Cons.ForceUpdate then
            pcall(Cons.ForceUpdate)
        end
        NotifyRestockStructureChanged()
        return true
    end
    return false
end

local function TryAcceptCursorItemToJunkList(listKind)
    local itemID = GetCursorItemID()
    if not itemID then
        return false
    end
    local FJ = _G.FluxVendorJunk
    if not FJ then
        return false
    end
    ClearCursor()
    if listKind == "useful" then
        if FJ.MarkUseful then
            FJ.MarkUseful(itemID)
        end
    elseif listKind == "junk" then
        if FJ.AddJunk then
            FJ.AddJunk(itemID)
        end
    else
        return false
    end
    NotifyRestockStructureChanged()
    return true
end

local function BindDropBoxHandlers(frame, dropKind)
    if not frame then
        return
    end
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnReceiveDrag", function()
        if dropKind == "preset" then
            TryAcceptCursorItemToPreset()
        elseif dropKind == "manual" then
            TryAcceptCursorItemToManual()
        elseif dropKind == "consumable" then
            TryAcceptCursorItemToConsumables()
        else
            TryAcceptCursorItemToJunkList(dropKind)
        end
    end)
    frame:SetScript("OnMouseUp", function(_, btn)
        if btn ~= "LeftButton" or select(1, GetCursorInfo()) ~= "item" then
            return
        end
        if dropKind == "preset" then
            TryAcceptCursorItemToPreset()
        elseif dropKind == "manual" then
            TryAcceptCursorItemToManual()
        elseif dropKind == "consumable" then
            TryAcceptCursorItemToConsumables()
        else
            TryAcceptCursorItemToJunkList(dropKind)
        end
    end)
end

local function CreatePersistentSection(content, title, hint, dropKind)
    local section = { cells = {}, hintText = hint or "" }
    section.header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    section.header:SetText(title)
    section.header:SetTextColor(1, 0.82, 0)

    section.box = CreateFrame("Frame", nil, content, backdropTemplate)
    section.box:SetSize(DEFAULT_CONTENT_W, MIN_DROP_H)
    section.box:EnableMouse(true)
    if section.box.SetBackdrop then
        section.box:SetBackdrop(DROP_BACKDROP)
        section.box:SetBackdropColor(0.06, 0.06, 0.08, 0.55)
        section.box:SetBackdropBorderColor(0.35, 0.35, 0.4, 0.9)
    end
    if dropKind then
        BindDropBoxHandlers(section.box, dropKind)
    end
    section.box._hint = section.box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    section.box._hint:SetPoint("CENTER")
    section.box._hint:SetJustifyH("CENTER")
    section.box._hint:SetText(hint or "")
    section.box._hint:SetAlpha(0.75)
    return section
end

local function RefreshConsumablesThreshold(section)
    if not section or not section.thresholdMinutesBox or not section.thresholdSecondsBox then
        return
    end
    if section.thresholdMinutesBox:HasFocus() or section.thresholdSecondsBox:HasFocus() then
        return
    end
    local totalSeconds = 300
    local Cons = _G.FluxNCConsumables
    if Cons and Cons.GetRefreshThreshold then
        totalSeconds = Cons.GetRefreshThreshold()
    end
    section.thresholdMinutesBox:SetText(tostring(math.floor(totalSeconds / 60)))
    section.thresholdSecondsBox:SetText(string.format("%02d", totalSeconds % 60))
end

local function ApplyConsumablesThreshold(section)
    if not section or not section.thresholdMinutesBox or not section.thresholdSecondsBox then
        return
    end
    local minutes = tonumber(section.thresholdMinutesBox:GetText()) or 0
    local seconds = tonumber(section.thresholdSecondsBox:GetText()) or 0
    minutes = math.max(0, math.min(59, math.floor(minutes)))
    seconds = math.max(0, math.min(59, math.floor(seconds)))
    if minutes == 0 and seconds == 0 then
        seconds = 1
    end
    local Cons = _G.FluxNCConsumables
    if Cons and Cons.SetRefreshThreshold then
        Cons.SetRefreshThreshold(minutes * 60 + seconds)
        RefreshConsumablesThreshold(section)
        local Config = _G.FluxConsumablesConfig
        if Config and Config.UpdateThresholdDisplay then
            Config.UpdateThresholdDisplay()
        end
    end
end

local function RefreshConsumablesPresetDropdown(section)
    if not section or not section.presetDropdown then
        return
    end
    if section.presetLabel then
        section.presetLabel:Show()
    end
    section.presetDropdown:Show()
    if section.newBtn then
        section.newBtn:Show()
    end
    if section.delBtn then
        section.delBtn:Show()
    end
    if section.thresholdLabel then
        section.thresholdLabel:Show()
    end
    if section.thresholdMinutesBox then
        section.thresholdMinutesBox:Show()
    end
    if section.thresholdMinutesLabel then
        section.thresholdMinutesLabel:Show()
    end
    if section.thresholdSeparator then
        section.thresholdSeparator:Show()
    end
    if section.thresholdSecondsBox then
        section.thresholdSecondsBox:Show()
    end
    if section.thresholdSecondsLabel then
        section.thresholdSecondsLabel:Show()
    end
    local Cons = _G.FluxNCConsumables
    local active = (Cons and Cons.GetActivePreset and Cons.GetActivePreset()) or "default"
    if section.presetDropdown.FluxSetText then
        section.presetDropdown:FluxSetText(active)
    end
    RefreshConsumablesThreshold(section)
end

local function EnsureConsumablesPresetControls(section, content)
    if section.presetDropdown then
        return
    end
    section.presetLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    section.presetLabel:SetText("Preset:")
    section.presetLabel:SetTextColor(0.85, 0.85, 0.85)

    local dropdown = _G.FluxBlizzardDropdown.Create(content, nil, 180)
    dropdown:FluxSetMenu(function()
        local Cons = _G.FluxNCConsumables
        local names = (Cons and Cons.GetPresetNames and Cons.GetPresetNames()) or { "default" }
        local active = (Cons and Cons.GetActivePreset and Cons.GetActivePreset()) or "default"
        local entries = {}
        for _, name in ipairs(names) do
            entries[#entries + 1] = {
                text = name,
                checked = (name == active),
                func = function()
                    if Cons and Cons.SetActivePreset and Cons.SetActivePreset(name) then
                        dropdown:FluxSetText(name)
                        if Cons.ForceUpdate then
                            pcall(Cons.ForceUpdate)
                        end
                        NotifyRestockStructureChanged()
                    end
                end,
            }
        end
        return entries
    end)
    section.presetDropdown = dropdown

    local newBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    newBtn:SetSize(CONSUMABLES_BTN_W, 22)
    newBtn:SetText("New")
    newBtn:SetScript("OnClick", function()
        local Config = _G.FluxConsumablesConfig
        if Config and Config.PromptNewPreset then
            Config.PromptNewPreset()
        end
    end)
    section.newBtn = newBtn

    local delBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    delBtn:SetSize(CONSUMABLES_BTN_W, 22)
    delBtn:SetText("Delete")
    delBtn:SetScript("OnClick", function()
        local Config = _G.FluxConsumablesConfig
        if Config and Config.ConfirmDeletePreset then
            Config.ConfirmDeletePreset()
        end
    end)
    section.delBtn = delBtn

    section.thresholdLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    section.thresholdLabel:SetText("Refresh threshold:")
    section.thresholdLabel:SetTextColor(0.85, 0.85, 0.85)

    section.thresholdMinutesBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    section.thresholdMinutesBox:SetSize(CONSUMABLES_EDIT_W, 20)
    section.thresholdMinutesBox:SetAutoFocus(false)
    section.thresholdMinutesBox:SetNumeric(true)
    section.thresholdMinutesBox:SetMaxLetters(2)
    section.thresholdMinutesBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        ApplyConsumablesThreshold(section)
    end)
    section.thresholdMinutesBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        RefreshConsumablesThreshold(section)
    end)
    section.thresholdMinutesBox:SetScript("OnTextChanged", function(self)
        local num = tonumber(self:GetText())
        if num and (num < 0 or num > 59) and Timer and Timer.After then
            Timer.After(0.01, function()
                RefreshConsumablesThreshold(section)
            end)
        end
    end)

    section.thresholdMinutesLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    section.thresholdMinutesLabel:SetText("min")
    section.thresholdMinutesLabel:SetTextColor(0.85, 0.85, 0.85)

    section.thresholdSeparator = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    section.thresholdSeparator:SetText(":")
    section.thresholdSeparator:SetTextColor(0.85, 0.85, 0.85)

    section.thresholdSecondsBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    section.thresholdSecondsBox:SetSize(CONSUMABLES_EDIT_W, 20)
    section.thresholdSecondsBox:SetAutoFocus(false)
    section.thresholdSecondsBox:SetNumeric(true)
    section.thresholdSecondsBox:SetMaxLetters(2)
    section.thresholdSecondsBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        ApplyConsumablesThreshold(section)
    end)
    section.thresholdSecondsBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        RefreshConsumablesThreshold(section)
    end)
    section.thresholdSecondsBox:SetScript("OnTextChanged", function(self)
        local num = tonumber(self:GetText())
        if num and (num < 0 or num > 59) and Timer and Timer.After then
            Timer.After(0.01, function()
                RefreshConsumablesThreshold(section)
            end)
        end
    end)

    section.thresholdSecondsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    section.thresholdSecondsLabel:SetText("sec")
    section.thresholdSecondsLabel:SetTextColor(0.85, 0.85, 0.85)

    RefreshConsumablesThreshold(section)
end

local function EnsureConsumablesPresetEventHook(widget)
    if widget._consumablePresetHooked then
        return
    end
    widget._consumablePresetHooked = true
    local Respec = _G.FluxRespec
    if Respec and Respec.On then
        Respec.On("CONSUMABLES_CONFIG_CHANGED", function()
            SchedulePanelRebuild(widget, 0)
        end)
    end
end

local function EnsureFluxSections(widget)
    if widget._fluxSections then
        return widget._fluxSections
    end
    local content = widget._content
    if not content then
        return nil
    end
    widget._fluxSections = {
        CreatePersistentSection(content, "Preset restock", "Drop spell reagents here.", "preset"),
        (function()
            local gridUI = GetGridUI()
            return gridUI and gridUI.CreateSection(
                content,
                "Consumables",
                "Drop consumables here. Drag icons to reorder.",
                "consumable",
                { onStructureChanged = function()
                    NotifyRestockStructureChanged(widget)
                end }
            )
        end)() or CreatePersistentSection(content, "Consumables", "Drop consumables here. Drag icons to reorder.", "consumable"),
        CreatePersistentSection(content, "Manual restock", "Drop item here.", "manual"),
        CreatePersistentSection(content, "Useful", "Drop to protect.", "useful"),
        CreatePersistentSection(content, "Junk", "Drop to sell.", "junk"),
    }
    EnsureConsumablesPresetControls(widget._fluxSections[2], content)
    EnsureConsumablesPresetEventHook(widget)
    return widget._fluxSections
end

local function SetBoxItems(section, width)
    local box = section.box
    local cells = section.cells
    if #cells > 0 and box._hint then
        box._hint:Hide()
    elseif box._hint and section.hintText and section.hintText ~= "" then
        box._hint:SetText(section.hintText)
        box._hint:SetWidth(math.max(width - 24, 80))
        box._hint:Show()
    elseif box._hint then
        box._hint:Hide()
    end
    box:SetWidth(width)
    local h = LayoutGrid(box, cells)
    box:SetHeight(h)
    return h
end

local function GetItemNameAndIcon(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil, "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    local icon
    if C_Item and C_Item.GetItemIconByID then
        icon = C_Item.GetItemIconByID(itemID)
    end
    if C_Item and C_Item.GetItemInfo then
        local info = C_Item.GetItemInfo(itemID)
        if type(info) == "table" then
            return info.itemName or info.name, icon or info.iconFileID or info.itemIcon or info.iconID
        end
    end
    local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemID)
    return name, icon or tex or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetJunkListBadge(itemID, listKind)
    if listKind == "useful" then
        return "|cff66ff66K|r"
    end
    local FJ = _G.FluxVendorJunk
    if FJ and FJ.IsExplicitJunk and FJ.IsExplicitJunk(itemID) then
        return "|cffffcc66M|r"
    end
    if FJ and FJ.IsAutoJunk and FJ.IsAutoJunk(itemID) then
        return "|cff888888A|r"
    end
    return "|cffff6666J|r"
end

local function ShowJunkListTooltip(btn, itemID, listKind)
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    local FVID = _G.FluxVendorItemDisplay
    if FVID and FVID.ShowTooltip then
        FVID.ShowTooltip(btn, itemID, nil, function()
            GameTooltip:AddLine(" ")
            if listKind == "useful" then
                GameTooltip:AddLine("Manually marked useful.", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("Click: move to Junk", 0.7, 0.7, 0.7)
            else
                local FJ = _G.FluxVendorJunk
                if FJ and FJ.IsExplicitJunk and FJ.IsExplicitJunk(itemID) then
                    GameTooltip:AddLine("Manually added to junk.", 0.85, 0.75, 0.45)
                elseif FJ and FJ.IsAutoJunk and FJ.IsAutoJunk(itemID) then
                    GameTooltip:AddLine("Auto-marked junk (inferior tier / conjure filter).", 0.65, 0.65, 0.65)
                end
                GameTooltip:AddLine("Click: move to Useful", 0.7, 0.7, 0.7)
            end
            GameTooltip:AddLine("Right-click: clear mark", 0.7, 0.7, 0.7)
        end)
        return
    end
    if GameTooltip.SetItemByID then
        pcall(GameTooltip.SetItemByID, GameTooltip, itemID)
    else
        GameTooltip:SetText((select(1, GetItemInfo(itemID))) or ("Item " .. tostring(itemID)), 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(listKind == "useful" and "Click: move to Junk" or "Click: move to Useful", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Right-click: clear mark", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

local function CreateJunkListCell(parent, itemID, listKind, widget, section)
    local name, iconTex = GetItemNameAndIcon(itemID)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(CELL_MIN, ROW_H)
    btn._layoutWidth = CELL_MIN
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(TEX, TEX)
    icon:SetPoint("TOP", btn, "TOP", 0, -2)
    icon:SetTexture(iconTex)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", btn, "BOTTOM", 0, 1)
    label:SetText(GetJunkListBadge(itemID, listKind))
    btn._itemId = itemID
    btn._icon = icon
    btn:SetScript("OnEnter", function(self)
        ShowJunkListTooltip(self, itemID, listKind)
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    btn:SetScript("OnReceiveDrag", function()
        TryAcceptCursorItemToJunkList(listKind)
    end)
    btn:SetScript("OnClick", function(_, button)
        local FJ = _G.FluxVendorJunk
        if not FJ then
            return
        end
        if button == "RightButton" then
            if FJ.ForgetJunk then
                FJ.ForgetJunk(itemID)
            end
        elseif listKind == "useful" then
            if FJ.AddJunk then
                FJ.AddJunk(itemID)
            end
        elseif FJ.MarkUseful then
            FJ.MarkUseful(itemID)
        end
        NotifyRestockStructureChanged()
    end)
    if C_Item and C_Item.RequestLoadItemDataByID and not name then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    section.cells[#section.cells + 1] = btn
    btn:Show()
    return btn
end

local function CreateRestockCell(parent, entry, widget, section)
    local itemId = entry.itemId
    local tierKind = entry.tierKind
    local iconTex = entry.icon
        or (itemId and GetItemIcon and GetItemIcon(itemId))
        or "Interface\\Icons\\INV_Misc_QuestionMark"

    local cell = CreateFrame("Button", nil, parent, backdropTemplate)
    cell:EnableMouse(true)
    cell._itemId = itemId
    cell._tierKind = tierKind
    cell._countBank = entry.countBank == true
    cell._restockSource = entry.restockSource
    cell._isChronoboon = entry.isChronoboon == true
    cell._isSpellReagent = entry.isSpellReagent == true
    cell._consumableIndex = entry.consumableIndex
    cell._entry = entry
    cell._fluxSection = section

    local gridUI = GetGridUI()
    if gridUI and gridUI.SetupCellChrome then
        gridUI.SetupCellChrome(cell, {
            iconTex = iconTex,
            entry = entry,
            itemId = itemId,
            tierKind = tierKind,
            section = section,
            maxEditLetters = 4,
            showReset = tierKind ~= nil,
            setupBankBtn = (itemId or tierKind) and function(cell, bankBtn, bankTex)
                local function IsBankCountOn()
                    local FV = _G.FluxVendorAuto
                    if tierKind and FV and FV.GetTierCountBankFlag then
                        return FV.GetTierCountBankFlag(tierKind) == true
                    end
                    if itemId and FV and FV.GetRestockItemFlags then
                        return FV.GetRestockItemFlags(itemId).countBank == true
                    end
                    return false
                end
                local function RefreshBankBtn()
                    local on = IsBankCountOn()
                    bankTex:SetDesaturated(not on)
                    bankTex:SetAlpha(on and 1 or 0.3)
                    cell._countBank = on
                end
                bankBtn:RegisterForClicks("LeftButtonUp")
                bankBtn:SetScript("OnClick", function()
                    local FV = _G.FluxVendorAuto
                    if tierKind and FV and FV.SetTierCountBankFlag then
                        FV.SetTierCountBankFlag(tierKind, not IsBankCountOn(), true)
                    elseif itemId and FV and FV.SetRestockItemFlag then
                        FV.SetRestockItemFlag(itemId, "countBank", not IsBankCountOn(), true)
                    end
                    RefreshBankBtn()
                    RefreshOneCell(cell, nil, true)
                    RelayoutCellSection(cell)
                    NotifyRestockDataChanged()
                end)
                bankBtn:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(bankBtn, "ANCHOR_RIGHT")
                    GameTooltip:SetText(IsBankCountOn() and "Bank count: on" or "Bank count: off", 1, 1, 1)
                    GameTooltip:AddLine("Click to toggle bank stock in target.", 0.7, 0.7, 0.7, true)
                    GameTooltip:Show()
                end)
                bankBtn:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
                RefreshBankBtn()
                cell._refreshBankBtn = RefreshBankBtn
            end or nil,
            setupResetBtn = tierKind and function(cell, resetBtn, resetTex)
                resetBtn:RegisterForClicks("LeftButtonUp")
                resetBtn:SetScript("OnClick", function()
                    ConfirmResetTierReference(tierKind)
                end)
                resetBtn:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(resetBtn, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Reset saved tier", 1, 1, 1)
                    GameTooltip:AddLine("Forget the learned tier baseline for this category.", 0.7, 0.7, 0.7, true)
                    GameTooltip:AddLine("Clears auto-junk marks for this category.", 0.7, 0.7, 0.7, true)
                    GameTooltip:AddLine("Restock target and bank count are unchanged.", 0.7, 0.7, 0.7, true)
                    GameTooltip:Show()
                end)
                resetBtn:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end or nil,
        })
    end

    local countStr = cell._countStr
    local editBox = cell.editBox
    if not countStr or not editBox then
        return cell
    end

    editBox:SetScript("OnEnterPressed", function(box)
        local v = tonumber(box:GetText()) or 0
        if tierKind then
            CommitTierRestockTarget(tierKind, v)
        elseif itemId then
            CommitRestockTarget(itemId, v, cell)
        end
        box:Hide()
        if GridUI and GridUI.SetCellCountLabelsVisible then
            GridUI.SetCellCountLabelsVisible(cell, true)
        elseif countStr then
            countStr:Show()
        end
        RefreshOneCell(cell, nil, true)
        RelayoutCellSection(cell)
        NotifyRestockDataChanged()
        box._fluxRestockEnterCommit = true
        box:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function(box)
        box._fluxRestockEscapeCancel = true
        box:ClearFocus()
        box:SetText(tierKind and tostring(GetTierRestockTarget(tierKind)) or tostring(GetRestockTarget(itemId, cell)))
        box:Hide()
        if GridUI and GridUI.SetCellCountLabelsVisible then
            GridUI.SetCellCountLabelsVisible(cell, true)
        elseif countStr then
            countStr:Show()
        end
        box._fluxRestockEscapeCancel = nil
        FlushPendingGridRebuild()
    end)
    editBox:SetScript("OnEditFocusLost", function(box)
        if box._fluxRestockEnterCommit then
            box._fluxRestockEnterCommit = nil
            FlushPendingGridRebuild()
            return
        end
        if box._fluxRestockEscapeCancel then
            return
        end
        if not box:IsShown() then
            FlushPendingGridRebuild()
            return
        end
        local v = tonumber(box:GetText()) or 0
        if tierKind then
            CommitTierRestockTarget(tierKind, v)
        elseif itemId then
            CommitRestockTarget(itemId, v, cell)
        end
        box:Hide()
        if GridUI and GridUI.SetCellCountLabelsVisible then
            GridUI.SetCellCountLabelsVisible(cell, true)
        elseif countStr then
            countStr:Show()
        end
        RefreshOneCell(cell, nil, true)
        RelayoutCellSection(cell)
        NotifyRestockDataChanged()
    end)

    cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    cell:RegisterForDrag("LeftButton")
    cell:SetScript("OnReceiveDrag", function(self)
        if self._restockSource == "consumable" and not self._isChronoboon then
            local cursorID = GetCursorItemID()
            if cursorID then
                local Cons = _G.FluxNCConsumables
                if Cons and Cons.AddItemAtIndex and self._consumableIndex then
                    ClearCursor()
                    Cons.AddItemAtIndex(cursorID, self._consumableIndex)
                    if Cons.ForceUpdate then
                        pcall(Cons.ForceUpdate)
                    end
                    NotifyRestockStructureChanged()
                else
                    TryAcceptCursorItemToConsumables()
                end
                return
            end
            if widget._consumableDragFrom and self._consumableIndex then
                FinishConsumableDragReorder(widget, self._consumableIndex)
            end
            return
        end
        if self._restockSource == "spellReagent" or self._tierKind then
            TryAcceptCursorItemToPreset()
            return
        end
        if self._restockSource == "manual" then
            TryAcceptCursorItemToManual()
        end
    end)
    if cell._restockSource == "consumable" and not cell._isChronoboon then
        cell:SetScript("OnDragStart", function(self)
            if self._consumableIndex then
                widget._consumableDragFrom = self._consumableIndex
                self:SetAlpha(0.5)
            end
        end)
        cell:SetScript("OnDragStop", function(self)
            self:SetAlpha(1)
            if widget._consumableDragFrom and not self._consumableIndex then
                widget._consumableDragFrom = nil
            end
        end)
    end
    cell:SetScript("OnEnter", function()
        if tierKind then
            ShowTierCellTooltip(cell, entry, tierKind)
        else
            ShowCellTooltip(cell, entry, itemId)
        end
    end)
    cell:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    cell:SetScript("OnClick", function(self, btn)
        if self._restockSource == "consumable" and not self._isChronoboon then
            if select(1, GetCursorInfo()) == "item" then
                local cursorID = GetCursorItemID()
                if cursorID and self._consumableIndex then
                    local Cons = _G.FluxNCConsumables
                    if Cons and Cons.AddItemAtIndex then
                        ClearCursor()
                        Cons.AddItemAtIndex(cursorID, self._consumableIndex)
                        if Cons.ForceUpdate then
                            pcall(Cons.ForceUpdate)
                        end
                        NotifyRestockStructureChanged()
                    end
                end
                return
            end
            if widget._consumableDragFrom and self._consumableIndex then
                FinishConsumableDragReorder(widget, self._consumableIndex)
                return
            end
            if IsRightClick(btn) then
                local Cons = _G.FluxNCConsumables
                if Cons and Cons.RemoveItemAtIndex and self._consumableIndex then
                    Cons.RemoveItemAtIndex(self._consumableIndex)
                    if Cons.ForceUpdate then
                        pcall(Cons.ForceUpdate)
                    end
                    NotifyRestockStructureChanged()
                end
                return
            end
            ToggleCellEditBox(self, itemId, nil)
            return
        end
        if select(1, GetCursorInfo()) == "item" then
            if self._restockSource == "spellReagent" or self._tierKind then
                TryAcceptCursorItemToPreset()
            else
                TryAcceptCursorItemToManual()
            end
            return
        end
        if tierKind then
            ToggleCellEditBox(cell, nil, tierKind)
        elseif cell._restockSource == "spellReagent"
            or cell._restockSource == "consumable"
            or IsSpellReagentItem(itemId) then
            ToggleCellEditBox(cell, itemId, nil)
        elseif IsRightClick(btn) then
            RemoveNonSpellRestock(itemId, cell)
        else
            ToggleCellEditBox(cell, itemId, nil)
        end
    end)
    cell.editBox = editBox
    if not ApplyCellCountsFromEntry(cell, entry) then
        RefreshOneCell(cell, nil, true)
    end
    cell._layoutWidth = cell._layoutWidth or CELL_MIN
    cell:Show()
    section.cells[#section.cells + 1] = cell
    widget._cells[#widget._cells + 1] = cell
    RegisterCellInMaps(cell)
    return cell
end

local function NormalizeRestockEntries()
    local FV = _G.FluxVendorAuto
    local merchantOpen = MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown()
    local preset, consumables, manual = {}, {}, {}

    -- Ensure spell-book reagents are ready before building Preset restock.
    local inv = Inv()
    if inv and inv.Spells then
        if inv.Spells.Refresh then
            pcall(inv.Spells.Refresh)
        elseif inv.Spells.ScheduleWarm then
            pcall(inv.Spells.ScheduleWarm)
        end
    end
    if FV and FV.InvalidateRestockOptionsPanelCache then
        pcall(FV.InvalidateRestockOptionsPanelCache)
    end

    if FV and FV.GetRestockTargetItems then
        local ok, targets = pcall(FV.GetRestockTargetItems, {
            forOptionsPanel = true,
            forceRefresh = true,
            merchantAware = merchantOpen,
        })
        optionsListForceRefresh = false
        if not ok then
            targets = nil
        end
        if type(targets) == "table" then
            if FV.FilterRestockListForVendor then
                targets = FV.FilterRestockListForVendor(targets, {
                    forOptionsPanel = true,
                    merchantAware = merchantOpen,
                })
            end
            for _, entry in ipairs(targets) do
                local normalized
                if entry and entry.isTierRestock and entry.tierKind then
                    normalized = {
                        tierKind = entry.tierKind,
                        icon = entry.texture,
                        name = entry.name,
                        restockSource = "tier",
                        countBank = entry.countBank == true,
                        bankCount = entry.bankCount or 0,
                        bagCount = entry.bagCount,
                        target = entry.target,
                        merchantChecked = entry.merchantChecked == true,
                        vendorNotSold = entry.vendorNotSold == true,
                        vendorSold = entry.vendorHasStock == true or entry.vendorLowerTierOnly == true,
                        vendorHasStock = entry.vendorHasStock == true,
                        vendorLowerTierOnly = entry.vendorLowerTierOnly == true,
                    }
                elseif entry and entry.itemID then
                    normalized = {
                        itemId = entry.itemID,
                        icon = entry.texture,
                        name = entry.name,
                        restockSource = entry.restockSource,
                        isChronoboon = entry.isChronoboon == true,
                        isSpellReagent = entry.isSpellReagent == true,
                        countBank = entry.countBank == true,
                        bankCount = entry.bankCount or 0,
                        bagCount = entry.bagCount,
                        target = entry.target,
                        merchantChecked = entry.merchantChecked == true,
                        vendorNotSold = entry.vendorNotSold == true,
                        vendorSold = entry.vendorSold == true,
                    }
                end
                if normalized then
                    if normalized.tierKind then
                        -- Tier cells live in Preset restock with spell reagents.
                        preset[#preset + 1] = normalized
                    elseif normalized.restockSource == "manual" then
                        manual[#manual + 1] = normalized
                    elseif normalized.restockSource == "consumable" and not normalized.isChronoboon then
                        consumables[#consumables + 1] = normalized
                    else
                        -- spellReagent + any other non-manual/non-consumable → Preset restock
                        preset[#preset + 1] = normalized
                    end
                end
            end
        end
    end
    if #preset > 1 then
        local tierOrder = { food = 1, water = 2, bandage = 3, healPotion = 4, manaPotion = 5 }
        table.sort(preset, function(a, b)
            local ta, tb = a.tierKind and tierOrder[a.tierKind], b.tierKind and tierOrder[b.tierKind]
            if ta or tb then
                if ta and tb then
                    return ta < tb
                end
                return ta ~= nil -- tiers before reagents
            end
            return (a.name or "") < (b.name or "")
        end)
    end
    if #consumables > 1 then
        local Cons = _G.FluxNCConsumables
        local order = Cons and Cons.GetRestockUIItemIDs and Cons.GetRestockUIItemIDs()
        if order then
            local rank = {}
            for i, id in ipairs(order) do
                rank[tonumber(id)] = i
            end
            table.sort(consumables, function(a, b)
                return (rank[a.itemId] or 999) < (rank[b.itemId] or 999)
            end)
        end
    end
    for i = 1, #consumables do
        consumables[i].consumableIndex = i
    end

    return preset, consumables, manual
end

local function LayoutSectionAt(section, content, width, y)
    section.header:ClearAllPoints()
    section.header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    y = y + 16
    section.box:ClearAllPoints()
    section.box:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    local h = SetBoxItems(section, width)
    return y + h + SECTION_GAP
end

local function LayoutConsumablesSection(section, content, width, y)
    section.header:ClearAllPoints()
    section.header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    y = y + 16
    RefreshConsumablesPresetDropdown(section)
    if section.presetLabel and section.presetDropdown then
        section.presetLabel:ClearAllPoints()
        section.presetLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        section.presetDropdown:ClearAllPoints()
        section.presetDropdown:SetPoint("LEFT", section.presetLabel, "RIGHT", 6, 0)
        if section.newBtn then
            section.newBtn:ClearAllPoints()
            section.newBtn:SetPoint("LEFT", section.presetDropdown, "RIGHT", 8, 0)
        end
        if section.delBtn and section.newBtn then
            section.delBtn:ClearAllPoints()
            section.delBtn:SetPoint("LEFT", section.newBtn, "RIGHT", 4, 0)
        end
        y = y + PRESET_ROW_H
    end
    if section.thresholdLabel and section.thresholdMinutesBox then
        section.thresholdLabel:ClearAllPoints()
        section.thresholdLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        section.thresholdMinutesBox:ClearAllPoints()
        section.thresholdMinutesBox:SetPoint("LEFT", section.thresholdLabel, "RIGHT", 8, 0)
        if section.thresholdMinutesLabel then
            section.thresholdMinutesLabel:ClearAllPoints()
            section.thresholdMinutesLabel:SetPoint("LEFT", section.thresholdMinutesBox, "RIGHT", 4, 0)
        end
        if section.thresholdSeparator and section.thresholdMinutesLabel then
            section.thresholdSeparator:ClearAllPoints()
            section.thresholdSeparator:SetPoint("LEFT", section.thresholdMinutesLabel, "RIGHT", 4, 0)
        end
        if section.thresholdSecondsBox and section.thresholdSeparator then
            section.thresholdSecondsBox:ClearAllPoints()
            section.thresholdSecondsBox:SetPoint("LEFT", section.thresholdSeparator, "RIGHT", 4, 0)
        end
        if section.thresholdSecondsLabel and section.thresholdSecondsBox then
            section.thresholdSecondsLabel:ClearAllPoints()
            section.thresholdSecondsLabel:SetPoint("LEFT", section.thresholdSecondsBox, "RIGHT", 4, 0)
        end
        y = y + THRESHOLD_ROW_H
    end
    section.box:ClearAllPoints()
    section.box:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    local h = SetBoxItems(section, width)
    return y + h + SECTION_GAP
end

local function SectionHasCells(sections)
    if not sections then
        return false
    end
    for i = 1, #sections do
        local cells = sections[i] and sections[i].cells
        if cells and #cells > 0 then
            return true
        end
    end
    return false
end

local function RelayoutPanelSections(self)
    local content = self._content
    if not content or not self._fluxSections then
        return
    end
    local sections = self._fluxSections
    local inner = GetEffectiveContentWidth(self)
    content:SetWidth(inner)
    local y = 0
    for i = 1, #sections do
        if i == 2 then
            y = LayoutConsumablesSection(sections[i], content, inner, y)
        else
            y = LayoutSectionAt(sections[i], content, inner, y)
        end
    end
    self._fluxInternalLayout = true
    content:SetHeight(math.max(y, MIN_DROP_H))
    self._fluxInternalLayout = nil
    ApplyWidgetLayoutHeight(self, content:GetHeight())
end

local function RefreshJunkListSections(self)
    if not self or not self._fluxSections then
        return
    end
    local sections = self._fluxSections
    if not sections[4] or not sections[5] then
        return
    end
    ClearSectionCells(sections[4])
    ClearSectionCells(sections[5])
    self._cells = self._cells or {}
    local FJ = _G.FluxVendorJunk
    local useful = (FJ and FJ.GetUsefulList and FJ.GetUsefulList()) or {}
    local junk = {}
    if FJ then
        if FJ.GetJunkTabList then
            junk = FJ.GetJunkTabList()
        elseif FJ.GetExplicitJunkList then
            junk = FJ.GetExplicitJunkList()
        end
    end
    for _, itemID in ipairs(useful) do
        CreateJunkListCell(sections[4].box, itemID, "useful", self, sections[4])
    end
    for _, itemID in ipairs(junk) do
        CreateJunkListCell(sections[5].box, itemID, "junk", self, sections[5])
    end
    RelayoutPanelSections(self)
end

RefreshPanel = function(self)
    if not self or not self._content then
        return
    end
    if AceGUI and AceGUI.IsReleasing and AceGUI:IsReleasing(self) then
        return
    end

    self._fluxLastContentHeight = nil
    ProfInc("restockPanel:RefreshPanel", 1)
    self._fluxBuildInProgress = true

    local content = self._content
    local sections = EnsureFluxSections(self)
    if not sections then
        self._fluxBuildInProgress = nil
        return
    end

    ClearCellMaps()
    self._cells = {}
    for i = 1, #sections do
        ClearSectionCells(sections[i])
    end

    local inner = GetEffectiveContentWidth(self)
    content:SetWidth(inner)

    local preset, consumables, manual = NormalizeRestockEntries()
    for _, entry in ipairs(preset) do
        CreateRestockCell(sections[1].box, entry, self, sections[1])
    end
    for _, entry in ipairs(consumables) do
        local gridUI = GetGridUI()
        if gridUI and gridUI.CreateConsumableCell then
            gridUI.CreateConsumableCell(sections[2].box, {
                itemId = entry.itemId,
                icon = entry.icon,
                consumableIndex = entry.consumableIndex,
                mode = "restock",
                dragState = self,
                entry = entry,
                section = sections[2],
                onStructureChanged = function()
                    NotifyRestockStructureChanged(self)
                end,
                onDataChanged = NotifyRestockDataChanged,
                onEditDone = FlushPendingGridRebuild,
                cellsList = sections[2].cells,
                widgetCells = self._cells,
                showTooltip = function(cell, itemId)
                    ShowCellTooltip(cell, entry, itemId)
                end,
            })
            local cells = sections[2].cells
            if cells and cells[#cells] then
                local lastCell = cells[#cells]
                lastCell._fluxSection = sections[2]
                RegisterCellInMaps(lastCell)
            end
        else
            CreateRestockCell(sections[2].box, entry, self, sections[2])
        end
    end
    for _, entry in ipairs(manual) do
        CreateRestockCell(sections[3].box, entry, self, sections[3])
    end

    local FJ = _G.FluxVendorJunk
    local useful = (FJ and FJ.GetUsefulList and FJ.GetUsefulList()) or {}
    local junk = {}
    if FJ then
        if FJ.GetJunkTabList then
            junk = FJ.GetJunkTabList()
        elseif FJ.GetExplicitJunkList then
            junk = FJ.GetExplicitJunkList()
        end
    end
    for _, itemID in ipairs(useful) do
        CreateJunkListCell(sections[4].box, itemID, "useful", self, sections[4])
    end
    for _, itemID in ipairs(junk) do
        CreateJunkListCell(sections[5].box, itemID, "junk", self, sections[5])
    end

    local y = 0
    for i = 1, #sections do
        if i == 2 then
            y = LayoutConsumablesSection(sections[i], content, inner, y)
        else
            y = LayoutSectionAt(sections[i], content, inner, y)
        end
    end

    self._fluxInternalLayout = true
    content:SetHeight(math.max(y, MIN_DROP_H))
    self._fluxInternalLayout = nil
    ApplyWidgetLayoutHeight(self, content:GetHeight())
    self._fluxBuildInProgress = nil
    lastFullBuildTime = (GetTime and GetTime()) or 0
end

local function RefreshOneCellMerchantVisual(cell)
    local entry = cell._entry
    if not entry or not entry.merchantChecked or not cell._icon then
        return
    end
    if entry.vendorNotSold then
        cell._icon:SetDesaturated(true)
        cell._icon:SetAlpha(0.55)
    elseif entry.vendorLowerTierOnly then
        cell._icon:SetDesaturated(false)
        cell._icon:SetAlpha(0.85)
    else
        cell._icon:SetDesaturated(false)
        cell._icon:SetAlpha(1)
    end
end

function ScheduleBagCellRefresh()
    if not IsPanelActive() then
        return
    end
    if ShouldDeferHeavyBagCellRefresh() then
        if ShouldDeferBankOrganizeBagCellRefresh() then
            pendingBagCellAfterBankOrganize = true
            EnsureBankOrganizeBagCellHook()
            EnsureBankRestockBagCellHook()
        else
            pendingBagCellAfterStorm = true
            EnsureStormBagCellHook()
        end
        return
    end
    if bagRefreshTimerHandle then
        return
    end
    if not Timer or not Timer.After then
        if _G.FluxRestockPanel_RefreshCellData then
            pcall(_G.FluxRestockPanel_RefreshCellData)
        end
        return
    end
    bagRefreshTimerHandle = Timer.After(BAG_REFRESH_DEBOUNCE, function()
        bagRefreshTimerHandle = nil
        if IsPanelActive() and _G.FluxRestockPanel_RefreshCellData then
            pcall(_G.FluxRestockPanel_RefreshCellData, pendingCountRefreshCtx)
            pendingCountRefreshCtx = nil
        end
    end)
end

local function EnsureFrameScripts(frame)
    if not frame or frame._fluxRestockFrameScripts then
        return
    end
    frame._fluxRestockFrameScripts = true
    frame:SetScript("OnShow", function()
        if activeWidget and activeWidget.frame == frame then
            if activeWidget._fluxSkipNextShowRebuild then
                activeWidget._fluxSkipNextShowRebuild = nil
                return
            end
            SchedulePanelRebuild(activeWidget, 0)
        end
        local FT = _G.FluxRestockTiers
        if FT and FT.TryRunDeferredLoginSettle and Timer and Timer.After then
            Timer.After(0.1, function()
                if IsPanelActive() then
                    pcall(FT.TryRunDeferredLoginSettle)
                end
            end)
        elseif FT and FT.TryRunDeferredLoginSettle then
            if IsPanelActive() then
                pcall(FT.TryRunDeferredLoginSettle)
            end
        end
    end)
end

local methods = {
    ["OnAcquire"] = function(self)
        self:SetFullWidth(true)

        local frame = self.frame
        frame:EnableMouse(true)
        EnsureFrameScripts(frame)

        if not self._content then
            local content = CreateFrame("Frame", nil, frame)
            content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            content:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            content:SetWidth(400)
            content:SetHeight(48)
            content:EnableMouse(false)
            self._content = content
        end

        EnsureFluxSections(self)
        panelEngaged = true
        activeWidget = self
        self._fluxSkipNextShowRebuild = true
        optionsListForceRefresh = true
        pendingStructureRefresh = true
        EnsureInventoryListener()
        SchedulePanelRebuild(self, 0)
        -- Rebuild after spell-reagent warm so Preset cells (Rebirth seeds, etc.) appear.
        if Timer and Timer.After then
            local tries = 0
            local function retryAfterReagentWarm()
                tries = tries + 1
                if not IsPanelActive(self) then
                    return
                end
                local inv = Inv()
                local S = inv and inv.Spells
                if S and S.OnVisibleItemsChanged then
                    pcall(S.OnVisibleItemsChanged)
                end
                optionsListForceRefresh = true
                pendingStructureRefresh = true
                SchedulePanelRebuild(self, 0)
                local warmed = S and S.AreReagentsWarmed and S.AreReagentsWarmed()
                if not warmed and tries < 10 then
                    Timer.After(0.4, retryAfterReagentWarm)
                end
            end
            Timer.After(0.5, retryAfterReagentWarm)
        end
    end,

    ["OnRelease"] = function(self)
        local frame = self.frame
        OnPanelHiddenCleanup(false)
        self._fluxInitialBuildScheduled = nil
        ClearCellMaps()
        if self._fluxSections then
            for i = 1, #self._fluxSections do
                ClearSectionCells(self._fluxSections[i])
            end
        end
        self._cells = nil
        self._consumableDragFrom = nil
        self._fluxLastContentHeight = nil
        self._fluxLastPanelWidth = nil
        panelEngaged = false
        if frame then
            frame:SetScript("OnShow", nil)
            frame._fluxRestockFrameScripts = nil
        end
        if activeWidget == self then
            activeWidget = nil
        end
    end,

    ["OnWidthSet"] = function(self, width)
        if self._fluxInternalLayout or self._fluxBuildInProgress then
            return
        end
        if type(width) ~= "number" or width <= 80 or not self._fluxSections then
            return
        end
        local last = self._fluxLastPanelWidth
        if last and math.abs(width - last) < 2 then
            return
        end
        local now = (GetTime and GetTime()) or 0
        if lastFullBuildTime > 0 and (now - lastFullBuildTime) < WIDTH_REBUILD_COOLDOWN then
            return
        end
        self._fluxLastPanelWidth = width
        if self._content then
            self._content:SetWidth(width - 16)
        end
        if SectionHasCells(self._fluxSections) and self._cells and #self._cells > 0 then
            RelayoutPanelSections(self)
        else
            ScheduleBuildGrid(self, 0.05)
        end
    end,

    ["SetLabel"] = function() end,
    ["SetText"] = function() end,
    ["SetFontObject"] = function() end,
}

local function Constructor()
    local name = "AceGUI30FluxRestockPanel" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:Hide()
    frame:SetScript("OnReceiveDrag", function()
        TryAcceptCursorItemToManual()
    end)
    frame:SetScript("OnMouseUp", function(_, btn)
        if btn == "LeftButton" then
            TryAcceptCursorItemToManual()
        end
    end)

    local widget = {
        frame = frame,
        type = Type,
        _cells = {},
    }
    for k, v in pairs(methods) do
        widget[k] = v
    end
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

function _G.FluxRestockPanel_RequestRefresh()
    if not IsPanelActive() then
        pendingStructureRefresh = true
        return
    end
    SchedulePanelRebuild(activeWidget, 0)
end

function _G.FluxRestockPanel_OnSpellReagentCacheReady()
    if not IsPanelActive() then
        pendingStructureRefresh = true
        return
    end
    optionsListForceRefresh = true
    pendingStructureRefresh = true
    SchedulePanelRebuild(activeWidget, 0)
end

function _G.FluxRestockPanel_IsTabVisible()
    return IsPanelActive()
end

function _G.FluxRestockPanel_IsActive()
    return IsPanelActive()
end

function _G.FluxRestockPanel_RefreshMerchantAvailability()
    if not IsPanelActive() or not activeWidget or not activeWidget._cells then
        return
    end
    for i = 1, #activeWidget._cells do
        RefreshOneCellMerchantVisual(activeWidget._cells[i])
    end
end

function _G.FluxRestockPanel_RefreshJunkLists()
    if not IsPanelActive() or not activeWidget then
        return
    end
    RefreshJunkListSections(activeWidget)
end

function _G.FluxRestockPanel_RefreshCellData(ctx)
    if not activeWidget or not activeWidget._cells or IsAnyCellEditing(activeWidget) then
        return
    end
    if not IsPanelActive() then
        return
    end
    ctx = ctx or pendingCountRefreshCtx
    pendingCountRefreshCtx = nil

    ProfInc("restockPanel:RefreshCellData", 1)

    local dirtyItems
    if ctx and (ctx.addedItemIDs or ctx.removedItemIDs) then
        dirtyItems = {}
        if ctx.addedItemIDs then
            for id in pairs(ctx.addedItemIDs) do
                dirtyItems[tonumber(id) or id] = true
            end
        end
        if ctx.removedItemIDs then
            for id in pairs(ctx.removedItemIDs) do
                dirtyItems[tonumber(id) or id] = true
            end
        end
        if next(dirtyItems) then
            ProfInc("restockPanel:RefreshCellDirty", 1)
        else
            dirtyItems = nil
        end
    end

    local function refreshCell(cell)
        if not cell then
            return
        end
        if cell._tierKind or (cell._itemId and cell._countStr) then
            RefreshOneCellMerchantVisual(cell)
            if cell._refreshBankBtn then
                cell._refreshBankBtn()
            end
            RefreshOneCell(cell, true, true)
        end
    end

    if dirtyItems then
        local touchedTierKinds = {}
        local FT = _G.FluxRestockTiers
        for itemId in pairs(dirtyItems) do
            refreshCell(cellsByItemId[itemId])
            if FT and FT.KindsTouchedByItemID then
                local kinds = FT.KindsTouchedByItemID(itemId)
                if kinds then
                    for kind in pairs(kinds) do
                        touchedTierKinds[kind] = true
                    end
                end
            end
        end
        for tierKind in pairs(touchedTierKinds) do
            refreshCell(cellsByTierKind[tierKind])
        end
    else
        local cells = activeWidget._cells
        for i = 1, #cells do
            refreshCell(cells[i])
        end
    end

    if activeWidget and activeWidget._fluxSections then
        RelayoutPanelSections(activeWidget)
    end
end

-- Counts-only path from FluxRestockTiers: refresh cells, never full rebuild.
do
    local Tiers = _G.FluxRestockTiers
    if Tiers and Tiers.RegisterCountsOnlyHandler then
        Tiers.RegisterCountsOnlyHandler(function()
            if _G.FluxRestockPanel_RefreshCellData then
                pcall(_G.FluxRestockPanel_RefreshCellData)
            end
        end)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            local T = _G.FluxRestockTiers
            if T and T.RegisterCountsOnlyHandler then
                T.RegisterCountsOnlyHandler(function()
                    if _G.FluxRestockPanel_RefreshCellData then
                        pcall(_G.FluxRestockPanel_RefreshCellData)
                    end
                end)
            end
        end)
    end
end
