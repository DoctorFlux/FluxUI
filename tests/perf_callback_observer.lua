-- Owned dispatcher timing only: no WoW secure VM or native FPS is modeled.
local function read(path)
    local f = assert(io.open(path, "rb")); local value = f:read("*a"); f:close(); return value
end
local checks = 0
local function check(value, message)
    checks = checks + 1; assert(value, message)
end

local function fixture(branch)
    local s = { clock = 0, reads = 0, frames = {}, timers = {}, errors = {}, deferred = {}, locked = false }
    local e = setmetatable({}, { __index = _G }); e._G = e
    local opaque = setmetatable({}, {
        __lt = function() error("secret clock compared") end,
        __le = function() error("secret clock compared") end,
        __sub = function() error("secret clock arithmetic") end,
    })
    e.type = function(value) if rawequal(value, opaque) then return "number" end; return type(value) end
    e.issecretvalue = function(value) return rawequal(value, opaque) end
    e.debugprofilestop = function()
        s.reads = s.reads + 1
        if s.badClock == "secret" then return opaque end
        if s.badClock == "infinite" then return math.huge end
        if s.badClock == "nan" then return 0 / 0 end
        return s.clock
    end
    e.geterrorhandler = function()
        return function(message) s.errors[#s.errors + 1] = message; s.clock = s.clock + 7 end
    end
    e.wipe = function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
    e.C_EventUtils = { IsEventValid = function() return true end }
    e.CreateFrame = function()
        local f = { events = {}, scripts = {}, shown = true }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:RegisterUnitEvent(event, unit) self.events[event] = unit end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:IsShown() return self.shown end
        function f:SetScript(name, fn) self.scripts[name] = fn end
        s.frames[#s.frames + 1] = f; return f
    end
    local flux = { Client = { expansion = branch }, Engine = {} }
    flux.Timer = { After = function(delay, fn) check(delay == 0, "scheduler preserves next-frame deferral"); s.timers[#s.timers + 1] = fn end }
    flux.Combat = { InLockdown = function() return s.locked end,
        Defer = function(key, fn) s.deferred[key] = fn end }
    flux.Safecall = function(fn, ...)
        local ok, result = pcall(fn, ...)
        if not ok then e.geterrorhandler()(result) end
        return ok, result
    end
    for _, name in ipairs({ "Events", "Ticker", "Scheduler" }) do
        assert(load(read("Core/Engine/" .. name .. ".lua"), "@Core/Engine/" .. name .. ".lua", "t", e))("_FluxUI", { Flux = flux })
    end
    s.flux, s.env = flux, e
    function s:fire(event, ...) self.frames[2].scripts.OnEvent(nil, event, ...) end
    function s:tick(elapsed) self.frames[3].scripts.OnUpdate(nil, elapsed or .016) end
    function s:nextFrame()
        local queue = self.timers; self.timers = {}
        for _, fn in ipairs(queue) do fn() end
    end
    function s:resume()
        local queue = self.deferred; self.deferred = {}
        for _, fn in pairs(queue) do fn() end
    end
    return s
end

local branches = { "live", "forever", "classic_era", "classic_anniversary", "classic" }
for _, branch in ipairs(branches) do
    local s = fixture(branch)
    local events, ticker, scheduler = s.flux.Events, s.flux.Ticker, s.flux.Scheduler
    local payload = setmetatable({}, { __index = function() error("diagnostic inspected event payload") end })
    local eventRuns, tickRuns, unitRuns = 0, 0, 0
    local eventFn = function(event, value) check(event == "EXAMPLE" and value == payload, "event arguments remain exact"); eventRuns = eventRuns + 1; s.clock = s.clock + 3 end
    local tickFn = function(elapsed) check(elapsed == .016, "ticker elapsed remains exact"); tickRuns = tickRuns + 1; s.clock = s.clock + 4 end
    local unitFn = function(event, unit, value) check(event == "UNIT_EXAMPLE" and unit == "player" and value == payload, "unit arguments remain exact"); unitRuns = unitRuns + 1; s.clock = s.clock + 5 end
    events.Register("EXAMPLE", eventFn); ticker.Add("owned.tick", tickFn)
    local unit = assert(events.RegisterUnit("UNIT_EXAMPLE", "player", unitFn))
    local frames = #s.frames
    s:fire("EXAMPLE", payload); s:tick(); unit.scripts.OnEvent(nil, "UNIT_EXAMPLE", "player", payload)
    scheduler.Request("eval", "owned", function() end); s:nextFrame()
    check(s.reads == 0 and eventRuns == 1 and tickRuns == 1 and unitRuns == 1, branch .. ": unobserved services do not query clocks")

    local samples, traceEvents, traceTicks = {}, 0, 0
    events.SetTrace(function(event, ms) check(event == "EXAMPLE" and ms >= 3, "legacy event trace remains active"); traceEvents = traceEvents + 1 end)
    ticker.SetTrace(function(ms) check(ms >= 4, "legacy ticker trace remains active"); traceTicks = traceTicks + 1 end)
    local function observer(key, fn, ms, failed, tokens) samples[#samples + 1] = { key = key, fn = fn, ms = ms, failed = failed, tokens = tokens } end
    local stopEvents = assert(events.ObserveTiming(observer))
    local stopTicker = assert(ticker.ObserveTiming(observer))
    local stopScheduler = assert(scheduler.ObserveTiming(observer))
    for _, service in ipairs({ events, ticker, scheduler }) do
        local rejected, reason = service.ObserveTiming(observer)
        check(not rejected and type(reason) == "string", "a second timing owner is rejected without replacing the first")
    end
    s:fire("EXAMPLE", payload); s:tick(); unit.scripts.OnEvent(nil, "UNIT_EXAMPLE", "player", payload)
    check(#samples == 3 and samples[1].key == "EXAMPLE" and samples[1].fn == eventFn and samples[1].ms == 3
        and samples[2].key == "owned.tick" and samples[2].fn == tickFn and samples[2].ms == 4
        and samples[3].key == "UNIT_EXAMPLE" and samples[3].fn == unitFn and samples[3].ms == 5,
        "owned callback timings include event, ticker and dedicated unit dispatch")
    check(traceEvents == 1 and traceTicks == 1 and #s.frames == frames, "timing observation creates no driver and does not steal legacy traces")
    for _, row in ipairs(samples) do check(row.failed == false, "successful callbacks are not marked failed") end

    local order = {}
    for _, tier in ipairs({ "layout", "display", "eval", "structural", "inventory" }) do
        local fn = function(tokens, reasons)
            check(tokens[tier] and reasons.trigger, "scheduler forwards original bucket token/reason tables")
            order[#order + 1] = tier .. ".callback"; s.clock = s.clock + 2
        end
        local listener = function() order[#order + 1] = tier .. ".listener"; s.clock = s.clock + 1 end
        scheduler.Register(tier, listener)
        scheduler.Request(tier, tier, fn, "trigger")
    end
    local oldSamples = #samples; s:nextFrame()
    check(table.concat(order, ",") == "layout.callback,layout.listener,display.callback,display.listener,eval.callback,eval.listener,structural.callback,structural.listener,inventory.callback,inventory.listener",
        "all tier callback/listener ordering stays unchanged")
    check(#samples == oldSamples + 10, "all scheduler callback and listener sites are observed")
    for i = oldSamples + 1, #samples do
        local tier = samples[i].key:match("^([^.]+)")
        check(samples[i].key == order[i - oldSamples] and samples[i].ms == ((i - oldSamples) % 2 == 1 and 2 or 1), "scheduler labels exact categories and individual duration")
        check(samples[i].tokens[tier] == true, "scheduler exposes its owned token set without reading feature arguments")
    end

    stopEvents(); stopTicker(); stopScheduler()
    events.SetTrace(nil); ticker.SetTrace(nil)
    local reads, rows = s.reads, #samples
    for _ = 1, 50 do s:fire("EXAMPLE", payload); s:tick(); unit.scripts.OnEvent(nil, "UNIT_EXAMPLE", "player", payload) end
    check(s.reads == reads and #samples == rows, "cleanup leaves no timing reads, observations or recurring work")
    for _, service in ipairs({ events, ticker, scheduler }) do
        local stopOld = assert(service.ObserveTiming(observer)); stopOld()
        local stopNew = assert(service.ObserveTiming(observer)); stopOld()
        local rejected = service.ObserveTiming(observer)
        check(not rejected, "old cleanup cannot detach a new registration of the same observer")
        stopNew(); stopNew()
        local invalid, reason = service.ObserveTiming(false)
        check(not invalid and type(reason) == "string", "invalid observer is rejected without arming")
    end
end

-- Attaching traces inside a dispatch previously used an uninitialized start.
for _, kind in ipairs({ "event", "ticker" }) do
    local s = fixture("forever"); local service = kind == "event" and s.flux.Events or s.flux.Ticker
    local traced, calls = 0, 0
    local trace = function() traced = traced + 1 end
    local fn = function() calls = calls + 1; if calls == 1 then service.SetTrace(trace) end; s.clock = s.clock + 2 end
    if kind == "event" then service.Register("EDGE", fn) else service.Add("edge", fn) end
    local function fire() if kind == "event" then s:fire("EDGE") else s:tick() end end
    check(pcall(fire) and traced == 0, "mid-dispatch legacy trace attachment starts with the next invocation")
    fire(); check(traced == 1, "the following invocation uses the attached legacy trace")
    local clear = function() service.SetTrace(nil) end
    if kind == "event" then service.Register("EDGE", clear) else service.Add("clear", clear) end
    fire(); check(traced == 1, "cleared legacy traces are not invoked after their dispatch")
end

for _, kind in ipairs({ "event", "unit", "ticker", "scheduler" }) do
    local s = fixture("forever"); local rows = {}
    local service = (kind == "event" or kind == "unit") and s.flux.Events or (kind == "ticker" and s.flux.Ticker or s.flux.Scheduler)
    local stop, replace
    local observe = function(...) rows[#rows + 1] = { ... } end
    stop = assert(service.ObserveTiming(observe))
    local runs = 0
    local fn = function()
        runs = runs + 1; s.clock = s.clock + 2
        if runs == 1 then stop(); replace = assert(service.ObserveTiming(observe)) end
    end
    local unit
    if kind == "event" then service.Register("EDGE", fn)
    elseif kind == "unit" then unit = service.RegisterUnit("EDGE", "player", fn)
    elseif kind == "ticker" then service.Add("edge", fn) end
    local function fire()
        if kind == "event" then s:fire("EDGE")
        elseif kind == "unit" then unit.scripts.OnEvent(nil, "EDGE", "player")
        elseif kind == "ticker" then s:tick()
        else service.Request("eval", "edge", fn); s:nextFrame() end
    end
    fire(); check(#rows == 0, "replacing an observer mid-callback cannot attribute a partial interval to either registration")
    stop(); fire(); check(#rows == 1 and rows[1][3] == 2, "new observer survives stale cleanup and sees the next complete callback")
    replace()
end

for _, kind in ipairs({ "event", "unit", "ticker", "scheduler" }) do
    local s = fixture("forever"); local rows = {}
    local service = (kind == "event" or kind == "unit") and s.flux.Events or (kind == "ticker" and s.flux.Ticker or s.flux.Scheduler)
    local stop = assert(service.ObserveTiming(function(...) rows[#rows + 1] = { ... } end))
    local fn = function() s.clock = s.clock + 5; error("original callback failure") end
    local unit
    if kind == "event" then service.Register("FAIL", fn)
    elseif kind == "unit" then unit = service.RegisterUnit("FAIL", "player", fn)
    elseif kind == "ticker" then service.Add("fail", fn) end
    local function fire()
        if kind == "event" then s:fire("FAIL")
        elseif kind == "unit" then unit.scripts.OnEvent(nil, "FAIL", "player")
        elseif kind == "ticker" then s:tick()
        else service.Request("eval", "fail", fn); s:nextFrame() end
    end
    local ok, err = pcall(fire)
    if kind == "unit" then
        check(not ok and tostring(err):find("original callback failure", 1, true) and #rows == 0 and #s.errors == 0,
            "unit failures retain direct propagation; unsuccessful unit calls are outside timing coverage")
    else
        check(ok and #s.errors == 1 and #rows == 1 and rows[1][3] == 12 and rows[1][4] == true,
            "existing error reporting remains visible and is included in failed owned-call duration")
    end
    stop()
end

do
    local s = fixture("forever"); local rows = {}
    s.flux.Events.Register("INNER", function() s.clock = s.clock + 2 end)
    s.flux.Events.Register("OUTER", function() s.clock = s.clock + 3; s:fire("INNER") end)
    local stop = assert(s.flux.Events.ObserveTiming(function(...) rows[#rows + 1] = { ... } end))
    s:fire("OUTER")
    check(#rows == 2 and rows[1][1] == "INNER" and rows[1][3] == 2 and rows[2][1] == "OUTER" and rows[2][3] == 5,
        "reentrant timings retain inclusive intervals; nested rows must not be summed")
    stop()
end

for _, bad in ipairs({ "secret", "infinite", "nan", "backward" }) do
    local s = fixture("forever"); local records = 0
    local observe = function() records = records + 1 end
    for _, service in ipairs({ s.flux.Events, s.flux.Ticker, s.flux.Scheduler }) do assert(service.ObserveTiming(observe)) end
    s.badClock = bad ~= "backward" and bad or nil
    local fn = function() s.clock = s.clock - 1 end
    s.flux.Events.Register("BAD_CLOCK", fn); s.flux.Ticker.Add("bad", fn)
    s:fire("BAD_CLOCK"); s:tick(); s.flux.Scheduler.Request("eval", "bad", fn); s:nextFrame()
    check(records == 0, "unreadable, nonfinite or reversed clocks produce no fabricated timings: " .. bad)
end

do
    local s = fixture("forever"); local rows = {}
    local scheduler = s.flux.Scheduler
    assert(scheduler.ObserveTiming(function(...) rows[#rows + 1] = { ... } end))
    local executed = 0
    for i = 1, 11 do scheduler.Request("inventory", i, function() executed = executed + 1; s.clock = s.clock + 1 end) end
    scheduler.Register("inventory", function() s.clock = s.clock + 2 end)
    s:nextFrame()
    check(executed == 8 and #rows == 9 and scheduler.HasPending("inventory"), "inventory retains its eight-callback budget and observes the listener separately")
    s:nextFrame(); check(executed == 11 and #rows == 13 and not scheduler.HasPending(), "remaining inventory callbacks retain their next-frame execution")
    rows = {}; s.locked = true
    scheduler.Request("structural", "first", function() executed = executed + 1; s.clock = s.clock + 3; s.locked = true end)
    scheduler.Request("structural", "second", function() executed = executed + 1; s.clock = s.clock + 4 end)
    s:nextFrame(); check(#rows == 0, "deferred protected work is not timed as if it had executed")
    s.locked = false; s:resume(); check(#rows == 1 and s.locked, "combat re-entry pauses structural work at its original boundary")
    s.locked = false; s:resume(); check(#rows == 2 and rows[1][3] == 3 and rows[2][3] == 4, "structural resume times exactly the remaining callback")
end

for _, kind in ipairs({ "event", "unit", "ticker", "scheduler" }) do
    local s = fixture("forever")
    local service = (kind == "event" or kind == "unit") and s.flux.Events or (kind == "ticker" and s.flux.Ticker or s.flux.Scheduler)
    local runs = 0
    local stop = assert(service.ObserveTiming(function() error("timing observer failure") end))
    local fn = function() runs = runs + 1; s.clock = s.clock + 1 end
    local unit
    if kind == "event" then service.Register("OBS_FAIL", fn)
    elseif kind == "unit" then unit = service.RegisterUnit("OBS_FAIL", "player", fn)
    elseif kind == "ticker" then service.Add("observer.fail", fn) end
    local function fire()
        if kind == "event" then s:fire("OBS_FAIL")
        elseif kind == "unit" then unit.scripts.OnEvent(nil, "OBS_FAIL", "player")
        elseif kind == "ticker" then s:tick()
        else service.Request("eval", "observer.fail", fn); s:nextFrame() end
    end
    check(pcall(fire) and runs == 1 and #s.errors == 1 and tostring(s.errors[1]):find("timing observer failure", 1, true),
        "observer failure is visibly reported without breaking feature dispatch")
    local reads = s.reads; fire()
    check(runs == 2 and #s.errors == 1 and s.reads == reads, "a failed observer detaches its own registration to avoid an error storm")
    local replacement = assert(service.ObserveTiming(function() end)); stop()
    check(not service.ObserveTiming(function() end), "failed-observer cleanup cannot detach its later replacement")
    replacement()
end

print(string.format("Owned callback timing observers: %d checks passed; five client models, no native VM/FPS claim", checks))
