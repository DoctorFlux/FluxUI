-- FluxStatusBar.lua
-- Universal EXP/REP Status Bar for FluxUI
-- Works across all WoW client versions (Classic Era to Retail)
-- Uses FluxBorder for consistent styling with FluxMicroMenu

local addonName, addonTable = ...
local Flux = (addonTable and addonTable.Flux) or _G.Flux
local managedStartup = Flux and Flux.Module and Flux.Module.Register
local statusHUDReady = false
local nativeHidePending = false
local pendingStatusLayout = false
local InitializeStatusHUD

-------------------------------------------------------------------------------
-- CONSTANTS & CONFIG
-------------------------------------------------------------------------------

local DEFAULT_STATUS_BAR_HEIGHT = 18

local function GetStatusBarPixelHeight()
    local h = DEFAULT_STATUS_BAR_HEIGHT
    if FluxOptions and FluxOptions.GetStatusBarSettingsDB then
        local d = FluxOptions:GetStatusBarSettingsDB()
        if d and type(d.barHeight) == "number" and d.barHeight == d.barHeight then
            h = d.barHeight
        end
    end
    return math.max(10, math.min(40, h))
end

--- Gold/currency strip; exp/rep always use the same pixel height from options.
local function ShouldShowCurrencyBar()
    if FluxOptions and FluxOptions.GetStatusBarSettingsDB then
        local d = FluxOptions:GetStatusBarSettingsDB()
        if d and d.showCurrencyBar == false then
            return false
        end
    end
    return true
end

--- When true, omit the exp strip whenever ShouldShowExperienceBar() is false (max level / no XP bar).
local function ShouldHideExpBarWhenNoXP()
    if FluxOptions and FluxOptions.GetStatusBarSettingsDB then
        local d = FluxOptions:GetStatusBarSettingsDB()
        if d and d.hideExpBarAtMaxLevel then
            return true
        end
    end
    return false
end

local VERT_PADDING = 2   -- Vertical padding inside the container
local HORIZ_PADDING = 0  -- Horizontal padding (0 to remove side gaps)
local BAR_SPACING = 0    -- Space between EXP and REP bars (0 to force overlap/touch)
-- Colors (gold strip + max-level fallback). EXP/REP fills use HUD atlases or
-- Classic vertex colors below — never an always-purple EXP tint on HUD clients.
local EXP_COLOR = { r = 0.58, g = 0.0, b = 0.55, a = 1.0 }  -- Classic unrested
local RESTED_COLOR = { r = 0.0, g = 0.39, b = 0.88, a = 1.0 }  -- Classic rested (inn)
local MAX_LEVEL_COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 0.8 }  -- Gray
local GOLD_COLOR = { r = 0.85, g = 0.65, b = 0.0, a = 0.9 }
local BG_COLOR = { r = 0.1, g = 0.1, b = 0.1, a = 0.85 }

local STATUS_BAR_FILE = "Interface\\TargetingFrame\\UI-StatusBar"
local HUD_XP_FILL = "UI-HUD-ExperienceBar-Fill-Experience"
local HUD_XP_RESTED = "UI-HUD-ExperienceBar-Fill-Rested"
local HUD_XP_BG = "UI-HUD-ExperienceBar-Background"
local HUD_XP_PREDICTION = "UI-HUD-ExperienceBar-Fill-Prediction"
local HUD_XP_PIP = "UI-HUD-ExperienceBar-Frame-Pip"
local CLASSIC_XP_PIP = "Interface\\MainMenuBar\\UI-ExhaustionTickNormal"
local HUD_REP_BLUE = "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Blue"
local HUD_REP_ATLASES = {
    "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Red",
    "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Red",
    "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Orange",
    "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Yellow",
    "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Green",
    "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Green",
    "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Green",
    "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Green",
}
local CLASSIC_EXP_UNRESTED = EXP_COLOR
local CLASSIC_EXP_RESTED = RESTED_COLOR
local CLASSIC_REST_OVERLAY_ALPHA = 0.15
local HUD_XP_DIVIDER = "ui-hud-experiencebar-divider"
local CLASSIC_XP_DIVIDER_FILE = "Interface\\MainMenuBar\\UI-XP-Bar"
-- PetBattle / classic MainMenuExpBar tick slice on UI-XP-Bar.
local CLASSIC_XP_DIVIDER_LEFT = 0.01562500
local CLASSIC_XP_DIVIDER_RIGHT = 0.15625000
local CLASSIC_XP_DIVIDER_TOP = 0.01562500
local CLASSIC_XP_DIVIDER_BOTTOM = 0.17187500
local CLASSIC_XP_DIVIDER_R = 0.7450980392156863
local CLASSIC_XP_DIVIDER_G = 0.6352941176470588
local CLASSIC_XP_DIVIDER_B = 0.5176470588235294

-------------------------------------------------------------------------------
-- VERSION DETECTION (using FLUX_API if available)
-------------------------------------------------------------------------------

local isPreDF = false
local isLegacyClient = false
local majorVersion = 11

-- Use FLUX_API if available from FluxAPICompat.lua
if FLUX_API then
    isPreDF = FLUX_API.majorVersion and FLUX_API.majorVersion < 10
    isLegacyClient = FLUX_API.isLegacyClient or FLUX_API.isClassicEra or false
    majorVersion = FLUX_API.majorVersion or 11
else
    -- Fallback detection
    local version = GetBuildInfo and GetBuildInfo() or "11.0.0"
    local vMajor = tonumber(version:match("^(%d+)")) or 11
    majorVersion = vMajor
    isPreDF = vMajor < 10
    isLegacyClient = vMajor < 4
end

local function IsClassicClient()
    local client = Flux and Flux.Client
    if client and client.isAnyClassic then
        return true
    end
    if FLUX_API and FLUX_API.isAnyClassic then
        return true
    end
    return isLegacyClient
end

--- Forever opens Character Info only through a secure click. ToggleCharacter
--- from these bars runs CharacterFrame:OnShow as addon code (secret health
--- compare; protected gamepad bindings).
local function IsForeverClient()
    local client = Flux and Flux.Client
    if client then
        return client.isCamelot == true
    end
    return FLUX_API and FLUX_API.isCamelot == true or false
end

local function CanOpenCurrencyTab()
    return FLUX_API and FLUX_API.hasCharacterCurrencyTab and ToggleCharacter and not IsForeverClient()
end

local function HasHudExperienceAtlas()
    local cap = Flux and (Flux.Capabilities or Flux.Cap)
    if cap and cap.HasAtlas then
        return cap.HasAtlas(HUD_XP_FILL) and true or false
    end
    if type(FluxHasAtlas) == "function" then
        return FluxHasAtlas(HUD_XP_FILL) and true or false
    end
    if C_Texture and C_Texture.GetAtlasInfo then
        local ok, info = pcall(C_Texture.GetAtlasInfo, HUD_XP_FILL)
        return ok and info ~= nil
    end
    return false
end

-- Classic can ship DF HUD atlases for nameplates; native XP/rep bars stay vertex-colored.
local useHudStatusBarArt = (not IsClassicClient()) and HasHudExperienceAtlas()

local function ApplyStatusBarFill(bar, atlasName)
    if not bar or not bar.SetStatusBarTexture then
        return
    end
    local key = atlasName or STATUS_BAR_FILE
    if bar._fluxFillKey == key then
        return
    end
    local prev = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if prev and prev.SetTexture then
        pcall(prev.SetTexture, prev, nil)
    end
    if atlasName then
        local ok, success = pcall(bar.SetStatusBarTexture, bar, atlasName)
        if not ok or success == false then
            bar:SetStatusBarTexture(STATUS_BAR_FILE)
            bar._fluxFillKey = STATUS_BAR_FILE
        else
            bar._fluxFillKey = atlasName
        end
    else
        bar:SetStatusBarTexture(STATUS_BAR_FILE)
        bar._fluxFillKey = STATUS_BAR_FILE
    end
    local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if tex and tex.Show then
        tex:Show()
    end
end

local function ApplyBarBackground(tex)
    if not tex then
        return
    end
    if useHudStatusBarArt and tex.SetAtlas then
        local ok = pcall(tex.SetAtlas, tex, HUD_XP_BG, false)
        if ok then
            tex:SetAllPoints()
            tex:SetVertexColor(1, 1, 1, 1)
            return
        end
    end
    if tex.SetColorTexture then
        tex:SetColorTexture(0.0, 0.0, 0.0, 0.5)
    else
        tex:SetTexture(STATUS_BAR_FILE)
        tex:SetVertexColor(0.0, 0.0, 0.0, 0.5)
    end
    if tex.SetAllPoints then
        tex:SetAllPoints()
    end
end

local function ApplyExpBarFill(bar, isRested, colorOverride)
    if useHudStatusBarArt then
        ApplyStatusBarFill(bar, isRested and HUD_XP_RESTED or HUD_XP_FILL)
        if colorOverride then
            bar:SetStatusBarColor(colorOverride.r, colorOverride.g, colorOverride.b, colorOverride.a or 1)
        else
            bar:SetStatusBarColor(1, 1, 1, 1)
        end
        return
    end
    ApplyStatusBarFill(bar, nil)
    if colorOverride then
        bar:SetStatusBarColor(colorOverride.r, colorOverride.g, colorOverride.b, colorOverride.a or 1)
        return
    end
    local c = isRested and CLASSIC_EXP_RESTED or CLASSIC_EXP_UNRESTED
    bar:SetStatusBarColor(c.r, c.g, c.b, c.a)
end

local function ResolveRepHudAtlas(standing, useBlue, isFriendship)
    if useBlue then
        return HUD_REP_BLUE
    end
    local idx = isFriendship and 5 or standing
    if type(idx) ~= "number" then
        idx = 4
    end
    return HUD_REP_ATLASES[idx] or HUD_REP_ATLASES[4]
end

local function ApplyRepBarFill(bar, standing, useBlue, isFriendship, color)
    if useHudStatusBarArt then
        local atlas = ResolveRepHudAtlas(standing, useBlue, isFriendship)
        ApplyStatusBarFill(bar, atlas)
        bar:SetStatusBarColor(1, 1, 1, 1)
        return atlas
    end
    ApplyStatusBarFill(bar, nil)
    if color then
        bar:SetStatusBarColor(color.r, color.g, color.b, 1)
    else
        bar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
    end
    return "file"
end

-- Forever/Camelot: STATUS_BAR_NUM_SEGMENTS = 20 with ui-hud-experiencebar-divider.
-- Classic: 20 UI-XP-Bar ticks (MainMenuExpBar / OverrideActionBar).
-- Live StatusTrackingBar does not call UpdateDividers (STATUS_BAR_NUM_SEGMENTS = 1).
local function GetStatusBarSegmentCount()
    local client = Flux and Flux.Client
    if client then
        if client.isAnyClassic then
            return 20
        end
        if client.isCamelot or client.isForever then
            return 20
        end
        return 1
    end
    if IsClassicClient() then
        return 20
    end
    return 1
end

local function ShouldUseHudDividers()
    if not useHudStatusBarArt then
        return false
    end
    if GetStatusBarSegmentCount() <= 1 then
        return false
    end
    local cap = Flux and (Flux.Capabilities or Flux.Cap)
    if cap and cap.HasAtlas then
        return cap.HasAtlas(HUD_XP_DIVIDER) and true or false
    end
    return true
end

local function ApplyDividerArt(tex)
    if not tex then
        return
    end
    if ShouldUseHudDividers() and tex.SetAtlas then
        local ok = pcall(tex.SetAtlas, tex, HUD_XP_DIVIDER, false)
        if ok then
            tex:SetVertexColor(1, 1, 1, 1)
            return
        end
    end
    tex:SetTexture(CLASSIC_XP_DIVIDER_FILE)
    if tex.SetTexCoord then
        tex:SetTexCoord(CLASSIC_XP_DIVIDER_LEFT, CLASSIC_XP_DIVIDER_RIGHT, CLASSIC_XP_DIVIDER_TOP, CLASSIC_XP_DIVIDER_BOTTOM)
    end
    tex:SetVertexColor(CLASSIC_XP_DIVIDER_R, CLASSIC_XP_DIVIDER_G, CLASSIC_XP_DIVIDER_B, 1)
end

local function UpdateBarDividers(bar)
    if not bar or not bar._fluxSegmented then
        return
    end
    local n = GetStatusBarSegmentCount()
    local w = (bar.GetWidth and bar:GetWidth()) or 0
    local h = (bar.GetHeight and bar:GetHeight()) or 0
    local hud = ShouldUseHudDividers()
    local sig = string.format("%d:%.1f:%.1f:%s", n, w, h, hud and "h" or "c")
    if bar._fluxDivSig == sig then
        return
    end
    bar._fluxDivSig = sig

    local dividers = bar._fluxDividers
    if not dividers then
        dividers = {}
        bar._fluxDividers = dividers
    end

    if n <= 1 or w <= 0 or h <= 0 then
        for i = 1, #dividers do
            dividers[i]:Hide()
        end
        return
    end

    local count = n - 1
    local segmentWidth = w / n
    local divW = hud and 3 or 9
    local divH = math.max(4, h)
    for i = 1, count do
        local tex = dividers[i]
        if not tex then
            tex = bar:CreateTexture(nil, "OVERLAY", nil, 6)
            ApplyDividerArt(tex)
            dividers[i] = tex
        end
        tex:ClearAllPoints()
        tex:SetPoint("LEFT", bar, "LEFT", segmentWidth * i, 0)
        tex:SetSize(divW, divH)
        tex:Show()
    end
    for i = count + 1, #dividers do
        dividers[i]:Hide()
    end
end

-------------------------------------------------------------------------------
-- COMPATIBILITY HELPERS
-------------------------------------------------------------------------------

-- Safe C_Timer.After (polyfilled by FluxAPICompat)
local function SafeTimerAfter(delay, callback)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, callback)
    else
        -- Ultimate fallback using OnUpdate
        local frame = CreateFrame("Frame")
        local elapsed = 0
        frame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= delay then
                callback()
                self:SetScript("OnUpdate", nil)
                self:Hide()
            end
        end)
    end
end

