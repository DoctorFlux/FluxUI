-- Exercise the actual immutable polygon cuts, with exact exported geometry for
-- paired runs against an external source checkpoint. No native FPS inference.
local sourcePath=arg[1] or 'Core/BorderJunctions.lua'
local measure=arg[2]=='--measure'
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(sourcePath)
local clip=assert(source:match('(local function ClipField.-)local function UVPoint'))
clip=clip:gsub('(local function ClipField%([^\n]+%)\n)','%1    calls=calls+1\n',1)
clip=clip:gsub('local out={};local previous=', 'built=built+1;local out={};local previous=',1)
local uv=assert(source:match('(local function UVPoint.-)local function EndpointSample'))
local caps=assert(source:match('(local function ExcludeCaps.-)%-%- Paired aura'))
local fallback=source:match('(local fallbackCompilePrevious,fallbackCompileNext.-)local function RenderFallbackRectangles')
    or assert(source:match('(local function FallbackTriangles.-)local function RenderFallbackRectangles'))
local public=assert(source:match('(local function PublicNumber.-)local function AlphaPresent'))
local functions=assert(load('local calls,built=0,0;local min,max,abs=math.min,math.max,math.abs\n'..
    'local J={stats={}};local active={}\n'..public..clip..uv..caps..fallback..'\nreturn {clip=ClipField,caps=ExcludeCaps,fallback=FallbackTriangles,work=function()return calls,built end}',
    '@actual-border-cuts','t',_G))()
local function encode(value)
 if type(value)=='number'then return string.format('%.12g',value)end
 local out={};for i,v in ipairs(value)do out[i]=encode(v)end;return '['..table.concat(out,',')..']'
end
local poly={{0,0,0,10},{0,1,0,0},{1,1,10,0},{1,0,10,10}}
local frozen=encode(poly)
local digest=0
local function hash(value)local s=encode(value);for i=1,#s do digest=(digest*257+s:byte(i))%2147483647 end end
local same=functions.clip(poly,3,-1,true)
if not measure then check(same==poly,'fully included immutable field is reused')end
check(encode(poly)==frozen,'whole-field cut leaves its input unchanged')
check(#functions.clip(poly,3,11,true)==0,'strictly outside field is empty')
for _,axis in ipairs{1,2,3,4}do
 for _,bound in ipairs{-20,-1,0,.25,.5,1,5,10,11,20}do
  for _,above in ipairs{true,false}do
   local result=functions.clip(poly,axis,bound,above)
   for _,p in ipairs(result)do check(above and p[axis]>=bound-1e-10 or not above and p[axis]<=bound+1e-10,'cut respects its retained half-plane')end
   hash(result);check(encode(poly)==frozen,'clipped fields never mutate the source')
  end
 end
end
-- Tangencies and crossing caps retain the same partition/order/UV points.
for _,rect in ipairs{{-30,-30,-20,20},{20,-30,30,20},{-1,-1,11,11},{0,0,10,10},
 {0,-5,5,5},{2,2,8,8},{5,-5,15,15},{-5,10,15,20},{-5,-10,15,0}}do
 local result=assert(functions.caps(poly,{rect}));hash(result)
 for _,field in ipairs(result)do for _,p in ipairs(field)do
  check(p[3]<=rect[1]+1e-10 or p[3]>=rect[3]-1e-10 or p[4]<=rect[2]+1e-10 or p[4]>=rect[4]-1e-10,'outside cap fields do not enter its strict interior')
 end end
end
local beforeCalls,beforeBuilt=functions.work()
local distant={};for i=1,300 do distant[i]={20+i,0,21+i,10}end
for _=1,50 do local result=assert(functions.caps(poly,distant));check(#result==1 and encode(result[1])==frozen,'distant caps leave the original partition exact')end
local afterCalls,afterBuilt=functions.work()
if not measure then check(afterCalls==beforeCalls and afterBuilt==beforeBuilt,'strict horizontal cap separation performs no clipping allocations')end
local op={rect={0,0,100,100}}
local triangle={a={0,0,0,0},b={0,1,0,1},c={1,1,1,1},arm=1}
local item={rect={0,0,100,100},texture={}}
local sourceField={uv={0,1,0,1}}
for _,bounds in ipairs{{200,200,210,210},{-20,-20,-10,-10},{25,25,75,75},{0,0,100,100},{100,0,110,100}}do
 local cell={rect=bounds,plan={item=item,source=sourceField},blockers={{}}}
 local count=functions.fallback(op,triangle,cell)
 local result={};for _,field in ipairs(op.fallbackTriangles or{})do result[#result+1]={field.a,field.b,field.c}end
 hash(result)
 if bounds[1]>100 or bounds[3]<0 then check(count==0,'strictly disjoint fallback triangle adds no paint')end
 op.fallbackTriangles=nil
end
check(encode(poly)==frozen,'all cuts retain source vertices')
print(string.format('Border clip work: %d checks PASS; distantCapCalls=%d distantCapBuilds=%d geometry=%d',checks,afterCalls-beforeCalls,afterBuilt-beforeBuilt,digest))
