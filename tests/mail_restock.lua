-- Actual Settings/Select/OpenAll/Restock modules with explicit native mailbox mocks.
-- Client/provider labels exercise shared Lua; they do not certify native clients.
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function boot(client, provider, cancellable, saved)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local s = { now = 0, frames = {}, timers = {}, calls = {}, proofs = {}, snapshots = {},
        wanted = {}, inbox = {}, free = 20, pending = false, combat = false,
        nativeReads = 0, maxSliceReads = 0 }
    local function widget(name)
        local w = { events = {}, shown = true }
        function w:RegisterEvent(event) self.events[event] = true end
        function w:SetScript(event, fn) self[event] = fn end
        function w:SetShown(value) self.shown = value end
        function w:IsShown() return self.shown end
        function w:SetEnabled(value) self.enabled = value end
        function w:SetText(value) self.text = value end
        function w:SetChecked(value) self.checked = value end
        function w:GetChecked() return self.checked end
        function w:GetFrameLevel() return 1 end
        function w:CreateFontString() return widget() end
        function w:SetPoint(...) self.point = { ... } end
        for _, key in ipairs({ "SetSize", "SetFrameLevel", "SetNormalTexture", "SetHighlightTexture",
            "SetDisabledTexture", "SetPushedTexture" }) do w[key] = function() end end
        s.frames[#s.frames + 1] = w
        if name then e[name] = w end
        return w
    end
    e.CreateFrame = function(_, name) return widget(name) end
    e.MailFrame, e.InboxFrame, e.OpenAllMail = widget(), widget(), widget()
    e.GetTime = function() return s.now end
    e.GameTooltip = {
        SetOwner = function(_, owner, anchor) s.tipOwner, s.tipAnchor = owner, anchor end,
        ClearLines = function() s.tipLines = {} end,
        AddLine = function(_, text, red, green, blue, wrap)
            check(type(text) == "string" and red == 1 and green == 1 and blue == 1 and wrap == true,
                "tooltip adds one wrapped white text line with the correct argument types")
            s.tipLines[#s.tipLines + 1] = text
        end,
        SetText = function(_, text, red, green, blue, alpha, wrap)
            assert(alpha == nil or type(alpha) == "number", "tooltip SetText alpha must be numeric")
            s.tipLines = { text }
        end,
        Show = function() s.tipShown = true end,
        Hide = function() s.tipShown = false end,
    }
    e.InCombatLockdown = function() return s.combat end
    e.C_Timer = {}
    local function timer(delay, fn)
        local t = { at = s.now + delay, fn = fn }
        function t:Cancel() self.cancelled = true end
        s.timers[#s.timers + 1] = t
        return t
    end
    e.C_Timer.After = timer
    if cancellable then e.C_Timer.NewTimer = timer end
    e.C_Mail = { IsCommandPending = function() return s.pending end }
    e.Enum = { PlayerInteractionType = { MailInfo = 17 } }
    e.ATTACHMENTS_MAX_RECEIVE, e.ATTACHMENTS_MAX = 16, 16
    e.FluxMailDB = saved
    e.GetInboxNumItems = function() s.nativeReads = s.nativeReads + 1; return #s.inbox, s.total or #s.inbox end
    local function attachmentCount(h)
        local n = 0; for _ in pairs(h.items) do n = n + 1 end; return n
    end
    e.GetInboxHeaderInfo = function(index)
        s.nativeReads = s.nativeReads + 1
        local h = s.inbox[index]
        if h then return nil, nil, h.sender, h.subject, h.money, h.cod, 20, attachmentCount(h), false, false, false, false, h.gm end
    end
    e.GetInboxItem = function(index, slot)
        s.nativeReads = s.nativeReads + 1
        local h = s.inbox[index]
        local item = h and h.items[slot]
        if item and not item.unavailable then return "Item " .. item.id, item.id, nil, item.quantity, nil, nil, item.currency end
    end
    local function action(kind, index, slot)
        check(not s.pending, client .. " no overlapping native commands")
        check(not s.combat, client .. " no mail action in combat")
        local _, id, _, quantity = e.GetInboxItem(index, slot)
        s.calls[#s.calls + 1] = { kind = kind, index = index, slot = slot, id = id, quantity = quantity, at = s.now }
        s.pending = true
    end
    e.TakeInboxItem = function(index, slot) action("item", index, slot) end
    e.TakeInboxMoney = function(index) action("money", index) end
    local ns = { FluxOptionsLocale = { MAIL_RESTOCK = "Localized restock", MAIL_RESTOCK_AUTO = "Localized auto" }, Flux = {
        Container = { GetTotalFreeBagSlots = function() return s.free end }, Client = { [client] = true },
    } }
    local f = {}
    e.FluxAuctionRestock = { Followup = f }
    f.GetMailItems = function() local copy = {}; for id, n in pairs(s.wanted) do copy[id] = n end; return copy end
    f.MailTakeStarted = function(id, quantity)
        if s.reject or quantity > (s.wanted[id] or 0) then return false end
        s.proofs[#s.proofs + 1] = { id = id, quantity = quantity }
        return true
    end
    f.MailTakeFinished = function(id, quantity)
        s.wanted[id] = math.max(0, (s.wanted[id] or 0) - quantity)
        if s.wanted[id] == 0 then s.wanted[id] = nil end
    end
    f.MailSnapshotComplete = function(counts) s.snapshots[#s.snapshots + 1] = counts end
    for _, path in ipairs({ "Mail/Settings.lua", "Mail/Select.lua", "Mail/OpenAll.lua", "Mail/Restock.lua" }) do
        assert(loadfile(path, "t", e))("_FluxUI", ns)
    end
    s.mail, s.env, s.ns, s.restockFrame = ns.Flux.Mail, e, ns, s.frames[#s.frames]
    function s:realFollowup(receipts, providerCounts)
        local settings = { pending = {}, followup = { version = 1, receipts = {}, outputs = {} } }
        self.bags = {}
        for id, quantity in pairs(receipts) do
            settings.followup.receipts[id] = { remaining = quantity, lastBags = 0 }
            settings.pending[id] = { accepted = true, units = quantity }
        end
        local inv = { snapshots = { mail = { generation = 1 } }, Mail = {
            GetCount = function(id) return providerCounts[id] or 0 end,
        }, IsBagStorm = function() return self.bagStorm end }
        ns.Flux.Inventory = inv
        ns.Flux.Events = { Register = function() end, Unregister = function() end }
        e.FluxRestock = { Inv = {
            IsReliable = function() return not self.unreliable end,
            GetLiveCount = function(id) return self.bags[id] or 0 end,
        } }
        local a = { Number = function(value) return tonumber(value) end, Settings = function() return settings end,
            MailUnits = function(row) return providerCounts[row.itemID] or 0 end,
            Release = function(id) settings.pending[id] = nil end }
        e.FluxAuctionRestock = a
        assert(loadfile("Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua", "t", e))("_FluxUI", ns)
        a.Followup.Refresh()
        self.followup, self.settings, self.providerCounts = a.Followup, settings, providerCounts
    end
    function s:event(event, value)
        -- Native frame registration order is represented explicitly by load order.
        local frames = {}; for _, w in ipairs(self.frames) do frames[#frames + 1] = w end
        for _, w in ipairs(frames) do if w.events[event] and w.OnEvent then w.OnEvent(w, event, value) end end
    end
    function s:frame()
        local frames = {}; for _, w in ipairs(self.frames) do frames[#frames + 1] = w end
        for _, w in ipairs(frames) do if w.OnUpdate then
            local reads = self.nativeReads
            w.OnUpdate(w, 1 / 60)
            self.maxSliceReads = math.max(self.maxSliceReads, self.nativeReads - reads)
        end end
    end
    function s:pumpFrames(count) for _ = 1, count do self:frame() end end
    function s:advance(seconds)
        local deadline, guard = self.now + seconds, 4000
        while #self.timers > 0 do
            table.sort(self.timers, function(a, b) return a.at < b.at end)
            if self.timers[1].at > deadline + 1e-9 then break end
            local t = table.remove(self.timers, 1); self.now = t.at
            if not t.cancelled then guard = guard - 1; assert(guard > 0, "bounded mail worker"); t.fn(); self:pumpFrames(2) end
        end
        self.now = deadline
        self:pumpFrames(2)
    end
    function s:ack()
        local call = self.calls[#self.calls]
        local h = self.inbox[call.index]
        if call.kind == "money" then h.money = 0 else h.items[call.slot] = nil end
        if h.money == 0 and attachmentCount(h) == 0 then table.remove(self.inbox, call.index) end
        self.pending = false
        self:event("MAIL_INBOX_UPDATE")
        self:pumpFrames(2)
    end
    function s:show() self:event("MAIL_SHOW") end
    function s:close() self:event("MAIL_CLOSED") end
    function s:update() self:event("MAIL_INBOX_UPDATE"); self:pumpFrames(4) end
    return s
end
if FLUX_MAIL_RESTOCK_FIXTURE_EXPORT then return boot end
local function mail(items, extra)
    local h = { sender = "Auction House", subject = "Auction won", money = 0, cod = 0, items = items }
    for key, value in pairs(extra or {}) do h[key] = value end
    return h
end
local function item(id, quantity) return { id = id, quantity = quantity or 1 } end

for _, client in ipairs({ "retail", "forever", "era", "anniversary", "mists" }) do
 for _, provider in ipairs({ "builtin", "syndicator" }) do
  for _, cancellable in ipairs({ false, true }) do
    local label = client .. "/" .. provider .. "/" .. tostring(cancellable)
    local s = boot(client, provider, cancellable)
    check(s.mail.GetSetting("Restock", "AutoCollect") == true, label .. " new preference enables requested mailbox auto collection")
    s.wanted = { [101] = 1, [303] = 2 }
    s.inbox = { mail({ [1] = item(101), [2] = item(202, 3), [16] = item(303, 2) }, { money = 77 }) }
    s:show()
    check(#s.calls == 0 and #s.snapshots == 0, label .. " show cannot act or clear from an old inbox cache")
    check(s.env.FluxMailRestockButton == nil and s.env.FluxMailRestockAuto == nil,
        label .. " mailbox creates no duplicate restock button or auto checkbox")
    check(not s.mail.CanTakeRestockItems(), label .. " initial mailbox placeholder cannot advertise a usable take")
    s:update()
    check(#s.calls == 1 and s.calls[1].id == 303 and #s.proofs == 1, label .. " inbox visit automatically starts only acknowledged attachment")
    check(not s.mail.CanTakeRestockItems() and s.mail.GetSetting("Restock", "AutoCollect"),
        label .. " active mail owner is not ready for another batch and preserves the auto preference")
    s:ack(); s:advance(.49)
    check(#s.calls == 1, label .. " subset respects configured opening cadence")
    s:advance(.01)
    check(#s.calls == 2 and s.calls[2].id == 101, label .. " subset prepares next matching attachment without taking money")
    s:ack(); s:advance(.5)
    check(not s.mail.GetJobGroup() and s.inbox[1].money == 77 and s.inbox[1].items[2].id == 202,
        label .. " unrelated attachment and money remain in the same message")
    local snapshot = s.snapshots[#s.snapshots]
    check(snapshot[202] == 3 and not snapshot[101] and not snapshot[303], label .. " complete snapshot includes unrelated physical item counts")
    check(not s.mail.CanTakeRestockItems(), label .. " completed restock does not advertise another take")

    s = boot(client, provider, cancellable)
    s.mail.SetSetting("Restock", "AutoCollect", false)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }) }
    s:show(); s:update()
    check(#s.calls == 0 and s.mail.CanTakeRestockItems(), label .. " saved auto false leaves the pending-item action ready")
    s.mail.TakeRestockItems()
    check(#s.calls == 1, label .. " manual restock uses same subset worker")
    s:ack(); s:advance(.5)
    check(not s.mail.GetJobGroup() and #s.calls == 1, label .. " manual job finishes normally")
    s.mail.SwitchProfile("Other"); check(s.mail.GetSetting("Restock", "AutoCollect"), label .. " profile defaults retain new auto option")
    s.mail.SwitchProfile("Default"); check(not s.mail.GetSetting("Restock", "AutoCollect"), label .. " profile preserves explicit opt out")
    local reload = boot(client, provider, cancellable, s.env.FluxMailDB)
    check(not reload.mail.GetSetting("Restock", "AutoCollect"), label .. " auto opt out survives saved variable reload")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }
    s.inbox = { mail({ item(101) }, { cod = 2 }), mail({ item(101) }, { gm = true }), mail({ item(101, 2) }) }
    s:show(); s:update(); s:advance(1)
    check(#s.calls == 0, label .. " COD GM and unsplittable excess attachments stay untouched")
    s.inbox[3].items[1] = item(101)
    s.reject = true; s:update()
    check(#s.calls == 0 and not s.mail.GetJobGroup(), label .. " rejected current receipt proof prevents native take")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }) }; s.inbox[1].items[1].unavailable = true
    s:show(); s:update()
    check(#s.calls == 0 and #s.snapshots == 0, label .. " unavailable item metadata is never empty authoritative mail")
    s:advance(.3); check(#s.calls == 0, label .. " metadata retries use shared cadence")
    s.inbox[1].items[1].unavailable = nil; s:advance(.2)
    check(#s.calls == 1 and #s.snapshots > 0, label .. " valid metadata resumes the same worker")
    s:close(); s.pending = false; s:advance(20)
    check(not s.mail.GetJobGroup() and #s.calls == 1 and not s.mail.CanTakeRestockItems(), label .. " close cancels all subset work and readiness")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }) }; s.free = 1
    s:show(); s:update()
    check(#s.calls == 0 and not s.mail.GetJobGroup(), label .. " Open All free slot reservation applies to restock")
    s.free = 2; s:update()
    check(#s.calls == 1, label .. " free bag space permits next event driven attempt")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }) }; s.pending = true
    s:show(); s:update(); s:advance(.5)
    check(#s.calls == 0 and #s.snapshots == 0, label .. " native command lock blocks extraction and authoritative snapshot")
    s.pending = false; s:advance(.1)
    check(#s.calls == 1, label .. " existing bounded worker lock wait resumes safely")
    s.mail.StopRestockItems(); s:ack(); s:advance(10)
    check(#s.calls == 1 and not s.mail.GetJobGroup(), label .. " explicit cancellation cannot restart from its command acknowledgement")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }) }; s.combat = true
    s:show(); s:update()
    check(#s.calls == 0 and not s.mail.CanTakeRestockItems(), label .. " combat prevents pending-item readiness and auto extraction")
    s.combat = false; s:event("PLAYER_REGEN_ENABLED")
    check(#s.calls == 0, label .. " combat exit only refreshes state")
    s:update(); check(#s.calls == 1, label .. " next mailbox update may start after combat")
    s.combat = true; s:event("PLAYER_REGEN_DISABLED"); s.pending = false; s:advance(10)
    check(#s.calls == 1 and not s.mail.GetJobGroup(), label .. " combat entry stops active extraction")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }) }; s.total = 2
    s:show(); s:update()
    check(#s.snapshots == 0, label .. " partial native inbox cannot clear remaining receipts")
    s:close(); s.pending = false; s.inbox = {}; s.total = 0; s:show()
    check(#s.snapshots == 0, label .. " reopening still requires a fresh inbox update")
    s:update()
    check(#s.snapshots > 0 and next(s.snapshots[#s.snapshots]) == nil, label .. " complete empty mailbox is authoritative too")

    s = boot(client, provider, cancellable)
    s.wanted = {}; s.inbox = { mail({ item(202) }, { money = 7 }) }
    s:show(); s:update()
    check(#s.calls == 0 and not s.mail.GetJobGroup(), label .. " unrelated inbox never activates a restock job")
    s.wanted = { [101] = 1 }; s.inbox[1].items[2] = item(101)
    s.mail.ProcessSelected("take", { { index = 1, header = { sender = "Auction House", subject = "Auction won", cod = 0 } } }, "Select")
    check(s.mail.GetJobGroup() == "Select" and s.calls[1].kind == "money", label .. " normal selection still collects whole selected message")
    s:update()
    check(s.mail.GetJobGroup() == "Select" and #s.calls == 1, label .. " restock auto cannot cancel or overlap selection owner")
    s:event("MAIL_FAILED")
    check(s.mail.GetJobGroup() == "Select" and #s.calls == 1, label .. " restock failure guard preserves pre-existing selected job behavior")
    check(not s.mail.ProcessRestockItems(s.wanted, { GetItems = function() return s.wanted end, OnTake = function() return true end }), label .. " subset API refuses another active owner")
    s.mail.SetSetting("Modules", "Select", false); s.pending = false
    s.mail.SetSetting("Modules", "Restock", false); s:update()
    check(#s.calls == 1 and not s.mail.CanTakeRestockItems(), label .. " disabling restock prevents pending-item readiness and auto actions")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }) }
    s.env.OpenAllMail.timeUntilNextRetrieval = .15
    s:show(); s:update(); s:advance(1)
    check(#s.calls == 0 and not s.mail.GetJobGroup(), label .. " native Open All gap retains its owner without takeover")
    s.env.OpenAllMail.timeUntilNextRetrieval = nil; s:update()
    check(#s.calls == 1, label .. " native Open All relinquishes ownership before restock starts")

    -- Real saved follow-up receipts with a provider that never updates and no
    -- net bag growth (e.g. an old charged copy is consumed as mail arrives).
    s = boot(client, provider, cancellable)
    s.inbox = { mail({ item(101) }), mail({ item(101) }) }
    s:realFollowup({ [101] = 2 }, { [101] = 2 })
    s:show(); s:update()
    check(#s.calls == 1 and s.settings.followup.receipts[101].remaining == 2, label .. " real acknowledged receipt starts first matching attachment")
    check(s.followup.GetState().canAct == false,
        label .. " global mail automation immediately publishes busy readiness without another inventory event")
    s:ack(); s:advance(.5)
    check(#s.calls == 2 and s.settings.followup.receipts[101].remaining == 1,
        label .. " authoritative partial take permits next attachment despite stale provider and unchanged bags")
    s:ack(); s:advance(.5)
    check(not s.settings.followup and not s.settings.pending[101] and not s.mail.GetJobGroup(),
        label .. " complete native empty inbox clears only own accepted receipt and pending")
    check(not s.mail.CanTakeRestockItems() and #s.calls == 2, label .. " completed job does not manufacture provider stock or extra mail actions")

    s = boot(client, provider, cancellable)
    s.mail.SetSetting("Restock", "AutoCollect", false)
    s.inbox = { mail({ item(101) }) }; s.wanted = { [101] = 1 }
    s:show(); s:update()
    s.mail.SetSetting("Restock", "AutoCollect", true)
    check(#s.calls == 1, label .. " enabling auto in an open ready mailbox immediately uses acknowledged work")

    s = boot(client, provider, cancellable)
    s.ns.FluxOptionsLocale = { MAIL_RESTOCK = "Late restock", MAIL_RESTOCK_AUTO = "Late auto" }
    s:show()
    check(s.env.FluxMailRestockButton == nil and s.env.FluxMailRestockAuto == nil,
        label .. " late locale initialization cannot recreate mailbox restock controls")
    local reads = s.nativeReads
    for _ = 1, 50 do s.restockFrame.OnEvent(s.restockFrame, "MAIL_INBOX_UPDATE"); s:frame() end
    check(s.nativeReads == reads and s.restockFrame.OnUpdate == nil, label .. " no acknowledged job means zero native snapshot reads or idle frame work")

    s = boot(client, provider, cancellable)
    s.mail.SetSetting("Restock", "AutoCollect", false)
    s.wanted = { [101] = 1 }
    for index = 1, 100 do
        local attachments = {}; for slot = 1, 16 do attachments[slot] = item(index == 100 and slot == 16 and 101 or 202) end
        s.inbox[index] = mail(attachments)
    end
    s:show(); s:event("MAIL_INBOX_UPDATE"); s:frame()
    check(#s.snapshots == 0 and s.restockFrame.OnUpdate ~= nil and s.nativeReads < 100, label .. " full inbox scan yields after bounded first frame")
    local firstReads = s.nativeReads
    s.inbox[1].items[1] = item(404, 2)
    s:event("MAIL_INBOX_UPDATE") -- Discard the partially captured old generation.
    for _ = 1, 50 do s:frame() end
    local snapshot = s.snapshots[#s.snapshots]
    check(snapshot and snapshot[404] == 2 and snapshot[202] == 1598 and snapshot[101] == 1,
        label .. " new inbox generation discards partial capture before publishing exact counts")
    check(s.maxSliceReads <= 48 and s.nativeReads > firstReads and s.restockFrame.OnUpdate == nil,
        label .. " every scan frame respects the48 call budget and stops on completion")
    reads = s.nativeReads
    for _ = 1, 30 do s.mail.OnJobStateChanged(false, "Other"); s:frame() end
    check(s.nativeReads == reads, label .. " complete current generation is cached across repeated UI refreshes")
    s.combat = true; s:event("PLAYER_REGEN_DISABLED")
    check(s.restockFrame.OnUpdate == nil, label .. " combat removes full mailbox snapshot work")
    s:close(); check(s.restockFrame.OnUpdate == nil, label .. " mailbox close removes demand frame work")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }
    for index = 1, 100 do s.inbox[index] = mail({ item(index == 1 and 101 or 202) }) end
    s:show(); s:event("MAIL_INBOX_UPDATE"); s:pumpFrames(50)
    check(#s.calls == 1 and s.calls[1].index == 1 and s.maxSliceReads <= 48,
        label .. " full inbox auto queue skips unrelated headers using the bounded native snapshot")

    s = boot(client, provider, cancellable)
    s.mail.SetSetting("Restock", "AutoCollect", false)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }) }
    local clock = 0
    s.env.debugprofilestop = function() clock = clock + .6; return clock end
    s:show(); s:event("MAIL_INBOX_UPDATE"); s:frame()
    check(s.maxSliceReads <= 1 and #s.snapshots == 0, label .. " one millisecond time budget can yield before48 calls")
    s:pumpFrames(22)
    check(#s.snapshots == 1 and s.restockFrame.OnUpdate == nil, label .. " time budget still completes the exact snapshot")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }) }; s.inbox[1].items[1].unavailable = true
    s:show(); s:update(); s:advance(8)
    check(#s.calls == 0 and #s.snapshots == 0 and s.restockFrame.OnUpdate == nil,
        label .. " unconfirmed metadata has a bounded demand scan deadline")
    reads = s.nativeReads; s:advance(30)
    check(s.nativeReads == reads, label .. " metadata timeout does not leave a recurring native reader")

    s = boot(client, provider, cancellable)
    s.inbox = { mail({ item(101) }), mail({ item(101) }) }
    s:realFollowup({ [101] = 2 }, { [101] = 2 })
    s:show(); s:update(); s.bagStorm = true
    s:ack(); s:advance(.5)
    check(#s.calls == 2, label .. " owned native attachment proof continues through a bag storm between takes")
    s:ack(); s:advance(.5)
    check(not s.settings.followup and not s.settings.pending[101], label .. " stormed final native receipt releases only confirmed owned pending")

    s = boot(client, provider, cancellable)
    s.inbox = { mail({ item(101) }) }
    s:realFollowup({ [101] = 1 }, { [101] = 1 })
    s:show(); s:update(); s:advance(8)
    check(#s.calls == 1 and not s.mail.GetJobGroup() and s.settings.followup.receipts[101].remaining == 1,
        label .. " native timeout stops the worker without discarding the receipt")
    s.pending = false
    s:pumpFrames(2); s.mail.TakeRestockItems()
    check(#s.calls == 2, label .. " manual retry after native timeout has no stale followup take lock")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }) }
    s:show(); s:update(); s.combat = true; s:event("PLAYER_REGEN_DISABLED")
    s.pending = false; s.combat = false; s:event("PLAYER_REGEN_ENABLED"); s:pumpFrames(2)
    check(#s.calls == 2, label .. " automatic job resumes after combat without another mailbox event")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1 }; s.inbox = { mail({ item(101) }), mail({}, { money = 7 }) }
    s:show()
    s.mail.ProcessSelected("take", { { index = 2, header = { sender = "Auction House", subject = "Auction won", cod = 0 } } }, "Select")
    s:update()
    check(s.mail.GetJobGroup() == "Select" and #s.calls == 1, label .. " foreign shared job retains ownership during snapshot preparation")
    s:ack(); s:advance(.5); s:pumpFrames(2)
    check(#s.calls == 2 and s.calls[2].id == 101 and s.mail.GetJobGroup() == "Restock",
        label .. " automatic restock begins after the shared selected job relinquishes ownership")

    s = boot(client, provider, cancellable)
    s.wanted = { [101] = 1, [303] = 1 }; s.inbox = { mail({ item(101) }, { money = 7 }) }
    s:show(); s:update()
    s.inbox[2] = mail({ item(303) }) -- Arrives while the first command owns the worker.
    s:ack(); s:advance(.5)
    check(#s.calls == 2 and s.calls[2].id == 303 and s.inbox[1].money == 7,
        label .. " newly arrived acknowledged attachment continues after the original fixed queue completes")
    s:ack(); s:advance(.5)
    check(#s.calls == 2 and not s.mail.GetJobGroup(), label .. " new generation continuation cannot loop on unrelated leftover mail")

    s = boot(client, provider, cancellable)
    s.total = 200
    for index = 1, 50 do s.inbox[index] = mail({ item(index == 25 and 101 or 202) }) end
    s:realFollowup({ [101] = 2, [303] = 1 }, { [101] = 2, [303] = 1 })
    s:show(); s:event("MAIL_INBOX_UPDATE"); s:pumpFrames(25)
    check(#s.calls == 1 and s.calls[1].id == 101 and #s.snapshots == 0,
        label .. " fifty of two hundred mails can collect only the verified visible restock item without absence authority")
    s:ack(); s:pumpFrames(25); s:advance(.5)
    check(s.settings.followup.receipts[101].remaining == 1 and s.settings.followup.receipts[303].remaining == 1,
        label .. " partial inbox confirmation credits exactly one and preserves both inaccessible receipts")
    check(s.settings.pending[101] and s.settings.pending[303] and #s.calls == 1,
        label .. " inaccessible mail is never mistaken for an absent item or cleared pending")
    s.bags[101] = 1; s.followup.Refresh()
    check(s.settings.followup.receipts[101] and s.settings.followup.receipts[101].remaining == 1,
        label .. " deferred bag publication cannot credit the same partial inbox attachment twice")

    s = boot(client, provider, cancellable)
    s.total = 200
    for index = 1, 50 do s.inbox[index] = mail({ item((index == 25 or index == 50) and 101 or 202) }, { money = 7 }) end
    s:realFollowup({ [101] = 3 }, { [101] = 3 })
    s:show(); s:event("MAIL_INBOX_UPDATE"); s:pumpFrames(25)
    s:ack(); s:pumpFrames(25); s:advance(.5)
    check(#s.calls == 2 and s.calls[2].id == 101, label .. " partial inbox can confirm consecutive same SKU attachments before bag publication")
    s:ack(); s:pumpFrames(25); s:advance(.5)
    check(s.settings.followup.receipts[101].remaining == 1, label .. " two confirmed visible copies leave exactly one inaccessible copy")
    s.bags[101] = 2; s.followup.Refresh()
    check(s.settings.followup.receipts[101] and s.settings.followup.receipts[101].remaining == 1,
        label .. " delayed batch bag publication cannot double credit multiple confirmed attachments")

    s = boot(client, provider, cancellable)
    s:realFollowup({ [101] = 1 }, { [101] = 1 })
    s:show()
    check(s.settings.followup and s.settings.pending[101] and s.followup.GetState().kind == "mail",
        label .. " initial zero placeholder at mailbox show cannot discard acknowledged pending")
    s:update()
    check(not s.settings.followup and not s.settings.pending[101] and s.followup.GetState() == nil,
        label .. " settled zero of zero native mailbox clears stale own pending context and HUD immediately")
    check(#s.calls == 0 and not s.mail.GetJobGroup() and s.restockFrame.OnUpdate == nil,
        label .. " complete empty mailbox leaves no extraction action worker or frame reader")
    check(s.providerCounts[101] == 1, label .. " empty mailbox reconciliation never changes provider owned mail ledger")

    for _, failed in ipairs({ false, true }) do
        s = boot(client, provider, cancellable)
        s.total = 200; s.inbox = { mail({ item(101) }) }
        s:realFollowup({ [101] = 1 }, { [101] = 1 })
        s:show(); s:update()
        if failed then
            s:event("MAIL_FAILED")
            check(not s.mail.GetJobGroup() and s.settings.followup.receipts[101].remaining == 1,
                label .. " mail failure immediately stops only its own restock worker without receipt credit")
        end
        table.insert(s.inbox, 1, mail({ item(202) }, { subject = "Unrelated new delivery" }))
        s.pending = false; s:update(); s:advance(.5)
        check(#s.calls == 1 and s.inbox[2].items[1].id == 101 and s.settings.followup and s.settings.followup.receipts[101].remaining == 1,
            label .. " foreign header shift never proves an owned attachment arrived, failure=" .. tostring(failed))
        check(s.settings.pending[101] and not s.mail.GetJobGroup(), label .. " rejected or shifted native take retains pending and relinquishes worker")
    end

    s = boot(client, provider, cancellable)
    s.mail.SetSetting("Restock", "AutoCollect", false)
    s.inbox = { mail({ item(101) }), mail({ item(101) }) }
    s:realFollowup({ [101] = 2 }, { [101] = 2 })
    s:show(); s:update()
    local f = s.followup
    s.mail.ProcessRestockItems(f.GetMailItems(), {
        list = { { index = 1, header = { sender = "Auction House", subject = "Auction won", cod = 0 } } },
        GetItems = f.GetMailItems, OnTake = f.MailTakeStarted, OnTaken = f.MailTakeFinished, OnStop = f.MailTakeCancelled,
    })
    s:ack(); s:advance(.5)
    check(#s.calls == 2 and s.calls[2].index == 1 and s.settings.followup.receipts[101].remaining == 1,
        label .. " proved first arrival advances when identical next mail compacts into the same index and slot")
    s:ack(); s:advance(.5)
    check(not s.settings.followup and not s.settings.pending[101] and #s.calls == 2,
        label .. " identical mail compaction credits each owned receipt once")

    s = boot(client, provider, cancellable)
    s.inbox = { mail({ item(101) }), mail({ item(101) }), mail({ item(101) }) }
    s:realFollowup({ [101] = 3 }, { [101] = 3 })
    s:show(); s:update(); s.bagStorm = true
    s:ack() -- Complete native snapshot arrives before the worker's .5s progress wake.
    check(s.settings.followup.receipts[101].remaining == 2, label .. " authoritative native snapshot credits the first owned attachment during bag storm")
    s.bagStorm = false; s.bags[101] = 1; s.followup.Refresh()
    check(s.settings.followup.receipts[101].remaining == 2,
        label .. " snapshot-first receipt proof suppresses its later delayed bag credit too")
  end
 end
end
print("Mail restock: " .. checks .. " checks PASS /20 client-provider-timer profiles")
