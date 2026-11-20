-- Actual Lua renderer differential and retained-resource regression.
-- Experimental bounded scene query around an output cell. Executes unchanged
-- production Core. This is source/art sampling, not a native renderer or FPS test.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local corePath='Core/BorderJunctions.lua'
local referenceMode=false
local function factory(reference)
 referenceMode=reference
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
prefix=prefix:gsub('    assert%(load%(', '    e.spatial=assert(load(',1)
prefix=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return string.format('%q',read(corePath):gsub('if Spatial.Try%(segments,signature,',referenceMode and 'if false and Spatial.Try(segments,signature,'or 'if Spatial.Try(segments,signature,')..'\nreturn {read=ReadLayout,source=Source,geometry=Geometry,available=PaintAvailable,clip=ClipField,slice=J.SliceUV,cells=Spatial.cells,inspect=function()return clipped,colorListeners,visibilityListeners,sprites end,spatial=Spatial}')end,1)
return assert(load(prefix..'\nreturn fixture','@actual-border-locality-fixture','t',_G))()
end
local fixture=factory(false)
local legacyFixture=factory(true)
local sampleSource=read('tests/border_optional_unit_parts.lua')
local sa=assert(sampleSource:find('\nlocal images={}\n',1,true))+1;local sb=assert(sampleSource:find("local paths={'baseline','candidate'}",sa,true))
local sample=assert(load('local check=...\n'..sampleSource:sub(sa,sb-1)..'\nreturn sampleRGBA','@canonical-art-sampler','t',_G))(function(v,m)assert(v,m)end)
local uv={TL={211/256,227/256,1/256,18/256},TR={229/256,245/256,1/256,18/256},BL={211/256,227/256,20/256,36/256},BR={229/256,245/256,20/256,36/256},
 Top={1/256,209/256,1/256,18/256},Bottom={1/256,209/256,20/256,36/256},Left={1/256,17/256,38/256,172/256},Right={19/256,35/256,38/256,172/256}}
