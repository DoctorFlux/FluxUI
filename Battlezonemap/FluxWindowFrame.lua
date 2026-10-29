-- FluxWindowFrame.lua
-- Universal Window Frame for FluxUI
-- Creates a 300x400 frame positioned at bottom-right of screen with FluxBorder
-- Can be used for Battlezone maps, Damage meters, and other UI elements

local addonName, addonTable = ...
local Flux = addonTable and addonTable.Flux or _G.Flux

-- Create the public API
FluxWindowFrame = {}

-- Configuration (accessible globally via FluxWindowFrame.WINDOW_WIDTH/HEIGHT)
-- Size matches Blizzard's BattlefieldMapFrame default (300x200)
local FluxWindowFrameRescale = 1.35
FluxWindowFrame.WINDOW_WIDTH = 300 * FluxWindowFrameRescale
FluxWindowFrame.WINDOW_HEIGHT = 200 * FluxWindowFrameRescale
local WINDOW_WIDTH = FluxWindowFrame.WINDOW_WIDTH
local WINDOW_HEIGHT = FluxWindowFrame.WINDOW_HEIGHT
local WINDOW_OFFSET_X = 0  -- Distance from right edge of screen
local WINDOW_OFFSET_Y = 0  -- Distance from bottom edge of screen

-- Internal frame storage
local windowFrame = nil

-- Tab system
local tabs = {} -- indexed by name
local tabList = {} -- indexed array for positioning
local activeTab = nil
local tabContainer = nil
local TAB_HEIGHT = 40
local TAB_MIN_WIDTH = 80

-- Map tab toggle state (true = Map, false = Minimap)
local isMapMode = true

-- A tab owns its delayed work. Native NewTimer lets us cancel queued callbacks;
-- the generation guard also covers clients providing only C_Timer.After.
local function CancelTabWork(tab)
    tab.workGeneration = (tab.workGeneration or 0) + 1
    if tab.workTimers then
        for _, work in pairs(tab.workTimers) do
            local timer = work.timer
            if timer and timer.Cancel then timer:Cancel() end
        end
    end
    tab.workTimers = nil
    tab.combatWork = nil
end

local function TabAfter(tab, key, delay, callback)
    local generation = tab.workGeneration or 0
    tab.workTimers = tab.workTimers or {}
    local timers = tab.workTimers
    local old = timers[key]
    if old and old.timer and old.timer.Cancel then old.timer:Cancel() end
    local work = {}
    timers[key] = work
    local function Run()
        if tabs[tab.name] ~= tab or activeTab ~= tab.name
            or generation ~= (tab.workGeneration or 0) or timers[key] ~= work then return end
        timers[key] = nil
        if InCombatLockdown() then
            tab.combatWork = tab.combatWork or {}
            tab.combatWork[key] = callback
            return
        end
        callback()
    end
    if C_Timer.NewTimer then
        work.timer = C_Timer.NewTimer(delay, Run)
    else
        C_Timer.After(delay, Run)
    end
end

local function GetTabStatusText(tab)
    local text = tab.statusText
    if not text then
        text = tab.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", tab.content, "CENTER")
        tab.statusText = text
    end
    text:Show()
    return text
end

-- Meter layout delegated to FluxMeterLayout (library + editor).
-- Meter tab: Details XOR Blizzard_DamageMeter. Neither → no tab.
local function ResolveMeterSystem()
    if FluxMeterLayout and FluxMeterLayout.GetMeterBackend then
        local backend = FluxMeterLayout.GetMeterBackend()
        if backend == "Details" then
            return "Details"
        end
        if backend == "Blizzard" then
            return "BlizzardMeter"
        end
        return nil
    end
    if FluxMeterLayout and FluxMeterLayout.IsDetailsAddonLoaded
        and FluxMeterLayout.IsDetailsAddonLoaded() then
        return "Details"
    end
    if FluxBlizzardMeter and FluxBlizzardMeter.IsAvailable and FluxBlizzardMeter:IsAvailable() then
        return "BlizzardMeter"
    end
    return nil
end

local function GetMeterPresetCount()
    if FluxMeterLayout and FluxMeterLayout.GetBuiltinCount then
        return FluxMeterLayout.GetBuiltinCount()
    end
    return 11
end

local function ApplyMeterCycleLayout()
    if not FluxMeterLayout then return end
    local id = FluxMeterLayout.GetActiveLayoutId and FluxMeterLayout.GetActiveLayoutId() or 'builtin:1'
    local n = tonumber((id or ''):match('^builtin:(%d+)$')) or 1
    local count = GetMeterPresetCount()
    n = (n % count) + 1
    FluxMeterLayout.ApplyBuiltin(n)
    if FluxMeterLayout.ReembedQuiet then
        FluxMeterLayout.ReembedQuiet()
    end
end

--- Save tab state per character
local function SaveTabState()
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end

    local activeTabIndex = 1
    if activeTab == "Meter" then
        activeTabIndex = 2
    elseif activeTab == "Respec" then
        activeTabIndex = 3
    elseif activeTab == "Buttons" then
        activeTabIndex = 4
    end

    _FluxUI_CharSavedVars.fluxWindowActiveTab = activeTabIndex
    _FluxUI_CharSavedVars.fluxWindowMapMode = isMapMode
    -- Meter layouts persist via FluxMeterLayout
end

--- One-time migration: Respec and Buttons swapped positions (Respec before Buttons).
--- Old save: 3 = Buttons, 4 = Respec. New save: 3 = Respec, 4 = Buttons.
local TAB_ORDER_MIGRATION_KEY = "fluxWindowTabOrderRespecBeforeButtons"
local function MigrateTabIndexIfNeeded()
    if not _FluxUI_CharSavedVars then
        return
    end
    if _FluxUI_CharSavedVars[TAB_ORDER_MIGRATION_KEY] then
        return
    end
    local idx = _FluxUI_CharSavedVars.fluxWindowActiveTab
    if type(idx) == "number" then
        if idx == 3 then
            _FluxUI_CharSavedVars.fluxWindowActiveTab = 4
        elseif idx == 4 then
            _FluxUI_CharSavedVars.fluxWindowActiveTab = 3
        end
    end
    _FluxUI_CharSavedVars[TAB_ORDER_MIGRATION_KEY] = true
end

--- Load tab state per character
local function LoadTabState()
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end

    MigrateTabIndexIfNeeded()

    local savedTabIndex = _FluxUI_CharSavedVars.fluxWindowActiveTab
    if savedTabIndex == 2 then
        activeTab = "Meter"
    elseif savedTabIndex == 3 then
        activeTab = "Respec"
    elseif savedTabIndex == 4 then
        activeTab = "Buttons"
    else
        activeTab = "Map"
    end

    isMapMode = (_FluxUI_CharSavedVars.fluxWindowMapMode ~= false)

    if FluxMeterLayout and FluxMeterLayout.Init then
        FluxMeterLayout.Init()
    end
end

local function GetStatusBarBottomLift()
    if _G.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome then
        return _G.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome() or 0
    end
    if _G.FluxStatusBar_GetBottomOverlayHeight then
        return _G.FluxStatusBar_GetBottomOverlayHeight() or 0
    end
    return 0
end

local function ApplyWindowFrameScreenAnchor()
    if not windowFrame then
        return
    end
    local lift = GetStatusBarBottomLift()
    windowFrame:ClearAllPoints()
    windowFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -WINDOW_OFFSET_X, WINDOW_OFFSET_Y + lift)
end

--- Re-anchor to UIParent when status bar position 3 bottom strip height changes.
function FluxWindowFrame:ApplyBottomLiftFromStatusBar()
    if not windowFrame or InCombatLockdown() then
        return
    end
    ApplyWindowFrameScreenAnchor()
end

