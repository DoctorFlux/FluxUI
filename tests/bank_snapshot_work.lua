-- Exact production bank snapshots and provider bridge with synthetic readable
-- native/provider facts. --measure reports work without requiring new budgets.
local root=(arg[1] or '.'):gsub('\\','/'):gsub('/$','')..'/'
local measure=arg[2]=='--measure'
local checks,failures=0,0
local function check(ok,label) checks=checks+1;if not ok then failures=failures+1;print('FAIL '..label)end end
local function budget(ok,label)if not measure then check(ok,label)end end
local function copy(t)local out={};for k,v in pairs(t)do out[k]=type(v)=='table'and copy(v)or v end;return out end
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function boot(provider,family)
 local h={facts={},sizes={},bankids={},warids={},phase=nil,stats={},bankopen=true,trace={},saved={}}
 local e=setmetatable({}, {__index=_G});e._G=e;e.SlashCmdList={};e.GetTime=function()return 100 end
 local function stat(k,n)h.stats[k]=(h.stats[k]or 0)+(n or 1)end
 e.pcall=function(...)stat('protected_calls');return pcall(...)end
 e.pairs=function(t)
  local iter,state,key=pairs(t)
  return function(s,k)local nk,v=iter(s,k);if nk~=nil then stat('all_pairs_visits');if h.phase then stat(h.phase..'_visits')elseif h.inv and t==h.inv.snapshots.bank.counts then stat('unclassified_countmap_visits')end end;return nk,v end,state,key
 end
 e.CreateFrame=function()return{RegisterEvent=function()end,UnregisterEvent=function()end,SetScript=function()end}end
 local flux={Client={[family=='retail'and'isRetail'or family=='era'and'isEra'or family=='anniversary'and'isAnniversary'or family=='mists'and'isMists'or'isForever']=true},
  Cap={},Module={Register=function()end},Container={GetNumSlots=function(bag)return h.sizes[bag]or 0 end,
  GetItemInfo=function(bag,slot)stat('native_slot_reads');local rec=h.facts[bag]and h.facts[bag][slot];return rec and {itemID=rec.itemID,stackCount=rec.count,hyperlink=rec.link}or nil,true end}}
 local ns={Flux=flux};h.env,h.flux,h.ns=e,flux,ns
 assert(loadfile(root..'Inventory/Init.lua','t',e))('_FluxUI',ns)
 local inv=flux.Inventory;h.inv=inv
 assert(loadfile(root..'Inventory/Containers.lua','t',e))('_FluxUI',ns)
 local c=inv.Containers;h.c=c
 inv.HasWarband=function()return h.war==true end
 c.GetCharacterBankIDs=function()return h.bankids end;c.GetWarbandBankIDs=function()return h.warids end
 c.IsCharacterBankContainer=function(bag)return h.facts[bag]~=nil and bag<20 end
 c.IsWarbandBankContainer=function(bag)return h.facts[bag]~=nil and bag>=20 end;c.IsBankContainer=function(bag)return h.facts[bag]~=nil end
 c.IsKeyringBag=function()return false end;c.IsBankReadable=function()return h.bankopen end
 local function meter(owner,name,phase)
  local fn=owner[name];owner[name]=function(...)local prev=h.phase;h.phase=phase;stat(phase..'_calls');local result=table.pack(fn(...));h.phase=prev;return table.unpack(result,1,result.n)end
 end
 meter(inv,'SnapshotCountKeys','snapshot_keys');meter(inv,'ClassifyCountKeys','classify_keys')
 meter(c,'CountsFromByBag','aggregate');meter(inv,'PersistBankCounts','persist')
 inv.Store={BindLive=function(field,t)stat('store_bind');h.saved[field]=t end,MarkPending=function()stat('store_pending');h.saved.pending=true end,
  BindWarbandBank=function(t)stat('store_warbind');h.saved.warband=t end,MarkWarbandPending=function()stat('store_warpending');h.saved.warpending=true end}
 for i=1,8 do local bag=4+i;h.bankids[i]=bag;h.facts[bag]={};h.sizes[bag]=40;for slot=1,40 do h.facts[bag][slot]={itemID=(i-1)*40+slot,count=1,link='item:'..((i-1)*40+slot)}end end
 if provider=='builtin'then
  assert(loadfile(root..'Inventory/Builtin/Bank.lua','t',e))('_FluxUI',ns)
  local b=inv.Builtin.Bank;h.owner=b;b.SetOpen(true);b.Refresh()
  h.refresh=function(dirty)if dirty then for bag in pairs(dirty)do b.MarkDirty(bag)end else b.MarkDirty()end;b.Refresh()end
  h.kind=function()return b.GetLastChangeKind(),b.GetLastAddedItemIDs(),b.GetLastRemovedItemIDs()end
 else
  local char={bank={}};for i,bag in ipairs(h.bankids)do char.bank[i]=h.facts[bag]end
  e.Syndicator={Constants={AllBankIndexes=h.bankids},API={GetCurrentCharacter=function()return'Current-Realm'end,GetCharacter=function()return char end}}
  if family=='forever'then e.Syndicator.Constants.CharacterBankTabsActive=true;char.bankTabs={};for i,bag in ipairs(h.bankids)do char.bankTabs[i]={slots=h.facts[bag]}end end
  assert(loadfile(root..'Inventory/Syndicator/Adapter.lua','t',e))('_FluxUI',ns)
  local a=inv.Syndicator;h.owner=a;a.RebuildBank()
  h.refresh=function(dirty)a.RebuildBank(dirty)end;h.kind=function()return a.GetLastBankChangeKind(),a.GetLastBankAddedItemIDs(),a.GetLastBankRemovedItemIDs()end
 end
 function h:verify(label)
  local expected={};for _,bag in ipairs(self.bankids)do for slot,rec in pairs(self.facts[bag])do if type(slot)=='number'then expected[rec.itemID]=(expected[rec.itemID]or 0)+rec.count end end end
  check(equal(expected,self.inv.snapshots.bank.counts),provider..'/'..family..' '..label..' counts')
  for _,bag in ipairs(self.bankids)do for slot=1,self.sizes[bag]do local a,b=self.facts[bag][slot],self.inv.snapshots.bank.byBag[bag][slot];check((not a and not b)or(a and b and a.itemID==b.itemID and a.count==b.count and a.link==b.link),label..' slot '..bag..'/'..slot)end end
  local kind,added,removed=self.kind();local counts={};for id,n in pairs(self.inv.snapshots.bank.counts)do counts[#counts+1]={id,n}end;table.sort(counts,function(a,b)return a[1]<b[1]end)
  self.trace[#self.trace+1]={label=label,kind=kind,added=copy(added or{}),removed=copy(removed or{}),counts=counts,generation=self.inv.snapshots.bank.generation}
 end
 return h
end
local metrics={};local traces={}
for _,family in ipairs({'forever','retail','era','anniversary','mists'})do for _,provider in ipairs({'builtin','syndicator'})do
 local h=boot(provider,family);h.stats={}
 for n=2,101 do local previous=h.inv.snapshots.bank.counts;local previousCount=previous[1];local generation=h.inv.snapshots.bank.generation;h.facts[5][1].count=n;h.refresh({[5]=true});check(h.inv.snapshots.bank.counts[1]==n,provider..' immediate dirty total');check(h.kind()=='countOnly',provider..' dirty count kind');check(h.inv.snapshots.bank.generation==generation+1,provider..' every refresh advances original generation');check(provider=='builtin'and previous~=h.inv.snapshots.bank.counts and previous[1]==previousCount or provider=='syndicator'and previous==h.inv.snapshots.bank.counts,provider..' aggregate identity contract')end
 metrics[provider..'/'..family]=copy(h.stats)
 budget((h.stats.snapshot_keys_calls or 0)==0 and(h.stats.classify_keys_calls or 0)==0,provider..' dirty path avoids full identity classification')
 if provider=='builtin'then
  budget((h.stats.aggregate_calls or 0)==0 and h.stats.native_slot_reads==4000 and h.stats.unclassified_countmap_visits==32000,'builtin dirty scans preserve slot reads/fresh aggregate copy without full slot aggregation')
  check(h.saved.pending==true and h.saved.bank==h.inv.snapshots.bank.byBag,'changed bank refresh publishes summary/binding immediately')
  local sv=h.env._FluxUI_CharSavedVars
  check(sv and sv.Bank and sv.Bank.charCounts and sv.Bank.charCounts[1]==101 and h.stats.persist_calls==100,'every changed bank refresh persists the current aggregate')
 end
 h:verify('100 count updates')
 h.facts[5][2].itemID=777;h.facts[5][2].link='item:777';h.refresh({[5]=true});local kind,added,removed=h.kind();check(kind=='identityChanged'and added[777]and removed[2],provider..' identity transition');h:verify('replacement')
 local rec=h.facts[5][2];h.facts[5][2]=h.facts[6][2];h.facts[6][2]=rec;h.refresh({[5]=true,[6]=true});check(h.kind()=='countOnly',provider..' identity-preserving move');h:verify('two bags move')
 h.facts[5][1].link='item:1:metadata';h.refresh({[5]=true});h:verify('metadata-only change')
 h.facts[6][2]=nil;h.refresh({[6]=true});kind,added,removed=h.kind();check(kind=='identityChanged'and removed[777],provider..' last-copy remove');h:verify('last-copy remove')
 if provider=='builtin'then
  local saved=h.saved.bank;h.saved.pending=false;h.stats={};for _=1,100 do h.owner.Refresh()end;metrics[provider..'/'..family..'/noop']=copy(h.stats)
  check(h.saved.bank==saved and saved==h.inv.snapshots.bank.byBag,'clean refresh preserves saved live binding')
  budget(not h.saved.pending and not h.stats.store_bind and not h.stats.persist_calls,'clean bank refresh creates no new saved-summary/persist work')
  local generation=h.inv.snapshots.bank.generation;h.owner.SetOpen(false);h.bankopen=false;h.facts[5][1].count=300;h.owner.MarkDirty(5);h.owner.Refresh();check(h.inv.snapshots.bank.counts[1]~=300 and h.inv.snapshots.bank.generation==generation,'closed bank snapshot retained');h.bankopen=true;h.owner.SetOpen(true);h.owner.Refresh();h:verify('reopen full scan')
  -- Failed scans preserve the prior aggregate; a partial byBag publication must
  -- not prevent the next original retry from rebuilding a complete total.
  local oldCounts=h.inv.snapshots.bank.counts;local oldValues=copy(oldCounts);local scan=h.c.ScanBag;local scanned=0
  h.facts[5][3].count=9;h.facts[6][3].count=12
  h.c.ScanBag=function(bag)scanned=scanned+1;if scanned==2 then error('native bank read failed',0)end;return scan(bag)end
  h.owner.MarkDirty(5);h.owner.MarkDirty(6);local ok=pcall(h.owner.Refresh)
  check(not ok and h.inv.snapshots.bank.counts==oldCounts and equal(oldCounts,oldValues),'failed dirty scan retains complete prior aggregate/error')
  h.c.ScanBag=scan;h.owner.Refresh();h:verify('retry after partial read failure')
  -- Synchronous item-data completion can publish another dirty bag from inside
  -- ScanBag. The outer view must include its identity and keep prior maps stable.
  local nested=false;oldCounts=h.inv.snapshots.bank.counts;oldValues=copy(oldCounts)
  h.c.ScanBag=function(bag)if not nested then nested=true;h.facts[6][4]={itemID=999,count=7,link='item:999'};h.owner.MarkDirty(6);h.owner.Refresh()end;return scan(bag)end
  h.facts[5][4].count=16;h.owner.MarkDirty(5);h.owner.Refresh();h.c.ScanBag=scan
  check(equal(oldCounts,oldValues),'nested refresh leaves retained aggregate immutable');h:verify('nested different-bag identity')
  -- Replaced public map identity cannot borrow a private coherence decision.
  h.inv.snapshots.bank.counts={[80000]=1};h.owner.MarkDirty(5);h.owner.Refresh();h:verify('aggregate replacement')
  h.inv.snapshots.bank.counts=nil;h.owner.MarkDirty(5);local cleared=pcall(h.owner.Refresh);check(cleared,'cleared aggregate refresh remains supported');if not cleared then h.owner.Invalidate();h.owner.Refresh()end;h:verify('cleared aggregate replacement')
  h.owner.SetOpen(false);for _,bag in ipairs(h.bankids)do h.sizes[bag]=0 end;h.owner.SetOpen(true)
  oldCounts=h.inv.snapshots.bank.counts;generation=h.inv.snapshots.bank.generation;h.owner.Refresh()
  check(h.inv.snapshots.bank.counts==oldCounts and h.inv.snapshots.bank.generation==generation,'unreadable opening preserves prior facts/generation')
  for _,bag in ipairs(h.bankids)do h.sizes[bag]=40 end;h.owner.Refresh();h:verify('readable opening retry')
  -- The same owner commits character and warband regions separately. A war-only
  -- dirty pass still persists both existing live bindings and exposes removals.
  h.war=true;h.warids={20,21};h.facts[20]={[1]={itemID=1200,count=4,link='item:1200'}};h.facts[21]={[1]={itemID=1300,count=2,link='item:1300'}};h.sizes[20]=1;h.sizes[21]=1
  h.owner.Invalidate();h.owner.Refresh();check(h.inv.snapshots.warband.counts[1200]==4 and h.saved.warband==h.inv.snapshots.warband.byBag,'warband full publish')
  local charGen=h.inv.snapshots.bank.generation;h.facts[20][1]={itemID=1400,count=6,link='item:1400'};h.owner.MarkDirty(20);h.owner.Refresh()
  local changed,adds,rems=h.kind();check(h.inv.snapshots.bank.generation==charGen and h.inv.snapshots.warband.counts[1400]==6 and not h.inv.snapshots.warband.counts[1200]and changed=='identityChanged'and adds[1400]and rems[1200],'war-only refresh keeps char generation and exact merged identities')
  sv=h.env._FluxUI_CharSavedVars
  check(sv and sv.Bank and sv.Bank.warCounts and sv.Bank.warCounts[1400]==6,'war-only refresh persists current shared saved facts')
  -- A failed publication owes its retry even though dirty scans already
  -- committed. Compare raw error identity and the original callback order.
  local publications={{h.inv.Store,'BindLive'},{h.inv.Store,'MarkPending'},
   {h.inv.Store,'BindWarbandBank'},{h.inv.Store,'MarkWarbandPending'},{h.inv,'PersistBankCounts'}}
  local fullOrder='BindLive,MarkPending,BindWarbandBank,MarkWarbandPending,PersistBankCounts'
  for _,failure in ipairs(publications)do
   local order,originals,failed,marker={},{},false,{}
   for _,stage in ipairs(publications)do
    local owner,name=stage[1],stage[2];originals[name]=owner[name]
    owner[name]=function(...)order[#order+1]=name;if name==failure[2]and not failed then failed=true;error(marker,0)end;return originals[name](...)end
   end
   h.facts[5][1].count=h.facts[5][1].count+1;h.owner.MarkDirty(5)
   local generation=h.inv.snapshots.bank.generation;local ok,raw=pcall(h.owner.Refresh)
   check(not ok and rawequal(raw,marker),'publication preserves raw '..failure[2]..' failure')
   check(h.inv.snapshots.bank.counts[1]==h.facts[5][1].count and h.inv.snapshots.bank.generation==generation+1,'failed publication keeps committed live counts')
   local expected={};for _,stage in ipairs(publications)do expected[#expected+1]=stage[2];if stage[2]==failure[2]then break end end
   check(table.concat(order,',')==table.concat(expected,','),'failed publication callback prefix stays ordered')
   order={};h.saved.pending=false;h.stats={};generation=h.inv.snapshots.bank.generation
   local retried=pcall(h.owner.Refresh);sv=h.env._FluxUI_CharSavedVars
   check(retried and h.saved.pending and sv and sv.Bank and sv.Bank.charCounts and sv.Bank.charCounts[1]==h.facts[5][1].count,'clean retry repairs failed '..failure[2]..' publication')
   check(table.concat(order,',')==fullOrder and h.inv.snapshots.bank.generation==generation and not h.stats.native_slot_reads and h.kind()=='none','publication retry has original callbacks, clean metadata and no native rescans')
   for _,stage in ipairs(publications)do stage[1][stage[2]]=originals[stage[2]]end
  end
  local store=h.inv.Store;h.inv.Store=nil;h.facts[5][1].count=h.facts[5][1].count+1;h.owner.MarkDirty(5);h.owner.Refresh()
  h.inv.Store=store;h.saved.pending=false;h.stats={};generation=h.inv.snapshots.bank.generation;h.owner.Refresh()
  check(h.saved.pending and h.saved.bank==h.inv.snapshots.bank.byBag and not h.stats.native_slot_reads and h.inv.snapshots.bank.generation==generation,'late Store recovery publishes already committed facts without rescanning')
  local persist=h.inv.PersistBankCounts;h.inv.PersistBankCounts=nil;h.facts[5][1].count=h.facts[5][1].count+1;h.owner.MarkDirty(5);h.owner.Refresh()
  h.inv.PersistBankCounts=persist;h.stats={};generation=h.inv.snapshots.bank.generation;h.owner.Refresh();sv=h.env._FluxUI_CharSavedVars
  check(sv and sv.Bank and sv.Bank.charCounts and sv.Bank.charCounts[1]==h.facts[5][1].count and not h.stats.native_slot_reads and h.inv.snapshots.bank.generation==generation,'late persistence recovery writes committed facts without rescanning')
  local bind=store.BindLive;local nested,bindCalls=false,0;h.stats={}
  store.BindLive=function(...)bindCalls=bindCalls+1;if not nested then nested=true;h.facts[6][5].count=99;h.owner.MarkDirty(6);h.owner.Refresh()end;return bind(...)end
  h.facts[5][1].count=h.facts[5][1].count+1;h.owner.MarkDirty(5);generation=h.inv.snapshots.bank.generation;h.owner.Refresh();store.BindLive=bind
  check(bindCalls==2 and h.stats.persist_calls==2 and h.inv.snapshots.bank.generation==generation+2,'nested successful publications retain both original immediate callback sequences');h:verify('nested successful publication')
  -- The nested attempt can finish and clear its own debt before the outer
  -- callback throws. The outer failure must still retain a clean retry.
  nested=false;bindCalls=0;local marker={}
  store.BindLive=function(...)bindCalls=bindCalls+1;if not nested then nested=true;h.facts[6][6].count=77;h.owner.MarkDirty(6);h.owner.Refresh();error(marker,0)end;return bind(...)end
  h.facts[5][1].count=h.facts[5][1].count+1;h.owner.MarkDirty(5);local ok,raw=pcall(h.owner.Refresh)
  check(not ok and rawequal(raw,marker)and bindCalls==2,'outer failure survives a successful nested publication')
  h.saved.pending=false;h.stats={};generation=h.inv.snapshots.bank.generation;h.owner.Refresh();store.BindLive=bind
  check(h.saved.pending and bindCalls==3 and h.stats.persist_calls==1 and not h.stats.native_slot_reads and h.inv.snapshots.bank.generation==generation,'outer failed publication retries despite nested debt clearing');h:verify('nested then failed publication retry')
  -- Conversely an outer persist can finish its old work, catch a nested new
  -- publication failure and return success. Only the newer revision owns debt.
  persist=h.inv.PersistBankCounts;nested=false;local nestedResult
  h.inv.PersistBankCounts=function(...)
   persist(...)
   if not nested then
    nested=true;h.facts[6][7].count=88;h.owner.MarkDirty(6)
    store.BindLive=function()error('nested new snapshot publication failure',0)end
    nestedResult=pcall(h.owner.Refresh);store.BindLive=bind
   end
  end
  h.facts[5][1].count=h.facts[5][1].count+1;h.owner.MarkDirty(5);local outer=pcall(h.owner.Refresh);h.inv.PersistBankCounts=persist
  check(outer and nestedResult==false,'outer completion can observe a caught newer nested failure')
  h.saved.pending=false;h.stats={};generation=h.inv.snapshots.bank.generation;h.owner.Refresh();sv=h.env._FluxUI_CharSavedVars
  check(h.saved.pending and sv and sv.Bank and sv.Bank.charCounts and sv.Bank.charCounts[47]==88 and not h.stats.native_slot_reads and h.inv.snapshots.bank.generation==generation,'outer success cannot clear newer nested failed publication');h:verify('outer success keeps nested failure debt')
  -- Character publication is owed as soon as that region commits, even if a
  -- later warband scan throws and is then temporarily unreadable.
  scan=h.c.ScanBag;h.c.ScanBag=function(bag)if bag>=20 then error('warband unavailable',0)end;return scan(bag)end
  h.facts[5][1].count=h.facts[5][1].count+1;h.owner.Invalidate();check(not pcall(h.owner.Refresh),'later region scan error propagates')
  h.c.ScanBag=scan;h.sizes[20],h.sizes[21]=0,0;h.saved.pending=false;h.stats={};generation=h.inv.snapshots.bank.generation;h.owner.Refresh();sv=h.env._FluxUI_CharSavedVars
  check(h.saved.pending and sv and sv.Bank and sv.Bank.charCounts and sv.Bank.charCounts[1]==h.facts[5][1].count and not h.stats.native_slot_reads and h.inv.snapshots.bank.generation==generation,'character commit publishes after later region failed/unreadable')
  h.sizes[20],h.sizes[21]=1,1;h.owner.Refresh()
 end
 traces[provider..'/'..family]=h.trace
end end
local function json(x)
 local typ=type(x);if typ=='nil'then return'null'elseif typ=='boolean'or typ=='number'then return tostring(x)elseif typ=='string'then return string.format('%q',x):gsub('\\\n','\\n')end
 local keys={};for k in pairs(x)do keys[#keys+1]=k end;table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 local rows={};for _,k in ipairs(keys)do rows[#rows+1]=json(tostring(k))..':'..json(x[k])end;return'{'..table.concat(rows,',')..'}'
end
print('METRICS '..json(metrics))
local trace=json(traces);local tracePath=os.getenv('FLUX_BANK_TRACE')
if tracePath then local file=assert(io.open(tracePath,'wb'));file:write(trace);file:close()end
print('TRACE bytes: '..#trace)
print(string.format('bank refresh work: %d checks, %d failures',checks,failures));if failures>0 then os.exit(1)end
