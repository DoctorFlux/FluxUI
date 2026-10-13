-- AceGUI: drag-and-drop reorder for stance bar slots (stances + extra spells).
-- Always character-specific (db.char.actionbars.stanceBarSlotOrder / stanceBarHiddenSlots).
-- Left-drag reorder. Right-click hide/show for built-in slots, remove for added slots.
-- The last cell accepts a dragged spell, item, macro, mount, toy, or pet.

local addonName, ns = ...

local Type, Version = "FluxStanceBarOrderPanel", 17
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local ICON_SZ = 44
local ICON_PAD = 2
local SLOT_GAP = 6
local BIND_H = 14
local SLOT_W = ICON_SZ + ICON_PAD * 2
local SLOT_H = ICON_SZ + ICON_PAD * 2 + BIND_H + 2
local SLOTS_PER_ROW = 10
local ROW_GAP = 6
local BORDER_PAD = 6
local Timer = C_Timer
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
local KeyBound = LibStub and LibStub("LibKeyBound-1.0", true)

local function GetFluxStance()
    if ns and ns.Flux and ns.Flux.Bars then
        return ns.Flux.Bars.Stance
    end
    return nil
end

--- Last embedded AceGUI widget instance (options panel open); used to refresh after reset.
local lastActiveWidget = nil

--- Forward declaration: FinishManualDrag calls this; must not be `local function` before assignment.
local RefreshPanel

local function GetStanceBar()
    return _G.FluxStanceBar
end

local function GetCharDB()
    if FluxOptions and FluxOptions.db and FluxOptions.db.char then
        if not FluxOptions.db.char.actionbars then
            FluxOptions.db.char.actionbars = {}
        end
        return FluxOptions.db.char.actionbars
    end
    return nil
end

local function GetBindingTextForSlot(visibleIndex)
    local bindName = "SHAPESHIFTBUTTON" .. visibleIndex
    local key = GetBindingKey(bindName)
    if key and key ~= "" then
        return key
    end
    return ""
end

-- ── Ghost (follows cursor in UIParent space; no BackdropTemplate — avoids load issues) ──

local GHOST_ICON_SZ = math.floor(ICON_SZ * 1.12 + 0.5)

local ghostFrame, ghostIcon

local function PlaceGhostAtCursor(self)
    if not self then return end
    local x, y
    if GetScaledCursorPosition then
        x, y = GetScaledCursorPosition()
    else
        local s = UIParent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        x, y = cx / s, cy / s
    end
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    if self.Raise then
        self:Raise()
    end
end

local function HideGhost()
    if ghostFrame then
        ghostFrame:Hide()
    end
end

local function ShowGhost(texture)
    HideGhost()
    if not ghostFrame then
        ghostFrame = CreateFrame("Frame", "FluxStanceBarOrderDragGhost", UIParent)
        -- Avoid TOOLTIP strata: same layer as GameTooltip can confuse the client after KeyBound / tooltip cycles.
        ghostFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        ghostFrame:SetFrameLevel(50000)
        ghostFrame:EnableMouse(false)
        ghostFrame:SetSize(GHOST_ICON_SZ, GHOST_ICON_SZ)
        if ghostFrame.SetToplevel then
            ghostFrame:SetToplevel(true)
        end

        ghostIcon = ghostFrame:CreateTexture(nil, "ARTWORK")
        ghostIcon:SetAllPoints()
        ghostIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    ghostIcon:SetTexture(texture or "Interface/Icons/INV_Misc_QuestionMark")
    ghostFrame:SetAlpha(1)
    PlaceGhostAtCursor(ghostFrame)
    ghostFrame:Show()
end

-- ── Drop index: cursor + slot rects in the same space (screen pixels) ───────

