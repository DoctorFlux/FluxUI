-- Production cooldown owner and existing complete Cast/utility fixture.
-- Setter denial below is an explicit robustness model, not a native trace.
local root=arg[1]or".";if not root:match("[/\\]$")then root=root.."/"end
local selected=arg[2]
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function read(p)local f=assert(io.open(root..p,"rb"));local s=f:read("*a");f:close();return(s:gsub("\r\n","\n"))end
local function env()local e=setmetatable({},{__index=_G});e._G=e;return e end
local function cooldown()
    local cd={attempts=0,shows=0,clears=0,shown=false}
    function cd:SetCooldown(start,duration)
        self.attempts=self.attempts+1
        if self.failTimer then self.failTimer=false;error("injected timer setter denial")end
        self.start,self.duration=start,duration
    end
    function cd:Clear()self.clears=self.clears+1;if self.failClear then self.failClear=false;error("injected clear denial")end;self.duration=0 end
    function cd:GetEffectiveAlpha()return 1 end
    function cd:SetDrawBling(v)self.bling=v end
    function cd:SetDrawEdge(v)self.edge=v end
    function cd:SetDrawSwipe(v)self.swipe=v end
    function cd:SetSwipeColor(_,_,_,a)self.swipeAlpha=a end
    function cd:Show()self.shown=true;self.shows=self.shows+1 end
    function cd:Hide()self.shown=false end
    function cd:IsShown()return self.shown end
    return cd
end
if not selected or selected=="charges"then
    for _,classic in ipairs({false,true})do
        local e=env();local ns={Flux={Client={isAnyClassic=classic},Secrets={IsSecretValue=function()return false end,
            SafeGetNumber=function(v,d)return tonumber(v)or d end}}}
        assert(load(read("Core/ButtonFX/Charges.lua"),"@Charges.lua","t",e))("_FluxUI",ns)
        local fx=ns.Flux.ButtonFX.Charges;local cd=cooldown();local w={cooldown=cd};cd.failTimer=true
        local opts={start=100,duration=8,enable=1,chargeIsActive=false,skipDurationObject=true,hideWhenIdle=true}
        fx.Apply(w,opts)
        print(("METRIC setter classic=%s attempts=%d failedSignature=%s shows=%d"):format(tostring(classic),cd.attempts,tostring(cd._fxSigSet==true),cd.shows))
        check(cd.attempts==1 and not cd._fxSigSet and cd.shows==0,"failed native setter cannot commit timer signature or shown state")
        for i=1,1000 do fx.Apply(w,opts)end
        check(cd.attempts==2 and cd.duration==8 and cd._fxSigShown==true,"identical timer recovers once without explicit cache clear")
        check(cd.shows==1 and cd.swipe and not cd.edge and cd.bling,"success preserves swipe, edge, bling and unchanged-timer budget")
        check(cd.swipeAlpha==(classic and .8 or .64),"client native swipe alpha preserved")
        opts.duration=0;opts.start=0;cd.failClear=true;fx.Apply(w,opts)
        check(not cd._fxSigSet and cd.shown,"failed idle clear cannot cache idle or hide previous timer")
        fx.Apply(w,opts);check(cd._fxSigShown==false and not cd.shown and cd.duration==0 and not cd.bling,"same idle request retries clear then hides with bling off")
        local clearCount=cd.clears;fx.Apply(w,opts);check(cd.clears==clearCount,"accepted idle clear remains cached")
        opts.start=100;opts.duration=8;fx.ClearCache(w);fx.Apply(w,opts)
        check(cd.attempts==3 and cd.shown,"owner reuse cache clear restarts matching timer once")
        local d=cooldown();w.cooldown=d
        function d:SetCooldownFromDurationObject(obj)
            self.objectAttempts=(self.objectAttempts or 0)+1
            if self.objectAttempts==1 then error("injected duration denial")end
            self.object=obj
        end
        opts.skipDurationObject=false;opts.durationObject={};fx.Apply(w,opts)
        check(not d._fxSigSet and d.shows==0,"rejected duration object cannot fabricate shown state")
        fx.Apply(w,opts);check(d.object==opts.durationObject and d.shows==1,"duration object retries through existing paint")
        opts.durationObject=nil;opts.expirationTime=108
        function d:SetCooldownFromExpirationTime(exp,dur,rate)self.expiration=exp;self.duration=dur;self.rate=rate end
        fx.Apply(w,opts);check(d.expiration==108 and d.rate==1,"native expiration setter remains preferred")
        fx.Apply(w,opts);check(d.attempts==0,"accepted expiration paint stays cached without numeric fallback")
        local edge=cooldown();w.chargeCooldown=edge
        opts.chargeIsActive=true;opts.chargeStart=100;opts.chargeDuration=8;edge.failTimer=true
        fx.Apply(w,opts);check(not edge._fxSigSet and edge.shows==0,"charge edge failure cannot cache shown")
        fx.Apply(w,opts);check(edge.attempts==2 and edge.edge and not edge.swipe and edge.shown,"charge edge retries preserving edge-only presentation")
        opts.chargeIsActive=false;fx.Apply(w,opts);check(edge._fxHidden and not edge.shown and not edge.bling,"known-idle charge cleanup preserved")
    end
