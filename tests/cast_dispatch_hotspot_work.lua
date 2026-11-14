-- Execute the real shared cast dispatcher with the established utility fixture.
-- Counters are desktop Lua work evidence, not native timing/taint certification.
local target=os.getenv('FLUX_CAST_DISPATCH_SOURCE')or'Core/ButtonFX/Cast.lua'
local baseline=false
for i=1,#arg do if arg[i]=='--source'then target=arg[i+1]elseif arg[i]=='--baseline'then baseline=true end end
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local text=read('tests/utility_modifier_vfx.lua')
text=text:sub(1,assert(text:find('    start("cast", 101);',1,true))-1)
text=text:gsub('local sourceRoot = arg%[1%]','local sourceRoot = nil',1)
local marker='for _, family in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do'
local a,b=assert(text:find(marker,1,true))
text=text:sub(1,a-1)..'local function fixture(family)'..text:sub(b+1)
text=text:gsub('local function loadFile%(path%)','local function loadFile(path)\n        if path=="Core/ButtonFX/Cast.lua" then return assert(load(read('..string.format('%q',target)..'), "@Core/ButtonFX/Cast.lua", "t", env))("_FluxUI", ns)end',1)
local fixture=assert(load(text..'\nreturn s,env,flux,w,other,pet,emit,start,mod\nend\nreturn fixture','@cast-dispatch-fixture','t',_G))()
local checks=0
local function check(ok,label)checks=checks+1;assert(ok,label)end
local code=read(target);local lines={};for line in(code..'\n'):gmatch('(.-)\n')do lines[#lines+1]=line end
local function make(family)
    local s,e,flux,w,other,pet,emit,start,mod=fixture(family)
    local metrics={routed=0,identities=0,nativeCasts=0,nativeChannels=0,paint=0};local seen={}
    local real=pcall
    e.pcall=function(fn,...)
        local info=debug.getinfo(fn,'S')
        if info and info.source=='@Core/ButtonFX/Cast.lua'then
            local line=lines[info.linedefined]or''
            if line:find('local ok, err = pcall(function()',1,true)or line:find('local function DispatchCastEvent',1,true)then
                metrics.routed=metrics.routed+1
                if not seen[fn]then seen[fn]=true;metrics.identities=metrics.identities+1 end
            end
        end
        return real(fn,...)
    end
    local cast,channel=e.UnitCastingInfo,e.UnitChannelInfo
    e.UnitCastingInfo=function(...)metrics.nativeCasts=metrics.nativeCasts+1;return cast(...)end
    e.UnitChannelInfo=function(...)metrics.nativeChannels=metrics.nativeChannels+1;return channel(...)end
    local ov=flux.ButtonFX.Overlay
    for _,name in ipairs{'PlayCast','PlayInterrupt','SyncBurst','ForceClear','ClearReticle','PlayReticle'}do
        local fn=ov[name];ov[name]=function(...)metrics.paint=metrics.paint+1;return fn(...)end
    end
    local function drain()local pending=s.timers;s.timers={};for _,fn in ipairs(pending)do fn()end end
    return s,e,flux,w,other,pet,emit,start,mod,metrics,drain
end
local function trace(family,label,s,w,pet)
    print('TRACE|'..family..'|'..label..'|'..tostring(w.mode)..'|'..tostring(w.actionButtonCastType)..'|'..tostring(pet.mode)..'|'..#s.timers..'|'..tostring(s.time))
end
for _,family in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
    local s,e,flux,w,other,pet,emit,start,mod,m,drain=make(family)
    for i=1,1000 do
        s.time=s.time+1;mod('');start('cast',101)
        check(w.mode=='cast'and w.actionButtonCastType==1,'normal cast still starts on the utility owner')
        if i%3==0 then
            s.kind=nil;emit('UNIT_SPELLCAST_INTERRUPTED',101)
            check(w.mode=='interrupt','interrupt retains its native visual owner')
        elseif i%3==1 then
            s.kind=nil;emit('UNIT_SPELLCAST_FAILED',101)
            check(w.mode==nil,'failed attempt clears active cast')
        else
            emit('UNIT_SPELLCAST_STOP',101);s.kind=nil;emit('UNIT_SPELLCAST_SUCCEEDED',101)
            check(w.mode=='finish','success after STOP retains completion burst')
        end
        drain()
        if i<5 or i>998 then trace(family,'cycle-'..i,s,w,pet)end
    end
    check(m.routed>2000,'fixture delivers every real dispatcher edge')
    if not baseline then check(m.identities==1,'shared protected router is reused across all cast edges')end
    for _,key in ipairs{'routed','identities','nativeCasts','nativeChannels','paint'}do print('METRIC|'..family..'_'..key..'|'..m[key])end
    start('channel',101);emit('UNIT_SPELLCAST_STOP',101);drain()
    check(w.mode=='cast'and w.actionButtonCastType==2,'ordinary STOP cannot cancel a live channel')
    s.time=s.time+8;s.kind=nil;emit('UNIT_SPELLCAST_CHANNEL_STOP',101);check(w.mode=='finish','real channel stop still completes')
    mod('CTRL');start('empower',102)
    check(w.mode=='cast'and w.actionButtonCastType==3,'empower routing retains its original kind')
    s.kind=nil;flux.ButtonFX.Cast._frame.scripts.OnEvent(flux.ButtonFX.Cast._frame,'UNIT_SPELLCAST_EMPOWER_STOP','player','Cast-guid',102,false)
    check(w.mode=='interrupt','failed empowerment still interrupts')
    mod('');s.targeting=true;emit('UNIT_SPELLCAST_RETICLE_TARGET',101)
    check(w.mode=='reticle','ground-target reticle remains owned by the matching spell')
    s.targeting=false;emit('UNIT_SPELLCAST_RETICLE_CLEAR',101);check(w.mode~='reticle','reticle clear still tears down targeting')
    s.kind='cast';s.sid=101;s.start=s.time
    local event=flux.ButtonFX.Cast._frame.scripts.OnEvent
    event(flux.ButtonFX.Cast._frame,'UNIT_SPELLCAST_START','pet','Pet-guid',101)
    check(pet.mode=='cast','pet unit remains separately routed')
    s.kind=nil;event(flux.ButtonFX.Cast._frame,'UNIT_SPELLCAST_INTERRUPTED','pet','Pet-guid',101)
    check(pet.mode=='interrupt','pet interruption retains its own owner')
    local mode=w.mode;event(flux.ButtonFX.Cast._frame,'UNIT_SPELLCAST_FAILED','target','bad',101)
    check(w.mode==mode,'unregistered unit cannot mutate player ownership')
    -- Delayed STOP from an old cast cannot kill the next cast.
    s.time=s.time+2;start('cast',101);emit('UNIT_SPELLCAST_STOP',101)
    s.time=s.time+.01;start('cast',101);drain();check(w.mode=='cast','stale STOP timer cannot cancel a replacement generation')
    emit('UNIT_SPELLCAST_STOP',101);s.time=s.time+.01;start('cast',101);s.kind=nil;drain()
    check(w.mode=='cast','stale STOP timer retains generation ownership through a transient native-data gap')
    local caught;local original=flux.ButtonFX.Overlay.PlayCast
    e.geterrorhandler=function()return function(err)caught=err end end
    flux.ButtonFX.Overlay.PlayCast=function()error('dispatch native paint failure',0)end
    start('cast',101)
    check(type(caught)=='string'and caught:find('dispatch native paint failure',1,true),'protected dispatcher retains original error-handler delivery')
    flux.ButtonFX.Overlay.PlayCast=original
    local nested=false
    flux.ButtonFX.Overlay.PlayCast=function(widget,kind)
        if widget==w and not nested then nested=true;event(flux.ButtonFX.Cast._frame,'UNIT_SPELLCAST_START','pet','Nested-pet',101)end
        return original(widget,kind)
    end
    start('cast',101)
    check(nested and w.mode=='cast'and pet.mode=='cast','same-stack player/pet dispatch retains private payloads')
end
print('Cast dispatch hotspot: '..checks..' checks PASS; five client models; native FPS/taint/pixels NOT RUN')
