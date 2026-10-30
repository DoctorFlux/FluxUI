-- UnitFrames/FluxUnitFrames_Target.lua
local addonName, ns = ...
local UF = ns.UnitFrames
local CB = ns.CastBar

-- Re-register Blizzard TargetFrame events after UnregisterAllEvents — do NOT call full TargetFrameMixin:OnLoad
-- again (it recreates auraPools and breaks the default UI).
local function FluxUnitFrames_ReregisterBlizzardTargetEvents(tf)
    if not tf then
        return
    end
    local unit = "target"
    tf:RegisterEvent("PLAYER_ENTERING_WORLD")
    tf:RegisterEvent("UNIT_HEALTH")
    if tf.showLevel then
        tf:RegisterEvent("UNIT_LEVEL")
    end
    tf:RegisterEvent("UNIT_FACTION")
    if tf.showClassification then
        tf:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
    end
    if tf.showLeader then
        tf:RegisterEvent("PLAYER_FLAGS_CHANGED")
    end
    tf:RegisterEvent("GROUP_ROSTER_UPDATE")
    tf:RegisterEvent("RAID_TARGET_UPDATE")
    -- Required for TargetFrame:Update / auras / sounds on retarget (registered in TargetFrame.xml after mixin OnLoad).
    tf:RegisterEvent("PLAYER_TARGET_CHANGED")
    tf:RegisterUnitEvent("UNIT_AURA", unit)
    tf:RegisterUnitEvent("UNIT_TARGET", unit)
    -- Normal target frame handles this in TargetFrameMixin:OnEvent (boss frames register in BossTargetFrameMixin).
    pcall(function()
        tf:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", unit)
    end)
    pcall(function()
        if SecureUnitButton_OnLoad and TargetFrame_OpenMenu then
            SecureUnitButton_OnLoad(tf, unit, TargetFrame_OpenMenu)
        end
    end)
end

local function FluxUnitFrames_SuspendFluxTargetPlaceholder(frame)
    if not frame then
        return
    end
    if frame.placeholderBorder then
        frame.placeholderBorder:Hide()
    end
    local ef = frame._fluxPlaceholderEventFrame
    if ef then
        ef:UnregisterAllEvents()
        ef:SetScript("OnEvent", nil)
    end
end

local function FluxUnitFrames_ResumeFluxTargetPlaceholder(frame)
    if not frame or not frame._fluxPlaceholderEventFrame then
        return
    end
    local ef = frame._fluxPlaceholderEventFrame
    ef:RegisterEvent("PLAYER_TARGET_CHANGED")
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:SetScript("OnEvent", function()
        if frame.UpdateFluxTargetPlaceholderVisibility then
            frame:UpdateFluxTargetPlaceholderVisibility()
        end
    end)
    if frame.UpdateFluxTargetPlaceholderVisibility then
        frame:UpdateFluxTargetPlaceholderVisibility()
    end
end

local function FluxUnitFrames_SuspendFluxTargetUnitWatch(frame)
    if not frame or frame._fluxUnitWatchSuspended or not UnregisterUnitWatch then
        return
    end
    UnregisterUnitWatch(frame)
    frame._fluxUnitWatchSuspended = true
end

local function FluxUnitFrames_ResumeFluxTargetUnitWatch(frame)
    if not frame or not frame._fluxUnitWatchSuspended or not RegisterUnitWatch then
        return
    end
    RegisterUnitWatch(frame)
    frame._fluxUnitWatchSuspended = nil
end

-- ---------------------------------------------------------------------------
-- Target Frame Initialization
-- ---------------------------------------------------------------------------
local targetFrameInitialized = false

