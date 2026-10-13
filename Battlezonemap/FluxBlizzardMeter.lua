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
local damageMeterFrame = nil
local primarySessionWindow = nil
local secondarySessionWindow = nil

-- Meter embed sizing:
-- 1) Lay out panes in an expanded canvas (20% larger W/H than Flux Content)
-- 2) Scale the whole DamageMeter 20% smaller (0.8)
-- Visual ≈ 0.96× Content — denser chrome; layout fracs stay correct.
local METER_SCALE = 0.8
local METER_SIZE_EXPAND = 1.40
local METER_PADDING_LEFT = 0
local METER_PADDING_RIGHT = 0
local METER_PADDING_TOP = 0
local METER_PADDING_BOTTOM = 0
local EMBED_ROW_GAP = 2
local EMBED_TOP_PAD = 0
local BLIZZARD_MAX_PANES = 3

-- Forever gamepad: do not SetParent the meter onto the Flux window. That taints
-- its dropdown click into SetPreferredGamepadInteractTarget. Anchor it to the
-- Flux window instead so the panes stay inside and follow the window.
local function ForeverGamepadEmbed()
    local Flux = addonTable and addonTable.Flux or _G.Flux
    local cap = Flux and (Flux.Cap or Flux.Capabilities)
    return cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() == true
end

local function PlainScale(frame)
    if not frame or not frame.GetEffectiveScale then
        return nil
    end
    local ok, scale = pcall(frame.GetEffectiveScale, frame)
    if not ok or type(scale) ~= "number" or scale <= 0 then
        return nil
    end
    if issecretvalue and issecretvalue(scale) then
        return nil
    end
    return scale
end

-- Layout-driven embed state
local currentLayoutConfig = nil
local embedPaneLayouts = {} -- [windowIndex] = { left, right, top, bot }

-- Forever/Midnight: CanShowNewSecondarySessionWindow / ShowNewSecondarySessionWindow.
-- Older PTR builds used CanShowNewSessionWindow / ShowNewSessionWindow.

local function UsesSecondaryWindowAPI(dmFrame)
    return dmFrame and dmFrame.CanShowNewSecondarySessionWindow and dmFrame.ShowNewSecondarySessionWindow
end

local function UsesLegacyWindowAPI(dmFrame)
    return dmFrame and dmFrame.CanShowNewSessionWindow and dmFrame.ShowNewSessionWindow
end

--- Check if the DamageMeter frame has multi-window API support.
-- @param dmFrame DamageMeter frame from GetDamageMeterFrame()
-- @return boolean - true if secondary window can be created
local function HasMultiWindowSupport(dmFrame)
    if not dmFrame or not dmFrame.GetCurrentSessionWindowCount or not dmFrame.GetSessionWindow then
        return false
    end
    return UsesSecondaryWindowAPI(dmFrame) or UsesLegacyWindowAPI(dmFrame)
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

--- Secret-safe helpers. When Flux embeds DamageMeter, OnShow/event registration runs
--- tainted; Blizzard entry code then cannot compare secret fields. Mirror Blizzard logic
--- but gate compares with canaccessvalue (works untainted; skips when tainted+secret).
local function FluxCanAccess(v)
    if canaccessvalue then
        return canaccessvalue(v) and true or false
    end
    if issecretvalue then
        return not issecretvalue(v)
    end
    return true
end

local function FluxSecretSafeEquals(a, b)
    if not FluxCanAccess(a) or not FluxCanAccess(b) then
        return false
    end
    return a == b
end

-- Standalone secret-safe implementations (bound onto mixin + each pooled entry instance).
-- Reference: wow-ui-source-forever Blizzard_DamageMeter/DamageMeterEntry.lua.

local function SafeGetSourceTypeAtlasElement(self)
    -- When class color is off, bars are colored by source type and don't need team icons.
    if not self.isClassColorDesired then
        return nil
    end
    local SourceDisplayType = Enum and Enum.DamageMeterSourceDisplayType
    local enemyType = SourceDisplayType and SourceDisplayType.Enemy
    if enemyType == nil or not FluxSecretSafeEquals(self.sourceDisplayType, enemyType) then
        return nil
    end
    local faction = self.factionGroup
    if FluxCanAccess(faction) and PLAYER_FACTION_GROUP then
        if faction == PLAYER_FACTION_GROUP[0] then
            return "HordeSymbol"
        elseif faction == PLAYER_FACTION_GROUP[1] then
            return "AllianceSymbol"
        end
    end
    return nil
end

