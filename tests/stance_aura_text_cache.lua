-- Real countdown helpers with owned/native display sinks replaced by counters.
-- No WoW secret VM, protected layout, rendering or native performance is modeled.
local function read(path)
    local file=assert(io.open(path,"rb")); local text=file:read("*a"); file:close()
    return text:gsub("\r\n","\n")
end
local source=read("Bars/Stance/Extras.lua")
local checks=0
local function check(value,message) assert(value,message); checks=checks+1 end
local function section(text,first,last)
    local a=assert(text:find(first,1,true)); local b=assert(text:find(last,a+#first,true))
    return text:sub(a,b-1)
end
local function fixture(body)
    local public=section(body,"local function PublicNumber(value)","local function PublicString(value)")
    local helpers=section(body,"local function ExtraAuraTimerOwned(btn)","local function FormArmorIsActive(btn)")
    local e=setmetatable({}, {__index=_G}); e._G=e
    local s={now=0,timeReads=0,frames={},ownedWrites=0,nativeHide=0,nativeFont=0,nativeRegions=0,nativeColor=0,nativeAlpha=0,holderShow=0,holderHide=0}
    local secret=setmetatable({}, {__tostring=function()error("secret formatting")end,__lt=function()error("secret comparison")end,__sub=function()error("secret arithmetic")end})
    e.Flux={Bars={Stance={}},Secrets={IsSecretValue=function(v)return rawequal(v,secret)end,CanAccessValue=function(v)return not rawequal(v,secret)end}}
    e.GetTime=function()s.timeReads=s.timeReads+1;return s.now end
    e.CreateFrame=function()
        local f={scripts={}}
        function f:Hide() self.shown=false end
        function f:Show() self.shown=true end
        function f:GetScript(name)return self.scripts[name]end
        function f:SetScript(name,fn)self.scripts[name]=fn end
        s.frames[#s.frames+1]=f;return f
    end
    local prelude="local Flux=Flux\nlocal Stance=Flux.Bars.Stance\n"
    s.set,s.format,s.tick,s.active,s.start=assert(load(prelude..public..helpers.."\nreturn AuraCountdownSetText,FormatAuraRemain,AuraCountdownTick,auraCountdownActive,EnsureAuraCountdownDriver","@production-stance-countdown","t",e))()
    function s:font(ready,options)
        options=options or {}; local fs={_fluxFontReady=ready,attempts=0,writes=0,fontAttempts=0}
        function fs:SetFont()
            self.fontAttempts=self.fontAttempts+1
            if options.fontFailures and self.fontAttempts<=options.fontFailures then error("controlled unavailable font")end
        end
        function fs:SetText(text)
            self.attempts=self.attempts+1
            if options.failValue==text and not self.failedValueOnce then self.failedValueOnce=true;error("controlled text failure")end
            if options.textFailures and self.attempts<=options.textFailures then error("controlled text failure")end
            self.displayed=text;self.writes=self.writes+1;s.ownedWrites=s.ownedWrites+1
        end
        fs.GetText=function()error("owned display text must not be read back")end
        return fs
    end
    function s:button(options)
        options=options or {};local fs=self:font(true)
        local digits={alpha=1,color=1}
        function digits:SetTextColor(_,_,_,alpha)s.nativeColor=s.nativeColor+1;self.color=alpha end
        function digits:SetAlpha(alpha)s.nativeAlpha=s.nativeAlpha+1;self.alpha=alpha end
        function digits:GetObjectType()return "FontString"end
        digits.GetText=function()error("native display text must not be read or cached")end
        local cd={}
        function cd:SetHideCountdownNumbers(value)check(value==true,"native digits still reconcile to hidden");s.nativeHide=s.nativeHide+1 end
        if not options.legacy then
            function cd:GetCountdownFontString()s.nativeFont=s.nativeFont+1;return digits end
        else
            function cd:GetRegions()s.nativeRegions=s.nativeRegions+1;return {GetObjectType=function()return "Texture"end},digits end
        end
        local holder={}
        function holder:Show()s.holderShow=s.holderShow+1;self.shown=true end
        function holder:Hide()s.holderHide=s.holderHide+1;self.shown=false end
        local widget={shown=true,IsShown=function(self)return self.shown end}
        local btn={FluxStanceManagedCooldown=true,Widget=widget,WCooldown=cd,StanceBuffExpirationTime=600,StanceBuffTimeMod=1,_fluxStanceAuraText=fs,_fluxStanceAuraHolder=holder}
        return btn,fs,holder,cd,digits
    end
    s.secret=secret
    return s
end

local function exercise(body)
    local s=fixture(body)
    s.set(nil,"ignored")
    check(s.ownedWrites==0 and #s.frames==0,"missing owned text has no work or resources")
    local fs=s:font(true)
    s.set(fs,nil);s.set(fs,"");s.set(fs,false)
    check(fs.writes==1 and fs.displayed=="","nil/false normalize to the same empty display")
    for _=1,1000 do s.set(fs,"10m")end
    check(fs.writes==2 and fs.displayed=="10m","unchanged public text writes once per actual transition")
    s.set(fs,"9m");s.set(fs,nil);s.set(fs,"")
    check(fs.writes==4 and fs.displayed=="","changed duration and clearing still write immediately")
    local other=s:font(true);s.set(other,"");s.set(other,"10m")
    check(other.writes==2 and other.displayed=="10m","a different FontString owns an independent successful-text cache")

    local retry=s:font(false,{fontFailures=2})
    for _=1,3 do s.set(retry,"10m")end
    check(retry.fontAttempts==3 and retry.writes==1 and retry.displayed=="10m","unavailable fonts retry before the first successful text write")
    retry._fluxFontReady=false;s.set(retry,"10m")
    check(retry.fontAttempts==4 and retry._fluxFontReady and retry.writes==1,"font readiness repairs are not skipped by identical text")
    local failed=s:font(true,{textFailures=1})
    s.set(failed,"10m");s.set(failed,"10m");s.set(failed,"10m")
    check(failed.attempts==2 and failed.writes==1,"failed writes do not poison the success cache and are retried")
    local changed=s:font(true,{failValue="9m"})
    s.set(changed,"10m");s.set(changed,"9m");s.set(changed,"10m");s.set(changed,"9m")
    check(changed.attempts==3 and changed.writes==2 and changed.displayed=="9m","a failed replacement preserves the last actually displayed string")
    local absent=s:font(true);local setter=absent.SetText;absent.SetText=nil
    s.set(absent,"10m");absent.SetText=setter;s.set(absent,"10m")
    check(absent.writes==1,"a temporarily absent setter is not marked successful")

    for _,case in ipairs({{-1,"0"},{.999,"0"},{1,"1"},{1.999,"1"},{89.99,"89"},{90,"2m"},{90.01,"2m"},{5399.99,"90m"},{5400,"2h"},{129599.99,"36h"},{129600,"2d"}}) do
        check(s.format(case[1])==case[2],"existing countdown format retained at "..case[1])
    end
    local stable=fixture(body);local btn,text,holder,cd,digits=stable:button()
    stable.active[btn]=true;stable.start()
    for i=1,1000 do
        stable.now=i/1000;digits.alpha,digits.color=1,1
        stable.tick()
        check(digits.alpha==0 and digits.color==0,"native digit changes continue to reconcile each frame")
    end
    check(text.writes==1 and text.displayed=="10m","actual stable countdown ticks suppress only duplicate owned text writes")
    check(stable.timeReads==1000 and stable.nativeHide==1000 and stable.nativeFont==1000 and stable.nativeColor==1000 and stable.nativeAlpha==1000 and stable.holderShow==1000,
        "clock, native digit reconciliation and holder visibility keep their per-frame cadence")
    check(#stable.frames==1 and type(stable.frames[1]:GetScript("OnUpdate"))=="function","existing driver resources and active lifetime remain unchanged")
    check(digits._fluxStanceAuraLastText==nil and cd._fluxStanceAuraLastText==nil,"no cache is added to native countdown objects")
    btn.StanceBuffExpirationTime=90;stable.now=0;stable.tick()
    check(text.displayed=="2m","the exact ninety-second boundary updates in the same tick")
    stable.now=.001;stable.tick()
    check(text.displayed=="89","the next frame retains the original below-ninety transition")
    btn.StanceBuffExpirationTime=1;stable.now=.948;stable.tick()
    check(stable.active[btn] and text.displayed=="0" and holder.shown,"the visible final-second display is retained above expiry cutoff")
    stable.now=.951;stable.tick()
    check(not stable.active[btn] and text.displayed=="" and not holder.shown and not stable.frames[1]:GetScript("OnUpdate"),"expiry clears immediately and disarms the existing driver")
    btn.StanceBuffExpirationTime=.05;stable.now=0;stable.active[btn]=true;stable.start();stable.tick()
    check(not stable.active[btn] and text.displayed=="" and not holder.shown,"the exact expiry cutoff remains inclusive")
    btn.StanceBuffExpirationTime=600;stable.now=0;stable.active[btn]=true;stable.start();stable.tick()
    check(text.displayed=="10m","reactivation on the same FontString displays fresh duration")
    btn.FluxStanceManagedCooldown=nil;stable.tick()
    check(not stable.active[btn] and text.displayed=="" and not holder.shown,"ownership loss clears text and holder immediately")
    btn.FluxConsumableAuraCooldown=true;stable.active[btn]=true;stable.start();stable.tick()
    btn.StanceBuffTimeMod=2;stable.tick()
    check(text.displayed=="5m","readable time modifiers still affect the display on the current tick")
    btn.Widget.shown=false;stable.tick()
    check(not stable.active[btn] and text.displayed=="" and not holder.shown,"hidden widgets leave no retained countdown")

    local legacy=fixture(body);local old,oldText=legacy:button({legacy=true});legacy.active[old]=true
    for i=1,20 do legacy.now=i/100;legacy.tick()end
    check(oldText.writes==1 and legacy.nativeRegions==20 and legacy.nativeHide==20,"legacy native region fallback remains reconciled every frame")
    old.StanceBuffExpirationTime=legacy.secret;legacy.tick()
    check(oldText.displayed=="" and not legacy.active[old],"unreadable expiry still clears without formatting or caching restricted values")
end

exercise(source)
local function replace(body,old,new)
    local a,b=assert(body:find(old,1,true));return body:sub(1,a-1)..new..body:sub(b+1)
end
local mutants={
    ["duplicate writes"]=replace(source," and fs._fluxStanceAuraLastText ~= text then"," then"),
    ["failed write cached"]=replace(source,"if ok then\n\t\t\tfs._fluxStanceAuraLastText = text","if true then\n\t\t\tfs._fluxStanceAuraLastText = text"),
    ["changed text lost"]=replace(source,"fs._fluxStanceAuraLastText ~= text","fs._fluxStanceAuraLastText == nil"),
}
for name,body in pairs(mutants)do check(not pcall(exercise,body),"fixture rejects "..name)end
print(string.format("Stance aura text cache: %d checks passed; three mutations rejected; 1000 stable ticks write owned text once; native rendering/performance unverified",checks))
