-- Native addon menu action + native focus responders. Secure dispatch, widgets
-- and protected C calls are modeled; actual taint and menu clicks need WoW.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local source=read(arg[1] or 'UnitFrames/FluxUnitFrames_Shared.lua')
local a=assert(source:find('function UF.ConfigureUnitMenu',1,true))
local b=assert(source:find('-- Preserve the existing samples',a,true))
for _,client in ipairs({'live','forever','classic','classic_era','classic_anniversary'})do
 local E=setmetatable({},{__index=_G});E._G=E
 local locked,hardware=false,false
 local popup,focus,clears,attrCalls=nil,nil,0,0
 local kind='npc'
 E.UF={DeferProtected=function()end};E.InCombatLockdown=function()return locked end
 E.TargetFrame_OpenMenu=function()error('main target must use native addon action')end
 E.FocusFrame_OpenMenu=function()error('main focus must use native addon action')end
 E.CompactUnitFrame_OpenMenu=function()end
 E.UnitIsUnit=function(u,v)return u==v or (u=='target' and kind==v)end
 E.UnitIsOtherPlayersBattlePet=function()return false end
 E.UnitIsOtherPlayersPet=function()return false end
 E.UnitIsPlayer=function(u)return (u=='target' and kind=='otherplayer') or u:match('^party%d+$') or u:match('^raid%d+$')end
 E.UnitInRaid=function(u)return u:match('^raid%d+$')~=nil end
 E.UnitInParty=function(u)return u:match('^party%d+$')~=nil end
 E.UnitPopup_OpenMenu=function(which,data)popup={which=which,data=data}end
 E.SecureButton_GetModifiedAttribute=function(f,key,button)
  local n=button=='RightButton' and '2' or '1'
  return f.attrs[key..n] or f.attrs['*'..key..n] or f.attrs[key]
 end
 E.SecureButton_GetUnit=function(f)return f.attrs.unit end
 E.FocusUnit=function(u)check(hardware,'focus is a native hardware response');focus=u end
 E.ClearFocus=function(u)check(hardware,'clear focus is a native hardware response');focus=nil;clears=clears+1 end
 E.SECURE_ACTIONS={}
 local base='../__AddonsForRef/wow-ui-source-'..client..'/Interface/AddOns/'
 local secure=read(base..'Blizzard_FrameXML/SecureTemplates.lua')
 local i=assert(secure:find('SECURE_ACTIONS.menu =',1,true));local j=assert(secure:find('SECURE_ACTIONS.actionbar =',i,true))
 local suppliesOwner=secure:sub(i,j-1):find('ownerFrame = self',1,true)~=nil
 assert(load(secure:sub(i,j-1),'@native-menu-actions-'..client,'t',E))()
 local shared=read(base..'Blizzard_UnitPopupShared/UnitPopupSharedButtonMixins.lua')
 E.UnitPopupSetFocusButtonMixin={};E.UnitPopupClearFocusButtonMixin={}
 for _,name in ipairs({'UnitPopupSetFocusButtonMixin','UnitPopupClearFocusButtonMixin'})do
  local body=assert(shared:match('function '..name..':OnClick%b()%s.-\nend'))
  -- Forever 9dc84f0d calls ClearFocus() without a unit. The read-only local
  -- reference has the older argument; replay the pinned responder's call.
  if client=='forever' and name=='UnitPopupClearFocusButtonMixin' then
   body=body:gsub('ClearFocus%(contextData%.unit%)','ClearFocus()')
  end
  assert(load(body,'@native-focus-response-'..client,'t',E))()
 end
 assert(load(source:sub(a,b-1),'@actual-unit-menu-configuration','t',E))()
 local function button(unit)
  local f={attrs={unit=unit}}
  function f:SetAttribute(k,v)check(not locked,'setup remains outside combat');self.attrs[k]=v end
  function f:ExecuteAttribute()attrCalls=attrCalls+1;error('callback attribute path used')end
  return f
 end
 for _,combat in ipairs({false,true})do
  locked=false;local t,f=button('target'),button('focus')
  E.UF.ConfigureUnitMenu(t,'target');E.UF.ConfigureUnitMenu(f,'focus')
  check(t.attrs.type2=='togglemenu' and f.attrs.type2=='togglemenu',client..' native addon menu action prepared')
  check(t.attrs['*type2']=='togglemenu' and f.attrs['*type2']=='togglemenu',client..' modified menu fallback retained')
  locked=combat;hardware=true;kind='npc'
  E.SECURE_ACTIONS.togglemenu(t,'target','RightButton',false,false)
  check(popup.which=='TARGET' and popup.data.unit=='target' and popup.data.ownerFrame==(suppliesOwner and t or nil),client..' target native popup retains native owner/unit contract')
  E.UnitPopupSetFocusButtonMixin:OnClick(popup.data)
  check(focus=='target',client..' native response receives the target')
  E.SECURE_ACTIONS.togglemenu(f,'focus','RightButton',false,false)
  check(popup.which=='FOCUS' and popup.data.ownerFrame==(suppliesOwner and f or nil),client..' focus uses native focus popup')
  E.UnitPopupClearFocusButtonMixin:OnClick(popup.data)
  check(focus==nil and clears>0,client..' native clear response receives focus')
  check(attrCalls==0,client..' main menus never execute callback attribute')
  kind='otherplayer';E.SECURE_ACTIONS.togglemenu(t,'target','RightButton',false,false)
  check(popup.which=='PLAYER',client..' player target keeps native addon category selection')
  kind='pet';E.SECURE_ACTIONS.togglemenu(t,'target','RightButton',false,false)
  check(popup.which=='PET',client..' own pet target keeps native menu')
  hardware=false;locked=false
  local other=button('focustarget');E.UF.ConfigureUnitMenu(other,'focustarget')
  check(other.attrs.type2=='menu' and other.attrs['menu-function']==E.CompactUnitFrame_OpenMenu,client..' dependent/roster menu callback preserved')
  E.UF.ConfigureUnitMenu(t,'target',false);check(t.attrs.type2==nil and t.attrs['*type2']==nil,client..' existing menu opt-out retained')
 end
 for _,case in ipairs({{'player','SELF'},{'pet','PET'},{'party1','PARTY'},{'raid1','RAID_PLAYER'}})do
  locked=false;local f=button(case[1]);E.UF.ConfigureUnitMenu(f) -- roster callers can omit the unit argument
  check(f.attrs.type2=='togglemenu',client..' ordinary unit menu uses addon action: '..case[1])
  locked=true;hardware=true;E.SECURE_ACTIONS.togglemenu(f,case[1],'RightButton',false,false)
  check(popup.which==case[2] and popup.data.unit==case[1],client..' ordinary native popup resolves current unit')
  E.UnitPopupSetFocusButtonMixin:OnClick(popup.data)
  check(focus==case[1],client..' ordinary popup focus response receives correct unit')
  locked=false;hardware=false
 end
 for _,action in ipairs({'focus'})do
  local p=assert(secure:find('SECURE_ACTIONS.'..action..' =',1,true))
  local q=secure:find('\nSECURE_ACTIONS.',p+20,true) or #secure
  assert(load(secure:sub(p,q-1),'@native-secure-focus-action-'..client,'t',E))()
 end
 local handlers={}
 E.SLASH_COMMAND={FOCUS='FOCUS',CLEARFOCUS='CLEARFOCUS',MAINTANKON='MAINTANKON'}
 E.SLASH_COMMAND_CATEGORY={FOCUS_TARGETING=1}
 E.SlashCommandUtil={CheckAddSecureSlashCommand=function(name,_,fn)handlers[name]=fn end}
 E.SecureCmdOptionParse=function(text)return text end -- literal unit/empty macro arguments; native parser remains modeled
 local slash=read(base..'Blizzard_ChatFrameBase/Shared/SlashCommands.lua')
 local p=assert(slash:find('SlashCommandUtil.CheckAddSecureSlashCommand(SLASH_COMMAND.FOCUS,',1,true))
 local q=assert(slash:find('SlashCommandUtil.CheckAddSecureSlashCommand(SLASH_COMMAND.MAINTANKON,',p,true))
 assert(load(slash:sub(p,q-1),'@native-focus-macro-handlers-'..client,'t',E))()
 locked=true;hardware=true
 for _,unit in ipairs({'player','target','party1','raid1','focustarget','targettarget','pettarget'})do
  E.SECURE_ACTIONS.focus(button(unit),unit,'LeftButton')
  check(focus==unit,client..' secure focus action retains arbitrary unit support')
  handlers.CLEARFOCUS('')
  check(focus==nil,client..' secure clear-focus action remains available in combat')
  handlers.FOCUS(unit)
  check(focus==unit,client..' native focus macro preserves literal unit')
  handlers.CLEARFOCUS('')
  check(focus==nil,client..' native clear-focus macro remains available in combat')
 end
end
print('Native focus menu routing: '..checks..' checks PASS; native menu action/responders replayed across five clients; actual taint/hardware pending')
