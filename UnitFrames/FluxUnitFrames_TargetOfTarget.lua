-- UnitFrames/FluxUnitFrames_TargetOfTarget.lua
local addonName, ns = ...
local UF = ns.UnitFrames
local CB = ns.CastBar

local function FluxUnitFrames_SuspendFluxToTUnitWatch(frame)
    if not frame or frame._fluxUnitWatchSuspended or not UnregisterUnitWatch then
        return
    end
    UnregisterUnitWatch(frame)
    frame._fluxUnitWatchSuspended = true
end

local function FluxUnitFrames_ResumeFluxToTUnitWatch(frame)
    if not frame or not frame._fluxUnitWatchSuspended or not RegisterUnitWatch then
        return
    end
    RegisterUnitWatch(frame)
    frame._fluxUnitWatchSuspended = nil
end

-- ---------------------------------------------------------------------------
-- Target of Target Frame Initialization
-- ---------------------------------------------------------------------------
local totFrameInitialized = false

local function InitializeTargetOfTargetFrame()
    if totFrameInitialized then
        return
    end
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux("targettarget") then
        totFrameInitialized = true
        return
    end

    local frameWidth, frameHeight = 125, 60
    if FluxUnitFrames_GetConfiguredFrameSize then
        local w, h = FluxUnitFrames_GetConfiguredFrameSize("targettarget")
        if w and h then
            frameWidth, frameHeight = w, h
        end
    end

    local frame = UF.CreateBaseFrame("targettarget", UIParent, frameWidth, frameHeight)
    frame.barAreaLeft = -2
    frame.barAreaRight = -6

    -- Configure outer border alignment ("BOTTOM" aligns bottom with atlas border, "TOP" aligns top with atlas border)
    frame.outerBorderAlignment = "BOTTOM"

    -- Configure outer border padding (how much taller the outer border is than the unit frame)
    frame.outerBorderPadding = 20

    -- Configure portrait position (no portrait for target of target)
    frame.portraitPosition = nil -- No portrait, so this shouldn't affect layout

    -- Configure right-click menu (true by default, can be set to false to disable)
    -- frame.outerBorderFrame:SetRightClickMenu(false) -- Uncomment to disable right-click menu for this frame

    -- Temporary position until TargetFrame exists; UpdatePosition applies classic vs side-by-side layout.
    if not InCombatLockdown() then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    end

    local function UpdatePosition()
        local tf = ns.TargetFrame
        if not tf or not tf.outerBorderFrame then
            return false
        end
        if InCombatLockdown() then
            frame.needsTotAnchorUpdate = true
            return false
        end
        frame.needsTotAnchorUpdate = nil

        local sideBySide = FluxUnitFrames_GetPlayerTargetPlacement
            and FluxUnitFrames_GetPlayerTargetPlacement() == 2
            and FluxUnitFrames_ShouldUseFlux("player")
            and FluxUnitFrames_ShouldUseFlux("target")

        frame:ClearAllPoints()
        if sideBySide then
            local ph = tf:GetHeight() or 100
            local totH = frame:GetHeight() or 60
            local inset = 8
            local innerH = math.max(10, ph - inset)
            local centerFromTop = 2 + innerH / 2
            local yOff = -centerFromTop + totH / 2
            if frame:GetParent() ~= tf then
                frame:SetParent(tf)
            end
            frame:SetFrameLevel((tf:GetFrameLevel() or 0) + 30)
            frame:SetPoint("TOPRIGHT", tf, "TOPRIGHT", 0, yOff)
        else
            if frame:GetParent() ~= UIParent then
                frame:SetParent(UIParent)
            end
            frame:SetPoint("TOPLEFT", tf.outerBorderFrame, "BOTTOMRIGHT", 0, -12)
        end
        return true
    end

    local regen = CreateFrame("Frame", nil, frame)
    regen:RegisterEvent("PLAYER_REGEN_ENABLED")
    regen:SetScript("OnEvent", function()
        if frame.needsTotAnchorUpdate then
            UpdatePosition()
        end
    end)

    -- Create Bars
    -- Health Bar (Managed by Partition)
    local health = UF.CreateHealthBar(frame)
    health:Show() -- Make sure it's visible

    -- Power Bar (Managed by Partition) - Only main resource bar for target of target
    local power = UF.CreatePowerBar(frame)
    power:Show() -- Make sure it's visible

    -- Power Cost Overlay (darkened resource cost while casting)
    if ns.HealthLossOverlay and ns.HealthLossOverlay.Initialize then
        ns.HealthLossOverlay.Initialize(frame)
    end
    if ns.PowerCostOverlay and ns.PowerCostOverlay.Initialize then
        ns.PowerCostOverlay.Initialize(frame)
    end

    -- NO Additional Power Bar for target of target (user requested only main resource bar)

    -- Bars will be updated by the shared event system when needed

    -- NO Portrait for target of target (as requested)

    -- Atlas Border (covers both unit frame and portrait, layered on top)
    local atlasBorder = UF.CreateAtlasBorder(frame)

    -- Outer Border (even more outer with background backdrop)
    local outerBorder = UF.CreateOuterBorder(frame)

    -- Remove class/spec icons for target of target frame
    if frame.classIcon then frame.classIcon = nil end
    if frame.specIcon then frame.specIcon = nil end
    if frame.classIconLeftBorder then frame.classIconLeftBorder = nil end
    if frame.classIconRightBorder then frame.classIconRightBorder = nil end

    -- NO Cast Bar for target of target (as requested)

    -- Force initial layout
    if frame.UpdatePartition then
        frame:UpdatePartition()
    end

    -- Force initial group text update
    if frame.UpdateGroupText then
        frame.UpdateGroupText()
    end

    -- Force initial raid icon update (oUF style)
    local index = GetRaidTargetIndex("targettarget")
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

    -- RegisterUnitWatch handles initial visibility automatically
    -- Initial data updates (will be updated when unit becomes visible)
    UF.UpdateHealth(frame, "targettarget")
    UF.UpdatePower(frame, "targettarget")
    UF.UpdatePortrait(frame, "targettarget")
    if frame.UpdatePartition then frame:UpdatePartition() end
    if frame.UpdateOuterBorder then frame:UpdateOuterBorder() end
    if UF.SyncWatchedUnitFrameVisibility then
        UF.SyncWatchedUnitFrameVisibility(frame)
    end

    -- Do not replace Shared.lua OnEvent (CreateBaseFrame): keep heal prediction, UI scale, group text, etc.
    -- Only re-anchor when the target frame / target-of-target relationship changes.
    frame:HookScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED"
            or (event == "UNIT_TARGET" and unit == "target")
            or (event == "UNIT_NAME_UPDATE" and unit == "targettarget") then
            UpdatePosition()
        end
    end)

    frame._fluxRefreshTotAnchor = UpdatePosition
    UpdatePosition()
    C_Timer.After(0.5, UpdatePosition)
    C_Timer.After(1.0, UpdatePosition)
    C_Timer.After(2.0, UpdatePosition)

    ns.TargetOfTargetFrame = frame

    if TargetFrame and TargetFrame.totFrame then
        if FluxUnitFrames_SuppressBlizzardUnitFrame and FluxUnitFrames_ShouldUseFlux("targettarget") then
            FluxUnitFrames_SuppressBlizzardUnitFrame("targettarget")
        else
            if TargetFrame.totFrame.SetAlpha then
                TargetFrame.totFrame:SetAlpha(0)
            end
        end
    end

    totFrameInitialized = true
