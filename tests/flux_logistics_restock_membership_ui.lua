local sourcePath = assert(arg[1], "pass the installed, baseline, or candidate ConsumablesConfig.lua")
local export = setmetatable({FLUX_AH_SOURCES_FIXTURE_EXPORT = true}, {__index = _G})
local boot = assert(loadfile("tests/auction_restock_sources.lua", "t", export))()
local _, st, env, loadOwner = boot(false, true, false)
env.Flux = st.flux
loadOwner("Inventory/Restock/Core/FluxRestockPolicy.lua")
loadOwner("ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua")
local policy, owner = st.flux.RestockPolicy, env.FluxNCConsumables
assert(policy.RegisterPlanner({GetCoverage = function() return {} end, Request = function() return true end}))
policy.SetManaged(true)
env._FluxUI_CharSavedVars.consumables = {
    activePreset = "default",
    presets = {
        default = {items = {17001}, restockTargets = {[17001] = 30}},
        legacyInactive = {items = {17002}, restockTargets = {[17002] = 70}},
        explicitOther = {items = {17003}, restockTargets = {[17003] = 50}, restockMembership = {openworld = true}},
        restockDisabled = {items = {17004}, restockTargets = {[17004] = 100}, restockEnabled = false},
        presetDisabled = {items = {17005}, restockTargets = {[17005] = 90}, enabled = false},
    },
}
local config = env._FluxUI_CharSavedVars.consumables
local widgets, modeDropdown = {}, nil
local checks, failures = 0, 0
local function same(actual, expected, label)
    checks = checks + 1
    if actual ~= expected then
        failures = failures + 1
        print(("FAIL %s (got %s, expected %s)"):format(label, tostring(actual), tostring(expected)))
    end
end
local function noop() end
local function widget()
    local w = {SetSize = noop, SetPoint = noop}
    function w:SetChecked(checked) self.checked = checked end
    function w:GetChecked() return self.checked end
    function w:SetEnabled(enabled) self.enabled = enabled end
    function w:SetScript(event, callback) self[event] = callback end
    function w:CreateFontString()
        return {SetPoint = noop, SetText = function(_, text) widgets[text] = self end}
    end
    return w
end
env.CreateFrame = function() return widget() end
env.FluxBlizzardDropdown = {Create = function()
    local dropdown = widget()
    function dropdown:FluxSetMenu(menu) self.menu = menu end
    function dropdown:FluxSetText(text) self.text = text end
    modeDropdown = dropdown
    return dropdown
end}
-- Execute the production widget initialization and actual callbacks. Supply
-- only the frame and placement locals from the surrounding editor layout.
local handle = assert(io.open(sourcePath, "rb"))
local source = handle:read("*a")
handle:close()
local first = assert(source:find("    local policy = _G.Flux and _G.Flux.RestockPolicy\n    local policyHeight", 1, true)
    or source:find("    local policy = _G.Flux and _G.Flux.RestockPolicy\r\n    local policyHeight", 1, true))
local last = assert(source:find("    -- Scrollable content", first, true))
local frame = widget()
assert(load("local frame = ...; local PADDING, thresholdRowY = 16, 0\n" .. source:sub(first, last-1),
    "@ConsumablesConfig.lua:restock-widget-block", "t", env))(frame)
local function activePreset(name)
    config.activePreset = name
    frame.RefreshRestockControls()
end
local function chooseMode(key)
    local text = policy.Text[key]
    for _, entry in ipairs(modeDropdown.menu()) do
        if entry.text == text then entry.func(); return end
    end
    error("mode control missing")
end
local function click(name, enabled)
    local button = assert(widgets[policy.Text[name]])
    button:SetChecked(enabled)
    button.OnClick(button)
end

frame.RefreshRestockControls()
same(widgets[policy.Text.normal]:GetChecked(), true, "selected legacy preset displays Normal")
same(owner.GetEffectiveRestockTargets()[17001], 30, "legacy Normal target")
same(owner.GetEffectiveRestockTargets()[17002], nil, "inactive legacy preset absent")
same(owner.GetEffectiveRestockTargets()[17003], nil, "open-world target absent in Normal")
same(widgets[policy.Text.managed].enabled, false, "Normal disables passive control")
same(policy.AllowsPassive(), false, "Normal remains manual even with managed preference saved")

click("raid", true)
local membership = owner.GetPresetRestockMembership()
same(membership.normal, true, "adding a mode materializes the displayed legacy Normal membership")
same(membership.raid, true, "clicked mode is saved")
same(widgets[policy.Text.normal]:GetChecked(), true, "an unrelated edit preserves Normal checkmark")
same(owner.GetEffectiveRestockTargets()[17001], 30, "an unrelated edit preserves the Normal target")
same(owner.GetEffectiveRestockTargets()[17002], nil, "unrelated edit leaves inactive legacy targets absent")
chooseMode("openworld")
same(widgets[policy.Text.managed].enabled, true, "Open world enables managed control")
same(owner.GetEffectiveRestockTargets()[17001], 30, "Open world inherits Normal target")
same(owner.GetEffectiveRestockTargets()[17003], 50, "other preset contributes its explicit open-world target")
same(owner.GetActivePreset(), "default", "changing mode keeps the current HUD preset")
chooseMode("normal")

config.presets.default.restockMembership = nil
frame.RefreshRestockControls()
click("all", true)
same(owner.GetPresetRestockMembership().normal, true, "All modes preserves the legacy membership")
same(owner.GetEffectiveRestockTargets()[17001], 30, "All modes contributes the target in Normal")
same(policy.AllowsPassive(), false, "All modes cannot authorize passive work in Normal")
click("all", false)
same(owner.GetEffectiveRestockTargets()[17001], 30, "All modes round-trip restores the prior effective target")
same(widgets[policy.Text.normal]:GetChecked(), true, "All modes round-trip preserves the Normal checkmark")

config.presets.default.restockMembership = nil
frame.RefreshRestockControls()
click("normal", false)
same(owner.GetEffectiveRestockTargets()[17001], nil, "explicitly unchecking the legacy Normal membership removes it")
click("raid", true)
same(owner.GetEffectiveRestockTargets()[17001], nil, "later edits preserve explicit Normal false")
click("all", true)
click("all", false)
same(owner.GetPresetRestockMembership().normal, false, "All modes round-trip preserves explicit Normal false")
same(owner.GetPresetRestockMembership().raid, true, "All modes round-trip preserves explicit Raid true")

for _, row in ipairs({{"restockDisabled", 17004}, {"presetDisabled", 17005}}) do
    activePreset(row[1])
    same(widgets[policy.Text.enabled]:GetChecked(), false, "disabled preset displays disabled")
    click("all", true)
    same(widgets[policy.Text.enabled]:GetChecked(), false, "membership edit does not enable the preset")
    same(owner.GetEffectiveRestockTargets()[row[2]], nil, "disabled All modes target stays omitted")
end
activePreset("default")
chooseMode("raid")
same(owner.GetEffectiveRestockTargets()[17001], 30, "explicit Raid-only preset works in Raid")
same(owner.GetEffectiveRestockTargets()[17003], 50, "Raid still inherits another preset's Open world target")
same(owner.GetEffectiveRestockTargets()[17002], nil, "inactive legacy target stays absent in Raid")

print(("Restock membership UI: %d checks, %d failures"):format(checks, failures))
if failures > 0 then os.exit(1) end
