-- External production-path work counter; does not change addon runtime files.
local target=os.getenv('FLUX_CAST_LAG_SOURCE')or'UnitFrames/FluxCastBar.lua'
local baseline=false
for i=1,#arg do if arg[i]=='--source'then target=arg[i+1]elseif arg[i]=='--baseline'then baseline=true end end
local checks=0
local function check(ok,label)checks=checks+1;assert(ok,label)end
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read('tests/castbar_school_themes.lua')
source=source:sub(1,assert(source:find('local function checkParticleGeometry',1,true))-1)
source=source:gsub('pet="PetFrame"','pet="PetFrame",party1="PartyFrame"')
local replaced
source,replaced=source:gsub('loadAddon%("UnitFrames/FluxCastBar.lua",%s*env,%s*ns%)',function()return 'loadAddon('..string.format('%q',target)..', env, ns)'end)
assert(replaced==1)
local fixture=assert(load(source..'\nreturn fixture','@cast-hotspot-fixture','t',_G))()
local function record(s,e,bar)
    local m={callbacks=0,distinct=0,info=0,width=0,wrap=0,lines=0,paints=0}
    local seen={};local real=pcall
    e.pcall=function(fn,...)
        local info=debug.getinfo(fn,'S')
        if info and info.source:find('FluxCastBar.lua',1,true)then
            m.callbacks=m.callbacks+1
            if not seen[fn]then seen[fn]=true;m.distinct=m.distinct+1 end
        end
        return real(fn,...)
    end
    local native=e.UnitCastingInfo
    e.UnitCastingInfo=function(...)m.info=m.info+1;return native(...)end
    for _,entry in ipairs{{'SetWidth','width'},{'SetWordWrap','wrap'},{'SetMaxLines','lines'}}do
        local fn=bar.Text[entry[1]]
        bar.Text[entry[1]]=function(self,...)m[entry[2]]=m[entry[2]]+1;return fn(self,...)end
    end
    local paint=bar.Time.SetFormattedText
    bar.Time.SetFormattedText=function(self,...)m.paints=m.paints+1;return paint(self,...)end
    return m
end
local function dump(label,m)
    for _,key in ipairs{'callbacks','distinct','info','width','wrap','lines','paints'}do
        print('METRIC|'..label..'_'..key..'|'..m[key])
    end
end
local function value(v)if v==nil then return'nil'end;return tostring(v)end
local function trace(label,bar)
    local fields={label,bar:IsShown(),bar.casting,bar.channeling,bar.holdTime,bar.fadeOut,bar.interrupted,
        bar.Text.text,bar.Time.text,bar.Text.width,bar.value,bar.maxValue,bar:GetValue(),bar:GetAlpha()}
    for i=1,14 do fields[i]=value(fields[i])end
    print('TRACE|'..table.concat(fields,'|'))
end
for _,client in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
    local s,e,ns=fixture(client)
    local db=s.GetDB();db.castBarThemes.enabled=false
    local bar=s.NewBar('player');s.casts.player={id=133,name='Fireball'}
    local m=record(s,e,bar)
    for i=1,1000 do
        s.Event(bar,'UNIT_SPELLCAST_START','player','cast-'..i,133)
        s.Tick(.05)
        local event=i%3==0 and'UNIT_SPELLCAST_INTERRUPTED'or i%3==1 and'UNIT_SPELLCAST_FAILED'or'UNIT_SPELLCAST_STOP'
        s.Event(bar,event,'player','cast-'..i,133)
        if i<=6 or i>998 then trace(client..'/cast/'..i,bar)end
        s.Tick(1.01)
    end
    check(m.info==1000,'cast lifecycle retains one native cast-info read per start')
    check(m.paints==3000 and m.width==3000 and m.wrap==3000 and m.lines==3000,'start and first-frame time/geometry cadence unchanged')
    if not baseline then check(m.distinct<=10,'cast start/terminal protected helpers reuse callbacks')end
    dump(client..'_1000casts',m)
