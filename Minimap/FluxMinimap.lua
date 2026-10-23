-- FluxMinimap.lua
-- Square Minimap implementation for FluxUI
-- Compatible with all WoW versions via FluxAPICompat & FluxBorder

local addonName, addonTable = ...

-- Include Questie integration mixin
pcall(function() require("Minimap.FluxQuestieMixin") end)

-- ----------------------------------------------------------------------------
-- CONSTANTS & CONFIG
-- ----------------------------------------------------------------------------
local CONFIG = {
    -- Size: Standardized across all WoW versions for consistency
    Size = 190,
    Position = {"TOPRIGHT", UIParent, "TOPRIGHT", -25, -25}, -- Default Position
    Scale = 1.0,
    MaskTexture = "Interface\\Buttons\\WHITE8x8", -- Use a solid square mask
    UpdateInterval = 1.0, -- Burst enforcer interval after layout changes
    StableUpdateInterval = 4.0, -- Idle fallback enforcer interval
}

-- Embedded mode state tracking
local embeddedState = {
    isEmbedded = false,
    parentFrame = nil,
    originalParent = nil,
    originalSize = nil,
    originalPosition = nil,
    normalMinimapWidth = nil,  -- Store normal minimap width for quest tracker
}

-- Combat-safe queue for minimap positioning operations
local minimapPositionQueue = {}

--- After embed/show/hide minimap size changes, refresh position-3 micromap strip height/anchor.
local function FluxMinimap_TryRebuildMicroMenuPos3()
    if not (C_Timer and C_Timer.After) then
        return
    end
    C_Timer.After(0, function()
        local FO = _G.FluxOptions
        local mm = _G.FluxMicroMenu
        if not FO or not mm or not mm.Rebuild or not FO.GetMicroMenuLayoutPosition then
            return
        end
        if FO:GetMicroMenuLayoutPosition() ~= 3 then
            return
        end
        if InCombatLockdown() then
            mm.needsUpdate = true
            return
        end
        mm:Rebuild()
    end)
end

-- Never add methods to EditModeManagerFrame or mutate registeredSystemFrames.
-- That taints UpdateActionBarLayout → RightManagedFrameContainer:SetSize when
-- StanceBar:Update runs from ActionBarController_UpdateAll (vehicles / possess).
local function FluxUnregisterObjectiveTrackerFromEditMode()
    local tracker = ObjectiveTrackerFrame or ObjectiveTrackerManager
    if tracker and FluxRemoveFrameFromEditMode then
        pcall(FluxRemoveFrameFromEditMode, tracker)
    end
end

-- ----------------------------------------------------------------------------
-- INITIALIZATION
-- ----------------------------------------------------------------------------
-- Create global FluxMinimap so it can be accessed from FluxWindowFrame
FluxMinimap = CreateFrame("Frame")

FluxMinimap:RegisterEvent("PLAYER_LOGIN")
FluxMinimap:RegisterEvent("PLAYER_ENTERING_WORLD")
FluxMinimap:RegisterEvent("ADDON_LOADED")
FluxMinimap:RegisterEvent("PLAYER_REGEN_ENABLED") -- For deferred position enforcement after combat
-- Events for instance difficulty updates
FluxMinimap:RegisterEvent("UPDATE_INSTANCE_INFO")
FluxMinimap:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
FluxMinimap:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED")
FluxMinimap:RegisterEvent("GROUP_ROSTER_UPDATE")
FluxMinimap:RegisterEvent("MINIMAP_UPDATE_TRACKING")
-- Events for display/UI changes that affect tracker position
FluxMinimap:RegisterEvent("DISPLAY_SIZE_CHANGED")
FluxMinimap:RegisterEvent("UI_SCALE_CHANGED")
-- Do not listen to PLAYER_SPECIALIZATION_CHANGED / level-up. Forever fires that
-- event on ding; Edit Mode InitSystemAnchors already runs, and Flux re-docking
-- the tracker (SortQuestWatches / PinLayoutHeight / clip rebuild) fights it.

FluxMinimap:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if self._fluxLoginPresented then return true end
        if InCombatLockdown() and Minimap.IsProtected and Minimap:IsProtected() then
            if _G.Flux and Flux.Combat then
                Flux.Combat.Defer("hud.minimap", function()
                    self:GetScript("OnEvent")(self, "PLAYER_LOGIN")
                end)
            end
            return false
        end
        -- Initialize immediately
        self:Initialize()
        
        -- Initial quest tracker position: simple delayed apply (no OnUpdate - stays static until embed toggle)
        -- Blizzard_ObjectiveTracker loads async; ADDON_LOADED handles first position when frame exists
        -- Second delay catches embedding state from saved vars (FluxWindowFrame may load after)
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if self.UpdateQuestTrackerPosition then self:UpdateQuestTrackerPosition() end
            end)
        end
        
        -- Call immediately for other positioning (no delay) - these are safe to call instantly
        self:PositionIndicators()
        
        -- CRITICAL: Hide MinimapCluster instantly if minimap is embedded but not on Map tab
        -- This must happen before EnforcePosition to prevent cluster from appearing
        if embeddedState.isEmbedded then
            if MinimapCluster then
                MinimapCluster:Hide()  -- Safe in combat
            end
            
            -- Check if we're on Map tab - if not, ensure minimap is hidden
            if FluxWindowFrame and FluxWindowFrame.GetActiveTab then
                local activeTab = FluxWindowFrame:GetActiveTab()
                if activeTab ~= "Map" then
                    -- Not on Map tab, hide embedded minimap
                    self:HideEmbedded()
                end
            end
        end
        
        -- Also enforce position and cleanup if not in combat
        if not InCombatLockdown() then
            self:EnforcePosition()
            self:CleanupBlizzardFrames()
        end
        self._fluxLoginPresented = true
        if _G.Flux and Flux.Startup then Flux.Startup.Mark("minimap_hud_presented") end
        return true
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UpdateStyle()
        -- Only enforce position when not in combat
        if not InCombatLockdown() then
            self:EnforcePosition()
            self:CleanupBlizzardFrames()
        end
        -- Update instance difficulty when entering world
        self:PositionIndicators()
        -- Force instance difficulty update
        if Minimap and Minimap.InstanceDifficulty and Minimap.InstanceDifficulty.Update then
            Minimap.InstanceDifficulty:Update()
        end
        -- Quest tracker: static until embed toggle - no re-apply here (avoids spec change, etc.)
        -- Forever: Manager.Init waits for this PEW + VARIABLES_LOADED. Kick dock once
        -- after that Init, not on later loading screens. Live retail stays static.
        if (FLUX_API.isCamelot or FLUX_API.isForever) and not self._fluxForeverPewTracker then
            self._fluxForeverPewTracker = true
            if FluxObjectiveTrackerScroll then
                if FluxObjectiveTrackerScroll.InstallForeverCompat then
                    FluxObjectiveTrackerScroll:InstallForeverCompat()
                end
                if FluxObjectiveTrackerScroll.StartForeverLoginPulse then
                    FluxObjectiveTrackerScroll:StartForeverLoginPulse()
                end
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if self.UpdateQuestTrackerPosition then
                        self:UpdateQuestTrackerPosition()
                    end
                end)
            elseif self.UpdateQuestTrackerPosition then
                self:UpdateQuestTrackerPosition()
            end
        end
        
        -- CRITICAL: Hide MinimapCluster instantly if minimap is embedded but not on Map tab
        -- This must happen before EnforcePosition to prevent cluster from appearing
        if embeddedState.isEmbedded then
            if MinimapCluster then
                MinimapCluster:Hide()  -- Safe in combat
            end
            
            -- Check if we're on Map tab - if not, ensure minimap is hidden
            if FluxWindowFrame and FluxWindowFrame.GetActiveTab then
                local activeTab = FluxWindowFrame:GetActiveTab()
                if activeTab ~= "Map" then
                    -- Not on Map tab, hide embedded minimap
                    self:HideEmbedded()
                end
            end
        end
        
        -- Also enforce position and cleanup if not in combat
        if not InCombatLockdown() then
            self:EnforcePosition()
            self:CleanupBlizzardFrames()
        end
    elseif event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == "Blizzard_TimeManager" then
            self:CleanupTimeManager()
        elseif loadedAddon == "Blizzard_EditMode" then
            if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_ObjectiveTracker") and FluxUnregisterObjectiveTrackerFromEditMode then
                C_Timer.After(0.05, function()
                    FluxUnregisterObjectiveTrackerFromEditMode()
                end)
            end
        elseif loadedAddon == "Blizzard_ObjectiveTracker" then
            if FluxUnregisterObjectiveTrackerFromEditMode then
                C_Timer.After(0.05, FluxUnregisterObjectiveTrackerFromEditMode)
            end
            -- ObjectiveTracker addon loaded, re-apply position
            C_Timer.After(0.1, function()
                if self.UpdateQuestTrackerPosition then
                    self:UpdateQuestTrackerPosition()
                end
            end)
        end
    elseif event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
        -- Tracker stays static - only updates on embed toggle
        if self.RefreshInfoBarZoneFit then
            self:RefreshInfoBarZoneFit()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Process queued minimap positioning operations
        if #minimapPositionQueue > 0 then
            for _, queuedOp in ipairs(minimapPositionQueue) do
                if queuedOp.type == "embed" then
                    -- Apply positioning for embed operation
                    if Minimap and queuedOp.parentFrame then
                        Minimap:SetParent(queuedOp.parentFrame)
                        Minimap:ClearAllPoints()
                        Minimap:SetPoint("TOPRIGHT", queuedOp.parentFrame, "TOPRIGHT", 0, -queuedOp.infoBarHeight + queuedOp.inset)
                        
                        -- Position InfoBar
                        if self.InfoBar then
                            self.InfoBar:SetParent(queuedOp.parentFrame)
                            self.InfoBar:ClearAllPoints()
                            self.InfoBar:SetPoint("BOTTOMRIGHT", Minimap, "TOPRIGHT", 0, -queuedOp.inset)
                        end
                    end
                elseif queuedOp.type == "restore" then
                    -- Apply positioning for restore operation
                    if Minimap and embeddedState.originalParent then
                        Minimap:SetParent(embeddedState.originalParent)
                        Minimap:ClearAllPoints()
                        if embeddedState.originalPosition then
                            Minimap:SetPoint(unpack(embeddedState.originalPosition))
                        end
                        
                        -- Restore InfoBar position
                        if self.InfoBar and embeddedState.originalInfoBarPosition then
                            self.InfoBar:SetParent(embeddedState.originalInfoBarParent)
                            self.InfoBar:ClearAllPoints()
                            self.InfoBar:SetPoint(unpack(embeddedState.originalInfoBarPosition))
                        end
                    end
                end
            end
            table.wipe(minimapPositionQueue)
            if self.RefreshInfoBarZoneFit then
                self:RefreshInfoBarZoneFit()
            end
            FluxMinimap.NotifyInfoFrameLayoutChanged()
        end
        
        -- Defer position enforcement after combat ends
        if not embeddedState.isEmbedded then
            self:EnforcePosition()
            self:CleanupBlizzardFrames()
        end
        
        -- Handle pending embed operation (legacy support)
        if self.pendingEmbed then
            local parentFrame = self.pendingEmbed
            self.pendingEmbed = nil
            self:EmbedInFrame(parentFrame)
        end
        
        -- Handle pending restore operation (legacy support)
        if self.pendingRestore then
            self.pendingRestore = nil
            self:RestoreToNormal()
        end
    elseif event == "UPDATE_INSTANCE_INFO" or event == "PLAYER_DIFFICULTY_CHANGED" or event == "INSTANCE_GROUP_SIZE_CHANGED" or event == "GROUP_ROSTER_UPDATE" or event == "MINIMAP_UPDATE_TRACKING" then
        -- Update instance difficulty and tracking when relevant events occur
        self:PositionIndicators()
    end
end)

function FluxMinimap:Initialize()
    -- ... (Previous code) ...
end

-- ...

-- Hooking logic moved to Initialize to properly use local helper if defined above
-- Re-defining Initialize to include the new hook logic

function FluxMinimap:RunEnforcerPass()
    if InCombatLockdown() then return end
    self:EnforcePosition()
    self:CleanupBlizzardFrames()
    -- Minimap only. Spec/level Edit Mode bursts this enforcer; a full tracker
    -- re-dock (watch sort, clip rebuild, pinned height) wrecks objectives.
end

function FluxMinimap:RequestEnforcerBurst(duration)
    -- Short burst; early-cancel after a clean pass inside the ticker.
    self._enforcerBurstUntil = GetTime() + (duration or 4)
    self._enforcerCleanPasses = 0
    self:EnsureEnforcerTicker()
    self:RunEnforcerPass()
end

function FluxMinimap:CancelEnforcerTicker()
    if self._enforcerTicker then
        self._enforcerTicker:Cancel()
        self._enforcerTicker = nil
    end
    self._enforcerAcc = 0
    self._enforcerBurstUntil = 0
end

