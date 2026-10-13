--[[
    ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua
    Manages the initialization and anchoring of the Trinket Menu.
    Anchors to the RIGHT side of FluxActionStrip (CombatGrid/NC fallbacks if present).
]]

local addonName, ns = ...

FluxTrinketMenuManager = FluxTrinketMenuManager or {}
local Manager = FluxTrinketMenuManager

-- Local references
local TM = FluxTrinketMenu
local ANCHOR_OFFSET_X = 4 -- Spacing between Action Bar and Trinket Menu

local function GetActionStripBottomY()
    local y = (_G.FluxExtraButtonSystem_GetActionStripBottomOffset and _G.FluxExtraButtonSystem_GetActionStripBottomOffset())
    if type(y) ~= "number" or y ~= y then
        local Bars = ns and ns.Flux and ns.Flux.Bars
        y = Bars and Bars.CONFIG and Bars.CONFIG.yOffset or 4
    end
    return y
end

local function ActionStripFrame()
    local bar = _G.FluxActionStrip or _G.FluxMainActionBar
    if bar and bar.IsShown and bar:IsShown() then
        return bar
    end
    return nil
end

local function ActionStripSensing()
    local f = _G.FluxActionStripSensing or _G.FluxActionBarSensing
    if f and f.IsShown and f:IsShown() then
        return f
    end
    return nil
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function Initialize()
    if InCombatLockdown() then return end
    
    -- Create the Trinket Menu Grid
    if not Manager.Initialized then
        TM.CreateGrid(UIParent)
        Manager.Initialized = true
    end
    
    -- Anchor accordingly
    Manager:UpdateAnchor()
    
    TM.UpdateTrinketVisibility()
    if TM.UpdateKeybindings then
        TM.UpdateKeybindings()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if TM.UpdateKeybindings then
                TM.UpdateKeybindings()
            end
        end)
        C_Timer.After(2, function()
            if TM.UpdateKeybindings then
                TM.UpdateKeybindings()
            end
        end)
    end
    if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
        FluxUnifiedBorder.UpdateBorder()
    end
end

-- ============================================================================
-- ANCHORING LOGIC
-- ============================================================================

function Manager:UpdateAnchor()
    if InCombatLockdown() or not TM.Frame then return end
    
    local anchorFrame = TM.ScaleHost or TM.Frame
    anchorFrame:ClearAllPoints()

    local strip = ActionStripFrame()
    if strip then
        -- Anchor Grid's BOTTOMLEFT to ActionBar's BOTTOMRIGHT
        -- Moved 4px to the left: ANCHOR_OFFSET_X - 2 - 4 = -2
        anchorFrame:SetPoint("BOTTOMLEFT", strip, "BOTTOMRIGHT", ANCHOR_OFFSET_X - 6, 0)

    -- Fallback: sensing envelope
    elseif ActionStripSensing() then
        -- Moved 4px to the left
        anchorFrame:SetPoint("BOTTOMLEFT", ActionStripSensing(), "BOTTOMRIGHT", ANCHOR_OFFSET_X - 4, 50)
    
    -- Strip hidden: non-combat, then combat, then trinkets, left to right.
    elseif FluxCombatManager and FluxCombatManager.Grid and FluxCombatManager.Grid.Frame and FluxCombatManager.Grid.Frame:IsShown() then
        local combatGridFrame = FluxCombatManager.Grid.Frame
        anchorFrame:SetPoint("BOTTOMLEFT", combatGridFrame, "BOTTOMRIGHT", 8, 0)
    
    -- 3. Right of NonCombatGrid when visible
    elseif FluxNonCombatAPI and FluxNonCombatAPI.DefaultGrid and FluxNonCombatAPI.DefaultGrid.Frame and FluxNonCombatAPI.DefaultGrid.Frame:IsShown() then
        local ncFrame = FluxNonCombatAPI.DefaultGrid.Frame
        anchorFrame:SetPoint("BOTTOMLEFT", ncFrame, "BOTTOMRIGHT", 8, 0)
    
    -- Fallback: Attach to FluxWindowFrame's left bottom corner
    elseif FluxWindowFrame and FluxWindowFrame.GetFrame then
        local windowFrame = FluxWindowFrame:GetFrame()
        if windowFrame and windowFrame.GetPoint then
            -- Anchor TrinketMenu's BOTTOMRIGHT to FluxWindowFrame's BOTTOMLEFT
            -- This places TrinketMenu to the LEFT of the window frame
            anchorFrame:SetPoint("BOTTOMRIGHT", windowFrame, "BOTTOMLEFT", -4, 0)
        end
    
    else
        -- Ultimate Fallback: Bottom right of screen on the shared action-strip baseline.
        anchorFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 200, GetActionStripBottomY())
    end

    if TM.ApplyHorizontalSqueeze then
        TM.ApplyHorizontalSqueeze()
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local eventFrame = CreateFrame("Frame")
local bagUpdateTimer = nil
local equipDebounceTimer = nil
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")

