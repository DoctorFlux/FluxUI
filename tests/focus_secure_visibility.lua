-- Actual visibility owners + pinned Blizzard driver replay. Widgets/secure dispatch
-- are modeled; real combat, taint and mouse routing require native acceptance.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local checks,failures=0,0
local observe=os.getenv('FLUX_FOCUS_OBSERVE')=='1'
local function check(v,m)
 checks=checks+1
 if not v then failures=failures+1;if observe then print('FAIL '..m)else error(m)end end
end
local src=read(arg[1] or 'UnitFrames/FluxUnitFrames_Shared.lua')
local function section(s,a,b)local i=assert(s:find(a,1,true),a);local j=assert(s:find(b,i+#a,true),b);return s:sub(i,j-1)end
local restricted=read('Core/Engine/Restricted.lua')
local samples={}
local clients=os.getenv('FLUX_FOCUS_CLIENT') and {os.getenv('FLUX_FOCUS_CLIENT')} or {'live','forever','classic','classic_era','classic_anniversary'}
for _,client in ipairs(clients)do
 local E=setmetatable({},{__index=_G});E._G=E
 local st={combat=false,secure=0,frames={},timers={},units={},blocked=0,mouseWrites=0,registrations=0}
 local ns={UnitFrames={},Flux={Cap={hasRestrictedClosures=client~='forever'},Client={isForever=client=='forever',isCamelot=client=='forever'}}}
 E.Flux=ns.Flux
 E.InCombatLockdown=function()return st.combat end
 E.UnitExists=function(u)return st.units[u]~=nil end
 E.UnitIsVisible=E.UnitExists
 E.UnitName=function(u)return st.units[u] and 'Known Unit' end
 E.UnitHealth=function(u)return st.units[u]=='dead' and 0 or 100 end
 E.UNKNOWNOBJECT='Unknown'
 E.wipe=function(t)for k in pairs(t)do t[k]=nil end end
 E.table=setmetatable({wipe=E.wipe},{__index=table})
 E.strmatch=string.match
 E.C_Timer={After=function(_,fn)st.timers[#st.timers+1]=fn end}
 local function protected()
  if st.combat and st.secure==0 then st.blocked=st.blocked+1;error('modeled protected write')end
 end
 local function trusted(fn,...)
  st.secure=st.secure+1;local out={pcall(fn,...)};st.secure=st.secure-1;assert(out[1],out[2]);return table.unpack(out,2)
 end
 local Frame={}
 function Frame:GetName()return self.name end
 function Frame:GetAttribute(k)return self.attrs[k]end
 function Frame:SetAttribute(k,v)
  protected();self.attrs[k]=v
  if self.scripts.OnAttributeChanged then
   if self.secureFrame then trusted(self.scripts.OnAttributeChanged,self,k,v)else self.scripts.OnAttributeChanged(self,k,v)end
  end
 end
 function Frame:SetScript(k,v)self.scripts[k]=v end
 function Frame:RegisterEvent()end
 function Frame:RegisterUnitEvent()end
 function Frame:Show()protected();self.shown=true end
 function Frame:Hide()protected();self.shown=false end
 function Frame:IsShown()return self.shown end
 function Frame:IsVisible()return self.shown and (not self.parent or self.parent:IsVisible())end
 function Frame:SetAlpha(v)self.alpha=v end
 function Frame:GetAlpha()return self.alpha end
 function Frame:EnableMouse(v)protected();st.mouseWrites=st.mouseWrites+1;self.mouse=v end
 function Frame:SetMouseClickEnabled(v)protected();self.mouse=v end
 function Frame:IsMouseEnabled()return self.mouse end
 function Frame:Execute()self:SetAttribute('flux-paging-probe',1)end
 E.CreateFrame=function(_,name,parent,template)
  local f=setmetatable({name=name,parent=parent,attrs={},scripts={},shown=true,alpha=1,mouse=true,secureFrame=template=='SecureFrameTemplate'},{__index=Frame})
  st.frames[#st.frames+1]=f;return f
 end
 E.SecureButton_GetUnit=function(f)return f.attrs.unit end
 E.SecureCmdOptionParse=function(text)
  for clause in text:gmatch('[^;]+')do
   local cond,value=clause:match('^%s*%[([^%]]+)%]%s*(%S+)')
   if not cond then return clause:match('%S+')end
   local u=cond:match('@([%a]+)') or 'target';local matches=true
   for token in cond:gmatch('[^,]+')do
    if token=='exists' then matches=matches and E.UnitExists(u)
    elseif token=='noexists' then matches=matches and not E.UnitExists(u)
    elseif token=='dead' then matches=matches and st.units[u]=='dead'
    elseif token=='nodead' then matches=matches and st.units[u]~='dead' end
   end
   if matches then return value end
  end
 end
 local native=read('../__AddonsForRef/wow-ui-source-'..client..'/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua')
 assert(load(native,'@pinned-native-unit-watch-'..client,'t',E))()
 local nativeRegister=E.RegisterAttributeDriver
 E.RegisterAttributeDriver=function(...)st.registrations=st.registrations+1;return nativeRegister(...)end
 assert(load(restricted,'@actual-restricted-owner','t',E))('_FluxUI',ns)
 E.ns,E.UF,E.API=ns,ns.UnitFrames,{UnitExistsSafe=E.UnitExists}
 E.RegisterUnitWatch=client=='forever' and ns.Flux.Restricted.RegisterUnitWatch or E.RegisterUnitWatch
 E.Restricted=ns.Flux.Restricted
 local vis=section(src,'local function UnitDisplayName(unit, showRealm)','local function SyncRelatedWatchedFrames(self)')
 assert(load(vis,'@actual-watched-unit-visibility','t',E))()
 local function drain()
  while #st.timers>0 do local q=st.timers;st.timers={};for _,fn in ipairs(q)do fn()end end
 end
 local function tick()
  for _,f in ipairs(st.frames)do
   if f.shown and f.scripts.OnEvent then
    if f==E.SecureStateDriverManager then trusted(f.scripts.OnEvent,f,'PLAYER_FOCUS_CHANGED')
    else f.scripts.OnEvent(f,'PLAYER_FOCUS_CHANGED')end
   end
   if f.shown and f.scripts.OnUpdate then
    if f==E.SecureStateDriverManager then trusted(f.scripts.OnUpdate,f,1)
    else f.scripts.OnUpdate(f,1)end
   end
  end
 end
 local function hit(f)return f:IsVisible() and f.mouse end -- Alpha never removes a hit region.
 local frames={}
 for _,unit in ipairs({'focus','focustarget'})do
  local f=E.CreateFrame('Button','FluxUnitFrame_'..unit);f.unit=unit;f.attrs.unit=unit;f.mouse=false
  local nextUnit=unit=='focus' and 'focustarget' or 'player'
  local reg=section(src,'    elseif unit == "'..unit..'" then','    elseif unit == "'..nextUnit..'" then')
  reg=reg:gsub('^    elseif unit == "'..unit..'" then','')
  assert(load('local frame,unit=...; '..reg,'@actual-focus-registration-'..unit,'t',E))(f,unit)
  f.outerBorderFrame=E.CreateFrame('Button','FluxUnitFrameOuter_'..unit,f)
  frames[unit]=f
  ns[unit=='focus' and 'FocusFrame' or 'FocusTargetFrame']=f
 end
 local function sync()for _,f in pairs(frames)do ns.UnitFrames.SyncWatchedUnitFrameVisibility(f)end drain()end
 if ns.UnitFrames.SetFocusUnitWatch then
  check(not ns.UnitFrames.SetFocusUnitWatch({},true),client..' focus policy does not register unrelated frames')
  local before=st.registrations
  for _=1,20 do ns.UnitFrames.SetFocusUnitWatch(frames.focus,true);ns.UnitFrames.SetFocusUnitWatch(frames.focustarget,true)end
  check(st.registrations==before,client..' stable settings do not recompile visibility conditions')
 end
 -- Present before combat, then clear focus. The previous Forever fallback
 -- kept the alpha-zero parent shown and its secure mouse child still active.
 st.units.focus='alive';st.units.focustarget='alive';tick();sync()
 check(hit(frames.focus.outerBorderFrame),client..' existing focus accepts interaction')
 st.combat=true;local mouseBefore=st.mouseWrites
 st.units={};tick();sync()
 check(not frames.focus:IsShown() and frames.focus.alpha==1,client..' missing focus is truly hidden rather than faded')
 check(not hit(frames.focus.outerBorderFrame),client..' clearing focus in combat releases the covered world')
 check(not hit(frames.focustarget.outerBorderFrame),client..' clearing focus releases dependent hit region')
 st.units.focustarget='alive';tick();sync()
 check(not hit(frames.focustarget.outerBorderFrame),client..' dependent cannot outlive a missing focus')
 -- The same prepared buttons must become usable when focus is set in combat.
 st.units.focus='alive';st.units.focustarget='alive';tick();sync()
 check(hit(frames.focus.outerBorderFrame) and frames.focus.alpha==1,client..' new combat focus is shown and clickable')
 check(hit(frames.focustarget.outerBorderFrame),client..' new focus target is clickable')
 st.units.focus='dead';tick();sync()
 check(not hit(frames.focustarget.outerBorderFrame),client..' dead focus does not leave invisible dependent hit region')
 st.units.focus='alive';tick();sync()
 for _=1,20 do st.units={};tick();sync();st.units.focus='alive';st.units.focustarget='alive';tick();sync()end
 check(st.mouseWrites==mouseBefore,client..' combat visibility changes do not write mouse state')
 check(st.blocked==0,client..' no insecure protected writes')
 st.combat=false;drain()
 -- Exercise real runtime toggles so a registered native driver cannot resurrect
 -- the Flux replacement after the user chooses Blizzard presentation.
 E.FLUX_API={hasFocusUnit=true};E.FluxUnitFrames_ShouldUseFlux=function()return true end
 E.FluxUnitFrames_SuppressBlizzardUnitFrame=function()end
 ns.UnitFrames.RegisterInitializer=function()end
 ns.UnitFrames.DeferProtected=function(_,fn)st.timers[#st.timers+1]=fn end
 for i,file in ipairs({'Focus','FocusTarget'})do assert(load(read(arg[i+1] or 'UnitFrames/FluxUnitFrames_'..file..'.lua'),'@actual-focus-runtime-'..file,'t',E))('_FluxUI',ns)end
 E.FluxUIPositionFocusFrameDefault=function()end
 E.FluxUnitFrames_ApplyRuntimeFocusTarget(false);E.FluxUnitFrames_ApplyRuntimeFocus(false);tick();sync()
 check(not hit(frames.focus.outerBorderFrame) and not hit(frames.focustarget.outerBorderFrame),client..' disabled replacements stay absent after driver tick')
 E.FluxUnitFrames_ApplyRuntimeFocus(true);E.FluxUnitFrames_ApplyRuntimeFocusTarget(true);tick();sync()
 check(hit(frames.focus.outerBorderFrame) and hit(frames.focustarget.outerBorderFrame),client..' re-enabled replacements retain interaction')
 -- An empty target used to disable mouse OOC and could not restore it when
 -- first acquired in combat. Replay native visibility on its real click host.
 if src:find('function UF.ConfigureTargetClickVisibility',1,true)then
  assert(load(section(src,'function UF.ConfigureTargetClickVisibility','-- Preserve the existing samples'),
   '@actual-target-click-visibility','t',E))()
 else ns.UnitFrames.ConfigureTargetClickVisibility=function()end end
 local target=E.CreateFrame('Button','FluxUnitFrame_target');target.unit='target';target.attrs.unit='target'
 target.outerBorderFrame=E.CreateFrame('Button','FluxUnitFrameOuter_target',target)
 st.units.target='alive'
 E.RegisterUnitWatch(target)
 ns.UnitFrames.ConfigureTargetClickVisibility(target);tick()
 ns.UnitFrames.SyncWatchedUnitFrameVisibility(target);drain()
 -- Addon target event can run before the native unit-watch hides the root.
 st.units.target=nil
 ns.UnitFrames.SyncWatchedUnitFrameVisibility(target);drain()
 tick()
 check(not hit(target.outerBorderFrame) and target.outerBorderFrame.mouse,client..' empty target hides native hit host with input prepared')
 local registrations=st.registrations
 for _=1,20 do ns.UnitFrames.ConfigureTargetClickVisibility(target)end
 check(st.registrations==registrations,client..' target driver setup is stable')
 st.combat=true;mouseBefore=st.mouseWrites
 for _=1,20 do
  st.units.target='alive';tick();ns.UnitFrames.SyncWatchedUnitFrameVisibility(target);drain()
  check(hit(target.outerBorderFrame),client..' first target gained in combat accepts native right click')
  st.units.target=nil;tick();ns.UnitFrames.SyncWatchedUnitFrameVisibility(target);drain()
  check(not hit(target.outerBorderFrame),client..' cleared combat target releases native hit host')
 end
 check(st.mouseWrites==mouseBefore and st.blocked==0,client..' target transitions make no insecure protected mouse writes')
 st.combat=false
 samples[#samples+1]={client=client,frames=#st.frames,registrations=st.registrations,blocked=st.blocked}
end
print('Focus secure visibility: '..checks..' checks; failures='..failures..'; '..#clients..' pinned driver replays; native combat/taint/hit testing pending')
for _,r in ipairs(samples)do print(r.client..': frames='..r.frames..' registrations='..r.registrations..' protectedFailures='..r.blocked)end
