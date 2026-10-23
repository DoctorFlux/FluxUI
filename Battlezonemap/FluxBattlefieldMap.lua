-- FluxBattlefieldMap.lua
-- Integration for Blizzard's Battlefield Map into FluxWindowFrame

local addonName, addonTable = ...

-- Create the public API
FluxBattlefieldMap = {}

local API = addonTable and addonTable.API

local function IsPostDFClient()
    if API and API.isPostDF ~= nil then
        return API.isPostDF
    end
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return true
    end
    return false
end

-- Configuration
local CONFIG = {
    -- Default scaling factors for pre-Dragonflight clients
    SCALE_X = 1,  -- From the old BattleZoneMap.lua working value
    SCALE_Y = 1,
    -- Frame strata levels for proper layering
    MAP_STRATA = "BACKGROUND",
    MAP_LEVEL = 2, -- Above backdrop (level 1) but below border (MEDIUM:10)
}

-- Internal state
local state = {
    mapFrame = nil,
    parentFrame = nil,
    isActive = false,
    isOlderClient = nil,
    tabHidden = false,
    embedPending = false,
    fluxPermitHide = false,
}

local layoutCache = {
    scale = nil,
    parentFrame = nil,
    layoutAnchored = false,
}

local SCALE_EPSILON = 0.001
local LAYOUT_DRIVER_INTERVAL = 0.5
local LAYOUT_STABLE_TICKS_TO_STOP = 3
local layoutDriver = CreateFrame("Frame")
layoutDriver:Hide()
local layoutDriverElapsed = 0
local layoutStableTicks = 0

local ApplyMapScaling
local StartLayoutDriver
local ApplyMapSetMapIDSilent
local FinishMapIDTransition

-- Transparent overlay: blocks mouse from reaching tainted map POI pins during combat
local combatMouseBlocker = CreateFrame("Frame", "FluxBattlefieldMapCombatBlocker", UIParent)
combatMouseBlocker:SetFrameStrata("MEDIUM")
combatMouseBlocker:SetFrameLevel(5)
combatMouseBlocker:EnableMouse(true)
combatMouseBlocker:SetPropagateMouseClicks(false)
combatMouseBlocker:SetPropagateMouseMotion(false)
combatMouseBlocker:Hide()

-- Check if we're running on an older client version
local function IsOlderClient()
    if state.isOlderClient == nil then
        -- Check for Dragonflight+ features and API availability
        -- Also check if modern APIs are available
        local hasModernAPIs = (C_AddOns and C_AddOns.IsAddOnLoaded)
        local hasLegacyAPIs = (MapCanvasMixin ~= nil and MapCanvasFrameTemplate ~= nil)
        state.isOlderClient = not hasModernAPIs and hasLegacyAPIs
    end
    return state.isOlderClient
end

-- Get Blizzard's BattlefieldMap frame, loading the addon if necessary
local function GetBlizzardBattlefieldMap()
    -- Ensure Blizzard_BattlefieldMap addon is loaded
    -- Use modern API for post-DF compatibility
    local isLoaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        isLoaded = C_AddOns.IsAddOnLoaded("Blizzard_BattlefieldMap")
    elseif IsAddOnLoaded then
        isLoaded = IsAddOnLoaded("Blizzard_BattlefieldMap")
    end

    if not isLoaded then
        if C_AddOns and C_AddOns.LoadAddOn then
            local success = C_AddOns.LoadAddOn("Blizzard_BattlefieldMap")
            if not success then
            end
        elseif LoadAddOn then
            local success = LoadAddOn("Blizzard_BattlefieldMap")
            if not success then
            end
        else
            return nil
        end
    end

    -- Try to get the battlefield map frame
    local mapFrame = _G["BattlefieldMapFrame"]
    if not mapFrame then
        return nil
    end

    return mapFrame
end

-- Combat-safe queue for positioning operations
local positionUpdateQueue = {}

-- Hide BattlefieldMapTab off-screen (keep real Blizzard tab; no global/method replacement)
local function HideBattlefieldMapTabInstantly()
    local tab = _G["BattlefieldMapTab"]
    if not tab then
        return
    end
    if not state.tabHidden then
        state.tabHidden = true
    end
    tab:Hide()
    tab:EnableMouse(false)
    tab:SetAlpha(0)
    tab:ClearAllPoints()
    tab:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -500, -500)
end

local function RestoreBattlefieldMapTab()
    local tab = _G["BattlefieldMapTab"]
    if not tab or not state.tabHidden then
        return
    end
    state.tabHidden = false
    tab:EnableMouse(true)
    tab:SetAlpha(0)
    tab:ClearAllPoints()
    tab:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
end

-- Export function for external use
FluxBattlefieldMap.HideBattlefieldMapTabInstantly = HideBattlefieldMapTabInstantly

--- Blizzard's BattlefieldMap OnUpdate polls the cursor every frame to fade a tab
--- Flux hides. Keep MapCanvas pin updates. Skip the tab poll on every client
--- that has MapCanvasMixin. Leave the original script alone when it does not.
local function InstallLightweightMapUpdate(mapFrame)
    if not mapFrame or mapFrame._fluxLiteUpdate then
        return
    end
    if not (MapCanvasMixin and MapCanvasMixin.OnUpdate) then
        return
    end
    mapFrame._fluxLiteUpdate = true
    mapFrame:SetScript("OnUpdate", function(self, elapsed)
        MapCanvasMixin.OnUpdate(self, elapsed)
    end)
end

function FluxBattlefieldMap:SecureHideBlizzardMap()
    local map = _G.BattlefieldMapFrame
    if map then
        map:Hide()
    end
end

