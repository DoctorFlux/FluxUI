-- Actual shared adapter; API values are mocked, never made readable by the test.
-- Optional arg1: baseline Core/API/Threat.lua; arg2 --measure records failures.
local source = arg[1] or "Core/API/Threat.lua"
local measure = arg[2] == "--measure"
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local secret = setmetatable({}, { __lt = function() error("secret comparison") end,
    __add = function() error("secret arithmetic") end, __tostring = function() error("secret conversion") end })
local function boot(forever)
    local s = { calls = 0, value = 200, percent = 20, tanking = false, changing = false }
    local e = setmetatable({}, { __index = _G }); e._G = e
    local ns = { Flux = { Client = { isForever = forever, isClassicEra = not forever },
        Secrets = { IsSecretValue = function(v) return v == secret end,
            CanAccessValue = function(v) return v ~= secret end,
            SafeBooleanTest = function(v, fallback) if v == secret then return fallback end; return v and true or false end },
        Spec = { IsPlayerEffectivelyTank = function() return false end } } }
    e.UnitDetailedThreatSituation = function()
        s.calls = s.calls + 1
        if s.absent then return end
        if s.changing then return false, 1, s.calls * 10, s.calls * 11, s.calls * 100 end
        return s.tanking, 1, s.percent, s.percent, s.value
    end
    assert(loadfile(source, "t", e))("_FluxUI", ns)
    return ns.Flux.Threat, s
end
local threat, s = boot(true)
s.changing = true
local row = threat.GetMeterRow("player", "target")
check(s.calls == 1, "one native query for a Forever row")
check(row.threatVal == 100 and row.threatPct == 10 and row.rawPct == 11, "one coherent native sample")
s.changing, s.calls = false, 0
for _ = 1, 500 do
    row = threat.GetMeterRow("player", "target")
    check(row.threatVal == 200 and row.threatPct == 20, "ordinary row preserved")
end
check(s.calls == 500, "500 settled rows make 500 native queries")
local settledQueries = s.calls
s.calls, s.value, s.percent = 0, secret, secret
row = threat.GetMeterRow("player", "target")
check(row.secret and row.threatVal == secret and row.threatPct == secret, "opaque values are preserved")
check(s.calls == 1, "opaque row uses one native query")
s.value, s.percent, s.tanking = 300, 60, true
row = threat.GetMeterRow("player", "target")
check(row.isTanking and row.threatPct == 100 and row.threatVal == 300, "tanking display preserved")
s.value, s.percent, s.tanking = 0, 0, false
check(threat.GetMeterRow("player", "target") == nil, "empty row omitted")
s.absent = true
check(threat.GetMeterRow("player", "target") == nil, "absent data remains absent")
local classic, cs = boot(false)
local classicRow = classic.GetMeterRow("player", "target")
check(cs.calls == 1 and classicRow.threatVal == 2 and classicRow.threatPct == 20, "Classic downscaling unchanged")
cs.value = secret
check(classic.GetMeterRow("player", "target") == nil, "Classic opaque omission unchanged")
print(string.format("threat meter sample: %d checks, %d failures; Forever queries per500=%d", checks, failures, settledQueries))
if not measure then assert(failures == 0, "coherent threat sample regression") end
