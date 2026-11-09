-- FluxFlyoutCore.lua
-- Main initialization and event handling for custom flyout system
-- Supports all WoW clients: Retail, Classic, Legacy
local addonName, ns = ...

local FluxFlyout = {}
_G.FluxFlyout = FluxFlyout

-- Pre-Dragonflight detection (for conditional logic if needed)
local isPreDF = FLUX_API and FLUX_API.isPreDF or false
FluxFlyout.isPreDF = isPreDF

-- ---------------------------------------------------------------------------
-- SLASH COMMAND REGISTRATION
-- ---------------------------------------------------------------------------
-- Register /flyout as a silent handler to prevent WoW's macro parser from
-- treating the rest of the line as macro conditionals (which would cause
-- "Unknown macro option" errors like "Unknown macro option: item").
-- The actual flyout logic is handled via OnClick hooks on buttons, not via
-- slash command execution.
SLASH_FLYOUT1 = "/flyout"
SlashCmdList["FLYOUT"] = function(msg)
    -- Intentionally empty - just prevents WoW from parsing the arguments
    -- as macro conditionals. The flyout display is triggered by button hooks.
end

-- ---------------------------------------------------------------------------
-- STATE TRACKING
-- ---------------------------------------------------------------------------

-- Cache of parsed flyout configurations by macro ID
local macroCache = {}

-- Cache of generated actions by macro ID
local actionCache = {}

-- Dynamic content tracking
local dynamicMacros = {
    -- macroId = { dynamicType = "bag"|"spell", config = {...} }
}

-- Registered buttons that may have flyouts
local registeredButtons = {}

-- Is the system initialized?
local isInitialized = false

-- Click-phase dedupe (prevents open+close on double OnClick within one physical click)
local flyoutOpenDedupe = {
    button = nil,
    time = 0,
}

local FLYOUT_OPEN_DEDUPE_SEC = 0.05

--- Parse macrotext for a /flyout line appropriate to the triggering mouse button.
--- Skips [btn:2] lines on left-click hooks, etc.
--- @param macroBody string
--- @param mouseButton string|nil "LeftButton", "RightButton", "MiddleButton"
--- @return string|nil flyoutLine without the /flyout prefix
local function ParseMacroForFlyoutText(macroBody, mouseButton)
    if not macroBody then return nil end
    mouseButton = mouseButton or "LeftButton"
    local wantBtnNum = 1
    if mouseButton == "RightButton" then
        wantBtnNum = 2
    elseif mouseButton == "MiddleButton" then
        wantBtnNum = 3
    end

    for line in macroBody:gmatch("[^\r\n]+") do
        local flyoutLine
        if line:match("^/flyout%s*") then
            flyoutLine = line:gsub("^/flyout%s*", "")
        elseif line:match("^#%s*/flyout%s*") then
            flyoutLine = line:gsub("^#%s*/flyout%s*", "")
        end
        if flyoutLine then
            local btnCond = flyoutLine:match("%[btn:(%d+)%]")
            if btnCond then
                if tonumber(btnCond) == wantBtnNum then
                    return flyoutLine
                end
            else
                return flyoutLine
            end
        end
    end

    return nil
end

--- Preset NonCombat grid buttons use dedicated right-click openers, not HookFluxButton OnClick.
local function IsPresetGridFlyoutButton(fluxButton, widget)
    if not fluxButton then return false end
    widget = widget or fluxButton.Widget
    if fluxButton.FluxGridFlyoutOwner or (widget and widget.FluxGridFlyoutOwner) then
        return true
    end
    return fluxButton.IsMountButton or fluxButton.IsTeleportPortalButton or fluxButton.IsHearthButton
end

-- ---------------------------------------------------------------------------
-- CROSS-VERSION HELPERS
-- ---------------------------------------------------------------------------

--- Whether this mouse event is the correct phase for flyout open (matches ActionButtonUseKeyDown).
--- @param down boolean|nil OnClick/PostClick down flag
--- @return boolean
function FluxFlyout.ShouldProcessFlyoutClick(down)
    if GetCVarBool then
        local ok, useKeyDown = pcall(GetCVarBool, "ActionButtonUseKeyDown")
        if ok then
            if useKeyDown then
                return down == true
            end
            return down == false
        end
    end
    return down == false or down == nil
end

--- Dedupe rapid duplicate opens from the same button (down+up both firing ToggleFlyout).
local function ShouldDedupeFlyoutOpen(button)
    local now = GetTime()
    if flyoutOpenDedupe.button == button and (now - flyoutOpenDedupe.time) < FLYOUT_OPEN_DEDUPE_SEC then
        return true
    end
    flyoutOpenDedupe.button = button
    flyoutOpenDedupe.time = now
    return false
end

--- Open flyout for button (toggle-close if already open for this trigger).
--- @param button Frame
--- @param actions table
--- @param config table|nil
function FluxFlyout.OpenFlyoutForButton(button, actions, config)
    if not button or not actions or #actions == 0 then
        return false
    end
    if InCombatLockdown() then
        return false
    end
    if ShouldDedupeFlyoutOpen(button) then
        return false
    end

    if FluxFlyoutFrame.IsFlyoutOpenFor and FluxFlyoutFrame.IsFlyoutOpenFor(button) then
        FluxFlyoutFrame.CloseFlyoutFor(button)
        return true
    end

    if not config then
        config = {}
    end
    if not config.direction then
        config = setmetatable({ direction = FluxFlyout.DetermineDefaultDirection(button) }, { __index = config })
    end

    FluxFlyoutFrame.ShowFlyout(button, actions, config)
    return true
