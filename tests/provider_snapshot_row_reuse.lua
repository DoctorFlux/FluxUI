-- Real provider adapter and scheduler; source facts/native timing are mocked.
-- Optional argument: alternate Inventory/Syndicator/Adapter.lua for baseline.
local source = arg[1] or "Inventory/Syndicator/Adapter.lua"
local checks, failures, active = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local constructors = {}
local f = assert(io.open(source, "r")); local line = 0
for text in f:lines() do
    line = line + 1
    if text:find("byIndex[index] = {", 1, true) then constructors[line] = true end
end
f:close()
local function size(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
local function record(id, count, link)
    return {itemID = id, itemCount = count or 1, itemLink = link or "item:" .. id}
end

local function boot(legacy, ready, installed)
    local e = setmetatable({}, {__index = _G}); e._G = e
    local h = {now = 10, timers = {}, events = {}, callbacks = {}, ready = ready ~= false,
        who = "Current-Realm", characters = {}, pubs = {}, stats = {rows = 0, cleared = 0, visits = 0}}
    local char = {mail = {}, auctions = {}}; h.characters[h.who] = char
    local inv = {source = "builtin", Builtin = {}, Syndicator = {},
        Containers = {NewItemSetLog = function() return {} end},
        snapshots = {mail = {byIndex = {}, counts = {}, generation = 0},
            auctions = {byIndex = {}, counts = {}, generation = 0}},
        Store = {SetUsesSyndicator = function(on) h.usesSyndicator = on end},
        HasWarband = function() return false end}
    inv.Builtin.Start = function() inv.source = "builtin"; h.builtinStarted = true end
    e.GetTime = function() return h.now end
    e.wipe = function(t)
        for k in pairs(t) do
            if t == inv.snapshots.mail.byIndex or t == inv.snapshots.auctions.byIndex then
                h.stats.cleared = h.stats.cleared + 1
            end
            t[k] = nil
        end
    end
    e.pairs = function(t)
        local iter, state, key = pairs(t)
        return function(st, k)
            local nextKey, value = iter(st, k)
            if nextKey ~= nil then
                local current = h.characters[h.who]
                if current and (t == current.mail or t == current.auctions) then
                    h.stats.visits = h.stats.visits + 1
                    if h.onVisit then h.onVisit() end
                end
            end
            return nextKey, value
        end, state, key
    end
    local flux = {Inventory = inv, Cap = {hasAuctionHouse = true, hasLegacyAuctionHouse = legacy,
        hasModernAuctionHouse = not legacy}, Safecall = function(fn, ...) return fn(...) end,
        Timer = {After = function(delay, fn) h.timers[#h.timers + 1] = {at = h.now + delay, fn = fn} end},
        Events = {Register = function(event, fn)
            check(not h.events[event], "owned-list handler registers once"); h.events[event] = fn
        end}}
    e.C_Timer = {After = flux.Timer.After}
    local ns = {Flux = flux}
    assert(loadfile("Core/Engine/Scheduler.lua", "t", e))("_FluxUI", ns)
    flux.Scheduler.Register("inventory", function(tokens)
        for _, region in ipairs({"mail", "auctions"}) do
            if tokens[region] then
                h.pubs[region] = (h.pubs[region] or 0) + 1
                if h.onPublish then h.onPublish(region) end
            end
        end
    end)
    if installed ~= false then
        e.Syndicator = {Constants = {IsLegacyAH = legacy},
            API = {IsReady = function() return h.ready end,
                GetCurrentCharacter = function() return h.who end,
                GetCharacter = function(name) return h.characters[name] end},
            CallbackRegistry = {RegisterCallback = function(_, event, fn)
                check(not h.callbacks[event], "provider callback registers once"); h.callbacks[event] = fn
            end}}
    end
    assert(loadfile(source, "t", e))("_FluxUI", ns)
    local a = inv.Syndicator
    -- The harness scopes initialization to these two real list producers.
    a.RebuildAll = function() a.RebuildMail(); a.RebuildAuctions() end
    h.inv, h.adapter, h.flux, h.env, h.char = inv, a, flux, e, char
    function h:run(fn, ...)
        active = self
        return fn(...)
    end
    function h:frame(dt)
        self.now = self.now + (dt or 0)
        local due = self.timers; self.timers = {}
        for _, timer in ipairs(due) do
            if timer.at <= self.now then self:run(timer.fn) else self.timers[#self.timers + 1] = timer end
        end
    end
    function h:settle()
        for _ = 1, 10 do
            if #self.timers == 0 then return end
            local at = math.huge; for _, timer in ipairs(self.timers) do at = math.min(at, timer.at) end
            self:frame(math.max(0, at - self.now))
        end
        error("provider row fixture did not settle")
    end
    function h:callback(region, who)
        local key = region == "mail" and "MailCacheUpdate" or region == "auctions" and "AuctionsCacheUpdate" or region
        local fn = self.callbacks[key]; if fn then self:run(fn, nil, who or self.who) end
    end
    function h:direct(region)
        return self:run(region == "mail" and a.RebuildMail or a.RebuildAuctions)
    end
    function h:reset() self.stats = {rows = 0, cleared = 0, visits = 0}; self.pubs = {} end
    function h:resources()
        return size(self.callbacks) == 9 and size(self.events) == 1 and #self.timers == 0
            and not self.flux.Scheduler.HasPending()
    end
    h:run(a.Start); h:settle(); h:reset()
    return h
end

debug.sethook(function(_, current)
    if active and constructors[current] then
        local info = debug.getinfo(2, "S")
        if info and info.source == "@" .. source then active.stats.rows = active.stats.rows + 1 end
    end
end, "l")

local curves = {}
for _, region in ipairs({"mail", "auctions"}) do
    local h = boot(false); local snap = h.inv.snapshots[region]
    curves[region] = {}
    for op = 1, 500 do
        local before = h.stats.rows
        h.char[region][op] = record(10000 + op, 1)
        h:callback(region); h:settle()
        if op == 10 or op == 100 or op == 500 then
            curves[region][op] = {rows = h.stats.rows, this = h.stats.rows - before, visits = h.stats.visits}
            check(h.stats.rows == op, region .. " append constructors equal actual facts at " .. op)
            check(size(snap.byIndex) == op and snap.counts[10000 + op] == 1, region .. " append retains every fact")
            check(h.pubs[region] == op and h:resources(), region .. " publication cadence and resources stay stable")
        end
    end
    local oldMap, oldCounts, generation, rows = snap.byIndex, snap.counts, snap.generation, h.stats.rows
    h:callback(region); h:settle()
    check(snap.byIndex == oldMap and snap.counts == oldCounts and snap.generation == generation
        and h.stats.rows == rows and h.pubs[region] == 500, region .. " unchanged scan preserves maps and no row construction")
end

local cancel = {}
for _, n in ipairs({10, 100, 500}) do
    local h = boot(false)
    for i = 1, n do h.char.auctions[i] = record(20000 + i, 1) end
    h:direct("auctions"); h:reset()
    for op = 1, n do
        local before = h.stats.rows
        h.char.mail[#h.char.mail + 1] = table.remove(h.char.auctions, 1)
        h:callback("auctions"); h:callback("mail"); h:settle()
        if op == n then
            cancel[n] = {rows = h.stats.rows, this = h.stats.rows - before, visits = h.stats.visits}
            check(h.stats.rows == n * (n + 1) / 2, "index-shifting cancellation reuses accumulated mail rows " .. n)
            check(size(h.inv.snapshots.mail.byIndex) == n and size(h.inv.snapshots.auctions.byIndex) == 0,
                "cancellation retains all returned items and removes listings " .. n)
            check(h.pubs.mail == n and h.pubs.auctions == n and h:resources(), "cancellation publications and resources " .. n)
        end
    end
end

-- Removing a suffix does not shift the remaining provider indexes.
local suffix = boot(false)
for i = 1, 500 do suffix.char.auctions[i] = record(30000 + i, 1) end
suffix:direct("auctions"); suffix:reset()
for _ = 1, 500 do
    suffix.char.mail[#suffix.char.mail + 1] = table.remove(suffix.char.auctions)
    suffix:callback("auctions"); suffix:callback("mail"); suffix:settle()
end
check(suffix.stats.rows == 500 and suffix.stats.cleared == 0, "stable-index cancellation constructs only newly returned rows")

for _, client in ipairs({"retail", "forever", "era", "anniversary", "mists"}) do
 for _, baganator in ipairs({false, true}) do
  for _, region in ipairs({"mail", "auctions"}) do
    local h = boot(client ~= "retail" and client ~= "forever")
    if baganator then h.env.Baganator = {API = {}} end
    local label = client .. "/" .. tostring(baganator) .. "/" .. region
    local snap = h.inv.snapshots[region]
    h.char[region] = {record(100, 1), record(200, 2)}
    check(h:direct(region), label .. " explicit rebuild stays synchronous")
    local oldMap, oldCounts, generation, first, second = snap.byIndex, snap.counts, snap.generation,
        snap.byIndex[1], snap.byIndex[2]
    local input = {record(100, 1), record(200, 4), [7] = record(100, 3),
        [100000] = {itemID = "300", itemCount = 0, count = 9, link = "item:300"}, [8] = {itemID = "bad"}}
    h.char[region] = input; h:reset()
    h.onVisit = function()
        check(snap.byIndex == oldMap and snap.counts == oldCounts and snap.generation == generation
            and oldMap[1] == first and oldMap[2] == second,
            label .. " source iteration sees previous complete generation")
    end
    h:direct(region); h.onVisit = nil
    check(snap.byIndex ~= oldMap and snap.byIndex[1] == first and oldMap[2] == second and second.count == 2,
        label .. " changed generation reuses immutable matching row")
    check(h.stats.rows == 3 and h.stats.cleared == 0, label .. " changed list constructs only three changed rows")
    check(snap.byIndex[100000].count == 0 and snap.counts[300] == 0 and snap.counts[100] == 4
        and snap.counts[200] == 4 and snap.byIndex[8] == nil,
        label .. " sparse zero duplicate and invalid facts preserve original semantics")
    check(input[2].itemCount == 4 and input[100000].count == 9, label .. " provider records remain owned by provider")
    local stableMap, stableCounts, stableGeneration = snap.byIndex, snap.counts, snap.generation
    input[1].iconTexture, input[1].quality, input[1].expirationTime, input[1].auctionID = 9, 4, 500, 42
    check(not h:direct(region) and snap.byIndex == stableMap and snap.counts == stableCounts
        and snap.generation == stableGeneration, label .. " ignored metadata keeps existing equality")
    input[1], input[2] = input[2], input[1]; h:reset(); h:direct(region)
    check(snap.byIndex[1].itemID == 200 and snap.byIndex[2].itemID == 100
        and h.stats.rows == 2 and stableMap[1].itemID == 100, label .. " reordered rows preserve index meaning")
    local prior = snap.byIndex[1]; input[1].itemLink = "item:200:variant"; h:reset(); h:direct(region)
    check(h.stats.rows == 1 and snap.byIndex[1].link == "item:200:variant" and prior.link == "item:200",
        label .. " link changes replace only their immutable row")
    input[2], input[7] = nil, nil; h:direct(region)
    check(snap.counts[100] == nil and snap.byIndex[2] == nil and snap.byIndex[7] == nil,
        label .. " removed sparse rows disappear")
    h:reset(); h:callback(region, "Other-Realm"); h:settle()
    check((h.pubs[region] or 0) == 0 and h.stats.rows == 0, label .. " foreign-character callback is inert")
    h.characters["Other-Realm"] = {[region] = {record(400, 5)}}; h.who = "Other-Realm"
    check(h:direct(region) and snap.counts[400] == 5 and snap.counts[200] == nil,
        label .. " current-character switch replaces old facts synchronously")
    h.characters[h.who][region] = nil; h:direct(region)
    check(next(snap.byIndex) == nil and next(snap.counts) == nil, label .. " unavailable current list clears previous facts")
  end
 end
end

local cadence = boot(false)
cadence.char.mail[1] = record(500, 1); cadence.char.auctions[1] = record(600, 2)
cadence:callback("mail"); cadence:callback("auctions"); cadence:frame()
check(cadence.pubs.auctions == 1 and cadence.pubs.mail == nil, "auction next-frame and mail debounce remain separate")
cadence:frame(.19); check(cadence.pubs.mail == nil, "mail quiet time remains unchanged")
cadence:frame(.02); cadence:frame()
check(cadence.pubs.mail == 1 and cadence.inv.snapshots.mail.counts[500] == 1, "mail publishes after existing debounce")
cadence:reset()
for i = 1, 500 do cadence.char.mail[i] = record(40000 + i, 1); cadence:callback("mail") end
cadence:settle()
check(cadence.stats.rows == 500 and cadence.pubs.mail == 1, "one callback burst still coalesces to one complete publication")
cadence:reset(); for _ = 1, 500 do cadence:callback("mail") end; cadence:settle()
check(cadence.stats.rows == 0 and cadence.pubs.mail == nil, "unchanged callback burst constructs no rows and does not publish")

local absent = boot(false, false, false)
check(absent.adapter.Start() == false and size(absent.callbacks) == 0 and size(absent.events) == 0,
    "absent provider adds no list ownership")
local waiting = boot(false, false)
check(waiting.inv.source == "builtin" and size(waiting.callbacks) == 1 and size(waiting.events) == 0,
    "pending provider preserves builtin ownership")
waiting.ready = true; waiting:callback("Ready"); waiting:settle()
check(waiting.inv.source == "syndicator" and waiting.usesSyndicator and size(waiting.callbacks) == 10
    and size(waiting.events) == 1 and #waiting.timers == 0, "Ready handoff binds once and retains its single readiness callback")
waiting:callback("Ready"); waiting:run(waiting.adapter.Start); waiting:settle()
check(size(waiting.callbacks) == 10 and size(waiting.events) == 1 and #waiting.timers == 0
    and not waiting.flux.Scheduler.HasPending(), "duplicate readiness does not add ownership")
debug.sethook()
for _, region in ipairs({"mail", "auctions"}) do
    for _, n in ipairs({10, 100, 500}) do local c = curves[region][n]
        print(string.format("APPEND %s n=%d normalized=%d this=%d sourceVisits=%d", region, n, c.rows, c.this, c.visits))
    end
end
for _, n in ipairs({10, 100, 500}) do local c = cancel[n]
    print(string.format("CANCEL_SHIFT n=%d normalized=%d last=%d sourceVisits=%d", n, c.rows, c.this, c.visits))
end
print(string.format("CANCEL_SUFFIX n=500 normalized=%d cleared=%d", suffix.stats.rows, suffix.stats.cleared))
print(string.format("provider snapshot row reuse: %d checks, %d failures", checks, failures))
if failures > 0 then os.exit(1) end