function FluxMinimap:EnsureEnforcerTicker()
    if not FLUX_API.hasC_Timer_NewTicker then return end
    if self._enforcerTicker then return end
    self._enforcerAcc = 0
    self._enforcerTicker = C_Timer.NewTicker(1.0, function()
        local burstUntil = FluxMinimap._enforcerBurstUntil or 0
        local now = GetTime()
        if now >= burstUntil then
            FluxMinimap:CancelEnforcerTicker()
            return
        end
        local interval = CONFIG.UpdateInterval or 1.0
        FluxMinimap._enforcerAcc = (FluxMinimap._enforcerAcc or 0) + 1.0
        if FluxMinimap._enforcerAcc >= interval then
            FluxMinimap._enforcerAcc = 0
            if not InCombatLockdown() then
                FluxMinimap:RunEnforcerPass()
                -- Early-cancel after one clean pass (no ongoing layout fight).
                FluxMinimap._enforcerCleanPasses = (FluxMinimap._enforcerCleanPasses or 0) + 1
                if (FluxMinimap._enforcerCleanPasses or 0) >= 1 then
                    FluxMinimap:CancelEnforcerTicker()
                end
            end
        end
    end)
end

function FluxMinimap.GetEnforcerBurstRemaining()
    local untilT = FluxMinimap._enforcerBurstUntil or 0
    local now = GetTime and GetTime() or 0
    if untilT <= now or not FluxMinimap._enforcerTicker then
        return 0
    end
    return untilT - now
end

function FluxMinimap:Initialize()
    if self._fluxInitialized then return end
    -- 1. Set Shape to Square
    Minimap:SetMaskTexture(CONFIG.MaskTexture)
    
    -- 2. Apply Border
    FluxBorder:ApplyTo(Minimap)
    FluxBorder:SetClassColor(Minimap, 1, false) -- alpha 1, false = do NOT tint/show backdrop
    
    -- Ensure the background is hidden so it doesn't cover the map
    if Minimap.FluxBorderFrame and Minimap.FluxBorderFrame.Background then
        Minimap.FluxBorderFrame.Background:Hide()
    end
    
    -- 3. Basic Sizing
    if FLUX_API.isLegacyClient then
        -- Legacy clients render the minimap slightly wider, user requested 175x190
        Minimap:SetSize(175, CONFIG.Size)
    else
        -- Modern clients: 190x190
        Minimap:SetSize(CONFIG.Size, CONFIG.Size)
    end
    Minimap:SetScale(CONFIG.Scale)
    
    -- Save the normal minimap width for quest tracker text width constraint
    embeddedState.normalMinimapWidth = Minimap:GetWidth()
    
    -- 4. Enable mouse wheel zooming
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)
    
    -- 5. Handle Right Click for tracking/calendar (Context Menu)
    -- Use HookScript so Blizzard's original OnMouseUp runs first (performs ping in untainted context).
    -- Our hook runs after; we only add right-click handling. Left-click ping is done by Blizzard's handler.
    if not self._fluxMouseUpHooked then
    Minimap:HookScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            if FLUX_API.isRetail then
                if MiniMapTrackingButton then MiniMapTrackingButton:OpenMenu() end
            else
                if FLUX_API.hasCalendar then ToggleCalendar() end
            end
        end
        -- Left-click: Blizzard's handler (which ran first) already did the ping - nothing to do here.
    end)
    self._fluxMouseUpHooked = true
    end


    -- 6. Hook Edit Mode (Retail only)
    if FLUX_API.hasEditMode then
        self:HandleEditMode()
    end
    
    -- 7. Adaptive enforcer (event-driven bursts + slower idle fallback)
    self:RequestEnforcerBurst(4)
    self:EnsureEnforcerTicker()
    local enforcerEvents = self._fluxEnforcerEvents or CreateFrame("Frame")
    self._fluxEnforcerEvents = enforcerEvents
    enforcerEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    enforcerEvents:RegisterEvent("DISPLAY_SIZE_CHANGED")
    enforcerEvents:RegisterEvent("UI_SCALE_CHANGED")
    if FLUX_API.hasEditMode then
        enforcerEvents:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    end
    enforcerEvents:SetScript("OnEvent", function()
        FluxMinimap:RequestEnforcerBurst(4)
    end)
    
    -- 8. Create Info Bar (Zone Text + Clock)
    self:CreateInfoBar()
    
    -- 9. Hook Blizzard's QuestWatchFrame positioning to prevent conflicts
    self:HookQuestWatchFramePositioning()
    self._fluxInitialized = true
end

--- Reapply border accent on minimap chrome and embedded extra buttons (called from FluxBorder:RefreshAppearanceDependents).
function FluxMinimap_ApplyAppearanceAccent()
    if not FluxBorder then return end
    if Minimap and Minimap.FluxBorderFrame then
        FluxBorder:SetClassColor(Minimap, 1, false)
        if Minimap.FluxBorderFrame.Background then
            Minimap.FluxBorderFrame.Background:Hide()
        end
    end
    if FluxMinimap and FluxMinimap.InfoBar then
        FluxBorder:SetClassColor(FluxMinimap.InfoBar, 1, true)
    end
    if FluxMinimapButtons and FluxMinimapButtons.RefreshAppearanceAccent then
        FluxMinimapButtons:RefreshAppearanceAccent()
    end
end

-- ----------------------------------------------------------------------------
-- STYLING & CLEANUP
-- ----------------------------------------------------------------------------

function FluxMinimap:UpdateStyle()
    Minimap:SetMaskTexture(CONFIG.MaskTexture)
    if Minimap.SetArchBlobRingScalar then
        Minimap:SetArchBlobRingScalar(0)
    end
    if Minimap.SetQuestBlobRingScalar then
        Minimap:SetQuestBlobRingScalar(0)
    end
    
    if Minimap.SetBorderTexture then
        Minimap:SetBorderTexture(nil) -- Remove default border texture if function exists
    end
end

function FluxMinimap:CleanupBlizzardFrames()
    -- Comprehensive list of frames to hide across all versions
    local framesToHide = {
        "MinimapBorder",
        "MinimapBorderTop",
        "MinimapZoomIn",
        "MinimapZoomOut",
        "MinimapNorthTag",
        "MinimapZoneTextButton",
        "MiniMapWorldMapButton", -- Classic
        -- "MiniMapTracking",       -- Keeping Tracking
        "GameTimeFrame",         -- Classic Clock/Calendar
        "TimeManagerClockButton", -- Retail Clock
        "MinimapBackdrop",       -- Common in Classic/TBC
        "MinimapCompassTexture",
        "MiniMapVoiceChatFrame",
        "QueueStatusMinimapButtonBorder",
        "MiniMapMailBorder",
        "MinimapToggleButton",
        "HybridMinimapToggleButton",
    }

    for _, name in pairs(framesToHide) do
        local frame = _G[name]
        if frame then
            frame:Hide()
            frame:SetParent(FluxMinimapHiddenFrame) -- Reparent to hidden frame
            -- Agressive: Hook OnShow to immediately Hide if something tries to show it back
            if not frame.fluxHooked then
                 frame.fluxHooked = true
                 if frame.HookScript then
                     frame:HookScript("OnShow", function(self) self:Hide() end)
                 end
            end
        end
    end

    -- Handle newer zoom buttons (Mainline/Retail) that are parentKey under Minimap
    if Minimap and Minimap.ZoomIn then
        Minimap.ZoomIn:Hide()
        Minimap.ZoomIn:SetParent(FluxMinimapHiddenFrame)
        if not Minimap.ZoomIn.fluxHooked then
            Minimap.ZoomIn.fluxHooked = true
            if Minimap.ZoomIn.HookScript then
                Minimap.ZoomIn:HookScript("OnShow", function(self) self:Hide() end)
            end
        end
    end

    if Minimap and Minimap.ZoomOut then
        Minimap.ZoomOut:Hide()
        Minimap.ZoomOut:SetParent(FluxMinimapHiddenFrame)
        if not Minimap.ZoomOut.fluxHooked then
            Minimap.ZoomOut.fluxHooked = true
            if Minimap.ZoomOut.HookScript then
                Minimap.ZoomOut:HookScript("OnShow", function(self) self:Hide() end)
            end
        end
    end
    
    -- Handle Tracking Button icon specifically
    -- We want to KEEP this now, but maybe style/position it.
    -- if MiniMapTrackingButton then
    --     MiniMapTrackingButton:Hide() 
    --     MiniMapTrackingButton:SetParent(FluxMinimapHiddenFrame)
    --     if not MiniMapTrackingButton.fluxHooked then
    --          hooksecurefunc(MiniMapTrackingButton, "Show", function(self) self:Hide() end)
    --          MiniMapTrackingButton.fluxHooked = true
    --     end
    -- end

    -- Garrison/Expansion Landing Page (Retail)
    -- We want to KEEP this now.
    -- if GarrisonLandingPageMinimapButton then
    --    GarrisonLandingPageMinimapButton:Hide()
    --    GarrisonLandingPageMinimapButton:SetParent(FluxMinimapHiddenFrame)
    -- end
    -- if ExpansionLandingPageMinimapButton then
    --    ExpansionLandingPageMinimapButton:Hide()
    --    ExpansionLandingPageMinimapButton:SetParent(FluxMinimapHiddenFrame)
    -- end
    
    -- Additional texture cleanup for Classic
    if MinimapBorderTop then MinimapBorderTop:Hide() end
end

function FluxMinimap:CleanupTimeManager()
    if TimeManagerClockButton then
        TimeManagerClockButton:Hide()
        TimeManagerClockButton:SetParent(FluxMinimapHiddenFrame)
    end
end

-- ----------------------------------------------------------------------------
-- POSITION & EDIT MODE
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- POSITION & EDIT MODE
-- ----------------------------------------------------------------------------

function FluxMinimap:EnforcePosition()
    if not Minimap then return end
    
    -- Skip enforcement when minimap is embedded in another frame
    if embeddedState.isEmbedded then return end
    
    -- Combat protection: Skip protected function calls during combat
    if InCombatLockdown() then return end
    
    -- Prevent moving
    Minimap:SetMovable(false)
    Minimap:ClearAllPoints()
    
    -- Calculate Y Offset for "0 Gap" at the top
    -- We want the InfoBar (which is above Minimap) to touch the top of screen (0).
    -- InfoBar Top = Minimap Top - Inset + Height
    -- 0 = Minimap Top - Inset + 24
    -- Minimap Top = Inset - 24
    local inset = (FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases()) and 4 or 2
    local topOffset = inset - 24
    
    Minimap:SetPoint(CONFIG.Position[1], CONFIG.Position[2], CONFIG.Position[3], 0, topOffset)
    Minimap:SetScale(CONFIG.Scale)
    
    -- Blizzard reads the cluster's height during protected action-bar layout.
    -- Keep its native anchors/size independent of the movable/embedded minimap.
    if MinimapCluster then
        MinimapCluster:EnableMouse(false) -- Disable cluster mouse interaction
        MinimapCluster:SetMovable(false)
        MinimapCluster:Hide() -- Hide the cluster which usually contains the border/zone text
        
        -- But we need the Minimap frame itself to be shown
        Minimap:Show()
        Minimap:SetParent(UIParent) -- Ensure it's not hidden by parent hide
    end
    
    self:PositionIndicators()
end


