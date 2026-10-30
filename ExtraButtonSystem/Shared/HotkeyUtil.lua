--[[
    ExtraButtonSystem/Shared/HotkeyUtil.lua
    Shared hotkey text utilities for ExtraButtonSystem (TrinketMenu, grids, etc.)
    
    Provides:
    - UpdateHotkeyText(btn, bindingName) - Updates button's hotkey text display
    - GetBindingKeyText(bindingName) - Gets formatted binding key text
    - GetFormattedKeyFromKey(key) - Formats raw key string with mouse icons and modifiers
    
    Compatible with all WoW versions via FluxAPICompat.lua
]]

-- Create namespace
FluxNCHotkeyUtil = FluxNCHotkeyUtil or {}
local HotkeyUtil = FluxNCHotkeyUtil

-- Key icons (mouse / scroll / space). Default 14px = 12 * 1.2.
-- Callers (e.g. TrinketMenu) may pass a larger iconSize; HotKey frames are resized to fit.
local KEY_ICON_SIZE = 14
local KEY_ICON_PATHS = {
    ["BUTTON3"] = "Interface\\AddOns\\_FluxUI\\Texture\\MouseButton3.tga",
    ["BUTTON4"] = "Interface\\AddOns\\_FluxUI\\Texture\\MouseButton4.tga",
    ["BUTTON5"] = "Interface\\AddOns\\_FluxUI\\Texture\\MouseButton5.tga",
    ["MOUSEWHEELUP"] = "Interface\\AddOns\\_FluxUI\\Texture\\MouseScrollUp.tga",
    ["MOUSEWHEELDOWN"] = "Interface\\AddOns\\_FluxUI\\Texture\\MouseScrollDown.tga",
    ["WU"] = "Interface\\AddOns\\_FluxUI\\Texture\\MouseScrollUp.tga",
    ["WD"] = "Interface\\AddOns\\_FluxUI\\Texture\\MouseScrollDown.tga",
    ["SPACE"] = "Interface\\AddOns\\_FluxUI\\Texture\\SpaceBarButton.tga",
    ["SP"] = "Interface\\AddOns\\_FluxUI\\Texture\\SpaceBarButton.tga", -- LibKeyBound "Sp"
}

local function KeyIconPath(token)
    if Flux and Flux.Hotkey and Flux.Hotkey.Path then
        return Flux.Hotkey.Path(token)
    end
    return KEY_ICON_PATHS[token]
end

local function KeyIcon(path, size, width)
    size = size or KEY_ICON_SIZE
    width = width or size
    size = math.max(1, math.floor(size + 0.5))
    width = math.max(1, math.floor(width + 0.5))
    return ("|T%s:%d:%d:0:-1|t"):format(path, size, width)
end

local function ResolveHotKeyFrame(btn)
    if not btn then return nil end
    if btn.WHotKey then return btn.WHotKey end
    local widget = btn.Widget or btn
    if type(widget) ~= "table" then return nil end
    if widget.HotKey then return widget.HotKey end
    local name = widget.GetName and widget:GetName()
    if name then
        return _G[name .. "HotKey"]
    end
    return nil
end

local function PrepareHotKeyFrame(hotKeyFrame, widget, iconSize, iconWidth)
    if not hotKeyFrame then return end

    iconSize = iconSize or KEY_ICON_SIZE
    iconWidth = iconWidth or iconSize
    local isWoW10Plus = FLUX_API and (FLUX_API.majorVersion or 12) >= 10
    local fontSize = isWoW10Plus and 14 or 13
    -- Room for |T| glyphs: ActionButtonTemplate HotKey is often ~10px tall and clips larger icons.
    local frameHeight = math.max(fontSize, iconSize) + 4
    local frameWidth = math.max(hotKeyFrame.GetWidth and hotKeyFrame:GetWidth() or 0, iconWidth + 28)

    if widget then
        hotKeyFrame:ClearAllPoints()
        hotKeyFrame:SetPoint("TOPRIGHT", widget, "TOPRIGHT", -2, -2)
    end
    if hotKeyFrame.SetSize then
        hotKeyFrame:SetSize(frameWidth, frameHeight)
    else
        if hotKeyFrame.SetWidth then hotKeyFrame:SetWidth(frameWidth) end
        if hotKeyFrame.SetHeight then hotKeyFrame:SetHeight(frameHeight) end
    end

    hotKeyFrame:SetFontObject("NumberFontNormalSmallGray")
    local font = hotKeyFrame.GetFont and hotKeyFrame:GetFont()
    if font then
        hotKeyFrame:SetFont(font, fontSize, "OUTLINE")
    end
    hotKeyFrame:SetTextColor(0.75, 0.75, 0.75)
    hotKeyFrame:SetJustifyH("RIGHT")
    hotKeyFrame:SetJustifyV("TOP")
    if hotKeyFrame.SetWordWrap then
        hotKeyFrame:SetWordWrap(false)
    end
