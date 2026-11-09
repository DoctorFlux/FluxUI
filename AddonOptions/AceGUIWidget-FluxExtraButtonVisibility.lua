-- AceGUI: compact icon grid to cycle Extra button visibility modes (Action Bars tab).
-- Intentionally does NOT call parent DoLayout (Ace scrollbar width feedback loops freeze the client).

local Type, Version = "FluxExtraButtonVisibilityPanel", 15
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local CELL = 44
local TEX = 34
local GAP = 0
local FRAME_PAD = 0
local MAX_COLS_SANITY = 64
--- Stable height estimate so Ace scroll width does not thrash with row count.
local HEIGHT_COLS_ASSUME = 8

local Timer = C_Timer

local MODE_BORDER = {
    off = { 0.55, 0.22, 0.22 },
    auto = { 0.28, 0.52, 0.85 },
    always = { 0.25, 0.72, 0.35 },
    hidden = { 0.45, 0.42, 0.55 },
}

local MODE_BADGE = {
    off = "O",
    auto = "A",
    always = "+",
    hidden = "H",
}

local CELL_BACKDROP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function ModeBorderColor(mode)
    local c = MODE_BORDER[mode] or MODE_BORDER.auto
    return c[1], c[2], c[3]
end

local function ModeBadgeChar(mode)
    return MODE_BADGE[mode] or "?"
end

local function AppendTooltipBody(EBV, id)
    local list = EBV.ModeLists and EBV.ModeLists[id]
    if list and #list > 0 then
        local badges = {}
        for _, m in ipairs(list) do
            badges[#badges + 1] = ModeBadgeChar(m)
        end
        GameTooltip:AddLine(table.concat(badges, " | "), 0.72, 0.78, 0.84, false)
    end
    if list and EBV.GetOptionsModeHelpLine then
        for _, m in ipairs(list) do
            local help = EBV.GetOptionsModeHelpLine(id, m)
            if help and help ~= "" then
                GameTooltip:AddLine(ModeBadgeChar(m) .. "  " .. help, 0.6, 0.66, 0.72, true)
            end
        end
    end
    if EBV.GetOptionsTooltipNote then
        local note = EBV.GetOptionsTooltipNote(id)
        if note and note ~= "" then
            GameTooltip:AddLine(note, 0.52, 0.55, 0.58, true)
        end
    end
    GameTooltip:AddLine("Click to cycle.", 0.42, 0.44, 0.48, false)
end

local function ShowTooltipForCell(btn, EBV, id)
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if GameTooltip.SetMinimumWidth then
        GameTooltip:SetMinimumWidth(220)
    end

    local title = (EBV.Labels and EBV.Labels[id]) or id
    if GameTooltip_SetTitle then
        GameTooltip_SetTitle(GameTooltip, title)
    else
        GameTooltip:AddLine(title, 1, 0.85, 0.1)
    end

    local m = EBV.GetRawMode and EBV.GetRawMode(id) or "auto"
    local shown = (EBV.ModeDisplayName and EBV.ModeDisplayName(m)) or m
    GameTooltip:AddLine("Now: " .. shown, 0.95, 0.95, 0.95, false)
    AppendTooltipBody(EBV, id)
    GameTooltip:Show()
end

local function RefreshTooltipIfStillHovering(btn, EBV, id)
    if not btn or not btn:IsMouseOver() then
        return
    end
    ShowTooltipForCell(btn, EBV, id)
end

local function BuildIconCell(parent, id)
    local EBV = FluxExtraButtonVisibility
    if not EBV then return end

    local btn = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    btn:SetSize(CELL, CELL)
    if btn.SetBackdrop then
        btn:SetBackdrop(CELL_BACKDROP)
    end

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(TEX, TEX)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    local tex = EBV.Icons and EBV.Icons[id] or "Interface/Icons/INV_Misc_QuestionMark"
    icon:SetTexture(tex)

    local hoverShine = btn:CreateTexture(nil, "OVERLAY")
    hoverShine:SetAllPoints(icon)
    hoverShine:SetColorTexture(1, 1, 1, 0)
    hoverShine:SetBlendMode("ADD")

    local badge = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 3)
    badge:SetJustifyH("RIGHT")
    if badge.SetShadowOffset then
        badge:SetShadowOffset(1, -1)
    end

    local function RefreshModeVisual()
        local m = EBV.GetRawMode and EBV.GetRawMode(id) or "auto"
        local r, g, b = ModeBorderColor(m)
        if btn.SetBackdropBorderColor then
            btn:SetBackdropBorderColor(r, g, b, 1)
        end
        if btn.SetBackdropColor then
            btn:SetBackdropColor(0.08, 0.08, 0.1, 0.92)
        end
        badge:SetText(ModeBadgeChar(m))
        badge:SetTextColor(1, 0.95, 0.85, 1)
    end
    RefreshModeVisual()
    btn._fluxRefreshMode = RefreshModeVisual

    local function ClearHover()
        hoverShine:SetColorTexture(1, 1, 1, 0)
        icon:SetVertexColor(1, 1, 1)
        RefreshModeVisual()
    end

    btn:SetScript("OnClick", function()
        if EBV.Cycle then
            EBV.Cycle(id)
        end
        RefreshModeVisual()
        if Timer and Timer.After then
            Timer.After(0, function()
                RefreshTooltipIfStillHovering(btn, EBV, id)
            end)
        else
            RefreshTooltipIfStillHovering(btn, EBV, id)
        end
    end)

    btn:SetScript("OnEnter", function(self)
        hoverShine:SetColorTexture(1, 1, 1, 0.22)
        local m = EBV.GetRawMode and EBV.GetRawMode(id) or "auto"
        local r, g, b = ModeBorderColor(m)
        if btn.SetBackdropBorderColor then
            btn:SetBackdropBorderColor(math.min(r * 1.35, 1), math.min(g * 1.35, 1), math.min(b * 1.35, 1), 1)
        end
        if btn.SetBackdropColor then
            btn:SetBackdropColor(0.2, 0.22, 0.28, 0.98)
        end
        ShowTooltipForCell(self, EBV, id)
    end)

    btn:SetScript("OnLeave", function()
        ClearHover()
        GameTooltip:Hide()
    end)

    return btn