-- Event frame for instant tab hiding
local tabHiderFrame = CreateFrame("Frame")
tabHiderFrame:RegisterEvent("ADDON_LOADED")
tabHiderFrame:RegisterEvent("PLAYER_LOGIN")
tabHiderFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
tabHiderFrame:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" and addon == "Blizzard_BattlefieldMap" then
        -- Hide tab immediately when Blizzard addon loads
        HideBattlefieldMapTabInstantly()
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- Also try to hide on login/reload (in case addon was already loaded)
        HideBattlefieldMapTabInstantly()
        
        -- Use watcher to catch tab if it appears later
        local tabWatcher = CreateFrame("Frame")
        local tabCheckCount = 0
        local MAX_TAB_CHECKS = 30  -- Increased to catch tab that might appear later
        tabWatcher:SetScript("OnUpdate", function(watcher, elapsed)
            tabCheckCount = tabCheckCount + 1
            HideBattlefieldMapTabInstantly()
            if tabCheckCount >= MAX_TAB_CHECKS or state.tabHidden then
                watcher:SetScript("OnUpdate", nil)
            end
        end)
    end
end)

-- Try to hide tab immediately on file load (in case addon was already loaded)
-- Use watcher to catch it when it becomes available
local initialTabWatcher = CreateFrame("Frame")
local initialTabCheckCount = 0
local MAX_INITIAL_CHECKS = 50  -- Check for up to ~0.8 seconds
initialTabWatcher:SetScript("OnUpdate", function(self, elapsed)
    initialTabCheckCount = initialTabCheckCount + 1
    HideBattlefieldMapTabInstantly()
    if initialTabCheckCount >= MAX_INITIAL_CHECKS or state.tabHidden then
        self:SetScript("OnUpdate", nil)
    end
end)

-- Anchor map to FluxWindowFrame without reparenting (keeps Blizzard frame hierarchy untainted)
-- IMPORTANT: Uses single-anchor positioning (CENTER) to avoid conflicts with scale
local function SetupMapParenting(mapFrame, parentFrame)
    if not mapFrame or not parentFrame then return end

    if InCombatLockdown() then
        table.insert(positionUpdateQueue, {mapFrame, parentFrame, "setup"})
        return
    end

    if mapFrame:GetParent() ~= UIParent then
        mapFrame:SetParent(UIParent)
    end

    layoutCache.layoutAnchored = false
    mapFrame:ClearAllPoints()
    mapFrame:SetPoint("CENTER", parentFrame, "CENTER", 0, -2)
    mapFrame:SetFrameStrata(CONFIG.MAP_STRATA)
    mapFrame:SetFrameLevel(CONFIG.MAP_LEVEL)
    if state.isActive then
        mapFrame:Show()
    end
    layoutCache.layoutAnchored = true
    layoutCache.parentFrame = parentFrame
end

local function ComputeTargetScale()
    local shouldScale = false
    if FLUX_API and FLUX_API.battlefieldMapScalingEnabled then
        shouldScale = true
    elseif FluxWindowFrame then
        shouldScale = true
    end

    if shouldScale and FluxWindowFrame and FluxWindowFrame.WINDOW_WIDTH and FluxWindowFrame.WINDOW_HEIGHT then
        local windowWidth = FluxWindowFrame.WINDOW_WIDTH
        local windowHeight = FluxWindowFrame.WINDOW_HEIGHT
        local widthScale = windowWidth / 300.0
        local heightScale = windowHeight / 200.0
        return math.min(widthScale, heightScale)
    end

    return CONFIG.SCALE_X
end

local function IsLayoutCurrent(mapFrame)
    if not mapFrame or not state.parentFrame then
        return false
    end

    local targetScale = ComputeTargetScale()
    if math.abs(mapFrame:GetScale() - targetScale) > SCALE_EPSILON then
        return false
    end
    if mapFrame:GetParent() ~= UIParent then
        return false
    end
    if mapFrame:GetFrameStrata() ~= CONFIG.MAP_STRATA then
        return false
    end
    if mapFrame:GetFrameLevel() ~= CONFIG.MAP_LEVEL then
        return false
    end
    if layoutCache.parentFrame ~= state.parentFrame or not layoutCache.layoutAnchored then
        return false
    end

    return true
end

local function InvalidateLayoutCache()
    layoutCache.scale = nil
    layoutCache.parentFrame = nil
    layoutCache.layoutAnchored = false
end

-- Apply scaling to the map (combat-safe, idempotent unless forceReset)
ApplyMapScaling = function(mapFrame, scaleX, scaleY, forceReset)
    if not mapFrame then
        return false
    end

    if not forceReset and IsLayoutCurrent(mapFrame) then
        return false
    end

    local targetScale = ComputeTargetScale()
    local currentScale = mapFrame:GetScale()

    if forceReset then
        mapFrame:SetScale(1.0)
        currentScale = 1.0
    end

    if math.abs(currentScale - targetScale) > SCALE_EPSILON then
        mapFrame:SetScale(targetScale)
    end

    if state.parentFrame then
        if InCombatLockdown() then
            table.insert(positionUpdateQueue, {mapFrame, state.parentFrame, "reposition"})
        elseif forceReset or not layoutCache.layoutAnchored or layoutCache.parentFrame ~= state.parentFrame then
            mapFrame:ClearAllPoints()
            mapFrame:SetPoint("CENTER", state.parentFrame, "CENTER", 0, -2)
            layoutCache.layoutAnchored = true
            layoutCache.parentFrame = state.parentFrame
        end
    end

    layoutCache.scale = targetScale
    return true
end