end

-- Shortened key names for display (non-mouse buttons)
local KEY_ABBREVIATIONS = {
    ["NUMPAD0"] = "N0", ["NUMPAD1"] = "N1", ["NUMPAD2"] = "N2", ["NUMPAD3"] = "N3",
    ["NUMPAD4"] = "N4", ["NUMPAD5"] = "N5", ["NUMPAD6"] = "N6", ["NUMPAD7"] = "N7",
    ["NUMPAD8"] = "N8", ["NUMPAD9"] = "N9", ["NUMPADPLUS"] = "N+", ["NUMPADMINUS"] = "N-",
    ["NUMPADMULTIPLY"] = "N*", ["NUMPADDIVIDE"] = "N/", ["NUMPADPERIOD"] = "N.",
}

-- Track current modifier state for dynamic display
local currentModifierState = {
    shift = false,
    ctrl = false,
    alt = false,
}

-- Check if a keybind string already contains modifiers
local function KeyHasModifiers(key)
    if not key or key == "" then return false end
    local upperKey = string.upper(key)
    return upperKey:find("SHIFT%-") ~= nil or 
           upperKey:find("CTRL%-") ~= nil or 
           upperKey:find("ALT%-") ~= nil or
           upperKey:find("STRG%-") ~= nil
end

-- Get current modifier state as prefix string (S-, C-, A-)
local function GetCurrentModifierPrefix()
    local prefix = ""
    if currentModifierState.shift then prefix = prefix .. "S-" end
    if currentModifierState.ctrl then prefix = prefix .. "C-" end
    if currentModifierState.alt then prefix = prefix .. "A-" end
    return prefix
end

-- Update current modifier state from WoW API
local function UpdateModifierState()
    currentModifierState.shift = IsShiftKeyDown and IsShiftKeyDown() or false
    currentModifierState.ctrl = IsControlKeyDown and IsControlKeyDown() or false
    currentModifierState.alt = IsAltKeyDown and IsAltKeyDown() or false
end