local function SafeUpdateName(self)
    local nameFontString = self:GetName()
    if not nameFontString then
        return
    end
    local ok, text = pcall(function()
        return self:GetNameText()
    end)
    if not ok then
        return
    end
    if not FluxCanAccess(text) then
        nameFontString:SetText(text)
        self.nameText = nil
    elseif text ~= self.nameText then
        self.nameText = text
        nameFontString:SetText(text or "")
    end
    -- isLocalPlayer is NeverSecret.
    if self.isLocalPlayer == true then
        local g = GREEN_FONT_COLOR
        nameFontString:SetTextColor(g.r, g.g, g.b)
    else
        nameFontString:SetTextColor(1, 1, 1)
    end
end

-- Current Blizzard UpdateValue only sets the value fontstring; UpdateStatusBar is separate.
local function SafeUpdateValue(self)
    local valueFontString = self:GetValue()
    if not valueFontString then
        return
    end
    local ok, text = pcall(function()
        return self:GetValueText()
    end)
    if ok and text ~= nil then
        valueFontString:SetText(text)
    else
        valueFontString:SetText("")
    end
end

local function SafeUpdateStatusBar(self)
    local statusBar = self:GetStatusBar()
    if not statusBar then
        return
    end
    local maxValue, value
    if self.GetMaxStatusValue then
        local ok, v = pcall(self.GetMaxStatusValue, self)
        if ok then
            maxValue = v
        end
    end
    if maxValue == nil then
        maxValue = self.maxValue
    end
    if self.GetStatusValue then
        local ok, v = pcall(self.GetStatusValue, self)
        if ok then
            value = v
        end
    end
    if value == nil then
        value = self.value
    end
    if not FluxCanAccess(maxValue) or not FluxCanAccess(value) then
        statusBar:SetMinMaxValues(0, maxValue)
        statusBar:SetValue(value)
    else
        statusBar:SetMinMaxValues(0, maxValue or 0)
        statusBar:SetValue(value or 0)
    end
end

local originalGetDesiredBarColor = nil

local function SafeGetDesiredBarColor(self)
    if self.isClassColorDesired then
        if originalGetDesiredBarColor then
            local ok, color = pcall(originalGetDesiredBarColor, self)
            if ok then
                return color
            end
        end
        if self.GetDefaultStatusBarColor then
            return self:GetDefaultStatusBarColor()
        end
        return nil
    end
    local SourceDisplayType = Enum and Enum.DamageMeterSourceDisplayType
    local allyType = SourceDisplayType and SourceDisplayType.Ally
    local enemyType = SourceDisplayType and SourceDisplayType.Enemy
    if allyType and FluxSecretSafeEquals(self.sourceDisplayType, allyType) then
        if self.GetAllyStatusBarColor then
            return self:GetAllyStatusBarColor()
        end
    elseif enemyType and FluxSecretSafeEquals(self.sourceDisplayType, enemyType) then
        if self.GetEnemyStatusBarColor then
            return self:GetEnemyStatusBarColor()
        end
    end
    if self.GetDefaultStatusBarColor then
        return self:GetDefaultStatusBarColor()
    end
    if originalGetDesiredBarColor then
        return originalGetDesiredBarColor(self)
    end
    return nil
end

local function ApplySecretSafeMethodsToEntry(frame)
    if not frame then
        return
    end
    -- Always rebind: pooled frames may still hold Blizzard originals from Mixin copy.
    frame.GetSourceTypeAtlasElement = SafeGetSourceTypeAtlasElement
    frame.UpdateName = SafeUpdateName
    frame.UpdateValue = SafeUpdateValue
    frame.UpdateStatusBar = SafeUpdateStatusBar
    frame.GetDesiredBarColor = SafeGetDesiredBarColor
    frame.__FluxSecretSafeEntry = true
end

local function InstallSecretSafeMethodsOnMixin()
    if not DamageMeterEntryMixin then
        return false
    end
    if not originalGetDesiredBarColor and DamageMeterEntryMixin.GetDesiredBarColor
        and DamageMeterEntryMixin.GetDesiredBarColor ~= SafeGetDesiredBarColor then
        originalGetDesiredBarColor = DamageMeterEntryMixin.GetDesiredBarColor
    end
    -- Always install, even if GetSourceTypeAtlasElement was previously nil on older builds.
    DamageMeterEntryMixin.GetSourceTypeAtlasElement = SafeGetSourceTypeAtlasElement
    DamageMeterEntryMixin.UpdateName = SafeUpdateName
    DamageMeterEntryMixin.UpdateValue = SafeUpdateValue
    DamageMeterEntryMixin.UpdateStatusBar = SafeUpdateStatusBar
    DamageMeterEntryMixin.GetDesiredBarColor = SafeGetDesiredBarColor
    return DamageMeterEntryMixin.GetSourceTypeAtlasElement == SafeGetSourceTypeAtlasElement
