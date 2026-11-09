-- Actual shared target painter and compact-focus routing. Native pixels/taint
-- remain untested; no secure input or client globals are modified.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function section(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(i,assert(s:find(b,i+#a,true),b)-1)end
local shared=read(os.getenv('FLUX_COLOR_SHARED') or 'UnitFrames/FluxUnitFrames_Shared.lua')
local party=read(os.getenv('FLUX_COLOR_PARTY') or 'UnitFrames/FluxUnitFrames_Party.lua')
local checks=0
local function check(v,m)assert(v,m);checks=checks+1 end
local function same(a,b,m)check(a and b and #a==#b,m);for i=1,#a do check(math.abs(a[i]-b[i])<1e-9,m)end end
for _,client in ipairs({'live','forever','classic','classic_era','classic_anniversary'})do
 local E=setmetatable({},{__index=_G});E._G=E
 local state={class='MAGE',mode='custom',combat=false,partyClass=false,reads={}}
 local UF,Party={},{}
 local Border={}
 local accent={.8,.1,.2,1}
 function Border:GetAccentColor()return table.unpack(accent)end
 function Border:SetClassColor(f)f.color={table.unpack(accent)};f.backdrop={.12,.18,.24,.85}end
 function Border:SetBorderColor(f,...)f.color={...}end
 function Border:SetBackdropColor(f,...)f.backdrop={...}end
 function Border:GetForeverClientChromeRGB()if client=='forever'then return 1,.82,0 end end
 function Border:GetForeverClientBackdropRGB()return .5,.41,0 end
 local function secret(v)return type(v)=='table' and v.opaque end
 E.UF,E.Party,E.ns=UF,Party,{UnitFrames=UF,PartyFrames=Party,Border=Border}
 E.Border,E.FluxBorder=Border,Border
 E.API={IsSecretValue=secret,SafeAccessibleString=function(v)if not secret(v) and type(v)=='string'then return v end end}
 E.IsSecretValue,E.Secret=secret,secret
 E.PublicGeometryNumber=function(v)return type(v)=='number'and v end
 E.SafeBooleanTest=function(v,fallback)if secret(v)then return fallback end;return v and true or false end
 E.RAID_CLASS_COLORS={MAGE={r=.2,g=.6,b=1},WARRIOR={r=.78,g=.61,b=.43}}
 E.UnitIsPlayer=function(u)return u=='player' or state.class~='NPC'end
 E.UnitClass=function(u)state.reads[u]=true;return 'Class',u=='player'and'WARRIOR'or state.class end
 E.UnitExists=function()return true end
 E.UnitAffectingCombat=function()return state.combat end
 E.FluxUnitFrames_IsPortraitCombatTintEnabled=function()return true end
 E.InCombatLockdown=function()return state.combat end
 UF.UsesHudUnitBars=function()return client=='live'or client=='forever'end
 UF.GetFramePublicLevel=function(f)return f and f.level or 40 end
 UF.SetFramePublicLevel=function(f,n)f.level=n end
 assert(load(section(shared,'local function ClassColorForUnit(unit)','-- Separator / chrome tint')
  ..section(party,'function Party.PaintChrome','function Party.RefreshChrome')
  ..section(shared,'local PORTRAIT_COMBAT_BORDER_R','-- Unit name on outer border:'),
  '@actual-focus-target-color-owners','t',E))()
 local function surface()
  local f={FluxBorderFrame={level=50,GetFrameLevel=function(s)return s.level end},level=40}
  function f:GetFrameLevel()return self.level end
  function f:SetAlpha(a)self.alpha=a end
  function f:SetVertexColor(...)self.color={...}end
  function f:Hide()self.shown=false end
  function f:Show()self.shown=true end
  f.bg={Hide=f.Hide,Show=f.Show,SetVertexColor=f.SetVertexColor}
  return f
 end
 local function frame(unit)
  local f=surface();f.unit=unit;f._fluxCompactFocus=unit=='focus'
  for _,k in ipairs({'PortraitFrame','outerBorderFrame','atlasBorderFrame','HealthPowerSeparator','PowerAdditionalSeparator','ThreatBar','_fluxPartyDivider'})do f[k]=surface()end
  f.CastBar={IconBorder=surface(),BorderFrame=surface()};f._fluxMainPowerAlpha=1
  return f
 end
 local target,focus=frame('target'),frame('focus')
 for _,mode in ipairs({'custom','class','atlas'})do
  state.mode=mode;accent=mode=='class'and{.78,.61,.43,1}or mode=='atlas'and{.9,.8,.6,1}or{.8,.1,.2,1}
  for _,class in ipairs({'MAGE','WARRIOR','NPC',{opaque=true}})do
   state.class=class
   for _,partyClass in ipairs({false,true})do
    state.partyClass=partyClass;focus._fluxPartyClassChrome=partyClass
    for _,combat in ipairs({false,true,false})do
     state.combat=combat;UF.UpdateBorderColors(target);Party.PaintChrome(focus)
     for _,k in ipairs({'PortraitFrame','outerBorderFrame','atlasBorderFrame','HealthPowerSeparator','PowerAdditionalSeparator','ThreatBar'})do
      same(focus[k].color,target[k].color,client..' '..mode..' focus matches target '..k)
     end
     same(focus.color,target.color,'main border follows focused unit')
     same(focus.outerBorderFrame.backdrop,target.outerBorderFrame.backdrop,'outer backdrop follows target policy')
     same(focus.PortraitFrame.backdrop,target.PortraitFrame.backdrop,'combat portrait restores target policy')
     same(focus.CastBar.IconBorder.color,target.CastBar.IconBorder.color,'cast icon follows target policy')
     same(focus.CastBar.BorderFrame.color,target.CastBar.BorderFrame.color,'cast shell follows target policy')
     same(focus._fluxPartyDivider.color,target.HealthPowerSeparator.color,'compact divider follows target colors')
     check(not state.reads.player,'focus chrome never reads player class')
    end
   end
  end
 end
 local member=frame('party1');member._fluxCompactFocus=nil;member._fluxPartyMember=true;member._fluxPartyClassChrome=false
 Party.PaintChrome(member);same(member.color,accent,'ordinary party retains configured accent')
end
print('Focus target colors: '..checks..' checks; five client models; focused-unit class/NPC/opaque colors; combat restoration and all accents; native pixels pending')
