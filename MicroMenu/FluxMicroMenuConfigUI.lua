-- FluxMicroMenuConfigUI.lua
-- MicroMenu layout editor: horizontal bar (matches FluxMicroMenu) inside FluxUI + standalone.
-- Editor-only extra gap, drag ghost at cursor, boundary-based drop index.

if not FluxMicroMenuConfig or not FluxMicroMenu then return end

FluxMicroMenuConfigUI = FluxMicroMenuConfigUI or {}
local UI = FluxMicroMenuConfigUI

local MODE_H = 14
local PADDING = 4
--- Extra pixels between preview slots in this editor only (live bar unchanged).
local EDITOR_SLOT_GAP = 8
--- Max buttons per row before wrapping (standalone + embed).
local EDITOR_SLOTS_PER_ROW = 12

--- Standalone (right-click) panel: same vertical relationship as FluxAddonContainer left-click popup.
local STANDALONE_TITLE_INSET = 38
--- Extra top inset for standalone panel when reset buttons are shown (below title).
local STANDALONE_RESET_ROW_H = 28
local STANDALONE_MIN_W, STANDALONE_MIN_H = 260, 140

UI.scroll = nil
UI.content = nil
--- FluxUI Ace embed only: rows live here (no UIPanelScrollFrameTemplate).
UI.embedDirectContent = nil
UI.rowFrames = {}
UI.dragStartIndex = nil
UI.draggedRow = nil
UI.isDragging = false
UI.embedAceWidget = nil
UI.floatingFrame = nil
UI.contentBar = nil
--- Incremented at each RefreshRows; deferred mode-label timers skip if stale.
UI._modeLabelRefreshGeneration = 0

-- Layout state (matches RefreshRows; used by drag hit-testing)
local slotW = 40
local layoutSpacing = -3
local ROW_V_GAP = 6

local ghostFrame = nil
local ghostPreview = nil

local MODE_LABELS = {
    account = "Acc",
    character = "Chr",
    off = "Off",
}

local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

--- Retail GameTooltip can leave status bars / widget sets / handler info; wipe alongside line text.
local TOOLTIP_LINE_WIPE_MAX = 80

local function ApplyGameTooltipFullClear(tip)
    if not tip then return end
    pcall(function()
        if tip.ClearHandlerInfo then
            tip:ClearHandlerInfo()
        end
    end)
    if GameTooltip_ClearStatusBars then
        pcall(GameTooltip_ClearStatusBars, tip)
    end
    if GameTooltip_ClearProgressBars then
        pcall(GameTooltip_ClearProgressBars, tip)
    end
    if GameTooltip_ClearWidgetSet then
        pcall(GameTooltip_ClearWidgetSet, tip)
    end
    if GameTooltip_ClearMoney then
        pcall(GameTooltip_ClearMoney, tip)
    end
end

local function WipeGameTooltipTextRegions(tip, maxLines)
    maxLines = maxLines or TOOLTIP_LINE_WIPE_MAX
    for i = 1, maxLines do
        local L = _G["GameTooltipTextLeft" .. i]
        local R = _G["GameTooltipTextRight" .. i]
        if L and L.SetText then
            L:SetText("")
        end
        if R and R.SetText then
            R:SetText("")
        end
    end
end

--- Single place for editor row tooltips: hide, anchor, wipe left+right columns (ClearLines often leaves residue).
local function ShowEditorTooltip(owner, titleLine, bodyLine)
    if not owner or not GameTooltip then return end
    local tip = GameTooltip
    tip:Hide()
    ApplyGameTooltipFullClear(tip)
    tip:SetOwner(owner, "ANCHOR_RIGHT")
    if tip.ClearLines then
        tip:ClearLines()
    end
    WipeGameTooltipTextRegions(tip, TOOLTIP_LINE_WIPE_MAX)
    tip:SetText(titleLine or " ", 1, 1, 1)
    if bodyLine and bodyLine ~= "" then
        tip:AddLine(bodyLine, 0.75, 0.75, 0.75, true)
    end
    tip:Show()
end

local function HideEditorTooltip()
    if not GameTooltip then return end
    GameTooltip:Hide()
    ApplyGameTooltipFullClear(GameTooltip)
end

--- Before destroying editor slots, hide tooltip if it is still anchored to this row (avoids stale lines after reorder).
local function HideEditorTooltipIfOwnerInRowFrames(rowFrames)
    if not GameTooltip or not GameTooltip.GetOwner or not GameTooltip.IsShown then
        return
    end
    if not GameTooltip:IsShown() then
        return
    end
    local owner = GameTooltip:GetOwner()
    if not owner then
        return
    end
    for _, slot in ipairs(rowFrames or {}) do
        if owner == slot or owner == slot._fluxPreview or owner == slot._fluxModeBtn then
            HideEditorTooltip()
            WipeGameTooltipTextRegions(GameTooltip, TOOLTIP_LINE_WIPE_MAX)
            return
        end
    end
end

local function PerformMicroMenuResetOrder()
    if FluxMicroMenuConfig and FluxMicroMenuConfig.ResetUnifiedOrderToDefault then
        FluxMicroMenuConfig:ResetUnifiedOrderToDefault()
    end
    if UI.RefreshRows then
        UI:RefreshRows()
    end
end

local function ShowMicroMenuResetAllDialog()
    StaticPopup_Show("FLUXUI_MICROMENU_RESET_ALL")
end

local function GetMicroSpacing()
    if FluxMicroMenu and FluxMicroMenu.GetLayoutSpacing then
        return FluxMicroMenu:GetLayoutSpacing()
    end
    local spacing = -3
    if FluxGetMicroButtonSpacing then
        local ok, s = pcall(FluxGetMicroButtonSpacing)
        if ok and type(s) == "number" then
            spacing = s
        end
    end
    return spacing
end

--- Spacing between slot anchors in the editor: non-negative gap for easier targeting.
local function GetEditorLayoutSpacing()
    local base = GetMicroSpacing()
    if base < 0 then
        return EDITOR_SLOT_GAP
    end
    return base + EDITOR_SLOT_GAP
end

local function GetSlotDimensions()
    local btnW, btnH = 32, 40
    if FluxGetStandardMicroButtonSize then
        local ok, w, h = pcall(FluxGetStandardMicroButtonSize)
        if ok and type(w) == "number" and type(h) == "number" then
            btnW, btnH = w, h
        end
    end
    --- Order preview uses nominal shell size only; do not tie slot grid to live bar size slider.
    return btnW, btnH + 2 + MODE_H
end

