-- FluxAddonMicroButton.lua
if not FluxMicroMenu or not FluxMicroMenu.CreateMicroButton then return end

-- ---------------------------------------------------------------------------
-- Constants & Config
-- ---------------------------------------------------------------------------
local BUTTON_SIZE = 32
local BUTTON_SPACING = 2
local PADDING = 6
local BUTTONS_PER_ROW = 4

local ADDON_POPUP_STRATA = "DIALOG"
local ADDON_POPUP_LEVEL = 100
-- Siblings: backdrop draws first; buttonHost and minimap buttons above (BackdropTemplate on the root can paint over children on retail).
local POPUP_BACKDROP_LAYER = 1
local POPUP_BUTTON_HOST_LAYER = 50

-- Expose globally for FluxMinimapToMicro integration
FluxAddonSystem = FluxAddonSystem or {}
local FluxAddonSystem = FluxAddonSystem

FluxAddonSystem.collectedButtons = FluxAddonSystem.collectedButtons or {}
FluxAddonSystem.buttonMap = FluxAddonSystem.buttonMap or {}
FluxAddonSystem.containerFrame = nil
FluxAddonSystem.contentFrame = nil -- New dedicated frame for buttons
FluxAddonSystem.isShown = false
FluxAddonSystem.scanTimer = nil
FluxAddonSystem._layoutInProgress = false
FluxAddonSystem._scanInProgress = false

-- Make it globally accessible
_G.FluxAddonSystem = FluxAddonSystem

-- Capture original frame methods to bypass overrides (MBB Style)
local SetPoint = UIParent.SetPoint
local ClearAllPoints = UIParent.ClearAllPoints

-- ---------------------------------------------------------------------------
-- 1. Container Frame (The Popup)
-- ---------------------------------------------------------------------------
-- Fix: Check BackdropTemplateMixin (lowercase d)
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

-- Plain shell (no BackdropTemplate on root — that layer can draw above nested button trees on retail).
local container = CreateFrame("Frame", "FluxAddonContainer", UIParent)
container:SetFrameStrata(ADDON_POPUP_STRATA)
container:SetFrameLevel(ADDON_POPUP_LEVEL)
container:SetSize(100, 100)
container:Hide()
FluxAddonSystem.containerFrame = container

local backdropFrame = CreateFrame("Frame", "FluxAddonBackdrop", container, backdropTemplate)
backdropFrame:SetAllPoints(container)
backdropFrame:SetFrameStrata(ADDON_POPUP_STRATA)
backdropFrame:SetFrameLevel(POPUP_BACKDROP_LAYER)
backdropFrame:EnableMouse(false)

if not backdropFrame.SetBackdrop and Mixin and BackdropTemplateMixin then
    Mixin(backdropFrame, BackdropTemplateMixin)
    backdropFrame:OnBackdropLoaded()
end

if backdropFrame.SetBackdrop then
    backdropFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    local r, g, b = 1, 1, 1
    if FluxBorder and FluxBorder.GetThemedVertexRGB then
        r, g, b = FluxBorder:GetThemedVertexRGB()
    else
        local _, class = UnitClass("player")
        if FluxMicroMenu and FluxMicroMenu.GetClassColor then
            r, g, b = FluxMicroMenu:GetClassColor()
        elseif C_ClassColor and C_ClassColor.GetClassColor then
            local color = C_ClassColor.GetClassColor(class)
            if color then r, g, b = color.r, color.g, color.b end
        elseif GetClassColor then
            r, g, b = GetClassColor(class)
        end
    end

    local br, bg, bb = r * 0.2, g * 0.2, b * 0.2
    if FluxBorder and FluxBorder.GetThemedBackdropFillRGB then
        br, bg, bb = FluxBorder:GetThemedBackdropFillRGB()
    end
    backdropFrame:SetBackdropColor(br, bg, bb, 0.95)
    backdropFrame:SetBackdropBorderColor(r, g, b, 1)
end

