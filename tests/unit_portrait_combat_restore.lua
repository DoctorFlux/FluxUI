-- Actual shared tint renderer + actual Party.PaintChrome, including focus's
-- compact branch. Native pixels/taint are outside this desktop fixture.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(arg[1] or 'UnitFrames/FluxUnitFrames_Shared.lua')
local first=assert(source:find('local PORTRAIT_COMBAT_BORDER_R',1,true))
local last=assert(source:find('function UF.UpdateBorderColors',first,true))
local classFirst=assert(source:find('local function ClassColorForUnit(unit)',1,true))
local classLast=assert(source:find('-- Separator / chrome tint',classFirst,true))
local party=read('UnitFrames/FluxUnitFrames_Party.lua')
local pa=assert(party:find('function Party.PaintChrome',1,true))
local pb=assert(party:find('function Party.RefreshChrome',pa,true))
local checks=0
local function check(v,m)assert(v,m);checks=checks+1 end
local state={combat=false,locked=false,enabled=true,levelWrites=0}
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
 Secret=function(v)return type(v)=='table'end,IsSecretValue=function(v)return type(v)=='table'end,
 API={SafeAccessibleString=function(v)if type(v)=='string'then return v end end},
 RAID_CLASS_COLORS={MAGE={r=.2,g=.6,b=1}},
 UnitIsPlayer=function()return true end,UnitClass=function()return 'Mage','MAGE'end,
 FluxUnitFrames_IsPortraitCombatTintEnabled=function()return state.enabled end,
 UnitExists=function()return true end,UnitAffectingCombat=function()return state.combat end,
 InCombatLockdown=function()return state.locked end},{__index=_G})
UF.SetFramePublicLevel=function(f,n)
 check(not state.locked,'combat tint must never call a protected frame-level setter')
 state.levelWrites=state.levelWrites+1;f.level=n
end
local levelFirst=assert(source:find('function UF.GetFramePublicLevel(frame)',1,true))
local levelLast=assert(source:find('function UF.SetFramePublicLevel(frame, level)',levelFirst,true))
assert(load(source:sub(levelFirst,levelLast-1),'@actual-public-level-reader','t',env))()
assert(load(source:sub(classFirst,classLast-1)..party:sub(pa,pb-1)..source:sub(first,last-1),'@actual-portrait-combat-restore','t',env))()
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
   check(math.abs(pf.backdrop[1]-((unit=='focus' or classColor) and .08 or .12))<1e-9,'focus restores its unit class; party restores its class or accent backdrop')
  end
  state.combat,state.enabled=true,true;UF.UpdatePortraitCombatTint(f)
  state.enabled=false;UF.UpdatePortraitCombatTint(f)
  check(not pf.bg.shown,'disabling tint removes active red plate')
  state.enabled=true;UF.UpdatePortraitCombatTint(f);state.combat={opaque=true};UF.UpdatePortraitCombatTint(f)
  check(not pf.bg.shown,'unreadable combat state restores normal presentation')
 end
end
check(state.levelWrites==0,'combat tint and restoration stay paint-only even when unlocked')

-- Execute the actual constructor through its layer preparation. The model and
-- its camera lifecycle are unrelated to this layer invariant.
state.locked=false
local createFirst=assert(source:find('function UF.CreatePortrait(frame)',1,true))
local fitFirst=assert(source:find('function UF.FitPortraitBorderBounds(',1,true))
assert(load(source:sub(fitFirst,createFirst-1),'@actual-portrait-bound-fit','t',env))()
local createLast=assert(source:find('-- Create the Model for 3D portrait',createFirst,true))
local levelsFirst=assert(source:find('function UF.GetFramePublicLevel(frame)',1,true))
local levelsLast=assert(source:find('local RefreshPublicPredictionCanvases',levelsFirst,true))
assert(load(source:sub(levelsFirst,levelsLast-1),'@actual-portrait-level-writers','t',env))()
local function frameObject(parent)
 local o={parent=parent,level=0}
 function o:GetFrameLevel()return self.level end
 function o:SetFrameLevel(n)check(not state.locked,'initial portrait layer is prepared outside combat');self.level=n end
 function o:SetSize(w,h)self.w,self.h=w,h end
 function o:EnableMouse()end
 function o:CreateTexture()local t=texture();function t:SetTexture()end;function t:SetPoint()end;function t:ClearAllPoints()end;return t end
 return o
end
env.CreateFrame=function(_,_,parent)return frameObject(parent)end
env.GetUnitClassColor=function()return env.RAID_CLASS_COLORS.MAGE end
env.ClassColorForUnit=env.GetUnitClassColor
UF.GetFramePublicDimensions=function()return 240,88 end
UF.RecordFrameDimensions=function()end
border.ApplyTo=function(_,f)f.FluxBorderFrame=frameObject(f)end
local make=assert(load(source:sub(createFirst,createLast-1)..'return portraitFrame end','@actual-portrait-layer-preparation','t',env));make()
for _,unit in ipairs{'player','target','focus','pet'}do
 local f=frameObject();f.unit=unit;f.level=40
 local pf=UF.CreatePortrait(f)
 check(pf.FluxBorderFrame.level==57,'all portrait chrome reserves the same stable combat paint layer before mesh creation')
 check(pf.FluxBorderFrame._fluxPublicLevelOwner==f and pf.FluxBorderFrame._fluxPublicLevelOffset==17,'public level fallback records actual unit-relative layer')
 f.PortraitFrame=pf;f.outerBorderFrame={FluxBorderFrame={GetFrameLevel=function()return 55 end}}
 local before=pf.FluxBorderFrame.level
 for i=1,8 do state.locked=true;state.combat=true;UF.UpdatePortraitCombatTint(f);state.combat=false;UF.UpdatePortraitCombatTint(f)end
 check(pf.FluxBorderFrame.level==before,'combat cycles preserve prebuilt source canvas parent level')
 state.locked=false
end
print('Portrait combat restore: '..checks..' actual tint/backdrop/constructor layer checks; no combat geometry writes; native pixels/taint pending')
