-- lua tests/grid_hotkey_refresh.lua
-- Exercise the loaded hotkey utility against the current EBS button registry.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local checks = 0
local function check(ok, message)
    assert(ok, message)
    checks = checks + 1
end

local bindings = {}
local function button(command, flag)
    local hotkey = { visible = false, text = "" }
    for _, method in ipairs({ "ClearAllPoints", "SetPoint", "SetSize", "SetFontObject",
        "SetFont", "SetTextColor", "SetJustifyH", "SetJustifyV", "SetWordWrap" }) do
        hotkey[method] = function() end
    end
    hotkey.GetWidth = function() return 30 end
    hotkey.GetFont = function() return "font" end
    hotkey.SetText = function(_, value) hotkey.text = value end
    hotkey.Show = function() hotkey.visible = true end
    hotkey.Hide = function() hotkey.visible = false end
    local widget = { GetWidth = function() return 44 end,
        GetHeight = function() return 44 end }
    local btn = { Widget = widget, WHotKey = hotkey }
    btn[flag] = true
    return btn, hotkey, command
end

local mount, mountText = button("FLUXGRIDSMARTMOUNT", "IsMountButton")
local hearth, hearthText = button("FLUXGRIDHEARTH", "IsHearthButton")
local combat, combatText = button("FLUXCOMBAT_HEALTHSTONE", "IsHealthstoneButton")
local updateCalls = { mount = 0, hearth = 0, combat = 0 }
local env = {
    Flux = { EBS = { buttons = { mount, hearth, combat } } },
    FLUX_API = { majorVersion = 12 },
    InCombatLockdown = function() return false end,
    GetBindingKey = function(command) return bindings[command] end,
    GetBindingText = function(key) return key end,
    CreateFrame = function()
        return { RegisterEvent = function() end, SetScript = function() end }
    end,
    FluxNCMount = { UpdateMountKeybinding = function() updateCalls.mount = updateCalls.mount + 1 end },
    FluxNCHearthstone = { UpdateHearthKeybinding = function() updateCalls.hearth = updateCalls.hearth + 1 end },
    FluxCombatHealthstone = { UpdateKeybinding = function() updateCalls.combat = updateCalls.combat + 1 end },
}
env._G = env
setmetatable(env, { __index = _G })
assert(loadfile(root .. "ExtraButtonSystem/Shared/HotkeyUtil.lua", "t", env))()
local util = env.FluxNCHotkeyUtil

for btn, command in pairs({ [mount] = "FLUXGRIDSMARTMOUNT",
        [hearth] = "FLUXGRIDHEARTH", [combat] = "FLUXCOMBAT_HEALTHSTONE" }) do
    util.UpdateHotkeyText(btn, command)
end
check(not mountText.visible and not hearthText.visible and not combatText.visible,
    "buttons created before bindings have empty labels")

bindings.FLUXGRIDSMARTMOUNT = "Y"
bindings.FLUXGRIDHEARTH = "7"
bindings.FLUXCOMBAT_HEALTHSTONE = "ALT-Z"
util.FlushAfterBulkBindings()
check(mountText.visible and mountText.text == "Y", "noncombat mount label appears after seed")
check(hearthText.visible and hearthText.text == "7", "noncombat hearth label appears after seed")
check(combatText.visible and combatText.text == "A-Z", "combat grid label appears after seed")
check(updateCalls.mount > 0 and updateCalls.hearth > 0 and updateCalls.combat > 0,
    "both grids' secure click owners are refreshed after bulk bindings")

bindings.FLUXGRIDHEARTH = nil
util.RefreshAfterBindingChange()
check(not hearthText.visible and hearthText.text == "", "unbound label clears on current registry")

env.Flux.EBS = nil
env.FluxButtonEvents = { ActiveButtons = { hearth } }
bindings.FLUXGRIDHEARTH = "7"
util.RefreshAfterBindingChange()
check(hearthText.visible and hearthText.text == "7", "legacy registry fallback remains available")

print("grid hotkey refresh: " .. checks .. " checks passed")