-- Short number formatting (always abbreviated)
-- Short number formatting (always abbreviated)
local function FormatNumber(number)
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 10000 then
        return string.format("%.0fK", number / 1000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

local function FormatMoneyCompact(money)
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100

    local goldStr = ""
    local silverStr = ""
    local copperStr = ""
    
    local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
    local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
    local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"

    if gold > 0 then
        if gold >= 10000 then -- Shorten big gold numbers
             goldStr = FormatNumber(gold) .. GOLD_ICON
        else
             goldStr = BreakUpLargeNumbers(gold) .. GOLD_ICON
        end
    end

    -- If we have a lot of gold (> 5000g), hide silver/copper to reduce clutter
    if gold > 5000 then
        return goldStr
    end

    if silver > 0 or gold > 0 then
        silverStr = silver .. SILVER_ICON
    end
    
    -- Hide copper if we have any gold
    if gold == 0 and copper > 0 then
        copperStr = copper .. COPPER_ICON
    end
    
    return string.trim(goldStr .. " " .. silverStr .. " " .. copperStr)
end

local function FormatMoneyFull(money)
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100
    
    local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
    local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
    local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
    
    local str = ""
    if gold > 0 then str = str .. BreakUpLargeNumbers(gold) .. GOLD_ICON .. " " end
    if silver > 0 or gold > 0 then str = str .. silver .. SILVER_ICON .. " " end
    str = str .. copper .. COPPER_ICON
    
    return str
end

-- Get max level for current expansion
local function GetMaxLevel()
    if GetMaxLevelForPlayerExpansion then
        return GetMaxLevelForPlayerExpansion()
    elseif GetMaxPlayerLevel then
        return GetMaxPlayerLevel()
    elseif isLegacyClient then
        return 60  -- Classic Era
    else
        return 80  -- Safe fallback
    end
end

-- Check if player can gain XP
local function CanPlayerGainXP()
    local level = UnitLevel("player")
    local maxLevel = GetMaxLevel()
    
    if level >= maxLevel then
        return false
    end
    
    -- Check if XP is disabled (Retail feature)
    if IsXPUserDisabled and IsXPUserDisabled() then
        return false
    end
    
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    
    if not currentXP or not maxXP or maxXP <= 0 then
        return false
    end
    
    return true
end

-- Check if Blizzard UI would show the experience bar
-- Uses Blizzard's own logic to detect max level (handles pre-patches correctly)
local function ShouldShowExperienceBar()
    -- Modern Retail: Use GameRulesUtil.CanShowExperienceBar() if available
    -- This is what Blizzard uses to determine EXP bar visibility
    if GameRulesUtil and GameRulesUtil.CanShowExperienceBar then
        return GameRulesUtil.CanShowExperienceBar()
    end
    
    -- Fallback: Use IsPlayerAtEffectiveMaxLevel() if available
    -- This accounts for effective max level (pre-patches, etc.)
    if IsPlayerAtEffectiveMaxLevel then
        return not IsPlayerAtEffectiveMaxLevel()
    end
    
    -- Final fallback: Use existing CanPlayerGainXP() logic for very old clients
    return CanPlayerGainXP()
end

-- Compatible GetWatchedFactionInfo for all clients
-- Returns: name, standing, minRep, maxRep, value (same as legacy API)
local function GetWatchedFactionInfo_Compat()
    -- Modern Retail (TWW+): Use C_Reputation
    if C_Reputation and C_Reputation.GetWatchedFactionData then
        local data = C_Reputation.GetWatchedFactionData()
        if data then
            local name = data.name
            local standing = data.reaction or 4  -- Default to Neutral
            local minRep = data.currentReactionThreshold or 0
            local maxRep = data.nextReactionThreshold or 1
            local value = data.currentStanding or 0
            return name, standing, minRep, maxRep, value
        end
        return nil
    end
    
    -- Legacy clients: Use original GetWatchedFactionInfo
    if GetWatchedFactionInfo then
        return GetWatchedFactionInfo()
    end
    
    -- No faction tracking available
    return nil
end

--- Separator tint aligned with unit-frame HP/power chrome (FluxUnitFrames_Shared GetChromeSeparatorRGB for player).
local function GetStatusBarSeparatorTintRGB()
    if not FluxBorder or not FluxBorder.GetAccentMode then
        local classColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
        if classColor then
            return classColor.r, classColor.g, classColor.b
        end
        return 1, 1, 1
    end
    local mode = FluxBorder:GetAccentMode()
    if mode == "atlas" then
        return FluxBorder:GetThemedVertexRGB()
    end
    if mode == "custom" then
        return FluxBorder:GetThemedVertexRGB()
    end
    local _, c = UnitClass("player")
    local classColor = c and RAID_CLASS_COLORS[c]
    if classColor then
        return classColor.r, classColor.g, classColor.b
    end
    return 1, 1, 1
end

-------------------------------------------------------------------------------
-- FRAME CREATION
-------------------------------------------------------------------------------

local FluxStatusBarContainer = CreateFrame("Frame", "FluxStatusBarContainer", UIParent)
FluxStatusBarContainer:SetFrameStrata("BACKGROUND")  -- Lowered to be below addon popup (was LOW)
FluxStatusBarContainer:SetFrameLevel(1)  -- Lowered to be below addon popup

-- Container for Separators (High FrameLevel to ensure they stay on top of bars)
local FluxSeparatorContainer = CreateFrame("Frame", nil, FluxStatusBarContainer)
FluxSeparatorContainer:SetAllPoints()
FluxSeparatorContainer:SetFrameLevel(3) -- Lowered to be below addon popup (was 50)

-- Separator Pool
local Separators = {}
local function GetSeparator(index)
    if not Separators[index] then
        local sep = FluxSeparatorContainer:CreateTexture(nil, "OVERLAY")
        sep:SetHeight(16)
        Separators[index] = sep
    end
    return Separators[index]
end

--- Vertical separators between Gold | EXP | Rep (status bar location 2 only).
local ColSeparators = {}
local function GetColSeparator(index)
    if not ColSeparators[index] then
        local sep = FluxSeparatorContainer:CreateTexture(nil, "OVERLAY")
        ColSeparators[index] = sep
    end
    return ColSeparators[index]
end

--- Layout pos 2: gap between vertical micromenu and status strip left (px).
local STATUS_BAR_LOC2_MICRO_GAP = 4
--- Must match MicroMenu BESIDE_CHAT_LEFT_INSET when column-right is not stored yet.
local STATUS_BAR_LOC2_MICRO_LEFT_INSET = 2
--- Layout pos 2: gap between status strip right and Flux window / map left (px); smaller = strip extends farther right.
local STATUS_BAR_LOC2_WINDOW_GAP = 0
--- Alias for older references (must stay local; same value as WINDOW_GAP).
local STATUS_BAR_LOC2_MAP_GAP = STATUS_BAR_LOC2_WINDOW_GAP
local VERT_SEP_WIDTH = 2
--- Vertical column split (location 2): atlas width matches unit-frame CreateIconBorder.
local COL_SEP_ATLAS_WIDTH = 18

local location2MainBarHooksRegistered = false
local function EnsureStatusBarLocation2Hooks()
    local mb = _G.FluxActionStrip or _G.FluxMainActionBar
    if not location2MainBarHooksRegistered and mb and mb.HookScript then
        mb:HookScript("OnSizeChanged", function()
            if _G.FluxStatusBarUpdateLayout then
                _G.FluxStatusBarUpdateLayout()
            end
        end)
        mb:HookScript("OnShow", function()
            if _G.FluxStatusBarUpdateLayout then
                _G.FluxStatusBarUpdateLayout()
            end
        end)
        location2MainBarHooksRegistered = true
    end
    local bmf = _G.BattlefieldMapFrame
    if bmf and bmf.HookScript and not bmf.FluxStatusBarLoc2Sized then
        bmf.FluxStatusBarLoc2Sized = true
        bmf:HookScript("OnSizeChanged", function()
            if FluxOptions and FluxOptions.GetStatusBarPosition then
                local p = FluxOptions:GetStatusBarPosition()
                if (p == 2 or p == 3) and _G.FluxStatusBarUpdateLayout then
                    _G.FluxStatusBarUpdateLayout()
                end
            end
        end)
    end
    if FluxWindowFrame and FluxWindowFrame.GetFrame then
        local wf = FluxWindowFrame:GetFrame()
        if wf and wf.HookScript and not wf.FluxStatusBarLoc2Sized then
            wf.FluxStatusBarLoc2Sized = true
            wf:HookScript("OnSizeChanged", function()
                if FluxOptions and FluxOptions.GetStatusBarPosition then
                    local p = FluxOptions:GetStatusBarPosition()
                    if (p == 2 or p == 3) and _G.FluxStatusBarUpdateLayout then
                        _G.FluxStatusBarUpdateLayout()
                    end
                end
            end)
        end
    end
    local mm = _G.FluxMicroMenu
    if mm and mm.HookScript and not mm.FluxStatusBarLoc2Sized then
        mm.FluxStatusBarLoc2Sized = true
        mm:HookScript("OnSizeChanged", function()
            if FluxOptions and FluxOptions.GetStatusBarPosition then
                local p = FluxOptions:GetStatusBarPosition()
                if (p == 2 or p == 3) and _G.FluxStatusBarUpdateLayout then
                    _G.FluxStatusBarUpdateLayout()
                end
            end
        end)
    end
    if UIParent and UIParent.HookScript and not UIParent.FluxStatusBarStripUIParentSized then
        UIParent.FluxStatusBarStripUIParentSized = true
        UIParent:HookScript("OnSizeChanged", function()
            if FluxOptions and FluxOptions.GetStatusBarPosition then
                local p = FluxOptions:GetStatusBarPosition()
                if (p == 2 or p == 3) and _G.FluxStatusBarUpdateLayout then
                    _G.FluxStatusBarUpdateLayout()
                end
            end
        end)
    end
end

--- Micromenu vertical strip (layout position 2): strip starts STATUS_BAR_LOC2_MICRO_GAP px right of the menu column.
local function GetStatusBarLocation2LeftInsetFromMicroMenu()
    if not FluxOptions or not FluxOptions.GetMicroMenuLayoutPosition or FluxOptions:GetMicroMenuLayoutPosition() ~= 2 then
        return 0
    end
    if _G.FluxMicroMenu_GetBesideChatColumnRightX then
        local ok, right = pcall(_G.FluxMicroMenu_GetBesideChatColumnRightX)
        if ok and type(right) == "number" and right == right and right > 0 then
            return right + STATUS_BAR_LOC2_MICRO_GAP
        end
    end
    local mm = _G.FluxMicroMenu
    if not mm then
        return 0
    end
    local right = mm._besideChatColumnRightX
    if type(right) == "number" and right == right and right > 0 then
        return right + STATUS_BAR_LOC2_MICRO_GAP
    end
    local reserve = mm._besideChatReserveWidth
    if type(reserve) == "number" and reserve > 8 then
        return reserve + STATUS_BAR_LOC2_MICRO_GAP + STATUS_BAR_LOC2_MICRO_LEFT_INSET
    end
    if mm.GetWidth then
        local w = mm:GetWidth()
        if type(w) == "number" and w > 8 then
            return w + STATUS_BAR_LOC2_MICRO_GAP + STATUS_BAR_LOC2_MICRO_LEFT_INSET
        end
    end
    return 0
end

--- Width from the status bar's left edge to the left edge of FluxWindowFrame (preferred).
--- leftInset: distance from UIParent left to where the strip starts (micromenu column when layout position 2).
--- Map is inset inside the window; measuring the map made the strip stop short of the window chrome.
--- Falls back to battlefield map, then geometry from WINDOW_WIDTH, then a wide UIParent estimate.
local function GetStatusBarLocation2Width(leftInset)
    leftInset = (type(leftInset) == "number" and leftInset > 0) and leftInset or 0
    local uLeft = UIParent:GetLeft()
    if not uLeft then
        uLeft = 0
    end

    local function applyInset(spanFromULeft)
        if type(spanFromULeft) ~= "number" or spanFromULeft ~= spanFromULeft then
            return nil
        end
        return math.max(120, spanFromULeft - leftInset)
    end

    local windowFrame = FluxWindowFrame and FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame()
    if windowFrame and windowFrame.GetLeft then
        local wl = windowFrame:GetLeft()
        if type(wl) == "number" and wl == wl then
            local w = applyInset((wl - uLeft) - STATUS_BAR_LOC2_WINDOW_GAP)
            if w then
                return w
            end
        end
    end

    local mapFrame = FluxBattlefieldMap and FluxBattlefieldMap.GetMapFrame and FluxBattlefieldMap:GetMapFrame()
    if mapFrame and mapFrame.GetLeft and (not mapFrame.IsShown or mapFrame:IsShown()) then
        local ml = mapFrame:GetLeft()
        if type(ml) == "number" and ml == ml then
            local w = applyInset((ml - uLeft) - STATUS_BAR_LOC2_WINDOW_GAP)
            if w then
                return w
            end
        end
    end

    local uRight = UIParent:GetRight()
    local uw = UIParent:GetWidth()
    if not uRight and type(uw) == "number" and uw > 0 then
        uRight = uLeft + uw
    end
    local ww = FluxWindowFrame and FluxWindowFrame.WINDOW_WIDTH
    if type(uRight) == "number" and uRight == uRight and type(ww) == "number" and ww > 0 then
        local wl = uRight - ww
        local w = applyInset((wl - uLeft) - STATUS_BAR_LOC2_WINDOW_GAP)
        if w then
            return w
        end
    end

    if type(uw) == "number" and uw > 0 then
        local w = applyInset(uw - 40)
        if w then
            return w
        end
        return math.max(120, uw - 40 - leftInset)
    end
    return math.max(120, 400 - leftInset)
end

--- Forward declarations: bodies assigned later (UpdateLayoutLocation2 is defined before those locals otherwise Lua resolves globals = nil).
local UpdateFluxDurabilityFramePosition
local UpdateExpBar
local HideStatusStripWithNoContent
local EnsureDurabilityUsesStatusContainer
--- Durability widget anchors to the right of the leftmost visible strip (gold, or exp if gold is hidden).
local durabilityAnchorFrame

local INFO_CELL = {}

--- Integrated info cell is shown only when the panel is on the status row and has stats to draw.
local function StatusInfoCellActive()
    if not (FluxOptions and FluxOptions.GetInfoFramePlacement and FluxOptions:GetInfoFramePlacement() == "statusIntegrated") then
        return false
    end
    return FluxInfoFrame and FluxInfoFrame.HasVisibleLines and FluxInfoFrame.HasVisibleLines() and true or false
end

--- 1-based index among bars+info. start = before first, middle = after first, end = after last.
local function StatusInfoInsertIndex(numBars)
    local slot = "start"
    if FluxOptions and FluxOptions.GetInfoStatusSlot then
        slot = FluxOptions:GetInfoStatusSlot()
    end
    if numBars <= 0 or slot == "start" then
        return 1
    end
    if slot == "end" then
        return numBars + 1
    end
    return 2
end

local function BuildStatusBarCells(activeBars)
    local cells = {}
    for i = 1, #activeBars do
        cells[i] = activeBars[i]
    end
    if StatusInfoCellActive() then
        table.insert(cells, StatusInfoInsertIndex(#activeBars), INFO_CELL)
    end
    return cells
end

local function AnchorIntegratedInfoCell(infoFrame, x, y, w, h, fullWidth)
    if not infoFrame or not FluxInfoFrame or not FluxInfoFrame.SetAnchoredByStatusBarColumn then
        return
    end
    FluxInfoFrame.SetAnchoredByStatusBarColumn(true)
    if infoFrame.GetParent and infoFrame:GetParent() ~= UIParent then
        infoFrame:SetParent(UIParent)
    end
    infoFrame:ClearAllPoints()
    infoFrame:SetPoint("TOPLEFT", FluxStatusBarContainer, "TOPLEFT", x, y)
    if fullWidth then
        infoFrame:SetPoint("TOPRIGHT", FluxStatusBarContainer, "TOPRIGHT", -HORIZ_PADDING, y)
        infoFrame:SetHeight(h)
    else
        infoFrame:SetSize(w, h)
    end
    infoFrame:Show()
end

--- Location-2 vertical seam: same atlas as unit-frame icon edge (battlefieldminimap-border-left).
local function ApplyVerticalColSeparatorTexture(vsep)
    local barH = GetStatusBarPixelHeight()
    if FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases() then
        vsep:SetAtlas("battlefieldminimap-border-left", false)
        vsep:SetWidth(COL_SEP_ATLAS_WIDTH)
        vsep:SetHeight(barH)
    else
        vsep:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga")
        vsep:SetTexCoord(0.004, 0.066, 0.148, 0.672)
        vsep:SetWidth(COL_SEP_ATLAS_WIDTH)
        vsep:SetHeight(barH)
    end
end

--- Integrated Info uses a narrow worst-case column; remaining width goes to gold/XP/rep (no equal 1/n slice).
--- Returns infoColW, barColW, colW (equal fallback), narrowIntegrated (variable separator placement).
local function ComputeStatusRowColumnWidths(innerW, numBars, integratedInfoCol, nCells)
    local totalVertSep = math.max(0, nCells - 1) * VERT_SEP_WIDTH
    local narrowIntegrated = integratedInfoCol and FluxInfoFrame and type(FluxInfoFrame.GetStableIntegratedColumnWidth) == "function"

    if narrowIntegrated then
        local wantInfo = FluxInfoFrame:GetStableIntegratedColumnWidth()
        local minCell = 24
        local sepBudget = totalVertSep
        local maxInfoAllowed = math.max(minCell, innerW - sepBudget - numBars * minCell)
        local infoColW = math.min(math.max(wantInfo, minCell), maxInfoAllowed)
        local remForBars = innerW - infoColW - sepBudget
        local barColW = numBars > 0 and (remForBars / numBars) or 0
        if numBars > 0 and barColW < minCell then
            barColW = minCell
            infoColW = math.max(minCell, innerW - sepBudget - numBars * barColW)
        end
        return infoColW, barColW, barColW, true
    end

    local colW = (innerW - totalVertSep) / math.max(1, nCells)
    if colW < 24 then
        colW = 24
    end
    return colW, colW, colW, false
end

--- Horizontal status row (locations 2 and 3). Info is one column at the chosen slot, not always the first.
local function PlaceHorizontalStatusCells(activeBars, innerW, rowH)
    if StatusInfoCellActive() and FluxInfoFrame and FluxInfoFrame.GetStableIntegratedColumnWidth then
        FluxInfoFrame.GetStableIntegratedColumnWidth()
    end
    local cells = BuildStatusBarCells(activeBars)
    local nCells = #cells
    if nCells < 1 then
        return
    end
    local includeInfo = false
    for i = 1, nCells do
        if cells[i] == INFO_CELL then
            includeInfo = true
            break
        end
    end
    local numBars = #activeBars
    local infoColW, barColW, colW, narrowIntegrated = ComputeStatusRowColumnWidths(innerW, numBars, includeInfo, nCells)
    local widths = {}
    if includeInfo and narrowIntegrated then
        for i, cell in ipairs(cells) do
            widths[i] = (cell == INFO_CELL) and infoColW or barColW
        end
    else
        for i = 1, nCells do
            widths[i] = colW
        end
    end

    local sepR, sepG, sepB = GetStatusBarSeparatorTintRGB()
    for _, sep in pairs(ColSeparators) do
        sep:Hide()
    end

    local x = HORIZ_PADDING
    for i, cell in ipairs(cells) do
        local w = widths[i]
        if cell == INFO_CELL then
            local infoFrame = FluxInfoFrame and FluxInfoFrame.GetFrame and FluxInfoFrame:GetFrame()
            AnchorIntegratedInfoCell(infoFrame, x, -VERT_PADDING, w, rowH, false)
        else
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", FluxStatusBarContainer, "TOPLEFT", x, -VERT_PADDING)
            cell:SetSize(w, rowH)
            cell:Show()
        end
        if i < nCells then
            x = x + w + VERT_SEP_WIDTH
        end
    end

    local leftEdge = HORIZ_PADDING
    for k = 1, nCells - 1 do
        local vsep = GetColSeparator(k)
        local wThis = widths[k]
        local centerX = leftEdge + wThis + VERT_SEP_WIDTH / 2
        local centerY = -VERT_PADDING - (rowH / 2)
        vsep:Show()
        vsep:ClearAllPoints()
        ApplyVerticalColSeparatorTexture(vsep)
        vsep:SetVertexColor(sepR, sepG, sepB, 1)
        vsep:SetPoint("CENTER", FluxStatusBarContainer, "TOPLEFT", centerX, centerY)
        leftEdge = leftEdge + wThis + VERT_SEP_WIDTH
    end
end

local function UpdateLayoutLocation2(activeBars)
    EnsureStatusBarLocation2Hooks()

    if HideStatusStripWithNoContent(activeBars, 2) then
        return
    end
    EnsureDurabilityUsesStatusContainer()

    local barH = GetStatusBarPixelHeight()
    local rowH = barH
    local totalHeight = VERT_PADDING * 2 + rowH
    local leftInset = GetStatusBarLocation2LeftInsetFromMicroMenu()
    local menuWidth = GetStatusBarLocation2Width(leftInset)

    local mainBar = _G.FluxActionStrip or _G.FluxMainActionBar
    local y = 120
    if mainBar and mainBar.IsShown and mainBar:IsShown() and mainBar.GetTop and UIParent.GetBottom then
        local mt, ub = mainBar:GetTop(), UIParent:GetBottom()
        if type(mt) == "number" and type(ub) == "number" and mt == mt and ub == ub then
            y = mt - ub
        end
    else
        -- Gamepad HUD: status stays on the gamepad bar. The grid strip sits above it.
        local Cap = _G.Flux and _G.Flux.Cap
        local floor = Cap and Cap.GetGamepadActionBarFloor and Cap.GetGamepadActionBarFloor()
        if type(floor) == "number" and floor == floor and floor > 0 then
            y = floor
        end
    end

    FluxStatusBarContainer:ClearAllPoints()
    FluxStatusBarContainer:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", leftInset, y)
    FluxStatusBarContainer:SetSize(menuWidth, totalHeight)

    local innerW = math.max(0, menuWidth - (HORIZ_PADDING * 2))
    PlaceHorizontalStatusCells(activeBars, innerW, rowH)

    UpdateFluxDurabilityFramePosition()

    if FluxBorder then
        FluxBorder:ApplyTo(FluxStatusBarContainer)
        FluxBorder:SetClassColor(FluxStatusBarContainer)
        if FluxStatusBarContainer.FluxBorderFrame and FluxStatusBarContainer.FluxBorderFrame.Background then
            FluxStatusBarContainer.FluxBorderFrame.Background:SetAlpha(0)
        end
        if FluxStatusBarContainer.FluxBorderFrame then
            FluxStatusBarContainer.FluxBorderFrame:SetFrameStrata("BACKGROUND")
            FluxStatusBarContainer.FluxBorderFrame:SetFrameLevel(5)
        end
        if FluxStatusBarContainer.FluxBorderFrame and FluxStatusBarContainer.FluxBorderFrame.BackgroundFrame then
            FluxStatusBarContainer.FluxBorderFrame.BackgroundFrame:SetFrameStrata("BACKGROUND")
            FluxStatusBarContainer.FluxBorderFrame.BackgroundFrame:SetFrameLevel(0)
        end
    end

    UpdateExpBar()
    FluxStatusBarContainer:Show()
end

--- Layout position 3: full-width single row flush to screen bottom (same column math as location 2).
local function UpdateLayoutLocation3(activeBars)
    EnsureStatusBarLocation2Hooks()

    if HideStatusStripWithNoContent(activeBars, 3) then
        return
    end
    EnsureDurabilityUsesStatusContainer()

    local barH = GetStatusBarPixelHeight()
    local rowH = barH
    local totalHeight = VERT_PADDING * 2 + rowH
    local xInset = 0
    local uw = UIParent:GetWidth()
    if type(uw) ~= "number" or uw <= 0 then
        local ur, ul = UIParent:GetRight(), UIParent:GetLeft()
        if type(ur) == "number" and type(ul) == "number" and ur == ur and ul == ul then
            uw = ur - ul
        else
            uw = 1200
        end
    end
    local menuWidth = math.max(120, uw - xInset * 2)

    FluxStatusBarContainer:ClearAllPoints()
    FluxStatusBarContainer:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", xInset, 0)
    FluxStatusBarContainer:SetSize(menuWidth, totalHeight)

    local innerW = math.max(0, menuWidth - (HORIZ_PADDING * 2))
    PlaceHorizontalStatusCells(activeBars, innerW, rowH)

    UpdateFluxDurabilityFramePosition()

    if FluxBorder then
        FluxBorder:ApplyTo(FluxStatusBarContainer)
        FluxBorder:SetClassColor(FluxStatusBarContainer)
        if FluxStatusBarContainer.FluxBorderFrame and FluxStatusBarContainer.FluxBorderFrame.Background then
            FluxStatusBarContainer.FluxBorderFrame.Background:SetAlpha(0)
        end
        if FluxStatusBarContainer.FluxBorderFrame then
            FluxStatusBarContainer.FluxBorderFrame:SetFrameStrata("BACKGROUND")
            FluxStatusBarContainer.FluxBorderFrame:SetFrameLevel(5)
        end
        if FluxStatusBarContainer.FluxBorderFrame and FluxStatusBarContainer.FluxBorderFrame.BackgroundFrame then
            FluxStatusBarContainer.FluxBorderFrame.BackgroundFrame:SetFrameStrata("BACKGROUND")
            FluxStatusBarContainer.FluxBorderFrame.BackgroundFrame:SetFrameLevel(0)
        end
    end

    UpdateExpBar()
    FluxStatusBarContainer:Show()
end

-- Gold Bar (Top)
local GoldBar = CreateFrame("StatusBar", "FluxGoldBar", FluxStatusBarContainer)
GoldBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
GoldBar:SetMinMaxValues(0, 100)
GoldBar:SetValue(100)
GoldBar:SetFrameLevel(2)  -- Lowered to be below addon popup (was 15)

-- Gold Bar Background
GoldBar.bg = GoldBar:CreateTexture(nil, "BACKGROUND", nil, -1)
GoldBar.bg:SetAllPoints()
GoldBar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
GoldBar.bg:SetVertexColor(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, BG_COLOR.a)

--- Same status-bar texture and alpha. Only the tint follows General → Accent.
local function ApplyGoldBarBackgroundColor()
    if not (GoldBar and GoldBar.bg) then
        return
    end
    if FluxBorder and FluxBorder.IsUntintedAtlasAccent and FluxBorder:IsUntintedAtlasAccent() then
        GoldBar.bg:SetVertexColor(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, BG_COLOR.a)
    elseif FluxBorder and FluxBorder.GetThemedVertexRGB then
        local r, g, b = FluxBorder:GetThemedVertexRGB()
        GoldBar.bg:SetVertexColor(r, g, b, 0.8)
    else
        local _, classFilename = UnitClass("player")
        local classColor = classFilename and RAID_CLASS_COLORS[classFilename]
        if classColor then
            GoldBar.bg:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.8)
        else
            GoldBar.bg:SetVertexColor(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, BG_COLOR.a)
        end
    end
end

-- Gold Text (money only — tracked currencies / PvP in suffixText for layout + tooltips)
GoldBar.text = GoldBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
GoldBar.text:SetDrawLayer("OVERLAY", 7)
GoldBar.text:SetPoint("CENTER", GoldBar, "CENTER", 0, 0)
GoldBar.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
GoldBar.text:SetTextColor(1, 1, 1, 1)
GoldBar.suffixText = GoldBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
GoldBar.suffixText:SetDrawLayer("OVERLAY", 7)
GoldBar.suffixText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
GoldBar.suffixText:SetTextColor(1, 1, 1, 1)
GoldBar.suffixText:SetJustifyV("MIDDLE")
GoldBar.suffixText:Hide()
--- Hit frames: account gold only on money; strip help on the rest
local function GoldBarForwardEvent(ev, handlerSelf, a1, ...)
    local s = GoldBar and GoldBar.GetScript and GoldBar:GetScript(ev)
    if s then
        s(GoldBar, a1, ...)
    end
end
--- Same as suffix hit: show on the bar background, gaps, and non-coin areas (not on the money hit)
local function GoldBarShowCurrencyHelpTooltip()
    if not (GameTooltip and GameTooltip.SetOwner) then
        return
    end
    pcall(function()
        GameTooltip:Hide()
    end)
    pcall(function()
        GameTooltip:SetOwner(GoldBar, "ANCHOR_BOTTOM")
    end)
    if GameTooltip.SetText then
        GameTooltip:SetText("Currency", 1, 1, 1)
    end
    if not GameTooltip.AddLine then
        pcall(function()
            GameTooltip:Show()
        end)
        return
    end
    if CanOpenCurrencyTab() then
        GameTooltip:AddLine("Left-click: Character window — Currency tab.", 0.85, 0.88, 0.9, true)
        GameTooltip:AddLine("Right-click: FluxUI — Status Bars.", 0.7, 0.75, 0.8, true)
    else
        GameTooltip:AddLine("Left or right: FluxUI — Status Bars (no in-game currency tab on this client).", 0.8, 0.85, 0.9, true)
    end
    if FluxItemCurrencyTracking then
        GameTooltip:AddLine("Drop an item to add to item currency (or hover the icons to the right).", 0.65, 0.7, 0.75, true)
    end
    pcall(function()
        GameTooltip:Show()
    end)
end
do
    local h = CreateFrame("Button", "FluxGoldLedgerHit", GoldBar)
    h:EnableMouse(true)
    pcall(function()
        h:SetFrameStrata("MEDIUM")
    end)
    pcall(function()
        h:SetFrameLevel((GoldBar.GetFrameLevel and (GoldBar:GetFrameLevel() + 30)) or 32)
    end)
    pcall(function()
        h:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end)
    pcall(function()
        h:RegisterForDrag("LeftButton")
    end)
    h:SetScript("OnEnter", function(self)
        if _G.FluxGoldLedger and _G.FluxGoldLedger.ShowAccountGoldTooltip then
            pcall(function()
                _G.FluxGoldLedger:ShowAccountGoldTooltip(self)
            end)
        end
    end)
    h:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            pcall(function()
                GameTooltip:Hide()
            end)
        end
    end)
    h:SetScript("OnMouseUp", function(me, b)
        GoldBarForwardEvent("OnMouseUp", me, b)
    end)
    h:SetScript("OnReceiveDrag", function()
        GoldBarForwardEvent("OnReceiveDrag", h)
    end)
    h:Hide()
    GoldBar.ledgerHit = h
    local s = CreateFrame("Button", "FluxGoldStripSuffixHit", GoldBar)
    s:EnableMouse(true)
    pcall(function()
        s:SetFrameStrata("MEDIUM")
    end)
    pcall(function()
        s:SetFrameLevel((GoldBar.GetFrameLevel and (GoldBar:GetFrameLevel() + 30)) or 32)
    end)
    pcall(function()
        s:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end)
    pcall(function()
        s:RegisterForDrag("LeftButton")
    end)
    s:SetScript("OnEnter", function()
        GoldBarShowCurrencyHelpTooltip()
    end)
    s:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            pcall(function()
                GameTooltip:Hide()
            end)
        end
    end)
    s:SetScript("OnMouseUp", function(me, b)
        GoldBarForwardEvent("OnMouseUp", me, b)
    end)
    s:SetScript("OnReceiveDrag", function()
        GoldBarForwardEvent("OnReceiveDrag", s)
    end)
    s:Hide()
    GoldBar.suffixHit = s
