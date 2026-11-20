-- Actual start/event/update/fade producer with the existing five-client fixture.
-- This verifies the authored contract; native appearance/FPS remain untested.
-- Optional arg1 replaces only FluxCastBar.lua for an archived negative control.
local function read(path)
    local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close()
    return (s:gsub("\r\n","\n"))
end
local checks=0
local function check(value,message) checks=checks+1;assert(value,message) end
local function near(a,b) return type(a)=="number" and math.abs(a-b)<1e-9 end
local source=read("tests/castbar_school_themes.lua")
source=source:sub(1,assert(source:find("-- Profession artwork must follow real production CastStart/Finish/Reset paths,",1,true))-1)
source=source:gsub('pet="PetFrame"','pet="PetFrame",party1="PartyFrame"')
if arg and arg[1] then
    local n
    source,n=source:gsub('loadAddon%("UnitFrames/FluxCastBar.lua",%s*env,%s*ns%)',function()
        return "loadAddon("..string.format("%q",arg[1])..",env,ns)"
    end)
    assert(n==1,"replace exactly the actual cast producer")
end
local make
if _VERSION=="Lua 5.1" then make=assert(loadstring(source.."\nreturn fixture","@completion-fixture"))()
else make=assert(load(source.."\nreturn fixture","@completion-fixture","t",_G))() end
local clients={"live","forever","classic_era","classic_anniversary","classic"}
local units={"player","target","focus","pet","party1"}
local plain="Interface\\TargetingFrame\\UI-StatusBar"
local function modern(client) return client=="live" or client=="forever" end
local function scene(client,unit,capabilities)
    local s,e,ns=make(client,capabilities or {nativeParticles=true,deferTimers=true})
    local work={geometry=0,geometryLog={},troughAnchors=0,border=0,paint=0,timers={},fades={}}
    for _,key in ipairs({"ApplyTo","SetBorderColor","SetBackdropColor","HideBackground","ShowBackground"}) do
        ns.Border[key]=function()
            if key=="ApplyTo" then work.border=work.border+1 else work.paint=work.paint+1 end
        end
    end
    e.C_Timer.NewTimer=function(duration,fn)
        local timer={duration=duration,callback=fn,cancelled=false}
        function timer:Cancel() self.cancelled=true end
        work.timers[#work.timers+1]=timer;return timer
    end
    e.UIFrameFadeOut=function(frame,duration,from,to)
        work.fades[#work.fades+1]={frame=frame,duration=duration,from=from,to=to}
    end
    e.UIFrameFadeRemoveFrame=function()end
    local bar=s.NewBar(unit)
    -- Count the real fill/icon/chrome setters, including width/height which the
    -- general school fixture does not count. Text layout is a separate owner.
    for _,object in ipairs({bar,bar.TimerBar,bar:GetStatusBarTexture(),bar.IconFrame,bar.Icon,
        bar.IconBorder,bar.BorderFrame,bar.bg,bar.HeaderCover,bar.FillEffectClip,bar.FillEffectHost}) do
        for _,key in ipairs({"SetSize","SetWidth","SetHeight","SetPoint","ClearAllPoints",
            "SetAllPoints","SetParent","SetFrameLevel","SetFrameStrata"}) do
            local original=object[key]
            if original then object[key]=function(self,...)
                if self==bar.bg and (key=="ClearAllPoints" or key=="SetPoint") then
                    -- Existing CastStop always restores the ordinary trough's
                    -- CENTER anchor, including non-empowered casts.
                    work.troughAnchors=work.troughAnchors+1
                else work.geometry=work.geometry+1;work.geometryLog[#work.geometryLog+1]=key end
                return original(self,...)
            end end
        end
    end
    return s,e,ns,bar,work
end
local function start(s,bar,unit,id,channel,trade,name,guid)
    s.casts[unit]={id=id,channel=channel,trade=trade,name=name or "Conjure Water"}
    bar:CastStart(unit,channel,guid or "cast-1")
    check(channel and bar.channeling or not channel and bar.casting,"actual cast producer starts")
end
local function stop(s,bar,unit,id,channel,guid)
    s.Event(bar,channel and "UNIT_SPELLCAST_CHANNEL_STOP" or "UNIT_SPELLCAST_STOP",unit,guid or "cast-1",id)
end
local function snapshot(s,work)
    local scripts={}
    for _,frame in ipairs(s.frames) do scripts[frame]=frame.scripts.OnUpdate or false end
    return {geometry=work.geometry,border=work.border,frames=#s.frames,textures=#s.textures,
        animations=#s.animations,timers=#work.timers,queued=#s.timers,scripts=scripts}
end
local function unchanged(s,work,before,label)
    check(work.geometry==before.geometry,label..": no fill/icon/chrome geometry setters ("..
        table.concat(work.geometryLog,",",before.geometry+1)..")")
    check(work.border==before.border,label..": no border reconstruction request")
    check(#s.frames==before.frames and #s.textures==before.textures and #s.animations==before.animations,
        label..": no new frames, textures or animation groups")
    check(#s.timers==before.queued,label..": no additional deferred jobs")
    for _,frame in ipairs(s.frames) do
        check((frame.scripts.OnUpdate or false)==before.scripts[frame],label..": no new per-frame driver")
    end
end
local function quiet(bar,client,label)
    local texture=bar:GetStatusBarTexture()
    check(texture.path==plain,label..": quiet plain success texture, not the striped native full atlas (got "..tostring(texture.path)..")")
    check(bar.TimerBar._fluxFillAtlas==nil,label..": no native full atlas bound")
    local expected={.12,.86,.15}
    for i=1,3 do check(near(bar.TimerBar.color[i],expected[i]),label..": authored success color "..i) end
    check(texture.uv[1]==0 and texture.uv[2]==1 and texture.uv[3]==0 and texture.uv[4]==1,
        label..": plain fill uses its whole texture")
end
local function held(bar,channel,label)
    check(not bar.casting and not bar.channeling and near(bar.holdTime,.35) and not bar.fadeOut,label..": unchanged .35 second hold")
    local _,maximum=bar:GetMinMaxValues()
    check(channel and bar:GetValue()==0 or not channel and bar:GetValue()==maximum,label..": cast stays full, channel empty")
    check(bar.Time.text=="" and not bar.Spark:IsShown(),label..": time cleared and spark hidden")
    check(bar.Text.text=="Conjure Water" and bar:IsShown() and bar:GetAlpha()==1,label..": name and owner retained during hold")
end
local function fade(s,bar,work,label)
    local count=#work.timers
    s.Tick(.34)
    check(bar.holdTime and not bar.fadeOut and #work.timers==count,label..": no early fade/timer")
    s.Tick(.02)
    local timer=work.timers[#work.timers];local native=work.fades[#work.fades]
    check(bar.fadeOut and not bar.holdTime and #work.timers==count+1,label..": existing one-shot fade starts once")
    check(timer and near(timer.duration,.75) and native and native.frame==bar and near(native.duration,.75)
        and native.from==1 and native.to==0,label..": unchanged .75 second native fade")
    s.Tick(.1)
    check(#work.timers==count+1,label..": fade creates no extra timer")
    return timer
end

-- Same shared producer for every unit consumer. Disabled school colors,
-- disabled themes, and unknown-school casts each expose the plain success fill.
for _,client in ipairs(clients) do
    for _,unit in ipairs(units) do
        for _,mode in ipairs({"themes-off","colors-off","unmapped"}) do
            for _,channel in ipairs({false,true}) do
                local s,e,ns,bar,work=scene(client,unit)
                local options={particles=false,halo=false,edge=false,backdrop=false}
                if mode=="themes-off" then options.enabled=false end
                if mode=="colors-off" then options.colors=false;ns.CastBarSchools.Learn(994123,4) end
                s.SetDB({castBarThemes=options})
                start(s,bar,unit,994123,channel)
                local before=snapshot(s,work);local revision=bar._fluxTimerRevision;local icon=bar.Icon.path
                local label=client.."/"..unit.."/"..mode..(channel and "/channel" or "/cast")
                stop(s,bar,unit,994123,channel)
                quiet(bar,client,label);held(bar,channel,label)
                check(bar._fluxTimerRevision==revision+(channel and 0 or 1),label..": duration detach exactly once for ordinary cast")
                check(bar.Icon.path==icon,label..": icon artwork unchanged")
                unchanged(s,work,before,label)
                check(#work.timers==before.timers,label..": no timer before hold elapses")
                local completed=snapshot(s,work)
                stop(s,bar,unit,994123,channel)
                unchanged(s,work,completed,label.." duplicate STOP")
                check(#work.timers==completed.timers and near(bar.holdTime,.35),label..": duplicate STOP does not restart finish")
                local timer=fade(s,bar,work,label)
                unchanged(s,work,before,label.." hold/fade")
                timer.callback()
                check(not bar:IsShown() and not bar.fadeOut and not bar.fadeTimer,label..": fade hides/releases owner")
            end
        end
    end
end

-- New casts clear completion immediately. A captured stale fade/event cannot
-- hide or finish a replacement cast. Reset and interrupts retain their owners.
for _,client in ipairs(clients) do
    for _,unit in ipairs(units) do
        local s,e,ns,bar,work=scene(client,unit)
        s.SetDB({castBarThemes={enabled=false}})
        start(s,bar,unit,994123,false);stop(s,bar,unit,994123,false)
        local old=fade(s,bar,work,client.." rapid recast")
        start(s,bar,unit,994124,false,false,"Replacement cast","cast-2")
        check(old.cancelled and not bar.holdTime and not bar.fadeOut and not bar.fadeTimer,client..": recast cancels finish/fade")
        check(bar.TimerBar._fluxFillAtlas==(modern(client) and "ui-castingbar-filling-standard" or nil),client..": recast restores filling art")
        local r,g,b=bar.TimerBar.color[1],bar.TimerBar.color[2],bar.TimerBar.color[3]
        check(modern(client) and r==1 and g==1 and b==1 or not modern(client) and r==1 and g==.95 and b==0,
            client..": recast restores filling color")
        old.callback()
        check(bar.casting and bar:IsShown() and bar.Text.text=="Replacement cast",client..": stale fade cannot hide replacement")
        s.Event(bar,"UNIT_SPELLCAST_STOP",unit,"cast-1",994123)
        check(bar.casting,client..": stale event cannot finish replacement")
        ns.CastBar.ResetCastForUnit(bar)
        check(not bar:IsShown() and not bar.holdTime and not bar.fadeOut and not bar._fluxSchoolCast,client..": reset clears presentation")
        check(bar.Text.text=="" and bar.Time.text=="" and not bar.IconFrame:IsShown(),client..": reset clears labels/icon")
        start(s,bar,unit,994123,false)
        s.Event(bar,"UNIT_SPELLCAST_INTERRUPTED",unit,"cast-1",994123)
        check(bar.interrupted and not bar.casting and near(bar.holdTime,1),client..": interruption keeps own hold/state")
        if modern(client) then
            check(bar.TimerBar._fluxFillAtlas=="ui-castingbar-interrupted",client..": interrupt keeps native red art")
        else
            check(bar:GetStatusBarTexture().path==plain and bar.TimerBar.color[1]==1 and bar.TimerBar.color[2]==0
                and bar.TimerBar.color[3]==0,client..": interrupt keeps exact Classic red")
        end
        local before=snapshot(s,work)
        stop(s,bar,unit,994123,false)
        unchanged(s,work,before,client.." interrupted late STOP")
        check(bar.interrupted and near(bar.holdTime,1),client..": late success cannot paint interrupt gold")
        ns.CastBar.ResetCastForUnit(bar)
    end
end

-- Successful school/profession casts release their active art and use the same
-- green finish until the next cast; native nameplate owners remain separate.
local function schoolLayers(s)
    local layers={}
    for _,texture in ipairs(s.textures) do
        if texture:IsVisible() and type(texture.path)=="string" and texture.path:find("Fills\\fill_",1,true) then
            layers[#layers+1]=texture
        end
    end
    return layers
end
local function tradeFill(s,bar)
    for _,texture in ipairs(s.textures) do
        if texture:IsVisible() and texture.parent==bar.TimerBar and texture.atlas
            and texture.atlas:find("Skillbar_Fill_Flipbook_",1,true)==1 then return texture end
    end
end
for _,client in ipairs(clients) do
    local s,e,ns,bar,work=scene(client,"player",{nativeParticles=true,tradeThemes=true,deferTimers=true})
    s.SetDB({castBarThemes={particles=false}})
    ns.CastBarSchools.Learn(994125,28)
    start(s,bar,"player",994125,false)
    local layers=schoolLayers(s)
    check(#layers==1 and bar:GetStatusBarTexture():GetAlpha()==0,client..": school owns visible fill")
    local before=snapshot(s,work)
    stop(s,bar,"player",994125,false)
    quiet(bar,client,client.." school underlay")
    check(not bar._fluxSchoolCast and not layers[1]:IsVisible()
        and bar:GetStatusBarTexture():GetAlpha()==1,client..": green success replaces active school art")
    unchanged(s,work,before,client.." school finish")
    local timer=fade(s,bar,work,client.." school");timer.callback()
    check(not layers[1]:IsVisible() and bar:GetStatusBarTexture():GetAlpha()==1,client..": hide restores school source")
    s.professions[994126]={profession=e.Enum.Profession.Alchemy,professionName="Alchemy"}
    for batch=1,3 do
        start(s,bar,"player",994126,false,true)
        local fill=tradeFill(s,bar)
        check((fill~=nil)==modern(client),client..": profession capability retained")
        local animation=modern(client) and s.animations[#s.animations] or nil
        before=snapshot(s,work)
        stop(s,bar,"player",994126,false)
        if modern(client) then
            check(not tradeFill(s,bar) and bar:GetStatusBarTexture():GetAlpha()==1 and not animation.playing,
                client..": profession finish releases active animation")
        end
        quiet(bar,client,client.." profession finish")
        unchanged(s,work,before,client.." batch finish "..batch)
        if batch<3 then
            local old=fade(s,bar,work,client.." profession batch")
            start(s,bar,"player",994126,false,true)
            check(old.cancelled and not bar.holdTime and not bar.fadeOut,client..": next batch clears finish")
            old.callback();check(bar.casting and bar:IsShown(),client..": old batch fade cannot hide craft")
        else
            timer=fade(s,bar,work,client.." final profession batch");timer.callback()
            check(not bar:IsShown() and not tradeFill(s,bar) and (not animation or not animation.playing),
                client..": final batch releases art with owner fade")
        end
    end
end
print("Cast completion visual: "..checks.." checks; actual producer in five client models; native appearance/performance deferred")
