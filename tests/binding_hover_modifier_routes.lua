-- Production hover snippets and native attribute lookup; hardware/taint remain native checks.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s:gsub("\r\n", "\n")
end
local source = read(arg[1] or "Binding/Input/FluxMouseoverKeybind.lua")
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
-- Run Blizzard's complete builder, including its raw substring restrictions.
-- Lua 5.4 shims model only 5.1 load/environment plumbing, not WoW security.
local validatorPath = "../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedExecution.lua"
local validatorSource = read(validatorPath)
local validatorEnd = assert(validatorSource:find("local CLOSURE_CACHE_MAX", 1, true))
local nativeEnv = setmetatable({
    scrub = function(...) return ... end,
    IsFrameHandle = function(value) return type(value) == "table" end,
    loadstring_untainted = function(body, name) return load(body, name, "t", {}) end,
    setfenv = function(fn, env)
        for i = 1, math.huge do
            local name = debug.getupvalue(fn, i)
            if not name then break end
            if name == "_ENV" then debug.setupvalue(fn, i, env); break end
        end
        return fn
    end,
}, { __index = _G })
local buildRestrictedClosure = assert(load(validatorSource:sub(1, validatorEnd - 1)
    .. "\nreturn BuildRestrictedClosure", "@native-restricted-builder", "t", nativeEnv))("_FluxUI", {})
for _, body in ipairs({ 'local kind = "function"', "local f = function() end" }) do
    local closure, err = buildRestrictedClosure(body, {})
    check(closure == nil and err == "The function keyword is not permitted",
        "native validator rejects raw blocked text even inside a quoted literal")
end
do
    local closure, err = buildRestrictedClosure("local t = {}", {})
    check(closure == nil and err == "Direct table creation is not permitted",
        "native validator retains its direct-table restriction")
