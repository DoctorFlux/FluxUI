-- On-demand CPU deltas. No hooks, wrappers, frame scans or tickers while idle.
-- Includes Blizzard frames: an embedded map can cost CPU outside _FluxUI's bill.
local addonName, ns = ...
local Flux = ns.Flux
local Capture = {}
Flux.PerfCapture = Capture
local active
local watch, watchFrame
local PREFIX = "|cff00ccffFluxPerf|r"
local SCRIPTS = { "OnUpdate", "OnEvent" }

local function PlainNumber(v)
    return type(v) == "number" and not (issecretvalue and issecretvalue(v))
end

local function ReadableTable(value)
    if type(value) ~= "table" then return false end
    if issecretvalue and issecretvalue(value) then return false end
    if issecrettable and issecrettable(value) then return false end
    if canaccesstable and not canaccesstable(value) then return false end
    return true
end

local function ReadCPU(api, object, children)
    if type(api) ~= "function" then return 0, 0 end
    local ok, ms, calls = pcall(api, object, children)
    if not ok or not PlainNumber(ms) then return 0, 0 end
    return ms, PlainNumber(calls) and calls or 0
end

local function ReadRecent(api, ...)
    if type(api) ~= "function" then return end
    local ok, value = pcall(api, ...)
    if ok and PlainNumber(value) then return value end
end

local function Method(object, name)
    if type(object) == "table" and not ReadableTable(object) then return nil end
    local fn = object and object[name]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object)
    if ok and not (issecretvalue and issecretvalue(value)) then return value end
end

local function Label(frame, index)
    local name = Method(frame, "GetName") or Method(frame, "GetDebugName")
    if type(name) == "string" and name ~= "" then return name end
    local parent = Method(frame, "GetParent")
    local parentName = parent and Method(parent, "GetName")
    return (parentName or "anonymous") .. "/" .. (Method(frame, "GetObjectType") or "Frame") .. "#" .. index
end

local function AddFunction(snapshot, fn, label)
    if type(fn) ~= "function" then return end
    if issecretvalue and issecretvalue(fn) then return end
    if snapshot.functions[fn] then return snapshot.functions[fn] end
    local ms, calls = ReadCPU(GetFunctionCPUUsage, fn, true)
    snapshot.functions[fn] = { label = label, ms = ms, calls = calls }
    return snapshot.functions[fn]
end

local function FrameState(frame)
    if not frame then return "missing" end
    if Method(frame, "IsForbidden") then return "forbidden" end
    return "shown=" .. tostring(Method(frame, "IsShown")) .. "/visible=" .. tostring(Method(frame, "IsVisible"))
end

