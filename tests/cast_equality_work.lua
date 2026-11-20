-- Execute the whole production Cast owner with the existing utility fixture.
-- Counts prove desktop work/behavior only; no timing or native FPS/taint claim.
local source = 'Core/ButtonFX/Cast.lua'
for i=1,#arg do if arg[i]=='--source' then source=assert(arg[i+1]) end end
local function read(path)local f=assert(io.open(path,'rb'));local t=f:read('*a'):gsub('\r\n','\n');f:close();return t end
local text=read('tests/utility_modifier_vfx.lua')
text=text:sub(1,assert(text:find('    start("cast", 101);',1,true))-1)
text=text:gsub('local sourceRoot = arg%[1%]','local sourceRoot = nil',1)
local marker='for _, family in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do'
local a,b=assert(text:find(marker,1,true))
text=text:sub(1,a-1)..'local function fixture(family)'..text:sub(b+1)
text=text:gsub('local function loadFile%(path%)','local function loadFile(path)\n        if path=="Core/ButtonFX/Cast.lua" then return assert(load(read('..string.format('%q',source)..'), "@Core/ButtonFX/Cast.lua", "t", env))("_FluxUI", ns)end',1)
local fixture=assert(load(text..'\nreturn s,env,flux,w,other,pet,emit,start,mod\nend\nreturn fixture','@cast-event-cost-fixture','t',_G))()
local checks=0
local function check(ok,label)checks=checks+1;assert(ok,label)end
local metrics,identities
local function count(k)if metrics then metrics[k]=(metrics[k]or 0)+1 end end
local sourceLines={};for line in(read(source)..'\n'):gmatch('(.-)\n')do sourceLines[#sourceLines+1]=line end
-- Classify pcall sites in the comparison block, including wrapper controls.
-- Callback identity, rather than a helper name, is the retained-work bound.
local comparisonStart,comparisonEnd
for n,line in ipairs(sourceLines)do
    if not comparisonStart and(line:find('local function EqualSpellValues',1,true)or line:find('function ButtonFX.SpellIdsMatch',1,true))then comparisonStart=n end
    if comparisonStart and line:find('local function NameMatchesFace',1,true)then comparisonEnd=n-1;break end
end
assert(comparisonStart and comparisonEnd,'comparison owner boundaries')
local function make(family)
    metrics=nil
    local s,e,f,w,other,pet,emit,start,mod=fixture(family)
    other.mode=nil;pet.mode=nil
    local cast,ov=f.ButtonFX.Cast,f.ButtonFX.Overlay
    local hosts,widgets,names={},{},{}
    for id=1,20000 do names[id]='Spell'..id end
    f.Spell.GetName=function(id)count('name');return names[id]end
    f.Spell.GetOverrideSpell=function(id)count('override');return id end
    f.Spell.GetSubtext=function(id)count('rank');return nil end
    f.Spell.GetBaseSpell=function(id)count('base');return id end
    f.Spell.FormatCastAttribute=function(id)count('format');return names[id]end
    for col=1,19 do
        local host={column=col};hosts[col]=host
        for i,key in ipairs{'main','sec','tert'}do
            local sid=1000+col*10+i
            if col==1 and i<=2 then sid=101 end
            local wi={id=sid,_fluxHost=host}
            function wi:GetAlpha()count('alpha');return 1 end
            function wi:IsShown()count('shown');return true end
            host[key]={widget=wi};widgets[#widgets+1]=wi
            cast.Register(wi,function(widget)count('getter');return widget.id end,i==1 and cast.RANK_MAIN or cast.RANK_MINI)
        end
    end
    f.Bars={NUM_COLUMNS=19,GetHost=function(col)count('host');return hosts[col]end}
    local originalMatch=f.ButtonFX.SpellIdsMatch
    f.ButtonFX.SpellIdsMatch=function(...)count('match');return originalMatch(...)end
    local call,channel=e.UnitCastingInfo,e.UnitChannelInfo
    e.UnitCastingInfo=function(...)count('nativeCast');return call(...)end
    e.UnitChannelInfo=function(...)count('nativeChannel');return channel(...)end
    local targeting=e.SpellIsTargeting
    e.SpellIsTargeting=function(...)count('targeting');return targeting(...)end
    for _,key in ipairs{'PlayCast','PlayInterrupt','ForceClear','ClearReticle','SyncCast','SyncBurst','StopCast'}do
        local old=ov[key]
        ov[key]=function(...)count('paint_'..key);return old(...)end
    end
    local pcallReal=pcall
    e.pcall=function(fn,...)
        if metrics then
            count('protected')
            if identities then
                local caller=debug.getinfo(2,'Sl')
                if caller and caller.source=='@Core/ButtonFX/Cast.lua'and caller.currentline>=comparisonStart and caller.currentline<=comparisonEnd then
                    count('equalityProtected');identities[fn]=true
                end
            end
        end
        return pcallReal(fn,...)
    end
    local function event(ev,unit,...)
        cast._frame.scripts.OnEvent(cast._frame,ev,unit,...)
    end
    local function drain()local p=s.timers;s.timers={};for _,fn in ipairs(p)do fn()end end
    return s,e,f,w,pet,emit,start,event,drain,widgets
end
local function dump(family,label,m)
    local keys={};for k in pairs(m)do keys[#keys+1]=k end;table.sort(keys)
    for _,k in ipairs(keys)do print('METRIC|'..family..'|'..label..'|'..k..'|'..m[k])end
end
local function reset()metrics={};identities={}end
local expectedWork = {['target-start']={['equalityIdentities']=0},['current-no-target']={['equalityIdentities']=0,['protected']=2,['targeting']=1},['start']={['alpha']=60,['base']=116,['equalityIdentities']=1,['equalityProtected']=180,['format']=57,['getter']=62,['host']=1,['match']=64,['name']=172,['nativeCast']=2,['nativeChannel']=1,['override']=117,['paint_ClearReticle']=1,['paint_ForceClear']=1,['paint_PlayCast']=2,['protected']=774,['rank']=56,['shown']=60,['targeting']=1},['stop-active']={['equalityIdentities']=0,['protected']=1},['interrupted-1']={['alpha']=171,['base']=334,['equalityIdentities']=1,['equalityProtected']=509,['getter']=172,['host']=19,['match']=175,['name']=334,['nativeCast']=2,['nativeChannel']=2,['override']=338,['paint_ClearReticle']=59,['paint_PlayInterrupt']=2,['protected']=1706,['shown']=171,['targeting']=1},['interrupted-2']={['alpha']=171,['base']=334,['equalityIdentities']=1,['equalityProtected']=509,['getter']=172,['host']=19,['match']=175,['name']=334,['nativeCast']=2,['nativeChannel']=2,['override']=338,['paint_ClearReticle']=59,['paint_PlayInterrupt']=2,['protected']=1706,['shown']=171,['targeting']=1},['interrupted-3']={['alpha']=171,['base']=334,['equalityIdentities']=1,['equalityProtected']=509,['getter']=172,['host']=19,['match']=175,['name']=334,['nativeCast']=2,['nativeChannel']=2,['override']=338,['paint_ClearReticle']=59,['paint_PlayInterrupt']=2,['protected']=1706,['shown']=171,['targeting']=1},['current-target-empty']={['equalityIdentities']=0,['nativeCast']=1,['nativeChannel']=2,['protected']=5,['targeting']=1},['current-target-owned']={['equalityIdentities']=0,['nativeCast']=1,['nativeChannel']=2,['paint_ClearReticle']=2,['protected']=5,['targeting']=1},['reticle-clear']={['equalityIdentities']=0,['nativeChannel']=1,['override']=1,['paint_ClearReticle']=59,['protected']=4,['targeting']=2},['unit-pet']={['equalityIdentities']=0,['paint_ForceClear']=1}}
local function finish(family,label)
    local n=0;for _ in pairs(identities)do n=n+1 end;metrics.equalityIdentities=n
    local expected=assert(expectedWork[label],label)
    -- Preserve protection count, then bound allocations. The old source and
    -- anonymous wrapper control keep protection but violate callback reuse.
    check((metrics.equalityProtected or 0)==(expected.equalityProtected or 0),label..': unchanged protected equality invocation count')
    check(metrics.equalityIdentities==expected.equalityIdentities,label..': protected equality callback identity bound')
    for key,value in pairs(expected)do
        if key~='equalityIdentities'then check((metrics[key]or 0)==value,label..': unchanged '..key..' work')end
    end
    for key,value in pairs(metrics)do check(value==(expected[key]or 0),label..': unexpected '..key..' work')end
    dump(family,label,metrics);metrics=nil;identities=nil
end
do
  for _,family in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
    local s,e,f,w,pet,emit,start,event,drain,widgets=make(family)
    reset();event('UNIT_SPELLCAST_START','target','Cast-guid',101);check(next(metrics)==nil,'foreign unit filtered before work');finish(family,'target-start')
    reset();event('CURRENT_SPELL_CAST_CHANGED');check((metrics.getter or 0)==0 and(metrics.match or 0)==0,'non-targeting current-spell edge performs no owner scans');finish(family,'current-no-target')
    reset();start('cast',101);check(w.mode=='cast'and widgets[1].mode=='cast','real START retains EBS and exclusive strip owner');finish(family,'start')
    reset();emit('UNIT_SPELLCAST_STOP',101);check(#s.timers==1,'STOP retains existing delayed cancel');finish(family,'stop-active')
    s.kind=nil
    for n=1,3 do
      reset();emit('UNIT_SPELLCAST_INTERRUPTED',101);check(w.mode=='interrupt'and widgets[1].mode=='interrupt','interrupt visual survives each edge');finish(family,'interrupted-'..n)
    end
    metrics=nil;drain();check(w.mode=='interrupt','stale STOP preserves interrupt')
    s.time=s.time+2;s.targeting=true
    reset();event('CURRENT_SPELL_CAST_CHANGED');check(w.mode~='reticle','empty current-spell payload does not fabricate an owner');finish(family,'current-target-empty')
    f.ButtonFX.Cast.NoteTargeting(w)
    reset();event('CURRENT_SPELL_CAST_CHANGED');check(w.mode=='reticle','targeting current-spell edge retains established reticle');finish(family,'current-target-owned')
    s.targeting=false
    reset();emit('UNIT_SPELLCAST_RETICLE_CLEAR',101);check(w.mode~='reticle','reticle clear remains');finish(family,'reticle-clear')
    reset();event('UNIT_PET','player');finish(family,'unit-pet')
  end
end
do
  local s,e,f,w,pet,emit,start,event,drain,widgets=make('forever')
  local match=f.ButtonFX.SpellIdsMatch
  check(match(101,101),'equal numeric IDs');check(not match(101,102),'different IDs');check(match('101',101),'normalization matches numeric string')
  check(not match(nil,101)and not match(101,false),'nil/false rejected')
  f.Spell.GetOverrideSpell=function(id)return id==102 and 101 or id end
  check(match(101,102),'overrides match')
  f.Spell.GetOverrideSpell=function(id)return id==102 and "101" or id end
  check(match(101,102),'numeric string override still matches a numeric spell ID')
  f.Spell.GetSubtext=function(id)return id==102 and'Rank 2'or'Rank 1'end
  check(not match(101,102),'rank difference remains distinct')
  f.Spell.GetSubtext=function()return nil end;f.Spell.GetOverrideSpell=function(id)return id end
  f.Spell.GetBaseSpell=function(id)return id==102 and 101 or id end
  check(match(101,102),'base identity fallback')
  f.Spell.GetBaseSpell=function(id)return id==102 and "101" or id end
  check(match(101,102),'numeric string base still matches a numeric spell ID')
  f.Spell.GetBaseSpell=function(id)return id end;f.Spell.GetName=function()return'Shared spell'end
  check(match(101,102),'shared unranked name fallback')
  local metacalls=0;local token={};local eq=function(a,b)metacalls=metacalls+1;return a.id==b.id end
  local a=setmetatable({id=101},{__eq=eq});local b=setmetatable({id=101},{__eq=eq})
  check(match(a,b)and metacalls==1,'opaque equality remains protected')
  local broken=function()error(token,0)end;a=setmetatable({},{__eq=broken});b=setmetatable({},{__eq=broken})
  -- The initial equality error is caught, then existing normalization can fail.
  local ok,err=pcall(match,a,b);check(ok and err==true,'protected equality error still permits existing name fallback')
  f.Spell.GetOverrideSpell=function()error(token,0)end
  local ok,err=pcall(match,101,102);check(not ok and err==token,'unwrapped normalization error preserves exact object')
  local original=f.Spell.GetOverrideSpell;local nested=false
  f.Spell.GetOverrideSpell=function(id)if not nested then nested=true;check(match(7,7),'same-stack equality remains private')end;return id end
  check(not match(1,2)or f.Spell.GetName(1)==f.Spell.GetName(2),'public nested fallback completes');f.Spell.GetOverrideSpell=original
end
print('Cast equality work: '..checks..' checks PASS; five desktop models; native FPS/taint/pixels NOT RUN')
