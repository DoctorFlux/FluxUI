-- Actual controller: shrink within two vertical columns before adding a third.
-- Visual/hit cells meet without gaps; existing assigned order/window bounds and
-- the secure visibility/flyout owner remain independent of the fitting policy.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(os.getenv('FLUX_MINIMAP_EXTRA_SOURCE')or'Minimap/FluxMinimapButtons.lua')
local prefix=read('tests/minimap_extra_layout.lua')
prefix=prefix:sub(1,assert(prefix:find('local function physical(frame)',1,true))-1)
prefix=prefix:gsub('local source = read[^\n]*','local source = ...',1)
local boot=assert(load(prefix..'\nreturn boot','@side-packing-fixture','t',_G))(source)
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b,m)check(math.abs(a-b)<.001,m)end
for _,uiScale in ipairs{.75,1,1.25}do for _,percent in ipairs{10,100,200}do
 for _,start in ipairs{'top','below'}do for _,height in ipairs{12,80,240,543,800}do
  local t=boot();local e,m=t.env,t.api;e.UIParent:SetScale(uiScale)
  m:SetSetting('sideEnabled',true);m:SetSetting('sideStart',start);m:SetSetting('sideScale',percent)
  local top=start=='top'and e.UIParent:GetTop()or e.Minimap:GetBottom()
  t.window:ClearAllPoints();t.window:SetPoint('BOTTOMRIGHT',e.UIParent,'BOTTOMRIGHT',-20,top-height-t.window:GetHeight())
  local wx,wy,ww,wh=t.window:rect()
  local half=22*percent*.85/100*uiScale
  local available=height*uiScale
  local capacity=math.floor(available/half+.00001)
  local wanted={1,2,15,60,120,2*capacity,2*capacity+1}
  table.sort(wanted)
  local previousCount,previousSize=0,math.huge
  for _,count in ipairs(wanted)do if count>=1 and count<=120 and count~=previousCount then
   previousCount=count;m:SetSetting('count',count)
   local widgets=t:visible();check(#widgets==count,'packing retains every numbered action slot')
   local root=e.FluxMinimapButtonsContainer;local x,y,w,h=root:rect()
   local sx,sy,sw,sh=e.UIParent:rect()
   check(x>=sx-.001 and x+w<=sx+sw+.001,'dense/tall-scale packing never crosses screen sides')
   near(y+h,top*uiScale,'grid starts at the existing minimap/screen edge')
   check(y>=(top-height)*uiScale-.001,'grid stays above the existing Flux Window')
   local first=widgets[1].Widget;local _,_,size=first:rect()
   local columns=math.floor(w/size+.5)
   if count<=2*capacity then check(columns<=2,'third column waits until two half-native columns cannot hold the count')end
   if columns>2 then check(count>2*capacity,'additional columns have a real two-column capacity witness')end
   local minWidth=capacity>0 and math.ceil(count/capacity)*half or math.huge
   if minWidth<=sw+.001 then check(size>=half-.001,'half-native density floor is retained whenever screen bounds permit')end
   local maximum=44*percent*.85/100*uiScale
   check(size<=maximum+.001 and size<=previousSize+.001,'more actions shrink or retain size without growing controls')
   previousSize=size
   if count*maximum<=available+.001 then near(size,maximum,'short lists retain the configured native size')end
   local prior
   for _,button in ipairs(widgets)do
    local bx,by,bw,bh=button.Widget:rect()
    if prior then
     if math.abs(bx-prior[1])<.001 then near(by+bh,prior[2],'successive vertical buttons meet with zero added gap')
     else near(bx+bw,prior[1],'adjacent columns meet with zero added gap');near(by+bh,y+h,'new column retains original column-first order')end
    end
    prior={bx,by,bw,bh}
   end
   local nx,ny,nw,nh=t.window:rect()
   near(nx,wx,'side fitting cannot move Flux Window');near(ny,wy,'side fitting cannot move Flux Window vertically')
   near(nw,ww,'side fitting cannot resize Flux Window');near(nh,wh,'side fitting cannot resize Flux Window height')
  end end
  local creates,actions=t.creates,t.actions
  for _=1,10 do m:RefreshLayout()end
  check(t.creates==creates and t.actions==actions,'settled fitting reuses widgets and saved action hydration')
  t:combatState(true);local writes=t.structuralWrites;m:SetSetting('count',119);m:RefreshLayout()
  check(t.structuralWrites==writes,'new density fitting still defers all protected combat layout writes')
 end end
end end
-- Explicit cross-setting witnesses: the same count must choose more columns
-- when grid scale consumes more height, and changing count at one fixed scale
-- must independently change columns. This guards against a hardcoded two-column
-- layout or an accidental scale-only/count-only decision.
do
 local t=boot();local e,m=t.env,t.api;m:SetSetting('sideEnabled',true);m:SetSetting('sideStart','below')
 local top=e.Minimap:GetBottom()
 t.window:ClearAllPoints();t.window:SetPoint('BOTTOMRIGHT',e.UIParent,'BOTTOMRIGHT',-20,top-330-t.window:GetHeight())
 local function columns(count,percent)
  m:SetSetting('count',count);m:SetSetting('sideScale',percent)
  local _,_,width=e.FluxMinimapButtonsContainer:rect();local _,_,size=t.widgets[1].Widget:rect()
  return math.floor(width/size+.5)
 end
 local lowSmall,lowDense=columns(4,50),columns(40,50)
 local highSmall,highDense=columns(4,200),columns(40,200)
 check(lowSmall==1 and highSmall==1,'a short list remains one native-size column at either scale when it fits')
 check(lowDense==2 and highDense>2,'same40buttons use two columns at50percent but additional columns at200percent')
 check(lowDense>lowSmall and highDense>highSmall,'column count independently responds to button count at each unchanged scale')
 local lowCapacity=2*math.floor(330/(22*.5*.85)+.00001)
 local highCapacity=2*math.floor(330/(22*2*.85)+.00001)
 check(40<=lowCapacity and 40>highCapacity,'scale-dependent column change has a two-half-native-column capacity witness')
end
print('Minimap side packing: '..checks..' checks PASS; two columns shrink to half-native before third; zero neighbor gaps; count/order/window preservation; tiny-height screen fallback; scales and density boundaries; reuse/combat guards; native pixels pending')
