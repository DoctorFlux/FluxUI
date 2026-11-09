-- Real Settings/Select/OpenAll modules; native frames, commands and timers mocked.
-- Optional arguments: alternate Select.lua and OpenAll.lua for baseline replay.
local selectSource = arg[1] or "Mail/Select.lua"
local openSource = arg[2] or "Mail/OpenAll.lua"
local checks, failures = 0, 0
local totals = {disabledActions = 0, disabledReads = 0, missedCancels = 0}
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end

local function boot(label, cancellable)
    local e = setmetatable({}, {__index = _G}); e._G = e
    local s = {now = 0, frames = {}, timers = {}, calls = {}, pendingReads = 0,
        commandPending = false, headerReads = 0, running = false, owner = "OpenAll"}
    local function widget(name)
        local f = {shown = true, events = {}}
        function f:RegisterEvent(event) self.events[event] = true end
        function f:SetScript(event, fn) self[event] = fn end
        function f:SetShown(on) self.shown = on end
        function f:IsShown() return self.shown end
        function f:SetText(text) self.text = text end
        function f:SetEnabled(on) self.enabled = on end
        function f:GetFrameLevel() return 1 end
        for _, key in ipairs({"SetPoint", "SetSize", "SetFrameLevel", "SetNormalTexture",
            "SetHighlightTexture", "SetDisabledTexture", "SetPushedTexture"}) do f[key] = function() end end
        s.frames[#s.frames + 1] = f
        if name then e[name] = f end
        return f
    end
    e.CreateFrame = function(_, name) return widget(name) end
    e.MailFrame, e.InboxFrame, e.OpenAllMail = widget(), widget(), widget()
    e.GetTime = function() return s.now end
    e.C_Timer = {}
    local function timer(delay, fn)
        local t = {at = s.now + delay, fn = fn}
        function t:Cancel() self.cancelled = true end
        s.timers[#s.timers + 1] = t
        return t
    end
    e.C_Timer.After = function(delay, fn) timer(delay, fn) end
    if cancellable then e.C_Timer.NewTimer = timer end
    e.C_Mail = {IsCommandPending = function()
        s.pendingReads = s.pendingReads + 1
        return s.commandPending
    end}
    e.ATTACHMENTS_MAX_RECEIVE = 16
    s.inbox = {{sender = "Friend", subject = "Supplies", money = 100, cod = 0, items = {205}}}
    e.GetInboxNumItems = function() return #s.inbox end
    e.GetInboxHeaderInfo = function(index)
        s.headerReads = s.headerReads + 1
        local h = s.inbox[index]
        if h then return nil,nil,h.sender,h.subject,h.money,h.cod,20,#h.items,false,false,false,false,false end
    end
    e.GetInboxItem = function(index, slot)
        local h = s.inbox[index]
        if h and h.items[slot] then return "Item",h.items[slot],nil,1 end
    end
    local ns = {Flux = {Container = {GetTotalFreeBagSlots = function() return 30 end},
        Mail = {OnJobStateChanged = function(running) s.running = running end}}}
    local function action(kind, index, slot)
        if not ns.Flux.Mail.IsEnabled(s.owner) then totals.disabledActions = totals.disabledActions + 1 end
        s.calls[#s.calls + 1] = {kind = kind, index = index, slot = slot, at = s.now}
        s.commandPending = true
    end
    e.TakeInboxMoney = function(index) action("money", index) end
    e.TakeInboxItem = function(index, slot) action("item", index, slot) end
    e.ReturnInboxItem = function(index) action("return", index) end
    e.DeleteInboxItem = function(index) action("delete", index) end
    e.InboxItemCanDelete = function() return true end
    assert(loadfile("Mail/Settings.lua", "t", e))("_FluxUI", ns)
    assert(loadfile(selectSource, "t", e))("_FluxUI", ns)
    assert(loadfile(openSource, "t", e))("_FluxUI", ns)
    s.mail, s.env, s.label = ns.Flux.Mail, e, label
    function s:event(event)
        for _, f in ipairs(self.frames) do
            if f.events[event] and f.OnEvent then f.OnEvent(f, event) end
        end
    end
    function s:advance(seconds)
        local deadline, limit = self.now + seconds, 1000
        while #self.timers > 0 do
            table.sort(self.timers, function(a,b) return a.at < b.at end)
            if self.timers[1].at > deadline + 1e-8 then break end
            local t = table.remove(self.timers, 1); self.now = t.at
            if not t.cancelled then limit = limit - 1; assert(limit > 0, "bounded lifecycle fixture"); t.fn() end
        end
        self.now = deadline
    end
    function s:activeTimers()
        local n = 0
        for _, t in ipairs(self.timers) do if not t.cancelled then n = n + 1 end end
        return n
    end
    function s:start(owner, mode)
        self.owner = owner or "OpenAll"
        if self.owner == "OpenAll" then self.mail.OpenAll(); return end
        local list = {}
        for index,h in ipairs(self.inbox) do list[#list + 1] = {index = index,
            header = {sender = h.sender, subject = h.subject, money = h.money, cod = h.cod, items = #h.items}} end
        self.mail.ProcessSelected(mode or "take", list, self.owner)
    end
    function s:ackMoney()
        self.inbox[1].money = 0; self.commandPending = false; self:event("MAIL_INBOX_UPDATE")
    end
    function s:closed()
        self.env.MailFrame.shown = false; self:event("MAIL_CLOSED")
    end
    s:event("MAIL_SHOW"); s:advance(0) -- Finish native-control installation retries.
    return s
end

for _, client in ipairs({"retail", "forever", "era", "anniversary", "mists"}) do
 for _, cancellable in ipairs({false, true}) do
    local label = client .. "/" .. (cancellable and "NewTimer" or "After")
    for _, owner in ipairs({"OpenAll", "Select"}) do
     for _, change in ipairs({"direct", "switch", "copy", "replace"}) do
        local s = boot(label .. "/" .. owner .. "/" .. change, cancellable)
        local m = s.mail
        if change == "switch" or change == "copy" then
            m.SwitchProfile("Disabled"); m.SetSetting("Modules", owner, false); m.SwitchProfile("Default")
        end
        s:start(owner)
        check(s.running and #s.calls == 1, s.label .. " starts once")
        if change == "direct" then m.SetSetting("Modules", owner, false)
        elseif change == "switch" then m.SwitchProfile("Disabled")
        elseif change == "copy" then m.CopyProfile("Disabled")
        else m.SetSetting("Modules", nil, {[owner] = false}) end
        check(not m.IsEnabled(owner) and not s.running, s.label .. " disables only its current job immediately")
        check(s.commandPending, s.label .. " leaves already-issued native command intact")
        if owner == "OpenAll" then
            check(not m.openAllRunning and s.env.OpenAllMail:IsShown(), s.label .. " hands native control back after stopping")
        end
        if cancellable then check(s:activeTimers() == 0, s.label .. " cancels owned timer handles") end
        s:ackMoney(); s:advance(20)
        check(#s.calls == 1, s.label .. " stale acknowledgements cannot issue another native action")
        check(not s.running, s.label .. " remains stopped after old deadlines")
        m.SetSetting("Modules", owner, true); s:closed()
        s.inbox = {{sender = "Friend", subject = "Reopen", money = 100, cod = 0, items = {205}}}
        local beforeReopen = #s.calls
        s.env.MailFrame.shown = true; s.commandPending = false; s:event("MAIL_SHOW"); s:start(owner)
        local n = #s.calls; check(n == beforeReopen + 1 and s.running, s.label .. " reenabling/reopening starts a fresh job")
        local ackAt = s.now; s:ackMoney(); s:advance(.499)
        check(#s.calls == n, s.label .. " retains configured minimum delay after reopen")
        s:advance(.001)
        check(#s.calls == n + 1 and s.calls[#s.calls].at >= ackAt + .5 - 1e-8,
            s.label .. " fresh job progresses at unchanged delay")
        s:closed()
     end
    end

    -- The worker must not act if a caller changes saved flags without a callback.
    local late = boot(label .. "/late flag", cancellable)
    late:start("Select")
    late.env.FluxMailDB.settings.Modules = {Select = false}
    late:ackMoney(); late:advance(.5)
    check(not late.running and #late.calls == 1, late.label .. " step rechecks current owner enable state")
    late:closed()

    -- Waiting on somebody else's command must not keep polling after disable.
    local busy = boot(label .. "/foreign wait", cancellable)
    busy.commandPending = true; busy:start("OpenAll")
    busy.mail.SetSetting("Modules", "OpenAll", false)
    local before = busy.pendingReads; busy:advance(20)
    totals.disabledReads = totals.disabledReads + busy.pendingReads - before
    check(not busy.running and #busy.calls == 0 and busy.pendingReads == before,
        busy.label .. " disabled job performs no native readiness polls")
    busy:closed()

    -- Final content can disappear before the native pending flag clears.
    for _, emptyInbox in ipairs({false, true}) do
        local s = boot(label .. (emptyInbox and "/empty inbox" or "/last letter"), cancellable)
        s.inbox[1].items = {}; s:start("OpenAll")
        s.inbox[1].money = 0
        if emptyInbox then s.inbox = {} end
        s:event("MAIL_INBOX_UPDATE")
        local reads = s.headerReads
        s.env.FluxMailOpenAllButton.OnClick(s.env.FluxMailOpenAllButton)
        if s.running then totals.missedCancels = totals.missedCancels + 1 end
        check(not s.running and not s.mail.openAllRunning, s.label .. " final pending job can be cancelled")
        check(s.headerReads == reads, s.label .. " cancellation does not rebuild the eligibility list")
        check(s.commandPending and #s.calls == 1, s.label .. " cancellation leaves native command alone")
        local pendingReads = s.pendingReads; s:advance(20)
        check(s.pendingReads == pendingReads and #s.calls == 1, s.label .. " cancellation invalidates every old wake")
        s:closed()
    end

    -- Other modules and profile flags must not stop the still-enabled owner.
    for _, owner in ipairs({"OpenAll", "Select"}) do
        local s = boot(label .. "/independent", cancellable); s:start(owner)
        for _, key in ipairs({owner == "OpenAll" and "Select" or "OpenAll", "DoNotWant", "CarbonCopy"}) do
            s.mail.SetSetting("Modules", key, false)
        end
        check(s.running and s.mail.IsEnabled(owner), s.label .. " unrelated modules do not cancel owner")
        s:ackMoney(); s:advance(.5)
        check(#s.calls == 2 and s.running, s.label .. " enabled owner continues normally")
        s:closed()
    end
    for _, mode in ipairs({"return", "delete"}) do
        local s = boot(label .. "/" .. mode, cancellable)
        s.inbox = {{sender = "Friend", subject = "Text", money = 0, cod = 0, items = {}}}
        s:start("Select", mode)
        s.mail.SetSetting("Modules", "Select", false)
        check(not s.running and #s.calls == 1 and s.calls[1].kind == mode and s.commandPending,
            s.label .. " disabled Select stops future " .. mode .. " work only")
        s:closed()
    end
 end
end
print(string.format("mail job lifecycle: %d checks, %d failures; disabled actions=%d disabled readiness reads=%d missed final cancels=%d",
    checks, failures, totals.disabledActions, totals.disabledReads, totals.missedCancels))
if failures > 0 then os.exit(1) end
