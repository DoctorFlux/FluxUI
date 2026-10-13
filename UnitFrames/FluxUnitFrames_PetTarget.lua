-- UnitFrames/FluxUnitFrames_PetTarget.lua
-- Minimal vertical HP bar for the pet's target (pettarget), no text.
local addonName, ns = ...
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
-- Asymmetric insets: tight to left border; a bit more room on other sides for corner art
local BAR_INSET_LEFT = 1
local BAR_INSET_RIGHT = 3
local BAR_INSET_TOP = 3
local BAR_INSET_BOTTOM = 3
local FALLBACK_PET_HEIGHT = 50
local TEXTURE_BAR = "Interface\\TargetingFrame\\UI-StatusBar"
local TEXTURE_BG = "Interface\\Buttons\\WHITE8X8"

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

local function GetHealthValues(unit)
    if API and API.SafeUnitHealth and API.SafeUnitHealthMax then
        return API.SafeUnitHealth(unit), API.SafeUnitHealthMax(unit)
    end
    return UnitHealth(unit), UnitHealthMax(unit)
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
    frame:SetAttribute("unit", "pettarget")
    frame.unit = "pettarget"
    frame:EnableMouse(true)

    local barW = GetPetTargetBarWidth()
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
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", BAR_INSET_LEFT, -BAR_INSET_TOP)
    bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BAR_INSET_RIGHT, BAR_INSET_BOTTOM)
    bar:SetStatusBarTexture(TEXTURE_BAR)
    local barTex = bar:GetStatusBarTexture()
    barTex:SetHorizTile(false)
    barTex:SetVertTile(false)
    -- UI-StatusBar is authored for horizontal fill; rotate UVs for vertical bottom-to-top growth
    barTex:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
    bar:SetOrientation("VERTICAL")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(TEXTURE_BG)
    bg:SetVertexColor(0.2, 0.2, 0.2)
    frame.HealthBar = bar

    -- TPerl-style ADD gold mouseover (inside border; above health bar)
    frame.mouseoverHighlight = UF.CreateMouseoverHighlight(frame, { left = 3, top = 3, right = 3, bottom = 3, outH = 0, outV = 0 }, 11)

    local function UpdateHealth()
        if not UnitExists("pettarget") then
            return
        end
        local cur, maxH = GetHealthValues("pettarget")
        bar:SetMinMaxValues(0, maxH)
        bar:SetValue(cur)
        if not UnitIsConnected("pettarget") then
            bar:SetStatusBarColor(0.5, 0.5, 0.5)
        else
            bar:SetStatusBarColor(0, 1, 0)
        end
    end

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

        local h = ns.PetFrame:GetHeight()
        if h and h > 0 then
            frame:SetHeight(h)
        end
        if UF and UF.ApplyEmulatedHorizontalSqueezeForFrame then
            UF.ApplyEmulatedHorizontalSqueezeForFrame(frame)
        else
            frame:SetWidth(GetPetTargetBarWidth())
        end

        if frame:GetParent() ~= ns.PetFrame then
            frame:SetParent(ns.PetFrame)
            frame:SetFrameLevel(ns.PetFrame:GetFrameLevel() + 5)
        end

        local anchor = ns.PetFrame.outerBorderFrame or ns.PetFrame.PortraitFrame or ns.PetFrame
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", ANCHOR_GAP, 0)
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
        C_Timer.After(0.5, function()
            FluxUnitFrames_ApplyRuntimePetTarget(wantFlux)
        end)
        return
    end

    if wantFlux then
        if not ns.PetTargetFrame then
            petTargetFrameInitialized = false
            InitializePetTargetFrame()
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
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if petTargetFrameInitialized then
            return
        end
        if ns.PetFrame then
            InitializePetTargetFrame()
        elseif not loader._initWatcher then
            loader._initWatcher = CreateFrame("Frame")
        end

        if not petTargetFrameInitialized then
            local watcher = loader._initWatcher
            if watcher:GetScript("OnUpdate") then
                return
            end
            local checkCount = 0
            local MAX_CHECKS = 20
            watcher:Hide()
            watcher:SetScript("OnUpdate", function(w)
                checkCount = checkCount + 1
                if ns.PetFrame then
                    w:SetScript("OnUpdate", nil)
                    InitializePetTargetFrame()
                elseif checkCount >= MAX_CHECKS then
                    w:SetScript("OnUpdate", nil)
                    InitializePetTargetFrame()
                end
            end)
            watcher:Show()
        end
    end
end)

