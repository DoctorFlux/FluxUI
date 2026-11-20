-- Execute the existing actual-constructor/partition/combat fixture and check
-- the unfilled straight edge inside the portrait. No native pixel/taint claim.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local script=read('tests/unit_portrait_border_fit.lua')
local checks,scenes=0,0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<1e-7 end
local function rgba(t)return t.fill or t.color end
local function same(a,b)
 for i=1,4 do if a[i]~=b[i]then return false end end
 return true
end
local function inspect(frame,pf,border,B,UF,state,counts)
 scenes=scenes+1
 local fill=border.PortraitBackdropFill
 local bg=border.Background;local host=border.BackgroundFrame
 local x,y,w,h=host:GetRect()
 local function covers(t,px,py)
  if not t or not t.shown then return false end
  local ax,ay,aw,ah=t:GetRect()
  return px>=ax and px<=ax+aw and py>=ay and py<=ay+ah
 end
 local px=pf:GetRect()
 check(covers(bg,px+.125,y+h*.5)or covers(fill,px+.125,y+h*.5),
  'full portrait inset has backdrop coverage up to the portrait edge')
 local fx,fy,fw,fh=fill:GetRect()
 check(near(fx,px)and near(fx+fw,x),'continuation spans the full authored inset without double-opacity overlap')
 check(near(fy,y+5)and near(fy+fh,y+h-5),'continuation stops before the original rounded-corner areas')
 check(fill:GetParent()==host,'continuation inherits original backdrop opacity and visibility owner')
 check(same(rgba(fill),rgba(bg)),'first paint gives both fill regions the same material and alpha')
 local function covered(px,py)
  local ax,ay,aw,ah=fill:GetRect()
  return fill.shown and px>=ax and px<=ax+aw and py>=ay and py<=ay+ah
 end
 check(covered(x-.125,y+h*.5)and covered(px+.125,y+h*.5),'both edges of the complete portrait inset are filled')
 check(not covered(x-.5,y+1)and not covered(x-.5,y+h-1),'fix adds no color outside the old rounded corner footprint')
 local objects,writes=counts();local clears,levels=state.clears,state.levels
 state.locked=true
 for _=1,20 do
  B:SetBackdropColor(pf,.17,.31,.47,.85)
  check(same(rgba(fill),rgba(bg)),'ordinary class/custom/combat paint remains seamless')
  B:SetBackdropAlpha(pf,.4)
  check(same(rgba(fill),rgba(bg)),'alpha changes keep the same fill on both regions')
  B:HideBackground(pf);check(not fill.shown and not bg.shown,'hiding the backdrop hides its continuation')
  B:ShowBackground(pf);check(fill.shown and bg.shown,'show restores the prepared continuation')
 end
 -- A native class-color channel is forwarded unchanged; never compared,
 -- converted, indexed, or multiplied by the implementation.
 local opaque=setmetatable({},{__eq=function()error('private comparison')end,__mul=function()error('private arithmetic')end,__tostring=function()error('private formatting')end})
 B:SetNativeUnitBackdrop(pf,opaque,opaque,opaque)
 check(rawequal(rgba(fill)[1],opaque)and rawequal(rgba(bg)[1],opaque),'restricted native RGB reaches both backdrop sinks unchanged')
 local nativeFill,nativeBg=fill.SetColorTexture,bg.SetColorTexture
 fill.SetColorTexture=false;bg.SetColorTexture=false
 B:SetNativeUnitBackdrop(pf,opaque,opaque,opaque)
 check(rawequal(fill.color[1],opaque)and rawequal(bg.color[1],opaque),'legacy texture-color sinks also forward private RGB without arithmetic')
 fill.SetColorTexture=nativeFill;bg.SetColorTexture=nativeBg
 B:SetBackdropColor(pf,.1,.2,.3,.85)
 local after,afterWrites=counts()
 check(after==objects and afterWrites==writes and state.clears==clears and state.levels==levels,'warm color/alpha/visibility changes allocate or move no geometry')
 state.locked=false
 check(not B:PreparePortraitBackdrop(pf),'repeated preparation reuses the existing fill')
 check(select(1,counts())==objects,'idempotent preparation creates no draw resources')
end
local marker='local bf=pf.FluxBorderFrame;local tracks=b:GetJoinTracks()'
local at=assert(script:find(marker,1,true))
script=script:sub(1,at+#marker-1)..'\nInspectPortraitBackdrop(frame,pf,bf,b,uf,state,counts)\n'..script:sub(at+#marker)
local env=setmetatable({InspectPortraitBackdrop=inspect},{__index=_G});env._G=env
assert(load(script,'@actual-portrait-fit-plus-backdrop-gap','t',env))()
print('Portrait backdrop gap: '..checks..' checks /'..scenes..' actual constructors PASS; both styles/atlas-file paths/mirrors/scales; corner exclusions; color/alpha/private sinks; no warm geometry/resources; native pixels pending')
