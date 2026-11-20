-- Real shared class-slot producer plus real junction solver. Class dividers
-- formerly had width only until the first player target/focus was painted.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@prepared-icon-fixture','t',_G))()
local source=read(arg[1]or'UnitFrames/FluxUnitFrames_Shared.lua')
local measure=arg[2]=='--measure'
local function section(first,last)
 local a=assert(source:find(first,1,true));return source:sub(a,assert(source:find(last,a+#first,true))-1)
end
local geometry=section('-- Current native state for name-strip icon geometry','--- Combat/rest beside level')
local outerUpdate=section('local function OuterBorderGeometryMatches','-- Additional Power Bar (Druid Mana, etc)')
local a=source:find('function UF.PrepareClassIconBounds(',1,true)
local producer=a and source:sub(a,assert(source:find('function UF.CreateOuterBorder(',a,true))-1)or''
local start=assert(source:find('-- Set splitter height to match outerBorderPadding',source:find('function UF.UpdateOuterBorder(',1,true),true))
local finish=assert(source:find('\n                else\n                    -- Hide borders for NPCs',start,true))
local paint=source:sub(start,finish-1)
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function verifyStableIcons(paint,root,counts,flush,j,scale,style,modern,e)
 paint(root);flush()
 local before=counts.writes
 local solves,reads=j.stats.solves,j.stats.geometryReads
 local start=os.clock()
 for _=1,30 do paint(root);flush()end
 local elapsed=(os.clock()-start)*1000
 local writes=counts.writes-before
 if not measure then check(writes==0,'settled chrome avoids class/spec and divider geometry writes')end
 check(j.stats.solves==solves and j.stats.geometryReads==reads,'settled connected chrome needs no new layout solve')
 local class,spec,left,right=root.classIcon,root.specIcon,root.classIconLeftBorder,root.classIconRightBorder
 local vertical=root.outerBorderAlignment=='BOTTOM'and'TOP'or'BOTTOM'
 local side=root.portraitPosition
 local corner=vertical..side
 local following=vertical..(side=='LEFT'and'RIGHT'or'LEFT')
 local p,c,r,x,y=class:GetPoint(1)
 check(p==corner and c==root.outerBorderFrame and r==corner and x==0
  and y==(vertical=='TOP'and-4 or 4),'class icon remains in its configured corner')
 p,c,r,x,y=spec:GetPoint(1)
 check(p==corner and c==class and r==following and x==0 and y==0,'spec icon keeps the adjacent attachment')
 check(left:IsShown()and right:IsShown()and left:GetHeight()==36 and right:GetHeight()==36,'both live dividers match their icon height')
 p,c,r,x,y=right:GetPoint(1)
 check(p=='CENTER'and c==spec and r=='RIGHT'and x==-2 and y==0,'right divider owns the spec edge')
 p,c,r,x,y=left:GetPoint(1)
 check(p=='CENTER'and c==spec and r=='LEFT'and x==-1 and y==0,'left divider owns the spec edge')
 if scale==1 then
  print(('NAME_STRIP_GEOMETRY unit=%s alignment=%s side=%s style=%d modern=%s writes=%d ms=%.3f')
   :format(root.unit,root.outerBorderAlignment,side,style,tostring(modern),writes,elapsed))
 end
 -- An intervening write gets repaired from current native state.
 spec:SetSize(21,21);spec:SetPoint('CENTER',root,'CENTER',7,3)
 right:SetHeight(12);right:ClearAllPoints();right:SetPoint('CENTER',root,'CENTER',2,0)
 paint(root);flush()
 p,c,r,x,y=spec:GetPoint(1)
 check(spec:GetNumPoints()==1 and p==corner and c==class and r==following and x==0 and y==0
  and spec:GetSize()==36,'full refresh repairs changed size and multiple anchors')
 p,c,r,x,y=right:GetPoint(1)
 check(p=='CENTER'and c==spec and r=='RIGHT'and x==-2 and y==0 and right:GetHeight()==36,'full refresh repairs divider geometry')
 if not measure then
  local priorSecret=e.issecretvalue
  local opaque=setmetatable({},{__eq=function()error('private point compared')end})
  e.issecretvalue=function(v)return rawequal(v,opaque)or priorSecret and priorSecret(v)end
  local savedGetPoint=right.GetPoint
  right.GetPoint=function()return 'CENTER',opaque,'RIGHT',-2,0 end
  before=counts.writes;paint(root)
  check(counts.writes-before==2,'private current point conservatively repairs its anchor')
  right.GetPoint=savedGetPoint;e.issecretvalue=priorSecret;flush()
 end
 e.GetSpecIcon=function()return nil end
 paint(root);flush()
 p,c,r,x,y=right:GetPoint(1)
 check(not spec:IsShown()and not left:IsShown()and right:IsShown()and c==class and r==(side=='LEFT'and'RIGHT'or'LEFT')
  and x==(side=='LEFT'and 1 or-1),'single-class fallback keeps the live stroke attached')
 e.GetSpecIcon=function()return 1234 end
 paint(root);flush()
 check(spec:IsShown()and left:IsShown()and select(2,right:GetPoint(1))==spec,'spec reveal restores both attached dividers')
end
for _,modern in ipairs{false,true}do for _,unit in ipairs{'player','target','focus','party1'}do for _,style in ipairs{1,2}do
 for _,alignment in ipairs{'BOTTOM','TOP'}do for _,portrait in ipairs{'LEFT','RIGHT'}do for _,scale in ipairs{.75,1,1.25}do
  local j,new,piece,flush,objects,lock,choose,_,e=fixture();choose(style,'class')
  e.UF={};if modern then e.issecretvalue=function()return false end end
  e.ValueIsSecret=function(v)return e.issecretvalue and e.issecretvalue(v)end
  e.API={IsSecretValue=e.ValueIsSecret,SafeAccessibleString=function(v)return v end}
  assert(load(geometry,'@actual-name-strip-geometry','t',e))()
  assert(load(producer,'@actual-class-slot-producer','t',e))()
  local function prepare(...)if e.UF.PrepareClassIconBounds then e.UF.PrepareClassIconBounds(...)end end
  local selected=assert(load('return function(self,outerBorderPadding,portraitPosition,br,bg,bb)\n'..paint..'\nend','@actual-class-divider-paint','t',e))()
  local root=new(e.UIParent,{200,100,300,150});root.unit=unit;root.scale=scale;root._FluxBorderStatic=true
  root._fluxPartyMember=unit=='party1'or nil
  local m=getmetatable(root).__index
  function m:GetSize()if self.size then return table.unpack(self.size)end;return self.rect[3],self.rect[4]end
  function m:GetWidth()return self:GetSize()end
  function m:GetHeight()local _,h=self:GetSize();return h end
  function m:SetHeight(h)local w=self:GetSize();self.size={w,h}end
  local counts={writes=0}
  for _,method in ipairs{'SetSize','SetHeight','ClearAllPoints','SetPoint'}do
   local original=m[method]
   m[method]=function(self,...)
    if self.countGeometry then counts.writes=counts.writes+1 end
    return original(self,...)
   end
  end
  local outer=new(root,{200,100,300,150});outer.scale=scale;outer._FluxBorderOwner=root;root.outerBorderFrame=outer
  local function icon()
   local o=new(outer,{0,0,0,0},'Texture');o.scale=scale;o.countGeometry=true
   function o:GetRect()end
   return o
  end
  root.classIcon=icon();root.specIcon=icon();root.classIcon:Hide();root.specIcon:Hide()
  local function divider()
   local o=piece(outer,'Left',{0,0,18,0});o.scale=scale;o.countGeometry=true
   function o:GetRect()end
   o:Hide();return o
  end
  root.classIconLeftBorder=divider();root.classIconRightBorder=divider()
  local track=style==1 and 8 or 9;local line=alignment=='BOTTOM'and 245 or 105
  piece(outer,'Top',{200,line-(17-track),300,17})
  root:Hide();prepare(root,36,alignment,portrait);flush()
  check((j.stats.triangles or 0)>0 and j.stats.fallback==nil,'absent unit has its actual class-divider junction prepared at load')
  check(not root.classIcon:IsShown()and not root.classIconRightBorder:IsShown(),'preparing bounds does not reveal icons or separators')
  check(root.classIconLeftBorder:GetNumPoints()==0,'unused spec-only duplicate cannot steal single-class stroke ownership')
  local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
  for _=1,30 do
   root:Show();root.classIcon:Show();root.specIcon:Hide()
   prepare(root,36,alignment,portrait);selected(root,36,portrait,.2,.6,.9);flush()
   root:Hide();root.classIcon:Hide();root.classIconLeftBorder:Hide();root.classIconRightBorder:Hide()
   prepare(root,36,alignment,portrait);flush()
  end
  check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'actual first/repeated class-target and focus divider paint performs zero reads/solves/resources')
  local old=root.classIcon.size[1]
  lock(true);prepare(root,40,alignment,portrait)
  check(root.classIcon.size[1]==old,'protected geometry is not touched in combat')
  lock(false);prepare(root,40,alignment,portrait);flush()
  check(j.stats.solves==solves+1,'actual configured slot-size change rebuilds its attachment')

  local function noop()end
  e.IsFluxUnitFrame=function()return true end
  e.PublicGeometryNumber=function(v)return not e.ValueIsSecret(v)and type(v)=='number'and v or nil end
  e.UnitIsPlayer=function()return true end
  e.UnitClass=function()return 'Mage','MAGE'end
  e.GetSpecIcon=function()return 1234 end
  e.ClassColorForUnit=function()return{r=.2,g=.6,b=.9}end
  e.TargetUnitUsesSideBySideTotTextLayout,e.PlayerUnitUsesFluxPetLayout=noop,noop
  e.PaintUnitFrameNameText=function()return 'Test',true end
  e.FitUnitFrameNameText,e.LayoutNameStripLevelText,e.LayoutNameStripCombatIcon,e.LayoutNameStripStatusAndPvpIcons=noop,noop,noop,noop
  e.ns={}
  e.UF.UpdateBorderColors,e.UF.LayoutBigDebuffsCornerPlaceholder,e.UF.LayoutPetHappinessIcon=noop,noop,noop
  e.UF.UpdateHealth,e.UF.UpdatePower=noop,noop
  e.UF.FrameUsesPortraitLayout=function()return false end
  root.nameText=new(outer,nil,'FontString');root.nameText.SetJustifyH=noop
  root.outerBorderPadding,root.outerBorderAlignment,root.portraitPosition=36,alignment,portrait
  root:Show()
  assert(load(outerUpdate,'@actual-full-name-strip-update','t',e))()
  verifyStableIcons(e.UF.UpdateOuterBorder,root,counts,flush,j,scale,style,modern,e)
  root.IsEventRegistered=function()return true end
  lock(true)
  local before=counts.writes;e.UF.UpdateOuterBorder(root);flush()
  if not measure then check(counts.writes==before,'settled icon geometry also stays stable during combat paint')end
  check(root.needsOuterBorderUpdate,'combat refresh retains protected work for the normal exit path')
  lock(false);e.UF.UpdateOuterBorder(root);flush()
  if not measure then check(not root.needsOuterBorderUpdate,'normal complete exit clears pending geometry')end
 end end end
end end end
print('Prepared class borders: '..checks..' checks PASS; actual outer-border refresh; player, target, focus and party; both styles/alignments/mirrors/scales; native point repair and pending combat work; native FPS/taint pending')
