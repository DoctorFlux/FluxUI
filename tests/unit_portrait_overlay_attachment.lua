-- Actual Border/Core, shared portrait constructor/partition and attachment
-- helpers. Engine primitives and the portrait-enabled predicate are modeled.
-- Mini anchors match the Pet/ToT/Party factories; their full initializers are
-- not loaded. No native pixels, taint or FPS acceptance is inferred.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return type(a)=="number"and type(b)=="number"and math.abs(a-b)<1e-7 end
local harness=read("tests/border_strip_envelope.lua")
local cut=assert(harness:find(" local init=read('Bars/Init.lua')",1,true))
local setup=harness:sub(1,cut-1)
setup=setup:gsub("local corePath=arg%[1%]or'Core/BorderJunctions.lua'",
    "local corePath="..string.format("%q",arg and arg[2]or"Core/BorderJunctions.lua"),1)
setup=setup..[[
 local function flush()local n=0;while #queue>0 do n=n+1;assert(n<30,'bounded queue');local q=queue;queue={};for _,fn in ipairs(q)do fn()end end end
 return {e=e,B=B,new=new,objects=objects,m=m,flush=flush,counts=counts}
end
return fixture
]]
local factory=assert(load(setup,"@actual-overlay-border-model","t",_G))()
local shared=read("UnitFrames/FluxUnitFrames_Shared.lua")
local ca=assert(shared:find("function UF.CreatePortrait(frame)",1,true))
local fa=assert(shared:find("function UF.FitPortraitBorderBounds(",1,true))
local miniColorStart=assert(shared:find("function UF.GetMiniUnitChromeColor(",1,true))
local miniColorEnd=assert(shared:find("function UF.ForeverNpcChrome(",miniColorStart,true))
local helpers=shared:sub(miniColorStart,miniColorEnd-1)..shared:sub(fa,ca-1)
local create=shared:sub(ca,assert(shared:find("-- Create the Model for 3D portrait",ca,true))-1).."return portraitFrame end\n"
local pa=assert(shared:find("-- Position portrait if it exists (full layout",1,true))
local position=shared:sub(pa,assert(shared:find("-- Apply Health - positioned within bar area",pa,true))-1)
local sa=assert(shared:find("function UF.UpdateFramePartitionSeparators(",1,true))
local sb=assert(shared:find("function UF.UpdateFramePartition(",sa,true))
local separator=shared:sub(sa,sb-1)
local samplerSource=harness:sub(assert(harness:find("local images={}",1,true)),
    assert(harness:find("local scenes,crest=0,0",1,true))-1)
local sample=assert(load("local check=...\n"..samplerSource.."\nreturn sample","@actual-art-overlay-sampler","t",_G))(check)
local function fields(f)
    local out={}
    for _,t in ipairs(f.objects)do
        if t:GetObjectType()=="Texture"and t:IsVisible()and t:GetEffectiveAlpha()>0
            and type(t.texture)=="string"and t.texture:find("Interface\\AddOns\\_FluxUI\\Texture\\",1,true)then
            local x,y,w,h=t:GetRect();local s=t:GetEffectiveScale();local uv=t.uv or{0,1,0,1}
            if #uv==4 then uv={uv[1],uv[3],uv[1],uv[4],uv[2],uv[3],uv[2],uv[4]}end
            local offsets={}
            for i=1,4 do local v=t.vertices and t.vertices[i]or{0,0};offsets[i]={v[1]*s,v[2]*s}end
            local px={x*s+offsets[1][1],x*s+offsets[2][1],(x+w)*s+offsets[3][1],(x+w)*s+offsets[4][1]}
            local py={(y+h)*s+offsets[1][2],y*s+offsets[2][2],(y+h)*s+offsets[3][2],y*s+offsets[4][2]}
            out[#out+1]={t.texture,{x*s,y*s,w*s,h*s},uv,offsets,t:GetEffectiveAlpha(),
                {math.min(table.unpack(px)),math.min(table.unpack(py)),math.max(table.unpack(px)),math.max(table.unpack(py))}}
        end
    end
    return out
end
local function coverage(fs,x,y)
    local n,a=0,0
    for _,field in ipairs(fs)do
        local b=field[6]
        if x>=b[1]-1e-8 and x<=b[3]+1e-8 and y>=b[2]-1e-8 and y<=b[4]+1e-8 then
            local v=sample(field,x,y);a=math.max(a,v);if v>1/255 then n=n+1 end
        end
    end
    return a,n