-- Pet battle events (Retail only)
if C_PetBattles then
    eventFrame:RegisterEvent("PET_BATTLE_OPENING_START")
    eventFrame:RegisterEvent("PET_BATTLE_CLOSE")
end

-- Event-based watcher for instant initialization
local watcherFrame = CreateFrame("Frame")
local checkCount = 0
local MAX_CHECKS = 30 -- Safety limit: ~0.5 seconds at 60fps
local initialized = false

local function TryInitialize(force)
    if InCombatLockdown() then return false end
    if initialized then 
        -- Already initialized - check if we need to re-anchor to FluxActionBar
        if TM.Frame and (_G["FluxMainActionBar"] and _G["FluxMainActionBar"]:IsShown() or 
                         _G["FluxActionBarSensing"] and _G["FluxActionBarSensing"]:IsShown()) then
            -- Re-anchor to action bar if it's now available (higher priority than window frame)
            Manager:UpdateAnchor()
        end
        return true 
    end
    
    -- Check if any valid anchor is available (instant initialization)
    -- Priority: FluxActionBar > FluxWindowFrame
    local hasAnchor = false
    if _G["FluxMainActionBar"] and _G["FluxMainActionBar"]:IsShown() then
        hasAnchor = true
    elseif _G["FluxActionBarSensing"] and _G["FluxActionBarSensing"]:IsShown() then
        hasAnchor = true
    elseif FluxWindowFrame and FluxWindowFrame.GetFrame then
        local windowFrame = FluxWindowFrame:GetFrame()
        if windowFrame and windowFrame.GetPoint then
            hasAnchor = true
        end
    end
    
    -- If forcing or any anchor exists, initialize immediately
    if force or hasAnchor then
        Initialize()
        initialized = true
        watcherFrame:SetScript("OnUpdate", nil) -- Stop watching
        return true
    end
    
    return false
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        local isInitialLogin = (event == "PLAYER_LOGIN")
            or (event == "PLAYER_ENTERING_WORLD" and arg1 == true)
        -- Try immediately first (will initialize if any anchor exists)
        if TryInitialize(false) then
            -- If initialized but not with FluxActionBar, continue watching for it
            if initialized and not (_G["FluxMainActionBar"] and _G["FluxMainActionBar"]:IsShown() or 
                                    _G["FluxActionBarSensing"] and _G["FluxActionBarSensing"]:IsShown()) then
                -- Continue watching for FluxActionBar to appear (higher priority)
                checkCount = 0
                watcherFrame:SetScript("OnUpdate", function(self, elapsed)
                    checkCount = checkCount + 1
                    -- Check if FluxActionBar is now available and re-anchor
                    if (_G["FluxMainActionBar"] and _G["FluxMainActionBar"]:IsShown() or 
                        _G["FluxActionBarSensing"] and _G["FluxActionBarSensing"]:IsShown()) then
                        if TM.Frame then
                            Manager:UpdateAnchor() -- This will automatically prioritize FluxActionBar
                        end
                        self:SetScript("OnUpdate", nil) -- Stop watching once anchored to action bar
                    elseif checkCount >= MAX_CHECKS * 2 then
                        -- Stop watching after extended checks (give it more time)
                        self:SetScript("OnUpdate", nil)
                    end
                end)
            end
            if not isInitialLogin and initialized then
                TM.UpdateTrinketVisibility()
                if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
                    FluxUnifiedBorder.UpdateBorder()
                end
            end
            return
        end
        
        -- If not initialized, watch every frame until any anchor is available
        -- After MAX_CHECKS, initialize anyway with fallback anchors
        checkCount = 0
        watcherFrame:SetScript("OnUpdate", function(self, elapsed)
            checkCount = checkCount + 1
            if TryInitialize(false) or checkCount >= MAX_CHECKS then
                -- If we hit the limit, force initialization with fallback anchors
                if checkCount >= MAX_CHECKS and not initialized then
                    TryInitialize(true)
                end
                -- If initialized but not with FluxActionBar, continue watching for it
                if initialized and not (_G["FluxMainActionBar"] and _G["FluxMainActionBar"]:IsShown() or 
                                        _G["FluxActionBarSensing"] and _G["FluxActionBarSensing"]:IsShown()) then
                    -- Continue watching for FluxActionBar (reset counter and keep watching)
                    checkCount = 0
                    return
                end
                self:SetScript("OnUpdate", nil)
            end
        end)

        if not isInitialLogin and initialized then
            TM.UpdateTrinketVisibility()
            if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
                FluxUnifiedBorder.UpdateBorder()
            end
        end
        
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if equipDebounceTimer then
            equipDebounceTimer:Cancel()
        end
        equipDebounceTimer = C_Timer.NewTimer(0.15, function()
            equipDebounceTimer = nil
            TM.UpdateTrinketVisibility()
            if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
                FluxUnifiedBorder.UpdateBorder()
            end
        end)
        
    elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
        TM.UpdateAllCooldowns()

    elseif event == "SPELL_UPDATE_USABLE" or event == "ACTIONBAR_UPDATE_STATE" then
        if TM.UpdateAllUsability then
            TM.UpdateAllUsability()
        end
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        TM.ProcessCombatQueue()

        if TM._pendingVisibilityUpdate then
            TM._pendingVisibilityUpdate = nil
            TM.UpdateTrinketVisibility()
            if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
                FluxUnifiedBorder.UpdateBorder()
            end
        end
        if TM._pendingKeybindUpdate then
            TM._pendingKeybindUpdate = nil
            TM.UpdateKeybindings()
        end
        if TM._pendingShow then
            TM._pendingShow = nil
            TM.UpdateTrinketVisibility()
            if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
                FluxUnifiedBorder.UpdateBorder()
            end
        end
        
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Custom flyout can stay open; kid clicks queue swaps while locked.

    elseif event == "UPDATE_BINDINGS" then
        if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            return
        end
        if eventFrame._bindRefreshPending then
            return
        end
        eventFrame._bindRefreshPending = true
        C_Timer.After(0.15, function()
            eventFrame._bindRefreshPending = false
            if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
                and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
                return
            end
            TM.UpdateKeybindings()
        end)

    elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        if TM.Frame and not InCombatLockdown() then
            Manager:UpdateAnchor()
        end
        
    elseif event == "PET_BATTLE_OPENING_START" then
        -- Hide during pet battles
        if TM.Frame and TM.Frame:IsShown() then
            TM.Frame:Hide()
            TM.Frame.WasShownBeforePetBattle = true
        end
        
    elseif event == "PET_BATTLE_CLOSE" then
        if TM.Frame and TM.Frame.WasShownBeforePetBattle then
            TM.UpdateTrinketVisibility()
            if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
                FluxUnifiedBorder.UpdateBorder()
            end
            TM.Frame.WasShownBeforePetBattle = nil
        end
    end
