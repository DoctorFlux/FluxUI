-- Actual PublicRect/Flush phase contracts, compared with the same renderer
-- with its phase activation disabled. Native FPS/pixels/taint are not measured.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local source=read(arg[1]or'Core/BorderJunctions.lua')
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local function fixture(code)
 local text,n=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return string.format('%q',code)end);assert(n==1)
 return assert(load(text..'\nreturn fixture','@phase-geometry-fixture','t',_G))()()
end
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function ref(fn,name,seen)
 seen=seen or{};if seen[fn]then return end;seen[fn]=true
 for i=1,80 do local key,value=debug.getupvalue(fn,i);if not key then break end;if key==name then return fn,i,value end end
 for i=1,80 do local key,value=debug.getupvalue(fn,i);if not key then break end;if type(value)=='function'then local f,n,v=ref(value,name,seen);if f then return f,n,v end end end
end
local function helpers(j)
 local _,_,rect=ref(j.Flush,'PublicRect');local _,_,origin=ref(j.Flush,'PublicOrigin')
 local owner,index=ref(rect,'rectReadPhase');assert(rect and origin and owner)
 local function phase()local _,v=debug.getupvalue(owner,index);return v end
 local function run(fn)
  debug.setupvalue(owner,index,{native={},private={},resolved={},origin={}})
  local ok,err=pcall(fn,phase());debug.setupvalue(owner,index,nil);assert(ok,err)
 end
 return rect,origin,run,phase
end
local function hidden(new,parent,x,y,w,h)
 local o=new(parent,{x,y,w,h});o._FluxBorderStatic=true
 function o:GetRect()self.reads=(self.reads or 0)+1 end
 function o:GetLeft()end;function o:GetBottom()end
 function o:GetSize()return w,h end
 o.anchors={{'BOTTOMLEFT',parent,'BOTTOMLEFT',x,y}}
 return o
