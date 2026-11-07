-- Executes Flux's production registration, secure snippets and native click
-- handlers. Hardware dispatch, protected execution and taint remain native checks.
local function read(path)
    local file = assert(io.open(path, "rb")); local value = file:read("*a"):gsub("\r\n", "\n"); file:close(); return value
end
local source = read("Binding/Input/FluxMouseoverKeybind.lua")
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function fixture(client, body)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local ns = { Flux = {} }
    e.FLUX_API = { hasEditMode = client ~= "classic_era", hasSecretValueAPI = client == "live" or client == "forever" }
    e.combat, e.secureDepth, e.writes, e.driver = false, 0, 0, false
    e.InCombatLockdown = function() return e.combat end
    e.secret = {}
    e.issecretvalue = function(value) return value == e.secret end
    e.wipe = function(t) for key in pairs(t) do t[key] = nil end end
    e.unpack = table.unpack or unpack
    e.GetBindingKey = function(binding) if binding == "ACTIONBUTTON1" then return "BUTTON4" end end
    e.GetTime = function() return 1 end
    e.RegisterAttributeDriver = function() assert(not e.combat); e.driver = true end
    e.UnregisterAttributeDriver = function() assert(not e.combat); e.driver = false end
    e.C_AddOns = { IsAddOnLoaded = function() return false end }
    e.C_Timer = { After = function() end }
    local methods, frames = {}, {}
    local function legal() assert(not e.combat, client .. ": insecure protected mutation in combat"); e.writes = e.writes + 1 end
    function methods:GetName() return self.name end
    function methods:IsForbidden() return false end
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown end
    function methods:IsUnderMouse() return self.hovered end
    function methods:IsMouseEnabled() return self.mouse ~= false end
    function methods:IsObjectType(kind) return self.kind == kind end
    function methods:GetChildren() return table.unpack(self.children) end
    function methods:GetParent() return self.parent end
    function methods:GetAttribute(key) return self.attrs[key] end
    function methods:SetAttribute(key, value) legal(); self.attrs[key] = value end
    function methods:RegisterForClicks(...) legal(); self.edges = {}; for _, edge in ipairs({ ... }) do self.edges[edge] = true end end
    function methods:EnableMouseWheel(value) legal(); self.wheel = value end
    function methods:SetPassThroughButtons(...) legal(); self.passthrough = { ... } end
    function methods:HookScript(event, fn) legal(); self.hooks[event] = self.hooks[event] or {}; table.insert(self.hooks[event], fn) end
    function methods:SetScript(event, fn) self.scripts[event] = fn end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:SetBindingClick(_, key, name, button) assert(e.secureDepth > 0); self.binds[key] = { name, button } end
    function methods:ClearBinding(key) assert(e.secureDepth > 0); self.binds[key] = nil end
    local function execute(header, frame, code)
        local secure = header.secure
        local previousSelf, previousControl = secure.self, secure.control
        secure.self, secure.control = frame, header
        e.secureDepth = e.secureDepth + 1
        assert(load(code, "@secure-cast-fixture", "t", secure))()
        e.secureDepth = e.secureDepth - 1
        secure.self, secure.control = previousSelf, previousControl
    end
    function methods:Execute(code) execute(self, self, code) end
    function methods:RunFor(frame, code) execute(self, frame, code) end
    function methods:WrapScript(frame, event, code) legal(); frame.wraps[event] = { header = self, code = code } end
    function methods:UnwrapScript(frame, event) legal(); frame.wraps[event] = nil end
    e.CreateFrame = function(kind, name, parent)
        local frame = setmetatable({ kind = kind, name = name, parent = parent, attrs = {}, scripts = {}, hooks = {},
            events = {}, children = {}, wraps = {}, binds = {}, shown = true }, { __index = methods })
        frame.secure = { newtable = function(...) return { ... } end,
            table = setmetatable({ maxn = function(t) return #t end }, { __index = table }) }
        table.insert(frames, frame)
        if name then e[name] = frame end
        if parent then table.insert(parent.children, frame) end
        return frame
    end
    e.FluxActionStripButton1 = {}
    ns.Flux.Restricted = {
        Works = function() return client ~= "forever" end,
        Execute = function(h, code) h:Execute(code); return true end,
        SetSnippet = function(h, key, value) h:SetAttribute(key, value); return true end,
        WrapScript = function(h, f, event, code) h:WrapScript(f, event, code); return true end,
        UnwrapScript = function(h, f, event) h:UnwrapScript(f, event) end,
    }
    assert(load(body or source, "@FluxMouseoverKeybind", "t", e))("_FluxUI", ns)
    local eventFrame = frames[1]
    local function event(name) eventFrame.scripts.OnEvent(eventFrame, name) end
    event("PLAYER_LOGIN")
    local module = ns.FluxMouseoverKeybind
    local function cell(name, raid, parent)
        local f = e.CreateFrame("Button", name, parent)
        f._fluxRaidUnit = raid
        f.attrs["*type1"], f.attrs.type2, f.attrs.unit = "target", "togglemenu", "raid1"
        return f
    end
    local function fire(f, name)
        if name == "OnEnter" then f.hovered = true elseif name == "OnLeave" or name == "OnHide" then f.hovered = false end
        if name == "OnHide" then f.shown = false end
        local wrap = f.wraps[name]
        if wrap then execute(wrap.header, f, wrap.code) end
        if f.scripts[name] then f.scripts[name](f) end
        for _, hook in ipairs(f.hooks[name] or {}) do hook(f) end
    end
    local function route(keys, bodies)
        local buttons = {}
        for i, key in ipairs(keys) do
            local name = "Cast_" .. key:gsub("[^%w]", "_")
            local f = e[name] or cell(name)
            f.attrs["flux-macrotext-hovercast"] = bodies[i]
            buttons[i] = name
        end
        return module:SetUfHoverRouting(keys, buttons, nil, bodies)
    end
    return e, module, cell, fire, route, event
end

local function exercise(client, body)
    local e, module, cell, fire, route, event = fixture(client, body)
    local raid = cell("FluxRaidGrp1Unit1", true)
    local peer = cell("FluxRaidGrp1Unit2", true)
    local ordinary = cell("FluxUnitFrameOuter_player", false)
    local native = cell("CompactRaidFrame1", false)
    local aura = cell("FluxRaidAura", false, raid)
    local inspected = { native=0, forbidden=0, status=0, opaque=0 }
    local function denied(kind)
        return function() inspected[kind] = inspected[kind]+1; error("restricted "..kind.." subtree inspected") end
    end
    local nativeBox = cell("NativePrivateContainer", false, raid)
    nativeBox.IsForbidden, nativeBox.IsMouseEnabled, nativeBox.GetChildren = denied("native"), denied("native"), denied("native")
    raid._fluxAuraContainers = { buffs=nativeBox }
    local nativeButton = cell("NativePrivateButton", false, raid)
    nativeButton.IsForbidden, nativeButton.IsMouseEnabled, nativeButton.GetChildren = denied("native"), denied("native"), denied("native")
    raid._fluxNativeAuraButtons = { nativeButton }
    local privateHost = cell("LegacyPrivateHost", false, raid)
    privateHost.IsForbidden, privateHost.IsMouseEnabled, privateHost.GetChildren = denied("native"), denied("native"), denied("native")
    raid._fluxPrivateAuraHost = privateHost
    local forbidden = cell("ForbiddenChild", false, raid)
    forbidden.IsForbidden = function() return true end
    forbidden.IsMouseEnabled, forbidden.GetChildren = denied("forbidden"), denied("forbidden")
    local statusBar = e.CreateFrame("StatusBar", "SecretMouseStatusBar", raid)
    statusBar.IsMouseEnabled, statusBar.GetChildren = denied("status"), denied("status")
    local opaque = cell("OpaqueMouseChild", false, raid)
    opaque.IsMouseEnabled = function() return e.secret end
    opaque.GetChildren = denied("opaque")
    local typedNative = cell("UnknownNativeContainer", false, raid)
    typedNative.GetObjectType = function() return "AuraContainer" end
    typedNative.IsMouseEnabled, typedNative.GetChildren = denied("native"), denied("native")
    local disabledParent = cell("FluxMouseDisabledParent", false, raid)
    disabledParent.mouse = false
    local descendantAura = cell("FluxNestedAura", false, disabledParent)
    peer.attrs.type1, peer.attrs.macro1, peer.attrs.macrotext1 = "spell", "PreviousMacro", "PreviousText"
    module:RegisterFrame(raid); module:RegisterFrame(peer); module:RegisterFrame(ordinary)
    check(inspected.native==0 and inspected.forbidden==0 and inspected.status==0 and inspected.opaque==0,
        client..": native, forbidden, status and opaque subtrees are not queried or descended")
    check(not opaque.wraps.OnEnter and not opaque.wraps.OnHide, client..": secret mouse boolean does not acquire hover wrappers")
    check(aura.wraps.OnEnter and descendantAura.wraps.OnEnter, client..": owned aura routing survives mouse-disabled ancestor traversal")
    local nativeWrites = e.writes
    module:RegisterFrame(native)
    if client ~= "classic_era" then
        check(not native.edges and not native.passthrough and not next(native.hooks), client .. ": native frames remain wrap-only")
        check(e.writes == nativeWrites + 3, client .. ": native registration installs only secure enter/leave/hide wrappers")
    end
    local heal, cleanse = "/cast [@mouseover,help,nodead] Heal", "/cast [@mouseover,help,nodead] Cleanse"
    check(route({ "BUTTON1", "SHIFT-CTRL-BUTTON2", "Q", "BUTTON3", "MOUSEWHEELUP" }, { heal, cleanse, heal, heal, heal }), client .. ": routing pushes OOC")
    check(raid.attrs.type1 == "macro" and raid.attrs.macrotext1 == heal, client .. ": configured left click uses existing Flux program")
    check(raid.attrs["ctrl-shift-type2"] == "macro" and raid.attrs["ctrl-shift-macrotext2"] == cleanse,
        client .. ": right-click modifiers follow native prefix order")
    check(raid.attrs.type2 == "togglemenu" and raid.attrs["*type1"] == "target", client .. ": ordinary interactions remain available")
    check(not ordinary.attrs.type1 and not ordinary.attrs["ctrl-shift-type2"], client .. ": healer clicks are scoped to raid cells")
    check(not native.attrs.type1 and not native.attrs["ctrl-shift-type2"], client .. ": native attributes are preserved")
    for _, name in ipairs(raid.passthrough or {}) do check(name ~= "LeftButton" and name ~= "RightButton", "primary clicks never pass through the cell") end

    -- Execute the supplied native handler to establish cast/interaction precedence.
    local nativeText = read("../__AddonsForRef/wow-ui-source-" .. client .. "/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua")
    local nativeStart = assert(nativeText:find("function SecureUnitButton_OnClick", 1, true))
    nativeText = nativeText:sub(nativeStart)
    local actions, casts, prefix = {}, 0, ""
    e.SecureButton_GetModifiedAttribute = function(f, name, button)
        local suffix = button == "LeftButton" and "1" or "2"
        return f.attrs[prefix .. name .. suffix] or f.attrs["*" .. name .. suffix]
    end
    e.SecureButton_GetModifiedUnit = function(f) return f.attrs.unit end
    e.SpellIsTargeting = function() return false end
    e.OnActionButtonClick = function(f, button, down)
        actions[#actions + 1] = { kind = e.SecureButton_GetModifiedAttribute(f, "type", button), down = down }
    end
    e.Enum = { ClickBindingType = { None = 0, Spell = 1, Macro = 2, Interaction = 3, PetAction = 4 } }
    local bindingType = 3
    e.MakeModifiers = function() return 0 end
    e.C_ClickBindings = { GetBindingType = function() return bindingType end,
        GetEffectiveInteractionButton = function(button) return button end,
        ExecuteBinding = function() casts = casts + 1 end }
    assert(load(nativeText, "@native-unit-handler-" .. client, "t", e))()
    local function click(button)
        for _, edge in ipairs({ { "Down", true }, { "Up", false } }) do
            if raid.edges[button .. edge[1]] then e.SecureUnitButton_OnClick(raid, button, edge[2]) end
        end
    end
    e.combat = true
    click("LeftButton")
    check(#actions == 1 and actions[1].kind == "macro" and not actions[1].down, client .. ": healer left click reaches native action once on release in combat")
    prefix = "ctrl-shift-"; click("RightButton")
    check(#actions == 2 and actions[2].kind == "macro" and not actions[2].down, client .. ": configured modifier right click reaches native action once")
    prefix = ""; bindingType = 1; click("LeftButton")
    check(casts == 1 and #actions == 2, client .. ": native click-cast assignment remains authoritative")
    bindingType = 3

    fire(raid, "OnEnter")
    check(raid.binds.Q and raid.binds.MOUSEWHEELUP, client .. ": keyboard and wheel hover routes arm during combat")
    check(not raid.binds.BUTTON1 and not raid.binds["SHIFT-CTRL-BUTTON2"], client .. ": primary clicks never install global overrides")
    fire(raid, "OnHide")
    check(not next(raid.binds), client .. ": hiding hovered cell clears secure overrides without OnLeave")
    raid.shown = true; fire(raid, "OnEnter"); fire(peer, "OnEnter"); fire(raid, "OnHide")
    check(peer.binds.Q and not next(raid.binds), client .. ": late hide preserves the sibling's current bindings")
    fire(peer, "OnLeave")
    fire(aura, "OnEnter"); fire(aura, "OnHide")
    check(not next(aura.binds), client .. ": aura-child hide also clears secure routes")

    local late = cell("FluxRaidMTMATarget42", true)
    local before = e.writes
    module:RegisterFrame(late)
    check(not late.edges and e.writes == before, client .. ": registration defers all protected writes in combat")
    check(route({}, {}) == false and raid.attrs.type1 == "macro", client .. ": binding removal waits for combat end")
    check(e.writes == before, client .. ": combat edit makes no protected writes")
    e.combat = false; event("PLAYER_REGEN_ENABLED")
    check(late.edges and late.wraps.OnHide, client .. ": late target mini registers after combat")
    check(not raid.attrs.type1 and not raid.attrs.macrotext1 and not raid.attrs["ctrl-shift-type2"], client .. ": removing binds restores exact prior attributes")
    check(raid.attrs["*type1"] == "target" and raid.attrs.type2 == "togglemenu", client .. ": target/menu survive binding removal")
    check(peer.attrs.type1 == "spell" and peer.attrs.macro1 == "PreviousMacro" and peer.attrs.macrotext1 == "PreviousText",
        client .. ": removing healer binding restores existing integration attributes")
    click("LeftButton"); click("RightButton")
    check(actions[3].kind == "target" and actions[4].kind == "togglemenu", client .. ": removed healer binds return to native interactions")

    route({ "Q" }, { heal })
    fire(peer, "OnEnter"); fire(peer, "OnEnter")
    if client ~= "forever" then check(e.driver, client .. ": actual hover arms unit-exists driver") end
    fire(peer, "OnHide"); fire(peer, "OnLeave")
    check(not e.driver, client .. ": hide plus leave balances hover bookkeeping despite duplicate enter")
    route({ "META-BUTTON1" }, { heal })
    check(peer.attrs.type1 == "spell", client .. ": unsupported Meta primary chord never aliases an unmodified heal")
    route({ "BUTTON1" }, { heal })
    peer.attrs.type1, peer.attrs.macrotext1 = "external", "ExternalText"
    route({}, {})
    check(peer.attrs.type1 == "external" and peer.attrs.macrotext1 == "ExternalText", client .. ": cleanup preserves a subsequent integration's writes")
    route({ "BUTTON1" }, { heal })
    e.ClickCastFrames[peer] = false
    check(peer.attrs.type1 == "external" and not peer.wraps.OnHide, client .. ": unregister restores primary clicks and removes secure cleanup wrapper")
end

for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do exercise(client) end
local noHide = source:gsub('local hideOk = R.WrapScript%(header, frame, "OnHide", LEAVE_SNIPPET%)', 'local hideOk = true')
check(not pcall(exercise, "live", noHide), "negative control rejects missing secure hide cleanup")
local noPrimary = source:gsub('if not frame%._fluxRaidUnit then return end', 'if true then return end')
check(not pcall(exercise, "live", noPrimary), "negative control rejects missing owned healer click integration")
local opaqueWrap = source:gsub('if OpaqueMouseValue%(enabled%) then return false, false end', 'if false then return false, false end')
check(not pcall(exercise, "live", opaqueWrap), "negative control rejects the reported native secret-mouse path")
local nativeWalk = source:gsub('or NativeAuraChild%(child, owner%)', '')
check(not pcall(exercise, "live", nativeWalk), "negative control rejects inspecting native aura objects")
print("Raid binding casting: " .. checks .. " checks; five native source handlers; four rejected negative controls")
