-- Actual Border/Core and Shared mini profile, portrait, separator, partition and
-- prediction-canvas writers. Engine widgets/secure state are modeled. Raw TGA
-- samples establish this fixture's source-art scope, not native pixel/FPS/taint
-- acceptance. Optional arguments: Shared.lua, FluxBorder.lua, BorderJunctions.lua.
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local function replace(s,a,b)local x,y=s:find(a,1,true);assert(x,a);return s:sub(1,x-1)..b..s:sub(y+1)end
local sharedPath=arg[1]or"UnitFrames/FluxUnitFrames_Shared.lua"
local borderPath=arg[2]or"FluxBorder.lua"
local corePath=arg[3]or"Core/BorderJunctions.lua"
local shared=read(sharedPath)
local function between(a,b)local x=assert(shared:find(a,1,true),a);return shared:sub(x,assert(shared:find(b,x+1,true),b)-1)end
local profile=between("    frame.unit = unit","    frame._FluxBorderStatic = true")
local baseCall=assert(shared:match("    (Border:ApplyTo%(frame,[^\n]+)"))
local atlasCall=assert(shared:match("        (ns.Border:ApplyTo%(atlasBorderFrame,[^\n]+)"))
local outerCall=assert(shared:match("        (ns.Border:ApplyTo%(outerBorderFrame,[^\n]+)"))
local separator=between("local function CreateSeparator(parent)","-- Animated Health Loss Mixin")
local partition=between("function UF.UpdateFramePartition(self)","-- Event Handling")
local prediction=between("local RefreshPublicPredictionCanvases","local function PlayerDeadOrGhost")..
    between("local function AnchorOverlayToStatusBarFill(","local function RefreshAbsorbShieldOverlay(")
local colorStart=shared:find("function UF.GetMiniUnitChromeColor(",1,true)
local colors=colorStart and between("function UF.GetMiniUnitChromeColor(","function UF.ForeverNpcChrome(")or""
-- Reuse the existing actual factory model, before its scenario loop. The
-- replacements select production constructor expressions, never simulate q or
-- the new mini insets. The portrait constructor is already extracted verbatim.
local original=read("tests/unit_portrait_overlay_attachment.lua")
local prefix=original:sub(1,assert(original:find("local function omitted(",1,true))-1)
prefix=replace(prefix,'local harness=read("tests/border_strip_envelope.lua")',
    'local harness=read("tests/border_strip_envelope.lua")\nharness=harness:gsub("local model=",function()return '..
    string.format("%q",'prefix=prefix:gsub(\'source%("FluxBorder.lua"%)\',function()return '..string.format("%q",'source('..string.format("%q",borderPath)..')')..' end,1)\nlocal model=')..' end,1)')
prefix=replace(prefix,'arg and arg[2]or"Core/BorderJunctions.lua"',string.format("%q",corePath))
prefix=replace(prefix,'local shared=read("UnitFrames/FluxUnitFrames_Shared.lua")','local shared=read('..string.format("%q",sharedPath)..')')
prefix=replace(prefix,'function UF.UsesHudUnitBars()return false end',[[
    function UF.UsesHudUnitBars()return true end
    function UF.UpdateAtlasBorder()end
    function UF.UpdateOuterBorder()end
    function UF.SyncPortraitModelGeometry()end
    function UF.LayoutThreatBar()end
    function UF.GetFramePublicLevel(frame)return frame and frame:GetFrameLevel()end
    function m:SetClipsChildren(v)self.clipsChildren=v end
    e.IsFluxUnitFrame=function()return true end
    e.FluxBorder=B
    e.FluxUnitFrames_GetHealthPartitionPct=function()return .6 end
]])
prefix=replace(prefix,'local side=unit=="targettarget"and"Right"or"Left"',
    'assert(load(MINI_CODE,"@actual-mini-profile-partition","t",e))()\n    local side=unit=="targettarget"and"Right"or"Left"')
prefix=replace(prefix,'mini:SetFrameLevel(owner:GetFrameLevel()+',
    'UF.TestMiniProfile(mini,unit)\n    mini:SetFrameLevel(owner:GetFrameLevel()+')
prefix=replace(prefix,'B:ApplyTo(mini,2,2,2,6)','UF.TestBaseBorder(mini)')
prefix=replace(prefix,'mini.atlasBorderFrame=atlas;B:ApplyTo(atlas,2,2,2,6)',
    'mini.atlasBorderFrame=atlas;UF.TestAtlasBorder(mini,atlas)')
