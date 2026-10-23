-- UnitFrames/FluxUnitFrames_FocusTarget.lua
-- Focus target-of-target: HP bar + atlas border only (matches focus bar width & health height)
local addonName, ns = ...
local UF = ns.UnitFrames

-- Fallback if FocusFrame is not ready yet (matches FluxUnitFrames_Focus defaults).
local FOCUS_STYLE_WIDTH = 119
local FOCUS_STYLE_TOTAL_HEIGHT = 50
-- Nudge focus target upward vs focus BOTTOMLEFT (positive = up on screen)
local FOCUS_TARGET_ANCHOR_Y = 6

--- Full visual width of focus: bar column + portrait (same as outerBorder / atlas combined width).
local function GetFocusFullVisualWidth(ff)
    if not ff then return FOCUS_STYLE_WIDTH end
    if ff.outerBorderFrame and ff.outerBorderFrame.GetWidth then
        local ow = ff.outerBorderFrame:GetWidth()
        if ow and ow > 1 then
            return ow
        end
    end
    local tw = ff:GetWidth() or FOCUS_STYLE_WIDTH
    if ff.PortraitFrame and ff.PortraitFrame:IsShown() then
        local ph = ff:GetHeight() or FOCUS_STYLE_TOTAL_HEIGHT
        return tw + ph + 2 -- portrait square + gap (matches UpdateOuterBorder combinedWidth)
    end
    return tw
end

local function MatchFocusBarMetrics(frame)
    local ff = ns.FocusFrame
    if not ff or not ff.GetWidth or not ff.GetHeight then return end
    local w = GetFocusFullVisualWidth(ff)
    local fh = ff:GetHeight() or FOCUS_STYLE_TOTAL_HEIGHT
    local h = UF.GetFluxStylePartitionHealthHeight(fh, "focus") + 4 -- 2 top + 2 bottom border insets (CreateBaseFrame borderInsetY=2)
    if not InCombatLockdown() then
        frame:SetSize(w, h)
    end
    if frame.UpdatePartition then
        frame:UpdatePartition()
    end
end

local ftInitialized = false

local function InitializeFocusTargetFrame()
    if ftInitialized then
        return
    end
    if FLUX_API and FLUX_API.RefreshFocusUnitCapability then
        FLUX_API.RefreshFocusUnitCapability()
    end
    if not FLUX_API or not FLUX_API.hasFocusUnit then
        return
    end
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux("focustarget") then
        ftInitialized = true
        return
    end
    if not ns.FocusFrame then
        return
    end

    local healthPix = UF.GetFluxStylePartitionHealthHeight(FOCUS_STYLE_TOTAL_HEIGHT, "focus")
    local frameHeight = healthPix + 4 -- 2px top + 2px bottom inside Border shell (matches UpdateFramePartition _fluxHealthBarOnly)

    local frame = UF.CreateBaseFrame("focustarget", UIParent, FOCUS_STYLE_WIDTH, frameHeight, 2) -- sized before Focus may exist; MatchFocusBarMetrics fixes
    frame._fluxHealthBarOnly = true
    frame.barAreaLeft = 2
    frame.barAreaRight = -2
    frame.portraitPosition = nil

    -- No outer-border chrome; main SecureUnitButton must receive clicks
    frame:EnableMouse(true)
    frame:SetMouseClickEnabled(true)

    if not InCombatLockdown() then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    end

    UF.CreateHealthBar(frame)
    UF.CreatePowerBar(frame)
    if frame.Power then
        frame.Power:Hide()
    end

    if ns.HealthLossOverlay and ns.HealthLossOverlay.Initialize then
        ns.HealthLossOverlay.Initialize(frame)
    end
    if ns.PowerCostOverlay and ns.PowerCostOverlay.Initialize then
        ns.PowerCostOverlay.Initialize(frame)
    end

    UF.CreateAtlasBorder(frame, 2) -- match tight base frame border; avoids gap under HP bar vs atlas

    -- Action-bar style mouseover ring; uniform inset inside Border shell (above health fill)
    frame.mouseoverHighlight = UF.CreateMouseoverHighlight(frame, { left = 3, top = 3, right = 3, bottom = 3, outH = 0, outV = 0 }, 11)

    local function UpdatePosition()
        MatchFocusBarMetrics(frame)
        local ff = ns.FocusFrame
        if ff and not InCombatLockdown() then
            frame:ClearAllPoints()
            -- Full width aligns with focus outer edge; sit slightly under bar column, nudged up
            frame:SetPoint("TOPLEFT", ff, "BOTTOMLEFT", 0, FOCUS_TARGET_ANCHOR_Y)
            return true
        end
        return false
    end

    if frame.UpdatePartition then
        frame:UpdatePartition()
    end

    UpdatePosition()
    C_Timer.After(0, function() MatchFocusBarMetrics(frame) end)
    C_Timer.After(0.5, UpdatePosition)
    C_Timer.After(1.0, UpdatePosition)
    C_Timer.After(2.0, UpdatePosition)

    UF.UpdateHealth(frame, "focustarget")
    if frame.UpdatePartition then frame:UpdatePartition() end

    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("UNIT_TARGET")
    frame:RegisterEvent("UNIT_NAME_UPDATE")

    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_FOCUS_CHANGED"
            or (event == "UNIT_TARGET" and unit == "focus")
            or (event == "UNIT_NAME_UPDATE" and unit == "focustarget") then
            UpdatePosition()
            UF.UpdateHealth(self, "focustarget")
            if self.UpdatePartition then self:UpdatePartition() end
            if self.UpdateBorderColors then self:UpdateBorderColors() end

            self:RegisterUnitEvent("UNIT_HEALTH", "focustarget")
            self:RegisterUnitEvent("UNIT_MAXHEALTH", "focustarget")
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            UF.UpdateHealth(self, "focustarget")
        elseif (event == "PLAYER_FLAGS_CHANGED" or event == "UNIT_FACTION") and unit == "focustarget" then
            UF.UpdateHealth(self, "focustarget")
        end
    end)

    frame:SetScript("OnEnter", function(self)
        if self.mouseoverHighlight and (not FluxUnitFrames_ShouldShowMouseover or FluxUnitFrames_ShouldShowMouseover(self.unit)) then
            self.mouseoverHighlight:Show()
        end
        UF.ShowUnitTooltip(self, "focustarget")
    end)
    frame:SetScript("OnLeave", function(self)
        if self.mouseoverHighlight then
            self.mouseoverHighlight:Hide()
        end
        UF.HideUnitTooltip()
    end)

    if FluxUnitFrames_SuppressBlizzardUnitFrame and FluxUnitFrames_ShouldUseFlux("focustarget") then
        FluxUnitFrames_SuppressBlizzardUnitFrame("focustarget")
    elseif FocusFrameToT then
        FocusFrameToT:UnregisterAllEvents()
        if not InCombatLockdown() and FocusFrameToT.SetAlpha then
            FocusFrameToT:SetAlpha(0)
        end
    end

    local blizzardFocusToTHideFrame = CreateFrame("Frame")
    blizzardFocusToTHideFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    blizzardFocusToTHideFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    blizzardFocusToTHideFrame:SetScript("OnEvent", function()
        if InCombatLockdown() then return end
        if FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ShouldUseFlux("focustarget") then
            if FluxUnitFrames_SuppressBlizzardUnitFrame then
                FluxUnitFrames_SuppressBlizzardUnitFrame("focustarget")
            elseif FocusFrameToT then
                if FocusFrameToT.SetAlpha then
                    FocusFrameToT:SetAlpha(0)
                end
            end
        end
    end)

    ns.FocusTargetFrame = frame
    _G.FluxFocusTargetFrame = frame

    ftInitialized = true
