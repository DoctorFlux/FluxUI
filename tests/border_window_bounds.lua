-- A nearby HIGH side strip, map or header must adapt its decorative chrome to
-- the configured Flux Window, without changing the window's visible outline.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@fixed-window-fixture','t',_G))()
local nearby=read('tests/border_nearby_panels.lua')
local start=assert(nearby:find(' local function panel(',1,true))
local finish=assert(nearby:find(' local strip,sb=',start,true))
local factory=assert(load('return function(new,piece,e,native)\n'..nearby:sub(start,finish-1)..'\nreturn panel end','@native-border-panels','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b,m)check(math.abs(a-b)<1e-7,m)end
local function native(v)return string.unpack('f',string.pack('f',v))end
for _,style in ipairs{1,2}do for _,factor in ipairs{.75,1,1.25}do for _,module in ipairs{false,true}do
 local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,'atlas')
 local panel=factory(new,piece,e,native)
 local track=style==1 and{Left=9,Right=9.5,Top=8,Bottom=8}or{Left=9.5,Right=9,Top=9,Bottom=7}
 local window,wb=panel('FluxWindowFrame',{152,0,200,200},factor*1.05,0,0,20,{0,1,0,1})
 if module then e.FluxWindowFrame={frame=window,GetFrame=function()error('topology must not create a window through its lazy getter')end}end
 local side,sb=panel('FluxMinimapButtonsSideBorder',{307,200,45,60},factor*.98,0,0,25,{.2,.6,1,1})
 side._FluxBorderHUD=true;side:SetFrameStrata('HIGH');sb:SetFrameStrata('HIGH')
 local map,mb=panel('Minimap',{307,263,45,45},factor,0,0,20,{.2,.6,1,1})
 local header,hb=panel('FluxMinimapInfoBar',{307,310,45,20},factor,0,0,20,{.2,.6,1,1})
 local initialContent={table.unpack(window.rect)}
 local function stroke(bf,key)
  local x,y,w,h=bf[key]:GetRect();local scale=bf:GetEffectiveScale()
  return(key=='Left'or key=='Right')and(x+track[key]/16*w)*scale or(y+h-track[key]/(key=='Top'and 17 or 16)*h)*scale
 end
 local function fixed(message)
  local x,y,w,h=wb:GetRect()
  for i,value in ipairs{x,y,w,h}do
   near(value,window.rect[i],message..': decorative window bound '..i..' stays configured')
  end
  for i,value in ipairs(initialContent)do near(window.rect[i],value,message..': content/input bound '..i..' stays unchanged')end
 end
 flush();fixed('initial adjacent side strip')
 near(stroke(sb,'Bottom'),stroke(wb,'Top'),'HIGH side bottom adapts to fixed window top')
 near(stroke(sb,'Right'),stroke(wb,'Right'),'HIGH side right adapts to fixed window perimeter')
 near(stroke(sb,'Top'),stroke(mb,'Bottom'),'side and map retain their shared perimeter')
 near(stroke(mb,'Top'),stroke(hb,'Bottom'),'map/header connection remains supported')
 local windowTopPaint=false
 for _,t in ipairs(objects)do
  local op=t._junctionOwnerOp
  if op and math.abs(op.x-stroke(wb,'Right'))<1e-7 and math.abs(op.y-stroke(wb,'Top'))<1e-7 and t._junctionSource==wb.Top then windowTopPaint=true end
 end
 check(windowTopPaint,'window-owned top stroke remains the actual paint source at the HIGH side T')
 -- Embed-like transition: the side gate disappears and the same named minimap
 -- moves under the window, then returns to its normal screen-side stack.
 local originalMap,originalHeader={table.unpack(map.rect)},{table.unpack(header.rect)}
 side:Hide();map:SetParent(window)
 map.rect={262/map.scale,0,90/map.scale,200/map.scale};map:SetPoint('TOPRIGHT',window,'TOPRIGHT',0,0)
 header.rect={262/header.scale,202/header.scale,90/header.scale,20/header.scale};header:SetPoint('BOTTOM',window,'TOP',0,0)
 j:CommitLayout();flush();fixed('embedded minimap')
 side:Show();map:SetParent(e.UIParent);map.rect=originalMap;header.rect=originalHeader
 map:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',307,263);header:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',307,310)
 j:CommitLayout();flush();fixed('normal minimap restored')
 near(stroke(sb,'Bottom'),stroke(wb,'Top'),'return from embed reconnects existing side/window strokes')
 -- A side-layout resize can move all neighboring nodes without modifying the
 -- configured window box. This models new side columns and a moved normal map.
 for _,f in ipairs{side,map,header}do f.rect[1]=f.rect[1]-4/f.scale;f:SetPoint('RIGHT',e.UIParent,'RIGHT',-4,0)end
 side.rect[3]=side.rect[3]+4/side.scale;side:SetSize(side.rect[3],side.rect[4])
 j:CommitLayout();flush();fixed('resized side grid')
 side:Hide();map:Hide();header:Hide();j:CommitLayout();flush();fixed('all neighboring panels hidden')
 for _,f in ipairs{side,map,header}do f:Show()end;j:CommitLayout();flush();fixed('neighbors shown again')
 local solves,reads,alignments,count=j.stats.solves,j.stats.geometryReads,j.stats.panelAlignments,#objects
 for _=1,40 do side:SetPoint('RIGHT',e.UIParent,'RIGHT',-4,0);j:CommitLayout();flush()end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and j.stats.panelAlignments==alignments and#objects==count,'settled unchanged side callbacks perform no solves/geometry passes/realignments/allocations')
 for _,f in ipairs{side,map,header}do f.rect[1]=f.rect[1]+300/f.scale;f:SetPoint('RIGHT',e.UIParent,'RIGHT',300,0)end
 j:CommitLayout();flush();fixed('neighbors detached')
 -- Real Layout changes remain allowed: keep the new configured bounds rather
 -- than restoring a stale pre-embed or pre-side version of the window.
 window.rect[1]=window.rect[1]+25/window.scale;window.rect[3]=window.rect[3]+20/window.scale
 initialContent={table.unpack(window.rect)};window:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',177,0)
 j:CommitLayout();flush();fixed('explicit window layout change')
 -- If a stacked window and the authoritative strip top disagree, neither fixed
 -- reference may be pulled to the other just because their bands are nearby.
 local strip,stripBF=panel('FluxActionStrip',{0,0,100,60},factor,4,-2,15,{1,0,0,1})
 window.rect={0,54/window.scale,200/window.scale,200/window.scale};initialContent={table.unpack(window.rect)}
 window:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',0,54)
 local stripTop=stroke(stripBF,'Top')
 j:CommitLayout();flush();fixed('disagreeing fixed references')
 near(stroke(stripBF,'Top'),stripTop,'window contact cannot move the fixed action-strip top under unit frames')
 check(math.abs(stroke(wb,'Bottom')-stripTop)>1/64,'conflicting nearby fixed strokes remain independent instead of changing their dimensions')
end end end
print('Flux Window bounds: '..checks..' checks PASS; fixed decorative/content geometry; HIGH side/map/header moves and embed-like visibility; window paint owner; detach/reconnect; static reuse; both styles/scales/module exports; conflicting fixed references; native pixels pending')