local function GetEditorRowInnerWidth()
    local btnW = select(1, GetSlotDimensions())
    local spacing = GetEditorLayoutSpacing()
    return EDITOR_SLOTS_PER_ROW * btnW + (EDITOR_SLOTS_PER_ROW - 1) * spacing
end

--- Scroll chrome (~36) + padded 12-slot row; capped to viewport in callers.
local function GetStandaloneOuterWidthFromSlotGrid()
    return math.max(STANDALONE_MIN_W, math.min(720, 36 + PADDING * 2 + GetEditorRowInnerWidth()))
end

local function IsEditorVisible()
    if UI.embedAceWidget and UI.embedAceWidget.frame and UI.embedAceWidget.frame:IsShown() then
        return true
    end
    if UI.floatingFrame and UI.floatingFrame:IsShown() then
        return true
    end
    return false
end

local function SyncMinimapToMicroConfigFlag()
    if not FluxMinimapToMicro then return end
    FluxMinimapToMicro.isConfigShown = IsEditorVisible()
end

local function HideDragGhost()
    if ghostFrame then
        ghostFrame:Hide()
        ghostFrame:SetScript("OnUpdate", nil)
    end
    if ghostPreview then
        ghostPreview:Hide()
        ghostPreview:SetParent(nil)
        ghostPreview = nil
    end
end

local function ShowDragGhost(iconSource)
    HideDragGhost()
    if not iconSource or not FluxMicroMenu or not FluxMicroMenu.CreateConfigPreviewMicroButton then
        return
    end
    if not ghostFrame then
        ghostFrame = CreateFrame("Frame", "FluxMicroMenuConfigDragGhost", UIParent)
        ghostFrame:SetFrameStrata("TOOLTIP")
        ghostFrame:SetFrameLevel(10000)
        ghostFrame:EnableMouse(false)
    end
    ghostPreview = FluxMicroMenu:CreateConfigPreviewMicroButton(ghostFrame, iconSource)
    if not ghostPreview then return end
    ghostPreview:EnableMouse(false)
    ghostPreview:SetPoint("CENTER", ghostFrame, "CENTER", 0, 0)
    local w, h = ghostPreview:GetSize()
    if w and h then
        ghostFrame:SetSize(w, h)
    else
        ghostFrame:SetSize(32, 40)
    end
    ghostFrame:SetAlpha(0.92)
    ghostFrame:Show()
    ghostFrame:SetScript("OnUpdate", function(self)
        if not UI.isDragging then return end
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    end)
end

do
    if FluxMicroMenuConfig.RegisterCallback then
        FluxMicroMenuConfig:RegisterCallback(function()
            if IsEditorVisible() then
                UI:RefreshRows()
            end
        end)
    end
end

local function GetScrollTopInset(parent)
    if parent == UI.floatingFrame and UI.floatingFrame and UI.floatingFrame.titleInset then
        return -UI.floatingFrame.titleInset
    end
    if UI.embedAceWidget and UI.embedAceWidget.frame == parent then
        return -4 - STANDALONE_RESET_ROW_H
    end
    return -4
end

function UI:IsAceEmbedParent(parent)
    return self.embedAceWidget and parent == self.embedAceWidget.frame
end

--- Standalone popup only: scrollable body (viewport-limited). Not used inside FluxUI Ace options.
function UI:EnsureScrollInternal(parent)
    if not self.scroll then
        local scroll = CreateFrame("ScrollFrame", "FluxMicroMenuConfigScroll", parent, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, GetScrollTopInset(parent))
        scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 8)
        scroll:EnableMouse(true)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(sc, delta)
            local cur = sc:GetVerticalScroll() or 0
            local step = 48
            local max = sc:GetVerticalScrollRange() or 0
            local n = cur - delta * step
            if n < 0 then n = 0 end
            if n > max then n = max end
            sc:SetVerticalScroll(n)
        end)

        local content = CreateFrame("Frame", nil, scroll)
        scroll:SetScrollChild(content)

        scroll._fluxSizeHook = true
        scroll:SetScript("OnSizeChanged", function()
            if IsEditorVisible() and UI.scroll == scroll then
                C_Timer.After(0, function()
                    if UI.scroll == scroll and scroll:IsVisible() then
                        UI:RefreshRows()
                    end
                end)
            end
        end)

        self.scroll = scroll
        self.content = content
    else
        self.scroll:SetParent(parent)
        self.scroll:ClearAllPoints()
        self.scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, GetScrollTopInset(parent))
        self.scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 8)
        self.scroll:Show()
    end
end

--- Routes to either a plain growing container (FluxUI options embed) or a scroll frame (standalone window).
function UI:EnsureContentContainer(parent)
    if self:IsAceEmbedParent(parent) then
        if self.scroll then
            self.scroll:Hide()
            self.scroll:SetParent(UIParent)
            self.scroll:ClearAllPoints()
            self.scroll = nil
        end
        if not self.embedDirectContent then
            self.embedDirectContent = CreateFrame("Frame", "FluxMicroMenuEmbedDirectContent", parent)
        end
        self.embedDirectContent:SetParent(parent)
        self.embedDirectContent:ClearAllPoints()
        local topInset = GetScrollTopInset(parent)
        self.embedDirectContent:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, topInset)
        self.embedDirectContent:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, topInset)
        self.content = self.embedDirectContent
        self.embedDirectContent:Show()
    else
        if self.embedDirectContent then
            self.embedDirectContent:Hide()
            self.embedDirectContent:SetParent(UIParent)
            self.embedDirectContent:ClearAllPoints()
        end
        self:EnsureScrollInternal(parent)
    end
end

--- Reset row for FluxUI Ace options embed (same actions as standalone panel).
function UI:EnsureEmbedResetButtons(parent)
    if not parent then
        return
    end
    local row = parent._fluxMicroMenuResetRow
    if not row then
        row = CreateFrame("Frame", nil, parent)
        parent._fluxMicroMenuResetRow = row
        row:SetHeight(24)

        local btnResetOrder = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        btnResetOrder:SetSize(132, 22)
        btnResetOrder:SetPoint("LEFT", row, "LEFT", 0, 0)
        btnResetOrder:SetText("Reset order")
        btnResetOrder:SetScript("OnClick", PerformMicroMenuResetOrder)
        btnResetOrder:SetScript("OnEnter", function(self)
            ShowEditorTooltip(self, "Reset order", "Restore the default row order (native priority + minimap scan + discovered buttons). Does not change Account / Character / Off.")
        end)
        btnResetOrder:SetScript("OnLeave", HideEditorTooltip)

        local btnResetAll = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        btnResetAll:SetSize(168, 22)
        btnResetAll:SetPoint("LEFT", btnResetOrder, "RIGHT", 8, 0)
        btnResetAll:SetText("Reset defaults…")
        btnResetAll:SetScript("OnClick", ShowMicroMenuResetAllDialog)
        btnResetAll:SetScript("OnEnter", function(self)
            ShowEditorTooltip(self, "Reset to defaults", "Restore default row order and set every native button to Account and every minimap icon to Off.")
        end)
        btnResetAll:SetScript("OnLeave", HideEditorTooltip)
    end
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -4)
    row:Show()
