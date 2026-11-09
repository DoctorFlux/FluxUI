-- AceGUI: drag-to-reorder list of Info Frame stats (FPS, ping, durability, pinned).
-- Order is per character (FluxInfoFrame char DB statOrder).

local Type, Version = "FluxInfoStatOrder", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local ROW_H = 22
local ROW_GAP = 4
local PAD = 4

local lastActiveWidget = nil
local FinishRowDrag

local function CursorY()
    local _, cy = GetCursorPosition()
    local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    if type(scale) ~= "number" or scale <= 0 then
        scale = 1
    end
    return cy / scale
end

local function ApplyOrder(keys)
    if FluxInfoFrame and FluxInfoFrame.SetStatOrder then
        FluxInfoFrame.SetStatOrder(keys)
    end
end

local function RefreshPanel(widget)
    if not widget or widget._fluxReleased or not widget._rows then
        return
    end
    local entries = {}
    if FluxInfoFrame and FluxInfoFrame.GetOrderedVisibleStats then
        entries = FluxInfoFrame.GetOrderedVisibleStats() or {}
    end
    local n = #entries
    local rows = widget._rows
    for i = 1, n do
        local row = rows[i]
        if not row then
            row = CreateFrame("Button", nil, widget._content)
            row:SetHeight(ROW_H)
            row:RegisterForDrag("LeftButton")
            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            row.bg:SetColorTexture(0.12, 0.12, 0.14, 0.9)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
            row.label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            row.label:SetJustifyH("LEFT")
            row:SetScript("OnEnter", function(self)
                if not self._drag then
                    self.bg:SetColorTexture(0.2, 0.22, 0.28, 0.95)
                end
            end)
            row:SetScript("OnLeave", function(self)
                if not self._drag then
                    self.bg:SetColorTexture(0.12, 0.12, 0.14, 0.9)
                end
            end)
            row:SetScript("OnMouseDown", function(self, button)
                if button ~= "LeftButton" then
                    return
                end
                self._pressY = CursorY()
                self._drag = false
            end)
            row:SetScript("OnUpdate", function(self)
                if self._drag then
                    if not IsMouseButtonDown("LeftButton") then
                        FinishRowDrag(widget, self)
                    end
                    return
                end
                if not self._pressY then
                    return
                end
                if not IsMouseButtonDown("LeftButton") then
                    self._pressY = nil
                    return
                end
                if math.abs(CursorY() - self._pressY) >= 4 then
                    self._pressY = nil
                    self._drag = true
                    widget._dragFrom = self._index
                    self.bg:SetColorTexture(0.25, 0.35, 0.5, 1)
                    if widget._ghost then
                        widget._ghost.label:SetText(self._label or "")
                        widget._ghost:Show()
                    end
                end
            end)
            row:SetScript("OnMouseUp", function(self)
                if self._drag or widget._dragFrom == self._index then
                    FinishRowDrag(widget, self)
                else
                    self._pressY = nil
                end
            end)
            rows[i] = row
        end
        local entry = entries[i]
        row._index = i
        row._key = entry.key
        row._label = entry.label or entry.key
        row.label:SetText(row._label)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", widget._content, "TOPLEFT", 0, -((i - 1) * (ROW_H + ROW_GAP)))
        row:SetPoint("TOPRIGHT", widget._content, "TOPRIGHT", 0, -((i - 1) * (ROW_H + ROW_GAP)))
        row._drag = false
        row:Show()
    end
    for i = n + 1, #rows do
        rows[i]:Hide()
        rows[i]._key = nil
    end
    widget._shownCount = n
    if widget._empty then
        if n == 0 then
            widget._empty:Show()
        else
            widget._empty:Hide()
        end
    end
    local height = PAD * 2 + (n > 0 and (n * ROW_H + (n - 1) * ROW_GAP) or 22)
    widget.frame:SetHeight(height)
    widget._content:SetHeight(math.max(1, height - PAD * 2))
end

FinishRowDrag = function(widget, row)
    if row then
        row._pressY = nil
        row._drag = false
        if row.bg then
            row.bg:SetColorTexture(0.12, 0.12, 0.14, 0.9)
        end
    end
    if not widget or not widget._dragFrom then
        if widget and widget._ghost then
            widget._ghost:Hide()
        end
        return
    end
    local fromIndex = widget._dragFrom
    widget._dragFrom = nil
    if widget._ghost then
        widget._ghost:Hide()
    end
    local rows = widget._rows
    local cy = CursorY()
    local dest = fromIndex
    local shown = widget._shownCount or 0
    for ri = 1, shown do
        local other = rows[ri]
        if other and other:IsShown() then
            local top, bottom = other:GetTop(), other:GetBottom()
            if top and bottom and cy <= top and cy >= bottom then
                local mid = (top + bottom) / 2
                dest = (cy >= mid) and ri or (ri + 1)
                break
            end
        end
    end
    if dest == fromIndex or dest == fromIndex + 1 then
        return
    end
    local keys = {}
    for ri = 1, shown do
        keys[ri] = rows[ri]._key
    end
    local moved = table.remove(keys, fromIndex)
    if not moved then
        return
    end
    if dest > fromIndex then
        dest = dest - 1
    end
    if dest < 1 then
        dest = 1
    end
    if dest > #keys + 1 then
        dest = #keys + 1
    end
    table.insert(keys, dest, moved)
    ApplyOrder(keys)
    RefreshPanel(widget)
end

local methods = {
    OnAcquire = function(self)
        self._fluxReleased = false
        lastActiveWidget = self
        RefreshPanel(self)
    end,
    OnRelease = function(self)
        self._fluxReleased = true
        self._dragFrom = nil
        if self._ghost then
            self._ghost:Hide()
        end
        if lastActiveWidget == self then
            lastActiveWidget = nil
        end
    end,
    SetText = function() end,
    SetLabel = function() end,
    OnWidthSet = function(self, width)
        if self._fluxReleased or not self._content then
            return
        end
        if type(width) == "number" and width > 0 then
            self._content:SetWidth(math.max(40, width - PAD * 2))
        end
    end,
}

local function Constructor()
    local name = "AceGUI30FluxInfoStatOrder" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:Hide()
    frame:SetHeight(PAD * 2 + ROW_H)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
    content:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD)
    content:SetHeight(ROW_H)

    local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    empty:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    empty:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    empty:SetJustifyH("LEFT")
    empty:SetText("Enable FPS, ping, durability, or pin a stat.")
    empty:Hide()

    local ghost = CreateFrame("Frame", nil, UIParent)
    ghost:SetFrameStrata("TOOLTIP")
    ghost:SetSize(160, ROW_H)
    ghost:EnableMouse(false)
    ghost:Hide()
    ghost.bg = ghost:CreateTexture(nil, "BACKGROUND")
    ghost.bg:SetAllPoints()
    ghost.bg:SetColorTexture(0.15, 0.25, 0.4, 0.9)
    ghost.label = ghost:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ghost.label:SetPoint("LEFT", 8, 0)
    ghost.label:SetPoint("RIGHT", -8, 0)
    ghost.label:SetJustifyH("LEFT")
    ghost:SetScript("OnUpdate", function(self)
        if not self:IsShown() then
            return
        end
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        if type(scale) ~= "number" or scale <= 0 then
            scale = 1
        end
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end)

    local widget = {
        frame = frame,
        type = Type,
        _content = content,
        _rows = {},
        _empty = empty,
        _ghost = ghost,
        _shownCount = 0,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

function _G.FluxInfoStatOrder_RequestRefresh()
    local w = lastActiveWidget
    if not w or w._fluxReleased then
        return
    end
    RefreshPanel(w)
end
