-- Replay the production trinket press watcher against its retained prior body.
-- No secure attributes, binding writes or WoW secure VM are modeled here.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local source = read("ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua")
local first = assert(source:find('local keyPushWatch = CreateFrame', 1, true))
source = source:sub(first, assert(source:find('-- /use 13 parses', first, true)) - 1)
local before = read("tests/fixtures/trinket_push_before.txt")
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function fixture(body, branch)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local s = { now = 0, queries = 0, down = {}, mouse = {}, bindings = { { "Q" }, { "E", "CTRL-BUTTON4" } }, timers = {}, widgets = {} }
    env.GetTime = function() return s.now end
    env.GetBindingKey = function(name)
        s.queries = s.queries + 1
        return table.unpack(s.bindings[name == "FLUXTRINKET1" and 1 or 2] or {})
    end
    env.IsKeyDown = function(key) if s.keyError then error("input unavailable") end; return s.down[key] end
    env.IsMouseButtonDown = function(key) return s.mouse[key] end
    env.IsShiftKeyDown = function() return s.shift end
    env.IsControlKeyDown = function() return s.ctrl end
    env.IsAltKeyDown = function() return s.alt end
    env.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    env.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    env.CreateFrame = function()
        local f = { shown = true, scripts = {}, events = {} }
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:RegisterEvent(event) self.events[event] = true end
        function f:SetAttribute() error("watcher must not write secure attributes") end
        s.watch = f; return f
    end
    local function region()
        return { shown = false, Show = function(self) self.shown = true end,
            Hide = function(self) self.shown = false end, SetAllPoints = function() end, SetColorTexture = function() end }
    end
    for i = 1, 2 do
        local w = { scripts = {}, state = "NORMAL", PushedTexture = region(), icon = {} }
        w.icon.color = { 0.7, 0.8, 0.9 }
        function w.icon:GetVertexColor() return table.unpack(self.color) end
        function w.icon:SetVertexColor(r, g, b) self.color[1], self.color[2], self.color[3] = r, g, b end
        function w:SetButtonState(state, locked) check(not locked, "push visuals never lock native button state"); self.state = state end
        function w:UnlockHighlight() end
        function w:CreateTexture() return region() end
        function w:GetScript(event) return self.scripts[event] end
        function w:SetScript(event, fn) self.scripts[event] = fn end
        function w:HookScript(event, fn)
            local old = self.scripts[event]
            self.scripts[event] = function(...) if old then old(...) end; return fn(...) end
        end
        function w:SetChecked(value) self.checked = value end
        s.widgets[i] = w
    end
    local tm = { Frame = { IsShown = function() return not s.hidden end }, VisibilityState = "both_equipped",
        SlotWidget = function(index) return s.widgets[index + 1] end,
        GetEquippedTrinketSlots = function() return { s.slot or 13 } end,
        BuildMenu = function() s.menus = (s.menus or 0) + 1 end }
    env.FluxTrinketMenu, s.tm = tm, tm
    assert(load("local TM = FluxTrinketMenu\nlocal wipe = wipe\n" .. body, "@trinket-" .. branch, "t", env))()
    for _, w in ipairs(s.widgets) do tm.HookTrinketClickScripts(w); tm.HookTrinketClickScripts(w) end
    tm.SyncKeybindPushWatch()
    function s:event(event)
        if self.watch.events[event] then self.watch.scripts.OnEvent(self.watch, event) end
    end
    function s:step(dt)
        self.now = self.now + dt
        if self.watch.shown then self.watch.scripts.OnUpdate(self.watch) end
        local timers = self.timers; self.timers = {}
        for _, fn in ipairs(timers) do fn() end
    end
    function s:input(index, event, ...)
        local w = self.widgets[index]; if w.scripts[event] then w.scripts[event](w, ...) end
    end
    function s:snapshot()
        local out = { self.menus or 0 }
        for _, w in ipairs(self.widgets) do
            out[#out + 1] = table.concat({ w.state, tostring(w.PushedTexture.shown),
                tostring(w._fluxTrinketPushShade and w._fluxTrinketPushShade.shown or false),
                string.format("%.3f/%.3f/%.3f", table.unpack(w.icon.color)) }, ":")
        end
        return table.concat(out, "|")
    end
    return s