-- Hide Blizzard's default UI elements
local function HideBlizzardUIBorder(mapFrame)
    if not mapFrame then return end

    -- Tab is already completely removed in Initialize(), no need to hide it here

    -- Hide border pieces
    if mapFrame.BorderFrame then
        local bf = mapFrame.BorderFrame
        if bf.TopLeft then bf.TopLeft:Hide() end
        if bf.Top then bf.Top:Hide() end
        if bf.TopRight then bf.TopRight:Hide() end
        if bf.Right then bf.Right:Hide() end
        if bf.BottomRight then bf.BottomRight:Hide() end
        if bf.Bottom then bf.Bottom:Hide() end
        if bf.BottomLeft then bf.BottomLeft:Hide() end
        if bf.Left then bf.Left:Hide() end
        if bf.CloseButton then bf.CloseButton:Hide() end
        if bf.CloseButtonBorder then bf.CloseButtonBorder:Hide() end  -- For older clients
    end
end

-- Show Blizzard's default UI elements (for cleanup)
local function ShowBlizzardUIBorder(mapFrame)
    if not mapFrame then return end

    -- Tab will be restored in Cleanup(), no need to show it here

    -- Show border pieces
    if mapFrame.BorderFrame then
        local bf = mapFrame.BorderFrame
        if bf.TopLeft then bf.TopLeft:Show() end
        if bf.Top then bf.Top:Show() end
        if bf.TopRight then bf.TopRight:Show() end
        if bf.Right then bf.Right:Show() end
        if bf.BottomRight then bf.BottomRight:Show() end
        if bf.Bottom then bf.Bottom:Show() end
        if bf.BottomLeft then bf.BottomLeft:Show() end
        if bf.Left then bf.Left:Show() end
        if bf.CloseButton then bf.CloseButton:Show() end
        if bf.CloseButtonBorder then bf.CloseButtonBorder:Show() end
    end
end

-- Refresh map on zone change (File Scope so it can be called from retry logic)
local refreshPending = false
local lastAppliedMapID = nil
local zoneMapRefreshDebouncePending = false
local zoneMapRefreshDeferred = false
local ZONE_MAP_REFRESH_DEBOUNCE_SEC = 0.3

local function GetPlayerDisplayMapID()
    if MapUtil and MapUtil.GetDisplayableMapForPlayer then
        return MapUtil.GetDisplayableMapForPlayer()
    elseif C_Map and C_Map.GetBestMapForUnit then
        return C_Map.GetBestMapForUnit("player")
    elseif GetCurrentMapAreaID then
        return GetCurrentMapAreaID()
    end
    return nil
end

local function GetFallbackWorldMapID()
    if C_Map and C_Map.GetFallbackWorldMapID then
        return C_Map.GetFallbackWorldMapID()
    end
    return nil
end

local function GetCurrentFrameMapID(mapFrame)
    if not mapFrame then
        return nil
    end
    if mapFrame.GetMapID then
        return mapFrame:GetMapID()
    end
    return mapFrame.mapID
end

local function IsWorldFallbackMapID(mapID)
    local fallbackID = GetFallbackWorldMapID()
    return fallbackID and mapID and mapID == fallbackID
end

local function IsWorldZoneTransition(fromMapID, toMapID)
    if not fromMapID or not toMapID or fromMapID == toMapID then
        return false
    end
    return IsWorldFallbackMapID(fromMapID) or IsWorldFallbackMapID(toMapID)
end

local function RefreshMapOnZoneChange()
    -- Don't refresh during combat to avoid protected function calls
    if InCombatLockdown() then
        return
    end

    local mapFrame = state.mapFrame
    if not mapFrame then
        return
    end

    -- NOTE: We no longer suppress PlaySound globally as it causes taint issues
    -- The sounds are minimal and acceptable

    local mapID = GetPlayerDisplayMapID()
    local currentMapID = GetCurrentFrameMapID(mapFrame)
    if mapID and currentMapID and mapID == currentMapID and IsLayoutCurrent(mapFrame) then
        return
    end
    if mapID then
        local changed = ApplyMapSetMapIDSilent(mapFrame, mapID)
        if not changed and currentMapID and mapID ~= currentMapID then
            changed = ApplyMapSetMapIDSilent(mapFrame, mapID, true)
        end

        if changed then
            if state.mapFrame and state.parentFrame then
                ApplyMapScaling(state.mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, false)
            end

            if state.isActive then
                StartLayoutDriver()
            end
        end
    else
        -- Restore immediately if no mapID, BUT STILL APPLY SCALING
        -- This is critical for login/reload when map data might not be ready
        if state.mapFrame and state.parentFrame then
            ApplyMapScaling(state.mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, false)
        end

        if state.isActive and not mapFrame:IsShown() then
            mapFrame:Show()
        end
    end
end

local function FlushDeferredZoneMapRefresh()
    if not zoneMapRefreshDeferred then
        return
    end
    zoneMapRefreshDeferred = false
    RefreshMapOnZoneChange()
end

local function QueueRefreshMapOnZoneChange()
    if FluxBoundaryBurst and FluxBoundaryBurst.ShouldDeferHeavyWork and FluxBoundaryBurst.ShouldDeferHeavyWork() then
        zoneMapRefreshDeferred = true
        return
    end
    if zoneMapRefreshDebouncePending then
        return
    end
    zoneMapRefreshDebouncePending = true
    if C_Timer and C_Timer.After then
        C_Timer.After(ZONE_MAP_REFRESH_DEBOUNCE_SEC, function()
            zoneMapRefreshDebouncePending = false
            RefreshMapOnZoneChange()
        end)
    else
        zoneMapRefreshDebouncePending = false
        RefreshMapOnZoneChange()
    end
end

local function ClearDeferredZoneMapRefresh()
    zoneMapRefreshDeferred = false
end

if FluxBoundaryBurst and FluxBoundaryBurst.RegisterFlushCallback then
    FluxBoundaryBurst.RegisterFlushCallback("BattlefieldMap", FlushDeferredZoneMapRefresh)
    if FluxBoundaryBurst.RegisterClearCallback then
        FluxBoundaryBurst.RegisterClearCallback("BattlefieldMap", ClearDeferredZoneMapRefresh)
    end
end

local DoInitialize

