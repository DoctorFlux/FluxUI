-- Reproduce R35 target/focus outer.Left gaining native geometry on first show.
-- Existing public corner anchors must prepare exactly the later native bounds.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@hidden-anchor-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs{1,2}do for _,unit in ipairs{'target','focus','party1','pet','targettarget'}do
 for _,scale in ipairs{.75,1,1.25}do
  local j,new,piece,flush,objects,lock,choose,_,e=fixture();choose(style,'class')
  local create=e.CreateFrame
  e.CreateFrame=function(...)
   local o=create(...);local get=o.GetPoint
   function o:GetPoint(i)local p,r,rp,x,y=get(self,i);if p then return p,r,rp,x or 0,y or 0 end end
   return o
  end
  local ready=false;local regions={}
  local function delayed(o,width,height)
   local get=o.GetRect
   function o:GetRect()if ready then return get(self)end end
   function o:GetLeft()if ready then local x=self:GetRect();return x end end
   function o:GetBottom()if ready then local _,y=self:GetRect();return y end end
   if width then function o:GetSize(ignoreRect)check(ignoreRect==true,'intrinsic size requested without relying on a native computed rect');return width,height end end
   regions[#regions+1]=o;return o
  end
  local root=delayed(new(e.UIParent,{200,100,300,120}),300,120)
  root.scale=scale;root.unit=unit;root._FluxBorderStatic=true
  root:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',200,100);root:Hide()
  local host=delayed(new(root,{200,100,300,120}));host.scale=scale;host._FluxBorderOwner=root;host:SetAllPoints(root)
  host.anchors={{'TOPLEFT',root,'TOPLEFT',0,0},{'BOTTOMRIGHT',root,'BOTTOMRIGHT',0,0}}
  local tl=delayed(new(host,{202,201,16,17},'Texture'),16,17);tl.scale=scale;tl:SetPoint('TOPLEFT',host,'TOPLEFT',2,-2)
  local tr=delayed(new(host,{482,201,16,17},'Texture'),16,17);tr.scale=scale;tr:SetPoint('TOPRIGHT',host,'TOPRIGHT',-2,-2)
  local bl=delayed(new(host,{202,102,16,16},'Texture'),16,16);bl.scale=scale;bl:SetPoint('BOTTOMLEFT',host,'BOTTOMLEFT',2,2)
  local top=piece(host,'Top',{218,201,264,17});top.scale=scale;delayed(top)
  top:SetPoint('TOPLEFT',tl,'TOPRIGHT',0,0);top:SetPoint('BOTTOMRIGHT',tr,'BOTTOMLEFT',0,0)
  local left=piece(host,'Left',{202,118,16,83});left.scale=scale;delayed(left)
  left:SetPoint('TOPLEFT',tl,'BOTTOMLEFT',0,0);left:SetPoint('BOTTOMRIGHT',bl,'TOPRIGHT',0,0)
  -- An internal divider gives the solver a real T even while all native GetRect
  -- calls in this unit's corner/edge chain are unavailable.
  local divider=piece(host,'Left',{341,175,16,43});divider.scale=scale;delayed(divider,16,43)
  divider:SetPoint('TOPLEFT',host,'TOPLEFT',141,-2)
  flush();check(j.stats.fallback==nil and j.stats.triangles>0,'hidden public anchors prebuild actual unit T geometry')
  local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
  for _,combat in ipairs{false,true}do
   lock(combat)
   for _=1,10 do
    ready=true;root:Show()
    for _,o in ipairs(regions)do j:Invalidate(nil,o)end
    j:CommitLayout();flush()
    ready=false;root:Hide()
    for _,o in ipairs(regions)do j:Invalidate(nil,o)end
    j:CommitLayout();flush()
   end
  end
  check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,
   'native rectangle availability exactly matches prepared public anchors; no solves/reads/resources on first or repeated show/clear, including combat')
  lock(false);root:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',208,100);root.rect[1]=208
  j:CommitLayout();check(j.stats.solves==solves+1,'real hidden-root anchor changes still rebuild prepared borders')
 end
end end
-- Do not derive withheld native geometry or follow cyclic anchor chains.
for _,failure in ipairs{'restricted','cycle','budget','dynamic'}do
 local j,new,piece,flush,_,_,_,_,e=fixture()
 local root=new(e.UIParent);root.unit='focus';root._FluxBorderStatic=failure~='dynamic'
 local edge=piece(root,'Top',{0,0,100,17});local probes=0
 function edge:GetSize()return 100,17 end
 if failure=='restricted'then
  local secret={};e.issecretvalue=function(v)return rawequal(v,secret)end
  function edge:GetRect()return secret,nil,100,17 end
  function edge:GetNumPoints()error('restricted rectangle must not be reconstructed')end
 else
  function edge:GetRect()end
  function edge:GetNumPoints()probes=probes+1;return failure=='budget'and 33 or 1 end
  edge:SetPoint('TOPLEFT',edge,'TOPLEFT',0,0)
 end
 flush();check((j.stats.triangles or 0)==0 and probes<=6,'invalid/private/cyclic/non-unit anchor resolution stays bounded and fails closed: '..failure..' probes='..probes)
end
print('Hidden unit anchors: '..checks..' checks PASS; delayed native root/corner/edge rectangles AND origins; exact public anchor geometry; intrinsic sizes; both styles/five units/three scales; first/repeated visibility0reads/solves/resources; actual moves; private/cycle/budget guards; native acceptance pending')
