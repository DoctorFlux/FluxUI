-- Actual production portrait/camera/partition/Pet callbacks, modeled native endpoints.
-- Run from repository root. Native renderer, security and client acceptance remain separate.
local sourceFile=debug.getinfo(1,'S').source:sub(2)
local folder=(sourceFile:match('^(.*)[/\\]')or'.')..'/'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function loadenv(body,label,env)
 if _VERSION=='Lua 5.1'then local fn,err=loadstring(body,label);if fn then setfenv(fn,env)end;return fn,err end
 return load(body,label,'t',env)
end
local model=assert(loadenv(read(folder..'support/unit_portrait_callback_model.txt'),'@portrait-callback-model',_G))()
local before=assert(loadenv(read(folder..'support/unit_portrait_callback_before.txt'),'@portrait-before-bodies',_G))()
local current=read(arg and arg[1]=='--source'and assert(arg[2])or folder..'../UnitFrames/FluxUnitFrames_Shared.lua')
local petSource=read(folder..'../UnitFrames/FluxUnitFrames_Pet.lua')
local function restore(source,newStart,oldStart,finish,body)
 local a=assert(source:find(newStart,1,true)or source:find(oldStart,1,true),newStart)
 local b=assert(source:find(finish,a,true),finish)
 return source:sub(1,a-1)..body..source:sub(b)
