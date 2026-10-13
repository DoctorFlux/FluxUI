--[[
    Inventory/FluxInv/FluxInv_Events.lua

    Own event frame + debounced fan-out for FluxInv.
    Does not share FluxInventory's event frame.
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Events = Inv.Events or {}
local Events = Inv.Events

local Compat = function()
    return Inv.Compat
end

local TIER_RANK = { instant = 1, light = 2, scan = 3, heavy = 4 }
local listeners = {} -- key -> { fn, tier, regions, deferHeavy, sync }
local pendingTier = 0
local pendingRegions = {}
local debouncePending = false
local DEBOUNCE = 0.05
local DEBOUNCE_BANK_OPEN = 0.12
local DEBOUNCE_STORM = 0.18
local initialized = false

-- Coalesce GET_ITEM_INFO_RECEIVED / ITEM_DATA_LOAD_RESULT into one light pulse.
local itemDataPulsePending = false
local ITEM_DATA_DEBOUNCE = 0.15

-- Track last Bags/Bank/Equip generations so Index.Bump only fires on real snapshot changes.
local lastBumpBagsGen = -1
local lastBumpBankGen = -1
local lastBumpEquipGen = -1

-- Frame-budgeted heavy listener queue (coalesce by key).
local heavyQueue = {} -- key -> { fn, ctx, key }
local heavyQueueOrder = {}
local heavyQueueArmed = false
local HEAVY_MAX_PER_FRAME = 2
local HEAVY_BUDGET_MS = 1.5
local heavyQueueFrame = nil

-- Listeners that must run in the same frame as snapshot refresh (counts / overlays).
local SYNC_KEYS = {
    EngineBagRefresh = true,
    FluxJunkOverlay = true,
    FluxJunkSlotCount = true,
    NCTeleportPortal = true,
    FluxBagMicroButton = true,
    FluxItemCurrencyTracking = true,
}

local function mergeRegion(name)
    pendingRegions[name] = true
end

local function raiseTier(tier)
    local rank = TIER_RANK[tier] or TIER_RANK.scan
    if rank > pendingTier then
        pendingTier = rank
    end
end

local function tierNameFromRank(rank)
    if rank >= 4 then
        return "heavy"
    end
    if rank >= 3 then
        return "scan"
    end
    if rank >= 2 then
        return "light"
    end
    return "instant"
end

local function regionMatches(wanted, pending)
    if not wanted or next(wanted) == nil then
        return true
    end
    for name in pairs(wanted) do
        if pending[name] then
            return true
        end
    end
    return false
end

local function snapshotGens()
    local bagsGen = Inv.Bags and Inv.Bags.GetGeneration and Inv.Bags.GetGeneration() or 0
    local bankGen = Inv.Bank and Inv.Bank.GetGeneration and Inv.Bank.GetGeneration() or 0
    local equipGen = Inv.Equip and Inv.Equip.GetGeneration and Inv.Equip.GetGeneration() or 0
    return bagsGen, bankGen, equipGen
end

local function debugEnabled()
    local D = _G.FluxInvDebug
    return D and D.IsEnabled and D.IsEnabled()
end

local function timedCall(fn)
    local D = _G.FluxInvDebug
    if not D or not D.ProfileStart or not D.ProfileStop then
        fn()
        return 0
    end
    D.ProfileStart()
    fn()
    return D.ProfileStop() or 0
end

local function isSyncListener(entry)
    if entry.sync then
        return true
    end
    if entry.deferHeavy then
        return false
    end
    local key = entry.key
    if key and SYNC_KEYS[key] then
        return true
    end
    -- Instant-tier listeners are count/cheap by contract.
    if entry.tier == "instant" then
        return true
    end
    return false
end

local function ensureHeavyQueueFrame()
    if heavyQueueFrame then
        return heavyQueueFrame
    end
    heavyQueueFrame = CreateFrame("Frame", "FluxInvHeavyListenerQueue")
    return heavyQueueFrame
end

local function processHeavyQueue(self, elapsed)
    local dbg = debugEnabled()
    local Dbg = dbg and _G.FluxInvDebug or nil
    local processed = 0
    local spent = 0
    while processed < HEAVY_MAX_PER_FRAME and #heavyQueueOrder > 0 do
        local key = table.remove(heavyQueueOrder, 1)
        local job = heavyQueue[key]
        heavyQueue[key] = nil
        if job and job.fn then
            if dbg and Dbg then
                local ms = timedCall(function()
                    pcall(job.fn, job.ctx)
                end)
                spent = spent + ms
                if Dbg.OnListener then
                    Dbg.OnListener((job.key or key) .. ":deferred", ms)
                end
            else
                pcall(job.fn, job.ctx)
            end
            processed = processed + 1
            if spent >= HEAVY_BUDGET_MS then
                break
            end
        end
    end
    if #heavyQueueOrder == 0 then
        heavyQueueArmed = false
        self:SetScript("OnUpdate", nil)
    end
end

local function enqueueHeavy(key, entry, ctx)
    local k = entry.key or key
    if not heavyQueue[k] then
        heavyQueueOrder[#heavyQueueOrder + 1] = k
    end
    heavyQueue[k] = { fn = entry.fn, ctx = ctx, key = k }
    if not heavyQueueArmed then
        heavyQueueArmed = true
        local f = ensureHeavyQueueFrame()
        f:SetScript("OnUpdate", processHeavyQueue)
    end
end

local function mergeItemIDSets(into, src)
    if not src then
        return into
    end
    into = into or {}
    for id in pairs(src) do
        into[id] = true
    end
    return into
end

--- Merge Bags + Bank change metadata so listeners can gate on equippable IDs
--- for bag↔bank transfers (either side may own the added/removed set).
local function resolveChangeKind(regions, bagsGenChanged, bankGenChanged)
    if not bagsGenChanged and not bankGenChanged then
        return "none", nil, nil
    end

    local added, removed = nil, nil
    local hasIdentity = false
    local hasCountOnly = false
    local sawMeta = false

    local function ingest(kind, add, rem)
        if not kind then
            return
        end
        sawMeta = true
        if kind == "identityChanged" then
            hasIdentity = true
        elseif kind == "countOnly" then
            hasCountOnly = true
        end
        added = mergeItemIDSets(added, add)
        removed = mergeItemIDSets(removed, rem)
    end

    if bagsGenChanged and Inv.Bags and Inv.Bags.GetLastChangeKind then
        ingest(
            Inv.Bags.GetLastChangeKind(),
            Inv.Bags.GetLastAddedItemIDs and Inv.Bags.GetLastAddedItemIDs(),
            Inv.Bags.GetLastRemovedItemIDs and Inv.Bags.GetLastRemovedItemIDs()
        )
    end

    if bankGenChanged then
        if Inv.Bank and Inv.Bank.GetLastChangeKind then
            ingest(
                Inv.Bank.GetLastChangeKind(),
                Inv.Bank.GetLastAddedItemIDs and Inv.Bank.GetLastAddedItemIDs(),
                Inv.Bank.GetLastRemovedItemIDs and Inv.Bank.GetLastRemovedItemIDs()
            )
        else
            -- No bank meta: treat as identity with unknown IDs.
            return "identityChanged", added, removed
        end
    end

    if hasIdentity then
        return "identityChanged", added, removed
    end
    if hasCountOnly and sawMeta then
        return "countOnly", nil, nil
    end
    return "unknown", added, removed
end

local function dispatch()
    debouncePending = false
    local tier = tierNameFromRank(pendingTier)
    local regions = pendingRegions
    pendingTier = 0
    pendingRegions = {}

    local dbg = debugEnabled()
    local Dbg = dbg and _G.FluxInvDebug or nil
    local bankOpen = Inv.Bank and Inv.Bank.IsOpen and Inv.Bank.IsOpen()
    local bagsMs, bankMs, equipMs, otherMs = 0, 0, 0, 0
    if Dbg and Dbg.OnDispatchStart then
        Dbg.OnDispatchStart(tier, regions, bankOpen)
    end

    local bagsGen0, bankGen0, equipGen0 = snapshotGens()

    -- Refresh snapshots before fan-out; capture dirty bags for targeted overlay paints.
    local dirtyBags = {}
    if regions.bags and Inv.Bags then
        if dbg then
            bagsMs = bagsMs + timedCall(function()
                Inv.Bags.Refresh()
            end)
        else
            Inv.Bags.Refresh()
        end
        if Inv.Bags.GetLastRefreshedDirtyBags then
            for bag in pairs(Inv.Bags.GetLastRefreshedDirtyBags()) do
                dirtyBags[bag] = true
            end
        end
    end
    if (regions.bank or regions.warband) and Inv.Bank then
        if Inv.Bank.IsOpen() then
            if dbg then
                bankMs = bankMs + timedCall(function()
                    Inv.Bank.Refresh()
                end)
            else
                Inv.Bank.Refresh()
            end
            if Inv.Bank.GetLastRefreshedDirtyBags then
                for bag in pairs(Inv.Bank.GetLastRefreshedDirtyBags()) do
                    dirtyBags[bag] = true
                end
            end
        end
    end
    if regions.equip and Inv.Equip then
        if dbg then
            equipMs = equipMs + timedCall(function()
                Inv.Equip.Refresh()
            end)
        else
            Inv.Equip.Refresh()
        end
    end
    if regions.bags or regions.bank or regions.warband then
        if Inv.Spells and Inv.Spells.OnVisibleItemsChanged then
            pcall(Inv.Spells.OnVisibleItemsChanged)
        end
    end
    if regions.spells and Inv.Spells and Inv.Spells.Refresh then
        if dbg then
            otherMs = otherMs + timedCall(function()
                Inv.Spells.Refresh()
            end)
        else
            Inv.Spells.Refresh()
        end
    end
    if regions.professions and Inv.Professions and Inv.Professions.OnEventPulse then
        if dbg then
            otherMs = otherMs + timedCall(function()
                Inv.Professions.OnEventPulse()
            end)
        else
            Inv.Professions.OnEventPulse()
        end
    end

    if Dbg and Dbg.OnRefreshMs then
        Dbg.OnRefreshMs(bagsMs, bankMs, equipMs, otherMs)
    end

    local bagsGen1, bankGen1, equipGen1 = snapshotGens()
    local bagsGenChanged = bagsGen1 ~= bagsGen0
    local bankGenChanged = bankGen1 ~= bankGen0
    local changed = bagsGenChanged or bankGenChanged or (equipGen1 ~= equipGen0)
        or (bagsGen1 ~= lastBumpBagsGen) or (bankGen1 ~= lastBumpBankGen) or (equipGen1 ~= lastBumpEquipGen)
    -- Always bump on spells/professions pulses (no gen tracker); otherwise only when bag/bank/equip gen moved.
    if regions.spells or regions.professions or changed then
        if Inv.Index then
            Inv.Index.Bump()
        end
        lastBumpBagsGen = bagsGen1
        lastBumpBankGen = bankGen1
        lastBumpEquipGen = equipGen1
    elseif not regions.bags and not regions.bank and not regions.warband and not regions.equip then
        if Inv.Index then
            Inv.Index.Bump()
        end
    end

    -- Real bag/bank content changes must wake scan listeners (Best / ExtraButtons / craft).
    -- Carried BAG_UPDATE starts as instant; without promotion those listeners never rebind.
    local tierRank = TIER_RANK[tier] or 1
    if (bagsGenChanged or bankGenChanged) and tierRank < TIER_RANK.scan then
        tier = "scan"
        tierRank = TIER_RANK.scan
    end

    local changeKind, addedItemIDs, removedItemIDs = resolveChangeKind(regions, bagsGenChanged, bankGenChanged)

    local ctx = {
        tier = tier,
        regions = regions,
        time = GetTime and GetTime() or 0,
        dirtyBags = next(dirtyBags) and dirtyBags or nil,
        bagsGenChanged = bagsGenChanged,
        bankGenChanged = bankGenChanged,
        changeKind = changeKind,
        addedItemIDs = addedItemIDs,
        removedItemIDs = removedItemIDs,
    }

    -- Sync path: overlays + count text. deferHeavy listeners: budgeted queue during storm/identity.
    local stormActive = Inv.IsBagStorm and Inv.IsBagStorm()
    local deferHeavyNow = stormActive
        or changeKind == "identityChanged"
        or (Inv.ShouldDeferHeavyWork and Inv.ShouldDeferHeavyWork())

    local listenersMs = 0
    for key, entry in pairs(listeners) do
        local wantRank = TIER_RANK[entry.tier] or TIER_RANK.scan
        if tierRank >= wantRank and regionMatches(entry.regions, regions) then
            local defer = (not isSyncListener(entry)) and entry.deferHeavy and deferHeavyNow
            if defer then
                enqueueHeavy(key, entry, ctx)
            elseif dbg and Dbg then
                local ms = timedCall(function()
                    pcall(entry.fn, ctx)
                end)
                listenersMs = listenersMs + ms
                if Dbg.OnListener then
                    Dbg.OnListener(entry.key or key, ms)
                end
            else
                pcall(entry.fn, ctx)
            end
        end
    end

    -- Identity changes: flush ExtraButton identity after heavy queue drains (or next frame).
    if changeKind == "identityChanged" and Inv.FlushExtraButtonIdentityRefresh then
        enqueueHeavy("__FlushExtraButtonIdentity", {
            key = "__FlushExtraButtonIdentity",
            fn = function()
                pcall(Inv.FlushExtraButtonIdentityRefresh)
            end,
            deferHeavy = true,
        }, ctx)
    end

    if Dbg and Dbg.OnDispatchEnd then
        Dbg.OnDispatchEnd({
            tier = tier,
            regions = regions,
            bankOpen = bankOpen,
            bagsMs = bagsMs,
            bankMs = bankMs,
            equipMs = equipMs,
            otherMs = otherMs,
            listenersMs = listenersMs,
            totalMs = bagsMs + bankMs + equipMs + otherMs + listenersMs,
            changeKind = changeKind,
            storm = stormActive,
        })
    end
end

local function currentDebounce()
    if Inv.IsBagStorm and Inv.IsBagStorm() then
        return DEBOUNCE_STORM
    end
    if Inv.Bank and Inv.Bank.IsOpen and Inv.Bank.IsOpen() then
        return DEBOUNCE_BANK_OPEN
    end
    return DEBOUNCE
end

local function scheduleDispatch()
    if debouncePending then
        return
    end
    debouncePending = true
    Compat().After(currentDebounce(), dispatch)
end

function Events.Pulse(tier, regions)
    raiseTier(tier or "scan")
    if type(regions) == "table" then
        for _, name in ipairs(regions) do
            mergeRegion(name)
        end
        for name, v in pairs(regions) do
            if type(name) == "string" and v == true then
                mergeRegion(name)
            end
        end
    elseif type(regions) == "string" then
        mergeRegion(regions)
    else
        mergeRegion("bags")
    end
    scheduleDispatch()
end

function Events.ForceDispatch()
    debouncePending = false
    dispatch()
end

function Events.RegisterListener(key, fn, opts)
    if type(key) ~= "string" or type(fn) ~= "function" then
        return
    end
    opts = opts or {}
    local regions
    if type(opts.regions) == "table" then
        regions = {}
        for _, name in ipairs(opts.regions) do
            regions[name] = true
        end
        for name, v in pairs(opts.regions) do
            if type(name) == "string" and v == true then
                regions[name] = true
            end
        end
    end
    listeners[key] = {
        key = key,
        fn = fn,
        tier = opts.tier or "scan",
        regions = regions,
        deferHeavy = opts.deferHeavy and true or false,
        sync = opts.sync and true or false,
    }
end

function Events.UnregisterListener(key)
    listeners[key] = nil
end

--- Read-only: true while a debounced dispatch is scheduled.
function Events.IsDebouncePending()
    return debouncePending
end

--- Snapshot of registered listeners for /fluxinvdebug listeners.
function Events.GetListeners()
    local out = {}
    for key, entry in pairs(listeners) do
        out[#out + 1] = {
            key = entry.key or key,
            tier = entry.tier,
            regions = entry.regions,
            deferHeavy = entry.deferHeavy,
            sync = entry.sync,
        }
    end
    return out
end

local function scheduleItemDataPulse()
    if itemDataPulsePending then
        return
    end
    itemDataPulsePending = true
    Compat().After(ITEM_DATA_DEBOUNCE, function()
        itemDataPulsePending = false
        -- Soft refresh: reclassify/listeners may need bags after item data lands.
        Events.Pulse("light", { "bags", "equip" })
    end)
end

local function bankIsOpen()
    return Inv.Bank and Inv.Bank.IsOpen and Inv.Bank.IsOpen()
end

local function notifyStorm()
    if Inv.NotifyBagStorm then
        Inv.NotifyBagStorm(0.25)
    end
end

-- Era/Anniversary: a drop is several BAG_UPDATEs. Mark dirty and wait for
-- BAG_UPDATE_DELAYED so instant listeners and the bag storm do not run per event.
local classicDropRegions

local function isEraOrAnniversary()
    local client = _G.Flux and _G.Flux.Client
    if client and (client.isEra or client.isAnniversary) then
        return true
    end
    local project = _G.WOW_PROJECT_ID
    return project == _G.WOW_PROJECT_CLASSIC or project == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
end

local function noteClassicDrop(region)
    classicDropRegions = classicDropRegions or {}
    classicDropRegions[region] = true
end

local function markBags(bagID)
    if Inv.Bags and Inv.Bags.MarkDirty then
        Inv.Bags.MarkDirty(bagID)
    end
end

local function markBank(bagID)
    if Inv.Bank and Inv.Bank.MarkDirty then
        Inv.Bank.MarkDirty(bagID)
    end
end

local function onBagUpdate(bagID)
    bagID = tonumber(bagID)
    local containers = Inv.Containers
    local settle = isEraOrAnniversary()
    if not containers then
        if settle then
            markBags()
            noteClassicDrop("bags")
            return
        end
        notifyStorm()
        Events.Pulse("scan", { "bags" })
        return
    end
    if bagID == nil then
        if settle then
            markBags()
            noteClassicDrop("bags")
            if bankIsOpen() then
                markBank()
                noteClassicDrop("bank")
                noteClassicDrop("warband")
            end
            return
        end
        notifyStorm()
        markBags()
        if bankIsOpen() then
            markBank()
            Events.Pulse("scan", { "bags", "bank", "warband" })
        else
            Events.Pulse("scan", { "bags" })
        end
        return
    end
    if containers.IsCarriedBag(bagID) then
        markBags(bagID)
        if settle then
            noteClassicDrop("bags")
            return
        end
        notifyStorm()
        Events.Pulse("instant", { "bags" })
    elseif containers.IsWarbandBankContainer(bagID) then
        if not bankIsOpen() then
            return
        end
        markBank(bagID)
        if settle then
            noteClassicDrop("warband")
            return
        end
        Events.Pulse("scan", { "warband" })
    elseif containers.IsBankContainer(bagID) then
        if not bankIsOpen() then
            return
        end
        markBank(bagID)
        if settle then
            noteClassicDrop("bank")
            return
        end
        Events.Pulse("scan", { "bank" })
    else
        -- Unknown bag: dirty bags; only touch bank when open
        notifyStorm()
        markBags(bagID)
        if bankIsOpen() then
            markBank(bagID)
            Events.Pulse("scan", { "bags", "bank" })
        else
            Events.Pulse("scan", { "bags" })
        end
    end
end

local function pulseClassicDrop()
    local pending = classicDropRegions
    classicDropRegions = nil
    if not pending then
        return
    end
    local list = {}
    for name in pairs(pending) do
        list[#list + 1] = name
    end
    if #list > 0 then
        Events.Pulse("light", list)
    end
end

local sessionSawInitialPew = false

local function IsLoginOrReloadPew(event, arg1, arg2)
    if event == "PLAYER_LOGIN" then
        return true
    end
    -- Modern clients: PEW(isInitialLogin, isReloadingUi)
    if arg1 == true or arg2 == true then
        return true
    end
    -- Classic / missing args: first PEW of the session is login; later = zone transfer.
    if not sessionSawInitialPew then
        return true
    end
    return false
end

local function ArmLoadHold()
    if Inv.Bags and Inv.Bags.MarkUnreliable then
        Inv.Bags.MarkUnreliable("zone")
    end
    local Best = rawget(_G, "FluxConsumableBest")
    if Best and Best.BeginLoadHold then
        Best.BeginLoadHold()
    elseif Best and Best.ArmPortalSoftHold then
        Best.ArmPortalSoftHold()
    end
end

local function onEvent(_, event, arg1, arg2)
    if event == "PLAYER_LEAVING_WORLD" or event == "LOADING_SCREEN_ENABLED" then
        ArmLoadHold()
        return
    end
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        local isLoginPath = IsLoginOrReloadPew(event, arg1, arg2)
        if event == "PLAYER_ENTERING_WORLD" then
            sessionSawInitialPew = true
        end

        if isLoginPath then
            if Inv.Bags then
                Inv.Bags.Invalidate()
            end
            if Inv.Equip then
                Inv.Equip.Invalidate()
            end
            if Inv.Bank then
                Inv.Bank.Invalidate()
            end
            Events.Pulse("heavy", { "bags", "bank", "warband", "equip", "spells", "professions" })
            if Inv.Professions and Inv.Professions.ScheduleLoginScan then
                Inv.Professions.ScheduleLoginScan()
            end
            if Inv.Spells and Inv.Spells.ScheduleWarm then
                Inv.Spells.ScheduleWarm()
            end
        else
            -- Zone transfer / teleport: soft bags+equip only — no bank wipe,
            -- no profession login scan, no spell warm.
            if Inv.Bags and Inv.Bags.MarkUnreliable then
                Inv.Bags.MarkUnreliable("zone")
            end
            if Inv.Bags and Inv.Bags.MarkDirty then
                Inv.Bags.MarkDirty()
            end
            if Inv.Equip and Inv.Equip.MarkDirty then
                Inv.Equip.MarkDirty()
            end
            Events.Pulse("scan", { "bags", "equip" })
        end
    elseif event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
        if debugEnabled() then
            local Dbg = _G.FluxInvDebug
            if Dbg and Dbg.OnBagUpdateEvent then
                Dbg.OnBagUpdateEvent(event == "BAG_UPDATE_DELAYED")
            end
        end
        if event == "BAG_UPDATE_DELAYED" and isEraOrAnniversary() then
            -- One light pulse after the drop. Heavy listeners stay on their debounce.
            pulseClassicDrop()
        else
            onBagUpdate(arg1)
        end
    elseif event == "ITEM_LOCK_CHANGED" then
        -- Lock-only: do not fan-out to all listeners unless a bag/slot was marked dirty.
        -- arg1 = bag (or inventory slot on some clients), arg2 = slot when bag-based.
        local bagID = tonumber(arg1)
        local slot = tonumber(arg2)
        if bagID and slot and Inv.Containers then
            if Inv.Containers.IsCarriedBag(bagID) then
                -- Content unchanged on lock alone; skip Pulse (BAG_UPDATE handles real moves).
                return
            end
            if Inv.Bank and (Inv.Containers.IsBankContainer(bagID) or Inv.Containers.IsWarbandBankContainer(bagID)) then
                return
            end
        end
        -- Ambiguous lock (inventory slot / no slot): ignore; equipment/bag events cover real changes.
        return
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then
        if event == "UNIT_INVENTORY_CHANGED" and arg1 and arg1 ~= "player" then
            return
        end
        if Inv.Equip then
            Inv.Equip.MarkDirty()
        end
        Events.Pulse("scan", { "equip" })
    elseif event == "BANKFRAME_OPENED" then
        if _G.FluxInvDebug and _G.FluxInvDebug.OnBankOpened then
            _G.FluxInvDebug.OnBankOpened()
        end
        if Inv.Bank then
            Inv.Bank.SetOpen(true)
            Inv.Bank.Invalidate()
        end
        if Inv.Containers then
            Inv.Containers.Invalidate()
        end
        Events.Pulse("heavy", { "bank", "warband" })
    elseif event == "BANKFRAME_CLOSED" then
        if _G.FluxInvDebug and _G.FluxInvDebug.OnBankClosed then
            _G.FluxInvDebug.OnBankClosed()
        end
        if Inv.Bank then
            Inv.Bank.SetOpen(false)
        end
        -- No bank/warband Pulse: RegisterBankClose hooks handle teardown.
        -- Fan-out here re-woke Best/Tiers/idle CanRun after the bank was gone.
    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        -- Slot content change: dirty specific bag when possible, not full Invalidate.
        -- The classic arg is a slot index and overlaps bank-bag ids, so Era and
        -- Anniversary only mark the main bank and wait for the settled light pulse.
        local bagOrSlot = tonumber(arg1)
        if Inv.Bank and Inv.Bank.IsOpen and Inv.Bank.IsOpen() then
            if isEraOrAnniversary() then
                local main = Inv.Containers and Inv.Containers.GetBankMainContainerID and Inv.Containers.GetBankMainContainerID()
                if main and Inv.Bank.MarkDirty then
                    Inv.Bank.MarkDirty(main)
                elseif Inv.Bank.MarkDirty then
                    Inv.Bank.MarkDirty()
                end
                noteClassicDrop("bank")
                return
            end
            if bagOrSlot and Inv.Containers and Inv.Containers.IsBankContainer and Inv.Containers.IsBankContainer(bagOrSlot) then
                Inv.Bank.MarkDirty(bagOrSlot)
            elseif Inv.Bank.MarkDirty then
                Inv.Bank.MarkDirty()
            end
            Events.Pulse("scan", { "bank", "warband" })
        end
    elseif event == "PLAYERBANKBAGSLOTS_CHANGED"
        or event == "BANK_BAG_SLOT_FLAGS_UPDATED" or event == "BANK_TABS_CHANGED"
        or event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED" or event == "BANK_TAB_SETTINGS_UPDATED" then
        -- Structure / tab changes: only while bank is open.
        if not (Inv.Bank and Inv.Bank.IsOpen and Inv.Bank.IsOpen()) then
            return
        end
        if Inv.Containers then
            Inv.Containers.Invalidate()
        end
        if Inv.Bank then
            Inv.Bank.Invalidate()
        end
        Events.Pulse("heavy", { "bank", "warband" })
    elseif event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
        local itemID = tonumber(arg1)
        local success = arg2
        -- ITEM_DATA_LOAD_RESULT: arg2 is success. GET_ITEM_INFO_RECEIVED: arg2 is success.
        local care = false
        if itemID then
            local Best = _G.FluxConsumableBest
            if Best and Best._pendingLoad and Best._pendingLoad[itemID] then
                care = true
            end
            local IC = _G.FluxItemClass
            if IC and IC.OnItemDataLoaded then
                pcall(IC.OnItemDataLoaded, itemID, success)
            end
            if Best and Best.Scan and Best.Scan.OnItemDataLoaded then
                pcall(Best.Scan.OnItemDataLoaded, itemID, success)
            end
            -- Classic: item cache fill may unlock spell-reagent name → ID.
            if success ~= false and Inv.Spells and Inv.Spells.OnVisibleItemsChanged then
                pcall(Inv.Spells.OnVisibleItemsChanged)
            end
        end
        -- Do not fan out bags/equip to every listener on global item-data spam.
        -- Best already RequestRecomputes when a pending load resolves.
        if care then
            scheduleItemDataPulse()
        end
    elseif event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB"
        or event == "LEARNED_SPELL_IN_SKILL_LINE" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        if Inv.Spells and Inv.Spells.Invalidate then
            Inv.Spells.Invalidate()
        end
        Events.Pulse("scan", { "spells" })
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE"
        or event == "TRADE_SKILL_LIST_UPDATE" or event == "NEW_RECIPE_LEARNED"
        or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then
        if Inv.Professions and Inv.Professions.OnProfessionEvent then
            Inv.Professions.OnProfessionEvent(event, arg1, arg2)
        end
        Events.Pulse("scan", { "professions" })
    elseif event == "TRADE_SKILL_CLOSE" then
        if Inv.Professions and Inv.Professions.OnProfessionClosed then
            Inv.Professions.OnProfessionClosed()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if Inv.Professions and Inv.Professions.AbortLoginScan then
            Inv.Professions.AbortLoginScan()
        end
    elseif event == "MERCHANT_SHOW" then
        if Inv.SetMerchantOpen then
            Inv.SetMerchantOpen(true)
        end
        -- Resolve spell-reagent names against merchant stock (Classic tooltips are name-only).
        if Inv.Spells and Inv.Spells.OnVisibleItemsChanged then
            pcall(Inv.Spells.OnVisibleItemsChanged)
        end
        -- No bags pulse: vendor session owns open work; pulsing here forced
        -- GearSetLock/junk/tiers rebuilds before automation even starts.
    elseif event == "MERCHANT_CLOSED" then
        if Inv.SetMerchantOpen then
            Inv.SetMerchantOpen(false)
        end
        -- No bags pulse on close (same reason as SHOW).
    end
end

function Events.Init()
    if initialized then
        return
    end
    initialized = true
    local frame = CreateFrame("Frame", "FluxInvEventFrame")
    frame:SetScript("OnEvent", onEvent)

    local list = {
        "PLAYER_LOGIN",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_LEAVING_WORLD",
        "LOADING_SCREEN_ENABLED",
        "BAG_UPDATE",
        "BAG_UPDATE_DELAYED",
        "ITEM_LOCK_CHANGED",
        "PLAYER_EQUIPMENT_CHANGED",
        "UNIT_INVENTORY_CHANGED",
        "BANKFRAME_OPENED",
        "BANKFRAME_CLOSED",
        "PLAYERBANKSLOTS_CHANGED",
        "PLAYERBANKBAGSLOTS_CHANGED",
        "BANK_BAG_SLOT_FLAGS_UPDATED",
        "BANK_TABS_CHANGED",
        "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED",
        "BANK_TAB_SETTINGS_UPDATED",
        "GET_ITEM_INFO_RECEIVED",
        "ITEM_DATA_LOAD_RESULT",
        "SPELLS_CHANGED",
        "LEARNED_SPELL_IN_TAB",
        "LEARNED_SPELL_IN_SKILL_LINE",
        "PLAYER_SPECIALIZATION_CHANGED",
        "TRADE_SKILL_SHOW",
        "TRADE_SKILL_CLOSE",
        "TRADE_SKILL_UPDATE",
        "TRADE_SKILL_LIST_UPDATE",
        "NEW_RECIPE_LEARNED",
        "TRADE_SKILL_DATA_SOURCE_CHANGED",
        "PLAYER_REGEN_DISABLED",
        "MERCHANT_SHOW",
        "MERCHANT_CLOSED",
    }
    local compat = Compat()
    for _, ev in ipairs(list) do
        compat.SafeRegisterEvent(frame, ev)
    end
    Events.frame = frame
end

_G.FluxInv = Inv
