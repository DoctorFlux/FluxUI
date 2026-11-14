-- Actual Range/Secrets modules: bounded per-call allocation, with unchanged
-- public/opaque/error and same-frame cache contracts. Not a WoW FPS benchmark.
local sourceRoot = arg[1] or "."
local measure = arg[2] == "--measure"
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function fixture(track)
    local state = { now = 10, exists = true, spellCalls = 0, itemCalls = 0, actionCalls = 0,
        blocked = false, events = {}, protectedFunctions = {}, probeFunctions = {} }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local ns = { Flux = {} }; local flux = ns.Flux
    env.GetTime = function()
        if state.timeHook then state.timeHook() end
        return state.now
    end
    env.UnitExists = function()
        if state.existsError then error("unavailable unit") end
        return state.exists
    end
    env.UnitCanAttack = function() return true end
    env.UnitCanAssist = function() return false end
    env.UnitIsDead = function() return false end
    env.wipe = function(t) for key in pairs(t) do t[key] = nil end; return t end
    env.pcall = function(fn, ...)
        if track then state.protectedFunctions[fn] = true end
        return pcall(fn, ...)
    end
    ns._secretsBackend = {
        IsSecretValue = function(v) return type(v) == "table" and v.secret == true end,
        CanAccessValue = function(v) return not (type(v) == "table" and v.inaccessible) end,
        CanAccessSecrets = function() return true end,
        IsSecretTable = function(v) return type(v) == "table" and v.secretTable == true end,
        CanAccessTable = function(v) return not (type(v) == "table" and v.inaccessible) end,
    }
    env.type = function(value)
        if type(value) == "table" and value.secretKind then return value.secretKind end
        return type(value)
    end
    flux.Events = { Register = function(name, fn) state.events[name] = fn end }
    flux.Spell = { IsInRange = function(id, unit)
        state.spellCalls = state.spellCalls + 1
        if state.spellError then error("temporary spell failure") end
        return state.spellResult
    end }
    flux.Item = {
        CanCheckRange = function() return not state.blocked end,
        IsInRange = function(id, unit)
            state.itemCalls = state.itemCalls + 1
            if state.itemError then error("temporary item failure") end
            return state.itemResult
        end,
    }
    env.IsActionInRange = function(slot, unit)
        state.actionCalls = state.actionCalls + 1
        state.actionUnit = unit
        if state.actionError then error("temporary action failure") end
        return state.actionResult
    end
    state.spellResult, state.itemResult, state.actionResult = true, false, 1
    assert(loadfile(sourceRoot .. "/Core/API/Secrets.lua", "t", env))("_FluxUI", ns)
    assert(loadfile(sourceRoot .. "/Core/Engine/Range.lua", "t", env))("_FluxUI", ns)
    if track then
        for index = 1, 30 do
            local name, original = debug.getupvalue(flux.Range.CheckSpell, index)
            if not name then break end
            if name == "Memo" then
                debug.setupvalue(flux.Range.CheckSpell, index, function(key, probe, ...)
                    state.probeFunctions[probe] = true
                    return original(key, probe, ...)
                end)
                state.memoInstrumented = true
                break
            end
        end
        assert(state.memoInstrumented, "actual memo boundary exists")
    end
    return state, flux, env
end

