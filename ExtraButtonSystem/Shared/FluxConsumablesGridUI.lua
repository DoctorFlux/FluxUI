--[[
    ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua
    Shared consumables grid UI: section headers, bordered drop boxes, compact cells,
    drag/drop/reorder. Used by ConsumablesConfig window and Vendor & Restock options panel.
]]

FluxConsumablesGridUI = FluxConsumablesGridUI or {}
local GridUI = FluxConsumablesGridUI

GridUI.CELL_MIN = 48
GridUI.CELL_MAX = 80
GridUI.CELL = GridUI.CELL_MIN
GridUI.TEX = 28
GridUI.ROW_H = 58
GridUI.CHROME_H = 14
GridUI.COUNT_H = 11
GridUI.BANK_COUNT_H = 10
GridUI.TOGGLE_SIZE = 13
GridUI.COUNT_PAD = 4
GridUI.COUNT_W = GridUI.CELL_MIN - 4
GridUI.GAP = 0
GridUI.SECTION_GAP = 10
GridUI.GRID_INSET = 7
GridUI.MIN_DROP_H = 46
GridUI.PRESET_ROW_H = 24
GridUI.DEFAULT_CONTENT_W = 420
GridUI.backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
GridUI.DROP_BACKDROP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local wipe = table.wipe or wipe
local Timer = C_Timer

local function ComputeDropInsertIndex(cell, fromIndex)
    local cellIndex = cell._consumableIndex
    if not cellIndex or not fromIndex then
        return cellIndex
    end
    if fromIndex == cellIndex then
        return cellIndex
    end

    local insertAfter = false
    if cell.GetLeft and cell.GetRight then
        local left, right = cell:GetLeft(), cell:GetRight()
        if left and right then
            local cx = select(1, GetCursorPosition()) / UIParent:GetEffectiveScale()
            insertAfter = cx > ((left + right) / 2)
        end
    end

    if insertAfter then
        if fromIndex < cellIndex then
            return cellIndex
        end
        return cellIndex + 1
    end
    if fromIndex < cellIndex then
        return cellIndex - 1
    end
    return cellIndex
end

local function FinishGridDragReorder(dragState, toIndex, onStructureChanged)
    local fromIndex = dragState and dragState._consumableDragFrom
    if dragState then
        dragState._consumableDragFrom = nil
        dragState._isDragging = false
    end
    if dragState and dragState.HideDragGhost then
        dragState.HideDragGhost()
    end
    if not fromIndex or not toIndex or fromIndex == toIndex then
        return false
    end
    local Cons = _G.FluxNCConsumables
    if not Cons or not Cons.MoveItem then
        return false
    end
    if Cons.MoveItem(fromIndex, toIndex) then
        if Cons.ForceUpdate then
            pcall(Cons.ForceUpdate)
        end
        if onStructureChanged then
            onStructureChanged()
        end
        return true
    end
    return false
end

function GridUI.IsRightClick(button)
    return button == "RightButton" or button == "RightButtonUp"
end

function GridUI.GetCursorItemID()
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

local function RestockInv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

local function GetItemCountCompat(itemId)
    local ri = RestockInv()
    if ri and ri.GetCount then
        return ri.GetCount(itemId, {
            charges = true,
            bags = true,
            bank = false,
            warband = false,
            equipped = false,
        }) or 0
    end
    local inv = _G.FluxInv
    if inv and inv.GetCount then
        return inv.GetCount(itemId, {
            charges = true,
            bags = true,
            bank = false,
            warband = false,
            equipped = false,
        }) or 0
    end
    if inv and inv.Bags and inv.Bags.GetCount then
        return inv.Bags.GetCount(itemId) or 0
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

function GridUI.IsChargeItem(itemId)
    return IsChargeItem(itemId)
end

