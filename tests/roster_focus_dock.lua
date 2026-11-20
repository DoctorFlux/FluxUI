-- Actual roster/layout/focus functions; native header and downstream bodies
-- are modeled sinks. These work counts do not certify native latency or taint.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function part(s,a,b)local x=assert(s:find(a,1,true));return s:sub(x,assert(s:find(b,x+#a,true))-1)end
local text=read('tests/raid_header_precreation.lua')
text=text:sub(1,assert(text:find('for _, client in ipairs({ "retail"',1,true))-1)
text=text:gsub('local sourceRoot = arg%[1%] or "."','local sourceRoot = "."',1)
text=text:gsub('function methods:CreateFontString%(%) return frame%(nil, self%) end','function methods:CreateFontString()local f=frame(nil,self);f.Show=function(s)s.shown=true end;f.Hide=function(s)s.shown=false end;return f end',1)
local nativeLoadfile=loadfile
if arg[1]then loadfile=function(path,mode,env)if path=='./RaidFrame/FluxRaidLayout.lua'then path=arg[1]end;return nativeLoadfile(path,mode,env)end end
local fixture=assert(load(text..'\nreturn fixture','@actual-roster-header-model','t',_G))()
local focusSource=read(arg[2]or'UnitFrames/FluxUnitFrames_Focus.lua')
local focus=part(focusSource,focusSource:find('local function FocusRosterNative',1,true)and'local function FocusRosterNative'or'function FluxUIPositionFocusFrameDefault(', 'local function InitializeFocusFrame()')
local aura=part(read('UnitFrames/FluxUnitFrames_Auras.lua'),'function _G.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack()','-- One HARMFUL|PLAYER scan')
local function boot(client,raid)
 local e,s=fixture(client,raid,true,true,false,true);local c={};local measuring=false
 local function inc(k)if measuring then c[k]=(c[k]or 0)+1 end end
 local method=getmetatable(e.UIParent).__index
 function method:GetEffectiveScale()return self.scale or 1 end
 function method:GetScale()return self.scale or 1 end
 function method:GetWidth()return self.width or 72 end;function method:GetHeight()return self.height or 43 end
 function method:GetNumPoints()return self.point and 1 or 0 end;function method:GetPoint()return table.unpack(self.point or{})end
 function method:SetFrameStrata(v)self.strata=v end;function method:GetFrameStrata()return self.strata or'MEDIUM'end
 function method:SetFrameLevel(v)self.level=v end;function method:GetFrameLevel()return self.level or 0 end
 local f=e.CreateFrame('Frame','FluxUnitFrame_focus',e.UIParent);f.unit='focus';f.width,f.height=119,85;f._fluxLayoutWidth,f._fluxLayoutHeight=119,85
 function f:UpdatePartition()inc('focus.partition')end;function f:UpdateOuterBorder()inc('focus.outer')end
 function f:GetWidth()return self.width end;function f:GetHeight()return self.height end
 local uf={UpdateAuraPosition=function()inc('focus.aura')end}
 local ns={FocusFrame=f};e.ns=ns;e.UF=uf
 local placement=2;e.FluxUnitFrames_GetPlayerTargetPlacement=function()return placement end
 assert(load(aura..focus,'@actual-roster-focus-bridge','t',e))()
 local methods={'SetPoint','ClearAllPoints','SetSize','SetWidth','SetHeight','SetFrameStrata','SetFrameLevel','Show','Hide','SetAttribute','SetFrameRef'}
 for _,key in ipairs(methods)do local old=method[key];if old then method[key]=function(self,...)inc((self==f and'focus.'or self==e.FluxRaidContainer and'container.'or'other.')..key);return old(self,...)end end end
 local default=e.FluxUIPositionFocusFrameDefault;e.FluxUIPositionFocusFrameDefault=function(...)inc('focus.default');return default(...)end
 local callback=e.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack;e.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack=function()inc('focus.auraEntry');return callback()end
 local function drain()for _=1,15 do if #s.timers==0 then return end;s:flush()end;error('unbounded roster timer chain')end
 s:registerEvents();s:configure();drain()
 local function event()e.FluxRaid_OnEvent(s.eventFrame,'GROUP_ROSTER_UPDATE')end
 local function phase(label,fn)
  c={};measuring=true;local oldAlloc=s.children;fn();drain();measuring=false;c.allocations=s.children-oldAlloc
  local pose={f.width,f.height,f.scale or 1,e.FluxRaidContainer.width or 0,e.FluxRaidContainer.height or 0,e.FluxRaidContainer.strata or'MEDIUM',e.FluxRaidContainer.level or 0}
  for _,object in ipairs{f,e.FluxRaidContainer}do for _,v in ipairs(object.point or{})do if type(v)=='table'then pose[#pose+1]=v.GetName and v:GetName()or'unnamed'else pose[#pose+1]=v end end end
  for i,v in ipairs(pose)do if type(v)=='number'then pose[i]=string.format('%.9g',v)end end;c.pose=table.concat(pose,',')
  local row={'ROSTER_FOCUS',client,raid and'raid'or'party',label};local keys={};for k in pairs(c)do keys[#keys+1]=k end;table.sort(keys);for _,k in ipairs(keys)do row[#row+1]=k..'='..c[k]end;
 end
 return {e=e,s=s,f=f,ns=ns,event=event,drain=drain,phase=phase,counts=function()return c end,setPlacement=function(v)placement=v end}
end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local function calls(t,key)return t.counts()[key]or 0 end
local function measured(t,label,fn)t.phase(label,fn)end
local function event(t,label)measured(t,label,function()t.event()end)end
for _,client in ipairs{'forever','live'}do for _,raid in ipairs{false,true}do
 local t=boot(client,raid);local e,s,f=t.e,t.s,t.f
 event(t,'stable');check(calls(t,'focus.partition')==0 and calls(t,'focus.outer')==0 and calls(t,'focus.auraEntry')==1,'stable prepared roster keeps notifications without duplicate full layout')
 check(calls(t,'container.SetPoint')==0 and calls(t,'container.SetHeight')==0,'fresh matching container setters are skipped')
 f._fluxRaidDockPrepared=nil;event(t,'first');check(calls(t,'focus.partition')==1 and calls(t,'focus.outer')==1,'first roster-only position still performs full initialization')
 measured(t,'direct',function()e.FluxUIPositionFocusFrameDefault()end);check(calls(t,'focus.partition')==1 and calls(t,'focus.outer')==1,'direct/default/settings caller without hint retains full behavior')
 f.width=f.width+5;event(t,'body-width-drift');check(calls(t,'focus.partition')==1,'native width drift cannot skip full layout');f.width=f._fluxLayoutWidth
 f.height=f.height+5;event(t,'body-height-drift');check(calls(t,'focus.partition')==1,'native height drift cannot skip full layout');f.height=f._fluxLayoutHeight
 f.scale=.7;event(t,'scale-change');check(calls(t,'focus.partition')==1,'effective scale change repairs desired focus offsets');event(t,'scale-stable');check(calls(t,'focus.partition')==0,'changed scale settles after one full layout')
 f:ClearAllPoints();f:SetPoint('CENTER',e.UIParent,'CENTER',5,5);event(t,'point-drift');check(calls(t,'focus.partition')==1 and f.point[1]=='BOTTOMRIGHT','native point drift restores original layout path')
 f.needsPartitionRelayout=true;event(t,'pending-partition');check(calls(t,'focus.partition')==1,'pending partition cannot be suppressed');f.needsPartitionRelayout=nil
 f.needsOuterBorderUpdate=true;event(t,'pending-outer');check(calls(t,'focus.outer')==1,'pending outer work cannot be suppressed');f.needsOuterBorderUpdate=nil
 local oldParent=f.parent;f.parent=e.FluxRaidContainer;event(t,'parent-context');check(calls(t,'focus.partition')==1,'different current native parent cannot skip full layout');f.parent=oldParent
 s.raid=not s.raid;event(t,'party-raid-conversion');check(calls(t,'focus.auraEntry')>=1 and e.FluxRaidState.secureConfigured,'conversion keeps prepared headers and focus callback notification')
 e.FluxRaidVisuals.FRAME_HEIGHT=e.FluxRaidVisuals.FRAME_HEIGHT+4;measured(t,'explicit-setting',function()e.FluxRaid_PositionContainer()end)
 check(calls(t,'container.SetHeight')==1 and calls(t,'focus.partition')==1,'explicit raid geometry/settings still repairs and fully refreshes focus')
 measured(t,'repeat-explicit',function()e.FluxRaid_PositionContainer()end);check(calls(t,'focus.partition')==1,'same-geometry explicit calls retain default behavior')
 local previousPartition=f.UpdatePartition;f.UpdatePartition=function(self)previousPartition(self)end
 event(t,'late-layout-method');check(calls(t,'focus.partition')==1,'replacement layout method is initialized before pose reuse')
 local secret=setmetatable({}, {__eq=function()error('opaque pose compared')end,__lt=function()error('opaque pose ordered')end,__sub=function()error('opaque pose arithmetic')end,__tostring=function()error('opaque pose formatted')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 for _,hint in ipairs{false,1,'yes',{},secret}do
  measured(t,'non-roster-hint',function()e.FluxUIPositionFocusFrameDefault(hint)end)
  check(calls(t,'focus.partition')==1,'only literal public true may select roster-only reuse')
 end
 for _,method in ipairs{'GetPoint','GetNumPoints','GetWidth','GetHeight','GetParent'}do
  local old=f[method]
  for _,kind in ipairs{'private','missing','error'}do
   if kind=='private'then f[method]=function()return secret,secret,secret,secret,secret end
   elseif kind=='missing'then f[method]=false else f[method]=function()error('native pose getter unavailable')end end
   event(t,'unknown-'..method..'-'..kind);check(calls(t,'focus.partition')==1,'unknown/private/missing pose requires full path '..method..kind)
   f[method]=old
  end
 end
 local get=f.GetPoint;f.GetPoint=function()return'BOTTOMRIGHT',e.UIParent,'BOTTOMLEFT',1/0,0/0 end
 event(t,'invalid-number');check(calls(t,'focus.partition')==1,'invalid public coordinates cannot match');f.GetPoint=get
 for _,field in ipairs{'_fluxRaidDockPrepared','needsPartitionRelayout','needsOuterBorderUpdate','_fluxLayoutWidth','_fluxLayoutHeight'}do
  local old=f[field];f[field]=secret;event(t,'private-'..field);check(calls(t,'focus.partition')==1,'private preparation metadata cannot bypass layout');f[field]=old
 end
 local before=s.children;measured(t,'combat-roster',function()s.combat=true;for _=1,20 do t.event()end end)
 check(calls(t,'container.SetPoint')==0 and calls(t,'focus.partition')==0 and s.children==before,'combat retains protected queue/capacity policy')
 e.FluxRaidContainer.height=1;measured(t,'combat-direct',function()e.FluxRaid_PositionContainer()end)
 check(calls(t,'container.SetHeight')==0 and calls(t,'focus.partition')==0,'direct combat placement also defers needed geometry repair')
 measured(t,'regen',function()s.combat=false;e.FluxRaid_RunPendingCombatWork()end);check(e.FluxRaidState.secureConfigured,'regen keeps prepared secure state')
 local default=e.FluxUIPositionFocusFrameDefault;local once=true
 e.FluxUIPositionFocusFrameDefault=function(...)
  if once then once=false;t.event()end
  return default(...)
 end
 event(t,'reentrant');check(not once and calls(t,'focus.auraEntry')==2,'one reentrant roster request drains in the existing next batch without lost callbacks')
 e.FluxUIPositionFocusFrameDefault=default
 local previous=t.ns.FocusFrame;local replacement=e.CreateFrame('Frame','ReplacementFocus',e.UIParent)
 replacement.unit='focus';replacement.width,replacement.height=119,85;replacement._fluxLayoutWidth,replacement._fluxLayoutHeight=119,85
 replacement.UpdatePartition=previous.UpdatePartition;replacement.UpdateOuterBorder=previous.UpdateOuterBorder
 t.ns.FocusFrame=replacement;event(t,'replacement');check(calls(t,'focus.partition')==1,'a replacement context performs first layout before reusing its pose')
end end
print('Roster focus dock: '..checks..' checks PASS; first/settings/default/unknown/drift recovery; body/scale/parent/context; combat+reentrant native-header policy; notification retention. Native latency/taint/pixels pending.')