function FluxMinimap:PositionIndicators()
    -- Combat protection: Skip protected function calls during combat
    if InCombatLockdown() then return end
    
    local btnSize = 32
    local padding = 2
    local inset = (FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases()) and 4 or 2

    -- 1. Tracking Icon (Bottom Right - stays in fixed position)
    -- Different names on different versions
    -- Retail uses MinimapCluster.Tracking, Classic uses MiniMapTracking/MiniMapTrackingButton

    local trackingBtn = nil
    if MinimapCluster and MinimapCluster.Tracking then
        trackingBtn = MinimapCluster.Tracking
    elseif MiniMapTracking then
        trackingBtn = MiniMapTracking
    elseif MiniMapTrackingButton then
        trackingBtn = MiniMapTrackingButton
    end

    if trackingBtn then
        trackingBtn:ClearAllPoints()
        trackingBtn:SetParent(Minimap)
        trackingBtn:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -inset, inset) -- Fixed position
        trackingBtn:SetFrameLevel(Minimap:GetFrameLevel() + 50) -- Ensure on top

        -- In Classic Era, only show tracking button if tracking is active
        if FLUX_API.isClassicEra then
            -- Check if any tracking is currently active
            local hasActiveTracking = false
            if C_Minimap and C_Minimap.GetNumTrackingTypes then
                local count = C_Minimap.GetNumTrackingTypes()
                for id = 1, count do
                    local trackingInfo = C_Minimap.GetTrackingInfo(id)
                    if trackingInfo and trackingInfo.active then
                        hasActiveTracking = true
                        break
                    end
                end
            end

            if hasActiveTracking then
                trackingBtn:Show()
            else
                trackingBtn:Hide()
            end
        else
            -- On modern clients, always show the tracking button
            trackingBtn:Show()
        end

        -- Handle visual setup differently for different clients
        if FLUX_API.isClassicEra then
            -- For Classic Era, use the built-in MiniMapTracking_Update function
            -- This properly sets the tracking icon texture using C_Minimap.GetTrackingInfo()
            if MiniMapTracking_Update then
                MiniMapTracking_Update()
            end

            -- Hide borders that might interfere
            if MiniMapTrackingButtonBorder then
                MiniMapTrackingButtonBorder:Hide()
            end

        else
            -- On Retail, Tracking Button has nested textures/borders.
            if trackingBtn.SetBorderHidden then
                trackingBtn:SetBorderHidden(true)
            end
            if MiniMapTrackingButtonBorder then
                MiniMapTrackingButtonBorder:Hide()
            end
        end

        -- For Classic Era, set up proper tooltip and ensure functionality
        if FLUX_API.isClassicEra then
            -- Set up tooltip
            if not trackingBtn:GetScript("OnEnter") then
                trackingBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
                    if GameTooltip.SetTrackingSpell then
                        GameTooltip:SetTrackingSpell()
                    else
                        GameTooltip:SetText("Tracking", 1, 1, 1)
                        GameTooltip:AddLine("Left-click to change tracking", 0.8, 0.8, 0.8)
                        GameTooltip:AddLine("Right-click to cancel tracking", 0.8, 0.8, 0.8)
                    end
                end)
            end

            if not trackingBtn:GetScript("OnLeave") then
                trackingBtn:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
            end

            -- The MiniMapTrackingButtonMixin should handle dropdown functionality
            -- If it doesn't have click handlers, the mixin might not be applied properly
            if not trackingBtn:GetScript("OnMouseDown") then
                -- Fallback: Try to use the dropdown system that Classic Era uses
                trackingBtn:SetScript("OnMouseDown", function(self, button)
                    if button == "LeftButton" then
                        if MiniMapTrackingDropDown then
                            ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self:GetName(), 0, -5)
                        end
                    end
                end)
            end

            -- Update the tracking icon to show current tracking
            if GetTrackingTexture then
                local texture = GetTrackingTexture()
                if texture and trackingBtn.icon then
                    trackingBtn.icon:SetTexture(texture)
                end
            end
        end
    end

    -- 2. Mail Icon (Left of Tracking when visible)
    -- Check for mail frame across different clients
    local mailFrame = MiniMapMailFrame or (Minimap and Minimap.MailFrame)

    -- If mail frame doesn't exist, create a fallback one
    if not mailFrame and Minimap then
        mailFrame = CreateFrame("Frame", "FluxMinimapMailFrame", Minimap)
        mailFrame:SetSize(20, 15)
        mailFrame:EnableMouse(true)
        mailFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)

        -- Create the mail icon texture
        local mailIcon = mailFrame:CreateTexture(nil, "ARTWORK")
        mailIcon:SetAtlas("ui-hud-minimap-mail-up")
        mailIcon:SetAllPoints()
        mailFrame.MailIcon = mailIcon
    end

    if mailFrame then
        mailFrame:ClearAllPoints()
        mailFrame:SetParent(Minimap)
        -- Position to the left of the tracking button
        if trackingBtn then
            mailFrame:SetPoint("RIGHT", trackingBtn, "LEFT", -2, 0)
        else
            -- Fallback if no tracking button
            mailFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -inset + 4, inset - 4)
        end
        mailFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)
        -- Ensure border is hidden if possible, but keep icon
        if MiniMapMailBorder then MiniMapMailBorder:Hide() end

        -- Make sure mail icon is interactive for tooltips but not clickable
        mailFrame:EnableMouse(true)

        -- Add tooltip functionality
        if not mailFrame.fluxTooltipHooked then
            mailFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
                if MinimapMailFrameUpdate then
                    MinimapMailFrameUpdate()
                else
                    -- Fallback tooltip if the function doesn't exist
                    local senders = { GetLatestThreeSenders() }
                    local headerText = #senders >= 1 and HAVE_MAIL_FROM or HAVE_MAIL
                    FormatUnreadMailTooltip(GameTooltip, headerText, senders)
                    GameTooltip:Show()
                end
            end)

            mailFrame:SetScript("OnLeave", function(self)
                GameTooltip_Hide()
            end)

            mailFrame.fluxTooltipHooked = true
        end

        -- Manually handle mail visibility since mixin might not work on all clients
        -- Always show mail icon when there's mail, regardless of game notification settings
        if not mailFrame.fluxMailRegistered then
            -- Always register for mail events - user wants to see mail icon
            mailFrame:RegisterEvent("UPDATE_PENDING_MAIL")
            mailFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

            mailFrame:SetScript("OnEvent", function(self, event, ...)
                if event == "UPDATE_PENDING_MAIL" or event == "PLAYER_ENTERING_WORLD" then
                    if HasNewMail and HasNewMail() then
                        self:Show()
                        -- Make sure the mail icon texture is visible
                        if self.MailIcon then
                            self.MailIcon:Show()
                        end
                    else
                        self:Hide()
                    end
                    -- Update layout when mail status changes
                    FluxMinimap:PositionIndicators()
                end
            end)

            -- Initial check
            if HasNewMail and HasNewMail() then
                mailFrame:Show()
                -- Make sure the mail icon texture is visible
                if mailFrame.MailIcon then
                    mailFrame.MailIcon:Show()
                end
            else
                mailFrame:Hide()
            end

            mailFrame.fluxMailRegistered = true
        end

        -- Hook to update layout immediately when mail appears/disappears
        if not mailFrame.fluxHooked then
             mailFrame:HookScript("OnShow", function() FluxMinimap:PositionIndicators() end)
             mailFrame:HookScript("OnHide", function() FluxMinimap:PositionIndicators() end)
             mailFrame.fluxHooked = true
        end
    end
    
    -- 3. Instance Difficulty Banner (Top Right)
    -- Handle Blizzard's instance difficulty banner
    -- Only create if the client supports InstanceDifficultyTemplate
    if Minimap and not Minimap.InstanceDifficulty then
        -- Check if InstanceDifficultyTemplate exists (modern clients)
        local hasTemplate = false
        if pcall(function() return InstanceDifficultyTemplate end) then
            hasTemplate = true
        end

        if hasTemplate then
            -- Create using the template for modern clients
            local success, frame = pcall(CreateFrame, "Frame", nil, Minimap, "InstanceDifficultyTemplate")
            if success and frame then
                Minimap.InstanceDifficulty = frame
                -- Call OnLoad if it exists
                if frame.OnLoad then
                    frame:OnLoad()
                elseif InstanceDifficultyMixin and InstanceDifficultyMixin.OnLoad then
                    InstanceDifficultyMixin.OnLoad(frame)
                end
            end
        end
        -- Note: Legacy clients without InstanceDifficultyTemplate won't get the banner
        -- This is intentional - they don't have this feature in the base UI
    end

    -- Position and show the frame if it exists
    if Minimap.InstanceDifficulty then
        Minimap.InstanceDifficulty:ClearAllPoints()
        Minimap.InstanceDifficulty:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)
        Minimap.InstanceDifficulty:SetFrameLevel(Minimap:GetFrameLevel() + 20)
        if Minimap.InstanceDifficulty.Update then
            Minimap.InstanceDifficulty:Update()
        end
        if Minimap.Layout then
            Minimap:Layout()
        end
        Minimap.InstanceDifficulty:Show()
    end

    -- Handle older client frames
    if MiniMapInstanceDifficulty then
        MiniMapInstanceDifficulty:ClearAllPoints()
        MiniMapInstanceDifficulty:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, 5)
        MiniMapInstanceDifficulty:SetFrameLevel(Minimap:GetFrameLevel() + 20)
        if MiniMapInstanceDifficulty_Update then
            MiniMapInstanceDifficulty_Update()
        end
        MiniMapInstanceDifficulty:Show()
    end

    if GuildInstanceDifficulty then
        GuildInstanceDifficulty:ClearAllPoints()
        GuildInstanceDifficulty:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, 5)
        GuildInstanceDifficulty:SetFrameLevel(Minimap:GetFrameLevel() + 20)
        GuildInstanceDifficulty:Show()
    end

    -- 4. Shared positioning helper for the objective tracker.
    
    -- Helper to Safely Set Point, bypassing Edit Mode hooks if possible
    -- This avoids "fighting" with Edit Mode and prevents infinite loops/flickering
    local function SafeSetPoint(frame, point, relativeTo, relativePoint, x, y)
        if not frame then return end
        
        -- Retail/Edit Mode uses Mixins that override SetPoint.
        -- 'SetPointBase' is usually the original C function.
        if frame.SetPointBase then
            frame:SetPointBase(point, relativeTo, relativePoint, x, y)
        else
            frame:SetPoint(point, relativeTo, relativePoint, x, y)
        end
    end
    FluxMinimap.SafeSetPoint = SafeSetPoint -- Export for use elsewhere

    -- 5. Expansion Landing Page
    -- Retail: ExpansionLandingPageMinimapButton
    -- SL: GarrisonLandingPageMinimapButton
    -- Free minimap: leave BOTTOMLEFT corner edge for the queue eye; nest landing just inside.
    -- Embedded: BOTTOMLEFT is free (queue eye moves to TOPRIGHT).
    local landingBtn = ExpansionLandingPageMinimapButton or GarrisonLandingPageMinimapButton
    if landingBtn and FLUX_API.isRetail then
        -- Forever/camelot: ExpansionLandingPageMinimapButton mixin exists, but the
        -- ExpansionLandingPage addon is AllowLoadGameType: standard only. Hide before
        -- reparent so RefreshButton/OnShow cannot index the missing frame.
        if landingBtn == ExpansionLandingPageMinimapButton and not ExpansionLandingPage then
            landingBtn:Hide()
        else
            landingBtn:SetSize(32, 32)
            landingBtn:ClearAllPoints()
            landingBtn:SetParent(Minimap)
            if embeddedState.isEmbedded then
                landingBtn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -2, -2)
            else
                landingBtn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 34, -2)
            end
            landingBtn:SetFrameLevel(Minimap:GetFrameLevel() + 10)

            if landingBtn.RefreshButton and ExpansionLandingPage then
                landingBtn:RefreshButton()
            else
                landingBtn:Show()
            end
        end
    end

    -- 6. Queue / PvP buttons (retail DF+ eye, classic PvP battlefield button)
    self:PositionQueueStatusEye()
end

--- Hide classic/legacy LFG minimap buttons (not the retail QueueStatusButton dungeon eye).
local function ParkLfgMinimapEyes()
    local hidden = _G.FluxMinimapHiddenFrame or _G.FluxHiddenParent
    for _, name in ipairs({ "LFGMinimapFrame", "MiniMapLFGFrame", "QueueStatusMinimapButton" }) do
        local f = _G[name]
        if f and not (f.IsForbidden and f:IsForbidden()) then
            pcall(function()
                f.FluxLfgEyeSuppressed = true
                f:Hide()
                f:SetAlpha(0)
                if hidden then
                    f:SetParent(hidden)
                end
                if not f.FluxLfgEyeParkHooked then
                    f.FluxLfgEyeParkHooked = true
                    if f.HookScript then
                        f:HookScript("OnShow", function(self)
                            if self.FluxLfgEyeSuppressed then
                                self:Hide()
                                self:SetAlpha(0)
                            end
                        end)
                    end
                end
            end)
        end
    end
end

local function IsRetailPostDfQueueEye()
    return FLUX_API and FLUX_API.isRetail and FLUX_API.isPostDF and _G.QueueStatusButton ~= nil
end

local function FluxHasActivePvPQueue()
    if GetMaxBattlefieldID and GetBattlefieldStatus then
        for i = 1, GetMaxBattlefieldID() do
            local status = GetBattlefieldStatus(i)
            if status and status ~= "none" then
                return true
            end
        end
    end
    if MAX_WORLD_PVP_QUEUES and GetWorldPVPQueueStatus then
        for i = 1, MAX_WORLD_PVP_QUEUES do
            local status = GetWorldPVPQueueStatus(i)
            if status and status ~= "none" then
                return true
            end
        end
    end
    if GetLFGRoleUpdate then
        local inProgress, _, _, _, _, isBattleground = GetLFGRoleUpdate()
        if inProgress and isBattleground then
            return true
        end
    end
    if GetLFGReadyCheckUpdate then
        local readyCheckInProgress, readyCheckIsBattleground = GetLFGReadyCheckUpdate()
        if readyCheckInProgress and readyCheckIsBattleground then
            return true
        end
    end
    return false
end

local function UnparkCombinedPvPEye(frame)
    if not frame then
        return
    end
    frame.FluxLfgEyeSuppressed = false
    if frame.SetAlpha then
        frame:SetAlpha(1)
    end
end

--- Shared placement for retail QueueStatusButton and classic MiniMapBattlefieldFrame.
--- Embedded: TOPRIGHT inside the border. Free-floating: center on BOTTOMLEFT corner (half past the border).
local QUEUE_STATUS_EYE_SCALE = 0.85

local function ApplyMinimapQueueButtonPlacement(btn, isEmbedded)
    if not btn or not btn.ClearAllPoints or not btn.SetPoint then
        return false
    end
    if btn.IsForbidden and btn:IsForbidden() then
        return false
    end
    local inset = (FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases()) and 4 or 2
    local ok = pcall(function()
        btn:SetParent(Minimap)
        btn:ClearAllPoints()
        if btn.SetScale then
            btn:SetScale(QUEUE_STATUS_EYE_SCALE)
        end
        if btn.SetAlpha then
            btn:SetAlpha(1)
        end
        btn:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 40)
        if isEmbedded then
            btn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -inset, -inset)
        else
            btn:SetPoint("CENTER", Minimap, "BOTTOMLEFT", 0, 0)
        end
    end)
    return ok