end

function UI:EnsureFloatingFrame()
    if self.floatingFrame then
        return self.floatingFrame
    end

    local f = CreateFrame("Frame", "FluxMicroMenuConfigUIPanel", UIParent, backdropTemplate)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetSize(GetStandaloneOuterWidthFromSlotGrid(), 280)
    f:SetPoint("CENTER")
    f:Hide()
    f:EnableMouse(true)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        local r, g, b = 0.12, 0.12, 0.15
        if FluxBorder and FluxBorder.GetThemedVertexRGB then
            r, g, b = FluxBorder:GetThemedVertexRGB()
        end
        f:SetBackdropColor(r * 0.25, g * 0.25, b * 0.25, 0.96)
        f:SetBackdropBorderColor(r, g, b, 1)
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("MicroMenu layout")

    f.titleInset = STANDALONE_TITLE_INSET + STANDALONE_RESET_ROW_H

    local resetRow = CreateFrame("Frame", nil, f)
    resetRow:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -34)
    resetRow:SetPoint("TOPRIGHT", f, "TOPRIGHT", -36, -34)
    resetRow:SetHeight(24)

    local btnResetOrder = CreateFrame("Button", nil, resetRow, "UIPanelButtonTemplate")
    btnResetOrder:SetSize(132, 22)
    btnResetOrder:SetPoint("LEFT", resetRow, "LEFT", 0, 0)
    btnResetOrder:SetText("Reset order")
    btnResetOrder:SetScript("OnClick", PerformMicroMenuResetOrder)
    btnResetOrder:SetScript("OnEnter", function(self)
        ShowEditorTooltip(self, "Reset order", "Restore the default row order (native priority + minimap scan + discovered buttons). Does not change Account / Character / Off.")
    end)
    btnResetOrder:SetScript("OnLeave", HideEditorTooltip)

    local btnResetAll = CreateFrame("Button", nil, resetRow, "UIPanelButtonTemplate")
    btnResetAll:SetSize(168, 22)
    btnResetAll:SetPoint("LEFT", btnResetOrder, "RIGHT", 8, 0)
    btnResetAll:SetText("Reset defaults…")
    btnResetAll:SetScript("OnClick", ShowMicroMenuResetAllDialog)
    btnResetAll:SetScript("OnEnter", function(self)
        ShowEditorTooltip(self, "Reset to defaults", "Restore default row order and set every native button to Account and every minimap icon to Off.")
    end)
    btnResetAll:SetScript("OnLeave", HideEditorTooltip)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        UI:HideStandalone()
    end)

    f:RegisterEvent("PLAYER_STARTED_MOVING")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_STARTED_MOVING" and not UI.isDragging then
            UI:HideStandalone()
        end
    end)

    if f.SetClampedToScreen then
        f:SetClampedToScreen(true)
    end

    self.floatingFrame = f
    return f
end

--- Same anchor as FluxAddonContainer (left-click): panel opens under the micro button, right-aligned.
local function PositionStandaloneNearAnchor(f, anchorButton)
    f:ClearAllPoints()
    if not anchorButton or not anchorButton.GetRight then
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        return
    end
    f:SetPoint("TOPRIGHT", anchorButton, "BOTTOMRIGHT", 0, -2)
end

--- Nudge within screen and away from FluxMicroMenu (same rules as FluxAddonContainer; see FluxAddonMicroButton.lua).
local function ClampStandaloneFrameAfterLayout(f, anchorButton)
    if not f or not f:IsShown() or not anchorButton or not anchorButton.GetRight then
        return
    end
    if FluxAddonSystem and FluxAddonSystem.ClampPopupToScreenAndMicroMenu then
        FluxAddonSystem.ClampPopupToScreenAndMicroMenu(f, anchorButton)
        return
    end
    local pw = UIParent:GetWidth()
    local ph = UIParent:GetHeight()
    local margin = 8

    f:ClearAllPoints()
    f:SetPoint("TOPRIGHT", anchorButton, "BOTTOMRIGHT", 0, -2)

    local left = f:GetLeft()
    local right = f:GetRight()
    local bottom = f:GetBottom()
    local top = f:GetTop()
    if not left or not right or not bottom or not top then
        return
    end

    local dx, dy = 0, 0
    if left < margin then
        dx = margin - left
    end
    if right > pw - margin then
        dx = dx + (pw - margin - right)
    end
    if bottom < margin then
        dy = margin - bottom
    end
    local topAfter = top + dy
    if topAfter > ph - margin then
        dy = dy + (ph - margin - topAfter)
    end

    if dx ~= 0 or dy ~= 0 then
        f:ClearAllPoints()
        f:SetPoint("TOPRIGHT", anchorButton, "BOTTOMRIGHT", dx, -2 + dy)
    end
end

--- Size floating window: fixed width (matches FluxAddon popup shell), height from content with scroll.
local function SizeStandaloneFrameToContent(f, content)
    if not f or not content or not UIParent or not UIParent.GetWidth then
        return
    end
    local pw = UIParent:GetWidth()
    local ph = UIParent:GetHeight()
    local maxOuterW = math.min(720, pw * 0.92)
    local maxOuterH = math.min(ph * 0.88, ph - 24)
    local titleInset = (f and f.titleInset) or STANDALONE_TITLE_INSET
    local chromeV = titleInset + 8 + 8
    local cw = content:GetWidth() or 120
    local ch = content:GetHeight() or 40
    local outerW = math.min(maxOuterW, math.max(STANDALONE_MIN_W, cw + 36))
    local maxBody = math.max(80, maxOuterH - chromeV)
    local bodyH = math.min(ch, maxBody)
    local outerH = math.max(STANDALONE_MIN_H, chromeV + bodyH)
    outerH = math.min(outerH, maxOuterH)
    f:SetSize(outerW, outerH)
end

