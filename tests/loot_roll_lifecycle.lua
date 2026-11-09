-- Replay real loot positioning with persistent native-frame identities.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s
end
local source, measure = "Other/FluxLootRollPosition.lua", false
for i, value in ipairs(arg or {}) do
    if value == "--source" then source = assert(arg[i + 1]) end
    if value == "--measure" then measure = true end
end
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function boot(body, legacy)
    local s = { frames = {}, combat = false, writes = 0, hooks = 0, ns = {} }
    local function frame()
        local f = { scripts = {}, events = {}, hooks = {}, shown = true }
        function f:SetScript(k, fn) self.scripts[k] = fn end
        function f:GetScript(k) return self.scripts[k] end
        function f:RegisterEvent(k) self.events[k] = true end
        function f:UnregisterAllEvents() self.events = {} end
        function f:HookScript(k, fn) self.hooks[k] = self.hooks[k] or {}; table.insert(self.hooks[k], fn); s.hooks = s.hooks + 1 end
        function f:Hide() self.shown = false end
        function f:Show() self.shown = true end
        function f:ClearAllPoints() assert(not s.combat, "protected clear in combat") end
        function f:SetPoint(...) assert(not s.combat, "protected anchor in combat"); self.point = { ... }; s.writes = s.writes + 1 end
        return f
    end
    s.loot = frame()
    local env = setmetatable({ InCombatLockdown = function() return s.combat end }, { __index = _G }); env._G = env
    env[legacy and "GroupLootFrame" or "GroupLootContainer"] = s.loot
    env.CreateFrame = function() local f = frame(); s.frames[#s.frames + 1] = f; return f end
    assert(load(body, "@loot-position-source", "t", env))("_FluxUI", s.ns)
    function s:event(k)
        local snapshot = {}; for i, f in ipairs(self.frames) do snapshot[i] = f end
        for _, f in ipairs(snapshot) do if f.events[k] and f.scripts.OnEvent then f.scripts.OnEvent(f, k) end end
    end
    function s:tick()
        local snapshot = {}; for i, f in ipairs(self.frames) do snapshot[i] = f end
        for _, f in ipairs(snapshot) do if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f, 0.016) end end
    end
    function s:show() for _, fn in ipairs(self.loot.hooks.OnShow or {}) do fn(self.loot) end end
    function s:pending()
        local events, updates = 0, 0
        for _, f in ipairs(self.frames) do
            if f.events.PLAYER_REGEN_ENABLED then events = events + 1 end
            if f.shown and f.scripts.OnUpdate then updates = updates + 1 end
        end
        return events, updates
    end
    function s:ready() self.ns.PlayerFrame = { outerBorderFrame = {} } end
    return s
end
for _, branch in ipairs({ "era", "anniversary", "progression", "live", "forever" }) do
    local s = boot(read(source), branch == "era" or branch == "anniversary")
    -- Repeated loading screens while the player frame is unavailable.
    for _ = 1, 100 do s:event("PLAYER_ENTERING_WORLD") end
    local _, updates = s:pending()
    check(updates == 1, branch .. " coalesces readiness watcher")
    check(#s.frames == 2, branch .. " one startup plus one readiness frame")
    for _ = 1, 49 do s:tick() end
    local _, beforeTimeout = s:pending(); check(beforeTimeout > 0, branch .. " retains 50-update timeout")
    s:tick(); local _, afterTimeout = s:pending(); check(afterTimeout == 0, branch .. " timeout sleeps")
    s:event("PLAYER_ENTERING_WORLD"); s:ready(); s:tick()
    check(s.writes == 1, branch .. " positions immediately when player becomes available")
    check(s.hooks == 1, branch .. " one native show hook")
    -- One new native frame per combat cycle would be permanently retained.
    local start = #s.frames
    for cycle = 1, 100 do
        s.combat = true
        local writes = s.writes
        s:show(); s:show(); s:event("PLAYER_ENTERING_WORLD")
        local pending = s:pending()
        check(pending == 1, branch .. " one combat subscription " .. cycle)
        check(s.writes == writes, branch .. " no geometry write in combat " .. cycle)
        s.combat = false; s:event("PLAYER_REGEN_ENABLED")
        check(s.writes == writes + 1, branch .. " one combat-end placement " .. cycle)
        check(s:pending() == 0, branch .. " combat subscription disarmed " .. cycle)
    end
    check(#s.frames - start == 1, branch .. " reuses combat waiter over 100 cycles")
    check(s.hooks == 1, branch .. " repeated world entries retain one hook")
    local p = s.loot.point
    check(p[1] == "BOTTOM" and p[2] == s.ns.PlayerFrame.outerBorderFrame and p[3] == "TOP" and p[4] == 0 and p[5] == 6,
        branch .. " original six-pixel anchor")
    -- A cleared pending flag must not retain an idle event subscription.
    s.combat = true; s:show(); s.loot._fluxLootRollNeedsPosition = nil
    s.combat = false; s:event("PLAYER_REGEN_ENABLED")
    check(s:pending() == 0, branch .. " cleared request still disarms waiter")
    print(("METRIC %s frames=%d combat_frames=%d hooks=%d writes=%d")
        :format(branch, #s.frames, #s.frames - start, s.hooks, s.writes))
end
print(("Loot roll lifecycle: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