end

local function PositionQueueStatusTooltip(anchor, isEmbedded)
    local tip = _G.QueueStatusFrame
    if not anchor or not tip or not tip.ClearAllPoints or not tip.SetPoint then
        return
    end
    if tip.IsForbidden and tip:IsForbidden() then
        return
    end
    pcall(function()
        tip:ClearAllPoints()
        if isEmbedded then
            tip:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", 0, -2)
        else
            tip:SetPoint("BOTTOMLEFT", anchor, "TOPRIGHT", 0, 2)
        end
    end)
end

--- Retail DF+ QueueStatusButton and classic PvP MiniMapBattlefieldFrame on the minimap.
--- Pre-DF retail: QueueStatusButton stays on micromenu fallback. Classic LFG minimap buttons stay parked.
--- @return boolean true if a queue button was managed on the minimap
function FluxMinimap:PositionQueueStatusEye()
    if not Minimap then
        return false
    end

    ParkLfgMinimapEyes()

    local isEmbedded = embeddedState.isEmbedded
    local placedAnchor = nil

    if IsRetailPostDfQueueEye() then
        local q = _G.QueueStatusButton
        if ApplyMinimapQueueButtonPlacement(q, isEmbedded) then
            placedAnchor = q
        end
    end

    local separateBg = true
    if MiniMap_BattleGroundQueueSeparateButton then
        separateBg = MiniMap_BattleGroundQueueSeparateButton() and true or false
    end

    if separateBg then
        local bg = _G.MiniMapBattlefieldFrame
        if ApplyMinimapQueueButtonPlacement(bg, isEmbedded) then
            placedAnchor = placedAnchor or bg
        end
    elseif FluxHasActivePvPQueue() then
        -- Mists-style combined eye: only for PvP queues, same corner placement as retail.
        local combined = _G.LFGMinimapFrame or _G.MiniMapLFGFrame
        if combined then
            UnparkCombinedPvPEye(combined)
            if ApplyMinimapQueueButtonPlacement(combined, isEmbedded) then
                placedAnchor = placedAnchor or combined
            end
        end
    end

    if placedAnchor then
        PositionQueueStatusTooltip(placedAnchor, isEmbedded)
    end

    self:EnsureQueueStatusEyeHooks()
    return placedAnchor ~= nil
end

function FluxMinimap:EnsureQueueStatusEyeHooks()
    if self._queueStatusEyeHooks then
        return
    end
    local managesRetail = IsRetailPostDfQueueEye()
    local managesClassicPvP = _G.MiniMapBattlefieldFrame ~= nil
        or _G.LFGMinimapFrame ~= nil
        or _G.MiniMapLFGFrame ~= nil
    if not managesRetail and not managesClassicPvP then
        return
    end
    self._queueStatusEyeHooks = true

    local function Reapply()
        -- Micro menu Edit Mode enter / exit move the eye inside its pass.
        if FluxEditModeBusy and FluxEditModeBusy() then
            FluxAfterEditMode(Reapply)
            return
        end
        if FluxMinimap and FluxMinimap.PositionQueueStatusEye then
            if not FluxMinimap:PositionQueueStatusEye() and _G.FluxMicroMenu_PositionQueueStatusFallback then
                _G.FluxMicroMenu_PositionQueueStatusFallback()
            end
        end
    end

    local q = _G.QueueStatusButton
    if q and type(q.UpdatePosition) == "function" then
        hooksecurefunc(q, "UpdatePosition", Reapply)
    end

    local tip = _G.QueueStatusFrame
    if tip and type(tip.UpdatePosition) == "function" then
        hooksecurefunc(tip, "UpdatePosition", Reapply)
    end

    for _, name in ipairs({
        "QueueStatusButton",
        "MiniMapBattlefieldFrame",
        "LFGMinimapFrame",
        "MiniMapLFGFrame",
    }) do
        local f = _G[name]
        if f and f.HookScript then
            f:HookScript("OnShow", Reapply)
        end
    end

    if EventRegistry and EventRegistry.RegisterCallback then
        pcall(function()
            EventRegistry:RegisterCallback("QueueStatusButton.OnShow", Reapply)
            EventRegistry:RegisterCallback("QueueStatusUpdate.QueuesUpdated", Reapply)
        end)
    end

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    pcall(function() ev:RegisterEvent("PVPQUEUE_ANYWHERE_SHOW") end)
    pcall(function() ev:RegisterEvent("PVPQUEUE_ANYWHERE_UPDATE_AVAILABLE") end)
    ev:SetScript("OnEvent", function()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, Reapply)
        else
            Reapply()
        end
    end)
end

-- ----------------------------------------------------------------------------
-- QUEST TRACKER POSITIONING HOOKS
-- ----------------------------------------------------------------------------

function FluxMinimap:HookQuestWatchFramePositioning()
    -- Only hook once
    if FluxMinimap._questWatchHooked then return end
    FluxMinimap._questWatchHooked = true
    
    local questTracker = ObjectiveTrackerFrame or QuestWatchFrame
    if not questTracker then return end
    
    -- Do NOT hook ObjectiveTrackerContainerMixin:UpdateHeight. It runs during ExitEditMode
    -- (RevertAllChanges -> UpdateLayoutInfo -> UIParent_ManageFramePositions -> UpdateFrame/RemoveManagedFrame
    -- -> ObjectiveTrackerFrame:UpdateHeight). Addon code there taints the stack, causing
    -- ADDON_ACTION_FORBIDDEN (ClearTarget) and CompactUnitFrame secret value taint.
    -- We rely on editModeHeight (set in UpdateQuestTrackerPosition) and Blizzard's UpdateHeight
    -- when not in default position. Ticker + EditMode.Exit re-apply position/height.
    --
    -- Hook FramePositionDelegate_Override_QuestWatchFrameOffsets if it exists (Classic clients)
    -- This function is called by Blizzard's UIParentPanelManager to position QuestWatchFrame
    if FramePositionDelegate_Override_QuestWatchFrameOffsets then
        local originalFunc = FramePositionDelegate_Override_QuestWatchFrameOffsets
        FramePositionDelegate_Override_QuestWatchFrameOffsets = function(anchorYStartValue, rightActionBars, buffsAnchorY)
            -- Check if FluxUI is managing the quest tracker (get it dynamically)
            local tracker = ObjectiveTrackerFrame or QuestWatchFrame or WatchFrame
            if tracker and tracker.fluxInitialized then
                -- FluxUI is managing it, return the anchorY without positioning
                return anchorYStartValue
            end
            -- Otherwise, call the original function
            return originalFunc(anchorYStartValue, rightActionBars, buffsAnchorY)
        end
    end
    
    -- Also hook QuestWatchFrame:SetPoint as a backup to prevent any SetPoint calls
    -- from Blizzard's positioning system when FluxUI is managing it
    if QuestWatchFrame and QuestWatchFrame.SetPoint then
        local originalSetPoint = QuestWatchFrame.SetPoint
        QuestWatchFrame.SetPoint = function(self, ...)
            -- Get the quest tracker dynamically (self might be QuestWatchFrame)
            local tracker = ObjectiveTrackerFrame or QuestWatchFrame or WatchFrame
            -- If FluxUI is managing the quest tracker and this isn't FluxUI setting the point,
            -- check if this call is coming from Blizzard's positioning system
            if tracker and tracker.fluxInitialized and not tracker.fluxSettingPosition then
                -- Try to detect if this is from Blizzard's positioning system
                -- Check call stack if available, otherwise use a more permissive approach
                local success, callStack = pcall(debugstack, 2, 3, 0)
                if success and callStack and (callStack:find("UIParentPanelManager") or callStack:find("FramePositionDelegate")) then
                    -- This is Blizzard trying to position it, prevent it to avoid anchor family connection errors
                    return
                end
            end
            -- Otherwise, allow the SetPoint call
            return originalSetPoint(self, ...)
        end
    end
    
    -- Also hook WatchFrame:SetPoint for Classic clients (WatchFrame is the same as QuestWatchFrame in some versions)
    if WatchFrame and WatchFrame ~= QuestWatchFrame and WatchFrame.SetPoint then
        local originalWatchSetPoint = WatchFrame.SetPoint
        WatchFrame.SetPoint = function(self, ...)
            local tracker = ObjectiveTrackerFrame or QuestWatchFrame or WatchFrame
            if tracker and tracker.fluxInitialized and not tracker.fluxSettingPosition then
                local success, callStack = pcall(debugstack, 2, 3, 0)
                if success and callStack and (callStack:find("UIParentPanelManager") or callStack:find("FramePositionDelegate")) then
                    return
                end
            end
            return originalWatchSetPoint(self, ...)
        end
    end
end