end
local function rect(o)return{o:GetRect()}end
local function sameRect(a,o,label)
    local b=rect(o);for i=1,4 do check(near(a[i],b[i]),label.." geometry component "..i)end
end
local function core(B,t,side)
    local x,y,w,h=t:GetRect();local s=t:GetEffectiveScale();local track=B:GetJoinTracks()[side]
    return(side=="Left"or side=="Right")and(x+w*track/16)*s or(y+h-h*track/(side=="Top"and 17 or 16))*s
end
local function make(style,globalScale,miniScale,unit,height,hp,ownPortrait)
    local f=factory(style,0,globalScale,false,"")
    local e,B,new,m=f.e,f.B,f.new,f.m
    function m:GetScale()return self.scale or 1 end
    local state={locked=false,geometry=0};f.state=state
    e.InCombatLockdown=function()return state.locked end
    local secret={};f.secret=secret
    e.IsSecretValue=function(v)return rawequal(v,secret)end;e.issecretvalue=e.IsSecretValue
    e.PublicGeometryNumber=function(v)return not e.IsSecretValue(v)and type(v)=="number"and v==v and math.abs(v)<math.huge and v or nil end
    for _,key in ipairs({"SetPoint","SetAllPoints","ClearAllPoints","SetWidth","SetHeight","SetSize","SetScale","SetParent","SetFrameLevel"})do
        local original=m[key]
        if original then m[key]=function(self,...)
            check(not state.locked,"attachment has no structural combat setters")
            state.geometry=state.geometry+1;return original(self,...)
        end end
    end
    local UF={};e.UF=UF;e.ns={UnitFrames=UF,Border=B};e.Border=B
    e.SecureUnitButton_OnLoad=function()end
    e.GetUnitClassColor=function()return e.RAID_CLASS_COLORS.MAGE end;e.ClassColorForUnit=e.GetUnitClassColor
    e.GetChromeSeparatorRGB=function()return B:GetAccentColor()end
    function UF.GetFramePublicDimensions(frame)return frame:GetWidth(),frame:GetHeight()end
    function UF.RecordFrameDimensions(frame,w,h)frame._fluxLayoutWidth,frame._fluxLayoutHeight=w,h end
    function UF.SetRelativeFramePublicLevel(frame,parent,offset)frame:SetFrameLevel(parent:GetFrameLevel()+offset)end
    function UF.FrameUsesPortraitLayout(frame)return frame.PortraitFrame and not frame._fluxPortraitDisabled end
    function UF.UsesHudUnitBars()return false end
    assert(load(helpers.."\n"..create.."\n"..separator,"@actual-overlay-shared-helpers","t",e))()
    local place=assert(load("return function(self,hasPortrait,portraitSize,portraitPosition)\n"..position.."end","@actual-portrait-partition","t",e))()
    local side=unit=="targettarget"and"Right"or"Left"
    local owner=new(e.UIParent);owner.rect={200,300,240,88};owner.unit=unit=="pet"and"player"or unit=="targettarget"and"target"or"party1"
    owner._FluxBorderStatic=true;owner._FluxBorderIndependent=unit=="partypet1"or nil;e["FluxUnitFrame_"..owner.unit]=owner
    owner.portraitPosition=side=="Left"and"LEFT"or"RIGHT"
    owner.PortraitFrame=UF.CreatePortrait(owner);place(owner,true,88,owner.portraitPosition)
    local mini=new(owner);mini:SetSize(90,height);mini:SetScale(miniScale);mini.unit=unit;mini._FluxBorderStatic=true
    mini:SetFrameLevel(owner:GetFrameLevel()+(unit=="partypet1"and 1 or 30))
    mini._FluxBorderIndependent=unit=="partypet1"or nil;e["FluxUnitFrame_"..unit]=mini
    if unit=="partypet1"then mini._fluxPartyPet=true;mini._fluxHealthBarOnly=true;mini._fluxHasMainPower=false end
    local function anchor()
        mini:ClearAllPoints()
        if side=="Left"then
            mini:SetPoint(unit=="partypet1"and"LEFT"or"TOPLEFT",owner,unit=="partypet1"and"LEFT"or"TOPLEFT",0,unit=="partypet1"and 0 or-20)
        else mini:SetPoint("TOPRIGHT",owner,"TOPRIGHT",0,-20)end
    end
    anchor()
    if ownPortrait then
        mini.portraitPosition="RIGHT"
        mini.PortraitFrame=UF.CreatePortrait(mini)
        place(mini,true,height,"RIGHT")
    end
    B:ApplyTo(mini,2,2,2,6)
    local atlas=new(e.UIParent);atlas:SetScale(mini:GetEffectiveScale()/e.UIParent:GetEffectiveScale())
    atlas:SetSize(90+(ownPortrait and height or 0),height);atlas:SetPoint("TOPLEFT",mini,"TOPLEFT",0,0);atlas._FluxBorderOwner=mini
    atlas:SetFrameLevel(mini:GetFrameLevel()+2)
    mini.atlasBorderFrame=atlas;B:ApplyTo(atlas,2,2,2,6)
    local outer=new(mini);outer:SetSize(90+(ownPortrait and height or 0),height)
    outer:SetPoint("TOPLEFT",mini,"TOPLEFT",(ownPortrait or unit=="targettarget")and 0 or-2,0)
    outer._FluxBorderOwner=mini;mini.outerBorderFrame=outer
    outer:SetFrameLevel(mini:GetFrameLevel()+5)
    B:ApplyTo(outer,2,2,2,6)
    for _,host in ipairs({mini,atlas,outer})do
        B:SetBorderColor(host,.8,.3,.1,1)
    end
    outer.FluxBorderFrame._FluxBorderRoundCorners=true
    local sepHost=new(e.UIParent);sepHost:SetScale(mini:GetEffectiveScale()/e.UIParent:GetEffectiveScale());sepHost._FluxBorderOwner=mini
    mini.SeparatorContainer=sepHost
    local sep=sepHost:CreateTexture();sep:SetHeight(17);sep:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga")
    sep:SetTexCoord(.004,.816,.004,.070);B:RegisterPiece(sep,"Top");mini.HealthPowerSeparator=sep
    if unit=="partypet1"then sep:Hide()
    else UF.UpdateFramePartitionSeparators(mini,(height-8)*hp,10,2,false,true)end
    f.UF,f.owner,f.mini,f.side,f.anchor=UF,owner,mini,side,anchor
    f.restorePortrait=function()place(owner,true,88,owner.portraitPosition)end
    f.portrait=owner.PortraitFrame;f.donor=f.portrait.FluxBorderFrame[side=="Left"and"Right"or"Left"]
    f.hosts={mini,atlas,outer};f.flush()
    return f
