-- UnitFrames/FluxUnitFrames_Focus.lua
local addonName, ns = ...
local UF = ns.UnitFrames
local CB = ns.CastBar

-- ---------------------------------------------------------------------------
-- Default position: buff aura panel TOPLEFT at ChatFrame1 TOPRIGHT (re-applied from FluxChatFrame)
-- ---------------------------------------------------------------------------
function FluxUIPositionFocusFrameDefault()
    if InCombatLockdown() then return end
    local frame = ns.FocusFrame
    if not frame or not ChatFrame1 then return end

    -- Placement 2: bottom above Flux raid stack top; right edge at synthetic group-2 column (same grid as raid preview).
    local sideBySide = FluxUnitFrames_GetPlayerTargetPlacement and FluxUnitFrames_GetPlayerTargetPlacement() == 2
    if sideBySide and FluxRaid_GetPlacement2FocusAnchorBottomRight then
        local rx, ry = FluxRaid_GetPlacement2FocusAnchorBottomRight()
        if rx and ry then
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", rx, ry)
            if frame.UpdatePartition then
                frame:UpdatePartition()
            end
            if frame.UpdateOuterBorder then
                frame:UpdateOuterBorder()
            end
            if _G.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack then
                _G.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack()
            end
            return
        end
    end

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", ChatFrame1, "TOPRIGHT", 0, 0)

    if frame.UpdatePartition then
        frame:UpdatePartition()
    end
    if frame.UpdateOuterBorder then
        frame:UpdateOuterBorder()
    end

    local buff = frame.BuffContainer
    if not buff then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", ChatFrame1, "TOPRIGHT", 8, 0)
        return
    end

    local bl, bt = buff:GetLeft(), buff:GetTop()
    local cr, ct = ChatFrame1:GetRight(), ChatFrame1:GetTop()
    if not bl or not bt or not cr or not ct then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", ChatFrame1, "TOPRIGHT", 8, 0)
        return
    end

    local dx = cr - bl
    local dy = ct - bt
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", ChatFrame1, "TOPRIGHT", dx, dy)
end

-- ---------------------------------------------------------------------------
-- Focus Frame Initialization
-- ---------------------------------------------------------------------------
local focusFrameInitialized = false