function GridUI.GetChargeAwareCount(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return 0
    end
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

function GridUI.GetChargeAwareBankCount(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return 0
    end
    local chargeOpts = IsChargeItem(itemId) and { charges = true } or nil
    local ri = RestockInv()
    local bank = ri and ri.Bank
    if bank and bank.GetCount then
        return bank.GetCount(itemId, chargeOpts) or 0
    end
    bank = _G.FluxInv and _G.FluxInv.Bank
    if bank and bank.GetCount then
        return bank.GetCount(itemId, chargeOpts) or 0
    end
    local BC = _G.FluxRestockBankCompat
    if BC and BC.GetCachedBankCount then
        return BC.GetCachedBankCount(itemId) or 0
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

function GridUI.FormatCellMainLine(have, bankCount, tgt, countBank, tierKind)
    -- Color is bank-aware: bags + bank. The coin still gates vendor-buy need.
    local combined = (tonumber(have) or 0) + (tonumber(bankCount) or 0)
    local r, g, b = GetRestockCountColor(combined, tgt)
    local hc = string.format("|cff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    local tc = "|cff888888"
    local Tiers = _G.FluxRestockTiers
    if tierKind and Tiers and Tiers.IsTierCountPending and Tiers.IsTierCountPending(tierKind) then
        return "|cff888888...|r" .. tc .. "/" .. tostring(tgt) .. "|r"
    end
    return hc .. tostring(have) .. "|r" .. tc .. "/" .. tostring(tgt) .. "|r"
end

function GridUI.FormatCellBankLine(bankCount, countBank)
    bankCount = tonumber(bankCount) or 0
    if not countBank and bankCount <= 0 then
        return nil
    end
    return "|cff7fbfff+" .. tostring(bankCount) .. "|r"
end

function GridUI.FormatCellCountLines(have, bankCount, tgt, countBank, tierKind)
    return GridUI.FormatCellMainLine(have, bankCount, tgt, countBank, tierKind),
        GridUI.FormatCellBankLine(bankCount, countBank)
end

function GridUI.FormatCellCountText(have, bankCount, tgt, countBank)
    local line1, line2 = GridUI.FormatCellCountLines(have, bankCount, tgt, countBank)
    if line2 then
        return line1 .. "\n" .. line2
    end
    return line1
end

function GridUI.FormatTierCellCountLines(have, bankCount, tgt, countBank, tierKind)
    return GridUI.FormatCellCountLines(have, bankCount, tgt, countBank, tierKind)
end

function GridUI.FormatTierCellCountText(have, bankCount, tgt, countBank, tierKind)
    local line1, line2 = GridUI.FormatTierCellCountLines(have, bankCount, tgt, countBank, tierKind)
    if line2 then
        return line1 .. "\n" .. line2
    end
    return line1
end

local COUNT_FONT_TIERS = {
    { obj = "GameFontNormalSmall" },
    { obj = "GameFontDisableSmall" },
    { font = "Fonts\\FRIZQT__.TTF", size = 9, flags = "OUTLINE" },
}

local function ApplyCountFontTier(countStr, tier)
    if tier.obj then
        countStr:SetFontObject(tier.obj)
    elseif tier.font then
        countStr:SetFont(tier.font, tier.size, tier.flags or "")
    end
end

local BANK_COUNT_FONT_TIERS = {
    { obj = "GameFontDisableSmall" },
    { font = "Fonts\\FRIZQT__.TTF", size = 8, flags = "OUTLINE" },
}

local function ApplyBankCountFontTier(bankStr, tier)
    if tier.obj then
        bankStr:SetFontObject(tier.obj)
    elseif tier.font then
        bankStr:SetFont(tier.font, tier.size, tier.flags or "")
    end
end

function GridUI.ConfigureCellCountString(countStr)
    if not countStr then
        return
    end
    countStr:SetHeight(GridUI.COUNT_H)
    countStr:SetJustifyH("CENTER")
    countStr:SetJustifyV("MIDDLE")
    countStr:SetWordWrap(false)
end

function GridUI.ConfigureCellBankCountString(bankStr)
    if not bankStr then
        return
    end
    bankStr:SetHeight(GridUI.BANK_COUNT_H)
    bankStr:SetJustifyH("CENTER")
    bankStr:SetJustifyV("MIDDLE")
    bankStr:SetWordWrap(false)
end

local function ApplyCellCountAnchors(cell, showBankLine)
    local countStr = cell._countStr
    local bankStr = cell._bankCountStr
    if not countStr then
        return
    end
    countStr:ClearAllPoints()
    if showBankLine and bankStr then
        bankStr:ClearAllPoints()
        bankStr:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 2, 1)
        bankStr:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -2, 1)
        bankStr:Show()
        countStr:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 2, 1 + GridUI.BANK_COUNT_H)
        countStr:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -2, 1 + GridUI.BANK_COUNT_H)
    else
        if bankStr then
            bankStr:Hide()
        end
        countStr:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 2, 1)
        countStr:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -2, 1)
    end
end

function GridUI.SetCellCountLabelsVisible(cell, visible)
    if not cell then
        return
    end
    if cell._countStr then
        if visible then
            cell._countStr:Show()
        else
            cell._countStr:Hide()
        end
    end
    if cell._bankCountStr then
        local showBank = visible and (cell._countBank or (tonumber(cell._bankCount) or 0) > 0)
        if showBank then
            cell._bankCountStr:Show()
        else
            cell._bankCountStr:Hide()
        end
    end
end

