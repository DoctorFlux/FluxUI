-- Actual shared tint renderer + actual Party.PaintChrome, including focus's
-- compact branch. Native pixels/taint are outside this desktop fixture.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(arg[1] or 'UnitFrames/FluxUnitFrames_Shared.lua')
local first=assert(source:find('local PORTRAIT_COMBAT_BORDER_R',1,true))
local last=assert(source:find('function UF.UpdateBorderColors',first,true))
local party=read('UnitFrames/FluxUnitFrames_Party.lua')
local pa=assert(party:find('function Party.PaintChrome',1,true))
local pb=assert(party:find('function Party.RefreshChrome',pa,true))
local checks=0
local function check(v,m)assert(v,m);checks=checks+1 end
local state={combat=false,locked=false,enabled=true}
local UF,Party={},{}
local border={}
function border:SetClassColor(f)f.backdrop={.12,.18,.24,.85};f.color={.3,.45,.6,1}end
function border:SetBorderColor(f,...)f.color={...}end
function border:SetBackdropColor(f,...)f.backdrop={...}end
function border:GetAccentColor()return .3,.45,.6 end
local function texture()
 return {shown=false,Hide=function(s)s.shown=false end,Show=function(s)s.shown=true end,
  SetVertexColor=function(s,...)s.color={...}end}
end
local env=setmetatable({UF=UF,Party=Party,ns={PartyFrames=Party,Border=border},Border=border,
 PublicGeometryNumber=function(v)return type(v)=='number'and v or nil end,
 SafeBooleanTest=function(v,fallback)if type(v)=='boolean'then return v end;return fallback end,
 Secret=function(v)return type(v)=='table'end,RAID_CLASS_COLORS={MAGE={r=.2,g=.6,b=1}},
 UnitIsPlayer=function()return true end,UnitClass=function()return 'Mage','MAGE'end,
 FluxUnitFrames_IsPortraitCombatTintEnabled=function()return state.enabled end,
 UnitExists=function()return true end,UnitAffectingCombat=function()return state.combat end,
 InCombatLockdown=function()return state.locked end},{__index=_G})
UF.SetFramePublicLevel=function(f,n)f.level=n end
local levelFirst=assert(source:find('function UF.GetFramePublicLevel(frame)',1,true))
local levelLast=assert(source:find('function UF.SetFramePublicLevel(frame, level)',levelFirst,true))
assert(load(source:sub(levelFirst,levelLast-1),'@actual-public-level-reader','t',env))()
assert(load(party:sub(pa,pb-1)..source:sub(first,last-1),'@actual-portrait-combat-restore','t',env))()
for _,unit in ipairs({'party1','party4','focus'})do
 for _,classColor in ipairs({false,true})do
  local pf={bg=texture(),level=41,FluxBorderFrame={level=51,GetFrameLevel=function(s)return s.level end},GetFrameLevel=function(s)return s.level end}
  local f={unit=unit,PortraitFrame=pf,outerBorderFrame={FluxBorderFrame={GetFrameLevel=function()return 55 end}},
   _fluxPartyMember=unit~='focus',_fluxCompactFocus=unit=='focus',_fluxPartyClassChrome=classColor,GetFrameLevel=function()return 40 end}
  for _=1,3 do
   state.combat,state.locked,state.enabled=true,true,true;UF.UpdatePortraitCombatTint(f)
   check(pf.bg.shown and pf.bg.color[1]==.4 and pf.backdrop[1]==.4,'combat applies the existing red border/backdrop/plate')
   state.combat=false;UF.UpdatePortraitCombatTint(f)
   check(not pf.bg.shown,'unit leaving combat hides red portrait plate even while player remains in combat')
   check(math.abs(pf.backdrop[1]-(classColor and .08 or .12))<1e-9,'normal class or accent backdrop is restored')
  end
  state.combat,state.enabled=true,true;UF.UpdatePortraitCombatTint(f)
  state.enabled=false;UF.UpdatePortraitCombatTint(f)
  check(not pf.bg.shown,'disabling tint removes active red plate')
  state.enabled=true;UF.UpdatePortraitCombatTint(f);state.combat={opaque=true};UF.UpdatePortraitCombatTint(f)
  check(not pf.bg.shown,'unreadable combat state restores normal presentation')
 end
end
print('Portrait combat restore: '..checks..' actual party/focus tint/backdrop checks; native pixels/taint pending')