end
local function PositionGoldBarRegionHits()
    if not (GoldBar and GoldBar.ledgerHit and GoldBar.suffixHit and GoldBar.text) then
        return
    end
    local h0 = 18
    pcall(function()
        if GoldBar.GetHeight then
            h0 = GoldBar:GetHeight() or 18
        end
    end)
    if type(h0) ~= "number" or h0 < 10 then
        h0 = 18
    end
    local t = GoldBar.text
    local st = GoldBar.suffixText
    if t and t.IsShown and t:GetText() and t:GetText() ~= "" and GoldBar.ledgerHit and GoldBar.ledgerHit.SetPoint then
        pcall(function()
            GoldBar.ledgerHit:ClearAllPoints()
            pcall(function()
                GoldBar.ledgerHit:SetAllPoints(t)
            end)
        end)
        pcall(function()
            GoldBar.ledgerHit:Show()
        end)
    else
        pcall(function()
            if GoldBar.ledgerHit and GoldBar.ledgerHit.Hide then
                GoldBar.ledgerHit:Hide()
            end
        end)
    end
    if st and st:IsShown() and st.GetStringWidth and st.GetText
        and st:GetText() and st:GetText() ~= "" then
        local wS = st:GetStringWidth() or 0
        pcall(function()
            GoldBar.suffixHit:ClearAllPoints()
            GoldBar.suffixHit:SetPoint("TOPLEFT", st, "TOPLEFT", -1, 0)
            if GoldBar.suffixHit.SetSize then
                GoldBar.suffixHit:SetSize(wS + 2, h0)
            end
        end)
        pcall(function()
            GoldBar.suffixHit:Show()
        end)
    else
        pcall(function()
            GoldBar.suffixHit:Hide()
        end)
    end
