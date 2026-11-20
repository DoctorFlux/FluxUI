-- Actual base compiler and global solve/commit. Cached geometry must match a
-- fresh compile exactly; no native FPS, taint or pixel certification.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local source=read(arg[1]or'Core/BorderJunctions.lua')
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local exported=source..[[
return {compile=CompileBranchFields,cache=function()return branchCompilePrevious,branchCompileNext end,
 alternate=function()return branchCompileAlternate end,
 begin=function()branchCompileNext={operations=0,triangles=0,values=0};J.stats.compileHits=0;J.stats.compileMisses=0 end,
 publish=function(ops)active=ops;J:_PublishBranchCompileCache()end,active=function()return active end}
]]
local text,n=prefix:gsub('assert%(load%(read%("Core/BorderJunctions.lua"%),"@Core/BorderJunctions.lua","t",e%)%)%("_FluxUI",{Border=B}%)',function()
 return 'e.exports=assert(load('..string.format('%q',exported)..',"@branch-cache-core","t",e))("_FluxUI",{Border=B})'
end);assert(n==1)
local fixture=assert(load(text..'\nreturn fixture','@branch-cache-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function digest(triangles,paint)
 local rows={}
 for _,t in ipairs(triangles or{})do
  local a={t.arm or 0,t.texture and t.texture.cacheName or'-',t.source.path,t.source.gutter or false,t.quadTail or false,t.roundFill or false}
  for _,p in ipairs{t.a,t.b,t.c}do for _,v in ipairs(p)do a[#a+1]=v end end
  if t.quad then for _,p in ipairs(t.quad)do for _,v in ipairs(p)do a[#a+1]=v end end end
  if paint then for _,v in ipairs(t.source.color)do a[#a+1]=v end;a[#a+1]=t.source.alpha end
  for i,v in ipairs(a)do a[i]=type(v)=='number'and string.format('%.17g',v)or tostring(v)end
  rows[#rows+1]=table.concat(a,',')
 end
 return table.concat(rows,';')
end
for _,style in ipairs{1,2}do
 local j,new,piece,_,_,_,choose,_,e=fixture();choose(style,'class')
 local p=new(e.UIParent);p._FluxBorderStatic=true;p.unit='target'
 local g={parent=p,id=1,paintID=1,priority=1,unitOwner='target'}
 local function make(key,name,r)
  local t,record=piece(p,key,r);t.cacheName=name
  record.art='Interface\\AddOns\\_FluxUI\\Texture\\borders\\'..(style==1 and'Battlefield100.tga'or'ForeverMetal150.tga')
  return t,record
 end
 local h,hr=make('Top','h',{-50,-9,100,17});local v,vr=make('Left','v',{-9,-50,16,100})
 local remote,rr=make('Top','remote',{-60,-9,120,17});local cap=make('TL','cap',{-16,-16,8,8})
 local function op()
  local a={texture=h,paintID=hr.junctionID,group=g,axis='H',side='Top',rect={-50,-9,50,8},a=-50,b=50,p=0,rawP=0,scale=1,paintCuts={}}
  local b={texture=v,paintID=vr.junctionID,group=g,axis='V',side='Left',rect={-9,-50,7,50},a=-50,b=50,p=0,rawP=0,scale=1,paintCuts={}}
  return {hs=a,vs=b,segments={[a]=true,[b]=true},members={[g]=true},bits=15,x=0,y=0,rect={-16,-16,16,16},fullRect={-16,-16,16,16},protectedRects={},roundCaps={}},a,b
 end
 local function build(change,expectHit,publish)
  local o,a,b=op();if change then change(o,a,b)end
  e.exports.begin();local result,why=e.exports.compile(j,o,{[1]=a,[2]=a,[3]=b,[4]=b})
  if not result then return nil,why,o end
  local fresh,freshWhy=j:BranchTriangles(o,{[1]=a,[2]=a,[3]=b,[4]=b})
  check(fresh and not freshWhy and digest(result,true)==digest(fresh,true),'cached fields equal a fresh compile with current paint descriptors')
  check(j.stats.compileHits==(expectHit and 1 or 0)and j.stats.compileMisses==(expectHit and 0 or 1),'exact semantic input changes choose the expected compile path')
  if publish~=false then e.exports.publish({o})end
  return result,nil,o
 end
 local first=assert(build(nil,false));local second=assert(build(nil,true))
 check(first[1].a==second[1].a and first[1].source~=second[1].source,'hits share immutable points but bind a fresh source table')
 h:SetTexture('current-material.tga');local material=assert(build(nil,true))
 check(material[1].source.path=='current-material.tga'or material[#material].source.path=='current-material.tga','material-only change uses current source path without recompiling unchanged UV geometry')
 h:SetVertexColor(.8,.2,.1,.4);local painted=assert(build(nil,true))
 local saw=false;for _,t in ipairs(painted)do if t.texture==h then saw=true;check(t.source.color[1]==.8 and t.source.alpha==.4,'class/debuff paint comes from the current pass, never cached RGBA')end end;check(saw,'horizontal source represented')
 local retainsAlternates=e.exports.alternate()~=nil
 local uv={h:GetTexCoord()};h:SetTexCoord(.1,.2,.3,.4);assert(build(nil,false));h:SetTexCoord(table.unpack(uv));assert(build(nil,retainsAlternates))
 local art=hr.art;hr.art=nil;assert(build(nil,false));hr.art=art;assert(build(nil,retainsAlternates))
 local variants={
  function(o)o.rect[1]=o.rect[1]+.125 end,
  function(_,a)a.rect[3]=a.rect[3]+.25 end,
  function(o)o.protectedRects={{-16,-16,-11,-11}}end,
  function(o,_,b)o.roundCaps={{item={texture=cap,rect={-8,-18,0,-8}},segment=b}}end,
  function(o)o.bits=11;p._FluxBorderAuraPanel=true end,
 }
 for index,change in ipairs(variants)do
  assert(build(change,false));assert(build(change,true));p._FluxBorderAuraPanel=nil
  assert(build(nil,retainsAlternates and index<#variants))
 end
 local function ownership(o,a)
  local owner={texture=remote,paintID=rr.junctionID,group=g,axis='H',side='Top',rect={-60,-9,60,8},a=-60,b=60,p=0,rawP=0,scale=1,paintCuts={}}
  a.paintCuts={{a=-16,b=16,owner=owner}}
 end
 assert(build(ownership,false));assert(build(ownership,true))
 remote:SetTexCoord(.2,.4,.1,.6);assert(build(ownership,false));assert(build(ownership,true))
 remote:SetVertexColor(.2,.7,.1,.8);assert(build(ownership,true))
 -- A remote PaintOwner is not in op.segments. Its mask/private validity must
 -- still be checked before a geometry hit can be returned.
 remote.maskCountOverride=1;local value,why=build(ownership,false)
 check(not value and why=='unavailable branch source','remote masked source cannot use a previous compiled result')
 remote.maskCountOverride=nil;remote.GetNumMaskTextures=function()return 0 end
 local secret=setmetatable({}, {__eq=function()error('private compared')end,__tostring=function()error('private formatted')end})
 e.issecretvalue=function(x)return rawequal(x,secret)end
 local get=remote.GetTexture;remote.GetTexture=function()return secret end
 value,why=build(ownership,false);check(not value and why=='unavailable branch source','remote private source cannot use cached geometry')
 remote.GetTexture=get;e.issecretvalue=nil;assert(build(ownership,true))
 -- Prepared fields in a component blocked later in planning are not committed.
 local _,_,prepared=build(nil,false,false);check(prepared._branchCompileCandidate~=nil,'valid base fields are prepared before the commit')
 e.exports.publish({});check(next(e.exports.cache())==nil,'later-blocked operations never publish a compile cache entry')
 assert(build(nil,false));j:ReleaseAll();check(next(e.exports.cache())==nil,'release/rollback removes every compiled generation')
 assert(build(nil,false))
 local previous=e.exports.cache()
 for _,entry in pairs(previous)do
  check(entry.source==nil and entry.root==nil and entry.color==nil and entry.alpha==nil,'cache record has no old source, paint or connected component')
  for _,t in ipairs(entry.geometry)do
   check(t.source==nil and t.alpha==nil and t.color==nil,'compiled geometry contains no old source paint')
   for _,point in ipairs{t.a,t.b,t.c}do for _,n in ipairs(point)do check(type(n)=='number','cached point/UV coordinates are numeric only')end end
  end
 end
end
-- One connected crossbar reproduces the actual locality problem: changing a
-- single separator must not recompile all the unrelated base junction fields.
local function connected(code,style)
 local exportCode=exported
 if code then exportCode=code..exported:sub(#source+1)end
 local text,n=prefix:gsub('assert%(load%(read%("Core/BorderJunctions.lua"%),"@Core/BorderJunctions.lua","t",e%)%)%("_FluxUI",{Border=B}%)',function()return'e.exports=assert(load('..string.format('%q',exportCode)..',"@connected-cache-core","t",e))("_FluxUI",{Border=B})'end);assert(n==1)
 local f=assert(load(text..'\nreturn fixture','@connected-cache-fixture','t',_G))()
 local j,new,piece,flush,objects,_,choose,_,e=f();choose(style,'class')
 local p=new(e.UIParent);local id=0
 local function edge(k,r)local t=piece(p,k,r);id=id+1;t.cacheName='edge'..id;return t end
 edge('Top',{0,-9,3400,17});local vertical={}
 for i=1,8 do for k=1,7 do vertical[#vertical+1]=edge('Left',{i*400+k*26-9,-40,16,80})end end
 local function mesh()
  local rows={};for _,o in ipairs(e.exports.active())do if o.triangles then rows[#rows+1]=digest(o.triangles,true)end end;table.sort(rows);return table.concat(rows,'\n')
 end
 flush();local first=mesh();local cold=j.stats.compileMisses
 vertical[7].rect[1]=vertical[7].rect[1]+11;j:Invalidate(nil,vertical[7]);flush()
 local changed=mesh();local hits,misses=j.stats.compileHits,j.stats.compileMisses
 j:Invalidate(true);flush();local warm=mesh();local warmHits,warmMisses=j.stats.compileHits,j.stats.compileMisses
 -- Force a native commit failure after some new fields have already compiled.
 local m=getmetatable(e.UIParent).__index;local create=m.CreateTexture;local fail=true
 m.CreateTexture=function(self,...)if fail then error('compile rollback allocation failure',0)end;return create(self,...)end
 edge('Left',{3300,-40,16,80});local ok,err=pcall(flush)
 check(not ok and tostring(err):find('compile rollback allocation failure',1,true),'real commit allocation failure propagates')
 check(next(e.exports.cache())==nil,'failed native commit publishes no prepared compile entries and clears the previous cache')
 fail=false;j:Invalidate(true);flush();check((j.stats.compileMisses or 0)>0,'retry compiles and commits a new valid generation after rollback')
 return first,changed,warm,cold,hits,misses,warmHits,warmMisses
end
local disabled,n=source:gsub('local cached=key and branchCompilePrevious%[key%]','local cached=nil');assert(n==1)
disabled=disabled:gsub('cached=key and branchCompileAlternate%[key%]','cached=nil')
for _,style in ipairs{1,2}do
 local first,changed,warm,cold,hits,misses,wh,wm=connected(nil,style)
 local bf,bc,bw=connected(disabled,style)
 check(first==bf and changed==bc and warm==bw and changed==warm,'cold/changed/warm complete base meshes match a fresh uncached compiler exactly')
 check(cold==56 and hits==54 and misses==2 and wh==56 and wm==0,'one connected graph reuses54unchanged junctions and recompiles only2changed fields')
 print('BRANCH_COMPILE_WORK|'..style..'|'..cold..'|'..hits..'|'..misses..'|'..wh..'|'..wm)
end
print('Border branch compile cache: '..checks..' checks PASS; exact prepared geometry/source inputs; fresh paint/material; remote ownership/private/masks; UV/gutter/caps/aura/subpixels; committed-only bounded generations; actual connected mesh and rollback parity. Native FPS/pixels/taint pending')
