-- AceGUI: multi-cast cast-order — stance-bar style icon grid.
-- Left-drag reorder (same manual-drag pattern as FluxStanceBarOrderPanel);
-- right-click remove extra; cursor drop spell/item; main row locked for remove.

local addonName, ns = ...

local Type, Version = "FluxMultiCastOrderPanel", 3
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local ICON_SZ = 44
local ICON_PAD = 2
local SLOT_GAP = 6
local LABEL_H = 16
local SLOT_W = ICON_SZ + ICON_PAD * 2
local SLOT_H = ICON_SZ + ICON_PAD * 2 + LABEL_H + 2
local SLOTS_PER_ROW = 8
local ROW_GAP = 6
local BORDER_PAD = 6
local Timer = C_Timer
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

local function L(key, fallback)
    local loc = _G.FluxSpellBindingLocale
    if loc and loc[key] then return loc[key] end
    return fallback or key
end

local function GetAction()
    return ns.FluxBindingAction or _G.FluxBindingAction3
end

local function GetDB()
    return ns.FluxBindingDB3 or _G.FluxBindingDB3API
end

-- ── Ghost (mirrors stance panel) ────────────────────────────────────────────

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
    if self.Raise then self:Raise() end
end

local function HideGhost()
    if ghostFrame then ghostFrame:Hide() end
end

local function ShowGhost(texture)
    HideGhost()
    if not ghostFrame then
        ghostFrame = CreateFrame("Frame", "FluxMultiCastOrderDragGhost", UIParent)
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

-- ── Drop index: same space as stance (GetCursorPosition + GetScaledRect) ────

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
        local l, b, w = s:GetScaledRect()
        if l and w then
            local mid = l + w * 0.5
            return (cx < mid) and best or math.min(best + 1, n + 1)
        end
    end
    return best
end

local function DetachAllContentChildren(content)
    if not content or not content.GetNumChildren then return end
    for i = content:GetNumChildren(), 1, -1 do
        local ch = select(i, content:GetChildren())
        if ch then
            ch:Hide()
            ch:SetParent(nil)
        end
    end
end

local function SlotCacheIsOrphaned(widget, content)
    if not content then return true end
    local s1 = widget._slotFrames and widget._slotFrames[1]
    if s1 and s1.GetParent and s1:GetParent() == content then
        return false
    end
    local nc = content.GetNumChildren and content:GetNumChildren() or 0
    if not s1 and nc > 0 then return true end
    if s1 and s1.GetParent and s1:GetParent() ~= content then return true end
    return false
end

local function HideUnusedSlotFrames(widget, keepCount)
    if not widget or not widget._slotFrames then return end
    keepCount = tonumber(keepCount) or 0
    for idx, sf in pairs(widget._slotFrames) do
        if type(idx) == "number" and sf and idx > keepCount then
            sf:SetAlpha(1)
            sf:Hide()
        end
    end
end

local function RenumberExtraIndexes(rows)
    local n = 0
    for i = 1, #rows do
        local r = rows[i]
        if r and r.kind == "extra" then
            n = n + 1
            r.extraIndex = n
        end
    end
end

local function CountExtras(rows)
    local n = 0
    for i = 1, #(rows or {}) do
        if rows[i] and rows[i].kind == "extra" then n = n + 1 end
    end
    return n
end

local function CloneRows(rows)
    local out = {}
    for i = 1, #(rows or {}) do
        local r = rows[i]
        if r and r.kind == "main" then
            out[i] = { kind = "main", action = r.action }
        elseif r and r.kind == "extra" and type(r.e) == "table" then
            out[i] = {
                kind = "extra",
                extraIndex = r.extraIndex,
                e = { type = r.e.type, id = r.e.id, name = r.e.name },
            }
        end
    end
    return out
end

