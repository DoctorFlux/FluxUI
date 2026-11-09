-- Public layout conversion and native-boundary guards; no native taint VM claims.
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function read(path) local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s:gsub("\r\n","\n") end
local function equal(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~="table"then return a==b end
    for k,v in pairs(a)do if not equal(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function clone(t)if type(t)~="table"then return t end local o={}for k,v in pairs(t)do o[k]=clone(v)end return o end
local settingNames={"IconSize","IconPadding","Opacity","VisibleSetting","ShowTimer","ShowTooltips","BarWidthScale","BarContent","HideWhenInactive","Orientation","IconDirection","IconLimit"}
local source=read(arg[1]or"Other/FluxCooldownDefaults.lua")
for _,client in ipairs({"retail","forever","classic","era","anniversary"})do
    local setting={}for i,k in ipairs(settingNames)do setting[k]=i end
    local saved,probeWrites={},0
    local combat,editing,tainted=false,false,false
    local e=setmetatable({SlashCmdList={},Enum={EditModeCooldownViewerSetting=setting,
        EditModeCooldownViewerSystemIndices={BuffBar=4,BuffIcon=3,Utility=2,Essential=1},
        EditModeSystem={CooldownViewer=13},EditModeLayoutType={Preset=0,Account=1,Character=2},
        EditModePresetLayouts={Modern=1,Classic=2},
        CooldownViewerOrientation={Vertical=1},CooldownViewerIconDirection={Right=1},
        CooldownViewerVisibleSetting={Always=0},CooldownViewerBarContent={IconAndName=0}},
        Constants={EditModeConsts={EditModeMaxLayoutsPerType=5}}},{__index=_G});e._G=e
    local ns={Flux={DB={GetChar=function()return saved end}}}
    e.GetBuildInfo=function()return client,"test-build"end
    e.InCombatLockdown=function()return combat end;e.FluxEditModeBusy=function()return editing end
    e.issecretvalue=function(v)return v=="RESTRICTED"end
    e.issecurevariable=function()return not tainted end
    e.C_EditMode={SetActiveLayout=function()error("activation forbidden during probe")end,IsValidLayoutName=function()return true end}
    local preset={layoutName="Modern",layoutType=0,layoutIndex=1,interfaceStyle=0,systems={}}
    preset.systems[1]={system=1,anchorInfo={point="CENTER",offsetX=49},settings={{setting=99,value=17}},isInDefaultPosition=true}
    for i=1,4 do preset.systems[#preset.systems+1]={system=13,systemIndex=i,
        settings={{setting=setting.IconSize,value=0},{setting=99,value=42}},anchorInfo={point="CENTER"},isInDefaultPosition=true}end
    local account={layoutName="Custom account",layoutType=1,systems={{anything={nested="keep"}}}}
    local char={layoutName="My saved layout",layoutType=2,systems={{setting="keep"}}}
    e.EditModeManagerFrame={layoutInfo={layouts={preset,account,char},activeLayout=1}}
    for _,name in ipairs({"BuffBarCooldownViewer","BuffIconCooldownViewer","UtilityCooldownViewer","EssentialCooldownViewer"})do e[name]={}end
    e.C_EditMode.SaveLayouts=function(data)
        probeWrites=probeWrites+1
        check(equal(data,e.EditModeManagerFrame.layoutInfo),"probe must not alter any layout")
        check(data~=e.EditModeManagerFrame.layoutInfo,"probe never passes native table to engine")
    end
    assert(load(source,"@cooldown-defaults","t",e))("_FluxUI",ns)
    local d=ns.CooldownDefaults
    check(d~=nil,"namespace")
    if client~="retail"and client~="forever"then
        e.Enum.EditModeCooldownViewerSetting=nil
        check(not d.IsAvailable(),"unsupported viewer contract")
        check(not d.BuildPlan({},{}),"unsupported no plan")
        check(not d.TestBoundary()and probeWrites==0,"unsupported no writes")
    else
        local original=clone(e.EditModeManagerFrame.layoutInfo)
        local plan,index=d.BuildPlan(original,{left=500,top=300})
        check(plan and index==4,"append one character layout")
        check(equal(original,e.EditModeManagerFrame.layoutInfo),"source unchanged")
        check(plan.activeLayout==1,"plan does not change active selection")
        check(equal(plan.layouts[2],account)and equal(plan.layouts[3],char),"custom layouts unchanged")
        check(equal(plan.layouts[1],preset),"preset unchanged")
        check(equal(plan.layouts[4].systems[1],preset.systems[1]),"unrelated systems unchanged")
        check(plan.layouts[4].layoutType==2 and plan.layouts[4].layoutIndex==nil,"character metadata")
        local positions={[1]=368,[2]=422,[3]=456,[4]=500}
        for _,system in ipairs(plan.layouts[4].systems)do if system.system==13 then
            local s={}for _,v in ipairs(system.settings)do s[v.setting]=v.value end
            local bar=system.systemIndex==4
            check(s[setting.IconSize]==(bar and 4 or 5),"encoded scale")
            check(s[setting.Opacity]==50,"encoded opacity")
            check(s[99]==42,"unknown native settings retained")
            check(system.anchorInfo.offsetX==positions[system.systemIndex]and system.anchorInfo.offsetY==304,"column geometry")
            check(system.anchorInfo.relativeTo=="UIParent"and system.anchorInfo.point=="BOTTOMLEFT","no protected dependency")
            check(not system.isInDefaultPosition,"saved native anchor")
            if bar then check(s[setting.BarWidthScale]==107 and s[setting.BarContent]==0,"encoded bar presentation")
            else check(s[setting.Orientation]==1 and s[setting.IconDirection]==1,"vertical up")end
        end end
        original.layouts[2].systems=clone(preset.systems)
        original.layouts[3].systems=clone(preset.systems)
        original.layouts[2].layoutIndex=1
        original.layouts[3].layoutIndex=1
        original.activeLayout=2
        check(not d.BuildPlan(original,{left=500,top=300}),"account custom untouched")
        original.activeLayout=3
        check(not d.BuildPlan(original,{left=500,top=300}),"character custom untouched")
        original.activeLayout=1
        check(not d.BuildPlan(original,{left="RESTRICTED",top=300}),"restricted geometry refused")
        original.layouts[2].layoutName="FluxUI"
        check(not d.BuildPlan(original,{left=500,top=300}),"existing layout never overwritten")
        original.layouts[2].layoutName="Custom account"
        for i=1,4 do original.layouts[#original.layouts+1]=clone(char)end
        check(not d.BuildPlan(original,{left=500,top=300}),"layout cap preserved")
        combat=true;check(not d.TestBoundary()and probeWrites==0,"combat no writes");combat=false
        editing=true;check(not d.TestBoundary()and probeWrites==0,"editor no writes");editing=false
        tainted=true;check(not d.TestBoundary()and probeWrites==0,"preexisting taint no writes");tainted=false
        check(d.TestBoundary()and probeWrites==1,"one public no-op round trip")
        d.TestBoundary();check(probeWrites==1,"no duplicate attempts")
        check(saved.cooldownDefaultsProbe.stage=="metadata-pass","bounded evidence")
    end
end
for _,mode in ipairs({"preset","custom","failed","unready","namesTaken","legacy","consolidate","editedCopy","missingAfterSave"})do
    local events,callbacks,queue,deferred={},{},{},{}
    local calls={save=0,activate=0,points=0}
    local combat,editing,tainted=false,false,false
    local state={cooldownDefaults={version=3}}
    if mode=="missingAfterSave"then
        state.cooldownDefaults={version=3,stage="applied",layouts={FluxUI=false},lastCustomized="FluxUI",
            retiredLayouts={{layoutName="Earlier recovery",systems={}}}}
    end
    if mode=="legacy"then state.cooldownDefaults={version=1,stage="applied",layoutName="Flux Cooldowns",managed=true}end
    local setting={}for i,k in ipairs(settingNames)do setting[k]=i end
    local e=setmetatable({SlashCmdList={},Enum={EditModeCooldownViewerSetting=setting,
        EditModeCooldownViewerSystemIndices={BuffBar=4,BuffIcon=3,Utility=2,Essential=1},
        EditModeSystem={CooldownViewer=13},EditModeLayoutType={Preset=0,Account=1,Character=2},
        EditModePresetLayouts={Modern=1,Classic=2},
        CooldownViewerOrientation={Vertical=1},CooldownViewerIconDirection={Right=1},
        CooldownViewerVisibleSetting={Always=0},CooldownViewerBarContent={IconAndName=0}},
        Constants={EditModeConsts={EditModeMaxLayoutsPerType=5}}},{__index=_G});e._G=e
    e.UIParent={}
    local ns={ClassPower={GetLayoutBounds=function()return {left=500,top=300}end},Flux={Client={isForever=true},
        DB={GetChar=function()return state end},Events={Register=function(k,fn)events[k]=fn end},
        Timer={Defer=function(fn)queue[#queue+1]=fn end},Combat={Defer=function(k,fn)deferred[k]=fn end}}}
    local function drain()local old=queue;queue={};for _,fn in ipairs(old)do fn()end end
    local preset={layoutName="Modern",layoutType=0,layoutIndex=1,systems={}}
    for i=1,4 do preset.systems[i]={system=13,systemIndex=i,settings={{setting=99,value=42}},anchorInfo={point="CENTER"}}end
    local custom={layoutName="Keep me",layoutType=2,systems={{system=1,settings={{value=73}}}}}
    local classic=clone(preset);classic.layoutName,classic.layoutIndex="Classic",2
    local layouts={preset,classic,custom}
    if mode=="legacy"then local legacy=clone(custom);legacy.layoutName="Flux Cooldowns";layouts[#layouts+1]=legacy end
    if mode=="namesTaken"then
        local reserved=clone(custom);reserved.layoutName="FluxUI";layouts[#layouts+1]=reserved
    end
    e.EditModeManagerFrame={layoutInfo={activeLayout=mode=="custom"and 3 or 1,layouts=layouts}}
    e.EventRegistry={RegisterCallback=function(_,k,fn)callbacks[k]=fn end}
    e.C_EditMode={IsValidLayoutName=function()return true end}
    e.issecurevariable=function()return not tainted end
    e.InCombatLockdown=function()return combat end;e.FluxEditModeBusy=function()return editing end
    e.FluxAfterEditMode=function(fn,k)deferred[k]=fn end
    e.C_EditMode.SaveLayouts=function(plan)
        calls.save=calls.save+1
        check(equal(plan.layouts[3],custom),"engine save preserves custom data")
        check(equal(plan.layouts[1],preset)and equal(plan.layouts[2],classic),"both native presets remain unchanged")
        e.EditModeManagerFrame.layoutInfo=clone(plan)
        if mode=="failed"then tainted=true end
        events.EDIT_MODE_LAYOUTS_UPDATED()
    end
    e.C_EditMode.SetActiveLayout=function(index)
        calls.activate=calls.activate+1;e.EditModeManagerFrame.layoutInfo.activeLayout=index
        events.EDIT_MODE_LAYOUTS_UPDATED()
    end
    for _,name in ipairs({"BuffBarCooldownViewer","BuffIconCooldownViewer","UtilityCooldownViewer","EssentialCooldownViewer"})do
        local point={"CENTER",e.UIParent,"CENTER",0,0}
        e[name]={ClearAllPointsBase=function()calls.points=calls.points+1 end,
            SetPointBase=function(_,...)point={...};calls.points=calls.points+1 end,GetPoint=function()return table.unpack(point)end}
    end
    if mode=="unready"then e.BuffBarCooldownViewer=nil end
    assert(load(source,"@cooldown-defaults-lifecycle","t",e))("_FluxUI",ns)
    if mode=="consolidate"or mode=="editedCopy"then
        local function encode(v)
            if type(v)~="table"then return type(v)..":"..tostring(v)end
            local keys={}for k in pairs(v)do keys[#keys+1]=k end
            table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
            local out={}for _,k in ipairs(keys)do out[#out+1]=encode(k).."="..encode(v[k])end
            return "{"..table.concat(out,",").."}"
        end
        e.C_EditMode.ConvertLayoutInfoToString=encode
        local d=ns.CooldownDefaults
        local first=assert(d.BuildPlan(e.EditModeManagerFrame.layoutInfo,{left=500,top=300},"Flux Modern"))
        first.activeLayout=2
        local second=assert(d.BuildPlan(first,{left=500,top=300},"Flux Classic"))
        second.activeLayout=4
        if mode=="editedCopy"then second.layouts[4].systems[1].settings[1].value=999 end
        e.EditModeManagerFrame.layoutInfo=second
        state.cooldownDefaults={version=2,stage="applied",layouts={["Flux Modern"]=true,["Flux Classic"]=true}}
    end
    check(calls.save==0 and #queue==0,"load has no native mutations")
    events.PLAYER_LOGIN()
    for i=1,20 do ns.CooldownDefaults.Request()end
    check(#queue==1,"readiness burst coalesced")
    combat=true;drain();check(calls.save==0,"combat defers all layout work")
    combat=false
    if deferred["cooldown.defaults"]then deferred["cooldown.defaults"]()end
    editing=true;drain();check(calls.save==0,"editor defers all layout work")
    editing=false
    if deferred["cooldown.defaults"]then deferred["cooldown.defaults"]()end
    drain()
    if mode=="preset"or mode=="legacy"or mode=="consolidate"or mode=="missingAfterSave"then
        check(calls.save==1 and calls.activate==1,"one public save and activation")
        check(calls.points==8,"four base-widget anchors")
        for i=1,20 do events.UI_SCALE_CHANGED()end;drain()
        check(calls.save==1 and calls.activate==1 and calls.points==8,"stable burst does not rewrite points/settings")
        callbacks["EditMode.SavedLayouts"]()
        check(state.cooldownDefaults.layouts.FluxUI==false and state.cooldownDefaults.lastCustomized=="FluxUI","native save takes ownership")
        events.UI_SCALE_CHANGED();drain();check(calls.points==8,"customized layout is no longer followed")
        if mode=="legacy"then
            check(state.cooldownDefaults.legacyLayoutName=="Flux Cooldowns"and state.cooldownDefaults.version==3,"migration preserves earlier copy identity")
            check(e.EditModeManagerFrame.layoutInfo.layouts[4].layoutName=="Flux Cooldowns","earlier copy remains untouched")
        elseif mode=="consolidate"then
            check(#e.EditModeManagerFrame.layoutInfo.layouts==4,"two untouched test copies consolidated into one")
            check(#state.cooldownDefaults.retiredLayouts==2,"both retired profiles remain recoverable")
        elseif mode=="missingAfterSave"then
            check(state.cooldownDefaults.retiredLayouts[1].layoutName=="Earlier recovery","recreation preserves recovery data")
        end
        if mode=="preset"then
            local root=e.EditModeManagerFrame.layoutInfo
            for i,l in ipairs(root.layouts)do if l.layoutName=="FluxUI"then table.remove(root.layouts,i);break end end
            root.activeLayout=1
            callbacks["EditMode.SavedLayouts"]()
            events.EDIT_MODE_LAYOUTS_UPDATED()
            drain()
            check(calls.save==2 and calls.activate==2,"deleted FluxUI layout recreated automatically")
            for i=1,20 do events.EDIT_MODE_LAYOUTS_UPDATED()end;drain()
            check(calls.save==2,"existing FluxUI never duplicated by subsequent events")
        end
    elseif mode=="failed"then
        check(calls.save==1 and calls.activate==0,"failed metadata prevents activation")
        tainted=false;ns.CooldownDefaults.Request();drain()
        check(calls.save==1 and state.cooldownDefaults.stage=="failed","no automatic retry after native failure")
    elseif mode=="custom"or mode=="editedCopy"then
        check(calls.save==1 and calls.activate==0 and calls.points==0,"copies added without changing active custom layout")
        check(e.EditModeManagerFrame.layoutInfo.activeLayout==(mode=="custom"and 3 or 4),"custom selection preserved")
        if mode=="editedCopy"then
            check(e.EditModeManagerFrame.layoutInfo.layouts[4].systems[1].settings[1].value==999,"edited generated profile retained")
            check(#state.cooldownDefaults.retiredLayouts==1,"only unchanged copy retired")
        end
    else check(calls.save==0 and calls.activate==0 and calls.points==0,"unavailable/existing named layouts untouched")end
end
-- Execute the real class-resource geometry helper independently of class setup.
local power=read("UnitFrames/FluxClassPower.lua")
local helper=assert(power:match("function ns.ClassPower.GetLayoutBounds%(parentFrame%).-\nend"))
local function frame(left,top,scale,visible)
    return {GetLeft=function()return left end,GetTop=function()return top end,GetEffectiveScale=function()return scale end,
        IsVisible=function()return visible end}
end
local ns={ClassPower={}}
local e=setmetatable({ns=ns,InCombatLockdown=function()return false end,UIParent=frame(0,0,0.8,true),
    ResolveClassPowerParent=function(f)return f end,GetAnchor=function(f)return f end},{__index=_G});e._G=e
local bars={frame(0,250,1.6,true),frame(0,900,1,false)}
e.EachClassBar=function(fn)for _,v in ipairs(bars)do fn(v)end end
assert(load(helper,"@class-layout-bounds","t",e))()
local bounds=ns.ClassPower.GetLayoutBounds(frame(100,150,1.6,true))
check(bounds.left==200 and bounds.top==500,"class/resource scaling in UIParent units")
e.InCombatLockdown=function()return true end
check(ns.ClassPower.GetLayoutBounds(frame(1,1,1,true))==nil,"no protected geometry in combat")
e.InCombatLockdown=function()return false end
e.issecretvalue=function(v)return v==900 end
bars[1]=frame(0,900,1,true)
check(ns.ClassPower.GetLayoutBounds(frame(100,150,1.6,true))==nil,"restricted class geometry no guessed clearance")
print("cooldown defaults: "..checks.." checks PASS (desktop data/guard scope)")