FluxAddonSystem.backgroundFrame = backdropFrame

local buttonHost = CreateFrame("Frame", "FluxAddonButtonHost", container)
buttonHost:SetAllPoints(container)
buttonHost:SetFrameStrata(ADDON_POPUP_STRATA)
buttonHost:SetFrameLevel(POPUP_BUTTON_HOST_LAYER)
FluxAddonSystem.contentFrame = buttonHost

-- Auto-Close on Movement
container:RegisterEvent("PLAYER_STARTED_MOVING")
container:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_STARTED_MOVING" then
        self:Hide()
        FluxAddonSystem.isShown = false
    end
end)

-- ---------------------------------------------------------------------------
-- 2. Button Identification & Exclusion
-- ---------------------------------------------------------------------------

-- Patterns to identify minimap buttons
local MINIMAP_BUTTON_PATTERNS = {
    "^LibDBIcon10_",
    "MinimapButton",
    "MinimapFrame", 
    "MinimapIcon",
    "[-_]Minimap[-_]",
    "Minimap$"
}

local EXCLUDED_BUTTONS = {
    "Minimap",
    "MinimapCluster",
    "MinimapBackdrop",
    "MinimapContainer",
    "LFG_MinimapEye",
    "QueueStatusMinimapButton",
    "MiniMapTracking",
    "MiniMapTrackingButton", -- Classic
    "MiniMapVoiceChatFrame",
    "TimeManagerClockButton",
    "GameTimeFrame",
    "GarrisonLandingPageMinimapButton",
    "ExpansionLandingPageMinimapButton", -- Dragonflight/TWW
    "MiniMapMailFrame",
    "MiniMapBattlefieldFrame",
    "FeedbackUIButton",
    "HelpOpenTicketButton",
    "COHCMinimapButton", -- Sometimes problematic
    "MinimapZoomIn",
    "MinimapZoomOut",
}

local function IsExcluded(name)
    if not name then return false end
    for _, excluded in ipairs(EXCLUDED_BUTTONS) do
        if name == excluded or string.match(name, "^LFG") then return true end
    end
    return false
end

local function NameLooksLikeMinimapButton(name)
    if type(name) ~= "string" or name == "" then return false end
    if IsExcluded(name) then return false end
    for _, pattern in ipairs(MINIMAP_BUTTON_PATTERNS) do
        if string.match(name, pattern) then return true end
    end
    if string.match(name, "^TomCats%-") then return true end
    return false
end

local function IsFrameLike(frame)
    if not frame then return false end
    local t = type(frame)
    if t ~= "table" and t ~= "userdata" then return false end
    if frame.IsForbidden then
        local okForbidden, forbidden = pcall(frame.IsForbidden, frame)
        if okForbidden and forbidden then return false end
    end
    if not frame.IsObjectType then return false end
    local okFrame, isFrame = pcall(frame.IsObjectType, frame, "Frame")
    if okFrame and isFrame then return true end
    local okBtn, isBtn = pcall(frame.IsObjectType, frame, "Button")
    return okBtn and isBtn
end

local function IsValidMinimapButton(frame)
    if not IsFrameLike(frame) or not frame.GetName then return false end
    local ok, name = pcall(frame.GetName, frame)
    if not ok or not name then return false end
    return NameLooksLikeMinimapButton(name)
end

--- Shared with FluxMinimapToMicro (this file loads first).
FluxAddonSystem.IsValidMinimapButton = IsValidMinimapButton
FluxAddonSystem.NameLooksLikeMinimapButton = NameLooksLikeMinimapButton

