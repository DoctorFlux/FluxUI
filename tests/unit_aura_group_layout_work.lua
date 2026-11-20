-- Production native-aura synchronization plus each client's actual layout
-- setter. This measures unchanged layout work, not native FPS or taint safety.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(arg[1]or'UnitFrames/FluxUnitFrames_AurasEngine.lua')
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function section(text,a,b)local i=assert(text:find(a,1,true),a);return text:sub(i,assert(text:find(b,i+#a,true),b)-1)end
local start=source:find('local function PublicLayoutNumber',1,true)or assert(source:find('local function GroupLayout',1,true))
local helpers=source:sub(start,assert(source:find('local function DiscardEngine',start,true))-1)
local function Fixture(client)
 local base='../__AddonsForRef/wow-ui-source-'..client..'/Interface/AddOns/Blizzard_AuraContainer/'
 local native=read(base..'Blizzard_CustomAuraContainer.lua')
 local shared=read(base..'Blizzard_AuraContainer.lua')
 check(native:find('Intentionally not exposed via the inbound interface',1,true)~=nil,'native group clearing is private, outside addon-owned public lifecycle')
 local setLayout=assert(native:match('function CustomAuraContainerSharedMixin:SetAuraGroupLayout%b()%s.-\nend'))
 local setUnit=assert(shared:match('function AuraContainerSharedMixin:SetUnit%b()%s.-\nend'))
 local setEnabled=assert(shared:match('function AuraContainerSharedMixin:SetEnabled%b()%s.-\nend'))
 check(not setUnit:find('ClearAuraGroups',1,true)and not setEnabled:find('ClearAuraGroups',1,true),'native unit/enable transitions preserve group registration')
 local counters={layout=0,dirty=0,refresh=0,count=0,frames=0,size=0,max=0,flow=0}
 local secret=setmetatable({}, {__eq=function()error('opaque compared')end,__lt=function()error('opaque ordered')end,__index=function()error('opaque indexed')end})
 local E=setmetatable({UF={},AURA_BORDER_INSET_X=8,AURA_BORDER_INSET_Y_TOP=10,AURA_BORDER_INSET_Y_BOTTOM=10,
  XSqueeze=function()return 1 end,FlowDir=function(n)return n end,GetDurationFormatter=function()end,
  AuraContainerSharedMixin={},CustomAuraContainerSharedMixin={},AuraContainerDirtyMask={AuraFrameLayoutGroups=1},
  issecretvalue=function(v)return rawequal(v,secret)end}, {__index=_G})
 E.GetRequiredAuraGroup=function(e,key)return assert(e.groups[key])end
 E.GetInboundAuraGroupLayoutOptions=function(options)return options end
 assert(load(setLayout..'\n'..setUnit..'\n'..setEnabled,'@pinned-'..client..'-layout-setters','t',E))()
 local exports=assert(load(helpers..'\nreturn {add=AddGroup,layout=SetGroupLayout,cache=groupLayouts}','@actual-aura-group-layout','t',E))()
 local function engine()
  local e={groups={buffs={},own={},other={}},layoutOptionsByAuraGroup={},frameCount=8,enabled=true,unitToken='target'}
  local nativeLayout=E.CustomAuraContainerSharedMixin.SetAuraGroupLayout
  function e:SetAuraGroupLayout(key,options)
   counters.layout=counters.layout+1;if self.failLayout then error('native layout rejected')end
   return nativeLayout(self,key,options)
  end
  function e:MarkDirty(mask)check(mask==1,'exact native group-layout dirty flag');counters.dirty=counters.dirty+1 end
  function e:HasAuraGroup(key)if self.privateGroup then return secret end;return self.groups[key]~=nil end
  function e:AddAuraGroup(key,filter,options)check(not self.groups[key],'owned re-registration uses a genuinely absent key');self.groups[key]={};self.layoutOptionsByAuraGroup[self.groups[key]]=options.layout end
  function e:SetAuraGroupMaxFrameCount()counters.max=counters.max+1 end
  function e:GetAuraGroupFrameCount()counters.count=counters.count+1;if self.privateCount then return secret end;return self.frameCount end
  function e:GetAuraGroupFrame()counters.frames=counters.frames+1;if self.privateFrame then return secret end;return {SetSize=function(_,w,h)counters.size=counters.size+1;check(type(w)=='number'and type(h)=='number','existing member gets current public dimensions')end}end
  e.SetUnit=E.AuraContainerSharedMixin.SetUnit;e.SetEnabled=E.AuraContainerSharedMixin.SetEnabled
  function e:UpdateEventRegistrations()end
  function e:UpdateAllAuras()counters.refresh=counters.refresh+1 end
  for _,name in ipairs{'SetFlowLayoutAnchorPoint','SetFlowLayoutGrowthDirection','SetFlowLayoutPadding','SetFlowLayoutMaximumLineSize'}do e[name]=function()counters.flow=counters.flow+1 end end
  return e
 end
 local function panel(unit,kind)
  return {unit=unit,containerType=kind,_fluxEngine=engine(),maxAuras=32,_fluxAuraBaseSize=35,_fluxAuraBaseSpacing=2,GetWidth=function()return 160 end}
 end
 local function sync(p)E.UF.SyncEngineAuras(p,{unit=p.unit})end
 return E,exports,counters,engine,panel,sync,secret
end
for _,client in ipairs{'forever','live'}do
 local E,x,c,new,panel,sync,secret=Fixture(client)
 local panels={panel('target','Buff'),panel('target','Debuff'),panel('focus','Buff'),panel('focus','Debuff')}
 for _,p in ipairs(panels)do sync(p)end
 local dirty,refresh,count,frames,size,max,flow=c.dirty,c.refresh,c.count,c.frames,c.size,c.max,c.flow
 check(dirty==6,'four actual panels apply six initial group layouts')
 for _=1,10 do for _,p in ipairs(panels)do sync(p)end end
 check(c.dirty==dirty,'unchanged synchronization never dirties the native group layout again')
 check(c.refresh-refresh==40 and c.count-count==60 and c.frames-frames==480 and c.size-size==480,'all full-aura refreshes and fresh native membership/frame/size work retain original cadence')
 check(c.max-max==60 and c.flow-flow==160,'native max-count and flow updates remain unchanged')
 local p=panels[2];local e=p._fluxEngine
 p._fluxAuraBaseSize=39;sync(p);check(c.dirty==dirty+2,'changed public width/height updates both current debuff layouts once');dirty=c.dirty
 p._fluxAuraBaseSpacing=3;sync(p);check(c.dirty==dirty+2,'changed spacing updates both layouts once');dirty=c.dirty
 E.UF.AuraOwn={GetIconSizes=function()return 31,30,47,46,5 end};sync(p);check(c.dirty==dirty+2,'current scale/own-size arguments update complete descriptors');dirty=c.dirty
 check(e.layoutOptionsByAuraGroup[e.groups.own].layoutIndex==1 and e.layoutOptionsByAuraGroup[e.groups.other].layoutIndex==2,'own/other layout order stays explicit')
 sync(p);check(c.dirty==dirty,'same changed settings remain stable after application')
 -- New aura members are queried and resized even with unchanged group geometry.
 local sizes=c.size;e.frameCount=9;sync(p);check(c.size-sizes==18 and c.dirty==dirty,'new native frames keep receiving existing current sizing without redirtying the layout')
 -- The native public SetUnit/SetEnabled implementations preserve the same
 -- group objects, so target/focus identity transitions need paint, not layout.
 e:SetUnit('focus');e:SetEnabled(false);sync(p);check(c.dirty==dirty,'native unit/enable transitions keep successful geometry while refreshing auras')
 local current=e.SetAuraGroupLayout;e.SetAuraGroupLayout=function(self,...)return current(self,...)end;sync(p)
 check(c.dirty==dirty+2,'public setter replacement/hot load cannot reuse an old method descriptor');dirty=c.dirty
 e.failLayout=true;p._fluxAuraBaseSpacing=4;E.UF.AuraOwn=nil;sync(p);check(c.dirty==dirty,'native failed setter publishes no successful dirty/layout record')
 local failed=c.layout;e.failLayout=false;sync(p);check(c.layout==failed+2 and c.dirty==dirty+2,'same desired geometry retries after native failure');dirty=c.dirty
 -- Fresh absence invalidates that key, independently from its numeric inputs.
 local own=e.groups.own;e.groups.own=nil;sync(p);e.groups.own={};sync(p)
 check(c.dirty==dirty+1,'an observed native group removal/recreation reapplies the new group layout');dirty=c.dirty
 -- Owned AddGroup also invalidates when no absent observation occurred.
 e.groups.own=nil;check(x.add(e,'own','HARMFUL|PLAYER',{layout={elementWidth=1}}),'actual owned AddGroup helper recreates the group');sync(p)
 check(c.dirty==dirty+1,'same-engine/key owned recreation cannot retain its predecessor descriptor');dirty=c.dirty
 local replacement=new();p._fluxEngine=replacement;sync(p);check(c.dirty==dirty+2,'new actual engine always receives its own initial descriptors');dirty=c.dirty
 p._fluxEngine=e;e.privateGroup=true;local oldCount=c.count;sync(p);check(c.count==oldCount,'opaque group existence fails closed before private branching/enumeration');e.privateGroup=false;sync(p)
 check(c.dirty==dirty+2,'public recovery re-applies layouts after opaque group state');dirty=c.dirty
 e.privateCount=true;local oldFrames=c.frames;sync(p);check(c.frames==oldFrames,'opaque frame count cannot enter a numeric loop');e.privateCount=false
 e.privateFrame=true;local oldSize=c.size;sync(p);check(c.size==oldSize,'opaque native frame handle is never indexed');e.privateFrame=false
 E.UF.AuraOwn={GetIconSizes=function()return secret,30,secret,46,5 end}
 local ok,err=pcall(sync,p);check(ok,'opaque dimensions are forwarded only to existing protected native setters without inspecting them')
 if x.cache then check(x.cache[e].own==nil and x.cache[e].other==nil,'opaque geometry never enters a retained successful layout descriptor')end
 E.UF.AuraOwn=nil;sync(p);check(c.dirty>dirty,'public recovery after opaque geometry performs real native layout again')
 print('AURA_GROUP_LAYOUT_WORK|'..client..'|unchangedNativeDirty=60->0|fullAuraRefreshes=40|groupCountReads=60|groupFrameReads=480|buttonSizeWrites=480')
end
print('Unit aura group layout: '..checks..' checks PASS; exact native setters, complete descriptors, unchanged paint/membership cadence, real engine/group lifetime, failure/private/hot-load recovery. Native FPS/taint pending')
