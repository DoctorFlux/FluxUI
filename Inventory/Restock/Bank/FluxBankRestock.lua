--[[
    Restock/Bank/FluxBankRestock.lua

    Bank restock session: task build, events, and TSM-style MoveExec.
    Live path: Need → MovePlan → MoveExec (burst whole + verified split/place).
]]

FluxBankRestock = FluxBankRestock or {}
local BR = FluxBankRestock

local function Inv() return _G.FluxRestock and _G.FluxRestock.Inv end
local function Bank()
    local inv = Inv()
    return inv and inv.Bank
end
local function IC() return _G.FluxItemClass end
local function Mover() return _G.FluxItemMover end
local function Registry() return _G.FluxRestockItemRegistry end
local function Rules() return _G.FluxBankRestockRules end
local function Planner() return _G.FluxBankRestockPlanner end
local function Inventory() return _G.FluxBankRestockInventory end
local function MovesMod() return _G.FluxBankRestockMoves end
local function ExecutorMod() return _G.FluxBankRestockExecutor end
local function LedgerMod() return _G.FluxBankRestockLedger end
local function EngineMod() return _G.FluxBankRestockEngine end
local function PlanExecutorMod() return _G.FluxBankRestockPlanExecutor end
local function MoveExecMod() return _G.FluxBankRestockMoveExec end
local function Settings() return FluxRestockSettings.Get() end

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

local function DbgStep(step, tag)
    local d = _G.FluxBankRestockDebug
    if d and d.FormatStep then
        local sig = (tag or "step") .. ":" .. d.FormatStep(step)
        if d.PrintThrottled then
            d.PrintThrottled("step", sig, 2.0, "%s %s", tag or "step", d.FormatStep(step))
        else
            Dbg("step", "%s %s", tag or "step", d.FormatStep(step))
        end
    end
end

local function After(delay, fn)
    if FluxAPICompat and FluxAPICompat.After then
        FluxAPICompat.After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

local SPLIT_FAIL_LIMIT = 5
local STALL_REPLAN_TICKS = 8
local MOVE_FAIL_LIMIT = 6
local LOCK_RETRY_LIMIT = 24
local TASK_PROGRESS_STALL_LIMIT = 6
local NO_STACK_RECOVERY_TICKS = 4
local STRAY_CURSOR_TICK_LIMIT = 12

-- Confirmed server-side split rejections ("Couldn't split those items").
-- Deliberately module-level, NOT part of `session` below: `session` is
-- fully rebuilt by BR.Start()/FinishSession() on every restock click, but a
-- rejection the server just confirmed doesn't forget that fact just
-- because the player stopped and restarted the button — if it did, every
-- fresh attempt would re-hit the exact same rejection at full pace instead
-- of ever accumulating enough confirmed failures to trip the no-split
-- (whole-stack-only) fallback.
--
-- fails/lastFailAt/noSplit are keyed by ITEM ID, not bag:slot: repeated
-- testing showed a confirmed rejection on one bank slot is immediately
-- reproduced on a completely different slot holding the SAME item (e.g.
-- -1:7 rejected, then -1:8 for the identical item rejected right after) —
-- so whatever is refusing the split cares about the item, not the specific
-- slot. Tracking per-slot would make the engine "rediscover" the same
-- item-wide rejection separately for every slot before giving up on any of
-- them. A single confirmed (hard) rejection trips `noSplit` for the item
-- immediately (see MarkSplitFailed) — once that's set, every OTHER slot
-- holding the item automatically routes to a whole-stack-only pick via
-- Rules' isNoSplit checks, so no separate item-wide cooldown is needed (and
-- one would actively hurt: it would also block those safe whole-stack
-- picks for no reason). cooldownUntil only covers the exact slot that just
-- failed, so it isn't instantly re-picked before its own backoff opens.
--
-- Entries decay after SPLIT_FAIL_TTL seconds of inactivity so a stale
-- record can't wedge an item forever. Item-level noSplit/fails only clear
-- when a move actually PROVES splitting works again (result.wasSplit);
-- whole-stack withdraw/merge success must NOT clear noSplit — that was
-- the mana-potion regression where a successful whole pull re-enabled
-- split-merge on the next bank slot and hit the same rejection again.
local SPLIT_FAIL_TTL = 120
local SPLIT_FAIL_COOLDOWN_HARD = 6
local SPLIT_FAIL_COOLDOWN_SOFT = 2
local persistentSplitState = {
    fails = {},         -- itemKey -> confirmed/soft failure count
    lastFailAt = {},    -- itemKey -> GetTime() of the most recent failure
    noSplit = {},       -- itemKey -> true once fails crosses SPLIT_FAIL_LIMIT
    cooldownUntil = {}, -- slotKey -> GetTime() before this slot is reselected
}

local restockEventFrame = CreateFrame("Frame")
local playerBagSet = {}
local bankBagSet = {}
local bagRefreshPending = false

local UI_REFRESH_EVERY = 8
local PLACE_FAIL_COOLDOWN = 2
local AUTOMATION_QUIET_PULSE = 0.5

-- Throttles the [step] resolve/resolved debug lines (see FluxBankRestockDebug).

local session = {
    running = false,
    tasks = nil,
    activeTaskIndex = 1,
    stepsCompleted = 0,
    aborted = false,
    skipped = {},
    manualGraceTicks = 0,
    movesSinceUIRefresh = 0,
    taskProgress = nil,
    waitReason = nil,
    lastNotifyEntry = nil,
    lastSplitMeta = nil,
}

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

local StacksForTask

local function ResolveMaxStack(itemID, entry)
    itemID = tonumber(itemID)
    if not itemID then
        return 1
    end

    local reg = Registry()
    if reg and reg.GetItemMaxStack then
        local fromReg = tonumber(reg.GetItemMaxStack(itemID))
        if fromReg and fromReg > 0 then
            return fromReg
        end
    end

    local inv = Inv()
    if inv then
        local function scanBags(bagIDs)
            if not bagIDs then return nil end
            for _, bag in ipairs(bagIDs) do
                local slots = inv.GetContainerNumSlots(bag)
                for slot = 1, slots do
                    local info = inv.GetContainerItemInfo(bag, slot)
                    if info and info.itemID == itemID then
                        local ic = IC()
                        local live = ic and ic.GetStackSize(itemID)
                        if live and live > 0 then
                            return live
                        end
                    end
                end
            end
            return nil
        end
        local live = scanBags(inv.GetBagContainerIDs and inv.GetBagContainerIDs())
        if live and live > 0 then
            return live
        end
        local bank = Bank()
        if bank and bank.GetContainerIDs then
            live = scanBags(bank.GetContainerIDs())
            if live and live > 0 then
                return live
            end
        end
    end

    if entry and tonumber(entry.maxStack) and entry.maxStack > 0 then
        return entry.maxStack
    end

    local ic = IC()
    local fromIc = ic and ic.GetStackSize(itemID)
    if fromIc and fromIc > 0 then
        return fromIc
    end

    return 1
end

local function SlotKey(bag, slot)
    return tostring(bag) .. ":" .. tostring(slot)
end

local function MarkSlotCooldown(bag, slot, secs)
    local ledger = LedgerMod()
    if ledger and ledger.SetCooldown then
        ledger.SetCooldown(bag, slot, secs)
    end
end

local function MarkSkipped(st)
    if st then
        session.skipped[SlotKey(st.bag, st.slot)] = true
        local ledger = LedgerMod()
        if ledger and ledger.MarkSkipped then
            ledger.MarkSkipped(st.bag, st.slot)
        end
    end
end

local function Now()
    return GetTime and GetTime() or 0
end

--- The failure/no-split key: item-scoped whenever an itemID is known (see
--- the persistentSplitState comment above for why), falling back to the
--- slot key only for the rare case a stack object has no itemID yet.
local function FailKey(st)
    if not st then
        return nil
    end
    local itemID = tonumber(st.itemID)
    if itemID then
        return "item:" .. itemID
    end
    return SlotKey(st.bag, st.slot)
end

--- Lazily expire a stale persistent record (no failure in the last
--- SPLIT_FAIL_TTL seconds) so an item always gets a fresh chance
--- eventually, even if the bank layout changes across a long play session.
local function ExpirePersistentSplitState(key, now)
    local at = persistentSplitState.lastFailAt[key]
    if not at or (now - at) < SPLIT_FAIL_TTL then
        return false
    end
    persistentSplitState.fails[key] = nil
    persistentSplitState.lastFailAt[key] = nil
    persistentSplitState.noSplit[key] = nil
    return true
end

local function MarkSplitFailed(st, hardFail, deferItemNoSplit)
    if not st then
        return
    end
    local key = FailKey(st)
    if not key then
        return
    end
    local now = Now()
    local increment = hardFail and SPLIT_FAIL_LIMIT or 1
    local fails = (persistentSplitState.fails[key] or 0) + increment
    persistentSplitState.fails[key] = fails
    persistentSplitState.lastFailAt[key] = now
    local trippedNoSplit = fails >= SPLIT_FAIL_LIMIT
    if st.bag and st.slot and not trippedNoSplit then
        local cooldown = hardFail and SPLIT_FAIL_COOLDOWN_HARD or SPLIT_FAIL_COOLDOWN_SOFT
        persistentSplitState.cooldownUntil[SlotKey(st.bag, st.slot)] = now + cooldown
    end
    Dbg("split", "MarkSplitFailed %s fails=%d hard=%s defer=%s", key, fails, hardFail and "Y" or "N",
        deferItemNoSplit and "Y" or "N")
    if trippedNoSplit or (hardFail and not deferItemNoSplit) then
        persistentSplitState.noSplit[key] = true
        local d = _G.FluxBankRestockDebug
        local line = "no-split " .. key .. " (whole-stack only)"
        if d and d.PrintImportant then
            d.PrintImportant("step", line)
        else
            Dbg("step", line)
        end
    end
end

local function ClearSplitFailForSlot(bag, slot, itemID, splitWorked)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if bag and slot then
        local slotKey = SlotKey(bag, slot)
        persistentSplitState.cooldownUntil[slotKey] = nil
        if session.skipped then
            session.skipped[slotKey] = nil
        end
    end
    itemID = tonumber(itemID)
    if itemID and splitWorked then
        local key = "item:" .. itemID
        persistentSplitState.fails[key] = nil
        persistentSplitState.lastFailAt[key] = nil
        persistentSplitState.noSplit[key] = nil
    end
