-- UnitFrames/FluxUnitFrames_Player.lua
local addonName, ns = ...
local UF = ns.UnitFrames
local CB = ns.CastBar
local ST = ns.SwingTimer

-- ---------------------------------------------------------------------------
-- Player Frame Initialization
-- ---------------------------------------------------------------------------
local playerFrameInitialized = false

local function InitializePlayerFrame()
    -- Prevent double initialization (can happen with PLAYER_LOGIN + PLAYER_ENTERING_WORLD)
    if playerFrameInitialized then
        return
    end
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux("player") then
        playerFrameInitialized = true
        return
    end

    local frameWidth, frameHeight = 325, 100
    if FluxUnitFrames_GetConfiguredFrameSize then
        local w, h = FluxUnitFrames_GetConfiguredFrameSize("player")
        if w and h then
            frameWidth, frameHeight = w, h
        end
    end

    local frame = UF.CreateBaseFrame("player", UIParent, frameWidth, frameHeight)

    -- Configure portrait position (can be "LEFT" or "RIGHT")
    frame.portraitPosition = "LEFT"

    -- Configure outer border alignment ("BOTTOM" aligns bottom with atlas border, "TOP" aligns top with atlas border)
    frame.outerBorderAlignment = "BOTTOM"

    -- Configure outer border padding (how much taller the outer border is than the unit frame)
    frame.outerBorderPadding = 36

    -- Configure right-click menu (true by default, can be set to false to disable)
    -- frame.outerBorderFrame:SetRightClickMenu(false) -- Uncomment to disable right-click menu for this frame

    -- Center on screen: offset when a side portrait exists so bars+portrait block stays centered; 0 when portrait off.
    local centerOffset = 0
    if FluxUnitFrames_GetScreenAnchorCenterOffsetX then
        centerOffset = FluxUnitFrames_GetScreenAnchorCenterOffsetX("player", frame.portraitPosition, frameWidth, frameHeight)
    else
        local portraitSize = frameHeight
        local portraitOffset = 2
        centerOffset = (portraitSize + portraitOffset) / 2
    end

    -- Position: Bottom Center (adjusted for portrait); clears horizontal status bar strip when layout position 2.
    local py = (_G.FluxUnitFrames_GetPlayerScreenBottomOffset and _G.FluxUnitFrames_GetPlayerScreenBottomOffset()) or 96
    if frame.portraitPosition == "LEFT" then
        frame:SetPoint("BOTTOM", UIParent, "BOTTOM", centerOffset, py)
    else -- RIGHT
        frame:SetPoint("BOTTOM", UIParent, "BOTTOM", -centerOffset, py)
    end
    
    -- Create Bars
    -- Health Bar (Managed by Partition)
    local health = UF.CreateHealthBar(frame)

    -- Power Bar (Managed by Partition)
    local power = UF.CreatePowerBar(frame)

    -- Additional Power Bar (Managed by Partition)
    local additionalPower = UF.CreateAdditionalPowerBar(frame)

    -- Health loss strip (red BACKGROUND shrink) + power cost overlay
    if ns.HealthLossOverlay and ns.HealthLossOverlay.Initialize then
        ns.HealthLossOverlay.Initialize(frame)
    end
    if ns.PowerCostOverlay and ns.PowerCostOverlay.Initialize then
        ns.PowerCostOverlay.Initialize(frame)
    end

    -- MP5 Rule / Mana Tick overlay (vanilla/TBC only)
    if ns.MP5Overlay and ns.MP5Overlay.Initialize then
        ns.MP5Overlay.Initialize(frame)
    end

    -- 3D Portrait (optional — Unit frames → Player)
    if not FluxUnitFrames_ShouldShowPortrait or FluxUnitFrames_ShouldShowPortrait("player") then
        UF.CreatePortrait(frame)
        if UF.CreatePortraitCombatFeedback then
            UF.CreatePortraitCombatFeedback(frame)
        end
        if ns.API and ns.API.NeedsPortraitCompat and ns.API.NeedsPortraitCompat()
            and ns.API.SetupPortraitModel and frame.Portrait and FluxUnitFrames_ShouldUse3DPortrait() then
            ns.API.SetupPortraitModel(frame.Portrait, "player")
        end
    end

    -- Atlas Border (covers both unit frame and portrait, layered on top)
    local atlasBorder = UF.CreateAtlasBorder(frame)

    -- Outer Border (even more outer with background backdrop)
    local outerBorder = UF.CreateOuterBorder(frame)

    -- Cast Bar (Positioned above the frame, scales with frame width)
    if CB and CB.CreateCastBar then
        CB.CreateCastBar(frame, "player")
    end

    -- Weapon Swing Timer (overlays the cast bar when idle)
    if ST and ST.SetPlayerSwingTimerEnabled then
        ST.SetPlayerSwingTimerEnabled(not FluxUnitFrames_IsFeatureEnabled or FluxUnitFrames_IsFeatureEnabled("swingTimer"))
    elseif ST and ST.AttachToCastBar and frame.CastBar then
        ST.AttachToCastBar(frame.CastBar, "player")
    end
    
    -- Hide Blizzard artwork while keeping its native player/vehicle updates.
    if FluxUnitFrames_SuppressBlizzardUnitFrame and FluxUnitFrames_ShouldUseFlux("player") then
        FluxUnitFrames_SuppressBlizzardUnitFrame("player")
    elseif PlayerFrame then
        -- Keep Blizzard's player/vehicle unit and aura updates in native code.
        if not InCombatLockdown() and PlayerFrame.SetAlpha then
            PlayerFrame:SetAlpha(0)
        end
        
        -- Do NOT call SetParent(hidden) or Hide() — PlayerFrame is an Edit Mode
        -- system; those taint UpdateLayoutInfo → SetClampRectInsets on spec/level.
    end
    
    -- Force initial layout
    if frame.UpdatePartition then
        frame:UpdatePartition()
    end

    -- Force initial group text update
    if frame.UpdateGroupText then
        frame:UpdateGroupText()
    end

    -- Force initial raid icon update (oUF style)
    local index = GetRaidTargetIndex("player")
    if frame.raidIcon then
        if index then
            SetRaidTargetIconTexture(frame.raidIcon, index)
            frame.raidIcon:Show()
        else
            frame.raidIcon:Hide()
        end
    end

    -- Force initial PvP icon update
    if frame.UpdateOuterBorder then
        frame:UpdateOuterBorder()
    end

    -- Initialize Class Power (Blizzard Native)
    if ns.ClassPower and ns.ClassPower.Initialize then
        ns.ClassPower.Initialize(frame)
    end
    
    -- Update power bar positions after outer border is set up
    -- This ensures they're positioned correctly at the top center of the outer border
    C_Timer.After(0.1, function()
        if ns.ClassPower and ns.ClassPower.UpdatePosition then
            pcall(ns.ClassPower.UpdatePosition, frame)
        end
    end)

    -- Initialize Stance Bar
    if ns.StanceBar and ns.StanceBar.Initialize then
        ns.StanceBar.Initialize(frame)
    end

    ns.PlayerFrame = frame

    -- Respec build-matched spec icon override (FluxRespec loads after UnitFrames; refresh once player strip exists).
    if _G.C_Timer and _G.C_Timer.After then
        C_Timer.After(0, function()
            if _G.FluxUnitFrames_RefreshPlayerSpecIcon then
                pcall(_G.FluxUnitFrames_RefreshPlayerSpecIcon)
            end
        end)
    elseif _G.FluxUnitFrames_RefreshPlayerSpecIcon then
        pcall(_G.FluxUnitFrames_RefreshPlayerSpecIcon)
    end

    if ns.PlayerSpecClick and ns.PlayerSpecClick.Initialize then
        ns.PlayerSpecClick.Initialize(frame)
    end
    if ns.PlayerTransmogClick and ns.PlayerTransmogClick.Initialize then
        ns.PlayerTransmogClick.Initialize(frame)
    end
    playerFrameInitialized = true
