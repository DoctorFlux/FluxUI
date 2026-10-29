-- Real Store/Mail/Adapter; native post-hooks/events and provider API tables are mocked.
-- Syndicator GetCharacter returns its mutable stored record (independently checked
-- against local v288 API/Main.lua); this portable test adds no external fixture.
local source, measureOnly = "Inventory/Builtin/Mail.lua", false
local index = 1
while arg and index <= #arg do
    if arg[index] == "--source" then
        index = index + 1
        source = assert(arg[index], "--source requires a Mail.lua path")
    elseif arg[index] == "--measure" then
        measureOnly = true
    else
        error("unknown argument: " .. tostring(arg[index]))
    end
    index = index + 1
end
local checks, failures = 0, {}
local function check(value, label)
    checks = checks + 1
    if not value then failures[#failures + 1] = label end
end
local function rows(record) return record and record.mail and #record.mail or 0 end
local function itemCount(record, id)
    local count = 0
    for _, item in ipairs(record and record.mail or {}) do
        if item.itemID == id then count = count + item.itemCount end
    end
    return count
end

local function harness(missingMail)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local h = { events = {}, hooks = {}, frames = {}, callbacks = {}, reads = 0,
        providerReads = 0, requests = 0, ready = false, recipient = "Alt", attachments = true }
    env.UnitName = function() return "Test" end
    env.GetNormalizedRealmName = function() return "Realm" end
    env.GetTime = function() return 0 end
    env.time = function() return 1000 end
    env.SendMail = function() end
    env.ReturnInboxItem = function() end
    env.hooksecurefunc = function(name, fn)
        assert(not h.hooks[name], "native hook must be installed once")
        h.hooks[name] = fn
    end
    env.GetSendMailItem = function(i)
        h.reads = h.reads + 1
        if h.attachments and i == 1 then return "Pending", 111, 1, 3, 2 end
    end
    env.GetInboxHeaderInfo = function()
        h.reads = h.reads + 1
        return nil, nil, h.recipient, nil, nil, nil, 7, h.attachments and 1 or 0
    end
    env.GetInboxItem = function(_, i)
        h.reads = h.reads + 1
        if h.attachments and i == 1 then return "Pending", 111, 1, 3, 2 end
    end
    env.CreateFrame = function()
        local frame = { scripts = {}, events = {} }
        function frame:SetScript(kind, fn) self.scripts[kind] = fn end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        h.frames[#h.frames + 1] = frame
        return frame
    end
    local inv = { Builtin = {}, Syndicator = {}, Containers = { NewItemSetLog = function() return {} end },
        snapshots = { mail = { byIndex = {}, counts = {}, generation = 0 } },
        HasWarband = function() return false end }
    local ns = { Flux = { Inventory = inv, Cap = {},
        Events = { Register = function(event, fn)
            assert(not h.events[event], "native event must be installed once")
            h.events[event] = fn
        end },
        Scheduler = { Request = function() h.requests = h.requests + 1 end } } }
    for _, path in ipairs({ "Inventory/Store.lua", source, "Inventory/Syndicator/Adapter.lua" }) do
        assert(loadfile(path, "t", env))("_FluxUI", ns)
    end
    local db = inv.Store.GetDB()
    h.old = { mail = not missingMail and { { itemID = 900, itemCount = 1 } } or nil }
    db.Characters["Alt-Realm"] = h.old
    inv.Builtin.Start = function() inv.source = "builtin"; inv.Builtin.Mail.Start() end
    -- The production Ready transition and mail builder run; unrelated region
    -- builders are excluded so the fixture models only outgoing ownership.
    inv.Syndicator.RebuildAll = inv.Syndicator.RebuildMail
    function h.installProvider()
        h.provider = { mail = not missingMail and { { itemID = 222, itemCount = 99 } } or nil }
        h.providerCurrent = { mail = {} }
        env.Syndicator = { API = {
            IsReady = function() return h.ready end,
            GetCurrentCharacter = function() return "Test-Realm" end,
            GetCharacter = function(name)
                h.providerReads = h.providerReads + 1
                if name == "Alt-Realm" then return h.provider end
                if name == "Test-Realm" then return h.providerCurrent end
            end,
        }, CallbackRegistry = { RegisterCallback = function(_, event, fn)
            assert(not h.callbacks[event], "provider callback must be installed once")
            h.callbacks[event] = fn
        end } }
    end
    function h.action(kind)
        if kind == "send" and h.hooks.SendMail then h.hooks.SendMail(h.recipient)
        elseif kind == "return" and h.hooks.ReturnInboxItem then h.hooks.ReturnInboxItem(1) end
    end
    function h.event(event)
        -- Also permits replay of an already-delivered callback after cleanup.
        local frame = h.frames[1]
        if frame and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event) end
    end
    function h.subscriptions()
        local count = 0
        for _, frame in ipairs(h.frames) do for _ in pairs(frame.events) do count = count + 1 end end
        return count
    end
    function h.clean()
        for _, frame in ipairs(h.frames) do
            for _, event in ipairs({ "MAIL_SEND_SUCCESS", "MAIL_SUCCESS", "MAIL_FAILED" }) do
                if frame.events[event] then return false end
            end
        end
        return true
    end
    function h.resetCounts() h.reads, h.providerReads, h.requests = 0, 0, 0 end
    h.inv, h.env, h.db = inv, env, db
    return h
end

for _, kind in ipairs({ "send", "return" }) do
    local success = kind == "send" and "MAIL_SEND_SUCCESS" or "MAIL_SUCCESS"
    for _, missingMail in ipairs({ false, true }) do
        local suffix = missingMail and " missing-mail" or " existing-mail"
        for _, pending in ipairs({ false, true }) do
            for _, failed in ipairs({ false, true }) do
                local h = harness(missingMail)
                if pending then h.installProvider(); h.inv.Syndicator.Start()
                else
                    check(h.inv.Syndicator.Start() == false, kind .. " absent provider is retryable")
                    h.inv.Builtin.Start()
                end
                local label = kind .. suffix .. (pending and " pending" or " absent") .. (failed and " failure" or " success")
                check(h.inv.source == "builtin" and not h.inv.Store.UsesSyndicator(), label .. " built-in owns pending attribution")
                h.inv.Builtin.Mail.Start()
                local before = rows(h.old)
                h.action(kind)
                check(h.subscriptions() == 2 and #h.frames == 1, label .. " one frame waits for success/failure")
                h.event(failed and "MAIL_FAILED" or success)
                check(rows(h.old) == before + (failed and 0 or 1) and itemCount(h.old, 111) == (failed and 0 or 3),
                    label .. " only successful operation credits known alt")
                check((failed and h.db.Pending.Characters["Alt-Realm"] == nil)
                    or (not failed and h.db.Pending.Characters["Alt-Realm"] == 1),
                    label .. " standalone invalidation follows successful attribution")
                if not failed then
                    local rec = h.old.mail[#h.old.mail]
                    local days = kind == "send" and 30 or 7
                    check(rec.expirationTime == 1000 + days * 86400 and rec.quality == 2,
                        label .. " attachment expiration/quality retained")
                end
                check(h.clean() and h.subscriptions() == 0, label .. " all three completion events cleaned")
                h.event(success); h.event("MAIL_SUCCESS"); h.event("MAIL_FAILED")
                check(rows(h.old) == before + (failed and 0 or 1), label .. " duplicate callback does not credit twice")
                check(not pending or itemCount(h.provider, 111) == 0, label .. " pending external table is untouched")
            end
        end

        for _, failed in ipairs({ false, true }) do
            local h = harness(missingMail)
            h.installProvider(); h.inv.Syndicator.Start()
            local label = kind .. suffix .. " handoff " .. (failed and "failure" or "success")
            local oldRows, oldMail = rows(h.old), h.old.mail
            local providerRows, providerMail = rows(h.provider), h.provider.mail
            h.action(kind)
            check(h.subscriptions() == 2, label .. " operation captured before Ready")
            h.ready = true; h.callbacks.Ready()
            check(h.inv.Store.UsesSyndicator() and h.inv.source == "syndicator"
                and h.inv.Store.GetCharacter("Alt-Realm") == h.provider,
                label .. " real adapter selects direct provider-owned record")
            h.resetCounts(); h.event(failed and "MAIL_FAILED" or success)
            print(string.format("%s providerLookups=%d providerRowsDelta=%d providerAddedCount=%d savedRowsDelta=%d savedPending=%s retainedEvents=%d",
                label, h.providerReads, rows(h.provider) - providerRows, itemCount(h.provider, 111),
                rows(h.old) - oldRows, tostring(h.db.Pending.Characters["Alt-Realm"]), h.subscriptions()))
            check(h.providerReads == 0, label .. " stale completion never resolves provider destination")
            check(rows(h.provider) == providerRows and h.provider.mail == providerMail and itemCount(h.provider, 111) == 0,
                label .. " stale completion does not mutate/create provider mail")
            check(rows(h.old) == oldRows and h.old.mail == oldMail and h.db.Pending.Characters["Alt-Realm"] == nil,
                label .. " stale completion leaves standalone ledger and pending marks unchanged")
            check(h.clean() and h.subscriptions() == 0, label .. " all three completion events cleaned")
            check(h.requests == 0, label .. " stale completion schedules no inventory work")
            local rowsAfterCompletion, savedAfterCompletion = rows(h.provider), rows(h.old)
            h.event(success); h.event("MAIL_SUCCESS"); h.event("MAIL_FAILED")
            check(rows(h.provider) == rowsAfterCompletion and rows(h.old) == savedAfterCompletion,
                label .. " duplicate completion cannot append another payload")
            h.resetCounts(); h.action(kind)
            check(h.reads == 0 and h.providerReads == 0 and h.subscriptions() == 0 and #h.frames == 1,
                label .. " permanent hook remains inert under external ownership")
        end
    end

    for _, pending in ipairs({ false, true }) do
        for _, mode in ipairs({ "unknown", "empty" }) do
            local h = harness(false)
            if pending then h.installProvider(); h.inv.Syndicator.Start() else h.inv.Builtin.Start() end
            if mode == "unknown" then h.recipient = "Unknown" else h.attachments = false end
            h.action(kind)
            check(#h.frames == 0 and h.clean() and itemCount(h.old, 111) == 0
                and h.db.Pending.Characters["Alt-Realm"] == nil,
                kind .. " " .. mode .. (pending and " pending" or " absent") .. " does not arm attribution")
        end
    end
    local ready = harness(false)
    ready.installProvider(); ready.ready = true; ready.inv.Syndicator.Start()
    ready.inv.Builtin.Mail.Start(); ready.resetCounts(); ready.action(kind)
    check(next(ready.hooks) == nil and next(ready.events) == nil and #ready.frames == 0 and ready.reads == 0,
        kind .. " initially ready provider never installs built-in hooks")

    local repeated = harness(false)
    repeated.inv.Builtin.Start()
    local successes = 0
    for cycle = 1, 100 do
        repeated.action(kind)
        local failed = cycle % 2 == 0
        if not failed then successes = successes + 1 end
        repeated.event(failed and "MAIL_FAILED" or success)
        check(#repeated.frames == 1 and repeated.clean() and repeated.subscriptions() == 0
            and rows(repeated.old) == 1 + successes and itemCount(repeated.old, 111) == successes * 3,
            kind .. " standalone cycle " .. cycle .. " reuses one frame and cleans completion subscriptions")
    end
    print(string.format("%s standalone cycles=100 frames=%d retainedEvents=%d successfulCredits=%d",
        kind, #repeated.frames, repeated.subscriptions(), successes))
end

print(string.format("pending mail provider handoff: %d checks, %d failures; desktop operation counts only", checks, #failures))
for _, message in ipairs(failures) do print("FAIL " .. message) end
if not measureOnly then assert(#failures == 0, "pending mail provider handoff regressions") end
