-- Actual TM visibility + Manager callback; native frames/provider are modeled.
local function read(p)local f=assert(io.open(p,'rb'));local b=f:read('*a');f:close();return b end
local path='ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua'
if arg and arg[1]=='--source'then path=assert(arg[2])end
local function loadenv(b,p,e)
 if _VERSION=='Lua 5.1'then local f,err=loadstring(b,p);if f then setfenv(f,e)end;return f,err end
 return load(b,p,'t',e)
end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local function fixture()
 local s={frames={},scans=0,borders=0,hides=0,locked=false,queue=0}
 local e=setmetatable({}, {__index=_G});e._G=e;e.SlashCmdList={};e.UIParent={}
 e.InCombatLockdown=function()return s.locked end
 e.wipe=function(t)for k in pairs(t)do t[k]=nil end end
 e.GetBindingKey=function()end;e.GetInventoryItemLink=function()end
 e.UnitClass=function()return 'Mage','MAGE'end;e.RAID_CLASS_COLORS={}
 e.CreateFrame=function()
  local f={scripts={},events={}};function f:RegisterEvent(v)self.events[v]=true end
  function f:SetScript(k,v)self.scripts[k]=v end
  function f:Hide()check(not s.locked,'hide remains outside lockdown');s.hides=s.hides+1 end
  function f:Show()check(not s.locked,'show remains outside lockdown')end
  function f:IsShown()return false end
  s.frames[#s.frames+1]=f;return f
 end
 e.C_Timer={After=function()error('regen must not add delayed work')end}
 e.FluxExtraButtonVisibility={Apply=function()return false end}
 e.FluxUnifiedBorder={UpdateBorder=function()s.borders=s.borders+1;if s.borderError then error(s.marker,0)end end}
 local flux={Module={Register=function()end},Inventory={Register=function()end}}
 assert(loadenv(read('ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua'),'@TrinketCore',e))('_FluxUI',{Flux=flux})
 local tm=e.FluxTrinketMenu;tm.Frame=e.CreateFrame();tm.Buttons={};tm.SyncKeybindPushWatch=function()end
 tm.ScanBagsForTrinkets=function()s.scans=s.scans+1;if s.scanError then error(s.marker,0)end;if s.reenter then s.reenter=false;s.locked=true;tm.Show();tm.UpdateTrinketVisibility();s.locked=false end end
 tm.ProcessCombatQueue=function()s.queue=s.queue+1 end
 assert(loadenv(read(path),'@TrinketManager',e))('_FluxUI',{Flux=flux})
 e.FluxTrinketMenuManager._startupReady=true
 s.hides=0
 local frame=s.frames[#s.frames];s.event=assert(frame.scripts.OnEvent);s.tm=tm
 function s:regen()self.locked=false;self.event(nil,'PLAYER_REGEN_ENABLED')end
 return s
end
for _,label in ipairs{'shared source'}do
 local s=fixture();local tm=s.tm
 s.locked=true;tm.Show();tm.UpdateTrinketVisibility()
 check(tm._pendingShow and tm._pendingVisibilityUpdate,label..': both intents can accumulate under lockdown')
 s:regen()
 check(s.scans==2 and s.hides==1 and s.borders==1,label..': one hidden-policy visibility update retains its original two scans')
 check(not tm._pendingShow and not tm._pendingVisibilityUpdate,label..': original intents consumed')
 local scans=s.scans;s:regen();check(s.scans==scans and s.borders==1,label..': ordinary regen has no hidden refresh')
 tm._pendingShow=true;s:regen();check(s.scans==scans+2 and s.borders==2,label..': show-only intent still evaluates current visibility')
 tm._pendingVisibilityUpdate=true;tm._pendingKeybindUpdate=true;s:regen()
 check(s.scans==scans+5 and not tm._pendingKeybindUpdate,label..': explicit binding recovery remains after visibility')
 tm._pendingShow=true;tm._pendingVisibilityUpdate=true;s.reenter=true;s:regen()
 check(tm._pendingShow and tm._pendingVisibilityUpdate,label..': freshly rearmed requests survive current callback')
 scans=s.scans;s:regen();check(s.scans==scans+2 and not tm._pendingShow and not tm._pendingVisibilityUpdate,label..': later safe edge consumes rearmed intents once')
 check(s.queue==6,label..': combat queue processed on every regen as before')
end
for _,kind in ipairs{'scanError','borderError'}do
 local s=fixture();local tm=s.tm;s.marker={};s[kind]=true
 tm._pendingShow=true;tm._pendingVisibilityUpdate=true
 local ok,err=pcall(function()s:regen()end)
 check(not ok and err==s.marker and tm._pendingShow and not tm._pendingVisibilityUpdate,kind..': exact error propagates and original show retry survives')
 s[kind]=false;local scans=s.scans;s:regen()
 check(s.scans==scans+2 and not tm._pendingShow,kind..': later regen recovers original show intent')
end
do
 local s=fixture();local tm=s.tm;local order={}
 local update,keys=tm.UpdateTrinketVisibility,tm.UpdateKeybindings
 tm.UpdateTrinketVisibility=function(...)order[#order+1]='visibility';return update(...)end
 tm.UpdateKeybindings=function(...)order[#order+1]='keys';return keys(...)end
 tm._pendingShow=true;tm._pendingKeybindUpdate=true;s:regen()
 check(table.concat(order,',')=='keys,visibility,keys','show-only recovery retains original keybinding-before-visibility order')
end
for _,reenter in ipairs{false,true}do
 local s=fixture();local tm=s.tm;s.marker={}
 local keys,calls=tm.UpdateKeybindings,0
 tm.UpdateKeybindings=function(...)
  calls=calls+1
  if calls==2 then
   if reenter then tm._pendingShow='new-show-intent'end
   error(s.marker,0)
  end
  return keys(...)
 end
 tm._pendingShow='old-show-intent';tm._pendingVisibilityUpdate=true;tm._pendingKeybindUpdate=true
 local ok,err=pcall(function()s:regen()end)
 check(not ok and err==s.marker and calls==2 and s.borders==1,'middle key failure follows successful first visibility and border with exact error')
 check(tm._pendingShow==(reenter and 'new-show-intent'or'old-show-intent')and not tm._pendingVisibilityUpdate and not tm._pendingKeybindUpdate,'middle key failure retains old show recovery and preserves a newer show intent')
 tm.UpdateKeybindings=keys;local scans=s.scans;s:regen()
 check(s.scans==scans+2 and not tm._pendingShow,'later regen recovers hidden visibility after middle key failure')
end
do
 local s=fixture();local tm=s.tm;s.marker={}
 tm.UpdateTrinketVisibility=function()tm.Show()end
 tm.UpdateKeybindings=function()error(s.marker,0)end
 tm._pendingShow=true;tm._pendingVisibilityUpdate=true;tm._pendingKeybindUpdate=true
 local ok,err=pcall(function()s:regen()end)
 check(not ok and err==s.marker and tm._pendingShow==false,'successful native Show consumes old intent before middle key error without inventing retry')
end
do
 local s=fixture();local tm=s.tm;s.marker={};s.borderError=true
 tm.UpdateTrinketVisibility=function()tm.Show()end
 tm._pendingShow=true;tm._pendingVisibilityUpdate=true
 local ok,err=pcall(function()s:regen()end)
 check(not ok and err==s.marker and tm._pendingShow==false,'native Show consumption also survives a later border error')
end
print('trinket regen refresh: '..checks..' checks PASS; native geometry/latency pending')