end

-- ---------------------------------------------------------------------------
-- Earliest legal secure phase; Core retries after combat when necessary.
-- ---------------------------------------------------------------------------
UF.RegisterInitializer("player", InitializePlayerFrame, function() return playerFrameInitialized end, 60)

-- ---------------------------------------------------------------------------
-- Live Flux vs Blizzard (no reload): options / profile refresh
-- ---------------------------------------------------------------------------
function FluxUnitFrames_ApplyRuntimePlayer(wantFlux)
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(function() FluxUnitFrames_ApplyRuntimePlayer(wantFlux) end,
            "unitframes.runtime.player")
        return
    end
    if InCombatLockdown() then
        UF.DeferProtected("runtime.player", function()
            FluxUnitFrames_ApplyRuntimePlayer(wantFlux)
        end)
        return
    end

    local function suppressBlizzard()
        if FluxUnitFrames_SuppressBlizzardUnitFrame then
            FluxUnitFrames_SuppressBlizzardUnitFrame("player")
            return
        end
        if PlayerFrame then
            if not InCombatLockdown() and PlayerFrame.SetAlpha then
                PlayerFrame:SetAlpha(0)
            end
        end
    end

    local function restoreBlizzard()
        local pf = PlayerFrame
        if not pf then
            return
        end
        -- Restore suspended overlay events without calling OnLoad, which would
        -- rewrite PlayerFrame.unit and the native handler state under Flux.
        if FluxUnitFrames_SetBlizzardPlayerPredictionMuted then
            FluxUnitFrames_SetBlizzardPlayerPredictionMuted(false)
        end
        if not InCombatLockdown() then
            if pf.SetAlpha then
                pf:SetAlpha(1)
            end
        end
    end

    if wantFlux then
        suppressBlizzard()
        if not ns.PlayerFrame then
            playerFrameInitialized = false
            UF.RunInitializer("player")
        else
            ns.PlayerFrame:Show()
            if ns.PlayerFrame.UpdatePartition then
                ns.PlayerFrame:UpdatePartition()
            end
        end
        if C_Timer and C_Timer.After and _G.FluxUnitFrames_RefreshStanceAndPetBarLayout then
            C_Timer.After(0, _G.FluxUnitFrames_RefreshStanceAndPetBarLayout)
        end
        return
    end

    if ns.PlayerFrame then
        ns.PlayerFrame:Hide()
    end
    restoreBlizzard()
    if C_Timer and C_Timer.After and _G.FluxUnitFrames_RefreshStanceAndPetBarLayout then
        C_Timer.After(0, _G.FluxUnitFrames_RefreshStanceAndPetBarLayout)
    end
end
