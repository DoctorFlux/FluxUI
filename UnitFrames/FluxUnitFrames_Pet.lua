-- UnitFrames/FluxUnitFrames_Pet.lua
local addonName, ns = ...
local UF = ns.UnitFrames
local CB = ns.CastBar

-- UnitExists only. RegisterUnitWatch also shows when UnitIsVisible is true, which
-- leaves the secure button up (then faded) after a pet is gone.
local PET_VISIBILITY = "[@pet,exists] show; hide"

local function FluxUnitFrames_SuspendFluxPetUnitWatch(frame)
    if not frame or frame._fluxPetUnitWatchSuspended then
        return
    end
    if UnregisterStateDriver then
        UnregisterStateDriver(frame, "visibility")
    end
    -- Drop a leftover unit watch so it cannot show the button again.
    if UnregisterUnitWatch and UnitWatchRegistered and UnitWatchRegistered(frame) then
        UnregisterUnitWatch(frame)
    end
    frame._fluxPetUnitWatchSuspended = true
end

local function FluxUnitFrames_ResumeFluxPetUnitWatch(frame)
    if not frame or not frame._fluxPetUnitWatchSuspended or not RegisterStateDriver then
        return
    end
    RegisterStateDriver(frame, "visibility", PET_VISIBILITY)
    frame._fluxPetUnitWatchSuspended = nil
end

-- ---------------------------------------------------------------------------
-- Pet Frame Initialization
-- ---------------------------------------------------------------------------
local petFrameInitialized = false

