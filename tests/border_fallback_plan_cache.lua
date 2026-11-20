-- Actual current renderer against its full-op reuse-disabled numeric oracle.
-- Desktop geometry/native-work models do not certify native FPS, pixels or taint.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local function replace(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(1,i-1)..b..s:sub(i+#a)end
local measureClip=arg[2]=='--clip-reject'
local source=read((not measureClip and arg[1])or'Core/BorderJunctions.lua'):gsub('\r\n','\n')
local original,n=source:gsub('local base=sourceReadPlan and op%._branchCompileCandidate','local base=nil',1)
assert(n==1,'actual full-op fallback planning helper must be present')
local prefix=assert(read('tests/border_fallback_compile_cache.lua'):match('^(.-)local fixture=makeFixture%(%)'))
prefix=replace(prefix,'return {fallback=FallbackTriangles,source=Source,clip=rawClip,uv=rawUV,merge=MergeRectangleField,',
 'return {fallback=FallbackTriangles,source=Source,clip=rawClip,uv=rawUV,merge=MergeRectangleField,stage=StageFallback,intersects=Intersects,planInputs=FallbackPlanInputs,planCache=function()return fallbackPlanPrevious or{} end,alternate=function()return branchCompileAlternate,fallbackPlanAlternate end,')
local make=assert(load(prefix..'\nreturn makeFixture','@local-plan-factory','t',_G))()
local candidate=source
local function makeScene(reuse,style,count,measure,archive)
 local core=archive or (reuse and candidate or original)
 if not measure then
 local count
 core,count=core:gsub('(local function FallbackTriangles%([^\n]+%)\n)','%1 _G.planWork.fallbacks=_G.planWork.fallbacks+1\n',1)
 assert(count==1,'instrument the fallback compiler entry')
 core=replace(core,'local function FallbackInputs(op,triangle,cell)',[[local function FallbackInputs(op,triangle,cell)
 _G.planWork.inputGuards=_G.planWork.inputGuards+1]])
 core=replace(core,'local function MergeRectangleField(group)',[[local function MergeRectangleField(group)
 if _G.planWork then _G.planWork.merges=_G.planWork.merges+1 end]])
 core=replace(core,'function J:Subtract(rectangles,cut)',[[function J:Subtract(rectangles,cut)
 _G.planWork.subtracts=_G.planWork.subtracts+1]])
 core=replace(core,'local function ReadSource(texture)',[[local function ReadSource(texture)
 _G.planWork.sources=_G.planWork.sources+1]])
 end
 local j,new,piece,flush,objects,_,choose,_,e=make(core)();choose(style,'class');local x=e.exports
 local previous={};local pending={};local retained=0
 local function reset()e.planWork={fallbacks=0,inputGuards=0,merges=0,subtracts=0,sources=0,hits=0,misses=0,retained=retained}end
 reset()
 local p=new(e.UIParent);p._FluxBorderStatic=true;p.unit='player'
 local low,high=new(p),new(p);low.level=1;high.level=20
 local dividers,textures={},{}
 local function edge(parent,k,r)local t=piece(parent,k,r);textures[#textures+1]=t;return t end
 if count==24 then
  edge(low,'Top',{0,-9,1000,17}):SetVertexColor(.2,.4,.6,.7)
  edge(high,'Top',{0,-9,1000,17}):SetVertexColor(.8,.5,.1,1)
  for i=1,count do dividers[#dividers+1]=edge(p,'Left',{i*37-9,-40,16,80})end
 else
  for section=0,7 do
   edge(low,'Top',{section*280,-9,300,17}):SetVertexColor(.2,.4,.6,.7)
   edge(high,'Top',{section*280,-9,300,17}):SetVertexColor(.8,.5,.1,1)
   for k=1,7 do dividers[#dividers+1]=edge(p,'Left',{section*280+k*37-9,-40,16,80})end
  end
 end
 local function drawing()
  local rows={}
  for _,t in ipairs(objects)do if t.decorative and t.shown and t.size then
   local values={t.path,t.alpha,t.parent:GetFrameStrata(),t.parent:GetFrameLevel()}
   for _,v in ipairs(t.uv)do values[#values+1]=v end
   for _,v in ipairs(t.size)do values[#values+1]=v end
   for _,v in ipairs(t.color)do values[#values+1]=v end
   for _,v in ipairs(t.point or{})do if type(v)~='table'then values[#values+1]=v end end
   for i=1,4 do for _,v in ipairs(t.vertices and t.vertices[i]or{})do values[#values+1]=v end end
   for i,v in ipairs(values)do
    if e.issecretvalue and e.issecretvalue(v)then values[i]='opaque'
    elseif type(v)=='number'then values[i]=string.format('%.17g',v)end
   end
   rows[#rows+1]=table.concat(values,',')
  end end
  table.sort(rows);return table.concat(rows,';'),#rows
 end
 return {j=j,e=e,x=x,flush=flush,reset=reset,drawing=drawing,dividers=dividers,textures=textures,piece=piece,parent=p,
  cache=function()return x.planCache()end,pending=function()return{}end}
end
if arg[2]=='--export'then return makeScene end
local checks=0;local function check(ok,m)checks=checks+1;assert(ok,m)end
if measureClip then
 local archive=read(assert(arg[1])):gsub('\r\n','\n')
 for _,style in ipairs{1,2}do for _,count in ipairs{24,56}do
  local a,b=makeScene(true,style,count,false,archive),makeScene(true,style,count,false)
  for step=1,2 do
   for _,m in ipairs{a,b}do
    m.reset()
    if step==2 then
     for index=7,20 do
      local t=m.dividers[index];t.rect[1]=t.rect[1]+3;m.j:Invalidate(nil,t)
     end
    end
    m.flush()
    check(not m.j.stats.fallback,'compiled junctions remain within budget')
   end
   check(a.drawing()==b.drawing(),'exact archived drawing at new geometry')
   local before,after=a.e.planWork,b.e.planWork
   check(after.inputGuards<=before.inputGuards,'fallback guard work stays bounded')
   print(('FALLBACK_CLIP|%d|%d|%d|%d|%d|%d|%d'):format(style,count,step,before.inputGuards,after.inputGuards,
    before.fallbacks,after.fallbacks))
  end
  for _,m in ipairs{a,b}do
   m.textures[2]:Hide()
   m.flush()
  end
  check(a.drawing()==b.drawing(),'original overlapping backup still appears')
 end end
 print('Fallback clip archive replay: '..checks..' checks PASS.')
 return
end
do
 local _,_,_,_,_,_,_,_,env=make(source)()
 local inputs=env.exports.planInputs
 local a,b,root,backup={},{},{},{}
 local op={root=root,rect={0,0,8,8},triangles={{texture=a},{texture=b},{texture=a}}}
 local function Cell(rect)
  return {rect=rect,blockers={a},plan={root=root,item={texture=backup,rect=rect},source={uv={0,1,0,1}}}}
 end
 local inside,outside=Cell({4,2,6,4}),Cell({9,9,12,12})
 local byOwner={[a]={inside},[b]={outside}}
 check(inputs(op,{}, {},nil,true)==nil,'empty fallback owners create no contexts or key')
 local contexts,byTexture,bindings,key=inputs(op,{},byOwner,nil,true)
 check(#contexts==1 and contexts[1]==inside and byTexture[b]==false and bindings[inside.blockers][backup]==1,
  'only contributing owners allocate cell lists and key inputs, in triangle order')
 local lists,_,uncachedBindings,uncachedKey=inputs(op,{},byOwner,nil,false)
 check(#lists==1 and lists[1]==inside and not uncachedBindings and not uncachedKey,
  'the uncached compiler keeps the same context without preparing a cache key')
 local second=Cell({1,1,2,2})
 local changed,_,newBindings,newKey=inputs(op,{},byOwner,{[b]={second}},true)
 check(#changed==2 and changed[2]==second and newBindings[second.blockers][backup]==2 and #newKey>#key,
  'an owner that gains a fallback invalidates the old key and gets a stable context index')
 check(inputs(op,{[root]=true},byOwner,nil,true)==nil,'blocked cells contribute no contexts')
end
for _,style in ipairs{1,2}do for _,count in ipairs{24,56}do
 local oracle=makeScene(false,style,count);local cached=makeScene(true,style,count)
 local function step(label,change)
  for _,s in ipairs{oracle,cached}do s.reset();if change then change(s)end;s.flush();check(not s.j.stats.fallback or label=='masked'or label=='private-uv','ordinary fixture remains within existing budgets')end
  check(oracle.drawing()==cached.drawing(),'exact current full drawing matches uncached op-plan oracle: '..label)
  local a,b=oracle.e.planWork,cached.e.planWork;b.hits=cached.j.stats.fallbackPlanHits or 0;b.misses=cached.j.stats.fallbackPlanMisses or 0
  print(string.format('LOCAL_PLAN style=%d nodes=%d case=%s fields=%d baselineFallbacks=%d candidateFallbacks=%d baseGuards=%d candidateGuards=%d merges=%d/%d sourceReads=%d/%d subtracts=%d/%d hits=%d misses=%d',
   style,count,label,select(2,cached.drawing()),a.fallbacks,b.fallbacks,a.inputGuards,b.inputGuards,a.merges,b.merges,a.sources,b.sources,a.subtracts,b.subtracts,b.hits,b.misses))
 end
 step('cold')
 step('warm',function(s)s.j:Invalidate(true)end)
 step('one-split',function(s)local t=s.dividers[7];t.rect[1]=t.rect[1]+.125;s.j:Invalidate(nil,t)end)
 step('warm-move',function(s)s.j:Invalidate(true)end)
 local function move(s,offset)
  for i=7,20 do local t=s.dividers[i];t.rect[1]=t.rect[1]+offset;s.j:Invalidate(nil,t) end
 end
 step('second-layout',function(s)move(s,3)end)
 step('return-first-layout',function(s)move(s,-3)end)
 local branch,alternate=cached.x.alternate()
 if branch then
  check(cached.j.stats.compileMisses==0 and cached.j.stats.fallbackPlanMisses==0,
   'return to the previous accepted geometry reuses every exact base and fallback plan')
  local branches,plans,tokens=0,0,0
  for _ in pairs(branch) do branches=branches+1 end
  for _,record in pairs(alternate) do plans=plans+1;tokens=tokens+#record.tokens end
  check(branches>0 and branches<=64 and plans>0 and plans<=64 and tokens<=1024,
   'alternate planning storage is bounded and retains the displaced layout')
 end
 step('live-color',function(s)s.textures[1]:SetVertexColor(.4,.1,.8,.3);s.j:Invalidate(true)end)
 step('material',function(s)s.textures[1]:SetTexture('fresh-source.tga');s.j:Invalidate(true)end)
 step('priority',function(s)s.textures[1]:GetParent().level=100;s.j:Invalidate(true)end)
 step('uv',function(s)s.textures[1]:SetTexCoord(.15,.8,.2,.75);s.j:Invalidate(true)end)
 step('masked',function(s)s.textures[1].maskCountOverride=1;s.j:Invalidate(true)end)
 step('unmask',function(s)s.textures[1].maskCountOverride=nil;s.j:Invalidate(true)end)
 local private=setmetatable({}, {__eq=function()error('opaque compared')end,__lt=function()error('opaque ordered')end,__tostring=function()error('opaque formatted')end})
 step('private-uv',function(s)s.e.issecretvalue=function(v)return rawequal(v,private)end;s.textures[1].GetTexCoord=function()return private,0,1,1 end;s.j:Invalidate(true)end)
 step('public-recovery',function(s)s.textures[1].GetTexCoord=nil;s.j:Invalidate(true)end)
 step('private-alpha',function(s)s.textures[1]:SetAlpha(private);s.j:Invalidate(true)end)
 for _,record in pairs(cached.cache())do
  check(record.source==nil and record.op==nil and record.group==nil and record.root==nil,'numeric op record retains no Source, root or transient operation')
  for _,v in ipairs(record.inputs)do check(not rawequal(v,private),'private alpha never enters the op input descriptor')end
  for _,field in ipairs(record.fields)do check(field.source==nil and field.fallbackBlockers==nil,'compiled field snapshots retain no old paint/blocker wrappers')end
 end
 step('public-alpha',function(s)s.textures[1]:SetAlpha(.45);s.j:Invalidate(true)end)
 for _,s in ipairs{oracle,cached}do s.j:ReleaseFor(s.textures[1])end
 check(oracle.drawing()==cached.drawing(),'partial component release restores the same exact source/field visibility')
 step('release-recovery',function(s)s.j:Invalidate(true)end)
 for _,s in ipairs{oracle,cached}do
  local m=getmetatable(s.e.UIParent).__index;local create=m.CreateTexture
  m.CreateTexture=function()error('local-plan allocation failure',0)end
  s.piece(s.parent,'Left',{965,-40,16,80})
  local ok,err=pcall(s.flush)
  check(not ok and tostring(err):find('local-plan allocation failure',1,true),'actual allocation failure propagates through unchanged transactional rendering')
  check(next(s.cache())==nil and next(s.pending())==nil,'failed commit publishes no partial or previous full-op plan')
  local oldBranches,oldPlans=s.x.alternate()
  check(not oldBranches or next(oldBranches)==nil and next(oldPlans)==nil,'failed commit clears alternates')
  m.CreateTexture=create;s.j:Invalidate(true);s.flush()
 end
 check(oracle.drawing()==cached.drawing(),'native allocation recovery produces exact current drawing')
 local retainedValues,retainedFields,retainedOperations=0,0,0
 for _,record in pairs(cached.cache())do
  retainedValues=retainedValues+record.values;retainedFields=retainedFields+#record.fields;retainedOperations=retainedOperations+1
  local charged=#record.inputs
  for _,field in ipairs(record.fields)do charged=charged+15+(field.quad and 16 or 0)end
  check(record.values>=charged,'retained vertex/UV, arm/context/quadTail and quad metadata is conservatively charged')
 end
 check(retainedValues<=cached.j.limits.junctionTriangles*64 and retainedFields<=cached.j.limits.junctionTriangles
  and retainedOperations<=cached.j.limits.operations,'actual committed numerical plans obey all retention bounds')
 for _,s in ipairs{oracle,cached}do
  local old=s.j.limits.junctionTriangles;s.j.limits.junctionTriangles=1;s.j:Invalidate(true);s.flush()
  check(s.j.stats.fallback~=nil,'existing global triangle budget rejects overlarge plan')
  check(next(s.cache())==nil,'budget rollback retains no full-op numerical generation')
  s.j.limits.junctionTriangles=old;s.j:Invalidate(true);s.flush()
 end
 check(oracle.drawing()==cached.drawing(),'budget recovery reproduces exact full drawing')
 for _,s in ipairs{oracle,cached}do
  s.j:Forget(s.dividers[7]);s.reset();s.flush()
  local oldBranches,oldPlans=s.x.alternate()
  check(not oldBranches or next(oldBranches)==nil and next(oldPlans)==nil,
   'forgetting a source discards alternate geometry through the next publication')
 end
 check(oracle.drawing()==cached.drawing(),'forgetting a source preserves the exact current drawing')
end end
print('Border fallback plan cache: '..checks..' checks PASS; current native geometry/source validation; immutable public plan metadata; current paint/priority/opaque alpha; release/rollback/budgets; native latency pending')