local function Snapshot(atEnd)
    local snap = { frames = {}, functions = {}, passes = {}, liveUpdates = 0, subscribers = {},
        presentation = { frames = 0, visibleFrames = 0, visibleRegions = 0, models = {} } }
    local function Boundary()
        if UpdateAddOnCPUUsage then pcall(UpdateAddOnCPUUsage) end
        snap.addonMs = ReadCPU(GetAddOnCPUUsage, addonName)
        snap.time = GetTime()
    end
    -- Exclude the expensive endpoint frame enumerations from addon CPU/time.
    if atEnd then Boundary() end
    -- Module functions also cover timer work, which GetFrameCPUUsage misses.
    -- Skip object graphs (frames, pools, button arrays, namespace cycles).
    local seen, aliases = {}, {}
    local function Walk(tbl, path, depth)
        if not ReadableTable(tbl) or seen[tbl] or depth > 3 then return end
        if rawget(tbl, 0) or tbl.GetObjectType then aliases[tbl] = path; return end
        seen[tbl] = true
        for key, value in pairs(tbl) do
            if type(key) == "string" and key ~= "ns" and key ~= "PerfCapture" then
                local label = path .. "." .. key
                if type(value) == "function" then
                    AddFunction(snap, value, label)
                elseif type(value) == "table" then
                    Walk(value, label, depth + 1)
                end
            end
        end
    end
    Walk(Flux, "Flux", 0)
    Walk(ns.UnitFrames, "UnitFrames", 0)
    -- The native dispatcher can dominate while its registered callbacks are
    -- absent from addon namespaces/frame scripts. Read its table only during
    -- requested endpoint scans; never hook, invoke or replace the callbacks.
    local registry = _G.EventRegistry
    local callbacks = ReadableTable(registry) and rawget(registry, "onUpdateCallbacksByOwner")
    if not ReadableTable(callbacks) then callbacks = nil end
    local registryNames = {}
    for key, value in pairs(_G) do
        if callbacks and type(key) == "string" and ReadableTable(value) then
            local callback = callbacks[value]
            if type(callback) == "function" and not (issecretvalue and issecretvalue(callback))
                and not registryNames[value] then registryNames[value] = key end
        end
        if type(key) == "string" and (key:match("^Flux") or key:match("^UF_"))
            and (type(value) == "table" or type(value) == "userdata") then
            aliases[value] = key
        end
        if type(key) == "string" and key:match("^Flux") and key ~= "FluxPerfCaptureDB" then
            if type(value) == "table" then Walk(value, key, 1)
            elseif type(value) == "function" then AddFunction(snap, value, key) end
        end
    end
    if callbacks then
        local index = 0
        for owner, callback in pairs(callbacks) do
            index = index + 1
            if not (issecretvalue and issecretvalue(owner)) then
                local ownerName = registryNames[owner] or ("anonymous#" .. index)
                local row = AddFunction(snap, callback, "EventRegistry:" .. ownerName)
                if row then
                    if registryNames[owner] and row.label:find("EventRegistry:", 1, true) == 1 then
                        row.label = "EventRegistry:" .. ownerName
                    end
                    row.registryOwners = row.registryOwners or {}
                    if #row.registryOwners < 5 then row.registryOwners[#row.registryOwners + 1] = ownerName end
                end
            end
        end
    end
    if Flux.Ticker and Flux.Ticker.GetSubscribers then
        for key, fn in pairs(Flux.Ticker.GetSubscribers()) do
            snap.subscribers[#snap.subscribers + 1] = tostring(key)
            AddFunction(snap, fn, "Ticker:" .. tostring(key))
        end
        table.sort(snap.subscribers)
    end
    local i = 0
    local frame = EnumerateFrames and EnumerateFrames()
    while frame do
        i = i + 1
        -- Forbidden frames cannot be inspected even by a diagnostic.
        if (type(frame) ~= "table" or ReadableTable(frame)) and not Method(frame, "IsForbidden") then
            local ms, calls = ReadCPU(GetFrameCPUUsage, frame, false)
            local label = aliases[frame] or Label(frame, i)
            -- This is the frame's creation location, not its script closure's
            -- definition. Some clients omit it or restrict ObjectDebug reads.
            local creationSource = Method(frame, "GetSourceLocation")
            if type(creationSource) ~= "string" or creationSource == "" then creationSource = nil end
            snap.frames[frame] = { label = label, ms = ms, calls = calls, creationSource = creationSource }
            local visible = Method(frame, "IsVisible")
            local kind = Method(frame, "GetObjectType")
            snap.presentation.frames = snap.presentation.frames + 1
            if visible then
                snap.presentation.visibleFrames = snap.presentation.visibleFrames + 1
                local regions = Method(frame, "GetNumRegions")
                if PlainNumber(regions) then snap.presentation.visibleRegions = snap.presentation.visibleRegions + regions end
                if type(kind) == "string" and kind:find("Model", 1, true) then
                    local alpha = Method(frame, "GetEffectiveAlpha")
                    snap.presentation.models[#snap.presentation.models + 1] = {
                        label = label, kind = kind, creationSource = creationSource,
                        alpha = PlainNumber(alpha) and alpha or nil,
                    }
                end
            end
            for _, script in ipairs(SCRIPTS) do
                local ok, fn = pcall(frame.GetScript, frame, script)
                if ok and type(fn) == "function" then
                    local row = AddFunction(snap, fn, label .. ":" .. script)
                    if script == "OnUpdate" then
                        -- A native script function can belong to several frames.
                        -- Its CPU total cannot identify which owner did the work.
                        row.ownerCount = (row.ownerCount or 0) + 1
                        row.visibleOwners = (row.visibleOwners or 0) + (Method(frame, "IsVisible") and 1 or 0)
                        row.owners = row.owners or {}
                        if #row.owners < 5 then
                            row.owners[#row.owners + 1] = label .. " (" .. FrameState(frame) .. ")"
                            row.ownerSources = row.ownerSources or {}
                            row.ownerSources[#row.ownerSources + 1] = { label = label, creationSource = creationSource }
                        end
                    end
                    if script == "OnUpdate" and Method(frame, "IsVisible") then
                        snap.liveUpdates = snap.liveUpdates + 1
                    end
                end
            end
        end
        frame = EnumerateFrames(frame)
    end
    if Flux.Perf and Flux.Perf.Snapshot then
        local p = Flux.Perf.Snapshot()
        for key, ms in pairs(p.passMs or {}) do
            snap.passes[key] = { label = key, ms = ms, calls = (p.passCalls or {})[key] or 0 }
        end
    end
    snap.uiState = {
        worldMap = FrameState(_G.WorldMapFrame), battlefieldMap = FrameState(_G.BattlefieldMapFrame),
        character = FrameState(_G.CharacterFrame),
        fluxTab = Method(_G.FluxWindowFrame, "GetActiveTab") or "unavailable",
    }
    if not atEnd then Boundary() end
    return snap
end

local function Rank(before, after, seconds, newCountersStartAtZero)
    local rows = {}
    for key, row in pairs(after) do
        local old = before[key]
        if not old and newCountersStartAtZero then old = { ms = 0, calls = 0 } end
        -- A newly discovered function may have lifetime CPU from before this
        -- capture. Do not mislabel that as a measured interval delta.
        if old then
            local ms, calls = row.ms - old.ms, row.calls - old.calls
            if ms > 0 and calls >= 0 then
                rows[#rows + 1] = { label = row.label, ms = ms, calls = calls, msPerSecond = ms / seconds,
                    ownerCount = row.ownerCount, visibleOwners = row.visibleOwners, owners = row.owners,
                    creationSource = row.creationSource, ownerSources = row.ownerSources,
                    registryOwners = row.registryOwners }
            end
        end
    end
    table.sort(rows, function(a, b) return a.ms > b.ms end)
    while #rows > 50 do rows[#rows] = nil end
    return rows
end

function Capture.Print()
    local r = _G.FluxPerfCaptureDB
    if not r then print(PREFIX, "No capture yet. /fluxperf capture 20") return end
    if not PlainNumber(r.seconds) then Capture.PrintSpikes() return end
    print(PREFIX, string.format("%s %s (%s) build %s | spellRanks=%s | %.1fs | scriptProfile=%s",
        r.client, r.version or "?", r.gameType or "?", r.build, r.spellRanks or "?", r.seconds, r.scriptProfile))
    print(PREFIX, string.format("FPS samples: avg %.1f / min %.1f | Flux CPU %.2f ms/s", r.fpsAverage, r.fpsMin, r.addonMsPerSecond))
    print(PREFIX, string.format("Visible OnUpdates (all addons): %d -> %d", r.liveBefore, r.liveAfter))
    print(PREFIX, "Flux ticker subscribers: " .. table.concat(r.subscribers, ", "))
    print(PREFIX, "CVars: " .. r.cvars)
    if r.uiAfter then
        print(PREFIX, "Map state: WorldMap " .. r.uiAfter.worldMap .. "; BattlefieldMap " .. r.uiAfter.battlefieldMap
            .. "; Flux tab=" .. r.uiAfter.fluxTab .. "; Character " .. r.uiAfter.character)
    end
    if r.presentationAfter then
        local p = r.presentationAfter
        print(PREFIX, string.format("Presentation: %d visible frames; %d regions on visible frames; %d visible model frames (alpha recorded separately)",
            p.visibleFrames, p.visibleRegions, #p.models))
    end
    if r.recentProfiler then
        local p = r.recentProfiler
        print(PREFIX, string.format("Recent profiler samples (ms/tick): application %.3f; all addons %.3f; Flux %.3f",
            p.applicationMs, p.overallMs, p.addonMs))
    end
    for _, section in ipairs({ "frames", "functions", "passes" }) do
        print(PREFIX, section .. " (inclusive; rows overlap, do not sum):")
        for i = 1, math.min(12, #r[section]) do
            local row = r[section][i]
            local shared = row.ownerCount
                and string.format(" [script owners: %d frames, %d visible]", row.ownerCount, row.visibleOwners or 0) or ""
            local source = row.creationSource
            if not source and row.ownerCount == 1 and row.ownerSources and row.ownerSources[1] then
                source = row.ownerSources[1].creationSource
            end
            local created = source and (" [owner created at: " .. source .. "]") or ""
            local registered = row.registryOwners and (" [registry owners: " .. table.concat(row.registryOwners, ", ") .. "]") or ""
            print(string.format("  %7.2f ms/s  %7d calls  %s%s%s%s", row.msPerSecond, row.calls, row.label, shared, created, registered))
        end
    end
    print(PREFIX, "Script CPU includes direct method calls; registered-owner visibility does not identify every caller.")
    print(PREFIX, "Creation sources identify frames, not callback definitions or every caller.")
    print(PREFIX, "CPU profiling adds overhead; use scriptProfile=0 for final FPS comparison. Native rendering is not measured.")
end

function Capture.Cancel()
    if watch then Capture.StopWatch("cancelled") end
    if not active then return end
    if active.timer then active.timer:Cancel() end
    if active.sampler then active.sampler:Cancel() end
    active.before = nil
    active.timer, active.sampler = nil, nil
    active = nil
end

function Capture.Start(seconds)
    if watch then print(PREFIX, "Spike watch is running. /fluxperf watch off") return end
    if active then print(PREFIX, "Capture already running. /fluxperf cancel") return end
    if not (GetTime and C_Timer and C_Timer.NewTimer and C_Timer.NewTicker) then
        print(PREFIX, "This client has no capture timer API.")
        return
    end
    seconds = tonumber(seconds) or 20
    if seconds ~= seconds then seconds = 20 end
    seconds = math.max(5, math.min(120, seconds))
    local state = { fpsSum = 0, fpsCount = 0, fpsMin = math.huge }
    local function Sample()
        local fps = GetFramerate and GetFramerate()
        if PlainNumber(fps) then
            state.fpsSum = state.fpsSum + fps
            state.fpsCount = state.fpsCount + 1
            state.fpsMin = math.min(state.fpsMin, fps)
        end
        local profiler = _G.C_AddOnProfiler
        local enums = _G.Enum
        local metrics = ReadableTable(enums) and enums.AddOnProfilerMetric
        local metric = ReadableTable(metrics) and metrics.RecentAverageTime
        if ReadableTable(profiler) and PlainNumber(metric) then
            local app = ReadRecent(profiler.GetApplicationMetric, metric)
            local overall = ReadRecent(profiler.GetOverallMetric, metric)
            local addon = ReadRecent(profiler.GetAddOnMetric, addonName, metric)
            if app and overall and addon then
                local p = state.recentProfiler
                if not p then p = { count = 0, applicationMs = 0, overallMs = 0, addonMs = 0 }; state.recentProfiler = p end
                p.count = p.count + 1
                p.applicationMs, p.overallMs, p.addonMs = p.applicationMs + app, p.overallMs + overall, p.addonMs + addon
            end
        end
    end
    local function CVar(name)
        local get = (C_CVar and C_CVar.GetCVar) or GetCVar
        if not get then return "unavailable" end
        local ok, v = pcall(get, name)
        return ok and tostring(v) or "unavailable"
    end
    print(PREFIX, string.format("Capturing %.0fs; keep the camera/scene steady. No features are disabled.", seconds))
    if CVar("scriptProfile") ~= "1" then
        print(PREFIX, "For CPU rankings: /console scriptProfile 1 then /reload. Current capture still records FPS and named passes.")
    end
    state.before = Snapshot()
    active = state
    state.sampler = C_Timer.NewTicker(1, Sample)
    state.timer = C_Timer.NewTimer(seconds, function()
        state.sampler:Cancel()
        Sample()
        local after = Snapshot(true)
        local elapsed = math.max(0.001, after.time - state.before.time)
        local client = Flux.Client or {}
        local version, build = GetBuildInfo()
        local cvars = {}
        for _, name in ipairs({ "maxFPS", "maxFPSBk", "maxFPSLoading", "vsync", "targetFPS", "useTargetFPS", "gxMaxFrameLatency" }) do
            cvars[#cvars + 1] = name .. "=" .. CVar(name)
        end
        local recent = state.recentProfiler
        if recent then
            recent.applicationMs, recent.overallMs, recent.addonMs = recent.applicationMs / recent.count,
                recent.overallMs / recent.count, recent.addonMs / recent.count
        end
        local previous = _G.FluxPerfCaptureDB
        local previousWatch = ReadableTable(previous) and previous.spikeWatch or nil
        _G.FluxPerfCaptureDB = {
            spikeWatch = previousWatch,
            inputDebug = ReadableTable(previous) and previous.inputDebug or nil,
            editModeDebug = ReadableTable(previous) and previous.editModeDebug or nil,
            -- expansion + version + gameType: live Midnight and Forever both use _retail_.
            client = client.expansion or (client.isCamelot and "Forever" or (client.isRetail and "Midnight"
                or (client.isEra and "Classic Era" or (client.isTBC and "Anniversary" or tostring(WOW_PROJECT_ID))))),
            gameType = client.gameType or (client.isCamelot and "camelot" or (client.isAnyClassic and "classic" or "live")),
            spellRanks = (Flux.Cap and Flux.Cap.supportsPerRankSpellBarFeatures) and "1" or "0",
            version = version, build = tostring(build), scriptProfile = CVar("scriptProfile"), seconds = elapsed,
            capturedAt = date and date("%Y-%m-%d %H:%M:%S") or nil,
            fpsAverage = state.fpsCount > 0 and state.fpsSum / state.fpsCount or 0,
            fpsMin = state.fpsCount > 0 and state.fpsMin or 0,
            addonMsPerSecond = math.max(0, after.addonMs - state.before.addonMs) / elapsed,
            liveBefore = state.before.liveUpdates, liveAfter = after.liveUpdates,
            subscribers = after.subscribers, cvars = table.concat(cvars, " "),
            uiBefore = state.before.uiState, uiAfter = after.uiState,
            presentationBefore = state.before.presentation, presentationAfter = after.presentation,
            recentProfiler = recent,
            frames = Rank(state.before.frames, after.frames, elapsed),
            functions = Rank(state.before.functions, after.functions, elapsed),
            passes = Rank(state.before.passes, after.passes, elapsed, true),
        }
        -- Timer callbacks can retain their state after cancellation/completion.
        -- Keep the compact report, release the full frame/function snapshot.
        state.before = nil
        state.timer, state.sampler = nil, nil
        active = nil
        Capture.Print()
    end)
end

-- Optional bounded watch. A frame gap is not automatically addon CPU: loading,
-- rendering, background throttling and other addons can also delay a frame.
local WATCH_SPIKES, WATCH_CALLBACKS, WATCH_LABELS = 20, 64, 512

local function WatchNumber(value)
    return PlainNumber(value) and value == value and value >= 0 and value < math.huge
end

local function WatchRead(api, ...)
    local value = ReadRecent(api, ...)
    if WatchNumber(value) then return value end
end

local function PublicString(value)
    return not (issecretvalue and issecretvalue(value)) and type(value) == "string"
end

local function WatchCVar(name)
    local get = (C_CVar and C_CVar.GetCVar) or GetCVar
    if type(get) ~= "function" then return "unavailable" end
    local ok, value = pcall(get, name)
    return ok and PublicString(value) and value or "unavailable"
end

local function HeapKB()
    return WatchRead(collectgarbage, "count")
end

local function ErrorCount()
    local bugs = _G.BugTabs
    if ReadableTable(bugs) then return WatchRead(bugs.GetSessionCounts) end
end

local function PushWatchRow(rows, limit, count)
    local index = (count - 1) % limit + 1
    local row = rows[index]
    if not row then row = {}; rows[index] = row end
    for key in pairs(row) do row[key] = nil end
    return row
end

local function FunctionLabels()
    local labels, seen, budget, count = {}, {}, 4096, 0
    local function Walk(tbl, path, depth)
        if budget <= 0 or depth > 4 or not ReadableTable(tbl) or seen[tbl] then return end
        if rawget(tbl, 0) or rawget(tbl, "GetObjectType") then return end
        seen[tbl] = true
        for key, value in pairs(tbl) do
            budget = budget - 1
            if budget < 0 then break end
            if PublicString(key) and key:match("^[%a_][%w_]*$") then
                local lower = key:lower()
                if lower ~= "ns" and lower ~= "profile" and lower ~= "history"
                    and not lower:find("saved", 1, true) and not lower:find("db", 1, true) then
                    local name = path .. "." .. key
                    if type(value) == "function" and not labels[value] and count < WATCH_LABELS then
                        labels[value], count = name, count + 1
                    elseif type(value) == "table" then Walk(value, name, depth + 1) end
                end
            end
        end
    end
    Walk(Flux, "Flux", 0)
    Walk(ns.UnitFrames, "UnitFrames", 0)
    Walk(_G.FluxInv, "FluxInv", 0)
    return labels, count
end

local function CallbackLabel(state, fn, kind, key)
    if issecretvalue and issecretvalue(fn) then return kind .. ":unavailable" end
    local label = state.labels[fn]
    if label then return label end
    -- Lua debug metadata, when supplied by the client, concerns the callback
    -- function only. No event arguments, frame graphs or actor data are read.
    if type(debug) == "table" and type(debug.getinfo) == "function" then
        local ok, info = pcall(debug.getinfo, fn, "S")
        if ok and ReadableTable(info) and PublicString(info.short_src) and PlainNumber(info.linedefined) then
            label = info.short_src:sub(1, 180) .. ":" .. info.linedefined
        end
    end
    if not label then label = kind .. ":" .. key .. ":unmapped" end
    if state.labelCount < WATCH_LABELS then
        state.labels[fn], state.labelCount = label, state.labelCount + 1
    end
    return label
end

local function ProfilerTick()
    local api = _G.C_AddOnProfiler
    local enums = _G.Enum
    local metrics = ReadableTable(enums) and enums.AddOnProfilerMetric
    local metric = ReadableTable(metrics) and metrics.LastTime
    if not ReadableTable(api) or not PlainNumber(metric) then return end
    local result = {
        applicationMs = WatchRead(api.GetApplicationMetric, metric),
        overallMs = WatchRead(api.GetOverallMetric, metric),
        addonMs = WatchRead(api.GetAddOnMetric, addonName, metric), top = {},
    }
    if type(api.GetTopKAddOnsForMetric) == "function" then
        local ok, rows = pcall(api.GetTopKAddOnsForMetric, metric, 5)
        if ok and ReadableTable(rows) then
            for i = 1, math.min(5, #rows) do
                local row = rows[i]
                if ReadableTable(row) and PublicString(row.addOnName) and WatchNumber(row.metricValue) then
                    result.top[#result.top + 1] = { addon = row.addOnName, ms = row.metricValue }
                end
            end
        end
    end
    if result.applicationMs or result.overallMs or result.addonMs or #result.top > 0 then return result end
end

local function WatchClock()
    local ms = debugprofilestop and debugprofilestop()
    if WatchNumber(ms) then return ms end
end

local function AddWatchCost(state, started)
    local ended = WatchClock()
    if started and ended and ended >= started then
        local ms = ended - started
        state.report.diagnosticMs = state.report.diagnosticMs + ms
        state.report.diagnosticPeakMs = math.max(state.report.diagnosticPeakMs, ms)
    end
end

local function ObserveWatch(state, kind, key, fn, ms, failed, tokens)
    if watch ~= state or not WatchNumber(ms) then return end
    local r = state.report
    r.observedCallbacks = r.observedCallbacks + 1
    state.frameCallbackCount = state.frameCallbackCount + 1
    key = (PublicString(key) or (PlainNumber(key) and key == key and key > -math.huge and key < math.huge)) and key or "unavailable"
    local keys = state.frameKeys[kind]
    if keys[key] then keys[key] = keys[key] + 1
    elseif state.frameKeyCount < 64 then
        keys[key], state.frameKeyCount = 1, state.frameKeyCount + 1
    else state.frameKeyOverflow = state.frameKeyOverflow + 1 end
    local hottest = ms > state.frameCallbackMs
    if hottest then
        state.frameCallbackMs, state.frameCallbackFn = ms, fn
        state.frameCallbackKey, state.frameCallbackKind = key, kind
        state.frameCallbackTokens = nil
    end
    if ms < 10 then return end
    local started = WatchClock()
    key = PublicString(key) and key or (PlainNumber(key) and tostring(key) or "unavailable")
    r.callbackCount = r.callbackCount + 1
    local row = PushWatchRow(r.callbacks, WATCH_CALLBACKS, r.callbackCount)
    row.sequence, row.at, row.kind, row.key = r.callbackCount, GetTime() - state.started, kind, key
    row.ms, row.failed = ms, failed == true
    row.label = CallbackLabel(state, fn, kind, key)
    if ReadableTable(tokens) then
        local names, visited = {}, 0
        for token in pairs(tokens) do
            visited = visited + 1
            if PublicString(token) then names[#names + 1] = token:sub(1, 80) end
            if #names == 4 or visited == 16 then break end
        end
        row.tokens = table.concat(names, ",")
    end
    if hottest then
        state.frameCallbackTokens = row.tokens
    end
    AddWatchCost(state, started)
end

function Capture.StopWatch(reason)
    local state = watch
    if not state then return false end
    watch = nil
    watchFrame:SetScript("OnUpdate", nil)
    watchFrame:SetScript("OnEvent", nil)
    watchFrame:UnregisterEvent("PLAYER_LOGOUT")
    watchFrame:Hide()
    for _, release in ipairs(state.releases) do release() end
    local r = state.report
    r.status, r.seconds = reason or "stopped", math.max(0, GetTime() - state.started)
    r.heapAfterKB, r.errorsAfter = HeapKB(), ErrorCount()
    state.labels, state.releases, state.frameKeys, state.frameCallbackFn = nil, nil, nil, nil
    local db = _G.FluxPerfCaptureDB
    if db == nil then db = {}; _G.FluxPerfCaptureDB = db end
    if ReadableTable(db) then db.spikeWatch = r end
    print(PREFIX, string.format("Spike watch stopped: %d frame gaps; %d slow callbacks. /fluxperf spikes", r.spikeCount, r.callbackCount))
    return true
end

function Capture.WatchStatus()
    if not watch then return { active = false } end
    return { active = true, secondsRemaining = math.max(0, watch.deadline - GetTime()),
        spikes = watch.report.spikeCount, callbacks = watch.report.callbackCount }
end

function Capture.StartWatch(seconds, thresholdMs)
    if watch or active then print(PREFIX, "A capture/watch is already running. /fluxperf cancel") return false end
    if type(CreateFrame) ~= "function" or type(GetTime) ~= "function" then
        print(PREFIX, "Spike watch is unavailable on this client.") return false
    end
    local db = _G.FluxPerfCaptureDB
    if db ~= nil and not ReadableTable(db) then print(PREFIX, "Saved diagnostic data is unavailable; it was preserved.") return false end
    seconds, thresholdMs = tonumber(seconds), tonumber(thresholdMs)
    seconds = PlainNumber(seconds) and seconds == seconds and math.max(30, math.min(3600, seconds)) or 600
    thresholdMs = PlainNumber(thresholdMs) and thresholdMs == thresholdMs and math.max(50, math.min(5000, thresholdMs)) or 200
    local version, build = GetBuildInfo()
    local state = { started = GetTime(), releases = {}, frameCallbackMs = 0,
        frameCallbackCount = 0, frameKeyCount = 0, frameKeyOverflow = 0,
        frameKeys = { Events = {}, Ticker = {}, Scheduler = {} },
        report = { mode = "spike-watch", diagnosticVersion = 2, status = "watching", version = version, build = tostring(build),
            durationLimit = seconds, thresholdMs = thresholdMs, scriptProfile = WatchCVar("scriptProfile"),
            maxFPS = WatchCVar("maxFPS"), maxFPSBk = WatchCVar("maxFPSBk"),
            capturedAt = date and date("%Y-%m-%d %H:%M:%S") or nil,
            heapBeforeKB = HeapKB(), errorsBefore = ErrorCount(),
            spikeCount = 0, callbackCount = 0, observedCallbacks = 0, frameCount = 0,
            peakFrameMs = 0, diagnosticMs = 0, diagnosticPeakMs = 0, periodicHeapSamples = 0, spikes = {}, callbacks = {}, coverage = {},
            interpretation = "Gaps include loading/background/rendering; callback spans are inclusive and may overlap. Nearest profiler tick is not exact gap attribution. Heap is global Lua KB, not addon allocations or a leak test. Error deltas span sampled boundaries. Unit callback failures and work outside observed Flux services are not timed. Diagnostic timings cover recorded sections only, excluding observer seam and fast callback overhead." } }
    state.deadline, state.previousHeap, state.previousErrors = state.started + seconds, state.report.heapBeforeKB, state.report.errorsBefore
    state.heapAttemptAt = state.started
    state.lastHeapKB = state.report.heapBeforeKB
    state.lastHeapAt = state.lastHeapKB and state.started or nil
    state.labels, state.labelCount = FunctionLabels()
    for _, kind in ipairs({ "Events", "Ticker", "Scheduler" }) do
        local sourceKind = kind
        local service = Flux[kind]
        if service and type(service.ObserveTiming) == "function" then
            local release, reason = service.ObserveTiming(function(...) ObserveWatch(state, sourceKind, ...) end)
            if not release then
                for _, undo in ipairs(state.releases) do undo() end
                print(PREFIX, "Timing observer busy: " .. kind .. "; " .. tostring(reason)) return false
            end
            state.releases[#state.releases + 1], state.report.coverage[kind] = release, true
        else state.report.coverage[kind] = false end
    end
    watch = state
    if not watchFrame then watchFrame = CreateFrame("Frame") end
    watchFrame:RegisterEvent("PLAYER_LOGOUT")
    watchFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGOUT" and watch == state then Capture.StopWatch("logout") end
    end)
    watchFrame:SetScript("OnUpdate", function(_, elapsed)
        if watch ~= state then return end
        local started, now = WatchClock(), GetTime()
        local r = state.report
        r.frameCount = r.frameCount + 1
        if state.previousTime and WatchNumber(elapsed) then
            local gapMs = elapsed * 1000
            r.peakFrameMs = math.max(r.peakFrameMs, gapMs)
            if gapMs >= thresholdMs then
                r.spikeCount = r.spikeCount + 1
                local row = PushWatchRow(r.spikes, WATCH_SPIKES, r.spikeCount)
                row.sequence, row.at, row.gapMs = r.spikeCount, now - state.started, gapMs
                row.intervalCallbacks, row.callbackMs = state.frameCallbackCount, state.frameCallbackMs
                row.callbackLabel = state.frameCallbackFn and CallbackLabel(state, state.frameCallbackFn, state.frameCallbackKind, tostring(state.frameCallbackKey)) or nil
                row.callbackKey, row.callbackKind, row.callbackTokens = state.frameCallbackKey, state.frameCallbackKind, state.frameCallbackTokens
                row.busyKeys, row.keyOverflow = {}, state.frameKeyOverflow
                for kind, keys in pairs(state.frameKeys) do
                    for key, count in pairs(keys) do
                        row.busyKeys[#row.busyKeys + 1] = { kind = kind, key = tostring(key), callbacks = count }
                    end
                end
                table.sort(row.busyKeys, function(a, b) return a.callbacks > b.callbacks end)
                while #row.busyKeys > 4 do row.busyKeys[#row.busyKeys] = nil end
                row.preHeapKB, row.preHeapAgeSeconds = state.lastHeapKB, state.lastHeapAt and now - state.lastHeapAt or nil
                row.contextSampled = not state.contextAt or now - state.contextAt >= 1
                if row.contextSampled then
                    row.profiler = ProfilerTick()
                    row.heapKB, row.errors = HeapKB(), ErrorCount()
                    if row.heapKB and state.previousHeap then row.heapDeltaKB = row.heapKB - state.previousHeap end
                    if row.heapKB and row.preHeapKB then row.shortHeapDeltaKB = row.heapKB - row.preHeapKB end
                    if row.errors and state.previousErrors then row.errorDelta = math.max(0, row.errors - state.previousErrors) end
                    state.previousHeap, state.previousErrors, state.contextAt = row.heapKB, row.errors, now
                    state.heapAttemptAt = now
                    if row.heapKB then state.lastHeapKB, state.lastHeapAt = row.heapKB, now end
                end
                row.ui = { fluxTab = Method(_G.FluxWindowFrame, "GetActiveTab"),
                    mail = FrameState(_G.MailFrame), auction = FrameState(_G.AuctionHouseFrame or _G.AuctionFrame),
                    worldMap = FrameState(_G.WorldMapFrame), combat = (InCombatLockdown and InCombatLockdown()) or false }
            end
        end
        if now - state.heapAttemptAt >= 1 then
            local heap = HeapKB()
            state.heapAttemptAt, r.periodicHeapSamples = now, r.periodicHeapSamples + 1
            if heap then state.lastHeapKB, state.lastHeapAt = heap, now end
        end
        state.previousTime, state.frameCallbackMs = now, 0
        state.frameCallbackFn, state.frameCallbackKey, state.frameCallbackKind, state.frameCallbackTokens = nil, nil, nil, nil
        state.frameCallbackCount, state.frameKeyCount, state.frameKeyOverflow = 0, 0, 0
        for _, keys in pairs(state.frameKeys) do for key in pairs(keys) do keys[key] = nil end end
        AddWatchCost(state, started)
        if now >= state.deadline then Capture.StopWatch("expired") end
    end)
    watchFrame:Show()
    if db == nil then db = {}; _G.FluxPerfCaptureDB = db end
    db.spikeWatch = state.report
    print(PREFIX, string.format("Watching %.0fs for frame gaps >= %.0fms and Flux callbacks >= 10ms. Play normally; no profiler setting changed.", seconds, thresholdMs))
    return true
end

function Capture.PrintSpikes()
    local r = watch and watch.report
    local db = _G.FluxPerfCaptureDB
    if not r and ReadableTable(db) then r = db.spikeWatch end
    if not ReadableTable(r) then print(PREFIX, "No spike watch yet. /fluxperf watch") return end
    local status = not watch and r.status == "watching" and "interrupted" or r.status
    print(PREFIX, string.format("Spike watch %s: %d gaps (peak %.1fms); %d slow callbacks; recorded diagnostic sections %.2fms / %.2fms peak.",
        status, r.spikeCount, r.peakFrameMs, r.callbackCount, r.diagnosticMs, r.diagnosticPeakMs))
    for sequence = math.max(1, r.spikeCount - 7), r.spikeCount do
        local row = r.spikes[(sequence - 1) % WATCH_SPIKES + 1]
        print(PREFIX, string.format("  +%.1fs gap %.1fms; callbacks %s; peak callback %.1fms %s %s; error delta %s",
            row.at, row.gapMs, tostring(row.intervalCallbacks or "unknown"), row.callbackMs or 0, row.callbackLabel or "unattributed", row.callbackTokens or "", tostring(row.errorDelta)))
        local busy = row.busyKeys and row.busyKeys[1]
        if busy then print(PREFIX, "    busiest " .. busy.kind .. ":" .. busy.key .. " x" .. busy.callbacks) end
    end
    for sequence = math.max(1, r.callbackCount - 7), r.callbackCount do
        local row = r.callbacks[(sequence - 1) % WATCH_CALLBACKS + 1]
        print(PREFIX, string.format("  +%.1fs callback %.1fms %s %s %s", row.at, row.ms, row.kind, row.key, row.label))
    end
    print(PREFIX, "Correlations only: do not sum overlapping spans or equate a frame gap with Flux CPU. /fluxperf watch off saves; /reload writes diagnostics to disk.")
end