prefix=replace(prefix,'B:ApplyTo(outer,2,2,2,6)','UF.TestOuterBorder(mini,outer)')
local a=assert(prefix:find('local sep=sepHost:CreateTexture();',1,true))
local b=assert(prefix:find('f.UF,f.owner,f.mini',a,true))
prefix=prefix:sub(1,a-1)..[[local sep=UF.CreateBarSeparator(mini);mini.HealthPowerSeparator=sep
    mini._fluxMainPowerAlpha=1
    mini.Health=new(mini);mini.Power=new(mini)
    mini.Health._fluxTextAnchor=new(mini.Health)
    for _,bar in ipairs({mini.Health,mini.Power})do
        bar.bg=bar:CreateTexture();bar.bg:SetAllPoints(bar)
    end
    local predicted=new(mini);predicted._fluxPredictionHealth=mini.Health
    predicted.GetStatusBarTexture=function()return mini.Health end
    predicted.shieldOverlay=predicted:CreateTexture()
    mini.totalAbsorbBar=predicted
    UF.TestAnchorPrediction(predicted,predicted.shieldOverlay)
    UF.UpdateFramePartition(mini)
    ]]..prefix:sub(b)
local miniCode=colors.."function UF.TestMiniProfile(frame,unit)\n"..profile.."end\n"..
    "function UF.TestBaseBorder(frame)\n"..baseCall.."\nend\n"..
    "function UF.TestAtlasBorder(frame,atlasBorderFrame,borderInsetY)\n"..atlasCall.."\nend\n"..
    "function UF.TestOuterBorder(frame,outerBorderFrame)\n"..outerCall.."\nend\n"..
    "local SHIELD_OVERLAY_TILE,ABSORB_OVERLAY_TILE=32,32\n"..prediction..separator..partition..
    "UF.TestAnchorPrediction=AnchorOverlayToStatusBarFill\n"
local env=setmetatable({MINI_CODE=miniCode},{__index=_G})
local fixture=assert(load(prefix.."\nreturn {make=make,fields=fields,coverage=coverage,core=core,sample=sample}","@actual-mini-border-fit-model","t",env))()
local checks,scenes,samples=0,0,0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return type(a)=="number"and type(b)=="number"and math.abs(a-b)<1e-7 end
local function rect(o)return{o:GetRect()}end
local function same(a,b,m)for i=1,4 do check(near(a[i],b[i]),m.." component "..i)end end
local function omit(side,k)return side=="Left"and(k=="Left"or k=="TL"or k=="BL")or side=="Right"and(k=="Right"or k=="TR"or k=="BR")end
local canonical={TL={211/256,227/256,1/256,18/256},TR={229/256,245/256,1/256,18/256},
    BL={211/256,227/256,20/256,36/256},BR={229/256,245/256,20/256,36/256}}
local function uv4(t)local u={t:GetTexCoord()};if #u==8 then return{u[1],u[5],u[2],u[4]}end;return u end
local function enclosed(o,frame,label)
    local x,y,w,h=o:GetRect();local fx,fy,fw,fh=frame:GetRect()
    check(x>=fx+3-1e-7 and x+w<=fx+fw-3+1e-7,label.." horizontal interior")
    check(y>=fy+5-1e-7 and y+h<=fy+fh-5+1e-7,label.." vertical interior")
