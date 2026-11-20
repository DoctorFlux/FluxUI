-- Actual FluxBorder factory/Core output sampled against canonical source art.
-- Engine geometry is modeled; no native pixel, GPU, FPS or taint certification.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local harness=assert(read('tests/border_strip_envelope.lua'):match('^(.-)local checks=0\n'))
local function replace(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(1,i-1)..b..s:sub(i+#a)end
if arg[3]then
 local marker="local model=assert(load(prefix..'\\nreturn model'"
 local at=assert(harness:find(marker,1,true))
 harness=harness:sub(1,at-1).."prefix=prefix:gsub('source%(\"FluxBorder.lua\"%)','source('..string.format('%q',arg[3])..')')\n"..harness:sub(at)
end
harness=replace(harness,"assert(load(read(activeCorePath),'@actual-strip-envelope-Core','t',e))('_FluxUI',{Border=B})",
 "e._shadowSource=assert(load(read(activeCorePath)..'\\nreturn Source','@actual-strip-envelope-Core','t',e))('_FluxUI',{Border=B})")
local factory=assert(load(harness..'\nreturn fixture','@shadow-factory-Core-model','t',_G))()
local sampler=assert(read('tests/border_strip_envelope.lua'):match('(local images={}.-)local function coverage'))
local checks=0
local function check(ok,why)checks=checks+1;assert(ok,why)end
local sample=assert(load('local check=...\n'..sampler..'\nreturn sample','@canonical-TGA-shadow-sampler','t',_G))(check)
local function capture(texture)
 local x,y,w,h=texture:GetRect();local scale=texture:GetEffectiveScale()
 local uv={texture:GetTexCoord()};if #uv==4 then uv={uv[1],uv[3],uv[1],uv[4],uv[2],uv[3],uv[2],uv[4]}end
 local offsets={};for i=1,4 do local p=texture.vertices and texture.vertices[i]or{0,0};offsets[i]={p[1]*scale,p[2]*scale}end
 local field={texture:GetTexture(),{x*scale,y*scale,w*scale,h*scale},uv,offsets,texture:GetEffectiveAlpha(),texture:GetParent():GetFrameLevel(),{texture:GetVertexColor()}}
 field.native=texture;return field
end
local cases={{name='up',bits=7,h={-100,100},v={0,100}},
 {name='down',bits=11,h={-100,100},v={-100,0}},
 {name='left',bits=13,h={-100,0},v={-100,100}},
 {name='right',bits=14,h={0,100},v={-100,100}},
 {name='cross',bits=15,h={-100,100},v={-100,100}}}
local profiles={{h='Top',v='Left',scale=.75},{h='Top',v='Left',scale=1},{h='Top',v='Left',scale=1.25},
 {h='Top',v='Right',scale=1},{h='Bottom',v='Left',scale=1},{h='Bottom',v='Right',scale=1},
 {h='Top',v='Left',scale=1,hs=.75,vs=1.25},{h='Top',v='Left',scale=1,hs=1.25,vs=.75},
 {h='Top',v='Left',scale=1,hs=.75,vs=1.25,short=true},
 {h='Bottom',v='Right',scale=1,hs=1.25,vs=.75,short=true}}
local inventory=arg[2]=='--inventory'
local guardsOnly=arg[2]=='--guards-only'
local printedDouble=false
local scenes,shadowSamples=0,0
for _,style in ipairs{1,2}do for _,profile in ipairs(profiles)do for _,mixed in ipairs{false,true}do
 local scale=profile.scale
 local scene=factory(style,8,scale,true,'hidden')
 local e,b,new=scene.e,scene.B,scene.new
 local tracks=b:GetJoinTracks();local shapes={}
 local function stroke(key,x,y,low,high,color,ownScale,level)
  ownScale=ownScale or 1;x,y,low,high=x/ownScale,y/ownScale,low/ownScale,high/ownScale
  local horizontal=key=='Top'or key=='Bottom'
  local host=new(e.UIParent);host.scale=ownScale;host.level=level or 1;host.rect={0,0,horizontal and high-low+32 or 80,not horizontal and high-low+33 or 80}
  local border=b:ApplyTo(host,0,0,0,0)
  for _,side in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do if side~=key then border[side]:Hide()end end
  if border.BackgroundFrame then border.BackgroundFrame:Hide()end
  local edge=border[key];local px,py,pw,ph=edge:GetRect()
  if horizontal then
   host.rect[3]=host.rect[3]+high-low-pw;px,py,pw,ph=edge:GetRect()
   check(math.abs(pw-(high-low))<1e-7,'factory horizontal source extent is measured from actual corner anchors')
   host.rect[1]=host.rect[1]+x+low-px
   host.rect[2]=host.rect[2]+y-(py+ph-tracks[key]/(key=='Top'and 17 or 16)*ph)
  else
   host.rect[4]=host.rect[4]+high-low-ph;px,py,pw,ph=edge:GetRect()
   check(math.abs(ph-(high-low))<1e-7,'factory vertical source extent is measured from actual corner anchors')
   host.rect[1]=host.rect[1]+x-(px+tracks[key]/16*pw)
   host.rect[2]=host.rect[2]+y+low-py
  end
  b:SetBorderColor(host,color[1],color[2],color[3],1)
  return host,edge,capture(edge)
 end
 for i,c in ipairs(cases)do
  local x,y=2400+(i-1)*400,500
  local hc={.8,.2,.1};local vc=mixed and{.1,.4,.9}or hc
  local hh,ht,hr=stroke(profile.h,x,y,c.h[1],c.h[2],hc,profile.hs)
  local vh,vt,vr=stroke(profile.v,x,y,c.v[1],c.v[2],vc,profile.vs)
  local shape={case=c,x=x*scale,y=y*scale,raw={hr,vr},hosts={hh,vh},textures={ht,vt},colors={hc,vc}}
  if profile.short then
   local start=c.h[2]>0 and 4 or-12
   local color=mixed and{.2,.8,.3}or hc
   local host,edge,raw=stroke(profile.h,x,y,start,start+8,color,1.25,20)
   shape.raw[3]=raw;shape.hosts[3]=host;shape.textures[3]=edge;shape.colors[3]=color
  end
  shapes[#shapes+1]=shape
 end
 scene.flush();scenes=scenes+1
 check(b.Junctions.stats.fallback==nil,'all five actual source topologies commit without fallback')
 for _,shape in ipairs(shapes)do
  local missing,doubled,samples=0,0,0
  local fields,ops,junctionColors={},{},{}
  for _,t in ipairs(scene.objects)do
   if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0 and t:GetTexture()
      and type(t:GetTexture())=='string'and t:GetTexture():find('Texture\\borders\\',1,true)then
    local field=capture(t);local r=field[2]
    if r[1]<shape.x+19*scale and r[1]+r[3]>shape.x-19*scale
       and r[2]<shape.y+19*scale and r[2]+r[4]>shape.y-19*scale then
     fields[#fields+1]=field
     if t._junctionOwnerOp then
      ops[t._junctionOwnerOp]=true
      local got=field[7];local allowed=false
      for i,color in ipairs(shape.colors)do if got[1]==color[1]and got[2]==color[2]and got[3]==color[3]then allowed=true;junctionColors[i]=true end end
      check(allowed and got[4]==1,'junction fields retain current source RGBA rather than a stale or global tint')
     end
    end
   end
  end
  local wanted=false;for op in pairs(ops)do if op.bits==shape.case.bits then wanted=true end end
  check(wanted,'actual renderer commits '..shape.case.name..' topology in this sampled region')
  if mixed then check(junctionColors[1]and junctionColors[2],'multi-color junction retains both source branches')end
  for ix=-24,24 do for iy=-24,24 do
   local x=shape.x+(ix*.75+.137)*scale;local y=shape.y+(iy*.75+.173)*scale
   local raw=0;for _,source in ipairs(shape.raw)do raw=math.max(raw,sample(source,x,y))end
   if raw>1/255 then
    local alpha,n=0,0
    for _,field in ipairs(fields)do local value=sample(field,x,y);alpha=math.max(alpha,value);if value>1/255 then n=n+1 end end
    shadowSamples=shadowSamples+1
    samples=samples+1;if alpha<=1e-7 then missing=missing+1 end;if n>1 then doubled=doubled+1 end
    local where=string.format('style%d scale%.2f %s/%s hs%.2f vs%.2f short%s %s mixed%s x%.3f y%.3f raw%.6f final%.6f fields%d',style,scale,profile.h,profile.v,profile.hs or 1,profile.vs or 1,tostring(profile.short==true),shape.case.name,tostring(mixed),ix*.75+.137,iy*.75+.173,raw,alpha,n)
    if inventory and n>1 and not printedDouble then
     printedDouble=true;print('DOUBLE_WITNESS '..where)
     for _,field in ipairs(fields)do if sample(field,x,y)>1/255 then
      local native=field.native;local source=native._junctionSource
      local owner='other';for i,t in ipairs(shape.textures)do if t==source then owner='source'..i end end
      local direct='none';for i,t in ipairs(shape.textures)do if t==native then direct='source'..i end end
      local r=field[2]
      print(string.format('DOUBLE_FIELD direct=%s owner=%s alpha=%.6f sourceAlpha=%s bits=%s fallback=%s box=%.3f,%.3f,%.3f,%.3f',direct,owner,field[5],tostring(source and source:GetAlpha()),tostring(native._junctionOwnerOp and native._junctionOwnerOp.bits),tostring(native._fallbackBlockers~=nil),r[1]-shape.x,r[2]-shape.y,r[3],r[4]))
     end end
     for i,t in ipairs(shape.textures)do print('DOUBLE_SOURCE '..i..' alpha='..tostring(t:GetAlpha())..' colorA='..tostring(select(4,t:GetVertexColor())))end
    end
    if not inventory and not guardsOnly then
     check(alpha>1e-7,'source shadow footprint has no transparent hole: '..where)
     check(n<=1,'one junction shadow profile is painted once: '..where)
    end
   end
  end end
  if style==2 and profile.h=='Top'and profile.v=='Left'and not profile.hs and not mixed and shape.case.bits==15 then
   local function at(offset)
    local value=0;for _,field in ipairs(fields)do value=math.max(value,sample(field,shape.x+offset*scale,shape.y+3.173*scale))end;return value
   end
   local left,right=at(-3-.0001),at(-3+.0001)
   if inventory then print(string.format('SHADOW_CONTINUITY scale=%.2f left=%.8f right=%.8f delta=%.8f',scale,left,right,math.abs(left-right)))end
   if not inventory and not guardsOnly then
    check(left>.1 and right>.1 and math.abs(left-right)<.002,'same-color canonical shadow must not jump at the zero-support boundary')
   end
  end
  if inventory then print(string.format('SHADOW_INVENTORY style=%d scale=%.2f profile=%s/%s hs=%.2f vs=%.2f short=%s shape=%s mixed=%s samples=%d missing=%d doubled=%d',style,scale,profile.h,profile.v,profile.hs or 1,profile.vs or 1,tostring(profile.short==true),shape.case.name,tostring(mixed),samples,missing,doubled))end
  -- Strong portions of each continuing arm retain that source's own RGB.
  for arm,index in ipairs{1,2}do
   local span=arm==1 and shape.case.h or shape.case.v
   local offset=span[2]>0 and 35 or-35
   local x=shape.x+(arm==1 and offset*scale or 0)
   local y=shape.y+(arm==2 and offset*scale or 0)
   local color=shape.colors[index];local found=false
   for _,t in ipairs(scene.objects)do if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0 and t:GetTexture()and type(t:GetTexture())=='string'and t:GetTexture():find('Texture\\borders\\',1,true)then
    local field=capture(t)
    if sample(field,x,y)>.5 then
     found=true;local got=field[7]
     check(got[1]==color[1]and got[2]==color[2]and got[3]==color[3],'continuing arm retains current source RGB')
    end
   end end
   check(found,'each active arm retains opaque source artwork')
  end
 end
 if profile.short and not inventory then
  for _,shape in ipairs(shapes)do check(shape.textures[3]:GetAlpha()==0,'a remotely borrowed branch source must suppress its native original')end
  local owner=shapes[1];local oldSolves,oldReads=b.Junctions.stats.solves,b.Junctions.stats.geometryReads
  b:SetBorderColor(owner.hosts[3],.6,.3,.9,1);scene.flush()
  check(owner.textures[3]:GetAlpha()==0,'recoloring a remotely borrowed source must not revive its native duplicate')
  check(b.Junctions.stats.solves==oldSolves and b.Junctions.stats.geometryReads==oldReads,'remote owner repaint stays in the prepared geometry')
  local native=owner.textures[3];local masks=native.GetNumMaskTextures
  native.GetNumMaskTextures=function()return 1 end
  b.Junctions:Invalidate(true);scene.flush()
  for _,t in ipairs(owner.textures)do check(t:GetAlpha()==1,'unavailable remote source restores its whole component to native originals')end
  check(shapes[2].textures[1]:GetAlpha()==0,'unavailable remote source does not release an unrelated junction component')
  native.GetNumMaskTextures=masks;b.Junctions:Invalidate(true);scene.flush()
  for _,t in ipairs(owner.textures)do check(t:GetAlpha()==0,'recovered remote owner rejoins with all duplicate native fields suppressed')end
 end
 local solves,reads,count=b.Junctions.stats.solves,b.Junctions.stats.geometryReads,#scene.objects
 for _=1,40 do b.Junctions:Flush()end
 check(b.Junctions.stats.solves==solves and b.Junctions.stats.geometryReads==reads and #scene.objects==count,'prepared shadow fields remain static while idle')
 b:SetBorderColor(shapes[1].hosts[1],.2,.9,.3,1);scene.flush()
 check(b.Junctions.stats.solves==solves and b.Junctions.stats.geometryReads==reads and #scene.objects==count,'live color change repaints prepared shadow fields without geometry or allocation')
 local repainted=0
 for _,t in ipairs(scene.objects)do if t._junctionSource==shapes[1].textures[1]and t._junctionOwnerOp and t:IsVisible()then
  local r,g,blue,a=t:GetVertexColor();check(r==.2 and g==.9 and blue==.3 and a==1,'live source repaint updates the existing shadow junction RGBA');repainted=repainted+1
 end end
 check(repainted>0,'live shadow repaint reaches actual prepared junction fields')
 if style==2 and not inventory then
  local t=shapes[1].textures[1];local record=assert(b._pieces[t]);local query=assert(e._shadowSource)
  local path,handle,uv=t.texture,record.artHandle,t.uv
  local original=query(t);check(original and original.support,'authored canonical handle and UV field admit measured support')
  t.texture=-9619;record.artHandle=-9619
  check(query(t).support~=nil,'an authored matching negative native handle retains canonical support')
  t.texture=-9620;check(query(t).support==nil,'foreign native handle cannot borrow registered canonical support')
  t.texture='foreign.tga';check(query(t).support==nil,'foreign texture path cannot borrow registered canonical support')
  t.texture=path;record.artHandle=handle;t.uv={0,1,0,1}
  check(query(t).support==nil,'foreign UV field cannot borrow registered canonical support')
  t.uv=uv;check(query(t).support~=nil,'canonical support recovers only after current handle and UV validation')
 end
end end end
-- Special policies are production branches, rather than ordinary miter shapes:
-- paired full aura panels keep their upper horizontal crest; a retained unit
-- meets the actual strip role through the middle strip crest band.
local specialSamples,specialScenes=0,0
for _,style in ipairs{1,2}do for _,mode in ipairs{'aura','strip-up','strip-down','strip-cross'}do for _,mixed in ipairs{false,true}do
 local scene=factory(style,8,1,true,'hidden');local e,b,new=scene.e,scene.B,scene.new
 local tracks=b:GetJoinTracks();local x,y=6000,600;local raw,hosts,colors={},{},{}
 local horizontal,vertical,horizontalRaw,horizontalRight,horizontalRightRaw,verticalRaw,losingVertical
 local function colorHost(host,color)
  b:SetBorderColor(host,color[1],color[2],color[3],1);hosts[#hosts+1]=host;colors[#colors+1]=color
 end
 if mode=='aura'then
  for i,side in ipairs{'Right','Left'}do
   local host=new(e.UIParent);host.rect={0,0,160,140};host.level=i==1 and 10 or 20;host._FluxBorderAuraPanel=true
   local border=b:ApplyTo(host,0,0,0,0);border._FluxBorderAuraPanel=true;if border.BackgroundFrame then border.BackgroundFrame:Hide()end
   local vx,_,vw=border[side]:GetRect();local _,ty,_,th=border.Top:GetRect()
   host.rect[1]=x-(vx+tracks[side]/16*vw);host.rect[2]=y-(ty+th-tracks.Top/17*th)
   colorHost(host,i==1 and{.8,.2,.1}or mixed and{.1,.4,.9}or{.8,.2,.1})
   for _,key in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do raw[#raw+1]=capture(border[key])end
   if i==1 then
    horizontal=border.Top;horizontalRaw=capture(horizontal);losingVertical=border.Right
   else
    horizontalRight=border.Top;horizontalRightRaw=capture(horizontalRight);vertical=border.Left;verticalRaw=capture(vertical)
   end
  end
 else
  local function line(key,low,high,color)
   local h=key=='Top';local host=new(e.UIParent);host.rect={0,0,h and high-low+32 or 80,not h and high-low+33 or 80}
   local border=b:ApplyTo(host,0,0,0,0)
   for _,side in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do if side~=key then
    border[side]:Hide();b.Junctions:Forget(border[side])
   end end
   -- This fixture is a sole retained stem, not an invisible complete unit
   -- shell. Hidden registered unit caps are intentionally retained in Core.
   if not h then host.unit='target';host._FluxBorderStatic=true end
   if border.BackgroundFrame then border.BackgroundFrame:Hide()end
   local edge=border[key];local px,py,pw,ph=edge:GetRect()
   if h then
    host.rect[3]=host.rect[3]+high-low-pw;px,py,pw,ph=edge:GetRect()
    host.rect[1]=x+low-px;host.rect[2]=y-(py+ph-tracks.Top/17*ph)
   else
    host.rect[4]=host.rect[4]+high-low-ph;px,py,pw,ph=edge:GetRect()
    host.rect[1]=x-(px+tracks.Left/16*pw);host.rect[2]=y+low-py
   end
   colorHost(host,color);raw[#raw+1]=capture(edge);return host,edge
  end
  local host;host,horizontal=line('Top',-100,100,{.8,.2,.1});horizontalRaw=capture(horizontal);e.FluxActionStrip=host
  local low=mode=='strip-up'and 0 or-100;local high=mode=='strip-down'and 0 or 100
  _,vertical=line('Left',low,high,mixed and{.1,.4,.9}or{.8,.2,.1});verticalRaw=capture(vertical)
 end
 scene.flush();specialScenes=specialScenes+1
 check(b.Junctions.stats.fallback==nil,'special '..mode..' source policy commits without fallback')
 local fields,crest,activeSources,patch,patchOp={},false,{},nil,nil
 for _,t in ipairs(scene.objects)do if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0 and type(t:GetTexture())=='string'and t:GetTexture():find('Texture\\borders\\',1,true)then
  local f=capture(t);local r=f[2]
  if r[1]<x+19 and r[1]+r[3]>x-19 and r[2]<y+19 and r[2]+r[4]>y-19 then
   fields[#fields+1]=f
   if t._junctionOwnerOp and t._junctionOwnerOp.auraTopCrest and math.abs(t._junctionOwnerOp.x-x)<1/64 and math.abs(t._junctionOwnerOp.y-y)<1/64 then
    crest=true;patch=t._junctionOwnerOp.rect;patchOp=t._junctionOwnerOp;activeSources[t._junctionSource]=true
   end
   local c=f[7];local allowed=false
   for _,color in ipairs(colors)do if c[1]==color[1]and c[2]==color[2]and c[3]==color[3]then allowed=true end end
   check(allowed and c[4]==1,'special policy retains current source RGBA')
  end
 end end
 check(crest,'special '..mode..' scene actually exercises its authoritative horizontal crest policy')
 if mode~='aura'then check(not next(patchOp.protectedCaps or{}),'isolated retained stem has no phantom reserved unit caps')end
 check(activeSources[horizontal]and activeSources[vertical]and(not horizontalRight or activeSources[horizontalRight]),'all active special-policy arm source identities and materials are represented')
 check(horizontal:GetAlpha()==0 and vertical:GetAlpha()==0 and(not horizontalRight or horizontalRight:GetAlpha()==0),'active special-policy native originals are suppressed')
 if losingVertical then check(losingVertical:GetAlpha()==0,'lower-priority parallel native stem is suppressed without restoring its discarded silhouette')end
 local function alphaAt(px,py)
  local alpha,n=0,0;for _,f in ipairs(fields)do local a=sample(f,px,py);alpha=math.max(alpha,a);if a>1/255 then n=n+1 end end;return alpha,n
 end
 local missing,doubled=0,0
 for ix=-24,24 do for iy=-24,24 do
  local px,py=x+ix*.75+.137,y+iy*.75+.173
  -- This oracle covers the junction replacement itself. Native caps and the
  -- discarded parallel stem have deliberately different outer silhouettes.
  -- Their union outside the node patch is not a T/X coverage requirement.
  local expected=0
  if px>=patch[1]and px<=patch[3]and py>=patch[2]and py<=patch[4]then
   if mode=='aura'then
    local h=px<x and horizontalRaw or horizontalRightRaw
    -- Canonical endpoint gutter policy extends these source profiles to the
    -- middle. Sample just inside each real source endpoint, independently of
    -- the renderer's triangle arm choice.
    local hx=px<x and(h[2][1]+h[2][3]-.25)or(h[2][1]+.25)
    expected=sample(h,hx,py)
    if py<=y then expected=math.max(expected,sample(verticalRaw,px,verticalRaw[2][2]+verticalRaw[2][4]/2))end
   else
    for _,f in ipairs(raw)do expected=math.max(expected,sample(f,px,py))end
   end
  end
  if expected>1/255 then
   local alpha,n=alphaAt(px,py);specialSamples=specialSamples+1
   if alpha<=1e-7 then missing=missing+1 end;if n>1 then doubled=doubled+1 end
   if not inventory and not guardsOnly then
    local protected=false
    for _,r in ipairs(patchOp.protectedRects or{})do if px>=r[1]and px<=r[3]and py>=r[2]and py<=r[4]then protected=true end end
    local where=string.format('style%d %s mixed%s x%.3f y%.3f raw%.6f final%.6f fields%d protected%s',style,mode,tostring(mixed),px-x,py-y,expected,alpha,n,tostring(protected))
    check(alpha>1e-7,'special policy retains the full nonzero source shadow footprint: '..where)
    check(n<=1,'special policy paints each junction shadow once: '..where)
   end
  end
 end end
 -- Compare the exposed band to the actual horizontal art away from the join;
 -- this protects the accepted aura-top fix while outside shadows are repaired.
 local offsets=mode=='aura'and{-.75,0,.75,2,3,5}or{-.75,0,.75}
 for _,dy in ipairs(offsets)do for _,dx in ipairs{-6.137,-3.137,-.137,2.137,5.137}do
  local reference=mode=='aura'and(dx<0 and horizontalRaw or horizontalRightRaw)or horizontalRaw
  local rx=x+dx
  if mode=='aura'then rx=dx<0 and(reference[2][1]+reference[2][3]-1e-6)or(reference[2][1]+1e-6)end
  local expected=sample(reference,rx,y+dy);local actual=alphaAt(x+dx,y+dy)
  if not inventory and not guardsOnly then check(math.abs(actual-expected)<1e-6,string.format('authoritative horizontal crest keeps its canonical alpha profile: style%d %s mixed%s dx%.3f dy%.3f expected%.8f actual%.8f',style,mode,tostring(mixed),dx,dy,expected,actual))end
 end end
 if inventory then print(string.format('SPECIAL_SHADOW_INVENTORY style=%d mode=%s mixed=%s missing=%d doubled=%d',style,mode,tostring(mixed),missing,doubled))end
 local solves,reads,count=b.Junctions.stats.solves,b.Junctions.stats.geometryReads,#scene.objects
 for _=1,40 do b.Junctions:Flush()end
 check(b.Junctions.stats.solves==solves and b.Junctions.stats.geometryReads==reads and #scene.objects==count,'special crest and shadow fields stay static while idle')
end end end
if inventory or guardsOnly then
 print(string.format('border junction shadows %s; shadow assertions disabled; %d other checks, %d scenes, %d footprint samples; native testing deferred',inventory and'INVENTORY ONLY'or'GUARDS ONLY',checks,scenes+specialScenes,shadowSamples+specialSamples))
else
 print(string.format('border junction shadows: %d checks PASS; %d scenes, %d source-footprint samples; actual factory/Core/TGA; native testing deferred',checks,scenes+specialScenes,shadowSamples+specialSamples))
end
