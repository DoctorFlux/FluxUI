-- Production regional commit must reserve/reuse unchanged local sprites.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local text=read('tests/border_locality.lua');local prefix=text:sub(1,assert(text:find("if arg[1]=='--work' then",1,true))-1)
prefix=prefix:gsub("local corePath='Core/BorderJunctions.lua'","local corePath=arg[1]or'Core/BorderJunctions.lua'",1)
local run=prefix..[[
if arg[2]~='--measure' then
 local m=model(scenes(1)[1].groups,1,1)
 local parent=m.parents[1]
 local field=m.new(parent,nil,'Texture')
 field._junctionSetCache={}
 local box=m.j._FieldGeometry.Box
 local clear,place=field.ClearAllPoints,field.SetPoint
 local clears,points=0,0
 function field:ClearAllPoints() clears=clears+1;return clear(self) end
 function field:SetPoint(...) points=points+1;return place(self,...) end
 box(field,parent,1,2,9,10)
 check(clears==1 and points==1,'initial field receives one clean anchor')
 box(field,parent,3,4,9,10)
 local anchor,relative,relativePoint,x,y=field:GetPoint(1)
 check(clears==1 and points==2 and field:GetNumPoints()==1 and anchor=='BOTTOMLEFT'
     and relative==parent and relativePoint=='BOTTOMLEFT' and x==3 and y==4,'same owned point updates in place')
 box(field,parent,3,4,9,10)
 check(clears==1 and points==2,'an identical request keeps the native anchor')
 field:SetPoint('TOPRIGHT',parent,'TOPRIGHT',0,0)
 box(field,parent,5,6,9,10)
 check(clears==2 and field:GetNumPoints()==1,'repair a field with an extra native anchor')
 field:ClearAllPoints()
 field:SetPoint('TOPLEFT',parent,'TOPLEFT',0,0)
 box(field,parent,7,8,9,10)
 check(clears==4 and field:GetPoint(1)=='BOTTOMLEFT','repair a different point name')
 local secret={}
 local issecret=m.e.issecretvalue
 m.e.issecretvalue=function(v)return rawequal(v,secret) or issecret and issecret(v)end
 field.GetPoint=function()return secret,secret,secret end
 box(field,parent,9,10,9,10)
 check(clears==5,'private anchor state uses the full writer')
 field.GetPoint=function()error('native point getter unavailable',0)end
 box(field,parent,11,12,9,10)
 check(clears==6,'an unavailable point getter uses the full writer')
 field.GetPoint=nil
 box(field,m.parents[2],13,14,9,10)
 check(clears==7 and select(2,field:GetPoint(1))==m.parents[2],'changing the anchor owner clears the former point')
 local marker={}
 field.SetPoint=function(self,...)place(self,...);error(marker,0)end
 local ok,err=pcall(box,field,m.parents[2],15,16,9,10)
 check(not ok and rawequal(err,marker) and field:GetNumPoints()==0,'anchor setter errors still propagate and clear the prior point')
 field.SetPoint=place
 box(field,m.parents[2],15,16,9,10)
 check(clears==9 and select(4,field:GetPoint(1))==15,'recovery after a failed write takes the full writer')
 local follow=m.j._FieldGeometry.Follow
 if follow then
  local owner=m.parents[2]
  local leader=m.new(owner,nil,'Texture')
  leader._junctionSetCache={}
  box(leader,owner,15,16,9,10)
  follow(field,leader)
  check(clears==10 and field.target==leader and field:GetNumPoints()==2,
   'a follower replaces its own box with the two leader anchors')
  follow(field,leader)
  check(clears==10 and field._junctionSetCache.leader==leader,
   'an existing link inherits a moved leader without another follower write')
  leader:Hide()
  check(field:IsShown() and field:GetEffectiveAlpha()==1 and field.target==leader,
   'followers keep their own paint independently of the leader')
  box(field,owner,17,18,11,12)
  follow(leader,field)
  check(clears==11 and not field.target and leader.target==field and not field._junctionSetCache.leader,
   'the next leader restores its direct box before old neighbors follow it')
  local attach=field.SetAllPoints
  field.SetAllPoints=function(self,target)attach(self,target);error(marker,0)end
  local spare=m.new(owner,nil,'Texture')
  spare._junctionSetCache={}
  box(spare,owner,20,21,9,9)
  ok,err=pcall(follow,field,spare)
  check(not ok and rawequal(err,marker) and field:GetNumPoints()==0 and not field.target,
   'failed shared anchor clears partial anchors and propagates the same failure')
  field.SetAllPoints=attach
  box(field,owner,17,18,11,12)
  check(clears==14 and field:GetNumPoints()==1 and not field.target and field.size[1]==11,
   'a direct writer restores position and size after failed attachment')
 end
end
for _,style in ipairs{1,2}do for _,scale in ipairs{.75,1,1.25}do
 local m=model(scenes(style)[1].groups,style,scale);local reference=model(scenes(style)[1].groups,style,scale,true)
 local strataReads,levelReads=0,0
 for _,parent in ipairs(m.parents) do
  local strata,level=parent.GetFrameStrata,parent.GetFrameLevel
  function parent:GetFrameStrata()strataReads=strataReads+1;return strata(self)end
  function parent:GetFrameLevel()levelReads=levelReads+1;return level(self)end
 end
 local report,clock={},0;m.e.Flux.PerfCapture={GetActiveWatchReport=function()return report end};m.e.debugprofilestop=function()clock=clock+1;return clock end
 local hits,setters=0,0
 for step,index in ipairs{8,18,8,18}do
  local t=m.sources[index][1];t.rect[1]=t.rect[1]+(step<3 and 7 or -7);m.j:Invalidate(nil,t);m.j:CommitLayout()
  local work=assert(report.borderLast.work);hits=hits+(work.drawReuses or 0);setters=setters+work.fieldCalls
  if arg[2]~='--measure' then check((work.drawReuses or 0)>0,'unchanged joins inside changed regions reuse prepared native fields, even after unrelated intervening commits') end
  local r=reference.sources[index][1];r.rect[1]=t.rect[1];reference.j:Invalidate(nil,r);reference.j:CommitLayout()
  compare(m,reference,{{90,0},{630,0},{637,0},{1530,0},{1537,0},{2160,0}},scale)
  local usage={operations=0,fields=0,values=0}
  for _,cell in pairs(m.cells)do if cell.enabled and cell.drawUsage then for k,v in pairs(cell.drawUsage)do usage[k]=usage[k]+v end end end
  check(usage.operations<=m.j.limits.operations and usage.fields<=m.j.limits.junctionTriangles and usage.values<=m.j.limits.junctionTriangles*64,'retained and updated regions share original global draw-cache budgets')
 end
 for _,q in ipairs{m,reference}do q.sources[8][1]:SetVertexColor(.9,.2,.4,.45);q.sources[18][1]:Hide()end
 compare(m,reference,{{637,0},{1530,0}},scale)
 print(string.format('REGIONAL_DRAW style=%d scale=%.2f reused=%d setters=%d participantStrata=%d participantLevel=%d',style,scale,hits,setters,strataReads,levelReads))
end end
print('Regional sprite reuse: '..checks..' checks PASS;canonical art/retained indexes/native paint/context epochs/global budgets;native GPU/CPU/taint pending')
]]
assert(load(run,'@regional-sprite-work','t',_G))()
