-- Execute production combat deferral against a retained pre-fix body. No
-- hardware input, native secure actions or taint VM are simulated here.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local source = read("Core/Engine/Combat.lua")
local before = read("tests/fixtures/combat_queue_before.txt")
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function fixture(body, branch, profiling)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local s = { locked = true, timers = {}, errors = {}, notes = {}, frames = {}, marks = 0 }
    local flux = { Engine = {}, Timer = { After = function(delay, fn)
        check(delay == 0, "recovery uses the existing next-frame boundary"); s.timers[#s.timers + 1] = fn
    end } }
    flux.Safecall = function(fn, ...)
        local ok, result = pcall(fn, ...)
        if not ok then s.errors[#s.errors + 1] = result end
        return ok, result
    end
    flux.Startup = { Count = function() end, CheckLayout = function() s.marks = s.marks + 1 end }
    if profiling then
        flux.Perf = { Regen = {
            Time = function(_, fn) fn() end,
            NoteFlushKeys = function(keys) s.notes[#s.notes + 1] = keys end,
        } }
    end
    env.InCombatLockdown = function() return s.locked end
    env.CreateFrame = function()
        local frame = {}
        function frame:RegisterEvent(event) check(event == "PLAYER_REGEN_ENABLED", "one recovery event remains") end
        function frame:SetScript(_, fn) self.event = fn end
        s.frames[#s.frames + 1] = frame; return frame
    end
    assert(load(body, "@combat-queue-" .. branch, "t", env))("_FluxUI", { Flux = flux })
    s.combat = flux.Combat
    function s:regen() self.locked = false; self.frames[1].event(nil, "PLAYER_REGEN_ENABLED") end
    function s:frame()
        local q = self.timers; self.timers = {}
        for _, fn in ipairs(q) do fn() end
    end
    return s
end
local function exercise(body, branch, baseline, profiling)
    local s = fixture(body, branch, profiling)
    local c, ran = s.combat, {}
    c.Defer("first", function()
        ran[#ran + 1] = "first"
        c.Defer("layout", function() ran[#ran + 1] = "superseded-new" end)
        c.Defer("layout", function() ran[#ran + 1] = "latest" end)
    end)
    c.Defer("layout", function() ran[#ran + 1] = "stale" end)
    c.Defer("unrelated", function() ran[#ran + 1] = "unrelated" end)
    check(c.PendingCount() == 3, branch .. ": pending keys coalesce before regen")
    s:regen()
    check(table.concat(ran, ",") == (baseline and "first,stale,unrelated" or "first,unrelated"),
        branch .. ": stale future job does not execute after replacement")
    check(c.PendingCount() == 1 and #s.timers == 1, "one latest job remains on the next frame")
    s:frame()
    check(ran[#ran] == "latest" and not c.HasPending(), "latest request executes exactly once")
    local executions = #ran
    s:regen(); s:frame()
    check(#ran == executions, "repeated regen never repeats completed work")
    if profiling and not baseline then
        check(table.concat(s.notes[1], ",") == "first,unrelated", "profiling records executed keys without stale jobs")
    end
    -- Requests made by the currently running key still represent new work.
    c.Defer("self", function()
        ran[#ran + 1] = "self-first"
        c.Defer("self", function() ran[#ran + 1] = "self-next" end)
    end)
    check(ran[#ran] == "self-first", "running callback is not cancelled by its own replacement")
    s:frame(); check(ran[#ran] == "self-next" and not c.HasPending(), "self retry runs next frame")
    -- A newer job remains authoritative if combat starts mid-flush.
    s.locked = true
    c.Defer("edge", function()
        s.locked = true
        c.Defer("remaining", function() ran[#ran + 1] = "edge-latest" end)
    end)
    c.Defer("remaining", function() ran[#ran + 1] = "edge-stale" end)
    c.Defer("other", function() ran[#ran + 1] = "edge-other" end)
    s:regen()
    check(c.PendingCount() == 2 and s.locked, "combat edge retains newer and unrelated work")
    s:regen()
    check(ran[#ran - 1] == "edge-latest" and ran[#ran] == "edge-other" and not c.HasPending(),
        "next regen resumes latest work without restoring stale callback")
    -- A queued next-frame callback rechecks lockdown instead of forcing work.
    c.Defer("arm", function() c.Defer("next", function() ran[#ran + 1] = "after-lock" end) end)
    s.locked = true; s:frame()
    check(c.PendingCount() == 1, "lockdown before scheduled flush retains pending work")
    s:regen(); check(ran[#ran] == "after-lock", "scheduled work resumes legally")
    -- Exceptions do not turn a superseded callback into a fallback execution.
    s.locked = true
    c.Defer("failed", function()
        c.Defer("recover", function() ran[#ran + 1] = "recovered" end)
        error("controlled failure")
    end)
    c.Defer("recover", function() ran[#ran + 1] = "failed-stale" end)
    s:regen(); s:frame()
    check(#s.errors == 1 and ran[#ran] == "recovered", "logged failure preserves independent latest recovery")
    return executions
end
local oldCount, newCount
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    oldCount = exercise(before, branch, true)
    newCount = exercise(source, branch)
    exercise(source, branch, false, true)
end
local a = assert(source:find("local fn = not pending[key] and map[key]", 1, true))
local mutant = source:sub(1, a - 1) .. "local fn = map[key]" .. source:sub(a + #"local fn = not pending[key] and map[key]")
local ok, err = pcall(exercise, mutant, "forever")
check(not ok and tostring(err):find("stale future job does not execute", 1, true), "stale-execution mutation is rejected")
print(string.format("combat queue supersession: %d checks; five clients; stale mutation rejected; recovery job executions %d -> %d with identical latest result", checks, oldCount, newCount))
