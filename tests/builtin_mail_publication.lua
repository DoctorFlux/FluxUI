-- Real Store/Mail; native source reads and frame scheduling isolated.
-- Optional argument: alternate Inventory/Builtin/Mail.lua for baseline replay.
local source = arg[1] or "Inventory/Builtin/Mail.lua"
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local allocationLines = {}
local file = assert(io.open(source, "r")); local line = 0
for text in file:lines() do
    line = line + 1
    if text:find("into[#into + 1] = {", 1, true) then allocationLines[line] = "capture" end
    if text:find("snap.byIndex[i] = {", 1, true) or text:find("row = { itemID = rec.itemID", 1, true) then
        allocationLines[line] = "normalized"
    end
end
file:close()
local function item(id, n) return {id = id, n = n or 1, texture = 1, quality = 1} end
local function mail(items, money) return {items = items or {}, money = money or 0, days = 29} end
local function countRows(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
local function many(count)
    local inbox = {}
    for m = 1, count do
        local entries = {}
        for a = 1, 16 do entries[a] = item(10000 + (m - 1) * 16 + a) end
        inbox[m] = mail(entries)
    end
    return inbox
end

local function boot()
    local e = setmetatable({}, {__index = _G}); e._G = e
    local h = {now = 0, cost = 0, nativeCost = 0, frames = {}, events = {}, hooks = {}, inbox = {}, pubs = 0}
    local inv = {Builtin = {}, snapshots = {mail = {byIndex = {}, counts = {}, generation = 0}}}
    local function emptyStats()
        return {capture = 0, normalized = 0, formats = 0, joinedChars = 0, cleared = 0,
            maxNormalized = 0, maxReads = 0, reads = 0, staleReads = 0, notifications = 0}
    end
    h.stats = emptyStats()
    e.UnitName = function() return "Main" end
    e.GetNormalizedRealmName = function() return "Realm" end
    e.GetTime = function() return h.now end
    e.time = function() return 1000 end
    e.debugprofilestop = function() return h.cost end
    e.ATTACHMENTS_MAX_RECEIVE = 16
    e.table = setmetatable({concat = function(t, sep)
        local out = table.concat(t, sep)
        if sep == ";" then h.stats.formats = h.stats.formats + #t; h.stats.joinedChars = h.stats.joinedChars + #out end
        return out
    end}, {__index = table})
    e.wipe = function(t)
        for k in pairs(t) do
            if t == inv.snapshots.mail.byIndex then h.stats.cleared = h.stats.cleared + 1 end
            t[k] = nil
        end
        return t
    end
    e.CreateFrame = function()
        local f = {scripts = {}, events = {}}
        function f:SetScript(k, fn) self.scripts[k] = fn end
        function f:RegisterEvent(k) self.events[k] = true end
        function f:UnregisterEvent(k) self.events[k] = nil end
        h.frames[#h.frames + 1] = f
        return f
    end
    function h:read(kind)
        if self.invalidated then self.stats.staleReads = self.stats.staleReads + 1 end
        if kind ~= "num" then self.frameReads = self.frameReads + 1; self.stats.reads = self.stats.reads + 1 end
        self.cost = self.cost + self.nativeCost
        if self.onRead then self:onRead(kind) end
    end
    e.GetInboxNumItems = function() local n = #h.inbox; h:read("num"); return n end
    e.GetInboxHeaderInfo = function(index)
        local m = h.inbox[index]; h:read("header")
        if m then return nil,nil,"Auction House","Delivery",m.money,0,m.days,m.expected or countRows(m.items) end
    end
    e.GetInboxItem = function(index, slot)
        local m = h.inbox[index]; local rec = m and m.items[slot]; h:read("item")
        if rec then return "Item",rec.id,rec.texture,rec.n,rec.quality end
    end
    e.GetInboxItemLink = function() error("mail capture must not request hyperlinks") end
    e.SendMail, e.ReturnInboxItem = function() end, function() end
    e.GetSendMailItem = function(slot) if slot == 1 then return "Sent",999,1,2,1 end end
    e.hooksecurefunc = function(name, fn) h.hooks[name] = fn end
    inv.Notify = function()
        h.pubs = h.pubs + 1; h.stats.notifications = h.stats.notifications + 1
        local expected, n = {}, 0
        for _, m in ipairs(h.inbox) do for _, rec in pairs(m.items) do
            if rec.id then n = n + 1; expected[rec.id] = (expected[rec.id] or 0) + rec.n end
        end end
        local snap = inv.snapshots.mail
        check(countRows(snap.byIndex) == n, "publication exposes one complete normalized generation")
        for id, count in pairs(expected) do check(snap.counts[id] == count, "publication complete count " .. id) end
        for id in pairs(snap.counts) do check(expected[id] ~= nil, "publication removes old count " .. id) end
    end
    local ns = {Flux = {Inventory = inv, Events = {Register = function(event, fn) h.events[event] = fn end}}}
    assert(loadfile("Inventory/Store.lua", "t", e))("_FluxUI", ns)
    assert(loadfile(source, "t", e))("_FluxUI", ns)
    inv.Store.EnsureCurrentCharacter(); inv.Builtin.Mail.Start()
    h.inv, h.env, h.store, h.module = inv, e, inv.Store, inv.Builtin.Mail
    function h:event(event)
        local fn = self.events[event]; if fn then fn(event) end
        for _, f in ipairs(self.frames) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event) end end
    end
    function h:tick()
        self.now = self.now + .02; self.frameReads = 0; self.frameNormalized = 0; self.invalidated = false
        local active = false
        debug.sethook(function(_, current)
            local kind = allocationLines[current]
            if not kind then return end
            local info = debug.getinfo(2, "S")
            if info and info.source == "@" .. source then
                self.stats[kind] = self.stats[kind] + 1
                if kind == "normalized" then self.frameNormalized = self.frameNormalized + 1 end
            end
        end, "l")
        for _, f in ipairs(self.frames) do if f.scripts.OnUpdate then active = true; f.scripts.OnUpdate(f, .02) end end
        debug.sethook()
        self.stats.maxNormalized = math.max(self.stats.maxNormalized, self.frameNormalized)
        self.stats.maxReads = math.max(self.stats.maxReads, self.frameReads)
        return active
    end
    function h:drain()
        for _ = 1, 10000 do if not self:tick() then return end end
        error("mail publication fixture did not settle")
    end
    function h:reset() self.stats = emptyStats() end
    h:event("MAIL_SHOW"); h:drain() -- First empty generation remains a publication.
    return h
end

local h = boot()
check(h.pubs == 1 and h.inv.snapshots.mail.generation == 1, "first empty refresh still publishes")
local stableRegion = h.inv.snapshots.mail
local originalMail = h.store.GetCurrentCharacter().mail
h.onRead = function(state)
    check(stableRegion.generation == 1 and next(stableRegion.byIndex) == nil and next(stableRegion.counts) == nil
        and state.store.GetCurrentCharacter().mail == originalMail,
        "source getter readers see only the previous complete generation")
end
h.inbox = many(100); h:reset(); h:event("MAIL_INBOX_UPDATE"); h:drain()
h.onRead = nil
local arrival = h.stats
check(arrival.reads == 1700 and arrival.maxReads <= 48, "native source scan retains 48-read bound")
check(arrival.normalized == 1600 and arrival.maxNormalized <= 48, "normalization is prepared within scan frames")
check(arrival.formats == 0 and arrival.joinedChars == 0, "complete generation needs no full-list fingerprint")
check(h.inv.snapshots.mail == stableRegion, "snapshot region identity retained")
local oldMap, oldCounts = stableRegion.byIndex, stableRegion.counts
h:reset(); for _ = 1, 5 do h:event("MAIL_INBOX_UPDATE"); h:drain() end
local unchanged = h.stats
check(unchanged.notifications == 0 and stableRegion.byIndex == oldMap and stableRegion.counts == oldCounts,
    "unchanged visits keep maps and publication cadence")
check(unchanged.normalized == 0 and unchanged.formats == 0, "unchanged visits allocate no normalized rows or fingerprint fields")

-- ID/count equality remains metadata-insensitive. A later real count change
-- must still commit freshly captured metadata for every persisted attachment.
local saved = h.store.GetCurrentCharacter().mail
h.inbox[1].items[1].texture = 7; h.inbox[1].items[1].quality = 4; h.inbox[1].days = 28
h:reset(); h:event("MAIL_INBOX_UPDATE"); h:drain()
check(h.stats.notifications == 0 and h.store.GetCurrentCharacter().mail == saved, "metadata-only changes retain original equality")
h.inbox[1].items[2].n = 2; h:reset(); h:event("MAIL_INBOX_UPDATE"); h:drain()
local changed = h.stats
check(changed.normalized == 1 and changed.maxNormalized <= 48, "one changed stack reuses identical normalized rows")
check(stableRegion.byIndex ~= oldMap and oldMap[2].count == 1 and stableRegion.byIndex[2].count == 2,
    "completed map swaps atomically without rewriting the old generation")
check(changed.cleared == 0 and changed.formats == 0, "publication does not clear or fingerprint whole lists")
saved = h.store.GetCurrentCharacter().mail
check(saved[1].iconTexture == 7 and saved[1].quality == 4 and saved[1].expirationTime == 1000 + 28*86400,
    "real change preserves current full-list metadata")
h.inbox = {mail({}, 100), mail({}, 20)}; h:reset(); h:event("MAIL_INBOX_UPDATE"); h:drain()
local money = h.stats
check(money.reads == 2 and money.cleared == 0 and next(stableRegion.counts) == nil,
    "last two money-only messages remove attachments without whole-map clearing")
h.inbox[1].money = 0; h:reset(); h:event("MAIL_INBOX_UPDATE"); h:event("MAIL_CLOSED"); h:drain()
check(h.stats.notifications == 0, "money-only completion keeps existing item publication semantics")

-- Sparse final slot, incomplete retries and closing/reopening retain generations.
local small = boot(); small.inbox = {mail({[16] = item(700, 7)})}
small:event("MAIL_INBOX_UPDATE"); small:drain()
check(small.inv.snapshots.mail.counts[700] == 7, "sparse sixteenth attachment retained")
local gen = small.inv.snapshots.mail.generation
small.inbox = {{items = {}, expected = 1, days = 29, money = 0}}
small:event("MAIL_INBOX_UPDATE"); small:drain()
check(small.inv.snapshots.mail.generation == gen and small.inv.snapshots.mail.counts[700] == 7,
    "incomplete attempts preserve last complete generation")
small.inbox = {mail({item(701, 3)})}; small:event("MAIL_INBOX_UPDATE"); small:event("MAIL_CLOSED"); small:drain()
check(small.inv.snapshots.mail.counts[701] == 3, "closing final scan retains remaining attachment facts")
small.inbox = {mail({item(702, 4)})}; small:event("MAIL_SHOW"); small:drain()
check(small.inv.snapshots.mail.counts[702] == 4 and small.inv.snapshots.mail.counts[701] == nil, "reopen publishes new complete inbox")
small.nativeCost = .25; small:reset(); small.inbox[1].items[1].n = 5
small:event("MAIL_INBOX_UPDATE"); small:drain()
check(small.stats.maxReads <= 4, "existing one-ms source budget still yields")

-- Self-send changes char.mail optimistically but not the last inbox facts.
local self = boot(); self.inbox = {mail({item(800, 2)})}; self:event("MAIL_INBOX_UPDATE"); self:drain()
self.hooks.SendMail("Main"); self:event("MAIL_SEND_SUCCESS")
local optimistic = self.store.GetCurrentCharacter().mail
check(#optimistic == 2 and optimistic[2].itemID == 999, "self-send optimistic cache recorded")
self:reset(); self:event("MAIL_INBOX_UPDATE"); self:drain()
check(self.stats.notifications == 0 and self.store.GetCurrentCharacter().mail == optimistic and #optimistic == 2,
    "comparison does not use self-mutated character mail list")
self.inbox[2] = mail({item(999, 2)}); self:event("MAIL_INBOX_UPDATE"); self:drain()
check(self.inv.snapshots.mail.counts[999] == 2 and #self.store.GetCurrentCharacter().mail == 2,
    "actual self-delivery commits matching native facts")

-- Getter callbacks can retire a scan, queue a newer generation or transfer
-- ownership. No later getter/publication from the interrupted job is permitted.
for _, getter in ipairs({"num", "header", "item"}) do
 for _, action in ipairs({"close", "refresh", "handoff"}) do
    local s = boot(); s.inbox = {mail({item(900, 1)})}
    local source = s.inv.snapshots.mail
    s.onRead = function(state, kind)
        if kind ~= getter then return end
        state.onRead = nil; state.invalidated = true
        if action == "handoff" then
            state.store.SetUsesSyndicator(true)
            source.byIndex = {{itemID = 9999, count = 9}}; source.counts = {[9999] = 9}; source.generation = 90
        else
            state.inbox = {mail({item(901, 2)})}
            state:event(action == "close" and "MAIL_CLOSED" or "MAIL_INBOX_UPDATE")
        end
    end
    s:reset(); s:event("MAIL_INBOX_UPDATE"); s:drain()
    check(s.stats.staleReads == 0, getter .. "/" .. action .. " stops old getter continuation")
    if action == "handoff" then
        check(source.generation == 90 and source.counts[9999] == 9 and s.stats.notifications == 0,
            getter .. " preserves provider-owned generation")
    else
        check(source.counts[901] == 2 and source.counts[900] == nil, getter .. "/" .. action .. " retains newer queued generation")
    end
 end
end
print(string.format("builtin mail publication: %d checks, %d failures; arrival normalized=%d peak=%d fingerprint fields=%d; unchanged capture=%d normalized=%d fingerprint fields=%d; one-change normalized=%d cleared=%d; money-only cleared=%d",
    checks, failures, arrival.normalized, arrival.maxNormalized, arrival.formats,
    unchanged.capture, unchanged.normalized, unchanged.formats, changed.normalized, changed.cleared, money.cleared))
if failures > 0 then os.exit(1) end
