-- A short high-priority shared stroke cannot erase the longer stroke on either
-- side of a T/X. Check actual committed source fields, not just node existence.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@branch-coverage-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function contains(t,x,y)
 local a,b,c=t.a,t.b,t.c
 local det=(b[2]-c[2])*(a[1]-c[1])+(c[1]-b[1])*(a[2]-c[2])
 if math.abs(det)<1e-12 then return false end
 local u=((b[2]-c[2])*(x-c[1])+(c[1]-b[1])*(y-c[2]))/det
 local v=((c[2]-a[2])*(x-c[1])+(a[1]-c[1])*(y-c[2]))/det
 return u>1e-8 and v>1e-8 and 1-u-v>1e-8
end
for _,style in ipairs({1,2})do for _,scale in ipairs({.75,1,1.25})do for _,axis in ipairs({'H','V'})do
 for _,tee in ipairs({false,true})do
  local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,'class')
  local a,b,c,d=new(e.UIParent),new(e.UIParent),new(e.UIParent),new(e.UIParent)
  a.scale,b.scale,c.scale,d.scale=scale,scale,scale,scale;a.level,b.level,c.level,d.level=5,20,10,30
  local top=style==1 and 8 or 9;local side=style==1 and 9 or 9.5
  local long,short,far
  if axis=='H' then
   long=piece(a,'Top',{0,top-17,100,17});short=piece(b,'Top',{44,top-17,12,17})
   piece(c,'Left',{50-side,tee and -50 or -40,16,tee and 50 or 80})
   far=piece(d,'Top',{58,top-17,4,17})
  else
   long=piece(a,'Left',{50-side,-50,16,100});short=piece(b,'Left',{50-side,-6,16,12})
   piece(c,'Top',{tee and 0 or 10,top-17,tee and 50 or 80,17})
   far=piece(d,'Left',{50-side,8,16,4})
  end
  long:SetVertexColor(.2,.6,.8,1);short:SetVertexColor(.9,.3,.1,1);far:SetVertexColor(.7,.8,.1,1);flush()
  check(j.stats.fallback==nil,'short-owner contact commits within existing budgets')
  local op
  for _,o in ipairs(objects)do if o._junctionOp then op=o._junctionOp;break end end
  check(op~=nil,'shared short/long contact has actual T/X paint')
  local r=op.rect;local w,h=r[3]-r[1],r[4]-r[2]
  for _,along in ipairs({-13.37,-9.23,-6.41,6.39,9.17,13.31})do
   local x,y=50*scale,.19*scale
   if axis=='H' then x=x+along*scale else x=x+.19*scale;y=along*scale end
   local count=0
   for _,t in ipairs(op.triangles)do if contains(t,(x-r[1])/w,(r[4]-y)/h)then
    count=count+1
    local expected=along>8 and along<12 and far or long
    check(t.texture==expected,'long stroke resumes except inside another owner\'s actual shared interval')
    check(t.source.color[1]==(expected==far and .7 or .2),'resumed branch retains its interval-specific material and tint')
   end end
   check(count==1,'every surviving long-stroke sample has exactly one paint field')
  end
  local solves,count=j.stats.solves,#objects
  for _=1,100 do long:SetVertexColor(.2,.6,.8,1)end;flush()
  check(j.stats.solves==solves and #objects==count,'branch ownership stays static on unchanged paint')
 end
end end end
print('Branch coverage: '..checks..' checks PASS; short/long shared owners; T/X; both axes/styles/scales; no missing or doubled source fields; static recolor; native pixels pending')
