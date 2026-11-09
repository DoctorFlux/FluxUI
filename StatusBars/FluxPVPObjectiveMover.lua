-- FluxPVPObjectiveMover.lua
-- Moves PVP capture bar and Top-Screen Objective/PVP Tracker relative to Flux layout.
-- Layout rules (see FluxOptions Layout tab):
--   Status bar position 1: below FluxStatusBarContainer (unchanged).
--   Status bar position 2/3 + micro menu position 1: below FluxMicroMenu (same X as horizontal bar).
--   Status bar position 2/3 + micro menu position 2/3: TOP center on UIParent offset to match the
--   default horizontal micro menu column (x=2, nominal MIN_BAR_WIDTH) so widgets do not hug the left edge (pre-DF).
--   Capture bar stacks under the objective/PVP top widget when present.
-- Works across all WoW client versions (Classic Era to Retail)

local addonName, addonTable = ...

-------------------------------------------------------------------------------
-- VERSION DETECTION & COMPATIBILITY
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

-------------------------------------------------------------------------------
-- FRAME POSITIONING LOGIC
-------------------------------------------------------------------------------

-- Fallback when we cannot stack to Flux frames (matches FluxMicroMenu default TOPLEFT x=2).
local VIRTUAL_HORIZONTAL_MENU_LEFT = 2
local OBJECTIVE_TOP_Y = -10
local CAPTURE_GAP_BELOW = -5
local OBJECTIVE_GAP_BELOW = -10

local function IsPlayerTargetPlacement2()
    local o = _G.FluxOptions
    if o and o.GetPlayerTargetPlacement then
        return o:GetPlayerTargetPlacement() == 2
    end
    if _G.FluxUnitFrames_GetPlayerTargetPlacement then
        return _G.FluxUnitFrames_GetPlayerTargetPlacement() == 2
    end
    return false
end

--- Horizontal offset from UIParent's TOP center so this frame's TOP center lines up with the
--- "layout 1" micro menu + status strip column (TOPLEFT at (2,0), nominal MIN_BAR_WIDTH wide).
--- Keeps PVP widgets from hugging the screen edge when status bar is pos2/3 + menu pos2/3 (pre-DF fix).
local function ShouldStackFluxPvpOnInfoFrame()
    local inf = _G.FluxInfoFrame and _G.FluxInfoFrame.GetFrame and _G.FluxInfoFrame:GetFrame()
    if not inf or not inf:IsShown() then
        return false
    end
    if inf.FluxAnchoredByStatusBarColumn then
        return false
    end
    local fo = _G.FluxOptions
    if not fo or not fo.GetInfoFramePlacement then
        return false
    end
    local placement = fo:GetInfoFramePlacement()
    if placement ~= "statusIntegrated" then
        return false
    end
    local st = fo.GetStatusBarPosition and fo:GetStatusBarPosition() or 1
    local mm = fo.GetMicroMenuLayoutPosition and fo:GetMicroMenuLayoutPosition() or 1
    if st == 1 and mm ~= 1 then
        return true
    end
    if (st == 2 or st == 3) and mm ~= 1 then
        return true
    end
    return false
end

local function GetVirtualHorizontalMenuCenterOffsetX()
    local ui = UIParent
    if not ui or not ui.GetWidth then
        return 0
    end
    local uiW = ui:GetWidth()
    if type(uiW) ~= "number" or uiW <= 0 then
        return 0
    end
    local mm = _G.FluxMicroMenu
    local virtualW = (mm and tonumber(mm.MIN_BAR_WIDTH)) or 250
    local centerX = VIRTUAL_HORIZONTAL_MENU_LEFT + virtualW / 2
    return centerX - uiW / 2
end

--- @return string mode "below"|"top_center"|"topleft", frame|nil, string|nil relPoint for below, number ox, number oy
local function GetFluxLayoutAnchorForObjective()
    --- Player/target placement 2 (side-by-side at bottom): keep top objective truly centered; skip micro-menu column offsets.
    if IsPlayerTargetPlacement2() then
        return "top_center", UIParent, "TOP", 0, OBJECTIVE_TOP_Y
    end

    local fluxOpts = _G.FluxOptions
    local statusPos = 1
    local menuPos = 1
    if fluxOpts and fluxOpts.GetStatusBarPosition then
        statusPos = fluxOpts:GetStatusBarPosition()
    end
    if fluxOpts and fluxOpts.GetMicroMenuLayoutPosition then
        menuPos = fluxOpts:GetMicroMenuLayoutPosition()
    end

    local statusBarContainer = _G.FluxStatusBarContainer

    if statusPos == 2 or statusPos == 3 then
        if menuPos == 1 then
            local mm = _G.FluxMicroMenu
            if mm then
                return "below", mm, "BOTTOM", 0, OBJECTIVE_GAP_BELOW
            end
        end
        if ShouldStackFluxPvpOnInfoFrame() then
            local inf = _G.FluxInfoFrame:GetFrame()
            return "below", inf, "BOTTOM", 0, OBJECTIVE_GAP_BELOW
        end
        return "top_center", UIParent, "TOP", GetVirtualHorizontalMenuCenterOffsetX(), OBJECTIVE_TOP_Y
    end

    if statusBarContainer and statusBarContainer:IsShown() then
        return "below", statusBarContainer, "BOTTOM", 0, OBJECTIVE_GAP_BELOW
    end
    if Minimap and Minimap:IsShown() then
        return "below", Minimap, "BOTTOM", 0, OBJECTIVE_GAP_BELOW
    end
    return "below", UIParent, "TOP", 0, -80