end
local function omitted(side,key)
    return side=="Left"and(key=="Left"or key=="TL"or key=="BL")
        or side=="Right"and(key=="Right"or key=="TR"or key=="BR")
end
local scenes=0
local guardsOnly=arg and arg[1]=="--guards-only"
local internalOnly=arg and arg[1]=="--internal-only"
if not guardsOnly and not internalOnly then
for _,style in ipairs({1,2})do for _,scale in ipairs({.75,1,1.25})do
    for _,miniScale in ipairs({.7,1,1.3})do for _,unit in ipairs({"pet","targettarget","partypet1"})do
        for _,height in ipairs({24,28,45})do for _,ownPortrait in ipairs(unit=="pet"and{false,true}or{false})do
            local f=make(style,scale,miniScale,unit,height,height<30 and .3 or .6,ownPortrait)
            local B,UF,mini,owner=f.B,f.UF,f.mini,f.owner;scenes=scenes+1
            local label="style="..style.." scale="..scale.." mini="..miniScale.." unit="..unit..
                " height="..height.." portrait="..tostring(ownPortrait)
            local body,parent,portrait,bg=rect(mini),rect(owner),rect(f.portrait),rect(mini.FluxBorderFrame.BackgroundFrame)
            local anchors=mini.points
            local baseline=fields(f)
            local outside=f.side=="Left"and"TR"or"TL"
            local cap=mini.outerBorderFrame.FluxBorderFrame[outside]
            local cx,cy,cw,ch=cap:GetRect();local cs=cap:GetEffectiveScale()
            local probes={}
            for ix=1,7 do for iy=1,7 do
                local x,y=(cx+cw*(ix-.17)/8)*cs,(cy+ch*(iy-.23)/8)*cs
                local a,n=coverage(baseline,x,y)
                if a>.5 then probes[#probes+1]={x,y,a,n}end
            end end
            UF.FitPortraitOverlay(mini,owner,f.side);f.flush()
            check(B.Junctions.stats.fallback==nil,"attachment compiles within current builder budgets")
            sameRect(body,mini,"mini body unchanged");sameRect(parent,owner,"parent body unchanged")
            sameRect(portrait,f.portrait,"portrait content box unchanged");sameRect(bg,mini.FluxBorderFrame.BackgroundFrame,"backdrop unchanged")
            check(mini.points==anchors,"mini input/root anchors unchanged")
            local x=core(B,f.donor,f.side=="Left"and"Right"or"Left")
            for _,host in ipairs(f.hosts)do
                local bf=host.FluxBorderFrame
                for _,key in ipairs({"TL","TR","BL","BR","Left","Right"})do
                    if omitted(f.side,key)then check(not bf[key]:IsShown()and bf[key]._fluxPortraitOmitted,"only attached side/caps omitted")end
                end
                for _,key in ipairs({"Top","Bottom"})do
                    local endX=(f.side=="Left"and bf[key]:GetLeft()or bf[key]:GetRight())*bf[key]:GetEffectiveScale()
                    check(near(endX,x),"straight edge meets actual parent portrait core: style="..style..
                        " scale="..scale.." mini="..miniScale.." unit="..unit.." edge="..key..
                        " host="..tostring(host==mini and"base"or host==mini.atlasBorderFrame and"atlas"or"outer")..
                        " got="..endX.." expected="..x.." offset="..tostring(mini._fluxPortraitOverlayOffset))
                end
            end
            if unit~="partypet1"then
                local sx=(f.side=="Left"and mini.HealthPowerSeparator:GetLeft()or mini.HealthPowerSeparator:GetRight())*mini.HealthPowerSeparator:GetEffectiveScale()
                check(near(sx,x),"HP/resource divider meets same portrait core")
            else check(not mini.HealthPowerSeparator:IsShown(),"party pet remains health-only")end
            local after=fields(f)
            check(#probes>0,"outside cap has meaningful opaque source probes")
            for _,probe in ipairs(probes)do
                local a,n=coverage(after,probe[1],probe[2])
                check(a+1/255>=probe[3],"outside rounded cap retains its source footprint")
                check(n<=probe[4],"attachment does not add layered fields at outside rounded cap: "..label..
                    " x="..probe[1].." y="..probe[2].." before="..probe[4].." after="..n..
                    " alphaBefore="..probe[3].." alphaAfter="..a)
            end
            local geometry,solves,reads,count=f.state.geometry,B.Junctions.stats.solves,B.Junctions.stats.geometryReads,#f.objects
            for _=1,5 do
                UF.FitPortraitOverlay(mini)
                B:SetBorderColor(mini,.1,.6,.8,1)
                mini:Hide();mini:Show();owner:Hide();owner:Show()
                f.flush()
            end
            check(f.state.geometry==geometry,"unchanged fit and visibility/color paint have no geometry writes")
            check(B.Junctions.stats.solves==solves and B.Junctions.stats.geometryReads==reads and #f.objects==count,
                "prepared attachment stays static through reveal/recolor")
            for _,host in ipairs(f.hosts)do for _,key in ipairs({"TL","TR","BL","BR","Left","Right"})do
                if omitted(f.side,key)then check(not host.FluxBorderFrame[key]:IsShown(),"color paint cannot revive omitted source")end
            end end
            f.state.locked=true;UF.FitPortraitOverlay(mini,owner,f.side=="Left"and"Right"or"Left");f.state.locked=false
            check(f.state.geometry==geometry,"combat relationship change waits without structural mutation")
            UF.FitPortraitOverlay(mini,owner,f.side)
            -- Move away, then restore stock anchor; outlines recover in place.
            mini:ClearAllPoints();mini:SetPoint("CENTER",owner,"CENTER",40,0)
            UF.FitPortraitOverlay(mini);f.flush()
            for _,host in ipairs(f.hosts)do
                check(not host.FluxBorderFrame._fluxAttachmentSide,"detached overlay restores complete border mode")
                for _,key in ipairs({"TL","TR","BL","BR","Left","Right"})do check(not host.FluxBorderFrame[key]._fluxPortraitOmitted,"detached source re-enrolled")end
            end
            f.anchor();UF.FitPortraitOverlay(mini);f.flush()
            check(mini.FluxBorderFrame._fluxAttachmentSide==f.side,"stock attachment returns after movement")
            owner._fluxPortraitDisabled=true;UF.FitPortraitOverlay(mini);f.flush()
            check(not mini.FluxBorderFrame._fluxAttachmentSide,"absent portrait restores complete outline")
            owner._fluxPortraitDisabled=nil;UF.FitPortraitOverlay(mini);f.flush()
            check(mini.FluxBorderFrame._fluxAttachmentSide==f.side,"portrait restore reconnects")
        end end
    end end
end end
end
-- A pet's optional own portrait sits at the OTHER end of its base rectangle.
-- Opening its left end must not resurrect the base TR curve as an internal cap.
for _,style in ipairs({1,2})do for _,height in ipairs({28,45})do
    local f=make(style,.75,.7,"pet",height,height<30 and .3 or .6,true)
    local cap=f.mini.FluxBorderFrame.TR
    local x,y,w,h=cap:GetRect();local s=cap:GetEffectiveScale()
    local before=fields(f);local probes={}
    for ix=1,9 do for iy=1,9 do
        local px,py=(x+w*(ix-.137)/10)*s,(y+h*(iy-.173)/10)*s
        local a,n=coverage(before,px,py)
        if a>.5 then probes[#probes+1]={px,py,a,n}end
    end end
    check(#probes>0,"internal body/portrait seam has meaningful source probes")
    f.UF.FitPortraitOverlay(f.mini,f.owner,f.side);f.flush()
    local after=fields(f)
    for _,p in ipairs(probes)do
        local a,n=coverage(after,p[1],p[2])
        check(a+1/255>=p[3],"opening parent-facing end does not erase pet's own portrait seam")
        check(n<=p[4],"opening parent-facing end adds no internal rounded-cap field: style="..style..
            " height="..height.." x="..p[1].." y="..p[2].." before="..p[4].." after="..n)
    end
end end
for _,style in ipairs({1,2})do for _,unit in ipairs({"pet","targettarget"})do
    local f=make(style,1,1,unit,45,.6,false)
    local UF,B,mini,owner=f.UF,f.B,f.mini,f.owner
    UF.FitPortraitOverlay(mini,owner,f.side);f.flush()
    local oldWidth=mini.GetWidth
    local sepBefore=rect(mini.HealthPowerSeparator);local geometry=f.state.geometry
    mini.GetWidth=function()return f.secret end
    UF.UpdateFramePartitionSeparators(mini,17,7,2,false,true)
    mini.GetWidth=oldWidth
    sameRect(sepBefore,mini.HealthPowerSeparator,"private width preserves prepared attached divider")
    check(f.state.geometry==geometry,"private attached separator width performs no native geometry writes")
    local function attached(label)
        check(mini.FluxBorderFrame._fluxAttachmentSide==f.side,label..": stock attachment remains")
    end
    local function detached(label)
        check(not mini.FluxBorderFrame._fluxAttachmentSide,label..": full outline restored")
    end
    for _,probe in ipairs({
        {object=mini,key="GetPoint",value=function()return "TOPLEFT",f.secret,"TOPLEFT",0,0 end},
        {object=mini,key="GetNumPoints",value=function()return f.secret end},
        {object=mini,key="GetEffectiveScale",value=function()return f.secret end},
        {object=f.portrait,key="GetPoint",value=function()return "TOPRIGHT",f.secret,"TOPLEFT",2,0 end},
        {object=f.portrait,key="GetNumPoints",value=function()return f.secret end},
    })do
        local previous=probe.object[probe.key];probe.object[probe.key]=probe.value
        local count=f.state.geometry;local objects=#f.objects
        UF.FitPortraitOverlay(mini)
        attached("unreadable "..probe.key)
        check(f.state.geometry==count and #f.objects==objects,"unreadable geometry performs no writes/allocation")
        probe.object[probe.key]=previous
    end
    mini:SetPoint("CENTER",owner,"CENTER",40,0);UF.FitPortraitOverlay(mini);f.flush()
    detached("multiple child anchors")
    f.anchor();UF.FitPortraitOverlay(mini);f.flush();attached("single child anchor restored")
    f.portrait:ClearAllPoints()
    f.portrait:SetPoint(owner.portraitPosition=="LEFT"and"TOPRIGHT"or"TOPLEFT",owner,
        owner.portraitPosition=="LEFT"and"TOPLEFT"or"TOPRIGHT",7,0)
    UF.FitPortraitOverlay(mini);f.flush();detached("custom portrait position")
    f.restorePortrait();UF.FitPortraitOverlay(mini);f.flush();attached("stock portrait restored")
    local old=owner.portraitPosition
    owner.portraitPosition=old=="LEFT"and"RIGHT"or"LEFT";f.restorePortrait()
    UF.FitPortraitOverlay(mini);f.flush();detached("portrait on other side")
    owner.portraitPosition=old;f.restorePortrait();UF.FitPortraitOverlay(mini);f.flush();attached("portrait mirror restored")
    f.e.FluxOptions.db.profile.appearance.borderType=3-style
    B:RefreshAllBorderTypes();UF.FitPortraitOverlay(mini);f.flush()
    attached("border type change")
    local contact=core(B,f.donor,f.side=="Left"and"Right"or"Left")
    for _,host in ipairs(f.hosts)do
        local edge=host.FluxBorderFrame.Top
        local x=(f.side=="Left"and edge:GetLeft()or edge:GetRight())*edge:GetEffectiveScale()
        check(near(x,contact),"type change refits actual source core")
        for _,key in ipairs({"TL","TR","BL","BR","Left","Right"})do
            if omitted(f.side,key)then check(not host.FluxBorderFrame[key]:IsShown(),"type refresh leaves attached sources omitted")end
        end
    end
end end
-- Detached atlas/separator hosts must follow a real parent whole-frame scale
-- change even when the child's own scale and attachment offset are unchanged.
for _,style in ipairs({1,2})do
    local f=make(style,.75,.7,"pet",45,.6,false)
    local UF,mini,owner=f.UF,f.mini,f.owner
    UF.FitPortraitOverlay(mini,owner,f.side);f.flush()
    owner:SetScale(1.4)
    UF.FitPortraitOverlay(mini);f.flush()
    check(near(mini.atlasBorderFrame:GetEffectiveScale(),mini:GetEffectiveScale()),"parent rescale updates detached pet atlas")
    check(near(mini.SeparatorContainer:GetEffectiveScale(),mini:GetEffectiveScale()),"parent rescale updates detached separator host")
    local contact=core(f.B,f.donor,"Right")
    for _,host in ipairs(f.hosts)do
        check(near(host.FluxBorderFrame.Top:GetLeft()*host.FluxBorderFrame.Top:GetEffectiveScale(),contact),
            "real parent rescale preserves exact portrait contact")
    end
    check(near(mini.HealthPowerSeparator:GetLeft()*mini.HealthPowerSeparator:GetEffectiveScale(),contact),
        "rescaled separator reaches actual portrait source")
    local writes=f.state.geometry
    for _=1,5 do UF.FitPortraitOverlay(mini)end
    check(f.state.geometry==writes,"settled rescale has no repeated geometry setters")

    local retry=make(style,.75,.7,"pet",45,.6,false)
    local child=retry.mini;local before=rect(child.HealthPowerSeparator)
    local width=child.GetWidth;child.GetWidth=function()return retry.secret end
    local geometry=retry.state.geometry
    retry.UF.FitPortraitOverlay(child,retry.owner,retry.side)
    child.GetWidth=width
    sameRect(before,child.HealthPowerSeparator,"first private width keeps original separator")
    check(retry.state.geometry==geometry,"first private width commits no partial attachment")
    retry.UF.FitPortraitOverlay(child);retry.flush()
    local endX=child.HealthPowerSeparator:GetLeft()*child.HealthPowerSeparator:GetEffectiveScale()
    check(near(endX,core(retry.B,retry.donor,"Right")),"public helper-only retry repairs separator after private width")
    geometry=retry.state.geometry;retry.UF.FitPortraitOverlay(child)
    check(retry.state.geometry==geometry,"successful private-width recovery becomes static")

    local fail=make(style,.75,.7,"pet",45,.6,false)
    local sep=fail.mini.HealthPowerSeparator;local setWidth=sep.SetWidth
    sep.SetWidth=function()error("modeled native separator write failure")end
    local ok=pcall(fail.UF.FitPortraitOverlay,fail.mini,fail.owner,fail.side)
    sep.SetWidth=setWidth
    check(not ok,"native separator errors remain observable")
    fail.UF.FitPortraitOverlay(fail.mini);fail.flush()
    check(near(sep:GetLeft()*sep:GetEffectiveScale(),core(fail.B,fail.donor,"Right")),
        "public helper-only retry repairs separator after native setter failure")
    geometry=fail.state.geometry;fail.UF.FitPortraitOverlay(fail.mini)
    check(fail.state.geometry==geometry,"successful native-failure recovery becomes static")
end
print("Portrait overlay attachment: "..checks.." checks; "..scenes.." actual Border/Core/Shared helper scenes;"..
    (guardsOnly and" GUARDS ONLY (full outside-cap matrix not run);"or internalOnly and" INTERNAL/GUARD ONLY;"or"")..
    " native pixels/taint/FPS pending")