end)

-- Bag/equip awareness via FluxInv (no FluxBagChangeDispatcher / FluxInventory).
do
    local function OnInvPulse(ctx)
        if ctx and ctx.regions then
            if not ctx.regions.bags and not ctx.regions.equipped then
                return
            end
        end
        if equipDebounceTimer then
            return
        end
        if bagUpdateTimer then
            bagUpdateTimer:Cancel()
        end
        bagUpdateTimer = C_Timer.NewTimer(0.2, function()
            bagUpdateTimer = nil
            if TM.ScanBagsForTrinkets then
                TM.ScanBagsForTrinkets()
            end
            TM.UpdateTrinketVisibility()
            if TM.SyncFlyoutEngine then
                TM.SyncFlyoutEngine()
            end
            if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
                FluxUnifiedBorder.UpdateBorder()
            end
        end)
    end

    local function TryRegisterInventory()
        local Flux = ns and ns.Flux
        local Inv = Flux and Flux.Inventory
        if Inv and Inv.Register then
            Inv.Register("TrinketMenu", OnInvPulse, {
                tier = "scan",
                regions = { "bags", "equip" },
                deferHeavy = true,
            })
            return true
        end
        local inv = _G.FluxInv
        if inv and inv.RegisterListener then
            inv.RegisterListener("TrinketMenu", OnInvPulse, {
                tier = "scan",
                regions = { "bags", "equip" },
                deferHeavy = true,
            })
            return true
        end
        return false
    end

    if not TryRegisterInventory() then
        local boot = CreateFrame("Frame")
        boot:RegisterEvent("PLAYER_LOGIN")
        boot:SetScript("OnEvent", function(self)
            if TryRegisterInventory() then
                self:UnregisterAllEvents()
            end
        end)
    end
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

