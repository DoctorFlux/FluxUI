-- Execute the real HUD click wiring, quantity editor and per-character store.
-- Native secure execution and rendering still require in-game verification.
local checks = 0
local function check(value, message) assert(value, message); checks = checks + 1 end
local function read(path)
    local file = assert(io.open(path, "rb")); local source = file:read("*a"); file:close()
    return source:gsub("\r\n", "\n")
end
local families = {
    { "Era", "1.15.9", 2 }, { "TBC", "2.5.6", 5 }, { "Wrath", "3.4.3", 11 },
    { "Cata", "4.4.2", 14 }, { "Mists", "5.5.4", 19 },
    { "Live", "12.0.1", 1 }, { "Forever", "1.16.0", 1 },
}
for _, family in ipairs(families) do
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.wipe = function(value) for key in pairs(value) do value[key] = nil end; return value end
    local ns = { Flux = {} }; env.Flux = ns.Flux
    local state = { shift = false, combat = false, crafts = 0, timers = {}, canCraft = false }
    local methods = {}
    function methods:SetScript(key, fn) self.scripts[key] = fn end
    function methods:HookScript(key, fn)
        check(key ~= "OnClick", "native secure click handler retains ownership")
        self.hooks[key] = self.hooks[key] or {}; table.insert(self.hooks[key], fn)
    end
    function methods:Fire(key, ...)
        if self.scripts[key] then self.scripts[key](self, ...) end
        for _, fn in ipairs(self.hooks[key] or {}) do fn(self, ...) end
    end
    function methods:SetAttribute(key, value)
        assert(not state.combat, "protected write in combat"); self.attrs[key] = value
    end
    function methods:GetAttribute(key) return self.attrs[key] end
    function methods:RegisterEvent() end
    function methods:SetSize() end
    function methods:SetPoint() end
    function methods:SetFontObject() end
    function methods:SetJustifyH() end
    function methods:SetAutoFocus() end
    function methods:SetNumeric() end
    function methods:SetMaxLetters() end
    function methods:SetFrameLevel() end
    function methods:GetFrameLevel() return 10 end
    function methods:GetFont() return "font", 12, "" end
    function methods:SetFont() end
    function methods:SetText(value) self.text = value end
    function methods:GetText() return self.text end
    function methods:Show() self.shown = true end
    function methods:IsShown() return self.shown end
    function methods:Hide() local was = self.shown; self.shown = false; if was then self:Fire("OnHide") end end
    function methods:HighlightText() end
    function methods:SetFocus() self.focus = true end
    function methods:ClearFocus() if self.focus then self.focus = false; self:Fire("OnEditFocusLost") end end
    env.CreateFrame = function()
        return setmetatable({ scripts = {}, hooks = {}, attrs = {}, shown = true }, { __index = methods })
    end
    env.InCombatLockdown = function() return state.combat end
    env.IsShiftKeyDown = function() return state.shift end
    env.IsControlKeyDown = function() return state.ctrl end
    env.IsAltKeyDown = function() return false end
    env.C_Timer = { After = function(_, fn) state.timers[#state.timers + 1] = fn end }
    env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC, env.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 1, 2, 5
    env.WOW_PROJECT_WRATH_CLASSIC, env.WOW_PROJECT_CATACLYSM_CLASSIC, env.WOW_PROJECT_MISTS_CLASSIC = 11, 14, 19
    env.WOW_PROJECT_ID = family[3]
    env.GetBuildInfo = function() return family[2], "70000", "", 0 end
    local function run(path) return assert(load(read(path), "@" .. path, "t", env))("_FluxUI", ns) end
    run("Core/Client.lua")
    run("ExtraButtonSystem/Engine/ConsumableBind.lua")
    run("Inventory/Restock/Core/FluxRestockSettings.lua")
    run("Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua")
    run("Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua")
    run("Inventory/Restock/Core/Tiers/FluxRestockTiers_UI.lua")
    local bridge, tiers = env.FluxEBSConsumableBridge, env.FluxRestockTiers
    bridge.SuppressCheckedVisual = function() end
    bridge.SuppressCheckedVisualSettle = function() end
    env.FluxInv = { Craft = {
        GetBestCraftable = function() return state.canCraft and { craftable = 1, recipeID = 123 } or nil end,
        ExecuteCraft = function() if state.canCraft and not state.combat then state.crafts = state.crafts + 1 end end,
    } }
    local function flush() local timers = state.timers; state.timers = {}; for _, fn in ipairs(timers) do fn() end end
    local function makeButton()
        return { Widget = env.CreateFrame(), SlotFrame = env.CreateFrame(), WCount = env.CreateFrame() }
    end
    for _, kind in ipairs({ "food", "water", "bandage", "healPotion", "manaPotion" }) do
        local btn = makeButton()
        local craft = kind ~= "food" and kind ~= "water"
        state.canCraft, state.shift = false, false
        if craft then bridge.ApplyCraftOrRestockRightClick(btn, kind)
        else bridge.WireRestockEdit(btn, kind) end
        check(btn.Widget:GetAttribute("type2") == "macro" and btn.Widget:GetAttribute("typerelease2") == "macro"
            and btn.Widget:GetAttribute("macrotext2") == "/stopmacro", family[1] .. " " .. kind .. " edit suppresses item use on both phases")
        btn.Widget:Fire("OnMouseUp", "LeftButton")
        check(not btn._fluxCombatRestockEdit, "left-click does not edit")
        btn.Widget:Fire("OnMouseDown", "RightButton")
        check(not btn._fluxCombatRestockEdit, "press does not open then close editor")
        btn.Widget:Fire("OnMouseUp", "RightButton"); flush()
        local box = assert(btn._fluxCombatRestockEdit)
        check(box:IsShown() and box.focus and not btn.WCount:IsShown(), "one mouse release opens focused editor")
        box:SetText("40"); box:Fire("OnEnterPressed")
        local fields = tiers._Private.KIND_FIELDS[kind]
        check(tiers.GetTarget(kind) == 40 and env._FluxUI_CharSavedVars.Restock[fields.store][fields.target] == 40,
            family[1] .. " " .. kind .. " saves the shared vendor/bank target")
        check(not box:IsShown() and btn.WCount:IsShown(), "commit restores count")
        btn.Widget:Fire("OnMouseUp", "RightButton"); flush()
        box:SetText("99"); box:Fire("OnEscapePressed")
        check(tiers.GetTarget(kind) == 40 and not box:IsShown(), "escape preserves target")
        btn.Widget:Fire("OnMouseUp", "RightButton"); flush()
        box:SetText("25"); box:ClearFocus()
        check(tiers.GetTarget(kind) == 25 and not box:IsShown(), "focus loss saves target")
        state.combat = true
        bridge.WireRestockEdit(btn, kind)
        btn.Widget:Fire("OnMouseUp", "RightButton")
        check(not box:IsShown(), "combat cannot open target editor or write secure attributes")
        state.combat = false
        state.canCraft = true
        if craft then bridge.ApplyCraftOrRestockRightClick(btn, kind)
        else
            bridge.ApplyRightClickSpell(btn, "Conjure")
            bridge.WireRestockEdit(btn, kind, { mode = "shift-right" })
        end
        local action = btn.Widget:GetAttribute("macrotext2")
        check(action ~= "/stopmacro" and btn.Widget:GetAttribute("shift-macrotext2") == "/stopmacro"
            and btn.Widget:GetAttribute("shift-typerelease2") == "macro", "craft/conjure retains plain right and reserves Shift+right")
        btn.Widget:Fire("OnMouseUp", "RightButton")
        check(not box:IsShown(), "plain right does not open editor when crafting/conjuring")
        state.shift = true
        local crafts = state.crafts
        btn.Widget:Fire("OnMouseDown", "RightButton"); btn.Widget:Fire("PostClick", "RightButton")
        btn.Widget:Fire("OnMouseUp", "RightButton"); flush()
        check(box:IsShown() and state.crafts == crafts, "Shift+right opens editor without crafting")
        box:SetText("60"); box:Fire("OnEnterPressed")
        check(tiers.GetTarget(kind) == 60, "modified gesture saves target")
        state.shift = false
        state.ctrl = true
        btn.Widget:Fire("OnMouseUp", "RightButton")
        check(not box:IsShown(), "Ctrl+right remains available for secondary conjure")
        state.ctrl = false
        if craft then
            btn.Widget:Fire("OnMouseDown", "RightButton")
            check(state.crafts == crafts + 1, "plain right still crafts")
            state.canCraft = false; bridge.ApplyCraftOrRestockRightClick(btn, kind)
            check(btn.Widget:GetAttribute("shift-macrotext2") == nil, "craft depletion clears stale Shift action")
        else
            bridge.ApplyRightClickSpell(btn, nil)
            bridge.WireRestockEdit(btn, kind)
        end
        local hooks = #btn.Widget.hooks.OnMouseUp
        bridge.WireRestockEdit(btn, kind)
        check(#btn.Widget.hooks.OnMouseUp == hooks, "rewiring does not stack callbacks")
        btn.Widget:Fire("OnMouseUp", "RightButton"); flush()
        check(box:IsShown(), "right-click edit restored after craft/conjure disappears")
        box:Fire("OnEscapePressed")
    end
    -- Run the real food/water ApplyRC callbacks, including Recuperate coexistence.
    for _, name in ipairs({ "Food", "Water" }) do
        run("ExtraButtonSystem/NonCombatGrid/Buttons/" .. name .. ".lua")
        local source = read("ExtraButtonSystem/NonCombatGrid/Buttons/" .. name .. ".lua")
        local first = assert(source:find("local function ApplyRC(btn)", 1, true))
        local last = assert(source:find("\nlocal function ", first + 1, true))
        -- Food's helper functions are part of the production preamble.
        if name == "Food" then
            first = assert(source:find("local function ClearRightClickSpell", 1, true))
        end
        local callback = assert(load("local Module, IsConjuredFoodOnButton = ...\n" .. source:sub(first, last - 1)
            .. "\nreturn ApplyRC", "@" .. name .. ":ApplyRC", "t", env))(
                { HasRecuperate = function() return state.recuperate end }, function() return false end)
        bridge["Get" .. name .. "ConjureSpell"] = function() return "Conjure" end
        bridge["Get" .. name .. "SecondaryConjureSpell"] = function() return "Ritual" end
        for _, recuperate in ipairs({ false, true }) do
            state.recuperate = recuperate
            local btn = makeButton(); callback(btn)
            check(btn._fluxRestockEditClickMode == "shift-right" and btn.Widget:GetAttribute("shift-macrotext2") == "/stopmacro",
                family[1] .. " " .. name .. " reserves Shift+right with/without Recuperate")
            check(btn.Widget:GetAttribute("ctrl-macrotext2") == "/cast Ritual", "secondary conjure moves to Ctrl+right")
        end
    end
end
print("Consumable restock clicks: " .. checks .. " checks across seven client models; native secure VM unverified")