end

local function StableHeightForCount(nids)
    local rows = math.max(1, math.ceil(nids / HEIGHT_COLS_ASSUME))
    return rows * CELL + (rows - 1) * GAP
end

--- Reposition cells from current width. Height is fixed (set once on build) to avoid Ace layout storms.
local function LayoutExtraButtonGrid(self)
    if self._fluxReleased or not self._iconParent or not self._rows then
        return
    end
    local EBV = FluxExtraButtonVisibility
    if not EBV or not (EBV.GetOptionsIds or EBV.GetOrderedIds) then
        return
    end
    local ids = (EBV.GetOptionsIds and EBV.GetOptionsIds()) or EBV.GetOrderedIds()
    local nids = #ids
    if nids == 0 then
        return
    end
    local fw = self.frame.width or self.frame:GetWidth() or 400
    local innerAvail = math.max(fw - 2 * FRAME_PAD, CELL + GAP)
    local cols = math.max(1, math.floor((innerAvail + GAP) / (CELL + GAP)))
    if cols > MAX_COLS_SANITY then
        cols = MAX_COLS_SANITY
    end

    local availW = math.max(fw - 2 * FRAME_PAD, cols * CELL + (cols - 1) * GAP)

    for i, cell in ipairs(self._rows) do
        if not cell then
            break
        end
        local idx = i - 1
        local row = math.floor(idx / cols)
        local col = idx % cols
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", self._iconParent, "TOPLEFT", col * (CELL + GAP), -(row * (CELL + GAP)))
    end

    local h = self._fluxFixedHeight or StableHeightForCount(nids)
    self._iconParent:SetSize(availW, h)
    -- Height already applied on build; do not SetHeight/DoLayout here.
