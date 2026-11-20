-- Real ReadLayout still validates every source's current native rectangle.
-- Only observer bookkeeping is localized; no positions survive a read phase.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local source=read(arg[1]or'Core/BorderJunctions.lua')
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local export='\nreturn {observed=observed,links=observerLinks,dependents=observerDependents,unsafe=observerUnsafe,snapshot=Snapshot,geometry=Geometry,static=StaticUnitOwner,ops=function()return active end,phase=function()return rectReadPhase end,runPhase=function(fn)rectReadPhase={native={},private={},resolved={},origin={}};local ok,err=pcall(fn,rectReadPhase);rectReadPhase=nil;assert(ok,err)end,refresh=RefreshObserverDependents}\n'
local function fixture(code,style)
 local text,n=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return string.format('%q',code..export)end);assert(n==1)
 text,n=text:gsub('    assert%(load%(', '    e.inspect=assert(load(',1);assert(n==1)
 local j,new,piece,flush,objects,combat,choose,queued,e=assert(load(text..'\nreturn fixture','@observer-fixture','t',_G))()()
 choose(style or 1,'class')
 local m=getmetatable(e.UIParent).__index
 function m:SetScale(v)self.scale=v end
 return j,new,piece,flush,objects,e,e.inspect,combat
end
local function panel(new,piece,parent,x,y)
 local anchor=new(parent,{x,y,150,120});anchor.testName='anchor'..x..':'..y
 local host=new(anchor,{x,y,150,120});host.testName='host'..x..':'..y;host.inheritScale=true
 local function xy()local a=anchor.position or anchor.rect;return a[1],a[2]end
 function host:GetRect()local a,b=xy();return a,b,150,120 end
 function host:GetLeft()return (xy())end
 function host:GetBottom()local _,b=xy();return b end
 local h=piece(host,'Top',{x,y+43,100,17});local v=piece(host,'Left',{x+40,y,16,80})
 for _,p in ipairs{h,v}do
  local dx,dy=p.rect[1]-x,p.rect[2]-y;local w,hh=p.rect[3],p.rect[4]
  p.inheritScale=true;p.nativeReads=0
  function p:GetRect()self.nativeReads=self.nativeReads+1;local a,b=xy();return a+dx,b+dy,w,hh end
 end
 return anchor,host,h,v
