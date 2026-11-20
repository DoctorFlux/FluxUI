-- Actual producer and five-client fixture; no native pixels, taint or FPS claim.
-- arg1: optional archived CastBar source for the terminal-state negative.
local function read(path)
    local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close()
    return (s:gsub("\r\n","\n"))
end
local checks=0
local function check(v,message) checks=checks+1;assert(v,message) end
local function near(a,b) return type(a)=="number" and math.abs(a-b)<1e-9 end
-- Reuse only the completion fixture helpers, not that test's scenario/assertion
-- body. They load the actual school/trade/theme/cast producers from the shared
-- castbar_school_themes fixture prefix.
local setup=read("tests/castbar_completion_visual.lua")
setup=setup:sub(1,assert(setup:find("-- Same shared producer",1,true))-1)
setup=setup.."\nreturn {scene=scene,snapshot=snapshot,unchanged=unchanged,quiet=quiet,fade=fade,checks=function()return checks end}"
local helpers
if _VERSION=="Lua 5.1" then helpers=assert(loadstring(setup,"@terminal-fixture"))()
else helpers=assert(load(setup,"@terminal-fixture","t",_G))() end
local clients={"live","forever","classic_era","classic_anniversary","classic"}
local units={"player","target","focus","pet","party1"}
local function modern(client) return client=="live" or client=="forever" end
local function sameColor(a,b)
    if not a or not b then return false end
    for i=1,4 do if not near(a[i],b[i]) then return false end end
    return true
