-- FluxVehicleExitButton.lua
-- Custom vehicle exit button that replicates MainMenuBarVehicleLeaveButton functionality
-- Works across all client versions (classic_anniversary, beta, classic_era)
-- Positioned left-aligned above player frame's outer border

local addonName, ns = ...

-- ---------------------------------------------------------------------------
-- VERSION DETECTION
-- ---------------------------------------------------------------------------
if not FLUX_API then
    print("|cFFFF0000[FluxUI]|r FLUX_API not found! Make sure FluxAPICompat.lua loads before this file.")
    return
end

local majorVersion = FLUX_API.majorVersion
local isRetail = FLUX_API.isRetail
local isClassicEra = FLUX_API.isClassicEra
local isWrath = FLUX_API.isWrath
local isModernClient = FLUX_API.isModernClient
local isLegacyClient = FLUX_API.isLegacyClient

-- ---------------------------------------------------------------------------
-- FLUX VEHICLE EXIT BUTTON MODULE
-- ---------------------------------------------------------------------------
local FluxVehicleExitButton = {}
ns.FluxVehicleExitButton = FluxVehicleExitButton

-- Button frame reference
local button = nil

-- Action bar state constants (with fallbacks)
local LE_ACTIONBAR_STATE_MAIN = LE_ACTIONBAR_STATE_MAIN or 0
local LE_ACTIONBAR_STATE_OVERRIDE = LE_ACTIONBAR_STATE_OVERRIDE or 1

-- ---------------------------------------------------------------------------
-- HELPER FUNCTIONS
-- ---------------------------------------------------------------------------

-- Check if ActionBarController API is available
local function HasActionBarController()
    return ActionBarController_GetCurrentActionBarState ~= nil
end

-- Get current action bar state (with fallback)
local function GetCurrentActionBarState()
    if HasActionBarController() then
        return ActionBarController_GetCurrentActionBarState()
    end
    -- Fallback: assume main state if API not available
    return LE_ACTIONBAR_STATE_MAIN
end

-- Check if we can exit vehicle
local function CanExitVehicleCheck()
    if _G.CanExitVehicle then
        return _G.CanExitVehicle()
    end
    return false
end

-- Check if player is on taxi
local function IsOnTaxi()
    if _G.UnitOnTaxi then
        return _G.UnitOnTaxi("player")
    end
    return false
end

-- ---------------------------------------------------------------------------
-- BUTTON CREATION
-- ---------------------------------------------------------------------------

