-- Separate members/previews cannot share a neutral border bridge. Each one's
-- own separators still connect, including detached hosts with logical owners.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@party-border-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs({1,2})do for _,sameToken in ipairs({false,true})do for _,scale in ipairs({.75,1,1.25})do
 local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,'class')
 local top=style==1 and 8 or 9;local side=style==1 and 9 or 9.5
 local members={}
 for i=1,2 do
  local f=new(e.UIParent);f.scale=scale;f.unit=sameToken and 'party1'or'party'..i;f._FluxBorderIndependent=true
  local detached=new(e.UIParent);detached.scale=scale;detached._FluxBorderOwner=f
  local y=(i-1)*2
  members[i]={f=f,h=piece(detached,'Top',{0,y+top-17,100,17})}
 end
 -- This neutral HUD side crosses both members and must not weld either one.
 local hud=new(e.UIParent);hud.scale=scale;piece(hud,'Left',{50-side,-40,16,100})
 flush()
 check(j.stats.operations==0 and j.stats.triangles==0,'party instances stay independent even with a neutral HUD bridge or identical preview unit tokens')
 check(members[1].h:GetAlpha()==1 and members[2].h:GetAlpha()==1,'complete independent member outlines remain original')
 local own=new(members[1].f);own.scale=scale;piece(own,'Left',{50-side,-40,16,40})
 flush();check(j.stats.triangles>0,'the member still connects its own internal separator')
 for _,t in ipairs(objects)do if t._junctionOp then
  for g in pairs(t._junctionOp.members)do
   check(g.unitOwner=='party1','one member cannot import a neighboring member or HUD group into its T/X')
  end
 end end
 local solves,count=j.stats.solves,#objects
 for _=1,100 do members[1].f:SetAlpha(1)end;flush()
 check(j.stats.solves==solves and #objects==count,'independent member scopes add no idle rebuilding')
end end end
print('Party border isolation: '..checks..' checks PASS; member/preview identity; neutral HUD bridge; detached logical hosts; internal joins; both styles/scales; static reuse; native group pixels pending')
