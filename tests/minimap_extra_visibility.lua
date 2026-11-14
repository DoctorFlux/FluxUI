-- Production controller + strict protected-write fixture. These are desktop
-- behavioral checks, not native secure execution, taint, pixels or FPS evidence.
local function read(path)
    local f = assert(io.open(path, 'rb')); local s = f:read('*a'):gsub('\r\n', '\n'); f:close(); return s
end
local source = read(os.getenv('FLUX_MINIMAP_EXTRA_SOURCE') or 'Minimap/FluxMinimapButtons.lua')
local fixture = read('tests/minimap_extra_layout.lua')
fixture = fixture:sub(1, assert(fixture:find('local function physical(frame)', 1, true)) - 1)
fixture = fixture:gsub('local source = read[^\n]*', 'local source = ...', 1)
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function near(a, b, why) check(math.abs(a-b) < .001, why) end
local function bootFor(src) return assert(load(fixture .. '\nreturn boot', '@strict minimap fixture', 't', _G))(src) end
local function drop(t, index, kind, value)
    t.env.Flux.EBS.Action.SetAction(t.widgets[index], kind, value)
    t.cursorType=nil; t:event('CURSOR_CHANGED')
    t.widgets[index].OnReceiveDragCallback(kind, value)
    t:flush()
end
local function erase(t, index)
    t.env.Flux.EBS.Action.Clear(t.widgets[index]); t.widgets[index].OnDelete(); t:flush()
end
local function pointer(t, frame)
    local x, y, w, h = frame:rect(); t.cursorX, t.cursorY = x+w/2, y+h/2; t:tick()
end
local function outside(t) t.cursorX, t.cursorY = 0, 0; t:tick() end
local function activeTimers(t)
    local n = 0; for _, timer in ipairs(t.tickers) do if not timer.cancelled then n=n+1 end end; return n
