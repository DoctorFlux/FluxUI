-- Production click/binding policy against pinned Blizzard secure dispatch.
-- Hardware, combat and frame access are desktop models, not native taint proof.
local clickPath = arg[1] or "Core/ButtonFX/Click.lua"
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s
end
for _, branch in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    for _, keyDown in ipairs({ false, true }) do
        local state = { combat = false, mod = "", actions = {}, frames = 0, writes = 0, overrides = {} }
        local env = setmetatable({}, { __index = _G }); env._G = env
        local function run(body, ...) return assert(load(body, "@menu-press", "t", env))(...) end
        env.InCombatLockdown = function() return state.combat end
        env.GetCVarBool = function(key) return key == "ActionButtonUseKeyDown" and keyDown end
        env.IsShiftKeyDown = function() return state.mod == "SHIFT" end
        env.IsControlKeyDown = function() return state.mod == "CTRL" end
        env.IsAltKeyDown = function() return state.mod == "ALT" end
        env.UnitExists = function() return true end
        env.UnitCanAttack = function() return false end
        env.UnitCanAssist = function() return false end
        env.SpellCanTargetItem = function() return false end
        env.SpellCanTargetItemID = function() return false end
        env.SecureCmdItemParse = function(item) return item end
        local function action(value) state.actions[#state.actions + 1] = value end
        env.SecureCmdUseItem = action
        env.CastSpellByName = action
        env.CastSpellByID = action
        env.C_Item = { IsEquippableItem = function() return false end }
        env.C_PaperDollInfo = { GetInventorySlotInfo = function() return 16 end, IsRangedSlotShown = function() return false end }
        env.GetInventorySlotInfo = env.C_PaperDollInfo.GetInventorySlotInfo
        env.C_Macro = { RunMacroText = action }
        local Frame = {}
        function Frame:GetAttribute(a, b, c)
            if not b then return self.attrs[a] end
            for _, key in ipairs({ a..b..c, "*"..b..c, a..b.."*", "*"..b.."*", a..b, b..c, b.."*", b }) do
                if self.attrs[key] ~= nil then return self.attrs[key] end
            end
        end
        function Frame:SetAttribute(key, value)
            check(not state.combat, "no insecure protected write in combat")
            self.attrs[key] = value; state.writes = state.writes + 1
        end
        function Frame:GetName() return self.name end
        function Frame:GetParent() return env.UIParent end
        function Frame:RegisterForClicks(...)
            self.clicks = {}; for _, edge in ipairs({...}) do self.clicks[edge] = true end
        end
        function Frame:EnableMouse() end
        function Frame:Hide() end
        function Frame:RegisterEvent() end
        function Frame:SetScript() end
        function Frame:WrapScript(widget, _, body) widget.wrap = body end
        function Frame:UnwrapScript(widget) widget.wrap = nil end
        function Frame:Execute(body) env.owner = self; run(body); env.owner = nil end
        function Frame:Click(button, down)
            if not self.clicks[down and "AnyDown" or "AnyUp"] then return end
            if self.wrap then
                local remap = run("return function(self, button, down)\n"..self.wrap.."\nend")(self, button, down)
                if remap == false then return end
                if type(remap) == "string" then button = remap end
            end
            -- SecureActionButtonTemplate supplies exactly these three arguments.
            env.SecureActionButton_OnClick(self, button, down)
        end
        env.CreateFrame = function(_, name)
            check(not state.combat, "no combat allocation")
            state.frames = state.frames + 1
            local f = setmetatable({ name = name, attrs = {} }, { __index = Frame })
            if name then env[name] = f end
            return f
        end
        env.UIParent = env.CreateFrame("Frame", "UIParent")
        env.GetFrameMetatable = function() return { __index = Frame } end
        env.CopyTable = function(t) local c = {}; for k, v in pairs(t) do c[k] = v end; return c end
        run(read("../__AddonsForRef/wow-ui-source-"..branch.."/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua"))
        local flux = { Restricted = { Works = function() return branch ~= "forever" end } }
        env.Flux = flux
        run(read(clickPath), "_FluxUI", { Flux = flux })
        run(read("ExtraButtonSystem/Engine/ConsumableBind.lua"))
        env.GetBindingKey = function(name) return name.."-1", name.."-2" end
        env.ClearOverrideBindings = function() state.overrides = {} end
        env.SetOverrideBindingClick = function(_, _, key, name, button) state.overrides[key] = { name, button } end
        local Click = flux.ButtonFX.Click
        for _, feature in ipairs({ "food", "water", "bandage", "healing potion", "mana gem", "mana potion", "healthstone", "trinket" }) do
            local w = env.CreateFrame("CheckButton", "MenuPressHost")
            w:SetAttribute("type1", "item"); w:SetAttribute("item1", feature)
            w:SetAttribute("type2", "spell"); w:SetAttribute("spell2", "Conjure "..feature)
            w:SetAttribute("shift-type1", "item"); w:SetAttribute("shift-item1", "shift "..feature)
            check(Click.Apply(w, { onDown = true }), "press policy ready")
            local btn = { Widget = w }
            env.FluxEBSConsumableBind.ApplyUseAndConjureBindings(btn, "USE", { conjureBindingName = "CREATE" })
            local use, conjure = state.overrides["USE-1"][2], state.overrides["CREATE-2"][2]
            for _, combat in ipairs({ false, true }) do
                state.combat = combat
                local writes, frames = state.writes, state.frames
                for _, input in ipairs({ "LeftButton", "RightButton", use, conjure }) do
                    local n = #state.actions
                    w:Click(input, true)
                    check(#state.actions == n + 1, branch.." "..feature.." fires on press: "..input)
                    w:Click(input, false)
                    check(#state.actions == n + 1, "release never repeats the action")
                    check(state.actions[n + 1] == ((input == "RightButton" or input == conjure) and "Conjure "..feature or feature), "use/conjure identity preserved")
                end
                state.mod = "SHIFT"
                local n = #state.actions; w:Click(use, true); w:Click(use, false)
                check(#state.actions == n + 1 and state.actions[n + 1] == "shift "..feature, "live modifier action preserved")
                state.mod = ""
                check(state.writes == writes and state.frames == frames, "input allocates and rewrites nothing")
                if combat then check(Click.Apply(w, { onDown = true }) == false, "combat setup remains deferred") end
            end
            state.combat = false
            -- Rebinding retains the second key, and returning to ordinary policy works.
            env.FluxEBSConsumableBind.ApplyBinding(btn, "USE")
            check(state.overrides["USE-2"] ~= nil, "secondary binding retained")
            check(Click.Apply(w), "ordinary policy restored")
            local n = #state.actions; w:Click("LeftButton", true)
            check(#state.actions == n, "ordinary mouse still waits for release")
            w:Click("LeftButton", false)
            check(#state.actions == n + 1, "ordinary release preserved")
        end
    end
end
print("menu_press_input: "..checks.." checks PASS (five existing clients; both CVars; mouse/use/conjure; modifiers; combat model)")