end

--- Generic dedupe wrapper for grid preset openFn callbacks.
--- @param button Frame
--- @param openFn function
--- @param dedupeSec number|nil
--- @return boolean true if openFn ran
function FluxFlyout.TryOpenFlyoutForButton(button, openFn, dedupeSec)
    if not button or not openFn then
        return false
    end
    if ShouldDedupeFlyoutOpen(button) then
        return false
    end
    pcall(openFn)
    return true
end

local function ResolveFluxButtonFlyoutActions(fluxButton)
    if not fluxButton then
        return nil, nil
    end
    local isMacroType = (fluxButton.ActionType == "macro" or fluxButton.ActionType == "macrotext")
    if not isMacroType then
        return nil, nil
    end

    local macroIndex = fluxButton.MacroIndex
    local actions, config

    if macroIndex then
        config = FluxFlyout.GetMacroConfig(macroIndex)
        if config then
            actions = FluxFlyout.GetMacroActions(macroIndex)
        end
    elseif fluxButton.MacroBody then
        local flyoutText = ParseMacroForFlyoutText(fluxButton.MacroBody, "LeftButton")
        if flyoutText then
            config = FluxFlyoutParser.ParseFlyoutLine(flyoutText)
            if config then
                actions = FluxFlyoutGenerators.GenerateActions(config)
            end
        end
    end

    return actions, config
end

local function TryOpenFlyoutFromActionBarButtonImpl(self, button, down)
    if button ~= "LeftButton" then
        return
    end
    if not FluxFlyout.ShouldProcessFlyoutClick(down) then
        return
    end
    if InCombatLockdown() then
        return
    end

    local action = self.action
    if not action or action == 0 then
        return
    end

    local actionType, id = GetActionInfo(action)
    if actionType ~= "macro" or not id then
        return
    end

    FluxFlyout.ShowForMacro(self, id)
end

local function SafeRegisterEvent(frame, event)
    if FluxSafeRegisterEvent then
        return FluxSafeRegisterEvent(frame, event)
    end
    local success = pcall(function() frame:RegisterEvent(event) end)
    return success
end

-- ---------------------------------------------------------------------------
-- MACRO SCANNING
-- ---------------------------------------------------------------------------

