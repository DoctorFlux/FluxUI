-- AceGUI widget: embeds Binding browser into FluxUI Options → Binding tab.
-- Custom /fluxui window: fill the pane. Blizzard Settings: fixed content height
-- so AceConfig's ScrollFrame can scroll when the canvas is shorter.

local Type, Version = "FluxBindingBrowserEmbed", 8
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local MIN_W, MIN_H = 280, 200
-- Binding split-pane content height in Blizzard AddOns → FluxUI.
-- Must exceed the Settings canvas so AceConfig's ScrollFrame shows a scrollbar.
local BLIZ_CONTENT_H = 560
local FRAME_CHROME_H = 100
local FRAME_CHROME_W = 28

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

local function ValidExtents(w, h)
    return (w or 0) > 40 and (h or 0) > 40
end

local function TryListWheel(delta)
    if _G.FluxBindingBrowser_TryListMouseWheel then
        return _G.FluxBindingBrowser_TryListMouseWheel(delta)
    end
    return false
end

local function TryTabWheel(delta)
    if _G.FluxBindingBrowser_TryTabMouseWheel then
        return _G.FluxBindingBrowser_TryTabMouseWheel(delta)
    end
    return false
end

--- Set widget height without calling SetHeight (avoids OnHeightSet recursion).
local function ApplyWidgetHeight(widget, h)
    if not widget or not widget.frame or widget._fluxBindApplyingHeight then
        return
    end
    widget._fluxBindApplyingHeight = true
    widget.height = h
    widget.frame.height = h
    widget.frame:SetHeight(h)
    widget._fluxBindApplyingHeight = false
end

--- Width/height available to the Binding embed.
--- Returns: width, height, hostKind ("bliz"|"flux"|"fallback"), fillHeight (bool)
local function MeasureHost(widgetFrame)
    local bliz = FindAncestorWidget(widgetFrame, "BlizOptionsGroup")
    if bliz then
        local w = 0
        local scroll = FindAncestorWidget(widgetFrame, "ScrollFrame")
        if scroll and scroll.scrollframe then
            w = scroll.scrollframe:GetWidth() or 0
            if w > 40 then
                w = w - 22
            end
        end
        if w <= 40 and bliz.content then
            w = (bliz.content:GetWidth() or 0) - 8
        end
        if w <= 40 and bliz.frame then
            w = (bliz.frame:GetWidth() or 0) - 40
        end
        if w < MIN_W then w = MIN_W end
        return w, BLIZ_CONTENT_H, "bliz", false
    end

    local scroll = FindAncestorWidget(widgetFrame, "ScrollFrame")
    if scroll and scroll.scrollframe then
        local sf = scroll.scrollframe
        local w = sf:GetWidth() or 0
        local h = sf:GetHeight() or 0
        if ValidExtents(w, h) then
            return w, math.max(MIN_H, h - 4), "flux", true
        end
    end

    local tab = FindAncestorWidget(widgetFrame, "TabGroup")
    if tab and tab.content then
        local c = tab.content
        local w = c:GetWidth() or 0
        local h = c:GetHeight() or 0
        if ValidExtents(w, h) then
            return w, math.max(MIN_H, h - 4), "flux", true
        end
    end

    local cfg = _G.FluxUIConfigFrame
    if cfg and cfg.GetWidth and widgetFrame then
        local f = widgetFrame
        while f do
            if f == cfg then
                local w = (cfg:GetWidth() or 720) - FRAME_CHROME_W
                local h = (cfg:GetHeight() or 580) - FRAME_CHROME_H
                return math.max(MIN_W, w), math.max(MIN_H, h), "flux", true
            end
            f = f:GetParent()
        end
    end

    return MIN_W, BLIZ_CONTENT_H, "fallback", false
end

local function ScheduleSync(widget)
    if not widget or widget._fluxReleased or widget._fluxBindSyncPending then
        return
    end
    widget._fluxBindSyncPending = true
    local function run()
        widget._fluxBindSyncPending = false
        if widget and not widget._fluxReleased then
            widget:_FluxSyncEmbed()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

local function RelayoutAceScrollParent(widget)
    local scroll = FindAncestorWidget(widget.frame, "ScrollFrame")
    if not scroll then
        return
    end
    -- Force Ace scroll content height from our frame height so the scrollbar
    -- range reaches the bottom of the Binding pane.
    local h = widget.frame.height or widget.frame:GetHeight() or 0
    if h > 40 and scroll.content then
        scroll.content:SetHeight(h + 8)
        if scroll.FixScroll then
            scroll:FixScroll()
        end
    end
end

local function SyncEmbedToWindow(widget)
    if not widget or widget._fluxReleased or not widget.frame or not widget.frame:IsShown() then
        return
    end
    if widget.frame.IsVisible and not widget.frame:IsVisible() then
        return
    end

    local hostW, hostH, kind, fillHeight = MeasureHost(widget.frame)
    hostW = math.floor((hostW or 0) + 0.5)
    hostH = math.floor((hostH or 0) + 0.5)
    if hostW < MIN_W then hostW = MIN_W end
    if hostH < MIN_H then hostH = MIN_H end

    widget._fluxBindBlizzard = (kind == "bliz")

    if widget.SetFullWidth then
        widget:SetFullWidth(true)
    end
    widget.width = "fill"

    if widget._fluxBindLastH == hostH and widget._fluxBindLastW == hostW and widget._fluxBindLastKind == kind then
        RelayoutAceScrollParent(widget)
        return
    end
    widget._fluxBindLastH = hostH
    widget._fluxBindLastW = hostW
    widget._fluxBindLastKind = kind

    ApplyWidgetHeight(widget, hostH)

    local curW = widget.frame:GetWidth() or 0
    if kind == "bliz" or curW < 40 or math.abs(curW - hostW) > 4 then
        widget.frame:SetWidth(hostW)
        widget.frame.width = hostW
    end

    RelayoutAceScrollParent(widget)

    if _G.FluxBindingBrowser_OnHostResized then
        local fw = widget.frame:GetWidth() or hostW
        pcall(_G.FluxBindingBrowser_OnHostResized, fw, hostH, {
            blizzard = (kind == "bliz"),
            fillHeight = fillHeight and true or false,
        })
    end
