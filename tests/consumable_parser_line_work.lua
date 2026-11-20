-- Actual installed parser; deterministic output and private per-line work only.
-- `before` records the pre-optimization work contract for the dated baseline.
local mode = arg[1] or "after"
assert(mode == "before" or mode == "after", "fixed before/after work contract")
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function eq(actual, expected, label)
    check(actual == expected, label .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end
local function compile(text, name, env)
    if setfenv then local fn = assert(loadstring(text, name)); setfenv(fn, env); return fn end
    return assert(load(text, name, "t", env))
end
local env = setmetatable({}, {__index = _G}); env._G = env
env.Flux = {Client = {isRetail = true}}
env.GetLocale = function() return "enUS" end
env.UnitHealthMax = function() return 1000 end
env.UnitPowerMax = function() return 2000 end
env.FluxAPICompat = false
env.FluxItemClass = {GetStatic = function() return {classID = 0, subClassID = 5} end}
local file = assert(io.open("Inventory/FluxConsumableClassify.lua", "rb"))
local source = file:read("*a"); file:close()
compile(source, "@actual-ConsumableClassify", env)()
local parse = env.FluxConsumableClassify.ParseFoodWaterRestore
local function private(fn, wanted, seen)
    seen = seen or {}; if seen[fn] then return end; seen[fn] = true
    local children = {}
    for i = 1, math.huge do
        local name, value = debug.getupvalue(fn, i)
        if not name then break end
        if name == wanted then return value end
        if type(value) == "function" then children[#children + 1] = value end
    end
    for i = 1, #children do local found = private(children[i], wanted, seen); if found then return found end end
end
local normalize = assert(private(parse, "NormalizeLine"))
local percentAxis = assert(private(parse, "ParseLinePercentAxis"))
local percentCombo = assert(private(parse, "ParseLineComboPercent"))
local function encode(value)
    if type(value) ~= "table" then return type(value) .. ":" .. tostring(value) end
    local keys, parts = {}, {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys)
    for i = 1, #keys do local key = keys[i]; parts[i] = key .. "=" .. encode(value[key]) end
    return "{" .. table.concat(parts, ";") .. "}"
end
local nbsp = string.char(194, 160)
local cases = {
    {"flat-health", "Use: Restores 120 health over 30 sec. Must remain seated while eating.", 120, 0, 0},
    {"flat-thousands-colour", "|cffffffffUse: Restores up to 1,200 mana over 30 sec.|r\nMust remain seated while drinking.", 0, 1200, 0},
    {"percent-combo", "Restores 50% health and 100% mana over 20 sec.\nMust remain seated while eating and drinking.", 500, 2000, 3},
    {"percent-rate", "Restores 2% of your health every second over 10 sec.\nMust remain seated while eating.", 200, 0, 1},
    {"mixed-lines", "Requires Level 35\nRestores 25% of your maximum health over 10 sec.\nRestores 100 mana over 10 sec.", 250, 100, 1},
    {"partial-nbsp", "Unresolved" .. nbsp .. "tooltip\nRequires Level 35", 0, 0, 0},
    {"maximum-buff", "Increases your maximum health by 10%.", 0, 0, 1},
    {"flat-combo", "Restores 120 health and 240 mana over 20 sec. Must remain seated while eating.", 120, 240, 0},
}
local totalNormalize, totalPercent, totalLines = 0, 0, 0
for i = 1, #cases do
    local case, calls, lines = cases[i], {normalize = 0, percent = 0}, 0
    for _ in case[2]:gmatch("[^\n]+") do
        lines = lines + 1
    end
    debug.sethook(function(event)
        if event == "call" then
            local fn = debug.getinfo(2, "f").func
            if fn == normalize then calls.normalize = calls.normalize + 1 end
            if fn == percentAxis or fn == percentCombo then calls.percent = calls.percent + 1 end
        end
    end, "c")
    local ok, result = pcall(parse, case[2], "item:117", "Food")
    debug.sethook()
    check(ok, case[1] .. " parse succeeds")
    eq(result.effectiveH, case[3], case[1] .. " health")
    eq(result.effectiveM, case[4], case[1] .. " mana")
    eq(calls.normalize, lines * (mode == "before" and 5 or 1), case[1] .. " normalizations")
    -- The current dispatcher enters only workers for the resources on that line.
    eq(calls.percent, mode == "before" and 3 * lines or case[5], case[1] .. " percent worker entries")
    local second = parse(case[2], "item:117", "Food")
    eq(encode(second), encode(result), case[1] .. " repeat full return values")
    check(second ~= result and second.health ~= result.health and second.mana ~= result.mana,
        case[1] .. " result and axes remain fresh")
    print("RESULT " .. case[1] .. " " .. encode(result))
    totalNormalize = totalNormalize + calls.normalize
    totalPercent = totalPercent + calls.percent
    totalLines = totalLines + lines
end
print(("Parser line work: %d checks PASS; cases=%d lines=%d normalizations=%d percentWorkers=%d mode=%s; actual parser, no timing/native claim")
    :format(checks, #cases, totalLines, totalNormalize, totalPercent, mode))