end
local function digest(objects)
 local out={}
 for _,t in ipairs(objects)do if t.decorative and t:IsShown()and t:GetAlpha()>0 and t.size and t.point then
  local parent=t:GetParent();local p=t.point;local values={parent:GetLeft()+(p[4]or 0),parent:GetBottom()+(p[5]or 0),t.size[1],t.size[2],t:GetAlpha()}
  for _,v in ipairs(t.uv)do values[#values+1]=v end
  for k=1,4 do local v=t.vertices and t.vertices[k]or{0,0};values[#values+1]=v[1];values[#values+1]=v[2]end
  local r,g,b=t:GetVertexColor();values[#values+1]=r;values[#values+1]=g;values[#values+1]=b;values[#values+1]=parent:GetFrameLevel()
  for i,v in ipairs(values)do values[i]=string.format('%.7f',v)end
  values[#values+1]=t.path;values[#values+1]=parent:GetFrameStrata();values[#values+1]=t.layer or'ARTWORK';values[#values+1]=t.sublevel or 0;out[#out+1]=table.concat(values,',')
 end end
 table.sort(out);return table.concat(out,'\n')
end
local fullObserver,n=source:gsub('pairs%(%(observerRefresh.all or fullDirty%) and watched or observerRefresh.items%)','pairs(watched)');assert(n==1,'one localized observer publication')
local function workload(code,style)
 local j,new,piece,flush,objects,e,q=fixture(code,style);local anchors,hosts,pieces={},{},{}
 local parentReads,sourceReads=0,0
 for i=1,180 do
  local a,h,x,y=panel(new,piece,e.UIParent,(i%20)*200,math.floor(i/20)*150)
  anchors[i],hosts[i]=a,h;pieces[#pieces+1]=x;pieces[#pieces+1]=y
  for _,o in ipairs{a,h}do local native=o.GetRect;function o:GetRect()if q.phase()then parentReads=parentReads+1 end;return native(self)end end
  for _,o in ipairs{x,y}do local native=o.GetRect;function o:GetRect()if q.phase()then sourceReads=sourceReads+1 end;return native(self)end end
 end
 flush();check(j.stats.fallback==nil and j.stats.triangles>0,'large fixture commits real complete border mesh')
 local cold=digest(objects);parentReads,sourceReads=0,0
 for _,i in ipairs{31,32}do anchors[i].rect[1]=anchors[i].rect[1]+12;anchors[i]:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',anchors[i].rect[1],anchors[i].rect[2])end
 flush();local moved=digest(objects)
 check(j.stats.fallback==nil and q.phase()==nil,'localized change succeeds and drops phase-only state')
 for _,i in ipairs{31,32}do
  check(q.observed[hosts[i]][2]==hosts[i]:GetRect(),'changed anchor refreshes its dependent host snapshot')
 end
 local reads=j.stats.geometryReads;hosts[31]:SetPoint('BOTTOMLEFT',anchors[31],'BOTTOMLEFT',0,0);flush()
 check(j.stats.geometryReads==reads,'unchanged dependent callback cannot schedule a redundant geometry read')
 return cold,moved,parentReads,sourceReads,j.stats.operations,j.stats.fragments,j.stats.triangles
end
for _,style in ipairs{1,2}do
 local bc,bm,bp,bs,bo,bf,bt=workload(fullObserver,style)
 local cc,cm,cp,cs,co,cf,ct=workload(source,style)
 check(bc==cc and bm==cm and bo==co and bf==cf and bt==ct,'local observer refresh preserves complete cold/moved meshes and operation budgets')
 check(cs==360 and bs==360,'all360 source rectangles are freshly validated in both actual read phases')
 check(cp<bp*.05,'two changed anchors refresh their own observers instead of360 unrelated parent snapshots')
 print('OBSERVER_WORK|'..style..'|parents='..bp..'->'..cp..'|sources='..bs..'->'..cs)
end
do
 local counted,n=source:gsub('function Spatial.Eligible%(segments,refreshItems%)',[[function Spatial.Eligible(segments,refreshItems)
    _G.eligibilityCalls=(_G.eligibilityCalls or 0)+1]],1)
 assert(n==1)
 local j,new,piece,flush,_,e,q=fixture(counted)
 local host=new(e.UIParent)
 local other=new(e.UIParent,{500,0,100,100})
 local function Authored(parent,key,rect)
  local texture,record=piece(parent,key,rect)
  record.art='Interface\\AddOns\\_FluxUI\\Texture\\borders\\Battlefield100.tga'
  texture.path=record.art
  return texture
 end
 local moving=Authored(host,'Top',{0,43,100,17})
 Authored(host,'Left',{40,0,16,80})
 Authored(other,'Top',{500,43,100,17})
 Authored(other,'Left',{540,0,16,80})
 flush()
 check(j.stats.localMode,'initial authored scene admits a regional layout')
 local function Move()
  local reads=e.eligibilityCalls
  moving.rect[2]=moving.rect[2]+3
  j:Invalidate(nil,moving)
  j:CommitLayout()
  return e.eligibilityCalls-reads
 end
 check(Move()==1 and j.stats.localMode,'a local geometry read uses the regional admission already checked for its filter')
 local update
 local getStrata=host.GetFrameStrata
 function host:GetFrameStrata()
  if update and q.phase() then
   local run=update;update=nil;run()
  end
  return getStrata(self)
 end
 update=function()j:Invalidate(nil,host)end
 check(Move()==2 and j.stats.localMode,'an observed setter during the read requires a fresh check')
 update=function()piece(other,'Left',{553,0,16,80})end
 check(Move()==2 and not j.stats.localMode,'foreign art registered during the read takes the fresh full layout')
 flush()
end
do
 local j,new,piece,flush,_,e=fixture(source)
 local host=new(e.UIParent)
 local other=new(e.UIParent,{400,0,100,100})
 local art='Interface\\AddOns\\_FluxUI\\Texture\\borders\\Battlefield100.tga'
 local moving,record=piece(host,'Top',{0,43,100,17})
 moving.path,record.art=art,art
 local distant,background=piece(other,'Top',{400,43,100,17})
 distant.path,background.art=art,art
 flush()
 check(j.stats.localMode,'authored registration can use the regional renderer')
 distant.GetRect=distant.GetRect
 moving.rect[1]=moving.rect[1]+4
 j:Invalidate(nil,moving)
 j:CommitLayout()
 check(not j.stats.localMode,'a foreign geometry getter on another border still prevents regional reuse on the next read')
end
do
 local j,new,piece,flush,objects,e,q=fixture(source)
 local a,host,h=panel(new,piece,e.UIParent,0,0);local b,_,other=panel(new,piece,e.UIParent,400,0)
 local mode='public';local original=h.GetRect
 local secret=setmetatable({}, {__add=function()error('private arithmetic')end,__eq=function()error('private comparison')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 function h:GetRect()if mode=='private'then self.nativeReads=self.nativeReads+1;return secret,43,100,17 elseif mode=='missing'then self.nativeReads=self.nativeReads+1;return end;return original(self)end
 flush();local initial=h.nativeReads
 for _,state in ipairs{'private','public','missing','public'}do
  mode=state;b.rect[1]=b.rect[1]+1;b:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',b.rect[1],0);flush()
  check(h.nativeReads>initial,'unrelated source native coordinates are always re-read on another grid change');initial=h.nativeReads
  local geometry=q.geometry(h)
  check(state=='public'and geometry~=nil or state~='public'and geometry==nil,'new private/missing native coordinates fail closed without a dirty signal on that source')
  local used=false;for _,op in ipairs(q.ops())do for segment in pairs(op.segments)do if segment.texture==h then used=true end end end
  check(used==(state=='public'),'actual committed mesh excludes new private/missing source and restores only fresh public source')
  check(q.phase()==nil and j.stats.fallback==nil,'private/missing transition leaves no phase and remains recoverable')
 end
 check(q.geometry(h)~=nil,'public source recovers without old cross-pass failure state')
 -- Replacing equal-position anchors must still replace dependency links.
 local same=new(e.UIParent,{0,0,150,120});e.NamedObserverAnchor=same
 host:SetPoint('BOTTOMLEFT',a,'BOTTOMLEFT',0,0);flush()
 check(q.links[host][a]and q.dependents[a][host],'initial explicit anchor is tracked')
 host:SetPoint('BOTTOMLEFT','NamedObserverAnchor','BOTTOMLEFT',0,0);flush()
 check(q.links[host][same]and q.dependents[same][host],'named equal-position replacement installs its new reverse dependency')
 -- Parent remains a genuine dependency until reparented.
 host:SetParent(same);flush()
 check(not q.links[host][a]and not q.dependents[a][host],'reparenting removes obsolete anchor/parent links')
 host:ClearAllPoints();flush();check(q.links[host][same]and not q.unsafe[host],'ClearAllPoints keeps only actual parent dependency')
 host:SetAllPoints(a);flush();check(q.links[host][a]and q.links[host][same],'SetAllPoints records both actual anchor and parent')
 host:ClearAllPoints();flush();check(not q.links[host][a],'commit removes old all-point dependency')
 -- Moving or scaling a parent refreshes descendants, while geometry always
 -- comes from the new native rectangles/scales rather than this graph.
 same.rect[1]=10;same:SetScale(.75);flush()
 check(q.observed[host][6]==.75,'actual inherited parent scale reaches dependent observer publication')
 local reads=j.stats.geometryReads;host:SetPoint('BOTTOMLEFT',same,'BOTTOMLEFT',0,0);flush()
 check(j.stats.geometryReads==reads,'real ancestor refresh prevents a later same-layout child reflow')
 j:Invalidate(true);flush();check(q.observed[h]~=false and q.phase()==nil,'full global force refreshes all observers with fresh native validation')
 -- Reverse cycles, uncertain links and traversal limits only broaden refresh.
 local r={all=false,items={}};q.dependents[a][same]=true;q.dependents[same][a]=true;q.refresh(r,a)
 check(r.all,'reverse dependency cycle falls back to all watched observers')
 q.dependents[a][same]=nil;q.dependents[same][a]=nil
 q.unsafe[a]=true;r={all=false,items={}};q.refresh(r,a);check(r.all,'private or unresolved dependency broadens observer refresh conservatively');q.unsafe[a]=nil
 local before=j.limits.segments;j.limits.segments=0;r={all=false,items={}};q.refresh(r,a);j.limits.segments=before
 check(r.all,'reverse dependency traversal budget falls back to a full observer refresh')
end
do
 local j,new,piece,flush,_,e,q,combat=fixture(source)
 local a,host=panel(new,piece,e.UIParent,0,0)
 local b=new(e.UIParent,{0,0,150,120})
 local transient=new(e.UIParent,{0,0,150,120})
 host:SetAllPoints(a)
 flush()
 local native=host.GetNumPoints
 local linkReads=0
 function host:GetNumPoints()
  linkReads=linkReads+1
  return native(self)
 end
 local reads=j.stats.geometryReads
 for _=1,20 do
  host:ClearAllPoints()
  host:SetPoint('TOPLEFT',transient,'TOPLEFT',0,0)
  host:SetPoint('BOTTOMRIGHT',transient,'BOTTOMRIGHT',0,0)
 end
 host:ClearAllPoints()
 host:SetPoint('TOPLEFT',b,'TOPLEFT',0,0)
 host:SetPoint('BOTTOMRIGHT',b,'BOTTOMRIGHT',0,0)
 check(linkReads==0 and not q.links[transient],'intermediate anchors do no observer reads or registration')
 j:CommitLayout()
 check(linkReads==1 and q.links[host][b] and q.dependents[b][host] and not q.links[host][transient],
    'one observer read installs the settled dependency, even with the same geometry')
 check(j.stats.geometryReads==reads,'a pure dependency change does not rebuild a stable mesh')
 local old=q.links[host]
 host:ClearAllPoints()
 host:SetPoint('TOPLEFT',b,'TOPLEFT',0,0)
 host:SetPoint('BOTTOMRIGHT',b,'BOTTOMRIGHT',0,0)
 j:CommitLayout()
 check(q.links[host]==old and linkReads==2,'unchanged dependencies retain their link set')
 local align=j.AlignNearbyPanels
 function j:AlignNearbyPanels()
  host:ClearAllPoints()
  host:SetPoint('TOPLEFT',a,'TOPLEFT',0,0)
  align(self)
 end
 b.rect[1]=5
 b:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',5,0)
 j:CommitLayout()
 check(q.links[host][a] and not q.links[host][b],'alignment changes also install before the same geometry read')
 j.AlignNearbyPanels=align
 local before=linkReads
 local secret={}
 e.issecretvalue=function(value)return rawequal(value,secret)end
 combat(true)
 host:ClearAllPoints()
 host:SetPoint('TOPLEFT',secret,'TOPLEFT',0,0)
 j:CommitLayout()
 check(linkReads==before and q.links[host][a],'combat defers dependency reads along with structural rendering')
 combat(false)
 j:CommitLayout()
 check(linkReads==before+1 and q.unsafe[host] and q.links[host][a] and not q.links[host][secret],
    'settled secret anchors leave only the actual parent dependency')
 host:SetPoint('TOPLEFT',b,'TOPLEFT',0,0)
 j:CommitLayout()
 check(not q.unsafe[host] and q.links[host][b],'returning to public geometry recovers scoped observers')

 -- Neither published weak set may alias the batch's reusable link scratch.
 local other,second=panel(new,piece,e.UIParent,500,0)
 host:SetPoint('TOPLEFT',a,'TOPLEFT',0,0)
 second:SetPoint('TOPLEFT',b,'TOPLEFT',0,0)
 j:CommitLayout()
 local firstLinks,secondLinks=q.links[host],q.links[second]
 check(firstLinks~=secondLinks and firstLinks[a] and not firstLinks[b]
     and secondLinks[other] and secondLinks[b] and not secondLinks[a],
     'simultaneous rewires publish independent and exact parent/anchor sets')
 second:ClearAllPoints();j:CommitLayout()
 check(q.links[host]==firstLinks and firstLinks[a] and q.links[second][other] and not q.links[second][b],
     'later scratch reuse cannot mutate a retained dependency set')

 local parent=host.GetParent
 function host:GetParent()return secret end
 local stamp,reason=q.snapshot(host)
 check(stamp==false and reason=='restricted parent',
     'an opaque parent is rejected before it can enter a comparable snapshot')
 host.GetParent=parent
end
do
 local _,new,_,_,_,e,q=fixture(source)
 local owner=new(e.UIParent);owner._FluxBorderStatic=true
 local child=new(owner);local reads=0
 function child:GetParent()reads=reads+1;return self.parent end
 q.runPhase(function(cache)
  check(q.static(child)==owner,'pure phase resolves the actual current stable owner')
  local first=reads;check(q.static(child)==owner and reads==first,'repeated owner query reuses only this phase ancestry result')
  check(cache.owners[child]==owner,'phase owner cache contains handles without paint or geometry values')
 end)
 local nextOwner=new(e.UIParent);nextOwner._FluxBorderStatic=true;child.parent=nextOwner
 q.runPhase(function()check(q.static(child)==nextOwner,'a new phase observes reparenting instead of an old cached owner')end)
 check(q.phase()==nil,'phase owner handles are discarded after pure reading')
 local secret={};e.issecretvalue=function(v)return rawequal(v,secret)end
 q.runPhase(function(cache)check(q.static(secret)==nil and cache.owners==nil,'restricted query is rejected before allocating or retaining owner records')end)
 -- Cached suffix ownership must not relax the original32-parent guard.
 local last=owner;local chain={}
 for i=1,33 do last=new(last);chain[i]=last end
 q.runPhase(function()
  check(q.static(chain[30])==owner,'a bounded suffix may prepare a valid owner record')
  check(q.static(chain[33])==nil,'phase owner memo preserves the original bounded walk for deeper queries')
 end)
end
do
 local _,new,piece,flush,_,e,q=fixture(source)
 local anchor,host,h=panel(new,piece,e.UIParent,0,0)
 flush()
 local branches,visits=q.dependents[host],0
 getmetatable(branches).__pairs=function(t)visits=visits+1;return next,t,nil end
 local refresh={items={}}
 q.refresh(refresh,anchor)
 for _=1,20 do q.refresh(refresh,host);q.refresh(refresh,anchor) end
 check(not refresh.all and refresh.items[h] and visits==1,'overlapping invalidations walk a completed observer branch once')
 local extra=piece(host,'Bottom',{0,0,100,17})
 q.refresh(refresh,anchor)
 check(refresh.items[extra] and visits==2,'changing observer links invalidates the current refresh memo')
end
do
 local j,new,piece,flush,_,e,q=fixture(source)
 local host=new(e.UIParent)
 local art='Interface\\AddOns\\_FluxUI\\Texture\\borders\\Battlefield100.tga'
 local moving,a=piece(host,'Top',{0,43,100,17})
 local cross,b=piece(host,'Left',{40,0,16,80})
 moving.path,a.art,cross.path,b.art=art,art,art,art
 local phaseReads=0
 function moving:GetDrawLayer()
  if q.phase()then phaseReads=phaseReads+1 end
  return self.layer or 'ARTWORK',self.sublevel or 0
 end
 flush()
 check(j.stats.localMode,'watched sources enter the regional renderer')
 local function Move()
  phaseReads=0
  moving.rect[2]=moving.rect[2]+3
  j:Invalidate(nil,moving)
  j:CommitLayout()
 end
 Move()
 check(phaseReads==1 and q.observed[moving][9]=='ARTWORK','unchanged alignment reuses the watched preflight snapshot')
 local align=j.AlignNearbyPanels
 function j:AlignNearbyPanels()
  moving.layer='OVERLAY'
  return 1
 end
 Move()
 check(phaseReads==2 and q.observed[moving][9]=='OVERLAY','alignment changes require fresh source observation')
 j.AlignNearbyPanels=align
 local getStrata,changeLayer=host.GetFrameStrata,true
 function host:GetFrameStrata()
  if changeLayer and q.phase()then
   changeLayer=false
   moving:SetDrawLayer('ARTWORK',2)
  end
  return getStrata(self)
 end
 Move()
 check(phaseReads==2 and q.observed[moving][9]=='ARTWORK' and q.observed[moving][10]==2,
   'a watched setter during the layout read invalidates the preflight observation')
end
print('Border observer refresh: '..checks..' checks PASS; complete mesh parity, localized observer API work, native source privacy/missing freshness, anchor replacement/parent/scale/cycle/budget guards. Native FPS/pixels/taint pending')