end
local function fixture(editMode, wraps)
    local e = setmetatable({ UIParent = {}, unpack = table.unpack }, { __index = _G }); e._G = e
    e.FLUX_API = { hasEditMode = editMode, hasRestrictedClosures = wraps }
    e.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    e.InCombatLockdown = function() return e.combat end
    e.GetTime = function() return 10 end
    e.C_Timer = { After = function() end }
    e.C_AddOns = { IsAddOnLoaded = function() return false end }
    e.GetBindingKey = function(cmd) if cmd == "ACTIONBUTTON9" then return "R" end end
    e.nativeCommands, e.worldTargets = {}, {}
    e.GetBindingAction = function(key, overrides)
        check(overrides == false, "ownership reads use native exact commands")
        return e.nativeCommands[key] or ""
    end
    e.RegisterAttributeDriver, e.UnregisterAttributeDriver = function() end, function() end
    local frames, methods = {}, {}
    local function legal() assert(not e.combat or e.secureDepth > 0, "protected write outside secure transport") end
    function methods:GetName() return self.name end
    function methods:GetParent() return self.parent end
    function methods:GetChildren() return table.unpack(self.children) end
    function methods:IsForbidden() return false end
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown end
    function methods:IsUnderMouse() return self.hovered end
    function methods:IsMouseEnabled() return true end
    function methods:IsObjectType(kind) return self.kind == kind end
    function methods:GetAttribute(a, b, c)
        if b then return self.attrs[a .. b .. c] or self.attrs["*" .. b .. c]
            or self.attrs[a .. b .. "*"] or self.attrs["*" .. b .. "*"] or self.attrs[b] end
        return self.attrs[a]
    end
    function methods:SetAttribute(k, v) legal(); self.attrs[k] = v end
    function methods:SetFrameRef(k, v) legal(); self.refs[k] = v end
    function methods:GetFrameRef(k) return self.refs[k] end
    function methods:SetScript(k, v) self.scripts[k] = v end
    function methods:HookScript(k, v) legal(); self.hooks[k] = self.hooks[k] or {}; table.insert(self.hooks[k], v) end
    function methods:RegisterEvent(k) self.events[k] = true end
    function methods:RegisterForClicks(...) legal(); self.edges = { ... } end
    function methods:EnableMouseWheel() legal() end
    function methods:SetPassThroughButtons(...) legal(); self.pass = { ... } end
    function methods:SetBindingClick(_, key, name, button)
        assert(e.secureDepth > 0, "only secure snippets install hover overrides"); self.binds[key] = { name, button }
    end
    function methods:SetBinding(_, key, action)
        assert(e.secureDepth > 0, "only secure snippets preserve exact native commands")
        self.binds[key] = { command = action }
    end
    function methods:ClearBinding(key) assert(e.secureDepth > 0); self.binds[key] = nil end
    local function execute(header, frame, code, name, value)
        local s = header.secure
        local previous = { s.self, s.control, s.name, s.value }
        s.self, s.control, s.name, s.value = frame, header, name, value
        e.secureDepth = (e.secureDepth or 0) + 1
        local closure, err = buildRestrictedClosure(code, s, "self,...")
        e.lastRestrictedError = err
        check(type(closure) == "function", "native restricted validator accepts production snippet: " .. tostring(err))
        local result = table.pack(closure(frame))
        e.secureDepth = e.secureDepth - 1
        s.self, s.control, s.name, s.value = table.unpack(previous, 1, 4)
        return table.unpack(result, 1, result.n)
    end
    function methods:Execute(code) return execute(self, self, code) end
    function methods:RunFor(frame, code) return execute(self, frame, code) end
    function methods:WrapScript(frame, event, code) legal(); frame.wraps[event] = { header = self, code = code } end
    function methods:UnwrapScript(frame, event) legal(); frame.wraps[event] = nil end
    e.CreateFrame = function(kind, name, parent)
        local f = setmetatable({ kind = kind, name = name, parent = parent, attrs = {}, refs = {}, scripts = {},
            hooks = {}, events = {}, binds = {}, wraps = {}, children = {}, shown = true }, { __index = methods })
        f.secure = { newtable = function(...) return { ... } end, type = type,
            UnitExists = function(unit) return e.units == nil or e.units[unit] ~= false end,
            table = setmetatable({ maxn = function(t) return #t end }, { __index = table }) }
        frames[#frames + 1] = f; if name then e[name] = f end
        if parent and parent.children then parent.children[#parent.children + 1] = f end
        return f
    end
    local strip = e.CreateFrame("Button", "FluxActionStripButton9")
    strip.attrs["type*"], strip.attrs["action*"] = "action", 9
    strip.attrs["shift-type*"], strip.attrs["shift-action*"] = "action", 69
    strip.attrs["ctrl-type*"], strip.attrs["ctrl-action*"] = "action", 33
    local keyer = e.CreateFrame("Button", "FluxActionStripKey9", strip)
    keyer.attrs["useparent-type"], keyer.attrs["useparent-action"] = true, true
    local ns = { Flux = { ButtonFX = { Click = { UsesWrap = function() return wraps end } } } }
    ns.Flux.Restricted = { Works = function() return wraps end,
        Execute = function(h, code) h:Execute(code); return true end,
        SetSnippet = function(h, k, v) h:SetAttribute(k, v); return true end,
        WrapScript = function(h, f, event, code) h:WrapScript(f, event, code); return true end,
        UnwrapScript = function(h, f, event) h:UnwrapScript(f, event) end }
    e.FluxBinding = {
        FindColumnForChord = function(chord) return (chord:match("R$") or chord:match("BUTTON4$")) and 9 end,
        GetWorldChordTarget = function(chord)
            local name = e.worldTargets[chord]
            if name then return name, "LeftButton" end
        end,
    }
    assert(load(source, "@FluxMouseoverKeybind", "t", e))("_FluxUI", ns)
    local eventFrame = frames[#frames]
    eventFrame.scripts.OnEvent(eventFrame, "PLAYER_LOGIN")
    local module = ns.FluxMouseoverKeybind
    local cell = e.CreateFrame("Button", "HoverRouteCell")
    cell.attrs.unit, cell.attrs["*type1"], cell.attrs.type2 = "raid1", "target", "togglemenu"
    module:RegisterFrame(cell)
    local function fire(event)
        cell.hovered = event == "OnEnter"
        local wrap = cell.wraps[event]; if wrap then execute(wrap.header, cell, wrap.code) end
        if cell.scripts[event] then cell.scripts[event](cell) end
        for _, hook in ipairs(cell.hooks[event] or {}) do hook(cell) end
    end
    local function routing(keys)
        local names, bodies = {}, {}
        for i, key in ipairs(keys) do
            local name = "HoverBody" .. i; local hc = e[name] or e.CreateFrame("Button", name)
            bodies[i] = "/cast Hover:" .. key
            hc.attrs.type, hc.attrs.macrotext, hc.attrs["flux-macrotext-hovercast"] = "macro", bodies[i], bodies[i]
            names[i] = name
        end
        return module:SetUfHoverRouting(keys, names, nil, bodies)
    end
    local native = read("../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua")
    local sig = "function SecureButton_GetModifiedAttribute(frame, name, button, prefix, suffix)"
    local a = assert(native:find(sig, 1, true)); local b = assert(native:find("\nend", a, true)) + 3
    e.LOCAL_CHECK_Frame = { GetAttribute = methods.GetAttribute, GetParent = methods.GetParent }
    e.ATTRIBUTE_NOOP = {}; e.SecureButton_GetButtonSuffix = function(button) return button == "LeftButton" and "1" or button end
    e.SecureButton_GetModifierPrefix = function() return e.prefix or "" end
    e.SecureButton_GetModifiedAttribute = assert(load("return function(frame,name,button,prefix,suffix)" .. native:sub(a + #sig, b), "native attribute lookup", "t", e))()
    local function dispatch(key, prefix)
        -- Model native modified-key fallback; source and actual selected target
        -- are exercised, while hardware override arbitration remains native.
        local bind = cell.binds[key] or cell.binds.R
        if not bind then return nil end
        if bind.command then return nil, nil, "command", bind.command end
        local f = assert(e[bind[1]], bind[1]); e.prefix = prefix or ""
        local typ = e.SecureButton_GetModifiedAttribute(f, "type", bind[2])
        local value = typ == "action" and e.SecureButton_GetModifiedAttribute(f, "action", bind[2])
            or e.SecureButton_GetModifiedAttribute(f, "macrotext", bind[2])
        return bind[1], bind[2], typ, value
    end
    e.setBindingAvailable = function(value) methods.SetBinding = value and e.setBindingMethod or nil end
    e.setBindingMethod = methods.SetBinding
    return e, module, cell, fire, routing, dispatch
end

for _, mode in ipairs({ { false, false }, { true, false }, { false, true }, { true, true } }) do
    local e, module, cell, fire, route, dispatch = fixture(mode[1], mode[2])
    local label = "edit=" .. tostring(mode[1]) .. "/wrap=" .. tostring(mode[2])
    check(route({ "R" }), label .. ": bare hover route installed: " .. tostring(e.lastRestrictedError))
    e.combat = true; fire("OnEnter")
    local name, button, typ, value = dispatch("R")
    check(name == "HoverBody1" and button == "LeftButton" and typ == "macro", label .. ": bare R stays on HC body")
    for _, item in ipairs({ { "SHIFT-R", "shift-", 69 }, { "CTRL-R", "ctrl-", 33 } }) do
        name, button, typ, value = dispatch(item[1], item[2])
        check(name == (mode[2] and "FluxActionStripButton9" or "FluxActionStripKey9"), label .. ": modifier selects real bar route")
        check(button == (mode[2] and "KeyBind" or "LeftButton") and typ == "action" and value == item[3], label .. ": native modifier resolves correct mini action")
    end
    for _, chord in ipairs({ "ALT-R", "CTRL-SHIFT-R", "ALT-SHIFT-R", "ALT-CTRL-R", "ALT-CTRL-SHIFT-R" }) do
        check(cell.binds[chord] and cell.binds[chord][1] ~= "HoverBody1", label .. ": combined modifier cannot fall back to bare HC")
    end
    fire("OnLeave"); check(next(cell.binds) == nil, label .. ": leaving releases every temporary override")
    e.units = { raid1 = false }; fire("OnEnter")
    check(next(cell.binds) == nil, label .. ": absent owner cannot arm modifier overrides")
    fire("OnLeave"); e.units = nil
    e.combat = false; check(route({ "R", "SHIFT-R" }), label .. ": explicit mini hover route installed")
    e.combat = true; fire("OnEnter")
    name, button, typ = dispatch("SHIFT-R", "shift-")
    check(name == "HoverBody2" and button == "LeftButton" and typ == "macro", label .. ": explicit Shift hover keeps ownership")
    check(route({}) == false, label .. ": combat route updates defer")
    fire("OnLeave"); e.combat = false
    check(module:FlushPendingHoverRouting(), label .. ": deferred route update flushes")
    fire("OnEnter"); check(next(cell.binds) == nil, label .. ": removed hover routes leave no modifier overrides")
    fire("OnLeave"); check(route({ "R", "BUTTON4" }), label .. ": mouse and keyboard hover can coexist")
    fire("OnEnter")
    if not mode[1] then
        check(cell.binds.BUTTON4 == nil and cell.binds["SHIFT-BUTTON4"] == nil,
            label .. ": legacy real mouse buttons retain frame attributes")
    end
    fire("OnLeave"); check(next(cell.binds) == nil, label .. ": mixed routing cleanup releases overrides")

    e.nativeCommands["SHIFT-R"] = "TOGGLECHARACTER0"
    e.nativeCommands["CTRL-R"] = "ACTIONBUTTON9"
    for _, chord in ipairs({ "ALT-R", "CTRL-SHIFT-R" }) do
        local name = "World_" .. chord
        local world = e.CreateFrame("Button", name)
        world.attrs.type, world.attrs.macrotext = "macro", "/cast World:" .. chord
        e.worldTargets[chord] = name
    end
    check(route({ "R" }), label .. ": distinct native/free modified owners prepared")
    fire("OnEnter")
    name, button, typ, value = dispatch("SHIFT-R", "shift-")
    check(typ == "command" and value == "TOGGLECHARACTER0", label .. ": foreign native command retains exact chord")
    name, button, typ, value = dispatch("CTRL-R", "ctrl-")
    check(typ == "action" and value == 33, label .. ": same-column native binding keeps mini routing")
    for _, chord in ipairs({ "ALT-R", "CTRL-SHIFT-R" }) do
        name, button, typ, value = dispatch(chord)
        check(name == e.worldTargets[chord] and button == "LeftButton" and typ == "macro"
            and value == "/cast World:" .. chord, label .. ": regular-only free owner wins over bare hover")
    end
    check(route({}) and next(cell.binds) == nil, label .. ": hovered reconfigure clears OLD native/free/HC vectors before replacement")
    check(route({ "R" }) and cell.binds["SHIFT-R"] and cell.binds["SHIFT-R"].command,
        label .. ": hovered reconfigure rearms valid current owner without a mouse leave")
    e.setBindingAvailable(false)
    check(route({ "R" }) == false and module:HasPendingHoverRouting(),
        label .. ": unavailable native command capability remains pending")
    check(next(cell.binds) == nil and e.FluxClickCastHeader.attrs["flux-native-binding-gap"] == true,
        label .. ": capability gap releases routing instead of substituting foreign action")
    e.setBindingAvailable(true)
    check(module:FlushPendingHoverRouting(), label .. ": native command capability can retry")
    name, button, typ = dispatch("R")
    check(name == "HoverBody1" and button == "LeftButton" and typ == "macro",
        label .. ": capability retry rearms HC under stationary valid cursor")
    name, button, typ, value = dispatch("SHIFT-R", "shift-")
    check(typ == "command" and value == "TOGGLECHARACTER0",
        label .. ": capability retry rearms exact native command without leave")
    for _, chord in ipairs({ "ALT-R", "CTRL-SHIFT-R" }) do
        name, button, typ, value = dispatch(chord)
        check(name == e.worldTargets[chord] and button == "LeftButton" and typ == "macro"
            and value == "/cast World:" .. chord, label .. ": capability retry rearms free owner without leave")
    end
    fire("OnLeave"); check(next(cell.binds) == nil, label .. ": native/free routes release after retry")
end
print("PASS binding hover modifier routes: " .. checks .. " checks (native dispatch/taint unverified)")
