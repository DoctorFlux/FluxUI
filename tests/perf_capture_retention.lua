-- Expired/cancelled timer callbacks may remain retained by native handles.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s
end
local source, measure = "Other/FluxPerfCapture.lua", false
for i, value in ipairs(arg or {}) do
    if value == "--source" then source = assert(arg[i + 1]) end
    if value == "--measure" then measure = true end
end
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function stateOf(fn)
    for i = 1, 20 do
        local name, value = debug.getupvalue(fn, i)
        if not name then break end
        if name == "state" then return value end
    end
    error("capture timer state not found")
end
for _, branch in ipairs({ "live", "forever", "classic_era", "classic_anniversary", "classic" }) do
    local now, timers, frames = 0, {}, {}
    local env = setmetatable({}, { __index = _G }); env._G = env
    for i = 1, 500 do
        local f = { index = i }
        function f:GetName() return "Owned" .. self.index end
        function f:GetObjectType() return "Frame" end
        function f:IsForbidden() return false end
        function f:IsVisible() return true end
        function f:GetScript() return nil end
        frames[i] = f
    end
    env.EnumerateFrames = function(previous) return frames[previous and previous.index + 1 or 1] end
    env.GetTime = function() return now end
    env.GetFramerate = function() return 120 end
    env.GetBuildInfo = function() return "model", 1 end
    env.GetCVar = function() return "1" end
    env.GetAddOnCPUUsage = function() return now end
    env.GetFrameCPUUsage = function() return now, now end
    env.GetFunctionCPUUsage = function() return now, now end
    env.print = function() end
    local function timer(_, fn)
        local t = { callback = fn }
        function t:Cancel() self.cancelled = true end
        timers[#timers + 1] = t
        return t
    end
    env.C_Timer = { NewTimer = timer, NewTicker = timer }
    local flux = { Client = { expansion = branch } }
    assert(load(read(source), "@capture-source", "t", env))("_FluxUI", { Flux = flux })
    local states, kept = {}, 0
    for cycle = 1, 20 do
        flux.PerfCapture.Start(5)
        local done = timers[#timers]
        local state = stateOf(done.callback); states[#states + 1] = state
        check(state.before and state.before.frames[frames[1]], branch .. " captures endpoint before work")
        if cycle % 2 == 0 then
            now = now + 5; done.callback()
            check(env.FluxPerfCaptureDB and #env.FluxPerfCaptureDB.frames == 50,
                branch .. " completion keeps compact top-50 report")
        else
            flux.PerfCapture.Cancel()
            check(timers[#timers - 1].cancelled and done.cancelled, branch .. " cancellation stops both handles")
        end
        check(state.before == nil, branch .. " releases full snapshot " .. cycle)
        check(state.timer == nil and state.sampler == nil, branch .. " drops timer cycle " .. cycle)
    end
    collectgarbage("collect")
    for _, state in ipairs(states) do if state.before then kept = kept + 1 end end
    print(("METRIC %s retained_snapshots=%d retained_frame_rows=%d timer_callbacks=%d")
        :format(branch, kept, kept * #frames, #timers))
end
print(("Capture retention: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
