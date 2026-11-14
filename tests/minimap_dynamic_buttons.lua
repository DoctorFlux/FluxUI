-- Actual shared controller and existing strict frame/action fixture. Desktop
-- models do not establish native secure input, taint, pixels or performance.
local function read(path)
    local f=assert(io.open(path,'rb')); local s=f:read('*a'):gsub('\r\n','\n'); f:close(); return s
end
local source=read(os.getenv('FLUX_MINIMAP_EXTRA_SOURCE') or 'Minimap/FluxMinimapButtons.lua')
local fixture=read('tests/minimap_extra_layout.lua')
fixture=fixture:sub(1,assert(fixture:find('local function physical(frame)',1,true))-1)
fixture=fixture:gsub('local source = read[^\n]*','local source = ...',1)
local checks=0
local function check(ok,why) checks=checks+1; assert(ok,why) end
local function bootFor(src) return assert(load(fixture..'\nreturn boot','@strict dynamic fixture','t',_G))(src) end
local function records(n)
    local out={};for i=1,n do out[i]={dataType='spell',data=100+i} end;return out
end
local function carry(t,on)
    t.cursorType,t.cursorValue=on and 'spell' or nil,on and 999 or nil
    t:event('CURSOR_CHANGED');t:flush()
end
local function drop(t,index,kind,value)
    check(t.widgets[index] and t.widgets[index].Widget:IsVisible(),'drop target exists before releasing cursor')
    t.env.Flux.EBS.Action.SetAction(t.widgets[index],kind or 'spell',value or 999)
    t.cursorType=nil;t:event('CURSOR_CHANGED') -- EBS clears before its save callback.
    t.widgets[index].OnReceiveDragCallback(kind or 'spell',value or 999);t:flush()
end
local function erase(t,index)
    t.env.Flux.EBS.Action.Clear(t.widgets[index]);t.widgets[index].OnDelete();t:flush()
end
local function observed(t)
    for _,f in ipairs(t.frames) do if f.events.CURSOR_CHANGED then return true end end;return false
end
local function bounded(t,mode)
    for _,b in ipairs(t:visible()) do
        local x,y,w,h=b.Widget:rect()
        check(w>0 and h>0,'active button has a usable size')
        if mode=='side' then
            local wx,wy,ww,wh=t.window:rect();local _,_,sw,sh=t.env.UIParent:rect()
            check(x>=0 and y>=wy+wh-.001 and x+w<=sw+.001 and y+h<=sh+.001,'dynamic side grid stays within screen/window bounds')
        else
            local wx,wy,ww,wh=t.window:rect();local mx=t.env.Minimap:rect()
            check(x>=wx-.001 and y>=wy-.001 and x+w<=mx+.001 and y+h<=wy+wh+.001,'dynamic embedded grid fits its host beside map')
        end
    end
