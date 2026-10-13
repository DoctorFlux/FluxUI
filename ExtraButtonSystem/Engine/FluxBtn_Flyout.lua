--[[
    ExtraButtonSystem/Engine/FluxBtn_Flyout.lua

    Cross-client flyout helpers for FluxBtn.
    Classic Era: prefer native SecureActionButton type=flyout when available.
    Anniversary / post-DF: FluxButton already uses spellbook lookup + optional
    FluxFlyoutFrame; this module exposes Compat flags and a small apply helper.
]]

FluxBtn = FluxBtn or {}
local Flyout = {}
FluxBtn.Flyout = Flyout

local function Compat()
    return FluxBtn.Compat
end

--- Apply flyout secure attributes for a button widget.
--- flyoutID: numeric flyout id from spellbook
function Flyout.ApplyAttributes(widget, flyoutID)
    if not widget or not flyoutID or InCombatLockdown() then
        return false
    end
    local c = Compat()
    if c and c.useNativeFlyout then
        widget:SetAttribute("type", "flyout")
        widget:SetAttribute("typerelease", "flyout")
        widget:SetAttribute("spell", flyoutID)
        return true
    end
    -- Modern: leave attribute setup to FluxButton:SetAction("flyout", id)
    -- which uses spellbook index / custom flyout click path.
    widget:SetAttribute("type", "flyout")
    widget:SetAttribute("typerelease", "flyout")
    widget:SetAttribute("spell", flyoutID)
    return true
end

function Flyout.ClearAttributes(widget)
    if not widget or InCombatLockdown() then
        return
    end
    widget:SetAttribute("type", nil)
    widget:SetAttribute("typerelease", nil)
    widget:SetAttribute("spell", nil)
end

function Flyout.UsesNative()
    local c = Compat()
    return c and c.useNativeFlyout or false
end

_G.FluxBtn = FluxBtn
