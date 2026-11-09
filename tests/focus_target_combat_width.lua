-- Actual focus metrics and global squeeze owners, without rendering or a native VM.
local function read(p) local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function section(s,a,b) local i=assert(s:find(a,1,true),a);return s:sub(i,assert(s:find(b,i+#a,true),b)-1) end
local checks=0
local function check(v,m) assert(v,m);checks=checks+1 end
local shared=read(os.getenv('FLUX_WIDTH_SHARED') or 'UnitFrames/FluxUnitFrames_Shared.lua')
local source=read(os.getenv('FLUX_WIDTH_FOCUS') or 'UnitFrames/FluxUnitFrames_FocusTarget.lua')
for _,client in ipairs({'live','forever','classic','classic_era','classic_anniversary'})do
 local E=setmetatable({},{__index=_G});E._G=E
 local combat,writes,width=false,0,30
 local queue={}
 local UF={}
 local focus={_fluxCompactFocus=true,outerBorderPadding=36,width=260,height=85}
 local frame={unit='focustarget',_fluxVerticalFocusTarget=true,_fluxLayoutBaseWidth=119,width=119,height=30}
 function frame:SetSize(w,h) assert(not combat,'protected resize in combat');writes=writes+1;self.width,self.height=w,h end
 function frame:SetWidth(w) assert(not combat,'protected width in combat');writes=writes+1;self.width=w end
 function frame:UpdatePartition() end
 function focus:GetWidth()return self.width end
 function focus:GetHeight()return self.height end
 UF.RecordFrameDimensions=function(f,w,h)f.publicWidth,f.publicHeight=w,h end
 UF.GetFramePublicDimensions=function(f)return f.publicWidth or f.width,f.publicHeight or f.height end
 UF.DeferProtected=function(key,fn)queue[key]=fn end
 E.ns={UnitFrames=UF,FocusFrame=focus};E.UF=UF
 E.FluxOptions={GetRaidFrameDB=function()return {partyTargetWidth=width}end}
 E.InCombatLockdown=function()return combat end
 E.FluxUILayoutSqueeze={GetEffectiveEmulatedDependentXFactorForUnitFrames=function()return .75 end}
 local metrics=assert(load(section(source,'local function PublicNumber','local function AnchorFocusTarget')..'\nreturn MatchFocusBarMetrics','@actual-focus-metrics','t',E))()
 E.FluxUnitFrames_MatchFocusTargetToFocus=function()metrics(frame)end
 assert(load(section(shared,'local function ApplyEmulatedHorizontalSqueezeToFrame','function UF.UpdateAllEmulatedHorizontalSqueeze'),
  '@actual-squeeze','t',E))()
 metrics(frame)
 check(frame.width==30 and frame.height==121,client..' compact strip owns its narrow configured width before focus exists')
 for _=1,20 do UF.ApplyEmulatedHorizontalSqueezeForFrame(frame)end
 check(frame.width==30,client..' world/scale/layout refresh cannot restore original wide construction size')
 local before=writes;combat=true
 for _=1,20 do metrics(frame);UF.ApplyEmulatedHorizontalSqueezeForFrame(frame)end
 check(frame.width==30 and writes==before,client..' first combat focus with a target retains narrow geometry without protected writes')
 width=42;metrics(frame)
 check(frame.width==30 and next(queue)~=nil,client..' combat option change is deferred')
 combat=false
 local pending=queue;queue={};for _,fn in pairs(pending)do fn()end
 check(frame.width==42 and frame._fluxLayoutBaseWidth==42,client..' latest strip width replays after combat')
 UF.ApplyEmulatedHorizontalSqueezeForFrame(frame)
 check(frame.width==42,client..' deferred width survives next squeeze refresh')
end
print('Focus target combat width: '..checks..' checks; five client models; native pixels/combat pending')