end
local function model(src,client,mode,uiScale)
    local boot=bootFor(src)
    local function make(n,minimum,dynamic)
        local t=boot({minimapExtraLayout={count=minimum or 15,sideEnabled=true,autoGrow=dynamic or false,
            sideStart='top',sideMoveFrames=false},minimapExtraButtons=records(n)})
        t.env.UIParent:SetScale(uiScale)
        if mode=='embedded' then t:embed(256) else t.api:RequestRefresh() end
        return t
    end
    local t=make(15)
    local m=t.api
    check(#t:visible()==15 and not observed(t),'fixed mode starts at configured count without cursor work')
    check(m:GetSetting('sideMoveFrames')==nil,'retired movement key is ignored without deleting saved data')
    if mode=='side' then
        check(m:GetMinimapOffset()<0,'always shown automatically reserves map space despite old movement=false')
        m:SetSetting('sideVisibility','mouseover')
        check(m:GetMinimapOffset()==0 and m:GetTrackerOffset()==0,'mouseover automatically releases both offsets')
        m:SetSetting('sideVisibility','always')
    end
    m:SetSetting('autoGrow',true)
    check(#t:visible()==15 and m:GetSetting('count')==15 and observed(t),'dynamic count starts at minimum and observes drags in both layouts')
    local first=t.widgets[1].Widget
    carry(t,true)
    check(#t:visible()==16 and t.widgets[16].Widget:IsVisible(),'full fifteen-slot grid offers slot sixteen before the drop')
    check(m:GetSetting('count')==15 and t.saved.minimapExtraLayout.count==15,'preview never rewrites configured minimum')
    bounded(t,mode)
    local preview=t.widgets[16].Widget
    carry(t,false)
    check(#t:visible()==15 and not preview:IsVisible(),'cancelling unused preview returns to fifteen')
    carry(t,true);drop(t,1)
    check(#t:visible()==15 and not preview:IsVisible(),'dropping elsewhere removes the unused preview')
    carry(t,true)
    check(preview==t.widgets[16].Widget,'next drag reuses the same preview widget')
    drop(t,16,'item',901)
    check(#t:visible()==16 and m:GetSetting('count')==15,'accepted new assignment keeps sixteen with minimum fifteen')
    check(t.saved.minimapExtraButtons[16].data==901,'accepted extra action is persisted in its original index')
    for _=1,6 do m:RequestRefresh() end
    check(#t:visible()==16,'idle refresh never adds another empty button')
    carry(t,true);check(#t:visible()==17,'next full-grid drag offers exactly one more button')
    carry(t,false);check(#t:visible()==16,'cancel removes only temporary seventeenth slot')
    carry(t,true)
    local macro=t.widgets[17];macro.MacroIndex,macro.MacroName,macro.MacroBody=1,'Saved Macro','/say preserved'
    drop(t,17,'macro',1)
    check(#t:visible()==17,'second accepted extra remains after releasing cursor')
    erase(t,16)
    check(#t:visible()==16 and not t.widgets[16].Widget:IsVisible() and t.widgets[17].Widget:IsVisible(),'removing an interior extra compacts immediately without renumbering later actions')
    erase(t,4)
    check(#t:visible()==15 and not t.widgets[4].Widget:IsVisible(),'removing another assignment shrinks to minimum without retaining a hole')
    erase(t,3)
    check(#t:visible()==15 and t.widgets[3].Widget:IsVisible() and not t.widgets[4].Widget:IsVisible(),'below minimum an existing empty numbered slot supplies the floor')
    check(m:GetSetting('count')==15 and t.widgets[1].Widget==first,'deletions never rewrite minimum or recreate original widgets')
    m:SetSetting('count',20);check(#t:visible()==20,'raising manual minimum adds empty placeholders')
    m:SetSetting('count',1);check(#t:visible()==14,'lowering minimum keeps every assigned slot including sparse higher indices')
    m:SetSetting('count',15);m:SetSetting('autoGrow',false)
    check(#t:visible()==15 and not t.widgets[17].Widget:IsVisible(),'fixed mode restores first configured indices')
    check(t.saved.minimapExtraButtons[17].macroBody=='/say preserved','turning dynamic mode off preserves hidden higher macro data')
    m:SetSetting('autoGrow',true)
    check(#t:visible()==15 and t.widgets[17].Widget:IsVisible(),'reenabling restores occupied higher indices')
    local reload=boot(t.saved)
    if mode=='embedded' then reload:embed(256) end
    check(reload.api:GetSetting('count')==15 and #reload:visible()==15,'saved minimum and dynamic selection survive reload')
    check(reload.widgets[17].actionValue.body=='/say preserved','macro recovery survives dynamic packing and reload')
    check(t.saved.minimapExtraLayout.sideMoveFrames==false,'retired preference remains saved but cannot override visibility policy')
    bounded(t,mode)

    local combat=make(15,15,true)
    combat:combatState(true);local writes=combat.structuralWrites
    carry(combat,true)
    check(#combat:visible()==15 and combat.creates==15 and writes==combat.structuralWrites,'cursor in combat queues growth with no protected frame writes')
    combat:combatState(false)
    check(#combat:visible()==16,'combat exit reconciles the current carried action')
    combat:combatState(true);writes=combat.structuralWrites;carry(combat,false)
    check(#combat:visible()==16 and writes==combat.structuralWrites,'combat cancellation does not hide the protected preview mid-combat')
    combat:combatState(false)
    check(#combat:visible()==15,'combat exit removes a cancelled empty preview')

    local maximum=make(120,15,true)
    carry(maximum,true)
    check(#maximum:visible()==120 and maximum.creates==120,'dynamic grids never exceed supported120 or discard assignments')
    drop(maximum,120);erase(maximum,120)
    check(#maximum:visible()==119,'deleting a full-cap extra shrinks immediately')
    carry(maximum,true);check(#maximum:visible()==120,'available last slot can be previewed again')
    carry(maximum,false);check(#maximum:visible()==119,'last temporary slot cancels without changing minimum')
    maximum.api:SetSetting('count',120);erase(maximum,119)
    check(#maximum:visible()==120,'manual minimum120 prevents shrinking past120')
    bounded(maximum,mode)

    if mode=='side' then
        local hidden=make(15,15,true)
        hidden.api:SetSetting('sideHideEmpty',true)
        carry(hidden,true);check(#hidden:visible()==16,'hide-empty retains the single dynamic drop target while carrying')
        drop(hidden,16);erase(hidden,5);erase(hidden,6)
        check(#hidden:visible()==14,'explicit hide-empty can hide minimum placeholders while retaining all assigned actions')
        carry(hidden,true);check(#hidden:visible()==15 and hidden.widgets[5].Widget:IsVisible(),'existing empty minimum slot is reused before adding another')
        carry(hidden,false);check(#hidden:visible()==14,'cancel hides the empty minimum placeholder again')
    end
    m:SetSetting('autoGrow',false);m:SetSetting('sideHideEmpty',false)
    check(not observed(t),'disabling dynamic and hide-empty stops cursor observation')
    return true
end
for _,client in ipairs({'retail','forever','classic','era','anniversary'}) do
    for _,mode in ipairs({'embedded','side'}) do
        for _,scale in ipairs({.7,1,1.4}) do model(source,client,mode,scale) end
    end
end
local function replace(s,old,new)
    local i=assert(s:find(old,1,true),old);return s:sub(1,i-1)..new..s:sub(i+#old)
end
local controls={
    replace(source,'if dragging and total == target and target < maximum then target = target + 1 end','-- no preview'),
    replace(source,'local target = math.max(minimum, total)','local target = math.max(minimum, total + 1)'),
    replace(source,'local target = math.max(minimum, total)','local target = total'),
    replace(source,'if HasAssignment(i) then selected[i] = true; total = total + 1 end','if i <= minimum and HasAssignment(i) then selected[i] = true; total = total + 1 end'),
    replace(source,'if self:GetSetting("autoGrow") or (layoutMode == "side" and self:GetSetting("sideHideEmpty")) then','if layoutMode == "side" and self:GetSetting("sideHideEmpty") then'),
    replace(source,'if self:GetSetting("sideVisibility") == "mouseover" then return 0 end','if false then return 0 end'),
}
local expected={
    'full fifteen-slot grid offers slot sixteen before the drop',
    'dynamic count starts at minimum and observes drags in both layouts',
    'below minimum an existing empty numbered slot supplies the floor',
    'accepted new assignment keeps sixteen with minimum fifteen',
    'dynamic count starts at minimum and observes drags in both layouts',
    'mouseover automatically releases both offsets',
}
for i,candidate in ipairs(controls) do
    local ok,err=pcall(model,candidate,'control',i==6 and 'side' or 'embedded',1)
    check(not ok and tostring(err):find(expected[i],1,true),'harmful dynamic control '..i..' must fail its intended behavior: '..tostring(err))
end
print('Minimap dynamic buttons: '..checks..' checks; 5 client models; 30 layout/scale cases; '..#controls..' harmful controls PASS')
