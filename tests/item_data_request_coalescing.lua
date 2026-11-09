-- Actual inventory init/container scans; native item data and frames mocked.
-- Optional Init.lua and Containers.lua arguments replay the external baseline.
local initSource = arg[1] or "Inventory/Init.lua"
local containerSource = arg[2] or "Inventory/Containers.lua"
local checks, failures = 0, 0
local totals = {burstRequests=0, burstWaiters=0, dirty=0, pulses=0, retryRequests=0, retained=0, ambiguousIDs=0, idleVisits=0, movedCallbacks=0}
local function check(ok,label)
    checks=checks+1
    if not ok then failures=failures+1;print("FAIL "..label) end
end
local function up(fn,name)
    for index=1,100 do
        local key,value=debug.getupvalue(fn,index)
        if key==name then return value end
        if not key then break end
    end
    error("missing fixture upvalue "..name)
end
local function boot(label)
    local e=setmetatable({}, {__index=_G});e._G=e;e.SlashCmdList={}
    local s={now=0,requests=0,pulses=0,dirty={},frames={},bags={},sizes={},cached={},partial={},partialNoID={},sync=nil,unknown={},unknownSlots={},pendingVisits=0,bankOpen=false}
    local flux={Client={isForever=true,isCamelot=true,isRetail=false},Cap={},Module={Register=function()end},
        Safecall=function(fn,...)return fn(...)end,Scheduler={Request=function()s.pulses=s.pulses+1 end}}
    local ns={Flux=flux}
    e.GetTime=function()return s.now end
    e.CreateFrame=function()
        local f={scripts={},events={}};function f:RegisterEvent(key)self.events[key]=true end
        function f:UnregisterEvent(key)self.events[key]=nil end
        function f:SetScript(k,fn)self.scripts[k]=fn end
        s.frames[#s.frames+1]=f;return f
    end
    local function unknown(bag,slot)
        return s.unknown[bag] or (s.unknownSlots[bag] and s.unknownSlots[bag][slot])
    end
    local function rec(location)
        local bag=s.bags[location.bagID]
        return not unknown(location.bagID,location.slotIndex) and bag and bag[location.slotIndex]
    end
    flux.Container={GetNumSlots=function(bag)return s.sizes[bag] or 0 end,
        GetItemInfo=function(bag,slot)
            if unknown(bag,slot) then return nil,false end
            local r=s.bags[bag] and s.bags[bag][slot]
            if not r then return nil,true end
            if s.partialNoID[bag] and s.partialNoID[bag][slot] then return {iconFileID=1} end
            if s.cached[r.id] then return {itemID=r.id,stackCount=r.count,hyperlink="item:"..r.id} end
            if s.partial[r.id] then return {itemID=r.id,stackCount=r.count} end
            return nil,false
        end}
    e.C_Item={DoesItemExist=function(loc)return not not rec(loc)end,
        GetItemID=function(loc)local r=rec(loc);return r and r.id end,
        GetStackCount=function(loc)local r=rec(loc);return r and r.count end,
        IsItemDataCachedByID=function(id)return s.cached[id] or false end,
        RequestLoadItemDataByID=function(id)
            s.requests=s.requests+1
            if s.sync then
                if s.sync=="success" then s.cached[id]=true end
                s:event(id,s.sync=="success")
            end
        end}
    assert(loadfile(initSource,"t",e))("_FluxUI",ns)
    assert(loadfile(containerSource,"t",e))("_FluxUI",ns)
    local inv=flux.Inventory;inv.source="builtin"
    s.pendingMap=up(inv.RequestItemData,"pendingItemData")
    e.pairs=function(t)
        if t~=s.pendingMap then return pairs(t) end
        return function(map,key)
            local k,v=next(map,key)
            if k~=nil then s.pendingVisits=s.pendingVisits+1 end
            return k,v
        end,t,nil
    end
    inv.Builtin.Bags={MarkDirty=function(bag)s.dirty[bag]=(s.dirty[bag] or 0)+1 end}
    inv.Builtin.Bank={MarkDirty=function(bag)s.dirty[bag]=(s.dirty[bag] or 0)+1 end,IsOpen=function()return s.bankOpen end}
    function s:fill(bag,id,n)
        self.sizes[bag]=n or 10;self.bags[bag]={}
        for slot=1,self.sizes[bag] do self.bags[bag][slot]={id=id,count=slot} end
    end
    function s:scan(bag)
        local scanned=inv.Containers.ScanBag(bag)
        inv.snapshots.bags.byBag[bag]=scanned
        return scanned
    end
    function s:event(id,success)
        for _,frame in ipairs(self.frames) do
            if frame.events.ITEM_DATA_LOAD_RESULT and frame.scripts.OnEvent then
                frame.scripts.OnEvent(frame,"ITEM_DATA_LOAD_RESULT",id,success)
            end
        end
    end
    function s:tick(dt)
        self.now=self.now+dt
        for _,frame in ipairs(self.frames) do
            if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame,dt) end
        end
    end
    function s:advance(seconds)
        for _=1,math.ceil(seconds/.1) do self:tick(.1) end
    end
    function s:armed()
        for _,f in ipairs(self.frames) do if f.scripts.OnUpdate then return true end end
        return false
    end
    function s:pending()
        return up(inv.RequestItemData,"pendingItemData")
    end
    function s:counts()
        local ids,callbacks=0,0
        for _,entry in pairs(self:pending()) do
            ids=ids+1;callbacks=callbacks+#(entry.callbacks or entry)
        end
        return ids,callbacks
    end
    s.inv,s.env=inv,e
    return s
