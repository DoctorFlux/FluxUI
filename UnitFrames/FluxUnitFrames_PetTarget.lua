-- UnitFrames/FluxUnitFrames_PetTarget.lua
-- Minimal vertical HP bar for the pet's target (pettarget), no text.
local addonName, ns = ...

-- Keep the Forever compatibility fallback local to Flux-owned frames.
local FluxDrivers = ((ns and ns.Flux) or _G.Flux or {}).Restricted
local useFluxDrivers = FluxDrivers and FluxDrivers.Works and not FluxDrivers.Works()
local RegisterStateDriver = (useFluxDrivers and FluxDrivers.RegisterStateDriver) or RegisterStateDriver
local UnregisterStateDriver = (useFluxDrivers and FluxDrivers.UnregisterStateDriver) or UnregisterStateDriver
local UnregisterUnitWatch = (useFluxDrivers and FluxDrivers.UnregisterUnitWatch) or UnregisterUnitWatch
local UnitWatchRegistered = (useFluxDrivers and FluxDrivers.UnitWatchRegistered) or UnitWatchRegistered
local API = ns.API
local Border = ns.Border
local UF = ns.UnitFrames

local function GetPetTargetBarWidth()
    if FluxUnitFrames_GetConfiguredPetTargetBarWidth then
        return FluxUnitFrames_GetConfiguredPetTargetBarWidth()
    end
    return 23
end
-- No horizontal gap: left edge of pet target meets right edge of anchor
local ANCHOR_GAP = 0
local FALLBACK_PET_HEIGHT = 50

local petTargetFrameInitialized = false

-- UnitExists("pettarget") only. A visible-but-missing token must not keep the bar up.
local PET_TARGET_VISIBILITY = "[@pettarget,exists] show; hide"

local function FluxUnitFrames_SuspendFluxPetTargetUnitWatch(frame)
    if not frame or frame._fluxPetTargetUnitWatchSuspended then
        return
    end
    if UnregisterStateDriver then
        UnregisterStateDriver(frame, "visibility")
    end
    if UnregisterUnitWatch and UnitWatchRegistered and UnitWatchRegistered(frame) then
        UnregisterUnitWatch(frame)
    end
    frame._fluxPetTargetUnitWatchSuspended = true
end

local function FluxUnitFrames_ResumeFluxPetTargetUnitWatch(frame)
    if not frame or not frame._fluxPetTargetUnitWatchSuspended or not RegisterStateDriver then
        return
    end
    RegisterStateDriver(frame, "visibility", PET_TARGET_VISIBILITY)
    frame._fluxPetTargetUnitWatchSuspended = nil
end