end
local contours,contourSamples={},0
local function rawContour(f,style)
    if contours[style]then return end;contours[style]=true
    local mini=f.mini;local ox,oy,w,h=mini:GetRect();local scale=mini:GetEffectiveScale()
    local raw={}
    for _,k in ipairs({"TL","TR","BL","BR","Top","Bottom","Left","Right"})do
        local t=mini.FluxBorderFrame[k];local x,y,tw,th=t:GetRect();local ts=t:GetEffectiveScale();local uv={t:GetTexCoord()}
        if #uv==4 then uv={uv[1],uv[3],uv[1],uv[4],uv[2],uv[3],uv[2],uv[4]}end
        raw[#raw+1]={t:GetTexture(),{x*ts,y*ts,tw*ts,th*ts},uv,{{0,0},{0,0},{0,0},{0,0}},1}
    end
    -- Source-art interior, not transparent-shadow rejection: flood the area
    -- outside the alpha>=.95 metal ridge. The actual fill/trough rectangle
    -- must stay on its interior side, including all four rounded turns.
    local step,margin=.5,12
    local nx,ny=math.ceil((w+2*margin)/step),math.ceil((h+2*margin)/step)
    local blocked,outside,queue={},{},{}
    local function id(x,y)return y*nx+x+1 end
    for iy=0,ny-1 do for ix=0,nx-1 do
        local x,y=-margin+(ix+.5)*step,-margin+(iy+.5)*step
        local px,py=(ox+x)*scale,(oy+y)*scale;local a=0
        for _,field in ipairs(raw)do
            local b=field[2]
            if px>=b[1]and py>=b[2]and px<=b[1]+b[3]and py<=b[2]+b[4]then
                a=math.max(a,fixture.sample(field,px,py));contourSamples=contourSamples+1
            end
        end
        blocked[id(ix,iy)]=a>=.95
    end end
    local function push(x,y)
        if x<0 or y<0 or x>=nx or y>=ny then return end
        local n=id(x,y);if not blocked[n]and not outside[n]then outside[n]=true;queue[#queue+1]={x,y}end
    end
    for x=0,nx-1 do push(x,0);push(x,ny-1)end
    for y=0,ny-1 do push(0,y);push(nx-1,y)end
    local head=1
    while head<=#queue do local p=queue[head];head=head+1;push(p[1]-1,p[2]);push(p[1]+1,p[2]);push(p[1],p[2]-1);push(p[1],p[2]+1)end
    local interior,leaks=0,0
    for iy=0,ny-1 do for ix=0,nx-1 do
        local x,y=-margin+(ix+.5)*step,-margin+(iy+.5)*step
        if x>=3 and x<=w-3 and y>=5 and y<=h-5 then
            interior=interior+1;if outside[id(ix,iy)]then leaks=leaks+1 end
        end
    end end
    check(interior>1000 and leaks==0,"actual mini fill/trough bounds stay inside the raw rounded metal contour: style="..style.." leaks="..leaks)
end
for _,style in ipairs({1,2})do for _,scale in ipairs({.75,1.25})do
for _,miniScale in ipairs({.7,1.3})do for _,unit in ipairs({"pet","targettarget","partypet1"})do
    local f=fixture.make(style,scale,miniScale,unit,45,.6,unit=="pet")
    local B,UF,mini=f.B,f.UF,f.mini;scenes=scenes+1
    check(mini._fluxMiniBorderScale==.75,"actual Base profile gives every mini the thinner geometry")
    check(mini.barAreaLeft==3 and mini.barAreaRight==-3 and mini._fluxMiniFillTop==5 and mini._fluxMiniFillBottom==5,
        "actual Base profile supplies bounded rounded-corner fill insets")
    check(near(mini:GetWidth(),90)and near(mini:GetHeight(),45),"mini body/input dimensions remain configured")
    local body,parent,portrait=rect(mini),rect(f.owner),rect(f.portrait)
    for _,host in ipairs(f.hosts)do
        local bf=host.FluxBorderFrame
        check(bf._fluxBorderGeometryScale==.75,"all mini base/atlas/outer constructors use q")
        for _,k in ipairs({"TL","TR","BL","BR"})do
            local t=bf[k];check(near(t:GetWidth(),12)and near(t:GetHeight(),(k=="TL"or k=="TR")and 12.75 or 12),"mini corners are physically thinner")
            same(canonical[k],uv4(t),"canonical mini UV remains exact")
            check(B._pieces[t].art:find(style==1 and"Battlefield100"or"ForeverMetal150",1,true),"canonical selected artwork retained")
        end
        local bg=bf.BackgroundFrame
        local x,y,w,h=bg:GetRect();local hx,hy,hw,hh=host:GetRect()
        check(near(x,hx+3)and near(y,hy+5)and near(w,hw-6)and near(h,hh-10),"constructor backdrop fits the mini paint interior")
    end
    local parentBorder=f.portrait.FluxBorderFrame
    check((parentBorder._fluxBorderGeometryScale or 1)==1 and near(parentBorder.TL:GetWidth(),16),"ordinary parent portrait remains original thickness")
    check(mini.PortraitFrame==nil or mini.PortraitFrame.FluxBorderFrame._fluxBorderGeometryScale==.75,"optional mini own portrait receives the same geometry")
    check(near(mini.HealthPowerSeparator:GetHeight(),12.75),"actual separator factory uses mini normal thickness")
    rawContour(f,style)
    enclosed(mini.Health,mini,"health fill");enclosed(mini.Health.bg,mini,"health trough")
    if unit~="partypet1"then
        enclosed(mini.Power,mini,"resource fill");enclosed(mini.Power.bg,mini,"resource trough")
        check(near(mini.Health:GetHeight(),35),"HUD health remains full height behind the resource layer")
    else check(not mini.Power:IsShown()and not mini.HealthPowerSeparator:IsShown(),"party pet retains health-only behavior")end
    local overlay=mini.totalAbsorbBar.shieldOverlay
    check(near(overlay:GetWidth(),84)and near(overlay:GetHeight(),35),"actual public prediction canvas follows mini paint insets")
    enclosed(overlay._fluxTileClip,mini,"prediction clip")
    UF.FitPortraitOverlay(mini,f.owner,f.side);f.flush()
    check(B.Junctions.stats.fallback==nil,"mini attachment stays inside existing renderer budgets: "..tostring(B.Junctions.stats.fallback).." "..unit.." style="..style.." scale="..scale.." mini="..miniScale)
    same(body,rect(mini),"fitting never resizes or moves mini input");same(parent,rect(f.owner),"parent root unchanged")
    same(portrait,rect(f.portrait),"parent portrait content unchanged")
    local wanted=fixture.core(B,f.donor,f.side=="Left"and"Right"or"Left")
    for _,host in ipairs(f.hosts)do for _,k in ipairs({"Top","Bottom"})do
        local t=host.FluxBorderFrame[k];local x=(f.side=="Left"and t:GetLeft()or t:GetRight())*t:GetEffectiveScale()
        check(near(x,wanted),"thinner mini endpoint joins actual parent portrait track")
    end end
    if unit~="partypet1"then
        local t=mini.HealthPowerSeparator;local x=(f.side=="Left"and t:GetLeft()or t:GetRight())*t:GetEffectiveScale()
        check(near(x,wanted),"thinner HP/resource separator shares exact portrait contact")
        local _,y,_,h=t:GetRect();local track=B:GetJoinTracks().Top
        local center=y+h-h*track/17
        check(near(center,mini.Power:GetTop()+1),"separator core stays centered in the resource gap")
    end
    -- Sample the outside rounded cap from the real files before/after paint
    -- transitions; this catches lost bevel/shadow support, beyond box checks.
    local cap=mini.outerBorderFrame.FluxBorderFrame[f.side=="Left"and"TR"or"TL"]
    local x,y,w,h=cap:GetRect();local cs=cap:GetEffectiveScale();local before=fixture.fields(f);local probes={}
    for ix=1,5 do for iy=1,5 do
        local px,py=(x+w*(ix-.19)/6)*cs,(y+h*(iy-.23)/6)*cs
        local a,n=fixture.coverage(before,px,py)
        if a>1/255 then probes[#probes+1]={px,py,a,n};samples=samples+1 end
    end end
    check(#probes>0,"canonical rounded mini cap has meaningful raw-art samples")
    local writes,solves,reads,n=f.state.geometry,B.Junctions.stats.solves,B.Junctions.stats.geometryReads,#f.objects
    for _=1,3 do
        UF.FitPortraitOverlay(mini);B:SetBorderColor(mini,.2,.7,.4,1)
        mini:Hide();mini:Show();f.owner:Hide();f.owner:Show();f.flush()
    end
    f.state.locked=true;UF.FitPortraitOverlay(mini,f.owner,f.side=="Left"and"Right"or"Left");f.state.locked=false
    check(writes==f.state.geometry and solves==B.Junctions.stats.solves and reads==B.Junctions.stats.geometryReads and n==#f.objects,
        "prepared mini reveal/color/combat callbacks have zero geometry/solve/read/allocation")
    for _,host in ipairs(f.hosts)do for _,k in ipairs({"TL","TR","BL","BR","Left","Right"})do
        if omit(f.side,k)then check(host.FluxBorderFrame[k]._fluxPortraitOmitted and not host.FluxBorderFrame[k]:IsShown(),"paint retains omitted portrait-facing sources")end
    end end
    local after=fixture.fields(f)
    for _,p in ipairs(probes)do local a,n=fixture.coverage(after,p[1],p[2]);check(near(a,p[3])and n==p[4],"paint retains actual rounded cap alpha/layer footprint")end
    mini:ClearAllPoints();mini:SetPoint("CENTER",f.owner,"CENTER",40,0);UF.FitPortraitOverlay(mini);f.flush()
    for _,host in ipairs(f.hosts)do
        check(not host.FluxBorderFrame._fluxAttachmentSide,"detachment restores complete thin outline")
        check(near(host.FluxBorderFrame.TL:GetWidth(),12),"detachment preserves mini geometry profile")
    end
end end end end
print("mini_unit_border_fit: "..checks.." passed; "..scenes.." scenes; "..samples.." raw-art cap samples; "..contourSamples.." raw contour samples")
