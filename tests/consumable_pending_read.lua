-- Actual installed selector/classifier owners; metadata, timers and widgets are modeled.
-- Checks pending-read work and recovery, not native timing, rendering or FPS.
local function read(path)
    local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close(); return text
end
local function compile(text, name, env)
    if setfenv then local fn = assert(loadstring(text, name)); setfenv(fn, env); return fn end
    return assert(load(text, name, "t", env))
end
local checks, uniqueWalks = 0, 0
local providerMode = arg[1] or "builtin"
assert(providerMode == "builtin" or providerMode == "syndicator", "fixed provider required")
local function check(value, label) checks = checks + 1; assert(value, label) end
local function eq(actual, expected, label)
    check(actual == expected, label .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local providerSource = read("tests/combat_grid_live_counts.lua")
local providerEnd = assert(providerSource:find("local entries =", 1, true))
local providerEnv = setmetatable({arg = {}}, {__index = _G})
providerEnv.load = function(text, name, _, env) return compile(text, name, env) end
local _, providerFixture = compile(providerSource:sub(1, providerEnd - 1) .. "return boot, provider",
    "@existing-live-count-provider", providerEnv)()

local source = read("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua")
source = source:sub(1, assert(source:find("-- PLAYER_LOGIN bag priming", 1, true)) - 1)
local stub = "    env.FluxConsumableClassify = { Classify = function(id) return items[id] end }"
local first, last = assert(source:find(stub, 1, true))
-- Match the TOC: actual metadata/classifier owners must exist when Scan captures them.
source = source:sub(1, first - 1) .. "    preparePendingReadOwners(s, env, load)" .. source:sub(last + 1)
local pendingReady, thirdRestore = false, 80
local fixture = setmetatable({arg = {[0] = "ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua"}}, {__index = _G})
fixture.preparePendingReadOwners = function(s, env, loadOwner)
    env.C_Item.GetItemInfoInstant = function(id) return id, "Consumable", "Food", "", 1, 0, 5 end
    env.C_Item.RequestLoadItemDataByID = function() end
    local function tooltip(id)
        local amount = id == 1487 and 120 or id == 2287 and thirdRestore or pendingReady and 500
        local text = amount and ("Use: Restores " .. amount .. " health over 30 sec. Must remain seated while eating.") or "Unresolved"
        return {lines = {{leftText = "item" .. id}, {leftText = text}}}
    end
    env.C_TooltipInfo = {
        GetBagItem = function(bag, slot)
            local row = s.slots[bag] and s.slots[bag][slot]
            return row and tooltip(row.itemID)
        end,
        GetHyperlink = function(link) return tooltip(tonumber(link:match("^item:(%d+)$"))) end,
    }
    local create = env.CreateFrame
    env.CreateFrame = function(kind, ...)
        local frame = create(kind, ...)
        if kind == "GameTooltip" then
            function frame:SetOwner() end
            function frame:ClearLines() end
            function frame:SetBagItem() end
            function frame:SetHyperlink() end
            function frame:NumLines() return 0 end
        end
        return frame
    end
    env.C_Timer.NewTicker = function(delay, fn)
        local timer = {cancelled = false}
        function timer:Cancel() self.cancelled = true end
        local function tick()
            if not timer.cancelled then fn(); if not timer.cancelled then env.C_Timer.After(delay, tick) end end
        end
        env.C_Timer.After(delay, tick); return timer
    end
    loadOwner("Inventory/FluxItemClass.lua")
    loadOwner("Inventory/FluxConsumableClassify.lua")
    if providerMode == "syndicator" then
        s.env, s.load = env, loadOwner
        providerFixture(s)
    end
end
local boot, items = compile(source .. "\nreturn boot, items", "@existing-pending-read-fixture", fixture)()
items[1487] = {kind = "food", effective = 120}
local s = boot("forever", false)
local env, Best, C, IC = s.env, s.best, s.env.FluxConsumableClassify, s.env.FluxItemClass
local function pulse(state)
    if providerMode == "syndicator" then
        state:publish()
        state:event("BAG_UPDATE", 0); state:event("BAG_UPDATE_DELAYED"); state:advance(0)
    else
        state:bags()
    end
end
check(type(C.GetInvalidationRevision) == "function", "actual classifier exposes invalidation revision")
s.inv.Start(); s:advance(10)
eq(s.inv.source, providerMode, "selected actual provider")
s:set(0, 2, 1487, 5); s:set(0, 3, 2287, 5); pulse(s); s:advance(3)
eq(Best.GetBest("food").itemID, 1487, "known positive wins before pending arrival")
env._FluxUI_CharSavedVars = {food = {preferRecuperate = false}}
env.FluxExtraButtonVisibility = {QuickGate = function() return true end, Apply = function() return true end}
s.bridge.GetPreferredCreateSpell = function() return 1, "Create fixture" end
local nc = read("ExtraButtonSystem/NonCombatGrid/Grid.lua")
local countStart = assert(nc:find("function btn:SetCount(count, opts)", 1, true))
local countEnd = assert(nc:find("function btn:ShowTooltip()", countStart, true))
local attach = env.FluxEBSButtonRefresh.Attach
env.FluxEBSButtonRefresh.Attach = function(opts)
    compile("local btn=...\n" .. nc:sub(countStart, countEnd - 1), "@existing-NC-count", env)(opts.btn)
    return attach(opts)
end
local btn, module = s:button("food", false, "ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua")
env.FluxEBSButtonRefresh.Attach = attach
s:advance(3)
eq(btn.ItemId, 1487, "actual Food face selects positive")
eq(module._trackedItemID, 1487, "actual Food tracks positive")

-- Observe the actual query by identity; replacing it would deliberately disable reuse.
local unique, uniqueIDs = s.inv.GetUniqueItems, s.inv.GetUniqueItemIDs
check(debug.gethook() == nil, "no inherited debug hook")
debug.sethook(function(event)
    if event == "call" or event == "tail call" then
        local query = debug.getinfo(2, "f").func
        if query == unique or query == uniqueIDs then uniqueWalks = uniqueWalks + 1 end
    end
end, "c")
local function demand()
    Best.GetBest("food"); Best.GetLadder("food"); Best.GetAllBest()
end
local function poll(n)
    for _ = 1, n do demand(); s:advance(0.45) end
end
local function selected(id, label)
    local best = Best.GetBest("food")
    eq(best and best.itemID, id, label)
end
local function ladderHas(id)
    for _, row in ipairs(Best.GetLadder("food")) do if row.itemID == id and row.count > 0 then return true end end
    return false
end

s:set(0, 1, 117, 13); pulse(s)
check(C.IsPending(117), "actual unresolved tooltip remains pending")
poll(2)
local before, generation = uniqueWalks, Best._generation
poll(3)
eq(uniqueWalks, before, "unchanged pending reads stop full unique walks")
check(Best._generation > generation, "pending reads retain publication cadence")
selected(1487, "known positive survives unresolved polls")
eq(btn.WCount.value, "5", "positive visible count survives unresolved polls")

local ready = s.inv.IsReady
s.inv.IsReady = function() return true end
before = uniqueWalks; poll(1)
check(uniqueWalks > before, "foreign readiness callback retains full walk")
s.inv.IsReady = ready
poll(2)

local effective = Best.Score.EffectiveFromClassify
local effectiveCalls = 0
Best.Score.EffectiveFromClassify = function(...)
    effectiveCalls = effectiveCalls + 1; return effective(...)
end
before = uniqueWalks; poll(1)
check(uniqueWalks > before, "foreign scoring callback retains full walk")
check(effectiveCalls > 0, "full path preserves foreign scoring callback")
Best.Score.EffectiveFromClassify = effective
poll(2)

local mutated = false
Best.RegisterListener("test.pending-read-mutation", function(_, runtime)
    if not mutated and runtime.food then runtime.food.effective = 1; mutated = true end
end)
poll(1); check(mutated, "registered callback receives real runtime row")
before = uniqueWalks; poll(1)
check(uniqueWalks > before, "in-place public runtime mutation forces rebuild")
eq(Best.GetBest("food").effective, 120, "full path repairs mutated candidate")
Best.UnregisterListener("test.pending-read-mutation")
poll(2)

local bagGeneration = s.inv.GetBagGeneration()
local revision = C.GetInvalidationRevision()
thirdRestore = 360
IC.OnItemDataLoaded(2287)
check(C.GetInvalidationRevision() > revision, "actual metadata invalidates classification revision")
before = uniqueWalks; poll(2)
eq(s.inv.GetBagGeneration(), bagGeneration, "metadata recovery needs no bag publication")
check(uniqueWalks > before, "other owned metadata invalidation forces full walk")
selected(2287, "newly stronger other owned candidate is promoted")
check(ladderHas(2287), "other owned candidate remains in public ladder")

pendingReady = true
before = uniqueWalks; poll(1)
check(uniqueWalks > before, "pending readiness without an event reopens full walk")
eq(s.inv.GetBagGeneration(), bagGeneration, "tooltip-only recovery keeps bag generation")
check(not C.IsPending(117), "ready tooltip drains actual pending classification")
selected(117, "late pending winner promotes on first eligible poll without metadata event")
check(ladderHas(117), "late winner is present in public ladder")

before = uniqueWalks
s:set(0, 1, 117, 0); pulse(s); s:advance(2)
check(uniqueWalks > before, "real depletion performs full inventory work")
selected(2287, "depletion selects next owned candidate")
check(not ladderHas(117), "depleted identity is absent from public owned ladder")
s:set(0, 1, 117, 13); pulse(s); s:advance(2)
selected(117, "real refill restores late winner")
eq(btn.ItemId, 117, "Food face follows real refill")
eq(btn.WCount.value, "13", "Food count follows real refill")
s:set(0, 1, 117, 0); s:set(0, 2, 1487, 0); s:set(0, 3, 2287, 0); pulse(s); s:advance(2)
selected(nil, "all real removals clear owned best")
eq(#Best.GetLadder("food"), 0, "all real removals clear owned ladder")
debug.sethook()

-- One past read must not turn the ordinary capped retry chain into a permanent
-- 0.4s publication loop after the consumer stops requesting the result.
pendingReady, thirdRestore = false, 80
local idle = boot("forever", false)
idle.inv.Start(); idle:advance(10)
eq(idle.inv.source, providerMode, "selected actual provider in stopped-read control")
idle:set(0, 2, 1487, 5); pulse(idle); idle:advance(3)
idle:set(0, 1, 117, 13); pulse(idle)
check(idle.env.FluxConsumableClassify.IsPending(117), "fresh no-UI context has real pending metadata")
idle.best.GetBest("food")
idle:advance(0.45)
local idleGeneration, idleBagGeneration = idle.best._generation, idle.inv.GetBagGeneration()
idle:advance(3)
check(idle.best._generation - idleGeneration <= 2, "past read demand does not cause perpetual fast publications")
eq(idle.inv.GetBagGeneration(), idleBagGeneration, "stopped-read interval has no inventory changes")
print(("Consumable pending read: %d checks PASS; provider=%s; actual owners, modeled metadata; no native/FPS claim"):format(checks, providerMode))