for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    local s, flux, env = fixture(false)
    local range, secrets = flux.Range, flux.Secrets
    for _, case in ipairs({ {1,1,"==",true},{1,2,"~=",true},{1,2,"<",true},
        {2,1,">",true},{1,1,">=",true},{1,1,"<=",true},{1,2,"==",false},
        {1,1,"<",false},{1,1,">",false},{2,1,"<=",false},{1,2,">=",false} }) do
        check(secrets.SafeCompare(case[1],case[2],case[3]) == case[4], client .. " comparison result")
    end
    check(secrets.SafeCompare({}, 1, "<") == nil, "invalid comparison remains contained")
    check(secrets.SafeCompare(1, 2, "unknown") == nil, "unknown operator remains nil")
    check(secrets.SafeCompare({secret=true}, 1, "==") == nil, "secret comparison stays guarded")
    check(secrets.SafeCompare({inaccessible=true}, 1, "==") == nil, "inaccessible comparison stays guarded")
    check(secrets.SafeBooleanTest(nil, false) == false, "nil default retained")
    check(secrets.SafeBooleanTest(0, false) == true, "Lua zero remains truthy")
    check(secrets.SafeBooleanTest("", false) == true, "Lua empty string remains truthy")
    check(secrets.SafeBooleanTest(false, true) == false, "false remains false")
    check(secrets.SafeBooleanTest({secret=true,secretKind="boolean"}, false) == false, "secret boolean fallback")
    check(secrets.SafeBooleanTest({secret=true,secretKind="number"}, false) == true, "existing nonboolean secret policy")
    for _, case in ipairs({ {true,true},{false,false},{1,true},{0,false},{"text",true} }) do
        check(secrets.NormalizeTriBool(case[1]) == case[2], "tri-state policy retained")
    end
    check(secrets.NormalizeTriBool(nil) == nil, "nil tri-state retained")
    check(secrets.NormalizeTriBool({secret=true,secretKind="boolean"}) == nil, "opaque boolean tri-state")
    check(secrets.SafeEqualForCache(1,2) == false and secrets.SafeEqualForCache(1,1), "cache equality policy")
    local opaque = {secret=true}
    check(secrets.SafeEqualForCache(opaque,opaque) == true, "existing protected equality fallback retained")

    check(range.CheckSpell(123,"target") == true, "spell range")
    check(range.CheckSpell("123","target") == true and s.spellCalls == 1, "original string/numeric memo key equivalence")
    check(range.CheckItem(42,"target") == false, "item false retained")
    check(range.CheckAction("7","target") == true, "action tri-state normalization")
    for _=1,10 do range.CheckSpell(123,"target");range.CheckItem(42,"target");range.CheckAction(7,"target") end
    check(s.spellCalls == 1 and s.itemCalls == 1 and s.actionCalls == 1, "same-frame query deduplication")
    s.blocked = true
    local value, blocked = range.CheckItem(42,"target")
    check(value == nil and blocked == true and s.itemCalls == 1, "item permission check precedes cached answer")
    s.blocked = false;s.now = 11
    s.spellError = true
    check(range.CheckSpell(123,"target") == nil, "failed spell query becomes unknown")
    s.spellError = false
    check(range.CheckSpell(123,"target") == nil and s.spellCalls == 2, "nil sentinel retained in frame")
    s.now = 12
    check(range.CheckSpell(123,"target") == true and s.spellCalls == 3, "next frame retries failure")
    range.Start();s.events.PLAYER_TARGET_CHANGED("PLAYER_TARGET_CHANGED")
    check(range.CheckSpell(123,"target") == true and s.spellCalls == 4, "same-frame identity event invalidates memo")
    s.exists = false;s.now = 13
    check(range.CheckSpell(123,"focus") == nil and s.spellCalls == 4, "missing unit skips probe")
    s.exists = true;s.existsError = true;s.now = 14
    check(range.CheckAction(7,"focus") == nil and s.actionCalls == 1, "failed unit getter stays unknown")
    s.existsError = false;s.now = 15
    check(range.CheckAction(7,"party2") == true and s.actionUnit == "party2", "explicit non-target action unit retained")

    -- Item CanCheckRange is an integration callback; it can replace the module.
    local old = flux.Item
    local oldCalls, replacementCalls = 0, 0
    old.IsInRange = function() oldCalls = oldCalls + 1;return false end
    old.CanCheckRange = function()
        flux.Item = { IsInRange=function() replacementCalls = replacementCalls+1;return true end }
        return true
    end
    check(range.CheckItem(99,"focus") == false and oldCalls == 1 and replacementCalls == 0,
        "same-call item owner snapshot retained across reentrant permission callback")
    s.now = 16
    check(range.CheckItem(99,"focus") == true and replacementCalls == 1, "next call observes replacement owner")
    -- Spell ownership was originally resolved inside the miss probe, after time.
    local clockCalls = 0
    s.timeHook = function()
        clockCalls = clockCalls + 1
        if clockCalls == 2 then flux.Spell = {IsInRange=function()return false end} end
    end
    s.now = 17
    check(range.CheckSpell(100,"party1") == false, "spell module resolves at original miss phase")
    s.timeHook = nil
end

local iterations = 10000
local function workload(state, flux)
    local r, s = flux.Range, flux.Secrets
    for _=1,iterations do
        r.CheckSpell(123,"target");r.CheckItem(42,"target");r.CheckAction(7,"target")
        s.SafeCompare(1,2,"<");s.SafeBooleanTest(true,false)
        s.NormalizeTriBool(false);s.SafeEqualForCache(1,2)
    end
end
local function cardinality(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
local state, flux = fixture(true)
workload(state, flux)
local probes, protected = cardinality(state.probeFunctions), cardinality(state.protectedFunctions)
if not measure then
    check(probes <= 3, "range uses stable probe functions on cache hits")
    check(protected <= 10, "protected operations reuse stable functions")
end
check(state.spellCalls==1 and state.itemCalls==1 and state.actionCalls==1, "native range probes remain identical")
local memoryState, memoryFlux = fixture(false)
memoryFlux.Range.CheckSpell(123,"target");memoryFlux.Range.CheckItem(42,"target");memoryFlux.Range.CheckAction(7,"target")
collectgarbage("collect")
collectgarbage("stop")
local before = collectgarbage("count")
workload(memoryState, memoryFlux)
local heap = collectgarbage("count") - before
collectgarbage("restart")
print(string.format("CORE_ALLOC|iterations=%d|probeFunctions=%d|protectedFunctions=%d|heapKiB=%.3f|nativeProbes=%d",
    iterations,probes,protected,heap,memoryState.spellCalls+memoryState.itemCalls+memoryState.actionCalls))
print("Passive core allocation: "..checks.." checks PASS; desktop heap/operation counts, native FPS unmeasured")