local function InitializePetTargetFrame()
    if petTargetFrameInitialized then
        return
    end
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux("pettarget") then
        petTargetFrameInitialized = true
        return
    end

    local parent = ns.PetFrame or UIParent
    local frame = CreateFrame("Button", "FluxUnitFrame_pettarget", parent, "SecureUnitButtonTemplate")
    SecureUnitButton_OnLoad(frame, "pettarget")
    UF.ConfigureUnitMenu(frame, "pettarget")
    frame:SetAttribute("unit", "pettarget")
    frame.unit = "pettarget"
    frame:EnableMouse(true)

    local barW = GetPetTargetBarWidth()
    if UF.RecordFrameDimensions then UF.RecordFrameDimensions(frame, barW, FALLBACK_PET_HEIGHT) end
    frame:SetSize(barW, FALLBACK_PET_HEIGHT)
    frame._fluxLayoutBaseWidth = barW
    if UF and UF.RegisterEmulatedHorizontalSqueeze then
        UF.RegisterEmulatedHorizontalSqueeze(frame)
    end
    local baseLevel = (ns.PetFrame and ns.PetFrame:GetFrameLevel()) or parent:GetFrameLevel()
    frame:SetFrameLevel(baseLevel + 5)

    if Border and Border.ApplyTo then
        -- Same as UF.CreateBaseFrame / pet unit chrome
        Border:ApplyTo(frame, 2, 2, 2, 6)
        Border:SetClassColor(frame, 1, true)
    end

    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetFrameLevel(frame:GetFrameLevel() + 2)
    UF.ConfigureVerticalTargetHealth(frame, bar)

    -- TPerl-style ADD gold mouseover (inside border; above health bar)
    frame.mouseoverHighlight = UF.CreateMouseoverHighlight(frame, { left = 3, top = 3, right = 3, bottom = 3, outH = 0, outV = 0 }, 11)

    local function UpdateHealth()
        UF.UpdateVerticalTargetHealth(frame, "pettarget")
    end
    frame._fluxRefreshHealth = UpdateHealth

    local function UpdatePosition()
        if not ns.PetFrame then
            return false
        end
        if InCombatLockdown() then
            frame.needsPositionUpdate = true
            if not frame._petTargetEventFrame:IsEventRegistered("PLAYER_REGEN_ENABLED") then
                frame._petTargetEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            end
            return false
        end
        frame.needsPositionUpdate = false

        local h, ignoredWidth
        if UF.GetFramePublicDimensions then ignoredWidth, h = UF.GetFramePublicDimensions(ns.PetFrame)
        else h = ns.PetFrame:GetHeight() end
        if API.IsSecretValue and API.IsSecretValue(h) then h = nil end
        if h and h > 0 then
            if UF.RecordFrameDimensions then UF.RecordFrameDimensions(frame, nil, h) end
            frame:SetHeight(h)
        end
        if UF and UF.ApplyEmulatedHorizontalSqueezeForFrame then
            UF.ApplyEmulatedHorizontalSqueezeForFrame(frame)
        else
            local width = GetPetTargetBarWidth()
            if UF.RecordFrameDimensions then UF.RecordFrameDimensions(frame, width) end
            frame:SetWidth(width)
        end

        if frame:GetParent() ~= ns.PetFrame then
            frame:SetParent(ns.PetFrame)
            frame:SetFrameLevel(ns.PetFrame:GetFrameLevel() + 5)
        end

        local anchor = ns.PetFrame.outerBorderFrame or ns.PetFrame.PortraitFrame or ns.PetFrame
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", ANCHOR_GAP, 0)
        if UF.LayoutVerticalTargetHealth then UF.LayoutVerticalTargetHealth(frame) end
        return true
    end

    frame._fluxRefreshLayout = UpdatePosition

    -- Secure Show/Hide from pettarget existence, including a target gained or
    -- lost in combat. Do not also RegisterUnitWatch.
    if RegisterStateDriver then
        RegisterStateDriver(frame, "visibility", PET_TARGET_VISIBILITY)
    end
    frame:HookScript("OnShow", function(self)
        local function paint()
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(self)
            end
        end
        if InCombatLockdown and InCombatLockdown() and C_Timer and C_Timer.After then
            C_Timer.After(0, paint)
        else
            paint()
        end
    end)

    frame:SetScript("OnEnter", function(self)
        if self.mouseoverHighlight and (not FluxUnitFrames_ShouldShowMouseover or FluxUnitFrames_ShouldShowMouseover(self.unit)) then
            self.mouseoverHighlight:Show()
        end
        UF.ShowUnitTooltip(self, "pettarget")
    end)
    frame:SetScript("OnLeave", function(self)
        if self.mouseoverHighlight then
            self.mouseoverHighlight:Hide()
        end
        UF.HideUnitTooltip()
    end)

    local evt = CreateFrame("Frame", nil, frame)
    frame._petTargetEventFrame = evt
    evt:RegisterUnitEvent("UNIT_HEALTH", "pettarget")
    evt:RegisterUnitEvent("UNIT_MAXHEALTH", "pettarget")
    evt:RegisterUnitEvent("UNIT_CONNECTION", "pettarget")
    evt:RegisterUnitEvent("UNIT_FLAGS", "pettarget")
    evt:RegisterUnitEvent("UNIT_FACTION", "pettarget")
    evt:RegisterUnitEvent("UNIT_TARGET", "pet")
    evt:RegisterUnitEvent("UNIT_PET", "player")
    evt:RegisterEvent("PLAYER_ENTERING_WORLD")
    evt:RegisterEvent("PLAYER_REGEN_ENABLED")

    evt:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_REGEN_ENABLED" then
            if frame.needsPositionUpdate then
                UpdatePosition()
            end
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(frame)
            end
            return
        end
        if event == "UNIT_PET" and unit ~= "player" then
            return
        end
        if event == "UNIT_TARGET" and unit ~= "pet" then
            return
        end
        if event == "UNIT_TARGET" or event == "UNIT_PET" or event == "PLAYER_ENTERING_WORLD" then UF.ResetVerticalTargetHealth(frame) end
        UpdateHealth()
        UpdatePosition()
        if UF.SyncWatchedUnitFrameVisibility then
            UF.SyncWatchedUnitFrameVisibility(frame)
        end
    end)

    UpdatePosition()
    UpdateHealth()
    if UF.SyncWatchedUnitFrameVisibility then
        UF.SyncWatchedUnitFrameVisibility(frame)
    end

    C_Timer.After(1, function()
        UpdatePosition()
        UpdateHealth()
    end)
    C_Timer.After(5, function()
        UpdatePosition()
        UpdateHealth()
    end)

    ns.PetTargetFrame = frame
    petTargetFrameInitialized = true
end

function FluxUnitFrames_ApplyRuntimePetTarget(wantFlux)
    if InCombatLockdown() then
        UF.DeferProtected("runtime.pettarget", function()
            FluxUnitFrames_ApplyRuntimePetTarget(wantFlux)
        end)
        return
    end

    if wantFlux then
        if not ns.PetTargetFrame then
            petTargetFrameInitialized = false
            UF.RunInitializer("pettarget")
        else
            FluxUnitFrames_ResumeFluxPetTargetUnitWatch(ns.PetTargetFrame)
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(ns.PetTargetFrame)
            end
        end
    else
        if ns.PetTargetFrame then
            FluxUnitFrames_SuspendFluxPetTargetUnitWatch(ns.PetTargetFrame)
            ns.PetTargetFrame:SetAlpha(1)
            ns.PetTargetFrame:Hide()
        end
    end
end

-- ---------------------------------------------------------------------------
-- Loader
-- ---------------------------------------------------------------------------
UF.RegisterInitializer("pettarget", InitializePetTargetFrame, function() return petTargetFrameInitialized end, 66)