end


-- Experience Bar
local ExpBar = CreateFrame("StatusBar", "FluxExpBar", FluxStatusBarContainer)
ApplyExpBarFill(ExpBar, false)
ExpBar:SetMinMaxValues(0, 100)
ExpBar:SetValue(0)
ExpBar:SetFrameLevel(2)  -- Lowered to be below addon popup (was 14)

-- Experience Bar Background
ExpBar.bg = ExpBar:CreateTexture(nil, "BACKGROUND", nil, -1)
ApplyBarBackground(ExpBar.bg)

-- Rested XP Overlay (Blizzard underlay from left to current+rested)
ExpBar.rested = ExpBar:CreateTexture(nil, "BACKGROUND", nil, 0)
if useHudStatusBarArt and ExpBar.rested.SetAtlas then
    local ok = pcall(ExpBar.rested.SetAtlas, ExpBar.rested, HUD_XP_PREDICTION, false)
    if ok then
        ExpBar.rested:SetVertexColor(1, 1, 1, 1)
    else
        ExpBar.rested:SetTexture(STATUS_BAR_FILE)
    end
elseif ExpBar.rested.SetColorTexture then
    ExpBar.rested:SetColorTexture(1, 1, 1, 1)
else
    ExpBar.rested:SetTexture(STATUS_BAR_FILE)
end
ExpBar.rested:SetPoint("TOPLEFT", ExpBar, "TOPLEFT", 0, 0)
ExpBar.rested:SetPoint("BOTTOMLEFT", ExpBar, "BOTTOMLEFT", 0, 0)
ExpBar.rested:SetWidth(0)
ExpBar.rested:Hide()

-- Rested Pin
ExpBar.restedPin = ExpBar:CreateTexture(nil, "OVERLAY", nil, 3)
if useHudStatusBarArt and ExpBar.restedPin.SetAtlas then
    local ok = pcall(ExpBar.restedPin.SetAtlas, ExpBar.restedPin, HUD_XP_PIP, true)
    if not ok then
        ExpBar.restedPin:SetTexture(CLASSIC_XP_PIP)
        ExpBar.restedPin:SetSize(10, 14)
    else
        ExpBar.restedPin:SetSize(10, 14)
    end
else
    ExpBar.restedPin:SetTexture(CLASSIC_XP_PIP)
    ExpBar.restedPin:SetSize(32, 32)
end
ExpBar.restedPin:Hide()


-- Experience Text
ExpBar.text = ExpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ExpBar.text:SetDrawLayer("OVERLAY", 7)
ExpBar.text:SetPoint("CENTER", ExpBar, "CENTER", 0, 0)
ExpBar.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
ExpBar.text:SetTextColor(1, 1, 1, 1)
ExpBar._fluxSegmented = true
ExpBar:SetScript("OnSizeChanged", UpdateBarDividers)

-- Reputation Bar
local RepBar = CreateFrame("StatusBar", "FluxRepBar", FluxStatusBarContainer)
ApplyRepBarFill(RepBar, 4, false, false, nil)
RepBar:SetMinMaxValues(0, 100)
RepBar:SetValue(0)
RepBar:SetFrameLevel(2)  -- Lowered to be below addon popup (was 13)

-- Reputation Bar Background
RepBar.bg = RepBar:CreateTexture(nil, "BACKGROUND", nil, -1)
ApplyBarBackground(RepBar.bg)


-- Reputation Text
RepBar.text = RepBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
RepBar.text:SetDrawLayer("OVERLAY", 7)
RepBar.text:SetPoint("CENTER", RepBar, "CENTER", 0, 0)
RepBar.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
RepBar.text:SetTextColor(1, 1, 1, 1)
RepBar._fluxSegmented = true
RepBar:SetScript("OnSizeChanged", UpdateBarDividers)

-------------------------------------------------------------------------------
-- HIDE ORIGINAL BLIZZARD BARS
-------------------------------------------------------------------------------

local FluxHiddenParent = _G.FluxHiddenParent or CreateFrame("Frame", "FluxHiddenParent", UIParent)
FluxHiddenParent:Hide()

local function HideBlizzardBars()
    if not statusHUDReady then return end
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(HideBlizzardBars)
        return
    end
    if InCombatLockdown() then
        nativeHidePending = true
        return
    end
    nativeHidePending = false
    -- List of bar names across all client versions
    local barsToHide = {
        -- Pre-Dragonflight bars
        "MainMenuExpBar",
        "MainMenuBarExpBar", 
        "ExperienceBar",
        "PlayerXPBar",
        "ReputationWatchBar",
        "ReputationWatchStatusBar",
        "MainMenuBarReputationBar",
        -- Post-Dragonflight containers
        "MainStatusTrackingBarContainer",
        "SecondaryStatusTrackingBarContainer",
        "StatusTrackingBarManager",
    }
    
    for _, barName in ipairs(barsToHide) do
        local bar = _G[barName]
        if bar then
            if Flux and Flux.Blizz and Flux.Blizz.SetMouseSuppressed then
                Flux.Blizz.SetMouseSuppressed(bar, true)
            end
            -- Post-DF status tracking bars are Edit Mode systems. Hide/OnShow-Hide
            -- and SetParent(addon) taint UpdateLayoutInfo → MainActionBar:SetPointBase
            -- on spec/level. Mute with alpha only, same as leftover MainActionBar.
            local isEditModeStatus = barName == "MainStatusTrackingBarContainer"
                or barName == "SecondaryStatusTrackingBarContainer"
                or barName == "StatusTrackingBarManager"
            if isEditModeStatus then
                if FluxRemoveFrameFromEditMode then
                    FluxRemoveFrameFromEditMode(bar)
                end
                if bar.UnregisterAllEvents then
                    pcall(function() bar:UnregisterAllEvents() end)
                end
                if not InCombatLockdown() and bar.SetAlpha then
                    bar:SetAlpha(0)
                end
            else
                bar:SetParent(FluxHiddenParent)
                bar:Hide()
                bar:SetAlpha(0)
                if bar.EnableMouse then
                    pcall(function() bar:EnableMouse(false) end)
                end
                if bar.UnregisterAllEvents then
                    pcall(function() bar:UnregisterAllEvents() end)
                end
                if not bar.FluxHideHooked then
                    bar:HookScript("OnShow", function(self) if not InCombatLockdown() then self:Hide() end end)
                    bar.FluxHideHooked = true
                end
            end
        end
    end
    
    -- Park stock DurabilityFrame once OOC. It is a right-managed Edit Mode
    -- system: Hide() / OnShow-Hide / SetParent(addon) taint UpdateLayoutInfo →
    -- MainActionBar:SetPointBase on spec/level. Mute with alpha only.
    if DurabilityFrame then
        if Flux and Flux.Blizz and Flux.Blizz.SetMouseSuppressed then
            Flux.Blizz.SetMouseSuppressed(DurabilityFrame, true)
        end
        if not InCombatLockdown() and DurabilityFrame.SetAlpha then
            DurabilityFrame:SetAlpha(0)
        end
        if DurabilityFrame.UnregisterAllEvents then
            pcall(function() DurabilityFrame:UnregisterAllEvents() end)
        end
        if FluxRemoveFrameFromEditMode then
            FluxRemoveFrameFromEditMode(DurabilityFrame)
        end
    end
end

-------------------------------------------------------------------------------
-- UPDATE FUNCTIONS
-------------------------------------------------------------------------------

-- Flux idle FPS: composition key so fill/text-only XP/rep updates skip full UpdateLayout
-- + dependent fan-out. Layout only when gold/exp/rep visibility or status position changes.
local _lastCompositionKey = nil
_G.FluxPerfStatusBarLayoutRuns = _G.FluxPerfStatusBarLayoutRuns or 0
_G.FluxPerfStatusBarLayoutSkipped = _G.FluxPerfStatusBarLayoutSkipped or 0
_G.FluxPerfStatusBarGoldSkipped = _G.FluxPerfStatusBarGoldSkipped or 0
_G.FluxPerfStatusBarExpSkipped = _G.FluxPerfStatusBarExpSkipped or 0
_G.FluxPerfStatusBarRepSkipped = _G.FluxPerfStatusBarRepSkipped or 0

local function ComputeStatusBarCompositionKey()
    local statusPos = 1
    if FluxOptions and FluxOptions.GetStatusBarPosition then
        statusPos = FluxOptions:GetStatusBarPosition() or 1
    end
    local gold = ShouldShowCurrencyBar() and "1" or "0"
    local xpActive = ShouldShowExperienceBar()
    local showMaxLevelStyleBar = not xpActive and not ShouldHideExpBarWhenNoXP()
    local showExp = (xpActive or (showMaxLevelStyleBar and not RepBar.isTracking)) and "1" or "0"
    local rep = RepBar.isTracking and "1" or "0"
    return tostring(statusPos) .. ":" .. gold .. ":" .. showExp .. ":" .. rep
end

local function GetGoldItemTrackSignature()
    if not (FluxItemCurrencyTracking and FluxItemCurrencyTracking.EnsureItemCurrencyData) then
        return ""
    end
    local ic = FluxItemCurrencyTracking.EnsureItemCurrencyData()
    if not ic or not ic.enabled then
        return "off"
    end
    local sig = ""
    local slots = ic.slots
    if not slots then
        return "off"
    end
    for s = 1, #slots do
        local row = slots[s]
        local id = row and row.itemId or 0
        if type(id) == "number" and id > 0 then
            local c = 0
            local inv = _G.FluxInv
            if inv and inv.GetLiveCount then
                c = inv.GetLiveCount(id, { includeBank = false, charges = true, bags = true, equipped = true }) or 0
            elseif inv and inv.GetCount then
                c = inv.GetCount(id, {
                    bags = true,
                    bank = false,
                    warband = false,
                    equipped = true,
                    charges = true,
                }) or 0
            elseif _G.FluxGetItemCount then
                c = _G.FluxGetItemCount(id, { includeBank = false, charges = true }) or 0
            elseif GetItemCount then
                c = GetItemCount(id) or 0
            end
            sig = sig .. id .. "=" .. c .. ";"
        end
    end
    return sig
end

local _goldLastSig = nil
local _goldFillConfigured = false
local _expLastSig = nil
local _repLastSig = nil

local function UpdateGoldBar()
    -- Always, including when money/currency text is unchanged (accent option refresh).
    ApplyGoldBarBackgroundColor()

    local money = GetMoney()
    
    -- Check for tracked currencies
    local currencyText = ""
    
    -- Tracked currencies are displayed as text.
    -- This display has no currency progress bar.
    
    -- Retail API (Backpack specific tracking)
    if C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo then
        local i = 1
        while true do
            local info = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
            if not info then break end
            
            local iconStr = string.format("|T%s:0:0:2:0|t", info.iconFileID)
            currencyText = currencyText .. "   " .. FormatNumber(info.quantity) .. iconStr
            
            i = i + 1
        end
        
    -- Legacy API / Fallback
    elseif GetCurrencyListSize then
        local limit = GetCurrencyListSize()
        for i = 1, limit do
            local name, isHeader, isExpanded, isUnused, isWatched, count, icon, maximum = GetCurrencyListInfo(i)
            if not isHeader and isWatched then
                 local iconStr = string.format("|T%s:0:0:2:0|t", icon)
                 currencyText = currencyText .. "   " .. FormatNumber(count) .. iconStr
            end
        end
    end
    
    -- Add PVP tracking (Honor/Arena Points) if enabled
    if FluxPVPTracking and FluxPVPTracking.GetTrackedPVPText then
        local pvpText = FluxPVPTracking.GetTrackedPVPText()
        if pvpText and pvpText ~= "" then
            currencyText = currencyText .. pvpText
        end
    end
    -- Tracked item currency: drawn by LayoutGoldItemHovers (enables per-item tooltips, no inline |T| text)
    local itemSig = GetGoldItemTrackSignature()
    local barW = (GoldBar.GetWidth and GoldBar:GetWidth()) or 0
    local goldSig = tostring(money) .. "|" .. currencyText .. "|" .. itemSig .. "|" .. string.format("%.1f", barW)
    if goldSig == _goldLastSig then
        _G.FluxPerfStatusBarGoldSkipped = (_G.FluxPerfStatusBarGoldSkipped or 0) + 1
        return
    end
    _goldLastSig = goldSig
    
    -- DETERMINE MONEY FORMAT
    -- "if only gold is there show it not shorten if not needed"
    -- If no tracked currencies (currencyText is empty), use Full Format. else Compact.
    local text = ""
    if currencyText == "" then
        text = FormatMoneyFull(money)
    else
        text = FormatMoneyCompact(money)
    end
    
    GoldBar.text:SetText(text)
    if GoldBar.suffixText then
        if currencyText ~= "" then
            GoldBar.suffixText:SetText(currencyText)
            GoldBar.suffixText:Show()
        else
            GoldBar.suffixText:SetText("")
            GoldBar.suffixText:Hide()
        end
    end
    
    -- Foreground (Bar) = Invisible (No Yellow Bar) — once is enough
    if not _goldFillConfigured then
        GoldBar:SetStatusBarColor(0, 0, 0, 0)
        GoldBar:SetValue(0)
        _goldFillConfigured = true
    end
    if FluxItemCurrencyTracking and FluxItemCurrencyTracking.LayoutGoldItemHovers then
        local dropFn = _G.FluxStatusBarOnGoldItemDrop
        FluxItemCurrencyTracking.LayoutGoldItemHovers(GoldBar, type(dropFn) == "function" and dropFn or nil)
    elseif GoldBar.text then
        if GoldBar._fluxICHost and GoldBar._fluxICHost.Hide then
            GoldBar._fluxICHost:Hide()
        end
        if FluxItemCurrencyTracking and FluxItemCurrencyTracking.AnchorGoldBarTextBlock then
            FluxItemCurrencyTracking.AnchorGoldBarTextBlock(GoldBar, 0)
        else
            if GoldBar.suffixText
                and GoldBar.suffixText.GetText
                and GoldBar.suffixText:GetText() ~= "" then
                local a = (GoldBar.text and GoldBar.text.GetText and GoldBar.text:GetText()) or ""
                pcall(function()
                    GoldBar.text:SetText(a .. (GoldBar.suffixText:GetText() or ""))
                end)
                pcall(function()
                    GoldBar.suffixText:Hide()
                end)
            end
            GoldBar.text:ClearAllPoints()
            GoldBar.text:SetPoint("TOPLEFT", GoldBar, "TOPLEFT", 2, 0)
            GoldBar.text:SetPoint("BOTTOMRIGHT", GoldBar, "BOTTOMRIGHT", -2, 0)
            GoldBar.text:SetJustifyH("CENTER")
        end
    end
    if _G.FluxGoldLedger and _G.FluxGoldLedger.OnAfterGoldBarUpdate then
        pcall(function()
            _G.FluxGoldLedger:OnAfterGoldBarUpdate()
        end)
    end
    pcall(PositionGoldBarRegionHits)