end

local function NoteBankSlotSuccess(bag, slot, itemID, splitWorked)
    local itemKey = itemID and ("item:" .. tonumber(itemID)) or nil
    local hadNoSplit = itemKey and persistentSplitState.noSplit[itemKey] == true
    ClearSplitFailForSlot(bag, slot, itemID, splitWorked)
    if hadNoSplit and not splitWorked then
        Dbg("split", "preserving no-split %s after whole-stack success", itemKey)
    end
end

local function SetLastOpKind(kind)
    session.lastOpKind = kind
end

--- True when `st` is flagged skipped for this session, or still inside its
--- post-failure per-slot reselect cooldown (see MarkSplitFailed).
local function IsSkipped(st)
    if not st or not st.bag or not st.slot then
        return false
    end
    local slotKey = SlotKey(st.bag, st.slot)
    if session.skipped[slotKey] == true then
        return true
    end
    local ledger = LedgerMod()
    if ledger and ledger.IsSelectable and not ledger.IsSelectable(st.bag, st.slot) then
        return true
    end
    local until_ = persistentSplitState.cooldownUntil[slotKey]
    if not until_ then
        return false
    end
    if Now() >= until_ then
        persistentSplitState.cooldownUntil[slotKey] = nil
        return false
    end
    return true
end

--- True when the server has confirmed it refuses to split this item
--- (repeated "Couldn't split those items", possibly across several
--- different bank slots holding it). Such an item is still usable for a
--- whole-stack move, just never for a partial split. Persists across
--- BR.Start()/FinishSession() restarts (see persistentSplitState above) so
--- repeated manual restarts don't reset the failure count to zero every
--- time; it only clears on a confirmed SPLIT success for that item
--- (result.wasSplit) or after SPLIT_FAIL_TTL seconds of no further failures.
local function IsNoSplit(st)
    local key = FailKey(st)
    if not key or not persistentSplitState.noSplit[key] then
        return false
    end
    if ExpirePersistentSplitState(key, Now()) then
        return false
    end
    return true
end

--- Planner hook: treat only hard no-split items as non-splittable for planning.
local function IsNoSplitForPlanning(st)
    return IsNoSplit(st)
end

--- Count bank stacks still eligible for merge (not skipped/cooldown), optionally
--- excluding one slot that just failed a split.
local function CountEligibleMergeStacks(entry, excludeBag, excludeSlot)
    local stacks = StacksForTask(entry)
    local n = 0
    excludeBag = tonumber(excludeBag)
    excludeSlot = tonumber(excludeSlot)
    for _, st in ipairs(stacks or {}) do
        if st.bag and st.slot and not IsSkipped(st) then
            if not (excludeBag and excludeSlot and st.bag == excludeBag and st.slot == excludeSlot) then
                if (tonumber(st.count) or 0) > 0 then
                    n = n + 1
                end
            end
        end
    end
    return n
end

local function ClearSkips()
    wipe(session.skipped)
    local ledger = LedgerMod()
    if ledger and ledger.WipeSkipped then
        ledger.WipeSkipped()
    end
end

--- Manual restock clears per-slot cooldowns so a fresh session can retry
--- other bank stacks; persistent item-level no-split is kept so planning
--- does not re-queue split_merge/split_withdraw for confirmed rejections.
local function ClearSplitBlocksForManualStart(tasks, isManual)
    if not isManual then
        return
    end
    wipe(persistentSplitState.cooldownUntil)
    for _, task in ipairs(tasks or {}) do
        local itemID = task.entry and tonumber(task.entry.itemID)
        if itemID then
            local key = "item:" .. itemID
            persistentSplitState.fails[key] = nil
            persistentSplitState.lastFailAt[key] = nil
            persistentSplitState.noSplit[key] = nil
        end
    end
end

local function SummarizeStacks(stacks, isSkippedFn)
    local total, locked, skipped, eligible = 0, 0, 0, 0
    for _, st in ipairs(stacks or {}) do
        total = total + 1
        if st.locked then
            locked = locked + 1
        end
        if isSkippedFn and isSkippedFn(st) then
            skipped = skipped + 1
        elseif not st.locked and (tonumber(st.count) or 0) > 0 then
            eligible = eligible + 1
        end
    end
    return total, locked, skipped, eligible
end

local InvalidateBurstCache
local SlotCharges
local FinishSession

local function RestockBankOpen()
    local bank = Bank()
    return bank and bank.IsOpen()
end

local function WakeEngine()
    if session.running and not RestockBankOpen() then
        BR.Stop()
        return
    end
    local moveExec = MoveExecMod()
    if moveExec and moveExec.IsActive and moveExec.IsActive() then
        if moveExec.Wake then
            moveExec.Wake()
        end
        return
    end
    local planExec = PlanExecutorMod()
    if planExec and planExec.IsRunning and planExec.IsRunning() then
        if planExec.Wake then
            planExec.Wake()
        end
        return
    end
    local engine = EngineMod()
    if engine and engine.Wake then
        engine.Wake()
    end
end

local function WakeMover()
    WakeEngine()
end

local function TiersMod()
    return _G.FluxRestockTiers
end

local function RebuildContainerBagSets()
    wipe(playerBagSet)
    wipe(bankBagSet)
    local inv = Inv()
    local bank = Bank()
    if inv and inv.GetBagContainerIDs then
        for _, bag in ipairs(inv.GetBagContainerIDs()) do
            playerBagSet[bag] = true
        end
    end
    if bank and bank.GetContainerIDs then
        for _, bag in ipairs(bank.GetContainerIDs()) do
            bankBagSet[bag] = true
        end
    end
end

local function IsPlayerBag(bag)
    bag = tonumber(bag)
    return bag ~= nil and playerBagSet[bag] == true
end

local function MaybeRefreshBagsFromEvent()
    if not bagRefreshPending then
        return
    end
    bagRefreshPending = false
    local inv = Inv()
    if inv and inv.ForceRefreshBagCounts then
        inv.ForceRefreshBagCounts()
    end
    local tiers = TiersMod()
    if tiers and tiers.InvalidateTierQueryCache then
        tiers.InvalidateTierQueryCache()
    end
end