end

for _,client in ipairs({"forever","retail","era","anniversary","mists"}) do
 for _,provider in ipairs({"builtin","provider-pending"}) do
    local label=client.."/"..provider
    local s=boot(label);s:fill(0,123)
    for _=1,100 do s:scan(0) end
    local ids,callbacks=s:counts()
    totals.burstRequests=totals.burstRequests+s.requests;totals.burstWaiters=totals.burstWaiters+callbacks
    check(s.requests==1 and ids==1 and callbacks==1,label.." 100x10 same-ID slots share one request and one bag callback")

    -- One unreadable slot must not retain the history of other known slots.
    local bounded=boot(label.."/ambiguous-history");bounded:fill(0,3000,2)
    bounded.bags[0][2].id=4000;bounded:scan(0);bounded:advance(8.5)
    bounded.unknownSlots[0]={[1]=true}
    for id=4001,5000 do bounded.bags[0][2].id=id;bounded:scan(0) end
    local history=select(1,bounded:counts());totals.ambiguousIDs=totals.ambiguousIDs+history
    check(history==2,label.." persistent ambiguous slot retains one prior owner, not known-slot history")
    bounded.cached[5000]=true;bounded:scan(0)
    check(select(1,bounded:counts())==1 and not bounded.inv.IsScanPending(),label.." ready metadata observed without event releases owner")
    bounded.cached[3000]=true;bounded:event(3000,true)
    check(bounded.dirty[0]==1 and select(1,bounded:counts())==0,label.." retained ambiguous owner still resolves late success")
    local partialInfo=boot(label.."/partial-info");partialInfo:fill(0,5001,1);partialInfo:scan(0)
    partialInfo.partial[5001]=true;partialInfo:scan(0)
    check(select(1,partialInfo:counts())==1,label.." partially available record retains metadata completion owner")
    partialInfo.cached[5001]=true;partialInfo:scan(0)
    check(select(1,partialInfo:counts())==0 and not partialInfo.inv.IsScanPending(),label.." full cached record without event releases metadata owner")

    for _,partial in ipairs({"read","patch"}) do
        local partialBag=boot(label.."/"..partial);partialBag:fill(0,5100,2)
        local slots=partialBag:scan(0);partialBag:advance(8.5)
        partialBag.unknownSlots[0]={[1]=true}
        for id=5101,5200 do
            partialBag.bags[0][2].id=id
            if partial=="read" then partialBag.inv.Containers.ReadSlot(0,2)
            else partialBag.inv.Containers.PatchSlots(slots,0,{[2]=true},{},{}) end
        end
        check(select(1,partialBag:counts())==2,label.." "..partial.." also retires obsolete known-slot history")
        partialBag.bags[0][2]=nil;partialBag.inv.Containers.ReadSlot(0,2)
        check(select(1,partialBag:counts())==1,label.." confirmed empty partial read releases its owner")
        partialBag.sizes[0]=0;partialBag:scan(0)
        check(select(1,partialBag:counts())==1,label.." zero-capacity scan does not discard unreadable old slot")
    end

    local idle=boot(label.."/walk-budget")
    for id=6000,6099 do idle.inv.RequestItemData(id,function()end) end
    idle.pendingVisits=0
    for _=1,100 do idle:tick(.001) end
    totals.idleVisits=totals.idleVisits+idle.pendingVisits
    check(idle.pendingVisits==0,label.." pending map is not walked on every pre-interval frame")

    for _,mode in ipairs({"partial","unreadable"}) do
        local moved=boot(label.."/moved/"..mode);moved:fill(0,7100,2);moved.bags[0][2]=nil
        moved:scan(0);moved:advance(8.5)
        moved.bags[0][1],moved.bags[0][2]=nil,{id=7100,count=7}
        if mode=="partial" then moved.partialNoID[0]={[2]=true}
        else moved.unknownSlots[0]={[2]=true} end
        local observed=moved:scan(0)
        if mode=="partial" then
            check(observed[2] and observed[2].itemID==7100 and observed[2].count==7,
                label.." partial item info still reads physical ID and count")
        end
        moved.cached[7100]=true;moved:event(7100,true)
        totals.movedCallbacks=totals.movedCallbacks+(moved.dirty[0] or 0)
        check(moved.dirty[0]==1 and moved.pulses==1,label.." moved cold item retains late completion through "..mode.." destination")
    end
    for _,order in ipairs({{0,1},{1,0}}) do
        for _,sourceUnknown in ipairs({false,true}) do
            local cross=boot(label.."/cross-bag");cross:fill(0,7150,1);cross:fill(1,7150,1);cross.bags[1]={}
            cross:scan(0);cross:scan(1);cross:advance(8.5)
            cross.bags[0]={};cross.bags[1][1]={id=7150,count=3};cross.unknownSlots[1]={[1]=true}
            if sourceUnknown then cross.unknownSlots[0]={[1]=true} end
            for _,bag in ipairs(order) do cross:scan(bag) end
            cross.cached[7150]=true;cross:event(7150,true)
            check(cross.dirty[1]==1 and cross.dirty[0]==(sourceUnknown and 1 or nil),
                label.." cross-bag move preserves late destination update in both scan orders")
            check(cross.pulses==(sourceUnknown and 2 or 1),label.." cross-bag specific/unknown observers coalesce per bag")
        end
    end
    local seen=boot(label.."/cross-ready");seen:fill(0,7160,1);seen:fill(1,7160,1);seen.bags[1]={}
    seen:scan(0);seen:scan(1);seen:advance(8.5)
    seen.bags[0]={};seen.bags[1][1]={id=7160,count=1};seen.unknownSlots[1]={[1]=true}
    seen:scan(0);seen:scan(1);seen.cached[7160]=true;seen.unknownSlots[1]={};seen:scan(1)
    seen:event(7160,true)
    check(seen.pulses==0 and not seen:armed(),label.." direct ready observation clears cross-bag watcher without requiring event")

    local watch=boot(label.."/wildcard");watch:fill(0,7200,2);watch.bags[0][2]=nil
    watch:scan(0);watch:advance(8.5)
    watch.bags[0][1],watch.bags[0][2]=nil,{id=7200,count=1};watch.unknownSlots[0]={[2]=true};watch:scan(0)
    local requests=watch.requests
    watch:event(9999,false);check(watch.pulses==0,label.." failed unrelated metadata cannot wake unknown bag")
    for id=10000,10999 do watch:event(id,true) end
    check(watch.dirty[0]==1 and watch.pulses==1,label.." unknown bag observer coalesces successful event storm until scan")
    check(not watch:armed() and not watch.inv.IsScanPending() and watch.requests==requests,label.." unknown observer adds no polling or native item requests")
    watch:scan(0);watch:event(11000,true)
    check(watch.dirty[0]==2,label.." scan rechecks unresolved observer readiness")
    watch.unknownSlots[0]={};watch.cached[7200]=true;watch:scan(0)
    local pulses=watch.pulses;watch:event(11001,true)
    check(watch.pulses==pulses,label.." fully readable scan removes obsolete bag observer")

    local same=boot(label.."/coalesced-owner");same:fill(0,7300,3);same.bags[0][2],same.bags[0][3]=nil,nil
    same:scan(0);same:advance(8.5)
    same.bags[0][1],same.bags[0][2],same.bags[0][3]=nil,{id=7300,count=1},{id=7301,count=1}
    same.unknownSlots[0]={[2]=true};same:scan(0);same.cached[7301]=true;same:event(7301,true)
    check(same.dirty[0]==1 and same.pulses==1,label.." specific and bag-wide owners share one completion notification")

    local bank=boot(label.."/closed-bank");bank:fill(-1,7400,2);bank.bags[-1][2]=nil
    bank:scan(-1);bank:advance(8.5)
    bank.bags[-1][1],bank.bags[-1][2]=nil,{id=7400,count=1};bank.unknownSlots[-1]={[2]=true};bank:scan(-1)
    for id=12000,12099 do bank:event(id,true) end
    check(bank.pulses==0 and bank.dirty[-1]==nil,label.." closed bank observer does not schedule hidden scans")
    bank.bankOpen=true;bank:event(12100,true)
    check(bank.dirty[-1]==1 and bank.pulses==1,label.." live bank retains late completion recovery")
    bank.bankOpen=false;bank.inv.SetBankOpenLatch(false)
    bank.bankOpen=true;bank:event(12101,true)
    check(bank.pulses==1,label.." closing bank retires unknown observer until next real scan")
    bank:scan(-1);bank:event(12102,true)
    check(bank.pulses==2,label.." next open bank scan can restore unresolved observer")
    bank.inv.source="syndicator";bank.inv.IsScanPending();bank:event(12101,true)
    check(bank.pulses==2 and not bank:armed(),label.." handoff removes passive bag observer")
    local latest=s:scan(0)
    check(latest[10].itemID==123 and latest[10].count==10,label.." cold fallback preserves every physical count")
    s:fill(1,123);s:scan(1)
    check(s.requests==1 and select(2,s:counts())==2,label.." same item in another bag adds only its distinct owner")
    s.cached[123]=true;s:event(123,true)
    check(s.dirty[0]==1 and s.dirty[1]==1 and s.pulses==2,label.." successful completion refreshes each owning bag once")
    check(not s.inv.IsScanPending() and not s:armed(),label.." synchronous completion disarms idle updater immediately")
    s:event(123,true)
    check(s.pulses==2,label.." duplicate successful completion performs no work")
    totals.dirty=totals.dirty+(s.dirty[0] or 0)+(s.dirty[1] or 0);totals.pulses=totals.pulses+s.pulses

    local mixed=boot(label.."/mixed");mixed:fill(0,201)
    for slot=6,10 do mixed.bags[0][slot].id=202 end
    mixed:scan(0)
    check(mixed.requests==2 and select(1,mixed:counts())==2,label.." distinct cold IDs receive independent requests")
    mixed.cached[201]=true;mixed:event(201,true)
    check(mixed.dirty[0]==1 and mixed.inv.IsScanPending(),label.." one success leaves the other ID pending")
    mixed:scan(0);check(mixed.requests==2,label.." mixed ready/cold rescan cannot duplicate pending ID")
    mixed.cached[202]=true;mixed:event(202,true)
    check(mixed.dirty[0]==2 and not mixed.inv.IsScanPending(),label.." second distinct ID completes independently")
    local owned=boot(label.."/multi-owner");owned:fill(0,203);owned:fill(1,203)
    owned:scan(0);owned:scan(1);owned.bags[0]={};owned:scan(0)
    check(select(2,owned:counts())==1,label.." one bag removal retains the other bag owner")
    owned.cached[203]=true;owned:event(203,true)
    check(owned.dirty[0]==nil and owned.dirty[1]==1,label.." success refreshes only remaining owner")

    local f=boot(label.."/failure");f:fill(0,456);f:scan(0)
    f:event(456,false)
    check(f.pulses==0 and f.dirty[0]==nil,label.." failed metadata is not successful completion")
    check(f.inv.IsScanPending(),label.." failed metadata retains bounded retry opportunity")
    f:advance(.5)
    check(f.requests==2,label.." failed metadata retries only on existing interval")
    f.cached[456]=true;f:event(456,true)
    check(f.dirty[0]==1 and f.pulses==1,label.." later successful result still resolves failed request")

    local t=boot(label.."/timeout");t:fill(0,789);t:scan(0);t:advance(8.5)
    totals.retryRequests=totals.retryRequests+t.requests
    check(t.requests<=4 and t.requests>1,label.." native load retries are finite")
    check(not t.inv.IsScanPending() and not t:armed(),label.." unavailable data releases active scan state at deadline")
    local requests=t.requests;t:advance(60)
    check(t.requests==requests,label.." deadline leaves no background retry work")
    t.cached[789]=true;t:event(789,true)
    check(t.dirty[0]==1 and t.pulses==1,label.." late success after deadline still refreshes owning bag")
    check(select(1,t:counts())==0,label.." late success releases passive ownership state")

    local r=boot(label.."/rearm");r:fill(0,800);r:scan(0);r:advance(8.5)
    local before=r.requests
    for _=1,100 do r:scan(0);r:advance(.5) end
    check(r.requests==before and not r.inv.IsScanPending() and not r:armed(),label.." repeated same-owner scans cannot rearm expired native work")
    local explicit=0;r.inv.RequestItemData(800,function()explicit=explicit+1 end)
    check(r.requests==before+1 and r.inv.IsScanPending(),label.." genuine explicit request can rearm timed-out item")
    r.cached[800]=true;r:event(800,true)
    check(r.dirty[0]==1 and explicit==1,label.." rearm keeps original owner and explicit callback")

    local p=boot(label.."/ownership");p:fill(0,1000)
    for id=1000,1049 do p:fill(0,id);p:scan(0);p:advance(8.5) end
    local retained,waiters=p:counts();totals.retained=totals.retained+retained
    check(retained==1 and waiters==1,label.." passive state stays bounded by latest complete bag contents")
    p.unknown[0]=true;p:scan(0)
    check(select(1,p:counts())==1,label.." ambiguous slot scan cannot discard known late-success owner")
    p.cached[1049]=true;p:event(1049,true)
    check(p.dirty[0]==1,label.." ambiguous-slot late success still schedules rescan")
    p.unknown[0]=false;p:fill(0,1050);p:scan(0);p:advance(8.5)
    p.bags[0]={};p:scan(0)
    check(select(1,p:counts())==0,label.." complete empty scan releases removed-item callbacks")
    local pulses=p.pulses;p.cached[1050]=true;p:event(1050,true)
    check(p.pulses==pulses,label.." removed item success does not refresh obsolete owner")

    local h=boot(label.."/handoff");h:fill(0,900);h:scan(0)
    local native=h.requests;h.inv.source="syndicator";h:advance(.5)
    check(h.requests==native and not h:armed() and not h.inv.IsScanPending(),label.." handoff stops native requests and active wait")
    check(select(1,h:counts())==0,label.." handoff releases builtin callbacks")
    h.cached[900]=true;h:event(900,true)
    check(h.pulses==0,label.." handoff ignores old native completion")
    h.inv.RequestItemData(901,function()error("inactive source callback")end)
    check(h.requests==native and not h:armed(),label.." inactive builtin source cannot start metadata requests")
    h.inv.source="builtin";h:fill(0,901);h:scan(0)
    check(h.requests==native+1,label.." later builtin scan can start fresh after handoff")
    local passive=boot(label.."/passive-handoff");passive:fill(0,902);passive:scan(0);passive:advance(8.5)
    passive.inv.source="syndicator"
    check(not passive.inv.IsScanPending() and select(1,passive:counts())==0,label.." source query also clears passive state on handoff")

    local a=boot(label.."/callbacks");local first,second=0,0
    local cb=function()first=first+1 end;local other=function()second=second+1 end
    for _=1,100 do a.inv.RequestItemData(10,cb) end
    a.inv.RequestItemData(10,other);a.cached[10]=true;a:event(10,true)
    check(a.requests==1 and first==1 and second==1,label.." legitimate distinct callbacks retained; identical function coalesced")
    local reentered=0
    a.inv.RequestItemData(11,function()
        a.inv.RequestItemData(12,function()reentered=reentered+1 end)
    end)
    a.cached[11]=true;a:event(11,true)
    check(a.inv.IsScanPending() and a:armed(),label.." callback can register another owned request")
    a.cached[12]=true;a:event(12,true)
    check(reentered==1 and not a.inv.IsScanPending(),label.." reentrant registration resolves independently")
    local transfer=boot(label.."/sync-handoff")
    local handoff=function()transfer.inv.source="syndicator" end
    transfer.inv.RequestItemData(21,handoff);transfer.inv.RequestItemData(22,handoff)
    transfer.sync="success";transfer:advance(.5)
    check(transfer.requests==3 and not transfer.inv.IsScanPending() and not transfer:armed(),
        label.." synchronous handoff stops remaining retry batch before another native call")

    local y=boot(label.."/sync-success");y:fill(0,321);y.sync="success";y:scan(0)
    check(y.requests==1 and y.dirty[0]==1,label.." synchronous native success resolves installed callback")
    check(not y:armed() and not y.inv.IsScanPending(),label.." synchronous native success cannot leave updater armed")
    local z=boot(label.."/sync-failure");z:fill(0,654);z.sync="failure";z:scan(0);z:advance(8.5)
    check(z.pulses==0 and z.requests<=4 and not z:armed(),label.." synchronous failure cannot create request/rescan feedback loop")

    for _,absent in ipairs({"namespace","request"}) do
        local n=boot(label.."/absence");local delivered=0
        if absent=="namespace" then n.env.C_Item=nil else n.env.C_Item.RequestLoadItemDataByID=nil end
        n.inv.RequestItemData(31,function()delivered=delivered+1 end)
        n:advance(12)
        check(not n.inv.IsScanPending() and not n:armed() and delivered==0,label.." missing "..absent.." cannot leave infinite wait")
    end
 end
end
print(string.format("item-data requests: %d checks, %d failures; burst native requests=%d waiters=%d completion dirty=%d pulses=%d bounded retry requests=%d retained IDs=%d ambiguous IDs=%d pre-interval row visits=%d moved-item callbacks=%d",
    checks,failures,totals.burstRequests,totals.burstWaiters,totals.dirty,totals.pulses,totals.retryRequests,totals.retained,totals.ambiguousIDs,totals.idleVisits,totals.movedCallbacks))
if failures>0 then os.exit(1) end
