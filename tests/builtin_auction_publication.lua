-- Real auction source; frame work/records are counted with mocked native calls.
-- Optional source path replays the externally preserved baseline unchanged.
local source=arg[1] or "Inventory/Builtin/Auctions.lua"
local checks,failures=0,0
local totals={fingerprintRows=0,maxFinalWork=0,newUnchangedRows=0,reentryErrors=0,pulses=0,stageRows=0}
local function check(ok,label)
    checks=checks+1
    if not ok then failures=failures+1;print("FAIL "..label)end
end
local function boot(legacy,pending,n)
    local env=setmetatable({}, {__index=_G});env._G=env
    local s={now=0,clock=0,events={},frames={},uses=false,pending=pending,quantity=2,rows=n or 1024,
        pulses=0,marks=0,nativeReads=0,linkReads=0,allRecords={},maps={},history={},auctionOffset=0,link="item:117",errors=0}
    local char={}
    local function charge(amount)s.clock=s.clock+(amount or .005)end
    local function instrument(map,staged)
        if not map or s.maps[map]then return end
        s.maps[map]=true
        setmetatable(map,{__newindex=function(t,k,v)
            if s.frame and v~=nil then
                s.frame.mapWrites=s.frame.mapWrites+1
                if staged then s.frame.stagedWrites=s.frame.stagedWrites+1 end
                if type(v)=="table" and not s.allRecords[v]then
                    s.frame.newRecords=s.frame.newRecords+1;s.allRecords[v]=true
                end
                charge(.01)
            end
            rawset(t,k,v)
        end})
    end
    local function attachStage()
        for _,f in ipairs(s.frames)do
            if f.OnUpdate then
                for i=1,30 do
                    local name,value=debug.getupvalue(f.OnUpdate,i)
                    if not name then break end
                    if name=="scan" and type(value)=="table"then instrument(value.byIndex,true)end
                end
            end
        end
    end
    env.tonumber=function(value,base)
        if s.frame then s.frame.numbers=s.frame.numbers+1;charge()end
        return tonumber(value,base)
    end
    env.ipairs=function(t)
        local iterator,state,key=ipairs(t)
        return function(a,b)
            local i,v=iterator(a,b)
            if i and s.frame then s.frame.fingerprints=s.frame.fingerprints+1;charge(.01)end
            return i,v
        end,state,key
    end
    env.wipe=function(t)
        for k in pairs(t)do
            if s.frame then s.frame.clears=s.frame.clears+1;charge()end
            rawset(t,k,nil)
        end
    end
    env.GetTime=function()return s.now end
    env.debugprofilestop=function()return s.clock end
    env.time=function()return 1000 end
    env.Enum={PlayerInteractionType={Auctioneer=1},AuctionStatus={Active=0}}
    env.CreateFrame=function()
        local f={};function f:SetScript(key,fn)self[key]=fn end
        s.frames[#s.frames+1]=f;return f
    end
    local function count()
        attachStage()
        local n=s.rows
        if s.onCount then local fn=s.onCount;s.onCount=nil;fn()end
        return n
    end
    local function read(index)
        attachStage();s.nativeReads=s.nativeReads+1;s.frame.reads=s.frame.reads+1;charge(s.nativeCost or .02)
        local id,quantity=117+(index%7),s.quantity
        if s.onRead then local fn=s.onRead;s.onRead=nil;fn(index)end
        return id,quantity
    end
    env.GetNumAuctionItems=count
    env.GetOwnerAuctionItems=function()end
    env.GetAuctionItemInfo=function(_,index)
        local id,q=read(index)
        if s.skip and index==s.skip then return nil end
        if s.legacyMissingID then id=nil end
        return "Item",42,q,3,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,id
    end
    env.GetAuctionItemLink=function(_,index)
        s.linkReads=s.linkReads+1
        if s.skip==index then return nil end
        return "item:"..(117+(index%7))
    end
    env.C_AuctionHouse={GetNumOwnedAuctions=count,QueryOwnedAuctions=function()end,
        GetOwnedAuctionInfo=function(index)
            local id,q=read(index)
            if s.skip and index==s.skip then return nil end
            return {itemKey={itemID=id},quantity=q,auctionID=s.stringAuctionID and tostring(index+s.auctionOffset)
                or index+s.auctionOffset,itemLink=s.link,timeLeftSeconds=30,status=s.inactive==index and 1 or 0}
        end}
    local snap={byIndex={},counts={},generation=0};instrument(snap.byIndex,false)
    local inv={Builtin={},snapshots={auctions=snap},HasWarband=function()return false end,Notify=function(tokens)
        check(tokens.auctions==true,"publication token retains auction region")
        s.pulses=s.pulses+1
        local total=0;for _,rec in pairs(snap.byIndex)do total=total+rec.count end
        local counts=0;for _,q in pairs(snap.counts)do counts=counts+q end
        check(total==counts,"notification observes completed coherent index/count maps")
    end}
    inv.Store={UsesSyndicator=function()return s.uses end,EnsureCurrentCharacter=function()return char end,
        MarkPending=function()s.marks=s.marks+1 end}
    local flux={Inventory=inv,Cap={hasAuctionHouse=true,hasLegacyAuctionHouse=legacy,hasModernAuctionHouse=not legacy},
        Events={Register=function(event,fn)s.events[event]=fn end}}
    assert(loadfile(source,"t",env))("_FluxUI",{Flux=flux})
    assert(loadfile("Inventory/Index.lua","t",env))("_FluxUI",{Flux=flux})
    s.inv,s.snap,s.saved,s.auctions,s.env=inv,snap,char,inv.Builtin.Auctions,env
    function s:event(event,...)if self.events[event]then self.events[event](event,...)end end
    function s:open()self:event("PLAYER_INTERACTION_MANAGER_FRAME_SHOW",1)end
    function s:step(seconds)
        self.now=self.now+(seconds or .02)
        local fr={reads=0,numbers=0,fingerprints=0,mapWrites=0,stagedWrites=0,newRecords=0,clears=0}
        self.frame=fr;self.history[#self.history+1]=fr
        local beforeGeneration,beforeMap,beforeCounts=self.snap.generation,self.snap.byIndex,self.snap.counts
        local function digest()
            local sum=0
            for i,rec in pairs(self.snap.byIndex)do sum=sum+i+rec.itemID*rec.count end
            for id,q in pairs(self.snap.counts)do sum=sum+id*q end
            return sum
        end
        local beforeDigest=digest()
        local beforeClock=self.clock
        for _,f in ipairs(self.frames)do if f.OnUpdate then
            local ok,message=pcall(f.OnUpdate,f,.02)
            if not ok then self.errors=self.errors+1;self.lastError=message;f.OnUpdate=nil end
        end end
        fr.work=fr.reads+fr.numbers+fr.fingerprints+fr.mapWrites+fr.clears
        fr.clock=self.clock-beforeClock
        if self.snap.generation==beforeGeneration then
            check(self.snap.byIndex==beforeMap and self.snap.counts==beforeCounts and digest()==beforeDigest,
                "incomplete/unchanged generation keeps published maps and contents")
        end
        self.frame=nil
        return fr
    end
    function s:drain()
        for _=1,3000 do
            local active=false;for _,f in ipairs(self.frames)do if f.OnUpdate then active=true end end
            if not active then return end
            self:step(.02)
        end
        error("auction scan did not settle")
    end
    function s:measure()
        local maxWork,maxNative,maxPrep,totalNew,totalFP,totalStage=0,0,0,0,0,0
        for _,fr in ipairs(self.history)do
            maxWork=math.max(maxWork,fr.work);maxNative=math.max(maxNative,fr.reads)
            maxPrep=math.max(maxPrep,fr.mapWrites);totalNew=totalNew+fr.newRecords
            totalFP=totalFP+fr.fingerprints;totalStage=totalStage+fr.stagedWrites
        end
        return {maxWork=maxWork,maxNative=maxNative,maxPrep=maxPrep,newRecords=totalNew,fp=totalFP,stage=totalStage}
    end
    function s:reset()self.history={};self.frame=nil end
    s.auctions.Start()
    return s
end

for _,client in ipairs({"era","anniversary","forever","retail","mists"})do
 local legacy=client=="era" or client=="anniversary"
 for _,pending in ipairs({false,true})do
    local label=client..(pending and "/provider-pending" or "/standalone")
    local s=boot(legacy,pending)
    s:open();s:step(.1)
    check(s.nativeReads==0,label.." initial quiet time retained")
    s:drain()
    local first=s:measure()
    check(s.errors==0 and s.pulses==1 and #s.saved.auctions==1024,label.." complete initial list publishes and persists once")
    check(first.maxNative<=32,label.." native rows remain bounded")
    check(first.maxPrep<=32 and first.maxWork<250,label.." preparation shares per-update budget")
    local region=s.snap;local index=s.snap.byIndex;local counts=s.snap.counts;local saved=s.saved.auctions
    local gen=s.snap.generation
    s:reset();for _=1,50 do s:event("OWNED_AUCTIONS_UPDATED")end;s:drain()
    local unchanged=s:measure()
    check(s.snap==region and s.snap.generation==gen and s.pulses==1,label.." unchanged burst keeps public region/generation")
    check(s.snap.byIndex==index and s.snap.counts==counts and s.saved.auctions==saved,label.." unchanged scan preserves completed records and saved list")
    check(unchanged.newRecords==0,label.." identical rows allocate no replacement snapshot records")
    check(unchanged.fp==0,label.." unchanged completion has no full-list fingerprint loop")
    check(unchanged.maxWork<250,label.." unchanged completion work is bounded")
    totals.fingerprintRows=totals.fingerprintRows+unchanged.fp
    totals.newUnchangedRows=totals.newUnchangedRows+unchanged.newRecords

    s:reset();s.quantity=3;for _=1,50 do s:event("OWNED_AUCTIONS_UPDATED")end;s:drain()
    local changed=s:measure()
    check(s.snap==region and s.snap.generation==gen+1 and s.pulses==2 and s.marks==2,label.." changed burst publishes exactly once")
    local sum=0;for _,q in pairs(s.snap.counts)do sum=sum+q end
    check(sum==3072 and #s.saved.auctions==1024,label.." full totals and listing shape preserved")
    local opts={bags=false,auctions=true}
    local found=s.inv.Find(118,opts);local located=0
    for _,loc in ipairs(found)do
        located=located+loc.count
        check(loc.region=="auctions" and loc.slot~=nil,label.." public Find retains auction locations")
    end
    check(located==s.inv.GetCount(118,opts) and located==s.inv.Auctions.GetCount(118)
        and s.inv.GetSnapshotGeneration("auctions")==s.snap.generation,label.." fresh public readers observe completed swapped maps")
    check(changed.maxPrep<=32 and changed.maxWork<250,label.." changed completion avoids linear publication work")
    check(changed.newRecords==1024,label.." changed normalized rows created once each")
    check(s.saved.auctions[1].itemCount==3 and (legacy and s.saved.auctions[1].quality==3 or not legacy and s.saved.auctions[1].expirationTime==1030),
        label.." saved quality/expiry fields retained")
    totals.maxFinalWork=math.max(totals.maxFinalWork,first.maxWork,unchanged.maxWork,changed.maxWork)
    totals.stageRows=totals.stageRows+first.stage+unchanged.stage+changed.stage
    totals.pulses=totals.pulses+s.pulses

    if not legacy then
        local oldSaved=s.saved.auctions;local oldGeneration=s.snap.generation
        s.link="item:117:metadata";s.stringAuctionID=true;s:event("OWNED_AUCTIONS_UPDATED");s:drain()
        check(s.snap.generation==oldGeneration and s.saved.auctions==oldSaved,label.." original equality ignores metadata and numeric/string auction-ID representation")
        s.auctionOffset=10000;s:event("OWNED_AUCTIONS_UPDATED");s:drain()
        check(s.snap.generation==oldGeneration+1 and s.saved.auctions[1].auctionID=="10001",label.." auction identity changes still publish")
    end
    s.rows=0;s:event("OWNED_AUCTIONS_UPDATED");s:drain()
    check(next(s.snap.byIndex)==nil and next(s.snap.counts)==nil and #s.saved.auctions==0,label.." empty generation removes all previous ownership")
    local emptyGeneration=s.snap.generation;s:event("OWNED_AUCTIONS_UPDATED");s:drain()
    check(s.snap.generation==emptyGeneration,label.." repeated empty generation is unchanged")

    local slow=boot(legacy,pending,100);slow.nativeCost=.6;slow:open();slow:drain()
    check(slow:measure().maxNative<=2 and slow.pulses==1,label.." slow native getter respects one-ms budget plus current row")

    for _,where in ipairs({"count","row"})do
     for _,action in ipairs({"refresh","close","handoff"})do
        local r=boot(legacy,pending,70)
        local function invalidate()
            if action=="refresh"then r.rows=5;r.quantity=7;r:event("OWNED_AUCTIONS_UPDATED")
            elseif action=="close"then r:event("AUCTION_HOUSE_CLOSED")
            else r.uses=true end
        end
        if where=="count"then r.onCount=invalidate else r.onRead=invalidate end
        r:open();r:drain()
        check(r.errors==0,label.." "..where.." getter "..action.." cannot access discarded job")
        if action=="refresh"then
            check(r.pulses==1 and #r.saved.auctions==5 and r.saved.auctions[1].itemCount==7,label.." "..where.." getter refresh preserves newer generation")
        else
            check(r.pulses==0 and r.saved.auctions==nil and r.snap.generation==0,label.." "..where.." getter "..action.." discards staged publication")
            check(r.nativeReads<=(where=="count" and 0 or 1),label.." "..where.." getter "..action.." stops native work immediately")
        end
        totals.reentryErrors=totals.reentryErrors+r.errors
     end
    end

    local interrupted=boot(legacy,pending,100)
    interrupted:open();interrupted:step(.2)
    check(interrupted.pulses==0 and interrupted.snap.generation==0,label.." partial scan stays private")
    interrupted.rows=5;interrupted.quantity=9;interrupted:event("OWNED_AUCTIONS_UPDATED");interrupted:drain()
    check(interrupted.pulses==1 and #interrupted.saved.auctions==5 and interrupted.saved.auctions[1].itemCount==9,label.." between-frame invalidation publishes only fresh rows")
    local closed=boot(legacy,pending,100);closed:open();closed:step(.2);closed:event("AUCTION_HOUSE_CLOSED");closed:drain()
    check(closed.pulses==0 and closed.snap.generation==0,label.." close drops partial staged snapshot")
    closed.rows=3;closed:open();closed:drain()
    check(closed.pulses==1 and #closed.saved.auctions==3,label.." reopen starts a clean complete snapshot")
    local empty=boot(legacy,pending,0);empty:open();empty:drain()
    check(empty.pulses==1 and empty.snap.generation==1 and #empty.saved.auctions==0,label.." first empty capture is still a real generation")
    local noClock=boot(legacy,pending,70);noClock.env.debugprofilestop=nil;noClock:open();noClock:drain()
    check(noClock.pulses==1 and noClock:measure().maxNative<=32 and noClock:measure().maxPrep<=32,label.." absent optional profiler retains row budget and completion")
    local filtered=boot(legacy,pending,5);filtered.skip=2;if not legacy then filtered.inactive=3 end
    filtered:open();filtered:drain()
    check(#filtered.saved.auctions==(legacy and 4 or 3) and #filtered.snap.byIndex==(legacy and 4 or 3),label.." skipped/inactive native rows keep compact snapshot indexes")
    if legacy then
        local fallback=boot(true,pending,3);fallback.legacyMissingID=true;fallback:open();fallback:drain()
        check(fallback.linkReads==3 and fallback.pulses==1 and #fallback.saved.auctions==3
            and fallback.saved.auctions[1].itemID==118 and fallback.saved.auctions[1].itemLink=="item:118",
            label.." ordinary missing-ID link fallback preserves data")
        for _,action in ipairs({"close","handoff","refresh"})do
            local stopped=boot(true,pending,3);stopped.legacyMissingID=true
            stopped.onRead=function()
                if action=="handoff"then stopped.uses=true
                elseif action=="close"then stopped:event("AUCTION_HOUSE_CLOSED")
                else stopped.rows=1;stopped:event("OWNED_AUCTIONS_UPDATED")end
            end
            stopped:open();stopped:step(.2)
            check(stopped.linkReads==0 and stopped.pulses==0 and stopped.errors==0,
                label.." legacy primary-getter "..action.." stops optional link getter")
            stopped:drain()
            check(action=="refresh" and stopped.linkReads==1 and stopped.pulses==1
                or action~="refresh" and stopped.linkReads==0 and stopped.pulses==0,
                label.." legacy fallback "..action.." retains only current ownership")
        end
    end
 end
end
print(string.format("builtin auction publication: %d checks, %d failures; unchangedFingerprintRows=%d maxUpdateWork=%d unchangedNewRecords=%d reentryErrors=%d publications=%d stagedRowWrites=%d",
    checks,failures,totals.fingerprintRows,totals.maxFinalWork,totals.newUnchangedRows,totals.reentryErrors,totals.pulses,totals.stageRows))
if failures>0 then os.exit(1)end
