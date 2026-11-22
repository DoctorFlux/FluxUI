-- Actual cast creator/layout/lifecycle with five client-shaped API fixtures.
-- Desktop geometry and work evidence; no native pixel/FPS/taint claim.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local src=read('tests/castbar_school_themes.lua')
src=src:sub(1,assert(src:find('local function checkParticleGeometry',1,true))-1)
src=src:gsub('pet="PetFrame"','pet="PetFrame",party1="PartyFrame"')
if arg[1]then
 local replaced;src,replaced=src:gsub('loadAddon%("UnitFrames/FluxCastBar.lua",%s*env,%s*ns%)',function()return 'loadAddon('..string.format('%q',arg[1])..', env, ns)'end)
 assert(replaced==1)
end
local fixture=assert(load(src..'\nreturn fixture','@cast-border-fixture','t',_G))()
local partyCastCover=assert(read('UnitFrames/FluxUnitFrames_Party.lua'):match(
 'function Party.SyncCastCover%(frame%).-\nend\n'))
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<1e-8 end
for _,client in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
 for _,unit in ipairs{'player','target','focus','pet','party1'}do for _,alignment in ipairs{'BOTTOM','TOP'}do
  local s,e,ns=fixture(client);local combat=false;local deferred,deferCount={},0
  e.InCombatLockdown=function()return combat end
  ns.UnitFrames.DeferProtected=function(key,fn)deferred[key]=fn;deferCount=deferCount+1 end
  local own={r=.8,g=.2,b=.1}
  ns.UnitFrames.GetUnitChromeColors=function()return own.r,own.g,own.b,own.r*.4,own.g*.4,own.b*.4 end
  local accent={.3,.5,.7}
  e.FluxBorder={GetThemedVertexRGB=function()return table.unpack(accent)end,GetThemedBackdropFillRGB=function()return accent[1]*.4,accent[2]*.4,accent[3]*.4 end}
  local applications={}
  local profile={Top=8,Bottom=8}
  ns.Border.GetJoinTracks=function()return profile end
  ns.Border.ApplyTo=function(_,surface,...)applications[#applications+1]={surface=surface,padding={...}};surface.FluxBorderFrame=e.CreateFrame('Frame',nil,surface);surface.FluxBorderFrame:SetFrameLevel(surface:GetFrameLevel()+10)end
  ns.Border.SetBorderColor=function(_,surface,r,g,b,a)surface.borderColor={r,g,b,a}end
  ns.Border.SetBackdropColor=function(_,surface,r,g,b,a)surface.backColor={r,g,b,a}end
  local bar=s.NewBar(unit);local frame=bar:GetParent()
  frame.outerBorderPadding=36;frame.outerBorderAlignment=alignment
  frame.atlasBorderFrame=e.CreateFrame('Frame',nil,frame);frame.atlasBorderFrame:SetWidth(304)
  frame.outerBorderFrame=e.CreateFrame('Frame',nil,frame);frame.outerBorderFrame:SetSize(300,124)
  frame._fluxPartyMember=unit=='party1';frame._fluxPartyClassChrome=true
  if unit=='party1'then ns.PartyFrames={members={frame}} end
  if unit=='pet'then
   frame.outerBorderPadding=0 -- Actual FluxUnitFrames_Pet.lua constructor metadata.
   frame.Power=e.CreateFrame('StatusBar',nil,frame);frame.Power:SetSize(90,18);frame.Power:SetFrameLevel(12)
   frame.atlasBorderFrame=nil;frame.outerBorderFrame=nil -- Power overlay has no header dependency.
  end
  bar:UpdateLayout()
  local positions,sizes,frames,textures=s.work.positions,s.work.sizes,#s.frames,#s.textures
  for _=1,100 do bar:UpdateLayout();bar:Hide();bar:Show()end
  check(s.work.positions==positions and s.work.sizes==sizes and #s.frames==frames and #s.textures==textures,
   'unchanged cast shell/icon layout reuses geometry and resources through parent visibility')
  check(bar._FluxBorderCast and bar._FluxBorderJunctionRole=='connected'and bar._FluxBorderOwner==frame,'cast row advertises one isolated unit-owned connection scope')
  check(#applications==2,'one native shared border per icon/body surface; no duplicate private shell')
  for _,row in ipairs(applications)do for i=1,4 do check(row.padding[i]==2,'identical icon/body shared-border insets preserved')end end
  if unit=='pet'then
   check(bar:GetWidth()==90 and bar:GetHeight()==18 and bar.IconFrame:GetWidth()==0,'real padding0 pet uses full Power dimensions without reserving an icon column')
   check(bar.IconFrame:GetHeight()==0 and bar.ShieldOverlay:GetWidth()==22 and near(bar.ShieldOverlay:GetHeight(),22*1.78),'unused pet icon and shield dimensions retain the original body-only layout')
   check(bar.TimerBar.points[1][4]==2 and bar._fluxPreparedLayout.contentWidth==86,'pet retains the native two-pixel horizontal resource fill insets')
   check(not bar.IconFrame:IsShown()and bar.IconBorder._FluxBorderJunctionRole=='overlay','permanently absent pet icon cannot own a connected edge')
   check(bar.allPoints==frame.Power and bar:GetFrameLevel()>frame:GetFrameLevel()+30,'pet shell remains on its power row above underlying unit text')
   check(bar.TimerBar.points[1][5]==-2 and bar.TimerBar.points[2][5]==2,'pet retains native two-pixel resource-fill insets')
  else
   check(bar:GetWidth()==260 and bar:GetHeight()==36 and bar.IconFrame:GetWidth()==40 and bar.IconFrame:GetHeight()==36,'four-pixel wider icon keeps the actual unit header height and total width fixed')
   check(bar.ShieldOverlay:GetWidth()==62 and near(bar.ShieldOverlay:GetHeight(),58*1.78),'shield follows the wider icon while retaining its original height')
   check(bar.TimerBar.points[1][4]==-4 and bar._fluxPreparedLayout.contentWidth==262 and bar.bg:GetWidth()==262,'cast fill and trough cover the rounded leading cap beneath the icon divider while retaining the right inset')
   local p=bar.points[1];check(p[1]=='LEFT'and p[2]==bar.IconFrame and p[3]=='RIGHT'and p[4]==0,'icon/body touch with the existing zero-gap anchor')
   p=bar.IconFrame.points[1];check(p[2]==frame.outerBorderFrame and p[1]==(alignment=='BOTTOM'and'TOPLEFT'or'BOTTOMLEFT')and p[5]==0,'cast row overlays the exact outer name/header strip')
  end
  check(bar.HeaderCover:GetParent()==bar and bar.HeaderCover.color[4]==1,'one preallocated opaque cast-owned plate covers lower name/spec/divider paint')
  local coverTop,coverBottom=bar.HeaderCover.points[1],bar.HeaderCover.points[2]
  if unit=='pet'then
   check(coverTop[5]==-2 and coverBottom[5]==2,'pet cover retains its native two-pixel resource insets')
  else
   local glyphTop=alignment=='BOTTOM'and -4 or 4
   check(coverTop[5]==glyphTop and coverBottom[5]==glyphTop,'header cover begins at the actual underlying class/spec glyph top without leaving a one-pixel strip')
   check(coverTop[4]==2 and coverBottom[4]==-2,'header cover remains inset under the rounded exterior border')
  end
  for _,style in ipairs{1,2}do
   profile=style==1 and{Top=8,Bottom=8}or{Top=9,Bottom=7};e.FluxCastBar_ApplyAppearanceAccent()
   local host=bar.BorderFrame;local top,bottom=host.points[1][5],host.points[2][5]
   if unit~='pet'then
    check(bar.IconBorder.FluxBorderFrame._FluxBorderCastInternalSide=='Right'and host.FluxBorderFrame._FluxBorderCastInternalSide=='Left','only facing icon/body caps are marked as internal')
    local rowBottom=alignment=='BOTTOM'and 88 or 0;local rowTop=rowBottom+36
    local coreTop=rowTop+top+4-profile.Top;local coreBottom=rowBottom+bottom+11-profile.Bottom
    local atlasJoin=alignment=='BOTTOM'and 88+4-profile.Top or 36+11-profile.Bottom
    check(near(alignment=='BOTTOM'and coreBottom or coreTop,atlasJoin),'decorative profile meets the original atlas edge core exactly in either style')
    local fillTop=rowTop+bar.TimerBar.points[1][5];local fillBottom=rowBottom+bar.TimerBar.points[2][5]
    check(near(coreTop-fillTop,2)and near(fillBottom-coreBottom,2)and near(fillTop-fillBottom,32),'fill has an exact two-pixel inset from each actual border-core edge')
    local iconTop=rowTop+bar.Icon.points[1][5];local iconBottom=rowBottom+bar.Icon.points[2][5]
    check(near(coreTop-iconTop,2)and near(iconBottom-coreBottom,2)and near(iconTop-iconBottom,32)and near(bar.IconFrame:GetWidth()-4,36),'icon shares the exact core inset and keeps its four-pixel wider content')
    check(bar:GetHeight()==36 and bar:GetWidth()==260 and bar.IconFrame:GetWidth()==40,'style profile adjustments preserve header size and icon width')
   else
    check(top==0 and bottom==0 and not host.FluxBorderFrame._FluxBorderCastInternalSide,'pet resource overlay does not borrow header offsets or internal icon caps')
   end
  end
  -- A real settings/Power-row resize recomputes once, then becomes static again.
  if unit=='pet'then frame.Power:SetSize(102,20)else frame.outerBorderFrame:SetWidth(320)end
  bar:UpdateLayout();local changed=s.work.positions
  check(changed>positions,'actual layout changes reposition the prepared cast row')
  bar:UpdateLayout();check(s.work.positions==changed,'new geometry is cached after one completed update')
  -- Existing unit defer service owns protected changes; repeated callbacks coalesce.
  combat=true
  if unit=='pet'then frame.Power.width=114 else frame.outerBorderFrame.width=340 end
  local prior=s.work.positions
  bar:UpdateLayout();bar:UpdateLayout()
  check(s.work.positions==prior and deferCount==1,'combat performs no cast-anchor writes and uses one existing protected defer')
  combat=false;for _,fn in pairs(deferred)do fn()end
  check(s.work.positions>prior and not bar._fluxLayoutDeferred,'deferred real layout runs after combat')
  local sized=unit=='pet'and frame.Power or frame.outerBorderFrame
  local width=sized.width;sized.width=s.secret;prior=s.work.positions
  bar:UpdateLayout();check(s.work.positions==prior,'restricted native width does not enter layout arithmetic or anchoring')
  sized.width=width
  -- Normal casting and custom timers must not revive the unused pet icon shell.
  s.Cast(unit,133)
  check(bar.IconFrame:IsShown()==(unit~='pet'),'cast-start icon visibility respects the actual pet/no-icon layout')
  check(bar.TimerBar.points[1][4]+bar.Text.points[1][4]==(unit=='pet'and 6 or 2),'the added fill underlap preserves the existing cast name origin')
  s.casts[unit]={id=133,locked=true};bar:CastStart(unit,false,'cast-shield')
  s.Event(bar,'UNIT_SPELLCAST_STOP',unit,'cast-shield',133)
  check(not bar.notInterruptible and not bar.ShieldOverlay:IsShown(),'successful protected casts clear their shield before restoring the ordinary inset')
  -- This fixture logs SetPoint calls; native LEFT re-anchors replace the
  -- previous LEFT point rather than retaining the old shield offset.
  check(bar.TimerBar.points[1][4]+bar.Text.points[#bar.Text.points][4]==(unit=='pet'and 6 or 2),'successful protected casts return to the same ordinary name origin: '..client..' '..unit)
  ns.CastBar.StartCustomTimer(bar,{duration=5,fromName='Origin',toName='Destination'})
  check(bar.IconFrame:IsShown()==(unit~='pet'),'custom timers preserve the pet/no-icon shell policy')
  check(bar.Text.text and bar.Text.text:find('Destination',1,true),'cached custom layout still fits its current label')
  check(near(bar.Text:GetWidth(),math.max(24,bar.TimerBar:GetWidth()-bar.Time:GetStringWidth()-bar.Text.points[#bar.Text.points][4]-10)),'custom timer names retain their reserved time gap after fill underlap')
  ns.CastBar.StopCustomTimer(bar,{immediate=true})
  if unit=='party1'then
   s.Cast(unit,133);check(near(bar.BorderFrame.borderColor[1],.8),'party class-chrome option uses the caster own class tint')
   frame._fluxPartyClassChrome=false;s.Cast(unit,133)
   check(near(bar.BorderFrame.borderColor[1],.3)and near(bar.BorderFrame.borderColor[3],.7),'disabled party class chrome uses current global accent')
   ns.PartyFrames={members={frame}};accent={.7,.4,.2};bar:SetStatusBarColor(1,0,0)
   e.FluxCastBar_ApplyAppearanceAccent()
   check(near(bar.BorderFrame.borderColor[1],.7)and near(bar.BorderFrame.backColor[1],.28),'appearance changes repaint existing party shell and backdrop immediately')
   check(bar.TimerBar.color[1]==1 and bar.TimerBar.color[2]==0,'chrome-only appearance repaint preserves the active interrupt fill')
   bar.notInterruptible=true;e.FluxCastBar_ApplyAppearanceAccent()
   check(bar.BorderFrame.borderColor[1]==1 and bar.BorderFrame.borderColor[2]==0,'uninterruptible red remains above the configured accent')
  end
 end end
 local s,e,ns=fixture(client)
 local showCast,showTime=true,true
 e.FluxUnitFrames_ShouldShowCastBar=function(unit)return showCast and unit~='targettarget'end
 e.FluxUnitFrames_ShouldShowCastTime=function()return showTime end
 e.InCombatLockdown=function()return true end
 e.UnitIsPlayer=function()error('options cast must use sample identity')end
 ns.UnitFrames.DeferProtected=function()error('options cast must not queue protected layout')end
 ns.UnitFrames.SyncBigDebuffsFrameLevelForUnitFrame=function()error('options cast must not touch live indicator levels')end
 ns.UnitFrames.GetFrameUnitChrome=function()return {r=.7,g=.3,b=.1},true end
 ns.UnitFrames.GetNormalUnitBackdrop=function(_,r,g,b)return r,g,b end
 ns.UnitFrames.GetMiniUnitChromeColor=function()return {r=.7,g=.3,b=.1}end
 e.FluxBorder={GetThemedVertexRGB=function()return .7,.3,.1 end,GetThemedBackdropFillRGB=function()return .28,.12,.04 end}
 local pane=e.CreateFrame('Frame')
 for _,unit in ipairs{'player','target','focus','pet','targettarget'}do
  local frame=e.CreateFrame('Frame',nil,pane)
  frame.unit=unit
  frame._fluxIndividualPreview=true
  frame._fluxPreviewLayerParent=pane
  frame._fluxCompactFocus=unit=='focus'
  frame.UpdatePartition=function() error('options cast must not call partition directly') end
  frame.outerBorderPadding=unit=='pet'and 0 or 36
  frame.outerBorderAlignment=unit=='target'and 'TOP'or 'BOTTOM'
  frame.atlasBorderFrame=e.CreateFrame('Frame',nil,frame)
  frame.outerBorderFrame=e.CreateFrame('Frame',nil,frame)
  frame.outerBorderFrame:SetSize(300,124)
  frame.Power=e.CreateFrame('StatusBar',nil,frame)
  frame.Power:SetSize(90,18)
  local paint=ns.CastBar.PaintOptionsSample
  check(paint(frame,false)==nil and not frame.CastBar,'idle options preview leaves native header available')
  local bar=paint(frame,true,'Healing Wave')
  if unit=='targettarget'then
   check(bar==nil and frame.CastBar==nil,'unsupported mini preview has no cast resources')
  else
   check(bar and bar:IsShown() and bar:GetValue()==.65,'selected options cast uses static sample progress during combat')
   check(bar.Text.text=='Healing Wave'and bar.Time.text=='1.4'and bar.Time:IsShown(),'native text fields display static sample and time')
   check(not next(bar.events) and not bar.scripts.OnUpdate and not bar.scripts.OnEvent and not bar.CastStart
    and not bar.RegisterPetCastEvents and not frame._fluxCastBarPartitionHooked,'sample has no runtime casts, events, callbacks or live partition hooks')
   if unit=='pet'then
    check(bar.allPoints==frame.Power and not bar.IconFrame:IsShown(),'options pet cast overlays the actual Power frame with no icon')
   else
    local point=bar.IconFrame.points[#bar.IconFrame.points]
    check(point[1]==(unit=='target'and 'BOTTOMLEFT'or 'TOPLEFT')and point[2]==frame.outerBorderFrame,
     'options cast uses the original header anchor in both native alignments')
   end
   if unit=='focus'then check(bar:GetFrameLevel()==frame:GetFrameLevel()+110,'compact Focus cast covers the raised name strip')end
   local positions,sizes,frames,textures=s.work.positions,s.work.sizes,#s.frames,#s.textures
   check(paint(frame,true,'Healing Wave')==bar and s.work.positions==positions and s.work.sizes==sizes
    and #s.frames==frames and #s.textures==textures,'unchanged options cast reuses resources and prepared geometry')
   local animate=ns.CastBar.SetOptionsSampleProgress
   animate(bar,0)
   check(bar:GetValue()==0 and bar.Time.text=='4.0'and not bar.Spark:IsShown(),'animation starts with an empty native fill and full remaining time')
   animate(bar,.25)
   local spark=bar.Spark.points[#bar.Spark.points]
   check(bar:GetValue()==.25 and bar.Time.text=='3.0'and bar.Spark:IsShown()
    and near(spark[4],.25*bar._fluxPreparedLayout.contentWidth),'animation steps only the native status fill, remaining time and spark')
   check(s.work.sizes==sizes and #s.frames==frames and #s.textures==textures,'cast animation creates no resources and never runs layout')
   animate(bar,1)
   check(bar:GetValue()==1 and bar.Time.text=='0.0'and not bar.Spark:IsShown(),'animation arrives at a filled cast and zero remaining time')
   paint(frame,true,'Healing Wave')
   check(bar:GetValue()==.65 and bar.Time.text=='1.4'and bar.Spark:IsShown(),'idle repaint restores the stationary casting example')
   showTime=false;paint(frame,true);check(not bar.Time:IsShown(),'options sample follows the cast time switch');showTime=true
   showCast=false;check(paint(frame,true)==nil and not bar:IsShown(),'cast visibility switch restores the idle frame');showCast=true
   check(paint(frame,true)==bar and paint(frame,false)==nil and not bar:IsShown(),'selection changes reuse the sample and restore the idle frame')
  end
 end

 assert(load(read('UnitFrames/FluxUnitFrames_PreviewAnimation.lua'),'@option-animation-fixture','t',e))('_FluxUI',ns)
 local start,stop=ns.UnitFrames.PlayOptionsPreviewAnimation,ns.UnitFrames.StopOptionsPreviewAnimation
 local progress,seconds,steps,finishes
 steps,finishes=0,0
 local function step(p,t) progress,seconds=p,t;steps=steps+1 end
 local function finish() finishes=finishes+1 end
 pane:Hide()
 start(pane,step,finish)
 check(not pane._fluxPreviewAnimationDriver and steps==0,'a hidden pane never allocates or starts an animation')
 pane:Show()
 start(pane,step,finish)
 local driver=pane._fluxPreviewAnimationDriver
 check(driver:IsShown() and driver.scripts.OnUpdate and steps==1 and progress==0 and seconds==0,'explicit play primes one visible driver')
 driver.scripts.OnUpdate(driver,.01)
 check(steps==1,'animation throttles updates below the paint interval')
 for _=1,241 do
  if driver.scripts.OnUpdate then driver.scripts.OnUpdate(driver,1/60) end
 end
 check(progress==1 and seconds==4 and finishes==1 and steps<=62,'one bounded animation ends after four seconds within the paint budget')
 check(not driver.scripts.OnUpdate and not driver:IsShown()and not driver.run,'completion removes every animation callback and parks the driver')
 start(pane,step,finish)
 check(pane._fluxPreviewAnimationDriver==driver and driver.scripts.OnUpdate,'replay retains the same driver')
 stop(pane)
 check(not driver.scripts.OnUpdate and not driver:IsShown()and finishes==1,'explicit stop clears the driver without invoking completion')
 start(pane,step,finish)
 pane:Hide()
 driver.scripts.OnHide(driver) -- The desktop widget mock does not propagate ancestor visibility events.
 check(not driver.scripts.OnUpdate and not driver.run and finishes==1,'an ancestor hiding clears an active preview animation')

 local function sampleMember(compact,state,owned)
  local frame=e.CreateFrame('Frame',nil,pane)
  local health=e.CreateFrame('StatusBar',nil,frame)
  local power=e.CreateFrame('StatusBar',nil,frame)
  health:SetMinMaxValues(0,100)
  health:SetValue(85)
  power:SetMinMaxValues(0,100)
  power:SetValue(75)
  local aura=e.CreateFrame('Frame',nil,frame)
  frame._fluxAuraBuff={aura}
  if compact then
   frame._fluxOptionsPreview=owned
   frame._fluxPreviewState=state
   frame.healthBar,frame.powerBar=health,power
  else
   frame.unit='party1'
   frame._fluxPartyMember=true
   frame._fluxPartyPreview=true
   frame._fluxPreviewLayerParent=owned and pane or nil
   frame._fluxPartyClassChrome=true
   frame._fluxPartyPreviewClass='MAGE'
   frame._fluxPartyStatusText=state==7 and 'Offline'or nil
   frame.Health,frame.Power=health,power
   frame.outerBorderPadding=36
   frame.outerBorderAlignment='BOTTOM'
   frame.atlasBorderFrame=e.CreateFrame('Frame',nil,frame)
   frame.outerBorderFrame=e.CreateFrame('Frame',nil,frame)
   frame.outerBorderFrame:SetSize(300,124)
   frame.nameText=frame:CreateFontString()
   frame.nameText:SetAlpha(.8)
   frame.levelText=frame:CreateFontString()
   frame.levelText:SetAlpha(.6)
  end
  return frame,health,power,aura
 end
 ns.PartyFrames=assert(load('local Party, Secret = ...\n'..partyCastCover..'\nreturn Party',
  '@party-cast-cover-fixture','t',e))({},function(value)return value==s.secret end)
 e.RAID_CLASS_COLORS={MAGE={r=.5,g=.75,b=1}}
 e.FluxRaidVisuals={SetHealthStatus=function(frame,_,_,_,percent)frame.displayedHealth=percent end}
 pane:Show()
 for _,compact in ipairs{true,false}do
  local inactive,inactiveHealth=sampleMember(compact,7,true)
  local world,worldHealth=sampleMember(compact,1,false)
  local first,health,power,aura=sampleMember(compact,1,true)
  local second=sampleMember(compact,2,true)
  local third=sampleMember(compact,3,true)
  local fourth,fourthHealth=sampleMember(compact,4,true)
  local members={inactive,world,first,second,third,fourth}
  local play=ns.UnitFrames.PlayOptionsGroupAnimation
  check(play(pane,members,#members,compact,finish),'group play starts on an embedded group with available samples')
  driver.scripts.OnUpdate(driver,1.8)
  check(near(health:GetValue(),53)and near(power:GetValue(),47)and near(aura:GetAlpha(),.35)
   and (not compact or near(first.displayedHealth,53)),'group animation updates health, visible power and synthetic aura opacity')
  check(inactiveHealth:GetValue()==85 and worldHealth:GetValue()==85 and fourthHealth:GetValue()==85,
   'group animation skips inactive states and non-option members and caps each run at three cells')
  if not compact then
   local bar=first.CastBar
   check(bar and bar:IsVisible()and near(bar:GetValue(),.45)and not next(bar.events)and not bar.scripts.OnUpdate,
    'the in-pane Party cast advances at the header with no runtime event or update registrations')
   check(bar:GetFrameLevel()==first:GetFrameLevel()+110 and first.nameText:GetAlpha()==0 and first.levelText:GetAlpha()==0
    and near(bar.HeaderCover.color[1],.2),'Party cast reuses raised header layering and the sample class palette')
  end
  local oldFinishes=finishes
  stop(pane)
  check(health:GetValue()==85 and power:GetValue()==75 and aura:GetAlpha()==1 and finishes==oldFinishes,
   'stopping group effects restores their exact static samples without a completion callback')
  if not compact then
   check(not first.CastBar:IsShown()and first.nameText:GetAlpha()==.8 and first.levelText:GetAlpha()==.6,
    'stopping the embedded cast restores the exact name and level alpha')
   showCast=false
   play(pane,members,#members,compact,finish)
   check(not first.CastBar:IsShown(),'the group sample honors the Party cast visibility switch')
   stop(pane)
   showCast=true
  end
  play(pane,members,#members,compact,finish)
  driver.scripts.OnUpdate(driver,4)
  check(health:GetValue()==85 and aura:GetAlpha()==1 and finishes==oldFinishes+1,
   'group effects restore baseline after natural completion')
 end
end
print('Cast border layout: '..checks..' checks PASS; five client API shapes; canonical icon/body touch; cached unchanged rows; real reflow; combat defer; restricted width; pet icon ownership; party class/global chrome; custom labels; isolated options samples and bounded preview animation. Native pixels/taint/FPS pending')
