-- FluxPVPTracking.lua
-- Adds checkboxes to PVP tab for tracking Honor and Arena Points
-- Works with older clients that don't have Currency tab
-- Integrates with FluxStatusBar to display tracked PVP points
--
-- PVP UI widget anchoring (capture bar / objective tracker vs layout) lives in FluxPVPObjectiveMover.lua

local addonName, addonTable = ...

-------------------------------------------------------------------------------
-- SAVED VARIABLES INITIALIZATION
-------------------------------------------------------------------------------

-- Initialize saved variables structure
if not _FluxUI_CharSavedVars then
    _FluxUI_CharSavedVars = {}
end
if not _FluxUI_CharSavedVars.PVPTracking then
    _FluxUI_CharSavedVars.PVPTracking = {
        trackHonor = false,
        trackArena = false,
    }
end

local savedVars = _FluxUI_CharSavedVars.PVPTracking

-------------------------------------------------------------------------------
-- VERSION DETECTION
-------------------------------------------------------------------------------

local isPreDF = false
if FLUX_API then
    isPreDF = FLUX_API.majorVersion and FLUX_API.majorVersion < 10
else
    local version = GetBuildInfo and GetBuildInfo() or "11.0.0"
    local vMajor = tonumber(version:match("^(%d+)")) or 11
    isPreDF = vMajor < 10
end

-- Only enable on clients without Currency tab (pre-DF or clients without C_CurrencyInfo)
local shouldEnable = isPreDF or not (C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo)

-------------------------------------------------------------------------------
-- GET HONOR/ARENA POINTS (Compatible across all clients)
-------------------------------------------------------------------------------

local function GetHonorPoints()
    -- Try modern Currency API first
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        -- Try using currency constants if available
        if Constants and Constants.CurrencyConsts and Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID then
            local info = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID)
            if info and info.quantity then
                return info.quantity
            end
        end
        
        -- Try common Honor currency IDs (varies by client)
        for _, currencyID in ipairs({ 1901, 392, 1792 }) do
            local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
            if info and info.quantity then
                return info.quantity
            end
        end
    end
    
    -- Try legacy GetHonorCurrency if available
    if GetHonorCurrency then
        return GetHonorCurrency()
    end
    
    -- Try reading from PVP frame if it exists
    if _G.PVPFrameHonorPoints then
        local text = _G.PVPFrameHonorPoints:GetText()
        if text then
            local honor = tonumber(text:gsub(",", ""))
            if honor then
                return honor
            end
        end
    end
    
    return 0
end

local function GetArenaPoints()
    -- Try modern Currency API first
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        -- Try using currency constants if available
        if Constants and Constants.CurrencyConsts and Constants.CurrencyConsts.CLASSIC_ARENA_POINTS_CURRENCY_ID then
            local info = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CLASSIC_ARENA_POINTS_CURRENCY_ID)
            if info and info.quantity then
                return info.quantity
            end
        end
        
        -- Try common Arena currency IDs
        for _, currencyID in ipairs({ 1900, 391, 1793 }) do
            local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
            if info and info.quantity then
                return info.quantity
            end
        end
    end
    
    -- Try legacy GetArenaCurrency if available
    if GetArenaCurrency then
        return GetArenaCurrency()
    end
    
    -- Try reading from PVP frame if it exists
    if _G.PVPFrameArenaPoints then
        local text = _G.PVPFrameArenaPoints:GetText()
        if text then
            local arena = tonumber(text:gsub(",", ""))
            if arena then
                return arena
            end
        end
    end
    
    return 0
end

-- Get Honor icon texture
local function GetHonorIcon()
    local factionGroup = UnitFactionGroup and UnitFactionGroup("player") or "Horde"
    return string.format("Interface\\TargetingFrame\\UI-PVP-%s", factionGroup)
end

-- Get Arena icon texture (path fallback)
local function GetArenaIcon()
    return "Interface\\PVPFrame\\PVP-ArenaPoints-Icon"
end

--- Try currency API first so the bar uses the same art + scaling as other watched currencies.
local function GetHonorIconFileID()
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return nil
    end
    for _, id in ipairs({ 1792, 1901, 392 }) do
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
        if ok and type(info) == "table" and type(info.iconFileID) == "number" and info.iconFileID > 0 then
            return info.iconFileID
        end
    end
    return nil
end

local function GetArenaIconFileID()
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return nil
    end
    for _, id in ipairs({ 1793, 1900, 391 }) do
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
        if ok and type(info) == "table" and type(info.iconFileID) == "number" and info.iconFileID > 0 then
            return info.iconFileID
        end
    end
    return nil