function UI:AttachToAceWidget(widget)
    if self.floatingFrame and self.floatingFrame:IsShown() then
        self.floatingFrame:Hide()
    end

    self.embedAceWidget = widget
    local parent = widget.frame
    parent:Show()

    self:EnsureEmbedResetButtons(parent)
    self:EnsureContentContainer(parent)
    self:RefreshRows()
    SyncMinimapToMicroConfigFlag()

    C_Timer.After(0, function()
        if UI.embedAceWidget ~= widget then return end
        if widget.frame and widget.frame:IsVisible() then
            UI:RefreshRows()
        end
    end)
end

function UI:DetachFromAceWidget(widget)
    if self.embedAceWidget ~= widget then return end
    if widget and widget.frame and widget.frame._fluxMicroMenuResetRow then
        widget.frame._fluxMicroMenuResetRow:Hide()
    end
    HideDragGhost()

    for _, r in ipairs(self.rowFrames) do
        r:Hide()
        r:SetParent(nil)
    end
    wipe(self.rowFrames)

    if self.contentBar then
        self.contentBar:Hide()
        self.contentBar:SetParent(nil)
    end

    if self.embedDirectContent then
        self.embedDirectContent:Hide()
        self.embedDirectContent:SetParent(UIParent)
        self.embedDirectContent:ClearAllPoints()
    end
    self.content = nil
    self.embedAceWidget = nil

    if self.floatingFrame and self.floatingFrame:IsShown() then
        self:EnsureContentContainer(self.floatingFrame)
        self:RefreshRows()
    elseif self.scroll then
        self.scroll:Hide()
        self.scroll:SetParent(UIParent)
        self.scroll:ClearAllPoints()
    end

    SyncMinimapToMicroConfigFlag()
end

function UI:ShowStandalone(anchorButton)
    self.standaloneAnchorButton = anchorButton
    local f = self:EnsureFloatingFrame()
    self:EnsureContentContainer(f)

    f:SetWidth(GetStandaloneOuterWidthFromSlotGrid())
    f:SetHeight(STANDALONE_MIN_H)

    PositionStandaloneNearAnchor(f, anchorButton)

    f:Show()
    self:RefreshRows()
    SyncMinimapToMicroConfigFlag()
    if self.scroll and self.scroll.UpdateScrollChildRect then
        self.scroll:UpdateScrollChildRect()
    end
    C_Timer.After(0, function()
        if not f:IsShown() or UI.standaloneAnchorButton ~= anchorButton then
            return
        end
        pcall(ClampStandaloneFrameAfterLayout, f, anchorButton)
    end)
end

function UI:HideStandalone()
    self.standaloneAnchorButton = nil
    HideDragGhost()
    if self.floatingFrame then
        self.floatingFrame:Hide()
    end

    if self.embedAceWidget and self.embedAceWidget.frame and self.embedAceWidget.frame:IsShown() then
        self:EnsureContentContainer(self.embedAceWidget.frame)
        self:RefreshRows()
    else
        for _, r in ipairs(self.rowFrames) do
            r:Hide()
            r:SetParent(nil)
        end
        wipe(self.rowFrames)
        if self.contentBar then
            self.contentBar:Hide()
            self.contentBar:SetParent(nil)
        end
        if self.scroll then
            self.scroll:Hide()
            self.scroll:SetParent(UIParent)
            self.scroll:ClearAllPoints()
        end
    end

    SyncMinimapToMicroConfigFlag()
end

function UI:ToggleStandalone(anchorButton)
    if self.floatingFrame and self.floatingFrame:IsShown() then
        self:HideStandalone()
    else
        self:ShowStandalone(anchorButton)
    end
end

--- Character micro button uses Portrait (SetPortraitTexture), not .icon — see Blizzard CharacterMicroButtonMixin.
local function GetCharacterMicroPortraitRegion(btn)
    if not btn then
        return nil
    end
    local portrait = btn.Portrait
    if not portrait and btn.GetName and btn:GetName() == "CharacterMicroButton" and _G.MicroButtonPortrait then
        portrait = _G.MicroButtonPortrait
    end
    return portrait
end

local function EnsureCharacterPortraitTexture(portrait)
    if not portrait or not SetPortraitTexture or not portrait.GetTexture then
        return
    end
    local t = portrait:GetTexture()
    if not t or t == "" then
        pcall(SetPortraitTexture, portrait, "player")
    end
end

local function GetCharacterMicroPortraitTexture(btn)
    local portrait = GetCharacterMicroPortraitRegion(btn)
    if not portrait then
        return nil
    end
    EnsureCharacterPortraitTexture(portrait)
    if portrait.GetTexture then
        local p = portrait:GetTexture()
        if p and p ~= "" then
            return p
        end
    end
    return nil
end

local function GetIconPathForRow(row)
    if row.kind == "native" then
        local btn
        if FluxMicroMenuConfig and FluxMicroMenuConfig.IsTradeSkillRowId
            and FluxMicroMenuConfig:IsTradeSkillRowId(row.rowId) then
            local key = FluxMicroMenuConfig:GetTradeSkillKey(row.rowId)
            local gname = key and FluxMicroMenuConfig:GetTradeSkillMicroGlobalName(key)
            btn = gname and _G[gname]
            if not btn and FluxTradeSkillMicro and FluxTradeSkillMicro.skillsByKey and key then
                local skill = FluxTradeSkillMicro.skillsByKey[key]
                if skill and skill.texture then
                    return skill.texture
                end
            end
        elseif FluxMicroMenuConfig and FluxMicroMenuConfig.IsTradeSkillFlyoutRowId
            and FluxMicroMenuConfig:IsTradeSkillFlyoutRowId(row.rowId) then
            btn = _G[row.rowId]
        else
            btn = _G[row.name] or _G[row.rowId]
        end
        if btn then
            local portraitPath = GetCharacterMicroPortraitTexture(btn)
            if portraitPath then
                return portraitPath
            end
            local nt = btn.GetNormalTexture and btn:GetNormalTexture()
            if nt and nt.GetTexture then
                local p = nt:GetTexture()
                if p then return p end
            end
            if btn.icon and btn.icon.GetTexture then
                local p = btn.icon:GetTexture()
                if p then return p end
            end
        end
    else
        if FluxMinimapToMicro and FluxMinimapToMicro.GetButtonIcon then
            local orig = FluxMinimapToMicro.buttonNameMap and FluxMinimapToMicro.buttonNameMap[row.name]
            if orig then
                local path = FluxMinimapToMicro:GetButtonIcon(orig)
                if path then return path end
            end
        end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

--- Snapshot of a Texture's file + texcoords so config preview stays on one static frame (no atlas animation).
local function GetTexCoordSnapshot(tex)
    if not tex or not tex.GetTexCoord then
        return nil
    end
    local a, b, c, d, e, f, g, h = tex:GetTexCoord()
    if not a then
        return nil
    end
    if e == nil then
        return { a, b, c, d }
    end
    return { a, b, c, d, e, f, g, h }
