-- Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua
-- AceGUI key cell widget + "FluxKeys" layout (ported from Clicked).

local addonName, ns = ...

local Type, Version = "FluxKeyVisualizerButton", 10
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
    return
end

local MAX_VIZ_BADGES = (_G.FluxBindingMaxCornerBadges) or 3
local BASE_GRID_SIZE = 34
local PADDING_SIZE = 2
local MOUSE_GAP_UNITS = 0.35

--- Same hotkey glyphs as Flux action-bar binding labels.
local TEX = "Interface\\AddOns\\_FluxUI\\Texture\\"
local HOTKEY_GLYPH = {
    SPACE = TEX .. "SpaceBarButton.tga",
    BUTTON3 = TEX .. "MouseButton3.tga",
    BUTTON4 = TEX .. "MouseButton4.tga",
    BUTTON5 = TEX .. "MouseButton5.tga",
    MOUSEWHEELUP = TEX .. "MouseScrollUp.tga",
    MOUSEWHEELDOWN = TEX .. "MouseScrollDown.tga",
}

local isRetail = ns.IsRetail or (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local hasSliceMode = Enum and Enum.UITextureSliceMode and Enum.UITextureSliceMode.Tiled

local function CurrentGridSize()
    local g = tonumber(ns.FluxKeyVisualizerGridSize)
    if g and g >= 16 and g <= 64 then
        return g
    end
    return BASE_GRID_SIZE
end

local function LayoutKeyGroup(content, children, originRelX, originRelY, keysMap)
    local GRID_SIZE = CurrentGridSize()
    local totalWidth = 0
    local totalHeight = 0
    local last = {
        relX = originRelX or 0,
        relY = originRelY or 0,
        relW = 0,
        relH = 0,
    }

    for i = 1, #children do
        local child = children[i]
        local frame = child.frame
        frame:ClearAllPoints()

        local key = child:GetKey()
        if key ~= nil then
            local anchor = key.relativeTo and keysMap[key.relativeTo] or last

            local relX = key.x
            if relX == nil then
                relX = anchor.relX + anchor.relW + (key.xOffset or 0)
            else
                relX = relX + (originRelX or 0)
            end
            local relY = key.y
            if relY == nil then
                relY = anchor.relY + (key.yOffset or 0)
            else
                relY = relY + (originRelY or 0)
            end
            local relW = key.width or 1
            local relH = key.height or 1

            local padX = relX * PADDING_SIZE
            local padY = relY * PADDING_SIZE
            local padW = (relW - 1) * PADDING_SIZE
            local padH = (relH - 1) * PADDING_SIZE

            local x = Round(relX * GRID_SIZE + padX)
            local y = Round(relY * GRID_SIZE + padY)
            local w = Round(relW * GRID_SIZE + padW)
            local h = Round(relH * GRID_SIZE + padH)

            last = {
                frame = frame,
                relX = relX,
                relY = relY,
                relW = relW,
                relH = relH,
            }
            keysMap[key:GetId()] = last

            child:SetWidth(w)
            child:SetHeight(h)
            frame:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)

            if child:IsVisible() then
                totalWidth = math.max(totalWidth, x + w)
                totalHeight = math.max(totalHeight, y + h)
                frame:Show()
            else
                frame:Hide()
            end
        end
    end

    return totalWidth, totalHeight
end

