-- Production observer regression for group-driven computed-rectangle loss.
-- Only addon-authored root dimensions/points qualify; native source guards stay.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(arg[1]or'Core/BorderJunctions.lua')
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
prefix=prefix:gsub('    assert%(load%(', '    e.observe=assert(load(',1)
prefix=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return string.format('%q',source..'\nreturn {snapshot=Snapshot,same=SameSnapshot,geometry=Geometry}')end,1)
local fixture=assert(load(prefix..'\nreturn fixture','@authored-unit-fixture','t',_G))()
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs{1,2}do for _,unit in ipairs{'player','target','focus','targettarget','pet','party1','partypet1'}do for _,scale in ipairs{.75,1,1.25}do
 local j,new,piece,flush,objects,combat,choose,_,e=fixture();choose(style,'class')
 local proto=getmetatable(e.UIParent).__index;local native=proto.GetRect;local rootReads=0
 function proto:GetRect()if self.testRoot then rootReads=rootReads+1;if self.unavailable then return end end;return native(self)end
 function proto:GetSize(ignoreRect)check(ignoreRect==true,'intrinsic size only');local r=self.rect;return self.widthOverride or r[3],r[4]end
 local anchor=new(e.UIParent,{200,100,150,120});anchor.unavailable=true
 -- No complete native/anchor rectangle is available for this reference. Its
 -- identity and the unit's own constraints still never changed.
 function anchor:GetRect()end
 local root=new(e.UIParent,{200,100,150,120});root.testRoot=true;root.unit=unit;root.scale=scale;root._FluxBorderStatic=true
 root._fluxLayoutWidth,root._fluxLayoutHeight=150,120;e['FluxUnitFrame_'..unit]=root
 root:SetPoint('BOTTOMLEFT',anchor,'BOTTOMLEFT',0,0)
 local h=piece(root,'Top',{200,143,150,17});local v=piece(root,'Left',{240,100,16,80});h.scale=scale;v.scale=scale
 flush();check(j.stats.triangles>0,'real unit junction committed')
 local solved,reads,count=j.stats.solves,j.stats.geometryReads,#objects;rootReads=0
 for i=1,16 do
  root.unavailable=i%2==1;if root.unavailable then root:Hide()else root:Show()end
  root:SetFrameLevel(20);j:CommitLayout();flush()
 end
 check(j.stats.solves==solved and j.stats.geometryReads==reads,'computed root availability changes cannot rediscover or rebuild authored unit borders')
 check(rootReads==0 and #objects==count,'visibility-only roster transitions read no computed root rectangle and allocate no replacement fields')
 -- Existing public anchors and dimensions remain live invalidation inputs.
 local a=e.observe.snapshot(root);root:SetPoint('BOTTOMLEFT',anchor,'BOTTOMLEFT',7,0)
 check(not e.observe.same(a,e.observe.snapshot(root)),'real point offset change remains dirty')
 a=e.observe.snapshot(root);root.widthOverride=151
 check(not e.observe.same(a,e.observe.snapshot(root)),'real intrinsic size change remains dirty')
 root.widthOverride=nil
 -- Foreign accessors and private authored sizes/points retain the guarded path.
 local size=proto.GetSize;root.GetSize=function()return 150,120 end
 check(not (e.observe.snapshot(root)or{}).layout,'foreign getter cannot use authored observation')
 root.GetSize=nil
 local secret=setmetatable({},{__eq=function()error('secret comparison')end,__add=function()error('secret arithmetic')end})
 e.issecretvalue=function(x)return rawequal(x,secret)end
 function proto:GetSize()return secret,120 end
 check(not (e.observe.snapshot(root)or{}).layout,'restricted authored size cannot enter layout identity')
 proto.GetSize=size
end end end
print('Authored unit layout: '..checks..' checks PASS; both border types/seven units/three scales;16visibility/availability transitions zero root-rect reads/rebuilds/resources;real point/size changes;private/foreign guards. Native pending.')