function FluxVehicleExitButton:Create()
    if button then return button end

    -- Create button frame (combat-safe for show/hide operations)
    button = CreateFrame("Button", "FluxVehicleExitButton", UIParent)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(100) -- High enough to be above unit frames
    
    -- Set up textures (matching Blizzard's implementation)
    local normalTexture = button:CreateTexture(nil, "ARTWORK")
    normalTexture:SetTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
    normalTexture:SetAllPoints()
    button:SetNormalTexture(normalTexture)
    
    -- Set texture coordinates (matching Blizzard XML: 0.140625, 0.859375, 0.140625, 0.859375)
    if button:GetNormalTexture() then
        button:GetNormalTexture():SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
    end
    
    local pushedTexture = button:CreateTexture(nil, "ARTWORK")
    pushedTexture:SetTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
    pushedTexture:SetAllPoints()
    button:SetPushedTexture(pushedTexture)
    
    if button:GetPushedTexture() then
        button:GetPushedTexture():SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
    end
    
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetTexture("Interface\\Vehicles\\UI-Vehicles-Button-Highlight")
    highlightTexture:SetAllPoints()
    highlightTexture:SetBlendMode("ADD")
    button:SetHighlightTexture(highlightTexture)
    
    if button:GetHighlightTexture() then
        -- Highlight uses slightly different coords (from Blizzard XML: 0.130625, 0.879375, 0.130625, 0.879375)
        button:GetHighlightTexture():SetTexCoord(0.130625, 0.879375, 0.130625, 0.879375)
    end
    
    -- Set up scripts
    button:SetScript("OnClick", function(self)
        FluxVehicleExitButton:OnClick(self)
    end)
    
    button:SetScript("OnEnter", function(self)
        FluxVehicleExitButton:OnEnter(self)
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Register events
    FluxVehicleExitButton:RegisterEvents()
    
    -- Initial hide
    button:Hide()
    
    -- Store reference
    self.button = button
    
    return button
end

-- ---------------------------------------------------------------------------
-- EVENT HANDLING
-- ---------------------------------------------------------------------------

function FluxVehicleExitButton:RegisterEvents()
    if not button then return end

    -- Flux perf T2.5: removed the permanent 10Hz OnUpdate poller. All state
    -- transitions that affect this button are event-observable; the prior
    -- polling existed as a belt-and-suspenders that effectively ran forever.
    button:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    button:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR")
    button:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
    button:RegisterEvent("UNIT_ENTERED_VEHICLE")
    button:RegisterEvent("UNIT_EXITED_VEHICLE")
    button:RegisterEvent("VEHICLE_UPDATE")
    button:RegisterEvent("PLAYER_CONTROL_GAINED")
    button:RegisterEvent("PLAYER_CONTROL_LOST")
    -- Taxi start/end reliably toggle the exit affordance.
    button:RegisterEvent("PLAYER_ENTERING_WORLD")

    -- Set event handler
    button:SetScript("OnEvent", function(buttonFrame, event, ...)
        FluxVehicleExitButton:OnEvent(buttonFrame, event, ...)
    end)
end

function FluxVehicleExitButton:OnEvent(buttonFrame, event, ...)
    -- For UNIT_ENTERED_VEHICLE and UNIT_EXITED_VEHICLE, check if it's for the player
    if event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
        local unit = ...
        if unit and unit ~= "player" then
            return -- Only care about player vehicle events
        end
    end
    
    -- Immediate update on vehicle/taxi events
    FluxVehicleExitButton:Update()
    
    -- Also update after a tiny delay to catch any state changes that happen slightly after the event
    if C_Timer and C_Timer.After then
        C_Timer.After(0.01, function()
            if button then
                FluxVehicleExitButton:Update()
            end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- VISIBILITY AND STATE LOGIC
-- ---------------------------------------------------------------------------

function FluxVehicleExitButton:CanExitVehicle()
    -- Check if we can exit vehicle or are on taxi
    local canExit = CanExitVehicleCheck()
    local onTaxi = IsOnTaxi()
    
    if not (canExit or onTaxi) then
        return false
    end
    
    -- Check action bar state (must be in main state)
    local actionBarState = GetCurrentActionBarState()
    if actionBarState ~= LE_ACTIONBAR_STATE_MAIN then
        return false
    end
    
    return true
end

function FluxVehicleExitButton:Update()
    if not button then return end
    
    local canExit = self:CanExitVehicle()
    
    -- Track previous state to avoid unnecessary show/hide calls
    local wasShown = button:IsShown()
    local shouldShow = canExit
    
    -- Show/Hide can be done in combat (combat-safe operations)
    -- Only SetPoint operations are restricted during combat
    if wasShown ~= shouldShow then
        if shouldShow then
            -- Show button (combat-safe)
            button:Show()
            button:Enable()
            
            -- Flux hides Blizzard PetActionBar; pet bar is FluxPetBar.
        else
            -- Reset highlight state
            button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")
            if button.UnlockHighlight then
                button:UnlockHighlight()
            end
            
            -- Hide button (combat-safe)
            button:Hide()
            
            -- Flux hides Blizzard PetActionBar; pet bar is FluxPetBar.
        end
    elseif shouldShow then
        -- If already shown, ensure it's enabled
        button:Enable()
    end
end

-- ---------------------------------------------------------------------------
-- CLICK HANDLING
-- ---------------------------------------------------------------------------

function FluxVehicleExitButton:OnClick(self)
    if IsOnTaxi() then
        -- Handle taxi early landing
        if TaxiRequestEarlyLanding then
            TaxiRequestEarlyLanding()
        end
        
        -- Show that the request for landing has been received
        button:Disable()
        button:SetHighlightTexture([[Interface\Buttons\CheckButtonHilight]], "ADD")
        if button.LockHighlight then
            button:LockHighlight()
        end
    else
        -- Handle vehicle exit
        if VehicleExit then
            VehicleExit()
        end
    end
end

-- ---------------------------------------------------------------------------
-- TOOLTIP
-- ---------------------------------------------------------------------------

function FluxVehicleExitButton:OnEnter(self)
    if IsOnTaxi() then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        
        -- Use TAXI_CANCEL if available, otherwise use fallback text
        if TAXI_CANCEL then
            GameTooltip_SetTitle(GameTooltip, TAXI_CANCEL)
        else
            GameTooltip:SetText("Cancel Flight", 1, 1, 1)
        end
        
        if TAXI_CANCEL_DESCRIPTION then
            GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
        else
            GameTooltip:AddLine("Click to request early landing", 1, 1, 1, true)
        end
        
        GameTooltip:Show()
    else
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        
        -- Use LEAVE_VEHICLE if available, otherwise use fallback text
        if LEAVE_VEHICLE then
            if GameTooltip_SetTitle then
                GameTooltip_SetTitle(GameTooltip, LEAVE_VEHICLE)
            else
                GameTooltip:SetText(LEAVE_VEHICLE, 1, 1, 1)
            end
        else
            GameTooltip:SetText("Leave Vehicle", 1, 1, 1)
        end
        
        -- Classic era uses GameTooltip_AddNewbieTip
        if isClassicEra and GameTooltip_AddNewbieTip then
            GameTooltip_AddNewbieTip(self, LEAVE_VEHICLE or "Leave Vehicle", 1.0, 1.0, 1.0, nil)
        end
        
        GameTooltip:Show()
    end
end

-- ---------------------------------------------------------------------------
-- POSITIONING
-- ---------------------------------------------------------------------------

function FluxVehicleExitButton:UpdatePosition()
    if not button then return end
    
    -- Check if player frame and outer border are available
    local playerFrame = ns.PlayerFrame
    if not playerFrame or not playerFrame.outerBorderFrame then
        return
    end
    
    -- Combat safety check - defer positioning if in combat
    -- Note: Show/Hide can be done in combat, but SetPoint cannot
    if InCombatLockdown() then
        -- Store flag to update after combat
        if not button.needsPositionUpdate then
            button.needsPositionUpdate = true
            -- Register event to update after combat if not already registered
            if not button:IsEventRegistered("PLAYER_REGEN_ENABLED") then
                button:RegisterEvent("PLAYER_REGEN_ENABLED")
                local originalOnEvent = button:GetScript("OnEvent")
                button:SetScript("OnEvent", function(buttonFrame, event, ...)
                    if event == "PLAYER_REGEN_ENABLED" and buttonFrame.needsPositionUpdate then
                        buttonFrame.needsPositionUpdate = false
                        buttonFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
                        FluxVehicleExitButton:UpdatePosition()
                    end
                    -- Call original event handler if it exists
                    if originalOnEvent then
                        originalOnEvent(buttonFrame, event, ...)
                    end
                end)
            end
        end
        return
    end
    
    -- Position button: bottom right corner at outer border's top left corner
    -- Button's BOTTOMRIGHT at outer border's TOPLEFT (with small vertical offset)
    local offset = 2 -- Small spacing above the border
    button:ClearAllPoints()
    button:SetPoint("BOTTOMRIGHT", playerFrame.outerBorderFrame, "TOPLEFT", 0, offset)
end

-- ---------------------------------------------------------------------------
-- INITIALIZATION
-- ---------------------------------------------------------------------------

local function Initialize()
    -- Create the button
    FluxVehicleExitButton:Create()
    
    -- Try to position immediately if player frame is ready
    FluxVehicleExitButton:UpdatePosition()
    
    -- Flux perf T2.5: replaced the 10Hz OnUpdate polling watcher with a small
    -- set of C_Timer.After retries. The player frame is created during
    -- PLAYER_ENTERING_WORLD / login; a handful of staggered tries covers any
    -- slow load path without a permanent ticker.
    if not ns.PlayerFrame or not ns.PlayerFrame.outerBorderFrame then
        if not button._fluxPositionRetryScheduled then
            button._fluxPositionRetryScheduled = true
            local attempts = 0
            local MAX_ATTEMPTS = 10
            local function retry()
                attempts = attempts + 1
                if ns.PlayerFrame and ns.PlayerFrame.outerBorderFrame then
                    FluxVehicleExitButton:UpdatePosition()
                    return
                end
                if attempts < MAX_ATTEMPTS and C_Timer and C_Timer.After then
                    C_Timer.After(0.5, retry)
                end
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0.25, retry)
            end
        end
    end
    
    -- Initial update
    FluxVehicleExitButton:Update()
end

-- Register startup events
local startupFrame = CreateFrame("Frame")
startupFrame:RegisterEvent("PLAYER_LOGIN")
startupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
startupFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        Initialize()
    end
end)

-- Export update position function for use by other modules
FluxVehicleExitButton.UpdatePosition = FluxVehicleExitButton.UpdatePosition


