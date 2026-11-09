-- AceGUI: item currency - icon grid (drag to reorder, ghost, drop).
-- char.itemCurrency.slots via FluxItemCurrencyTracking / GetItemCurrencyDB.

local Type, Version = "FluxItemCurrencySlots", 8
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
    return
end

-- Match FluxNCFlyoutPanel drag/slot patterns.
local CELL = 44
local TEX = 36
local GAP = 4
local DRAG_THRESHOLD_SQ = 64
local MAX_UI_SLOT_ROWS = 40
local Timer = C_Timer
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

-- Forward
local ApplyItemToSlot, ClearSlot, MoveItemCurrencySlots, RefreshPanel

local function GetItemIdFromCursor()
    if _G.FluxItemCurrencyTracking and _G.FluxItemCurrencyTracking.GetItemIdFromCursor then
        return _G.FluxItemCurrencyTracking.GetItemIdFromCursor()
    end
    return nil
end

local function GetItemIconForSlot(itemId)
    local F = _G.FluxItemCurrencyTracking
    if F and F.GetItemIcon then
        return F.GetItemIcon(itemId)
    end
    if not itemId or itemId < 1 then
        return "Interface/Icons/INV_Misc_QuestionMark"
    end
    if C_Item and C_Item.GetItemIconByID then
        local ok, ic = pcall(C_Item.GetItemIconByID, itemId)
        if ok and ic and ic ~= 0 and ic ~= "" then
            return ic
        end
    end
    if GetItemInfo then
        local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemId)
        if (type(tex) == "number" and tex > 0) or (type(tex) == "string" and tex ~= "") then
            return tex
        end
    end
    return "Interface/Icons/INV_Misc_QuestionMark"
end

-- ── Ghost (separate from profession panel) ─────────────────────────────────
local icGhost
local function EnsureICGhost()
    if icGhost then
        return
    end
    icGhost = CreateFrame("Frame", "FluxItemCurrencyPanelGhost", UIParent)
    icGhost:SetSize(CELL, CELL)
    if icGhost.SetFrameStrata then
        icGhost:SetFrameStrata("TOOLTIP")
    end
    icGhost.icon = icGhost:CreateTexture(nil, "ARTWORK")
    icGhost.icon:SetAllPoints(icGhost)
    icGhost.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icGhost:Hide()
end

local function HideICGhost()
    if icGhost then
        icGhost:Hide()
    end
end

local function PlaceGhostAtCursor(frame)
    if not frame then
        return
    end
    local scale = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
end

local function ShowICGhost(iconPath)
    EnsureICGhost()
    icGhost.icon:SetTexture(iconPath or "Interface/Icons/INV_Misc_QuestionMark")
    PlaceGhostAtCursor(icGhost)
    icGhost:Show()
    if icGhost.Raise then
        icGhost:Raise()
    end
end

local function ComputeDropIndexUniform(slots, cx, cy)
    local n = #slots
    if n == 0 then
        return nil
    end
    for i = 1, n do
        local s = slots[i]
        if s and s.IsShown and s:IsShown() and s.GetScaledRect then
            local l, b, w, h = s:GetScaledRect()
            if l and b and w and h and w > 0 and h > 0 then
                local r, t = l + w, b + h
                if cx >= l and cx <= r and cy >= b and cy <= t then
                    local mid = l + w * 0.5
                    return (cx < mid) and i or math.min(i + 1, n + 1)
                end
            end
        end
    end
    local best, bestD = 1, math.huge
    for i = 1, n do
        local s = slots[i]
        if s and s.GetScaledRect then
            local l, b, w, h = s:GetScaledRect()
            if l and w and h then
                local mx, my = l + w * 0.5, b + h * 0.5
                local d = (cx - mx) ^ 2 + (cy - my) ^ 2
                if d < bestD then
                    bestD, best = d, i
                end
            end
        end
    end
    local s = slots[best]
    if s and s.GetScaledRect then
        local l, _, w = s:GetScaledRect()
        if l and w then
            local mid = l + w * 0.5
            return (cx < mid) and best or math.min(best + 1, n + 1)
        end
    end
    return best
end

local function LayoutICRow(parent, slots, cols)
    cols = math.max(1, cols or 6)
    local n = #slots
    for i, slot in ipairs(slots) do
        local idx = i - 1
        local row = math.floor(idx / cols)
        local col = idx % cols
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", parent, "TOPLEFT", col * (CELL + GAP), -row * (CELL + GAP))
    end
    local rows = math.max(1, math.ceil(n / cols))
    local pw = cols * CELL + (cols - 1) * GAP
    local ph = rows * CELL + (rows - 1) * GAP
    parent:SetSize(pw, ph)
    return ph