--- Create or get the window frame
function FluxWindowFrame:GetFrame()
    if windowFrame then
        return windowFrame
    end

    -- Create the main frame
    windowFrame = CreateFrame("Frame", "FluxWindowFrame", UIParent)
    windowFrame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    ApplyWindowFrameScreenAnchor()
    windowFrame:SetFrameStrata("MEDIUM") -- Higher than ActionBars borders
    windowFrame:SetFrameLevel(10) -- Higher than ActionBars (which use level 1-6)

    -- Keep it stationary (not movable)

    -- Apply FluxBorder first
    if FluxBorder then
        FluxBorder:ApplyTo(windowFrame)

        -- Set class color for both border and backdrop using FluxBorder's SetClassColor method
        local _, classFilename = UnitClass("player")
        local color = RAID_CLASS_COLORS[classFilename]

        if color then
            -- Use the unified SetClassColor method which handles both border and backdrop
            FluxBorder:SetClassColor(windowFrame, 1, true)
        else
            -- Fallback if no class color found
            FluxBorder:SetBorderColor(windowFrame, 0.5, 0.5, 0.5, 1)
            FluxBorder:SetBackdropColor(windowFrame, 0.1, 0.1, 0.1, 0.8)
        end

    else
    end

    -- Create content area AFTER border is applied (inset from border)
    -- Use generous inset to avoid any border overlap
    local contentInset = 20
    windowFrame.Content = CreateFrame("Frame", nil, windowFrame)
    windowFrame.Content:SetPoint("TOPLEFT", windowFrame, "TOPLEFT", contentInset, -contentInset)
    windowFrame.Content:SetPoint("BOTTOMRIGHT", windowFrame, "BOTTOMRIGHT", -contentInset, contentInset)

    -- Store reference
    self.frame = windowFrame

    return windowFrame
end

--- Show the window frame
function FluxWindowFrame:Show()
    local frame = self:GetFrame()
    frame:Show()
    if Flux and Flux.Startup then Flux.Startup.Mark("window_shell_visible") end
    if frame._fluxMapWasActive and FluxBattlefieldMap and FluxBattlefieldMap.Show then
        frame._fluxMapWasActive = nil
        FluxBattlefieldMap:Show()
    end
    if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
        FluxUnifiedBorder.UpdateBorder()
    end
end

--- Hide the window frame
function FluxWindowFrame:Hide()
    if windowFrame then
        if FluxBattlefieldMap and FluxBattlefieldMap.IsActive and FluxBattlefieldMap:IsActive() then
            FluxBattlefieldMap:Hide()
            windowFrame._fluxMapWasActive = true
        end
        windowFrame:Hide()
        if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
            FluxUnifiedBorder.UpdateBorder()
        end
    end
end

--- Toggle the window frame visibility
function FluxWindowFrame:Toggle()
    if windowFrame and windowFrame:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

--- Set the window size
-- @param width The new width
-- @param height The new height
function FluxWindowFrame:SetSize(width, height)
    WINDOW_WIDTH = width or WINDOW_WIDTH
    WINDOW_HEIGHT = height or WINDOW_HEIGHT

    if windowFrame then
        windowFrame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    end
    -- Binding tab expands the window; skip-unchanged dock still applies the new height.
    if FluxMinimap and FluxMinimap.UpdateQuestTrackerPosition then
        FluxMinimap:UpdateQuestTrackerPosition()
    end
end

--- Set the window position offset from bottom-right
-- @param xOffset Distance from right edge (positive = move left)
-- @param yOffset Distance from bottom edge (positive = move up)
function FluxWindowFrame:SetOffset(xOffset, yOffset)
    WINDOW_OFFSET_X = xOffset or WINDOW_OFFSET_X
    WINDOW_OFFSET_Y = yOffset or WINDOW_OFFSET_Y

    if windowFrame then
        ApplyWindowFrameScreenAnchor()
    end
end

--- Return the content frame for child widgets.
function FluxWindowFrame:GetContentFrame()
    local frame = self:GetFrame()
    return frame.Content
end

--- Set border color using FluxBorder
-- @param r Red (0-1)
-- @param g Green (0-1)
-- @param b Blue (0-1)
-- @param a Alpha (0-1, optional)
function FluxWindowFrame:SetBorderColor(r, g, b, a)
    if FluxBorder and windowFrame then
        FluxBorder:SetBorderColor(windowFrame, r, g, b, a)
    end
end

--- Set backdrop color using FluxBorder
-- @param r Red (0-1)
-- @param g Green (0-1)
-- @param b Blue (0-1)
-- @param a Alpha (0-1, optional)
function FluxWindowFrame:SetBackdropColor(r, g, b, a)
    if FluxBorder and windowFrame then
        FluxBorder:SetBackdropColor(windowFrame, r, g, b, a)
    end
end

--- Set class color border using FluxBorder
-- @param a Alpha (0-1, optional)
-- @param tintBackdrop Boolean (optional, default true) - if true, also colors background
function FluxWindowFrame:SetClassColor(a, tintBackdrop)
    if FluxBorder and windowFrame then
        FluxBorder:SetClassColor(windowFrame, a, tintBackdrop)
    end
end

--- Open AddonOptions on the FluxWindow tab (meter layout / tab settings)
local function ShowMeterLayoutMenu(anchor)
    if FluxOptions and FluxOptions.OpenToFluxWindowTab then
        FluxOptions:OpenToFluxWindowTab()
    end
end

function FluxWindowFrame:ShowMeterLayoutMenu(anchor)
    ShowMeterLayoutMenu(anchor)
end

function FluxWindowFrame:IsMeterEditMode()
    return FluxMeterLayout and FluxMeterLayout.IsEditorOpen and FluxMeterLayout.IsEditorOpen()
end

function FluxWindowFrame:ExitMeterEditMode()
    if FluxMeterLayout and FluxMeterLayout.CloseEditor then
        FluxMeterLayout.CloseEditor()
    end
end

function FluxWindowFrame:ReembedMeterQuiet()
    if FluxMeterLayout and FluxMeterLayout.ReembedQuiet then
        FluxMeterLayout.ReembedQuiet()
    end
end

