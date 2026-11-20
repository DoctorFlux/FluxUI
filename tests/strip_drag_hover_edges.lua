-- Actual held-cursor enter/leave behavior, without an action-slot change.
-- Optional arguments point to archived UnifiedBorder.lua and Bars/Layout.lua.
local function read(path)
    local f = assert(io.open(path, "rb"))
    local source = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return source
end
local function section(text, first, last)
    local start = assert(text:find(first, 1, true))
    return text:sub(start, assert(text:find(last, start + #first, true)) - 1)
end
local stripTest = read("tests/bars_strip_layout_work.lua")
local fixtureSource = stripTest:sub(1, assert(stripTest:find("local candidate=true;local checks=0", 1, true)) - 1)
local outer = setmetatable({ arg = {} }, { __index = _G })
local loadFixture = assert(load(fixtureSource .. "\nreturn fixture", "@action-strip-widget-fixture", "t", outer))
local fixture = loadFixture()
local checks = 0
local function check(ok, why)
    checks = checks + 1
    assert(ok, why)
end

local function run(path, modern, slotReplay)
    local f = fixture(true)
    local bars, env = f.B, f.env
    env.Flux = f.flux
    local strip = bars.Strip
    local tick
    f.flux.Ticker = {
        Add = function(key, fn) if key == "bars.layout.drag" then tick = fn end end,
        Remove = function(key) if key == "bars.layout.drag" then tick = nil end end,
    }
    for _, frame in ipairs({strip.frame, strip.sensing}) do
        frame.scripts = {}
        function frame:HookScript(name, fn)
            check(not self.scripts[name], "each hover edge is hooked once")
            self.scripts[name] = fn
        end
    end
    env.FluxActionStrip, env.FluxActionStripSensing = strip.frame, strip.sensing
    local commitPose
    local originalCommit = env.FluxBorder.Junctions.CommitLayout
    env.FluxBorder.Junctions.CommitLayout = function(self, pose)
        commitPose = pose
        originalCommit(self)
    end
    local refreshKeys = bars.Hosts.RefreshKeys
    local hoverKeys
    bars.Hosts.RefreshKeys = function(hoverOnly)
        hoverKeys = hoverOnly
        return refreshKeys(hoverOnly)
    end
    env.NamedFrame = function(...) for _, key in ipairs({...}) do if env[key] then return env[key] end end end
    env.HookUpdateSmartLayout = function() end
    local source = read(path)
    local first = source:find("local function GetActiveActionStripLayout()", 1, true)
        and "local function GetActiveActionStripLayout()" or "local function SetupActionBarHooks()"
    local hover = section(source, first, "-- Event handling")
    local cursor = section(source, '    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "CURSOR_CHANGED" then',
        "\n    end\nend)")
    local setup, onEvent, eventFrame = assert(load([[
local initialized, borderFrame, eventFrame = true, {}, {}
local function UpdateBorder() FluxUnifiedBorder.UpdateBorder() end
local function EnsureBorderFormStormSettledHook() eventFrame._settledHook = true end
]] .. hover .. "\nreturn SetupActionBarHooks, function(event) if false then\n" .. cursor
        .. "\nend end, eventFrame", "@actual-unified-hover-and-cursor", "t", env))()
    setup(); setup()
    if slotReplay then
        local raw, settled, signatures = 0, 0, {}
        local function SlotChanged(slot)
            f.emit("ACTIONBAR_SLOT_CHANGED", slot)
            onEvent("ACTIONBAR_SLOT_CHANGED")
        end
        check(bars.Watch.slotEvents == env.Flux.Events, "the modern watcher accepted native slot events")
        for i = 1, 60 do
            local grows = i % 2 == 1
            f.reset()
            f.occupied[15] = grows and 115 or nil
            SlotChanged(15)
            SlotChanged(15)
            local before = f.counts().envelope or 0
            f.drain()
            raw = raw + before
            settled = settled + (f.counts().envelope or 0) - before
            check(f.counts().commit == 1, "the slot batch commits the current strip once")
            signatures[i] = f.signature()
        end
        f.reset()
        f.occupied[1], f.occupied[2] = f.occupied[2], f.occupied[1]
        SlotChanged(1); SlotChanged(2); f.drain()
        check(not f.counts().commit, "a same-occupancy swap retains its prepared border")
        if not modern then return raw, settled, signatures end
        check(not f.counts().envelope, "a same-occupancy swap does not query envelope geometry")
        local slotEvents = bars.Watch.slotEvents
        for _,owner in ipairs({false, {}}) do
            f.reset()
            bars.Watch.slotEvents = owner
            onEvent("ACTIONBAR_SLOT_CHANGED")
            check(f.counts().envelope == 1, "a missing or superseded watcher retains immediate recovery")
        end
        bars.Watch.slotEvents = slotEvents
        strip.frame:Hide(); f.reset(); onEvent("ACTIONBAR_SLOT_CHANGED")
        check(f.counts().envelope == 1, "a hidden strip retains fallback envelope ownership")
        strip.frame:Show(); f.reset()
        env.FluxButtonEvents = { IsFormStormActive = function() return true end }
        onEvent("ACTIONBAR_SLOT_CHANGED")
        check(eventFrame._settledHook and eventFrame._fluxFormBorderPending and not f.counts().envelope,
            "form waves retain their separate settled fallback")
        return raw, settled, signatures
    end
    f.reset()
    f.cursor = "spell"; f.hover = false
    f.emit("CURSOR_CHANGED"); onEvent("CURSOR_CHANGED"); f.drain()
    check(tick, "picking up an action starts the existing drag check")
    check((f.counts().envelope or 0) == (modern and 0 or 1), "held cursor outside the strip leaves modern borders prepared")
    local function visibleLayout()
        local parts = {}
        local function append(frame)
            parts[#parts + 1] = tostring(frame:IsShown())
            if frame:IsShown() and not frame._fluxParked then
                local p, relative, rp, x, y = frame:GetPoint(1)
                parts[#parts + 1] = table.concat({frame.width, frame.height, frame.scale,
                    p or "", relative and relative.name or "", rp or "", x or 0, y or 0}, ",")
            end
        end
        append(strip.frame); append(strip.inner)
        bars.ForEachHost(function(host)
            parts[#parts + 1] = tostring(host.slot)
            append(host.widget)
        end)
        return table.concat(parts, "|")
    end
    local facesBefore = visibleLayout()
    if modern then
        local fullPaints = 0
        local flush = bars.Paint.Flush
        bars.Paint.Flush = function(tokens)
            if tokens == nil then fullPaints = fullPaints + 1 end
            return flush(tokens)
        end
        f.reset()
        for _ = 1, 10 do
            f.hover = true
            strip.sensing.scripts.OnEnter()
            f.hover = false
            strip.sensing.scripts.OnLeave()
        end
        f.drain()
        check(fullPaints == 0 and not f.counts().commit and visibleLayout() == facesBefore,
            "hover reversals before the same update keep the already-painted layout")
        check(not f.counts().keys and not f.counts()["get.width"] and not f.counts().mappingWrites,
            "a reverted hover skips geometry reads, secure mapping and key refresh")
        bars.Paint.Flush = flush
    end
    local immediateReads = 0
    for _, edge in ipairs({true, false, true, false}) do
        f.reset(); f.hover = edge; hoverKeys = nil
        local event = edge and "OnEnter" or "OnLeave"
        strip.sensing.scripts[event]()
        strip.frame.scripts[event]()
        immediateReads = immediateReads + (f.counts().envelope or 0)
        if modern then
            check(not f.counts().envelope, "hover waits for the completed layout before reading the envelope")
        else
            tick(1)
        end
        f.drain()
        check(f.counts().commit == 1 and bars.Layout.IsExpanding() == edge,
            "holding the same action expands or collapses with one completed border commit")
        if modern then
            check(commitPose == edge, "strip passes the finished collapsed/expanded pose")
            check(hoverKeys == true, "pure hover carries its key route reuse request")
        end
        check(f.counts().envelope == (modern and 1 or 3), "each edge uses one settled envelope update")
        if not edge then check(visibleLayout() == facesBefore, "leaving restores slot IDs and visible geometry") end
        f.reset()
        tick(1); f.drain()
        check(not f.counts().commit, "a repeated drag check leaves the prepared layout alone")
    end
    if modern then
        for _,kind in ipairs({"item", "macro"}) do
            f.cursor = kind
            f.emit("CURSOR_CHANGED"); onEvent("CURSOR_CHANGED"); f.drain()
            for _,inside in ipairs({true, false}) do
                f.reset(); f.hover = inside
                strip.sensing.scripts[inside and "OnEnter" or "OnLeave"]()
                f.drain()
                check(f.counts().commit == 1 and bars.Layout.IsExpanding() == inside,
                    kind .. " on the cursor still commits both hover poses")
            end
        end
        local main=bars.hosts[1].main.widget
        local mini=bars.hosts[1].sec.widget
        local show,setScale=main.Show,mini.SetScale
        local showWrites,scaleWrites=0,0
        function main:Show() showWrites=showWrites+1;return show(self) end
        function mini:SetScale(scale) scaleWrites=scaleWrites+1;return setScale(self,scale) end
        for _,inside in ipairs({true,false}) do
            f.hover=inside
            strip.sensing.scripts[inside and "OnEnter" or "OnLeave"]()
            f.drain()
        end
        check(showWrites==0 and scaleWrites==0,"current button visibility and scale survive repeated held-action crossings")
        main:Hide()
        setScale(mini,0.75)
        f.hover=true;strip.sensing.scripts.OnEnter();f.drain()
        check(main:IsShown() and mini:GetScale()==0.5 and showWrites==1 and scaleWrites==1,
            "hover repairs externally changed visibility and scale")
        local readShown,readScale=main.IsShown,mini.GetScale
        local secret={}
        env.issecretvalue=function(value)return rawequal(value,secret)end
        main.IsShown=function()return secret end
        mini.GetScale=function()error("test getter denied")end
        f.hover=false;strip.sensing.scripts.OnLeave();f.drain()
        main.IsShown,mini.GetScale=readShown,readScale
        check(showWrites==2 and scaleWrites==2 and visibleLayout()==facesBefore,
            "opaque or denied state retains the ordinary restore")

        local countPaints, painted = 0, {}
        local updateHotkey = bars.Paint.UpdateHotkey
        bars.Paint.UpdateHotkey = function(host)
            countPaints = countPaints + 1
            painted[host.widget] = true
            return updateHotkey(host)
        end
        f.hover = true; strip.sensing.scripts.OnEnter(); f.drain()
        check(countPaints > 0 and countPaints < 57 and painted[mini] and not painted[main],
            "settled hover repaints moved mini faces and skips stable main faces")
        local repair = bars.hosts[2].main.widget
        repair:SetSize(repair.width + 2, repair.height + 2)
        local size = repair.GetSize
        repair.GetSize = function() return secret, secret end
        painted, countPaints = {}, 0
        bars.Paint.MarkDirty(bars.hosts[1].main)
        f.hover = false; strip.sensing.scripts.OnLeave(); f.drain()
        repair.GetSize = size
        check(countPaints < 57 and painted[main] and painted[repair] and visibleLayout() == facesBefore,
            "scoped paint retains slot dirties and restores an opaque native size")
        painted, countPaints = {}, 0
        hoverKeys = nil
        f.hover = true; strip.sensing.scripts.OnEnter(); f.emit("CURSOR_CHANGED"); f.drain()
        check(countPaints == 57 and painted[main], "a coalesced cursor change keeps the whole paint")
        check(hoverKeys == false, "coalesced content or cursor changes keep live binding reconciliation")
        bars.Paint.UpdateHotkey = updateHotkey
        f.hover = false; strip.sensing.scripts.OnLeave(); f.drain()
        local settings = section(read("FluxDefaultSettings.lua"),
            "-- Squeeze callback bodies are shared across notifications.", "local squeezeRefreshScheduled")
        assert(load(settings, "@actual-strip-dependent-notification", "t", env))()
        local order = {}
        local updateEnvelope = env.FluxUnifiedBorder.UpdateBorder
        env.FluxUnifiedBorder.UpdateBorder = function(...)
            order[#order + 1] = "envelope"
            return updateEnvelope(...)
        end
        env.FluxChatFrame_ApplyPrimaryPosition = function(force)
            check(force == true, "full reconciliation requests the existing forced chat path")
            order[#order + 1] = "force"
        end
        env.FluxChatFrame_UpdateAfterStripLayout = function() order[#order + 1] = "chat" end
        local commit = env.FluxBorder.Junctions.CommitLayout
        env.FluxBorder.Junctions.CommitLayout = function(...)
            order[#order + 1] = "border"
            return commit(...)
        end
        f.hover = true; strip.sensing.scripts.OnEnter(); f.drain()
        check(table.concat(order, "/") == "envelope/chat/border",
            "pure hover positions chat from the finished envelope before border commit")
        order = {}
        f.hover = false; strip.sensing.scripts.OnLeave(); f.emit("CURSOR_CHANGED"); f.drain()
        check(table.concat(order, "/") == "force/envelope/border",
            "coalesced cursor changes retain the broad dependency pass")
        f.reset(); f.hover = true
        tick(1); f.drain()
        check(f.counts().commit == 1, "the drag check retains detection when a mouse-disabled area has no hover callback")
        f.reset(); f.cursor = nil; f.hover = false
        f.emit("CURSOR_CHANGED"); onEvent("CURSOR_CHANGED"); f.drain()
        check(f.counts().commit == 1 and not tick, "lifting the cursor dispatches the final collapse through the strip")
        bars.started = false
        f.reset(); strip.sensing.scripts.OnEnter()
        check(f.counts().envelope == 1, "legacy hover still refreshes when the modern strip is unavailable")
    end
    return immediateReads
end

local baseline = arg[1] and arg[1] ~= "-" and run(arg[1], false)
local candidate = run("Layout/UnifiedBorder.lua", true)
if baseline then print(("DRAG_HOVER immediateEnvelopeReads=%d/%d"):format(baseline, candidate)) end
do
    local raw, settled, layouts = run("Layout/UnifiedBorder.lua", true, true)
    check(raw == 0 and settled == 60, "60 slot batches settle the envelope once each")
    if arg[3] then
        local oldRaw, oldSettled, oldLayouts = run(arg[3], false, true)
        check(oldRaw == 120 and oldSettled == settled, "the archived event handler read the envelope twice per batch")
        for i,signature in ipairs(layouts) do
            check(signature == oldLayouts[i], "slot-event ownership preserves settled geometry and action routes")
        end
        print(("STRIP_SLOT_EVENTS rawEnvelope=%d/%d settled=%d/%d"):format(oldRaw, raw, oldSettled, settled))
    end
end

local function MappingReplay(layoutPath, bottom)
    outer.arg = layoutPath and {layoutPath, "Bars/Strip.lua"} or {}
    local model = loadFixture()(not layoutPath)
    local bars = model.B
    model.bottom = bottom
    model.occupied[1], model.occupied[2] = nil, nil
    model.occupied[25], model.occupied[74] = 125, 174
    bars.Layout.Invalidate()
    bars.Layout.Apply()
    model.drain()

    local sampling, samples = false, 0
    local apply, hasAction = bars.Layout.ApplyMappings, model.flux.Action.HasAction
    bars.Layout.ApplyMappings = function(...)
        sampling = true
        apply(...)
        sampling = false
    end
    model.flux.Action.HasAction = function(slot)
        if sampling then samples = samples + 1 end
        return hasAction(slot)
    end
    local function Cross(inside)
        model.hover = inside
        model.reset()
        samples = 0
        bars.Layout.OnDragHover()
        model.drain()
        return {signature = model.signature(), writes = model.counts().mappingWrites or 0,
            reads = samples, applies = model.applies, commits = model.counts().commit}
    end
    local results = {}
    for _,kind in ipairs({"spell", "item", "macro"}) do
        model.cursor = kind
        results[#results + 1] = Cross(true)
        results[#results + 1] = Cross(false)
    end

    if not layoutPath then
        local main = bars.hosts[2].main.widget
        local getter = main.GetAttribute
        local secret = setmetatable({}, {__eq = function() error("private attribute compared") end})
        model.env.issecretvalue = function(v) return rawequal(v, secret) end
        main:SetAttribute("flux-promoted", 9)
        main.GetAttribute = function(self, key)
            if key == "flux-promoted" then return secret end
            return getter(self, key)
        end
        Cross(true)
        check(main.attributes["flux-promoted"] == 0, "an opaque unchanged flag still writes the expected native value")
        main.GetAttribute = getter
        main:SetAttribute("flux-promoted", 9)
        Cross(false)
        check(main.attributes["flux-promoted"] == 0, "an unchanged flag with native drift is repaired")

        model.reset()
        bars.Layout.InvalidateMappings(2)
        bars.Layout.ApplyMappings()
        check(model.counts().mappingWrites == 9 and model.applies == 1,
            "slot invalidation still stamps all flags and forces a live action update")
        model.combat = true
        local locked = Cross(true)
        check(locked.writes == 0 and locked.reads == 0 and locked.applies == 0,
            "the held cursor does not stamp or sample protected mappings in combat")
    end
    return results
end

for _,bottom in ipairs({false, true}) do
    local old = arg[2] and arg[2] ~= "-" and MappingReplay(arg[2], bottom)
    local current = MappingReplay(nil, bottom)
    local reads, writes, beforeReads, beforeWrites = 0, 0, 0, 0
    for index, result in ipairs(current) do
        local expanding = index % 2 == 1
        check(not expanding or result.reads == 0, "expanded mapping does not read slots before placing faces")
        check(result.commits == 1 and result.applies == 1, "each crossing uses one secure refresh and border commit")
        reads, writes = reads + result.reads, writes + result.writes
        if old then
            local before = old[index]
            check(before.signature == result.signature, "held-action changes retain mapped slots and face geometry")
            check(before.writes > result.writes, "changed columns retain their matching flags")
            beforeReads, beforeWrites = beforeReads + before.reads, beforeWrites + before.writes
        end
    end
    if old then
        print(("HOVER_MAPPING edge=%s writes=%d/%d reads=%d/%d"):format(
            bottom and "bottom" or "top", beforeWrites, writes, beforeReads, reads))
    end
end
do
    local model=fixture(true)
    local sensing=model.B.Strip.sensing
    local tick
    model.flux.Ticker={Add=function(_,fn)tick=fn end,Remove=function()tick=nil end}
    local originalShow,originalHide=sensing.Show,sensing.Hide
    local shows,hides=0,0
    function sensing:Show() shows=shows+1;return originalShow(self) end
    function sensing:Hide() hides=hides+1;return originalHide(self) end
    originalHide(sensing)
    model.cursor="spell"
    model.B.Layout.OnCursor()
    check(sensing:IsShown() and shows==1 and tick,"pickup reveals the native sensing frame once")
    for _=1,60 do tick(1) end
    check(shows==1 and hides==0,"an unchanged held cursor leaves the sensing frame alone")
    originalHide(sensing)
    tick(1)
    check(sensing:IsShown() and shows==2,"a hidden sensing frame is repaired")
    local gamepad=true
    model.flux.Cap={IsGamepadUIEnabled=function() return gamepad end}
    tick(1);tick(1)
    check(not sensing:IsShown() and hides==1,"active gamepad hides the sensing frame once")
    gamepad=false
    tick(1)
    check(sensing:IsShown() and shows==3,"returning to mouse mode restores sensing")
    local shown=sensing.IsShown
    sensing.IsShown=function()error("unavailable native visibility")end
    tick(1)
    sensing.IsShown=shown
    check(shows==4,"unavailable visibility retains the show fallback")
    model.cursor=nil
    tick(1)
    check(not tick and not sensing:IsShown() and hides==2,"release stops the watcher and hides the frame")
end
print(("Strip drag hover edges: %d checks; enter/leave while holding the same action. Native timing and seams pending.")
    :format(checks))
