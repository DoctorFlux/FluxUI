-- Actual current-source validation is shared only during the pure planning
-- phase. Native getter counts and exact output parity are not FPS measurements.
local sourcePath=arg[1]or'Core/BorderJunctions.lua'
local measure=arg[2]=='--measure'
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function corrected(v,m)if not measure then check(v,m)end end
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local core=read(sourcePath)..'\nreturn {Source=Source,memo=function()return sourceReadPlan end}'
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
prefix=prefix:gsub('assert%(load%(read%("Core/BorderJunctions.lua"%),"@Core/BorderJunctions.lua","t",e%)%)%("_FluxUI",{Border=B}%)',
 function()return 'e.exports=assert(load('..string.format('%q',core)..',"@source-phase-core","t",e))("_FluxUI",{Border=B})'end)
prefix=prefix:gsub('function%(a,b%)style=a;accent=b end,function%(%)return #queue end,e',
 'function(a,b)style=a;accent=b end,function()return #queue end,e,m')
local fixture=assert(load(prefix..'\nreturn fixture','@source-phase-fixture','t',_G))()
local function mesh(objects)
 local rows={}
 for _,t in ipairs(objects)do if t.decorative and t.shown and t.size then
  local a={t.path,t.alpha,t.parent:GetFrameStrata(),t.parent:GetFrameLevel()}
  for _,v in ipairs(t.uv)do a[#a+1]=v end
  for _,v in ipairs(t.size)do a[#a+1]=v end
  for _,v in ipairs(t.color)do a[#a+1]=v end
  for _,v in ipairs(t.point or{})do if type(v)~='table'then a[#a+1]=v end end
  for i=1,4 do for _,v in ipairs(t.vertices and t.vertices[i]or{})do a[#a+1]=v end end
  for i,v in ipairs(a)do if type(v)=='number'then a[i]=string.format('%.12g',v)end end
  rows[#rows+1]=table.concat(a,',')
 end end
 table.sort(rows);local h=0;for _,r in ipairs(rows)do for i=1,#r do h=(h*257+r:byte(i))%2147483647 end end
 return h,#rows
end
for _,style in ipairs{1,2}do
 local j,new,piece,flush,objects,_,choose,_,e,m=fixture();choose(style,'class')
 local calls=0;local getter=m.GetTexture
 m.GetTexture=function(self)if self.sourceTest then calls=calls+1 end;return getter(self)end
 local parent=new(e.UIParent);local textures={}
 local function add(k,r)local t=piece(parent,k,r);t.sourceTest=true;textures[#textures+1]=t;return t end
 local top=add('Top',{0,-9,1400,17})
 local dividers={};for i=1,24 do dividers[i]=add('Left',{i*50-9,-40,16,80})end
 calls=0;flush();local coldCalls=calls;local first,fields=mesh(objects)
 check(j.stats.triangles>200 and j.stats.fallback==nil,'connected graph builds actual source fields: '..tostring(j.stats.triangles)..'/'..tostring(j.stats.fallback))
 corrected(coldCalls<=#textures,'each source is read at most once in one pure plan')
 corrected(j.stats.sourceReads==#textures and j.stats.sourceHits>j.stats.sourceReads,'actual source map records bounded reads and reuses')
 check(e.exports.memo()==nil,'successful plan releases source memo before drawing completes')
 calls=0;dividers[7].rect[1]=dividers[7].rect[1]+11;j:Invalidate(nil,dividers[7]);flush()
 local changed,changedFields=mesh(objects);local changedCalls=calls
 corrected(changedCalls<=#textures,'real local change reads each current source once')
 check(changed~=first and changedFields>0,'moving a divider changes the actual drawing')
 calls=0;j:Invalidate(true);flush()
 check(mesh(objects)==changed,'forced warm reuse preserves exact current mesh')
 corrected(calls<=#textures,'warm global validation does not re-read the same source')
 print(string.format('SOURCE_PHASE_WORK style=%d sources=%d coldCalls=%d changedCalls=%d mesh=%d changedMesh=%d fields=%d',
  style,#textures,coldCalls,changedCalls,first,changed,fields))
 if not measure then
  local count=calls;top.path='fresh-source.tga'
  check(e.exports.Source(top).path=='fresh-source.tga'and calls==count+1,'outside planning every Source call reads fresh native material')
  top.path='second-source.tga'
  check(e.exports.Source(top).path=='second-source.tga'and calls==count+2,'outside planning no Source tuple is retained')
  j:Invalidate(true);flush();check(e.exports.memo()==nil,'material-changing plan clears memo')
  local currentTexture=top.GetTexture
  top.GetTexture=function()error('injected source getter failure',0)end
  j:Invalidate(true);local ok,err=pcall(flush)
  check(not ok and tostring(err):find('injected source getter failure',1,true),'exact planning getter error is reported')
  check(e.exports.memo()==nil,'planning exception releases all current-source data')
  for _,t in ipairs(textures)do check(t.alpha~=0,'planning failure restores the original source instead of leaving suppressed art')end
  for _,t in ipairs(objects)do if t.decorative then check(not t.shown,'planning failure retires all replacement fields')end end
  top.GetTexture=currentTexture;top.path='recovered-source.tga';j:Invalidate(true);flush()
  check(top.alpha==0 and e.exports.Source(top).path=='recovered-source.tga','failed plan can retry with fresh source')
  for _,budget in ipairs{'junctionTriangles','fragments'}do
   local old=j.limits[budget];j.limits[budget]=1;j:Invalidate(true);flush()
   check(e.exports.memo()==nil and j.stats.fallback~=nil,'budget exit releases memo: '..budget)
   j.limits[budget]=old;j:Invalidate(true);flush()
   check(top.alpha==0 and e.exports.memo()==nil,'budget exit remains retryable: '..budget)
  end
  local private=setmetatable({}, {__eq=function()error('private source alpha compared')end,
   __lt=function()error('private source alpha ordered')end,__tostring=function()error('private source alpha formatted')end})
  e.issecretvalue=function(v)return rawequal(v,private)end
  top:SetAlpha(private);j:Invalidate(true);check(pcall(flush),'opaque source alpha survives one-plan native-sink forwarding')
  check(e.exports.memo()==nil,'opaque source alpha is not retained in a phase memo')
  top:SetAlpha(.75);j:Invalidate(true);flush()
  check(e.exports.Source(top).alpha==.75,'public alpha recovery observes current author paint')
 end
end
if not measure then
 local j,new,piece,_,_,_,choose,_,e,m=fixture();choose(2,'class')
 local parent=new(e.UIParent);parent._FluxBorderStatic=true;parent.unit='player'
 local texture,record=piece(parent,'Top',{0,-9,100,17})
 local art='Interface\\AddOns\\_FluxUI\\Texture\\borders\\ForeverMetal150Tint.tga'
 record.art,record.artHandle=art,art
 texture:SetTexture(art)
 local read=e.exports.Source
 local live=j._ReadPreparedSource
 local private=setmetatable({},{__eq=function()error('private UV compared')end})
 e.issecretvalue=function(v)return rawequal(v,private)end
 local paths,uvReads,masks=0,0,0
 local getPath,getUV,getMasks=m.GetTexture,m.GetTexCoord,m.GetNumMaskTextures
 function m:GetTexture()paths=paths+1;return getPath(self)end
 function m:GetTexCoord()uvReads=uvReads+1;return getUV(self)end
 function m:GetNumMaskTextures()masks=masks+1;return getMasks(self)end
 local left,right,top,bottom=1/256,209/256,1/256,18/256
 for _,uv in ipairs{{left,right,top,bottom},{left,top,left,bottom,right,top,right,bottom}}do
  texture.uv=uv
  local snapshot=assert(read(texture))
  local expected={path=snapshot.path,uv=snapshot.uv,gutter=snapshot.gutter,support=snapshot.support}
  check(expected.support~=nil,'fixture uses the current canonical support profile')
  local beforePath,beforeUV,beforeMasks=paths,uvReads,masks
  texture:SetVertexColor(.3,.5,.8,.75)
  local paint=assert(live(texture,expected))
  check(paint.uv==expected.uv and paint.color[1]==.3 and paint.alpha==.75,'same native samples share geometry and read fresh paint')
  check(paths==beforePath+1 and uvReads==beforeUV+1 and masks==beforeMasks+1,'prepared material still samples the live handle, mask count and UV tuple')
  check(expected.color==nil and expected.alpha==nil,'prepared material stays paint-free')
  texture:SetAlpha(private)
  check(rawequal(assert(live(texture,expected)).alpha,private),'live private alpha is forwarded through the normal paint snapshot')
  texture:SetAlpha(.75)
  texture.uv={table.unpack(uv)};texture.uv[#uv]=private
  check(live(texture,expected)==nil,'private current UV cannot match a public prepared source')
  texture.uv={table.unpack(uv)};texture.uv[#uv]=0
  check(live(texture,expected)==nil,'the actual last coordinate is validated')
  texture.uv={table.unpack(uv)};texture.uv[#uv+1]=.1
  check(live(texture,expected)==nil,'unexpected UV arity declines prepared reuse')
  texture.uv=uv;texture.maskCountOverride=1
  check(live(texture,expected)==nil,'native mask changes still decline prepared reuse')
  texture.maskCountOverride=nil;texture.path='fresh-material.tga'
  check(live(texture,expected)==nil,'live material replacement declines prepared reuse')
  texture.path=art;record.artHandle='retired-native-handle'
  check(live(texture,expected)==nil,'changed canonical support metadata declines prepared reuse')
  record.artHandle=art
  check(assert(live(texture,expected)).uv==expected.uv,'public material and UV recovery succeeds immediately')
 end
end
print('Border source phase: '..checks..' checks PASS; current native source validation; pure-plan reuse; fresh material and opaque alpha; failure/budget cleanup; exact reflow meshes. Native latency pending')