end

-- Gold Bar Interaction: item drop = add to item currency. Left = game Currency tab when available, else
-- FluxUI Status Bars. Right = always FluxUI Status Bars (so config is reachable on clients with a game tab).
GoldBar:EnableMouse(true)
if not GoldBar._fluxICSizeHook then
    GoldBar._fluxICSizeHook = true
    GoldBar:SetScript("OnSizeChanged", function()
        if _G.UpdateGoldBar then
            pcall(_G.UpdateGoldBar)
        end
    end)
end
pcall(function()
    if GoldBar.RegisterForClicks then
        GoldBar:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end
end)
pcall(function()
    if GoldBar.RegisterForDrag then
        GoldBar:RegisterForDrag("LeftButton")
    end
end)

local function GoldBarHandleItemFromCursor()
    if not (FluxItemCurrencyTracking and FluxItemCurrencyTracking.GetItemIdFromCursor
        and FluxItemCurrencyTracking.AcceptItemDropOnCurrencyBar) then
        return false
    end
    local id = FluxItemCurrencyTracking.GetItemIdFromCursor()
    if not id or id < 1 then
        return false
    end
    if not FluxItemCurrencyTracking.AcceptItemDropOnCurrencyBar(id) then
        return false
    end
    if ClearCursor then
        ClearCursor()
    end
    return true
end

-- Used by FluxItemCurrencyTracking.LayoutGoldItemHovers for item button drag targets (set after this block loads)
_G.FluxStatusBarOnGoldItemDrop = GoldBarHandleItemFromCursor

GoldBar:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" or button == "LeftButtonUp" then
        if GetCursorInfo and select(1, GetCursorInfo()) == "item" then
            GoldBarHandleItemFromCursor()
            return
        end
        if CanOpenCurrencyTab() then
            pcall(ToggleCharacter, "TokenFrame")
        elseif FluxOptions and FluxOptions.OpenToStatusBarsTab then
            FluxOptions:OpenToStatusBarsTab()
        end
        return
    end
    if button == "RightButton" or button == "RightButtonUp" then
        if FluxOptions and FluxOptions.OpenToStatusBarsTab then
            FluxOptions:OpenToStatusBarsTab()
        end
    end
end)
GoldBar:SetScript("OnReceiveDrag", function()
    GoldBarHandleItemFromCursor()
end)
-- Bar padding and gaps. Do not clobber the coin (ledger) or suffix tooltips: those sit on top and
-- may share the same OnEnter pass with the parent in some UIs; skip help if mouse is on a child.
GoldBar:SetScript("OnEnter", function()
    -- Parent receives enter before/after child in some order; never show the padding "Currency" help
    -- when the cursor is actually over the coin text hit or the token suffix (gold tooltip is on the coin).
    local h0, s0 = GoldBar.ledgerHit, GoldBar.suffixHit
    local overH, overS = false, false
    if h0 and h0.IsMouseOver then
        local ok, v = pcall(h0.IsMouseOver, h0, 10, 10)
        if ok and v then
            overH = true
        else
            ok, v = pcall(h0.IsMouseOver, h0)
            overH = ok and v
        end
    end
    if s0 and s0.IsMouseOver then
        local ok, v = pcall(s0.IsMouseOver, s0, 6, 6)
        if ok and v then
            overS = true
        else
            ok, v = pcall(s0.IsMouseOver, s0)
            overS = ok and v
        end
    end
    if overH or overS then
        return
    end
    GoldBarShowCurrencyHelpTooltip()
end)
GoldBar:SetScript("OnLeave", function()
    pcall(function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)
end)

durabilityAnchorFrame = GoldBar

local function UpdateRestedUnderlay(currentXP, maxXP, restedXP, isRested)
    if not restedXP or restedXP <= 0 or not maxXP or maxXP <= 0 then
        ExpBar.rested:Hide()
        ExpBar.restedPin:Hide()
        return
    end
    local barWidth = ExpBar:GetWidth()
    if not barWidth or barWidth <= 0 then
        ExpBar.rested:Hide()
        ExpBar.restedPin:Hide()
        return
    end
    local widthRatio = math.max((currentXP + restedXP) / maxXP, 0)
    local exhaustionTickSet = math.max(0, math.min(widthRatio * barWidth, barWidth))
    ExpBar.rested:ClearAllPoints()
    ExpBar.rested:SetPoint("TOPLEFT", ExpBar, "TOPLEFT", 0, 0)
    ExpBar.rested:SetPoint("BOTTOMLEFT", ExpBar, "BOTTOMLEFT", 0, 0)
    ExpBar.rested:SetWidth(math.max(1, exhaustionTickSet))
    if ExpBar.rested.SetTexCoord then
        ExpBar.rested:SetTexCoord(0, math.min(widthRatio, 1), 0, 1)
    end
    if useHudStatusBarArt then
        ExpBar.rested:SetVertexColor(1, 1, 1, 1)
    else
        local c = isRested and CLASSIC_EXP_RESTED or CLASSIC_EXP_UNRESTED
        ExpBar.rested:SetVertexColor(c.r, c.g, c.b, CLASSIC_REST_OVERLAY_ALPHA)
    end
    ExpBar.rested:Show()

    local showPip = true
    if useHudStatusBarArt then
        showPip = widthRatio >= 0.01 and widthRatio <= 0.99
    end
    if showPip then
        ExpBar.restedPin:ClearAllPoints()
        ExpBar.restedPin:SetPoint("CENTER", ExpBar, "LEFT", exhaustionTickSet, 0)
        ExpBar.restedPin:Show()
    else
        ExpBar.restedPin:Hide()
    end
end

function UpdateExpBar()
    local shouldShow = ShouldShowExperienceBar()
    local barW = (ExpBar.GetWidth and ExpBar:GetWidth()) or 0
    local restState = (GetRestState and GetRestState()) or 0
    local isRested = restState == 1

    if not shouldShow and ShouldHideExpBarWhenNoXP() then
        local sig = "hidden"
        if _expLastSig == sig then
            _G.FluxPerfStatusBarExpSkipped = (_G.FluxPerfStatusBarExpSkipped or 0) + 1
            return
        end
        _expLastSig = sig
        ExpBar.rested:Hide()
        ExpBar.restedPin:Hide()
        return
    end

    if not shouldShow then
        -- Max level or XP disabled
        local sig = string.format("max:%d:%.1f", restState, barW)
        if _expLastSig == sig then
            _G.FluxPerfStatusBarExpSkipped = (_G.FluxPerfStatusBarExpSkipped or 0) + 1
            return
        end
        _expLastSig = sig
        ExpBar:SetMinMaxValues(0, 1)
        ExpBar:SetValue(1)
        ApplyExpBarFill(ExpBar, false, MAX_LEVEL_COLOR)
        ExpBar.text:SetText("Max Level")
        ExpBar.tooltipText = "You have reached the maximum level."
        ExpBar.rested:Hide()
        ExpBar.restedPin:Hide()
    else
        local currentXP = UnitXP("player") or 0
        local maxXP = UnitXPMax("player") or 0
        local restedXP = GetXPExhaustion() or 0

        -- Can happen briefly at login / during transitions; avoid 0/0 → NaN in text and layout
        if maxXP <= 0 then
            local sig = "pending"
            if _expLastSig == sig then
                _G.FluxPerfStatusBarExpSkipped = (_G.FluxPerfStatusBarExpSkipped or 0) + 1
                return
            end
            _expLastSig = sig
            ExpBar:SetMinMaxValues(0, 1)
            ExpBar:SetValue(0)
            ApplyExpBarFill(ExpBar, isRested)
            ExpBar.rested:Hide()
            ExpBar.restedPin:Hide()
            ExpBar.text:SetText("—")
            ExpBar.tooltipText = "Experience data is not available yet."
            return
        end

        local sig = string.format("xp:%d:%d:%d:%d:%.1f", currentXP, maxXP, restedXP, restState, barW)
        if _expLastSig == sig then
            _G.FluxPerfStatusBarExpSkipped = (_G.FluxPerfStatusBarExpSkipped or 0) + 1
            return
        end
        _expLastSig = sig

        ExpBar:SetMinMaxValues(0, maxXP)
        ExpBar:SetValue(currentXP)
        ApplyExpBarFill(ExpBar, isRested)
        UpdateRestedUnderlay(currentXP, maxXP, restedXP, isRested)

        -- Update text
        local percent = math.floor((currentXP / maxXP) * 100)
        local remaining = maxXP - currentXP
        ExpBar.text:SetText(string.format("%s / %s (%d%%)", FormatNumber(currentXP), FormatNumber(maxXP), percent))

        -- Tooltip
        local tooltipText = string.format("Experience: %s / %s (%d%%)\nRemaining: %s",
            FormatNumber(currentXP), FormatNumber(maxXP), percent, FormatNumber(remaining))
        if restedXP > 0 then
            tooltipText = tooltipText .. string.format("\n\nRested XP: %s\nYou will gain experience 200%% faster.", FormatNumber(restedXP))
        end
        ExpBar.tooltipText = tooltipText
    end
end

local function UpdateRepBar()
    local name, standing, minRep, maxRep, value = GetWatchedFactionInfo_Compat()
    
    if not name then
        local wasTracking = RepBar.isTracking
        if not (InCombatLockdown() and RepBar.IsProtected and RepBar:IsProtected()) then
            RepBar:Hide()
        else
            pendingStatusLayout = true
        end
        RepBar.isTracking = false
        if not wasTracking and _repLastSig == "none" then
            _G.FluxPerfStatusBarRepSkipped = (_G.FluxPerfStatusBarRepSkipped or 0) + 1
            return
        end
        _repLastSig = "none"
        return
    end
    
    if not (InCombatLockdown() and RepBar.IsProtected and RepBar:IsProtected()) then
        RepBar:Show()
    else
        pendingStatusLayout = true
    end
    RepBar.isTracking = true
    
    local current = value - minRep
    local total = maxRep - minRep
    local percent = 0
    if total > 0 then
        percent = math.floor((current / total) * 100)
    end
    
    -- Determine color and label based on reputation type
    local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[standing]
    local standingText = _G["FACTION_STANDING_LABEL" .. standing] or "Unfriendly"
    local isRenown = false
    local isFriendship = false
    
    -- Check for C_Reputation data if available (Retail/TWW)
    if C_Reputation and C_Reputation.GetWatchedFactionData then
        local data = C_Reputation.GetWatchedFactionData()
        if data then
            local factionID = data.factionID
            
            if data.isRenown or (factionID and C_Reputation.IsMajorFaction(factionID)) then
                isRenown = true
                -- Use C_MajorFactions for accurate Renown data
                if factionID and C_MajorFactions and C_MajorFactions.GetMajorFactionData then
                    local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID)
                    if majorFactionData then
                        current = majorFactionData.renownReputationEarned or 0
                        total = majorFactionData.renownLevelThreshold or 0
                        standingText = "Renown " .. (majorFactionData.renownLevel or 0)
                        if total > 0 then
                            percent = math.floor((current / total) * 100)
                        end
                    end
                else
                    -- Fallback for Renown if C_MajorFactions fails (rare)
                    standingText = "Renown " .. (data.reaction or data.currentRenown or 0)
                    if data.currentRenownXP and data.currentRenownMaxXP and data.currentRenownMaxXP > 0 then
                        current = data.currentRenownXP
                        total = data.currentRenownMaxXP
                        percent = math.floor((current / total) * 100)
                    end
                end
            elseif data.isFriendship then
                isFriendship = true
                if data.reaction then
                     standingText = data.reaction
                end
                if data.nextReactionThreshold and data.nextReactionThreshold > 0 then
                     current = math.max(0, current)
                end
            end
            if factionID and C_Reputation.IsFactionParagonForCurrentPlayer
                and C_Reputation.IsMajorFaction
                and C_Reputation.IsFactionParagonForCurrentPlayer(factionID)
                and C_Reputation.IsMajorFaction(factionID) then
                isRenown = true
            end
        end
    end

    -- Safety clamp for all bars
    current = math.max(0, current)

    local fillKey
    if useHudStatusBarArt then
        fillKey = ResolveRepHudAtlas(standing, isRenown, isFriendship)
    else
        local colorR = color and color.r or 0.5
        local colorG = color and color.g or 0.5
        local colorB = color and color.b or 0.5
        fillKey = string.format("%.2f:%.2f:%.2f", colorR, colorG, colorB)
    end
    local repSig = string.format("%s:%s:%d:%d:%d:%s",
        name, standingText, current, total, percent, fillKey)
    if repSig == _repLastSig then
        _G.FluxPerfStatusBarRepSkipped = (_G.FluxPerfStatusBarRepSkipped or 0) + 1
        return
    end
    _repLastSig = repSig

    RepBar:SetMinMaxValues(0, total)
    RepBar:SetValue(current)
    ApplyRepBarFill(RepBar, standing, isRenown, isFriendship, color)
    RepBar.text:SetText(string.format("%s: %s / %s (%d%%)", name, FormatNumber(current), FormatNumber(total), percent))
    
    -- Tooltip
    local remaining = total - current
    local tooltipText = string.format("%s\n%s\n%s / %s (%d%%)", name, standingText, FormatNumber(current), FormatNumber(total), percent)
    
    if isRenown then
         tooltipText = tooltipText .. "\n(Renown Faction)"
    elseif remaining > 0 and standing < 8 then
        -- Standard faction progression hint
        local nextStanding = _G["FACTION_STANDING_LABEL" .. (standing + 1)] or "Next Level"
        tooltipText = tooltipText .. string.format("\n\nTo %s: %s", nextStanding, FormatNumber(remaining))
    end
    
    RepBar.tooltipText = tooltipText
end

-------------------------------------------------------------------------------
-- LAYOUT & SIZING
-------------------------------------------------------------------------------

-- Layout Helpers
local function GetBorderInset()
    -- Different insets based on border type
    return FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases() and 4 or 2
end

-------------------------------------------------------------------------------
-- DURABILITY FRAME CONSTANTS
-------------------------------------------------------------------------------