end

local function HookFrameResize(frame, flagKey)
    if not frame or frame[flagKey] then
        return
    end
    frame[flagKey] = true
    frame:HookScript("OnSizeChanged", function()
        local w = _G.FluxBindingBrowserEmbedActive
        if w and not w._fluxReleased and w.frame and w.frame:IsShown() then
            ScheduleSync(w)
        end
    end)
end

--- Prefer catalog list scroll when the cursor is over it and the list can move;
--- otherwise let Ace's outer ScrollFrame scroll the Binding tab.
local function HookAceOuterMouseWheel(widget)
    local scroll = FindAncestorWidget(widget.frame, "ScrollFrame")
    if not scroll or not scroll.scrollframe or scroll._fluxBindWheelHooked then
        return
    end
    scroll._fluxBindWheelHooked = true
    local sf = scroll.scrollframe
    local prev = sf:GetScript("OnMouseWheel")
    sf:SetScript("OnMouseWheel", function(self, delta)
        local active = _G.FluxBindingBrowserEmbedActive
        if active and not active._fluxReleased and active.frame and active.frame:IsShown() then
            -- Editor tabs first (so Ace outer does not yank content the wrong way),
            -- then catalog list, then Ace outer.
            if TryTabWheel(delta) then
                return
            end
            if TryListWheel(delta) then
                return
            end
        end
        if prev then
            return prev(self, delta)
        end
    end)
end

local function HookHostResizes(widget)
    if not widget or not widget.frame then
        return
    end

    HookFrameResize(_G.FluxUIConfigFrame, "_fluxBindResizeHooked")

    local bliz = FindAncestorWidget(widget.frame, "BlizOptionsGroup")
    if bliz and bliz.frame then
        HookFrameResize(bliz.frame, "_fluxBindBlizResizeHooked")
    end

    local tab = FindAncestorWidget(widget.frame, "TabGroup")
    if tab and tab.frame then
        HookFrameResize(tab.frame, "_fluxBindTabResizeHooked")
    end

    local scroll = FindAncestorWidget(widget.frame, "ScrollFrame")
    if scroll and scroll.frame then
        HookFrameResize(scroll.frame, "_fluxBindScrollResizeHooked")
    end

    HookAceOuterMouseWheel(widget)
end

local methods = {
    ["_FluxSyncEmbed"] = function(self)
        SyncEmbedToWindow(self)
        HookHostResizes(self)
    end,

    ["OnAcquire"] = function(self)
        self._fluxReleased = false
        self._fluxBindSyncPending = false
        self._fluxBindApplyingHeight = false
        self._fluxBindLastH = nil
        self._fluxBindLastW = nil
        self._fluxBindLastKind = nil
        self._fluxBindBlizzard = false
        _G.FluxBindingBrowserEmbedActive = self
        self:SetFullWidth(true)
        self.width = "fill"
        ApplyWidgetHeight(self, BLIZ_CONTENT_H)

        if _G.FluxBindingBrowser_Attach then
            _G.FluxBindingBrowser_Attach(self)
        end

        ScheduleSync(self)
        if C_Timer and C_Timer.After then
            C_Timer.After(0.05, function()
                if self._fluxReleased or not self.frame or not self.frame:IsShown() then
                    return
                end
                if self.frame.IsVisible and not self.frame:IsVisible() then
                    return
                end
                SyncEmbedToWindow(self)
                HookHostResizes(self)
            end)
        end
    end,

    ["OnRelease"] = function(self)
        self._fluxReleased = true
        self._fluxBindSyncPending = false
        if _G.FluxBindingBrowserEmbedActive == self then
            _G.FluxBindingBrowserEmbedActive = nil
        end
        if _G.FluxBindingBrowser_Detach then
            _G.FluxBindingBrowser_Detach(self)
        end
    end,

    ["OnWidthSet"] = function(self, width)
        if self._fluxReleased or not self.frame or not width or width <= 0 then
            return
        end
        self.frame:SetWidth(width)
        ScheduleSync(self)
    end,

    ["OnHeightSet"] = function(self, height)
        -- Never call self:SetHeight here — AceGUI SetHeight → OnHeightSet loops.
        if self._fluxReleased or not self.frame or self._fluxBindApplyingHeight then
            return
        end
        if self._fluxBindBlizzard then
            ApplyWidgetHeight(self, BLIZ_CONTENT_H)
            RelayoutAceScrollParent(self)
            if _G.FluxBindingBrowser_OnHostResized then
                local w = self.frame:GetWidth() or 0
                pcall(_G.FluxBindingBrowser_OnHostResized, w, BLIZ_CONTENT_H, { blizzard = true })
            end
            return
        end
        if height and height > 0 then
            self.frame:SetHeight(height)
            if _G.FluxBindingBrowser_OnHostResized then
                local w = self.frame:GetWidth() or 0
                pcall(_G.FluxBindingBrowser_OnHostResized, w, height, { blizzard = false })
            end
        end
    end,

    ["SetText"] = function(self, text)
        self._aceTitle = text
    end,

    ["SetFontObject"] = function() end,
    ["SetImage"] = function() end,
    ["SetImageSize"] = function() end,
}

local function Constructor()
    local name = "AceGUI30FluxBindingBrowserEmbed" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:EnableMouse(true)
    frame:EnableMouseWheel(false)
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
