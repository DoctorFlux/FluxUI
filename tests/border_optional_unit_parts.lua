-- Optional unit-part junctions: actual factory/Core output and canonical TGA.
-- Run: lua tests/border_optional_unit_parts.lua [alternateCorePath].
-- A pre-fix Core is an expected negative control; no external archive required.
-- Engine geometry is modeled; no native pixel, GPU, FPS or taint certification.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local core=read(arg[1]or'Core/BorderJunctions.lua')
local prior=core:gsub('    local unitFallbacks=self:_PrepareUnitBranchFallbacks%(meshOperations,plans,blocked,fallbackByOwner%)\n','')
prior=prior:gsub('    self:_PrepareUnitBranchFallbacks%(%a+,plans,blocked,fallbackByOwner%)\n','')
prior=prior:gsub('    self:_TrimUnitBranchFallbackRects%(%a+,plans,blocked%)\n','')
local coreSources={baseline=prior,candidate=core}
local harness=assert(read('tests/border_strip_envelope.lua'):match('^(.-)local checks=0\n'))
local function replace(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(1,i-1)..b..s:sub(i+#a)end
if arg[3]then
 local marker="local model=assert(load(prefix..'\\nreturn model'"
 local at=assert(harness:find(marker,1,true))
 harness=harness:sub(1,at-1).."prefix=prefix:gsub('source%(\"FluxBorder.lua\"%)','source('..string.format('%q',arg[3])..')')\n"..harness:sub(at)
end
harness=replace(harness,"assert(load(read(activeCorePath),'@actual-strip-envelope-Core','t',e))('_FluxUI',{Border=B})",
 "e._shadowSource=assert(load(coreSources[activeCorePath]..'\\nreturn Source','@actual-strip-envelope-Core','t',e))('_FluxUI',{Border=B})")
local fixtureEnv=setmetatable({coreSources=coreSources},{__index=_G});fixtureEnv._G=fixtureEnv
local factory=assert(load(harness..'\nreturn fixture','@shadow-factory-Core-model','t',fixtureEnv))()
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
local images={}
local function image(path)
 local old=images[path];if old then return old end
 local localPath=path:gsub('Interface\\AddOns\\_FluxUI\\',''):gsub('\\','/')
 local f=assert(io.open(localPath,'rb'));local data=f:read('*a');f:close()
 local function word(i)local a,b=data:byte(i,i+1);return a+256*b end
 local id,cmap,kind=data:byte(1,3);local w,h=word(13),word(15);local depth,descriptor=data:byte(17,18)
 check(cmap==0 and kind==2 and depth==32,'canonical artwork uses the expected raw32-bit TGA source')
 old={w=w,h=h,descriptor=descriptor,data=data,start=19+id};images[path]=old;return old
end
local function sampleRGBA(t,x,y)
 local path,box,uv,offset,alpha=t[1],t[2],t[3],t[4],t[5];local bx,by,w,h=table.unpack(box)
 if not w or not h then return 0,0,0,0 end
 local p={{bx+offset[1][1],by+h+offset[1][2]},{bx+offset[2][1],by+offset[2][2]},
  {bx+w+offset[3][1],by+h+offset[3][2]},{bx+w+offset[4][1],by+offset[4][2]}}
 for _,ids in ipairs{{1,2,3},{3,2,4}}do
  local a,b,c=p[ids[1]],p[ids[2]],p[ids[3]];local den=(b[2]-c[2])*(a[1]-c[1])+(c[1]-b[1])*(a[2]-c[2])
  if math.abs(den)>1e-10 then
   local q=((b[2]-c[2])*(x-c[1])+(c[1]-b[1])*(y-c[2]))/den
   local r=((c[2]-a[2])*(x-c[1])+(a[1]-c[1])*(y-c[2]))/den;local s=1-q-r
   if math.min(q,r,s)>=-1e-8 then
    local u=q*uv[2*ids[1]-1]+r*uv[2*ids[2]-1]+s*uv[2*ids[3]-1]
    local v=q*uv[2*ids[1]]+r*uv[2*ids[2]]+s*uv[2*ids[3]]
    local im=image(path);local fx,fy=u*im.w-.5,v*im.h-.5;local ix,iy=math.floor(fx),math.floor(fy);local dx,dy=fx-math.floor(fx),fy-math.floor(fy)
    local function pixel(cx,cy,ch)
     cx=math.max(0,math.min(im.w-1,cx));cy=math.max(0,math.min(im.h-1,cy))
     if math.floor(im.descriptor/32)%2==0 then cy=im.h-1-cy end
     if math.floor(im.descriptor/16)%2==1 then cx=im.w-1-cx end
     return im.data:byte(im.start+(cy*im.w+cx)*4+ch)/255
    end
    local out={};local color=t[7]or{1,1,1,1}
    for ch=0,3 do
     local value=(1-dy)*((1-dx)*pixel(ix,iy,ch)+dx*pixel(ix+1,iy,ch))+dy*((1-dx)*pixel(ix,iy+1,ch)+dx*pixel(ix+1,iy+1,ch))
     out[ch+1]=value*(ch==3 and alpha or color[ch+1])
    end
    return table.unpack(out)
   end
  end
 end
 return 0,0,0,0
end

local paths={'baseline','candidate'}
local cases={{name='class-down',h={-100,100},v={-36,0}},{name='class-up',h={-100,100},v={0,36}},
 {name='resource-left',h={-36,0},v={-100,100}},{name='resource-right',h={0,36},v={-100,100}},
 {name='resource-cross',h={-100,100},v={-100,100}}}
local totalSamples,baselineMissing,candidateMissing,worstMissing=0,0,0,0
local function fields(scene,x,y,scale)
 local out={}
 for _,t in ipairs(scene.objects)do
  if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0 and type(t:GetTexture())=='string'and t:GetTexture():find('Texture\\borders\\',1,true)then
   local f=capture(t);local r=f[2]
   if r[1]<x*scale+22*scale and r[1]+r[3]>x*scale-22*scale and r[2]<y*scale+22*scale and r[2]+r[4]>y*scale-22*scale then out[#out+1]=f end
  end
 end
 return out
end
local function signature(fs)
 local out={}
 for _,f in ipairs(fs)do
  local row={f[1]};local function add(n)row[#row+1]=type(n)=='number'and string.format('%.11g',n)or tostring(n)end
  for _,k in ipairs{2,3}do for _,n in ipairs(f[k])do add(n)end end
  for _,p in ipairs(f[4])do for _,n in ipairs(p)do add(n)end end
  add(f[5]);add(f[6]);for _,n in ipairs(f[7])do add(n)end
  out[#out+1]=table.concat(row,',')
 end
 table.sort(out);return table.concat(out,'|')
end
local function build(style,scale,c,path)
 local scene=factory(style,8,scale,true,'hidden',path);local e,b,new=scene.e,scene.B,scene.new
 local tracks=b:GetJoinTracks();local x,y=4000,500
 local function stroke(key,low,high,color)
  local h=key=='Top';local host=new(e.UIParent);host.unit='target';host._FluxBorderStatic=true
  host.rect={0,0,h and high-low+32 or 80,not h and high-low+33 or 80}
  local border=b:ApplyTo(host,0,0,0,0)
  for _,side in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do if side~=key then border[side]:Hide();b.Junctions:Forget(border[side])end end
  border.BackgroundFrame:Hide();local t=border[key];local px,py,pw,ph=t:GetRect()
  if h then
   host.rect[3]=host.rect[3]+high-low-pw;px,py,pw,ph=t:GetRect();host.rect[1]=x+low-px;host.rect[2]=y-(py+ph-tracks.Top/17*ph)
  else
   host.rect[4]=host.rect[4]+high-low-ph;px,py,pw,ph=t:GetRect();host.rect[1]=x-(px+tracks.Left/16*pw);host.rect[2]=y+low-py
  end
  b:SetBorderColor(host,table.unpack(color));return t,capture(t)
 end
 local h,hr=stroke('Top',c.h[1],c.h[2],{.8,.2,.1,1})
 local v,vr=stroke('Left',c.v[1],c.v[2],{.1,.4,.9,1})
 -- Resource-less present units use alpha zero; class/spec absence uses Hide.
 if c.name:find('class',1,true)then v:Hide()else h:SetAlpha(0)end
 scene.flush()
 return scene,h,v,hr,vr,x,y
end
local function compareRaw(scene,raw,x,y,scale,strict)
 local fs=fields(scene,x,y,scale);local missing,doubled,maxError,maxMissing=0,0,0,0
 for ix=-28,28 do for iy=-28,28 do
  local px,py=(x+ix*.7+.137)*scale,(y+iy*.7+.173)*scale
  local er,eg,eb,ea=sampleRGBA(raw,px,py)
  if ea>1/255 then
   totalSamples=totalSamples+1;local ar,ag,ab,aa,n=0,0,0,0,0
   for _,f in ipairs(fs)do local r,g,b,a=sampleRGBA(f,px,py);if a>1/255 then n=n+1 end;if a>aa then ar,ag,ab,aa=r,g,b,a end end
   if aa<=1e-7 then missing=missing+1;maxMissing=math.max(maxMissing,ea)end
   if n>1 then doubled=doubled+1 end
   maxError=math.max(maxError,math.abs(aa-ea),math.abs(ar*aa-er*ea),math.abs(ag*aa-eg*ea),math.abs(ab*aa-eb*ea))
  end
 end end
 if strict then check(missing==0 and doubled==0,'hidden footprint has one live source');check(maxError<1e-7,'hidden full premultiplied RGBA equals the uncut source')end
 return missing,doubled,maxError,maxMissing
end
for _,style in ipairs{1,2}do for _,scale in ipairs{.75,1,1.25}do for _,c in ipairs(cases)do
 local scenes={};local visible={};local sums={}
 for version,path in ipairs(paths)do
  local scene,h,v,hr,vr,x,y=build(style,scale,c,path);scenes[version]=scene
  local hidden=c.name:find('class',1,true)and v or h;local raw=hidden==v and hr or vr
  local solves,reads,count=scene.B.Junctions.stats.solves,scene.B.Junctions.stats.geometryReads,#scene.objects
  local m,d,err,w=compareRaw(scene,raw,x,y,scale,version==2)
  if version==1 then baselineMissing=baselineMissing+m;worstMissing=math.max(worstMissing,w)else candidateMissing=candidateMissing+m end
  hidden:Show();hidden:SetAlpha(1);scene.flush();visible[version]=signature(fields(scene,x,y,scale))
  hidden:Hide();scene.flush();compareRaw(scene,raw,x,y,scale,version==2)
  hidden:Show();hidden:SetAlpha(0);scene.flush();compareRaw(scene,raw,x,y,scale,version==2)
  check(scene.B.Junctions.stats.solves==solves and scene.B.Junctions.stats.geometryReads==reads and #scene.objects==count,'all availability transitions remain prepared/static')
  sums[version]=string.format('missing%d maxerr%.9g worstMissingAlpha%.9g',m,err,w)
 end
 check(visible[1]==visible[2],'visible active mesh path/UV/geometry/level/RGBA remains exactly unchanged')
end end end
print(string.format('UNIT_FALLBACK checks=%d samples=%d baselineMissing=%d candidateMissing=%d worstMissingAlpha=%.9g',checks,totalSamples,baselineMissing,candidateMissing,worstMissing))

do
local function build(style,scale,c,path)
 local scene=factory(style,8,scale,true,'hidden',path);local e,b,new=scene.e,scene.B,scene.new
 local tracks=b:GetJoinTracks();local x,y=4000,500
 local function stroke(key,low,high,color,level)
  local h=key=='Top';local host=new(e.UIParent);host.unit='target';host._FluxBorderStatic=true;host.level=level or 20
  host.rect={0,0,h and high-low+32 or 80,not h and high-low+33 or 80}
  local border=b:ApplyTo(host,0,0,0,0)
  for _,side in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do if side~=key then border[side]:Hide();b.Junctions:Forget(border[side])end end
  border.BackgroundFrame:Hide();local t=border[key];local px,py,pw,ph=t:GetRect()
  if h then
   host.rect[3]=host.rect[3]+high-low-pw;px,py,pw,ph=t:GetRect();host.rect[1]=x+low-px;host.rect[2]=y-(py+ph-tracks.Top/17*ph)
  else
   host.rect[4]=host.rect[4]+high-low-ph;px,py,pw,ph=t:GetRect();host.rect[1]=x-(px+tracks.Left/16*pw);host.rect[2]=y+low-py
  end
  b:SetBorderColor(host,table.unpack(color));return t,capture(t),host
 end
 local h,hr=stroke('Top',c.h[1],c.h[2],{.8,.2,.1,1})
 local v,vr=stroke('Left',c.v[1],c.v[2],{.1,.4,.9,1},40)
 local backup=stroke('Left',-8,-4,{.3,.8,.2,1},30)
 -- Resource-less present units use alpha zero; class/spec absence uses Hide.
 if c.name:find('class',1,true)then v:Hide()else h:SetAlpha(0)end
 scene.flush()
 return scene,h,v,hr,vr,x,y,backup
end

for _,style in ipairs{1,2}do
 local scene,h,v,hr,vr,x,y,backup=build(style,1,{name='class-down',h={-100,100},v={-36,0}},'candidate')
 local j=scene.B.Junctions;local solves,reads,count=j.stats.solves,j.stats.geometryReads,#scene.objects
 local function probe()
  local fs=fields(scene,x,y,1);local missing,doubled=0,0
  for ix=-18,18 do for iy=-18,18 do
   local px,py=x+ix*.7+.137,y+iy*.7+.173;local _,_,_,expected=sampleRGBA(hr,px,py)
   if expected>1/255 then
    local actual,n=0,0;for _,f in ipairs(fs)do local _,_,_,a=sampleRGBA(f,px,py);actual=math.max(actual,a);if a>1/255 then n=n+1 end end
    if actual<1e-7 then missing=missing+1 end;if n>1 then doubled=doubled+1 end
   end
  end end
  check(missing==0 and doubled==0,'partial parallel backup neither punches holes nor doubles the H profile')
 end
 probe();backup:Hide();scene.flush();probe()
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #scene.objects==count,'partial-backup visibility is static')
end
end

do
local function build(style,scale,c,path)
 local scene=factory(style,8,scale,true,'hidden',path);local e,b,new=scene.e,scene.B,scene.new
 local tracks=b:GetJoinTracks();local x,y=4000,500
 local function stroke(key,low,high,color,level)
  local h=key=='Top';local host=new(e.UIParent);host.unit='target';host._FluxBorderStatic=true;host.level=level or 20
  host.rect={0,0,h and high-low+32 or 80,not h and high-low+33 or 80}
  local border=b:ApplyTo(host,0,0,0,0)
  for _,side in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do if side~=key then border[side]:Hide();b.Junctions:Forget(border[side])end end
  border.BackgroundFrame:Hide();local t=border[key];local px,py,pw,ph=t:GetRect()
  if h then
   host.rect[3]=host.rect[3]+high-low-pw;px,py,pw,ph=t:GetRect();host.rect[1]=x+low-px;host.rect[2]=y-(py+ph-tracks.Top/17*ph)
  else
   host.rect[4]=host.rect[4]+high-low-ph;px,py,pw,ph=t:GetRect();host.rect[1]=x-(px+tracks.Left/16*pw);host.rect[2]=y+low-py
  end
  b:SetBorderColor(host,table.unpack(color));return t,capture(t),host
 end
 local h,hr=stroke('Top',c.h[1],c.h[2],{.8,.2,.1,1},40)
 local v,vr=stroke('Left',c.v[1],c.v[2],{.1,.4,.9,1},40)
 local backup,backupRaw=stroke('Top',c.h[1],c.h[2],{.3,.8,.2,1},30)
 -- Resource-less present units use alpha zero; class/spec absence uses Hide.
 if c.name:find('class',1,true)then v:Hide()else h:SetAlpha(0)end
 scene.flush()
 return scene,h,v,hr,vr,x,y,backup,backupRaw
end

for _,style in ipairs{1,2}do
 local scene,h,v,hr,vr,x,y,backup,raw=build(style,1,{name='class-down',h={-100,100},v={-36,0}},'candidate')
 local j=scene.B.Junctions;local solves,reads,count=j.stats.solves,j.stats.geometryReads,#scene.objects
 h:Hide();scene.flush();compareRaw(scene,raw,x,y,1,true)
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #scene.objects==count,'own-axis backup restores complete current RGBA statically')
end
end

do
local function build(style,scale,c,path)
 local scene=factory(style,8,scale,true,'hidden',path);local e,b,new=scene.e,scene.B,scene.new
 local tracks=b:GetJoinTracks();local x,y=4000,500
 local function stroke(key,low,high,color,level)
  local h=key=='Top';local host=new(e.UIParent);host._FluxBorderStatic=true;host.level=level or 20
  host.rect={0,0,h and high-low+32 or 80,not h and high-low+33 or 80}
  local border=b:ApplyTo(host,0,0,0,0)
  for _,side in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do if side~=key then border[side]:Hide();b.Junctions:Forget(border[side])end end
  border.BackgroundFrame:Hide();local t=border[key];local px,py,pw,ph=t:GetRect()
  if h then
   host.rect[3]=host.rect[3]+high-low-pw;px,py,pw,ph=t:GetRect();host.rect[1]=x+low-px;host.rect[2]=y-(py+ph-tracks.Top/17*ph)
  else
   host.rect[4]=host.rect[4]+high-low-ph;px,py,pw,ph=t:GetRect();host.rect[1]=x-(px+tracks.Left/16*pw);host.rect[2]=y+low-py
  end
  b:SetBorderColor(host,table.unpack(color));return t,capture(t),host
 end
 local h,hr=stroke('Top',c.h[1],c.h[2],{.8,.2,.1,1})
 local v,vr=stroke('Left',c.v[1],c.v[2],{.1,.4,.9,1},40)
 local backup,backupRaw=stroke('Left',-8,-4,{.3,.8,.2,1},30)
 -- Resource-less present units use alpha zero; class/spec absence uses Hide.
 if c.name:find('class',1,true)then v:Hide()else h:SetAlpha(0)end
 scene.flush()
 return scene,h,v,hr,vr,x,y,backup,backupRaw
end

for _,style in ipairs{1,2}do
 local signatures={}
 for version,path in ipairs(paths)do
 local scene,h,v,hr,vr,x,y,backup,raw=build(style,1,{name='class-down',h={-100,100},v={-36,0}},path)
 h:Hide();scene.flush();signatures[version]=signature(fields(scene,x,y,1));local missing,_,error=compareRaw(scene,raw,x,y,1,false);check(missing==0 and error<1e-7,'ineligible policy retains complete original source RGBA')
 end
 check(signatures[1]==signatures[2],'non-unit policy keeps exact prior rendered fields, including preexisting overlap')
end
end

do
local function build(style,scale,c,path)
 local scene=factory(style,8,scale,true,'hidden',path);local e,b,new=scene.e,scene.B,scene.new
 local tracks=b:GetJoinTracks();local x,y=4000,500
 local function stroke(key,low,high,color,level)
  local h=key=='Top';local host=new(e.UIParent);host.unit='target';host._FluxBorderStatic=true;host.level=level or 20
  host.rect={0,0,h and high-low+32 or 80,not h and high-low+33 or 80}
  local border=b:ApplyTo(host,0,0,0,0)
  for _,side in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do if side~=key then border[side]:Hide();b.Junctions:Forget(border[side])end end
  border.BackgroundFrame:Hide();local t=border[key];local px,py,pw,ph=t:GetRect()
  if h then
   host.rect[3]=host.rect[3]+high-low-pw;px,py,pw,ph=t:GetRect();host.rect[1]=x+low-px;host.rect[2]=y-(py+ph-tracks.Top/17*ph)
  else
   host.rect[4]=host.rect[4]+high-low-ph;px,py,pw,ph=t:GetRect();host.rect[1]=x-(px+tracks.Left/16*pw);host.rect[2]=y+low-py
  end
  b:SetBorderColor(host,table.unpack(color));return t,capture(t),host
 end
 local h,hr=stroke('Top',c.h[1],c.h[2],{.8,.2,.1,1})
 local h2=stroke('Top',0,100,{.7,.1,.4,1},20)
 local v,vr=stroke('Left',c.v[1],c.v[2],{.1,.4,.9,1},40)
 local backup,backupRaw=stroke('Left',-8,-4,{.3,.8,.2,1},30)
 -- Resource-less present units use alpha zero; class/spec absence uses Hide.
 if c.name:find('class',1,true)then v:Hide()else h:SetAlpha(0)end
 scene.flush()
 return scene,h,v,hr,vr,x,y,backup,backupRaw,h2
end

for _,style in ipairs{1,2}do
 local signatures={}
 for version,path in ipairs(paths)do
 local scene,h,v,hr,vr,x,y,backup,raw,h2=build(style,1,{name='class-down',h={-100,0},v={-36,0}},path)
 local maxH=0
 for _,t in ipairs(scene.objects)do local op=t._junctionOp;if op and op.bits and math.abs(op.x-x)<.1 and math.abs(op.y-y)<.1 then
  local unique,n={},0;for _,tri in ipairs(op.triangles)do if tri.arm<=2 and not unique[tri.texture]then unique[tri.texture]=true;n=n+1 end end;maxH=math.max(maxH,n)
 end end
 check(maxH>=2,'ambiguous unit control really has two horizontal primary sources')
 h:Hide();h2:Hide();scene.flush();signatures[version]=signature(fields(scene,x,y,1));local missing,_,error=compareRaw(scene,raw,x,y,1,false);check(missing==0 and error<1e-7,'ineligible policy retains complete original source RGBA')
 end
 check(signatures[1]==signatures[2],'ambiguous-unit policy keeps exact prior rendered fields, including preexisting overlap')
end
end

for _,style in ipairs{1,2}do
 local scene,h,v,hr,vr,x,y=build(style,1,{name='class-down',h={-100,100},v={-36,0}},paths[2])
 local j=scene.B.Junctions
 compareRaw(scene,hr,x,y,1,true)
 local old=signature(fields(scene,x,y,1));j:Invalidate(true);scene.flush()
 check(signature(fields(scene,x,y,1))==old,'warm forced generation keeps exact mesh/gates');compareRaw(scene,hr,x,y,1,true)
 local solves,reads,count=j.stats.solves,j.stats.geometryReads,#scene.objects
 for _,t in ipairs{h,v}do local host=t:GetParent():GetParent();host.rect[1]=host.rect[1]+4 end
 j:Invalidate(true);scene.flush();hr[2][1]=hr[2][1]+4
 compareRaw(scene,hr,x+4,y,1,true)
 check(j.stats.solves==solves+1,'actual moved layout recomputes once')
 local afterSolves,afterReads,afterCount=j.stats.solves,j.stats.geometryReads,#scene.objects
 for _=1,10 do v:Show();v:SetAlpha(1);v:Hide();scene.flush()end
 check(j.stats.solves==afterSolves and j.stats.geometryReads==afterReads and #scene.objects==afterCount,'post-layout visibility remains static')
 local r={v:GetRect()};local rect={r[1],r[2],r[1]+r[3],r[2]+r[4]};local root={}
 local function plan()
  local record={};for k,value in pairs(scene.B._pieces[v])do record[k]=value end
  local source=scene.e._shadowSource(v);local uv={table.unpack(source.uv)}
  return {root=root,item={record=record,rect={table.unpack(rect)}},source={path=source.path,uv=uv,support=source.support}}
 end
 local a,b=plan(),plan()
 check(j:_UnitFallbackProfileMatches(a,b),'same authored canonical profile trusted')
 b.item.rect[1]=b.item.rect[1]+.00001;b.item.rect[3]=b.item.rect[3]+.00001
 check(j:_UnitFallbackProfileMatches(a,b),'native float roundoff retains canonical equivalence')
 b=plan();b.item.rect[1]=b.item.rect[1]+.25;b.item.rect[3]=b.item.rect[3]+.25
 check(not j:_UnitFallbackProfileMatches(a,b),'meaningful normal shift preserves conservative path')
 b=plan();b.item.rect[3]=b.item.rect[1]+(b.item.rect[3]-b.item.rect[1])*.75
 check(not j:_UnitFallbackProfileMatches(a,b),'mixed normal scale preserves conservative path')
 b=plan();b.root={};check(not j:_UnitFallbackProfileMatches(a,b),'different component roots isolated')
 b=plan();b.item.record.key='TL';check(not j:_UnitFallbackProfileMatches(a,b),'rounded caps never inherit straight cuts')
 b=plan();b.source.support=nil;b.item.record.artHandle='foreign';check(not j:_UnitFallbackProfileMatches(a,b),'foreign handle cannot authorize crop')
 b=plan();b.source.support=nil;b.source.uv[1]=b.source.uv[1]+1/256
 check(not j:_UnitFallbackProfileMatches(a,b),'cropped or foreign UV cannot authorize type1 fallback')
 print('CACHE_GUARDS style'..style..' PASS; warm/current/moved/static/profile/unknown/cap guard')
end
print('Unit fallback cache/profile guards: '..checks..' checks PASS; actual source producer/factory/Core, no native acceptance claim')

-- Pure current-pass bookkeeping cannot retain an old admission marker or exceed
-- the per-piece budget before any native writer runs.
do
 local scene,h,v=build(1,1,{name='class-down',h={-100,100},v={-36,0}},'candidate')
 local j=scene.B.Junctions;local op
 for _,t in ipairs(scene.objects)do if t._junctionOwnerOp and t._junctionSource==h then op=t._junctionOwnerOp;break end end
 check(op~=nil,'real renderer operation is available for budget/reset controls')
 op._unitBranchPrepared=true;j:_PrepareUnitBranchFallbacks({op},{},{[op.root]=true},{})
 check(op._unitBranchPrepared==nil,'blocked current operation clears stale admission')
 local old=j.limits.fragmentsPerPiece;j.limits.fragmentsPerPiece=0
 local plans={};for _,t in ipairs{h,v}do local x,y,w,hh=t:GetRect();plans[t]={root=op.root,item={texture=t,record=scene.B._pieces[t],rect={x,y,x+w,y+hh}},source=scene.e._shadowSource(t),rects={},fallbackRects={}}end
 local blocked={};j:_PrepareUnitBranchFallbacks({op},plans,blocked,{})
 check(blocked[op.root]~=nil and not op._unitBranchPrepared,'visibility budget blocks incomplete admission')
 j.limits.fragmentsPerPiece=old
end

-- Unknown/cropped parallel profiles retain the entire prior policy. Max RGBA
-- alone cannot detect duplicate shadows, so compare active fields and native
-- source-over counts too; do not add inactive mesh resources for a rejected op.
do
local function build(style,scale,c,path)
 local scene=factory(style,8,scale,true,'hidden',path);local e,b,new=scene.e,scene.B,scene.new
 local tracks=b:GetJoinTracks();local x,y=4000,500
 local function stroke(key,low,high,color,level)
  local h=key=='Top';local host=new(e.UIParent);host.unit='target';host._FluxBorderStatic=true;host.level=level or 20
  host.rect={0,0,h and high-low+32 or 80,not h and high-low+33 or 80}
  local border=b:ApplyTo(host,0,0,0,0)
  for _,side in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do if side~=key then border[side]:Hide();b.Junctions:Forget(border[side])end end
  border.BackgroundFrame:Hide();local t=border[key];local px,py,pw,ph=t:GetRect()
  if h then
   host.rect[3]=host.rect[3]+high-low-pw;px,py,pw,ph=t:GetRect();host.rect[1]=x+low-px;host.rect[2]=y-(py+ph-tracks.Top/17*ph)
  else
   host.rect[4]=host.rect[4]+high-low-ph;px,py,pw,ph=t:GetRect();host.rect[1]=x-(px+tracks.Left/16*pw);host.rect[2]=y+low-py
  end
  b:SetBorderColor(host,table.unpack(color));return t,capture(t),host
 end
 local h,hr=stroke('Top',c.h[1],c.h[2],{.8,.2,.1,1})
 local v,vr=stroke('Left',c.v[1],c.v[2],{.1,.4,.9,1},40)
 local backup,backupRaw=stroke('Left',-8,-4,{.3,.8,.2,1},30)
 local uv={backup:GetTexCoord()};assert(#uv==4);backup:SetTexCoord(uv[1]+1/256,uv[2]+1/256,uv[3],uv[4]);backupRaw=capture(backup)
 -- Resource-less present units use alpha zero; class/spec absence uses Hide.
 if c.name:find('class',1,true)then v:Hide()else h:SetAlpha(0)end
 scene.flush()
 return scene,h,v,hr,vr,x,y,backup,backupRaw
end

for _,style in ipairs{1,2}do
 local got={}
 for version,path in ipairs(paths)do
  local scene,h,v,hr,vr,x,y,backup,raw=build(style,1,{name='class-down',h={-100,100},v={-36,0}},path)
  local j=scene.B.Junctions;local solves,reads,count=j.stats.solves,j.stats.geometryReads,#scene.objects
  h:Hide();scene.flush();local fs=fields(scene,x,y,1)
  local samples,doubled,overdraw,maxError=0,0,0,0
  for ix=-18,18 do for iy=-18,18 do
   local px,py=x+ix*.7+.137,y+iy*.7+.173;local er,eg,eb,ea=sampleRGBA(raw,px,py)
   if ea>1/255 then
    samples=samples+1;local actual={0,0,0,0};local n,composite=0,0
    for _,f in ipairs(fs)do local r,g,b,a=sampleRGBA(f,px,py);composite=1-(1-composite)*(1-a);if a>1/255 then n=n+1 end;if a>actual[4]then actual={r,g,b,a}end end
    if n>1 then doubled=doubled+1 end;if composite-ea>1e-7 then overdraw=overdraw+1 end
    maxError=math.max(maxError,math.abs(actual[4]-ea),math.abs(actual[1]*actual[4]-er*ea),math.abs(actual[2]*actual[4]-eg*ea),math.abs(actual[3]*actual[4]-eb*ea))
   end
  end end
  check(samples>0 and samples<=138 and maxError<1e-7,'finite foreign backup keeps its complete prior source RGBA')
  local regions,inactive=0,0
  for _,t in ipairs(scene.objects)do if t._junctionOwnerOp and t:GetObjectType()=='Texture'then
   local f=capture(t);local r=f[2]
   if r[1]<x+22 and r[1]+r[3]>x-22 and r[2]<y+22 and r[2]+r[4]>y-22 then regions=regions+1;if t:GetEffectiveAlpha()<=0 then inactive=inactive+1 end end
  end end
  got[version]={signature=signature(fs),samples=samples,doubled=doubled,overdraw=overdraw,regions=regions,inactive=inactive}
  check(j.stats.solves==solves and j.stats.geometryReads==reads and #scene.objects==count,'foreign-profile transitions require no geometry work or allocations')
 end
 check(got[1].signature==got[2].signature,'foreign backup preserves exact prior active fields')
 for _,k in ipairs{'samples','doubled','overdraw','regions','inactive'}do check(got[1][k]==got[2][k],'foreign backup preserves prior '..k)end
 print(string.format('FOREIGN_PROFILE style%d samples%d doubled%d overdraw%d regions%d inactive%d unchanged',style,got[2].samples,got[2].doubled,got[2].overdraw,got[2].regions,got[2].inactive))
end
end
print('Optional unit parts: '..checks..' checks PASS; actual factory/Core/TGA, four Ts+X, exact hidden RGBA, active mesh parity, partial/own parallel backups, eligibility, current generation, budgets; native validation pending')
