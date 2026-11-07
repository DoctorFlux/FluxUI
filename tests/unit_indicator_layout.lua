local f=assert(io.open((arg and arg[1]) or 'UnitFrames/FluxUnitFrames_Shared.lua','rb'))
local src=f:read('*a'):gsub('\r\n','\n'); f:close()
local function section(a,b) local x=assert(src:find(a,1,true));return src:sub(x,assert(src:find(b,x+#a,true))-1) end
local checks=0
local function check(x,m) assert(x,m);checks=checks+1 end
local function widget()
 return {shown=true,Hide=function(s)s.shown=false end,Show=function(s)s.shown=true end,IsShown=function(s)return s.shown end,
 SetAlpha=function(s,a)s.alpha=a end,SetTexture=function(s,t)s.texture=t end,SetAtlas=function(s,a)s.atlas=a end,
 SetTexCoord=function(s,...)s.coords={...}end,SetSize=function(s,w,h)s.width=w;s.height=h end,
 SetDrawLayer=function()end,ClearAllPoints=function()end,SetPoint=function(s,...)s.point={...}end,
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
local layout=assert(load(section('local function LayoutNameStripCombatIcon','local function UnitIsMasterLooterOfGroup')..'\nreturn LayoutNameStripCombatIcon','rest','t',env))()
local s={unit='player',combatIcon=widget(),restIcon=widget(),levelText=widget(),outerBorderFrame=widget(),outerBorderPadding=35}
s.restAnimation={playing=false,Play=function(a)a.playing=true end,Stop=function(a)a.playing=false end,IsPlaying=function(a)return a.playing end}
layout(s);check(s.restIcon.shown and s.restAnimation.playing and s.levelText.alpha==1 and not s.combatIcon.shown,'rest keeps level')
state.combat=true;layout(s);check(not s.restIcon.shown and not s.restAnimation.playing and s.combatIcon.shown and s.levelText.alpha==1,'combat restores level and stops rest')
state.combat=false;state.rest=false;layout(s);check(not s.restIcon.shown and not s.combatIcon.shown and s.levelText.alpha==1,'idle reset')
state.rest=true;state.enabled=false;layout(s);check(not s.restIcon.shown and not s.restAnimation.playing and s.levelText.alpha==1,'option off')
state.enabled=true;s.restIcon=nil;s.restAnimation=nil;layout(s);check(s.combatIcon.shown and s.levelText.alpha==1,'classic static fallback')
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
  arrange(s,unit=='focus' and 24 or 35)
  check(s.leaderIcon.shown and not s.assistantIcon.shown,'leader priority')
  check(s.masterLooterIcon.shown,'master looter included')
  check(s._fluxStatusIconChainEnd==nil and s._fluxStatusIconsOnRight==nil,'group number stays name anchored')
  local bound=s.outerBorderFrame.width
  for _,key in ipairs({'pvpIcon','leaderIcon','mainTankIcon','mainAssistIcon','masterLooterIcon'}) do
   local t=s[key];check(t.width>0 and math.abs(t.point[4])+t.width<=bound and t.height<=29,'inside frame')
  end
 end
end
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
print('PASS '..checks..' unit indicator state/art/layout checks (desktop only)')