function FluxAddonSystem.GetMinimapScanRoots()
    local roots = {}
    local seen = {}
    local function add(f)
        if f and not seen[f] then
            seen[f] = true
            roots[#roots + 1] = f
        end
    end
    add(_G.Minimap)
    add(_G.MinimapCluster)
    local cluster = _G.MinimapCluster
    if cluster then
        add(cluster.MinimapContainer)
        if cluster.MinimapContainer then
            add(cluster.MinimapContainer.Minimap)
        end
        add(cluster.Minimap)
    end
    add(_G.MinimapBackdrop)
    return roots
end

-- ---------------------------------------------------------------------------
-- 3. Collection Logic
-- ---------------------------------------------------------------------------

local function doNothing() end

local function UpdateLayoutIfNeeded(button)
    if FluxAddonSystem.isShown and not FluxAddonSystem._layoutInProgress then
        FluxAddonSystem:UpdateLayout()
    end
end

local function CollectButton(button)
    if not button or FluxAddonSystem.buttonMap[button] then return end
    
    FluxAddonSystem.buttonMap[button] = true
    table.insert(FluxAddonSystem.collectedButtons, button)
    
    -- Parent to buttonHost (above container backdrop draw pass; LibDBIcon fixes strata/level — clear so DIALOG applies).
    button:SetParent(buttonHost)
    if button.SetFixedFrameStrata then
        pcall(button.SetFixedFrameStrata, button, false)
    end
    if button.SetFixedFrameLevel then
        pcall(button.SetFixedFrameLevel, button, false)
    end
    button:SetFrameStrata(ADDON_POPUP_STRATA)
    if button.SetFrameLevel then
        button:SetFrameLevel(10)
    end
    if button.SetFixedFrameStrata then
        pcall(button.SetFixedFrameStrata, button, true)
    end
    
    -- Disable specific scripts that might cause issues
    if button.SetScript then
        button:SetScript("OnDragStart", nil)
        button:SetScript("OnDragStop", nil)
    end
    button:SetMovable(false)
    
    -- Ensure visibility assumes we control it
    button:SetAlpha(1)
    button:SetScale(1.0)
    
    -- Ensure it scales with our container (if supported)
    if button.SetIgnoreParentScale then
        button:SetIgnoreParentScale(false)
    end
    
    -- MBB-Style Aggressive Overrides: Prevent addons from moving/resizing/re-layering their buttons
    button.ClearAllPoints = doNothing
    button.SetPoint = doNothing
    button.SetScale = doNothing 
    button.SetParent = doNothing
    
    -- LOCK the layering so they can't fall behind
    button.SetFrameStrata = doNothing
    button.SetFrameLevel = doNothing
    
    -- Hook visibility to re-layout if an addon hides its button
    if not button._fluxAddonVisHooked then
        button._fluxAddonVisHooked = true
        if button.HookScript then
            button:HookScript("OnShow", UpdateLayoutIfNeeded)
            button:HookScript("OnHide", UpdateLayoutIfNeeded)
        end
    end
    
    -- Hide initially (SetupLayout will show them)
    ClearAllPoints(button)
    button:Hide() -- Hide determines visibility, we still want to hook it
end

function FluxAddonSystem:Scan()
    -- Re-entrant Scan (e.g. SetParent / hooks / LibDBIcon) must not recurse — stack overflow.
    if self._scanInProgress then
        return
    end
    self._scanInProgress = true
    local ok, err = pcall(function()
    local function collectFromParent(parent)
        if not parent or not parent.GetChildren then return end
        local okPack, packed = pcall(function()
            return { parent:GetChildren() }
        end)
        if not okPack or type(packed) ~= "table" then return end
        for i = 1, #packed do
            local child = packed[i]
            if child and IsValidMinimapButton(child) then
                CollectButton(child)
            end
        end
    end

    local roots = FluxAddonSystem.GetMinimapScanRoots and FluxAddonSystem.GetMinimapScanRoots() or { _G.Minimap }
    for i = 1, #roots do
        collectFromParent(roots[i])
    end

    -- 2. Scan LibDBIcon
    local LibDBIcon = _G.LibStub and _G.LibStub:GetLibrary("LibDBIcon-1.0", true)
    if LibDBIcon and LibDBIcon.GetButtonList then
        for _, name in ipairs(LibDBIcon:GetButtonList()) do
            local button = LibDBIcon:GetMinimapButton(name)
            if button then CollectButton(button) end
        end
    end
    
    -- 3. Scan LibMapButton
    local LibMapButton = _G.LibStub and _G.LibStub:GetLibrary("LibMapButton-1.1", true)
    if LibMapButton and LibMapButton.buttons then
        for _, button in pairs(LibMapButton.buttons) do
            CollectButton(button)
        end
    end

    -- 4. Register LibDBIcon Callback (MBB style)
    if LibDBIcon and LibDBIcon.RegisterCallback then
        -- Avoid duplicate registration
        if not FluxAddonSystem.callbackRegistered then
            LibDBIcon.RegisterCallback("FluxUI", "LibDBIcon_IconCreated", function(_, button)
                 CollectButton(button)
                 if FluxAddonSystem.isShown then FluxAddonSystem:UpdateLayout() end
            end)
            FluxAddonSystem.callbackRegistered = true
        end
    end
    end)
    self._scanInProgress = false
    if not ok then
        local handler = geterrorhandler and geterrorhandler()
        if handler then
            pcall(handler, err)
        end
    end
end

function FluxAddonSystem:UpdateLayout()
    if self._layoutInProgress then return end
    self._layoutInProgress = true
    
    local function releaseLayoutLock()
        self._layoutInProgress = false
    end
    
    local buttons = self.collectedButtons
    if #buttons == 0 then 
        container:Hide()
        releaseLayoutLock()
        return 
    end
    
    -- Filter out buttons that are enabled as micro menu buttons
    local filteredButtons = {}
    local enabledNames = {}
    
    -- Get enabled button names from FluxMinimapToMicro if available
    if FluxMinimapToMicro and FluxMinimapToMicro.GetEnabledButtonNames then
        enabledNames = FluxMinimapToMicro:GetEnabledButtonNames()
    end
    
    for _, button in ipairs(buttons) do
        local buttonName = button:GetName()
        if not buttonName or not enabledNames[buttonName] then
            table.insert(filteredButtons, button)
        else
            -- Hide buttons that are converted to micro buttons
            button:Hide()
        end
    end
    
    if #filteredButtons == 0 then 
        container:Hide()
        releaseLayoutLock()
        return 
    end
    
    local rows = math.ceil(#filteredButtons / BUTTONS_PER_ROW)
    local cols = math.min(#filteredButtons, BUTTONS_PER_ROW)
    
    local w = (cols * BUTTON_SIZE) + ((cols - 1) * BUTTON_SPACING) + (PADDING * 2)
    local h = (rows * BUTTON_SIZE) + ((rows - 1) * BUTTON_SPACING) + (PADDING * 2)
    
    container:SetSize(w, h)
    
    for i, button in ipairs(filteredButtons) do
        local row = math.floor((i - 1) / BUTTONS_PER_ROW)
        local col = (i - 1) % BUTTONS_PER_ROW
        
        ClearAllPoints(button)
        SetPoint(button, "TOPLEFT", buttonHost, "TOPLEFT",
            PADDING + (col * (BUTTON_SIZE + BUTTON_SPACING)),
            -(PADDING + (row * (BUTTON_SIZE + BUTTON_SPACING)))
        )
        button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        button:Show()
    end
    
    releaseLayoutLock()

    if self.ClampContainerToScreen and container:IsShown() then
        self:ClampContainerToScreen()
    end
end

-- Margin from UIParent edges; extra padding around FluxMicroMenu so popups never sit on the bar.
local POPUP_SCREEN_MARGIN = 8
local MICRO_MENU_PAD = 4
local ANCHOR_BELOW_Y = -2
local ANCHOR_ABOVE_Y = 2

local function PopupGetLRTB(f)
    local l, r, b, t = f:GetLeft(), f:GetRight(), f:GetBottom(), f:GetTop()
    if not l or not r or not b or not t then
        return nil
    end
    return l, r, b, t
end

local function PopupRectsOverlap(l1, r1, b1, t1, l2, r2, b2, t2)
    return (math.min(r1, r2) > math.max(l1, l2)) and (math.min(t1, t2) > math.max(b1, b2))
end

--- Visible FluxMicroMenu bounds inflated slightly — popups must not intersect this rect.
local function GetMicroMenuAvoidRect()
    local mm = _G.FluxMicroMenu
    if not mm or not mm.IsVisible or not mm:IsVisible() then
        return nil
    end
    local l, r, b, t = PopupGetLRTB(mm)
    if not l then
        return nil
    end
    local p = MICRO_MENU_PAD
    return l - p, r + p, b - p, t + p
end

--- Shared by FluxAddonContainer (left click) and FluxMicroMenuConfigUI standalone (right click):
--- keep frame inside UIParent and out from under FluxMicroMenu.
function FluxAddonSystem.ClampPopupToScreenAndMicroMenu(frame, anchorButton)
    if not frame or not anchorButton or not frame:IsShown() then
        return
    end

    local pw = UIParent:GetWidth()
    local ph = UIParent:GetHeight()
    local m = POPUP_SCREEN_MARGIN

    local function apply(below, dx, dy)
        frame:ClearAllPoints()
        if below then
            frame:SetPoint("TOPRIGHT", anchorButton, "BOTTOMRIGHT", dx, ANCHOR_BELOW_Y + dy)
        else
            frame:SetPoint("BOTTOMRIGHT", anchorButton, "TOPRIGHT", dx, ANCHOR_ABOVE_Y + dy)
        end
    end

    local function onePass(below, dx, dy)
        apply(below, dx, dy)
        local l, r, b, t = PopupGetLRTB(frame)
        if not l then
            return dx, dy, false
        end

        if l < m then
            return dx + (m - l), dy, true
        end
        if r > pw - m then
            return dx + (pw - m - r), dy, true
        end
        if b < m then
            return dx, dy + (m - b), true
        end
        if t > ph - m then
            return dx, dy + (ph - m - t), true
        end

        local al, ar_, ab, at = GetMicroMenuAvoidRect()
        if al and PopupRectsOverlap(l, r, b, t, al, ar_, ab, at) then
            local ndx, ndy = dx, dy
            if below then
                ndy = ndy - 4
            else
                ndy = ndy + 4
            end
            -- Wide popups can span the bar horizontally; slide toward the nearest screen edge.
            if math.min(r, ar_) > math.max(l, al) then
                local mid = (l + r) * 0.5
                local midM = (al + ar_) * 0.5
                if mid < midM then
                    ndx = ndx - 8
                else
                    ndx = ndx + 8
                end
            end
            return ndx, ndy, true
        end

        return dx, dy, false
    end

    for _, below in ipairs({ true, false }) do
        local dx, dy = 0, 0
        for _ = 1, 120 do
            local ndx, ndy, moved = onePass(below, dx, dy)
            dx, dy = ndx, ndy
            if not moved then
                return
            end
        end
    end
end

function FluxAddonSystem:ClampContainerToScreen()
    local mb = self.microButton
    if not mb or not container:IsShown() then return end
    C_Timer.After(0, function()
        if not container:IsShown() then return end
        local mb2 = FluxAddonSystem.microButton
        if not mb2 then return end
        FluxAddonSystem.ClampPopupToScreenAndMicroMenu(container, mb2)
    end)
end

-- ---------------------------------------------------------------------------
-- 4. Micro Button Setup
-- ---------------------------------------------------------------------------

-- Single file texture present in all builds; GearManager path was missing on some clients (blank icon).
-- CreateMicroButton applies portrait TexCoords to the icon — we override to full image below.
local ADDON_MICRO_PLUS_TEXTURE = "Interface\\Buttons\\UI-PlusButton-Up"

local clickHandler = {
    OnClick = function(self, button)
        if button == "RightButton" then
            -- Right-click: Open config popup for converting minimap buttons to micro buttons
            -- Close left-click popup first if open
            if FluxAddonSystem.isShown then
                FluxAddonSystem.isShown = false
                container:Hide()
            end
            
            if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.ToggleStandalone then
                FluxMicroMenuConfigUI:ToggleStandalone(self)
            elseif FluxMinimapToMicro and FluxMinimapToMicro.ShowConfigPopup then
                FluxMinimapToMicro:ShowConfigPopup(self)
            end
        else
            -- Left-click: Toggle minimap buttons popup
            -- Close config popup first if open
            if FluxMinimapToMicro and FluxMinimapToMicro.isConfigShown then
                FluxMinimapToMicro:HideConfigPopup()
            end
            
            -- Toggle left-click popup
            if FluxAddonSystem.isShown then
                FluxAddonSystem.isShown = false
                container:Hide()
            else
                FluxAddonSystem:Scan() -- Scan for new ones before showing
                FluxAddonSystem:UpdateLayout()
                FluxAddonSystem.isShown = true
                container:Show()
                if container.Raise then
                    container:Raise()
                end
                FluxAddonSystem:ClampContainerToScreen()
            end
        end
    end,
    
    OnTooltip = function(tooltip)
        tooltip:AddLine("Addons")
        tooltip:AddLine("<Left Click> View minimap buttons", 1, 1, 1)
        tooltip:AddLine("<Right Click> Configure micro buttons", 1, 1, 1)
        tooltip:AddLine("Collected: " .. #FluxAddonSystem.collectedButtons, 0.7, 0.7, 0.7)
    end
}

local btn = FluxMicroMenu:CreateMicroButton(
    "FluxAddonMicroButton",
    ADDON_MICRO_PLUS_TEXTURE,
    "Addons",
    "TOGGLEADDONS",
    clickHandler
)

if btn then
    -- Enable right-click on the button
    btn:RegisterForClicks("AnyUp")

    if btn.icon then
        btn.icon:SetTexture(ADDON_MICRO_PLUS_TEXTURE)
        -- CreateMicroButton sets portrait crop (0.2…0.9) on both DF and legacy shells; plus art needs full UVs.
        btn.icon:SetTexCoord(0, 1, 0, 1)
        btn.icon:SetVertexColor(1, 1, 1)
    end
    
    -- Anchor container to button
    container:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, -2)
    
    -- Store reference for config popup anchoring
    FluxAddonSystem.microButton = btn
    
    -- Start Periodic Scan
    local function PeriodicScan()
        FluxAddonSystem:Scan()
        C_Timer.After(10, PeriodicScan) -- Scan every 10s (periodic is fine)
    end
    
    -- Event-Based Startup Scan (Instant initialization)
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:SetScript("OnEvent", function(self, event)
        -- Instant scan on events
        FluxAddonSystem:Scan()
        
        -- Start periodic scan immediately (no delay)
        if event == "PLAYER_LOGIN" then
            PeriodicScan()  -- Start immediately, will schedule next one after 10s
        end
    end)
    
    -- Immediate Scan (instant)
    FluxAddonSystem:Scan()
    
    -- Force Rebuild to make button appear immediately
    if FluxMicroMenu.Rebuild then
        FluxMicroMenu:Rebuild()
    end
end

function FluxAddonPopup_RefreshAccent()
    local bg = FluxAddonSystem and FluxAddonSystem.backgroundFrame
    if not bg or not bg.SetBackdropColor then return end
    local r, g, b = 1, 1, 1
    if FluxBorder and FluxBorder.GetThemedVertexRGB then
        r, g, b = FluxBorder:GetThemedVertexRGB()
    end
    local br, bg2, bb = r * 0.2, g * 0.2, b * 0.2
    if FluxBorder and FluxBorder.GetThemedBackdropFillRGB then
        br, bg2, bb = FluxBorder:GetThemedBackdropFillRGB()
    end
    bg:SetBackdropColor(br, bg2, bb, 0.95)
    bg:SetBackdropBorderColor(r, g, b, 1)
end