function FluxMinimap:UpdateQuestTrackerPosition()
    -- Defensive: self may be nil when called as bare callback (e.g. C_Timer.After(fn))
    self = self or FluxMinimap
    -- Combat protection: Skip protected function calls during combat
    if InCombatLockdown() then return end
    
    -- Skip if Edit Mode is active (let Edit Mode handle positioning)
    if FLUX_API.hasEditMode and EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return
    end
    
    local s = (self and type(self) == "table") and self or FluxMinimap
    local questie = addonTable and addonTable.FluxQuestie
    if questie and questie:IsTrackerEnabled() then
        questie:UpdateLayout()
        return
    end
    if FluxObjectiveTrackerScroll and FluxObjectiveTrackerScroll.UpdateQuestieVisibility then
        FluxObjectiveTrackerScroll:UpdateQuestieVisibility()
    end
    local questTracker = ObjectiveTrackerFrame or QuestWatchFrame
    if not questTracker then return end

    if FluxObjectiveTrackerScroll and FluxObjectiveTrackerScroll.InstallForeverCompat
        and (FLUX_API.isCamelot or FLUX_API.isForever) then
        FluxObjectiveTrackerScroll:InstallForeverCompat()
    end

    if questTracker.fluxSettingPosition then return end
    questTracker.fluxSettingPosition = true
    
    local foreverClient = FLUX_API.isCamelot or FLUX_API.isForever
    local foreverTracker = foreverClient and ObjectiveTrackerFrame and questTracker == ObjectiveTrackerFrame
        and FluxObjectiveTrackerScroll

    -- Initial setup for scale and detachment if not already done
    if not questTracker.fluxInitialized then
        local useOTScroll = FLUX_API.hasBlizzardObjectiveTrackerScroll and ObjectiveTrackerFrame
            and questTracker == ObjectiveTrackerFrame and FluxObjectiveTrackerScroll

        local scrollReady = false
        if useOTScroll then
            -- Forever: leave Blizzard parent/anchors until Manager.Init has run
            -- and the tracker height is non-zero. EnsureViewport returns nil
            -- until then. Clearing points before Init made UpdateAll see height 0.
            scrollReady = FluxObjectiveTrackerScroll:EnsureViewport(questTracker) ~= nil
        else
            questTracker:SetScale(0.75)
            -- Ensure it's parented to UIParent so it's not hidden/moved by managed containers
            if questTracker:GetParent() ~= UIParent then
                questTracker:SetParent(UIParent)
            end
            if questTracker.Header and questTracker.Header.ClearAllPoints
                and questTracker.Header:GetParent() ~= questTracker then
                questTracker.Header:SetParent(questTracker)
                questTracker.Header:ClearAllPoints()
                questTracker.Header:SetPoint("TOPLEFT")
            end
            -- Do not write systemInfo.isInDefaultPosition: InitSystemAnchors reads
            -- it on spec/level and a Flux value taints MainActionBar:SetPointBase.
            scrollReady = true
        end

        if scrollReady and (not foreverTracker or questTracker.fluxScrollActive) then
            -- Detach from Blizzard's Layout/Position Managers
            questTracker:SetMovable(true)
            questTracker:SetUserPlaced(true)
            questTracker.ignoreFramePositionManager = true

            -- Remove from Edit Mode if available
            if FLUX_API.hasEditMode and FluxRemoveFrameFromEditMode then
                FluxRemoveFrameFromEditMode(questTracker)
            end

            questTracker.fluxInitialized = true
        end
        
        -- Do NOT wrap SetHeight: right-container Layout calls it, then
        -- RightManagedFrameContainer:SetSize is ADDON_ACTION_BLOCKED.
        -- Height is applied OOC via SetMaxHeight / SetHeight below and EditMode.Exit.
        
        -- Hook Blizzard's positioning system to prevent conflicts (use s - self may be nil when called as callback)
        s:HookQuestWatchFramePositioning()
        
        -- Do NOT hook ObjectiveTrackerFrame:SetPoint or ObjectiveTrackerContainerMixin:UpdateHeight -
        -- they run during ExitEditMode layout flow (RevertAllChanges -> UIParent_ManageFramePositions)
        -- and taint the stack, causing ADDON_ACTION_FORBIDDEN (ClearTarget) errors.
        -- Do NOT patch EditModeManagerFrame (UnregisterSystem): that taints
        -- StanceBar:Update → RightManagedFrameContainer:SetSize on vehicle.
        -- Do not write systemInfo.isInDefaultPosition (InitSystemAnchors /
        -- MainActionBar:SetPointBase on spec/level). ignoreFramePositionManager,
        -- editModeHeight, and deferred re-application (ticker + EditMode.Exit).
    end

    -- Get FluxWindowFrame reference for positioning (use GetFrame to ensure it exists)
    local windowFrame = FluxWindowFrame and FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame()
    
    -- Check if we're in Minimap mode (minimap is embedded)
    local isMinimapMode = s.IsEmbedded and s:IsEmbedded()
    
    -- Geometry validation (post-DF fix): Ensure frames have valid layout before applying position
    -- If geometry is invalid, schedule retry instead of applying a potentially wrong position
    local function isGeometryValid()
        if not Minimap or Minimap:GetWidth() == 0 or Minimap:GetHeight() == 0 then
            return false
        end
        if not isMinimapMode and (not Minimap:GetBottom() or Minimap:GetBottom() == 0) then
            return false
        end
        if windowFrame and (windowFrame:GetWidth() == 0 or windowFrame:GetHeight() == 0) then
            return false
        end
        return true
    end
    
    if not isGeometryValid() then
        questTracker.fluxSettingPosition = false
        if C_Timer and C_Timer.After then
            C_Timer.After(0.1, function()
                if s.UpdateQuestTrackerPosition then
                    s:UpdateQuestTrackerPosition()
                end
            end)
        end
        return
    end

    -- Gap between Objective Tracker bottom and FluxWindowFrame top (prevents overlap)
    -- Blizzard's UpdateHeight uses math.max(editModeHeight, contentHeight) so it can grow past our limit;
    -- we subtract this buffer and clamp SetHeight to enforce the boundary.
    local TRACKER_WINDOW_GAP = 20

    -- Height first, then skip. Tab switches used to ClearAllPoints + SortQuestWatches
    -- before this check and flickered the Forever/retail tracker.
    local availableHeight = nil
    if isMinimapMode then
        if windowFrame then
            local screenTop = UIParent:GetTop() or UIParent:GetHeight()
            local windowTop = windowFrame:GetTop() or 0
            availableHeight = (screenTop - windowTop - TRACKER_WINDOW_GAP) / 0.75
            availableHeight = math.max(100, availableHeight)
        end
    elseif windowFrame then
        local minimapBottom = Minimap:GetBottom() or 0
        local windowTop = windowFrame:GetTop() or 0
        availableHeight = (minimapBottom - windowTop - TRACKER_WINDOW_GAP) / 0.75
        availableHeight = math.max(100, availableHeight)
    end

    -- Fallback height when windowFrame unavailable or calculation failed (e.g. load-order race)
    -- Ensures tracker always has valid height for both embedded and non-embedded modes
    if not availableHeight or availableHeight <= 0 then
        local screenHeight = UIParent:GetHeight() or 768
        availableHeight = math.max(300, screenHeight * 0.4)  -- ~40% of screen, min 300px
    end

    local snap = questTracker._fluxDockSnap
    if questTracker.fluxInitialized and snap
        and snap.embedded == isMinimapMode
        and math.abs((snap.height or 0) - availableHeight) < 0.5
        and snap.parent and questTracker:GetParent() == snap.parent then
        questTracker.fluxSettingPosition = false
        return
    end

    local vpScroll = nil
    if FLUX_API.hasBlizzardObjectiveTrackerScroll and ObjectiveTrackerFrame and questTracker == ObjectiveTrackerFrame and FluxObjectiveTrackerScroll then
        vpScroll = FluxObjectiveTrackerScroll:EnsureViewport(questTracker)
    end
    if foreverTracker and not vpScroll then
        -- Manager.Init or a real height has not landed. Do not anchor or
        -- ClearAllPoints the tracker. A later PEW / Init hook retries.
        questTracker.fluxSettingPosition = false
        local tries = questTracker._fluxScrollDockTries or 0
        if tries < 40 and C_Timer and C_Timer.After and not questTracker._fluxScrollDockWait then
            questTracker._fluxScrollDockWait = true
            questTracker._fluxScrollDockTries = tries + 1
            C_Timer.After(0.1, function()
                questTracker._fluxScrollDockWait = false
                if s.UpdateQuestTrackerPosition then
                    s:UpdateQuestTrackerPosition()
                end
            end)
        end
        return
    end
    if vpScroll and not questTracker.fluxInitialized then
        questTracker:SetMovable(true)
        questTracker:SetUserPlaced(true)
        questTracker.ignoreFramePositionManager = true
        if FLUX_API.hasEditMode and FluxRemoveFrameFromEditMode then
            FluxRemoveFrameFromEditMode(questTracker)
        end
        questTracker.fluxInitialized = true
    end
    local anchorFrame = vpScroll or questTracker

    -- Re-anchor only when the dock target changed. Unconditional ClearAllPoints
    -- unhooks the tracker for a frame on every Flux window tab click.
    local wantRel = isMinimapMode and UIParent or Minimap
    local wantRelPoint = isMinimapMode and "TOPRIGHT" or "BOTTOMRIGHT"
    local needAnchor = true
    if anchorFrame.GetNumPoints and anchorFrame:GetNumPoints() == 1 then
        local point, rel, relPoint, x, y = anchorFrame:GetPoint(1)
        if point == "TOPRIGHT" and rel == wantRel and relPoint == wantRelPoint
            and math.abs(x or 0) < 0.5 and math.abs(y or 0) < 0.5 then
            needAnchor = false
        end
    end
    if needAnchor then
        anchorFrame:ClearAllPoints()
        if anchorFrame.SetClampedToScreen then
            anchorFrame:SetClampedToScreen(true)
        end
        if s.SafeSetPoint then
            s.SafeSetPoint(anchorFrame, "TOPRIGHT", wantRel, wantRelPoint, 0, 0)
        else
            anchorFrame:SetPoint("TOPRIGHT", wantRel, wantRelPoint, 0, 0)
        end
    elseif anchorFrame.SetClampedToScreen then
        anchorFrame:SetClampedToScreen(true)
    end
    
    -- Store calculated height. Do not SetHeight/SetMaxHeight/UpdateHeight on the
    -- tracker from Flux: OnSizeChanged → MarkDirty taints the next Blizzard Update
    -- (ShouldShowMawBuffs / Edit Mode SetPoint).
    if availableHeight then
        questTracker.fluxMaxHeight = availableHeight

        local useScroll = questTracker.fluxScrollActive and vpScroll and FluxObjectiveTrackerScroll
        if not useScroll then
            questTracker.editModeHeight = availableHeight
        end

        if useScroll then
            -- Viewport scroll: PinLayoutHeight inside the scroll child, never SetHeight
            -- the tracker from this dock. Embedded and floating minimap both size
            -- this same viewport (TOPRIGHT of UIParent, or under the minimap).
            -- Do not SortQuestWatches here: that rebuilds the watch list and flickers
            -- the tracker on every Flux window tab click. KickScrollLayoutOnce owns that kick.
            FluxObjectiveTrackerScroll:PinLayoutHeight(questTracker)
            local sizeChanged = FluxObjectiveTrackerScroll:ApplyViewportSize(vpScroll, questTracker, availableHeight, questTracker:GetWidth())
            if sizeChanged then
                FluxObjectiveTrackerScroll:RefreshLayout(questTracker)
            end
            if foreverTracker and FluxObjectiveTrackerScroll.RecoverStuckDirty then
                FluxObjectiveTrackerScroll:RecoverStuckDirty(questTracker)
            end
        else
            -- Immediately set the height multiple times to ensure it sticks
            -- This is critical for instant updates when toggling modes
            if questTracker.SetMaxHeight then
                questTracker:SetMaxHeight(availableHeight)
                questTracker:SetMaxHeight(availableHeight)
            else
                questTracker:SetHeight(availableHeight)
                questTracker:SetHeight(availableHeight)
            end
            if questTracker.UpdateHeight then
                questTracker:UpdateHeight()
                if questTracker.SetMaxHeight then
                    questTracker:SetMaxHeight(availableHeight)
                else
                    questTracker:SetHeight(availableHeight)
                end
            end
        end
        
        -- Do NOT hook OnSizeChanged or OnShow - they run during ExitEditMode layout flow,
        -- which would taint the stack and cause ADDON_ACTION_FORBIDDEN (ClearTarget).
        -- We rely on editModeHeight + Blizzard's UpdateHeight and periodic re-application (ticker).
    end
    
    -- For pre-Dragonflight clients, limit width to Minimap's NORMAL width (not embedded width)
    -- This prevents quest text from being too long and going off-screen
    if not FLUX_API.hasEditMode then
        -- Use saved normal width, which stays the same even when minimap is embedded
        local minimapWidth = embeddedState.normalMinimapWidth or CONFIG.Size
        -- Adjust for scale (since tracker is scaled to 0.75)
        local maxWidth = minimapWidth / 0.75
        if math.abs((questTracker:GetWidth() or 0) - maxWidth) >= 0.5 then
            questTracker:SetWidth(maxWidth)
        end
        
        -- For Classic QuestWatchFrame, set up proper text handling
        if QuestWatchFrame then
            -- Set the frame width explicitly
            if math.abs((QuestWatchFrame:GetWidth() or 0) - maxWidth) >= 0.5 then
                QuestWatchFrame:SetWidth(maxWidth)
            end
            
            -- Try to set up text wrapping and right-justification on quest text lines
            for i = 1, 30 do
                local line = _G["QuestWatchLine" .. i]
                if line then
                    if line.SetWordWrap then line:SetWordWrap(true) end
                    if line.SetJustifyH then line:SetJustifyH("RIGHT") end
                    if line.SetWidth then line:SetWidth(maxWidth - 10) end
                    if line.SetNonSpaceWrap then line:SetNonSpaceWrap(true) end
                end
            end
            
            -- Also handle QuestWatchQuestName and QuestWatchObjective for some clients
            for i = 1, 10 do
                local questName = _G["QuestWatchQuestName" .. i]
                local objective = _G["QuestWatchObjective" .. i]
                if questName then
                    if questName.SetWordWrap then questName:SetWordWrap(true) end
                    if questName.SetJustifyH then questName:SetJustifyH("RIGHT") end
                    if questName.SetWidth then questName:SetWidth(maxWidth - 10) end
                end
                if objective then
                    if objective.SetWordWrap then objective:SetWordWrap(true) end
                    if objective.SetJustifyH then objective:SetJustifyH("RIGHT") end
                    if objective.SetWidth then objective:SetWidth(maxWidth - 10) end
                end
            end
        end
    end
    
    questTracker._fluxDockSnap = {
        embedded = isMinimapMode,
        height = availableHeight,
        parent = questTracker:GetParent(),
    }
    questTracker.fluxSettingPosition = false
end

-- Forever: PLAYER_LOGIN does not fire on /reload. AfterLogin runs on login and when
-- IsLoggedIn() already (reload). Live retail still docks from PLAYER_LOGIN only.
if Flux and Flux.AfterLogin then
    Flux.AfterLogin(function()
        if not (FLUX_API and (FLUX_API.isCamelot or FLUX_API.isForever)) then
            return
        end
        if FluxObjectiveTrackerScroll then
            if FluxObjectiveTrackerScroll.InstallForeverCompat then
                FluxObjectiveTrackerScroll:InstallForeverCompat()
            end
            if FluxObjectiveTrackerScroll.StartForeverLoginPulse then
                FluxObjectiveTrackerScroll:StartForeverLoginPulse()
            end
        end
        if FluxMinimap and FluxMinimap.UpdateQuestTrackerPosition then
            FluxMinimap:UpdateQuestTrackerPosition()
        end
    end)
end

function FluxMinimap:HandleEditMode()
    -- Try to opt-out of Edit Mode for Minimap on Retail
    if not C_EditMode then return end

    FluxUnregisterObjectiveTrackerFromEditMode()
    
    -- EditMode.Exit: Blizzard reparents/resizes the tracker; re-apply after layout settles.
    if EventRegistry and EventRegistry.RegisterCallback and not FluxMinimap._editModeExitRegistered then
        FluxMinimap._editModeExitRegistered = true
        EventRegistry:RegisterCallback("EditMode.Exit", function()
            local function restoreTracker()
                if InCombatLockdown() then return end
                if EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive
                    and EditModeManagerFrame:IsEditModeActive() then
                    return
                end
                if FluxUnregisterObjectiveTrackerFromEditMode then
                    FluxUnregisterObjectiveTrackerFromEditMode()
                end
                if not FluxMinimap then return end
                if FluxMinimap.EnforcePosition then FluxMinimap:EnforcePosition() end
                if FluxMinimap.PositionBuffFrames then FluxMinimap:PositionBuffFrames() end
                if FluxMinimap.RefreshBlizzardBuffDebuffSqueeze then FluxMinimap:RefreshBlizzardBuffDebuffSqueeze() end
                if FluxMinimap.UpdateQuestTrackerPosition then FluxMinimap:UpdateQuestTrackerPosition() end
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0, restoreTracker)
                C_Timer.After(0.25, restoreTracker)
                C_Timer.After(0.75, restoreTracker)
                C_Timer.After(1.5, restoreTracker)
            else
                restoreTracker()
            end
            if FluxMinimap.RequestEnforcerBurst then
                FluxMinimap:RequestEnforcerBurst(5)
            end
        end)
    end
    
    -- Tracker stays static: we do NOT re-apply on EDIT_MODE_LAYOUT_APPLIED /
    -- EDIT_MODE_LAYOUTS_UPDATED / spec / level-up. Those fire while leveling
    -- (Forever PLAYER_SPECIALIZATION_CHANGED) and a Flux re-dock fights Edit Mode.
    -- Position only updates on: initial load, embed toggle, tab switch, EditMode.Exit.
    -- Tab switch calls UpdateQuestTrackerPosition; unchanged dock is a no-op
    -- (_fluxDockSnap) so the tracker does not flicker.