end

--- Capture bar when not stacked under objective: same horizontal column as pos1; Y uses gap or top offset.
local function GetFluxLayoutAnchorForCaptureStandalone()
    --- Placement 2: avoid Flux column math; use default-like stacking (status strip / minimap / UIParent).
    if IsPlayerTargetPlacement2() then
        local statusBarContainer = _G.FluxStatusBarContainer
        if statusBarContainer and statusBarContainer:IsShown() then
            return "below", statusBarContainer, "BOTTOM", 0, CAPTURE_GAP_BELOW
        end
        if Minimap and Minimap:IsShown() then
            return "below", Minimap, "BOTTOM", 0, CAPTURE_GAP_BELOW
        end
        return "below", UIParent, "TOP", 0, -80
    end

    local fluxOpts = _G.FluxOptions
    local statusPos = 1
    local menuPos = 1
    if fluxOpts and fluxOpts.GetStatusBarPosition then
        statusPos = fluxOpts:GetStatusBarPosition()
    end
    if fluxOpts and fluxOpts.GetMicroMenuLayoutPosition then
        menuPos = fluxOpts:GetMicroMenuLayoutPosition()
    end

    local statusBarContainer = _G.FluxStatusBarContainer

    if statusPos == 2 or statusPos == 3 then
        if menuPos == 1 then
            local mm = _G.FluxMicroMenu
            if mm then
                return "below", mm, "BOTTOM", 0, CAPTURE_GAP_BELOW
            end
        end
        if ShouldStackFluxPvpOnInfoFrame() then
            local inf = _G.FluxInfoFrame:GetFrame()
            return "below", inf, "BOTTOM", 0, CAPTURE_GAP_BELOW
        end
        return "top_center", UIParent, "TOP", GetVirtualHorizontalMenuCenterOffsetX(), OBJECTIVE_TOP_Y
    end

    if statusBarContainer and statusBarContainer:IsShown() then
        return "below", statusBarContainer, "BOTTOM", 0, CAPTURE_GAP_BELOW
    end
    return "top_center", UIParent, "TOP", GetVirtualHorizontalMenuCenterOffsetX(), OBJECTIVE_TOP_Y
end

local function ApplyAnchorSpec(self, mode, frame, relPoint, ox, oy)
    if not mode or not frame then
        return false
    end
    self:ClearAllPoints()
    if mode == "top_center" then
        self:SetPoint("TOP", frame, relPoint or "TOP", ox or 0, oy or 0)
    elseif mode == "topleft" then
        self:SetPoint("TOPLEFT", frame, "TOPLEFT", ox or 0, oy or 0)
    else
        self:SetPoint("TOP", frame, relPoint, ox or 0, oy or 0)
    end
    return true
end

local function ApplyObjectiveFromSpec()
    local objectiveFrame = _G.UIWidgetTopCenterContainerFrame
    if not objectiveFrame then
        return false
    end
    local mode, frame, relPoint, ox, oy = GetFluxLayoutAnchorForObjective()
    return ApplyAnchorSpec(objectiveFrame, mode, frame, relPoint, ox, oy)
end

--- Capture stacks under the top objective/PVP widget when it is visible; otherwise same rules as layout without stacking.
local function ApplyCapturePosition()
    local captureBarFrame = _G.UIWidgetBelowMinimapContainerFrame
    local objectiveFrame = _G.UIWidgetTopCenterContainerFrame
    if not captureBarFrame then
        return false
    end

    captureBarFrame.FluxRepositioningCaptureBar = true
    captureBarFrame:ClearAllPoints()

    if objectiveFrame and objectiveFrame.IsShown and objectiveFrame:IsShown() then
        captureBarFrame:SetPoint("TOP", objectiveFrame, "BOTTOM", 0, CAPTURE_GAP_BELOW)
    else
        local mode, frame, relPoint, ox, oy = GetFluxLayoutAnchorForCaptureStandalone()
        if mode and frame then
            ApplyAnchorSpec(captureBarFrame, mode, frame, relPoint, ox, oy)
        end
    end

    captureBarFrame.FluxRepositioningCaptureBar = false

    if captureBarFrame:IsShown() then
        captureBarFrame:SetFrameStrata("BACKGROUND")
        local objLevel = (objectiveFrame and objectiveFrame.GetFrameLevel and objectiveFrame:GetFrameLevel()) or 2
        captureBarFrame:SetFrameLevel(math.max(0, objLevel - 1))
    end

    return true
end