end
local old=restore(current,'local ApplyPortraitCamera\n','local function ApplyPortraitCamera(portrait, keepIfClose)','\nlocal function SchedulePortraitCameraRefresh',before.camera)
old=restore(old,'local SetPortraitUnit\n','local function SetPortraitUnit(portrait, unit)','\n-- The right portrait overlaps',before.setUnit)
old=restore(old,'-- Protected portrait paint callback:','function UF.UpdatePortrait(self, unit)','\n--- Resize the PlayerModel',before.paint)
old=restore(old,'-- Protected portrait geometry callback:','function UF.SyncPortraitModelGeometry(self)','\n--- Full portrait refresh after resolution',before.geometry)
local baseline=model.compileSource(old,'retained-original-callbacks',petSource)
local candidate=model.compileSource(current,'current-callbacks',petSource)
local traceRoot=arg and arg[3]
local checks,cases=0,0
local function check(v,m)checks=checks+1;assert(v,m)end
local function count(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
local function write(name,suffix,body)
 if not traceRoot then return end
 local f=assert(io.open(traceRoot..'/'..name..suffix,'wb'));f:write(body);f:close()
end
local specs={
 {name='normal',unit='pet'},
 {name='player',unit='player'},
 {name='target',unit='target'},
 {name='party',unit='party1'},
 {name='flat',kind='2D'},
 {name='empty',kind='empty'},
 {name='flat-no-texture',kind='2D',noFlat=true},
 {name='no-model',missingModel=true},
 {name='legacy-SetUnit',setUnit='twoarg-fail'},
 {name='failed-SetUnit',setUnit='both-fail'},
 {name='false-native-return',setUnit='returns-false'},
 {name='replacement-SetUnit',setUnit='twoarg-swap-fail'},
 {name='SetUnit-lookup-once',lookupFault='SetUnit'},
 {name='SetUnit-lookup-always',lookupFault='SetUnit',lookupAlways=true},
 {name='ClearModel-lookup-error',lookupFault='ClearModel'},
 {name='camera-lookup-error',lookupFault='SetPortraitZoom'},
 {name='ClearModel-error',fail='ClearModel'},
 {name='camera-native-error',fail='SetPortraitZoom'},
 {name='geometry-native-error',fail='SetSize'},
 {name='ClearModel-native-swap',clearSwap=true},
 {name='ClearModel-getter-swap',clearLookupSwap=true},
 {name='geometry-container-swap',geometrySwap=true},
 {name='native-load-callback',syncLoad=true},
 {name='reentrant-paint',reenter=true},
 {name='missing-custom-camera',noCustom=true},
 {name='private-model-id',modelPrivate=true},
 {name='missing-unit',state='exists',value=false},
 {name='private-exists',state='exists',value='private'},
 {name='unavailable-unit',state='visible',value=false},
 {name='disconnected-unit',state='connected',value=false},
 {name='private-visibility',state='visible',value='private'},
 {name='private-connection',state='connected',value='private'},
 {name='non-player-unit',state='isPlayer',value=false},
 {name='hidden-owner',hideOwner=true},
 {name='transparent-owner',alpha=0},
 {name='lockdown-partition',lockdown=true},
 {name='private-dimensions',privateDimensions=true},
 {name='close-camera',closeCamera=true},
}
local function exercise(compiled,spec,branch)
 local cfg={};for k,v in pairs(spec)do cfg[k]=v end;cfg.branch=branch
 local s=model.fixture(compiled,cfg)
 if cfg.state then s[cfg.state]=cfg.value=='private'and s.private or cfg.value end
 if cfg.hideOwner then s.owner:Hide()end
 if cfg.alpha~=nil then s.owner:SetAlpha(cfg.alpha)end
 if cfg.lockdown then s.locked=true end
 if cfg.privateDimensions then s.owner._fluxLayoutHeight=s.private end
 if cfg.closeCamera then s.seedDistance=.9 end
 s:reset()
 local returned={}
 for i=1,3 do
  local values={pcall(s.full,s)}
  returned[#returned+1]=tostring(values[1])..':'..(rawequal(values[2],s.marker)and'opaque'or type(values[2]))
  if values[1]==false and not rawequal(values[2],s.marker)then s.errors[#s.errors+1]=tostring(values[2])end
 end
 -- Exercise finite callbacks, close-camera keep and both direct compatibility
 -- signatures without replacing any production camera/paint owner.
 if s.owner.Portrait then
  s.apply(s.owner.Portrait,true)
  for _=1,3 do if s.pendingTimers>0 then s:drain()end end
 end
 if cfg.lockdown then
  s.locked=false
  for key,fn in pairs(s.deferred or{})do s.deferred[key]=nil;fn()end
 end
 local snapshot=s:snapshot()
 return s,table.concat(returned,','),snapshot
end
for _,branch in ipairs{'live','forever','classic'}do
 for _,spec in ipairs(specs)do
  cases=cases+1
  local a,ar,as=exercise(baseline,spec,branch)
  local b,br,bs=exercise(candidate,spec,branch)
  local name=branch..'-'..spec.name
  write(name,'.baseline.trace',table.concat(a.trace,'\n'))
  write(name,'.candidate.trace',table.concat(b.trace,'\n'))
  write(name,'.baseline.snapshot',as);write(name,'.candidate.snapshot',bs)
  write(name,'.baseline.errors',table.concat(a.errors,'\n'));write(name,'.candidate.errors',table.concat(b.errors,'\n'))
  check(ar==br,name..': return/error kind remains identical')
  check(as==bs,name..': final model/native/cache state identical')
  check(#a.trace==#b.trace,name..': native/property/pcall trace length differs '..#a.trace..'/'..#b.trace)
  for i=1,#a.trace do check(a.trace[i]==b.trace[i],name..': native/property/pcall trace differs at '..i..' '..tostring(a.trace[i])..' / '..tostring(b.trace[i]))end
  check(#a.errors==#b.errors,name..': protected failure count/order retained')
  for i=1,#a.errors do
   check((a.errors[i]=='<opaque-error>')==(b.errors[i]=='<opaque-error>'),name..': opaque protected error identity retained')
  end
 end
end
-- A functional resource assertion counts actual callbacks received by pcall,
-- without CPU timers or memory sampling. Native callbacks remain called.
do
 local a=model.fixture(baseline,{branch='forever'});local b=model.fixture(candidate,{branch='forever'})
 for _=1,20 do a:full();b:full()end
 check(#a.trace==#b.trace,'repeat resource proof retains trace length')
 for i=1,#a.trace do check(a.trace[i]==b.trace[i],'repeat resource proof retains exact native/property/pcall trace')end
 local before,after=count(a.pcalls),count(b.pcalls)
 check(after<before,'protected portrait callbacks reuse stable identities')
 print('CALLBACK_IDENTITIES baseline='..before..' candidate='..after..' fullCalls=20; not bytes or native CPU')
 local traceCount=#a.trace
 for _=1,20 do a:full();b:full()end
 check(#a.trace==#b.trace,'continued resource proof retains trace length')
 for i=traceCount+1,#a.trace do check(a.trace[i]==b.trace[i],'continued resource proof retains exact native/property/pcall trace')end
 check(count(b.pcalls)==after,'unchanged full consumer introduces no new protected callback identities after warm-up')
end

-- Exercise the opted-in party roster path against the ordinary portrait paint.
if not (arg and arg[1] == "--source") then
 for _, branch in ipairs{ "live", "forever", "classic" } do
  local stable = model.fixture(candidate, { branch = branch, unit = "party1" })
  local full = model.fixture(baseline, { branch = branch, unit = "party1" })
  local guid = "member-A"
  stable.env.UnitGUID = function() return guid end
  local function assignments(state)
   local count = 0
   for _, line in ipairs(state.trace) do
    if line:find("%.ClearModel$") then count = count + 1 end
   end
   return count
  end
  local function paint()
   stable.uf.UpdatePortrait(stable.owner, "party1", true)
   if stable.pendingTimers > 0 then stable:drain() end
  end
  stable:reset()
  full:reset()
  local preparedSnapshot
  for sample = 1, 20 do
   paint()
   full.uf.UpdatePortrait(full.owner, "party1")
   if full.pendingTimers > 0 then full:drain() end
   if sample == 1 then
    preparedSnapshot = stable:snapshot()
    check(full:snapshot() == preparedSnapshot, branch .. ": first roster paint preserves model and camera setup")
   end
  end
  local beforeCount, afterCount = assignments(full), assignments(stable)
  check(beforeCount == 20 and afterCount == 1, branch .. ": twenty stable roster samples use one model reset")
  check(preparedSnapshot == stable:snapshot(), branch .. ": unchanged member keeps its prepared camera and model")
  local n = afterCount
  local function repaint(label)
   paint()
   n = n + 1
   check(assignments(stable) == n, branch .. ": " .. label .. " reloads the model")
  end
  guid = "member-B"; repaint("same slot with different public member")
  guid = stable.private; repaint("secret identity")
  guid = nil; repaint("missing identity")
  guid = "member-B"; repaint("public identity recovery")
  stable.uf.ForgetRosterPortrait(stable.owner); repaint("hide/reveal")
  stable.uf.UpdatePortrait(stable.owner, "party1"); n = n + 1
  repaint("explicit unit model refresh")
  stable.owner.Portrait._data.modelID = 789; repaint("native model drift")
  stable.visible = stable.private; repaint("unavailable visibility")
  stable.visible = true
  stable.owner.Portrait:Hide(); repaint("hidden model")
  print("ROSTER_PORTRAIT " .. branch .. " resetModel=" .. beforeCount .. "/" .. afterCount .. " rosterSamples=20")
 end
end

-- Compiled harmful controls retain the same actual owners and native endpoints.
local function replace(text,a,b)
 local first,last=text:find(a,1,true)
 assert(first,'negative-control source anchor')
 return text:sub(1,first-1)..b..text:sub(last+1)
end
local controls={
 {'pin-old-portrait-across-clear',[[        self.Portrait:ClearModel()
        return SetPortraitUnit(self.Portrait, unit)]],[[        local portrait = self.Portrait
        portrait:ClearModel()
        return SetPortraitUnit(portrait, unit)]],'ClearModel-native-swap'},
 {'lookup-SetUnit-before-protected','local ok = pcall(SetPortraitUnitWithFlag, portrait, unit)','local ok = pcall(portrait.SetUnit, portrait, unit, false)','normal'},
 {'return-SetUnit-native-value',[[    local function SetPortraitUnitWithFlag(portrait, unit)
        portrait:SetUnit(unit, false)]],[[    local function SetPortraitUnitWithFlag(portrait, unit)
        return portrait:SetUnit(unit, false)]],'false-native-return'},
 {'drop-camera-protection','pcall(ApplyPortraitCameraProtected, portrait, keepIfClose)','ApplyPortraitCameraProtected(portrait, keepIfClose)','normal'},
 {'drop-keep-camera-mode','pcall(ApplyPortraitCameraProtected, portrait, keepIfClose)','pcall(ApplyPortraitCameraProtected, portrait, false)','close-camera'},
 {'read-new-container-for-second-region','pcall(SyncPortraitRegionGeometry, self.Portrait2D, pf, contentSize)','pcall(SyncPortraitRegionGeometry, self.Portrait2D, self.PortraitFrame, contentSize)','geometry-container-swap'},
 {'reallocate-camera-callback','pcall(ApplyPortraitCameraProtected, portrait, keepIfClose)','pcall(function() ApplyPortraitCameraProtected(portrait, keepIfClose) end)','resource'},
}
local function same(a,ar,as,b,br,bs)
 if ar~=br or as~=bs or #a.trace~=#b.trace or #a.errors~=#b.errors then return false end
 for i=1,#a.trace do if a.trace[i]~=b.trace[i]then return false end end
 for i=1,#a.errors do if(a.errors[i]=='<opaque-error>')~=(b.errors[i]=='<opaque-error>')then return false end end
 return true
end
for _,control in ipairs(controls)do
 local mutated=replace(current,control[2],control[3])
 check(loadenv(mutated,'@compiled-portrait-control:'..control[1],_G)~=nil,control[1]..': control compiles')
 local compiled=model.compileSource(mutated,control[1],petSource)
 local rejected=false
 if control[4]=='resource'then
  local s=model.fixture(compiled,{branch='forever'})
  for _=1,20 do s:full()end
  local functions=count(s.pcalls)
  for _=1,20 do s:full()end
  rejected=count(s.pcalls)>functions
 else
  local selected
  for _,spec in ipairs(specs)do if spec.name==control[4]then selected=spec end end
  local a,ar,as=exercise(baseline,assert(selected),'forever')
  local b,br,bs=exercise(compiled,selected,'forever')
  rejected=not same(a,ar,as,b,br,bs)
 end
 check(rejected,control[1]..': harmful control rejected')
end
print('Portrait protected callbacks: '..cases..' scenarios/'..checks..' checks PASS; actual production bodies, modeled native endpoints; no CPU timing/native tests')
