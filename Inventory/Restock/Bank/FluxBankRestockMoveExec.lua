--[[
    Restock/Bank/FluxBankRestockMoveExec.lua

    Bank restock — hybrid execution. Merging is always bank-first:
      1) Bank prep: consolidate the bank's own partial stacks for the items we
         are about to withdraw, then replan. Splitting 11 out of a single 19
         beats splitting out of a 9 and a 10, and it stops last session's
         remainders from multiplying.
      2) Burst UseContainerItem for every whole/charge stack (one frame). Whole
         stacks touch independent slots, so bursting them is safe and fast.
      3) Serial Split+Place: ONE split per max(140ms, ping*3) tick, skipping any
         move whose source or destination is still locked. Bursting these made
         the second split land on slots the client had locked, which is why a
         leftover 1 never merged onto an existing 9.
      4) Per move: merge-first, and only fall back to an empty slot after two
         genuine merge failures (a transient lock must not cost the merge).
      5) Cleanup, bank before bags: consolidate the remainders our splits left
         in the bank, then tidy bag partials. Both only move a stack that
         actually fits the destination's room — never pick up a 20 onto a 9,
         which swaps the slots and loops forever.

    Every phase is bounded (per-move attempts, phase deadlines, cursor-clear
    budget) and Exec.Reset() wipes all of it so a second button press replans
    from scratch instead of inheriting the previous run's give-up flags.
]]

FluxBankRestockMoveExec = FluxBankRestockMoveExec or {}
local Exec = FluxBankRestockMoveExec

local function NeedMod()
    return _G.FluxBankRestockNeed
end

local function PlanMod()
    return _G.FluxBankRestockMovePlan
end

local function Ctx()
    return _G.FluxBankRestockMoveContext
end

local function Inv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

local function Bank()
    local inv = Inv()
    return inv and inv.Bank
end

local function Dbg(cat, fmt, ...)
    local d = _G.FluxBankRestockDebug
    if d and d.Print then
        d.Print(cat, fmt, ...)
    end
end

local function DbgImportant(cat, fmt, ...)
    local d = _G.FluxBankRestockDebug
    if d and d.PrintImportant then
        d.PrintImportant(cat, fmt, ...)
    else
        Dbg(cat, fmt, ...)
    end
end

local PHASE_IDLE = "Idle"
local PHASE_WITHDRAW_WAIT = "WithdrawWait"
local PHASE_SPLIT_STEP = "SplitStep"
local PHASE_SPLIT_WAIT = "SplitWait"
local PHASE_BAG_MERGE = "BagMerge"
local PHASE_BANK_MERGE = "BankMerge"

local ACK_TIMEOUT = 3.0
local SETTLE_SEC = 0.12
local SPLIT_SETTLE_SEC = 0.15
local MERGE_IDLE_SEC = 0.35
local MERGE_HARD_TIMEOUT = 5.0
local MAX_BURST = 50
local MAX_REPLANS = 2
-- Merge attempts come first, then the empty-slot fallback gets its own tries.
local MAX_MERGE_FAILS = 2
local MAX_MOVE_ATTEMPTS = 4
local SPLIT_PHASE_TIMEOUT = 12.0
local MAX_CURSOR_CLEARS = 8
local CURSOR_CLEAR_THROTTLE = 0.2
local MAX_MERGE_PER_TICK = 40

--- Fresh field set for a session. Exec.Reset() refills the live `state` table
--- from this so a second button press can never inherit banned items, reserved
--- destinations or give-up flags from the previous run.
local function defaultState()
    return {
        active = false,
        session = nil,
        opts = nil,
        onDone = nil,
        queue = nil,
        withdraw = nil,
        reservedDest = {},
        mergeItemIDs = {},
        mergeBanned = {},
        mergeRetryOnce = {},
        mergeAfter = nil,
        mergeIdleSince = 0,
        mergeStartedAt = 0,
        mergeSettleUntil = 0,
        mergeTotal = 0,
        bankMergeItemIDs = {},
        bankMergeBanned = {},
        bankMergeRetryOnce = {},
        bankMergeStartedAt = 0,
        bankMergeIdleSince = 0,
        bankMergeSettleUntil = 0,
        bankMergeTotal = 0,
        bankMergeStage = nil,
        bankPrepDone = false,
        splitRound = 0,
        splitDeadline = 0,
        nextStepAt = 0,
        cursorClears = 0,
        lastCursorClearAt = 0,
        gaveUpSplits = false,
        phase = PHASE_IDLE,
        phaseStarted = 0,
        replanCount = 0,
        stepsCompleted = 0,
    }
end

local state = defaultState()

local frame = CreateFrame("Frame")
frame:Hide()

local function now()
    return GetTime and GetTime() or 0
end

--- Restocker pacing: never faster than 140ms, and back off to 3x round trip
--- on high latency so the client has time to unlock slots between moves.
local function stepInterval()
    local pingHome, pingWorld = 0, 0
    if GetNetStats then
        local _, _, home, world = GetNetStats()
        pingHome, pingWorld = tonumber(home) or 0, tonumber(world) or 0
    end
    return math.max(0.14, (math.max(pingHome, pingWorld) * 3) / 1000)
end

local function setPhase(phase)
    state.phase = phase
    state.phaseStarted = now()
    Dbg("exec", "phase=%s", phase)
end

local function slotKey(bag, slot)
    return tostring(bag) .. ":" .. tostring(slot)
end

local resolveMaxStack
local collectPartials
local takeEmptyBagSlot

