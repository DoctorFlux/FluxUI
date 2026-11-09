-- Execute the real EBS layout and shared scheduler. Child refresh/pack calls
-- are counted, not rendered; native secure layout and FPS are not simulated.
local function read(path)
    local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close()
    return text:gsub("\r\n", "\n")
end
local source = read("ExtraButtonSystem/Layout.lua")
local scheduler = read("Core/Engine/Scheduler.lua")
local combat = read("Core/Engine/Combat.lua")
local checks = 0
local function check(value, message) assert(value, message); checks = checks + 1 end

local function fixture(body)
    local env = setmetatable({}, {__index=_G}); env._G = env
    local s = {queue={},frames={},events={},errors={},flushes=0,refreshes=0,packs=0,anchors=0,range=0,schedules=0,reasons={},locked=false}
    local flux = {EBS={hosts={},stats={}},Timer={}}
    local ns = {Flux=flux}
    function flux.Timer.After(delay, fn)
        check(delay == 0, "layout keeps the existing next-frame boundary")
        s.queue[#s.queue+1] = fn; s.schedules=s.schedules+1
    end
    function flux.Safecall(fn, ...)
        local ok, result = pcall(fn, ...)
        if not ok then s.errors[#s.errors+1] = result end
        return ok, result
    end
    env.InCombatLockdown = function() return s.locked end
    env.CreateFrame = function()
        local f = {RegisterEvent=function() end}
        function f:SetScript(event, fn) self[event]=fn end
        s.frames[#s.frames+1]=f; return f
    end
    flux.Events = {Register=function(event, fn) s.events[event]=fn end}
    assert(load(combat,"@production-combat","t",env))("_FluxUI",ns)
    assert(load(scheduler,"@production-scheduler","t",env))("_FluxUI",ns)
    for _,name in ipairs({"Combat","NonCombat","Trinket","Utility"}) do
        flux.EBS[name]={Refresh=function() s.refreshes=s.refreshes+1 end}
    end
    flux.EBS.Range={SyncDemand=function() s.range=s.range+1 end}
    for _,name in ipairs({"combat","nc","trinket"}) do flux.EBS.hosts[name]={Frame={IsShown=function() return true end}} end
    assert(load(body,"@production-ebs-layout","t",env))("_FluxUI",ns)
    local layout=flux.EBS.Layout
    for _,name in ipairs({"AnchorCombat","AnchorNC","AnchorTrinket"}) do layout[name]=function() s.anchors=s.anchors+1 end end
    layout.Pack=function() s.packs=s.packs+1 end
    local originalFlush=layout.Flush
    layout.Flush=function(...) s.flushes=s.flushes+1; return originalFlush(...) end
    flux.Scheduler.Register("layout",function(tokens,reasons)
        check(tokens.ebs==true, "the existing EBS token reaches shared layout listeners")
        s.reasons[#s.reasons+1]=reasons
    end)
    function s:frame()
        local queue=self.queue; self.queue={}
        for _,fn in ipairs(queue) do fn() end
    end
    s.flux,s.layout=flux,layout
    return s
end

local function exercise(body)
    local s=fixture(body); local layout=s.layout
    for i=1,1000 do layout.Request(i%2==0 and "uiscale" or "display") end
    layout.Request()
    check(s.flushes==0 and #s.queue==1, "all requests keep one scheduled frame and no synchronous refresh")
    check(s.flux.Scheduler.Stats().requests.layout==1001, "every request still contributes its token and reason")
    s:frame()
    check(s.flushes==1 and s.refreshes==4 and s.packs==3 and s.anchors==3 and s.range==1,
        "1001 same-frame requests perform one full refresh and one pack per host")
    check(#s.reasons==1 and s.reasons[1].uiscale and s.reasons[1].display and s.reasons[1]["ebs.layout"],
        "coalescing preserves all reasons including the default reason")
    check(#s.queue==0 and not s.flux.Scheduler.HasPending(), "completed bursts retain no work or timer")
    for _=1,100 do s:frame() end
    check(s.flushes==1 and s.schedules==1 and #s.frames==1, "idle frames add no work or resources")
    layout.Request("later"); s:frame()
    check(s.flushes==2 and s.reasons[2].later, "a later burst is not suppressed by the completed flag")

    local events=fixture(body); events.layout.Start()
    for _=1,100 do events.events.UI_SCALE_CHANGED(); events.events.DISPLAY_SIZE_CHANGED() end
    events:frame()
    check(events.flushes==1 and events.reasons[1].uiscale and events.reasons[1].display,
        "real scale and display handlers merge their same-frame layout work")

    local nested=fixture(body); local nestedCalls=0
    nested.flux.EBS.Combat.Refresh=function()
        nestedCalls=nestedCalls+1
        if nestedCalls==1 then nested.layout.Request("nested-one"); nested.layout.Request("nested-two") end
    end
    nested.layout.Request("outer"); nested:frame()
    check(nested.flushes==1 and #nested.queue==1, "a request during refresh schedules the next frame")
    nested:frame()
    check(nested.flushes==2 and nested.reasons[2]["nested-one"] and nested.reasons[2]["nested-two"],
        "requests during a running refresh are retained and coalesced independently")
    check(#nested.queue==0 and #nested.errors==0, "nested recovery terminates without recursion or hidden failures")

    local direct=fixture(body)
    direct.layout.Flush()
    check(direct.flushes==1 and #direct.queue==0, "direct Flush remains synchronous")
    for _=1,50 do direct.layout.Request("before-direct") end
    direct.layout.Flush()
    for _=1,50 do direct.layout.Request("after-direct") end
    check(direct.flushes==2 and #direct.queue==1, "direct work does not duplicate or consume the queued callback")
    direct:frame()
    check(direct.flushes==3 and direct.reasons[1]["before-direct"] and direct.reasons[1]["after-direct"],
        "one scheduled refresh follows direct work with both request reasons intact")

    local failed=fixture(body); local attempts=0
    failed.flux.EBS.Combat.Refresh=function()
        attempts=attempts+1
        if attempts==1 then error("controlled child refresh failure") end
    end
    failed.layout.Request("first"); failed:frame()
    check(#failed.errors==1 and failed.errors[1]:find("controlled child refresh failure",1,true),
        "existing scheduler error handling still reports the child failure")
    failed.layout.Request("recovery"); failed:frame()
    check(failed.flushes==2 and attempts==2 and #failed.queue==0,
        "the queue flag cannot stay stuck after a child refresh fails")

    local locked=fixture(body); local deferred=0; locked.locked=true
    locked.flux.EBS.Combat.Refresh=function()
        locked.flux.Combat.Defer("ebs.layout.fixture",function() deferred=deferred+1 end)
    end
    for _=1,100 do locked.layout.Request("combat") end
    locked:frame()
    check(locked.flushes==1 and deferred==0 and locked.flux.Combat.PendingCount()==1,
        "child-owned combat deferral remains pending without duplicate layout refreshes")
    locked.locked=false; locked.frames[1].OnEvent(nil,"PLAYER_REGEN_ENABLED")
    check(deferred==1 and not locked.flux.Combat.HasPending(), "the existing combat queue resumes its child work once")
    locked.layout.Request("after-combat"); locked:frame()
    check(locked.flushes==2 and deferred==2, "a legal later request still executes after combat recovery")

    local immediate=fixture(body); local immediateRequests=0
    immediate.flux.Scheduler.Request=function(tier,token,fn,reason)
        check(tier=="layout" and token=="ebs" and reason=="immediate", "synchronous scheduler receives the unchanged public contract")
        immediateRequests=immediateRequests+1
        if fn then fn() end
    end
    for _=1,10 do immediate.layout.Request("immediate") end
    check(immediateRequests==10 and immediate.flushes==10 and #immediate.queue==0,
        "an immediate scheduler backend keeps its existing synchronous cadence")
end

exercise(source)
local function replace(body, old, new)
    local a,b=assert(body:find(old,1,true))
    return body:sub(1,a-1)..new..body:sub(b+1)
end
local mutants={
    ["lost coalescing"]=replace(source,"Flux.Scheduler.Request(\"layout\", \"ebs\", callback, reason or \"ebs.layout\")",
        "Flux.Scheduler.Request(\"layout\", \"ebs\", Layout.Flush, reason or \"ebs.layout\")"),
    ["lost reasons"]=replace(source,"function Layout.Request(reason)\n", "function Layout.Request(reason)\n\tif layoutQueued then return end\n"),
    ["lost next burst"]=replace(source,"\tlayoutQueued = false\n\tLayout.Flush()", "\tLayout.Flush()"),
    ["lost reentry"]=replace(source,"\tlayoutQueued = false\n\tLayout.Flush()", "\tLayout.Flush()\n\tlayoutQueued = false"),
}
for name, body in pairs(mutants) do
    local ok=pcall(exercise,body)
    check(not ok,"fixture rejects "..name)
end
print(string.format("EBS layout coalescing: %d checks passed; four mutations rejected; 1001 requests -> one refresh; native secure layout/FPS unverified",checks))