end

--- Prefer atlas name for DF+ HUD icons: GetTexture returns the atlas texture page and GetTexCoord is often full 0–1, which draws the entire sheet in the preview.
local function CaptureTextureForConfigPreview(tex)
    if not tex then
        return nil
    end
    if tex.GetAtlas then
        local okA, atlas = pcall(function()
            return tex:GetAtlas()
        end)
        if okA and type(atlas) == "string" and atlas ~= "" then
            return { atlas = atlas, texture = "Interface\\Icons\\INV_Misc_QuestionMark" }
        end
    end
    if not tex.GetTexture then
        return nil
    end
    local ok, t = pcall(function()
        return tex:GetTexture()
    end)
    if not ok or not t or t == "" then
        return nil
    end
    local coords = GetTexCoordSnapshot(tex)
    if coords and coords[1] and coords[2] and coords[3] and coords[4] then
        local a, b, c, d = coords[1], coords[2], coords[3], coords[4]
        if a <= 0.001 and b >= 0.999 and c <= 0.001 and d >= 0.999 then
            coords = nil
        end
    end
    if coords then
        return { texture = t, texCoords = coords }
    end
    return { texture = t }
end

--- Match live FluxMicroMenu bar: same frame + icon layer as on the bar (atlas or texture / fileID).
--- Player portrait cannot be copied via GetTexture+SetTexture; preview uses SetPortraitTexture (see FluxMicroMenu ApplyConfigPreviewIconLayer).
local function GetIconSourceForRow(row)
    if row.kind == "native" and row.name == "CharacterMicroButton" then
        if SetPortraitTexture then
            return { usePlayerPortrait = true }
        end
        local cbtn = _G.CharacterMicroButton
        if cbtn then
            local portrait = GetCharacterMicroPortraitRegion(cbtn)
            if portrait then
                EnsureCharacterPortraitTexture(portrait)
                local cap = CaptureTextureForConfigPreview(portrait)
                if cap then
                    return cap
                end
                if portrait.GetTexture then
                    local tex = portrait:GetTexture()
                    if tex and tex ~= "" then
                        return { texture = tex }
                    end
                end
            end
        end
    end
    local btn
    if row.kind == "native" then
        if FluxMicroMenuConfig and FluxMicroMenuConfig.IsTradeSkillRowId
            and FluxMicroMenuConfig:IsTradeSkillRowId(row.rowId) then
            local key = FluxMicroMenuConfig:GetTradeSkillKey(row.rowId)
            local gname = key and FluxMicroMenuConfig:GetTradeSkillMicroGlobalName(key)
            btn = gname and _G[gname]
        elseif FluxMicroMenuConfig and FluxMicroMenuConfig.IsTradeSkillFlyoutRowId
            and FluxMicroMenuConfig:IsTradeSkillFlyoutRowId(row.rowId) then
            btn = _G[row.rowId]
        else
            btn = _G[row.name] or _G[row.rowId]
        end
    elseif FluxMicroMenuConfig and row.name then
        local gname = FluxMicroMenuConfig:GetMinimapMicroGlobalName(row.name)
        btn = gname and _G[gname]
    end
    if btn and btn.icon then
        local ic = btn.icon
        if ic.GetAtlas then
            local ok, atlas = pcall(function()
                return ic:GetAtlas()
            end)
            if ok and type(atlas) == "string" and atlas ~= "" then
                return { atlas = atlas, texture = "Interface\\Icons\\INV_Misc_QuestionMark" }
            end
        end
        local cap = CaptureTextureForConfigPreview(ic)
        if cap then
            return cap
        end
        if ic.GetTexture then
            local tex = ic:GetTexture()
            if tex then
                return { texture = tex }
            end
        end
    end
    if btn then
        local nt = btn.GetNormalTexture and btn:GetNormalTexture()
        if nt then
            if nt.GetAtlas then
                local ok, atlas = pcall(function()
                    return nt:GetAtlas()
                end)
                if ok and type(atlas) == "string" and atlas ~= "" then
                    return { atlas = atlas, texture = "Interface\\Icons\\INV_Misc_QuestionMark" }
                end
            end
            local cap = CaptureTextureForConfigPreview(nt)
            if cap then
                return cap
            end
            if nt.GetTexture then
                local p = nt:GetTexture()
                if p then
                    return { texture = p }
                end
            end
        end
    end
    return { texture = GetIconPathForRow(row) }
end

--- Tooltip / display name from live slot fields (not captured rowData tables).
local function GetSlotDisplayName(slot)
    if not slot or not slot.rowId then
        return ""
    end
    if FluxMicroMenuConfig and FluxMicroMenuConfig.IsMinimapRowId and FluxMicroMenuConfig:IsMinimapRowId(slot.rowId) then
        local src = slot.name or ""
        if FluxMinimapToMicro and FluxMinimapToMicro.GetFriendlyMinimapButtonName then
            return FluxMinimapToMicro:GetFriendlyMinimapButtonName(src)
        end
        return src
    end
    return slot.name or slot.rowId or ""
end

--- Unified mode for native rows and M2M rows (account / character / off).
local function GetSlotMode(slot)
    if not slot or not slot.rowId or not FluxMicroMenuConfig then
        return "off"
    end
    if FluxMicroMenuConfig:IsMinimapRowId(slot.rowId) then
        if FluxMinimapToMicro and FluxMinimapToMicro.GetMode and slot.name then
            return FluxMinimapToMicro:GetMode(slot.name)
        end
    else
        -- Always use rowId (TSK rows use a friendly display name in slot.name).
        return FluxMicroMenuConfig:GetNativeMode(slot.rowId)
    end
    return "off"
end

