-- Current production binding owners. No native VM, true secrets or FPS claims.
local root = arg[1] or "."
root = root:gsub("\\", "/"):gsub("/$", "") .. "/"
local selected, checks = arg[2], 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function near(a, b, why) check(type(a) == "number" and math.abs(a - b) < 1e-9, why) end
local function read(path)
    local f = assert(io.open(root .. path, "rb")); local s = f:read("*a"); f:close(); return s:gsub("\r\n", "\n")
end
local function loadModule(path, e, ns) return assert(load(read(path), "@" .. path, "t", e))("_FluxUI", ns) end
local function fixture(client, colorMode)
    local s = { frames = {}, timers = {}, down = {}, mask = 0, combat = false, pending = {}, colors = {} }
    local e = setmetatable({ UIParent = {}, FluxButton = {} }, { __index = _G }); e._G = e
    e.wipe = function(t) for k in pairs(t) do t[k] = nil end; return t end
    e.InCombatLockdown = function() return s.combat end
    e.GetTime = function() return s.now or 10 end
    e.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    e.IsKeyDown = function(key) return s.down[key] or false end
    e.IsShiftKeyDown = function() return s.mask % 2 == 1 end
    e.IsControlKeyDown = function() return math.floor(s.mask / 2) % 2 == 1 end
    e.IsAltKeyDown = function() return s.mask >= 4 end
    e.GetBindingKey = function(cmd)
        if cmd == "ACTIONBUTTON1" then return "Q", "Z" end
        if cmd == "ACTIONBUTTON2" then return "E" end
        if cmd == "ACTIONBUTTON3" then return "-" end
    end
    e.issecretvalue = function(value) return type(value) == "table" and rawget(value, "opaque") == true end
    e.CreateFrame = function(_, name, parent)
        local f = { name = name, parent = parent, shown = true, attrs = {}, events = {}, scripts = {}, hooks = {} }
        function f:GetName() return self.name end
        function f:GetParent() return self.parent end
        function f:SetParent(p) check(not s.combat, "no protected parent writes in combat"); self.parent = p end
        function f:SetSize(w, h) self.width, self.height = w, h end
        function f:Hide() self.shown = false end
        function f:Show() self.shown = true end
        function f:IsShown() return self.shown end
        function f:IsForbidden() return false end
        function f:GetAttribute(k) return self.attrs[k] end
        function f:SetAttribute(k, v) check(not s.combat, "no protected attributes in combat"); self.attrs[k] = v end
        function f:RegisterForClicks(...) check(not s.combat, "no protected registration in combat"); self.clicks = { ... } end
        function f:RegisterEvent(k) self.events[k] = true end
        function f:UnregisterEvent(k) self.events[k] = nil end
        function f:SetScript(k, v) self.scripts[k] = v end
        function f:GetScript(k) return self.scripts[k] end
        function f:HookScript(k, v) self.hooks[k] = self.hooks[k] or {}; self.hooks[k][#self.hooks[k] + 1] = v end
        function f:WrapScript() end
        function f:SetButtonState(value) self.state = value end
        s.frames[#s.frames + 1] = f; if name then e[name] = f end; return f
    end
    local hosts = {}
    local flux = { Client = { key = client }, Bars = { GetMain = function(col) return hosts[col] end },
        Combat = { InLockdown = e.InCombatLockdown, Defer = function(k, fn) s.pending[k] = fn end } }
    local ns = { Flux = flux }; e.Flux = flux
    loadModule("Binding/Core/ChordMap.lua", e, ns)
    for i = 1, 3 do
        local f = e.CreateFrame("Button", "FluxActionStripButton" .. i)
        local color = { 1, 1, 1 }; s.colors[i] = color
        f.icon = { SetVertexColor = function(_, r, g, b) color[1], color[2], color[3] = r, g, b end,
            SetDesaturated = function() end,
            GetVertexColor = function()
                if colorMode == "nil" then return end
                if colorMode == "opaque" then
                    local v = setmetatable({ opaque = true }, { __mul = function() error("secret arithmetic") end })
                    return v, v, v, 1
                end
                return color[1], color[2], color[3], 1
            end }
        hosts[i] = { widget = f, WIcon = f.icon, column = i, row = "main", slot = i }
    end
    loadModule("Binding/Core/PushPress.lua", e, ns)
    local pp = ns.FluxBindingPushPress; pp.EnsureBarButtonPushHooks()
    function s.press(col, down)
        for _, fn in ipairs(hosts[col].widget.hooks.PreClick or {}) do fn(hosts[col].widget, "KeyBind", down ~= false) end
    end
    function s.tick(dt)
        s.now = (s.now or 10) + dt
        local q = s.timers; s.timers = {}; for _, fn in ipairs(q) do fn() end
        for _, f in ipairs(s.frames) do if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f, dt) end end
    end
    function s.drain() local q = s.timers; s.timers = {}; for _, fn in ipairs(q) do fn() end end
    function s.regen()
        s.combat = false; local q = s.pending; s.pending = {}; for _, fn in pairs(q) do fn() end
    end
    return s, e, ns, hosts
end

for _, client in ipairs({ "classic_era", "classic_anniversary", "classic", "live", "forever" }) do
    if not selected or selected == "BIND-01" then
        local s, e, ns, hosts = fixture(client)
        s.down.Q, s.down.E = true, true; s.press(1); s.press(2)
        s.down.Q = false; s.tick(.1)
        check(hosts[1].widget.state == "NORMAL" and hosts[2].widget.state == "PUSHED", "overlapping columns retain independent hold owners")
        s.down.E = false; s.tick(.1)
        check(hosts[2].widget.state == "NORMAL" and s.colors[1][1] == 1 and s.colors[2][1] == 1, "both releases restore without manual all-clear")
        local frames = #s.frames
        for i = 1, 2000 do s.mask = i % 8; s.down.Q, s.down.E = true, true; s.press(i % 2 + 1) end
        check(#s.timers <= 1 and #s.frames == frames, "changed-key/modifier spam coalesces one reassert kick without driver growth")
        s.down.Q, s.down.E = false, false; s.tick(.1)
        check(hosts[1].widget.state == "NORMAL" and hosts[2].widget.state == "NORMAL", "spam releases every prior column")
        s.mask = 0; s.down.Z = true; s.press(1); s.tick(.1)
        check(hosts[1].widget.state == "PUSHED", "secondary native binding key retains held feedback")
        s.down.Z = false; s.tick(.1); check(hosts[1].widget.state == "NORMAL", "secondary native key releases")
        s.down.Q = true; s.press(1); s.tick(.04); s.down.Q = false; s.tick(.02)
        check(hosts[1].widget.state == "PUSHED", "original release grace remains")
        s.tick(.03); check(hosts[1].widget.state == "NORMAL", "original grace deadline clears")
        s.down.Q = true; s.press(1); s.tick(1); s.press(1); s.tick(.51)
        check(hosts[1].widget.state == "NORMAL", "held repeat cannot reset original safety cap")
        ns.FluxBindingPushPress.ClearAll()
        -- The watched hover chord must match all three physical modifiers.
        e.FluxMouseoverKeybindModule = { IsHovercastPeekMouseContext = function() return true end }
        for wanted = 0, 7 do
            local chord = (wanted >= 4 and "ALT-" or "") .. (math.floor(wanted / 2) % 2 == 1 and "CTRL-" or "")
                .. (wanted % 2 == 1 and "SHIFT-" or "") .. "Q"
            for actual = 0, 7 do
                ns.FluxBindingPushPress.WipeUfHover(); ns.FluxBindingPushPress.ClearAll()
                s.mask = actual; s.down.Q = true
                ns.FluxBindingPushPress.RegisterUfHover("FluxMatrix_HC", chord)
                ns.FluxBindingPushPress.WakeUfHoverFromUnitFrame()
                check((hosts[1].widget.state == "PUSHED") == (wanted == actual), "all eight watched modifier masks match physical truth exactly")
            end
        end
        s.down.Q = false; ns.FluxBindingPushPress.WipeUfHover(); ns.FluxBindingPushPress.ClearAll(); s.drain()
    end
    if not selected or selected == "BIND-02" then
        local _, _, ns = fixture(client); local cm = ns.FluxBindingChordMap
        for mask = 0, 15 do
            local prefix = (mask % 2 == 1 and "ALT-" or "") .. (math.floor(mask / 2) % 2 == 1 and "CTRL-" or "")
                .. (math.floor(mask / 4) % 2 == 1 and "SHIFT-" or "") .. (mask >= 8 and "META-" or "")
            for _, base in ipairs({ "-", "=", "/", "_", "Q", "NUMPADMINUS", "MOUSEWHEELUP", "BUTTON4" }) do
                local key, mods = cm.Parse(cm.Normalize(prefix .. base))
                check(key == base and mods.alt == (mask % 2 == 1) and mods.ctrl == (math.floor(mask / 2) % 2 == 1)
                    and mods.shift == (math.floor(mask / 4) % 2 == 1) and mods.meta == (mask >= 8), "modifier/base key round-trip including delimiter")
            end
        end
        check(cm.FindColumnForChord("-") == 3 and cm.FindColumnForChord("SHIFT--") == 3, "minus keys locate their native bar column")
    end
    if not selected or selected == "BIND-04" then
        for _, mode in ipairs({ "nil", "opaque" }) do
            local s, _, ns, hosts = fixture(client, mode); s.down.Q = true
            check(pcall(s.press, 1), "nil/denied color cannot abort actual press hook")
            check(hosts[1].widget.state == "PUSHED", "legal press state survives unreadable color")
            s.down.Q = false; s.tick(.1); check(hosts[1].widget.state == "NORMAL", "unreadable color does not strand release")
            check(ns.FluxBindingPushPress.SetIconColor(hosts[1].widget.icon, .8, .1, .1), "owner public palette accepted")
            s.down.Q = true; s.press(1); near(s.colors[1][1], .8 * .62, "public owner still dims when native getter unreadable")
            ns.FluxBindingPushPress.SetIconColor(hosts[1].widget.icon, .5, .5, 1)
            near(s.colors[1][3], .62, "held palette updates retain push factor")
            s.down.Q = false; s.tick(.1); near(s.colors[1][1], .5, "release restores latest mana palette")
        end
        -- Load the actual complete Bars/EBS painters and range owner, not a
        -- copied color function. Public palette updates happen during Q/E hold.
        local s, e, ns, hosts = fixture(client)
        s.range, s.usable, s.mana = true, true, false
        e.UnitExists = function() return true end; e.UnitCanAttack = function() return true end; e.UnitCanAssist = function() return false end
        e.HasAction = function() return true end; e.GetActionInfo = function() return "spell", 101 end
        local f = ns.Flux
        f.Bars.COLOR = { usable = {1,1,1}, mana = {.5,.5,1}, unusable = {.4,.4,.4}, outOfRange = {.8,.1,.1} }
        f.EBS = { buttons = {}, badges = {} }; f.Events = { Register = function() end }
        f.Ticker = { Add = function() end, Remove = function() end }; f.MouseoverCast = { IsActive = function() return false end }
        f.Action = { HasAction = function() return true end, IsUsable = function() return s.usable, s.mana end }
        f.Spell = { GetOverrideSpell = function(id) return id end, IsInRange = function() return s.range end,
            IsUsable = function() return s.usable, s.mana end }
        f.Item = { IsInRange = function() return s.range end, CanCheckRange = function() return true end,
            IsUsable = function() return s.usable, s.mana end, IsConsumable = function() return false end, UsesConsumableCharges = function() return false end }
        loadModule("Core/Engine/Range.lua", e, ns); loadModule("ExtraButtonSystem/Engine/Paint.lua", e, ns); loadModule("Bars/Paint.lua", e, ns)
        for i = 1, 2 do f.Bars.Paint.UpdateUsable(hosts[i]); hosts[i].widget.icon.GetVertexColor = function() error("owner seed must avoid native read") end end
        s.down.Q, s.down.E = true, true; s.press(1); s.press(2)
        s.range = false; s.now = 11
        for i = 1, 2 do f.Bars.Paint.UpdateRange(hosts[i]); near(s.colors[i][1], .8 * .62, "actual painter preserves held OOR red") end
        s.range, s.usable, s.mana, s.now = true, false, true, 12
        for i = 1, 2 do f.Bars.Paint.UpdateRange(hosts[i]); f.Bars.Paint.UpdateUsable(hosts[i]); near(s.colors[i][3], .62, "actual painter preserves held mana blue") end
        s.usable, s.mana = false, false
        for i = 1, 2 do f.Bars.Paint.UpdateUsable(hosts[i]); near(s.colors[i][1], .4 * .62, "actual painter preserves held unusable dim") end
        s.down.Q = false; s.tick(.1); near(s.colors[1][1], .4, "Q release restores newest usable state")
        near(s.colors[2][1], .4 * .62, "E hold retains palette during Q release")
        s.down.E = false; s.tick(.1); near(s.colors[2][1], .4, "E release restores newest usable state")
    end
end

local function snapshotFixture()
    local s = { frames = {}, timers = {}, combat = true, store = { nextUid = 1, bindings = {} } }
    local e = setmetatable({}, { __index = _G }); e._G = e
    e.InCombatLockdown = function() return s.combat end
    e.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    e.CreateFrame = function()
        local f = { events = {} }; function f:RegisterEvent(k) self.events[k] = true end
        function f:UnregisterEvent(k) self.events[k] = nil end
        function f:SetScript(k, v) self[k] = v end
        s.frames[#s.frames + 1] = f; return f
    end
    e.FluxBinding = { RequestApplyAll = function() end, IsBindingRespecRelevant = function() return true end }
    local ns = { FluxBindingDB3 = { EnsureLive = function() return s.store end }, FluxBindingConditions = { InvalidateAvailability = function() end } }
    loadModule("Binding/Respec.lua", e, ns)
    function s.snap(id) return { version = 3, doc = { bindings = { [id] = { uid = id, key = "Q", action = { type = "spell", id = id } } } } } end
    function s.regen() s.combat = false; s.frames[1].OnEvent(s.frames[1], "PLAYER_REGEN_ENABLED") end
    function s.drain() local q = s.timers; s.timers = {}; for _, fn in ipairs(q) do fn() end end
    return s, e
end
if not selected or selected == "BIND-03" then
    for _ = 1, 5 do
        local s, e = snapshotFixture(); local done = { A = {}, B = {}, C = {} }
        local function cb(key) return function(...) done[key][#done[key] + 1] = { ... } end end
        e.FluxSpellBindings_ApplySnapshot(s.snap(1), function(ok, why)
            cb("A")(ok, why); if why == "SUPERSEDED" then e.FluxSpellBindings_ApplySnapshot(s.snap(3), cb("C")) end
        end)
        e.FluxSpellBindings_ApplySnapshot(s.snap(2), cb("B")); s.regen(); s.drain()
        check(s.store.bindings[3] and not s.store.bindings[2], "reentrant newest snapshot survives outer return")
        check(#done.A == 1 and not done.A[1][1] and #done.B == 1 and not done.B[1][1] and #done.C == 1 and done.C[1][1], "each superseded/new owner settles exactly once")
        s, e = snapshotFixture(); local first, nextDone = {}, {}
        e.FluxBindingBrowser_Refresh = function()
            e.FluxBindingBrowser_Refresh = nil; s.combat = true
            e.FluxSpellBindings_ApplySnapshot(s.snap(5), function(...) nextDone[#nextDone + 1] = { ... } end)
        end
        e.FluxSpellBindings_ApplySnapshot(s.snap(4), function(...) first[#first + 1] = { ... } end)
        s.regen(); s.drain()
        check(#first == 1 and not first[1][1] and #nextDone == 0 and s.frames[1].events.PLAYER_REGEN_ENABLED, "regen completion cannot settle or remove a newer queued owner")
        s.regen(); s.drain(); check(s.store.bindings[5] and #nextDone == 1 and nextDone[1][1], "new queued owner applies on its own regen")
        s, e = snapshotFixture(); s.combat = false; local entered = false
        e.FluxBinding.RequestApplyAll = function()
            if not entered then entered = true; e.FluxSpellBindings_ApplySnapshot(s.snap(7)); error("old request failed after reentry") end
        end
        e.FluxSpellBindings_ApplySnapshot(s.snap(6)); s.drain()
        check(s.store.bindings[7] ~= nil, "old rollback cannot overwrite newer successful document")
    end
end

if not selected or selected == "BIND-05" then
    local s, e, ns, hosts = fixture("forever"); local bars = ns.Flux.Bars
    bars.ForEachHost = function(fn) for i = 1, 2 do fn(hosts[i]) end end
    bars.Hosts = { LiveSlot = function(host) return host.slot end }
    loadModule("Bars/SlotProgram.lua", e, ns); local sp = ns.FluxSlotProgram
    sp.Apply(1, "/cast Original"); sp.Apply(2, "/cast Untouched")
    s.combat = true; sp.Apply(1, false); check(hosts[1].widget.attrs["flux-p-1"] == "/cast Original", "combat clear defers protected attributes")
    s.regen(); check(sp.Get(1) == nil and hosts[1].widget.attrs["flux-p-1"] == nil and hosts[1].widget.attrs.type == "action", "regen clears removed final logical entry")
    s.combat = true; sp.Apply(1, "/cast Old"); sp.Apply(1, false); sp.Apply(1, "/cast Latest"); s.regen()
    check(hosts[1].widget.attrs["flux-p-1"] == "/cast Latest", "latest combat model wins over tombstone")
    s.combat = true; sp.Apply(1, false); s.combat = false; sp.Apply(1, false)
    check(hosts[1].widget.attrs["flux-p-1"] == nil, "identical OOC clear reconciles outstanding protected state")
    local replacement = e.CreateFrame("Button", "FluxReplacementHost"); hosts[1].widget = replacement; s.regen()
    check(replacement.attrs["flux-p-2"] == "/cast Untouched", "full pending reconciliation preserves existing programs on replacement host")
end

if not selected or selected == "MOD-01" then
    local s, e, ns = fixture("forever")
    local removals, insertions, resolves, paints = 0, 0, 0, 0
    e.table = setmetatable({ remove = function(t, i) removals = removals + 1; return table.remove(t, i) end }, { __index = table })
    local bars, all = ns.Flux.Bars, {}
    bars.NUM_COLUMNS = 19; bars.ForEachHost = function(fn) for _, host in ipairs(all) do fn(host) end end
    bars.Paint = { Dirty = function() paints = paints + 1 end }
    loadModule("Bars/SlotMath.lua", e, ns); loadModule("Bars/Hosts.lua", e, ns); loadModule("Bars/State.lua", e, ns)
    bars.State.GetCurrentPage = function() return s.page or 1 end
    local resolve = bars.SlotMath.Resolve
    bars.SlotMath.Resolve = function(...) resolves = resolves + 1; return resolve(...) end
    for col = 1, 19 do
        for _, row in ipairs({ "main", "sec", "tert" }) do
            local f = e.CreateFrame("Button", "FluxIndex_" .. row .. col)
            f:SetAttribute("flux-has-sec", 1); f:SetAttribute("flux-has-tert", 1)
            all[#all + 1] = { widget = f, column = col, row = row }
        end
    end
    bars.State.IndexLiveSlots()
    for _, host in ipairs(all) do
        local list = bars.Hosts.ForSlot(host.slot)
        setmetatable(list, { __newindex = function(t, k, v) insertions = insertions + 1; rawset(t, k, v) end })
    end
    s.combat = true; local beforePaints = paints
    for _ = 1, 2000 do bars.State.IndexLiveSlots() end
    check(removals == 0 and insertions == 0 and paints == beforePaints, "unchanged combat index does not remove/reinsert or repaint stable memberships")
    check(resolves == 57 * 2001, "immediate live resolution cadence is retained, not broadly debounced")
    s.mask = 1; bars.State.IndexLiveSlots()
    check(paints == beforePaints + 38, "real Shift swaps preserve changed-row paint cadence")
    for _, host in ipairs(all) do
        local count = 0; for _, member in ipairs(bars.Hosts.ForSlot(host.slot)) do if member == host then count = count + 1 end end
        check(count == 1 and host.widget.action == host.slot, "reverse index and painted live slot remain coherent")
    end
    local oldRemove, oldInsert, oldPaint = removals, insertions, paints
    s.mask = 5; bars.State.IndexLiveSlots()
    check(removals == oldRemove and insertions == oldInsert and paints == oldPaint, "Alt changes leave equivalent Shift mapping untouched")
    local host = all[1]; local list = bars.Hosts.ForSlot(host.slot)
    list[#list + 1] = host; bars.Hosts.IndexSlot(host, host.slot)
    local count = 0; for _, member in ipairs(list) do if member == host then count = count + 1 end end
    check(count == 1, "idempotent fast path retains legacy duplicate-membership repair")
end

if not selected or selected == "BIND-06" then
    local s, e, ns = fixture("forever"); local overrides, routing = {}, {}
    e.SetOverrideBindingClick = function(_, _, key, name) overrides[key] = name end
    e.SetOverrideBinding = function(_, _, key) overrides[key] = nil end
    e.FluxMouseoverKeybindModule = { SetUfHoverRouting = function(_, keys, names) routing = {}; for i, key in ipairs(keys) do routing[key] = names[i] end; return true end }
    loadModule("Binding/Core/SecurePool.lua", e, ns)
    local body = read("Binding/Core/Apply.lua"); local a = assert(body:find("local overrideOwner = CreateFrame", 1, true))
    local b = assert(body:find("local function MainStripButtonName", a, true))
    local apply, name = assert(load("local ns=...;local Pool=ns.FluxSecureButtonPool;local ChordMap=ns.FluxBindingChordMap\n" .. body:sub(a, b - 1)
        .. "\nreturn ApplyFreeChords,PoolButtonName", "@Binding/Core/Apply.lua:free-chords", "t", e))(ns)
    local desired, seen = {}, {}
    for _, key in ipairs({ "=", "/", "_", "-", "_2D", "-2D", "Q", ";", "[", "]", "é" }) do
        for _, prefix in ipairs({ "", "ALT-", "CTRL-", "ALT-CTRL-SHIFT-" }) do
            local chord = prefix .. key; local frame = name(chord)
            check(not seen[frame], "bijective chord frame identity including literal escape patterns")
            seen[frame] = true; desired[chord] = { text = "/cast " .. chord, hoverText = "/cast Hover" .. chord }
        end
    end
    apply(desired, {}, {})
    for chord, want in pairs(desired) do check(e[overrides[chord]].attrs.macrotext == want.text and e[routing[chord]].attrs.macrotext == want.hoverText, "world and hover keys retain their own payload") end
    local count = #s.frames; apply(desired, {}, {}); check(#s.frames == count, "unchanged chord map reuses pool frames")
    local keep = "ALT-/"; apply({ [keep] = desired[keep] }, {}, {})
    check(e[overrides[keep]].attrs.macrotext == desired[keep].text, "removing punctuation peer cannot poison survivor")
end
print("binding roadmap: " .. checks .. " checks passed (" .. (selected or "BIND-01..06") .. "; native acceptance pending)")
