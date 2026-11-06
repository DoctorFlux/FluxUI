-- FluxBlizzardMeter.lua
-- Integration module for Blizzard's native Damage Meter.
-- Embeds the damage meter into FluxUI's window frame system.
-- Active when Blizzard_DamageMeter exists on this client and Details is not loaded.

local addonName, addonTable = ...

-- Create the public API
FluxBlizzardMeter = {}

-- State tracking
local embeddedParentFrame = nil
local isEmbedded = false
local explicitlyHidden = false
local damageMeterFrame = nil
local primarySessionWindow = nil
local secondarySessionWindow = nil
local pendingEmbed = nil
local visibilityHooked = false
local visibilityShowHooked = false
local ownsNativeVisibility = nil -- nil until initial claim; false after explicit Cleanup.
local InstallNativeVisibility
local pendingStartup = false
local pendingNativeEnable = false
local pendingCleanup = false
local startupTimer = nil
local startupGeneration = 0
local StartStartupEmbed
local embeddedNativePaneCount = nil
local embeddedThreatSelected = false
local threatEmbeddedParent = nil
local FLUX_THREAT_PLUGIN = "DETAILS_PLUGIN_FLUX_THREAT"
local selectedNativeWindows = {}
local missingNativeTypes = {}
local lastConfigurationNotice = ""

local function VisibilityHost()
    local window = FluxWindowFrame
    if not window or not window.GetActiveTab then return nil end
    if window.IsTabEnabled and not window:IsTabEnabled("Meter") then return nil end
    return embeddedParentFrame or (window.frame and window.frame.Content)
end

local function IsEmbeddedHostVisible()
    local host = VisibilityHost()
    local activeTab = FluxWindowFrame and FluxWindowFrame.GetActiveTab
        and FluxWindowFrame:GetActiveTab()
    return not explicitlyHidden and not pendingCleanup and host and host:IsVisible()
        and (not activeTab or activeTab == "Meter") and FluxBlizzardMeter:IsAvailable()
end

local function SyncThreatVisibility()
    if not FluxThreatMeter then return end
    if isEmbedded and embeddedThreatSelected and IsEmbeddedHostVisible() then
        FluxThreatMeter:Show()
    else
        FluxThreatMeter:Hide()
    end
end

local function HideUnusedNativeWindows(dmFrame)
    if not isEmbedded or not dmFrame or not dmFrame.ForEachSessionWindow then return end
    dmFrame:ForEachSessionWindow(function(window)
        if not selectedNativeWindows[window] and window:IsShown() then window:Hide() end
    end)
end

local function ShowEmbeddedRoot(dmFrame)
    local show = embeddedNativePaneCount ~= 0 and IsEmbeddedHostVisible()
    -- Edit Mode owns visibility. Writing it here taints later native combat timers.
    if show and dmFrame.ShouldBeShown then show = dmFrame:ShouldBeShown() end
    if show then
        if not dmFrame:IsShown() then dmFrame:Show() end
    else
        dmFrame:Hide()
    end
    SyncThreatVisibility()
end

local function CancelStartupEmbed()
    startupGeneration = startupGeneration + 1
    if startupTimer and startupTimer.Cancel then startupTimer:Cancel() end
    startupTimer = nil
    pendingStartup = false
end

-- The outer Flux window is the same geometry reference used by FluxDetails.
-- Convert its body rectangles into the native root's .8-scale coordinates.
local METER_SCALE = 0.8
local METER_PADDING_LEFT = 0
local METER_PADDING_RIGHT = 0
local METER_PADDING_TOP = 0
local METER_PADDING_BOTTOM = 0
local EMBED_ROW_GAP = 16
local EMBED_TOP_PAD = 20
local PANE_HEADER_HEIGHT = 14
local BLIZZARD_MAX_PANES = 3

-- Forever gamepad: do not SetParent the meter onto the Flux window. That taints
-- its dropdown click into SetPreferredGamepadInteractTarget. Anchor it to the
-- Flux window instead so the panes stay inside and follow the window.
local function ForeverGamepadEmbed()
    local Flux = addonTable and addonTable.Flux or _G.Flux
    local cap = Flux and (Flux.Cap or Flux.Capabilities)
    return cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() == true
end

local function PlainNumber(value)
    return not (issecretvalue and issecretvalue(value)) and type(value) == "number"
end

local function PlainScale(frame)
    if not frame or not frame.GetEffectiveScale then
        return nil
    end
    local ok, scale = pcall(frame.GetEffectiveScale, frame)
    if not ok or not PlainNumber(scale) or scale <= 0 then
        return nil
    end
    return scale
end

local function EmbedReferenceSize(host)
    local reference = host
    local outer = FluxWindowFrame and FluxWindowFrame.frame
    if outer and outer.Content == host and outer.GetWidth and outer.GetHeight then reference = outer end
    local width = reference and reference.GetWidth and reference:GetWidth()
    local height = reference and reference.GetHeight and reference:GetHeight()
    if not PlainNumber(width) or width < 80 then width = (FluxWindowFrame and FluxWindowFrame.WINDOW_WIDTH) or 400 end
    if not PlainNumber(height) or height < 80 then height = (FluxWindowFrame and FluxWindowFrame.WINDOW_HEIGHT) or 270 end
    return reference, width, height
end

-- Layout-driven embed state
local currentLayoutConfig = nil
local embedPaneLayouts = {} -- [windowIndex] = { left, right, top, bot }
local geometryHooks = {}
local geometryApplying = false
local geometryPending = false
local geometryWakePending = false
local geometryTimer = nil
local geometryGeneration = 0
local RepairEmbeddedGeometry

local function CancelGeometryRepair()
    geometryGeneration = geometryGeneration + 1
    if geometryTimer and geometryTimer.Cancel then geometryTimer:Cancel() end
    geometryTimer, geometryWakePending, geometryPending = nil, false, false
end

local function RequestGeometryRepair()
    if geometryApplying or pendingCleanup or not isEmbedded or not embeddedParentFrame or not FluxBlizzardMeter:IsAvailable() then return end
    geometryPending = true
    if InCombatLockdown() or geometryWakePending then return end
    geometryWakePending = true
    local generation = geometryGeneration
    local function Run()
        if generation ~= geometryGeneration then return end
        geometryTimer, geometryWakePending = nil, false
        if InCombatLockdown() then return end
        geometryPending = false
        RepairEmbeddedGeometry()
    end
    if C_Timer.NewTimer then geometryTimer = C_Timer.NewTimer(0, Run)
    else C_Timer.After(0, Run) end
end

local function WatchGeometry(frame, root)
    if not frame or geometryHooks[frame] then return end
    geometryHooks[frame] = true
    local methods = root and { "SetPoint", "SetPointBase", "SetParent", "SetSize", "SetScale", "SetScaleBase" }
        or { "SetPoint", "SetScale", "SetSize" }
    for _, method in ipairs(methods) do
        if type(frame[method]) == "function" then hooksecurefunc(frame, method, RequestGeometryRepair) end
    end
