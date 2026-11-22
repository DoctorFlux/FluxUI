-- Collect only acknowledged auction-restock attachments through the mail worker.
local _, ns = ...
local Flux = ns.Flux
local Mail = Flux.Mail or {}
Flux.Mail = Mail
local opened, inboxUpdated, autoStopped = false, false, false
local updating
local frame, scan, complete, generation = nil, nil, nil, 0
local failedGeneration
local suspending
local requested, active
local Update, Start

local function Followup()
    local a = _G.FluxAuctionRestock
    return a and a.Followup
end
local function Combat() return InCombatLockdown and InCombatLockdown() end
local function Enabled() return not Mail.IsEnabled or Mail.IsEnabled("Restock") end
local function Items(companion)
    local f = Followup()
    return f and f.GetMailItems and f.GetMailItems(companion) or {}
end
local function HasNewTargets(current, captured)
    for id, quantity in pairs(current) do
        if quantity > (captured[id] or 0) then return true end
    end
    return false
end
local function BuyerMail(index)
    local invoice = GetInboxInvoiceInfo and GetInboxInvoiceInfo(index)
    return not (issecretvalue and issecretvalue(invoice)) and invoice == "buyer"
end

local function StopScan()
    scan = nil
    if frame then frame:SetScript("OnUpdate", nil) end
end
local function Invalidate()
    generation, complete = generation + 1, nil
    failedGeneration = nil
    StopScan()
end
local function Busy() return C_Mail and C_Mail.IsCommandPending and C_Mail.IsCommandPending() end
local function NativeOpenAll() return OpenAllMail and OpenAllMail.timeUntilNextRetrieval ~= nil end
local function FreeSpace()
    local free = Flux.Container and Flux.Container.GetTotalFreeBagSlots
    return not free or free() > (tonumber(Mail.GetSetting("OpenAll", "KeepFreeSpace")) or 1)
end
local function Automatic() return Mail.GetSetting("Restock", "AutoCollect") == true end
local function Clock() return debugprofilestop and debugprofilestop() or (GetTime and GetTime() * 1000 or 0) end
local function Match(row, index, header, id, quantity)
    row = row or { index = index, items = {}, header = header }
    row.items[id] = math.min(row.items[id] or quantity, quantity)
    return row
end
local function MatchAttachment(work, id, quantity, calls)
    if not work.eligible then return calls end
    local owner = quantity <= (work.owner[id] or 0)
    local companion = quantity <= (work.companion[id] or 0)
    if companion and work.buyer == nil then
        work.buyer = BuyerMail(work.index)
        calls = calls + 1
    end
    if not owner and not (companion and work.buyer) then return calls end
    local header = work.header or {
        sender = work.sender or "", subject = work.subject or "", money = tonumber(work.money) or 0,
        cod = 0, items = work.attachments, gm = false,
    }
    work.header = header
    if owner then work.ownerRow = Match(work.ownerRow, work.index, header, id, quantity) end
    if companion and work.buyer then work.companionRow = Match(work.companionRow, work.index, header, id, quantity) end
    return calls
