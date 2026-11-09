-- Production setup and source-pinned native secure click/menu callbacks.
-- This models trusted dispatch; native hardware, secure VM and taint need WoW.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local checks=0
local function check(v,m)assert(v,m);checks=checks+1 end
local source=read(os.getenv('FLUX_UNIT_MENU_SOURCE') or 'UnitFrames/FluxUnitFrames_Shared.lua')
local a=assert(source:find('function UF.ConfigureUnitMenu',1,true));local b=assert(source:find('-- Preserve the existing samples',a,true))
for _,client in ipairs({'live','forever','classic','classic_era','classic_anniversary'})do
 local E=setmetatable({},{__index=_G});E._G=E
 local combat,depth,writes=false,0,0
 local opened,queue={},{}
 E.UF={DeferProtected=function(key,fn)queue[key]=fn end}
 E.InCombatLockdown=function()return combat end
 E.RAID_TARGET_ICON='Raid marker'
 E.UnitIsUnit=function(unit,other)return unit==other end
 E.UnitIsHumanPlayer=function(unit)return unit=='party1' or unit=='party2' or unit=='raid1' or unit=='raid2' end
 E.UnitIsPlayer=E.UnitIsHumanPlayer
 E.UnitIsOtherPlayersBattlePet=function()return false end
 E.UnitIsOtherPlayersPet=function(unit)return unit=='partypet1' end
 E.UnitInRaid=function(unit)return unit:match('^raid%d+$')~=nil end
 E.UnitInParty=function(unit)return unit:match('^party%d+$')~=nil end
 E.UnitPopup_OpenMenu=function(which,context)
  check(combat and depth>0,'native callback executes through trusted combat click')
  opened[#opened+1]={which=which,unit=context.unit}
 end
 local base='../__AddonsForRef/wow-ui-source-'..client..'/Interface/AddOns/'
 local secure=read(base..'Blizzard_FrameXML/SecureTemplates.lua')
 local compact=read(base..'Blizzard_UnitFrame/Shared/CompactUnitFrame.lua')
 local callback=assert(compact:match('function CompactUnitFrame_OpenMenu%b()%s.-\nend'))
 assert(load(callback,'@native-compact-menu-'..client,'t',E))()
 E.SECURE_ACTIONS={}
 local s=assert(secure:find('SECURE_ACTIONS.menu =',1,true))
 local t=assert(secure:find('SECURE_ACTIONS.actionbar =',s,true))
 assert(load(secure:sub(s,t-1),'@native-menu-action-'..client,'t',E))()
 E.Enum={ClickBindingType={None=0,Spell=1,Macro=2,Interaction=3,PetAction=4}}
 local bindingType=3;local macros=0;local casts=0;local prefix=''
 E.MakeModifiers=function()return 0 end
 E.C_ClickBindings=client=='live' or client=='forever'
 if E.C_ClickBindings then E.C_ClickBindings={GetBindingType=function()return bindingType end,
  GetEffectiveInteractionButton=function(button)return button end,ExecuteBinding=function()casts=casts+1 end}end
 E.SecureButton_GetModifiedUnit=function(f)return f.attrs.unit end
 E.SecureButton_GetModifiedAttribute=function(f,name,button)
  local index=button=='RightButton' and '2' or '1'
  return f.attrs[prefix..name..index] or f.attrs[name..index] or f.attrs['*'..name..index]
 end
 E.SpellIsTargeting=function()return false end
 E.OnActionButtonClick=function(f,button,down)
  local action=E.SecureButton_GetModifiedAttribute(f,'type',button)
  if action=='menu'then E.SECURE_ACTIONS.menu(f,f.attrs.unit,button,false,down)
  elseif action=='togglemenu'then E.SECURE_ACTIONS.togglemenu(f,f.attrs.unit,button,false,down)
  elseif action=='macro'then macros=macros+1 end
 end
 s=assert(secure:find('function SecureUnitButton_OnClick',1,true))
 assert(load(secure:sub(s),'@native-unit-click-'..client,'t',E))()
 assert(load(source:sub(a,b-1),'@actual-unit-menu-setup','t',E))()
 local function button(unit)
  local f={attrs={unit=unit,['*type1']='target'}}
  function f:SetAttribute(k,v)assert(not combat,'ordinary protected write in combat');writes=writes+1;self.attrs[k]=v end
  function f:ExecuteAttribute(key,...)check(depth>0,'menu callback only from secure native action');return assert(self.attrs[key])(...)end
  return f
 end
 local function click(f,down)if down then return end;depth=depth+1;E.SecureUnitButton_OnClick(f,'RightButton',down);depth=depth-1 end -- right-button widget registration is Up-only
 for _,case in ipairs({{'player','SELF'},{'vehicle','VEHICLE'},{'pet','PET'},{'party1','PARTY'},{'raid1','RAID_PLAYER'},
  {'partypet1','OTHERPET'},{'party1target','TARGET'},{'pettarget','TARGET'},{'focustarget','TARGET'},{'targettarget','TARGET'}})do
  combat=false;local f=button(case[1]);check(E.UF.ConfigureUnitMenu(f,case[1]),'menu prepared out of combat')
  local action=case[1]:sub(-6)=='target' and 'menu' or 'togglemenu'
  check(f.attrs['menu-function']==E.CompactUnitFrame_OpenMenu and f.attrs.type2==action and f.attrs['*type2']==action,'native callback retained and supported action selected for the unit token')
  combat=true;local before=writes;local count=#opened
  click(f,true);check(#opened==count,'menu opens on release only')
  click(f,false);check(opened[#opened].which==case[2] and opened[#opened].unit==case[1],'combat right click opens current native unit menu')
  check(writes==before,'opening menu changes no protected attributes')
  -- Restricted roster engine updates the unit in place; no addon setup occurs.
  f.attrs.unit='raid2';click(f,false)
  check(opened[#opened].unit=='raid2' and opened[#opened].which=='RAID_PLAYER','combat roster movement follows resolved click unit')
  E.UF.ConfigureUnitMenu(f,case[1],false);check(writes==before and f.attrs.type2==action,'combat option edit defers and keeps existing menu usable')
  E.UF.ConfigureUnitMenu(f,case[1],true)
  combat=false;for key,fn in pairs(queue)do queue[key]=nil;fn()end
  check(f.attrs.type2==action,'latest deferred menu choice wins')
  combat=true;f.attrs['shift-type2']='macro';prefix='shift-';count=#opened;click(f,false)
  check(#opened==count and macros>0,'explicit modified Flux hover cast retains precedence')
  prefix=''
  if E.C_ClickBindings then
   bindingType=1;count=#opened;click(f,false);check(casts>0 and #opened==count,'native click-cast assignment retains precedence')
   bindingType=3
  end
 end
 combat=false;local nativeFocus=function()end;E.FocusFrame_OpenMenu=nativeFocus
 local focus=button('focus');E.UF.ConfigureUnitMenu(focus,'focus');check(focus.attrs['menu-function']==nativeFocus,'focus-specific native menu pointer retained')
 E.CompactUnitFrame_OpenMenu=nil;local fallback=button('party1');E.UF.ConfigureUnitMenu(fallback,'party1')
 check(fallback.attrs.type2=='togglemenu' and fallback.attrs['menu-function']==nil,'missing optional native UI retains secure legacy fallback')
end
print('Combat unit menus: '..checks..' checks; five native source handlers/callbacks; native taint/hardware pending')