local function overlap(a,b)return a[1]<b[3]and b[1]<a[3]and a[2]<b[4]and b[2]<a[4]end
local function query(scene,r,halo,scale)
 local q={r[1]-halo,r[2]-halo,r[3]+halo,r[4]+halo};local out={}
 for _,g in ipairs(scene)do
  for _,p in ipairs(g.parts)do local a=p[2];local box={a[1]*scale,a[2]*scale,(a[1]+a[3])*scale,(a[2]+a[4])*scale}
   if overlap(box,q)then out[#out+1]=g;break end
  end
 end
 return out
end
local function box(x,y,w,h,name,unit,level)
 return{name=name,unit=unit,level=level,parts={{'TL',{x-9,y+h-13,16,17}},{'TR',{x+w-11,y+h-13,16,17}},
  {'BL',{x-9,y-5,16,16}},{'BR',{x+w-11,y-5,16,16}},{'Top',{x+7,y+h-13,w-18,17}},
  {'Bottom',{x+7,y-5,w-18,16}},{'Left',{x-9,y+11,16,h-24}},{'Right',{x+w-11,y+11,16,h-24}}}}
end
local function capture(t)
 local p=t:GetParent();local scale=p:GetEffectiveScale();local x,y,w,h
 if t.decorative then
  local box=t.target or t
  if box~=t then
   assert(not box.target and box:GetParent()==p and box._junctionOwnerOp==t._junctionOwnerOp,
    "a shared texture box belongs to a direct leader in the same operation")
  end
  if not box.point or not box.size then return end
  x=(p:GetLeft()+(box.point[4]or 0))*scale;y=(p:GetBottom()+(box.point[5]or 0))*scale
  w,h=box.size[1]*scale,box.size[2]*scale
 else
  x,y,w,h=t:GetRect();scale=t:GetEffectiveScale();x,y,w,h=x*scale,y*scale,w*scale,h*scale
 end
 local coords={t:GetTexCoord()};if #coords==4 then coords={coords[1],coords[3],coords[1],coords[4],coords[2],coords[3],coords[2],coords[4]}end
 local offsets={};for i=1,4 do local v=t.vertices and t.vertices[i]or{0,0};offsets[i]={v[1]*scale,v[2]*scale}end
 return{t:GetTexture(),{x,y,w,h},coords,offsets,t:GetEffectiveAlpha(),p:GetFrameLevel(),{t:GetVertexColor()}}
end
local function pixel(fields,x,y)
 local out={0,0,0,0};local n=0
 for _,f in ipairs(fields)do
  local r=f[2]
  if x>=r[1]-40 and x<=r[1]+r[3]+40 and y>=r[2]-40 and y<=r[2]+r[4]+40 then
   local a,b,c,d=sample(f,x,y)
   if d>out[4]then out={a,b,c,d}end
   if d>1/255 then n=n+1 end
  end
 end
 return out,n
end
local function scenes(style)
 local track=style==1 and 8 or 9;local left=style==1 and 9 or 9.5
 local cross={{name='long shared bar',level=5,parts={{'Top',{0,-17+track,3200,17}}}}}
 for i=1,24 do cross[#cross+1]={name='divider'..i,unit='player',parts={{'Left',{i*90-left,-40,16,80}}}}end
 local panels={}
 for i=0,7 do panels[#panels+1]=box(i*170,0,170,100,'panel'..i,nil,i%2==0 and 10 or 5)end
 local units={box(0,0,320,124,'player','player',20),box(326,0,320,124,'target','target',20),
  box(-44,0,44,124,'stance',nil,5),box(-180,-85,1100,85,'strip',nil,5)}
 for _,g in ipairs(units)do g.round=g.unit~=nil end
 local auraY=style==1 and 117 or 115
 units[#units+1]=box(326,auraY,160,87,'buffs','target',0);units[#units].aura=true
 units[#units+1]=box(486,auraY,160,87,'debuffs','target',0);units[#units].aura=true
 local hidden={};for _,g in ipairs(units)do hidden[#hidden+1]=g end
 local oldTarget=hidden[2];local target={};for k,v in pairs(oldTarget)do target[k]=v end;target.hidden=true;hidden[2]=target
 local cases={{name='shared-crossbar',groups=cross,points={90,630,1440,2160}},{name='adjacent-panels',groups=panels,points={170,340,680,1020}},
  {name='unit-stance-strip',groups=units,points={0,320,326,646}},{name='target-hidden',groups=hidden,points={326,486,646},y=120},
  {name='rounded-unit-aura',groups=units,points={326,486,646},y=auraY+87+4-(style==1 and 8 or 9)}}
 for _,case in ipairs(cases)do for i,g in ipairs(case.groups)do
  g.color=g.color or{.2+(i%3)*.22,.25+(i%2)*.3,.85-(i%4)*.16,.85}
 end end
 units[2].natural=true;units[2].color={1,1,1,.85};target.natural=true;target.color={1,1,1,.85}
 return cases
end

local checks=0
local function check(ok,message)checks=checks+1;assert(ok,message)end
local function model(scene,style,scale,legacy)
 local j,new,piece,flush,objects,lock,choose,_,e=(legacy and legacyFixture or fixture)();choose(style,'class')
 local source,records={},{};local parents={}
 for i,g in ipairs(scene)do
  local path='Interface\\AddOns\\_FluxUI\\Texture\\borders\\'..(style==1 and'Battlefield100.tga'or g.natural and'ForeverMetal150.tga'or'ForeverMetal150Tint.tga')
  local parent=new(e.UIParent,{0,0,5000,2000});parent.scale=scale;parent._FluxBorderStatic=true;parent.unit=g.unit;parent.level=g.level or 5;parent.strata=g.strata
  parents[i]=parent;if g.hidden then parent:Hide()end
  parent._FluxBorderRoundCorners=g.round;parent._FluxBorderAuraPanel=g.aura
  source[i]={};records[i]={}
  for k,part in ipairs(g.parts)do
   local t,r=piece(parent,part[1],{table.unpack(part[2])});t.scale=scale;t:SetTexture(path);t:SetTexCoord(table.unpack(uv[part[1]]))
   r.art=path;r.artHandle=path;t:SetVertexColor(table.unpack(g.color or{.4,.6,.8,.85}));source[i][k]=t;records[i][k]=r
  end
 end
 flush();check(not j.stats.fallback,'canonical scene did not fall back')
 return{j=j,sources=source,records=records,parents=parents,objects=objects,flush=flush,e=e,cells=e.spatial.cells,lock=lock,piece=piece,new=new,choose=choose}
end
local function fields(m)
 local out={}
 for _,t in ipairs(m.objects)do if t:IsVisible()and t:GetAlpha()>0 and type(t:GetTexture())=='string'and t:GetTexture():find('Texture\\borders\\',1,true)then local f=capture(t);if f then out[#out+1]=f end end end
 return out
end
local function indexes(m)
 if not m.j.stats.localMode then return end
 local pools,colors,visibility,sprites=m.e.spatial.inspect()
 for _,entry in pairs(pools)do for i,field in ipairs(entry.pool)do check(field._localPoolIndex==i,'source pool swap index')end end
 local regionalColors=true
 for _,list in pairs(colors)do if list[1] then regionalColors=false;break end end
 if regionalColors then
  for source,byCell in pairs(colors)do
   check(next(byCell),'empty regional color list was retired')
   for cell,list in pairs(byCell)do
    check(cell.enabled and cell.colors[source]==list and #list>0,'color list belongs to live tile')
    for _,field in ipairs(list)do check(field._junctionSource==source,'color field has its current source')end
   end
  end
 else -- archived renderer used one flat array per source
  for source,list in pairs(colors)do for i,field in ipairs(list)do check(field._localColorIndex==i and field._junctionSource==source,'color listener source/index')end end
 end
 local regionalVisibility=true
 for _,list in pairs(visibility)do if list[1] then regionalVisibility=false;break end end
 if regionalVisibility then
  for object,byCell in pairs(visibility)do
   check(next(byCell),'empty regional visibility list was retired')
   for cell,list in pairs(byCell)do
    check(cell.enabled and cell.visibility[object]==list and #list>0,'visibility list belongs to live tile')
   end
  end
 else -- archived renderer used one flat array per observer
  for object,list in pairs(visibility)do for i,field in ipairs(list)do check(field._localVisibility and field._localVisibility[object]==i,'visibility listener swap index')end end
 end
 if regionalColors then
  for owner,byCell in pairs(sprites)do
   check(next(byCell),'empty regional sprite index was retired')
   for cell,pool in pairs(byCell)do
    check(cell.enabled and cell.sprites[owner]==pool,'sprite pool belongs to live tile')
    for _,field in ipairs(pool)do
     check(field._junctionPoolOwner==owner,'sprite field has its current pool owner')
     check(field._junctionOwnerOp or not field:IsShown(),'free sprite fields stay hidden after reflow')
    end
   end
  end
 else
  for owner,list in pairs(sprites)do for i,field in ipairs(list)do check(field._localSpriteIndex==i and field._junctionPoolOwner==owner,'sprite owner/index')end end
 end
 local claims,membership={},{}
 for _,cell in pairs(m.cells)do if cell.enabled then
  for source,entry in pairs(cell.clipped)do
   local current=entry.active and entry.epoch==cell.epoch
   if current then claims[source]=(claims[source]or 0)+1 end
   for _,field in ipairs(entry.pool)do
    if current and field._renderEpoch==cell.epoch then
     membership[field]=source
     check(pools[source].pool[field._localPoolIndex]==field,'current fragment belongs to its source pool')
    else
     check(field._localPoolIndex==nil,'retired fragment has no source pool index')
     check(not field:IsShown(),'retired fragments stay hidden after reflow')
    end
   end
  end
  if regionalColors then for source,list in pairs(cell.colors)do
   check(colors[source] and colors[source][cell]==list,'live tile has its color listener attached')
  end end
  if regionalColors then for owner,pool in pairs(cell.sprites)do
   check(sprites[owner] and sprites[owner][cell]==pool,'live tile has its sprite pool attached')
  end end
  if regionalVisibility then for object,list in pairs(cell.visibility)do
   check(visibility[object] and visibility[object][cell]==list,'live tile has its listener attached')
  end end
  for field,following in pairs(cell.visibilityNext or {})do
   check(field._renderEpoch==cell.epoch and following._renderEpoch==cell.epoch,
     'listener links only contain current fields after reflow')
   check(field._fallbackSource==following._fallbackSource and field._fallbackBlockers==following._fallbackBlockers,
     'a listener run shares one live fallback source and blocker list')
  end
 end end
 for source,entry in pairs(pools)do
  check((entry._localClaims or 0)==(claims[source]or 0),'source claims match retained cells')
  for _,field in ipairs(entry.pool)do check(membership[field]==source,'source pool has only current fragments')end
 end
end
local function compare(a,b,points,scale)
 indexes(a);indexes(b)
 local aa,bb=fields(a),fields(b)
 for _,p in ipairs(points)do for dx=-6,6 do for dy=-6,6 do
  -- Avoid exact GPU triangle boundaries: this sampler does not implement
  -- the native rasterizer top-left coverage rule.
  local x,y=p[1]*scale+dx*1.137+.137109,p[2]*scale+dy*1.173+.173307
  local av,bv=pixel(aa,x,y),pixel(bb,x,y);local err=0
  for k=1,4 do err=math.max(err,math.abs(av[k]*(k==4 and 1 or av[4])-bv[k]*(k==4 and 1 or bv[4])))end
  check(err<1e-7,string.format('regional field differs at %.4f,%.4f: %.8f',x,y,err))
 end end end
end
if arg[1]=='--work' then
 for _,style in ipairs{1,2}do
  local scene=scenes(style)[1].groups
  local current=model(scene,style,1);local reference=model(scene,style,1,true)
  for trial=1,7 do
   local samples={}
   for i,m in ipairs(trial%2==1 and{current,reference}or{reference,current})do
    local reads=m.e.rectReads;local before=collectgarbage('count');local start=os.clock()
    local t=m.sources[8][1];t.rect[1]=t.rect[1]+(trial%2==1 and 7 or-7);m.j:Invalidate(nil,t);m.j:CommitLayout()
    local ms=(os.clock()-start)*1000
    samples[m==current and 1 or 2]={ms,m.e.rectReads-reads,collectgarbage('count')-before}
   end
   print(string.format('LOCALITY_WORK style=%d trial=%d regionalMs=%.3f fullMs=%.3f regionalReads=%d fullReads=%d regionalKB=%.3f fullKB=%.3f updated=%d cells=%d',style,trial,samples[1][1],samples[2][1],samples[1][2],samples[2][2],samples[1][3],samples[2][3],current.j.stats.localUpdated,current.j.stats.localCells))
  end
 end
 return
end
for _,style in ipairs{1,2}do for _,scale in ipairs{.75,1,1.25}do
 local scene=scenes(style)[1].groups;local current=model(scene,style,scale);local reference=model(scene,style,scale,true)
 check((current.j.stats.localCells or 0)>0,'actual regional dispatch is active')
 compare(current,reference,{{90,0},{630,0},{1440,0},{2160,0}},scale)
 local retained={};for key,cell in pairs(current.cells)do retained[key]={cell=cell,epoch=cell.epoch}end
 local priorReads={current.e.rectReads,reference.e.rectReads}
 for _,m in ipairs{current,reference}do local t=m.sources[8][1];t.rect[1]=t.rect[1]+11;m.j:Invalidate(nil,t);m.j:CommitLayout()end
 local localReads,fullReads=current.e.rectReads-priorReads[1],reference.e.rectReads-priorReads[2]
 check(localReads<fullReads/2,'unchanged geometry must not be reread')
 local kept,updated=0,0
 for key,old in pairs(retained)do if current.cells[key].epoch==old.epoch then kept=kept+1 else updated=updated+1 end;check(current.cells[key]==old.cell,'cell resource owner replaced')end
 check(kept>updated and updated>0,'local divider movement must retain most cells')
 compare(current,reference,{{90,0},{630,0},{641,0},{1440,0},{2160,0}},scale)
 for _,m in ipairs{current,reference}do m.sources[8][1]:SetVertexColor(.9,.2,.4,.4);m.sources[12][1]:Hide();m.sources[12][1]:SetVertexColor(.3,.8,.4,.6)end
 compare(current,reference,{{641,0},{990,0}},scale)
 for _,m in ipairs{current,reference}do
  m.j:Recolor(m.parents[1],.8,.3,.1,.85)
  m.j:Recolor(m.parents[8],.3,.4,.8,.4)
 end
 compare(current,reference,{{90,0},{641,0},{1440,0}},scale)
 -- The border factory supplies the same paint to the original pieces.
 for _,m in ipairs{current,reference}do
  m.sources[1][1]:SetVertexColor(.8,.3,.1,.85)
  m.sources[8][1]:SetVertexColor(.3,.4,.8,.4)
 end
 print(string.format('Regional render style=%d scale=%.2f retained=%d updated=%d rectReads=%d/%d',style,scale,kept,updated,localReads,fullReads))
 -- Register a new managed run, then remove it: only its contact area changes.
 local added={}
 for i,m in ipairs{current,reference}do
  local parent=m.new(m.e.UIParent,{0,0,5000,2000});parent.scale=scale;parent._FluxBorderStatic=true;parent.unit='player'
  local t,r=m.piece(parent,'Left',{3000-(style==1 and 9 or 9.5),-40,16,80});t.scale=scale
  local path='Interface\\AddOns\\_FluxUI\\Texture\\borders\\'..(style==1 and'Battlefield100.tga'or'ForeverMetal150Tint.tga')
  r.art=path;r.artHandle=path;t:SetTexture(path);t:SetTexCoord(table.unpack(uv.Left));t:SetVertexColor(.2,.7,.9,.85)
  added[i]=t;m.j:CommitLayout()
 end
 check(current.j.stats.localUpdated<current.j.stats.localCells/2,'new piece must not trigger a cold full build')
 compare(current,reference,{{3000,0},{1440,0}},scale)
 local beforeRemoval=current.j.stats.solves
 for i,m in ipairs{current,reference}do m.j:Forget(added[i]);added[i]:Hide();m.j:CommitLayout()end
 check(current.j.stats.solves>beforeRemoval,"removal refreshes the old registered parent, not just the detached source")
 check(current.j.stats.localUpdated<current.j.stats.localCells/2,'removed piece must not trigger a cold full build')
 compare(current,reference,{{3000,0},{1440,0}},scale)
 local all=scenes(style)
 for _,index in ipairs{2,3,4,5}do
  local c=all[index];local a=model(c.groups,style,scale);local b=model(c.groups,style,scale,true);local points={}
  for _,x in ipairs(c.points)do points[#points+1]={x,c.y or 0}end
  compare(a,b,points,scale)
 end
end end
-- Removing a high neighbour must lower the shared canvas on retained cells.
do
 local scene=scenes(1)[1].groups;scene[2].level=30
 local current=model(scene,1,1);local reference=model(scene,1,1,true)
 for _,m in ipairs{current,reference}do
  local t=m.sources[2][1];t.rect[2]=t.rect[2]+300;m.j:Invalidate(nil,t);m.j:CommitLayout()
 end
 local function Level(m)
  for _,t in ipairs(m.objects)do if t:IsShown()and t._junctionSource==m.sources[1][1] then return t:GetParent():GetFrameLevel()end end
 end
 check(Level(current)==Level(reference),'retained shared canvas drops a removed neighbour level requirement')
 compare(current,reference,{{90,0},{1440,0}},1)
end
-- A native write failure must restore every original and hide all staged cells.
do
 local scene=scenes(2)[2].groups;local m=model(scene,2,1)
 local victim,source,record
 for _,t in ipairs(m.objects)do if t._junctionSource then
  for i,list in ipairs(m.sources)do for k,owned in ipairs(list)do if owned==t._junctionSource then victim=t;source=owned;record=m.records[i][k];break end end;if victim then break end end
  if victim then break end
 end end
 check(victim~=nil,'rollback test has a prepared native field')
 local setter=victim.SetTexture
 local path='Interface\\AddOns\\_FluxUI\\Texture\\borders\\ForeverMetal150.tga'
 source:SetTexture(path);record.art=path;record.artHandle=path
 victim.SetTexture=function()error('regional intentional native failure',0)end
 m.j:Invalidate(true)
 local ok,err=pcall(function()m.j:CommitLayout()end)
 check(not ok and tostring(err):find('regional intentional native failure',1,true),'exact native failure surfaces')
 check(m.j.stats.localMode==false,'failed transaction retires the regional state')
 for _,list in ipairs(m.sources)do for _,t in ipairs(list)do check(t:GetAlpha()==.85,'rollback restores original source opacity')end end
 for _,t in ipairs(m.objects)do if t.decorative then check(not t:IsShown(),'rollback hides every staged decoration')end end
 victim.SetTexture=setter
end
-- A failed warm repaint can leave old fields in dirty cells whose geometry
-- has already been detached. Rollback must retire those fields too.
do
 local current=model(scenes(1)[1].groups,1,1)
 local source=current.sources[1][1]
 local pools=current.e.spatial.inspect()
 local previousPool=pools[source].pool
 check(#previousPool>0,'warm rollback starts with indexed fragments')
 local spatial=current.e.spatial.spatial
 local attach=spatial.Attach
 spatial.Attach=function()error('regional warm publication failure',0)end
 local divider=current.sources[8][1]
 divider.rect[1]=divider.rect[1]+11
 current.j:Invalidate(nil,divider)
 local ok,err=pcall(function()current.j:CommitLayout()end)
 check(not ok and tostring(err):find('regional warm publication failure',1,true),'warm publication failure surfaces')
 check(not current.j.stats.localMode and #previousPool==0,'warm rollback clears retained source membership')
 for _,list in ipairs(current.sources)do for _,t in ipairs(list)do check(t:GetAlpha()==.85,'warm rollback restores source opacity')end end
 for _,t in ipairs(current.objects)do if t.decorative then
  check(not t:IsShown() and not t._localPoolIndex,'warm rollback retires detached decorations')
 end end
 spatial.Attach=attach
 current.j:Invalidate(true);current.j:CommitLayout()
 check(current.j.stats.localMode,'regional renderer recovers after a warm rollback')
 indexes(current)
end
print('Actual-source regional border checks: '..checks..' passed; native GPU/FPS/combat acceptance pending.')