--- Scan and cache all macros for flyout commands
function FluxFlyout.ScanMacros()
    local oldCache = macroCache
    macroCache = {}
    local changedMacros = {}
    
    -- Scan general macros (1-120) and character macros (121-138)
    local maxMacros = 138
    if GetNumMacros then
        local numGlobal, numChar = GetNumMacros()
        maxMacros = math.max(138, (numGlobal or 120) + (numChar or 18))
    end
    
    for macroId = 1, maxMacros do
        local name, icon, body = GetMacroInfo(macroId)
        if name and body then
            -- Check if macro has flyout command
            local hasFlyout, flyoutLine = FluxFlyoutParser.ContainsFlyoutCommand(body)
            if hasFlyout then
                local config = FluxFlyoutParser.ParseFlyoutLine(flyoutLine)
                
                -- Store macro body and icon for inline parsing
                config.macroBody = body
                config.macroIcon = icon
                
                -- If the flyout list is empty AND it's not a dynamic/preset type,
                -- parse /cast and /use commands from the macro body
                -- Dynamic presets like "spell portal" have empty list but generate content dynamically
                local shouldParseInline = (not config.list or #config.list == 0) and
                                          not config.isDynamic and
                                          not config.subType  -- subType indicates a preset like "portal", "profession", etc.
                
                if shouldParseInline then
                    local inlineList = FluxFlyoutParser.ParseInlineMacroActions(body)
                    if inlineList and #inlineList > 0 then
                        config.inlineList = inlineList
                    end
                end
                
                macroCache[macroId] = config
                
                -- Track dynamic macros
                if config.isDynamic then
                    dynamicMacros[macroId] = {
                        dynamicType = config.dynamicType,
                        config = config,
                    }
                else
                    dynamicMacros[macroId] = nil
                end
                
                -- Check if this macro changed
                local oldConfig = oldCache[macroId]
                if not oldConfig or oldConfig.raw ~= config.raw then
                    table.insert(changedMacros, macroId)
                end
            end
        end
    end
    
    -- Clear entries for macros that no longer have flyouts
    for macroId in pairs(oldCache) do
        if not macroCache[macroId] then
            actionCache[macroId] = nil
            dynamicMacros[macroId] = nil
        end
    end
    
    return changedMacros
end

--- Get cached flyout configuration for a macro
-- @param macroId The macro ID
-- @return table config or nil
function FluxFlyout.GetMacroConfig(macroId)
    return macroCache[macroId]
end

--- Generate actions for a macro flyout
-- @param macroId The macro ID
-- @param forceRefresh Force regeneration even if cached
-- @return table actions
function FluxFlyout.GetMacroActions(macroId, forceRefresh)
    local config = macroCache[macroId]
    if not config then return nil end
    
    -- Check cache
    if not forceRefresh and actionCache[macroId] then
        return actionCache[macroId].actions
    end
    
    -- Generate actions
    local actions, cacheKey = FluxFlyoutGenerators.GenerateActions(config)
    
    -- Cache result
    actionCache[macroId] = {
        actions = actions,
        cacheKey = cacheKey,
    }
    
    return actions
end

-- ---------------------------------------------------------------------------
-- DYNAMIC CONTENT UPDATES
-- ---------------------------------------------------------------------------

--- Update dynamic flyouts of a specific type
-- @param dynamicType "bag" or "spell"
function FluxFlyout.UpdateDynamic(dynamicType)
    for macroId, data in pairs(dynamicMacros) do
        if data.dynamicType == dynamicType then
            local config = data.config
            local oldCacheKey = actionCache[macroId] and actionCache[macroId].cacheKey
            
            -- Regenerate actions
            local actions, newCacheKey = FluxFlyoutGenerators.GenerateActions(config)
            
            -- Only update if content changed
            if newCacheKey ~= oldCacheKey then
                actionCache[macroId] = {
                    actions = actions,
                    cacheKey = newCacheKey,
                }
                
                -- If this flyout is currently open, refresh it
                local activeFlyout = FluxFlyoutFrame.GetActiveFlyout()
                if activeFlyout and activeFlyout.config and 
                   activeFlyout.config == config then
                    FluxFlyoutFrame.RefreshActions(actions)
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- SMART DIRECTION DETECTION
-- ---------------------------------------------------------------------------

--- Determine if a button is part of ExtraButtons system
-- @param button The button frame
-- @return boolean
local function IsExtraButton(button)
    if _G.FluxFlyoutFrame and FluxFlyoutFrame.IsButtonInGridOrExtraButtonsContext then
        return FluxFlyoutFrame.IsButtonInGridOrExtraButtonsContext(button)
    end
    return false
end

--- Determine if a button is a Blizzard action bar button
-- @param button The button frame
-- @return boolean
local function IsActionBarButton(button)
    if not button then return false end
    
    local name = button:GetName() or ""
    
    -- Check for standard action bar button patterns
    if name:match("^ActionButton%d+$") then return true end
    if name:match("^MultiBar") then return true end
    if name:match("^Bonus") then return true end
    if name:match("^Override") then return true end
    if name:match("^FluxActionButton%d+$") then return true end
    if name:match("^FluxSecondaryButton%d+$") then return true end
    if name:match("^FluxTertiaryButton%d+$") then return true end
    
    return false
end

--- Helper function to identify if a button is a minimap button
local function IsMinimapButton(button)
    if not button then return false end
    
    -- Check if button widget has the minimap flag
    if button.Widget and button.Widget._isMinimapButton then
        return true
    end
    
    -- Check if button's parent is the minimap buttons container
    local widget = button.Widget or button
    if widget then
        local parent = widget:GetParent()
        if parent and parent:GetName() == "FluxMinimapButtonsContainer" then
            return true
        end
    end
    
    return false
end

--- Determine the best direction for a flyout based on button context
-- @param button The button frame
-- @return string direction - "UP", "DOWN", "LEFT", or "RIGHT"
function FluxFlyout.DetermineDefaultDirection(button)
    if not button then return "UP" end
    
    -- Minimap buttons should always flyout UP
    if IsMinimapButton(button) then
        return "UP"
    end
    
    -- ExtraButtons should flyout DOWN
    if IsExtraButton(button) then
        return "DOWN"
    end
    
    -- Check button name for side bar hints
    local name = button:GetName() or ""
    if name:match("MultiBarRight") then
        return "LEFT"
    elseif name:match("MultiBarLeft") then
        return "RIGHT"
    end
    
    -- Default: ActionBars flyout UP
    return "UP"
end

--- Get direction from macro options, falling back to smart detection
-- @param config The parsed flyout config
-- @param button The button frame
-- @return string direction
function FluxFlyout.GetDirectionForButton(config, button)
    -- Config direction takes precedence
    if config and config.direction then
        return config.direction
    end
    
    -- Fall back to smart detection
    return FluxFlyout.DetermineDefaultDirection(button)
end

-- ---------------------------------------------------------------------------
-- BUTTON INTERACTION
-- ---------------------------------------------------------------------------

--- Show flyout for a button based on macro ID
-- @param button The button frame that was clicked
-- @param macroId The macro ID associated with the button
function FluxFlyout.ShowForMacro(button, macroId)
    local config = FluxFlyout.GetMacroConfig(macroId)
    if not config then return end
    
    local actions = FluxFlyout.GetMacroActions(macroId)
    if not actions or #actions == 0 then return end
    
    FluxFlyout.OpenFlyoutForButton(button, actions, config)
end

--- Show flyout for a button based on macro body text
-- @param button The button frame that was clicked
-- @param macroBody The macro text
function FluxFlyout.ShowForMacroBody(button, macroBody)
    if not macroBody then return end
    
    local config = FluxFlyoutParser.ParseMacro(macroBody)
    if not config then return end
    
    local actions = FluxFlyoutGenerators.GenerateActions(config)
    if not actions or #actions == 0 then return end
    
    FluxFlyout.OpenFlyoutForButton(button, actions, config)
end

--- Show flyout for a button (generic entry point)
-- @param button The button frame or widget
-- @param macroId Optional macro ID
-- @param macroBody Optional macro body text
function FluxFlyout.ShowForButton(button, macroId, macroBody)
    if macroId then
        FluxFlyout.ShowForMacro(button, macroId)
    elseif macroBody then
        FluxFlyout.ShowForMacroBody(button, macroBody)
    end
end

--- Register a button for flyout detection
-- @param button The button frame to monitor
function FluxFlyout.RegisterButton(button)
    if not button then return end
    registeredButtons[button] = true
end

--- Unregister a button
-- @param button The button frame to stop monitoring
function FluxFlyout.UnregisterButton(button)
    registeredButtons[button] = nil
end

-- ---------------------------------------------------------------------------
-- FLUXBUTTON INTEGRATION
-- ---------------------------------------------------------------------------

--- Hook a FluxButton instance for custom flyout support
-- @param fluxButton The FluxButton instance (not the widget)
function FluxFlyout.HookFluxButton(fluxButton)
    if not fluxButton or not fluxButton.Widget then return end
    if fluxButton._fluxFlyoutHooked then
        -- Already hooked, just update arrow
        FluxFlyout.UpdateFluxButtonArrow(fluxButton)
        return
    end
    
    local widget = fluxButton.Widget
    
    -- Determine if this is an ExtraButton
    fluxButton._isExtraButton = IsExtraButton(widget)
    
    -- Hook the OnClick to check for flyouts (skip preset grid owners — they use dedicated openers)
    if widget.HookScript and not IsPresetGridFlyoutButton(fluxButton, widget) then
        widget:HookScript("OnClick", function(w, button, down)
            if button ~= "LeftButton" then return end
            if not FluxFlyout.ShouldProcessFlyoutClick(down) then return end
            if InCombatLockdown() then return end
            
            local actions, config = ResolveFluxButtonFlyoutActions(fluxButton)
            if actions and #actions > 0 then
                local direction = FluxFlyout.GetDirectionForButton(config, w)
                if config then
                    config = setmetatable({ direction = direction }, { __index = config })
                else
                    config = { direction = direction }
                end
                FluxFlyout.OpenFlyoutForButton(w, actions, config)
            end
        end)
    end
    
    -- Create flyout arrow on the widget
    FluxFlyoutFrame.CreateArrow(widget)
    
    fluxButton._fluxFlyoutHooked = true
    
    -- Update arrow visibility
    FluxFlyout.UpdateFluxButtonArrow(fluxButton)
end

--- Update flyout arrow visibility on a FluxButton
-- @param fluxButton The FluxButton instance
function FluxFlyout.UpdateFluxButtonArrow(fluxButton)
    if not fluxButton or not fluxButton.Widget then return end
    
    local widget = fluxButton.Widget

    -- Hearth / Mount / TeleportPortal own their arrows (right-click / type2 flyout).
    -- Their macros are /use or /cast, not /flyout — do not HideArrow on SetAction.
    if IsPresetGridFlyoutButton(fluxButton, widget) then
        return
    end
    
    -- Ensure arrow frame exists (may not have been created if flyout system loaded after button)
    if not widget.FluxFlyoutArrow and FluxFlyoutFrame and FluxFlyoutFrame.CreateArrow then
        FluxFlyoutFrame.CreateArrow(widget)
    end
    
    local hasFlyout = false
    local direction = "UP"
    local config = nil
    
    -- Check for flyout in macro - try cache first, then parse on-the-fly
    if fluxButton.MacroIndex then
        config = FluxFlyout.GetMacroConfig(fluxButton.MacroIndex)
        if config then
            hasFlyout = true
            direction = FluxFlyout.GetDirectionForButton(config, widget)
        else
            -- Fallback: parse macro directly for pre-initialization or cache miss
            local flyoutText = ParseMacroForFlyoutText(fluxButton.MacroBody, "LeftButton")
            if not flyoutText then
                -- Try getting macro body from macro index
                local name, icon, body = GetMacroInfo(fluxButton.MacroIndex)
                if body then
                    flyoutText = ParseMacroForFlyoutText(body, "LeftButton")
                end
            end
            if flyoutText and FluxFlyoutParser then
                config = FluxFlyoutParser.ParseFlyoutLine(flyoutText)
                if config then
                    hasFlyout = true
                    direction = FluxFlyout.GetDirectionForButton(config, widget)
                end
            end
        end
    elseif fluxButton.MacroBody then
        local flyoutText = ParseMacroForFlyoutText(fluxButton.MacroBody, "LeftButton")
            or ParseMacroForFlyoutText(fluxButton.MacroBody, "RightButton")
            or ParseMacroForFlyoutText(fluxButton.MacroBody, "MiddleButton")
        if flyoutText and FluxFlyoutParser then
            hasFlyout = true
            config = FluxFlyoutParser.ParseFlyoutLine(flyoutText)
            direction = FluxFlyout.GetDirectionForButton(config, widget)
        end
    end
    
    -- Force DOWN for ExtraButtons unless explicitly specified otherwise
    if hasFlyout and fluxButton._isExtraButton and direction == "UP" then
        direction = "DOWN"
    end
    
    if hasFlyout then
        -- Check if flyout is currently open for this button
        local isOpen = false
        if FluxFlyoutFrame and FluxFlyoutFrame.IsFlyoutOpenFor then
            isOpen = FluxFlyoutFrame.IsFlyoutOpenFor(widget)
        end
        
        if FluxFlyoutFrame then
            FluxFlyoutFrame.ShowArrow(widget, direction)
            FluxFlyoutFrame.UpdateArrow(widget, direction, isOpen)
        end
    else
        if FluxFlyoutFrame then
            FluxFlyoutFrame.HideArrow(widget)
        end
    end
end

--- Clear the flyout arrow on a FluxButton (called when action is cleared)
-- @param fluxButton The FluxButton instance
function FluxFlyout.ClearFluxButtonArrow(fluxButton)
    if not fluxButton or not fluxButton.Widget then return end
    FluxFlyoutFrame.ClearArrow(fluxButton.Widget)
end

--- Refresh all registered FluxButton arrows
function FluxFlyout.RefreshFluxButtonArrows()
    -- Hook and refresh FluxButton instances (Engine Core.ActiveButtons; legacy FluxButtonGlobal.ButtonRegistry)
    if FluxButtonCore and FluxButtonCore.GetActiveButtons then
        for _, button in ipairs(FluxButtonCore.GetActiveButtons()) do
            FluxFlyout.HookFluxButton(button)
        end
    elseif FluxButtonGlobal and FluxButtonGlobal.ButtonRegistry then
        for _, button in pairs(FluxButtonGlobal.ButtonRegistry) do
            FluxFlyout.HookFluxButton(button)
        end
    end
    
    -- Also refresh registered buttons
    for button in pairs(registeredButtons) do
        if button.FluxButton then
            FluxFlyout.UpdateFluxButtonArrow(button.FluxButton)
        elseif button.FluxFlyoutArrow then
            -- Direct widget, just update arrow
            local isOpen = FluxFlyoutFrame.IsFlyoutOpenFor(button)
            FluxFlyoutFrame.UpdateArrow(button, "UP", isOpen)
        end
    end
end

-- ---------------------------------------------------------------------------
-- PROXY BUTTON SYSTEM (Arrow overlays for Blizzard action bars)
-- ---------------------------------------------------------------------------

-- Arrow size constants (must be defined before CreateProxyButton)
local ARROW_SIZE_W = 23
local ARROW_SIZE_H = 11
local ARROW_TEX_COORDS = { 0.62500000, 0.98437500, 0.74218750, 0.82812500 }

local proxyButtons = {}

--- Create a proxy button (arrow overlay) for a Blizzard action bar button
-- @param parent The parent action bar button
-- @return frame The proxy frame
local function CreateProxyButton(parent)
    if not parent then return nil end
    
    local parentName = parent:GetName()
    if not parentName then return nil end
    
    local proxyName = parentName .. "FluxFlyoutProxy"
    if _G[proxyName] then return _G[proxyName] end
    
    -- Create arrow overlay frame
    local proxy = CreateFrame("Frame", proxyName, parent)
    
    proxy:SetSize(36, 36)
    proxy:SetPoint("CENTER", parent, "CENTER")
    proxy:SetFrameLevel(parent:GetFrameLevel() + 5)
    
    -- Flyout arrow texture
    proxy.FlyoutArrow = proxy:CreateTexture(nil, "OVERLAY", nil, 7)
    proxy.FlyoutArrow:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton")
    proxy.FlyoutArrow:SetSize(ARROW_SIZE_W, ARROW_SIZE_H)
    proxy.FlyoutArrow:SetTexCoord(unpack(ARROW_TEX_COORDS))
    proxy.FlyoutArrow:SetPoint("TOP", proxy, "TOP", 0, 2)
    proxy.FlyoutArrow:Hide()
    
    -- Store parent reference
    proxy.parentButton = parent

    local function ProxyTryOpenFlyout(proxyFrame, mouseButton, down)
        if mouseButton ~= "LeftButton" or not proxyFrame.parentButton then
            return
        end
        TryOpenFlyoutFromActionBarButtonImpl(proxyFrame.parentButton, mouseButton, down)
    end

    proxy:SetScript("OnMouseDown", function(self, mouseButton)
        ProxyTryOpenFlyout(self, mouseButton, true)
    end)
    proxy:SetScript("OnMouseUp", function(self, mouseButton)
        ProxyTryOpenFlyout(self, mouseButton, false)
    end)
    
    -- Scale to match parent
    local scale = parent:GetWidth() / 36
    if scale > 0 then
        proxy:SetScale(scale)
    end
    
    proxy:Hide()
    
    table.insert(proxyButtons, proxy)
    return proxy
end

--- Update a proxy button's state based on its parent's action
-- @param proxy The proxy frame
local function ResetProxyOverlay(proxy, parent)
    if proxy.FlyoutArrow then
        proxy.FlyoutArrow:Hide()
    end
    proxy:EnableMouse(false)
    proxy:ClearAllPoints()
    proxy:SetSize(36, 36)
    proxy:SetPoint("CENTER", parent, "CENTER")
    proxy:Hide()
end

local function UpdateProxyButton(proxy)
    if not proxy or not proxy.parentButton then return end
    
    local parent = proxy.parentButton
    local action = parent.action
    
    if not action or action == 0 then
        ResetProxyOverlay(proxy, parent)
        return
    end
    
    local actionType, actionId = GetActionInfo(action)
    if actionType ~= "macro" then
        ResetProxyOverlay(proxy, parent)
        return
    end
    
    -- Check if macro has flyout
    local config = FluxFlyout.GetMacroConfig(actionId)
    if config then
        proxy:SetAllPoints(parent)
        proxy:EnableMouse(true)
        proxy:Show()
        
        -- Determine direction
        local direction = FluxFlyout.GetDirectionForButton(config, parent)
        
        -- Check if flyout is open
        local isOpen = FluxFlyoutFrame.IsFlyoutOpenFor(parent)
        
        -- Update arrow position and rotation
        local arrow = proxy.FlyoutArrow
        if arrow then
            arrow:ClearAllPoints()
            
            local baseOffset = 6
            
            if direction == "LEFT" then
                arrow:SetPoint("LEFT", proxy, "LEFT", -baseOffset, 0)
                SetClampedTextureRotation(arrow, isOpen and 90 or 270)
            elseif direction == "RIGHT" then
                arrow:SetPoint("RIGHT", proxy, "RIGHT", baseOffset, 0)
                SetClampedTextureRotation(arrow, isOpen and 270 or 90)
            elseif direction == "DOWN" then
                arrow:SetPoint("BOTTOM", proxy, "BOTTOM", 0, -baseOffset)
                SetClampedTextureRotation(arrow, isOpen and 0 or 180)
            else  -- UP (default)
                arrow:SetPoint("TOP", proxy, "TOP", 0, baseOffset)
                SetClampedTextureRotation(arrow, isOpen and 180 or 0)
            end
            
            arrow:Show()
        end
    else
        ResetProxyOverlay(proxy, parent)
    end
end

--- Update all proxy buttons
function FluxFlyout.UpdateProxyButtons()
    for _, proxy in ipairs(proxyButtons) do
        if proxy.parentButton then
            UpdateProxyButton(proxy)
        end
    end
end

--- Create proxy buttons for all action bar buttons
local function CreateProxyButtonsForActionBars()
    local function ScanBarPrefix(prefix, count)
        count = count or 12
        for i = 1, count do
            local button = _G[prefix .. i]
            if button then CreateProxyButton(button) end
        end
    end

    -- Main action bar
    ScanBarPrefix("ActionButton")

    -- MultiBar buttons
    local barPrefixes = {
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
    }
    for _, prefix in ipairs(barPrefixes) do
        ScanBarPrefix(prefix)
    end

    -- Flux custom action bars (Edit Mode / FluxActionBar)
    local fluxBarPrefixes = {
        "FluxActionButton",
        "FluxSecondaryButton",
        "FluxTertiaryButton",
    }
    for _, prefix in ipairs(fluxBarPrefixes) do
        ScanBarPrefix(prefix)
    end
end

-- ---------------------------------------------------------------------------
-- ACTION BAR HOOKS
-- ---------------------------------------------------------------------------

local function HookActionButtons()
    -- CreateProxyButton hooks each parent OnClick once (_fluxFlyoutProxyHooked).
    -- Do not HookScript here too — duplicate hooks can run inside the secure click chain.
    CreateProxyButtonsForActionBars()
    FluxFlyout.UpdateProxyButtons()
end

-- ---------------------------------------------------------------------------
-- EVENT HANDLING
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local bagUpdateTimer = nil
local pendingFlyoutStormRefresh = false

local function OnEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initial macro scan after a short delay
        C_Timer.After(0.5, function()
            FluxFlyout.ScanMacros()
            HookActionButtons()
            FluxFlyout.RefreshFluxButtonArrows()
            isInitialized = true
        end)
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Rescan macros on world enter
        if isInitialized then
            C_Timer.After(0.1, function()
                FluxFlyout.ScanMacros()
                FluxFlyout.UpdateProxyButtons()
                FluxFlyout.RefreshFluxButtonArrows()
            end)
        end
        
    elseif event == "UPDATE_MACROS" then
        -- Macro was edited
        if isInitialized then
            local changedMacros = FluxFlyout.ScanMacros()
            
            -- Close flyout if its macro was changed
            local activeFlyout = FluxFlyoutFrame.GetActiveFlyout()
            if activeFlyout and activeFlyout.config then
                for _, macroId in ipairs(changedMacros) do
                    local config = macroCache[macroId]
                    if config and activeFlyout.config == config then
                        FluxFlyoutFrame.CloseFlyout()
                        break
                    end
                end
            end
            
            -- Update proxy buttons and arrows
            FluxFlyout.UpdateProxyButtons()
            FluxFlyout.RefreshFluxButtonArrows()
        end
        
    elseif event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
        local inv = _G.FluxInv or _G.FluxInventory
        if inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet() then
            return
        end
        if FluxVendorSession and FluxVendorSession.IsBurstActive and FluxVendorSession.IsBurstActive() then
            return
        end
        -- During a vendor purchase storm, coalesce all flyout bag refreshes into
        -- a single pass once the storm settles.
        if FluxVendorSession and FluxVendorSession.IsPurchaseStormActive
            and FluxVendorSession.IsPurchaseStormActive() then
            if isInitialized and not pendingFlyoutStormRefresh then
                pendingFlyoutStormRefresh = true
                FluxVendorSession.OnPurchaseStormSettled(function()
                    pendingFlyoutStormRefresh = false
                    FluxFlyout.UpdateDynamic("bag")
                    FluxFlyoutFrame.UpdateCooldowns()
                end)
            end
            return
        end
        -- Bag contents changed - update dynamic bag flyouts (debounced to avoid lag on item use)
        if isInitialized then
            if bagUpdateTimer then
                bagUpdateTimer:Cancel()
            end
            bagUpdateTimer = C_Timer.NewTimer(0.3, function()
                bagUpdateTimer = nil
                FluxFlyout.UpdateDynamic("bag")
                FluxFlyoutFrame.UpdateCooldowns()
            end)
        end
        
    elseif event == "LEARNED_SPELL_IN_TAB" or event == "LEARNED_SPELL_IN_SKILL_LINE" or event == "SPELLS_CHANGED" then
        -- Spellbook changed - update dynamic spell flyouts
        if isInitialized then
            FluxFlyout.UpdateDynamic("spell")
            FluxFlyout.RefreshFluxButtonArrows()
        end
        
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN"
        or event == "SPELL_UPDATE_CHARGES" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
        -- Update cooldown displays
        FluxFlyoutFrame.UpdateCooldowns()

    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
        FluxFlyoutFrame.UpdateCooldowns()
        
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat - close flyout
        FluxFlyoutFrame.CloseFlyout()
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat - refresh buttons
        FluxFlyout.UpdateProxyButtons()
        FluxFlyout.RefreshFluxButtonArrows()
        
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" then
        -- Action bar changed - update proxy buttons
        if isInitialized then
            -- Shapeshift ASC/page storms: ExtraButton proxies don't need per-slot rebuilds.
            if FluxButtonEvents and FluxButtonEvents.IsFormStormActive
                and FluxButtonEvents.IsFormStormActive() then
                return
            end
            if event == "ACTIONBAR_SLOT_CHANGED" then
                local slotNum = tonumber((...))
                if slotNum and slotNum > 0 then
                    local peek = _G.FluxActionBarPeekSlotOccupancyChanged
                    if peek and not peek(slotNum) then
                        return
                    end
                end
            end
            C_Timer.After(0.05, function()
                if FluxButtonEvents and FluxButtonEvents.IsFormStormActive
                    and FluxButtonEvents.IsFormStormActive() then
                    return
                end
                FluxFlyout.UpdateProxyButtons()
            end)
        end
        
    elseif event == "PLAYER_LOGOUT" then
        FluxFlyoutFrame.Cleanup()
    end
end

-- Register events
eventFrame:SetScript("OnEvent", OnEvent)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

-- Use safe registration for potentially unavailable events
SafeRegisterEvent(eventFrame, "UPDATE_MACROS")
-- Only the coalesced delayed variant; raw BAG_UPDATE fires once per affected
-- slot and the handler already debounces, so BAG_UPDATE_DELAYED is sufficient.
SafeRegisterEvent(eventFrame, "BAG_UPDATE_DELAYED")
SafeRegisterEvent(eventFrame, "LEARNED_SPELL_IN_TAB")
SafeRegisterEvent(eventFrame, "LEARNED_SPELL_IN_SKILL_LINE")
SafeRegisterEvent(eventFrame, "SPELLS_CHANGED")
SafeRegisterEvent(eventFrame, "SPELL_UPDATE_COOLDOWN")
SafeRegisterEvent(eventFrame, "BAG_UPDATE_COOLDOWN")
SafeRegisterEvent(eventFrame, "SPELL_UPDATE_CHARGES")
SafeRegisterEvent(eventFrame, "ACTIONBAR_UPDATE_COOLDOWN")
SafeRegisterEvent(eventFrame, "ZONE_CHANGED")
SafeRegisterEvent(eventFrame, "ZONE_CHANGED_INDOORS")
SafeRegisterEvent(eventFrame, "ZONE_CHANGED_NEW_AREA")
SafeRegisterEvent(eventFrame, "ACTIONBAR_SLOT_CHANGED")
SafeRegisterEvent(eventFrame, "ACTIONBAR_PAGE_CHANGED")

-- ---------------------------------------------------------------------------
-- SLASH COMMAND
-- ---------------------------------------------------------------------------

local helpText = [=[
|cff00ffffFlux Flyout System|r
Create custom flyouts using macro syntax:

|cffffd700/flyout [options] subType, list1, list2, ...|r

|cff00ff00Options (comma-separated in brackets):|r
  Direction: left, right, up, down
  Cooldown: cooldown, cooldown_white, nocooldown
  Type: item_ench_temp, conjure, spell, item, mixed

|cff00ff00Spell Sub-Types (dynamic):|r
  profession, portal, teleport
  totem, totem_earth, totem_fire, totem_air, totem_water
  trap, track, aspect, warlockpet
  shaman_weapon, presence, shapeshift, aura, blessing, stance

|cff00ff00Examples:|r
  /flyout [spell,up] portal
  /flyout [item] Hearthstone, Dark Portal
  /flyout [conjure] dynamic
  /flyout [item_ench_temp,cooldown] dynamic
  /flyout [mixed] spell:190336, item:6948

|cff00ff00Example Macro:|r
  #showtooltip
  /flyout [spell] profession
  /stopmacro [btn:1]
  /cast Alchemy
]=]

SLASH_FLUXFLYOUT1 = "/fluxflyout"
SLASH_FLUXFLYOUT2 = "/fflyout"
SlashCmdList["FLUXFLYOUT"] = function(msg)
    local cmd = msg and msg:lower():match("^(%S+)") or ""
    
    if cmd == "scan" then
        local changed = FluxFlyout.ScanMacros()
        print("|cff00ffff[FluxFlyout]|r Scanned macros. Found " .. 
              (function() local c = 0; for _ in pairs(macroCache) do c = c + 1 end; return c end)() .. 
              " flyout macros.")
              
    elseif cmd == "list" then
        print("|cff00ffff[FluxFlyout]|r Registered flyout macros:")
        local count = 0
        for macroId, config in pairs(macroCache) do
            local name = GetMacroInfo(macroId)
            print("  [" .. macroId .. "] " .. (name or "Unknown") .. ": " .. (config.raw or ""))
            count = count + 1
        end
        if count == 0 then
            print("  (none)")
        end
        
    elseif cmd == "close" then
        FluxFlyoutFrame.CloseFlyout()
        print("|cff00ffff[FluxFlyout]|r Flyout closed.")
        
    elseif cmd == "debuggrid" then
        print("|cff00ffff[FluxFlyout]|r Grid flyout debug (direct Lua open, no click):")
        local opened = false
        if FluxNCTeleportPortal and FluxNCTeleportPortal.ShowFlyout then
            local n = 0
            if FluxNCTeleportPortal._button and FluxNCTeleportPortal.BuildFlyoutActions then
                n = #(FluxNCTeleportPortal.BuildFlyoutActions(FluxNCTeleportPortal.GetMode and FluxNCTeleportPortal.GetMode()) or {})
            end
            print("  TeleportPortal actions:", n)
            FluxNCTeleportPortal.ShowFlyout()
            opened = true
        end
        if FluxNCHearthstone and FluxNCHearthstone.ShowTeleportFlyout then
            print("  Hearth teleport items:", FluxNCHearthstone.HasTeleportItems and FluxNCHearthstone.HasTeleportItems())
            FluxNCHearthstone.ShowTeleportFlyout()
            opened = true
        end
        if FluxNCMount and FluxNCMount.ShowMountItemFlyout then
            FluxNCMount.ShowMountItemFlyout()
            opened = true
        end
        if not opened then
            print("  (no grid modules loaded)")
        end
        local active = FluxFlyoutFrame and FluxFlyoutFrame.GetActiveFlyout and FluxFlyoutFrame.GetActiveFlyout()
        print("  active flyout after open:", active and active:IsShown() and "yes" or "no",
              active and active.actions and #active.actions or 0, "actions")
        
    elseif cmd == "test" then
        local isPreDF = FLUX_API and FLUX_API.isPreDF
        local useKeyDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")
        local hasActionBar = C_ActionBar ~= nil
        print("|cff00ffff[FluxFlyout]|r Diagnostics:")
        print("  isPreDF:", tostring(isPreDF))
        print("  ActionButtonUseKeyDown:", tostring(useKeyDown))
        print("  C_ActionBar:", tostring(hasActionBar))
        print("  proxy buttons:", #proxyButtons)
        print("  macro cache:", (function() local c = 0; for _ in pairs(macroCache) do c = c + 1 end; return c end)())
        local active = FluxFlyoutFrame and FluxFlyoutFrame.GetActiveFlyout and FluxFlyoutFrame.GetActiveFlyout()
        if active then
            print("  active flyout actions:", active.actions and #active.actions or 0)
        else
            print("  active flyout: none")
        end
        if FluxFlyoutParser then
            FluxFlyoutParser.Test()
        end
        if FluxFlyoutGenerators then
            FluxFlyoutGenerators.Test()
        end
        if FluxFlyoutFrame then
            FluxFlyoutFrame.Test()
        end
        
    else
        -- Print help
        print(helpText)
    end
end

-- Also register original /flyout command to not conflict
-- The macro parser will handle the command, this is just for help
SLASH_FLYOUTHELP1 = "/flyouthelp"
SlashCmdList["FLYOUTHELP"] = function(msg)
    print(helpText)
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------

-- Export main functions
FluxFlyout.ShowForMacro = FluxFlyout.ShowForMacro
FluxFlyout.ShowForMacroBody = FluxFlyout.ShowForMacroBody
FluxFlyout.ShowForButton = FluxFlyout.ShowForButton
FluxFlyout.RegisterButton = FluxFlyout.RegisterButton
FluxFlyout.UnregisterButton = FluxFlyout.UnregisterButton
FluxFlyout.ScanMacros = FluxFlyout.ScanMacros
FluxFlyout.GetMacroConfig = FluxFlyout.GetMacroConfig
FluxFlyout.GetMacroActions = FluxFlyout.GetMacroActions
FluxFlyout.UpdateDynamic = FluxFlyout.UpdateDynamic

-- Direction detection
FluxFlyout.DetermineDefaultDirection = FluxFlyout.DetermineDefaultDirection
FluxFlyout.GetDirectionForButton = FluxFlyout.GetDirectionForButton

-- FluxButton integration
FluxFlyout.HookFluxButton = FluxFlyout.HookFluxButton
FluxFlyout.UpdateFluxButtonArrow = FluxFlyout.UpdateFluxButtonArrow
FluxFlyout.ClearFluxButtonArrow = FluxFlyout.ClearFluxButtonArrow
FluxFlyout.RefreshFluxButtonArrows = FluxFlyout.RefreshFluxButtonArrows

-- Proxy button system
FluxFlyout.UpdateProxyButtons = FluxFlyout.UpdateProxyButtons

-- Click phase + open helpers
FluxFlyout.ShouldProcessFlyoutClick = FluxFlyout.ShouldProcessFlyoutClick
FluxFlyout.OpenFlyoutForButton = FluxFlyout.OpenFlyoutForButton
FluxFlyout.TryOpenFlyoutForButton = FluxFlyout.TryOpenFlyoutForButton

-- Expose for other modules
FluxFlyout.IsInitialized = function() return isInitialized end


