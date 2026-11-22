-- Real inventory facade, scan, store and Syndicator callback adapter.
local root, referenceRoot = arg[1] or ".", arg[2] or "."
local checks, failures = 0, 0
local function check(value, message)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. message) end
end

local function harness(saved, actor, provider, prepare)
    local env = setmetatable({}, {__index = _G})
    env._G, env.FluxUIInventoryDB = env, saved
    local state = {clock = 0, open = false, shown = 0, total = 0, events = {}, frames = {}, callbacks = {},
        timers = {}, mailNotifies = 0, providerNotifies = 0, requests = 0}
    local inv = {Builtin = {}, Syndicator = {}, Containers = {NewItemSetLog = function() return {} end},
        snapshots = {mail = {byIndex = {}, counts = {}, generation = 0}},
        HasWarband = function() return false end,
        IsMailboxOpen = function() return state.open end,
        Notify = function(regions) if regions.mail then state.mailNotifies = state.mailNotifies + 1 end end}
    local flux = {Inventory = inv, Events = {Register = function(event, callback)
        local bucket = state.events[event] or {}
        state.events[event] = bucket
        bucket[#bucket + 1] = callback
        return true
    end}, Scheduler = {Request = function(_, token)
        state.requests = state.requests + 1
        if token == "mail" then state.providerNotifies = state.providerNotifies + 1 end
    end}}
    local ns = {Flux = flux}
    env.UnitName = function() return actor or "Main" end
    env.GetNormalizedRealmName = function() return "Realm" end
    env.GetTime = function() return state.clock end
    env.time = function() return 123456 end
    env.C_Timer = {After = function(delay, callback)
        state.timers[#state.timers + 1] = {at = state.clock + delay, callback = callback}
    end}
    env.GetInboxNumItems = function() return state.shown, state.total end
    env.GetInboxHeaderInfo = function()
        if state.shown > 0 then return nil, nil, nil, nil, nil, nil, 20, 1 end
    end
    env.GetInboxItem = function(_, index)
        if index == 1 and not state.missing then return "Fixture", 700, 1, 2, 1 end
    end
    env.CreateFrame = function()
        local frame = {scripts = {}}
        function frame:SetScript(kind, script) self.scripts[kind] = script end
        state.frames[#state.frames + 1] = frame
        return frame
    end
    if prepare then prepare(env, state) end
    assert(loadfile(referenceRoot .. "/Inventory/Syndicator/Sync.lua", "t", env))("_FluxUI", ns)
    for _, path in ipairs({"Inventory/Store.lua", "Inventory/Index.lua", "Inventory/Builtin/Mail.lua",
        "Inventory/Syndicator/Adapter.lua"}) do
        local source = path == "Inventory/Syndicator/Adapter.lua" and arg[4] or root .. "/" .. path
        assert(loadfile(source, "t", env))("_FluxUI", ns)
    end
    -- Other regions are irrelevant and remain outside this mailbox fixture.
    inv.Syndicator.RebuildAll = inv.Syndicator.RebuildMail
    inv.Builtin.Start = function()
        inv.source = "builtin"
        inv.Store.HydrateSnapshots()
        inv.Builtin.Mail.Start()
    end
    function state:fire(event, ...)
        for _, callback in ipairs(self.events[event] or {}) do callback(event, ...) end
    end
    function state:step()
        self.clock = self.clock + 0.25
        for _, frame in ipairs(self.frames) do
            if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame) end
        end
        for index = #self.timers, 1, -1 do
            local timer = self.timers[index]
            if timer.at <= self.clock then
                table.remove(self.timers, index)
                timer.callback()
            end
        end
    end
    function state:show() self.open = true; self:fire("MAIL_SHOW") end
    function state:update(shown, total)
        self.shown, self.total = shown, total
        self:fire("MAIL_INBOX_UPDATE")
    end
    function state:close() self.open = false; self:fire("MAIL_CLOSED") end
    function state:proved()
        return inv.Mail.HasObservedInbox and inv.Mail.HasObservedInbox() or false
    end
    function state:installProvider(ready, rows)
        self.ready = ready
        local name = (actor or "Main") .. "-Realm"
        self.provider = {details = {character = actor or "Main", realmNormalized = "Realm"}, mail = rows or {}}
        env.SYNDICATOR_DATA = {Version = 2, Characters = {[name] = self.provider}, Guilds = {}, Warband = {}}
        env.Syndicator = {API = {
            IsReady = function() return self.ready end,
            GetCurrentCharacter = function() return name end,
            GetCharacter = function(key) return env.SYNDICATOR_DATA.Characters[key] end,
        }, Constants = {AllBagIndexes = {}, AllBankIndexes = {}, AllWarbandIndexes = {}}, CallbackRegistry = {
            RegisterCallback = function(_, event, callback) self.callbacks[event] = callback end,
        }}
        self.character = name
        inv.Syndicator.Start()
    end
    function state:providerMail(rows, actorName)
        if rows then self.provider.mail = rows end
        self.callbacks.MailCacheUpdate(nil, actorName or self.character)
    end
    if provider then state:installProvider(true, provider) else inv.Builtin.Start() end
    state.inv, state.env = inv, env
    return state
end

local builtin = harness()
check(builtin.inv.GetSnapshotGeneration("mail") > 0 and not builtin:proved(), "fresh built-in hydration is unknown")
check(builtin.inv.Builtin.Mail.RecordAuctionDelivery(705, 3) and builtin.inv.Mail.GetCount(705) == 3
    and not builtin:proved(), "built-in receipt alone is not inbox proof")
check(builtin.inv.Mail.GetObservedCount(705) == nil, "a predicted built-in delivery is not physical mail")
builtin:show(); builtin:step()
check(not builtin:proved(), "opening and provisional empty publisher are not proof")
builtin:update(0, nil); builtin:step()
check(not builtin:proved(), "missing native total is not proof")
builtin:update(0, 2); builtin:step()
check(not builtin:proved(), "not all mail pages are available")
local publication = builtin.mailNotifies
builtin:update(0, 0); builtin:step()
check(builtin:proved() and builtin.inv.Mail.GetCount(705) == 0, "verified empty clears old predictions")
check(builtin.mailNotifies == publication + 1, "an unchanged count still publishes readiness")
check(builtin.inv.Builtin.Mail.RecordAuctionDelivery(705, 2) and builtin:proved(), "receipt preserves an existing observation")
check(builtin.inv.Mail.GetObservedCount(705) == 0, "known empty physical stock stays zero after a prediction")
local saved = builtin.env.FluxUIInventoryDB
local warm = harness(saved)
check(warm:proved() and warm.inv.Mail.GetCount(705) == 2, "warm same-character built-in reload keeps observed coverage")
check(not harness(saved, "Alt"):proved(), "another character has no claim on that observation")

local original = harness()
original:show(); original:update(1, 1); original:step()
check(original:proved() and original.inv.Mail.GetCount(700) == 2, "verified nonempty counts are ready")
check(original.inv.Mail.GetObservedCount(700) == 2, "built-in physical attachments count immediately on publication")
local originalSaved = original.env.FluxUIInventoryDB
local closeWarm = harness(originalSaved)
closeWarm.shown, closeWarm.total = 1, 1
closeWarm:show(); closeWarm:close(); closeWarm:step()
check(closeWarm:proved() and closeWarm.inv.Mail.GetCount(700) == 2, "unchanged forced close retains warm proof")
local unavailable = harness(originalSaved)
unavailable.shown = nil
local gen = unavailable.inv.GetSnapshotGeneration("mail")
unavailable:show(); unavailable:close(); unavailable:step()
check(unavailable:proved() and unavailable.inv.Mail.GetCount(700) == 2
    and unavailable.inv.GetSnapshotGeneration("mail") == gen, "unavailable native item count does not replace the cache")
local provisional = harness(originalSaved)
provisional:show(); provisional:step()
check(not provisional:proved() and provisional.inv.Mail.GetCount(700) == 0, "changed provisional rows retire warm proof")
original:show(); original:update(1, 1); original:step()
local changedClose = harness(original.env.FluxUIInventoryDB)
changedClose:show(); changedClose:close(); changedClose:step()
check(not changedClose:proved() and changedClose.inv.Mail.GetCount(700) == 0, "changed forced close retires warm proof")

local forced = harness()
forced:show(); forced:update(0, 0); forced:close(); forced:step()
check(not forced:proved(), "a forced closed read cannot establish proof even after an update")
local missing = harness()
missing.missing = true
missing:show(); missing:update(1, 1); missing:step()
check(not missing:proved(), "an incomplete attachment scan cannot establish proof")

local missingHeader = harness()
local readHeader = missingHeader.env.GetInboxHeaderInfo
missingHeader.env.GetInboxHeaderInfo = function() end
local noHeaderGeneration = missingHeader.inv.GetSnapshotGeneration("mail")
missingHeader:show(); missingHeader:update(1, 1); missingHeader:step()
check(not missingHeader:proved() and missingHeader.inv.GetSnapshotGeneration("mail") == noHeaderGeneration,
    "an advertised row without a loaded header cannot certify an empty inbox")
missingHeader.env.GetInboxHeaderInfo = readHeader
missingHeader:step(); missingHeader:step()
check(missingHeader:proved() and missingHeader.inv.Mail.GetCount(700) == 2,
    "a header that arrives during the bounded retry can verify its attachment")

local warmMissingHeader = harness(missingHeader.env.FluxUIInventoryDB)
warmMissingHeader.env.GetInboxHeaderInfo = function() end
local warmHeaderGeneration = warmMissingHeader.inv.GetSnapshotGeneration("mail")
warmMissingHeader:show(); warmMissingHeader:update(1, 1); warmMissingHeader:close(); warmMissingHeader:step()
check(warmMissingHeader:proved() and warmMissingHeader.inv.Mail.GetCount(700) == 2
    and warmMissingHeader.inv.GetSnapshotGeneration("mail") == warmHeaderGeneration,
    "a missing header in the close scan cannot replace an existing verified cache")

local letter = harness()
letter.env.GetInboxHeaderInfo = function() return nil, nil, nil, nil, nil, nil, 20, nil end
letter:show(); letter:update(1, 1); letter:step()
check(letter:proved() and letter.inv.Mail.GetCount(700) == 0,
    "a loaded header can certify an inbox with no attachments")

builtin:installProvider(true)
check(builtin.inv.source == "syndicator" and not builtin:proved(), "provider handoff retires built-in proof")
builtin.provider.mail[#builtin.provider.mail + 1] = {itemID = 706, itemCount = 4}
builtin:providerMail(); builtin:step()
check(builtin.inv.Mail.GetCount(706) == 4 and not builtin:proved(), "Syndicator receipt alone cannot establish proof")
check(builtin.inv.Mail.GetObservedCount(706) == nil, "Syndicator in-place auction appends are not observed attachments")
builtin:providerMail({}); builtin:step()
check(not builtin:proved(), "Syndicator table replacement without an inbox event is not proof")
builtin:update(0, 0)
builtin:providerMail(nil, "Alt-Realm"); builtin:step()
check(not builtin:proved(), "callback for another character cannot establish proof")
builtin:providerMail({}); builtin:step()
check(not builtin:proved(), "an opaque Syndicator callback cannot establish proof")

local cachedMail = harness(nil, nil, {{itemID = 4306, itemCount = 60}})
local physical, pending = cachedMail.inv.Mail.GetObservedCount(4306)
check(physical == nil and pending == 60 and not cachedMail:proved(),
    "a warm Syndicator cache reports 60 pending Silk Cloth without claiming physical mail")
cachedMail:show(); cachedMail:update(1, 1); cachedMail:providerMail({{itemID = 4306, itemCount = 60}})
physical, pending = cachedMail.inv.Mail.GetObservedCount(4306)
check(physical == 60 and pending == nil, "a fresh provider replacement promotes the cached pending quantity to physical mail")

local partial = harness(nil, nil, {})
local earlyPublication = partial.providerNotifies
partial:show(); partial:update(1, 2); partial:providerMail({{itemID = 700, itemCount = 2}})
check(partial.inv.Mail.GetObservedCount(700) == 2 and partial.providerNotifies == earlyPublication + 1,
    "Syndicator publishes physical mail before its settled snapshot debounce")
partial:step()
check(not partial:proved() and partial.inv.Mail.GetCount(700) == 2, "Syndicator partial counts remain visible but unverified")
partial.provider.mail[#partial.provider.mail + 1] = {itemID = 700, itemCount = 3}
partial:providerMail(); partial:step()
check(partial.inv.Mail.GetCount(700) == 5 and partial.inv.Mail.GetObservedCount(700) == 2,
    "an appended auction delivery cannot inflate an existing physical count")
partial:update(0, nil); partial:providerMail({}); partial:step()
check(not partial:proved(), "Syndicator callback with unavailable native total is not proof")
check(partial.inv.Mail.GetObservedCount(700) == nil, "a replacement with unknown coverage cannot establish zero")
local delegatedSaved = partial.env.FluxUIInventoryDB
check(not harness(delegatedSaved):proved(), "a provider import does not give built-in source authority")

local externalMailSource = arg[3]
if externalMailSource then
    -- Exercise the exact installed Syndicator publisher with a desktop model of
    -- object post-hooks and the provider's deferred item-data callbacks.
    local function makePublisher(options)
        local frames, items = {}, {}
        local installed = harness(nil, nil, nil, function(env, state)
            env.GetFramesRegisteredForEvent = function(event)
                assert(event == "MAIL_INBOX_UPDATE")
                if options.lookupError then error("unavailable frame enumeration") end
                return table.unpack(frames)
            end
            env.hooksecurefunc = function(object, name, after)
                if options.hookError and name == "SetScript" then error("unavailable object post-hook") end
                local original = assert(object[name])
                object[name] = function(...)
                    original(...)
                    after(...)
                end
            end
            state.deferred, state.cached, state.reads, state.starts = {}, {}, 0, 0
        end)
        local env = installed.env
        local deferred, cached = installed.deferred, installed.cached
        env.debugprofilestop = function() return 0 end
        env.ATTACHMENTS_MAX = 12
        env.GetInboxNumItems = function()
            installed.reads = installed.reads + 1
            if options.scalarError and installed.reads == 1 then error("temporary unavailable inbox count") end
            return installed.shown, installed.total
        end
        env.GetInboxHeaderInfo = function() return nil, nil, nil, nil, nil, nil, 20, 1 end
        env.GetInboxItem = function(mailIndex, index)
            if index == 1 and items[mailIndex] then return "Fixture", items[mailIndex], 1, 2, 1 end
        end
        env.C_Item = {IsItemDataCachedByID = function(itemID) return cached[itemID] == true end}
        env.GetInboxItemLink = function(index) return "item:" .. items[index] end
        local provider = {
            Config = {Get = function() return false end, Options = {DEBUG_TIMERS = "debug"}},
            Constants = {BattlePetCageID = 82800},
            Utilities = {LoadItemData = function(itemID, callback)
                local pending = deferred[itemID] or {}
                deferred[itemID] = pending
                pending[#pending + 1] = callback
                if installed.nested == itemID then
                    installed.nested = nil
                    assert(table.remove(pending, 1))()
                end
            end},
            CallbackRegistry = {TriggerEvent = function(_, event, name) installed.callbacks[event](nil, name) end},
        }
        assert(loadfile(externalMailSource, "t", env))("Syndicator", provider)
        local mailMixin = env.SyndicatorMailCacheMixin
        local scripts = {OnEvent = mailMixin.OnEvent}
        local owner = {currentCharacter = "Main-Realm", ScanMail = mailMixin.ScanMail,
            SetScript = function(_, key, handler) scripts[key] = handler end,
            GetScript = function(_, key) return scripts[key] end}
        local unrelated = {ScanMail = mailMixin.ScanMail, GetScript = function() end}
        frames = {unrelated, owner}
        installed.unrelated, installed.mixin = unrelated, mailMixin
        if not options.late then installed:fire("PLAYER_ENTERING_WORLD", false, true) end
        if options.preBindUpdate then installed:show(); installed:update(0, 0) end
        installed:installProvider(not options.providerReady)
        if options.providerReady then installed.callbacks.Ready(); installed.ready = true end
        function installed:change(shown, total, mailbox)
            items = mailbox
            self:update(shown, total)
            owner:GetScript("OnEvent")(owner, "MAIL_INBOX_UPDATE")
        end
        function installed:begin()
            self.starts = self.starts + 1
            owner:GetScript("OnUpdate")(owner)
        end
        function installed:finish(itemID)
            assert(table.remove(assert(deferred[itemID]), 1))()
        end
        return installed
    end
    local installed = makePublisher({})
    local deferred, cached = installed.deferred, installed.cached
    local function update(...) installed:change(...) end
    local function start() installed:begin() end
    local function finish(itemID) installed:finish(itemID) end

    installed:show(); update(1, 2, {700}); start()
    check(not installed:proved() and #deferred[700] == 1, "actual partial scan waits for item data")
    update(2, 2, {700, 701}); start()
    check(#deferred[700] == 2 and #deferred[701] == 1, "new full scan starts while the old scan is pending")
    finish(700); installed:step()
    check(not installed:proved() and installed.inv.Mail.GetCount(700) == 2 and installed.inv.Mail.GetCount(701) == 0,
        "old partial callback cannot borrow completeness from a newer full scan")
    finish(700); finish(701); installed:step()
    check(not installed:proved() and installed.inv.Mail.GetCount(701) == 2,
        "an opaque async publication updates counts without supplying a scan identity")

    cached[700], cached[701] = true, true
    local beforeReads, beforeStarts = installed.reads, installed.starts
    update(1, 2, {700})
    update(2, 2, {700, 701})
    start(); installed:step()
    check(installed.starts == beforeStarts + 1 and installed.reads == beforeReads + 2,
        "coalesced provider updates use one scan and one scalar completeness read")
    check(installed:proved() and installed.inv.Mail.GetCount(701) == 2,
        "the next clean full synchronous scan restores proof")
    check(installed.unrelated.ScanMail == installed.mixin.ScanMail, "a lookalike frame without the provider handler is never hooked")
    local providerRows = installed.provider.mail
    installed.provider.mail[#installed.provider.mail + 1] = {itemID = 702, itemCount = 3}
    installed:providerMail(); installed:step()
    check(installed.provider.mail == providerRows and installed:proved() and installed.inv.Mail.GetCount(702) == 3,
        "receipt append keeps the existing scan proof and updates its counts")
    update(1, 2, {700}); start(); installed:step()
    check(not installed:proved(), "even synchronous partial scans leave proof false")
    update(0, 0, {}); start(); installed:step()
    check(installed:proved() and installed.inv.Mail.GetCount(700) == 0,
        "one complete empty scan grants proof")

    cached[700] = false
    update(1, 2, {700}); start()
    cached[700] = true
    update(2, 2, {700, 701}); start(); installed:step()
    check(not installed:proved() and installed.inv.Mail.GetCount(701) == 2,
        "a reverse-order synchronous full scan cannot certify rows while an older scan waits")
    finish(700); installed:step()
    check(not installed:proved() and installed.inv.Mail.GetCount(701) == 0,
        "an older callback replacing verified rows retires proof with the new snapshot")
    update(0, 0, {}); start(); installed:step()
    check(installed:proved(), "a further clean scan restores proof after an out-of-order overwrite")

    cached[700], cached[701] = false, false
    update(1, 2, {700}); start()
    installed.nested = 700
    update(2, 2, {700, 701}); start(); installed:step()
    check(not installed:proved() and installed.inv.Mail.GetCount(700) == 2 and installed.inv.Mail.GetCount(701) == 0,
        "an old item callback nested inside a newer full ScanMail cannot establish completeness")
    finish(700); finish(701); installed:step()
    check(not installed:proved(), "the callback from the overlapped full scan also remains unverified")
    cached[700], cached[701] = true, true
    update(2, 2, {700, 701}); start(); installed:step()
    check(installed:proved() and installed.inv.Mail.GetCount(701) == 2,
        "one clean scan after nested overlap restores full counts and proof")
    check(not harness(installed.env.FluxUIInventoryDB, nil, installed.provider.mail):proved(),
        "Syndicator reload does not assume an independently owned cache is observed")

    update(0, 0, {}); installed:close(); start(); installed:step()
    check(not installed:proved(), "scheduled scan that runs after mailbox close cannot restore proof")

    local aborted = makePublisher({})
    aborted.cached[700] = true
    aborted:show(); aborted:change(1, 1, {700}); aborted:begin(); aborted:step()
    check(aborted:proved(), "a normal complete scan establishes proof before the transient error")
    local availableHeader = aborted.env.GetInboxHeaderInfo
    aborted.env.GetInboxHeaderInfo = function() end
    aborted:change(1, 1, {700})
    local succeeded, scanError = pcall(aborted.begin, aborted)
    check(not succeeded and scanError:find("daysLeft", 1, true) and not aborted:proved(),
        "an advertised unavailable header aborts the installed publisher and invalidates the old proof")
    aborted.env.GetInboxHeaderInfo = availableHeader
    aborted:change(1, 1, {700}); aborted:begin(); aborted:step()
    check(aborted:proved() and aborted.inv.Mail.GetCount(700) == 2,
        "a complete scan in the current mailbox recovers after the failed scan")

    local overlappedAbort = makePublisher({})
    overlappedAbort:show(); overlappedAbort:change(1, 2, {700}); overlappedAbort:begin()
    local completeHeader = overlappedAbort.env.GetInboxHeaderInfo
    overlappedAbort.env.GetInboxHeaderInfo = function(index)
        if index == 1 then return completeHeader() end
    end
    overlappedAbort:change(2, 2, {700, 701})
    succeeded, scanError = pcall(overlappedAbort.begin, overlappedAbort)
    check(not succeeded and scanError:find("daysLeft", 1, true) and #overlappedAbort.deferred[700] == 2,
        "the failing scan can already have requested data for previous rows")
    overlappedAbort.env.GetInboxHeaderInfo = completeHeader
    overlappedAbort.cached[700], overlappedAbort.cached[701] = true, true
    overlappedAbort:close(); overlappedAbort:show()
    overlappedAbort:change(2, 2, {700, 701}); overlappedAbort:begin(); overlappedAbort:step()
    check(not overlappedAbort:proved() and overlappedAbort.inv.Mail.GetCount(701) == 2,
        "reopening keeps a genuinely older deferred publication from borrowing current proof")
    overlappedAbort:finish(700); overlappedAbort:step()
    check(not overlappedAbort:proved() and overlappedAbort.inv.Mail.GetCount(701) == 0,
        "the older deferred scan can still replace the provider rows")
    overlappedAbort:finish(700); overlappedAbort:step()
    check(not overlappedAbort:proved() and overlappedAbort.inv.Mail.GetCount(701) == 0,
        "a deferred item callback from the failed scan cannot publish")
    overlappedAbort:change(2, 2, {700, 701}); overlappedAbort:begin(); overlappedAbort:step()
    check(overlappedAbort:proved() and overlappedAbort.inv.Mail.GetCount(701) == 2,
        "the next complete scan after reopening clears the error without a reload")

    local missingSlot = makePublisher({})
    local availableItem = missingSlot.env.GetInboxItem
    missingSlot.env.GetInboxItem = function() end
    missingSlot:show(); missingSlot:change(1, 1, {700}); missingSlot:begin(); missingSlot:step()
    check(not missingSlot:proved() and missingSlot.inv.Mail.GetCount(700) == 0,
        "a loaded header advertising one attachment prevents a skipped item slot from certifying an empty inbox")
    missingSlot.env.GetInboxItem = availableItem
    missingSlot.cached[700] = true
    missingSlot:change(1, 1, {700}); missingSlot:begin(); missingSlot:step()
    check(missingSlot:proved() and missingSlot.inv.Mail.GetCount(700) == 2,
        "the next matching publication verifies the loaded attachment and its stack count")

    local readyEmpty = makePublisher({})
    local function loadedEmptyHeader() return nil, nil, nil, nil, nil, nil, 20, nil end
    local headerReads = 0
    readyEmpty.env.GetInboxHeaderInfo = function()
        headerReads = headerReads + 1
        if headerReads == 1 then return loadedEmptyHeader() end
    end
    readyEmpty:show(); readyEmpty:change(1, 1, {}); readyEmpty:begin(); readyEmpty:step()
    check(not readyEmpty:proved(), "a header unavailable to the observer does not certify an empty provider list")
    readyEmpty.env.GetInboxHeaderInfo = loadedEmptyHeader
    local priorNotification = readyEmpty.providerNotifies
    readyEmpty:change(1, 1, {}); readyEmpty:begin(); readyEmpty:step()
    check(readyEmpty:proved() and readyEmpty.providerNotifies == priorNotification + 1,
        "a loaded money-only or text header with nil attachments verifies the unchanged empty list")

    local unknownCount = makePublisher({})
    unknownCount.env.GetInboxHeaderInfo = function() return nil, nil, nil, nil, nil, nil, 20, true end
    unknownCount:show(); unknownCount:change(1, 1, {}); unknownCount:begin(); unknownCount:step()
    check(not unknownCount:proved(), "an unsupported nonnumeric attachment indicator does not establish proof")
    local unknownStack = makePublisher({})
    unknownStack.cached[700] = true
    unknownStack.env.GetInboxItem = function(_, index)
        if index == 1 then return "Fixture", 700, 1, nil, 1 end
    end
    unknownStack:show(); unknownStack:change(1, 1, {700}); unknownStack:begin(); unknownStack:step()
    check(not unknownStack:proved(), "a provider row with missing stack size cannot satisfy verified attachment coverage")

    local held = makePublisher({})
    held:show(); held:change(0, 0, {}); held:fire("MAIL_CLOSED"); held:begin(); held:step()
    check(not held:proved(), "native close event fences a scan even while the inventory mailbox latch is held")

    local late = makePublisher({late = true})
    late:fire("PLAYER_ENTERING_WORLD", false, false)
    late:show(); late:change(0, 0, {}); late:begin(); late:step()
    check(late.inv.ready and not late:proved(), "unknown pre-load provider scans disable proof while leaving normal inventory ready")
    local preBind = makePublisher({preBindUpdate = true})
    preBind:change(0, 0, {}); preBind:begin(); preBind:step()
    check(preBind.inv.ready and not preBind:proved(), "an observed inbox update before an already-ready bind fences its unknown scans")
    local providerReady = makePublisher({late = true, providerReady = true})
    providerReady:show(); providerReady:change(0, 0, {}); providerReady:begin(); providerReady:step()
    check(providerReady:proved(), "the provider Ready callback establishes an observed start even for a late module")
    for _, options in ipairs({{lookupError = true}, {hookError = true}, {scalarError = true}}) do
        local fallback = makePublisher(options)
        fallback:show(); fallback.cached[700] = true
        fallback:change(1, 1, {700}); fallback:begin(); fallback:step()
        check(fallback.inv.ready and not fallback:proved() and fallback.inv.Mail.GetCount(700) == 2,
            "optional observer failure preserves otherwise normal Syndicator binding and counts")
    end
end

assert(failures == 0, ("%d/%d observed-inbox checks failed"):format(failures, checks))
print(("Mailbox observation: %d checks PASS; built-in and Syndicator owner, native mail and UI NOT RUN"):format(checks))