SLASH_FLUXTRINKETMENU1 = "/fluxtrinket"
SLASH_FLUXTRINKETMENU2 = "/ftm"
SlashCmdList["FLUXTRINKETMENU"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "" or msg == "toggle" then
        TM.ScanBagsForTrinkets()
        if TM.GetTrinketVisibilityState() == "none" then
            print("|cff00ffff[FluxTrinketMenu]|r No trinkets to show.")
        else
            TM.Toggle()
        end
    elseif msg == "show" then
        TM.ScanBagsForTrinkets()
        if TM.GetTrinketVisibilityState() == "none" then
            print("|cff00ffff[FluxTrinketMenu]|r No trinkets to show.")
        else
            TM.Show()
        end
    elseif msg == "hide" then
        TM.Hide()
    elseif msg == "reset" then
        if TM.Frame then
            Manager:UpdateAnchor()
            print("|cff00ffff[FluxTrinketMenu]|r Position reset.")
        end
    else
        print("|cff00ffff[FluxTrinketMenu]|r Commands:")
        print("  /fluxtrinket - Toggle visibility")
        print("  /fluxtrinket show - Show trinket menu")
        print("  /fluxtrinket hide - Hide trinket menu")
        print("  /fluxtrinket reset - Reset position")
    end
end

-- ============================================================================
-- API EXPORTS
-- ============================================================================

function Manager:GetFrame()
    return TM.Frame
end

function Manager:GetButtons()
    return TM.Buttons
end

function Manager:Refresh()
    TM.UpdateTrinketVisibility()
    if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
        FluxUnifiedBorder.UpdateBorder()
    end
end

_G.FluxTrinketMenuManager = Manager

function Manager.UpdateKeybindings()
    local TM = FluxTrinketMenu
    if TM and TM.UpdateKeybindings then
        TM.UpdateKeybindings()
    end
end

