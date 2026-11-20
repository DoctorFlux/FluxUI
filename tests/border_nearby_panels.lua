-- Production panel alignment and junction drawing with resolved native-style
-- anchors. Content frames and secure input are independent of border boxes.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local prefix=assert(read("tests/border_junctions.lua"):match("^(.-)local J=fixture%(%)"))
local core=read(arg[1] or "Core/BorderJunctions.lua"):gsub("\r\n","\n")
local measure=arg[2]=="--measure"
local count
core,count=core:gsub("local function PlanPanelAlignment%(panels%)\n",
 "local function PlanPanelAlignment(panels)\n    _G.alignPlans=(_G.alignPlans or 0)+1\n",1)
assert(count==1,"count the actual alignment graph builds")
if measure then
 core,count=core:gsub("([ ]+)([^\n=]+)={frame=frame,state=state,scale=scale,value=",function(indent,writer)
  return indent.."_G.alignSamples=(_G.alignSamples or 0)+1\n"..indent..writer.."={frame=frame,state=state,scale=scale,value="
 end,1)
 assert(count==1,"count only new panel input records")
end
prefix=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return ("%q"):format(core)end,1)
local fixture=assert(load(prefix.."\nreturn fixture","@nearby-panel-fixture","t",_G))()
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function close(a,b)return math.abs(a-b)<1e-7 end
local function native(v)return string.unpack("f",string.pack("f",v))end
for _,style in ipairs({1,2})do for _,factor in ipairs(measure and {1} or {.75,1,1.25})do for _,moduleExport in ipairs(measure and {false} or {false,true})do
 local j,new,piece,flush,objects,lock,choose,queued,e=fixture();choose(style,"atlas")
 local track=style==1 and {Left=9,Right=9.5,Top=8,Bottom=8}or{Left=9.5,Right=9,Top=9,Bottom=7}
 local function panel(name,world,scale,padx,pady,level,color)
  local f=new(e.UIParent,{world[1]/scale,world[2]/scale,world[3]/scale,world[4]/scale});f.scale=scale
  function f:SetAttribute()error("panel alignment must never write secure attributes")end
  local bf=new(f);bf.inheritScale=true;bf.level=level;f.FluxBorderFrame=bf;bf:SetAllPoints(f)
  bf._fluxBorderInsets={padx,pady}
  function bf:GetRect()
   e.rectReads=(e.rectReads or 0)+1
   local l,r,t,b=0,0,0,0
   for _,p in ipairs(self.anchors or {})do
    if p[1]=="TOPLEFT"then l,t=p[4]or 0,p[5]or 0
    elseif p[1]=="BOTTOMRIGHT"then r,b=p[4]or 0,p[5]or 0 end
   end
   local x,y,w,h=f.rect[1]+l,f.rect[2]+b,f.rect[3]+r-l,f.rect[4]+t-b
   if e.nativeGeometry then return native(x),native(y),native(w),native(h)end
   return x,y,w,h
  end
  function bf:GetLeft()return self:GetRect()end
  function bf:GetBottom()local _,y=self:GetRect();return y end
  local function rect(key)
   local x,y,w,h=bf:GetRect()
   if key=="TL"then return {x+padx-11,y+h-pady-11,16,17}
   elseif key=="TR"then return {x+w-padx-9,y+h-pady-11,16,17}
   elseif key=="BL"then return {x+padx-11,y+pady-7,16,16}
   elseif key=="BR"then return {x+w-padx-9,y+pady-7,16,16}
   elseif key=="Top"then return {x+padx+5,y+h-pady-11,w-2*padx-14,17}
   elseif key=="Bottom"then return {x+padx+5,y+pady-7,w-2*padx-14,16}
   elseif key=="Left"then return {x+padx-11,y+pady+9,16,h-2*pady-20}
   else return {x+w-padx-9,y+pady+9,16,h-2*pady-20}end
  end
  for _,key in ipairs({"TL","TR","BL","BR","Top","Bottom","Left","Right"})do
   local source=piece(bf,key,rect(key));bf[key]=source
   function source:GetRect()
    e.rectReads=(e.rectReads or 0)+1
    local r=rect(key)
    if e.nativeGeometry then return native(r[1])+(e.nativeNoise or 0),native(r[2])+(e.nativeNoise or 0),native(r[3]),native(r[4])end
    return table.unpack(r)
   end
   source:SetVertexColor(table.unpack(color))
  end
  e[name]=f
  return f,bf
 end
 local strip,sb=panel("FluxActionStrip",{0,0,100,60},factor,4,-2,15,{1,0,0,1})
 local menu,mb=panel("FluxTrinketMenuFrame",{103,0,45,60},factor*.94,0,-4,13,{0,0,1,1})
 local window,wb=panel("FluxWindowFrame",{152,0,200,200},factor*1.05,0,0,20,{0,1,0,1})
 -- Production exports can retain a module table rather than the named frame.
 -- Window GetFrame creates lazily, so topology must use its existing .frame.
 if moduleExport then e.FluxWindowFrame={frame=window,GetFrame=function()error("topology must not create/open a Flux Window")end}end
 local info,ib=panel("InfoNativeFrame",{-132,0,80,60},factor*.98,0,-4,17,{.3,.4,.5,1})
 e.FluxInfoFrame={GetFrame=function()return info end}
 local combat,cb=panel("CombatNativeFrame",{-49,0,45,60},factor*.94,-4,-4,13,{1,.5,0,1})
 e.FluxCombatManager={Grid={Frame=combat}}
 local noncombat,nb=panel("NonCombatNativeFrame",{-180,0,45,60},factor*.94,-4,-4,13,{.6,.2,.7,1})
 e.FluxNonCombatAPI={DefaultGrid={Frame=noncombat}}
 local envelope,eb=panel("FluxUnifiedBorderFrame",{-180,0,326,60},factor,-4,-4,18,{.5,.5,.5,1})
 local function stroke(bf,key)
  local x,y,w,h=bf[key]:GetRect();local scale=bf:GetEffectiveScale()
  return (key=="Left"or key=="Right")and(x+track[key]/16*w)*scale or(y+h-track[key]/(key=="Top"and 17 or 16)*h)*scale
 end
 local original={}
 for _,f in ipairs({strip,menu,window})do original[f]={table.unpack(f.rect)}end
 local originalWindow={wb:GetRect()}
 local originalFloor=stroke(wb,"Bottom")
 local originalStripTop=stroke(sb,"Top")
 flush()
 check(close(stroke(sb,"Right"),stroke(mb,"Left")),"strip and Trinket Menu meet at one native vertical stroke")
 check(close(stroke(mb,"Right"),stroke(wb,"Left")),"Trinket Menu and Flux Window meet at one native vertical stroke")
 check(close(stroke(nb,"Right"),stroke(ib,"Left")),"NonCombat Grid and Info share their actual native stroke")
 check(close(stroke(ib,"Right"),stroke(cb,"Left")),"Info and Combat Grid share their actual native stroke")
 check(close(stroke(cb,"Right"),stroke(sb,"Left")),"Combat Grid and action strip share their actual native stroke")
 check(close(stroke(eb,"Right"),stroke(wb,"Left")),"surrounding HUD border terminates on the same Flux Window seam")
 check(close(stroke(sb,"Bottom"),stroke(wb,"Bottom"))and close(stroke(mb,"Bottom"),stroke(wb,"Bottom")),"three-panel floor shares one transitive boundary")
 check(close(stroke(wb,"Bottom"),originalFloor),"window floor remains its configured reference for neighboring chrome")
 for i,v in ipairs(originalWindow)do check(close(({wb:GetRect()})[i],v),"Flux Window decorative dimensions and position remain fixed")end
 check(close(stroke(sb,"Top"),stroke(mb,"Top")),"nearby equal-height panel tops meet without changing content height")
 check(close(stroke(sb,"Top"),originalStripTop),"actual strip top remains authoritative beneath unit frames")
 for _,bf in ipairs({ib,cb,nb,eb})do
  check(close(stroke(bf,"Bottom"),stroke(sb,"Bottom")),"grid/Info/envelope bottom contacts join the same transitive floor")
 end
 for _,f in ipairs({info,combat,noncombat,envelope})do
  check(f.rect[2]==0 and f.rect[4]==60/f.scale,"extra HUD alignment keeps content height and position")
 end
 for _,f in ipairs({strip,menu,window})do
  for i,v in ipairs(original[f])do check(f.rect[i]==v,"decorative alignment never moves/resizes a content/input frame")end
 end
 local floor,seen=stroke(wb,"Bottom"),0
 for _,o in ipairs(objects)do
  if o._junctionOp and close(o._junctionOp.y,floor)then
   check(o._junctionOp.bits==7,"native common floor uses a real T instead of stacked L caps")
   seen=seen+1
  end
 end
 check(seen>=2,"both bottom contacts have committed T geometry")
 for _,bf in ipairs({nb,ib,cb,sb,mb})do
  local expectedX=stroke(bf,"Right");local found=false
  for _,o in ipairs(objects)do
   local op=o._junctionOp
   if op and close(op.x,expectedX)and close(op.y,floor)then
    check(op.bits==7,"each HUD floor contact has the expected continuous T arms")
    found=true
   end
  end
  check(found,"each grid/Info/strip/menu boundary commits an actual T at its shared floor")
 end
 local function SetMenuPose(detached)
  menu.rect[1]=detached and 600/menu.scale or original[menu][1]
  menu:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",detached and 600 or 103,0)
  j:CommitLayout(detached)
 end
 SetMenuPose(true);SetMenuPose(false)
 local plans=e.alignPlans
 for _=1,4 do
  SetMenuPose(true)
  check(close(({mb:GetRect()})[1],menu.rect[1]),"prepared detachment restores the menu's border")
  SetMenuPose(false)
  check(close(stroke(sb,"Right"),stroke(mb,"Left")),"prepared reattachment joins the current strip")
 end
 check(e.alignPlans==plans,"both warmed menu poses reuse their alignment graphs")
 if measure then
  local function SetCrossing(expanded,shift)
   shift=expanded and shift or 0
   local width=original[strip][3]+shift/strip.scale
   strip.rect[3]=width
   menu.rect[1]=original[menu][1]+shift/menu.scale
   combat.rect[1]=(-49-shift/2)/combat.scale
   noncombat.rect[1]=(-180-shift/2)/noncombat.scale
   envelope.rect[3]=(326+shift)/envelope.scale
  end
  local parts={sb,mb,wb,ib,cb,nb,eb}
  for _,scenario in ipairs({"stable","crossing","newWidth"})do
   SetCrossing(true,12);j:AlignNearbyPanels()
   SetCrossing(false,12);j:AlignNearbyPanels()
   e.alignSamples,e.alignPlans,e.rectReads=0,0,0
   collectgarbage("collect");collectgarbage("stop")
   local before=collectgarbage("count")
   local t=os.clock()
   local writes=0
   local steps=tonumber(arg[3]) or 60
   for step=1,steps do
    if scenario=="crossing" then SetCrossing(step%2==1,12)
    elseif scenario=="newWidth" then SetCrossing(true,step%37+1) end
    writes=writes+j:AlignNearbyPanels()
   end
   local elapsed=(os.clock()-t)*1000
   local heap=collectgarbage("count")-before
   collectgarbage("restart")
   local reads=e.rectReads
   local edges={}
   for _,part in ipairs(parts)do
    local x,y,w,h=part:GetRect()
    edges[#edges+1]=("%.9f,%.9f,%.9f,%.9f"):format(x,y,w,h)
   end
   print(("PANEL_INPUT style=%d case=%s steps=%d samples=%d graphs=%d writes=%d reads=%d ms=%.3f kib=%.2f geometry=%s")
    :format(style,scenario,steps,e.alignSamples,e.alignPlans,writes,reads,elapsed,heap,table.concat(edges,"/")))
  end
  SetCrossing(false,12)
  j:AlignNearbyPanels()
  menu:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",103,0)
  j:CommitLayout(false)
 end
 local count,solves,alignments=#objects,j.stats.solves,j.stats.panelAlignments;e.rectReads=0
 for _=1,100 do menu:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",103,0)end
 flush()
 check(e.rectReads==1 and #objects==count and j.stats.solves==solves and j.stats.panelAlignments==alignments,"unchanged setters skip panel reads, solves and anchor writes")
 e.nativeGeometry=true
 local scaleReads,scaleGetter=0,wb.GetEffectiveScale
 function wb:GetEffectiveScale()scaleReads=scaleReads+1;return scaleGetter(self)end
 for i=1,40 do
  e.nativeNoise=i%2==0 and -.0001 or .0001
  check(j:AlignNearbyPanels()==0,"rounded decorative readback cannot feed another panel realignment")
 end
 check(scaleReads==40,"matching panel inputs sample each scale once and skip the alignment output pass")
 wb.GetEffectiveScale=scaleGetter
 check(j.stats.panelAlignments==alignments and j.stats.solves==solves,"native float feedback keeps the seven-panel mesh static")
 e.nativeGeometry=false;e.nativeNoise=0
 local clear=mb.ClearAllPoints
 local joinedRect={mb:GetRect()}
 menu.rect[1]=600/menu.scale
 function mb:ClearAllPoints()clear(self);error('partial alignment write')end
 local ok,err=pcall(j.AlignNearbyPanels,j)
 check(not ok and tostring(err):find('partial alignment write',1,true),'native alignment errors still propagate')
 mb.ClearAllPoints=clear
 menu.rect[1]=original[menu][1]
 j:AlignNearbyPanels()
 for i,value in ipairs({mb:GetRect()})do
  check(close(value,joinedRect[i]),'restoring prior inputs repairs an interrupted decorative write')
 end
 window.rect[1]=window.rect[1]+150/window.scale;window:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",302,0);flush()
 check(close(stroke(sb,"Right"),stroke(mb,"Left")),"strip/menu attachment remains after the window detaches")
 check(close(stroke(sb,"Bottom"),stroke(mb,"Bottom")),"detached window stops owning the strip/menu floor")
 menu.rect[1]=600/menu.scale;menu:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",600,0);flush()
 for _,f in ipairs({info,combat,noncombat,envelope})do f:Hide()end;flush()
 for _,f in ipairs({strip,menu,window})do
  local x,y,w,h=f.FluxBorderFrame:GetRect()
  check(close(x,f.rect[1])and close(y,f.rect[2])and close(w,f.rect[3])and close(h,f.rect[4]),"fully detached panels restore their original eight-piece box")
 end
 menu.rect[1]=original[menu][1];window.rect[1]=original[window][1]
 menu:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",103,0);window:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",152,0);flush()
 check(close(stroke(mb,"Right"),stroke(wb,"Left")),"reattaching panels restores contact in the same selected style")
 window:Hide();flush()
 check(close(stroke(sb,"Bottom"),stroke(mb,"Bottom")),"hidden window cannot keep control of the shared floor")
 window:Show();flush()
 check(close(stroke(mb,"Bottom"),stroke(wb,"Bottom")),"reappearing window reconnects existing decorative boxes")
 window:SetAlpha(0);flush()
 local x,y,w,h=wb:GetRect()
 check(close(x,window.rect[1])and close(y,window.rect[2])and close(w,window.rect[3])and close(h,window.rect[4]),"a transparent shown panel restores its nominal border and cannot own a nearby join")
 window:SetAlpha(1);flush()
 check(close(stroke(mb,"Bottom"),stroke(wb,"Bottom")),"ending a transparent visibility transition reconnects the current panels")
 lock(true);window.rect[1]=window.rect[1]+150/window.scale;window:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",302,0);flush()
 check(queued()==0,"combat does not schedule protected layout writes")
 lock(false);for _,o in ipairs(objects)do if o.OnEvent then o:OnEvent("PLAYER_REGEN_ENABLED")end end;flush()
 check(close(stroke(sb,"Bottom"),stroke(mb,"Bottom")),"post-combat layout restores attachments against the current panels")
 menu.rect[1]=600/menu.scale;menu:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",600,0)
 window.rect[1],window.rect[2]=0,54/window.scale;window:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",0,54);flush()
 check(math.abs(stroke(wb,"Bottom")-stroke(sb,"Top"))<=1+8*math.min(window.scale,strip.scale),"fixed window/strip references remain inside the bounded join field without resizing either")
 check(close(stroke(sb,"Top"),originalStripTop),"stacked panel contact preserves strip authority under unit frames")
 check(close(stroke(wb,"Left"),stroke(sb,"Left")),"stacked panels align their nearby left outside caps")
 window.rect[2]=300/window.scale;window:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",0,300);flush()
 local x,y,w,h=sb:GetRect()
 check(close(x,strip.rect[1])and close(y,strip.rect[2])and close(w,strip.rect[3])and close(h,strip.rect[4]),"separating stacked panels restores the strip's original decorative box")
 window.rect[1],window.rect[2]=152/window.scale,0;window:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",152,0);flush()
 local side,sideBF=panel("FluxMinimapButtonsSideBorder",{307,200,45,60},factor*.98,0,0,25,{.2,.6,1,1})
 side._FluxBorderHUD=true;side:SetFrameStrata("HIGH");sideBF:SetFrameStrata("HIGH")
 local map,mapBF=panel("Minimap",{307,263,45,45},factor,0,0,20,{.2,.6,1,1})
 local header,headerBF=panel("FluxMinimapInfoBar",{307,310,45,20},factor,0,0,20,{.2,.6,1,1})
 flush()
 check(close(stroke(sideBF,"Bottom"),stroke(wb,"Top")),"high-layer side buttons meet the Flux Window at their real shared stroke")
 check(close(stroke(sideBF,"Top"),stroke(mapBF,"Bottom")),"side buttons meet the normal minimap above them")
 check(close(stroke(mapBF,"Top"),stroke(headerBF,"Bottom")),"minimap zone header joins the same map perimeter")
 check(close(stroke(sideBF,"Right"),stroke(wb,"Right"))and close(stroke(sideBF,"Right"),stroke(mapBF,"Right")),"right screen perimeter stays continuous through side buttons, map and window")
 local t=false
 for _,o in ipairs(objects)do
  local op=o._junctionOp
  if op and close(op.x,stroke(wb,"Right"))and close(op.y,stroke(wb,"Top"))then
   check(op.bits==13,"explicit high-layer HUD source participates in the window's right-side T")
   t=true
  end
 end
 check(t,"the high-layer side strip is not isolated from the HUD topology")
 side:Hide();j:CommitLayout()
 check(wb.TR:GetAlpha()==1,"explicit embed transition immediately restores the window's exposed corner")
 side:Show();j:CommitLayout()
 check(close(stroke(sideBF,"Bottom"),stroke(wb,"Top")),"explicit unembed transition immediately restores the current side/window join")
 -- Pet and stance shells use the same bounded alignment, including scale
 -- changes and detach; only decorative hosts may move.
 side:Hide();map:Hide();header:Hide()
 menu.rect[1]=600/menu.scale;window.rect[1]=800/window.scale
 menu:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",600,0)
 window:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",800,0)
 local pet,pb=panel("FluxPetBar",{103,0,44,60},factor*.94,-2,-4,12,{.3,.6,.9,1})
 local stance,tb=panel("FluxStanceBar",{150,0,44,60},factor*1.05,-2,-4,13,{.8,.5,.2,1})
 flush()
 check(close(stroke(sb,"Right"),stroke(pb,"Left")),"pet bar joins the actual action-strip stroke")
 check(close(stroke(pb,"Right"),stroke(tb,"Left")),"stance and pet shells align through different scales/insets")
 check(close(stroke(pb,"Bottom"),stroke(sb,"Bottom"))and close(stroke(tb,"Bottom"),stroke(sb,"Bottom")),"stance/pet/strip retain a continuous transitive floor")
 check(pet.rect[1]==103/pet.scale and stance.rect[1]==150/stance.scale,"stance/pet input and button frames never move during border alignment")
 local attachedStance={tb:GetRect()}
 local suffixPlans=e.alignPlans
 pet:Hide();j:CommitLayout()
 check(close(({pb:GetRect()})[1],pet.rect[1]),"removing the last panel owner restores its native border box")
 pet:Show();j:CommitLayout()
 for i,v in ipairs(attachedStance)do
  check(close(({tb:GetRect()})[i],v),"restoring the last panel owner recovers the retained stance join")
 end
 check(e.alignPlans==suffixPlans+1,"only the shorter panel list needs a new alignment graph")
 stance.rect[1]=400/stance.scale;stance:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",400,0);j:CommitLayout()
 local x,y,w,h=tb:GetRect()
 check(close(x,stance.rect[1])and close(y,stance.rect[2])and close(w,stance.rect[3])and close(h,stance.rect[4]),"moved stance bar restores its complete standalone outline")
end end end
print("Nearby panel borders: "..checks.." checks PASS; both styles; fractional mixed scales; module/frame exports; grids/Info/strip/menu/window/envelope T contacts; transitive floors; detach/hide/reattach; static work; combat deferral; untouched content/input geometry. Native pixels/FPS pending")