end
local function model(src, client, uiScale)
    local boot = bootFor(src)
    local t = boot({minimapExtraLayout={count=5,sideEnabled=true},minimapExtraButtons={
        [2]={actionType='spell',actionValue=7}, [5]={dataType='item',data=9},
        [90]={dataType='macro',data=1,macroBody='/say retained'},
    }})
    local m, e = t.api, t.env
    check(m:GetSetting('autoGrow') == false and m:GetSetting('sideHideEmpty') == false
        and m:GetSetting('sideMoveFrames') == nil and m:GetSetting('sideVisibility') == 'always', 'preferences preserve defaults and retire independent movement')
    e.UIParent:SetScale(uiScale)
    m:SetSetting('sideHideEmpty',true)
    check(#t:visible()==2 and t:visible()[1]==t.widgets[2] and t:visible()[2]==t.widgets[5], 'only unassigned slots collapse; depleted assigned item retained')
    near(t.widgets[2].Widget:GetTop()-t.widgets[5].Widget:GetTop(),t.widgets[2].Widget:GetHeight()*t.widgets[2].Widget:GetScale(), 'sparse assigned slots pack together')
    local identity=t.widgets[2].Widget
    t.cursorType,t.cursorValue='spell',40; t:event('CURSOR_CHANGED'); t:flush()
    check(#t:visible()==3 and t.widgets[1].Widget:IsVisible() and not t.widgets[3].Widget:IsVisible(), 'carried action reveals exactly one empty drop target')
    t.cursorType=nil; t:event('CURSOR_CHANGED'); t:flush()
    check(#t:visible()==2, 'cancelled drag hides spare again')
    erase(t,2)
    check(#t:visible()==1 and t.widgets[5].Widget:IsVisible(), 'deletion repacks without losing numbered assignments')
    check(t.saved.minimapExtraButtons[90].macroBody=='/say retained', 'collapsed higher saved records survive')
    m:SetSetting('sideHideEmpty',false)
    check(#t:visible()==5 and identity==t.widgets[2].Widget, 'show empty restores original widgets')
    m:SetSetting('sideVisibility','mouseover')
    for _, start in ipairs({'top','below'}) do
        m:SetSetting('sideStart',start)
        check(m:GetMinimapOffset()==0 and m:GetTrackerOffset()==0 and m:GetSideWidth()>0, 'overlay keeps actual grid width but releases all native reservation')
    end
    m:SetSetting('sideVisibility','always')
    check(m:GetTrackerOffset()<0, 'always shown automatically restores reservation')
    m:SetSetting('sideVisibility','mouseover')
    check(#t:visible()==0 and activeTimers(t)==1, 'mouseover hides with one owned ticker')
    local root=e.FluxMinimapButtonsContainer
    pointer(t,root)
    check(#t:visible()==5, 'hover detects hidden root geometry without an input-blocking sensor')
    for _=1,8 do m:RequestRefresh() end
    check(activeTimers(t)==1, 'repeated refresh does not duplicate hover polling')
    local popup=e.CreateFrame('Frame',nil,e.UIParent); popup:SetSize(50,50)
    popup:SetPoint('BOTTOMRIGHT',root,'TOPLEFT',0,10)
    local arrow=e.CreateFrame('Frame',nil,e.UIParent); arrow:SetSize(10,10)
    arrow:SetPoint('BOTTOM',root,'TOP',0,0)
    e.Flux.EBS.Flyout.GetPopup=function(w) if w==t.widgets[1].Widget then return popup end end
    e.Flux.EBS.Flyout.GetArrow=function(w) if w==t.widgets[1].Widget then return arrow end end
    pointer(t,popup); check(#t:visible()==5, 'pointer can use open flyout outside grid')
    pointer(t,arrow); check(#t:visible()==5, 'pointer can use flyout arrow outside grid')
    outside(t); check(#t:visible()==0, 'leaving grid and flyout hides root')
    local writes=t.structuralWrites
    t:combatState(true); pointer(t,root)
    check(#t:visible()==0 and activeTimers(t)==0 and writes==t.structuralWrites, 'hidden hover state freezes in combat with no protected writes or polling')
    t:combatState(false)
    check(#t:visible()==5 and activeTimers(t)==1, 'combat exit resumes current pointer state')
    t:combatState(true); writes=t.structuralWrites; outside(t)
    check(#t:visible()==5 and writes==t.structuralWrites, 'shown hover state freezes in combat')
    m:SetSetting('sideVisibility','always'); m:SetSetting('sideHideEmpty',true)
    check(writes==t.structuralWrites, 'combat option changes defer geometry and visibility')
    t:combatState(false)
    check(#t:visible()==1 and activeTimers(t)==0, 'latest saved choices apply after combat')
    m:SetSetting('sideHideEmpty',false); m:SetSetting('sideVisibility','mouseover'); outside(t)
    m:SetSetting('hideInCombat',true)
    check(next(t.drivers)~=nil and #t:visible()==0, 'secure combat gate cannot override hidden hover parent')
    -- Model the driver's repeated OOC show, rather than only state transitions.
    for host in pairs(t.drivers) do host:Show() end
    check(#t:visible()==0, 'repeated native combat-driver show cannot defeat mouseover')
    pointer(t,root); check(#t:visible()==5, 'combined mouseover/combat options reveal outside combat')
    t:combatState(true)
    check(#t:visible()==0 and activeTimers(t)==0, 'combat-hide overrides frozen shown hover state securely')
    t:combatState(false); check(#t:visible()==5, 'combined mode resumes after combat')
    m:SetSetting('sideVisibility','always')
    t:combatState(true); check(#t:visible()==0, 'always plus combat-hide hides only in combat')
    t:combatState(false); check(#t:visible()==5, 'hide-only-combat restores all configured slots')
    m:SetSetting('sideHideEmpty',true); m:SetSetting('sideVisibility','mouseover'); t:embed(256)
    check(#t:visible()==5 and activeTimers(t)==0 and not next(t.drivers), 'embedding ignores empty hiding and both side visibility choices')
    t:combatState(true); check(#t:visible()==5, 'embedded grid stays visible in combat')
    t:combatState(false)
    m:SetSetting('sideEnabled',false); t:normal()
    check(#t:visible()==0 and activeTimers(t)==0,'disabled side grid stops hover work')
    for _, f in ipairs(t.frames) do check(not f.events.CURSOR_CHANGED,'disabled strip unregisters cursor observer') end
    local empty=boot({minimapExtraLayout={sideEnabled=true,sideHideEmpty=true,sideVisibility='mouseover'}})
    check(#empty:visible()==0 and empty.api:GetSideWidth()==0,'all-empty side grid has no visible or reserved area')
    empty.cursorType='spell'; empty:event('CURSOR_CHANGED'); empty:flush()
    pointer(empty,empty.env.FluxMinimapButtonsContainer)
    check(#empty:visible()==1,'all-empty mouseover grid can reveal its first drop target')
    local retained=boot({minimapExtraLayout={count=1,sideEnabled=true,autoGrow=true},minimapExtraButtons={
        [2]={dataType='macro',data=1,macroName='Saved Macro',macroBody='/say retained'},
    }})
    drop(retained,1,'spell',10)
    check(retained.api:GetSetting('count')==1 and #retained:visible()==2 and retained.widgets[2].actionValue.body=='/say retained', 'dynamic mode retains higher assigned indices without rewriting the configured minimum')
    local legacy=boot({minimapExtraLayout={sideEnabled=true,hideInCombat=true,sideVisibility='mouseover'}},function(t) t.supported=false end)
    check(not next(legacy.drivers),'unsupported secure hiding never installs an insecure fallback')
    pointer(legacy,legacy.env.FluxMinimapButtonsContainer); legacy:combatState(true); outside(legacy)
    check(#legacy:visible()==15,'mouseover can freeze safely without a native combat driver')
    return true
end
for _, client in ipairs({'retail','forever','classic','era','anniversary'}) do
    for _, scale in ipairs({.7,1,1.4}) do model(source,client,scale) end
end
local function replace(s,old,new)
    local i=assert(s:find(old,1,true),old); return s:sub(1,i-1)..new..s:sub(i+#old)
end
local controls={
    replace(source,'local collapse = not IsEmbedded() and M:GetSetting("sideHideEmpty")','local collapse = false'),
    replace(source,'if self:GetSetting("sideVisibility") == "mouseover" then return 0 end','if false then return 0 end'),
    replace(source,'if InCombat() or not containerFrame or not UsesMouseover() then return end','if not containerFrame or not UsesMouseover() then return end'),
    replace(source,'StopHoverTicker()\n    elseif event == "PLAYER_REGEN_ENABLED"','UpdateMouseover()\n    elseif event == "PLAYER_REGEN_ENABLED"'),
}
-- The first combat mutation control also leaves polling alive to exercise its
-- protected-write guard; the separate lifecycle control catches the live ticker.
controls[3]=replace(controls[3],'StopHoverTicker()\n    elseif event == "PLAYER_REGEN_ENABLED"','-- left running\n    elseif event == "PLAYER_REGEN_ENABLED"')
for i,candidate in ipairs(controls) do
    check(not pcall(model,candidate,'control',1),'harmful control '..i..' must fail')
end
print('Minimap extra visibility: '..checks..' checks; 5 client models; 15 scale cases; '..#controls..' harmful controls PASS')