end

local function WrapEntryInitMethods()
    if DamageMeterSourceEntryMixin and DamageMeterSourceEntryMixin.Init
        and not DamageMeterSourceEntryMixin._FluxSecretSafeInitWrapped then
        local originalInit = DamageMeterSourceEntryMixin.Init
        DamageMeterSourceEntryMixin.Init = function(self, combatSource)
            ApplySecretSafeMethodsToEntry(self)
            return originalInit(self, combatSource)
        end
        DamageMeterSourceEntryMixin._FluxSecretSafeInitWrapped = true
    end
    if DamageMeterSpellEntryMixin and DamageMeterSpellEntryMixin.Init
        and not DamageMeterSpellEntryMixin._FluxSecretSafeInitWrapped then
        local originalSpellInit = DamageMeterSpellEntryMixin.Init
        DamageMeterSpellEntryMixin.Init = function(self, combatSpell)
            ApplySecretSafeMethodsToEntry(self)
            return originalSpellInit(self, combatSpell)
        end
        DamageMeterSpellEntryMixin._FluxSecretSafeInitWrapped = true
    end
end

--- Patch already-pooled ScrollBox entry frames (Mixin copied Blizzard originals onto them).
local function PatchPooledEntryFrames()
    local dmFrame = _G["DamageMeter"]
    if not dmFrame then
        return
    end
    local function patchWindow(sessionWindow)
        if not sessionWindow then
            return
        end
        if sessionWindow.ForEachEntryFrame then
            sessionWindow:ForEachEntryFrame(function(frame)
                ApplySecretSafeMethodsToEntry(frame)
            end)
        elseif sessionWindow.EnumerateEntryFrames then
            for _, frame in sessionWindow:EnumerateEntryFrames() do
                ApplySecretSafeMethodsToEntry(frame)
            end
        end
        local sourceWindow = sessionWindow.GetSourceWindow and sessionWindow:GetSourceWindow()
        if sourceWindow and sourceWindow.ForEachEntryFrame then
            sourceWindow:ForEachEntryFrame(function(frame)
                ApplySecretSafeMethodsToEntry(frame)
            end)
        end
    end
    if dmFrame.ForEachSessionWindow then
        dmFrame:ForEachSessionWindow(patchWindow)
    elseif dmFrame.GetPrimarySessionWindow then
        patchWindow(dmFrame:GetPrimarySessionWindow())
        if dmFrame.GetMaxSessionWindowCount and dmFrame.GetSessionWindow then
            for i = 2, dmFrame:GetMaxSessionWindowCount() do
                patchWindow(dmFrame:GetSessionWindow(i))
            end
        end
    end
end

--- Keep Blizzard DamageMeter entry updates working while embedded (tainted).
local function PatchDamageMeterEntryMethods()
    if not DamageMeterEntryMixin then
        return
    end

    if DamageMeterEntryMixin._FluxSecretSafePatched then
        WrapEntryInitMethods()
        PatchPooledEntryFrames()
        return
    end

    -- Undo older Flux replacements if present from a prior load in-session.
    if DamageMeterEntryMixin._FluxOriginalUpdateName then
        DamageMeterEntryMixin.UpdateName = DamageMeterEntryMixin._FluxOriginalUpdateName
        DamageMeterEntryMixin._FluxOriginalUpdateName = nil
    end
    if DamageMeterEntryMixin._FluxOriginalUpdateValue then
        DamageMeterEntryMixin.UpdateValue = DamageMeterEntryMixin._FluxOriginalUpdateValue
        DamageMeterEntryMixin._FluxOriginalUpdateValue = nil
    end
    DamageMeterEntryMixin._FluxPatched = nil
    DamageMeterEntryMixin._FluxNameColorHooked = nil

    local installed = InstallSecretSafeMethodsOnMixin()
    WrapEntryInitMethods()

    -- Only mark complete after GetSourceTypeAtlasElement is our safe impl (critical path).
    if installed then
        DamageMeterEntryMixin._FluxSecretSafePatched = true
        PatchPooledEntryFrames()
    else
        DamageMeterEntryMixin._FluxSecretSafePatched = nil
    end
end