local function ComputeDropIndex(slots, cx, cy)
    local n = #slots
    if n == 0 then return nil end
    cx = cx or select(1, GetCursorPosition())
    cy = cy or select(2, GetCursorPosition())

    local function hitTest(i, s)
        if not s or not s:IsShown() then return nil end
        if s.GetScaledRect then
            local l, b, w, h = s:GetScaledRect()
            if l and b and w and h and w > 0 and h > 0 then
                local r = l + w
                local t = b + h
                if cx >= l and cx <= r and cy >= b and cy <= t then
                    local mid = l + w * 0.5
                    return (cx < mid) and i or math.min(i + 1, n + 1)
                end
            end
        end
        local l, r, top, bot = s:GetLeft(), s:GetRight(), s:GetTop(), s:GetBottom()
        if l and r and top and bot and cx >= l and cx <= r and cy >= bot and cy <= top then
            local mid = (l + r) * 0.5
            return (cx < mid) and i or math.min(i + 1, n + 1)
        end
        return nil
    end

    for i = 1, n do
        local ins = hitTest(i, slots[i])
        if ins then return ins end
    end

    local best, bestD = 1, math.huge
    for i = 1, n do
        local s = slots[i]
        if s and s.GetScaledRect then
            local l, b, w, h = s:GetScaledRect()
            if l and w and h then
                local mx, my = l + w * 0.5, b + h * 0.5
                local d = (cx - mx) ^ 2 + (cy - my) ^ 2
                if d < bestD then bestD, best = d, i end
            end
        elseif s then
            local mx, my = s:GetCenter()
            if mx and my then
                local d = (cx - mx) ^ 2 + (cy - my) ^ 2
                if d < bestD then bestD, best = d, i end
            end
        end
    end
    local s = slots[best]
    if s and s.GetScaledRect then
        local l, b, w, h = s:GetScaledRect()
        if l and w then
            local mid = l + w * 0.5
            return (cx < mid) and best or math.min(best + 1, n + 1)
        end
    end
    return best
end

-- ── Reorder + persist ───────────────────────────────────────────────────────

local function ReorderAndSave(widget, fromIndex, toIndex)
    local stanceBar = GetStanceBar()
    if not stanceBar or not stanceBar.GetSlotOrderEditorRows then return end

    local rows = stanceBar:GetSlotOrderEditorRows()
    local n = #rows
    if fromIndex < 1 or fromIndex > n then return end
    if toIndex < 1 or toIndex > n + 1 then return end
    if toIndex == fromIndex then return end

    local entry = table.remove(rows, fromIndex)
    local insertAt = toIndex
    if toIndex > fromIndex then insertAt = toIndex - 1 end
    if insertAt < 1 then insertAt = 1 end
    if insertAt > #rows + 1 then insertAt = #rows + 1 end
    table.insert(rows, insertAt, entry)

    local db = GetCharDB()
    if not db then return end
    if not db.stanceBarSlotOrder then db.stanceBarSlotOrder = {} end
    table.wipe(db.stanceBarSlotOrder)
    for j = 1, #rows do
        db.stanceBarSlotOrder[j] = rows[j].key
    end
    stanceBar:ApplySavedSlotOrderAndRefresh()
end

-- ── Tooltip: same as live stance bar buttons (FluxStanceBar CreateStanceButton OnEnter) ──
-- GameTooltip is global; only hide/reset when we own it (RefreshPanel runs often — do not nuke other UI tooltips).

local function TooltipOwnerIsDescendantOfStanceWidget(owner, widget)
    if not owner or not widget or not widget.frame then
        return false
    end
    local f = owner
    local target = widget.frame
    for _ = 1, 32 do
        if not f then
            return false
        end
        if f == target then
            return true
        end
        f = f:GetParent()
    end
    return false
end

