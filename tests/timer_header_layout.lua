-- Real cast + swing/shoot producers. Native anchor/clip contracts are modeled;
-- these checks do not certify in-game pixels, combat taint or frame rate.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local src=read('tests/castbar_school_themes.lua')
src=src:sub(1,assert(src:find('local function checkParticleGeometry',1,true))-1)
for i,path in ipairs{'UnitFrames/FluxCastBar.lua','UnitFrames/FluxCastBarThemes.lua'}do
 if arg[i]then local n;src,n=src:gsub('loadAddon%("'..path..'",env,ns%)',function()return'loadAddon('..string.format('%q',arg[i])..',env,ns)'end);assert(n==1)end
end
local fixture=assert(load(src..'\nreturn fixture','@timer-header-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<1e-7 end
local function visuals(fx)for i=1,30 do local k,v=debug.getupvalue(fx.Update,i);if k=='visuals'then return v end end;error('visual registry missing')end
local coeff={TOPLEFT={0,1},TOPRIGHT={1,1},BOTTOMLEFT={0,0},BOTTOMRIGHT={1,0},LEFT={0,.5},RIGHT={1,.5},TOP={.5,1},BOTTOM={.5,0},CENTER={.5,.5}}
local function rect(o,seen)
 seen=seen or{};assert(not seen[o],'anchor cycle');seen[o]=true
 local x,y,w,h=0,0,o.width,o.height
 if o.allPoints then x,y,w,h=rect(o.allPoints,seen)
 elseif o.points and o.points[1]then
  local function target(p)local a,b,c,d=rect(p[2]or o.parent,seen);local k=coeff[p[3]or p[1]];return a+k[1]*c+(p[4]or 0),b+k[2]*d+(p[5]or 0)end
  local p=o.points[1];local ax,ay=target(p);local a=coeff[p[1]]
  local q=o.points[2]
  if q then local bx,by=target(q);local b=coeff[q[1]];if b[1]~=a[1]then w=(bx-ax)/(b[1]-a[1])end;if b[2]~=a[2]then h=(by-ay)/(b[2]-a[2])end end
  x,y=ax-a[1]*w,ay-a[2]*h
 end
 seen[o]=nil;return x,y,w,h
end
local function sameRect(a,b)
 local ax,ay,aw,ah=rect(a);local bx,by,bw,bh=rect(b)
 return near(ax,bx)and near(ay,by)and near(aw,bw)and near(ah,bh)
end
local function paintedRect(o)
 local x,y,w,h=rect(o);local r,t=x+w,y+h;local p=o.parent
 while p do if p.clipped then local a,b,c,d=rect(p);x,y,r,t=math.max(x,a),math.max(y,b),math.min(r,a+c),math.min(t,b+d)end;p=p.parent end
 return x,y,math.max(0,r-x),math.max(0,t-y)
end
for _,client in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do for _,below in ipairs{false,true}do
 local s,e,ns=fixture(client);local combat=false;local jobs,calls={},0
 e.InCombatLockdown=function()return combat end
 ns.UnitFrames.DeferProtected=function(k,fn)jobs[k]=fn;calls=calls+1 end
 -- Use actual secure-hook callback ordering so the swing row follows the real
 -- cast layout and native cover paint, rather than invoking a parallel copy.
 e.hooksecurefunc=function(o,k,fn)local orig=o[k];o[k]=function(...)local out={orig(...)};fn(...);return table.unpack(out)end end
 local profile={Top=8,Bottom=8,Right=9.5}
 ns.Border.GetJoinTracks=function()return profile end
 ns.Border.GetSideTrackOffset=function(_,side,padding)assert(side=='Right'and padding==2);return -padding+7-16+profile.Right end
 ns.Border.ApplyTo=function(_,f)f.FluxBorderFrame=e.CreateFrame('Frame',nil,f)end
 ns.Border.SetClassColor=function()end
 local dual=false
 e.UnitAttackSpeed=function()return 2,dual and 2 or 0,2 end
 e.UnitRangedDamage=function()return 2 end
 e.GetInventoryItemID=function()return 7001 end
 e.GetInventoryItemLink=function()return'item:7001'end
 e.GetItemInfo=function()return nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,2,19 end
 e.C_Item={GetItemInfoInstant=function()return 7001,nil,nil,nil,nil,2,19 end}
 e.C_TooltipInfo={GetInventoryItem=function()return{lines={{leftText='12 - 24 Fire Damage'}}}end}
 ns.API.GetSpellInfo=function()return nil,nil,132208 end
 local bar=s.NewBar('player');local owner=bar:GetParent()
 owner.outerBorderPadding=36;owner.outerBorderAlignment=below and'TOP'or'BOTTOM'
 owner.outerBorderFrame=e.CreateFrame('Frame',nil,owner);owner.outerBorderFrame:SetSize(300,124)
 owner.atlasBorderFrame=e.CreateFrame('Frame',nil,owner);owner.atlasBorderFrame:SetSize(300,88)
 bar:UpdateLayout()
 check(bar.IconFrame:GetWidth()==40 and bar.IconFrame:GetHeight()==36 and bar:GetWidth()==260,
  'cast icon gains exactly four horizontal pixels without moving the header or changing its height')
 local methods=getmetatable(bar).__index
 -- Resolve the real public point equations for size getters in this fixture.
 methods.GetWidth=function(o)local _,_,w=rect(o);return w end
 methods.GetHeight=function(o)local _,_,_,h=rect(o);return h end
 methods.GetSize=function(o)local _,_,w,h=rect(o);return w,h end
 local headerWrites=0
 for _,k in ipairs{'SetPoint','SetAllPoints','ClearAllPoints','SetSize','SetWidth','SetHeight','SetFrameLevel','SetParent'}do
  local original=methods[k];methods[k]=function(o,...)if o._guardHeader then headerWrites=headerWrites+1;check(not combat,'protected header setter '..k..' during combat')end;return original(o,...)end
 end
 local function interiorClip(subject)
  local x,y,w,h=rect(subject.FillEffectClip)
  local fx,fy,fw,fh=rect(subject.TimerBar)
  local bx,by,bw,bh=rect(bar.BorderFrame)
  local ix,_,iw=rect(bar.IconFrame)
  -- Independent factory pad2 core equations, rather than clip anchor labels.
  local divider=ix+iw-11+profile.Right
  local coreTop,coreBottom=by+bh+4-profile.Top,by+11-profile.Bottom
  check(near(x,divider)and near(y,coreBottom)and near(y+h,coreTop),'glow clip reaches the real header core tracks and sole icon-right divider')
  check(near(x+w,fx+fw)and near(h,fh+4)and x>fx,'clip keeps its right boundary, admits the four-unit glow band and excludes native icon underlap')
  check(not sameRect(subject.FillEffectClip,subject.TimerBar)and sameRect(subject.FillEffectHost,subject.FillEffectClip),'school art host uses the authored interior, not the smaller progress rectangle')
  return x,y,w,h,fx,fy,fw,fh
 end
 local function fireBounds(subject)
  local v=visuals(ns.CastBarThemes)[subject];check(v and v.theme==ns.CastBarThemes.ThemeForMask(4),'actual Fire cast selects its original palette')
  local fill=subject.TimerBar;local cx,cy,cw,ch,fx,fy,fw,fh=interiorClip(subject)
  check(subject.FillEffectHost and subject.FillEffectClip and subject.FillEffectClip.clipped
   and subject.FillEffectHost:GetParent()==subject.FillEffectClip,'artwork lives on an actual child of the prepared native clip')
  check(subject.FillEffectHost:GetFrameLevel()<fill:GetFrameLevel(),'school glow is behind its fill rather than a colored overlay on the icon')
  for _,art in ipairs{v.halo,v.backdrop}do
   local ax,_,aw=rect(art);check(ax<fx and ax+aw>fx+fw,'actual existing Fire artwork extends outside the fill before clipping')
   local x,y,w,h=paintedRect(art)
   check(x>=cx-1e-7 and y>=cy-1e-7 and x+w<=cx+cw+1e-7 and y+h<=cy+ch+1e-7,'actual Fire halo/backdrop is bounded by border cores and cannot cross the icon divider')
   check(y<fy-1e-7 and y+h>fy+fh+1e-7,'oversized art can reach the previously excluded upper and lower glow bands')
   check(art:GetParent()==subject.FillEffectHost,'oversized school art uses the cast-owned clipped host')
  end
  check(v.fill:GetParent()==fill and bar.Spark:GetParent()==bar.SparkFrame,'fill and native progress spark keep their existing owners')
 end
 ns.CastBarSchools.Learn(133,4);s.Cast('player',133);fireBounds(bar)
 local pet=s.NewBar('pet');local petOwner=pet:GetParent();petOwner.outerBorderPadding=0
 petOwner.Power=e.CreateFrame('StatusBar',nil,petOwner);petOwner.Power:SetSize(90,18);pet:UpdateLayout()
 local function petClip()
  check(sameRect(pet.FillEffectClip,pet.TimerBar)and sameRect(pet.FillEffectHost,pet.TimerBar),'pet retains its original resource-row clip and host')
 end
 petClip();s.Cast('pet',133)
 for _,art in ipairs{visuals(ns.CastBarThemes)[pet].halo,visuals(ns.CastBarThemes)[pet].backdrop}do
  local x,y,w,h=paintedRect(art);local px,py,pw,ph=rect(pet.TimerBar)
  check(x>=px-1e-7 and y>=py-1e-7 and x+w<=px+pw+1e-7 and y+h<=py+ph+1e-7,'pet art remains inside its accepted resource clip')
 end
 pet:Hide()
 bar.casting=nil;bar:Hide()
 local swingSource=arg[3]or'UnitFrames/FluxSwingTimer.lua'
 assert(load(read(swingSource),'@'..swingSource,'t',e))('FluxUI',ns)
 local st=ns.SwingTimer
 combat=true;local count=#s.frames
 for _=1,20 do st.AttachToCastBar(bar,'player')end
 check(#s.frames==count and calls==1,'cold combat attachment allocates nothing and coalesces through the existing defer service')
 combat=false;for k,fn in pairs(jobs)do jobs[k]=nil;fn()end
 local swing,ranged,events
 for _,f in ipairs(s.frames)do if f.FillFrame then swing=f end;if f.cooldownTex and f.TimerBar==f then ranged=f end;if f.events.START_AUTOREPEAT_SPELL then events=f end end
 check(swing and ranged and events,'actual swing/shoot module creates its existing visual and event slots')
 local function fit()
  check(sameRect(swing,bar)and sameRect(swing.FillFrame,bar.TimerBar),'swing/shoot body and fill use the real cast row rather than independent insets')
  for _,k in ipairs{'Icon','IconFrame','IconBorder','BorderFrame','HeaderCover'}do check(sameRect(swing[k],bar[k]),'shared cast source owns the actual '..k..' bounds')end
  check(sameRect(ranged,swing.FillFrame),'Shoot always has the same prepared content rectangle as casting')
  check(sameRect(ranged.FillEffectClip,bar.FillEffectClip)and sameRect(ranged.FillEffectHost,bar.FillEffectClip),'swing-owned Shoot glow follows the prepared cast interior through real layout hooks')
  interiorClip(ranged)
  local bx,_,bw=rect(bar);local tx,_,tw=rect(swing.TextHolder)
  check(near(tx,bx-2)and near(tw,bw),'swing/Shoot label origin and width remain unchanged when the fill underlaps its icon divider')
  check(swing._FluxBorderOwner==owner and swing._FluxBorderCast,'swing shares the unit-owned cast connection scope')
  check(swing.IconBorder.FluxBorderFrame._FluxBorderCastInternalSide=='Right'and swing.BorderFrame.FluxBorderFrame._FluxBorderCastInternalSide=='Left','only the shared icon/body cap sides become T/X junctions')
 end
 fit()
 local melee={}
 for _,f in ipairs(s.frames)do if f:GetParent()==swing and f.fillTexture then melee[#melee+1]=f end end
 check(#melee==2 and sameRect(melee[1],swing.FillFrame)and not melee[2]:IsShown(),'single-weapon swing occupies the same entire cast fill')
 dual=true;events.scripts.OnEvent(events,'WEAPON_SLOT_CHANGED')
 local _,my,_,mh=rect(melee[1]);local _,oy,_,oh=rect(melee[2]);local _,fy,_,fh=rect(swing.FillFrame)
 check(melee[2]:IsShown()and near(my,oy+oh)and near(oy,fy)and near(mh+oh,fh),'dual-wield halves exactly tile the same cast content with no gap or extra padding')
 dual=false;events.scripts.OnEvent(events,'WEAPON_SLOT_CHANGED')
 check(sameRect(melee[1],swing.FillFrame)and not melee[2]:IsShown(),'returning to one weapon restores the full prepared fill')
 for _,f in ipairs{bar,bar.IconFrame,bar.IconBorder,bar.BorderFrame,bar.TimerBar,bar.FillEffectClip,bar.FillEffectHost,swing,swing.IconFrame,swing.IconBorder,swing.BorderFrame,swing.FillFrame,ranged,ranged.FillEffectClip,ranged.FillEffectHost}do f._guardHeader=true end
 local positions,sizes,frames,textures=s.work.positions,s.work.sizes,#s.frames,#s.textures
 local writes=headerWrites
 for _=1,100 do bar:UpdateLayout()end
 check(s.work.positions==positions and s.work.sizes==sizes and #s.frames==frames and #s.textures==textures and headerWrites==writes,'100 unchanged real cast hooks preserve static headers/clips without any native geometry setters or resources')
 local sourceLevel=bar.GetFrameLevel;bar.GetFrameLevel=function()return s.secret end
 bar:UpdateLayout();bar.GetFrameLevel=sourceLevel
 check(s.work.positions==positions and s.work.sizes==sizes,'restricted frame levels are never used for swing arithmetic or geometry')
 bar.HeaderCover:SetVertexColor(.1,.2,.3,1)
 check(swing.HeaderCover.color[1]==.1 and swing.HeaderCover.color[3]==.3,'native class/accent cover paint updates without relayout')
 bar.HeaderCover:SetVertexColor(s.secret,.2,.3,1)
 check(rawequal(swing.HeaderCover.color[1],s.secret),'opaque paint is forwarded only to the native color sink without comparison or arithmetic')
 bar.HeaderCover:SetVertexColor(.1,.2,.3,1)
 for _,style in ipairs{2,1}do profile=style==1 and{Top=8,Bottom=8,Right=9.5}or{Top=9,Bottom=7,Right=9};bar:UpdateLayout();pet:UpdateLayout();fit();interiorClip(bar);petClip()end
 events.scripts.OnEvent(events,'START_AUTOREPEAT_SPELL');swing:Show();ns.CastBarThemes.BeginMask(ranged,'player',4);fireBounds(ranged)
 -- Both mode geometries exist before combat. Ranged/melee swaps repaint only.
 combat=true;positions=s.work.positions;sizes=s.work.sizes;count=calls;writes=headerWrites
 for _=1,20 do events.scripts.OnEvent(events,'STOP_AUTOREPEAT_SPELL');events.scripts.OnEvent(events,'START_AUTOREPEAT_SPELL')end
 check(s.work.positions==positions and s.work.sizes==sizes and headerWrites==writes,'combat ranged/melee switches do not rewrite prepared headers or clips')
 check(calls-count<=1,'combat frame-level reconciliation is coalesced rather than queued per timer event')
 -- A genuine layout change remains deferred and is applied once after combat.
 owner.outerBorderFrame.width=320;bar:UpdateLayout();bar:UpdateLayout()
 combat=false;for k,fn in pairs(jobs)do jobs[k]=nil;fn()end
 fit();positions=s.work.positions;sizes=s.work.sizes;bar:UpdateLayout()
 check(s.work.positions==positions and s.work.sizes==sizes,'completed real header reflow becomes static again')
end end
print('Timer header layout: '..checks..' checks PASS; actual cast/Fire/swing/Shoot; fitted native clip bounds; both styles/alignments; shared source geometry; static unchanged hooks; cold/combat defer. Native pixels/taint/FPS pending')
