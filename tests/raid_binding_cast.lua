-- Executes Flux's production registration, secure snippets and native click
-- handlers. Hardware dispatch, protected execution and taint remain native checks.
local function read(path)
    local file = assert(io.open(path, "rb")); local value = file:read("*a"):gsub("\r\n", "\n"); file:close(); return value
end
local source = read(arg[1] or "Binding/Input/FluxMouseoverKeybind.lua")
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function fixture(client, body)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local ns = { Flux = {} }
    e.ns = ns
    e.FLUX_API = { hasEditMode = client ~= "classic_era", hasSecretValueAPI = client == "live" or client == "forever" }
    e.combat, e.secureDepth, e.writes, e.driver = false, 0, 0, false
    e.InCombatLockdown = function() return e.combat end
    e.FluxEditModeBusy = function() return e.editing end
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
    function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function methods:IsUnderMouse() return self.hovered end
    function methods:IsMouseEnabled() return self.mouse ~= false end
    function methods:IsObjectType(kind) return self.kind == kind end
    function methods:GetChildren() return table.unpack(self.children) end
    function methods:GetParent() return self.parent end
    function methods:GetAttribute(key) return self.attrs[key] end
    function methods:SetFrameRef(key, frame) legal(); self.refs = self.refs or {}; self.refs[key] = frame end
    function methods:GetFrameRef(key) return self.refs and self.refs[key] end
    function methods:SetAttribute(key, value) legal(); self.attrs[key] = value end
    function methods:RegisterForClicks(...) legal(); self.edges = {}; for _, edge in ipairs({ ... }) do self.edges[edge] = true end end
    function methods:EnableMouseWheel(value) legal(); self.wheel = value end
    function methods:SetPassThroughButtons(...) legal(); self.passthrough = { ... } end
    function methods:HookScript(event, fn) legal(); self.hooks[event] = self.hooks[event] or {}; table.insert(self.hooks[event], fn) end
    function methods:SetScript(event, fn) self.scripts[event] = fn end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:SetBindingClick(_, key, name, button) assert(e.secureDepth > 0); self.binds[key] = { name, button } end
    function methods:ClearBinding(key) assert(e.secureDepth > 0); self.binds[key] = nil end
    local function execute(header, frame, code, name, value)
        local secure = header.secure
        local previousSelf, previousControl = secure.self, secure.control
        local previousName, previousValue = secure.name, secure.value
        secure.self, secure.control = frame, header
        secure.name, secure.value = name, value
        e.secureDepth = e.secureDepth + 1
        local result = table.pack(assert(load(code, "@secure-cast-fixture", "t", secure))())
        e.secureDepth = e.secureDepth - 1
        secure.self, secure.control = previousSelf, previousControl
        secure.name, secure.value = previousName, previousValue
        return table.unpack(result, 1, result.n)
    end
    function methods:Execute(code) return execute(self, self, code) end
    function methods:RunFor(frame, code) return execute(self, frame, code) end
    function methods:WrapScript(frame, event, code) legal(); frame.wraps[event] = { header = self, code = code } end
    function methods:UnwrapScript(frame, event) legal(); frame.wraps[event] = nil end
    e.CreateFrame = function(kind, name, parent)
        local frame = setmetatable({ kind = kind, name = name, parent = parent, attrs = {}, scripts = {}, hooks = {},
            events = {}, children = {}, wraps = {}, binds = {}, shown = true }, { __index = methods })
        frame.secure = { newtable = function(...) return { ... } end, type = type,
            UnitExists = function(unit) return not e.units or e.units[unit] ~= false end,
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
    function e.NativeAttribute(frame, name, value)
        frame.attrs[name] = value
        local wrap = frame.wraps.OnAttributeChanged
        if wrap then execute(wrap.header, frame, wrap.code, name, value)
        elseif frame.attrs._onattributechanged then execute(frame, frame, frame.attrs._onattributechanged, name, value) end
    end
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
        check(e.writes == nativeWrites + 4, client .. ": native registration installs only secure enter/leave/hide/unit-change wrappers")
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

local function ghostPlayer(client, body)
    local e, module, cell, fire, route, event = fixture(client, body)
    local player = cell("PlayerFrame", false)
    local nativeChild = cell("NativePlayerChild", false, player)
    local fluxPlayer = cell("FluxUnitFrameOuter_player", false)
    local peekWakes, peekParks = 0, 0
    e.FluxBindingPushPress = {
        WakeUfHoverFromUnitFrame = function() peekWakes = peekWakes + 1 end,
        ParkUfHoverFromUnitFrame = function() peekParks = peekParks + 1 end,
    }
    local suppressed = false
    e.ns.Flux.Blizz = { IsMouseSuppressed = function(frame) return frame == player and suppressed end }
    module:RegisterFrame(player); module:RegisterFrame(fluxPlayer)
    route({ "Q" }, { "/cast Heal" })
    fire(player, "OnEnter")
    check(player.binds.Q, client .. ": native player control arms before replacement")
    local castingSurface = player
    if nativeChild.wraps.OnEnter then
        fire(nativeChild, "OnEnter")
        castingSurface = nativeChild
        check(nativeChild.binds.Q, client .. ": legacy player child can own the active override")
    end
    suppressed = true
    e.combat = true
    local writes = e.writes
    if module.SyncNativePlayerSuppression then module:SyncNativePlayerSuppression() end
    check(castingSurface.binds.Q and e.writes == writes, client .. ": an active native override is left to secure cleanup until combat ends")
    e.combat = false
    if module.SyncNativePlayerSuppression then module:SyncNativePlayerSuppression() end
    check(not next(player.binds), client .. ": replacing a hovered native player clears already armed secure overrides")
    check(not next(nativeChild.binds) and not nativeChild.wraps.OnEnter, client .. ": legacy native child overrides and wrappers are also removed")
    check(not player.wraps.OnEnter and not player.wraps.OnHide, client .. ": suppressed native player loses Flux secure hover registration")
    check(not e.driver and peekWakes == peekParks, client .. ": native removal balances legacy hover bookkeeping")
    e.combat = true
    writes = e.writes
    local wakes = peekWakes
    fire(player, "OnEnter")
    module:RegisterFrame(player)
    if module.SyncNativePlayerSuppression then module:SyncNativePlayerSuppression() end
    check(not next(player.binds) and e.writes == writes, client .. ": native ghost cannot rearm or mutate protected state in combat")
    check(peekWakes == wakes, client .. ": retained legacy hooks cannot wake an unregistered native frame")
    fire(fluxPlayer, "OnEnter")
    check(fluxPlayer.binds.Q, client .. ": real Flux player still casts in combat")
    fire(fluxPlayer, "OnLeave")
    e.combat = false; event("PLAYER_REGEN_ENABLED")
    module:RefreshKeybinds(); module:RegisterFrame(player)
    check(not player.wraps.OnEnter, client .. ": discovery and binding refresh cannot reregister the suppressed native player")
    suppressed = false
    if module.SyncNativePlayerSuppression then module:SyncNativePlayerSuppression() end
    fire(player, "OnEnter")
    check(player.binds.Q and player.wraps.OnHide, client .. ": native selection restores hover registration")
    fire(player, "OnLeave")
    fire(fluxPlayer, "OnEnter")
    suppressed = true
    module:SyncNativePlayerSuppression()
    check(fluxPlayer.binds.Q, client .. ": removing native player registration preserves a peer's active override")
    fire(fluxPlayer, "OnLeave")
    suppressed = false; module:SyncNativePlayerSuppression()
    fire(player, "OnEnter")
    suppressed = true; e.editing = true
    writes = e.writes
    module:SyncNativePlayerSuppression()
    check(player.binds.Q and e.writes == writes, client .. ": native Edit Mode reset stack defers secure registration changes")
    e.editing = false; module:SyncNativePlayerSuppression()
    check(not next(player.binds) and not player.wraps.OnEnter, client .. ": post-Edit Mode reconciliation removes the ghost override")
    suppressed = false; e.combat = true
    writes = e.writes
    module:SyncNativePlayerSuppression()
    check(not player.wraps.OnEnter and e.writes == writes, client .. ": native registration restoration waits through combat")
    e.combat = false; module:SyncNativePlayerSuppression()
    e.ClickCastFrames[player] = false
    suppressed = true
    module:RegisterFrame(player)
    check(not player.wraps.OnEnter, client .. ": late initial registration also respects native player suppression")
end

local function rosterDiscovery(client, body, passes, newCells)
    local e, module, cell, fire, route, event = fixture(client, body)
    local timer, reads = {}, 0
    e.C_Timer.After = function(_, callback) timer[#timer + 1] = callback end
    e.FluxActionStripButton2, e.FluxActionStripButton3 = {}, {}
    e.GetBindingKey = function(binding)
        reads = reads + 1
        if binding == "ACTIONBUTTON1" then return "BUTTON4", nil, "SHIFT-BUTTON5", "ALT-MOUSEWHEELUP" end
        if binding == "ACTIONBUTTON2" then return "", "MOUSEWHEELDOWN" end
        if binding == "ACTIONBUTTON3" then return "Q" end
    end
    check(route({}, {}), "mouse and wheel routes are prepared")
    local frames, discoveries = {}, 0
    for i = 1, (newCells or 5) do
        frames[i] = cell("FluxRosterMember" .. i, true)
        if not newCells then module:RegisterFrame(frames[i]) end
    end
    e.ns.FluxRaidRegisterAllMouseoverKeybindFrames = function()
        discoveries = discoveries + 1
        for _, frame in ipairs(frames) do
            if not module:IsFrameRegistered(frame) then module:RegisterFrame(frame) end
        end
    end
    reads = 0
    local writes = e.writes
    local elapsed = os.clock()
    for _ = 1, passes do
        for _ = 1, 20 do event("GROUP_ROSTER_UPDATE") end
        check(#timer == 1, "a roster burst queues one discovery")
        local callback = timer[1]; timer[1] = nil; callback()
    end
    elapsed = (os.clock() - elapsed) * 1000
    local samples = { reads = reads, discoveries = discoveries, writes = e.writes - writes, elapsed = elapsed }
    check(discoveries == passes, "each roster burst discovers its settled frames")
    check(not e.driver, "mouse-only routing never arms the spell-hover driver")
    local fingerprint = {}
    local function record(tab)
        for key, value in pairs(tab or {}) do
            if type(value) ~= "table" then fingerprint[#fingerprint+1] = key .. "=" .. tostring(value) end
        end
    end
    for _, frame in ipairs(frames) do
        check(module:IsFrameRegistered(frame), "settled roster admits all current members")
        record(frame.attrs)
        record(frame.edges)
        record(frame.passthrough)
    end
    fire(frames[1], "OnEnter")
    for key, binding in pairs(frames[1].binds) do
        fingerprint[#fingerprint+1] = key .. "=" .. binding[1] .. ":" .. binding[2]
    end
    if e.FLUX_API.hasEditMode then
        check(frames[1].binds["ALT-MOUSEWHEELUP"] and frames[1].binds["MOUSEWHEELDOWN"],
            "both wheel chords, including a chord after a nil binding result, are retained")
    end
    fire(frames[1], "OnLeave")
    table.sort(fingerprint)
    samples.signature = table.concat(fingerprint, ";")
    return samples
end

local rosterBefore = os.getenv("FLUX_HOVER_ROSTER_CHECKPOINT")
local archived = rosterBefore and read(rosterBefore .. "/Binding-Input-FluxMouseoverKeybind.lua")
local bench = os.getenv("FLUX_HOVER_ROSTER_TIMING") == "1"
for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    exercise(client)
    ghostPlayer(client)
    local e, _, cell, fire, route = fixture(client)
    local frame = cell("FluxUnitFrameOuter_player")
    check(route({"Q"},{"/cast [@mouseover] Heal"}), "spell hover route is available")
    fire(frame, "OnEnter")
    if client ~= "forever" then check(e.driver, "spell hover arms the exists driver") end
    check(route({},{}), "clearing spell routes retains ordinary mouse bindings")
    check(not e.driver, "mouse-only routes release the spell-hover driver even while hovered")
    fire(frame, "OnLeave")
    for _, case in ipairs({{"settled",bench and 180 or 30},{"party",1,5},{"raid",1,40}}) do
        for trial=1,bench and 5 or 1 do
            local old, current
            if archived and trial%2==1 then old = rosterDiscovery(client, archived, case[2], case[3]) end
            current = rosterDiscovery(client, source, case[2], case[3])
            if archived and trial%2==0 then old = rosterDiscovery(client, archived, case[2], case[3]) end
            if old then
                check(old.signature == current.signature and old.writes == current.writes,
                    "matched roster keeps click and wheel routes, admission and protected writes")
                check(old.reads > current.reads, "matched roster reads fewer native binding keys")
                print(("HOVER_ROSTER client=%s case=%s trial=%d bursts=%d keyReads=%d/%d writes=%d/%d ms=%.3f/%.3f"):
                    format(client,case[1],trial,case[2],old.reads,current.reads,old.writes,current.writes,old.elapsed,current.elapsed))
            end
            if case[1]=="settled" then check(current.reads==0 and current.writes==0,"settled roster avoids key reads and protected writes") end
        end
    end
end
local noHide = source:gsub('local hideOk = R.WrapScript%(header, frame, "OnHide", LEAVE_SNIPPET%)', 'local hideOk = true')
check(not pcall(exercise, "live", noHide), "negative control rejects missing secure hide cleanup")
local noPrimary = source:gsub('if not frame%._fluxRaidUnit then return end', 'if true then return end')
check(not pcall(exercise, "live", noPrimary), "negative control rejects missing owned healer click integration")
local opaqueWrap = source:gsub('if OpaqueMouseValue%(enabled%) then return false, false end', 'if false then return false, false end')
check(not pcall(exercise, "live", opaqueWrap), "negative control rejects the reported native secret-mouse path")
local nativeWalk = source:gsub('or NativeAuraChild%(child, owner%)', '')
check(not pcall(exercise, "live", nativeWalk), "negative control rejects inspecting native aura objects")
local ghostControls = {
    source:gsub('if NativePlayerHoverSuppressed%(frame%) then return end', 'if false then return end', 1),
    source:gsub('if currentButton == frame then', 'if false then', 1),
    source:gsub('            UnregisterFrame%(frame%)', '', 1),
    source:gsub('or %(FluxEditModeBusy and FluxEditModeBusy%(%)%)', '', 1),
    (source:gsub('if not header or InCombatLockdown%(%) or', 'if not header or false or', 1)),
}
for i, mutant in ipairs(ghostControls) do
    assert(load(mutant, "@ghost-player-control-" .. i))
    check(not pcall(ghostPlayer, "forever", mutant), "native ghost control " .. i .. " rejected")
end
print("Raid binding casting: " .. checks .. " checks; five native source handlers; nine rejected negative controls")