-- Define constants if not already global
if not INVENTORY_ALERT_STATUS_SLOTS then
    INVENTORY_ALERT_STATUS_SLOTS = {}
    INVENTORY_ALERT_STATUS_SLOTS[1] = {slot = "Head"}
    INVENTORY_ALERT_STATUS_SLOTS[2] = {slot = "Shoulders"}
    INVENTORY_ALERT_STATUS_SLOTS[3] = {slot = "Chest"}
    INVENTORY_ALERT_STATUS_SLOTS[4] = {slot = "Waist"}
    INVENTORY_ALERT_STATUS_SLOTS[5] = {slot = "Legs"}
    INVENTORY_ALERT_STATUS_SLOTS[6] = {slot = "Feet"}
    INVENTORY_ALERT_STATUS_SLOTS[7] = {slot = "Wrists"}
    INVENTORY_ALERT_STATUS_SLOTS[8] = {slot = "Hands"}
    INVENTORY_ALERT_STATUS_SLOTS[9] = {slot = "Weapon", showSeparate = 1}
    INVENTORY_ALERT_STATUS_SLOTS[10] = {slot = "Shield", showSeparate = 1}
    INVENTORY_ALERT_STATUS_SLOTS[11] = {slot = "Ranged", showSeparate = 1}
end

if not INVENTORY_ALERT_COLORS then
    INVENTORY_ALERT_COLORS = {}
    INVENTORY_ALERT_COLORS[1] = {r = 1, g = 0.82, b = 0.18}  -- Yellow (breaking)
    INVENTORY_ALERT_COLORS[2] = {r = 0.93, g = 0.07, b = 0.07}  -- Red (broken)
end

-------------------------------------------------------------------------------
-- CUSTOM DURABILITY FRAME
-------------------------------------------------------------------------------

local FluxDurabilityFrame = nil
local FluxDurabilityTextures = {}
local DURABILITY_TOPLEFT_X = 8
local DURABILITY_TOPLEFT_Y = -120
local DURABILITY_TOPLEFT_PVP_GAP = -6

-- Create custom DurabilityFrame
local function CreateFluxDurabilityFrame()
    if FluxDurabilityFrame then return end
    
    -- Create main frame
    -- UIParent, not the status strip. A hidden or relocated strip (every micro
    -- menu and status position) would hide a child frame with it.
    FluxDurabilityFrame = CreateFrame("Frame", "FluxDurabilityFrame", UIParent)
    FluxDurabilityFrame:SetSize(60, 75)
    FluxDurabilityFrame:SetFrameStrata("HIGH")
    FluxDurabilityFrame:SetFrameLevel(20)
    FluxDurabilityFrame:EnableMouse(true)
    FluxDurabilityFrame:Hide() -- Start hidden, will show when alerts are present
    
    -- Initialize state
    FluxDurabilityFrame.anyItemBroken = false
    FluxDurabilityFrame.anyItemBreaking = false
    FluxDurabilityFrame.shouldShow = false
    
    -- Create all texture elements (order matters for positioning)
    local createOrder = {"Head", "Shoulders", "Chest", "Wrists", "Hands", "Waist", "Legs", "Feet", "Weapon", "Shield", "OffWeapon", "Ranged"}
    
    local textureData = {
        Head = {size = {18, 22}, coords = {0, 0.140625, 0, 0.171875}},
        Shoulders = {size = {48, 22}, coords = {0.140625, 0.515625, 0, 0.171875}},
        Chest = {size = {20, 22}, coords = {0.515625, 0.6640625, 0, 0.171875}},
        Wrists = {size = {44, 22}, coords = {0.6640625, 1.0, 0, 0.171875}},
        Hands = {size = {42, 18}, coords = {0, 0.328125, 0.171875, 0.3046875}},
        Waist = {size = {16, 5}, coords = {0.328125, 0.46875, 0.171875, 0.203125}},
        Legs = {size = {29, 20}, coords = {0.46875, 0.6875, 0.171875, 0.3203125}},
        Feet = {size = {41, 32}, coords = {0.6875, 1.0, 0.171875, 0.4140625}},
        Weapon = {size = {20, 45}, coords = {0, 0.140625, 0.3203125, 0.6640625}},
        Shield = {size = {25, 31}, coords = {0.1875, 0.375, 0.3203125, 0.5546875}},
        OffWeapon = {size = {20, 45}, coords = {0, 0.140625, 0.3203125, 0.6640625}},
        Ranged = {size = {28, 38}, coords = {0.1875, 0.3984375, 0.5546875, 0.84375}},
    }
    
    -- Create textures in order
    for _, name in ipairs(createOrder) do
        local data = textureData[name]
        if data then
            local texture = FluxDurabilityFrame:CreateTexture("FluxDurability" .. name, "BACKGROUND")
            texture:SetTexture("Interface\\Durability\\UI-Durability-Icons")
            texture:SetSize(data.size[1], data.size[2])
            texture:SetTexCoord(data.coords[1], data.coords[2], data.coords[3], data.coords[4])
            
            FluxDurabilityTextures[name] = texture
            _G["FluxDurability" .. name] = texture
        end
    end
    
    -- Position textures (must be done after all are created)
    if FluxDurabilityTextures.Head then
        FluxDurabilityTextures.Head:SetPoint("TOPRIGHT")
    end
    if FluxDurabilityTextures.Shoulders and FluxDurabilityTextures.Head then
        FluxDurabilityTextures.Shoulders:SetPoint("TOP", FluxDurabilityTextures.Head, "BOTTOM", 0, 16)
    end
    if FluxDurabilityTextures.Chest and FluxDurabilityTextures.Shoulders then
        FluxDurabilityTextures.Chest:SetPoint("TOP", FluxDurabilityTextures.Shoulders, "TOP", 0, -7)
    end
    if FluxDurabilityTextures.Wrists and FluxDurabilityTextures.Shoulders then
        FluxDurabilityTextures.Wrists:SetPoint("TOP", FluxDurabilityTextures.Shoulders, "BOTTOM", 0, 7)
    end
    if FluxDurabilityTextures.Hands and FluxDurabilityTextures.Wrists then
        FluxDurabilityTextures.Hands:SetPoint("TOP", FluxDurabilityTextures.Wrists, "BOTTOM", 0, 15)
    end
    if FluxDurabilityTextures.Waist and FluxDurabilityTextures.Chest then
        FluxDurabilityTextures.Waist:SetPoint("TOP", FluxDurabilityTextures.Chest, "BOTTOM", 0, 6)
    end
    if FluxDurabilityTextures.Legs and FluxDurabilityTextures.Waist then
        FluxDurabilityTextures.Legs:SetPoint("TOP", FluxDurabilityTextures.Waist, "BOTTOM", 0, 2)
    end
    if FluxDurabilityTextures.Feet and FluxDurabilityTextures.Legs then
        FluxDurabilityTextures.Feet:SetPoint("TOP", FluxDurabilityTextures.Legs, "BOTTOM", 0, 8)
    end
    if FluxDurabilityTextures.Weapon and FluxDurabilityTextures.Wrists then
        FluxDurabilityTextures.Weapon:SetPoint("RIGHT", FluxDurabilityTextures.Wrists, "LEFT", 0, -6)
    end
    if FluxDurabilityTextures.Shield and FluxDurabilityTextures.Wrists then
        FluxDurabilityTextures.Shield:SetPoint("LEFT", FluxDurabilityTextures.Wrists, "RIGHT", 0, 10)
    end
    if FluxDurabilityTextures.OffWeapon and FluxDurabilityTextures.Wrists then
        FluxDurabilityTextures.OffWeapon:SetPoint("LEFT", FluxDurabilityTextures.Wrists, "RIGHT", 0, -6)
        FluxDurabilityTextures.OffWeapon:Hide()
    end
    if FluxDurabilityTextures.Ranged and FluxDurabilityTextures.Shield then
        FluxDurabilityTextures.Ranged:SetPoint("TOP", FluxDurabilityTextures.Shield, "BOTTOM", 0, 5)
    end
    
    -- Tooltip handlers
    FluxDurabilityFrame:SetScript("OnEnter", function(self)
        if self.anyItemBroken or self.anyItemBreaking then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
            local wrap = true
            if GameTooltip_SetTitle then
                GameTooltip_SetTitle(GameTooltip, REPAIR_ARMOR_TOOLTIP_TITLE or "Repair Armor", HIGHLIGHT_FONT_COLOR or {r=1, g=1, b=1}, wrap)
            else
                GameTooltip:SetText(REPAIR_ARMOR_TOOLTIP_TITLE or "Repair Armor")
            end
            if self.anyItemBroken then
                if GameTooltip_AddNormalLine then
                    GameTooltip_AddNormalLine(GameTooltip, REPAIR_ARMOR_TOOLTIP_BROKEN or "Some of your armor is broken and needs repair.", wrap)
                else
                    GameTooltip:AddLine(REPAIR_ARMOR_TOOLTIP_BROKEN or "Some of your armor is broken and needs repair.")
                end
            else
                if GameTooltip_AddNormalLine then
                    GameTooltip_AddNormalLine(GameTooltip, REPAIR_ARMOR_TOOLTIP_BREAKING or "Some of your armor is damaged and needs repair.", wrap)
                else
                    GameTooltip:AddLine(REPAIR_ARMOR_TOOLTIP_BREAKING or "Some of your armor is damaged and needs repair.")
                end
            end
            GameTooltip:Show()
        end
    end)
    
    FluxDurabilityFrame:SetScript("OnLeave", function(self)
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)
    
    -- Remove from Edit Mode if Edit Mode exists
    if FluxRemoveFrameFromEditMode then
        FluxRemoveFrameFromEditMode(FluxDurabilityFrame)
    end
end

-- Update durability alerts
local function FluxDurabilityFrame_SetAlerts()
    if not FluxDurabilityFrame then return end
    
    -- Check if repair is disabled
    if C_GameRules and C_GameRules.IsGameRuleActive and Enum.GameRule and Enum.GameRule.RepairArmorDisabled and C_GameRules.IsGameRuleActive(Enum.GameRule.RepairArmorDisabled) then
        FluxDurabilityFrame:Hide()
        return
    end
    
    local numAlerts = 0
    local texture, color, showDurability
    local hasLeft, hasRight
    FluxDurabilityFrame.anyItemBroken = false
    
    for index, value in pairs(INVENTORY_ALERT_STATUS_SLOTS) do
        texture = FluxDurabilityTextures[value.slot]
        
        -- Handle Shield vs Offhand Weapon
        if value.slot == "Shield" then
            if C_PaperDollInfo and C_PaperDollInfo.OffhandHasWeapon and C_PaperDollInfo.OffhandHasWeapon() then
                if FluxDurabilityTextures.Shield then
                    FluxDurabilityTextures.Shield:Hide()
                end
                texture = FluxDurabilityTextures.OffWeapon
            else
                if FluxDurabilityTextures.OffWeapon then
                    FluxDurabilityTextures.OffWeapon:Hide()
                end
                texture = FluxDurabilityTextures.Shield
            end
        end
        
        if texture and GetInventoryAlertStatus then
            local alertStatus = GetInventoryAlertStatus(index)
            color = INVENTORY_ALERT_COLORS[alertStatus]
            
            if color then
                texture:SetVertexColor(color.r, color.g, color.b, 1.0)
                if value.showSeparate then
                    if value.slot == "Shield" or value.slot == "Ranged" then
                        hasRight = true
                    elseif value.slot == "Weapon" then
                        hasLeft = true
                    end
                    texture:Show()
                else
                    showDurability = 1
                end
                numAlerts = numAlerts + 1
                if alertStatus == 2 then
                    FluxDurabilityFrame.anyItemBroken = true
                end
            else
                texture:SetVertexColor(1.0, 1.0, 1.0, 0.5)
                if value.showSeparate then
                    texture:Hide()
                end
            end
        end
    end
    
    FluxDurabilityFrame.anyItemBreaking = numAlerts > 0
    
    -- Show/hide non-separate textures
    for index, value in pairs(INVENTORY_ALERT_STATUS_SLOTS) do
        if not value.showSeparate then
            texture = FluxDurabilityTextures[value.slot]
            if texture then
                if showDurability then
                    texture:Show()
                else
                    texture:Hide()
                end
            end
        end
    end
    
    -- Calculate and set frame width
    local width = 58
    if hasRight then
        if FluxDurabilityTextures.Head then
            FluxDurabilityTextures.Head:ClearAllPoints()
            FluxDurabilityTextures.Head:SetPoint("TOPRIGHT", FluxDurabilityFrame, "TOPRIGHT", -40, 0)
        end
        width = width + 20
    else
        if FluxDurabilityTextures.Head then
            FluxDurabilityTextures.Head:ClearAllPoints()
            FluxDurabilityTextures.Head:SetPoint("TOPRIGHT", FluxDurabilityFrame, "TOPRIGHT", -20, 0)
        end
    end
    if hasLeft then
        width = width + 14
    end
    
    if not InCombatLockdown() then
        FluxDurabilityFrame:SetWidth(width)
    end
    
    -- Vehicle seats sit to the right of this frame (FluxVehicleSeats), so they no longer replace it.
    local isNotShowingCompactArenaFrame = not CompactArenaFrame or not CompactArenaFrame:IsShown()
    FluxDurabilityFrame.shouldShow = numAlerts > 0 and isNotShowingCompactArenaFrame
    
    -- Update shown state
    if C_GameRules and C_GameRules.IsGameRuleActive and Enum.GameRule and Enum.GameRule.RepairArmorDisabled and C_GameRules.IsGameRuleActive(Enum.GameRule.RepairArmorDisabled) then
        FluxDurabilityFrame:Hide()
        return
    end
    
    local kioskEnabled = Kiosk and Kiosk.IsEnabled and Kiosk.IsEnabled()
    if not InCombatLockdown() then
        FluxDurabilityFrame:SetShown(FluxDurabilityFrame.shouldShow and not kioskEnabled)
    end
end

local function FrameInTopLeft(frame)
    if not frame or not frame.IsShown or not frame:IsShown() then
        return false
    end
    if not frame.GetTop or not frame.GetLeft or not frame.GetBottom then
        return false
    end
    local top, left, bottom = frame:GetTop(), frame:GetLeft(), frame:GetBottom()
    local uiTop = UIParent and UIParent.GetTop and UIParent:GetTop()
    local uiLeft = UIParent and UIParent.GetLeft and UIParent:GetLeft()
    local uiWidth = UIParent and UIParent.GetWidth and UIParent:GetWidth()
    if type(top) ~= "number" or type(left) ~= "number" or type(bottom) ~= "number" then
        return false
    end
    if type(uiTop) ~= "number" or type(uiLeft) ~= "number" or type(uiWidth) ~= "number" or uiWidth <= 0 then
        return false
    end
    return (uiTop - top) <= 180 and (left - uiLeft) <= (uiWidth * 0.5)
end

local function LowerTopLeftFrame(a, b)
    if not FrameInTopLeft(a) then
        return FrameInTopLeft(b) and b or nil
    end
    if not FrameInTopLeft(b) then
        return a
    end
    local ab, bb = a:GetBottom(), b:GetBottom()
    if type(bb) == "number" and (type(ab) ~= "number" or bb < ab) then
        return b
    end
    return a
end

