-- FluxSalvage_Settings.lua
-- Saved settings and change callbacks for the salvage overlay.

FluxSalvage = FluxSalvage or {}
local S = FluxSalvage

local modifierCallbacks = {}

local function EnsureDB()
    FluxSalvageDB = FluxSalvageDB or {}
    if FluxSalvageDB.enabled == nil then
        FluxSalvageDB.enabled = true
    end
    if FluxSalvageDB.modifier == nil then
        FluxSalvageDB.modifier = "ALT"
    end
    return FluxSalvageDB
end

function S.IsEnabled()
    local db = EnsureDB()
    return db.enabled ~= false
end

function S.SetEnabled(enabled)
    local db = EnsureDB()
    db.enabled = enabled and true or false
end

function S.GetModifier()
    local db = EnsureDB()
    return db.modifier or "ALT"
end

function S.SetModifier(value)
    local db = EnsureDB()
    db.modifier = value or "ALT"
    for i = 1, #modifierCallbacks do
        modifierCallbacks[i](db.modifier)
    end
end

function S.RegisterModifierCallback(callback)
    if type(callback) == "function" then
        modifierCallbacks[#modifierCallbacks + 1] = callback
    end
end

function S.ModifierActive()
    local modifier = S.GetModifier()
    if not IsAltKeyDown() then
        return false
    end
    if modifier == "CTRL" then
        return IsControlKeyDown()
    end
    if modifier == "SHIFT" then
        return IsShiftKeyDown()
    end
    return not IsControlKeyDown() and not IsShiftKeyDown()
end

function S.ModifierReleased()
    local modifier = S.GetModifier()
    if modifier == "CTRL" and not IsControlKeyDown() then
        return true
    end
    if modifier ~= "CTRL" and IsControlKeyDown() then
        return true
    end
    if modifier == "SHIFT" and not IsShiftKeyDown() then
        return true
    end
    if modifier ~= "SHIFT" and IsShiftKeyDown() then
        return true
    end
    return false
end

EnsureDB()