local function ShowSlotTooltip(owner, row)
    if not owner or not row then return end
    -- LibKeyBound owns GameTooltip while binding UI is shown; do not overlay spell tooltips.
    if KeyBound and KeyBound.IsShown and KeyBound:IsShown() then
        return
    end
    if FluxTooltipGuard and FluxTooltipGuard.Reset then
        FluxTooltipGuard.Reset(GameTooltip)
    elseif FluxTooltipGuard and FluxTooltipGuard.Unblock then
        FluxTooltipGuard.Unblock(GameTooltip)
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local sid = row.spellID
    local itemID = row.itemID
    local tipped = false
    if (row.actionType == "item" or row.actionType == "toy") and itemID and GameTooltip.SetItemByID then
        tipped = pcall(GameTooltip.SetItemByID, GameTooltip, itemID)
    end
    if not tipped and sid and GameTooltip.SetSpellByID then
        tipped = pcall(GameTooltip.SetSpellByID, GameTooltip, sid)
    end
    if not tipped then
        GameTooltip:SetText(row.label or row.key or "?", 1, 1, 1)
    end
    if row.hidden then
        GameTooltip:AddLine("Hidden from stance bar.", 1, 0.35, 0.35)
    end
    if row.suppressed then
        GameTooltip:AddLine("Already on the stance bar.", 1, 0.8, 0.2, true)
    end
    if row.removable then
        GameTooltip:AddLine("Drag to reorder. Right-click remove.", 0.55, 0.62, 0.7, true)
    else
        GameTooltip:AddLine("Drag to reorder. Right-click hide/show.", 0.55, 0.62, 0.7, true)
    end
    GameTooltip:Show()
end

local function HideSlotTooltip(widget)
    if not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        return
    end
    local owner = GameTooltip:GetOwner()
    if not owner or not widget or not TooltipOwnerIsDescendantOfStanceWidget(owner, widget) then
        return
    end
    if GameTooltip.Hide then
        pcall(function()
            GameTooltip:Hide()
        end)
    end
    if FluxTooltipGuard and FluxTooltipGuard.Reset then
        FluxTooltipGuard.Reset(GameTooltip)
    elseif FluxTooltipGuard and FluxTooltipGuard.Unblock then
        FluxTooltipGuard.Unblock(GameTooltip)
    end
end

--- Detach every direct child from the content frame (fixes duplicate icons when AceGUI releases
--- the widget but leaves frames parented, then RefreshPanel creates new slots on top).
local function DetachAllContentChildren(content)
    if not content or not content.GetNumChildren then
        return
    end
    local nc = content:GetNumChildren()
    if nc < 1 then
        return
    end
    for i = nc, 1, -1 do
        local ch = select(i, content:GetChildren())
        if ch then
            ch:Hide()
            ch:SetParent(nil)
        end
    end
end

local function SlotCacheIsOrphaned(widget, content)
    if not content then
        return true
    end
    local nc = content.GetNumChildren and content:GetNumChildren() or 0
    local s1 = widget._slotFrames and widget._slotFrames[1]
    if s1 and s1.GetParent and s1:GetParent() == content then
        return false
    end
    -- No valid ref to row 1, but content still has frames — stale children from a prior acquire.
    if not s1 and nc > 0 then
        return true
    end
    if s1 and s1.GetParent and s1:GetParent() ~= content then
        return true
    end
    return false
end

--- Hide slot frames with index > keepCount; keepCount 0 hides all. Resets alpha (stuck drag dim).
local function HideUnusedSlotFrames(widget, keepCount)
    if not widget or not widget._slotFrames then
        return
    end
    keepCount = tonumber(keepCount) or 0
    for idx, sf in pairs(widget._slotFrames) do
        if type(idx) == "number" and sf then
            if idx > keepCount then
                sf:SetAlpha(1)
                sf:Hide()
            end
        end
    end
end

-- ── Manual drag (RegisterForDrag is unreliable over Ace options content) ──

local function FinishManualDrag(widget)
    if not widget or not widget._fluxDragging then
        return
    end
    widget._fluxDragging = false
    local fromIdx = widget._fluxDragFromIndex
    widget._fluxDragFromIndex = nil
    if widget.frame then
        widget.frame:SetScript("OnUpdate", widget._fluxPrevOnUpdate)
    end
    widget._fluxPrevOnUpdate = nil

    HideGhost()
    HideSlotTooltip(widget)

    local stanceBar = GetStanceBar()
    local n = 0
    if stanceBar and stanceBar.GetSlotOrderEditorRows then
        n = #(stanceBar:GetSlotOrderEditorRows())
    end
    local visibleSlots = {}
    for vi = 1, n do
        visibleSlots[vi] = widget._slotFrames and widget._slotFrames[vi]
    end
    local cx, cy = GetCursorPosition()
    local dropIdx = ComputeDropIndex(visibleSlots, cx, cy)
    if dropIdx and fromIdx and dropIdx ~= fromIdx then
        ReorderAndSave(widget, fromIdx, dropIdx)
    end
    RefreshPanel(widget)
