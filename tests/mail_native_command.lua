-- Production selected/OpenAll worker with independently delayed native commands.
-- Optional alternate Mail/Select.lua enables exact pre-change replay.
-- Client/provider names exercise the shared worker; no native client is emulated.
local source = arg[1] or "Mail/Select.lua"
local checks, failures = 0, 0
local totals = {unsafe = 0, premature = 0, pendingReads = 0, timers = 0}
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end

local function boot(label, cancellable, api)
    local e = setmetatable({}, {__index = _G}); e._G = e
    local s = {now = 0, timers = {}, creates = 0, calls = {}, pendingReads = 0,
        commandPending = false, notices = {}, running = false, unsafe = 0, premature = 0,
        inbox = {}, speed = .5}
    local function widget(name)
        local w = {shown = true, events = {}}
        function w:RegisterEvent(key) self.events[key] = true end
        function w:SetScript(key, fn) self[key] = fn end
        function w:SetSize() end
        function w:SetPoint() end
        function w:SetText(text) self.text = text end
        function w:SetShown(v) self.shown = v end
        function w:IsShown() return self.shown end
        function w:SetEnabled(v) self.enabled = v end
        if name then e[name] = w end
        return w
    end
    local eventFrame
    e.CreateFrame = function(_, name)
        local w = widget(name)
        if not name then eventFrame = w end
        return w
    end
    e.MailFrame, e.InboxFrame = widget(), widget()
    e.GetTime = function() return s.now end
    e.C_Timer = {}
    local function timer(delay, fn)
        check(delay >= 0, label .. " nonnegative timer")
        local t = {at = s.now + delay, fn = fn}
        function t:Cancel() self.cancelled = true end
        s.timers[#s.timers+1] = t; s.creates = s.creates + 1
        return t
    end
    e.C_Timer.After = function(delay, fn) timer(delay, fn) end
    if cancellable then e.C_Timer.NewTimer = timer end
    if api ~= "absent" then
        e.C_Mail = {}
        if api ~= "missing" then
            e.C_Mail.IsCommandPending = function()
                s.pendingReads = s.pendingReads + 1
                return s.commandPending
            end
        end
    end
    e.ATTACHMENTS_MAX_RECEIVE = 16
    e.GetInboxNumItems = function() return #s.inbox end
    e.GetInboxHeaderInfo = function(index)
        local h = s.inbox[index]
        if h then return nil,nil,h.sender,h.subject,h.money,h.cod,20,#h.items,false,false,false,false,false end
    end
    e.GetInboxItem = function(index, slot)
        local h = s.inbox[index]
        if h and h.items[slot] and s.itemsAvailable~=false then return "Item",h.items[slot],nil,1 end
    end
    local function action(kind, index, slot)
        if s.commandPending then s.unsafe = s.unsafe + 1 end
        s.calls[#s.calls+1] = {kind = kind, index = index, slot = slot, at = s.now}
        s.commandPending = true
    end
    e.TakeInboxMoney = function(index) action("money",index) end
    e.TakeInboxItem = function(index, slot) action("item",index,slot) end
    e.ReturnInboxItem = function(index) action("return",index) end
    e.DeleteInboxItem = function(index) action("delete",index) end
    e.InboxItemCanDelete = function() return true end
    local ns = {Flux = {Container = {GetTotalFreeBagSlots = function() return 30 end}, Mail = {
        GetSetting = function(group, key)
            if group == "OpenSpeed" then return s.speed end
            if key == "SpamChat" then return false end
        end,
        Print = function(message) s.notices[#s.notices+1] = message end,
        OnJobStateChanged = function(running, _, message)
            s.running, s.lastMessage = running, message
            if not running and message and message:find("Finished",1,true) and s.commandPending then
                s.premature = s.premature + 1
            end
        end,
    }}}
    assert(loadfile(source,"t",e))("_FluxUI",ns)
    function s:event(name) eventFrame.OnEvent(eventFrame,name) end
    function s:burst()
        for _ = 1, 100 do self:event("MAIL_INBOX_UPDATE") end
    end
    function s:start(mode)
        local list = {}
        for index,h in ipairs(self.inbox) do
            list[#list+1] = {index = index, header = {
                sender = h.sender, subject = h.subject, money = h.money, cod = h.cod, items = #h.items}}
        end
        ns.Flux.Mail.ProcessSelected(mode or "take",list,"Select")
    end
    function s:advance(seconds)
        local deadline, limit = self.now + seconds, 20000
        while #self.timers > 0 do
            table.sort(self.timers,function(a,b) return a.at < b.at end)
            if self.timers[1].at > deadline + 1e-9 then break end
            local t = table.remove(self.timers,1)
            self.now = t.at
            if not t.cancelled then limit = limit-1; assert(limit > 0,"bounded native-command fixture"); t.fn() end
        end
        self.now = deadline
    end
    function s:liveTimers()
        local n=0
        for _,t in ipairs(self.timers) do if not t.cancelled then n=n+1 end end
        return n
    end
    function s:finish()
        totals.unsafe = totals.unsafe + self.unsafe
        totals.premature = totals.premature + self.premature
        totals.pendingReads = totals.pendingReads + self.pendingReads
        totals.timers = totals.timers + self.creates
    end
    s:event("MAIL_SHOW")
    return s, e
end

local function message(subject, money, items)
    return {sender="Alt",subject=subject or "Supplies",money=money or 0,cod=0,items=items or {}}
end

for _, client in ipairs({"forever","retail","era","anniversary","mists"}) do
 for _, provider in ipairs({"builtin","syndicator","baganator","baganator+syndicator"}) do
  for _, cancellable in ipairs({false,true}) do
    local label=client.."/"..provider.."/"..(cancellable and "NewTimer" or "After")
    -- Money and item headers can confirm before the client's command completes.
    local s=boot(label,cancellable)
    s.inbox={message("Auction successful",670,{101})}; s:start()
    check(#s.calls==1 and s.calls[1].kind=="money",label.." ready first money request stays immediate")
    s.inbox[1].money=0; s:burst()
    s:advance(.49); check(#s.calls==1,label.." event cannot bypass configured minimum")
    s:advance(.01); check(#s.calls==1 and s.running,label.." confirmed header cannot overlap native command")
    local creates=s.creates; s:burst()
    check(s.creates==creates,label.." duplicate events do not multiply native readiness wakes")
    s:advance(.2); check(#s.calls==1,label.." native busy remains blocked across retries")
    s.commandPending=false; s:advance(.1)
    check(#s.calls==2 and s.calls[2].kind=="item" and s.calls[2].at>=.5,
        label.." item resumes after native completion at or after minimum")
    s.inbox={}; s:burst(); s:advance(.5)
    check(s.running,label.." empty header does not finish while native command is pending")
    s.commandPending=false; s:advance(.1)
    check(not s.running and s.lastMessage and s.lastMessage:find("Finished",1,true),label.." completed command finishes job")
    check(s.unsafe==0 and s.premature==0,label.." no unsafe requests or premature completion")
    local reads=s.pendingReads; s:advance(20)
    check(s.pendingReads==reads,label.." completed job performs no idle native checks")
    s:finish()

    for _, mode in ipairs({"take","return","delete"}) do
        local f=boot(label.."/foreign/"..mode,cancellable)
        f.inbox={message("Foreign",mode=="take" and 1 or 0)}
        f.commandPending=true; f:start(mode)
        check(#f.calls==0 and f.running,label.." initial foreign command blocks "..mode)
        f:advance(.4); check(#f.calls==0,label.." initial foreign command remains blocked "..mode)
        f.commandPending=false; f:advance(.1)
        check(#f.calls==1 and f.calls[1].kind==(mode=="take" and "money" or mode),label.." foreign completion resumes "..mode)
        f.inbox={}; f:burst(); f:advance(.5)
        check(f.running,label.." header removal cannot finish pending "..mode)
        f.commandPending=false; f:advance(.1)
        check(not f.running,label.." native completion finishes "..mode)
        check(f.unsafe==0 and f.premature==0,label.." foreign/"..mode.." never overlaps/completes early")
        f:finish()
    end

    for _, mode in ipairs({"return","delete"}) do
        local p=boot(label.."/sequence/"..mode,cancellable)
        p.inbox={message("Earlier"),message("Later")}; p:start(mode)
        check(#p.calls==1 and p.calls[1].index==2,label.." "..mode.." starts at descending selected index")
        table.remove(p.inbox,2); p:burst(); p:advance(.5)
        check(#p.calls==1 and p.running,label.." confirmed "..mode.." cannot overlap next selected action")
        p.commandPending=false; p:advance(.1)
        check(#p.calls==2 and p.calls[2].index==1,label.." next "..mode.." resumes after native completion")
        p:event("MAIL_CLOSED"); p:finish()
    end

    -- Once a foreign command finishes, its watchdog cannot accelerate an
    -- unrelated missing-metadata retry that still has no own pending action.
    local m=boot(label.."/foreign-metadata",cancellable)
    m.speed=5; m.inbox={message("Metadata",0,{103})}; m.itemsAvailable=false
    m.commandPending=true; m:start(); m:advance(.1)
    m.commandPending=false; m:advance(.1)
    m:advance(5.1); m.itemsAvailable=true; m:advance(2.8)
    check(#m.calls==0 and m.running,label.." old foreign watchdog cannot bypass metadata retry delay")
    m:advance(2.2)
    check(#m.calls==1 and m.calls[1].at>=10.2-1e-9,label.." metadata retry resumes at its configured deadline")
    m:event("MAIL_CLOSED"); m:finish()

    -- A permanently busy native command must not introduce unbounded polling.
    for _, initial in ipairs({true,false}) do
        local t=boot(label.."/timeout",cancellable)
        t.inbox={message("Timeout",1)}
        t.commandPending=initial; t:start()
        if not initial then t.inbox[1].money=0; t:burst() end
        t:advance(8.01)
        check(not t.running and t.lastMessage and t.lastMessage:find("Stopped",1,true),label.." native wait times out within eight seconds")
        check(#t.calls==(initial and 0 or 1),label.." timeout never overlaps native command")
        check(t.pendingReads<=90,label.." native busy polling is bounded")
        local reads=t.pendingReads; t:advance(30)
        check(t.pendingReads==reads,label.." timeout stops all readiness work")
        t:finish()
    end

    -- Stop/close invalidate callbacks, including uncancellable After handles.
    for _, stop in ipairs({"close","button"}) do
        local c=boot(label.."/"..stop,cancellable)
        c.inbox={message("Cancel",1)}; c.commandPending=true; c:start()
        c:advance(.2)
        if stop=="close" then c:event("MAIL_CLOSED") else c:start() end
        local reads,calls=c.pendingReads,#c.calls
        if cancellable then check(c:liveTimers()==0,label.." stop cancels timer handles") end
        c:advance(20)
        check(c.pendingReads==reads and #c.calls==calls and not c.running,label.." "..stop.." leaves no stale readiness work")
        c.commandPending=false; c:event("MAIL_SHOW"); c:start()
        check(#c.calls==calls+1,label.." reopened job can proceed normally")
        c:event("MAIL_CLOSED"); c:finish()
    end

    -- Ready or unavailable APIs preserve every configured minimum without polls.
    for _, api in ipairs({"ready","absent","missing"}) do
      for _, speed in ipairs({0,.3,.5,2,5}) do
        local r=boot(label.."/"..api,cancellable,api)
        r.speed=speed; r.inbox={message("Cadence",1,{102})}; r:start()
        check(#r.calls==1,label.." ready/absent API preserves immediate start")
        local creates=r.creates
        r.commandPending=false; r.inbox[1].money=0; r:burst()
        check(r.creates==creates+1,label.." ready/absent API adds only existing progress timer")
        if speed>0 then r:advance(speed-.001); check(#r.calls==1,label.." configured minimum retained with "..api) end
        r:advance(speed>0 and .001 or 0)
        check(#r.calls==2 and r.calls[2].at>=speed-1e-9,label.." ready/absent API resumes at configured minimum")
        r:event("MAIL_CLOSED"); r:finish()
      end
    end
  end
 end
end
print(string.format("mail native command: %d checks, %d failures; unsafe requests=%d premature completion=%d native checks=%d timers=%d",
    checks,failures,totals.unsafe,totals.premature,totals.pendingReads,totals.timers))
if failures>0 then os.exit(1) end
