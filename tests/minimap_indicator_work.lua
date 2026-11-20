-- Actual indicator controller, native state/side effects modeled. Optional
-- arg[1] selects the exact baseline; --measure records its redundant writes.
-- Counts do not certify native latency, secure execution or pixel parity.
local function read(path)
    local f=assert(io.open(path,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s
end
local fixture=read('tests/minimap_mail_lifecycle.lua')
fixture=fixture:sub(1,assert(fixture:find('\nfor _, provider in ipairs',1,true))-1)
local boot=assert(load(fixture..'\nreturn boot','@actual-indicator-fixture','t',_G))()
local eventSource=read(arg[1] or 'Minimap/FluxMinimap.lua')
local eventScript=assert(eventSource:match(
 '(FluxMinimap:SetScript%("OnEvent", function.-)\n\nfunction FluxMinimap:Initialize'))
local groupBatch=eventSource:match('(local groupIndicatorsScheduled.-)\nFluxMinimap:SetScript') or ''
local measure=arg[2]=='--measure'
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function corrected(v,m)if not measure then check(v,m)end end
for _,shape in ipairs{'cluster','global','minimap','missing'}do
 local h,e=boot(shape,false)
 local c={};local function hit(name)c[name]=(c[name]or 0)+1 end
 local secret=setmetatable({}, {__eq=function()error('private compared')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 local function instrument(w)
  if w.instrumented then return end;w.instrumented=true
  for _,name in ipairs{'SetParent','SetPoint','ClearAllPoints','SetFrameLevel'}do
   local original=w[name]
   w[name]=function(self,...)hit(name);return original(self,...)end
  end
  function w:GetNumPoints()hit('GetNumPoints');return self.extraPoint and 2 or self.point and 1 or 0 end
  function w:GetPoint()hit('GetPoint');return table.unpack(self.point or {})end
  local clear=w.ClearAllPoints
  function w:ClearAllPoints()self.extraPoint=nil;return clear(self)end
 end
 local function new(name)
  local w=e.CreateFrame('Frame',name,e.Minimap);instrument(w);return w
 end
 e.Minimap.InstanceDifficulty=new('ModernDifficulty')
 e.Minimap.InstanceDifficulty.Update=function()hit('DifficultyUpdate')end
 e.Minimap.Layout=function()hit('Layout')end
 e.MiniMapInstanceDifficulty=new('LegacyDifficulty')
 e.MiniMapInstanceDifficulty_Update=function()hit('LegacyUpdate')end
 e.GuildInstanceDifficulty=new('GuildDifficulty')
 e.FLUX_API.isRetail=true;e.ExpansionLandingPage={}
 e.ExpansionLandingPageMinimapButton=new('Landing')
 e.ExpansionLandingPageMinimapButton.RefreshButton=function()hit('LandingRefresh')end
 e.FluxMinimap.PositionQueueStatusEye=function()hit('Queue')end
 for _,w in ipairs(h.all)do instrument(w)end
 h:position() -- Complete original setup and mail reentry before measuring.
 for _,w in ipairs(h.all)do instrument(w)end
 local tracking=e.MinimapCluster.Tracking
 local mail=h:mailFrame()
 local targets={tracking,mail,e.Minimap.InstanceDifficulty,e.MiniMapInstanceDifficulty,
  e.GuildInstanceDifficulty,e.ExpansionLandingPageMinimapButton}
 local function reset()c={}end
 local function writes()return(c.SetParent or 0)+(c.SetPoint or 0)+(c.ClearAllPoints or 0)+(c.SetFrameLevel or 0)end
 local onEvent
 e.FluxMinimap.SetScript=function(_,script,callback)
  check(script=='OnEvent','loads the production minimap event handler')
  onEvent=callback
 end
 local tasks={}
 e.C_Timer={After=function(delay,callback)
  check(delay==0,'group batch uses the next turn')
  tasks[#tasks+1]=callback
 end}
 local function drain()
  local current=tasks;tasks={}
  for _,callback in ipairs(current)do callback()end
 end
 local eventSetup='local minimapPositionQueue={}\nlocal embeddedState={isEmbedded=true}\n'
 assert(load(eventSetup..groupBatch..eventScript,'@actual-minimap-events','t',e))()
 local nativeMail=e.HasNewMail
 e.HasNewMail=function()hit('Mail');return nativeMail()end
 local hideTrackingBorder=tracking.SetBorderHidden
 tracking.SetBorderHidden=function(...)hit('Tracking');return hideTrackingBorder(...)end
 local function dispatch(event)onEvent(e.FluxMinimap,event)end
 reset()
 for i=1,20 do dispatch(i%2==0 and 'INSTANCE_GROUP_SIZE_CHANGED' or 'GROUP_ROSTER_UPDATE')end
 if groupBatch~='' then
  check(#tasks==1 and c.Layout==nil,'same-turn group notifications share one pending callback')
  drain()
 end
 local passes=groupBatch~='' and 1 or 20
 check(c.DifficultyUpdate==passes and c.Layout==passes and c.LegacyUpdate==passes and c.Queue==passes,
  'final roster updates native difficulty banners and queues')
 corrected(not c.Tracking and not c.LandingRefresh and not c.Mail and c.GetPoint==3*passes,
  'group events skip unrelated indicator refreshes and anchor reads')
 print('MINIMAP_GROUP_WORK|'..shape..'|20rosterOrSize|tracking='..(c.Tracking or 0)
  ..'|landing='..(c.LandingRefresh or 0)..'|mail='..(c.Mail or 0)..'|anchors='..(c.GetPoint or 0)
  ..'|layouts='..c.Layout..'|queues='..c.Queue)
 if groupBatch~='' then
  reset();dispatch('GROUP_ROSTER_UPDATE');h.combat=true;drain()
  check(next(c)==nil,'pending roster paint skips protected placement on combat entry')
  h.combat=false;dispatch('PLAYER_REGEN_ENABLED')
  check(c.Layout==1 and c.Queue==1,'combat release applies the pending roster paint once')
  reset();dispatch('GROUP_ROSTER_UPDATE');dispatch('PLAYER_REGEN_ENABLED');drain()
  check(c.Layout==1 and c.Queue==1,'a timer consumed by combat release stays idle')
  reset();dispatch('GROUP_ROSTER_UPDATE');dispatch('MINIMAP_UPDATE_TRACKING');drain()
  check(c.Layout==1 and c.Queue==1,'a full indicator reflow consumes pending roster work')
  local timer=e.C_Timer;e.C_Timer=nil
  reset();dispatch('GROUP_ROSTER_UPDATE')
  check(c.Layout==1 and c.Queue==1,'without a timer group paint stays synchronous')
  e.C_Timer=timer
 end
 reset();dispatch('MINIMAP_UPDATE_TRACKING')
 check(c.Tracking==1 and c.LandingRefresh==1 and c.Queue==1,
  'tracking events still use full indicator layout')
 reset();h.combat=true;dispatch('GROUP_ROSTER_UPDATE');dispatch('INSTANCE_GROUP_SIZE_CHANGED');h.combat=false
 check(next(c)==nil,'group events honor the existing combat layout guard')
 reset()
 for _=1,100 do h:position()end
 local warm=writes()
 corrected(warm==0,'unchanged indicators retain current geometry without native layout writes')
 corrected(c.GetPoint==600,'every indicator reads its current native anchor on every pass')
 check(c.DifficultyUpdate==100 and c.Layout==100 and c.LegacyUpdate==100
  and c.LandingRefresh==100 and c.Queue==100,'all native difficulty/layout/landing/queue refreshes retain their original cadence')
 check(mail.parent==e.Minimap and mail.point[1]=='RIGHT'and mail.point[2]==tracking
  and tracking.point[4]==-4 and tracking.point[5]==4,'original tracking and mail geometry retained')
 -- SetParent can show native frames synchronously. Match the original empty
 -- anchors observed inside those callbacks, including reentrant positioning.
 for _,w in ipairs{tracking,mail,e.ExpansionLandingPageMinimapButton}do
  local original=w.SetParent;local callbacks=0
  w.parent=e.UIParent;w.point={'CENTER',e.UIParent,'CENTER',13,14}
  w.SetParent=function(self,parent)
   check(self.point==nil,'native parent-change callback sees original cleared anchors')
   original(self,parent);callbacks=callbacks+1;h:position()
  end
  h:position();check(callbacks==1 and w.parent==e.Minimap and w.point~=nil,'reentrant parent correction completes once with final geometry')
  w.SetParent=original
 end
 -- No event/dirty flag accompanies external drift. Fresh native state repairs it.
 for _,w in ipairs(targets)do w.point={'CENTER',e.UIParent,'CENTER',11,12};w.extraPoint=true;w.level=-1 end
 tracking.parent=e.UIParent;mail.parent=e.UIParent;e.ExpansionLandingPageMinimapButton.parent=e.UIParent
 reset();h:position()
 check(writes()>0 and tracking.parent==e.Minimap and mail.parent==e.Minimap
  and tracking.point[1]=='BOTTOMRIGHT'and not tracking.extraPoint,'unsignaled parent/anchor/extra-point drift is corrected')
 check(tracking.level==51 and mail.level==11 and e.Minimap.InstanceDifficulty.level==21
  and e.GuildInstanceDifficulty.point[5]==5,'native frame level and legacy/modern offsets are corrected')
 e.FluxBorder.CanUseAtlases=function()return false end;h:position()
 check(tracking.point[4]==-2 and tracking.point[5]==2,'current style changes apply without an old-state cache')
 e.Minimap.level=8;h:position()
 check(tracking.level==58 and mail.level==18,'current minimap frame level propagates')
 -- Every unreadable native getter conservatively retains the original writer.
 for _,name in ipairs{'GetParent','GetNumPoints','GetPoint','GetFrameLevel'}do
  local original=tracking[name]
  for _,failure in ipairs{'missing','throw','private'}do
   tracking[name]=failure=='missing'and false or function()
    if failure=='throw'then error('native unavailable')end;return secret
   end
   reset();check(pcall(h.position,h),'unavailable/private getter is never inspected')
   local n=name=='GetParent'and c.SetParent or name=='GetFrameLevel'and c.SetFrameLevel or c.SetPoint
   check(n and n>0,'unknown state preserves original correction')
  end
  tracking[name]=original
 end
 -- Replacements receive the same initialization; absence uses the original mail anchor.
 e.MinimapCluster.Tracking=new('ReplacementTracking');h:position()
 check(mail.point[2]==e.MinimapCluster.Tracking and e.MinimapCluster.Tracking.level==58,'late native tracking replacement is positioned and becomes the mail anchor')
 e.MinimapCluster.Tracking=nil;h:position()
 check(mail.point[1]=='BOTTOMRIGHT'and mail.point[2]==e.Minimap,'tracking absence preserves fallback mail placement')
 reset();h.combat=true;h:position()
 check(writes()==0 and not c.DifficultyUpdate and not c.Queue,'combat still defers all indicator geometry and native refresh work')
 h.combat=false;h:position()
 -- Getter protection must not suppress a real setter error.
 local setPoint=mail.SetPoint;mail.point=nil;mail.SetPoint=function()error('expected native writer failure')end
 local ok,err=pcall(h.position,h)
 check(not ok and tostring(err):find('expected native writer failure',1,true),'native setter errors retain original propagation')
 mail.SetPoint=setPoint;h:position()
 print('MINIMAP_INDICATOR_WORK|'..shape..'|100unchanged|geometryWrites='..warm..'|nativeUpdates=500')
end
print('Minimap indicator work: '..checks..' checks PASS; actual controller, fresh state and native updates retained; native timing pending')
