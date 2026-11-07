-- Execute commit-pinned restricted methods; inherited protection differs from
-- explicitly protected handles. Desktop contracts do not certify native taint.
local function read(path)
    local f=assert(io.open(path,"rb"),path);local s=f:read("*a"):gsub("\r\n","\n");f:close();return s
end
local function slice(s,a,b)
    local first=assert(s:find(a,1,true),a);local last=assert(s:find(b,first+#a,true),b)
    return s:sub(first,last-1)
end
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local cache=os.getenv("FLUX_RAID_UPSTREAM_CACHE")
local secure=read("RaidFrame/FluxRaidSecure.lua")
local snippet=assert(secure:match("local PARTY_TEXT = %[%=%[(.-)%]%=%]"))
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local path=(cache and cache.."/"..client.."/"or"../__AddonsForRef/wow-ui-source-"..client.."/")
        .."Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua"
    local source=read(path)
    local frames,handles={},{}
    local E=setmetatable({HANDLE={},_set_points={TOPLEFT=true,TOPRIGHT=true,BOTTOMRIGHT=true},
        scrub=function(v)return v end},{__index=_G})
    E.GetHandleFrame=function(h)return assert(frames[h])end
    E.GetFrameHandleFrame=function(h,_,explicit)
        local f=frames[h];if f and(not explicit or f.explicit)then return f end
    end
    E.IsFrameHandle=function(h)return frames[h]~=nil end
    E.LOCAL_CHECK_Frame={
        GetAttribute=function(f,k)return f.attrs[k]end,
        GetParent=function(f)return f.parent end,
        SetPoint=function(f,...)f.points[#f.points+1]={...}end,
    }
    assert(load(slice(source,"function HANDLE:GetAttribute(name)","function HANDLE:GetFrameRef"),"@native-attribute-"..client,"t",E))()
    assert(load(slice(source,"function HANDLE:SetPoint(point", "function HANDLE:SetAllPoints"),"@native-point-"..client,"t",E))()
    function E.HANDLE:ClearAllPoints()frames[self].points={}end
    function E.HANDLE:SetHeight(h)frames[self].height=h end
    function E.HANDLE:SetAttribute(k,v)frames[self].attrs[k]=v end
    local function handle(frame)
        local h=assert(io.tmpfile());local mt=debug.getmetatable(h)
        frames[h]=frame;handles[#handles+1]={h,mt};debug.setmetatable(h,{__index=E.HANDLE});return h
    end
    local parent={attrs={},explicit=false}
    local inherited=handle(parent)
    local raw={attrs={['pet-offset']=64,['text-band-height']=32},parent=parent,points={},explicit=true}
    local host=handle(raw)
    local ok,err=pcall(host.SetPoint,host,"TOPLEFT",inherited,"TOPLEFT",0,0)
    check(not ok and tostring(err):find("Invalid relative frame handle",1,true),"native rejects inherited-only relative handle")
    local run=assert(load("return function(self,newstate)\n"..snippet.."\nend","@party-text-"..client,"t",E))()
    raw.attrs['health-host']=true;run(host,"show")
    check(raw.points[1][2]==parent and raw.points[1][4]==64 and raw.height==32,"native $parent anchors pet-present top band")
    run(host,"hide")
    check(raw.points[1][4]==0 and raw.points[2][1]=="BOTTOMRIGHT","native pet disappearance restores full bar text host")
    raw.attrs['name-host']=true;raw.attrs['portrait-width']=85;run(host,"show")
    check(raw.points[1][4]==85,"name header reserves portrait once, independently of pet")
    raw.attrs['_private-ready']=true;raw.attrs['roster-layout-ready']=true
    check(host:GetAttribute('_private-ready')==nil and host:GetAttribute('roster-layout-ready')==true,"native blocks private attributes but permits public readiness")
    for _,entry in ipairs(handles)do debug.setmetatable(entry[1],entry[2]);entry[1]:close()end
end
local shared=read(os.getenv("FLUX_PARTY_SHARED_SOURCE")or"UnitFrames/FluxUnitFrames_Shared.lua")
local opaque=setmetatable({},{__le=function()error("secret alpha compared")end})
local E=setmetatable({UF={},IsSecretValue=function(v)return rawequal(v,opaque)end},{__index=_G})
local visible=slice(shared,"local function PortraitFrameIsVisuallyShown(self)","-- OOR")
local fn=assert(load(visible.."\nreturn PortraitFrameIsVisuallyShown","@portrait-alpha","t",E))()
check(fn({IsShown=function()return true end,GetAlpha=function()return opaque end}),"opaque alpha never enters numeric comparison")
check(not fn({GetAlpha=function()return 0 end}),"known zero alpha suppresses portrait work")
check(fn({GetAlpha=function()return .44 end}),"range-faded portrait remains drawable")
local fallback=slice(shared,"local function ShowBlizzardPortraitFallback", "local function PortraitUnitExists")
local paints=0
E.SetPortraitTexture=function(texture,unit)check(unit=="party1","engine fallback uses actual unit");paints=paints+1 end
local fill=assert(load(fallback.."\nreturn ShowBlizzardPortraitFallback","@portrait-fallback","t",E))()
local model={Hide=function(s)s.hidden=true end,ClearModel=function()error("fallback destroys pending model")end}
local texture={Show=function(s)s.shown=true end}
fill(model,{Portrait2D=texture},"party1")
check(model.hidden and texture.shown and paints==1,"unavailable model delegates to native portrait texture without clearing pending load")
check(shared:find("model:SetIgnoreParentAlpha(false)",1,true) and shared:find("portraitFrame:SetIgnoreParentAlpha(false)",1,true)
    and shared:find("tex2d:SetIgnoreParentAlpha(false)",1,true),"all portrait surfaces inherit unit opacity")
E.model={Hide=function(s)s.hidden=true end,SetUnit=function()error("model unavailable")end}
E.SetPortraitUnit=function()error("model unavailable")end
E.UnitRace=function()error("unavailable model must not fabricate a race model")end
assert(load(slice(shared,"    local success, assigned = pcall(SetPortraitUnit, model, unit)","    -- Store GUID"),"@portrait-create-fallback","t",E))()
check(E.model.hidden and E.model._fluxBlizzardFallback,"failed model creation selects engine fallback, never a generic human")
E.model.hidden=false;E.model._fluxBlizzardFallback=nil;E.SetPortraitUnit=function()return false end
assert(load(slice(shared,"    local success, assigned = pcall(SetPortraitUnit, model, unit)","    -- Store GUID"),"@portrait-create-failed-binding","t",E))()
check(E.model.hidden and E.model._fluxBlizzardFallback,"failed SetUnit compatibility attempts select the native fallback")
E.BindPortraitUnit=function()end;E.ApplyPortraitCamera=function()end
local assign=assert(load(slice(shared,"local function SetPortraitUnit(portrait, unit)","function UF.CreatePortrait" ).."\nreturn SetPortraitUnit","@portrait-bind-result","t",E))()
local attempts=0
local failed={SetUnit=function()attempts=attempts+1;error("no cached unit model")end}
check(assign(failed,"party1")==false and attempts==2,"both failed native setter signatures are reported to the fallback owner")
local compatible={SetUnit=function(_,_,blend)if blend~=nil then error("legacy signature")end end}
check(assign(compatible,"party1")==true,"legacy SetUnit signature succeeds without losing 3D")
-- Run the actual tint/connection painters, including restoration after status.
E.ValueIsSecret=E.IsSecretValue;E.TEXTURE_BAR="neutral"
E.ApplyHealthBarArt=function()end
E.UF.UnitIsAFKDisplay=function()return false end
E.UnitIsConnected=function()return true end;E.PlayerDeadOrGhost=function()return false end
E.DesaturateBarTexture=function(bar,value)bar.texture:SetDesaturated(value)end
local gray=slice(shared,"local function SetStatusBarFillGray", "function UF.UpdateResourceSpark")
E.SetStatusBarFillGray=assert(load(gray.."\nreturn SetStatusBarFillGray","@status-fill","t",E))()
assert(load(slice(shared,"function UF.UpdateHealthColor(self, unit)","-- ---------------------------------------------------------------------------\n-- Power Bar"),"@health-tint","t",E))()
assert(load(slice(shared,"function UF.RefreshResourceConnection", "function UF.ApplyStaggerBarStyle"),"@resource-connection","t",E))()
local function bar()
    local texture={SetDesaturated=function(s,v)s.desaturated=v end,SetAlpha=function()end}
    return {texture=texture,GetStatusBarTexture=function(s)return s.texture end,
        SetStatusBarColor=function(s,...)s.color={...}end,SetStatusBarTexture=function(s,v)s.art=v end}
end
local frame={unit="party1",Health=bar(),Power=bar()}
frame.Power._fluxPartyBar=true;frame.Power._fluxHudAtlas=true;frame.Power._fluxHudVertexWhite=true
for _,status in ipairs({"Dead","Ghost","AFK","Offline"})do
    frame._fluxPartyMuted=true;frame.Power._fluxPartyMuted=true
    E.UF.UpdateHealthColor(frame);E.UF.RefreshResourceConnection(frame.Power,"party1")
    check(frame.Health.color[1]==.5 and frame.Power.color[1]==.5,"HP and resource gray together for "..status)
    check(frame.Health.texture.desaturated and frame.Power.texture.desaturated,"precolored atlas desaturates for "..status)
    frame._fluxPartyMuted=false;frame.Power._fluxPartyMuted=false
    E.UF.UpdateHealthColor(frame);E.UF.RefreshResourceConnection(frame.Power,"party1")
    check(frame.Health.color[2]==1 and frame.Power.color[1]==1 and not frame.Health.texture.desaturated
        and not frame.Power.texture.desaturated,"normal colors recover after "..status)
end
E.FluxUnitFrames_GetTargetClassHealthColor=function()return .2,.5,1 end
E.UF.UpdateHealthColor(frame,"focustarget")
check(frame.Health.color[1]==.2 and frame.Health.art=="neutral","focus target class color uses neutral fill")
E.FluxUnitFrames_GetTargetClassHealthColor=function()end
E.UF.UpdateHealthColor(frame,"focustarget")
check(not frame.Health._fluxTargetClassTint and frame.Health.color[2]==1,"disabling target class color restores normal HP")
local party=read("UnitFrames/FluxUnitFrames_Party.lua")
local options={};local status=0;local dead=false;local warnings=true
E.DB=function()return options end;E.Secret=E.IsSecretValue;E.Flux={};E.Party={}
E.UnitIsDead=function()return dead end;E.UnitThreatSituation=function()return status end
E.IsThreatWarningEnabled=function()return warnings end
E.GetThreatStatusColor=function(s)return s/3,.25,.1 end
local tint
E.Party.SetThreatColor=function(_,...)tint={...}end
assert(load(slice(party,"function Party.UpdateThreat", "local function CreateThreat"),"@party-threat","t",E))()
local glow={Hide=function(s)s.shown=false end,Show=function(s)s.shown=true end}
frame._fluxPartyThreat=glow
for i=1,3 do status=i;E.Party.UpdateThreat(frame);check(glow.shown and tint[1]==i/3,"border follows native threat color for status "..i)end
for _,value in ipairs({0,opaque})do status=value;E.Party.UpdateThreat(frame);check(not glow.shown,"no overlay for zero/opaque threat")end
status=3;dead=true;E.Party.UpdateThreat(frame);check(not glow.shown,"dead frame has no threat overlay")
dead=false;warnings=false;E.Party.UpdateThreat(frame);check(not glow.shown,"native threat warning toggle is respected")
warnings=true;options.partyThreatHighlight=false;E.Party.UpdateThreat(frame);check(not glow.shown,"party threat toggle disables overlay")
check(frame.Health.color[2]==1,"threat overlay never recolors HP")
local preview=read("RaidFrame/FluxRaidPreview.lua")
local body=slice(preview,"function FluxRaidPreview.IsPartyShown", "function FluxRaidPreview.RefreshFromOptions")
local P={};local db={previewRosterSize=20}
local env=setmetatable({FluxRaidPreview=P,FluxOptions={GetRaidFrameDB=function()return db end}},{__index=_G})
P.Show=function()env.previewSessionVisible=true end;P.Hide=function()env.previewSessionVisible=false end
assert(load(body,"@preview-toggle","t",env))()
for i=1,10 do
    P.ToggleParty();check(P.IsPartyShown() and db.previewRosterSize==5,"party preview toggle shows correct family")
    P.ToggleParty();check(not P.IsPartyShown(),"party preview toggle hides current session")
end
print("Party native contracts: "..checks.." checks across five pinned restricted implementations; native rendering/taint pending")
