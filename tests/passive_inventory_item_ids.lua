-- Full production Index and exact SpellReagents harvester bodies.
-- Compare fresh ID membership/read traces against the public record query.
-- Consumer authority oracle independently exercises the legacy public query
-- contract in every extension fixture; it does not depend on candidate guards.
-- Args: Index.lua source, SpellReagents.lua source, optional cancellation sentinel.
do
local source,cancel=arg[1]or"Inventory/Index.lua",arg[3]
local checks=0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..": "..tostring(a).." ~= "..tostring(b))end
local function stop()local f=cancel and io.open(cancel,"rb");if f then f:close();error("ROOT CANCEL",0)end end
local function boot(cap)
 local e=setmetatable({},{__index=_G});e._G=e
 local inv={snapshots={},HasWarband=function()return cap end}
 for _,r in ipairs({"bags","bank","warband","equip","mail","void","auctions","guild"})do inv.snapshots[r]={byBag={},bySlot={},byIndex={},counts={[999999]=77}}end
 assert(loadfile(source,"t",e))("_FluxUI",{Flux={Inventory=inv,Item={GetCount=function()error("unexpected native count")end}}})
 return inv,e
end
local function keys(t)local k={};for id in pairs(t or{})do k[#k+1]=id end;return k end
local function compare(a,b,label)
 local ka,kb=keys(a),keys(b);eq(#ka,#kb,label.." key count")
 for i,id in ipairs(ka)do eq(kb[i],id,label.." native iteration order");eq(b[id]~=nil,true,label.." ID membership")end
end
for _,family in ipairs({"Retail","Forever","MoP","Era","Anniversary"})do
 stop();local inv,e=boot(family=="Retail"or family=="Forever")
 inv.snapshots.bags.byBag={[0]={[1]={itemID=11,count=3,link="bag"},[2]={itemID="12",count="4"},[3]={itemID=0,count=0},[4]={itemID=-1,count=-2},[5]={itemID="bad",count=99},[6]=false}}
 inv.snapshots.bank.byBag={[7]={[1]={itemID=11,count=2,link="bank"},[2]={itemID=15,count=2}}}
 inv.snapshots.warband.byBag={[13]={[1]={itemID=11,count=7,link="account"}}}
 inv.snapshots.equip.bySlot={[5]={itemID=12,count=1,link="equipped"},[6]={itemID=16,count=3}}
 inv.snapshots.mail.byIndex={[2]={itemID=12,count=2,link="mail"},[3]={itemID=17,count=9}}
 inv.snapshots.auctions.byIndex={[8]={itemID=11,count=1,link="auction"},[9]={itemID=18,count=2}}
 for _,opts in ipairs({{}, {bank=true,warband=true,equipped=true,mail=true,auctions=true},{includeBank=true,warband=true,bank=false},{bank=true,warband=true,includeBank=false},{bags=false},{bags=false,bank=true},{bags=false,equipped=true},{bags=false,mail=true},{bags=false,auctions=true}})do
  local rows,ids=inv.GetUniqueItems(opts),inv.GetUniqueItemIDs(opts);compare(rows,ids,family)
  eq(ids[999999],nil,"counts-only persisted facts must not invent visible locations")
  local again=inv.GetUniqueItemIDs(opts);eq(rawequal(ids,again),false,"fresh ID map")
  for id in pairs(ids)do ids[id]=nil end;compare(rows,again,"caller cannot mutate later query")
 end
 local a,b=inv.GetUniqueItems(),inv.GetUniqueItems();eq(rawequal(a[11],b[11]),false,"public rows still fresh");eq(a[11].count,3,"public count intact");eq(a[11].link,"bag","public link intact")
end
-- Compare exact option/record/metatable/read/reentry traces against the unchanged public query.
local function traceQuery(method,scenario)
 local inv,e=boot(true);local trace={};local entered=false
 local function rec(id,count,link)
  return setmetatable({},{__index=function(_,key)
   trace[#trace+1]="field:"..tostring(id)..":"..key
   if scenario=="error"and key=="count"then error(scenario,0)end
   if key=="itemID"then return id elseif key=="count"then return count elseif key=="link"then return link end
  end})
 end
 local bags={[0]={[1]=rec(1,2,nil),[2]=rec(1,3,"later"),[3]=rec(1,4,"last"),[4]=rec(2,1,false)}}
 inv.snapshots.bags.byBag=bags;inv.snapshots.equip.bySlot={[4]=rec(2,2,"equip-does-not-fill"),[5]=rec(3,3,"fresh-equipped")}
 inv.snapshots.mail.byIndex={[1]=rec(2,4,"mail-fills"),[2]=rec(3,1,"ignored")}
 e.pairs=function(t)
  trace[#trace+1]="pairs:"..(t==bags and"bags"or t==bags[0]and"slots"or t==inv.snapshots.equip.bySlot and"equip"or t==inv.snapshots.mail.byIndex and"mail"or"other")
  if scenario=="reentry"and t==bags and not entered then
   entered=true;trace[#trace+1]="nested-start"
   local nested=inv[method]({bags=false,mail=true});eq(nested[2]~=nil,true,"nested map populated");eq(nested[1],nil,"nested output independent")
   bags[0][5]=rec(4,7,"late");trace[#trace+1]="nested-end"
  end
  return pairs(t)
 end
 e.tonumber=function(value)trace[#trace+1]="number:"..tostring(value);return tonumber(value)end
 inv.HasWarband=function()trace[#trace+1]="capability";return true end
 local opts=setmetatable({},{__index=function(_,key)trace[#trace+1]="opts:"..key;return (key=="warband"or key=="equipped"or key=="mail")and true or nil end,__newindex=function()error("opts mutation")end})
 local ok,result=pcall(inv[method],opts)
 return trace,ok,result
end
for _,scenario in ipairs({"normal","reentry","error"})do
 local ta,oka,a=traceQuery("GetUniqueItems",scenario);local tb,okb,b=traceQuery("GetUniqueItemIDs",scenario)
 eq(oka,okb,scenario.." raw success");eq(table.concat(ta,"|"),table.concat(tb,"|"),scenario.." exact getter/query trace")
 if oka then compare(a,b,scenario)else eq(a,b,"same raw failure value")end
end
-- Public extension seams remain live on every call, including nil/error/reentry results.
do
 local inv,e=boot(true);local originalInv=inv.GetUniqueItems;local originalIndex=inv.Index.GetUniqueItems
 local opts={bags=true};local answer={[17]={count=9}};local calls=0
 inv.GetUniqueItems=function(o)calls=calls+1;eq(o,opts,"Inventory override exact opts identity");return answer end
 eq(inv.GetUniqueItemIDs(opts),answer,"Inventory replacement delegated by identity");eq(calls,1,"one override call")
 inv.GetUniqueItems=function()return nil end;eq(inv.GetUniqueItemIDs(opts),nil,"nil override preserved")
 local marker={};inv.GetUniqueItems=function()error(marker,0)end
 local ok,err=pcall(inv.GetUniqueItemIDs,opts);eq(ok,false,"Inventory override error propagates");eq(err,marker,"Inventory raw error identity")
 inv.GetUniqueItems=originalInv
 inv.Index.GetUniqueItems=function(o)calls=calls+1;eq(o,opts,"Index override exact opts identity");return answer end
 eq(inv.GetUniqueItemIDs(opts),answer,"Index replacement delegated by identity")
 inv.Index.GetUniqueItems=function()return false end;eq(inv.GetUniqueItemIDs(opts),false,"false override preserved")
 inv.Index.GetUniqueItems=function()error(marker,0)end
 ok,err=pcall(inv.GetUniqueItemIDs,opts);eq(ok,false,"Index override error propagates");eq(err,marker,"Index raw error identity")
 inv.Index.GetUniqueItems=originalIndex
 local entered=false
 inv.snapshots.bags.byBag={[0]={{itemID=1,count=1}}}
 e.pairs=function(t)
  if not entered then entered=true;inv.Index.GetUniqueItems=function()return answer end end
  return pairs(t)
 end
 local current=inv.GetUniqueItemIDs(opts);eq(current[1]~=nil,true,"entered traversal remains own current query");eq(current[17],nil,"late replacement waits for next query")
 eq(inv.GetUniqueItemIDs(opts),answer,"next query observes late replacement")
end
print(("FRESH_IDS_FUNCTIONAL_CHECKS %d PASS"):format(checks))

-- This is an allocation/work bound, not a machine-dependent CPU assertion.
do
 local inv=boot(true);local slots={};inv.snapshots.bags.byBag[0]=slots
 for i=1,121 do slots[i]={itemID=10000+i,count=1,link="item:"..i}end
 local opts={bags=true,bank=true,warband=true}
 local function allocation(fn)
  fn(opts);collectgarbage("collect");collectgarbage("stop")
  local before=collectgarbage("count")
  for i=1,20 do fn(opts)end
  local delta=collectgarbage("count")-before;collectgarbage("restart");collectgarbage("collect")
  return delta
 end
 local records,ids=allocation(inv.GetUniqueItems),allocation(inv.GetUniqueItemIDs)
 eq(ids<records*.5,true,"121-ID harvest allocates less than half of unused record-map construction")
 compare(inv.GetUniqueItems(opts),inv.GetUniqueItemIDs(opts),"allocation path retains all fresh keys")
 print(("FRESH_IDS_ALLOCATION recordsKiB20=%.4f idsKiB20=%.4f PASS"):format(records,ids))
end

end
do
local nextIndex,nextSpell,cancel=arg[1]or"Inventory/Index.lua",arg[2]or"Inventory/SpellReagents.lua",arg[3]
local baseIndex,baseSpell,expectSame=nextIndex,nextSpell,true
local function read(p)local f=assert(io.open(p,"rb"));local text=f:read("*a"):gsub("\r\n","\n");f:close();return text end
local function stop()local f=cancel and io.open(cancel,"rb");if f then f:close();error("ROOT CANCEL",0)end end
local checks,differences=0,0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..": "..tostring(a).." ~= "..tostring(b))end
local function run(index,spell,kind,when,disablePrivateQuery)
 stop()
 local env=setmetatable({},{__index=_G});env._G=env
 local inv={snapshots={},HasWarband=function()return true end}
 for _,r in ipairs({"bags","bank","warband","equip","mail","void","auctions","guild"})do inv.snapshots[r]={byBag={},bySlot={},byIndex={},counts={}}end
 inv.snapshots.bags.byBag[0]={{itemID=123,count=1,link="item:123"}}
 local flux={Inventory=inv};local ns={Flux=flux};local trace={}
 assert(load(read(index),"@whole-Index-authority","t",env))("_FluxUI",ns)
 local idx=inv.Index
 local function custom(owner)
  owner.GetUniqueItems=nil;local reads=0
  setmetatable(owner,{__index=function(_,key)
   if key=="GetUniqueItems"then
    reads=reads+1;local which=reads;trace[#trace+1]="get:"..which
    return function(opts)
     eq(opts.bags,true,"bags opts");eq(opts.bank,true,"bank opts");eq(opts.warband,true,"warband opts")
     trace[#trace+1]="call:"..which;return{[700+which]={count=1}}
    end
   end
  end})
 end
 local function foreignItems(opts)trace[#trace+1]="custom";return{[999]={count=1}}end
 local function foreignIDs(opts)trace[#trace+1]="foreign-ids";return{[888]=true}end
 local function mutate()
  if kind=="facade"then custom(inv)
  elseif kind=="delegated"then custom(idx)
  elseif kind=="namespace-copy"then flux.Inventory={GetUniqueItems=foreignItems,GetUniqueItemIDs=inv.GetUniqueItemIDs}
  elseif kind=="namespace-forged-owner"then
   local other={GetUniqueItems=foreignItems,GetUniqueItemIDs=inv.GetUniqueItemIDs};other.owner=other;other.query=other.GetUniqueItemIDs;flux.Inventory=other
  elseif kind=="optional-helper"then inv.GetUniqueItemIDs=foreignIDs
  elseif kind=="optional-index-helper"then idx.GetUniqueItemIDs=foreignIDs
  elseif kind=="both-helpers"then inv.GetUniqueItems=foreignItems;inv.GetUniqueItemIDs=foreignIDs
  elseif kind=="both-index-helpers"then idx.GetUniqueItems=foreignItems;idx.GetUniqueItemIDs=foreignIDs
  elseif kind=="inherited-optional"then
   inv.GetUniqueItemIDs=nil;setmetatable(inv,{__index=function(_,key)if key=="GetUniqueItemIDs"then trace[#trace+1]="optional-accessor";return foreignIDs end end})
  elseif kind=="replace-public-index-table"then inv.Index={GetUniqueItems=foreignItems,GetUniqueItemIDs=foreignIDs}
  elseif kind=="private-record-absent"then ns.InventoryUniqueItemIDQuery=nil
  elseif kind=="query-nil"then inv.GetUniqueItems=function()trace[#trace+1]="nil";return nil end
  elseif kind=="query-false"then inv.GetUniqueItems=function()trace[#trace+1]="false";return false end
  elseif kind=="query-error"then inv.GetUniqueItems=function()trace[#trace+1]="error";error("raw-marker",0)end
  elseif kind=="getter-replaces-helper"then
   inv.GetUniqueItems=nil;local reads=0;setmetatable(inv,{__index=function(_,key)
    if key=="GetUniqueItems"then reads=reads+1;local which=reads;trace[#trace+1]="get:"..which;inv.GetUniqueItemIDs=foreignIDs;return function()trace[#trace+1]="call:"..which;return{[700+which]={}}end end
   end})
  elseif kind~="native-replaces-namespace"and kind~="ordinary"then error("unknown case:"..kind)end
 end
 if when=="before"then mutate()end
 local text=read(spell);local first=assert(text:find("local function RememberItemName(",1,true));local last=assert(text:find("\nlocal function GetItemIDFromName(",first,true))
 local capture="";local captureStart=text:find("-- Only Index.lua can establish",1,true)
 if captureStart then capture=text:sub(captureStart,assert(text:find("local wipe =",captureStart,true))-1)end
 -- Synthetic Name<ID> authority cases are nonblacklisted; supply the extracted helper dependency.
 local chunk="local Flux,ns=...\n"..capture.."\nlocal nameToItemID,pendingReagentNames={},{}\nlocal blacklistedReagentNames={}\nlocal function IsSoulShardName()return false end\n"..text:sub(first,last-1).."\nreturn HarvestVisibleItemNames\n"
 local harvest=assert(load(chunk,"@actual-Harvest-authority","t",env))(flux,ns)
 -- Independent legacy public-query contract, rather than a disabled candidate guard.
 -- These fixtures return named numeric IDs and have no merchant API.
 if disablePrivateQuery then
  harvest=function()
   local api=flux and flux.Inventory
   if api and api.GetUniqueItems then
    local set=api.GetUniqueItems({bags=true,bank=true,warband=true})
    if type(set)=="table"then
     for itemID in pairs(set)do
      itemID=tonumber(itemID)
      if itemID then env.C_Item.GetItemNameByID(itemID)end
     end
    end
   end
  end
 end
 if when=="after"then mutate()end
 local changed=false
 env.C_Item={GetItemNameByID=function(id)
  trace[#trace+1]="name:"..id
  if kind=="native-replaces-namespace"and not changed then changed=true;flux.Inventory={GetUniqueItems=foreignItems,GetUniqueItemIDs=inv.GetUniqueItemIDs}end
  return"Name"..id
 end}
 env.GetItemInfo=nil;env.GetMerchantNumItems=nil;env.GetMerchantItemLink=nil
 local ok,err=pcall(harvest);trace[#trace+1]="ok:"..tostring(ok)
 if not ok then trace[#trace+1]="error:"..tostring(err)end
 if kind=="native-replaces-namespace"then harvest()end
 return table.concat(trace,"|")
end
for _,when in ipairs({"before","after"})do
 for _,kind in ipairs({"ordinary","facade","delegated","namespace-copy","namespace-forged-owner","optional-helper","optional-index-helper","both-helpers","both-index-helpers","inherited-optional","replace-public-index-table","private-record-absent","query-nil","query-false","query-error","getter-replaces-helper","native-replaces-namespace"})do
  local before=run(baseIndex,baseSpell,kind,when,true);local after=run(nextIndex,nextSpell,kind,when)
  if before~=after then differences=differences+1 end
  print("AUTHORITY_CASE "..when.."/"..kind.." SAME="..tostring(before==after));print("BASE "..before);print("CAND "..after)
  if expectSame then eq(before,after,when.."/"..kind.." exact legacy observable trace")end
 end
end
if not expectSame then eq(differences>=3,true,"blocked C0 negative control exposes authority/accessor changes")end
print(("C1_AUTHORITY_CHECKS %d PASS; differences=%d; expectSame=%s"):format(checks,differences,tostring(expectSame)))

end
do
-- Extracted unchanged production private functions; candidate guards external.
-- All item/native/inventory/context inputs are explicit synthetic facts.
local source,cancel=arg[2]or"Inventory/SpellReagents.lua",arg[3]
local function cancelled()if not cancel then return false end;local f=io.open(cancel,'rb');if f then f:close();return true end end
assert(not cancelled(),'ROOT CANCEL')
local f=assert(io.open(source,'rb'));local src=f:read('*a'):gsub('\r\n','\n');f:close()
local first=assert(src:find('local function RememberItemName(',1,true))
local finish=assert(src:find('\nlocal function AddReagentNamesFromText',first,true))
local helpers=src:sub(first,finish-1)
first=assert(src:find('local function ResolvePendingReagentNames(',1,true))
finish=assert(src:find('\nlocal function rebuildReagents()',first,true))
local resolution=src:sub(first,finish-1)
first=assert(src:find('local function UpdateVisibleReagentNames(',1,true)
    or src:find('function Spells.OnVisibleItemsChanged()',1,true))
finish=assert(src:find('\nfunction Spells.UsesReagents(',first,true))
local public=src:sub(first,finish-1)
local checks=0;local function check(v,s)checks=checks+1;assert(v,s)end
local function boot(mode)
 local state={visible={},names={},nativeByName={},calls={},migrations=0,notifies=0}
 local e=setmetatable({}, {__index=_G});e._G=e
 local Flux={Inventory={GetUniqueItems=function(opts)
  state.calls[#state.calls+1]='unique'
  if state.onUnique then state.onUnique()end
  return state.visible
 end}}
 state.inventory=Flux.Inventory
 e.C_Item={GetItemNameByID=function(id)
  state.calls[#state.calls+1]='name:'..id
  if state.nameError then error(state.nameError,0)end
  return state.names[id]
 end,GetItemInfoByName=function(name)return state.nativeByName[name]end}
 e.GetItemInfo=function()end
 e.FluxRestockList={OnActiveReagentsFinalized=function(migrations)state.migrations=state.migrations+1 end}
 e.FluxRestock={Inv={Notify=function()state.notifies=state.notifies+1 end}}
 local body=helpers
 local resolve=resolution
 if mode=='pending' then resolve=resolve:gsub('    HarvestVisibleItemNames%(%)','    if next(pendingReagentNames) then HarvestVisibleItemNames() end',1)
 elseif mode=='unresolved' then resolve=resolve:gsub('    HarvestVisibleItemNames%(%)','    if HasUnresolved() then HarvestVisibleItemNames() end',1)
 elseif mode=='lazy' then
  resolve=resolve:gsub('    HarvestVisibleItemNames%(%)','',1)
  body=body:gsub('    local cached = nameToItemID%[key%]','    HarvestVisibleItemNames()\n    local cached = nameToItemID[key]',1)
 end
 local prefix=[[
local Flux=...
local snapshotItemIDOwner,snapshotItemIDs
local nameToItemID,pendingReagentNames,reagentBySpell={},{},{}
local allReagentItemIDs,spellsUsingReagent,activeReagentItemIDs,maxRankReagentSpell={},{},{},{}
local RUNE_NAME_IDS={};local Spells={};local FinalizeActiveReagents
local reagentsWarmDone=true
-- Synthetic history names are nonblacklisted; mirror the same private helper dependency.
local blacklistedReagentNames={}
local function IsSoulShardName()return false end
local function IsBlacklistedReagent()return false end
local function GetSpellBaseNameKey(id)return 'family'..id end
local function RankScore(id)return id end
local function wipe(t)for k in pairs(t)do t[k]=nil end end
local function HasUnresolved()for _,rows in pairs(reagentBySpell)do for _,r in ipairs(rows)do if not r.itemID and r.name then return true end end end;return false end
]]
 local ending=[[
return {observe=Spells.OnVisibleItemsChanged,lookup=GetItemIDFromName,remember=RememberItemName,
 row=function(name,pending)local r={name=name};reagentBySpell[17]={r};if pending then pendingReagentNames[name:lower()]=true end;return r end,
 active=function(id)return activeReagentItemIDs[id]==true end}
]]
 local api=assert(load(prefix..body..resolve..public..ending,'@actual-SpellReagents-private-'..mode,'t',e))(Flux)
 return api,state
end

local a,s=boot('baseline');s.visible={[302]=true};s.names[302]='Future Fiber'
a.observe();s.visible={};check(a.lookup('Future Fiber')==302,'unconditional first harvest retains disappeared name history')
a,s=boot('baseline');a.remember(301,'Alias Fiber');s.visible={[302]=true};s.names[302]='Alias Fiber'
a.observe();s.visible={};check(a.lookup('Alias Fiber')==302,'known alias still updates before future cold lookup')
a,s=boot('baseline');local row=a.row('Alias Fiber',true);a.remember(301,'Alias Fiber');s.visible={[302]=true};s.names[302]='Alias Fiber'
check(a.observe()==true,'pending-empty unresolved row still updates');check(row.itemID==302,'migration resolves fresh alias ID')
check(s.migrations==1 and s.notifies==1,'same migration notification');check(a.active(302),'same finalized public active set')
a,s=boot('baseline');local token={raw=true};s.visible={[302]=true};s.names[302]='Fiber';s.nameError=token
local ok,err=pcall(a.observe);check(ok==false and err==token,'same raw native error object')
a,s=boot('baseline');local count=0;s.onUnique=function()count=count+1;a.lookup('NoSuchName')end
a.observe();check(count==1,'public unique seam and reentrant lookup still invoked')
-- Provider-off legacy Inventory table with no optional method must still use the original seam.
a,s=boot('baseline');s.visible={[302]=true};s.names[302]='Fiber';setmetatable(s.inventory,{__index=function(_,key)error('unexpected optional metatable getter:'..key)end})
a.observe();check(a.lookup('Fiber')==302,'missing optional API uses raw lookup and unchanged public fallback')
check(s.calls[1]=='unique'and s.calls[2]=='name:302','fallback query/name order exact')
-- Nonfunction optional member also falls back; fallback false/nil do not trigger extra calls.
a,s=boot('baseline');s.inventory.GetUniqueItemIDs=true;s.visible={[302]=true};s.names[302]='Fiber';a.observe();check(a.lookup('Fiber')==302,'nonfunction optional member uses legacy public query')
a,s=boot('baseline');s.inventory.GetUniqueItems=function()count=count+1;return nil end;count=0;a.observe();check(count==1,'public nil result queried once')
a,s=boot('baseline');s.inventory.GetUniqueItems=function()error(token,0)end;ok,err=pcall(a.observe);check(not ok and err==token,'public fallback raw error retained')
print('FRESH_HARVEST_HISTORY_FALLBACK '..checks..' checks PASS; extracted exact production helper/public bodies')

end
