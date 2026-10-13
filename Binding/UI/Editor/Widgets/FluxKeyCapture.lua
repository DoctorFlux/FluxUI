--[[ Key chord capture widget for Flux binding editor. ]]

local Type, Version = "FluxKeyCapture", 3
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local L = _G.FluxSpellBindingLocale or setmetatable({}, { __index = function(_, k) return k end })

local ignoreKeys = {
    UNKNOWN = true,
    LSHIFT = true, LCTRL = true, LALT = true, LMETA = true,
    RSHIFT = true, RCTRL = true, RALT = true, RMETA = true,
    SHIFT = true, CTRL = true, ALT = true, META = true,
}

local function GenerateChord(key)
    if ignoreKeys[key] then return nil end
    local chord = {}
    if IsAltKeyDown() then chord[#chord + 1] = "ALT" end
    if IsControlKeyDown() then chord[#chord + 1] = "CTRL" end
    if IsShiftKeyDown() then chord[#chord + 1] = "SHIFT" end
    if IsMetaKeyDown and IsMetaKeyDown() then chord[#chord + 1] = "META" end
    chord[#chord + 1] = key
    return table.concat(chord, "-")
end

local function EnableKeyCapture(frame)
    local self = frame.obj
    if self.locked or self.disabled then return end
    frame:EnableKeyboard(true)
    frame:EnableMouseWheel(true)
    if frame.EnableGamePadButton then frame:EnableGamePadButton(true) end
    frame:LockHighlight()
    self.waitingForKey = true
    self.button:SetText(L["Press any key or ESC to cancel"] or "Press any key or ESC to cancel")
end

local function DisableKeyCapture(frame)
    local self = frame.obj
    frame:EnableKeyboard(false)
    frame:EnableMouseWheel(false)
    if frame.EnableGamePadButton then frame:EnableGamePadButton(false) end
    frame:UnlockHighlight()
    self.waitingForKey = nil
    self.lastClickTime = GetTime()
    self:UpdateText()
end

local function Keybinding_OnClick(frame, button)
    local self = frame.obj
    if self.locked or self.disabled then
        AceGUI:ClearFocus()
        return
    end
    local passed = GetTime() - (self.lastClickTime or 0)
    if button == "LeftButton" then
        if not self.waitingForKey and passed > 0.01 then EnableKeyCapture(frame) end
    elseif button == "RightButton" then
        if not self.waitingForKey and passed > 0.01 then
            -- Inherited (bar/Extra) keys cannot be cleared here — only manual Flux keys.
            if self.inherited or self.locked then
                return
            end
            self:SetKey("")
            self:Fire("OnKeyChanged", "")
        end
    end
    AceGUI:ClearFocus()
end

local function Keybinding_OnKeyDown(frame, key)
    local self = frame.obj
    if not self.waitingForKey then return end
    if self.locked or self.disabled then
        DisableKeyCapture(frame)
        return
    end
    if key == "ESCAPE" then
        DisableKeyCapture(frame)
        return
    end
    local chord = GenerateChord(key)
    if chord ~= nil then
        DisableKeyCapture(frame)
        if not self.disabled then
            self:SetKey(chord)
            self:Fire("OnKeyChanged", chord)
        end
    end
end

local function Keybinding_OnMouseDown(frame, button)
    if button == "LeftButton" then button = "BUTTON1"
    elseif button == "RightButton" then button = "BUTTON2"
    elseif button == "MiddleButton" then button = "BUTTON3"
    elseif string.match(button, "Button%d") then button = string.upper(button) end
    Keybinding_OnKeyDown(frame, button)
end

local function Keybinding_OnMouseWheel(frame, direction)
    Keybinding_OnKeyDown(frame, direction >= 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN")
end

local Methods = {}

function Methods:OnAcquire()
    self:BaseOnAcquire()
    self.key = ""
    self.hasMarker = false
    self.inherited = false
    self.locked = false
end

function Methods:SetKey(key)
    self.key = key or ""
    self:UpdateText()
end

function Methods:GetKey()
    return self.key
end

function Methods:SetMarker(marker)
    self.hasMarker = marker and true or false
    self:UpdateText()
end

--- Inherited from action bar / Extra / stance (not a manual Flux key).
function Methods:SetInherited(inherited)
    self.inherited = inherited and true or false
    self:UpdateText()
end

function Methods:IsInherited()
    return self.inherited and true or false
end

--- Locked Extra/Bindings.xml keys: shown, not editable.
function Methods:SetLocked(locked)
    self.locked = locked and true or false
    if self.locked and self.waitingForKey then
        DisableKeyCapture(self.frame)
    end
    self:UpdateText()
end

function Methods:IsLocked()
    return self.locked and true or false
end

function Methods:UpdateText()
    local key = self.key or ""
    local button = self.button
    if key == "" then
        button:SetText(NOT_BOUND)
        button:SetNormalFontObject("GameFontNormal")
        if button.GetFontString then
            local fs = button:GetFontString()
            if fs then fs:SetTextColor(1, 0.82, 0) end
        end
    elseif self.locked or self.inherited then
        -- Dim cyan — on bar/Extra/stance / Bindings.xml (no edit).
        button:SetText(key)
        button:SetNormalFontObject("GameFontHighlight")
        if button.GetFontString then
            local fs = button:GetFontString()
            if fs then fs:SetTextColor(0.55, 0.75, 0.95) end
        end
    else
        button:SetText(self.hasMarker and (key .. "*") or key)
        button:SetNormalFontObject("GameFontHighlight")
        if button.GetFontString then
            local fs = button:GetFontString()
            if fs then fs:SetTextColor(1, 1, 1) end
        end
    end
end

local function Constructor()
    local widget = AceGUI:Create("Keybinding")
    widget.type = Type
    local button = widget.button
    button:SetScript("OnClick", Keybinding_OnClick)
    button:SetScript("OnKeyDown", Keybinding_OnKeyDown)
    button:SetScript("OnMouseDown", Keybinding_OnMouseDown)
    button:SetScript("OnMouseWheel", Keybinding_OnMouseWheel)
    if button.SetScript then
        button:SetScript("OnGamePadButtonDown", Keybinding_OnKeyDown)
    end
    widget.BaseOnAcquire = widget.OnAcquire
    for method, func in pairs(Methods) do widget[method] = func end
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
