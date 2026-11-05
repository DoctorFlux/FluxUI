-- Real selected/OpenAll worker; native mail actions, frames and timers mocked.
-- Optional argument: alternate Mail/Select.lua for baseline replay.
-- Client/provider labels exercise the shared worker, not native client support.
local source = arg[1] or "Mail/Select.lua"
local checks, failures = 0, 0
local burstCreates, burstReads = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end

local function fixture(client, provider, cancellable)
    local label = client .. "/" .. provider .. "/" .. (cancellable and "NewTimer" or "After")
    local e = setmetatable({}, {__index = _G}); e._G = e
    local s = {now = 0, timers = {}, creates = 0, cancels = 0, headers = 0, actions = {}, notices = {}}
    local function widget(name)
        local w = {shown = true, events = {}}
        function w:RegisterEvent(event) self.events[event] = true end
        function w:SetScript(event, fn) self[event] = fn end
        function w:SetSize() end
        function w:SetPoint() end
        function w:SetShown(value) self.shown = value end
        function w:IsShown() return self.shown end
        function w:SetEnabled(value) self.enabled = value end
        function w:SetText(value) self.text = value end
        if name then e[name] = w end
        return w
    end
    local eventFrame
    e.CreateFrame = function(_, name)
        local frame = widget(name)
        if not name then eventFrame = frame end
        return frame
    end
    e.MailFrame, e.InboxFrame = widget(), widget()
    e.GetTime = function() return s.now end
    e.C_Timer = {}
    local function timer(delay, fn)
        local t = {at = s.now + delay, fn = fn}
        s.creates = s.creates + 1; s.timers[#s.timers + 1] = t
        function t:Cancel() if not self.cancelled then s.cancels = s.cancels + 1 end; self.cancelled = true end
        return t
    end
    e.C_Timer.After = function(delay, fn) timer(delay, fn) end
    if cancellable then e.C_Timer.NewTimer = timer end
    local function advance(seconds)
        local deadline, limit = s.now + seconds, 20000
        while #s.timers > 0 do
            table.sort(s.timers, function(a,b) return a.at < b.at end)
            if s.timers[1].at > deadline + 1e-8 then break end
            local t = table.remove(s.timers, 1)
            s.now = t.at
            if not t.cancelled then
                limit = limit - 1; assert(limit > 0, "bounded mail timer fixture")
                t.fn()
            end
        end
        s.now = deadline
    end
    local function activeTimers()
        local n = 0
        for _, t in ipairs(s.timers) do if not t.cancelled then n = n + 1 end end
        return n
    end
    local inbox = {}
    for i=1,3 do
        local h = {sender="Alt",subject="Supplies"..i,money=0,cod=0,items={}}
        for slot=1,12 do h.items[slot] = 100 + slot end
        inbox[i] = h
    end
    e.GetInboxNumItems = function() return #inbox end
    e.GetInboxHeaderInfo = function(index)
        s.headers = s.headers + 1
        local h = inbox[index]
        if h then return nil,nil,h.sender,h.subject,h.money,h.cod,20,#h.items,false,false,false,false,h.gm end
    end
    e.GetInboxItem = function(index,slot)
        local h = inbox[index]
        if h and h.items[slot] then return "Item",h.items[slot],nil,1 end
    end
    e.TakeInboxItem = function(index,slot)
        check(not s.nativePending, label .. " one unconfirmed native action")
        local action = {at=s.now,index=index,slot=slot}
        s.actions[#s.actions+1] = action; s.nativePending = action
    end
    local function ack()
        local p = s.nativePending
        if not p then return end
        local h = inbox[p.index]
        if h then
            table.remove(h.items,p.slot)
            if #h.items == 0 and h.money == 0 then table.remove(inbox,p.index) end
        end
        s.nativePending = nil
    end
    local speed = .5
    local ns = {Flux={Client={branch=client},Container={GetTotalFreeBagSlots=function()return 30 end},
        Mail={GetSetting=function(group,key)
            if group=="OpenSpeed" then return speed end
            if key=="KeepFreeSpace" then return 1 end
            if key=="SpamChat" then return false end
        end,Print=function(msg)s.notices[#s.notices+1]=msg end}}}
    if provider:find("syndicator",1,true) then e.Syndicator={} end
    if provider:find("baganator",1,true) then e.Baganator={} end
    assert(loadfile(source,"t",e))("_FluxUI",ns)
    local mail = ns.Flux.Mail
    local function event(name) eventFrame.OnEvent(eventFrame,name) end
    local function start()
        local list={}
        for index,h in ipairs(inbox) do
            list[#list+1]={index=index,header={sender=h.sender,subject=h.subject,cod=h.cod,money=h.money,items=#h.items}}
        end
        mail.ProcessSelected("take",list,"OpenAll")
    end
    event("MAIL_SHOW"); start()
    check(#s.actions==1,label.." first loot action remains immediate")
    local created=s.creates
    for i=1,100 do event("MAIL_INBOX_UPDATE") end
    local burst=s.creates-created
    burstCreates=burstCreates+burst
    check(burst==1,label.." inbox burst coalesces one progress timer")
    check(activeTimers()<=2,label.." one progress wake and one watchdog")
    local headers=s.headers
    advance(.5)
    local reads=s.headers-headers; burstReads=burstReads+reads
    check(reads==1,label.." duplicate wakes do not repeat pending header checks")
    check(#s.actions==1,label.." unconfirmed item never advances")
    ack(); event("MAIL_INBOX_UPDATE")
    advance(.49)
    check(#s.actions==1,label.." configured OpenSpeed delay remains intact")
    advance(.01)
    check(#s.actions==2,label.." confirmed loot progresses at configured delay")

    -- This spans old 8s action watchdogs. A previous action's timeout must not
    -- accelerate a later action after its confirmation event.
    for i=1,20 do
        local actions=#s.actions
        advance(.25); ack(); event("MAIL_INBOX_UPDATE")
        local confirmed=s.now
        advance(.49)
        check(#s.actions==actions,label.." old watchdog preserves later-action cadence")
        advance(.01)
        check(#s.actions==actions+1 and s.actions[#s.actions].at>=confirmed+.5-1e-8,
            label.." only current action wake advances loot")
    end
    e.MailFrame.shown=false; event("MAIL_CLOSED")
    if cancellable then check(activeTimers()==0,label.." close cancels native timer handles") end
    local actions,reads=#s.actions,s.headers
    advance(20)
    check(#s.actions==actions and s.headers==reads,label.." closed mailbox performs no stale work")
    s.nativePending=nil

    -- No confirmation still times out, and restarting after close must not let
    -- callbacks from a previous job operate on the new pending action.
    inbox={{sender="Alt",subject="Timeout",money=0,cod=0,items={101}}}
    e.MailFrame.shown=true; event("MAIL_SHOW"); start()
    local before=#s.actions
    advance(8)
    check(#s.actions==before and not e.FluxMailTakeSelected.enabled
        and s.notices[#s.notices]:find("not confirmed",1,true),label.." existing timeout still stops unconfirmed action")
    s.nativePending=nil
    inbox={{sender="Alt",subject="Reopen",money=0,cod=0,items={102}}}
    start(); ack(); event("MAIL_INBOX_UPDATE")
    event("MAIL_CLOSED"); event("MAIL_SHOW"); s.nativePending=nil
    start(); local reopened=#s.actions
    advance(.5)
    check(#s.actions==reopened,label.." prior close/reopen callbacks cannot advance new job")
    event("MAIL_CLOSED")
    s.nativePending=nil
    inbox={{sender="Alt",subject="Speed change",money=0,cod=0,items={103,104}}}
    event("MAIL_SHOW"); start(); ack(); event("MAIL_INBOX_UPDATE")
    advance(.05); speed=.1; event("MAIL_INBOX_UPDATE")
    local changed=#s.actions
    advance(.09)
    check(#s.actions==changed,label.." changed speed still waits for its requested deadline")
    advance(.01)
    check(#s.actions==changed+1,label.." earlier OpenSpeed preference supersedes later wake")
    event("MAIL_CLOSED")
end

for _,client in ipairs({"retail","forever","era","anniversary","mists"}) do
    for _,provider in ipairs({"builtin","syndicator","baganator","baganator+syndicator"}) do
        fixture(client,provider,false)
        fixture(client,provider,true)
    end
end
print(string.format("mail loot scheduling: %d checks, %d failures; burst timers=%d pending header reads=%d",
    checks,failures,burstCreates,burstReads))
if failures>0 then os.exit(1) end
