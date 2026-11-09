-- UnitFrames/FluxHealthLossOverlay.lua
-- Red trailing health bar on every client.
-- Readable horizontal HUD bars use AnimatedHealthLossMixin; Classic/vertical
-- gaps use the same cadence (0.25s, start 0.1, pause 0.05, postpone 0.05).
-- Secret combat values are not read: the loss bar stays on the previous SetValue for 0.1s,
-- then SetValue(current, ExponentialEaseOut). A newer hit postpones that set by 0.05s.
local addonName, ns = ...
ns.HealthLossOverlay = ns.HealthLossOverlay or {}
local HLO = ns.HealthLossOverlay
local API = ns.API
local UF = ns.UnitFrames

local TEXTURE_BAR = "Interface\\TargetingFrame\\UI-StatusBar"
local START_DELAY = 0.1
local POSTPONE_DELAY = 0.05
local SECRET_EASE_HIDE = 0.6

local function CanRead(value)
    if API and API.IsSecretValue and API.IsSecretValue(value) then return false end
    return not (API and API.CanAccessValue) or API.CanAccessValue(value)
end

local function ReadableNumber(value)
    if not CanRead(value) or type(value) ~= "number" then return nil end
    if value ~= value or value <= -math.huge or value >= math.huge then return nil end
    return value
end

local function ReadableGUID(unit)
    local guid = unit and UnitGUID and UnitGUID(unit)
    if not CanRead(guid) or type(guid) ~= "string" then return nil end
    return guid
end

local function IsVertical(bar)
    if bar and bar._fluxVerticalHealthBar then return true end
    local orientation = bar and bar.GetOrientation and bar:GetOrientation()
    return CanRead(orientation) and orientation == "VERTICAL"
end

-- Retain the established pixel-cache names; vertical bars store axis length.
local function TryLayoutWidth(region)
    if not region then return nil end
    local cached = ReadableNumber(region._fluxHealthLossExtent)
    if cached and cached > 0 then return cached end
    local getter = IsVertical(region) and region.GetHeight or region.GetWidth
    local extent = getter and ReadableNumber(getter(region))
    if extent and extent > 0 then return math.min(extent, 100000) end
end

local function GetHealthFillWidth(healthBar)
    local fill = healthBar:GetStatusBarTexture()
    local getter = fill and (IsVertical(healthBar) and fill.GetHeight or fill.GetWidth)
    local extent = getter and ReadableNumber(getter(fill))
    if extent and extent >= 0 then return extent end
end

local function UsesHud()
    return UF and UF.UsesHudUnitBars and UF.UsesHudUnitBars()
end

local function EnsureClassicLossTex(healthBar)
    if healthBar.ClassicLossTex then
        return healthBar.ClassicLossTex
    end
    -- Above the status bar. Classic often draws the fill texture across the
    -- whole bar, so a texture behind it never shows the gap.
    local host = healthBar.ClassicLossHost
    if not host then
        host = CreateFrame("Frame", nil, healthBar:GetParent() or healthBar)
        host:SetAllPoints(healthBar)
        host:SetFrameLevel((healthBar:GetFrameLevel() or 0) + 3)
        host:EnableMouse(false)
        healthBar.ClassicLossHost = host
    end
    local tex = host:CreateTexture(nil, "ARTWORK")
    tex:SetTexture(TEXTURE_BAR)
    tex:SetVertexColor(1, 0, 0, 1)
    tex:Hide()
    healthBar.ClassicLossTex = tex
    return tex
end

local function HideClassicLoss(healthBar)
    local tex = healthBar and healthBar.ClassicLossTex
    if not tex then
        return
    end
    tex:Hide()
    tex._animStart = nil
    tex._animFrom = nil
    tex._animTo = nil
    tex._displayedEdge = nil
    if tex._driver then
        tex._driver:Hide()
    end
end

local function PlaceClassicLossGap(healthBar, tex, edge)
    local gap = edge - (tex._animTo or 0)
    if gap < 1 then HideClassicLoss(healthBar); return end
    tex._displayedEdge = edge
    tex:ClearAllPoints()
    if IsVertical(healthBar) then
        tex:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", 0, tex._animTo or 0)
        tex:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, tex._animTo or 0)
        tex:SetHeight(gap)
    else
        tex:SetPoint("TOPLEFT", healthBar, "TOPLEFT", tex._animTo or 0, 0)
        tex:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", tex._animTo or 0, 0)
        tex:SetWidth(gap)
    end
    tex:Show()
end

