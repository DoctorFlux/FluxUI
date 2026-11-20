-- Canonical alpha support is certified from asset bytes, not an opacity cutoff.
-- Optional args: actual Core source path, actual FluxBorder source path.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s:gsub('\r\n','\n')end
local function binary(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local checks=0;local function check(value,message)checks=checks+1;assert(value,message)end
local core=read(arg[1]or'Core/BorderJunctions.lua')
local border=read(arg[2]or'FluxBorder.lua')
local path='Interface\\AddOns\\_FluxUI\\Texture\\borders\\'
local prefix=assert(read('tests/border_types.lua'):match('^(.-)\nfor _, forever'))
local hits;prefix,hits=prefix:gsub('source%("FluxBorder.lua"%)',function()return string.format('%q',border)end)
check(hits==1,'candidate override changes only the actual Border source')
local model=assert(load(prefix..'\nreturn model','@shadow-material-border-model','t',_G))()
local function sourceReader(e,b)
 e.SlashCmdList={}
 return assert(load(core..'\nreturn visibleSupport,Source','@actual-material-core','t',e))('_FluxUI',{Border=b})
end
local env,probeBorder,_,newProbe=model(true,'all')
local profiles,readProbe=sourceReader(env,probeBorder)
local probe=newProbe(env.UIParent)
function probe:GetAlpha()return 1 end
local function support(record,handle,uv)
 probeBorder._pieces[probe]=record
 probe:SetTexture(handle)
 probe:SetTexCoord(table.unpack(uv))
 return assert(readProbe(probe)).support
end
local function sameBand(value,key)return value and value[1]==profiles[key].band[1]and value[2]==profiles[key].band[2]end

local function tga(name)
 local data=binary('Texture/borders/'..name)
 local function u16(i)return data:byte(i)+256*data:byte(i+1)end
 local width,height=u16(13),u16(15);local descriptor=data:byte(18)
 check(data:byte(2)==0 and data:byte(3)==2 and data:byte(17)==32,'authored TGA is uncompressed BGRA without palette')
 check(width==256 and height==256,'canonical sheet dimensions remain256 squared')
 local offset=19+data:byte(1);local top=math.floor(descriptor/32)%2==1
 local reverseX=math.floor(descriptor/16)%2==1
 return {width=width,height=height,alpha=function(x,y)
  if x<0 or y<0 or x>=width or y>=height then return 0 end
  local sx=reverseX and width-1-x or x;local sy=top and y or height-1-y
  return data:byte(offset+(sy*width+sx)*4+3)
 end}
end
local natural,tint=tga('ForeverMetal150.tga'),tga('ForeverMetal150Tint.tga')
for y=0,255 do for x=0,255 do
 check(natural.alpha(x,y)==tint.alpha(x,y),'natural and tint sheets preserve every alpha texel')
end end
local function bilinear(image,x,y)
 local ix,iy=math.floor(x-.5),math.floor(y-.5);local fx,fy=x-.5-ix,y-.5-iy
 return image.alpha(ix,iy)*(1-fx)*(1-fy)+image.alpha(ix+1,iy)*fx*(1-fy)
  +image.alpha(ix,iy+1)*(1-fx)*fy+image.alpha(ix+1,iy+1)*fx*fy
end
for _,key in ipairs{'Top','Bottom','Left','Right'}do
 local p=assert(profiles[key]);local c=p.uv
 local x0,x1,y0,y1=c[1]*256,c[2]*256,c[3]*256,c[4]*256
 local horizontal=key=='Top'or key=='Bottom'
 local normal0,normal1=horizontal and y0 or x0,horizontal and y1 or x1
 local along0,along1=horizontal and x0 or y0,horizontal and x1 or y1
 for _,image in ipairs{natural,tint}do
  local low,high=math.huge,-math.huge
  -- Neighbor texels at each authored endpoint also influence bilinear samples.
  for along=along0-1,along1 do for normal=normal0-1,normal1 do
   local alpha=horizontal and image.alpha(along,normal)or image.alpha(normal,along)
   if alpha~=0 then low=math.min(low,normal);high=math.max(high,normal)end
  end end
  check(low~=math.huge,'edge has genuine nonzero authored paint')
  local fringeLow,fringeHigh=low-.5,high+1.5
  check(p.band[1]==(fringeLow-normal0)/(normal1-normal0)and p.band[2]==(fringeHigh-normal0)/(normal1-normal0),
   'metadata is the exact alpha support plus one-half-texel bilinear fringe: '..key)
  local witnessed=false
  for along=along0,along1,.5 do
   for normal=normal0,normal1,.5 do
    if normal<=fringeLow or normal>=fringeHigh then
     local alpha=horizontal and bilinear(image,along,normal)or bilinear(image,normal,along)
     check(alpha==0,'every along-position has exactly zero alpha outside support, including fringe boundaries: '..key)
    end
   end
   local alpha=horizontal and bilinear(image,along,fringeLow+.25)or bilinear(image,fringeLow+.25,along)
   witnessed=witnessed or alpha>0
  end
  check(witnessed,'the support cannot be moved inward past its certified fringe: '..key)
 end
 local record={key=key,art=path..'ForeverMetal150.tga',artHandle=-9619}
 check(support(record,-9619,c)==p.band,'trusted negative native texture handle retains canonical support')
 record.artHandle=9619;check(support(record,9619,c)==p.band,'trusted positive native texture handle is supported')
 record.artHandle=record.art;check(support(record,record.art,c)==p.band,'public authored path handle is supported')
 record.art=path..'ForeverMetal150Tint.tga';record.artHandle=record.art
 check(support(record,record.art,c)==p.band,'neutral tint sheet has identical support')
 check(support(record,'foreign.tga',c)==nil,'a foreign current handle never inherits authored support')
 local handle=record.artHandle;record.art='foreign.tga'
 check(support(record,handle,c)==nil,'unknown art preserves full source bounds')
 record.art=path..'Battlefield100.tga';check(support(record,handle,c)==nil,'type1 does not borrow type2 support')
 record.art=path..'ForeverMetal150.tga';record.artHandle=-9619
 local eight={c[1],c[3],c[1],c[4],c[2],c[3],c[2],c[4]}
 check(support(record,-9619,eight)==p.band,'equivalent native eight-coordinate field is recognized')
 for _,uv in ipairs{{c[1]+1/256,c[2],c[3],c[4]},{c[2],c[1],c[3],c[4]},
  {c[1],c[2],c[4],c[3]},
  {c[1]+1/256,c[3],c[1],c[4],c[2],c[3],c[2],c[4]},
  {c[2],c[3],c[2],c[4],c[1],c[3],c[1],c[4]},
  {c[1],c[4],c[1],c[3],c[2],c[4],c[2],c[3]}}do
  check(support(record,-9619,uv)==nil,'cropped/reversed four- or eight-coordinate fields keep original bounds')
 end
end

-- Exercise assignments and recoloring through the real Border factory.
for _,forever in ipairs{false,true}do
 local e,b,db,new=model(forever,'all');local m=getmetatable(new(e.UIParent)).__index
 local ids,nextID={},-9600;local privateMode=false
 local opaque=setmetatable({}, {__eq=function()error('opaque compared')end,__index=function()error('opaque indexed')end,
  __tostring=function()error('opaque formatted')end})
 e.issecretvalue=function(value)return rawequal(value,opaque)end
 function m:SetTexture(value)
  self.assignments=(self.assignments or 0)+1;self.assignedArt=value
  if privateMode then self.texture=opaque
  elseif type(value)=='string'and value:sub(1,#path)==path then
   if not ids[value]then nextID=nextID-1;ids[value]=nextID end;self.texture=ids[value]
  else self.texture=value end;self.atlas=nil
 end
 function m:GetTexture()self.handleReads=(self.handleReads or 0)+1;return self.texture end
 function m:GetAlpha()return self.color[4]or 1 end
 function m:SetAlpha(value)self.color[4]=value end
 function m:GetNumMaskTextures()return 0 end
 db.borderType=2;db.borderAccent='atlas'
 local frame=new(e.UIParent);local bf=b:ApplyTo(frame);local texture=bf.Top;local record=b._pieces[texture]
 check(record.artHandle==texture.texture and record.artHandle<0,'actual PaintPiece captures assigned native art handle')
 local _,readSource=sourceReader(e,b)
 local value=assert(readSource(texture));check(sameBand(value.support,'Top'),'actual ReadSource admits trusted canonical negative handle')
 local reads,writes=texture.handleReads,texture.assignments
 b:RefreshAllBorderTypes()
 check(texture.handleReads==reads and texture.assignments==writes,'ordinary recoloring neither rereads nor reassigns material trust')
 local trusted=record.artHandle;texture.texture=-999999
 reads=texture.handleReads;b:RefreshAllBorderTypes()
 check(record.artHandle==trusted and texture.handleReads==reads,'recolor cannot retrust a foreign replacement handle')
 value=assert(readSource(texture));check(value.support==nil and value.path==-999999,'foreign replacement remains renderable with full source bounds')
 db.borderAccent='custom';reads=texture.handleReads;writes=texture.assignments;b:RefreshAllBorderTypes()
 check(texture.assignments==writes+1 and texture.handleReads==reads+1,'genuine art transition assigns and captures exactly once')
 check(record.artHandle==texture.texture and record.artHandle~=trusted,'new material captures its current native handle')
 value=assert(readSource(texture));check(sameBand(value.support,'Top'),'tint art transition restores certified support')
 db.customAccent={r=.7,g=.2,b=.4};reads=texture.handleReads;writes=texture.assignments;b:RefreshAllBorderTypes()
 check(texture.assignments==writes and texture.handleReads==reads,'RGB-only accent changes preserve the existing trusted handle')
 texture.texture=opaque;check(readSource(texture)==nil,'private current handle fails closed before comparison')
 b:RefreshAllBorderTypes();check(record.artHandle~=opaque,'recolor does not copy a private foreign handle')
 privateMode=true;db.borderAccent='atlas';b:RefreshAllBorderTypes()
 check(record.artHandle==nil and readSource(texture)==nil,'private handle after a genuine assignment is never trusted')
 privateMode=false;db.borderAccent='custom';b:RefreshAllBorderTypes()
 check(record.artHandle==texture.texture and sameBand(assert(readSource(texture)).support,'Top'),'later public art assignment recovers without stale private trust')
 texture.texture=0;check(readSource(texture)==nil,'empty numeric texture handle cannot use support')
 texture.texture='';check(readSource(texture)==nil,'empty path cannot use support')
 texture.texture=record.artHandle;local uv=texture.uv;texture:SetTexCoord(uv[1]+1/256,uv[2],uv[3],uv[4])
 check(assert(readSource(texture)).support==nil,'actual cropped UV source remains rendered without canonical trimming')
end
-- Exercise the real factory, hooked SetTexture, committed renderer and dirty
-- preflight together. Material fast paint must not hide a support-shape change.
local harness=assert(read('tests/border_strip_envelope.lua'):match('^(.-)local checks=0\n'))
local marker="local model=assert(load(prefix..'\\nreturn model'"
local at=assert(harness:find(marker,1,true))
harness=harness:sub(1,at-1).."prefix=prefix:gsub('source%(\"FluxBorder.lua\"%)','source('..string.format('%q',arg[2]or'FluxBorder.lua')..')')\n"..harness:sub(at)
local sceneFactory=assert(load(harness..'\nreturn fixture','@shadow-live-material-factory','t',_G))()
for _,scale in ipairs{.75,1,1.25}do
 local scene=sceneFactory(2,8,scale,true,'');local b,j=scene.B,scene.B.Junctions
 local owner=scene.envelope;local texture=owner.FluxBorderFrame.Top
 check(texture:GetAlpha()==0,'live material test starts from a genuinely clipped factory source')
 local function stats()return j.stats.solves,j.stats.geometryReads or 0 end
 local function unchanged(s,r,label)
  scene.flush();check(j.stats.solves==s and(j.stats.geometryReads or 0)==r,label..' keeps prepared support geometry')
 end
 local s,r=stats();local naturalPath=texture:GetTexture()
 b:SetUnitColor(owner,{r=.2,g=.5,b=.8})
 check(texture:GetTexture()~=naturalPath,'actual per-unit class paint changes natural artwork to neutral tint')
 unchanged(s,r,'natural-to-tint file transition')
 s,r=stats();b:SetUnitColor(owner,{r=.7,g=.2,b=.4});unchanged(s,r,'RGB-only class paint')
 s,r=stats();b:SetUnitColor(owner,nil)
 check(texture:GetTexture()==naturalPath,'clearing per-unit paint restores actual natural artwork')
 unchanged(s,r,'tint-to-natural identical-alpha transition')
 local function geometry()
  local rows={}
  for _,t in ipairs(scene.objects)do if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0
      and(t._junctionOwnerOp or t._junctionUV)then
   local row={t:GetRect()};for _,v in ipairs(t.uv or{})do row[#row+1]=v end
   for i=1,4 do for _,v in ipairs(t.vertices and t.vertices[i]or{})do row[#row+1]=v end end
   for i,v in ipairs(row)do row[i]=string.format('%.12g',v)end;rows[#rows+1]=table.concat(row,',')
  end end
  table.sort(rows);return table.concat(rows,';')
 end
 local original=geometry();s,r=stats()
 texture:SetTexture(path..'Battlefield100.tga');texture:SetTexture(path..'Battlefield100.tga')
 scene.flush()
 check(j.stats.solves==s+1 and(j.stats.geometryReads or 0)==r+1,
  'same-UV foreign support replacement coalesces into one real geometry rebuild')
 s,r=stats();texture:SetTexture(naturalPath);scene.flush()
 check(j.stats.solves==s+1 and(j.stats.geometryReads or 0)==r+1,
  'trusted canonical support recovery performs exactly one real geometry rebuild')
 check(geometry()==original,'restoring support recovers the complete committed geometry')
 s,r=stats();texture:SetTexture(naturalPath);unchanged(s,r,'repeated identical trusted source')
end
print('Shadow material support: '..checks..' PASS; exact TGA alpha/half-texel margins; natural/tint parity; trusted handles; live support-change/recovery rebuilds; static tint/RGB; private/recolor/cropped UV recovery; offline only')
