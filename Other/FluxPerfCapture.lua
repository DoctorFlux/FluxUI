-- On-demand CPU deltas. No hooks, wrappers, frame scans or tickers while idle.
-- Includes Blizzard frames: an embedded map can cost CPU outside _FluxUI's bill.
local addonName, ns = ...
local Flux = ns.Flux
local Capture = {}
Flux.PerfCapture = Capture
local active
local PREFIX = "|cff00ccffFluxPerf|r"
local SCRIPTS = { "OnUpdate", "OnEvent" }

local function PlainNumber(v)
    return type(v) == "number" and not (issecretvalue and issecretvalue(v))
end

local function ReadCPU(api, object, children)
    if type(api) ~= "function" then return 0, 0 end
    local ok, ms, calls = pcall(api, object, children)
    if not ok or not PlainNumber(ms) then return 0, 0 end
    return ms, PlainNumber(calls) and calls or 0
end

local function Method(object, name)
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
    if type(fn) ~= "function" or snapshot.functions[fn] then return end
    local ms, calls = ReadCPU(GetFunctionCPUUsage, fn, true)
    snapshot.functions[fn] = { label = label, ms = ms, calls = calls }
end

local function Snapshot(atEnd)
    local snap = { frames = {}, functions = {}, passes = {}, liveUpdates = 0, subscribers = {} }
    local function Boundary()
        if UpdateAddOnCPUUsage then pcall(UpdateAddOnCPUUsage) end
        snap.addonMs = ReadCPU(GetAddOnCPUUsage, addonName)
        snap.time = GetTime()
    end
    -- Exclude the expensive endpoint frame enumerations from addon CPU/time.
    if atEnd then Boundary() end
    -- Module functions also cover timer work, which GetFrameCPUUsage misses.
    -- Skip object graphs (frames, pools, button arrays, namespace cycles).
    local seen = {}
    local function Walk(tbl, path, depth)
        if type(tbl) ~= "table" or seen[tbl] or depth > 3 then return end
        if rawget(tbl, 0) or tbl.GetObjectType then return end
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
    local aliases = {}
    for key, value in pairs(_G) do
        if type(key) == "string" and (key:match("^Flux") or key:match("^UF_"))
            and (type(value) == "table" or type(value) == "userdata") then
            aliases[value] = key
        end
        if type(key) == "string" and key:match("^Flux") and key ~= "FluxPerfCaptureDB" then
            if type(value) == "table" then Walk(value, key, 1)
            elseif type(value) == "function" then AddFunction(snap, value, key) end
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
        if not Method(frame, "IsForbidden") then
            local ms, calls = ReadCPU(GetFrameCPUUsage, frame, false)
            local label = aliases[frame] or Label(frame, i)
            snap.frames[frame] = { label = label, ms = ms, calls = calls }
            for _, script in ipairs(SCRIPTS) do
                local ok, fn = pcall(frame.GetScript, frame, script)
                if ok and type(fn) == "function" then
                    AddFunction(snap, fn, label .. ":" .. script)
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
                rows[#rows + 1] = { label = row.label, ms = ms, calls = calls, msPerSecond = ms / seconds }
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
    print(PREFIX, string.format("%s %s (%s) build %s | spellRanks=%s | %.1fs | scriptProfile=%s",
        r.client, r.version or "?", r.gameType or "?", r.build, r.spellRanks or "?", r.seconds, r.scriptProfile))
    print(PREFIX, string.format("FPS samples: avg %.1f / min %.1f | Flux CPU %.2f ms/s", r.fpsAverage, r.fpsMin, r.addonMsPerSecond))
    print(PREFIX, string.format("Visible OnUpdates (all addons): %d -> %d", r.liveBefore, r.liveAfter))
    print(PREFIX, "Flux ticker subscribers: " .. table.concat(r.subscribers, ", "))
    print(PREFIX, "CVars: " .. r.cvars)
    for _, section in ipairs({ "frames", "functions", "passes" }) do
        print(PREFIX, section .. " (inclusive; rows overlap, do not sum):")
        for i = 1, math.min(12, #r[section]) do
            local row = r[section][i]
            print(string.format("  %7.2f ms/s  %7d calls  %s", row.msPerSecond, row.calls, row.label))
        end
    end
    print(PREFIX, "CPU profiling adds overhead; use scriptProfile=0 for final FPS comparison. Native rendering is not measured.")
end

function Capture.Cancel()
    if not active then return end
    if active.timer then active.timer:Cancel() end
    if active.sampler then active.sampler:Cancel() end
    active = nil
end

function Capture.Start(seconds)
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
        _G.FluxPerfCaptureDB = {
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
            frames = Rank(state.before.frames, after.frames, elapsed),
            functions = Rank(state.before.functions, after.functions, elapsed),
            passes = Rank(state.before.passes, after.passes, elapsed, true),
        }
        active = nil
        Capture.Print()
    end)
end