end

local function DragFrameOnUpdate(widget, elapsed)
    if not widget._fluxDragging then
        return
    end
    if ghostFrame and ghostFrame:IsShown() then
        PlaceGhostAtCursor(ghostFrame)
    end
    if not IsMouseButtonDown("LeftButton") then
        FinishManualDrag(widget)
    end
end

local function RequestParentLayout(widget)
    if not widget or not Timer or not Timer.After then return end
    if widget._fluxReleased then return end
    if widget._fluxParentLayoutPending then return end
    local prev = widget._fluxLastLayoutHeight
    local h = widget.frame and widget.frame:GetHeight()
    if prev and h and math.abs(h - prev) < 0.5 then
        return
    end
    if h then
        widget._fluxLastLayoutHeight = h
    end
    widget._fluxParentLayoutPending = true
    widget._fluxLayoutGen = (widget._fluxLayoutGen or 0) + 1
    local gen = widget._fluxLayoutGen
    Timer.After(0, function()
        if widget._fluxLayoutGen ~= gen or widget._fluxReleased then
            return
        end
        widget._fluxParentLayoutPending = nil
        local p = widget and widget.parent
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

local function ShowAddTooltip(owner)
    if not owner then return end
    if KeyBound and KeyBound.IsShown and KeyBound:IsShown() then
        return
    end
    if FluxTooltipGuard and FluxTooltipGuard.Reset then
        FluxTooltipGuard.Reset(GameTooltip)
    elseif FluxTooltipGuard and FluxTooltipGuard.Unblock then
        FluxTooltipGuard.Unblock(GameTooltip)
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText("Add to stance bar", 1, 1, 1)
    GameTooltip:AddLine("Drag a spell, item, macro, mount, toy, or pet here.", 0.55, 0.62, 0.7, true)
    GameTooltip:Show()
end

local function TryAddFromCursor()
    local FS = GetFluxStance()
    if FS and FS.AddCustomFromCursor then
        return FS.AddCustomFromCursor() and true or false
    end
    return false
end

local function EnsureAddSlot(widget, content)
    local slot = widget._addSlot
    if not slot then
        slot = CreateFrame("Frame", nil, content, backdropTemplate)
        slot:SetSize(SLOT_W, SLOT_H)
        widget._addSlot = slot

        if slot.SetBackdrop then
            slot:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false, edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 },
            })
            slot:SetBackdropColor(0, 0, 0, 0.08)
            slot:SetBackdropBorderColor(0.45, 0.4, 0.2, 0.7)
        end

        local iconBtn = CreateFrame("Button", nil, slot)
        iconBtn:SetSize(ICON_SZ, ICON_SZ)
        iconBtn:SetPoint("TOP", slot, "TOP", 0, -ICON_PAD)
        iconBtn:RegisterForDrag("LeftButton")
        if iconBtn.RegisterForClicks then
            iconBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        end
        slot._iconBtn = iconBtn

        local plus = iconBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        plus:SetPoint("CENTER", iconBtn, "CENTER", 0, 0)
        plus:SetText("+")
        plus:SetTextColor(0.95, 0.86, 0.45)
        slot._plus = plus

        local bindLabel = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        bindLabel:SetPoint("TOP", iconBtn, "BOTTOM", 0, -2)
        bindLabel:SetWidth(SLOT_W)
        bindLabel:SetJustifyH("CENTER")
        bindLabel:SetTextColor(0.9, 0.82, 0.55)
        bindLabel:SetText("Add")
        slot._bindLabel = bindLabel

        iconBtn:SetScript("OnReceiveDrag", function()
            TryAddFromCursor()
        end)
        iconBtn:SetScript("OnMouseUp", function(_, btn)
            if btn ~= "LeftButton" then
                return
            end
            if not GetCursorInfo or not GetCursorInfo() then
                return
            end
            TryAddFromCursor()
        end)
        iconBtn:SetScript("OnEnter", function()
            if widget._fluxDragging then
                return
            end
            ShowAddTooltip(iconBtn)
        end)
        iconBtn:SetScript("OnLeave", function()
            HideSlotTooltip(widget)
        end)
    end
    if slot.GetParent and slot:GetParent() ~= content then
        slot:SetParent(content)
    end
    return slot