end

local function clearContentAll(content)
    if not content then
        return
    end
    if content.GetRegions then
        for r = select("#", content:GetRegions()), 1, -1 do
            local reg = select(r, content:GetRegions())
            if reg then
                reg:Hide()
                reg:SetParent(nil)
            end
        end
    end
    if content.GetChildren then
        for c = select("#", content:GetChildren()), 1, -1 do
            local ch = select(c, content:GetChildren())
            if ch then
                ch:Hide()
                ch:SetParent(nil)
            end
        end
    end
end

MoveItemCurrencySlots = function(widget, fromIdx, toIdx)
    local FIC = _G.FluxItemCurrencyTracking
    if not FIC or not FIC.EnsureItemCurrencyData or not FIC.NotifyItemCurrencyChanged or fromIdx == toIdx or fromIdx < 1 or toIdx < 1 then
        return
    end
    local ic = FIC.EnsureItemCurrencyData()
    if not ic or not ic.slots or fromIdx > #ic.slots or toIdx > #ic.slots then
        return
    end
    local t = table.remove(ic.slots, fromIdx)
    if not t then
        return
    end
    table.insert(ic.slots, toIdx, t)
    if FIC.MaintainItemCurrencySlotList then
        pcall(FIC.MaintainItemCurrencySlotList, ic)
    end
    FIC.NotifyItemCurrencyChanged()
    if widget and RefreshPanel then
        RefreshPanel(widget)
    end
end

-- Pending-drag OnUpdate (pattern from FluxNCFlyoutPanel)
local function FluxICStripPendingDragOnUpdate(f)
    local w = f._fluxICStripOwner
    if not w or not w._fluxICPendingDrag then
        return
    end
    local p = w._fluxICPendingDrag
    if IsMouseButtonDown("LeftButton") then
        local cx, cy = GetCursorPosition()
        local dx, dy = cx - p.startCX, cy - p.startCY
        if not p.dragActive and (dx * dx + dy * dy) >= DRAG_THRESHOLD_SQ then
            p.dragActive = true
            w._fluxICDragging = true
            ShowICGhost(p.iconPath)
        end
        if p.dragActive and icGhost then
            PlaceGhostAtCursor(icGhost)
            if icGhost.Raise then
                icGhost:Raise()
            end
        end
        return
    end

    f:SetScript("OnUpdate", w._fluxICPrevOnUpdate)
    w._fluxICPrevOnUpdate = nil
    w._fluxICPendingDrag = nil
    if GameTooltip and GameTooltip.Hide then
        GameTooltip:Hide()
    end

    if p.dragActive then
        HideICGhost()
        local cx, cy = GetCursorPosition()
        local fromIdx, slots, n = p.fromIdx, p.slots, p.nSlots
        w._fluxICDragging = false
        if fromIdx and slots and n and n > 0 then
            local dropIdx = ComputeDropIndexUniform(slots, cx, cy)
            if dropIdx and dropIdx ~= fromIdx then
                local toIdx = dropIdx
                if fromIdx < toIdx then
                    toIdx = toIdx - 1
                end
                if toIdx < 1 then
                    toIdx = 1
                end
                if toIdx > n then
                    toIdx = n
                end
                if toIdx ~= fromIdx then
                    MoveItemCurrencySlots(w, fromIdx, toIdx)
                else
                    if RefreshPanel then
                        RefreshPanel(w)
                    end
                end
            else
                if RefreshPanel then
                    RefreshPanel(w)
                end
            end
        else
            if RefreshPanel then
                RefreshPanel(w)
            end
        end
    else
        w._fluxICDragging = false
        -- Click (no drag): place item if cursor has one
        if p.fromIdx and GetItemIdFromCursor then
            local id = GetItemIdFromCursor()
            if type(id) == "number" and id > 0 and ApplyItemToSlot then
                ApplyItemToSlot(w, p.fromIdx, id)
            elseif RefreshPanel then
                RefreshPanel(w)
            end
        else
            if RefreshPanel then
                RefreshPanel(w)
            end
        end
    end
end