-- Update durability frame position
function UpdateFluxDurabilityFramePosition()
    if not FluxDurabilityFrame then
        return
    end

    if not InCombatLockdown() then
        FluxDurabilityFrame:ClearAllPoints()
        -- Top-left. If the micro menu and/or status strip is in that corner,
        -- sit under the lower of the two so both stay above the repair icons.
        local under = LowerTopLeftFrame(_G.FluxMicroMenu, _G.FluxStatusBarContainer)
        if under then
            FluxDurabilityFrame:SetPoint("TOPLEFT", under, "BOTTOMLEFT", 0, -4)
            if FluxVehicleSeats_UpdateAnchor then
                FluxVehicleSeats_UpdateAnchor()
            end
            return
        end

        -- Neither chrome is in the top-left. If a PVP objective widget is there, stack under it.
        local pvpObj = _G.UIWidgetTopCenterContainerFrame
        if pvpObj and pvpObj.IsShown and pvpObj:GetTop() and pvpObj:GetLeft() and pvpObj:GetRight() and pvpObj:IsShown() then
            local pvpTop = pvpObj:GetTop()
            local pvpLeft = pvpObj:GetLeft()
            local pvpRight = pvpObj:GetRight()
            local uiTop = UIParent and UIParent.GetTop and UIParent:GetTop()
            local uiLeft = UIParent and UIParent.GetLeft and UIParent:GetLeft()
            local uiWidth = UIParent and UIParent.GetWidth and UIParent:GetWidth()
            if type(pvpTop) == "number" and type(pvpLeft) == "number" and type(pvpRight) == "number"
                and type(uiTop) == "number" and type(uiLeft) == "number" and type(uiWidth) == "number" and uiWidth > 0 then
                local pvpNearTop = (uiTop - pvpTop) <= 120
                local pvpCenterX = (pvpLeft + pvpRight) / 2
                local pvpInLeftThird = pvpCenterX <= (uiLeft + (uiWidth / 3))
                if pvpNearTop and pvpInLeftThird then
                    FluxDurabilityFrame:SetPoint("TOPLEFT", pvpObj, "BOTTOMLEFT", 0, DURABILITY_TOPLEFT_PVP_GAP)
                    if FluxVehicleSeats_UpdateAnchor then
                        FluxVehicleSeats_UpdateAnchor()
                    end
                    return
                end
            end
        end

        FluxDurabilityFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", DURABILITY_TOPLEFT_X, DURABILITY_TOPLEFT_Y)
    end
    if FluxVehicleSeats_UpdateAnchor then
        FluxVehicleSeats_UpdateAnchor()
    end
end

EnsureDurabilityUsesStatusContainer = function()
    if not FluxDurabilityFrame or InCombatLockdown() then
        return
    end
    if FluxDurabilityFrame:GetParent() ~= UIParent then
        FluxDurabilityFrame:SetParent(UIParent)
    end
end

--- No gold/exp/rep strips: hide the stack entirely (FluxBorder + container) so nothing remains on screen.
HideStatusStripWithNoContent = function(activeBars, statusStripPosition)
    if activeBars and #activeBars > 0 then
        return false
    end
    if StatusInfoCellActive() then
        return false
    end
    for _, sep in pairs(Separators) do
        sep:Hide()
    end
    for _, sep in pairs(ColSeparators) do
        sep:Hide()
    end
    if FluxBorder and FluxBorder.RemoveFrom then
        FluxBorder:RemoveFrom(FluxStatusBarContainer)
    end
    FluxStatusBarContainer:Hide()
    durabilityAnchorFrame = nil
    if FluxDurabilityFrame and not InCombatLockdown() and FluxDurabilityFrame:GetParent() ~= UIParent then
        FluxDurabilityFrame:SetParent(UIParent)
    end
    UpdateFluxDurabilityFramePosition()
    UpdateExpBar()
    return true
end

--- Match chat / window width when micro menu is vertical (status bar not tied to narrow menu column).
local function GetFluxStatusBarReferenceWidth()
    if FluxWindowFrame and FluxWindowFrame.WINDOW_WIDTH then
        return FluxWindowFrame.WINDOW_WIDTH
    end
    return 300 * 1.35
end

--- Distance from UIParent bottom up to the top edge of FluxStatusBarContainer when Layout position 2 is active.
--- Used to lift chat / player / pet bar above the horizontal strip. Returns nil if not applicable.
function _G.FluxStatusBar_GetLocation2MinBottomOffset()
    if not FluxOptions or not FluxOptions.GetStatusBarPosition or FluxOptions:GetStatusBarPosition() ~= 2 then
        return nil
    end
    local sb = _G.FluxStatusBarContainer
    if not sb or not sb.IsShown or not sb:IsShown() or not sb.GetTop or not UIParent or not UIParent.GetBottom then
        return nil
    end
    local t, b = sb:GetTop(), UIParent:GetBottom()
    if type(t) ~= "number" or type(b) ~= "number" or t ~= t or b ~= b then
        return nil
    end
    local fes = (sb.GetEffectiveScale and sb:GetEffectiveScale()) or 1
    local ues = (UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    if type(fes) == "number" and fes > 0 and type(ues) == "number" and ues > 0 then
        t = t * fes / ues
    end
    return t - b
end

--- Height of the bottom status strip when layout position 3 is active (lifts main action bar and other bottom UI).
function _G.FluxStatusBar_GetBottomOverlayHeight()
    if not FluxOptions or not FluxOptions.GetStatusBarPosition or FluxOptions:GetStatusBarPosition() ~= 3 then
        return 0
    end
    local sb = _G.FluxStatusBarContainer
    if not sb or not sb.IsShown or not sb:IsShown() or not sb.GetHeight then
        return 0
    end
    local h = sb:GetHeight()
    if type(h) ~= "number" or h ~= h or h <= 0 then
        return 0
    end
    return h
end

--- Strip height adjusted for UI that should align with the main action bar row (pos3: same -4px nudge as FluxActionBar).
--- Chat / NC grid clearing the physical strip still use FluxStatusBar_GetBottomOverlayHeight (raw).
local STATUS_POS3_ALIGNED_CHROME_NUDGE = 4

function _G.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome()
    local h = _G.FluxStatusBar_GetBottomOverlayHeight and _G.FluxStatusBar_GetBottomOverlayHeight() or 0
    if type(h) ~= "number" or h <= 0 or h ~= h then
        return 0
    end
    if FluxOptions and FluxOptions.GetStatusBarPosition and FluxOptions:GetStatusBarPosition() == 3 then
        return math.max(0, h - STATUS_POS3_ALIGNED_CHROME_NUDGE)
    end
    return h
end

local notifyLayoutSkippedCombat = false

local function InfoPlacementIsStatusIntegrated()
    return FluxOptions and FluxOptions.GetInfoFramePlacement
        and FluxOptions:GetInfoFramePlacement() == "statusIntegrated"
end

--- When Info is status-integrated, FluxStatusBar.UpdateLayout runs extremely often (micro menu / XP ticks).
--- NotifyStatusBarLayoutDependents used to call UnifiedBorder + PVP every time — same work InfoFrame also
--- triggers — causing sustained FPS loss. Coalesce border/PVP to a short timer when integrated only.
local NOTIFY_UNIFIED_UI_COOLDOWN = 0.32
local notifyUnifiedUITimer
local notifyUnifiedUIEarliest = 0

local function CancelNotifyUnifiedUICoalescer()
    if notifyUnifiedUITimer then
        if type(notifyUnifiedUITimer) == "table" and notifyUnifiedUITimer.Cancel then
            pcall(function()
                notifyUnifiedUITimer:Cancel()
            end)
        end
        notifyUnifiedUITimer = nil
    end
end

local function NotifyUnifiedUIAndPVPThrottled()
    if not InfoPlacementIsStatusIntegrated() then
        CancelNotifyUnifiedUICoalescer()
        notifyUnifiedUIEarliest = 0
        if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
            pcall(FluxUnifiedBorder.UpdateBorder)
        end
        if FluxUnifiedBorder and FluxUnifiedBorder.UpdateStatusBarBorder then
            pcall(FluxUnifiedBorder.UpdateStatusBarBorder)
        end
        if _G.FluxPVPObjectiveMover and _G.FluxPVPObjectiveMover.UpdatePositions then
            pcall(_G.FluxPVPObjectiveMover.UpdatePositions)
        end
        return
    end

    if not (C_Timer and C_Timer.After) then
        if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
            pcall(FluxUnifiedBorder.UpdateBorder)
        end
        if FluxUnifiedBorder and FluxUnifiedBorder.UpdateStatusBarBorder then
            pcall(FluxUnifiedBorder.UpdateStatusBarBorder)
        end
        if _G.FluxPVPObjectiveMover and _G.FluxPVPObjectiveMover.UpdatePositions then
            pcall(_G.FluxPVPObjectiveMover.UpdatePositions)
        end
        return
    end

    if notifyUnifiedUITimer then
        return
    end

    local now = GetTime()
    local delay = math.max(0.001, notifyUnifiedUIEarliest - now)
    notifyUnifiedUITimer = C_Timer.After(delay, function()
        notifyUnifiedUITimer = nil
        notifyUnifiedUIEarliest = GetTime() + NOTIFY_UNIFIED_UI_COOLDOWN
        if InCombatLockdown() then
            return
        end
        if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
            pcall(FluxUnifiedBorder.UpdateBorder)
        end
        if FluxUnifiedBorder and FluxUnifiedBorder.UpdateStatusBarBorder then
            pcall(FluxUnifiedBorder.UpdateStatusBarBorder)
        end
        if _G.FluxPVPObjectiveMover and _G.FluxPVPObjectiveMover.UpdatePositions then
            pcall(_G.FluxPVPObjectiveMover.UpdatePositions)
        end
    end)
end

local function NotifyStatusBarLayoutDependentsBody()
    if _G.FluxActionBar and _G.FluxActionBar.UpdatePosition then
        pcall(_G.FluxActionBar.UpdatePosition, _G.FluxActionBar)
    end
    if FluxWindowFrame and FluxWindowFrame.ApplyBottomLiftFromStatusBar then
        pcall(FluxWindowFrame.ApplyBottomLiftFromStatusBar, FluxWindowFrame)
    end
    if _G.FluxNonCombatGrid_ApplyScreenBottomAnchor then
        pcall(_G.FluxNonCombatGrid_ApplyScreenBottomAnchor)
    end
    if FluxCombatManager and FluxCombatManager.UpdateAnchor then
        pcall(FluxCombatManager.UpdateAnchor, FluxCombatManager)
    end
    if FluxTrinketMenuManager and FluxTrinketMenuManager.UpdateAnchor then
        pcall(FluxTrinketMenuManager.UpdateAnchor, FluxTrinketMenuManager)
    end
    if FluxInfoFrame and FluxInfoFrame.UpdatePosition then
        pcall(FluxInfoFrame.UpdatePosition)
    end
    if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
        pcall(FluxUnifiedBorder.UpdateBorder)
    end
    NotifyUnifiedUIAndPVPThrottled()
    if _G.FluxUnitFrames_ApplyPlayerStatusBarLayout then
        pcall(_G.FluxUnitFrames_ApplyPlayerStatusBarLayout)
    end
    if _G.FluxUnitFrames_RefreshStanceAndPetBarLayout then
        pcall(_G.FluxUnitFrames_RefreshStanceAndPetBarLayout)
    elseif _G.FluxPetBar and _G.FluxPetBar.UpdatePosition then
        pcall(_G.FluxPetBar.UpdatePosition, _G.FluxPetBar)
    end
end

local regenFlushNotifyFrame = CreateFrame("Frame")
regenFlushNotifyFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
regenFlushNotifyFrame:SetScript("OnEvent", function()
    if notifyLayoutSkippedCombat and not InCombatLockdown() then
        notifyLayoutSkippedCombat = false
        NotifyStatusBarLayoutDependentsBody()
    end
end)

-- Flux perf: NotifyStatusBarLayoutDependents cascades into ~8 subsystems
-- (FluxActionBar / FluxCombatManager / FluxInfoFrame / FluxUnitFrames / ...).
-- A single user action (micro button resize, option toggle) can queue multiple
-- UpdateLayout passes in one stack tick; each previously drove the full
-- cascade. Coalesce to one fan-out per frame via a pending flag + 0s timer.
local notifyCoalescePending = false

local function FlushNotifyCoalesced()
    notifyCoalescePending = false
    if InCombatLockdown() then
        notifyLayoutSkippedCombat = true
        -- regenFlushNotifyFrame will re-fire the body post-combat.
        return
    end
    notifyLayoutSkippedCombat = false
    NotifyStatusBarLayoutDependentsBody()
end

local function NotifyStatusBarLayoutDependents()
    if InCombatLockdown() then
        notifyLayoutSkippedCombat = true
        -- Keep the existing post-combat retry path.
        if C_Timer and C_Timer.After and not notifyCoalescePending then
            notifyCoalescePending = true
            C_Timer.After(0, FlushNotifyCoalesced)
        end
        return
    end
    if notifyCoalescePending then
        return
    end
    if C_Timer and C_Timer.After then
        notifyCoalescePending = true
        C_Timer.After(0, FlushNotifyCoalesced)
    else
        -- Fallback: run synchronously if no timer API.
        notifyLayoutSkippedCombat = false
        NotifyStatusBarLayoutDependentsBody()
    end
end

local function ClearInfoIntegratedColumnFlag()
    if FluxInfoFrame and FluxInfoFrame.SetAnchoredByStatusBarColumn then
        FluxInfoFrame.SetAnchoredByStatusBarColumn(false)
    end
end

local UpdateLayout
local function MaybeUpdateLayoutForComposition()
    local key = ComputeStatusBarCompositionKey()
    if key == _lastCompositionKey then
        _G.FluxPerfStatusBarLayoutSkipped = (_G.FluxPerfStatusBarLayoutSkipped or 0) + 1
        return false
    end
    UpdateLayout()
    return true
end

function UpdateLayout()
    ClearInfoIntegratedColumnFlag()
    _G.FluxPerfStatusBarLayoutRuns = (_G.FluxPerfStatusBarLayoutRuns or 0) + 1

    local statusPos = 1
    if FluxOptions and FluxOptions.GetStatusBarPosition then
        statusPos = FluxOptions:GetStatusBarPosition()
    end

    local microMenu = _G.FluxMicroMenu
    if statusPos ~= 2 and statusPos ~= 3 and not microMenu then
        pendingStatusLayout = true
        return false
    end
    -- Display fills remain live in combat. Only structural layouts involving
    -- protected frames/anchors need the combat-end reconciliation.
    if InCombatLockdown() and (
        (FluxStatusBarContainer.IsProtected and FluxStatusBarContainer:IsProtected())
        or (statusPos == 1 and microMenu and microMenu.IsProtected and microMenu:IsProtected())
        or (ExpBar.IsProtected and ExpBar:IsProtected())
        or (RepBar.IsProtected and RepBar:IsProtected())) then
        pendingStatusLayout = true
        return false
    end
    pendingStatusLayout = false
    if Flux and Flux.Startup then Flux.Startup.Count("layout_passes") end

    -- List of bars to show (in Top-Down order)
    local activeBars = {}

    -- 1. Gold / currency strip
    if ShouldShowCurrencyBar() then
        table.insert(activeBars, GoldBar)
        GoldBar:Show()
    else
        GoldBar:Hide()
    end

    -- 2. Exp: hide "Max Level" strip when rep bar is shown (redundant); keep when no rep so user can click to open reputation.
    -- Optional: hide entirely when the game would not show an XP bar (e.g. max level) — Status Bars → Hide experience bar when not gaining XP.
    local xpActive = ShouldShowExperienceBar()
    local showMaxLevelStyleBar = not xpActive and not ShouldHideExpBarWhenNoXP()
    local showExpBar = xpActive or (showMaxLevelStyleBar and not RepBar.isTracking)
    if showExpBar then
        table.insert(activeBars, ExpBar)
    else
        ExpBar:Hide()
    end
    
    -- 3. Rep (Conditional)
    if RepBar.isTracking then
        table.insert(activeBars, RepBar)
        RepBar:Show()
    else
        RepBar:Hide()
    end

    _lastCompositionKey = ComputeStatusBarCompositionKey()

    durabilityAnchorFrame = activeBars[1] or ExpBar

    -- Reset all separators
    for _, sep in pairs(Separators) do
        sep:Hide()
    end
    for _, sep in pairs(ColSeparators) do
        sep:Hide()
    end

    if statusPos == 3 then
        UpdateLayoutLocation3(activeBars)
        NotifyStatusBarLayoutDependents()
        return
    end

    if statusPos == 2 then
        UpdateLayoutLocation2(activeBars)
        NotifyStatusBarLayoutDependents()
        return
    end

    if not microMenu then
        return
    end

    if HideStatusStripWithNoContent(activeBars, 1) then
        NotifyStatusBarLayoutDependents()
        return
    end
    EnsureDurabilityUsesStatusContainer()

    if StatusInfoCellActive() and FluxInfoFrame and FluxInfoFrame.GetStableIntegratedColumnWidth then
        FluxInfoFrame.GetStableIntegratedColumnWidth()
    end
    local cells = BuildStatusBarCells(activeBars)
    local numRows = #cells
    local vertPad = VERT_PADDING

    -- Calculate Container Height
    local barH = GetStatusBarPixelHeight()
    local totalHeight = vertPad * 2
    if numRows > 0 then
        totalHeight = totalHeight + (numRows * barH)
        if numRows > 1 then
            totalHeight = totalHeight + ((numRows - 1) * BAR_SPACING)
        end
    end

    -- Setup Container
    local layoutPos = 1
    if FluxOptions and FluxOptions.GetMicroMenuLayoutPosition then
        layoutPos = FluxOptions:GetMicroMenuLayoutPosition()
    end

    local inset = GetBorderInset()
    FluxStatusBarContainer:ClearAllPoints()
    local menuWidth
    if layoutPos == 2 or layoutPos == 3 then
        local minBarW = tonumber(FluxMicroMenu.MIN_BAR_WIDTH) or 250
        menuWidth = math.max(minBarW, GetFluxStatusBarReferenceWidth())
        FluxStatusBarContainer:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 2, 0)
    else
        menuWidth = microMenu:GetWidth() or 300
        FluxStatusBarContainer:SetPoint("TOPLEFT", microMenu, "BOTTOMLEFT", 0, inset)
    end
    FluxStatusBarContainer:SetSize(menuWidth, totalHeight)
    
    -- Position bars and the info row. Slot start/middle/end is top / after the first bar / bottom.
    local currentY = -vertPad
    local sepR, sepG, sepB = GetStatusBarSeparatorTintRGB()

    for i, cell in ipairs(cells) do
        if cell == INFO_CELL then
            local infoFrame = FluxInfoFrame and FluxInfoFrame.GetFrame and FluxInfoFrame:GetFrame()
            AnchorIntegratedInfoCell(infoFrame, HORIZ_PADDING, currentY, 0, barH, true)
        else
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", FluxStatusBarContainer, "TOPLEFT", HORIZ_PADDING, currentY)
            cell:SetPoint("TOPRIGHT", FluxStatusBarContainer, "TOPRIGHT", -HORIZ_PADDING, currentY)
            cell:SetHeight(barH)
            cell:Show()
        end

        currentY = currentY - barH

        if i < numRows then
            local sep = GetSeparator(i)
            sep:Show()
            sep:ClearAllPoints()

            local sepCenterY = currentY - (BAR_SPACING / 2)
            local sepHalfHeight = 8
            local sepTopY = sepCenterY + sepHalfHeight

            sep:SetPoint("TOPLEFT", FluxStatusBarContainer, "TOPLEFT", 0, sepTopY)
            sep:SetPoint("TOPRIGHT", FluxStatusBarContainer, "TOPRIGHT", 0, sepTopY)

            if FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases() then
                sep:SetAtlas("battlefieldminimap-border-top", true)
                sep:SetAtlas("battlefieldminimap-border-top", false)
                sep:SetHeight(17)
            else
                sep:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga")
                sep:SetTexCoord(0.004, 0.816, 0.004, 0.070)
                sep:SetHeight(17)
            end

            sep:SetVertexColor(sepR, sepG, sepB, 1)

            currentY = currentY - BAR_SPACING
        end
    end
    
    -- Position custom DurabilityFrame to the right of the gold bar
    UpdateFluxDurabilityFramePosition()

    -- Finalize Border
    if FluxBorder then
        FluxBorder:ApplyTo(FluxStatusBarContainer)
        FluxBorder:SetClassColor(FluxStatusBarContainer)
        if FluxStatusBarContainer.FluxBorderFrame and FluxStatusBarContainer.FluxBorderFrame.Background then
             FluxStatusBarContainer.FluxBorderFrame.Background:SetAlpha(0)
        end
        -- Lower border frame strata and level to be below UnifiedBorder (MEDIUM level 7) and addon popup
        if FluxStatusBarContainer.FluxBorderFrame then
            FluxStatusBarContainer.FluxBorderFrame:SetFrameStrata("BACKGROUND")
            FluxStatusBarContainer.FluxBorderFrame:SetFrameLevel(5) -- Below UnifiedBorder (MEDIUM 7) and addon popup background (BACKGROUND 10)
        end
        -- Also lower the background frame if it exists
        if FluxStatusBarContainer.FluxBorderFrame and FluxStatusBarContainer.FluxBorderFrame.BackgroundFrame then
            FluxStatusBarContainer.FluxBorderFrame.BackgroundFrame:SetFrameStrata("BACKGROUND")
            FluxStatusBarContainer.FluxBorderFrame.BackgroundFrame:SetFrameLevel(0)
        end
    end

    -- Rested overlay/pin use pixel offsets from bar width; must follow micro menu / container resizes
    UpdateExpBar()

    FluxStatusBarContainer:Show()
    NotifyStatusBarLayoutDependents()
