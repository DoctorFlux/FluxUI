-- Actual shared constructors, portrait/outer positioning and tint with the real
-- border factory. This proves decorative geometry/work, not native pixels/taint.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local prefix=assert(read('tests/border_types.lua'):match('^(.-)for _, forever in ipairs'))
local model=assert(load(prefix..'\nreturn model','@portrait-border-factory','t',_G))()
local source=read(arg[1]or'UnitFrames/FluxUnitFrames_Shared.lua')
local creator=assert(source:find('function UF.CreatePortrait(frame)',1,true))
local create=source:sub(creator,assert(source:find('-- Create the Model for 3D portrait',creator,true))-1)..'return portraitFrame end'
local helper=source:find('function UF.FitPortraitBorderBounds(',1,true)
local fit=helper and source:sub(helper,creator-1)or'function UF.FitPortraitBorderBounds()return false end'
local colorStart=source:find('function UF.GetMiniUnitChromeColor(',1,true)
local colorHelpers=colorStart and source:sub(colorStart,assert(source:find('function UF.ForeverNpcChrome(',colorStart,true))-1)or''
local oa=assert(source:find('function UF.CreateOuterBorder(frame)',1,true))
local outer=source:sub(oa,assert(source:find('-- Inside outer chrome',oa,true))-1)..'return outerBorderFrame end'
local pa=assert(source:find('-- Position portrait if it exists (full layout',1,true))
local position=source:sub(pa,assert(source:find('-- Apply Health - positioned within bar area',pa,true))-1)
local a=assert(source:find('-- Layout Updates (Protected during combat)',1,true))
a=assert(source:find('        if hasPortrait then',a,true))
local outerPosition=source:sub(a,assert(source:find('if self.mouseoverHighlight',a,true))-1)
local helperStart=source:find('local function OuterBorderGeometryMatches',1,true)
local outerHelpers=helperStart and source:sub(helperStart,assert(source:find('function UF.UpdateOuterBorder(',helperStart,true))-1)or''
local ta=assert(source:find('local PORTRAIT_COMBAT_BORDER_R',1,true))
local tint=source:sub(ta,assert(source:find('function UF.UpdateBorderColors',ta,true))-1)
local factors={TOPLEFT={0,1},TOPRIGHT={1,1},BOTTOMLEFT={0,0},BOTTOMRIGHT={1,0},CENTER={.5,.5}}
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<1e-7 end
for _,forever in ipairs{false,true}do for _,atlas in ipairs{'all','none'}do
 for _,style in ipairs{1,2}do for _,scale in ipairs{.75,1,1.25}do
  for _,alignment in ipairs{'TOP','BOTTOM'}do for _,side in ipairs{'RIGHT','LEFT'}do
   for _,unit in ipairs{'player','target','focus'}do
    local e,b,db,new,counts=model(forever,atlas);db.borderType=style
    local state={locked=false,combat=false,clears=0,levels=0}
    local secret={};e.IsSecretValue=function(v)return rawequal(v,secret)end
    e.ValueIsSecret=e.IsSecretValue
    local m=getmetatable(e.UIParent).__index
    function m:GetName()return self.name or'FluxUnitFrame_test'end
    function m:GetEffectiveScale()return(self.scale or 1)*(self.parent and self.parent:GetEffectiveScale()or 1)end
    function m:ClearAllPoints()check(not state.locked,'no protected anchor clears during combat');self.points={};self.allPoints=nil;state.clears=state.clears+1 end
    local all=m.SetAllPoints
    function m:SetAllPoints(p)all(self,p or self.parent)end
    local point=m.SetPoint
    function m:SetPoint(...)check(not state.locked,'no protected anchor setters during combat');return point(self,...)end
    local level=m.SetFrameLevel
    function m:SetFrameLevel(v)check(not state.locked,'combat tint cannot move compiled source layers');state.levels=state.levels+1;level(self,v)end
    local function rect(o)
     if o.rect then return table.unpack(o.rect)end
     if o.allPoints or #o.points==0 then return rect(o.allPoints or o.parent)end
     local c={}
     for _,p in ipairs(o.points)do
      local relative=p[2]or o.parent;local x,y,w,h=rect(relative);local r,f=factors[p[3]],factors[p[1]]
      local ratio=relative:GetEffectiveScale()/o:GetEffectiveScale()
      c[#c+1]={f[1],(x+r[1]*w)*ratio+(p[4]or 0),f[2],(y+r[2]*h)*ratio+(p[5]or 0)}
     end
     local function axis(i,size)
      local first=c[1]
      for k=2,#c do if c[k][i]~=first[i]then size=(c[k][i+1]-first[i+1])/(c[k][i]-first[i]);break end end
      return first[i+1]-first[i]*size,size
     end
     local x,w=axis(1,o.width);local y,h=axis(3,o.height);return x,y,w,h
    end
    function m:GetRect()return rect(self)end
    local uf={};e.UF=uf;e.ns={UnitFrames=uf,Border=b};e.Border=b
    e.InCombatLockdown=function()return state.locked end
    e.SecureUnitButton_OnLoad=function()end
    e.PublicGeometryNumber=function(v)return type(v)=='number'and v or nil end
    e.GetUnitClassColor=function()return e.RAID_CLASS_COLORS.MAGE end;e.ClassColorForUnit=e.GetUnitClassColor
    e.SafeBooleanTest=function(v,fallback)return type(v)=='boolean'and v or fallback end
    e.UnitExists=function()return true end;e.UnitIsPlayer=e.UnitExists
    e.UnitAffectingCombat=function()return state.combat end
    function uf.GetFramePublicDimensions(f)return f.rect[3],f.rect[4]end
    function uf.RecordFrameDimensions(f,w,h)f._fluxLayoutWidth,f._fluxLayoutHeight=w,h end
    function uf.SetRelativeFramePublicLevel(f,p,n)f:SetFrameLevel(p:GetFrameLevel()+n)end
    function uf.RecordRelativeFramePublicLevel()end
    function uf.GetFramePublicLevel(f)return f:GetFrameLevel()end
    function uf.SetFramePublicLevel(f,n)f:SetFrameLevel(n)end
    function uf.ForeverNpcChrome()end
    function uf.GetNormalUnitBackdrop(_,r,g,bb)return r,g,bb end
    assert(load(colorHelpers..'\n'..fit..'\n'..create..'\n'..outer..'\n'..tint,'@actual-portrait-border-producers','t',e))()
    local positionPortrait=assert(load('return function(self,hasPortrait,portraitSize,portraitPosition)\n'..position..'end','@actual-portrait-position','t',e))()
    local positionOuter=assert(load(outerHelpers..'return function(self,totalWidth,totalHeight,outerBorderPadding,outerBorderAlignment,portraitPosition,hasPortrait,portraitSize)\n'..outerPosition..'end','@actual-outer-position','t',e))()
    e.UIParent.rect={0,0,1920,1080}
    local frame=new(e.UIParent);frame.unit=unit;frame.rect={977.271545,106.839996,237.593566,88};frame.scale=scale;frame.portraitPosition=side
    local pf=uf.CreatePortrait(frame);frame.PortraitFrame=pf
    local ob=uf.CreateOuterBorder(frame)
    positionPortrait(frame,true,88,side);positionOuter(frame,237.593566,88,36,alignment,side,true,88)
    local bf=pf.FluxBorderFrame;local tracks=b:GetJoinTracks()
    local function core(t,which)local x,_,w=t:GetRect();return(x+w*tracks[which]/16)*t:GetEffectiveScale()end
    local exterior=side=='RIGHT'and'Right'or'Left'
    for _,key in ipairs(side=='RIGHT'and{'Right','TR','BR'}or{'Left','TL','BL'})do
     check(near(core(bf[key],exterior),core(ob.FluxBorderFrame[key],exterior)),unit..' '..side..' portrait exterior core meets real outer source: '..key)
    end
    local px,py,pw,ph=pf:GetRect();local fx,fy,fw,fh=frame:GetRect();local bx,by,bw,bh=bf:GetRect()
    check(near(bx,px)and near(by,py)and near(bh,ph)and near(bw,pw+(side=='RIGHT'and 2 or 0)),'only decorative right extent changes; other portrait bounds remain')
    check(near(px,side=='RIGHT'and fx+fw-2 or fx+2-pw)and near(pw,88),'actual portrait/body overlap and dimensions stay unchanged')
    local padding=bf._fluxBorderInsets;check(padding[1]==2 and padding[2]==2,'factory insets retained')
    local anchors={};for _,key in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do anchors[key]=bf[key].points end
    local savedBg={bf.BackgroundFrame:GetRect()};local modelFrame=new(pf);modelFrame:SetSize(84,84);modelFrame:SetPoint('CENTER',pf,'CENTER',0,0)
    local savedModel={modelFrame:GetRect()};local _,writes=counts();writes=writes+state.clears+state.levels;local objects=select(1,counts())
    for _=1,10 do
     state.locked=true;state.combat=true;uf.UpdatePortraitCombatTint(frame)
     state.combat=false;uf.UpdatePortraitCombatTint(frame);state.locked=false
     check(not uf.FitPortraitBorderBounds(frame,pf,side),'unchanged fitting reuses prepared anchors')
     check(near(core(bf[exterior],exterior),core(ob.FluxBorderFrame[exterior],exterior)),'red/normal paint preserves fitted exterior')
    end
    local _,after=counts();check(after+state.clears+state.levels==writes and select(1,counts())==objects,'combat red/restore and unchanged fit allocate/move no geometry or source layers')
    local opposite=side=='RIGHT'and'LEFT'or'RIGHT'
    state.locked=true;check(not uf.FitPortraitBorderBounds(frame,pf,opposite)and frame.needsPartitionRelayout,'combat mirror change waits for normal partition');state.locked=false
    local _,afterCombat=counts();check(afterCombat+state.clears+state.levels==writes,'combat fitting performs no setters')
    check(not uf.FitPortraitBorderBounds(frame,pf,secret),'private side never selects geometry')
    local old=frame.portraitPosition;frame.portraitPosition=secret;check(not uf.FitPortraitBorderBounds(frame,pf),'private side metadata remains unread');frame.portraitPosition=old
    check(uf.FitPortraitBorderBounds(frame,pf,opposite)and uf.FitPortraitBorderBounds(frame,pf,side),'actual mirror change restores then refits decorative extent')
    for i,v in ipairs(savedBg)do check(near(({bf.BackgroundFrame:GetRect()})[i],v),'background bounds unchanged')end
    for i,v in ipairs(savedModel)do check(near(({modelFrame:GetRect()})[i],v),'portrait model bounds unchanged')end
    for key,points in pairs(anchors)do check(bf[key].points==points,'original factory piece anchors retained: '..key)end
    check(bf._fluxBorderInsets==padding,'fit never replaces consumer padding metadata')
    check(not uf.FitPortraitBorderBounds({})and not uf.FitPortraitBorderBounds({},{}),'missing frame/border property guard')
   end
  end end
 end end
end end
print('Portrait border fit: '..checks..' checks PASS; actual constructors/partition/outer/tint and shared factory; both types/atlas-file clients/mirrors/alignments/scales; exterior cores match; content/model/background/padding retained; cached paint and combat/private guards. Native pixels/taint pending')