local function EnsureClassicLossDriver(healthBar)
    local tex = EnsureClassicLossTex(healthBar)
    if not tex._driver then
        local driver = CreateFrame("Frame", nil, healthBar)
        tex._driver = driver
        driver:Hide()
        driver:SetScript("OnUpdate", function()
            if not tex._animStart then driver:Hide(); return end
            local elapsed = GetTime() - tex._animStart
            if elapsed < 0 then return end
            local t = elapsed / .25
            if t >= 1 then HideClassicLoss(healthBar); return end
            PlaceClassicLossGap(healthBar, tex, tex._animFrom + (tex._animTo - tex._animFrom) * t)
        end)
    end
    return tex
end

local function DriveClassicLoss(healthBar, fromW, toW)
    local tex = EnsureClassicLossDriver(healthBar)
    local barW = TryLayoutWidth(healthBar) or fromW
    if not barW or barW < 1 or not fromW or not toW or fromW <= toW + .5 then
        if tex._animStart and toW and tex._animFrom and toW >= tex._animFrom - .5 then HideClassicLoss(healthBar) end
        return
    end
    local now = GetTime()
    if tex._animStart and now < tex._animStart then
        tex._animStart = tex._animStart + .05
        tex._animFrom = math.max(tex._animFrom or fromW, fromW)
    elseif tex._animStart and tex:IsShown() then
        -- A texture's size is the red gap, not its trailing edge.
        tex._animFrom = math.max(tex._displayedEdge or fromW, fromW)
        tex._animStart = now + .05
    else
        tex._animFrom = fromW
        tex._animStart = now + START_DELAY
    end
    tex._animTo = toW
    tex._begun = true
    PlaceClassicLossGap(healthBar, tex, tex._animFrom)
    tex._driver:Show()
end

local function PrepareVerticalLoss(healthBar)
    if not IsVertical(healthBar) then return true end
    local loss = healthBar.AnimatedLossBar
    if InCombatLockdown and InCombatLockdown() and (not loss or not healthBar.ClassicLossTex) then return false end
    if not loss then
        loss = CreateFrame("StatusBar", nil, healthBar:GetParent() or healthBar)
        healthBar.AnimatedLossBar = loss
    end
    if not loss._fluxHealthLossVertical then
        loss:SetAllPoints(healthBar)
        loss:SetFrameLevel(math.max(0, (healthBar._fluxPublicFrameLevel or healthBar:GetFrameLevel()) - 1))
        loss:SetOrientation("VERTICAL")
        loss:SetStatusBarTexture(TEXTURE_BAR)
        local fill = loss:GetStatusBarTexture()
        fill:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
        loss._fluxHealthLossVertical = true
        loss:Hide()
    end
    local tex = EnsureClassicLossDriver(healthBar)
    if tex.SetTexCoord then tex:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1) end
    return true
end

local function Interpolation(name)
    return Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation[name]
end

local function SetLossValue(loss, value, interpolation)
    if interpolation then
        local ok = pcall(loss.SetValue, loss, value, interpolation)
        if ok then
            return
        end
    end
    pcall(loss.SetValue, loss, value)
end

local function AbsorbBlocks(unit)
    if not unit or not UnitGetTotalAbsorbs then
        return false
    end
    local absorb = UnitGetTotalAbsorbs(unit)
    if API and API.IsSecretValue and API.IsSecretValue(absorb) then
        return false
    end
    if API and API.CanAccessValue and not API.CanAccessValue(absorb) then
        return false
    end
    local n = API and API.SafeGetNumber and API.SafeGetNumber(absorb, 0) or 0
    return type(n) == "number" and n > 0
end

local function SyncLossImmediate(healthBar)
    local loss = healthBar and healthBar.AnimatedLossBar
    local unit = healthBar and healthBar._fluxHealthLossUnit
    if not loss or not unit then
        return
    end
    pcall(function()
        loss:SetMinMaxValues(0, UnitHealthMax(unit))
    end)
    SetLossValue(loss, UnitHealth(unit), Interpolation("Immediate"))
    loss:Hide()
    loss.animationStartTime = nil
    loss.animationCompletePercent = nil
    if loss._pixelDriver then
        loss._pixelDriver:Hide()
    end
    healthBar._fluxLossSecretPending = false
    healthBar._fluxLossVerticalNativeActive = nil
end

local function FeedLoss(healthBar, currentW, previousW)
    local loss = healthBar and healthBar.AnimatedLossBar
    if not loss or not loss.UpdateFromPixels then
        return
    end
    if type(currentW) ~= "number" or type(previousW) ~= "number" then
        return
    end
    local barW = TryLayoutWidth(healthBar) or previousW
    if barW < 1 then
        return
    end
    loss.unit = healthBar._fluxHealthLossUnit or loss.unit
    loss:UpdateFromPixels(currentW, previousW, barW)
end

