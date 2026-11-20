-- Execute the production fallback compiler against its uncached numeric oracle.
-- Work counts describe desktop clipping/UV calls, never native FPS or pixels.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local source=read(arg[1]or'Core/BorderJunctions.lua')
local measure=arg[2]=='--measure'
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local exports=[[
local rawClip,rawUV,rawFallback=ClipField,UVPoint,FallbackTriangles
local work={clips=0,uv=0}
local absentCache={}
local running=false
ClipField=function(...)if running then work.clips=work.clips+1 end;return rawClip(...)end
UVPoint=function(...)if running then work.uv=work.uv+1 end;return rawUV(...)end
FallbackTriangles=function(...)running=true;local n=rawFallback(...);running=false;return n end
return {fallback=FallbackTriangles,source=Source,clip=rawClip,uv=rawUV,merge=MergeRectangleField,
 cache=function()return fallbackCompilePrevious or absentCache,fallbackCompileNext end,
 records=function()
  local records,seen={},{}
  local function visit(value)
   if seen[value]then return end;seen[value]=true
   if (value.guardSnapshot or value.inputs) and value.geometry then records[#records+1]=value
   else for _,child in pairs(value)do if type(child)=='table'then visit(child)end end end
  end
  visit(fallbackCompilePrevious or absentCache);return records
 end,
 begin=function()if J._BeginFallbackCompileGeneration then J:_BeginFallbackCompileGeneration()end end,
 publish=function(ops)active=ops;if J._PublishFallbackCompileCache then J:_PublishFallbackCompileCache()end end,
 work=function()return work.clips,work.uv end,reset=function()work.clips=0;work.uv=0 end,
 active=function()return active end}
]]
local function makeFixture(code)
 local text,n=prefix:gsub('assert%(load%(read%("Core/BorderJunctions.lua"%),"@Core/BorderJunctions.lua","t",e%)%)%("_FluxUI",{Border=B}%)',function()
  return'e.exports=assert(load('..string.format('%q',(code or source)..exports)..',"@fallback-cache-core","t",e))("_FluxUI",{Border=B})'
 end);assert(n==1)
 return assert(load(text..'\nreturn fixture','@fallback-cache-fixture','t',_G))()
end
local fixture=makeFixture()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function corrected(v,m)if not measure then check(v,m)end end
local function copy(a)local b={};for i,v in ipairs(a)do b[i]=v end;return b end
local function geometry(fields)
 local out={}
 for _,t in ipairs(fields or{})do
  local row={t.arm or 0};for _,p in ipairs{t.a,t.b,t.c}do for _,v in ipairs(p)do row[#row+1]=string.format('%.17g',v)end end
  if t.quad then for _,p in ipairs(t.quad)do for _,v in ipairs(p)do row[#row+1]=string.format('%.17g',v)end end end
  row[#row+1]=t.quadTail and 1 or 0;out[#out+1]=table.concat(row,',')
 end
 return table.concat(out,';')
end
-- R48's pure fallback geometry, using the same public clipping/UV primitives.
local function reference(x,op,t,cell)
 local r,bounds=op.rect,cell.rect;local w,h=r[3]-r[1],r[4]-r[2]
 local left,right=(bounds[1]-r[1])/w,(bounds[3]-r[1])/w
 local top,bottom=(r[4]-bounds[4])/h,(r[4]-bounds[2])/h
 local a,b,c=t.a,t.b,t.c
 if math.max(a[1],b[1],c[1])<left or math.min(a[1],b[1],c[1])>right
  or math.max(a[2],b[2],c[2])<top or math.min(a[2],b[2],c[2])>bottom then return{},false end
 local poly=x.clip({a,b,c},1,left,true)
 if #poly>0 then poly=x.clip(poly,1,right,false)end
 if #poly>0 then poly=x.clip(poly,2,top,true)end
 if #poly>0 then poly=x.clip(poly,2,bottom,false)end
 local item,paint=cell.plan.item,cell.plan.source;local points={}
 for _,p in ipairs(poly)do
  local px,py=r[1]+p[1]*w,r[4]-p[2]*h
  local u,v=x.uv(paint.uv,(px-item.rect[1])/(item.rect[3]-item.rect[1]),(item.rect[4]-py)/(item.rect[4]-item.rect[2]))
  points[#points+1]={p[1],p[2],u,v}
 end
 local out={}
 for i=2,#points-1 do
  local pa,pb,pc=points[1],points[i],points[i+1]
  if math.abs((pb[1]-pa[1])*(pc[2]-pa[2])-(pb[2]-pa[2])*(pc[1]-pa[1]))>1e-12 then
   out[#out+1]={arm=t.arm,a=pa,b=pb,c=pc,texture=item.texture,source=paint,fallbackBlockers=cell.blockers}
  end
 end
 return out,true
end
for _,style in ipairs{1,2}do
 local j,new,piece,_,_,_,choose,_,e=fixture();choose(style,'class');local x=e.exports
 local p=new(e.UIParent);p._FluxBorderStatic=true;p.unit='target'
 local t,record=piece(p,'Top',{-40,-8,80,16});t.cacheName='fallback'
 record.art='Interface\\AddOns\\_FluxUI\\Texture\\borders\\Battlefield100.tga'
 local base={arm=1,a={0,0,.1,.2},b={0,1,.1,.8},c={1,0,.9,.2}}
 local function build(change,hit,publish)
  local op={rect={-16,-16,16,16}}
  local cell={rect={-12,-10,12,12},blockers={{}},plan={item={rect={-40,-8,40,8},texture=t},source=assert(x.source(t))}}
  if change then change(op,base,cell)end
  local fresh,present=reference(x,op,base,cell)
  x.begin();x.reset();local count=x.fallback(op,base,cell)
  check(count==#fresh and geometry(op.fallbackTriangles)==geometry(fresh),'cached fallback geometry equals the exact uncached result')
  check((cell.aliasGroups~=nil)==present,'empty/disjoint alias-group behavior matches the uncached compiler')
  for _,field in ipairs(op.fallbackTriangles or{})do
   check(field.source==cell.plan.source and field.fallbackBlockers==cell.blockers and field.texture==cell.plan.item.texture,'every wrapper binds current paint, blockers and texture')
   check(cell.aliasGroups[op][1]~=nil,'aliases belong to the current operation')
  end
  corrected(j.stats.fallbackCompileHits==(hit and 1 or 0)and j.stats.fallbackCompileMisses==(hit and 0 or 1),'numeric structural inputs choose the expected hit/miss path')
  if hit then local clips,uv=x.work();corrected(clips==0 and uv==0,'a cache hit performs no polygon clipping or UV interpolation')end
  if publish~=false then x.publish({op})end
  return op,cell
 end
 local first,fc=build(nil,false);local second,sc=build(nil,true)
 corrected(type(first._fallbackGeometryTokens)=='table'and type(second._fallbackGeometryTokens)=='table'and first._fallbackGeometryTokens[1]==second._fallbackGeometryTokens[1],'warm geometry publishes a stable immutable token')
 check(first.fallbackTriangles[1]~=second.fallbackTriangles[1]and fc.plan.source~=sc.plan.source and fc.blockers~=sc.blockers,'paint, blockers and triangle wrappers are fresh')
 corrected(first.fallbackTriangles[1].a==second.fallbackTriangles[1].a,'warm wrappers share only immutable numeric vertices')
 t:SetTexture('replacement-material.tga');local path,pathCell=build(nil,true)
 check(path.fallbackTriangles[1].source.path=='replacement-material.tga','material validity is fresh and current path is rebound')
 t:SetVertexColor(.3,.7,.2,.4);local paint,paintCell=build(nil,true)
 check(paint.fallbackTriangles[1].source.color[1]==.3 and paintCell.plan.source.alpha==.4,'current public paint never comes from a cached source')
 local other=piece(p,'Top',{-40,-8,80,16})
 local function swapTexture(_,_,cell)cell.plan.item.texture=other;cell.plan.source=assert(x.source(other))end
 build(swapTexture,false);build(swapTexture,true);build(nil,false)
 local uv={t:GetTexCoord()};t:SetTexCoord(.1,.8,.2,.7);build(nil,false);build(nil,true)
 t:SetTexCoord(table.unpack(uv));build(nil,false);build(nil,true)
 for _,change in ipairs{
  function(o)o.rect[1]=o.rect[1]+.125 end,
  function(_,_,c)c.rect[1]=c.rect[1]+.125 end,
  function(_,_,c)c.plan.item.rect[1]=c.plan.item.rect[1]+.125 end,
  function(_,_,c)c.rect={100,100,110,110}end,
  function(_,_,c)c.rect={15,15,16,16}end,
 }do build(change,false);build(change,true);build(nil,false)end
 for _,index in ipairs{1,2,3,4}do
  local old=base.b[index];base.b[index]=old+.03125;build(nil,false);build(nil,true)
  base.b[index]=old;build(nil,false)
 end
 base.arm=2;build(nil,false);build(nil,true);base.arm=1;build(nil,false)
 local secret=setmetatable({}, {__eq=function()error('private alpha compared')end,__lt=function()error('private alpha ordered')end,__tostring=function()error('private alpha formatted')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 t:SetAlpha(secret);local private,pc=build(nil,true)
 check(rawequal(pc.plan.source.alpha,secret)and rawequal(private.fallbackTriangles[1].source.alpha,secret),'private alpha remains current paint and never enters the numeric cache')
 local getUV=t.GetTexCoord;t.GetTexCoord=function()return secret,0,1,1 end
 check(x.source(t)==nil,'private UV still rejects Source before a cache can be consulted');t.GetTexCoord=getUV
 local getPath=t.GetTexture;t.GetTexture=function()return secret end
 check(x.source(t)==nil,'private path still rejects Source before a cache can be consulted');t.GetTexture=getPath
 t.maskCountOverride=1;check(x.source(t)==nil,'foreign masks still reject Source before a cache can be consulted');t.maskCountOverride=nil
 e.issecretvalue=nil;t:SetAlpha(.4);build(nil,true)
 local before=x.cache();build(function(_,_,c)c.rect[2]=c.rect[2]+.25 end,false,false)
 check(x.cache()==before,'prepared records cannot replace the last committed cache')
 x.publish({});check(next(x.cache())==nil,'later-blocked operations do not publish fallback records')
 build(nil,false);j:ReleaseAll();corrected(next(x.cache())==nil,'rollback/release discards both compiled generations')
 build(nil,false)
 local oldLimit=j.limits.junctionTriangles;j.limits.junctionTriangles=0
 local budget=build(nil,true);corrected(budget._fallbackGeometryTokens==false,'cache budgets disable reuse eligibility without changing geometry');corrected(next(x.cache())==nil,'over-budget tokens never publish')
 j.limits.junctionTriangles=oldLimit;build(nil,false)
 for _,entry in ipairs(x.records())do
  check(entry.source==nil and entry.blockers==nil and entry.op==nil and entry.root==nil and entry.color==nil and entry.alpha==nil,'cache records retain no source, blockers, operations or paint')
  check(entry.texture==t,'only the stable texture handle is retained')
  for _,value in ipairs(entry.base)do check(type(value)=='number','the lookup identity retains only the immutable numeric base point')end
  if entry.guardSnapshot then
   local scalars=0
   for _,chunk in ipairs(entry.guardSnapshot.chunks)do
    scalars=scalars+#chunk
    for _,value in ipairs(chunk)do check(type(value)=='number','cache fingerprint values are public numeric snapshots')end
   end
   if entry.retainedValues then
    check(entry.inputs==nil and entry.retainedValues==2*scalars+9+#entry.geometry*12,
     'single guard snapshot keeps the historical cache charge')
   end
  else
   for _,value in ipairs(entry.inputs)do check(type(value)=='number','cache fingerprint values are public numeric snapshots')end
  end
  for _,tri in ipairs(entry.geometry)do for _,point in ipairs(tri)do for _,value in ipairs(point)do check(type(value)=='number','cached geometry is numeric only')end end end
 end
 -- MergeRectangleField mutates current wrappers only, including after a hit.
 local rectangle={base,{arm=1,a=base.c,b=base.b,c={1,1,.9,.8}}}
 local function merged()
  local o={rect={-16,-16,16,16}};local c={rect=copy(o.rect),blockers={},plan={item={rect=copy(o.rect),texture=t},source=assert(x.source(t))}}
  x.begin();for _,tri in ipairs(rectangle)do x.fallback(o,tri,c)end
  for _,field in ipairs(o.fallbackTriangles)do check(field.quad==nil and field.quadTail==nil,'cached numeric records never leak old merge flags')end
  x.merge(c.aliasGroups[o]);check(o.fallbackTriangles[1].quad and o.fallbackTriangles[2].quadTail,'fresh alias wrappers support current rectangle merging')
  x.publish({o});return o
 end
 local m1=merged();local m2=merged();check(geometry(m1.fallbackTriangles)==geometry(m2.fallbackTriangles),'warm fallback rectangle geometry matches cold merging exactly')
 -- Mixed generations retain the common small list and index only a large
 -- collision bucket when it is queried; every current wrapper stays fresh.
 local smallA,largeA={0,0,0,0},{0,0,0,0}
 local bs={{0,1,0,1},{.02,.98,0,1}};local cs={{1,0,1,0},{.98,.02,1,0}}
 local templates={}
 for v=1,4 do templates[#templates+1]={triangle={arm=1,a=smallA,b=bs[1],c=cs[1]},texture=t,rect={-12+v,-10,12,10}}end
 for _,b in ipairs(bs)do for _,c in ipairs(cs)do for _,texture in ipairs{t,other}do for v=1,2 do
  templates[#templates+1]={triangle={arm=1,a=largeA,b=b,c=c},texture=texture,rect={-12+v,-10,12,10}}
 end end end end
 local function mixed()
  x.begin();local ops,all={},{}
  for _,template in ipairs(templates)do
   local o={rect={-16,-16,16,16}}
   local cell={rect=template.rect,blockers={{}},plan={item={texture=template.texture,rect={-40,-8,40,8}},source=assert(x.source(template.texture))}}
   local expected=reference(x,o,template.triangle,cell);x.fallback(o,template.triangle,cell)
   check(geometry(o.fallbackTriangles)==geometry(expected),'mixed small/large bucket geometry equals a fresh compiler')
   for _,field in ipairs(o.fallbackTriangles or{})do
    check(field.source==cell.plan.source and field.fallbackBlockers==cell.blockers,'mixed bucket wrappers keep current source and blocker identities');all[#all+1]=field
   end
   ops[#ops+1]=o
  end
  return ops,geometry(all)
 end
 local coldOps,coldGeometry=mixed();x.publish(coldOps)
 local saved=x.cache()
 if j.stats.fallbackProbes~=nil then
  check(#saved[smallA]==4 and saved[smallA]._tuple==nil,'publication keeps a four-record bucket flat')
  check(#saved[largeA]==16 and saved[largeA]._tuple==nil,'publication allocates no large tuple index before a query')
 end
 local warmOps,warmGeometry=mixed();check(coldGeometry==warmGeometry,'mixed warm generation preserves exact numeric geometry')
 if j.stats.fallbackProbes~=nil then
  check(saved[smallA]._tuple==nil and saved[largeA]._tuple~=nil,'only the queried large bucket gains an index')
  check(j.stats.fallbackCompileHits==20 and j.stats.fallbackCompileMisses==0 and j.stats.fallbackProbes==34,'mixed lookup records the exact four-record and two-record leaf probes')
 end
 x.publish(warmOps)
 if j.stats.fallbackProbes~=nil then check(x.cache()[largeA]._tuple==nil,'the prior lazy index is not retained by a new committed generation')end
 bs[1][1]=bs[1][1]+.03125
 local changedOps,changedGeometry=mixed()
 check(changedGeometry~=warmGeometry,'in-place public base changes produce new numeric fallback geometry')
 check(j.stats.fallbackCompileHits==8 and j.stats.fallbackCompileMisses==12,'the full numeric guard rejects changed arrays even when their tuple identities match')
end
local function connected(code,style)
 local j,new,piece,flush,objects,_,choose,_,e=makeFixture(code)();choose(style,'class');local x=e.exports
 local p=new(e.UIParent);p._FluxBorderStatic=true;p.unit='player'
 local low=new(p);low.level=1;local high=new(p);high.level=20
 piece(low,'Top',{0,-9,1000,17}):SetVertexColor(.2,.4,.6,.7)
 piece(high,'Top',{0,-9,1000,17}):SetVertexColor(.8,.5,.1,1)
 local vertical={};for i=1,24 do vertical[i]=piece(p,'Left',{i*37-9,-40,16,80})end
 local function mesh()
  local rows={};for _,op in ipairs(x.active())do if op.fallbackTriangles then rows[#rows+1]=geometry(op.fallbackTriangles)end end;table.sort(rows);return table.concat(rows,';')
 end
 x.reset();flush();local first=mesh();local coldClip,coldUV=x.work()
 x.reset();j:Invalidate(true);flush();local warm=mesh();local warmClip,warmUV=x.work()
 if not code then corrected((j.stats.fallbackCompileHits or 0)>0 and (j.stats.fallbackCompileMisses or 0)==0,'actual warm duplicated-crossbar commit reuses every fallback record')end
 x.reset();vertical[7].rect[1]=vertical[7].rect[1]+5;j:Invalidate(nil,vertical[7]);flush()
 local moved=mesh();local moveClip,moveUV=x.work();local hits,misses=j.stats.fallbackCompileHits,j.stats.fallbackCompileMisses
 local m=getmetatable(e.UIParent).__index;local create=m.CreateTexture
 m.CreateTexture=function()error('fallback compile rollback failure',0)end
 piece(p,'Left',{970,-40,16,80});local ok,err=pcall(flush)
 check(not ok and tostring(err):find('fallback compile rollback failure',1,true),'a real render failure propagates after fallback preparation')
 corrected(next(x.cache())==nil,'failed commit publishes no prepared fallback cache and removes previous generation')
 m.CreateTexture=create;j:Invalidate(true);flush()
 return first,warm,moved,coldClip,coldUV,warmClip,warmUV,moveClip,moveUV,hits,misses
end
local disabled,n=source:gsub('local bucket=cacheable and fallbackCompilePrevious%[a%]','local bucket=nil')
if not measure then assert(n==1)end
for _,style in ipairs{1,2}do
 local first,warm,moved,cc,cu,wc,wu,mc,mu,hits,misses=connected(nil,style)
 if n==1 then
  local bf,bw,bm=connected(disabled,style)
  check(first==bf and warm==bw and moved==bm and first==warm,'cached cold/warm/local-change fallback meshes equal an uncached full commit exactly')
 end
 corrected(cc>0 and cu>0 and wc==0 and wu==0 and mc<cc and mu<cu and hits>0 and misses>0,'isolated change recompiles only the affected fallback numeric fields')
 print(string.format('FALLBACK_COMPILE_WORK|%d|cold=%d/%d|warm=%d/%d|move=%d/%d|hits=%s|misses=%s',style,cc,cu,wc,wu,mc,mu,tostring(hits),tostring(misses)))
end
print('Border fallback compile cache: '..checks..' checks PASS'..(measure and' (measurement)'or'')..'; numeric parity/current paint/blockers; source validity; merge isolation; committed-only bounded generations; native FPS/pixels/taint pending')
