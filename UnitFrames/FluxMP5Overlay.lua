-- UnitFrames/FluxMP5Overlay.lua
-- MP5 (Five Second Rule) and mana tick overlay for Era, Anniversary/TBC, and Forever
-- Layers over the mana bar like FiveSecondRule does over Blizzard's PlayerFrameManaBar
local addonName, ns = ...
ns.MP5Overlay = ns.MP5Overlay or {}

local MP5 = ns.MP5Overlay

-- Tick-based mana clients, including Forever's Classic gameplay.
local function ShouldEnable()
    local client = ns.Flux and ns.Flux.Client or FLUX_API
    return client and (client.isEra or client.isClassicEra or client.isTBC
        or client.isAnniversary or client.isForever or client.isCamelot) and true or false
end
MP5.SupportsClient = ShouldEnable
local API = ns.API
local TEXTURE_BAR = "Interface\\TargetingFrame\\UI-StatusBar"

-- State
local mp5StartTime = 0
local gainingMana = true
local previousPower = 0
local manaTickTime = 0
local powerRegenTime = 2
local mp5Delay = 5
local frame = nil
local fsrOverlay = nil
local tickOverlay = nil
local showSpark = true
local mp5Driver = nil
local pendingManaSpend, lastSuccessfulCast

local function CanRead(value)
    if API and API.IsSecretValue and API.IsSecretValue(value) then return false end
    return not (API and API.CanAccessValue) or API.CanAccessValue(value)
end

-- Get the bar that displays mana (Power for primary mana, AdditionalPower for Druid cat)
local function GetManaBar()
    if not frame or not frame.Power then return nil end
    -- Druid in cat form: AdditionalPower shows mana
    if frame.isAdditionalPowerShown and frame.AdditionalPower and frame.AdditionalPower:IsShown() then
        return frame.AdditionalPower
    end
    -- Mana classes: Power shows mana. Skip if Power shows energy (Druid cat without AdditionalPower)
    local powerType = UnitPowerType("player")
    if CanRead(powerType) and powerType == 0 then -- MANA
        return frame.Power
    end
    return nil
end

-- Expand overlay beyond mana bar (padding in px) - makes effect more prominent
local OVERLAY_PADDING = 6

-- Reposition overlays over mana bar, extending beyond its bounds for more visible effect
local function RefreshOverlays()
    local manaBar = GetManaBar()
    if not manaBar then
        if fsrOverlay then fsrOverlay:Hide() end
        if tickOverlay then tickOverlay:Hide() end
        return
    end

    local pad = OVERLAY_PADDING
    for _, overlay in ipairs({ fsrOverlay, tickOverlay }) do
        if overlay then
            -- UIParent: ClearAllPoints is blocked on children of SecureUnitButton during combat lockdown
            overlay:ClearAllPoints()
            overlay:SetPoint("TOPLEFT", manaBar, "TOPLEFT", -pad, pad)
            overlay:SetPoint("BOTTOMRIGHT", manaBar, "BOTTOMRIGHT", pad, -pad)
            overlay:SetFrameStrata(manaBar:GetFrameStrata())
            overlay:SetFrameLevel(manaBar:GetFrameLevel() + 5)
        end
    end
end

-- Create overlay StatusBar (transparent, for visual countdown only)
local function CreateOverlayBar(name, minVal, maxVal)
    local bar = CreateFrame("StatusBar", nil, UIParent)
    bar:SetMinMaxValues(minVal, maxVal)
    bar:SetValue(0)
    bar:SetStatusBarTexture(TEXTURE_BAR)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
    bar:SetStatusBarColor(0, 0, 0, 0)
    bar:EnableMouse(false)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(TEXTURE_BAR)
    bg:SetVertexColor(0, 0, 0)
    bg:SetAlpha(0)
    bar.bg = bg

    if showSpark then
        local spark = bar:CreateTexture(nil, "OVERLAY")
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetWidth(28)
        spark:SetVertexColor(1, 1, 1)
        spark:SetBlendMode("ADD")
        bar.spark = spark
    end

    bar:Hide()
    return bar
end

local function GetPower()
    return API and API.SafeUnitPower and API.SafeUnitPower("player", 0) or UnitPower("player", 0)
end

local function GetPowerMax()
    return API and API.SafeUnitPowerMax and API.SafeUnitPowerMax("player", 0) or UnitPowerMax("player", 0)
end

local function SafeNum(v, def)
    def = def or 0
    if v == nil then return def end
    if API and API.SafeGetNumber then
        return API.SafeGetNumber(v, def)
    end
    local n = tonumber(v)
    return n or def
end