end

local methods = {
    ["OnAcquire"] = function(self)
        self._fluxReleased = false
        self:SetFullWidth(true)
        local frame = self.frame
        frame:EnableMouse(true)

        if not self._iconParent then
            self._iconParent = CreateFrame("Frame", nil, frame)
            self._iconParent:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PAD, -FRAME_PAD)
        end

        if not self._built then
            self._rows = self._rows or {}
            local EBV = FluxExtraButtonVisibility
            if EBV and (EBV.GetOptionsIds or EBV.GetOrderedIds) then
                local ids = (EBV.GetOptionsIds and EBV.GetOptionsIds()) or EBV.GetOrderedIds()
                local h = StableHeightForCount(#ids)
                self._fluxFixedHeight = h
                self:SetHeight(h)
                if frame.SetHeight then
                    frame:SetHeight(h)
                end
                for i, id in ipairs(ids) do
                    local cell = BuildIconCell(self._iconParent, id)
                    cell:SetParent(self._iconParent)
                    cell:Show()
                    self._rows[i] = cell
                end
            else
                self._fluxFixedHeight = 40
                self:SetWidth(200)
                self:SetHeight(40)
            end
            self._built = true
        else
            local h = self._fluxFixedHeight or 44
            self:SetHeight(h)
            if frame.SetHeight then
                frame:SetHeight(h)
            end
            for _, cell in ipairs(self._rows or {}) do
                if cell then
                    cell:SetParent(self._iconParent)
                    cell:Show()
                    if cell._fluxRefreshMode then
                        cell._fluxRefreshMode()
                    end
                end
            end
        end

        self._fluxLastPanelWidth = nil
        self._fluxLayoutGen = (self._fluxLayoutGen or 0) + 1
        local gen = self._fluxLayoutGen
        if Timer and Timer.After then
            Timer.After(0, function()
                if self._fluxReleased or self._fluxLayoutGen ~= gen then
                    return
                end
                LayoutExtraButtonGrid(self)
            end)
        else
            LayoutExtraButtonGrid(self)
        end
        if FluxExtraButtonVisibility and FluxExtraButtonVisibility._RegisterOptionPanelWidget then
            FluxExtraButtonVisibility._RegisterOptionPanelWidget(self)
        end
    end,

    ["OnRelease"] = function(self)
        self._fluxReleased = true
        self._fluxLayoutGen = (self._fluxLayoutGen or 0) + 1
        self._fluxLastPanelWidth = nil
        if FluxExtraButtonVisibility and FluxExtraButtonVisibility._UnregisterOptionPanelWidget then
            FluxExtraButtonVisibility._UnregisterOptionPanelWidget(self)
        end
        if self._rows then
            for _, r in ipairs(self._rows) do
                if r then
                    if r.Hide then
                        r:Hide()
                    end
                end
            end
        end
    end,

    ["SetText"] = function(self, text)
        self._title = text
    end,

    ["SetFontObject"] = function() end,
    ["SetImage"] = function() end,
    ["SetImageSize"] = function() end,

    ["OnWidthSet"] = function(self, width)
        if self._fluxReleased then
            return
        end
        if type(width) ~= "number" or width <= 0 then
            return
        end
        local last = self._fluxLastPanelWidth
        if last and math.abs(width - last) < 2 then
            return
        end
        self._fluxLastPanelWidth = width
        if self._built then
            LayoutExtraButtonGrid(self)
        end
    end,
}

local function Constructor()
    local name = "AceGUI30FluxExtraButtonVisibility" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:EnableMouse(true)
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

function _G.FluxExtraButtonVisibilityPanel_OnOptionsClosed()
    if FluxExtraButtonVisibility and FluxExtraButtonVisibility._ClearOptionPanelWidgets then
        FluxExtraButtonVisibility._ClearOptionPanelWidgets()
    end
end
