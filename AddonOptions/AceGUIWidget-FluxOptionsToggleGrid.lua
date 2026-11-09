-- AceGUI: responsive checkbox grid for Vendor & restock options (Automation, junk filters).

local Type, Version = "FluxOptionsToggleGrid", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local Timer = C_Timer

local CHECK = 24
local LABEL_PAD = 6
local ROW_H = 26
local GAP_X = 16
local GAP_Y = 4
local MIN_COL_W = 200
local MAX_COLS = 8

local function RequestParentLayout(widget)
    if not widget or not Timer or not Timer.After then
        return
    end
    if widget._fluxParentLayoutPending then
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

local function MeasureColWidth(toggle, font)
    local label = toggle.name or ""
    font:SetText(label)
    local tw = font:GetStringWidth() or 0
    return CHECK + LABEL_PAD + tw + GAP_X
end

local function RefreshToggleRow(row)
    if not row or not row.toggle then
        return
    end
    local t = row.toggle
    local hidden = t.hidden and t.hidden() or false
    local disabled = t.disabled and t.disabled() or false
    if hidden then
        row.frame:Hide()
        return
    end
    row.frame:Show()
    local checked = t.get and t.get() or false
    row.check:SetChecked(checked and true or false)
    row.check:SetEnabled(not disabled)
    if row.label then
        local alpha = disabled and 0.45 or 1
        row.label:SetAlpha(alpha)
    end
end

local function BuildToggleRow(parent, toggle, onChanged)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)

    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(CHECK, CHECK)
    check:SetPoint("LEFT", row, "LEFT", 0, 0)
    check:SetScript("OnClick", function(self)
        if toggle.set then
            toggle.set(self:GetChecked())
        end
        if onChanged then
            onChanged()
        end
        RefreshToggleRow(row)
    end)
    if toggle.desc and toggle.desc ~= "" then
        check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(toggle.name or "", 1, 1, 1)
            GameTooltip:AddLine(toggle.desc, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", LABEL_PAD, 0)
    label:SetJustifyH("LEFT")
    label:SetText(toggle.name or "")
    label:SetScript("OnEnter", check:GetScript("OnEnter"))
    label:SetScript("OnLeave", check:GetScript("OnLeave"))

    row.check = check
    row.label = label
    row.toggle = toggle
    row.frame = row
    RefreshToggleRow(row)
    return row
end

local function GetSectionToggles(sectionKey)
    local sections = _G.FluxOptionsToggleGridSections
    if not sections or not sectionKey then
        return nil
    end
    return sections[sectionKey]
end

local function LayoutToggleGrid(self)
    local toggles = self._toggles
    if not toggles or not self._gridParent then
        return
    end

    local visible = {}
    for _, row in ipairs(self._rows or {}) do
        if row and row.toggle then
            local hidden = row.toggle.hidden and row.toggle.hidden() or false
            if not hidden then
                visible[#visible + 1] = row
            else
                row.frame:Hide()
            end
        end
    end

    local n = #visible
    if n == 0 then
        self._gridParent:SetSize(1, 1)
        self:SetHeight(1)
        RequestParentLayout(self)
        return
    end

    local fw = self.frame.width or self.frame:GetWidth() or 400
    fw = math.max(fw, MIN_COL_W)

    local measureFont = self._measureFont
    local colWidths = {}
    for i, row in ipairs(visible) do
        colWidths[i] = math.max(MIN_COL_W, MeasureColWidth(row.toggle, measureFont))
    end

    local cols = 1
    for tryCols = math.min(n, MAX_COLS), 1, -1 do
        local rows = math.ceil(n / tryCols)
        local ok = true
        for r = 0, rows - 1 do
            local rowW = 0
            for c = 0, tryCols - 1 do
                local idx = r * tryCols + c + 1
                if idx > n then
                    break
                end
                rowW = rowW + colWidths[idx]
            end
            if rowW - GAP_X > fw then
                ok = false
                break
            end
        end
        if ok then
            cols = tryCols
            break
        end
    end

    local rows = math.ceil(n / cols)
    local y = 0
    for r = 0, rows - 1 do
        local x = 0
        local rowMaxH = ROW_H
        for c = 0, cols - 1 do
            local idx = r * cols + c + 1
            if idx > n then
                break
            end
            local row = visible[idx]
            local w = colWidths[idx]
            row.frame:ClearAllPoints()
            row.frame:SetPoint("TOPLEFT", self._gridParent, "TOPLEFT", x, -y)
            row.frame:SetSize(w - GAP_X, ROW_H)
            row.frame:Show()
            x = x + w
            RefreshToggleRow(row)
        end
        y = y + rowMaxH + GAP_Y
    end

    local totalH = math.max(ROW_H, y - GAP_Y)
    self._gridParent:SetSize(fw, totalH)
    self:SetHeight(totalH)
    RequestParentLayout(self)
end

local function EnsureBuilt(self)
    if self._built then
        return
    end
    local sectionKey = self._sectionKey
    local toggles = GetSectionToggles(sectionKey)
    self._toggles = toggles
    if not toggles then
        return
    end
    self._rows = self._rows or {}
    local onChanged = function()
        LayoutToggleGrid(self)
    end
    for _, toggle in ipairs(toggles) do
        local row = BuildToggleRow(self._gridParent, toggle, onChanged)
        self._rows[#self._rows + 1] = row
    end
    self._built = true
end

local methods = {
    ["OnAcquire"] = function(self)
        self:SetFullWidth(true)
        local frame = self.frame
        frame:EnableMouse(false)

        if not self._gridParent then
            self._gridParent = CreateFrame("Frame", nil, frame)
            self._gridParent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        end
        if not self._measureFont then
            self._measureFont = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            self._measureFont:Hide()
        end

        if Timer and Timer.After then
            Timer.After(0, function()
                EnsureBuilt(self)
                LayoutToggleGrid(self)
            end)
        else
            EnsureBuilt(self)
            LayoutToggleGrid(self)
        end
    end,

    ["OnRelease"] = function(self)
        if self._rows then
            for _, row in ipairs(self._rows) do
                if row and row.frame then
                    row.frame:Hide()
                    row.frame:SetParent(nil)
                end
            end
            self._rows = {}
        end
        self._built = nil
        self._toggles = nil
        self._sectionKey = nil
    end,

    ["SetText"] = function(self, text)
        self._sectionKey = text
        EnsureBuilt(self)
        LayoutToggleGrid(self)
    end,

    ["SetFontObject"] = function() end,
    ["SetImage"] = function() end,
    ["SetImageSize"] = function() end,

    ["OnWidthSet"] = function(self, width)
        if type(width) ~= "number" or width <= 0 then
            return
        end
        local last = self._fluxLastPanelWidth
        if last and math.abs(width - last) < 2 then
            return
        end
        self._fluxLastPanelWidth = width
        if self._built then
            LayoutToggleGrid(self)
        end
    end,
}

local function Constructor()
    local name = "AceGUI30FluxOptionsToggleGrid" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:Hide()

    local widget = {
        frame = frame,
        type = Type,
        _rows = {},
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