local function InitializeTargetFrame()
    if targetFrameInitialized then
        return
    end
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux("target") then
        targetFrameInitialized = true
        return
    end

    local frameWidth, frameHeight = 500, 100
    if FluxUnitFrames_GetConfiguredFrameSize then
        local w, h = FluxUnitFrames_GetConfiguredFrameSize("target")
        if w and h then
            frameWidth, frameHeight = w, h
        end
    end

    local frame = UF.CreateBaseFrame("target", UIParent, frameWidth, frameHeight)

    -- Configure portrait position (can be "LEFT" or "RIGHT")
    frame.portraitPosition = "RIGHT"

    -- Configure outer border alignment ("BOTTOM" aligns bottom with atlas border, "TOP" aligns top with atlas border)
    frame.outerBorderAlignment = "TOP"

    -- Configure outer border padding (how much taller the outer border is than the unit frame)
    frame.outerBorderPadding = 36

    -- Configure right-click menu (true by default, can be set to false to disable)
    -- frame.outerBorderFrame:SetRightClickMenu(false) -- Uncomment to disable right-click menu for this frame

    local centerOffset = 0
    if FluxUnitFrames_GetScreenAnchorCenterOffsetX then
        centerOffset = FluxUnitFrames_GetScreenAnchorCenterOffsetX("target", frame.portraitPosition, frameWidth, frameHeight)
    else
        local portraitSize = frameHeight
        local portraitOffset = 2
        centerOffset = (portraitSize + portraitOffset) / 2
    end

    -- Position: Top Center (adjusted for portrait) - at the very top
    if frame.portraitPosition == "LEFT" then
        frame:SetPoint("TOP", UIParent, "TOP", centerOffset, 2)
    else -- RIGHT
        frame:SetPoint("TOP", UIParent, "TOP", -centerOffset, 2)
    end

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

    -- Additional Power Bar (Managed by Partition) - Disabled for target frame
    -- local additionalPower = UF.CreateAdditionalPowerBar(frame)

    if not FluxUnitFrames_ShouldShowPortrait or FluxUnitFrames_ShouldShowPortrait("target") then
        UF.CreatePortrait(frame)
        if UF.CreatePortraitCombatFeedback then
            UF.CreatePortraitCombatFeedback(frame)
        end
        if ns.API and ns.API.NeedsPortraitCompat and ns.API.NeedsPortraitCompat()
            and ns.API.SetupPortraitModel and frame.Portrait and FluxUnitFrames_ShouldUse3DPortrait() then
            ns.API.SetupPortraitModel(frame.Portrait, "target")
        end
    end

    -- Threat Bar (portrait overlay or strip between frame and auras)
    if UF.CreateThreatBar then
        UF.CreateThreatBar(frame)
    end

    -- Atlas Border (covers both unit frame and portrait, layered on top)
    local atlasBorder = UF.CreateAtlasBorder(frame)

    -- Outer Border (even more outer with background backdrop)
    local outerBorder = UF.CreateOuterBorder(frame)

    -- Threat strip (between mode) needs outer chrome before aura panels pin to it.
    if UF.LayoutThreatBar and frame.ThreatBar then
        UF.LayoutThreatBar(frame)
    end

    -- Enable auras for target frame — layout from Unit frames options (auraTarget)
    if UF.ApplyAuraOptionsToFrame and FluxUnitFrames_GetAuraConfigTables then
        local b, d = FluxUnitFrames_GetAuraConfigTables("target")
        UF.ApplyAuraOptionsToFrame(frame, true, true, b, d)
    else
        UF.EnableAuras(frame, true)
    end

    -- Placeholder Border (shows when no target, transparent with no color tint)
    local placeholderBorder = CreateFrame("Frame", nil, UIParent)
    placeholderBorder:SetFrameStrata("BACKGROUND")
    placeholderBorder:SetFrameLevel(1) -- Below main frame but above world
    placeholderBorder:SetAllPoints(outerBorder)
    frame.placeholderBorder = placeholderBorder

    -- Apply transparent border with same sizing as outer border
    if ns.Border then
        ns.Border:ApplyTo(placeholderBorder, 2, 2, 2, 2) -- Same padding as outer border
        -- Make it transparent with no color tint
        ns.Border:SetBorderColor(placeholderBorder, 0.5, 0.5, 0.5, 0.7) -- Very subtle gray
        ns.Border:SetBackdropColor(placeholderBorder, 0.5, 0.5, 0.5, 0.25) -- Very transparent black backdrop

        -- Adjust backdrop positioning based on outer border alignment (same as main frame)
        if placeholderBorder.FluxBorderFrame and placeholderBorder.FluxBorderFrame.BackgroundFrame then
            local alignment = frame.outerBorderAlignment or "BOTTOM"
            if alignment == "TOP" then
                -- Extend backdrop to bottom edge
                placeholderBorder.FluxBorderFrame.BackgroundFrame:SetPoint("BOTTOMRIGHT", placeholderBorder, "BOTTOMRIGHT", -2, 0)
            elseif alignment == "BOTTOM" then
                -- Extend backdrop to top edge
                placeholderBorder.FluxBorderFrame.BackgroundFrame:SetPoint("TOPLEFT", placeholderBorder, "TOPLEFT", 2, 0)
            end
        end
    end

    -- Cast Bar (Positioned below the frame, scales with frame width)
    if CB and CB.CreateCastBar then
        CB.CreateCastBar(frame, "target")
    end

    -- Hide Blizzard Target Frame (Conservative Approach for Classic Taint)
    if FluxUnitFrames_SuppressBlizzardUnitFrame and FluxUnitFrames_ShouldUseFlux("target") then
        FluxUnitFrames_SuppressBlizzardUnitFrame("target")
    elseif TargetFrame then
        TargetFrame:UnregisterAllEvents()
        
        -- Do not Hide() — TargetFrame is an Edit Mode system (SetClampRectInsets taint).
        if not InCombatLockdown() and TargetFrame.SetAlpha then
           TargetFrame:SetAlpha(0)
        end
        
        -- Do NOT call SetParent(hidden) on Classic/Pre-DF as it causes heavy taint
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
    local index = GetRaidTargetIndex("target")
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

    -- Initial visibility check
    if UF.SyncWatchedUnitFrameVisibility then
        UF.SyncWatchedUnitFrameVisibility(frame)
    elseif not (UnitExists("target") or UnitIsVisible("target")) then
        frame:Hide()
    end

    ns.TargetFrame = frame
    if FluxUnitFrames_ReanchorUnitFrameScreenPosition then
        FluxUnitFrames_ReanchorUnitFrameScreenPosition(frame, "target")
    end

    -- Placeholder Border Visibility Management (also used when re-enabling Flux target at runtime)
    function frame:UpdateFluxTargetPlaceholderVisibility()
        if UF.SyncTargetPlaceholderVisibility then
            UF.SyncTargetPlaceholderVisibility(self)
            return
        end
        if not self.placeholderBorder then
            return
        end
        if FluxUnitFrames_ShouldShowTargetNoTargetPlaceholder and not FluxUnitFrames_ShouldShowTargetNoTargetPlaceholder() then
            self.placeholderBorder:Hide()
            return
        end
        local hasTarget
        if UF.UnitTokenIsResolved then
            hasTarget = UF.UnitTokenIsResolved("target")
        else
            hasTarget = UnitExists("target") or UnitIsVisible("target")
        end
        if not hasTarget then
            self.placeholderBorder:Show()
        else
            self.placeholderBorder:Hide()
        end
    end

    local eventFrame = CreateFrame("Frame")
    frame._fluxPlaceholderEventFrame = eventFrame
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", function()
        frame:UpdateFluxTargetPlaceholderVisibility()
    end)

    frame:UpdateFluxTargetPlaceholderVisibility()

    if FluxUnitFrames_ReanchorUnitFrameScreenPosition and C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if InCombatLockdown() then
                return
            end
            if ns.TargetFrame then
                FluxUnitFrames_ReanchorUnitFrameScreenPosition(ns.TargetFrame, "target")
            end
        end)
    end

    targetFrameInitialized = true
