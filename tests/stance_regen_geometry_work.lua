-- Full Strip/Watch -> Stance layout and Combat owner execution. Native frame,
-- input and form endpoints are modeled; no native CPU/FPS/taint claim.
local path='Bars/Stance/Layout.lua'
if arg and arg[1]=='--source'then path=assert(arg[2])end
local checkpoint=arg[1]=='--strip-checkpoint' and arg[2]
local function read(p)local f=assert(io.open(p,'rb'));local b=f:read('*a');f:close();return b end
local function loadenv(b,p,e)
 if _VERSION=='Lua 5.1'then local f,err=loadstring(b,p);if f then setfenv(f,e)end;return f,err end
 return load(b,p,'t',e)
end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local function fixture(layoutPath)
 local s={frames={},timers={},events={},locked=false,forms=3,buttons={},catalogs=0,paints=0,binds=0,commits=0,chrome=0,pet=0,clips=0}
 local e=setmetatable({}, {__index=_G});e._G=e
 local private=setmetatable({}, {__eq=function()error('private value compared')end})
 e.issecretvalue=function(v)return rawequal(v,private)end
 e.InCombatLockdown=function()return s.locked end
 e.GetTime=function()return 100 end
 local function native(f,method,...)
  local mode=f.modes[method]
  if mode=='error'then error(s.marker,0)end
  if mode=='private'then return private end
  return ...
 end
 local function write(f,method)
  check(not s.locked,'protected '..method..' stays outside lockdown')
  f.writes[method]=(f.writes[method]or 0)+1
  if f.fail==method then error(s.marker,0)end
 end
 local function frame(name,parent)
  local f={name=name,parent=parent,scale=1,width=44,height=44,shown=true,points={},writes={},modes={},scripts={},events={}}
  function f:GetName()return self.name end
  function f:GetSize()return native(self,'GetSize',self.width,self.height)end
  function f:GetWidth()return self.width end;function f:GetHeight()return self.height end
  function f:GetScale()return native(self,'GetScale',self.scale)end
  function f:GetEffectiveScale()return self.scale*(self.parent and self.parent:GetEffectiveScale()or 1)end
  function f:GetParent()return native(self,'GetParent',self.parent)end
  function f:GetNumPoints()return native(self,'GetNumPoints',#self.points)end
  function f:GetPoint()return native(self,'GetPoint',(table.unpack or unpack)(self.points[1]or{}))end
  function f:SetSize(w,h)write(self,'SetSize');self.width,self.height=w,h end
  function f:SetScale(v)write(self,'SetScale');self.scale=v end
  function f:SetParent(v)write(self,'SetParent');self.parent=v end
  function f:ClearAllPoints()write(self,'ClearAllPoints');self.points={}end
  function f:SetPoint(...)write(self,'SetPoint');self.points[1]={...}end
  function f:SetClipsChildren(clip)self.clip=clip;s.clips=s.clips+1 end
  function f:DoesClipChildren()return native(self,'DoesClipChildren',self.clip)end
  function f:Show()self.shown=true end;function f:Hide()self.shown=false end
  function f:IsShown()return self.shown end;function f:IsVisible()return self.shown end
  function f:SetAlpha(v)self.alpha=v end
  function f:RegisterEvent(v)self.events[v]=true end
  function f:SetScript(k,v)self.scripts[k]=v end
  function f:EnableMouse()end
  s.frames[#s.frames+1]=f;return f
 end
 e.CreateFrame=function(_,name,parent)return frame(name,parent)end
 e.UIParent=frame('UIParent');local root=e.UIParent
 local stanceFrame=frame('stance',root)
 local player=frame('player',root);player.outerBorderFrame=frame('playerBorder',player);player.outerBorderFrame.height=100
 local stance={GetFrame=function()return stanceFrame end,ShouldAnchorToPlayerBorder=function()return s.attached~=false end,
  STANCE_SIZE=30,STANCE_SPACING=-2,BORDER_PAD_H=5.5,BORDER_PAD_V=13.5,MAX_ROWS_PER_COLUMN=5,
  STANCE_SIZE_REF_COUNT=3,STANCE_BUTTON_SIZE_MULT=1.055,PET_SLOT_LAYOUT_PAD_H=2,PET_SLOT_LAYOUT_PAD_V=4,
  STANCE_ANCHOR_GAP=-4,STANCE_WINDOW_GAP_X=-4,STANCE_WINDOW_GAP_Y=-4,STATUS_LOC2_STACK_GAP=2,
  ApplyBorderChrome=function()s.chrome=s.chrome+1 end,
  Catalog=function()s.catalogs=s.catalogs+1;return s.forms,{}, {},s.forms end,
  GetSavedOrder=function()return{}end,
  BuildPermutation=function(n)local list={};for i=1,n do list[i]=i end;return list end,
  EnsureFormButton=function(i)return s.buttons[i]end,
  ReassignBindings=function()s.binds=s.binds+1;return true end,
  ForEachPooled=function(fn)for _,b in ipairs(s.buttons)do fn(b)end end,
  PaintFormVisuals=function()s.formVisuals=(s.formVisuals or 0)+1 end,
  PaintExtraVisuals=function()s.extraVisuals=(s.extraVisuals or 0)+1 end}
 for i=1,3 do s.buttons[i]={Widget=frame('widget'..i,root),SlotFrame=frame('slot'..i,root)}end
 local flux={Bars={Stance=stance,CONFIG={buttonSize=44},ForEachHost=function()end,RequestPaint=function()end},
  EBS={Paint={Update=function()s.paints=s.paints+1 end}},Cap={IsGamepadUIEnabled=function()return s.hud end},
  Safecall=function(fn,...)return pcall(fn,...)end,
  Timer={After=function(_,fn)s.timers[#s.timers+1]=fn end,Defer=function(fn)s.timers[#s.timers+1]=fn end}}
 flux.Bars.Pet={UpdatePosition=function()s.pet=s.pet+1 end}
 flux.Events={Register=function(name,fn)s.events[name]=s.events[name]or{};table.insert(s.events[name],fn)end}
 e.FluxBorder={Junctions={CommitLayout=function()s.commits=s.commits+1 end}}
 e.FluxUILayoutSqueeze={GetEffectiveEmulatedDependentXFactorForUnitFrames=function()return s.squeeze or 1 end}
 local ns={Flux=flux,PlayerFrame=player}
 for _,p in ipairs{'Core/Engine/Combat.lua','Bars/Strip.lua','Bars/Watch.lua','Bars/Stance/Watch.lua'}do
  assert(loadenv(read(p),'@'..p,e))('_FluxUI',ns)
 end
 layoutPath=layoutPath or path
 assert(loadenv(read(layoutPath),'@'..layoutPath,e))('_FluxUI',ns)
 flux.Bars.Strip.frame=frame('strip',root);flux.Bars.secureReady=true
 flux.Bars.Watch.Start();stance.Watch.Start()
 s.stance,s.stanceFrame,s.flux,s.env,s.player,s.frame,s.ns=stance,stanceFrame,flux,e,player,frame,ns
 function s:emit(name,...)
  for _,f in ipairs(self.frames)do if f.events[name]and f.scripts.OnEvent then f.scripts.OnEvent(f,name,...)end end
  for _,fn in ipairs(self.events[name]or{})do fn(name,...)end
 end
 function s:drain()local q=self.timers;self.timers={};for _,fn in ipairs(q)do fn()end end
 function s:regen()self.locked=false;self:emit('PLAYER_REGEN_ENABLED');self:drain()end
 function s:childWrites()
  local n=0;for _,b in ipairs(self.buttons)do for _,f in ipairs{b.Widget,b.SlotFrame}do for _,v in pairs(f.writes)do n=n+v end end end;return n
 end
 return s
end

local function stripFixture(before, attached)
 local function source(relative)
  return before and before..'/'..relative:gsub('/','-') or relative
 end
 local s=fixture(source('Bars/Stance/Layout.lua'))
 local e,ns,pet=s.env,s.ns,s.flux.Bars.Pet
 s.attached=attached;s.squeeze=.85;e.Flux=s.flux
 local petFrame=s.frame('pet',e.UIParent)
 pet.CONFIG={buttonSize=44,buttonPadding=1,columns=5,rows=5,totalButtons=0}
 pet.GetFrame=function()return petFrame end
 e.FluxWindowFrame=s.frame('window',e.UIParent)
 assert(loadenv(read(source('Bars/Pet/Layout.lua')),'@strip-pet-layout',e))('_FluxUI',ns)
 local code=read(source('FluxDefaultSettings.lua')):gsub('\r\n','\n')
 local first=assert(code:find('-- Squeeze callback bodies are shared across notifications.',1,true))
 local last=assert(code:find('local squeezeRefreshScheduled',first,true))
 assert(loadenv(code:sub(first,last-1),'@strip-stance-notifier',e))()
 pet.LayoutButtons()
 s:drain()
 local sizeOnly=s.stance.RequestSizeOnly
 function s.stance.RequestSizeOnly(...)
  s.sizeRequests=(s.sizeRequests or 0)+1
  return sizeOnly(...)
 end
 function s:cross()
  local owner=attached and s.player.outerBorderFrame or e.FluxWindowFrame
  owner.offset=owner.offset==20 and 0 or 20
  e.FluxUILayoutSqueeze.NotifyLayoutDependents(true,true)
  e.FluxBorder.Junctions:CommitLayout()
 end
 function s:signature()
  local values={}
  for _,f in ipairs({self.stanceFrame,self.buttons[1].SlotFrame,self.buttons[1].Widget})do
   local point,owner,relative,x,y=f:GetPoint()
   for _,v in ipairs({f.width,f.height,f.scale,point,owner.name,relative,x,y,tostring(f.shown)})do
    values[#values+1]=tostring(v)
   end
  end
  return table.concat(values,'|')
 end
 return s
end

for _,attached in ipairs{true,false}do
 local a,b=stripFixture(checkpoint,attached),stripFixture(nil,attached)
 local keys={'catalogs','paints','binds','commits'}
 local before,after={},{}
 for _,key in ipairs(keys)do before[key],after[key]=a[key],b[key] end
 for _=1,8 do
  a:cross();a:drain()
  b:cross()
  check(#b.timers==0,'settled stance has no follow-up wake after a strip crossing')
  b:drain()
  check(a:signature()==b:signature(),'strip crossing keeps identical stance size and relative anchors')
 end
 local results={}
 for _,key in ipairs(keys)do
  local old,new=a[key]-before[key],b[key]-after[key]
  check(new==(key=='commits' and 8 or 0),'settled stance avoids duplicate '..key)
  if checkpoint then check(old==({catalogs=8,paints=24,binds=8,commits=16})[key],'baseline covers '..key)end
  results[#results+1]=('%s=%d/%d'):format(key,old,new)
 end
 check(not b.sizeRequests,'pet and notifier do not request a full stance repaint on a settled crossing')
 print(('STANCE_STRIP_LAYOUT|%s|%s'):format(attached and 'player' or 'pet',table.concat(results,'|')))
 local function repair(trigger,accept)
  local old=b.catalogs
  trigger();b:cross()
  check(#b.timers==1,'changed stance geometry queues one repair')
  b:drain()
  check(b.catalogs==old+1 and (not accept or accept()),'repair applies full current stance layout')
 end
 repair(function()b.squeeze=.7 end,function()return b.buttons[1].Widget.width==44*.7 end)
 repair(function()b.buttons[1].Widget.points={}end,function()return b.buttons[1].Widget.points[1][1]=='CENTER'end)
 repair(function()b.buttons[1].SlotFrame.clip=false end,function()return b.buttons[1].SlotFrame.clip end)
 repair(function()b.stanceFrame.points={}end,function()return #b.stanceFrame.points==1 end)
 repair(function()b.stanceFrame.modes.GetPoint='private'end)
 b.stanceFrame.modes.GetPoint=nil
 if attached then
  repair(function()b.player.outerBorderFrame.height=125 end)
 else
  repair(function()b.flux.Bars.Pet.CONFIG.rows=6 end)
  repair(function()b.env.FluxWindowFrame=b.frame('replacementWindow',b.env.UIParent)end,
   function()return b.stanceFrame.points[1][2]==b.env.FluxWindowFrame end)
 end
 repair(function()b.forms=2;b:emit('UPDATE_SHAPESHIFT_FORMS')end,function()return not b.buttons[3].Widget.shown end)
 local beforeLock=b.catalogs
 b.locked=true
 b.env.FluxUILayoutSqueeze.NotifyLayoutDependents(true,true)
 check(#b.timers==0 and b.catalogs==beforeLock,'lockdown defers the notifier without touching protected layout')
 b:regen();b:drain()
 check(b.catalogs>beforeLock,'pending combat and ordinary refresh paths still apply current geometry')
end

do
 local s=fixture();check(s.stance.ApplyLayout(),'initial layout completes')
 local child=s:childWrites();local sizes=s.stanceFrame.writes.SetSize
 local cat,paint,bind,commit,chrome,pet,clip=s.catalogs,s.paints,s.binds,s.commits,s.chrome,s.pet,s.clips
 for _=1,50 do s.locked=true;s:emit('PLAYER_REGEN_DISABLED');s:regen()end
 check(s:childWrites()==child and s.stanceFrame.writes.SetSize==sizes,'50 unchanged combat exits skip only identical native child geometry and root size')
 check(s.catalogs==cat+50 and s.paints==paint+150 and s.binds==bind+50,'full fresh derivation, visual paint and binding repair cadence retained')
 check(s.commits==commit+50 and s.chrome==chrome+50 and s.pet==pet+50 and s.clips==clip+150,'border/layout integrations and clipping callbacks retained')
 check(s.formVisuals==50 and s.extraVisuals==50,'entry/exit visual requests retain original deferred coalescing')
 local b=s.buttons[1];b.Widget.width=1;b.Widget.scale=2;b.Widget.parent=s.env.UIParent;b.Widget.points={};b.SlotFrame.width=1;b.SlotFrame.parent=s.env.UIParent;b.SlotFrame.points={{'LEFT',s.env.UIParent,'LEFT',1,2},{'RIGHT',s.env.UIParent,'RIGHT',0,0}}
 s:regen();check(b.Widget.width==44 and b.Widget.scale~=2 and b.Widget.parent==b.SlotFrame and b.Widget.points[1][1]=='CENTER','external widget size/scale/parent/anchor drift repaired live')
 check(b.SlotFrame.parent==s.stanceFrame and #b.SlotFrame.points==1 and b.SlotFrame.points[1][1]=='TOPRIGHT','slot parent and multiple-anchor drift repaired live')
 s.locked=true;s.forms=2;s.stance.RequestLayout('options');s:drain()
 check(s.flux.Combat.PendingCount()==1,'changed layout requested during combat remains queued')
 s:regen();check(not s.buttons[3].Widget.shown and s.binds>bind+50 and s.flux.Combat.PendingCount()==0,'queued source/layout change applies after combat')
 s.forms=3;s.squeeze=.75;s.stance.RequestSizeOnly();s:drain()
 check(b.Widget.width==33 and b.Widget.shown,'squeeze/size-only request applies fresh desired geometry')
 local paints=s.paints;s.flux.Bars.Strip.ApplyGamepadHud();check(s.paints==paints+3,'explicit gamepad refresh still executes full layout')
 s.hud=true;s.flux.Bars.Strip.ApplyGamepadHud();check(not s.flux.Bars.Strip.frame.shown,'real gamepad transition preserves strip visibility')
 s.hud=false;s.flux.Bars.Strip.ApplyGamepadHud();check(s.flux.Bars.Strip.frame.shown,'leaving gamepad restores strip visibility')
 local pet,chrome=s.pet,s.chrome;s.stance.Anchor();check(s.pet==pet+1 and s.chrome==chrome+1,'standalone Anchor preserves integrations')
end
for _,mode in ipairs{'private','error','missing'}do
 local s=fixture();s.stance.ApplyLayout();s.marker={}
 local b=s.buttons[1]
 for _,spec in ipairs{{b.Widget,'GetSize'},{b.Widget,'GetScale'},{b.Widget,'GetParent'},{b.Widget,'GetPoint'},{b.SlotFrame,'GetSize'},{b.SlotFrame,'GetParent'},{b.SlotFrame,'GetNumPoints'}}do
  if mode=='missing'then spec[1][spec[2]]=false else spec[1].modes[spec[2]]=mode end
 end
 local before=s:childWrites()
 local parentWrites=b.Widget.writes.SetParent;local slotParentWrites=b.SlotFrame.writes.SetParent
 local scaleWrites=b.Widget.writes.SetScale
 check(s.stance.ApplyLayout()and s:childWrites()>before,mode..': unavailable getters retain original setters without comparing private values')
 check(b.Widget.writes.SetParent==parentWrites+1 and b.SlotFrame.writes.SetParent==slotParentWrites+1
  and b.Widget.writes.SetScale==scaleWrites+1,mode..': each original protected parent/scale setter remains called despite its original pcall wrapper')
end
for _,method in ipairs{'SetSize','ClearAllPoints','SetPoint','SetScale','SetParent'}do
 local s=fixture();s.stance.ApplyLayout();s.marker={};local b=s.buttons[1]
 local f=(method=='ClearAllPoints'or method=='SetPoint')and b.SlotFrame or b.Widget
 f.fail=method;f.width=1;f.scale=2;f.parent=s.env.UIParent;f.points={}
 local before=f.writes[method]or 0;local ok,err=pcall(s.stance.ApplyLayout)
 check((f.writes[method]or 0)==before+1,method..': original failing setter still called')
 if method=='SetScale'or method=='SetParent'then check(ok,method..': original pcall policy retained')
 else check(not ok and err==s.marker,method..': exact direct setter error preserved')end
end
print('stance regen geometry work: '..checks..' checks PASS; native latency/geometry/taint pending')
