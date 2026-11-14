-- Auction-owned tab using the existing FluxUI restock cell chrome/count layout.
local _, ns = ...
local A, L = FluxAuctionRestock, ns.FluxOptionsLocale
local attaching, activating = false, false
local COINS = {
    gold = "Interface/MoneyFrame/UI-GoldIcon", silver = "Interface/MoneyFrame/UI-SilverIcon", copper = "Interface/MoneyFrame/UI-CopperIcon",
}
local function Money(n)
    if n == math.huge then return L.AH_UNLIMITED end
    return GetMoneyString and GetMoneyString(math.ceil(n or 0)) or A.PriceText(n)
end
local function UnitMoney(n)
    if n % 1 == 0 then return Money(n) end
    local copper = ("%.6f"):format(n % 100):gsub("0+$", ""):gsub("%.$", "")
    return ("%d %s %d %s %s %s"):format(math.floor(n / 10000), L.AH_GOLD,
        math.floor(n / 100) % 100, L.AH_SILVER, copper, L.AH_COPPER)
end
local function CellMoney(n)
    if n == math.huge then return L.AH_UNLIMITED end
    local text = ""
    if n >= 10000 then text = math.floor(n / 10000) .. "|T" .. COINS.gold .. ":10:10|t" end
    if n >= 100 then text = text .. math.floor(n / 100) % 100 .. "|T" .. COINS.silver .. ":10:10|t" end
    local copper = ("%.6f"):format(n % 100):gsub("0+$", ""):gsub("%.$", "")
    return text .. copper .. "|T" .. COINS.copper .. ":10:10|t"
end
local function Label(parent, text, x, y, width, font)
    local f = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT", x, y); f:SetWidth(width); f:SetJustifyH("LEFT"); f:SetText(text)
    return f
end
local function Button(parent, text, width, fn)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:RegisterForClicks("LeftButtonUp")
    b:SetSize(width, 22); b:SetText(text); b:SetScript("OnClick", fn)
    return b