end

--- Refresh Blizzard target + ToT and Flux target + ToT together (after Flux vs Blizzard target toggle).
function FluxUnitFrames_RefreshTargetAndTotTogether()
    local UF = ns.UnitFrames
    local btf = _G.TargetFrame
    local useFluxTarget = FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ShouldUseFlux("target")
    local useFluxTot = FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ShouldUseFlux("targettarget")
    --- Blizzard TargetFrame:Update() re-shows the default frame when a target exists — skip while Flux target is active.
    if not useFluxTarget and btf and btf.Update then
        pcall(function()
            btf:Update()
        end)
    end
    if btf and btf.totFrame and not useFluxTot then
        local tot = btf.totFrame
        --- Blizzard ToT only (or Blizzard strip on Flux target): never refresh when Flux ToT replaces it.
        pcall(function()
            if tot.OnTargetOfTargetCVarChanged then
                tot:OnTargetOfTargetCVarChanged()
            elseif tot.Update then
                tot:Update()
            end
        end)
    end
    if not UF then
        return
    end
    if ns.TargetFrame then
        if UF.SyncWatchedUnitFrameVisibility then
            pcall(UF.SyncWatchedUnitFrameVisibility, ns.TargetFrame)
        end
        if UF.UpdateHealth then
            pcall(UF.UpdateHealth, ns.TargetFrame, "target")
        end
        if UF.UpdatePower then
            pcall(UF.UpdatePower, ns.TargetFrame, "target")
        end
        if UF.UpdatePortrait then
            pcall(UF.UpdatePortrait, ns.TargetFrame, "target")
        end
        if ns.TargetFrame.UpdatePartition then
            pcall(ns.TargetFrame.UpdatePartition, ns.TargetFrame)
        end
        if ns.TargetFrame.UpdateOuterBorder then
            pcall(ns.TargetFrame.UpdateOuterBorder, ns.TargetFrame)
        end
        if UF.UpdateAuras then
            pcall(UF.UpdateAuras, ns.TargetFrame)
        end
    end
    if ns.TargetOfTargetFrame then
        if UF.SyncWatchedUnitFrameVisibility then
            pcall(UF.SyncWatchedUnitFrameVisibility, ns.TargetOfTargetFrame)
        end
        if UF.UpdateHealth then
            pcall(UF.UpdateHealth, ns.TargetOfTargetFrame, "targettarget")
        end
        if UF.UpdatePower then
            pcall(UF.UpdatePower, ns.TargetOfTargetFrame, "targettarget")
        end
        if UF.UpdatePortrait then
            pcall(UF.UpdatePortrait, ns.TargetOfTargetFrame, "targettarget")
        end
        if ns.TargetOfTargetFrame.UpdatePartition then
            pcall(ns.TargetOfTargetFrame.UpdatePartition, ns.TargetOfTargetFrame)
        end
        if ns.TargetOfTargetFrame.UpdateOuterBorder then
            pcall(ns.TargetOfTargetFrame.UpdateOuterBorder, ns.TargetOfTargetFrame)
        end
    end
    FluxUnitFrames_RefreshTargetOfTargetAnchor()