FinishMapIDTransition = function(mapFrame)
    if not mapFrame then
        return
    end

    if mapFrame.ResetZoom then
        pcall(mapFrame.ResetZoom, mapFrame)
    elseif mapFrame.SetMapZoom then
        pcall(mapFrame.SetMapZoom, mapFrame, 0)
    end

    if mapFrame.RefreshDetailLayers and mapFrame.IsShown and mapFrame:IsShown() then
        pcall(mapFrame.RefreshDetailLayers, mapFrame)
    end

    if FluxBattlefieldMapWorldFeatures then
        if FluxBattlefieldMapWorldFeatures.RefreshBattlefieldMapPublic then
            pcall(FluxBattlefieldMapWorldFeatures.RefreshBattlefieldMapPublic, FluxBattlefieldMapWorldFeatures, true)
        end
        if FluxBattlefieldMapWorldFeatures.SyncIfMapActive then
            pcall(FluxBattlefieldMapWorldFeatures.SyncIfMapActive, FluxBattlefieldMapWorldFeatures)
        end
    end
end

ApplyMapSetMapIDSilent = function(mapFrame, mapID, forceApply)
    if not mapFrame or not mapID then
        return false
    end

    local currentMapID = GetCurrentFrameMapID(mapFrame)
    local worldTransition = IsWorldZoneTransition(currentMapID, mapID)

    if not forceApply and not worldTransition and currentMapID and mapID == currentMapID then
        lastAppliedMapID = mapID
        return false
    end

    lastAppliedMapID = mapID
    mapFrame:SetMapID(mapID)
    FinishMapIDTransition(mapFrame)
    return true
end

local function ForceSetMapID(mapFrame, mapID)
    if not mapFrame or not mapID then
        return
    end

    lastAppliedMapID = mapID
    mapFrame:SetMapID(mapID)
end

-- Post-DF: zone refresh without replacing BattlefieldMapFrame.OnEvent (avoids map canvas taint).
local zoneLayoutWatcher = nil

local function RefreshEmbeddedMapLayout(mapFrame)
    if not state.isActive or not mapFrame then
        return
    end
    local mapID = GetPlayerDisplayMapID()
    if ApplyMapSetMapIDSilent(mapFrame, mapID) and state.parentFrame then
        ApplyMapScaling(mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, false)
    end
end

local function OnZoneLayoutWatcherEvent()
    if not state.isActive then
        return
    end
    local mapFrame = state.mapFrame
    if not mapFrame then
        return
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            RefreshEmbeddedMapLayout(mapFrame)
        end)
    else
        RefreshEmbeddedMapLayout(mapFrame)
    end
end

local function EnsureZoneLayoutWatcher()
    if not zoneLayoutWatcher then
        zoneLayoutWatcher = CreateFrame("Frame")
    end
    if zoneLayoutWatcher:GetScript("OnEvent") then return end
    zoneLayoutWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    zoneLayoutWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    zoneLayoutWatcher:RegisterEvent("NEW_WMO_CHUNK")
    zoneLayoutWatcher:SetScript("OnEvent", OnZoneLayoutWatcherEvent)
end

local function StopZoneLayoutWatcher()
    if not zoneLayoutWatcher then
        return
    end
    zoneLayoutWatcher:UnregisterAllEvents()
    zoneLayoutWatcher:SetScript("OnEvent", nil)
end

local function StripCombatUnsafeMapProviders(mapFrame)
    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.StripCombatUnsafeProviders then
        pcall(FluxBattlefieldMapWorldFeatures.StripCombatUnsafeProviders, FluxBattlefieldMapWorldFeatures, mapFrame)
    end
end

local function RunEmbeddedOnShowDeferred(mapFrame)
    if not mapFrame then
        return
    end
    HideBattlefieldMapTabInstantly()
    StripCombatUnsafeMapProviders(mapFrame)
    local mapID = GetPlayerDisplayMapID()
    if mapID then
        ForceSetMapID(mapFrame, mapID)
    end
    if state.parentFrame then
        ApplyMapScaling(mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, false)
    end
end

local function RunEmbeddedOnShow(mapFrame)
    HideBattlefieldMapTabInstantly()

    -- Strip before MapCanvas OnShow so EJ cannot AcquirePin under Flux taint.
    StripCombatUnsafeMapProviders(mapFrame)

    local mapID = GetPlayerDisplayMapID()
    if mapID then
        -- Always set map ID before MapCanvas OnShow; scroll container needs canvas dimensions.
        ForceSetMapID(mapFrame, mapID)
    end

    if MapCanvasMixin and MapCanvasMixin.OnShow then
        MapCanvasMixin.OnShow(mapFrame)
    end

    if state.parentFrame then
        ApplyMapScaling(mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, false)
    end
end

local function InstallMapLayoutHooksPostDF(mapFrame)
    if not mapFrame or mapFrame.FluxLayoutHooked then
        return
    end

    mapFrame.FluxLayoutHooked = true
    EnsureZoneLayoutWatcher()

    if hooksecurefunc and mapFrame.OnShow and not mapFrame.FluxBattlefieldMap_OnShowHooked then
        mapFrame.FluxBattlefieldMap_OnShowHooked = true
        hooksecurefunc(mapFrame, "OnShow", function(self)
            if not state.isActive then
                return
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if state.isActive and self and self:IsShown() then
                        RunEmbeddedOnShowDeferred(self)
                    end
                end)
            else
                RunEmbeddedOnShowDeferred(self)
            end
        end)
    end

    if mapFrame.HookScript and not mapFrame.FluxBattlefieldMap_HideHooked then
        mapFrame.FluxBattlefieldMap_HideHooked = true
        mapFrame:HookScript("OnHide", function(self)
            if state.isActive and not state.fluxPermitHide and self then
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, function()
                        if state.isActive and not state.fluxPermitHide and self then
                            self:Show()
                        end
                    end)
                else
                    self:Show()
                end
            end
        end)
    end