ApplyItemToSlot = function(self, slotIdx, itemId)
    local FIC = _G.FluxItemCurrencyTracking
    if not FIC or not FIC.EnsureItemCurrencyData or not FIC.NotifyItemCurrencyChanged or not itemId or itemId < 1 then
        return
    end
    local ic = FIC.EnsureItemCurrencyData()
    if not ic or not ic.slots or not ic.slots[slotIdx] then
        return
    end
    ic.slots[slotIdx].itemId = itemId
    ic.slots[slotIdx].show = true
    if FIC.MaintainItemCurrencySlotList then
        pcall(FIC.MaintainItemCurrencySlotList, ic)
    end
    if ClearCursor then
        ClearCursor()
    end
    FIC.NotifyItemCurrencyChanged()
    if self and RefreshPanel then
        RefreshPanel(self)
    end
end

ClearSlot = function(self, slotIdx)
    local FIC = _G.FluxItemCurrencyTracking
    if not FIC or not FIC.EnsureItemCurrencyData or not FIC.NotifyItemCurrencyChanged then
        return
    end
    local ic = FIC.EnsureItemCurrencyData()
    if not ic or not ic.slots or not ic.slots[slotIdx] then
        return
    end
    ic.slots[slotIdx].itemId = 0
    ic.slots[slotIdx].show = false
    if FIC.MaintainItemCurrencySlotList then
        pcall(FIC.MaintainItemCurrencySlotList, ic)
    end
    FIC.NotifyItemCurrencyChanged()
    if self and RefreshPanel then
        RefreshPanel(self)
    end
end

