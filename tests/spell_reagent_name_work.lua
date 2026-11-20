-- Whole production SpellReagents owners, with private closures reached by debug
-- only for precise input/state injection. No production function body is copied.
-- Defaults are the current production owner; optional source arguments allow
-- an unchanged baseline and an external candidate to be compared before editing.
local baseline = (arg and arg[1]) or "Inventory/SpellReagents.lua"
local candidate = (arg and arg[2]) or baseline
local cancel = arg and arg[3]
local function stop()
 if not cancel then return end
 local f=io.open(cancel,'rb');if f then f:close();error('ROOT CANCEL',0)end
end
local checks,cases=0,0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local function up(fn,wanted,seen)
 seen=seen or{};if seen[fn]then return end;seen[fn]=true
 local fs={}
 for i=1,100 do
  local name,value=debug.getupvalue(fn,i);if not name then break end
  if name==wanted then return value,fn,i end
  if type(value)=='function'then fs[#fs+1]=value end
 end
 for _,child in ipairs(fs)do local value,owner,index=up(child,wanted,seen);if owner then return value,owner,index end end
end
local function get(fn,name)local value,owner=up(fn,name);assert(owner,'missing actual production upvalue '..name);return value end
local function serial(value)
 if type(value)~='table'then return type(value)..':'..tostring(value)end
 local keys={};for k in pairs(value)do keys[#keys+1]=k end;table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 local parts={};for _,k in ipairs(keys)do parts[#parts+1]=serial(k)..'='..serial(value[k])end;return'{'..table.concat(parts,',')..'}'
end
local function boot(source,cold)
 local st={visible={},names={},byName={},trace={},notifications=0,migrations=0,timers={}}
 local e=setmetatable({}, {__index=_G});e._G=e
 local spells={Refresh=function()return cold==true end}
 local inv={CreateSpells=spells,GetUniqueItems=function()
  st.trace[#st.trace+1]='unique';if st.onUnique then st.onUnique()end;return st.visible
 end}
 e.FluxInv={Spells=spells}
 e.C_Timer={After=function(delay,fn)st.timers[#st.timers+1]={delay,fn}end}
 e.C_Item={GetItemNameByID=function(id)
  st.trace[#st.trace+1]='name:'..tostring(id)
  if st.onName then st.onName(id)end
  if st.nameError then error(st.nameError,0)end
  return st.names[id]
 end,GetItemInfoByName=function(name)st.trace[#st.trace+1]='byName:'..name;return st.byName[name]end}
 e.GetItemInfo=function(value)st.trace[#st.trace+1]='legacy:'..tostring(value)end
 e.C_Spell={GetSpellInfo=function(id)return{name='Thread Spell',spellID=id}end,GetSpellSubtext=function()return'Rank 1'end}
 e.FluxRestockList={OnActiveReagentsFinalized=function()st.migrations=st.migrations+1 end}
 e.FluxRestock={Inv={Notify=function()st.notifications=st.notifications+1 end}}
 assert(loadfile(source,'t',e))('_FluxUI',{Flux={Inventory=inv}})
 local remember=get(spells.OnVisibleItemsChanged,'RememberItemName')
 local a={env=e,spells=spells,remember=remember,lookup=get(spells.OnVisibleItemsChanged,'GetItemIDFromName'),
  names=get(remember,'nameToItemID'),pending=get(remember,'pendingReagentNames'),
  blacklist=get(spells.IsBlacklistedReagent,'IsBlacklistedReagent'),
  rows=get(spells.OnVisibleItemsChanged,'reagentBySpell')}
 function a.snapshot()return serial({names=a.names,pending=a.pending,rows=a.rows,trace=st.trace,notifications=st.notifications,migrations=st.migrations})end
 function a.warmed(value)local _,owner,index=up(spells.AreReagentsWarmed,'reagentsWarmDone');debug.setupvalue(owner,index,value)end
 return a,st
end
local function run(source)
 local results={}
 local function case(label,body,cold)
  stop();cases=cases+1
  local a,s=boot(source,cold);body(a,s)
  results[#results+1]=label..':'..a.snapshot()
 end
 case('native-lowercase-keys',function(a)
  for i,name in ipairs({'FlAx FiBeR','already lowercase','ÄÖÜß Étoffe','魔法粉末','МАГИЧЕСКАЯ ПЫЛЬ','A\0B','Rune of Portals'})do
   a.pending[name:lower()]=true;a.remember(300+i,name)
   eq(a.names[name:lower()],300+i,'language-native lower key');eq(a.pending[name:lower()],nil,'matching pending key cleared')
  end
 end)
 case('fresh-key-alias-history',function(a,s)
  s.visible={[302]=true};s.names[302]='Alias FiBeR';a.remember(301,'alias fiber')
  a.spells.OnVisibleItemsChanged();s.visible={}
  eq(a.lookup('  Alias Fiber  '),302,'latest observed alias persists after disappearance')
  s.visible={[303]=true};s.names[303]='Different Name';a.spells.OnVisibleItemsChanged();s.visible={}
  eq(a.lookup('alias fiber'),302,'new name does not erase older alias');eq(a.lookup('different name'),303,'per-call fresh key')
 end)
 case('dynamic-blacklist',function(a)
  a.pending['soul shard']=true;a.remember(301,'SOUL SHARD');eq(a.names['soul shard'],nil,'built-in blacklist');eq(a.pending['soul shard'],true,'blacklist pending untouched')
  eq(a.blacklist(6265,'Äme SeELENSplitter'),true,'ID6265 learns localized name')
  a.pending[('Äme SeELENSplitter'):lower()]=true;a.remember(302,'Äme SeELENSplitter')
  eq(a.names[('Äme SeELENSplitter'):lower()],nil,'learned blacklist');eq(a.pending[('Äme SeELENSplitter'):lower()],true,'learned blacklist pending untouched')
  a.remember(303,'Ordinary Thread');eq(a.names['ordinary thread'],303,'unrelated names remain valid')
 end)
 case('invalid-and-coerced-ids',function(a)
  a.remember(nil,'X');a.remember(false,'X');a.remember({},'X');a.remember(301,nil);a.remember(301,false);a.remember(301,'')
  eq(next(a.names),nil,'original early exits');a.remember('302','Fiber');eq(a.names.fiber,302,'numeric string ID coercion')
 end)
 case('stringlike-lookup-sequence',function(a,s)
  local calls=0;local value=setmetatable({}, {__index=function(_,key)
   s.trace[#s.trace+1]='index:'..key;return function()calls=calls+1;s.trace[#s.trace+1]='lower:'..calls;return'key'..calls end
  end})
  a.pending.key1=true;a.pending.key2=true;a.remember(301,value)
  eq(calls,2,'nonstring lower invocation count');eq(a.names.key1,301,'first custom key writes history');eq(a.pending.key1,true,'first key not used to clear pending');eq(a.pending.key2,nil,'second custom key clears pending')
 end)
 for _,failure in ipairs({1,2})do case('stringlike-error-'..failure,function(a,s)
  local marker={};local count=0;local value=setmetatable({}, {__index=function(_,key)
   s.trace[#s.trace+1]='index:'..key;return function()count=count+1;s.trace[#s.trace+1]='lower:'..count;if count==failure then error(marker,0)end;return'fiber'end
  end})
  local ok,err=pcall(a.remember,301,value);eq(ok,false,'raw custom lower error');eq(err==marker,true,'custom lower error identity');eq(count,failure,'custom lower stopped at original call')
  eq(a.names.fiber,failure==2 and 301 or nil,'partial first write retained')
 end)end
 case('nonstring-method-absence',function(a)
  for _,value in ipairs({true,7,{}})do local ok=pcall(a.remember,301,value);eq(ok,false,'original invalid method failure')end
 end)
 case('stringlike-reentry',function(a,s)
  local calls=0;local value=setmetatable({}, {__index=function(_,key)
   s.trace[#s.trace+1]='index:'..key;return function()calls=calls+1;a.remember(310+calls,'Nested '..calls);return'outer'end
  end})
  a.remember(301,value);eq(calls,2,'custom lower reentry cadence');eq(a.names['nested 1'],311,'first nested remember');eq(a.names['nested 2'],312,'second nested remember');eq(a.names.outer,301,'outer remember retained')
 end)
 case('native-name-error',function(a,s)
  local marker={};s.visible={[302]=true};s.nameError=marker
  local ok,err=pcall(a.spells.OnVisibleItemsChanged);eq(ok,false,'native raw failure');eq(err==marker,true,'native error identity')
 end)
 case('native-name-reentry',function(a,s)
  s.visible={[302]=true};s.names[302]='Alias Fiber';s.onName=function(id)s.onName=nil;a.remember(301,'Alias Fiber')end
  a.spells.OnVisibleItemsChanged();eq(a.names['alias fiber'],302,'outer fresh value wins after reentry')
 end)
 case('nested-harvest-reentry',function(a,s)
  s.visible={[302]=true};s.names[302]='Outer Fiber';s.names[303]='Inner Fiber'
  s.onName=function()s.onName=nil;s.visible={[303]=true};a.spells.OnVisibleItemsChanged()end
  a.spells.OnVisibleItemsChanged();eq(a.names['outer fiber'],302,'outer name retained');eq(a.names['inner fiber'],303,'inner name retained')
 end)
 case('merchant-name-fallback-order',function(a,s)
  a.env.GetMerchantNumItems=function()s.trace[#s.trace+1]='merchantCount';return 2 end
  a.env.GetMerchantItemLink=function(i)s.trace[#s.trace+1]='merchantLink:'..i;return'item:'..(400+i)end
  a.env.GetMerchantItemInfo=function(i)s.trace[#s.trace+1]='merchantInfo:'..i;if i==1 then return'Merchant Étoffe'end end
  s.names[402]='Native Fallback';a.spells.OnVisibleItemsChanged()
  eq(a.names[('Merchant Étoffe'):lower()],401,'merchant direct string retained');eq(a.names['native fallback'],402,'merchant missing name native fallback retained')
 end)
 case('merchant-stringlike-path',function(a,s)
  local calls=0;local value=setmetatable({}, {__index=function(_,key)
   s.trace[#s.trace+1]='merchant-index:'..key;return function()calls=calls+1;s.trace[#s.trace+1]='merchant-lower:'..calls;return'key'..calls end
  end})
  a.env.GetMerchantNumItems=function()return 1 end
  a.env.GetMerchantItemLink=function()return'item:401'end
  a.env.GetMerchantItemInfo=function()return value end
  a.pending.key1=true;a.pending.key2=true;a.spells.OnVisibleItemsChanged()
  eq(calls,2,'public merchant stringlike lower count');eq(a.names.key1,401,'public merchant first key');eq(a.pending.key2,nil,'public merchant second key')
 end)
 case('pending-migration',function(a,s)
  a.warmed(true);a.pending['alias fiber']=true;a.rows[17]={{name='Alias Fiber'}}
  a.remember(301,'Alias Fiber');s.visible={[302]=true};s.names[302]='Alias Fiber'
  eq(a.spells.OnVisibleItemsChanged(),true,'unresolved row resolves even after pending cleared')
  eq(a.rows[17][1].itemID,302,'fresh alias drives migration');eq(s.migrations,1,'migration hook retained');eq(s.notifications,1,'inventory hook retained')
 end)
 case('cold-refresh',function(a,s)
  s.visible={[302]=true};s.names[302]='Cold Fiber';eq(a.spells.Refresh(),true,'real cold original refresh')
  eq(a.spells.AreReagentsWarmed(),true,'empty spellbook warm completed');eq(a.names['cold fiber'],302,'cold finalize harvest retained')
 end,true)
 return results
end
local before=run(baseline);local after=run(candidate)
eq(#before,#after,'same actual whole-source cases')
for i=1,#before do eq(before[i],after[i],'actual state/native trace parity case '..i)end
-- This isolated work assertion applies only to the candidate/current owner.
-- The semantic comparison above still permits the old baseline's redundant calls.
-- Count the ordinary intrinsic directly, without a wrapper or timed assertion.
local workCases=0
local work=boot(candidate)
local intrinsicLower=string.lower
local function lowerBound(label,expected,fn)
 stop();workCases=workCases+1
 local calls=0
 debug.sethook(function(event)
  if event=="call" then
   local info=debug.getinfo(2,"f")
   if info and info.func==intrinsicLower then calls=calls+1 end
  end
 end,"c")
 local ok,err=pcall(fn)
 debug.sethook()
 assert(ok,err)
 eq(calls,expected,label.." intrinsic string.lower work bound")
end
lowerBound("ordinary primitive string",1,function()work.remember(401,"First FiBeR")end)
lowerBound("blacklisted primitive string",1,function()work.remember(402,"SOUL SHARD")end)
lowerBound("invalid ID",0,function()work.remember(nil,"Invalid FiBeR")end)
lowerBound("empty name",0,function()work.remember(403,"")end)
lowerBound("fresh following string",1,function()work.remember(404,"Second FiBeR")end)
eq(work.names["first fiber"],401,"work bound retained earlier distinct key")
eq(work.names["second fiber"],404,"work bound computes fresh following key")
print(("SPELL_REAGENT_NAMES %d checks/%d owner-cases/%d isolated-work-cases PASS; complete production owner, no CPU assertions"):format(checks,cases,workCases))