end
local function replay(body, branch)
    local a, b = fixture(before, branch), fixture(body, branch)
    local function both(fn) fn(a); fn(b); check(a:snapshot() == b:snapshot(), branch .. ": press behavior differs from prior implementation") end
    both(function(s) s:step(0.01) end)
    both(function(s) s.down.Q = true; s:step(0.01) end) -- no OnClick: release-only secure bind
    both(function(s) s:step(0.4) end)
    both(function(s) s.down.Q = false; s:step(0.01) end)
    both(function(s) s:step(0.21) end)
    both(function(s) s.bindings[1] = { "R" }; s:event("UPDATE_BINDINGS"); s.down.R = true; s:step(0.01) end)
    both(function(s) s.down.R = false; s:step(0.3) end)
    for _, chord in ipairs({ "SHIFT-Q", "CTRL-Q", "ALT-Q", "SHIFT-CTRL-Q", "CTRL-SHIFT-Q", "CTRL-BUTTON4", "ALT-MOUSEWHEELUP", "Q" }) do
        both(function(s) s.bindings[1] = { chord }; s:event("UPDATE_BINDINGS"); s.down.Q = true; s.mouse.Button4 = true end)
        for _, mods in ipairs({ { false, false, false }, { true, false, false }, { false, true, false }, { false, false, true }, { true, true, true } }) do
            both(function(s)
                s.hidden = true; s.tm.SyncKeybindPushWatch()
                s.hidden = false; s.tm.SyncKeybindPushWatch()
                s.shift, s.ctrl, s.alt = table.unpack(mods); s:step(0.01)
            end)
        end
        both(function(s) s.down.Q = false; s.mouse.Button4 = false; s:step(0.3) end)
    end
    both(function(s) s.shift, s.ctrl, s.alt = false, false, false; s.bindings = { { "Q" }, { "E" } }; s:event("UPDATE_BINDINGS") end)
    both(function(s) s.down.Q, s.down.E = true, true; s:step(0.01) end)
    both(function(s) s:step(1.6); s:step(0.01); s:step(0.01) end)
    both(function(s) s.down.Q, s.down.E = false, false; s:step(0.3) end)
    both(function(s) s.tm.VisibilityState = "one_equipped"; s.slot = 14; s.down.Q = true; s.down.E = true; s:step(0.01) end)
    both(function(s) s:step(1.6) end) -- safety cap and eventual physical release
    both(function(s) s:step(0.01) end)
    both(function(s) s.down.Q, s.down.E = false, false; s:step(0.01) end)
    both(function(s) s.mouse.LeftButton = true; s:input(2, "OnMouseDown", "LeftButton"); s:step(0.01) end)
    both(function(s) s.mouse.LeftButton = false; s:event("GLOBAL_MOUSE_UP"); s:step(0.01) end)
    both(function(s) s:step(0.21) end)
    both(function(s) s:input(1, "OnClick", "KeyBind", true); s:step(0.01) end)
    both(function(s) s:step(0.21); s:input(1, "OnMouseDown", "RightButton") end)
    both(function(s) s.keyError = true; s:step(0.01) end)
    both(function(s) s.hidden = true; s.tm.SyncKeybindPushWatch() end)
    both(function(s) s.hidden = false; s.tm.SyncKeybindPushWatch(); s.keyError = false; s:step(0.01) end)
    both(function(s) s.tm.VisibilityState = "bag_only"; s.down.Q = true; s:step(0.01) end)
    both(function(s) s.tm.VisibilityState = "none"; s:step(0.21) end)
end
for _, branch in ipairs({ "live", "forever", "classic_era", "classic_anniversary", "classic" }) do replay(source, branch) end
local function idle(body)
    local s = fixture(body, "live")
    collectgarbage("collect"); collectgarbage("stop")
    local start, queries = collectgarbage("count"), s.queries
    for _ = 1, 4800 do s.now = s.now + 1 / 240; s.watch.scripts.OnUpdate(s.watch) end
    local allocated = collectgarbage("count") - start
    collectgarbage("restart")
    return s.queries - queries, allocated
end
local oldQueries, oldKB = idle(before)
local queries, kb = idle(source)
check(oldQueries == 9600 and queries == 0, "4800 idle frames avoid all 9600 repeated binding lookups")
check(kb < oldKB / 10, "idle table allocation is eliminated without lowering polling cadence")
local mutations = {
    { 'if event == "UPDATE_BINDINGS" then', 'if event == "UNUSED" then' },
    { 'return shift and not ctrl', 'return shift' },
    { 'if chord.mode == "both" then', 'if false then' },
    { 'if i == 1 then held1 = widget else held2 = widget end', 'held1 = widget' },
}
for i, pair in ipairs(mutations) do
    local a, b = assert(source:find(pair[1], 1, true))
    local mutant = source:sub(1, a - 1) .. pair[2] .. source:sub(b + 1)
    check(not pcall(replay, mutant, "live"), "behavioral negative control " .. i .. " is rejected")
end
print(("idle trinkets: %d checks; five client models; %d mutations rejected; 4800 frames binding queries %d -> %d; Lua heap %.2fKB -> %.2fKB (GC paused in fixture only)")
    :format(checks, #mutations, oldQueries, queries, oldKB, kb))
