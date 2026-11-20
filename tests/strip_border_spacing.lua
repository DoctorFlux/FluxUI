-- Actual decorative strip layout; no action attributes, handlers or bindings.
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function frame()
 return {ClearAllPoints=function(s)s.point=nil end,SetPoint=function(s,...)s.point={...}end,
 SetSize=function(s,w,h)s.width,s.height=w,h end,SetScale=function(s,v)s.scale=v end,
 SetAttribute=function()error('strip spacing must not touch action attributes')end}
end
local E=setmetatable({},{__index=_G});E._G=E;E.UIParent=frame()
local Bars={NUM_COLUMNS=19,CONFIG={buttonSize=45,padding=1,scale=1.24,margin=4,heightTweak=-2,yOffset=4}}
local Flux={Bars=Bars,Combat={InLockdown=function()return false end}}
local f=assert(io.open('Bars/Strip.lua','rb'));local source=f:read('*a');f:close()
assert(load(source,'@actual-strip-spacing','t',E))('_FluxUI',{Flux=Flux})
local strip=Bars.Strip;strip.frame,strip.inner,strip.sensing=frame(),frame(),frame();strip.SyncVisibility=function()end
for _,lift in ipairs({0,12,30})do for _,expanding in ipairs({false,true})do for _,mini in ipairs({false,true})do
 E.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome=function()return lift end
 strip.Layout(19,mini,expanding,1,1)
 check(strip.frame.point[5]==lift+2,'whole strip lowers two units against its existing status-bar floor')
 check(strip.inner.point[5]==-2,'buttons lower two units inside the unchanged strip dimensions')
 check(strip.inner.point[1]==(expanding and 'BOTTOM'or'CENTER'),'expanded/resting anchor behavior is preserved')
 check(strip.sensing.point[5]==lift+2-50,'existing sensing footprint follows the same strip shift')
 check(strip.frame.width==(19*45+18)*1.24+8,'column widths and button packing stay unchanged')
end end end
print('Strip border spacing: '..checks..' checks PASS; actual layout; preserved dimensions/packing/input; two-unit chrome/content shift; native pixels pending')