local function InitializeFocusFrame()
    if focusFrameInitialized then
        return
    end
    -- Re-check at login: FocusFrame / APIs may not exist when FluxAPICompat first parsed.
    if FLUX_API and FLUX_API.RefreshFocusUnitCapability then
        FLUX_API.RefreshFocusUnitCapability()
    end
    if not FLUX_API or not FLUX_API.hasFocusUnit then
        return
    end
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux("focus") then
        focusFrameInitialized = true
        return
    end

    local frameWidth, frameHeight = 119, 50
    if FluxUnitFrames_GetConfiguredFrameSize then
        local w, h = FluxUnitFrames_GetConfiguredFrameSize("focus")
        if w and h then
            frameWidth, frameHeight = w, h
        end
    end

    local frame = UF.CreateBaseFrame("focus", UIParent, frameWidth, frameHeight)

    frame.portraitPosition = "RIGHT"
    -- Match player frame: padding + name/class/spec/cast sit above the HP/power area (not below).
    frame.outerBorderAlignment = "BOTTOM"
    -- Chrome strip only (between HP and top border): ~30% shorter than default 36; cast bar + class icons scale with this.
    frame.outerBorderPadding = 25
    -- Auras sit above the unit frame; FluxUnitFrames_Auras uses bottom→up row fill
    frame.auraFrameAboveUnit = true

    if not InCombatLockdown() then
        frame:ClearAllPoints()
        if ChatFrame1 then
            frame:SetPoint("TOPLEFT", ChatFrame1, "TOPRIGHT", 8, 0)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end

    UF.CreateHealthBar(frame)
    UF.CreatePowerBar(frame)

    if ns.HealthLossOverlay and ns.HealthLossOverlay.Initialize then
        ns.HealthLossOverlay.Initialize(frame)
    end
    if ns.PowerCostOverlay and ns.PowerCostOverlay.Initialize then
        ns.PowerCostOverlay.Initialize(frame)
    end

    if not FluxUnitFrames_ShouldShowPortrait or FluxUnitFrames_ShouldShowPortrait("focus") then
        UF.CreatePortrait(frame)
        if UF.CreatePortraitCombatFeedback then
            UF.CreatePortraitCombatFeedback(frame)
        end
        if ns.API and ns.API.NeedsPortraitCompat and ns.API.NeedsPortraitCompat()
            and ns.API.SetupPortraitModel and frame.Portrait and FluxUnitFrames_ShouldUse3DPortrait() then
            ns.API.SetupPortraitModel(frame.Portrait, "focus")
        end
    end

    if UF.CreateThreatBar then
        UF.CreateThreatBar(frame)
    end

    UF.CreateAtlasBorder(frame)
    UF.CreateOuterBorder(frame)

    if UF.LayoutThreatBar and frame.ThreatBar then
        UF.LayoutThreatBar(frame)
    end

    -- Aura layout from Unit frames options (auraFocus); defaults match compact focus frame
    if UF.ApplyAuraOptionsToFrame and FluxUnitFrames_GetAuraConfigTables then
        local b, d = FluxUnitFrames_GetAuraConfigTables("focus")
        UF.ApplyAuraOptionsToFrame(frame, true, true, b, d)
    else
        UF.EnableAuras(frame, true, true, { size = 20, spacing = 2 }, { size = 20, spacing = 2 })
    end

    if CB and CB.CreateCastBar then
        CB.CreateCastBar(frame, "focus")
    end

    -- Blizzard focus UI: only the main FocusFrame is replaced here; FocusFrameToT is handled in FluxUnitFrames_FocusTarget.
    if FluxUnitFrames_SuppressBlizzardUnitFrame and FluxUnitFrames_ShouldUseFlux("focus") then
        FluxUnitFrames_SuppressBlizzardUnitFrame("focus")
    else
        local function SuppressBlizzardFocusFrame(ff)
            if not ff then return end
            ff:UnregisterAllEvents()
            if not InCombatLockdown() and ff.SetAlpha then
                ff:SetAlpha(0)
            end
        end
        if FocusFrame then
            SuppressBlizzardFocusFrame(FocusFrame)
        end
    end

    local blizzardFocusHideFrame = CreateFrame("Frame")
    blizzardFocusHideFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    blizzardFocusHideFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    blizzardFocusHideFrame:SetScript("OnEvent", function()
        if InCombatLockdown() then return end
        if FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ShouldUseFlux("focus") then
            if FluxUnitFrames_SuppressBlizzardUnitFrame then
                FluxUnitFrames_SuppressBlizzardUnitFrame("focus")
            elseif FocusFrame then
                if FocusFrame.SetAlpha then
                    FocusFrame:SetAlpha(0)
                end
            end
        end
    end)

    if frame.UpdatePartition then
        frame:UpdatePartition()
    end
    if frame.UpdateGroupText then
        frame:UpdateGroupText()
    end

    local index = GetRaidTargetIndex("focus")
    if frame.raidIcon then
        if index then
            SetRaidTargetIconTexture(frame.raidIcon, index)
            frame.raidIcon:Show()
        else
            frame.raidIcon:Hide()
        end
    end

    if frame.UpdateOuterBorder then
        frame:UpdateOuterBorder()
    end

    if UF.SyncWatchedUnitFrameVisibility then
        UF.SyncWatchedUnitFrameVisibility(frame)
    elseif not (UnitExists("focus") or UnitIsVisible("focus")) then
        frame:Hide()
    end

    ns.FocusFrame = frame
    _G.FluxFocusFrame = frame

    C_Timer.After(0, FluxUIPositionFocusFrameDefault)
    C_Timer.After(0.5, FluxUIPositionFocusFrameDefault)
    C_Timer.After(2, FluxUIPositionFocusFrameDefault)

    focusFrameInitialized = true
end

function FluxUnitFrames_ApplyRuntimeFocus(wantFlux)
    if not FLUX_API or not FLUX_API.hasFocusUnit then
        return
    end
    if InCombatLockdown() then
        C_Timer.After(0.5, function()
            FluxUnitFrames_ApplyRuntimeFocus(wantFlux)
        end)
        return
    end

    local function suppressBlizzard()
        if FluxUnitFrames_SuppressBlizzardUnitFrame then
            FluxUnitFrames_SuppressBlizzardUnitFrame("focus")
            return
        end
        local ff = FocusFrame
        if not ff then
            return
        end
        ff:UnregisterAllEvents()
        if not InCombatLockdown() and ff.SetAlpha then
            ff:SetAlpha(0)
        end
    end

    local function restoreBlizzard()
        local ff = FocusFrame
        if not ff then
            return
        end
        pcall(function()
            if TargetFrameMixin and TargetFrameMixin.OnLoad and FocusFrame_OpenMenu then
                TargetFrameMixin.OnLoad(ff, "focus", FocusFrame_OpenMenu)
            end
        end)
        if not InCombatLockdown() then
            if ff.SetAlpha then
                ff:SetAlpha(1)
            end
            ff:Show()
        end
        if ff.Update then
            pcall(function()
                ff:Update()
            end)
        end
    end

    if wantFlux then
        suppressBlizzard()
        if not ns.FocusFrame then
            focusFrameInitialized = false
            InitializeFocusFrame()
        else
            ns.FocusFrame:Show()
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(ns.FocusFrame)
            end
            if ns.FocusFrame.UpdatePartition then
                ns.FocusFrame:UpdatePartition()
            end
            FluxUIPositionFocusFrameDefault()
        end
        return
    end

    if ns.FocusFrame then
        ns.FocusFrame:Hide()
    end
    _G.FluxFocusFrame = ns.FocusFrame
    restoreBlizzard()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    InitializeFocusFrame()
end)

