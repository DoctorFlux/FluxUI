-- Actual controller: side rings fill their zero-spacing cells. Embedded sizing,
-- saved actions and combat ownership remain independent of the changed packing.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(os.getenv('FLUX_MINIMAP_EXTRA_SOURCE')or'Minimap/FluxMinimapButtons.lua')
local prefix=read('tests/minimap_extra_layout.lua')
prefix=prefix:sub(1,assert(prefix:find('local function physical(frame)',1,true))-1)
prefix=prefix:gsub('local source = read[^\n]*','local source = ...',1)
local boot=assert(load(prefix..'\nreturn boot','@side-inset-fixture','t',_G))(source)
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,uiScale in ipairs({.75,1,1.25})do
 local t=boot();t.env.UIParent:SetScale(uiScale);t.api:SetSetting('sideEnabled',true)
 for _,start in ipairs({'top','below'})do for _,percent in ipairs({10,100,200})do for _,count in ipairs({1,15,60,120})do
  t.api:SetSetting('sideStart',start);t.api:SetSetting('sideScale',percent);t.api:SetSetting('count',count)
  local right=t.env.UIParent:GetRight()*t.env.UIParent:GetEffectiveScale()
  for _,b in ipairs(t:visible())do
   local x,y,w,h=b.Widget:rect();local sx,sy,sw,sh=b.SlotFrame:rect()
   check(math.abs(w-sw)<.001 and math.abs(h-sh)<.001,'side visual and hit bounds exactly fill the assigned cell')
   check(math.abs(x-sx)<.001 and math.abs(y-sy)<.001,'side artwork has zero added gaps in dense/mixed-scale layouts')
   check(math.abs(x+w/2-sx-sw/2)<.001 and math.abs(y+h/2-sy-sh/2)<.001,'visual and hit rectangle remain centered in the assigned slot')
   check(x+w<=right+.001,'side button stays inside the screen perimeter')
  end
 end end end
 local creates,actions=t.creates,t.actions
 for _=1,20 do t.api:RefreshLayout()end
 check(t.creates==creates and t.actions==actions,'unchanged reflow preserves widgets and secure action hydration')
 t:embed(256)
 local b=t.widgets[1];local _,_,w,h=b.Widget:rect();local _,_,sw,sh=b.SlotFrame:rect()
 check(math.abs(w-sw)<.001 and math.abs(h-sh)<.001,'embedded presentation retains its established button size')
 t:combatState(true);local writes=t.structuralWrites;t.api:RefreshLayout()
 check(t.structuralWrites==writes,'inset/layout work still defers without protected combat writes')
end
print('Minimap side cells: '..checks..' checks PASS; counts1..120; side scales10/100/200; UI scales.75/1/1.25; zero added visual gaps; unchanged embed/actions; combat deferral; native pixels/controller pending')
