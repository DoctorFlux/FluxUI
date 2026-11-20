-- Actual Adapter/Containers/Init regression. Desktop iteration work, not native latency/FPS.
local root=os.getenv('FLUX_AH_ROOT')or'.'
local source=arg[1]or(root..'/Inventory/Syndicator/Adapter.lua')
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local function loadEnv(path,env)
 local f,err
 if setfenv then f,err=loadfile(path);if f then setfenv(f,env)end else f,err=loadfile(path,'t',env)end
 return assert(f,err)
end
local function boot(region)
 local h={callbacks={},pending={},latest=nil,publications=0,visits=0,active=false,tracked={},timers={},now=100}
 local env=setmetatable({},{__index=_G});env._G=env;env.GetTime=function()return h.now end;env.SlashCmdList={}
 env.CreateFrame=function()return{SetScript=function()end,RegisterEvent=function()end}end
 env.BankFrame={IsShown=function()return false end}
 env.pairs=function(t)
  local iter,state,key=pairs(t)
  if not(h.active and h.tracked[t])then return iter,state,key end
  return function(a,b)local k,v=iter(a,b);if k~=nil then h.visits=h.visits+1 end;return k,v end,state,key
 end
 local function after(delay,fn)h.timers[#h.timers+1]={at=h.now+delay,fn=fn}end
 env.C_Timer={After=after}
 local flux={Cap={},Client={isForever=true},Module={Register=function()end},Safecall=function(fn,...)return fn(...)end,Timer={After=after},Scheduler={Request=function(_,token)h.pending[token]=true end}}
 env.Flux=flux;local ns={Flux=flux}
 for _,path in ipairs({'Inventory/Init.lua','Inventory/Containers.lua'})do loadEnv(root..'/'..path,env)('_FluxUI',ns)end
 local inv=flux.Inventory;h.inv=inv
 local ids=region=='bags'and{0,1}or{101,102};h.ids=ids
 local rows={{{itemID=100,itemCount=2},{itemID=100,itemCount=3},{itemID=200,itemCount=1}},{{itemID=100,itemCount=4},{itemID=900,itemCount=1}}}
 local char={bags={},bankTabs={}}
 if region=='bags'then char.bags=rows else char.bankTabs={{slots=rows[1]},{slots=rows[2]}}end
 env.Syndicator={Constants={AllBagIndexes=region=='bags'and ids or{},AllBankIndexes=region=='bank'and ids or{},CharacterBankTabsActive=true},API={IsReady=function()return true end,GetCurrentCharacter=function()return'Fixture-Realm'end,GetCharacter=function()return char end},CallbackRegistry={RegisterCallback=function(_,name,fn)h.callbacks[name]=fn end}}
 loadEnv(source,env)('_FluxUI',ns);local adapter=inv.Syndicator
 adapter.RebuildAll=function()adapter.RebuildBags();adapter.RebuildBank()end
 adapter.Start();inv.Notify(h.pending);h.pending={};adapter.TakeBankItemSets()
 inv.Register('PartialWorkFixture',function(ctx)h.latest=ctx;h.publications=h.publications+1 end,{tier='light',regions={region},sync=true})
 function h.set(i,newRows)rows[i]=newRows;if region=='bags'then char.bags[i]=newRows else char.bankTabs[i]={slots=newRows}end end
 function h.pulse(dirty)h.callbacks.BagCacheUpdate(nil,'Fixture-Realm',{[region]=dirty,containerBags={}})end
 function h.flush()
  if next(h.pending)then inv.Notify(h.pending);h.pending={}end
  local n=0;while #h.timers>0 do table.sort(h.timers,function(a,b)return a.at<b.at end);local t=table.remove(h.timers,1);h.now=t.at;t.fn();n=n+1;assert(n<20,'bounded fixture timers')end
  return h.latest
 end
 function h.itemSets()if region=='bags'then return h.latest.touchedItemIDs,h.latest.changedItemIDs end;return adapter.TakeBankItemSets()end
 function h.count(id)return inv.snapshots[region].counts[id]or 0 end
 function h.trackOld()
  h.tracked={};local n=0
  for _,slots in pairs(inv.snapshots[region].byBag)do h.tracked[slots]=true;for _ in pairs(slots)do n=n+1 end end
  h.active=true;h.visits=0;return n
 end
 h.rows,h.adapter,h.region=rows,adapter,region;return h
end
for _,region in ipairs({'bags','bank'})do
 local h=boot(region);local a,b=h.ids[1],h.ids[2]
 -- Plain aggregate-only state can disagree with retained old slots. False is recorded, not unset.
 h.inv.snapshots[region].counts[100]=nil;h.inv.snapshots[region].counts[777]=25
 h.pulse({[a]=true,[b]=true});local ctx=h.flush()
 check(h.count(100)==5 and h.count(777)==25,region..' aggregate-only facts retained')
 check(ctx.changeKind=='identityChanged'and ctx.addedItemIDs[100],region..' first false survives cross-bag refill')
 -- Cross-bag move keeps aggregate identity; last-copy removal changes it.
 h=boot(region);a,b=h.ids[1],h.ids[2]
 h.set(1,{{itemID=100,itemCount=2},{itemID=100,itemCount=3}})
 h.set(2,{{itemID=100,itemCount=4},{itemID=900,itemCount=1},{itemID=200,itemCount=1}})
 h.pulse({[a]=true,[b]=true});ctx=h.flush();local touched,changed=h.itemSets()
 check(h.count(100)==9 and h.count(200)==1 and ctx.changeKind=='countOnly',region..' cross-bag totals/classification')
 check(ctx.dirtyBags[a]and ctx.dirtyBags[b],region..' both dirty bags retained')
 check(touched[200]and not changed[200],region..' moved slot touched without count delta')
 h.set(2,{{itemID=100,itemCount=4},{itemID=900,itemCount=1}})
 h.pulse({[b]=true});ctx=h.flush();h.itemSets()
 check(h.count(200)==0 and ctx.changeKind=='identityChanged'and ctx.removedItemIDs[200],region..' final copy removal')
 -- Same-ID stack swap also needs the public slot diff, even though total count is unchanged.
 h.set(1,{{itemID=100,itemCount=3},{itemID=100,itemCount=2}})
 h.pulse({[a]=true});ctx=h.flush();touched,changed=h.itemSets()
 check(h.count(100)==9 and ctx.changeKind=='countOnly',region..' same-total slot swap countOnly')
 check(touched[100]and not changed[100],region..' same-total slot swap touched only')
 -- Dynamic public method errors retain exact raw object and original partial-write boundary.
 h=boot(region);a=h.ids[1];local snap=h.inv.snapshots[region];local generation=snap.generation;local token={opaque=true};local calls=0
 local diff=h.inv.Containers.DiffSlots
 h.inv.Containers.DiffSlots=function(old,new,touchedSet,delta)calls=calls+1;check(old~=new and new==snap.byBag[a],region..' dynamic diff destination');error(token,0)end
 h.rows[1][1].itemCount=5;local ok,err=pcall(h.pulse,{[a]=true});h.inv.Containers.DiffSlots=diff;h.flush()
 check(not ok and err==token and calls==1,region..' raw public diff error')
 check(h.count(100)==12 and snap.generation==generation and h.publications==0,region..' partial write precedes error and no later publication')
end
-- All semantic assertions run before the work budget, so the original fails only redundant work.
local work={}
for _,region in ipairs({'bags','bank'})do
 local h=boot(region);local n=h.trackOld();h.pulse({[h.ids[1]]=true,[h.ids[2]]=true});h.active=false;local ctx=h.flush()
 check(n==5 and h.count(100)==9 and h.count(200)==1 and ctx.changeKind=='countOnly',region..' measured event facts')
 work[#work+1]={region=region,visits=h.visits,budget=2*n}
end
print('SEMANTICS_PASS '..checks)
for _,x in ipairs(work)do print('WORK '..x.region..' '..x.visits..' '..x.budget)end
for _,x in ipairs(work)do check(x.visits<=x.budget,x.region..' old-slot iteration budget: '..x.visits..' > '..x.budget)end
print('PASS '..checks..' checks')
