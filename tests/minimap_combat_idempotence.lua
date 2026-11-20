-- Actual minimap enforcement/cleanup. Fresh getters protect corrections; these
-- desktop mutation counts do not establish native FPS, pixels or taint safety.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(arg[1]or'Minimap/FluxMinimap.lua')
local function section(a,b)local i=assert(source:find(a,1,true),a);return source:sub(i,assert(source:find(b,i+#a,true),b)-1)end
local start=source:find('local function MinimapNativeValue',1,true)or assert(source:find('function FluxMinimap:CleanupBlizzardFrames()',1,true))
local cleanup=source:sub(start,assert(source:find('function FluxMinimap:CleanupTimeManager()',start,true))-1)
local enforce=section('function FluxMinimap:EnforcePosition()','function FluxMinimap:PositionIndicators()')
local names=assert(load('return '..assert(cleanup:match('local framesToHide = (%b{})')),'@actual-minimap-cleanup-names','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function Fixture(style,shape)
 local E=setmetatable({},{__index=_G});E._G=E
 local c={writes=0,hide=0,parent=0,anchor=0,scale=0,other=0,indicator=0,hooks=0,reads={}}
 local secret=setmetatable({}, {__eq=function()error('private compared')end,__lt=function()error('private ordered')end,__index=function()error('private indexed')end})
 E.issecretvalue=function(v)return rawequal(v,secret)end
 local m={};local function object(parent)return setmetatable({parent=parent,shown=true,scale=1,points={},hooks={}}, {__index=m})end
 local function write(name)c.writes=c.writes+1;c[name]=c[name]+1 end
 local function value(o,method,result)
  c.reads[method]=(c.reads[method]or 0)+1
  if o.throwGetters then error('native getter unavailable')end
  if o.privateGetters or o['private'..method]then return secret end
  return result
 end
 function m:Hide()write('hide');self.shown=false end
 function m:Show()write('hide');local changed=not self.shown;self.shown=true;if changed and self.hooks.OnShow then self.hooks.OnShow(self)end end
 function m:IsShown()return value(self,'IsShown',self.shown)end
 function m:GetParent()return value(self,'GetParent',self.parent)end
 function m:SetParent(p)write('parent');self.parent=p end
 function m:ClearAllPoints()write('anchor');self.points={}end
 function m:SetPoint(...)write('anchor');self.points={{...}}end
 function m:GetNumPoints()return value(self,'GetNumPoints',#self.points)end
 function m:GetPoint(i)
  local p=self.points[i]or{}
  local point=value(self,'GetPoint',p[1]);if rawequal(point,secret)then return secret end
  return point,p[2],p[3],p[4],p[5]
 end
 function m:GetScale()return value(self,'GetScale',self.scale)end
 function m:SetScale(s)write('scale');self.scale=s end
 function m:SetMovable()write('other')end
 function m:EnableMouse()write('other')end
 function m:HookScript(event,fn)c.hooks=c.hooks+1;self.hooks[event]=fn end
 E.UIParent=object();E.FluxMinimapHiddenFrame=object(E.UIParent);E.FluxMinimap={PositionIndicators=function()c.indicator=c.indicator+1 end}
 E.Minimap=object(E.UIParent);E.MinimapCluster=object(E.UIParent)
 for _,name in ipairs(names)do if shape~='retail'or name~='MinimapZoomIn'and name~='MinimapZoomOut'then E[name]=object(E.UIParent)end end
 if shape~='classic'then E.Minimap.ZoomIn=shape=='alias'and E.MinimapZoomIn or object(E.Minimap);E.Minimap.ZoomOut=shape=='alias'and E.MinimapZoomOut or object(E.Minimap)end
 E.InCombatLockdown=function()return E.locked end;E.embeddedState={isEmbedded=false};E.CONFIG={Position={'TOPRIGHT',E.UIParent,'TOPRIGHT',-25,-25},Scale=1}
 E.FluxBorder={CanUseAtlases=function()return style==2 end}
 E.FluxMinimapButtons={GetMinimapOffset=function()return E.offset or 0 end}
 assert(load(cleanup..enforce,'@actual-minimap-transition-layout','t',E))()
 local function run()E.FluxMinimap:EnforcePosition();E.FluxMinimap:CleanupBlizzardFrames()end
 local function reset()for k in pairs(c)do c[k]=type(c[k])=='table'and{}or 0 end end
 run();reset()
 return E,c,object,run,reset,secret
end
for _,style in ipairs{1,2}do for _,shape in ipairs{'classic','retail','alias'}do
 local E,c,new,run,reset,secret=Fixture(style,shape)
 for _=1,100 do run()end
 check(c.hide==0 and c.parent==0 and c.anchor==0 and c.scale==0,'unchanged native minimap/decoration states skip only redundant setters')
 check(c.other==300 and c.indicator==100 and c.hooks==0,'movable/mouse/indicator cadence and one-time native hooks remain unchanged')
 check(c.reads.GetNumPoints==100 and c.reads.GetPoint==100 and c.reads.GetScale==100,'actual native anchor/scale getters run freshly every pass')
 local top=style==2 and-20 or-22
 check(E.Minimap.points[1][1]=='TOPRIGHT'and E.Minimap.points[1][5]==top,'style-dependent original minimap placement remains exact')
 -- Change native state without any addon event/dirty signal or stale memo.
 E.Minimap.parent=new();E.Minimap.scale=.5;E.Minimap.points={{'CENTER',E.UIParent,'CENTER',12,12}};E.Minimap.shown=false;E.MinimapCluster.shown=true
 E[names[1]].shown=true;E[names[1]].parent=E.UIParent;reset();run()
 check(E.Minimap.parent==E.UIParent and E.Minimap.scale==1 and E.Minimap.points[1][1]=='TOPRIGHT'and E.Minimap.shown and not E.MinimapCluster.shown,'fresh actual geometry/visibility/parent correction survives an unsignaled native change')
 check(not E[names[1]].shown and E[names[1]].parent==E.FluxMinimapHiddenFrame,'fresh native decoration change gets hidden/reparented again')
 E.offset=-41.5;run();check(E.Minimap.points[1][4]==-41.5,'current side-button offset moves the minimap immediately')
 E.CONFIG.Scale=.85;run();check(E.Minimap.scale==.85,'current requested scale change is applied')
 E.Minimap.points[2]={'BOTTOM',E.UIParent,'BOTTOM',0,1};run();check(#E.Minimap.points==1,'additional native points are removed before restoring the one desired anchor')
 -- Replacement global/native child receives original ownership and hook setup.
 local old=E[names[2]];E[names[2]]=new(E.UIParent);run()
 check(E[names[2]]~=old and not E[names[2]].shown and E[names[2]].parent==E.FluxMinimapHiddenFrame and E[names[2]].hooks.OnShow,'late replacement decoration is corrected and hooked rather than skipped by a name cache')
 E[names[2]]:Show();check(not E[names[2]].shown,'original native OnShow suppression remains immediate')
 if E.Minimap.ZoomIn then E.Minimap.ZoomIn=new(E.Minimap);run();check(not E.Minimap.ZoomIn.shown and E.Minimap.ZoomIn.parent==E.FluxMinimapHiddenFrame,'late actual retail zoom child is corrected')end
 -- Each unavailable/private getter uses the original native setter path.
 E.Minimap.privateGetters=true;reset();check(pcall(run),'opaque native getters are never compared or indexed')
 check(c.anchor==2 and c.scale==1 and c.parent==1 and c.hide>=1,'opaque current values cannot produce a false unchanged fast path')
 E.Minimap.privateGetters=nil
 for _,method in ipairs{'GetNumPoints','GetPoint','GetScale','GetParent','IsShown'}do
  local prior=E.Minimap[method];E.Minimap[method]=false;reset();check(pcall(run),'missing optional getter preserves existing setter behavior')
  local needed=method=='GetScale'and c.scale or method=='GetParent'and c.parent or method=='IsShown'and c.hide or c.anchor
  check(needed>0,'missing current-state API cannot hide required original setter');E.Minimap[method]=prior
 end
 E.Minimap.throwGetters=true;reset();check(pcall(run)and c.anchor==2 and c.scale==1 and c.parent==1,'native getter errors conservatively preserve original setter path');E.Minimap.throwGetters=nil
 reset();E.locked=true;E.FluxMinimap:EnforcePosition();check(c.writes==0 and c.indicator==0,'protected minimap enforcement remains blocked in combat')
 E.locked=false;E.embeddedState.isEmbedded=true;E.FluxMinimap:EnforcePosition();check(c.writes==0 and c.indicator==0,'embedded minimap retains its independent geometry and cadence')
 E.embeddedState.isEmbedded=false;E.FluxMinimap:EnforcePosition();check(c.indicator==1,'normal placement resumes through the original method after embedding ends')
 print('MINIMAP_NATIVE_STATE_WORK|'..style..'|'..shape..'|100warmPasses|guardedWrites=0|movableMouseCalls=300|indicatorCalls=100')
end end
print('Minimap combat idempotence: '..checks..' checks PASS; fresh native geometry/parent/scale/visibility, private/missing/error recovery, late frames, style/side offsets and original combat/embed/indicator policy. Native FPS/pixels/taint pending')