--- Create a tab button with chat-frame style
-- @param container The tab container
-- @param name The tab name
-- @param index The tab index for positioning
local function CreateTabButton(container, name, index)
    local tab = CreateFrame("Button", nil, container)
    tab:SetHeight(TAB_HEIGHT)
    tab:SetFrameStrata("BACKGROUND")
    tab:SetFrameLevel(2)

    -- Tab textures (chat frame style) - scaled up
    local leftTexture = tab:CreateTexture(nil, "BACKGROUND")
    leftTexture:SetTexture("Interface\\ChatFrame\\ChatFrameTab-BGLeft")
    leftTexture:SetSize(20, TAB_HEIGHT)
    leftTexture:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", -2, 0)
    leftTexture:SetVertexColor(0.5, 0.5, 0.5, 0.8) -- Gray base color
    tab.leftTexture = leftTexture

    local rightTexture = tab:CreateTexture(nil, "BACKGROUND")
    rightTexture:SetTexture("Interface\\ChatFrame\\ChatFrameTab-BGRight")
    rightTexture:SetSize(20, TAB_HEIGHT)
    rightTexture:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 2, 0)
    rightTexture:SetVertexColor(0.5, 0.5, 0.5, 0.8) -- Gray base color
    tab.rightTexture = rightTexture

    local middleTexture = tab:CreateTexture(nil, "BACKGROUND")
    middleTexture:SetTexture("Interface\\ChatFrame\\ChatFrameTab-BGMid")
    middleTexture:SetHeight(TAB_HEIGHT)
    middleTexture:SetPoint("LEFT", leftTexture, "RIGHT", 0, 0)
    middleTexture:SetPoint("RIGHT", rightTexture, "LEFT", 0, 0)
    middleTexture:SetHorizTile(true)
    middleTexture:SetVertexColor(0.5, 0.5, 0.5, 0.8) -- Gray base color
    tab.middleTexture = middleTexture

    -- Active state textures (shown when selected)
    local activeLeft = tab:CreateTexture(nil, "BORDER")
    activeLeft:SetTexture("Interface\\ChatFrame\\ChatFrameTab-SelectedLeft")
    activeLeft:SetBlendMode("ADD")
    activeLeft:SetSize(20, TAB_HEIGHT)
    activeLeft:SetPoint("TOPLEFT", leftTexture, "TOPLEFT", 0, 0)
    activeLeft:Hide()
    tab.activeLeft = activeLeft

    local activeMiddle = tab:CreateTexture(nil, "BORDER")
    activeMiddle:SetTexture("Interface\\ChatFrame\\ChatFrameTab-SelectedMid")
    activeMiddle:SetBlendMode("ADD")
    activeMiddle:SetHeight(TAB_HEIGHT)
    activeMiddle:SetPoint("LEFT", middleTexture, "LEFT", 0, 0)
    activeMiddle:SetPoint("RIGHT", middleTexture, "RIGHT", 0, 0)
    activeMiddle:SetHorizTile(true)
    activeMiddle:Hide()
    tab.activeMiddle = activeMiddle

    local activeRight = tab:CreateTexture(nil, "BORDER")
    activeRight:SetTexture("Interface\\ChatFrame\\ChatFrameTab-SelectedRight")
    activeRight:SetBlendMode("ADD")
    activeRight:SetSize(20, TAB_HEIGHT)
    activeRight:SetPoint("TOPRIGHT", rightTexture, "TOPRIGHT", 0, 0)
    activeRight:Hide()
    tab.activeRight = activeRight

    -- Highlight textures (for mouseover)
    local highlightLeft = tab:CreateTexture(nil, "HIGHLIGHT")
    highlightLeft:SetTexture("Interface\\ChatFrame\\ChatFrameTab-HighlightLeft")
    highlightLeft:SetBlendMode("ADD")
    highlightLeft:SetSize(20, TAB_HEIGHT)
    highlightLeft:SetPoint("TOPLEFT", leftTexture, "TOPLEFT", 0, 0)
    highlightLeft:Hide()
    tab.highlightLeft = highlightLeft

    local highlightMiddle = tab:CreateTexture(nil, "HIGHLIGHT")
    highlightMiddle:SetTexture("Interface\\ChatFrame\\ChatFrameTab-HighlightMid")
    highlightMiddle:SetBlendMode("ADD")
    highlightMiddle:SetHeight(TAB_HEIGHT)
    highlightMiddle:SetPoint("LEFT", middleTexture, "LEFT", 0, 0)
    highlightMiddle:SetPoint("RIGHT", middleTexture, "RIGHT", 0, 0)
    highlightMiddle:SetHorizTile(true)
    highlightMiddle:Hide()
    tab.highlightMiddle = highlightMiddle

    local highlightRight = tab:CreateTexture(nil, "HIGHLIGHT")
    highlightRight:SetTexture("Interface\\ChatFrame\\ChatFrameTab-HighlightRight")
    highlightRight:SetBlendMode("ADD")
    highlightRight:SetSize(20, TAB_HEIGHT)
    highlightRight:SetPoint("TOPRIGHT", rightTexture, "TOPRIGHT", 0, 0)
    highlightRight:Hide()
    tab.highlightRight = highlightRight

    -- Tab text
    local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", tab, "CENTER", 0, -5)
    text:SetText(name)
    tab.text = text

    -- Size the tab
    local width = math.max(TAB_MIN_WIDTH, text:GetStringWidth() + 30)
    tab:SetWidth(width)

    -- Position the tab
    if index == 1 then
        tab:SetPoint("LEFT")
    else
        tab:SetPoint("LEFT", tabList[index-1].button, "RIGHT", -4, 0)
    end

    -- Resolve accent color for active/highlight tab textures
    local tr, tg, tb = 0.5, 0.5, 0.5
    if FluxBorder and FluxBorder.GetThemedVertexRGB then
        tr, tg, tb = FluxBorder:GetThemedVertexRGB()
    else
        local _, classFilename = UnitClass("player")
        local color = RAID_CLASS_COLORS[classFilename]
        if color then tr, tg, tb = color.r, color.g, color.b end
    end
    tab.selectedColorTable = { r = tr, g = tg, b = tb }

    activeLeft:SetVertexColor(tr, tg, tb, 1.0)
    activeMiddle:SetVertexColor(tr, tg, tb, 1.0)
    activeRight:SetVertexColor(tr, tg, tb, 1.0)
    highlightLeft:SetVertexColor(tr, tg, tb, 0.9)
    highlightMiddle:SetVertexColor(tr, tg, tb, 0.9)
    highlightRight:SetVertexColor(tr, tg, tb, 0.9)

    return tab
end

--- Update tab visual state (like the old BattleZoneMap system)
-- @param tab The tab button
-- @param selected Whether the tab is selected
local function UpdateTabVisualState(tab, selected)
    if selected then
        -- Active tab: show active textures, hide highlight textures
        if tab.activeLeft then tab.activeLeft:Show() end
        if tab.activeMiddle then tab.activeMiddle:Show() end
        if tab.activeRight then tab.activeRight:Show() end
        -- Hide any mouseover highlights on active tab
        if tab.highlightLeft then tab.highlightLeft:Hide() end
        if tab.highlightMiddle then tab.highlightMiddle:Hide() end
        if tab.highlightRight then tab.highlightRight:Hide() end
    else
        -- Inactive tab: hide active textures
        if tab.activeLeft then tab.activeLeft:Hide() end
        if tab.activeMiddle then tab.activeMiddle:Hide() end
        if tab.activeRight then tab.activeRight:Hide() end
        -- Also hide any lingering highlight textures
        if tab.highlightLeft then tab.highlightLeft:Hide() end
        if tab.highlightMiddle then tab.highlightMiddle:Hide() end
        if tab.highlightRight then tab.highlightRight:Hide() end
    end
end

--- Thoroughly clean up all content from a tab's content frame
-- @param tab The tab object to clean up
local function CleanupTabContent(tab)
    if not tab or not tab.content then return end

    -- Hide the content frame first
    tab.content:Hide()

    -- Get all child frames and regions
    local children = { tab.content:GetChildren() }
    local regions = { tab.content:GetRegions() }

    -- Helper function for safe parent setting (works across all WoW versions)
    local function SafeSetParent(obj, parent)
        if not obj then return end

        -- Use pcall to handle cases where SetParent(nil) fails on some clients
        local success = pcall(function()
            obj:SetParent(parent)
        end)

        -- If SetParent(nil) failed, try to set it to a safe parent instead
        if not success and parent == nil then
            -- Some clients reject nil parents for fonts and textures.
            -- Instead, just hide them and clear points
            obj:Hide()
            if obj.ClearAllPoints then
                obj:ClearAllPoints()
            end
        end
    end

    -- Helper function for safe hiding
    local function SafeHide(obj)
        if obj and obj.Hide then
            pcall(function() obj:Hide() end)
        end
    end

    -- Helper function for safe ClearAllPoints
    local function SafeClearAllPoints(obj)
        if obj and obj.ClearAllPoints then
            pcall(function() obj:ClearAllPoints() end)
        end
    end

    -- Destroy all child frames (recursively)
    for _, child in ipairs(children) do
        if child and child.GetChildren then
            -- Recursively clean up children first
            local grandchildren = { child:GetChildren() }
            for _, grandchild in ipairs(grandchildren) do
                if grandchild then
                    SafeHide(grandchild)
                    SafeSetParent(grandchild, nil)
                    SafeClearAllPoints(grandchild)
                end
            end
            -- Then clean up the child itself
            SafeHide(child)
            SafeSetParent(child, nil)
            SafeClearAllPoints(child)
        end
    end

    -- Clean up all regions (textures, font strings, etc.)
    for _, region in ipairs(regions) do
        if region then
            SafeHide(region)
            SafeSetParent(region, nil)
            SafeClearAllPoints(region)
        end
    end

    -- Clear any scripts that might be attached (with error handling)
    local scripts = {"OnUpdate", "OnEvent", "OnShow", "OnHide"}
    for _, script in ipairs(scripts) do
        pcall(function()
            if tab.content.SetScript then
                tab.content:SetScript(script, nil)
            end
        end)
    end

    -- Reset basic properties (with error handling)
    pcall(function()
        tab.content:ClearAllPoints()
        tab.content:SetAllPoints(windowFrame.Content)
    end)

    -- Additional fallback: If cleanup failed, recreate the content frame entirely
    -- This is a nuclear option for clients where cleanup is problematic
    local needsRecreation = false
    if tab.content.GetChildren then
        local remainingChildren = { tab.content:GetChildren() }
        if #remainingChildren > 0 then
            needsRecreation = true
        end
    end

    if needsRecreation then
        -- Recreate the content frame as a last resort (fallback for problematic clients)
        local oldContent = tab.content
        tab.content = CreateFrame("Frame", nil, windowFrame.Content)
        tab.content:SetAllPoints(windowFrame.Content)
        tab.content:Hide()

        -- Hide the detached content frame.
        pcall(function() oldContent:Hide() end)
        -- Don't try to set parent to nil, just leave it
    end