local function PositionCaptureBar()
    local captureBarFrame = _G.UIWidgetBelowMinimapContainerFrame

    if not captureBarFrame then
        return false
    end

    -- Do not wrap SetPoint: UIWidgetBelowMinimapContainerFrame is
    -- right-managed; Layout → SetPoint wrap → SetSize ADDON_ACTION_BLOCKED.
    ApplyCapturePosition()
    return true
end

local function PositionObjectiveTracker()
    local objectiveFrame = _G.UIWidgetTopCenterContainerFrame

    if not objectiveFrame then
        return false
    end

    -- Do not wrap SetPoint (same right/top Layout trap as the capture bar).
    ApplyObjectiveFromSpec()

    if objectiveFrame:IsShown() then
        objectiveFrame:SetFrameStrata("BACKGROUND")
        objectiveFrame:SetFrameLevel(2)
    end

    return true
end

local layoutHooksRegistered = false
--- Forward-declare UpdatePositions so micromenu hooks never call a nil upvalue.
local UpdatePositions

local function EnsureFluxLayoutHooksForPVP()
    if layoutHooksRegistered then
        return
    end
    local mm = _G.FluxMicroMenu
    if not mm or not mm.HookScript then
        return
    end
    layoutHooksRegistered = true
    mm:HookScript("OnSizeChanged", function()
        UpdatePositions()
    end)
    mm:HookScript("OnShow", function()
        UpdatePositions()
    end)
    mm:HookScript("OnHide", function()
        UpdatePositions()
    end)
end

UpdatePositions = function()
    EnsureFluxLayoutHooksForPVP()
    PositionObjectiveTracker()
    PositionCaptureBar()
end

-------------------------------------------------------------------------------
-- EVENT HANDLING
-------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_UI_WIDGET")

-- Handle widget updates for dynamic content
if majorVersion >= 10 then
    -- Dragonflight+ widget system
    eventFrame:RegisterEvent("UPDATE_UI_WIDGET")
end

-- Debounce for UPDATE_UI_WIDGET - can fire very frequently and cause lag
local updateWidgetLastScheduled = 0
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- Initial setup with delays to ensure all frames are loaded (kept minimal to avoid lag)
        SafeTimerAfter(0.1, UpdatePositions)
        SafeTimerAfter(1.0, UpdatePositions)
        SafeTimerAfter(3.0, UpdatePositions)
    elseif event == "UPDATE_UI_WIDGET" then
        -- Debounce: only schedule if we haven't scheduled in the last 0.5s
        local now = GetTime()
        if now - updateWidgetLastScheduled >= 0.5 then
            updateWidgetLastScheduled = now
            SafeTimerAfter(0.1, UpdatePositions)
        end
    end
end)

-- Also hook into status bar updates to reposition when bars change
if _G.FluxStatusBarContainer and _G.FluxStatusBarContainer.HookScript then
    _G.FluxStatusBarContainer:HookScript("OnShow", UpdatePositions)
    _G.FluxStatusBarContainer:HookScript("OnHide", UpdatePositions)
end

-- Create global reference
_G.FluxPVPObjectiveMover = {
    UpdatePositions = UpdatePositions,
    PositionCaptureBar = PositionCaptureBar,
    PositionObjectiveTracker = PositionObjectiveTracker,
}

-------------------------------------------------------------------------------
-- SLASH COMMAND FOR DEBUGGING
-------------------------------------------------------------------------------

SLASH_FLUXPVP1 = "/fluxpvp"
SlashCmdList["FLUXPVP"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "debug" then
        print("|cFF00FF00[FluxPVPObjectiveMover]|r Debug Info:")
        print("  Capture Bar Frame:", _G.UIWidgetBelowMinimapContainerFrame and "Found" or "Not Found")
        print("  Objective Frame:", _G.UIWidgetTopCenterContainerFrame and "Found" or "Not Found")
        print("  Status Bar Container:", _G.FluxStatusBarContainer and "Found" or "Not Found")
        print("  Client version:", majorVersion .. " (PreDF: " .. tostring(isPreDF) .. ", Legacy: " .. tostring(isLegacyClient) .. ")")

        local captureBar = _G.UIWidgetBelowMinimapContainerFrame
        if captureBar then
            print("  Capture Bar visible:", captureBar:IsShown())
            print("  Capture Bar hooked:", captureBar.FluxCaptureBarHooked or false)
        end

        local objectiveFrame = _G.UIWidgetTopCenterContainerFrame
        if objectiveFrame then
            print("  Objective Frame visible:", objectiveFrame:IsShown())
            print("  Objective Frame hooked:", objectiveFrame.FluxObjectiveHooked or false)
        end
    elseif msg == "reposition" then
        UpdatePositions()
        print("|cFF00FF00[FluxPVPObjectiveMover]|r Repositioned elements.")
    else
        print("|cFF00FF00[FluxPVPObjectiveMover]|r Usage:")
        print("  /fluxpvp debug - Show debug info")
        print("  /fluxpvp reposition - Force reposition elements")
    end
end

