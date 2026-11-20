-- Opening the production hover binder must retain the current native binding
-- set and live edits. LibKeyBound owns explicit checkbox, Save and Cancel work.
local root = arg[1] or "."
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function read(path)
    local f = assert(io.open(path, "rb")); local source = f:read("*a"); f:close(); return source
end
local function compile(source, env)
    if setfenv then local fn = assert(loadstring(source)); setfenv(fn, env); return fn end
    return assert(load(source, "@binding_mode_scope_safety", "t", env))
end
for _, client in ipairs({ "live", "forever", "classic", "era", "anniversary" }) do
    for _, set in ipairs({ 1, 2 }) do
        local s = { set = set, action = "CUSTOM_UNSAVED", loads = 0, saves = 0, callbacks = {}, pending = {} }
        local checkbox = { SetChecked = function(self, value) self.checked = value end }
        local env = setmetatable({}, { __index = _G }); env._G = env
        env.GetCurrentBindingSet = function() return s.set end
        env.LoadBindings = function(index) s.set = index; s.action = "SAVED_" .. index; s.loads = s.loads + 1 end
        env.SaveBindings = function(index) s.saves = s.saves + 1; s.savedSet = index; s.savedAction = s.action end
        env.InCombatLockdown = function() return false end
        env.KeyboundDialogCheck = checkbox
        env.KeyboundDialog = { HookScript = function() end }
        env.C_Timer = { After = function(_, fn) s.pending[#s.pending + 1] = fn end }
        local keybound = { Set = function() end, RegisterCallback = function(_, event, fn) s.callbacks[event] = fn end,
            IsShown = function() return s.shown end }
        -- These are the verified LibKeyBound dialog boundaries: OnShow reflects
        -- the selected set; only explicit checkbox/Save/Cancel change native data.
        function keybound:Activate()
            s.shown = true; checkbox:SetChecked(env.GetCurrentBindingSet() == 2)
            s.callbacks.LIBKEYBOUND_ENABLED()
        end
        function keybound:Deactivate() s.shown = false; s.callbacks.LIBKEYBOUND_DISABLED() end
        env.LibStub = function(name) if name == "LibKeyBound-1.0" then return keybound end end
        compile(read(root .. "/Bars/BindingMode.lua"), env)("_FluxUI", { Flux = { Bars = { NUM_COLUMNS = 1 } } })
        local function flush()
            local pending = s.pending; s.pending = {}; for _, fn in ipairs(pending) do fn() end
        end
        local binder = env.FluxBindingMode
        binder:Activate(); flush()
        check(binder:IsActive() and s.shown, client .. " binder activates")
        check(s.set == set and s.loads == 0 and s.saves == 0, client .. " binder opening retains selected native scope")
        check(s.action == "CUSTOM_UNSAVED", client .. " binder opening retains live unsaved keys")
        check(checkbox.checked == (set == 2), client .. " native scope checkbox retains selection")
        binder:Deactivate(); flush()
        check(not binder:IsActive(), client .. " binder deactivates")
        s.action = "CUSTOM_REOPEN"
        binder:Activate(); flush()
        check(s.set == set and s.loads == 0 and s.action == "CUSTOM_REOPEN", client .. " repeated opens retain custom bindings")
        -- A player may choose the other set while the dialog is open. A delayed
        -- Flux callback must not replace that explicit selection with account.
        env.LoadBindings(set == 1 and 2 or 1)
        checkbox:SetChecked(s.set == 2)
        s.callbacks.LIBKEYBOUND_ENABLED(); flush()
        check(s.set == (set == 1 and 2 or 1) and s.loads == 1, client .. " explicit scope switch remains selected")
        check(checkbox.checked == (s.set == 2), client .. " explicit scope checkbox remains selected")
    end
end
print("binding_mode_scope_safety: " .. checks .. " checks PASS")
