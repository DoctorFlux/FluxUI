local partyReplay=arg[1]=='--party-roster'
local function read(path)
 local f=assert(io.open(path,'rb'))
 local source=f:read('*a'):gsub('\r\n','\n')
 f:close()
 return source
end
local src=read(not partyReplay and arg[1] or 'UnitFrames/FluxUnitFrames_Shared.lua')
local function section(a,b,source)
 source=source or src
 local from=assert(source:find(a,1,true),a)
 return source:sub(from,assert(source:find(b,from+#a,true),b)-1)
end
local checks=0
local function check(x,m) assert(x,m);checks=checks+1 end
local function widget()
 return {shown=true,Hide=function(s)s.shown=false end,Show=function(s)s.shown=true end,IsShown=function(s)return s.shown end,
 SetAlpha=function(s,a)s.alpha=a end,SetTexture=function(s,t)s.texture=t end,SetAtlas=function(s,a,natural)s.atlas=a;s.natural=natural end,
 SetTexCoord=function(s,...)s.coords={...}end,SetSize=function(s,w,h)s.width=w;s.height=h end,
 SetDrawLayer=function()end,ClearAllPoints=function(s)s.point=nil end,SetPoint=function(s,...)s.point={...}end,
 GetSize=function(s)return s.width,s.height end,GetNumPoints=function(s)return s.point and 1 or 0 end,
 GetPoint=function(s)return table.unpack(s.point or {}) end,
 EnableMouse=function()end,SetAllPoints=function(s,f)s.allpoints=f end,SetFrameLevel=function(s,n)s.level=n end,SetScale=function(s,n)s.scale=n end,
 GetStringWidth=function()return 20 end,GetWidth=function(s)return s.width or 16 end,GetFrameLevel=function()return 1 end}
end
local state={rest=true,combat=false,enabled=true}
local env=setmetatable({UF={},API={SafeGetNumber=function(n)return n or 0 end},
 UnitAffectingCombat=function()return state.combat end,IsResting=function()return state.rest end,
 FluxUnitFrames_ShouldShowCombatIcon=function()return state.enabled end,
 C_Texture={GetAtlasInfo=function(a)return state.atlas and {} end}}, {__index=_G})
assert(load(section('function UF.SetIndicatorArt','function UF.CreateOuterBorder'),'art','t',env))()
local t=widget(); state.atlas=true;check(env.UF.SetIndicatorArt(t,'present','legacy'),'atlas selected')
state.atlas=false;check(not env.UF.SetIndicatorArt(t,'missing','legacy') and t.texture=='legacy','legacy fallback')
local geometry=src:find('-- Current native state for name-strip icon geometry',1,true)
 and section('-- Current native state for name-strip icon geometry','--- Combat/rest beside level')or''
local layout=assert(load(geometry..section('local function LayoutNameStripCombatIcon','local function UnitIsMasterLooterOfGroup')..'\nreturn LayoutNameStripCombatIcon','rest','t',env))()
local s={unit='player',combatIcon=widget(),restIcon=widget(),levelText=widget(),outerBorderFrame=widget(),outerBorderPadding=35}
s.restAnimation={playing=false,Play=function(a)a.playing=true end,Stop=function(a)a.playing=false end,IsPlaying=function(a)return a.playing end}
layout(s);check(s.restIcon.shown and s.restAnimation.playing and s.levelText.alpha==1 and not s.combatIcon.shown,'rest keeps level')
state.combat=true;layout(s);check(not s.restIcon.shown and not s.restAnimation.playing and s.combatIcon.shown and s.levelText.alpha==1,'combat restores level and stops rest')
state.combat=false;state.rest=false;layout(s);check(not s.restIcon.shown and not s.combatIcon.shown and s.levelText.alpha==1,'idle reset')
state.rest=true;state.enabled=false;layout(s);check(not s.restIcon.shown and not s.restAnimation.playing and s.levelText.alpha==1,'option off')
state.enabled=true;s.restIcon=nil;s.restAnimation=nil;layout(s);check(s.combatIcon.shown and s.levelText.alpha==1,'classic static fallback')
env.CreateFrame=function()local f=widget();f.CreateTexture=function()return widget()end;return f end
env.ns={};env.SafeBooleanTest=function(x)return x end; env.UnitIsPlayer=function()return true end
env.IsInGroup=function()return true end;env.IsInRaid=function()return false end
env.UnitInParty=function()return true end;env.UnitIsUnit=function()return true end; env.GetLootMethod=function()return "master",0 end
env.UnitIsGroupLeader=function()return true end;env.GetPartyAssignment=function()return true end
env.GetNameStripCenterY=function(_,p)return -p/2 end
local status=section('local function UnitIsMasterLooterOfGroup','local function ClampPvpIconInOuterBorder')
local arrange=assert(load(status..'\nreturn LayoutNameStripStatusAndPvpIcons','status','t',env))()
for _,unit in ipairs({'player','target','focus'}) do
 for _,side in ipairs({'LEFT','RIGHT'}) do
  local s={unit=unit,portraitPosition=side,nameText=widget(),outerBorderFrame=widget(),pvpIcon=widget(),
   leaderIcon=widget(),assistantIcon=widget(),mainTankIcon=widget(),mainAssistIcon=widget(),masterLooterIcon=widget()}
  s.outerBorderFrame.width=unit=='focus' and 160 or 330
  s.classIcon=widget();s.classIcon.width=24
  s.specIcon=widget();s.specIcon.width=24
  s.pvpIcon.width=64;s.pvpIcon.height=64
  s.pvpIcon.IsShown=function()error("native PvP visibility must not be read by status packing")end
  arrange(s,unit=='focus' and 24 or 35)
  check(s.leaderIcon.shown and not s.assistantIcon.shown,'leader priority')
  check(s.masterLooterIcon.shown,'master looter included')
  check(s._fluxStatusIconChainEnd==nil and s._fluxStatusIconsOnRight==nil,'group number stays name anchored')
  check(s.pvpIcon.width==64 and s.pvpIcon.height==64 and not s.pvpIcon.point,'native badge stays outside square packing')
  local bound=s.outerBorderFrame.width
  for _,key in ipairs({'leaderIcon','mainTankIcon','mainAssistIcon','masterLooterIcon'}) do
   local t=s[key];check(t.width>0 and math.abs(t.point[4])+t.width<=bound and t.height<=29,'inside frame')
  end
 end
end
local roleKeys={'leaderIcon','assistantIcon','mainTankIcon','mainAssistIcon','masterLooterIcon'}
local roles={group=true,leader=true}
local counters={}
local function tracked()
 local tex=widget()
 for _,method in ipairs({'Show','Hide','SetSize','ClearAllPoints','SetPoint'}) do
  local original=tex[method]
  tex[method]=function(self,...)
   counters[method]=(counters[method] or 0)+1
   return original(self,...)
  end
 end
 return tex
end
local frames={}
for _,unit in ipairs({'player','target','focus'}) do
 local frame={unit=unit,nameText=widget(),outerBorderFrame=widget(),portraitPosition=unit=='target' and 'RIGHT' or 'LEFT'}
 frame.outerBorderFrame.width=unit=='focus' and 160 or 330
 frame.classIcon=widget();frame.specIcon=widget()
 for _,key in ipairs(roleKeys) do frame[key]=tracked() end
 frames[#frames+1]=frame
end
env.IsInGroup=function()return roles.group end
env.UnitIsGroupLeader=function()return roles.leader end
env.UnitIsGroupAssistant=function()return not roles.leader end
local function LayoutRoles()
 for _,frame in ipairs(frames) do
  local padding=frame.unit=='focus' and 24 or 35
  arrange(frame,padding)
  arrange(frame,padding)
 end
end
local function RoleSignature()
 local fields={}
 for _,frame in ipairs(frames) do
  for _,key in ipairs(roleKeys) do
   local tex=frame[key]
   if tex.shown then
    local point,owner,relative,x,y=tex:GetPoint()
    check(owner==frame.outerBorderFrame,'active role stays anchored to the owning border')
    fields[#fields+1]=table.concat({frame.unit,key,tex.width,tex.height,point,relative,x,y},':')
   end
  end
 end
 return table.concat(fields,'|')
end
LayoutRoles()
counters={}
for _=1,20 do LayoutRoles() end
print(('ROLE_STRIP_STABLE show=%d hide=%d size=%d clear=%d point=%d geometry=%s'):format(
 counters.Show or 0,counters.Hide or 0,counters.SetSize or 0,counters.ClearAllPoints or 0,counters.SetPoint or 0,RoleSignature()))
if arg[2]~='--measure' then
 check(next(counters)==nil,'unchanged roster preserves the native role textures without setters')
end
roles.leader=false
LayoutRoles()
local assistant=frames[1].assistantIcon
check(not frames[1].leaderIcon.shown and assistant.shown,'a leader-to-assistant transition repaints roles')
local signature=RoleSignature()
assistant.width=1
assistant.point=nil
assistant.shown=false
LayoutRoles()
check(RoleSignature()==signature,'native size, point and visibility drift are repaired')
local opaque={}
env.API.IsSecretValue=function(value)return rawequal(value,opaque)end
assistant.shown=opaque
LayoutRoles()
check(RoleSignature()==signature,'opaque native role visibility takes the guarded write path')
env.API.IsSecretValue=nil
roles.group=false
LayoutRoles()
check(RoleSignature()=='','leaving a group clears the roles')
env.UnitIsGroupLeader=function()return true end
env.IsInGroup=function()return true end
local reserve=assert(load(section('local function GetNameStripSideReserve','--- Short rarity labels')..'\nreturn GetNameStripSideReserve','reserve','t',env))()
local crowded={unit='player',leaderIcon=widget(),pvpIcon=widget(),classIcon=widget()}
check(reserve(crowded)==28,'status icons do not shorten name')
local master=assert(load(status..'\nreturn UnitIsMasterLooterOfGroup','master','t',env))()
env.GetLootMethod=nil;env.C_PartyInfo={GetLootMethod=function()return 2,0 end}
check(master('player'),'namespace enum master loot')
env.C_PartyInfo.GetLootMethod=function()return 5,0 end
check(not master('player'),'non-master loot does not show')
env.IsInRaid=function()return true end
env.C_PartyInfo.GetLootMethod=function()return 2,nil,7 end
env.UnitIsUnit=function(unit,other)return other=='raid7' end
check(master('target') and master('focus'),'raid master resolves target/focus aliases')
if not arg[1] or partyReplay then
 env.IsInRaid=function()return false end
 local exists=0
 env.UnitExists=function(unit)exists=exists+1;return unit=='party4'end
 env.UnitIsUnit=function(unit,other)return (unit=='target' and 'party4' or unit)==other end
 env.C_PartyInfo.GetLootMethod=function()return 2,4 end
 check(master('target') and not master('party1') and exists==2,
   'only the assigned party token is probed, including for an alias')
 env.C_PartyInfo.GetLootMethod=function()return 2,2.5 end
 check(not master('target') and exists==2,'an invalid assignment does not probe any unit')
 env.UnitExists=nil
end
-- Exercise the actual shared factory/renderer for every supported source model,
-- including player, target and focus (the original party-only change missed these).
for _,client in ipairs({'live','forever','classic','classic_era','classic_anniversary'}) do
 env.ns.Flux={Client={isRetail=client=='live',isForever=client=='forever'}}
 for _,unit in ipairs({'player','target','focus','party1'}) do
  local f={unit=unit,levelText=widget(),pvpTimer=widget(),outerBorderFrame=widget()}
  f.outerBorderFrame.CreateTexture=function()return widget()end
  env.UF.CreatePvpBadge(f)
  check(f._fluxPvpLayer.scale==1.35,'badge enlarged another35 percent')
  check(f.pvpIcon.width==64 and f._fluxPvpPrestigePortrait.width==50 and f._fluxPvpPrestigePortrait.height==52
   and f._fluxPvpPrestigeBadge.width==30,'full native factory dimensions')
  env.UnitFrameUtil=nil
  env.FluxUnitFrames_ShouldShowPvp=function()return true end
  env.UnitIsPVPFreeForAll=function()return false end;env.UnitIsPVP=function()return true end
  env.UnitFactionGroup=function()return 'Horde' end
  env.C_Texture.GetAtlasInfo=function()return (client=='live' or client=='forever') and {} or nil end
  env.UF.UpdatePvpBadge(f)
  check(f.pvpIcon.point[2]==f.levelText and f.pvpIcon.point[3]=='TOP','full badge behind level')
  check(f.pvpTimer.point[2]==f.levelText and f.pvpTimer.point[3]=='BOTTOM','timer below level')
  check(unit=='player' and f.pvpTimer.shown or unit~='player' and not f.pvpTimer.shown,'only self keeps real timer')
  check(f.pvpIcon.shown and (f.pvpIcon.natural or f.pvpIcon.texture=='Interface\\TargetingFrame\\UI-PVP-Horde'),'client-native faction artwork')
  env.UnitIsPVPFreeForAll=function()return true end;env.UF.UpdatePvpBadge(f)
  check(f.pvpIcon.atlas=='UI-HUD-UnitFrame-Player-PVP-FFAIcon' or f.pvpIcon.texture=='Interface\\TargetingFrame\\UI-PVP-FFA','FFA badge')
  env.UnitIsPVPFreeForAll=function()return false end;env.UnitIsPVP=function()return false end
  env.UF.UpdatePvpBadge(f);check(not f.pvpIcon.shown and not f._fluxPvpPrestigePortrait.shown and not f._fluxPvpPrestigeBadge.shown,'unflagged clears all art')
  local opaque={};env.issecretvalue=function(v)return v==opaque end
  env.UnitFactionGroup=function()return opaque end;env.UF.UpdatePvpBadge(f)
  check(not f.pvpIcon.shown,'fallback hides opaque state without testing it')
  local delegated=0
  env.UnitFrameUtil={UpdateUnitPvPIndicator=function(elements,token,mercenary)
   check(elements==f._fluxPvpElements and token==unit and mercenary==(unit=='player'),'native delegate has actual unit and owned art')
   delegated=delegated+1;elements.pvpIcon:Show();elements.prestigeBadge:Show()
  end}
  env.UF.UpdatePvpBadge(f);check(delegated==1 and f._fluxPvpPrestigeBadge.shown,'native delegate handles private PvP/prestige state')
  env.UF.UpdatePvpBadge(f,true);check(delegated==1,'layout refresh does not query native state again')
  env.FluxUnitFrames_ShouldShowPvp=function()return false end
  env.UF.UpdatePvpBadge(f);check(not f.pvpIcon.shown and not f._fluxPvpPrestigeBadge.shown and not f.pvpTimer.shown,'option hides all art/timer')
  env.UnitFrameUtil=nil;env.issecretvalue=nil
 end
end
local function rosterModel(shared,party)
 local work,frames,group={}, {}, {count=4,leader='party1'}
 local function count(key) work[key]=(work[key] or 0)+1 end
 local function counted(label)
  local t=widget()
  t.label=label
  for _,key in ipairs({'Show','Hide','SetSize','ClearAllPoints','SetPoint','GetStringWidth','GetWidth'}) do
   local original=t[key]
   t[key]=function(self,...)
    count(label..'.'..key)
    return original(self,...)
   end
  end
  function t:SetFont(_,size)self.fontSize=size end
  function t:SetText(text)self.text=text end
  function t:SetTextColor(...)self.color=table.concat({...},',')end
  function t:SetJustifyH(side)self.justify=side end
  function t:SetWidth(width)self.width=width end
  return t
 end
 local function noop() end
 local owner={ApplyTextModes=noop,UpdateThreat=noop,UpdatePvpBadge=noop}
 local uf={UpdateHealth=noop,UpdatePower=noop,UpdatePvpBadge=noop}
 local e=setmetatable({
  UF=uf,Party=owner,ns={PartyFrames=owner},API={SafeGetNumber=function(value,fallback)return value or fallback end},
  SafeBooleanTest=function(value)return value==true end,Secret=function()return false end,
  InCombatLockdown=function()return group.locked end,
  IsInGroup=function()return group.count>0 end,IsInRaid=function()return false end,
  UnitIsPlayer=function()return true end,UnitInParty=function()return true end,
  UnitExists=function()count('exists');return true end,
  UnitIsUnit=function(a,b)return a==b end,
  UnitIsGroupLeader=function(unit)count('leader');return unit==group.leader end,
  UnitIsGroupAssistant=function(unit)return unit=='party2' end,
  GetPartyAssignment=function(role,unit)return role=='MAINTANK' and unit=='party3' end,
  GetLootMethod=function()return 'master',4 end,
  GetNameStripCenterY=function(_,pad)return -(pad or 35)/2 end,
  GetNameStripLevelFontSize=function()return 13 end,
  GetDifficultyColor=function()return {r=1,g=.8,b=.2} end,
  GetNpcLevelMetaVariants=function()return {'72'},true,72 end,
  LayoutNameStripCombatIcon=noop,FluxRaidAuras={Update=noop},FluxRaidVisuals={GetFluxRaidOptionTable=function()return {} end},
  UIParent={GetEffectiveScale=function()return 1 end},
 },{__index=_G})
 e.DB=function()return {}end
 e.Scale=function(_,default)return default end
 local level=section('local function LayoutNameStripLevelText','--- Fit metadata into its corner',shared)
 local placement=section('-- Current native state for name-strip icon geometry','--- Combat/rest beside level',shared)
 local statuses=section('local function UnitIsMasterLooterOfGroup','local function ClampPvpIconInOuterBorder',shared)
 local first=shared:find('    -- A party paint finishes',1,true) and '    -- A party paint finishes'
   or '    -- Name-strip level/type/rarity (corner opposite class/spec; never on portrait)'
 local early=section(first,'    -- Update group text for players',shared)
 local late=section('    -- Re-place PvP/status after name/ToT fit','    -- Geometry skipped on combat entry',shared)
 local body='local NAME_FONT_PATH="font"\n'..level..placement..statuses
    ..'\nreturn function(self,deferPartyIndicators)\nlocal outerBorderPadding,totPos2Minimal=35,false\n'
    ..early..late..'\nend'
 local dispatch=assert(load(body,'@actual-outer-indicator-dispatch','t',e))()
 local paint=assert(load(section('local ROLE_ATLAS','local INDICATOR_EVENTS',party)
   .. section('function Party.StyleText','function Party.UpdatePvpBadge',party)
   .. section('function Party.UpdateIndicators','function Party.UpdateThreat',party)
   .. section('local function Paint(frame','local rosterPaintPending',party)..'\nreturn Paint','@actual-normal-party-paint','t',e))()
 for index=1,4 do
  local f={unit='party'..index,_fluxPartyMember=true,GetEffectiveScale=function()return .6 end,
    outerBorderFrame=counted('outer'),nameText=counted('name'),levelText=counted('level'),
    PortraitFrame=counted('portrait'),_fluxPartyIndicatorLayer=counted('layer'),UpdateOuterBorder=dispatch}
  f.outerBorderFrame.width=260
  for _,key in ipairs(roleKeys) do f[key]=counted('role') end
  frames[index]=f
 end
 local function step(i)
  group.count=(i%3)+2
  group.leader='party'..(i%group.count+1)
  group.locked=i%4==0
  for index=1,group.count do paint(frames[index]) end
 end
 local function signature()
  local values={}
  for index=1,group.count do
   local f=frames[index]
   local function place(t)
    local p,relative,edge,x,y=t:GetPoint()
    values[#values+1]=table.concat({p,relative.label,edge,x,y,t.width or 0,t.height or 0},',')
   end
   for _,key in ipairs(roleKeys) do
    values[#values+1]=tostring(f[key].shown)
    if f[key].shown then place(f[key]) end
   end
   place(f.levelText)
   values[#values+1]=table.concat({f.levelText.text,f.levelText.fontSize,f.levelText.color,f.levelText.justify},',')
  end
  return table.concat(values,'|')
 end
 return {step=step,signature=signature,frames=frames,group=group,dispatch=dispatch,owner=owner,
  reset=function()work={} end,count=function(key)return work[key] or 0 end}
end

if partyReplay or not arg[1] then
 local party=read('UnitFrames/FluxUnitFrames_Party.lua')
 local prior=partyReplay and arg[2]
 local previous=prior and rosterModel(read(prior..'/UnitFrames-FluxUnitFrames_Shared.lua'),
  read(prior..'/UnitFrames-FluxUnitFrames_Party.lua')) or rosterModel(src,party)
 local current=rosterModel(src,party)
 previous.step(2);current.step(2)
 previous.reset();current.reset()
 for i=1,60 do
  previous.step(i);current.step(i)
  check(current.signature()==previous.signature(),'settled party placement and visible level/role paint agree')
 end
 check(current.count('role.SetPoint')<current.count('leader')*2
  and current.count('level.SetPoint')==0 and current.count('name.GetStringWidth')==0,
  'warmed roster refreshes place roles only at their final portrait position')
 if prior then
  check(previous.count('leader')==current.count('leader')*2
    and previous.count('exists')>current.count('exists')
    and previous.count('level.SetPoint')>0 and previous.count('role.SetPoint')>current.count('role.SetPoint'),
    'archived party paint repeats the shared placement and membership work')
 end
 print(('PARTY_STATUS count=60 leader=%d/%d rolePoints=%d/%d levelPoints=%d/%d nameMeasure=%d/%d lootSlots=%d/%d')
  :format(previous.count('leader'),current.count('leader'),previous.count('role.SetPoint'),current.count('role.SetPoint'),
    previous.count('level.SetPoint'),current.count('level.SetPoint'),previous.count('name.GetStringWidth'),current.count('name.GetStringWidth'),
    previous.count('exists'),current.count('exists')))
 local f=current.frames[1]
 local layer=f._fluxPartyIndicatorLayer
 f._fluxPartyIndicatorLayer=nil
 current.dispatch(f,true)
 check(select(2,f.levelText:GetPoint())==f.outerBorderFrame,
  'missing party owner keeps the shared level placement')
 f._fluxPartyIndicatorLayer=layer
 current.owner.LayoutIndicators(f)
 check(select(2,f.levelText:GetPoint())==layer,'restoring the party layer repairs its level anchor')
 f.levelText.point={'TOPRIGHT',layer,'TOPRIGHT',-11,-3}
 current.owner.LayoutIndicators(f)
 check(f.levelText.point[4]==-3,'real anchor movement still repairs the native position')
end
print('PASS '..checks..' unit indicator state/art/layout checks (desktop only)')
