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
local requested
local Update, Start

local function Followup()
    local a = _G.FluxAuctionRestock
    return a and a.Followup
end
local function Combat() return InCombatLockdown and InCombatLockdown() end
local function Enabled() return not Mail.IsEnabled or Mail.IsEnabled("Restock") end
local function Items()
    local f = Followup()
    return f and f.GetMailItems and f.GetMailItems() or {}
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
local function Clock() return debugprofilestop and debugprofilestop() or (GetTime and GetTime() * 1000 or 0) end
local function Slice()
    local work = scan
    if not work then return end
    if not opened or Combat() or not Enabled() or not next(Items()) then StopScan(); return end
    local now = GetTime and GetTime() or 0
    if now >= work.deadline then
        failedGeneration = generation; StopScan()
        if Mail.NotifyRestockSnapshotReady then Mail.NotifyRestockSnapshotReady() end
        return
    end
    if work.retryAt and now < work.retryAt then return end
    if Busy() then return end
    if work.done then
        complete = { generation = generation, counts = work.counts, list = work.list, authoritative = work.authoritative }
        local automatic = work.automatic
        StopScan()
        local f = Followup()
        if complete.authoritative and f and f.MailSnapshotComplete then f.MailSnapshotComplete(complete.counts) end
        Update(automatic)
        if Mail.NotifyRestockSnapshotReady then Mail.NotifyRestockSnapshotReady() end
        return
    end
    local calls, started = 0, Clock()
    local function Retry()
        work.index, work.slot, work.loaded, work.counts, work.list = 1, nil, nil, {}, {}
        work.targets = Items()
        work.retryAt = now + math.max(.3, tonumber(Mail.GetSetting("OpenSpeed")) or .5)
    end
    while scan == work and calls < 48 and Clock() - started < 1 do
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
            work.row = nil
            if work.attachments > 0 and not gm and (tonumber(cod) or 0) == 0 then
                work.row = { index = work.index, items = {}, header = {
                    sender = sender or "", subject = subject or "", money = tonumber(money) or 0,
                    cod = tonumber(cod) or 0, items = work.attachments, gm = gm == true,
                } }
            end
            if work.attachments == 0 then work.index = work.index + 1 else work.slot = 1 end
        else
            local name, id, _, quantity, _, _, currency = GetInboxItem(work.index, work.slot); calls = calls + 1
            if currency then work.known = work.known + 1
            elseif name and type(id) == "number" and id > 0 and type(quantity) == "number" and quantity > 0 then
                work.known = work.known + 1
                work.counts[id] = (work.counts[id] or 0) + quantity
                if work.row and quantity <= (work.targets[id] or 0) then
                    work.row.matches = true
                    work.row.items[id] = math.min(work.row.items[id] or quantity, quantity)
                end
            end
            work.slot = work.slot + 1
            if work.slot > work.slots then
                if work.known ~= work.attachments then Retry(); return end
                if work.row and work.row.matches then work.list[#work.list + 1] = work.row end
                work.index, work.slot = work.index + 1, nil
            end
        end
    end
end
local function Snapshot(automatic)
    if not opened or not inboxUpdated or Combat() or not Enabled() then StopScan(); return false end
    if not next(Items()) then StopScan(); return false end
    if complete and complete.generation == generation then return true end
    if failedGeneration == generation then return end
    if not (GetInboxNumItems and GetInboxHeaderInfo and GetInboxItem) then return false end
    if not scan then
        scan = { index = 1, counts = {}, list = {}, targets = Items(), deadline = (GetTime and GetTime() or 0) + 8,
            slots = math.max(tonumber(ATTACHMENTS_MAX_RECEIVE) or 0, tonumber(ATTACHMENTS_MAX) or 0, 12),
            automatic = automatic == true }
        frame:SetScript("OnUpdate", Slice)
    elseif automatic then scan.automatic = true end
    return false
end

Start = function()
    if not opened or not inboxUpdated or Combat() or not Enabled() or not Mail.ProcessRestockItems then return false end
    if Mail.GetJobGroup and Mail.GetJobGroup() then return false end
    local f = Followup()
    if not f or not f.GetMailItems or not f.MailTakeStarted then return false end
    if not Snapshot(false) or Busy() then return false end
    local wanted, list, began = Items(), {}, generation
    for _, row in ipairs(complete.list) do
        for id, quantity in pairs(row.items) do
            if quantity <= (wanted[id] or 0) then list[#list + 1] = row; break end
        end
    end
    return Mail.ProcessRestockItems(wanted, {
        list = list,
        GetItems = Items,
        OnTake = function(id, quantity)
            local accepted = f.MailTakeStarted(id, quantity)
            if accepted ~= false then Invalidate() end
            return accepted
        end,
        OnTaken = function(id, quantity) if f.MailTakeFinished then f.MailTakeFinished(id, quantity) end end,
        OnSnapshot = function() return Snapshot(false) end,
        OnStop = function(message)
            if f.MailTakeCancelled then f.MailTakeCancelled() end
            if not suspending and (not message or message:find("Stopped", 1, true)) then autoStopped = true end
            local continued = message and message:find("Finished", 1, true) and not message:find("remain", 1, true)
                and generation ~= began
            if not continued then requested = nil end
            if Update then Update(continued) end
        end,
    })
end
-- The HUD can be pressed while the bounded native inbox snapshot is loading.
-- Retain that one request and let this existing worker start when it is ready.
function Mail.TakeRestockItems()
    if not opened or not inboxUpdated or Combat() or not Enabled() then return false end
    requested = true
    Start()
    return requested == true
end
function Mail.IsRestockContextOpen()
    return opened and inboxUpdated and not Combat() and Enabled() or false
end
function Mail.CanTakeRestockItems()
    if not Mail.IsRestockContextOpen() or Busy() or requested or (Mail.GetJobGroup and Mail.GetJobGroup())
        or not complete or complete.generation ~= generation then return false end
    if OpenAllMail and OpenAllMail.timeUntilNextRetrieval ~= nil then return false end
    local free = Flux.Container and Flux.Container.GetTotalFreeBagSlots
    if free and free() <= (tonumber(Mail.GetSetting("OpenAll", "KeepFreeSpace")) or 1) then return false end
    local wanted = Items()
    for _, row in ipairs(complete.list) do
        for id, quantity in pairs(row.items) do if quantity <= (wanted[id] or 0) then return true end end
    end
    return false
end

Update = function(automatic)
    if updating then return end
    updating = true
    if opened then Snapshot(automatic) end
    if not next(Items()) then requested = nil end
    if requested and opened and Enabled() and not Combat() then Start() end
    if automatic and opened and Enabled() and not Combat() and not autoStopped
        and Mail.GetSetting("Restock", "AutoCollect") == true then Start() end
    updating = nil
    local f = Followup()
    if f and f.Refresh then f.Refresh() end
end

local previous = Mail.OnJobStateChanged
Mail.OnJobStateChanged = function(running, group, message)
    if previous then previous(running, group, message) end
    Update(not running and group ~= "Restock")
end
if Mail.OnSettingsChanged then Mail.OnSettingsChanged(function(group, key)
    if group ~= "Restock" and group ~= "Modules" then return end
    if not Enabled() or group == "Restock" and key == "AutoCollect" and not Mail.GetSetting("Restock", "AutoCollect") then
        requested = nil
        if Mail.StopRestockItems then Mail.StopRestockItems() end
    end
    local automatic = group == "Restock" and key == "AutoCollect" and Mail.GetSetting("Restock", "AutoCollect") == true
    if automatic then autoStopped = false end
    Update(automatic)
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
        suspending = true
        if Mail.StopRestockItems then Mail.StopRestockItems() end
        suspending = nil
        Update(false)
    elseif event == "PLAYER_REGEN_ENABLED" then Update(true) end
end)