end

-- ----------------------------------------------------------------------------
-- INFO BAR (Zone Text & Clock)
-- ----------------------------------------------------------------------------

local ZONE_TEXT_PAD_LEFT = 8
local ZONE_TEXT_PAD_RIGHT = 50 -- reserve for clock
local ZONE_SCROLL_PX_PER_SEC = 48

local function GetBorderInset()
    -- Different insets based on border type (matches FluxStatusBar logic)
    return FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases() and 4 or 2
end

--- First `n` UTF-8 codepoints of `text` (safe for non-Latin locales when utf8 lib exists).
local function utf8Prefix(text, n)
    if not text or text == "" or not n or n <= 0 then
        return ""
    end
    if utf8 and utf8.len and utf8.offset then
        local len = utf8.len(text)
        if len and n >= len then
            return text
        end
        local endByte = utf8.offset(text, n + 1, 1)
        if not endByte then
            return text
        end
        return string.sub(text, 1, endByte - 1)
    end
    if strlenutf8 then
        local len = strlenutf8(text)
        if n >= len then
            return text
        end
    end
    local pos = 1
    local bytes = #text
    local chars = 0
    while pos <= bytes and chars < n do
        local b = string.byte(text, pos)
        local charLen = 1
        if b >= 240 then
            charLen = 4
        elseif b >= 224 then
            charLen = 3
        elseif b >= 192 then
            charLen = 2
        end
        pos = pos + charLen
        chars = chars + 1
    end
    return string.sub(text, 1, pos - 1)
end

--- Returns display string and whether it was shortened vs `text`.
local function TruncateFontStringToWidth(fs, text, maxWidth)
    if not text or text == "" then
        fs:SetText("")
        return "", false
    end
    if maxWidth <= 0 then
        fs:SetText("")
        return "", true
    end
    fs:SetText(text)
    if fs:GetStringWidth() <= maxWidth then
        return text, false
    end
    local ellipsis = "..."
    fs:SetText(ellipsis)
    if fs:GetStringWidth() > maxWidth then
        fs:SetText("")
        return "", true
    end
    local n = (utf8 and utf8.len and utf8.len(text)) or (strlenutf8 and strlenutf8(text)) or #text
    if not n or n == 0 then
        fs:SetText(ellipsis)
        return ellipsis, true
    end
    local lo, hi = 0, n
    local best = ellipsis
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        local prefix = utf8Prefix(text, mid)
        local candidate = prefix .. ellipsis
        fs:SetText(candidate)
        if fs:GetStringWidth() <= maxWidth then
            best = candidate
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    fs:SetText(best)
    return best, best ~= text
end

function FluxMinimap:CreateInfoBar()
    if self.InfoBar then return end
    
    local inset = GetBorderInset()
    
    local infoBar = CreateFrame("Button", "FluxMinimapInfoBar", UIParent)
    infoBar:SetHeight(24)
    -- Anchor BOTTOM of InfoBar to TOP of Minimap with negative offset to overlap and look connected
    infoBar:SetPoint("BOTTOMLEFT", Minimap, "TOPLEFT", 0, -inset)
    infoBar:SetPoint("BOTTOMRIGHT", Minimap, "TOPRIGHT", 0, -inset)
    infoBar:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Apply FluxBorder to InfoBar
    FluxBorder:ApplyTo(infoBar)
    FluxBorder:SetClassColor(infoBar, 1, true)
    
    -- Parent text to the border frame so it renders on top of the background/border
    local textParent = infoBar.FluxBorderFrame or infoBar
    -- Let ZoneHit receive hover above the border container (default mouse behavior varies by client).
    if textParent.EnableMouse then
        textParent:EnableMouse(false)
    end

    -- Clip region for zone name (enables horizontal scroll on hover without drawing outside the bar)
    local zoneScrollClip = CreateFrame("Frame", nil, textParent)
    if zoneScrollClip.SetClipsChildren then
        zoneScrollClip:SetClipsChildren(true)
    end
    zoneScrollClip:SetPoint("TOPLEFT", infoBar, "TOPLEFT", ZONE_TEXT_PAD_LEFT, 0)
    zoneScrollClip:SetPoint("BOTTOMLEFT", infoBar, "BOTTOMLEFT", ZONE_TEXT_PAD_LEFT, 0)
    zoneScrollClip:SetWidth(100)
    
    -- Zone Text (width set in ApplyInfoBarZoneTextFit; explicit column avoids wrap/overflow)
    local zoneText = zoneScrollClip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoneText:SetPoint("TOPLEFT", zoneScrollClip, "TOPLEFT", 0, 0)
    zoneText:SetPoint("BOTTOMLEFT", zoneScrollClip, "BOTTOMLEFT", 0, 0)
    zoneText:SetWidth(1)
    zoneText:SetJustifyH("LEFT")
    pcall(function() zoneText:SetJustifyV("MIDDLE") end)
    zoneText:SetTextColor(1, 1, 1)
    if zoneText.SetWordWrap then
        zoneText:SetWordWrap(false)
    end
    pcall(function()
        if zoneText.SetMaxLines then
            zoneText:SetMaxLines(1)
        end
    end)
    
    -- Clock Text
    local timeText = textParent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeText:SetPoint("RIGHT", infoBar, "RIGHT", -8, 0)
    timeText:SetJustifyH("RIGHT")
    timeText:SetTextColor(1, 0.82, 0) -- Gold/Yellow
    
    self.InfoBar = infoBar
    self.InfoBar.ZoneScrollClip = zoneScrollClip
    self.InfoBar.ZoneText = zoneText
    self.InfoBar.TimeText = timeText
    self.InfoBar._fullZoneText = ""
    self.InfoBar._zoneTextTruncated = false
    self.InfoBar._zoneScrollActive = false

    -- Hover: scroll full zone name inside clip when truncated (does not cover clock area)
    -- Use Button so RegisterForClicks exists (Frame has no RegisterForClicks on some clients).
    local zoneHit = CreateFrame("Button", nil, infoBar)
    -- Must sit above FluxBorderFrame (typically parentFrameLevel+10) or it never receives mouse.
    zoneHit:SetFrameStrata(infoBar:GetFrameStrata() or "MEDIUM")
    local bf = infoBar.FluxBorderFrame
    local zl = (bf and bf.GetFrameLevel and bf:GetFrameLevel()) or 0
    zoneHit:SetFrameLevel(math.min(zl + 25, 65535))
    zoneHit:SetPoint("TOPLEFT", infoBar, "TOPLEFT", 0, 0)
    zoneHit:SetPoint("BOTTOMRIGHT", infoBar, "BOTTOMRIGHT", -60, 0)
    local zoneHitTex = zoneHit:CreateTexture(nil, "BACKGROUND")
    zoneHitTex:SetAllPoints()
    zoneHitTex:SetColorTexture(0, 0, 0, 0)
    zoneHit:EnableMouse(true)
    zoneHit:SetScript("OnEnter", function()
        FluxMinimap:OnInfoBarZoneHitEnter()
    end)
    zoneHit:SetScript("OnLeave", function()
        FluxMinimap:OnInfoBarZoneHitLeave()
    end)
    self.InfoBar.ZoneHit = zoneHit
    
    -- Flux perf T2.7: replaced the permanent per-frame OnUpdate with a 1s
    -- clock ticker and a demand-driven marquee OnUpdate. The zone-scroll
    -- marquee is now attached in OnInfoBarZoneHitEnter only when the label
    -- is actually wider than the clip, and is cleared in
    -- OnInfoBarZoneHitLeave / UpdateInfoBarZoneScroll when scrolling ends.
    self._infoBarFrame = infoBar
    local clockHour, clockMinute
    local function _tickClock()
        if self.InfoBar and self.InfoBar.TimeText and C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
            local date = C_DateAndTime.GetCurrentCalendarTime()
            local hour, minute = date and date.hour, date and date.minute
            if hour and minute and (hour ~= clockHour or minute ~= clockMinute) then
                self.InfoBar.TimeText:SetText(string.format("%02d:%02d", hour, minute))
                clockHour, clockMinute = hour, minute
            end
        end
    end
    local function StartClock()
        _tickClock()
        if not self._clockTicker and C_Timer and C_Timer.NewTicker then
            self._clockTicker = C_Timer.NewTicker(1, _tickClock)
        end
    end
    infoBar:HookScript("OnShow", StartClock)
    infoBar:HookScript("OnHide", function()
        if self._clockTicker then
            self._clockTicker:Cancel()
            self._clockTicker = nil
        end
        -- Inherited visibility changes need not send the hit region OnLeave.
        infoBar._zoneScrollActive = false
        infoBar._zoneScrollPos = nil
        infoBar._zoneScrollDir = nil
        infoBar._zoneScrollWidth = nil
        infoBar:SetScript("OnUpdate", nil)
    end)
    if infoBar:IsShown() then
        StartClock()
    end
    
    infoBar:RegisterEvent("ZONE_CHANGED")
    infoBar:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    infoBar:RegisterEvent("ZONE_CHANGED_INDOORS")
    infoBar:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    infoBar:SetScript("OnEvent", function()
        self:UpdateInfoBarZone()
    end)
    
    infoBar:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
             -- Default: Toggle World Map
             if ToggleFrame then ToggleFrame(WorldMapFrame) end
        else
             -- Right Click: Toggle Calendar (if available) or other time features
             -- Since we only have one bar, let's map actions:
             -- Left: Map. Right: Calendar (if available). Shift-Left: Stopwatch?
             if FLUX_API.hasCalendar then
                 ToggleCalendar()
             end
        end
    end)

    -- Forward clicks through zone hit area (otherwise mouse-enabled zoneHit would eat bar clicks)
    zoneHit:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    zoneHit:SetScript("OnClick", function(_, button)
        local handler = infoBar:GetScript("OnClick")
        if handler then
            handler(infoBar, button)
        end
    end)
    
    -- Hook specific click on TimeText area?
    -- Creating a hidden button over the time for specific Clock interactions
    local clockButton = CreateFrame("Button", nil, infoBar)
    clockButton:SetFrameStrata(infoBar:GetFrameStrata() or "MEDIUM")
    clockButton:SetFrameLevel(math.min((zoneHit.GetFrameLevel and zoneHit:GetFrameLevel() or 0) + 10, 65535))
    clockButton:SetPoint("TOPRIGHT", infoBar, "TOPRIGHT", 0, 0)
    clockButton:SetPoint("BOTTOMRIGHT", infoBar, "BOTTOMRIGHT", 0, 0)
    clockButton:SetWidth(60)
    clockButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    clockButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(clockButton, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine("Time Features")
        if FLUX_API.hasCalendar then
            GameTooltip:AddLine("|cFFeda55fLeft Click:|r Toggle Calendar", 1, 1, 1)
        end
        GameTooltip:AddLine("|cFFeda55fRight Click:|r Toggle Clock/Stopwatch", 1, 1, 1)
        GameTooltip:Show()
    end)
    clockButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    clockButton:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            if FLUX_API.hasCalendar then ToggleCalendar() end
        else
            -- Right Click: Toggle Stopwatch or TimeManager
            if ToggleTimeManager then ToggleTimeManager() end
            if Stopwatch_Toggle then Stopwatch_Toggle() end
        end
    end)
    
    -- Initial Update
    self:UpdateInfoBarZone()
    FluxMinimap.NotifyInfoFrameLayoutChanged()
end

function FluxMinimap:ApplyInfoBarZoneTextFit(fullText, r, g, b)
    local ib = self.InfoBar
    if not ib or not ib.ZoneText then return end
    ib._fullZoneText = fullText or ""
    ib._lastZoneR, ib._lastZoneG, ib._lastZoneB = r, g, b
    local w = ib:GetWidth()
    if not w or w <= 0 then
        w = CONFIG.Size
    end
    local maxWidth = math.max(1, w - ZONE_TEXT_PAD_LEFT - ZONE_TEXT_PAD_RIGHT)
    local ft = ib.ZoneText
    local clip = ib.ZoneScrollClip
    if clip then
        clip:SetWidth(maxWidth)
    end
    ib._zoneScrollActive = false
    ib._zoneScrollPos = nil
    ib._zoneScrollDir = nil
    ib._zoneScrollWidth = nil
    -- Zone/layout events can refit the label before the hover region sees a
    -- leave. Do not retain a per-frame script after that refit stops scrolling.
    local bar = self._infoBarFrame
    if bar then
        bar:SetScript("OnUpdate", nil)
    end
    ft:ClearAllPoints()
    if clip then
        ft:SetPoint("TOPLEFT", clip, "TOPLEFT", 0, 0)
        ft:SetPoint("BOTTOMLEFT", clip, "BOTTOMLEFT", 0, 0)
    else
        ft:SetPoint("TOPLEFT", ib, "TOPLEFT", ZONE_TEXT_PAD_LEFT, 0)
        ft:SetPoint("BOTTOMLEFT", ib, "BOTTOMLEFT", ZONE_TEXT_PAD_LEFT, 0)
    end
    ft:SetWidth(maxWidth)
    local _, truncated = TruncateFontStringToWidth(ft, fullText or "", maxWidth)
    ib._zoneTextTruncated = truncated
    ft:SetTextColor(r, g, b)