--- Session duration can be secret while tainted; use a Blizzard-compatible safe setter.
local function PatchDamageMeterSessionWindowMethods()
    if ForeverGamepadEmbed() then
        return
    end
    if not DamageMeterSessionWindowMixin then
        return
    end
    if DamageMeterSessionWindowMixin._FluxDurationHooked then
        return
    end

    if DamageMeterSessionWindowMixin._FluxOriginalSetSessionDuration then
        DamageMeterSessionWindowMixin.SetSessionDuration = DamageMeterSessionWindowMixin._FluxOriginalSetSessionDuration
        DamageMeterSessionWindowMixin._FluxOriginalSetSessionDuration = nil
    end
    DamageMeterSessionWindowMixin._FluxPatched = nil

    if not DamageMeterSessionWindowMixin.SetSessionDuration then
        return
    end

    DamageMeterSessionWindowMixin.SetSessionDuration = function(self, durationSeconds)
        local sessionTimer = self.GetSessionTimerFontString and self:GetSessionTimerFontString()
        if not sessionTimer then
            return
        end
        if type(durationSeconds) ~= "number" then
            sessionTimer:SetText("")
            return
        end
        if not FluxCanAccess(durationSeconds) then
            sessionTimer:SetText("[--:--] ")
            return
        end
        local success, timerText = pcall(function()
            return ("[%s] "):format(SecondsToClock(durationSeconds))
        end)
        if success then
            sessionTimer:SetText(timerText)
        else
            sessionTimer:SetText("[--:--] ")
        end
    end
    DamageMeterSessionWindowMixin._FluxDurationHooked = true
    DamageMeterSessionWindowMixin._FluxPatched = true
end

-- Do not wrap DamageMeterMixin.SetupSessionWindow — that permanently taints window setup.
local function PatchSessionWindowInstance(sessionWindow)
    if ForeverGamepadEmbed() then
        return
    end
    if not sessionWindow or sessionWindow.__FluxSetSessionDurationPatched then
        return
    end
    if DamageMeterSessionWindowMixin and DamageMeterSessionWindowMixin.SetSessionDuration then
        sessionWindow.SetSessionDuration = DamageMeterSessionWindowMixin.SetSessionDuration
    end
    sessionWindow.__FluxSetSessionDurationPatched = true
end

local function IsSecretSafeEntryPatchComplete()
    if not DamageMeterEntryMixin or not DamageMeterEntryMixin._FluxSecretSafePatched then
        return false
    end
    -- Init wraps must land once Source/Spell mixins exist (may load after EntryMixin).
    if DamageMeterSourceEntryMixin and DamageMeterSourceEntryMixin.Init
        and not DamageMeterSourceEntryMixin._FluxSecretSafeInitWrapped then
        return false
    end
    if DamageMeterSpellEntryMixin and DamageMeterSpellEntryMixin.Init
        and not DamageMeterSpellEntryMixin._FluxSecretSafeInitWrapped then
        return false
    end
    return true
end

-- Retry patching with a delay to catch late-loading cases
local function RetryPatchDamageMeterEntryMethods(attempt)
    attempt = attempt or 1
    local maxAttempts = 10

    -- Always invoke: when already flagged, still wraps Init + rebinds pooled frames.
    PatchDamageMeterEntryMethods()

    if DamageMeterSessionWindowMixin and not DamageMeterSessionWindowMixin._FluxDurationHooked then
        PatchDamageMeterSessionWindowMethods()
    end

    if attempt < maxAttempts and (not IsSecretSafeEntryPatchComplete()
        or not DamageMeterSessionWindowMixin or not DamageMeterSessionWindowMixin._FluxDurationHooked) then
        C_Timer.After(0.1, function()
            RetryPatchDamageMeterEntryMethods(attempt + 1)
        end)
    end
end

