-- AceGUI widgets for FluxUI Options → Battlezone:
--   FluxBattlezoneTabStrip  — drag to reorder Flux window tabs, click to toggle
--   FluxMeterLayoutEmbed    — hosts the full meter layout editor

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI then return end

local DRAG_THRESHOLD_SQ = 64
local CHIP_H = 32
local CHIP_PAD = 6
local STRIP_H = 52

local TAB_LABELS = {
    Map = "Map",
    Meter = "Meter",
    Respec = "Respec",
    Buttons = "Buttons",
}

local TAB_ICONS = {
    Map = "Interface\\Icons\\INV_Misc_Map02",
    Meter = "Interface\\Icons\\Ability_DualWield",
    Respec = "Interface\\Icons\\INV_Misc_Book_09",
    Buttons = "Interface\\Icons\\INV_Misc_Gear_01",
}

---------------------------------------------------------------------------
-- Ghost chip for drag
---------------------------------------------------------------------------
local tabGhost
local function EnsureTabGhost()
    if tabGhost then return tabGhost end
    tabGhost = CreateFrame("Frame", "FluxBattlezoneTabGhost", UIParent, "BackdropTemplate")
    tabGhost:SetSize(96, CHIP_H)
    tabGhost:SetFrameStrata("TOOLTIP")
    tabGhost:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    tabGhost:SetBackdropColor(0.22, 0.2, 0.14, 0.95)
    tabGhost:SetBackdropBorderColor(0.95, 0.78, 0.25, 1)
    tabGhost.icon = tabGhost:CreateTexture(nil, "ARTWORK")
    tabGhost.icon:SetSize(18, 18)
    tabGhost.icon:SetPoint("LEFT", 8, 0)
    tabGhost.label = tabGhost:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tabGhost.label:SetPoint("LEFT", tabGhost.icon, "RIGHT", 6, 0)
    tabGhost.label:SetPoint("RIGHT", -8, 0)
    tabGhost.label:SetJustifyH("LEFT")
    tabGhost:Hide()
    return tabGhost
end

local function PlaceGhostAtCursor()
    if not tabGhost then return end
    local scale = UIParent:GetEffectiveScale() or 1
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    tabGhost:ClearAllPoints()
    tabGhost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
end

---------------------------------------------------------------------------
-- FluxBattlezoneTabStrip
---------------------------------------------------------------------------
local TabType, TabVersion = "FluxBattlezoneTabStrip", 1
if (AceGUI:GetWidgetVersion(TabType) or 0) < TabVersion then

local function WindowReady()
    return FluxWindowFrame
        and FluxWindowFrame.GetTabOrder
        and FluxWindowFrame.SetTabOrder
        and FluxWindowFrame.IsTabEnabled
        and FluxWindowFrame.SetTabEnabled
end