end
local function Slice()
    local work = scan
    if not work then return end
    if not opened or Combat() or not Enabled() then StopScan(); return end
    local now = GetTime and GetTime() or 0
    if now >= work.deadline then
        failedGeneration = generation; StopScan()
        if Mail.NotifyRestockSnapshotReady then Mail.NotifyRestockSnapshotReady() end
        return
    end
    if work.retryAt and now < work.retryAt then return end
    if Busy() or NativeOpenAll() then return end
    if work.done then
        complete = work
        StopScan()
        local f = Followup()
        if next(work.owner) and work.authoritative and f and f.MailSnapshotComplete then f.MailSnapshotComplete(work.counts) end
        Update(true)
        if Mail.NotifyRestockSnapshotReady then Mail.NotifyRestockSnapshotReady() end
        return
    end
    local calls, started = 0, Clock()
    local function Retry()
        work.index, work.slot, work.loaded, work.counts = 1, nil, nil, {}
        work.ownerList, work.companionList = {}, {}
        work.retryAt = now + math.max(.3, tonumber(Mail.GetSetting("OpenSpeed")) or .5)
    end
    local callLimit = next(work.companion) and 47 or 48 -- a matching slot can also read its invoice
    while scan == work and calls < callLimit and Clock() - started < 1 do
        if work.loaded == nil then
            local loaded, total = GetInboxNumItems(); calls = calls + 1
            if type(loaded) ~= "number" or loaded < 0 or type(total) == "number" and total < loaded then Retry(); return end
            work.loaded, work.authoritative = loaded, total == loaded
        elseif work.index > work.loaded then
            -- Publish/start on the next frame; queue preparation must not add a
            -- second full header traversal after this frame's scan budget.
            work.done = true
            return
        elseif not work.slot then
            local _, _, sender, subject, money, cod, _, attachments, _, _, _, _, gm = GetInboxHeaderInfo(work.index); calls = calls + 1
            if not sender and not subject then Retry(); return end
            work.attachments, work.known = tonumber(attachments) or 0, 0
            work.ownerRow, work.companionRow, work.buyer, work.header = nil, nil, nil, nil
            local codAmount = work.attachments > 0 and not gm and (tonumber(cod) or 0)
            work.eligible = codAmount == 0
            work.sender, work.subject, work.money = sender, subject, money
            if work.attachments == 0 then work.index = work.index + 1 else work.slot = 1 end
        else
            local name, id, _, quantity, _, _, currency = GetInboxItem(work.index, work.slot); calls = calls + 1
            if currency then work.known = work.known + 1
            elseif name and type(id) == "number" and id > 0 and type(quantity) == "number" and quantity > 0 then
                work.known = work.known + 1
                work.counts[id] = (work.counts[id] or 0) + quantity
                calls = MatchAttachment(work, id, quantity, calls)
            end
            work.slot = work.slot + 1
            if work.slot > work.slots then
                if work.known ~= work.attachments then Retry(); return end
                if work.ownerRow then work.ownerList[#work.ownerList + 1] = work.ownerRow end
                if work.companionRow then work.companionList[#work.companionList + 1] = work.companionRow end
                work.index, work.slot = work.index + 1, nil
            end
        end
    end
end
local function Snapshot()
    if not opened or not inboxUpdated or Combat() or not Enabled() then StopScan(); return false end
    local owner, companion = Items(false), Items(true)
    if not next(owner) and not next(companion) then StopScan(); return false end
    local existing = complete or scan
    if existing and (HasNewTargets(owner, existing.owner) or HasNewTargets(companion, existing.companion)) then Invalidate() end
    if complete then return true end
    if failedGeneration == generation then return end
    if not (GetInboxNumItems and GetInboxHeaderInfo and GetInboxItem) then return false end
    if not scan then
        scan = { index = 1, counts = {}, owner = owner, companion = companion, ownerList = {}, companionList = {},
            deadline = (GetTime and GetTime() or 0) + 8,
            slots = math.max(tonumber(ATTACHMENTS_MAX_RECEIVE) or 0, tonumber(ATTACHMENTS_MAX) or 0, 12) }
        frame:SetScript("OnUpdate", Slice)
    end
    return false
end

local function Mode(companion) return companion and "logistics" or "owner" end
local function Matches(row, wanted)
    for id, quantity in pairs(row.items) do
        if quantity <= (wanted[id] or 0) then return true end
    end
    return false
end
local function Rows(companion) return companion and complete.companionList or complete.ownerList end

Start = function(companion, automatic)
    if not opened or not inboxUpdated or Combat() or not Enabled() or not Mail.ProcessRestockItems then return false end
    if active or NativeOpenAll() or automatic and not FreeSpace() or Mail.GetJobGroup and Mail.GetJobGroup() then return false end
    local f = Followup()
    if not f or not f.GetMailItems or (companion and not f.LogisticsMailTaken)
        or (not companion and not f.MailTakeStarted) then return false end
    if not Snapshot() or Busy() then return false end
    local wanted, list, began = Items(companion), {}, generation
    for _, row in ipairs(Rows(companion)) do
        if Matches(row, wanted) then list[#list + 1] = row end
    end
    if #list == 0 then return false end
    local mode = Mode(companion)
    local explicit = requested == mode
    if explicit then requested = nil end
    local session = { automatic = automatic }
    active = session
    local companionBefore
    local function NoteCompanionTake(id, quantity)
        local remaining = Items(true)[id] or 0
        local credited = math.max(0, (companionBefore or remaining) - remaining)
        -- A bag observation can credit this take before the inbox confirms it.
        if credited < quantity then f.LogisticsMailTaken(id, quantity - credited) end
    end
    local started = Mail.ProcessRestockItems(wanted, {
        list = list,
        GetItems = function() return Items(companion) end,
        OnTake = function(id, quantity, index)
            local accepted
            if companion then
                companionBefore = Items(true)[id] or 0
                accepted = quantity <= companionBefore and BuyerMail(index)
            else accepted = f.MailTakeStarted(id, quantity) end
            session.issued = accepted ~= false
            if companion or accepted ~= false then Invalidate() end
            return accepted
        end,
        OnTaken = function(id, quantity)
            if companion then NoteCompanionTake(id, quantity)
            elseif f.MailTakeFinished then f.MailTakeFinished(id, quantity) end
        end,
        -- An inbox index may shift after a take. Retain the issued allowance
        -- until the queue sees the carried receipt, without claiming delivery.
        OnUnconfirmed = companion and NoteCompanionTake or nil,
        OnSnapshot = Snapshot,
        OnStop = function(message)
            active = nil
            local finished = message and message:find("Finished", 1, true)
            if not finished and not suspending then autoStopped = true end
            if not companion and f.MailTakeCancelled then f.MailTakeCancelled() end
            local continued = finished and not message:find("remain", 1, true)
                and generation ~= began
            if explicit and continued and not requested and next(Items(companion)) then requested = mode end
            Update(continued)
        end,
    })
    if not started and active == session then
        active = nil
        if explicit then requested = mode end
    end
    return started and (active == session or session.issued) or false
end
-- The HUD can be pressed while the bounded native inbox snapshot is loading.
-- Retain that one request and let this existing worker start when it is ready.
function Mail.TakeRestockItems(companion)
    if not opened or not inboxUpdated or Combat() or not Enabled() then return false end
    local mode = Mode(companion)
    requested = mode
    local started = Start(companion == true)
    return started or requested == mode
end
function Mail.IsRestockContextOpen()
    return opened and inboxUpdated and not Combat() and Enabled() or false
end
function Mail.CanTakeRestockItems(companion)
    if not Mail.IsRestockContextOpen() or Busy() or requested or (Mail.GetJobGroup and Mail.GetJobGroup()) then return false end
    if not Snapshot() or NativeOpenAll() or not FreeSpace() then return false end
    local wanted = Items(companion)
    for _, row in ipairs(Rows(companion)) do
        if Matches(row, wanted) then return true end
    end
    return false
end

Update = function(automatic)
    if updating then return end
    updating = true
    if requested and not next(Items(requested == "logistics")) then requested = nil end
    if opened and Snapshot() then
        local started = requested and Start(requested == "logistics")
        if not started and automatic and not autoStopped and Automatic() then
            if not Start(false, true) then Start(true, true) end
        end
    end
    updating = nil
    local f = Followup()
    if f and f.Refresh then f.Refresh() end
end

function Mail.NotifyRestockTargetsChanged()
    if opened then Update(true) end
end

local previous = Mail.OnJobStateChanged
Mail.OnJobStateChanged = function(running, group, message)
    if previous then previous(running, group, message) end
    Update(not running and group ~= "Restock")
end
if Mail.OnSettingsChanged then Mail.OnSettingsChanged(function(group, key)
    if group ~= "Restock" and group ~= "Modules" then return end
    if not Enabled() then
        requested = nil
        if Mail.StopRestockItems then Mail.StopRestockItems() end
    elseif not Automatic() and active and active.automatic then
        if Mail.StopRestockItems then Mail.StopRestockItems() end
    end
    if group == "Restock" and key == "AutoCollect" and Automatic() then autoStopped = false end
    Update(true)
end) end

frame = CreateFrame("Frame")
for _, event in ipairs({ "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "PLAYER_LEAVING_WORLD",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" }) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent", function(_, event, interaction)
    local mailType = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
    if event == "MAIL_SHOW" or mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and interaction == mailType then
        if not opened then inboxUpdated, autoStopped = false, false; Invalidate() end
        opened = true
        Update(true)
    elseif event == "MAIL_INBOX_UPDATE" then
        if not opened then return end
        inboxUpdated = true
        Invalidate()
        Update(true)
    elseif event == "MAIL_CLOSED" or event == "PLAYER_LEAVING_WORLD"
        or mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and interaction == mailType then
        opened, inboxUpdated = false, false
        requested = nil
        Invalidate()
        suspending = true
        if Mail.StopRestockItems then Mail.StopRestockItems() end
        suspending = nil
        Update(false)
    elseif event == "PLAYER_REGEN_DISABLED" then
        requested = nil
        Invalidate()
        Update(false)
    elseif event == "PLAYER_REGEN_ENABLED" then
        Update(true)
        if Mail.NotifyRestockSnapshotReady then Mail.NotifyRestockSnapshotReady() end
    end
end)
