-- Optional spike diagnostics: bounded data, observer ownership and honest scope.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local sourcePath = root .. "Other/FluxPerfCapture.lua"
for i, value in ipairs(arg or {}) do if value == "--source" then sourcePath = assert(arg[i + 1]) end end
local file = assert(io.open(sourcePath, "rb")); local source = file:read("*a"); file:close()
local checks = 0
local function check(value, message)
    assert(value, "spike watch: " .. message)
    checks = checks + 1
end

local function harness(options)
    options = options or {}
    local env = setmetatable({}, { __index = function(_, key)
        if options.optional == "missing" and (key == "collectgarbage" or key == "BugTabs"
            or key == "C_AddOnProfiler" or key == "Enum") then return nil end
        return _G[key]
    end }); env._G = env
    local s = { now = 0, clock = 0, frames = {}, timers = {}, output = {}, scans = 0,
        metricReads = 0, errorReads = 0, heapReads = 0, clockReads = 0,
        observerAdds = 0, observerReleases = 0, errors = 2, heap = 1024, services = {} }
    local secret = setmetatable({}, {
        __tostring = function() error("formatted secret") end,
        __add = function() error("used secret arithmetic") end,
        __sub = function() error("used secret arithmetic") end,
        __lt = function() error("compared secret") end,
        __le = function() error("compared secret") end,
    })
    local invalidNumbers = { nan = 0 / 0, infinite = math.huge, negative = -1 }
    s.secret = secret
    env.issecretvalue = function(value) return rawequal(value, secret) end
    env.issecrettable = function(value) return type(value) == "table" and rawget(value, "secretTable") == true end
    env.canaccesstable = function(value) return not rawget(value, "inaccessible") end
    env.GetTime = function() return s.now end
    env.debugprofilestop = function() s.clockReads = s.clockReads + 1; s.clock = s.clock + .001; return s.clock end
    env.GetBuildInfo = function() return "fixture", 70790 end
    env.GetCVar = function(name)
        if options.optional == "error" then error("optional CVar unavailable") end
        if options.optional == "secret" then return secret end
        return name == "maxFPSBk" and "30" or (name == "scriptProfile" and "0" or "120")
    end
    env.SetCVar = function() error("diagnostics changed a CVar") end
    env.C_CVar = { SetCVar = env.SetCVar }
    env.EnumerateFrames = function() s.scans = s.scans + 1; return nil end
    env.UpdateAddOnCPUUsage = function() error("watch requested legacy CPU scan") end
    env.GetFrameCPUUsage = function() error("watch requested frame CPU scan") end
    env.GetFunctionCPUUsage = function() error("watch requested function CPU scan") end
    env.GetAddOnCPUUsage = function() return 0 end
    env.GetFramerate = function() return 120 end
    env.InCombatLockdown = function() return false end
    env.date = function() return "fixture-date" end
    env.debug = false
    env.collectgarbage = function(operation)
        assert(operation == "count", "diagnostic forced collection")
        s.heapReads = s.heapReads + 1
        if options.optional == "error" then error("heap unavailable") end
        if options.optional == "secret" then return secret end
        if options.optional == "malformed" then return "not a number" end
        if invalidNumbers[options.optional] then return invalidNumbers[options.optional] end
        return s.heap
    end
    env.BugTabs = { GetSessionCounts = function()
        s.errorReads = s.errorReads + 1
        if options.optional == "error" then error("error counter unavailable") end
        if options.optional == "secret" then return secret end
        if options.optional == "malformed" then return {} end
        if invalidNumbers[options.optional] then return invalidNumbers[options.optional] end
        return s.errors, { { addon = "fixture", count = s.errors } }
    end }
    local function metric()
        s.metricReads = s.metricReads + 1
        if options.optional == "error" then error("profiler unavailable") end
        if options.optional == "secret" then return secret end
        if options.optional == "malformed" then return "not a number" end
        if invalidNumbers[options.optional] then return invalidNumbers[options.optional] end
        return .25
    end
    env.Enum = { AddOnProfilerMetric = { LastTime = 1 } }
    env.C_AddOnProfiler = { GetApplicationMetric = metric, GetOverallMetric = metric,
        GetAddOnMetric = function(addon, key) assert(addon == "_FluxUI" and key == 1); return metric() end,
        GetTopKAddOnsForMetric = function(key, maximum)
            s.metricReads = s.metricReads + 1; assert(key == 1 and maximum == 5)
            if options.optional == "error" then error("ranking unavailable") end
            if options.optional == "secret" then return secret end
            if options.optional == "malformed" then return "not a table" end
            if invalidNumbers[options.optional] then return {{ addOnName = "bad", metricValue = invalidNumbers[options.optional] }} end
            return {{ addOnName = "fixture", metricValue = .1 },
                {addOnName = secret, metricValue = .2}, {addOnName = "badMetric", metricValue = secret}}
        end }
    if options.optional == "missing" then env.C_AddOnProfiler, env.Enum, env.BugTabs, env.collectgarbage = nil, nil, nil, nil end
    env.print = function(...)
        local values = {}; for i = 1, select("#", ...) do values[i] = tostring(select(i, ...)) end
        s.output[#s.output + 1] = table.concat(values, " ")
    end
    env.CreateFrame = function(kind)
        assert(kind == "Frame")
        local f = { scripts = {}, events = {}, shown = false }
        function f:SetScript(key, callback) assert(key == "OnUpdate" or key == "OnEvent"); self.scripts[key] = callback end
        function f:GetScript(key) return self.scripts[key] end
        function f:RegisterEvent(key) assert(key == "PLAYER_LOGOUT"); self.events[key] = true end
        function f:UnregisterEvent(key) self.events[key] = nil end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:IsShown() return self.shown end
        s.frames[#s.frames + 1] = f; return f
    end
    local function timer(delay, callback)
        local t = { delay = delay, callback = callback }
        function t:Cancel() self.cancelled = true end
        s.timers[#s.timers + 1] = t; return t
    end
    env.C_Timer = { NewTimer = timer, NewTicker = timer }
    local flux = { Client = { expansion = "forever" }, Work = {} }
    for _, kind in ipairs({ "Events", "Ticker", "Scheduler" }) do
        local state = { token = nil, observer = nil }
        s.services[kind] = state
        flux[kind] = { SetTrace = function() error("watch replaced an existing trace") end,
            SetUnitTrace = function() error("watch replaced an existing unit trace") end,
            ObserveTiming = function(callback)
            s.observerAdds = s.observerAdds + 1
            if options.conflict == kind or state.observer then return nil, "busy fixture" end
            local token = {}; state.observer, state.token = callback, token
            local function cleanup()
                if state.token == token then
                    state.observer, state.token = nil, nil; s.observerReleases = s.observerReleases + 1
                end
            end
            state.cleanup = cleanup
            return cleanup
        end }
    end
    if options.noObservers then flux.Events, flux.Ticker, flux.Scheduler = nil, nil, nil end
    local payload = setmetatable({ inaccessible = true }, {
        __index = function() error("inspected native/event payload") end,
        __pairs = function() error("enumerated native/event payload") end,
        __tostring = function() error("formatted native/event payload") end,
    })
    s.payload = payload
    flux.savedPrivateDB = payload
    flux.Work.Burst = function() error("diagnostic invoked callback") end
    env.Flux = flux
    if options.saved then env.FluxPerfCaptureDB = options.saved end
    assert(load(source, "@Other/FluxPerfCapture.lua", "t", env))("_FluxUI", { Flux = flux })
    s.env, s.flux, s.capture = env, flux, flux.PerfCapture
    function s.tick(delta)
        s.now, s.clock = s.now + delta, s.clock + delta * 1000
        for _, frame in ipairs(s.frames) do
            if frame.shown and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, delta) end
        end
    end
    function s.emit(kind, key, ms, failed, fn, tokens)
        local observer = assert(s.services[kind].observer, "watch observer not attached")
        observer(key, fn or flux.Work.Burst, ms, failed, tokens)
    end
    function s.detached()
        for _, state in pairs(s.services) do if state.observer then return false end end
        return #s.frames == 0 or (not s.frames[1].shown and s.frames[1]:GetScript("OnUpdate") == nil
            and s.frames[1]:GetScript("OnEvent") == nil and next(s.frames[1].events) == nil)
    end
    return s
end

local function report(s) return assert(s.env.FluxPerfCaptureDB and s.env.FluxPerfCaptureDB.spikeWatch) end
local function plain(value, seen)
    local kind = type(value)
    if kind == "number" then return value == value and value ~= math.huge and value ~= -math.huge end
    if kind ~= "table" then return kind == "nil" or kind == "boolean" or kind == "string" end
    seen = seen or {}; if seen[value] then return false end; seen[value] = true
    for key, item in pairs(value) do if not plain(key, seen) or not plain(item, seen) then return false end end
    seen[value] = nil; return true
end

local function activeState(s)
    local update = assert(s.frames[1]:GetScript("OnUpdate"))
    for i = 1, 30 do
        local name, value = debug.getupvalue(update, i)
        if name == "state" then return value end
    end
    error("watch state not found")
end

do
    local s = harness()
    check(type(s.capture.StartWatch) == "function" and type(s.capture.StopWatch) == "function"
        and type(s.capture.PrintSpikes) == "function" and type(s.capture.WatchStatus) == "function", "watch APIs exist")
    check(#s.frames == 0 and #s.timers == 0 and s.scans == 0 and s.clockReads == 0
        and s.metricReads == 0 and s.errorReads == 0 and s.heapReads == 0 and s.observerAdds == 0,
        "disabled diagnostics add no frames, observers, clocks, scans, timers or metric work")
    s.capture.PrintSpikes()
    check(not s.capture.WatchStatus().active and #s.frames == 0 and s.metricReads == 0,
        "status and empty report remain dormant")
    check(s.capture.StartWatch() == true, "explicit watch starts")
    check(s.capture.WatchStatus().active and #s.frames == 1 and #s.timers == 0 and s.scans == 0
        and s.observerAdds == 3, "one owned frame attaches the three additive observers without scans/timers")
    check(report(s).status == "watching" and plain(report(s)),
        "active evidence is immediately present in the existing saved root as primitives")
    local errorReads, metrics = s.errorReads, s.metricReads
    s.tick(4) -- A newly shown OnUpdate may receive elapsed time accumulated before activation.
    local heapReads = s.heapReads
    for _ = 1, 100 do s.tick(.001) end
    check(s.capture.WatchStatus().spikes == 0 and s.metricReads == metrics
        and s.heapReads == heapReads and s.errorReads == errorReads,
        "initial elapsed is discarded and sub-second ordinary frames do not poll optional metrics")
    local timers, scans = #s.timers, s.scans
    s.capture.Start(5)
    check(#s.timers == timers and s.scans == scans and s.capture.WatchStatus().active,
        "normal endpoint capture cannot start or scan while watching")
    check(s.capture.StartWatch() == false and #s.frames == 1 and s.observerAdds == 3,
        "a duplicate watch cannot steal observer ownership or allocate a second frame")
    s.emit("Events", "UNIT_AURA", 9.9, false)
    s.emit("Events", "UNIT_AURA", 25, true, nil, s.payload)
    s.emit("Scheduler", "inventory", 40, false, nil, { ["inventory.summary"] = true })
    check(s.capture.WatchStatus().callbacks == 2 and s.capture.WatchStatus().spikes == 0,
        "slow callback spans are recorded separately from measured frame gaps")
    s.heap, s.errors = 1152, 5; s.tick(.25)
    check(s.capture.StopWatch("fixture") == true and s.detached(), "stop detaches every observer and the owned frame")
    local r = report(s)
    check(r.durationLimit == 600 and r.thresholdMs == 200 and r.maxFPSBk == "30" and r.scriptProfile == "0",
        "defaults and background throttle/profiler context are retained without changing CVars")
    check(r.diagnosticVersion == 2 and r.periodicHeapSamples == 1,
        "versioned diagnostics disclose coarse heap sampling separately from gap sampling")
    check(r.spikeCount == 1 and #r.spikes == 1 and r.spikes[1].gapMs == 250
        and r.spikes[1].callbackMs == 40 and r.spikes[1].callbackKey == "inventory",
        "a gap records its largest measured overlapping callback as correlation, not summed CPU")
    check(r.spikes[1].intervalCallbacks == 3 and r.spikes[1].busyKeys[1].kind == "Events"
        and r.spikes[1].busyKeys[1].key == "UNIT_AURA" and r.spikes[1].busyKeys[1].callbacks == 2,
        "gap context includes fast callback fan-out rather than only slow callbacks")
    check(r.spikes[1].heapDeltaKB == 128 and r.spikes[1].errorDelta == 3
        and r.spikes[1].profiler.top[1].addon == "fixture" and #r.spikes[1].profiler.top == 1,
        "gap boundaries correlate global heap/error changes and readable top-addon samples")
    check(r.observedCallbacks == 3 and r.callbackCount == 2 and r.callbacks[1].failed == true
        and r.callbacks[2].tokens == "inventory.summary", "callback failures and scheduler tokens remain distinct")
    check(plain(r), "saved watch consists only of bounded primitive data, not closures, payloads or frame objects")
    check(r.interpretation:find("inclusive", 1, true) and r.interpretation:find("global Lua", 1, true),
        "saved interpretation documents overlapping spans and global rather than addon allocation scope")
    local reads, calls = s.metricReads, s.clockReads
    s.tick(100); s.capture.PrintSpikes(); s.capture.Print()
    check(s.metricReads == reads and s.clockReads == calls and s.scans == 0,
        "stopped reports and inherited print neither resume work nor enumerate native frames")
    check(s.capture.StopWatch() == false, "stopping twice is harmless")
    check(s.capture.StartWatch(30, 50), "watch restarts after all resources are released")
    s.capture.Cancel()
    check(s.detached() and not s.capture.WatchStatus().active and #s.frames == 1,
        "existing cancel stops the watch and restart reuses its sole owned frame")
end

do
    local s = harness()
    check(s.capture.StartWatch(100000, 1), "watch accepts bounded explicit configuration")
    s.tick(.01)
    local heldUpdate = s.frames[1]:GetScript("OnUpdate")
    local state = activeState(s)
    check(type(state) == "table", "retained callback closure exposes its state for retention regression")
    for i = 1, 10000 do s.emit("Ticker", "burst" .. i, 12, false, function() return i end, s.payload) end
    local labels = 0; for _ in pairs(state.labels) do labels = labels + 1 end
    check(labels <= 512 and state.labelCount <= 512, "ten thousand distinct callbacks retain at most512 transient function labels")
    for i = 1, 50 do s.tick(.05) end
    check(s.capture.StopWatch("bounded"), "large stress watch stops")
    local r = report(s)
    check(r.durationLimit == 3600 and r.thresholdMs == 50 and r.callbackCount == 10000
        and #r.callbacks == 64 and r.spikeCount == 50 and #r.spikes == 20,
        "ten thousand spans and fifty gaps retain only the bounded callback/gap rings")
    local earliest, latest = math.huge, 0
    for _, row in ipairs(r.callbacks) do earliest, latest = math.min(earliest, row.sequence), math.max(latest, row.sequence) end
    check(earliest == 9937 and latest == 10000 and plain(r), "ring replacement retains the latest records and primitive data only")
    check(s.scans == 0 and #s.timers == 0, "stress capture introduces no endpoint scans or timer objects")
    check(s.metricReads <= 12 and s.heapReads <= 5 and s.errorReads <= 5,
        "fifty repeated gaps sample expensive correlation context at most once per second")
    local unsampled = false
    for _, row in ipairs(r.spikes) do if row.contextSampled == false then unsampled = true end end
    check(unsampled, "throttled gaps explicitly mark that correlation context was not sampled")
    check(state.labels == nil and state.releases == nil and state.frameKeys == nil and state.frameCallbackFn == nil,
        "stopping drops function caches and detach closures even when an expired script closure is retained")
end

do
    local s = harness(); check(s.capture.StartWatch(), "fast callback fan-out watch starts")
    s.tick(.01)
    local state, originalLabels = activeState(s), activeState(s).labelCount
    for i = 1, 3000 do s.emit("Events", "UNIT_AURA", .03, false, function() return i end, s.payload) end
    for _ = 1, 1000 do s.emit("Scheduler", "inventory", .04, false, s.flux.Work.Burst, s.payload) end
    check(state.labelCount == originalLabels and report(s).callbackCount == 0,
        "fast spans do not resolve labels or allocate slow-callback records individually")
    s.tick(.25)
    local gap = report(s).spikes[1]
    check(gap.intervalCallbacks == 4000 and gap.callbackMs == .04 and gap.callbackKind == "Scheduler"
        and gap.callbackKey == "inventory" and gap.callbackLabel == "Flux.Work.Burst",
        "a gap preserves the busiest interval count and hottest sub-threshold callback")
    check(#gap.busyKeys == 2 and gap.busyKeys[1].callbacks == 3000 and gap.busyKeys[1].key == "UNIT_AURA"
        and gap.busyKeys[2].callbacks == 1000 and gap.keyOverflow == 0,
        "busy keys rank callback frequency without treating counts as CPU attribution")
    check(state.frameCallbackFn == nil and state.frameCallbackCount == 0,
        "ordinary frame completion drops transient hottest-function references and interval counts")
    s.tick(.01); s.tick(.25)
    gap = report(s).spikes[2]
    check(gap.intervalCallbacks == 0 and gap.callbackMs == 0 and gap.callbackLabel == nil and #gap.busyKeys == 0,
        "a later quiet gap does not inherit an earlier callback or fan-out")
    s.capture.StopWatch("fan-out")
    check(plain(report(s)) and s.detached(), "fast fan-out persists no callback functions or opaque arguments")
end

do
    local s = harness(); check(s.capture.StartWatch(), "unique-key fan-out watch starts")
    s.tick(.01)
    for i = 1, 10000 do s.emit("Ticker", "key" .. i, .02, false, nil, s.payload) end
    local state, retainedKeys = activeState(s), 0
    for _, keys in pairs(state.frameKeys) do for _ in pairs(keys) do retainedKeys = retainedKeys + 1 end end
    check(retainedKeys == 64 and state.frameKeyOverflow == 9936,
        "ten thousand distinct fast keys retain64 metadata slots and disclose overflow")
    s.tick(.25)
    local gap = report(s).spikes[1]
    check(gap.intervalCallbacks == 10000 and gap.keyOverflow == 9936 and #gap.busyKeys == 4
        and report(s).callbackCount == 0, "saved gap keeps four bounded key summaries without slow-record inflation")
    s.capture.StopWatch("keys")
end

do
    local s = harness(); check(s.capture.StartWatch(), "key and token attribution watch starts")
    s.tick(.01)
    s.emit("Scheduler", "inventory", 20, false, nil, { ["inventory.summary"] = true })
    s.emit("Events", "UNIT_AURA", 20, false, nil, { ["unrelated.event"] = true })
    s.tick(.25)
    local gap = report(s).spikes[1]
    check(gap.callbackKind == "Scheduler" and gap.callbackKey == "inventory"
        and gap.callbackTokens == "inventory.summary",
        "equal spans from the same function do not overwrite the hottest key's token attribution")
    s.emit("Ticker", -3, .03, false)
    s.tick(.25); gap = report(s).spikes[2]
    check(gap.callbackKey == -3 and gap.busyKeys[1].key == "-3" and gap.callbackTokens == nil,
        "finite negative ticker keys remain valid metadata without inheriting another interval's tokens")
    s.capture.StopWatch("key-attribution")
end

do
    local s = harness(); check(s.capture.StartWatch(), "pre-gap heap watch starts")
    s.tick(.01); s.heap = 2048
    for _ = 1, 10 do s.tick(.1) end
    local state = activeState(s)
    check(report(s).periodicHeapSamples == 1 and state.lastHeapKB == 2048,
        "quiet active frames retain a single global heap sample about once per second")
    s.heap = 1024; s.tick(.25)
    local gap = report(s).spikes[1]
    check(gap.preHeapKB == 2048 and gap.preHeapAgeSeconds >= .249 and gap.preHeapAgeSeconds <= .251
        and gap.shortHeapDeltaKB == -1024 and gap.heapDeltaKB == 0,
        "recent heap drops remain distinct from broad start-to-gap heap deltas")
    check(report(s).heapSamples == nil and type(state.lastHeapKB) == "number" and type(state.lastHeapAt) == "number",
        "coarse heap context retains scalars rather than a growing heap time series")
    s.capture.StopWatch("heap")
end

for _, badHeap in ipairs({ "secret", "nan", "infinite", "negative", "error" }) do
    local s = harness({ optional = badHeap }); check(s.capture.StartWatch(), "unavailable coarse heap watch starts: " .. badHeap)
    s.tick(.01); for _ = 1, 300 do s.tick(.01) end
    local beforeStopReads = s.heapReads
    check(beforeStopReads <= 4 and report(s).periodicHeapSamples <= 3,
        "failed or restricted coarse reads keep a one-second attempt cadence: " .. badHeap)
    s.tick(.25)
    local gap = report(s).spikes[1]
    check(gap.preHeapKB == nil and gap.preHeapAgeSeconds == nil and gap.shortHeapDeltaKB == nil,
        "invalid coarse values cannot become pre-gap numeric evidence: " .. badHeap)
    s.capture.StopWatch("unavailable-heap")
    check(plain(report(s)), "restricted coarse samples never enter saved data: " .. badHeap)
end

do
    local s = harness(); check(s.capture.StartWatch(), "stale coarse context watch starts")
    s.tick(.01); s.heap = s.secret
    for _ = 1, 100 do s.tick(.01) end
    s.tick(.25)
    local gap = report(s).spikes[1]
    check(gap.preHeapKB == 1024 and gap.preHeapAgeSeconds > 1 and gap.heapKB == nil
        and gap.shortHeapDeltaKB == nil,
        "a failed fresh read preserves the older sample with its real age and omits a new delta")
    s.emit("Events", s.secret, .02, false, nil, s.payload)
    s.tick(.25)
    gap = report(s).spikes[2]
    check(gap.callbackKey == "unavailable" and gap.busyKeys[1].key == "unavailable",
        "secret callback keys become unavailable without entering numeric or string summaries")
    s.capture.StopWatch("stale-heap")
    check(plain(report(s)), "stale and restricted context remains primitive when saved")
end

do
    local s = harness(); check(s.capture.StartWatch(), "bounded token watch starts")
    local visits = 0
    local tokens = setmetatable({}, { __pairs = function()
        return function()
            visits = visits + 1
            if visits <= 10000 then return visits, true end
        end
    end })
    s.emit("Scheduler", "inventory", 20, false, nil, tokens)
    check(visits <= 16, "unrecognized scheduler token keys have an independent visit budget")
    local observed = report(s).observedCallbacks
    for _, ms in ipairs({0 / 0, math.huge, -1, s.secret}) do s.emit("Events", "invalid", ms, false) end
    check(report(s).observedCallbacks == observed, "nonfinite, negative and secret callback times are omitted")
    s.capture.StopWatch("tokens")
end

do
    local s = harness()
    check(s.capture.StartWatch(), "logout watch starts")
    s.tick(.01); s.tick(.25)
    s.frames[1]:GetScript("OnEvent")(s.frames[1], "PLAYER_LOGOUT")
    check(report(s).status == "logout" and report(s).spikeCount == 1 and s.detached(),
        "logout finalizes active evidence and unregisters every diagnostic resource")
    report(s).status = "watching" -- Reproduce a persisted report from an interrupted client.
    s.capture.PrintSpikes()
    check(table.concat(s.output, "\n"):find("interrupted", 1, true),
        "a reloaded unfinished report is labeled interrupted rather than currently active")
end

for _, kind in ipairs({ "Events", "Ticker", "Scheduler" }) do
    local s = harness({ conflict = kind })
    check(s.capture.StartWatch() == false and not s.capture.WatchStatus().active,
        "conflicting " .. kind .. " observer rejects watch startup")
    check(s.detached() and #s.frames == 0 and s.observerReleases == s.observerAdds - 1,
        "partial observer attachment rolls back without touching the conflicting owner: " .. kind)
end

for _, mode in ipairs({ "missing", "secret", "error", "malformed", "nan", "infinite", "negative" }) do
    local s = harness({ optional = mode })
    check(s.capture.StartWatch(30, 200), "optional API failures do not block watch: " .. mode)
    s.tick(.01); s.tick(.25); s.capture.StopWatch("optional")
    local r = report(s)
    check(r.heapBeforeKB == nil and r.heapAfterKB == nil and r.errorsBefore == nil and r.errorsAfter == nil
        and r.spikes[1].profiler == nil and r.spikes[1].heapKB == nil and r.spikes[1].errors == nil,
        "missing/secret/error/malformed optional samples are omitted: " .. mode)
    check(plain(r) and s.detached(), "restricted optional samples do not enter saved state or leave work: " .. mode)
end

do
    for _, unavailable in ipairs({ {secretTable = true}, {inaccessible = true}, false }) do
        local s = harness({ saved = unavailable })
        if unavailable == false then s.env.FluxPerfCaptureDB = false end
        check(s.capture.StartWatch() == false and s.env.FluxPerfCaptureDB == unavailable
            and #s.frames == 0 and s.observerAdds == 0,
            "unreadable or malformed saved diagnostic roots are preserved without attaching work")
    end
    for _, missing in ipairs({"CreateFrame", "GetTime"}) do
        local s = harness(); s.env[missing] = false
        check(s.capture.StartWatch() == false and #s.frames == 0 and s.observerAdds == 0,
            "missing required runtime capability rejects watch startup: " .. missing)
    end
end

do
    local previous = { sentinel = "preserve", seconds = 5, client = "fixture", version = "1", build = "1",
        scriptProfile = "0", fpsAverage = 120, fpsMin = 100, addonMsPerSecond = 0,
        liveBefore = 0, liveAfter = 0, subscribers = {}, cvars = "", frames = {}, functions = {}, passes = {} }
    local s = harness({ saved = previous })
    check(s.capture.StartWatch(1, 100000), "small watch configuration is normalized")
    s.tick(.01); s.tick(30)
    local r = report(s)
    check(s.env.FluxPerfCaptureDB == previous and previous.sentinel == "preserve" and previous.seconds == 5
        and r.durationLimit == 30 and r.thresholdMs == 5000 and r.status == "expired" and s.detached(),
        "expiry clamps parameters, stops work and preserves prior capture/custom fields")
    s.capture.Print()
    check(table.concat(s.output, "\n"):find("FPS samples", 1, true), "normal saved capture remains printable beside watch evidence")
    s.capture.Start(5)
    check(#s.timers == 2 and s.capture.StartWatch() == false and #s.frames == 1,
        "an active endpoint capture excludes watch startup")
    s.now = s.now + 5; s.timers[2].callback()
    check(s.env.FluxPerfCaptureDB.spikeWatch == r, "later endpoint capture preserves the previous bounded watch report")
end

do
    local s = harness({ noObservers = true })
    check(s.capture.StartWatch(30, 200), "frame-gap-only watch remains available without observer services")
    s.tick(.01); s.tick(.25); s.capture.StopWatch("frame-only")
    local r = report(s)
    check(r.spikeCount == 1 and r.callbackCount == 0 and not r.coverage.Events
        and not r.coverage.Ticker and not r.coverage.Scheduler,
        "missing Flux coverage is explicit rather than fabricated attribution")
end

print(string.format("spike watch: %d checks passed; 10,000 spans retain64 callback records and20 gaps; native attribution unverified", checks))
