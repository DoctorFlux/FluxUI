-- Actual loaded owners and event/paint/fade callbacks under desktop widgets.
-- These work counts do not establish native FPS, pixels, or protected permission.
local function read(p)local f=assert(io.open(p,"rb"),p);local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local function up(fn,wanted)for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end;if n==wanted then return v end end;error(wanted)end
local checks=0;local baseline=os.getenv("FLUX_PASS3_BASELINE")=="1";local metrics,traces={},{}
local function check(v,m)checks=checks+1;assert(v,m)end
local text=read("tests/mp5_mana_ticks.lua")
local prefix=text:sub(1,assert(text:find("for _,branch in ipairs",1,true))-1)
prefix=prefix:gsub("local function loadAddon%(path,env,ns%)",function(s)return s.."\n    if path=='UnitFrames/FluxMP5Overlay.lua' then path=os.getenv('FLUX_PASS3_MP5_SOURCE')or path end"end,1)
local makeMP5=assert(load(prefix.."\nreturn fixture","@mp5-style-fixture","t",_G))()
local function MP5Fixture(branch)
    local s,e,ns=makeMP5(branch or"forever",50);s.Initialize();s.Flush()
    local m={anchor=0,level=0,height=0,spark=0,value=0,power=0,maximum=0};local methods=getmetatable(e.UIParent).__index
    for name,key in pairs{SetPoint="anchor",SetFrameLevel="level",SetValue="value"}do local old=methods[name];methods[name]=function(self,...)if self==s.tick then m[key]=m[key]+1 end;return old(self,...)end end
    local oldHeight=methods.SetHeight;methods.SetHeight=function(self,...)if self==s.tick.spark then m.height=m.height+1 end;return oldHeight(self,...)end
    local oldPoint=methods.SetPoint;methods.SetPoint=function(self,...)
        if self==s.tick.spark then m.spark=m.spark+1 end
        oldPoint(self,...)
        if self==s.tick or self==s.fsr then self.points=self.points or{};self.points[#self.points+1]={...}end
    end
    local oldPower=ns.API.SafeUnitPower;ns.API.SafeUnitPower=function(...)m.power=m.power+1;return oldPower(...)end
    local oldMax=ns.API.SafeUnitPowerMax;ns.API.SafeUnitPowerMax=function(...)m.maximum=m.maximum+1;return oldMax(...)end
    local width,height=methods.GetWidth,methods.GetHeight
    methods.GetWidth=function(self)if self==s.tick or self==s.fsr then local bar=self.point and self.point[2];return (bar and bar.width or 200)+12 end;return width(self)end
    methods.GetHeight=function(self)if self==s.tick or self==s.fsr then local bar=self.point and self.point[2];local h=bar and bar.height or 16;return type(h)=="number"and h+12 or h end;return height(self)end
    return s,e,ns,m,methods
end
for _,fps in ipairs{60,144,240}do
    local s,e,ns,m=MP5Fixture();s.Advance(1/fps)
    for key in pairs(m)do m[key]=0 end
    for i=1,fps*60 do s.Advance(1/fps)end
    for key,value in pairs(m)do metrics["mp5_"..fps.."_"..key]=value end
    check(m.value==fps*60 and m.spark==fps*60 and m.power==fps*60 and m.maximum==fps*60,"MP5 values, moving sparks and power reads remain frame-synchronous")
    if not baseline then check(m.anchor==0 and m.level==0 and m.height==0,"MP5 settled owned style is not rewritten")end
end
for _,branch in ipairs{"era","anniversary","tbc","forever"}do
    local s,e,ns,m,methods=MP5Fixture(branch);local trace={}
    s.Advance(.25);trace[#trace+1]=string.format("%.2f",s.tick.value)
    s.player.Power.width,s.player.Power.height,s.player.Power.level=280,22,20;s.Advance(.01)
    check(s.tick.level==26 and s.tick.spark.height==34,"MP5 follows live source level/height on the next original frame")
    check(s.tick.spark.point[2]==s.tick,"moving spark remains attached to its current overlay")
    s.player.isAdditionalPowerShown=true;s.player.AdditionalPower.height=18;s.Advance(.01)
    check(s.tick.point[2]==s.player.AdditionalPower and s.tick.spark.height==30,"druid secondary mana rebinds immediately")
    s.player.isAdditionalPowerShown=false;s.Advance(.01);check(s.tick.point[2]==s.player.Power,"primary mana attachment returns immediately")
    s.mana=40;s.Event("UNIT_POWER_UPDATE","player","MANA");s.Event("UNIT_SPELLCAST_SUCCEEDED","player","cast")
    s.Advance(.5);check(s.fsr.shown and not s.tick.shown,"FSR keeps the same mana-spend/cast lifecycle")
    trace[#trace+1]=string.format("%.2f",s.fsr.value)
    s.Advance(5);check(s.tick.shown,"FSR completion restores mana tick at the original update")
    local opaque=setmetatable({secret=true},{__eq=function()error("opaque geometry comparison")end})
    s.player.Power.height=opaque;local before=m.height;s.Advance(.01);s.Advance(.01)
    check(rawequal(s.tick.spark.height,opaque)and m.height-before==2,"opaque spark heights forward every time without cache comparison")
    s.player.Power.height=24;s.Advance(.01);check(s.tick.spark.height==36,"public geometry resumes after opaque samples")
    local inaccessible={};local access=ns.API.CanAccessValue
    ns.API.CanAccessValue=function(v)return not rawequal(v,inaccessible)and access(v)end
    s.player.Power.height=inaccessible;before=m.height;s.Advance(.01);s.Advance(.01)
    check(rawequal(s.tick.spark.height,inaccessible)and m.height-before==2,"inaccessible public heights also retain native forwarding")
    ns.API.CanAccessValue=access;s.player.Power.height=24;s.Advance(.01)
    local setter=methods.SetHeight;local fail=true
    methods.SetHeight=function(self,v)if self==s.tick.spark and fail then fail=false;error("height sink failure")end;return setter(self,v)end
    s.player.Power.height=25;check(not pcall(s.Advance,.01),"native height failure remains observable")
    s.Advance(.01);check(s.tick.spark.height==37,"failed height write retries at the next original update");methods.SetHeight=setter
    local level=methods.SetFrameLevel;fail=true
    methods.SetFrameLevel=function(self,v)if self==s.tick and fail then fail=false;error("level sink failure")end;return level(self,v)end
    s.player.Power.level=24;check(not pcall(s.Advance,.01),"native level failure remains observable")
    s.Advance(.01);check(s.tick.level==30,"failed level write retries without losing attachment");methods.SetFrameLevel=level
    local point=methods.SetPoint;fail=true
    methods.SetPoint=function(self,...)if self==s.tick and fail then fail=false;error("anchor sink failure")end;return point(self,...)end
    s.player.isAdditionalPowerShown=true;check(not pcall(s.Advance,.01),"native attachment failure remains observable")
    s.Advance(.01);check(s.tick.point[2]==s.player.AdditionalPower,"partially failed attachment is retried");methods.SetPoint=point
    s.player.isAdditionalPowerShown=false;s.Advance(.01)
    s.mana=100;s.Event("UNIT_POWER_UPDATE","player","MANA");check(not s.driver.scripts.OnUpdate,"full mana parks its driver")
    s.mana=50;s.Event("UNIT_POWER_UPDATE","player","MANA");check(s.driver.scripts.OnUpdate and s.tick.shown,"new power traffic wakes before first visible paint")
    ns.MP5Overlay.Shutdown();check(not s.driver.scripts.OnUpdate and not s.tick.shown,"shutdown keeps the original dormant state")
    traces["mp5_"..branch]=table.concat(trace,",")
end

text=read("tests/castbar_school_themes.lua");prefix=text:sub(1,assert(text:find("local function checkParticleGeometry",1,true))-1)
local makeCast=assert(load(prefix.."\nreturn fixture","@swing-style-fixture","t",_G))()
local function SwingFixture()
    local s,e,ns=makeCast("forever");ns.Flux.Cap.hasNativePlayerSwing=true
    e.Enum.PlayerSwingType={MainHand=0,OffHand=1,Ranged=2};e.UnitAttackSpeed=function()return 2,nil,0 end
    ns.API.GetSpellInfo=function()return nil,nil,132208 end;ns.Border.SetClassColor=function()end
    e.tinsert=table.insert;e.securecallfunction=function(fn,...)return fn(...)end
    e.tDeleteItem=function(t,v)for i=#t,1,-1 do if t[i]==v then table.remove(t,i)end end end
    assert(loadfile(os.getenv("FLUX_PASS3_FRAMEUTIL_SOURCE")or"../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua","t",e))()
    local bar=s.NewBar("player")
    assert(loadfile(os.getenv("FLUX_PASS3_SWING_SOURCE")or"UnitFrames/FluxSwingTimer.lua","t",e))("_FluxUI",ns)
    ns.SwingTimer.AttachToCastBar(bar,"player")
    local event,swing
    for _,f in ipairs(s.frames)do
        if f.events.PLAYER_SWING then event=f end
        if f.scripts.OnUpdate and debug.getinfo(f.scripts.OnUpdate,"S").source:find("FluxSwingTimer",1,true)then swing=f end
    end
    -- Mutant/source paths need not have the original filename.
    if not swing then for _,f in ipairs(s.frames)do if f.scripts.OnUpdate then local ok=pcall(up,f.scripts.OnUpdate,"mainTimer");if ok then swing=f;break end end end end
    assert(event and swing)
    local ok,label=pcall(up,swing.scripts.OnUpdate,"swingText");if not ok then label=up(up(swing.scripts.OnUpdate,"SetSwingLabel"),"swingText")end
    local time=up(swing.scripts.OnUpdate,"swingTime")
    local m={level=0,label=0,alpha=0,color=0,speeds=0};local methods=getmetatable(e.UIParent).__index
    for name,key in pairs{SetFrameLevel="level",SetAlpha="alpha"}do local old=methods[name];methods[name]=function(self,...)if self==swing then m[key]=m[key]+1 end;return old(self,...)end end
    local setText=methods.SetText;methods.SetText=function(self,...)if self==label then m.label=m.label+1 end;return setText(self,...)end
    local setColor=methods.SetTextColor;methods.SetTextColor=function(self,...)if self==label or self==time then m.color=m.color+1 end;setColor(self,...);self.textColor={...}end
    e.UnitAttackSpeed=function()m.speeds=m.speeds+1;return 2,nil,0 end
    function s.Swing(duration,kind)event.scripts.OnEvent(event,"PLAYER_SWING",duration,kind or e.Enum.PlayerSwingType.MainHand)end
    function s.Range(inside)event.scripts.OnEvent(event,"PLAYER_SWING_RANGE_UPDATE",e.Enum.PlayerSwingType.MainHand,inside,true)end
    function s.Event(name,...)event.scripts.OnEvent(event,name,...)end
    function s.Advance(dt)s.clock=s.clock+dt;s.Tick(dt)end
    return s,e,ns,bar,swing,label,time,m,methods
end
for _,fps in ipairs{60,144,240}do
    local s,e,ns,bar,swing,label,time,m=SwingFixture();s.Swing(100);s.Advance(1/fps)
    for key in pairs(m)do m[key]=0 end
    for i=1,fps*60 do s.Advance(1/fps)end
    for key,value in pairs(m)do metrics["swing_"..fps.."_"..key]=value end
    check(m.speeds==fps*120 and label.text=="Attack","swing speed reads and label output remain unchanged")
    if not baseline then check(m.level==0 and m.label==0 and m.alpha==0 and m.color==0,"stable swing presentation has no repeated owned style writes")end
end
do
    local s,e,ns,bar,swing,label,time=SwingFixture();local sample={}
    local main=up(up(swing.scripts.OnUpdate,"PaintMeleeActiveBars"),"mainBar")
    for i=1,480 do
        if(i-1)%120==0 then s.Swing(2)end
        s.Advance(1/60)
        if i%30==0 then sample[#sample+1]=string.format("%.4f",main.value)..":"..tostring(time.text)..":"..label.text end
    end
    traces.swing_two_second_cycles=table.concat(sample,",")
    check(label.text=="Attack"and #sample==16,"repeated real two-second swings keep all intermediate value/time/label samples")
end
do
    local s,e,ns,m,methods=MP5Fixture();local original=methods.SetHeight;local once=true
    methods.SetHeight=function(self,v)
        original(self,v)
        if self==s.tick.spark and once then
            once=false;s.player.Power.height=40;s.Advance(0);s.player.Power.height=30
        end
    end
    s.player.Power.height=30;s.Advance(.01);s.Advance(.01)
    check(s.tick.spark.height==42,"reentrant MP5 height cannot commit an obsolete outer cache value")
end
do
    local s,e,ns,m,methods=MP5Fixture();s.player.isAdditionalPowerShown=true;s.Advance(.01)
    local setter=methods.SetPoint;local once=true
    methods.SetPoint=function(self,point,anchor,...)
        setter(self,point,anchor,...)
        if self==s.tick and point=="TOPLEFT"and anchor==s.player.Power and once then
            once=false;s.player.isAdditionalPowerShown=true
            s.player.AdditionalPower.level,s.player.AdditionalPower.height=30,36;s.Advance(0)
        end
    end
    s.player.isAdditionalPowerShown=false;s.Advance(.01)
    local mixed=#s.tick.points
    s.Advance(.01)
    check(#s.tick.points==2 and s.tick.points[1][2]==s.player.AdditionalPower
        and s.tick.points[2][2]==s.player.AdditionalPower,"a reentrant first anchor cannot leave a valid cache over hybrid old/new anchors")
    check(s.tick.level==36 and s.tick.spark.height==48,"the next original frame repairs source level and height with the new attachment")
    traces.mp5_reentrant_attachment=mixed..",2,36,48"
end
do
    local s,e,ns,bar,swing,label,time,m,methods=SwingFixture();s.Swing(2);s.Advance(.01);s.Range(false)
    local setter=methods.SetAlpha;local once=true
    methods.SetAlpha=function(self,v)
        setter(self,v)
        if self==swing and v==1 and once then once=false;s.Range(false)end
    end
    s.Range(true);s.Range(true);check(swing.alpha==1,"reentrant range alpha cannot leave a stale owned endpoint cache")
    methods.SetAlpha=setter
    local color=methods.SetTextColor;once=true
    methods.SetTextColor=function(self,...)
        color(self,...)
        if self==label and once then once=false;s.Range(true)end
    end
    s.Range(false);s.Range(false);check(label.textColor[2]==.1,"reentrant color write cannot commit over a newer nested owner")
    methods.SetTextColor=color
end
do
    local s,e,ns,bar,swing,label,time,m,methods=SwingFixture();local setter=methods.SetText;local once=true
    methods.SetText=function(self,v)
        setter(self,v)
        if self==label and once then
            once=false;s.Event("START_AUTOREPEAT_SPELL");s.Swing(.1,e.Enum.PlayerSwingType.Ranged);s.Advance(0)
            s.Event("PLAYER_ENTERING_WORLD");s.Swing(2)
        end
    end
    s.Swing(2);s.Advance(.01);s.Advance(.01)
    check(label.text=="Attack","reentrant ranged/melee label changes cannot leave an obsolete outer cache")
end
do
    local s,e,ns,bar,swing,label,time,m,methods=SwingFixture();s.Swing(2);s.Advance(.01)
    local trace={label.text..":"..swing.alpha}
    swing.level=99;s.Advance(.01);check(swing.level==bar.level+1,"native frame-level reset is repaired on the same frame")
    bar.level=32;s.Advance(.01);check(swing.level==33,"borrowed cast-bar level changes are read every original update")
    local getter=methods.GetFrameLevel
    methods.GetFrameLevel=function(self)if self==swing then return s.secret end;return getter(self)end
    s.Advance(.01);check(swing.level==33,"opaque owned frame level uses the original setter fallback")
    methods.GetFrameLevel=function(self)if self==swing then error("level getter failure")end;return getter(self)end
    s.Advance(.01);check(swing.level==33,"failed owned level getter cannot suppress native recovery");methods.GetFrameLevel=getter
    s.Range(false);check(swing.alpha<1 and label.textColor[1]==1 and label.textColor[2]==.1,"out-of-range alpha and red text stay immediate")
    trace[#trace+1]=tostring(swing.alpha);s.Range(true);check(swing.alpha==1 and label.textColor[2]==1,"in-range colors return immediately")
    s.Swing(.01);s.Advance(.02);s.Advance(5.1)
    check(#e.FADEFRAMES==1,"real native fade begins after the unchanged ready linger")
    s.Advance(.25);check(swing.alpha>0 and swing.alpha<1,"real native FrameUtil paints the intermediate alpha")
    trace[#trace+1]=string.format("%.2f",swing.alpha)
    s.Swing(2);check(swing.alpha==1 and #e.FADEFRAMES==0,"new swing cancels native fade and repaints the cached public endpoint")
    trace[#trace+1]=tostring(swing.alpha)
    bar.casting=true;s.Advance(.01);check(not swing.shown and swing.alpha==0,"cast claim still hides the swing immediately")
    bar.casting=false;ns.SwingTimer.OnCastBarSlotReleased();check(swing.shown and swing.alpha==1,"cast release restores the active swing immediately")
    local setter=methods.SetTextColor;local fail=true
    methods.SetTextColor=function(self,...)if self==label and fail then fail=false;error("color sink failure")end;return setter(self,...)end
    check(not pcall(s.Range,false),"failed native color write remains observable")
    s.Advance(.01);check(label.textColor[2]==.1,"native color failure retries on the next original frame");methods.SetTextColor=setter
    e.RED_FONT_COLOR={GetRGB=function()return s.secret,.1,.1 end}
    local before=m.color;s.Range(false);s.Range(false);check(m.color-before==4 and rawequal(label.textColor[1],s.secret),"opaque text colors always forward to both native sinks")
    e.RED_FONT_COLOR=nil;s.Range(true)
    traces.swing=table.concat(trace,",")
end
do
    local s,e,ns,bar,swing,label,time,m,methods=SwingFixture();local setter=methods.SetText;local fail=true
    methods.SetText=function(self,...)if self==label and fail then fail=false;error("label sink failure")end;return setter(self,...)end
    s.Swing(2);check(not pcall(s.Advance,.01),"failed native label write remains observable")
    s.Advance(.01);check(label.text=="Attack","label cache commits only after a successful native sink")
end

local function RaidFixture()
    local frames={};local e=setmetatable({},{__index=_G});e._G=e
    e.FluxRaidCompat={IsSecret=function()return false end};e.FluxRaidState={frameArray={}};e.FluxRaidVisuals={}
    e.CreateFrame=function()local f={};function f:SetScript(k,v)self[k]=v end;frames[#frames+1]=f;return f end
    assert(loadfile(os.getenv("FLUX_PASS3_RAID_SOURCE")or"RaidFrame/FluxRaidUnit.lua","t",e))("_FluxUI",{})
    local event=up(e.FluxRaidUnit_OnLoad,"OnUnitEvent");local mark=up(event,"MarkPaint");local pending=up(mark,"pendingPaint")
    local s={e=e,frames=frames,event=event,pending=pending,trace={}}
    for _,part in ipairs{"Health","StatusText","HealPrediction","Power","Auras","DispelHighlight","AggroHighlight","Range","CenterStatus"}do
        e["FluxRaid_Update"..part]=function(f)s.trace[#s.trace+1]=part..":"..tostring(f.unit)end
    end
    e.FluxRaid_PaintUnit=function(f)s.trace[#s.trace+1]="Full:"..tostring(f.unit)end
    function s.Cell(unit)local f={unit=unit,visible=true};function f:IsVisible()return self.visible end;return f end
    function s.Event(f,part)event(f,"UNIT_"..part,f.unit)end
    function s.Flush()if frames[1]and frames[1].OnUpdate then frames[1].OnUpdate(frames[1])end end
    return s
end
do
    local s=RaidFixture();local cells={};for i=1,40 do cells[i]=s.Cell("raid"..i)end
    local rows,unique={},0
    for tick=1,1200 do
        for _,f in ipairs(cells)do s.Event(f,"HEALTH");local row=s.pending[f];if not rows[row]then rows[row]=true;unique=unique+1 end end
        s.Flush()
    end
    metrics.raid_dirty_arrays=unique;metrics.raid_value_paints=#s.trace
    check(#s.trace==144000,"raid retains every health/status/prediction paint at the original frame boundary")
    if not baseline then check(unique==40,"one settled dirty buffer is reused per cell")end
end
do
    local s=RaidFixture();local f=s.Cell("raid1")
    for i=1,100 do s.Event(f,"HEALTH")end;s.Event(f,"POWER_UPDATE");s.Event(f,"HEAL_PREDICTION");s.Flush()
    check(table.concat(s.trace,",")=="Health:raid1,StatusText:raid1,HealPrediction:raid1,Power:raid1","same-frame dirty parts retain original merge and painter order")
    s.trace={};s.Event(f,"POWER_UPDATE");s.Flush();check(table.concat(s.trace,",")=="Power:raid1","recycled buffers cannot retain stale health flags")
    s.trace={};local original=s.e.FluxRaid_UpdateHealth;local oldRow;local once=true
    s.e.FluxRaid_UpdateHealth=function(frame)
        original(frame)
        if once then once=false;s.Event(frame,"POWER_UPDATE");check(s.pending[frame]~=oldRow,"reentrant paint must own a distinct dirty buffer")end
    end
    s.Event(f,"HEALTH");oldRow=s.pending[f];s.Flush();s.Flush()
    check(table.concat(s.trace,",")=="Health:raid1,StatusText:raid1,HealPrediction:raid1,Power:raid1","reentrant flags keep the original next-frame paint")
    traces.raid_reentrant=table.concat(s.trace,",")
    s.e.FluxRaid_UpdateHealth=original;s.trace={};f.visible=false;s.Event(f,"HEALTH");s.Flush()
    f.visible=true;s.Event(f,"POWER_UPDATE");s.Flush();check(table.concat(s.trace,",")=="Power:raid1","hidden work is discarded without stale flags on reveal")
    s.trace={};s.e.FluxRaid_UpdateHealth=function()error("native paint failure")end
    s.Event(f,"HEALTH");oldRow=s.pending[f];check(not pcall(s.Flush),"paint failure remains observable")
    s.e.FluxRaid_UpdateHealth=original;s.Event(f,"POWER_UPDATE");check(s.pending[f]~=oldRow,"failed active buffer is not handed out as a spare")
    s.Flush();check(table.concat(s.trace,",")=="Power:raid1","new work rearms after a failed painter")
    s.trace={};s.Event(f,"HEALTH");s.e.FluxRaid_BindUnit(f,nil);s.Flush();check(#s.trace==0 and not s.pending[f],"unbind cancels queued work before recycling its flags")
    f.unit="raid2";s.Event(f,"POWER_UPDATE");s.Flush();check(table.concat(s.trace,",")=="Power:raid2","new unit identity cannot inherit discarded flags")
end
local keys={};for k in pairs(metrics)do keys[#keys+1]=k end;table.sort(keys);for _,k in ipairs(keys)do print("METRIC\t"..k.."\t"..metrics[k])end
keys={};for k in pairs(traces)do keys[#keys+1]=k end;table.sort(keys);for _,k in ipairs(keys)do print("TRACE\t"..k.."\t"..traces[k])end
print("Passive unit styles: "..checks.." checks PASS; native FPS/pixels/taint pending")