local function RefreshTabStrip(widget)
    if not widget or not widget.frame then return end
    local strip = widget.strip
    if not strip then return end

    strip.chips = strip.chips or {}
    for _, chip in ipairs(strip.chips) do
        chip:Hide()
    end

    if not WindowReady() then
        widget.hint:SetText("Flux window not ready yet — reopen options after login.")
        widget.hint:Show()
        return
    end
    widget.hint:SetText("Drag to reorder · click to turn on/off")
    widget.hint:Show()

    local order = FluxWindowFrame:GetTabOrder()
    local x = 0
    for i, name in ipairs(order) do
        local chip = strip.chips[i]
        if not chip then
            chip = CreateFrame("Button", nil, strip, "BackdropTemplate")
            chip:SetHeight(CHIP_H)
            chip:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            chip.icon = chip:CreateTexture(nil, "ARTWORK")
            chip.icon:SetSize(18, 18)
            chip.icon:SetPoint("LEFT", 8, 0)
            chip.label = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            chip.label:SetPoint("LEFT", chip.icon, "RIGHT", 6, 0)
            chip.label:SetJustifyH("LEFT")
            chip:RegisterForClicks("LeftButtonUp")
            chip:EnableMouse(true)

            chip:SetScript("OnEnter", function(self)
                if widget._dragging then return end
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(self._tabName or "Tab")
                local on = FluxWindowFrame and FluxWindowFrame:IsTabEnabled(self._tabName)
                GameTooltip:AddLine(on and "On — click to disable" or "Off — click to enable", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("Drag to reorder", 0.65, 0.65, 0.65)
                GameTooltip:Show()
            end)
            chip:SetScript("OnLeave", GameTooltip_Hide)

            chip:SetScript("OnMouseDown", function(self, button)
                if button ~= "LeftButton" or not WindowReady() then return end
                local cx, cy = GetCursorPosition()
                widget._pending = {
                    name = self._tabName,
                    fromIdx = self._index,
                    startCX = cx,
                    startCY = cy,
                    dragActive = false,
                    label = self.label:GetText(),
                    icon = TAB_ICONS[self._tabName],
                }
                widget.frame:SetScript("OnUpdate", function()
                    local p = widget._pending
                    if not p then
                        widget.frame:SetScript("OnUpdate", nil)
                        return
                    end
                    if not IsMouseButtonDown("LeftButton") then
                        widget.frame:SetScript("OnUpdate", nil)
                        local pending = widget._pending
                        widget._pending = nil
                        widget._dragging = false
                        if tabGhost then tabGhost:Hide() end

                        if pending.dragActive then
                            local liveOrder = FluxWindowFrame:GetTabOrder()
                            local dropIdx = #liveOrder
                            local mx = GetCursorPosition() / (strip:GetEffectiveScale() or 1)
                            for j, c in ipairs(strip.chips) do
                                if c:IsShown() and c._tabName then
                                    local left, width = c:GetLeft(), c:GetWidth()
                                    if left and width and mx < left + width * 0.5 then
                                        dropIdx = j
                                        break
                                    end
                                end
                            end
                            if pending.fromIdx < dropIdx then
                                dropIdx = dropIdx - 1
                            end
                            dropIdx = math.max(1, math.min(#liveOrder, dropIdx))
                            if dropIdx ~= pending.fromIdx then
                                local newOrder = {}
                                for _, n in ipairs(liveOrder) do
                                    if n ~= pending.name then
                                        newOrder[#newOrder + 1] = n
                                    end
                                end
                                table.insert(newOrder, dropIdx, pending.name)
                                FluxWindowFrame:SetTabOrder(newOrder)
                            end
                            RefreshTabStrip(widget)
                        else
                            -- Click toggle
                            local on = FluxWindowFrame:IsTabEnabled(pending.name)
                            if not FluxWindowFrame:SetTabEnabled(pending.name, not on) and on then
                                print("|cffFFD100FluxUI:|r Keep at least one Flux window tab enabled.")
                            end
                            RefreshTabStrip(widget)
                        end
                        return
                    end

                    local cx2, cy2 = GetCursorPosition()
                    local dx, dy = cx2 - p.startCX, cy2 - p.startCY
                    if not p.dragActive and (dx * dx + dy * dy) >= DRAG_THRESHOLD_SQ then
                        p.dragActive = true
                        widget._dragging = true
                        local g = EnsureTabGhost()
                        g.icon:SetTexture(p.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                        g.label:SetText(p.label or p.name)
                        local tw = (g.label:GetStringWidth() or 40) + 40
                        g:SetWidth(math.max(72, tw))
                        PlaceGhostAtCursor()
                        g:Show()
                        g:Raise()
                        GameTooltip:Hide()
                    end
                    if p.dragActive then
                        PlaceGhostAtCursor()
                    end
                end)
            end)

            strip.chips[i] = chip
        end

        local enabled = FluxWindowFrame:IsTabEnabled(name)
        local exists = FluxWindowFrame.GetTabContent and FluxWindowFrame:GetTabContent(name) ~= nil
        local label = TAB_LABELS[name] or name
        chip._tabName = name
        chip._index = i
        chip.icon:SetTexture(TAB_ICONS[name] or "Interface\\Icons\\INV_Misc_QuestionMark")
        chip.label:SetText(label)
        local textW = chip.label:GetStringWidth() or 40
        chip:SetWidth(math.max(72, textW + 40))
        chip:ClearAllPoints()
        chip:SetPoint("LEFT", strip, "LEFT", x, 0)
        x = x + chip:GetWidth() + CHIP_PAD

        if enabled then
            chip:SetBackdropColor(0.28, 0.24, 0.14, 1)
            chip:SetBackdropBorderColor(0.95, 0.78, 0.25, 1)
            chip.label:SetTextColor(1, 0.92, 0.7)
            chip.icon:SetDesaturated(false)
            chip:SetAlpha(exists and 1 or 0.55)
        else
            chip:SetBackdropColor(0.12, 0.12, 0.14, 1)
            chip:SetBackdropBorderColor(0.35, 0.35, 0.38, 1)
            chip.label:SetTextColor(0.55, 0.55, 0.55)
            chip.icon:SetDesaturated(true)
            chip:SetAlpha(0.7)
        end
        chip:EnableMouse(exists)
        chip:Show()
    end
end

local tabMethods = {
    OnAcquire = function(self)
        self.width = "fill"
        self:SetHeight(STRIP_H + 18)
        pcall(function() self:SetFullWidth(true) end)
        RefreshTabStrip(self)
        if not WindowReady() then
            C_Timer.After(1, function()
                if self.frame and self.frame:IsShown() then
                    RefreshTabStrip(self)
                end
            end)
        end
    end,
    OnRelease = function(self)
        self._pending = nil
        self._dragging = false
        self.frame:SetScript("OnUpdate", nil)
        if tabGhost then tabGhost:Hide() end
    end,
    SetText = function() end,
    SetLabel = function() end,
    OnWidthSet = function(self)
        RefreshTabStrip(self)
    end,
}

local function TabConstructor()
    local name = "AceGUI30FluxBattlezoneTabStrip" .. AceGUI:GetNextWidgetNum(TabType)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:Hide()

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 0, 0)
    hint:SetPoint("TOPRIGHT", 0, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText("Drag to reorder · click to turn on/off")

    local strip = CreateFrame("Frame", nil, frame)
    strip:SetPoint("TOPLEFT", 0, -16)
    strip:SetPoint("TOPRIGHT", 0, -16)
    strip:SetHeight(CHIP_H + 8)

    local widget = {
        frame = frame,
        strip = strip,
        hint = hint,
        type = TabType,
    }
    for method, func in pairs(tabMethods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(TabType, TabConstructor, TabVersion)
end

---------------------------------------------------------------------------
-- FluxMeterLayoutEmbed
---------------------------------------------------------------------------
local EmbedType, EmbedVersion = "FluxMeterLayoutEmbed", 4
if (AceGUI:GetWidgetVersion(EmbedType) or 0) < EmbedVersion then

local FRAME_CHROME_W = 36

local function FindAncestorWidget(frame, typeName)
    local f = frame
    while f do
        local obj = f.obj
        if obj and obj.type == typeName then
            return obj
        end
        f = f:GetParent()
    end
    return nil
end

local function MeasureEmbedWidth(widgetFrame)
    local tab = FindAncestorWidget(widgetFrame, "TabGroup")
    if tab and tab.content then
        local w = tab.content:GetWidth() or 0
        if w > 40 then return w - 8 end
    end
    local scroll = FindAncestorWidget(widgetFrame, "ScrollFrame")
    if scroll and scroll.content then
        local parent = scroll.content:GetParent()
        if parent then
            local w = parent:GetWidth() or 0
            if w > 40 then return w - 8 end
        end
    end
    local cfg = _G.FluxUIConfigFrame
    if cfg and cfg.GetWidth then
        return math.max(320, (cfg:GetWidth() or 720) - FRAME_CHROME_W)
    end
    return 700
end

local function HasMeterLayoutBackend()
    if FluxMeterLayout and FluxMeterLayout.HasMeterBackend then
        return FluxMeterLayout.HasMeterBackend()
    end
    local detailsLoaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        detailsLoaded = C_AddOns.IsAddOnLoaded("Details")
    elseif IsAddOnLoaded then
        detailsLoaded = IsAddOnLoaded("Details")
    else
        detailsLoaded = _G.Details ~= nil
    end
    if detailsLoaded then return true end
    if FluxMeterLayout and FluxMeterLayout.HasBlizzardDamageMeterClient
        and FluxMeterLayout.HasBlizzardDamageMeterClient() then
        return true
    end
    return false
end

local function SyncMeterEmbed(widget)
    if not widget or widget._fluxReleased or not widget.frame then return end
    if not (FluxMeterLayout and FluxMeterLayout.AttachToHost) then return end

    if not HasMeterLayoutBackend() then
        widget:SetHeight(1)
        if FluxMeterLayout.DetachFromAceWidget then
            FluxMeterLayout.DetachFromAceWidget(widget)
        end
        return
    end

    local editor = FluxMeterLayout.AttachToHost(widget.frame)
    if not editor then return end

    local availW = MeasureEmbedWidth(widget.frame)
    local usedW, usedH = FluxMeterLayout.FitEditorToHost(widget.frame, availW, nil)
    if widget.SetFullWidth then
        pcall(widget.SetFullWidth, widget, true)
    end
    widget.width = "fill"
    if usedH and usedH > 40 then
        widget:SetHeight(usedH)
        widget.frame:SetHeight(usedH)
    end
    if usedW and usedW > 40 then
        widget.frame:SetWidth(usedW)
    end
end

local function HookOptionsWindowResize(widget)
    local cfg = _G.FluxUIConfigFrame
    if not cfg then return end
    if not cfg._fluxMeterLayoutResizeHooked then
        cfg._fluxMeterLayoutResizeHooked = true
        cfg:HookScript("OnSizeChanged", function()
            local w = _G.FluxMeterLayoutEmbedActive
            if w and not w._fluxReleased and w.frame and w.frame:IsShown() then
                C_Timer.After(0, function()
                    if w and not w._fluxReleased then
                        SyncMeterEmbed(w)
                    end
                end)
            end
        end)
    end
end

local embedMethods = {
    OnAcquire = function(self)
        self._fluxReleased = false
        _G.FluxMeterLayoutEmbedActive = self
        self.width = "fill"
        pcall(function() self:SetFullWidth(true) end)
        HookOptionsWindowResize(self)
        SyncMeterEmbed(self)
        -- Layout may not have width yet on first open.
        C_Timer.After(0, function()
            if self and not self._fluxReleased then
                SyncMeterEmbed(self)
            end
        end)
    end,
    OnRelease = function(self)
        self._fluxReleased = true
        if _G.FluxMeterLayoutEmbedActive == self then
            _G.FluxMeterLayoutEmbedActive = nil
        end
        if FluxMeterLayout and FluxMeterLayout.DetachFromAceWidget then
            FluxMeterLayout.DetachFromAceWidget(self)
        end
    end,
    SetText = function() end,
    SetLabel = function() end,
    OnWidthSet = function(self)
        if self._fluxReleased then return end
        C_Timer.After(0, function()
            if self and not self._fluxReleased then
                SyncMeterEmbed(self)
            end
        end)
    end,
}

local function EmbedConstructor()
    local name = "AceGUI30FluxMeterLayoutEmbed" .. AceGUI:GetNextWidgetNum(EmbedType)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:EnableMouse(true)
    frame:Hide()

    local widget = {
        frame = frame,
        type = EmbedType,
    }
    for method, func in pairs(embedMethods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(EmbedType, EmbedConstructor, EmbedVersion)
end