--- Preview icon/button: grayscale when off; full color for account / character (overlay handles chr tint).
local function ApplyPreviewVisualForMode(preview, mode)
    if not preview then return end
    local off = (mode == "off")
    local r, g, b = 1, 1, 1
    local a = 1
    if off then
        r, g, b = 0.48, 0.48, 0.48
        a = 0.78
    end
    preview:SetAlpha(a)
    local regions = { preview:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.IsObjectType and region:IsObjectType("Texture") and region.SetVertexColor then
            region:SetVertexColor(r, g, b)
        end
    end
end

--- Account: current default strip look. Character: green strip + green overlay on preview. Off: dim / colorless.
local function ApplySlotModeVisual(slot)
    if not slot then return end
    local mode = GetSlotMode(slot)
    if type(mode) == "string" then
        mode = mode:lower()
    end

    local preview = slot._fluxPreview
    local overlay = slot._fluxCharOverlay
    local modeBtn = slot._fluxModeBtn
    local mfs = slot._fluxModeLabel

    if overlay then
        if mode == "character" then
            overlay:Show()
        else
            overlay:Hide()
        end
    end

    ApplyPreviewVisualForMode(preview, mode)

    if modeBtn and modeBtn.SetBackdropColor and modeBtn.SetBackdropBorderColor then
        if mode == "off" then
            modeBtn:SetBackdropColor(0.06, 0.06, 0.07, 0.88)
            modeBtn:SetBackdropBorderColor(0.22, 0.22, 0.22, 0.45)
        elseif mode == "character" then
            modeBtn:SetBackdropColor(0.05, 0.12, 0.09, 0.92)
            modeBtn:SetBackdropBorderColor(0.28, 0.62, 0.42, 0.82)
        else
            modeBtn:SetBackdropColor(0.12, 0.12, 0.15, 0.92)
            modeBtn:SetBackdropBorderColor(0.4, 0.45, 0.4, 0.7)
        end
    end

    if mfs and mfs.SetTextColor then
        if mode == "off" then
            mfs:SetTextColor(0.55, 0.55, 0.55)
        elseif mode == "character" then
            mfs:SetTextColor(0.75, 1, 0.82)
        else
            mfs:SetTextColor(1, 1, 1)
        end
    end
end

--- Mode strip reads only from slot + saved vars (avoids stale closures after drag/reorder).
local function MakeModeLabelRefresh(slot, mfs)
    return function()
        if not mfs or not slot or not slot.rowId or not FluxMicroMenuConfig then
            return
        end
        local mode = GetSlotMode(slot)
        local label = MODE_LABELS[mode]
        if not label and type(mode) == "string" then
            label = MODE_LABELS[mode:lower()]
        end
        local text = label or mode or "?"
        if mfs.SetText then
            mfs:SetText("")
        end
        if mfs.SetFormattedText then
            mfs:SetFormattedText("%s", text)
        else
            mfs:SetText(text)
        end
        if mfs.SetNonSpaceWrap then
            mfs:SetNonSpaceWrap(true)
        end
        if mfs.SetMaxLines then
            mfs:SetMaxLines(1)
        end
        ApplySlotModeVisual(slot)
    end
end

function UI:RefreshAllModeLabels()
    for _, slot in ipairs(self.rowFrames or {}) do
        if slot._fluxRefreshMode then
            pcall(slot._fluxRefreshMode)
        end
    end
end

function UI:ScheduleModeLabelRefresh()
    local gen = UI._modeLabelRefreshGeneration or 0
    C_Timer.After(0, function()
        if gen ~= (UI._modeLabelRefreshGeneration or 0) then
            return
        end
        if UI.RefreshAllModeLabels then
            UI:RefreshAllModeLabels()
        end
        C_Timer.After(0.05, function()
            if gen ~= (UI._modeLabelRefreshGeneration or 0) then
                return
            end
            if UI.RefreshAllModeLabels then
                UI:RefreshAllModeLabels()
            end
        end)
    end)
end

local function CycleModeForRowSlot(slot)
    if not FluxMicroMenuConfig or not slot or not slot.rowId then
        return
    end
    HideEditorTooltip()
    FluxMicroMenuConfig:CycleRowMode(slot.rowId)
    UI:RefreshRows()
end

function UI:CreateSlot(parent, unifiedListIndex, rowData, slotWidth, slotHeight, iconPath)
    local slot = CreateFrame("Frame", nil, parent, backdropTemplate)
    slot:SetSize(slotWidth, slotHeight)
    if slot.SetClipsChildren then
        slot:SetClipsChildren(true)
    end

    if slot.SetBackdrop then
        slot:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        slot:SetBackdropColor(0, 0, 0, 0.06)
        slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.35)
    end

    -- Index into FluxMicroMenuConfig:GetUnifiedOrderList() (not filtered row order).
    slot.rowIndex = unifiedListIndex or rowData.unifiedListIndex
    slot.rowId = rowData.rowId
    slot.kind = rowData.kind
    slot.name = rowData.name
    slot._iconSource = iconPath

    local preview

    if FluxMicroMenu and FluxMicroMenu.CreateConfigPreviewMicroButton then
        preview = FluxMicroMenu:CreateConfigPreviewMicroButton(slot, iconPath)
    else
        preview = CreateFrame("Button", nil, slot)
        preview:SetSize(slotWidth, slotHeight - MODE_H - 2)
        local tex = preview:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(iconPath)
        preview.icon = tex
    end

    slot._fluxPreview = preview

    if preview then
        preview:SetFrameLevel(slot:GetFrameLevel() + 1)
        preview:SetPoint("TOP", slot, "TOP", 0, -2)
        -- Slot height is btnH + 2 + MODE_H; reserve 2px gap above mode strip so preview can be full btnH (same as live FluxMicroMenu buttons). -6 was squashing icons vs the bar.
        local maxPreviewH = math.max(8, slotHeight - MODE_H - 2)
        local pw, ph = preview:GetSize()
        if ph and ph > maxPreviewH then
            preview:SetHeight(maxPreviewH)
        end
        if pw and pw > slotWidth then
            preview:SetWidth(slotWidth)
        end
        preview:RegisterForDrag("LeftButton")
        if preview.RegisterForClicks then
            preview:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        end
        preview:SetScript("OnDragStart", function()
            if not FluxMicroMenuConfig then return end
            UI.isDragging = true
            UI.dragStartIndex = slot.rowIndex
            UI.dragStartRowId = slot.rowId
            UI.draggedRow = slot
            slot:SetAlpha(0.42)
            ShowDragGhost(slot._iconSource)
        end)
        preview:SetScript("OnDragStop", function()
            slot:SetAlpha(1)
            HideDragGhost()
            if UI.draggedRow and FluxMicroMenuConfig then
                UI:HandleDragDropHorizontal()
            end
            UI.draggedRow = nil
            UI.dragStartIndex = nil
            UI.dragStartRowId = nil
            UI.isDragging = false
        end)
        preview:SetScript("OnClick", function(_, btn)
            if btn == "RightButton" or btn == "MiddleButton" then
                CycleModeForRowSlot(slot)
            end
        end)

        local chrOverlay = CreateFrame("Frame", nil, slot)
        chrOverlay:SetFrameLevel(preview:GetFrameLevel() + 12)
        chrOverlay:SetPoint("TOPLEFT", preview, "TOPLEFT", -1, 1)
        chrOverlay:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", 1, -1)
        chrOverlay:EnableMouse(false)
        local chrTex = chrOverlay:CreateTexture(nil, "OVERLAY")
        chrTex:SetAllPoints()
        chrTex:SetColorTexture(0.12, 0.78, 0.36, 0.26)
        chrOverlay:Hide()
        slot._fluxCharOverlay = chrOverlay
    end

    local modeBtn = CreateFrame("Button", nil, slot)
    modeBtn:SetSize(slotWidth - 4, MODE_H)
    modeBtn:SetPoint("BOTTOM", slot, "BOTTOM", 0, 2)
    modeBtn:SetFrameLevel(slot:GetFrameLevel() + 25)
    modeBtn:EnableMouse(true)
    modeBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    if modeBtn.Raise then
        modeBtn:Raise()
    end

    if modeBtn.SetBackdrop then
        modeBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        modeBtn:SetBackdropColor(0.12, 0.12, 0.15, 0.92)
        modeBtn:SetBackdropBorderColor(0.4, 0.45, 0.4, 0.7)
    end

    slot._fluxModeBtn = modeBtn

    local mfs = modeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mfs:SetAllPoints()
    mfs:SetJustifyH("CENTER")
    slot._fluxModeLabel = mfs

    slot._fluxRefreshMode = MakeModeLabelRefresh(slot, mfs)
    slot._fluxRefreshMode()

    modeBtn:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" or btn == "RightButton" or btn == "MiddleButton" then
            CycleModeForRowSlot(slot)
        end
    end)
    modeBtn:SetScript("OnEnter", function()
        local tip = "Click to cycle Off → Account → Character → Off."
        if FluxMicroMenuConfig and FluxMicroMenuConfig.IsTradeSkillRelatedRowId
            and FluxMicroMenuConfig:IsTradeSkillRelatedRowId(slot.rowId) then
            tip = "Trade skills are character-only. Click to cycle Off → Character → Off."
        end
        ShowEditorTooltip(modeBtn, GetSlotDisplayName(slot), tip)
    end)
    modeBtn:SetScript("OnLeave", function()
        HideEditorTooltip()
    end)

    if preview then
        preview:SetScript("OnEnter", function()
            local cycleTip = "Left-drag the icon to reorder. Right-click or middle-click the icon, or click the strip below, to cycle Off → Account → Character → Off."
            if FluxMicroMenuConfig and FluxMicroMenuConfig.IsTradeSkillRelatedRowId
                and FluxMicroMenuConfig:IsTradeSkillRelatedRowId(slot.rowId) then
                cycleTip = "Left-drag the icon to reorder. Right-click or middle-click the icon, or click the strip below, to cycle Off → Character → Off (trade skills are character-only)."
            end
            ShowEditorTooltip(
                preview,
                GetSlotDisplayName(slot),
                cycleTip
            )
        end)
        preview:SetScript("OnLeave", function()
            HideEditorTooltip()
        end)
    end

    return slot
