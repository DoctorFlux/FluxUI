-- Actual production inventory owners with synthetic native/provider facts.
-- Optional source-root argument selects an external exact baseline. --measure
-- keeps parity assertions while reporting (rather than requiring) work budgets.
local sourceRoot = (arg[1] or "."):gsub("\\", "/"):gsub("/$", "") .. "/"
local measure = arg[2] == "--measure"
local checks, failures = 0, 0
local function check(ok, why)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. why) end
end
local function budget(ok, why) if not measure then check(ok, why) end end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s
end
local function source(path) return sourceRoot .. path end
local function fixture(path, marker, selected, tail)
    local text = read(path)
    text = text:sub(1, assert(text:find(marker, 1, true)) - 1)
    local env = setmetatable({arg = {selected}}, {__index = _G})
    return assert(load(text .. "\n" .. tail, "@reused-passive-inventory-fixture", "t", env))()
end

-- Mail: retain every getter, even when an attachment count is inaccurate or
-- an item occupies only the last supported slot. Optimize immutable captures.
local mailBoot, item, message = fixture("tests/builtin_mail_publication.lua", "\nlocal h = boot()",
    source("Inventory/Builtin/Mail.lua"), "return boot, item, mail")
local m = mailBoot()
m.inbox = {}
for i = 1, 50 do m.inbox[i] = message({item(20000 + i, 1)}) end
m:event("MAIL_INBOX_UPDATE"); m:drain()
local mailRows, mailReads = 0, 0
for _ = 1, 5 do
    m:reset(); m:event("MAIL_INBOX_UPDATE"); m:drain()
    mailRows, mailReads = mailRows + m.stats.capture, mailReads + m.stats.reads
    check(m.stats.reads == 850 and m.stats.maxReads <= 48, "RPF15 getters/sparse-slot policy and read cap retained")
    check(m.stats.notifications == 0, "RPF15 unchanged scan remains unpublished")
end
budget(mailRows == 0, "RPF15 unchanged inbox constructs no persisted capture records")
local saved = m.store.GetCurrentCharacter().mail
m.inbox[1].items[1].texture = 8; m.inbox[1].items[1].quality = 4; m.inbox[1].days = 28
m:event("MAIL_INBOX_UPDATE"); m:drain()
check(m.store.GetCurrentCharacter().mail == saved and saved[1].iconTexture ~= 8,
    "RPF15 metadata-only scan leaves published saved records unchanged")
m.inbox[50].items[1].n = 2
m:event("MAIL_INBOX_UPDATE"); m:drain()
local changed = m.store.GetCurrentCharacter().mail
check(changed[1].iconTexture == 8 and changed[1].quality == 4
    and changed[1].expirationTime == 1000 + 28*86400 and changed[50].itemCount == 2,
    "RPF15 real publication retains fresh metadata from preceding rows")
local sparse = mailBoot()
sparse.inbox = {{items = {[16] = item(700, 7)}, expected = 1, days = 29}}
sparse:event("MAIL_INBOX_UPDATE"); sparse:drain()
check(sparse.inv.snapshots.mail.counts[700] == 7, "RPF15 numeric header cannot hide sparse final slot")
sparse.inbox = {{items = {[1] = item(701), [16] = item(702)}, expected = 1, days = 29}}
sparse:event("MAIL_INBOX_UPDATE"); sparse:drain()
check(sparse.inv.snapshots.mail.counts[701] == 1 and sparse.inv.snapshots.mail.counts[702] == 1,
    "RPF15 inaccurate low numeric header cannot truncate real attachments")
local header = sparse.env.GetInboxHeaderInfo
sparse.env.GetInboxHeaderInfo = function(index)
    local a,b,c,d,e,f,g = header(index); return a,b,c,d,e,f,g,true
end
sparse:event("MAIL_INBOX_UPDATE"); sparse:drain()
check(sparse.inv.snapshots.mail.counts[702] == 1, "RPF15 boolean header keeps complete sparse capture")