-- OnUpdate: FSR countdown + tick countdown. Driver is demand-armed only while
-- an overlay is active; events re-arm when mana spend / regen cycles start.
local OnUpdate -- forward decl for MP5_ArmDriver

local function MP5_DisarmDriver()
    if not mp5Driver then return end
    mp5Driver:SetScript("OnUpdate", nil)
    mp5Driver:Hide()
    _G.FluxPerfMP5Armed = false
end

local function MP5_ArmDriver()
    if not mp5Driver or not OnUpdate then return end
    if mp5Driver:GetScript("OnUpdate") then
        mp5Driver:Show()
        _G.FluxPerfMP5Armed = true
        return
    end
    mp5Driver:SetScript("OnUpdate", OnUpdate)
    mp5Driver:Show()
    _G.FluxPerfMP5Armed = true
end

OnUpdate = function(self, elapsed)
    local dead = UnitIsDead("player")
    if not frame or not frame:IsShown() or not CanRead(dead) or dead then
        if fsrOverlay then fsrOverlay:Hide() end
        if tickOverlay then tickOverlay:Hide() end
        MP5_DisarmDriver()
        return
    end

    local manaBar = GetManaBar()
    if not manaBar or not manaBar:IsShown() then
        if fsrOverlay then fsrOverlay:Hide() end
        if tickOverlay then tickOverlay:Hide() end
        MP5_DisarmDriver()
        return
    end

    local now = GetTime()
    local power = GetPower()
    local powerMax = GetPowerMax()
    local powerNum = SafeNum(power, -1)
    local powerMaxNum = SafeNum(powerMax, -1)
    local active = false
    if powerNum < 0 or powerMaxNum <= 0 then
        if fsrOverlay then fsrOverlay:Hide() end
        if tickOverlay then tickOverlay:Hide() end
        MP5_DisarmDriver()
        return
    end

    -- FSR (5-second rule) overlay
    if mp5StartTime > 0 then
        local remaining = mp5StartTime - now
        if remaining > 0 then
            active = true
            fsrOverlay:ClearAllPoints()
            fsrOverlay:SetPoint("TOPLEFT", manaBar, "TOPLEFT", -OVERLAY_PADDING, OVERLAY_PADDING)
            fsrOverlay:SetPoint("BOTTOMRIGHT", manaBar, "BOTTOMRIGHT", OVERLAY_PADDING, -OVERLAY_PADDING)
            fsrOverlay:SetFrameLevel(manaBar:GetFrameLevel() + 5)
            fsrOverlay:Show()
            fsrOverlay:SetValue(remaining)
            if fsrOverlay.spark then
                local barWidth = fsrOverlay:GetWidth()
                local barHeight = fsrOverlay:GetHeight()
                local posLeft = (remaining / mp5Delay) * (barWidth or 100)
                fsrOverlay.spark:SetHeight(barHeight or 12)
                fsrOverlay.spark:ClearAllPoints()
                fsrOverlay.spark:SetPoint("CENTER", fsrOverlay, "LEFT", posLeft, 0)
            end
        else
            gainingMana = true
            mp5StartTime = 0
            fsrOverlay:Hide()
        end
    else
        fsrOverlay:Hide()
    end

    -- Tick overlay (2-second mana tick countdown)
    if gainingMana then
        if manaTickTime > 0 and powerNum < powerMaxNum then
            active = true
            tickOverlay:ClearAllPoints()
            tickOverlay:SetPoint("TOPLEFT", manaBar, "TOPLEFT", -OVERLAY_PADDING, OVERLAY_PADDING)
            tickOverlay:SetPoint("BOTTOMRIGHT", manaBar, "BOTTOMRIGHT", OVERLAY_PADDING, -OVERLAY_PADDING)
            tickOverlay:SetFrameLevel(manaBar:GetFrameLevel() + 6) -- Above FSR
            tickOverlay:Show()

            local val = manaTickTime - now
            if val <= 0 then
                manaTickTime = now + powerRegenTime
                val = powerRegenTime
            end
            tickOverlay:SetValue(powerRegenTime - val)
            if tickOverlay.spark then
                local barWidth = tickOverlay:GetWidth()
                local barHeight = tickOverlay:GetHeight()
                local posLeft = (1 - val / powerRegenTime) * (barWidth or 100)
                tickOverlay.spark:SetHeight(barHeight or 12)
                tickOverlay.spark:ClearAllPoints()
                tickOverlay.spark:SetPoint("CENTER", tickOverlay, "LEFT", math.min(posLeft, barWidth or 100) - 2, 0)
            end
        else
            tickOverlay:Hide()
        end
    else
        tickOverlay:Hide()
    end

    if not active then
        MP5_DisarmDriver()
    end
end