end

--- Map cursor (nx, ny) to final list index (1..n). Works for wrapped multi-row layout.
function UI:ComputeDropIndexFromCursor(nx, ny)
    local n = #self.rowFrames
    if n == 0 then return nil end

    for i = 1, n do
        local s = self.rowFrames[i]
        local l, r, t, b = s:GetLeft(), s:GetRight(), s:GetTop(), s:GetBottom()
        if l and r and t and b and nx >= l and nx <= r and ny >= b and ny <= t then
            local cx = (l + r) / 2
            if nx < cx then
                return i
            else
                return math.min(i + 1, n + 1)
            end
        end
    end

    local best, bestD = 1, math.huge
    for i = 1, n do
        local s = self.rowFrames[i]
        local cx, cy = s:GetCenter()
        if cx and cy then
            local d = (nx - cx) * (nx - cx) + (ny - cy) * (ny - cy)
            if d < bestD then
                bestD = d
                best = i
            end
        end
    end
    local s = self.rowFrames[best]
    local l, r = s:GetLeft(), s:GetRight()
    if l and r then
        local cx = (l + r) / 2
        if nx < cx then
            return best
        else
            return math.min(best + 1, n + 1)
        end
    end
    return best
end

--- Map visible drop target to a rowId-based reorder (handles hidden inactive TSK gaps).
--- insertVisible: 1 = before first visible; n+1 = after last visible.
local function ApplyVisibleDropReorder(rowFrames, fromRowId, insertVisible)
    if not FluxMicroMenuConfig or not fromRowId then
        return
    end
    local n = #rowFrames
    if n == 0 then
        return
    end
    if insertVisible < 1 then
        insertVisible = 1
    end
    if insertVisible > n + 1 then
        insertVisible = n + 1
    end

    if insertVisible == n + 1 then
        -- After last visible slot (may have hidden TSK between it and Addon).
        FluxMicroMenuConfig:ReorderUnifiedRowAfter(fromRowId, rowFrames[n].rowId)
        return
    end

    local target = rowFrames[insertVisible]
    if not target or not target.rowId then
        return
    end

    if target.rowId == fromRowId then
        -- Drop landed on self (common when only hidden rows sit between prev and self).
        -- Treat as "place immediately after previous visible".
        local prev = insertVisible > 1 and rowFrames[insertVisible - 1] or nil
        if prev and prev.rowId and prev.rowId ~= fromRowId then
            FluxMicroMenuConfig:ReorderUnifiedRowAfter(fromRowId, prev.rowId)
        end
        return
    end

    FluxMicroMenuConfig:ReorderUnifiedRowById(fromRowId, target.rowId)
end

function UI:HandleDragDropHorizontal()
    if not self.dragStartRowId or not FluxMicroMenuConfig then
        self:RefreshRows()
        return
    end

    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    local nx, ny = x / scale, y / scale

    local n = #self.rowFrames
    local fromRowId = self.dragStartRowId
    local insertVisible = self:ComputeDropIndexFromCursor(nx, ny)

    if not insertVisible or insertVisible < 1 or insertVisible > n + 1 then
        self:RefreshRows()
        return
    end

    ApplyVisibleDropReorder(self.rowFrames, fromRowId, insertVisible)
    self:RefreshRows()
end

--- Clearing scripts that were never set errors on some frame types (e.g. overlay Frame without OnClick).
local function SafeClearScript(frame, scriptName)
    if not frame or not frame.SetScript then return end
    if frame.HasScript then
        local ok, has = pcall(function()
            return frame:HasScript(scriptName)
        end)
        if ok and has then
            frame:SetScript(scriptName, nil)
        end
    else
        pcall(function()
            frame:SetScript(scriptName, nil)
        end)
    end
