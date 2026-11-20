-- Replay the actual WindowMover attachment, posthooks and saved-layout writer
-- alongside the actual original-map owner. This models Lua ownership only;
-- it does not certify native clipping, compositor, secure execution or FPS.
local surfaceSource = (arg and arg[1]) or "Battlezonemap/FluxBattlefieldWorldMap.lua"
local moverSource = (arg and arg[2]) or "WindowMover/Engine.lua"
local originalArg = arg
arg = { surfaceSource, "--fixture" }
local Runtime = assert(loadfile("tests/world_map_surface.lua"))()
arg = originalArg
local checks = 0
local function check(value,label) checks=checks+1; assert(value,label) end
local function Compile(path,env)
    if setfenv then local fn=assert(loadfile(path)); setfenv(fn,env); return fn end
    return assert(loadfile(path,"t",env))
end
local function Setup(client,lateAttach)
    local env,s = Runtime(client)
    s.cursorX,s.cursorY,s.buttonDown = 100,100,true
    s.moverDeferred,s.moverDeferRequests = {},0
    local db = { enabled=true,scaleEnabled=true,savePosition=true,saveScale=true,
        requireModifier=false,clampToScreen=false,snap=0,lock=false,
        frames={ WorldMapFrame={x=16,y=374,scale=.9}, OtherPanel={x=40,y=60,scale=1.1} } }
    s.db=db
    env.FluxOptions={GetWindowMoverDB=function() return db end}
    env.Flux.Combat={InLockdown=function() return s.combat end,
        Defer=function(key,fn) s.moverDeferRequests=s.moverDeferRequests+1; s.moverDeferred[key]=fn end}
    env.GetCursorPosition=function() return s.cursorX,s.cursorY end
    env.IsMouseButtonDown=function() return s.buttonDown end
    env.GetMouseFoci=function() return {} end
    env.GetMouseFocus=function() return nil end
    env.IsShiftKeyDown=function() return true end
    env.IsControlKeyDown=function() return false end
    env.IsAltKeyDown=function() return false end
    local function ProxyAPI(frame,name)
        frame.name=name
        function frame:GetName() return self.name end
        function frame:GetObjectType() return "Frame" end
        function frame:SetMovable(value) self.movable=value end
        function frame:SetClampedToScreen(value) self.clamped=value end
        function frame:SetUserPlaced(value) self.userPlaced=value end
        return frame
    end
    local create = env.CreateFrame
    env.CreateFrame=function(kind,name,parent,template) return ProxyAPI(create(kind,name,parent,template),name) end
    ProxyAPI(s.world,"WorldMapFrame")
    s.other=ProxyAPI(s.Frame(env.UIParent),"OtherPanel")
    env.OtherPanel=s.other
    local mover={IsFrame=function(frame) return type(frame)=="table" and frame.SetPoint~=nil end,
        Resolve=function(name) return env[name] end,ShouldSkip=function() return false end,
        IsBlacklisted=function() return false end,FindDragHandles=function(frame) return {frame} end}
    env.Flux.WindowMover=mover
    Compile(moverSource,env)("_FluxUI",{Flux=env.Flux})
    s.mover=mover
    if not lateAttach then check(mover.Attach({name="WorldMapFrame",drag="frame"}),client.." actual mover attaches original map") end
    check(mover.Attach({name="OtherPanel",drag="frame"}),client.." actual mover attaches unrelated panel")
    return env,s
end
local function Writes(frame)
    return (frame.geometryWrites or 0)+(frame.ScrollContainer and frame.ScrollContainer.geometryWrites or 0)
end
local function Saved(frame,env,record)
    local p,r,rp,x,y=frame:GetPoint(1)
    return frame:GetNumPoints()==1 and p=="BOTTOMLEFT" and r==env.UIParent and rp=="BOTTOMLEFT"
        and x==record.x and y==record.y and math.abs(frame:GetScale()-record.scale)<.000001
end
local function Hosted(s,env)
    local world=s.world
    local host=world:GetParent()
    if not s.bridge:IsEmbedded() or host==env.UIParent or world:GetNumPoints()~=1 then return false end
    local p,r,rp,x,y=world:GetPoint(1)
    local scale=math.min(host:GetWidth()/world:GetWidth(),host:GetHeight()/world:GetHeight())
    return p=="TOPLEFT" and r==host and rp=="TOPLEFT" and math.abs(world:GetScale()-scale)<.000001
        and math.abs(x-(host:GetWidth()/scale-world:GetWidth())/2)<.000001
        and math.abs(y+(host:GetHeight()/scale-world:GetHeight())/2)<.000001
end
local function SameRecord(record,x,y,scale)
    return record.x==x and record.y==y and record.scale==scale
