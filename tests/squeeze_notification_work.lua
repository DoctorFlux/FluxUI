-- Actual notification transaction. Callback order/arguments/errors and native
-- recovery stay intact; function identities expose per-exit closure allocation.
-- Optional: --source <exact baseline> --measure. No native timing/FPS claim.
local path='FluxDefaultSettings.lua';local measuring=false
for i,v in ipairs(arg or {})do if v=='--source'then path=assert(arg[i+1])elseif v=='--measure'then measuring=true end end
local f=assert(io.open(path,'rb'));local source=f:read('*a'):gsub('\r\n','\n');f:close()
local first=source:find('-- Squeeze callback bodies are shared across notifications.',1,true)
 or assert(source:find('function FluxUILayoutSqueeze.NotifyLayoutDependents()',1,true))
local body=source:sub(first,assert(source:find('local squeezeRefreshScheduled',first,true))-1)
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local function loadenv(s,e)
 if _VERSION=='Lua 5.1'then local fn,err=loadstring(s,'@actual-squeeze-notification');if fn then setfenv(fn,e)end;return fn,err end
 return load(s,'@actual-squeeze-notification','t',e)
end
local function fixture(modern)
 local s={trace={},seen={},errors={},factor=1,reads=0,pending={},locked=false}
 local e=setmetatable({},{__index=_G});e._G=e
 local expected={};local function track(name,...)
  local want=expected[name]or{}
  check(select('#',...)==#want,name..' keeps original argument count')
  for i=1,#want do check(select(i,...)==want[i],name..' keeps original receiver/argument')end
  s.trace[#s.trace+1]=name
  if s.active then local seen=s.seen[name]or{};s.seen[name]=seen;seen[s.active]=true end
  if s.hook then s.hook(name)end
  if s.fail==name then error(s.errorToken,0)end
 end
 local function callback(name)return function(...)track(name,...);return false end end
 e.pcall=function(fn,...)
  local previous=s.active;s.active=fn
  local ok,a,b=pcall(fn,...);s.active=previous
  if not ok then s.errors[#s.errors+1]=a end
  return ok,a,b
 end
 e.InCombatLockdown=function()return s.locked end
 e.debugprofilestop=function()error('unrequested phase clock')end
 e.FluxUILayoutSqueeze={InvalidateEmulatedDependentCache=callback('invalidate'),
  GetEffectiveEmulatedDependentXFactorForUnitFrames=function()s.reads=s.reads+1;return s.factor end}
 e.FluxTrinketMenu={ApplyHorizontalSqueeze=callback('trinket')}
 local combat={Relayout=callback('combatGrid')};expected.combatGrid={combat}
 e.FluxCombatManager={Grid=combat,UpdateAnchor=callback('combatAnchor')};expected.combatAnchor={e.FluxCombatManager}
 e.FluxNonCombatGrid_ApplyScreenBottomAnchor=callback('ncScreen')
 local nc={Relayout=callback('ncGrid')};expected.ncGrid={nc};e.FluxNonCombatAPI={DefaultGrid=nc}
 e.FluxTrinketMenuManager={UpdateAnchor=callback('trinketAnchor')};expected.trinketAnchor={e.FluxTrinketMenuManager}
 local button={Relayout=callback('buttonGrid')};expected.buttonGrid={button};e.FluxButtonAPI={DefaultGrid=button}
 e.FluxSpellBookSlots_ApplyHorizontalSqueeze=callback('spellSlots')
 e.FluxFlyoutFrame={OnDependentsLayoutChanged=callback('flyout')}
 e.FluxChatFrame_ApplyPrimaryPosition=callback('chat');expected.chat={true}
 e.FluxMinimap={RefreshBlizzardBuffDebuffSqueeze=callback('minimap')};expected.minimap={e.FluxMinimap}
 e.FluxUnitFrames_ApplyPlayerStatusBarLayout=callback('player')
 e.FluxUnitFrames_RefreshAuraLayoutsAfterSqueeze=callback('aura')
 e.Flux={Bars={BadgeHost={RefreshLayout=callback('badge')},Pet={LayoutButtons=callback('pet')},
  Stance={RequestSizeOnly=callback('stance')}},Combat={Defer=function(key,fn)s.pending[key]=fn end},EBS={}}
 if modern then e.Flux.EBS.Flyout={OnDependentsLayoutChanged=callback('flyout')}end
 assert(loadenv(body,e))()
 s.env=e;s.run=e.FluxUILayoutSqueeze.NotifyLayoutDependents;s.track=track;s.expected=expected
 return s
end
local expected={'invalidate','trinket','combatGrid','ncScreen','ncGrid','combatAnchor','trinketAnchor',
 'buttonGrid','spellSlots','flyout','chat','badge','minimap','pet','stance','player','aura'}
local function sequence(t)return table.concat(t,',')end
for _,modern in ipairs{false,true}do
 local s=fixture(modern);local e=s.env;s.run()
 check(sequence(s.trace)==sequence(expected),'full initial notification keeps dependency order')
 check(e.FluxUILayoutSqueeze._lastPushedAuraX==1 and s.reads==2,'successful aura callback retains applied-factor publication even when returning false')
 for _=1,20 do s.trace={};s.run();check(sequence(s.trace)==table.concat(expected,',',1,#expected-1),'unchanged factors still notify every layout owner in order')end
 local identities=0
 for _,name in ipairs{'combatGrid','ncGrid','buttonGrid','minimap'}do
  local n=0;for _ in pairs(s.seen[name])do n=n+1 end;identities=identities+n
  if not measuring then check(n==1,'repeated notifications reuse protected '..name..' callback body')end
 end
 if not modern then local n=0;for _ in pairs(s.seen.flyout)do n=n+1 end;identities=identities+n
  if not measuring then check(n==1,'legacy flyout reuses its protected body')end
 end
 -- Reentrant notification does not duplicate or suppress the outer transaction.
 s.trace={};local reentries=0;s.hook=function(name)if name=='combatGrid'then reentries=reentries+1;s.run()end end
 s.run();check(reentries==1 and #s.trace==16 and e.FluxUILayoutSqueeze._notifyingDependents==nil,'reentrant current-owner notification preserves guard lifecycle')
 s.hook=nil
 for _,name in ipairs{'trinket','combatGrid','ncGrid','combatAnchor','trinketAnchor','buttonGrid','spellSlots','flyout','chat','badge','minimap','pet','stance','player'}do
  s.trace={};s.errors={};s.fail=name;s.errorToken={owner=name};s.run()
  check(sequence(s.trace)==table.concat(expected,',',1,16)and #s.errors==1 and s.errors[1]==s.errorToken,'owner failure retains exact protected error and later callbacks: '..name)
 end
 s.fail='aura';s.errorToken={};s.factor=.75;s.trace={};s.errors={};s.run()
 check(#s.errors==1 and s.errors[1]==s.errorToken and e.FluxUILayoutSqueeze._lastPushedAuraX==1,'failed aura refresh does not publish an applied factor')
 s.fail=nil;s.trace={};s.run();check(e.FluxUILayoutSqueeze._lastPushedAuraX==.75 and s.trace[#s.trace]=='aura','next notification retries failed aura layout')
 -- Native/mixin field access must remain inside the protected body too.
 for _,name in ipairs{'combatGrid','ncGrid','buttonGrid','minimap'}do
  local object,method
  if name=='combatGrid'then object=e.FluxCombatManager.Grid;method='Relayout'
  elseif name=='ncGrid'then object=e.FluxNonCombatAPI.DefaultGrid;method='Relayout'
  elseif name=='buttonGrid'then object=e.FluxButtonAPI.DefaultGrid;method='Relayout'
  else object=e.FluxMinimap;method='RefreshBlizzardBuffDebuffSqueeze'end
  local fn=object[method];local reads=0;local err={owner=name};object[method]=nil
  setmetatable(object,{__index=function(_,key)if key==method then reads=reads+1;if reads==2 then error(err,0)end;return fn end end})
  s.errors={};s.trace={};check(pcall(s.run),'second method access remains protected: '..name)
  check(#s.errors==1 and s.errors[1]==err and s.trace[#s.trace]=='player'and e.FluxUILayoutSqueeze._notifyingDependents==nil,'lookup failure preserves tail and exact error: '..name)
  setmetatable(object,nil);object[method]=fn
 end
 s.locked=true;s.trace={};for _=1,10 do s.run()end
 check(#s.trace==0 and s.pending['layout.squeeze.dependents']==s.run,'lockdown retains original named pending owner and skips all protected layout')
 s.locked=false;s.pending['layout.squeeze.dependents']();check(#s.trace==16,'queued notification still drains full current dependency pass')
 print('SQUEEZE_NOTIFICATION_WORK|'..(modern and'modern'or'legacy')..'|21passes|transientProtectedCallbackIdentities='..identities)
end
-- Source replacement during an earlier owner must be visible to later owners.
do
 local s=fixture(true);local e=s.env;local replacement={}
 replacement.Relayout=function(self)check(self==replacement,'new owner receiver retained');s.track('replacement')end
 s.hook=function(name)if name=='trinket'then e.FluxCombatManager.Grid=replacement end end
 s.run();check(s.trace[3]=='replacement','shared body resolves the current global owner after preceding callbacks')
end
print('Squeeze notification work: '..checks..' checks PASS; full current dependency order/arguments/recovery retained; no native timing claim')
