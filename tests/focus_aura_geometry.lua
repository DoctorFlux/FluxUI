-- Actual bordered-aura metrics/anchors at independently scaled focus/body sizes.
-- Does not establish native pixels, private widget state or combat safety.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(arg[1] or 'UnitFrames/FluxUnitFrames_Auras.lua')
local function section(a,b)local i=assert(source:find(a,1,true));return source:sub(i,assert(source:find(b,i+#a,true))-1)end
local borderSource=read('FluxBorder.lua')
local borderStart=assert(borderSource:find('local atlasCorners =',1,true))
local borderEnd=assert(borderSource:find('local atlasEdges =',borderStart,true))
local focusCorners=assert(load(borderSource:sub(borderStart,borderEnd-1)..'\nreturn atlasCorners','@focus-native-border-corners','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<1e-7 end
local env=setmetatable({UF={},DEFAULT_AURA_SIZE=20,DEFAULT_AURA_SPACING=2,AURA_BORDER_INSET_X=8,AURA_BORDER_INSET_X2=16,AURA_BORDER_INSET_Y_TOP=10,AURA_BORDER_INSET_Y_BOTTOM=10,ns={},
 IsSecretValue=function(v)return type(v)=='table' end,
 GetFluxAuraLayoutXSqueezeMult=function()return 1 end,
 ShouldAurasAnchorAboveUnit=function()return true end,
 PositionAurasInBorderedContainer=function(c)c.arranged=true end}, {__index=_G})
env.UF.GetFramePublicDimensions=function(f)return f.width,f.height end
env.UF.FrameUsesPortraitLayout=function(f)return f.portrait end
local enableStart=assert(source:find('-- Aura panels anchored above the unit frame use bottom',1,true))
local enableEnd=assert(source:find('    if enableBuffs ~= false or enableDebuffs ~= false then\n        RefreshFrameAuras',enableStart,true))
local enableLayout='\nfunction TestEnableAuraLayout(frame)\n'
 ..'local enableBuffs,enableDebuffs=true,true\n'
 ..'local buffConfig,debuffConfig={},{}\n'
 ..'local buffSize,debuffSize,buffSpacing,debuffSpacing=20,20,2,2\n'
 ..'local buffMax,debuffMax,buffPerRow,debuffPerRow=32,32,8,8\n'
 ..'local lockOwnDebuffSize,ownDebuffMinScale=true,1\n'
 ..source:sub(enableStart,enableEnd-1)..'\nend\n'
local posStart=assert(source:find('PositionAurasInBorderedContainer = function(container)',1,true))
local posEnd=assert(source:find('function UF.ApplyAuraOptionsToFrame',posStart,true))
local packingSource=section("function UF.GetAuraPackingWidth", "--- Row advance")
env.GetAuraLayoutRowStepY=function()return 22 end
assert(load(packingSource..section('local function ComputeAuraContainerWidthHeight','--- Called when Flux raid repositions')..source:sub(posStart,posEnd-1)..enableLayout,'@actual-focus-panel-geometry','t',env))()
local engineSource=read(arg[2] or 'UnitFrames/FluxUnitFrames_AurasEngine.lua')
local engineStart=assert(engineSource:find('local function PlaceEngine',1,true))
local engineEnd=assert(engineSource:find('function UF.AttachEngineAuras',engineStart,true))
env.FlowDir=function(name)return name end
local flowStart=assert(engineSource:find('local function ApplyFlow',1,true))
local flowEnd=assert(engineSource:find('local function ResizeGroupButtons',flowStart,true))
local applyFlow=assert(load('local UF=...\n'..engineSource:sub(flowStart,flowEnd-1)..'\nreturn ApplyFlow','@native-full-width-flow','t',env))(env.UF)
local placeEngine=assert(load('local UF=...\n'..engineSource:sub(engineStart,engineEnd-1)..'\nreturn PlaceEngine','@actual-focus-native-aura-placement','t',env))(env.UF)
local function panel(frame,kind)
 local p={buttons={},containerType=kind,_fluxAuraBaseSize=20,_fluxAuraBaseSpacing=2,scale=frame._fluxFocusAuraPanelScale,_fluxAuraBorderMatchesFocus=frame._fluxCompactFocus}
 function p:GetParent()return frame end
 function p:GetWidth()return self.width end
 function p:GetHeight()return self.height end
 function p:GetSize()return self.width,self.height end
 function p:GetNumPoints()return self.extraPoint and 2 or self.point and 1 or 0 end
 function p:GetPoint()return table.unpack(self.point or {})end
 function p:SetSize(w,h)self.width,self.height=w,h;self.sizeWrites=(self.sizeWrites or 0)+1 end
 function p:ClearAllPoints()self.point=nil;self.extraPoint=nil end
 function p:SetPoint(...)self.point={...};self.anchorWrites=(self.anchorWrites or 0)+1 end
 function p:Show()self.shown=true end
 p.borderFrame={scale=1,SetSize=function(s,w,h)s.width,s.height=w,h;s.sizeWrites=(s.sizeWrites or 0)+1 end,SetScale=function(s,v)s.scale=v;s.scaleWrites=(s.scaleWrites or 0)+1 end}
 function p.borderFrame:GetSize()return self.width,self.height end
 function p.borderFrame:ClearAllPoints()self.point=nil end
 function p.borderFrame:SetPoint(...)self.point={...};self.anchorWrites=(self.anchorWrites or 0)+1 end
 for _,key in ipairs({'TL','TR','BL','BR'})do
  p.borderFrame[key]={ClearAllPoints=function(s)s.point=nil end,SetPoint=function(s,...)s.point={...}end}
 end
 for i=1,2 do
  p.buttons[i]={IsShown=function()return true end,GetWidth=function()return math.min(20,math.max(1,p.width-24))end,
   ClearAllPoints=function(s)s.point=nil end,SetPoint=function(s,...)s.point={...}end}
 end
 p._fluxAuraCaption={GetParent=function()return p end,ClearAllPoints=function(s)s.point=nil end,
  SetPoint=function(s,...)s.point={...};s.writes=(s.writes or 0)+1 end}
 return p
end
env.CreateBorderedAuraContainer=function(frame,kind)return panel(frame,kind)end
local function samePoint(a,b)
 for i=1,5 do if a[i]~=b[i] then return false end end
 return true
end
for _,bodyScale in ipairs({.2,.4,.55,.9})do
 for _,userScale in ipairs({.5,1,1.75})do
  for _,portrait in ipairs({true,false})do
   local f={unit='focus',_fluxCompactFocus=true,width=260,height=85,portrait=portrait,
    _fluxFocusAuraPanelScale=1/bodyScale,outerBorderFrame={},ThreatBar={},_fluxThreatBarMode="between"}
   function f:GetWidth()error('focus must use recorded public width')end
   function f:GetHeight()error('focus must use recorded public height')end
   f.BuffContainer=panel(f,'Buff');f.DebuffContainer=panel(f,'Debuff')
   env.UF.UpdateAuraPosition(f)
   local visualWidth=(260+(portrait and 85 or 0))*bodyScale*userScale
   for _,p in ipairs({f.BuffContainer,f.DebuffContainer})do
    check(near(p.width*userScale,visualWidth/2),'each panel is exactly half of the visible focus frame width')
    check(p.height>=64 and p.height<=140,'two aura rows fit the focus panel height bounds')
    check(p.buttons[1].point and near(p.borderFrame.width*p.borderFrame.scale,p.width) and near(p.borderFrame.height*p.borderFrame.scale,p.height),'border and icons share converted geometry')
    check(p._fluxAuraGrowUpward and p.point[2]==f.outerBorderFrame and p.point[3]:find('TOP',1,true),'both panels stay above the compact focus header')
    check(p.size==20 and p.spacing==2,'existing icon size/spacing settings are preserved')
    check(near(p.borderFrame.scale,bodyScale),'border art uses the same scale as the focus border while icons keep their size')
    local icon=p.buttons[1].point
    check(near(icon[4],(p.containerType=='Debuff' and -5 or -2)*bodyScale),'focus icon starts at target-equivalent body-relative horizontal origin')
    check(near(p.point[5]+icon[5],0),'focus icon bottom meets the header at the same origin as target')
    check(near(p._fluxAuraCaption.point[5],5*bodyScale),'focus caption uses target-equivalent baseline')
    check(near(p._fluxAuraCaption.point[4],(p.containerType=='Debuff' and -6.5 or -3.5)*bodyScale),
     'focus caption uses target-equivalent horizontal origin')
    local engine={points={},SetPoint=function(s,...)s.points[#s.points+1]={...}end,
     SetFrameLevel=function()end,SetClipsChildren=function()end}
    p.SetClipsChildren=function(s,v)s.clips=v end
    placeEngine(engine,p)
    engine.SetFlowLayoutPadding=function(s,l,r,t,b)s.padding={l,r,t,b}end
    engine.SetFlowLayoutMaximumLineSize=function(s,w)s.lineWidth=w end
    applyFlow(engine,p)
    check(engine.padding[1]==0 and engine.padding[2]==0 and near(engine.lineWidth,p.width),'native flow uses full focus panel width without fixed horizontal padding')
    check(near(engine.points[1][4],icon[4]) and near(engine.points[1][5]+10,icon[5]),'native and Lua aura placement share content offsets')
    check(p.clips==false,'native focus content translation is not clipped at compact panel edge')
    for key,offset in pairs(focusCorners)do
     local point=p.borderFrame[key].point
     local right=key=='TR' or key=='BR';local bottom=key=='BL' or key=='BR'
     check(point[4]==offset.ox+(right and -2 or 2) and point[5]==offset.oy+(bottom and 2 or -2),
      'aura corners use the same inset and artwork offsets as the real focus border')
    end
   end
   check(near((f.BuffContainer.width+f.DebuffContainer.width)*userScale,visualWidth),'paired aura panels cover exactly one focus width')
   check(f.BuffContainer.point[4]==0 and f.DebuffContainer.point[4]==0,'aura panels keep the original focus outer-frame edges')
   check(near(f.BuffContainer.point[5],-7*bodyScale),'vertical border nesting follows body scale')
   local expectedBuff,expectedDebuff=f.BuffContainer.point,f.DebuffContainer.point
   env.TestEnableAuraLayout(f)
   check(samePoint(f.BuffContainer.point,expectedBuff) and samePoint(f.DebuffContainer.point,expectedDebuff),
    'actual re-enable path uses the same focus positions as outer-border relayout')
   local fresh={unit='focus',_fluxCompactFocus=true,width=f.width,height=f.height,portrait=portrait,
    _fluxFocusAuraPanelScale=f._fluxFocusAuraPanelScale,outerBorderFrame=f.outerBorderFrame,
    GetWidth=f.GetWidth,GetHeight=f.GetHeight}
   env.TestEnableAuraLayout(fresh)
   check(samePoint(fresh.BuffContainer.point,expectedBuff) and samePoint(fresh.DebuffContainer.point,expectedDebuff),
    'actual first-create path uses the same focus positions as outer-border relayout')
   env.UF.UpdateAuraPosition(f)
   check(f.BuffContainer.borderFrame.scaleWrites==1 and f.DebuffContainer.borderFrame.scaleWrites==1,
    'unchanged aura refreshes do not keep changing border scale')
   check(f.BuffContainer._fluxAuraCaption.writes==1,'unchanged aura refreshes do not rewrite caption anchors')
  end
 end
end
-- Dense rows exercise real Lua positioning and the native flow width contract.
local dense={unit='focus',_fluxCompactFocus=true,width=260,height=100,portrait=true,
 _fluxFocusAuraPanelScale=1,outerBorderFrame={},ThreatBar={},_fluxThreatBarMode='between'}
dense.GetWidth=function(f)return f.width end;dense.GetHeight=function(f)return f.height end
dense.BuffContainer=panel(dense,'Buff');dense.DebuffContainer=panel(dense,'Debuff')
for _,c in ipairs({dense.BuffContainer,dense.DebuffContainer})do
 c.buttons={}
 for i=1,20 do c.buttons[i]={IsShown=function()return true end,GetWidth=function()return 20 end,
  ClearAllPoints=function(s)s.point=nil end,SetPoint=function(s,...)s.point={...}end}end
end
env.UF.UpdateAuraPosition(dense)
for _,c in ipairs({dense.BuffContainer,dense.DebuffContainer})do
 local perRow=math.max(1,math.floor((c.width+2)/22))
 check(perRow>=8,'normal icons fill the newly available row width')
 local y=c.buttons[1].point[5]
 for i=1,perRow do check(c.buttons[i].point[5]==y,'icons fit across the first row before wrapping')end
 check(c.buttons[perRow+1].point[5]>y,'next icon wraps only after the available width is filled')
end
env.FluxUnitFrames_ShouldUseFlux=function(unit)return unit~='focustarget'end
env.UF.UpdateAuraPosition(dense)
check(near(dense.BuffContainer.width+dense.DebuffContainer.width,360),'focus-target settings do not resize the aura row')
env.FluxUnitFrames_ShouldUseFlux=nil
-- Existing native containers follow a changed panel scale and cache stable anchors.
local native={points={},SetPoint=function(s,...)s.points[#s.points+1]={...}end,
 SetFrameLevel=function()end,SetClipsChildren=function()end}
placeEngine(native,dense.BuffContainer)
local initialWrites=#native.points
placeEngine(native,dense.BuffContainer)
check(#native.points==initialWrites,'unchanged native placement does not rewrite anchors')
dense._fluxFocusAuraPanelScale=2
env.UF.UpdateAuraPosition(dense)
placeEngine(native,dense.BuffContainer)
local last=native.points[#native.points]
check(#native.points==initialWrites+2 and near(last[4],-1) and near(last[5]+10,3.5),
 'existing native placement follows changed focus scale')
placeEngine(native,dense.BuffContainer)
check(#native.points==initialWrites+2,'updated native placement caches its new anchors')
-- Ordinary target/legacy focus retain their original metrics and nesting.
local legacy={unit='focus',width=119,height=50,portrait=true,outerBorderFrame={}}
function legacy:GetWidth()return self.width end
function legacy:GetHeight()return self.height end
legacy.BuffContainer=panel(legacy,'Buff');legacy.DebuffContainer=panel(legacy,'Debuff')
env.UF.UpdateAuraPosition(legacy)
check(legacy.BuffContainer.width==97.5 and legacy.BuffContainer.height==66,'legacy focus metrics unchanged')
local legacyBuff,legacyDebuff=legacy.BuffContainer.point,legacy.DebuffContainer.point
env.TestEnableAuraLayout(legacy)
check(samePoint(legacy.BuffContainer.point,legacyBuff) and samePoint(legacy.DebuffContainer.point,legacyDebuff),
 'legacy focus create/re-enable position remains unchanged')
legacy.unit='target';env.UF.UpdateAuraPosition(legacy)
local targetBuff,targetDebuff=legacy.BuffContainer.point,legacy.DebuffContainer.point
env.TestEnableAuraLayout(legacy)
check(samePoint(legacy.BuffContainer.point,targetBuff) and samePoint(legacy.DebuffContainer.point,targetDebuff),
 'target create/re-enable and relayout keep their matching positions')
for _,style in ipairs({1,2})do for _,above in ipairs({true,false})do
 local tracks=style==1 and {Top=8,Bottom=8}or{Top=9,Bottom=7}
 env.Border={GetJoinTracks=function()return tracks end}
 env.ShouldAurasAnchorAboveUnit=function()return above end
 legacy.outerBorderFrame.FluxBorderFrame={_fluxBorderInsets={2,2}}
 env.UF.UpdateAuraPosition(legacy)
 for _,p in ipairs({legacy.BuffContainer,legacy.DebuffContainer})do
  local bf=p.borderFrame
  check(near(bf.width,legacy.width/2+legacy.height/2),'decorative aura halves exactly cover the unit while icon/container packing stays unchanged')
  local point=bf.point;local offset=point[5]
  local auraStroke,unitStroke
  if above then auraStroke=-10+offset+11-tracks.Bottom;unitStroke=6-2-tracks.Top
  else auraStroke=10+offset+4-tracks.Top;unitStroke=2+9-tracks.Bottom end
  check(near(auraStroke,unitStroke),'aura and unit header sample one exact shared stroke in both styles/above and below')
  for key,info in pairs(focusCorners)do
   local q=bf[key].point;local right=key=='TR'or key=='BR';local bottom=key=='BL'or key=='BR'
   check(q[4]==info.ox+(right and -2 or 2)and q[5]==info.oy+(bottom and 2 or -2),'ordinary aura caps use the same offsets as focus and shared unit chrome')
  end
  local writes=bf.anchorWrites;env.UF.UpdateAuraPosition(legacy)
  check(bf.anchorWrites==writes,'unchanged aura data cannot re-anchor its decorative border')
 end
end end
-- Group reconciliation uses UpdateAuraPosition even when the dock, panel
-- dimensions and borders are already correct. It still refreshes aura paint.
local private={}
env.IsSecretValue=function(value)return rawequal(value,private)end
for _,f in ipairs({dense,legacy})do
 local p,b=f.BuffContainer,f.DebuffContainer
 local calls=0
 env.UF.UpdateAuras=function()calls=calls+1 end
 env.UF.UpdateAuraPosition(f)
 local function work()
  return p.anchorWrites+b.anchorWrites,p.sizeWrites+b.sizeWrites+p.borderFrame.sizeWrites+b.borderFrame.sizeWrites
 end
 local anchors,sizes=work()
 for _=1,20 do env.UF.UpdateAuraPosition(f)end
 local afterAnchors,afterSizes=work()
 check(calls==21,'existing aura paint still runs on every explicit refresh')
 if arg[3]~='--measure' then
  check(afterAnchors==anchors and afterSizes==sizes,'prepared aura panel keeps unchanged geometry across a roster burst')
 end
 print(string.format('AURA_ROSTER_WORK compact=%s anchors=%d sizes=%d paint=%d',
  tostring(not not f._fluxCompactFocus),afterAnchors-anchors,afterSizes-sizes,calls-1))
 local point=table.pack(p:GetPoint());local w,h=p:GetSize()
 p.extraPoint=true;p.width=w+8
 env.UF.UpdateAuraPosition(f)
 check(not p.extraPoint and samePoint(p.point,point) and p.width==w and p.height==h,'unsignaled native drift is restored')
 local getPoint,getSize=p.GetPoint,p.GetSize
 p.GetPoint=function()return point[1],private,point[3],point[4],point[5]end
 p.GetSize=function()return private,h end
 anchors,sizes=work();env.UF.UpdateAuraPosition(f)
 afterAnchors,afterSizes=work()
 check(afterAnchors>anchors and afterSizes>sizes and samePoint(p.point,point),'unreadable native geometry takes the existing setter path')
 p.GetPoint,p.GetSize=getPoint,getSize
end
print('Focus aura geometry: '..checks..' actual metric/anchor checks; native pixels pending')
