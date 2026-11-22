-- Production joins: native rounded unit caps stay intact while aura stems
-- continue underneath. Unit/placeholder/nested visibility remains event-driven.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@unit-contour-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<1e-7 end
do
 local j=fixture()
 local root,rect={},{0,0,10,10}
 local horizontal,vertical,stem={},{},{}
 local header={root=root,item={texture=horizontal,rect=rect,record={key='Top'}}}
 local divider={root=root,item={texture=vertical,rect=rect,record={key='Left'}}}
 local underlay={texture=stem,roundFill=true}
 local op={root=root,rect=rect,bits=11,members={[{unitOwner='target'}]=true},
  triangles={{arm=1,texture=horizontal},{arm=4,texture=vertical},underlay}}
 local blocked={}
 local owners=j:_PrepareUnitBranchFallbacks({op},{[horizontal]=header,[vertical]=divider},blocked,{})[op]
 check(not blocked[root] and op._unitBranchPrepared,'rounded underlay leaves both straight-arm continuations eligible')
 check(owners[horizontal][1].plan==divider and owners[vertical][1].plan==header,'each hidden arm uses the actual perpendicular owner')
 check(owners[stem]==nil and op.triangles[3]==underlay,'rounded underlay stays in base paint without acquiring a branch owner')
end
for _,style in ipairs({1,2})do for _,scale in ipairs({.75,1,1.25})do for _,unit in ipairs({'target','focus','party1','pet','targettarget'})do
 local j,new,piece,flush,objects,lock,choose,queued,e=fixture();choose(style,'class')
 local root=new(e.UIParent);root.unit=unit;root.scale=scale
 local function box(name,x,y,w,h,level,aura)
  local p=new(root,{x,y,w,h});p.scale=scale;p.level=level;p.name=name
  p._FluxBorderAuraPanel=aura;p._FluxBorderRoundCorners=not aura
  local r={TL={x-9,y+h-13,16,17},TR={x+w-11,y+h-13,16,17},BL={x-9,y-5,16,16},BR={x+w-11,y-5,16,16},Top={x+7,y+h-13,w-18,17},Bottom={x+7,y-5,w-18,16},Left={x-9,y+11,16,h-24},Right={x+w-11,y+11,16,h-24}}
  local parts={}
  for _,key in ipairs({'TL','TR','BL','BR','Top','Bottom','Left','Right'})do
   local t=piece(p,key,r[key]);parts[key]=t
   t:SetTexture(name..'-'..key..'.tga');t:SetTexCoord(.1,.2,.3,.4)
   t:SetVertexColor(aura and .2 or .8,.5,aura and 1 or .3,aura and .4 or 1)
  end
  return p,parts,r
 end
 local outer,parts,rects=box('unit',0,-124,320,124,20,false)
 local bottom=style==1 and -7 or -9
 local buff=box('buff',0,bottom,160,87,0,true);local debuff=box('debuff',160,bottom,160,87,0,true)
 flush()
 check(j.stats.fallback==nil and j.stats.triangles>0,'aura/unit contours commit without fallback')
 local topMiddle=false
 local top=(bottom+87+4-(style==1 and 8 or 9))*scale
 for _,o in ipairs(objects)do
  local op=o._junctionOp
  if op and math.abs(op.x-160*scale)<4*scale and near(op.y,top)then
   check(op.bits==11 and #op.triangles>0,'paired aura top uses one complete horizontal/down T')
   topMiddle=true
  end
 end
 check(topMiddle,'the aura top-middle join is present')
 local caps={}
 for _,key in ipairs({'TL','TR'})do
  local matches=0
  for _,o in ipairs(objects)do
   if o.decorative and o.path=='unit-'..key..'.tga'and o.shown and o.alpha>0 then
    matches=matches+1;caps[key]=o
    check(o.parent:GetParent()==outer and o.parent:GetFrameLevel()>outer:GetFrameLevel(),'original rounded cap draws above the incoming aura continuation')
    check(near(o.size[1],16)and near(o.size[2],17),'complete native cap dimensions remain unchanged')
    check(table.concat(o.uv,',')=='.1,.2,.3,.4'or near(o.uv[1],.1)and near(o.uv[2],.2)and near(o.uv[3],.3)and near(o.uv[4],.4),'native curved-cap UV field stays intact')
    check(o.color[1]==.8 and o.color[4]==1,'unit cap keeps its own class tint and opacity')
   end
  end
  check(matches==1,'one complete rounded cap replaces the clipped source without stacking outlines')
 end
 local fill=0
 for _,o in ipairs(objects)do
  local op=o._junctionOp
  if op then for _,triangle in ipairs(op.triangles)do
   if triangle.roundFill then
    check(triangle.source.color[1]==.2 and triangle.source.color[4]==.4,'corner-gap continuation retains the aura branch color/alpha')
    fill=fill+1
   end
  end end
 end
 check(fill==4,'two rounded unit corners receive two bounded incoming-stem triangles each')
 for _,o in ipairs(objects)do
  local op=o._junctionOp
  if op and #(op.roundCaps or {})>0 then
   check(caps.TL:GetParent():GetFrameLevel()>o:GetParent():GetFrameLevel(),'native curved cap stays above the raised junction layer')
  end
 end
 local solves,count=j.stats.solves,#objects
 for _=1,100 do root:SetAlpha(1);parts.TL:SetVertexColor(.8,.5,.3,1)end;flush()
 check(j.stats.solves==solves and #objects==count,'unchanged unit updates leave the contour mesh static')
 parts.TL:SetVertexColor(.1,.7,.9,1)
 check(caps.TL.color[1]==.1 and caps.TL.color[3]==.9,'unit class paint reaches its raised curved cap immediately')
 for _=1,3 do
  root:SetAlpha(0);j:CommitLayout()
  check(caps.TL:GetEffectiveAlpha()==0 and caps.TR:GetEffectiveAlpha()==0,'clearing/fading a unit hides all retained curved caps')
  root:SetAlpha(1);j:CommitLayout()
  check(caps.TL.shown and caps.TR.shown and j.stats.fallback==nil,'reappearing units reconnect using their existing curved-cap resources')
 end
 check(#objects==count,'repeated unit changes reuse prepared contour resources')
 root:Hide();j:CommitLayout()
 check(not outer:IsVisible(),'native unit hide removes its entire contour owner')
 root:Show();j:CommitLayout()
 check(caps.TL.shown and caps.TR.shown and #objects==count,'native unit show restores the same contour resources')
end end end
print('Unit contour borders: '..checks..' checks PASS; both styles/scales; rounded source caps; filled aura turns; top-middle T; target/focus/party/pet/ToT hide/fade/show; static recolor; native combat/pixels pending')