end

local function RestoreMapLayoutHooksPostDF(mapFrame)
    StopZoneLayoutWatcher()
    if not mapFrame then
        return
    end
    -- These post-hooks are permanent. Clearing their installation flags on
    -- every tab departure installs duplicates when the same native map returns.
    -- Their callbacks already gate all work on the current embedding state.
    mapFrame.FluxLayoutHooked = nil
end

local function InstallMapLayoutHooks(mapFrame)
    if not mapFrame or mapFrame.FluxLayoutHooked then
        return
    end

    if IsPostDFClient() then
        InstallMapLayoutHooksPostDF(mapFrame)
        return
    end

    mapFrame.FluxLayoutHooked = true

    if mapFrame.OnEvent and not mapFrame.FluxBattlefieldMap_OnEvent then
        mapFrame.FluxBattlefieldMap_OnEvent = mapFrame.OnEvent
        mapFrame.OnEvent = function(self, event, ...)
            if state.isActive then
                if event == "PLAYER_ENTERING_WORLD"
                    or event == "ZONE_CHANGED_NEW_AREA"
                    or event == "NEW_WMO_CHUNK" then
                    local mapID = GetPlayerDisplayMapID()
                    if ApplyMapSetMapIDSilent(self, mapID) and state.parentFrame then
                        ApplyMapScaling(self, CONFIG.SCALE_X, CONFIG.SCALE_Y, false)
                    end
                    if MapCanvasMixin and MapCanvasMixin.OnEvent then
                        MapCanvasMixin.OnEvent(self, event, ...)
                    end
                    return
                end
            end
            return self.FluxBattlefieldMap_OnEvent(self, event, ...)
        end
    end

    if mapFrame.OnShow and not mapFrame.FluxBattlefieldMap_OnShow then
        mapFrame.FluxBattlefieldMap_OnShow = mapFrame.OnShow
        mapFrame.OnShow = function(self)
            if state.isActive then
                RunEmbeddedOnShow(self)
                return
            end
            return self.FluxBattlefieldMap_OnShow(self)
        end
    end

    if mapFrame.Hide and not mapFrame.FluxBattlefieldMap_Hide then
        mapFrame.FluxBattlefieldMap_Hide = mapFrame.Hide
        mapFrame.Hide = function(self)
            if state.isActive and not state.fluxPermitHide then
                return
            end
            return self.FluxBattlefieldMap_Hide(self)
        end
    end
end

local function RestoreMapLayoutHooks(mapFrame)
    if not mapFrame then
        return
    end

    if IsPostDFClient() then
        RestoreMapLayoutHooksPostDF(mapFrame)
        return
    end

    if mapFrame.FluxBattlefieldMap_OnEvent then
        mapFrame.OnEvent = mapFrame.FluxBattlefieldMap_OnEvent
        mapFrame.FluxBattlefieldMap_OnEvent = nil
    end

    if mapFrame.FluxBattlefieldMap_OnShow then
        mapFrame.OnShow = mapFrame.FluxBattlefieldMap_OnShow
        mapFrame.FluxBattlefieldMap_OnShow = nil
    end

    if mapFrame.FluxBattlefieldMap_Hide then
        mapFrame.Hide = mapFrame.FluxBattlefieldMap_Hide
        mapFrame.FluxBattlefieldMap_Hide = nil
    end

    mapFrame.FluxLayoutHooked = nil
end

local function HideCombatMouseBlocker()
    combatMouseBlocker:Hide()
end

local function UpdateCombatMouseBlocker()
    if not state.isActive or not state.parentFrame or not InCombatLockdown() then
        HideCombatMouseBlocker()
        return
    end
    combatMouseBlocker:ClearAllPoints()
    combatMouseBlocker:SetPoint("TOPLEFT", state.parentFrame, "TOPLEFT", 0, -4)
    combatMouseBlocker:SetPoint("BOTTOMRIGHT", state.parentFrame, "BOTTOMRIGHT", 0, -4)
    combatMouseBlocker:Show()
    if GameTooltip and GameTooltip:IsShown() then
        GameTooltip:Hide()
    end
end

local function StopLayoutDriver()
    layoutDriver:SetScript("OnUpdate", nil)
    layoutDriver:Hide()
    layoutDriverElapsed = 0
    layoutStableTicks = 0
end

local function RunLayoutDriverTick()
    if not state.isActive or not state.mapFrame or not state.parentFrame then
        StopLayoutDriver()
        HideCombatMouseBlocker()
        return
    end

    if InCombatLockdown() then
        UpdateCombatMouseBlocker()
        return
    end

    HideCombatMouseBlocker()

    local mapFrame = state.mapFrame
    local needsRepair = false

    HideBattlefieldMapTabInstantly()

    if not mapFrame:IsShown() then
        if state.isActive then
            mapFrame:Show()
        end
        needsRepair = true
    end

    if mapFrame:GetParent() ~= UIParent then
        mapFrame:SetParent(UIParent)
        layoutCache.layoutAnchored = false
        needsRepair = true
    end

    if mapFrame:GetFrameStrata() ~= CONFIG.MAP_STRATA then
        mapFrame:SetFrameStrata(CONFIG.MAP_STRATA)
        needsRepair = true
    end

    if mapFrame:GetFrameLevel() ~= CONFIG.MAP_LEVEL then
        mapFrame:SetFrameLevel(CONFIG.MAP_LEVEL)
        needsRepair = true
    end

    if not IsLayoutCurrent(mapFrame) then
        ApplyMapScaling(mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, false)
        needsRepair = true
    end

    if needsRepair then
        layoutStableTicks = 0
    else
        layoutStableTicks = layoutStableTicks + 1
        if layoutStableTicks >= LAYOUT_STABLE_TICKS_TO_STOP then
            StopLayoutDriver()
        end
    end