-- Format raw key string with modifier prefix (S-, C-, A-) and mouse icons
-- key: e.g. "SHIFT-CTRL-MOUSEWHEELUP", "BUTTON4", "ALT-BUTTON5"
-- addDynamicModifiers: if true and key doesn't have modifiers, add current modifier state
-- hasModifierAssignments: if true, enable dynamic modifiers even if keybind has no modifiers
-- iconSize: optional |T| pixel height for mouse/space glyphs (default KEY_ICON_SIZE)
-- iconWidth: optional |T| pixel width (default iconSize); pass a squeezed width for X-scale.
function HotkeyUtil.GetFormattedKeyFromKey(key, addDynamicModifiers, hasModifierAssignments, iconSize, iconWidth)
    if not key or key == "" then return "" end
    
    local parts = {}
    for part in string.gmatch(key, "[^-]+") do
        table.insert(parts, part:upper())
    end
    if #parts == 0 then return "" end
    
    local baseKey = parts[#parts]
    local modifierPrefix = ""
    local keyHasMods = KeyHasModifiers(key)
    
    -- Build modifier prefix from preceding segments (order: S-, C-, A-)
    for i = 1, #parts - 1 do
        local p = parts[i]
        if p == "SHIFT" then
            modifierPrefix = modifierPrefix .. "S-"
        elseif p == "CTRL" or p == "STRG" then
            modifierPrefix = modifierPrefix .. "C-"
        elseif p == "ALT" then
            modifierPrefix = modifierPrefix .. "A-"
        end
    end
    
    -- Add dynamic modifiers if:
    -- 1. Key doesn't already have modifiers AND
    -- 2. (addDynamicModifiers is true OR hasModifierAssignments is true)
    if not keyHasMods and (addDynamicModifiers or hasModifierAssignments) then
        UpdateModifierState()
        modifierPrefix = modifierPrefix .. GetCurrentModifierPrefix()
    end
    
    -- Check for key icon (mouse, scroll, spacebar)
    local path = KeyIconPath(baseKey)
    if path then
        return modifierPrefix .. KeyIcon(path, iconSize, iconWidth)
    end
    
    -- Non-mouse: use abbreviation or GetBindingText fallback
    if KEY_ABBREVIATIONS[baseKey] then
        return modifierPrefix .. KEY_ABBREVIATIONS[baseKey]
    end
    
    -- Fallback: Use GetBindingText for display, then shorten
    local text = GetBindingText(key) or key
    text = text:gsub("CTRL%-", "C-")
    text = text:gsub("ALT%-", "A-")
    text = text:gsub("SHIFT%-", "S-")
    text = text:gsub("NUMPAD", "N")
    text = text:gsub("BUTTON", "M")
    text = text:gsub("MOUSEWHEELUP", "MWU")
    text = text:gsub("MOUSEWHEELDOWN", "MWD")
    
    -- Add dynamic modifier prefix to fallback text if needed
    if not keyHasMods and (addDynamicModifiers or hasModifierAssignments) then
        UpdateModifierState()
        local dynamicPrefix = GetCurrentModifierPrefix()
        if dynamicPrefix ~= "" then
            text = dynamicPrefix .. text
        end
    end
    
    return text
end

-- Get formatted binding key text with mouse icons and modifier prefix
-- addDynamicModifiers: if true, add current modifier state when keybind has no modifiers
-- hasModifierAssignments: if true, enable dynamic modifiers even if keybind has no modifiers
-- iconSize: optional |T| pixel size for mouse/space glyphs
function HotkeyUtil.GetBindingKeyText(bindingName, addDynamicModifiers, hasModifierAssignments, iconSize, iconWidth)
    if not bindingName then return nil end
    
    local key = GetBindingKey(bindingName)
    if not key then return nil end
    
    return HotkeyUtil.GetFormattedKeyFromKey(key, addDynamicModifiers, hasModifierAssignments, iconSize, iconWidth)
end

-- Update button's hotkey text display
-- btn: The FluxButton object (must have Widget with HotKey child)
-- bindingName: The binding name e.g. "FLUXGRIDHEARTH"
-- addDynamicModifiers: if true, add current modifier state when keybind has no modifiers
-- hasModifierAssignments: if true, enable dynamic modifiers even if keybind has no modifiers
-- iconSize: optional |T| pixel size for mouse/space glyphs (persisted on btn.HotkeyIconSize)
function HotkeyUtil.UpdateHotkeyText(btn, bindingName, addDynamicModifiers, hasModifierAssignments, iconSize)
    if not btn or not btn.Widget then return end
    
    -- Store binding name and flags for persistence through FullRefresh()
    btn.HotkeyBinding = bindingName
    btn.HotkeyAddDynamicModifiers = addDynamicModifiers
    btn.HotkeyHasModifierAssignments = hasModifierAssignments
    if iconSize ~= nil then
        btn.HotkeyIconSize = iconSize
    end
    local resolvedIconSize = btn.HotkeyIconSize or iconSize or KEY_ICON_SIZE
    local widget = btn.Widget
    local xF = 1
    if FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetWidgetHorizontalSqueezeFactor then
        local native = (widget.GetHeight and widget:GetHeight()) or 44
        xF = FluxUILayoutSqueeze.GetWidgetHorizontalSqueezeFactor(widget, native) or 1
    elseif widget and widget.GetWidth and widget.GetHeight then
        local w, h = widget:GetWidth(), widget:GetHeight()
        if type(w) == "number" and type(h) == "number" and h > 0 then
            xF = math.max(0.4, math.min(1, w / h))
        end
    end
    local resolvedIconWidth = math.max(1, resolvedIconSize * xF)

    local hotKeyFrame = ResolveHotKeyFrame(btn)
    if not hotKeyFrame then return end

    PrepareHotKeyFrame(hotKeyFrame, widget, resolvedIconSize, resolvedIconWidth)
    
    local text = HotkeyUtil.GetBindingKeyText(bindingName, addDynamicModifiers, hasModifierAssignments, resolvedIconSize, resolvedIconWidth)
    if text and text ~= "" then
        hotKeyFrame:SetText(text)
        hotKeyFrame:Show()
    else
        hotKeyFrame:SetText("")
        hotKeyFrame:Hide()
    end
end

-- Update button's hotkey text from multiple possible bindings (for buttons with multiple actions)
-- Returns the first found binding text
function HotkeyUtil.UpdateHotkeyTextMultiple(btn, bindingNames, iconSize)
    if not btn or not btn.Widget or not bindingNames then return end
    
    for _, bindingName in ipairs(bindingNames) do
        local text = HotkeyUtil.GetBindingKeyText(bindingName, nil, nil, iconSize or btn.HotkeyIconSize)
        if text and text ~= "" then
            HotkeyUtil.UpdateHotkeyText(btn, bindingName, nil, nil, iconSize)
            return
        end
    end
    
    -- No binding found, clear hotkey text and persistence
    btn.HotkeyBinding = nil
    local hotKeyFrame = ResolveHotKeyFrame(btn)
    if hotKeyFrame then
        hotKeyFrame:SetText("")
        hotKeyFrame:Hide()
    end
end

-- Add tooltip line for a keybinding
function HotkeyUtil.AddTooltipBinding(tooltip, label, bindingName)
    if not tooltip or not bindingName then return end
    
    local keyText = HotkeyUtil.GetBindingKeyText(bindingName)
    if keyText and keyText ~= "" then
        tooltip:AddDoubleLine(label, keyText, 0.7, 0.7, 0.7, 0.2, 1, 0.2)
    end
end

-- Add tooltip lines for all bindings relevant to a button
function HotkeyUtil.AddTooltipBindings(tooltip, bindings)
    if not tooltip or not bindings then return end
    
    local hasAny = false
    for _, binding in ipairs(bindings) do
        local keyText = HotkeyUtil.GetBindingKeyText(binding.name)
        if keyText and keyText ~= "" then
            hasAny = true
        end
    end
    
    if hasAny then
        tooltip:AddLine(" ")
        tooltip:AddLine("Keybindings:", 0.8, 0.8, 0)
        for _, binding in ipairs(bindings) do
            local keyText = HotkeyUtil.GetBindingKeyText(binding.name)
            if keyText and keyText ~= "" then
                tooltip:AddDoubleLine("  " .. binding.label, keyText, 0.6, 0.6, 0.6, 0.2, 1, 0.2)
            end
        end
    end
end
-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local function ActiveExtraButtons()
    local ebs = Flux and Flux.EBS
    if ebs and ebs.buttons then return ebs.buttons end
    return FluxButtonEvents and FluxButtonEvents.ActiveButtons
end

--- Light refresh for a single keybind change (hotkey text + bound Extra buttons only).
function HotkeyUtil.RefreshAfterBindingChange()
    if InCombatLockdown and InCombatLockdown() then
        HotkeyUtil._deferredLightRefresh = true
        return
    end
    HotkeyUtil._deferredLightRefresh = nil
    local buttons = ActiveExtraButtons()
    if not buttons then return end
    for _, btn in ipairs(buttons) do
        if btn and btn.HotkeyBinding then
            HotkeyUtil.UpdateHotkeyText(btn, btn.HotkeyBinding, btn.HotkeyAddDynamicModifiers, btn.HotkeyHasModifierAssignments, btn.HotkeyIconSize)

            if btn.IsHearthButton and _G.FluxNCHearthstone and _G.FluxNCHearthstone.UpdateHearthKeybinding then
                pcall(_G.FluxNCHearthstone.UpdateHearthKeybinding, btn)
            elseif btn.IsMountButton and _G.FluxNCMount and _G.FluxNCMount.UpdateMountKeybinding then
                pcall(_G.FluxNCMount.UpdateMountKeybinding, btn)
            elseif btn.IsTeleportPortalButton and _G.FluxNCTeleportPortal and _G.FluxNCTeleportPortal.UpdateTeleportKeybinding then
                pcall(_G.FluxNCTeleportPortal.UpdateTeleportKeybinding, btn)
            elseif btn.IsFoodButton and _G.FluxNCFood and _G.FluxNCFood.UpdateKeybinding then
                pcall(_G.FluxNCFood.UpdateKeybinding)
            elseif btn.IsWaterButton and _G.FluxNCWater and _G.FluxNCWater.UpdateKeybinding then
                pcall(_G.FluxNCWater.UpdateKeybinding)
            elseif btn.IsManaGemButton and _G.FluxCombatManaGem and _G.FluxCombatManaGem.UpdateKeybinding then
                pcall(_G.FluxCombatManaGem.UpdateKeybinding)
            elseif btn.IsHealthstoneButton and _G.FluxCombatHealthstone and _G.FluxCombatHealthstone.UpdateKeybinding then
                pcall(_G.FluxCombatHealthstone.UpdateKeybinding)
            elseif btn.IsConsumableButton and _G.FluxNCConsumables and _G.FluxNCConsumables.UpdateKeybindings then
                pcall(_G.FluxNCConsumables.UpdateKeybindings)
            end
        end
    end
end

--- Re-apply Extra Button override binds + hotkey text after bulk SetBinding (Defaults).
function HotkeyUtil.FlushAfterBulkBindings()
    if InCombatLockdown and InCombatLockdown() then
        HotkeyUtil._deferredFlush = true
        return
    end
    HotkeyUtil._deferredFlush = nil

    -- Secure override rebinds (not just hotkey text)
    local modules = {}
    local function addModule(module)
        if module then modules[#modules + 1] = module end
    end
    addModule(_G.FluxNCFood)
    addModule(_G.FluxNCWater)
    addModule(_G.FluxNCConsumables)
    addModule(_G.FluxCombatHealthstone)
    addModule(_G.FluxCombatManaGem)
    addModule(_G.FluxCombatHealPotion)
    addModule(_G.FluxCombatManaPotion)
    addModule(_G.FluxCombatBandage)
    addModule(_G.FluxTrinketMenu)
    for i = 1, #modules do
        local m = modules[i]
        if m then
            if m.UpdateKeybindings then
                pcall(m.UpdateKeybindings)
            elseif m.UpdateKeybinding then
                pcall(m.UpdateKeybinding)
            end
        end
    end
    if _G.FluxNCHearthstone and _G.FluxNCHearthstone.UpdateHearthKeybinding then
        pcall(_G.FluxNCHearthstone.UpdateHearthKeybinding)
    end
    if _G.FluxNCMount and _G.FluxNCMount.UpdateMountKeybinding then
        pcall(_G.FluxNCMount.UpdateMountKeybinding)
    end
    if _G.FluxNCTeleportPortal and _G.FluxNCTeleportPortal.UpdateTeleportKeybinding then
        pcall(_G.FluxNCTeleportPortal.UpdateTeleportKeybinding)
    end

    HotkeyUtil.RefreshAfterBindingChange()
end

local eventFrame = CreateFrame("Frame")
-- Debounce UPDATE_BINDINGS: keybindings don't change on modifier presses,
-- but UPDATE_BINDINGS fires on every modifier press/release.
-- A short debounce coalesces Settings single-key edits without running the bulk flush.
local bindingUpdatePending = false
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if HotkeyUtil._deferredFlush then
            HotkeyUtil.FlushAfterBulkBindings()
        elseif HotkeyUtil._deferredLightRefresh then
            HotkeyUtil.RefreshAfterBindingChange()
        end
        return
    end
    if event == "UPDATE_BINDINGS" then
        if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            HotkeyUtil._deferredFlush = true
            return
        end
        if not bindingUpdatePending then
            bindingUpdatePending = true
            C_Timer.After(0.15, function()
                bindingUpdatePending = false
                if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
                    and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
                    HotkeyUtil._deferredFlush = true
                    return
                end
                -- Single-key edit: light refresh only (bulk Defaults uses FlushAfterBulkBindings).
                HotkeyUtil.RefreshAfterBindingChange()
            end)
        end
    elseif event == "MODIFIER_STATE_CHANGED" then
        -- Update modifier state immediately
        UpdateModifierState()
        
        -- Update hotkey text for buttons that use dynamic modifiers
        -- Use a small delay to batch multiple modifier changes
        if not self._modifierUpdatePending then
            self._modifierUpdatePending = true
            local Timer = C_Timer or {}
            if Timer.After then
                Timer.After(0.05, function()
                    self._modifierUpdatePending = false
                    local buttons = ActiveExtraButtons()
                    if buttons then
                        for _, btn in ipairs(buttons) do
                            if btn and btn.HotkeyBinding and (btn.HotkeyAddDynamicModifiers or btn.HotkeyHasModifierAssignments) then
                                HotkeyUtil.UpdateHotkeyText(btn, btn.HotkeyBinding, btn.HotkeyAddDynamicModifiers, btn.HotkeyHasModifierAssignments, btn.HotkeyIconSize)
                            end
                        end
                    end
                end)
            else
                -- Fallback for older clients
                self._modifierUpdatePending = false
                local buttons = ActiveExtraButtons()
                if buttons then
                    for _, btn in ipairs(buttons) do
                        if btn and btn.HotkeyBinding and (btn.HotkeyAddDynamicModifiers or btn.HotkeyHasModifierAssignments) then
                            HotkeyUtil.UpdateHotkeyText(btn, btn.HotkeyBinding, btn.HotkeyAddDynamicModifiers, btn.HotkeyHasModifierAssignments, btn.HotkeyIconSize)
                        end
                    end
                end
            end
        end
    end
end)