end
for _,fps in ipairs{60,144,240}do
    local s,e,ns=fixture('forever');s.GetDB().castBarThemes.enabled=false
    local function fields(unit)return'Long spell','Long spell',133,0,120000,false,'long-cast',false,133 end
    e.UnitCastingInfo=fields
    local bar=s.NewBar('player');s.casts.player={id=133,name='Long spell'}
    bar:CastStart('player',false,'long-cast')
    local m=record(s,e,bar)
    for i=1,fps*60 do s.Tick(1/fps)end
    check(bar.casting and bar.Time.text~='','long active cast remains live')
    check(m.info==0,'client start/end timing does not requery native cast fields during progress')
    check(m.callbacks==m.paints and m.width==m.paints,'one protected native progress read per unchanged text paint')
    if not baseline then check(m.distinct==1,'active progress reuses the protected reader')end
    trace(fps..'fps/end',bar);dump('active_'..fps..'fps_60s',m)
end
-- Actual Retail event deferral ordering, including empty and terminal storms.
do
    local s,e,ns=fixture('live',{deferTimers=true})
    ns.API.majorVersion=12;e.WOW_PROJECT_ID=1;e.WOW_PROJECT_MAINLINE=1
    s.GetDB().castBarThemes.enabled=false
    local bar=s.NewBar('player');local m=record(s,e,bar)
    for i=1,1000 do
        s.Event(bar,'UNIT_SPELLCAST_FAILED','player','rejected-'..i,133)
    end
    assert(#s.timers==1000 and not bar:IsShown())
    s.FlushTimers();assert(not bar:IsShown());dump('retail_1000rejected',m)
end

-- Failure, reentry, native-query order, channel and opaque-value contracts.
for _,client in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
    local function boot()
        local s,e,ns=fixture(client);s.GetDB().castBarThemes.enabled=false
        return s,e,ns,s.NewBar('player')
    end
    do
        local s,e,ns,bar=boot();s.casts.player={id=133,name='Fireball'}
        s.Event(bar,'UNIT_SPELLCAST_START','player','current',133)
        local _,maximum=bar:GetMinMaxValues()
        check(maximum==5 and bar:GetValue()==1,'native millisecond timing still becomes the original five-second cast')
        s.Event(bar,'UNIT_SPELLCAST_INTERRUPTED','target','current',133)
        check(bar.casting and not bar.interrupted,'another unit cannot interrupt a routed cast')
        s.Event(bar,'UNIT_SPELLCAST_STOP','player','old',133)
        check(bar.casting and bar.castGUID=='current','old terminal identity cannot stop replacement')
        s.Event(bar,'UNIT_SPELLCAST_STOP','player','current',133)
        check(not bar.casting and bar.holdTime==.35,'real completion preserves finish hold')
    end
    do
        local s,e,ns,bar=boot();s.casts.player={id=5143,name='Channel',channel=true}
        s.Event(bar,'UNIT_SPELLCAST_CHANNEL_START','player','channel',5143)
        check(bar.channeling and bar.spellID==5143,'channel return fields retain native slot mapping')
        local before=bar:GetValue();s.Tick(.1)
        check(bar:GetValue()<before,'channel progress still decreases every original frame')
        s.Event(bar,'UNIT_SPELLCAST_CHANNEL_STOP','player','channel',5143)
        check(not bar.channeling and bar:GetValue()==0,'channel completion empties the bar')
    end
    do
        local s,e,ns,bar=boot();s.casts.player={id=133,name='Fireball'}
        s.Event(bar,'UNIT_SPELLCAST_START','player','current',133)
        local order={}
        bar.GetMinMaxValues=function(self)order[#order+1]='maximum';self.TimerBar.value=2;return 0,10 end
        bar.GetValue=function(self)order[#order+1]='value';return self.TimerBar.value end
        s.Tick(.05)
        check(table.concat(order,',')=='maximum,value','progress keeps original getter order in one protected operation')
        check(bar.Time.text=='8.0','remaining time uses same-call widget values')
        local reads=0
        bar.GetMinMaxValues=function()error('transient maximum failure')end
        bar.GetValue=function()reads=reads+1;return 2 end
        check(pcall(s.Tick,.05),'getter failure remains protected')
        check(reads==0 and bar.Time.text=='','failed first getter never queries a later getter or invents remaining time')
    end
    do
        local s,e,ns,bar=boot();local inner=s.NewBar('target');local entered=false
        e.UnitCastingInfo=function(unit)
            if unit=='player'and not entered then entered=true;inner:CastStart('target',false,'inner')end
            return'Spell '..unit,'Spell '..unit,12345,0,8000,false,unit=='player'and'outer'or'inner',false,unit=='player'and 133 or 116
        end
        bar:CastStart('player',false,'outer')
        check(entered and bar.castGUID=='outer'and inner.castGUID=='inner','reentrant cast probes keep private identity state')
        check(bar.spellID==133 and inner.spellID==116 and bar.Text.text=='Spell player'and inner.Text.text=='Spell target','reentrant probe/text callbacks never share mutable scratch fields')
    end
    do
        local s,e,ns,bar=boot();e.UnitCastingInfo=function()error('native cast query failure')end
        check(pcall(bar.CastStart,bar,'player',false,'bad'),'native cast probe failure remains contained')
        check(not bar:IsShown()and not bar.casting,'failed cast query cannot show fabricated progress')
    end
    do
        local s,e,ns,bar=boot();s.casts.player={id=133,name='Fireball'}
        local native=bar.Icon.SetTexture;local writes=0
        bar.Icon.SetTexture=function(self,texture)writes=writes+1;if writes==1 then error('transient native texture failure')end;return native(self,texture)end
        e.GetProfessions=function()return nil,nil,nil,nil,7 end
        e.GetProfessionInfo=function(index)assert(index==7);return'Fireball',789 end
        check(pcall(bar.CastStart,bar,'player',false,'icon-fallback'),'native icon failure stays inside its existing guard')
        check(writes==2 and bar.Icon.path==789 and bar.IconFrame:IsShown(),'profession icon fallback retains nil-hole traversal and subsequent native paint')
    end
    do
        local s,e,ns,bar=boot()
        e.UnitCastingInfo=function()return s.secret,s.secret,12345,s.secret,s.secret,false,'opaque',false,133 end
        check(pcall(bar.CastStart,bar,'player',false,'opaque'),'opaque cast fields remain within existing guards')
        check(bar.casting and rawequal(bar.Text.text,s.secret),'opaque spell text is forwarded to the native text sink')
        s.Event(bar,'UNIT_SPELLCAST_INTERRUPTED','player','opaque',133)
        check(bar.interrupted and bar.holdTime==1,'opaque timing still supports real interruption feedback')
    end
    do
        local s,e,ns,bar=boot();s.casts.player={id=133,name='Fireball'}
        bar.sentTarget='Target';e.UnitName=function()error('target-name lookup failure')end
        check(pcall(bar.CastStart,bar,'player',false,'label-error'),'target-name lookup failure stays inside original label guard')
        check(bar.casting and bar.Text.text=='Fireball','failed target decoration still paints the original spell label')
    end
    do
        local s,e,ns,bar=boot();s.casts.player={id=133,name='Fireball'}
        bar:CastStart('player',false,'interrupt-error')
        bar.Text.SetText=function()error('transient interrupt-label failure')end
        check(pcall(s.Event,bar,'UNIT_SPELLCAST_FAILED','player','interrupt-error',133),'interruption paint failure remains protected')
        check(bar.interrupted and bar.holdTime==1 and bar:GetAlpha()==1,'terminal feedback ownership/hold still completes after protected paint failure')
    end
end
print('Cast hotspot work: '..checks..' checks PASS; five client families; native FPS/pixels/taint NOT RUN')