end

StartLayoutDriver = function()
    layoutStableTicks = 0
    layoutDriverElapsed = 0
    layoutDriver:Show()
    layoutDriver:SetScript("OnUpdate", function(self, elapsed)
        layoutDriverElapsed = layoutDriverElapsed + elapsed
        if layoutDriverElapsed < LAYOUT_DRIVER_INTERVAL then
            return
        end
        layoutDriverElapsed = 0
        RunLayoutDriverTick()
    end)
    RunLayoutDriverTick()
end

local function FinishDeferredEmbed()
    if not state.embedPending or not state.parentFrame then
        return
    end
    local parentFrame = state.parentFrame
    local wasActive = state.isActive
    state.embedPending = false
    DoInitialize(parentFrame)
    if wasActive and state.mapFrame then
        HideBlizzardUIBorder(state.mapFrame)
        StartLayoutDriver()
        StripCombatUnsafeMapProviders(state.mapFrame)
        if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.OnMapShown then
            FluxBattlefieldMapWorldFeatures:OnMapShown(parentFrame)
        end
    end
end

local zoneRefresher = CreateFrame("Frame")
zoneRefresher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneRefresher:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneRefresher:RegisterEvent("ZONE_CHANGED")
zoneRefresher:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneRefresher:RegisterEvent("PLAYER_REGEN_DISABLED")
zoneRefresher:RegisterEvent("PLAYER_REGEN_ENABLED")
zoneRefresher:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        refreshPending = false
        UpdateCombatMouseBlocker()
    elseif event == "PLAYER_REGEN_ENABLED" then
        HideCombatMouseBlocker()
        FinishDeferredEmbed()

        if #positionUpdateQueue > 0 then
            for _, queuedOp in ipairs(positionUpdateQueue) do
                local mapFrame, parentFrame, opType
                if type(queuedOp) == "table" and queuedOp.type then
                    opType = queuedOp.type
                    mapFrame = state.mapFrame
                    parentFrame = queuedOp.parentFrame
                else
                    mapFrame = queuedOp[1]
                    parentFrame = queuedOp[2]
                    opType = queuedOp[3]
                end

                if opType == "setup" then
                    if mapFrame and parentFrame then
                        if mapFrame:GetParent() ~= UIParent then
                            mapFrame:SetParent(UIParent)
                        end
                        mapFrame:ClearAllPoints()
                        mapFrame:SetPoint("CENTER", parentFrame, "CENTER", 0, -2)
                        mapFrame:SetFrameStrata(CONFIG.MAP_STRATA)
                        mapFrame:SetFrameLevel(CONFIG.MAP_LEVEL)
                        mapFrame:Show()
                        layoutCache.layoutAnchored = true
                        layoutCache.parentFrame = parentFrame
                    end
                elseif opType == "reposition" then
                    if mapFrame and parentFrame then
                        mapFrame:ClearAllPoints()
                        mapFrame:SetPoint("CENTER", parentFrame, "CENTER", 0, -2)
                        layoutCache.layoutAnchored = true
                        layoutCache.parentFrame = parentFrame
                    end
                elseif opType == "cleanup" then
                    if mapFrame then
                        mapFrame:ClearAllPoints()
                        if BattlefieldMapTab then
                            mapFrame:SetPoint("TOPLEFT", "BattlefieldMapTab", "BOTTOMLEFT", 0, -2)
                        end
                        InvalidateLayoutCache()
                    end
                end
            end
            table.wipe(positionUpdateQueue)
        end

        if refreshPending then
            refreshPending = false
            QueueRefreshMapOnZoneChange()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        lastAppliedMapID = nil
        if InCombatLockdown() then
            refreshPending = true
        else
            QueueRefreshMapOnZoneChange()
        end
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        if InCombatLockdown() then
            refreshPending = true
        else
            QueueRefreshMapOnZoneChange()
        end
    end
end)

