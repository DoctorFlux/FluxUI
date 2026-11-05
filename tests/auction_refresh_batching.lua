-- Actual Flux adapter and scheduler; native events/provider data are mocked.
-- The progressive append/callback trace matches Syndicator's public full-list
-- behavior. No external addon files are required or copied into this fixture.
-- Optional argument: alternate Adapter.lua source for baseline replay.
local source = arg[1] or "Inventory/Syndicator/Adapter.lua"
local checks, failures = 0, 0
local totals = { rebuilds = 0, rows = 0, maps = 0, publications = 0, requests = 0 }
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end

local function harness(legacy, ready, installed)
    local e = setmetatable({}, {__index = _G}); e._G = e
    local h = { now = 10, timers = {}, events = {}, callbacks = {}, ready = ready,
        publications = 0, mailPublications = 0, rebuilds = 0, rows = 0, maps = 0, builtinStarts = 0 }
    local char = {auctions = {},mail = {}}
    e.GetTime = function() return h.now end
    local inv = {source = "builtin", Syndicator = {}, Builtin = {},
        Containers = {NewItemSetLog = function() return {} end},
        snapshots = {auctions = {byIndex = {},counts = {},generation = 0},
            mail = {byIndex = {},counts = {},generation = 0}},
        Store = {SetUsesSyndicator = function(value) h.usesSyndicator = value end},
        HasWarband = function() return false end}
    inv.Builtin.Start = function() inv.source = "builtin"; h.builtinStarts = h.builtinStarts + 1 end
    local flux = {Inventory = inv, Cap = {hasAuctionHouse = true,hasLegacyAuctionHouse = legacy,
        hasModernAuctionHouse = not legacy},
        Safecall = function(fn,...) return fn(...) end,
        Timer = {After = function(delay,fn) h.timers[#h.timers+1] = {at=h.now+delay,fn=fn} end},
        Events = {Register = function(event,fn)
            check(not h.events[event],"native owned-list fallback registers once")
            h.events[event] = fn
            return true
        end}}
    e.C_Timer = {After = flux.Timer.After}
    local ns = {Flux = flux}
    assert(loadfile("Core/Engine/Scheduler.lua","t",e))("_FluxUI",ns)
    flux.Scheduler.Register("inventory",function(tokens)
        if tokens.auctions then
            h.publications = h.publications + 1
            h.publishedGeneration = inv.snapshots.auctions.generation
        end
        if tokens.mail then h.mailPublications = h.mailPublications + 1 end
    end)
    if installed then
        e.Syndicator = {Constants = {IsLegacyAH = legacy},
            API = {IsReady = function() return h.ready end,
                GetCurrentCharacter = function() return "Fixture-Realm" end,
                GetCharacter = function() return char end},
            CallbackRegistry = {RegisterCallback = function(_,event,fn)
                check(not h.callbacks[event],"provider callback registers once")
                h.callbacks[event] = fn
            end}}
    end
    assert(loadfile(source,"t",e))("_FluxUI",ns)
    local adapter = inv.Syndicator
    adapter.RebuildAll = function() adapter.RebuildMail(); adapter.RebuildAuctions() end
    local nativeRebuild = adapter.RebuildAuctions
    adapter.RebuildAuctions = function()
        h.rebuilds = h.rebuilds + 1
        local old = inv.snapshots.auctions.counts
        local changed = nativeRebuild()
        if old ~= inv.snapshots.auctions.counts then
            h.maps = h.maps + 1
            -- FillFromList replaces one snapshot record per published index.
            -- This is a desktop source-operation count, not native allocation.
            for _ in pairs(inv.snapshots.auctions.byIndex) do h.rows = h.rows + 1 end
        end
        return changed
    end
    function h.frame(seconds)
        h.now = h.now + (seconds or 0)
        local pending = h.timers; h.timers = {}
        for _,t in ipairs(pending) do
            if t.at <= h.now then t.fn() else h.timers[#h.timers+1] = t end
        end
    end
    function h.fireOwned()
        local fn = h.events[legacy and "AUCTION_OWNED_LIST_UPDATE" or "OWNED_AUCTIONS_UPDATED"]
        if fn then fn(legacy and "AUCTION_OWNED_LIST_UPDATE" or "OWNED_AUCTIONS_UPDATED") end
    end
    function h.callback(name,who) if h.callbacks[name] then h.callbacks[name](nil,who or "Fixture-Realm") end end
    function h.reset()
        h.publications,h.mailPublications,h.rebuilds,h.rows,h.maps = 0,0,0,0,0
        h.requestsBefore = flux.Scheduler.stats.requests.inventory
    end
    h.inv,h.adapter,h.char,h.flux,h.env = inv,adapter,char,flux,e
    return h
end

for _,client in ipairs({"retail","forever","era","anniversary","mists"}) do
    local legacy = client ~= "retail" and client ~= "forever"
    for _,baganator in ipairs({false,true}) do
        local label = client .. (baganator and "/Baganator" or "/default-bags")
        local h = harness(legacy,true,true)
        if baganator then h.env.Baganator = {API={}} end
        local a,snap = h.adapter,h.inv.snapshots.auctions
        a.Start()
        -- A stable fallback in the startup bucket must not erase its original
        -- auction token. Native state is already primed by synchronous RebuildAll.
        h.fireOwned(); h.frame()
        check(h.publications==1 and snap.generation==1,label.." startup publication remains intact")
        h.reset()
        local generation = snap.generation
        h.char.auctions = {}
        for i=1,500 do
            h.char.auctions[i] = {itemID=100+i%3,itemCount=2,itemLink="item:"..(100+i%3)}
            h.callback("AuctionsCacheUpdate")
        end
        check(snap.generation==generation,label.." progressive callback list stays atomic until publication tier")
        h.frame()
        check(h.rebuilds==1 and h.rows==500 and h.maps==1,label.." progressive rows rebuild once")
        check(h.publications==1 and h.publishedGeneration==snap.generation,
            label.." final snapshot reaches listeners in same scheduled tier")
        local requestCount = h.flux.Scheduler.stats.requests.inventory-h.requestsBefore
        check(requestCount==1 and not h.flux.Scheduler.HasPending(),label.." one bounded scheduler request and no extra frame")
        for key in pairs(totals) do
            totals[key] = totals[key] + (key=="requests" and requestCount or h[key])
        end
        local count = (snap.counts[100] or 0)+(snap.counts[101] or 0)+(snap.counts[102] or 0)
        check(count==1000,label.." final quantities retained")
        h.reset(); generation=snap.generation
        for i=1,100 do h.callback("AuctionsCacheUpdate") end
        h.fireOwned(); h.frame()
        check(snap.generation==generation and h.rows==0 and h.maps==0 and h.publications==0,
            label.." unchanged facts produce no auction publication")
        h.reset()
        h.char.auctions[500]=nil; h.callback("AuctionsCacheUpdate")
        h.char.mail[1]={itemID=900,itemCount=4,itemLink="item:900"};h.callback("MailCacheUpdate")
        h.frame()
        check(snap.byIndex[500]==nil and h.publications==1 and h.mailPublications==0,
            label.." sale removal publishes at existing tier and mail keeps debounce")
        h.frame(.2);h.frame()
        check(h.inv.snapshots.mail.counts[900]==4 and h.mailPublications==1,
            label.." purchase/delivery mail facts retain separate cadence")
        h.reset()
        h.char.auctions[100000]={itemID="901",count=7,link="item:901"};h.callback("AuctionsCacheUpdate")
        h.frame()
        check(snap.counts[901]==7 and snap.byIndex[100000].link=="item:901",label.." sparse/legacy listing metadata retained")
        h.char.auctions[100000].count=0;h.char.auctions[100000].link="item:901:new";h.callback("AuctionsCacheUpdate")
        h.frame()
        check(snap.counts[901]==0 and snap.byIndex[100000].link=="item:901:new",label.." later metadata and zero counts reconcile")
        h.reset(); generation=snap.generation
        h.char.auctions[100000].count=3;h.callback("AuctionsCacheUpdate","Other-Realm");h.frame()
        check(snap.generation==generation and h.rebuilds==0 and h.publications==0,label.." foreign callbacks stay inert")
        h.callback("AuctionsCacheUpdate");h.frame()
        check(snap.counts[901]==3,label.." later current-character callback remains responsive")

        h.reset();h.fireOwned();h.char.auctions={};h.frame()
        check(next(snap.byIndex)==nil and next(snap.counts)==nil and h.publications==1,
            label.." zero rows reconcile when native callback precedes provider clear")
        h.char.auctions={{itemID=902,itemCount=5,itemLink="item:902"}};a.RebuildAuctions()
        h.reset();h.char.auctions={};h.fireOwned();h.frame()
        check(next(snap.counts)==nil and h.publications==1,label.." zero rows reconcile after provider clear")

        h.char.auctions={{itemID=903,itemCount=2}};h.callback("AuctionsCacheUpdate")
        h.inv.source="builtin";h.reset();h.frame()
        check(h.rebuilds==0 and h.publications==0 and next(snap.counts)==nil,
            label.." queued provider work stops after ownership handoff")
        h.fireOwned();h.callback("AuctionsCacheUpdate");h.frame()
        check(h.rebuilds==0 and h.publications==0,label.." inactive provider callbacks do no work")
        h.inv.source="syndicator";h.callback("AuctionsCacheUpdate");h.frame()
        check(snap.counts[903]==2,label.." pending flag rearms after inactive flush")
        h.char.auctions={{itemID=904,itemCount=6}}
        check(a.RebuildAuctions() and snap.counts[904]==6,label.." explicit rebuild API remains synchronous")
    end
    local absent=harness(legacy,false,false)
    check(absent.adapter.Start()==false and next(absent.events)==nil,
        client.." absent Syndicator adds no native auction handlers")
    local waiting=harness(legacy,false,true)
    waiting.inv.source=nil
    waiting.adapter.Start()
    check(waiting.inv.source=="builtin" and waiting.builtinStarts==1 and next(waiting.events)==nil,
        client.." pending provider leaves builtin ownership and events alone")
    waiting.ready=true;waiting.callback("Ready");waiting.frame()
    check(waiting.inv.source=="syndicator" and waiting.usesSyndicator and waiting.publications==1,
        client.." Ready handoff retains initial snapshot publication")
    local before=0;for _ in pairs(waiting.events) do before=before+1 end
    waiting.callback("Ready");waiting.adapter.Start()
    local after=0;for _ in pairs(waiting.events) do after=after+1 end
    check(before==1 and after==1,client.." duplicate readiness does not multiply native fallbacks")
end
print(string.format("auction refresh batching: %d checks, %d failures; progressive rebuilds=%d snapshot rows=%d maps=%d publications=%d scheduler requests=%d",
    checks,failures,totals.rebuilds,totals.rows,totals.maps,totals.publications,totals.requests))
if failures>0 then os.exit(1) end