local function RequestParentLayout(widget)
    if not widget or not Timer or not Timer.After then return end
    if widget._fluxReleased or widget._fluxParentLayoutPending then return end
    widget._fluxParentLayoutPending = true
    widget._fluxLayoutGen = (widget._fluxLayoutGen or 0) + 1
    local gen = widget._fluxLayoutGen
    Timer.After(0, function()
        if widget._fluxLayoutGen ~= gen or widget._fluxReleased then return end
        widget._fluxParentLayoutPending = nil
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

local function ResolveRowIcon(row)
    if not row then return 134400 end
    local Action = GetAction()
    local DB = GetDB()
    if row.kind == "main" and row.action then
        if Action and Action.GetIcon then
            return Action.GetIcon(row.action) or 134400
        end
        local a = row.action
        if a.type == "spell" and a.id and C_Spell and C_Spell.GetSpellTexture then
            return C_Spell.GetSpellTexture(a.id) or 134400
        elseif a.type == "item" and a.id and C_Item and C_Item.GetItemIconByID then
            return C_Item.GetItemIconByID(a.id) or 134400
        end
    elseif row.kind == "extra" and row.e and DB and DB.GetMacroExtraIcon then
        return DB.GetMacroExtraIcon(row.e) or 134400
    end
    return 134400
end

local function IsRowAvailable(row)
    if not row or row.kind == "main" then return true end
    local DB = GetDB()
    if row.e and DB and DB.IsMacroExtraAvailable then
        return DB.IsMacroExtraAvailable(row.e)
    end
    return true
end

local function ResolveRowLabel(row)
    if not row then return "?" end
    local Action = GetAction()
    local DB = GetDB()
    if row.kind == "main" then
        local name = "?"
        if row.action and Action and Action.GetName then
            name = Action.GetName(row.action) or name
        elseif row.action and row.action.name then
            name = row.action.name
        end
        return name
    elseif row.kind == "extra" and row.e then
        return (DB and DB.GetMacroExtraLabel and DB.GetMacroExtraLabel(row.e)) or "?"
    end
    return "?"
end

local function ShortLabel(text, maxLen)
    maxLen = maxLen or 10
    if type(text) ~= "string" then return "?" end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    if #text > maxLen then
        return text:sub(1, maxLen - 1) .. "…"
    end
    return text
end

local RefreshPanel

local function FireRowsChanged(widget)
    if not widget or widget._suppressRowsChanged then return end
    RenumberExtraIndexes(widget._rows)
    widget:Fire("OnRowsChanged", CloneRows(widget._rows))
end

local function ReorderRows(widget, fromIndex, toIndex)
    local rows = widget._rows
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
    RenumberExtraIndexes(rows)
    FireRowsChanged(widget)
end

local function FinishManualDrag(widget)
    if not widget or not widget._fluxDragging then return end
    widget._fluxDragging = false
    local fromIdx = widget._fluxDragFromIndex
    widget._fluxDragFromIndex = nil
    if widget.frame then
        widget.frame:SetScript("OnUpdate", widget._fluxPrevOnUpdate)
    end
    widget._fluxPrevOnUpdate = nil
    HideGhost()

    local n = #(widget._rows or {})
    local visibleSlots = {}
    for vi = 1, n do
        visibleSlots[vi] = widget._slotFrames and widget._slotFrames[vi]
    end
    local cx, cy = GetCursorPosition()
    local dropIdx = ComputeDropIndex(visibleSlots, cx, cy)
    if dropIdx and fromIdx and dropIdx ~= fromIdx then
        ReorderRows(widget, fromIdx, dropIdx)
    end
    RefreshPanel(widget)
end

local function DragFrameOnUpdate(widget)
    if not widget._fluxDragging then return end
    if ghostFrame and ghostFrame:IsShown() then
        PlaceGhostAtCursor(ghostFrame)
    end
    if not IsMouseButtonDown("LeftButton") then
        FinishManualDrag(widget)
    end
end

local function TryAcceptCursorDrop(widget, preferIndex)
    if not widget or not widget._canAdd then return false end
    if widget._fluxDragging then return false end
    local Action = GetAction()
    if not Action or not Action.FromCursor then return false end
    local desc = Action.FromCursor()
    if not desc then return false end
    if desc.type ~= "spell" and desc.type ~= "item" then return false end
    if CountExtras(widget._rows) >= (widget._maxExtras or 20) then
        return true
    end

    local n = #(widget._rows or {})
    local insertAt = preferIndex
    if not insertAt then
        local visibleSlots = {}
        for vi = 1, n do
            visibleSlots[vi] = widget._slotFrames and widget._slotFrames[vi]
        end
        insertAt = ComputeDropIndex(visibleSlots, GetCursorPosition()) or (n + 1)
    end
    if insertAt < 1 then insertAt = 1 end
    if insertAt > n + 1 then insertAt = n + 1 end

    table.insert(widget._rows, insertAt, {
        kind = "extra",
        e = {
            type = desc.type,
            id = desc.id,
            name = (Action.GetName and Action.GetName(desc)) or desc.name,
        },
    })
    RenumberExtraIndexes(widget._rows)
    widget:Fire("OnCursorAccepted")
    if ClearCursor then ClearCursor() end
    FireRowsChanged(widget)
    RefreshPanel(widget)
    return true
end

local function RemoveAt(widget, seqIndex)
    local row = widget._rows and widget._rows[seqIndex]
    if not row or row.kind ~= "extra" then return end
    table.remove(widget._rows, seqIndex)
    RenumberExtraIndexes(widget._rows)
    FireRowsChanged(widget)
    RefreshPanel(widget)
end

RefreshPanel = function(widget)
    if not widget or not widget._scrollChild then return end
    if widget._fluxReleased then return end
    if widget._fluxDragging then return end

    local content = widget._scrollChild
    local empty = widget._fluxEmptyText
    if not widget._slotFrames then widget._slotFrames = {} end
    if SlotCacheIsOrphaned(widget, content) then
        DetachAllContentChildren(content)
        widget._slotFrames = {}
    end

    local rows = widget._rows or {}
    local n = #rows
    if n == 0 then
        HideUnusedSlotFrames(widget, 0)
        if empty then
            empty:SetText(L("multicast_order_empty", "Drop spells or items here to build cast order."))
            empty:Show()
        end
        content:SetHeight(1)
        widget.frame:SetHeight(48)
        RequestParentLayout(widget)
        return
    end
    if empty then empty:Hide() end
    HideUnusedSlotFrames(widget, n)

    local panelW = widget.frame:GetWidth() or 400
    if panelW > 24 then
        content:SetWidth(panelW)
    end

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

            -- Dedicated icon button (stance pattern) — receives mouse reliably.
            local iconBtn = CreateFrame("Button", nil, slot)
            iconBtn:SetSize(ICON_SZ, ICON_SZ)
            iconBtn:SetPoint("TOP", slot, "TOP", 0, -ICON_PAD)
            iconBtn:EnableMouse(true)
            iconBtn:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "RightButtonUp")
            slot._iconBtn = iconBtn

            local tex = iconBtn:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            slot._iconTex = tex

            local hl = iconBtn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.15)

            local nameLabel = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameLabel:SetPoint("TOP", iconBtn, "BOTTOM", 0, -2)
            nameLabel:SetWidth(SLOT_W + 4)
            nameLabel:SetJustifyH("CENTER")
            slot._nameLabel = nameLabel
        end

        if col >= SLOTS_PER_ROW then
            x = BORDER_PAD
            y = y - (SLOT_H + ROW_GAP)
            col = 0
        end

        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
        slot:SetAlpha(1)
        slot:Show()

        local isMain = r.kind == "main"
        local avail = IsRowAvailable(r)
        if slot.SetBackdropBorderColor then
            if isMain then
                slot:SetBackdropBorderColor(0.85, 0.7, 0.25, 0.95)
            else
                slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.4)
            end
        end

        local texture = ResolveRowIcon(r)
        slot._iconTex:SetTexture(texture)
        if slot._iconTex.SetDesaturated then
            slot._iconTex:SetDesaturated(not avail)
        end
        slot._iconTex:SetVertexColor(1, 1, 1)
        if not avail then
            slot._iconTex:SetVertexColor(0.55, 0.55, 0.55)
            slot:SetAlpha(0.55)
        end

        local fullName = ResolveRowLabel(r)
        if isMain then
            slot._nameLabel:SetText(ShortLabel(fullName .. " ★", 11))
            slot._nameLabel:SetTextColor(0.95, 0.85, 0.45)
        else
            slot._nameLabel:SetText(ShortLabel(fullName, 10))
            slot._nameLabel:SetTextColor(avail and 0.9 or 0.65, avail and 0.82 or 0.65, avail and 0.55 or 0.65)
        end

        local idx = i
        local iconBtn = slot._iconBtn
        iconBtn:EnableMouse(true)
        if iconBtn.RegisterForClicks then
            iconBtn:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "RightButtonUp")
        end
        iconBtn:SetScript("OnDragStart", nil)
        iconBtn:SetScript("OnDragStop", nil)
        iconBtn:SetScript("OnClick", function(_, btn)
            if btn ~= "RightButton" then return end
            if widget._fluxDragging then return end
            if isMain then return end
            RemoveAt(widget, idx)
        end)
        iconBtn:SetScript("OnMouseDown", function(_, btn)
            if btn ~= "LeftButton" then return end
            -- Prefer accepting a held spell/item over starting a reorder drag.
            if TryAcceptCursorDrop(widget, idx) then return end
            widget._fluxDragging = true
            widget._fluxDragFromIndex = idx
            slot:SetAlpha(0.42)
            ShowGhost(texture)
            if widget.frame then
                widget._fluxPrevOnUpdate = widget.frame:GetScript("OnUpdate")
                widget.frame:SetScript("OnUpdate", function()
                    DragFrameOnUpdate(widget)
                end)
            end
        end)
        iconBtn:SetScript("OnEnter", function()
            if widget._fluxDragging then return end
            GameTooltip:SetOwner(iconBtn, "ANCHOR_RIGHT")
            local tip = fullName
            if isMain then
                tip = tip .. " " .. L("multicast_main_mark", "(main)")
            elseif not avail then
                local skip = L("multicast_extras_skipped", "skipped")
                if r.e and r.e.type == "slot" then
                    skip = L("multicast_extras_unequipped", "unequipped")
                elseif r.e and r.e.type == "item" then
                    skip = L("multicast_extras_missing", "missing")
                end
                tip = tip .. " (" .. skip .. ")"
            end
            GameTooltip:SetText(tip, 1, 1, 1)
            if isMain then
                GameTooltip:AddLine(L("multicast_main_tip", "Bar action — drag to place before/after extras."), 0.55, 0.62, 0.7, true)
            else
                GameTooltip:AddLine(L("multicast_order_tip", "Drag to reorder. Right-click to remove."), 0.55, 0.62, 0.7, true)
                if not avail then
                    GameTooltip:AddLine(L("multicast_skipped_tip", "Shown in order but skipped in the cast macro until available."), 1, 0.75, 0.35, true)
                end
            end
            GameTooltip:Show()
        end)
        iconBtn:SetScript("OnLeave", function()
            if GameTooltip:IsOwned(iconBtn) then GameTooltip:Hide() end
        end)

        x = x + SLOT_W + SLOT_GAP
        col = col + 1
    end

    local numRows = math.ceil(n / SLOTS_PER_ROW)
    local totalH = numRows * SLOT_H + math.max(0, numRows - 1) * ROW_GAP + BORDER_PAD * 2
    content:SetHeight(totalH)
    widget.frame:SetHeight(math.max(SLOT_H + BORDER_PAD * 2, totalH + 8))
    RequestParentLayout(widget)