end

function FluxUnitFrames_ApplyRuntimeFocusTarget(wantFlux)
    if not FLUX_API or not FLUX_API.hasFocusUnit then
        return
    end
    if InCombatLockdown() then
        UF.DeferProtected("runtime.focustarget", function()
            FluxUnitFrames_ApplyRuntimeFocusTarget(wantFlux)
        end)
        return
    end

    local fft = _G.FocusFrameToT

    local function suppressBlizzardToT(ff)
        if FluxUnitFrames_SuppressBlizzardUnitFrame then
            FluxUnitFrames_SuppressBlizzardUnitFrame("focustarget")
            return
        end
        if not ff then
            return
        end
        ff:UnregisterAllEvents()
        if not InCombatLockdown() and ff.SetAlpha then
            ff:SetAlpha(0)
        end
    end

    local function restoreBlizzardToT(ff)
        if not ff then
            return
        end
        pcall(function()
            if TargetFrameMixin and TargetFrameMixin.OnLoad and FocusFrame_OpenMenu then
                TargetFrameMixin.OnLoad(ff, "focustarget", FocusFrame_OpenMenu)
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
        if fft then
            suppressBlizzardToT(fft)
        end
        if not ns.FocusFrame then
            return
        end
        if not ns.FocusTargetFrame then
            ftInitialized = false
            UF.RunInitializer("focustarget")
        else
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(ns.FocusTargetFrame)
            else
                ns.FocusTargetFrame:Show()
            end
            if ns.FocusTargetFrame.UpdatePartition then
                ns.FocusTargetFrame:UpdatePartition()
            end
        end
        return
    end

    if ns.FocusTargetFrame then
        ns.FocusTargetFrame:Hide()
    end
    if fft then
        restoreBlizzardToT(fft)
    end
end

--- Re-apply focus target-of-target size (from focus) + anchor; used when layout options change.
function FluxUnitFrames_MatchFocusTargetToFocus()
    local frame = ns.FocusTargetFrame
    if not frame then
        return
    end
    MatchFocusBarMetrics(frame)
    local ff = ns.FocusFrame
    if ff and not InCombatLockdown() then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", ff, "BOTTOMLEFT", 0, FOCUS_TARGET_ANCHOR_Y)
    end
    if frame.UpdatePartition then
        frame:UpdatePartition()
    end
    if frame.UpdateAtlasBorder then
        frame:UpdateAtlasBorder()
    end
end

UF.RegisterInitializer("focustarget", InitializeFocusTargetFrame, function() return ftInitialized end, 63)