AceGUI:RegisterLayout("FluxKeys", function(content, children)
    local GRID_SIZE = CurrentGridSize()
    local kbChildren = {}
    local mouseChildren = {}

    for i = 1, #children do
        local child = children[i]
        local key = child:GetKey()
        if key and key.mousePanel then
            mouseChildren[#mouseChildren + 1] = child
        else
            kbChildren[#kbChildren + 1] = child
        end
    end

    local keysMap = {}
    local kbW, kbH = LayoutKeyGroup(content, kbChildren, 0, 0, keysMap)

    local mouseOriginX = 0
    if #mouseChildren > 0 then
        local unit = GRID_SIZE + PADDING_SIZE
        mouseOriginX = (kbW > 0 and (kbW / unit) or 0) + MOUSE_GAP_UNITS
    end

    local mW, mH = 0, 0
    if #mouseChildren > 0 then
        mW, mH = LayoutKeyGroup(content, mouseChildren, mouseOriginX, 0.2, keysMap)
    end

    local totalWidth = math.max(kbW, mW)
    local totalHeight = math.max(kbH, mH)

    local obj = content.obj
    if obj and obj.LayoutFinished then
        obj:LayoutFinished(totalWidth, totalHeight)
    end
end)

local function Control_OnEnter(frame)
    frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
    frame.obj:Fire("OnLeave")
end

local Methods = {}

function Methods:OnAcquire()
    self:SetKey()
    self:SetIcon()
    self:SetDesaturated(false)
    self:SetBadges(nil)
    self:SetVisible(true)
    self:SetHighlight(false)
    self:SetActionCount(0)
end

function Methods:SetKey(key)
    self.key = key
    local id = key and key:GetId()
    local glyph = id and HOTKEY_GLYPH[id]
    local abbr = key ~= nil and key:GetAbbreviation() or nil
    if glyph and id == "SPACE" then
        self.keyName:SetText("|T" .. glyph .. ":14:14:0:0|t " .. (abbr or "SPACE"))
    elseif glyph then
        self.keyName:SetText("|T" .. glyph .. ":14:14:0:0|t")
    else
        self.keyName:SetText(abbr)
    end
    if self.keyName then
        self.keyName:ClearAllPoints()
        self.keyName:SetPoint("TOPRIGHT", -3, -2)
        self.keyName:SetJustifyH("RIGHT")
    end
    self.frame:SetAlpha(key ~= nil and (key.disabled and 0.5 or 1) or 1)
    self:FitActionIcon()
end

function Methods:FitActionIcon()
    if not self.image then return end
    local gs = CurrentGridSize()
    local w = self.frame:GetWidth() or gs
    local h = self.frame:GetHeight() or gs
    local s = math.min(w, h) - 6
    local maxIcon = math.max(12, gs - 6)
    s = math.max(10, math.min(s, maxIcon))
    self.image:SetSize(s, s * 0.98)
    if self.backgroundMask then
        local ms = s + 10
        self.backgroundMask:SetSize(ms, ms + 1)
    end
end

function Methods:SetActionCount(count)
    if count and count > 1 then
        self.extraActionCount:SetText("+" .. (count - 1))
        self.extraActionCount:Show()
    else
        self.extraActionCount:Hide()
    end
end

function Methods:SetIcon(icon)
    self.image:SetTexture(icon)
    if not icon and self.image.SetDesaturated then
        self.image:SetDesaturated(false)
    end
end

function Methods:SetDesaturated(desaturated)
    if self.image and self.image.SetDesaturated then
        self.image:SetDesaturated(desaturated and true or false)
    end
end

--- Corner badges (TOPLEFT stack), mirroring Flux action-bar badges.
--- list entries: { icon = texture|id, alpha = number?, desaturated = bool? }
function Methods:SetBadges(list)
    if not self.badgeTex then
        self.badgeTex = {}
    end
    for i = 1, MAX_VIZ_BADGES do
        local t = self.badgeTex[i]
        if t then
            t:Hide()
        end
    end
    if type(list) ~= "table" or #list == 0 then
        return
    end
    local fw = self.frame:GetWidth() or CurrentGridSize()
    local fh = self.frame:GetHeight() or fw
    local stack = MAX_VIZ_BADGES
    if stack < 1 then
        stack = 1
    end
    local size = math.max(7, math.min(fw, fh) / stack)
    local n = math.min(MAX_VIZ_BADGES, #list)
    for i = 1, n do
        local e = list[i]
        if e and e.icon then
            local t = self.badgeTex[i]
            if not t then
                t = self.frame:CreateTexture(nil, "OVERLAY", nil, 7)
                self.badgeTex[i] = t
            end
            t:ClearAllPoints()
            t:SetSize(size, size)
            t:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -(i - 1) * size)
            t:SetTexture(e.icon)
            t:SetAlpha(tonumber(e.alpha) or 0.75)
            if t.SetDesaturated then
                t:SetDesaturated(e.desaturated and true or false)
            end
            t:Show()
        end
    end
end

function Methods:SetVisible(visible)
    self.visible = visible and true or false
    if self.visible then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

function Methods:SetHighlight(highlight)
    self.highlight = highlight and true or false
    if self.highlight then
        self.background:SetVertexColor(0, 1, 0, 1)
    else
        self.background:SetVertexColor(1, 1, 1, 1)
    end
end

function Methods:GetKey()
    return self.key
end

function Methods:IsVisible()
    return self.visible
end

function Methods:IsHighlighted()
    return self.highlight
end

function Methods:OnWidthSet(width)
    self:FitActionIcon()
    if self.keyName then
        self.keyName:ClearAllPoints()
        self.keyName:SetPoint("TOPRIGHT", -3, -2)
        self.keyName:SetJustifyH("RIGHT")
    end
end

function Methods:OnHeightSet(height)
    self:FitActionIcon()
    if self._lastBadges then
        self:SetBadges(self._lastBadges)
    end
end

local function Constructor()
    local name = "FluxKeyVisualizerButton" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", Control_OnEnter)
    frame:SetScript("OnLeave", Control_OnLeave)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()

    if isRetail then
        background:SetTexture("Interface/HUD/UIActionBar")
        background:SetTexCoord(0.707031, 0.886719, 0.248047, 0.291992)
        if background.SetTextureSliceMargins then
            background:SetTextureSliceMargins(8, 8, 8, 8)
        end
        if hasSliceMode and background.SetTextureSliceMode then
            background:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
        end
    else
        background:SetTexture("Interface/Buttons/ui-quickslot2")
        background:SetTexCoord(0.2, 0.8, 0.2, 0.8)
        if background.SetTextureSliceMargins then
            background:SetTextureSliceMargins(20, 20, 20, 20)
        end
        if hasSliceMode and background.SetTextureSliceMode then
            background:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
        end
    end

    local image = frame:CreateTexture(nil, "ARTWORK")
    image:SetPoint("CENTER")
    image:SetSize(29, 28)

    local backgroundMask
    if isRetail then
        backgroundMask = frame:CreateMaskTexture(nil, "BACKGROUND")
        backgroundMask:SetPoint("CENTER", 0, -0.5)
        backgroundMask:SetTexture("Interface/HUD/UIActionBarIconFrameMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        backgroundMask:SetTexCoord(0, 1, 0, 1)
        backgroundMask:SetSize(44, 45)
        image:AddMaskTexture(backgroundMask)
    end

    local keyName = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    keyName:ClearAllPoints()
    keyName:SetPoint("TOPRIGHT", -3, -2)
    keyName:SetJustifyH("RIGHT")
    keyName:SetHeight(9)

    local extraActionCount = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    extraActionCount:ClearAllPoints()
    extraActionCount:SetPoint("BOTTOMRIGHT", -2, 3)
    extraActionCount:SetHeight(9)
    extraActionCount:SetJustifyH("RIGHT")

    local widget = {
        type = Type,
        background = background,
        backgroundMask = backgroundMask,
        keyName = keyName,
        extraActionCount = extraActionCount,
        image = image,
        frame = frame,
    }

    for method, func in pairs(Methods) do
        widget[method] = func
    end

    -- Preserve badges across SetBadges for OnHeightSet refresh.
    local origSetBadges = widget.SetBadges
    function widget:SetBadges(list)
        self._lastBadges = list
        return origSetBadges(self, list)
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
