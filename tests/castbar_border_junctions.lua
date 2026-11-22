-- Source-field proof for the actual two-box cast geometry and explicit facing
-- cap metadata. Samples the existing canonical alpha through actual rendered
-- fragment/triangle UVs, including valid200% frame scale with1.25/1.5 UI scale.
-- No native pixel/FPS/taint certification.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local renderer=read(arg[1]or'Core/BorderJunctions.lua')..'\nreturn function()return clipped end'
local replaced;prefix,replaced=prefix:gsub('assert%(load%(read%("Core/BorderJunctions.lua"%)',function()
 return 'e.clipped=assert(load('..string.format('%q',renderer)
end)
assert(replaced==1)
prefix=prefix:gsub('function%(%)return #queue end,e','function()return #queue end,e,B',1)
local fixture=assert(load(prefix..'\nreturn fixture','@cast-junction-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local borderSource=read('FluxBorder.lua')
local coords=assert(load(assert(borderSource:match('(local NORMALIZED_COORDS = {.-\n})'))..'\nreturn NORMALIZED_COORDS','@cast-canonical-uv','t',_G))()
local styles=assert(load('local STYLE_ART\n'..assert(borderSource:match('\n(STYLE_ART = {.-\n})'))..'\nreturn STYLE_ART',
 '@cast-style-art','t',{NORMALIZED_COORDS=coords}))()
local function sheet(name)
 local data=read('Texture/borders/'..name)
 local w=data:byte(13)+256*data:byte(14);local h=data:byte(15)+256*data:byte(16)
 check(data:byte(3)==2 and data:byte(17)==32,'raster witness uses existing uncompressed RGBA artwork')
 local function alpha(x,y)
  x=math.max(0,math.min(w-1,x));y=math.max(0,math.min(h-1,y))
  if data:byte(18)<32 then y=h-1-y end
  return data:byte(18+(y*w+x)*4+4)/255
 end
 return function(u,v)
  local x,y=u*w-.5,v*h-.5;local ix,iy=math.floor(x),math.floor(y);local fx,fy=x-ix,y-iy
  return alpha(ix,iy)*(1-fx)*(1-fy)+alpha(ix+1,iy)*fx*(1-fy)+alpha(ix,iy+1)*(1-fx)*fy+alpha(ix+1,iy+1)*fx*fy
 end
end
local sheets={sheet('Battlefield100.tga'),sheet('ForeverMetal150.tga')}
-- Use the same available artwork bytes with a separate style ID, material
-- identity and track layout to exercise future style registration.
sheets[7]=sheets[1]
local profiles={[7]={Top=8.25,Bottom=7.75,Left=9.25,Right=9.5,thickness=125,file='CastProfileFixture.tga'}}
for style,art in pairs(styles)do
 local profile=art.tracks
 profile.thickness=art.thickness
 profile.file=assert(art.texture:match('[^\\]+$'))
 profiles[style]=profile
end
-- Pinned local Forever source: UiTextureAtlasMember14234, atlas1942,
-- FileData4505182 SHA25696c4779261efb57e93294498680b95ed98549977855f3ac31707182270856423.
-- Actual first alpha column of ui-castingbar-filling-standard (209x11).
-- Its middle rows are opaque from column0; top/bottom antialiasing is kept.
local nativeFillFirstColumn={0,182,255,255,255,255,255,255,182,0,0}
-- The same pinned PNG's first eight columns. A center-row-only assertion
-- misses the rounded transparent leading cap beside the first name letter.
local nativeFillLeadingAlpha={
 {0,182,255,255,255,255,255,255},{182,255,255,255,255,255,255,255},
 {255,255,255,255,255,255,255,255},{255,255,255,255,255,255,255,255},
 {255,255,255,255,255,255,255,255},{255,255,255,255,255,255,255,255},
 {255,255,255,255,255,255,255,255},{255,255,255,255,255,255,255,255},
 {182,255,255,255,255,255,255,255},{0,182,255,255,255,255,255,255},
 {0,29,181,187,187,187,187,187},
}
local function nativeLeadingAlpha(x,y,left,bottom,width,height)
 local px,py=(x-left)*209/width-.5,(bottom+height-y)*11/height-.5
 local ix,iy=math.floor(px),math.floor(py);local dx,dy=px-ix,py-iy
 local function a(col,row)return nativeFillLeadingAlpha[math.max(0,math.min(10,row))+1][math.max(0,math.min(7,col))+1]/255 end
 return a(ix,iy)*(1-dx)*(1-dy)+a(ix+1,iy)*dx*(1-dy)+a(ix,iy+1)*(1-dx)*dy+a(ix+1,iy+1)*dx*dy
end
local runtimePrefix=assert(read('tests/timer_header_layout.lua'):match("^(.-)for _,client in ipairs{'live'"))
local runtimeEnv=setmetatable({arg={arg[2]}},{__index=_G})
local runtimeFixture,runtimeRect=assert(load(runtimePrefix..'\nreturn fixture,rect','@cast-fill-source-fixture','t',runtimeEnv))()
local function fillBounds(header,width,below,style,client)
 local _,e,ns=runtimeFixture(client)
 ns.Border.GetJoinTracks=function()return profiles[style]end
 local bar=ns.CastBar.CreateCastBar(e.CreateFrame('Frame',nil,e.UIParent),'player')
 local frame=bar:GetParent();frame.unit='player';frame.outerBorderPadding=header;frame.outerBorderAlignment=below and'TOP'or'BOTTOM'
 frame.outerBorderFrame=e.CreateFrame('Frame',nil,frame);frame.outerBorderFrame:SetSize(width,100)
 frame.atlasBorderFrame=e.CreateFrame('Frame',nil,frame);frame.atlasBorderFrame:SetSize(width,100-header)
 bar:UpdateLayout()
 local x,y,w,h=runtimeRect(bar.TimerBar)
 return x,y,w,h
end
local function alphaAt(t,x,y,sample)
 if not t:IsVisible()or t:GetEffectiveAlpha()<=0 then return 0 end
 local z=t:GetParent():GetEffectiveScale();local bx,by,bw,bh
 if t.decorative and t.point and t.size then bx=t:GetParent():GetLeft()+t.point[4];by=t:GetParent():GetBottom()+t.point[5];bw,bh=table.unpack(t.size)
 else bx,by,bw,bh=t:GetRect()end
 bx,by,bw,bh=bx*z,by*z,bw*z,bh*z
 local uv={t:GetTexCoord()};local u,v
 if t._junctionOwnerOp and not t._junctionQuad and t.vertices then
  local function vertex(i,dx,dy)local o=t.vertices[i]or{0,0};return{bx+dx*bw+o[1]*z,by+dy*bh+o[2]*z}end
  local a,b,c=vertex(1,0,1),vertex(2,0,0),vertex(3,1,1)
  local det=(b[2]-c[2])*(a[1]-c[1])+(c[1]-b[1])*(a[2]-c[2]);if math.abs(det)<1e-10 then return 0 end
  local p=((b[2]-c[2])*(x-c[1])+(c[1]-b[1])*(y-c[2]))/det
  local q=((c[2]-a[2])*(x-c[1])+(a[1]-c[1])*(y-c[2]))/det;local r=1-p-q
  if p< -1e-8 or q< -1e-8 or r< -1e-8 then return 0 end
  u=p*uv[1]+q*uv[3]+r*uv[5];v=p*uv[2]+q*uv[4]+r*uv[6]
 else
  if x<bx or x>bx+bw or y<by or y>by+bh then return 0 end
  local dx,dy=(x-bx)/bw,1-(y-by)/bh
  if #uv==4 then u=uv[1]+dx*(uv[2]-uv[1]);v=uv[3]+dy*(uv[4]-uv[3])
  else u=uv[1]*(1-dx)*(1-dy)+uv[3]*(1-dx)*dy+uv[5]*dx*(1-dy)+uv[7]*dx*dy;v=uv[2]*(1-dx)*(1-dy)+uv[4]*(1-dx)*dy+uv[6]*dx*(1-dy)+uv[8]*dx*dy end
 end
 return sample(u,v)*t:GetEffectiveAlpha()
end
for _,profile in ipairs{{20,125},{25,169},{36,300}}do
local header,totalWidth=table.unpack(profile)
local iconWidth=header+4
for _,style in ipairs{1,2,7}do for _,scale in ipairs{.75,1,1.25,2.5,3}do for _,below in ipairs{false,true}do
 local j,new,piece,flush,objects,lock,choose,_,e,border=fixture();choose(style,'class')
 local profile=profiles[style]
 border.GetJoinTracks=function()return profile end
 border.GetBorderThickness=function()return profile.thickness end
 local root=new(e.UIParent);root.unit='target';root._FluxBorderStatic=true;root.scale=scale
 local cast=new(root);cast.scale=scale;cast._FluxBorderOwner=root;cast._FluxBorderCast=true;cast._FluxBorderJunctionRole='connected'
 local topTrack,bottomTrack=profile.Top,profile.Bottom
 local bottom=below and 0 or 100-header-7+bottomTrack-topTrack
 local top=below and header+7+topTrack-bottomTrack or 100
 local function box(x,width,level,internal,color)
  local p=new(cast,{x,bottom,width,top-bottom});p.scale=scale;p.level=level;p._FluxBorderCastInternalSide=internal
  local rects={TL={x-9,top-13,16,17},TR={x+width-11,top-13,16,17},BL={x-9,bottom-5,16,16},BR={x+width-11,bottom-5,16,16},
   Top={x+7,top-13,width-18,17},Bottom={x+7,bottom-5,width-18,16},Left={x-9,bottom+11,16,top-bottom-24},Right={x+width-11,bottom+11,16,top-bottom-24}}
  local parts={}
  for _,key in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do
   local t,r=piece(p,key,rects[key]);r.art='Interface\\AddOns\\_FluxUI\\Texture\\borders\\'..profile.file
   t:SetTexture(r.art);t:SetTexCoord(table.unpack(coords[key]));t:SetVertexColor(table.unpack(color));parts[key]=t
  end
  return p,parts
 end
 local icon,ip=box(0,iconWidth,62,'Right',{.2,.6,.9,1})
 local body,bp=box(iconWidth,totalWidth-iconWidth,61,'Left',{.9,.4,.2,1})
 local solve,divider=j.Solve
 j.Solve=function(self,segments)
  local ops,reason=solve(self,segments)
  for _,s in ipairs(segments)do if s.texture==ip.Right and s.axis=='V'then divider=s.rawP/scale end end
  return ops,reason
 end
 flush();check(j.stats.fallback==nil and j.stats.triangles>0,'cast icon/body seam commits source-profile junctions')
 for _,t in ipairs{ip.TL,ip.BL,bp.TR,bp.BR}do check(t:GetAlpha()==1,'outer four cast corners retain their original rounded source art')end
 for _,t in ipairs{ip.TR,ip.BR,bp.TL,bp.BL}do check(t:GetAlpha()==0,'facing internal caps are replaced by joined fields instead of leaving rounded notches')end
 local junctions=0
 for _,o in ipairs(objects)do if o._junctionOp then
  local op=o._junctionOp;junctions=junctions+1
  for item in pairs(op.protectedCaps or{})do
   local internal=item.texture==ip.TR or item.texture==ip.BR or item.texture==bp.TL or item.texture==bp.BL
   check(not internal,'an internal corner cannot punch an exclusion hole in its T/X mesh')
  end
  check(#op.triangles>0,'each committed cast seam has actual source-field paint')
 end end
 check(junctions>=2,'top and bottom icon/body connections are both drawn')
 local function crest(y)
  for i=0,96 do
   local x=(iconWidth-11.863+i*.25)*scale;local opacity=0
   for _,t in ipairs(objects)do if t:GetObjectType()=='Texture'and type(t:GetTexture())=='string'and t:GetTexture():find('Texture\\borders\\',1,true)then
    local a=alphaAt(t,x,y*scale,sheets[style]);opacity=1-(1-opacity)*(1-a)
   end end
   check(opacity>.65,'actual drawn source fields leave no horizontal cast crest hole: header'..header..' style'..style..' scale'..scale..' below='..tostring(below)..' x='..x/scale..' y='..y..' alpha='..opacity)
  end
 end
 crest(top+4-topTrack-.17);crest(bottom+11-bottomTrack+.13)
 check(divider~=nil,'source graph identifies the actual merged icon divider core')
 local fragmentSources={}
 for source,record in pairs(e.clipped())do
  for _,field in ipairs(record.pool)do fragmentSources[field]=source end
 end
 local function sourceOpacity(x,y,first,second)
  local opacity=0
  for _,t in ipairs(objects)do
   local source=t._junctionSource or fragmentSources[t] or t
   if source==first or source==second then
    local alpha=alphaAt(t,x*scale,y*scale,sheets[style])
    opacity=1-(1-opacity)*(1-alpha)
   end
  end
  return opacity
 end
 local halfStroke=profile.thickness/100
 local iconStroke=style==1 and 2 or halfStroke
 local middle=(top+4-topTrack+bottom+11-bottomTrack)/2
 check(sourceOpacity(divider+.11,middle,ip.Right,bp.Left)>.95,'the cast divider retains its material at the center')
 if style==1 then
  check(sourceOpacity(divider-1.65,middle,ip.Right,bp.Left)>.9,'type 1 covers the icon-side shoulder of its cast divider')
 end
 for _,offset in ipairs{-iconStroke-.13,halfStroke+.13}do
  local x=divider+offset
  check(sourceOpacity(x,middle,ip.Right,bp.Left)==0,
   'cast divider excludes the outer bevel beside the icon and fill: style '..style..' scale '..scale)
 end
 for _,side in ipairs{'Top','Bottom'}do
  local crossbar=side=='Top'and top+4-topTrack or bottom+11-bottomTrack
  local inward=side=='Top'and -1 or 1
  for _,dx in ipairs{-.42,-.15,.15,.42}do
   local x,y=divider+dx,crossbar+inward*.55
   check(sourceOpacity(x,y,ip[side],bp[side])>.95 and sourceOpacity(x,y,ip.Right,bp.Left)==0,
    'horizontal rim artwork stays continuous through the cast '..side..' divider: style '..style..' scale '..scale)
  end
  check(sourceOpacity(divider+.11,crossbar+inward*3.55,ip.Right,bp.Left)>.95,
   'the vertical divider still meets the cast rim')
  if style==1 then
   check(sourceOpacity(divider-1.65,crossbar+inward*9.55,ip.Right,bp.Left)>.9,
    'type 1 keeps its icon-side shoulder where the cast divider joins the rim')
  end
  for _,offset in ipairs{-iconStroke-.13,halfStroke+.13}do
   check(sourceOpacity(divider+offset,crossbar+inward*3.55,ip.Right,bp.Left)==0,
    'the cast divider uses the same trim inside its T-junction')
  end
 end
 for _,client in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
  local fx,fy,fw,fh=fillBounds(header,totalWidth,below,style,client)
  if header==36 then
   local x,y=divider+2,fy+fh-1
   check(nativeLeadingAlpha(x,y,fx,fy,fw,fh)>.99,'production '..client..' fill covers its rounded upper leading cap beside the spell name: style'..style..' below='..tostring(below))
  end
  local y=fy+fh*.5
  for _,delta in ipairs{1.75,2,2.5}do
   local x=divider+delta;local borderAlpha=0
   for _,t in ipairs(objects)do if t:GetObjectType()=='Texture'and type(t:GetTexture())=='string'and t:GetTexture():find('Texture\\borders\\',1,true)then
    local a=alphaAt(t,x*scale,y*scale,sheets[style]);borderAlpha=1-(1-borderAlpha)*(1-a)
   end end
   local fillAlpha=x>=fx and x<=fx+fw and nativeFillFirstColumn[6]/255 or 0
   check(borderAlpha+(1-borderAlpha)*fillAlpha>.95,'production '..client..' cast fill must start beneath its actual merged divider rather than leave an unfilled trough band: style'..style..' scale'..scale..' header'..header..' x='..x..' fillLeft='..fx)
  end
 end
 local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
 for _,combat in ipairs{false,true}do
  lock(combat)
  for _=1,30 do cast:Hide();ip.Top:SetVertexColor(.4,.7,.2,1);cast:Show();flush()end
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'cast show/hide/recolor reuses complete cap-free joins without geometry work or allocation')
end end end end
print('Cast border junctions: '..checks..' checks PASS; two released styles and a simulated new profile; scales .75..3/headers20,25,36/both alignments; continuous rim and divider; rounded outside caps; static cast visibility/color including combat. Native pixels/taint/FPS pending')