end

--- Clear preview button scripts plus one level of nested children (textures/regions) before orphaning the slot.
local function SafeClearSlotPreviewScripts(slot)
    local preview = slot and slot._fluxPreview
    if not preview then
        return
    end
    for _, scriptName in ipairs({ "OnEnter", "OnLeave", "OnClick", "OnDragStart", "OnDragStop" }) do
        SafeClearScript(preview, scriptName)
    end
    for _, child in ipairs({ preview:GetChildren() }) do
        if child and child.SetScript then
            SafeClearScript(child, "OnEnter")
            SafeClearScript(child, "OnLeave")
            SafeClearScript(child, "OnClick")
        end
    end
end

function UI:RefreshRows()
    self._modeLabelRefreshGeneration = (self._modeLabelRefreshGeneration or 0) + 1

    HideDragGhost()
    HideEditorTooltip()
    HideEditorTooltipIfOwnerInRowFrames(self.rowFrames)

    local content = self.content
    if not content then return end

    for _, r in ipairs(self.rowFrames) do
        SafeClearSlotPreviewScripts(r)
        r:Hide()
        r:SetParent(nil)
        SafeClearScript(r, "OnEnter")
        SafeClearScript(r, "OnLeave")
        for _, child in ipairs({ r:GetChildren() }) do
            if child and child.SetScript then
                SafeClearScript(child, "OnEnter")
                SafeClearScript(child, "OnLeave")
                SafeClearScript(child, "OnClick")
                SafeClearScript(child, "OnDragStart")
                SafeClearScript(child, "OnDragStop")
            end
        end
    end
    wipe(self.rowFrames)

    -- GetEffectiveRows scans minimap buttons and applies M2M visibility; EnsureUnifiedDefaults merges discoveries.
    local rows = FluxMicroMenuConfig:GetEffectiveRows()
    local n = #rows
    layoutSpacing = GetEditorLayoutSpacing()
    local btnW, slotH = GetSlotDimensions()
    slotW = btnW

    local standaloneMode = self.floatingFrame and self.floatingFrame:IsShown() and not self.embedAceWidget
    local availInnerW = GetEditorRowInnerWidth()
    local availW = availInnerW
    local contentW = PADDING * 2 + availInnerW

    local x = PADDING
    local y = -PADDING
    local prev = nil
    local col = 0
    local rowIndex = (n > 0) and 1 or 0

    if n > 0 then
        if not self.contentBar then
            self.contentBar = CreateFrame("Frame", nil, content, backdropTemplate)
            self.contentBar:SetFrameLevel(content:GetFrameLevel())
        end
        self.contentBar:SetParent(content)
        self.contentBar:ClearAllPoints()
        self.contentBar:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        self.contentBar:SetSize(availW + PADDING * 2, 100)
        if self.contentBar.SetBackdrop then
            self.contentBar:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false, edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 },
            })
            self.contentBar:SetBackdropColor(0.08, 0.08, 0.1, 0.55)
            self.contentBar:SetBackdropBorderColor(0.25, 0.25, 0.28, 0.5)
        end
        self.contentBar:Show()
    elseif self.contentBar then
        self.contentBar:Hide()
    end

    for i, rd in ipairs(rows) do
        if col >= EDITOR_SLOTS_PER_ROW then
            x = PADDING
            y = y - (slotH + ROW_V_GAP)
            rowIndex = rowIndex + 1
            prev = nil
            col = 0
        end

        local iconSource = GetIconSourceForRow(rd)
        local slot = self:CreateSlot(content, rd.unifiedListIndex or i, rd, btnW, slotH, iconSource)
        if self.contentBar then
            slot:SetFrameLevel(self.contentBar:GetFrameLevel() + 2)
        else
            slot:SetFrameLevel(content:GetFrameLevel() + 2)
        end

        if prev == nil then
            slot:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
        else
            slot:SetPoint("LEFT", prev, "RIGHT", layoutSpacing, 0)
        end

        table.insert(self.rowFrames, slot)
        slot:Show()
        prev = slot
        x = x + btnW + layoutSpacing
        col = col + 1
    end

    local numRows = rowIndex

    for _, slot in ipairs(self.rowFrames) do
        if slot._fluxRefreshMode then
            slot._fluxRefreshMode()
        end
    end
    self:ScheduleModeLabelRefresh()

    local contentH = (n > 0) and (PADDING * 2 + numRows * slotH + math.max(0, numRows - 1) * ROW_V_GAP) or 24
    content:SetSize(math.max(contentW, 120), math.max(contentH, slotH + PADDING * 2))

    if self.contentBar and n > 0 then
        self.contentBar:SetSize(content:GetWidth(), content:GetHeight())
    end

    if self.scroll then
        self.scroll:SetVerticalScroll(0)
        if self.scroll.UpdateScrollChildRect then
            self.scroll:UpdateScrollChildRect()
        end
    end

    -- FluxUI Ace options: grow the widget with row count (no inner scroll frame).
    if self.embedAceWidget and self.embedDirectContent and content == self.embedDirectContent then
        local parent = self.embedAceWidget.frame
        if parent then
            local topInset = GetScrollTopInset(parent)
            local chromeTop = math.abs(topInset)
            local ch = content:GetHeight() or 40
            local totalH = chromeTop + ch + 10
            pcall(function()
                self.embedAceWidget:SetHeight(totalH)
            end)
        end
    end

    if standaloneMode and self.floatingFrame and self.content then
        SizeStandaloneFrameToContent(self.floatingFrame, self.content)
        local anchor = self.standaloneAnchorButton
        local fr = self.floatingFrame
        if anchor and fr and fr:IsShown() and UI.standaloneAnchorButton == anchor then
            pcall(ClampStandaloneFrameAfterLayout, fr, anchor)
        end
    end

    C_Timer.After(0, function()
        HideEditorTooltip()
    end)
end

if not StaticPopupDialogs["FLUXUI_MICROMENU_RESET_ALL"] then
    StaticPopupDialogs["FLUXUI_MICROMENU_RESET_ALL"] = {
        text = "Reset MicroMenu to factory defaults?\n\n|cffccccccOrder:|r default natives + minimap scan + discovered extras.\n|cffccccccNative buttons:|r Account.\n|cffccccccMinimap icons:|r Off.|r",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            if FluxMicroMenuConfig and FluxMicroMenuConfig.ResetMicroMenuToFactoryDefaults then
                FluxMicroMenuConfig:ResetMicroMenuToFactoryDefaults()
            end
            if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.RefreshRows then
                FluxMicroMenuConfigUI:RefreshRows()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end