end

function FluxMinimap:OnInfoBarZoneHitEnter()
    local ib = self.InfoBar
    if not ib or not ib.ZoneText or not ib.ZoneScrollClip then return end
    if not ib._fullZoneText or ib._fullZoneText == "" then return end
    local clip = ib.ZoneScrollClip
    local ft = ib.ZoneText
    local clipW = clip:GetWidth()
    if not clipW or clipW <= 0 then return end
    ft:SetText(ib._fullZoneText)
    if ft.SetWidth then
        ft:SetWidth(0)
    end
    local fullW = ft:GetStringWidth()
    -- Scroll whenever the full label is wider than the clip (not only when ellipsis was used).
    if fullW <= clipW + 1 then
        return
    end
    ib._zoneScrollActive = true
    ib._zoneScrollPos = 0
    ib._zoneScrollDir = -1
    ib._zoneScrollWidth = fullW
    ft:ClearAllPoints()
    ft:SetPoint("LEFT", clip, "LEFT", 0, 0)
    local r, g, b = ib._lastZoneR or 1, ib._lastZoneG or 1, ib._lastZoneB or 1
    ft:SetTextColor(r, g, b)

    -- Flux perf T2.7: attach the marquee OnUpdate only while scrolling is active.
    local bar = self._infoBarFrame
    if bar then
        bar:SetScript("OnUpdate", function(_, elapsed)
            self:UpdateInfoBarZoneScroll(elapsed)
        end)
    end
end

function FluxMinimap:OnInfoBarZoneHitLeave()
    local ib = self.InfoBar
    if not ib then return end
    if ib._zoneScrollActive then
        ib._zoneScrollActive = false
        ib._zoneScrollPos = nil
        ib._zoneScrollDir = nil
        ib._zoneScrollWidth = nil
    end
    -- Flux perf T2.7: detach the marquee OnUpdate when no longer needed.
    local bar = self._infoBarFrame
    if bar then
        bar:SetScript("OnUpdate", nil)
    end
    self:UpdateInfoBarZone()
end

function FluxMinimap:UpdateInfoBarZoneScroll(elapsed)
    local ib = self.InfoBar
    if not ib or not ib._zoneScrollActive or not ib.ZoneText or not ib.ZoneScrollClip then
        local bar = self._infoBarFrame
        if bar then bar:SetScript("OnUpdate", nil) end
        return
    end
    local clip = ib.ZoneScrollClip
    local ft = ib.ZoneText
    local clipW = clip:GetWidth()
    if not clipW or clipW <= 0 then return end
    -- Enter/refit owns this text and its measurement. Animation only changes
    -- the position; formatting and measuring it every frame invalidates text
    -- layout even when the zone and font have not changed.
    local fullW = ib._zoneScrollWidth
    if not fullW then
        ft:SetText(ib._fullZoneText or "")
        if ft.SetWidth then ft:SetWidth(0) end
        fullW = ft:GetStringWidth()
        ib._zoneScrollWidth = fullW
    end
    local maxScroll = math.max(0, fullW - clipW)
    if maxScroll <= 0 then
        ib._zoneScrollActive = false
        ib._zoneScrollPos = nil
        ib._zoneScrollDir = nil
        ib._zoneScrollWidth = nil
        -- Flux perf T2.7: zone now fits; stop the marquee OnUpdate.
        local bar = self._infoBarFrame
        if bar then
            bar:SetScript("OnUpdate", nil)
        end
        self:UpdateInfoBarZone()
        return
    end
    local pos = ib._zoneScrollPos or 0
    local dir = ib._zoneScrollDir or -1
    pos = pos + dir * ZONE_SCROLL_PX_PER_SEC * elapsed
    if pos > 0 then
        pos = 0
        ib._zoneScrollDir = -1
    elseif pos < -maxScroll then
        pos = -maxScroll
        ib._zoneScrollDir = 1
    end
    ib._zoneScrollPos = pos
    ft:ClearAllPoints()
    ft:SetPoint("LEFT", clip, "LEFT", pos, 0)
end

function FluxMinimap:RefreshInfoBarZoneFit()
    self:UpdateInfoBarZone()
end

function FluxMinimap:UpdateInfoBarZone()
    if not self.InfoBar then return end

    local zoneName = GetZoneText() or ""
    local subZoneName = GetSubZoneText() or ""
    local fullText
    if subZoneName ~= "" and subZoneName ~= zoneName then
        fullText = zoneName .. " - " .. subZoneName
    else
        fullText = zoneName
    end

    local pvpType
    if C_PvP and C_PvP.GetZonePVPInfo then
        pvpType = C_PvP.GetZonePVPInfo()
    elseif GetZonePVPInfo then
        pvpType = GetZonePVPInfo()
    end
    local r, g, b = 1, 1, 1
    if pvpType == "sanctuary" then
        r, g, b = 0.41, 0.8, 0.94
    elseif pvpType == "arena" then
        r, g, b = 1, 0.1, 0.1
    elseif pvpType == "friendly" then
        r, g, b = 0.1, 1, 0.1
    elseif pvpType == "hostile" then
        r, g, b = 1, 0.1, 0.1
    elseif pvpType == "contested" then
        r, g, b = 1, 0.7, 0
    end
    self:ApplyInfoBarZoneTextFit(fullText, r, g, b)
end

--- Flux perf T2.7: legacy per-frame accumulator preserved for backward compat.
--- The clock is now driven by a 1s C_Timer.NewTicker created when the info bar
--- is set up; this function is retained as a no-op in case any external caller
--- still invokes it.
function FluxMinimap:UpdateInfoBarTime(_)
end

-- ----------------------------------------------------------------------------
-- EMBED / RESTORE FUNCTIONS
-- ----------------------------------------------------------------------------

-- MinimapCluster is an Edit Mode system; Edit Mode shows it inside its pass.
local function KeepMinimapClusterHidden()
    local cluster = _G.MinimapCluster
    if not cluster or not embeddedState.isEmbedded then
        return
    end
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(KeepMinimapClusterHidden)
        return
    end
    local onMapTab = FluxWindowFrame and FluxWindowFrame.GetActiveTab
        and FluxWindowFrame:GetActiveTab() == "Map"
    if not onMapTab and cluster:IsShown() then
        cluster:Hide()
    end
end

local function HookMinimapClusterKeepHidden()
    if MinimapCluster.fluxHooked then
        return
    end
    MinimapCluster.fluxHooked = true
    MinimapCluster:HookScript("OnShow", KeepMinimapClusterHidden)
end

--- Embed the Minimap inside a parent frame (for FluxWindowFrame integration)
-- @param parentFrame The frame to embed the Minimap into
function FluxMinimap:EmbedInFrame(parentFrame)
    if not parentFrame or not Minimap then return false end
    
    -- Already embedded in this parent
    if embeddedState.isEmbedded and embeddedState.parentFrame == parentFrame then
        return true
    end
    
    -- Store original state before embedding (safe to do in combat)
    if not embeddedState.isEmbedded then
        embeddedState.originalParent = Minimap:GetParent()
        embeddedState.originalSize = { Minimap:GetSize() }
        -- Store position info (safe to read in combat)
        local point, relativeTo, relativePoint, x, y = Minimap:GetPoint(1)
        embeddedState.originalPosition = { point, relativeTo, relativePoint, x, y }
        
        -- Store InfoBar original state
        if self.InfoBar then
            local ibPoint, ibRelativeTo, ibRelativePoint, ibX, ibY = self.InfoBar:GetPoint(1)
            embeddedState.originalInfoBarPosition = { ibPoint, ibRelativeTo, ibRelativePoint, ibX, ibY }
            embeddedState.originalInfoBarParent = self.InfoBar:GetParent()
        end
    end
    
    embeddedState.isEmbedded = true
    embeddedState.parentFrame = parentFrame
    
    -- Get the border inset
    local inset = (FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases()) and 4 or 2
    local infoBarHeight = 24
    
    -- Get parent dimensions - ensure we have valid dimensions
    local parentWidth, parentHeight = parentFrame:GetSize()
    
    -- If parent frame doesn't have valid size yet (login/reload), use window frame constants
    if (not parentWidth or parentWidth <= 0) and FluxWindowFrame then
        parentWidth = FluxWindowFrame.WINDOW_WIDTH or 405
    end
    if (not parentHeight or parentHeight <= 0) and FluxWindowFrame then
        parentHeight = FluxWindowFrame.WINDOW_HEIGHT or 270
    end
    
    -- Fallback to reasonable defaults if still invalid
    if not parentWidth or parentWidth <= 0 then
        parentWidth = 405
    end
    if not parentHeight or parentHeight <= 0 then
        parentHeight = 270
    end
    
    -- Calculate minimap size (square, fit within available height)
    local availableHeight = parentHeight - infoBarHeight + inset
    local mapSize = math.min(parentWidth, availableHeight)  -- Keep it square
    
    -- SAFE OPERATIONS (can be done during combat):
    -- SetSize, SetScale, SetFrameStrata, SetFrameLevel, Show() are all safe
    Minimap:SetSize(mapSize, mapSize)  -- Safe in combat
    Minimap:SetScale(1.0) -- Reset scale when embedded (safe in combat)
    Minimap:SetFrameStrata("MEDIUM")  -- Safe in combat
    Minimap:SetFrameLevel(2)  -- Safe in combat
    Minimap:Show()  -- Safe in combat
    
    -- Also ensure the minimap's FluxBorder is at an appropriate level (safe)
    if Minimap.FluxBorderFrame then
        Minimap.FluxBorderFrame:SetFrameLevel(3)  -- Safe in combat
    end
    
    -- InfoBar sizing (safe in combat)
    if self.InfoBar then
        self.InfoBar:SetWidth(mapSize)  -- Safe in combat
        self.InfoBar:SetHeight(infoBarHeight)  -- Safe in combat
        self.InfoBar:SetFrameStrata("MEDIUM")  -- Safe in combat
        self.InfoBar:SetFrameLevel(4)  -- Safe in combat
        self.InfoBar:Show()  -- Safe in combat
        if self.RefreshInfoBarZoneFit then
            self:RefreshInfoBarZoneFit()
        end
    end
    
    -- PROTECTED OPERATIONS (must be queued during combat):
    -- SetParent, ClearAllPoints, SetPoint are protected
    local inCombat = InCombatLockdown()
    
    if inCombat then
        -- Queue positioning operations for after combat
        table.insert(minimapPositionQueue, {
            type = "embed",
            parentFrame = parentFrame,
            mapSize = mapSize,
            infoBarHeight = infoBarHeight,
            inset = inset
        })
        
        -- Register for combat end if not already registered
        if not FluxMinimap._positionQueueRegistered then
            FluxMinimap:RegisterEvent("PLAYER_REGEN_ENABLED")
            FluxMinimap._positionQueueRegistered = true
        end
        
        -- Return true because sizing succeeded (minimap is properly sized)
        -- Positioning will be applied when combat ends
        return true
    else
        -- Not in combat, do positioning immediately
        Minimap:SetParent(parentFrame)
        Minimap:ClearAllPoints()
        Minimap:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 0, -infoBarHeight + inset)
        
        -- Now position the InfoBar to match minimap width, aligned to the right
        if self.InfoBar then
            self.InfoBar:SetParent(parentFrame)
            self.InfoBar:ClearAllPoints()
            -- Position above the minimap, matching its width (right-aligned)
            self.InfoBar:SetPoint("BOTTOMRIGHT", Minimap, "TOPRIGHT", 0, -inset)
        end
    end
    
    -- Ensure the parent's (FluxWindowFrame) border is on top of everything
    if parentFrame.FluxBorderFrame then
        parentFrame.FluxBorderFrame:SetFrameLevel(20)  -- Higher than minimap and its border
    end
    
    -- CRITICAL: Hide MinimapCluster when embedding (contains zone text and timer)
    -- This must happen instantly, even during combat
    if MinimapCluster then
        MinimapCluster:Hide()  -- Safe in combat
        HookMinimapClusterKeepHidden()
    end
    
    -- Re-apply styling and position elements
    self:UpdateStyle()
    self:PositionIndicators()
    FluxMinimap_TryRebuildMicroMenuPos3()
    
    -- Quest tracker: update position/height on embed toggle (stays static otherwise)
    if self.UpdateQuestTrackerPosition then
        self:UpdateQuestTrackerPosition()
    end

    
    -- Ensure proper sizing after embedding (especially important on login/reload)
    -- Use a watcher to re-apply sizing if parent frame size changes or wasn't ready initially
    if not self._embedSizeWatcher then
        self._embedSizeWatcher = CreateFrame("Frame")
    end
    
    local checkCount = 0
    local MAX_CHECKS = 30  -- Increased to allow more time for parent frame to get proper size
    self._embedSizeWatcher:SetScript("OnUpdate", function(watcher, elapsed)
        checkCount = checkCount + 1
        
        -- CRITICAL: Ensure MinimapCluster stays hidden when embedded (especially on login/reload)
        if embeddedState.isEmbedded and MinimapCluster then
            -- Check if we're on Map tab
            local shouldHideCluster = true
            if FluxWindowFrame and FluxWindowFrame.GetActiveTab then
                local activeTab = FluxWindowFrame:GetActiveTab()
                if activeTab == "Map" then
                    -- On Map tab, cluster should still be hidden (we use InfoBar instead)
                    shouldHideCluster = true
                end
            end
            
            if shouldHideCluster and MinimapCluster:IsShown() then
                MinimapCluster:Hide()  -- Safe in combat
            end
        end
        
        -- Re-check parent dimensions and re-apply sizing if needed
        if embeddedState.isEmbedded and embeddedState.parentFrame and Minimap then
            local currentParentWidth, currentParentHeight = embeddedState.parentFrame:GetSize()
            
            -- Only re-apply if we have valid dimensions
            if currentParentWidth and currentParentWidth > 0 and currentParentHeight and currentParentHeight > 0 then
                local inset = (FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases()) and 4 or 2
                local infoBarHeight = 24
                local availableHeight = currentParentHeight - infoBarHeight + inset
                local newMapSize = math.min(currentParentWidth, availableHeight)
                
                -- Get current minimap size
                local currentMapSize = Minimap:GetWidth()
                
                -- Always re-apply sizing if parent frame now has valid size (even if sizes match)
                -- This ensures proper sizing on login/reload when parent frame wasn't ready initially
                if math.abs(newMapSize - currentMapSize) > 1 or checkCount <= 5 then
                    -- Re-apply sizing (safe in combat)
                    Minimap:SetSize(newMapSize, newMapSize)
                    
                    -- Also update InfoBar width
                    if FluxMinimap.InfoBar then
                        FluxMinimap.InfoBar:SetWidth(newMapSize)
                        if FluxMinimap.RefreshInfoBarZoneFit then
                            FluxMinimap:RefreshInfoBarZoneFit()
                        end
                    end
                    
                    -- Re-position if not in combat
                    if not InCombatLockdown() then
                        Minimap:ClearAllPoints()
                        Minimap:SetPoint("TOPRIGHT", embeddedState.parentFrame, "TOPRIGHT", 0, -infoBarHeight + inset)
                        
                        if FluxMinimap.InfoBar then
                            FluxMinimap.InfoBar:ClearAllPoints()
                            FluxMinimap.InfoBar:SetPoint("BOTTOMRIGHT", Minimap, "TOPRIGHT", 0, -inset)
                        end
                    end
                end
                
                -- Stop watching once we've applied correct sizing and parent has valid size
                if math.abs(newMapSize - currentMapSize) <= 1 and checkCount > 5 then
                    watcher:SetScript("OnUpdate", nil)
                end
            end
        end
        
        -- Stop watching after max checks
        if checkCount >= MAX_CHECKS then
            watcher:SetScript("OnUpdate", nil)
        end
    end)

    -- Notify FluxMinimapButtons of embedding state change
    if FluxMinimapButtons and FluxMinimapButtons.OnEmbedStateChanged then
        FluxMinimapButtons:OnEmbedStateChanged(true)
    end

    -- Position FluxMinimapButtons if available
    if FluxMinimapButtons and FluxMinimapButtons.PositionInWindow then
        local minimapWidth = mapSize
        local infoBarHeight = infoBarHeight
        local inset = inset
        FluxMinimapButtons:PositionInWindow(parentFrame, minimapWidth, infoBarHeight, inset)
    end

    -- Notify Questie integration of embedding state change
    if self.OnEmbeddingStateChanged then
        self:OnEmbeddingStateChanged()
    end

    -- Force refresh to fix texture resolution
    self:Refresh()

    if self.RefreshInfoBarZoneFit then
        self:RefreshInfoBarZoneFit()
    end

    return true