end

--- Blizzard ToT is parented to Blizzard TargetFrame. When Flux replaces the target frame, the default
--- Blizzard frame is hidden, so the ToT must be reparented to stay visible if the user chose Blizzard ToT.
--- Parent must be a frame with unit "target" (e.g. Flux target), NOT UIParent: TargetOfTargetMixin:Update()
--- uses parent.unit; UIParent has no unit and Blizzard ToT breaks.
local function FluxBlizzTot_AttachToFluxTarget(bTot)
    if not bTot then
        return
    end
    local flux = ns.TargetFrame
    local anchor = flux and flux.outerBorderFrame
    if not anchor then
        return
    end
    bTot._fluxUIParentedToFluxTarget = true
    bTot:SetParent(flux)
    bTot:ClearAllPoints()
    local sideBySide = FluxUnitFrames_GetPlayerTargetPlacement
        and FluxUnitFrames_GetPlayerTargetPlacement() == 2
        and FluxUnitFrames_ShouldUseFlux("player")
        and FluxUnitFrames_ShouldUseFlux("target")
    if sideBySide then
        local ph = flux:GetHeight() or 100
        local bh = bTot:GetHeight() or 60
        local inset = 8
        local innerH = math.max(10, ph - inset)
        local centerFromTop = 2 + innerH / 2
        local yOff = -centerFromTop + bh / 2
        bTot:SetPoint("TOPRIGHT", flux, "TOPRIGHT", 0, yOff)
    else
        bTot:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", 0, -12)
    end
    bTot:SetFrameStrata(flux:GetFrameStrata())
    bTot:SetFrameLevel((flux:GetFrameLevel() or 0) + 25)
    pcall(function()
        if bTot.OnTargetOfTargetCVarChanged then
            bTot:OnTargetOfTargetCVarChanged()
        end
    end)
    if bTot.Update then
        pcall(function()
            bTot:Update()
        end)
    end