local function creditTask(task, needEntry, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return 0
    end
    local need = NeedMod()
    local credited = 0
    if need and need.Credit then
        credited = need.Credit(task, needEntry, amount)
    elseif task then
        local rem = math.floor(tonumber(task.remaining) or 0)
        credited = math.min(amount, rem)
        task.remaining = math.max(0, rem - credited)
    end
    if credited > 0 then
        state.stepsCompleted = (state.stepsCompleted or 0) + credited
        if state.session then
            state.session.stepsCompleted = (state.session.stepsCompleted or 0) + credited
        end
        local br = _G.FluxBankRestock
        if br and br.RunLiveButtonRefresh then
            br.RunLiveButtonRefresh()
        end
    end
    return credited
end

local function Mover()
    return _G.FluxItemMover
end

local function isWithdrawMove(mv)
    local k = mv and mv.kind or ""
    return k == "whole" or k == "charge"
end

local function isSplitMove(mv)
    return (mv and mv.kind or "") == "split_place"
end

local function countQueueKinds()
    local wholes, splits = 0, 0
    for _, mv in ipairs(state.queue or {}) do
        if isWithdrawMove(mv) then
            wholes = wholes + 1
        elseif isSplitMove(mv) then
            splits = splits + 1
        end
    end
    return wholes, splits
end

local function hasPendingWithdrawMoves()
    for _, mv in ipairs(state.queue or {}) do
        if isWithdrawMove(mv) and not mv.withdrawIssued then
            return true
        end
    end
    return false
end

local function slotItemID(bag, slot)
    local inv = Inv()
    if inv and inv.GetContainerItemInfo then
        local info = inv.GetContainerItemInfo(bag, slot)
        return info and tonumber(info.itemID)
    end
    return nil
end

local function itemsCanMergeAtDest(destItemID, itemID, tierKind)
    if tonumber(destItemID) == tonumber(itemID) then
        return true
    end
    local mover = Mover()
    if tierKind and mover and mover.ItemsCanMerge then
        return mover.ItemsCanMerge(destItemID, itemID, tierKind)
    end
    return false
end

--- Right item and enough headroom, ignoring locks. A dest that is merely locked
--- is still the dest we want — the caller waits for it instead of rebinding to
--- an empty slot, which is how a leftover ends up as a stray stack.
local function mergeDestFits(mv, bag, slot)
    local ctx = Ctx()
    if not ctx or not bag or not slot then
        return false
    end
    local qty = math.floor(tonumber(mv.qty) or 0)
    local maxStack = tonumber(mv.maxStack) or resolveMaxStack(mv.itemID)
    local count = ctx.GetSlotQuantity(bag, slot)
    if count <= 0 then
        return false
    end
    local destItem = slotItemID(bag, slot)
    if destItem == nil or not itemsCanMergeAtDest(destItem, mv.itemID, mv.tierKind) then
        return false
    end
    return (maxStack - count) >= qty
end

local function mergeDestHasRoom(mv, bag, slot)
    local ctx = Ctx()
    if not ctx or not mergeDestFits(mv, bag, slot) then
        return false
    end
    return not ctx.IsSlotLocked(bag, slot)
end

local function emptyDestFree(bag, slot)
    local ctx = Ctx()
    return ctx and bag and slot and ctx.GetSlotQuantity(bag, slot) <= 0
end

local function reserveDest(bag, slot)
    if bag and slot then
        state.reservedDest = state.reservedDest or {}
        state.reservedDest[slotKey(bag, slot)] = true
    end
end

--- Restocker best-fit over live bag partials (respects reservedDest).
local function findBestFitLivePartial(itemID, amount, tierKind, maxStack)
    itemID = tonumber(itemID)
    amount = math.floor(tonumber(amount) or 0)
    maxStack = tonumber(maxStack) or resolveMaxStack(itemID)
    if not itemID or amount <= 0 then
        return nil
    end
    local partials = collectPartials(itemID, maxStack, false)
    local best, bestRemainder
    for _, p in ipairs(partials) do
        local key = slotKey(p.bag, p.slot)
        if not (state.reservedDest and state.reservedDest[key]) then
            local room = maxStack - p.count
            if room >= amount then
                local remainder = room - amount
                if not bestRemainder or remainder < bestRemainder then
                    best = p
                    bestRemainder = remainder
                end
            end
        end
    end
    return best
end

--- A transient lock can fail one merge attempt. Only stop aiming at bag
--- partials once the same move has genuinely failed to merge twice.
local function mergeGivenUp(mv)
    return (tonumber(mv and mv.mergeFails) or 0) >= MAX_MERGE_FAILS
end

local function noteMergeFail(mv, reason)
    if not mv then
        return
    end
    mv.mergeFails = (tonumber(mv.mergeFails) or 0) + 1
    DbgImportant("split", "merge attempt %d/%d failed item=%s — %s",
        mv.mergeFails, MAX_MERGE_FAILS, tostring(mv.itemID), tostring(reason or "?"))
end

--- Live merge-first dest for a split_place move (caller reserves after assign).
local function resolveLiveSplitDest(mv)
    local qty = math.floor(tonumber(mv.qty) or 0)
    if qty <= 0 then
        return nil, nil, nil
    end
    local maxStack = tonumber(mv.maxStack) or resolveMaxStack(mv.itemID)
    local allowMerge = not mergeGivenUp(mv)

    -- Keep an already-chosen merge target even while it is locked (mergeDestFits
    -- ignores locks): the planner picked it because it is the stack we want to
    -- top off, and the step gate waits for the lock to clear.
    if allowMerge
        and mv.destKind == "merge" and mv.toBag and mv.toSlot
        and mergeDestFits(mv, mv.toBag, mv.toSlot) then
        return mv.toBag, mv.toSlot, "merge"
    end
    if mv.destKind == "empty" and mv.toBag and mv.toSlot and emptyDestFree(mv.toBag, mv.toSlot) then
        return mv.toBag, mv.toSlot, "empty"
    end

    if allowMerge then
        local partial = findBestFitLivePartial(mv.itemID, qty, mv.tierKind, maxStack)
        if partial then
            return partial.bag, partial.slot, "merge"
        end
    end

    local bag, slot = takeEmptyBagSlot()
    if bag then
        return bag, slot, "empty"
    end
    return nil, nil, nil
end

local function finishSession(reason)
    local sess = state.session
    local cb = state.onDone
    state.active = false
    state.queue = nil
    state.withdraw = nil
    state.reservedDest = nil
    state.mergeItemIDs = nil
    state.session = nil
    state.onDone = nil
    setPhase(PHASE_IDLE)
    frame:Hide()
    DbgImportant("session", "MoveExec done reason=%s steps=%s",
        tostring(reason or "?"), tostring(state.stepsCompleted or 0))
    if sess and cb then
        pcall(cb, reason)
    end
end

--- Clear a cursor that is blocking progress, and abort the session if it keeps
--- coming back. Counted at most once per CURSOR_CLEAR_THROTTLE so a per-frame
--- phase tick cannot burn the whole budget in a fraction of a second.
local function clearStuckCursor(ctx)
    if not ctx then
        return false
    end
    ctx.ClearCursor()
    local at = now()
    if at - (state.lastCursorClearAt or 0) < CURSOR_CLEAR_THROTTLE then
        return false
    end
    state.lastCursorClearAt = at
    state.cursorClears = (state.cursorClears or 0) + 1
    if state.cursorClears >= MAX_CURSOR_CLEARS then
        DbgImportant("exec", "cursor stuck — abort after %s clears", tostring(state.cursorClears))
        finishSession("cursor_stuck")
        return true
    end
    return false
end

local function rebuildPlan()
    local plan = PlanMod()
    local need = NeedMod()
    if not plan or not need or not state.session then
        return false
    end
    local tasks = state.session.tasks or {}
    local needs = need.BuildFromTasks(tasks)
    if need.TotalRemaining(needs) <= 0 then
        return false
    end
    local moves = plan.Build(needs, state.opts) or {}
    state.queue = moves
    state.withdraw = {}
    state.reservedDest = {}
    state.splitRound = 0
    if state.session then
        state.session.planQueue = moves
    end
    local wholes, splits = countQueueKinds()
    DbgImportant("plan", "replan queue=%d wholes=%d splits=%d", #moves, wholes, splits)
    return #moves > 0
end

takeEmptyBagSlot = function()
    local inv = Inv()
    local ctx = Ctx()
    if not inv or not inv.GetBagContainerIDs then
        return nil, nil
    end
    state.reservedDest = state.reservedDest or {}
    for _, bag in ipairs(inv.GetBagContainerIDs() or {}) do
        local num = inv.GetContainerNumSlots(bag) or 0
        for slot = 1, num do
            local key = slotKey(bag, slot)
            if not state.reservedDest[key] then
                local count = ctx and ctx.GetSlotQuantity(bag, slot) or 0
                if count <= 0 then
                    state.reservedDest[key] = true
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

local function freeDest(bag, slot)
    if bag and slot and state.reservedDest then
        state.reservedDest[slotKey(bag, slot)] = nil
    end
end

local function noteMergeItem(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return
    end
    state.mergeItemIDs = state.mergeItemIDs or {}
    state.mergeItemIDs[itemID] = true
end

resolveMaxStack = function(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 20
    end
    -- Prefer live item stack size (task.maxStack can be stale / target-like).
    if GetItemInfo then
        local name, _, _, _, _, _, _, stack = GetItemInfo(itemID)
        if name and tonumber(stack) and tonumber(stack) > 1 then
            return tonumber(stack)
        end
    end
    local opts = state.opts
    if opts and opts.resolveMaxStack then
        local n = tonumber(opts.resolveMaxStack(itemID))
        if n and n > 1 then
            return n
        end
    end
    for _, task in ipairs(state.session and state.session.tasks or {}) do
        local id = task.entry and task.entry.itemID or task.itemID
        if tonumber(id) == itemID then
            local ms = tonumber(task.maxStack)
                or (task.entry and tonumber(task.entry.maxStack))
            if ms and ms > 1 then
                return ms
            end
        end
    end
    for _, mv in ipairs(state.queue or {}) do
        if isSplitMove(mv) and tonumber(mv.itemID) == itemID and tonumber(mv.maxStack) and tonumber(mv.maxStack) > 1 then
            return tonumber(mv.maxStack)
        end
    end
    return 20
end

collectPartials = function(itemID, maxStack, includeLocked)
    local ctx = Ctx()
    local inv = Inv()
    local out = {}
    if not inv or not inv.FindBagStacks then
        return out
    end
    maxStack = tonumber(maxStack) or 20
    for _, st in ipairs(inv.FindBagStacks(itemID) or {}) do
        local count = tonumber(st.count) or 0
        local locked = st.locked or (ctx and ctx.IsSlotLocked(st.bag, st.slot))
        if count > 0 and count < maxStack and (includeLocked or not locked) then
            out[#out + 1] = {
                bag = st.bag,
                slot = st.slot,
                count = count,
                locked = locked and true or false,
            }
        end
    end
    table.sort(out, function(a, b)
        if a.count == b.count then
            if a.bag == b.bag then
                return a.slot < b.slot
            end
            return a.bag < b.bag
        end
        return a.count < b.count
    end)
    return out
end

local function bagMergeBlockedByLock()
    for itemID in pairs(state.mergeItemIDs or {}) do
        for _, st in ipairs(collectPartials(itemID, resolveMaxStack(itemID), true)) do
            if st.locked then
                return true
            end
        end
    end
    return false
end

local function isChargeItem(itemID)
    itemID = tonumber(itemID)
    for _, task in ipairs(state.session and state.session.tasks or {}) do
        local id = task.entry and task.entry.itemID or task.itemID
        if tonumber(id) == itemID then
            local mode = task.mode or (task.entry and task.entry.mode)
            if mode == "charge" then
                return true
            end
        end
    end
    return false
end

local function banMerge(itemID, reason)
    itemID = tonumber(itemID)
    if not itemID then
        return
    end
    state.mergeBanned = state.mergeBanned or {}
    if not state.mergeBanned[itemID] then
        state.mergeBanned[itemID] = true
        DbgImportant("merge", "skip item=%s — %s", tostring(itemID), tostring(reason or "banned"))
    end
end

--- Items that still have 2+ combinable partial stacks (stackable only).
local function countPendingMerges()
    local pending = 0
    for itemID in pairs(state.mergeItemIDs or {}) do
        if not (state.mergeBanned and state.mergeBanned[itemID]) and not isChargeItem(itemID) then
            local maxStack = resolveMaxStack(itemID)
            if maxStack > 1 then
                local partials = collectPartials(itemID, maxStack, true)
                if #partials >= 2 then
                    local a, b = partials[1], partials[2]
                    -- Only count pairs that can actually combine (a 9 and a 20 cannot).
                    if a.count <= (maxStack - b.count) or b.count <= (maxStack - a.count) then
                        pending = pending + 1
                    end
                end
            end
        end
    end
    return pending
end

--- True only when stacks actually combined (target grew, source shrank).
--- Cursor-clear alone is not enough — non-stacking items just swap.
local function mergeOnto(fromBag, fromSlot, toBag, toSlot)
    local ctx = Ctx()
    local inv = Inv()
    if not ctx or not inv then
        return false
    end
    if ctx.CursorHasItem() then
        ctx.ClearCursor()
    end
    if ctx.IsSlotLocked(fromBag, fromSlot) or ctx.IsSlotLocked(toBag, toSlot) then
        return false
    end
    local fromBefore = ctx.GetSlotQuantity(fromBag, fromSlot)
    local toBefore = ctx.GetSlotQuantity(toBag, toSlot)
    if fromBefore <= 0 or toBefore <= 0 then
        return false
    end
    local destMax = resolveMaxStack(slotItemID(toBag, toSlot)) or 20
    if fromBefore > (destMax - toBefore) then
        -- Whole source does not fit — pickup would swap stacks and loop.
        return false
    end

    inv.PickupContainerItem(fromBag, fromSlot)
    if not ctx.CursorHasItem() and C_Container and C_Container.PickupContainerItem then
        pcall(C_Container.PickupContainerItem, fromBag, fromSlot)
    end
    if not ctx.CursorHasItem() then
        return false
    end
    inv.PickupContainerItem(toBag, toSlot)
    if ctx.CursorHasItem() then
        ctx.ReturnToSource(fromBag, fromSlot)
        if ctx.CursorHasItem() then
            ctx.ClearCursor()
        end
    end

    local fromAfter = ctx.GetSlotQuantity(fromBag, fromSlot)
    local toAfter = ctx.GetSlotQuantity(toBag, toSlot)
    -- Real merge: destination stack grew and source shrank/emptied.
    if toAfter > toBefore and fromAfter < fromBefore then
        return true
    end
    -- Swap or no-op — not progress.
    return false
end

--- Prefer merging the two smallest partials until one is full or only one partial remains.
local function tryMergeSmallestPair(itemID)
    itemID = tonumber(itemID)
    if not itemID or (state.mergeBanned and state.mergeBanned[itemID]) then
        return false
    end
    if isChargeItem(itemID) then
        banMerge(itemID, "charge mode")
        return false
    end

    local maxStack = resolveMaxStack(itemID)
    if maxStack <= 1 then
        banMerge(itemID, "maxStack=1")
        return false
    end

    local partials = collectPartials(itemID, maxStack, false)
    if #partials < 2 then
        return false
    end

    local a, b = partials[1], partials[2]
    local roomB = maxStack - b.count
    local roomA = maxStack - a.count
    local ok = false
    -- Only merge a stack that actually fits. Never pick up a 20 onto a 9
    -- (that swaps the two slots and loops).
    if a.count <= roomB then
        DbgImportant("merge", "smallest item=%s %s:%s x%s -> %s:%s x%s",
            tostring(itemID), a.bag, a.slot, a.count, b.bag, b.slot, b.count)
        ok = mergeOnto(a.bag, a.slot, b.bag, b.slot)
    elseif b.count <= roomA then
        DbgImportant("merge", "smallest item=%s %s:%s x%s -> %s:%s x%s",
            tostring(itemID), b.bag, b.slot, b.count, a.bag, a.slot, a.count)
        ok = mergeOnto(b.bag, b.slot, a.bag, a.slot)
    else
        return false
    end

    if not ok then
        local ctx = Ctx()
        if ctx and (ctx.IsSlotLocked(a.bag, a.slot) or ctx.IsSlotLocked(b.bag, b.slot)) then
            return false
        end
        state.mergeRetryOnce = state.mergeRetryOnce or {}
        if not state.mergeRetryOnce[itemID] then
            state.mergeRetryOnce[itemID] = true
            state.mergeSettleUntil = math.max(state.mergeSettleUntil or 0, now() + SETTLE_SEC)
            return false
        end
        -- Non-stacking (different charges, unique, etc.) — stop trying this item.
        banMerge(itemID, "no stack progress (swap/blocked)")
        return false
    end
    if state.mergeRetryOnce then
        state.mergeRetryOnce[itemID] = nil
    end
    return true
end

--- Burst: repeatedly merge two-smallest pairs across all tracked items.
local function fireBagMergeBurst()
    local ctx = Ctx()
    local inv = Inv()
    if not ctx or not inv then
        return 0
    end
    if inv.ForceRefreshBagCounts then
        inv.ForceRefreshBagCounts()
    end
    if ctx.CursorHasItem() then
        ctx.ClearCursor()
        return 0
    end

    local issued = 0
    while issued < MAX_MERGE_PER_TICK do
        local made = false
        local ids = {}
        for itemID in pairs(state.mergeItemIDs or {}) do
            if not (state.mergeBanned and state.mergeBanned[itemID]) then
                ids[#ids + 1] = itemID
            end
        end
        table.sort(ids)
        for _, itemID in ipairs(ids) do
            if issued >= MAX_MERGE_PER_TICK then
                break
            end
            if tryMergeSmallestPair(itemID) then
                issued = issued + 1
                made = true
            end
        end
        if not made then
            break
        end
    end
    return issued
end

-- ---------------------------------------------------------------------------
-- BANK-SIDE CONSOLIDATION
-- Withdrawing partial amounts leaves fragments behind in the bank (a 20 split
-- for 11 leaves a 9). Combine those the same way as bag partials so the next
-- session sees whole stacks instead of a growing pile of remainders.
-- ---------------------------------------------------------------------------

--- Force one bank walk for the current tick. collectBankPartials then reads the
--- refreshed snapshot, so a phase with many items costs one walk, not one per item.
local function refreshBankSnapshot()
    local bank = Bank()
    if bank and bank.Refresh then
        bank.Refresh({ force = true })
    end
end

local function collectBankPartials(itemID, maxStack, includeLocked)
    local bank = Bank()
    local ctx = Ctx()
    local out = {}
    if not bank or not bank.FindStacks then
        return out
    end
    maxStack = tonumber(maxStack) or 20
    for _, st in ipairs(bank.FindStacks(itemID) or {}) do
        local count = tonumber(st.count) or 0
        local locked = st.locked or (ctx and ctx.IsSlotLocked(st.bag, st.slot))
        if count > 0 and count < maxStack and (includeLocked or not locked) then
            out[#out + 1] = {
                bag = st.bag,
                slot = st.slot,
                count = count,
                locked = locked and true or false,
            }
        end
    end
    table.sort(out, function(a, b)
        if a.count == b.count then
            if a.bag == b.bag then
                return a.slot < b.slot
            end
            return a.bag < b.bag
        end
        return a.count < b.count
    end)
    return out
end

local function countPendingBankMerges()
    local pending = 0
    for itemID in pairs(state.bankMergeItemIDs or {}) do
        if not (state.bankMergeBanned and state.bankMergeBanned[itemID]) and not isChargeItem(itemID) then
            local maxStack = resolveMaxStack(itemID)
            if maxStack > 1 then
                local partials = collectBankPartials(itemID, maxStack, true)
                if #partials >= 2 then
                    local a, b = partials[1], partials[2]
                    if a.count <= (maxStack - b.count) or b.count <= (maxStack - a.count) then
                        pending = pending + 1
                    end
                end
            end
        end
    end
    return pending
end

local function banBankMerge(itemID, reason)
    itemID = tonumber(itemID)
    if not itemID then
        return
    end
    state.bankMergeBanned = state.bankMergeBanned or {}
    if not state.bankMergeBanned[itemID] then
        state.bankMergeBanned[itemID] = true
        DbgImportant("merge", "bank skip item=%s — %s", tostring(itemID), tostring(reason or "banned"))
    end
end

--- Same two-smallest / must-fit rule as the bag side.
local function tryMergeSmallestBankPair(itemID)
    itemID = tonumber(itemID)
    if not itemID or (state.bankMergeBanned and state.bankMergeBanned[itemID]) then
        return false
    end
    if isChargeItem(itemID) then
        banBankMerge(itemID, "charge mode")
        return false
    end

    local maxStack = resolveMaxStack(itemID)
    if maxStack <= 1 then
        banBankMerge(itemID, "maxStack=1")
        return false
    end

    local partials = collectBankPartials(itemID, maxStack, false)
    if #partials < 2 then
        return false
    end

    local a, b = partials[1], partials[2]
    local ok
    if a.count <= (maxStack - b.count) then
        DbgImportant("merge", "bank item=%s %s:%s x%s -> %s:%s x%s",
            tostring(itemID), a.bag, a.slot, a.count, b.bag, b.slot, b.count)
        ok = mergeOnto(a.bag, a.slot, b.bag, b.slot)
    elseif b.count <= (maxStack - a.count) then
        DbgImportant("merge", "bank item=%s %s:%s x%s -> %s:%s x%s",
            tostring(itemID), b.bag, b.slot, b.count, a.bag, a.slot, a.count)
        ok = mergeOnto(b.bag, b.slot, a.bag, a.slot)
    else
        return false
    end

    if not ok then
        local ctx = Ctx()
        if ctx and (ctx.IsSlotLocked(a.bag, a.slot) or ctx.IsSlotLocked(b.bag, b.slot)) then
            return false
        end
        state.bankMergeRetryOnce = state.bankMergeRetryOnce or {}
        if not state.bankMergeRetryOnce[itemID] then
            state.bankMergeRetryOnce[itemID] = true
            state.bankMergeSettleUntil = math.max(state.bankMergeSettleUntil or 0, now() + SETTLE_SEC)
            return false
        end
        banBankMerge(itemID, "no stack progress (swap/blocked)")
        return false
    end
    if state.bankMergeRetryOnce then
        state.bankMergeRetryOnce[itemID] = nil
    end
    return true
end

local function bankMergeBlockedByLock()
    for itemID in pairs(state.bankMergeItemIDs or {}) do
        for _, p in ipairs(collectBankPartials(itemID, resolveMaxStack(itemID), true)) do
            if p.locked then
                return true
            end
        end
    end
    return false
end

-- Forward decls
local beginSplitPhase
local beginBankMergePhase

local function finishRestockWork()
    local need = NeedMod()
    local tasks = state.session and state.session.tasks or {}
    local still = need and need.BuildFromTasks(tasks)
    if still and need.TotalRemaining(still) > 0
        and state.replanCount < MAX_REPLANS
        and not state.gaveUpSplits then
        state.replanCount = state.replanCount + 1
        if rebuildPlan() then
            setPhase(PHASE_IDLE)
            return
        end
    end
    finishSession("done")
end

local function beginBagMergePhase(after)
    state.mergeItemIDs = {}
    state.mergeBanned = {}
    state.mergeRetryOnce = {}
    for _, task in ipairs(state.session and state.session.tasks or {}) do
        local id = task.entry and task.entry.itemID or task.itemID
        local mode = task.mode or (task.entry and task.entry.mode)
        if mode ~= "charge" then
            noteMergeItem(id)
        end
    end
    for _, mv in ipairs(state.queue or {}) do
        if isSplitMove(mv) then
            noteMergeItem(mv.itemID)
        elseif isWithdrawMove(mv) and mv.kind ~= "charge" then
            noteMergeItem(mv.itemID)
        end
    end
    state.mergeAfter = after or "done"
    state.mergeStartedAt = now()
    state.mergeIdleSince = now()
    state.mergeTotal = 0
    state.mergeSettleUntil = now() + MERGE_IDLE_SEC
    local n = 0
    for _ in pairs(state.mergeItemIDs) do
        n = n + 1
    end
    DbgImportant("session", "bag merge burst items=%d after=%s pending~%d",
        n, tostring(state.mergeAfter), countPendingMerges())
    setPhase(PHASE_BAG_MERGE)
end

local function tickBagMerge()
    local ctx = Ctx()
    if ctx and ctx.CursorHasItem() then
        if clearStuckCursor(ctx) then
            return
        end
        return
    end
    state.cursorClears = 0

    -- Wait for post-split bag locks / counts to settle before first scan.
    if now() < (state.mergeSettleUntil or 0) then
        return
    end

    local issued = fireBagMergeBurst()
    local pending = countPendingMerges()
    if issued > 0 then
        state.mergeTotal = (state.mergeTotal or 0) + issued
        state.mergeIdleSince = now()
        DbgImportant("merge", "burst issued=%d total=%d pending~%d",
            issued, state.mergeTotal, pending)
        return
    end

    if pending > 0 or bagMergeBlockedByLock() then
        if (now() - (state.mergeStartedAt or 0)) < MERGE_HARD_TIMEOUT then
            return
        end
        DbgImportant("merge", "hard timeout pending~%d locked=%s",
            pending, bagMergeBlockedByLock() and "Y" or "N")
    elseif (now() - (state.mergeIdleSince or 0)) < 0.25 then
        return
    end

    local after = state.mergeAfter or "done"
    state.mergeAfter = nil
    DbgImportant("session", "bag merge done total=%d next=%s",
        state.mergeTotal or 0, tostring(after))
    if after == "splits" then
        beginSplitPhase()
        return
    end
    finishRestockWork()
end

--- Where a finished bank-merge stage hands off to.
---  "prep"    — ran before any withdrawal, so replan against the merged stacks.
---  "cleanup" — ran after the splits, so tidy the bags next.
local function finishBankMergeStage()
    local stage = state.bankMergeStage or "cleanup"
    state.bankMergeStage = nil
    DbgImportant("session", "bank merge (%s) done total=%d",
        stage, state.bankMergeTotal or 0)

    if stage ~= "prep" then
        beginBagMergePhase("done")
        return
    end

    state.bankPrepDone = true
    -- Consolidating changed which bank slots hold what, so the withdraw/split
    -- plan must be rebuilt against the merged stacks before anything moves.
    if (state.bankMergeTotal or 0) > 0 and not rebuildPlan() then
        finishSession("done")
        return
    end
    setPhase(PHASE_IDLE)
end

beginBankMergePhase = function(stage)
    stage = stage or "cleanup"
    if stage == "prep" and state.bankPrepDone then
        setPhase(PHASE_IDLE)
        return
    end

    state.bankMergeStage = stage
    state.bankMergeItemIDs = {}
    state.bankMergeBanned = {}
    state.bankMergeRetryOnce = {}
    -- Only items this session actually touched: never reorganize the whole bank.
    for _, mv in ipairs(state.queue or {}) do
        if mv.kind ~= "charge" then
            local id = tonumber(mv.itemID)
            if id then
                state.bankMergeItemIDs[id] = true
            end
        end
    end
    state.bankMergeStartedAt = now()
    state.bankMergeIdleSince = now()
    state.bankMergeSettleUntil = now() + (stage == "prep" and 0 or MERGE_IDLE_SEC)
    state.bankMergeTotal = 0
    state.nextStepAt = state.bankMergeSettleUntil
    local n = 0
    for _ in pairs(state.bankMergeItemIDs) do
        n = n + 1
    end
    if n > 0 then
        refreshBankSnapshot()
    end
    local pending = n > 0 and countPendingBankMerges() or 0
    if pending == 0 then
        -- Nothing to combine — do not make every restock pay for this phase.
        finishBankMergeStage()
        return
    end
    DbgImportant("session", "bank merge (%s) items=%d pending~%d", stage, n, pending)
    setPhase(PHASE_BANK_MERGE)
end

--- One bank pair per tick: both slots are bank-side, so the client needs the
--- same breathing room between pickups that the split steps get.
local function tickBankMerge()
    local ctx = Ctx()
    if ctx and ctx.CursorHasItem() then
        if clearStuckCursor(ctx) then
            return
        end
        return
    end
    state.cursorClears = 0

    if now() < (state.bankMergeSettleUntil or 0) or now() < (state.nextStepAt or 0) then
        return
    end
    refreshBankSnapshot()

    local ids = {}
    for itemID in pairs(state.bankMergeItemIDs or {}) do
        if not (state.bankMergeBanned and state.bankMergeBanned[itemID]) then
            ids[#ids + 1] = itemID
        end
    end
    table.sort(ids)

    for _, itemID in ipairs(ids) do
        if tryMergeSmallestBankPair(itemID) then
            state.bankMergeTotal = (state.bankMergeTotal or 0) + 1
            state.bankMergeIdleSince = now()
            state.nextStepAt = now() + stepInterval()
            DbgImportant("merge", "bank merged total=%d pending~%d",
                state.bankMergeTotal, countPendingBankMerges())
            return
        end
    end

    state.nextStepAt = now() + stepInterval()
    local pending = countPendingBankMerges()
    if pending > 0 or bankMergeBlockedByLock() then
        if (now() - (state.bankMergeStartedAt or 0)) < MERGE_HARD_TIMEOUT then
            return
        end
        DbgImportant("merge", "bank hard timeout pending~%d", pending)
    elseif (now() - (state.bankMergeIdleSince or 0)) < 0.25 then
        return
    end

    finishBankMergeStage()
end

--- Rebind destinations for every pending split against live bags. Keeps the
--- planned merge target when it still fits (even if momentarily locked) so the
--- top-off the planner designed is not downgraded to a stray empty slot.
local function refreshPartialDestinations()
    state.reservedDest = {}
    for _, mv in ipairs(state.queue or {}) do
        if isSplitMove(mv) and not mv.done then
            if mv.toBag and mv.toSlot
                and state.reservedDest[slotKey(mv.toBag, mv.toSlot)] then
                -- Someone else in this pass claimed it; force a rescan.
                mv.toBag, mv.toSlot = nil, nil
            end
            local bag, slot, kind = resolveLiveSplitDest(mv)
            mv.toBag, mv.toSlot = bag, slot
            mv.destKind = kind
            if kind == "merge" and bag and slot then
                reserveDest(bag, slot)
            end
            mv.inFlight = false
            mv.placed = false
            mv.sawUiError = false
            mv.attempts = mv.attempts or 0
            Dbg("plan", "partial dest item=%s amt=%s -> %s:%s kind=%s",
                tostring(mv.itemID), tostring(mv.qty), tostring(bag), tostring(slot), tostring(kind))
        end
    end
end

local function fireWithdrawBurst()
    local ctx = Ctx()
    if not ctx then
        return 0
    end
    if ctx.CursorHasItem() then
        ctx.ClearCursor()
    end

    local issued = 0
    local pending = 0
    for _, mv in ipairs(state.queue or {}) do
        if isWithdrawMove(mv) and not mv.withdrawIssued then
            if issued >= MAX_BURST then
                pending = pending + 1
            elseif ctx.IsSlotLocked(mv.fromBag, mv.fromSlot) then
                pending = pending + 1
            else
                local had = ctx.GetSlotQuantity(mv.fromBag, mv.fromSlot)
                if had > 0 and ctx.UseWhole(mv.fromBag, mv.fromSlot) then
                    issued = issued + 1
                    mv.withdrawIssued = true
                    local credit = had
                    if mv.kind == "charge" then
                        credit = tonumber(mv.chargeCredit) or had
                    end
                    Dbg("session", "withdraw whole item=%s amt=%s bank=%s:%s",
                        tostring(mv.itemID), tostring(had), tostring(mv.fromBag), tostring(mv.fromSlot))
                    state.withdraw[#state.withdraw + 1] = {
                        fromBag = mv.fromBag,
                        fromSlot = mv.fromSlot,
                        itemID = mv.itemID,
                        creditQty = credit,
                        task = mv.task,
                        need = mv.need,
                        acked = false,
                    }
                    noteMergeItem(mv.itemID)
                else
                    pending = pending + 1
                end
            end
        end
    end
    local _, splits = countQueueKinds()
    DbgImportant("session", "withdraw burst issued=%d pending=%d splits=%d",
        issued, pending, splits)
    return issued
end

local function pollWithdrawAcks()
    local ctx = Ctx()
    if not ctx then
        return true
    end
    local allDone = true
    for _, w in ipairs(state.withdraw or {}) do
        if not w.acked then
            if ctx.SourceAcked(w.fromBag, w.fromSlot, 0) then
                w.acked = true
                creditTask(w.task, w.need, w.creditQty)
            else
                allDone = false
            end
        end
    end
    return allDone
end

local function completeSplit(mv, ok, reason)
    if not mv or mv.done then
        return
    end
    mv.done = true
    mv.inFlight = false
    DbgImportant("session", "split %s item=%s amt=%s reason=%s",
        ok and "ok" or "fail", tostring(mv.itemID), tostring(mv.qty), tostring(reason or "-"))
    if ok then
        creditTask(mv.task, mv.need, mv.qty)
        noteMergeItem(mv.itemID)
    end
    freeDest(mv.toBag, mv.toSlot)
end

--- Bind (or rebind) a live destination for a split move. Returns true when the
--- move has somewhere to land.
local function ensureSplitDest(mv)
    local destOk = mv.toBag and mv.toSlot
        and ((mv.destKind == "merge" and not mergeGivenUp(mv)
                and mergeDestFits(mv, mv.toBag, mv.toSlot))
            or (mv.destKind == "empty" and emptyDestFree(mv.toBag, mv.toSlot)))
    if destOk then
        return true
    end
    freeDest(mv.toBag, mv.toSlot)
    local bag, slot, kind = resolveLiveSplitDest(mv)
    mv.toBag, mv.toSlot = bag, slot
    mv.destKind = kind
    if kind == "merge" and bag and slot then
        reserveDest(bag, slot)
    end
    return mv.toBag ~= nil and mv.toSlot ~= nil
end

--- A split move is issuable only when nothing it touches is locked. Restocker
--- skips the whole cycle on any lock rather than pushing into a busy slot.
local function splitMoveReady(mv, ctx)
    if ctx.IsSlotLocked(mv.fromBag, mv.fromSlot) then
        return false, "source_locked"
    end
    if mv.toBag and mv.toSlot and ctx.IsSlotLocked(mv.toBag, mv.toSlot) then
        return false, "dest_locked"
    end
    return true
end

--- Roll back a failed attempt so the next tick can retry or fall back to empty.
local function abandonSplitAttempt(mv, ctx, reason)
    if ctx.CursorHasItem() then
        ctx.ReturnToSource(mv.fromBag, mv.fromSlot)
    end
    if mv.destKind == "merge" then
        noteMergeFail(mv, reason)
        freeDest(mv.toBag, mv.toSlot)
        mv.toBag, mv.toSlot, mv.destKind = nil, nil, nil
    end
    mv.inFlight = false
    mv.placed = false
    if (mv.attempts or 0) >= MAX_MOVE_ATTEMPTS then
        completeSplit(mv, false, "max_attempts")
    end
end

--- Issue exactly ONE partial Split+Place, Restocker style. Bursting these in a
--- single frame made the second split land while the client still had the first
--- move's slots locked, which is why a leftover 1 never merged onto a 9.
--- @return boolean issued, boolean blocked (something pending but locked)
local function fireOneSplit()
    local ctx = Ctx()
    if not ctx then
        return false, false
    end
    if ctx.CursorHasItem() then
        clearStuckCursor(ctx)
        return false, true
    end
    state.cursorClears = 0

    local blocked = false
    for _, mv in ipairs(state.queue or {}) do
        if isSplitMove(mv) and not mv.done and not mv.inFlight then
            local qty = math.floor(tonumber(mv.qty) or 0)
            local before = ctx.GetSlotQuantity(mv.fromBag, mv.fromSlot)
            if before <= 0 then
                completeSplit(mv, false, "source_gone")
            elseif (mv.attempts or 0) >= MAX_MOVE_ATTEMPTS then
                completeSplit(mv, false, "max_attempts")
            else
                local hasDest = ensureSplitDest(mv)
                local ready, why = splitMoveReady(mv, ctx)
                if not ready then
                    Dbg("split", "defer %s bank=%s:%s", tostring(why), mv.fromBag, mv.fromSlot)
                    blocked = true
                elseif not hasDest then
                    -- No partial with room and no empty slot: taking the whole
                    -- remaining stack is still progress when it fits the need.
                    if qty >= before and ctx.UseWhole(mv.fromBag, mv.fromSlot) then
                        mv.sourceBefore = before
                        mv.endQty = 0
                        mv.attempts = (mv.attempts or 0) + 1
                        mv.placed = true
                        mv.inFlight = true
                        DbgImportant("split", "whole bank=%s:%s (no dest)", mv.fromBag, mv.fromSlot)
                        return true, blocked
                    end
                    completeSplit(mv, false, "no_room")
                else
                    -- qty >= before means "take what is left of this bank stack",
                    -- but still place it onto the merge dest instead of
                    -- UseContainerItem, which would dump it in an empty slot.
                    local takeQty = math.min(qty, before)
                    mv.sourceBefore = before
                    mv.endQty = before - takeQty
                    mv.attempts = (mv.attempts or 0) + 1
                    mv.sawUiError = false
                    DbgImportant("split", "step bank=%s:%s amt=%s -> %s:%s dest=%s (attempt %s)",
                        mv.fromBag, mv.fromSlot, takeQty, mv.toBag, mv.toSlot,
                        tostring(mv.destKind), tostring(mv.attempts))
                    local ok, reason = ctx.TryBankSplitPlace(
                        mv.fromBag, mv.fromSlot, mv.toBag, mv.toSlot, takeQty)
                    if ctx.CursorHasItem() then
                        ctx.Place(mv.toBag, mv.toSlot)
                    end
                    local left = ctx.GetSlotQuantity(mv.fromBag, mv.fromSlot)
                    if ok or reason == "split_pending"
                        or (not ctx.CursorHasItem() and left < before) then
                        mv.placed = true
                        mv.inFlight = true
                        return true, blocked
                    end
                    abandonSplitAttempt(mv, ctx, reason or "place_failed")
                    return false, true
                end
            end
        end
    end
    return false, blocked
end

local function pendingSplits()
    local n = 0
    for _, mv in ipairs(state.queue or {}) do
        if isSplitMove(mv) and not mv.done then
            n = n + 1
        end
    end
    return n
end

local function inFlightSplits()
    local n = 0
    for _, mv in ipairs(state.queue or {}) do
        if isSplitMove(mv) and mv.inFlight and not mv.done then
            n = n + 1
        end
    end
    return n
end

local function pollSplitAcks()
    local ctx = Ctx()
    if not ctx then
        return true
    end
    local allDone = true
    for _, mv in ipairs(state.queue or {}) do
        if isSplitMove(mv) and mv.inFlight and not mv.done then
            local before = tonumber(mv.sourceBefore) or 0
            local endQty = tonumber(mv.endQty) or 0
            local left = ctx.GetSlotQuantity(mv.fromBag, mv.fromSlot)
            local locked = ctx.IsSlotLocked(mv.fromBag, mv.fromSlot)

            if left <= endQty or (before > 0 and left < before) then
                if left < before and left > endQty then
                    mv.qty = before - left
                end
                completeSplit(mv, true, "acked")
            elseif locked then
                allDone = false
            elseif left >= before and not ctx.CursorHasItem() then
                -- Rejected — clear inFlight for retry (or give up).
                if mv.sawUiError or (now() - (state.phaseStarted or 0)) >= 0.5 then
                    mv.inFlight = false
                    mv.placed = false
                    if mv.destKind == "merge" then
                        noteMergeFail(mv, "rejected")
                        freeDest(mv.toBag, mv.toSlot)
                        mv.toBag, mv.toSlot, mv.destKind = nil, nil, nil
                    end
                    if (mv.attempts or 0) >= MAX_MOVE_ATTEMPTS then
                        completeSplit(mv, false, "max_attempts")
                    else
                        DbgImportant("split", "reject item=%s — will retry", tostring(mv.itemID))
                    end
                else
                    allDone = false
                end
            else
                allDone = false
            end
        end
    end
    return allDone and inFlightSplits() == 0
end

--- Abandon every split still pending and move on. Nothing replans these: a
--- leftover the client keeps refusing must not restart the whole session.
local function giveUpRemainingSplits(reason)
    local gaveUp = false
    for _, mv in ipairs(state.queue or {}) do
        if isSplitMove(mv) and not mv.done then
            completeSplit(mv, false, reason)
            gaveUp = true
        end
    end
    if gaveUp then
        state.gaveUpSplits = true
    end
end

beginSplitPhase = function(settleAfterWithdraw)
    refreshPartialDestinations()
    state.splitRound = (state.splitRound or 0) + 1
    state.nextStepAt = now() + (settleAfterWithdraw and SPLIT_SETTLE_SEC or 0)
    state.splitDeadline = now() + SPLIT_PHASE_TIMEOUT
    DbgImportant("session", "split phase round=%d partials=%d interval=%.0fms",
        state.splitRound, pendingSplits(), stepInterval() * 1000)
    setPhase(PHASE_SPLIT_STEP)
end

--- One move per tick, paced like Restocker's coroutine resume.
local function tickSplitStep()
    if pendingSplits() <= 0 then
        beginBankMergePhase("cleanup")
        return
    end
    if now() >= (state.splitDeadline or 0) then
        DbgImportant("split", "phase timeout — abandoning %d split(s)", pendingSplits())
        giveUpRemainingSplits("phase_timeout")
        beginBankMergePhase("cleanup")
        return
    end
    if now() < (state.nextStepAt or 0) then
        return
    end

    local issued, blocked = fireOneSplit()
    state.nextStepAt = now() + stepInterval()
    if issued then
        setPhase(PHASE_SPLIT_WAIT)
        return
    end
    if not blocked and pendingSplits() <= 0 then
        beginBankMergePhase("cleanup")
    end
    -- Blocked by a lock or a failed attempt: stay in this phase and retry on
    -- the next interval until the deadline.
end

--- Wait for the single in-flight move, then step again.
local function tickSplitWait()
    if pollSplitAcks() then
        setPhase(PHASE_SPLIT_STEP)
        return
    end
    if (now() - (state.phaseStarted or 0)) >= ACK_TIMEOUT then
        local ctx = Ctx()
        for _, mv in ipairs(state.queue or {}) do
            if isSplitMove(mv) and mv.inFlight and not mv.done then
                local before = tonumber(mv.sourceBefore) or 0
                local left = ctx and ctx.GetSlotQuantity(mv.fromBag, mv.fromSlot) or before
                if left < before then
                    mv.qty = before - left
                    completeSplit(mv, true, "ack_timeout")
                elseif (mv.attempts or 0) >= MAX_MOVE_ATTEMPTS then
                    completeSplit(mv, false, "ack_timeout")
                else
                    mv.inFlight = false
                    mv.placed = false
                end
            end
        end
        setPhase(PHASE_SPLIT_STEP)
    end
end

local function tickIdle()
    local ctx = Ctx()
    if ctx and ctx.CursorHasItem() then
        if clearStuckCursor(ctx) then
            return
        end
        return
    end
    state.cursorClears = 0

    if hasPendingWithdrawMoves() then
        local issued = fireWithdrawBurst()
        if issued > 0 then
            setPhase(PHASE_WITHDRAW_WAIT)
            return
        end
        if (now() - (state.phaseStarted or 0)) < ACK_TIMEOUT then
            return
        end
        -- Locked or failed wholes — skip to splits if any.
    end

    if pendingSplits() > 0 then
        beginSplitPhase()
        return
    end

    beginBankMergePhase("cleanup")
end

local function tickWithdrawWait()
    local done = pollWithdrawAcks()
    if done then
        if hasPendingWithdrawMoves() then
            setPhase(PHASE_IDLE)
            return
        end
        -- Let withdrawn stacks land before splitting onto bag partials.
        if pendingSplits() > 0 then
            beginSplitPhase(true)
        else
            beginBankMergePhase("cleanup")
        end
        return
    end
    if (now() - (state.phaseStarted or 0)) >= ACK_TIMEOUT then
        for _, w in ipairs(state.withdraw or {}) do
            if not w.acked then
                w.acked = true
                creditTask(w.task, w.need, w.creditQty)
            end
        end
        if hasPendingWithdrawMoves() then
            setPhase(PHASE_IDLE)
            return
        end
        if pendingSplits() > 0 then
            beginSplitPhase(true)
        else
            beginBankMergePhase("cleanup")
        end
    end
end

local function onUpdate()
    if not state.active or not state.session then
        frame:Hide()
        return
    end
    if state.session.aborted then
        local ctx = Ctx()
        if ctx then
            ctx.ClearCursor()
        end
        finishSession("aborted")
        return
    end
    local bank = Bank()
    if not bank or not bank.IsLive or not bank.IsLive() then
        finishSession("bank_close")
        return
    end

    local phase = state.phase or PHASE_IDLE
    if phase == PHASE_IDLE then
        tickIdle()
    elseif phase == PHASE_WITHDRAW_WAIT then
        tickWithdrawWait()
    elseif phase == PHASE_SPLIT_STEP then
        tickSplitStep()
    elseif phase == PHASE_SPLIT_WAIT then
        tickSplitWait()
    elseif phase == PHASE_BAG_MERGE then
        tickBagMerge()
    elseif phase == PHASE_BANK_MERGE then
        tickBankMerge()
    else
        setPhase(PHASE_IDLE)
    end
end

frame:SetScript("OnUpdate", onUpdate)

--- Drop every trace of a previous run. Closures capture `state`, so refill it
--- in place instead of rebinding the local.
function Exec.Reset()
    frame:Hide()
    for key in pairs(state) do
        state[key] = nil
    end
    for key, value in pairs(defaultState()) do
        state[key] = value
    end
    Dbg("exec", "MoveExec state reset")
end

function Exec.Start(session, opts)
    if not session or not session.tasks then
        return false
    end
    Exec.Reset()
    opts = opts or {}
    state.active = true
    state.session = session
    state.opts = opts
    state.onDone = opts.onDone
    state.stepsCompleted = session.stepsCompleted or 0
    setPhase(PHASE_IDLE)

    if not rebuildPlan() then
        DbgImportant("session", "MoveExec nothing to move")
        state.active = false
        state.session = nil
        return false
    end

    local wholes, splits = countQueueKinds()
    DbgImportant("session", "MoveExec started queue=%d wholes=%d splits=%d",
        #(state.queue or {}), wholes, splits)

    -- Consolidate bank fragments BEFORE moving anything, then replan. Splitting
    -- out of a single 19 beats splitting out of a 9 and a 10, and it keeps last
    -- session's remainders from multiplying.
    beginBankMergePhase("prep")

    frame:Show()
    return true
end

function Exec.Stop()
    if not state.active then
        Exec.Reset()
        return
    end
    local ctx = Ctx()
    if ctx then
        ctx.ClearCursor()
    end
    Exec.Reset()
end

function Exec.IsActive()
    return state.active == true
end

function Exec.OnSplitRejected()
    if not state.active then
        return
    end
    local ctx = Ctx()
    if not ctx then
        return
    end
    -- Mark any in-flight split whose source has not shrunk.
    for _, mv in ipairs(state.queue or {}) do
        if isSplitMove(mv) and mv.inFlight and not mv.done then
            local before = tonumber(mv.sourceBefore) or 0
            local left = ctx.GetSlotQuantity(mv.fromBag, mv.fromSlot)
            if before > 0 and left >= before then
                mv.sawUiError = true
                if ctx.CursorHasItem() then
                    ctx.ReturnToSource(mv.fromBag, mv.fromSlot)
                end
                DbgImportant("event", "UI_ERROR on in-flight item=%s", tostring(mv.itemID))
            elseif before > 0 and left < before then
                -- Actually succeeded despite error.
                Dbg("event", "UI_ERROR ignored — source shrunk item=%s", tostring(mv.itemID))
            end
        end
    end
end

function Exec.Wake()
end

_G.FluxBankRestockMoveExec = Exec
return Exec
