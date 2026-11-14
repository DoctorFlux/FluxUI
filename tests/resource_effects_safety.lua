-- Actual Shared spark, pulse animation constructor and main-bar factory replay.
-- Counted widget contracts are not a native rendering/taint/FPS certification.
local source=arg[1] or 'UnitFrames/FluxUnitFrames_Shared.lua'
local output=arg[2]
local measure=arg[3]=='--measure'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function slice(s,a,b)local first=assert(s:find(a,1,true),a);return s:sub(first,assert(s:find(b,first+#a,true),b)-1)end
local body=read(source)
local checks,failures=0,0
local results={}
local failureMessages={}
local function check(value,message)
 checks=checks+1
 if not value then failures=failures+1;failureMessages[#failureMessages+1]=message;if not measure then error(message,2) end end
end
local geometry=slice(body,'local function ValueIsSecret(value)','-- The addon owns these dimensions.')
local sparkCode=slice(body,'function UF.UpdateResourceSpark(','local function EnsureResourceSpark(')
local pulseCode=slice(body,'local function ConfigureAlpha(','-- Shorten the displayed fill')
local factory=slice(body,'function UF.CreatePowerBar(frame)','-- 3D Portrait')
local function scenario(client)
 local s={combat=false,hud=client=='live' or client=='forever',atlas=true,frames=0,textures=0,groups=0,animations=0,
  blocked=0,unsafe=0,getters=0,styleWrites=0,plays=0,regs=0,queues=0,now=100}
 local secret,inaccessible={},{}
 local function denied()s.unsafe=s.unsafe+1;error('secret arithmetic/comparison')end
 for _,v in ipairs({secret,inaccessible}) do setmetatable(v,{__add=denied,__sub=denied,__lt=denied,__le=denied})end
 local env=setmetatable({},{__index=_G});env._G=env
 local ns={Flux={Client={}}};local UF={UsesHudUnitBars=function()return s.hud end};ns.UnitFrames=UF
 local API={IsSecretValue=function(v)return v==secret end,CanAccessValue=function(v)return v~=inaccessible end,
  SafeGetNumber=function(v,default)return type(v)=='number' and v or default end}
 env.ns,env.UF,env.API,env.TEXTURE_BAR=ns,UF,API,'bar'
 env.AtlasExists=function()return s.atlas end;env.InCombatLockdown=function()return s.combat end
 env.UnitAffectingCombat=function()return s.combat end;env.GetTime=function()return s.now end
 env.C_EventUtils={IsEventValid=function()return true end}
 env.geterrorhandler=function()return function(err)error(err)end end
 local pending={}
 UF.DeferProtected=function(key,fn)s.queues=s.queues+1;pending[key]=fn end
 local allFrames={}
 local function legal(w)
  if s.combat and w.protected and (w.kind=='Frame' or w.kind=='StatusBar') then s.blocked=s.blocked+1;error('protected combat structure')end
 end
 local widget
 local function animationGroup(parent)
  s.groups=s.groups+1
  local group={parent=parent,playing=false,anims={},scripts={}}
  function group:CreateAnimation(kind)
   legal(self.parent);s.animations=s.animations+1
   local anim={kind=kind};self.anims[#self.anims+1]=anim
   return setmetatable(anim,{__index=function(_,key)return function(self,...)self[key]={...}end end})
  end
  function group:SetLooping(v)self.looping=v end
  function group:SetToFinalAlpha(v)self.final=v end
  function group:SetScript(k,v)self.scripts[k]=v end
  function group:IsPlaying()return self.playing end
  function group:Play()self.playing=true;s.plays=s.plays+1 end
  function group:Stop()self.playing=false end
  return group
 end
 widget=function(kind,parent,protected)
  local w={kind=kind,parent=parent,protected=protected or parent and parent.protected,shown=true,width=100,height=24,level=40,scripts={},events={}}
  function w:SetAllPoints(v)legal(self);self.all=v end
  function w:SetFrameLevel(v)legal(self);self.level=v end
  function w:GetFrameLevel()return self.level end
  function w:GetParent()return self.parent end
  function w:SetFrameStrata(v)legal(self);self.strata=v end
  function w:GetFrameStrata()return self.strata or 'MEDIUM'end
  function w:SetSize(x,y)legal(self);self.width,self.height=x,y end
  function w:SetWidth(v)legal(self);self.width=v end
  function w:SetHeight(v)legal(self);self.height=v end
  function w:SetPoint(...)legal(self);self.point={...};s.styleWrites=s.styleWrites+1 end
  function w:ClearAllPoints()legal(self);self.point=nil;s.styleWrites=s.styleWrites+1 end
  function w:SetScale(v)self.scale=v;s.styleWrites=s.styleWrites+1 end
  function w:SetAlpha(v)self.alpha=v end
  function w:Show()legal(self);self.shown=true end
  function w:Hide()legal(self);self.shown=false end
  function w:IsShown()return self.shown end
  function w:SetBlendMode(v)self.blend=v end
  function w:SetVertexColor(...)self.vertex={...}end
  function w:SetAtlas(v)self.atlas=v;s.styleWrites=s.styleWrites+1 end
  function w:SetTexture(v)self.texture=v end
  function w:SetStatusBarTexture(v)self.texture=v end
  function w:SetStatusBarColor(...)self.color={...}end
  function w:GetStatusBarTexture()return self.fill end
  function w:GetWidth()s.getters=s.getters+1;if self.getterError then error('unavailable width')end;return self.width end
  function w:GetHeight()s.getters=s.getters+1;if self.getterError then error('unavailable height')end;return self.height end
  function w:SetClipsChildren()end
  function w:SetHorizTile()end
  function w:SetFont(...)self.font={...}end
  function w:SetTextColor(...)self.color={...}end
  function w:EnableMouse()end
  function w:SetScript(k,v)self.scripts[k]=v end
  function w:RegisterEvent(k)self.events[k]=true;s.regs=s.regs+1 end
  function w:UnregisterEvent(k)self.events[k]=nil end
  function w:CreateTexture()
   s.textures=s.textures+1
   local tex=widget('Texture',self,false);tex.protected=false;return tex
  end
  function w:CreateFontString()local fs=widget('FontString',self,false);fs.protected=false;return fs end
  function w:CreateAnimationGroup()legal(self);return animationGroup(self)end
  return w
 end
 env.CreateFrame=function(kind,_,parent)
  if s.combat and parent and parent.protected then s.blocked=s.blocked+1;error('protected combat allocation')end
  if s.failPulse and parent and parent._fluxPulseCanChangeType and kind=='Frame' then error('temporary OOC constructor failure')end
  s.frames=s.frames+1
  local w=widget(kind,parent);allFrames[#allFrames+1]=w
  if kind=='StatusBar' then w.fill=widget('Texture',w,false);w.fill.protected=false;w.fill.width=50 end
  return w
 end
 assert(load(geometry..sparkCode..pulseCode..factory,'@actual-shared-resource-effects','t',env))()
 local function root(flags)
  local frame=widget('Frame',nil,true);frame.unit='party1'
  for k,v in pairs(flags or {})do frame[k]=v end
  return frame
 end
 local before=s.frames
 local frame=root();local bar=UF.CreatePowerBar(frame)
 check(frame.Power==bar,'actual main-bar factory mounts exact bar')
 local setup={frames=s.frames-before,textures=s.textures,groups=s.groups,animations=s.animations,regs=s.regs}
 if s.hud then
  check(bar.FullPowerFrame~=nil,'factory prewarms future-unit pulse before any paint')
  check(bar.FullPowerFrame and not bar.FullPowerFrame.active and bar.FullPowerFrame.alpha==0,'inactive preparation is transparent')
 else check(not bar.FullPowerFrame and s.groups==0,'Classic factory adds no pulse resources')end
 for _,f in ipairs(allFrames)do check(f.scripts.OnUpdate==nil,'no idle OnUpdate driver')end
 s.combat=true;local allocated=s.frames
 UF.SetFullResourcePulseActive(bar,true)
 UF.UpdateFullResourcePulse(bar,100,100)
 if s.hud then
  check(s.blocked==0 and s.frames==allocated and not bar._fluxPulseFailed,'first combat activation never allocates or poisons pulse')
  check(bar.FullPowerFrame and bar.FullPowerFrame._shownFull and bar.FullPowerFrame.SpikeFrame.SpikeAnim:IsPlaying(),'prepared full animation starts on original paint')
  UF.UpdateFullResourcePulse(bar,30,100)
  check(bar.FullPowerFrame and not bar.FullPowerFrame._shownFull and bar.FullPowerFrame.FadeoutAnim:IsPlaying(),'spend retains native fade request')
  UF.SetFullResourcePulseActive(bar,false)
  check(bar.FullPowerFrame and not bar.FullPowerFrame.active and bar.FullPowerFrame.alpha==0,'deactivation retains transparent stop semantics')
 end
 -- Cold external bar: no secure allocations or permanently failed state in combat.
 local cold=widget('StatusBar',root(),true);cold.fill=widget('Texture',cold,false);cold.fill.protected=false
 local blocked=s.blocked;local queues=s.queues
 for _=1,100 do UF.SetFullResourcePulseActive(cold,true)end
 if s.hud then check(s.blocked==blocked and not cold._fluxPulseFailed and s.queues==queues+1,'cold requests coalesce without forbidden attempt')end
 UF.SetFullResourcePulseActive(cold,false)
 s.combat=false;for key,fn in pairs(pending)do pending[key]=nil;fn()end
 if s.hud then check(not cold.FullPowerFrame and not cold._fluxPulsePreparePending,'latest disabled cold request cancels activation/allocation')end
 -- OOC explicit active request remains compatible for bars outside the main factory.
 UF.SetFullResourcePulseActive(cold,true)
 check(not s.hud or cold.FullPowerFrame and cold.FullPowerFrame.active,'OOC explicit demand remains functional')
 local unneeded=root({_fluxPartyPet=true,_fluxHealthBarOnly=true})
 local more=s.frames;local petPower=UF.CreatePowerBar(unneeded)
 check(s.frames-more==2 and not petPower.FullPowerFrame,'HP-only party/focus bars avoid inactive prewarm')
 if s.hud then
  local latest=widget('StatusBar',root(),true);s.combat=true;local queued=s.queues
  UF.SetFullResourcePulseActive(latest,true);UF.SetFullResourcePulseActive(latest,false);UF.SetFullResourcePulseActive(latest,true)
  check(s.queues==queued+1,'cold false/true changes retain one latest job')
  for _,fn in pairs(pending)do fn()end
  check(not latest.FullPowerFrame and latest._fluxPulsePreparePending,'early flush while combat remains pending')
  s.combat=false;for key,fn in pairs(pending)do pending[key]=nil;fn()end
  check(latest.FullPowerFrame and latest.FullPowerFrame.active,'latest enabled cold request prepares at regen')
  s.atlas=false
  local late=root();local lateBar=UF.CreatePowerBar(late)
  check(not lateBar.FullPowerFrame and not lateBar._fluxPulseFailed,'missing atlases do not poison future preparation')
  s.atlas=true;UF.SetFullResourcePulseActive(lateBar,false)
  check(lateBar.FullPowerFrame and not lateBar.FullPowerFrame.active,'late atlas availability retries inactive preparation')
  local broken=widget('StatusBar',root(),true);broken._fluxPulseCanChangeType=true
  s.failPulse=true;UF.SetFullResourcePulseActive(broken,true)
  check(broken._fluxPulseFailed==true,'genuine OOC constructor failure keeps established failure policy')
  s.failPulse=false
 end
 -- Actual central Events fallback; an existing consumer remains registered.
 if s.hud then
  UF.DeferProtected=nil
  assert(load(read('Core/Engine/Events.lua'),'@actual-central-events','t',env))('_FluxUI',ns)
  local other=0;ns.Flux.Events.Register('PLAYER_REGEN_ENABLED',function()other=other+1 end)
  local fallback=widget('StatusBar',root(),true)
  local setter=UF.SetFullResourcePulseActive;local reconciles=0
  UF.SetFullResourcePulseActive=function(bar,...)if bar==fallback then reconciles=reconciles+1 end;return setter(bar,...)end
  s.combat=true;UF.SetFullResourcePulseActive(fallback,true)
  check(not fallback.FullPowerFrame and fallback._fluxPulsePreparePending,'missing helper uses owned regen subscription')
  s.combat=false
  for _,f in ipairs(allFrames)do if f.events.PLAYER_REGEN_ENABLED and f.scripts.OnEvent then f.scripts.OnEvent(f,'PLAYER_REGEN_ENABLED')end end
  check(fallback.FullPowerFrame and fallback.FullPowerFrame.active and not fallback._fluxPulsePreparePending,'regen fallback prepares latest demand')
  check(other==1,'fallback never replaces/removes another regen consumer')
  local reconciled=reconciles
  for _,f in ipairs(allFrames)do if f.events.PLAYER_REGEN_ENABLED and f.scripts.OnEvent then f.scripts.OnEvent(f,'PLAYER_REGEN_ENABLED')end end
  check(other==2 and reconciles==reconciled,'completed fallback unsubscribes only its own callback')
  UF.SetFullResourcePulseActive=setter
  local events=ns.Flux.Events;ns.Flux.Events=nil
  local noOwner=widget('StatusBar',root(),true);s.combat=true;UF.SetFullResourcePulseActive(noOwner,true)
  check(not noOwner.FullPowerFrame and not noOwner._fluxPulsePreparePending and not noOwner._fluxPulseFailed,'missing queue ownership stays retryable without protected attempt')
  s.combat=false;UF.SetFullResourcePulseActive(noOwner,true)
  check(noOwner.FullPowerFrame and noOwner.FullPowerFrame.active,'ordinary next paint recovers if no queue service was available')
  ns.Flux.Events=events
 end
 -- Spark active only on HUD clients, including secret and invalid native geometry.
 local fill=widget('Texture',nil,false);fill.width=50;fill.height=24
 local tex=widget('Texture',nil,false)
 local sparkBar=widget('StatusBar',nil,false);sparkBar.Spark=tex;sparkBar.fill=fill
 local info={atlas='spark',barHeight=12,xOffset=2}
 s.combat=false
 local function paint()UF.UpdateResourceSpark(sparkBar,info)end
 paint()
 if s.hud then check(tex.shown and tex.scale==2,'readable spark appearance unchanged')else check(not tex.shown,'Classic spark gate unchanged')end
 local style=s.styleWrites;local gets=s.getters
 for _=1,300 do paint()end
 local stable={styleWrites=s.styleWrites-style,getters=s.getters-gets}
 check(stable.styleWrites==0,'settled style writes remain zero')
 if s.hud then
  fill.width=100;paint();check(not tex.shown,'full resource hides spark same paint')
  info.showAtMax=true;paint();check(tex.shown,'show-at-max remains immediate')
  fill.width=0;paint();check(not tex.shown,'empty resource remains hidden')
  fill.width=50;info.showAtMax=false
  local scales=tex.scale
  for _,value in ipairs({secret,inaccessible,0/0,math.huge,-math.huge,'50',false})do
   fill.height=value;fill.width=value;sparkBar.width=value
   for _=1,100 do paint()end
   check(s.unsafe==0,'secret/inaccessible geometry never enters arithmetic even inside pcall')
   check(not tex.shown and tex.scale==scales,'unverifiable geometry retains hidden/unscaled fallback')
  end
  fill.height,fill.width,sparkBar.width=36,50,100;paint()
  check(tex.shown and tex.scale==3,'public geometry resumes on first readable paint')
  fill.getterError=true;paint();check(not tex.shown,'getter error retains quiet fallback');fill.getterError=false
 end
 return {client=client,setup=setup,stable=stable,counters=s}
end
for _,client in ipairs({'live','forever','classic','classic_era','classic_anniversary'})do results[#results+1]=scenario(client)end
local function json(v)
 if type(v)=='number' or type(v)=='boolean' then return tostring(v)end
 if type(v)=='string'then return string.format('%q',v)end
 local array=true;for k in pairs(v)do if type(k)~='number'then array=false end end
 local out={};if array then for i=1,#v do out[#out+1]=json(v[i])end;return '['..table.concat(out,',')..']'end
 local keys={};for k in pairs(v)do keys[#keys+1]=k end;table.sort(keys)
 for _,k in ipairs(keys)do out[#out+1]=json(k)..':'..json(v[k])end;return '{'..table.concat(out,',')..'}'
end
if output then local f=assert(io.open(output,'wb'));f:write(json({checks=checks,failures=failures,failureMessages=failureMessages,lua=_VERSION,results=results}),'\n');f:close()end
print(('Resource effects safety: %d checks, %d failures; actual helpers/factory/central regen; native appearance/taint/FPS pending'):format(checks,failures))
if failures>0 and not measure then os.exit(1)end