function GridUI.FitCellCountDisplay(cell, have, bankCount, tgt, countBank, tierKind)
    if not cell or not cell._countStr then
        return
    end
    local mainText, bankText = GridUI.FormatTierCellCountLines(have, bankCount, tgt, countBank, tierKind)
    local showBankLine = bankText ~= nil
    local countStr = cell._countStr
    local bankStr = cell._bankCountStr
    local pad = GridUI.COUNT_PAD * 2
    local cellW = GridUI.CELL_MIN
    local chosenTier = COUNT_FONT_TIERS[1]
    local chosenBankTier = BANK_COUNT_FONT_TIERS[1]

    for i = 1, #COUNT_FONT_TIERS do
        local tier = COUNT_FONT_TIERS[i]
        local bankTier = BANK_COUNT_FONT_TIERS[math.min(i, #BANK_COUNT_FONT_TIERS)]
        ApplyCountFontTier(countStr, tier)
        countStr:SetWordWrap(false)
        countStr:SetText(mainText)
        local textW = countStr:GetStringWidth() or 0
        chosenTier = tier
        chosenBankTier = bankTier
        if showBankLine and bankStr then
            ApplyBankCountFontTier(bankStr, bankTier)
            bankStr:SetWordWrap(false)
            bankStr:SetText(bankText)
            textW = math.max(textW, bankStr:GetStringWidth() or 0)
        end
        local needed = math.ceil(textW + pad)
        if needed <= GridUI.CELL_MAX then
            cellW = math.max(GridUI.CELL_MIN, needed)
            break
        end
        cellW = GridUI.CELL_MAX
    end

    ApplyCountFontTier(countStr, chosenTier)
    countStr:SetWordWrap(false)
    countStr:SetText(mainText)
    if showBankLine and bankStr then
        ApplyBankCountFontTier(bankStr, chosenBankTier)
        bankStr:SetWordWrap(false)
        bankStr:SetText(bankText)
    end
    ApplyCellCountAnchors(cell, showBankLine)
    cell._bankCount = tonumber(bankCount) or 0
    cell:SetWidth(cellW)
    cell._layoutWidth = cellW
    cell._layoutHeight = showBankLine and (GridUI.ROW_H + GridUI.BANK_COUNT_H) or GridUI.ROW_H
    cell:SetHeight(cell._layoutHeight)
end

function GridUI.ApplyCellCountDisplay(cell, have, bankCount, tgt, countBank, tierKind)
    GridUI.FitCellCountDisplay(cell, have, bankCount, tgt, countBank, tierKind)
end

function GridUI.LayoutFlowGrid(box, slots)
    local boxW = box:GetWidth()
    if not boxW or boxW <= 0 then
        boxW = GridUI.DEFAULT_CONTENT_W
    end
    local innerW = math.max(boxW - GridUI.GRID_INSET * 2, GridUI.CELL_MIN)
    local x = GridUI.GRID_INSET
    local y = -GridUI.GRID_INSET
    local rowMaxH = GridUI.ROW_H

    for _, cell in ipairs(slots) do
        local w = cell._layoutWidth or GridUI.CELL_MIN
        local h = cell._layoutHeight or GridUI.ROW_H
        if x > GridUI.GRID_INSET and (x - GridUI.GRID_INSET + w) > innerW then
            y = y - rowMaxH
            x = GridUI.GRID_INSET
            rowMaxH = h
        else
            rowMaxH = math.max(rowMaxH, h)
        end
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", box, "TOPLEFT", x, y)
        cell:SetHeight(h)
        x = x + w + GridUI.GAP
    end

    if #slots == 0 then
        return GridUI.MIN_DROP_H
    end
    return math.max(GridUI.MIN_DROP_H, math.abs(y) + rowMaxH + GridUI.GRID_INSET)
end

function GridUI.LayoutGrid(box, slots, cols)
    return GridUI.LayoutFlowGrid(box, slots)
end

function GridUI.RelayoutSection(section, width)
    if not section or not section.box then
        return 0
    end
    width = width or section.box:GetWidth() or GridUI.DEFAULT_CONTENT_W
    return GridUI.SetBoxItems(section, width)
end

local function ReleaseCellFrame(cell)
    if not cell then
        return
    end
    cell:SetScript("OnEnter", nil)
    cell:SetScript("OnLeave", nil)
    cell:SetScript("OnClick", nil)
    cell:SetScript("OnDragStart", nil)
    cell:SetScript("OnDragStop", nil)
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

function GridUI.ClearSectionCells(section)
    if not section or not section.cells then
        return
    end
    for i = 1, #section.cells do
        ReleaseCellFrame(section.cells[i])
    end
    wipe(section.cells)
end

function GridUI.BindDropBoxHandlers(frame, dropKind, handlers)
    if not frame then
        return
    end
    handlers = handlers or {}
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    local function acceptDrop()
        if handlers.dragState and handlers.dragState._consumableDragFrom then
            local Cons = _G.FluxNCConsumables
            local items = Cons and Cons.GetConfigItems and Cons.GetConfigItems() or {}
            local toIndex = math.max(1, #items)
            return FinishGridDragReorder(handlers.dragState, toIndex, handlers.onStructureChanged)
        end
        if dropKind == "consumable" then
            if handlers.onAcceptConsumable then
                return handlers.onAcceptConsumable()
            end
            local itemID = GridUI.GetCursorItemID()
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
                if handlers.onStructureChanged then
                    handlers.onStructureChanged()
                end
                return true
            end
        end
        return false
    end

    frame:SetScript("OnReceiveDrag", function()
        acceptDrop()
    end)
    frame:SetScript("OnMouseUp", function(_, btn)
        if btn ~= "LeftButton" or select(1, GetCursorInfo()) ~= "item" then
            return
        end
        acceptDrop()
    end)
end

function GridUI.CreateSection(parent, title, hint, dropKind, handlers)
    local section = { cells = {}, hintText = hint or "" }
    section.header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    section.header:SetText(title)
    section.header:SetTextColor(1, 0.82, 0)

    section.box = CreateFrame("Frame", nil, parent, GridUI.backdropTemplate)
    section.box:SetSize(GridUI.DEFAULT_CONTENT_W, GridUI.MIN_DROP_H)
    section.box:EnableMouse(true)
    if section.box.SetBackdrop then
        section.box:SetBackdrop(GridUI.DROP_BACKDROP)
        section.box:SetBackdropColor(0.06, 0.06, 0.08, 0.55)
        section.box:SetBackdropBorderColor(0.35, 0.35, 0.4, 0.9)
    end
    if dropKind then
        GridUI.BindDropBoxHandlers(section.box, dropKind, handlers)
    end
    section.box._hint = section.box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    section.box._hint:SetPoint("CENTER")
    section.box._hint:SetJustifyH("CENTER")
    section.box._hint:SetText(hint or "")
    section.box._hint:SetAlpha(0.75)
    return section
end

function GridUI.SetBoxItems(section, width)
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
    local h = GridUI.LayoutFlowGrid(box, cells)
    box:SetHeight(h)
    return h
end

function GridUI.LayoutSectionAt(section, content, width, y)
    section.header:ClearAllPoints()
    section.header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    y = y + 16
    section.box:ClearAllPoints()
    section.box:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    local h = GridUI.SetBoxItems(section, width)
    return y + h + GridUI.SECTION_GAP
end

local function GetRestockTarget(itemId, cell)
    itemId = tonumber(itemId)
    if not itemId then
        return 0
    end
    if cell and cell._isChronoboon then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.GetChronoboonRestockTarget then
            return Cons.GetChronoboonRestockTarget() or 0
        end
        return 0
    end
    local Cons = _G.FluxNCConsumables
    if Cons and Cons.GetPresetRestockTarget then
        return Cons.GetPresetRestockTarget(itemId) or 0
    end
    return 0
end

local function CommitRestockTarget(itemId, quantity, cell)
    itemId = tonumber(itemId)
    if not itemId then
        return
    end
    quantity = tonumber(quantity) or 0
    if cell and cell._isChronoboon then
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.SetChronoboonRestockTarget then
            if Cons.EnsureChronoboonPresetEntry and Cons.GetDefaultChronoboonItemID then
                local chronoID = (Cons.GetCanonicalChronoboonID and Cons.GetCanonicalChronoboonID())
                    or Cons.GetDefaultChronoboonItemID()
                if chronoID then
                    Cons.EnsureChronoboonPresetEntry(chronoID)
                end
            end
            Cons.SetChronoboonRestockTarget(quantity)
        end
        return
    end
    local Cons = _G.FluxNCConsumables
    if Cons and Cons.SetPresetRestockTarget then
        Cons.SetPresetRestockTarget(itemId, quantity, true)
    end
end

local function ToggleCellEditBox(cell, itemId, onDataChanged, onEditDone)
    local editBox = cell.editBox
    if not editBox or not cell._countStr then
        return
    end
    if editBox:IsShown() then
        editBox:ClearFocus()
        editBox:Hide()
        GridUI.SetCellCountLabelsVisible(cell, true)
        if onEditDone then
            onEditDone()
        end
    else
        editBox:Show()
        editBox._fluxEnterCommit = nil
        editBox._fluxEscapeCancel = nil
        editBox:SetText(tostring(GetRestockTarget(itemId, cell)))
        editBox:HighlightText(0, 0)
        editBox:SetFocus()
        GridUI.SetCellCountLabelsVisible(cell, false)
    end
end

function GridUI.AttachCooldownOverlay(cell)
    if cell.cooldown then
        return
    end
    local cooldown = CreateFrame("Cooldown", nil, cell, "CooldownFrameTemplate")
    cooldown:SetAllPoints(cell._icon)
    cooldown:SetDrawEdge(false)
    cooldown:SetReverse(false)
    cooldown:SetHideCountdownNumbers(true)
    cooldown:Hide()
    cell.cooldown = cooldown

    local timerText = cell:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    timerText:SetPoint("CENTER", cell._icon, "CENTER", 0, 0)
    timerText:SetJustifyH("CENTER")
    timerText:Hide()
    cell.timerText = timerText
end

function GridUI.UpdateCellCooldown(cell, itemID)
    if not cell or not itemID then
        return
    end
    if not cell.cooldown then
        return
    end

    local Cons = _G.FluxNCConsumables
    local isChronoboon = Cons and Cons.IsChronoboonItem and Cons.IsChronoboonItem(itemID)
    local isSupercharged = isChronoboon and Cons.IsSuperchargedChronoboonItem and Cons.IsSuperchargedChronoboonItem(itemID)

    if isChronoboon and isSupercharged then
        cell.cooldown:Hide()
        if cell.timerText then
            cell.timerText:Hide()
        end
        return
    end

    if isChronoboon and not isSupercharged then
        local startTime, duration, isEnabled = 0, 0, 0
        if C_Item and C_Item.GetItemCooldown then
            local cooldownInfo = C_Item.GetItemCooldown(itemID)
            if cooldownInfo and type(cooldownInfo) == "table" then
                startTime = cooldownInfo.startTime or 0
                duration = cooldownInfo.duration or 0
                isEnabled = (cooldownInfo.isEnabled and 1) or 0
            else
                startTime, duration, isEnabled = C_Item.GetItemCooldown(itemID)
                startTime = startTime or 0
                duration = duration or 0
                isEnabled = isEnabled and 1 or 0
            end
        elseif GetItemCooldown then
            startTime, duration, isEnabled = GetItemCooldown(itemID)
            startTime = startTime or 0
            duration = duration or 0
            isEnabled = isEnabled and 1 or 0
        end
        if isEnabled == 1 and duration > 0 then
            local remaining = (startTime + duration) - GetTime()
            if remaining > 0 then
                cell.cooldown:SetCooldown(startTime, duration)
                cell.cooldown:Show()
                if cell.timerText then
                    if remaining >= 60 then
                        cell.timerText:SetText(tostring(math.ceil(remaining / 60)) .. "m")
                    else
                        cell.timerText:SetText(tostring(math.ceil(remaining)))
                    end
                    cell.timerText:SetTextColor(1, 1, 1, 1)
                    cell.timerText:Show()
                end
                return
            end
        end
        cell.cooldown:Hide()
        if cell.timerText then
            cell.timerText:Hide()
        end
        return
    end

    local buff = Cons and Cons.FindBuffForItem and Cons.FindBuffForItem(itemID)
    local remaining = 0
    if Cons and Cons.GetBuffRemaining then
        remaining = Cons.GetBuffRemaining(buff)
    elseif buff and buff.expirationTime and buff.expirationTime > 0 then
        remaining = buff.expirationTime - GetTime()
    end
    if buff and remaining > 0 then
        local maxDuration = buff.maxDuration or buff.duration or 0
        if maxDuration <= 0 and buff.spellID and GetSpellInfo then
            local _, _, _, _, _, _, _, _, _, spellMaxDuration = GetSpellInfo(buff.spellID)
            if spellMaxDuration and spellMaxDuration > 0 then
                maxDuration = spellMaxDuration / 1000
            end
        end
        if maxDuration <= 0 then
            if remaining > 3600 then
                maxDuration = 7200
            elseif remaining > 1800 then
                maxDuration = 3600
            elseif remaining > 0 then
                maxDuration = 1800
            else
                cell.cooldown:Hide()
                if cell.timerText then
                    cell.timerText:Hide()
                end
                return
            end
        end
        local startTime
        if buff.expirationTime and buff.expirationTime > 0 then
            startTime = buff.expirationTime - maxDuration
            if startTime > GetTime() then
                startTime = GetTime()
                maxDuration = remaining
            end
        else
            startTime = GetTime() - (maxDuration - remaining)
        end
        if buff.durationObject and cell.cooldown.SetCooldownFromDurationObject then
            pcall(cell.cooldown.SetCooldownFromDurationObject, cell.cooldown, buff.durationObject)
        else
            cell.cooldown:SetCooldown(startTime, maxDuration)
        end
        cell.cooldown:Show()
        if cell.timerText then
            if remaining >= 90 then
                cell.timerText:SetText(tostring(math.ceil(remaining / 60)) .. "m")
            else
                cell.timerText:SetText(tostring(math.floor(remaining + 1e-6)))
            end
            cell.timerText:SetTextColor(1, 1, 1, 1)
            cell.timerText:Show()
        end
        return
    end

    cell.cooldown:Hide()
    if cell.timerText then
        cell.timerText:Hide()
    end
end

function GridUI.SetupCellChrome(cell, opts)
    opts = opts or {}
    local iconTex = opts.iconTex or "Interface\\Icons\\INV_Misc_QuestionMark"
    local entry = opts.entry
    local itemId = opts.itemId
    local tierKind = opts.tierKind
    local maxLetters = opts.maxEditLetters or 4

    cell:SetSize(GridUI.CELL_MIN, GridUI.ROW_H)
    cell._layoutWidth = GridUI.CELL_MIN

    if opts.withBackdrop ~= false and cell.SetBackdrop then
        cell:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 7,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        cell:SetBackdropColor(0.06, 0.06, 0.08, 0.72)
    end

    local chrome = CreateFrame("Frame", nil, cell)
    chrome:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
    chrome:SetPoint("TOPRIGHT", cell, "TOPRIGHT", 0, 0)
    chrome:SetHeight(GridUI.CHROME_H)
    cell._chrome = chrome

    local icon = cell:CreateTexture(nil, "ARTWORK")
    icon:SetSize(GridUI.TEX, GridUI.TEX)
    icon:SetPoint("TOP", cell, "TOP", 0, -(GridUI.CHROME_H + 1))
    icon:SetTexture(iconTex)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if entry and entry.merchantChecked and entry.vendorNotSold then
        icon:SetDesaturated(true)
        icon:SetAlpha(0.55)
    elseif entry and entry.merchantChecked and entry.vendorLowerTierOnly then
        icon:SetAlpha(0.85)
    else
        icon:SetDesaturated(false)
        icon:SetAlpha(1)
    end
    cell._icon = icon

    local countStr = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countStr:SetText("0/0")
    GridUI.ConfigureCellCountString(countStr)
    cell._countStr = countStr

    local bankCountStr = cell:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    bankCountStr:Hide()
    GridUI.ConfigureCellBankCountString(bankCountStr)
    cell._bankCountStr = bankCountStr

    local editBox = CreateFrame("EditBox", nil, cell, "InputBoxTemplate")
    editBox:SetSize(36, 15)
    editBox:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -1, 1)
    editBox:SetFontObject("GameFontNormalSmall")
    editBox:SetJustifyH("RIGHT")
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    editBox:SetMaxLetters(maxLetters)
    editBox:Hide()
    cell.editBox = editBox

    if opts.showBank ~= false and (itemId or tierKind) then
        local bankBtn = CreateFrame("Button", nil, chrome)
        bankBtn:SetSize(GridUI.TOGGLE_SIZE, GridUI.TOGGLE_SIZE)
        bankBtn:SetPoint("TOPLEFT", chrome, "TOPLEFT", 0, 0)
        bankBtn:SetFrameLevel(cell:GetFrameLevel() + 5)
        local bankTex = bankBtn:CreateTexture(nil, "OVERLAY")
        bankTex:SetAllPoints()
        bankTex:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
        bankTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        cell._bankBtn = bankBtn
        cell._bankTex = bankTex
        if opts.setupBankBtn then
            opts.setupBankBtn(cell, bankBtn, bankTex)
        end
    end

    if tierKind and opts.showReset then
        local resetBtn = CreateFrame("Button", nil, chrome)
        resetBtn:SetSize(GridUI.TOGGLE_SIZE, GridUI.TOGGLE_SIZE)
        resetBtn:SetPoint("TOPRIGHT", chrome, "TOPRIGHT", 0, 0)
        resetBtn:SetFrameLevel(cell:GetFrameLevel() + 5)
        local resetTex = resetBtn:CreateTexture(nil, "OVERLAY")
        resetTex:SetAllPoints()
        resetTex:SetTexture("Interface\\Buttons\\UI-RefreshButton")
        resetTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        resetTex:SetAlpha(0.85)
        cell._resetBtn = resetBtn
        if opts.setupResetBtn then
            opts.setupResetBtn(cell, resetBtn, resetTex)
        end
    end

    if opts.section then
        cell._relayoutSection = opts.section
        cell._fluxSection = opts.section
    end

    return cell
end

function GridUI.RefreshConsumableCell(cell, skipRelayout)
    if not cell or not cell._countStr then
        return
    end
    local have, tgt, countBank, bankCount = 0, 0, false, 0
    if cell._itemId then
        local Cons = _G.FluxNCConsumables
        if cell._isChronoboon and Cons and Cons.GetChronoboonBagCount then
            have = Cons.GetChronoboonBagCount()
        else
            have = GridUI.GetChargeAwareCount(cell._itemId)
        end
        tgt = GetRestockTarget(cell._itemId, cell)
        local FV = _G.FluxVendorAuto
        if FV and FV.GetRestockItemFlags then
            countBank = FV.GetRestockItemFlags(cell._itemId).countBank == true
        end
        if cell._isChronoboon and Cons and Cons.GetChronoboonBankCount then
            bankCount = Cons.GetChronoboonBankCount()
        else
            bankCount = GridUI.GetChargeAwareBankCount(cell._itemId)
        end
        cell._countBank = countBank
    else
        return
    end
    GridUI.FitCellCountDisplay(cell, have, bankCount, tgt, countBank, cell._tierKind)
    if cell._refreshBankBtn then
        cell._refreshBankBtn()
    end
    if cell._mode == "config" and cell._itemId then
        GridUI.UpdateCellCooldown(cell, cell._itemId)
    end
    if not skipRelayout and cell._relayoutSection then
        local width = cell._relayoutSection.box:GetWidth() or GridUI.DEFAULT_CONTENT_W
        GridUI.RelayoutSection(cell._relayoutSection, width)
    end
end

function GridUI.CreateConsumableCell(parent, opts)
    opts = opts or {}
    local itemId = opts.itemId
    local iconTex = opts.icon
        or (itemId and GetItemIcon and GetItemIcon(itemId))
        or "Interface\\Icons\\INV_Misc_QuestionMark"
    local dragState = opts.dragState
    local onStructureChanged = opts.onStructureChanged
    local onDataChanged = opts.onDataChanged
    local onEditBlocked = opts.onEditBlocked
    local onEditDone = opts.onEditDone
    local showTooltip = opts.showTooltip
    local isChronoboon = opts.isChronoboon == true
    local consumableIndex = opts.consumableIndex
    local mode = opts.mode or "restock"
    local entry = opts.entry

    local cell = CreateFrame("Button", nil, parent, GridUI.backdropTemplate)
    cell:EnableMouse(true)
    cell._itemId = itemId
    cell._isChronoboon = isChronoboon
    cell._consumableIndex = consumableIndex
    cell._mode = mode
    cell._entry = entry
    cell.itemID = itemId

    GridUI.SetupCellChrome(cell, {
        iconTex = iconTex,
        entry = entry,
        itemId = itemId,
        section = opts.section,
        setupBankBtn = itemId and function(cell, bankBtn, bankTex)
            local function IsBankCountOn()
                local FV = _G.FluxVendorAuto
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
                if itemId and FV and FV.SetRestockItemFlag then
                    FV.SetRestockItemFlag(itemId, "countBank", not IsBankCountOn(), true)
                end
                RefreshBankBtn()
                GridUI.RefreshConsumableCell(cell)
                if onDataChanged then
                    onDataChanged()
                end
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
    })

    local countStr = cell._countStr
    local editBox = cell.editBox

    if mode == "config" and not isChronoboon then
        GridUI.AttachCooldownOverlay(cell)
    end

    local function finishEdit(box)
        local v = tonumber(box:GetText()) or 0
        CommitRestockTarget(itemId, v, cell)
        box:Hide()
        GridUI.SetCellCountLabelsVisible(cell, true)
        GridUI.RefreshConsumableCell(cell)
        if onDataChanged then
            onDataChanged()
        end
    end

    editBox:SetScript("OnEnterPressed", function(box)
        finishEdit(box)
        box._fluxEnterCommit = true
        box:ClearFocus()
        if onEditDone then
            onEditDone()
        end
    end)
    editBox:SetScript("OnEscapePressed", function(box)
        box._fluxEscapeCancel = true
        box:ClearFocus()
        box:SetText(tostring(GetRestockTarget(itemId, cell)))
        box:Hide()
        GridUI.SetCellCountLabelsVisible(cell, true)
        box._fluxEscapeCancel = nil
        if onEditDone then
            onEditDone()
        end
    end)
    editBox:SetScript("OnEditFocusLost", function(box)
        if box._fluxEnterCommit then
            box._fluxEnterCommit = nil
            if onEditDone then
                onEditDone()
            end
            return
        end
        if box._fluxEscapeCancel then
            return
        end
        if not box:IsShown() then
            if onEditDone then
                onEditDone()
            end
            return
        end
        finishEdit(box)
        if onEditDone then
            onEditDone()
        end
    end)

    local function finishDragReorder(cell)
        local fromIndex = dragState and dragState._consumableDragFrom
        if not fromIndex or not cell or not cell._consumableIndex then
            return false
        end
        local toIndex = ComputeDropInsertIndex(cell, fromIndex)
        return FinishGridDragReorder(dragState, toIndex, onStructureChanged)
    end

    local function acceptCursorAtIndex(cell)
        local cursorID = GridUI.GetCursorItemID()
        if not cursorID or not cell or not cell._consumableIndex then
            return false
        end
        local Cons = _G.FluxNCConsumables
        if not Cons or not Cons.AddItemAtIndex then
            return false
        end
        local index = cell._consumableIndex
        if cell.GetLeft and cell.GetRight then
            local left, right = cell:GetLeft(), cell:GetRight()
            if left and right then
                local cx = select(1, GetCursorPosition()) / UIParent:GetEffectiveScale()
                if cx > ((left + right) / 2) then
                    index = index + 1
                end
            end
        end
        ClearCursor()
        Cons.AddItemAtIndex(cursorID, index)
        if Cons.ForceUpdate then
            pcall(Cons.ForceUpdate)
        end
        if onStructureChanged then
            onStructureChanged()
        end
        return true
    end

    cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    if not isChronoboon then
        cell:RegisterForDrag("LeftButton")
    end

    cell:SetScript("OnReceiveDrag", function(self)
        if isChronoboon then
            return
        end
        local cursorID = GridUI.GetCursorItemID()
        if cursorID and self._consumableIndex then
            acceptCursorAtIndex(self)
            return
        end
        if dragState and dragState._consumableDragFrom and self._consumableIndex then
            finishDragReorder(self)
        end
    end)

    if not isChronoboon then
        cell:SetScript("OnDragStart", function(self)
            if self._consumableIndex and dragState then
                dragState._consumableDragFrom = self._consumableIndex
                dragState._isDragging = true
                self:SetAlpha(0.5)
                if dragState.ShowDragGhost and self._itemId then
                    dragState.ShowDragGhost(self._itemId)
                end
            end
        end)
        cell:SetScript("OnDragStop", function(self)
            self:SetAlpha(1)
            if not dragState or not dragState._consumableDragFrom then
                return
            end
            local pendingFrom = dragState._consumableDragFrom
            if Timer and Timer.After then
                Timer.After(0.05, function()
                    if dragState._consumableDragFrom == pendingFrom then
                        dragState._consumableDragFrom = nil
                        dragState._isDragging = false
                        if dragState.HideDragGhost then
                            dragState.HideDragGhost()
                        end
                    end
                end)
            end
        end)
    end

    cell:SetScript("OnEnter", function(self)
        if showTooltip then
            showTooltip(self, itemId)
        elseif itemId then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if GameTooltip.SetItemByID then
                pcall(GameTooltip.SetItemByID, GameTooltip, itemId)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffaaaaaaClick:|r set restock target", 0.65, 0.7, 0.75, true)
            if not isChronoboon then
                GameTooltip:AddLine("|cffaaaaaaRight-click:|r remove from preset", 0.65, 0.7, 0.75, true)
                GameTooltip:AddLine("|cffaaaaaaDrag:|r reorder (left/right half inserts between)", 0.65, 0.7, 0.75, true)
            end
            GameTooltip:Show()
        end
    end)
    cell:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    cell:SetScript("OnClick", function(self, btn)
        if isChronoboon then
            if opts.onChronoboonFlyout and GridUI.IsRightClick(btn) then
                opts.onChronoboonFlyout(self)
                return
            end
            if opts.onChronoboonEdit and not GridUI.IsRightClick(btn) then
                opts.onChronoboonEdit(self)
                return
            end
            ToggleCellEditBox(self, itemId, onDataChanged, onEditDone)
            return
        end

        if select(1, GetCursorInfo()) == "item" then
            if self._consumableIndex then
                acceptCursorAtIndex(self)
            end
            return
        end
        if dragState and dragState._consumableDragFrom and self._consumableIndex then
            finishDragReorder(self)
            return
        end
        if GridUI.IsRightClick(btn) then
            local Cons = _G.FluxNCConsumables
            -- Shift-right-click clears a learned ground-placed aura binding
            if IsShiftKeyDown and IsShiftKeyDown()
                and Cons and Cons.ClearGroundAuraBinding
                and Cons.GetGroundAuraBinding and Cons.GetGroundAuraBinding(itemId) then
                Cons.ClearGroundAuraBinding(itemId)
                if Cons.ForceUpdate then
                    pcall(Cons.ForceUpdate)
                end
                if showTooltip then
                    showTooltip(self, itemId)
                end
                if onDataChanged then
                    onDataChanged()
                end
                return
            end
            if Cons and Cons.RemoveItemAtIndex and self._consumableIndex then
                Cons.RemoveItemAtIndex(self._consumableIndex)
                if Cons.ForceUpdate then
                    pcall(Cons.ForceUpdate)
                end
                if onStructureChanged then
                    onStructureChanged()
                end
            end
            return
        end
        if onEditBlocked and onEditBlocked() then
            return
        end
        ToggleCellEditBox(self, itemId, onDataChanged, onEditDone)
    end)

    GridUI.RefreshConsumableCell(cell, true)
    cell:Show()

    if opts.cellsList then
        opts.cellsList[#opts.cellsList + 1] = cell
        cell._relayoutSection = cell._relayoutSection or { box = parent, cells = opts.cellsList }
    end
    if opts.widgetCells then
        opts.widgetCells[#opts.widgetCells + 1] = cell
    end
    if opts.allCells then
        opts.allCells[#opts.allCells + 1] = cell
    end

    return cell
end

function GridUI.RebuildConfigHost(host)
    if not host or not host.content then
        return 0
    end
    if host.isDragging and host.isDragging() then
        return host._lastHeight or 0
    end

    local width = host.width or GridUI.DEFAULT_CONTENT_W
    host.allCells = host.allCells or {}
    wipe(host.allCells)

    if host.consumablesSection then
        GridUI.ClearSectionCells(host.consumablesSection)
        local section = host.consumablesSection

        if host.chronoEnabled and host.chronoEnabled() then
            local Cons = _G.FluxNCConsumables
            local itemID = Cons and (
                (Cons.GetCanonicalChronoboonID and Cons.GetCanonicalChronoboonID())
                or (Cons.GetDefaultChronoboonItemID and Cons.GetDefaultChronoboonItemID())
            )
            if itemID then
                GridUI.CreateConsumableCell(section.box, {
                    itemId = itemID,
                    isChronoboon = true,
                    mode = "config",
                    onChronoboonEdit = host.onChronoboonEdit,
                    onChronoboonFlyout = host.onChronoboonFlyout,
                    showTooltip = host.showTooltip,
                    onDataChanged = host.onDataChanged,
                    cellsList = section.cells,
                    section = section,
                    allCells = host.allCells,
                })
            end
        end

        local items = {}
        local Cons = _G.FluxNCConsumables
        if Cons and Cons.GetConfigItems then
            items = Cons.GetConfigItems()
        elseif Cons and Cons.GetItems then
            items = Cons.GetItems()
        end
        for i, itemID in ipairs(items) do
            GridUI.CreateConsumableCell(section.box, {
                itemId = itemID,
                consumableIndex = i,
                mode = "config",
                dragState = host.dragState,
                showTooltip = host.showTooltip,
                onStructureChanged = host.onStructureChanged,
                onDataChanged = host.onDataChanged,
                onEditBlocked = host.isDragging,
                cellsList = section.cells,
                section = section,
                allCells = host.allCells,
            })
            if C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(itemID)
            end
        end
    end

    local y = 0
    if host.consumablesSection then
        y = GridUI.LayoutSectionAt(host.consumablesSection, host.content, width, y)
    end

    host.content:SetWidth(width)
    host.content:SetHeight(math.max(y, GridUI.MIN_DROP_H))
    host._lastHeight = y
    return y
end

function GridUI.RefreshAllCells(cells, relayoutCtx)
    if not cells then
        return
    end
    for i = 1, #cells do
        GridUI.RefreshConsumableCell(cells[i], true)
    end
    if relayoutCtx and relayoutCtx.section then
        GridUI.RelayoutSection(relayoutCtx.section, relayoutCtx.width)
    elseif cells[1] and cells[1]._relayoutSection then
        local section = cells[1]._relayoutSection
        local width = section.box and section.box:GetWidth() or GridUI.DEFAULT_CONTENT_W
        GridUI.RelayoutSection(section, width)
    end
end

function GridUI.UpdateAllCooldowns(cells)
    if not cells then
        return
    end
    for i = 1, #cells do
        local cell = cells[i]
        if cell:IsShown() and cell._itemId and cell._mode == "config" and not cell._isChronoboon then
            GridUI.UpdateCellCooldown(cell, cell._itemId)
        end
    end
end