end

--- Create a new tab
-- @param name The name of the tab
-- @param onShow Function to call when tab is shown
-- @param onHide Function to call when tab is hidden (optional)
-- @param tooltipText Text to show in tooltip (optional)
function FluxWindowFrame:AddTab(name, onShow, onHide, tooltipText)
    if not windowFrame then return end
    if tabs[name] then return end -- Tab already exists

    -- Create tab container if it doesn't exist
    if not tabContainer then
        tabContainer = CreateFrame("Frame", "FluxWindowTabContainer", windowFrame)
        tabContainer:SetFrameStrata("BACKGROUND")
        tabContainer:SetFrameLevel(1)
        tabContainer:SetSize(1, TAB_HEIGHT)
        tabContainer:SetPoint("BOTTOMLEFT", windowFrame, "TOPLEFT", 0, -2)
        tabContainer:EnableMouse(true)
        tabContainer:Show()
    end

    local tabIndex = #tabList + 1

    -- Create tab structure first
    local tab = {
        name = name,
        index = tabIndex,
        onShow = onShow,
        onHide = onHide,
        content = CreateFrame("Frame", nil, windowFrame.Content)
    }

    -- Add to tabList first so positioning can work
    table.insert(tabList, tab)

    -- Now create the button with proper positioning
    tab.button = CreateTabButton(tabContainer, name, tabIndex)
    -- Middle-click only fires OnClick if registered (Meter tab uses it for reset).
    if name == "Meter" and tab.button.RegisterForClicks then
        tab.button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    end

    -- Setup tab content area (full content area)
    tab.content:SetAllPoints(windowFrame.Content)
    tab.content:Hide()

    -- Tab button click handler (special handling for Map tab)
    tab.button:SetScript("OnClick", function(self, button)
        if InCombatLockdown() then
            return
        end

        if name == "Meter" and button == "RightButton" then
            FluxWindowFrame:ShowMeterLayoutMenu(self)
            return
        end

        if name == "Meter" and button == "MiddleButton" then
            if InCombatLockdown() or (UnitAffectingCombat and UnitAffectingCombat("player")) then
                return
            end
            if FluxDetails and FluxDetails.ResetAllDataIfOutOfCombat then
                FluxDetails:ResetAllDataIfOutOfCombat()
            end
            if FluxBlizzardMeter and FluxBlizzardMeter.ResetAllSessionsIfOutOfCombat then
                FluxBlizzardMeter:ResetAllSessionsIfOutOfCombat()
            end
            return
        end

        if name == "Map" then
            -- Special behavior for Map tab: toggle between Map and Minimap modes
            if activeTab == "Map" then
                -- Already on Map tab, toggle the mode
                local wasMinimapMode = not isMapMode  -- store previous state before toggle
                isMapMode = not isMapMode

                -- Update tab text to reflect current mode
                tab.button.text:SetText(isMapMode and "Map" or "Minimap")

                -- Before updating content, restore minimap if we were in minimap mode
                if wasMinimapMode and FluxMinimap and FluxMinimap.IsEmbedded and FluxMinimap:IsEmbedded() then
                    FluxMinimap:RestoreToNormal()
                end

                -- Cancel work for the old mode before showing the new one.
                CancelTabWork(tab)
                if tab.statusText then tab.statusText:Hide() end
                if tabs["Map"].onShow then
                    tabs["Map"].onShow(tabs["Map"])
                end
                
                -- Update objective tracker only when Map/Minimap mode actually
                -- changed. Unchanged docks are a no-op inside UpdateQuestTrackerPosition.
                if FluxMinimap and FluxMinimap.UpdateQuestTrackerPosition then
                    TabAfter(tab, "tracker", 0.1, function() FluxMinimap:UpdateQuestTrackerPosition() end)
                end

                -- Save the new state
                SaveTabState()
            else
                -- Switch to Map tab (don't change mode, just switch tabs)
                FluxWindowFrame:SwitchToTab("Map")
            end
        elseif name == "Meter" then
            -- Special behavior for Meter tab: cycle between layout presets on left-click
            if activeTab == "Meter" then
                ApplyMeterCycleLayout()
            else
                FluxWindowFrame:SwitchToTab("Meter")
            end
        else
            -- Normal tab switching for other tabs
            FluxWindowFrame:SwitchToTab(name)
        end
    end)

    -- Mouseover effects
    tab.button:SetScript("OnEnter", function(self)
        if activeTab ~= name then
            if self.highlightLeft then self.highlightLeft:Show() end
            if self.highlightMiddle then self.highlightMiddle:Show() end
            if self.highlightRight then self.highlightRight:Show() end
        end
        
        -- Show tooltip if provided
        if tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(name) -- Title is tab name
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true) -- Description, white text, wrapping
            GameTooltip:Show()
        end
    end)

    tab.button:SetScript("OnLeave", function(self)
        if activeTab ~= name then
            if self.highlightLeft then self.highlightLeft:Hide() end
            if self.highlightMiddle then self.highlightMiddle:Hide() end
            if self.highlightRight then self.highlightRight:Hide() end
        end
        
        if tooltipText then
            GameTooltip:Hide()
        end
    end)

    -- Add to tabs table
    tabs[name] = tab

    -- Update container width
    local totalWidth = 0
    for _, t in ipairs(tabList) do
        totalWidth = totalWidth + t.button:GetWidth() - 4 -- Account for overlap
    end
    tabContainer:SetWidth(totalWidth + 4)

    -- If this is the first tab, make it active (but don't override saved state)
    if tabIndex == 1 and not activeTab then
        self:SwitchToTab(name)
    end

    return tab
end

--- Switch to a specific tab
-- @param tabName The name of the tab to switch to
function FluxWindowFrame:SwitchToTab(tabName)
    if not tabs[tabName] or InCombatLockdown() then
        return
    end
    if not self:IsTabEnabled(tabName) then
        return
    end

    -- Clear ALL highlights from ALL tabs first
    for _, tab in ipairs(tabList) do
        -- Hide all active textures
        if tab.button.activeLeft then tab.button.activeLeft:Hide() end
        if tab.button.activeMiddle then tab.button.activeMiddle:Hide() end
        if tab.button.activeRight then tab.button.activeRight:Hide() end
        -- Hide all highlight textures
        if tab.button.highlightLeft then tab.button.highlightLeft:Hide() end
        if tab.button.highlightMiddle then tab.button.highlightMiddle:Hide() end
        if tab.button.highlightRight then tab.button.highlightRight:Hide() end
    end

    -- Hosted modules retain their frames, scripts and regions across tab switches.
    if activeTab and tabs[activeTab] then
        local previous = tabs[activeTab]
        CancelTabWork(previous)
        if previous.onHide then
            previous.onHide(previous)
        end
        previous.content:Hide()
    end

    -- Show new tab
    activeTab = tabName
    -- Re-setup the content area for the new tab
    tabs[activeTab].content:SetAllPoints(windowFrame.Content)
    tabs[activeTab].content:Show()
    if tabs[activeTab].statusText then tabs[activeTab].statusText:Hide() end
    UpdateTabVisualState(tabs[activeTab].button, true)
    if tabs[activeTab].onShow then
        tabs[activeTab].onShow(tabs[activeTab])
    end

    -- Save tab state
    SaveTabState()
    
    -- Tracker dock: tab switches do not change window size or embed mode, so
    -- UpdateQuestTrackerPosition is a no-op (no ClearAllPoints / quest rebuild).
    -- Binding-tab SetSize and Map/Minimap embed still apply when geometry changes.
    if FluxMinimap and FluxMinimap.UpdateQuestTrackerPosition then
        TabAfter(tabs[activeTab], "tracker", 0.1, function() FluxMinimap:UpdateQuestTrackerPosition() end)
    end
end

--- Remove a tab
-- @param tabName The name of the tab to remove
function FluxWindowFrame:RemoveTab(tabName)
    if not tabs[tabName] then return end

    local tab = tabs[tabName]
    CancelTabWork(tab)

    -- If this tab is active, switch to another tab
    if activeTab == tabName then
        activeTab = nil
        -- Find another tab to switch to
        for name, t in pairs(tabs) do
            if name ~= tabName then
                self:SwitchToTab(name)
                break
            end
        end
    end

    -- Thoroughly clean up and hide tab
    CleanupTabContent(tab)
    tab.button:Hide()
    if tab.onHide then
        tab.onHide(tab)
    end

    -- Remove from tabs tables
    tabs[tabName] = nil

    -- Rebuild strip from saved order / visibility
    self:RepositionTabs()
end

--- Get the content frame for a specific tab
-- @param tabName The name of the tab
function FluxWindowFrame:GetTabContent(tabName)
    return tabs[tabName] and tabs[tabName].content or nil
end

--- Get the currently active tab name
function FluxWindowFrame:GetActiveTab()
    return activeTab
end

-- ---------------------------------------------------------------------------
-- Tab order / visibility (CharSavedVars)
-- ---------------------------------------------------------------------------
local DEFAULT_TAB_ORDER = { "Map", "Meter", "Respec", "Buttons" }

local function MeterTabIsHosted()
    return ResolveMeterSystem() ~= nil
end

local function FilterUnavailableTabs(order)
    local hosted = MeterTabIsHosted()
    local out = {}
    if type(order) ~= "table" then
        return out
    end
    for _, name in ipairs(order) do
        if name ~= "Meter" or hosted then
            out[#out + 1] = name
        end
    end
    return out
end

local function CopyStringList(src)
    local out = {}
    if type(src) ~= "table" then return out end
    for i, v in ipairs(src) do
        if type(v) == "string" then
            out[#out + 1] = v
        end
    end
    return out
end

local function EnsureTabConfigDB()
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    local sv = _FluxUI_CharSavedVars
    if type(sv.fluxWindowTabOrder) ~= "table" or #sv.fluxWindowTabOrder == 0 then
        sv.fluxWindowTabOrder = CopyStringList(DEFAULT_TAB_ORDER)
    end
    if type(sv.fluxWindowTabEnabled) ~= "table" then
        sv.fluxWindowTabEnabled = {}
    end
    for _, name in ipairs(DEFAULT_TAB_ORDER) do
        if sv.fluxWindowTabEnabled[name] == nil then
            sv.fluxWindowTabEnabled[name] = true
        end
    end
    -- Keep order list complete + de-duplicated.
    local seen = {}
    local cleaned = {}
    for _, name in ipairs(sv.fluxWindowTabOrder) do
        if type(name) == "string" and not seen[name] then
            seen[name] = true
            cleaned[#cleaned + 1] = name
        end
    end
    for _, name in ipairs(DEFAULT_TAB_ORDER) do
        if not seen[name] then
            cleaned[#cleaned + 1] = name
            seen[name] = true
        end
    end
    sv.fluxWindowTabOrder = cleaned
    return sv
end

function FluxWindowFrame:GetManagedTabNames()
    return FilterUnavailableTabs(CopyStringList(DEFAULT_TAB_ORDER))
end

function FluxWindowFrame:GetTabOrder()
    local sv = EnsureTabConfigDB()
    return FilterUnavailableTabs(CopyStringList(sv.fluxWindowTabOrder))
end

function FluxWindowFrame:IsTabEnabled(name)
    if not name then return false end
    local sv = EnsureTabConfigDB()
    if sv.fluxWindowTabEnabled[name] == nil then
        return true
    end
    return sv.fluxWindowTabEnabled[name] ~= false
end

function FluxWindowFrame:GetFirstEnabledTab()
    for _, name in ipairs(self:GetTabOrder()) do
        if tabs[name] and self:IsTabEnabled(name) then
            return name
        end
    end
    for name in pairs(tabs) do
        if self:IsTabEnabled(name) then
            return name
        end
    end
    return nil
end

function FluxWindowFrame:CountEnabledTabs()
    local n = 0
    for name in pairs(tabs) do
        if self:IsTabEnabled(name) then
            n = n + 1
        end
    end
    return n
end

--- Rebuild tab button strip from saved order + enabled flags.
function FluxWindowFrame:RepositionTabs()
    if not tabContainer then return end
    local sv = EnsureTabConfigDB()
    local order = sv.fluxWindowTabOrder
    local enabled = sv.fluxWindowTabEnabled

    local newList = {}
    local seen = {}
    for _, name in ipairs(order) do
        local t = tabs[name]
        if t then
            newList[#newList + 1] = t
            seen[name] = true
        end
    end
    for name, t in pairs(tabs) do
        if not seen[name] then
            newList[#newList + 1] = t
            if not enabled[name] then
                enabled[name] = true
            end
            -- Keep extras at end of saved order.
            local found = false
            for _, n in ipairs(order) do
                if n == name then found = true break end
            end
            if not found then
                order[#order + 1] = name
            end
        end
    end
    tabList = newList

    local prevVisible = nil
    local totalWidth = 0
    for i, t in ipairs(tabList) do
        t.index = i
        local on = enabled[t.name] ~= false
        t.button:ClearAllPoints()
        if on then
            t.button:Show()
            if not prevVisible then
                t.button:SetPoint("LEFT", tabContainer, "LEFT")
            else
                t.button:SetPoint("LEFT", prevVisible.button, "RIGHT", -4, 0)
            end
            prevVisible = t
            totalWidth = totalWidth + t.button:GetWidth() - 4
        else
            t.button:Hide()
        end
    end
    tabContainer:SetWidth(math.max(1, totalWidth + 4))

    if activeTab and enabled[activeTab] == false then
        local fallback = self:GetFirstEnabledTab()
        if fallback and not InCombatLockdown() then
            self:SwitchToTab(fallback)
        end
    end
end

function FluxWindowFrame:ApplyTabConfig()
    EnsureTabConfigDB()
    self:RepositionTabs()
    self:ReleaseMinimapEmbedIfMapDisabled()
end

--- When Map tab is off, minimap must not stay embedded in the Flux window.
function FluxWindowFrame:ReleaseMinimapEmbedIfMapDisabled()
    if self:IsTabEnabled("Map") then
        return
    end
    if FluxMinimap and FluxMinimap.IsEmbedded and FluxMinimap:IsEmbedded() then
        if FluxMinimap.RestoreToNormal then
            FluxMinimap:RestoreToNormal()
        elseif FluxMinimap.HideEmbedded then
            FluxMinimap:HideEmbedded()
        end
    end
    if not isMapMode then
        isMapMode = true
        SaveTabState()
        if tabs["Map"] and tabs["Map"].button and tabs["Map"].button.text then
            tabs["Map"].button.text:SetText("Map")
        end
    end
end

function FluxWindowFrame:SetTabEnabled(name, enabled)
    if not name or not tabs[name] then return false end
    local sv = EnsureTabConfigDB()
    enabled = not not enabled
    if not enabled then
        -- Keep at least one visible tab.
        local others = 0
        for tabName in pairs(tabs) do
            if tabName ~= name and sv.fluxWindowTabEnabled[tabName] ~= false then
                others = others + 1
            end
        end
        if others < 1 then
            return false
        end
    end
    sv.fluxWindowTabEnabled[name] = enabled
    self:RepositionTabs()
    if name == "Map" and not enabled then
        self:ReleaseMinimapEmbedIfMapDisabled()
    end
    return true
end

function FluxWindowFrame:MoveTabInOrder(name, delta)
    if type(name) ~= "string" or type(delta) ~= "number" or delta == 0 then
        return false
    end
    local sv = EnsureTabConfigDB()
    local order = sv.fluxWindowTabOrder
    local idx
    for i, n in ipairs(order) do
        if n == name then
            idx = i
            break
        end
    end
    if not idx then
        order[#order + 1] = name
        idx = #order
    end
    local newIdx = idx + delta
    if newIdx < 1 or newIdx > #order then
        return false
    end
    order[idx], order[newIdx] = order[newIdx], order[idx]
    self:RepositionTabs()
    return true
end

--- Replace full tab order (drag/drop). Unknown names ignored; missing managed tabs appended.
function FluxWindowFrame:SetTabOrder(orderList)
    if type(orderList) ~= "table" then
        return false
    end
    local sv = EnsureTabConfigDB()
    local seen = {}
    local cleaned = {}
    for _, name in ipairs(orderList) do
        if type(name) == "string" and not seen[name] then
            seen[name] = true
            cleaned[#cleaned + 1] = name
        end
    end
    for _, name in ipairs(DEFAULT_TAB_ORDER) do
        if not seen[name] then
            cleaned[#cleaned + 1] = name
            seen[name] = true
        end
    end
    for name in pairs(tabs) do
        if not seen[name] then
            cleaned[#cleaned + 1] = name
            seen[name] = true
        end
    end
    sv.fluxWindowTabOrder = cleaned
    self:RepositionTabs()
    return true
end

function FluxWindowFrame:ResetTabConfigDefaults()
    local sv = EnsureTabConfigDB()
    sv.fluxWindowTabOrder = CopyStringList(DEFAULT_TAB_ORDER)
    sv.fluxWindowTabEnabled = {}
    for _, name in ipairs(DEFAULT_TAB_ORDER) do
        sv.fluxWindowTabEnabled[name] = true
    end
    self:RepositionTabs()
end

--- Get full meter layout config for FluxDetails:Embed / FluxBlizzardMeter:Embed.
function FluxWindowFrame:GetMeterLayoutConfig()
    if FluxMeterLayout and FluxMeterLayout.GetWorkingLayout then
        return FluxMeterLayout.GetWorkingLayout()
    end
    if FluxMeterLayout and FluxMeterLayout.IsBlizzardBackend and FluxMeterLayout.IsBlizzardBackend() then
        local T = Enum and Enum.DamageMeterType
        return {
            topSlots = { { kind = "blizzard", damageMeterType = T and T.DamageDone or 0 } },
            bottomSlots = { { kind = "blizzard", damageMeterType = T and T.HealingDone or 2 } },
            topColFracs = { 1 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
        }
    end
    return {
        topSlots = { { kind = "attr", attribute = 1, subAttribute = 1 } },
        bottomSlots = { { kind = "attr", attribute = 2, subAttribute = 1 } },
        topColFracs = { 1 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
    }
end

function FluxWindowFrame:GetMeterPresetIndex()
    local id = FluxMeterLayout and FluxMeterLayout.GetActiveLayoutId and FluxMeterLayout.GetActiveLayoutId()
    local n = id and id:match("^builtin:(%d+)$")
    return tonumber(n) or 1
end

function FluxWindowFrame:SetMeterPresetIndex(index, reembed)
    if not FluxMeterLayout then return end
    FluxMeterLayout.ApplyBuiltin(index)
    if reembed and FluxMeterLayout.ReembedQuiet then
        FluxMeterLayout.ReembedQuiet()
    end
end

-------------------------------------------------------------------------------
-- TEMPORARY SLASH COMMANDS FOR TESTING
-------------------------------------------------------------------------------

SLASH_FLUXWINDOW1 = "/fluxwindow"
SLASH_FLUXWINDOW2 = "/fw"
SlashCmdList["FLUXWINDOW"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    local cmd = args[1]

    if cmd == "show" then
        FluxWindowFrame:Show()
    elseif cmd == "hide" then
        FluxWindowFrame:Hide()
    elseif cmd == "toggle" then
        FluxWindowFrame:Toggle()
    elseif cmd == "tab" and args[2] then
        if not InCombatLockdown() then
            FluxWindowFrame:SwitchToTab(args[2])
        end
    elseif cmd == "addtab" and args[2] then
        local tabName = args[2]
        FluxWindowFrame:AddTab(tabName, function(tab)
            local text = tab.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("CENTER", tab.content, "CENTER")
            text:SetText(tabName .. " Tab")
            text:SetTextColor(1, 1, 1, 1)
        end)
    elseif cmd == "removetab" and args[2] then
        FluxWindowFrame:RemoveTab(args[2])
    else
    end
end

-- Initialize the frame when addon loads
local frame = CreateFrame("Frame")
local initialized = false
local watcherFrame = CreateFrame("Frame")
local checkCount = 0
local MAX_CHECKS = 30 -- Safety limit: ~0.5 seconds at 60fps
local pendingInitialTab
local pendingTabConfig = false

local function RegisterMeterTab()
    if tabs["Meter"] or not windowFrame then return false end
    -- Meter tab only when Details is loaded XOR this client ships Blizzard_DamageMeter.
    local meterSystem = ResolveMeterSystem()

    -- Only add the Meter tab if we have a valid meter system
    if meterSystem then
        FluxWindowFrame:AddTab("Meter", function(tab)
            -- Re-resolve on show so Details vs Blizzard stays exclusive.
            local meterSystem = ResolveMeterSystem()
            -- Meter tab content - embed the appropriate damage meter
            if meterSystem == "Details" then
                -- Priority 1: Use Details addon
                if FluxDetails and FluxDetails.Embed then
                    -- Retry until Details StartMeUp finishes; Embed creates missing windows.
                    local function TryEmbedDetails(attempt)
                        attempt = attempt or 1
                        local maxAttempts = 30 -- 6 seconds (30 * 0.2s)

                        local isDetailsReady = FluxDetails.IsDetailsUIReady and FluxDetails:IsDetailsUIReady()

                        if isDetailsReady then
                            local layoutConfig = FluxWindowFrame:GetMeterLayoutConfig()
                            FluxDetails:Embed(windowFrame, layoutConfig)
                            tab.content:Hide()
                            return
                        end

                        -- Not ready yet, show loading message and retry
                        if attempt < maxAttempts then
                            tab.content:Show()

                            local meterText = GetTabStatusText(tab)

                            meterText:SetText("Details! Meter\n(Initializing... " .. attempt .. "/" .. maxAttempts .. ")")
                            meterText:SetTextColor(1, 1, 0.5, 1)

                            TabAfter(tab, "meter-embed", 0.2, function()
                                TryEmbedDetails(attempt + 1)
                            end)
                        else
                            -- Failed after all attempts
                            tab.content:Show()
                            local meterText = GetTabStatusText(tab)
                            meterText:SetText("Details! Meter\n(Failed to Initialize)")
                            meterText:SetTextColor(1, 0.2, 0.2, 1)
                        end
                    end

                    -- Start embedding attempt
                    TryEmbedDetails(1)
                else
                    -- Fallback if FluxDetails is not available yet
                    tab.content:Show()
                    local meterText = GetTabStatusText(tab)
                    meterText:SetText("Details! Meter\n(Loading...)")
                    meterText:SetTextColor(1, 1, 1, 1)
                end
            elseif meterSystem == "BlizzardMeter" then
                -- Priority 2: Use Blizzard's native damage meter when Details is absent
                if FluxBlizzardMeter and FluxBlizzardMeter.Embed then
                    -- Check if meter is already embedded (from previous tab switch or startup)
                    if FluxBlizzardMeter:IsEmbedded() then
                        -- Already embedded - refresh layout then show
                        local layoutConfig = FluxWindowFrame:GetMeterLayoutConfig()
                        FluxBlizzardMeter:Embed(windowFrame.Content, layoutConfig)
                        FluxBlizzardMeter:Show()
                        tab.content:Hide()
                    else
                        -- Not embedded yet - need to embed it
                        -- Retry logic for startup case
                        local function TryEmbed(attempt)
                            attempt = attempt or 1
                            local maxAttempts = 15 -- 3 seconds

                            -- Check if meter is ready
                            if FluxBlizzardMeter.IsMeterReady and FluxBlizzardMeter:IsMeterReady() then
                                local layoutConfig = FluxWindowFrame:GetMeterLayoutConfig()
                                local success = FluxBlizzardMeter:Embed(windowFrame.Content, layoutConfig)
                                if success then
                                    if Flux and Flux.Startup then Flux.Startup.Mark("optional.BlizzardMeter.embedded") end
                                    tab.content:Hide()
                                    return
                                end
                            end

                            -- Not ready yet, show loading message and retry
                            if attempt < maxAttempts then
                                tab.content:Show()

                                local meterText = GetTabStatusText(tab)

                                meterText:SetText("Blizzard Damage Meter\n(Initializing... " .. attempt .. "/" .. maxAttempts .. ")")
                                meterText:SetTextColor(1, 1, 0.5, 1)

                                TabAfter(tab, "meter-embed", 0.2, function()
                                    TryEmbed(attempt + 1)
                                end)
                            else
                                -- Failed after all attempts
                                tab.content:Show()
                                local meterText = GetTabStatusText(tab)
                                meterText:SetText("Blizzard Damage Meter\n(Failed to Initialize)")
                                meterText:SetTextColor(1, 0.2, 0.2, 1)
                            end
                        end

                        -- Start embedding attempt
                        TryEmbed(1)
                    end
                else
                    -- Fallback if FluxBlizzardMeter is not available
                    tab.content:Show()
                    local meterText = GetTabStatusText(tab)
                    meterText:SetText("Blizzard Damage Meter\n(Not Available)")
                    meterText:SetTextColor(1, 0.5, 0.2, 1)
                end
            end
        end, function(tab)
            -- Never leave both backends visible.
            if FluxMeterLayout and FluxMeterLayout.CancelPendingWork then FluxMeterLayout.CancelPendingWork() end
            if FluxDetails and FluxDetails.Hide then
                FluxDetails:Hide()
            end
            if FluxBlizzardMeter and FluxBlizzardMeter.Hide then
                FluxBlizzardMeter:Hide()
            end
            tab.content:Show()
        end, "Damage/Healing Meters\nLeft-click: cycle layouts. Right-click: FluxWindow options.\nMiddle-click: reset all meter data (out of combat).")
    end

    return tabs["Meter"] ~= nil
end

-- Function to initialize the window frame and tabs
local function InitializeWindowFrame()
    if initialized then return true end

    -- Core's HUD barrier follows VARIABLES_LOADED on Forever, including gamepad.
    if Flux and Flux.AfterLogin and not Flux.loggedIn then return false end
    
    -- Initialize saved variables if they don't exist
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end

    -- Load saved tab state before creating tabs
    LoadTabState()

    -- Pre-create the frame so it's ready to use
    FluxWindowFrame:GetFrame()

    -- Add the three main tabs
    FluxWindowFrame:AddTab("Map", function(tab)
            -- Map tab content
            -- The tab and its fallback label persist between visits.
            if tab.statusText then tab.statusText:Hide() end

            -- Check if we're in Map mode (battlefield map) or Minimap mode
            if isMapMode then
                -- Map mode: Show Blizzard's battlefield map
                if FluxBattlefieldMap then
                    -- ALWAYS cleanup and reinitialize to ensure proper scaling
                    -- This fixes issues when logging in on Map tab or switching back from other tabs
                    if FluxBattlefieldMap:IsActive() then
                        FluxBattlefieldMap:Hide()
                        FluxBattlefieldMap:Cleanup()
                    end
                    
                    -- Parent to the main window frame to fill the entire area
                    local success = FluxBattlefieldMap:Initialize(windowFrame)
                    if success then
                        FluxBattlefieldMap:Show()
                        -- Hide the tab content since we're using the full window
                        tab.content:Hide()
                        
                        -- Enforce scaling with multiple delays to handle async operations
                        -- This guarantees proper scale even if Blizzard's code resets it
                        local function EnforceScaling()
                            if FluxBattlefieldMap and FluxBattlefieldMap:IsActive() then
                                FluxBattlefieldMap:UpdateLayout()
                            end
                        end
                        TabAfter(tab, "map-scale-early", 0.1, EnforceScaling)
                        TabAfter(tab, "map-scale-mid", 0.5, EnforceScaling)
                        TabAfter(tab, "map-scale-final", 1.0, EnforceScaling)
                    else
                        -- Fallback if initialization failed
                        tab.content:Show()
                        local text = GetTabStatusText(tab)
                        text:SetPoint("CENTER", tab.content, "CENTER")
                        text:SetText("Battlefield Map\n(Init Failed)")
                        text:SetTextColor(1, 0.2, 0.2, 1)
                    end
                else
                    -- Fallback if FluxBattlefieldMap is not available
                    tab.content:Show()
                    local text = GetTabStatusText(tab)
                    text:SetPoint("CENTER", tab.content, "CENTER")
                    text:SetText("FluxBattlefieldMap\n(Not Available)")
                    text:SetTextColor(1, 0.5, 0.2, 1)
                end
            else
                -- Minimap mode - hide battlefield map and embed the actual Minimap
                if FluxBattlefieldMap and FluxBattlefieldMap:IsActive() then
                    FluxBattlefieldMap:Hide()
                    FluxBattlefieldMap:Cleanup()  -- Fully remove it
                end

                -- Check if minimap is already embedded (returning to tab)
                if FluxMinimap and FluxMinimap.IsEmbedded and FluxMinimap:IsEmbedded() then
                    -- Just show it again
                    FluxMinimap:ShowEmbedded()
                    tab.content:Hide()
                elseif FluxMinimap and FluxMinimap.EmbedInFrame then
                    -- Embed the Minimap into this window
                    local success = FluxMinimap:EmbedInFrame(windowFrame)
                    if success then
                        -- Hide tab content since minimap is now occupying the space
                        tab.content:Hide()
                    else
                        -- Fallback if embedding failed
                        tab.content:Show()
                        local text = GetTabStatusText(tab)
                        text:SetPoint("CENTER", tab.content, "CENTER")
                        text:SetText("Minimap\n(Embed Failed)")
                        text:SetTextColor(1, 0.2, 0.2, 1)
                    end
                else
                    -- Fallback if FluxMinimap is not available
                    tab.content:Show()
                    local text = GetTabStatusText(tab)
                    text:SetPoint("CENTER", tab.content, "CENTER")
                    text:SetText("FluxMinimap\n(Not Available)")
                    text:SetTextColor(1, 0.5, 0.2, 1)
                end
            end
        end, function(tab)
            -- Cleanup when hiding map tab
            -- Just hide the embedded minimap (don't restore to normal position)
            if FluxMinimap and FluxMinimap.HideEmbedded then
                FluxMinimap:HideEmbedded()
            end
            -- Hide the minimap buttons
            if FluxMinimapButtons and FluxMinimapButtons.OnEmbedStateChanged then
                FluxMinimapButtons:OnEmbedStateChanged(false)
            end
            -- Clean up battlefield map if active
            if FluxBattlefieldMap and FluxBattlefieldMap:IsActive() then
                FluxBattlefieldMap:Hide()
                FluxBattlefieldMap:Cleanup()
            end
            -- Show tab content again
            tab.content:Show()
        end, "Battlezone Map\nClick again to switch between Map and Minimap modes.")

    RegisterMeterTab()

        -- Respec tab (3rd, after Map and Meter). Registered via FluxRespec_Register so UI lives in Respec/.
        -- Tall SoD rune flyout: FluxRespec adds temporary bottom inset on its body scroll (FluxRespec_UI)
        -- so the window content can scroll; the flyout itself is RuneReminder-style (no inner scrollbar).
        if _G.FluxRespec and _G.FluxRespec.Register and _G.FluxRespec.Register.AddTab then
            _G.FluxRespec.Register.AddTab()
        end

        -- Buttons tab (4th, after Respec)
        FluxWindowFrame:AddTab("Buttons", function(tab)
            -- Buttons tab content - Extra Button System
            if FluxExtraButtons and FluxExtraButtons.UI then
                -- Attach the Extra Buttons UI to this tab's content frame
                FluxExtraButtons.UI:AttachTo(tab.content)
                -- Explicitly show the UI (visibility is controlled by these callbacks, not HookScript)
                FluxExtraButtons.UI:Show()
            else
                -- Fallback if FluxExtraButtons is not available
                local buttonsText = GetTabStatusText(tab)
                buttonsText:SetPoint("CENTER", tab.content, "CENTER")
                buttonsText:SetText("Extra Buttons\n(Module Not Found)")
                buttonsText:SetTextColor(1, 0.5, 0.2, 1)
            end
        end, function(tab)
            -- Cleanup when hiding buttons tab - explicitly hide ExtraButtons
            if FluxExtraButtons and FluxExtraButtons.UI then
                FluxExtraButtons.UI:Hide()
            end
        end, "Extra Buttons")

    -- Apply saved tab order / on-off before choosing the active tab.
    if tabs["Meter"] and not MeterTabIsHosted() then
        FluxWindowFrame:RemoveTab("Meter")
    end
    FluxWindowFrame:ApplyTabConfig()

    -- After all tabs are created, switch to the saved active tab immediately (no delay)
    -- Find the best tab to switch to
    local targetTab = activeTab or "Map"

    -- If the saved tab doesn't exist or is disabled, find the first available enabled tab
    if not tabs[targetTab] or not FluxWindowFrame:IsTabEnabled(targetTab) then
        targetTab = FluxWindowFrame:GetFirstEnabledTab() or "Map"
        if not tabs[targetTab] then
            local availableTabs = {"Map", "Meter", "Respec", "Buttons"}
            for _, tabName in ipairs(availableTabs) do
                if tabs[tabName] and FluxWindowFrame:IsTabEnabled(tabName) then
                    targetTab = tabName
                    break
                end
            end
        end
    end

    -- Switch once to the saved tab; FluxDetails post-login coordinator handles Details embed.
    if tabs[targetTab] and not InCombatLockdown() then
        FluxWindowFrame:SwitchToTab(targetTab)
    else
        pendingInitialTab = targetTab
    end

    -- Update the Map tab button text to reflect current mode
    if tabs["Map"] and tabs["Map"].button then
        tabs["Map"].button.text:SetText(isMapMode and "Map" or "Minimap")
    end
    
    -- If we're in Minimap mode but NOT on the Map tab, 
    -- embed the minimap before hiding it, only while the Map tab is enabled.
    if FluxWindowFrame:IsTabEnabled("Map") and not isMapMode and targetTab ~= "Map" then
        if FluxMinimap and FluxMinimap.EmbedInFrame and not InCombatLockdown() then
            FluxMinimap:EmbedInFrame(windowFrame)
            FluxMinimap:HideEmbedded()
        end
    elseif not FluxWindowFrame:IsTabEnabled("Map") then
        FluxWindowFrame:ReleaseMinimapEmbedIfMapDisabled()
    end

    FluxWindowFrame:Show() -- Start visible so you can see it
    
    initialized = true
    watcherFrame:SetScript("OnUpdate", nil) -- Stop watching
    
    return true
end

-- Try to initialize immediately
local function TryInitialize(force)
    if initialized then return true end
    
    -- Check if dependencies are ready (FluxBorder is optional, but preferred)
    local isReady = true -- We can initialize without FluxBorder, it's optional
    
    -- If forcing or ready, initialize immediately
    if force or isReady then
        return InitializeWindowFrame()
    end
    
    return false
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event, addon)
    if event == "PLAYER_REGEN_ENABLED" then
        if InCombatLockdown() then return end
        if pendingTabConfig then
            pendingTabConfig = false
            FluxWindowFrame:ApplyTabConfig()
        end
        if pendingInitialTab then
            local targetTab = pendingInitialTab
            pendingInitialTab = nil
            FluxWindowFrame:ApplyTabConfig()
            FluxWindowFrame:SwitchToTab(targetTab)
        end
        local tab = activeTab and tabs[activeTab]
        if tab and tab.combatWork then
            local work = tab.combatWork
            local generation = tab.workGeneration
            tab.combatWork = nil
            for _, callback in pairs(work) do
                if activeTab ~= tab.name or tab.workGeneration ~= generation then break end
                callback()
            end
        end
    elseif event == "ADDON_LOADED" and initialized then
        -- Optional backends can arrive after the HUD. Reuse the same tab callback.
        if RegisterMeterTab() then
            if InCombatLockdown() then pendingTabConfig = true
            else FluxWindowFrame:ApplyTabConfig() end
        end
    elseif event == "ADDON_LOADED" and addon == addonName then
        if Flux and Flux.AfterLogin and not Flux.loggedIn then return end
        -- Try immediately first (will initialize if ready)
        if TryInitialize(false) then
            return
        end
        
        -- If not initialized, watch every frame until ready
        checkCount = 0
        watcherFrame:SetScript("OnUpdate", function(self, elapsed)
            checkCount = checkCount + 1
            if TryInitialize(false) or checkCount >= MAX_CHECKS then
                -- If we hit the limit, force initialization
                if checkCount >= MAX_CHECKS and not initialized then
                    TryInitialize(true)
                end
                self:SetScript("OnUpdate", nil)
            end
        end)
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- Double-check saved variables are loaded at PLAYER_LOGIN

        -- DO NOT reload saved vars here as it might overwrite the current state
        -- The vars should already be loaded during ADDON_LOADED

        -- Pre-load BattlefieldMap addon to prevent scaling issues on tab switch
        -- This ensures the frame is initialized early regardless of which tab is active
        local success = false
        if not InCombatLockdown() and C_AddOns and C_AddOns.LoadAddOn then
            success = C_AddOns.LoadAddOn("Blizzard_BattlefieldMap")
        elseif not InCombatLockdown() and LoadAddOn then
            success = LoadAddOn("Blizzard_BattlefieldMap")
        end
        
        -- If loaded successfully, ensure it is hidden initially until needed
        -- This prevents it from popping up in the middle of the screen
        if success and not isMapMode then
            if FluxBattlefieldMap and FluxBattlefieldMap.SecureHideBlizzardMap then
                FluxBattlefieldMap:SecureHideBlizzardMap()
            end
        end
        
        -- Also hide BattlefieldMapTab immediately if FluxBattlefieldMap is available
        -- This ensures instant removal even if the addon was already loaded
        if FluxBattlefieldMap and FluxBattlefieldMap.HideBattlefieldMapTabInstantly then
            FluxBattlefieldMap.HideBattlefieldMapTabInstantly()
        end
        
        -- Also try to initialize if not already done
        if not initialized then
            if TryInitialize(false) then
                return
            end
            
            -- If not initialized, watch every frame until ready
            checkCount = 0
            watcherFrame:SetScript("OnUpdate", function(self, elapsed)
                checkCount = checkCount + 1
                if TryInitialize(false) or checkCount >= MAX_CHECKS then
                    -- If we hit the limit, force initialization
                    if checkCount >= MAX_CHECKS and not initialized then
                        TryInitialize(true)
                    end
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end
    end
end)

if Flux and Flux.AfterLogin then
    Flux.AfterLogin(function() TryInitialize(false) end)
end

function FluxWindowFrame_RefreshTabAccent()
    local r, g, b = 0.5, 0.5, 0.5
    if FluxBorder and FluxBorder.GetThemedVertexRGB then
        r, g, b = FluxBorder:GetThemedVertexRGB()
    else
        local _, classFilename = UnitClass("player")
        local color = RAID_CLASS_COLORS[classFilename]
        if color then r, g, b = color.r, color.g, color.b end
    end
    for _, tab in ipairs(tabList) do
        local btn = tab.button
        if btn then
            tab.selectedColorTable = { r = r, g = g, b = b }
            if btn.activeLeft then btn.activeLeft:SetVertexColor(r, g, b, 1.0) end
            if btn.activeMiddle then btn.activeMiddle:SetVertexColor(r, g, b, 1.0) end
            if btn.activeRight then btn.activeRight:SetVertexColor(r, g, b, 1.0) end
            if btn.highlightLeft then btn.highlightLeft:SetVertexColor(r, g, b, 0.9) end
            if btn.highlightMiddle then btn.highlightMiddle:SetVertexColor(r, g, b, 0.9) end
            if btn.highlightRight then btn.highlightRight:SetVertexColor(r, g, b, 0.9) end
        end
    end
end


