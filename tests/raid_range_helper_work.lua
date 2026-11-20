-- Offline only: complete production Compat/Unit modules, actual registered
-- Bind/OnShow/OnHide/ticker/export paths; native widgets come from the existing
-- raid runtime fixture. No client, settings or saved diagnostics are read.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function loadenv(s,n,m,e)
 if _VERSION=='Lua 5.1'then local f,err=loadstring(s,n);if f then setfenv(f,e)end;return f,err end
 return load(s,n,m,e)
end
local nativePairs=pairs
local function installOrderedRangePairs(e)
 e.pairs=function(t)
  if t~=e.FluxRaidState.frameArray and t~=e.FluxRaidState.partyRangeFrames then return nativePairs(t)end
  local keys={};for k in nativePairs(t)do keys[#keys+1]=k end
  table.sort(keys,function(a,b)return a.nameID<b.nameID end)
  local i=0;return function()i=i+1;local k=keys[i];if k then return k,t[k]end end
 end
end
local prefix=read('tests/raid_healer_runtime.lua')
prefix=prefix:sub(1,assert(prefix:find('local function exercise(client,body)',1,true))-1)
local needle='    assert(load(body or unitSource,"@FluxRaidUnit","t",e))'
assert(prefix:find(needle,1,true),'complete Unit fixture admission marker')
prefix=prefix:gsub('    assert%(load%(body or unitSource,"@FluxRaidUnit","t",e%)%)',
 '    installOrderedRangePairs(e)\n    assert(load(body or unitSource,"@FluxRaidUnit","t",e))',1)
local compatTable={};for k,v in pairs(table)do compatTable[k]=v end;compatTable.unpack=table.unpack or unpack
local outer=setmetatable({load=loadenv,table=compatTable,installOrderedRangePairs=installOrderedRangePairs},{__index=_G});outer._G=outer
local fixture=assert(loadenv(prefix..'\nreturn fixture','@complete-runtime-fixture','t',outer))()
local source=read(os.getenv('FLUX_RANGE_HELPER_SOURCE') or arg[1] or 'RaidFrame/FluxRaidUnit.lua')
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local function exerciseSource(source)
local results={}
for _,client in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
 local e,cell,fire,flush,pending,facts,calls,queries,options,registered,tickers=fixture(client,source)
 local trace={};local rows={}
 local function note(s)trace[#trace+1]=s end
 local a,b,p=cell('A'),cell('B'),cell('Party')
 local list={a,b,p}
 for _,f in ipairs(list)do
  local original=f.IsVisible
  f.IsVisible=function(self)note('visible:'..self.nameID);return original(self)end
 end
 local originalEnabled=e.FluxRaid_IsFluxRaidEnabled
 e.FluxRaid_IsFluxRaidEnabled=function()note('enabled');return originalEnabled()end
 local originalRange=e.FluxRaid_UpdateRange
 e.FluxRaid_UpdateRange=function(f)note('paint:'..f.nameID);return originalRange(f)end
 local timerAPI=e.C_Timer.NewTicker
 e.C_Timer.NewTicker=function(interval,fn)
  note('start:'..interval);local t=timerAPI(interval,fn);t.cancels=0;local cancel=t.Cancel
  t.Cancel=function(self)note('cancel');self.cancels=self.cancels+1;return cancel(self)end
  return t
 end
 local function active()local n=0;for _,t in ipairs(tickers)do if not t.cancelled then n=n+1 end end;return n end
 local function phase(label,fn)
  trace={};fn();local out={label,table.concat(trace,','),'timers='..#tickers,'active='..active()}
  for _,f in ipairs(list)do
   out[#out+1]=f.nameID..':'..tostring(f.unit)..':'..tostring(f._fluxRangeEventSupported)..':'..tostring(f.shown)
    ..':'..tostring(f._fluxContent and f._fluxContent.alpha)
  end
  rows[#rows+1]=table.concat(out,'|')
 end
 phase('supported-native',function()
  e.FluxRaid_BindUnit(a,'party1');e.FluxRaid_BindUnit(b,'party2');e.FluxRaid_BindUnit(p,'raid1')
  e.FluxRaid_EnsureRangePoll();check(#tickers==0,'supported native events remain ticker-free')
 end)
 phase('first-fallback-show',function()
  local register=a.RegisterUnitEvent
  a.RegisterUnitEvent=function(self,event,...)
   if event=='UNIT_IN_RANGE_UPDATE'then error('unsupported native event')end
   return register(self,event,...)
  end
  e.FluxRaidUnit_OnShow(a)
  check(#tickers==1 and tickers[1].interval==.25,'actual OnShow starts existing cadence')
 end)
 phase('two-pools',function()
  b._fluxRangeEventSupported=false;p._fluxRangeEventSupported=false
  e.FluxRaidState.frameArray[p]=nil;e.FluxRaidState.partyRangeFrames={[p]=p}
  e.FluxRaid_EnsureRangePoll();tickers[1].fn()
  local n=0;for _,s in ipairs(trace)do if s:find('paint:',1,true)==1 then n=n+1 end end
  check(n==3 and #tickers==1,'ticker paints every current fallback owner in both pools')
 end)
 phase('hide-one',function()a.shown=false;e.FluxRaidUnit_OnHide(a);check(active()==1,'other live owners retain ticker')end)
 phase('late-painter',function()
  e.FluxRaid_UpdateRange=function(f)note('replacement:'..f.nameID);return originalRange(f)end
  tickers[1].fn();check(table.concat(trace,','):find('replacement:B',1,true),'ticker resolves current global painter')
 end)
 phase('late-visibility',function()
  b.IsVisible=function()note('changed-visible:B');return false end
  tickers[1].fn();check(not table.concat(trace,','):find('replacement:B',1,true),'ticker resolves current owner visibility method')
 end)
 phase('disabled',function()e.enabled=false;e.FluxRaid_EnsureRangePoll();check(tickers[1].cancels==1,'current enable state stops ticker')end)
 phase('restart',function()
  e.enabled=true;e.FluxRaid_EnsureRangePoll()
  check(#tickers==2 and tickers[1].fn~=tickers[2].fn,'ticker callback identity remains fresh across restart')
 end)
 phase('replace-raid-pool',function()
  e.FluxRaidState.frameArray={};tickers[2].fn();check(active()==1,'new raid pool does not retire current party pool')
  check(not table.concat(trace,','):find('changed-visible:B',1,true),'retired pool is not retained by a helper')
 end)
 phase('replace-party-pool',function()e.FluxRaidState.partyRangeFrames={};tickers[2].fn();check(active()==0,'new empty pools retire polling')end)
 phase('late-timer-api',function()
  e.FluxRaidState.frameArray={[b]=b};b.IsVisible=function(self)note('restored-visible:B');return self.shown end
  local timer=e.C_Timer.NewTicker;e.C_Timer.NewTicker=nil;e.FluxRaid_EnsureRangePoll();check(#tickers==2,'missing timer API does not create resources')
  e.C_Timer.NewTicker=function(interval,fn)note('new-timer-api');return timer(interval,fn)end
  e.FluxRaid_EnsureRangePoll();check(#tickers==3 and tickers[3].fn~=tickers[2].fn,'late timer API remains current')
 end)
 phase('visibility-error',function()
  local old=b.IsVisible;local marker={};b.IsVisible=function()error(marker,0)end
  local ok,err=pcall(e.FluxRaid_EnsureRangePoll);check(not ok and rawequal(err,marker),'exact native visibility failure propagates')
  b.IsVisible=old;check(active()==1,'read failure does not lose old timer owner')
 end)
 phase('painter-error',function()
  local old=e.FluxRaid_UpdateRange;local marker={};e.FluxRaid_UpdateRange=function()error(marker,0)end
  local ok,err=pcall(tickers[3].fn);check(not ok and rawequal(err,marker),'exact native painter error propagates');e.FluxRaid_UpdateRange=old
 end)
 phase('ticker-reentry',function()
  local once=true
  e.FluxRaid_UpdateRange=function(f)
   note('reentrant:'..f.nameID)
   if once then once=false;e.enabled=false;e.FluxRaid_EnsureRangePoll();e.enabled=true;e.FluxRaid_EnsureRangePoll()end
   return originalRange(f)
  end
  tickers[3].fn();check(not once and #tickers==4 and tickers[3].cancels==1 and active()==1,'reentrant cancellation/restart keeps new ticker owner')
  check(tickers[3].fn~=tickers[4].fn,'reentrant restart retains a fresh timer callback')
 end)
 phase('late-enable-callback',function()
  e.FluxRaid_IsFluxRaidEnabled=function()note('new-disabled-callback');return false end
  e.FluxRaid_EnsureRangePoll();check(active()==0,'replacement enable callback is observed without cached capability results')
  e.FluxRaid_IsFluxRaidEnabled=function()note('restored-enable-callback');return originalEnabled()end
  e.FluxRaid_EnsureRangePoll();check(active()==1,'replacement enable callback can restore current demand')
 end)
 phase('missing-enable-callback',function()
  e.FluxRaid_IsFluxRaidEnabled=nil;e.FluxRaid_EnsureRangePoll();check(active()==1,'absent optional enable callback preserves fallback')
 end)
 phase('final-hide',function()b.shown=false;e.FluxRaidUnit_OnHide(b);check(active()==0,'last owner hide stops fallback')end)
 for _,row in ipairs(rows)do results[#results+1]=client..'|'..row end
end
return results
end
local results=exerciseSource(source)

-- Private helper extraction must never retain current globals, state pools,
-- ticker identity, or a prior native failure. Mutate the real source bodies.
local first=source:find('-- Shared range helpers keep per-discovery state in arguments only.',1,true)
    or assert(source:find('EnsureRangePoll = function(frame)',1,true))
local last=assert(source:find('function FluxRaid_EnsureRangePoll()',first,true))
local prefix,range,suffix=source:sub(1,first-1),source:sub(first,last-1),source:sub(last)
local function replaceOnce(text,old,new)
 local a,b=text:find(old,1,true);assert(a,'negative control marker: '..old)
 return text:sub(1,a-1)..new..text:sub(b+1)
end
local function rejects(declaration,body,label)
 local text=prefix..declaration..body..suffix
 check(loadenv(text,'@range-helper-negative-syntax','t',{})~=nil,'negative control compiles: '..label)
 local ok=pcall(exerciseSource,text)
 check(not ok,'negative control rejected: '..label)
end
rejects('local cachedRangePainter=FluxRaid_UpdateRange\n',
 replaceOnce(range,'if paint then FluxRaid_UpdateRange(btn) end','if paint then cachedRangePainter(btn) end'),'stale global painter')
rejects('local cachedRangeEnable=FluxRaid_IsFluxRaidEnabled\n',
 replaceOnce(range,'(not FluxRaid_IsFluxRaidEnabled or FluxRaid_IsFluxRaidEnabled())','(not cachedRangeEnable or cachedRangeEnable())'),'stale enable callback')
local stalePool,n=range:gsub('PollSet%(State%.frameArray,','PollSet(cachedRangePool,')
check(n==2,'pool control covers discovery and ticker current-state paths')
rejects('local cachedRangePool=State.frameArray\n',stalePool,'stale replaced State pool')
local a=assert(range:find('    rangePollTicker = C_Timer.NewTicker(0.25, function()',1,true))
local b=assert(range:find('\n    end)\nend',a,true))
local head='    rangePollTicker = C_Timer.NewTicker(0.25, function()'
local body=range:sub(a+#head,b-1)
local reused=range:sub(1,a-1)..'    cachedRangeTicker = cachedRangeTicker or function()'..body
 ..'\n    end\n    rangePollTicker = C_Timer.NewTicker(0.25, cachedRangeTicker)'..range:sub(b+#'\n    end)')
rejects('local cachedRangeTicker\n',reused,'reused per-ticker callback identity')
rejects('local function swallowedRangeVisible(btn)local ok,value=pcall(btn.IsVisible,btn);return ok and value end\n',
 replaceOnce(range,'and btn.IsVisible and btn:IsVisible()','and btn.IsVisible and swallowedRangeVisible(btn)'),'concealed native visibility failure')
if os.getenv('FLUX_RANGE_HELPER_EMIT_TRACE')=='1'then
 for _,row in ipairs(results)do print('TRACE|'..row)end
end
print('Raid range helper work: '..checks..' checks PASS; complete owners, current callbacks/pools, fresh ticker identity and5rejected controls; native behavior/timing pending')