end

-------------------------------------------------------------------------------
-- TOOLTIP HANDLING
-------------------------------------------------------------------------------

ExpBar:EnableMouse(true)
ExpBar:SetScript("OnEnter", function(self)
    if self.tooltipText then
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end
end)
ExpBar:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Click to open reputation frame (on both bars)
local function OpenReputationFrame()
    if IsForeverClient() then
        return
    end
    if not InCombatLockdown() then
        if ToggleCharacter then
            ToggleCharacter("ReputationFrame")
        end
    end
end

ExpBar:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        OpenReputationFrame()
    end
end)

RepBar:EnableMouse(true)
RepBar:SetScript("OnEnter", function(self)
    if self.tooltipText then
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end
end)
RepBar:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

RepBar:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        OpenReputationFrame()
    end
end)

-- Forever: left click is a secure click of CharacterMicroButton (Character Info).
do
    local proxy = Flux and Flux.SecureClickProxy
    if proxy and IsForeverClient() then
        local function CharacterButton()
            return _G.CharacterMicroButton
        end
        local function Always()
            return true
        end
        proxy.Attach(ExpBar, { target = CharacterButton, enabled = Always, clicks = "LeftButtonUp" })
        proxy.Attach(RepBar, { target = CharacterButton, enabled = Always, clicks = "LeftButtonUp" })
    end
end

-------------------------------------------------------------------------------
-- EVENT HANDLING
-------------------------------------------------------------------------------

-- Coalesce BAG_UPDATE spam into one UpdateGoldBar (item counts on gold strip)
local goldBarFromBagsDebounce
local function ScheduleUpdateGoldBarFromBags()
    if goldBarFromBagsDebounce then
        return
    end
    if C_Timer and C_Timer.After then
        goldBarFromBagsDebounce = true
        C_Timer.After(0, function()
            goldBarFromBagsDebounce = false
            if _G.UpdateGoldBar then
                pcall(_G.UpdateGoldBar)
            end
        end)
    elseif _G.UpdateGoldBar then
        pcall(_G.UpdateGoldBar)
    end
end

-- Item currency counts refresh via FluxInventory (single bag-event owner)
local goldBarBagListenerHooked = false
local function EnsureGoldBarBagListener()
    if goldBarBagListenerHooked then
        return
    end
    -- FluxItemCurrencyTracking already refreshes the strip on bag pulses.
    local tracking = _G.FluxItemCurrencyTracking
    if tracking and tracking.invListenerRegistered then
        goldBarBagListenerHooked = true
        return
    end
    local inv = _G.FluxInventory
    if inv and inv.RegisterCountListener then
        goldBarBagListenerHooked = true
        inv.RegisterCountListener("FluxStatusBar_GoldBar", ScheduleUpdateGoldBarFromBags, {
            tier = "instant",
            regions = { "bags", "equip" },
        })
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("UPDATE_EXHAUSTION")
eventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
eventFrame:RegisterEvent("UPDATE_FACTION")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
eventFrame:RegisterEvent("UPDATE_INVENTORY_ALERTS")
-- Item currency counts: FluxInventory RegisterCountListener (see EnsureGoldBarBagListener)
-- PVP events for Honor/Arena Points tracking (safely register)
if FluxSafeRegisterEvent then
    FluxSafeRegisterEvent(eventFrame, "HONOR_UPDATE")
    FluxSafeRegisterEvent(eventFrame, "ARENA_POINTS_UPDATE")
    FluxSafeRegisterEvent(eventFrame, "PLAYER_PVP_KILLS_CHANGED")
    FluxSafeRegisterEvent(eventFrame, "CURRENCY_DISPLAY_UPDATE")
end

EnsureGoldBarBagListener()

-- Native controls remain in place until a replacement layout exists. All
-- nonprotected status display work can run during an already-in-combat login.
InitializeStatusHUD = function()
    if managedStartup and not Flux.loggedIn then return false end
    EnsureGoldBarBagListener()
    CreateFluxDurabilityFrame()
    UpdateExpBar()
    UpdateRepBar()
    UpdateGoldBar()
    if FluxDurabilityFrame_SetAlerts then FluxDurabilityFrame_SetAlerts() end
    if not statusHUDReady then
        if UpdateLayout() == false then return false end
        statusHUDReady = true
        if Flux and Flux.Startup then Flux.Startup.Mark("status_hud_ready") end
    else
        MaybeUpdateLayoutForComposition()
    end
    HideBlizzardBars()
    return true
end

if managedStartup then
    Flux.Module.Register("StatusBars", {
        phase = "hud", priority = 50, OnEnable = InitializeStatusHUD,
    })
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        InitializeStatusHUD()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not statusHUDReady then
            InitializeStatusHUD()
        elseif pendingStatusLayout then
            UpdateLayout()
        end
        if nativeHidePending then HideBlizzardBars() end
    elseif event == "ADDON_LOADED" then
        if statusHUDReady then
            HideBlizzardBars()
        elseif not managedStartup or Flux.loggedIn then
            InitializeStatusHUD()
        end
    elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" or 
           event == "UPDATE_EXHAUSTION" or event == "PLAYER_UPDATE_RESTING" then
        UpdateExpBar()
        MaybeUpdateLayoutForComposition()
    elseif event == "UPDATE_FACTION" then
        UpdateRepBar()
        MaybeUpdateLayoutForComposition()
    elseif event == "QUEST_LOG_UPDATE" then
        -- High-frequency; only refresh rep fill/text when a faction is watched — never full layout.
        local watchedName = select(1, GetWatchedFactionInfo_Compat())
        if watchedName or RepBar.isTracking then
            UpdateRepBar()
        end
    elseif event == "PLAYER_MONEY" or event == "CURRENCY_DISPLAY_UPDATE" then
        UpdateGoldBar()
    elseif event == "UPDATE_INVENTORY_ALERTS" then
        -- Update durability frame when it updates
        if FluxDurabilityFrame_SetAlerts then
            FluxDurabilityFrame_SetAlerts()
        end
        UpdateFluxDurabilityFramePosition()
    elseif event == "HONOR_UPDATE" or event == "ARENA_POINTS_UPDATE" or event == "PLAYER_PVP_KILLS_CHANGED" then
        -- Update Gold bar when PVP points change (if tracking is enabled)
        UpdateGoldBar()
    end
end)

-- Hook into Currency Tracking Changes
-- These functions are called when user toggles "Show on Backpack"
if C_CurrencyInfo and C_CurrencyInfo.SetCurrencyBackpack then
    hooksecurefunc(C_CurrencyInfo, "SetCurrencyBackpack", function()
        UpdateGoldBar()
    end)
end

-- Legacy Hook
if SetCurrencyBackpack then
    hooksecurefunc("SetCurrencyBackpack", function()
        UpdateGoldBar()
    end)
end

-------------------------------------------------------------------------------
-- SLASH COMMAND
-------------------------------------------------------------------------------

SLASH_FLUXSTATUS1 = "/fluxstatus"
SlashCmdList["FLUXSTATUS"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "debug" then
        -- Debug functionality removed
    elseif msg == "refresh" then
        HideBlizzardBars()
        UpdateExpBar()
        UpdateRepBar()
        UpdateLayout()
    elseif msg == "testdurability" then
        UpdateFluxDurabilityFramePosition()
        -- Force show durability frame for testing (will hide on next update if no alerts)
        if FluxDurabilityFrame then
            FluxDurabilityFrame_SetAlerts()
            if not InCombatLockdown() then
                FluxDurabilityFrame:Show()
            end
        end
    else
        print("|cFF00FF00[FluxStatusBar]|r Usage:")
        print("  /fluxstatus debug - Show debug info")
        print("  /fluxstatus refresh - Force refresh bars")
        print("  /fluxstatus testdurability - Test durability frame positioning")
    end
end

-- Make container accessible globally
_G.FluxStatusBarContainer = FluxStatusBarContainer
_G.FluxExpBar = ExpBar
_G.FluxRepBar = RepBar
_G.FluxGoldBar = GoldBar
-- Make UpdateGoldBar accessible for PVP tracking module
_G.UpdateGoldBar = UpdateGoldBar

-- Make UpdateLayout accessible for micro menu integration.
-- Flux perf: external callers (FluxMicroMenu hijack, OnSizeChanged cascade,
-- options toggles) can trigger multiple UpdateLayout calls in a single stack
-- tick. Each full UpdateLayout + NotifyStatusBarLayoutDependents is heavy and
-- re-entrant via FluxStatusBarContainer:OnSizeChanged -> FluxInfoFrame ->
-- back into UpdateLayout. Coalesce external entries to one real pass per frame.
-- Internal calls remain synchronous; external requests reconcile after the
-- current layout transaction finishes.
do
    local layoutPending = false
    local function FlushPendingLayout()
        layoutPending = false
        if statusHUDReady then UpdateLayout() else InitializeStatusHUD() end
    end
    _G.FluxStatusBarUpdateLayout = function()
        if layoutPending then return end
        if not (C_Timer and C_Timer.After) then
            -- No timer API: run immediately (classic fallback paths).
            if statusHUDReady then UpdateLayout() else InitializeStatusHUD() end
            return
        end
        layoutPending = true
        C_Timer.After(0, FlushPendingLayout)
    end
end