--- Use the Blizzard Damage Meter only when Blizzard already loaded it.
-- @return boolean - true if loaded successfully, false otherwise
local function LoadDamageMeterAddon()
    if not HasBlizzardDamageMeterClient() then
        return false
    end
    if _G["DamageMeter"] then
        PatchDamageMeterEntryMethods()
        PatchDamageMeterSessionWindowMethods()
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
    if not dmFrame then
        return windows
    end

    local maxCount = BLIZZARD_MAX_PANES
    if dmFrame.GetMaxSessionWindowCount then
        maxCount = dmFrame:GetMaxSessionWindowCount() or BLIZZARD_MAX_PANES
    end
    count = math.max(1, math.min(count or 1, maxCount))

    local function tryShowNew()
        -- Creating a pane from Flux runs its dropdown SetupMenu as _FluxUI.
        if ForeverGamepadEmbed() then
            return false
        end
        if UsesSecondaryWindowAPI(dmFrame) then
            if dmFrame:CanShowNewSecondarySessionWindow() then
                dmFrame:ShowNewSecondarySessionWindow()
                return true
            end
        elseif UsesLegacyWindowAPI(dmFrame) then
            if dmFrame:CanShowNewSessionWindow() then
                dmFrame:ShowNewSessionWindow()
                return true
            end
        end
        return false
    end

    local primary = dmFrame.GetPrimarySessionWindow and dmFrame:GetPrimarySessionWindow()
    if primary then
        PatchSessionWindowInstance(primary)
        if not primary:IsShown() then
            primary:Show()
        end
    end

    local safety = 0
    while true do
        safety = safety + 1
        if safety > 8 then break end
        local shown = 0
        if dmFrame.GetCurrentSessionWindowCount then
            shown = dmFrame:GetCurrentSessionWindowCount() or 0
        elseif dmFrame.ForEachSessionWindow then
            dmFrame:ForEachSessionWindow(function(sw)
                if sw and sw:IsShown() then shown = shown + 1 end
            end)
        end
        if shown >= count then break end
        if not tryShowNew() then break end
    end

    for i = 1, count do
        local win = dmFrame.GetSessionWindow and dmFrame:GetSessionWindow(i)
        if not win and i == 1 then
            win = primary
        end
        if win then
            if not win:IsShown() then
                win:Show()
            end
            PatchSessionWindowInstance(win)
            windows[i] = win
        end
    end

    if dmFrame.GetMaxSessionWindowCount and dmFrame.HideSessionWindow then
        for i = count + 1, dmFrame:GetMaxSessionWindowCount() do
            local extra = dmFrame:GetSessionWindow(i)
            if extra and extra:IsShown() and dmFrame:CanHideSessionWindow(extra) then
                dmFrame:HideSessionWindow(extra)
            end
        end
    end

    primarySessionWindow = windows[1]
    secondarySessionWindow = windows[2]
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
local function GetSessionWindowMinimizeButton(sessionWindow)
    if not sessionWindow then
        return nil
    end
    if sessionWindow.GetMinimizeButton then
        return sessionWindow:GetMinimizeButton()
    end
    return sessionWindow.MinimizeButton
end

local function GetSessionWindowResizeButton(sessionWindow)
    if not sessionWindow then
        return nil
    end
    if sessionWindow.GetResizeButton then
        return sessionWindow:GetResizeButton()
    end
    return sessionWindow.ResizeButton
end

local function ApplyEmbeddedNoMinimize(sessionWindow, dmFrame)
    if not sessionWindow or not dmFrame then
        return
    end
    if dmFrame.SetSessionWindowMinimized then
        pcall(function()
            dmFrame:SetSessionWindowMinimized(sessionWindow, false)
        end)
    elseif sessionWindow.SetMinimized then
        pcall(function()
            sessionWindow:SetMinimized(false)
        end)
    end
    local minBtn = GetSessionWindowMinimizeButton(sessionWindow)
    if minBtn and minBtn.Hide then
        minBtn:Hide()
    end
    local resizeBtn = GetSessionWindowResizeButton(sessionWindow)
    if resizeBtn and resizeBtn.Hide then
        resizeBtn:Hide()
    end
end

local function RestoreSessionWindowMinimizeButton(sessionWindow)
    local minBtn = GetSessionWindowMinimizeButton(sessionWindow)
    if minBtn and minBtn.Show then
        minBtn:Show()
    end
    local resizeBtn = GetSessionWindowResizeButton(sessionWindow)
    if resizeBtn and resizeBtn.Show then
        resizeBtn:Show()
    end
end

--- Resolve a layout slot to Enum.DamageMeterType
local function SlotToDamageMeterType(slot)
    local T = Enum and Enum.DamageMeterType
    local fallback = T and T.DamageDone or 0
    if type(slot) ~= "table" then
        return fallback
    end
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
    sessionWindow:ClearAllPoints()
    sessionWindow:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", leftOff, -topOff)
    sessionWindow:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", rightOff, botOff)
    if sessionWindow.SetScale then
        sessionWindow:SetScale(1)
    end
end

