-- Replay the user's six native aura rectangles through the production renderer.
-- A present T is insufficient: its vertical bevel must not notch the top crest.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@aura-crest-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function covers(t,x,y)
 local a,b,c=t.a,t.b,t.c
 local det=(b[2]-c[2])*(a[1]-c[1])+(c[1]-b[1])*(a[2]-c[2])
 if math.abs(det)<1e-12 then return false end
 local u=((b[2]-c[2])*(x-c[1])+(c[1]-b[1])*(y-c[2]))/det
 local v=((c[2]-a[2])*(x-c[1])+(a[1]-c[1])*(y-c[2]))/det
 return u>1e-8 and v>1e-8 and 1-u-v>1e-8
end
for _,style in ipairs({1,2})do for _,scale in ipairs({.5,.75,1,1.25})do for _,reverse in ipairs({false,true})do
 local j,new,piece,flush,objects,_,choose=fixture();choose(style,'class')
 local root=new();root.unit='target';root.scale=scale
 local function box(name,x)
  local y,top,w=230.84004211426,293.84005737305,144.79716491699
  local p=new(root,{x,y-16,w+32,top-y+33});p.scale=scale;p.level=0;p.strata='BACKGROUND'
  p.name=name;p._FluxBorderAuraPanel=true
  local r={TL={x,top,16,17},TR={x+16+w,top,16,17},BL={x,y-16,16,16},BR={x+16+w,y-16,16,16},Top={x+16,top,w,17},Bottom={x+16,y-16,w,16},Left={x,y,16,top-y},Right={x+16+w,y,16,top-y}}
  for _,key in ipairs({'TL','TR','BL','BR','Top','Bottom','Left','Right'})do
   local t=piece(p,key,r[key]);t:SetTexture(name..'-'..key..'.tga');t:SetTexCoord(.1,.8,.2,.4)
   t:SetVertexColor(name=='buff'and .2 or .7,.5,.8,.4)
  end
 end
 if reverse then box('debuff',1131.2987060547);box('buff',968.50158691406)
 else box('buff',968.50158691406);box('debuff',1131.2987060547)end
 flush();check(j.stats.fallback==nil,'native aura layout commits within existing budgets')
 local op
 for _,t in ipairs(objects)do
  if t._junctionOp and t._junctionOp.bits==11 then op=t._junctionOp;break end
 end
 check(op~=nil,'native pair has one horizontal/down middle T')
 local r=op.rect;local w,h=r[3]-r[1],r[4]-r[2]
 -- Sample interiors rather than shared raster boundaries. On the old diagonal
 -- partition, a side-shadow wedge occupies samples below the track at the T.
 for _,dx in ipairs({-1.37,-.43,.29,1.13})do for _,dy in ipairs({-.73,-.21,.17,.61})do
  local x=(op.x+dx*scale-r[1])/w;local y=(r[4]-op.y-dy*scale)/h
  local count=0
  for _,t in ipairs(op.triangles)do if covers(t,x,y)then
   count=count+1
   check(t.arm==1 or t.arm==2,'horizontal crest stays continuous across the T; no vertical shadow wedge')
   check(t.source.alpha==.4,'crest preserves the source aura opacity')
  end end
  check(count==1,'crest sample has exactly one source field without gaps or stacked alpha')
 end end
 local stem=false
 for _,t in ipairs(op.triangles)do if t.arm==4 then
  stem=true
  for _,v in ipairs({t.a,t.b,t.c})do
   local y=r[4]-v[2]*h
   check(y<=op.y-scale+1e-7,'vertical stem stops beneath the continuous inner crest')
  end
 end end
 check(stem,'bounded vertical stem still reaches the crossbar')
 local solves,count=j.stats.solves,#objects
 for _=1,100 do root:SetAlpha(1)end;flush()
 check(j.stats.solves==solves and #objects==count,'corrected T remains static on unchanged unit callbacks')
end end end
print('Aura crest: '..checks..' checks PASS; exact native rectangles; both styles/four scales/registration orders; continuous crest; one source per sample; bounded stem; static reuse; native pixels pending')