DoInitialize = function(parentFrame)
    -- Get Blizzard's battlefield map frame (loads addon if needed)
    state.mapFrame = GetBlizzardBattlefieldMap()
    
    -- If frame not available, try loading addon
    if not state.mapFrame then
        -- Try loading the addon synchronously
        local success = false
        if C_AddOns and C_AddOns.LoadAddOn then
            success = C_AddOns.LoadAddOn("Blizzard_BattlefieldMap")
        elseif LoadAddOn then
            success = LoadAddOn("Blizzard_BattlefieldMap")
        end
        
        if success then
            -- Try to get frame immediately after loading
            state.mapFrame = _G["BattlefieldMapFrame"]
        end
        
        -- If still not available, return false (caller can retry or use watcher)
        -- Note: FluxWindowFrame pre-loads this addon in PLAYER_LOGIN, so it should be available
        if not state.mapFrame then
            return false
        end
    end

    -- IMMEDIATELY reset scale to 1.0 to ensure clean state from the very beginning
    -- This is critical when switching to Map tab after login on a different tab
    -- The Blizzard map frame may have cached an incorrect scale from its initialization
    state.mapFrame:SetScale(1.0)
    InvalidateLayoutCache()

    -- Initialize BattlefieldMapOptions if it doesn't exist
    if not BattlefieldMapOptions then
        BattlefieldMapOptions = {
            opacity = 0,
            locked = true,
            showPlayers = true,
        }
    end

    -- Configure for embedded use (disable interactions for older clients)
    if IsOlderClient() then
        if state.mapFrame.SetShouldZoomInOnClick then
            state.mapFrame:SetShouldZoomInOnClick(false)
        end
        if state.mapFrame.SetShouldPanOnClick then
            state.mapFrame:SetShouldPanOnClick(false)
        end
        if state.mapFrame.SetShouldNavigateOnClick then
            state.mapFrame:SetShouldNavigateOnClick(false)
        end
    end

    HideBattlefieldMapTabInstantly()

    InstallMapLayoutHooks(state.mapFrame)

    -- Refresh alpha and units visibility
    if state.mapFrame.RefreshAlpha then
        state.mapFrame:RefreshAlpha()
    end
    if state.mapFrame.UpdateUnitsVisibility then
        state.mapFrame:UpdateUnitsVisibility()
    end

    -- Set up parenting and positioning
    SetupMapParenting(state.mapFrame, parentFrame)

    -- Apply initial scaling
    ApplyMapScaling(state.mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, true)

    -- Use watcher pattern instead of delays for instant setup
    -- This ensures proper scaling during initial login/reload when Map tab is active
    local scalingWatcher = CreateFrame("Frame")
    local scalingCheckCount = 0
    local MAX_SCALING_CHECKS = 10
    
    scalingWatcher:SetScript("OnUpdate", function(self, elapsed)
        scalingCheckCount = scalingCheckCount + 1
        
        -- Check if map frame is ready and apply scaling
        if state.mapFrame and state.parentFrame then
            -- Reapply scaling to handle any Blizzard resets
            ApplyMapScaling(state.mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, false)
            if RefreshMapOnZoneChange then
                RefreshMapOnZoneChange()
            end
            
            self:SetScript("OnUpdate", nil)
        elseif scalingCheckCount >= MAX_SCALING_CHECKS then
            -- Stop watching after max checks
            self:SetScript("OnUpdate", nil)
        end
    end)

    -- Initialize the map with current zone
    -- Use compatible API for getting current map
    local mapID = nil
    if MapUtil and MapUtil.GetDisplayableMapForPlayer then
        -- Post-Dragonflight API
        mapID = MapUtil.GetDisplayableMapForPlayer()
    elseif C_Map and C_Map.GetBestMapForUnit then
        -- Modern API available on some older clients
        mapID = C_Map.GetBestMapForUnit("player")
    elseif GetCurrentMapAreaID then
        -- Legacy API for very old clients
        mapID = GetCurrentMapAreaID()
    end

    if mapID then
        ApplyMapSetMapIDSilent(state.mapFrame, mapID)

        -- For older clients, ensure proper zoom level (use watcher instead of delay)
        if IsOlderClient() then
            local zoomWatcher = CreateFrame("Frame")
            local zoomCheckCount = 0
            zoomWatcher:SetScript("OnUpdate", function(self, elapsed)
                zoomCheckCount = zoomCheckCount + 1
                if state.mapFrame then
                    if state.mapFrame.SetMapZoom then
                        state.mapFrame:SetMapZoom(0) -- Fully zoomed out
                    elseif state.mapFrame.ZoomOut then
                        for i = 1, 10 do
                            state.mapFrame:ZoomOut()
                        end
                    end
                    self:SetScript("OnUpdate", nil)
                elseif zoomCheckCount >= 5 then
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end
    end

    InstallLightweightMapUpdate(state.mapFrame)
    return true
end

-- Initialize the battlefield map for use with FluxWindowFrame
function FluxBattlefieldMap:Initialize(parentFrame)
    if not parentFrame then
        return false
    end
    state.parentFrame = parentFrame

    if InCombatLockdown() then
        state.embedPending = true
        state.mapFrame = GetBlizzardBattlefieldMap()
        return state.mapFrame ~= nil
    end

    state.embedPending = false
    return DoInitialize(parentFrame)
end

-- Show the battlefield map
function FluxBattlefieldMap:Show()
    if not state.mapFrame and not state.embedPending then
        return
    end

    if not state.mapFrame then
        state.mapFrame = GetBlizzardBattlefieldMap()
    end
    if not state.mapFrame then
        return
    end

    SetCVar("showBattlefieldMinimap", "1")

    if state.embedPending then
        state.isActive = true
        if _G.BattlefieldMapOptions then
            _G.BattlefieldMapOptions.opacity = 0
        end
        StartLayoutDriver()
        UpdateCombatMouseBlocker()
        StripCombatUnsafeMapProviders(state.mapFrame)
        if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.OnMapShown then
            FluxBattlefieldMapWorldFeatures:OnMapShown(state.parentFrame)
        end
        return
    end

    -- IMMEDIATELY reset scale to 1.0 and apply correct scaling
    -- This fixes issues when switching to Map tab after login/reload on a different tab
    -- The map frame may have cached an incorrect scale from Blizzard's initialization
    InvalidateLayoutCache()
    ApplyMapScaling(state.mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, true)

    -- Ensure proper parenting and positioning
    if state.parentFrame then
        SetupMapParenting(state.mapFrame, state.parentFrame)
    end

    InstallMapLayoutHooks(state.mapFrame)

    if _G.BattlefieldMapOptions then
        _G.BattlefieldMapOptions.opacity = 0
    end

    state.isActive = true

    InstallLightweightMapUpdate(state.mapFrame)
    StripCombatUnsafeMapProviders(state.mapFrame)

    if not state.mapFrame:IsShown() then
        state.mapFrame:Show()
    else
        RunEmbeddedOnShow(state.mapFrame)
    end

    HideBlizzardUIBorder(state.mapFrame)
    StartLayoutDriver()
    UpdateCombatMouseBlocker()

    -- Refresh alpha and units visibility
    if state.mapFrame.RefreshAlpha then
        state.mapFrame:RefreshAlpha()
    end
    if state.mapFrame.UpdateUnitsVisibility then
        state.mapFrame:UpdateUnitsVisibility()
    end

    StripCombatUnsafeMapProviders(state.mapFrame)
    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.OnMapShown then
        FluxBattlefieldMapWorldFeatures:OnMapShown(state.parentFrame)
    end
    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.SyncIfMapActive then
        FluxBattlefieldMapWorldFeatures:SyncIfMapActive()
    end
end

-- Hide the battlefield map
function FluxBattlefieldMap:Hide()
    if not state.mapFrame then return end

    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.OnMapHidden then
        FluxBattlefieldMapWorldFeatures:OnMapHidden()
    end

    StopLayoutDriver()
    HideCombatMouseBlocker()
    state.isActive = false
    state.embedPending = false
    SetCVar("showBattlefieldMinimap", "0")
    state.fluxPermitHide = true
    state.mapFrame:Hide()
    state.fluxPermitHide = false

    -- Show Blizzard's default UI elements
    ShowBlizzardUIBorder(state.mapFrame)
end

-- Set scaling factors
function FluxBattlefieldMap:SetScaling(scaleX, scaleY)
    CONFIG.SCALE_X = scaleX or 1.0
    CONFIG.SCALE_Y = scaleY or 1.0

    if state.mapFrame and state.isActive then
        InvalidateLayoutCache()
        ApplyMapScaling(state.mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, true)
        StartLayoutDriver()
    end
end

-- Get current scaling factors
function FluxBattlefieldMap:GetScaling()
    return CONFIG.SCALE_X, CONFIG.SCALE_Y
end

-- Update map positioning and scaling when parent frame changes
function FluxBattlefieldMap:UpdateLayout()
    if not state.mapFrame or not state.parentFrame or not state.isActive then return end

    if InCombatLockdown() then
        UpdateCombatMouseBlocker()
        return
    end

    SetupMapParenting(state.mapFrame, state.parentFrame)
    ApplyMapScaling(state.mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, false)
    StartLayoutDriver()
    UpdateCombatMouseBlocker()
    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.RefreshToggleLayout then
        FluxBattlefieldMapWorldFeatures:RefreshToggleLayout()
    end
end

-- Set the parent frame (for re-parenting)
function FluxBattlefieldMap:SetParent(parentFrame)
    state.parentFrame = parentFrame
    if state.mapFrame and state.isActive then
        SetupMapParenting(state.mapFrame, parentFrame)
        ApplyMapScaling(state.mapFrame, CONFIG.SCALE_X, CONFIG.SCALE_Y, false)
        StartLayoutDriver()
    end
end

-- Check if the map is currently active
function FluxBattlefieldMap:IsActive()
    return state.isActive
end

-- Get the underlying map frame
function FluxBattlefieldMap:GetMapFrame()
    return state.mapFrame
end

function FluxBattlefieldMap:SetWorldMapFeaturesEnabled(enabled)
    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.SetEnabled then
        FluxBattlefieldMapWorldFeatures:SetEnabled(enabled)
    end
end

function FluxBattlefieldMap:GetWorldMapFeaturesEnabled()
    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.IsEnabled then
        return FluxBattlefieldMapWorldFeatures:IsEnabled()
    end
    return false
end

-- Force refresh of the map display
function FluxBattlefieldMap:Refresh()
    if not state.mapFrame then return end

    -- Force a refresh by hiding and showing
    local wasActive = state.isActive
    self:Hide()

    if wasActive then
        C_Timer.After(0.01, function()
            self:Show()
            -- Extra zoom reset for older clients
            if IsOlderClient() then
                C_Timer.After(0.1, function()
                    if state.mapFrame.SetMapZoom then
                        state.mapFrame:SetMapZoom(0)
                    elseif state.mapFrame.ZoomOut then
                        for i = 1, 10 do
                            state.mapFrame:ZoomOut()
                        end
                    end
                end)
            end
        end)
    end
end

-- Cleanup function
function FluxBattlefieldMap:Cleanup()
    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.OnMapHidden then
        FluxBattlefieldMapWorldFeatures:OnMapHidden()
    end

    StopLayoutDriver()
    HideCombatMouseBlocker()
    state.embedPending = false
    SetCVar("showBattlefieldMinimap", "0")
    InvalidateLayoutCache()
    lastAppliedMapID = nil

    if state.mapFrame then
        state.isActive = false
        state.fluxPermitHide = true
        RestoreMapLayoutHooks(state.mapFrame)

        ShowBlizzardUIBorder(state.mapFrame)
        RestoreBattlefieldMapTab()

        state.mapFrame:SetScale(1.0)
        state.mapFrame:SetFrameStrata("MEDIUM")
        state.mapFrame:Hide()
        state.fluxPermitHide = false

        if InCombatLockdown() then
            table.insert(positionUpdateQueue, { type = "cleanup" })
        else
            if state.mapFrame:GetParent() ~= UIParent then
                state.mapFrame:SetParent(UIParent)
            end
            state.mapFrame:ClearAllPoints()
            if BattlefieldMapTab then
                state.mapFrame:SetPoint("TOPLEFT", "BattlefieldMapTab", "BOTTOMLEFT", 0, -2)
            end
        end
    end

    state.mapFrame = nil
    state.parentFrame = nil
    state.isActive = false
    state.isOlderClient = nil
end

-- Slash command for testing
SLASH_FLUXBATTLEFIELDMAP1 = "/fluxmap"
SlashCmdList["FLUXBATTLEFIELDMAP"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    local cmd = args[1]

    if cmd == "testload" then
        local mapFrame = GetBlizzardBattlefieldMap()
    elseif cmd == "scale" then
        local scaleX = tonumber(args[2]) or 1.0
        local scaleY = tonumber(args[3]) or scaleX
        FluxBattlefieldMap:SetScaling(scaleX, scaleY)
    elseif cmd == "show" then
        if FluxBattlefieldMap:Initialize(UIParent) then
            FluxBattlefieldMap:Show()
        end
    elseif cmd == "hide" then
        FluxBattlefieldMap:Hide()
    elseif cmd == "refresh" then
        FluxBattlefieldMap:Refresh()
    elseif cmd == "cleanup" then
        FluxBattlefieldMap:Cleanup()
    end
end