end

RefreshPanel = function(widget)
    if not widget or not widget._scrollChild then return end
    if widget._fluxReleased then return end
    if widget.frame and widget.frame.IsShown and not widget.frame:IsShown() then return end
    if not widget._fluxDragging then
        HideGhost()
        HideSlotTooltip(widget)
    end

    local stanceBar = GetStanceBar()
    local content = widget._scrollChild
    local empty = widget._fluxEmptyText

    if not widget._slotFrames then
        widget._slotFrames = {}
    end
    -- AceGUI OnRelease nils _slotFrames while content still holds old slot frames; next pass
    -- would CreateFrame again and stack duplicates. Drop strays and reset the cache when needed.
    if SlotCacheIsOrphaned(widget, content) then
        DetachAllContentChildren(content)
        widget._slotFrames = {}
    end

    if not stanceBar or not stanceBar.GetSlotOrderEditorRows then
        HideUnusedSlotFrames(widget, 0)
        if widget._addSlot then
            widget._addSlot:Hide()
        end
        if empty then empty:SetText("Stance bar not loaded."); empty:Show() end
        content:SetHeight(1)
        widget.frame:SetHeight(48)
        return
    end

    local rows = stanceBar:GetSlotOrderEditorRows()
    local n = #rows
    local bindMap
    if stanceBar.GetCanonicalToShapeshiftButtonBindingIndexMap then
        bindMap = stanceBar:GetCanonicalToShapeshiftButtonBindingIndexMap()
    end

    if empty then empty:Hide() end

    -- Drop reused count: hide everything above n first (reset clears stale backdrops/icons).
    HideUnusedSlotFrames(widget, n)

    local x = BORDER_PAD
    local y = -BORDER_PAD
    local col = 0

    for i = 1, n do
        local r = rows[i]
        local slot = widget._slotFrames[i]

        if not slot then
            slot = CreateFrame("Frame", nil, content, backdropTemplate)
            slot:SetSize(SLOT_W, SLOT_H)
            widget._slotFrames[i] = slot

            if slot.SetBackdrop then
                slot:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = false, edgeSize = 1,
                    insets = { left = 0, right = 0, top = 0, bottom = 0 },
                })
                slot:SetBackdropColor(0, 0, 0, 0.08)
                slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.4)
            end

            local iconBtn = CreateFrame("Button", nil, slot)
            iconBtn:SetSize(ICON_SZ, ICON_SZ)
            iconBtn:SetPoint("TOP", slot, "TOP", 0, -ICON_PAD)
            slot._iconBtn = iconBtn

            local tex = iconBtn:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            slot._iconTex = tex

            local hl = iconBtn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.15)
            slot._iconHL = hl

            local bindLabel = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            bindLabel:SetPoint("TOP", iconBtn, "BOTTOM", 0, -2)
            bindLabel:SetWidth(SLOT_W)
            bindLabel:SetJustifyH("CENTER")
            bindLabel:SetTextColor(0.9, 0.82, 0.55)
            slot._bindLabel = bindLabel
        end

        -- Wrap to next row
        if col >= SLOTS_PER_ROW then
            x = BORDER_PAD
            y = y - (SLOT_H + ROW_GAP)
            col = 0
        end

        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
        local isHidden = r.hidden and true or false
        local dimmed = isHidden or r.suppressed
        slot:SetAlpha(dimmed and 0.42 or 1)
        slot:Show()

        local texture = r.texture
        if texture and texture ~= "" then
            slot._iconTex:SetTexture(texture)
        else
            slot._iconTex:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
        end
        if slot._iconTex.SetDesaturated then
            slot._iconTex:SetDesaturated(dimmed)
        end

        local canon = r.slotIndex
        local bindN = bindMap and canon and bindMap[canon]
        local bindText = (bindN and GetBindingTextForSlot(bindN)) or ""
        slot._bindLabel:SetText(bindText)
        slot._rowLabel = r.label or r.key or "?"
        slot._rowIndex = i

        local idx = i
        local rowKey = r.key
        local removable = r.removable and true or false
        local iconBtn = slot._iconBtn
        if iconBtn.RegisterForClicks then
            iconBtn:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "RightButtonUp")
        end
        iconBtn:SetScript("OnDragStart", nil)
        iconBtn:SetScript("OnDragStop", nil)
        iconBtn:SetScript("OnClick", function(_, btn)
            if btn ~= "RightButton" then
                return
            end
            if widget._fluxDragging then
                return
            end
            local FS = GetFluxStance()
            if removable then
                if FS and FS.RemoveCustomSlot and rowKey then
                    FS.RemoveCustomSlot(rowKey)
                end
            elseif FS and FS.ToggleStanceSlotHidden and rowKey then
                FS.ToggleStanceSlotHidden(rowKey)
            end
        end)
        iconBtn:SetScript("OnMouseDown", function(_, btn)
            if btn ~= "LeftButton" then return end
            widget._fluxDragging = true
            widget._fluxDragFromIndex = idx
            slot:SetAlpha(0.42)
            ShowGhost(r.texture)
            HideSlotTooltip(widget)
            if widget.frame then
                widget._fluxPrevOnUpdate = widget.frame:GetScript("OnUpdate")
                widget.frame:SetScript("OnUpdate", function(self, elap)
                    DragFrameOnUpdate(widget, elap)
                end)
            end
        end)
        iconBtn:SetScript("OnEnter", function()
            if widget._fluxDragging then return end
            ShowSlotTooltip(iconBtn, r)
        end)
        iconBtn:SetScript("OnLeave", function()
            HideSlotTooltip(widget)
        end)

        x = x + SLOT_W + SLOT_GAP
        col = col + 1
    end

    if col >= SLOTS_PER_ROW then
        x = BORDER_PAD
        y = y - (SLOT_H + ROW_GAP)
        col = 0
    end
    local addSlot = EnsureAddSlot(widget, content)
    addSlot:ClearAllPoints()
    addSlot:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    addSlot:SetAlpha(1)
    addSlot:Show()

    local numRows = math.ceil((n + 1) / SLOTS_PER_ROW)
    local totalH = numRows * SLOT_H + math.max(0, numRows - 1) * ROW_GAP + BORDER_PAD * 2
    content:SetHeight(totalH)
    local showH = math.max(SLOT_H + BORDER_PAD * 2, totalH + 8)
    widget.frame:SetHeight(showH)
    RequestParentLayout(widget)