local function BuildIconStrip(widget, parent, nSlots, ic)
    local slots = {}
    local n = nSlots
    n = math.min(n, MAX_UI_SLOT_ROWS)
    for i = 1, n do
        local slot = ic.slots[i]
        local itemId = (slot and type(slot.itemId) == "number") and slot.itemId or 0
        local btn = CreateFrame("Button", nil, parent, backdropTemplate)
        btn:SetSize(CELL, CELL)
        if btn.SetBackdrop then
            pcall(function()
                btn:SetBackdrop({
                    bgFile = "Interface/Buttons/WHITE8X8",
                    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                    tile = false,
                    edgeSize = 8,
                    insets = { left = 1, right = 1, top = 1, bottom = 1 },
                })
            end)
            pcall(function()
                btn:SetBackdropColor(0.06, 0.06, 0.08, 0.9)
                btn:SetBackdropBorderColor(0.35, 0.45, 0.55, 1)
            end)
        end
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(TEX, TEX)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        local path = (itemId > 0) and GetItemIconForSlot(itemId) or "Interface/Icons/INV_Misc_QuestionMark"
        icon:SetTexture(path)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if itemId < 1 then
            icon:SetDesaturated(true)
            icon:SetVertexColor(0.5, 0.5, 0.5, 0.85)
        else
            icon:SetDesaturated(false)
            icon:SetVertexColor(1, 1, 1, 1)
        end
        local slotIndex = i
        btn:SetScript("OnEnter", function(selfBtn)
            if not GameTooltip then
                return
            end
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            if itemId and itemId > 0 and GameTooltip.SetItemByID then
                pcall(function()
                    GameTooltip:SetItemByID(itemId)
                end)
            else
                GameTooltip:SetText("Item slot " .. tostring(i), 1, 1, 1)
                if GameTooltip.AddLine then
                    GameTooltip:AddLine("Drag to reorder, or put an item on the cursor and click. Drag from bags works too. Right-click to clear.", 0.55, 0.6, 0.68, true)
                end
            end
            if GameTooltip.AddLine and itemId and itemId > 0 then
                GameTooltip:AddLine("Drag: reorder. Cursor + click: replace. Right-click: remove.", 0.5, 0.55, 0.62, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
        btn:RegisterForClicks("RightButtonUp")
        btn:SetScript("OnClick", function(_, button)
            if button == "RightButton" and ClearSlot then
                ClearSlot(widget, slotIndex)
            end
        end)
        pcall(function()
            btn:RegisterForDrag("LeftButton")
        end)
        btn:SetScript("OnReceiveDrag", function()
            if widget._fluxICPendingDrag or widget._fluxICDragging then
                return
            end
            local id = GetItemIdFromCursor()
            if type(id) == "number" and id > 0 and ApplyItemToSlot then
                ApplyItemToSlot(widget, slotIndex, id)
            end
        end)
        btn:SetScript("OnMouseDown", function(_, mbutton)
            if mbutton ~= "LeftButton" or widget._fluxICPendingDrag then
                return
            end
            if widget._fluxICDragging then
                return
            end
            local cx, cy = GetCursorPosition()
            local iconPath = (itemId > 0) and GetItemIconForSlot(itemId) or "Interface/Icons/INV_Misc_QuestionMark"
            widget._fluxICPendingDrag = {
                startCX = cx,
                startCY = cy,
                fromIdx = i,
                slots = slots,
                nSlots = n,
                iconPath = iconPath,
                dragActive = false,
            }
            if widget.frame then
                widget.frame._fluxICStripOwner = widget
                widget._fluxICPrevOnUpdate = widget.frame:GetScript("OnUpdate")
                widget.frame:SetScript("OnUpdate", FluxICStripPendingDragOnUpdate)
            end
        end)
        slots[i] = btn
    end
    local fw = 400
    if widget.frame and widget.frame.GetWidth then
        fw = (widget.frame:GetWidth() or fw)
    end
    local inner = math.max(120, fw - 8)
    local cols = math.max(1, math.floor((inner + GAP) / (CELL + GAP)))
    return LayoutICRow(parent, slots, cols)
end

RefreshPanel = function(widget)
    if not widget or not widget._content then
        return
    end
    if widget._fluxICDragging then
        return
    end
    local FIC = _G.FluxItemCurrencyTracking
    if not FIC or not FIC.EnsureItemCurrencyData then
        return
    end
    local content = widget._content
    clearContentAll(content)
    local ic = FIC.EnsureItemCurrencyData()
    if not ic or not ic.slots then
        return
    end
    if FIC.MaintainItemCurrencySlotList then
        pcall(FIC.MaintainItemCurrencySlotList, ic)
    end
    local n = math.min(#ic.slots, MAX_UI_SLOT_ROWS)
    if n < 1 then
        n = 1
    end
    local grid = CreateFrame("Frame", nil, content)
    grid:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    local h = BuildIconStrip(widget, grid, n, ic)
    content:SetWidth(grid:GetWidth() or 200)
    content:SetHeight(h + 8)
    if widget.frame and widget.frame.SetHeight then
        local fh = h + 16
        widget.frame:SetHeight(math.max(fh, 100))
    end
    if widget.SetHeight then
        widget:SetHeight((widget.frame and widget.frame.GetHeight) and (widget.frame:GetHeight() or 120) or 120)
    end
end

local methods = {
    OnAcquire = function(self)
        self:SetFullWidth(true)
        self:SetLabel("")
        local F = _G.FluxItemCurrencyTracking
        if F then
            F._configSlotsWidget = self
        end
        if not self._content then
            self._content = CreateFrame("Frame", nil, self.frame)
            self._content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
            self._content:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
        end
        if self.frame then
            self.frame:EnableMouse(true)
            self.frame._fluxICStripOwner = self
        end
        if Timer and Timer.After then
            Timer.After(0, function()
                if RefreshPanel then
                    RefreshPanel(self)
                end
            end)
        elseif RefreshPanel then
            RefreshPanel(self)
        end
        if self.frame and self.frame.Show then
            self.frame:Show()
        end
    end,
    OnRelease = function(self)
        self._fluxICPendingDrag = nil
        self._fluxICDragging = false
        if self.frame then
            self.frame:SetScript("OnUpdate", self._fluxICPrevOnUpdate)
        end
        self._fluxICPrevOnUpdate = nil
        HideICGhost()
        if _G.FluxItemCurrencyTracking and _G.FluxItemCurrencyTracking._configSlotsWidget == self then
            _G.FluxItemCurrencyTracking._configSlotsWidget = nil
        end
    end,
    OnWidthSet = function(self, width)
        if type(width) == "number" and width > 40 and self._content then
            self._content:SetWidth(width - 8)
        end
        if not RefreshPanel then
            return
        end
        if Timer and Timer.After then
            Timer.After(0, function()
                RefreshPanel(self)
            end)
        else
            RefreshPanel(self)
        end
    end,
    SetLabel = function() end,
    SetText = function() end,
    SetFontObject = function() end,
}

local function Constructor()
    local n = "AceGUI30FluxItemCurrencySlots" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", n, UIParent)
    frame:EnableMouse(true)
    frame:Hide()
    local widget = {
        type = Type,
        frame = frame,
    }
    for k, v in pairs(methods) do
        widget[k] = v
    end
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

do
    local F = _G.FluxItemCurrencyTracking
    if F then
        F._RefreshSlotsUIFromAce = function()
            local w = F._configSlotsWidget
            if w and w._content and RefreshPanel then
                if not w._fluxICDragging and not w._fluxICPendingDrag then
                    RefreshPanel(w)
                end
            end
        end
    end
end
