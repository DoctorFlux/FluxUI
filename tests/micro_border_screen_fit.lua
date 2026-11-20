-- Actual shared border factory and MicroMenu fitting routine. Screen clipping
-- must not alter the menu's button/content rectangle or leave its fill behind.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local fixture=assert(read('tests/border_types.lua'):match('^(.-)for _, forever in ipairs'))
local model=assert(load(fixture..'\nreturn model','@micro-border-fixture','t',_G))()
local source=read(arg[1]or'MicroMenu/FluxMicroMenu.lua')
local a=source:find('function FluxMicroMenu:FitScreenBorder()',1,true)
local helper=a and source:sub(a,assert(source:find('local BESIDE_CHAT_ABOVE_GRID_GAP',a,true))-1)or''
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local factors={TOPLEFT={0,1},TOPRIGHT={1,1},BOTTOMLEFT={0,0},BOTTOMRIGHT={1,0}}
for _,forever in ipairs{false,true}do for _,screenScale in ipairs{.64,.75,1}do for _,factor in ipairs{.75,1,1.25}do for _,pad in ipairs{0,-2}do
 for _,edge in ipairs{'left','corners','right'}do
  local e,b,db,new,counts=model(forever,'none');local root=new(e.UIParent);local locked=false
  local m=getmetatable(root).__index
  function m:GetEffectiveScale()return(self.scale or 1)*(self.parent and self.parent:GetEffectiveScale()or 1)end
  function m:ClearAllPoints()self.points={};self.allPoints=nil end
  local function rect(o)
   if o.rect then return table.unpack(o.rect)end
   if o.allPoints or #o.points==0 then return rect(o.allPoints or o.parent)end
   local c={}
   for _,p in ipairs(o.points)do
    local relative=p[2]or o.parent;local x,y,w,h=rect(relative);local r=factors[p[3]];local f=factors[p[1]]
    local ratio=relative:GetEffectiveScale()/o:GetEffectiveScale()
    c[#c+1]={f[1],(x+r[1]*w)*ratio+(p[4]or 0),f[2],(y+r[2]*h)*ratio+(p[5]or 0)}
   end
   local function axis(i,size)
    local first=c[1]
    for k=2,#c do if c[k][i]~=first[i]then size=(c[k][i+1]-first[i+1])/(c[k][i]-first[i]);break end end
    return first[i+1]-first[i]*size,size
   end
   local x,w=axis(1,o.width);local y,h=axis(3,o.height);return x,y,w,h
  end
  function m:GetRect()return rect(self)end
  e.UIParent.scale=screenScale;e.UIParent.rect={0,0,1920,1080};root.scale=factor
  root.rect=edge=='right'and{1920/factor-80,100,80,250}or edge=='corners'and{0,0,80,250}or{2,100,80,250}
  e.FluxMicroMenu=root;e.FluxBorder=b;e.InCombatLockdown=function()return locked end
  e.hooksecurefunc=function(object,key,fn)local original=object[key];object[key]=function(...)local r={original(...)};fn(...);return table.unpack(r)end end
  b:ApplyTo(root,pad,pad,0,0);b:SetClassColor(root)
  assert(load(helper,'@actual-micro-screen-fit','t',e))()
  if not root.FitScreenBorder then root.FitScreenBorder=function()return false end end
  local original={table.unpack(root.rect)};local bf=root.FluxBorderFrame;local bg=bf.BackgroundFrame
  for _,style in ipairs{1,2}do
   db.borderType=style;b:RefreshAllBorderTypes();root:FitScreenBorder()
   local tracks=b:GetJoinTracks();local lx,_,lw=bf.Left:GetRect();local _,ty,_,th=bf.Top:GetRect()
   local left=(lx+lw*tracks.Left/16)*root:GetEffectiveScale()
   local top=(ty+th-th*tracks.Top/17)*root:GetEffectiveScale()
   local gx,gy,gw,gh=bg:GetRect();local _,ry,rw,rh=bf.Right:GetRect();local _,by,_,bh=bf.Bottom:GetRect()
   local rx=select(1,bf.Right:GetRect())+rw*tracks.Right/16
   local bottom=by+bh-bh*tracks.Bottom/16
   check(left>=-.0001 and rx*root:GetEffectiveScale()<=1920*screenScale+.0001,'left/right strokes stay inside the actual screen in both styles')
   check(math.abs(gx*root:GetEffectiveScale()-left)<.0001 and math.abs((gy+gh)*root:GetEffectiveScale()-top)<.0001,'fill meets corrected left/top border instead of the old content inset')
   check(math.abs(gx+gw-rx)<.0001 and math.abs(gy-bottom)<.0001,'fill meets right/bottom core as well')
   for i=1,4 do check(root.rect[i]==original[i],'content dimensions and position stay fixed')end
   local _,writes=counts();for _=1,20 do check(not root:FitScreenBorder(),'unchanged fitting reuses the committed bounds')end
   local _,after=counts();check(writes==after,'unchanged fitting performs no geometry writes')
  end
  local _,writes=counts();locked=true;check(not root:FitScreenBorder()and root.needsUpdate,'combat defers decorative fitting through the existing layout flag')
  local _,after=counts();check(writes==after,'combat cannot mutate protected menu geometry')
  locked=false
  local secret={};e.issecretvalue=function(v)return rawequal(v,secret)end
  root.rect[1]=secret;local _,before=counts()
  check(not root:FitScreenBorder(),'restricted geometry remains owned by native code')
  local _,afterPrivate=counts();check(before==afterPrivate,'restricted coordinates cause no decorative geometry writes')
 end
end end end end
print('MicroMenu screen border: '..checks..' checks PASS; actual factory/fitter; both styles; screen/menu scales; left/right/bottom clipping; matched backdrop; unchanged content; static cache; combat guard; native pixels/controller pending')
