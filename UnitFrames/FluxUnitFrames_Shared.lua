-- UnitFrames/FluxUnitFrames_Shared.lua
local addonName, ns = ...
ns.UnitFrames = ns.UnitFrames or {}
local UF = ns.UnitFrames

-- Preserve the existing samples, but wake at their deadlines instead of every
-- rendered frame. A shared OnUpdate remains available for timer-less clients.
do
local POLL_HEALTH_INTERVAL = 0.2
local POLL_THREAT_INTERVAL = 0.5
UF_UnitFramePollFrame = CreateFrame("Frame")
UF_UnitFramePollFrame:Hide()
local pollHealthAcc = 0
local pollThreatAcc = 0
local pollHealthUnits = {}
local pollThreatUnits = {}
local pollThreatArmed = true -- OOC: skip threat walk; re-arm in combat
local pollHealthTimer, pollThreatTimer
local SyncPollFrameVisibility

local function PollFrameHasWork()
    if next(pollHealthUnits) ~= nil then
        return true
    end
    if pollThreatArmed and next(pollThreatUnits) ~= nil then
        return true
    end
    return false
end

-- Midnight: canaccessvalue can be true for secret combat numbers, but comparing
-- them under addon taint errors. Only plain numbers may be cached/compared.
local function PollValueUnusable(v)
    if v == nil then
        return true
    end
    local api = ns.API
    if api then
        if api.IsSecretValue and api.IsSecretValue(v) then
            return true
        end
        if api.CanAccessValue and not api.CanAccessValue(v) then
            return true
        end
    elseif issecretvalue and issecretvalue(v) then
        return true
    end
    return false
end

local function SafePollNumber(v)
    if PollValueUnusable(v) then
        return nil
    end
    local ok, n = pcall(tonumber, v)
    if not ok or n == nil or PollValueUnusable(n) then
        return nil
    end
    if type(n) ~= "number" then
        return nil
    end
    return n
end

local function PollHealthUnchanged(frame, unit)
    if not frame or not unit then return false end
    local api = ns.API
    local health = (api and api.SafeUnitHealth and api.SafeUnitHealth(unit)) or UnitHealth(unit)
    local maxH = (api and api.SafeUnitHealthMax and api.SafeUnitHealthMax(unit)) or UnitHealthMax(unit)
    local h = SafePollNumber(health)
    local m = SafePollNumber(maxH)
    -- Secret / non-numeric: always update; never keep secrets on the frame cache.
    if h == nil or m == nil then
        frame._fluxPollHealth = nil
        frame._fluxPollHealthMax = nil
        return false
    end
    if PollValueUnusable(frame._fluxPollHealth) or PollValueUnusable(frame._fluxPollHealthMax) then
        frame._fluxPollHealth = h
        frame._fluxPollHealthMax = m
        return false
    end
    -- Both samples and cached values passed the secret/access guards above.
    -- Compare plain values directly instead of allocating a closure every poll.
    if frame._fluxPollHealth == h and frame._fluxPollHealthMax == m then
        return true
    end
    frame._fluxPollHealth = h
    frame._fluxPollHealthMax = m
    return false
end

local function PollPowerUnchanged(frame, unit)
    if not frame or not unit then return false end
    local api = ns.API
    local powerType = UnitPowerType and UnitPowerType(unit) or 0
    local power = (api and api.SafeUnitPower and api.SafeUnitPower(unit, powerType)) or UnitPower(unit, powerType)
    local maxP = (api and api.SafeUnitPowerMax and api.SafeUnitPowerMax(unit, powerType)) or UnitPowerMax(unit, powerType)
    local p = SafePollNumber(power)
    local m = SafePollNumber(maxP)
    if p == nil or m == nil or PollValueUnusable(powerType) then
        frame._fluxPollPower = nil
        frame._fluxPollPowerMax = nil
        frame._fluxPollPowerType = nil
        return false
    end
    if PollValueUnusable(frame._fluxPollPower) or PollValueUnusable(frame._fluxPollPowerMax)
        or PollValueUnusable(frame._fluxPollPowerType) then
        frame._fluxPollPower = p
        frame._fluxPollPowerMax = m
        frame._fluxPollPowerType = powerType
        return false
    end
    if frame._fluxPollPower == p and frame._fluxPollPowerMax == m and frame._fluxPollPowerType == powerType then
        return true
    end
    frame._fluxPollPower = p
    frame._fluxPollPowerMax = m
    frame._fluxPollPowerType = powerType
    return false
end

function UF.RegisterUnitFramePoll(frame, opts)
    if not frame or not frame.unit then return end
    opts = opts or {}
    local unit = frame.unit
    if opts.health or opts.power then
        pollHealthUnits[unit] = frame
    end
    if opts.threat then
        pollThreatUnits[unit] = frame
    end
    SyncPollFrameVisibility()
end

function UF.UnregisterUnitFramePoll(unit)
    if not unit then return end
    pollHealthUnits[unit] = nil
    pollThreatUnits[unit] = nil
    SyncPollFrameVisibility()
end

function FluxUI_GetUnitFramePollStats()
    local healthUnits, threatUnits = 0, 0
    for _ in pairs(pollHealthUnits) do
        healthUnits = healthUnits + 1
    end
    for _ in pairs(pollThreatUnits) do
        threatUnits = threatUnits + 1
    end
    return {
        healthUnits = healthUnits,
        threatUnits = threatUnits,
        active = PollFrameHasWork(),
        threatArmed = pollThreatArmed,
        healthTimer = pollHealthTimer ~= nil,
        threatTimer = pollThreatTimer ~= nil,
    }
end

local function SetThreatPollArmed(armed)
    pollThreatArmed = armed and true or false
    if not pollThreatArmed then
        pollThreatAcc = 0
    end
    SyncPollFrameVisibility()
end

-- Threat poll only while player in combat (UpdateThreatBar OOC early-outs anyway).
do
    local threatArmFrame = CreateFrame("Frame")
    threatArmFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    threatArmFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    threatArmFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    threatArmFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            SetThreatPollArmed(true)
        elseif event == "PLAYER_REGEN_ENABLED" then
            SetThreatPollArmed(false)
        else
            SetThreatPollArmed(InCombatLockdown and InCombatLockdown())
        end
    end)
    pollThreatArmed = (InCombatLockdown and InCombatLockdown()) and true or false
end

local function PollHealthUnits()
    for unit, self in pairs(pollHealthUnits) do
        if unit == "player" then
            if self.Health and not PollHealthUnchanged(self, self.unit) then
                UF.UpdateHealth(self, self.unit)
            end
            if self.Power and not PollPowerUnchanged(self, self.unit) then
                UF.UpdatePower(self, self.unit)
                if self.AdditionalPower then
                    UF.UpdateAdditionalPower(self, self.unit)
                end
            end
        elseif unit == "target" or unit == "focus" then
            if UF.SyncWatchedUnitFrameVisibility then
                UF.SyncWatchedUnitFrameVisibility(self)
            end
        elseif unit == "targettarget" or unit == "focustarget" then
            local shown = UF.SyncWatchedUnitFrameVisibility and UF.SyncWatchedUnitFrameVisibility(self)
            if shown and self.Health then
                if not PollHealthUnchanged(self, unit) then
                    UF.UpdateHealth(self, unit)
                end
                if self.Power and not PollPowerUnchanged(self, unit) then
                    UF.UpdatePower(self, unit)
                end
                if self.AdditionalPower then
                    UF.UpdateAdditionalPower(self, unit)
                end
                local name = UnitName and UnitName(unit)
                local api = ns.API
                if api and api.SafeAccessibleString then
                    name = api.SafeAccessibleString(name)
                end
                if self._fluxPollTotName ~= name then
                    self._fluxPollTotName = name
                    if self.UpdateOuterBorder then
                        self:UpdateOuterBorder()
                    end
                end
            else
                self._fluxPollTotName = nil
            end
        end
    end
end

local function PollThreatUnits()
    if pollThreatArmed then
        for _, self in pairs(pollThreatUnits) do
            if UF.UpdateThreatBar then
                UF.UpdateThreatBar(self)
            end
        end
    end
end

SyncPollFrameVisibility = function()
    local timer = ns.Flux and ns.Flux.Timer
    local newTicker = timer and timer.NewTicker or (C_Timer and C_Timer.NewTicker)
    if newTicker then
        if next(pollHealthUnits) then
            if not pollHealthTimer then
                pollHealthTimer = newTicker(POLL_HEALTH_INTERVAL, PollHealthUnits)
            end
        elseif pollHealthTimer then
            pollHealthTimer:Cancel()
            pollHealthTimer = nil
        end
        if pollThreatArmed and next(pollThreatUnits) then
            if not pollThreatTimer then
                pollThreatTimer = newTicker(POLL_THREAT_INTERVAL, PollThreatUnits)
            end
        elseif pollThreatTimer then
            pollThreatTimer:Cancel()
            pollThreatTimer = nil
        end
        UF_UnitFramePollFrame:Hide()
    elseif PollFrameHasWork() then
        UF_UnitFramePollFrame:Show()
    else
        pollHealthAcc = 0
        pollThreatAcc = 0
        UF_UnitFramePollFrame:Hide()
    end
end

UF_UnitFramePollFrame:SetScript("OnUpdate", function(_, elapsed)
    local el = elapsed or 0
    if next(pollHealthUnits) then
        pollHealthAcc = pollHealthAcc + el
        if pollHealthAcc >= POLL_HEALTH_INTERVAL then
            pollHealthAcc = 0
            PollHealthUnits()
        end
    else
        pollHealthAcc = 0
    end
    if pollThreatArmed and next(pollThreatUnits) then
        pollThreatAcc = pollThreatAcc + el
        if pollThreatAcc >= POLL_THREAT_INTERVAL then
            pollThreatAcc = 0
            PollThreatUnits()
        end
    else
        pollThreatAcc = 0
    end
end)
end

-- Replaced by UnitFrames/FluxUnitFrames_BigDebuffs.lua when that module loads (optional BigDebuffs).
function UF.SyncBigDebuffsFrameLevelForUnitFrame() end

-- Local copy of FluxAPI for speed
local API = ns.API
local Border = ns.Border

local function UnitDisplayName(unit, showRealm)
    local PN = ns.Flux and ns.Flux.PlayerName
    if PN and PN.GetDisplayName then
        local name = PN.GetDisplayName(unit, showRealm)
        if API and API.SafeAccessibleString then
            name = API.SafeAccessibleString(name)
        end
        if name and name ~= "" then
            return name
        end
    end
    local raw = UnitName(unit)
    if API and API.SafeAccessibleString then
        raw = API.SafeAccessibleString(raw)
    end
    return raw
end

local function UnknownObjectName()
    local s = rawget(_G, "UNKNOWNOBJECT")
    if API and API.SafeAccessibleString then
        s = API.SafeAccessibleString(s)
    end
    return s
end

local function UnitExistsPlain(unit)
    if not unit then
        return false
    end
    if API and API.UnitExistsSafe then
        return API.UnitExistsSafe(unit) and true or false
    end
    if not UnitExists then
        return false
    end
    local ok, exists = pcall(UnitExists, unit)
    return ok and exists and true or false
end

local function FluxCannotShowHideInCombat()
    local cap = ns.Flux and ns.Flux.Cap
    return cap and cap.hasRestrictedClosures == false
end

--- True when the token is a real unit. Accessible UNKNOWNOBJECT is treated as missing.
--- Secret Midnight names still count as resolved (UnitExists, name not readable).
function UF.UnitTokenIsResolved(unit)
    if not unit or not UnitExistsPlain(unit) then
        return false
    end
    local name = UnitDisplayName(unit)
    local unknown = UnknownObjectName()
    if name and unknown and name == unknown then
        return false
    end
    return true
end

local function NestedParentUnit(unit)
    if unit == "targettarget" then
        return "target"
    end
    if unit == "focustarget" then
        return "focus"
    end
    if unit == "pettarget" then
        return "pet"
    end
    return nil
end

local function ParentIsAliveForTot(unit)
    if not unit then
        return false
    end
    local raw = UnitHealth and UnitHealth(unit)
    if API and API.IsSecretValue and API.IsSecretValue(raw) then
        return true
    end
    local hp
    if API and API.SafeGetNumber then
        hp = API.SafeGetNumber(raw, 1)
    else
        hp = tonumber(raw) or 1
    end
    return hp > 0
end

local function WatchWouldShowUnit(unit)
    if not unit then
        return false
    end
    if UnitExistsPlain(unit) then
        return true
    end
    if UnitIsVisible then
        local ok, vis = pcall(UnitIsVisible, unit)
        if ok and vis then
            return true
        end
    end
    return false
end

function UF.ShouldShowWatchedUnitFrame(frame)
    if not frame then
        return false
    end
    if frame._fluxUnitWatchSuspended or frame._fluxPetUnitWatchSuspended
        or frame._fluxPetTargetUnitWatchSuspended then
        return false
    end
    local unit = frame.unit
    if not unit then
        return false
    end
    if unit == "targettarget" or unit == "focustarget" or unit == "pettarget" then
        local parent = NestedParentUnit(unit)
        if not UnitExistsPlain(parent) or not UF.UnitTokenIsResolved(unit) then
            return false
        end
        if unit ~= "pettarget" then
            if not ParentIsAliveForTot(parent) then
                return false
            end
        end
        return true
    end
    if unit == "target" or unit == "focus" or unit == "pet" then
        return UF.UnitTokenIsResolved(unit)
    end
    return UnitExistsPlain(unit)
end

local function SetWatchedFrameClickable(frame, enabled)
    -- EnableMouse on a SecureUnitButton is protected. pcall still reports
    -- ADDON_ACTION_BLOCKED, including while Edit Mode's panel-show attribute
    -- handler is on the stack and InCombatLockdown() is still false.
    -- The exists driver hides the button in combat. Mouse updates wait one
    -- frame, then skip lockdown, a hidden button, and an unchanged state.
    -- Helpers stay inside this function: the file chunk is at Lua's 200-local cap.
    if not frame then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    if frame.IsShown and not frame:IsShown() then
        return
    end
    enabled = enabled and true or false
    local target = frame.outerBorderFrame or frame
    local function MouseAlready(want)
        if target._fluxMouseEnabled == want then
            return true
        end
        if target.IsMouseEnabled then
            local ok, current = pcall(target.IsMouseEnabled, target)
            if ok and (current and true or false) == want then
                target._fluxMouseEnabled = want
                return true
            end
        end
        return false
    end
    target._fluxMouseWanted = enabled
    if target._fluxMousePending then
        return
    end
    if MouseAlready(enabled) then
        return
    end
    if not (C_Timer and C_Timer.After) then
        return
    end
    target._fluxMousePending = true
    C_Timer.After(0, function()
        target._fluxMousePending = nil
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        if frame.IsShown and not frame:IsShown() then
            return
        end
        local want = target._fluxMouseWanted
        if MouseAlready(want) then
            return
        end
        target._fluxMouseEnabled = want
        pcall(function()
            target:EnableMouse(want)
            if target.SetMouseClickEnabled then
                target:SetMouseClickEnabled(want)
            end
        end)
    end)
end

local function SetWatchedFrameAlpha(frame, alpha)
    if frame and frame.SetAlpha then
        pcall(frame.SetAlpha, frame, alpha)
    end
end

local function SetWatchedSeparatorShown(frame, shown)
    if frame and frame.SeparatorContainer then
        frame.SeparatorContainer:SetShown(shown and true or false)
    end
end

local function SetWatchedAtlasShown(frame, shown)
    if frame and frame.atlasBorderFrame then
        frame.atlasBorderFrame:SetShown(shown and true or false)
    end
end

local function HideEmptyUnitPortrait(self)
    if not self then
        return
    end
    if self.Portrait then
        local portrait = self.Portrait
        portrait._fluxQuestionMark = nil
        -- Missing watched units are checked at 5Hz. A successfully emptied
        -- Flux-owned model needs no further ClearModel until it is painted or
        -- shown again. Failed clears stay retryable; replacement models start
        -- without this flag. Do not retain an invisible, animating model.
        if not portrait._fluxEmptyCleared or (portrait.IsShown and portrait:IsShown()) then
            local ok = pcall(function()
                if portrait.SetKeepModelOnHide then
                    portrait:SetKeepModelOnHide(false)
                end
                if portrait.ClearModel then
                    portrait:ClearModel()
                end
            end)
            portrait._fluxEmptyCleared = ok or nil
        end
        portrait:Hide()
    end
    if self.Portrait2D then
        self.Portrait2D:Hide()
    end
end

function UF.HideEmptyUnitPortrait(self)
    HideEmptyUnitPortrait(self)
end

local function ApplyWatchedUnitChrome(frame, want)
    SetWatchedSeparatorShown(frame, want)
    SetWatchedAtlasShown(frame, want)
    if not want then
        HideEmptyUnitPortrait(frame)
        return
    end
    -- Poll can fade a watched frame back in without a portrait event.
    if UF.UpdatePortrait then
        local p3 = frame.Portrait
        local p2 = frame.Portrait2D
        if not ((p3 and p3.IsShown and p3:IsShown()) or (p2 and p2.IsShown and p2:IsShown())) then
            UF.UpdatePortrait(frame, frame.unit)
        end
    end
end

--- Empty-target outline: on iff Flux target is active, the option is on, and there is no resolved target.
function UF.SyncTargetPlaceholderVisibility(frame)
    frame = frame or ns.TargetFrame
    if not frame or not frame.placeholderBorder then
        return
    end
    local ph = frame.placeholderBorder
    if frame._fluxUnitWatchSuspended then
        ph:Hide()
        return
    end
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux("target") then
        ph:Hide()
        return
    end
    if FluxUnitFrames_ShouldShowTargetNoTargetPlaceholder
        and not FluxUnitFrames_ShouldShowTargetNoTargetPlaceholder() then
        ph:Hide()
        return
    end
    local showPlaceholder = not UF.ShouldShowWatchedUnitFrame(frame)
    if showPlaceholder then
        ph:Show()
    else
        ph:Hide()
    end
end

--- Pet / pet target: [@unit,exists] owns Show/Hide, including mid-combat.
--- Never Show() these from Lua, and never leave them shown at alpha 0.
--- Forever cannot Show/Hide in combat: fade only while the button is already
--- shown, then the visibility fallback real-hides or shows on regen.
local function SyncPetExistenceFrame(frame, want, locked)
    local shown = frame.IsShown and frame:IsShown() and true or false
    if FluxCannotShowHideInCombat() and locked then
        if shown then
            SetWatchedFrameAlpha(frame, want and 1 or 0)
            ApplyWatchedUnitChrome(frame, want)
        else
            -- Hidden before this combat. Do not Show — that is ADDON_ACTION_BLOCKED.
            SetWatchedFrameAlpha(frame, 1)
            ApplyWatchedUnitChrome(frame, false)
        end
        return
    end
    if not (FluxCannotShowHideInCombat() and shown and not want) then
        -- Leave a Forever combat fade at alpha 0 until the fallback Hides and
        -- restores alpha 1. Raising alpha here flashes the empty frame.
        SetWatchedFrameAlpha(frame, 1)
    end
    if not locked then
        SetWatchedFrameClickable(frame, want and shown)
    end
    -- UIParent chrome must not stay up after the button is hidden.
    ApplyWatchedUnitChrome(frame, want and shown)
end

--- Combat-safe show/hide for target / ToT / focus / pet watched frames.
--- SecureUnitButton Show/Hide is protected in combat (ADDON_ACTION_BLOCKED even
--- under pcall). RegisterUnitWatch owns shown-state; combat hide is alpha.
--- Forever also cannot Show/Hide in combat, so those stay shown and use alpha.
function UF.SyncWatchedUnitFrameVisibility(frame)
    if not frame or not frame.unit then
        return false
    end
    local unit = frame.unit
    if unit ~= "target" and unit ~= "focus" and unit ~= "targettarget"
        and unit ~= "focustarget" and unit ~= "pet" and unit ~= "pettarget" then
        return false
    end
    local want = UF.ShouldShowWatchedUnitFrame(frame)
    local locked = InCombatLockdown and InCombatLockdown()
    if unit == "pet" or unit == "pettarget" then
        SyncPetExistenceFrame(frame, want, locked)
        return want
    end
    if FluxCannotShowHideInCombat() then
        if not locked then
            if frame.IsShown and not frame:IsShown() then
                pcall(frame.Show, frame)
            end
            SetWatchedFrameClickable(frame, want)
        end
        SetWatchedFrameAlpha(frame, want and 1 or 0)
        ApplyWatchedUnitChrome(frame, want)
        if unit == "target" then
            UF.SyncTargetPlaceholderVisibility(frame)
        end
        return want
    end

    local watchShows = WatchWouldShowUnit(unit)
    if not locked then
        if want then
            if frame.IsShown and not frame:IsShown() then
                pcall(frame.Show, frame)
            end
            SetWatchedFrameAlpha(frame, 1)
        elseif watchShows then
            -- RegisterUnitWatch will keep this shown (UnitExists). Fade instead of fighting it.
            if frame.IsShown and not frame:IsShown() then
                pcall(frame.Show, frame)
            end
            SetWatchedFrameAlpha(frame, 0)
        else
            if frame.IsShown and frame:IsShown() then
                pcall(frame.Hide, frame)
            end
            SetWatchedFrameAlpha(frame, 1)
        end
        SetWatchedFrameClickable(frame, want)
        ApplyWatchedUnitChrome(frame, want)
        if unit == "target" then
            UF.SyncTargetPlaceholderVisibility(frame)
        end
        return want
    end

    -- Combat: Show/Hide on SecureUnitButton is protected. pcall still fires
    -- ADDON_ACTION_BLOCKED (UNKNOWN()). RegisterUnitWatch owns shown-state.
    if want then
        SetWatchedFrameAlpha(frame, 1)
        ApplyWatchedUnitChrome(frame, true)
    elseif frame.IsShown and frame:IsShown() then
        SetWatchedFrameAlpha(frame, 0)
        ApplyWatchedUnitChrome(frame, false)
    else
        SetWatchedFrameAlpha(frame, 1)
        ApplyWatchedUnitChrome(frame, false)
    end
    if unit == "target" then
        UF.SyncTargetPlaceholderVisibility(frame)
    end
    return want
end

local function SyncRelatedWatchedFrames(self)
    UF.SyncWatchedUnitFrameVisibility(self)
    if not self then
        return
    end
    if self.unit == "target" then
        UF.SyncWatchedUnitFrameVisibility(ns.TargetOfTargetFrame)
    elseif self.unit == "focus" then
        UF.SyncWatchedUnitFrameVisibility(ns.FocusTargetFrame)
    elseif self.unit == "pet" then
        UF.SyncWatchedUnitFrameVisibility(ns.PetTargetFrame)
    end
end

--- Accessible name for painting. nil + resolved=false: missing unit (do not write Unknown).
--- nil + resolved=true: secret name (keep last text).
local function UnitFrameResolvedDisplayName(unit)
    if not UF.UnitTokenIsResolved(unit) then
        return nil, false
    end
    local name = UnitDisplayName(unit)
    if not name or name == "" then
        return nil, true
    end
    return name, true
end

local function PaintUnitFrameNameText(self, nameText)
    if not self or not nameText then
        return nil
    end
    local unitName, resolved = UnitFrameResolvedDisplayName(self.unit)
    if unitName then
        nameText:SetText(unitName)
        self._fluxLastRealName = unitName
        return unitName
    end
    if resolved then
        return self._fluxLastRealName
    end
    return self._fluxLastRealName
end

-- Aura system loads automatically from TOC

-- Constants
local TEXTURE_BAR = "Interface\\TargetingFrame\\UI-StatusBar" -- Standard Blizzard texture
local TEXTURE_BG = "Interface\\Buttons\\WHITE8X8"
local TEXTURE_GLOW = "Interface\\TargetingFrame\\UI-StatusBar-Glow"
local HUD_HEALTH_ATLAS = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health"
local HUD_BAR_ROOT = "UI-HUD-UnitFrame-Player-PortraitOn"
local FluxPowerBarColor

-- Forever changed the artwork behind these Retail atlas names. Standalone
-- Retail fills also avoid StatusBar resetting a manually cropped sheet's UVs.
do
    local RETAIL_BAR_PATH = "Interface\\AddOns\\_FluxUI\\Media\\UnitFrames\\Retail\\"
    local RETAIL_BAR_FILES = {
        [HUD_BAR_ROOT .. "-Bar-Health"] = "Health",
        [HUD_BAR_ROOT .. "-Bar-Mana"] = "Mana",
        [HUD_BAR_ROOT .. "-Bar-Mana-Status"] = "ManaStatus",
        [HUD_BAR_ROOT .. "-Bar-Energy"] = "Energy",
        [HUD_BAR_ROOT .. "-Bar-Focus"] = "Focus",
        [HUD_BAR_ROOT .. "-Bar-Rage"] = "Rage",
        [HUD_BAR_ROOT .. "-Bar-RunicPower"] = "RunicPower",
        [HUD_BAR_ROOT .. "-ClassResource-Bar-Mana"] = "ClassResourceMana",
        [HUD_BAR_ROOT .. "-ClassResource-Bar-Energy"] = "ClassResourceEnergy",
    }

    function UF.GetHudBarTexture(atlas)
        local client = ns.Flux and ns.Flux.Client or rawget(_G, "FLUX_API")
        local file = client and client.isForever and RETAIL_BAR_FILES[atlas]
        return file and (RETAIL_BAR_PATH .. file .. ".tga") or atlas
    end
end

-- Live Midnight and Forever use the HUD unit-frame atlases. Era, Anniversary, and Mists stay on UI-StatusBar.
function UF.UsesHudUnitBars()
    local client = ns.Flux and ns.Flux.Client
    if client then
        return (client.isLiveMidnight or client.isForever) and true or false
    end
    local api = rawget(_G, "FLUX_API")
    if api then
        return (api.isLiveMidnight or api.isForever) and true or false
    end
    return false
end

local function AtlasExists(name)
    if not name or name == "" then return false end
    if UF.GetHudBarTexture(name) ~= name then return true end
    if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
    local ok, info = pcall(C_Texture.GetAtlasInfo, name)
    return ok and info ~= nil
end

local function ValueIsSecret(value)
    if value == nil then return false end
    if API.IsSecretValue and API.IsSecretValue(value) then return true end
    if API.CanAccessValue and not API.CanAccessValue(value) then return true end
    return false
end

local function PlayerDeadOrGhost(unit)
    if unit ~= "player" then return false end
    local dead, ghost = UnitIsDead(unit), UnitIsGhost(unit)
    if ValueIsSecret(dead) or ValueIsSecret(ghost) then return false end
    return (dead or ghost) and true or false
end

local function ResolvePowerInfo(powerToken, powerType)
    local info
    if PowerBarColor then
        info = PowerBarColor[powerToken] or PowerBarColor[powerType]
    end
    if not info and FluxPowerBarColor then
        info = FluxPowerBarColor[powerToken] or FluxPowerBarColor[powerType] or FluxPowerBarColor["MANA"]
    end
    return info or { r = 0, g = 0, b = 1, atlasElementName = "Mana" }
end

function UF.GetPowerPredictionColor(info)
    local function read(color)
        if color and color.GetRGBA then
            local ok, r, g, b, a = pcall(function()
                return color:GetRGBA()
            end)
            if ok and type(r) == "number" then
                return r, g, b, a or 1
            end
        end
        return nil
    end
    local r, g, b, a = read(info and info.predictionColor)
    if r then return r, g, b, a end
    r, g, b, a = read(rawget(_G, "POWERBAR_PREDICTION_COLOR_MANA"))
    if r then return r, g, b, a end
    return 0.2, 0.4, 1, 1
end

function UF.GetPowerStatusAtlas(info)
    if info and info.atlasElementName then
        local named = HUD_BAR_ROOT .. "-Bar-" .. info.atlasElementName .. "-Status"
        if AtlasExists(named) then
            return named
        end
    end
    local mana = HUD_BAR_ROOT .. "-Bar-Mana-Status"
    if AtlasExists(mana) then
        return mana
    end
    return nil
end

local function HudPowerAtlas(info, classResource, altR)
    if info and info.atlas then
        return info.atlas, false
    end
    if info and info.atlasElementName then
        local cr = (classResource and info.hasClassResourceVariant) and "-ClassResource" or ""
        return HUD_BAR_ROOT .. cr .. "-Bar-" .. info.atlasElementName, false
    end
    if altR then
        return HUD_BAR_ROOT .. "-Bar-Mana-Status", true
    end
    return HUD_BAR_ROOT .. "-Bar-Mana", false
end

local function DesaturateBarTexture(bar, deadOrGhost)
    local tex = bar and bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if not tex then return end
    if tex.SetDesaturated then
        tex:SetDesaturated(deadOrGhost and true or false)
    end
    tex:SetAlpha(deadOrGhost and 0.5 or 1)
end

--- HUD atlases are pre-colored, so a gray vertex only darkens them. Desaturate the fill.
local function SetStatusBarFillGray(bar, gray)
    if not bar then return end
    local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if tex then
        if tex.SetDesaturated then
            tex:SetDesaturated(gray and true or false)
        end
        if tex.SetAlpha then
            tex:SetAlpha(1)
        end
    end
    if gray then
        bar:SetStatusBarColor(0.5, 0.5, 0.5)
    end
end

function UF.UpdateResourceSpark(bar, sparkInfo)
    local spark = bar and bar.Spark
    if not spark then return end
    if not UF.UsesHudUnitBars() or not sparkInfo or not sparkInfo.atlas or not AtlasExists(sparkInfo.atlas) then
        spark:Hide()
        spark.isActive = false
        spark.visualInfo = nil
        return
    end
    spark.isActive = true
    spark.visualInfo = sparkInfo
    local fill = bar:GetStatusBarTexture()
    spark:ClearAllPoints()
    if fill then
        spark:SetPoint("RIGHT", fill, "RIGHT", sparkInfo.xOffset or 0, 0)
    else
        spark:SetPoint("RIGHT", bar, "LEFT", sparkInfo.xOffset or 0, 0)
    end
    spark:SetAtlas(sparkInfo.atlas, true)
    if sparkInfo.barHeight and sparkInfo.barHeight > 0 and fill then
        local okH, h = pcall(function()
            return fill:GetHeight() + 0
        end)
        if okH and type(h) == "number" and h > 0 then
            spark:SetScale(h / sparkInfo.barHeight)
        end
    end
    local show = false
    local okShow, result = pcall(function()
        local fw = fill and (fill:GetWidth() + 0) or 0
        local bw = bar:GetWidth() + 0
        if fw <= 1 or bw <= 0 then return false end
        if sparkInfo.showAtMax then return true end
        return fw < (bw - 1)
    end)
    if okShow then
        show = result and true or false
    end
    if show then
        spark:Show()
    else
        spark:Hide()
    end
end

local function EnsureResourceSpark(bar)
    if not bar or bar.Spark then return end
    local spark = bar:CreateTexture(nil, "OVERLAY", nil, 2)
    spark:SetBlendMode("ADD")
    spark:Hide()
    bar.Spark = spark
end

local function ConfigureAlpha(group, childKey, fromAlpha, toAlpha, duration, delay, smoothing)
    local anim = group:CreateAnimation("Alpha")
    anim:SetChildKey(childKey)
    anim:SetOrder(1)
    anim:SetDuration(duration)
    anim:SetFromAlpha(fromAlpha)
    anim:SetToAlpha(toAlpha)
    if delay and delay > 0 then
        anim:SetStartDelay(delay)
    end
    if smoothing then
        anim:SetSmoothing(smoothing)
    end
    return anim
end

local function ConfigureScale(group, childKey, fromX, fromY, toX, toY, duration, delay, smoothing, origin)
    local anim = group:CreateAnimation("Scale")
    anim:SetChildKey(childKey)
    anim:SetOrder(1)
    anim:SetDuration(duration)
    if delay and delay > 0 then
        anim:SetStartDelay(delay)
    end
    if smoothing then
        anim:SetSmoothing(smoothing)
    end
    if origin and anim.SetOrigin then
        anim:SetOrigin(origin, 0, 0)
    end
    if anim.SetScaleFrom and anim.SetScaleTo then
        anim:SetScaleFrom(fromX, fromY)
        anim:SetScaleTo(toX, toY)
    else
        anim:SetScale(toX, toY)
    end
    return anim
end

local function ConfigureTranslation(group, childKey, offsetX, duration, delay, smoothing)
    local anim = group:CreateAnimation("Translation")
    anim:SetChildKey(childKey)
    anim:SetOrder(1)
    anim:SetDuration(duration)
    anim:SetOffset(offsetX, 0)
    if delay and delay > 0 then
        anim:SetStartDelay(delay)
    end
    if smoothing then
        anim:SetSmoothing(smoothing)
    end
    return anim
end

local function EnsureFullResourcePulse(bar)
    if not bar or bar.FullPowerFrame or not UF.UsesHudUnitBars() then return bar and bar.FullPowerFrame end
    if not (AtlasExists("FullAlert-BigSpike") and AtlasExists("FullAlert-FrameGlow")) then
        return nil
    end

    local pulse = CreateFrame("Frame", nil, bar)
    pulse:SetAllPoints(bar)
    pulse:SetFrameLevel(bar:GetFrameLevel() + 5)
    pulse:SetAlpha(0)
    pulse.active = false

    local spike = CreateFrame("Frame", nil, pulse)
    spike:SetAllPoints(pulse)
    local big = spike:CreateTexture(nil, "OVERLAY")
    big:SetAtlas("FullAlert-BigSpike", true)
    big:SetAlpha(0)
    big:SetBlendMode("BLEND")
    big:SetPoint("RIGHT", spike, "RIGHT", 21, 0)
    spike.BigSpikeGlow = big
    local stay = spike:CreateTexture(nil, "OVERLAY")
    if AtlasExists("FullAlert-FrameGlow") then
        stay:SetAtlas("FullAlert-FrameGlow", true)
    end
    stay:SetAlpha(0)
    stay:SetBlendMode("BLEND")
    stay:SetPoint("RIGHT", spike, "RIGHT", 11, 0)
    spike.AlertSpikeStay = stay

    local spikeAnim = spike:CreateAnimationGroup()
    spikeAnim:SetToFinalAlpha(true)
    ConfigureAlpha(spikeAnim, "BigSpikeGlow", 0, 1, 0.25, 0, "IN")
    ConfigureScale(spikeAnim, "BigSpikeGlow", 0.25, 0.75, 1.4, 0.75, 0.1, 0, "NONE", "LEFT")
    ConfigureScale(spikeAnim, "BigSpikeGlow", 1, 1, 0.5, 1, 0.2, 0.2, "IN", "LEFT")
    ConfigureAlpha(spikeAnim, "BigSpikeGlow", 1, 0, 0.25, 0.3, nil)
    ConfigureAlpha(spikeAnim, "AlertSpikeStay", 0, 1, 0.25, 0, "IN")
    spike.SpikeAnim = spikeAnim

    local pulseFrame = CreateFrame("Frame", nil, pulse)
    pulseFrame:SetAllPoints(pulse)
    local yellow = pulseFrame:CreateTexture(nil, "OVERLAY")
    yellow:SetAlpha(0)
    yellow:SetBlendMode("BLEND")
    yellow:SetSize(20, 24)
    yellow:SetPoint("RIGHT", pulseFrame, "RIGHT", -1, -1)
    if AtlasExists("FullAlert-YellowCurveGlow") then
        yellow:SetAtlas("FullAlert-YellowCurveGlow")
    end
    pulseFrame.YellowGlow = yellow
    local soft = pulseFrame:CreateTexture(nil, "OVERLAY")
    soft:SetAlpha(0)
    soft:SetBlendMode("BLEND")
    soft:SetSize(20, 24)
    soft:SetPoint("RIGHT", pulseFrame, "RIGHT", -1, -1)
    if AtlasExists("FullAlert-SoftCurveGlow") then
        soft:SetAtlas("FullAlert-SoftCurveGlow")
    end
    pulseFrame.SoftGlow = soft

    local pulseAnim = pulseFrame:CreateAnimationGroup()
    pulseAnim:SetLooping("REPEAT")
    ConfigureAlpha(pulseAnim, "YellowGlow", 0, 1, 0.1, 0, nil)
    ConfigureTranslation(pulseAnim, "YellowGlow", 20, 0.5, 0, "OUT")
    ConfigureAlpha(pulseAnim, "YellowGlow", 1, 0, 0.1, 0.4, nil)
    ConfigureAlpha(pulseAnim, "SoftGlow", 0, 1, 0.1, 0, nil)
    ConfigureTranslation(pulseAnim, "SoftGlow", 20, 0.7, 0, "OUT")
    ConfigureAlpha(pulseAnim, "SoftGlow", 1, 0, 0.1, 0.6, nil)
    pulseFrame.PulseAnim = pulseAnim

    local fade = pulse:CreateAnimationGroup()
    fade:SetToFinalAlpha(true)
    local fadeAlpha = fade:CreateAnimation("Alpha")
    fadeAlpha:SetOrder(1)
    fadeAlpha:SetDuration(0.5)
    fadeAlpha:SetFromAlpha(1)
    fadeAlpha:SetToAlpha(0)
    fade:SetScript("OnFinished", function()
        if spike.SpikeAnim:IsPlaying() then
            spike.SpikeAnim:Stop()
        end
        if pulseFrame.PulseAnim:IsPlaying() then
            pulseFrame.PulseAnim:Stop()
        end
    end)
    pulse.FadeoutAnim = fade
    pulse.SpikeFrame = spike
    pulse.PulseFrame = pulseFrame

    pulse:RegisterEvent("PLAYER_REGEN_ENABLED")
    pulse:SetScript("OnEvent", function(self)
        if self.SpikeFrame.SpikeAnim:IsPlaying() or self.PulseFrame.PulseAnim:IsPlaying() then
            self.FadeoutAnim:Play()
        end
    end)

    function pulse:StartAnimIfFull(isFull)
        if isFull and UnitAffectingCombat("player") then
            if not self._shownFull then
                self._shownFull = true
                if self.FadeoutAnim:IsPlaying() then
                    self.FadeoutAnim:Stop()
                end
                self:SetAlpha(1)
                self.SpikeFrame.SpikeAnim:Play()
                if not self.PulseFrame.PulseAnim:IsPlaying() then
                    self.PulseFrame.PulseAnim:Play()
                end
            end
        else
            self._shownFull = false
            local spikePlaying = self.SpikeFrame.SpikeAnim:IsPlaying()
            local pulsePlaying = self.PulseFrame.PulseAnim:IsPlaying()
            if not self.FadeoutAnim:IsPlaying() and (spikePlaying or pulsePlaying) then
                self.FadeoutAnim:Play()
            end
        end
    end

    function pulse:RemoveAnims()
        self._shownFull = false
        self:SetAlpha(0)
        if self.PulseFrame.PulseAnim:IsPlaying() then
            self.PulseFrame.PulseAnim:Stop()
        end
        if self.SpikeFrame.SpikeAnim:IsPlaying() then
            self.SpikeFrame.SpikeAnim:Stop()
        end
    end

    bar.FullPowerFrame = pulse
    return pulse
end

function UF.SetFullResourcePulseActive(bar, active)
    if not bar then return end
    if not active or not UF.UsesHudUnitBars() then
        if bar.FullPowerFrame then
            bar.FullPowerFrame.active = false
            bar.FullPowerFrame:RemoveAnims()
        end
        return
    end
    if bar._fluxPulseFailed then return end
    if bar.FullPowerFrame then
        bar.FullPowerFrame.active = true
        return
    end
    local ok, pulse = pcall(EnsureFullResourcePulse, bar)
    if not ok then
        bar._fluxPulseFailed = true
        return
    end
    if not pulse then return end
    pulse.active = true
end

function UF.UpdateFullResourcePulse(bar, power, maxPower)
    local pulse = bar and bar.FullPowerFrame
    if not pulse or not pulse.active then return end
    local isFull
    if not ValueIsSecret(power) and not ValueIsSecret(maxPower) then
        local p = API.SafeGetNumber(power, -1)
        local m = API.SafeGetNumber(maxPower, -1)
        if p >= 0 and m > 0 then
            isFull = p >= m
        end
    end
    if isFull == nil then
        local ok, full = pcall(function()
            local fill = bar:GetStatusBarTexture()
            local fw = fill and (fill:GetWidth() + 0) or 0
            local bw = bar:GetWidth() + 0
            return bw > 1 and fw >= (bw - 1)
        end)
        isFull = ok and full and true or false
    end
    pulse:StartAnimIfFull(isFull)
end

-- Shorten the displayed fill by a readable predicted cost. Secret values keep the real fill.
function UF.PowerValueForDisplay(bar, power)
    local cost = bar and bar._fluxPredictedCost
    -- Classic draws the cost on the current fill. Only Live/Forever shorten the bar.
    if bar and not UF.UsesHudUnitBars() then
        bar._fluxPredictionShortened = false
        return power
    end
    if cost == nil or ValueIsSecret(cost) or type(cost) ~= "number" or cost <= 0 then
        if bar then bar._fluxPredictionShortened = false end
        return power
    end
    if ValueIsSecret(power) then
        bar._fluxPredictionShortened = false
        return power
    end
    local pNum = API.SafeGetNumber(power, 0)
    bar._fluxPredictionShortened = true
    if pNum <= cost then
        return 0
    end
    return pNum - cost
end

local RETAIL_POWER_TINT = {
    MANA = { 0.25, 0.5, 1.0 },
    ENERGY = { 0.95, 0.95, 0.45 },
    RAGE = { 0.95, 0.15, 0.15 },
    FOCUS = { 1.0, 0.55, 0.35 },
    RUNIC_POWER = { 0.2, 0.85, 1.0 },
    [0] = { 0.25, 0.5, 1.0 },
    [1] = { 0.95, 0.15, 0.15 },
    [2] = { 1.0, 0.55, 0.35 },
    [3] = { 0.95, 0.95, 0.45 },
    [6] = { 0.2, 0.85, 1.0 },
}

function UF.ApplyResourceBarStyle(bar, unit, powerToken, powerType, altR, altG, altB, classResource)
    if not bar then return nil end
    local info = ResolvePowerInfo(powerToken, powerType)
    bar._fluxPowerInfo = info
    local hud = UF.UsesHudUnitBars()
    local dead = PlayerDeadOrGhost(unit)
    local disconnected = unit and not UnitIsConnected(unit)
    if hud then
        EnsureResourceSpark(bar)
    end

    if hud then
        local atlas, tintAlt = HudPowerAtlas(info, classResource, altR)
        if not AtlasExists(atlas) then
            atlas = HUD_BAR_ROOT .. "-Bar-Mana"
            tintAlt = altR and true or false
        end
        if AtlasExists(atlas) then
            bar:SetStatusBarTexture(UF.GetHudBarTexture(atlas))
            bar._fluxBarAtlas = atlas
            bar._fluxHudAtlas = true
            if tintAlt and altR and not ValueIsSecret(altR) then
                bar:SetStatusBarColor(altR, altG, altB)
                bar._fluxHudVertexWhite = false
            else
                bar:SetStatusBarColor(1, 1, 1)
                bar._fluxHudVertexWhite = true
            end
            if disconnected then
                bar:SetStatusBarColor(0.5, 0.5, 0.5)
            else
                DesaturateBarTexture(bar, dead)
            end
        else
            bar._fluxBarAtlas = nil
            bar._fluxHudAtlas = false
            bar:SetStatusBarTexture(TEXTURE_BAR)
            if disconnected then
                bar:SetStatusBarColor(0.5, 0.5, 0.5)
            elseif dead then
                bar:SetStatusBarColor(0.6, 0.6, 0.6, 0.5)
            else
                bar:SetStatusBarColor(info.r or 0, info.g or 0, info.b or 1)
            end
        end
        UF.UpdateResourceSpark(bar, info.spark)
        UF.SetFullResourcePulseActive(bar, info.fullPowerAnim and true or false)
    else
        -- Classic: Live atlas only when it exists, otherwise UI-StatusBar and retail-like tints.
        bar._fluxHudAtlas = false
        local atlas = nil
        if info.atlas and AtlasExists(info.atlas) then
            atlas = info.atlas
        elseif info.atlasElementName then
            local named = HUD_BAR_ROOT .. "-Bar-" .. info.atlasElementName
            if AtlasExists(named) then
                atlas = named
            end
        end
        if atlas then
            if bar._fluxBarAtlas ~= atlas then
                bar:SetStatusBarTexture(atlas)
                bar._fluxBarAtlas = atlas
            end
            bar:SetStatusBarColor(1, 1, 1)
            if disconnected then
                bar:SetStatusBarColor(0.5, 0.5, 0.5)
            end
        else
            if bar._fluxBarAtlas ~= nil or not bar._fluxClassicTex then
                bar:SetStatusBarTexture(TEXTURE_BAR)
                bar._fluxBarAtlas = nil
                bar._fluxClassicTex = true
            end
            local tint = RETAIL_POWER_TINT[powerToken] or RETAIL_POWER_TINT[powerType]
            if disconnected then
                bar:SetStatusBarColor(0.5, 0.5, 0.5)
            elseif dead then
                bar:SetStatusBarColor(0.6, 0.6, 0.6, 0.5)
            elseif tint then
                bar:SetStatusBarColor(tint[1], tint[2], tint[3])
            else
                bar:SetStatusBarColor(info.r or 0, info.g or 0, info.b or 1, 1)
            end
        end
    end

    local PCO = ns.PowerCostOverlay
    if PCO and PCO.ApplySegmentArt then
        PCO.ApplySegmentArt(bar)
    end
    return info
end

function UF.RefreshResourceConnection(bar, unit)
    if not bar or not unit then return end
    local dead = PlayerDeadOrGhost(unit)
    local disconnected = not UnitIsConnected(unit)
    if disconnected then
        bar:SetStatusBarColor(0.5, 0.5, 0.5)
        return
    end
    if bar._fluxHudAtlas then
        if bar._fluxHudVertexWhite then
            bar:SetStatusBarColor(1, 1, 1)
        end
        DesaturateBarTexture(bar, dead)
    elseif dead then
        bar:SetStatusBarColor(0.6, 0.6, 0.6, 0.5)
    end
end

function UF.ApplyStaggerBarStyle(bar, tier, r, g, b)
    if not bar then return end
    EnsureResourceSpark(bar)
    local stag = PowerBarColor and PowerBarColor.STAGGER
    local entry = stag and stag[tier]
    if UF.UsesHudUnitBars() and entry and entry.atlas and AtlasExists(entry.atlas) then
        if bar._fluxBarAtlas ~= entry.atlas then
            bar:SetStatusBarTexture(entry.atlas)
            bar._fluxBarAtlas = entry.atlas
            bar._fluxHudAtlas = true
        end
        bar:SetStatusBarColor(1, 1, 1)
        UF.UpdateResourceSpark(bar, stag.spark)
    else
        if bar._fluxBarAtlas ~= nil or bar._fluxHudAtlas then
            bar:SetStatusBarTexture(TEXTURE_BAR)
        end
        bar._fluxBarAtlas = nil
        bar._fluxHudAtlas = false
        bar:SetStatusBarColor(r, g, b)
        UF.UpdateResourceSpark(bar, nil)
    end
    UF.SetFullResourcePulseActive(bar, false)
end

local function ApplyHealthBarArt(health)
    if not health then return end
    local hud = UF.UsesHudUnitBars() and AtlasExists(HUD_HEALTH_ATLAS)
    local loss = health.AnimatedLossBar
    if hud then
        if not health._fluxHudHealth then
            health:SetStatusBarTexture(UF.GetHudBarTexture(HUD_HEALTH_ATLAS))
            health._fluxHudHealth = true
        end
        health:SetStatusBarColor(1, 1, 1)
        if loss then
            if not loss._fluxHudHealth then
                loss:SetStatusBarTexture(UF.GetHudBarTexture(HUD_HEALTH_ATLAS))
                loss._fluxHudHealth = true
            end
            loss:SetStatusBarColor(1, 0, 0, 1)
        end
    else
        if health._fluxHudHealth ~= false then
            health:SetStatusBarTexture(TEXTURE_BAR)
            health._fluxHudHealth = false
        end
        if loss and loss._fluxHudHealth ~= false then
            loss:SetStatusBarTexture(TEXTURE_BAR)
            loss._fluxHudHealth = false
            loss:SetStatusBarColor(1, 0, 0, 1)
        end
    end
end

-- Blizzard raid-frame absorb assets (CompactUnitFrame / UnitFrame templates, wow-ui-source-live)
local ATLAS_RAID_SHIELD_FILL = "raidframe-shield-fill"
local ATLAS_RAID_SHIELD_OVERLAY = "RaidFrame-Shield-Overlay"
local ATLAS_RAID_ABSORB_FILL = "raidframe-absorb-fill"
local ATLAS_RAID_ABSORB_OVERLAY = "RaidFrame-Absorb-Overlay"
local ATLAS_RAID_SHIELD_OVERSHIELD = "RaidFrame-Shield-Overshield"
local ATLAS_RAID_ABSORB_OVERABSORB = "RaidFrame-Absorb-Overabsorb"
local FILE_ABSORB_EDGE = "Interface\\RaidFrame\\Absorb-Edge"
local SHIELD_OVERLAY_TILE = 32
local ABSORB_OVERLAY_TILE = 32

--- HP/power text layout and pet name under the player name only when Flux pet frame is enabled.
--- If the pet uses Blizzard's frame (Flux pet off), keep solo-style bars/text like there is no pet.
local function PlayerUnitUsesFluxPetLayout()
    if not UnitExists("pet") then
        return false
    end
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux("pet") then
        return false
    end
    return true
end

--- Pet happiness icon on the player pet name line.
--- Nested so these locals do not count toward the file's 200-local cap.
--- Forever uses C_PetInfo.GetPetHappiness; classic uses GetPetHappiness.
--- Retail has neither. A nil result means this client or this pet has no happiness.
function UF.LayoutPetHappinessIcon(self)
    local impl = UF._layoutPetHappiness
    if not impl then
        local PET_HAPPINESS_FILE = "Interface\\PetPaperDollFrame\\UI-PetHappiness"
        local PET_HAPPINESS_ATLAS = {
            [1] = "UI-PetMad",
            [2] = "UI-PetNeutral",
            [3] = "UI-PetHappiness",
        }
        local PET_HAPPINESS_COORD = {
            [1] = { 0.375, 0.5625, 0, 0.359375 },
            [2] = { 0.1875, 0.375, 0, 0.359375 },
            [3] = { 0, 0.1875, 0, 0.359375 },
        }
        local petHappinessQuery -- function, or false when this client has no API
        local petHappinessUsesAtlas

        local function PetHappinessQuery()
            if petHappinessQuery ~= nil then
                return petHappinessQuery ~= false and petHappinessQuery or nil
            end
            if C_PetInfo and type(C_PetInfo.GetPetHappiness) == "function" then
                petHappinessQuery = function()
                    return C_PetInfo.GetPetHappiness()
                end
            elseif type(GetPetHappiness) == "function" then
                petHappinessQuery = GetPetHappiness
            else
                petHappinessQuery = false
            end
            return petHappinessQuery ~= false and petHappinessQuery or nil
        end

        local function PetHappinessUsesAtlas()
            if petHappinessUsesAtlas ~= nil then
                return petHappinessUsesAtlas
            end
            petHappinessUsesAtlas = AtlasExists("UI-PetHappiness")
            return petHappinessUsesAtlas
        end

        --- happiness, damagePercentage, loyaltyRate. Nil happiness hides the icon.
        local function ReadPetHappiness()
            local query = PetHappinessQuery()
            if not query then
                return nil
            end
            local ok, happiness, damagePercentage, loyaltyRate = pcall(query)
            if not ok or ValueIsSecret(happiness) or happiness == nil then
                return nil
            end
            local level = API.SafeGetNumber(happiness, -1)
            if level ~= 1 and level ~= 2 and level ~= 3 then
                return nil
            end
            if not HasPetUI then
                return nil
            end
            local hasOk, _, isHunterPet = pcall(HasPetUI)
            if not hasOk or ValueIsSecret(isHunterPet) or not isHunterPet then
                return nil
            end
            return level, API.SafeGetNumber(damagePercentage, 0), API.SafeGetNumber(loyaltyRate, 0)
        end

        local function PetHappinessDietLine()
            if not (C_PetInfo and type(C_PetInfo.GetPetFoodTypes) == "function") then
                return nil
            end
            if not PET_DIET_TEMPLATE then
                return nil
            end
            local ok, line = pcall(function()
                local diet = C_PetInfo.GetPetFoodTypes()
                if type(diet) ~= "table" or #diet == 0 then
                    return PET_DIET_TEMPLATE:format(NONE or "")
                end
                return PET_DIET_TEMPLATE:format(table.concat(diet, PET_FOOD_DELIMIT or ", "))
            end)
            if ok and type(line) == "string" and line ~= "" then
                return line
            end
            return nil
        end

        local function PetHappinessIcon_OnEnter(icon)
            if not GameTooltip or not icon.tooltip then
                return
            end
            GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
            GameTooltip:SetText(icon.tooltip)
            if icon.tooltipDamage then
                GameTooltip:AddLine(icon.tooltipDamage, 1, 1, 1)
            end
            if icon.tooltipLoyalty then
                GameTooltip:AddLine(icon.tooltipLoyalty, 1, 1, 1)
            end
            if icon.tooltipDiet then
                GameTooltip:AddLine(icon.tooltipDiet, 1, 1, 1)
            end
            GameTooltip:Show()
        end

        local function PetHappinessIcon_OnLeave()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end

        local function ApplyPetHappinessArt(tex, happiness)
            if PetHappinessUsesAtlas() and tex.SetAtlas then
                local ok = pcall(tex.SetAtlas, tex, PET_HAPPINESS_ATLAS[happiness])
                if ok then
                    return
                end
            end
            tex:SetTexture(PET_HAPPINESS_FILE)
            local coord = PET_HAPPINESS_COORD[happiness]
            tex:SetTexCoord(coord[1], coord[2], coord[3], coord[4])
        end

        local function EnsurePetHappinessIcon(frame)
            if frame.petHappinessIcon then
                return frame.petHappinessIcon
            end
            local parent = frame.outerBorderFrame
            if not parent then
                return nil
            end
            local icon = CreateFrame("Frame", nil, parent)
            icon:SetSize(16, 15)
            icon:SetFrameLevel(parent:GetFrameLevel() + 24)
            icon:EnableMouse(true)
            icon:Hide()
            local tex = icon:CreateTexture(nil, "OVERLAY")
            tex:SetAllPoints(icon)
            icon.texture = tex
            icon:SetScript("OnEnter", PetHappinessIcon_OnEnter)
            icon:SetScript("OnLeave", PetHappinessIcon_OnLeave)
            frame.petHappinessIcon = icon
            return icon
        end

        local function HidePetHappinessIcon(frame)
            if frame.petHappinessIcon then
                frame.petHappinessIcon:Hide()
            end
        end

        local function Layout(frame)
            if frame.unit ~= "player" then
                return
            end
            local fs = frame.petNameText
            if not fs or not fs:IsShown() or not PlayerUnitUsesFluxPetLayout() or not PetHappinessQuery() then
                HidePetHappinessIcon(frame)
                return
            end
            local happiness, damagePercentage, loyaltyRate = ReadPetHappiness()
            -- A nil happiness result hides the icon (feature off, or this pet has none).
            if happiness == nil then
                HidePetHappinessIcon(frame)
                return
            end
            local icon = EnsurePetHappinessIcon(frame)
            if not icon then
                return
            end
            ApplyPetHappinessArt(icon.texture, happiness)
            icon.tooltip = _G["PET_HAPPINESS" .. happiness]
            if PET_DAMAGE_PERCENTAGE then
                icon.tooltipDamage = string.format(PET_DAMAGE_PERCENTAGE, damagePercentage or 0)
            else
                icon.tooltipDamage = nil
            end
            if loyaltyRate and loyaltyRate < 0 and LOSING_LOYALTY then
                icon.tooltipLoyalty = LOSING_LOYALTY
            elseif loyaltyRate and loyaltyRate > 0 and GAINING_LOYALTY then
                icon.tooltipLoyalty = GAINING_LOYALTY
            else
                icon.tooltipLoyalty = nil
            end
            icon.tooltipDiet = PetHappinessDietLine()
            local sw = API.SafeGetNumber(fs:GetStringWidth(), 0)
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", fs, "CENTER", (sw * 0.5) + 2, 0)
            icon:Show()
        end

        impl = Layout
        UF._layoutPetHappiness = impl
    end
    impl(self)
end

--- Placement 2: target HP/power text corners match player-with-pet when ToT exists (Flux ToT on).
local function TargetUnitUsesSideBySideTotTextLayout(unit)
    if unit ~= "target" then
        return false
    end
    if not (FluxUnitFrames_GetPlayerTargetPlacement and FluxUnitFrames_GetPlayerTargetPlacement() == 2) then
        return false
    end
    if not (FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ShouldUseFlux("targettarget")) then
        return false
    end
    return UF.UnitTokenIsResolved("target") and UF.UnitTokenIsResolved("targettarget")
end

--- Rich "ToT: |class or reaction colored name| [level]" for target frame petNameText (placement 2).
local function FluxTargetTotPetNameRichText()
    local unit = "targettarget"
    if not UF.UnitTokenIsResolved("target") or not UF.UnitTokenIsResolved(unit) then
        return "ToT:"
    end
    local name = UnitDisplayName(unit)
    if not name then
        return "ToT:"
    end
    local level = API.SafeGetNumber(UnitLevel(unit), 0)
    local levelStr = (level > 0) and (" [" .. level .. "]") or ""
    local function toHex(r, g, b)
        return string.format(
            "%02x%02x%02x",
            math.floor(r * 255 + 0.5),
            math.floor(g * 255 + 0.5),
            math.floor(b * 255 + 0.5)
        )
    end
    local coloredName
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        class = API.SafeAccessibleString(class)
        local c = class and RAID_CLASS_COLORS[class]
        if c then
            coloredName = string.format("|cff%s%s|r", toHex(c.r, c.g, c.b), name)
        else
            coloredName = name
        end
    else
        local reaction = UnitReaction(unit, "player")
        local r, g, b = 1, 1, 1
        if reaction then
            if reaction >= 5 then
                r, g, b = 0, 1, 0
            elseif reaction >= 4 then
                r, g, b = 1, 1, 0
            else
                r, g, b = 1, 0, 0
            end
        end
        coloredName = string.format("|cff%s%s|r", toHex(r, g, b), name)
    end
    local levelRich = (levelStr ~= "") and string.format("|cffaaaaaa%s|r", levelStr) or ""
    return "ToT: " .. coloredName .. levelRich
end

-- Midnight (12+): StatusBar can interpolate; loss overlays sample fill width between min/max and value updates.
local function StatusBarSetMinMaxImmediate(bar, minV, maxV)
    if not bar then return end
    if API.isMidnight and Enum and Enum.StatusBarInterpolation then
        local im = Enum.StatusBarInterpolation.Immediate
        pcall(function()
            bar:SetMinMaxValues(minV, maxV, im)
        end)
    else
        bar:SetMinMaxValues(minV, maxV)
    end
end

local function StatusBarSetValueImmediate(bar, value)
    if not bar then return end
    if API.isMidnight and Enum and Enum.StatusBarInterpolation then
        local im = Enum.StatusBarInterpolation.Immediate
        pcall(function()
            bar:SetValue(value, im)
        end)
        if bar.SetToTargetValue then
            pcall(bar.SetToTargetValue, bar)
        end
    else
        bar:SetValue(value)
    end
end

-- Power/additional bars: no snapshot between min/max and value.
local function StatusBarSetMinMaxAndValueImmediate(bar, minV, maxV, value)
    StatusBarSetMinMaxImmediate(bar, minV, maxV)
    StatusBarSetValueImmediate(bar, value)
end

-- ---------------------------------------------------------------------------
-- Utility Functions
-- ---------------------------------------------------------------------------
local function FormatValue(value)
    -- AbbreviateLargeNumbers is AllowedWhenTainted (engine-side). Lua compare/concat on secrets throws.
    if value == nil then
        return nil
    end
    if AbbreviateLargeNumbers then
        local ok, result = pcall(AbbreviateLargeNumbers, value)
        if ok and result ~= nil then
            return result
        end
    end
    if API.IsSecretValue and API.IsSecretValue(value) then
        return value
    end

    -- Standard formatting for accessible numbers
    if value >= 1000000000 then
        return string.format("%.1fb", value / 1000000000)
    elseif value >= 1000000 then
        return string.format("%.1fm", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fk", value / 1000)
    else
        return tostring(value)
    end
end

-- FontString:SetFormattedText / SetText are AllowedWhenTainted. Never string.format or `..` secrets.
local function SetFSFormat(fs, fmt, a, b)
    if not fs then
        return
    end
    if a == nil then
        fs:SetText("")
        return
    end
    if b ~= nil then
        if pcall(fs.SetFormattedText, fs, fmt, a, b) then
            return
        end
    end
    if pcall(fs.SetFormattedText, fs, fmt, a) then
        return
    end
    pcall(fs.SetText, fs, a)
end

local function SetPercentLabel(fs, percent)
    if not fs then
        return
    end
    if API and API.IsSecretValue and API.IsSecretValue(percent) then
        if pcall(fs.SetFormattedText, fs, "%.0f%%", percent) then
            return
        end
        if pcall(fs.SetFormattedText, fs, "%d%%", percent) then
            return
        end
        SetFSFormat(fs, "%s%%", percent)
        return
    end
    if percent == nil then
        fs:SetText("")
        return
    end
    if pcall(fs.SetFormattedText, fs, "%.0f%%", percent) then
        return
    end
    if pcall(fs.SetFormattedText, fs, "%d%%", percent) then
        return
    end
    SetFSFormat(fs, "%s%%", percent)
end

local function SetCurMaxLabel(fs, cur, max)
    if not fs then
        return
    end
    if cur == nil then
        fs:SetText("")
        return
    end
    if max == nil then
        SetFSFormat(fs, "%s", cur)
        return
    end
    SetFSFormat(fs, "%s / %s", cur, max)
end

-- Helper functions for secret value handling (12.0+ compatibility)
local function IsSecretValue(value)
    return API and API.IsSecretValue and API.IsSecretValue(value)
end

-- Check if unit is one of our custom FluxUI unit frames (not Blizzard's CompactRaidFrames)
local function IsFluxUnitFrame(unit)
    if not unit then return false end
    return unit == "player" or unit == "target" or unit == "targettarget"
        or unit == "focus" or unit == "focustarget" or unit == "pet"
end

local function SafeGetNumber(value)
    if IsSecretValue(value) then
        return 0 -- Default fallback for secret values
    end
    return tonumber(value) or 0
end

-- UnitHealthMax is 0–100 scaled on live Midnight when UnitHealthPercent exists.
-- Forever/camelot still has real Classic HP; UnitHealthPercent can exist there too,
-- so max <= 100 must not hide current/max (a level-1 with 67 HP was showing only "100%").
-- Never treat a *secret* max as percent-scaled: that hides current HP. Ellesmere
-- still shows UnitHealth through AbbreviateNumbers + SetFormattedText.
-- Never compare secret maxHealth under addon taint (errors on > / <=).
local function ClientUsesRealHealthNumbers()
    local client = ns.Flux and ns.Flux.Client
    if client and (client.isCamelot or client.isAnyClassic) then
        return true
    end
    if FLUX_API and (FLUX_API.isCamelot or FLUX_API.isAnyClassic) then
        return true
    end
    return false
end

local function IsPercentScaledHealthMax(maxH)
    if ClientUsesRealHealthNumbers() then
        return false
    end
    if not UnitHealthPercent or maxH == nil then
        return false
    end
    if IsSecretValue(maxH) then
        return false
    end
    if API.CanAccessValue and not API.CanAccessValue(maxH) then
        return false
    end
    if type(maxH) ~= "number" then
        return false
    end
    if API.SafeCompare then
        local gt = API.SafeCompare(maxH, 0, ">")
        local le = API.SafeCompare(maxH, 100, "<=")
        if gt ~= nil and le ~= nil then
            return gt and le
        end
    end
    local ok, res = pcall(function()
        return maxH > 0 and maxH <= 100
    end)
    return ok and res or false
end

local function SafeBooleanTest(value, default)
    default = (default ~= nil) and default or false
    if API and API.SafeBooleanTest then
        return API.SafeBooleanTest(value, default)
    end
    if IsSecretValue(value) then
        return default
    end
    if value == nil then
        return default
    end
    local ok, res = pcall(function()
        return not not value
    end)
    return ok and res or default
end

local function SafeCompareGUID(guid1, guid2)
    -- Don't compare secret GUIDs directly
    if IsSecretValue(guid1) or IsSecretValue(guid2) then
        return false -- Can't compare secret values
    end
    return guid1 == guid2
end

-- Midnight: UnitClass tokens can be secret strings. RAID_CLASS_COLORS cannot
-- be indexed with secret keys even when canaccessvalue is true.
local function ClassColorForUnit(unit)
    if not unit then
        return nil
    end
    local _, class = UnitClass(unit)
    class = API.SafeAccessibleString(class)
    if not class then
        return nil
    end
    local ok, color = pcall(function()
        return RAID_CLASS_COLORS[class]
    end)
    if ok then
        return color
    end
    return nil
end

--- Forever NPC chrome: Blizzard status-bar gold. Nil for players and other clients.
--- Stored on UF so this chunk stays under Lua's 200-local limit.
function UF.ForeverNpcChrome(unit)
    if not unit or not UnitIsPlayer then
        return nil
    end
    local ok, value = pcall(UnitIsPlayer, unit)
    if not ok or value == nil or IsSecretValue(value) then
        return nil
    end
    if SafeBooleanTest(value, false) then
        return nil
    end
    if not FluxBorder or not FluxBorder.GetForeverClientChromeRGB or not FluxBorder.GetForeverClientBackdropRGB then
        return nil
    end
    local r, g, b = FluxBorder:GetForeverClientChromeRGB()
    if not r then
        return nil
    end
    local br, bg, bb = FluxBorder:GetForeverClientBackdropRGB()
    return r, g, b, br or (r * 0.5), bg or (g * 0.5), bb or (b * 0.5)
end

-- Helper function to get unit's class color (for target frames)
local function GetUnitClassColor(unit)
    if not unit then return { r = 0.6, g = 0.6, b = 0.6 } end

    if UnitIsPlayer(unit) then
        return ClassColorForUnit(unit) or { r = 0.6, g = 0.6, b = 0.6 }
    end
    local r, g, b = UF.ForeverNpcChrome(unit)
    if r then
        return { r = r, g = g, b = b }
    end
    -- For NPCs, use neutral/default colors (no hostility colors)
    return { r = 0.6, g = 0.6, b = 0.6 } -- Neutral gray
end

-- Separator / chrome tint: atlas → white; custom → custom accent; class → unit class RGB.
-- Target / target-of-target: always that unit's class color (ignores global border accent).
local function GetChromeSeparatorRGB(unit)
    unit = unit or "player"
    if unit == "target" or unit == "targettarget" or unit == "focus" or unit == "focustarget" then
        local classColor = ClassColorForUnit(unit)
        if classColor then
            return classColor.r, classColor.g, classColor.b
        end
        local r, g, b = UF.ForeverNpcChrome(unit)
        if r then
            return r, g, b
        end
        return 1, 1, 1
    end
    if not FluxBorder or not FluxBorder.GetAccentMode then
        local classColor = ClassColorForUnit(unit)
        if classColor then return classColor.r, classColor.g, classColor.b end
        return 1, 1, 1
    end
    local mode = FluxBorder:GetAccentMode()
    if mode == "atlas" then
        return FluxBorder:GetThemedVertexRGB()
    end
    if mode == "custom" then
        return FluxBorder:GetThemedVertexRGB()
    end
    local classColor = ClassColorForUnit(unit)
    if classColor then return classColor.r, classColor.g, classColor.b end
    return 1, 1, 1
end

-- ---------------------------------------------------------------------------
-- Health Bar
-- ---------------------------------------------------------------------------
local function CreateSeparator(parent)
    -- Use container if available, otherwise parent
    local textureParent = parent.SeparatorContainer or parent
    local sep = textureParent:CreateTexture(nil, "OVERLAY", nil, 7)
    sep:SetHeight(17) -- Start with 20, visual check. 32 might be overwhelming.
    
    if FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases() then
        sep:SetAtlas("battlefieldminimap-border-top", true)
         -- Atlas usually sets its own size, force height update if needed
         -- Force scaling to matches width? No, slice logic.
         -- Use non-true param to NOT force native size?
         -- sep:SetAtlas("name", UseAtlasSize) -> false allows SetSize
        sep:SetAtlas("battlefieldminimap-border-top", false)
        sep:SetHeight(17) -- Slightly thicker for Atlas
    else
        sep:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga")
        sep:SetTexCoord(0.004, 0.816, 0.004, 0.070)
        sep:SetHeight(17)
    end
    
    sep:SetVertexColor(1, 1, 1, 1)
    return sep
end

-- ---------------------------------------------------------------------------
-- Animated Health Loss Mixin (Ported from Retail UnitFrame.lua)
-- ---------------------------------------------------------------------------
local AnimatedHealthLossMixin = {}

function AnimatedHealthLossMixin:OnLoad()
    self:SetStatusBarColor(1, 0, 0, 1)
    self:SetDuration(.25)
    self:SetStartDelay(.1)
    self:SetPauseDelay(.05)
    self:SetPostponeDelay(.05)
end

function AnimatedHealthLossMixin:SetDuration(duration)
    self.animationDuration = duration or 0
end

function AnimatedHealthLossMixin:SetStartDelay(delay)
    self.animationStartDelay = delay or 0
end

function AnimatedHealthLossMixin:SetPauseDelay(delay)
    self.animationPauseDelay = delay or 0
end

function AnimatedHealthLossMixin:SetPostponeDelay(delay)
    self.animationPostponeDelay = delay or 0
end

function AnimatedHealthLossMixin:SetUnitHealthBar(unit, healthBar)
    if self.unit ~= unit then
        healthBar.AnimatedLossBar = self
        self.unit = unit
        self:SetAllPoints(healthBar)
        self:SetFrameLevel(healthBar:GetFrameLevel() - 1) -- Behind health bar
        self:UpdateHealthMinMax()
    end
end

function AnimatedHealthLossMixin:UpdateHealthMinMax()
    local maxValue = API.SafeUnitHealthMax(self.unit)
    self:SetMinMaxValues(0, maxValue)
end

function AnimatedHealthLossMixin:GetHealthLossAnimationData(currentHealth, previousHealth)
    if self.animationStartTime then
        local totalElapsedTime = GetTime() - self.animationStartTime
        if totalElapsedTime > 0 then
            local animCompletePercent = totalElapsedTime / self.animationDuration
            if animCompletePercent < 1 and API.SafeGetNumber(previousHealth) > API.SafeGetNumber(currentHealth) then
                local healthDelta = API.SafeGetNumber(previousHealth) - API.SafeGetNumber(currentHealth)
                local animatedLossAmount = API.SafeGetNumber(previousHealth) - (animCompletePercent * healthDelta)
                return animatedLossAmount, animCompletePercent
            end
        else
            return previousHealth, 0
        end
    end
    return 0, 1 -- Animated loss amount is 0, and the animation is fully complete.
end

function AnimatedHealthLossMixin:CancelAnimation()
    self:Hide()
    self.animationStartTime = nil
    self.animationCompletePercent = nil
end

function AnimatedHealthLossMixin:SetDisplayedLoss(value)
    if self._pixelMode and Enum and Enum.StatusBarInterpolation then
        local im = Enum.StatusBarInterpolation.Immediate
        if pcall(self.SetValue, self, value, im) then
            return
        end
    end
    self:SetValue(value)
end

function AnimatedHealthLossMixin:BeginAnimation(value)
    self.animationStartValue = value
    self.animationStartTime = GetTime() + self.animationStartDelay
    self.animationCompletePercent = 0
    self:SetStatusBarColor(1, 0, 0, 1)
    self:Show()
    self:SetDisplayedLoss(self.animationStartValue)
end

function AnimatedHealthLossMixin:PostponeStartTime()
    self.animationStartTime = self.animationStartTime + self.animationPostponeDelay
end

function AnimatedHealthLossMixin:UpdateHealth(currentHealth, previousHealth)
    local delta = API.SafeGetNumber(currentHealth) - API.SafeGetNumber(previousHealth)
    local hasLoss = delta < 0
    local hasBegun = self.animationStartTime ~= nil
    local isAnimating = hasBegun and self.animationCompletePercent > 0

    if hasLoss and not hasBegun then
        self:BeginAnimation(previousHealth)
    elseif hasLoss and hasBegun and not isAnimating then
        self:PostponeStartTime()
    elseif hasLoss and isAnimating then
        self.animationStartValue = self:GetHealthLossAnimationData(previousHealth, self.animationStartValue)
        self.animationStartTime = GetTime() + self.animationPauseDelay
    elseif not hasLoss and hasBegun and currentHealth >= self.animationStartValue then
        self:CancelAnimation()
    end
end

function AnimatedHealthLossMixin:ReadableAbsorbBlocks()
    local unit = self.unit
    if not unit or not UnitGetTotalAbsorbs then return false end
    local absorb = UnitGetTotalAbsorbs(unit)
    if ValueIsSecret(absorb) then return false end
    return API.SafeGetNumber(absorb, 0) > 0
end

function AnimatedHealthLossMixin:UpdateLossAnimation(currentHealth)
    if self._pixelMode and self:ReadableAbsorbBlocks() then
        self:CancelAnimation()
        return
    end
    if self.animationStartTime then
        if self._pixelMode and self._pixelBarW then
            self:SetMinMaxValues(0, self._pixelBarW)
        end
        local animationValue, animationCompletePercent = self:GetHealthLossAnimationData(API.SafeGetNumber(currentHealth), self.animationStartValue)
        self.animationCompletePercent = animationCompletePercent
        if animationCompletePercent >= 1 then
            self:CancelAnimation()
        else
            self:SetDisplayedLoss(animationValue)
        end
    end
end

function AnimatedHealthLossMixin:ShowPixelDriver()
    if not self._pixelDriver then
        local driver = CreateFrame("Frame", nil, self)
        driver:SetScript("OnUpdate", function()
            if not self.animationStartTime then
                driver:Hide()
                return
            end
            local current = self._pixelCurrent
            if current == nil then
                return
            end
            self:UpdateLossAnimation(current)
            if not self.animationStartTime then
                driver:Hide()
            end
        end)
        self._pixelDriver = driver
    end
    self._pixelDriver:Show()
end

-- Widths are plain pixels so Midnight secret health values are never compared.
function AnimatedHealthLossMixin:UpdateFromPixels(currentW, previousW, barW)
    self._pixelMode = true
    self._pixelCurrent = currentW
    self._pixelBarW = math.max(barW or 1, 1)
    self:SetMinMaxValues(0, self._pixelBarW)
    if self:ReadableAbsorbBlocks() then
        self:CancelAnimation()
        return
    end
    self:UpdateHealth(currentW, previousW)
    if self.animationStartTime then
        self:ShowPixelDriver()
        self:UpdateLossAnimation(currentW)
    end
end
-- Mixin global export for ease of use
ns.AnimatedHealthLossMixin = AnimatedHealthLossMixin

-- ---------------------------------------------------------------------------
-- Heal Prediction and Absorb System
-- ---------------------------------------------------------------------------
local MAX_INCOMING_HEAL_OVERFLOW = 1.0

-- Prefer ns.API.SafeSetAtlas (FluxAPICompat); tolerate absent/old compat tables.
local function SafeSetAtlasForTextures(texture, atlasName, useAtlasSize)
    if type(API.SafeSetAtlas) == "function" then
        return API.SafeSetAtlas(texture, atlasName, useAtlasSize)
    end
    if not texture or not atlasName or not texture.SetAtlas then
        return false
    end
    return select(1, pcall(function()
        texture:SetAtlas(atlasName, useAtlasSize)
    end))
end

-- Match CompactUnitFrameLayout_SetupAbsorbElement / TextureUtil.SetTextureWithAddressModeOptions
local function SetupTextureWithWrap(texture, asset)
    if not texture or not asset then return false end
    local TK = _G.TextureKitConstants
    if _G.SetTextureWithAddressModeOptions and TK then
        local ok = pcall(function()
            SetTextureWithAddressModeOptions(texture, asset, TK.IgnoreAtlasSize, TK.AddressModeWrap, TK.AddressModeWrap)
        end)
        if ok then
            return true
        end
    end
    if SafeSetAtlasForTextures(texture, asset, false) then
        pcall(function()
            texture:SetHorizTile(true)
            texture:SetVertTile(true)
        end)
        return true
    end
    return false
end

local function SetupTextureWithClamp(texture, asset)
    if not texture or not asset then return false end
    local TK = _G.TextureKitConstants
    if _G.SetTextureWithAddressModeOptions and TK then
        local ok = pcall(function()
            SetTextureWithAddressModeOptions(texture, asset, TK.IgnoreAtlasSize, TK.AddressModeClamp, TK.AddressModeClamp)
        end)
        if ok then
            return true
        end
    end
    return SafeSetAtlasForTextures(texture, asset, false)
end

local function ApplyBlizzardShieldFillToStatusBar(bar)
    local tex = bar and bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if not tex then return false end
    if SetupTextureWithWrap(tex, ATLAS_RAID_SHIELD_FILL) then
        bar:SetStatusBarColor(1, 1, 1, 0.7)
        return true
    end
    tex:SetTexture(TEXTURE_BG)
    bar:SetStatusBarColor(0.14, 0.33, 0.7, 0.7)
    return false
end

local function ApplyBlizzardHealAbsorbFillToStatusBar(bar)
    local tex = bar and bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if not tex then return false end
    if SetupTextureWithWrap(tex, ATLAS_RAID_ABSORB_FILL) then
        bar:SetStatusBarColor(1, 1, 1, 0.7)
        return true
    end
    tex:SetTexture(TEXTURE_BAR)
    bar:SetStatusBarColor(0.68, 0.28, 0.28, 0.7)
    return false
end

-- Striped overlays must track the StatusBar *fill* region, not the bar frame
-- (SetAllPoints on the frame covers the full widget while the fill is partial).
local function AnchorOverlayToStatusBarFill(bar, overlay)
    if not bar or not overlay then return end
    local fill = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if not fill then return end
    overlay:ClearAllPoints()
    overlay:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
    overlay:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)
end

local function RefreshTiledOverlayTexCoords(overlay, tileSize)
    if not overlay or not overlay:IsShown() then return end
    if not tileSize or tileSize <= 0 then return end
    -- Use overlay's own dimensions (matches fill after AnchorOverlayToStatusBarFill).
    pcall(function()
        local w = overlay:GetWidth()
        local h = overlay:GetHeight()
        overlay:SetTexCoord(0, w / tileSize, 0, h / tileSize)
    end)
end

local function RefreshAbsorbShieldOverlay(bar, tileSize)
    if not bar or not bar.shieldOverlay then return end
    AnchorOverlayToStatusBarFill(bar, bar.shieldOverlay)
    RefreshTiledOverlayTexCoords(bar.shieldOverlay, tileSize)
end

local function FrameHasPositiveTotalAbsorbs(unit)
    local okA, a = pcall(UnitGetTotalAbsorbs, unit)
    if not okA or not a then return false end
    local okP, positive = pcall(function() return a > 0 end)
    return okP and positive
end

-- Heal absorb: Blizzard edge shadows + tiled absorb overlay (CompactUnitFrame pattern)
local function UpdateHealAbsorbDecorations(bar, unit, allIncomingHeal, damageAbsorbPositive)
    if not bar then return end
    if not bar:IsShown() then
        if bar.absorbOverlay then bar.absorbOverlay:Hide() end
        if bar.healAbsorbLeftShadow then bar.healAbsorbLeftShadow:Hide() end
        if bar.healAbsorbRightShadow then bar.healAbsorbRightShadow:Hide() end
        return
    end
    local ht = bar:GetStatusBarTexture()
    if not ht then return end

    if bar.absorbOverlay and bar.healAbsorbOverlayActive then
        AnchorOverlayToStatusBarFill(bar, bar.absorbOverlay)
        bar.absorbOverlay:Show()
        RefreshTiledOverlayTexCoords(bar.absorbOverlay, ABSORB_OVERLAY_TILE)
    end

    local showLeft = true
    if allIncomingHeal ~= nil then
        local ok, res = pcall(function() return allIncomingHeal <= 0 end)
        if ok then showLeft = res end
    end
    if bar.healAbsorbLeftShadow then
        bar.healAbsorbLeftShadow:SetShown(showLeft)
        if showLeft then
            bar.healAbsorbLeftShadow:ClearAllPoints()
            bar.healAbsorbLeftShadow:SetPoint("TOPLEFT", ht, "TOPLEFT", 0, 0)
            bar.healAbsorbLeftShadow:SetPoint("BOTTOMLEFT", ht, "BOTTOMLEFT", 0, 0)
        end
    end

    local showRight = damageAbsorbPositive
    if showRight == nil and unit then
        showRight = FrameHasPositiveTotalAbsorbs(unit)
    end
    if bar.healAbsorbRightShadow then
        bar.healAbsorbRightShadow:SetShown(showRight and true or false)
        if showRight then
            bar.healAbsorbRightShadow:ClearAllPoints()
            bar.healAbsorbRightShadow:SetPoint("TOPLEFT", ht, "TOPRIGHT", -8, 0)
            bar.healAbsorbRightShadow:SetPoint("BOTTOMLEFT", ht, "BOTTOMRIGHT", -8, 0)
        end
    end
end

-- Helper to set position of prediction/absorb bars relative to health texture.
-- offsetXPercent: optional fraction of bar width to shift anchor (negative = bite into health).
local function UpdateFillPosition(self, previousTexture, amount, offsetXPercent)
    -- 12.0 Safety: amount might be a secret value; comparisons on secrets error.
    local shouldHide = false
    if not amount then
        shouldHide = true
    else
        local ok, res = pcall(function() return amount <= 0 end)
        if ok then shouldHide = res end
    end
    if shouldHide then
        self:Hide()
        if self.overlay then self.overlay:Hide() end
        if self.absorbOverlay then self.absorbOverlay:Hide() end
        if self.healAbsorbLeftShadow then self.healAbsorbLeftShadow:Hide() end
        if self.healAbsorbRightShadow then self.healAbsorbRightShadow:Hide() end
        return nil
    end

    local parent = self:GetParent() -- The Health Bar
    local totalWidth = parent:GetWidth()
    local _, maxHealth = parent:GetMinMaxValues()

    local maxIsSecret = API.IsSecretValue(maxHealth)
    if not maxIsSecret and (not maxHealth or maxHealth <= 0) then
        maxHealth = 1
    end

    if totalWidth == 0 then
        self:Hide()
        if self.overlay then self.overlay:Hide() end
        if self.absorbOverlay then self.absorbOverlay:Hide() end
        if self.healAbsorbLeftShadow then self.healAbsorbLeftShadow:Hide() end
        if self.healAbsorbRightShadow then self.healAbsorbRightShadow:Hide() end
        return nil
    end

    local barOffsetX = 0
    if offsetXPercent then
        barOffsetX = totalWidth * offsetXPercent
    end

    self:SetHeight(parent:GetHeight())
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", previousTexture, "TOPRIGHT", barOffsetX, 0)
    self:SetPoint("BOTTOMLEFT", previousTexture, "BOTTOMRIGHT", barOffsetX, 0)

    if API.isMidnight then
        -- 12.0: Use StatusBar's native fill logic to avoid math on secret values
        self:SetWidth(totalWidth)
        self:SetMinMaxValues(0, maxHealth)
        self:SetValue(amount)
    else
        -- Legacy: Manual width calculation
        local percent = amount / maxHealth
        local width = totalWidth * percent
        self:SetWidth(width)
        self:SetValue(amount)
    end

    self:Show()
    if self.overlay then
        self.overlay:SetAllPoints(self)
        self.overlay:Show()
    end
    if self.absorbOverlay and self.healAbsorbOverlayActive then
        AnchorOverlayToStatusBarFill(self, self.absorbOverlay)
        self.absorbOverlay:Show()
        RefreshTiledOverlayTexCoords(self.absorbOverlay, ABSORB_OVERLAY_TILE)
    end
    return self:GetStatusBarTexture()
end




--- Hide heal and absorb overlays the options turned off. Called after the painter so a later Show does not stick.
function UF.ApplyHealAbsorbOptionVisibility(frame)
    if not frame then
        return
    end
    local function hideRegion(region)
        if region and region.Hide then
            region:Hide()
        end
    end
    local unit = frame.unit
    local showHeal = not FluxUnitFrames_ShouldShowHealPrediction or FluxUnitFrames_ShouldShowHealPrediction(unit)
    local showAbsorb = not FluxUnitFrames_ShouldShowAbsorbs or FluxUnitFrames_ShouldShowAbsorbs(unit)
    if not showHeal then
        hideRegion(frame.myHealPredictionBar)
        hideRegion(frame.otherHealPredictionBar)
    end
    if not showAbsorb then
        hideRegion(frame.totalAbsorbBar)
        hideRegion(frame.absorbOverflow)
        hideRegion(frame.healAbsorbBar)
        hideRegion(frame.overAbsorbGlow)
        hideRegion(frame.overHealAbsorbGlow)
    end
end

-- Ported from Retail UnitFrameHealPredictionBars_Update, with absorb support.
-- totalAbsorbBar uses TPerl/XPerl style: positioned at the health fill boundary
-- with reverse-fill so the absorb renders right where the green health ends.
function UF.UpdateHealPrediction(frame)
    if not frame.myHealPredictionBar then return end
    local showHeal = not FluxUnitFrames_ShouldShowHealPrediction or FluxUnitFrames_ShouldShowHealPrediction(frame.unit)
    local showAbsorb = not FluxUnitFrames_ShouldShowAbsorbs or FluxUnitFrames_ShouldShowAbsorbs(frame.unit)
    if not showHeal and not showAbsorb then
        UF.ApplyHealAbsorbOptionVisibility(frame)
        return
    end

    if API.isMidnight then
        -- ---------------------------------------------------------------
        -- 12.0+ Path: All numeric values may be secret.
        -- Arithmetic on secrets produces secrets (safe); only comparisons
        -- (>, <, ==) error.  Wrap comparisons in pcall; pass secrets
        -- directly to widget APIs (SetValue, SetMinMaxValues, SetPoint).
        -- ---------------------------------------------------------------
        if not frame.Health.healCalc then
            frame.Health.healCalc = API.CreateUnitHealPredictionCalculator()
        end

        API.UnitGetDetailedHealPrediction(frame.unit, "player", frame.Health.healCalc)

        local allIncomingHeal, myIncomingHeal, otherIncomingHeal, healClamped = frame.Health.healCalc:GetIncomingHeals()
        local healAbsorb, overHealAbsorb = frame.Health.healCalc:GetHealAbsorbs()

        local healthTexture = frame.Health:GetStatusBarTexture()
        local lastTexture = healthTexture

        -- Heal absorb segment (bites into health from the right)
        if frame.healAbsorbBar then
            lastTexture = UpdateFillPosition(frame.healAbsorbBar, healthTexture, healAbsorb) or lastTexture
            if frame.healAbsorbBar:IsShown() then
                UpdateHealAbsorbDecorations(frame.healAbsorbBar, frame.unit, allIncomingHeal, nil)
            end
        end

        if frame.overHealAbsorbGlow then
            local showGlow = false
            if overHealAbsorb ~= nil then
                local ok, val = pcall(function() return overHealAbsorb == true end)
                if ok then showGlow = val end
            end
            frame.overHealAbsorbGlow:SetShown(showGlow)
        end

        -- My heals
        if frame.myHealPredictionBar then
            lastTexture = UpdateFillPosition(frame.myHealPredictionBar, lastTexture, myIncomingHeal) or lastTexture
        end

        -- Other heals
        if frame.otherHealPredictionBar then
            UpdateFillPosition(frame.otherHealPredictionBar, lastTexture, otherIncomingHeal)
        end

        -- Total absorb: split into forward bar (empty space) and overflow bar
        -- (over health). The overflow bar lives inside absorbClipFrame which is
        -- anchored to the health fill texture, so SetClipsChildren clips it at
        -- the health boundary automatically — no secret-value comparisons needed.
        if frame.totalAbsorbBar and frame.Health.healCalc then
            local healCalc = frame.Health.healCalc
            local dead = UnitIsDeadOrGhost(frame.unit)
            local healthBar = frame.Health
            local barWidth = healthBar:GetWidth()

            if not dead and barWidth > 0 then
                local healthTex = healthBar:GetStatusBarTexture()
                local _, maxHP = healthBar:GetMinMaxValues()

                pcall(healCalc.SetDamageAbsorbClampMode, healCalc, 1)
                local okC, clampedAbsorb = pcall(healCalc.GetDamageAbsorbs, healCalc)

                pcall(healCalc.SetDamageAbsorbClampMode, healCalc, 2)
                local okF, fullAbsorb = pcall(healCalc.GetDamageAbsorbs, healCalc)

                if okC then
                    local bar = frame.totalAbsorbBar
                    bar:ClearAllPoints()
                    bar:SetPoint("TOPLEFT", healthTex, "TOPRIGHT", 0, 0)
                    bar:SetPoint("BOTTOMLEFT", healthTex, "BOTTOMRIGHT", 0, 0)
                    bar:SetWidth(barWidth)
                    pcall(bar.SetMinMaxValues, bar, 0, maxHP)
                    pcall(bar.SetValue, bar, clampedAbsorb)
                    bar:Show()
                    RefreshAbsorbShieldOverlay(bar, SHIELD_OVERLAY_TILE)
                else
                    frame.totalAbsorbBar:Hide()
                end

                if okF and frame.absorbOverflow then
                    local ovf = frame.absorbOverflow
                    pcall(ovf.SetMinMaxValues, ovf, 0, maxHP)
                    pcall(ovf.SetValue, ovf, fullAbsorb)
                    ovf:Show()
                    RefreshAbsorbShieldOverlay(ovf, SHIELD_OVERLAY_TILE)
                elseif frame.absorbOverflow then
                    frame.absorbOverflow:Hide()
                end
            else
                frame.totalAbsorbBar:Hide()
                if frame.absorbOverflow then frame.absorbOverflow:Hide() end
            end
        end

        -- Over absorb glow (right edge)
        if frame.overAbsorbGlow then
            local showGlow = false
            local okAbs, absAmt = pcall(UnitGetTotalAbsorbs, frame.unit)
            if okAbs and absAmt then
                local ok, val = pcall(function()
                    local _, maxHP = frame.Health:GetMinMaxValues()
                    local curHP = frame.Health:GetValue()
                    return absAmt > 0 and (curHP + absAmt >= maxHP)
                end)
                if ok then showGlow = val end
            end
            frame.overAbsorbGlow:SetShown(showGlow)
        end

        UF.ApplyHealAbsorbOptionVisibility(frame)
        return
    end

    -- -------------------------------------------------------------------
    -- Legacy Path (pre-12.0): Manual math with safe number conversion.
    -- Exact TPerl pre-retail positioning logic for the absorb bar.
    -- -------------------------------------------------------------------
    local _, maxHealth = frame.Health:GetMinMaxValues()
    local health = frame.Health:GetValue()

    maxHealth = API.SafeGetNumber(maxHealth)
    health = API.SafeGetNumber(health)

    if maxHealth <= 0 then
        UF.ApplyHealAbsorbOptionVisibility(frame)
        return
    end

    local myIncomingHeal = API.SafeGetNumber(API.SafeUnitGetIncomingHeals(frame.unit, "player"))
    local allIncomingHeal = API.SafeGetNumber(API.SafeUnitGetIncomingHeals(frame.unit))
    local totalAbsorb = API.SafeGetNumber(API.SafeUnitGetTotalAbsorbs(frame.unit))

    -- Heal absorb
    local myCurrentHealAbsorb = 0
    if frame.healAbsorbBar then
        myCurrentHealAbsorb = API.SafeGetNumber(API.SafeUnitGetTotalHealAbsorbs(frame.unit))

        if health < myCurrentHealAbsorb then
            if frame.overHealAbsorbGlow then frame.overHealAbsorbGlow:Show() end
            myCurrentHealAbsorb = health
        else
            if frame.overHealAbsorbGlow then frame.overHealAbsorbGlow:Hide() end
        end
    else
        if frame.overHealAbsorbGlow then frame.overHealAbsorbGlow:Hide() end
    end

    -- Overflow handling (account for heal absorb eating into effective health)
    if health - myCurrentHealAbsorb + allIncomingHeal > maxHealth * MAX_INCOMING_HEAL_OVERFLOW then
        allIncomingHeal = maxHealth * MAX_INCOMING_HEAL_OVERFLOW - health + myCurrentHealAbsorb
    end

    -- Split heals
    local otherIncomingHeal = 0
    if allIncomingHeal >= myIncomingHeal then
        otherIncomingHeal = allIncomingHeal - myIncomingHeal
    else
        myIncomingHeal = allIncomingHeal
    end

    -- Over absorb glow
    if frame.overAbsorbGlow then
        frame.overAbsorbGlow:SetShown(totalAbsorb > 0 and (health + totalAbsorb >= maxHealth))
    end

    local healthTexture = frame.Health:GetStatusBarTexture()
    local myCurrentHealAbsorbPercent = myCurrentHealAbsorb / maxHealth

    -- Heal absorb bar (segment, negative offset bites into health)
    if frame.healAbsorbBar then
        if myCurrentHealAbsorb > allIncomingHeal then
            local shownHealAbsorb = myCurrentHealAbsorb - allIncomingHeal
            local shownHealAbsorbPercent = shownHealAbsorb / maxHealth
            UpdateFillPosition(frame.healAbsorbBar, healthTexture, shownHealAbsorb, -shownHealAbsorbPercent)
            UpdateHealAbsorbDecorations(frame.healAbsorbBar, frame.unit, allIncomingHeal, totalAbsorb > 0)
        else
            frame.healAbsorbBar:Hide()
            UpdateHealAbsorbDecorations(frame.healAbsorbBar, frame.unit, nil, false)
        end
    end

    -- My heals (offset by heal absorb so they start after the bite)
    local incomingHealTexture
    if frame.myHealPredictionBar then
        incomingHealTexture = UpdateFillPosition(frame.myHealPredictionBar, healthTexture, myIncomingHeal, -myCurrentHealAbsorbPercent)
    end

    -- Other heals
    local otherHealLeftTexture = (myIncomingHeal > 0) and incomingHealTexture or healthTexture
    local xOffset = (myIncomingHeal > 0) and 0 or -myCurrentHealAbsorbPercent
    if frame.otherHealPredictionBar then
        UpdateFillPosition(frame.otherHealPredictionBar, otherHealLeftTexture, otherIncomingHeal, xOffset)
    end

    -- Total absorb (pixel-positioned Frame+Texture overlay)
    if frame.totalAbsorbBar then
        if totalAbsorb > 0 and not UnitIsDeadOrGhost(frame.unit) then
            local barWidth = frame.Health:GetWidth()
            if barWidth > 0 and maxHealth > 0 then
                local absorbFrac = totalAbsorb / maxHealth
                local healthFrac = health / maxHealth
                local rightFrac = math.min(healthFrac + absorbFrac, 1.0)
                local leftFrac = math.max(rightFrac - absorbFrac, 0)
                frame.totalAbsorbBar:ClearAllPoints()
                frame.totalAbsorbBar:SetPoint("TOPLEFT", frame.Health, "TOPLEFT", leftFrac * barWidth, 0)
                frame.totalAbsorbBar:SetPoint("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -(1 - rightFrac) * barWidth, 0)
                frame.totalAbsorbBar:Show()
                RefreshTiledOverlayTexCoords(frame.totalAbsorbBar.shieldOverlay, SHIELD_OVERLAY_TILE)
            else
                frame.totalAbsorbBar:Hide()
            end
        else
            frame.totalAbsorbBar:Hide()
        end
    end
    UF.ApplyHealAbsorbOptionVisibility(frame)
end

-- AFK: safe boolean + display rules (Midnight may restrict UnitIsAFK comparisons)
function UF.UnitIsAFKDisplay(unit)
    if not unit or not UnitExists(unit) then return false end
    if not UnitIsPlayer(unit) then return false end
    if not UnitIsConnected(unit) then return false end
    local v = UnitIsAFK(unit)
    if v == nil then return false end
    if not API.CanAccessValue(v) then return false end
    return v and true or false
end

function UF.ShouldShowAFKHealthOverlay(unit)
    if not UF.UnitIsAFKDisplay(unit) then return false end
    if UnitIsDeadOrGhost(unit) then return false end
    return true
end

-- DEAD / Ghost status tag (numeric X/max still shown separately in UF.UpdateHealth).
function UF.GetHealthDeadGhostStatusText(unit)
    if not unit or not UnitExists(unit) then return nil end
    if UnitIsDead(unit) then return DEAD end
    if UnitIsGhost(unit) then return "Ghost" end
    return nil
end

--- FontString anchors are not protected. Skip the work when the point is unchanged.
local function PlaceBarText(fs, key, point, relative, relPoint, x, y)
    if not fs or not relative then
        return
    end
    if fs._fluxPointKey == key then
        return
    end
    fs._fluxPointKey = key
    fs:ClearAllPoints()
    fs:SetPoint(point, relative, relPoint, x, y)
end

function UF.UpdateHealth(self, unit)
    unit = unit or self.unit
    if not self.Health then return end -- Guard against calling before Health bar is created

    local health = API.SafeUnitHealth(unit)
    local maxHealth = API.SafeUnitHealthMax(unit)

    StatusBarSetMinMaxImmediate(self.Health, 0, maxHealth)

    -- Loss trail: readable widths use the mixin; secret values keep the previous SetValue.
    if ns.HealthLossOverlay and ns.HealthLossOverlay.OnBeforeHealthValueSet and self.Health._fluxHealthLossUnderlay then
        ns.HealthLossOverlay.OnBeforeHealthValueSet(self.Health)
    end

    StatusBarSetValueImmediate(self.Health, health)
    self.Health.currValue = health -- Store for next update

    if ns.HealthLossOverlay and ns.HealthLossOverlay.OnAfterHealthValueSet and self.Health._fluxHealthLossUnderlay then
        ns.HealthLossOverlay.OnAfterHealthValueSet(self.Health)
    end

    -- Update Prediction Bars
    UF.UpdateHealPrediction(self)
    
    -- Calculate Percentage
    local percent = API.GetHealthPercent100(unit)
    
    -- Health text mode: player/target default to current/max + percent. Other frames default to percent.
    local showAFK = UF.ShouldShowAFKHealthOverlay(unit)
    local deadGhostText = UF.GetHealthDeadGhostStatusText(unit)
    local healthTextMode = "both"
    if FluxUnitFrames_GetHealthTextMode then
        healthTextMode = FluxUnitFrames_GetHealthTextMode(unit)
    elseif unit == "targettarget" or unit == "focustarget" or unit == "focus" or unit == "pet" or unit == "pettarget" then
        healthTextMode = "percent"
    end

    local function HideHealthText(fs)
        if not fs then
            return
        end
        fs:SetText("")
        fs:Hide()
    end

    if healthTextMode == "none" then
        HideHealthText(self.Health.Value)
        HideHealthText(self.Health.Percent)
    elseif healthTextMode == "percent" then
        HideHealthText(self.Health.Value)
        if self.Health.Percent then
            self.Health.Percent:Show()
            SetPercentLabel(self.Health.Percent, percent)
            self.Health.Percent:ClearAllPoints()
            self.Health.Percent:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
        end
    else
        local showValues = healthTextMode == "both" or healthTextMode == "values"
        local showPercentText = healthTextMode == "both"
        if self.Health.Value then
            if not showValues then
                HideHealthText(self.Health.Value)
            else
                self.Health.Value:Show()
                local txtH = FormatValue(health)
                local txtM = FormatValue(maxHealth)
                local percentScaleMax = IsPercentScaledHealthMax(maxHealth)
                if percentScaleMax and healthTextMode ~= "values" then
                    self.Health.Value:SetText("")
                else
                    SetCurMaxLabel(self.Health.Value, txtH, txtM)
                end
            end
        end

        if self.Health.Percent then
            if not showPercentText then
                HideHealthText(self.Health.Percent)
            else
                self.Health.Percent:Show()
                SetPercentLabel(self.Health.Percent, percent)
            end
        end

        local percentOnly = IsPercentScaledHealthMax(maxHealth) and healthTextMode ~= "values"

        if unit == "player" or unit == "target" then
            local nested = (unit == "player" and PlayerUnitUsesFluxPetLayout())
                or (unit == "target" and TargetUnitUsesSideBySideTotTextLayout(unit))
            local layout = nested and "nest" or "solo"
            if showValues and self.Health.Value and self.Health.Value:IsShown() then
                if nested then
                    PlaceBarText(self.Health.Value, layout .. ":hv", "TOPRIGHT", self.Health, "TOPRIGHT", -5, -5)
                else
                    PlaceBarText(self.Health.Value, layout .. ":hv", "RIGHT", self.Health, "RIGHT", -5, 0)
                end
            elseif showValues and self.Health.Value then
                self.Health.Value:ClearAllPoints()
                self.Health.Value:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
            end
            if showPercentText and self.Health.Percent then
                if percentOnly then
                    PlaceBarText(self.Health.Percent, layout .. ":hp", "CENTER", self.Health, "CENTER", 0, 0)
                elseif nested then
                    PlaceBarText(self.Health.Percent, layout .. ":hp:n", "TOPLEFT", self.Health, "TOPLEFT", 5, -5)
                else
                    PlaceBarText(self.Health.Percent, layout .. ":hp:s", "LEFT", self.Health, "LEFT", 5, 0)
                end
            end
        elseif showValues and not showPercentText and self.Health.Value then
            self.Health.Value:ClearAllPoints()
            self.Health.Value:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
        elseif percentOnly and showPercentText and self.Health.Percent then
            self.Health.Percent:ClearAllPoints()
            self.Health.Percent:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
        end
    end

    if self.Health.HealthStatusLabel then
        if showAFK then
            self.Health.HealthStatusLabel:SetText(CHAT_MSG_AFK)
            self.Health.HealthStatusLabel:ClearAllPoints()
            self.Health.HealthStatusLabel:SetPoint("TOP", self.Health, "TOP", 0, -4)
            self.Health.HealthStatusLabel:Show()
        elseif deadGhostText then
            self.Health.HealthStatusLabel:SetText(deadGhostText)
            self.Health.HealthStatusLabel:ClearAllPoints()
            self.Health.HealthStatusLabel:SetPoint("TOP", self.Health, "TOP", 0, -4)
            self.Health.HealthStatusLabel:Show()
        else
            self.Health.HealthStatusLabel:Hide()
        end
    end

    UF.UpdateHealthColor(self, unit)
end

function UF.CreateHealthBar(frame)
    local health = CreateFrame("StatusBar", nil, frame)
    health:SetStatusBarTexture(TEXTURE_BAR)
    health:GetStatusBarTexture():SetHorizTile(false)
    health:SetFrameLevel(frame:GetFrameLevel() + 2)

    -- Color options (similar to oUF)
    health.colorClass = true        -- Color by class for players
    health.colorReaction = true     -- Color by reaction for NPCs
    health.colorHealth = true       -- Fallback to health color

    if UF.UsesHudUnitBars() then
        -- Trough sits behind the loss bar, which sits behind the health fill.
        local trough = CreateFrame("Frame", nil, frame)
        trough:SetFrameLevel(frame:GetFrameLevel())
        trough:SetAllPoints(health)
        local bg = trough:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(TEXTURE_BG)
        bg:SetVertexColor(0.2, 0.2, 0.2)
        health.bg = bg
        health.trough = trough

        local animatedLoss = CreateFrame("StatusBar", nil, frame)
        animatedLoss:SetStatusBarTexture(TEXTURE_BAR)
        animatedLoss:SetFrameLevel(math.max(trough:GetFrameLevel() + 1, frame:GetFrameLevel() + 1))
        animatedLoss:SetAllPoints(health)
        Mixin(animatedLoss, ns.AnimatedHealthLossMixin)
        animatedLoss:OnLoad()
        animatedLoss:Hide()
        health.AnimatedLossBar = animatedLoss
        ApplyHealthBarArt(health)
    else
        -- Classic: background on the health bar itself (V10). Loss trail is a texture in the overlay.
        local bg = health:CreateTexture(nil, "BACKGROUND", nil, 0)
        bg:SetAllPoints()
        bg:SetTexture(TEXTURE_BG)
        bg:SetVertexColor(0.2, 0.2, 0.2)
        health.bg = bg
        health:SetStatusBarTexture(TEXTURE_BAR)
        health:SetStatusBarColor(0, 1, 0)
    end
    
    -- Heal Prediction Bars
    local myHealPrediction = CreateFrame("StatusBar", nil, health)
    myHealPrediction:SetStatusBarTexture(TEXTURE_BAR)
    myHealPrediction:SetStatusBarColor(0.0, 0.82, 1.0, 0.7)
    myHealPrediction:SetFrameLevel(health:GetFrameLevel() + 1)
    myHealPrediction:Hide()
    myHealPrediction.UpdateFillPosition = UpdateFillPosition
    frame.myHealPredictionBar = myHealPrediction

    local otherHealPrediction = CreateFrame("StatusBar", nil, health)
    otherHealPrediction:SetStatusBarTexture(TEXTURE_BAR)
    otherHealPrediction:SetStatusBarColor(0.0, 0.63, 0.55, 0.7)
    otherHealPrediction:SetFrameLevel(health:GetFrameLevel() + 1)
    otherHealPrediction:Hide()
    otherHealPrediction.UpdateFillPosition = UpdateFillPosition
    frame.otherHealPredictionBar = otherHealPrediction

    -- Total Absorb Bar (damage shields like PW:S).
    -- Two pieces anchored to the health fill texture so absorb tracks
    -- the health boundary: a forward-fill bar for the portion extending
    -- rightward into empty space, and a reverse-fill bar for overflow
    -- that extends leftward over health.
    if API.isMidnight then
        -- 12.0+: Secret-safe approach using StatusBars anchored to healthTexture.
        local healthTex = health:GetStatusBarTexture()

        local totalAbsorbBar = CreateFrame("StatusBar", nil, health)
        totalAbsorbBar:SetStatusBarTexture(TEXTURE_BG)
        ApplyBlizzardShieldFillToStatusBar(totalAbsorbBar)
        totalAbsorbBar:SetFrameLevel(health:GetFrameLevel() + 1)
        totalAbsorbBar:Hide()
        local tabShieldOv = totalAbsorbBar:CreateTexture(nil, "ARTWORK", nil, 1)
        if SetupTextureWithWrap(tabShieldOv, ATLAS_RAID_SHIELD_OVERLAY) then
            tabShieldOv:Show()
        else
            tabShieldOv:Hide()
        end
        totalAbsorbBar.shieldOverlay = tabShieldOv
        AnchorOverlayToStatusBarFill(totalAbsorbBar, tabShieldOv)
        frame.totalAbsorbBar = totalAbsorbBar

        local absorbClipFrame = CreateFrame("Frame", nil, health)
        absorbClipFrame:SetClipsChildren(true)
        absorbClipFrame:SetPoint("TOPLEFT", healthTex, "TOPLEFT", 0, 0)
        absorbClipFrame:SetPoint("BOTTOMRIGHT", healthTex, "BOTTOMRIGHT", 0, 0)
        absorbClipFrame:SetFrameLevel(health:GetFrameLevel() + 1)
        frame.absorbClipFrame = absorbClipFrame

        local absorbOverflow = CreateFrame("StatusBar", nil, absorbClipFrame)
        absorbOverflow:SetStatusBarTexture(TEXTURE_BG)
        ApplyBlizzardShieldFillToStatusBar(absorbOverflow)
        absorbOverflow:SetFrameLevel(health:GetFrameLevel() + 1)
        absorbOverflow:SetReverseFill(true)
        absorbOverflow:SetPoint("TOPLEFT", health, "TOPLEFT", 0, 0)
        absorbOverflow:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", 0, 0)
        absorbOverflow:Hide()
        local ovfShieldOv = absorbOverflow:CreateTexture(nil, "ARTWORK", nil, 1)
        if SetupTextureWithWrap(ovfShieldOv, ATLAS_RAID_SHIELD_OVERLAY) then
            ovfShieldOv:Show()
        else
            ovfShieldOv:Hide()
        end
        absorbOverflow.shieldOverlay = ovfShieldOv
        AnchorOverlayToStatusBarFill(absorbOverflow, ovfShieldOv)
        frame.absorbOverflow = absorbOverflow
    else
        -- Pre-12.0: Frame+Texture positioned via pixel offsets so absorb
        -- starts at the health fill boundary and extends rightward.
        local totalAbsorbBar = CreateFrame("Frame", nil, health)
        totalAbsorbBar:SetFrameLevel(health:GetFrameLevel() + 1)
        totalAbsorbBar:Hide()
        local absorbTex = totalAbsorbBar:CreateTexture(nil, "ARTWORK")
        absorbTex:SetAllPoints()
        if not SetupTextureWithWrap(absorbTex, ATLAS_RAID_SHIELD_FILL) then
            absorbTex:SetTexture(TEXTURE_BG)
            absorbTex:SetVertexColor(0.14, 0.33, 0.7, 0.7)
        else
            absorbTex:SetVertexColor(1, 1, 1, 0.7)
        end
        local legShieldOv = totalAbsorbBar:CreateTexture(nil, "ARTWORK", nil, 1)
        legShieldOv:SetAllPoints()
        if SetupTextureWithWrap(legShieldOv, ATLAS_RAID_SHIELD_OVERLAY) then
            legShieldOv:Show()
        else
            legShieldOv:Hide()
        end
        totalAbsorbBar.shieldOverlay = legShieldOv
        frame.totalAbsorbBar = totalAbsorbBar
    end

    -- Heal Absorb Bar (anti-heal effects like Necrotic, eats into current health)
    local healAbsorbBar = CreateFrame("StatusBar", nil, health)
    healAbsorbBar:SetStatusBarTexture(TEXTURE_BAR)
    ApplyBlizzardHealAbsorbFillToStatusBar(healAbsorbBar)
    healAbsorbBar:SetFrameLevel(health:GetFrameLevel() + 1)
    healAbsorbBar:Hide()
    healAbsorbBar.UpdateFillPosition = UpdateFillPosition
    local healAbsOverlay = healAbsorbBar:CreateTexture(nil, "ARTWORK", nil, 2)
    healAbsorbBar.healAbsorbOverlayActive = SetupTextureWithWrap(healAbsOverlay, ATLAS_RAID_ABSORB_OVERLAY)
    if healAbsorbBar.healAbsorbOverlayActive then
        healAbsOverlay:SetAlpha(0.2)
    else
        healAbsOverlay:Hide()
    end
    healAbsorbBar.absorbOverlay = healAbsOverlay
    AnchorOverlayToStatusBarFill(healAbsorbBar, healAbsOverlay)
    local healAbsLeft = healAbsorbBar:CreateTexture(nil, "ARTWORK", nil, 0)
    healAbsLeft:SetTexture(FILE_ABSORB_EDGE)
    healAbsLeft:Hide()
    healAbsorbBar.healAbsorbLeftShadow = healAbsLeft
    local healAbsRight = healAbsorbBar:CreateTexture(nil, "ARTWORK", nil, 0)
    healAbsRight:SetTexture(FILE_ABSORB_EDGE)
    healAbsRight:SetTexCoord(1, 0, 0, 1)
    healAbsRight:Hide()
    healAbsorbBar.healAbsorbRightShadow = healAbsRight
    frame.healAbsorbBar = healAbsorbBar

    -- Glow Frame (child of FRAME, not health, so glows aren't clipped by SetClipsChildren)
    local glowFrame = CreateFrame("Frame", nil, frame)
    glowFrame:SetAllPoints(health)
    glowFrame:SetFrameLevel(health:GetFrameLevel() + 2)

    -- Over Absorb Glow (right edge of health bar, shown when shield exceeds bar space)
    local overAbsorbGlow = glowFrame:CreateTexture(nil, "OVERLAY")
    if not SetupTextureWithClamp(overAbsorbGlow, ATLAS_RAID_SHIELD_OVERSHIELD) then
        overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
    end
    overAbsorbGlow:SetBlendMode("ADD")
    overAbsorbGlow:SetWidth(16)
    overAbsorbGlow:SetPoint("TOPLEFT", health, "TOPRIGHT", -7, 0)
    overAbsorbGlow:SetPoint("BOTTOMLEFT", health, "BOTTOMRIGHT", -7, 0)
    overAbsorbGlow:Hide()
    frame.overAbsorbGlow = overAbsorbGlow

    -- Over Heal Absorb Glow (left edge of health bar, shown when heal absorb exceeds current HP)
    local overHealAbsorbGlow = glowFrame:CreateTexture(nil, "OVERLAY")
    if not SetupTextureWithClamp(overHealAbsorbGlow, ATLAS_RAID_ABSORB_OVERABSORB) then
        overHealAbsorbGlow:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
    end
    overHealAbsorbGlow:SetBlendMode("ADD")
    overHealAbsorbGlow:SetWidth(16)
    overHealAbsorbGlow:SetPoint("TOPRIGHT", health, "TOPLEFT", 7, 0)
    overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", health, "BOTTOMLEFT", 7, 0)
    overHealAbsorbGlow:Hide()
    frame.overHealAbsorbGlow = overHealAbsorbGlow

    local barFont = 12
    if frame.unit == "focus" then
        barFont = 8 -- ~30% smaller than default 12
    end

    local value = health:CreateFontString(nil, "OVERLAY")
    value:SetPoint("RIGHT", -5, 0)
    value:SetFont("Fonts\\FRIZQT__.TTF", barFont, "OUTLINE") 
    value:SetTextColor(1, 1, 1, 1) 
    health.Value = value

    local percent = health:CreateFontString(nil, "OVERLAY")
    percent:SetPoint("LEFT", 5, 0)
    percent:SetFont("Fonts\\FRIZQT__.TTF", barFont, "OUTLINE") 
    percent:SetTextColor(1, 1, 1, 1) 
    health.Percent = percent

    local healthStatusLabel = health:CreateFontString(nil, "OVERLAY")
    healthStatusLabel:SetPoint("CENTER", health, "CENTER", 0, 0)
    healthStatusLabel:SetFont("Fonts\\FRIZQT__.TTF", barFont, "OUTLINE")
    healthStatusLabel:SetTextColor(1, 1, 1, 1)
    healthStatusLabel:SetText(CHAT_MSG_AFK)
    healthStatusLabel:Hide()
    health.HealthStatusLabel = healthStatusLabel
    
    -- Text Overlay Frame (Parent to FRAME not Health, so it isn't clipped by Health's SetClipsChildren)
    local textOverlay = CreateFrame("Frame", nil, frame)
    textOverlay:SetAllPoints(health)
    textOverlay:SetFrameLevel(frame:GetFrameLevel() + 30) -- Text is High priority
    health.TextOverlay = textOverlay
    
    -- IMPORTANT: Clip children so Absorb/Spark never bleed outside the frame
    health:SetClipsChildren(true)
    


    -- Reparent Text
    value:SetParent(textOverlay)
    percent:SetParent(textOverlay)
    healthStatusLabel:SetParent(textOverlay)
    
    frame.Health = health
    return health
end

-- Health bar tint. HUD clients keep the green health atlas (player frame lockColor).
-- Disconnected or AFK grays the fill. Loss, absorb, and heal prediction stay as they are.
function UF.UpdateHealthColor(self, unit)
    unit = unit or self.unit
    if not self.Health then return end

    ApplyHealthBarArt(self.Health)
    local muted = (not UnitIsConnected(unit)) or UF.UnitIsAFKDisplay(unit)
    if muted then
        SetStatusBarFillGray(self.Health, true)
        return
    end
    SetStatusBarFillGray(self.Health, false)
    if self.Health._fluxHudHealth then
        self.Health:SetStatusBarColor(1, 1, 1)
    else
        self.Health:SetStatusBarColor(0, 1, 0)
    end
end

-- ---------------------------------------------------------------------------
-- Power Bar
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- Retail Power Bar Colors (Hardcoded for Consistency/Fallback)
-- ---------------------------------------------------------------------------
FluxPowerBarColor = {
    ["MANA"] = { r = 0.00, g = 0.00, b = 1.00, atlasElementName="Mana", hasClassResourceVariant = true },
    ["RAGE"] = { r = 1.00, g = 0.00, b = 0.00, atlasElementName="Rage", fullPowerAnim=true },
    ["FOCUS"] = { r = 1.00, g = 0.50, b = 0.25, atlasElementName="Focus", fullPowerAnim=true },
    ["ENERGY"] = { r = 1.00, g = 1.00, b = 0.00, atlasElementName="Energy", hasClassResourceVariant = true, fullPowerAnim=true },
    ["COMBO_POINTS"] = { r = 1.00, g = 0.96, b = 0.41 },
    ["RUNES"] = { r = 0.50, g = 0.50, b = 0.50 },
    ["RUNIC_POWER"] = { r = 0.00, g = 0.82, b = 1.00, atlasElementName="RunicPower", fullPowerAnim=true },
    ["SOUL_SHARDS"] = { r = 0.50, g = 0.32, b = 0.55 },
    ["LUNAR_POWER"] = { r = 0.30, g = 0.52, b = 0.90, atlas="Unit_Druid_AstralPower_Fill" },
    ["HOLY_POWER"] = { r = 0.95, g = 0.90, b = 0.60 },
    ["MAELSTROM"] = { r = 0.00, g = 0.50, b = 1.00, atlas = "Unit_Shaman_Maelstrom_Fill", fullPowerAnim=true },
    ["INSANITY"] = { r = 0.40, g = 0.00, b = 0.80, atlas = "Unit_Priest_Insanity_Fill" },
    ["CHI"] = { r = 0.71, g = 1.00, b = 0.92 },
    ["ARCANE_CHARGES"] = { r = 0.10, g = 0.10, b = 0.98 },
    ["FURY"] = { r = 0.788, g = 0.259, b = 0.992, atlas = "Unit_DemonHunter_Fury_Fill", fullPowerAnim=true },
    ["PAIN"] = { r = 255/255, g = 156/255, b = 0, atlas = "_DemonHunter-DemonicPainBar", fullPowerAnim=true },
    -- Fallback Maps
    [0] = { r = 0.00, g = 0.00, b = 1.00, atlasElementName="Mana" }, -- Mana
    [1] = { r = 1.00, g = 0.00, b = 0.00, atlasElementName="Rage" }, -- Rage
    [2] = { r = 1.00, g = 0.50, b = 0.25, atlasElementName="Focus" }, -- Focus
    [3] = { r = 1.00, g = 1.00, b = 0.00, atlasElementName="Energy" }, -- Energy
}

function UF.UpdatePower(self, unit)
    unit = unit or self.unit
    -- Safety check: don't update if Power bar doesn't exist yet
    if not self.Power then return end

    local afkPower = UF.UnitIsAFKDisplay(unit)
    if not afkPower and self._fluxLastAFKPower then
        self.lastPowerType = nil
        self.lastPowerToken = nil
        self.lastPowerStyle = nil
    end

    local powerType, powerToken, altR, altG, altB = UnitPowerType(unit)
    local power = API.SafeUnitPower(unit, powerType)
    local maxPower = API.SafeUnitPowerMax(unit, powerType)

    local displayPower = UF.PowerValueForDisplay(self.Power, power)
    if ns.PowerCostOverlay and ns.PowerCostOverlay.BeforePowerApplied then
        ns.PowerCostOverlay.BeforePowerApplied(self.Power)
    end
    self.Power._fluxFromPowerEvent = self._fluxPowerSpentEvent and true or false
    StatusBarSetMinMaxAndValueImmediate(self.Power, 0, maxPower, displayPower)
    
    -- Calculate Percent
    local percent = API.GetPowerPercent100(unit, powerType)
    
    -- Update Text
    local showPowerText = not FluxUnitFrames_ShouldShowPowerText or FluxUnitFrames_ShouldShowPowerText(unit)
    if not showPowerText then
        if self.Power.Value then
            self.Power.Value:SetText("")
            self.Power.Value:Hide()
        end
        if self.Power.Percent then
            self.Power.Percent:SetText("")
            self.Power.Percent:Hide()
        end
    else
    if self.Power.Value then
        self.Power.Value:Show()
    end
    if self.Power.Percent then
        self.Power.Percent:Show()
    end
    -- Special formatting for Target of Target / Focus Target / Focus and Pet
    if unit == "targettarget" or unit == "focustarget" or unit == "focus" or unit == "pet" then
        -- Only show percentage, centered
        if self.Power.Value then
            self.Power.Value:SetText("")
        end
        if self.Power.Percent then
            SetPercentLabel(self.Power.Percent, percent)
            self.Power.Percent:ClearAllPoints()
            self.Power.Percent:SetPoint("CENTER", self.Power, "CENTER", 0, 0)
        end
    else
        -- Normal frames: Show both current/max and percentage
        if self.Power.Value then
            local txtP = FormatValue(power)
            local txtM = FormatValue(maxPower)
            SetCurMaxLabel(self.Power.Value, txtP, txtM)
        end

        if self.Power.Percent then
            SetPercentLabel(self.Power.Percent, percent)
        end

        -- Player+pet and target+ToT share the corner layout. Re-anchor only when it changes.
        if unit == "player" or unit == "target" then
            local nested = (unit == "player" and PlayerUnitUsesFluxPetLayout())
                or (unit == "target" and TargetUnitUsesSideBySideTotTextLayout(unit))
            local layout = nested and "nest" or "solo"
            if self.Power.Value then
                if nested then
                    PlaceBarText(self.Power.Value, layout .. ":pv", "BOTTOMRIGHT", self.Power, "BOTTOMRIGHT", -5, 2)
                else
                    PlaceBarText(self.Power.Value, layout .. ":pv", "RIGHT", self.Power, "RIGHT", -5, 0)
                end
            end
            if self.Power.Percent then
                if nested then
                    PlaceBarText(self.Power.Percent, layout .. ":pp", "BOTTOMLEFT", self.Power, "BOTTOMLEFT", 5, 2)
                else
                    PlaceBarText(self.Power.Percent, layout .. ":pp", "LEFT", self.Power, "LEFT", 5, 0)
                end
            end
        end
    end
    end

    -- Texture changes reset the status bar on older clients, so only restyle when the power type
    -- or the class-resource atlas variant changes.
    local classResource = self.isAdditionalPowerShown and true or false
    local styleKey = tostring(powerToken) .. ":" .. tostring(powerType) .. (classResource and ":cr" or "")
    if self.lastPowerStyle ~= styleKey then
        self.lastPowerStyle = styleKey
        self.lastPowerType = powerType
        self.lastPowerToken = powerToken
        self.Power._fluxPrevFillW = nil
        UF.ApplyResourceBarStyle(self.Power, unit, powerToken, powerType, altR, altG, altB, classResource)
    else
        UF.RefreshResourceConnection(self.Power, unit)
        UF.UpdateResourceSpark(self.Power, self.Power._fluxPowerInfo and self.Power._fluxPowerInfo.spark)
    end

    UF.UpdateFullResourcePulse(self.Power, power, maxPower)

    local PCO = ns.PowerCostOverlay
    if PCO and PCO.AfterPowerApplied then
        PCO.AfterPowerApplied(self.Power, unit, displayPower, maxPower)
    end

    if afkPower then
        SetStatusBarFillGray(self.Power, true)
        if PCO and PCO.UpdateOverlayColor then
            PCO.UpdateOverlayColor(self.Power, 0.5, 0.5, 0.5)
        end
    end
    self._fluxLastAFKPower = afkPower
end

function UF.CreatePowerBar(frame)
    local power = CreateFrame("StatusBar", nil, frame)
    power:SetStatusBarTexture(TEXTURE_BAR)
    power:GetStatusBarTexture():SetHorizTile(false)
    power:SetFrameLevel(frame:GetFrameLevel() + 2)
    power:SetClipsChildren(true)
    
    local bg = power:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(TEXTURE_BG)
    bg:SetVertexColor(0.2, 0.2, 0.2)
    power.bg = bg

    local barFont = 12
    if frame.unit == "focus" then
        barFont = 8
    end
    
    -- Above the spend glow (FeedbackFrame is bar level + 4).
    local textOverlay = CreateFrame("Frame", nil, power)
    textOverlay:SetAllPoints(power)
    textOverlay:SetFrameLevel(power:GetFrameLevel() + 20)
    textOverlay:EnableMouse(false)
    power.TextOverlay = textOverlay

    local value = textOverlay:CreateFontString(nil, "OVERLAY")
    value:SetPoint("RIGHT", power, "RIGHT", -5, 0)
    value:SetFont("Fonts\\FRIZQT__.TTF", barFont, "OUTLINE") -- Match FluxStatusBar styling
    value:SetTextColor(1, 1, 1, 1) -- White text like FluxStatusBar
    power.Value = value

    local percent = textOverlay:CreateFontString(nil, "OVERLAY")
    percent:SetPoint("LEFT", power, "LEFT", 5, 0)
    percent:SetFont("Fonts\\FRIZQT__.TTF", barFont, "OUTLINE") -- Match FluxStatusBar styling
    percent:SetTextColor(1, 1, 1, 1) -- White text like FluxStatusBar
    power.Percent = percent
    
    frame.Power = power

    if ns.PowerCostOverlay and ns.PowerCostOverlay.CreateOverlay then
        ns.PowerCostOverlay.CreateOverlay(power)
    end

    return power
end

-- ---------------------------------------------------------------------------
-- 3D Portrait (square with FluxBorder)
-- ---------------------------------------------------------------------------
-- oUF portrait.lua: SetCamDistanceScale(1), SetPortraitZoom(1), SetPosition(0,0,0),
-- then ClearModel, then SetUnit. Live DF also RefreshCamera (baked portrait cam).
-- Forever must not RefreshCamera or SetCamera(0) — both restore a full-body bake.
-- Era/Anniversary use SetCamera(0). Forever: engine zoom first; if the camera is
-- still far, lift using that model's camera (not a race-height table).
local function IsCamelotPortraitClient()
    local api = rawget(_G, "FLUX_API")
    if api and (api.isCamelot or api.isForever) then
        return true
    end
    local client = ns.Flux and ns.Flux.Client
    if client and (client.isCamelot or client.isForever) then
        return true
    end
    if ns._isCamelotGameType == true then
        return true
    end
    return false
end

local function IsPostDFPortraitClient()
    if IsCamelotPortraitClient() then
        return false
    end
    local api = rawget(_G, "FLUX_API")
    if api and api.isPostDF ~= nil then
        return api.isPostDF and true or false
    end
    if GetBuildInfo then
        local version = GetBuildInfo()
        local major = tonumber(version and version:match("^(%d+)")) or 0
        return major >= 10
    end
    return false
end

local function NeedsDeferredPortraitCamera()
    return IsPostDFPortraitClient() or IsCamelotPortraitClient()
end

-- Forever: SetPortraitZoom is the real face crop. If the .m2 has no portrait
-- camera, zoom is a no-op and GetCameraDistance stays far — then pull in along
-- this model's own look axis, lifting to the top of that frustum (not a race Z).
local function ApplyCamelotPortraitCamera(portrait)
    if portrait.MakeCurrentCameraCustom then
        pcall(portrait.MakeCurrentCameraCustom, portrait)
    elseif portrait.SetCustomCamera then
        pcall(portrait.SetCustomCamera, portrait, 1)
    end

    local dist
    if portrait.GetCameraDistance then
        local ok, d = pcall(portrait.GetCameraDistance, portrait)
        if ok then
            dist = d
        end
    end
    -- Model not ready, or engine zoom already framed the head.
    if type(dist) ~= "number" or dist ~= dist or dist < 0.08 then
        return
    end
    if dist < 1.55 then
        return
    end

    local tx, ty, tz = 0, 0, 0
    local cx, cy, cz = dist, 0, 0
    if portrait.GetCameraTarget then
        local ok, x, y, z = pcall(portrait.GetCameraTarget, portrait)
        if ok and type(x) == "number" then
            tx, ty, tz = x, y, z
        end
    end
    if portrait.GetCameraPosition then
        local ok, x, y, z = pcall(portrait.GetCameraPosition, portrait)
        if ok and type(x) == "number" then
            cx, cy, cz = x, y, z
        end
    end

    local midZ = tz
    if type(cz) == "number" and cz > midZ then
        midZ = cz
    end
    if midZ < 0.2 then
        midZ = dist * 0.35
    end
    -- Previous race table aimed at ~1.52 (chest on Forever). Lift by a fraction
    -- of viewing distance so the look-at is the face of *this* model.
    local headZ = midZ + dist * 0.32
    local near = dist * 0.18
    if near < 0.58 then
        near = 0.58
    elseif near > 1.35 then
        near = 1.35
    end

    local dx, dy = cx - tx, cy - ty
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.05 then
        dx, dy, len = 1, 0, 1
    end
    local nx, ny = dx / len, dy / len
    if portrait.SetCameraTarget then
        pcall(portrait.SetCameraTarget, portrait, tx, ty, headZ)
    end
    if portrait.SetCameraPosition then
        pcall(portrait.SetCameraPosition, portrait, tx + nx * near, ty + ny * near, headZ)
    end
    if portrait.SetCameraDistance then
        pcall(portrait.SetCameraDistance, portrait, near)
    end
end

-- keepIfClose: OnAnimStarted must not reset a crop that already took.
local function ApplyPortraitCamera(portrait, keepIfClose)
    if not portrait or portrait._fluxQuestionMark then
        return
    end
    pcall(function()
        if keepIfClose and IsCamelotPortraitClient() and portrait.GetCameraDistance then
            local ok, d = pcall(portrait.GetCameraDistance, portrait)
            if ok and type(d) == "number" and d >= 0.35 and d < 1.55 then
                return
            end
        end
        if portrait.SetCamDistanceScale then
            portrait:SetCamDistanceScale(1)
        end
        if portrait.SetPortraitZoom then
            portrait:SetPortraitZoom(1)
        end
        if portrait.SetPosition then
            portrait:SetPosition(0, 0, 0)
        end
        if portrait.SetModelScale then
            portrait:SetModelScale(1.0)
        end
        if IsCamelotPortraitClient() then
            ApplyCamelotPortraitCamera(portrait)
            return
        end
        if IsPostDFPortraitClient() then
            if portrait.RefreshCamera then
                portrait:RefreshCamera()
            end
            return
        end
        if portrait.SetCamera then
            portrait:SetCamera(0)
        end
    end)
end

local function SchedulePortraitCameraRefresh(portrait)
    if not portrait or not NeedsDeferredPortraitCamera() then
        return
    end
    if portrait._fluxCamRefreshQueued then
        return
    end
    if not (C_Timer and C_Timer.After) then
        return
    end
    portrait._fluxCamRefreshQueued = true
    local function tick()
        if portrait:IsShown() and not portrait._fluxQuestionMark then
            ApplyPortraitCamera(portrait)
        end
    end
    C_Timer.After(0, tick)
    C_Timer.After(0.05, tick)
    C_Timer.After(0.20, function()
        portrait._fluxCamRefreshQueued = nil
        tick()
    end)
end

local function BindPortraitUnit(portrait, unit)
    if portrait then
        portrait._fluxPortraitUnit = unit
    end
end

-- oUF order: camera helpers, then SetUnit (ClearModel is the caller's job).
local function SetPortraitUnit(portrait, unit)
    if not portrait or not unit then
        return
    end
    BindPortraitUnit(portrait, unit)
    if portrait.SetDoBlend then
        pcall(portrait.SetDoBlend, portrait, false)
    end
    if portrait.SetKeepModelOnHide then
        pcall(portrait.SetKeepModelOnHide, portrait, true)
    end
    ApplyPortraitCamera(portrait)
    local ok = pcall(function()
        portrait:SetUnit(unit, false)
    end)
    if not ok then
        pcall(portrait.SetUnit, portrait, unit)
    end
    ApplyPortraitCamera(portrait)
end

function UF.CreatePortrait(frame)
    -- Guard: Return early if portrait already exists (prevents duplicate models)
    if frame.Portrait or frame.PortraitFrame then
        return frame.PortraitFrame or (frame.Portrait and frame.Portrait:GetParent())
    end
    
    -- Create container for the portrait with border
    local portraitFrame = CreateFrame("Frame", nil, frame)
    portraitFrame:SetFrameLevel(frame:GetFrameLevel() + 1)

    -- Set initial size (will be updated in UpdateFramePartition)
    local portraitSize = frame:GetHeight() -- Same as frame height (110px)
    portraitFrame:SetSize(portraitSize, portraitSize)

    -- Disable mouse on portrait frame - outer border handles all interaction
    portraitFrame:EnableMouse(false)

    -- Apply FluxBorder to the portrait frame first
    if ns.Border then
        ns.Border:ApplyTo(portraitFrame, 2, 2, 2, 2)

        -- Target / ToT: unit class color always (not global Appearance accent). Pet/player: themed accent via SetClassColor below.
        if frame.unit == "target" or frame.unit == "targettarget" or frame.unit == "focus" or frame.unit == "focustarget" then
            local color = GetUnitClassColor(frame.unit)
            ns.Border:SetBorderColor(portraitFrame, color.r, color.g, color.b, 1)
            ns.Border:SetBackdropColor(portraitFrame, color.r * 0.4, color.g * 0.4, color.b * 0.4, 0.85)
            if not portraitFrame.bg then
                portraitFrame.bg = portraitFrame:CreateTexture(nil, "BACKGROUND")
                portraitFrame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
                portraitFrame.bg:SetPoint("TOPLEFT", portraitFrame, "TOPLEFT", 2, -2)
                portraitFrame.bg:SetPoint("BOTTOMRIGHT", portraitFrame, "BOTTOMRIGHT", -2, 2)
            end
            portraitFrame.bg:Hide()
        elseif frame.unit == "pet" then
            -- Pet frame: Class colored border and backdrop (using Player's class)
            local color = ClassColorForUnit("player") or {r=0.5, g=0.5, b=0.5} -- Fallback
            
            -- Manual Background Texture for absolute solidity
            if not portraitFrame.bg then
                portraitFrame.bg = portraitFrame:CreateTexture(nil, "BACKGROUND")
                portraitFrame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            end
            -- Inset by 2px to be strictly inside the border
            portraitFrame.bg:ClearAllPoints()
            portraitFrame.bg:SetPoint("TOPLEFT", portraitFrame, "TOPLEFT", 2, -2)
            portraitFrame.bg:SetPoint("BOTTOMRIGHT", portraitFrame, "BOTTOMRIGHT", -2, 2)

            if Border and Border.GetAccentMode and Border:GetAccentMode() == "atlas" then
                if Border.GetThemedBackdropFillRGB then
                    local br, bg, bb = Border:GetThemedBackdropFillRGB()
                    portraitFrame.bg:SetVertexColor(br, bg, bb, 1)
                else
                    portraitFrame.bg:SetVertexColor(0.15, 0.15, 0.15, 1)
                end
            else
                portraitFrame.bg:SetVertexColor(color.r * 0.25, color.g * 0.25, color.b * 0.25, 1)
            end
            portraitFrame.bg:Show()

            ns.Border:SetClassColor(portraitFrame, 1, true) -- Initialize border
            ns.Border:SetBorderColor(portraitFrame, color.r, color.g, color.b, 1)
            -- ns.Border:SetBackdropColor -- Ignore FluxBorder backdrop, we have our own
            
            -- Ensure pet portrait is MUCH higher than player frame elements
            -- Pet frame is at player + 30, so portrait should be well above that
            portraitFrame:SetFrameLevel(frame:GetFrameLevel() + 5)
        else
            if not portraitFrame.bg then
                portraitFrame.bg = portraitFrame:CreateTexture(nil, "BACKGROUND")
                portraitFrame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
                portraitFrame.bg:SetPoint("TOPLEFT", portraitFrame, "TOPLEFT", 2, -2)
                portraitFrame.bg:SetPoint("BOTTOMRIGHT", portraitFrame, "BOTTOMRIGHT", -2, 2)
            end
            portraitFrame.bg:Hide()
            ns.Border:SetClassColor(portraitFrame, 1, true) -- Shows backdrop by default
        end
    end

    -- Create the Model for 3D portrait (use PlayerModel for unit portraits)
    local model = CreateFrame("PlayerModel", nil, portraitFrame)
    model:EnableMouse(false)
    model:ClearAllPoints()
    -- Size the model to fit within the FluxBorder (accounting for 2px border insets)
    -- Frame size is 110x110, border insets are 2px each side, so content area is 106x106
    -- Use 75% of content area and center it for better fit
    local contentSize = portraitSize - 4  -- 2px insets each side
    model:SetSize(contentSize * 1, contentSize * 1)
    model:SetPoint("CENTER", portraitFrame, "CENTER", 0, 0)
    -- model:SetFrameStrata("BACKGROUND") -- REMOVED: This was pushing the model behind the frame!
    -- Increase model level for pets to be well above backdrop
    -- Must be higher than portraitFrame for the model to sit on top of the backdrop textures
    model:SetFrameLevel(portraitFrame:GetFrameLevel() + 2)

    -- Get the unit for this frame (use frame.unit, not hardcoded "player")
    local unit = frame.unit
    BindPortraitUnit(model, unit)

    -- Set up the model (camera via ApplyPortraitCamera — post-DF vs classic vs Forever)
    local success = pcall(function()
        SetPortraitUnit(model, unit)
    end)

    if not success then
        -- Fallback 1: SetUnit only, then re-apply camera
        success = pcall(function()
            model:SetUnit(unit)
            ApplyPortraitCamera(model)
        end)
    end

    if not success then
        -- Fallback 2: Use race/gender specific model (only for player unit)
        local _, race = UnitRace(unit)
        local gender = UnitSex(unit) -- 2 = male, 3 = female

        if race and gender then
            local raceName = race:lower():gsub("%s+", "") -- Remove spaces
            local genderName = (gender == 3) and "female" or "male"

            local modelPath = string.format("Character\\%s\\%s\\%s%s.m2",
                raceName, genderName, raceName, genderName:sub(1,1):upper())

            success = pcall(function()
                model:SetModel(modelPath)
            end)
        end
    end

    if not success then
        -- Fallback 3: Generic human model
        pcall(function()
            model:SetModel("Character\\Human\\Male\\HumanMale.m2")
        end)
    end

    -- Store GUID for ShadowedUnitFrames-style GUID checking
    model.guid = nil

    -- Register events using the correct unit
    local unit = frame.unit
    FluxSafeRegisterUnitEvent(model, "UNIT_PORTRAIT_UPDATE", unit)
    FluxSafeRegisterUnitEvent(model, "UNIT_MODEL_CHANGED", unit)

    -- Set up event handler exactly like ShadowedUnitFrames but dynamic for the unit
    model:SetScript("OnEvent", function(self, event, unitParam)
        if event == "UNIT_PORTRAIT_UPDATE" and (unitParam == unit or unitParam == "player") then -- Allow player to trigger update for safety
             -- GUID-based checking
             local currentGUID = UnitGUID(unit)
            if self.guid ~= currentGUID then
                UF.UpdatePortrait(frame, unit)
                self.guid = currentGUID
            end
        elseif event == "UNIT_MODEL_CHANGED" and (unitParam == unit or unitParam == "player") then
            UF.UpdatePortrait(frame, unit)
        end
    end)

    -- Re-apply face framing when the model is shown (alt-Z / reload / strata changes).
    -- Skip when the unit is missing/out of range — question-mark fallback owns that camera.
    model:SetScript("OnShow", function(self)
        local u = frame.unit
        BindPortraitUnit(self, u)
        if u and UnitExists(u) and UnitIsVisible(u) and UnitIsConnected(u) then
            ApplyPortraitCamera(self)
            SchedulePortraitCameraRefresh(self)
        end
    end)

    -- SetCamera(0) / portrait zoom do nothing until the .m2 is actually loaded.
    pcall(function()
        model:SetScript("OnModelLoaded", function(self)
            -- SetUnit can finish loading after an empty watched frame hid it.
            -- The next missing-unit check must clear that late hidden model.
            self._fluxEmptyCleared = nil
            if not self._fluxQuestionMark then
                ApplyPortraitCamera(self)
                SchedulePortraitCameraRefresh(self)
            end
        end)
    end)
    pcall(function()
        model:SetScript("OnAnimStarted", function(self)
            if not self._fluxQuestionMark then
                ApplyPortraitCamera(self, true)
            end
        end)
    end)

    SchedulePortraitCameraRefresh(model)

    -- Flat portrait (2D) — same geometry as the PlayerModel; toggled in Unit frames → General → Features.
    -- Classic: CreateTexture(name, layer, subLevel) is not supported; the 3rd arg is a template name ("7" errors).
    local tex2d = portraitFrame:CreateTexture(nil, "ARTWORK")
    if tex2d.SetDrawLayer then
        pcall(tex2d.SetDrawLayer, tex2d, "ARTWORK", 7)
    end
    tex2d:SetPoint("CENTER", portraitFrame, "CENTER", 0, 0)
    tex2d:SetSize(contentSize, contentSize)
    tex2d:Hide()

    frame.PortraitFrame = portraitFrame
    frame.Portrait = model
    frame.Portrait2D = tex2d

    UF.UpdatePortrait(frame, unit)
    UF.UpdatePortraitCombatTint(frame)

    return portraitFrame
end

--- True when layout should reserve horizontal space for the side portrait (bar column + portrait strip).
function UF.FrameUsesPortraitLayout(self)
    if not self then
        return false
    end
    if self.portraitPosition == nil then
        return false
    end
    if not self.PortraitFrame then
        return false
    end
    if self._fluxPortraitDisabled then
        return false
    end
    return true
end

--- When the portrait strip is hidden, BigDebuffs anchors to the class icon; for NPCs (no class icon) this frame matches that slot.
function UF.LayoutBigDebuffsCornerPlaceholder(self)
    if not self or not self.unit or not IsFluxUnitFrame(self.unit) then
        return
    end
    if self.unit ~= "player" and self.unit ~= "target" and self.unit ~= "focus" and self.unit ~= "pet" then
        return
    end

    if UF.FrameUsesPortraitLayout(self) then
        if self._fluxBDCornerAnchor then
            self._fluxBDCornerAnchor:Hide()
        end
        return
    end

    -- Class/spec icons use the same chrome slot; hide placeholder while they are shown.
    if (self.classIcon and self.classIcon:IsShown()) or (self.specIcon and self.specIcon:IsShown()) then
        if self._fluxBDCornerAnchor then
            self._fluxBDCornerAnchor:Hide()
        end
        return
    end

    local ob = self.outerBorderFrame
    if not ob then
        return
    end

    local h = self._fluxBDCornerAnchor
    if not h then
        h = CreateFrame("Frame", nil, ob)
        h:SetFrameStrata(ob:GetFrameStrata())
        h:SetFrameLevel((ob:GetFrameLevel() or 0) + 35)
        self._fluxBDCornerAnchor = h
    end

    local outerBorderPadding = self.outerBorderPadding or 36
    if outerBorderPadding < 2 then
        outerBorderPadding = math.floor(self:GetHeight() or 36)
    end
    local outerBorderAlignment = self.outerBorderAlignment or "BOTTOM"
    local portraitPosition = self.portraitPosition or "LEFT"

    h:SetSize(outerBorderPadding, outerBorderPadding)
    h:ClearAllPoints()
    if outerBorderAlignment == "BOTTOM" then
        if portraitPosition == "LEFT" then
            h:SetPoint("TOPLEFT", ob, "TOPLEFT", 0, -4)
        else
            h:SetPoint("TOPRIGHT", ob, "TOPRIGHT", 0, -4)
        end
    else
        if portraitPosition == "LEFT" then
            h:SetPoint("BOTTOMLEFT", ob, "BOTTOMLEFT", 0, 4)
        else
            h:SetPoint("BOTTOMRIGHT", ob, "BOTTOMRIGHT", 0, 4)
        end
    end
    h:Show()
end

-- ---------------------------------------------------------------------------
-- Portrait Updates
-- ---------------------------------------------------------------------------
local function ShowPortraitQuestionMark(portrait)
    if not portrait then return end
    portrait._fluxQuestionMark = true
    pcall(function()
        portrait:ClearModel()
        if portrait.SetKeepModelOnHide then
            portrait:SetKeepModelOnHide(true)
        end
        if portrait.SetModelScale then portrait:SetModelScale(4.0) end
        if portrait.SetPosition then portrait:SetPosition(0, 0, -0.5) end
        portrait:SetModel("Interface\\Buttons\\TalkToMeQuestionMark.m2")
        portrait:Show()
    end)
end

local function PortraitUnitExists(unit)
    if not unit then
        return false
    end
    local exists = false
    pcall(function()
        exists = UnitExists(unit) and true or false
    end)
    return exists
end

local function PortraitFrameIsVisuallyShown(self)
    if not self then
        return false
    end
    if self.IsShown and not self:IsShown() then
        return false
    end
    if self.GetAlpha and (self:GetAlpha() or 1) <= 0.01 then
        return false
    end
    if UF.ShouldShowWatchedUnitFrame then
        local u = self.unit
        if u == "target" or u == "focus" or u == "targettarget" or u == "focustarget"
            or u == "pet" or u == "pettarget" then
            return UF.ShouldShowWatchedUnitFrame(self) and true or false
        end
    end
    return true
end

-- OOR "?" only while the unit exists but is not visible, and the frame is shown.
local function PortraitShouldShowOutOfRangeMark(self, unit)
    if not PortraitFrameIsVisuallyShown(self) or not PortraitUnitExists(unit) then
        return false
    end
    local visible = true
    pcall(function()
        if UnitIsVisible then
            visible = UnitIsVisible(unit) and true or false
        end
    end)
    if not visible then
        return true
    end
    local isPlayer = false
    pcall(function()
        isPlayer = UnitIsPlayer(unit) and true or false
    end)
    if not isPlayer then
        return false
    end
    local connected = true
    pcall(function()
        if UnitIsConnected then
            connected = UnitIsConnected(unit) and true or false
        end
    end)
    return not connected
end

function UF.UpdatePortrait(self, unit)
    if self._fluxPortraitDisabled then
        return
    end
    if not self.Portrait then return end

    -- ALWAYS use self.unit, never a passed unit parameter that might be wrong
    -- This prevents cross-contamination between portrait frames
    unit = self.unit

    if not PortraitUnitExists(unit) or not PortraitFrameIsVisuallyShown(self) then
        HideEmptyUnitPortrait(self)
        return
    end

    -- Every real paint (3D, question mark, or flat) invalidates the empty model.
    self.Portrait._fluxEmptyCleared = nil
    local use3D = (not FluxUnitFrames_ShouldUse3DPortrait) or FluxUnitFrames_ShouldUse3DPortrait()

    if not use3D then
        self.Portrait._fluxQuestionMark = nil
        pcall(function()
            if self.Portrait.SetKeepModelOnHide then
                self.Portrait:SetKeepModelOnHide(false)
            end
            if self.Portrait.ClearModel then
                self.Portrait:ClearModel()
            end
        end)
        self.Portrait:Hide()
        if self.Portrait2D then
            pcall(function()
                SetPortraitTexture(self.Portrait2D, unit)
            end)
            self.Portrait2D:Show()
        end
        return
    end

    if self.Portrait2D then
        self.Portrait2D:Hide()
    end

    -- Special case for pets: Always show 3D model, never question mark
    if unit == "pet" then
        self.Portrait._fluxQuestionMark = nil
        pcall(function()
            self.Portrait:ClearModel()
            SetPortraitUnit(self.Portrait, unit)
        end)
        ApplyPortraitCamera(self.Portrait)
        SchedulePortraitCameraRefresh(self.Portrait)
        self.Portrait:Show()
        return
    end

    -- Use 3D portrait, but the unit is not in range so swap to question mark
    if PortraitShouldShowOutOfRangeMark(self, unit) then
        ShowPortraitQuestionMark(self.Portrait)
        return
    end

    -- Use animated 3D portrait - like Blizzard's UnitFramePortrait_Update
    -- Live DF: portrait zoom before SetUnit. Forever: engine zoom, no RefreshCamera.
    self.Portrait._fluxQuestionMark = nil
    BindPortraitUnit(self.Portrait, unit)
    pcall(function()
        self.Portrait:ClearModel()
        SetPortraitUnit(self.Portrait, unit)
    end)
    ApplyPortraitCamera(self.Portrait)
    SchedulePortraitCameraRefresh(self.Portrait)
    self.Portrait:Show()
end

--- Resize the PlayerModel to match PortraitFrame (CreatePortrait uses frameHeight − 4 for content).
--- Call after layout / UI scale so 3D portraits do not stay at stale pixel size.
function UF.SyncPortraitModelGeometry(self)
    if not self or not self.Portrait or not self.PortraitFrame then return end
    local pf = self.PortraitFrame
    local portraitSize = pf.GetWidth and pf:GetWidth()
    if not portraitSize or portraitSize <= 0 then
        portraitSize = self.GetHeight and self:GetHeight()
    end
    if not portraitSize or portraitSize <= 0 then return end
    local contentSize = portraitSize - 4
    if contentSize < 1 then contentSize = 1 end
    pcall(function()
        self.Portrait:ClearAllPoints()
        self.Portrait:SetSize(contentSize, contentSize)
        self.Portrait:SetPoint("CENTER", pf, "CENTER", 0, 0)
    end)
    if self.Portrait2D then
        pcall(function()
            self.Portrait2D:ClearAllPoints()
            self.Portrait2D:SetSize(contentSize, contentSize)
            self.Portrait2D:SetPoint("CENTER", pf, "CENTER", 0, 0)
        end)
    end
end

--- Full portrait refresh after resolution / UI scale (model size + unit + camera helpers).
function UF.RefreshPortraitAfterDisplayMetrics(self)
    if not self or not self.PortraitFrame or not self.Portrait then return end
    if self.UpdatePartition then
        self:UpdatePartition()
    else
        UF.SyncPortraitModelGeometry(self)
    end
    -- Ensure model size matches PortraitFrame even if UpdatePartition returned early (combat / anchors).
    UF.SyncPortraitModelGeometry(self)
    UF.UpdatePortrait(self, self.unit)
end

-- ---------------------------------------------------------------------------
-- Spec Icon Detection (works across all clients)
-- Talent-tree (Vanilla/TBC/WotLK): uses GetTalentTabInfo for player,
-- NotifyInspect + INSPECT_READY + cache for target.
-- ---------------------------------------------------------------------------
local specIconCache = {}  -- guid -> { icon = path }
local SPEC_ICON_CACHE_TTL = 300  -- 5 minutes
local inspectPendingGUID = nil

-- Helper: compute primary spec icon from talent tab points (Blizzard formula)
local function GetSpecIconFromTalentTabs(inspect)
    if not GetTalentTabInfo then return nil end
    local maxPoints = 0
    local bestTab = nil
    local totalPoints = 0
    local tabPoints = { 0, 0, 0 }
    local talentGroup = 1
    if GetActiveTalentGroup then
        local ok, grp = pcall(GetActiveTalentGroup, inspect or false, false)
        if ok and grp then talentGroup = grp end
    end
    for tab = 1, 3 do
        local pts
        if inspect then
            pts = select(5, GetTalentTabInfo(tab, true, false, talentGroup))
        else
            pts = select(5, GetTalentTabInfo(tab))
        end
        local numPoints = 0
        if pts ~= nil then
            if type(pts) == "string" then numPoints = tonumber(pts) or 0
            elseif type(pts) == "number" then numPoints = pts end
        end
        tabPoints[tab] = numPoints
        totalPoints = totalPoints + numPoints
        if numPoints > maxPoints then
            maxPoints = numPoints
            bestTab = tab
        end
    end
    if totalPoints <= 0 or not bestTab then return nil end
    local lowPoints = math.min(tabPoints[1], tabPoints[2], tabPoints[3])
    local highPoints = maxPoints
    local sorted = { tabPoints[1], tabPoints[2], tabPoints[3] }
    table.sort(sorted)
    local midPoints = sorted[2]
    if (3 * (midPoints - lowPoints)) < (2 * (highPoints - lowPoints)) then
        if inspect then
            return select(4, GetTalentTabInfo(bestTab, true, false, talentGroup))
        else
            return select(4, GetTalentTabInfo(bestTab))
        end
    end
    return nil
end

local function CanInspectUnitForSpec(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return false end
    if UnitIsUnit(unit, "player") then return false end
    if UnitIsFriend and not UnitIsFriend("player", unit) then return false end
    if UnitIsEnemy and UnitIsEnemy("player", unit) then return false end
    if not UnitIsVisible(unit) or not UnitIsConnected(unit) then return false end
    if InCombatLockdown() then return false end
    local ok, dist = pcall(CheckInteractDistance, unit, 1)
    if not ok or not dist then return false end
    if CanInspect then return CanInspect(unit, false) == true end
    return false
end

local function TryInspectTarget()
    if not FLUX_API or not FLUX_API.hasInspectTalents then return end
    local unit = "target"
    if not CanInspectUnitForSpec(unit) then return end
    local guid = UnitGUID(unit)
    if not guid then return end
    if specIconCache[guid] and (GetTime() - (specIconCache[guid].time or 0)) < SPEC_ICON_CACHE_TTL then
        return  -- already cached recently
    end
    inspectPendingGUID = guid
    NotifyInspect(unit)
end

local function OnInspectReady(guid)
    if not guid or not FLUX_API or not FLUX_API.hasInspectTalents then return end
    if inspectPendingGUID and guid ~= inspectPendingGUID then return end
    if UnitGUID("target") ~= guid then return end
    local icon = GetSpecIconFromTalentTabs(true)
    specIconCache[guid] = { icon = icon, time = GetTime() }
    inspectPendingGUID = nil
    -- Do not call ClearInspectPlayer() here: it tears down the inspect session and breaks the default Inspect UI.
    if ns.TargetFrame and ns.TargetFrame.UpdateOuterBorder then
        ns.TargetFrame:UpdateOuterBorder()
    end
end

-- Inspect event frame (for target spec icon on talent-tree clients)
local inspectFrame = CreateFrame("Frame")
if FluxSafeRegisterEvent then
    FluxSafeRegisterEvent(inspectFrame, "INSPECT_READY")
end
if inspectFrame.RegisterUnitEvent then
    inspectFrame:RegisterUnitEvent("UNIT_TARGET", "player")
else
    inspectFrame:RegisterEvent("UNIT_TARGET")
end
inspectFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "INSPECT_READY" then
        OnInspectReady(arg1)
    elseif event == "UNIT_TARGET" and FLUX_API and FLUX_API.hasTalentTreeSpec then
        if UnitExists("target") and UnitIsPlayer("target") and (not UnitIsFriend or UnitIsFriend("player", "target")) then
            C_Timer.After(0.1, TryInspectTarget)  -- slight delay so target is set
        end
    end
end)

--- Lightweight spec-icon refresh for Respec build-match override (avoids full UpdateOuterBorder).
function UF.UpdatePlayerSpecIconOnly(self)
    if not IsFluxUnitFrame(self.unit) or self.unit ~= "player" then
        return
    end
    if not self.outerBorderFrame or not self.specIcon then
        return
    end

    local totPos2Minimal = self.unit == "targettarget"
        and FluxUnitFrames_GetPlayerTargetPlacement
        and FluxUnitFrames_GetPlayerTargetPlacement() == 2
        and FluxUnitFrames_ShouldUseFlux("player")
        and FluxUnitFrames_ShouldUseFlux("target")

    if totPos2Minimal or not UnitIsPlayer(self.unit) then
        self.specIcon:Hide()
        return
    end

    if not self.classIcon or not self.classIcon:IsShown() then
        self.specIcon:Hide()
        return
    end

    local outerBorderPadding = self.outerBorderPadding or 35
    local portraitPosition = self.portraitPosition or "LEFT"
    local outerBorderAlignment = self.outerBorderAlignment or "BOTTOM"

    local specIconPath = GetSpecIcon(self.unit)
    if specIconPath then
        self.specIcon:SetTexture(specIconPath)
        if not self.specIcon:GetTexture() and specIconPath then
            local altPath = specIconPath:gsub("Interface\\Icons\\", "")
            if altPath ~= specIconPath then
                self.specIcon:SetTexture("Interface\\Icons\\" .. altPath)
            end
        end
        self.specIcon:SetSize(outerBorderPadding, outerBorderPadding)
        self.specIcon:Show()
        self.specIcon:ClearAllPoints()
        if outerBorderAlignment == "BOTTOM" then
            if portraitPosition == "LEFT" then
                self.specIcon:SetPoint("TOPLEFT", self.classIcon, "TOPRIGHT", 0, 0)
            else
                self.specIcon:SetPoint("TOPRIGHT", self.classIcon, "TOPLEFT", 0, 0)
            end
        else
            if portraitPosition == "LEFT" then
                self.specIcon:SetPoint("BOTTOMLEFT", self.classIcon, "BOTTOMRIGHT", 0, 0)
            else
                self.specIcon:SetPoint("BOTTOMRIGHT", self.classIcon, "BOTTOMLEFT", 0, 0)
            end
        end
    else
        self.specIcon:Hide()
    end
end

--- Refresh player unit frame class strip spec icon (Respec build-match override, etc.).
function _G.FluxUnitFrames_RefreshPlayerSpecIcon()
    local f = ns.PlayerFrame
    if f and f.UpdatePlayerSpecIconOnly then
        f:UpdatePlayerSpecIconOnly()
    elseif f and f.UpdateOuterBorder then
        f:UpdateOuterBorder()
    end
end

local function GetSpecIcon(unit)
    if not UnitIsPlayer(unit) then return nil end

    -- Player unit
    if unit == "player" then
        if _G.FluxRespec_GetPlayerSpecIconOverride then
            local ok, o = pcall(_G.FluxRespec_GetPlayerSpecIconOverride)
            if ok and o and o ~= "" and o ~= 0 then
                return o
            end
        end
        if GetSpecialization then
            local specID = GetSpecialization()
            if specID then
                return select(4, GetSpecializationInfo(specID))
            end
        end
        if FLUX_API and FLUX_API.hasTalentTreeSpec then
            return GetSpecIconFromTalentTabs(false)
        end
        return nil
    end

    -- Target or other player units (enemies cannot be inspected)
    if UnitIsFriend and not UnitIsFriend("player", unit) then return nil end
    if UnitIsEnemy and UnitIsEnemy("player", unit) then return nil end

    local guid = UnitGUID(unit)
    if guid and specIconCache[guid] then
        local cached = specIconCache[guid]
        if (GetTime() - (cached.time or 0)) < SPEC_ICON_CACHE_TTL then
            return cached.icon
        end
    end

    -- Retail: try GetInspectSpecialization (friendly players only; enemies cannot be inspected)
    if CanInspectUnitForSpec(unit) and GetInspectSpecialization and GetSpecializationInfoByID then
        local specID = GetInspectSpecialization(unit)
        if specID and specID > 0 then
            return select(4, GetSpecializationInfoByID(specID))
        end
    end

    -- Talent-tree target: trigger inspect, return nil until cached
    if FLUX_API and FLUX_API.hasTalentTreeSpec and FLUX_API.hasInspectTalents and unit == "target" then
        TryInspectTarget()
    end
    return nil
end

--- Same spec icon as the player frame class strip (Retail: specialization; Classic: talent-tab heuristic).
--- Used by Respec UI so the talents row matches UnitFrames pixel-for-pixel.
function _G.FluxUnitFrames_GetPlayerSpecIcon()
    return GetSpecIcon("player")
end

-- Get difficulty color for level display
local function GetDifficultyColor(targetLevel)
    local playerLevel = UnitLevel("player")
    if not playerLevel or not targetLevel then
        return { r = 1, g = 1, b = 1 } -- White fallback
    end

    local levelDiff = targetLevel - playerLevel

    if levelDiff >= 5 then
        -- Skull (impossible)
        return { r = 1, g = 0.1, b = 0.1 } -- Dark red
    elseif levelDiff >= 3 then
        -- Red (deadly)
        return { r = 1, g = 0.1, b = 0.1 }
    elseif levelDiff >= 2 then
        -- Orange (difficult)
        return { r = 1, g = 0.5, b = 0.25 }
    elseif levelDiff >= -2 then
        -- Yellow (fair)
        return { r = 1, g = 1, b = 0 }
    elseif levelDiff >= -4 then
        -- Green (easy)
        return { r = 0.25, g = 0.75, b = 0.25 }
    else
        -- Gray (trivial)
        return { r = 0.7, g = 0.7, b = 0.7 }
    end
end

-- ---------------------------------------------------------------------------
-- Atlas Border Frame (covers both unit frame and portrait, layered on top)
-- ---------------------------------------------------------------------------
--- @param borderInsetY optional bottom inset for Border:ApplyTo on atlas shell (default 6); match CreateBaseFrame for focustarget (2)
function UF.CreateAtlasBorder(frame, borderInsetY)
    -- UIParent: ClearAllPoints is blocked on children of SecureUnitButton during combat lockdown
    local atlasBorderFrame = CreateFrame("Frame", nil, UIParent)
    atlasBorderFrame:SetFrameStrata(frame:GetFrameStrata())
    atlasBorderFrame:SetFrameLevel(frame:GetFrameLevel() + 2) -- 2 levels above individual borders
    frame.atlasBorderFrame = atlasBorderFrame
    atlasBorderFrame:SetShown(frame:IsShown())
    frame:HookScript("OnShow", function()
        if not frame.atlasBorderFrame then
            return
        end
        local want = true
        if UF.ShouldShowWatchedUnitFrame and (frame.unit == "target" or frame.unit == "focus"
            or frame.unit == "targettarget" or frame.unit == "focustarget"
            or frame.unit == "pet" or frame.unit == "pettarget") then
            want = UF.ShouldShowWatchedUnitFrame(frame)
        end
        frame.atlasBorderFrame:SetShown(want)
    end)
    frame:HookScript("OnHide", function()
        if frame.atlasBorderFrame then frame.atlasBorderFrame:Hide() end
    end)

    -- Disable mouse on atlas border frame - outer border handles all interaction
    atlasBorderFrame:EnableMouse(false)

    -- Apply border without backdrop (just the border lines)
    if ns.Border then
        ns.Border:ApplyTo(atlasBorderFrame, 2, 2, 2, borderInsetY or 6) -- Usually same as unit frame; focustarget passes 2

        -- Target / ToT: unit class border. Others: global accent.
        if frame.unit == "target" or frame.unit == "targettarget" or frame.unit == "focus" or frame.unit == "focustarget" then
            local color = GetUnitClassColor(frame.unit)
            ns.Border:SetBorderColor(atlasBorderFrame, color.r, color.g, color.b, 1)
        else
            ns.Border:SetClassColor(atlasBorderFrame, 1, false) -- No backdrop, just border
        end
    end

    return atlasBorderFrame
end

-- ---------------------------------------------------------------------------
-- Update Atlas Border (covers the combined unit + portrait area)
-- ---------------------------------------------------------------------------
function UF.UpdateAtlasBorder(self)
    if not self.atlasBorderFrame then return end

    local totalWidth = self:GetWidth()
    local totalHeight = self:GetHeight()
    local hasPortrait = UF.FrameUsesPortraitLayout(self)
    local portraitPosition = self.portraitPosition or "LEFT"
    local portraitSize = totalHeight -- Portrait is square with frame height

    -- atlasBorderFrame is parented to UIParent so ClearAllPoints is allowed in combat lockdown
    self.atlasBorderFrame:SetFrameStrata(self:GetFrameStrata())
    self.atlasBorderFrame:SetFrameLevel(self:GetFrameLevel() + 2)

    self.atlasBorderFrame:ClearAllPoints()

    if hasPortrait then
        -- Calculate combined dimensions (same as unit frame + portrait + gap)
        local combinedWidth = totalWidth + portraitSize  -- unit frame + portrait + small gap
        local combinedHeight = totalHeight -- Same height as unit frame

        self.atlasBorderFrame:SetSize(combinedWidth, combinedHeight)

        if portraitPosition == "LEFT" then
            -- Portrait is to the left, position atlas border starting from portrait
            self.atlasBorderFrame:SetPoint("TOPLEFT", self.PortraitFrame, "TOPLEFT", 0, 0)
        else -- RIGHT
            -- Portrait is to the right, position atlas border starting from unit frame
            self.atlasBorderFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
        end
    else
        -- No portrait, atlas border just encompasses the unit frame
        self.atlasBorderFrame:SetSize(totalWidth, totalHeight)
        self.atlasBorderFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    end
end

-- ---------------------------------------------------------------------------
-- Unit tooltip (custom SecureUnitButton frames do not get default Blizzard tips)
-- Use SetDefaultAnchor(UIParent) so Flux HUD reposition hook runs; ANCHOR_NONE
-- without a successful SetPoint parks the tip off-screen (looks like "no tip").
-- Refresh via GameTooltip.UpdateTooltip (not owner) so we keep UIParent ownership.
-- GameTooltip:SetUnit from here is tainted, so the tooltip health bar must not
-- compare secret health. Blizzard's script always does that compare.
-- ---------------------------------------------------------------------------
function UF.GuardTooltipStatusBar()
    local function OnValueChanged(self, value)
        if value == nil or (issecretvalue and issecretvalue(value)) then
            return
        end
        if not self.lockColor and self.SetStatusBarColor then
            self:SetStatusBarColor(0, 1, 0)
        end
    end
    local function Apply(bar)
        if not bar or not bar.SetScript or not bar.GetScript then
            return
        end
        if bar:GetScript("OnValueChanged") == OnValueChanged then
            return
        end
        pcall(bar.SetScript, bar, "OnValueChanged", OnValueChanged)
    end
    local bar = _G.GameTooltipStatusBar
    if not bar and GameTooltip then
        bar = GameTooltip.StatusBar
    end
    Apply(bar)
    local mixin = _G.GameTooltipUnitHealthBarMixin
    if mixin and not mixin._fluxSecretHealth then
        mixin._fluxSecretHealth = true
        if type(mixin.ResetUnitHealth) == "function" then
            local origReset = mixin.ResetUnitHealth
            function mixin:ResetUnitHealth(...)
                Apply(self)
                return origReset(self, ...)
            end
        end
        if type(mixin.UpdateUnitHealth) == "function" then
            local origUpdate = mixin.UpdateUnitHealth
            function mixin:UpdateUnitHealth(...)
                Apply(self)
                return origUpdate(self, ...)
            end
        end
    end
end

function UF.ShowUnitTooltip(anchorFrame, unit, fromUpdate)
    if not anchorFrame or not unit or not UnitExists(unit) then return end
    if GameTooltip:IsForbidden() then return end
    UF.GuardTooltipStatusBar()

    local guid = UnitGUID and UnitGUID(unit) or nil
    -- Raid-grid OnEnter: skip a full SetUnit rebuild when the unit id is unchanged.
    -- GameTooltip_OnUpdate still refreshes (fromUpdate).
    if not fromUpdate and guid and GameTooltip:IsShown()
        and GameTooltip._fluxUnitTipGuid == guid and GameTooltip.UpdateTooltip then
        return
    end
    GameTooltip._fluxUnitTipGuid = guid

    -- Pet-aura OnHide hook must not treat SetUnit rebuild as a real dismiss.
    GameTooltip._fluxUnitTipRebuilding = true

    if ns.ApplyHUDTooltipPosition then
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:SetUnit(unit)
        GameTooltip:Show()
        ns.ApplyHUDTooltipPosition()
    else
        GameTooltip_SetDefaultAnchor(GameTooltip, anchorFrame)
        GameTooltip:SetUnit(unit)
        GameTooltip:Show()
    end

    -- Keep tip alive while still hovered (GameTooltip_OnUpdate calls this).
    GameTooltip.UpdateTooltip = function()
        if GameTooltip:IsForbidden() then return end
        if not UnitExists(unit) or not anchorFrame:IsMouseOver() then
            GameTooltip.UpdateTooltip = nil
            return
        end
        UF.ShowUnitTooltip(anchorFrame, unit, true)
    end

    GameTooltip._fluxUnitTipRebuilding = nil
end

function UF.HideUnitTooltip()
    if GameTooltip:IsForbidden() then return end
    GameTooltip.UpdateTooltip = nil
    GameTooltip._fluxUnitTipGuid = nil
    GameTooltip:Hide()
end

-- ---------------------------------------------------------------------------
-- Mouseover highlight: ButtonHilight-Square + ADD (same asset as spec click).
-- Unit frames are large vs the tiny spec hit — higher default alpha so the glow reads clearly.
-- Optional: inset.alpha, r/g/b, vertexColor, blendMode, texture.
-- ---------------------------------------------------------------------------
local MOUSEOVER_HILITE_TEXTURE = "Interface\\Buttons\\ButtonHilight-Square"
local MOUSEOVER_HILITE_BLEND = "ADD"
-- Spec icon uses 0.25 on a small rect; full unit chrome needs more punch.
local MOUSEOVER_HILITE_ALPHA = 0.52
local MOUSEOVER_HILITE_R, MOUSEOVER_HILITE_G, MOUSEOVER_HILITE_B = 1, 0.88, 0.12

local function MouseoverHighlight_Layout(tex, clip)
    if not tex or not clip then return end
    local cw = clip:GetWidth()
    local ch = clip:GetHeight()
    if API and API.SafeGetNumber then
        cw = API.SafeGetNumber(cw, 0)
        ch = API.SafeGetNumber(ch, 0)
    else
        cw = cw or 0
        ch = ch or 0
    end
    if cw < 2 or ch < 2 then return end
    tex:ClearAllPoints()
    tex:SetAllPoints(clip)
    -- Full UV; optional tiny inset would only shrink the glow slightly
    if tex.SetTexCoord then
        tex:SetTexCoord(0, 1, 0, 1)
    end
end

--- @param hostFrame Region — outer border shell or full unit button
--- @param inset number|table|nil uniform padding, or { left, top, right, bottom, outH?, outV?, texture?, blendMode?, alpha?, r?, g?, b? } or { vertexColor = {r,g,b} }
--- @param frameLevelOffset number|nil added to host:GetFrameLevel() (default 3; use 1 inside outerBorderFrame)
--- @return Frame clip root (hidden until mouseover); texture fills clip (stretches with frame)
function UF.CreateMouseoverHighlight(hostFrame, inset, frameLevelOffset)
    if not hostFrame then return nil end
    frameLevelOffset = frameLevelOffset or 3

    local function field(t, key, idx, default)
        local v = t[key]
        if v == nil and idx then v = t[idx] end
        if v == nil then v = default end
        return v
    end

    local left, top, right, bottom, outH, outV
    local texPath, blendMode, texAlpha, vr, vg, vb
    if type(inset) == "table" then
        left = field(inset, "left", 1, 4)
        top = field(inset, "top", 2, 4)
        right = field(inset, "right", 3, 4)
        bottom = field(inset, "bottom", 4, 4)
        outH = inset.outH or inset.outsetH or 0
        outV = inset.outV or inset.outsetV or 0
        texPath = inset.texture or MOUSEOVER_HILITE_TEXTURE
        blendMode = inset.blendMode or MOUSEOVER_HILITE_BLEND
        texAlpha = inset.alpha
        if texAlpha == nil then texAlpha = MOUSEOVER_HILITE_ALPHA end
        local vc = inset.vertexColor
        if type(vc) == "table" and vc[1] and vc[2] and vc[3] then
            vr, vg, vb = vc[1], vc[2], vc[3]
        elseif inset.r ~= nil and inset.g ~= nil and inset.b ~= nil then
            vr, vg, vb = inset.r, inset.g, inset.b
        else
            vr, vg, vb = MOUSEOVER_HILITE_R, MOUSEOVER_HILITE_G, MOUSEOVER_HILITE_B
        end
    else
        local u = inset or 4
        left, top, right, bottom = u, u, u, u
        outH, outV = 0, 0
        texPath = MOUSEOVER_HILITE_TEXTURE
        blendMode = MOUSEOVER_HILITE_BLEND
        texAlpha = MOUSEOVER_HILITE_ALPHA
        vr, vg, vb = MOUSEOVER_HILITE_R, MOUSEOVER_HILITE_G, MOUSEOVER_HILITE_B
    end

    local clip = CreateFrame("Frame", nil, hostFrame)
    clip:SetFrameStrata(hostFrame:GetFrameStrata())
    clip:SetFrameLevel(hostFrame:GetFrameLevel() + frameLevelOffset)
    -- Expand past host: typical pattern TOPLEFT (-oh,+ov), BOTTOMRIGHT (+oh,-ov) when insets are 0
    clip:SetPoint("TOPLEFT", hostFrame, "TOPLEFT", left - outH, -top + outV)
    clip:SetPoint("BOTTOMRIGHT", hostFrame, "BOTTOMRIGHT", -right + outH, bottom - outV)
    clip:EnableMouse(false)

    local tex = clip:CreateTexture(nil, "ARTWORK")
    tex:SetVertexColor(vr, vg, vb)
    local okTex = pcall(function()
        tex:SetTexture(texPath)
    end)
    if not okTex then
        tex:SetTexture(MOUSEOVER_HILITE_TEXTURE)
    end
    pcall(function()
        tex:SetBlendMode(blendMode)
    end)
    tex:SetAlpha(texAlpha)

    local function layout()
        MouseoverHighlight_Layout(tex, clip)
    end

    clip._fluxLayoutMouseover = layout
    clip:SetScript("OnSizeChanged", layout)
    hostFrame:HookScript("OnSizeChanged", layout)
    C_Timer.After(0, layout)

    clip._fluxMouseoverTex = tex
    clip:Hide()
    return clip
end

-- ---------------------------------------------------------------------------
-- Outer Border Frame (even more outer, with background backdrop)
-- ---------------------------------------------------------------------------
function UF.CreateOuterBorder(frame)
    -- Create the most outer border frame with background backdrop (needs to be SecureUnitButton for click handling)
    local outerBorderFrame = CreateFrame("Button", "FluxUnitFrameOuter_"..frame.unit, frame, "SecureUnitButtonTemplate")
    SecureUnitButton_OnLoad(outerBorderFrame, frame.unit)
    outerBorderFrame:SetFrameLevel(frame:GetFrameLevel() + 5) -- Even higher level to ensure it's always on top
    frame.outerBorderFrame = outerBorderFrame

    -- Apply border with backdrop, but set backdrop to background layer
    if ns.Border then
        ns.Border:ApplyTo(outerBorderFrame, 2, 2, 2, 6) -- Symmetric padding for outer border

        -- Target / ToT: unit class border+backdrop. Others: global accent.
        if frame.unit == "target" or frame.unit == "targettarget" or frame.unit == "focus" or frame.unit == "focustarget" then
            local color = GetUnitClassColor(frame.unit)
            ns.Border:SetBorderColor(outerBorderFrame, color.r, color.g, color.b, 1)
            ns.Border:SetBackdropColor(outerBorderFrame, color.r * 0.4, color.g * 0.4, color.b * 0.4, 0.85)
        else
            ns.Border:SetClassColor(outerBorderFrame, 1, true) -- Enable backdrop
        end

        -- Move the backdrop to the most background layer
        if outerBorderFrame.FluxBorderFrame and outerBorderFrame.FluxBorderFrame.BackgroundFrame then
            outerBorderFrame.FluxBorderFrame.BackgroundFrame:SetFrameStrata("BACKGROUND")
            outerBorderFrame.FluxBorderFrame.BackgroundFrame:SetFrameLevel(0)

            -- Set backdrop to fill the outer border area minus border insets
            outerBorderFrame.FluxBorderFrame.BackgroundFrame:ClearAllPoints()
            outerBorderFrame.FluxBorderFrame.BackgroundFrame:SetPoint("TOPLEFT", outerBorderFrame, "TOPLEFT", 2, -4)
            outerBorderFrame.FluxBorderFrame.BackgroundFrame:SetPoint("BOTTOMRIGHT", outerBorderFrame, "BOTTOMRIGHT", -2, 2)
        end
    end

    -- Inside outer chrome (same inner box as BackgroundFrame); no outH/outV so it cannot extend past the border.
    frame.mouseoverHighlight = UF.CreateMouseoverHighlight(outerBorderFrame, {
        left = 2, top = 4, right = 2, bottom = 2,
        outH = 0,
        outV = 0,
    }, 11)

    local nameFont, levelFont, groupFont, pvpTimerFont = 16, 14, 12, 10
    if frame.unit == "focus" then
        nameFont, levelFont, groupFont, pvpTimerFont = 11, 10, 8, 7 -- ~30% smaller than defaults
    elseif frame.unit == "targettarget" or frame.unit == "focustarget" then
        nameFont = 12
    end

    -- Create name text display with same outline styling as HP/mana text
    local nameText = outerBorderFrame:CreateFontString(nil, "OVERLAY")
    nameText:SetPoint("CENTER", outerBorderFrame, "CENTER") -- Will be repositioned in UpdateOuterBorder
    nameText:SetFont("Fonts\\FRIZQT__.TTF", nameFont, "OUTLINE") -- Match FluxStatusBar styling with outline
    nameText:SetTextColor(1, 1, 1, 1) -- White text like FluxStatusBar
    frame.nameText = nameText

    -- Create pet name text display (for player frame)
    local petNameText = outerBorderFrame:CreateFontString(nil, "OVERLAY")
    petNameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- Smaller than nameText
    petNameText:SetTextColor(0.8, 0.8, 0.8, 1) -- Slightly gray
    petNameText:Hide()
    frame.petNameText = petNameText

    -- Create class icon for players (sized to outerBorderPadding, layered between border and backdrop)
    local classIcon = outerBorderFrame:CreateTexture(nil, "OVERLAY")
    classIcon:SetDrawLayer("OVERLAY", 1) -- Above backdrop, below borders
    classIcon:Hide() -- Hidden by default, shown only for players
    frame.classIcon = classIcon

    -- Create spec icon for players (sized same as class icon, layered between border and backdrop)
    local specIcon = outerBorderFrame:CreateTexture(nil, "OVERLAY")
    specIcon:SetDrawLayer("OVERLAY", 1) -- Above backdrop, below borders
    specIcon:Hide() -- Hidden by default, shown only for players
    frame.specIcon = specIcon

    -- Create combat status icon frame (separate frame with higher level to appear above level text + mouseover highlight)
    local combatIconFrame = CreateFrame("Frame", nil, outerBorderFrame)
    combatIconFrame:SetFrameLevel(outerBorderFrame:GetFrameLevel() + 22)
    combatIconFrame:SetAllPoints(outerBorderFrame)
    combatIconFrame:EnableMouse(false)
    local combatIcon = combatIconFrame:CreateTexture(nil, "OVERLAY")
    combatIcon:SetSize(32, 32) -- Match level text size
    combatIcon:Hide() -- Hidden by default
    frame.combatIcon = combatIcon
    frame.combatIconFrame = combatIconFrame

    -- Create level text display (same styling as name text)
    local levelText = outerBorderFrame:CreateFontString(nil, "OVERLAY")
    levelText:SetFont("Fonts\\FRIZQT__.TTF", levelFont, "OUTLINE") -- Slightly smaller than name text
    levelText:SetTextColor(1, 1, 1, 1) -- White text
    levelText:Hide() -- Hidden by default
    frame.levelText = levelText

    -- Create group number text display (for raids)
    local groupText = outerBorderFrame:CreateFontString(nil, "OVERLAY")
    groupText:SetFont("Fonts\\FRIZQT__.TTF", groupFont, "OUTLINE") -- Smaller than level text
    groupText:SetTextColor(1, 1, 0, 1) -- Yellow for visibility
    groupText:Hide() -- Hidden by default
    frame.groupText = groupText

    -- Create raid target icon (skull, square, triangle, etc.) - centered on HP bar
    local raidIcon = outerBorderFrame:CreateTexture(nil, "OVERLAY")
    raidIcon:SetSize(20, 20) -- Initial size, will be updated in UpdateOuterBorder
    raidIcon:SetPoint("CENTER", frame.Health, "CENTER", 0, 0) -- Center of HP bar
    raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons") -- Default texture
    raidIcon:SetAlpha(0.8) -- Slightly more transparent
    raidIcon:Hide() -- Hidden by default
    frame.raidIcon = raidIcon

    -- Create PvP/WarMode indicator (below name-strip text so labels stay readable)
    local pvpIcon = outerBorderFrame:CreateTexture(nil, "ARTWORK", nil, 2)
    pvpIcon:SetSize(20, 20) -- Initial size, will be updated to outerBorderPadding
    pvpIcon:SetAlpha(0.9)
    pvpIcon:Hide() -- Hidden by default
    frame.pvpIcon = pvpIcon

    -- Group status icons (leader / assistant / MT / MA / master looter) — opposite metadata corner
    local function CreateStatusIcon(texturePath)
        local tex = outerBorderFrame:CreateTexture(nil, "ARTWORK", nil, 2)
        tex:SetSize(16, 16)
        tex:SetTexture(texturePath)
        tex:SetAlpha(0.95)
        tex:Hide()
        return tex
    end
    frame.leaderIcon = CreateStatusIcon("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    frame.assistantIcon = CreateStatusIcon("Interface\\GroupFrame\\UI-Group-AssistantIcon")
    frame.mainTankIcon = CreateStatusIcon("Interface\\GroupFrame\\UI-Group-MainTankIcon")
    frame.mainAssistIcon = CreateStatusIcon("Interface\\GroupFrame\\UI-Group-MainAssistIcon")
    frame.masterLooterIcon = CreateStatusIcon("Interface\\GroupFrame\\UI-Group-MasterLooter")

    -- Name-strip labels above status/PvP art
    if nameText.SetDrawLayer then nameText:SetDrawLayer("OVERLAY", 7) end
    if petNameText.SetDrawLayer then petNameText:SetDrawLayer("OVERLAY", 7) end
    if levelText.SetDrawLayer then levelText:SetDrawLayer("OVERLAY", 7) end
    if groupText.SetDrawLayer then groupText:SetDrawLayer("OVERLAY", 7) end

    -- Create PvP timer text
    local pvpTimer = outerBorderFrame:CreateFontString(nil, "OVERLAY")
    pvpTimer:SetFont("Fonts\\FRIZQT__.TTF", pvpTimerFont, "OUTLINE")
    pvpTimer:SetTextColor(1, 1, 0, 1) -- Yellow text
    pvpTimer:Hide() -- Hidden by default
    frame.pvpTimer = pvpTimer
    if pvpTimer.SetDrawLayer then pvpTimer:SetDrawLayer("OVERLAY", 7) end

    -- PvP timer countdown only applies to the player frame; skip OnUpdate on target/ToT/pet.
    local pvpTimerFrame = CreateFrame("Frame")
    pvpTimerFrame:Hide()
    pvpTimerFrame.updateTimer = 0
    _G.FluxUI_PlayerPvpTimerDriver = pvpTimerFrame

    local function SyncPvpTimerDriver()
        if frame.unit ~= "player" then
            pvpTimerFrame:Hide()
            if frame.pvpTimer then
                frame.pvpTimer:Hide()
            end
            return
        end
        local pvpTimerValue = GetPVPTimer and GetPVPTimer() or 0
        if pvpTimerValue and pvpTimerValue > 0 then
            pvpTimerFrame:Show()
        else
            pvpTimerFrame:Hide()
            if frame.pvpTimer then
                frame.pvpTimer:Hide()
            end
        end
    end

    if frame.unit == "player" then
        pvpTimerFrame:SetScript("OnUpdate", function(self, elapsed)
            self.updateTimer = (self.updateTimer or 0) + elapsed
            if self.updateTimer >= 1 then
                self.updateTimer = 0
                if frame.pvpTimer then
                    local pvpTimerValue = GetPVPTimer and GetPVPTimer() or 0
                    if pvpTimerValue and pvpTimerValue > 0 then
                        local timeLeft = math.floor(pvpTimerValue / 1000)
                        if timeLeft > 0 and timeLeft <= 300 then
                            local minutes = math.floor(timeLeft / 60)
                            local seconds = timeLeft % 60
                            frame.pvpTimer:SetText(string.format("%d:%02d", minutes, seconds))
                            frame.pvpTimer:Show()
                        else
                            frame.pvpTimer:Hide()
                            self:Hide()
                        end
                    else
                        frame.pvpTimer:Hide()
                        self:Hide()
                    end
                end
            end
        end)
        pvpTimerFrame:SetScript("OnEvent", function()
            SyncPvpTimerDriver()
        end)
        pvpTimerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        pvpTimerFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
        SyncPvpTimerDriver()
    end

    -- Create border frames for class/spec icons (like separators)
    local function CreateIconBorder(parent)
        local border = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        -- Height will be set dynamically to match outerBorderPadding

        if ns.Border and ns.Border.CanUseAtlases and ns.Border:CanUseAtlases() then
            border:SetAtlas("battlefieldminimap-border-left", false)
            border:SetWidth(18) -- Thicker width for more prominence
        else
            border:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga")
            border:SetTexCoord(0.004, 0.066, 0.148, 0.672)
            border:SetWidth(18) -- Thicker width for more prominence
        end

        border:Hide() -- Hidden by default
        return border
    end

    frame.classIconLeftBorder = CreateIconBorder(outerBorderFrame)
    frame.classIconRightBorder = CreateIconBorder(outerBorderFrame)

    -- Enable mouse interaction on outer border frame - it handles all interaction for the entire unit frame area
    outerBorderFrame:EnableMouse(true)
    outerBorderFrame:SetMouseClickEnabled(true)
    outerBorderFrame:RegisterForClicks("AnyUp")
    outerBorderFrame:SetAttribute("unit", frame.unit)
    outerBorderFrame:SetAttribute("*type1", "target") -- Left click targets
    outerBorderFrame:SetAttribute("*type2", "togglemenu") -- Right click menu

    -- Register raid target update event on outer border frame
    outerBorderFrame:RegisterEvent("RAID_TARGET_UPDATE")

    -- Helper function to enable/disable right-click menus (called on outer border frame)
    outerBorderFrame.SetRightClickMenu = function(self, enabled)
        frame.enableRightClickMenu = enabled
        if enabled then
            self:SetAttribute("*type2", "togglemenu")
            self:SetAttribute("type2", "togglemenu")
        else
            self:SetAttribute("*type2", nil)
            self:SetAttribute("type2", nil)
        end
    end

    -- Update group text function (shows raid group number)
    local function UpdateGroupText()
        if not frame.groupText then return end

        -- Check if player is in raid
        local inRaid = UnitInRaid("player")
        if inRaid then
            -- Get the player's raid group number (1-8)
            local groupNumber = 1
            local PN = ns.Flux and ns.Flux.PlayerName

            -- Use GetRaidRosterInfo to get the correct subgroup
            for i = 1, GetNumGroupMembers() do
                local name, rank, subgroup = GetRaidRosterInfo(i)
                local isMe = false
                if PN and PN.IsUnitPlayer then
                    isMe = PN.IsUnitPlayer("raid" .. i)
                elseif UnitIsUnit then
                    local ok, same = pcall(UnitIsUnit, "raid" .. i, "player")
                    isMe = ok and same and true or false
                else
                    local playerName = API.SafeAccessibleString(UnitName("player"))
                    local rosterName = API.SafeAccessibleString(name)
                    isMe = playerName and rosterName and rosterName == playerName
                end
                if isMe then
                    groupNumber = subgroup
                    break
                end
            end

            -- Only update if the group number actually changed
            local currentText = frame.groupText:GetText()
            local newText = "Grp: " .. groupNumber

            if currentText ~= newText then
                frame.groupText:SetText(newText)
                frame.groupText:Show()
            end
        else
            -- Not in raid, hide the group text
            if frame.groupText:IsShown() then
                frame.groupText:Hide()
            end
        end
    end

    -- Store the update function for external access
    frame.UpdateGroupText = UpdateGroupText

    -- Forward mouseover events from outer border to main frame
    outerBorderFrame:SetScript("OnEnter", function(self)
        local mainFrame = self:GetParent()
        if frame.mouseoverHighlight and (not FluxUnitFrames_ShouldShowMouseover or FluxUnitFrames_ShouldShowMouseover(frame.unit)) then
            frame.mouseoverHighlight:Show()
        end
        UF.ShowUnitTooltip(self, frame.unit)
        if mainFrame:GetScript("OnEnter") then
            mainFrame:GetScript("OnEnter")(mainFrame)
        end
    end)

    outerBorderFrame:SetScript("OnLeave", function(self)
        local mainFrame = self:GetParent()
        if frame.mouseoverHighlight then
            frame.mouseoverHighlight:Hide()
        end
        UF.HideUnitTooltip()
        if mainFrame:GetScript("OnLeave") then
            mainFrame:GetScript("OnLeave")(mainFrame)
        end
    end)

    return outerBorderFrame
end

-- ---------------------------------------------------------------------------
-- Update Outer Border (same length as atlas border but +25px taller)
-- ---------------------------------------------------------------------------
-- Combat-safe border color updates (can run during combat)
-- Combat-safe border color updates (can run during combat)

local PORTRAIT_COMBAT_BORDER_R, PORTRAIT_COMBAT_BORDER_G, PORTRAIT_COMBAT_BORDER_B = 1, 0.08, 0.08
local PORTRAIT_COMBAT_BACK_R, PORTRAIT_COMBAT_BACK_G, PORTRAIT_COMBAT_BACK_B = 0.4, 0.03, 0.03

--- Solid fill on the portrait frame, behind the 3D model. The FluxBorder backdrop
--- lives on a BACKGROUND-strata frame and can slip behind other UI, so the model
--- sometimes shows the world instead of the red plate.
local function EnsurePortraitPlate(pf)
    if not pf then
        return nil
    end
    if pf.bg then
        return pf.bg
    end
    -- Anchors are set only while creating. SetPoint on a secure unit frame's
    -- regions is blocked in combat and reports ADDON_ACTION_BLOCKED.
    local bg = pf:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    if not (InCombatLockdown and InCombatLockdown()) then
        bg:SetPoint("TOPLEFT", pf, "TOPLEFT", 2, -2)
        bg:SetPoint("BOTTOMRIGHT", pf, "BOTTOMRIGHT", -2, 2)
    end
    pf.bg = bg
    return bg
end

function UF.SetFrameLevelIfChanged(frame, level)
    if not frame or not level then
        return
    end
    if level < 1 then
        level = 1
    elseif level > 65535 then
        level = 65535
    end
    if frame:GetFrameLevel() ~= level then
        frame:SetFrameLevel(level)
    end
end

local function PortraitCombatTintEnabled()
    if FluxUnitFrames_IsPortraitCombatTintEnabled then
        return FluxUnitFrames_IsPortraitCombatTintEnabled()
    end
    return true
end

--- Per-unit combat. A secret boolean cannot be tested, so the portrait stays on its normal colors.
local function UnitIsInCombat(unit)
    if not unit or type(UnitAffectingCombat) ~= "function" then
        return false
    end
    if UnitExists then
        local okExists, exists = pcall(UnitExists, unit)
        if not okExists or not SafeBooleanTest(exists, false) then
            return false
        end
    end
    local ok, inCombat = pcall(UnitAffectingCombat, unit)
    if not ok then
        return false
    end
    return SafeBooleanTest(inCombat, false)
end

--- Out-of-combat portrait chrome. Target/focus match UpdateBorderColors (class, or white for NPCs).
local function ApplyNormalPortraitChrome(self)
    local pf = self.PortraitFrame
    local unit = self.unit
    if not pf or not ns.Border then
        return
    end
    if unit == "target" or unit == "focus" or unit == "targettarget" or unit == "focustarget" then
        local color = { r = 1, g = 1, b = 1 }
        local isPlayer = false
        if UnitIsPlayer then
            local ok, v = pcall(UnitIsPlayer, unit)
            if ok then
                isPlayer = SafeBooleanTest(v, false)
            end
        end
        if isPlayer then
            color = ClassColorForUnit(unit) or color
        end
        local nr, ng, nb, br, bg, bb = UF.ForeverNpcChrome(unit)
        if nr then
            color = { r = nr, g = ng, b = nb }
            ns.Border:SetBorderColor(pf, nr, ng, nb, 1)
            ns.Border:SetBackdropColor(pf, br, bg, bb, 0.85)
        else
            ns.Border:SetBorderColor(pf, color.r, color.g, color.b, 1)
            ns.Border:SetBackdropColor(pf, color.r * 0.4, color.g * 0.4, color.b * 0.4, 0.85)
        end
        if pf.bg then
            pf.bg:Hide()
        end
    elseif unit == "pet" then
        local color = ClassColorForUnit("player") or { r = 0.5, g = 0.5, b = 0.5 }
        if not pf.bg then
            pf.bg = pf:CreateTexture(nil, "BACKGROUND")
            pf.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            pf.bg:ClearAllPoints()
            pf.bg:SetPoint("TOPLEFT", pf, "TOPLEFT", 2, -2)
            pf.bg:SetPoint("BOTTOMRIGHT", pf, "BOTTOMRIGHT", -2, 2)
        end
        if Border and Border.GetAccentMode and Border:GetAccentMode() == "atlas" then
            if Border.GetThemedBackdropFillRGB then
                local br, bg, bb = Border:GetThemedBackdropFillRGB()
                pf.bg:SetVertexColor(br, bg, bb, 1)
            else
                pf.bg:SetVertexColor(0.15, 0.15, 0.15, 1)
            end
        else
            pf.bg:SetVertexColor(color.r * 0.25, color.g * 0.25, color.b * 0.25, 1)
        end
        pf.bg:Show()
        ns.Border:SetClassColor(pf, 1, true)
        ns.Border:SetBorderColor(pf, color.r, color.g, color.b, 1)
    else
        if pf.bg then
            pf.bg:Hide()
        end
        ns.Border:SetClassColor(pf, 1, true)
    end
end

--- Red portrait border and backdrop while this frame's unit is in combat.
function UF.UpdatePortraitCombatTint(self)
    if not self or not self.PortraitFrame or not ns.Border then
        return
    end
    local pf = self.PortraitFrame
    if not pf.FluxBorderFrame then
        return
    end
    if PortraitCombatTintEnabled() and UnitIsInCombat(self.unit) then
        ns.Border:SetBorderColor(pf, PORTRAIT_COMBAT_BORDER_R, PORTRAIT_COMBAT_BORDER_G, PORTRAIT_COMBAT_BORDER_B, 1)
        ns.Border:SetBackdropColor(pf, PORTRAIT_COMBAT_BACK_R, PORTRAIT_COMBAT_BACK_G, PORTRAIT_COMBAT_BACK_B, 0.85)
        local plate = EnsurePortraitPlate(pf)
        if plate then
            plate:SetVertexColor(PORTRAIT_COMBAT_BACK_R, PORTRAIT_COMBAT_BACK_G, PORTRAIT_COMBAT_BACK_B, 1)
            plate:Show()
        end
        local outer = self.outerBorderFrame
        local outerBorder = outer and outer.FluxBorderFrame
        local borderLevel = outerBorder and (outerBorder:GetFrameLevel() + 2) or ((self:GetFrameLevel() or 0) + 17)
        UF.SetFrameLevelIfChanged(pf.FluxBorderFrame, borderLevel)
        return
    end
    ApplyNormalPortraitChrome(self)
    UF.SetFrameLevelIfChanged(pf.FluxBorderFrame, pf:GetFrameLevel() + 10)
end

function UF.UpdateBorderColors(self)
    if not self.unit then return end
    
    -- Determine if this frame relies on dynamic coloring (Target, TargetOfTarget)
    -- Or if it's the player frame (which might just stay Class Color or default)
    -- For this fix, we focus on Target and TargetTarget as requested.
    local useDynamicColor = (self.unit == "target" or self.unit == "targettarget"
        or self.unit == "focus" or self.unit == "focustarget")
    
    if useDynamicColor then
        local color = { r = 1, g = 1, b = 1 } -- Default white

        local npcR, npcG, npcB, npcBackR, npcBackG, npcBackB = UF.ForeverNpcChrome(self.unit)
        if UnitIsPlayer(self.unit) then
            local classColor = ClassColorForUnit(self.unit)
            if classColor then
                color = classColor
            end
        elseif npcR then
            color = { r = npcR, g = npcG, b = npcB }
        else
            -- NPC: No color tint (user requested no tint for non-players)
            color = { r = 1, g = 1, b = 1 }
        end

        -- Players: unit class. Forever NPCs: Blizzard status-bar gold. Other NPCs: untinted.
        local borderR, borderG, borderB = color.r, color.g, color.b
        local backR, backG, backB = color.r * 0.4, color.g * 0.4, color.b * 0.4
        if npcR and not UnitIsPlayer(self.unit) then
            backR, backG, backB = npcBackR, npcBackG, npcBackB
        end

        -- Update main frame border
        if ns.Border and self.FluxBorderFrame then
            ns.Border:SetBorderColor(self, borderR, borderG, borderB, 1)
            ns.Border:SetBackdropColor(self, backR, backG, backB, 0.85)
        end

        -- Update portrait border
        if self.PortraitFrame and self.PortraitFrame.FluxBorderFrame then
            ns.Border:SetBorderColor(self.PortraitFrame, borderR, borderG, borderB, 1)
            ns.Border:SetBackdropColor(self.PortraitFrame, backR, backG, backB, 0.85)
        end

        -- Update atlas border
        if self.atlasBorderFrame and self.atlasBorderFrame.FluxBorderFrame then
            ns.Border:SetBorderColor(self.atlasBorderFrame, borderR, borderG, borderB, 1)
        end

        -- Update outer border
        if self.outerBorderFrame and self.outerBorderFrame.FluxBorderFrame then
            ns.Border:SetBorderColor(self.outerBorderFrame, borderR, borderG, borderB, 1)
            ns.Border:SetBackdropColor(self.outerBorderFrame, backR, backG, backB, 0.85)

            -- Sync Separators with chrome accent
            if self.HealthPowerSeparator then
                self.HealthPowerSeparator:SetVertexColor(borderR, borderG, borderB, 1)
            end
            if self.PowerAdditionalSeparator then
                self.PowerAdditionalSeparator:SetVertexColor(borderR, borderG, borderB, 1)
            end
        end

        -- Update cast bar borders
        if self.CastBar then
            if self.CastBar.IconBorder and self.CastBar.IconBorder.FluxBorderFrame then
                ns.Border:SetBorderColor(self.CastBar.IconBorder, borderR, borderG, borderB, 1)
                ns.Border:SetBackdropColor(self.CastBar.IconBorder, backR, backG, backB, 0.85)
            end
            if self.CastBar.BorderFrame and self.CastBar.BorderFrame.FluxBorderFrame then
                ns.Border:SetBorderColor(self.CastBar.BorderFrame, borderR, borderG, borderB, 1)
                ns.Border:SetBackdropColor(self.CastBar.BorderFrame, backR, backG, backB, 0.85)
            end
        end

        -- Threat bar shell (target / focus)
        if self.ThreatBar and self.ThreatBar.FluxBorderFrame then
            ns.Border:SetBorderColor(self.ThreatBar, borderR, borderG, borderB, 1)
            ns.Border:SetBackdropColor(self.ThreatBar, backR, backG, backB, 0.85)
        end
    end

    -- After class/accent paint so a target or focus refresh cannot wipe combat red.
    UF.UpdatePortraitCombatTint(self)
end

-- Unit name on outer border: shrink font so long names fit (FontString sizing is combat-safe).
local NAME_FONT_PATH = "Fonts\\FRIZQT__.TTF"

local function GetOuterBorderContentWidth(self)
    local SN = API.SafeGetNumber
    local hasPortrait = UF.FrameUsesPortraitLayout(self)
    local portraitSize = SN(self:GetHeight(), 0)
    local totalWidth = SN(self:GetWidth(), 0)
    local w = totalWidth + (hasPortrait and portraitSize or 0)
    if self.outerBorderFrame then
        local obw = SN(self.outerBorderFrame:GetWidth(), 0)
        if obw > 1 then w = obw end
    end
    if w < 40 then
        w = totalWidth + (hasPortrait and portraitSize or 0)
    end
    return w
end

--- Side chrome reserve for the name (PvP / group status / group text / class / spec). Metadata uses its own corner budget.
local function GetNameStripSideReserve(self)
    local SN = API.SafeGetNumber
    local reserve = 12
    if self.unit == "focus" then
        reserve = reserve + 6 -- left padding (name is LEFT-justified on outer border)
    end
    local function addIfShown(tex, pad)
        if tex and tex:IsShown() then
            reserve = reserve + SN(tex:GetWidth(), 0) + (pad or 2)
        end
    end
    addIfShown(self.leaderIcon, 2)
    addIfShown(self.assistantIcon, 2)
    addIfShown(self.mainTankIcon, 2)
    addIfShown(self.mainAssistIcon, 2)
    addIfShown(self.masterLooterIcon, 2)
    addIfShown(self.pvpIcon, 8)
    if self.groupText and self.groupText:IsShown() and SafeBooleanTest(UnitIsUnit(self.unit, "player")) then
        reserve = reserve + SN(self.groupText:GetStringWidth(), 0) + 10
    end
    if self.classIcon and self.classIcon:IsShown() then
        reserve = reserve + SN(self.classIcon:GetWidth(), 0)
        if self.specIcon and self.specIcon:IsShown() then
            reserve = reserve + SN(self.specIcon:GetWidth(), 0)
        end
    end
    -- Compact metadata corner: reserve full width so the name cannot run into level/type.
    if self.levelText and self.levelText:IsShown() then
        reserve = reserve + SN(self.levelText:GetStringWidth(), 0) + 16
    end
    if self.combatIcon and self.combatIcon:IsShown() and self.unit == "player" and UnitAffectingCombat("player") then
        reserve = reserve + SN(self.combatIcon:GetWidth(), 0) + 4
    end
    return reserve
end

--- Short rarity labels so metadata stays compact in the name strip.
local function GetClassificationWord(classification)
    if classification == "elite" then
        return "Elite"
    elseif classification == "rare" then
        return "Rare"
    elseif classification == "rareelite" then
        return "Rare+"
    elseif classification == "worldboss" or classification == "boss" then
        return "Boss"
    end
    return nil
end

--- Progressive NPC metadata: level+rarity+type → level+rarity → level only.
--- Players: level only. Returns variants, isPlayer, level — or nil.
local function GetNpcLevelMetaVariants(self)
    if not self or not self.unit then return nil end
    if self.unit == "pet" or self.unit == "targettarget" or self.unit == "focustarget" then
        return nil
    end
    local level = API.SafeGetNumber(UnitLevel(self.unit), 0)
    if level <= 0 then return nil end

    if UnitIsPlayer(self.unit) then
        return { tostring(level) }, true, level
    end

    local classification = API.SafeAccessibleString(UnitClassification(self.unit))
    local creatureType = API.SafeAccessibleString(UnitCreatureType(self.unit))
    local classWord = GetClassificationWord(classification)
    local levelStr = tostring(level)
    local variants = {}
    local seen = {}

    local function push(s)
        if not s or s == "" or seen[s] then return end
        seen[s] = true
        variants[#variants + 1] = s
    end

    -- Prefer compact "72 Rare+ Humanoid" then drop type, then level only.
    if classWord and creatureType and creatureType ~= "" then
        push(levelStr .. " " .. classWord .. " " .. creatureType)
    end
    if classWord then
        push(levelStr .. " " .. classWord)
    elseif creatureType and creatureType ~= "" then
        push(levelStr .. " " .. creatureType)
    end
    push(levelStr)

    return variants, false, level
end

local function GetNameStripLevelFontSize(self)
    if self.unit == "focus" then
        return 10
    end
    return 13
end

--- Vertical center of the name strip relative to TOP* or BOTTOM* outer anchors.
local function GetNameStripCenterY(outerBorderAlignment, padding)
    padding = padding or 35
    if outerBorderAlignment == "BOTTOM" then
        return -padding / 2
    end
    return padding / 2
end

local function BinarySearchFontSize(fs, text, maxWidth, maxSize, minSize)
    local SN = API.SafeGetNumber
    fs:SetText(text)
    local lo, hi = minSize, maxSize
    local best = minSize
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        fs:SetFont(NAME_FONT_PATH, mid, "OUTLINE")
        local strW = SN(fs:GetStringWidth(), 0)
        if strW <= maxWidth then
            best = mid
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    fs:SetFont(NAME_FONT_PATH, best, "OUTLINE")
    return best
end

local function Utf8TextLen(text)
    if not text or text == "" then
        return 0
    end
    if utf8 and utf8.len then
        return utf8.len(text) or #text
    end
    if strlenutf8 then
        return strlenutf8(text) or #text
    end
    return #text
end

local function Utf8TextPrefix(text, n)
    if not text or text == "" or not n or n <= 0 then
        return ""
    end
    if utf8 and utf8.len and utf8.offset then
        local len = utf8.len(text)
        if len and n >= len then
            return text
        end
        local endByte = utf8.offset(text, n + 1, 1)
        if not endByte then
            return text
        end
        return string.sub(text, 1, endByte - 1)
    end
    local pos, bytes, chars = 1, #text, 0
    while pos <= bytes and chars < n do
        local b = string.byte(text, pos)
        local charLen = 1
        if b >= 240 then
            charLen = 4
        elseif b >= 224 then
            charLen = 3
        elseif b >= 192 then
            charLen = 2
        end
        pos = pos + charLen
        chars = chars + 1
    end
    return string.sub(text, 1, pos - 1)
end

--- Shrink a plain (no color codes) string with ellipsis until GetStringWidth fits.
local function TruncatePlainTextToWidth(fs, text, maxWidth, fontSize)
    local SN = API.SafeGetNumber
    fs:SetFont(NAME_FONT_PATH, fontSize, "OUTLINE")
    fs:SetText(text)
    if SN(fs:GetStringWidth(), 0) <= maxWidth then
        return text, false
    end
    local ellipsis = "..."
    fs:SetText(ellipsis)
    if SN(fs:GetStringWidth(), 0) > maxWidth then
        return ellipsis, true
    end
    local lo, hi = 1, Utf8TextLen(text)
    local best = ellipsis
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        local candidate = Utf8TextPrefix(text, mid) .. ellipsis
        fs:SetText(candidate)
        if SN(fs:GetStringWidth(), 0) <= maxWidth then
            best = candidate
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    fs:SetText(best)
    return best, true
end

--- Place compact level/rarity/type in the free name-strip corner (opposite class/spec), never on portrait.
local function LayoutNameStripLevelText(self)
    local levelFs = self.levelText
    if not levelFs then return end
    if FluxUnitFrames_ShouldShowLevel and not FluxUnitFrames_ShouldShowLevel(self.unit) then
        levelFs:Hide()
        return
    end
    if not self.nameText or self.unit == "pet"
        or self.unit == "targettarget" or self.unit == "focustarget" then
        levelFs:Hide()
        return
    end

    local variants, isPlayer, level = GetNpcLevelMetaVariants(self)
    if not variants then
        levelFs:Hide()
        self._fluxLevelMetaOnRight = nil
        return
    end

    local outer = self.outerBorderFrame
    if not outer then
        levelFs:Hide()
        self._fluxLevelMetaOnRight = nil
        return
    end

    local portraitPosition = self.portraitPosition or "LEFT"
    local outerBorderAlignment = self.outerBorderAlignment or "BOTTOM"
    local levelFontSize = GetNameStripLevelFontSize(self)

    -- Start with the shortest-preferred full variant; FitNameStripMetadata shortens if needed.
    levelFs:SetFont(NAME_FONT_PATH, levelFontSize, "OUTLINE")
    levelFs:SetText(variants[1])
    if isPlayer then
        local color = GetDifficultyColor(level)
        levelFs:SetTextColor(color.r, color.g, color.b, 1)
    else
        -- Soft gray-white so it reads as secondary to the name
        levelFs:SetTextColor(0.85, 0.85, 0.85, 1)
    end

    -- Opposite the class/spec corner so metadata never sits on the portrait column.
    -- When Pet/ToT second line is shown, lock level to the name row so it cannot overlap that line.
    levelFs:ClearAllPoints()
    local pad = self.outerBorderPadding or 35
    local yCenter = GetNameStripCenterY(outerBorderAlignment, pad)
    local useRight = (self.unit == "focus") or (portraitPosition == "LEFT")
    local xInset = useRight and -6 or 6
    local secondaryShown = self.petNameText and self.petNameText:IsShown()

    if secondaryShown and self.nameText then
        -- Same vertical band as the unit name; ToT/Pet stays below without crossing type/level.
        levelFs:SetPoint("TOP", self.nameText, "TOP", 0, 0)
        if useRight then
            levelFs:SetPoint("RIGHT", outer, "RIGHT", xInset, 0)
            levelFs:SetJustifyH("RIGHT")
        else
            levelFs:SetPoint("LEFT", outer, "LEFT", xInset, 0)
            levelFs:SetJustifyH("LEFT")
        end
    elseif outerBorderAlignment == "BOTTOM" then
        if useRight then
            levelFs:SetPoint("RIGHT", outer, "TOPRIGHT", xInset, yCenter)
            levelFs:SetJustifyH("RIGHT")
        else
            levelFs:SetPoint("LEFT", outer, "TOPLEFT", xInset, yCenter)
            levelFs:SetJustifyH("LEFT")
        end
    else -- TOP (classic target strip under bars)
        if useRight then
            levelFs:SetPoint("RIGHT", outer, "BOTTOMRIGHT", xInset, yCenter)
            levelFs:SetJustifyH("RIGHT")
        else
            levelFs:SetPoint("LEFT", outer, "BOTTOMLEFT", xInset, yCenter)
            levelFs:SetJustifyH("LEFT")
        end
    end

    levelFs:Show()
    self._fluxLevelMetaVariants = variants
    self._fluxLevelMetaIsPlayer = isPlayer
    self._fluxLevelMetaLevel = level
    self._fluxLevelMetaOnRight = useRight
end

--- Fit metadata into its corner without stealing the name's readable size.
local function FitNameStripMetadata(self)
    local levelFs = self.levelText
    if not levelFs or not levelFs:IsShown() then return end
    local variants = self._fluxLevelMetaVariants
    if not variants or #variants == 0 then return end

    local SN = API.SafeGetNumber
    local w = GetOuterBorderContentWidth(self)
    local secondaryShown = self.petNameText and self.petNameText:IsShown()
    -- Cap metadata so the centered name (and ToT/Pet line) keep the middle of the strip.
    local metaMax = math.max(36, math.floor(w * (secondaryShown and 0.22 or 0.28)))
    if self.unit == "focus" then
        metaMax = math.max(28, math.floor(w * 0.30))
    end

    local levelFontSize = GetNameStripLevelFontSize(self)
    local chosen = variants[#variants] -- fallback: level only
    for i = 1, #variants do
        levelFs:SetFont(NAME_FONT_PATH, levelFontSize, "OUTLINE")
        levelFs:SetText(variants[i])
        if SN(levelFs:GetStringWidth(), 0) <= metaMax then
            chosen = variants[i]
            break
        end
    end
    levelFs:SetText(chosen)
    -- Do not SetWidth here: a wide region shifts CENTER away from the digits (breaks rest icon overlay).
    if self._fluxLevelMetaIsPlayer and self._fluxLevelMetaLevel then
        local color = GetDifficultyColor(self._fluxLevelMetaLevel)
        levelFs:SetTextColor(color.r, color.g, color.b, 1)
    else
        levelFs:SetTextColor(0.85, 0.85, 0.85, 1)
    end
end

--- Combat beside level; resting always centered on top of the level number.
local function LayoutNameStripCombatIcon(self)
    local combatIcon = self.combatIcon
    if not combatIcon then return end
    if self.unit ~= "player" then
        combatIcon:Hide()
        return
    end
    if FluxUnitFrames_ShouldShowCombatIcon and not FluxUnitFrames_ShouldShowCombatIcon(self.unit) then
        combatIcon:Hide()
        return
    end

    local inCombat = UnitAffectingCombat("player")
    local isResting = IsResting()
    local padding = self.outerBorderPadding or 35
    local iconSize = math.min(28, math.max(20, padding - 8))

    if self.combatIconFrame then
        self.combatIconFrame:SetFrameLevel((self.outerBorderFrame and self.outerBorderFrame:GetFrameLevel() or 0) + 22)
    end

    if inCombat then
        combatIcon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        combatIcon:SetTexCoord(0.5, 1.0, 0.0, 0.5)
        combatIcon:SetSize(iconSize, iconSize)
        if combatIcon.SetDrawLayer then combatIcon:SetDrawLayer("OVERLAY", 6) end
        combatIcon:Show()
        if self.levelText and self.levelText:IsShown() then
            combatIcon:ClearAllPoints()
            if self._fluxLevelMetaOnRight then
                combatIcon:SetPoint("RIGHT", self.levelText, "LEFT", -2, 0)
            else
                combatIcon:SetPoint("LEFT", self.levelText, "RIGHT", 2, 0)
            end
        end
    elseif isResting then
        -- Always sit on top of the level number (visual center of the digits).
        combatIcon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        combatIcon:SetTexCoord(0, 0.5, 0.0, 0.5)
        local restSize = math.min(iconSize + 4, padding - 4)
        combatIcon:SetSize(restSize, restSize)
        if combatIcon.SetDrawLayer then combatIcon:SetDrawLayer("OVERLAY", 7) end
        combatIcon:Show()
        local levelFs = self.levelText
        if levelFs and levelFs:IsShown() then
            combatIcon:ClearAllPoints()
            -- Prefer true string center so RIGHT/LEFT justify cannot offset the Zzz.
            local sw = API.SafeGetNumber(levelFs:GetStringWidth(), 0)
            if sw > 0 and self._fluxLevelMetaOnRight then
                combatIcon:SetPoint("CENTER", levelFs, "RIGHT", -sw * 0.5, 0)
            elseif sw > 0 then
                combatIcon:SetPoint("CENTER", levelFs, "LEFT", sw * 0.5, 0)
            else
                combatIcon:SetPoint("CENTER", levelFs, "CENTER", 0, 0)
            end
        end
    else
        combatIcon:Hide()
    end
end

local function UnitIsMasterLooterOfGroup(unit)
    if not unit or not GetLootMethod then return false end
    local ok, method, partyID, raidID = pcall(GetLootMethod)
    if not ok or method ~= "master" then return false end
    if IsInRaid() then
        local index = UnitInRaid(unit)
        return index ~= nil and raidID ~= nil and index == raidID
    end
    if UnitIsUnit(unit, "player") then
        return partyID == 0
    end
    for i = 1, 4 do
        if UnitExists("party" .. i) and UnitIsUnit(unit, "party" .. i) and partyID == i then
            return true
        end
    end
    return false
end

local function HideNameStripStatusIcons(self)
    if self.leaderIcon then self.leaderIcon:Hide() end
    if self.assistantIcon then self.assistantIcon:Hide() end
    if self.mainTankIcon then self.mainTankIcon:Hide() end
    if self.mainAssistIcon then self.mainAssistIcon:Hide() end
    if self.masterLooterIcon then self.masterLooterIcon:Hide() end
end

local function GetShownTexWidth(tex)
    if not tex or not tex:IsShown() then return 0 end
    return API.SafeGetNumber(tex:GetWidth(), 0)
end

--- Dynamic PvP + group status icons.
--- - No Pet/ToT: sit on the name row (vertically locked to nameText), class/portrait side.
--- - With Pet/ToT: stay strip-centered with class/spec (name is nudged up for the second line).
--- Size = largest that still fits fully inside the outer-border name strip.
local function LayoutNameStripStatusAndPvpIcons(self, outerBorderPadding)
    local SN = API.SafeGetNumber
    local padding = outerBorderPadding or self.outerBorderPadding or 35
    local outer = self.outerBorderFrame
    local outerBorderAlignment = self.outerBorderAlignment or "BOTTOM"
    local portraitPosition = self.portraitPosition or "LEFT"
    local inset = 3
    local statusSize = math.max(12, math.min(padding - 18, 16))

    if self.unit == "targettarget" or self.unit == "focustarget" or self.unit == "pet" then
        HideNameStripStatusIcons(self)
        if self.pvpIcon then self.pvpIcon:Hide() end
        if self.pvpTimer then self.pvpTimer:Hide() end
        return
    end

    HideNameStripStatusIcons(self)

    local unit = self.unit
    local isPlayerUnit = UnitIsPlayer(unit)
    local inGroup = IsInGroup() or IsInRaid()
    local canShowGroupStatus = isPlayerUnit and inGroup and (UnitInParty(unit) or UnitInRaid(unit) or UnitIsUnit(unit, "player"))

    if canShowGroupStatus then
        local isLeader = UnitIsGroupLeader and SafeBooleanTest(UnitIsGroupLeader(unit))
        local isAssistant = (not isLeader) and UnitIsGroupAssistant and SafeBooleanTest(UnitIsGroupAssistant(unit))
        local isMainTank = GetPartyAssignment and SafeBooleanTest(GetPartyAssignment("MAINTANK", unit))
        local isMainAssist = GetPartyAssignment and SafeBooleanTest(GetPartyAssignment("MAINASSIST", unit))
        local isMasterLooter = UnitIsMasterLooterOfGroup(unit)

        local function applyIcon(tex, yes)
            if not tex then return end
            if yes then
                tex:SetSize(statusSize, statusSize)
                tex:Show()
            else
                tex:Hide()
            end
        end
        applyIcon(self.leaderIcon, isLeader)
        applyIcon(self.assistantIcon, isAssistant)
        applyIcon(self.mainTankIcon, isMainTank)
        applyIcon(self.mainAssistIcon, isMainAssist)
        applyIcon(self.masterLooterIcon, isMasterLooter)
    end

    local statusChain = {}
    local function pushStatus(tex)
        if tex and tex:IsShown() then
            statusChain[#statusChain + 1] = tex
        end
    end
    pushStatus(self.leaderIcon)
    pushStatus(self.assistantIcon)
    pushStatus(self.mainTankIcon)
    pushStatus(self.mainAssistIcon)
    pushStatus(self.masterLooterIcon)

    local hasPvp = self.pvpIcon and self.pvpIcon:IsShown()
    if not hasPvp and #statusChain == 0 then
        self._fluxStatusIconsOnRight = nil
        self._fluxStatusIconChainEnd = nil
        return
    end
    if not outer or not self.nameText then
        return
    end

    -- Class/portrait side (opposite level/type corner).
    local onLeft = (portraitPosition ~= "RIGHT")
    if self.unit == "focus" then
        onLeft = true
    end
    self._fluxStatusIconsOnRight = not onLeft

    local secondaryShown = self.petNameText and self.petNameText:IsShown()
    local classW = GetShownTexWidth(self.classIcon) + GetShownTexWidth(self.specIcon)
    local statusW = 0
    for i = 1, #statusChain do
        statusW = statusW + statusSize + 1
    end

    -- Largest square that fits in the name strip height (never past top/bottom chrome).
    local maxByStrip = math.max(14, padding - inset * 2)

    -- When locked to the name row, measure how far the name sits from strip edges.
    local maxByNameRow = maxByStrip
    if not secondaryShown and self.nameText then
        local nameFromEdge = padding / 2
        local p, _, rp, _, oy = self.nameText:GetPoint(1)
        oy = oy or 0
        if outerBorderAlignment == "BOTTOM" then
            -- Name anchored to TOP* of outer → |oy| is distance down from top.
            if rp == "TOP" or rp == "TOPLEFT" or rp == "TOPRIGHT" then
                nameFromEdge = math.abs(oy)
            end
            local maxUp = math.max(6, nameFromEdge - inset)
            local maxDown = math.max(6, padding - nameFromEdge - inset)
            maxByNameRow = math.max(14, math.floor(2 * math.min(maxUp, maxDown)))
        else
            -- Name anchored to BOTTOM* of outer → |oy| is distance up from bottom.
            if rp == "BOTTOM" or rp == "BOTTOMLEFT" or rp == "BOTTOMRIGHT" then
                nameFromEdge = math.abs(oy)
            end
            local maxDown = math.max(6, nameFromEdge - inset)
            local maxUp = math.max(6, padding - nameFromEdge - inset)
            maxByNameRow = math.max(14, math.floor(2 * math.min(maxUp, maxDown)))
        end
    end

    -- Horizontal room between class cluster and the name.
    local outerW = SN(outer:GetWidth(), 0)
    if outerW < 40 then outerW = GetOuterBorderContentWidth(self) end
    local nameW = SN(self.nameText:GetStringWidth(), 0)
    local halfFree = math.max(0, (outerW - nameW) * 0.5 - classW - inset - 4)
    if self.unit == "focus" then
        halfFree = math.max(16, classW > 0 and 20 or 28)
    end
    local maxByGap = math.max(14, math.floor(halfFree - statusW - 2))

    local pvpSize = math.min(maxByStrip, maxByNameRow, maxByGap, 36)
    pvpSize = math.max(16, pvpSize)

    if hasPvp then
        self.pvpIcon:SetSize(pvpSize, pvpSize)
        -- Crop soft halo so art does not read as past the border.
        self.pvpIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    -- Place PvP (or first status) as root.
    local root = hasPvp and self.pvpIcon or statusChain[1]
    root:ClearAllPoints()

    if secondaryShown then
        -- Pet/ToT: keep icons strip-centered with class/spec, not on the raised name line.
        local x = onLeft and (inset + classW + 2) or -(inset + classW + 2)
        local y = GetNameStripCenterY(outerBorderAlignment, padding)
        local point = onLeft and "LEFT" or "RIGHT"
        local relative
        if outerBorderAlignment == "BOTTOM" then
            relative = onLeft and "TOPLEFT" or "TOPRIGHT"
        else
            relative = onLeft and "BOTTOMLEFT" or "BOTTOMRIGHT"
        end
        -- Cap size again against strip when using strip-center (already maxByStrip).
        if hasPvp then
            local stripSize = math.min(pvpSize, maxByStrip)
            self.pvpIcon:SetSize(stripSize, stripSize)
        end
        root:SetPoint(point, outer, relative, x, y)
    else
        -- At the unit name: same vertical center as nameText, tucked on the class side.
        if onLeft then
            root:SetPoint("RIGHT", self.nameText, "LEFT", -3, 0)
        else
            root:SetPoint("LEFT", self.nameText, "RIGHT", 3, 0)
        end
        -- If class icons would overlap, sit just inside of them instead of under the name.
        if classW > 0 and hasPvp then
            -- Re-check: prefer name attachment; class side gap already sized. Done.
        end
    end

    -- Chain status icons from PvP outward (PvP stays nearest the name).
    if hasPvp then
        local prev = root
        for i = #statusChain, 1, -1 do
            local tex = statusChain[i]
            tex:ClearAllPoints()
            if onLeft then
                tex:SetPoint("RIGHT", prev, "LEFT", -1, 0)
            else
                tex:SetPoint("LEFT", prev, "RIGHT", 1, 0)
            end
            prev = tex
        end
        self._fluxStatusIconChainEnd = (#statusChain > 0) and statusChain[1] or root
    else
        local prev = root
        for i = 2, #statusChain do
            local tex = statusChain[i]
            tex:ClearAllPoints()
            if onLeft then
                tex:SetPoint("RIGHT", prev, "LEFT", -1, 0)
            else
                tex:SetPoint("LEFT", prev, "RIGHT", 1, 0)
            end
            prev = tex
        end
        self._fluxStatusIconChainEnd = prev
    end
end

local function ClampPvpIconInOuterBorder(self, outerBorderPadding)
    LayoutNameStripStatusAndPvpIcons(self, outerBorderPadding)
end

local function FitUnitFrameNameText(self, unitName, maxSize, minSize)
    local fs = self.nameText
    -- v12+: UnitName() may be a secret string; never compare, concat, or use as cache key raw.
    unitName = API.SafeAccessibleString(unitName)
    if not fs or not unitName or unitName == "" or self.unit == "pet" then return end
    if not fs:IsShown() then return end

    FitNameStripMetadata(self)

    local SN = API.SafeGetNumber
    local compactName = (self.unit == "targettarget" or self.unit == "focustarget")
    local twoLineName = self.petNameText and self.petNameText:IsShown() and true or false
    local w = GetOuterBorderContentWidth(self)
    local sideReserve = GetNameStripSideReserve(self)
    local minBudget = compactName and 28 or 40
    local nameBudget = math.max(minBudget, w - sideReserve)
    maxSize = maxSize or 16
    -- Compact ToT / focus-target, or a Pet/ToT second line: shrink in place (same anchor).
    if compactName or twoLineName then
        maxSize = math.min(maxSize, 12)
    end
    -- Keep names readable on full frames; allow smaller type on ToT and two-line strips.
    if compactName or twoLineName then
        minSize = 7
    else
        minSize = math.max(minSize or 8, (self.unit == "focus") and 7 or 10)
    end

    local fitKey = unitName .. "\0" .. math.floor(nameBudget + 0.5) .. "\0" .. maxSize .. "\0" .. minSize
        .. (twoLineName and "\0s" or "\0")
        .. (compactName and "\0c" or "")
    if fs._fluxNameFitKey == fitKey then
        -- PaintUnitFrameNameText may have restored the full name since last fit.
        if SN(fs:GetStringWidth(), 0) <= nameBudget then
            return
        end
    end
    fs._fluxNameFitKey = fitKey
    fs._fluxNameNudgeApplied = nil
    if fs.SetWidth then
        fs:SetWidth(nameBudget)
        if fs.SetWordWrap then
            fs:SetWordWrap(false)
        end
    end
    local best = BinarySearchFontSize(fs, unitName, nameBudget, maxSize, minSize)
    if SN(fs:GetStringWidth(), 0) > nameBudget then
        TruncatePlainTextToWidth(fs, unitName, nameBudget, best)
    end
end

--- Fit Pet / ToT second line under the name without changing format or anchors.
local function FitUnitFrameSecondaryNameText(self)
    local fs = self.petNameText
    if not fs or not fs:IsShown() then return end

    local SN = API.SafeGetNumber
    local w = GetOuterBorderContentWidth(self)
    -- Keep ToT/Pet out of the level/type corner and class/PvP side chrome.
    local sidePad = 16
    if self.levelText and self.levelText:IsShown() then
        sidePad = sidePad + SN(self.levelText:GetStringWidth(), 0) + 16
    end
    if self.classIcon and self.classIcon:IsShown() then
        sidePad = sidePad + SN(self.classIcon:GetWidth(), 0)
        if self.specIcon and self.specIcon:IsShown() then
            sidePad = sidePad + SN(self.specIcon:GetWidth(), 0)
        end
    end
    if self.pvpIcon and self.pvpIcon:IsShown() then
        sidePad = sidePad + SN(self.pvpIcon:GetWidth(), 0) + 8
    end
    local maxWidth = math.max(24, w - sidePad)
    local maxSize, minSize = 12, 8
    -- Placement-2 ToT line shares the target strip; keep it smaller than the unit name.
    if self.unit == "target" then
        maxSize, minSize = 10, 7
    end
    local text = fs:GetText() or ""
    if text == "" then return end

    fs:SetJustifyH("CENTER")
    if fs.SetWidth then
        fs:SetWidth(maxWidth)
        if fs.SetWordWrap then fs:SetWordWrap(false) end
    end

    local fitKey = text .. "\0" .. math.floor(maxWidth + 0.5) .. "\0" .. maxSize .. "\0" .. minSize
    if fs._fluxSecondaryFitKey == fitKey then
        -- Text may have been reset to the full form since last fit; re-check width.
        if SN(fs:GetStringWidth(), 0) <= maxWidth then
            return
        end
    end

    local best = BinarySearchFontSize(fs, text, maxWidth, maxSize, minSize)
    local strW = SN(fs:GetStringWidth(), 0)
    if strW <= maxWidth then
        fs._fluxSecondaryFitKey = fitKey
        return
    end

    -- Soft-truncate the name portion after "Pet: " / "ToT: " while keeping level suffix.
    local prefix, rest = text:match("^(Pet: )(.+)$")
    local isTot = false
    if not prefix then
        local plain = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        prefix, rest = plain:match("^(ToT: )(.+)$")
        isTot = prefix ~= nil
        if not rest then
            fs._fluxSecondaryFitKey = fitKey
            return
        end
    end

    local levelSuffix = rest:match("(%s*%[%d+%])$") or ""
    local namePart = rest:sub(1, #rest - #levelSuffix)
    namePart = namePart:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    fs:SetFont(NAME_FONT_PATH, best, "OUTLINE")
    fs:SetText(prefix .. levelSuffix)
    local suffixW = SN(fs:GetStringWidth(), 0)
    local nameBudget = math.max(12, maxWidth - suffixW)
    local truncated = select(1, TruncatePlainTextToWidth(fs, namePart, nameBudget, best))

    if isTot then
        local unit = "targettarget"
        local colored = truncated
        if UF.UnitTokenIsResolved("target") and UF.UnitTokenIsResolved(unit) then
            local function toHex(r, g, b)
                return string.format(
                    "%02x%02x%02x",
                    math.floor(r * 255 + 0.5),
                    math.floor(g * 255 + 0.5),
                    math.floor(b * 255 + 0.5)
                )
            end
            if UnitIsPlayer(unit) then
                local _, class = UnitClass(unit)
                class = API.SafeAccessibleString(class)
                local c = class and RAID_CLASS_COLORS[class]
                if c then
                    colored = string.format("|cff%s%s|r", toHex(c.r, c.g, c.b), truncated)
                end
            else
                local reaction = UnitReaction(unit, "player")
                local r, g, b = 1, 1, 1
                if reaction then
                    if reaction >= 5 then
                        r, g, b = 0, 1, 0
                    elseif reaction >= 4 then
                        r, g, b = 1, 1, 0
                    else
                        r, g, b = 1, 0, 0
                    end
                end
                colored = string.format("|cff%s%s|r", toHex(r, g, b), truncated)
            end
        end
        local levelRich = (levelSuffix ~= "") and string.format("|cffaaaaaa%s|r", levelSuffix) or ""
        fs:SetText(prefix .. colored .. levelRich)
    else
        fs:SetText(prefix .. truncated .. levelSuffix)
    end
    fs._fluxSecondaryFitKey = fitKey
end

function UF.UpdateOuterBorder(self)
    -- Validate this is one of our frames, not a Blizzard CompactRaidFrame
    if not IsFluxUnitFrame(self.unit) then return end
    
    if not self.outerBorderFrame then return end

    -- Combat Lockdown Check: Defer layout updates if in combat, but allow visual updates
    local inCombat = InCombatLockdown()
    if inCombat and not self.needsOuterBorderUpdate then
        self.needsOuterBorderUpdate = true
        -- Register event to update layout after combat
        if not self:IsEventRegistered("PLAYER_REGEN_ENABLED") then
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
    end

    -- Update border colors (combat-safe part)
    UF.UpdateBorderColors(self)

    local totalWidth = self:GetWidth()
    local totalHeight = self:GetHeight()
    local hasPortrait = UF.FrameUsesPortraitLayout(self)
    local portraitPosition = self.portraitPosition or "LEFT"
    local portraitSize = totalHeight -- Portrait is square with frame height
    local outerBorderAlignment = self.outerBorderAlignment or "BOTTOM" -- "BOTTOM" or "TOP"
    local outerBorderPadding = self.outerBorderPadding or 35 -- How much taller the outer border is
    local totPos2Minimal = self.unit == "targettarget"
        and FluxUnitFrames_GetPlayerTargetPlacement
        and FluxUnitFrames_GetPlayerTargetPlacement() == 2
        and FluxUnitFrames_ShouldUseFlux("player")
        and FluxUnitFrames_ShouldUseFlux("target")
    if totPos2Minimal then
        outerBorderPadding = 0
    end

    -- Update name text
    if self.nameText then
        if totPos2Minimal then
            self.nameText:Hide()
        else
        local unitName = PaintUnitFrameNameText(self, self.nameText)

        -- Set text color based on unit type
        if UnitIsPlayer(self.unit) then
            -- Class color for players (v12+: class token may be a secret string)
            local _, class = UnitClass(self.unit)
            class = API.SafeAccessibleString(class)
            local color = class and RAID_CLASS_COLORS[class]
            if color then
                self.nameText:SetTextColor(color.r, color.g, color.b, 1)
            else
                self.nameText:SetTextColor(1, 1, 1, 1) -- White fallback
            end
        else
            -- For target and targettarget frame NPCs: use hostility colors
            if self.unit == "target" or self.unit == "targettarget"
                or self.unit == "focus" or self.unit == "focustarget" then
                local reaction = UnitReaction(self.unit, "player")
                if reaction then
                    if reaction >= 5 then
                        self.nameText:SetTextColor(0, 1, 0, 1) -- Green for friendly
                    elseif reaction >= 4 then
                        self.nameText:SetTextColor(1, 1, 0, 1) -- Yellow for neutral
                    else
                        self.nameText:SetTextColor(1, 0, 0, 1) -- Red for hostile
                    end
                else
                    self.nameText:SetTextColor(1, 1, 1, 1) -- White fallback
                end
            else
                -- For other frames (like player frame), use neutral colors for NPCs
                self.nameText:SetTextColor(1, 1, 1, 1) -- White for NPCs in non-target frames
            end
        end

        -- Position based on alignment and padding (Protected in combat)
        if not inCombat then
            self.nameText:ClearAllPoints()
            if self.unit == "targettarget" or self.unit == "focustarget" then
                -- Target of Target / Focus Target: Lower the name text position
                if outerBorderAlignment == "BOTTOM" then
                    -- Position lower than normal for target of target
                    self.nameText:SetPoint("CENTER", self.outerBorderFrame, "TOP", 0, -outerBorderPadding/2 - 4)
                else -- "TOP"
                    -- Position lower than normal for target of target
                    self.nameText:SetPoint("CENTER", self.outerBorderFrame, "BOTTOM", 0, outerBorderPadding/2 - 14)
                end
            elseif self.unit == "pet" then
                -- Hide name on Pet Frame
                self.nameText:Hide()
            else
                if outerBorderAlignment == "BOTTOM" then
                    -- Position at top center of the outer border padding area
                    local nameYOffset
                    if self.unit == "player" then
                        nameYOffset = -2
                    elseif self.unit == "focus" then
                        -- Compact focus chrome: default +4 for other units sits too high vs the padding strip
                        nameYOffset = -4
                    elseif self.unit == "target" then
                        --- Bottom-anchored target uses the same name strip as the player frame.
                        nameYOffset = -2
                    else
                        nameYOffset = 4
                    end
                    if self.unit == "focus" then
                        self.nameText:SetJustifyH("LEFT")
                        self.nameText:SetPoint("LEFT", self.outerBorderFrame, "TOPLEFT", 6, -outerBorderPadding/2 + nameYOffset)
                    else
                        self.nameText:SetJustifyH("CENTER")
                        self.nameText:SetPoint("CENTER", self.outerBorderFrame, "TOP", 0, -outerBorderPadding/2 + nameYOffset)
                    end
                else -- "TOP"
                    -- Position at bottom center of the outer border padding area
                    if self.unit == "focus" then
                        self.nameText:SetJustifyH("LEFT")
                        self.nameText:SetPoint("LEFT", self.outerBorderFrame, "BOTTOMLEFT", 6, outerBorderPadding/2 - 4)
                    else
                        self.nameText:SetJustifyH("CENTER")
                        self.nameText:SetPoint("CENTER", self.outerBorderFrame, "BOTTOM", 0, outerBorderPadding/2 - 4)
                    end
                end
            end
            --- totPos2Minimal uses :Hide() above; restoring placement/classic layout must show the string again.
            if self.unit ~= "pet" and self.nameText then
                self.nameText:Show()
            end
        end

        if (self.unit == "targettarget" or self.unit == "focustarget") and self.levelText then
            self.levelText:Hide()
        end

        -- Update name positioning and pet name (Safe in combat as they are FontStrings)
        if self.unit == "player" and self.petNameText then
            if PlayerUnitUsesFluxPetLayout() then
                local petName = API.SafeAccessibleString(UnitName("pet"))
                local petLevel = API.SafeGetNumber(UnitLevel("pet"), 0)
                local levelStr = (petLevel > 0) and (" ["..petLevel.."]") or ""
                if petName then
                    self.petNameText:SetText("Pet: "..petName..levelStr)
                else
                    self.petNameText:SetText("Pet:"..levelStr)
                end
                self.petNameText:ClearAllPoints()
                -- Positioned under player name
                self.petNameText:SetPoint("TOP", self.nameText, "BOTTOM", 0, -2)
                self.petNameText:Show()
                
                -- Nudge player name UP to make room (font size finalized after layout via FitUnitFrameNameText)
                self.nameText:ClearAllPoints()
                if outerBorderAlignment == "BOTTOM" then
                    -- Move UP by roughly 10px from normal (-20 -> -10)
                    self.nameText:SetPoint("CENTER", self.outerBorderFrame, "TOP", 0, -12)
                else -- "TOP"
                    -- Move DOWN visually (which is UP relatively to the padding)
                    self.nameText:SetPoint("CENTER", self.outerBorderFrame, "BOTTOM", 0, 10)
                end
            else
                -- Restore default when no pet exists (font size finalized after layout via FitUnitFrameNameText)
                self.petNameText:Hide()

                -- FontStrings stay movable in combat. The secure frame itself is not touched.
                self.nameText:ClearAllPoints()
                if outerBorderAlignment == "BOTTOM" then
                    self.nameText:SetPoint("CENTER", self.outerBorderFrame, "TOP", 0, -outerBorderPadding/2 + -2)
                else
                    self.nameText:SetPoint("CENTER", self.outerBorderFrame, "BOTTOM", 0, outerBorderPadding/2 - 4)
                end
            end
        elseif self.unit == "target" and self.petNameText
            and FluxUnitFrames_ShouldUseFlux
            and FluxUnitFrames_ShouldUseFlux("target")
        then
            local pos2 = FluxUnitFrames_GetPlayerTargetPlacement
                and FluxUnitFrames_GetPlayerTargetPlacement() == 2
            if not pos2 then
                --- Classic layout: ToT name belongs on the Flux ToT frame, not as a second line on target.
                self.petNameText:Hide()
                if self.nameText then
                    self.nameText:ClearAllPoints()
                    if outerBorderAlignment == "BOTTOM" then
                        self.nameText:SetJustifyH("CENTER")
                        self.nameText:SetPoint("CENTER", self.outerBorderFrame, "TOP", 0, -outerBorderPadding/2 + 4)
                    else
                        self.nameText:SetJustifyH("CENTER")
                        self.nameText:SetPoint("CENTER", self.outerBorderFrame, "BOTTOM", 0, outerBorderPadding/2 - 4)
                    end
                    self.nameText:Show()
                end
            elseif FluxUnitFrames_ShouldUseFlux("targettarget") then
                -- Same as player+pet: lift the name whenever the nested frame exists,
                -- including when you target yourself (targettarget == player).
                local totResolved = UF.UnitTokenIsResolved("targettarget")
                if totResolved then
                    self.petNameText:SetText(FluxTargetTotPetNameRichText())
                    self.petNameText:ClearAllPoints()
                    self.petNameText:SetPoint("TOP", self.nameText, "BOTTOM", 0, -2)
                    self.petNameText:Show()
                    self.nameText:ClearAllPoints()
                    if outerBorderAlignment == "BOTTOM" then
                        self.nameText:SetPoint("CENTER", self.outerBorderFrame, "TOP", 0, -12)
                    else
                        self.nameText:SetPoint("CENTER", self.outerBorderFrame, "BOTTOM", 0, 10)
                    end
                    self.nameText:Show()
                else
                    self.petNameText:Hide()
                    if self.nameText then
                        self.nameText:ClearAllPoints()
                        if outerBorderAlignment == "BOTTOM" then
                            local nameYOffset = (FluxUnitFrames_GetPlayerTargetPlacement() == 2) and -2 or 4
                            self.nameText:SetJustifyH("CENTER")
                            self.nameText:SetPoint("CENTER", self.outerBorderFrame, "TOP", 0, -outerBorderPadding/2 + nameYOffset)
                        else
                            self.nameText:SetJustifyH("CENTER")
                            self.nameText:SetPoint("CENTER", self.outerBorderFrame, "BOTTOM", 0, outerBorderPadding/2 - 4)
                        end
                        self.nameText:Show()
                    end
                end
            else
                self.petNameText:Hide()
            end
        end

        -- Pet or ToT appeared or left: move health and power text now, including
        -- in combat. Later bar ticks keep the point (PlaceBarText skips unchanged keys).
        if self.unit == "player" or self.unit == "target" then
            local nested = (self.unit == "player" and PlayerUnitUsesFluxPetLayout())
                or (self.unit == "target" and TargetUnitUsesSideBySideTotTextLayout(self.unit))
            if self._fluxNestedTextLayout ~= nested then
                self._fluxNestedTextLayout = nested
                UF.UpdateHealth(self, self.unit)
                UF.UpdatePower(self, self.unit)
            end
        end

        end

        
        -- Special case for Pet frame in combat: ensure name is hidden
        if inCombat and self.unit == "pet" then
            self.nameText:Hide()
        end

        if totPos2Minimal then
            if self.classIcon then self.classIcon:Hide() end
            if self.specIcon then self.specIcon:Hide() end
            if self.levelText then self.levelText:Hide() end
            if self.classIconLeftBorder then self.classIconLeftBorder:Hide() end
            if self.classIconRightBorder then self.classIconRightBorder:Hide() end
        end

        -- Update class icon for players
        if self.classIcon and not totPos2Minimal then
            if FluxUnitFrames_ShouldShowClassIcon and not FluxUnitFrames_ShouldShowClassIcon(self.unit) then
                self.classIcon:Hide()
                if self.specIcon then self.specIcon:Hide() end
                if self.classIconLeftBorder then self.classIconLeftBorder:Hide() end
                if self.classIconRightBorder then self.classIconRightBorder:Hide() end
            elseif UnitIsPlayer(self.unit) then
                -- Show and position class icon for players
                local _, class = UnitClass(self.unit)
                if class then
                    -- Try different class icon naming conventions
                    local classIconPath = "Interface\\Icons\\ClassIcon_" .. class
                    self.classIcon:SetTexture(classIconPath)

                    -- Verify texture loaded, fallback if needed
                    if not self.classIcon:GetTexture() then
                        -- Try alternative naming (some clients use different format)
                        classIconPath = "Interface\\Icons\\Class_" .. class
                        self.classIcon:SetTexture(classIconPath)
                    end

                    -- Size the icon to match outerBorderPadding
                    self.classIcon:SetSize(outerBorderPadding, outerBorderPadding)
                    self.classIcon:Show()

                    -- Position in the appropriate corner
                    self.classIcon:ClearAllPoints()

                    if outerBorderAlignment == "BOTTOM" then
                        -- Top corner positioning
                        if portraitPosition == "LEFT" then
                            -- Top-left corner of outer border
                            self.classIcon:SetPoint("TOPLEFT", self.outerBorderFrame, "TOPLEFT", 0, -4)
                        else -- RIGHT
                            -- Top-right corner of outer border
                            self.classIcon:SetPoint("TOPRIGHT", self.outerBorderFrame, "TOPRIGHT", 0, -4)
                        end
                    else -- "TOP"
                        -- Bottom corner positioning
                        if portraitPosition == "LEFT" then
                            -- Bottom-left corner of outer border
                            self.classIcon:SetPoint("BOTTOMLEFT", self.outerBorderFrame, "BOTTOMLEFT", 0, 4)
                        else -- RIGHT
                            -- Bottom-right corner of outer border
                            self.classIcon:SetPoint("BOTTOMRIGHT", self.outerBorderFrame, "BOTTOMRIGHT", 0, 4)
                        end
                    end
                else
                    self.classIcon:Hide()
                end
            else
                -- Hide class icon for NPCs
                self.classIcon:Hide()
            end

            -- Update spec icon for players (skip compact ToT / focus-target so the name can fit)
            if self.specIcon then
                if FluxUnitFrames_ShouldShowClassIcon and not FluxUnitFrames_ShouldShowClassIcon(self.unit) then
                    self.specIcon:Hide()
                elseif self.unit == "targettarget" or self.unit == "focustarget" then
                    self.specIcon:Hide()
                elseif UnitIsPlayer(self.unit) then
                    -- Show and position spec icon for players
                    local specIconPath = GetSpecIcon(self.unit)
                    if specIconPath then
                        self.specIcon:SetTexture(specIconPath)

                        -- Verify texture loaded, fallback if needed
                        if not self.specIcon:GetTexture() and specIconPath then
                            -- Try alternative paths or simplified names
                            local altPath = specIconPath:gsub("Interface\\Icons\\", "")
                            if altPath ~= specIconPath then
                                self.specIcon:SetTexture("Interface\\Icons\\" .. altPath)
                            end
                        end

                        -- Size the icon to match outerBorderPadding
                        self.specIcon:SetSize(outerBorderPadding, outerBorderPadding)
                        self.specIcon:Show()

                        -- Position next to class icon (no gap)
                        self.specIcon:ClearAllPoints()

                        if outerBorderAlignment == "BOTTOM" then
                            -- Top positioning
                            if portraitPosition == "LEFT" then
                                -- Right of class icon (top area)
                                self.specIcon:SetPoint("TOPLEFT", self.classIcon, "TOPRIGHT", 0, 0)
                            else -- RIGHT
                                -- Left of class icon (top area)
                                self.specIcon:SetPoint("TOPRIGHT", self.classIcon, "TOPLEFT", 0, 0)
                            end
                        else -- "TOP"
                            -- Bottom positioning
                            if portraitPosition == "LEFT" then
                                -- Right of class icon (bottom area)
                                self.specIcon:SetPoint("BOTTOMLEFT", self.classIcon, "BOTTOMRIGHT", 0, 0)
                            else -- RIGHT
                                -- Left of class icon (bottom area)
                                self.specIcon:SetPoint("BOTTOMRIGHT", self.classIcon, "BOTTOMLEFT", 0, 0)
                            end
                        end
                    else
                        self.specIcon:Hide()
                    end
                else
                    -- Hide spec icon for NPCs
                    self.specIcon:Hide()
                end
            end

            -- Update class/spec icon borders
            if self.classIconLeftBorder and self.classIconRightBorder then
                if UnitIsPlayer(self.unit) and self.classIcon:IsShown() then
                    local br, bg, bb = 1, 1, 1
                    if self.unit == "target" or self.unit == "targettarget"
                        or self.unit == "focus" or self.unit == "focustarget" then
                        local color = ClassColorForUnit(self.unit) or { r = 1, g = 1, b = 1 }
                        br, bg, bb = color.r, color.g, color.b
                    elseif FluxBorder and FluxBorder.GetAccentMode then
                        local mode = FluxBorder:GetAccentMode()
                        if mode == "atlas" then
                            br, bg, bb = FluxBorder:GetThemedVertexRGB()
                        elseif mode == "custom" then
                            br, bg, bb = FluxBorder:GetThemedVertexRGB()
                        else
                            local color = ClassColorForUnit(self.unit) or { r = 1, g = 1, b = 1 }
                            br, bg, bb = color.r, color.g, color.b
                        end
                    else
                        local color = ClassColorForUnit(self.unit) or { r = 1, g = 1, b = 1 }
                        br, bg, bb = color.r, color.g, color.b
                    end

                    -- Set splitter height to match outerBorderPadding
                    self.classIconLeftBorder:SetHeight(outerBorderPadding)
                    self.classIconRightBorder:SetHeight(outerBorderPadding)

                    if self.specIcon:IsShown() then
                        -- Position borders around the spec icon (vertical separators)
                        -- Left border (vertical line centered on spec icon left edge)
                        self.classIconLeftBorder:ClearAllPoints()
                        self.classIconLeftBorder:SetPoint("CENTER", self.specIcon, "LEFT", -1, 0)
                        self.classIconLeftBorder:SetVertexColor(br, bg, bb, 1)
                        self.classIconLeftBorder:Show()

                        -- Right border (vertical line centered on spec icon right edge)
                        self.classIconRightBorder:ClearAllPoints()
                        self.classIconRightBorder:SetPoint("CENTER", self.specIcon, "RIGHT", -2, 0)
                        self.classIconRightBorder:SetVertexColor(br, bg, bb, 1)
                        self.classIconRightBorder:Show()
                    else
                        -- No spec icon - show single border next to class icon for visual separation
                        self.classIconLeftBorder:Hide()

                        -- Position right border next to class icon
                        self.classIconRightBorder:ClearAllPoints()
                        if portraitPosition == "LEFT" then
                            self.classIconRightBorder:SetPoint("CENTER", self.classIcon, "RIGHT", 1, 0)
                        else -- RIGHT
                            self.classIconRightBorder:SetPoint("CENTER", self.classIcon, "LEFT", -1, 0)
                        end
                        self.classIconRightBorder:SetVertexColor(br, bg, bb, 1)
                        self.classIconRightBorder:Show()
                    end
                else
                    -- Hide borders for NPCs or when class icon is hidden
                    self.classIconLeftBorder:Hide()
                    self.classIconRightBorder:Hide()
                end
            end
        end
    end

    -- Name-strip level/type/rarity (corner opposite class/spec; never on portrait)
    if not totPos2Minimal then
        LayoutNameStripLevelText(self)
        LayoutNameStripCombatIcon(self)
    end

    -- Update raid icon (call this regularly like ShadowedUnitFrames does)
    if self.raidIcon then
        if totPos2Minimal or (FluxUnitFrames_ShouldShowRaidIcon and not FluxUnitFrames_ShouldShowRaidIcon(self.unit)) then
            self.raidIcon:Hide()
        else
        -- Size the raid icon to 90% of HP bar height
        local healthBarHeight = self.Health and self.Health:GetHeight() or 20
        local iconSize = healthBarHeight * 0.9
        self.raidIcon:SetSize(iconSize, iconSize)

        -- Position at center of HP bar
        self.raidIcon:ClearAllPoints()
        self.raidIcon:SetPoint("CENTER", self.Health, "CENTER", 0, 0)

        -- Update the raid icon state
        local index = GetRaidTargetIndex(self.unit)
        if index then
            SetRaidTargetIconTexture(self.raidIcon, index)
            self.raidIcon:Show()
        else
            self.raidIcon:Hide()
        end
        end
    end

    -- Update PvP/WarMode icon + group status icons (leader / assist / MT / MA / ML)
    -- Laid out opposite the level/type corner so they never cover mob metadata.
    if self.pvpIcon then
        if self.unit == "targettarget" or self.unit == "focustarget" or self.unit == "pet"
            or (FluxUnitFrames_ShouldShowPvp and not FluxUnitFrames_ShouldShowPvp(self.unit)) then
            self.pvpIcon:Hide()
            if self.pvpTimer then self.pvpTimer:Hide() end
            HideNameStripStatusIcons(self)
        else
            local faction = UnitFactionGroup(self.unit)
            if UnitIsPVPFreeForAll(self.unit) then
                self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
                self.pvpIcon:SetTexCoord(0, 1, 0, 1)
                self.pvpIcon:Show()
                if self.pvpTimer then self.pvpTimer:Hide() end
            elseif faction and faction ~= "Neutral" and UnitIsPVP(self.unit) then
                self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. faction)
                self.pvpIcon:SetTexCoord(0, 1, 0, 1)
                self.pvpIcon:Show()
                if self.pvpTimer then
                    self.pvpTimer:ClearAllPoints()
                    self.pvpTimer:SetPoint("CENTER", self.pvpIcon, "CENTER", -10, 0)
                end
            else
                self.pvpIcon:Hide()
            end
            LayoutNameStripStatusAndPvpIcons(self, outerBorderPadding)
        end
    elseif self.leaderIcon then
        LayoutNameStripStatusAndPvpIcons(self, outerBorderPadding)
    end

    -- Update group text for players (raid group number) — after status icons so anchors stay clear
    if self.groupText then
        local isPlayerUnit = UnitIsPlayer(self.unit)
        local isPlayerSelf = UnitIsUnit(self.unit, "player")
        if SafeBooleanTest(isPlayerUnit) and SafeBooleanTest(isPlayerSelf) then
            self.groupText:ClearAllPoints()
            local groupAnchor = self.nameText
            if self._fluxStatusIconsOnRight and self._fluxStatusIconChainEnd then
                groupAnchor = self._fluxStatusIconChainEnd
            end
            self.groupText:SetPoint("LEFT", groupAnchor, "RIGHT", 8, 0)

            if self.UpdateGroupText then
                self:UpdateGroupText()
            end
        else
            self.groupText:Hide()
        end
    end

    -- Layout Updates (Protected during combat)
    if not inCombat then
        self.outerBorderFrame:ClearAllPoints()

        if hasPortrait then
            -- Same width as atlas border, but + outerBorderPadding taller
            local combinedWidth = totalWidth + portraitSize -- unit frame + portrait + small gap
            local combinedHeight = totalHeight + outerBorderPadding -- Configurable height

            self.outerBorderFrame:SetSize(combinedWidth, combinedHeight)

            local verticalOffset
            if outerBorderAlignment == "BOTTOM" then
                -- Align bottom with atlas border bottom (outer extends upward)
                verticalOffset = outerBorderPadding -- Align bottoms
            else -- "TOP"
                -- Align top with atlas border top (outer extends downward)
                verticalOffset = 0 -- Same top alignment as atlas border
            end

            if portraitPosition == "LEFT" then
                self.outerBorderFrame:SetPoint("TOPLEFT", self.PortraitFrame, "TOPLEFT", 0, verticalOffset)
            else -- RIGHT
                self.outerBorderFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, verticalOffset)
            end
        else
            -- No portrait, outer border just encompasses the unit frame
            self.outerBorderFrame:SetSize(totalWidth, totalHeight + outerBorderPadding)

            local verticalOffset
            if outerBorderAlignment == "BOTTOM" then
                verticalOffset = outerBorderPadding -- Align bottom with atlas border
            else -- "TOP"
                verticalOffset = -2 -- Align top with atlas border
            end

            -- Default -2 pulls the border left of the frame; bars stay on the frame so content
            -- looks shifted right inside the border. ToT: align X with frame for even chrome.
            local outerX = (self.unit == "targettarget" or self.unit == "focustarget") and 0 or -2
            self.outerBorderFrame:SetPoint("TOPLEFT", self, "TOPLEFT", outerX, verticalOffset)
        end

        if self.mouseoverHighlight and self.mouseoverHighlight._fluxLayoutMouseover then
            self.mouseoverHighlight._fluxLayoutMouseover()
        end

        -- Flux auras anchor to outerBorderFrame; refresh after border size/position is final.
        if not totPos2Minimal then
            if UF.UpdateAuraPosition then
                UF.UpdateAuraPosition(self)
            end
            UF.LayoutBigDebuffsCornerPlaceholder(self)
        end
    end

    -- Update custom vehicle exit button position when player frame's outer border updates
    if self.unit == "player" and ns.FluxVehicleExitButton and ns.FluxVehicleExitButton.UpdatePosition then
        ns.FluxVehicleExitButton:UpdatePosition()
    end
    
    -- Update power bar positions when player frame's outer border updates
    if self.unit == "player" and ns.ClassPower and ns.ClassPower.UpdatePosition then
        -- Trigger position update immediately (outer border is already updated at this point)
        pcall(ns.ClassPower.UpdatePosition, self)
    end

    if self.nameText and self.unit ~= "pet" and self.nameText:IsShown() then
        local maxSz, minSz = 16, 8
        if self.unit == "targettarget" or self.unit == "focustarget" then
            maxSz = 14
        elseif self.unit == "focus" then
            maxSz, minSz = 11, 6 -- ~30% smaller cap vs default 16/8
        end
        if self.unit == "player" and PlayerUnitUsesFluxPetLayout() then
            maxSz = 12
        end
        -- Name was just re-anchored above; fit name (and compact corner metadata) independently.
        FitUnitFrameNameText(self, PaintUnitFrameNameText(self, self.nameText), maxSz, minSz)
    end
    if self.petNameText and self.petNameText:IsShown() then
        FitUnitFrameSecondaryNameText(self)
    end
    UF.LayoutPetHappinessIcon(self)
    -- Re-place PvP/status after name/ToT fit so size/slot use final text widths; keep rest on level.
    if not totPos2Minimal then
        LayoutNameStripStatusAndPvpIcons(self, outerBorderPadding)
        LayoutNameStripCombatIcon(self)
    end
end

-- ---------------------------------------------------------------------------
-- Additional Power Bar (Druid Mana, etc)
-- ---------------------------------------------------------------------------

-- Helper function to check if mana should be shown as secondary resource
-- Uses Blizzard's official API when available; falls back when the API omits cases (see below).
local function ShouldShowManaAsSecondary(unit)
    if not unit then return false end

    local manaPowerType = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0

    -- Blizzard's GetUnitSecondaryPowerInfo only pairs some primaries (see ALT_POWER_BAR_PAIR_DISPLAY_INFO).
    -- Druid Balance (LunarPower -> Mana) is listed; Feral/Guardian (Energy/Rage + Mana) are NOT, so it returns nil.
    if GetUnitSecondaryPowerInfo then
        local secondaryPowerType, secondaryPowerName = GetUnitSecondaryPowerInfo(unit)
        if secondaryPowerType and secondaryPowerName then
            if secondaryPowerType == manaPowerType or secondaryPowerName == "MANA" then
                return true
            end
            -- Blizzard paired a non-mana secondary for this primary (e.g. Traveler)
            return false
        end
        -- nil: fall through — do not hide Druid cat/bear mana
    end

    local maxMana = API.SafeUnitPowerMax(unit, 0)
    local maxManaNum = API.SafeGetNumber(maxMana)

    if maxManaNum <= 0 then
        return false
    end

    -- Druid in any shapeshift where the main bar is not mana: always show player mana underneath
    if unit == "player" then
        local _, class = UnitClass(unit)
        if class == "DRUID" and UnitPowerType(unit) ~= manaPowerType then
            return true
        end
    end

    -- Check if GetPowerRegen exists and returns non-zero for mana
    -- This indicates mana is actively regenerating, so it's being used
    if GetPowerRegen then
        local success, manaRegen = pcall(GetPowerRegen, unit, 0) -- 0 is mana power type
        -- 12.x: regen is a secret number on a tainted path. Do not compare it.
        if success and manaRegen and not (issecretvalue and issecretvalue(manaRegen)) and manaRegen ~= 0 then
            return true -- Mana is actively regenerating, so it's being used
        end
    end
    
    -- Secondary check: For player unit, check if mana is not at max
    -- This indicates mana has been used recently
    if unit == "player" then
        local currentMana = API.SafeUnitPower(unit, 0)
        local currentManaNum = API.SafeGetNumber(currentMana)
        
        -- If mana is not at max, it's being used
        if currentManaNum < maxManaNum then
            return true
        end
    end
    
    return false
end

-- Helper function to check if unit is Brewmaster Monk
local function IsBrewmasterMonk(unit)
    if not unit or unit ~= "player" then return false end
    
    local _, class = UnitClass("player")
    if class ~= "MONK" then return false end
    
    if GetSpecialization then
        local spec = GetSpecialization()
        return spec == 1 -- 1 is Brewmaster spec
    end
    
    return false
end

function UF.UpdateAdditionalPower(self, unit)
    unit = unit or self.unit
    if not self.AdditionalPower then return end

    local afkAdd = UF.UnitIsAFKDisplay(unit)
    if not afkAdd and self._fluxLastAFKAdditional then
        self.AdditionalPower.styleApplied = false
    end
    
    -- Check if we should show it
    local mainPowerType = UnitPowerType(unit)
    local showAdditional = false
    local isStaggerBar = false
    
    -- Check for Brewmaster Monk stagger first
    if IsBrewmasterMonk(unit) then
        showAdditional = true
        isStaggerBar = true
        
        local stagger = UnitStagger and UnitStagger(unit) or 0
        local maxHealth = UnitHealthMax(unit)
        local staggerPercent = maxHealth > 0 and (stagger / maxHealth) or 0
        
        -- Color based on stagger amount (green/yellow/red)
        local r, g, b = 0.52, 1.0, 0.52 -- Default green
        if staggerPercent >= 0.6 then
            r, g, b = 1.0, 0.42, 0.42 -- Red for heavy stagger
        elseif staggerPercent >= 0.3 then
            r, g, b = 1.0, 0.98, 0.72 -- Yellow for moderate stagger
        end
        
        -- Set stagger bar values
        StatusBarSetMinMaxAndValueImmediate(self.AdditionalPower, 0, maxHealth, stagger)
        local staggerTier = "green"
        if staggerPercent >= 0.6 then
            staggerTier = "red"
        elseif staggerPercent >= 0.3 then
            staggerTier = "yellow"
        end
        if self.AdditionalPower._fluxStaggerTier ~= staggerTier or not self.AdditionalPower.isStaggerBar then
            self.AdditionalPower._fluxStaggerTier = staggerTier
            self.AdditionalPower.isStaggerBar = true
            self.AdditionalPower.styleApplied = false
            UF.ApplyStaggerBarStyle(self.AdditionalPower, staggerTier, r, g, b)
        end
        
        -- Update Text
        if self.AdditionalPower.Value then
            local txtStagger = FormatValue(stagger)
            if type(txtStagger) == "userdata" then
                self.AdditionalPower.Value:SetText(txtStagger)
            else
                self.AdditionalPower.Value:SetText(txtStagger)
            end
        end
        if self.AdditionalPower.Percent then
            local pctText = string.format("%.1f%%", staggerPercent * 100)
            self.AdditionalPower.Percent:SetText(pctText)
        end
    -- Check for mana as secondary resource (only if actively used)
    elseif mainPowerType ~= 0 then
        local maxMana = API.SafeUnitPowerMax(unit, 0)
        local maxManaNum = API.SafeGetNumber(maxMana)
        
        -- Only show mana bar if Blizzard's API says to, or if mana exists AND is actively being used
        if maxManaNum > 0 and ShouldShowManaAsSecondary(unit) then
            showAdditional = true
            isStaggerBar = false
            
            -- Reset style flag when switching from stagger to mana
            if self.AdditionalPower.isStaggerBar then
                self.AdditionalPower.styleApplied = false
                self.AdditionalPower.isStaggerBar = false
            end
            
            local mana = API.SafeUnitPower(unit, 0)
            local displayMana = UF.PowerValueForDisplay(self.AdditionalPower, mana)
            if ns.PowerCostOverlay and ns.PowerCostOverlay.BeforePowerApplied then
                ns.PowerCostOverlay.BeforePowerApplied(self.AdditionalPower)
            end
            self.AdditionalPower._fluxFromPowerEvent = self._fluxPowerSpentEvent and true or false
            StatusBarSetMinMaxAndValueImmediate(self.AdditionalPower, 0, maxMana, displayMana)

            -- Style updates (Run once to prevent flickering)
            if not self.AdditionalPower.styleApplied or self.AdditionalPower.isStaggerBar then
                self.AdditionalPower.isStaggerBar = false
                self.AdditionalPower._fluxStaggerTier = nil
                self.AdditionalPower._fluxPrevFillW = nil
                UF.ApplyResourceBarStyle(self.AdditionalPower, unit, "MANA", 0, nil, nil, nil, false)
                self.AdditionalPower.styleApplied = true
            else
                UF.RefreshResourceConnection(self.AdditionalPower, unit)
                UF.UpdateResourceSpark(self.AdditionalPower, self.AdditionalPower._fluxPowerInfo and self.AdditionalPower._fluxPowerInfo.spark)
            end

            UF.UpdateFullResourcePulse(self.AdditionalPower, mana, maxMana)
            if ns.PowerCostOverlay and ns.PowerCostOverlay.AfterPowerApplied then
                ns.PowerCostOverlay.AfterPowerApplied(self.AdditionalPower, unit, displayMana, maxMana)
            end
            
            -- Update Text
            if self.AdditionalPower.Value then
                local txtMan = FormatValue(mana)
                local txtMax = FormatValue(maxMana)
                if type(txtMan) == "userdata" or type(txtMax) == "userdata" then
                    self.AdditionalPower.Value:SetText(txtMan)
                else
                    self.AdditionalPower.Value:SetText(txtMan .. " / " .. txtMax)
                end
            end
            if self.AdditionalPower.Percent then
                local pct = API.GetPowerPercent100(unit, 0)
                
                local success = false
                if API.IsSecretValue(pct) then
                    success = pcall(function() 
                        self.AdditionalPower.Percent:SetText(string.format("%.0f%%", pct))
                    end)
                end
                
                if not success then
                    if API.IsSecretValue(pct) or type(pct) == "userdata" then
                        self.AdditionalPower.Percent:SetText(pct)
                    else
                        self.AdditionalPower.Percent:SetText(string.format("%.0f%%", pct))
                    end
                end
            end
        end
    end
    
    if showAdditional ~= self.isAdditionalPowerShown then
        self.isAdditionalPowerShown = showAdditional
        -- Primary bar uses the ClassResource atlas while the extra mana bar is up.
        self.lastPowerStyle = nil
        if self.UpdatePartition then self:UpdatePartition() end
        if self.Power then
            UF.UpdatePower(self, unit)
        end
    end
    
    if showAdditional then
        self.AdditionalPower:Show()
    else
        self.AdditionalPower:Hide()
    end

    if showAdditional and afkAdd then
        SetStatusBarFillGray(self.AdditionalPower, true)
        if ns.PowerCostOverlay and ns.PowerCostOverlay.UpdateOverlayColor then
            ns.PowerCostOverlay.UpdateOverlayColor(self.AdditionalPower, 0.5, 0.5, 0.5)
        end
    end
    self._fluxLastAFKAdditional = afkAdd
end

function UF.CreateAdditionalPowerBar(frame)
    -- UIParent: must anchor/reposition in combat when secondary mana appears (ClearAllPoints blocked on SecureUnitButton children)
    local ap = CreateFrame("StatusBar", nil, UIParent)
    ap:SetFrameStrata(frame:GetFrameStrata())
    ap:SetFrameLevel(frame:GetFrameLevel() + 3) -- above Health/Power (+2) on the unit frame stack
    ap:EnableMouse(false)
    ap:SetClipsChildren(true)
    ap:SetStatusBarTexture(TEXTURE_BAR)
    ap:GetStatusBarTexture():SetHorizTile(false)
    ap:Hide()

    frame:HookScript("OnShow", function()
        if frame.AdditionalPower and frame.isAdditionalPowerShown then
            frame.AdditionalPower:Show()
        end
    end)
    frame:HookScript("OnHide", function()
        if frame.AdditionalPower then
            frame.AdditionalPower:Hide()
        end
    end)
    
    local bg = ap:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(TEXTURE_BG)
    bg:SetVertexColor(0.2, 0.2, 0.2)
    ap.bg = bg
    
    local textOverlay = CreateFrame("Frame", nil, ap)
    textOverlay:SetAllPoints(ap)
    textOverlay:SetFrameLevel(ap:GetFrameLevel() + 20)
    textOverlay:EnableMouse(false)
    ap.TextOverlay = textOverlay

    local value = textOverlay:CreateFontString(nil, "OVERLAY")
    value:SetPoint("RIGHT", ap, "RIGHT", -5, 0)
    value:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- Match FluxStatusBar styling
    value:SetTextColor(1, 1, 1, 1) -- White text like FluxStatusBar
    ap.Value = value

    local percent = textOverlay:CreateFontString(nil, "OVERLAY")
    percent:SetPoint("LEFT", ap, "LEFT", 5, 0)
    percent:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- Match FluxStatusBar styling
    percent:SetTextColor(1, 1, 1, 1) -- White text like FluxStatusBar
    ap.Percent = percent
    
    frame.AdditionalPower = ap

    if ns.PowerCostOverlay and ns.PowerCostOverlay.CreateOverlay then
        ns.PowerCostOverlay.CreateOverlay(ap)
    end

    return ap
end

-- ---------------------------------------------------------------------------
-- Threat Bar (target / focus) — portrait overlay or strip between chrome & auras
-- ---------------------------------------------------------------------------
-- Between / vertical strip height.
local THREAT_BAR_HEIGHT = 32
-- Portrait overlay: thinner meter (no Flux border chrome).
local THREAT_BAR_PORTRAIT_HEIGHT = 16
-- Match cast-bar flush: ns.Border pad 2 on both sides → 4px overlap so chrome meets with no visual gap.
local THREAT_OUTER_OVERLAP = 4
local THREAT_EMPTY_R, THREAT_EMPTY_G, THREAT_EMPTY_B = 0.25, 0.25, 0.25

-- Helper function to get threat color based on percentage (green→yellow→red)
local function GetThreatColor(percent)
    local ThreatAPI = ns.Flux and ns.Flux.Threat
    if ThreatAPI and ThreatAPI.GetPercentColor then
        local r, g, b = ThreatAPI.GetPercentColor(percent)
        if r then
            return r, g, b
        end
    end
    if not percent or percent < 0 then percent = 0 end
    if percent > 100 then percent = 100 end
    
    local r, g, b
    
    if percent <= 50 then
        -- 0-50%: Green (0,1,0) → Yellow (1,1,0)
        local factor = percent / 50
        r = factor
        g = 1
        b = 0
    else
        -- 50-100%: Yellow (1,1,0) → Red (1,0,0)
        local factor = (percent - 50) / 50
        r = 1
        g = 1 - factor
        b = 0
    end
    
    return r, g, b
end

-- Helper function to calculate threat position in group (including pets)
local function CalculateThreatPosition(targetUnit)
    local ThreatAPI = ns.Flux and ns.Flux.Threat
    if ThreatAPI and ThreatAPI.GetPlayerRank then
        return ThreatAPI.GetPlayerRank(targetUnit)
    end
    if not targetUnit or not UnitExists(targetUnit) then return nil end
    if not UnitAffectingCombat("player") then return nil end
    
    local threatList = {}
    
    -- Helper function to add unit to threat list
    local function AddUnitToThreatList(unit)
        if not UnitExists(unit) then return end
        local isTanking, _, threatPercent, _, threatValue = UnitDetailedThreatSituation(unit, targetUnit)
        if threatValue and threatValue > 0 then
            table.insert(threatList, {
                unit = unit,
                threatValue = threatValue,
                threatPercent = threatPercent or 0,
                isTanking = isTanking or false
            })
        end
    end
    
    -- Get player threat
    AddUnitToThreatList("player")
    
    -- Get player's pet threat
    if UnitExists("pet") then
        AddUnitToThreatList("pet")
    end
    
    -- Scan party members and their pets
    if IsInGroup() and not IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "party" .. i
            AddUnitToThreatList(unit)
            
            -- Add party pet
            local petUnit = "partypet" .. i
            if UnitExists(petUnit) then
                AddUnitToThreatList(petUnit)
            end
        end
    -- Scan raid members and their pets
    elseif IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            AddUnitToThreatList(unit)
            
            -- Add raid pet
            local petUnit = "raidpet" .. i
            if UnitExists(petUnit) then
                AddUnitToThreatList(petUnit)
            end
        end
    end
    
    -- Sort by threat value (descending)
    table.sort(threatList, function(a, b)
        -- Tanks always come first
        if a.isTanking and not b.isTanking then return true end
        if not a.isTanking and b.isTanking then return false end
        return a.threatValue > b.threatValue
    end)
    
    -- Find player's position in the sorted list
    for i, data in ipairs(threatList) do
        if UnitIsUnit(data.unit, "player") then
            return i
        end
    end
    
    return nil
end

--- True when player+target use side-by-side layout (placement 2).
local function ThreatBarIsTargetSideBySide()
    if not FluxUnitFrames_GetPlayerTargetPlacement or not FluxUnitFrames_ShouldUseFlux then
        return false
    end
    return FluxUnitFrames_GetPlayerTargetPlacement() == 2
        and FluxUnitFrames_ShouldUseFlux("player")
        and FluxUnitFrames_ShouldUseFlux("target")
end

--- DB position: portrait | between | left | right. Target "left" is coerced to "right" in side-by-side (pos2).
function UF.GetThreatBarPosition(frame)
    local unit = frame and frame.unit
    if unit ~= "target" and unit ~= "focus" then
        return "portrait"
    end
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    local key = (unit == "focus") and "threatBarPositionFocus" or "threatBarPositionTarget"
    local v = db and db[key]
    if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then
        v = "portrait"
    end
    -- Side-by-side target: never pin a vertical strip on the inward (left) edge.
    if v == "left" and unit == "target" and ThreatBarIsTargetSideBySide() then
        return "right"
    end
    return v
end

--- Portrait + vertical side strips respect visibility (always / group / never).
--- Legacy: threatBarGroupOnly false → always; unset/true → group.
local function GetThreatBarVisibilityMode()
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    local v = db and db.threatBarVisibility
    if v == "always" or v == "group" or v == "never" then
        return v
    end
    if db and db.threatBarGroupOnly == false then
        return "always"
    end
    return "group"
end

local function ThreatBarIsGrouped()
    return (IsInGroup and IsInGroup()) or (IsInRaid and IsInRaid()) or false
end

--- Portrait / left / right respect visibility; "between" stays reserved unless Never.
local function ThreatBarAllowedByGroup(mode)
    local vis = GetThreatBarVisibilityMode()
    if vis == "never" then
        return false
    end
    if mode == "between" then
        return true
    end
    if vis == "always" then
        return true
    end
    return ThreatBarIsGrouped()
end

--- Vertical left/right are reserved only while the unit is an enemy NPC (otherwise fully hidden).
--- Between keeps a reserved empty strip; portrait overlays only when threat exists.
local function ThreatBarModeIsVertical(mode)
    return mode == "left" or mode == "right"
end

local THREAT_GLOW_START_PCT = 70
local THREAT_GLOW_BAND = 5 -- quantize color updates to avoid restarting glow every poll

local function ThreatBarIsEnemyNpc(unit)
    local ThreatAPI = ns.Flux and ns.Flux.Threat
    if ThreatAPI and ThreatAPI.IsEnemyNpc then
        return ThreatAPI.IsEnemyNpc(unit)
    end
    if not unit or not UnitExists(unit) then
        return false
    end
    if UnitIsPlayer(unit) then
        return false
    end
    return UnitCanAttack("player", unit) and true or false
end

--- Portrait: existing show rules. Between: always reserve. Vertical: only for enemy NPCs.
local function ThreatBarShouldShowStrip(frame, mode)
    if not frame or not frame.unit then
        return false
    end
    if mode == "left" or mode == "right" then
        return ThreatBarIsEnemyNpc(frame.unit)
    end
    if mode == "between" then
        return true
    end
    -- portrait: visibility driven by threat update
    return true
end

--- Yellow→red glow color from threat %; nil below start threshold. Tanking / rank #1 → full red.
local function ThreatBarGlowColor(percent, isTanking, rank)
    if isTanking or rank == 1 then
        return { 1, 0, 0, 1 }
    end
    percent = tonumber(percent) or 0
    if percent < THREAT_GLOW_START_PCT then
        return nil
    end
    if percent > 100 then
        percent = 100
    end
    local t = (percent - THREAT_GLOW_START_PCT) / (100 - THREAT_GLOW_START_PCT)
    if t < 0 then t = 0 end
    if t > 1 then t = 1 end
    -- Yellow (1,1,0) → Red (1,0,0)
    return { 1, 1 - t, 0, 1 }
end

local function ThreatBarGlowBandKey(color)
    if not color then
        return 0
    end
    -- Encode quantized g-channel (yellow→red) so small % jitter does not restart glow.
    local g = color[2] or 0
    return 1 + math.floor((1 - g) * 100 / THREAT_GLOW_BAND + 0.5)
end

--- Full-bar IconAlert glow (same style as Respec armed profile on the spec flyout button).
--- Drawn above ns.Border (FluxBorderFrame is shell+10); labels stay above the glow.
local function ThreatBarRaiseGlowAboveBorder(shell)
    if not shell then
        return
    end
    local borderLv = 0
    if shell.FluxBorderFrame and shell.FluxBorderFrame.GetFrameLevel then
        borderLv = shell.FluxBorderFrame:GetFrameLevel() or 0
    else
        borderLv = (shell:GetFrameLevel() or 0) + 10
    end
    local glowLv = borderLv + 5
    local glow = shell._ButtonGlow or shell.__LBGoverlay
    if glow and glow.SetFrameLevel then
        glow:SetFrameLevel(glowLv)
    end
    if shell.TextFrame and shell.TextFrame.SetFrameLevel then
        shell.TextFrame:SetFrameLevel(glowLv + 5)
    end
end

local function ThreatBarStopGlow(shell)
    if not shell then
        return
    end
    local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)
    local LBG = LibStub and LibStub("LibButtonGlow-1.0", true)
    local legacyHost = shell.GlowHost
    if legacyHost then
        if LCG and LCG.ButtonGlow_Stop then
            pcall(LCG.ButtonGlow_Stop, legacyHost)
        end
        if LBG and LBG.HideOverlayGlow then
            pcall(LBG.HideOverlayGlow, legacyHost)
        end
        legacyHost:Hide()
    end
    -- Always stop when asked — do not gate on _fluxThreatGlowBand (layout may clear it first).
    if LCG and LCG.ButtonGlow_Stop then
        pcall(LCG.ButtonGlow_Stop, shell)
    end
    if LBG and LBG.HideOverlayGlow then
        pcall(LBG.HideOverlayGlow, shell)
    end
    local function forceHideIfStuck(overlay)
        if not overlay or not overlay.IsShown or not overlay:IsShown() then
            return
        end
        local out = overlay.animOut
        if out and out.IsPlaying and out:IsPlaying() then
            return
        end
        overlay:Hide()
    end
    forceHideIfStuck(shell._ButtonGlow)
    forceHideIfStuck(shell.__LBGoverlay)
    shell._fluxThreatGlowBand = nil
end

local function ThreatBarUpdateGlow(shell, color)
    if not shell then
        return
    end
    local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)
    local LBG = LibStub and LibStub("LibButtonGlow-1.0", true)
    if not ((LCG and LCG.ButtonGlow_Start and LCG.ButtonGlow_Stop) or (LBG and LBG.ShowOverlayGlow)) then
        return
    end

    if not color then
        ThreatBarStopGlow(shell)
        return
    end

    local band = ThreatBarGlowBandKey(color)
    if shell._fluxThreatGlowBand == band and (shell._ButtonGlow or shell.__LBGoverlay) then
        ThreatBarRaiseGlowAboveBorder(shell)
        return
    end
    shell._fluxThreatGlowBand = band
    -- Prefer LCG so we can tint yellow→red; frameLevel arg must clear the border (+10).
    if LCG and LCG.ButtonGlow_Start then
        pcall(LCG.ButtonGlow_Start, shell, color, 0.25, 16)
    elseif LBG and LBG.ShowOverlayGlow then
        pcall(LBG.ShowOverlayGlow, shell)
    end
    ThreatBarRaiseGlowAboveBorder(shell)
end

--- Same side as auras (focus / side-by-side target → above; classic target → below).
local function ThreatBarAurasAboveUnit(frame)
    if not frame then
        return false
    end
    if frame.unit == "focus" or frame.auraFrameAboveUnit == true then
        return true
    end
    if frame.unit ~= "target" then
        return false
    end
    return ThreatBarIsTargetSideBySide()
end

local function ThreatBarSetEmptyVisual(shell)
    local bar = shell.StatusBar or shell
    bar:SetValue(0)
    bar:SetStatusBarColor(THREAT_EMPTY_R, THREAT_EMPTY_G, THREAT_EMPTY_B)
    if shell.PositionText then
        shell.PositionText:SetText("")
    end
    if shell.PercentText then
        shell.PercentText:SetText("")
    end
end

--- Portrait: no Flux border, bar fills the shell. Between/vertical: keep border inset.
local function ThreatBarApplyBorderStyle(shell, portraitMode)
    if not shell then
        return
    end
    local bar = shell.StatusBar
    if shell.FluxBorderFrame then
        if portraitMode then
            shell.FluxBorderFrame:Hide()
        else
            shell.FluxBorderFrame:Show()
        end
    end
    if bar then
        bar:ClearAllPoints()
        if portraitMode then
            bar:SetPoint("TOPLEFT", shell, "TOPLEFT", 0, 0)
            bar:SetPoint("BOTTOMRIGHT", shell, "BOTTOMRIGHT", 0, 0)
        else
            bar:SetPoint("TOPLEFT", shell, "TOPLEFT", 2, -2)
            bar:SetPoint("BOTTOMRIGHT", shell, "BOTTOMRIGHT", -2, 2)
        end
    end
end

--- Horizontal: rank left, % right. Vertical: rank above % (centered).
local function ThreatBarApplyChromeOrientation(shell, vertical)
    local bar = shell and shell.StatusBar
    if not bar then
        return
    end
    if vertical then
        bar:SetOrientation("VERTICAL")
    else
        bar:SetOrientation("HORIZONTAL")
    end
    local tex = bar:GetStatusBarTexture()
    if tex then
        tex:SetHorizTile(false)
        if tex.SetVertTile then
            tex:SetVertTile(false)
        end
    end
    if shell.TextFrame then
        shell.TextFrame:SetFrameLevel((shell:GetFrameLevel() or 0) + 25)
    end
    if vertical then
        if shell.PositionText then
            shell.PositionText:ClearAllPoints()
            shell.PositionText:SetPoint("BOTTOM", bar, "CENTER", 0, 1)
            shell.PositionText:SetJustifyH("CENTER")
        end
        if shell.PercentText then
            shell.PercentText:ClearAllPoints()
            if shell.PositionText then
                shell.PercentText:SetPoint("TOP", shell.PositionText, "BOTTOM", 0, -1)
            else
                shell.PercentText:SetPoint("TOP", bar, "CENTER", 0, -1)
            end
            shell.PercentText:SetJustifyH("CENTER")
        end
    else
        if shell.PositionText then
            shell.PositionText:ClearAllPoints()
            shell.PositionText:SetPoint("LEFT", bar, "LEFT", 4, 0)
            shell.PositionText:SetJustifyH("LEFT")
        end
        if shell.PercentText then
            shell.PercentText:ClearAllPoints()
            shell.PercentText:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
            shell.PercentText:SetJustifyH("RIGHT")
        end
    end
end

function UF.CreateThreatBar(frame)
    -- Only create for target / focus frame
    if not frame or (frame.unit ~= "target" and frame.unit ~= "focus") then
        return nil
    end
    if frame.ThreatBar then
        return frame.ThreatBar
    end

    -- Bordered shell (same chrome as cast / outer); StatusBar fills interior.
    local shell = CreateFrame("Frame", nil, frame)
    shell:SetFrameLevel((frame:GetFrameLevel() or 0) + 10)
    shell:SetHeight(THREAT_BAR_HEIGHT)
    shell:Hide()

    if ns.Border then
        ns.Border:ApplyTo(shell, 2, 2, 2, 2)
        local color = GetUnitClassColor(frame.unit)
        ns.Border:SetBorderColor(shell, color.r, color.g, color.b, 1)
        ns.Border:SetBackdropColor(shell, color.r * 0.4, color.g * 0.4, color.b * 0.4, 0.85)
    end

    local threatBar = CreateFrame("StatusBar", nil, shell)
    threatBar:SetPoint("TOPLEFT", shell, "TOPLEFT", 2, -2)
    threatBar:SetPoint("BOTTOMRIGHT", shell, "BOTTOMRIGHT", -2, 2)
    threatBar:SetMinMaxValues(0, 100)
    threatBar:SetValue(0)
    threatBar:SetStatusBarTexture(TEXTURE_BAR)
    threatBar:GetStatusBarTexture():SetHorizTile(false)
    threatBar:SetStatusBarColor(THREAT_EMPTY_R, THREAT_EMPTY_G, THREAT_EMPTY_B)
    shell.StatusBar = threatBar

    local bg = threatBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(TEXTURE_BG)
    bg:SetVertexColor(0.2, 0.2, 0.2)
    threatBar.bg = bg
    shell.bg = bg

    -- Labels sit above the square Respec-style glow host.
    local textFrame = CreateFrame("Frame", nil, shell)
    textFrame:SetAllPoints(shell)
    textFrame:EnableMouse(false)
    textFrame:SetFrameLevel((shell:GetFrameLevel() or 0) + 25)
    shell.TextFrame = textFrame

    local threatFont = (frame.unit == "focus") and 10 or 14
    local positionText = textFrame:CreateFontString(nil, "OVERLAY")
    positionText:SetPoint("BOTTOM", threatBar, "CENTER", 0, 1)
    positionText:SetFont("Fonts\\FRIZQT__.TTF", threatFont, "OUTLINE")
    positionText:SetTextColor(1, 1, 1, 1)
    positionText:SetJustifyH("CENTER")
    shell.PositionText = positionText

    local percentText = textFrame:CreateFontString(nil, "OVERLAY")
    percentText:SetPoint("TOP", positionText, "BOTTOM", 0, -1)
    percentText:SetFont("Fonts\\FRIZQT__.TTF", threatFont, "OUTLINE")
    percentText:SetTextColor(1, 1, 1, 1)
    percentText:SetJustifyH("CENTER")
    shell.PercentText = percentText

    frame.ThreatBar = shell
    UF.LayoutThreatBar(frame)
    return shell
end

--- Re-anchor threat bar (portrait / between auras / vertical left / vertical right).
function UF.LayoutThreatBar(frame)
    if not frame or not frame.ThreatBar then
        return
    end
    if frame.unit ~= "target" and frame.unit ~= "focus" then
        return
    end
    local shell = frame.ThreatBar
    local mode = UF.GetThreatBarPosition(frame)
    local prevMode = frame._fluxThreatBarMode
    local above = ThreatBarAurasAboveUnit(frame)
    local prevAbove = frame._fluxThreatBarAbove
    frame._fluxThreatBarMode = mode
    frame._fluxThreatBarAbove = above

    local portraitMode = (mode ~= "between" and not ThreatBarModeIsVertical(mode))
    shell:ClearAllPoints()
    ThreatBarApplyBorderStyle(shell, portraitMode)
    ThreatBarApplyChromeOrientation(shell, ThreatBarModeIsVertical(mode))

    -- Portrait / vertical: optional group-only gate (between always allowed).
    if not ThreatBarAllowedByGroup(mode) then
        ThreatBarSetEmptyVisual(shell)
        ThreatBarUpdateGlow(shell, nil)
        shell:Hide()
        if UF.UpdateAuraPosition and (prevMode ~= mode or prevAbove ~= above) then
            UF.UpdateAuraPosition(frame)
        end
        return
    end

    -- Vertical: fully hide when not an enemy NPC (no reserved strip).
    if ThreatBarModeIsVertical(mode) and not ThreatBarShouldShowStrip(frame, mode) then
        ThreatBarSetEmptyVisual(shell)
        ThreatBarUpdateGlow(shell, nil)
        shell:Hide()
        if UF.UpdateAuraPosition and (prevMode ~= mode or prevAbove ~= above) then
            UF.UpdateAuraPosition(frame)
        end
        return
    end

    if mode == "between" then
        local anchor = frame.outerBorderFrame or frame
        shell:SetHeight(THREAT_BAR_HEIGHT)
        local threatFont = (frame.unit == "focus") and 10 or 14
        if shell.PositionText then
            shell.PositionText:SetFont("Fonts\\FRIZQT__.TTF", threatFont, "OUTLINE")
        end
        if shell.PercentText then
            shell.PercentText:SetFont("Fonts\\FRIZQT__.TTF", threatFont, "OUTLINE")
        end
        -- Overlap outer chrome like cast bar (pad 2 + pad 2) so there is no visual gap at the seam.
        if above then
            shell:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, -THREAT_OUTER_OVERLAP)
            shell:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, -THREAT_OUTER_OVERLAP)
        else
            shell:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, THREAT_OUTER_OVERLAP)
            shell:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, THREAT_OUTER_OVERLAP)
        end
        ThreatBarSetEmptyVisual(shell)
        shell:Show()
    elseif mode == "left" or mode == "right" then
        local anchor = frame.outerBorderFrame or frame
        -- Thickness matches horizontal strip height; span full outer chrome height.
        shell:SetWidth(THREAT_BAR_HEIGHT)
        local threatFont = (frame.unit == "focus") and 10 or 14
        if shell.PositionText then
            shell.PositionText:SetFont("Fonts\\FRIZQT__.TTF", threatFont, "OUTLINE")
        end
        if shell.PercentText then
            shell.PercentText:SetFont("Fonts\\FRIZQT__.TTF", threatFont, "OUTLINE")
        end
        if mode == "left" then
            shell:SetPoint("TOPRIGHT", anchor, "TOPLEFT", THREAT_OUTER_OVERLAP, 0)
            shell:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMLEFT", THREAT_OUTER_OVERLAP, 0)
        else
            shell:SetPoint("TOPLEFT", anchor, "TOPRIGHT", -THREAT_OUTER_OVERLAP, 0)
            shell:SetPoint("BOTTOMLEFT", anchor, "BOTTOMRIGHT", -THREAT_OUTER_OVERLAP, 0)
        end
        ThreatBarSetEmptyVisual(shell)
        shell:Show()
    else
        -- Portrait overlay: thinner, borderless; glow applied in UpdateThreatBar.
        local anchor = (UF.FrameUsesPortraitLayout(frame) and frame.PortraitFrame) or frame
        shell:SetHeight(THREAT_BAR_PORTRAIT_HEIGHT)
        if anchor then
            local inset = (anchor == frame.PortraitFrame) and 2 or 4
            shell:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", inset, inset)
            shell:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -inset, inset)
            if not UnitExists(frame.unit) or not UnitAffectingCombat("player") then
                shell:Hide()
            end
        end
        local threatFont = (frame.unit == "focus") and 9 or 11
        if shell.PositionText then
            shell.PositionText:SetFont("Fonts\\FRIZQT__.TTF", threatFont, "OUTLINE")
        end
        if shell.PercentText then
            shell.PercentText:SetFont("Fonts\\FRIZQT__.TTF", threatFont, "OUTLINE")
        end
    end

    -- Re-anchor auras when mode or above/below side changes (only "between" pins auras to the strip).
    if UF.UpdateAuraPosition and (prevMode ~= mode or prevAbove ~= above) then
        UF.UpdateAuraPosition(frame)
    end
    -- Force glow re-apply so IconAlert overlay matches the new full-bar size.
    shell._fluxThreatGlowBand = nil
    if UF.UpdateThreatBar then
        UF.UpdateThreatBar(frame)
    end
end

-- Compat alias for older call sites.
UF.LayoutThreatBarForPortraitState = UF.LayoutThreatBar

function UF.UpdateThreatBar(frame)
    -- Only update for target / focus frame
    if (not frame) or (frame.unit ~= "target" and frame.unit ~= "focus") or not frame.ThreatBar then
        return
    end

    local shell = frame.ThreatBar
    local bar = shell.StatusBar or shell
    local tu = frame.unit
    local mode = frame._fluxThreatBarMode or UF.GetThreatBarPosition(frame)
    local vertical = ThreatBarModeIsVertical(mode)
    local enemyNpc = ThreatBarIsEnemyNpc(tu)
    local reserved = (mode == "between") or (vertical and enemyNpc)
    local ThreatAPI = ns.Flux and ns.Flux.Threat
    local Secrets = ns.Flux and ns.Flux.Secrets

    -- Portrait / vertical: optional group-only gate.
    if not ThreatBarAllowedByGroup(mode) then
        ThreatBarSetEmptyVisual(shell)
        ThreatBarUpdateGlow(shell, nil)
        shell:Hide()
        return
    end

    -- Vertical: only appear for enemy NPCs.
    if vertical and not enemyNpc then
        ThreatBarSetEmptyVisual(shell)
        ThreatBarUpdateGlow(shell, nil)
        shell:Hide()
        return
    end

    local function showEmpty()
        ThreatBarSetEmptyVisual(shell)
        ThreatBarUpdateGlow(shell, nil)
        if reserved then
            shell:Show()
        else
            shell:Hide()
            UF.SyncBigDebuffsFrameLevelForUnitFrame(frame)
        end
    end

    local unitExists = true
    if ThreatAPI and ThreatAPI.UnitExists then
        unitExists = ThreatAPI.UnitExists(tu)
    elseif UnitExists then
        local okExists, exists = pcall(UnitExists, tu)
        if okExists then
            if Secrets and Secrets.SafeBooleanTest then
                unitExists = Secrets.SafeBooleanTest(exists, false)
            else
                unitExists = exists and true or false
            end
        else
            unitExists = false
        end
    end
    if not unitExists then
        showEmpty()
        return
    end

    local displayPercent, status, isTanking, detailed
    local foreverFrame = false
    if ThreatAPI and ThreatAPI.GetForeverFrameDisplay then
        local client = ns.Flux and ns.Flux.Client
        foreverFrame = client and (client.isCamelot or client.isForever) and true or false
    end
    if foreverFrame then
        displayPercent, status, isTanking, detailed = ThreatAPI.GetForeverFrameDisplay("player", tu)
    elseif ThreatAPI and ThreatAPI.GetNumericDisplay then
        displayPercent, status, isTanking, detailed = ThreatAPI.GetNumericDisplay("player", tu)
    else
        local tanking, _, threatPercent, rawThreatPercent, threatValue = UnitDetailedThreatSituation("player", tu)
        isTanking = tanking
        displayPercent = threatPercent or rawThreatPercent
        if not displayPercent and not threatValue then
            showEmpty()
            return
        end
    end

    if foreverFrame and ThreatAPI.IsExcludedThreatUnit and ThreatAPI.IsExcludedThreatUnit(tu) then
        showEmpty()
        return
    end

    local function ThreatValuePresent(value)
        if Secrets and Secrets.IsSecretValue and Secrets.IsSecretValue(value) then
            return true
        end
        return value ~= nil
    end
    if not ThreatValuePresent(displayPercent) and not detailed then
        showEmpty()
        return
    end

    local tankingNow = false
    if Secrets and Secrets.SafeBooleanTest then
        tankingNow = Secrets.SafeBooleanTest(isTanking, false)
    elseif isTanking then
        tankingNow = true
    end

    local hasThreat = false
    if ThreatAPI and ThreatAPI.ShouldShowThreat then
        hasThreat = ThreatAPI.ShouldShowThreat(displayPercent, isTanking)
    else
        hasThreat = tankingNow
        if not hasThreat then
            if ThreatAPI and ThreatAPI.HasNonZeroDisplay then
                hasThreat = ThreatAPI.HasNonZeroDisplay(displayPercent)
                    or ThreatAPI.HasNonZeroDisplay(detailed and detailed.rawThreat)
            else
                hasThreat = displayPercent and displayPercent ~= 0
            end
        end
    end
    if not hasThreat then
        showEmpty()
        return
    end

    local fill = 0
    if ThreatAPI and ThreatAPI.SetBarValue then
        fill = ThreatAPI.SetBarValue(bar, displayPercent or (detailed and detailed.scaledPercentage), isTanking)
    else
        if ThreatAPI and ThreatAPI.AccessibleNumber then
            fill = ThreatAPI.AccessibleNumber(detailed and detailed.scaledPercentage)
                or ThreatAPI.AccessibleNumber(detailed and detailed.rawPercentage)
                or ThreatAPI.AccessibleNumber(displayPercent)
                or 0
        else
            fill = displayPercent or 0
        end
        if tankingNow then
            fill = 100
        elseif fill > 100 then
            fill = 100
        elseif fill < 0 then
            fill = 0
        end
        pcall(bar.SetValue, bar, fill)
    end

    local r, g, b
    if ThreatAPI then
        if ThreatAPI.GetStatusColor then
            r, g, b = ThreatAPI.GetStatusColor(status)
        end
        if not r and ThreatAPI.GetPercentColor then
            r, g, b = ThreatAPI.GetPercentColor(fill)
        end
    end
    if not r then
        r, g, b = GetThreatColor(fill)
    end
    pcall(bar.SetStatusBarColor, bar, r, g, b)

    if shell.PercentText then
        local showPct = not ThreatAPI or not ThreatAPI.ShouldShowNumericOnUnit or ThreatAPI.ShouldShowNumericOnUnit(tu)
        if showPct then
            if ThreatAPI and ThreatAPI.SetPercentText then
                ThreatAPI.SetPercentText(shell.PercentText, displayPercent)
            elseif displayPercent then
                pcall(shell.PercentText.SetFormattedText, shell.PercentText, "%.0f%%", displayPercent)
            else
                shell.PercentText:SetText("")
            end
        else
            shell.PercentText:SetText("")
        end
    end
    local position = CalculateThreatPosition(tu)
    if shell.PositionText then
        if position then
            shell.PositionText:SetText(tostring(position))
        else
            shell.PositionText:SetText("")
        end
    end

    shell:Show()
    if not reserved then
        UF.SyncBigDebuffsFrameLevelForUnitFrame(frame)
    end
    -- Portrait / between / vertical: yellow→red glow when high threat on enemy NPCs.
    -- Glow colors compare percents; skip when the value is secret.
    if enemyNpc and type(fill) == "number" then
        ThreatBarUpdateGlow(shell, ThreatBarGlowColor(fill, tankingNow, position))
    else
        ThreatBarUpdateGlow(shell, nil)
    end
end

-- ---------------------------------------------------------------------------
-- Dynamic Partitioning (Sizing)
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- Dynamic Partitioning (Sizing)
-- ---------------------------------------------------------------------------
-- Combat-safe visual element updates (icons, level text, etc.) - can run during combat
function UF.UpdateFrameVisualElements(self)
    -- Validate this is one of our frames, not a Blizzard CompactRaidFrame
    if not IsFluxUnitFrame(self.unit) then return end
    
    -- Update class icon, spec icon, and level/mob type text immediately (safe during combat)
    if self.classIcon or self.specIcon or self.levelText then
        local outerBorderPadding = self.outerBorderPadding or 36
        local outerBorderAlignment = self.outerBorderAlignment or "BOTTOM"
        local portraitPosition = self.portraitPosition or "LEFT"

        -- Update class icon for players
        if self.classIcon then
            if FluxUnitFrames_ShouldShowClassIcon and not FluxUnitFrames_ShouldShowClassIcon(self.unit) then
                self.classIcon:Hide()
                if self.specIcon then self.specIcon:Hide() end
            elseif UnitIsPlayer(self.unit) then
                -- Show and position class icon for players
                local _, class = UnitClass(self.unit)
                if class then
                    -- Try different class icon naming conventions
                    local classIconPath = "Interface\\Icons\\ClassIcon_" .. class
                    self.classIcon:SetTexture(classIconPath)

                    -- Verify texture loaded, fallback if needed
                    if not self.classIcon:GetTexture() then
                        -- Try alternative naming (some clients use different format)
                        classIconPath = "Interface\\Icons\\Class_" .. class
                        self.classIcon:SetTexture(classIconPath)
                    end

                    -- Size the icon to match outerBorderPadding
                    self.classIcon:SetSize(outerBorderPadding, outerBorderPadding)
                    self.classIcon:Show()

                    -- Position in the appropriate corner
                    self.classIcon:ClearAllPoints()

                    if outerBorderAlignment == "BOTTOM" then
                        -- Top corner positioning
                        if portraitPosition == "LEFT" then
                            -- Top-left corner of outer border
                            self.classIcon:SetPoint("TOPLEFT", self.outerBorderFrame, "TOPLEFT", 0, -4)
                        else -- RIGHT
                            -- Top-right corner of outer border
                            self.classIcon:SetPoint("TOPRIGHT", self.outerBorderFrame, "TOPRIGHT", 0, -4)
                        end
                    else -- "TOP"
                        -- Bottom corner positioning
                        if portraitPosition == "LEFT" then
                            -- Bottom-left corner of outer border
                            self.classIcon:SetPoint("BOTTOMLEFT", self.outerBorderFrame, "BOTTOMLEFT", 0, 4)
                        else -- RIGHT
                            -- Bottom-right corner of outer border
                            self.classIcon:SetPoint("BOTTOMRIGHT", self.outerBorderFrame, "BOTTOMRIGHT", 0, 4)
                        end
                    end
                else
                    self.classIcon:Hide()
                end
            else
                -- Hide class icon for NPCs
                self.classIcon:Hide()
            end
        end

        -- Update spec icon for players (skip during combat to avoid protected function calls)
        if self.specIcon and (self.unit == "targettarget" or self.unit == "focustarget") then
            self.specIcon:Hide()
        elseif self.specIcon and not InCombatLockdown() then
            if FluxUnitFrames_ShouldShowClassIcon and not FluxUnitFrames_ShouldShowClassIcon(self.unit) then
                self.specIcon:Hide()
            elseif UnitIsPlayer(self.unit) then
                -- Show and position spec icon for players
                local specIconPath = GetSpecIcon(self.unit)
                if specIconPath then
                    self.specIcon:SetTexture(specIconPath)

                    -- Verify texture loaded, fallback if needed
                    if not self.specIcon:GetTexture() and specIconPath then
                        -- Try alternative paths or simplified names
                        local altPath = specIconPath:gsub("Interface\\Icons\\", "")
                        if altPath ~= specIconPath then
                            self.specIcon:SetTexture("Interface\\Icons\\" .. altPath)
                        end
                    end

                    -- Size the icon to match outerBorderPadding
                    self.specIcon:SetSize(outerBorderPadding, outerBorderPadding)
                    self.specIcon:Show()

                    -- Position next to class icon (no gap)
                    self.specIcon:ClearAllPoints()

                    if outerBorderAlignment == "BOTTOM" then
                        -- Top positioning
                        if portraitPosition == "LEFT" then
                            -- Right of class icon (top area)
                            self.specIcon:SetPoint("TOPLEFT", self.classIcon, "TOPRIGHT", 0, 0)
                        else -- RIGHT
                            -- Left of class icon (top area)
                            self.specIcon:SetPoint("TOPRIGHT", self.classIcon, "TOPLEFT", 0, 0)
                        end
                    else -- "TOP"
                        -- Bottom positioning
                        if portraitPosition == "LEFT" then
                            -- Right of class icon (bottom area)
                            self.specIcon:SetPoint("BOTTOMLEFT", self.classIcon, "BOTTOMRIGHT", 0, 0)
                        else -- RIGHT
                            -- Left of class icon (bottom area)
                            self.specIcon:SetPoint("BOTTOMRIGHT", self.classIcon, "BOTTOMLEFT", 0, 0)
                        end
                    end
                else
                    self.specIcon:Hide()
                end
            else
                -- Hide spec icon for NPCs
                self.specIcon:Hide()
            end
        end

        -- Update level text for players and NPCs (name strip; shared with UpdateOuterBorder)
        if self.levelText then
            LayoutNameStripLevelText(self)
            LayoutNameStripCombatIcon(self)
            if self.nameText and self.unit ~= "pet" and self.nameText:IsShown() then
                local maxSz, minSz = 16, 8
                if self.unit == "focus" then
                    maxSz, minSz = 11, 6
                elseif self.unit == "targettarget" or self.unit == "focustarget" then
                    maxSz = 14
                end
                FitUnitFrameNameText(self, PaintUnitFrameNameText(self, self.nameText), maxSz, minSz)
            end
            if self.petNameText and self.petNameText:IsShown() then
                FitUnitFrameSecondaryNameText(self)
            end
        end
    end

    -- Update health bar color based on unit class/reaction
    UF.UpdateHealthColor(self)
end

-- HP / power / mana splitter textures (hosted on UIParent SeparatorContainer — combat-safe)
function UF.UpdateFramePartitionSeparators(self, hHeight, rHeight, padding, showAdditional)
    if not self.HealthPowerSeparator and not self.PowerAdditionalSeparator then return end

    local r, g, b = GetChromeSeparatorRGB(self.unit or "player")

    if self.HealthPowerSeparator then
        self.HealthPowerSeparator:ClearAllPoints()
        local sepY = -2 - hHeight - (padding / 2)
        self.HealthPowerSeparator:SetPoint("CENTER", self, "TOP", 0, sepY)
        self.HealthPowerSeparator:SetWidth(self:GetWidth())
        self.HealthPowerSeparator:SetVertexColor(r, g, b, 1)
        self.HealthPowerSeparator:Show()
    end

    if self.AdditionalPower and showAdditional and self.PowerAdditionalSeparator then
        local sepY = -2 - hHeight - padding - rHeight - (padding / 2)
        self.PowerAdditionalSeparator:ClearAllPoints()
        self.PowerAdditionalSeparator:SetPoint("CENTER", self, "TOP", 0, sepY)
        self.PowerAdditionalSeparator:SetWidth(self:GetWidth())
        self.PowerAdditionalSeparator:SetVertexColor(r, g, b, 1)
        self.PowerAdditionalSeparator:Show()
    elseif self.PowerAdditionalSeparator then
        self.PowerAdditionalSeparator:Hide()
    end
end

-- Health bar height (pixels) for HP/power split — matches UpdateFramePartition when no additional power.
-- unitForPartition: which unit’s saved split to use (e.g. "focus" for focus target-of-target metrics).
function UF.GetFluxStylePartitionHealthHeight(totalFrameHeight, unitForPartition)
    totalFrameHeight = totalFrameHeight or 50
    unitForPartition = unitForPartition or "player"
    local padding = 2
    local inset = 8
    local innerHeight = totalFrameHeight - inset
    if innerHeight < 10 then innerHeight = 10 end
    local hp = 0.60
    if FluxUnitFrames_GetHealthPartitionPct then
        hp = FluxUnitFrames_GetHealthPartitionPct(unitForPartition)
    end
    return innerHeight * hp - (padding / 2)
end

function UF.UpdateFramePartition(self)
    -- Validate this is one of our frames, not a Blizzard CompactRaidFrame
    if not IsFluxUnitFrame(self.unit) then return end
    
    -- Safety checks: don't update if required bars don't exist
    if not self.Health or not self.Power then return end

    -- Focus target-of-target: single health bar only (width/height match focus style); atlas border, no chrome
    if self._fluxHealthBarOnly then
        local totalHeight = self:GetHeight()
        local barAreaLeft = self.barAreaLeft or 2
        local barAreaRight = self.barAreaRight or -2
        local topInset = 2
        local bottomInset = 2 -- pair with tighter Border bottom on focustarget (see FluxUnitFrames_FocusTarget)
        local innerHeight = totalHeight - topInset - bottomInset
        if innerHeight < 10 then innerHeight = 10 end
        local inCombat = InCombatLockdown()

        if inCombat then
            if self.Health then
                -- TOP+TOPRIGHT+height avoids ClearAllPoints issues on some paths; matches vertical span of TOP+BOTTOM stretch
                self.Health:ClearAllPoints()
                self.Health:SetPoint("TOPLEFT", self, "TOPLEFT", barAreaLeft, -topInset)
                self.Health:SetPoint("TOPRIGHT", self, "TOPRIGHT", barAreaRight, -topInset)
                self.Health:SetHeight(innerHeight)
            end
            if self.Power then
                self.Power:Hide()
            end
            if self.HealthPowerSeparator then self.HealthPowerSeparator:Hide() end
            if self.PowerAdditionalSeparator then self.PowerAdditionalSeparator:Hide() end
            UF.UpdateAtlasBorder(self)
            if self.UpdateOuterBorder then
                self:UpdateOuterBorder()
            end
            return
        end

        self.needsPartitionRelayout = false

        -- Stretch health to top/bottom insets so no gap above atlas border under the bar
        self.Health:ClearAllPoints()
        self.Health:SetPoint("TOPLEFT", self, "TOPLEFT", barAreaLeft, -topInset)
        self.Health:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", barAreaRight, bottomInset)
        if self.Power then
            self.Power:ClearAllPoints()
            self.Power:Hide()
        end
        if self.AdditionalPower then
            self.AdditionalPower:Hide()
        end
        if self.HealthPowerSeparator then self.HealthPowerSeparator:Hide() end
        if self.PowerAdditionalSeparator then self.PowerAdditionalSeparator:Hide() end

        UF.UpdateAtlasBorder(self)
        if self.UpdateOuterBorder then
            self:UpdateOuterBorder()
        end
        return
    end

    local totalHeight = self:GetHeight()

    local portraitPosition = self.portraitPosition or "LEFT" -- Can be "LEFT" or "RIGHT"
    local hasPortrait = UF.FrameUsesPortraitLayout(self)
    local portraitSize = totalHeight -- Square portrait with frame height

    -- Calculate available space for bars (portrait is now outside the frame)
    local barAreaLeft = self.barAreaLeft or 2 -- Standard left inset (frames may override, e.g. ToT)
    local barAreaRight = self.barAreaRight or -2 -- Standard right inset

    local showAdditional = self.isAdditionalPowerShown

    local hPct, rPct, mPct
    if showAdditional then
        hPct, rPct, mPct = 0.50, 0.30, 0.20
    else
        local hp = 0.60
        if FluxUnitFrames_GetHealthPartitionPct then
            hp = FluxUnitFrames_GetHealthPartitionPct(self.unit or "player")
        end
        hPct, rPct = hp, 1 - hp
    end

    local padding = 2
    local inset = 8 -- 2 top + 6 bottom to match border insets
    local innerHeight = totalHeight - inset
    if innerHeight < 10 then innerHeight = 10 end

    local hHeight = innerHeight * hPct
    local rHeight = innerHeight * rPct
    local mHeight = showAdditional and (innerHeight * mPct) or 0

    if mHeight > 0 then mHeight = mHeight - (padding / 2) end
    if rHeight > 0 then rHeight = rHeight - (padding / 2) end
    hHeight = hHeight - (padding / 2)

    local inCombat = InCombatLockdown()

    -- During combat lockdown, ClearAllPoints/SetPoint on children of SecureUnitButton is blocked.
    -- Resize bars with SetHeight only (anchors from last full layout) and defer full relayout.
    if inCombat then
        local function AnchorCount(f)
            if not f or not f.GetNumPoints then return 2 end
            local ok, n = pcall(function() return f:GetNumPoints() end)
            if ok and type(n) == "number" and n > 0 then return n end
            return 0
        end

        if AnchorCount(self.Health) < 1 or AnchorCount(self.Power) < 1 then
            self.needsPartitionRelayout = true
            if not self:IsEventRegistered("PLAYER_REGEN_ENABLED") then
                self:RegisterEvent("PLAYER_REGEN_ENABLED")
            end
            return
        end

        self.Health:SetHeight(hHeight)
        self.Power:SetHeight(rHeight)

        if self.AdditionalPower then
            if showAdditional then
                self.AdditionalPower:SetFrameStrata(self:GetFrameStrata())
                self.AdditionalPower:SetFrameLevel(self.Power:GetFrameLevel() + 1)
                self.AdditionalPower:ClearAllPoints()
                self.AdditionalPower:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -padding)
                self.AdditionalPower:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -padding)
                self.AdditionalPower:SetHeight(mHeight)
                self.AdditionalPower:Show()
            else
                self.AdditionalPower:Hide()
            end
        end

        self.needsPartitionRelayout = true
        if not self:IsEventRegistered("PLAYER_REGEN_ENABLED") then
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
        end

        UF.UpdateFramePartitionSeparators(self, hHeight, rHeight, padding, showAdditional)
        UF.UpdateAtlasBorder(self)
        UF.UpdateOuterBorder(self)
        if hasPortrait then
            UF.SyncPortraitModelGeometry(self)
        end
        return
    end

    self.needsPartitionRelayout = false

    -- Position portrait if it exists (full layout — not allowed during combat lockdown)
    if hasPortrait then
        self.PortraitFrame:ClearAllPoints()
        self.PortraitFrame:SetSize(portraitSize, portraitSize)

        if portraitPosition == "LEFT" then
            self.PortraitFrame:SetPoint("TOPRIGHT", self, "TOPLEFT", 2, 0)
        else -- RIGHT
            self.PortraitFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", -2, 0)
        end
    end

    -- Apply Health - positioned within bar area (accounting for portrait)
    self.Health:ClearAllPoints()
    self.Health:SetPoint("TOPLEFT", self, "TOPLEFT", barAreaLeft, -2)
    self.Health:SetPoint("TOPRIGHT", self, "TOPRIGHT", barAreaRight, -2)
    self.Health:SetHeight(hHeight)

    -- Apply Power (Resource)
    self.Power:ClearAllPoints()
    self.Power:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -padding)
    self.Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, -padding)
    self.Power:SetHeight(rHeight)

    -- Apply Additional Power (UIParent child — full anchor refresh out of combat)
    if self.AdditionalPower then
        if showAdditional then
            self.AdditionalPower:SetFrameStrata(self:GetFrameStrata())
            self.AdditionalPower:SetFrameLevel(self.Power:GetFrameLevel() + 1)
            self.AdditionalPower:ClearAllPoints()
            self.AdditionalPower:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -padding)
            self.AdditionalPower:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -padding)
            self.AdditionalPower:SetHeight(mHeight)
        end
    end

    UF.UpdateFramePartitionSeparators(self, hHeight, rHeight, padding, showAdditional)

    UF.UpdateAtlasBorder(self)
    UF.UpdateOuterBorder(self)

    if hasPortrait then
        UF.SyncPortraitModelGeometry(self)
    end

    UF.LayoutThreatBar(self)
end


-- ---------------------------------------------------------------------------
-- Event Handling
-- ---------------------------------------------------------------------------
-- UpdateOuterBorder does name fit, class/spec/PvP chrome — too expensive on every
-- UNIT_POWER_* tick (energy, fragmenting mana, etc.). Rarer events still call it directly.
local OUTER_BORDER_POWER_HEALTH_THROTTLE = 0.25

local function TryThrottledUpdateOuterBorder(self)
    if not self.UpdateOuterBorder then return end
    local now = GetTime()
    local nextOk = self._fluxOBThrottleNext
    if not nextOk or now >= nextOk then
        self._fluxOBThrottleNext = now + OUTER_BORDER_POWER_HEALTH_THROTTLE
        self:UpdateOuterBorder()
    end
end

--- Full refresh when target's target (or focus's target) changes via UNIT_TARGET.
local function RefreshTargetOfTargetFrameData(totFrame)
    if not totFrame then
        return
    end
    UF.SyncWatchedUnitFrameVisibility(totFrame)
    UF.UpdateHealth(totFrame, "targettarget")
    UF.UpdatePower(totFrame, "targettarget")
    UF.UpdatePortrait(totFrame, "targettarget")
    if totFrame.UpdatePartition then
        totFrame:UpdatePartition()
    end
    if totFrame.UpdateOuterBorder then
        totFrame:UpdateOuterBorder()
    end
    UF.UpdateBorderColors(totFrame)
end

--- Name/class chrome can lag one frame behind UNIT_TARGET; retry on the next tick.
local function DeferredTargetOfTargetChromeRefresh(totFrame, targetFrame)
    if not C_Timer or not C_Timer.After then
        return
    end
    C_Timer.After(0, function()
        if totFrame then
            UF.SyncWatchedUnitFrameVisibility(totFrame)
            if totFrame.UpdateOuterBorder then
                totFrame:UpdateOuterBorder()
            end
            UF.UpdateBorderColors(totFrame)
        end
        if targetFrame and targetFrame.UpdateOuterBorder then
            targetFrame:UpdateOuterBorder()
        end
    end)
end

local function OnEvent(self, event, unit, ...)
    -- 3D portraits need size + SetUnit refresh when UI scale or resolution changes
    if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        local function doPortraitMetrics()
            if self.PortraitFrame and self.Portrait then
                UF.RefreshPortraitAfterDisplayMetrics(self)
            end
        end
        doPortraitMetrics()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, doPortraitMetrics)
            C_Timer.After(0.05, doPortraitMetrics)
        end
        return
    end

    -- Special case for player frame: allow pet events to update the pet name display
    if unit and unit ~= self.unit then
        if self.unit == "player" and (unit == "pet") then
            -- Allow it
        elseif self.unit == "player" and unit == "vehicle" and event == "UNIT_COMBAT" then
            -- Vehicle combat feedback (same as Blizzard PlayerFrame)
        elseif self.unit == "targettarget" and event == "UNIT_TARGET" and unit == "target" then
            -- Target's target changed; unit is "target", not "targettarget"
        elseif self.unit == "focustarget" and event == "UNIT_TARGET" and unit == "focus" then
            -- Focus's target changed
        else
            return
        end
    end

    -- Full partition (portrait, atlas, separators, anchors) deferred from combat lockdown
    if event == "PLAYER_REGEN_ENABLED" and self.needsPartitionRelayout then
        self.needsPartitionRelayout = false
        local keepRegen = self.unit == "player" or self.unit == "target" or self.unit == "focus"
            or self.unit == "targettarget" or self.unit == "focustarget" or self.unit == "pet"
        if not keepRegen then
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        end
        if self.UpdatePartition then
            self:UpdatePartition()
        end
    end

    -- Combat icon (player) and threat bar (target): must run on every regen toggle.
    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        if event == "PLAYER_REGEN_ENABLED" then
            SyncRelatedWatchedFrames(self)
        end
        if self.unit == "player" and self.UpdateFrameVisualElements then
            self:UpdateFrameVisualElements()
        elseif (self.unit == "target" or self.unit == "focus") and UF.UpdateThreatBar then
            UF.UpdateThreatBar(self)
        end
        if self.unit == "player" then
            UF.UpdatePortraitCombatTint(self)
        end
    end

    if event == "UNIT_FLAGS" then
        UF.UpdatePortraitCombatTint(self)
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        UF.UpdateHealth(self, self.unit)
        TryThrottledUpdateOuterBorder(self)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        -- Druid form: DISPLAYPOWER + form both rebuild additional mana — coalesce partition.
        self._fluxPowerSpentEvent = (event == "UNIT_POWER_UPDATE")
        if event == "UNIT_DISPLAYPOWER" and self.unit == "player" then
            UF.UpdatePower(self, self.unit)
            if self.AdditionalPower then UF.UpdateAdditionalPower(self, self.unit) end
            if not self._fluxPowerTypePartitionPending then
                self._fluxPowerTypePartitionPending = true
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, function()
                        self._fluxPowerTypePartitionPending = nil
                        if self.UpdatePartition then self:UpdatePartition() end
                        TryThrottledUpdateOuterBorder(self)
                    end)
                else
                    self._fluxPowerTypePartitionPending = nil
                    if self.UpdatePartition then self:UpdatePartition() end
                    TryThrottledUpdateOuterBorder(self)
                end
            end
        else
            UF.UpdatePower(self, self.unit)
            if self.AdditionalPower then UF.UpdateAdditionalPower(self, self.unit) end
            TryThrottledUpdateOuterBorder(self)
        end
        self._fluxPowerSpentEvent = nil
    elseif event == "PLAYER_ENTERING_WORLD" then
        SyncRelatedWatchedFrames(self)

        UF.UpdateHealth(self, self.unit)
        UF.UpdatePower(self, self.unit)
        UF.UpdatePortrait(self, self.unit)
        UF.UpdatePortraitCombatTint(self)
        if self.AdditionalPower then UF.UpdateAdditionalPower(self, self.unit) end
        if self.UpdatePartition then self:UpdatePartition() end
        -- Update PvP indicators on entering world
        if self.UpdateOuterBorder then self:UpdateOuterBorder() end
        -- Update threat bar on entering world
        if (self.unit == "target" or self.unit == "focus") and UF.UpdateThreatBar then UF.UpdateThreatBar(self) end

        -- Note: Don't manually call BuffFrame_Update() as it can interfere with
        -- Blizzard's secure buff frame system and break right-click buff removal during combat.
        -- Blizzard's buff frame handles its own updates via UNIT_AURA events.
    elseif event == "UNIT_COMBAT" then
        local action, descriptor, damage, damageType = ...
        if self.portraitCombatFeedbackEnabled and UF.PortraitCombatFeedback_OnCombatEvent and action
            and (not FluxUnitFrames_ShouldShowPortraitCombat or FluxUnitFrames_ShouldShowPortraitCombat(self.unit)) then
            UF.PortraitCombatFeedback_OnCombatEvent(self, action, descriptor, damage, damageType)
        end
    elseif event == "UNIT_HEAL_PREDICTION" or 
           event == "UNIT_ABSORB_AMOUNT_CHANGED" or 
           event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
         UF.UpdateHealPrediction(self)
    elseif event == "UNIT_NAME_UPDATE" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
         SyncRelatedWatchedFrames(self)
         -- Handle target / focus / ToT / focus-ToT visibility and updates (like Blizzard)
         if self.unit == "target" and (event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_NAME_UPDATE" and unit == "target")) then
             -- Full frame update when target changes (even in combat) - like Blizzard's TargetFrame:Update()
             UF.UpdateHealth(self, self.unit)
             UF.UpdatePower(self, self.unit)
             if self.AdditionalPower then UF.UpdateAdditionalPower(self, self.unit) end
             UF.UpdatePortrait(self, self.unit)
             -- Update visual elements immediately (combat-safe) - like oUF does
             UF.UpdateFrameVisualElements(self)
             -- Update border colors immediately (combat-safe)
             UF.UpdateBorderColors(self)
             if self.UpdatePartition then self:UpdatePartition() end
             if self.UpdateOuterBorder then self:UpdateOuterBorder() end
             -- Update threat bar when target changes
             if UF.UpdateThreatBar then UF.UpdateThreatBar(self) end



             -- Update target of target data immediately (visibility handled by RegisterUnitWatch)
             if ns.TargetOfTargetFrame then
                 -- Update all data immediately regardless of visibility timing
                 UF.UpdateHealth(ns.TargetOfTargetFrame, "targettarget")
                 UF.UpdatePower(ns.TargetOfTargetFrame, "targettarget")
                 UF.UpdatePortrait(ns.TargetOfTargetFrame, "targettarget")
                 if ns.TargetOfTargetFrame.UpdatePartition then ns.TargetOfTargetFrame:UpdatePartition() end
                 
                 -- IMPORTANT: Explicitly update border/name for ToT when target changes
                 if ns.TargetOfTargetFrame.UpdateOuterBorder then ns.TargetOfTargetFrame:UpdateOuterBorder() end
                 UF.UpdateBorderColors(ns.TargetOfTargetFrame)
             end

             -- Flux custom buff/debuff icons: UNIT_AURA alone can lag or miss on target swap
             if UF.UpdateAuras then
                 UF.UpdateAuras(self)
             end
         elseif self.unit == "focus" and (event == "PLAYER_FOCUS_CHANGED" or (event == "UNIT_NAME_UPDATE" and unit == "focus")) then
             UF.UpdateHealth(self, self.unit)
             UF.UpdatePower(self, self.unit)
             if self.AdditionalPower then UF.UpdateAdditionalPower(self, self.unit) end
             UF.UpdatePortrait(self, self.unit)
             UF.UpdateFrameVisualElements(self)
             UF.UpdateBorderColors(self)
             if self.UpdatePartition then self:UpdatePartition() end
             if self.UpdateOuterBorder then self:UpdateOuterBorder() end
             if UF.UpdateThreatBar then UF.UpdateThreatBar(self) end
             if ns.FocusTargetFrame then
                 UF.UpdateHealth(ns.FocusTargetFrame, "focustarget")
                 UF.UpdatePower(ns.FocusTargetFrame, "focustarget")
                 UF.UpdatePortrait(ns.FocusTargetFrame, "focustarget")
                 if ns.FocusTargetFrame.UpdatePartition then ns.FocusTargetFrame:UpdatePartition() end
                 if ns.FocusTargetFrame.UpdateOuterBorder then ns.FocusTargetFrame:UpdateOuterBorder() end
                 UF.UpdateBorderColors(ns.FocusTargetFrame)
             end
             if UF.UpdateAuras then
                 UF.UpdateAuras(self)
             end
         elseif self.unit == "targettarget" and (event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_NAME_UPDATE" and unit == "targettarget")) then
             -- Update target of target frame
             UF.UpdateHealth(self, self.unit)
             UF.UpdatePower(self, self.unit)
             UF.UpdatePortrait(self, self.unit)
             if self.UpdatePartition then self:UpdatePartition() end
             if self.UpdateOuterBorder then self:UpdateOuterBorder() end
         elseif self.unit == "focustarget" and (event == "PLAYER_FOCUS_CHANGED" or (event == "UNIT_NAME_UPDATE" and unit == "focustarget")) then
             UF.UpdateHealth(self, self.unit)
             UF.UpdatePower(self, self.unit)
             UF.UpdatePortrait(self, self.unit)
             if self.UpdatePartition then self:UpdatePartition() end
             if self.UpdateOuterBorder then self:UpdateOuterBorder() end
         end

         -- Update outer border (name, etc.) for all frames
         if self.UpdateOuterBorder then self:UpdateOuterBorder() end

        -- Restart the target/focus bar if the new unit is already casting.
        -- Do not Hide first: a secret spell name used to fail the restart after Hide.
        if (self.unit == "target" or self.unit == "focus") and self.CastBar then
            local CB = ns.CastBar
            if CB and CB.RefreshCastForUnit then
                CB.RefreshCastForUnit(self.CastBar, self.unit)
            elseif self.CastBar.CastStart then
                self.CastBar:CastStart(self.unit)
            end
         end

    elseif event == "UNIT_TARGET" then
        -- Target switched targets (UNIT_TARGET on "target", not "targettarget")
        SyncRelatedWatchedFrames(self)
        if self.unit == "targettarget" and unit == "target" then
            UF.UpdateHealth(self, self.unit)
            UF.UpdatePower(self, self.unit)
            UF.UpdatePortrait(self, self.unit)
            if self.UpdatePartition then self:UpdatePartition() end
            if self.UpdateOuterBorder then self:UpdateOuterBorder() end
            UF.UpdateBorderColors(self)
            if ns.TargetFrame and ns.TargetFrame.UpdateOuterBorder then
                ns.TargetFrame:UpdateOuterBorder()
            end
            DeferredTargetOfTargetChromeRefresh(self, ns.TargetFrame)
        elseif self.unit == "target" and unit == "target" then
            RefreshTargetOfTargetFrameData(ns.TargetOfTargetFrame)
            if self.UpdateOuterBorder then
                self:UpdateOuterBorder()
            end
            DeferredTargetOfTargetChromeRefresh(ns.TargetOfTargetFrame, self)
        elseif self.unit == "focustarget" and unit == "focus" then
            UF.UpdateHealth(self, self.unit)
            UF.UpdatePower(self, self.unit)
            UF.UpdatePortrait(self, self.unit)
            if self.UpdatePartition then self:UpdatePartition() end
            if self.UpdateOuterBorder then self:UpdateOuterBorder() end
            UF.UpdateBorderColors(self)
            DeferredTargetOfTargetChromeRefresh(self, nil)
        end

    elseif event == "UPDATE_SHAPESHIFT_FORM" then
         UF.UpdatePower(self, self.unit)
         if self.AdditionalPower then UF.UpdateAdditionalPower(self, self.unit) end
         -- Share partition coalesce with UNIT_DISPLAYPOWER (same Druid mana bar flip).
         if self.unit == "player" then
             if not self._fluxPowerTypePartitionPending then
                 self._fluxPowerTypePartitionPending = true
                 if C_Timer and C_Timer.After then
                     C_Timer.After(0, function()
                         self._fluxPowerTypePartitionPending = nil
                         if self.UpdatePartition then self:UpdatePartition() end
                     end)
                 else
                     self._fluxPowerTypePartitionPending = nil
                     if self.UpdatePartition then self:UpdatePartition() end
                 end
             end
         elseif self.UpdatePartition then
             self:UpdatePartition()
         end
    elseif (event == "UNIT_CLASSIFICATION_CHANGED" and unit == self.unit) or
           (event == "UNIT_LEVEL" and unit == self.unit) or
           event == "PLAYER_LEVEL_UP" then
         -- Level, classification, or mob type may have changed - update immediately
         if self.UpdateOuterBorder then self:UpdateOuterBorder() end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE"
        or event == "PARTY_LEADER_CHANGED" or event == "PARTY_LOOT_METHOD_CHANGED" then
         if self.UpdateGroupText then self:UpdateGroupText() end
         -- Leader / assist / MT / MA / ML icons live on the name strip.
         if self.UpdateOuterBorder then self:UpdateOuterBorder() end
         -- Re-layout threat (portrait/vertical may gate on group membership).
         if (self.unit == "target" or self.unit == "focus") and UF.LayoutThreatBar then
             UF.LayoutThreatBar(self)
         elseif (self.unit == "target" or self.unit == "focus") and UF.UpdateThreatBar then
             UF.UpdateThreatBar(self)
         end
    elseif (event == "UNIT_FACTION" and unit == self.unit) or
           (event == "PLAYER_FLAGS_CHANGED" and unit == self.unit) then
         -- PvP state may have changed - immediate update (like ShadowedUnitFrames)
         if self.UpdateOuterBorder then self:UpdateOuterBorder() end
         -- Also update combat icon for player frame (resting status)
         if self.unit == "player" and self.UpdateFrameVisualElements then
             self:UpdateFrameVisualElements()
         end
         -- AFK toggles / flags: refresh bars without waiting for OnUpdate
         UF.UpdateHealth(self, self.unit)
         UF.UpdatePower(self, self.unit)
         if self.AdditionalPower then UF.UpdateAdditionalPower(self, self.unit) end
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or
           event == "ZONE_CHANGED_INDOORS" or event == "PLAYER_ENTERING_WORLD" then
         -- Zone changes can affect PvP status - update indicators
         if self.UpdateOuterBorder then self:UpdateOuterBorder() end
    elseif event == "RAID_TARGET_UPDATE" then
        if self.raidIcon then
            -- Use oUF approach: SetRaidTargetIconTexture handles secret values properly
            local index = GetRaidTargetIndex(self.unit)
            if index then
                SetRaidTargetIconTexture(self.raidIcon, index)
                self.raidIcon:Show()
            else
                self.raidIcon:Hide()
            end
        end
    elseif event == "UNIT_THREAT_LIST_UPDATE" then
        -- Update threat bar when threat list changes
        if (self.unit == "target" or self.unit == "focus") and UF.UpdateThreatBar then UF.UpdateThreatBar(self) end
    elseif event == "UNIT_PET" or (event == "UNIT_NAME_UPDATE" and (unit == "pet" or unit == self.unit)) then
        if self.unit == "pet" then
            SyncRelatedWatchedFrames(self)
        end
        if self.unit == "player" and self.UpdateOuterBorder then
            self:UpdateOuterBorder()
        end
    elseif event == "UNIT_HAPPINESS" then
        if self.unit == "player" and self.UpdateOuterBorder then
            self:UpdateOuterBorder()
        end
    end
end

-- ---------------------------------------------------------------------------
-- Emulated horizontal squeeze (matches trinket dependent X at full 19-button layout; UI scale only)
-- ---------------------------------------------------------------------------
local emulatedSqueezeFrames = {}
local emulatedSqueezeEventFrame = nil

local function ApplyEmulatedHorizontalSqueezeToFrame(frame)
    if not frame or not frame._fluxLayoutBaseWidth then return end
    if InCombatLockdown() then
        return
    end
    -- Side-by-side player+target (placement 2): keep focus at configured width — squeeze reads like the frame
    -- "shrinks" as its right edge meets the player stack; emulated bar squeeze still applies to other frames.
    local mult = 1
    local skipFocusSqueeze = frame.unit == "focus"
        and FluxUnitFrames_GetPlayerTargetPlacement
        and FluxUnitFrames_GetPlayerTargetPlacement() == 2
    if not skipFocusSqueeze then
        local g = FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames
        mult = (g and g()) or 1
    end
    frame:SetWidth(frame._fluxLayoutBaseWidth * mult)
    if frame.UpdatePartition then
        frame:UpdatePartition()
    end
    if frame.UpdateAtlasBorder then
        frame:UpdateAtlasBorder()
    end
    if frame.UpdateOuterBorder then
        frame:UpdateOuterBorder()
    end
end

function UF.ApplyEmulatedHorizontalSqueezeForFrame(frame)
    ApplyEmulatedHorizontalSqueezeToFrame(frame)
end

function UF.UpdateAllEmulatedHorizontalSqueeze()
    for fr in pairs(emulatedSqueezeFrames) do
        if fr and fr.GetWidth then
            ApplyEmulatedHorizontalSqueezeToFrame(fr)
        end
    end
    if FluxUILayoutSqueeze and FluxUILayoutSqueeze.NotifyLayoutDependents then
        pcall(FluxUILayoutSqueeze.NotifyLayoutDependents)
    end
end

--- Global hook: keep emulated X squeeze on unit frames in sync (options resize, action bar relayout at min UI scale).
function FluxUnitFrames_UpdateAllEmulatedHorizontalSqueeze()
    UF.UpdateAllEmulatedHorizontalSqueeze()
end

function UF.RegisterEmulatedHorizontalSqueeze(frame)
    if not frame then return end
    if not frame._fluxLayoutBaseWidth then
        local w = frame:GetWidth()
        frame._fluxLayoutBaseWidth = (type(w) == "number" and w > 0) and w or 250
    end
    emulatedSqueezeFrames[frame] = true
    if not emulatedSqueezeEventFrame then
        emulatedSqueezeEventFrame = CreateFrame("Frame")
        emulatedSqueezeEventFrame:RegisterEvent("UI_SCALE_CHANGED")
        emulatedSqueezeEventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
        emulatedSqueezeEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        emulatedSqueezeEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        local function refreshFromLayoutChange()
            if FluxUILayoutSqueeze and FluxUILayoutSqueeze.InvalidateEmulatedDependentCache then
                FluxUILayoutSqueeze.InvalidateEmulatedDependentCache()
            end
            UF.UpdateAllEmulatedHorizontalSqueeze()
        end
        emulatedSqueezeEventFrame:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_ENABLED" then
                if FluxUILayoutSqueeze and FluxUILayoutSqueeze.InvalidateEmulatedDependentCache then
                    FluxUILayoutSqueeze.InvalidateEmulatedDependentCache()
                end
                UF.UpdateAllEmulatedHorizontalSqueeze()
                return
            end
            refreshFromLayoutChange()
            if event == "PLAYER_ENTERING_WORLD" then
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, refreshFromLayoutChange)
                    C_Timer.After(0.05, refreshFromLayoutChange)
                else
                    refreshFromLayoutChange()
                end
            end
        end)
    end
    ApplyEmulatedHorizontalSqueezeToFrame(frame)
end

-- ---------------------------------------------------------------------------
-- Base Frame Construction
-- ---------------------------------------------------------------------------
--- @param borderInsetY optional bottom backdrop inset for Border:ApplyTo (default 6); use 2 for minimal frames like focustarget
function UF.CreateBaseFrame(unit, parent, width, height, borderInsetY)
    -- Create SecureUnitButton for click-to-target/menu functionality
    local frame = CreateFrame("Button", "FluxUnitFrame_"..unit, parent, "SecureUnitButtonTemplate")
    SecureUnitButton_OnLoad(frame, unit)
    frame:SetAttribute("unit", unit)
    -- Above action strip / pet / stance (those sit on MEDIUM at level 5).
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(40)

    -- Disable mouse on main frame - outer border handles all interaction
    frame:EnableMouse(false)
    frame:SetMouseClickEnabled(false)

    -- Click handling will be set up on the outer border frame instead

    frame.unit = unit

    -- Set size (defaults if not provided)
    width = width or 250
    height = height or 100
    frame:SetSize(width, height)
    frame._fluxLayoutBaseWidth = width
    UF.RegisterEmulatedHorizontalSqueeze(frame)

    -- Script Handlers
    frame:SetScript("OnEvent", OnEvent)
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UI_SCALE_CHANGED")
    frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    frame:RegisterUnitEvent("UNIT_HEALTH", unit)
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    frame:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
    frame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit)
    -- Heal Prediction & Absorb Events (safe-register for pre-DF clients where events may not exist)
    FluxSafeRegisterUnitEvent(frame, "UNIT_HEAL_PREDICTION", unit)
    FluxSafeRegisterUnitEvent(frame, "UNIT_ABSORB_AMOUNT_CHANGED", unit)
    FluxSafeRegisterUnitEvent(frame, "UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit)

    -- Additional useful events
    if unit == "target" then
         frame:RegisterEvent("PLAYER_TARGET_CHANGED")
         frame:RegisterEvent("PLAYER_REGEN_ENABLED")
         -- Register for automatic show/hide based on unit existence
         RegisterUnitWatch(frame)
         -- Self-as-target surname / name changes (Forever UnitSurnameOwn).
         frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
         -- Register events for level/classification/mob type updates (like oUF tags system)
         frame:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", unit)
         frame:RegisterUnitEvent("UNIT_LEVEL", unit)
         frame:RegisterEvent("PLAYER_LEVEL_UP") -- For when player levels up (affects difficulty colors)
         frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    elseif unit == "targettarget" then
         frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
         frame:RegisterEvent("PLAYER_TARGET_CHANGED") -- For when target changes
         frame:RegisterEvent("PLAYER_REGEN_ENABLED")

         -- Register for updates when your target switches targets (fixes "Unknown" name)
         frame:RegisterUnitEvent("UNIT_TARGET", "target")

         -- Register for automatic show/hide based on unit existence
         RegisterUnitWatch(frame)
         -- Unit events are registered dynamically in the frame's OnEvent handler
         frame:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", unit)
         frame:RegisterUnitEvent("UNIT_LEVEL", unit)
    elseif unit == "focus" then
         if FluxSafeRegisterEvent then
             FluxSafeRegisterEvent(frame, "PLAYER_FOCUS_CHANGED")
         else
             frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
         end
         frame:RegisterEvent("PLAYER_REGEN_ENABLED")
         RegisterUnitWatch(frame)
         frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
         frame:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", unit)
         frame:RegisterUnitEvent("UNIT_LEVEL", unit)
         frame:RegisterEvent("PLAYER_LEVEL_UP")
         frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    elseif unit == "focustarget" then
         frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
         if FluxSafeRegisterEvent then
             FluxSafeRegisterEvent(frame, "PLAYER_FOCUS_CHANGED")
         else
             frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
         end
         frame:RegisterUnitEvent("UNIT_TARGET", "focus")
         frame:RegisterEvent("PLAYER_REGEN_ENABLED")
         RegisterUnitWatch(frame)
         frame:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", unit)
         frame:RegisterUnitEvent("UNIT_LEVEL", unit)
    elseif unit == "player" then
         -- Register for pet updates to show pet name on player frame
         frame:RegisterEvent("UNIT_PET")
         if FluxSafeRegisterEvent then
             FluxSafeRegisterEvent(frame, "UNIT_HAPPINESS")
         end
         -- One RegisterUnitEvent: a second call would replace the pet filter.
         frame:RegisterUnitEvent("UNIT_NAME_UPDATE", "player", "pet")
         -- Player frame does not register UNIT_AURA; Blizzard BuffFrame/DebuffFrame handle their own events.
         -- Target auras use FluxUnitFrames_Auras (separate auraEventFrame on the target frame only).
         -- Register events for combat/resting status updates
         frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entered combat
         frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Left combat
         frame:RegisterEvent("PLAYER_FLAGS_CHANGED") -- Resting status changed
    end

    -- Group/raid events for group number + status icons (leader / MT / ML, etc.)
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    frame:RegisterEvent("PARTY_LEADER_CHANGED")
    if FluxSafeRegisterEvent then
        FluxSafeRegisterEvent(frame, "PARTY_LOOT_METHOD_CHANGED")
    else
        pcall(function() frame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED") end)
    end

    -- PvP events - following ShadowedUnitFrames classic approach
    frame:RegisterUnitEvent("UNIT_FACTION", frame.unit)
    frame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", frame.unit)
    -- Per-unit combat for the portrait tint (target/focus/pet, not only the player).
    FluxSafeRegisterUnitEvent(frame, "UNIT_FLAGS", frame.unit)
    -- Additional events that can trigger PvP status changes
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("ZONE_CHANGED_INDOORS")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Apply Border with better bottom padding to fully cover bars (focustarget uses tighter bottom)
    Border:ApplyTo(frame, 2, 2, 2, borderInsetY or 6)

    -- Target / ToT / focus / focustarget: unit class tint always. Other frames: global Appearance accent.
    if frame.unit == "target" or frame.unit == "targettarget" or frame.unit == "focus" or frame.unit == "focustarget" then
        local color = GetUnitClassColor(frame.unit)
        local _, _, _, br, bg, bb = UF.ForeverNpcChrome(frame.unit)
        Border:SetBorderColor(frame, color.r, color.g, color.b, 1)
        if br then
            Border:SetBackdropColor(frame, br, bg, bb, 0.85)
        else
            Border:SetBackdropColor(frame, color.r * 0.4, color.g * 0.4, color.b * 0.4, 0.85)
        end
    else
        Border:SetClassColor(frame, 1, true)
    end
    
    -- Bind Partition Method
    frame.UpdatePartition = UF.UpdateFramePartition
    frame.UpdateOuterBorder = UF.UpdateOuterBorder
    frame.UpdateFrameVisualElements = UF.UpdateFrameVisualElements
    frame.UpdateBorderColors = UF.UpdateBorderColors

    -- Flux perf T2.6b: register with shared poll frame (no per-frame OnUpdate on each unit frame).
    if frame.unit == "player" then
        UF.RegisterUnitFramePoll(frame, { health = true, power = true })
    elseif frame.unit == "targettarget" or frame.unit == "focustarget" then
        UF.RegisterUnitFramePoll(frame, { health = true, power = true })
    elseif frame.unit == "target" or frame.unit == "focus" then
        UF.RegisterUnitFramePoll(frame, { health = true, threat = UF.UpdateThreatBar and true or nil })
    end

    -- Separator textures must not live under SecureUnitButton (ClearAllPoints blocked in combat)
    local sepContainer = CreateFrame("Frame", nil, UIParent)
    sepContainer:SetFrameStrata(frame:GetFrameStrata())
    sepContainer:SetFrameLevel(frame:GetFrameLevel() + 10)
    sepContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    sepContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    sepContainer:SetShown(frame:IsShown())
    frame.SeparatorContainer = sepContainer
    frame:HookScript("OnShow", function()
        if not frame.SeparatorContainer then
            return
        end
        local want = true
        if UF.ShouldShowWatchedUnitFrame and (frame.unit == "target" or frame.unit == "focus"
            or frame.unit == "targettarget" or frame.unit == "focustarget"
            or frame.unit == "pet" or frame.unit == "pettarget") then
            want = UF.ShouldShowWatchedUnitFrame(frame)
        end
        frame.SeparatorContainer:SetShown(want)
    end)
    frame:HookScript("OnHide", function()
        if frame.SeparatorContainer then frame.SeparatorContainer:Hide() end
    end)

    -- Create Separators (Early)
    frame.HealthPowerSeparator = CreateSeparator(frame)
    frame.PowerAdditionalSeparator = CreateSeparator(frame)
    frame.PowerAdditionalSeparator:Hide()

    if unit == "target" or unit == "targettarget" or unit == "focus"
        or unit == "focustarget" or unit == "pet" or unit == "pettarget" then
        UF.SyncWatchedUnitFrameVisibility(frame)
    end

    return frame
end

local function ClearUnitFrameNamePaintCache(frame)
    if not frame then
        return
    end
    frame._fluxLastRealName = nil
    if frame.nameText then
        frame.nameText._fluxNameFitKey = nil
    end
end

local function UnitFrameTokenIsPlayer(unit)
    if type(unit) ~= "string" or unit == "" then
        return false
    end
    local PN = ns.Flux and ns.Flux.PlayerName
    if PN and PN.IsUnitPlayer then
        return PN.IsUnitPlayer(unit) and true or false
    end
    if not UnitIsUnit then
        return unit == "player"
    end
    local ok, isMe = pcall(UnitIsUnit, unit, "player")
    return ok and isMe and true or false
end

local function RefreshUnitFrameDisplayName(frame, always)
    if not frame then
        return
    end
    if not always and not UnitFrameTokenIsPlayer(frame.unit) then
        return
    end
    ClearUnitFrameNamePaintCache(frame)
    if frame.UpdateOuterBorder then
        frame:UpdateOuterBorder()
    end
end

--- Forever UnitSurnameOwn: given vs given+surname on the player's own frames.
function UF.RefreshSelfDisplayNames()
    RefreshUnitFrameDisplayName(ns.PlayerFrame, true)
    RefreshUnitFrameDisplayName(ns.TargetFrame)
    RefreshUnitFrameDisplayName(ns.FocusFrame)
    RefreshUnitFrameDisplayName(ns.TargetOfTargetFrame)
    RefreshUnitFrameDisplayName(ns.FocusTargetFrame)
    if type(FluxRaid_RefreshSelfDisplayNames) == "function" then
        FluxRaid_RefreshSelfDisplayNames()
    end
end

do
    local surnameCvarListener = CreateFrame("Frame")
    surnameCvarListener:RegisterEvent("CVAR_UPDATE")
    surnameCvarListener:SetScript("OnEvent", function(_, _, cvarName)
        if type(cvarName) ~= "string" or string.lower(cvarName) ~= "unitsurnameown" then
            return
        end
        UF.RefreshSelfDisplayNames()
    end)
end

function FluxUnitFrames_RefreshAppearanceChrome()
    local frames = { ns.PlayerFrame, ns.TargetFrame, ns.PetFrame, ns.TargetOfTargetFrame, ns.FocusFrame, ns.FocusTargetFrame }
    for _, frame in ipairs(frames) do
        if frame and frame.UpdatePartition then
            frame:UpdatePartition()
        end
        if frame and UF.UpdateBorderColors then
            UF.UpdateBorderColors(frame)
        end
        if frame and UF.UpdatePortraitCombatTint then
            UF.UpdatePortraitCombatTint(frame)
        end
        if frame and UF.UpdateFrameVisualElements then
            UF.UpdateFrameVisualElements(frame)
        end
    end
    if ns.PetTargetFrame and FluxBorder and FluxBorder.RefreshClassColor then
        FluxBorder:RefreshClassColor(ns.PetTargetFrame)
    end
end