end

local function HasBlizzardDamageMeterClient()
    if FluxMeterLayout and FluxMeterLayout.HasBlizzardDamageMeterClient then
        return FluxMeterLayout.HasBlizzardDamageMeterClient()
    end
    if not (C_DamageMeter and type(C_DamageMeter.IsDamageMeterAvailable) == "function") then
        return false
    end
    local dm = _G.DamageMeter
    return type(dm) == "table" and dm.GetPrimarySessionWindow ~= nil
end

local function IsDetailsAddonLoaded()
    if FluxMeterLayout and FluxMeterLayout.IsDetailsAddonLoaded then
        return FluxMeterLayout.IsDetailsAddonLoaded()
    end
    local loaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local ok, v = pcall(C_AddOns.IsAddOnLoaded, "Details")
        loaded = ok and v and true or false
    elseif IsAddOnLoaded then
        local ok, v = pcall(IsAddOnLoaded, "Details")
        loaded = ok and v and true or false
    end
    return loaded and type(_G.Details) == "table"
end

-- ---------------------------------------------------------------------------
-- DETECTION & AVAILABILITY
-- ---------------------------------------------------------------------------

--- True when this client ships Blizzard_DamageMeter (live standard / Forever camelot).
function FluxBlizzardMeter:IsSupportedClient()
    return HasBlizzardDamageMeterClient()
end

--- Whether Battlezone should offer/embed the native meter.
-- Details takes the Meter tab when loaded (never both). Does not require
-- C_DamageMeter.IsDamageMeterAvailable(): that is a content/CVar gate.
function FluxBlizzardMeter:IsAvailable()
    if IsDetailsAddonLoaded() then
        return false
    end
    return self:IsSupportedClient()
end

local function EnsureNativeEnabled()
    if not FluxBlizzardMeter:IsAvailable() then return end
    local api = C_CVar
    if not api or not api.GetCVar or not api.SetCVar then return end
    local value = api.GetCVar("damageMeterEnabled")
    if value == nil or value == "1" or value == 1 then return end
    if api.GetCVarInfo then
        local _, _, _, _, locked, secure, readOnly = api.GetCVarInfo("damageMeterEnabled")
        if locked or secure or readOnly then return end
    end
    if InCombatLockdown() then pendingNativeEnable = true; return end
    pendingNativeEnable = false
    -- Match Blizzard's public settings checkbox. Its native CVAR_UPDATE refreshes
    -- cached visibility; never call that pipeline ourselves.
    api.SetCVar("damageMeterEnabled", "1")
end

function FluxBlizzardMeter:EnsureEnabled()
    if InstallNativeVisibility then InstallNativeVisibility() end
    EnsureNativeEnabled()
end

--- Current-zone content gate from Blizzard (diagnostic / empty-data hint).
-- @return boolean, string|nil
function FluxBlizzardMeter:IsContentAvailable()
    if not C_DamageMeter or not C_DamageMeter.IsDamageMeterAvailable then
        return false, "no C_DamageMeter"
    end
    local isAvailable, failureReason = C_DamageMeter.IsDamageMeterAvailable()
    return isAvailable == true, failureReason
end

--- Check if currently embedded
-- @return boolean - true if embedded, false otherwise
function FluxBlizzardMeter:IsEmbedded()
    -- Check if we have a parent frame set (more reliable than isEmbedded flag)
    return embeddedParentFrame ~= nil
end

--- Reset Blizzard native combat sessions (C_DamageMeter). Use with Details reset
--- so server-side meter data matches cleared Details segments.
--- @return boolean true if API ran without error
function FluxBlizzardMeter:ResetAllSessionsIfOutOfCombat()
    if InCombatLockdown() then
        return false
    end
    if UnitAffectingCombat and UnitAffectingCombat("player") then
        return false
    end
    if not self:IsSupportedClient() then
        return false
    end
    if not (C_DamageMeter and type(C_DamageMeter.ResetAllCombatSessions) == "function") then
        return false
    end
    -- Do not gate on IsDamageMeterAvailable: it can be false in some zones/UI states
    -- while reset is still valid; Blizzard's own menu calls ResetAllCombatSessions unconditionally.
    local ok = pcall(C_DamageMeter.ResetAllCombatSessions)
    if not ok then
        return false
    end
    -- Reset fires DAMAGE_METER_RESET; Blizzard session windows refresh themselves.
    -- Do not call Refresh from Flux (taints Init/UpdateName).
    return true
end

-- ---------------------------------------------------------------------------
-- ADDON LOADING & FRAME ACCESS
-- ---------------------------------------------------------------------------

-- Blizzard owns entry initialization, rendering and duration formatting. Replacing
-- those methods taints secure ScrollBox initialization before it reads meter data.
--- Use the Blizzard Damage Meter only when Blizzard already loaded it.
-- @return boolean - true if loaded successfully, false otherwise
local function LoadDamageMeterAddon()
    if not HasBlizzardDamageMeterClient() then
        return false
    end
    if _G["DamageMeter"] then
        return true
    end
    -- Never LoadAddOn Blizzard_DamageMeter from Flux. DamageMeter inherits
    -- EditModeDamageMeterSystemTemplate; OnSystemLoad RegisterSystemFrame then
    -- taints InitSystemAnchors → MainActionBar:SetPointBase on spec/level.
    return false
end

--- Get the main DamageMeter frame
-- @return Frame|nil - the DamageMeter frame or nil if not available
local function GetDamageMeterFrame()
    if not damageMeterFrame then
        damageMeterFrame = _G["DamageMeter"]
    end
    return damageMeterFrame
end

InstallNativeVisibility = function()
    local dmFrame = GetDamageMeterFrame()
    if not dmFrame or not FluxBlizzardMeter:IsSupportedClient() then return end
    if ownsNativeVisibility == nil and VisibilityHost() then ownsNativeVisibility = true end
    local function EnforceVisibility()
        if ownsNativeVisibility ~= true or not VisibilityHost() then return end
        if not isEmbedded or embeddedNativePaneCount == 0 or not IsEmbeddedHostVisible() then dmFrame:Hide() end
        HideUnusedNativeWindows(dmFrame)
        SyncThreatVisibility()
    end
    if not visibilityHooked and dmFrame.UpdateShownState then
        visibilityHooked = true
        hooksecurefunc(dmFrame, "UpdateShownState", EnforceVisibility)
    end
    if not visibilityShowHooked then
        visibilityShowHooked = true
        dmFrame:HookScript("OnShow", function()
            EnforceVisibility()
            if ownsNativeVisibility == true and dmFrame:IsShown() then RequestGeometryRepair() end
        end)
    end
    EnforceVisibility()
end

