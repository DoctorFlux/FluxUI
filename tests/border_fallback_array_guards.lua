-- Execute the actual fallback input guards; phase memoization never extends to
-- native source reads, paint, standalone callers, or a later layout generation.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local function replace(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(1,i-1)..b..s:sub(i+#a)end
local code=read(arg[1]or'Core/BorderJunctions.lua')
local prefix=assert(read('tests/border_fallback_compile_cache.lua'):match('^(.-)local fixture=makeFixture%(%)'))
prefix=replace(prefix,'return {fallback=FallbackTriangles,source=Source,clip=rawClip,uv=rawUV,merge=MergeRectangleField,',[[return {fallback=FallbackTriangles,source=Source,clip=rawClip,uv=rawUV,merge=MergeRectangleField,
 guard=FallbackInputs,matches=FallbackMatches,snapshot=FallbackSnapshot,
 phase=function(on)sourceReadPlan=on and {values={},reads=0,hits=0}or nil end,
 memo=function()return sourceReadPlan end,]])
local make=assert(load(prefix..'\nreturn makeFixture','@guard-proof-factory','t',_G))()
local checks=0
local function check(ok,m)checks=checks+1;assert(ok,m)end
for _,style in ipairs{1,2}do
 local j,new,piece,_,_,_,choose,_,e=make(code)();choose(style,'class');local x=e.exports
 local parent=new(e.UIParent);local texture=piece(parent,'Top',{-40,-8,80,16})
 local op={rect={-16,-16,16,16}}
 local t={arm=1,a={0,0,.1,.2},b={0,1,.1,.8},c={1,0,.9,.2}}
 local cell={rect={-12,-10,12,12},blockers={{}},plan={item={rect={-40,-8,40,8},texture=texture},source=assert(x.source(texture))}}
 local function flatExpected()
  local values={t.arm}
  for _,a in ipairs{t.a,t.b,t.c,op.rect,cell.rect,cell.plan.item.rect,cell.plan.source.uv}do
   values[#values+1]=#a;for _,v in ipairs(a)do values[#values+1]=v end
  end
  return values
 end
 x.phase(true)
 local guard=assert(x.guard(op,t,cell));local again=assert(x.guard(op,t,cell))
 for i=1,7 do check(guard[i]==again[i],'public current array validates once in its pure plan')end
 local saved,size=x.snapshot(guard);local expected=flatExpected()
 check(type(size)=='number' and size+8==#expected or type(size)=='table' and #size==#expected,
  'guard metadata accounts for the exact legacy budget size')
 local actual={saved.arm}
 for _,chunk in ipairs(saved.chunks)do actual[#actual+1]=#chunk;for _,v in ipairs(chunk)do actual[#actual+1]=v end end
 for i,v in ipairs(expected)do check(actual[i]==v,'snapshot preserves the complete numeric guard')end
 for i,raw in ipairs{t.a,t.b,t.c,op.rect,cell.rect,cell.plan.item.rect,cell.plan.source.uv}do
  check(saved.chunks[i]~=raw,'published chunk copies, rather than retains, the current mutable array')
 end
 local saved2=x.snapshot(again)
 for i=1,7 do check(saved.chunks[i]==saved2.chunks[i],'one pass shares only immutable copied chunks')end
 check(saved.source==nil and saved.op==nil and saved.state==nil and saved.arrays==nil,'snapshot retains no Source, operation, group or phase state')
 x.phase(false);check(x.memo()==nil,'phase cleanup owns all current validation maps')
 t.b[3]=t.b[3]+.03125
 local direct=assert(x.guard(op,t,cell));check(not x.matches(direct,saved),'outside a plan changed b is read fresh')
 t.b[3]=t.b[3]-.03125
 direct=assert(x.guard(op,t,cell));check(x.matches(direct,saved),'standalone guard recovers after current b restoration')
 local oldUV=cell.plan.source.uv[1];cell.plan.source.uv[1]=oldUV+.0625
 check(not x.matches(assert(x.guard(op,t,cell)),saved),'outside a plan changed UV is read fresh')
 cell.plan.source.uv[1]=oldUV
 x.phase(true);guard=assert(x.guard(op,t,cell));check(x.matches(guard,saved),'new plan validates current arrays against prior copied chunks')
 local adopted=x.snapshot(guard)
 for i=1,7 do check(adopted.chunks[i]==saved.chunks[i],'a matching prior immutable chunk is canonicalized without a fresh copy')end
 local alternate={arm=saved.arm,chunks={}}
 for i,c in ipairs(saved.chunks)do alternate.chunks[i]={};for k,v in ipairs(c)do alternate.chunks[i][k]=v end end
 alternate.chunks[1][1]=.03125
 check(not x.matches(guard,alternate),'a second distinct old chunk remains a complete guarded comparison')
 check(x.matches(guard,saved),'alternate lookup cannot poison the first matching chunk')
 check(not x.matches(guard,alternate),'negative pair result can be safely memoized within its pure plan')
 x.phase(false)
 local private=setmetatable({}, {__eq=function()error('opaque compared')end,__lt=function()error('opaque ordered')end,__tostring=function()error('opaque formatted')end})
 e.issecretvalue=function(v)return rawequal(v,private)end
 local previous=t.b[2];t.b[2]=private
 x.phase(true);check(x.guard(op,t,cell)==nil,'current opaque numeric value is rejected before comparison/copy')
 check(x.memo().fallbackGuard.valid[t.b]==false,'private numeric failure marker is confined to this plan')
 x.phase(false);t.b[2]=previous
 check(x.matches(assert(x.guard(op,t,cell)),saved),'private failure cannot leak into a later direct query')
 e.issecrettable=function(v)return rawequal(v,t.b)end
 x.phase(true);check(x.guard(op,t,cell)==nil,'restricted current table is rejected before indexing/copy')
 x.phase(false);e.issecrettable=nil
 e.canaccesstable=function(v)return not rawequal(v,t.b)end
 check(x.guard(op,t,cell)==nil,'inaccessible current table is rejected before indexing/copy')
 e.canaccesstable=nil
 x.phase(true);check(x.matches(assert(x.guard(op,t,cell)),saved),'public table recovery works in a new plan')
 x.phase(false)
 local rawA=t.a;t.a=nil
 check(x.guard(op,t,cell)==nil,'missing current array is rejected')
 t.a=rawA
 local rawB=t.b;t.b={0,nil,.1,.8}
 check(x.guard(op,t,cell)==nil,'missing current scalar is rejected before copying')
 t.b={0,'1',.1,.8}
 check(x.guard(op,t,cell)==nil,'nonnumeric current scalar is rejected before comparison')
 t.b=private
 check(x.guard(op,t,cell)==nil,'whole opaque current array is rejected before indexing')
 t.b=rawB
 local standalone=assert(x.guard(op,t,cell));local standaloneValue=t.b[2]
 t.b[2]=standaloneValue+.125
 local standaloneSnapshot=x.snapshot(standalone)
 check(standaloneSnapshot.chunks[2][2]==standaloneValue,'standalone snapshot owns the values copied at validation time')
 t.b[2]=standaloneValue
 local oldChunk=saved.chunks[2][2];t.b[2]=previous+.125
 check(saved.chunks[2][2]==oldChunk,'later native/layout changes cannot mutate a committed numeric snapshot')
 x.phase(true);check(not x.matches(assert(x.guard(op,t,cell)),saved),'a next-pass layout change invalidates the matching record')
 x.phase(false)
end
for _,style in ipairs{1,2}do
 local j,new,piece,_,_,_,choose,_,e=make(code)();choose(style,'class');local x=e.exports
 local p=new(e.UIParent);local texture=piece(p,'Top',{-40,-8,80,16})
 local triangle={arm=1,a={0,0,.1,.2},b={0,1,.1,.8},c={1,0,.9,.2}}
 local function build()
  local op={rect={-16,-16,16,16}}
  local cell={rect={-16,-16,16,16},blockers={{}},plan={item={rect={-40,-8,40,8},texture=texture},source=assert(x.source(texture))}}
  x.begin();local n=x.fallback(op,triangle,cell)
  local geometry={}
  for _,field in ipairs(op.fallbackTriangles or{})do
   for _,vertex in ipairs{field.a,field.b,field.c}do for _,value in ipairs(vertex)do geometry[#geometry+1]=string.format('%.17g',value)end end
   check(field.source==cell.plan.source and field.fallbackBlockers==cell.blockers,'low cache budget retains fresh current drawing owners')
  end
  return op,n,table.concat(geometry,',')
 end
 local first,n,mesh=build();check(n==1 and first._fallbackGeometryTokens~=false,'one triangle fits the normal compile budget')
 x.publish({first});check(#x.records()==1,'normal completed generation publishes its numeric record')
 local old=j.limits.junctionTriangles;j.limits.junctionTriangles=1
 local small,smallN,smallMesh=build()
 check(smallN==1 and smallMesh==mesh,'one-triangle low metadata budget preserves exact visible drawing')
 check(small._fallbackGeometryTokens==false,'the conservative metadata charge exhausts the 64-scalar budget')
 local _,generation=x.cache();check(generation.values==0,'rejected record never exceeds the retained scalar budget')
 x.publish({small});check(next(x.cache())==nil,'rejected generation cannot retain a stale previously committed record')
 j.limits.junctionTriangles=old
 local recovered,recoveredN,recoveredMesh=build()
 check(recoveredN==1 and recoveredMesh==mesh and j.stats.fallbackCompileMisses==1,'metadata budget recovery recompiles exact fresh drawing')
 x.publish({recovered});check(#x.records()==1,'recovery publishes a fresh bounded record')
end
local measured=replace(code,'local function PublicNumber(v)',[[local function PublicNumber(v)
 if _G.guardCounting then _G.guardWork.validations=_G.guardWork.validations+1 end]])
measured=replace(measured,'local function FallbackInputs(op,triangle,cell)',[[local function FallbackInputs(op,triangle,cell)
 _G.guardCounting=true;_G.guardWork.calls=_G.guardWork.calls+1]])
measured=replace(measured,'    arrays.arm=arm;arrays.state=state;return arrays',
 '    _G.guardCounting=false;arrays.arm=arm;arrays.state=state;return arrays')
measured=replace(measured,'local function FallbackSnapshot(inputs)',[[local function FallbackSnapshot(inputs)
 _G.guardWork.fingerprints=_G.guardWork.fingerprints+1]])
local function mesh(objects)
 local rows={}
 for _,t in ipairs(objects)do if t.decorative and t.shown and t.size then
  local values={t.path,t.alpha,t.parent:GetFrameStrata(),t.parent:GetFrameLevel()}
  for _,v in ipairs(t.uv)do values[#values+1]=v end
  for _,v in ipairs(t.size)do values[#values+1]=v end
  for _,v in ipairs(t.color)do values[#values+1]=v end
  for _,v in ipairs(t.point or{})do if type(v)~='table'then values[#values+1]=v end end
  for i=1,4 do for _,v in ipairs(t.vertices and t.vertices[i]or{})do values[#values+1]=v end end
  for i,v in ipairs(values)do if type(v)=='number'then values[i]=string.format('%.17g',v)end end
  rows[#rows+1]=table.concat(values,',')
 end end
 table.sort(rows);return table.concat(rows,';')
end
for _,style in ipairs{1,2}do for _,count in ipairs{24,56}do
 local j,new,piece,flush,objects,_,choose,_,e=make(measured)();choose(style,'class');local x=e.exports
 local p=new(e.UIParent);p._FluxBorderStatic=true;p.unit='player'
 local low,high=new(p),new(p);low.level=1;high.level=20
 local dividers={}
 if count==24 then
  piece(low,'Top',{0,-9,1000,17});piece(high,'Top',{0,-9,1000,17})
  for i=1,count do dividers[#dividers+1]=piece(p,'Left',{i*37-9,-40,16,80})end
 else
  for section=0,7 do
   piece(low,'Top',{section*280,-9,300,17});piece(high,'Top',{section*280,-9,300,17})
   for k=1,7 do dividers[#dividers+1]=piece(p,'Left',{section*280+k*37-9,-40,16,80})end
  end
 end
 local function reset()e.guardWork={validations=0,fingerprints=0,calls=0}end
 reset();flush();check(not j.stats.fallback and e.guardWork.fingerprints>0,'actual cold plan creates bounded miss fingerprints')
 local expected=#x.records()
 check(expected>0 and j.stats.fallbackCompileMisses==expected,'the cold graph publishes every current fallback record, including rectangular shadow fields')
 local first=mesh(objects)
 reset();j:Invalidate(true);flush();local w=e.guardWork
 local guardedCalls=j.stats.fallbackPlanHits==count and 0 or expected
 check(w.calls==guardedCalls and j.stats.fallbackCompileHits==expected and j.stats.fallbackCompileMisses==0,'actual connected warm graph reuses every fallback record through full-op or array guards')
 check(w.fingerprints==0,'a warm plan reuses validated snapshots')
 check(w.validations<(count==24 and 4752 or 11088)*.3,'current public numeric validation falls below30% of the flat baseline')
 check(mesh(objects)==first,'unchanged current plan preserves exact full drawing, layers, geometry, UV, paint and visibility')
 check(x.memo()==nil,'successful actual commit releases the complete current array plan')
 for _,r in ipairs(x.records())do
  check(r.guardSnapshot.state==nil and r.guardSnapshot.source==nil,'published records cannot retain validation state or source paint')
  for _,chunk in ipairs(r.guardSnapshot.chunks)do for _,v in ipairs(chunk)do check(type(v)=='number','committed snapshot chunks contain only copied public numbers')end end
 end
 reset();dividers[7].rect[1]=dividers[7].rect[1]+.125;j:Invalidate(nil,dividers[7]);flush()
 local moved=mesh(objects)
 check(moved~=first and j.stats.fallbackCompileMisses>0,'a following generation observes a genuine current layout change')
 check(e.guardWork.fingerprints==j.stats.fallbackCompileMisses,'only actual misses construct new guard snapshots')
 reset();j:Invalidate(true);flush()
 check(mesh(objects)==moved and e.guardWork.fingerprints==0,'changed layout becomes a stable exact warm mesh')
 local source=dividers[1];local get=source.GetTexture
 source.GetTexture=function()error('array-guard source failure',0)end
 j:Invalidate(true);local ok,err=pcall(flush)
 check(not ok and tostring(err):find('array-guard source failure',1,true),'actual pure-plan error propagates')
 check(x.memo()==nil,'actual planning exception releases current arrays and pair memos')
 source.GetTexture=get;j:Invalidate(true);flush()
 for _,budget in ipairs{'junctionTriangles','fragments'}do
  local old=j.limits[budget];j.limits[budget]=1;j:Invalidate(true);flush()
  check(x.memo()==nil and j.stats.fallback~=nil,'budget exit discards phase array guards: '..budget)
  j.limits[budget]=old;j:Invalidate(true);flush()
  check(x.memo()==nil and not j.stats.fallback,'budget recovery starts with fresh current validation: '..budget)
 end
 print(string.format('FALLBACK_ARRAY_WORK style=%d junctions=%d calls=%d validations=%d warmFingerprints=%d',style,count,w.calls,w.validations,w.fingerprints))
end end
print('Border fallback array guards: '..checks..' checks PASS; public-only immutable snapshots; plan-only positive/negative pairs; direct mutations; private/current recovery; exact legacy fingerprints')
