-- Native GetRect returns float-sized UI coordinates. Repeated layout setters
-- must not rebuild the HUD for round-trip noise far below one physical pixel.
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a");f:close();return s end
local prefix=assert(read("tests/border_junctions.lua"):match("^(.-)local J=fixture%(%)"))
local fixture=assert(load(prefix.."\nreturn fixture","@static-border-fixture","t",_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function native(v)return string.unpack("f",string.pack("f",v))end
for _,style in ipairs({1,2})do for _,scale in ipairs({.75,1,1.25})do
 local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,"class")
 local p=new(e.UIParent,{1100/scale,300/scale,100,80});p.scale=scale
 local originalX=p.rect[1]
 local function source(key,offset)
  local t=piece(p,key,{0,0,100,17})
  function t:GetRect()
   e.rectReads=(e.rectReads or 0)+1
   return native(p.rect[1]+offset[1]),native(p.rect[2]+offset[2]),native(offset[3]),native(offset[4])
  end
  return t
 end
 local h=source("Top",{0,0,100,17});source("Left",{40,-30,16,80})
 for i=1,500 do piece(new(e.UIParent),"Top",{4000+i*200,0,100,17})end
 flush();local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
 for i=1,100 do
  p.rect[1]=native(originalX+(i%2==0 and -.00006 or .00006))
  p:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",originalX,300/scale);flush()
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,
  "float round-trip noise cannot scan/rebuild an unchanged HUD")
 p.rect[1]=native(originalX+1/scale);p:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",p.rect[1],300/scale);flush()
 check(j.stats.geometryReads==reads+1 and j.stats.solves==solves+1,"a real one-pixel move rebuilds the affected attachment")
 local nextSolves=j.stats.solves
 for _=1,100 do h:SetVertexColor(.2,.6,1,1)end;flush()
 check(j.stats.solves==nextSolves,"live class tint stays paint-only on committed geometry")
end end
do
 local j,new,piece,flush,objects,_,_,_,e=fixture()
 local now,timers=0,{}
 e.GetTime=function()return now end
 e.C_Timer={After=function(delay,fn)timers[#timers+1]={at=now+delay,fn=fn}end}
 local p=new(e.UIParent);piece(p,"Top",{0,0,100,17});piece(p,"Left",{40,-30,16,80});flush()
 local reads,solves=j.stats.geometryReads,j.stats.solves
 now=.01;p:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",0,0);flush()
 check(#timers==1,"a same-layout request inside the burst window schedules one wake")
 now=.06;timers[1].fn();flush()
 check(j.stats.geometryReads==reads and j.stats.solves==solves,"a delayed no-op wake cannot turn the whole registry dirty")
 local output={};e.print=function(line)output[#output+1]=line end
 e.SlashCmdList.FLUXBORDERS('idle')
 check(#timers==2 and timers[2].at==now+10,"the user-invoked idle check owns exactly one finite timer")
 now=timers[2].at;timers[2].fn()
 check(output[2]:find('solves=0 panelAlignments=0 geometryReads=0',1,true),"idle diagnostic reports counter deltas without triggering geometry work")
end
print("Static border geometry: "..checks.." checks PASS; native float precision;100 no-op layout rounds with500 unrelated pieces; real pixel moves and immediate paint; no native FPS claim")
