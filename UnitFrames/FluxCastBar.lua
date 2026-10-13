-- UnitFrames/FluxCastBar.lua
local addonName, ns = ...
ns.CastBar = {}
local CB = ns.CastBar
local UF = ns.UnitFrames
local API = ns.API
local Border = ns.Border

-- Helper function to get unit's class color (copied from shared file)
local function GetUnitClassColor(unit)
    if not unit then return { r = 0.6, g = 0.6, b = 0.6 } end

    if UnitIsPlayer(unit) then
        local _, classFilename = UnitClass(unit)
        classFilename = API.SafeAccessibleString(classFilename)
        if not classFilename then
            return { r = 0.6, g = 0.6, b = 0.6 }
        end
        local ok, color = pcall(function()
            return RAID_CLASS_COLORS[classFilename]
        end)
        return (ok and color) or { r = 0.6, g = 0.6, b = 0.6 }
    else
        -- For NPCs, no color tint (user requested no tint for non-players)
        return { r = 0.6, g = 0.6, b = 0.6 } -- Neutral gray
    end
end

-- Border + backdrop tint for Flux chrome: player/pet follow General → Appearance; target keeps target class color.
local function GetCastBarChromeColors(unit)
    if unit == "target" or unit == "focus" then
        local c = GetUnitClassColor(unit)
        return c.r, c.g, c.b, c.r * 0.4, c.g * 0.4, c.b * 0.4
    end
    if unit == "player" or unit == "pet" then
        if FluxBorder and FluxBorder.GetThemedVertexRGB and FluxBorder.GetThemedBackdropFillRGB then
            local br, bg, bb = FluxBorder:GetThemedVertexRGB()
            local dr, dg, db = FluxBorder:GetThemedBackdropFillRGB()
            return br, bg, bb, dr, dg, db
        end
        local c = GetUnitClassColor("player")
        return c.r, c.g, c.b, c.r * 0.4, c.g * 0.4, c.b * 0.4
    end
    local c = GetUnitClassColor("player")
    return c.r, c.g, c.b, c.r * 0.4, c.g * 0.4, c.b * 0.4
end