end
local function scene(client,unit,trade)
    local s,e,ns,bar,work=helpers.scene(client,unit,{nativeParticles=true,tradeThemes=true,deferTimers=true})
    ns.Border.SetBorderColor=function(_,frame,...) work.paint=work.paint+1;frame.terminalColor={...} end
    for _,key in ipairs({"SetSize","SetWidth","SetHeight","SetPoint","ClearAllPoints","SetAllPoints","SetFrameLevel"}) do
        local original=bar.ShieldOverlay[key]
        if original then bar.ShieldOverlay[key]=function(self,...)
            work.geometry=work.geometry+1;work.geometryLog[#work.geometryLog+1]="shield."..key
            return original(self,...)
        end end
    end
    s.SetDB({castBarThemes=trade and {particles=false} or {enabled=false}})
    return s,e,ns,bar,work
end
local function start(s,bar,unit,id,channel,locked,trade,guid)
    s.casts[unit]={id=id,name=trade and "Crafting" or "Locked spell",channel=channel,locked=locked,trade=trade}
    bar:CastStart(unit,channel,guid or "cast-1")
    check(channel and bar.channeling or not channel and bar.casting,"actual producer starts cast/channel")
end
local function stop(s,bar,unit,id,channel)
    s.Event(bar,channel and "UNIT_SPELLCAST_CHANNEL_STOP" or "UNIT_SPELLCAST_STOP",unit,"cast-1",id)
end
local function normal(bar,icon,body,label)
    check(not bar.notInterruptible,label..": terminal cast clears uninterruptible flag")
    check(not bar.ShieldOverlay:IsShown(),label..": terminal cast hides shield")
    check(sameColor(bar.IconBorder.terminalColor,icon),label..": icon restores normal chrome")
    check(sameColor(bar.BorderFrame.terminalColor,body),label..": body restores normal chrome")
end
local function activeTrade(s,bar)
    local fill,flare,animation
    for _,texture in ipairs(s.textures) do
        if texture.parent==bar.TimerBar and type(texture.atlas)=="string" then
            if texture.atlas:find("Skillbar_Fill_Flipbook_",1,true)==1 then fill=texture
            elseif texture.atlas:find("Skillbar_Flare_",1,true)==1 then flare=texture end
        end
    end
    if fill then for _,group in ipairs(s.animations) do if group.texture==fill then animation=group end end end
    return fill,flare,animation
end
local function quietTrade(s,bar,client,fill,flare,animation,label)
    helpers.quiet(bar,client,label)
    check(sameColor({bar.TimerBar.color[1],bar.TimerBar.color[2],bar.TimerBar.color[3],1},{.12,.86,.15,1}),
        label..": successful cast is exact plain green on every client")
    check(bar:GetStatusBarTexture():GetAlpha()==1,label..": quiet success source is visible")
    check(bar._fluxSchoolCast==nil,label..": successful cast releases theme identity")
    check(not fill or not fill:IsShown(),label..": finished profession flipbook hidden")
    check(not flare or not flare:IsShown(),label..": finished skill-up flare hidden")
    check(not animation or not animation.playing,label..": native repeat animation stopped")
end

for _,client in ipairs(clients) do
    for _,unit in ipairs(units) do
        for _,channel in ipairs({false,true}) do
            local label=client.."/"..unit..(channel and "/channel" or "/cast")
            local s,e,ns,bar,work=scene(client,unit,false)
            -- Capture the actual authored normal chrome, not a duplicated color
            -- formula: client/theme/class policy stays in production.
            start(s,bar,unit,994301,channel,false,false)
            local icon,body=bar.IconBorder.terminalColor,bar.BorderFrame.terminalColor
            check(icon and body and not bar.ShieldOverlay:IsShown(),label..": ordinary cast establishes normal chrome")
            start(s,bar,unit,994301,channel,true,false)
            check(bar.notInterruptible and bar.ShieldOverlay:IsShown(),label..": locked cast shows shield")
            check(sameColor(bar.IconBorder.terminalColor,{1,0,0,1}) and sameColor(bar.BorderFrame.terminalColor,{1,0,0,1}),
                label..": locked cast uses red icon/body chrome")
            local before=helpers.snapshot(s,work)
            stop(s,bar,unit,994301,channel)
            normal(bar,icon,body,label);helpers.quiet(bar,client,label)
            check(bar._fluxSchoolCast==nil,label..": successful cast clears theme identity")
            check(near(bar.holdTime,.35) and not bar.casting and not bar.channeling,label..": success hold unchanged")
            check(channel and bar:GetValue()==0 or not channel and bar:GetValue()==select(2,bar:GetMinMaxValues()),
                label..": channel empty/cast full preserved")
            helpers.unchanged(s,work,before,label.." success")
            local timer=helpers.fade(s,bar,work,label)
            start(s,bar,unit,994301,channel,true,false,"cast-2")
            check(timer.cancelled and bar.notInterruptible and bar.ShieldOverlay:IsShown(),
                label..": rapid new locked cast restores its active shield/red state")
            timer.callback()
            check((bar.casting or bar.channeling) and bar:IsShown(),label..": old fade cannot hide rapid recast")
            ns.CastBar.ResetCastForUnit(bar)
        end

        -- Failed/interrupted locked casts keep their established red terminal
        -- fill and own 1s/.3s timing; they must not pass through success gold.
        for _,event in ipairs({"UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED"}) do
            local label=client.."/"..unit.."/"..event
            local s,e,ns,bar,work=scene(client,unit,false)
            start(s,bar,unit,994302,false,false,false)
            local icon,body=bar.IconBorder.terminalColor,bar.BorderFrame.terminalColor
            start(s,bar,unit,994302,false,true,false)
            s.Event(bar,event,unit,"cast-1",994302)
            normal(bar,icon,body,label)
            check(bar.interrupted and not bar.casting and near(bar.holdTime,1),label..": failure hold preserved")
            if modern(client) then
                check(bar.TimerBar._fluxFillAtlas=="ui-castingbar-interrupted",label..": native red interrupted fill retained")
            else
                check(sameColor({bar.TimerBar.color[1],bar.TimerBar.color[2],bar.TimerBar.color[3],1},{1,0,0,1}),
                    label..": exact Classic red retained")
            end
            local before=helpers.snapshot(s,work)
            stop(s,bar,unit,994302,false)
            helpers.unchanged(s,work,before,label.." late STOP")
            check(bar.interrupted and near(bar.holdTime,1),label..": late STOP does not select success")
            s.Tick(1.01)
            check(bar.fadeOut and near(work.timers[#work.timers].duration,.3),label..": interrupt fade remains .3s")
            work.timers[#work.timers].callback()
            check(not bar:IsShown(),label..": failure fade releases owner")
        end

--- Profession paint is an active-cast feature. Both success and later
--- Apply/Refresh must expose the plain green finish until the next batch.
        local label=client.."/"..unit.."/profession"
        local s,e,ns,bar,work=scene(client,unit,true)
        s.professions[994303]={profession=e.Enum.Profession.Alchemy,professionName="Alchemy"}
        for batch=1,3 do
            start(s,bar,unit,994303,false,true,true)
            local fill,flare,animation=activeTrade(s,bar)
            local native=modern(client) and unit~="party1"
            check((fill~=nil)==native,label..": current unit/client profession support retained")
            if native then
                check(fill:IsShown() and flare:IsShown() and animation and animation.playing,
                    label..": active craft retains native animation/flare")
                check(bar:GetStatusBarTexture():GetAlpha()==0,label..": active profession owns fill")
            end
            local before=helpers.snapshot(s,work)
            stop(s,bar,unit,994303,false)
            quietTrade(s,bar,client,fill,flare,animation,label.." success "..batch)
            check(not bar.notInterruptible and not bar.ShieldOverlay:IsShown(),label..": craft terminal state clears shield")
            helpers.unchanged(s,work,before,label.." finish")
            ns.CastBarThemes.Apply(bar)
            quietTrade(s,bar,client,fill,flare,animation,label.." finished Apply")
            helpers.unchanged(s,work,before,label.." finished Apply")
            local timer=helpers.fade(s,bar,work,label)
            if batch<3 then
                start(s,bar,unit,994303,false,false,true)
                check(timer.cancelled and not bar.holdTime and not bar.fadeOut,label..": next batch clears terminal state")
                if native then check(fill:IsShown() and animation.playing,label..": next batch restarts active art") end
                timer.callback();check(bar.casting and bar:IsShown(),label..": old batch fade cannot hide active craft")
            else
                timer.callback()
                check(not bar:IsShown() and not bar.fadeOut,label..": final batch uses existing owner fade")
            end
        end
        start(s,bar,unit,994303,false,true,true)
        local fill,flare,animation=activeTrade(s,bar)
        s.Event(bar,"UNIT_SPELLCAST_INTERRUPTED",unit,"cast-1",994303)
        check(bar.interrupted and (not animation or not animation.playing) and (not fill or not fill:IsShown())
            and (not flare or not flare:IsShown()),label..": interrupted craft still clears profession art")
        if modern(client) then check(bar.TimerBar._fluxFillAtlas=="ui-castingbar-interrupted",label..": interrupted craft stays red") end
        ns.CastBar.ResetCastForUnit(bar)
    end
end
-- Successful school casts also release their active overlay rather than cover
-- the requested green terminal surface; a stale Apply cannot bring it back.
for _,client in ipairs(clients) do
    for _,unit in ipairs(units) do
        local s,e,ns,bar,work=scene(client,unit,true)
        ns.CastBarSchools.Learn(994305,28)
        start(s,bar,unit,994305,false,true,false)
        local layers={}
        for _,texture in ipairs(s.textures) do
            if texture:IsVisible() and type(texture.path)=="string" and texture.path:find("Fills\\fill_",1,true) then
                layers[#layers+1]=texture
            end
        end
        check(#layers==(unit=="party1" and 0 or 1),client.."/"..unit..": known school active appearance retained")
        local before=helpers.snapshot(s,work)
        stop(s,bar,unit,994305,false)
        quietTrade(s,bar,client,nil,nil,nil,client.."/"..unit.." school success")
        for _,texture in ipairs(layers) do check(not texture:IsShown(),client..": successful school overlay is released") end
        helpers.unchanged(s,work,before,client.." school success")
        ns.CastBarThemes.Apply(bar)
        quietTrade(s,bar,client,nil,nil,nil,client.."/"..unit.." school finished Apply")
        for _,texture in ipairs(layers) do check(not texture:IsShown(),client..": finished Apply cannot revive school art") end
        ns.CastBar.ResetCastForUnit(bar)
    end
end
-- A status bar may change its native texture object when rebound. Finish must
-- restore the old animation mask source and expose the already allocated new
-- source, without treating that replacement as permission to rebuild chrome.
for _,client in ipairs({"live","forever"}) do
    local s,e,ns,bar,work=scene(client,"player",true)
    s.professions[994304]={profession=e.Enum.Profession.Alchemy}
    start(s,bar,"player",994304,false,true,true)
    local fill,flare,animation=activeTrade(s,bar)
    check(fill and animation and animation.playing,client..": replacement probe begins with active profession")
    local old=bar:GetStatusBarTexture()
    local replacement=bar.TimerBar:CreateTexture()
    replacement:SetTexture("preallocated native replacement")
    local set=bar.TimerBar.SetStatusBarTexture
    bar.TimerBar.SetStatusBarTexture=function(self,path,...)
        if path=="Interface\\TargetingFrame\\UI-StatusBar" then self.texture=replacement end
        return set(self,path,...)
    end
    local before=helpers.snapshot(s,work)
    stop(s,bar,"player",994304,false)
    check(bar:GetStatusBarTexture()==replacement and old:GetAlpha()==1 and replacement:GetAlpha()==1,
        client..": finish restores old masked source and exposes new source")
    quietTrade(s,bar,client,fill,flare,animation,client.." replacement success")
    helpers.unchanged(s,work,before,client.." replacement success")
    ns.CastBar.ResetCastForUnit(bar)

    -- Nameplate duration/fade belongs to its native cast owner. The same public
    -- theme callback must retain that existing profession lifecycle.
    start(s,bar,"player",994304,false,false,true)
    fill,flare,animation=activeTrade(s,bar)
    bar._fluxSchoolCast.nameplate=true
    before=helpers.snapshot(s,work)
    ns.CastBarThemes.Finish(bar)
    check(fill:IsShown() and flare:IsShown() and animation.playing and bar:GetStatusBarTexture():GetAlpha()==0,
        client..": nameplate-owned finish retains native profession art")
    ns.CastBarThemes.Apply(bar)
    check(fill:IsShown() and animation.playing,client..": nameplate-owned finished Apply retains art")
    helpers.unchanged(s,work,before,client.." nameplate-owned theme finish")
    ns.CastBar.ResetCastForUnit(bar)
end
print("Cast terminal styles: "..(checks+helpers.checks()).." checks; actual producer in five client models; native appearance/performance deferred")