end

local methods = {
    OnAcquire = function(self)
        self._fluxReleased = false
        self:SetFullWidth(true)
        self._fluxDragging = false
        self._fluxDragFromIndex = nil
        self._fluxPrevOnUpdate = nil
        self._rows = {}
        self._canAdd = true
        self._maxExtras = 20
        local frame = self.frame
        frame:EnableMouse(true)
        frame:SetScript("OnReceiveDrag", function()
            TryAcceptCursorDrop(self, nil)
        end)
        frame:SetScript("OnMouseUp", function(_, btn)
            if btn == "LeftButton" and not self._fluxDragging then
                TryAcceptCursorDrop(self, nil)
            end
        end)

        if not self._scrollChild then
            local child = CreateFrame("Frame", nil, frame)
            child:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            child:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            child:SetWidth(400)
            child:EnableMouse(false)
            self._scrollChild = child

            local emptyFS = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            emptyFS:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -4)
            emptyFS:SetWidth(360)
            emptyFS:SetJustifyH("LEFT")
            emptyFS:SetTextColor(0.75, 0.75, 0.75)
            emptyFS:Hide()
            self._fluxEmptyText = emptyFS
        end
    end,

    OnRelease = function(self)
        self._fluxReleased = true
        self._fluxDragging = false
        self._fluxDragFromIndex = nil
        if self.frame then
            self.frame:SetScript("OnUpdate", self._fluxPrevOnUpdate)
            self.frame:SetScript("OnReceiveDrag", nil)
            self.frame:SetScript("OnMouseUp", nil)
        end
        self._fluxPrevOnUpdate = nil
        HideGhost()
        if self._scrollChild then
            DetachAllContentChildren(self._scrollChild)
        end
        self._slotFrames = nil
        self._rows = nil
    end,

    SetRows = function(self, rows)
        self._suppressRowsChanged = true
        self._rows = CloneRows(rows) or {}
        RenumberExtraIndexes(self._rows)
        self._suppressRowsChanged = nil
        RefreshPanel(self)
    end,

    --- Allow dropping new spells/items (gate). Reorder/remove always work.
    SetCanAdd = function(self, canAdd)
        self._canAdd = canAdd and true or false
    end,

    --- Back-compat: old SetCanEdit now means "can add" only.
    SetCanEdit = function(self, canEdit)
        self._canAdd = canEdit and true or false
    end,

    SetMaxExtras = function(self, n)
        self._maxExtras = tonumber(n) or 20
    end,

    OnWidthSet = function(self, width)
        if self._fluxReleased then return end
        if type(width) ~= "number" or width <= 0 or not self._scrollChild then return end
        self._scrollChild:SetWidth(width)
        if not self._fluxDragging then
            RefreshPanel(self)
        end
    end,

    Refresh = function(self)
        RefreshPanel(self)
    end,

    SetText = function() end,
    SetFontObject = function() end,
}

local function Constructor()
    local name = "AceGUI30FluxMultiCastOrder" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:Hide()
    frame:SetHeight(SLOT_H + BORDER_PAD * 2)

    local widget = {
        type = Type,
        frame = frame,
    }
    for method, fn in pairs(methods) do
        widget[method] = fn
    end
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
