-- Actual owner bank-row regression. Churn is table identity work, not heap/CPU/native FPS.
local root=os.getenv('FLUX_AH_ROOT')or'.'
local adapterSource=arg[1]or(root..'/Inventory/Syndicator/Adapter.lua')
local containerSource=arg[2]or(root..'/Inventory/Containers.lua')
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function loadEnv(path,e)local f,err;if setfenv then f,err=loadfile(path);if f then setfenv(f,e)end else f,err=loadfile(path,'t',e)end;return assert(f,err)end
local function copy(v)if type(v)~='table'then return v end;local o={};for k,x in pairs(v)do o[k]=copy(x)end;return o end
local function eq(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not eq(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function fresh(old,new)local good=true;for slot,row in pairs(new)do if old and row==old[slot]then good=false end end;return good end
local function boot()
 local h={rows={},callbacks={},pending={},timers={},now=100,observations=0,observe=false,publications=0}
 for i=1,98 do h.rows[i]={itemID=10000+i,itemCount=1,itemLink='item:'..(10000+i)}end
 local e=setmetatable({},{__index=_G});e._G=e;e.SlashCmdList={};e.GetTime=function()return h.now end
 e.CreateFrame=function()return{SetScript=function()end,RegisterEvent=function()end}end;e.BankFrame={IsShown=function()return false end}
 e.pairs=function(t)local it,state,key=pairs(t);if not(h.observe and t==h.rows)then return it,state,key end;return function(a,b)local k,v=it(a,b);if k~=nil then h.observations=h.observations+1 end;return k,v end,state,key end
 local function after(d,f)h.timers[#h.timers+1]={at=h.now+d,fn=f}end;e.C_Timer={After=after}
 local flux={Cap={},Client={isForever=true},Module={Register=function()end},Safecall=function(fn,...)return fn(...)end,Timer={After=after},Scheduler={Request=function(_,token)h.pending[token]=true end}}
 e.Flux=flux;local ns={Flux=flux};loadEnv(root..'/Inventory/Init.lua',e)('_FluxUI',ns);loadEnv(containerSource,e)('_FluxUI',ns)
 local inv=flux.Inventory;h.inv=inv;local char={bags={},bankTabs={{slots=h.rows}}}
 e.Syndicator={Constants={AllBagIndexes={},AllBankIndexes={101,102},AllWarbandIndexes={},CharacterBankTabsActive=true},API={IsReady=function()return true end,GetCurrentCharacter=function()return'Fixture-Realm'end,GetCharacter=function()return char end},CallbackRegistry={RegisterCallback=function(_,name,fn)h.callbacks[name]=fn end}}
 loadEnv(adapterSource,e)('_FluxUI',ns);local a=inv.Syndicator;h.a=a;h.c=inv.Containers;h.diff=rawget(h.c,'DiffSlots')
 a.RebuildAll=function()a.RebuildBank()end;a.Start();inv.Notify(h.pending);h.pending={};a.TakeBankItemSets()
 inv.Register('BankReuseFixture',function(ctx)h.ctx=ctx;h.publications=h.publications+1 end,{tier='light',regions={'bank'},sync=true})
 function h.current()return inv.snapshots.bank.byBag[101]end
 function h.pulse(full)h.callbacks.BagCacheUpdate(nil,'Fixture-Realm',{bank={[101]=true},containerBags={bank=full==true}})end
 function h.begin()h.observe=true;h.observations=0;h.ctx=nil;h.publications=0 end
 function h.flush()h.observe=false;if next(h.pending)then inv.Notify(h.pending);h.pending={}end;local n=0;while #h.timers>0 do table.sort(h.timers,function(a,b)return a.at<b.at end);local t=table.remove(h.timers,1);h.now=t.at;t.fn();n=n+1;assert(n<20)end end
 function h.restore()rawset(h.c,'DiffSlots',h.diff);setmetatable(h.c,nil)end
 function h.sum()local n=0;for _,v in pairs(inv.snapshots.bank.counts)do n=n+v end;return n end
 return h
end
local budgets={};local h=boot()
-- Canonical semantics run without replacing DiffSlots. Only the final budgets assert reuse.
for _,mode in ipairs({'unchanged','one-count','one-link'})do
 local old=h.current();local oldValue=copy(old);local oldObjects={};for _,row in pairs(old)do oldObjects[row]=true end
 if mode=='one-count'then h.rows[1].itemCount=2 elseif mode=='one-link'then h.rows[2].itemLink='item:10002:metadata'end
 h.begin();h.pulse();h.flush();local touched,changed=h.a.TakeBankItemSets()
 check(h.observations==98,'canonical observes all98 provider rows')
 check(h.sum()==(mode=='unchanged'and 98 or 99)and h.ctx.changeKind=='countOnly','canonical current values/classification')
 check(eq(old,oldValue),'held canonical old map values immutable')
 if mode=='one-count'then check(touched[10001]and changed[10001],'one-count slot delta')elseif mode=='one-link'then check(touched[10002]and not changed[10002]and h.current()[2].link=='item:10002:metadata','fresh link observation and metadata delta')end
 local made=0;for _,row in pairs(h.current())do if not oldObjects[row]then made=made+1 end end
 budgets[#budgets+1]={mode=mode,newRows=made,limit=mode=='unchanged'and 0 or 1}
end
-- Retained foreign arguments cannot poison a later canonical refresh.
h=boot();local held
h.c.DiffSlots=function(old,new,touched,delta)check(fresh(old,new),'foreign initial rows fresh');held=new;rawset(h.c,'DiffSlots',h.diff);return h.diff(old,new,touched,delta)end
h.begin();h.pulse();h.flush();h.begin();h.pulse();h.flush();held[1].link='retained-only'
check(h.current()[1].link=='item:10001','retained foreign link isolated after return')
-- Restoring canonical inside a foreign callback must not enable nested sharing.
h=boot();local nested=false
h.c.DiffSlots=function(old,new,touched,delta)
 check(fresh(old,new),'nested foreign initial rows fresh')
 if not nested then nested=true;rawset(h.c,'DiffSlots',h.diff);h.a.RebuildBank({[101]=true});new[1].link='nested-only';check(h.current()[1].link=='item:10001','nested foreign link isolated after canonical restore')end
 return h.diff(old,new,touched,delta)
end
local gen=h.inv.snapshots.bank.generation;h.begin();h.pulse();h.flush()
check(h.observations==196 and h.inv.snapshots.bank.generation==gen+2 and h.publications==1,'actual nested reads/generations and one publication')
-- A mid-Fill getter installs a virtual public Diff method. It must run only after Fill,
-- with fresh current rows; no instrumentation replaces canonical Diff in other cases.
for _,throw in ipairs({false,true})do
 h=boot();local old=h.current();local oldValue=copy(old);local token={opaque=true};local lookups=0;local data=h.rows[49];local fired=false
 h.rows[49]=setmetatable({},{__index=function(_,key)
  if h.observe and key=='itemID'and not fired then
   fired=true;rawset(h.c,'DiffSlots',nil);setmetatable(h.c,{__index=function(_,name)
    if name~='DiffSlots'then return nil end;lookups=lookups+1
    check(h.observations==98 and fresh(old,h.current()),'late getter sees fresh bank rows after Fill')
    if throw then error(token,0)end
    return function(o,n,t,d)n[1].link='foreign-link';return h.diff(o,n,t,d)end
   end})
  end
  return data[key]
 end})
 local before=h.inv.snapshots.bank.generation;h.begin();local ok,err=pcall(h.pulse);h.flush();if not throw then assert(ok,err)end
 check(lookups==1 and eq(old,oldValue),'one late public lookup and immutable old values')
 if throw then check(not ok and err==token and h.publications==0 and h.inv.snapshots.bank.generation==before,'late getter exact raw error boundary')
 else local touched,changed=h.a.TakeBankItemSets();check(ok and h.current()[1].link=='foreign-link'and touched[10001]and not changed[10001],'foreign link mutation retains diff semantics')end
 h.restore();local prior=h.current();h.begin();h.pulse();h.flush();check(fresh(prior,h.current()),'late getter revocation remains sticky')
end
-- Even old=nil must revoke before foreign exposure; later canonical rows stay fresh.
h=boot();h.inv.snapshots.bank.byBag[101]=nil;h.inv.snapshots.bank.counts={};local data=h.rows[1];local fired=false
h.rows[1]=setmetatable({},{__index=function(_,key)
 if h.observe and key=='itemID'and not fired then fired=true;h.c.DiffSlots=function(o,n,t,d)check(fresh(o,n),'oldnil foreign rows fresh');return h.diff(o,n,t,d)end end
 return data[key]
end})
h.begin();h.pulse();h.flush();check(h.sum()==98,'oldnil current provider facts')
h.restore();local prior=h.current();h.begin();h.pulse();h.flush();check(fresh(prior,h.current()),'oldnil exposure permanently revokes')
-- Full rebuild does not reset revocation, and keeps its original fresh row behavior.
h.begin();h.pulse(true);h.flush();check(h.sum()==98,'full current facts');prior=h.current();h.begin();h.pulse();h.flush();check(fresh(prior,h.current()),'full does not reenable revoked reuse')
print('SEMANTICS_PASS '..checks)
for _,x in ipairs(budgets)do print('CHURN '..x.mode..' '..x.newRows..' '..x.limit)end
for _,x in ipairs(budgets)do check(x.newRows<=x.limit,x.mode..' normalized row churn budget: '..x.newRows..' > '..x.limit)end
print('PASS '..checks..' checks')