local function Resume()
    if not frame then return end
    RefreshOverlays()
    local power, maximum = SafeNum(GetPower(), -1), SafeNum(GetPowerMax(), -1)
    if power >= 0 and maximum > 0 and (power < maximum or mp5StartTime > GetTime()) then
        if manaTickTime <= 0 then manaTickTime = GetTime() + powerRegenTime end
        MP5_ArmDriver()
        OnUpdate()
    else
        if fsrOverlay then fsrOverlay:Hide() end
        if tickOverlay then tickOverlay:Hide() end
        MP5_DisarmDriver()
    end
end

local function StartFSR(now)
    gainingMana = false
    mp5StartTime = now + mp5Delay
    pendingManaSpend, lastSuccessfulCast = nil, nil
    if tickOverlay then tickOverlay:Hide() end
end

-- Retain mana drops until cast success regardless of which event arrives first.
local function OnEvent(self, event, unit, powerToken)
    local worldEvent = event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST"
    if not worldEvent and unit ~= "player" then return end
    if (event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT") and powerToken and powerToken ~= "MANA" then return end
    local now = GetTime()
    local power = GetPower()
    local previous, current = SafeNum(previousPower, -1), SafeNum(power, -1)
    if not worldEvent and previous >= 0 and current >= 0 then
        if current < previous then
            if lastSuccessfulCast and now - lastSuccessfulCast <= 0.5 then StartFSR(now)
            else pendingManaSpend = now end
        elseif current > previous then
            manaTickTime = now + powerRegenTime
        end
    end
    previousPower = power
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if pendingManaSpend and now - pendingManaSpend <= 0.5 then StartFSR(now)
        else lastSuccessfulCast = now end
    end
    Resume()
end

function MP5.Shutdown()
    if mp5Driver then
        mp5Driver:UnregisterAllEvents()
        mp5Driver:SetScript("OnUpdate", nil)
        mp5Driver:SetScript("OnEvent", nil)
        mp5Driver:Hide()
    end
    if fsrOverlay then
        fsrOverlay:Hide()
    end
    if tickOverlay then
        tickOverlay:Hide()
    end
    mp5StartTime, manaTickTime, previousPower = 0, 0, 0
    gainingMana = true
    pendingManaSpend, lastSuccessfulCast = nil, nil
    _G.FluxPerfMP5Armed = false
    frame = nil
end

function MP5.Initialize(playerFrame)
    if not playerFrame or playerFrame.unit ~= "player" then return end
    if not ShouldEnable() then MP5.Shutdown(); return end
    if FluxUnitFrames_IsFeatureEnabled and not FluxUnitFrames_IsFeatureEnabled("mp5Overlay") then
        MP5.Shutdown()
        return
    end
    -- The legacy has-mana cache compares raw values, which may be secret on
    -- Forever. Let inaccessible data pause the driver without blocking setup.
    if SafeNum(GetPowerMax(), -1) == 0 then
        MP5.Shutdown()
        return
    end

    if frame == playerFrame and mp5Driver then Resume(); return end
    MP5.Shutdown()

    frame = playerFrame

    if not fsrOverlay then
        fsrOverlay = CreateOverlayBar("FSR", 0, mp5Delay)
    end
    if not tickOverlay then
        tickOverlay = CreateOverlayBar("Tick", 0, powerRegenTime)
    end

    local updater = mp5Driver or CreateFrame("Frame", nil, UIParent)
    mp5Driver = updater
    updater:Hide()
    -- Demand-arm only; idle with full mana must not keep a permanent OnUpdate.
    updater:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    updater:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    updater:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    updater:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    updater:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    updater:RegisterEvent("PLAYER_ENTERING_WORLD")
    updater:RegisterEvent("PLAYER_ALIVE")
    updater:RegisterEvent("PLAYER_UNGHOST")
    updater:SetScript("OnEvent", OnEvent)
    _G.FluxPerfMP5Armed = false

    -- Initial power for comparison
    previousPower = GetPower()

    -- Preserve hooks owned by cast bars and other layout consumers.
    if not frame._fluxMP5Hooks then
        frame._fluxMP5Hooks = true
        if frame.UpdatePartition then
            hooksecurefunc(frame, "UpdatePartition", function(self)
                if frame == self then Resume() end
            end)
        end
        frame:HookScript("OnHide", function(self)
            if frame ~= self then return end
            fsrOverlay:Hide(); tickOverlay:Hide(); MP5_DisarmDriver()
        end)
        frame:HookScript("OnShow", function(self) if frame == self then Resume() end end)
    end

    Resume()
    -- Defer first refresh so partition/layout is done
    C_Timer.After(0.1, function() if frame == playerFrame then Resume() end end)
end