local function ScheduleSecretCatchUp(healthBar)
    local loss = healthBar.AnimatedLossBar
    local unit = healthBar._fluxHealthLossUnit
    if not loss or not unit then
        return
    end
    if AbsorbBlocks(unit) then
        SyncLossImmediate(healthBar)
        return
    end

    pcall(function()
        loss:SetMinMaxValues(0, UnitHealthMax(unit))
    end)
    loss:SetStatusBarColor(1, 0, 0, 1)
    loss:Show()

    local delay = healthBar._fluxLossSecretPending and POSTPONE_DELAY or START_DELAY
    healthBar._fluxLossSecretPending = true
    healthBar._fluxLossSecretSeq = (healthBar._fluxLossSecretSeq or 0) + 1
    local seq = healthBar._fluxLossSecretSeq

    if not (C_Timer and C_Timer.After) then
        SetLossValue(loss, UnitHealth(unit), Interpolation("ExponentialEaseOut") or Interpolation("Immediate"))
        healthBar._fluxLossSecretPending = false
        return
    end

    C_Timer.After(delay, function()
        if healthBar._fluxLossSecretSeq ~= seq then
            return
        end
        if not healthBar._fluxHealthLossUnderlay then
            return
        end
        healthBar._fluxLossSecretPending = false
        if AbsorbBlocks(unit) then
            SyncLossImmediate(healthBar)
            return
        end
        SetLossValue(loss, UnitHealth(unit), Interpolation("ExponentialEaseOut") or Interpolation("Immediate"))
        C_Timer.After(SECRET_EASE_HIDE, function()
            if healthBar._fluxLossSecretSeq ~= seq then
                return
            end
            if healthBar._fluxLossSecretPending then
                return
            end
            loss:Hide()
            healthBar._fluxLossVerticalNativeActive = nil
        end)
    end)
end

function HLO.DisableForHealthBar(healthBar)
    if not healthBar then
        return
    end
    healthBar._fluxHealthLossUnderlay = nil
    healthBar._fluxUseHealthLossOverlay = false
    healthBar._fluxHealthLossUnit = nil
    healthBar._fluxLossSecretPending = false
    healthBar._fluxLossSecretSeq = (healthBar._fluxLossSecretSeq or 0) + 1
    healthBar._fluxLossPrimed = nil
    healthBar._fluxLossGUID = nil
    healthBar._fluxLossSampleUnit = nil
    healthBar._fluxLossPrevHealth = nil
    healthBar._fluxLossPrevMaxHealth = nil
    healthBar._fluxLossLastHealthOpaque = nil
    healthBar._fluxLossVerticalNativeActive = nil
    healthBar._fluxLossPrevFillW = nil
    HideClassicLoss(healthBar)
    local loss = healthBar.AnimatedLossBar
    if loss then
        loss:Hide()
        loss.animationStartTime = nil
        loss.animationCompletePercent = nil
        if loss._pixelDriver then
            loss._pixelDriver:Hide()
        end
    end
end

-- Existing unit-frame identity events reset opaque target swaps. Resetting on
-- every inaccessible GUID sample would suppress the health-loss trail.
function HLO.ResetIdentityForFrame(frame)
    local bar = frame and frame.Health
    if not bar or not bar._fluxHealthLossUnderlay then return end
    bar._fluxLossPrimed = nil
    bar._fluxLossGUID = nil
    bar._fluxLossSampleUnit = nil
    bar._fluxLossPrevHealth = nil
    bar._fluxLossPrevMaxHealth = nil
    bar._fluxLossLastHealthOpaque = nil
    bar._fluxLossVerticalNativeActive = nil
    bar._fluxLossPrevFillW = nil
    bar._fluxLossSecretSeq = (bar._fluxLossSecretSeq or 0) + 1
    bar._fluxLossSecretPending = false
    HideClassicLoss(bar)
    local loss = bar.AnimatedLossBar
    if loss then
        loss:Hide()
        loss.animationStartTime = nil
        loss.animationCompletePercent = nil
        if loss._pixelDriver then loss._pixelDriver:Hide() end
    end
end

local function ReadableHealth(unit)
    if not unit then return nil, nil end
    local h, m = ReadableNumber(UnitHealth(unit)), ReadableNumber(UnitHealthMax(unit))
    if not h or not m or m <= 0 then return nil, nil end
    return h, m
end

function HLO.OnBeforeHealthValueSet(healthBar)
    if not healthBar or not healthBar._fluxHealthLossUnderlay then
        return
    end
    if not IsVertical(healthBar) then healthBar._fluxLossPrevFillW = GetHealthFillWidth(healthBar) end
end