local function base()
    local h = {now = 100, timers = {}, frames = {}, callbacks = {}, onupdates = 0, countVisits = 0, rowNews = 0}
    local e = setmetatable({}, {__index = _G}); e._G = e
    e.GetTime = function() return h.now end
    e.SlashCmdList = {}
    e.CreateFrame = function()
        local f = {scripts = {}, shown = true}
        function f:SetScript(key, fn) self.scripts[key] = fn end
        function f:RegisterEvent() end
        function f:UnregisterEvent() end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:IsShown() return self.shown end
        h.frames[#h.frames + 1] = f; return f
    end
    local flux = {Cap = {}, Client = {}, Module = {Register = function() end},
        Safecall = function(fn, ...) return fn(...) end,
        Scheduler = {Request = function() end, Register = function() end}}
    flux.Timer = {After = function(delay, fn) h.timers[#h.timers + 1] = {at = h.now + delay, fn = fn} end}
    e.C_Timer = flux.Timer
    local ns = {Flux = flux}
    assert(loadfile(source("Inventory/Init.lua"), "t", e))("_FluxUI", ns)
    h.inv, h.env, h.flux, h.ns = flux.Inventory, e, flux, ns
    function h:step(dt)
        self.now = self.now + dt
        local timers = self.timers; self.timers = {}
        for _, t in ipairs(timers) do
            if t.at <= self.now then t.fn() else self.timers[#self.timers + 1] = t end
        end
        for _, f in ipairs(self.frames) do
            if f.shown ~= false and f.scripts.OnUpdate then self.onupdates = self.onupdates + 1; f.scripts.OnUpdate(f, dt) end
        end
    end
    return h
end

-- Provider lists: every live row still validates, including in-place mutation.
-- Only the adapter-owned old map's redundant second cardinality walk is removed.
local p = base()
local inv, e = p.inv, p.env
inv.Store = {SetUsesSyndicator = function() end}
local char = {mail = {}, auctions = {}}
e.Syndicator = {API = {GetCurrentCharacter = function() return "Current-Realm" end,
    GetCharacter = function() return char end}}
local sourceVisits, indexVisits = 0, 0
e.pairs = function(t)
    local iter, state, key = pairs(t)
    return function(st, last)
        local k,v = iter(st,last)
        if k ~= nil then
            if t == char.mail or t == char.auctions then sourceVisits = sourceVisits + 1 end
            if t == inv.snapshots.mail.byIndex or t == inv.snapshots.auctions.byIndex then indexVisits = indexVisits + 1 end
        end
        return k,v
    end,state,key
end
inv.Containers = {NewItemSetLog = function() return {} end}
assert(loadfile(source("Inventory/Syndicator/Adapter.lua"), "t", e))("_FluxUI", p.ns)
for i = 1, 1000 do char.mail[i] = {itemID = i, itemCount = 1, itemLink = "item:" .. i} end
inv.Syndicator.RebuildMail(); sourceVisits, indexVisits = 0,0
local stable, generation = inv.snapshots.mail.byIndex, inv.snapshots.mail.generation
for _ = 1, 100 do check(inv.Syndicator.RebuildMail() == false, "RPF16 unchanged list returns false") end
check(inv.snapshots.mail.byIndex == stable and inv.snapshots.mail.generation == generation,
    "RPF16 unchanged list retains maps/generation")
local providerIndexVisits, providerSourceVisits = indexVisits, sourceVisits
budget(providerIndexVisits == 0 and providerSourceVisits == 100000,
    "RPF16 unchanged provider rows validate once without old index traversal")
char.mail[1000].itemLink = "item:1000:variant"
check(inv.Syndicator.RebuildMail() and inv.snapshots.mail.byIndex[1000].link == "item:1000:variant"
    and stable[1000].link == "item:1000", "RPF16 in-place metadata edits publish atomically")
char.mail[1] = nil; char.mail[90000] = {itemID = 90000, count = 3, link = "item:90000"}
check(inv.Syndicator.RebuildMail() and not inv.snapshots.mail.byIndex[1]
    and inv.snapshots.mail.counts[90000] == 3, "RPF16 sparse replacement with unchanged size is detected")
char.mail[90000] = {itemID = "invalid"}
check(inv.Syndicator.RebuildMail() and not inv.snapshots.mail.counts[90000], "RPF16 invalid-ID replacement removes old row")
check(inv.Syndicator.RebuildMail() == false, "RPF16 invalid source rows do not create publications")
-- Ownership replacement invalidates cardinality metadata, even if a caller
-- installs an empty map without changing the numeric generation.
inv.snapshots.mail.byIndex = {}
check(inv.Syndicator.RebuildMail() and inv.snapshots.mail.byIndex[2].itemID == 2,
    "RPF16 replacing private index identity cannot reuse stale cardinality")

-- Bag facts remain authoritative synchronously. Meter only visits to the entire
-- aggregate count map and the actual normalized bag-row constructor site.
local b = base()
local bagChar = {bags = {}}
for bag = 1, 5 do
    bagChar.bags[bag] = {}
    for slot = 1, 40 do bagChar.bags[bag][slot] = {itemID = (bag - 1)*40 + slot, itemCount = 1} end
end
b.env.Syndicator = {Constants = {AllBagIndexes = {0,1,2,3,4}},
    API = {GetCurrentCharacter = function() return "Current-Realm" end, GetCharacter = function() return bagChar end}}
assert(loadfile("Inventory/Containers.lua", "t", b.env))("_FluxUI", b.ns)
b.env.pairs = function(t)
    local iter, state, key = pairs(t)
    return function(st,last)
        local k,v = iter(st,last)
        if k ~= nil and t == b.inv.snapshots.bags.counts then b.countVisits = b.countVisits + 1 end
        return k,v
    end,state,key
end
local adapterPath = source("Inventory/Syndicator/Adapter.lua")
assert(loadfile(adapterPath, "t", b.env))("_FluxUI", b.ns)
b.inv.Syndicator.RebuildBags(); b.inv.Syndicator.TakeBagsItemSets()
local oldRow = b.inv.snapshots.bags.byBag[0][2]
local constructors, line = {}, 0
for text in (read(adapterPath) .. "\n"):gmatch("(.-)\n") do
    line = line + 1
    if text:find("dest[slot] = {", 1, true) then constructors[line] = true end
end
debug.sethook(function(_, current)
    if constructors[current] then
        local info = debug.getinfo(2,"S")
        if info and info.source == "@" .. adapterPath then b.rowNews = b.rowNews + 1 end
    end
end,"l")
b.countVisits = 0
for n = 2, 101 do
    bagChar.bags[1][1].itemCount = n
    b.inv.Syndicator.RebuildBags({[0] = true})
    check(b.inv.snapshots.bags.counts[1] == n and b.inv.Syndicator.GetLastBagsChangeKind() == "countOnly",
        "RPF17 dirty callback immediately exposes current count/classification")
    b.inv.Syndicator.TakeBagsItemSets()
end
debug.sethook()
local bagCountVisits, bagRows = b.countVisits, b.rowNews
budget(bagCountVisits == 0 and bagRows == 100, "RPF17 incremental bag update avoids whole counts walk and identical row constructors")
budget(b.inv.snapshots.bags.byBag[0][2] == oldRow, "RPF17 unchanged bag row retains identity")
bagChar.bags[1][1] = {itemID = 777, itemCount = 2}
b.inv.Syndicator.RebuildBags({[0] = true})
check(b.inv.Syndicator.GetLastBagsAddedItemIDs()[777]
    and b.inv.Syndicator.GetLastBagsRemovedItemIDs()[1], "RPF17 targeted identity additions/removals remain complete")
b.inv.Syndicator.TakeBagsItemSets()
-- Moving an identity between two dirty bags retains aggregate identity.
bagChar.bags[1][1] = nil; bagChar.bags[2][41] = {itemID = 777, itemCount = 2}
b.inv.Syndicator.RebuildBags({[0] = true,[1] = true})
check(b.inv.Syndicator.GetLastBagsChangeKind() == "countOnly" and b.inv.snapshots.bags.counts[777] == 2,
    "RPF17 cross-bag transfer preserves identity and current total")
b.inv.Syndicator.TakeBagsItemSets()
bagChar.bags[1][1] = {itemID = 778, itemCount = 1}
b.inv.Syndicator.RebuildBags({[0] = true});bagChar.bags[1][1] = nil
b.inv.Syndicator.RebuildBags({[0] = true})
check(b.inv.Syndicator.GetLastBagsAddedItemIDs()[778] and b.inv.Syndicator.GetLastBagsRemovedItemIDs()[778],
    "RPF17 acquisition then removal before publication retains both identity facts")

-- Deferred listener deadlines: the queue sleeps before 50ms, then retains the
-- same frame budget. Continued pulses retain the existing 0.6s maximum wait.
local q = base()
local paints, maximum, first = 0,0,nil
for i = 1, 20 do
    q.inv.Register("passive.queue." .. i,function()
        paints = paints + 1; first = first or q.now
    end,{regions={"mail"},tier="scan"})
end
q.inv.Notify({mail = true})
for _ = 1, 48 do
    local before = paints; q:step(1/240); maximum = math.max(maximum, paints-before)
end
check(paints == 20 and maximum <= 2 and first >= 100.05 and first < 100.06,
    "RPF18 original quiet deadline, response frame and two-listener drain preserved")
local queueCallbacks = q.onupdates
budget(queueCallbacks == 10, "RPF18 only runnable drain frames execute OnUpdate")
for i = 1,20 do q.inv.Unregister("passive.queue." .. i) end
local once, at = 0,nil
q.inv.Register("passive.continuous",function() once = once + 1; at = at or q.now end,{regions={"mail"},tier="scan"})
local start = q.now
for _ = 1, 160 do q.inv.Notify({mail=true});q:step(1/240) end
check(once >= 1 and at >= start+0.6 and at < start+0.61, "RPF18 continuous stream retains 0.6s maximum wait")
q.inv.Unregister("passive.continuous")
q:step(1/240) -- Historical driver may retire its empty queue on the next frame.
local stopped = q.onupdates
for _ = 1, 100 do q:step(1/240) end
check(q.onupdates == stopped and #q.timers == 0, "RPF18 cancelled pending work leaves no active callback or timer")

-- The actual timer service's polyfill has different frame-loop/error ownership.
-- Keep historical queue dispatch when it cannot capture a native After API.
local poly = base()
poly.env.C_Timer = nil
assert(loadfile("Core/Engine/Timer.lua", "t", poly.env))("_FluxUI", poly.ns)
check(poly.flux.Timer.HasNativeAfter == false, "RPF18 real timer service records missing native After")
local polyPaints, polyMaximum, polyFirst = 0,0,nil
for i = 1,20 do
    poly.inv.Register("passive.poly." .. i,function()
        polyPaints = polyPaints + 1; polyFirst = polyFirst or poly.now
    end,{regions={"mail"},tier="scan"})
end
poly.inv.Notify({mail=true})
local scheduledPolyfill = poly.flux.Timer.HasPendingPolyfill()
check(not scheduledPolyfill, "RPF18 absent native After cannot schedule a polyfill waiter")
-- This harmful control can otherwise consume freshly added tiny deadlines
-- indefinitely inside the existing polyfill's same-frame while loop.
if scheduledPolyfill then error("RPF18 rejected polyfill wait before unsafe dispatch") end
for _ = 1,48 do
    local before = polyPaints; poly:step(1/240); polyMaximum = math.max(polyMaximum,polyPaints-before)
end
check(polyPaints == 20 and polyMaximum <= 2 and polyFirst == first and poly.onupdates == 22,
    "RPF18 no-native timer path retains exact historical deadline/drain callbacks")
check(not poly.flux.Timer.HasPendingPolyfill(), "RPF18 queue never enters polyfill wait loop")
poly.inv.Register("passive.poly.cancel",function() error("cancelled polyfill job ran") end,{regions={"mail"},tier="scan"})
poly.inv.Notify({mail=true});poly.inv.Unregister("passive.poly.cancel")
for i = 1,20 do poly.inv.Unregister("passive.poly." .. i) end
poly:step(1/240)
local polyStopped = poly.onupdates
for _ = 1,100 do poly:step(1/240) end
check(poly.onupdates == polyStopped and not poly.flux.Timer.HasPendingPolyfill(),
    "RPF18 no-native cancellation retires frame dispatch without timers")

-- Summary reads preserve complete visible totals. Filtered characters remain
-- pending; repeated unchanged rows avoid reparsing links, with in-place guards.
local summaryFixture = fixture("tests/inventory_summary_pruning.lua", "\nlocal function rowCounts",
    source("Inventory/Summaries.lua"), "return fixture")
local s = summaryFixture()
local main, remote = s.character("Main","Realm"), s.character("Remote","Other")
for i = 1, 1000 do main.mail[i] = s.item(i,1);remote.mail[i] = s.item(i,2) end
local keyCalls, nativeGetKey = 0,s.store.GetItemKey
s.store.GetItemKey = function(...) keyCalls = keyCalls + 1; return nativeGetKey(...) end
s.store.MarkPending("Main-Realm","all");s.store.MarkPending("Remote-Other","all")
local selected = s.summaries.GetTooltipInfoByItemID(1,true,false)
check(#selected.characters == 1 and selected.characters[1].mail == 1, "RPF19 connected query returns complete eligible counts")
local filteredKeys = keyCalls
budget(filteredKeys == 1000 and s.db.Pending.Characters["Remote-Other"] == s.store.PendingAll(),
    "RPF19 irrelevant character remains pending without source traversal")
local all = s.summaries.GetTooltipInfoByItemID(1,false,false)
check(#all.characters == 2 and s.db.Pending.Characters["Remote-Other"] == nil,
    "RPF19 removing filter immediately includes retained pending character")
keyCalls = 0
for _ = 1,20 do
    s.store.MarkPending("Main-Realm","all")
    local info = s.summaries.GetTooltipInfoByItemID(1)
    check(#info.characters == 2, "RPF19 complete totals retained through repeated full pending generation")
end
local summaryKeyCalls = keyCalls
budget(summaryKeyCalls == 0, "RPF19 unchanged source records reuse parsed item keys")
main.mail[1].link = "battlepet:777"; s.store.MarkPending("Main-Realm","all")
local pet = s.summaries.GetTooltipInfo("battlepet:777")
check(#pet.characters == 1 and pet.characters[1].mail == 1
    and #s.summaries.GetTooltipInfoByItemID(1).characters == 1, "RPF19 in-place hyperlink edit invalidates parsed key")
main.mail[1].link = nil; main.mail[1].itemID = 888; s.store.MarkPending("Main-Realm","all")
local fallback = s.summaries.GetTooltipInfoByItemID(888)
local mainCount
for _, row in ipairs(fallback.characters) do if row.character == "Main" then mainCount = row.mail end end
check(mainCount == 2, "RPF19 itemID fallback edits invalidate parsed key and accumulate duplicate IDs")

print(string.format('METRICS {"mail_capture_rows":%d,"mail_reads":%d,"provider_source_visits":%d,"provider_old_index_visits":%d,"bag_full_count_visits":%d,"bag_row_constructors":%d,"queue_onupdates":%d,"filtered_summary_key_parses":%d,"repeated_summary_key_parses":%d}',
    mailRows,mailReads,providerSourceVisits,providerIndexVisits,bagCountVisits,bagRows,queueCallbacks,filteredKeys,summaryKeyCalls))
print(string.format("passive inventory work: %d checks, %d failures; production owners, synthetic facts; native FPS/taint pending",checks,failures))
if failures > 0 then os.exit(1) end