local function StartRestockEvents()
    RebuildContainerBagSets()
    restockEventFrame:RegisterEvent("BAG_UPDATE")
    pcall(function() restockEventFrame:RegisterEvent("BAG_UPDATE_DELAYED") end)
    pcall(function() restockEventFrame:RegisterEvent("ITEM_UNLOCKED") end)
    pcall(function() restockEventFrame:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED") end)
end

local function StopRestockEvents()
    restockEventFrame:UnregisterAllEvents()
    bagRefreshPending = false
    wipe(playerBagSet)
    wipe(bankBagSet)
end

local function GetCursorItemID()
    if not GetCursorInfo then
        return nil
    end
    local cursorType, itemID = GetCursorInfo()
    if cursorType == "item" then
        return tonumber(itemID)
    end
    return nil
end

local function EndSessionForManualCursor()
    session.aborted = true
    return true
end

local function PlayerIsManipulatingCursor()
    if IsMouseButtonDown and (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")) then
        return true
    end
    if IsModifiedClick and IsModifiedClick("SPLITSTACK") then
        return true
    end
    return false
end

local function ShouldAbortForManualCursor()
    if (session.manualGraceTicks or 0) > 0 then
        session.manualGraceTicks = session.manualGraceTicks - 1
        return false
    end
    return true
end

restockEventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if not session.running then
        return
    end
    if not RestockBankOpen() then
        BR.Stop()
        return
    end
    if event == "BAG_UPDATE_DELAYED" and IsPlayerBag(arg1) then
        bagRefreshPending = true
        InvalidateBurstCache()
        WakeEngine()
        local planExec = PlanExecutorMod()
        if planExec and planExec.IsRunning and planExec.IsRunning()
            and planExec.OnBagChanged then
            planExec.OnBagChanged(session)
        end
    elseif event == "BAG_UPDATE" and (IsPlayerBag(arg1) or bankBagSet[arg1]) then
        if IsPlayerBag(arg1) then
            bagRefreshPending = true
        end
        InvalidateBurstCache()
        WakeEngine()
        local planExec = PlanExecutorMod()
        if planExec and planExec.IsRunning and planExec.IsRunning()
            and planExec.OnBagChanged then
            planExec.OnBagChanged(session)
        end
    elseif event == "ITEM_UNLOCKED" then
        local bag, slot = arg1, arg2
        if bag and IsPlayerBag(bag) then
            bagRefreshPending = true
            local mover = Mover()
            if mover and mover.NudgeTailMerge then
                mover.NudgeTailMerge(bag, slot)
            end
            local inv = Inv()
            if inv and inv.ForceRefreshBagCounts then
                inv.ForceRefreshBagCounts()
            end
            local tiers = TiersMod()
            if tiers and tiers.InvalidateTierQueryCache then
                tiers.InvalidateTierQueryCache()
            end
            InvalidateBurstCache()
            WakeEngine()
            local planExec = PlanExecutorMod()
            if planExec and planExec.IsRunning and planExec.IsRunning()
                and planExec.OnBagChanged then
                planExec.OnBagChanged(session)
            end
        elseif bag and bankBagSet[bag] then
            Dbg("event", "ITEM_UNLOCKED bank bag=%s:%s", tostring(bag), tostring(slot))
            local mover = Mover()
            if mover and mover.NotePendingBankUnlocked then
                mover.NotePendingBankUnlocked(bag, slot)
            end
            InvalidateBurstCache()
            WakeEngine()
        end
    elseif event == "PLAYERBANKBAGSLOTS_CHANGED" then
        -- Classic: purchasing/equipping a bank bag changes available container IDs.
        local inv = Inv()
        if inv and inv.Containers and inv.Containers.Invalidate then
            inv.Containers.Invalidate()
        end
        RebuildContainerBagSets()
        InvalidateBurstCache()
        WakeEngine()
        local planExec = PlanExecutorMod()
        if planExec and planExec.IsRunning and planExec.IsRunning()
            and planExec.OnBagChanged then
            planExec.OnBagChanged(session)
        end
    end
end)

--- Best-effort hint for placing a cursor item the player is (or we are)
--- holding, based on the current active task's tier/item.
local function StrayCursorPlaceHint(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    local inv = Inv()
    local mover = Mover()
    if not inv or not mover then
        return nil
    end
    local bagIDs = inv.GetBagContainerIDs()
    if not bagIDs then
        return nil
    end
    local onCursor = mover.GetCursorItemCount and mover.GetCursorItemCount() or 1
    if onCursor <= 0 then
        onCursor = 1
    end
    local tierKind = nil
    local idx = session.activeTaskIndex or 1
    local activeTask = (session.tasks or {})[idx]
    if activeTask and activeTask.entry and activeTask.entry.tierKind then
        tierKind = activeTask.entry.tierKind
    end
    local maxStack = ResolveMaxStack(itemID, activeTask and activeTask.entry)
    local mergeBag, mergeSlot = nil, nil
    if mover.GetBestMergeTarget then
        mergeBag, mergeSlot = mover.GetBestMergeTarget(
            bagIDs, itemID, onCursor, maxStack, tierKind)
    end
    return {
        itemID = itemID,
        amount = onCursor,
        realMaxStack = maxStack,
        tierKind = tierKind,
        mergeBag = mergeBag,
        mergeSlot = mergeSlot,
    }
end

--- One-shot attempt to place whatever is currently on the cursor (never our
--- own action's cursor — Mover always owns that lifecycle itself). Returns
--- the amount placed, or 0 if it's still stuck on the cursor.
local function TryPlaceHeldCursor(itemID)
    local mover = Mover()
    if not mover or not mover.CursorHasItem or not mover.CursorHasItem() then
        return 0
    end
    itemID = tonumber(itemID) or GetCursorItemID()
    if not itemID then
        return 0
    end
    local hint = StrayCursorPlaceHint(itemID)
    local maxStack = (hint and hint.realMaxStack) or ResolveMaxStack(itemID, nil)
    local onCursor = mover.GetCursorItemCount and mover.GetCursorItemCount() or 1
    if onCursor <= 0 then
        onCursor = 1
    end
    local tierKind = hint and hint.tierKind
    local mergeBag = hint and tonumber(hint.mergeBag)
    local mergeSlot = hint and tonumber(hint.mergeSlot)

    if mover.PlaceCursorInPlayerBags and mergeBag and mergeSlot then
        if mover.PlaceCursorInPlayerBags(itemID, onCursor, maxStack, "mergeOnly", mergeBag, mergeSlot, tierKind)
            and not mover.CursorHasItem() then
            return onCursor
        end
    end
    if mover.PutItemInPlayerBag
        and mover.PutItemInPlayerBag(itemID, onCursor, maxStack, tierKind, mergeBag, mergeSlot)
        and not mover.CursorHasItem() then
        return onCursor
    end

    if not mover.CursorHasItem() then
        return onCursor
    end
    return 0
end

local function TaskCacheKey(task)
    local entry = task and task.entry
    if not entry then
        return nil
    end
    if entry.isTierBankEntry and entry.tierKind then
        return "tier:" .. tostring(entry.tierKind)
    end
    return "item:" .. tostring(entry.itemID)
end

InvalidateBurstCache = function()
end


local function RefreshTaskCaches()
    local inv = Inv()
    if inv and inv.ForceRefreshBagCounts then
        inv.ForceRefreshBagCounts()
    end
    local tiers = TiersMod()
    if tiers and tiers.InvalidateTierQueryCache then
        tiers.InvalidateTierQueryCache()
    end
end

--- Lightweight in-session refresh: incremental bank/bag dirty tracking via
--- BAG_UPDATE (FluxInv) — avoids full rescans on every move.
local function RefreshTaskCachesLive()
    MaybeRefreshBagsFromEvent()
    local bank = Bank()
    if bank and bank.IsOpen() and bank.RefreshIfOpen then
        bank.RefreshIfOpen()
    end
    local tiers = TiersMod()
    if tiers and tiers.InvalidateTierQueryCache then
        tiers.InvalidateTierQueryCache()
    end
end

local function RefreshTaskCachesFull()
    local bank = Bank()
    if bank and bank.IsOpen() then
        if bank.RequestLiveRefresh then
            bank.RequestLiveRefresh()
        elseif bank.RefreshIfOpen then
            bank.RefreshIfOpen()
        end
    end
    RefreshTaskCaches()
end

local function BumpUIRefresh(force)
    session.movesSinceUIRefresh = (session.movesSinceUIRefresh or 0) + 1
    if force or session.movesSinceUIRefresh >= UI_REFRESH_EVERY then
        session.movesSinceUIRefresh = 0
        BR.RunFastButtonRefresh()
        BR.RunLiveButtonRefresh()
    end
end

local function ExtendAutomationQuiet()
    local inv = Inv()
    if inv and inv.NotifyAutomationPulse then
        inv.NotifyAutomationPulse(AUTOMATION_QUIET_PULSE)
    end
end

local function NotifyAfterMove(entry)
    if not entry or not entry.tierKind then
        return
    end
    local tiers = TiersMod()
    if tiers and tiers.InvalidateTierQueryCache then
        tiers.InvalidateTierQueryCache()
    end
end

local function flushPendingBankRefresh(sess)
    sess = sess or session
    if not sess or not sess.burstBankRefreshPending then
        return
    end
    local bank = Bank()
    if bank and bank.IsOpen() and bank.RefreshIfOpen then
        bank.RefreshIfOpen()
    end
    sess.burstBankRefreshPending = nil
    sess.burstDirtyBank = nil
end

local function FlushBurstSideEffects(sess, opts)
    opts = type(opts) == "table" and opts or {}
    sess = sess or session
    if not sess then
        return
    end
    if opts.flushPendingBank then
        flushPendingBankRefresh(sess)
    end
    if sess.burstDirtyPlayer then
        local inv = Inv()
        if inv and inv.ForceRefreshBagCounts then
            inv.ForceRefreshBagCounts()
        end
        sess.burstDirtyPlayer = nil
    end
    if sess.burstDirtyBank then
        if opts.deferBankRefresh then
            sess.burstBankRefreshPending = true
        else
            local bank = Bank()
            if bank and bank.IsOpen() and bank.RefreshIfOpen then
                bank.RefreshIfOpen()
            end
            sess.burstDirtyBank = nil
            sess.burstBankRefreshPending = nil
        end
    end
    if sess.burstTierDirty then
        local tiers = TiersMod()
        if tiers and tiers.InvalidateTierQueryCache then
            tiers.InvalidateTierQueryCache()
        end
        sess.burstTierDirty = nil
    end
    if sess.burstHadMoves then
        BumpUIRefresh(true)
        sess.burstHadMoves = nil
    end
end

-- ---------------------------------------------------------------------------
-- SETTINGS
-- ---------------------------------------------------------------------------

function BR.IsAutoEnabled()
    return Settings().autoBankRestock == true
end

function BR.SetAutoEnabled(enabled)
    Settings().autoBankRestock = enabled and true or false
end

function BR.IsRunning()
    return session.running
end

-- ---------------------------------------------------------------------------
-- COUNTS
-- ---------------------------------------------------------------------------

local function EntryCountBankEnabled(entry)
    if not entry then return false end
    if entry.tierKind then
        local T = TiersMod()
        return T and T.GetCountBankFlag and T.GetCountBankFlag(entry.tierKind) or false
    end
    local s = Settings()
    local data = s.restockItems and s.restockItems[entry.itemID]
    return type(data) == "table" and data.countBank == true
end

local function TierCountFor(kind)
    local T = TiersMod()
    if not kind or not T then
        return 0
    end
    if T.GetTierBagTotalForBankRestock then
        return tonumber(T.GetTierBagTotalForBankRestock(kind)) or 0
    end
    if T.GetTierCount then
        return tonumber(T.GetTierCount(kind)) or 0
    end
    return 0
end

local function LiveBagCountForItem(itemID, charges)
    local inv = Inv()
    itemID = tonumber(itemID)
    if not itemID or not inv then
        return 0
    end
    local opts = {
        bags = true,
        bank = false,
        warband = false,
        charges = charges and true or false,
    }
    if inv.GetLiveCount then
        local n = tonumber(inv.GetLiveCount(itemID, opts)) or 0
        if n > 0 then
            return n
        end
    end
    local Item = _G.Flux and _G.Flux.Item
    if Item and Item.GetCount then
        local n = tonumber(Item.GetCount(itemID, false, charges and true or false, false, false)) or 0
        if n > 0 then
            return n
        end
    end
    if C_Item and C_Item.GetItemCount then
        local ok, raw = pcall(C_Item.GetItemCount, itemID, false, charges and true or false, false, false)
        if ok then
            local n = tonumber(raw) or 0
            if n > 0 then
                return n
            end
        end
    end
    return tonumber(inv.GetCount(itemID, opts)) or 0
end

local function BagCountFor(entry)
    if entry and entry.isTierBankEntry and entry.tierKind then
        return TierCountFor(entry.tierKind)
    end
    -- Live GetItemCount, not the Syndicator snapshot. Empty snapshots at bank
    -- open made need = full target on top of items already in bags.
    return LiveBagCountForItem(entry and entry.itemID, entry and entry.mode == "charge")
end

local function BankCountFor(entry)
    local bank = Bank()
    if not bank then return 0 end
    local itemID = entry.itemID
    if entry.mode == "charge" then
        return bank.GetCount(itemID, { charges = true })
    end
    return bank.GetCount(itemID)
end

local function EntryBankCountForDisplay(entry)
    if not entry or not EntryCountBankEnabled(entry) then
        return 0
    end
    if entry.tierKind then
        local T = TiersMod()
        return (T and T.GetBankCountForKind and T.GetBankCountForKind(entry.tierKind)) or 0
    end
    return BankCountFor(entry)
end

SlotCharges = function(bag, slot, fallback)
    local reg = Registry()
    if reg and reg.GetSlotCharges then
        local c = reg.GetSlotCharges(bag, slot)
        if c and c > 0 then
            return c
        end
    end
    return fallback or 1
end

local function GetMaxCharges(itemID)
    local reg = Registry()
    return reg and reg.GetItemMaxCharges and reg.GetItemMaxCharges(itemID)
end

StacksForTask = function(entry)
    local bank = Bank()
    if not bank then
        return {}
    end
    if entry and entry.isTierBankEntry and entry.tierKind then
        local T = TiersMod()
        if T and T.FindBankStacksForKind then
            return T.FindBankStacksForKind(entry.tierKind)
        end
        return {}
    end
    return bank.FindStacks(entry.itemID)
end

--- Plan-time bank stacks. Forces a live bank walk so replans (and a second
--- button press within the 0.2s Bank.Refresh throttle) never target slot/count
--- data left over from the previous session. Only the mover uses this;
--- tooltips and CanRunNow keep the throttled StacksForTask so bank open does
--- not pay for a walk per entry.
local function StacksForPlanning(entry)
    local bank = Bank()
    if not bank then
        return {}
    end
    if entry and entry.isTierBankEntry and entry.tierKind then
        -- Bump the bank generation so the tier kind→stacks index rebuilds
        -- instead of serving the previous session's slots.
        if bank.Refresh then
            bank.Refresh({ force = true })
        end
        return StacksForTask(entry)
    end
    return bank.FindStacks(entry and entry.itemID, { force = true }) or {}
end

--- Annotate stacks with charge counts and order fewest-charges-first.
local function DecorateChargeStacks(stacks, entry)
    if not entry or entry.mode ~= "charge" then
        return stacks
    end
    for _, st in ipairs(stacks) do
        st.charges = SlotCharges(st.bag, st.slot, st.count)
    end
    table.sort(stacks, function(a, b)
        local ca, cb = tonumber(a.charges) or 0, tonumber(b.charges) or 0
        if ca ~= cb then
            return ca < cb
        end
        if (a.bag or 0) ~= (b.bag or 0) then
            return (a.bag or 0) < (b.bag or 0)
        end
        return (a.slot or 0) < (b.slot or 0)
    end)
    return stacks
end

local function StacksForChargeTask(entry)
    return DecorateChargeStacks(StacksForTask(entry), entry)
end

local function StacksForChargePlanning(entry)
    return DecorateChargeStacks(StacksForPlanning(entry), entry)
end

local function LiveStackTotal(entry)
    local total = 0
    for _, st in ipairs(StacksForTask(entry)) do
        if not st.locked and not IsSkipped(st) then
            total = total + (tonumber(st.count) or 0)
        end
    end
    return total
end

local function BankAvailableForEntry(entry)
    if entry and entry.isTierBankEntry and entry.tierKind then
        local T = TiersMod()
        local kind = entry.tierKind
        -- Prefer O(1) aggregate counts for idle CanRun / tooltips.
        -- Stack scans (FindBankStacksForKind) are for move execution only.
        if T and T.GetBankCountForKind then
            return T.GetBankCountForKind(kind) or 0
        end
        if T and T.SumBankStacksForKind then
            return T.SumBankStacksForKind(kind) or 0
        end
        return 0
    end
    -- Aggregates from the last bank walk — do not FindStacks here (N full bank walks).
    return BankCountFor(entry)
end

local function TaskTargetFor(entry)
    if not entry then
        return 0
    end
    if entry.isTierBankEntry and entry.tierKind then
        local T = TiersMod()
        return T and T.GetTarget(entry.tierKind) or 0
    end
    return tonumber(entry.target) or 0
end

local function TaskProgressKey(task)
    local entry = task and task.entry
    if not entry then
        return nil
    end
    if entry.isTierBankEntry and entry.tierKind then
        return "tier:" .. tostring(entry.tierKind)
    end
    return "item:" .. tostring(entry.itemID)
end

local function TaskNeedRemaining(task)
    local entry = task and task.entry
    if not entry then
        return 0
    end
    local liveNeed = math.max(0, TaskTargetFor(entry) - BagCountFor(entry))
    if entry.isTierBankEntry and entry.tierKind then
        local cap = tonumber(entry.tierWithdraw)
        if cap and cap > 0 then
            liveNeed = math.min(liveNeed, cap)
        end
        local rem = tonumber(task.remaining)
        if session.running and rem ~= nil then
            return math.min(rem, liveNeed)
        end
        return liveNeed
    end
    return liveNeed
end

local function TaskPlanRemaining(task)
    return TaskNeedRemaining(task)
end

local function LedgerReserve(bag, slot, info)
    local ledger = LedgerMod()
    if ledger and ledger.Reserve then
        ledger.Reserve(bag, slot, info)
    end
end

local function LedgerConfirm(bag, slot)
    local ledger = LedgerMod()
    if ledger and ledger.Confirm then
        ledger.Confirm(bag, slot)
    end
end

local function LedgerRelease(bag, slot, reason, cooldownSecs)
    local ledger = LedgerMod()
    if ledger and ledger.Release then
        ledger.Release(bag, slot, reason, cooldownSecs)
    elseif ledger and ledger.SetCooldown and bag and slot then
        ledger.SetCooldown(bag, slot, cooldownSecs or PLACE_FAIL_COOLDOWN)
    end
end

local function CreditTaskWithdraw(task, moved)
    moved = tonumber(moved) or 0
    if not task or moved <= 0 or not session.running then
        return
    end
    local entry = task.entry
    if entry and entry.isTierBankEntry and entry.tierKind then
        local rem = tonumber(task.remaining)
        if rem == nil then
            rem = TaskNeedRemaining(task)
        end
        task.remaining = math.max(0, rem - moved)
    else
        task.remaining = TaskNeedRemaining(task)
    end
    task.withdraw = task.remaining
end

local function NoteTaskProgress(task, moved)
    moved = tonumber(moved) or 0
    if not task then
        return
    end
    if moved > 0 then
        CreditTaskWithdraw(task, moved)
    end
    local key = TaskProgressKey(task)
    if not key then
        return
    end
    session.taskProgress = session.taskProgress or {}
    local rem = TaskNeedRemaining(task)
    local prog = session.taskProgress[key]
    if not prog then
        prog = { lastRemaining = rem, stall = 0 }
        session.taskProgress[key] = prog
    end
    if moved > 0 or rem < (prog.lastRemaining or rem) then
        prog.stall = 0
        task._preferWithdraw = nil
        task._bulkSplitFailed = nil
        local d = _G.FluxBankRestockDebug
        if d and d.PrintImportant then
            d.PrintImportant("progress", "progress %s rem %s->%s moved=%s",
                key, tostring(prog.lastRemaining), tostring(rem), tostring(moved))
        else
            Dbg("progress", "progress %s rem %s->%s moved=%s stall reset",
                key, tostring(prog.lastRemaining), tostring(rem), tostring(moved))
        end
    elseif rem == prog.lastRemaining then
        prog.stall = (prog.stall or 0) + 1
        if prog.stall >= TASK_PROGRESS_STALL_LIMIT then
            task._preferWithdraw = true
            local d = _G.FluxBankRestockDebug
            if d and d.PrintImportant then
                d.PrintImportant("progress", "progress %s preferWithdraw=ON (stall=%d)", key, prog.stall)
            end
        end
    end
    prog.lastRemaining = rem
end

local function TaskIsComplete(task)
    return TaskNeedRemaining(task) <= 0
end

local function GetActiveTask()
    local tasks = session.tasks or {}
    local idx = session.activeTaskIndex or 1
    while idx <= #tasks do
        local task = tasks[idx]
        if task and not TaskIsComplete(task) then
            session.activeTaskIndex = idx
            return task
        end
        idx = idx + 1
    end
    session.activeTaskIndex = #tasks + 1
    return nil
end

local function AdvanceActiveTaskIfComplete(task)
    if not task or not TaskIsComplete(task) then
        return false
    end
    local tasks = session.tasks or {}
    local idx = session.activeTaskIndex or 1
    if tasks[idx] ~= task then
        return false
    end
    session.activeTaskIndex = idx + 1
    session.replanAttempts = 0
    session.moveFailRetries = 0
    session.blockedTaskIdx = nil
    session.blockedCount = 0
    return true
end

local function ReconcileTasks()
    for _, task in ipairs(session.tasks or {}) do
        task.remaining = TaskNeedRemaining(task)
    end
end

local function MaxStackFor(entry)
    if not entry then
        return 1
    end
    return ResolveMaxStack(entry.itemID, entry)
end

local TIER_KIND_ORDER = {
    food = 1,
    water = 2,
    bandage = 3,
    healPotion = 4,
    manaPotion = 5,
}

local function TierKindSortOrder(kind)
    return TIER_KIND_ORDER[kind] or 50
end

local function SortRestockTasks(tasks)
    table.sort(tasks, function(a, b)
        local ae = a.entry
        local be = b.entry
        local ka = (ae and ae.isTierBankEntry and ae.tierKind) and TierKindSortOrder(ae.tierKind) or 100
        local kb = (be and be.isTierBankEntry and be.tierKind) and TierKindSortOrder(be.tierKind) or 100
        if ka ~= kb then
            return ka < kb
        end
        if ae and ae.isTierBankEntry and be and be.isTierBankEntry then
            local ta = tonumber(ae.tierWithdraw) or 0
            local tb = tonumber(be.tierWithdraw) or 0
            if ta ~= tb then
                return ta < tb
            end
        end
        return (tonumber(ae and ae.itemID) or 0) < (tonumber(be and be.itemID) or 0)
    end)
end

local function EntryCoveredByActiveTier(entry, tierKindsActive, T)
    if not entry or entry.isTierBankEntry or not entry.itemID or not T or not tierKindsActive then
        return false
    end
    for kind in pairs(tierKindsActive) do
        if T.ItemMatchesRestockKind then
            if T.ItemMatchesRestockKind(kind, entry.itemID) then
                return true
            end
        elseif T.GetItemTierValue and (T.GetItemTierValue(kind, entry.itemID) or 0) > 0 then
            return true
        end
    end
    return false
end

local function BuildTasks()
    local reg = Registry()
    local rules = Rules()
    if not reg or not rules then return {} end
    local bank = Bank()
    if bank and bank.RefreshIfOpen then
        bank.RefreshIfOpen()
    end
    local tasks = {}
    local tierKindSeen = {}
    local tierKindsActive = {}
    for _, entry in ipairs(reg.GetBankTargetList()) do
        if entry.isTierBankEntry and entry.tierKind then
            tierKindsActive[entry.tierKind] = true
        end
    end
    local T = TiersMod()
    for _, entry in ipairs(reg.GetBankTargetList()) do
        if entry.isTierBankEntry and entry.tierKind then
            if not tierKindSeen[entry.tierKind] then
                tierKindSeen[entry.tierKind] = true
                local bagCount = BagCountFor(entry)
                local bankAvail = BankAvailableForEntry(entry)
                local withdraw = rules.ComputeWithdrawTarget(entry, bagCount, bankAvail)
                if withdraw > 0 then
                    tasks[#tasks + 1] = {
                        entry = entry,
                        itemID = entry.itemID,
                        mode = entry.mode or "stack",
                        maxStack = MaxStackFor(entry),
                        withdraw = withdraw,
                        remaining = withdraw,
                    }
                end
            end
        else
            local coveredByTier = EntryCoveredByActiveTier(entry, tierKindsActive, T)
            if not coveredByTier then
                local bagCount = BagCountFor(entry)
                local bankAvail = BankAvailableForEntry(entry)
                local withdraw = rules.ComputeWithdrawTarget(entry, bagCount, bankAvail)
                if withdraw > 0 then
                    tasks[#tasks + 1] = {
                        entry = entry,
                        itemID = entry.itemID,
                        mode = entry.mode or "stack",
                        maxStack = MaxStackFor(entry),
                        withdraw = withdraw,
                        remaining = withdraw,
                    }
                end
            end
        end
    end
    SortRestockTasks(tasks)
    return tasks
end

local function PlayerSnapForTask(task)
    local inv = Inv()
    local invMod = Inventory()
    local entry = task and task.entry
    if not inv or not invMod or not entry then
        return { summary = {}, slots = {} }
    end
    local bagIDs = inv.GetBagContainerIDs and inv.GetBagContainerIDs()
    local matchFn
    if entry.isTierBankEntry and entry.tierKind then
        matchFn = invMod.MatchTierKind(entry.tierKind)
    else
        matchFn = invMod.MatchItemID(entry.itemID)
    end
    return invMod.SnapshotPlayerBags(bagIDs, matchFn, function(itemID)
        return ResolveMaxStack(itemID, entry)
    end)
end

local function SessionNeedsMoreWork()
    for _, task in ipairs(session.tasks or {}) do
        if TaskNeedRemaining(task) > 0 and BankAvailableForEntry(task.entry) > 0 then
            return true
        end
    end
    return false
end

local function ClearStaleInFlight()
    local ledger = LedgerMod()
    if ledger and ledger.ClearStale then
        ledger.ClearStale(5)
    end
end

local function BuildStepContext(task)
    local StepContext = _G.FluxBankRestockStepContext
    local inv = Inv()
    local mover = Mover()
    local invMod = Inventory()
    local entry = task and task.entry
    local bagIDs = inv and inv.GetBagContainerIDs and inv.GetBagContainerIDs()
    local remaining = TaskNeedRemaining(task)
    local tierKind = entry and entry.isTierBankEntry and entry.tierKind or nil
    local maxStack = tonumber(task.maxStack) or MaxStackFor(entry)
    local bagCount = BagCountFor(entry)
    local target = TaskTargetFor(entry)

    local function isInFlight(st)
        if not st then
            return false
        end
        local ledger = LedgerMod()
        if ledger and ledger.IsReserved and ledger.IsReserved(st.bag, st.slot) then
            return true
        end
        return false
    end

    if not StepContext or not StepContext.Build then
        return {
            task = task,
            entry = entry,
            inv = inv,
            remaining = remaining,
            bagCount = bagCount,
            target = target,
            stacks = (entry and entry.mode == "charge") and StacksForChargeTask(entry) or StacksForTask(entry),
            tierKind = tierKind,
            itemID = entry and entry.itemID,
            maxStack = maxStack,
            resolveMaxStack = ResolveMaxStack,
            isSkipped = function(st)
                return IsSkipped(st) or isInFlight(st)
            end,
            isNoSplit = IsNoSplitForPlanning,
            mode = task.mode or (entry and entry.mode) or "stack",
            preferWithdraw = task._preferWithdraw == true,
            bagIDs = bagIDs,
            playerSnap = PlayerSnapForTask(task),
        }
    end

    return StepContext.Build({
        task = task,
        entry = entry,
        inv = inv,
        remaining = remaining,
        bagCount = bagCount,
        target = target,
        stacks = (entry and entry.mode == "charge") and StacksForChargeTask(entry) or StacksForTask(entry),
        tierKind = tierKind,
        itemID = entry and entry.itemID,
        maxStack = maxStack,
        resolveMaxStack = ResolveMaxStack,
        isSkipped = function(st)
            return IsSkipped(st) or isInFlight(st)
        end,
        isNoSplit = IsNoSplitForPlanning,
        mode = task.mode or (entry and entry.mode) or "stack",
        preferWithdraw = task._preferWithdraw == true,
        bagIDs = bagIDs,
        playerSnap = PlayerSnapForTask(task),
        getMaxCharges = function(itemID)
            return GetMaxCharges(itemID)
        end,
        enrichChargeStacks = function(stacks)
            for _, st in ipairs(stacks or {}) do
                st.charges = SlotCharges(st.bag, st.slot, st.count)
            end
        end,
        getMergeTarget = function(id, stepCap, ms, tk)
            if not mover or not mover.GetBestMergeTarget or not bagIDs then
                return nil, nil, 0, nil
            end
            local mergeBag, mergeSlot, mergeRoom, mergeRoomFull = mover.GetBestMergeTarget(
                bagIDs, id, stepCap, ms, tk)
            local mergeItemID = id
            if mergeBag and mergeSlot and inv then
                local info = inv.GetContainerItemInfo(mergeBag, mergeSlot)
                mergeItemID = info and info.itemID or id
            end
            return mergeBag, mergeSlot, mergeRoom, mergeRoomFull, mergeItemID
        end,
        getMaxPlaceable = function(want, id, ms, tk)
            if not mover or not mover.GetMaxPlaceableAmount or not bagIDs then
                return 0
            end
            return mover.GetMaxPlaceableAmount(bagIDs, id, want, ms, tk)
        end,
        canPlace = function(id, amount, ms, tk)
            if not mover or not mover.CanPlaceAmount or not bagIDs then
                return false
            end
            return mover.CanPlaceAmount(bagIDs, id, amount, ms, tk)
        end,
        hasEmptyBagSlot = function()
            return invMod and invMod.HasEmptyBagSlot and invMod.HasEmptyBagSlot(bagIDs)
        end,
        getTotalMergeRoom = function(id, ms, tk)
            if not mover or not mover.GetTotalMergeRoom or not bagIDs then
                return 0
            end
            return mover.GetTotalMergeRoom(bagIDs, id, ms, tk)
        end,
        getPreferredEmptySlot = function(id, tk)
            if not mover or not bagIDs then
                return nil, nil
            end
            if mover.FindFirstEmptyBagSlot then
                return mover.FindFirstEmptyBagSlot(bagIDs)
            end
            if mover.FindConsolidatedEmptySlot then
                return mover.FindConsolidatedEmptySlot(bagIDs, id, tk)
            end
            return nil, nil
        end,
    })
end

local bankModulesConfigured = false
local function ConfigureBankModules()
    if bankModulesConfigured then
        return
    end
    bankModulesConfigured = true
    local engine = EngineMod()
    if not engine or not engine.Configure then
        return
    end
    local sharedDeps = {
        session = session,
        Inv = Inv,
        Bank = Bank,
        Dbg = Dbg,
        DbgImportant = DbgImportant,
        Rules = Rules,
        Planner = Planner,
        Executor = ExecutorMod,
        BuildStepContext = BuildStepContext,
        TaskNeedRemaining = TaskNeedRemaining,
        TaskTargetFor = TaskTargetFor,
        BagCountFor = BagCountFor,
        ForceRefreshCaches = RefreshTaskCachesLive,
        SessionNeedsMoreWork = SessionNeedsMoreWork,
        ReconcileTasks = ReconcileTasks,
        ClearStaleInFlight = ClearStaleInFlight,
        MaybeRefreshBagsFromEvent = MaybeRefreshBagsFromEvent,
        RefreshTaskCaches = RefreshTaskCachesLive,
        BumpUIRefresh = BumpUIRefresh,
        NotifyAfterMove = NotifyAfterMove,
        ResolveMaxStack = ResolveMaxStack,
        SlotCharges = SlotCharges,
        GetMaxCharges = GetMaxCharges,
        MarkSplitFailed = MarkSplitFailed,
        MarkSlotCooldown = MarkSlotCooldown,
        NoteBankSlotSuccess = NoteBankSlotSuccess,
        NoteTaskProgress = NoteTaskProgress,
        LedgerReserve = LedgerReserve,
        LedgerConfirm = LedgerConfirm,
        LedgerRelease = LedgerRelease,
        BankAvailableForEntry = BankAvailableForEntry,
        LiveStackTotal = LiveStackTotal,
        IsNoSplit = IsNoSplit,
        IsNoSplitForPlanning = IsNoSplitForPlanning,
        CountEligibleMergeStacks = CountEligibleMergeStacks,
        PlanExecutor = PlanExecutorMod,
        ExtendAutomationQuiet = ExtendAutomationQuiet,
        ConfigureBankModules = ConfigureBankModules,
        FinishSession = function(reason)
            FinishSession(reason)
        end,
    }
    engine.Configure(sharedDeps)
    local planExec = PlanExecutorMod()
    if planExec and planExec.Configure then
        local inv = Inv()
        local bank = Bank()
        local lockContainers = {}
        if inv and inv.GetBagContainerIDs then
            for _, bag in ipairs(inv.GetBagContainerIDs()) do
                lockContainers[#lockContainers + 1] = bag
            end
        end
        if bank and bank.GetContainerIDs then
            for _, bag in ipairs(bank.GetContainerIDs()) do
                lockContainers[#lockContainers + 1] = bag
            end
        end
        planExec.Configure({
            session = session,
            Inv = Inv,
            Bank = Bank,
            Dbg = Dbg,
            DbgImportant = DbgImportant,
            Rules = Rules,
            Planner = Planner,
            Engine = EngineMod,
            Ledger = LedgerMod,
            TaskNeedRemaining = TaskNeedRemaining,
            TaskTargetFor = TaskTargetFor,
            BagCountFor = BagCountFor,
            SessionNeedsMoreWork = SessionNeedsMoreWork,
            ClearStaleInFlight = ClearStaleInFlight,
            MaybeRefreshBagsFromEvent = MaybeRefreshBagsFromEvent,
            BumpUIRefresh = BumpUIRefresh,
            NotifyAfterMove = NotifyAfterMove,
            NoteTaskProgress = NoteTaskProgress,
            LedgerReserve = LedgerReserve,
            LedgerConfirm = LedgerConfirm,
            LedgerRelease = LedgerRelease,
            ResolveMaxStack = ResolveMaxStack,
            SlotCharges = SlotCharges,
            GetMaxCharges = GetMaxCharges,
            IsNoSplit = IsNoSplit,
            Executor = ExecutorMod,
            NoteBankSlotSuccess = NoteBankSlotSuccess,
            MarkSplitFailed = MarkSplitFailed,
            MarkSlotCooldown = MarkSlotCooldown,
            ForceRefreshCaches = RefreshTaskCachesLive,
            ExtendAutomationQuiet = ExtendAutomationQuiet,
            ConfigureBankModules = ConfigureBankModules,
            FlushBurstSideEffects = FlushBurstSideEffects,
            FinishSession = function(reason)
                FinishSession(reason)
            end,
        })
    end
end

local function BuildPlannerContext()
    local planner = Planner()
    if not planner or not planner.BuildPlannerContext then
        return nil
    end
    local inv = Inv()
    local bank = Bank()
    return planner.BuildPlannerContext({
        inv = inv,
        bank = bank,
        bagIDs = inv and inv.GetBagContainerIDs and inv.GetBagContainerIDs(),
        bankBagIDs = bank and bank.GetContainerIDs and bank.GetContainerIDs(),
        resolveMaxStack = ResolveMaxStack,
        getSlotCharges = SlotCharges,
        getMaxCharges = GetMaxCharges,
        tiersMod = TiersMod(),
        rules = Rules(),
        isNoSplit = IsNoSplitForPlanning,
    })
end

local function BuildSessionPlan(tasks)
    local planner = Planner()
    if not planner or not planner.BuildSessionPlan then
        return nil, {}
    end
    local pctx = BuildPlannerContext()
    if not pctx then
        return nil, {}
    end
    planner.BuildSessionPlan(tasks, pctx)
    local valid, reason = true, nil
    if planner.ValidateSessionPlan then
        valid, reason = planner.ValidateSessionPlan(tasks, pctx)
    end
    if not valid then
        DbgImportant("plan", "ValidateSessionPlan failed: %s", tostring(reason))
        for _, task in ipairs(tasks) do
            task.plannedMoves = nil
            task.planIndex = nil
        end
        return pctx, {}
    end
    local queue = planner.FlattenMoveQueue and planner.FlattenMoveQueue(tasks, pctx) or {}
    return pctx, queue
end

local function StartRestockEngine()
    local moveExec = MoveExecMod()
    if not moveExec or not moveExec.Start then
        DbgImportant("session", "MoveExec missing — cannot start")
        return
    end
    local ok = moveExec.Start(session, {
        resolveMaxStack = ResolveMaxStack,
        stacksForTask = StacksForPlanning,
        stacksForCharge = StacksForChargePlanning,
        playerSnapForTask = PlayerSnapForTask,
        getSlotCharges = SlotCharges,
        onDone = function(reason)
            if session.running then
                FinishSession(reason or "done")
            end
        end,
    })
    if ok then
        DbgImportant("session", "MoveExec started")
    else
        DbgImportant("session", "MoveExec nothing to do")
        FinishSession("empty")
    end
end


-- ---------------------------------------------------------------------------
-- SESSION END
-- ---------------------------------------------------------------------------

local sessionEndCallbacks = {}

function BR.RegisterSessionEndCallback(fn)
    if type(fn) == "function" then
        sessionEndCallbacks[#sessionEndCallbacks + 1] = fn
    end
end

local function FireSessionEndCallbacks()
    for i = 1, #sessionEndCallbacks do
        pcall(sessionEndCallbacks[i])
    end
end

local finishSessionRunning = false
local postSessionRefreshPending = false

local function RunPostSessionRefresh(includePanel)
    postSessionRefreshPending = false
    RefreshTaskCaches()
    BR.RunFastButtonRefresh()
    BR.RunLiveButtonRefresh()
    if includePanel and _G.FluxRestockPanel_RefreshCellData then
        pcall(_G.FluxRestockPanel_RefreshCellData)
    end
end

local function SchedulePostSessionRefresh(reason)
    if postSessionRefreshPending then
        return
    end
    postSessionRefreshPending = true
    local deferPanel = (reason == "bank_close")
    After(deferPanel and 0.12 or 0, function()
        RunPostSessionRefresh(not deferPanel)
    end)
end

FinishSession = function(reason)
    if finishSessionRunning then
        return
    end
    finishSessionRunning = true
    local moveExec = MoveExecMod()
    if moveExec and moveExec.Stop then
        moveExec.Stop()
    end
    local planExec = PlanExecutorMod()
    if planExec and planExec.Stop then
        planExec.Stop()
    end
    local mover = Mover()
    if mover and mover.FlushAction then
        mover.FlushAction()
    end
    local engine = EngineMod()
    if engine and engine.Stop then
        engine.Stop()
    end
    if mover then
        if mover.CancelAction then
            mover.CancelAction()
        end
        if mover.Stop then
            mover.Stop({ clearCursor = true, fireOnDone = false })
        end
        if mover.ClearCursor then
            mover.ClearCursor()
        end
    end
    FlushBurstSideEffects(session, { flushPendingBank = true })
    DbgImportant("session", "FinishSession steps=%s aborted=%s reason=%s",
        tostring(session.stepsCompleted or 0), tostring(session.aborted), tostring(reason or "?"))
    session.running = false
    session.tasks = nil
    session.activeTaskIndex = 1
    session.stepsCompleted = 0
    session.aborted = false
    session.waitReason = nil
    session.lastNotifyEntry = nil
    session.lastSplitMeta = nil
    session.planQueue = nil
    session.planIndex = nil
    session.inFlight = nil
    session.usePlanExecutor = nil
    session.usePlanQueue = nil
    session.useMoveExec = nil
    session.fallbackActive = nil
    session.deferredMoves = nil
    session.plannerCtx = nil
    local ledger = LedgerMod()
    if ledger and ledger.Reset then
        ledger.Reset()
    end
    session.manual = false
    ClearSkips()
    StopRestockEvents()
    FireSessionEndCallbacks()
    -- Bank close runs FlushDeferredScans on the next frame; defer UI work so
    -- we don't stack full rescans + panel refresh on the same frame.
    if reason == "bank_close" then
        SchedulePostSessionRefresh(reason)
    else
        local bank = Bank()
        if bank and bank.IsOpen() and bank.SchedulePersist then
            bank.SchedulePersist()
        end
        SchedulePostSessionRefresh(reason)
    end
    finishSessionRunning = false
end

-- ---------------------------------------------------------------------------
-- PUBLIC CONTROL
-- ---------------------------------------------------------------------------

local function HasUnifiedBankUI()
    local api = _G.FLUX_API
    return api and api.HasUnifiedBankUI and api.HasUnifiedBankUI()
end

local startDeferred = false

function BR.Start(isManual)
    local inv = Inv()
    local bank = Bank()
    local moves = MovesMod()
    if not inv or not bank or not bank.IsLive or not bank.IsLive() then
        return false
    end
    if not MoveExecMod() then
        DbgImportant("session", "MoveExec not loaded")
        return false
    end
    if session.running then
        session.aborted = true
        FinishSession()
    end

    -- Every press starts from a clean planner/exec state: no banned merge items,
    -- reserved destinations or give-up flags carried over from the last run.
    local moveExec = MoveExecMod()
    if moveExec and moveExec.Reset then
        moveExec.Reset()
    end

    local reg = Registry()
    if reg and reg.InvalidateBankTargetsCache then
        reg.InvalidateBankTargetsCache()
    end

    RefreshTaskCachesFull()
    if inv.Containers and inv.Containers.Invalidate then
        inv.Containers.Invalidate()
    end
    if bank.Refresh then
        bank.Refresh({ force = true })
    end
    local tasks = BuildTasks()
    if #tasks == 0 then
        return false
    end

    -- Manual start clears stale split cooldowns; new path does not soft-ban items.
    ClearSplitBlocksForManualStart(tasks, isManual)
    wipe(persistentSplitState.noSplit)
    wipe(persistentSplitState.fails)
    wipe(persistentSplitState.lastFailAt)
    wipe(persistentSplitState.cooldownUntil)
    session.manual = isManual and true or false

    session.running = true
    session.tasks = tasks
    DbgImportant("session", "Start manual=%s tasks=%d", tostring(isManual and true or false), #tasks)
    session.aborted = false
    session.movesSinceUIRefresh = 0
    session.activeTaskIndex = 1
    session.stepsCompleted = 0
    session.waitReason = nil
    session.lastNotifyEntry = nil
    session.lastSplitMeta = nil
    local ledger = LedgerMod()
    if ledger and ledger.Reset then
        ledger.Reset()
    end
    ClearSkips()
    if moves and moves.ClearCursor then
        moves.ClearCursor()
    end
    local mover = Mover()
    if mover and mover.ClearCursor then
        mover.ClearCursor()
    end
    ExtendAutomationQuiet()

    session.plannerCtx = nil
    session.planQueue = nil
    session.planIndex = 1
    session.inFlight = {}
    session.usePlanExecutor = false
    session.usePlanQueue = false
    session.useMoveExec = true
    session.fallbackActive = false
    session.deferredMoves = nil

    StartRestockEvents()
    StartRestockEngine()
    BR.RunFastButtonRefresh()
    return true
end

function BR.Stop(reason)
    if not session.running then
        return
    end
    session.aborted = true
    local moveExec = MoveExecMod()
    if moveExec and moveExec.Stop then
        moveExec.Stop()
    end
    local planExec = PlanExecutorMod()
    if planExec and planExec.Stop then
        planExec.Stop()
    end
    local engine = EngineMod()
    if engine and engine.Stop then
        engine.Stop()
    end
    FinishSession(reason or "stop")
end

function BR.RunManual()
    if startDeferred then
        return false
    end
    if not BR.CanRunNow() then
        return false
    end
    if HasUnifiedBankUI() then
        startDeferred = true
        After(0.05, function()
            startDeferred = false
            BR.Start(true)
            BR.RunFastButtonRefresh()
        end)
        return true
    end
    return BR.Start(true)
end

-- ---------------------------------------------------------------------------
-- SUMMARY / TOOLTIP / PROGRESS
-- ---------------------------------------------------------------------------

local canRunCache = {
    bagGen = nil,
    bankGen = nil,
    pull = nil,
    canRun = false,
}
local canRunFillGen = 0

local function GetInventoryGens()
    local bagGen, bankGen = 0, 0
    local inv = Inv()
    if inv and inv.Bags and inv.Bags.GetGeneration then
        bagGen = inv.Bags.GetGeneration() or 0
    end
    local bank = Bank()
    if bank and bank.GetGeneration then
        bankGen = bank.GetGeneration() or 0
    end
    return bagGen, bankGen
end

local function BankIsLive()
    local bank = Bank()
    return bank and bank.IsLive and bank.IsLive() or false
end

local function CacheHit(bagGen, bankGen)
    if canRunCache.pull == nil then
        return false
    end
    if canRunCache.bagGen ~= bagGen or canRunCache.bankGen ~= bankGen then
        return false
    end
    if canRunCache.pull == 0 and BankIsLive() then
        local bank = Bank()
        -- Recompute only until the first live C_Container walk finishes.
        if not (bank and bank._liveWalked) then
            return false
        end
    end
    return true
end

local function ScheduleCanRunCacheFill()
    canRunFillGen = canRunFillGen + 1
    local gen = canRunFillGen
    local inv = Inv()
    -- Aggregates are cheap now; only defer a frame while bank is open so we
    -- do not compete with Blizzard/Baganator bank layout on the open tick.
    local delay = 0
    if inv and inv.IsBankOpen and inv.IsBankOpen() then
        delay = 0.05
    end
    After(delay, function()
        if gen ~= canRunFillGen then
            return
        end
        if not BankIsLive() then
            return
        end
        BR.CanRunNow()
        BR.RunFastButtonRefresh()
    end)
end

function BR.GetPendingSummary()
    local bagGen, bankGen = GetInventoryGens()
    if CacheHit(bagGen, bankGen) then
        return canRunCache.pull
    end
    local reg = Registry()
    local rules = Rules()
    if not reg or not rules then return 0 end
    local pull = 0
    local seenTierKinds = {}
    local tierKindsActive = {}
    local list = reg.GetBankTargetList()
    for _, entry in ipairs(list) do
        if entry.isTierBankEntry and entry.tierKind then
            tierKindsActive[entry.tierKind] = true
        end
    end
    local T = TiersMod()
    for _, entry in ipairs(list) do
        local skip = false
        if entry.isTierBankEntry and entry.tierKind then
            if seenTierKinds[entry.tierKind] then
                skip = true
            else
                seenTierKinds[entry.tierKind] = true
            end
        elseif EntryCoveredByActiveTier(entry, tierKindsActive, T) then
            skip = true
        end
        if not skip then
            local bagCount = BagCountFor(entry)
            local bankAvail = BankAvailableForEntry(entry)
            pull = pull + rules.ComputeWithdrawTarget(entry, bagCount, bankAvail)
        end
    end
    canRunCache.bagGen = bagGen
    canRunCache.bankGen = bankGen
    canRunCache.pull = pull
    canRunCache.canRun = pull > 0
    return pull
end

function BR.CanRunNow()
    local bank = Bank()
    if not bank or not bank.IsLive or not bank.IsLive() then
        return false
    end
    return BR.GetPendingSummary() > 0
end

--- Cache-hit path for button attach / idle paint. On miss, fill from aggregates
--- (cheap) and return; avoid nested deferred timers that stacked to ~1s hitches.
function BR.GetCachedCanRunNow()
    local bank = Bank()
    if not bank or not bank.IsLive or not bank.IsLive() then
        return false
    end
    local bagGen, bankGen = GetInventoryGens()
    if CacheHit(bagGen, bankGen) then
        return canRunCache.canRun
    end
    return BR.CanRunNow()
end

function BR.InvalidateCanRunCache()
    canRunCache.bagGen = nil
    canRunCache.bankGen = nil
    canRunCache.pull = nil
    -- Keep canRunCache.canRun as last-known so idle paint does not flicker
    -- disabled→enabled while a deferred fill recomputes.
end

function BR.GetProgress()
    if not session.running then
        return nil
    end
    local total = #(session.tasks or {})
    local current = math.max(0, (session.activeTaskIndex or 1) - 1)
    return {
        current = current,
        total = total,
        items = session.stepsCompleted or 0,
        steps = session.stepsCompleted or 0,
    }
end

function BR.GetTooltipItems()
    local reg = Registry()
    local rules = Rules()
    local ic = IC()
    if not reg or not rules then return {} end
    local out = {}
    for _, entry in ipairs(reg.GetBankTargetList()) do
        local bagCount = BagCountFor(entry)
        local bankAvail = BankAvailableForEntry(entry)
        local target = entry.target or 0
        if entry.isTierBankEntry and entry.tierKind then
            local T = TiersMod()
            target = (T and T.GetTarget and T.GetTarget(entry.tierKind)) or target
        end
        local countBank = EntryCountBankEnabled(entry)
        local bankCountDisplay = EntryBankCountForDisplay(entry)
        local combinedHave = countBank and (bagCount + bankCountDisplay) or bagCount
        local needed = math.max(0, target - combinedHave)
        local pull = rules.ComputeWithdrawTarget(entry, bagCount, bankAvail)
        out[#out + 1] = {
            itemID = entry.itemID,
            name = (ic and ic.GetName(entry.itemID)) or ("Item " .. tostring(entry.itemID)),
            texture = ic and ic.GetIcon(entry.itemID) or nil,
            bagCount = bagCount,
            bankCount = bankCountDisplay,
            countBank = countBank,
            target = target,
            needed = needed,
            pull = pull,
            restock = entry.restock ~= false,
            tierKind = entry.tierKind,
        }
    end
    table.sort(out, function(a, b)
        return (a.name or "") < (b.name or "")
    end)
    return out
end

function BR.RunFastButtonRefresh()
    local btn = _G.FluxBankRestockButton
    if btn and btn.RefreshIdle then
        pcall(btn.RefreshIdle)
    end
end

local idleButtonRefreshGen = 0
local IDLE_BUTTON_REFRESH_DELAY = 0.2
local IDLE_BUTTON_REFRESH_DELAY_BANK = 0.35

local function ScheduleIdleButtonRefresh()
    idleButtonRefreshGen = idleButtonRefreshGen + 1
    local gen = idleButtonRefreshGen
    local inv = Inv()
    local bank = Bank()
    if not bank or not bank.IsOpen() then
        return
    end
    local delay = IDLE_BUTTON_REFRESH_DELAY
    if inv and inv.IsBankOpen and inv.IsBankOpen() then
        delay = IDLE_BUTTON_REFRESH_DELAY_BANK
    end
    After(delay, function()
        if gen ~= idleButtonRefreshGen then
            return
        end
        local bankNow = Bank()
        if not bankNow or not bankNow.IsOpen() then
            return
        end
        -- Fill can-run in this same deferred tick (no nested 0.55s timer).
        BR.InvalidateCanRunCache()
        BR.CanRunNow()
        BR.RunFastButtonRefresh()
    end)
end
BR.ScheduleIdleButtonRefresh = ScheduleIdleButtonRefresh

--- Cancel pending idle CanRun / button refresh timers (bank close).
function BR.CancelIdleCanRunWork()
    canRunFillGen = canRunFillGen + 1
    idleButtonRefreshGen = idleButtonRefreshGen + 1
end

local liveRefreshPending = false
function BR.RunLiveButtonRefresh()
    if liveRefreshPending then return end
    liveRefreshPending = true
    After(0.1, function()
        liveRefreshPending = false
        local btn = _G.FluxBankRestockButton
        if btn and btn.RefreshLive then
            pcall(btn.RefreshLive)
        end
    end)
end

-- ---------------------------------------------------------------------------
-- LIFECYCLE
-- ---------------------------------------------------------------------------

local function OnBankOpen()
    After(0.35, function()
        local bank = Bank()
        if not bank or not bank.IsOpen() then return end
        BR.CanRunNow()
        BR.RunFastButtonRefresh()
    end)
    After(0.6, function()
        local bank = Bank()
        if not bank or not bank.IsOpen() then return end
        BR.CanRunNow()
        BR.RunFastButtonRefresh()
        if not BR.IsAutoEnabled() then return end
        if IsShiftKeyDown and IsShiftKeyDown() then return end
        local mover = Mover()
        if mover and mover.CursorHasItem and mover.CursorHasItem() then return end
        if not session.running then
            BR.Start(false)
        end
    end)
end

local function OnBankClose()
    if session.running then
        BR.Stop("bank_close")
    end
    if BR.CancelIdleCanRunWork then
        BR.CancelIdleCanRunWork()
    end
    BR.InvalidateCanRunCache()
end

local errFrame = CreateFrame("Frame")
pcall(function() errFrame:RegisterEvent("UI_ERROR_MESSAGE") end)
errFrame:SetScript("OnEvent", function(_, _, arg1, arg2)
    if not session.running then return end
    local msg = tostring(arg2 or arg1 or "")
    if msg:lower():find("split", 1, true) then
        DbgImportant("event", "UI_ERROR: %s", msg)
        local moveExec = MoveExecMod()
        if moveExec and moveExec.OnSplitRejected then
            moveExec.OnSplitRejected()
        end
        WakeEngine()
    end
    if msg == ERR_INV_FULL or msg == ERR_BANK_FULL or msg == ERR_ITEM_MAX_COUNT then
        DbgImportant("event", "UI_ERROR stop session: %s", msg)
        BR.Stop()
    end
end)

local function RegisterLifecycle()
    local bank = Bank()
    if bank and not BR._lifecycleRegistered then
        BR._lifecycleRegistered = true
        bank.RegisterBankOpen("FluxBankRestock", OnBankOpen)
        bank.RegisterBankClose("FluxBankRestock", OnBankClose)
    end
end
RegisterLifecycle()

local restockInv = Inv()
if restockInv and restockInv.RegisterListener then
    restockInv.RegisterListener("BankSlots_FluxBankRestockIdle", function(ctx)
        if session.running then
            return
        end
        local bank = Bank()
        if not bank or not bank.IsOpen() then
            return
        end
        local regions = ctx and ctx.regions
        if not regions or not (regions.bank or regions.warband or regions.bags) then
            return
        end
        if BR.InvalidateCanRunCache then
            BR.InvalidateCanRunCache()
        end
        BR.ScheduleIdleButtonRefresh()
    end, { tier = "scan", regions = { "bags", "bank", "warband" }, deferHeavy = true })
end

--- Offline smoke test for MovePlan destination rules (no live bags required).
--- Usage: /run FluxBankRestock.RunMovePlanSmokeTest()
function BR.RunMovePlanSmokeTest()
    local plan = _G.FluxBankRestockMovePlan
    local need = _G.FluxBankRestockNeed
    local ctx = _G.FluxBankRestockMoveContext
    if not plan or not need then
        print("FluxBankRestock: MovePlan/Need not loaded")
        return false
    end
    local passed, failed = 0, 0
    local function check(name, cond)
        if cond then
            passed = passed + 1
            print("|cff00ff00PASS|r " .. name)
        else
            failed = failed + 1
            print("|cffff0000FAIL|r " .. name)
        end
    end

    -- Mock: need 8 of item 28103; bank stack 20; bag partial count 2 max 20 → merge dest.
    local task = {
        entry = { itemID = 28103, mode = "stack", target = 10 },
        itemID = 28103,
        mode = "stack",
        maxStack = 20,
        withdraw = 8,
        remaining = 8,
    }
    local needs = need.BuildFromTasks({ task })
    check("need map size", #needs == 1 and needs[1].remaining == 8)

    local moves = plan.Build(needs, {
        resolveMaxStack = function() return 20 end,
        stacksForTask = function()
            return { { bag = -1, slot = 4, count = 20, locked = false, itemID = 28103 } }
        end,
        playerSnapForTask = function()
            return {
                slots = {
                    ["28103"] = { { bag = 1, slot = 4, count = 2, itemID = 28103 } },
                },
            }
        end,
    })
    check("split_merge onto partial", #moves == 1
        and moves[1].kind == "split_place"
        and moves[1].qty == 8
        and moves[1].toBag == 1 and moves[1].toSlot == 4
        and moves[1].destKind == "merge"
        and moves[1].endQty == 12)

    -- Whole stack fits need → whole UseContainerItem, no dest required.
    task.remaining = 20
    task.withdraw = 20
    needs = need.BuildFromTasks({ task })
    moves = plan.Build(needs, {
        resolveMaxStack = function() return 20 end,
        stacksForTask = function()
            return { { bag = -1, slot = 1, count = 20, locked = false, itemID = 28103 } }
        end,
        playerSnapForTask = function()
            return { slots = {} }
        end,
    })
    check("whole withdraw", #moves == 1 and moves[1].kind == "whole" and moves[1].qty == 20)

    -- Partial need, bag full of that item, no empties → no move.
    task.remaining = 5
    task.withdraw = 5
    needs = need.BuildFromTasks({ task })
    moves = plan.Build(needs, {
        resolveMaxStack = function() return 20 end,
        emptySlots = {},
        stacksForTask = function()
            return { { bag = -1, slot = 2, count = 20, locked = false, itemID = 28103 } }
        end,
        playerSnapForTask = function()
            return {
                slots = {
                    ["28103"] = { { bag = 1, slot = 1, count = 20, itemID = 28103 } },
                },
            }
        end,
    })
    check("no_target when full", #moves == 0)

    -- Split to empty slot when no fitting partial.
    task.remaining = 5
    needs = need.BuildFromTasks({ task })
    moves = plan.Build(needs, {
        resolveMaxStack = function() return 20 end,
        emptySlots = { { bag = 0, slot = 1 } },
        stacksForTask = function()
            return { { bag = -1, slot = 3, count = 20, locked = false, itemID = 28103 } }
        end,
        playerSnapForTask = function()
            return { slots = {} }
        end,
    })
    check("split to empty", #moves == 1
        and moves[1].kind == "split_place"
        and moves[1].destKind == "empty"
        and moves[1].toBag == 0 and moves[1].toSlot == 1)

    -- Target 30 / max 20 / bags 9 / bank 20+20: fill 11 onto the 9, then 10
    -- to empty. Never whole-20 followed by a leftover-1 split onto the 9.
    task.remaining = 21
    task.withdraw = 21
    needs = need.BuildFromTasks({ task })
    moves = plan.Build(needs, {
        resolveMaxStack = function() return 20 end,
        emptySlots = { { bag = 0, slot = 1 } },
        stacksForTask = function()
            return {
                { bag = -1, slot = 1, count = 20, locked = false, itemID = 28103 },
                { bag = -1, slot = 2, count = 20, locked = false, itemID = 28103 },
            }
        end,
        playerSnapForTask = function()
            return {
                slots = {
                    ["28103"] = { { bag = 1, slot = 1, count = 9, itemID = 28103 } },
                },
            }
        end,
    })
    check("bags 9 need 21: fill 11 then split 10 (no leftover-1)",
        #moves == 2
        and moves[1].kind == "split_place" and moves[1].qty == 11
        and moves[1].destKind == "merge" and moves[1].toBag == 1 and moves[1].toSlot == 1
        and moves[2].kind == "split_place" and moves[2].qty == 10
        and moves[2].destKind == "empty"
        and moves[1].kind ~= "whole" and moves[2].kind ~= "whole")

    -- Only one bank 20 cannot cover fill-11 + leftover 10; take the whole 20.
    moves = plan.Build(needs, {
        resolveMaxStack = function() return 20 end,
        emptySlots = { { bag = 0, slot = 1 } },
        stacksForTask = function()
            return { { bag = -1, slot = 1, count = 20, locked = false, itemID = 28103 } }
        end,
        playerSnapForTask = function()
            return {
                slots = {
                    ["28103"] = { { bag = 1, slot = 1, count = 9, itemID = 28103 } },
                },
            }
        end,
    })
    check("bags 9 need 21 single 20: whole 20, no stranded fill",
        #moves == 1 and moves[1].kind == "whole" and moves[1].qty == 20)

    -- Bank 11 + 20: directed 11 onto the 9, then 10 from the 20.
    moves = plan.Build(needs, {
        resolveMaxStack = function() return 20 end,
        emptySlots = { { bag = 0, slot = 1 } },
        stacksForTask = function()
            return {
                { bag = -1, slot = 1, count = 11, locked = false, itemID = 28103 },
                { bag = -1, slot = 2, count = 20, locked = false, itemID = 28103 },
            }
        end,
        playerSnapForTask = function()
            return {
                slots = {
                    ["28103"] = { { bag = 1, slot = 1, count = 9, itemID = 28103 } },
                },
            }
        end,
    })
    check("bags 9 need 21: exact 11 fills 9, then split 10",
        #moves == 2
        and moves[1].kind == "split_place" and moves[1].qty == 11
        and moves[1].destKind == "merge" and moves[1].endQty == 0
        and moves[2].kind == "split_place" and moves[2].qty == 10
        and moves[2].destKind == "empty")

    -- Legitimate leftover-1: bags 19, need exactly 1.
    task.remaining = 1
    task.withdraw = 1
    needs = need.BuildFromTasks({ task })
    moves = plan.Build(needs, {
        resolveMaxStack = function() return 20 end,
        emptySlots = { { bag = 0, slot = 1 } },
        stacksForTask = function()
            return { { bag = -1, slot = 1, count = 20, locked = false, itemID = 28103 } }
        end,
        playerSnapForTask = function()
            return {
                slots = {
                    ["28103"] = { { bag = 1, slot = 1, count = 19, itemID = 28103 } },
                },
            }
        end,
    })
    check("need 1 onto 19: split 1 merge",
        #moves == 1
        and moves[1].kind == "split_place" and moves[1].qty == 1
        and moves[1].destKind == "merge")

    -- A bank slot the client has not finished resolving (still locked from the
    -- previous session) must never be planned against.
    task.remaining = 5
    task.withdraw = 5
    needs = need.BuildFromTasks({ task })
    local lockedStats
    moves, lockedStats = plan.Build(needs, {
        resolveMaxStack = function() return 20 end,
        emptySlots = { { bag = 0, slot = 1 } },
        stacksForTask = function()
            return { { bag = -1, slot = 1, count = 20, locked = true, itemID = 28103 } }
        end,
        playerSnapForTask = function()
            return { slots = {} }
        end,
    })
    check("locked bank stack is skipped",
        #moves == 0 and lockedStats and lockedStats.locked >= 1)

    -- Same need, one locked stack and one free stack: use the free one only.
    moves = plan.Build(needs, {
        resolveMaxStack = function() return 20 end,
        emptySlots = { { bag = 0, slot = 1 } },
        stacksForTask = function()
            return {
                { bag = -1, slot = 1, count = 20, locked = true, itemID = 28103 },
                { bag = -1, slot = 2, count = 20, locked = false, itemID = 28103 },
            }
        end,
        playerSnapForTask = function()
            return { slots = {} }
        end,
    })
    check("locked stack skipped, free stack used",
        #moves == 1 and moves[1].fromSlot == 2 and moves[1].qty == 5)

    check("MoveContext Place", ctx and type(ctx.Place) == "function")
    check("MoveContext SourceAcked", ctx and type(ctx.SourceAcked) == "function")
    check("MoveExec loaded", _G.FluxBankRestockMoveExec and type(_G.FluxBankRestockMoveExec.Start) == "function")
    check("MoveExec no SplitPlace burst API", not (ctx and ctx.SplitPlace))

    print(string.format("FluxBankRestock MovePlan smoke: %d passed, %d failed", passed, failed))
    return failed == 0, passed, failed
end

--- Run offline regression sims; prints results to chat. Usage: /run FluxBankRestock.RunSimRegression()
function BR.RunSimRegression()
    if BR.RunMovePlanSmokeTest then
        BR.RunMovePlanSmokeTest()
    end
    local planner = Planner()
    if not planner or not planner.RunRegressionSims then
        print("FluxBankRestock: legacy planner sims not loaded (expected after rewrite)")
        return 0, 0
    end
    local passed, failed, lines
    if planner.RunAllSims then
        passed, failed, lines = planner.RunAllSims()
    else
        passed, failed, lines = planner.RunRegressionSims()
    end
    print(string.format("FluxBankRestock sim: %d passed, %d failed", passed, failed))
    for _, line in ipairs(lines or {}) do
        print(line)
    end
    return passed, failed
end

BR.RunRegressionSims = BR.RunSimRegression

function BR.IsDebug()
    local d = _G.FluxBankRestockDebug
    return d and d.IsEnabled and d.IsEnabled() or false
end

function BR.SetDebug(enabled)
    local d = _G.FluxBankRestockDebug
    if d and d.SetEnabled then
        d.SetEnabled(enabled)
    end
end

function BR.DebugDumpSession()
    local d = _G.FluxBankRestockDebug
    if d and d.DumpSession then
        d.DumpSession(session)
    end
end

function BR.Debug(cat, fmt, ...)
    Dbg(cat, fmt, ...)
end

_G.FluxBankRestock = BR
return BR
