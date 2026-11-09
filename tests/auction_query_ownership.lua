-- Real built-in auction lifecycle; native queries, events and row APIs mocked.
-- Optional Auctions.lua source argument replays the exact external baseline.
local source=arg[1] or "Inventory/Builtin/Auctions.lua"
local checks,failures=0,0
local totals={legacy=0,modern=0,foreign=0,reentrant=0}
local function check(ok,label)
    checks=checks+1;if not ok then failures=failures+1;print("FAIL "..label)end
end
local capFile=assert(io.open("Core/Capabilities.lua"));local capText=capFile:read("*a");capFile:close()
local first=assert(capText:find("function Cap.HasLegacyAuctionHouse()",1,true))
local last=assert(capText:find("function Cap.RefreshInventoryCaps()",first,true))
local capFunction="local Client,Cap=...\n"..capText:sub(first,last-1).."\nreturn Cap.HasLegacyAuctionHouse()"
local function boot(client,legacy,owned)
    local e=setmetatable({}, {__index=_G});e._G=e
    local s={now=0,uses=owned or false,events={},frames={},legacyQueries=0,modernQueries=0,
        foreign=0,reads=0,pulses=0,marked=0,rows={{id=117,count=3},{id=118,count=2}}}
    local char={}
    e.GetTime=function()return s.now end
    e.Enum={PlayerInteractionType={Auctioneer=21,MailInfo=17},AuctionStatus={Active=0}}
    local function query(kind)
        if kind=="legacy" then s.legacyQueries=s.legacyQueries+1 else s.modernQueries=s.modernQueries+1 end
        if s.uses then s.foreign=s.foreign+1 end
        if s.onQuery then s.onQuery() end
        if s.throwQuery then error("modeled native query refusal") end
    end
    e.GetOwnerAuctionItems=function()query("legacy")end
    e.GetNumAuctionItems=function()return #s.rows end
    e.GetAuctionItemInfo=function(_,index)
        s.reads=s.reads+1;local r=s.rows[index]
        if r then return "Item",1,r.count,1,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,r.id end
    end
    e.IsUsingLegacyAuctionClient=function()return legacy end
    e.C_AuctionHouse={QueryOwnedAuctions=function(sorts)
        check(type(sorts)=="table","modern owned-query sort table retained");query("modern")
    end,GetNumOwnedAuctions=function()return #s.rows end,GetOwnedAuctionInfo=function(index)
        s.reads=s.reads+1;local r=s.rows[index]
        if r then return {itemKey={itemID=r.id},quantity=r.count,auctionID=index,status=0,itemLink="item:"..r.id}end
    end}
    local selected=assert(load(capFunction,"@production-auction-capability","t",e))({isEra=client=="era"},{})
    check(selected==legacy,client.." both API namespaces retain capability-selected auction client")
    local inv={Builtin={},source=owned and "syndicator" or "builtin",
        snapshots={auctions={byIndex={},counts={},generation=0}},Notify=function(tokens)
            check(tokens.auctions==true,"auction snapshot publishes its own region");s.pulses=s.pulses+1
        end}
    inv.Store={UsesSyndicator=function()return s.uses end,EnsureCurrentCharacter=function()return char end,
        MarkPending=function()s.marked=s.marked+1 end}
    local flux={Inventory=inv,Cap={hasAuctionHouse=true,hasLegacyAuctionHouse=selected,hasModernAuctionHouse=not selected},
        Events={Register=function(key,fn)check(not s.events[key],"event registration remains unique");s.events[key]=fn end}}
    e.CreateFrame=function()
        local f={};function f:SetScript(key,fn)self[key]=fn end;s.frames[#s.frames+1]=f;return f
    end
    assert(loadfile(source,"t",e))("_FluxUI",{Flux=flux})
    s.auctions,s.inv,s.env,s.saved=inv.Builtin.Auctions,inv,e,char
    function s:event(key,kind)if self.events[key]then self.events[key](key,kind)end end
    function s:open(reverse)
        if reverse then self:event("AUCTION_HOUSE_SHOW");self:event("PLAYER_INTERACTION_MANAGER_FRAME_SHOW",21)
        else self:event("PLAYER_INTERACTION_MANAGER_FRAME_SHOW",21);self:event("AUCTION_HOUSE_SHOW")end
    end
    function s:advance(seconds)
        for _=1,math.ceil(seconds/.02)do
            self.now=self.now+.02
            for _,f in ipairs(self.frames)do if f.OnUpdate then f:OnUpdate(.02)end end
        end
    end
    function s:queries()return self.legacyQueries+self.modernQueries end
    s.auctions.Start()
    return s
end

for _,client in ipairs({"era","anniversary","forever","retail","mists"})do
 local legacy=client=="era" or client=="anniversary"
 for _,reverse in ipairs({false,true})do
    local label=client.."/"..(reverse and "SHOW-first" or "PIM-first")
    local s=boot(client,legacy)
    s.auctions.Refresh();s:event("PLAYER_INTERACTION_MANAGER_FRAME_SHOW",17);s:advance(.3)
    check(s:queries()==0 and #s.frames==0,label.." unrelated interaction and closed refresh stay inert")
    s:open(reverse)
    check(s:queries()==1,label.." paired show events issue one initial owned query")
    check((legacy and s.modernQueries==0)or(not legacy and s.legacyQueries==0),label.." query matches selected native client")
    for _=1,50 do s:open(reverse)end
    check(s:queries()==1,label.." duplicate show events cannot repeat native query")
    if legacy then totals.legacy=totals.legacy+s:queries()else totals.modern=totals.modern+s:queries()end
    s:advance(.3)
    local snap=s.inv.snapshots.auctions
    check(s.reads==2 and snap.counts[117]==3 and snap.counts[118]==2,label.." unchanged scan cadence publishes real cached rows")
    check(s.saved.auctions and #s.saved.auctions==2 and s.marked==1,label.." saved ownership records retain existing publication")
    local generation=snap.generation
    s:open(reverse);s:advance(.3)
    check(snap.generation==generation and s.pulses==1,label.." unchanged rows retain equality guard")
    s.rows[1].count=4;s:open(reverse);s:advance(.3)
    check(snap.counts[117]==4 and s.pulses==2,label.." repeated show still refreshes changed cached facts")
    local queried=s:queries();s.rows[1].count=5;s.auctions.Refresh();s:advance(.3)
    check(s:queries()==queried and snap.counts[117]==5,label.." explicit Refresh stays a cache scan without requery")
    s:event("AUCTION_HOUSE_CLOSED");s:event("PLAYER_INTERACTION_MANAGER_FRAME_HIDE",21)
    local reads=s.reads;s:advance(.3)
    check(s.reads==reads,label.." duplicate close cancels owned scan")
    s:open(reverse)
    check(s:queries()==queried+1,label.." actual reopen requests one fresh owned list")
    s.uses=true;s.inv.source="syndicator";local before=s:queries();local pulses=s.pulses
    for _=1,50 do s:open(reverse)end
    check(s:queries()==before and s.foreign==0,label.." source handoff guards before every native query")
    totals.foreign=totals.foreign+s.foreign
    s:advance(.3)
    check(s.pulses==pulses,label.." pending built-in scan cannot publish after handoff")
    s:event("AUCTION_HOUSE_CLOSED");s:open(reverse)
    check(s:queries()==before,label.." external source stays inert across close and reopen")

    local ready=boot(client,legacy,true);ready:open(reverse)
    check(ready:queries()==0 and next(ready.events)==nil,label.." ready provider never installs built-in query handlers")

    local r=boot(client,legacy);local depth=0
    r.onQuery=function()
        if depth<4 then depth=depth+1;r:open(reverse);depth=depth-1 end
    end
    r:open(reverse)
    check(r:queries()==1,label.." query latch precedes synchronous reentrant show callbacks")
    totals.reentrant=totals.reentrant+r:queries()

    local refused=boot(client,legacy);refused.throwQuery=true
    local ok=pcall(function()refused:open(reverse)end)
    for _=1,10 do refused:open(reverse)end
    check(ok and refused:queries()==1,label.." failed native attempt does not form a duplicate-query retry loop")
    refused.throwQuery=false;refused:event("AUCTION_HOUSE_CLOSED");refused:open(reverse)
    check(refused:queries()==2,label.." close and reopen permits recovery from refusal")

    local missing=boot(client,legacy)
    local legacyFn,modernFn=missing.env.GetOwnerAuctionItems,missing.env.C_AuctionHouse.QueryOwnedAuctions
    missing.env.GetOwnerAuctionItems=nil;missing.env.C_AuctionHouse.QueryOwnedAuctions=nil
    missing:open(reverse)
    check(missing:queries()==0,label.." absent native APIs are not called")
    missing.env.GetOwnerAuctionItems=legacyFn;missing.env.C_AuctionHouse.QueryOwnedAuctions=modernFn
    missing:open(reverse)
    check(missing:queries()==1,label.." later API presence can request once in same open session")

    if not legacy then
        local modern=boot(client,false)
        for _=1,20 do modern:event("AUCTION_HOUSE_SHOW")end
        check(modern:queries()==0,label.." modern query remains on interaction-show trigger")
        modern:advance(.3)
        check(modern.inv.snapshots.auctions.counts[117]==3,label.." standalone native-show still reads cached modern rows")
        modern:event("PLAYER_INTERACTION_MANAGER_FRAME_SHOW",21)
        check(modern:queries()==1,label.." later interaction event still owns modern initial query")
    end
 end
end
print(string.format("auction query ownership: %d checks, %d failures; duplicate-burst legacy queries=%d modern queries=%d foreign queries=%d reentrant queries=%d",
    checks,failures,totals.legacy,totals.modern,totals.foreign,totals.reentrant))
if failures>0 then os.exit(1)end