local function InitializePetFrame()
    -- Prevent double initialization (can happen with PLAYER_LOGIN + PLAYER_ENTERING_WORLD)
    if petFrameInitialized then
        return
    end
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux("pet") then
        petFrameInitialized = true
        return
    end

    local frameWidth, frameHeight = 100, 50
    if FluxUnitFrames_GetConfiguredFrameSize then
        local w, h = FluxUnitFrames_GetConfiguredFrameSize("pet")
        if w and h then
            frameWidth, frameHeight = w, h
        end
    end

    local frame = UF.CreateBaseFrame("pet", ns.PlayerFrame or UIParent, frameWidth, frameHeight)
    
    -- Ensure it's layered ABOVE the player frame
    if ns.PlayerFrame then
        frame:SetFrameLevel(ns.PlayerFrame:GetFrameLevel() + 30)
    end

    -- Configure portrait position (can be "LEFT" or "RIGHT")
    frame.portraitPosition = "RIGHT"

    -- Configure outer border alignment ("BOTTOM" aligns bottom with atlas border, "TOP" aligns top with atlas border)
    frame.outerBorderAlignment = "BOTTOM"

    -- Configure outer border padding (how much taller the outer border is than the unit frame)
    frame.outerBorderPadding = 0

    -- Position relative to Player Frame
    -- We'll use a deferred positioning to ensure ns.PlayerFrame is ready
    local function UpdatePosition()
        if ns.PlayerFrame and not InCombatLockdown() then
            frame:ClearAllPoints()
            local ph = ns.PlayerFrame:GetHeight() or 100
            local petH = frame:GetHeight() or 50
            local inset = 8
            local innerH = math.max(10, ph - inset)
            local centerFromTop = 2 + innerH / 2
            local yOff = -centerFromTop + petH / 2
            frame:SetPoint("TOPLEFT", ns.PlayerFrame, "TOPLEFT", 0, yOff)
            
            -- Ensure parent is correct if it was created before PlayerFrame
            if frame:GetParent() ~= ns.PlayerFrame then
                frame:SetParent(ns.PlayerFrame)
                frame:SetFrameLevel(ns.PlayerFrame:GetFrameLevel() + 30)
            end
            return true
        end
        return false
    end

    -- Initial position attempt
    if not UpdatePosition() then
        -- Fallback position if player frame isn't ready
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 200, 100)
    end

    frame._fluxRefreshAnchor = UpdatePosition

    -- Periodically check for player frame to sync position
    C_Timer.After(1, UpdatePosition)
    C_Timer.After(5, UpdatePosition)

    -- Secure Show/Hide from pet existence, including summon and dismiss in combat.
    -- Do not also RegisterUnitWatch — the two drivers fight. Blizzard's PetFrame
    -- must not get this driver (Classic CompactRaidFrames taint).
    if RegisterStateDriver then
        RegisterStateDriver(frame, "visibility", PET_VISIBILITY)
    end
    frame:HookScript("OnShow", function(self)
        local function paint()
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(self)
            end
        end
        -- The exists driver Shows from secure code. Paint after that returns
        -- so mouse and chrome updates do not run inside the secure call.
        if InCombatLockdown and InCombatLockdown() and C_Timer and C_Timer.After then
            C_Timer.After(0, paint)
        else
            paint()
        end
    end)

    -- Create Bars
    -- Health Bar (Managed by Partition)
    local health = UF.CreateHealthBar(frame)

    -- Power Bar (Managed by Partition)
    local power = UF.CreatePowerBar(frame)

    -- Power Cost Overlay (darkened resource cost while casting)
    if ns.HealthLossOverlay and ns.HealthLossOverlay.Initialize then
        ns.HealthLossOverlay.Initialize(frame)
    end
    if ns.PowerCostOverlay and ns.PowerCostOverlay.Initialize then
        ns.PowerCostOverlay.Initialize(frame)
    end

    -- 3D Portrait (optional — Unit frames → Pet)
    if not FluxUnitFrames_ShouldShowPortrait or FluxUnitFrames_ShouldShowPortrait("pet") then
        UF.CreatePortrait(frame)
        if ns.API and ns.API.NeedsPortraitCompat and ns.API.NeedsPortraitCompat()
            and ns.API.SetupPortraitModel and frame.Portrait and FluxUnitFrames_ShouldUse3DPortrait() then
            ns.API.SetupPortraitModel(frame.Portrait, "pet")
        end
    end

    -- Atlas Border (covers both unit frame and portrait, layered on top)
    local atlasBorder = UF.CreateAtlasBorder(frame)

    -- Outer Border (even more outer with background backdrop)
    local outerBorder = UF.CreateOuterBorder(frame)

    -- Cast Bar (overlay on power bar). Off by default via showCastBarPet.
    if CB and CB.CreateCastBar
        and FluxUnitFrames_ShouldShowCastBar and FluxUnitFrames_ShouldShowCastBar("pet") then
        CB.CreateCastBar(frame, "pet")
    end
    
    -- Hide Blizzard Pet Frame
    if FluxUnitFrames_SuppressBlizzardUnitFrame and FluxUnitFrames_ShouldUseFlux("pet") then
        FluxUnitFrames_SuppressBlizzardUnitFrame("pet")
    elseif PetFrame then
        PetFrame:UnregisterAllEvents()
        
        if not InCombatLockdown() and PetFrame.SetAlpha then
           PetFrame:SetAlpha(0)
        end
        
        -- Don't use RegisterStateDriver or SetParent on Blizzard's PetFrame.
        -- That taints CompactRaidFrames on Classic. This Blizzard frame stays muted
        -- with alpha 0; FluxUnitFrame_pet owns the exists visibility driver.
    end
    
    -- Force initial layout
    if frame.UpdatePartition then
        frame:UpdatePartition()
    end

    -- Force initial outer border update
    if frame.UpdateOuterBorder then
        frame:UpdateOuterBorder()
    end

    -- Register for unit-specific events
    frame:RegisterEvent("UNIT_PET")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    -- Update function for pet-specific logic
    -- IMPORTANT: Only update if the unit is actually the player's pet
    local function UpdatePetData()
        -- Validate that we're dealing with the player's pet, not raid/party pets
        -- The frame.unit should always be "pet" (player's pet), but double-check
        if frame.unit ~= "pet" then
            return
        end
        
        -- Ensure pet exists before updating
        if not UnitExists("pet") then
            if UF.UpdatePortraitCombatTint then
                UF.UpdatePortraitCombatTint(frame)
            end
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(frame)
            end
            return
        end
        
        UF.UpdateHealth(frame, "pet")
        UF.UpdatePower(frame, "pet")
        UF.UpdatePortrait(frame, "pet")
        if UF.UpdatePortraitCombatTint then
            UF.UpdatePortraitCombatTint(frame)
        end
        if frame.UpdatePartition then frame:UpdatePartition() end
        if frame.UpdateOuterBorder then frame:UpdateOuterBorder() end
        if UF.SyncWatchedUnitFrameVisibility then
            UF.SyncWatchedUnitFrameVisibility(frame)
        end
    end

    -- Initial update
    UpdatePetData()

    -- Hook events
    local originalOnEvent = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function(self, event, ...)
        -- Only process events for the player's pet, never for raid/party pets
        local unit = ...
        
        if event == "UNIT_PET" then
            -- UNIT_PET fires with the owner unit (e.g., "player", "party1", "raid1")
            -- Only process if it's the player's pet
            if unit == "player" then
                -- Validate pet exists before updating
                if UnitExists("pet") then
                    UpdatePetData()
                    UpdatePosition()
                elseif UF.SyncWatchedUnitFrameVisibility then
                    UF.SyncWatchedUnitFrameVisibility(frame)
                end
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            UpdatePosition()
        end
        
        -- Call original handler if it exists
        if originalOnEvent then
            originalOnEvent(self, event, ...)
        end
        
        -- Ensure data stays fresh on relevant units
        -- CRITICAL: Only process if unit is exactly "pet" (player's pet)
        -- Do NOT process "party1pet", "raid1pet", etc. as those are handled by CompactUnitFrames
        -- The RegisterUnitEvent system should already filter this, but be extra safe
        if unit == "pet" and frame.unit == "pet" then
            UpdatePetData()
        end
    end)

    ns.PetFrame = frame
    petFrameInitialized = true
end

function FluxUnitFrames_ApplyRuntimePet(wantFlux)
    if InCombatLockdown() then
        C_Timer.After(0.5, function()
            FluxUnitFrames_ApplyRuntimePet(wantFlux)
        end)
        return
    end

    local function suppressBlizzard()
        if FluxUnitFrames_SuppressBlizzardUnitFrame then
            FluxUnitFrames_SuppressBlizzardUnitFrame("pet")
            return
        end
        local pf = _G.PetFrame
        if not pf then
            return
        end
        pf:UnregisterAllEvents()
        if not InCombatLockdown() and pf.SetAlpha then
            pf:SetAlpha(0)
        end
    end

    local function restoreBlizzard()
        local pf = _G.PetFrame
        if not pf then
            return
        end
        pcall(function()
            if _G.PetFrame_OnLoad then
                PetFrame_OnLoad(pf)
            elseif PetFrameMixin and PetFrameMixin.OnLoad then
                PetFrameMixin.OnLoad(pf)
            end
        end)
        if not InCombatLockdown() then
            if pf.SetAlpha then
                pf:SetAlpha(1)
            end
            pf:Show()
        end
        if pf.Update then
            pcall(function()
                pf:Update()
            end)
        end
    end

    if wantFlux then
        suppressBlizzard()
        if not ns.PetFrame then
            petFrameInitialized = false
            InitializePetFrame()
        else
            FluxUnitFrames_ResumeFluxPetUnitWatch(ns.PetFrame)
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(ns.PetFrame)
            end
            if ns.PetFrame.UpdatePartition then
                ns.PetFrame:UpdatePartition()
            end
        end
    else
        if ns.PetFrame then
            FluxUnitFrames_SuspendFluxPetUnitWatch(ns.PetFrame)
            ns.PetFrame:SetAlpha(1)
            ns.PetFrame:Hide()
        end
        restoreBlizzard()
    end

    if FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ApplyRuntimePetTarget then
        FluxUnitFrames_ApplyRuntimePetTarget(FluxUnitFrames_ShouldUseFlux("pettarget"))
    end

    local p = ns.PlayerFrame
    if p and UF then
        if UF.UpdateHealth then
            pcall(UF.UpdateHealth, p, "player")
        end
        if UF.UpdatePower then
            pcall(UF.UpdatePower, p, "player")
        end
        if p.UpdateOuterBorder then
            pcall(p.UpdateOuterBorder, p)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Loader (Instant Initialization)
-- ---------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- Try to initialize immediately
        if UF and UF.CreateBaseFrame then
            InitializePetFrame()
        else
            -- Use watcher pattern if UF module isn't ready yet
            if not loader._initWatcher then
                loader._initWatcher = CreateFrame("Frame")
            end
            
            local watcher = loader._initWatcher
            local checkCount = 0
            local MAX_CHECKS = 20
            
            watcher:Hide()
            watcher:SetScript("OnUpdate", function(self)
                checkCount = checkCount + 1
                if UF and UF.CreateBaseFrame then
                    self:Hide()
                    InitializePetFrame()
                elseif checkCount >= MAX_CHECKS then
                    self:Hide()
                    -- Force initialization even if UF isn't ready
                    InitializePetFrame()
                end
            end)
            watcher:Show()
        end
    end
end)