end
local function same(a,b)if not a or not b then return a==b end;for i=1,4 do if a[i]~=b[i]then return false end end;return true end
do
 local j,new,_,_,_,_,_,_,e=fixture(source)
 local _,_,role=ref(j.Flush,'Role')
 local _,_,run,phase=helpers(j)
 local overlay=new(e.UIParent)
 overlay._FluxBorderJunctionRole='overlay'
 local branch=new(overlay)
 local a,b=new(branch),new(branch)
 local reads=0
 function branch:GetParent() reads=reads+1;return self.parent end
 run(function(cache)
  check(role(a)=='overlay' and role(b)=='overlay' and reads==1,'sibling border groups share a public role ancestry walk')
  check(cache.roles[branch]=='overlay' and cache.roles[a]=='overlay','only the authoring role is retained in the read phase')
 end)
 check(phase()==nil and role(a)=='overlay' and reads==2,'outside the geometry phase ancestry is read live')
 overlay._FluxBorderJunctionRole='connected'
 overlay._FluxBorderOverlay=true
 run(function(cache)
  check(role(a)==nil and role(b)==nil and reads==3 and cache.roles[branch]==false,
      'explicit connected wins over the overlay flag and later phases sample it afresh')
 end)
 overlay._FluxBorderJunctionRole='overlay'
 local reentrant=new(branch)
 function reentrant:GetParent()
  branch.parent=e.UIParent
  j:Invalidate(nil,branch)
  return branch
 end
 run(function(cache)
  check(role(a)=='overlay','admission can prepare a public role')
  check(role(reentrant)==nil and role(b)==nil and cache.admissionInvalidated and not cache.roles,
      'observed change from inside a parent read drops stale memo entries and reads the new ancestry')
 end)
 local secret=setmetatable({}, {__index=function()error('private parent dereferenced')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 local inaccessible=new(secret)
 run(function(cache)
  check(role(inaccessible)=='overlay' and next(cache.roles)==nil,'unreadable role ancestry never becomes a cached connected source')
  inaccessible.parent=e.UIParent
  check(role(inaccessible)==nil and cache.roles[inaccessible]==false,'a later public read can classify the previously unreadable source')
 end)
 local privateRole=new(e.UIParent);privateRole._FluxBorderJunctionRole=secret
 run(function(cache)
  check(role(privateRole)=='overlay' and not next(cache.roles),'private role fields bypass the geometry cache')
 end)
end
do
 local j,new,_,_,_,_,_,_,e=fixture(source);local rect,origin,run,phase=helpers(j)
 local o=hidden(new,e.UIParent,20,30,40,50)
 run(function()
  local a={rect(o)};local reads=o.reads;local b={rect(o)}
  check(same(a,{20,30,40,50})and same(a,b)and o.reads==reads,'same pure phase reuses a validated hidden rectangle')
  local x,y=origin(o);check(x==20 and y==30,'missing native origin uses the same public anchor rectangle')
 end)
 check(phase()==nil,'helper phase ends without retaining geometry')
 o.anchors[1][4]=27
 run(function()check(same({rect(o)},{27,30,40,50}),'later phase observes a real changed anchor without stale memo')end)
 function o:GetRect()return 90,80,70,60 end
 function o:GetNumPoints()error('public native rectangle must win over anchors')end
 run(function()check(same({rect(o)},{90,80,70,60}),'new native public geometry wins over an older prepared anchor rectangle')end)
 local secret=setmetatable({}, {__eq=function()error('private comparison')end,__add=function()error('private arithmetic')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 function o:GetRect()return secret,80,70,60 end
 run(function(cache)
  check(rect(o)==nil and cache.native[o]==false and cache.private[o]==true,'private native geometry fails closed with only a boolean marker')
  check(cache.resolved[o]==nil,'private native values never enter resolved public tuples')
 end)
 function o:GetRect()return 91,81,71,61 end
 run(function()check(same({rect(o)},{91,81,71,61}),'private marker cannot survive into a later public phase')end)
 local missing=hidden(new,e.UIParent,0,0,20,20);missing.anchors={}
 run(function()check(rect(missing)==nil,'missing geometry fails closed')end)
 missing.anchors={{'BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',14,15}}
 run(function()check(same({rect(missing)},{14,15,20,20}),'missing marker cannot poison a later prepared shape')end)
 -- A root longer than the original depth allowance must stay unavailable,
 -- regardless of whether shallower suffixes were memoized first.
 local chain={};local parent=e.UIParent
 for i=1,11 do local o=hidden(new,parent,1,1,20,20);chain[i]=o;parent=o end
 local expected={rect(chain[11])};check(#expected==0,'baseline rejects an over-depth anchor chain')
 run(function()
  for i=1,8 do rect(chain[i])end
  check(same({rect(chain[11])},expected),'cached suffixes do not relax the original depth-eight guard')
 end)
 run(function()
  check(rect(chain[11])==nil,'context-dependent depth failure remains closed')
  check(same({rect(chain[6])},{6,6,20,20}),'deep-root failure cannot poison a later shallower root')
 end)
 local cycle=hidden(new,e.UIParent,0,0,20,20);cycle.anchors={{'BOTTOMLEFT',cycle,'BOTTOMLEFT',0,0}}
 run(function()for _=1,3 do check(rect(cycle)==nil,'cyclic anchors remain bounded and unavailable')end end)
 -- A wide acyclic graph exceeds64 unique visited nodes while every individual
 -- branch stays below8 deep. Cached branches must still consume that budget.
 local leaves={};for i=1,64 do leaves[i]=hidden(new,e.UIParent,i,0,20,20)end
 local branches={}
 for i=1,8 do local b=hidden(new,e.UIParent,0,0,20,20);b.anchors={};for k=1,8 do b.anchors[k]={'BOTTOMLEFT',leaves[(i-1)*8+k],'BOTTOMLEFT',0,0}end;branches[i]=b end
 local wide=hidden(new,e.UIParent,0,0,20,20);wide.anchors={};for i,b in ipairs(branches)do wide.anchors[i]={'BOTTOMLEFT',b,'BOTTOMLEFT',0,0}end
 check(rect(wide)==nil,'baseline rejects over64 unique anchor nodes')
 run(function()for _,b in ipairs(branches)do rect(b)end;check(rect(wide)==nil,'shared positive cache cannot bypass the original unique-node budget')end)
end
do
 local j,new,piece,flush,_,_,_,_,e=fixture(source);local rect,_,_,phase=helpers(j)
 local root=new(e.UIParent);root._FluxBorderStatic=true
 local a=piece(root,'Top',{0,0,100,17});piece(root,'Left',{40,-30,16,80})
 local original=a.GetRect;local fail=false;local readCount=0
 function a:GetRect()
  if phase()then readCount=readCount+1;if fail then error('native geometry read failure')end end
  return original(self)
 end
 local align=j.AlignNearbyPanels
 function j:AlignNearbyPanels()
  check(phase()==nil,'alignment runs before any geometry memo is active')
  local _=rect(a);a.rect[1]=a.rect[1]+1
  return align(self)
 end
 flush();check(readCount==1,'actual ReadLayout plus all watched snapshots share exactly one native rectangle read')
 check(phase()==nil,'actual successful Flush drops all phase caches before solving/rendering')
 fail=true;j:Invalidate(true);local ok,err=pcall(flush)
 check(not ok and tostring(err):find('native geometry read failure',1,true)and phase()==nil,'native getter exception clears the phase before propagating the original failure')
 fail=false;a.rect[1]=51;j:Invalidate(true);flush()
 check(phase()==nil and j.stats.fallback==nil,'next real Flush recovers with fresh geometry after a failed phase')
end
do
 local j,new,piece,_,_,_,_,_,e=fixture(source)
 local _,_,readLayout=ref(j.Flush,'ReadLayout')
 local root=new(e.UIParent)
 root.unit,root._FluxBorderIndependent='party1',true
 local reads={strata=0,scale=0,level=0}
 local strata,scale,level=root.GetFrameStrata,root.GetEffectiveScale,root.GetFrameLevel
 function root:GetFrameStrata()reads.strata=reads.strata+1;return strata(self)end
 function root:GetEffectiveScale()reads.scale=reads.scale+1;return scale(self)end
 function root:GetFrameLevel()reads.level=reads.level+1;return level(self)end
 local top=piece(root,'Top',{0,0,100,17})
 for x=15,60,15 do piece(root,'Left',{x,-30,16,80})end
 reads.strata,reads.scale,reads.level=0,0,0
 local segments=readLayout()
 check(#segments==5,'actual layout keeps all independent runs on the same parent')
 if arg[2]~='--measure-parent' then
  check(reads.strata==1 and reads.scale==1 and reads.level==1,'same-parent runs and textures share one verified native parent sample')
 end
 print(('PARENT_LAYOUT_READS runs=%d strata=%d scale=%d level=%d'):format(#segments,reads.strata,reads.scale,reads.level))
 local function ByTexture(values)
  local result={}
  for _,segment in ipairs(values)do result[segment.texture]=segment.group end
  return result
 end
 local firstPriority=ByTexture(segments)[top].priority
 root.level,root.scale,root.unit=12,.8,'party2'
 local newEdge=piece(root,'Bottom',{0,-45,100,16})
 local updated=ByTexture(readLayout())
 check(updated[top].unitOwner=='party2' and updated[top].scale==.8,
  'a new layout observes the changed unit and scale')
 check(updated[top].priority==firstPriority and updated[newEdge].priority==firstPriority+12,
  'sharing a parent preserves existing and newly assigned group priorities')
 local secret={}
 e.issecretvalue=function(value)return rawequal(value,secret)end
 local attempts=0
 function root:GetFrameLevel()
  attempts=attempts+1
  if attempts==1 then return secret end
  return level(self)
 end
 local recovered=readLayout()
 check(#recovered==5 and attempts>=2,'the unavailable sample does not poison usable sibling runs')
 function root:GetEffectiveScale()return secret end
 check(#(readLayout())==0,'a new read discards the previous public scale when the client restricts it')
 function root:GetEffectiveScale()return scale(self)end
 check(#(readLayout())==6,'restoring public scale recovers the same runs on the next read')
end
local noMemo,n=source:gsub('rectReadPhase={native={},private={},resolved={},origin={}}','rectReadPhase=nil');assert(n==2,'primary and conservative fallback read-phase activations')
local function workload(code,style)
 local j,new,piece,flush,objects,_,choose,_,e=fixture(code);choose(style,'class')
 local rect,origin,_,phase=helpers(j);local reading=false;local nativeReads=0
 local m=getmetatable(e.UIParent).__index;local original=m.GetRect
 function m:GetRect()if reading then nativeReads=nativeReads+1 end;return original(self)end
 local function delayed(o,w,h)
  function o:GetRect()if reading then nativeReads=nativeReads+1 end end
  function o:GetLeft()end;function o:GetBottom()end
  function o:GetSize()return w,h end
  return o
 end
 local root=delayed(new(e.UIParent),5000,2000);root._FluxBorderStatic=true;root.unit='target';root:Hide();root.anchors={{'BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',100,100}}
 local common=root
 for _=1,3 do local p=delayed(new(root),5000,2000);p.anchors={{'BOTTOMLEFT',common,'BOTTOMLEFT',1,1}};common=p end
 for i=1,160 do
  local host=delayed(new(root),120,90);host._FluxBorderOwner=root;host.anchors={{'BOTTOMLEFT',common,'BOTTOMLEFT',(i%20)*200,math.floor(i/20)*100}}
  local h=delayed(piece(host,'Top',{0,43,100,17}),100,17);h.anchors={{'BOTTOMLEFT',host,'BOTTOMLEFT',0,43}}
  local v=delayed(piece(host,'Left',{40,0,16,80}),16,80);v.anchors={{'BOTTOMLEFT',host,'BOTTOMLEFT',40,0}}
 end
 local align=j.AlignNearbyPanels;function j:AlignNearbyPanels()local v=align(self);reading=true;return v end
 local solve=j.Solve;function j:Solve(...)reading=false;return solve(self,...)end
 flush();reading=false
 check(j.stats.fallback==nil and (j.stats.triangles or 0)>0,'hundreds of shared hidden anchor regions compile a real prepared mesh')
 check(phase()==nil,'large actual Flush retains no phase cache')
 local digest={}
 for _,t in ipairs(objects)do if t.decorative and t:IsShown()and t:GetAlpha()>0 and t.size and t.point then
  local x,y=origin(t:GetParent());local p=t.point;local values={x+(p[4]or 0),y+(p[5]or 0),t.size[1],t.size[2],t:GetAlpha()}
  for _,v in ipairs(t.uv)do values[#values+1]=v end
  for k=1,4 do local v=t.vertices and t.vertices[k]or{0,0};values[#values+1]=v[1];values[#values+1]=v[2]end
  for k,v in ipairs(values)do values[k]=string.format('%.7f',v)end
  digest[#digest+1]=table.concat(values,',')
 end end
 table.sort(digest)
 return table.concat(digest,'\n'),nativeReads,j.stats.operations,j.stats.fragments,j.stats.triangles
end
for _,style in ipairs{1,2}do
 local baseline,baseReads,bo,bf,bt=workload(noMemo,style)
 local current,reads,co,cf,ct=workload(source,style)
 check(current==baseline and bo==co and bf==cf and bt==ct,'phase memo keeps the actual complete baseline mesh digest and operation/fragment/triangle counts')
 check(reads<baseReads*.5,'phase-local native reads decrease on320 border pieces with shared hidden anchor chains')
 print('PHASE_WORK|'..style..'|'..baseReads..'|'..reads..'|'..co..'|'..cf..'|'..ct)
end
print('Border geometry phase: '..checks..' checks PASS; exact native/hidden/private/missing/depth/budget/cycle contracts; alignment/exception/future-phase freshness; actual mesh parity and shared-anchor API work. Native FPS/pixels/taint pending')