--- Check if the damage meter is fully ready for embedding
-- @return boolean - true if ready, false otherwise
local function IsMeterReady()
    -- Must be available
    if not FluxBlizzardMeter:IsAvailable() then
        return false
    end
    
    -- Must be loaded (this also loads dependencies)
    if not LoadDamageMeterAddon() then
        return false
    end
    
    -- Get the frame
    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then
        return false
    end
    
    -- Frame must have mixin methods (confirms initialization)
    if not dmFrame.GetPrimarySessionWindow then
        return false
    end
    
    -- Verify windowDataList has been initialized (confirms InitializeWindowDataList() has run)
    if not dmFrame.GetWindowDataList then
        return false
    end
    
    local windowDataList = dmFrame:GetWindowDataList()
    if not windowDataList then
        return false
    end
    
    -- Must be able to get primary window (confirms windowDataList initialized and primary window exists)
    local primary = dmFrame:GetPrimarySessionWindow()
    if not primary then
        return false
    end
    
    return true
end

-- Export as public method
FluxBlizzardMeter.IsMeterReady = IsMeterReady

--- Ensure at least `count` session windows exist and are shown (max 3).
-- @param count number
-- @return table array of session window frames (1-based)
local function EnsureNSessionWindows(count)
    local dmFrame = GetDamageMeterFrame()
    local windows = {}
    if not dmFrame then return windows end
    local maxCount = dmFrame.GetMaxSessionWindowCount and dmFrame:GetMaxSessionWindowCount() or BLIZZARD_MAX_PANES
    for i = 1, maxCount do
        local win = dmFrame.GetSessionWindow and dmFrame:GetSessionWindow(i)
        if not win and i == 1 and dmFrame.GetPrimarySessionWindow then win = dmFrame:GetPrimarySessionWindow() end
        if win then windows[#windows + 1] = win end
    end
    return windows
end

--- Get or create session windows for embedding
-- @return Frame|nil, Frame|nil - primary and secondary session windows
local function GetSessionWindows()
    local windows = EnsureNSessionWindows(2)
    return windows[1], windows[2]
end

-- ---------------------------------------------------------------------------
-- CONFIGURATION & STYLING
-- ---------------------------------------------------------------------------

-- PTR adds a minimize control on session windows; hide it while embedded in Flux (layout is fixed).
local function SlotToDamageMeterType(slot)
    local T = Enum and Enum.DamageMeterType
    local fallback = T and T.DamageDone or 0
    if type(slot) ~= "table" then
        return fallback
    end
    if slot.kind == "plugin" then return nil end
    if slot.kind == "blizzard" and slot.damageMeterType ~= nil then
        return tonumber(slot.damageMeterType) or fallback
    end
    -- Best-effort map from Details attr slots if a mixed layout sneaks through.
    if slot.kind == "attr" then
        local attr = tonumber(slot.attribute) or 1
        local sub = tonumber(slot.subAttribute) or 1
        if not T then return fallback end
        if attr == 1 then
            if sub == 2 then return T.Dps end
            return T.DamageDone
        end
        if attr == 2 then
            if sub == 2 then return T.Hps end
            return T.HealingDone
        end
        if attr == 4 then
            if sub == 3 then return T.Interrupts end
            if sub == 4 then return T.Dispels end
        end
    end
    return fallback
end

local function NormalizeColFracs(fracs, n)
    n = math.max(1, n or 1)
    if type(fracs) ~= "table" or #fracs ~= n then
        local each, out = 1 / n, {}
        for i = 1, n do out[i] = each end
        return out
    end
    local out, sum = {}, 0
    for i = 1, n do
        local v = tonumber(fracs[i]) or 0
        if v < 0.10 then v = 0.10 end
        out[i] = v
        sum = sum + v
    end
    if sum <= 0 then
        local each = 1 / n
        for i = 1, n do out[i] = each end
        return out
    end
    for i = 1, n do out[i] = out[i] / sum end
    return out
end

local function DefaultLayoutConfig()
    local T = Enum and Enum.DamageMeterType
    local dmg = T and T.DamageDone or 0
    local heal = T and T.HealingDone or 2
    return {
        topSlots = { { kind = "blizzard", damageMeterType = dmg } },
        bottomSlots = { { kind = "blizzard", damageMeterType = heal } },
        topColFracs = { 1 },
        bottomColFracs = { 1 },
        topRowFrac = 0.60,
    }
end

local function ResolveLayoutConfig(layoutConfig)
    if type(layoutConfig) == "table" and layoutConfig.topSlots then
        return layoutConfig
    end
    if FluxWindowFrame and FluxWindowFrame.GetMeterLayoutConfig then
        local cfg = FluxWindowFrame:GetMeterLayoutConfig()
        if type(cfg) == "table" and cfg.topSlots then
            return cfg
        end
    end
    if FluxMeterLayout and FluxMeterLayout.GetWorkingLayout then
        local cfg = FluxMeterLayout.GetWorkingLayout()
        if type(cfg) == "table" and cfg.topSlots then
            return cfg
        end
    end
    return DefaultLayoutConfig()
end

--- Position a session window in the parent using pixel offsets (Details-style grid).
-- Session windows stay at scale 1; the DamageMeter root is scaled/expanded instead.
local function PositionSessionWindowGrid(sessionWindow, parentFrame, leftOff, rightOff, topOff, botOff)
    if not sessionWindow or not parentFrame then return end
    if InCombatLockdown() then return end
    local previous = geometryApplying; geometryApplying = true
    sessionWindow:ClearAllPoints()
    sessionWindow:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", leftOff, -topOff)
    sessionWindow:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", rightOff, botOff)
    if sessionWindow.SetScale then sessionWindow:SetScale(1) end
    geometryApplying = previous
end

--- Keep the scaled native canvas exactly over the outer Flux window.
local function ApplyRootScaleAndSize(parentFrame)
    if not parentFrame or InCombatLockdown() then return end
    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then return end

    local reference, pw, ph = EmbedReferenceSize(parentFrame)
    local layoutW, layoutH = pw / METER_SCALE, ph / METER_SCALE
    local previous = geometryApplying; geometryApplying = true
    -- Blizzard supplies these aliases to the original widget methods. Avoid
    -- its Edit Mode overrides writing snap/layout metadata from addon geometry.
    local setPoint = type(dmFrame.SetPointBase) == "function" and dmFrame.SetPointBase or dmFrame.SetPoint
    local clearPoints = type(dmFrame.ClearAllPointsBase) == "function" and dmFrame.ClearAllPointsBase or dmFrame.ClearAllPoints
    local setScale = type(dmFrame.SetScaleBase) == "function" and dmFrame.SetScaleBase or dmFrame.SetScale

    if ForeverGamepadEmbed() then
        local hostScale = PlainScale(reference)
        local holderScale = PlainScale(dmFrame:GetParent())
        if hostScale and holderScale then
            setScale(dmFrame, (hostScale * METER_SCALE) / holderScale)
        else
            setScale(dmFrame, METER_SCALE)
        end
        clearPoints(dmFrame)
        dmFrame:SetSize(layoutW, layoutH)
        setPoint(dmFrame, "CENTER", reference, "CENTER", 0, 0)
        if parentFrame.GetFrameStrata and dmFrame.SetFrameStrata then
            dmFrame:SetFrameStrata(parentFrame:GetFrameStrata())
        end
        if parentFrame.GetFrameLevel and dmFrame.SetFrameLevel then
            dmFrame:SetFrameLevel((parentFrame:GetFrameLevel() or 0) + 20)
        end
        geometryApplying = previous
        return
    end

    dmFrame:SetParent(parentFrame)
    setScale(dmFrame, METER_SCALE)
    clearPoints(dmFrame)
    dmFrame:SetSize(layoutW, layoutH)
    setPoint(dmFrame, "CENTER", reference, "CENTER", 0, 0)
    geometryApplying = previous
end

RepairEmbeddedGeometry = function()
    if not isEmbedded or not embeddedParentFrame or InCombatLockdown() or not FluxBlizzardMeter:IsAvailable() then return end
    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then return end
    ApplyRootScaleAndSize(embeddedParentFrame)
    for index, pane in pairs(embedPaneLayouts) do
        local window = pane.window or (dmFrame.GetSessionWindow and dmFrame:GetSessionWindow(index))
        if window then PositionSessionWindowGrid(window, dmFrame, pane.left, pane.right, pane.top, pane.bot) end
    end
    if FluxMeterSkin and FluxMeterSkin.SyncNativeTimer then FluxMeterSkin:SyncNativeTimer() end
end

local styledEntryWindows = {}
local skinnedWindows = {}

local function ApplyEmbeddedWindowSkin(window)
    if window and FluxMeterSkin and FluxMeterSkin.ApplyToWindow then
        FluxMeterSkin:ApplyToWindow(window, METER_SCALE)
        skinnedWindows[window] = true
    end
end

local function StyleEmbeddedEntryName(entry)
    if not entry or not entry.GetName then return end
    local isLocalPlayer = entry.isLocalPlayer
    if issecretvalue and issecretvalue(isLocalPlayer) then return end
    local name = entry:GetName()
    if not name or not name.SetTextColor then return end
    if isLocalPlayer == true then
        local color = GREEN_FONT_COLOR
        name:SetTextColor(color.r, color.g, color.b)
    else
        name:SetTextColor(1, 1, 1)
    end
    if FluxMeterSkin and FluxMeterSkin.ApplyToEntry then
        FluxMeterSkin:ApplyToEntry(entry, METER_SCALE)
    end
end

local function InstallEmbeddedEntryStyle(window)
    if not window or not window.InitEntry then return end
    -- Resolve installed artwork before the first pooled row uses it.
    if not skinnedWindows[window] then ApplyEmbeddedWindowSkin(window) end
    if styledEntryWindows[window] then return end
    styledEntryWindows[window] = true
    -- Preserve Flux's local-player tint after Blizzard finishes native Init.
    -- Secure posthooks keep entry functions and secret rendering under Blizzard.
    hooksecurefunc(window, "InitEntry", function(_, entry)
        if isEmbedded and FluxBlizzardMeter:IsAvailable() then StyleEmbeddedEntryName(entry) end
    end)
    if type(window.UpdateBackground) == "function" then
        hooksecurefunc(window, "UpdateBackground", function()
            if isEmbedded and skinnedWindows[window] and FluxBlizzardMeter:IsAvailable() then
                ApplyEmbeddedWindowSkin(window)
            end
        end)
    end
    if window.ForEachEntryFrame then
        window:ForEachEntryFrame(StyleEmbeddedEntryName)
    end
    if window.GetLocalPlayerEntry then
        StyleEmbeddedEntryName(window:GetLocalPlayerEntry())
    end
end

--- Configure chrome/type for an embedded session window (position applied separately).
local function ConfigureSessionWindowChrome(sessionWindow)
    if not sessionWindow then return end
    if InCombatLockdown() then return end

    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then return end
    WatchGeometry(sessionWindow)

    InstallEmbeddedEntryStyle(sessionWindow)
    local sourceWindow = sessionWindow.GetSourceWindow and sessionWindow:GetSourceWindow()
    InstallEmbeddedEntryStyle(sourceWindow)

    -- Native menus own type, session, row settings and display flags. Calling
    -- their Lua setters from addon code can taint secret-data refreshes.

    if sessionWindow.SetMovable then
        sessionWindow:SetMovable(false)
    end
    if sessionWindow.SetResizable then
        sessionWindow:SetResizable(false)
    end

    -- Do not replace SetupEntry / entry UpdateName|UpdateValue — that taints Blizzard's
    -- secret-safe Init path (sourceDisplayType comparisons in GetSourceTypeAtlasElement).

    ApplyEmbeddedWindowSkin(sessionWindow)
    ApplyEmbeddedWindowSkin(sourceWindow)
    sessionWindow:Show()
end

--- Apply layout grid to session windows inside parentFrame.
local function LayoutMeterGrid(parentFrame, layoutConfig)
    if not parentFrame or not layoutConfig or not isEmbedded then return end
    if InCombatLockdown() or not FluxBlizzardMeter:IsAvailable() then return end

    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then return end

    CancelGeometryRepair()
    local previous = geometryApplying; geometryApplying = true
    local hostParent = embeddedParentFrame or parentFrame
    local _, frameW, frameH = EmbedReferenceSize(hostParent)
    ApplyRootScaleAndSize(hostParent)
    parentFrame = dmFrame

    local nativeCount, threatCount = 0, 0
    local threatAvailable = FluxThreatMeter and FluxThreatMeter.IsAvailable and FluxThreatMeter:IsAvailable()
    local function takeSlots(list)
        local out = {}
        for i = 1, math.min(3, #(list or {})) do
            local slot = list[i]
            if type(slot) == "table" and slot.kind == "plugin" then
                if slot.plugin == FLUX_THREAT_PLUGIN and threatAvailable and threatCount == 0 then
                    out[#out + 1] = slot; threatCount = 1
                end
            elseif nativeCount < BLIZZARD_MAX_PANES then
                out[#out + 1] = slot; nativeCount = nativeCount + 1
            end
        end
        return out
    end
    local topSlots = takeSlots(layoutConfig.topSlots)
    local bottomSlots = takeSlots(layoutConfig.bottomSlots)
    if #(layoutConfig.topSlots or {}) + #(layoutConfig.bottomSlots or {}) == 0 then
        topSlots = DefaultLayoutConfig().topSlots
        nativeCount = #topSlots
    end
    embeddedNativePaneCount = 0
    embeddedThreatSelected = threatCount > 0
    local threatFrame
    if embeddedThreatSelected then
        threatFrame = FluxThreatMeter:GetFrame()
        if not threatFrame or threatEmbeddedParent ~= hostParent then
            threatFrame = FluxThreatMeter:Embed(hostParent, METER_SCALE)
            threatEmbeddedParent = threatFrame and hostParent or nil
        end
    elseif FluxThreatMeter then FluxThreatMeter:Hide() end

    local topRowFrac = tonumber(layoutConfig.topRowFrac) or 0.60
    if topRowFrac < 0.25 then topRowFrac = 0.25 end
    if topRowFrac > 0.75 then topRowFrac = 0.75 end

    local hasBottomRow = #bottomSlots > 0
    local topPad = EMBED_TOP_PAD
    local topRowBotOff = 0
    local botRowTopOff = 0
    if hasBottomRow then
        local usable = math.max(40, frameH - topPad - EMBED_ROW_GAP)
        local topH = usable * topRowFrac
        topRowBotOff = frameH - (topPad + topH)
        botRowTopOff = topPad + topH + EMBED_ROW_GAP
    end

    local windows = nativeCount > 0 and EnsureNSessionWindows(nativeCount) or {}

    wipe(embedPaneLayouts)
    wipe(selectedNativeWindows)
    wipe(missingNativeTypes)
    local outerLeft = -1
    local outerRight = 1
    local idx = 1

    local function PositionRow(slots, colFracs, topOff, botOff, bottom)
        local n = #slots
        if n == 0 then return end
        if n == 2 and (not colFracs or #colFracs ~= n) then
            local left = layoutConfig.leftColFracTop or layoutConfig.leftColFracBottom or .45
            left = (bottom and layoutConfig.leftColFracBottom or layoutConfig.leftColFracTop) or left
            colFracs = { left, 1 - left }
        end
        colFracs = NormalizeColFracs(colFracs, n)
        local cum = 0
        for i = 1, n do
            local slot = slots[i]
            local isThreat = type(slot) == "table" and slot.kind == "plugin" and slot.plugin == FLUX_THREAT_PLUGIN
            local win = isThreat and threatFrame or nil
            local wantedType = not isThreat and SlotToDamageMeterType(slot) or nil
            if not isThreat then
                for _, candidate in ipairs(windows) do
                    local currentType = candidate.GetDamageMeterType and candidate:GetDamageMeterType()
                    if not selectedNativeWindows[candidate] and PlainNumber(currentType) and currentType == wantedType then
                        win = candidate; selectedNativeWindows[candidate] = true; break
                    end
                end
                if not win then missingNativeTypes[#missingNativeTypes + 1] = wantedType end
            end
            local leftOff = outerLeft + (frameW * cum)
            cum = cum + colFracs[i]
            local rightOff
            if i == n then
                rightOff = outerRight
            else
                local splitX = outerLeft + (frameW * cum)
                rightOff = -(frameW - splitX)
            end
            if win then
                -- Details places its body frame below a separate 14-pixel title.
                -- Native/owned panes include that header; convert once to canvas units.
                local canvasLeft, canvasRight = leftOff / METER_SCALE, rightOff / METER_SCALE
                local canvasTop, canvasBottom = (topOff - PANE_HEADER_HEIGHT) / METER_SCALE, botOff / METER_SCALE
                if isThreat then
                    -- Owned pane remains a Content child; root-hidden native policy cannot hide it.
                    win:ClearAllPoints()
                    win:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", canvasLeft, -canvasTop)
                    win:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", canvasRight, canvasBottom)
                    if FluxThreatMeter.RefreshLayout then FluxThreatMeter:RefreshLayout() end
                else
                    ConfigureSessionWindowChrome(win)
                    PositionSessionWindowGrid(win, parentFrame, canvasLeft, canvasRight, canvasTop, canvasBottom)
                    embedPaneLayouts[idx] = {
                        left = canvasLeft, right = canvasRight, top = canvasTop, bot = canvasBottom,
                        window = win,
                    }
                    idx = idx + 1
                end
            end
        end
    end

    PositionRow(topSlots, layoutConfig.topColFracs, topPad, topRowBotOff, false)
    PositionRow(bottomSlots, layoutConfig.bottomColFracs, botRowTopOff, 0, true)
    embeddedNativePaneCount = idx - 1
    HideUnusedNativeWindows(dmFrame)
    local notice = table.concat(missingNativeTypes, ", ")
    if notice ~= "" and notice ~= lastConfigurationNotice then
        print("|cff00ffff[FluxUI]|r Configure the requested meter types in Blizzard's meter menu, then reopen Meter. /fbm status lists the missing views.")
    end
    lastConfigurationNotice = notice
    ShowEmbeddedRoot(dmFrame)
    if FluxMeterSkin and FluxMeterSkin.SyncNativeTimer then FluxMeterSkin:SyncNativeTimer() end
    geometryApplying = previous

    -- Do not call sessionWindow:Refresh from Flux — that taints Init/UpdateName.
    -- Blizzard refreshes on its own events (DAMAGE_METER_*).
end

--- Configure a session window for embedding (legacy offset API; used by hooks).
local function ConfigureSessionWindow(sessionWindow, damageMeterType, topOffset, bottomOffset)
    ConfigureSessionWindowChrome(sessionWindow, damageMeterType)
    if embeddedParentFrame then
        PositionSessionWindowGrid(
            sessionWindow,
            embeddedParentFrame,
            -METER_PADDING_LEFT,
            METER_PADDING_RIGHT,
            topOffset + METER_PADDING_TOP,
            bottomOffset + METER_PADDING_BOTTOM
        )
    end
end

--- Force correct position (called on layout changes)
-- @param sessionWindow The session window to reposition
-- @param topOffset Offset from top of parent
-- @param bottomOffset Offset from bottom of parent
local function ForceCorrectPosition(sessionWindow, topOffset, bottomOffset)
    if not sessionWindow or not embeddedParentFrame then return end
    
    -- Prevent taint during combat
    if InCombatLockdown() then
        return
    end
    
    -- Get window frame dimensions to ensure we don't exceed them
    local frameHeight = embeddedParentFrame:GetHeight()
    local frameWidth = embeddedParentFrame:GetWidth()
    
    -- Calculate actual available height (accounting for scale)
    local scaledHeight = frameHeight / METER_SCALE
    
    -- Ensure offsets don't exceed frame bounds
    local actualTopOffset = math.min(topOffset, scaledHeight)
    local actualBottomOffset = math.min(bottomOffset, scaledHeight)
    
    sessionWindow:ClearAllPoints()
    sessionWindow:SetPoint("TOPLEFT", embeddedParentFrame, "TOPLEFT", 
        -METER_PADDING_LEFT, 
        -(actualTopOffset + METER_PADDING_TOP))
    sessionWindow:SetPoint("BOTTOMRIGHT", embeddedParentFrame, "BOTTOMRIGHT", 
        METER_PADDING_RIGHT, 
        actualBottomOffset + METER_PADDING_BOTTOM)
    
    -- Ensure scale is maintained
    sessionWindow:SetScale(METER_SCALE)
end

--- Hook session window functions to maintain embedding
-- @param sessionWindow The session window to hook
-- @param topOffset Offset from top of parent
-- @param bottomOffset Offset from bottom of parent
local function HookSessionWindow(sessionWindow, topOffset, bottomOffset)
    if not sessionWindow then return end
    if ForeverGamepadEmbed() then
        return
    end
    
    -- Hook OnSizeChanged to maintain position and enforce bounds
    if not sessionWindow.__FluxHooked then
        sessionWindow:HookScript("OnSizeChanged", function(self)
            if isEmbedded and embeddedParentFrame and not InCombatLockdown() then
                -- Get current size
                local currentWidth, currentHeight = self:GetSize()
                local frameWidth = embeddedParentFrame:GetWidth()
                local frameHeight = embeddedParentFrame:GetHeight()
                
                -- Constrain to frame bounds (accounting for scale)
                local maxWidth = (frameWidth + METER_PADDING_LEFT + METER_PADDING_RIGHT) / METER_SCALE
                local maxHeight = (frameHeight + METER_PADDING_TOP + METER_PADDING_BOTTOM) / METER_SCALE
                
                -- Force correct position (which will constrain it)
                ForceCorrectPosition(self, topOffset, bottomOffset)
            end
        end)
        
        sessionWindow.__FluxHooked = true
    end
end

-- ---------------------------------------------------------------------------
-- EMBEDDING & DISPLAY
-- ---------------------------------------------------------------------------

--- Embed the Blizzard Damage Meter into a parent frame
-- @param parentFrame The frame to embed into (usually FluxWindowFrame.Content)
-- @param layoutConfig optional layout table from FluxMeterLayout
-- @return boolean - true if successfully embedded, false otherwise
function FluxBlizzardMeter:Embed(parentFrame, layoutConfig)
    ownsNativeVisibility = true
    pendingCleanup = false -- A newer embed request owns the next out-of-combat transition.
    if not parentFrame then
        return false
    end
    explicitlyHidden = false
    if InCombatLockdown() then
        -- Keep only the latest requested structure; never poll until combat ends.
        pendingEmbed = { parent = parentFrame, layout = layoutConfig }
        return false
    end
    pendingEmbed = nil

    if not self:IsAvailable() then
        return false
    end
    EnsureNativeEnabled()

    if not LoadDamageMeterAddon() then
        return false
    end

    if not IsMeterReady() then
        return false
    end
    CancelStartupEmbed()

    local resolvedLayout = ResolveLayoutConfig(layoutConfig)
    currentLayoutConfig = resolvedLayout

    local function DoEmbed()
        if InCombatLockdown() then
            pendingEmbed = { parent = parentFrame, layout = layoutConfig }
            return
        end

        embeddedParentFrame = parentFrame
        isEmbedded = true

        local dmFrame = GetDamageMeterFrame()
        if not dmFrame then
            isEmbedded = false
            return
        end

        WatchGeometry(dmFrame, true)
        InstallNativeVisibility()

        -- Layout panes on the expanded canvas; root scale keeps visual over Content.
        LayoutMeterGrid(parentFrame, currentLayoutConfig or resolvedLayout)

        -- Size-change: reflow grid. OnShow/OnHide keep the unparented meter with the window.
        if not parentFrame.__FluxBlizzardMeterSizeHooked then
            parentFrame.__FluxBlizzardMeterSizeHooked = true
            parentFrame:HookScript("OnSizeChanged", function()
                if isEmbedded and embeddedParentFrame and not InCombatLockdown() and currentLayoutConfig then
                    LayoutMeterGrid(embeddedParentFrame, currentLayoutConfig)
                end
            end)
            if ForeverGamepadEmbed() then
                parentFrame:HookScript("OnHide", function()
                    if not isEmbedded then
                        return
                    end
                    local dm = GetDamageMeterFrame()
                    if dm then
                        dm:Hide()
                    end
                end)
                parentFrame:HookScript("OnShow", function()
                    if not isEmbedded or InCombatLockdown() then
                        return
                    end
                    local dm = GetDamageMeterFrame()
                    if dm then
                        ShowEmbeddedRoot(dm)
                        if currentLayoutConfig then
                            LayoutMeterGrid(embeddedParentFrame, currentLayoutConfig)
                        end
                    end
                end)
            end
        end
        if ForeverGamepadEmbed() and not parentFrame:IsShown() then
            dmFrame:Hide()
        end
    end

    DoEmbed()
    return true
end

--- Push only geometry from a layout table (live splitter drag).
function FluxBlizzardMeter:SyncGeometryFromLayout(layout)
    if not isEmbedded or not embeddedParentFrame or not layout then
        return
    end
    if InCombatLockdown() then
        return
    end
    if currentLayoutConfig then
        currentLayoutConfig.topColFracs = layout.topColFracs or currentLayoutConfig.topColFracs
        currentLayoutConfig.bottomColFracs = layout.bottomColFracs or currentLayoutConfig.bottomColFracs
        if layout.topRowFrac then
            currentLayoutConfig.topRowFrac = layout.topRowFrac
        end
        -- Keep slot lists in sync if the editor changed them
        if layout.topSlots then currentLayoutConfig.topSlots = layout.topSlots end
        if layout.bottomSlots then currentLayoutConfig.bottomSlots = layout.bottomSlots end
    else
        currentLayoutConfig = ResolveLayoutConfig(layout)
    end
    LayoutMeterGrid(embeddedParentFrame, currentLayoutConfig)
end

--- Re-apply the active layout after resize / type refresh.
function FluxBlizzardMeter:RefreshEmbeddedLayout()
    if not isEmbedded or not embeddedParentFrame or not currentLayoutConfig then
        return
    end
    if InCombatLockdown() then
        return
    end
    LayoutMeterGrid(embeddedParentFrame, currentLayoutConfig)
end

--- Hide the embedded damage meter
function FluxBlizzardMeter:GetLayoutStatus()
    local missing = {}
    for i, value in ipairs(missingNativeTypes) do missing[i] = value end
    return { configurationRequired = #missing > 0, missingTypes = missing,
        visibleNativePanes = embeddedNativePaneCount or 0, nativeSettingsOwnedByBlizzard = true }
end

function FluxBlizzardMeter:Hide()
    -- Tab onHide runs before GetActiveTab changes; native callbacks must honor it.
    explicitlyHidden = true
    CancelGeometryRepair()
    if FluxThreatMeter then FluxThreatMeter:Hide() end
    if IsDetailsAddonLoaded() and FluxMeterSkin and FluxMeterSkin.ReleaseAllNative then
        FluxMeterSkin:ReleaseAllNative()
        wipe(skinnedWindows)
    end
    pendingEmbed = nil
    pendingNativeEnable = false
    CancelStartupEmbed()
    -- Keep the embedded state so Show can resume, but also hide a native root
    -- loaded before the first Meter selection when Flux owns that tab.
    if embeddedParentFrame and not pendingCleanup and FluxWindowFrame and FluxWindowFrame.IsTabEnabled
        and not FluxWindowFrame:IsTabEnabled("Meter") then self:Cleanup(); return end
    if not embeddedParentFrame and (ownsNativeVisibility == false or not VisibilityHost()) then return end
    InstallNativeVisibility()

    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then
        return
    end
    
    -- Hide the main frame (but keep embedded state)
    dmFrame:Hide()
end

--- Show the embedded damage meter (if previously hidden)
function FluxBlizzardMeter:Show()
    if not self:IsAvailable() then self:Hide(); return end
    if not embeddedParentFrame then
        return
    end
    explicitlyHidden = false
    EnsureNativeEnabled()

    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then
        return
    end
    
    -- Ensure embedded state is set
    isEmbedded = true
    
    if not InCombatLockdown() then
        if currentLayoutConfig then
            LayoutMeterGrid(embeddedParentFrame, currentLayoutConfig)
        else
            ApplyRootScaleAndSize(embeddedParentFrame)
        end
    end
    
    ShowEmbeddedRoot(dmFrame)
end

-- ---------------------------------------------------------------------------
-- CLEANUP
-- ---------------------------------------------------------------------------

--- Clean up and reset the damage meter to normal state
function FluxBlizzardMeter:Cleanup()
    CancelGeometryRepair()
    pendingEmbed = nil
    pendingNativeEnable = false
    CancelStartupEmbed()
    if InCombatLockdown() then
        pendingCleanup = true
        self:Hide()
        if FluxThreatMeter then FluxThreatMeter:Cleanup() end
        threatEmbeddedParent = nil
        if FluxMeterSkin and FluxMeterSkin.ReleaseAllNative then FluxMeterSkin:ReleaseAllNative() end
        wipe(skinnedWindows)
        return
    end
    pendingCleanup = false
    ownsNativeVisibility = false
    isEmbedded = false
    embeddedParentFrame = nil
    currentLayoutConfig = nil
    embeddedNativePaneCount = nil
    embeddedThreatSelected = false
    threatEmbeddedParent = nil
    if FluxThreatMeter then FluxThreatMeter:Cleanup() end
    if FluxMeterSkin and FluxMeterSkin.ReleaseAllNative then FluxMeterSkin:ReleaseAllNative() end
    wipe(skinnedWindows)
    wipe(embedPaneLayouts)
    wipe(selectedNativeWindows)
    wipe(missingNativeTypes)
    lastConfigurationNotice = ""
    
    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then
        return
    end
    
    -- Forever gamepad never changed the parent. SetParent here would taint the dropdowns.
    if not ForeverGamepadEmbed() then
        dmFrame:SetParent(UIParent)
    end
    local setScale = type(dmFrame.SetScaleBase) == "function" and dmFrame.SetScaleBase or dmFrame.SetScale
    if setScale then setScale(dmFrame, 1) end
    local clearPoints = type(dmFrame.ClearAllPointsBase) == "function" and dmFrame.ClearAllPointsBase or dmFrame.ClearAllPoints
    clearPoints(dmFrame)

    -- Unlock every session window (Forever allows up to 3).
    local function RestoreWindowChrome(sessionWindow)
        if not sessionWindow then
            return
        end
        if sessionWindow.SetMovable then
            sessionWindow:SetMovable(true)
        end
        if sessionWindow.SetResizable then
            sessionWindow:SetResizable(true)
        end
    end

    if dmFrame.ForEachSessionWindow then
        dmFrame:ForEachSessionWindow(RestoreWindowChrome)
    else
        RestoreWindowChrome(dmFrame:GetPrimarySessionWindow())
        if dmFrame.GetMaxSessionWindowCount and dmFrame.GetSessionWindow then
            for i = 2, dmFrame:GetMaxSessionWindowCount() do
                RestoreWindowChrome(dmFrame:GetSessionWindow(i))
            end
        elseif dmFrame.GetSessionWindow then
            RestoreWindowChrome(dmFrame:GetSessionWindow(2))
        end
    end
end

-- ---------------------------------------------------------------------------
-- INITIALIZATION
-- ---------------------------------------------------------------------------

-- Register for combat lockdown events to prevent taint
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat
if FluxBlizzardMeter:IsSupportedClient() then frame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED") end

frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "EDIT_MODE_LAYOUTS_UPDATED" then
        RequestGeometryRepair()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat - don't allow embedding changes
        -- This prevents taint issues
    elseif event == "PLAYER_REGEN_ENABLED" then
        if InCombatLockdown() then return end
        if pendingCleanup then FluxBlizzardMeter:Cleanup() end
        if pendingNativeEnable then
            pendingNativeEnable = false
            EnsureNativeEnabled()
            if isEmbedded then FluxBlizzardMeter:Show() end
        end
        local embed = pendingEmbed
        pendingEmbed = nil
        if embed then FluxBlizzardMeter:Embed(embed.parent, embed.layout) end
        if pendingStartup and StartStartupEmbed then StartStartupEmbed() end
        if geometryPending then RequestGeometryRepair() end

    end
end)

-- ---------------------------------------------------------------------------
-- STARTUP EMBEDDING (handles login/reload with Meter tab active)
-- ---------------------------------------------------------------------------

-- Retry embedding on startup
local function TryStartupEmbed(attempt, generation)
    if generation ~= startupGeneration then return end
    startupTimer = nil
    if not FluxWindowFrame or not FluxWindowFrame.GetActiveTab
        or FluxWindowFrame:GetActiveTab() ~= "Meter" then return end
    if InCombatLockdown() then
        pendingStartup = true
        return
    end
    attempt = attempt or 1
    local maxAttempts = 20 -- Try for up to 4 seconds (20 * 0.2s)
    
    -- Enable the supported feature before checking its native UI readiness.
    EnsureNativeEnabled()
    -- Use the meter only if Blizzard already loaded it.
    LoadDamageMeterAddon()
    
    -- Check if meter is ready (IsMeterReady also calls LoadDamageMeterAddon, but we call it explicitly first)
    if IsMeterReady() then
        -- Meter is ready, try to embed
        if FluxWindowFrame and FluxWindowFrame.frame and FluxWindowFrame.frame.Content then
            local layoutConfig = FluxWindowFrame.GetMeterLayoutConfig and FluxWindowFrame:GetMeterLayoutConfig()
            local success = FluxBlizzardMeter:Embed(FluxWindowFrame.frame.Content, layoutConfig)
            if success then
                -- Success! Stop retrying
                return
            end
        end
    end
    
    -- Not ready yet or embed failed, retry
    if attempt < maxAttempts then
        local function Retry() TryStartupEmbed(attempt + 1, generation) end
        if C_Timer.NewTimer then startupTimer = C_Timer.NewTimer(0.2, Retry)
        else C_Timer.After(0.2, Retry) end
    end
end

StartStartupEmbed = function()
    CancelStartupEmbed()
    TryStartupEmbed(1, startupGeneration)
end

-- Startup embedding frame (handles login/reload with Meter tab active)
local startupFrame = CreateFrame("Frame")
startupFrame:RegisterEvent("ADDON_LOADED")
startupFrame:RegisterEvent("VARIABLES_LOADED")
startupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

startupFrame:SetScript("OnEvent", function(self, event, arg1)
    InstallNativeVisibility()
    -- IsAvailable is false when Details is loaded or Blizzard_DamageMeter is absent.
    if not FluxBlizzardMeter:IsAvailable() then
        return
    end

    -- Check if Meter tab was active before logout/reload
    local wasMeterActive = false
    if _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.fluxWindowActiveTab == 2 then
        wasMeterActive = true
    end
    
    -- Meter tab was active, try to embed after initialization
    if event == "ADDON_LOADED" and arg1 == "_FluxUI" then
        -- Try to load addon early, even if tab wasn't active (might be needed later)
        -- Wait for VARIABLES_LOADED before trying to embed
        -- This ensures Blizzard_DamageMeter is fully initialized
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_DamageMeter" then
        if wasMeterActive then StartStartupEmbed() end
    elseif event == "VARIABLES_LOADED" then
        -- Variables loaded, try to embed now (if tab was active)
        if wasMeterActive then
            StartStartupEmbed()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Final attempt after entering world (if tab was active)
        if wasMeterActive then
            StartStartupEmbed()
        end
    end
    -- Settle after native layout/position restoration in the same world-entry pass,
    -- including engine updates that do not call the Lua widget-method fields.
    if event == "PLAYER_ENTERING_WORLD" then RequestGeometryRepair() end
end)

-- Debug command for testing
SLASH_FLUXBLIZZMETER1 = "/fluxblizzmeter"
SLASH_FLUXBLIZZMETER2 = "/fbm"
SlashCmdList["FLUXBLIZZMETER"] = function(msg)
    if msg == "status" then
        local status = FluxBlizzardMeter:GetLayoutStatus()
        if status.configurationRequired then
            local labels = {}
            for _, meterType in ipairs(status.missingTypes) do
                local slot = { kind = "blizzard", damageMeterType = meterType }
                labels[#labels + 1] = FluxMeterLayout and FluxMeterLayout.SlotShortLabel
                    and FluxMeterLayout.SlotShortLabel(slot) or tostring(meterType)
            end
            print("|cff00ffff[FluxUI]|r Configure these views using Blizzard's meter menu: " .. table.concat(labels, ", ") .. ". Then reopen Meter.")
        else
            print("|cff00ffff[FluxUI]|r Requested meter windows are available.")
        end
        print("  Row size, spacing, class colors, icons and combat-session choices use Blizzard's settings.")
    elseif msg == "available" then
        local available = FluxBlizzardMeter:IsAvailable()
        print("|cff00ffff[FluxBlizzardMeter]|r Available: " .. tostring(available))
        print("  SupportedClient: " .. tostring(FluxBlizzardMeter:IsSupportedClient()))
        if FluxMeterLayout and FluxMeterLayout.GetMeterBackend then
            print("  GetMeterBackend: " .. tostring(FluxMeterLayout.GetMeterBackend()))
        end
        local exists
        if C_AddOns and C_AddOns.DoesAddOnExist then
            exists = C_AddOns.DoesAddOnExist("Blizzard_DamageMeter")
        end
        print("  Blizzard_DamageMeter exists: " .. tostring(exists))
        print("  DamageMeter frame: " .. tostring(_G.DamageMeter ~= nil))
        print("  Details loaded: " .. tostring(IsDetailsAddonLoaded()))
        print("  C_DamageMeter: " .. tostring(C_DamageMeter ~= nil))
        if C_DamageMeter and C_DamageMeter.IsDamageMeterAvailable then
            local isAvail, reason = C_DamageMeter.IsDamageMeterAvailable()
            print("  IsDamageMeterAvailable: " .. tostring(isAvail))
            if reason then
                print("  Reason: " .. tostring(reason))
            end
        end
    elseif msg == "embed" then
        if FluxWindowFrame and FluxWindowFrame.frame and FluxWindowFrame.frame.Content then
            local layoutConfig = FluxWindowFrame.GetMeterLayoutConfig and FluxWindowFrame:GetMeterLayoutConfig()
            local success = FluxBlizzardMeter:Embed(FluxWindowFrame.frame.Content, layoutConfig)
            print("|cff00ffff[FluxBlizzardMeter]|r Embed: " .. tostring(success))
        else
            print("|cff00ffff[FluxBlizzardMeter]|r FluxWindowFrame not available")
        end
    elseif msg == "hide" then
        FluxBlizzardMeter:Hide()
        print("|cff00ffff[FluxBlizzardMeter]|r Hidden")
    elseif msg == "show" then
        FluxBlizzardMeter:Show()
        print("|cff00ffff[FluxBlizzardMeter]|r Shown")
    elseif msg == "cleanup" then
        FluxBlizzardMeter:Cleanup()
        print("|cff00ffff[FluxBlizzardMeter]|r Cleaned up")
    elseif msg == "api" then
        LoadDamageMeterAddon()
        local dm = _G["DamageMeter"]
        if not dm then
            print("|cff00ffff[FluxBlizzardMeter]|r api: DamageMeter frame not loaded")
        else
            local mode = "none"
            if dm.GetSessionWindow then mode = "existing native windows" end
            print("|cff00ffff[FluxBlizzardMeter]|r api: " .. mode)
            print("  HasMultiWindowSupport: " .. tostring(dm.GetSessionWindow ~= nil))
            print("  SetupSessionWindow: (windowDataIndex, windowData)")
            print("  MaxSessionWindows: " .. tostring(dm.GetMaxSessionWindowCount and dm:GetMaxSessionWindowCount()))
            print("  CurrentSessionWindows: " .. tostring(dm.GetCurrentSessionWindowCount and dm:GetCurrentSessionWindowCount()))
            local T = Enum and Enum.DamageMeterType
            if T then
                print("  DamageMeterType.EnemyDamageTaken: " .. tostring(T.EnemyDamageTaken)
                    .. " Deaths: " .. tostring(T.Deaths))
            end
        end
    else
        print("|cff00ffff[FluxBlizzardMeter]|r Commands:")
        print("  /fbm available - Check if damage meter is available")
        print("  /fbm api - Show which Blizzard multi-window API is in use")
        print("  /fbm embed - Embed into FluxWindowFrame")
        print("  /fbm hide - Hide the meter")
        print("  /fbm show - Show the meter")
        print("  /fbm cleanup - Clean up and reset")
    end
end