--- Size/scale the DamageMeter root so panes look denser but still cover Flux Content.
-- Canvas = Content × METER_SIZE_EXPAND, then SetScale(METER_SCALE), centered on Content.
local function ApplyRootScaleAndSize(parentFrame)
    if not parentFrame or InCombatLockdown() then return end
    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then return end

    local pw = parentFrame:GetWidth() or 0
    local ph = parentFrame:GetHeight() or 0
    if pw < 40 then
        pw = (_G.FluxWindowFrame and _G.FluxWindowFrame.WINDOW_WIDTH) or 300
    end
    if ph < 40 then
        ph = (_G.FluxWindowFrame and _G.FluxWindowFrame.WINDOW_HEIGHT) or 270
    end

    local layoutW = pw * METER_SIZE_EXPAND
    local layoutH = ph * METER_SIZE_EXPAND

    if ForeverGamepadEmbed() then
        local hostScale = PlainScale(parentFrame)
        local holderScale = PlainScale(dmFrame:GetParent())
        if hostScale and holderScale then
            dmFrame:SetScale((hostScale * METER_SCALE) / holderScale)
        else
            dmFrame:SetScale(METER_SCALE)
        end
        dmFrame:ClearAllPoints()
        dmFrame:SetSize(layoutW, layoutH)
        dmFrame:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
        if parentFrame.GetFrameStrata and dmFrame.SetFrameStrata then
            dmFrame:SetFrameStrata(parentFrame:GetFrameStrata())
        end
        if parentFrame.GetFrameLevel and dmFrame.SetFrameLevel then
            dmFrame:SetFrameLevel((parentFrame:GetFrameLevel() or 0) + 20)
        end
        return
    end

    dmFrame:SetParent(parentFrame)
    dmFrame:SetScale(METER_SCALE)
    dmFrame:ClearAllPoints()
    -- CENTER + explicit size: after scale, visual ≈ Content × (EXPAND×SCALE) and stays centered.
    dmFrame:SetSize(layoutW, layoutH)
    dmFrame:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
end

--- Configure chrome/type for an embedded session window (position applied separately).
local function ConfigureSessionWindowChrome(sessionWindow, damageMeterType)
    if not sessionWindow then return end
    if InCombatLockdown() then return end

    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then return end

    if damageMeterType ~= nil then
        dmFrame:SetSessionWindowDamageMeterType(sessionWindow, damageMeterType)
    end

    sessionWindow:SetUseClassColor(true)
    sessionWindow:SetShowBarIcons(true)
    dmFrame:SetSessionWindowSessionID(sessionWindow, Enum.DamageMeterSessionType.Overall, nil)

    if sessionWindow.SetMovable then
        sessionWindow:SetMovable(false)
    end
    if sessionWindow.SetResizable then
        sessionWindow:SetResizable(false)
    end
    if not ForeverGamepadEmbed() and dmFrame.SetSessionWindowLocked then
        dmFrame:SetSessionWindowLocked(sessionWindow, true)
    end
    ApplyEmbeddedNoMinimize(sessionWindow, dmFrame)

    -- Do not replace SetupEntry / entry UpdateName|UpdateValue — that taints Blizzard's
    -- secret-safe Init path (sourceDisplayType comparisons in GetSourceTypeAtlasElement).

    PatchSessionWindowInstance(sessionWindow)
    sessionWindow:Show()
end

