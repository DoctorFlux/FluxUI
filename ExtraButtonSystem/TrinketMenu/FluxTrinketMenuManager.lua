--[[
    ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua
    Manages the initialization and anchoring of the Trinket Menu.
    Anchors to the RIGHT side of FluxActionStrip (CombatGrid/NC fallbacks if present).
]]

local addonName, ns = ...

FluxTrinketMenuManager = FluxTrinketMenuManager or {}
local Manager = FluxTrinketMenuManager
local Flux = (ns and ns.Flux) or _G.Flux
local managedStartup = Flux and Flux.Module and Flux.Module.Register

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
    if InCombatLockdown() or (managedStartup and not Flux.securePhaseReady) then return false end
    if Manager._startupReady then return true end
    if not TM or not TM.CreateGrid then return false end

    if not Manager.Initialized then
        TM.CreateGrid(UIParent)
        if not TM.Frame then return false end
    end
    Manager:UpdateAnchor()
    -- Equipped-slot input is ready without waiting on a full bag classification.
    -- Deferred initialization and inventory pulses populate the flyout afterward.
    TM.UpdateTrinketVisibility(true)
    if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
        FluxUnifiedBorder.UpdateBorder()
    end
    Manager.Initialized = true
    Manager._startupReady = true
    if Flux and Flux.Startup then Flux.Startup.Mark("trinkets_ready") end
    return true
end

-- ============================================================================
-- ANCHORING LOGIC
-- ============================================================================

function Manager:UpdateAnchor()
    if InCombatLockdown() then
        Manager._pendingAnchor = true
        return
    end
    if not TM.Frame then return end
    Manager._pendingAnchor = nil
    
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

-- The startup pipeline creates secure input even with only the screen fallback
-- anchor available. Layout notifications re-anchor it when the action strip moves.
local function TryInitialize()
    return Initialize()
end

if managedStartup then
    Flux.Module.Register("TrinketMenu", {
        phase = "secure", priority = 47, protected = true, OnEnable = Initialize,
    })
    Flux.Module.Register("TrinketInventory", {
        phase = "deferred", priority = 60, protected = true,
        OnEnable = function()
            if not Manager._startupReady then return false end
            TM.UpdateTrinketVisibility()
            return true
        end,
    })
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        if not Manager._startupReady then
            TryInitialize()
        else
            Manager:UpdateAnchor()
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
        if not Manager._startupReady then
            if not TryInitialize() then return end
        end
        if Manager._pendingAnchor then Manager:UpdateAnchor() end
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
        Manager:UpdateAnchor()
        
    elseif event == "PET_BATTLE_OPENING_START" then
        -- Hide during pet battles
        if TM.Frame and TM.Frame:IsShown() and not InCombatLockdown() then
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