-- ---------------------------------------------------------------------------
-- Constants & Configuration
-- ---------------------------------------------------------------------------
-- Empowered cast bar constants (matching Blizzard's implementation)
local CASTBAR_STAGE_INVALID = -1
local CASTBAR_STAGE_DURATION_INVALID = -1

-- Post-cast hold + fade. Interrupt timings match Blizzard UNITFRAME
-- HoldFadeOutAnim (1.0 hold at full alpha, then 0.3 fade) in CastingBarFrameTemplates.xml.
local FLUX_CASTBAR_HOLD_FINISH    = 0.35
local FLUX_CASTBAR_HOLD_INTERRUPT = 1.00
local FLUX_CASTBAR_FADE_DURATION  = 0.75
local FLUX_CASTBAR_FADE_INTERRUPT = 0.30
-- 20Hz matches the tenth-of-a-second precision while cutting SetFormattedText
-- calls by ~2/3. Bar/spark skip SetValue/SetPoint when delta < 1px.
local FLUX_CASTBAR_TIME_TEXT_INTERVAL = 0.05

-- Spell name inset; extra pad while the uninterruptible shield hangs onto the bar.
local CASTBAR_TEXT_LEFT_PAD = 4
local CASTBAR_TEXT_RIGHT_PAD = 4
local CASTBAR_TEXT_TIME_GAP = 6
local CASTBAR_TEXT_SHIELD_PAD = 10
-- UI-CastingBar-Small-Shield art sits a few px right/up of geometric center.
local SHIELD_OFFSET_X = -3
local SHIELD_OFFSET_Y = -2

local function CastBarSpellTextLeftPad(castBar)
    local pad = CASTBAR_TEXT_LEFT_PAD
    if not castBar then
        return pad
    end
    local shield = castBar.ShieldOverlay
    local iconFrame = castBar.IconFrame
    -- Pet hides the icon (and thus the shield); keep the normal inset.
    if shield and shield.IsShown and shield:IsShown()
        and iconFrame and iconFrame.IsShown and iconFrame:IsShown() then
        pad = pad + CASTBAR_TEXT_SHIELD_PAD
    end
    return pad
end

-- Custom timer presets (flight path, etc.)
local FLUX_CUSTOM_TIMER_COLORS = {
    flight = { 0.32, 0.72, 1.0 },
    default = { 1, 0.95, 0 },
}

-- Helper functions for secret value handling (12.0+ compatibility)
local function IsSecretValue(value)
    return API and API.IsSecretValue and API.IsSecretValue(value)
end

-- Midnight can wrap UnitCastingInfo name/text/times. `if not name` throws or
-- fails closed, so treat any secret-or-nonempty payload as an active cast.
local function CastFieldLooksPresent(value)
    if value == nil then
        return false
    end
    if IsSecretValue(value) then
        return true
    end
    local t = type(value)
    if t == "string" then
        return value ~= ""
    end
    if t == "number" then
        return value ~= 0
    end
    return true
end

local function CastLooksActive(name, text, spellID, startTime, endTime)
    return CastFieldLooksPresent(name)
        or CastFieldLooksPresent(text)
        or CastFieldLooksPresent(spellID)
        or CastFieldLooksPresent(startTime)
        or CastFieldLooksPresent(endTime)
end

local function ProbeUnitCastFields(unit, wantChannel)
    local name, text, texture, startTime, endTime, spellID
    pcall(function()
        if wantChannel then
            if UnitChannelInfo then
                name, text, texture, startTime, endTime, _, _, spellID = UnitChannelInfo(unit)
            end
        elseif UnitCastingInfo then
            name, text, texture, startTime, endTime, _, _, _, spellID = UnitCastingInfo(unit)
        end
    end)
    return name, text, texture, startTime, endTime, spellID
end

local function GenericCastLabel(isChannel)
    if isChannel then
        return CHANNELING or "Channeling"
    end
    return CASTING or "Casting"
end

-- Blizzard CastingBarMixin:HandleCastStart feeds displayName into FontString:SetText
-- even when the string is secret (SecretAspect.Text). Do not unwrap or stringify it.
-- Forever uses text (displayName); fall back to name if text is missing or empty.
local function PaintCastBarSpellText(fs, name, text, isChannel)
    if not fs or not fs.SetText then
        return false
    end
    local function trySet(label)
        if label == nil then
            return false
        end
        local ok = pcall(fs.SetText, fs, label)
        if not ok then
            return false
        end
        local shown = API and API.SafeAccessibleString and API.SafeAccessibleString(label)
        -- Secret SetText succeeded (shown nil) or nonempty accessible string.
        return shown == nil or shown ~= ""
    end
    if trySet(text) then
        return true
    end
    if trySet(name) then
        return true
    end
    pcall(fs.SetText, fs, GenericCastLabel(isChannel))
    return false
end

local function EventUnitMatchesRegistered(eventUnit, registeredUnit)
    if eventUnit == nil then
        return true
    end
    if IsSecretValue(eventUnit) then
        return true
    end
    local ok, matches = pcall(function()
        return eventUnit == registeredUnit
    end)
    if not ok then
        return true
    end
    return matches and true or false
end

local function SafeGetNumber(value)
    if IsSecretValue(value) then
        return 0 -- Default fallback for secret values
    end
    return tonumber(value) or 0
end

-- Prefer nil over a fake 1s when DurationObject timings are secret/inaccessible.
local function TryGetDurationSeconds(dur)
    if dur == nil then
        return nil
    end
    if type(dur) == "number" then
        if IsSecretValue(dur) then
            return nil
        end
        local secs = tonumber(dur)
        return (secs and secs > 0) and secs or nil
    end
    if type(dur) == "userdata" then
        local ok, val = pcall(function()
            if dur.GetTotalDuration then
                return dur:GetTotalDuration()
            end
            if dur.GetDuration then
                return dur:GetDuration()
            end
        end)
        if ok and val and not IsSecretValue(val) then
            local secs = tonumber(val)
            if secs and secs > 0 then
                return secs
            end
        end
    end
    return nil
end

local function SpellCastTimeFromID(spellID)
    if not spellID or IsSecretValue(spellID) then
        return nil
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and type(info) == "table" and info.castTime and not IsSecretValue(info.castTime) then
            local ms = tonumber(info.castTime)
            if ms and ms > 0 then
                return ms / 1000
            end
        end
    end
    return nil
end

local function GetUnitCastDurationObject(unit, isChannel, isEmpowered)
    if isEmpowered and UnitEmpoweredChannelDuration then
        return UnitEmpoweredChannelDuration(unit, true)
    end
    if isChannel and UnitChannelDuration then
        return UnitChannelDuration(unit)
    end
    if UnitCastingDuration then
        return UnitCastingDuration(unit)
    end
    return nil
end

--- Apply engine-driven StatusBar timer (12.0+). Do NOT call SetMinMaxValues afterward —
--- that clears the DurationObject and forces the 1s manual fallback.
local function ApplyCastBarTimerDuration(self, unit, isChannel, isEmpowered)
    if not self.SetTimerDuration then
        return nil
    end
    local durationObj = GetUnitCastDurationObject(unit, isChannel, isEmpowered)
    if not durationObj then
        return nil
    end
    local direction
    if isChannel and not isEmpowered then
        direction = Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime
    else
        direction = Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.ElapsedTime
    end
    local interpolation = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or 0
    local ok = pcall(self.SetTimerDuration, self, durationObj, interpolation, direction)
    if not ok then
        return nil
    end
    return durationObj
end

-- Forever CastingBarMixin:HandleCastStart: value/maxValue from UnitCastingInfo
-- startTime/endTime (ms), then OnUpdate adds elapsed. Same data as the client bar.
local function ApplyClientCastTiming(self, startTime, endTime, isChannel)
    if startTime == nil or endTime == nil then
        return false
    end
    local ok, value, maxValue = pcall(function()
        local maxV = (endTime - startTime) / 1000
        local val
        if isChannel then
            val = (endTime / 1000) - GetTime()
        else
            val = GetTime() - (startTime / 1000)
        end
        return val, maxV
    end)
    if not ok or value == nil or maxValue == nil then
        return false
    end
    if IsSecretValue(value) or IsSecretValue(maxValue) then
        return false
    end
    maxValue = tonumber(maxValue)
    value = tonumber(value)
    if not maxValue or maxValue <= 0 then
        return false
    end
    if value < 0 then
        value = 0
    end
    if value > maxValue then
        value = maxValue
    end
    self.value = value
    self.maxValue = maxValue
    self._fluxClientCastTiming = true
    self._fluxUsedTimerDuration = false
    self:SetMinMaxValues(0, maxValue)
    self:SetValue(value)
    return true
end

-- Remaining-seconds countdown like Forever CastingBarMixin:UpdateCastTimeText.
-- Prefer cached value/maxValue; fall back to GetValue, then wall-clock from CastStart.
local function AccessibleRemainingSeconds(self)
    if not self then
        return nil
    end
    local value, maxValue
    if self.value ~= nil and not IsSecretValue(self.value) then
        value = tonumber(self.value)
    end
    if self.maxValue ~= nil and not IsSecretValue(self.maxValue) then
        maxValue = tonumber(self.maxValue)
    end
    if value == nil or maxValue == nil then
        local ok, cur, maxV = pcall(function()
            local c = self.GetValue and self:GetValue()
            local _, m = self:GetMinMaxValues()
            return c, m
        end)
        if ok then
            if value == nil and cur ~= nil and not IsSecretValue(cur) then
                value = tonumber(cur)
            end
            if maxValue == nil and maxV ~= nil and not IsSecretValue(maxV) then
                maxValue = tonumber(maxV)
            end
        end
    end
    if (maxValue == nil or maxValue <= 0) and self._fluxCastWallMax ~= nil
        and not IsSecretValue(self._fluxCastWallMax) then
        maxValue = tonumber(self._fluxCastWallMax)
    end
    if value ~= nil and maxValue ~= nil and maxValue > 0 then
        local rem = self.channeling and value or (maxValue - value)
        if rem < 0 then
            rem = 0
        end
        return rem
    end
    local start = self._fluxCastWallStart
    if start and maxValue and maxValue > 0 then
        local rem = maxValue - (GetTime() - start)
        if rem < 0 then
            rem = 0
        end
        return rem
    end
    return nil
end

local function PaintCastBarRemainingTime(self)
    if not self or not self.Time then
        return
    end
    local castUnit = self.unitID or self.unit
    if FluxUnitFrames_ShouldShowCastTime and not FluxUnitFrames_ShouldShowCastTime(castUnit) then
        self.Time:SetText("")
        self.Time:Hide()
        return
    end
    if not self.casting and not self.channeling and not self.customTimer then
        return
    end
    local rem = AccessibleRemainingSeconds(self)
    if rem == nil then
        self.Time:Show()
        return
    end
    if rem < 0.05 then
        rem = 0
    end
    self.Time:SetFormattedText("%.1f", rem)
    self.Time:Show()
    if self.Text and self.Text:IsShown() then
        local barW = (self.TimerBar and self.TimerBar:GetWidth()) or self:GetWidth() or 0
        local timeW = self.Time:GetStringWidth() or 0
        if timeW < 28 then
            timeW = 28
        end
        local maxText = barW - timeW - CastBarSpellTextLeftPad(self) - CASTBAR_TEXT_RIGHT_PAD - CASTBAR_TEXT_TIME_GAP
        if maxText < 24 then
            maxText = 24
        end
        self.Text:SetWidth(maxText)
        self.Text:SetWordWrap(false)
        if self.Text.SetMaxLines then
            self.Text:SetMaxLines(1)
        end
    end
end

local function SafeCompareGUID(guid1, guid2)
    -- If either GUID is secret, we can't verify identity directly.
    -- However, since we use RegisterUnitEvent, we trust the event routing.
    -- Blocking here causes missing "Stop" events for secret targets.
    if IsSecretValue(guid1) or IsSecretValue(guid2) then
        return true -- Assume match for secret values to allow event processing
    end
    return guid1 == guid2
end

local function SafeCompareSpellID(id1, id2)
    -- RegisterUnitEvent already scoped the event. Secret ids cannot be compared;
    -- assume match so CHANNEL_STOP still finishes the bar.
    if IsSecretValue(id1) or IsSecretValue(id2) then
        return true
    end
    return id1 == id2
end

local function SafeBooleanTest(value)
    -- Can't perform boolean tests on secret values
    if IsSecretValue(value) then
        return false -- Default to false for secret values
    end
    return not not value -- Convert to boolean safely
end

local TEXTURE_BAR = "Interface\\TargetingFrame\\UI-StatusBar"
local TEXTURE_BG = "Interface\\Buttons\\WHITE8X8"

-- Legacy compatibility helper for atlas textures (copied from backup)
local isLegacyClient = IsWoWLegacyClient and IsWoWLegacyClient() or false

-- Check for Dragonflight+ atlas support
local hasAtlasSupport = false
if C_Texture and C_Texture.GetAtlasInfo then
    -- Try to check if atlas system works
    local testAtlas = C_Texture.GetAtlasInfo("ui-castingbar-filling-standard")
    hasAtlasSupport = testAtlas ~= nil
end

local function SetAtlasLegacy(texture, atlasName)
    if isLegacyClient or not hasAtlasSupport then
        -- Comprehensive fallback textures for pre-DF clients
        local legacyTextures = {
            -- Standard casting bar textures
            ["ui-castingbar-filling-standard"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-pip"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
            ["ui-castingbar-pip-red"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
            ["ui-castingbar-empower-pip"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
            ["ui-castingbar-empower-cursor"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
            ["ui-castingbar-spark"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
            ["ui-castingbar-full-glow-standard"] = "Interface\\CastingBar\\UI-CastingBar-Full-Glow",
            ["ui-castingbar-flash-standard"] = "Interface\\CastingBar\\UI-CastingBar-Flash",
            ["ui-castingbar-full-standard"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-interrupted"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-background"] = "Interface\\TargetingFrame\\UI-StatusBar",

            -- Channel textures (purple/lavender appearance for retail-like look)
            ["ui-castingbar-filling-channel"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-full-channel"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-full-glow-channel"] = "Interface\\CastingBar\\UI-CastingBar-Full-Glow",

            -- Uninterruptable textures
            ["ui-castingbar-uninterruptable"] = "Interface\\TargetingFrame\\UI-StatusBar",

            -- Empowered textures (fallback to standard)
            ["ui-castingbar-filling-empower"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-full-empower"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-full-glow-empower"] = "Interface\\CastingBar\\UI-CastingBar-Full-Glow",

            -- Empowered tier textures
            ["ui-castingbar-tier1-empower"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-tier2-empower"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-tier3-empower"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-tier4-empower"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-disabled-tier1-empower"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-disabled-tier2-empower"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-disabled-tier3-empower"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-disabled-tier4-empower"] = "Interface\\TargetingFrame\\UI-StatusBar",
            ["ui-castingbar-glow-tier1-empower"] = "Interface\\CastingBar\\UI-CastingBar-Full-Glow",
            ["ui-castingbar-glow-tier2-empower"] = "Interface\\CastingBar\\UI-CastingBar-Full-Glow",
            ["ui-castingbar-glow-tier3-empower"] = "Interface\\CastingBar\\UI-CastingBar-Full-Glow",
            ["ui-castingbar-glow-tier4-empower"] = "Interface\\CastingBar\\UI-CastingBar-Full-Glow",
        }
        local path = legacyTextures[atlasName] or "Interface\\TargetingFrame\\UI-StatusBar"
        texture:SetTexture(path)

        -- Special handling for spark texture
        if atlasName == "ui-castingbar-pip" then
            texture:SetTexCoord(0, 1, 0, 1)
        else
            texture:SetTexCoord(0, 1, 0, 1)
        end
        return
    end

    if texture.SetAtlas then
        -- Force clear previous texture reference to ensure clean swap
        texture:SetTexture(nil) 

        -- Fix for missing Empowered Atlas in some clients: Check existence first!
        local atlasInfo = C_Texture.GetAtlasInfo(atlasName)
        if atlasInfo then
             -- Keep the caller's size. useAtlasSize draws the atlas's native
             -- rect, which sticks the empower trough and tier art past the bar.
             texture:SetAtlas(atlasName, false)
        else
             -- Fallback to standard texture if atlas is missing (e.g. Empowered filling on some clients)
             texture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
             texture:SetTexCoord(0, 1, 0, 1)
        end
    end
end

-- Retail 10.0+: Blizzard's OverlayPlayerCastingBarFrame (talent commit, etc.) must run
-- UNIT_SPELLCAST handlers before addon code in the same dispatch, or CastingBarTypeInfo
-- is inaccessible (taint). Defer our player/vehicle bar work to the next frame.
local function FluxCastBar_IsRetailPostDF()
    if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
        return false
    end
    local major = (API and API.majorVersion) or (FLUX_API and FLUX_API.majorVersion)
    if type(major) == "number" and major >= 10 then
        return true
    end
    -- PLAYER_LOGIN can run before ns.API is filled; TOC 10+ implies DF+ mainline.
    if GetBuildInfo then
        local _, _, _, toc = GetBuildInfo()
        toc = tonumber(toc) or 0
        if toc >= 100000 then
            return true
        end
    end
    return false
end

-- 12.x+: sentTarget / spell target names may be secret; never compare or concatenate raw.
local function UnitNameForMatch(unit)
    local PN = ns.Flux and ns.Flux.PlayerName
    if PN and PN.GetFullName then
        local full = PN.GetFullName(unit)
        if full then
            return full
        end
    end
    return UnitName(unit)
end

local function NameMatches(unit, targetName)
    if not unit or not targetName then
        return false
    end
    local PN = ns.Flux and ns.Flux.PlayerName
    local unitName = UnitNameForMatch(unit)
    if PN and PN.NamesEqual then
        return PN.NamesEqual(unitName, targetName)
    end
    local SafeEq = API.SafeEqualForCache
    return SafeEq and SafeEq(unitName, targetName)
end

local function FindUnitForCastTargetName(targetName, casterUnit)
    if not targetName or not API.CanAccessValue(targetName) then
        return nil
    end
    if casterUnit and NameMatches(casterUnit .. "target", targetName) then
        return casterUnit .. "target"
    end
    if NameMatches("player", targetName) then return "player" end
    if NameMatches("target", targetName) then return "target" end
    if NameMatches("focus", targetName) then return "focus" end
    if NameMatches("mouseover", targetName) and UnitExists("mouseover") then
        return "mouseover"
    end
    if IsInRaid() then
        for i = 1, 40 do
            if NameMatches("raid" .. i, targetName) then
                return "raid" .. i
            end
        end
    elseif IsInGroup() then
        for i = 1, 4 do
            if NameMatches("party" .. i, targetName) then
                return "party" .. i
            end
        end
    end
    return nil
end

local function FluxCastBar_ShouldDeferUnitCastEvents(unit)
    if unit ~= "player" and unit ~= "vehicle" then
        return false
    end
    return FluxCastBar_IsRetailPostDF()
end

local function FluxCastBar_DeferEvent(callback)
    if RunNextFrame then
        RunNextFrame(callback)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(0, callback)
    else
        callback()
    end
end

-- ---------------------------------------------------------------------------
-- Retail: Blizzard copies CastingBarMixin methods onto each bar frame at
-- creation, so replacing CastingBarMixin does not fix OverlayPlayerCastingBarFrame.
-- With _FluxUI taint, Overlay's OnEvent cannot read CastingBarTypeInfo (secret keys).
-- Talent/spec UIs only need the overlay for "ApplyingTalents" cosmetics
-- (TalentFrameBaseMixin:SetCommitCastBarActive, ClassTalentsFrameMixin override,
-- ClassSpecFrameMixin:SetActivateVisualsActive — see wow-ui-source-live). Skip
-- StartReplacingPlayerBarAt for that bar type only; other uses (professions,
-- override action bar, etc.) stay unchanged.
-- ---------------------------------------------------------------------------
-- Do not read or compare overrideInfo.overrideBarType: it is a secret-wrapped
-- value and comparing it under _FluxUI taint errors. In wow-ui-source-live,
-- only talent/spec paths pass overrideBarType; professions use hideBarText only.
local function FluxCastBar_OverrideInfoHasApplyingTalentsBarTypeKey(overrideInfo)
    if type(overrideInfo) ~= "table" then
        return false
    end
    -- Midnight: do not pairs() override tables that may carry secret keys.
    if canaccesstable and not canaccesstable(overrideInfo) then
        -- Talent/spec paths always include overrideBarType; when inaccessible under
        -- Flux taint, skip Overlay replacement rather than iterating.
        return true
    end
    local ok, hasKey = pcall(function()
        return rawget(overrideInfo, "overrideBarType") ~= nil
    end)
    if ok then
        return hasKey
    end
    ok, hasKey = pcall(function()
        for k in pairs(overrideInfo) do
            if k == "overrideBarType" then
                return true
            end
        end
        return false
    end)
    return ok and hasKey
end

local function FluxCastBar_BlockOverlayApplyingTalentsCastBar()
    if _G.FluxCastBar_OverlayApplyingTalentsHooked then
        return
    end
    if not FluxCastBar_IsRetailPostDF() then
        return
    end
    -- Post-DF: do not replace OverlayPlayerCastingBarFrame methods — shares CastingBarMixin
    -- paths with Settings nameplate preview SimulateCast (CastingBarTypeInfo taint).
    return
end

-- Cast bar type definitions (from old system)
local CASTING_BAR_TYPES = {
    standard = {
        filling = "ui-castingbar-filling-standard",
        full = "ui-castingbar-full-standard",
        glow = "ui-castingbar-full-glow-standard",
        sparkFx = "StandardGlow",
        finishAnim = "StandardFinish",
    },
    channel = {
        filling = "ui-castingbar-filling-channel",
        full = "ui-castingbar-full-channel",
        glow = "ui-castingbar-full-glow-channel",
        sparkFx = "ChannelShadow",
        finishAnim = "ChannelFinish",
    },
    interrupted = {
        filling = "ui-castingbar-interrupted",
        full = "ui-castingbar-interrupted",
        glow = "ui-castingbar-full-glow-standard",
    },
    uninterruptable = {
        filling = "ui-castingbar-uninterruptable",
        full = "ui-castingbar-uninterruptable",
        glow = "ui-castingbar-full-glow-standard",
    },
    empowered = { 
        filling = "ui-castingbar-filling-empower",
        full = "ui-castingbar-full-empower",
        glow = "ui-castingbar-full-glow-empower",
        sparkFx = "EmpowerGlow",
        tier1 = "ui-castingbar-tier1-empower",
        tier2 = "ui-castingbar-tier2-empower",
        tier3 = "ui-castingbar-tier3-empower",
        tier4 = "ui-castingbar-tier4-empower",
        disabled_tier1 = "ui-castingbar-disabled-tier1-empower",
        disabled_tier2 = "ui-castingbar-disabled-tier2-empower",
        disabled_tier3 = "ui-castingbar-disabled-tier3-empower",
        disabled_tier4 = "ui-castingbar-disabled-tier4-empower",
    },
}

-- ---------------------------------------------------------------------------
-- Cast Bar Logic
-- ---------------------------------------------------------------------------

-- Helper function to check if texture is the placeholder icon
-- Skip checks when texture is secret (WoW 12+ target cast bar) - can't compare
local function IsPlaceholderIcon(texture)
    if texture == nil or IsSecretValue(texture) then
        return false
    end
    if canaccessvalue and not canaccessvalue(texture) then
        return false  -- Secret value: use texture as-is, don't try profession icon replacement
    end

    -- Check if it's the placeholder ID (136235)
    if type(texture) == "number" and texture == 136235 then
        return true
    end

    -- Check if it's a file path containing "temp" (placeholder texture)
    if type(texture) == "string" then
        if texture:find("temp") or texture:find("136235") then
            return true
        end
    end

    return false
end

-- Retail/forever: C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank).
-- Passing "spell" throws; the bank is a number. Classic uses GetSpellBookItemInfo(slot, BOOKTYPE_SPELL).
local function GetPlayerSpellBookBank()
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    if type(bank) == "number" then
        return bank
    end
    return 0
end

local function GetSpellBookSlotSpellID(slotIndex)
    if type(slotIndex) ~= "number" then
        return nil
    end
    local SB = C_SpellBook
    local bank = GetPlayerSpellBookBank()
    if SB and SB.GetSpellBookItemInfo then
        local ok, info = pcall(SB.GetSpellBookItemInfo, slotIndex, bank)
        if ok and type(info) == "table" then
            return info.spellID or info.actionID
        end
    end
    if SB and SB.GetSpellBookItemType then
        local ok, _, actionID, bookSpellID = pcall(SB.GetSpellBookItemType, slotIndex, bank)
        if ok then
            return bookSpellID or actionID
        end
    end
    local bookType = BOOKTYPE_SPELL or "spell"
    if GetSpellBookItemInfo then
        local ok, kind, id = pcall(GetSpellBookItemInfo, slotIndex, bookType)
        if ok then
            if type(kind) == "table" then
                return kind.spellID or kind.actionID
            end
            if type(id) == "number" then
                return id
            end
        end
    end
    if GetSpellBookItemName then
        local ok, _, _, id = pcall(GetSpellBookItemName, slotIndex, bookType)
        if ok and type(id) == "number" then
            return id
        end
    end
    return nil
end

local function ForEachProfessionIndex(callback)
    if not GetProfessions or not GetProfessionInfo then
        return
    end
    local prof1, prof2, arch, fish, cook = GetProfessions()
    local professions = { prof1, prof2, arch, fish, cook }
    -- GetProfessions can return nil holes (e.g. only cooking). ipairs would stop.
    for i = 1, 5 do
        local profIndex = professions[i]
        if profIndex then
            callback(profIndex)
        end
    end
end

-- Helper function to get profession icon for a spell
local function GetProfessionIconForSpell(spellName, spellID)
    if IsSecretValue(spellName) or IsSecretValue(spellID) then
        return nil
    end
    if not spellName or not spellID then return nil end
    
    -- Method 1: Check if spell name matches profession names
    local function CheckProfessionByName()
        local match
        ForEachProfessionIndex(function(profIndex)
            if match then
                return
            end
            local name, texture = GetProfessionInfo(profIndex)
            if name and texture then
                if spellName == name then
                    match = texture
                    return
                end
                if type(spellName) == "string" and type(name) == "string" and spellName:find(name, 1, true) then
                    match = texture
                end
            end
        end)
        return match
    end
    
    -- Method 2: Check if spell is in a profession spell book tab
    local function CheckProfessionBySpellBook()
        local match
        ForEachProfessionIndex(function(profIndex)
            if match then
                return
            end
            local _, texture, _, _, numSpells, spellOffset = GetProfessionInfo(profIndex)
            if not texture or not spellOffset or not numSpells then
                return
            end
            for i = 1, numSpells do
                local bookSpellID = GetSpellBookSlotSpellID(spellOffset + i)
                if bookSpellID and bookSpellID == spellID then
                    match = texture
                    return
                end
            end
        end)
        return match
    end
    
    -- Try name matching first (faster)
    local profIcon = CheckProfessionByName()
    if profIcon then
        return profIcon
    end
    
    -- Fall back to spellbook check
    profIcon = CheckProfessionBySpellBook()
    if profIcon then
        return profIcon
    end
    
    return nil
end

local function UseModernCastBarArt()
    return hasAtlasSupport and not isLegacyClient
end

-- Era / Anniversary / progression Classic ship the DF filling atlases (nameplates)
-- but player bars are classicStyleCastBar: UI-StatusBar + vertex color. Atlas
-- full/interrupted caps do not stay on the leading edge (no useAtlasSize BarTexture
-- / InterruptSparkAnim). Forever, Camelot, and retail keep modern atlas finish art.
local function UseClassicCastBarColorFinish()
    local api = FLUX_API
    if api and api.isAnyClassic then
        return true
    end
    local client = ns.Flux and ns.Flux.Client
    if client and client.isAnyClassic then
        return true
    end
    return not UseModernCastBarArt()
end

-- Classic finish/interrupt: keep Flux UI-StatusBar (not Flash / interrupted atlas).
local FLUX_CASTBAR_FINISH_GREEN = { 0.12, 0.86, 0.15 }
local FLUX_CASTBAR_INTERRUPT_RED = { 1.0, 0.0, 0.0 }

local function ApplyCastBarVertexFill(castBar, r, g, b)
    local timerBar = castBar and castBar.TimerBar
    if not timerBar then
        return
    end
    local prev = timerBar.GetStatusBarTexture and timerBar:GetStatusBarTexture()
    if prev and prev.SetTexture then
        pcall(prev.SetTexture, prev, nil)
    end
    timerBar:SetStatusBarTexture(TEXTURE_BAR)
    timerBar._fluxFillAtlas = nil
    local tex = timerBar.GetStatusBarTexture and timerBar:GetStatusBarTexture()
    timerBar.statusBarTexture = tex
    if tex then
        if tex.SetTexCoord then
            tex:SetTexCoord(0, 1, 0, 1)
        end
        if tex.Show then
            tex:Show()
        end
    end
    castBar:SetStatusBarColor(r, g, b)
end

-- forever CastingBarMixin:UpdateBarFillTexture — SetStatusBarTexture(atlas name),
-- SetStatusBarColor(1,1,1). XML BarTexture uses atlas + useAtlasSize; the engine
-- owns width so the filling atlas cap glow stays on the leading edge.
-- SetAtlas + SetSize(full bar) + LEFT-anchor stretches that cap to the right
-- end, or fights SetTimerDuration after layout.
local function ApplyCastBarFillAtlas(castBar, atlasName)
    local timerBar = castBar and castBar.TimerBar
    if not timerBar then
        return
    end
    -- interrupted / filling / full share one atlas sheet. SetStatusBarTexture(new)
    -- can no-op and leave the red interrupt cap on the next cast unless we unbind first.
    local prev = timerBar.GetStatusBarTexture and timerBar:GetStatusBarTexture()
    if prev and prev.SetTexture and timerBar._fluxFillAtlas ~= atlasName then
        pcall(prev.SetTexture, prev, nil)
    end
    if UseModernCastBarArt() and atlasName then
        local ok, success = pcall(timerBar.SetStatusBarTexture, timerBar, atlasName)
        if not ok or success == false then
            timerBar:SetStatusBarTexture(TEXTURE_BAR)
            timerBar._fluxFillAtlas = nil
        else
            timerBar._fluxFillAtlas = atlasName
        end
    else
        timerBar:SetStatusBarTexture(TEXTURE_BAR)
        timerBar._fluxFillAtlas = nil
    end
    local tex = timerBar.GetStatusBarTexture and timerBar:GetStatusBarTexture()
    timerBar.statusBarTexture = tex
    if tex and tex.Show then
        tex:Show()
    end
end

local function ApplyModernFillColor(castBar)
    if UseModernCastBarArt() then
        castBar:SetStatusBarColor(1, 1, 1)
        return true
    end
    return false
end

local function UpdateCastBarColor(self, unit)
    if SafeBooleanTest(self.notInterruptible) then
        if not ApplyModernFillColor(self) then
            self:SetStatusBarColor(1.0, 0.0, 0.0) -- Red for uninterruptible
        end
        if self.IconBorder then
             Border:SetBorderColor(self.IconBorder, 1.0, 0.0, 0.0, 1)
        end
        if self.BorderFrame then
             Border:SetBorderColor(self.BorderFrame, 1.0, 0.0, 0.0, 1)
        end
        -- Show shield overlay for uninterruptible casts
        if self.ShieldOverlay then
            self.ShieldOverlay:Show()
        end
    else
        -- Only set standard yellow if NOT empowered. Empowered has its own dynamic colors.
        -- Modern filling atlases are pre-colored; vertex tint blows out the leading-edge glow.
        if not SafeBooleanTest(self.isEmpowered) then
            if not ApplyModernFillColor(self) then
                self:SetStatusBarColor(1, 0.95, 0) -- Classic yellow/gold (Legacy Color: 1, 0.95, 0)
            end
        end

        if self.IconBorder then
             local parentFrame = self:GetParent()
             local u = parentFrame and parentFrame.unit or "player"
             local br, bg, bb = GetCastBarChromeColors(u)
             Border:SetBorderColor(self.IconBorder, br, bg, bb, 1)
        end
        if self.BorderFrame then
             local parentFrame = self:GetParent()
             local u = parentFrame and parentFrame.unit or "player"
             local br, bg, bb = GetCastBarChromeColors(u)
             Border:SetBorderColor(self.BorderFrame, br, bg, bb, 1)
        end
        -- Hide shield overlay for interruptible casts
        if self.ShieldOverlay then
            self.ShieldOverlay:Hide()
        end
    end
end

-- Match CreateCastBar / UpdateCastBarColor backdrop tint (class * 0.4 @ 0.85 alpha).
local function RestoreCastBarFluxBackdrop(castBar)
    if not Border or not castBar.BorderFrame then
        return
    end
    local parentFrame = castBar:GetParent()
    local u = parentFrame and parentFrame.unit
    if not u then
        return
    end
    local _, _, _, dr, dg, db = GetCastBarChromeColors(u)
    Border:SetBackdropColor(castBar.BorderFrame, dr, dg, db, 0.85)
end

local function SetCastBarEmpoweredBackdrop(castBar, empowered)
    if not Border or not castBar.BorderFrame then
        return
    end
    if empowered then
        Border:HideBackground(castBar.BorderFrame)
    else
        RestoreCastBarFluxBackdrop(castBar)
    end
end

-- Inner trough behind fill: default gray StatusBar * 0.3 reads as a dark overlay through empower tier atlases.
-- Mainline uses ui-castingbar-background (CastingBarFrameBaseTemplate Background).
local function RestoreCastBarTrough(castBar)
    local bg = castBar.bg
    if not bg then
        return
    end
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetTexCoord(0, 1, 0, 1)
    bg:SetVertexColor(0.3, 0.3, 0.3, 1)
end

local function SetCastBarEmpoweredTrough(castBar, empowered)
    local bg = castBar.bg
    if not bg then
        return
    end
    if empowered then
        SetAtlasLegacy(bg, "ui-castingbar-background")
        bg:SetVertexColor(1, 1, 1, 1)
        local timerBar = castBar.TimerBar
        if timerBar then
            bg:ClearAllPoints()
            bg:SetAllPoints(timerBar)
        end
    else
        RestoreCastBarTrough(castBar)
        local timerBar = castBar.TimerBar
        if timerBar then
            bg:ClearAllPoints()
            bg:SetPoint("CENTER", timerBar, "CENTER", 0, 0)
        end
    end
end

-- Blizzard CastingBarMixin:GetInterruptText (live + forever).
local function GetInterruptText(interruptedBy)
    if interruptedBy == nil or IsSecretValue(interruptedBy) or not UnitNameFromGUID then
        return INTERRUPTED or "Interrupted"
    end
    local okName, unitName = pcall(UnitNameFromGUID, interruptedBy)
    if okName and type(unitName) == "string" and #unitName > 0 then
        if UnitClassFromGUID and RAID_CLASS_COLORS then
            local okClass, _, classFilename = pcall(UnitClassFromGUID, interruptedBy)
            if okClass and classFilename and not IsSecretValue(classFilename) then
                local classColor = RAID_CLASS_COLORS[classFilename]
                if classColor and classColor.WrapTextInColorCode then
                    unitName = classColor:WrapTextInColorCode(unitName)
                end
            end
        end
        if SPELL_INTERRUPTED_BY then
            return SPELL_INTERRUPTED_BY:format(unitName)
        end
    end
    return INTERRUPTED or "Interrupted"
end

local function SnapshotCastBarProgress(self)
    local cur, maxV
    if self.GetValue then
        local ok, value = pcall(self.GetValue, self)
        if ok and value and not IsSecretValue(value) then
            cur = tonumber(value)
        end
    end
    if self.GetMinMaxValues then
        local ok, _, maxValue = pcall(self.GetMinMaxValues, self)
        if ok and maxValue and not IsSecretValue(maxValue) then
            maxV = tonumber(maxValue)
        end
    end
    if (not cur or not maxV or maxV <= 0) and self.GetTimerDuration then
        local okDur, durationObject = pcall(self.GetTimerDuration, self)
        if okDur and durationObject then
            if not maxV then
                maxV = TryGetDurationSeconds(durationObject)
            end
            if not cur and maxV and durationObject.GetElapsedPercent then
                local okPct, pct = pcall(durationObject.GetElapsedPercent, durationObject)
                if okPct and pct and not IsSecretValue(pct) then
                    local ratio = tonumber(pct)
                    if ratio then
                        cur = ratio * maxV
                    end
                end
            end
            if not cur and maxV and durationObject.GetRemainingPercent then
                local okPct, pct = pcall(durationObject.GetRemainingPercent, durationObject)
                if okPct and pct and not IsSecretValue(pct) then
                    local ratio = tonumber(pct)
                    if ratio then
                        cur = (1 - ratio) * maxV
                    end
                end
            end
        end
    end
    return cur, maxV
end

local function ShowInterruptSpark(self, ratio)
    if not self.Spark then
        return
    end
    -- Classic has no InterruptSparkAnim; pip-red + atlas cap sit at the bar end.
    if UseClassicCastBarColorFinish() then
        self.Spark:Hide()
        return
    end
    local parent = self.SparkFrame or self
    local w = parent.GetWidth and parent:GetWidth() or 0
    local h = (self.TimerBar and self.TimerBar:GetHeight()) or 12
    SetAtlasLegacy(self.Spark, "ui-castingbar-pip-red")
    self.Spark:SetVertexColor(1, 1, 1, 1)
    self.Spark:SetSize(8, h * 1.1)
    if ratio and w > 0 then
        self.Spark:ClearAllPoints()
        self.Spark:SetPoint("CENTER", parent, "LEFT", ratio * w, self.sparkEmpoweredOffset or 0)
        self.Spark:Show()
        return
    end
    self.Spark:Hide()
end

-- UNITFRAME look (live + forever CastingBarMixin): interrupted atlas, keep current fill,
-- red pip, localized Interrupted / Interrupted by. Classic Style fills red immediately
-- (CastingBarMixin:ApplyInterruptFilledState) and does not use the interrupted atlas cap.
local function HandleInterrupt(self, failed, interruptedBy)
    self.interrupted = true
    self.beingInterrupted = true
    self.casting = nil
    self.channeling = nil
    self.castGUID = nil
    self.spellID = nil

    pcall(function()
        local label = failed and (FAILED or "Failed") or GetInterruptText(interruptedBy)
        if self.Text then
            self.Text:SetText(label)
            self.Text:ClearAllPoints()
            self.Text:SetJustifyH("CENTER")
            self.Text:SetPoint("CENTER", self, "CENTER", 0, 0)
            self.Text:Show()
        end

        if self.Time then
            self.Time:SetText("")
            self.Time:Hide()
        end

        local cur, maxV = SnapshotCastBarProgress(self)
        local classicFinish = UseClassicCastBarColorFinish()
        local modern = UseModernCastBarArt() and not classicFinish
        local freezeMax = (maxV and maxV > 0) and maxV or 1
        local freezeVal = freezeMax
        local sparkRatio = 1
        if modern and cur and maxV and maxV > 0 then
            freezeVal = math.max(0, math.min(maxV, cur))
            sparkRatio = freezeVal / maxV
        end

        -- Freeze engine DurationObject so the bar does not keep ticking after kick.
        self:SetMinMaxValues(0, freezeMax)
        self:SetValue(freezeVal)

        if classicFinish then
            ApplyCastBarVertexFill(self, FLUX_CASTBAR_INTERRUPT_RED[1], FLUX_CASTBAR_INTERRUPT_RED[2], FLUX_CASTBAR_INTERRUPT_RED[3])
            if self.Spark then
                self.Spark:Hide()
            end
        else
            ApplyCastBarFillAtlas(self, "ui-castingbar-interrupted")
            -- Atlas already carries the red interrupt art (CastingBarMixin:UpdateBarFillTexture).
            ApplyModernFillColor(self)
            ShowInterruptSpark(self, sparkRatio)
        end

        SetCastBarEmpoweredBackdrop(self, false)
        SetCastBarEmpoweredTrough(self, false)
    end)

    self.holdTime = FLUX_CASTBAR_HOLD_INTERRUPT
    self:SetAlpha(1)
    if self.IsShown and not self:IsShown() then
        self:Show()
    end
end

local HideCastBarInstant

local function NotifyCastBarSlotReleased(self)
    local unit = self.unitID
    if unit ~= "player" and unit ~= "vehicle" then
        return
    end
    local ST = ns.SwingTimer
    if ST and ST.OnCastBarSlotReleased then
        ST.OnCastBarSlotReleased()
    end
end

HideCastBarInstant = function(self, isAfterInterrupt)
    if self.fadeTimer then
        self.fadeTimer:Cancel()
        self.fadeTimer = nil
    end
    UIFrameFadeRemoveFrame(self)
    self.fadeOut = nil
    self.stopTime = nil
    self.customTimer = nil
    self.customDuration = nil
    self.customStartTime = nil
    self.customTimerKind = nil
    self.customFromName = nil
    self.customToName = nil
    self._fluxCustomLabelFitPending = nil
    self._fluxClientCastTiming = nil
    self._fluxUsedTimerDuration = nil
    self._fluxCastWallStart = nil
    self._fluxCastWallMax = nil
    self:SetAlpha(1)
    self:Hide()
    if self.Text then
        self.Text:Hide()
        self.Text:SetWidth(0)
    end
    if self.Time then self.Time:Hide() end
    if isAfterInterrupt then
        self.beingInterrupted = nil
        self.interrupted = nil
    end
    NotifyCastBarSlotReleased(self)
end

local function FinishCastBarFade(self)
    if self.casting or self.channeling or self.customTimer then
        self.fadeOut = nil
        if self.fadeTimer then
            self.fadeTimer:Cancel()
            self.fadeTimer = nil
        end
        UIFrameFadeRemoveFrame(self)
        return
    end
    self.fadeOut = nil
    if self.fadeTimer then
        self.fadeTimer:Cancel()
        self.fadeTimer = nil
    end
    local wasInterrupted = self.interrupted
    HideCastBarInstant(self, wasInterrupted)
end

local function StartCastBarFadeOut(self)
    if self.fadeOut then
        return
    end
    if self.casting or self.channeling or self.customTimer then
        return
    end
    if self.fadeTimer then
        self.fadeTimer:Cancel()
        self.fadeTimer = nil
    end
    UIFrameFadeRemoveFrame(self)
    self.fadeOut = true
    self:SetAlpha(1)
    if not self:IsShown() then
        self:Show()
    end
    local fadeDur = self.interrupted and FLUX_CASTBAR_FADE_INTERRUPT or FLUX_CASTBAR_FADE_DURATION
    UIFrameFadeOut(self, fadeDur, self:GetAlpha(), 0)
    self.fadeTimer = C_Timer.NewTimer(fadeDur, function()
        if self.fadeOut and not self.casting and not self.channeling and not self.customTimer then
            FinishCastBarFade(self)
        end
    end)
end

local function CastStop(self, failed)
    -- Don't process if this cast was already interrupted or in post-cast animation
    if self.interrupted or self.holdTime or self.fadeOut then
        return
    end

    local wasChanneling = self.channeling
    self.casting = nil
    self.channeling = nil
    SetCastBarEmpoweredBackdrop(self, false)
    SetCastBarEmpoweredTrough(self, false)

    if failed then
        HandleInterrupt(self, true)
        return
    end

    -- Completed: forever UpdateBarFillTexture(true) swaps filling → full atlas.
    -- Modern full atlases are pre-colored; vertex green on top blows out the end glow.
    -- Classic Style uses classicFullColor (green) on UI-StatusBar; filling/full share a
    -- sheet so SetStatusBarTexture(full) can no-op and skip the success flash.
    local classicFinish = UseClassicCastBarColorFinish()
    local gr, gg, gb = FLUX_CASTBAR_FINISH_GREEN[1], FLUX_CASTBAR_FINISH_GREEN[2], FLUX_CASTBAR_FINISH_GREEN[3]
    if wasChanneling then
        self:SetValue(0) -- Empty bar for completed channel
        if classicFinish then
            ApplyCastBarVertexFill(self, gr, gg, gb)
        else
            ApplyCastBarFillAtlas(self, CASTING_BAR_TYPES.channel.full)
            if not ApplyModernFillColor(self) then
                self:SetStatusBarColor(gr, gg, gb)
            end
        end
    else
        local _, maxValue = self:GetMinMaxValues()
        if IsSecretValue(maxValue) or not maxValue or maxValue <= 0 then
            maxValue = self.maxValue or 1
        end
        -- Detach DurationObject (SetMinMaxValues) so the engine does not clear the
        -- success flash before the hold/fade.
        self:SetMinMaxValues(0, maxValue)
        self:SetValue(math.max(0, maxValue)) -- Full bar for completed cast (ensure valid value)
        if classicFinish then
            ApplyCastBarVertexFill(self, gr, gg, gb)
        else
            ApplyCastBarFillAtlas(self, CASTING_BAR_TYPES.standard.full)
            if not ApplyModernFillColor(self) then
                self:SetStatusBarColor(gr, gg, gb)
            end
        end
    end
    if self.Time then self.Time:SetText("") end

    if self.Spark then self.Spark:Hide() end

    self.holdTime = FLUX_CASTBAR_HOLD_FINISH
    self:SetAlpha(1)
    if self.IsShown and not self:IsShown() then
        self:Show()
    end
end

-- Blizzard Mainline CastingBarFrameStageTierTemplate FlashAnim: glow 0 -> 1 -> 0 (~0.5s)
local function EnsureStageTierGlowFlash(tierFrame, glowTex)
    if tierFrame.GlowFlashAnim or not glowTex or not glowTex.CreateAnimationGroup then
        return
    end
    local ag = glowTex:CreateAnimationGroup()
    local a1 = ag:CreateAnimation("Alpha")
    a1:SetOrder(1)
    a1:SetDuration(0.01)
    a1:SetFromAlpha(0)
    a1:SetToAlpha(1)
    local a2 = ag:CreateAnimation("Alpha")
    a2:SetOrder(2)
    a2:SetDuration(0.5)
    a2:SetFromAlpha(1)
    a2:SetToAlpha(0)
    a2:SetSmoothing("OUT")
    ag:SetScript("OnFinished", function()
        glowTex:SetAlpha(0)
    end)
    tierFrame.GlowFlashAnim = ag
end

local function ConfigureCastBarSpark(castBar, isEmpowered)
    if not castBar.Spark then
        return
    end
    local isPreDF = (FLUX_API and FLUX_API.isPreDF) or (FLUX_API and FLUX_API.majorVersion and FLUX_API.majorVersion < 10) or false
    if isLegacyClient or isPreDF then
        -- Must replace pip-red from HandleInterrupt; do not keep the red interrupt spark.
        castBar.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        castBar.Spark:SetBlendMode("ADD")
        castBar.Spark:SetVertexColor(1, 1, 1, 1)
        local sparkSize = (castBar:GetHeight() or 12) * 1.2
        castBar.Spark:SetSize(sparkSize, sparkSize)
        castBar.sparkEmpoweredOffset = 0
        return
    end
    local h = (castBar.TimerBar and castBar.TimerBar:GetHeight()) or 12
    if isEmpowered then
        SetAtlasLegacy(castBar.Spark, "ui-castingbar-empower-cursor")
        castBar.Spark:SetVertexColor(1, 1, 1, 1)
        castBar.Spark:SetSize(16, h * 1.15)
        castBar.sparkEmpoweredOffset = 4
    else
        -- forever ShowSpark: ui-castingbar-pip (not pip-red leftover from interrupt)
        SetAtlasLegacy(castBar.Spark, "ui-castingbar-pip")
        castBar.Spark:SetVertexColor(1, 1, 1, 1)
        castBar.Spark:SetSize(8, h * 1.1)
        castBar.sparkEmpoweredOffset = 0
    end
end

local function UpdateStage(self)
    -- Mainline: tier i uses Normal when i <= maxStage, Disabled when i > maxStage (no filling-tier layer)
    if not self.isEmpowered or not self.casting then return end

    local stageValue = 0
    local currentValue = self:GetValue()
    if not IsSecretValue(currentValue) then
        stageValue = currentValue * 1000
    else
        return
    end

    local maxStage = 0
    if self.StagePoints then
        for i = 1, self.NumStages do
            if self.StagePoints[i] then
                if stageValue > self.StagePoints[i] then
                    maxStage = i
                else
                    break
                end
            end
        end
    end

    if self.StageTiers then
        for i = 1, self.NumStages - 1 do
            local chargeTier = self.StageTiers[i]
            if chargeTier then
                if i <= maxStage then
                    chargeTier.Normal:SetShown(true)
                    chargeTier.Disabled:SetShown(false)
                else
                    chargeTier.Normal:SetShown(false)
                    chargeTier.Disabled:SetShown(true)
                end
                if chargeTier.Filling then
                    chargeTier.Filling:SetShown(false)
                end
            end
        end
    end

    if maxStage ~= self.CurrSpellStage then
        if maxStage >= 1 and maxStage <= self.NumStages then
            local tier = self.StageTiers[maxStage]
            if tier and tier.GlowFlashAnim then
                tier.GlowFlashAnim:Stop()
                tier.Glow:SetAlpha(0)
                tier.GlowFlashAnim:Play()
            end
        end
        self.CurrSpellStage = maxStage
    end
end

local function AddStages(self, numStages)
    -- Match Blizzard's AddStages implementation exactly
    self.CurrSpellStage = CASTBAR_STAGE_INVALID
    self.NumStages = numStages + 1  -- Includes hold time as final stage
    local sumDuration = 0
    self.StagePoints = {}
    if not self.StagePips then self.StagePips = {} end
    if not self.StageTiers then self.StageTiers = {} end
    
    -- Get maxValue in milliseconds for calculations
    local _, maxValue = self:GetMinMaxValues()
    if IsSecretValue(maxValue) or not maxValue or maxValue <= 0 then
        maxValue = 1
    end
    local stageMaxValue = maxValue * 1000  -- Convert to milliseconds
    
    -- Helper function to get stage duration (matching Blizzard's getStageDuration)
    local getStageDuration = function(stage)
        if stage == self.NumStages then
            -- Final stage is hold time
            local holdTime = GetUnitEmpowerHoldAtMaxTime(self.unitID or "player")
            if holdTime and not IsSecretValue(holdTime) then
                return holdTime
            end
            return 0
        else
            -- Regular stages (API is 0-indexed, we're 1-indexed internally)
            local duration = GetUnitEmpowerStageDuration(self.unitID or "player", stage - 1)
            if duration and not IsSecretValue(duration) then
                return duration
            end
            return 0
        end
    end
    
    -- Get bar dimensions for pip positioning
    local castBarLeft = self.TimerBar:GetLeft()
    local castBarRight = self.TimerBar:GetRight()
    
    if not castBarLeft or not castBarRight then
        return
    end
    
    local castBarWidth = castBarRight - castBarLeft

    -- Create and position pips (matching Blizzard's logic)
    for i = 1, self.NumStages - 1 do
        local duration = getStageDuration(i)
        if duration > CASTBAR_STAGE_DURATION_INVALID then
            sumDuration = sumDuration + duration
            local portion = sumDuration / stageMaxValue
            local offset = castBarWidth * portion
            
            -- Store StagePoints in milliseconds (matching Blizzard)
            self.StagePoints[i] = sumDuration
            
            local pipParent = self.StagePipHolder or self.TimerBar
            if not self.StagePips[i] then
                -- ARTWORK on a low frame-level holder; tier frames use +2 so fills cover pip centers cleanly
                self.StagePips[i] = pipParent:CreateTexture(nil, "ARTWORK")
            else
                self.StagePips[i]:SetParent(pipParent)
            end

            local pip = self.StagePips[i]
            SetAtlasLegacy(pip, "ui-castingbar-empower-pip")
            local barH = self.TimerBar:GetHeight()
            pip:SetHeight(math.max(barH - 2, 8))
            if not pip:GetWidth() or pip:GetWidth() < 2 then
                pip:SetWidth(7)
            end
            pip:SetVertexColor(1, 1, 1, 1)
            pip:SetAlpha(1)
            pip:ClearAllPoints()
            pip:SetPoint("TOP", pipParent, "TOPLEFT", offset, -1)
            pip:SetPoint("BOTTOM", pipParent, "BOTTOMLEFT", offset, 1)
            pip:Show()
        end
    end
    
    -- Create StageTiers with Normal/Disabled/Glow textures (matching Blizzard)
    for i = 1, self.NumStages - 1 do
        -- Create tier frame if needed
        if not self.StageTiers[i] then
            local tierFrame = CreateFrame("Frame", nil, self.TimerBar)
            tierFrame:SetFrameLevel(self.TimerBar:GetFrameLevel() + 2)  -- Above empowered fill texture
            
            -- Normal texture (shown when stage is reached)
            local normal = tierFrame:CreateTexture(nil, "ARTWORK")
            normal:SetAllPoints(tierFrame)
            tierFrame.Normal = normal
            
            -- Disabled texture (shown initially, hidden when stage reached)
            local disabled = tierFrame:CreateTexture(nil, "ARTWORK")
            disabled:SetAllPoints(tierFrame)
            tierFrame.Disabled = disabled
            
            local glow = tierFrame:CreateTexture(nil, "OVERLAY")
            glow:SetAllPoints(tierFrame)
            glow:SetBlendMode("ADD")
            tierFrame.Glow = glow

            self.StageTiers[i] = tierFrame
        end
        
        local chargeTier = self.StageTiers[i]
        local leftStagePip = self.StagePips[i]
        local rightStagePip = self.StagePips[i + 1]

        -- Blizzard Mainline: tier rect from pip center to pip center (CastingBarMixin:AddStages)
        if leftStagePip then
            chargeTier:SetPoint("TOPLEFT", leftStagePip, "TOP", 0, 0)
        end
        if rightStagePip then
            chargeTier:SetPoint("BOTTOMRIGHT", rightStagePip, "BOTTOM", 0, 0)
        else
            chargeTier:SetPoint("BOTTOMRIGHT", self.TimerBar, "BOTTOMRIGHT", 0, 0)
        end

        local chargeTierLeft = chargeTier:GetLeft()
        local chargeTierRight = chargeTier:GetRight()

        if chargeTierLeft and chargeTierRight and castBarWidth > 0 then
            local left = (chargeTierLeft - castBarLeft) / castBarWidth
            local right = 1.0 - ((castBarRight - chargeTierRight) / castBarWidth)

            -- Same geometry as Blizzard; trim UVs slightly at interior seams only so adjacent tier atlases
            -- do not bilinear-bleed into each other (no visible gap — quads still flush).
            local du = math.min(0.5 / castBarWidth, (right - left) * 0.15)
            if du < 1e-6 then
                du = 0
            end
            local uLeft = left
            local uRight = right
            if i > 1 then
                uLeft = uLeft + du
            end
            if rightStagePip then
                uRight = uRight - du
            end
            if uRight <= uLeft then
                uLeft, uRight = left, right
            end

            SetAtlasLegacy(chargeTier.Normal, ("ui-castingbar-tier%d-empower"):format(i))
            SetAtlasLegacy(chargeTier.Disabled, ("ui-castingbar-disabled-tier%d-empower"):format(i))
            SetAtlasLegacy(chargeTier.Glow, ("ui-castingbar-glow-tier%d-empower"):format(i))
            chargeTier.Normal:SetAllPoints(chargeTier)
            chargeTier.Disabled:SetAllPoints(chargeTier)
            chargeTier.Glow:SetAllPoints(chargeTier)

            chargeTier.Normal:SetTexCoord(uLeft, uRight, 0, 1)
            chargeTier.Disabled:SetTexCoord(uLeft, uRight, 0, 1)
            chargeTier.Glow:SetTexCoord(uLeft, uRight, 0, 1)
            if chargeTier.Filling then
                chargeTier.Filling:SetShown(false)
            end
        end

        EnsureStageTierGlowFlash(chargeTier, chargeTier.Glow)

        chargeTier.Normal:SetShown(false)
        chargeTier.Disabled:SetShown(true)
        chargeTier.Glow:SetAlpha(0)
        
        chargeTier:Show()
    end
end

local function ClearStages(self)
    -- Match Blizzard's ClearStages implementation
    if self.StagePips then
        for _, stagePip in pairs(self.StagePips) do
            stagePip:Hide()
        end
    end
    
    if self.StageTiers then
        for _, stageTier in pairs(self.StageTiers) do
            if stageTier.GlowFlashAnim then
                stageTier.GlowFlashAnim:Stop()
            end
            if stageTier.Glow then
                stageTier.Glow:SetAlpha(0)
            end
            stageTier:Hide()
        end
    end
    
    self.NumStages = 0
    self.CurrSpellStage = CASTBAR_STAGE_INVALID
    if self.StagePoints then
        for k in pairs(self.StagePoints) do
            self.StagePoints[k] = nil
        end
    end
end

local function TrimCastBarName(s)
    if strtrim then
        return strtrim(s or "")
    end
    return (s or ""):match("^%s*(.-)%s*$") or ""
end

local function CityOnlyCastBarName(name)
    name = TrimCastBarName(name)
    if name == "" then
        return "?"
    end
    local city = name:match("^([^,]+)")
    return TrimCastBarName(city or name)
end

local function BuildFlightLabelCandidates(fromName, toName)
    local fromFull = TrimCastBarName(fromName)
    local toFull = TrimCastBarName(toName)
    local fromCity = CityOnlyCastBarName(fromFull)
    local toCity = CityOnlyCastBarName(toFull)
    local candidates = {}
    local seen = {}

    local function add(label)
        label = TrimCastBarName(label)
        if label ~= "" and not seen[label] then
            seen[label] = true
            candidates[#candidates + 1] = label
        end
    end

    add(fromFull .. " to " .. toFull)
    add(fromCity .. " to " .. toFull)
    add(fromCity .. " to " .. toCity)
    add(toFull)
    add(toCity)
    return candidates
end

local function ApplyCustomTimerLabel(castBar)
    if not castBar or not castBar.Text or not castBar.customFromName then
        return false
    end

    local barWidth = castBar.TimerBar and castBar.TimerBar:GetWidth() or castBar:GetWidth() or 0
    if barWidth <= 0 then
        return false
    end

    local duration = castBar.customDuration or 1
    local timeFS = castBar.Time
    local timeSample = string.format("%.1f", duration)
    if timeFS then
        timeFS:SetText(timeSample)
    end
    local timeWidth = (timeFS and timeFS:GetStringWidth()) or 0
    local maxTextWidth = barWidth - timeWidth - CASTBAR_TEXT_LEFT_PAD - CASTBAR_TEXT_RIGHT_PAD - CASTBAR_TEXT_TIME_GAP
    if maxTextWidth < 24 then
        maxTextWidth = 24
    end

    local textFS = castBar.Text
    local candidates = BuildFlightLabelCandidates(castBar.customFromName, castBar.customToName)
    local chosen = candidates[#candidates] or castBar.customToName or "Flight"

    for i = 1, #candidates do
        textFS:SetText(candidates[i])
        local textWidth = textFS:GetStringWidth() or 0
        if textWidth <= maxTextWidth then
            chosen = candidates[i]
            break
        end
    end

    textFS:SetText(chosen)
    textFS:SetWidth(maxTextWidth)
    textFS:SetWordWrap(false)
    textFS:SetMaxLines(1)
    textFS:Show()
    return true
end

local function StopCustomTimerInternal(self, opts)
    if not self or not self.customTimer then
        return
    end
    self.customTimer = nil
    self.customDuration = nil
    self.customStartTime = nil
    self.customTimerKind = nil
    self.customFromName = nil
    self.customToName = nil
    self._fluxCustomLabelFitPending = nil
    self.casting = nil
    self.channeling = nil
    SetCastBarEmpoweredBackdrop(self, false)
    SetCastBarEmpoweredTrough(self, false)
    if opts and opts.fade then
        self.holdTime = FLUX_CASTBAR_HOLD_FINISH
    else
        HideCastBarInstant(self)
    end
end

function CB.StopCustomTimer(castBar, opts)
    if castBar then
        StopCustomTimerInternal(castBar, opts)
    end
end

function CB.StartCustomTimer(castBar, timerOpts)
    if not castBar or not timerOpts then
        return
    end
    local duration = tonumber(timerOpts.duration) or 0
    if duration <= 0 then
        return
    end

    StopCustomTimerInternal(castBar)

    castBar.casting = nil
    castBar.channeling = nil
    castBar.fadeOut = nil
    castBar.holdTime = nil
    castBar.stopTime = nil
    castBar.beingInterrupted = nil
    castBar.preInterrupt = nil
    castBar.isEmpowered = nil
    castBar.interrupted = nil
    if castBar.fadeTimer then
        castBar.fadeTimer:Cancel()
        castBar.fadeTimer = nil
    end
    UIFrameFadeRemoveFrame(castBar)
    ClearStages(castBar)

    castBar.customTimer = true
    castBar.customDuration = duration
    castBar.customStartTime = timerOpts.startTime or GetTime()
    castBar.customTimerKind = timerOpts.kind or "default"
    castBar.customFromName = timerOpts.fromName
    castBar.customToName = timerOpts.toName
    castBar._fluxCustomLabelFitPending = true
    castBar._fluxTimeTextAccum = FLUX_CASTBAR_TIME_TEXT_INTERVAL

    SetCastBarEmpoweredBackdrop(castBar, false)
    SetCastBarEmpoweredTrough(castBar, false)
    ApplyCastBarFillAtlas(castBar, CASTING_BAR_TYPES.standard.filling)
    local barColor = timerOpts.barColor or FLUX_CUSTOM_TIMER_COLORS[timerOpts.kind] or FLUX_CUSTOM_TIMER_COLORS.default
    castBar:SetStatusBarColor(barColor[1], barColor[2], barColor[3])

    local icon = timerOpts.icon or "Interface\\ICONS\\INV_Misc_PocketWatch_02"
    if castBar.Icon then
        castBar.Icon:SetTexture(icon)
        if castBar.IconFrame then
            castBar.IconFrame:Show()
        end
    end

    castBar:SetMinMaxValues(0, duration)
    local elapsed = GetTime() - castBar.customStartTime
    if elapsed < 0 then elapsed = 0 end
    if elapsed > duration then elapsed = duration end
    castBar:SetValue(elapsed)

    ConfigureCastBarSpark(castBar, false)
    if castBar.ShieldOverlay then
        castBar.ShieldOverlay:Hide()
    end

    castBar:SetAlpha(1)
    castBar:Show()
    AddStages(castBar, 0)

    if castBar.UpdateLayout then
        castBar.UpdateLayout()
    end

    if timerOpts.fromName and timerOpts.toName then
        if not ApplyCustomTimerLabel(castBar) then
            castBar._fluxCustomLabelFitPending = true
        end
    else
        local label = timerOpts.name or FLIGHT or "Flight"
        if castBar.Text then
            castBar.Text:SetText(label)
            castBar.Text:SetWidth(0)
            castBar.Text:Show()
        end
    end
    if castBar.Time then
        castBar.Time:Show()
        local remaining = duration - elapsed
        if remaining < 0.05 then remaining = 0 end
        castBar.Time:SetFormattedText("%.1f", remaining)
    end

    local unit = castBar.unitID
    if unit == "player" or unit == "vehicle" then
        local ST = ns.SwingTimer
        if ST and ST.HideForCastBarClaim then
            ST.HideForCastBarClaim()
        end
    end
end

local function CastStart(self, unit, isChannel, castGUID)
    if FluxUnitFrames_ShouldShowCastBar and not FluxUnitFrames_ShouldShowCastBar(unit) then
        self:Hide()
        return
    end
    if self._fluxPetCastDisabled then
        self:Hide()
        return
    end

    if self.customTimer then
        StopCustomTimerInternal(self)
    end

    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID
    local numStages = 0

    pcall(function()
        if isChannel then
            if UnitChannelInfo then
                name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID, _, numStages = UnitChannelInfo(unit)
                castID = nil
            end
        else
            if UnitCastingInfo then
                name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
            end
        end
    end)

    if not CastLooksActive(name, text, spellID, startTime, endTime) then
        self:Hide()
        return
    end

    -- FULL RESET of all state variables to prevent pollution from previous casts
    self.casting = nil
    self.channeling = nil
    self.fadeOut = nil
    self.stopTime = nil
    self.beingInterrupted = nil
    self.preInterrupt = nil
    self.isEmpowered = nil
    self.holdTime = nil
    self.interrupted = nil

    -- Reset Legacy Fade State
    if self.fadeTimer then
        self.fadeTimer:Cancel()
        self.fadeTimer = nil
    end
    UIFrameFadeRemoveFrame(self) -- Remove any UIFrameFade effects

    -- Clear any existing stages (matching Blizzard's ClearStages call)
    ClearStages(self)

    -- Empowered Logic (handle secret numStages)
    local isChargeSpell = SafeBooleanTest(numStages) and SafeGetNumber(numStages) > 0
    self.isEmpowered = isChargeSpell
    self.unitID = unit -- Store for AddStages usage

    -- Calculate maxValue including hold time for empowered casts (matching Blizzard)
    if isChargeSpell then
        if GetUnitEmpowerHoldAtMaxTime then
            local holdTime = GetUnitEmpowerHoldAtMaxTime(unit)
            -- Only add holdTime when we can safely use endTime (not secret)
            if (not canaccessvalue) or (canaccessvalue(endTime) and canaccessvalue(holdTime)) then
                endTime = endTime + holdTime
            end
        end
        -- Treat empowered as a CAST (Filling Up), but it comes as a CHANNEL event.
        isChannel = false -- Force casting behavior logic
    end

    -- forever HandleCastStart: UpdateBarFillTexture + ShowSpark before SetValue /
    -- SetTimerDuration. Interrupt leaves ui-castingbar-interrupted + pip-red; if the
    -- engine timer starts first, the next cast keeps the red cap glow.
    local barType = "standard"
    if isChargeSpell then
        barType = "empowered"
    elseif SafeBooleanTest(notInterruptible) then
        barType = "uninterruptable"
    elseif isChannel then
        barType = "channel"
    end

    if isChargeSpell then
        if self.TimerBar.SetColorFill then
            self.TimerBar:SetColorFill(0, 0, 0, 0)
        end
        if self.TimerBar.statusBarTexture then
            self.TimerBar.statusBarTexture:Hide()
        end
        if self.TimerBar then
            self.TimerBar._fluxFillAtlas = nil
        end
        SetCastBarEmpoweredBackdrop(self, true)
        SetCastBarEmpoweredTrough(self, true)
    else
        SetCastBarEmpoweredBackdrop(self, false)
        SetCastBarEmpoweredTrough(self, false)
        ApplyCastBarFillAtlas(self, CASTING_BAR_TYPES[barType].filling)
        if not ApplyModernFillColor(self) then
            if isChannel then
                self:SetStatusBarColor(0.6, 0.4, 1.0) -- Purple/lavender for channeling
            else
                self:SetStatusBarColor(1, 0.95, 0) -- Classic yellow/gold for casting
            end
        end
    end
    ConfigureCastBarSpark(self, SafeBooleanTest(self.isEmpowered))

    -- Forever CastingBarMixin uses UnitCastingInfo start/end + OnUpdate elapsed.
    -- DurationObject is only the tainted fallback when those times cannot be used.
    local usedTimerDuration = false
    local maxValue = nil
    self._fluxClientCastTiming = nil

    if not isChargeSpell and ApplyClientCastTiming(self, startTime, endTime, isChannel) then
        maxValue = self.maxValue
    elseif self.SetTimerDuration and not isChargeSpell then
        local durationObj = ApplyCastBarTimerDuration(self, unit, isChannel, false)
        if durationObj then
            usedTimerDuration = true
            maxValue = TryGetDurationSeconds(durationObj)
            self._fluxUsedTimerDuration = true
        end
    end

    if not maxValue then
        maxValue = TryGetDurationSeconds(GetUnitCastDurationObject(unit, isChannel, isChargeSpell))
    end

    if not maxValue then
        if usedTimerDuration then
            maxValue = SpellCastTimeFromID(spellID) or self.maxValue or (isChannel and 6.0) or 1.5
            self.maxValue = maxValue
        else
            maxValue = SpellCastTimeFromID(spellID) or (isChannel and 6.0) or 1.5
            self.maxValue = maxValue
            self.value = isChannel and maxValue or 0
            self._fluxClientCastTiming = true
            self._fluxUsedTimerDuration = false
            self:SetMinMaxValues(0, maxValue)
            self:SetValue(self.value)
        end
    end

    self.maxValue = maxValue or self.maxValue
    self._fluxUsedTimerDuration = usedTimerDuration or self._fluxUsedTimerDuration
    self._fluxCastWallStart = GetTime()
    self._fluxCastWallMax = self.maxValue

    -- Set casting/channeling state
    if self.isEmpowered then
        -- Empowered casts: handle manually (SetTimerDuration doesn't work well with SetColorFill)
        self.casting = true
        self.channeling = nil
    elseif isChannel then
        self.channeling = true
        self.casting = nil
    else
        self.casting = true
        self.channeling = nil
    end
    -- Flux perf T2.3: force the first time-text refresh of a new cast to happen
    -- on the very next OnUpdate tick so there is no visible lag before any
    -- number appears.
    self._fluxTimeTextAccum = FLUX_CASTBAR_TIME_TEXT_INTERVAL

    self.notInterruptible = SafeBooleanTest(notInterruptible)
    self.castID = castID
    self.castGUID = castGUID or castID
    self.spellID = spellID
    UpdateCastBarColor(self, unit)

    -- Handle icon like Forever HandleCastStart: Icon:SetTexture(texture).
    if self.Icon then
        local painted = false
        if not IsPlaceholderIcon(texture) then
            painted = pcall(function()
                self.Icon:SetTexture(texture)
            end)
        end
        if not painted then
            local profIcon = GetProfessionIconForSpell(name, spellID)
            if profIcon then
                painted = pcall(function()
                    self.Icon:SetTexture(profIcon)
                end)
            end
        end
        if self.IconFrame then
            self.IconFrame:SetShown(painted and true or false)
        end
    end

    if self.Text then
        local tName = nil
        local tUnit = nil
        local accessibleText = (text ~= nil and not IsSecretValue(text)) and text or nil

        local okText = pcall(function()
            -- Determine Target (player/vehicle only; never concat secret spell text)
            if unit == "player" or unit == "vehicle" then
                local sent = self.sentTarget
                if sent ~= nil and not IsSecretValue(sent) and API.CanAccessValue(sent) then
                    tName = sent
                    tUnit = FindUnitForCastTargetName(sent, nil)
                end
            elseif accessibleText and accessibleText:find(" > ") then
                local _, targetName = accessibleText:match("^(.-) > (.+)$")
                if targetName ~= nil and not IsSecretValue(targetName) and API.CanAccessValue(targetName) then
                    tName = targetName
                    tUnit = FindUnitForCastTargetName(targetName, unit)
                end
            end

            local spellPart = accessibleText
            if spellPart and spellPart:find(" > ") then
                spellPart = spellPart:match("^(.-) > .+$") or spellPart
            end

            if tName ~= nil and not IsSecretValue(tName) and API.CanAccessValue(tName) and spellPart then
                local colorHex = "ffffffff"

                if tUnit and UnitExists(tUnit) then
                    if UnitIsPlayer(tUnit) then
                        local _, class = UnitClass(tUnit)
                        class = API.SafeAccessibleString(class)
                        local c = class and RAID_CLASS_COLORS[class]
                        if c then
                            colorHex = c.colorStr
                        end
                    else
                        local reaction = UnitReaction(tUnit, "player")
                        if reaction then
                            if reaction >= 5 then
                                colorHex = "ff00ff00"
                            elseif reaction == 4 then
                                colorHex = "ffffff00"
                            else
                                colorHex = "ffcc0000"
                            end
                        end
                    end
                end

                self.Text:SetText(spellPart .. " > |c" .. colorHex .. tName .. "|r")
            else
                PaintCastBarSpellText(self.Text, name, text, isChannel)
            end
        end)

        if not okText then
            PaintCastBarSpellText(self.Text, name, text, isChannel)
        end

        self.Text:ClearAllPoints()
        self.Text:SetJustifyH("LEFT")
        self.Text:SetPoint("LEFT", self.TimerBar, "LEFT", CastBarSpellTextLeftPad(self), 0)
        self.Text:Show()
    end

    if self.Time then
        PaintCastBarRemainingTime(self)
    end

    -- Manual min/max only when not using DurationObject (SetMinMaxValues clears SetTimerDuration).
    if not usedTimerDuration and not self._fluxClientCastTiming then
        self:SetMinMaxValues(0, maxValue)
    end

    -- Empowered / client-timed casts: OnUpdate ticks self.value like CastingBarMixin.
    if self.isEmpowered and not self._fluxClientCastTiming then
        if not ApplyClientCastTiming(self, startTime, endTime, false) then
            self.value = 0
            self.maxValue = maxValue or 1
            self._fluxClientCastTiming = true
            if not usedTimerDuration then
                self:SetMinMaxValues(0, self.maxValue)
                self:SetValue(self.value)
            end
        end
    end
    
    self:SetAlpha(1)
    self:Show()
    PaintCastBarRemainingTime(self)
    
    -- AddStages after Show so that the layout is valid (matching Blizzard's pattern)
    if self.isEmpowered then
        AddStages(self, numStages)
    else
        AddStages(self, 0)
    end

    if unit == "player" or unit == "vehicle" then
        local ST = ns.SwingTimer
        if ST and ST.HideForCastBarClaim then
            ST.HideForCastBarClaim()
        end
    end
end

function CB.RefreshCastForUnit(castBar, unit)
    if not castBar or not unit then
        return false
    end

    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID
    local isChannel = false
    pcall(function()
        if UnitCastingInfo then
            name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
        end
    end)
    if not CastLooksActive(name, text, spellID, startTime, endTime) then
        pcall(function()
            if UnitChannelInfo then
                name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
            end
        end)
        isChannel = CastLooksActive(name, text, spellID, startTime, endTime)
        if isChannel then
            castID = nil
        end
    end

    if CastLooksActive(name, text, spellID, startTime, endTime) then
        CastStart(castBar, unit, isChannel, castID)
        return true
    end

    if not castBar.fadeOut and not (castBar.holdTime and castBar.holdTime > 0) then
        castBar:Hide()
        castBar:SetAlpha(1)
        castBar.casting = nil
        castBar.channeling = nil
        castBar.fadeOut = nil
        castBar.castGUID = nil
        castBar.castID = nil
        castBar.spellID = nil
        castBar._fluxClientCastTiming = nil
    end
    return false
end

-- Flux perf T2.3: Time-text refresh period. The time label displays "%.1f"
-- seconds so there is no visible benefit to updating it every frame (60Hz);
local function CastBar_SetValueIfChanged(self, value)
    local last = self._fluxLastBarValue
    if last ~= nil and value ~= nil and math.abs(value - last) < 0.001 then
        return false
    end
    self._fluxLastBarValue = value
    self:SetValue(value)
    return true
end

local function CastBar_SetSparkIfChanged(self, sparkRatio)
    if not self.Spark then return end
    local last = self._fluxLastSparkRatio
    local parent = self.SparkFrame or self
    local w = parent.GetWidth and parent:GetWidth() or 0
    local eps = (w > 0) and (1 / w) or 0.002
    if last ~= nil and math.abs(sparkRatio - last) < eps then
        return
    end
    self._fluxLastSparkRatio = sparkRatio
    self.Spark:Show()
    local oy = self.sparkEmpoweredOffset or 0
    self.Spark:SetPoint("CENTER", parent, "LEFT", sparkRatio * w, oy)
end

local function OnUpdate(self, elapsed)
    -- Only hide if there's no active cast, hold, or fade
    if not self.casting and not self.channeling and not self.customTimer and not self.preInterrupt
        and (not self.holdTime or self.holdTime <= 0) and not self.fadeOut then
        self:SetAlpha(0)
        self:Hide()
        return
    end

    if self.fadeOut then
        return
    end

    -- Post-cast hold: skip progress updates, only count down to fade
    if not self.casting and not self.channeling and not self.customTimer and self.holdTime and self.holdTime > 0 then
        self.holdTime = self.holdTime - elapsed
        if self.holdTime <= 0 then
            self.holdTime = nil
            StartCastBarFadeOut(self)
        end
        return
    end

    -- If being interrupted, don't update the cast progress
    if self.beingInterrupted or self.preInterrupt then
        return
    end

    -- Flux perf T2.3: accumulate elapsed and gate the time-text refresh.
    local _timeAccum = (self._fluxTimeTextAccum or 0) + (elapsed or 0)
    local _updateTimeText = _timeAccum >= FLUX_CASTBAR_TIME_TEXT_INTERVAL
    if _updateTimeText and FluxUnitFrames_ShouldShowCastTime then
        local castUnit = self.unitID or self.unit
        if not FluxUnitFrames_ShouldShowCastTime(castUnit) then
            _updateTimeText = false
            if self.Time then
                self.Time:Hide()
            end
        end
    end
    if _updateTimeText then
        self._fluxTimeTextAccum = 0
    else
        self._fluxTimeTextAccum = _timeAccum
    end

    -- Custom timer (flight path, etc.): manual elapsed fill like empowered casts
    if self.customTimer then
        if self._fluxCustomLabelFitPending then
            if ApplyCustomTimerLabel(self) then
                self._fluxCustomLabelFitPending = nil
            end
        end

        local maxValue = self.customDuration or 1
        if maxValue <= 0 then maxValue = 1 end
        local elapsedTime = GetTime() - (self.customStartTime or GetTime())
        if elapsedTime < 0 then elapsedTime = 0 end

        if elapsedTime >= maxValue then
            CastBar_SetValueIfChanged(self, maxValue)
            if self.Time then
                self.Time:SetText("")
            end
            if self.Spark then
                self.Spark:Hide()
            end
            if not self.holdTime and not self.fadeOut then
                StopCustomTimerInternal(self, { fade = true })
            end
            return
        end

        CastBar_SetValueIfChanged(self, elapsedTime)

        if self.Time and _updateTimeText then
            local remainingTime = maxValue - elapsedTime
            if remainingTime < 0.05 then remainingTime = 0 end
            self.Time:SetFormattedText("%.1f", remainingTime)
            self.Time:Show()
        end

        if self.Spark then
            local _, maxVal = self:GetMinMaxValues()
            if maxVal and maxVal > 0 then
                local sparkRatio = elapsedTime / maxVal
                sparkRatio = math.max(0, math.min(1, sparkRatio))
                CastBar_SetSparkIfChanged(self, sparkRatio)
            end
        end
        return
    end

    -- For empowered casts, manually track value like Blizzard does (SetTimerDuration doesn't work well with SetColorFill)
    if self.isEmpowered and self.casting then
        -- Initialize value if not set
        if not self.value then
            self.value = 0
        end
        
        -- Manually increment value each frame (matching Blizzard's pattern)
        self.value = self.value + elapsed
        
        -- Check for completion (matching Blizzard's pattern)
        if self.value >= self.maxValue then
            CastBar_SetValueIfChanged(self, self.maxValue)
            if self.Time then
                self.Time:SetText("")
            end
            -- Hide spark when at max (matching Blizzard)
            if self.Spark then
                self.Spark:Hide()
            end
            -- Don't finish immediately - let it hold at max (matching Blizzard's behavior)
            -- The EMPOWER_STOP event will handle completion
            return
        end
        
        CastBar_SetValueIfChanged(self, self.value)

        -- Update time display (throttled to ~20Hz for "%.1f" precision).
        if self.Time and _updateTimeText then
            PaintCastBarRemainingTime(self)
        end
        
        -- Update spark position
        if self.Spark then
            local _, maxValue = self:GetMinMaxValues()
            if maxValue and maxValue > 0 then
                local sparkRatio = self.value / maxValue
                sparkRatio = math.max(0, math.min(1, sparkRatio))
                CastBar_SetSparkIfChanged(self, sparkRatio)
            end
        end

        UpdateStage(self)
        
        return  -- Skip the rest of OnUpdate for empowered casts
    end

    -- Forever CastingBarMixin:OnUpdate: tick cached start/end value; do not re-query
    -- UnitCastingInfo (that false-stops secret/Forever target casts).
    if self._fluxClientCastTiming and (self.casting or self.channeling) then
        local maxValue = self.maxValue or 1
        if maxValue <= 0 then
            maxValue = 1
        end
        if self.casting then
            self.value = (self.value or 0) + elapsed
            if self.value >= maxValue then
                CastBar_SetValueIfChanged(self, maxValue)
                if self.Time then
                    self.Time:SetText("")
                end
                if self.Spark then
                    self.Spark:Hide()
                end
                CastStop(self, false)
                return
            end
            CastBar_SetValueIfChanged(self, self.value)
        else
            self.value = (self.value or maxValue) - elapsed
            if self.value <= 0 then
                CastBar_SetValueIfChanged(self, 0)
                if self.Time then
                    self.Time:SetText("")
                end
                if self.Spark then
                    self.Spark:Hide()
                end
                CastStop(self, false)
                return
            end
            CastBar_SetValueIfChanged(self, self.value)
        end

        if self.Time and _updateTimeText then
            PaintCastBarRemainingTime(self)
        end

        if self.Spark then
            local sparkRatio = self.value / maxValue
            sparkRatio = math.max(0, math.min(1, sparkRatio))
            CastBar_SetSparkIfChanged(self, sparkRatio)
        end
        return
    end

    -- Update time display and spark position using GetTimerDuration() (12.0+) or manual calculation (pre-12.0)
    local durationObject
    if self.GetTimerDuration then
        local okDur, dur = pcall(self.GetTimerDuration, self)
        if okDur then
            durationObject = dur
        end
    end

    if durationObject then
        local remainingTime
        if durationObject.GetRemainingDuration then
            local okRem, rem = pcall(durationObject.GetRemainingDuration, durationObject)
            if okRem then
                remainingTime = rem
            end
        end

        if remainingTime ~= nil and not IsSecretValue(remainingTime) then
            local rem = tonumber(remainingTime)
            if rem then
                if self.channeling then
                    self.value = rem
                elseif self.maxValue then
                    self.value = math.max(0, self.maxValue - rem)
                end
            end
        elseif self._fluxCastWallStart and self._fluxCastWallMax then
            local elapsedWall = GetTime() - self._fluxCastWallStart
            local maxV = self._fluxCastWallMax
            if self.channeling then
                self.value = math.max(0, maxV - elapsedWall)
            else
                self.value = math.min(maxV, math.max(0, elapsedWall))
            end
            if not self.maxValue then
                self.maxValue = maxV
            end
        end
        if self.Time and _updateTimeText then
            PaintCastBarRemainingTime(self)
        end

        if self.Spark then
            local sparkRatio = nil
            if self.channeling and durationObject.GetRemainingPercent then
                local ok, pct = pcall(durationObject.GetRemainingPercent, durationObject)
                if ok and pct ~= nil and not IsSecretValue(pct) then
                    sparkRatio = tonumber(pct)
                end
            elseif durationObject.GetElapsedPercent then
                local ok, pct = pcall(durationObject.GetElapsedPercent, durationObject)
                if ok and pct ~= nil and not IsSecretValue(pct) then
                    sparkRatio = tonumber(pct)
                end
            end
            if sparkRatio == nil then
                local okVal, currentValue = pcall(self.GetValue, self)
                local okMax, _, maxValue = pcall(self.GetMinMaxValues, self)
                if okVal and okMax and currentValue ~= nil and maxValue ~= nil
                    and not IsSecretValue(currentValue) and not IsSecretValue(maxValue)
                    and maxValue > 0 then
                    sparkRatio = currentValue / maxValue
                end
            end
            if sparkRatio then
                sparkRatio = math.max(0, math.min(1, sparkRatio))
                self.Spark:Show()
                local sparkParent = self.SparkFrame or self
                self.Spark:SetPoint("CENTER", sparkParent, "LEFT", sparkRatio * sparkParent:GetWidth(), 0)
            else
                self.Spark:Hide()
            end
        end

        if remainingTime ~= nil and not IsSecretValue(remainingTime) and remainingTime <= 0
            and not self.beingInterrupted and not self.holdTime and not self.fadeOut then
            CastStop(self, false)
        end
    else
        -- Fallback when GetTimerDuration is nil: re-apply DurationObject on 12.0+, else manual timing.
        if API.isV12 and self.SetTimerDuration and not self.isEmpowered
            and (self.casting or self.channeling) then
            local reapplied = ApplyCastBarTimerDuration(
                self,
                self.unitID,
                self.channeling and true or false,
                false
            )
            if reapplied then
                self._fluxUsedTimerDuration = true
                local total = TryGetDurationSeconds(reapplied)
                if total then
                    self.maxValue = total
                end
                -- Engine will drive the bar; refresh text/spark next tick via GetTimerDuration.
                return
            end
        end

        local remainingTime = 0
        local maxTime = self.maxValue or 1
        local currentTime = GetTime()
        local usedSecretTiming = false
        local payloadGone = false

        if self.casting then
            local name, text, texture, startTime, endTime, spellID = ProbeUnitCastFields(self.unitID, false)
            if CastLooksActive(name, text, spellID, startTime, endTime) then
                local canUseTiming = startTime ~= nil and endTime ~= nil
                    and not IsSecretValue(startTime) and not IsSecretValue(endTime)
                if not canUseTiming then
                    usedSecretTiming = true
                    -- Estimated progress when DurationObject unavailable (spellID castTime).
                    maxTime = SpellCastTimeFromID(self.spellID) or self.maxValue or 1.5
                    local barValue = math.min(SafeGetNumber(self:GetValue(), 0) + elapsed, maxTime)
                    remainingTime = maxTime - barValue
                    self:SetMinMaxValues(0, maxTime)
                    self:SetValue(barValue)
                    self.maxValue = maxTime
                else
                    remainingTime = (endTime / 1000) - currentTime
                    maxTime = (endTime - startTime) / 1000
                    local castElapsed = currentTime - (startTime / 1000)

                    self:SetMinMaxValues(0, maxTime)
                    self:SetValue(castElapsed)
                    self.maxValue = maxTime
                end
            else
                payloadGone = true
            end
        elseif self.channeling then
            local name, text, texture, startTime, endTime, spellID = ProbeUnitCastFields(self.unitID, true)
            if CastLooksActive(name, text, spellID, startTime, endTime) then
                local canUseTiming = startTime ~= nil and endTime ~= nil
                    and not IsSecretValue(startTime) and not IsSecretValue(endTime)
                if not canUseTiming then
                    usedSecretTiming = true
                    maxTime = SpellCastTimeFromID(self.spellID) or self.maxValue or 6.0
                    local prevVal = SafeGetNumber(self:GetValue(), maxTime)
                    if prevVal <= 0 and maxTime > 0 then prevVal = maxTime end
                    local barValue = math.max(prevVal - elapsed, 0)
                    remainingTime = barValue
                    self:SetMinMaxValues(0, maxTime)
                    self:SetValue(barValue)
                    self.maxValue = maxTime
                else
                    remainingTime = (endTime / 1000) - currentTime
                    maxTime = (endTime - startTime) / 1000
                    local castElapsed = currentTime - (startTime / 1000)

                    self:SetMinMaxValues(0, maxTime)
                    self:SetValue(maxTime - castElapsed)
                    self.maxValue = maxTime
                end
            else
                payloadGone = true
            end
        end

        if payloadGone and not self.beingInterrupted and not self.holdTime and not self.fadeOut then
            CastStop(self, false)
            return
        end

        -- Update time display (throttled to ~20Hz).
        if self.Time and _updateTimeText then
            PaintCastBarRemainingTime(self)
        end

        -- Update spark position
        if self.Spark then
            local okVal, currentValue = pcall(self.GetValue, self)
            local okMax, _, maxValue = pcall(self.GetMinMaxValues, self)

            if okVal and okMax and currentValue ~= nil and maxValue ~= nil
                and not IsSecretValue(currentValue) and not IsSecretValue(maxValue)
                and maxValue > 0 then
                local sparkRatio = currentValue / maxValue
                sparkRatio = math.max(0, math.min(1, sparkRatio))

                self.Spark:Show()
                local sparkParent = self.SparkFrame or self
                self.Spark:SetPoint("CENTER", sparkParent, "LEFT", sparkRatio * sparkParent:GetWidth(), 0)
            else
                self.Spark:Hide()
            end
        end

        if self.isEmpowered and self.casting then
            UpdateStage(self)
        end

        if not usedSecretTiming and remainingTime <= 0 and not self.beingInterrupted
            and not self.holdTime and not self.fadeOut then
            CastStop(self, false)
        end
    end
end


-- ---------------------------------------------------------------------------
-- Creation
-- ---------------------------------------------------------------------------

-- FluxBorder.ApplyTo draws atlas corners/edges on FluxBorderFrame at shell:GetFrameLevel()+10
-- (see FluxBorder.lua). Progress spark must sit above FluxBorderFrame. Stage pips live inside
-- TimerBar below stage tier frames (+2) so they do not stack on top of tier art as a seam overlay.
local function SyncCastBarChromeFrameLevels(castBar)
    local shell = castBar.BorderFrame
    if not shell then
        return
    end
    local top = (shell.FluxBorderFrame and shell.FluxBorderFrame:GetFrameLevel()) or (shell:GetFrameLevel() + 10)
    if castBar.StagePipHolder and castBar.TimerBar then
        castBar.StagePipHolder:SetFrameLevel(castBar.TimerBar:GetFrameLevel() + 1)
    end
    if castBar.SparkFrame then
        castBar.SparkFrame:SetFrameLevel(top + 2)
    end
end

function CB.CreateCastBar(frame, unit)
    if frame.CastBar then
        return frame.CastBar
    end
    -- We attach to the unit frame "frame"
    -- We attach to the unit frame "frame"
    -- Main Container Frame (Holds everything)
    local castBar = CreateFrame("Frame", nil, frame)
    castBar.unitID = unit
    castBar:SetFrameLevel(frame:GetFrameLevel() + 40) -- Ensure above TextOverlay (+30) 
    castBar:Hide()

    -- Child StatusBar (The actual fill) - Inset by 2px to fit inside border
    local timerBar = CreateFrame("StatusBar", nil, castBar)
    timerBar:SetPoint("TOPLEFT", castBar, "TOPLEFT", 2, -2)
    timerBar:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -2, 2)
    -- Empower tier atlases include a dark margin. Keep that inside the bar.
    if timerBar.SetClipsChildren then
        timerBar:SetClipsChildren(true)
    end
    timerBar:SetMinMaxValues(0, 1)
    timerBar:SetValue(0)

    -- Proxy StatusBar methods from castBar to timerBar
    castBar.SetValue = function(self, ...) timerBar:SetValue(...) end
    castBar.GetValue = function(self, ...) return timerBar:GetValue(...) end
    castBar.SetMinMaxValues = function(self, ...) timerBar:SetMinMaxValues(...) end
    castBar.GetMinMaxValues = function(self, ...) return timerBar:GetMinMaxValues(...) end
    castBar.SetStatusBarColor = function(self, ...) timerBar:SetStatusBarColor(...) end
    castBar.SetStatusBarTexture = function(self, ...) timerBar:SetStatusBarTexture(...) end
    castBar.GetStatusBarTexture = function(self, ...) return timerBar:GetStatusBarTexture(...) end

    -- Store timerBar before fill apply (engine owns the BarTexture; do not SetSize/SetAtlas).
    castBar.TimerBar = timerBar
    ApplyCastBarFillAtlas(castBar, CASTING_BAR_TYPES.standard.filling)
    if not ApplyModernFillColor(castBar) then
        timerBar:SetStatusBarColor(1, 0.95, 0)
    end

    -- Only proxy timer methods if they exist (12.0+)
    if timerBar.SetTimerDuration then
        castBar.SetTimerDuration = function(self, ...) timerBar:SetTimerDuration(...) end
    end
    if timerBar.GetTimerDuration then
        castBar.GetTimerDuration = function(self, ...) return timerBar:GetTimerDuration(...) end
    end

    -- Background (Matches Inner StatusBar size) - use proper texture like old system
    local bg = timerBar:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(castBar:GetWidth() - 4, castBar:GetHeight() - 4)
    bg:SetPoint("CENTER", timerBar, "CENTER", 0, 0)
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0.3, 0.3, 0.3, 1) -- Lighter gray background like old system
    castBar.bg = bg

    -- Create a dedicated high-level container for text (like old system)
    local textHolder = CreateFrame("Frame", nil, castBar)
    textHolder:SetAllPoints(timerBar)
    textHolder:SetFrameLevel(castBar:GetFrameLevel() + 50)

    local castFont = (unit == "focus") and 8 or 12 -- focus: ~30% smaller than 12

    -- Text (Spell name - match unit frame font styling)
    local spellText = textHolder:CreateFontString(nil, "OVERLAY")
    spellText:SetFont("Fonts\\FRIZQT__.TTF", castFont, "OUTLINE") -- Match unit frame font
    spellText:SetPoint("LEFT", textHolder, "LEFT", CASTBAR_TEXT_LEFT_PAD, 0)
    spellText:SetJustifyH("LEFT")
    spellText:SetTextColor(1, 1, 1)
    spellText:Hide() -- Hide initially
    castBar.Text = spellText

    -- Time (Remaining time - match unit frame font styling)
    local timeText = textHolder:CreateFontString(nil, "OVERLAY")
    timeText:SetFont("Fonts\\FRIZQT__.TTF", castFont, "OUTLINE") -- Match unit frame font
    timeText:SetPoint("RIGHT", textHolder, "RIGHT", -4, 0)
    timeText:SetJustifyH("RIGHT")
    timeText:SetTextColor(1, 1, 1)
    timeText:Hide() -- Hide initially
    castBar.Time = timeText

    -- Icon (Separate frame to handle border nicely)
    local iconFrame = CreateFrame("Frame", nil, castBar)
    -- Size will be set in UpdateLayout
    castBar.IconFrame = iconFrame

    -- Icon texture (Inset by 2px to fit inside border)
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    castBar.Icon = icon

    -- Icon Border
    local iconBorder = CreateFrame("Frame", nil, iconFrame)
    iconBorder:SetFrameLevel(iconFrame:GetFrameLevel() + 1)
    iconBorder:SetAllPoints()
    castBar.IconBorder = iconBorder

    if Border then
        Border:ApplyTo(iconBorder, 2, 2, 2, 2)
        do
            local br, bg, bb, dr, dg, db = GetCastBarChromeColors(unit)
            Border:SetBorderColor(iconBorder, br, bg, bb, 1)
            Border:SetBackdropColor(iconBorder, dr, dg, db, 0.85)
        end
    end

    -- Shield overlay for uninterruptible casts
    local shieldFrame = CreateFrame("Frame", nil, iconFrame)
    shieldFrame:SetFrameLevel(iconFrame:GetFrameLevel() + 2) -- Above icon border
    shieldFrame:SetFrameStrata("HIGH")
    -- Size will be set in UpdateLayout to properly fit over the icon

    local shieldTexture = shieldFrame:CreateTexture(nil, "ARTWORK")
    shieldTexture:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield")
    shieldTexture:SetTexCoord(0, 36/256, 0, 1) -- Proper tex coord for small shield
    shieldTexture:SetAllPoints(shieldFrame)
    shieldFrame:Hide()

    castBar.ShieldOverlay = shieldFrame

    -- Cast Bar Border (Attached to Main Container)
    local barBorder = CreateFrame("Frame", nil, castBar)
    barBorder:SetFrameLevel(castBar:GetFrameLevel() + 1)
    barBorder:SetAllPoints()
    castBar.BorderFrame = barBorder

    if Border then
        Border:ApplyTo(barBorder, 2, 2, 2, 2)
        do
            local br, bg, bb, dr, dg, db = GetCastBarChromeColors(unit)
            Border:SetBorderColor(barBorder, br, bg, bb, 1)
            Border:SetBackdropColor(barBorder, dr, dg, db, 0.85)
        end
    end

    -- Empowered stage pips: child of TimerBar, frame level below StageTiers (+2), so pips sit under
    -- tier fills (not a bright overlay between stages). Spark stays on castBar above FluxBorder.
    local stagePipHolder = CreateFrame("Frame", nil, timerBar)
    stagePipHolder:SetAllPoints()
    stagePipHolder:EnableMouse(false)
    castBar.StagePipHolder = stagePipHolder

    -- Progress spark (pin): above FluxBorder atlas layer
    local sparkFrame = CreateFrame("Frame", nil, castBar)
    sparkFrame:SetPoint("TOPLEFT", timerBar, "TOPLEFT", 0, 0)
    sparkFrame:SetPoint("BOTTOMRIGHT", timerBar, "BOTTOMRIGHT", 0, 0)
    sparkFrame:EnableMouse(false)

    local spark = sparkFrame:CreateTexture(nil, "OVERLAY")
    local isPreDF = (FLUX_API and FLUX_API.isPreDF) or (FLUX_API and FLUX_API.majorVersion and FLUX_API.majorVersion < 10) or false
    if isLegacyClient or isPreDF then
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetBlendMode("ADD")
        spark:SetTexCoord(0, 1, 0, 1)
        spark:SetVertexColor(1, 1, 1, 1)
        local sparkSize = castBar:GetHeight() * 1.2
        spark:SetSize(sparkSize, sparkSize)
    else
        SetAtlasLegacy(spark, "ui-castingbar-pip")
        spark:SetVertexColor(1, 1, 1, 1)
        spark:SetSize(8, castBar:GetHeight() * 1.1)
    end
    spark:SetPoint("CENTER", sparkFrame, "LEFT", 0, 0)
    spark:Hide()
    castBar.Spark = spark
    castBar.SparkFrame = sparkFrame
    castBar.sparkEmpoweredOffset = 0
    SyncCastBarChromeFrameLevels(castBar)

    -- Event Handling
    -- Cast bar registers its own events for all units (player and target)
    -- Generic safe register function
    local function SafeRegister(event)
        local success = pcall(function() castBar:RegisterUnitEvent(event, unit) end)
        return success
    end

    local function RegisterUnitCastEvents()
        castBar._fluxPetCastDisabled = nil
        SafeRegister("UNIT_SPELLCAST_START")
        SafeRegister("UNIT_SPELLCAST_STOP")
        SafeRegister("UNIT_SPELLCAST_FAILED")
        SafeRegister("UNIT_SPELLCAST_INTERRUPTED")
        SafeRegister("UNIT_SPELLCAST_DELAYED")

        -- Channel events (Modern vs Legacy)
        local channelStartRegistered = SafeRegister("UNIT_SPELLCAST_CHANNEL_START")
        if not channelStartRegistered then
            SafeRegister("UNIT_CHANNEL_START")
        end

        local channelStopRegistered = SafeRegister("UNIT_SPELLCAST_CHANNEL_STOP")
        if not channelStopRegistered then
            SafeRegister("UNIT_CHANNEL_STOP")
        end

        local channelUpdateRegistered = SafeRegister("UNIT_SPELLCAST_CHANNEL_UPDATE")
        if not channelUpdateRegistered then
            SafeRegister("UNIT_CHANNEL_UPDATE")
        end

        SafeRegister("UNIT_SPELLCAST_EMPOWER_START")
        SafeRegister("UNIT_SPELLCAST_EMPOWER_STOP")
        SafeRegister("UNIT_SPELLCAST_EMPOWER_UPDATE")

        if unit == "player" then
            pcall(function() castBar:RegisterEvent("UNIT_SPELLCAST_SENT") end)
        end
    end

    castBar.RegisterPetCastEvents = RegisterUnitCastEvents
    castBar.DisablePetCastBar = function(self)
        self._fluxPetCastDisabled = true
        self:Hide()
        self:UnregisterAllEvents()
        self.casting = nil
        self.channeling = nil
        self.fadeOut = nil
    end

    RegisterUnitCastEvents()

    local deferUnitCastEvents = FluxCastBar_ShouldDeferUnitCastEvents(unit)

    local function handleCastBarUnitEvent(self, event, ...)
        if self._fluxPetCastDisabled then return end
        local unitID = ...
        if not EventUnitMatchesRegistered(unitID, unit) then return end

        -- Unpack arguments carefully. First arg is unitID.
        local arg1, arg2, arg3, arg4 = select(2, ...)

        local castGUID = arg1
        local spellID = arg2

        -- Helper boolean to identify if this is a channel event
        local isChannelEvent = (event == "UNIT_CHANNEL_START" or event == "UNIT_CHANNEL_STOP" or event == "UNIT_CHANNEL_UPDATE" or
                               event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" or
                               event == "UNIT_SPELLCAST_EMPOWER_START" or event == "UNIT_SPELLCAST_EMPOWER_STOP" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE")

        if isChannelEvent then
            -- UNIT_CHANNEL_* and UNIT_SPELLCAST_CHANNEL_* events: (unit, castGUID, spellID, ...)
            -- UNIT_SPELLCAST_EMPOWER_* events have different structure
            if event == "UNIT_SPELLCAST_EMPOWER_START" or event == "UNIT_SPELLCAST_EMPOWER_STOP" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
                -- Empowered events: (unit, castGUID, spellID, ...)
                castGUID = arg1
                spellID = arg2
            else
                -- Channel events: (unit, castGUID, spellID, ...)
                castGUID = arg1
                spellID = arg2
            end
        end

        if isChannelEvent then
            -- UNIT_CHANNEL_* and UNIT_SPELLCAST_EMPOWER_* events share the structure:
            -- (unit, castGUID, spellID, ...)

            -- Previously we assumed channels were (unit, spellID), but modern API uses castGUID as arg1.
            -- Using castGUID allows us to track channels uniquely too.
            castGUID = arg1
            spellID = arg2
        end

        -- Handle interruptions first and most aggressively
        if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
            if self.channeling then
                return
            end

            -- Verify this event matches our current cast
            if not SafeCompareGUID(self.castGUID, castGUID) then
                return
            end

            HandleInterrupt(self, event == "UNIT_SPELLCAST_FAILED", arg3)
            return
        end

        if event == "UNIT_SPELLCAST_START" then
            CastStart(self, unit, false, castGUID)
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            CastStart(self, unit, true, castGUID)
        elseif event == "UNIT_SPELLCAST_EMPOWER_START" then
             CastStart(self, unit, true, castGUID)
        elseif event == "UNIT_SPELLCAST_DELAYED" then
            -- Forever HandleCastDelayed: re-read UnitCastingInfo start/end.
            if self.casting and not self.isEmpowered then
                local _, _, _, startTime, endTime = ProbeUnitCastFields(unit, false)
                if not ApplyClientCastTiming(self, startTime, endTime, false) and self.SetTimerDuration then
                    local durationObj = ApplyCastBarTimerDuration(self, unit, false, false)
                    if durationObj then
                        self._fluxUsedTimerDuration = true
                        self._fluxClientCastTiming = nil
                        local total = TryGetDurationSeconds(durationObj)
                        if total then
                            self.maxValue = total
                        end
                    end
                end
            end
        elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
            -- UNIT_SPELLCAST_EMPOWER_STOP payload: unit, castGUID(arg1), spellID(arg2), success(arg3)
             local success = arg3

             -- RACE CONDITION FIX: Verify this event matches our current cast
             -- If we started a new cast immediately after interrupt, this STOP event from the OLD cast
             -- must be ignored, otherwise it will kill the new cast.
             if not SafeCompareGUID(self.castGUID, castGUID) then
                 return
             end

            -- Restore Interrupted State (User Request)
            -- Now safe to do because CastStart has a Full State Reset and Texture Clear.
            if SafeBooleanTest(success) == false then
                HandleInterrupt(self, false, arg4)
                return
            end

            -- Only call CastStop if not already interrupted
            if not self.interrupted then
                CastStop(self, false)
            end
             return

        elseif event == "UNIT_CHANNEL_UPDATE" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
             if self.isEmpowered or self.channeling then
                  local _, _, _, startTime, endTime, spellID = ProbeUnitCastFields(unit, true)
                  if ApplyClientCastTiming(self, startTime, endTime, not self.isEmpowered) then
                      -- Client start/end path refreshed.
                  elseif self.SetTimerDuration then
                      if self.isEmpowered then
                          local durationObj = GetUnitCastDurationObject(unit, false, true)
                          local total = TryGetDurationSeconds(durationObj)
                          if total then
                              self.maxValue = total
                          end
                      else
                          local durationObj = ApplyCastBarTimerDuration(self, unit, true, false)
                          if durationObj then
                              self._fluxUsedTimerDuration = true
                              self._fluxClientCastTiming = nil
                              local total = TryGetDurationSeconds(durationObj)
                              if total then
                                  self.maxValue = total
                              end
                          end
                      end
                  end
             end
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_CHANNEL_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            -- Forever HandleCastStop: STOP always completes; CHANNEL_STOP with interruptedBy kicks.
            if not isChannelEvent then
                if not SafeCompareGUID(self.castGUID or self.castID, castGUID) then
                    return
                end
            end

            if not self.beingInterrupted and not self.interrupted then
                local interruptedBy = arg3
                local kicked = false
                if self.channeling and isChannelEvent then
                    pcall(function()
                        kicked = interruptedBy ~= nil
                    end)
                end
                if kicked then
                    HandleInterrupt(self, false, interruptedBy)
                else
                    CastStop(self, false)
                end
            end
        elseif event == "UNIT_SPELLCAST_SENT" then
             local _, targetName = ...
             -- Only for player or vehicle
             if unit == "player" or unit == "vehicle" then
                 self.sentTarget = targetName
             end
        end
    end

    castBar:SetScript("OnEvent", function(self, event, ...)
        if deferUnitCastEvents then
            local nargs = select("#", ...)
            if nargs > 0 then
                local buf = {}
                for i = 1, nargs do
                    buf[i] = select(i, ...)
                end
                FluxCastBar_DeferEvent(function()
                    if not self:GetParent() then
                        return
                    end
                    handleCastBarUnitEvent(self, event, unpack(buf, 1, nargs))
                end)
            else
                FluxCastBar_DeferEvent(function()
                    if not self:GetParent() then
                        return
                    end
                    handleCastBarUnitEvent(self, event)
                end)
            end
            return
        end
        handleCastBarUnitEvent(self, event, ...)
    end)
    
    castBar:SetScript("OnUpdate", OnUpdate)

    -- Dynamic Layout Update function
    castBar.UpdateLayout = function()
        if not frame.atlasBorderFrame then return end
        
        -- Requirement: Match Old Code Logic
        -- Content Size = frame.outerBorderPadding + 4 (Compensate for 2px inset on both sides)
        -- Visual Size will be exactly outerBorderPadding (36px)
        local totalHeight = frame.outerBorderPadding + 4
        -- No shrinking for innerHeight. Content is full size.
        
        castBar:SetHeight(totalHeight)
        
        -- Requirement: Icon + Bar length = UF.CreateAtlasBorder(frame) combined width
        -- The atlasBorderFrame already covers unit frame + portrait + gaps.
        local totalWidth = frame.atlasBorderFrame:GetWidth()
        
        -- Icon is square, same size as Height
        local iconSize = totalHeight
        
        -- Bar Width = Total Width - Icon Size
        -- (Content widths. Borders will expand separately and overlap)
        local barWidth = totalWidth - iconSize
        
        castBar:SetWidth(barWidth)
        iconFrame:SetSize(iconSize, iconSize)

        -- Update shield overlay size to properly fit over the icon
        if castBar.ShieldOverlay then
            local shieldWidth = iconSize + 22 -- Make shield larger than icon like old implementation
            castBar.ShieldOverlay:SetSize(shieldWidth, shieldWidth * 1.78)
            castBar.ShieldOverlay:ClearAllPoints()
            castBar.ShieldOverlay:SetPoint("CENTER", castBar.Icon, "CENTER", SHIELD_OFFSET_X, SHIELD_OFFSET_Y)
        end

        if castBar.BorderFrame then
             -- No manual point clearing. FluxBorder manages it.
             -- FluxBorder.ApplyTo sets points relative to the frame.
        end
        
        if castBar.IconBorder then
             -- No manual point clearing.
        end

        -- Fill texture is StatusBar-owned (forever BarTexture atlas). Do not SetSize —
        -- that pins the filling atlas cap glow to the right end of the bar.

        -- Update background texture size
        if castBar.bg then
            castBar.bg:SetSize(barWidth - 4, totalHeight - 4)
        end

        if castBar.Spark then
            local isPreDF = (FLUX_API and FLUX_API.isPreDF) or (FLUX_API and FLUX_API.majorVersion and FLUX_API.majorVersion < 10) or false
            if isLegacyClient or isPreDF then
                local sparkSize = totalHeight * 1.2
                castBar.Spark:SetSize(sparkSize, sparkSize)
            else
                ConfigureCastBarSpark(castBar, SafeBooleanTest(castBar.isEmpowered))
            end
        end
        SyncCastBarChromeFrameLevels(castBar)

        -- Position logic based on outerBorderAlignment
        -- If "BOTTOM", Cast Bar ABOVE frame.
        -- If "TOP", Cast Bar BELOW frame.
        castBar:ClearAllPoints()
        iconFrame:ClearAllPoints()
        
        -- Anchor the BORDERS (which represent the outer bounds) to the Atlas Border
        -- Since we navigate by Inner Frames, we offset by the inset amount (2px)
        
        if frame.outerBorderAlignment == "BOTTOM" then
            -- Cast bar above frame
            -- Visual Bottom of Icon Border maps to Visual Top of Atlas Border
            -- Icon Border is at (IconFrame - 2px).
            -- So IconFrame Bottom is at (Atlas Top + 2px).
            iconFrame:SetPoint("BOTTOMLEFT", frame.atlasBorderFrame, "TOPLEFT", 0, -4) 
            castBar:SetPoint("LEFT", iconFrame, "RIGHT", 0, 0) -- Gap of 0 visual, but 2+2 gap between inner frames
        else
            -- Cast bar below frame
            -- Visual Top of Icon Border maps to Visual Bottom of Atlas Border
            -- IconFrame Top is at (Atlas Bottom - 2px)
            iconFrame:SetPoint("TOPLEFT", frame.atlasBorderFrame, "BOTTOMLEFT", 0, 4)
             castBar:SetPoint("LEFT", iconFrame, "RIGHT", 0, 0)
        end

        -- SPECIAL CASE: Pet Cast Bar (Layered OVER Resource Bar)
        if unit == "pet" then
            -- Hide Icon Frame for pet
            iconFrame:Hide()
            
            -- Match Power bar position and size
            if frame.Power then
                castBar:ClearAllPoints()
                castBar:SetAllPoints(frame.Power)
                castBar:SetFrameLevel(frame.Power:GetFrameLevel() + 5)
                
                -- Ensure trough matches new size; fill texture stays StatusBar-owned.
                local pWidth, pHeight = frame.Power:GetSize()
                if castBar.bg then
                    castBar.bg:SetSize(pWidth - 4, pHeight - 4)
                end
            end
        end

        if castBar.customTimer and castBar.customFromName then
            ApplyCustomTimerLabel(castBar)
        end
    end

    frame.CastBar = castBar
    
    -- Hook into frame update events if possible, or just call it initially
    -- Hook into frame update events (UpdatePartition handles resizing)
    if frame.UpdatePartition and not frame._fluxCastBarPartitionHooked then
        frame._fluxCastBarPartitionHooked = true
        hooksecurefunc(frame, "UpdatePartition", function()
            if frame.CastBar and frame.CastBar.UpdateLayout then
                frame.CastBar:UpdateLayout()
            end
        end)
    end
    
    -- Initial call
    castBar.UpdateLayout()

    if UF and UF.SyncBigDebuffsFrameLevelForUnitFrame then
        UF.SyncBigDebuffsFrameLevelForUnitFrame(frame)
        if not castBar._fluxBigDebuffsFrameLevelHook then
            castBar._fluxBigDebuffsFrameLevelHook = true
            hooksecurefunc(castBar, "UpdateLayout", function()
                UF.SyncBigDebuffsFrameLevelForUnitFrame(frame)
            end)
        end
    end

    -- Make CastStart available for manual calls (like when switching targets)
    castBar.CastStart = CastStart

    return castBar
end

-- Mute Blizzard unit/player cast bars on every client (Era, Anniversary, MoP Classic, Midnight).
-- All of those clients now use PlayerCastingBarFrame + CastingBarMixin. Classic TypeInfo keys
-- are secretwrap()'d; Midnight wraps barType via C_Secrets.ShouldUnitSpellCastingBeSecret.
-- Do not UnregisterAllEvents, SetParent, or replace mixin methods — that taints Overlay
-- professions/talent commit and Settings nameplate SimulateCast (CastingBarTypeInfo).
-- OverlayPlayerCastingBarFrame is left alone so those overlays still work.
local function WantFluxUnitForBlizzardCastMute(unit)
    if not FluxUnitFrames_ShouldUseFlux then
        return true
    end
    return FluxUnitFrames_ShouldUseFlux(unit) and true or false
end

-- HoldFadeOutAnim / FadeOutAnim use fromAlpha=1 (CastingBarFrameTemplates.xml).
-- On interrupt that forces the muted Blizzard UNITFRAME bar visible for ~1s.
local function StopMutedCastBarAnims(self)
    local function stop(anim)
        if anim and anim.Stop then
            pcall(anim.Stop, anim)
        end
    end
    stop(self.HoldFadeOutAnim)
    stop(self.FadeOutAnim)
    stop(self.InterruptShakeAnim)
    stop(self.InterruptGlowAnim)
    stop(self.InterruptSparkAnim)
    stop(self.FlashAnim)
    stop(self.FlashLoopingAnim)
    if self.StopInterruptAnims then
        pcall(self.StopInterruptAnims, self)
    end
end

local function ForceHideMutedBlizzardCastBar(self)
    if not self or not self._fluxMuteBlizzCast or self._fluxMuteBlizzCastApplying then
        return
    end
    -- Edit Mode's RefreshCastBar / OnEditModeExit fire these hooks inside its pass.
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(function()
            ForceHideMutedBlizzardCastBar(self)
        end, self)
        return
    end
    self._fluxMuteBlizzCastApplying = true
    -- Do not Hide(): PlayerFrame ApplySystemAnchor calls PlayerCastingBarFrame
    -- ApplySystemAnchor on spec/level; Hide/OnShow-Hide taints SetClampRectInsets.
    StopMutedCastBarAnims(self)
    if self.SetAlpha then
        pcall(self.SetAlpha, self, 0)
    end
    self._fluxMuteBlizzCastApplying = false
end

local function HookMutedAnimPlay(anim)
    if not anim or anim._fluxMutePlayHooked or type(anim.Play) ~= "function" then
        return
    end
    anim._fluxMutePlayHooked = true
    hooksecurefunc(anim, "Play", function(self)
        local parent = self.GetParent and self:GetParent()
        if parent and parent._fluxMuteBlizzCast then
            if not (FluxEditModeBusy and FluxEditModeBusy()) then
                pcall(self.Stop, self)
            end
            ForceHideMutedBlizzardCastBar(parent)
        end
    end)
end

local function InstallBlizzardCastBarMute(frame)
    if not frame or frame._fluxMuteBlizzCastHooked then
        return
    end
    if frame == _G.OverlayPlayerCastingBarFrame then
        return
    end
    frame._fluxMuteBlizzCastHooked = true
    if type(frame.UpdateShownState) == "function" then
        hooksecurefunc(frame, "UpdateShownState", ForceHideMutedBlizzardCastBar)
    end
    if type(frame.ApplyAlpha) == "function" then
        hooksecurefunc(frame, "ApplyAlpha", function(self)
            if self._fluxMuteBlizzCast then
                ForceHideMutedBlizzardCastBar(self)
            end
        end)
    end
    if type(frame.PlayInterruptAnims) == "function" then
        hooksecurefunc(frame, "PlayInterruptAnims", ForceHideMutedBlizzardCastBar)
    end
    if type(frame.PlayFadeAnim) == "function" then
        hooksecurefunc(frame, "PlayFadeAnim", ForceHideMutedBlizzardCastBar)
    end
    pcall(hooksecurefunc, frame, "SetAlpha", function(self, alpha)
        if self._fluxMuteBlizzCast and not self._fluxMuteBlizzCastApplying and alpha ~= 0 then
            ForceHideMutedBlizzardCastBar(self)
        end
    end)
    HookMutedAnimPlay(frame.HoldFadeOutAnim)
    HookMutedAnimPlay(frame.FadeOutAnim)
    HookMutedAnimPlay(frame.InterruptShakeAnim)
    HookMutedAnimPlay(frame.InterruptGlowAnim)
    HookMutedAnimPlay(frame.InterruptSparkAnim)
    if not frame._fluxMuteOnShowHooked then
        frame._fluxMuteOnShowHooked = true
        frame:HookScript("OnShow", ForceHideMutedBlizzardCastBar)
    end
end

local function SetBlizzardCastBarMuted(frame, muted)
    if not frame or frame == _G.OverlayPlayerCastingBarFrame then
        return
    end
    InstallBlizzardCastBarMute(frame)
    if muted then
        frame._fluxMuteBlizzCast = true
        ForceHideMutedBlizzardCastBar(frame)
        return
    end
    if frame._fluxMuteBlizzCast then
        frame._fluxMuteBlizzCast = nil
        if frame.SetAlpha then
            pcall(frame.SetAlpha, frame, 1)
        end
    end
end

local function HookBlizzardSpellbarCreate(unitFrame)
    if not unitFrame or unitFrame._fluxSpellbarCreateHooked then
        return
    end
    if type(unitFrame.CreateSpellbar) ~= "function" then
        return
    end
    unitFrame._fluxSpellbarCreateHooked = true
    hooksecurefunc(unitFrame, "CreateSpellbar", function()
        if CB.SyncBlizzardCastBars then
            CB.SyncBlizzardCastBars()
        end
    end)
end

local overlayEndHooked = false
local attachHooksInstalled = false

local function InstallBlizzardCastBarRestoreHooks()
    if not overlayEndHooked then
        local overlay = _G.OverlayPlayerCastingBarFrame
        if overlay and overlay.EndReplacingPlayerBar then
            overlayEndHooked = true
            hooksecurefunc(overlay, "EndReplacingPlayerBar", function()
                if CB.SyncBlizzardCastBars then
                    CB.SyncBlizzardCastBars()
                end
            end)
        end
    end
    if attachHooksInstalled then
        return
    end
    attachHooksInstalled = true
    if type(_G.PlayerFrame_DetachCastBar) == "function" then
        hooksecurefunc("PlayerFrame_DetachCastBar", function()
            if CB.SyncBlizzardCastBars then
                CB.SyncBlizzardCastBars()
            end
        end)
    end
    if type(_G.PlayerFrame_AttachCastBar) == "function" then
        hooksecurefunc("PlayerFrame_AttachCastBar", function()
            if CB.SyncBlizzardCastBars then
                CB.SyncBlizzardCastBars()
            end
        end)
    end
end

--- Hide Blizzard player/target/focus/pet cast bars while the matching Flux unit frame is on.
--- Visual mute only: events and mixin stay intact for Overlay + Settings preview.
function CB.SyncBlizzardCastBars()
    InstallBlizzardCastBarRestoreHooks()

    local mutePlayer = WantFluxUnitForBlizzardCastMute("player")
    SetBlizzardCastBarMuted(_G.PlayerCastingBarFrame, mutePlayer)
    SetBlizzardCastBarMuted(_G.CastingBarFrame, mutePlayer)

    -- Pet bar is parented to UIParent and sits on the player bar; mute with Flux player or pet.
    local mutePet = WantFluxUnitForBlizzardCastMute("pet") or mutePlayer
    SetBlizzardCastBarMuted(_G.PetCastingBarFrame, mutePet)

    local muteTarget = WantFluxUnitForBlizzardCastMute("target")
    local tf = _G.TargetFrame
    HookBlizzardSpellbarCreate(tf)
    if tf then
        SetBlizzardCastBarMuted(tf.spellbar, muteTarget)
        SetBlizzardCastBarMuted(tf.spellBar, muteTarget)
    end
    SetBlizzardCastBarMuted(_G.TargetFrameSpellBar, muteTarget)

    local muteFocus = WantFluxUnitForBlizzardCastMute("focus")
    local ff = _G.FocusFrame
    HookBlizzardSpellbarCreate(ff)
    if ff then
        SetBlizzardCastBarMuted(ff.spellbar, muteFocus)
        SetBlizzardCastBarMuted(ff.spellBar, muteFocus)
    end
    SetBlizzardCastBarMuted(_G.FocusFrameSpellBar, muteFocus)
end

--- Reapply player/pet cast bar Flux chrome when General → Appearance accent changes (target bar unchanged).
function FluxCastBar_ApplyAppearanceAccent()
    if ns.PlayerFrame and ns.PlayerFrame.CastBar then
        UpdateCastBarColor(ns.PlayerFrame.CastBar)
    end
    if ns.PetFrame and ns.PetFrame.CastBar then
        UpdateCastBarColor(ns.PetFrame.CastBar)
    end
end

-- Loader
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
pcall(loader.RegisterEvent, loader, "EDIT_MODE_LAYOUT_APPLIED")
loader:SetScript("OnEvent", function()
    -- Overlay can load after PLAYER_LOGIN; retry until hooked.
    FluxCastBar_BlockOverlayApplyingTalentsCastBar()
    CB.SyncBlizzardCastBars()
    -- Edit Mode / bottom-managed layout can re-show the default bar after this dispatch.
    if C_Timer and C_Timer.After then
        C_Timer.After(0, CB.SyncBlizzardCastBars)
        C_Timer.After(0.5, CB.SyncBlizzardCastBars)
    end
end)