--- Apply layout grid to session windows inside parentFrame.
local function LayoutMeterGrid(parentFrame, layoutConfig)
    if not parentFrame or not layoutConfig or not isEmbedded then return end
    if InCombatLockdown() then return end

    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then return end

    -- Expand + scale the root first so layout math uses the pre-scale canvas size.
    local hostParent = embeddedParentFrame or parentFrame
    ApplyRootScaleAndSize(hostParent)
    -- Lay out against dmFrame (expanded canvas), not Content.
    parentFrame = dmFrame

    local topSlots = layoutConfig.topSlots or {}
    local bottomSlots = layoutConfig.bottomSlots or {}
    if #topSlots > 3 then topSlots = { topSlots[1], topSlots[2], topSlots[3] } end
    if #bottomSlots > 3 then bottomSlots = { bottomSlots[1], bottomSlots[2], bottomSlots[3] } end

    local totalSlots = #topSlots + #bottomSlots
    if totalSlots < 1 then
        topSlots = DefaultLayoutConfig().topSlots
        bottomSlots = {}
        totalSlots = 1
    end
    if totalSlots > BLIZZARD_MAX_PANES then
        -- Prefer keeping top row; drop bottom extras then top extras.
        while #topSlots + #bottomSlots > BLIZZARD_MAX_PANES and #bottomSlots > 0 do
            table.remove(bottomSlots)
        end
        while #topSlots + #bottomSlots > BLIZZARD_MAX_PANES and #topSlots > 1 do
            table.remove(topSlots)
        end
        totalSlots = #topSlots + #bottomSlots
    end

    local topRowFrac = tonumber(layoutConfig.topRowFrac) or 0.60
    if topRowFrac < 0.25 then topRowFrac = 0.25 end
    if topRowFrac > 0.75 then topRowFrac = 0.75 end

    local frameH = parentFrame:GetHeight() or 270
    if frameH < 80 then
        frameH = (_G.FluxWindowFrame and _G.FluxWindowFrame.WINDOW_HEIGHT) or 270
        frameH = frameH * METER_SIZE_EXPAND
    end
    local frameW = parentFrame:GetWidth() or 300
    if frameW < 40 then
        frameW = (_G.FluxWindowFrame and _G.FluxWindowFrame.WINDOW_WIDTH) or 300
        frameW = frameW * METER_SIZE_EXPAND
    end

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

    local windows = EnsureNSessionWindows(totalSlots)
    if not windows or #windows < 1 then return end

    wipe(embedPaneLayouts)
    local outerLeft = 0
    local outerRight = 0
    local idx = 1

    local function PositionRow(slots, colFracs, topOff, botOff)
        local n = #slots
        if n == 0 then return end
        colFracs = NormalizeColFracs(colFracs, n)
        local cum = 0
        for i = 1, n do
            local win = windows[idx]
            if not win then break end
            local leftOff = outerLeft + (frameW * cum)
            cum = cum + colFracs[i]
            local rightOff
            if i == n then
                rightOff = outerRight
            else
                local splitX = outerLeft + (frameW * cum)
                rightOff = -(frameW - splitX)
            end
            ConfigureSessionWindowChrome(win, SlotToDamageMeterType(slots[i]))
            PositionSessionWindowGrid(win, parentFrame, leftOff, rightOff, topOff, botOff)
            embedPaneLayouts[idx] = {
                left = leftOff, right = rightOff, top = topOff, bot = botOff,
                damageMeterType = SlotToDamageMeterType(slots[i]),
            }
            idx = idx + 1
        end
    end

    PositionRow(topSlots, layoutConfig.topColFracs, topPad, topRowBotOff)
    PositionRow(bottomSlots, layoutConfig.bottomColFracs, botRowTopOff, 0)

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
    if not parentFrame then
        return false
    end

    if not self:IsAvailable() then
        return false
    end

    if not LoadDamageMeterAddon() then
        return false
    end

    PatchDamageMeterEntryMethods()
    PatchDamageMeterSessionWindowMethods()

    if not IsMeterReady() then
        return false
    end

    local resolvedLayout = ResolveLayoutConfig(layoutConfig)
    currentLayoutConfig = resolvedLayout

    local function DoEmbed()
        if InCombatLockdown() then
            C_Timer.After(0.1, DoEmbed)
            return
        end

        embeddedParentFrame = parentFrame
        isEmbedded = true

        local dmFrame = GetDamageMeterFrame()
        if not dmFrame then
            isEmbedded = false
            return
        end

        if not dmFrame.__OriginalShouldBeShown then
            dmFrame.__OriginalShouldBeShown = dmFrame.ShouldBeShown
            dmFrame.ShouldBeShown = function(self)
                if isEmbedded then
                    return true
                end
                return self:__OriginalShouldBeShown()
            end
        end

        if not dmFrame.__OriginalUpdateShownState then
            dmFrame.__OriginalUpdateShownState = dmFrame.UpdateShownState
            dmFrame.UpdateShownState = function(self)
                if isEmbedded then
                    return
                end
                return self:__OriginalUpdateShownState()
            end
        end

        if dmFrame.SetVisibility then
            dmFrame:SetVisibility(Enum.DamageMeterVisibility.Always)
        elseif dmFrame.visibility ~= nil then
            dmFrame.visibility = Enum.DamageMeterVisibility.Always
        end

        -- Root is sized/scaled in LayoutMeterGrid via ApplyRootScaleAndSize.
        dmFrame:Show()

        if dmFrame.ForEachSessionWindow then
            dmFrame:ForEachSessionWindow(function(sessionWindow)
                if sessionWindow then
                    PatchSessionWindowInstance(sessionWindow)
                    ApplyEmbeddedNoMinimize(sessionWindow, dmFrame)
                end
            end)
        end

        -- Layout panes on the expanded canvas; root scale keeps visual over Content.
        LayoutMeterGrid(parentFrame, currentLayoutConfig or resolvedLayout)

        -- Re-bind secret-safe methods on pooled entry frames after windows are shown.
        PatchDamageMeterEntryMethods()
        PatchPooledEntryFrames()

        -- Size-change: reflow grid. OnShow/OnHide keep the unparented meter with the window.
        if not parentFrame.__FluxBlizzardMeterSizeHooked then
            parentFrame.__FluxBlizzardMeterSizeHooked = true
            parentFrame:HookScript("OnSizeChanged", function()
                if isEmbedded and embeddedParentFrame and not InCombatLockdown() and currentLayoutConfig then
                    LayoutMeterGrid(embeddedParentFrame, currentLayoutConfig)
                    PatchPooledEntryFrames()
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
                        dm:Show()
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
function FluxBlizzardMeter:Hide()
    -- Don't reset isEmbedded - keep the embedded state so Show() can work
    -- Just hide the frame when switching away from Meter tab
    if not embeddedParentFrame then
        return
    end
    
    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then
        return
    end
    
    -- Hide the main frame (but keep embedded state)
    dmFrame:Hide()
end

--- Show the embedded damage meter (if previously hidden)
function FluxBlizzardMeter:Show()
    if not embeddedParentFrame then
        return
    end
    
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
    
    -- Show the main frame
    dmFrame:Show()
end

-- ---------------------------------------------------------------------------
-- CLEANUP
-- ---------------------------------------------------------------------------

--- Clean up and reset the damage meter to normal state
function FluxBlizzardMeter:Cleanup()
    isEmbedded = false
    embeddedParentFrame = nil
    currentLayoutConfig = nil
    wipe(embedPaneLayouts)
    
    local dmFrame = GetDamageMeterFrame()
    if not dmFrame then
        return
    end
    
    -- Forever gamepad never changed the parent. SetParent here would taint the dropdowns.
    if not ForeverGamepadEmbed() then
        dmFrame:SetParent(UIParent)
    end
    if dmFrame.SetScale then
        dmFrame:SetScale(1)
    end
    dmFrame:ClearAllPoints()
    
    -- Restore original ShouldBeShown if hooked
    if dmFrame.__OriginalShouldBeShown then
        dmFrame.ShouldBeShown = dmFrame.__OriginalShouldBeShown
        dmFrame.__OriginalShouldBeShown = nil
    end
    
    -- Restore original UpdateShownState if hooked
    if dmFrame.__OriginalUpdateShownState then
        dmFrame.UpdateShownState = dmFrame.__OriginalUpdateShownState
        dmFrame.__OriginalUpdateShownState = nil
    end
    
    -- Unlock every session window (Forever allows up to 3).
    local function RestoreWindowChrome(sessionWindow)
        if not sessionWindow then
            return
        end
        if not ForeverGamepadEmbed() and dmFrame.SetSessionWindowLocked then
            dmFrame:SetSessionWindowLocked(sessionWindow, false)
        end
        if sessionWindow.SetMovable then
            sessionWindow:SetMovable(true)
        end
        if sessionWindow.SetResizable then
            sessionWindow:SetResizable(true)
        end
        RestoreSessionWindowMinimizeButton(sessionWindow)
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
frame:RegisterEvent("ADDON_LOADED") -- For patching when DamageMeter loads

frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat - don't allow embedding changes
        -- This prevents taint issues
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Left combat - safe to make changes again if needed
    elseif event == "ADDON_LOADED" and addonName == "Blizzard_DamageMeter" then
        -- Patch entry methods when DamageMeter addon loads
        PatchDamageMeterEntryMethods()
        PatchDamageMeterSessionWindowMethods()
        -- Also retry with delays to catch late-loading mixins
        RetryPatchDamageMeterEntryMethods()
    end
end)

