-- Real Store, Mail, Auctions and Syndicator adapter; native APIs/frames are mocked.
-- Operation counts do not measure native client timing, rendering or secure behavior.
local sources = { mail = "Inventory/Builtin/Mail.lua", auctions = "Inventory/Builtin/Auctions.lua" }
local measureOnly = false
local index = 1
while arg and index <= #arg do
    local flag = arg[index]
    if flag == "--measure" then
        measureOnly = true
    elseif flag == "--mail-source" or flag == "--auction-source" then
        index = index + 1
        sources[flag == "--mail-source" and "mail" or "auctions"] = assert(arg[index], flag .. " requires a path")
    else
        error("unknown argument: " .. tostring(flag))
    end
    index = index + 1
end
local checks, failures = 0, {}
local function check(value, message)
    checks = checks + 1
    if not value then failures[#failures + 1] = message end
end

local function harness(region, modern)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local h = { now = 0, events = {}, callbacks = {}, frames = {}, ready = false,
        reads = 0, notifications = 0, requests = 0, queries = 0, binds = 0,
        size = region == "mail" and 8 or 70, itemCount = 3, missing = false }
    env.UnitName = function() return "Test" end
    env.GetNormalizedRealmName = function() return "Realm" end
    env.GetTime = function() return h.now end
    env.time = function() return 1000 end
    env.CreateFrame = function()
        local frame = { scripts = {} }
        function frame:SetScript(kind, fn) self.scripts[kind] = fn end
        function frame:RegisterEvent() end
        function frame:UnregisterEvent() end
        h.frames[#h.frames + 1] = frame
        return frame
    end
    env.Enum = { PlayerInteractionType = { Auctioneer = 1, MailInfo = 2 }, AuctionStatus = { Active = 1 } }
    env.GetInboxNumItems = function() h.reads = h.reads + 1; return h.size end
    env.GetInboxHeaderInfo = function()
        h.reads = h.reads + 1
        return nil, nil, nil, nil, nil, nil, 30, 1
    end
    env.GetInboxItem = function(_, slot)
        h.reads = h.reads + 1
        if slot == 1 and not h.missing then return "Native", 111, 1, h.itemCount, 1 end
    end
    env.GetNumAuctionItems = function() h.reads = h.reads + 1; return h.size end
    env.GetOwnerAuctionItems = function() h.queries = h.queries + 1 end
    env.GetAuctionItemInfo = function()
        h.reads = h.reads + 1
        local info = { "Native", 1, h.itemCount, 1 }
        info[17] = 111
        return table.unpack(info, 1, 17)
    end
    env.C_AuctionHouse = {
        QueryOwnedAuctions = function() h.queries = h.queries + 1 end,
        GetNumOwnedAuctions = function() h.reads = h.reads + 1; return h.size end,
        GetOwnedAuctionInfo = function(i)
            h.reads = h.reads + 1
            return { itemKey = { itemID = 111 }, quantity = h.itemCount, status = 1, auctionID = i }
        end,
    }
    local inv = { Builtin = {}, Syndicator = {}, Containers = { NewItemSetLog = function() return {} end },
        snapshots = { [region] = { byIndex = {}, counts = {}, generation = 0 } },
        HasWarband = function() return false end,
        Notify = function() h.notifications = h.notifications + 1 end }
    local ns = { Flux = { Inventory = inv,
        Cap = { hasModernAuctionHouse = modern, hasLegacyAuctionHouse = not modern },
        Scheduler = { Request = function() h.requests = h.requests + 1 end },
        Events = { Register = function(event, fn)
            assert(not h.events[event], "duplicate native event registration")
            h.events[event] = fn
        end } } }
    for _, path in ipairs({ "Inventory/Store.lua", sources[region], "Inventory/Syndicator/Adapter.lua" }) do
        assert(loadfile(path, "t", env))("_FluxUI", ns)
    end
    local module = region == "mail" and inv.Builtin.Mail or inv.Builtin.Auctions
    inv.Builtin.Start = function() inv.source = "builtin"; module.Start() end
    inv.Syndicator.RebuildAll = function()
        h.binds = h.binds + 1
        if region == "mail" then inv.Syndicator.RebuildMail() else inv.Syndicator.RebuildAuctions() end
    end
    function h.installProvider(empty)
        h.character = { [region] = empty and {} or { { itemID = 222, itemCount = 99 } } }
        env.Syndicator = { API = {
            IsReady = function() return h.ready end,
            GetCurrentCharacter = function() return "Test-Realm" end,
            GetCharacter = function() return h.character end,
        }, CallbackRegistry = { RegisterCallback = function(_, event, fn)
            assert(not h.callbacks[event], "duplicate provider callback registration")
            h.callbacks[event] = fn
        end } }
    end
    function h.fire(event, ...)
        if h.events[event] then h.events[event](event, ...) end
    end
    function h.open()
        if region == "mail" then h.fire("MAIL_SHOW")
        elseif modern then h.fire("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", 1)
        else h.fire("AUCTION_HOUSE_SHOW") end
    end
    function h.close()
        if region == "mail" then h.fire("MAIL_CLOSED") else h.fire("AUCTION_HOUSE_CLOSED") end
    end
    function h.active()
        local n = 0
        for _, frame in ipairs(h.frames) do if frame.scripts.OnUpdate then n = n + 1 end end
        return n
    end
    function h.step(seconds)
        h.now = h.now + seconds
        for _, frame in ipairs(h.frames) do
            local fn = frame.scripts.OnUpdate
            if fn then fn(frame) end
        end
    end
    function h.drain()
        for _ = 1, 20 do
            if h.active() == 0 then return end
            h.step(1)
        end
        error("scan failed to finish within 20 mock frames")
    end
    function h.resetCounts() h.reads, h.notifications, h.requests, h.queries = 0, 0, 0, 0 end
    h.inv, h.module, h.env = inv, module, env
    return h
end

for _, config in ipairs({ { "mail", false }, { "auctions", false }, { "auctions", true } }) do
    local region, modern = config[1], config[2]
    local name = region .. (region == "auctions" and (modern and "-modern" or "-legacy") or "")
    -- Absent and pending providers keep standalone facts, debounce and close behavior.
    for _, pending in ipairs({ false, true }) do
        local h = harness(region, modern)
        local inv = h.inv
        if pending then
            h.installProvider(false); inv.Syndicator.Start()
        else
            check(inv.Syndicator.Start() == false, name .. " absent provider remains retryable")
            inv.Builtin.Start()
        end
        local label = name .. (pending and " pending" or " standalone")
        check(inv.source == "builtin" and not inv.Store.UsesSyndicator(), label .. " built-in source owns facts")
        h.open(); h.step(0.1)
        check(h.reads == 0 and h.active() == 1, label .. " debounce preserves quiet time")
        h.drain()
        local snap = inv.snapshots[region]
        check(snap.counts[111] == h.size * 3 and h.notifications == 1, label .. " complete scan published once")
        local saved = inv.Store.GetDB().Characters["Test-Realm"]
        check(saved and #saved[region] == h.size, label .. " standalone ledger persists complete region")
        local generation = snap.generation
        h.module.Refresh(); h.drain()
        check(snap.generation == generation and h.notifications == 1, label .. " unchanged scan does not republish")
        h.itemCount = 4
        h.module.Refresh(); h.close(); h.resetCounts(); h.drain()
        if region == "mail" then
            check(snap.counts[111] == h.size * 4 and h.notifications == 1, label .. " mailbox close completes final pending scan")
        else
            check(h.reads == 0 and h.active() == 0 and snap.counts[111] == h.size * 3,
                label .. " auction close cancels pending scan")
        end
    end

    -- A Ready handoff must retire work queued before its first frame or mid-scan.
    for _, partial in ipairs({ false, true }) do
        for _, empty in ipairs({ false, true }) do
            local h = harness(region, modern)
            local inv = h.inv
            inv.Builtin.Start()
            local saved = inv.Store.EnsureCurrentCharacter()
            local previousSaved = saved[region]
            h.open()
            if partial then h.step(1) end
            local label = name .. (partial and " partial" or " queued") .. (empty and " empty-provider" or " provider")
            check(h.active() == 1 and h.notifications == 0, label .. " scan is pending without partial publication")
            check(not partial or h.reads > 0, label .. " partial case executes native reads before handoff")
            h.installProvider(empty); inv.Syndicator.Start()
            check(inv.source == "builtin" and h.callbacks.Ready, label .. " pending Ready retains source")
            h.ready = true; h.callbacks.Ready()
            local snap = inv.snapshots[region]
            check(inv.source == "syndicator" and inv.Store.UsesSyndicator() and h.binds == 1,
                label .. " real adapter hands off ownership")
            check(snap.counts[111] == nil and (empty and next(snap.counts) == nil or not empty and snap.counts[222] == 99),
                label .. " provider facts replace old region")
            local generation = snap.generation
            h.resetCounts(); h.step(0.01)
            local activeAfterFirst = h.active()
            h.drain()
            print(string.format("%s nativeReads=%d notifications=%d generationDelta=%d activeAfterFirst=%d providerCount=%s builtinCount=%s",
                label, h.reads, h.notifications, snap.generation - generation, activeAfterFirst,
                tostring(snap.counts[222]), tostring(snap.counts[111])))
            check(h.reads == 0 and h.notifications == 0 and h.requests == 0, label .. " stale scan does no work or publication")
            check(activeAfterFirst == 0, label .. " stale scan retires on its first callback")
            check(region ~= "mail" or h.module.IsOpen(), label .. " canceling scan preserves open mailbox state")
            check(snap.generation == generation and snap.counts[111] == nil
                and (empty and next(snap.counts) == nil or not empty and snap.counts[222] == 99),
                label .. " provider snapshot remains intact")
            check(saved[region] == previousSaved, label .. " handoff leaves old standalone ledger intact")
            h.resetCounts(); h.module.Refresh(); h.step(1)
            check(h.reads == 0 and h.active() == 0 and h.notifications == 0, label .. " stale refresh cannot restart native scan")
            if region == "mail" then
                check(inv.Syndicator.RebuildMail() == false and snap.counts[111] == nil,
                    label .. " unchanged provider fingerprint cannot leave stale native facts")
            end
            h.character[region] = { { itemID = 333, itemCount = 17 } }
            h.callbacks[region == "mail" and "MailCacheUpdate" or "AuctionsCacheUpdate"](nil, "Test-Realm")
            check(snap.counts[333] == 17 and snap.counts[222] == nil and snap.counts[111] == nil and h.requests == 1,
                label .. " future provider updates remain responsive")
            h.callbacks.Ready(); inv.Syndicator.Start(); h.module.Start()
            check(h.binds == 1 and h.active() == 0, label .. " duplicate readiness does not restart scan")
        end
    end

    local readyFirst = harness(region, modern)
    readyFirst.installProvider(false); readyFirst.ready = true; readyFirst.inv.Syndicator.Start()
    readyFirst.module.Start(); readyFirst.module.Refresh(); readyFirst.open(); readyFirst.step(1)
    check(next(readyFirst.events) == nil and readyFirst.reads == 0 and readyFirst.active() == 0,
        name .. " already-ready provider never starts native region")
end

-- Incomplete standalone mail still retries twice and never publishes partial data.
local retry = harness("mail", false)
retry.inv.Builtin.Start(); retry.size = 1; retry.missing = true; retry.open(); retry.drain()
check(retry.reads == 42 and retry.notifications == 0 and retry.active() == 0,
    "standalone missing attachments stop after three 14-read attempts without publication")
retry.missing = false; retry.fire("MAIL_INBOX_UPDATE"); retry.drain()
check(retry.inv.snapshots.mail.counts[111] == 3 and retry.notifications == 1,
    "new inbox event recovers after exhausted incomplete retries")

for _, mode in ipairs({ "retry", "force-close" }) do
    local h = harness("mail", false)
    h.inv.Builtin.Start(); h.size = 1
    if mode == "retry" then h.missing = true end
    h.open()
    if mode == "retry" then h.step(1) else h.close() end
    check(h.active() == 1 and h.notifications == 0, mode .. " mail scan is queued")
    h.installProvider(false); h.inv.Syndicator.Start(); h.ready = true; h.callbacks.Ready()
    local snap = h.inv.snapshots.mail
    local generation = snap.generation
    h.resetCounts(); h.step(0.01)
    check(h.active() == 0 and h.reads == 0 and h.notifications == 0 and snap.generation == generation
        and snap.counts[222] == 99, mode .. " handoff cancels before due time without overwriting provider")
    check(h.module.IsOpen() == (mode == "retry"), mode .. " handoff preserves mailbox open/closed state")
end

print(string.format("deferred inventory handoff: %d checks, %d failures; desktop operation counts only", checks, #failures))
for _, message in ipairs(failures) do print("FAIL " .. message) end
if not measureOnly then assert(#failures == 0, "deferred inventory handoff regressions") end