end

function FluxUnitFrames_ApplyRuntimeTarget(wantFlux)
    if InCombatLockdown() then
        UF.DeferProtected("runtime.target", function()
            FluxUnitFrames_ApplyRuntimeTarget(wantFlux)
        end)
        return
    end

    local function suppressBlizzard()
        if FluxUnitFrames_SuppressBlizzardUnitFrame then
            FluxUnitFrames_SuppressBlizzardUnitFrame("target")
            return
        end
        if TargetFrame then
            -- Detached Blizzard ToT is parented to UIParent; hide explicitly before hiding TargetFrame.
            if TargetFrame.totFrame and TargetFrame.totFrame.SetAlpha then
                TargetFrame.totFrame:SetAlpha(0)
            end
            TargetFrame:UnregisterAllEvents()
            if not InCombatLockdown() and TargetFrame.SetAlpha then
                TargetFrame:SetAlpha(0)
            end
        end
    end

    local function restoreBlizzard()
        local tf = TargetFrame
        if not tf then
            return
        end
        if FluxUnitFrames_RestoreBlizzardTotDefaultParent then
            FluxUnitFrames_RestoreBlizzardTotDefaultParent()
        end
        FluxUnitFrames_ReregisterBlizzardTargetEvents(tf)
        if not InCombatLockdown() then
            if tf.SetAlpha then
                tf:SetAlpha(1)
            end
            tf:Show()
        end
        if tf.Update then
            pcall(function()
                tf:Update()
            end)
        end
        -- One-frame refresh: Edit Mode / layout sometimes needs a second pass after Show + events.
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                local f = _G.TargetFrame
                if f and f.Update then
                    pcall(function()
                        f:Update()
                    end)
                end
            end)
        end
    end

    if wantFlux then
        suppressBlizzard()
        if not ns.TargetFrame then
            targetFrameInitialized = false
            UF.RunInitializer("target")
        else
            FluxUnitFrames_ResumeFluxTargetPlaceholder(ns.TargetFrame)
            FluxUnitFrames_ResumeFluxTargetUnitWatch(ns.TargetFrame)
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(ns.TargetFrame)
            else
                ns.TargetFrame:Show()
            end
            if ns.TargetFrame.UpdatePartition then
                ns.TargetFrame:UpdatePartition()
            end
        end
    else
        if ns.TargetFrame then
            FluxUnitFrames_SuspendFluxTargetPlaceholder(ns.TargetFrame)
            FluxUnitFrames_SuspendFluxTargetUnitWatch(ns.TargetFrame)
            ns.TargetFrame:Hide()
        end
        restoreBlizzard()
    end

    -- Target-of-target anchors to Flux target or Blizzard ToT; re-apply immediately after target mode changes.
    if FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ApplyRuntimeToT then
        FluxUnitFrames_ApplyRuntimeToT(FluxUnitFrames_ShouldUseFlux("targettarget"))
    end

    FluxUnitFrames_RefreshTargetAndTotTogether()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, FluxUnitFrames_RefreshTargetAndTotTogether)
    end
end

-- ---------------------------------------------------------------------------
-- Loader
-- ---------------------------------------------------------------------------
UF.RegisterInitializer("target", InitializeTargetFrame, function() return targetFrameInitialized end, 61)