-- ---------------------------------------------------------------------------
-- STARTUP EMBEDDING (handles login/reload with Meter tab active)
-- ---------------------------------------------------------------------------

-- Retry embedding on startup
local function TryStartupEmbed(attempt)
    attempt = attempt or 1
    local maxAttempts = 20 -- Try for up to 4 seconds (20 * 0.2s)
    
    -- Patch if Blizzard already loaded the meter (never LoadAddOn from Flux).
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
        C_Timer.After(0.2, function()
            TryStartupEmbed(attempt + 1)
        end)
    end
end

-- Startup embedding frame (handles login/reload with Meter tab active)
local startupFrame = CreateFrame("Frame")
startupFrame:RegisterEvent("ADDON_LOADED")
startupFrame:RegisterEvent("VARIABLES_LOADED")
startupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

startupFrame:SetScript("OnEvent", function(self, event, arg1)
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
    elseif event == "VARIABLES_LOADED" then
        -- Variables loaded, try to embed now (if tab was active)
        if wasMeterActive then
            TryStartupEmbed()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Final attempt after entering world (if tab was active)
        if wasMeterActive then
            TryStartupEmbed()
        end
    end
end)

-- Debug command for testing
SLASH_FLUXBLIZZMETER1 = "/fluxblizzmeter"
SLASH_FLUXBLIZZMETER2 = "/fbm"
SlashCmdList["FLUXBLIZZMETER"] = function(msg)
    if msg == "available" then
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
            if UsesSecondaryWindowAPI(dm) then
                mode = "secondary (Forever/Midnight)"
            elseif UsesLegacyWindowAPI(dm) then
                mode = "legacy (ShowNewSessionWindow)"
            end
            print("|cff00ffff[FluxBlizzardMeter]|r api: " .. mode)
            print("  HasMultiWindowSupport: " .. tostring(HasMultiWindowSupport(dm)))
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