end

-- Arena: explicit |T| size. Honor: slightly larger (only honor is bumped).
-- yOff: tiny nudge for honor on the line (–h/2 was too far down).
local PVP_STATUS_ICON_PX = 22
local PVP_HONOR_ICON_PX = 26
local PVP_HONOR_ICON_DY = -3
local PVP_ARENA_ICON_DY = 0

local function PvpStatusBarIconMarkup(fileId, pathFallback, yOff, sizePx)
    yOff = yOff or 0
    local s = type(sizePx) == "number" and sizePx > 0 and sizePx or PVP_STATUS_ICON_PX
    if type(fileId) == "number" and fileId > 0 then
        return string.format("|T%d:%d:%d:2:%d|t", fileId, s, s, yOff)
    end
    if pathFallback and pathFallback ~= "" then
        return string.format("|T%s:%d:%d:2:%d|t", pathFallback, s, s, yOff)
    end
    return ""
end

-------------------------------------------------------------------------------
-- CHECKBOX CREATION
-------------------------------------------------------------------------------

local checkboxesCreated = false

local function CreatePVPCheckboxes()
    if not shouldEnable then return end
    
    local pvpFrame = _G.PVPFrame
    if not pvpFrame then return end
    
    -- Find Honor Points section
    local honorLabel = _G.PVPFrameHonorPoints
    if not honorLabel then return end
    
    -- Find Arena Points section
    local arenaLabel = _G.PVPFrameArenaPoints
    if not arenaLabel then return end
    
    -- Create Honor checkbox (reuse if exists)
    local honorCheckbox = _G.FluxPVPTrackHonorCheckbox
    if not honorCheckbox then
        honorCheckbox = CreateFrame("CheckButton", "FluxPVPTrackHonorCheckbox", pvpFrame, "UICheckButtonTemplate")
        honorCheckbox:SetSize(20, 20)
        honorCheckbox:EnableMouse(true)
        honorCheckbox:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        honorCheckbox:SetFrameLevel(pvpFrame:GetFrameLevel() + 10)
        honorCheckbox.text = honorCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        honorCheckbox.text:SetPoint("LEFT", honorCheckbox, "RIGHT", 5, 0)
        honorCheckbox.text:SetText("Track in Status Bar")
        honorCheckbox.text:SetTextColor(1, 1, 1, 0.8)
        honorCheckbox.text:SetNonSpaceWrap(false)
        -- Make text non-interactive so clicks go through to checkbox
        honorCheckbox.text:EnableMouse(false)
        
        honorCheckbox:SetScript("OnClick", function(self)
            savedVars.trackHonor = self:GetChecked()
            -- Notify FluxStatusBar to update
            if _G.FluxStatusBarContainer and _G.FluxStatusBarContainer.UpdateGoldBar then
                _G.FluxStatusBarContainer.UpdateGoldBar()
            elseif _G.UpdateGoldBar then
                _G.UpdateGoldBar()
            end
        end)
    end
    honorCheckbox:ClearAllPoints()
    honorCheckbox:SetPoint("LEFT", honorLabel, "RIGHT", 10, 0)
    honorCheckbox:SetChecked(savedVars.trackHonor)
    honorCheckbox:SetFrameLevel(pvpFrame:GetFrameLevel() + 10)
    honorCheckbox:Show()
    
    honorCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Track Honor Points", 1, 1, 1)
        GameTooltip:AddLine("When checked, Honor Points will be displayed in the Gold status bar.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    honorCheckbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Create Arena checkbox (reuse if exists)
    local arenaCheckbox = _G.FluxPVPTrackArenaCheckbox
    if not arenaCheckbox then
        arenaCheckbox = CreateFrame("CheckButton", "FluxPVPTrackArenaCheckbox", pvpFrame, "UICheckButtonTemplate")
        arenaCheckbox:SetSize(20, 20)
        arenaCheckbox:EnableMouse(true)
        arenaCheckbox:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        arenaCheckbox:SetFrameLevel(pvpFrame:GetFrameLevel() + 10)
        arenaCheckbox.text = arenaCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        arenaCheckbox.text:SetPoint("LEFT", arenaCheckbox, "RIGHT", 5, 0)
        arenaCheckbox.text:SetText("Track in Status Bar")
        arenaCheckbox.text:SetTextColor(1, 1, 1, 0.8)
        arenaCheckbox.text:SetNonSpaceWrap(false)
        -- Make text non-interactive so clicks go through to checkbox
        arenaCheckbox.text:EnableMouse(false)
        
        arenaCheckbox:SetScript("OnClick", function(self)
            savedVars.trackArena = self:GetChecked()
            -- Notify FluxStatusBar to update
            if _G.FluxStatusBarContainer and _G.FluxStatusBarContainer.UpdateGoldBar then
                _G.FluxStatusBarContainer.UpdateGoldBar()
            elseif _G.UpdateGoldBar then
                _G.UpdateGoldBar()
            end
        end)
    end
    arenaCheckbox:ClearAllPoints()
    arenaCheckbox:SetPoint("LEFT", arenaLabel, "RIGHT", 10, 0)
    arenaCheckbox:SetChecked(savedVars.trackArena)
    arenaCheckbox:SetFrameLevel(pvpFrame:GetFrameLevel() + 10)
    arenaCheckbox:Show()
    
    arenaCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Track Arena Points", 1, 1, 1)
        GameTooltip:AddLine("When checked, Arena Points will be displayed in the Gold status bar.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    arenaCheckbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    checkboxesCreated = true
end

-------------------------------------------------------------------------------
-- INTEGRATION WITH FLUXSTATUSBAR
-------------------------------------------------------------------------------

-- Export functions for FluxStatusBar to use
FluxPVPTracking = FluxPVPTracking or {}

-- Hoisted (was nested inside GetTrackedPVPText every gold-bar refresh).
local function FormatPVPNumber(number)
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

FluxPVPTracking.GetTrackedPVPText = function()
    if not shouldEnable then return "" end
    
    local text = ""
    
    if savedVars.trackHonor then
        local honor = GetHonorPoints()
        if honor and honor > 0 then
            if text ~= "" then
                text = text .. " "
            end
            text = text
                .. FormatPVPNumber(honor)
                .. PvpStatusBarIconMarkup(GetHonorIconFileID(), GetHonorIcon(), PVP_HONOR_ICON_DY, PVP_HONOR_ICON_PX)
        end
    end
    if savedVars.trackArena then
        local arena = GetArenaPoints()
        if arena and arena > 0 then
            if text ~= "" then
                text = text .. " "
            end
            text = text
                .. FormatPVPNumber(arena)
                .. PvpStatusBarIconMarkup(GetArenaIconFileID(), GetArenaIcon(), PVP_ARENA_ICON_DY)
        end
    end
    -- One gap before the PvP block (after backpack / gold); tight spacing between honor and arena
    if text ~= "" then
        return "   " .. text
    end
    return ""
end

FluxPVPTracking.ShouldEnable = function()
    return shouldEnable
end

FluxPVPTracking.GetHonorPoints = GetHonorPoints
FluxPVPTracking.GetArenaPoints = GetArenaPoints

--- Keep PVP panel checkboxes aligned when Honor/Arena toggles change elsewhere (e.g. FluxUI Status Bars options).
function FluxPVPTracking.SyncHonorArenaCheckboxesFromSavedVars()
    if not shouldEnable then
        return
    end
    local h = _G.FluxPVPTrackHonorCheckbox
    local a = _G.FluxPVPTrackArenaCheckbox
    if h and h.SetChecked then
        h:SetChecked(savedVars.trackHonor and true or false)
    end
    if a and a.SetChecked then
        a:SetChecked(savedVars.trackArena and true or false)
    end
end

-------------------------------------------------------------------------------
-- EVENT HANDLING
-------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            -- Initialize saved vars
            if not _FluxUI_CharSavedVars then
                _FluxUI_CharSavedVars = {}
            end
            if not _FluxUI_CharSavedVars.PVPTracking then
                _FluxUI_CharSavedVars.PVPTracking = {
                    trackHonor = false,
                    trackArena = false,
                }
            end
            savedVars = _FluxUI_CharSavedVars.PVPTracking
        end
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- Delay checkbox creation to ensure PVP frame is loaded
        C_Timer.After(0.5, function()
            CreatePVPCheckboxes()
        end)
        
        -- Also try when PVP frame is shown
        if _G.PVPFrame then
            if not _G.PVPFrame.FluxHooked then
                _G.PVPFrame:HookScript("OnShow", function()
                    CreatePVPCheckboxes()
                end)
                _G.PVPFrame.FluxHooked = true
            end
        end
    end
end)

-- Also hook PVPHonor_Update if it exists to ensure checkboxes are created
if _G.PVPHonor_Update then
    hooksecurefunc("PVPHonor_Update", function()
        CreatePVPCheckboxes()
    end)
end

-- Make module accessible globally
_G.FluxPVPTracking = FluxPVPTracking