end
local function EndTip() GameTooltip:Hide() end
local function SelectionChrome(cell)
    -- Decoration only: the cell remains the sole click/focus target.
    cell.selectionEdges = {}
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local edge = cell:CreateTexture(nil, "OVERLAY")
        edge:SetColorTexture(1, 0.82, 0.12, 1)
        if side == "TOP" or side == "BOTTOM" then
            edge:SetPoint(side .. "LEFT", cell, side .. "LEFT", 0, 0)
            edge:SetPoint(side .. "RIGHT", cell, side .. "RIGHT", 0, 0)
            edge:SetHeight(3)
        else
            edge:SetPoint("TOP" .. side, cell, "TOP" .. side, 0, 0)
            edge:SetPoint("BOTTOM" .. side, cell, "BOTTOM" .. side, 0, 0)
            edge:SetWidth(3)
        end
        edge:Hide(); cell.selectionEdges[#cell.selectionEdges + 1] = edge
    end
end
local function Tip(self, text)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine(text, 1, 1, 1, true); GameTooltip:Show()
end
local function Restore(group)
    local n = group.itemID and A.GetMaxPrice(group.itemID) or 0
    group.gold:SetText(tostring(math.floor(n / 10000)))
    group.silver:SetText(tostring(math.floor(n / 100) % 100))
    group.copper:SetText(tostring(math.floor(n) % 100))
end
local function Save(box)
    local g = box.currencyGroup
    if g.saving then return true end
    if not g.itemID then return false end
    local values = {}
    for i, key in ipairs({ "gold", "silver", "copper" }) do
        local text = g[key]:GetText(); if text == "" then text = "0" end
        if not text:match("^%d+$") then Restore(g); A.Invalidate("badPrice"); return false end
        values[i] = tonumber(text)
    end
    local n = values[1] * 10000 + values[2] * 100 + values[3]
    if not A.Number(n) or n > 1000000000000 or values[2] > 99 or values[3] > 99 then Restore(g); A.Invalidate("badPrice"); return false end
    g.saving = true; box:ClearFocus()
    if n ~= A.GetMaxPrice(g.itemID) then A.SetMaxPrice(g.itemID, n, A.IsPriceUnlimited(g.itemID)) end
    g.saving = false; A.GetRows(true); A.UpdateUI(); return true
end
local function Blur()
    local g = A.frame and A.frame.currencyGroup
    if g then for _, key in ipairs({ "gold", "silver", "copper" }) do g[key]:ClearFocus() end end
end
local function CellIcon(row)
    local modules = { bandage = _G.FluxCombatBandage, healPotion = _G.FluxCombatHealPotion, manaPotion = _G.FluxCombatManaPotion }
    local module = row.tierKind and modules[row.tierKind]
    local button = module and module.Button
    if button and button.ItemId == row.itemID and button.WIcon then
        local texture = button.WIcon:GetTexture(); if texture then return texture end
    end
    local ic = _G.FluxItemClass
    return ic and ic.GetIcon and ic.GetIcon(row.itemID) or row.texture or "Interface/Icons/INV_Misc_QuestionMark"
end
A.CellIcon = CellIcon
local function SetQuantity(cell)
    local row = cell.row
    if not row or row.isCraftMaterial or A.transaction then return end
    local n = tonumber(cell.editBox:GetText())
    if not A.Number(n) or n % 1 ~= 0 then return end
    if row.isTierRestock and FluxRestockTiers then FluxRestockTiers.SetTarget(row.tierKind, n)
    elseif row.restockSource == "consumable" and FluxNCConsumables then FluxNCConsumables.SetPresetRestockTarget(row.upgradeFrom or row.itemID, n)
    else FluxVendorAuto.SetRestockTarget(row.upgradeFrom or row.itemID, n) end
    cell.editBox:Hide(); A.SettingsChanged()
end
local function HideContent()
    if A.frame then A.frame:Hide() end
end
local function Layout(f)
    local width, height = math.max(480, f.owner:GetWidth() - 24), math.max(240, f.owner:GetHeight() - 88)
    if f.layoutWidth == width and f.layoutHeight == height then return end
    f.layoutWidth, f.layoutHeight = width, height
    f.cols = math.max(1, math.floor((width - 40) / 84))
    f.viewportHeight = math.max(84, height - 150)
    f.gridRows = math.max(1, math.floor(f.viewportHeight / 84))
    f.scroll:SetSize(width - 44, f.viewportHeight); f.content:SetWidth(width - 44)
    f.help:SetWidth(width - 24); f.selected:SetWidth(width - 270)
    f.crafting:ClearAllPoints(); f.crafting:SetPoint("TOPLEFT", width - 250, -20)
    f.excess:ClearAllPoints(); f.excess:SetPoint("TOPLEFT", width - 174, -44)
    f.status:ClearAllPoints(); f.status:SetPoint("TOPLEFT", 12, -(height - 66)); f.status:SetWidth(width - 24)
    local primaryWidth = width >= 640 and 220 or 150
    f.primary:SetWidth(primaryWidth)
    if f.refresh then
        f.refresh:SetWidth(width >= 640 and 140 or 120)
        f.refresh:ClearAllPoints(); f.refresh:SetPoint("BOTTOMLEFT", primaryWidth + 24, 8)
    end
end
local function LayoutCells(f, count, revision)
    local y, rowHeight, groups = 0, 0, {}
    for i = 1, count do
        local cell, col = f.cells[i], (i - 1) % f.cols
        if col == 0 and i > 1 then y, rowHeight = y + rowHeight + 26, 0 end
        if col == 0 then groups[#groups + 1] = { first = i, last = i, y = y } end
        cell.nextSlotX, cell.nextSlotY = col * 84, y
        rowHeight = math.max(rowHeight, cell.layoutHeight + (cell.upgradeHeight or 0))
        groups[#groups].last, groups[#groups].height = i, rowHeight
    end
    local height = math.max(f.viewportHeight, count > 0 and y + rowHeight + 26 or 0)
    f.maxScroll = math.max(0, height - f.viewportHeight)
    f.flowGroups = groups
    for i = 1, count do
        local cell = f.cells[i]
        local x, top = cell.nextSlotX, cell.nextSlotY
        cell:SetSize(80, cell.layoutHeight)
        if f.modelRevision ~= revision then return false end
        if cell.slotX ~= x or cell.slotY ~= top then
            cell:ClearAllPoints(); cell:SetPoint("TOPLEFT", x, -top)
            if f.modelRevision ~= revision then return false end
            cell.slotX, cell.slotY = x, top
        end
    end
    if f.contentHeight ~= height then
        f.content:SetHeight(height)
        if f.modelRevision ~= revision then return false end
        f.contentHeight = height
    end
    local offset = f.scroll:GetVerticalScroll() or 0
    if offset > f.maxScroll then f.scroll:SetVerticalScroll(f.maxScroll) end
    return f.modelRevision == revision
end
local function CellKey(row, proposal)
    if row.upgradeOnly then return "upgrade:" .. tostring(row.tierKind) .. ":" .. tostring(proposal.sourceID or 0) end
    return "item:" .. row.itemID
end
local function SameQuantityOwner(a, b)
    return a and b and a.itemID == b.itemID and a.tierKind == b.tierKind
        and a.restockSource == b.restockSource and a.upgradeFrom == b.upgradeFrom
        and a.isCraftMaterial == b.isCraftMaterial and a.upgradeOnly == b.upgradeOnly
end
local function PaintCell(f, cell, revision)
    local row, proposal, grid = cell.row, cell.proposal, FluxConsumablesGridUI
    if not row then return false end
    cell.EnsureChrome()
    if f.modelRevision ~= revision then cell.paintRevision = nil; return false end
    cell._itemId, cell._entry = row.itemID, row
    cell._icon:SetTexture(CellIcon(row))
    grid.ApplyCellCountDisplay(cell, row.bagCount or 0, row.bankCount or 0, row.target or 0, row.countBank, row.tierKind)
    if f.modelRevision ~= revision then cell.paintRevision = nil; return false end
    cell.incoming:SetText((row.pending or 0) > 0 and ("|cff66ccff" .. L.AH_INCOMING:format(row.pending) .. "|r") or "")
    cell.route:SetText(A.RouteText(row))
    cell:SetWidth(80)
    local cap = row.upgradeOnly and A.PriceLimit(proposal.sourceID) or A.PurchaseLimit(row.itemID)
    cell.limit:SetText(CellMoney(cap))
    local editing = row.itemID == A.editorID
    for _, edge in ipairs(cell.selectionEdges) do edge:SetShown(editing) end
    cell:SetBackdropColor(editing and 0.22 or 0.06, editing and 0.16 or 0.06, editing and 0.04 or 0.08, 0.9)
    if cell.SetBackdropBorderColor then
        if editing then cell:SetBackdropBorderColor(1, 0.82, 0.2, 1) else cell:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) end
    end
    cell._bankTex:SetDesaturated(not row.countBank); cell._bankTex:SetAlpha(row.countBank and 1 or 0.3)
    if proposal then
        local ic, id = _G.FluxItemClass, proposal.candidate.itemID
        cell.upgrade.icon:SetTexture(ic and ic.GetIcon and ic.GetIcon(id) or "Interface/Icons/INV_Misc_QuestionMark")
    end
    if f.modelRevision ~= revision then cell.paintRevision = nil; return false end
    cell.paintRevision = revision
    if f.tooltipOwner == cell and f.hoveredCell == cell and cell.RefreshTip and f.tooltipBinding ~= cell.binding then cell.RefreshTip(cell, cap) end
    if cell.upgrade and f.tooltipOwner == f.hoveredUpgrade and f.hoveredUpgrade and f.hoveredUpgrade.card == cell.upgrade and f.hoveredUpgrade.RefreshTip then
        if f.hoveredUpgrade.tooltipProposal ~= proposal then f.hoveredUpgrade.RefreshTip(f.hoveredUpgrade) end
    end
    if f.modelRevision ~= revision then cell.paintRevision = nil; return false end
    return true
end
local function CreatePanel(owner)
    if A.frame then return A.frame end
    local grid = _G.FluxConsumablesGridUI
    if not grid or not grid.SetupCellChrome then return end
    local f = CreateFrame("Frame", "FluxAuctionRestockFrame", owner, "BackdropTemplate")
    f:Hide(); f:SetPoint("TOPLEFT", owner, "TOPLEFT", 12, -54); f:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", -12, 34)
    f:SetFrameLevel(owner:GetFrameLevel() + 50); f:EnableMouse(true)
    f:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16 })
    f:SetBackdropColor(0.06, 0.06, 0.08, 1)
    f.owner = owner
    f.help = Label(f, A.legacy and L.AH_HELP_LEGACY or L.AH_HELP, 12, -8, 1, "GameFontDisableSmall"); f.help:SetHeight(12); f.help:SetWordWrap(false)
    f.scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", 12, -74); f.scroll:EnableMouseWheel(true)
    f.content = CreateFrame("Frame", nil, f.scroll); f.scroll:SetScrollChild(f.content)
    -- Keep the template's scrollbar/range handlers. Scrolling never selects or buys.
    f.scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.min(f.maxScroll or 0, math.max(0, (self:GetVerticalScroll() or 0) - delta * 84)))
    end)
    f.cells, f.activeByKey = {}, {}
    function f.PaintViewport(force)
        local revision, groups = f.modelRevision, f.flowGroups
        if not groups or not f:IsShown() then return end
        local offset = f.scroll:GetVerticalScroll() or 0
        local first, last = 1, #groups
        while first <= #groups and groups[first].y + groups[first].height + 26 < offset do first = first + 1 end
        while last >= first and groups[last].y > offset + f.viewportHeight do last = last - 1 end
        first, last = math.max(1, first - 1), math.min(#groups, last + 1)
        for groupIndex = first, last do
            local group = groups[groupIndex]
            for i = group.first, group.last do
                local cell = f.cells[i]
                if force or cell.paintRevision ~= revision then
                    local ok, painted = pcall(PaintCell, f, cell, revision)
                    if not ok then cell.paintRevision = nil; error(painted, 0) end
                    if not painted then
                        -- A native font/widget callback can synchronously publish a newer model.
                        -- Repair any old paint after that callback without rebinding its controls.
                        if f.modelRevision ~= revision then f.PaintViewport(true) end
                        return
                    end
                end
            end
        end
    end
    f.scroll:HookScript("OnVerticalScroll", function() f.PaintViewport() end)
    function f.Reveal(cell)
        if not cell.row or f.cells[cell.index] ~= cell then return false end
        local top, bottom = cell.slotY, cell.slotY + cell.layoutHeight + (cell.upgradeHeight or 0) + 26
        local offset = f.scroll:GetVerticalScroll() or 0
        if top < offset then f.scroll:SetVerticalScroll(top)
        elseif bottom > offset + f.viewportHeight then f.scroll:SetVerticalScroll(math.min(f.maxScroll, bottom - f.viewportHeight)) end
        return cell.row ~= nil and f.cells[cell.index] == cell
    end
    function f.CreateCell(index)
        local cell = CreateFrame("Button", nil, f.content, grid.backdropTemplate)
        cell.index = index
        -- Native navigation keeps these frame pointers, including hidden editors.
        -- Retain their hierarchy and identity; only decorative regions are lazy.
        cell._chrome = CreateFrame("Frame", nil, cell)
        cell._chrome:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
        cell._chrome:SetPoint("TOPRIGHT", cell, "TOPRIGHT", 0, 0)
        cell._chrome:SetHeight(grid.CHROME_H)
        grid.CreateCellEditBox(cell, 4)
        cell._bankBtn = CreateFrame("Button", nil, cell._chrome)
        cell._bankBtn:SetSize(grid.TOGGLE_SIZE, grid.TOGGLE_SIZE)
        cell._bankBtn:SetPoint("TOPLEFT", cell._chrome, "TOPLEFT", 0, 0)
        cell._bankBtn:SetFrameLevel(cell:GetFrameLevel() + 5)
        function cell.EnsureChrome()
            if cell.chromeReady then return end
            grid.SetupCellChrome(cell, { itemId = 1, showBank = false, reuseChrome = true, reuseEditBox = true })
            local tex = cell._bankBtn:CreateTexture(nil, "OVERLAY")
            tex:SetAllPoints(); tex:SetTexture("Interface\\Icons\\INV_Misc_Coin_01"); tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            cell._bankTex = tex
            SelectionChrome(cell)
            cell.limit = cell._chrome:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cell.limit:SetPoint("TOPRIGHT", -1, -1); cell.limit:SetWidth(63); cell.limit:SetJustifyH("RIGHT")
            cell.incoming = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cell.incoming:SetPoint("TOP", cell, "BOTTOM", 0, -13); cell.incoming:SetWidth(84); cell.incoming:SetHeight(12)
            cell.route = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cell.route:SetPoint("TOP", cell, "BOTTOM", 0, -1); cell.route:SetWidth(84); cell.route:SetHeight(12)
            cell.chromeReady = true
        end
        local function Current(token)
            return cell.binding == token and f.cells[index] == cell and cell.row ~= nil
        end
        cell:SetScript("OnMouseDown", function(self) self.pressBinding = self.binding end)
        cell:SetScript("OnMouseUp", function(self) self.releaseBinding, self.pressBinding = self.pressBinding, nil end)
        cell._bankBtn:SetScript("OnMouseDown", function(self) self.pressBinding = cell.binding end)
        cell._bankBtn:SetScript("OnMouseUp", function(self) self.releaseBinding, self.pressBinding = self.pressBinding, nil end)
        local function Released(control, token)
            if not Current(token) then return false end
            local press = control.releaseBinding or control.pressBinding
            control.releaseBinding, control.pressBinding = nil, nil
            return not press or press == token
        end
        function cell.Bind()
            local token = {}; cell.binding = token
            cell._bankBtn:SetScript("OnClick", function(control)
                if not Released(control, token) or A.transaction then return end
                if not f.Reveal(cell) or not Current(token) then return end
                local row = cell.row
                if row.isTierRestock then FluxRestockTiers.SetCountBankFlag(row.tierKind, not row.countBank)
                else FluxVendorAuto.SetRestockItemFlag(row.upgradeFrom or row.itemID, "countBank", not row.countBank) end
                if A.ResetCraftPlans then A.ResetCraftPlans() end
                A.SettingsChanged()
            end)
            cell:SetScript("OnClick", function(self, button)
            if not Released(self, token) or self.row.upgradeOnly or A.transaction then return end
            if not f.Reveal(cell) or not Current(token) then return end
            for _, other in ipairs(f.cells) do other.editBox:ClearFocus(); other.editBox:Hide() end
            Blur()
            if not Current(token) then return end
            A.Select(self.row.itemID)
            if not Current(token) then return end
            local row = self.row
            if button == "RightButton" and not row.isCraftMaterial then
                cell.EnsureChrome()
                self.editBox:SetText(tostring(row.baseTarget or row.target or 0))
                self.editBox:Show(); self.editBox:SetFocus(); self.editBox:HighlightText()
                grid.SetCellCountLabelsVisible(self, false)
            end
        end)
            cell.editBox:SetScript("OnEnterPressed", function() if Current(token) then SetQuantity(cell); cell.editBox:ClearFocus() end end)
            cell.editBox:SetScript("OnEscapePressed", function(self) if Current(token) then self:Hide(); self:ClearFocus() end end)
            cell.RefreshTip = function(self, cap)
                if not Current(token) then return end
                cap = cap or A.PurchaseLimit(self.row.itemID)
                f.hoveredUpgrade = nil
                f.hoveredCell, f.tooltipOwner, f.tooltipBinding = cell, cell, token
                cell.ShowTip(self, cap)
            end
            cell:SetScript("OnEnter", cell.RefreshTip)
            cell:SetScript("OnLeave", function()
                if f.hoveredCell == cell and f.tooltipBinding == token then f.hoveredCell = nil end
                if f.tooltipOwner == cell and f.tooltipBinding == token then f.tooltipOwner = nil; EndTip() end
            end)
        end
        cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        cell.editBox:HookScript("OnEditFocusLost", function(self) if cell.row and self:IsShown() then SetQuantity(cell) end end)
        cell.editBox:HookScript("OnHide", function() grid.SetCellCountLabelsVisible(cell, true) end)
        function cell.ShowTip(self, cap)
            if not self.row then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetItemByID(self.row.itemID)
            GameTooltip:AddLine(L.AH_LIMIT_TOOLTIP:format(Money(cap)), 1, 0.82, 0.3, true)
            if A.VendorSource then
                local unlimited, price, _, source = A.VendorSource(self.row.itemID)
                if unlimited and price ~= nil then
                    GameTooltip:AddLine(L.AH_VENDOR_BENCHMARK:format(UnitMoney(price),
                        source == "merchant" and L.AH_VENDOR_OBSERVED or L.AH_VENDOR_CATALOGUE), 0.8, 0.8, 0.8, true)
                end
            end
            GameTooltip:AddLine(L.AH_INCOMING_HELP:format(self.row.pending or 0, self.row.mailCount or 0), 0.4, 0.8, 1, true)
            if self.row.isCharge and self.row.unitsPerItem then
                GameTooltip:AddLine(L.AH_CHARGES_HELP:format(self.row.unitsPerItem), 0.8, 0.8, 0.8, true)
            end
            local price, source
            if A.MarketPrice then price, source = A.MarketPrice(self.row.itemID) end
            if price then GameTooltip:AddLine(L.AH_MARKET_PRICE:format(UnitMoney(price), source == "Auctionator" and L.AH_AUCTIONATOR or L.AH_LAST_SCAN), 0.8, 0.8, 0.8, true) end
            GameTooltip:AddLine(L.AH_CELL_HELP, 0.8, 0.8, 0.8, true); GameTooltip:Show()
        end
        function cell.EnsureUpgrade()
            if cell.upgrade then return cell.upgrade end
            local card = CreateFrame("Frame", nil, cell)
            card:SetPoint("TOPLEFT", cell, "BOTTOMLEFT", 0, -28); card:SetSize(80, 44); card:Hide()
            cell.upgrade = card
            card.item = CreateFrame("Button", nil, card)
            card.item:SetPoint("TOPLEFT", 0, 0); card.item:SetSize(24, 24)
            card.icon = card.item:CreateTexture(nil, "ARTWORK"); card.icon:SetAllPoints(card.item)
            local function CandidateTip(self)
                local proposal = card.proposal; if not proposal then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetItemByID(proposal.candidate.itemID)
                if self.upgradeAction then GameTooltip:AddLine(L["AH_UPGRADE_" .. self.upgradeAction:upper()], 1, 0.82, 0.3, true) end
                GameTooltip:AddLine(L.AH_UPGRADE_RESTORE:format(proposal.previousRestore, proposal.candidate.effective), 1, 0.82, 0.3, true)
                GameTooltip:AddLine(L.AH_UPGRADE_COST:format(UnitMoney(proposal.unitPrice), Money(A.Number(GetMoney()) or 0)), 1, 1, 1, true)
                GameTooltip:AddLine(L.AH_UPGRADE_HELP, 0.8, 0.8, 0.8, true)
                GameTooltip:AddLine(L.AH_UPGRADE_BLACKLIST_HELP, 0.8, 0.8, 0.8, true); GameTooltip:Show()
            end
            for _, action in ipairs({ "upgrade", "keep", "blacklist" }) do
                local label = action == "keep" and L.AH_UPGRADE_KEEP_SHORT or action == "blacklist" and L.AH_UPGRADE_BLACKLIST_SHORT or L.AH_UPGRADE_UPGRADE
                local width = action == "keep" and 36 or action == "blacklist" and 42 or 52
                local control = Button(card, label, width, nil)
                card[action] = control; control:SetHeight(18)
                control.upgradeAction = action
                control:SetScript("OnMouseDown", function(self) self.pressProposal = card.proposal end)
                control:SetScript("OnMouseUp", function(self) self.releaseProposal, self.pressProposal = self.pressProposal, nil end)
            end
            card.upgrade:SetPoint("TOPLEFT", 28, 0)
            card.keep:SetPoint("TOPLEFT", 0, -26)
            card.blacklist:SetPoint("TOPLEFT", 38, -26)
            function card.BindProposal(proposal)
                card.proposal = proposal
                if not proposal and f.tooltipOwner and f.tooltipOwner.card == card then
                    f.tooltipOwner, f.hoveredUpgrade = nil, nil; EndTip()
                end
                local function BindTip(control)
                    control.card = card
                    control.RefreshTip = function(self)
                        if proposal and card.proposal == proposal and cell.proposal == proposal then
                            self.tooltipProposal = proposal
                            f.hoveredCell = nil
                            f.hoveredUpgrade, f.tooltipOwner, f.tooltipBinding = self, self, proposal
                            CandidateTip(self)
                        end
                    end
                    control:SetScript("OnEnter", control.RefreshTip)
                    control:SetScript("OnLeave", function(self)
                        if f.hoveredUpgrade == self and f.tooltipBinding == proposal then f.hoveredUpgrade = nil end
                        if f.tooltipOwner == self and f.tooltipBinding == proposal then f.tooltipOwner = nil; EndTip() end
                    end)
                end
                BindTip(card.item)
                for _, action in ipairs({ "upgrade", "keep", "blacklist" }) do
                    local control = card[action]
                    control:SetScript("OnClick", function(self)
                        if not proposal or card.proposal ~= proposal or cell.proposal ~= proposal or f.cells[index] ~= cell then return end
                        local press = self.releaseProposal or self.pressProposal
                        self.releaseProposal, self.pressProposal = nil, nil
                        if press and press ~= proposal then return end
                        if not f.Reveal(cell) or card.proposal ~= proposal or cell.proposal ~= proposal then return end
                        Blur(); A.ResolveUpgrade(proposal, action)
                    end)
                    BindTip(control)
                end
            end
            return card
        end
        f.cells[index] = cell
        return cell
    end
    f.crafting = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    f.crafting:SetSize(24, 24); f.crafting.Text:SetText(L.AH_CRAFT_TOGGLE)
    f.crafting:SetScript("OnClick", function(self) Blur(); A.SetPreferCrafting(self:GetChecked() == true) end)
    f.crafting:SetScript("OnEnter", function(self) Tip(self, L.AH_CRAFT_TOGGLE_HELP) end); f.crafting:SetScript("OnLeave", EndTip)
    f.selected = Label(f, "", 12, -26, 1, "GameFontNormal"); f.selected:SetHeight(14); f.selected:SetWordWrap(false)
    local g = {}; f.currencyGroup = g
    for i, key in ipairs({ "gold", "silver", "copper" }) do
        local box = CreateFrame("EditBox", nil, f, "InputBoxTemplate"); g[key] = box; box.currencyGroup = g
        box:SetPoint("TOPLEFT", 16 + (i - 1) * 76, -44); box:SetSize(i == 1 and 54 or 38, 20)
        box.coin = box:CreateTexture(nil, "ARTWORK"); box.coin:SetTexture(COINS[key]); box.coin:SetSize(12, 12)
        box.coin:SetPoint("LEFT", box, "RIGHT", 3, 0)
        box:SetScript("OnEnter", function(self) Tip(self, L["AH_" .. key:upper()]) end); box:SetScript("OnLeave", EndTip)
        box:SetAutoFocus(false); box:SetNumeric(true); box:SetMaxLetters(i == 1 and 9 or 2)
        box:SetScript("OnEnterPressed", Save)
        box:SetScript("OnEscapePressed", function(self) Restore(g); self:ClearFocus() end)
        box:SetScript("OnTabPressed", function(self, reverse)
            if Save(self) then local nextBox = g[({ "gold", "silver", "copper" })[((i - 1 + (reverse and -1 or 1)) % 3) + 1]]; nextBox:SetFocus(); nextBox:HighlightText() end
        end)
        box:HookScript("OnEditFocusLost", function(self) if g.itemID then Save(self) end end)
    end
    f.noLimit = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    f.noLimit:SetPoint("TOPLEFT", 224, -44); f.noLimit:SetSize(24, 24); f.noLimit.Text:SetText(L.AH_UNLIMITED)
    f.noLimit.Text:ClearAllPoints(); f.noLimit.Text:SetPoint("LEFT", f.noLimit, "RIGHT", 0, 0)
    f.noLimit.Text:SetWidth(56); f.noLimit.Text:SetWordWrap(false); f.noLimit.Text:SetJustifyH("LEFT")
    f.noLimit:SetScript("OnClick", function(self)
        if not g.itemID or A.transaction or A.state == "quoting" then
            self:SetChecked(g.itemID and A.IsPriceUnlimited(g.itemID) or false); return
        end
        local unlimited = self:GetChecked() == true
        Blur(); A.SetPriceUnlimited(g.itemID, unlimited)
    end)
    f.noLimit:SetScript("OnEnter", function(self) Tip(self, L.AH_NO_LIMIT_HELP) end); f.noLimit:SetScript("OnLeave", EndTip)
    f.excess = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    f.excess:SetSize(24, 24); f.excess.Text:SetText(L.AH_EXCESS)
    f.excess.Text:SetWidth(140); f.excess.Text:SetHeight(28); f.excess.Text:SetWordWrap(true); f.excess.Text:SetJustifyH("LEFT")
    f.excess:SetScript("OnClick", function(self)
        if not A.legacy or A.transaction then self:SetChecked(A.Settings().allowExcessStacks == true); return end
        A.Settings().allowExcessStacks = self:GetChecked() == true; A.ResetCraftPlans(); A.SettingsChanged()
    end)
    f.excess:SetScript("OnEnter", function(self) Tip(self, L.AH_EXCESS_HELP) end); f.excess:SetScript("OnLeave", EndTip)
    f.status = Label(f, "", 12, 0, 1); f.status:SetHeight(36); f.status:SetJustifyV("TOP")
    f.primary = Button(f, L.AH_SEARCH, 150, function()
        for _, key in ipairs({ "gold", "silver", "copper" }) do if g[key]:HasFocus() and not Save(g[key]) then return end end
        A.Primary()
    end)
    f.primary:SetPoint("BOTTOMLEFT", 12, 8)
    if not A.legacy then
        f.refresh = Button(f, L.AH_REFRESH, 138, function()
            if A.legacy then return end
            Blur(); A.ResetCraftPlans()
            if A.ResetPotionDiscovery then A.ResetPotionDiscovery() end
            A.ScanQueue(true, true)
        end)
    end
    Layout(f)
    f:HookScript("OnSizeChanged", function() if A.frame == f and f:IsShown() then A.UpdateUI() end end)
    f:SetScript("OnShow", function() A.ShowSession(); A.UpdateUI() end)
    f:SetScript("OnHide", function()
        Blur()
        for _, cell in ipairs(f.cells) do cell.editBox:ClearFocus(); cell.editBox:Hide() end
        f.hoveredCell, f.hoveredUpgrade, f.tooltipOwner, f.tooltipBinding = nil, nil, nil, nil
        A.HideSession(); EndTip()
    end)
    owner.FluxRestockContent = f; A.frame = f
    return f
end
function A.UpdateUI()
    local f = A.frame; if not f or not f:IsShown() then return end
    local rows, grid = {}, FluxConsumablesGridUI
    for _, row in ipairs(A.GetRows(false)) do rows[#rows + 1] = row end
    local proposals = A.GetUpgradeProposals and A.GetUpgradeProposals() or {}
    local byRow = {}
    for _, proposal in ipairs(proposals) do
        local found
        for _, row in ipairs(rows) do
            if not byRow[row] and (proposal.sourceID == row.itemID or (not proposal.sourceID and proposal.kind == row.tierKind)) then
                byRow[row], found = proposal, true; break
            end
        end
        if not found then
            local id = proposal.sourceID or proposal.candidate.itemID
            local row = { itemID = id, tierKind = proposal.kind, upgradeOnly = true, target = proposal.target }
            rows[#rows + 1], byRow[row] = row, proposal
        end
    end
    table.sort(rows, A.RowLess)
    Layout(f)
    f.help:SetText(A.legacy and L.AH_HELP_LEGACY or L.AH_HELP)
    local selected = A.FindRow(A.editorID)
    if not selected then
        for _, row in ipairs(rows) do
            if not row.upgradeOnly then A.editorID, selected = row.itemID, row; break end
        end
    end
    for i = #f.cells + 1, #rows do f.CreateCell(i) end
    local cells, active = f.cells, {}
    for i, row in ipairs(rows) do
        local key = CellKey(row, byRow[row])
        active[key] = cells[i]
    end
    -- Preserve the original maximum-row slot pointers and native hierarchy.
    -- Scrolling paints those slots; only model changes can change their owners.
    f.activeByKey = active
    local revision = (f.modelRevision or 0) + 1; f.modelRevision = revision
    for i, cell in ipairs(cells) do
        local row = rows[i]
        if cell.row ~= row then
            local sameOwner = SameQuantityOwner(cell.row, row)
            if not sameOwner then cell.editBox:Hide(); cell.editBox:ClearFocus() end
            if not row and f.tooltipOwner == cell then f.tooltipOwner, f.hoveredCell = nil, nil; EndTip() end
            cell.row = row
            if row and not sameOwner then cell.Bind() elseif not row then cell.binding = nil end
        end
        local proposal = row and byRow[row]
        cell.proposal, cell.upgradeHeight = proposal, proposal and 50 or 0
        if proposal then cell.EnsureUpgrade() end
        if cell.upgrade and cell.upgrade.proposal ~= proposal then cell.upgrade.BindProposal(proposal) end
        if row then
            local bankText = grid.FormatCellBankLine(row.bankCount or 0, row.countBank)
            if f.modelRevision ~= revision then return end
            cell.layoutHeight = grid.ROW_H + (bankText ~= nil and grid.BANK_COUNT_H or 0)
        end
    end
    for _, cell in ipairs(cells) do
        cell:SetShown(cell.row ~= nil)
        if cell.upgrade then cell.upgrade:SetShown(cell.proposal ~= nil) end
        if cell.row then
            cell._bankBtn:SetShown(not cell.row.upgradeOnly); cell._bankBtn:SetEnabled(not A.transaction)
            cell:SetEnabled(not A.transaction)
            if cell.proposal then
                local enabled = A.state == "upgrade" and not InCombatLockdown() and not A.transaction
                for _, action in ipairs({ "upgrade", "keep", "blacklist" }) do
                    if cell.upgrade[action]:IsEnabled() ~= enabled then cell.upgrade[action]:SetEnabled(enabled) end
                end
            end
        end
        if f.modelRevision ~= revision then return end
    end
    if not LayoutCells(f, #rows, revision) then return end
    local selectedCell = selected and active["item:" .. selected.itemID]
    if f.selectedCell ~= selectedCell and f.selectedCell and f.selectedCell.selectionEdges then
        for _, edge in ipairs(f.selectedCell.selectionEdges) do edge:Hide() end
    end
    f.selectedCell = selectedCell
    f.PaintViewport()
    if f.modelRevision ~= revision then return end
    local g = f.currencyGroup
    if g.itemID ~= (selected and selected.itemID) then Blur() end
    g.itemID = selected and selected.itemID
    f.selected:SetText(selected and L.AH_LIMIT_SHORT:format(selected.name or tostring(selected.itemID)) or L.AH_SELECT_CELL)
    if not g.gold:HasFocus() and not g.silver:HasFocus() and not g.copper:HasFocus() then Restore(g) end
    for _, key in ipairs({ "gold", "silver", "copper" }) do g[key]:SetEnabled(selected ~= nil and not A.transaction) end
    f.noLimit:SetChecked(selected ~= nil and A.IsPriceUnlimited(selected.itemID))
    f.noLimit:SetEnabled(selected ~= nil and not A.transaction and A.state ~= "quoting")
    f.crafting:SetChecked(A.PreferCrafting()); f.crafting:SetEnabled(not A.transaction and A.state ~= "quoting")
    f.excess:SetShown(A.legacy == true)
    f.excess:SetChecked(A.Settings().allowExcessStacks == true); f.excess:SetEnabled(A.legacy == true and not A.transaction)
    local busy = A.state == "searching" or A.state == "quoting" or A.state == "buying" or A.state == "classifying" or A.state == "upgrade"
    f.primary:SetEnabled(A.houseOpen == true and not busy)
    if f.refresh then
        f.refresh:SetShown(not A.legacy); f.refresh:SetEnabled(not A.legacy and not A.transaction)
    end
    local offer, text = A.offer
    if offer and A.state == "ready" then
        local row = A.FindRow(offer.itemID)
        text = L.AH_OFFER:format(row and row.name or tostring(offer.itemID), offer.quantity, Money(offer.total), UnitMoney(offer.total / offer.quantity))
        if row and row.isCharge and row.unitsPerItem then
            text = text .. "\n" .. L.AH_CHARGES_OFFER:format(offer.quantity * row.unitsPerItem)
        end
        local extra = offer.quantity - (row and A.Need(row) or 0); if extra > 0 then text = text .. "\n" .. L.AH_SURPLUS:format(extra) end
        f.primary:SetText(L.AH_BUY:format(offer.quantity))
    else
        text = #rows == 0 and not busy and A.status ~= "potionData" and L.AH_EMPTY or L["AH_STATUS_" .. A.status] or L.AH_STATUS_intro
        f.primary:SetText(busy and L.AH_WAIT or L.AH_BUY_NEXT)
    end
    f.status:SetText(text)
end
function A.Toggle()
    A.legacy = A.IsLegacy()
    local owner = A.legacy and _G.AuctionFrame or _G.AuctionHouseFrame
    if not owner or not owner:IsShown() then (ns.Flux.Print or print)(L.AH_STATUS_openAH); return end
    A.houseOpen = true; A.AttachButton()
    local f = CreatePanel(owner); if not f then return end
    activating = true
    if not A.legacy and owner.SetDisplayMode and owner.tabsForDisplayMode then
        A.displayMode = A.displayMode or { "FluxRestockContent" }
        owner.tabsForDisplayMode[A.displayMode] = A.launcher:GetID()
        owner:SetDisplayMode(A.displayMode)
    elseif PanelTemplates_SetTab then PanelTemplates_SetTab(owner, A.launcher:GetID()) end
    f:Show(); activating = false
end
function A.AttachButton()
    if attaching then return end
    local owner = A.legacy and _G.AuctionFrame or _G.AuctionHouseFrame
    if not owner then return end
    attaching = true
    if not A.launcher then
        A.launcher = CreateFrame("Button", "FluxAuctionRestockTab", owner, A.legacy and "AuctionTabTemplate" or "AuctionHouseFrameTabTemplate")
        A.launcher:SetText(L.AH_TAB); A.launcher:SetScript("OnClick", A.Toggle)
        owner:HookScript("OnHide", HideContent)
        if owner.SetDisplayMode then hooksecurefunc(owner, "SetDisplayMode", function(_, mode) if not activating and mode ~= A.displayMode then HideContent() end end) end
        if PanelTemplates_SetTab then hooksecurefunc("PanelTemplates_SetTab", function(frame, id) if frame == owner and not activating and id ~= A.launcher:GetID() then HideContent() end end) end
        if PanelTemplates_SetNumTabs then hooksecurefunc("PanelTemplates_SetNumTabs", function(frame) if frame == owner and not attaching then A.AttachButton() end end) end
    end
    local name, tabs = owner:GetName(), owner.Tabs
    local count = math.max(tonumber(owner.numTabs) or 0, tabs and #tabs or 0)
    for i = 1, 30 do if name and _G[name .. "Tab" .. i] then count = math.max(count, i) end end
    local ownIndex, last
    for i = 1, count do
        local alias = name and _G[name .. "Tab" .. i]
        local tab = tabs and tabs[i] or alias
        if tab == A.launcher and alias and alias ~= A.launcher then tab = alias; if tabs then tabs[i] = alias end end
        if tab and tab ~= A.launcher and alias == A.launcher and name then _G[name .. "Tab" .. i] = tab end
        if tab == A.launcher then ownIndex = i
        elseif tab then
            last = tab
            if not tab._fluxAuctionRestockObserved then tab._fluxAuctionRestockObserved = true; tab:HookScript("OnClick", HideContent) end
        end
    end
    if not ownIndex then ownIndex = count + 1 end
    if tabs then tabs[ownIndex] = A.launcher end
    if name then _G[name .. "Tab" .. ownIndex] = A.launcher end
    A.launcher:SetID(ownIndex)
    if owner.tabsForDisplayMode and A.displayMode then owner.tabsForDisplayMode[A.displayMode] = ownIndex end
    if PanelTemplates_SetNumTabs then PanelTemplates_SetNumTabs(owner, math.max(count, ownIndex)) else owner.numTabs = math.max(count, ownIndex) end
    A.launcher:ClearAllPoints()
    local previous = ownIndex > 1 and ((tabs and tabs[ownIndex - 1]) or (name and _G[name .. "Tab" .. (ownIndex - 1)]))
    if previous and previous ~= A.launcher then last = previous end
    -- Equal top edges/heights prevent the selected tab dropping below its row.
    -- Center anchoring magnified the Classic/Forever template height difference.
    if last then
        A.launcher:SetHeight(last:GetHeight())
        A.launcher:SetPoint("TOPLEFT", last, "TOPRIGHT", A.legacy and -15 or 3, 0)
    else A.launcher:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 12, 2) end
    if PanelTemplates_TabResize then PanelTemplates_TabResize(A.launcher, 20) end
    A.launcher:Show(); attaching = false
end
SLASH_FLUXAUCTIONRESTOCK1 = "/fluxah"
SlashCmdList.FLUXAUCTIONRESTOCK = function(message)
    if type(message) == "string" and message:match("^%s*debug%s*$") then A.PrintStatus() else A.Toggle() end
end