end

function FluxUnitFrames_RestoreBlizzardTotDefaultParent()
    local tf = _G.TargetFrame
    local bTot = tf and tf.totFrame
    if not bTot or not bTot._fluxUIParentedToFluxTarget then
        return
    end
    bTot._fluxUIParentedToFluxTarget = nil
    bTot:SetParent(tf)
    bTot:ClearAllPoints()
    -- Layout is reapplied by TargetFrame:Update() after events are re-registered (see FluxUnitFrames_Target).
end

function FluxUnitFrames_ApplyRuntimeToT(wantFlux)
    if InCombatLockdown() then
        C_Timer.After(0.5, function()
            FluxUnitFrames_ApplyRuntimeToT(wantFlux)
        end)
        return
    end

    local bTot = TargetFrame and TargetFrame.totFrame

    if wantFlux then
        if bTot then
            if bTot._fluxUIParentedToFluxTarget then
                FluxUnitFrames_RestoreBlizzardTotDefaultParent()
            end
            bTot:Hide()
        end
        if not ns.TargetOfTargetFrame then
            totFrameInitialized = false
            InitializeTargetOfTargetFrame()
        else
            FluxUnitFrames_ResumeFluxToTUnitWatch(ns.TargetOfTargetFrame)
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(ns.TargetOfTargetFrame)
            else
                ns.TargetOfTargetFrame:Show()
            end
            if ns.TargetOfTargetFrame.UpdatePartition then
                ns.TargetOfTargetFrame:UpdatePartition()
            end
        end
        return
    end

    if ns.TargetOfTargetFrame then
        FluxUnitFrames_SuspendFluxToTUnitWatch(ns.TargetOfTargetFrame)
        ns.TargetOfTargetFrame:Hide()
    end
    if bTot then
        local useFluxTarget = FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ShouldUseFlux("target")
        if useFluxTarget and ns.TargetFrame then
            if ns.TargetFrame.outerBorderFrame then
                FluxBlizzTot_AttachToFluxTarget(bTot)
            else
                C_Timer.After(0, function()
                    if not bTot or bTot._fluxUIParentedToFluxTarget then
                        return
                    end
                    if FluxUnitFrames_ShouldUseFlux
                        and FluxUnitFrames_ShouldUseFlux("target")
                        and not FluxUnitFrames_ShouldUseFlux("targettarget")
                        and ns.TargetFrame
                        and ns.TargetFrame.outerBorderFrame then
                        FluxBlizzTot_AttachToFluxTarget(bTot)
                    end
                end)
            end
        else
            FluxUnitFrames_RestoreBlizzardTotDefaultParent()
            if not InCombatLockdown() then
                bTot:Show()
            end
            if bTot.Update then
                pcall(function()
                    bTot:Update()
                end)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Loader
-- ---------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event)
    InitializeTargetOfTargetFrame()
end)