end
for _,client in ipairs({"retail","forever","classic","era","anniversary"}) do
    for _,lateAttach in ipairs({false,true}) do
        local env,s=Setup(client,lateAttach)
        local world,mover=s.world,s.mover
        local record=s.db.frames.WorldMapFrame
        local x,y,scale=record.x,record.y,record.scale
        if not lateAttach then check(Saved(world,env,record),client.." actual mover restores normal saved map coordinates before takeover") end
        local pin=s.arbitrary[4]
        local pinOwner,marker,handler=pin:GetParent(),pin.marker,pin:GetScript("OnUpdate")
        s.bridge:Activate(s.battlefield)
        check(not s.bridge:IsEmbedded() and world:IsShown() and world:GetAlpha()==0,client.." original map preparation remains the owner before deferred layout")
        if lateAttach then
            check(mover.Attach({name="WorldMapFrame",drag="frame"}),client.." actual mover can attach while source preparation already owns layout")
        end
        local writes,deferred=Writes(world),s.moverDeferRequests
        for _=1,100 do mover.Apply("WorldMapFrame",world) end
        check(Writes(world)==writes and s.moverDeferRequests==deferred,client.." prepared source rejects real saved-layout applies without deferred jobs")
        s:Flush()
        check(Hosted(s,env),client.." actual mover posthooks cannot overwrite embedded source with saved BOTTOMLEFT UIParent placement")
        check(pin:GetParent()==pinOwner and pin.marker==marker and pin:GetScript("OnUpdate")==handler,
            client.." mover coordination preserves original addon pin ownership and callback")
        local pinPixels=pin:GetWidth()*pin:GetEffectiveScale()
        local frames,hooks,scans,schedules=#s.frames,#s.hooks,s.scans,s.timerSchedules
        writes,deferred=Writes(world),s.moverDeferRequests
        for _=1,1000 do mover.Apply("WorldMapFrame",world); s.bridge:Sync() end
        s:Flush()
        check(Writes(world)==writes and s.timerSchedules==schedules and s.moverDeferRequests==deferred,
            client.." 1000 hosted applies and syncs add no geometry writes, timers or deferred mover jobs")
        check(Saved(s.other,env,s.db.frames.OtherPanel),client.." unrelated saved window remains under the actual mover")
        s.other:ClearAllPoints(); s.other:SetPoint("CENTER",env.UIParent,"CENTER",0,0)
        check(Saved(s.other,env,s.db.frames.OtherPanel),client.." unrelated native layout still triggers its actual mover posthook")
        for _,button in ipairs({"LeftButton","RightButton"}) do
            local onMouseDown=world:GetScript("OnMouseDown")
            check(type(onMouseDown)=="function",client.." actual mover drag/scale handler is installed")
            onMouseDown(world,button)
            s.cursorX,s.cursorY=s.cursorX+80,s.cursorY+40
            mover._OnProxyUpdate()
            check(Hosted(s,env) and SameRecord(record,x,y,scale),client.." hosted mover gesture cannot move source or save field dimensions")
        end
        check(#s.frames==frames and #s.hooks==hooks and s.scans==scans,
            client.." hosted gesture rejection allocates no proxy, hooks or canvas scans")
        env.ToggleWorldMap(); s:Flush()
        check(not s.bridge:IsEmbedded() and world:IsShown() and Saved(world,env,record),
            client.." normal large map regains actual saved position and scale")
        world:ClearAllPoints(); world:SetPoint("CENTER",env.UIParent,"CENTER",0,0)
        check(Saved(world,env,record),client.." normal large-map SetPoint still runs saved-layout posthook")
        env.ToggleWorldMap(); s:Flush()
        check(Hosted(s,env) and math.abs(pin:GetWidth()*pin:GetEffectiveScale()-pinPixels)<.000001,
            client.." closing saved large map restores uniform original pin scale")
        s.combat=true
        s.bridge:Deactivate(); s:Flush()
        writes,deferred=Writes(world),s.moverDeferRequests
        for _=1,100 do mover.Apply("WorldMapFrame",world) end
        mover._OnProxyUpdate()
        check(Writes(world)==writes and s.moverDeferRequests==deferred,
            client.." requested-off combat-deferred source still owns its native layout without mover jobs")
        check(SameRecord(record,x,y,scale),client.." deferred release preserves saved normal-map data")
        s.combat=false; s:Event("PLAYER_REGEN_ENABLED")
        check(not s.bridge:IsEmbedded() and world:GetParent()==env.UIParent and not world:IsShown(),client.." combat exit releases original source to normal owner")
        mover.Apply("WorldMapFrame",world)
        check(Saved(world,env,record),client.." disabled map surface allows actual saved normal-map layout")
        check(#s.frames==frames and #s.hooks==hooks and s.scans==scans,
            client.." combined mover/surface lifecycle keeps hosts and permanent hooks bounded")
        check(s.db.frames.WorldMapFrame==record and SameRecord(record,x,y,scale),client.." all ownership transfers preserve saved record identity and values")
    end
end

-- A gesture can start while the ordinary map is open, then remain active when
-- another native path closes it. The next actual proxy update must stop before
-- writing the newly hosted source or saving its field-space position/scale.
for _,client in ipairs({"retail","forever","classic","era","anniversary"}) do
    for _,button in ipairs({"LeftButton","RightButton"}) do
        local env,s=Setup(client,false)
        local world,mover=s.world,s.mover
        world:Show()
        world:GetScript("OnMouseDown")(world,button)
        local record=s.db.frames.WorldMapFrame
        local x,y,scale=record.x,record.y,record.scale
        s.bridge:Activate(s.battlefield); s:Flush()
        check(not s.bridge:IsEmbedded() and world:IsShown(),client.." active normal-map gesture retains native large-map priority")
        env.HideUIPanel(world); s:Flush()
        check(Hosted(s,env),client.." native close hands an active normal-map gesture's source to the field owner")
        local frames,hooks=#s.frames,#s.hooks
        local writes,deferred=Writes(world),s.moverDeferRequests
        s.cursorX,s.cursorY=s.cursorX+140,s.cursorY+90
        mover._OnProxyUpdate()
        check(Writes(world)==writes and s.moverDeferRequests==deferred and Hosted(s,env),
            client.." active "..button.." stops before writing the newly hosted original source")
        check(SameRecord(record,x,y,scale),client.." active "..button.." takeover saves neither field position nor field scale")
        s.bridge:Deactivate(); s:Flush(); mover.Apply("WorldMapFrame",world)
        check(Saved(world,env,record),client.." stopped gesture leaves normal map saved layout unchanged")
        check(#s.frames==frames and #s.hooks==hooks,client.." stopping takeover gesture reuses existing proxies and permanent hooks")
    end
end
print("Original world-map / actual WindowMover ownership PASS: "..checks.." checks")