end

--- Restore the Minimap to its normal position (top-right corner)
function FluxMinimap:RestoreToNormal()
    if not embeddedState.isEmbedded then return end
    
    embeddedState.isEmbedded = false
    embeddedState.parentFrame = nil
    
    -- Stop the sizing watcher if it's running
    if self._embedSizeWatcher then
        self._embedSizeWatcher:SetScript("OnUpdate", nil)
    end
    
    -- SAFE OPERATIONS (can be done during combat):
    -- SetSize, SetScale, SetFrameStrata, SetFrameLevel, Show() are all safe
    -- Always restore to CONFIG size to ensure proper sizing (originalSize might be incorrect if stored during login/reload)
    if FLUX_API.isLegacyClient then
        Minimap:SetSize(175, CONFIG.Size)
    else
        Minimap:SetSize(CONFIG.Size, CONFIG.Size)
    end
    
    -- Reset scale to CONFIG scale
    Minimap:SetScale(CONFIG.Scale)
    
    -- Restore InfoBar size (safe in combat)
    if self.InfoBar then
        self.InfoBar:Show()  -- Safe in combat
        -- Reset InfoBar to its default width (will be set by EnforcePosition/positioning)
    end
    
    -- PROTECTED OPERATIONS (must be queued during combat):
    local inCombat = InCombatLockdown()
    
    if inCombat then
        -- Queue positioning operations for after combat
        table.insert(minimapPositionQueue, {
            type = "restore"
        })
        
        -- Register for combat end if not already registered
        if not FluxMinimap._positionQueueRegistered then
            FluxMinimap:RegisterEvent("PLAYER_REGEN_ENABLED")
            FluxMinimap._positionQueueRegistered = true
        end
        
        -- Return early - sizing is done, positioning will be queued
        return
    else
        -- Not in combat, do positioning immediately
        -- Restore parent
        Minimap:SetParent(embeddedState.originalParent or UIParent)
        Minimap:ClearAllPoints()
        
        -- Restore position
        if embeddedState.originalPosition then
            Minimap:SetPoint(unpack(embeddedState.originalPosition))
        end
        
        -- Restore InfoBar to original position
        if self.InfoBar then
            self.InfoBar:SetParent(embeddedState.originalInfoBarParent or UIParent)
            self.InfoBar:ClearAllPoints()
            
            -- Re-anchor InfoBar above the Minimap
            local inset = (FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases()) and 4 or 2
            self.InfoBar:SetPoint("BOTTOMLEFT", Minimap, "TOPLEFT", 0, -inset)
            self.InfoBar:SetPoint("BOTTOMRIGHT", Minimap, "TOPRIGHT", 0, -inset)
        end
    end
    

    -- Notify FluxMinimapButtons of embedding state change
    if FluxMinimapButtons and FluxMinimapButtons.OnEmbedStateChanged then
        FluxMinimapButtons:OnEmbedStateChanged(false)
    end

    -- Re-apply normal position (this also ensures proper sizing)
    self:EnforcePosition()

    -- Re-apply styling and position elements
    self:UpdateStyle()
    self:PositionIndicators()
    
    -- Quest tracker: update position/height on embed toggle (only time we reposition)
    if self.UpdateQuestTrackerPosition then
        self:UpdateQuestTrackerPosition()
    end

    -- Notify Questie integration of embedding state change
    if self.OnEmbeddingStateChanged then
        self:OnEmbeddingStateChanged()
    end

    -- Force refresh to fix texture resolution
    self:Refresh()

    if self.RefreshInfoBarZoneFit then
        self:RefreshInfoBarZoneFit()
    end
    
    -- Ensure proper sizing after restore (use watcher to handle any delayed sizing issues)
    if not self._restoreSizeWatcher then
        self._restoreSizeWatcher = CreateFrame("Frame")
    end
    
    local checkCount = 0
    local MAX_CHECKS = 10
    self._restoreSizeWatcher:SetScript("OnUpdate", function(watcher, elapsed)
        checkCount = checkCount + 1
        
        -- Ensure minimap has correct size
        if not embeddedState.isEmbedded and Minimap then
            local expectedWidth = FLUX_API.isLegacyClient and 175 or CONFIG.Size
            local expectedHeight = CONFIG.Size
            local currentWidth, currentHeight = Minimap:GetSize()
            
            -- If size doesn't match, re-apply
            if math.abs(currentWidth - expectedWidth) > 1 or math.abs(currentHeight - expectedHeight) > 1 then
                Minimap:SetSize(expectedWidth, expectedHeight)
                Minimap:SetScale(CONFIG.Scale)
                
                -- Re-enforce position to ensure everything is correct
                if not InCombatLockdown() then
                    FluxMinimap:EnforcePosition()
                end
            end
            
            -- Stop watching once size is correct
            if math.abs(currentWidth - expectedWidth) <= 1 and math.abs(currentHeight - expectedHeight) <= 1 then
                watcher:SetScript("OnUpdate", nil)
            end
        end
        
        -- Stop watching after max checks
        if checkCount >= MAX_CHECKS then
            watcher:SetScript("OnUpdate", nil)
        end
    end)
end

--- Check if the Minimap is currently embedded
function FluxMinimap:IsEmbedded()
    return embeddedState.isEmbedded
end

--- Width of the top-right minimap, not the size used while it is embedded.
function FluxMinimap:GetNormalWidth()
    local w = embeddedState.normalMinimapWidth
    if type(w) == "number" and w > 50 then
        return w
    end
    if FLUX_API and FLUX_API.isLegacyClient then
        return 175
    end
    return CONFIG.Size
end

--- Hide the embedded minimap (but keep it embedded, don't restore to normal)
function FluxMinimap:HideEmbedded()
    if not embeddedState.isEmbedded then return end

    -- Hide minimap and InfoBar (safe in combat)
    Minimap:Hide()
    if self.InfoBar then
        self.InfoBar:Hide()
    end
    
    -- CRITICAL: Hide MinimapCluster instantly (contains zone text and timer)
    -- This must happen instantly even during combat
    if MinimapCluster then
        MinimapCluster:Hide()  -- Safe in combat
        HookMinimapClusterKeepHidden()
    end
    
    -- Also hide the minimap buttons
    if FluxMinimapButtons and FluxMinimapButtons.OnEmbedStateChanged then
        FluxMinimapButtons:OnEmbedStateChanged(false)
    end
    FluxMinimap_TryRebuildMicroMenuPos3()
    FluxMinimap.NotifyInfoFrameLayoutChanged()
end

--- Show the embedded minimap (when returning to the tab)
function FluxMinimap:ShowEmbedded()
    if not embeddedState.isEmbedded then return end

    Minimap:Show()
    if self.InfoBar then
        self.InfoBar:Show()
    end
    
    -- Keep MinimapCluster hidden when embedded (we use our own InfoBar)
    if MinimapCluster then
        MinimapCluster:Hide()  -- Always hide cluster when embedded
    end
    
    -- Also show the minimap buttons
    if FluxMinimapButtons and FluxMinimapButtons.OnEmbedStateChanged then
        FluxMinimapButtons:OnEmbedStateChanged(true)
    end
    FluxMinimap_TryRebuildMicroMenuPos3()
    FluxMinimap.NotifyInfoFrameLayoutChanged()
end

--- Notify FluxInfoFrame when Layout uses \"Above minimap\" so the FPS strip tracks embed / zone bar / resize.
function FluxMinimap.NotifyInfoFrameLayoutChanged()
    local FO = _G.FluxOptions
    if not FO or not FO.GetInfoFramePlacement or FO:GetInfoFramePlacement() ~= "minimapTop" then
        return
    end
    local fn = _G.FluxInfoFrame and _G.FluxInfoFrame.UpdatePosition
    if type(fn) == "function" then
        pcall(fn)
    end
end

--- Force a refresh of the minimap content (fixes blurry/stale map after resize).
-- This simulates movement by toggling zoom, demanding a texture update from the client.
function FluxMinimap:Refresh()
    if not Minimap:IsVisible() then return end
    
    -- 1. Call standard update if available
    if Minimap_Update then
        Minimap_Update()
    end
    
    -- 2. Force texture refresh by toggling zoom
    -- We can't actually change the zoom if it's maxed out, so we handle both directions
    local currentZoom = Minimap:GetZoom()
    local maxZoom = Minimap.GetZoomLevels and Minimap:GetZoomLevels() or 5
    
    if currentZoom < maxZoom then
        Minimap:SetZoom(currentZoom + 1)
        Minimap:SetZoom(currentZoom)
    else
        Minimap:SetZoom(currentZoom - 1)
        Minimap:SetZoom(currentZoom)
    end

    FluxMinimap.NotifyInfoFrameLayoutChanged()
end

-- ----------------------------------------------------------------------------
-- HIDDEN PARENT FRAME
-- ----------------------------------------------------------------------------
-- A dumping ground for frames we want to permanently hide
FluxMinimapHiddenFrame = CreateFrame("Frame")
FluxMinimapHiddenFrame:Hide()

if addonTable.Flux and addonTable.Flux.Module then
    addonTable.Flux.Module.Register("MinimapHUD", {
        phase = "hud", priority = 60,
        OnEnable = function()
            return FluxMinimap:GetScript("OnEvent")(FluxMinimap, "PLAYER_LOGIN")
        end,
    })
end