end

-- LibKeyBound toggles: cancel in-progress drags and restore GameTooltip / FluxTooltipGuard (binding mode exit).
local function CancelManualDragWithoutReorder(widget)
    if not widget or not widget._fluxDragging then
        return
    end
    widget._fluxDragging = false
    local fromIdx = widget._fluxDragFromIndex
    widget._fluxDragFromIndex = nil
    if widget.frame then
        widget.frame:SetScript("OnUpdate", widget._fluxPrevOnUpdate)
    end
    widget._fluxPrevOnUpdate = nil
    HideGhost()
    HideSlotTooltip(widget)
    if fromIdx and widget._slotFrames and widget._slotFrames[fromIdx] then
        widget._slotFrames[fromIdx]:SetAlpha(1)
    end
    RefreshPanel(widget)
end

local function OnBindingModeChanged()
    local w = lastActiveWidget
    if w and w._fluxDragging then
        CancelManualDragWithoutReorder(w)
        return
    end
    HideGhost()
    HideSlotTooltip(w)
end

-- ── AceGUI widget methods ───────────────────────────────────────────────────

local methods = {
    OnAcquire = function(self)
        self._fluxReleased = false
        self:SetFullWidth(true)
        self._fluxDragging = false
        self._fluxDragFromIndex = nil
        self._fluxPrevOnUpdate = nil
        self._fluxLastLayoutHeight = nil
        lastActiveWidget = self
        local frame = self.frame
        frame:EnableMouse(true)

        -- Plain content frame (no nested ScrollFrame) so mouse wheel reaches the FluxUI/AceConfig scroll.
        if not self._scrollChild then
            local child = CreateFrame("Frame", nil, frame)
            child:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            child:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            child:SetWidth(400)
            self._scrollChild = child

            local emptyFS = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            emptyFS:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -4)
            emptyFS:SetWidth(360)
            emptyFS:SetJustifyH("LEFT")
            emptyFS:SetTextColor(0.75, 0.75, 0.75)
            emptyFS:Hide()
            self._fluxEmptyText = emptyFS
        end

        self._fluxAcquireGen = (self._fluxAcquireGen or 0) + 1
        local gen = self._fluxAcquireGen
        Timer.After(0, function()
            if self._fluxReleased or self._fluxAcquireGen ~= gen then
                return
            end
            RefreshPanel(self)
        end)
    end,

    OnRelease = function(self)
        self._fluxReleased = true
        self._fluxAcquireGen = (self._fluxAcquireGen or 0) + 1
        self._fluxLayoutGen = (self._fluxLayoutGen or 0) + 1
        self._fluxParentLayoutPending = nil
        if lastActiveWidget == self then
            lastActiveWidget = nil
        end
        self._fluxDragging = false
        self._fluxDragFromIndex = nil
        if self.frame then
            self.frame:SetScript("OnUpdate", self._fluxPrevOnUpdate)
        end
        self._fluxPrevOnUpdate = nil
        HideGhost()
        HideSlotTooltip(self)
        if self._scrollChild then
            DetachAllContentChildren(self._scrollChild)
        end
        self._slotFrames = nil
    end,

    SetText = function() end,
    SetFontObject = function() end,
    SetImage = function() end,
    SetImageSize = function() end,

    OnWidthSet = function(self, width)
        if self._fluxReleased then return end
        if type(width) ~= "number" or width <= 0 or not self._scrollChild then return end
        local last = self._fluxLastPanelWidth
        if last and math.abs(width - last) < 2 then
            return
        end
        self._fluxLastPanelWidth = width
        self._scrollChild:SetWidth(width - 24)
        self._fluxWidthRefreshGen = (self._fluxWidthRefreshGen or 0) + 1
        local gen = self._fluxWidthRefreshGen
        Timer.After(0.05, function()
            if self._fluxReleased or self._fluxWidthRefreshGen ~= gen then
                return
            end
            RefreshPanel(self)
        end)
    end,
}

local function Constructor()
    local name = "AceGUI30FluxStanceBarOrder" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:Hide()

    local widget = {
        frame = frame,
        type = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

if KeyBound and KeyBound.RegisterCallback then
    KeyBound:RegisterCallback("LIBKEYBOUND_ENABLED", OnBindingModeChanged)
    KeyBound:RegisterCallback("LIBKEYBOUND_DISABLED", OnBindingModeChanged)
end

function _G.FluxStanceBarOrderPanel_RequestRefresh()
    local w = lastActiveWidget
    if not w or w._fluxReleased then
        return
    end
    if w.frame and w.frame.IsShown and not w.frame:IsShown() then
        return
    end
    RefreshPanel(w)
end

function _G.FluxStanceBarOrderPanel_OnOptionsClosed()
    lastActiveWidget = nil
end