function HLO.OnAfterHealthValueSet(healthBar)
    if not healthBar or not healthBar._fluxHealthLossUnderlay then
        return
    end

    local unit = healthBar._fluxHealthLossUnit
    local guid = ReadableGUID(unit)
    -- Keep the last plain GUID through restricted samples. Public identity
    -- events reset opaque unit swaps without dropping the first combat hit.
    if not CanRead(healthBar._fluxLossGUID)
        or (guid and healthBar._fluxLossGUID and guid ~= healthBar._fluxLossGUID)
        or unit ~= healthBar._fluxLossSampleUnit or not healthBar._fluxLossPrimed then
        healthBar._fluxLossGUID = guid
        healthBar._fluxLossSampleUnit = unit
        healthBar._fluxLossPrimed = true
        healthBar._fluxLossPrevFillW = nil
        healthBar._fluxLossSecretSeq = (healthBar._fluxLossSecretSeq or 0) + 1
        if not UsesHud() or IsVertical(healthBar) then
            local h, m = ReadableHealth(unit)
            healthBar._fluxLossPrevHealth = h
            healthBar._fluxLossPrevMaxHealth = m
            HideClassicLoss(healthBar)
        end
        SyncLossImmediate(healthBar)
        return
    end
    if guid then healthBar._fluxLossGUID = guid end

    if IsVertical(healthBar) then
        local h, m = ReadableHealth(unit)
        local previous = ReadableNumber(healthBar._fluxLossPrevHealth)
        local previousMax = ReadableNumber(healthBar._fluxLossPrevMaxHealth)
        local extent = TryLayoutWidth(healthBar)
        if h and m and (healthBar._fluxLossLastHealthOpaque or healthBar._fluxLossVerticalNativeActive) then
            HideClassicLoss(healthBar)
            healthBar._fluxLossLastHealthOpaque = nil
            healthBar._fluxLossVerticalNativeActive = true
            ScheduleSecretCatchUp(healthBar)
        elseif h and m and previous then
            if m ~= previousMax or h > previous or AbsorbBlocks(unit) then
                HideClassicLoss(healthBar)
            elseif h < previous and extent then
                DriveClassicLoss(healthBar, previous / m * extent, h / m * extent)
            elseif h < previous then
                ScheduleSecretCatchUp(healthBar)
            end
            if extent or h >= previous or m ~= previousMax then
                healthBar._fluxLossSecretSeq = (healthBar._fluxLossSecretSeq or 0) + 1
                SyncLossImmediate(healthBar)
            end
        elseif not h or not m then
            HideClassicLoss(healthBar)
            healthBar._fluxLossLastHealthOpaque = true
            healthBar._fluxLossVerticalNativeActive = true
            ScheduleSecretCatchUp(healthBar)
        else
            SyncLossImmediate(healthBar)
        end
        if h then healthBar._fluxLossPrevHealth = h end
        if m then healthBar._fluxLossPrevMaxHealth = m end
        return
    end

    local oldW = ReadableNumber(healthBar._fluxLossPrevFillW)
    healthBar._fluxLossPrevFillW = nil
    local newW = GetHealthFillWidth(healthBar)

    if not UsesHud() then
        -- UnitHealth is already the new value before OnBefore runs, so the
        -- previous sample is the one saved at the end of the last update.
        local h, m = ReadableHealth(unit)
        local prevH = ReadableNumber(healthBar._fluxLossPrevHealth)
        local bw = TryLayoutWidth(healthBar)
        if type(prevH) == "number" and type(h) == "number" and type(m) == "number" and bw and bw > 0 then
            DriveClassicLoss(healthBar, (prevH / m) * bw, (h / m) * bw)
        end
        if type(h) == "number" then
            healthBar._fluxLossPrevHealth = h
        end
        return
    end

    if type(oldW) == "number" and type(newW) == "number" then
        if oldW > newW + 0.5 or (healthBar.AnimatedLossBar and healthBar.AnimatedLossBar.animationStartTime) then
            FeedLoss(healthBar, newW, oldW)
        end
        return
    end

    ScheduleSecretCatchUp(healthBar)
end

function HLO.Initialize(frame)
    if not frame or not frame.Health then
        return
    end
    if not PrepareVerticalLoss(frame.Health) then
        HLO.DisableForHealthBar(frame.Health)
        return
    end
    local enabled = not FluxUnitFrames_IsFeatureEnabled or FluxUnitFrames_IsFeatureEnabled("healthLossOverlay")
    if not enabled then
        HLO.DisableForHealthBar(frame.Health)
        return
    end
    frame.Health._fluxHealthLossUnderlay = true
    frame.Health._fluxUseHealthLossOverlay = true
    frame.Health._fluxHealthLossUnit = frame.unit
    HLO.ResetIdentityForFrame(frame)
    local loss = frame.Health.AnimatedLossBar
    if loss then
        loss.unit = frame.unit
        loss:SetStatusBarColor(1, 0, 0, 1)
        loss:Hide()
        loss.animationStartTime = nil
        loss.animationCompletePercent = nil
    end
end
