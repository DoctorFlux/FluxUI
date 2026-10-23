-- lua Inventory/_tmp_inventorylag_smoke.lua
-- Real scheduler, frame-driven sources, dispatch queue, and Syndicator adapter.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local checks = 0
local function eq(a, b, label)
    checks = checks + 1
    assert(a == b, label .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local function yes(value, label) eq(not not value, true, label) end
local families = {
    forever = { "1.16.0", 1, 16001 }, retail = { "12.0.1", 1, 120001 },
    era = { "1.15.9", 2, 11509 }, anniversary = { "2.5.6", 5, 20506 },
    wrath = { "3.4.3", 11, 30403 }, cata = { "4.4.2", 14, 40402 }, mists = { "5.5.4", 19, 50504 },
}
local function boot(family, syndicator)
    local s = { now = 10, timers = {}, frames = {}, events = {}, inbox = {}, slots = { [0] = {}, [1] = {} },
        calls = 0, loads = 0, reads = 0, headers = 0, inboxReads = 0, auctionReads = 0, writes = 0,
        size = 16, auctions = {}, syn = syndicator, callbacks = {}, legacy = family ~= "retail" and family ~= "forever" }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local Flux = { Cap = {}, Module = { Register = function() end } }
    local ns = { Flux = Flux }; s.env, s.flux = env, Flux
    env.SlashCmdList = {}; env.wipe = function(t) for k in pairs(t) do t[k] = nil end; return t end
    env.GetTime = function() return s.now end; env.time = function() return 100000 end
    env.debugprofilestop = function() return s.calls * (s.cost or 0) end
    local function charge() s.calls = s.calls + 1 end
    env.C_Timer = { After = function(delay, fn)
        s.timers[#s.timers + 1] = { at = s.now + math.max(delay, 0.001), fn = fn }
    end }; Flux.Timer = env.C_Timer
    env.CreateFrame = function()
        local f = { scripts = {}, events = {} }
        function f:SetScript(key, fn) self.scripts[key] = fn end
        function f:HookScript(key, fn) self.scripts[key] = fn end
        function f:RegisterEvent(key) self.events[key] = true end
        function f:RegisterUnitEvent(key) self.events[key] = true end
        function f:UnregisterEvent(key) self.events[key] = nil end
        s.frames[#s.frames + 1] = f; return f
    end
    Flux.Safecall = function(fn, ...) return fn(...) end
    Flux.Events = { Register = function(key, fn)
        s.events[key] = s.events[key] or {}; table.insert(s.events[key], fn)
    end, RegisterUnit = function(key, _, fn)
        s.events[key] = s.events[key] or {}; table.insert(s.events[key], fn)
    end }
    function s:event(key, ...)
        for _, fn in ipairs(self.events[key] or {}) do fn(key, ...) end
        for _, f in ipairs(self.frames) do if f.events[key] and f.scripts.OnEvent then f.scripts.OnEvent(f, key, ...) end end
    end
    function s:tick(dt)
        self.now = self.now + (dt or 0.016)
        local due = {}
        for i = #self.timers, 1, -1 do
            if self.timers[i].at <= self.now then due[#due + 1] = table.remove(self.timers, i) end
        end
        for _, t in ipairs(due) do t.fn() end
        local frames = {}; for i, f in ipairs(self.frames) do frames[i] = f end
        local before = self.calls
        for _, f in ipairs(frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f, dt or 0.016) end end
        self.maxFrame = math.max(self.maxFrame or 0, self.calls - before)
    end
    function s:advance(seconds) for _ = 1, math.ceil(seconds / 0.016) do self:tick() end end
    env.WOW_PROJECT_ID = families[family][2]
    env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC, env.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 1, 2, 5
    env.WOW_PROJECT_WRATH_CLASSIC, env.WOW_PROJECT_CATACLYSM_CLASSIC, env.WOW_PROJECT_MISTS_CLASSIC = 11, 14, 19
    env.GetBuildInfo = function() return families[family][1], "70000", "", families[family][3] end
    env.C_Item = { IsItemDataCachedByID = function() return false end,
        RequestLoadItemDataByID = function() s.loads = s.loads + 1 end }
    local function slots(bag) return (bag == 0 or bag == 1) and s.size or 0 end
    local function info(bag, slot)
        s.reads = s.reads + 1; local r = s.slots[bag] and s.slots[bag][slot]
        if r then return { itemID = r.itemID, stackCount = r.itemCount, hyperlink = "item:" .. r.itemID } end
    end
    if s.legacy then
        env.GetContainerNumSlots = slots
        env.GetContainerItemInfo = function(bag, slot)
            local r = info(bag, slot); if r then return 1, r.stackCount, false, 1, false, false, r.hyperlink, false, false, r.itemID end
        end
    else
        env.C_Container = { GetContainerNumSlots = slots, GetContainerItemInfo = info }
    end
    env.ATTACHMENTS_MAX_RECEIVE = 16
    env.GetInboxNumItems = function() s.inboxReads = s.inboxReads + 1; return #s.inbox end
    env.GetInboxHeaderInfo = function(i)
        charge(); s.headers = s.headers + 1; local mail = s.inbox[i]
        return nil, nil, "Sender", nil, nil, nil, 29, mail and (mail.expected or #mail)
    end
    env.GetInboxItem = function(i, slot)
        charge(); local rec = s.inbox[i] and s.inbox[i][slot]
        if rec then return "item", rec.itemID, nil, rec.itemCount end
    end
    env.GetInboxItemLink = function() error("blocking mail hyperlink lookup") end
    env.GetItemInfo = function() error("inventory capture must not load item metadata") end
    env.GetNumAuctionItems = function() return #s.auctions end
    env.GetAuctionItemInfo = function(_, i)
        charge(); s.auctionReads = s.auctionReads + 1; local r = s.auctions[i]
        return "item", 1, r.itemCount, 1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, r.itemID
    end
    env.GetAuctionItemLink = function() error("unnecessary auction hyperlink lookup") end
    env.C_AuctionHouse = { GetNumOwnedAuctions = function() return #s.auctions end,
        GetOwnedAuctionInfo = function(i)
            charge(); s.auctionReads = s.auctionReads + 1; local r = s.auctions[i]
            return { itemKey = { itemID = r.itemID }, quantity = r.itemCount, auctionID = i, status = 0 }
        end }
    local function loadFile(path)
        local pathRoot = arg[1] and path == arg[2] and arg[1] or root
        local file = assert(io.open(pathRoot .. path)); local src = file:read("*a"); file:close()
        local chunk
        if setfenv then chunk = assert(loadstring(src)); setfenv(chunk, env) else chunk = assert(load(src, path, "t", env)) end
        return chunk("_FluxUI", ns)
    end
    s.load = loadFile
    loadFile("Core/Client.lua"); loadFile("Core/API/Container.lua"); loadFile("Core/Engine/Scheduler.lua")
    loadFile("Inventory/Init.lua"); loadFile("Inventory/Containers.lua"); loadFile("Inventory/Index.lua")
    local Inv = Flux.Inventory; s.inv = Inv
    Flux.Cap.hasAuctionHouse, Flux.Cap.hasLegacyAuctionHouse = true, s.legacy
    local char = { bags = { s.slots[0], s.slots[1] }, mail = {} }; s.char = char
    Inv.Store = { UsesSyndicator = function() return s.syn end,
        SetUsesSyndicator = function(v) s.syn = v end,
        EnsureCurrentCharacter = function() return char end,
        GetCurrentCharacterName = function() return "Player-Realm" end,
        BindLive = function() end, MarkPending = function() s.writes = s.writes + 1 end }
    Inv.Builtin.Bank = { Refresh = function() end, IsOpen = function() return false end }
    Inv.Builtin.Equip = { Refresh = function() end, Invalidate = function() end }
    loadFile("Inventory/Builtin/Bags.lua"); loadFile("Inventory/Builtin/Mail.lua")
    loadFile("Inventory/Builtin/Auctions.lua"); loadFile("Inventory/Builtin/Watch.lua")
    if syndicator then
        env.Syndicator = { API = { IsReady = function() return true end,
            GetCurrentCharacter = function() return "Player-Realm" end, GetCharacter = function() return char end },
            Constants = { AllBagIndexes = { 0, 1 }, AllBankIndexes = {} }, CallbackRegistry = {} }
        function env.Syndicator.CallbackRegistry:RegisterCallback(key, fn) s.callbacks[key] = fn end
        Flux.Optional = { Get = function() return { loaded = true } end }
        loadFile("Inventory/Syndicator/Adapter.lua")
    end
    Inv.Start(); s:advance(9)
    function s:bag(id, count, slot, bag)
        bag, slot = bag or 0, slot or 1
        self.slots[bag][slot] = count > 0 and { itemID = id, itemCount = count } or nil
        if syndicator then self.callbacks.BagCacheUpdate(nil, "Player-Realm", { bags = { [bag] = true } })
        else self:event("BAG_UPDATE", bag); self:event("BAG_UPDATE_DELAYED") end
    end
    return s
end

for family in pairs(families) do
    for _, syn in ipairs({ false, true }) do
        local s = boot(family, syn); local Inv = s.inv
        -- Buying an auction / arrival of new mail while the mailbox is closed.
        s:event("MAIL_INBOX_UPDATE"); s:advance(2)
        eq(Inv.IsMailboxOpen(), false, family .. " mail notification cannot open mailbox")
        eq(s.inboxReads, 0, "closed mailbox never scanned")
        local lights, scans, heavyInFrame, scanContext = 0, 0, 0
        Inv.Register("lag.counts", function() lights = lights + 1 end, { tier = "light", sync = true, regions = { "bags" } })
        Inv.Register("lag.scan", function(ctx) scans = scans + 1; scanContext = ctx end, { tier = "scan", regions = { "bags", "mail" }, deferHeavy = true })
        -- Many attachments into bags, purchases, loot, crafting: light counts
        -- keep up, deferred changes union instead of losing the first item.
        s:event("MAIL_SHOW")
        for n = 1, 30 do s:bag(1000 + n, n, n <= 15 and n or n - 15, n <= 15 and 0 or 1); s:tick() end
        eq(lights, 30, "each bag transfer updates light listeners")
        eq(scans, 0, "no scan fan-out for each attachment")
        s:advance(0.25)
        eq(scans, 1, "one merged scan after mail burst")
        yes(scanContext.regions.bags, "deferred bags region retained")
        yes(scanContext.addedItemIDs[1001] and scanContext.addedItemIDs[1030], "identity changes retained across burst")
        yes(scanContext.dirtyBags[0] and scanContext.dirtyBags[1], "both dirty bags retained")
        eq(Inv.GetCount(1030), 30, "last transfer counted")
        eq(Inv.GetCount(1001), 1, "first transfer counted")
        s:advance(1)
        local before = scans
        for n = 1, 90 do s:bag(1030, 30 + n, 15, 1); s:tick() end
        yes(scans > before, "continuous transfers cannot starve scans")
        yes(scans - before <= 3, "continuous transfers remain batched")
        s:advance(1)
        eq(Inv.GetCount(1030), 120, "continuous transfer final count")
        -- Non-sync legacy listeners also receive a budgeted scan after light pulses.
        for n = 1, 9 do Inv.Register("lag.heavy" .. n, function() heavyInFrame = heavyInFrame + 1 end, { regions = { "bags" } }) end
        s:bag(1030, 2, 15, 1)
        for _ = 1, 60 do heavyInFrame = 0; s:tick(); yes(heavyInFrame <= 2, "at most two heavy listeners per frame") end
        -- Unregistration/forced delivery cancels stale queued work.
        local calls = 0
        Inv.Register("lag.cancel", function() calls = calls + 1 end, { regions = { "bags" }, deferHeavy = true })
        s:bag(1030, 1, 15, 1); s:tick(); Inv.Unregister("lag.cancel"); s:advance(1)
        eq(calls, 0, "unregistered callback cancelled")
        Inv.Register("lag.cancel", function() calls = calls + 1 end, { regions = { "bags" }, deferHeavy = true })
        s:bag(1030, 0, 15, 1); s:tick(); Inv.Notify({ bags = true, force = true }); s:advance(1)
        eq(calls, 1, "forced callback cancels older pending delivery")
        -- Move/split/bank/delete/refill preserves aggregate totals and locations.
        s:bag(1001, 0, 1); s:bag(1001, 1, 16, 1); s:advance(0.5)
        eq(Inv.GetCount(1001), 1, "cross-bag move total")
        eq(Inv.snapshots.bags.byBag[1][16].itemID, 1001, "cross-bag move location")
        s:bag(1001, 3, 16, 1); s:bag(1001, 2, 1); s:advance(0.5)
        eq(Inv.GetCount(1001), 5, "split/stack total")
        s:bag(1001, 0, 16, 1); s:bag(1001, 0, 1); s:advance(0.5)
        eq(Inv.GetCount(1001), 0, "banked/deleted items absent")
        s:bag(1001, 20, 1); s:advance(0.5); eq(Inv.GetCount(1001), 20, "refill total")
        -- Light notifications during a bank move still owe every scan listener
        -- a pass, even when no later scan-tier event arrives.
        local bankOpen = Inv.IsBankOpen
        Inv.IsBankOpen = function() return true end
        local beforeScans = scans
        s:bag(1001, 19, 1); s:advance(0.5)
        eq(Inv.GetCount(1001), 19, "bank-open light count refresh")
        yes(scans > beforeScans, "bank-open light reaches scan listener")
        Inv.IsBankOpen = bankOpen
        -- Count-only and mail pulses cannot downgrade an earlier identity
        -- change or erase unknown/full-rescan metadata.
        local merged
        Inv.Register("lag.merge", function(ctx) merged = ctx end, { regions = { "bags", "mail" }, deferHeavy = true })
        s:bag(9001, 1, 1); s:tick(); s:bag(9001, 2, 1); s:tick()
        Inv.Notify({ mail = true }); s:advance(0.5)
        eq(merged.changeKind, "identityChanged", "count-only cannot erase identity change")
        yes(merged.regions.bags and merged.regions.mail, "mail cannot erase pending bag region")
        yes(merged.changedItemIDs[9001], "mail cannot erase changed item IDs")
        s:bag(9001, 3, 1); s:tick(); Inv.Notify({ mail = true, force = true })
        yes(merged.regions.bags and merged.regions.mail, "forced mail preserves queued bag region")
        yes(merged.changedItemIDs[9001], "forced mail preserves queued changed IDs")
        Inv.Notify({ bags = true }); Inv.Notify({ mail = true }); s:advance(0.5)
        eq(merged.changedItemIDs, nil, "unknown change set stays unknown")
        -- BAG_UPDATE_DELAYED used to invoke permanent settle callbacks inline
        -- and then again when the outstanding settle timer fired.
        s:advance(1)
        local settles = 0
        Inv.RegisterStormSettled("lag.settle", function() settles = settles + 1 end)
        for _ = 1, 10 do Inv.NotifyBagStorm(); Inv.EndBagStorm() end
        eq(settles, 0, "settle callback never blocks bag event")
        s:advance(0.5); eq(settles, 1, "one settle callback per burst")
        if syn then
            s.char.mail = { { itemID = 117, itemCount = 20 } }
            for _ = 1, 100 do s.callbacks.MailCacheUpdate(nil, "Player-Realm") end
            yes(#s.timers < 10, "Syndicator mail uses one pending timer")
            s:advance(1); eq(Inv.snapshots.mail.counts[117], 20, "Syndicator mail published")
        else
            local gen, reads = Inv.snapshots.bags.generation, s.reads
            for _ = 1, 100 do Inv.Builtin.Bags.Refresh() end
            eq(Inv.snapshots.bags.generation, gen, "clean bag refresh leaves generation intact")
            eq(s.reads, reads, "clean refresh never walks bags")
        end
        s:event("MAIL_CLOSED"); s:advance(1)
        eq(Inv.IsMailboxOpen(), false, "mail close clears open hold")
    end
    -- Full native inbox, uncached auction attachments, burst updates, missing
    -- IDs and stale headers. Exercise real OnUpdate work, not just timer counts.
    local s = boot(family, false); local Inv = s.inv
    for m = 1, 50 do s.inbox[m] = {}; for a = 1, 16 do s.inbox[m][a] = { itemID = 117, itemCount = 2 } end end
    s:event("MAIL_SHOW"); s:tick(0.16)
    eq(Inv.snapshots.mail.generation, 0, "partial full inbox never published")
    s:advance(1)
    eq(Inv.snapshots.mail.counts[117], 1600, "uncached inbox IDs counted without metadata")
    eq(s.loads, 0, "mail capture never requests item data")
    yes(s.maxFrame <= 48, "inbox API calls bounded per frame")
    local gen, reads = Inv.snapshots.mail.generation, s.inboxReads
    s:advance(4); eq(s.inboxReads, reads, "no uncached-item retry loop")
    for _ = 1, 100 do s:event("MAIL_INBOX_UPDATE") end
    s:advance(1)
    eq(s.inboxReads - reads, 1, "inbox event burst scans once")
    eq(Inv.snapshots.mail.generation, gen, "unchanged mail does not republish")
    reads = s.inboxReads
    local calls = s.calls
    for n = 1, 100 do
        s.inbox[1][1].itemCount = n
        s:event("MAIL_INBOX_UPDATE"); s:tick()
    end
    s:advance(1)
    yes(s.inboxReads - reads <= 4, "mail take-all across frames coalesces scans")
    yes(s.calls - calls < 1200, "mail take-all does not walk full inbox per event")
    eq(Inv.snapshots.mail.counts[117], 1698, "mail burst publishes latest quantities")
    -- A take shifts indexes while an incremental scan is in flight.
    s:event("MAIL_INBOX_UPDATE"); s:tick(0.16)
    s.inbox = { { { itemID = 159, itemCount = 7 } } }; s:event("MAIL_INBOX_UPDATE"); s:advance(1)
    eq(Inv.snapshots.mail.counts[159], 7, "interrupted scan restarts on current inbox")
    eq(Inv.snapshots.mail.counts[117], nil, "old inbox scan cannot overwrite new view")
    s.inbox = { { expected = 1 } }; s:event("MAIL_INBOX_UPDATE"); reads = s.inboxReads; s:advance(6)
    yes(s.inboxReads - reads <= 3, "missing mail IDs get bounded retries")
    eq(Inv.snapshots.mail.counts[159], 7, "incomplete API data preserves last complete view")
    reads = s.inboxReads; s:advance(6); eq(s.inboxReads, reads, "stale header cannot rescan forever")
    s.inbox = {}; s:event("MAIL_INBOX_UPDATE"); s:event("MAIL_CLOSED"); s:advance(1)
    eq(next(Inv.snapshots.mail.counts), nil, "last take before close persists empty inbox")
    -- Closing/reopening cancels the previous scan generation.
    s.inbox = { { { itemID = 118, itemCount = 1 } } }; s:event("MAIL_SHOW"); s:event("MAIL_CLOSED")
    s.inbox = { { { itemID = 2455, itemCount = 3 } } }; s:event("MAIL_SHOW"); s:advance(1)
    eq(Inv.snapshots.mail.counts[2455], 3, "rapid reopen keeps new inbox")
    eq(Inv.snapshots.mail.counts[118], nil, "old close cannot overwrite reopened inbox")
    -- Time budget, in addition to the call-count limit.
    s.cost, s.maxFrame = 0.4, 0
    s.inbox = {}; for m = 1, 5 do s.inbox[m] = { { itemID = 1251, itemCount = 1 } } end
    s:event("MAIL_INBOX_UPDATE"); s:advance(1)
    yes(s.maxFrame <= 3, "slow inbox APIs yield at one millisecond")
    eq(Inv.snapshots.mail.counts[1251], 5, "budgeted slow inbox eventually completes")
    s:event("MAIL_CLOSED"); s:advance(1); s.cost, s.maxFrame = 0, 0
    -- Auction listing updates may fire repeatedly on purchase. Both old and
    -- modern AH APIs must batch and yield without GetItemInfo or hyperlinks.
    for i = 1, 200 do s.auctions[i] = { itemID = 117, itemCount = 2 } end
    s:event("AUCTION_HOUSE_SHOW")
    for _ = 1, 100 do s:event(s.legacy and "AUCTION_OWNED_LIST_UPDATE" or "OWNED_AUCTIONS_UPDATED") end
    s:advance(1)
    eq(s.auctionReads, 200, "auction update burst scans once")
    yes(s.maxFrame <= 32, "auction API reads bounded per frame")
    eq(Inv.snapshots.auctions.counts[117], 400, "auction totals complete")
    gen = Inv.snapshots.auctions.generation
    s:event("OWNED_AUCTIONS_UPDATED"); s:advance(1)
    eq(Inv.snapshots.auctions.generation, gen, "unchanged auctions never republished")
    s:event("AUCTION_HOUSE_CLOSED"); reads = s.auctionReads; s:event("OWNED_AUCTIONS_UPDATED"); s:advance(1)
    eq(s.auctionReads, reads, "closed auction house never scanned")
    -- Exercise the actual binding-extras inventory callback without creating
    -- secure UI hosts. Quantity changes must not recompile all binding macros.
    local file = assert(io.open(root .. "Binding/Core/Apply.lua")); local source = file:read("*a"); file:close()
    local first = assert(source:find("-- Bag quantities do not change", 1, true))
    local last = assert(source:find("local regen = CreateFrame", first, true))
    local extra = { type = "item", id = 117 }
    local all = { test = { forms = { base = { macro = { extras = { extra } } } } } }
    local dirty, apply, available, equipped = 0, 0, true, 111
    local db = { All = function() return all end, IsMacroExtraAvailable = function() return available end }
    s.env.GetInventoryItemID = function() return equipped end
    local body = "local ns, DB, MarkPlanDirty, ScheduleApply = ...\n" .. source:sub(first, last - 1)
    local chunk
    if setfenv then chunk = assert(loadstring(body)); setfenv(chunk, s.env) else chunk = assert(load(body, "extras callback", "t", s.env)) end
    chunk({ Flux = s.flux }, db, function() dirty = dirty + 1 end, function() apply = apply + 1 end)
    s:bag(117, 20); s:advance(0.5); dirty, apply = 0, 0
    for n = 1, 30 do s:bag(117, n); s:tick() end
    s:advance(0.5); eq(apply, 0, "multicast counts do not recompile bindings")
    available = false; s:bag(117, 0); s:advance(0.5); eq(apply, 1, "depleted multicast extra recompiles")
    available = true; s:bag(117, 2); s:advance(0.5); eq(apply, 2, "refilled multicast extra recompiles")
    extra.type, extra.id = "slot", 13
    s.inv.Notify({ equip = true }); s:advance(0.5); apply = 0
    equipped = 222; s.inv.Notify({ equip = true }); s:advance(0.5)
    eq(apply, 1, "equipped extra replacement recompiles")
    eq(dirty > 0, true, "binding plan invalidated for actual changes")
    print(family .. " inventory/mail/AH pipeline passed (built-in + Syndicator)")
end
print("Inventory lag smoke passed: " .. checks .. " checks")
