-- Complete production range service and painters; native APIs/frames are models.
-- Labels describe simulated context only, never native secure VM/FPS acceptance.
local sourceRoot = arg[1]
local function read(path)
    local f = assert(io.open((sourceRoot and sourceRoot .. "/" or "") .. path, "rb"))
    local body = f:read("*a"); f:close(); return body
end
local checks, failures, edges = 0, 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; if failures <= 30 then print("FAIL " .. label) end end
end
local function fixture(client)
    local s = { now = 10, combat = false, range = true, usable = true, mana = false,
        units = { target = true, mouseover = true, focus = true }, events = {}, queries = 0, writes = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env; env.FluxButton = {}
    s.mask=0
    env.IsShiftKeyDown=function()return s.mask%2==1 end
    env.IsControlKeyDown=function()return math.floor(s.mask/2)%2==1 end
    env.IsAltKeyDown=function()return s.mask>=4 end
    env.CreateFrame=function()
        local frame={scripts={}};s.modFrame=frame
        function frame:RegisterEvent()end
        function frame:SetScript(k,v)self.scripts[k]=v end
        return frame
    end
    env.GetTime = function() return s.now end
    env.InCombatLockdown = function() return s.combat end
    env.UnitExists = function(u) return s.units[u] end
    env.UnitCanAttack = function(_, u) return u == "target" end
    env.UnitCanAssist = function(_, u) return u ~= "target" end
    env.HasAction = function() return true end
    env.GetActionInfo = function() return "spell", 101 end
    env.IsActionInRange = function() s.queries = s.queries + 1; return s.range end
    local flux = { Safecall=function(fn,...)return fn(...)end, Client = { key = client }, EBS = { buttons = {}, badges = {} },
        Bars = { COLOR = { usable = {1,1,1}, mana = {.5,.5,1}, unusable = {.4,.4,.4}, outOfRange = {.8,.1,.1} } },
        Events = { Register = function(e, fn) s.events[e] = fn end },
        Ticker = { Add = function(_, fn) s.tick = fn end, Remove = function() s.tick = nil end },
        MouseoverCast = { IsActive = function() return s.mouseover end },
        Spell = { GetOverrideSpell = function(id) return id end,
            IsInRange = function(id, u) s.queries = s.queries + 1; s.probeID, s.probeUnit = id, u; return s.range end,
            IsUsable = function() return s.usable, s.mana end },
        Item = { IsInRange = function(id, u) s.queries = s.queries + 1; s.probeID, s.probeUnit = id, u; return s.range end,
            CanCheckRange = function() return not s.blocked end,
            IsUsable = function() return s.usable, s.mana end,
            IsConsumable = function() return false end, UsesConsumableCharges = function() return false end } }
    flux.Action = { HasAction = function() return true end, IsUsable = function() return s.usable, s.mana end }
    env.Flux = flux
    for _, path in ipairs({ "Core/Engine/Modifier.lua", "Core/Engine/Range.lua", "ExtraButtonSystem/Engine/Paint.lua", "Bars/Paint.lua" }) do
        assert(load(read(path), "@" .. path, "t", env))("_FluxUI", { Flux = flux })
    end
    flux.Range.Start()
    local function icon()
        return { SetVertexColor = function(self, r,g,b) self.r,self.g,self.b=r,g,b; s.writes=s.writes+1 end,
            SetDesaturated = function(self, v) self.desat = v end }
    end
    function s.extra(id)
        return { ActionType="spell", ActionValue=id or 101, SpellId=id or 101, Widget={},
            WIcon=icon(), WNormalTexture={SetVertexColor=function() end}, categoryScope="account" }
    end
    function s.bar()
        return { slot=1, widget={}, WIcon=icon() }
    end
    function s.color(btn,r,g,b,label)
        check(btn.WIcon.r==r and btn.WIcon.g==g and btn.WIcon.b==b, client.." "..label)
    end
    function s.invalidate() s.now=s.now+.001 end
    return s,flux
end
for _, client in ipairs({"live","forever","classic_era","classic_anniversary"}) do
    local s,f=fixture(client);local p,b,r=f.EBS.Paint,f.Bars.Paint,f.Range
    local extra,bar=s.extra(),s.bar()
    p.UpdateUsable(extra);b.UpdateUsable(bar)
    s.range=false;r.Invalidate();p.UpdateRange(extra);b.UpdateRange(bar)
    s.color(extra,.8,.1,.1,"range red");s.color(bar,.8,.1,.1,"bar range red")
    s.range=true;r.Invalidate();p.UpdateRange(extra);b.UpdateRange(bar)
    s.color(extra,1,1,1,"same-frame invalidation refreshes memo")
    s.color(bar,1,1,1,"shared bar memo refreshes same frame")
    local probes=s.queries
    for i=1,1000 do s.events.UPDATE_MOUSEOVER_UNIT();r.CheckSpell(101,"target") end
    check(s.queries==probes,client.." mouseover churn retains unchanged target's shared memo")
    -- A utility is stored as macrotext but executes its own secure unit.
    extra.ActionType,extra.MacroMode,extra._fluxUtilityGetEntry="macrotext","spell",function()end
    extra.Widget.GetAttribute=function()return "mouseover"end;s.mouseover=true;s.invalidate()
    p.UpdateRange(extra);check(s.probeUnit=="mouseover",client.." utility ranges its actual hovercast unit")
    extra._fluxUtilityGetEntry=nil;extra.MacroTarget="focus";s.invalidate();p.UpdateRange(extra)
    check(s.probeUnit=="focus",client.." ordinary macro keeps explicit target over hub unit")
    extra.MacroTarget="player";s.invalidate();p.UpdateRange(extra)
    check(s.probeUnit=="target",client.." ordinary self macro ignores stale hovercast hub unit")
    f.Bars.Hosts={ForSlot=function()return {bar}end}
    bar.widget.GetAttribute=function()return "mouseover"end
    bar._outOfRange=false;b.ApplySlotRange(1,false,true)
    check(bar._outOfRange==false,client.." native target range payload does not overwrite hovercast range")
    bar.widget.GetAttribute=nil
    -- Friendly item checks become unavailable in combat. Preserve only this
    -- same face/unit's established state, never another chord's red tint.
    local item=s.extra();item.ActionType,item.ItemId="item",201
    s.range=false;s.invalidate();p.UpdateRange(item);s.color(item,.8,.1,.1,"item starts red")
    s.blocked=true;p.UpdateRange(item);s.color(item,.8,.1,.1,"same blocked item preserves tint")
    item.ItemId,item.ActionValue=202,202;p.UpdateRange(item)
    s.color(item,1,1,1,"new blocked item does not inherit previous action range")
    s.blocked=false;s.range=false;s.invalidate();p.UpdateRange(item)
    s.blocked=true;s.events.PLAYER_TARGET_CHANGED();p.UpdateRange(item)
    s.color(item,1,1,1,"new target does not inherit blocked previous-target range")
    -- Unknown usability is retained for the same action, cleared on identity
    -- replacement, and independent of a temporary range overlay.
    s.blocked=false;s.range=true;s.usable=false;s.mana=false;s.invalidate()
    extra=s.extra();p.UpdateUsable(extra);s.color(extra,.4,.4,.4,"known unusable darkens")
    s.usable=nil;s.mana=nil;p.UpdateUsable(extra);s.color(extra,.4,.4,.4,"same unknown keeps prior unusable")
    extra.SpellId,extra.ActionValue=102,102;p.UpdateUsable(extra);s.color(extra,1,1,1,"new unknown spell does not inherit dark state")
    s.usable=false;s.mana=false;b.UpdateUsable(bar);s.range=false;s.invalidate();b.UpdateRange(bar)
    s.usable=nil;s.mana=nil;s.range=true;s.invalidate();b.UpdateRange(bar)
    s.color(bar,.4,.4,.4,"unknown bar restores usable layer after red clears")
    -- All eight physical chord states, overlapping rapid presses/releases,
    -- target hops and combat/context transitions; final API truth wins.
    extra=s.extra()
    f.Modifier.Register("range.test",function() extra.SpellId,extra.ActionValue=101+s.mask,101+s.mask end)
    local startEdges=edges
    for _,context in ipairs({"world","party","dungeon","raid"}) do
      for _,combat in ipairs({false,true}) do
        s.combat=combat
        for frame=1,512 do
          for edge=1,33 do
            local bit=({1,2,1,4,1,2,1,4})[(edge-1)%8+1]
            s.mask=math.floor(s.mask/bit)%2==1 and s.mask-bit or s.mask+bit
            edges=edges+1
            s.modFrame.scripts.OnEvent(s.modFrame,"MODIFIER_STATE_CHANGED","LALT",edge%2)
          end
          s.modFrame.scripts.OnUpdate(s.modFrame,1/120)
          check(extra.SpellId==101+s.mask and not f.Modifier.IsArmed(),client.." physical API truth selects final face and parks driver")
          s.usable=frame%3~=0;s.mana=frame%5==0;s.range=frame%7~=0;s.invalidate()
          p.UpdateRange(extra);p.UpdateUsable(extra)
          b.UpdateRange(bar);b.UpdateUsable(bar)
          local rr,gg,bb=1,1,1
          if not s.range then rr,gg,bb=.8,.1,.1 elseif s.mana then rr,gg,bb=.5,.5,1 elseif not s.usable then rr,gg,bb=.4,.4,.4 end
          s.color(extra,rr,gg,bb,context.." rapid final extra state")
          s.color(bar,rr,gg,bb,context.." rapid final bar state")
          local before=s.queries
          for i=1,64 do r.CheckSpell(101+s.mask,"target") end
          check(s.queries==before,client.." shared same-frame range memo bounds 64 duplicate consumers")
          local writes=s.writes;p.UpdateUsable(extra);b.UpdateUsable(bar)
          check(s.writes==writes,client.." unchanged palette performs no extra vertex-color writes")
        end
      end
    end
    -- Exercise the real shared ticker: per-host range demand must remain true
    -- while it throttles a continuous mouseover stream to bounded catch-up.
    local sweeps,lastSweep=0,0
    r.RegisterSweep("bars",function()return b.NeedsRange(bar)end,function()
        sweeps=sweeps+1;b.UpdateRange(bar);b.UpdateUsable(bar)
    end)
    s.usable,s.mana=true,false
    for frame=1,1200 do
        s.now=s.now+1/120;s.range=math.floor(frame/120)%2==0
        s.events.UPDATE_MOUSEOVER_UNIT()
        local before=sweeps;assert(s.tick,"range ticker must stay armed during visible hop stream")(1/120)
        if sweeps>before then
            lastSweep=frame
            s.color(bar,s.range and 1 or .8,s.range and 1 or .1,s.range and 1 or .1,"bounded full-ticker catch-up paints current range")
        end
        check(frame-lastSweep<=63,client.." continuous hop stream cannot bypass bounded catch-up")
    end
    check(sweeps>=18 and sweeps<=21,client.." ten-second cursor storm bounds range sweeps near 2Hz")
    s.units.target=false;r.Sync();check(not r.IsArmed()and s.tick==nil,client.." no targets parks shared ticker")
    print(("RANGE_USABILITY client=%s rapid_edges=%d hop_sweeps=%d checks=%d failures=%d"):format(client,edges-startEdges,sweeps,checks,failures))
end
print(("RANGE_USABILITY SUMMARY checks=%d failures=%d modeled_edges=%d native_VM_pixels_FPS=NOT_RUN"):format(checks,failures,edges))
os.exit(failures>0 and 1 or 0)
