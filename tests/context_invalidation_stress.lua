-- Permanent production Context/Modifier event stress. No game APIs or files are changed.
-- Local APIs are deliberately narrow models; this cannot prove native taint safety.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close()
    return s:gsub("\r\n", "\n")
end
local checks, failures, stressEvents = 0, 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function fixture(branch)
    local s = { time = 0, combat = false, mods = "", target = "target1", focus = "focus1",
        reaction = "f", events = {}, frames = {}, timers = {}, display = {}, notices = {}, errors = {} }
    local e = setmetatable({}, { __index = _G }); e._G = e
    local flux = { Client = { key = branch } }
    e.Flux = flux
    flux.Safecall = function(fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok then s.errors[#s.errors + 1] = tostring(err) end
    end
    flux.Events = { Register = function(name, fn) s.events[name] = fn end,
        Unregister = function(name) s.events[name] = nil end, IsValid = function() return true end }
    flux.Timer = { After = function(delay, fn) s.timers[#s.timers + 1] = { at = s.time + delay, fn = fn } end }
    flux.Scheduler = { Request = function(_, key, fn) s.display[key] = fn end }
    flux.Secrets = { AccessibleGUIDForUnit = function(unit)
        if s.restricted then return nil end
        return unit == "target" and s.target or s.focus
    end, SafeEqualForCache = function(a, b) return a == b end }
    flux.Bars = { ProgramFace = { Needs = function() return true end,
        WakeMouseoverPoll = function() s.wakes = (s.wakes or 0) + 1 end } }
    e.InCombatLockdown = function() return s.combat end
    e.IsShiftKeyDown = function() return s.mods:find("s", 1, true) ~= nil end
    e.IsControlKeyDown = function() return s.mods:find("c", 1, true) ~= nil end
    e.IsAltKeyDown = function() return s.mods:find("a", 1, true) ~= nil end
    e.GetTime = function() return s.time end
    e.UnitExists = function(unit)
        if unit == "target" then return s.target ~= nil end
        if unit == "focus" then return s.focus ~= nil end
        return s.reaction ~= "-"
    end
    e.UnitIsDead = function() return s.reaction == "d" end
    e.UnitCanAttack = function() return s.reaction == "e" end
    e.UnitCanAssist = function() return s.reaction == "f" end
    e.CreateFrame = function()
        local frame = { scripts = {}, events = {} }
        function frame:SetScript(name, fn) self.scripts[name] = fn end
        function frame:RegisterEvent(name) self.events[name] = true end
        function frame:Show() self.shown = true end
        function frame:Hide() self.shown = false end
        s.frames[#s.frames + 1] = frame
        return frame
    end
    local ns = { Flux = flux }
    assert(load(read("Core/Engine/Modifier.lua"), "@production-modifier", "t", e))("_FluxUI", ns)
    s.modFrame = s.frames[1]
    assert(load(read("Core/Engine/Context.lua"), "@production-context", "t", e))("_FluxUI", ns)
    local function notice(info) s.notices[#s.notices + 1] = info end
    flux.Context.Subscribe(notice)
    function s.event(name)
        stressEvents = stressEvents + 1
        if name == "MODIFIER_STATE_CHANGED" then
            s.modFrame.scripts.OnEvent(s.modFrame, name)
        elseif s.events[name] then s.events[name](name) end
    end
    function s.frame()
        local fn = s.modFrame.scripts.OnUpdate
        if fn then fn(s.modFrame, 1 / 120) end
    end
    function s.flush(delay)
        s.time = s.time + (delay or 0)
        local guard = 0
        while true do
            guard = guard + 1; assert(guard < 100, "timer model must quiesce")
            local ready, keep = {}, {}
            for _, timer in ipairs(s.timers) do
                if timer.at <= s.time then ready[#ready + 1] = timer else keep[#keep + 1] = timer end
            end
            s.timers = keep
            if #ready == 0 then break end
            for _, timer in ipairs(ready) do timer.fn() end
        end
        local display = s.display; s.display = {}
        for _, fn in pairs(display) do fn() end
    end
    flux.Context.Request(true); s.flush(); s.notices = {}
    return s, flux, notice
end

for _, branch in ipairs({ "live", "forever", "classic_era", "classic_anniversary", "classic" }) do
    local s, flux, notice = fixture(branch)
    -- 128,000 modifier events per model, duplicate/reversed/partial releases.
    -- The service reads actual final held state, independent of event payload order.
    local expectedNotifications = 0
    for tick = 1, 500 do
        s.mods = tick % 2 == 0 and "sc" or ""
        for i = 1, 256 do
            s.event("MODIFIER_STATE_CHANGED")
        end
        local previous = #s.notices
        s.frame(); s.flush()
        if tick > 1 then expectedNotifications = expectedNotifications + 1 end
        check(#s.notices - previous <= 1, branch .. " burst has at most one context delivery")
        check(not flux.Modifier.IsArmed(), branch .. " modifier driver parks after the burst")
        check(#s.timers == 0, branch .. " modifier burst leaves no timer backlog")
    end
    check(#s.notices == expectedNotifications, branch .. " every changed final chord is delivered")
    check(#s.frames == 1, branch .. " input storm allocates no extra driver frames")
    check(#s.errors == 0, branch .. " callbacks have no hidden simulation errors")

    -- Target/mouseover bursts should retain the wider requested invalidation.
    -- Each sequence starts from a fresh production bus to avoid cross-case state.
    for _, kind in ipairs({ "target", "mods", "combat" }) do
        local a, fx = fixture(branch)
        if kind == "target" then a.target = "target2"; a.event("PLAYER_TARGET_CHANGED") end
        if kind == "mods" then a.mods = "s"; a.event("MODIFIER_STATE_CHANGED"); a.frame() end
        if kind == "combat" then a.combat = true; a.event("PLAYER_REGEN_DISABLED") end
        a.reaction = "e"; a.event("UPDATE_MOUSEOVER_UNIT"); a.flush()
        local got = a.notices[#a.notices]
        check(got ~= nil, branch .. " mixed " .. kind .. "/mouseover burst delivers")
        check(got and got[kind] == true, branch .. " mixed " .. kind .. "/mouseover burst retains " .. kind .. " invalidation")
        print(("OBSERVATION branch=%s ordering=%s_then_mouseover notice=%s requested_flag=%s mouseoverOnly=%s")
            :format(branch, kind, tostring(got ~= nil), tostring(got and got[kind]), tostring(got and got.mouseoverOnly)))
        -- Reverse ordering is a control: full request should widen the pending refresh.
        local b, fy = fixture(branch)
        b.reaction = "e"; b.event("UPDATE_MOUSEOVER_UNIT")
        if kind == "target" then b.target = "target2"; b.event("PLAYER_TARGET_CHANGED") end
        if kind == "mods" then b.mods = "s"; b.event("MODIFIER_STATE_CHANGED"); b.frame() end
        if kind == "combat" then b.combat = true; b.event("PLAYER_REGEN_DISABLED") end
        b.flush(0.08)
        local reverse = b.notices[#b.notices]
        check(reverse and reverse[kind] == true, branch .. " reverse ordering retains " .. kind .. " invalidation")
    end

    -- Restricted GUID accessor returns unknown, rather than an inspectable value.
    -- This checks fallback logic only; Lua tables cannot emulate native secrets.
    s.restricted = true; s.target = "other"; s.focus = "other-focus"
    s.event("PLAYER_TARGET_CHANGED"); s.flush()
    check(type(flux.Context.Fingerprint()) == "string", branch .. " unavailable GUID uses public placeholder")
    for _, reaction in ipairs({ "-", "f", "e", "o", "d" }) do
        s.reaction = reaction; s.event("UPDATE_MOUSEOVER_UNIT"); s.flush(0.08)
        check(flux.Context.MouseoverReactionClass() == reaction, branch .. " reaction transition " .. reaction)
    end
    flux.Context.Unsubscribe(notice)
    check(not flux.Context.HasSubscribers(), branch .. " last subscriber detaches")
    check(not flux.Modifier.IsArmed(), branch .. " unsubscribed modifier driver stays parked")
    local before = #s.notices
    for i = 1, 10000 do s.event("MODIFIER_STATE_CHANGED") end
    s.frame(); s.flush(0.1)
    check(#s.notices == before, branch .. " detached context receives no notifications")
    print(("METRIC branch=%s modifier_events=138002 stress_frames=500 final_context_notices=%d pending_timers=%d")
        :format(branch, #s.notices, #s.timers))
end
print(("SUMMARY checks=%d failures=%d events=%d"):format(checks, failures, stressEvents))
os.exit(failures > 0 and 1 or 0)