end
if not selected or selected=="legacy"then
    local e=env();local active="Blocked";e.FLUX_API={isLegacyClient=true}
    e.SecureCmdOptionParse=function()return active end
    e.GetInventoryItemID=function(_,slot)return 10000+slot end
    assert(load(read("ExtraButtonSystem/Engine/Usability.lua"),"@dormant-Usability.lua","t",e))()
    local u=e.FluxButtonUsability
    u.CheckSpellUsability=function(_,spell)return spell=="Blocked"and u.STATE_NOT_USABLE or u.STATE_USABLE,false end
    u.CheckItemUsability=function(_,id)return id==10013 and u.STATE_NOT_USABLE or u.STATE_USABLE,false end
    for i=1,1000 do
        active=i%2==0 and"Blocked"or"Ready"
        check(u:CheckMacroUsability("/cast [mod:shift] Blocked; Ready","spell",111)==(i%2==0 and u.STATE_NOT_USABLE or u.STATE_USABLE),"literal bracket selects actual public active clause")
    end
    active="13";check(u:CheckMacroUsability("/use [mod:shift] 13; 14")==u.STATE_NOT_USABLE,"conditional inventory-slot clause remains supported")
    active=nil;check(u:CheckMacroUsability("/cast [@mouseover,help] Missing")==u.STATE_USABLE,"no matching UF peek remains neutral")
end
if not selected or selected=="reticle"then
    local fixture=read("tests/utility_modifier_vfx.lua")
    local anchor="    manager.UpdateButton(b, map)";fixture=fixture:sub(1,assert(fixture:find(anchor,1,true))+#anchor-1)
    local addition=[=[
    if not flux.Client.isPostDF then
        local sidCalls,alphaCalls=0,0
        for i=1,60 do
            local kid={shown=true,IsShown=function()return true end}
            function kid:GetAlpha()alphaCalls=alphaCalls+1;return 1 end
            cast.Register(kid,function()sidCalls=sidCalls+1;return 101 end,cast.RANK_EBS)
        end
        s.targeting=true;cast.NoteTargeting(w)
        check(s.tickers["buttonfx.reticle"]~=nil,"targeting arms shared cancellation observer")
        env.FluxOptions={GetActionbarsDB=function()return{spellCastVFX=false}end};cast.RefreshFromOptions()
        local reads,alphas=sidCalls,alphaCalls
        for i=1,600 do s.tickers["buttonfx.reticle"](.05)end
        print(("METRIC reticle client=%s ticks=600 extraFaces=60 spellReads=%d alphaReads=%d"):format(family,sidCalls-reads,alphaCalls-alphas))
        check(sidCalls==reads and alphaCalls==alphas,"disabled reticle performs zero face/alpha resolution across 600 ticks")
        check(w.mode==nil,"disabled optional VFX stays cleared")
        env.FluxOptions.GetActionbarsDB=function()return{spellCastVFX=true}end
        s.tickers["buttonfx.reticle"](.05)
        check(sidCalls>reads,"re-enable while targeting refreshes current owners without new ticker")
        env.FluxOptions.GetActionbarsDB=function()return{spellCastVFX=false}end;cast.RefreshFromOptions()
        s.targeting=false;s.tickers["buttonfx.reticle"](.05)
        check(s.tickers["buttonfx.reticle"]==nil,"disabled targeting cancellation disarms demand and preserves cleanup")
    end
end
print("Reticle option budget: "..checks.." complete-fixture checks; Classic optional rendering, modern policy PASS")
]=]
    local e=setmetatable({arg={[1]=root}},{__index=_G});e._G=_G
    assert(load(fixture..addition,"@production-reticle-option-regression","t",e))()
end
print(("ButtonFX paint recovery / dormant macro: %d checks; no native taint/pixel/timing claim PASS"):format(checks))
