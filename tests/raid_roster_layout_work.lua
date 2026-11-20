-- Offline actual Layout + secure roster method/snippet + focus callback proof.
-- The fixture models native slot rebinding; it does not certify native timing/taint.
-- Partial native false can leave different hidden poses after delegation, while
-- fallback hide/Blizzard restore/error/retry and successful recovery are retained.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function part(s,a,b)local x=assert(s:find(a,1,true));return s:sub(x,assert(s:find(b,x+#a,true))-1)end
-- Optional arg1 is an alternate RaidLayout source, including an archived
-- pre-fix source for the saved-write negative control. The prior staging block
-- is embedded below so normal repository tests need no external archive.
local layoutSource=read(arg[1]or'RaidFrame/FluxRaidLayout.lua')
local priorPositions=[==[    if mtmaHeader then
        mtmaHeader:ClearAllPoints()
        if mtShown and layout.x_lo and layout.k >= 1 then
            mtmaHeader:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", layout.xMT, yAlignMT)
        else
            mtmaHeader:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 0, 0)
        end
    end
    for g = 1, GROUP_COUNT do
        local header = State.raidHeaders[g]
        if header then
            header:ClearAllPoints()
            local gx = layout.groupX and layout.groupX[g]
            if (gc[g] or 0) > 0 and gx then
                header:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", gx, 0)
                if header._fluxGroupLabel then header._fluxGroupLabel:Show() end
            else
                header:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", -10000, 0)
                if header._fluxGroupLabel then header._fluxGroupLabel:Hide() end
            end
        end
    end
    containerFrame:SetWidth(layout.totalSlots * colStep)
    if State.secureRosterPrepared and FluxRaidSecure then
        local ready=FluxRaidSecure.RefreshRosterLayout(containerFrame,State.raidHeaders,
            FluxRaid_DisplayMainTankAndAssistCVarEnabled() and State.mtmaHeader or nil,
            {colStep=colStep,columnHeight=ColumnHeight(),mtChildStep=MTMAChildStep(),mtExtraY=MTMA_EXTRA_Y_FOR_FOUR_PLUS})
        if not ready then
            State.secureRosterError="Secure roster layout is unavailable"
            return false
        end
    end
]==]
local function priorLayout(source)
 local a=source:find('    local prepared = State.secureRosterPrepared and FluxRaidSecure',assert(source:find('LayoutHeaders = function(',1,true)),true)
 if not a then return source end
 local b=assert(source:find('    if mtShown and mtmaHeader then\n        C_Timer.After(0, ApplyMTMAChatOverlapLift)',a,true))
 local readLegacy=source:find('local function ReadLegacyHeaderLayout(',1,true)
 return source:sub(1,a-1)..(readLegacy and '    local gc, layout, yAlignMT = ReadLegacyHeaderLayout(colStep, mtShown)\n' or '')
     ..priorPositions..source:sub(b)
end
local secureSource=read('RaidFrame/FluxRaidSecure.lua')
local snippet=part(secureSource,'local ROSTER_LAYOUT = [=[','-- Native state-visibility'):match('%[=%[(.-)%]=%]')
local refresh=part(secureSource,'function Secure.RefreshRosterLayout(', '_G.FluxRaidSecure = Secure')
local sync=part(read('RaidFrame/FluxRaidUnit.lua'),'function FluxRaid_SyncHeaderChildUnits(', 'function FluxRaid_ApplyChromeToChildren(')
local bootText=read('tests/roster_focus_dock.lua')
bootText=bootText:sub(1,assert(bootText:find('local checks=0;',1,true))-1)
bootText=bootText:gsub('s:registerEvents%(%)%;s:configure%(%)%;drain%(%)','InstallSecure(e,s,inc);s:registerEvents();s:configure();drain()',1)
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local rows={};local function log(s)rows[#rows+1]=s;print(s)end
local function install(e,s,inc)
 local methods=getmetatable(e.UIParent).__index
 local hub=e.CreateFrame('Frame','ProofSecureRosterHub',e.UIParent)
 local setPoint,setAttribute=methods.SetPoint,methods.SetAttribute
 function methods:SetPoint(point,parent,...)
  if parent=='$parent'then parent=self.parent end
  return setPoint(self,point,parent,...)
 end
 function methods:SetAttribute(key,value)
  if key:sub(1,9)=='frameref-'then self.references[key:sub(10)]=value end
  return setAttribute(self,key,value)
 end
 function methods:GetFrameRef(k)return self.references and self.references[k]end
 local function applyNativeUnits()
  local state=e.FluxRaidState
  local grouped={};for i=1,8 do grouped[i]={}end
  local tanks={}
  if s.raid then
   for i,row in ipairs(s.rows or{{group=1,mt=true}})do
    grouped[row.group][#grouped[row.group]+1]='raid'..i
    if row.mt then tanks[#tanks+1]='raid'..i end
   end
  elseif s.group then
   grouped[1][1]='player';for i=1,s.roster-1 do grouped[1][#grouped[1]+1]='party'..i end
  end
  for group,h in ipairs(state.raidHeaders)do
   h.shown=s.raid or s.group and group==1
   for i=1,5 do
    local child=h.attributes['child'..i]
    if child then
     setmetatable(child,{__index=methods});child.attributes=child.attributes or{};child.references=child.references or{}
     child.attributes.unit=grouped[group][i];child.shown=child.attributes.unit~=nil;child.parent=h
     h.references['child'..i]=child
    end
   end
  end
  local h=state.mtmaHeader
  if h then
   h.shown=s.raid and s.mtEnabled~=false
   for i=1,40 do
    local child=h.attributes['child'..i]
    if child then
     setmetatable(child,{__index=methods});child.attributes=child.attributes or{};child.references=child.references or{}
     child.attributes.unit=tanks[i];child.shown=child.attributes.unit~=nil;child.parent=h
     h.references['child'..i]=child
    end
   end
  end
 end
 local function execute(self,body)
  inc('secure.Execute');s.secureLayoutCalls=s.secureLayoutCalls+1
  if s.layoutError then error('controlled secure execute error')end
  if s.partialFailure or s.partialError then
   local h=self:GetFrameRef('roster-group8')
   h:ClearAllPoints();h:SetPoint('TOPLEFT',h.parent,'TOPLEFT',999,666)
   self:GetFrameRef('roster-container'):SetWidth(999)
   if s.partialError then error('controlled partial secure execute error')end
   return false
  end
  if not s.secureLayoutSupported then return false end
  applyNativeUnits()
  local se=setmetatable({self=self,newtable=function()return{}end},{__index=e})
  return pcall(assert(load(body,'@actual-ROSTER_LAYOUT-invocation','t',se)))
 end
 function methods:Execute(body)return execute(self,body)end
 function methods:RunAttribute(k)
  inc('secure.ROSTER_LAYOUT')
  local se=setmetatable({self=self,newtable=function()return{}end},{__index=e})
  return assert(load(assert(self.attributes[k]),'@actual-ROSTER_LAYOUT','t',se))()
 end
 local se=setmetatable({Secure=e.FluxRaidSecure,InCombat=e.InCombatLockdown,ROSTER_LAYOUT=snippet,
  EnsureHub=function()return hub,{ExecutePaging=execute}end},{__index=e})
 assert(load(refresh,'@actual-Secure.RefreshRosterLayout','t',se))()
 e.FluxRaid_DisplayMainTankAndAssistCVarEnabled=function()return s.mtEnabled~=false end
 e.GetRaidRosterInfo=function(index)
  inc('legacy.rosterRead')
  local row=(s.rows or{{group=1,mt=true}})[index];if not row then return end
  return 'Member'..index,0,row.group,80,'Warrior','WARRIOR',nil,nil,nil,row.mt and'MAINTANK'or nil
 end
 e.UnitExists=function(unit)
  local i=tonumber(unit:match('%d+'));return s.raid and(s.rows or{{group=1,mt=true}})[i]~=nil or not s.raid and s.group and i and i<s.roster or unit=='player'
 end
 local function each(fn,onlyHeader)
  if onlyHeader then
   for i=1,5 do local child=onlyHeader.attributes['child'..i];if child then fn(child)end end
   return
  end
  for _,h in ipairs(e.FluxRaidState.raidHeaders)do for i=1,5 do local child=h.attributes['child'..i];if child then fn(child)end end end
  local h=e.FluxRaidState.mtmaHeader;if h then for i=1,40 do local child=h.attributes['child'..i];if child then fn(child)end end end
 end
 local ue=setmetatable({FluxRaid_ForEachHeaderChild=each,
  MarkPaint=function(_,kind)check(kind=='full','sync retains full paint mode');inc('unit.MarkPaint.full')end},{__index=e})
 e.FluxRaid_BindUnit=function(child,unit)child.unit=unit;inc('unit.BindUnit')end
 e.FluxRaid_RequestJoinedBorderRefresh=function()inc('unit.JoinedRequest')end
 assert(load(sync,'@actual-SyncHeaderChildUnits','t',ue))()
 e.FluxRaid_SyncHeaderChildUnits=ue.FluxRaid_SyncHeaderChildUnits
 e.FluxRaid_RefreshMTMATargetAttachments=function()inc('unit.MTMAAttachments')end
 s.nativeRoster=applyNativeUnits
end
local function boot(source,client,raid)
 local nativeLoadfile=loadfile
 local function sourceLoadfile(path,mode,env)
  if path=='@roster-layout-under-test'then return load(source,path,mode or't',env)end
  return nativeLoadfile(path,mode,env)
 end
 local function setup(e,s,inc)
  install(e,s,inc)
  local build=e.FluxRaidCompat.BuildVisibleGroupsReverse
  e.FluxRaidCompat.BuildVisibleGroupsReverse=function(...)inc('legacy.build');return build(...)end
 end
 local outer=setmetatable({arg={[1]='@roster-layout-under-test'},InstallSecure=setup,loadfile=sourceLoadfile},{__index=_G});outer._G=outer
 return assert(load(bootText..'\nreturn boot','@actual-roster-focus-fixture','t',outer))()(client,raid)
end
local function pose(t)
 local e=t.e;local out={}
 local function put(v)if type(v)=='table'then v=v.name or'child'elseif type(v)=='number'then v=string.format('%.12g',v)end;out[#out+1]=tostring(v)end
 local function frame(f)
  put(f.name);put(f.shown);put(f.alpha);put(f.width);put(f.height);put(f.scale);put(f.strata);put(f.level)
  for i=1,5 do put(f.point and f.point[i])end
  if f._fluxGroupLabel then put(f._fluxGroupLabel.shown)end
 end
 frame(e.FluxRaidContainer);frame(t.f)
 for _,h in ipairs(e.FluxRaidState.raidHeaders)do frame(h);for i=1,5 do local child=h.attributes['child'..i];put(child and child.attributes and child.attributes.unit);put(child and child.unit)end end
 frame(e.FluxRaidState.mtmaHeader)
 for i=1,40 do local child=e.FluxRaidState.mtmaHeader.attributes['child'..i];put(child and child.attributes and child.attributes.unit);put(child and child.unit)end
 return table.concat(out,'|')
end
local function counts(t,k)return t.counts()[k]or 0 end
local function findFunction(fn,wanted,seen)
 seen=seen or{};if seen[fn]then return end;seen[fn]=true
 for i=1,100 do
  local name,value=debug.getupvalue(fn,i);if not name then return end
  if name==wanted then return value end
  if type(value)=='function'then local result=findFunction(value,wanted,seen);if result then return result end end
 end
end
local baseline=arg[2] and read(arg[2]) or priorLayout(layoutSource)
local candidate=layoutSource
local skipsLegacy=candidate:find('LayoutHeaders = function(labelsFollow',1,true)~=nil
local samplesRoster=candidate:find('local function ReadLegacyRaidRoster(',1,true)~=nil
for _,client in ipairs{'forever','live'}do
 for _,initialRaid in ipairs{false,true}do
  local a,b=boot(baseline,client,initialRaid),boot(candidate,client,initialRaid)
  local function pair(label,fn,options)
   options=options or{}
   a.phase(label,function()fn(a)end);b.phase(label,function()fn(b)end)
   if not options.noPose then check(pose(a)==pose(b),label..' final native pose/slot equality')end
   for _,k in ipairs{'secure.Execute','secure.ROSTER_LAYOUT','unit.MarkPaint.full','unit.BindUnit','unit.JoinedRequest','unit.MTMAAttachments','focus.default','focus.partition','focus.outer','focus.auraEntry','allocations'}do
    check(counts(a,k)==counts(b,k),label..' preserved '..k)
   end
   if options.saved then
    check(counts(a,'other.ClearAllPoints')>=counts(b,'other.ClearAllPoints'),label..' avoids redundant header clears')
    check(counts(a,'other.SetPoint')>=counts(b,'other.SetPoint'),label..' avoids redundant header points')
    check(counts(a,'container.SetWidth')>=counts(b,'container.SetWidth'),label..' avoids redundant width changes')
   end
   if options.log then log(string.format('WORK %s %s %s clear=%d/%d points=%d/%d width=%d/%d execute=%d/%d fullPaint=%d/%d bind=%d/%d legacyLayouts=%d/%d rosterReads=%d/%d',client,initialRaid and'raid'or'party',label,counts(a,'other.ClearAllPoints'),counts(b,'other.ClearAllPoints'),counts(a,'other.SetPoint'),counts(b,'other.SetPoint'),counts(a,'container.SetWidth'),counts(b,'container.SetWidth'),counts(a,'secure.Execute'),counts(b,'secure.Execute'),counts(a,'unit.MarkPaint.full'),counts(b,'unit.MarkPaint.full'),counts(a,'unit.BindUnit'),counts(b,'unit.BindUnit'),counts(a,'legacy.build'),counts(b,'legacy.build'),counts(a,'legacy.rosterRead'),counts(b,'legacy.rosterRead')))end
   if skipsLegacy and options.noLegacy then
    check(counts(a,'legacy.build')>counts(b,'legacy.build'),label..' avoids the duplicate layout for prepared secure headers')
    check(counts(b,'legacy.rosterRead')==0,label..' performs no legacy roster reads')
   end
  end
  pair('unchanged-prepared',function(t)t.event()end,{saved=true,log=true,noLegacy=initialRaid})
  check(counts(b,'other.ClearAllPoints')==0 and counts(b,'other.SetPoint')==0
      and counts(b,'container.SetWidth')==0,'secure unchanged roster performs no geometry writes')
  local states={
   {mode='solo'},{mode='party',n=2},{mode='party',n=5},
   {mode='raid',rows={{group=8,mt=true},{group=2},{group=8}}},
   {mode='raid',rows={{group=3},{group=1,mt=true},{group=3,mt=true},{group=7}}},
   {mode='raid',rows={}},{mode='solo'},
  }
  for i,state in ipairs(states)do
   pair('transition'..i..state.mode,function(t)
    t.s.raid=state.mode=='raid';t.s.group=state.mode~='solo';t.s.roster=state.n or 1;t.s.rows=state.rows
    t.s.nativeRoster();t.event()
   end,{saved=true,log=true,noLegacy=true})
  end
  pair('mtma-four-plus',function(t)
   t.s.raid,t.s.group=true,true;t.s.rows={};for i=1,12 do t.s.rows[i]={group=math.ceil(i/5),mt=true}end
   t.s.nativeRoster();t.event()
  end,{saved=true,log=true,noLegacy=true})
  pair('mtma-chat-lift',function(t)
   t.e.ChatFrame1=t.e.CreateFrame('Frame','ChatFrame1',t.e.UIParent);t.e.ChatFrame1.shown=true;t.event()
  end,{saved=true,log=true})
  check(a.e.FluxRaidState.mtmaHeader.point[5]>60,'actual deferred MTMA overlap callback still lifts header')
  pair('unprepared-legacy',function(t)
   t.e.FluxRaidState.secureRosterPrepared=false
   assert(findFunction(t.e.FluxRaid_OnRosterOrPartyChanged,'LayoutHeaders'))()
  end)
  check(counts(b,'secure.Execute')==0 and counts(b,'other.ClearAllPoints')<=9
      ,'unprepared path preserves matched legacy positions without redundant passes')
  pair('legacy-roster-with-mt',function(t)
   t.s.rows={}
   for i=1,40 do t.s.rows[i]={group=math.ceil(i/5),mt=i>36} end
   t.s.nativeRoster()
   assert(findFunction(t.e.FluxRaid_OnRosterOrPartyChanged,'RefreshGroupVisibility'))()
  end,{saved=true,log=true})
  if samplesRoster then
   check(counts(b,'legacy.rosterRead')==40,'legacy roster samples each slot once for columns and MT visibility')
   check(b.e.FluxRaidState.mtmaHeader:IsShown() and b.e.FluxRaidState.mtmaHeader.point[5]>=60,
       'four tanks still use their inset column')
  end
  pair('legacy-roster-without-mt',function(t)
   t.s.mtEnabled=false
   assert(findFunction(t.e.FluxRaid_OnRosterOrPartyChanged,'RefreshGroupVisibility'))()
  end,{saved=true,log=true})
  if samplesRoster then
   check(counts(b,'legacy.rosterRead')==40 and not b.e.FluxRaidState.mtmaHeader:IsShown(),
       'hidden MT column uses only the ordinary roster sample')
  end
  for _,t in ipairs{a,b}do t.s.mtEnabled=true;t.e.FluxRaidState.secureRosterPrepared=true end
  pair('prepared-after-legacy',function(t)t.event()end,{saved=true})
  pair('mtma-disabled-while-shown',function(t)t.s.mtEnabled=false;t.event()end,{saved=true,log=true})
  if skipsLegacy then check(counts(b,'legacy.rosterRead')>0,'still-shown legacy MT column keeps Lua placement') end
  for _,t in ipairs{a,b}do t.s.mtEnabled=true;t.s.nativeRoster() end
  pair('mtma-disabled',function(t)t.s.mtEnabled=false;t.s.nativeRoster();t.event()end,{saved=true})
  pair('geometry-setting',function(t)t.e.FluxRaidVisuals.FRAME_WIDTH=83;t.e.FluxRaidVisuals.FRAME_HEIGHT=51;t.event()end,{saved=true})
  pair('drift-repair',function(t)
   for _,h in ipairs(t.e.FluxRaidState.raidHeaders)do h.point={'CENTER',t.e.UIParent,'CENTER',33,44}end
   t.e.FluxRaidContainer.width=1;t.event()
  end,{saved=true})
  pair('combat-burst',function(t)t.s.combat=true;for _=1,20 do t.event()end end)
  check(counts(b,'secure.Execute')==0 and counts(b,'other.SetPoint')==0,'combat has no new ordinary geometry writes')
  pair('combat-release',function(t)t.s.combat=false;t.e.FluxRaid_RunPendingCombatWork()end,{saved=true})
  pair('reentrant',function(t)
   local previous=t.e.FluxUIPositionFocusFrameDefault;local once=true
   t.e.FluxUIPositionFocusFrameDefault=function(...)if once then once=false;t.event()end;return previous(...)end
   t.event();t.e._restoreFocus=previous
  end)
  for _,t in ipairs{a,b}do t.e.FluxUIPositionFocusFrameDefault=t.e._restoreFocus end
  -- Native/private getters remain unknown; no current pose/value cache is added.
  pair('private-pose-getter',function(t)
   local secret={};t.e.issecretvalue=function(v)return rawequal(v,secret)end
   t.f.GetPoint=function()return secret,secret,secret,secret,secret end;t.event()
  end,{saved=true})
  pair('secure-failure',function(t)t.s.secureLayoutSupported=false;t.event()end,{noPose=true})
  check(not a.e.FluxRaidState.secureConfigured and not b.e.FluxRaidState.secureConfigured,'both retain native fallback after secure failure')
  check(not a.s.nativeHidden and not b.s.nativeHidden,'both restore native grid on failure')
  pair('failure-recovery',function(t)t.s.secureLayoutSupported=true;t.s.configure();t.drain()end)
  pair('partial-native-failure',function(t)t.s.partialFailure=true;t.event()end,{noPose=true})
  check(not a.e.FluxRaidState.secureConfigured and not b.e.FluxRaidState.secureConfigured,'partial native false restores both fallback readiness states')
  check(not a.s.nativeHidden and not b.s.nativeHidden,'partial native false restores both native grids')
  if not arg[2] then
   check(pose(a)~=pose(b),'partial returned failure hidden poses differ honestly after legacy recovery staging')
   log('QUALIFIER '..client..' partial-false hidden poses differ; both hide/Blizzard-restore/retry retained')
  end
  pair('partial-failure-recovery',function(t)t.s.partialFailure=false;t.s.configure();t.drain()end)
  -- A thrown execute has the same externally visible failure and recovery path.
  for _,t in ipairs{a,b}do
   t.s.layoutError=true;local ok,err=pcall(function()t.event();t.drain()end)
   check(not ok and tostring(err):find('controlled secure execute error',1,true),'raw native execution failure propagates unchanged')
   t.s.layoutError=false;t.s.configure();t.drain()
  end
  check(pose(a)==pose(b),'recovered native failure final pose parity')
  for _,t in ipairs{a,b}do
   t.s.partialError=true;local ok,err=pcall(function()t.event();t.drain()end)
   check(not ok and tostring(err):find('controlled partial secure execute error',1,true),'partial native throw propagates in both')
   t.s.partialError=false;t.s.configure();t.drain()
  end
  check(pose(a)==pose(b),'partial native throw recovery final pose parity')
 end
end
if samplesRoster then
    local t=boot(candidate,"forever",true)
    local hidden=setmetatable({},{
        __eq=function() error("private equality") end,
        __lt=function() error("private comparison") end,
    })
    t.e.issecretvalue=function(value) return rawequal(value,hidden) end
    local rows={
        {"Member",0,8,80,nil,"PRIEST",nil,nil,nil,nil,nil,"MAINASSIST"},
        {"",0,2,0,nil,"WARRIOR",nil,nil,nil,"MAINTANK"},
        {"",0,1,0,nil,nil,nil,nil,nil,"MAINTANK"},
        {"Pending",0,4,80,nil,"PRIEST",nil,nil,nil,"MAINASSIST"},
        {"Unknown group",0,hidden,80,nil,"PRIEST"},
        {"Unknown role",0,6,80,nil,"PRIEST",nil,nil,nil,hidden},
        {"",0,7,0,nil,"",nil,nil,nil,"MAINTANK"},
    }
    t.e.GetRaidRosterInfo=function(i) return table.unpack(rows[i] or {},1,12) end
    t.e.UnitInRaid=function() return 3 end
    t.e.UnitExists=function(unit)
        check(unit~="raid3","the known player slot needs no existence getter")
        if unit=="raid4" then return hidden end
        return true
    end
    t.e.GetPartyAssignment=function() return hidden end
    check(t.e.FluxRaid_GetMTMARosterCount()==3,
        "tank and assist fallback uses readable roles, class or known player identity")
    t.e.FluxRaidState.secureRosterPrepared=false
    assert(findFunction(t.e.FluxRaid_OnRosterOrPartyChanged,"RefreshGroupVisibility"))()
    t.drain()
    local headers=t.e.FluxRaidState.raidHeaders
    check(headers[4].point[4]>=0,"opaque UnitExists still admits a compatibility roster column")
    check(headers[5].point[4]==-10000 and headers[7].point[4]==-10000,
        "an opaque subgroup or empty roster row never creates a guessed column")
    t.s.raid=false
    check(t.e.FluxRaid_GetMTMARosterCount()==0,"party and solo need no raid roster count")
end
print('Party roster prepared delegation: '..checks..' checks PASS. Actual Layout/RefreshRosterLayout/ROSTER_LAYOUT/Sync functions; modeled native rebinding and protected widgets. Native latency/taint pending.')
