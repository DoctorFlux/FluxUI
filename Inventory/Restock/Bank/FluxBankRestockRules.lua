--[[
    Restock/Bank/FluxBankRestockRules.lua

    Pure withdrawal decision rules for the bank restock engine.

    Stack withdraw algorithm (ResolveNextStep — one move per call):
      remaining = target - live bag count
      stepCap = min(remaining, maxStack)

      1. Merge-first when bags have no empty slots, remaining fits in merge room
         (tail fill), or remaining exceeds merge room but cannot be placed in one
         clean step to an empty slot. When empty bag space exists and the full
         remaining need (up to stepCap) fits in one placement, prefer that single
         withdraw over topping off partials first (avoids fragmented 7+3 pulls).
      2. Otherwise prefer whole stacks that fill bag slots efficiently: max-stack
         pulls first when empty slots exist, then largest whole stack that fits,
         then split from the smallest bank stack that can supply the step.

    PickStackWithdrawStack returns the authoritative pull amount per step.
]]

FluxBankRestockRules = FluxBankRestockRules or {}
local Rules = FluxBankRestockRules

local function tierStackMatches(kind, itemID)
    kind = kind and tostring(kind) or nil
    itemID = tonumber(itemID)
    if not kind or not itemID then
        return false
    end
    local T = _G.FluxRestockTiers
    if T and T.StackMatchesBankRestockKind then
        return T.StackMatchesBankRestockKind(kind, itemID)
    end
    if T and T.GetItemTierValue then
        return (T.GetItemTierValue(kind, itemID) or 0) > 0
    end
    return false
end

function Rules.ComputeWithdrawTarget(entry, bagCount, bankAvailable, opts)
    opts = type(opts) == "table" and opts or nil
    bagCount = tonumber(bagCount) or 0
    bankAvailable = tonumber(bankAvailable) or 0
    if bankAvailable <= 0 or entry.restock == false then
        return 0
    end

    if entry.isTierBankEntry then
        local T = _G.FluxRestockTiers
        local kindTarget = 0
        if entry.tierKind and T and T.GetTarget then
            kindTarget = tonumber(T.GetTarget(entry.tierKind)) or 0
        end
        if kindTarget <= 0 then
            return 0
        end
        local kindHave = tonumber(bagCount) or 0
        if kindHave >= kindTarget then
            return 0
        end
        local tierNeed = kindTarget - kindHave
        local cap = tonumber(entry.tierWithdraw)
        if cap and cap > 0 then
            tierNeed = math.min(tierNeed, cap)
        end
        return math.min(tierNeed, bankAvailable)
    end

    local target = tonumber(entry.target) or 0
    if target <= bagCount then
        return 0
    end
    local need = target - bagCount

    if entry.mode == "charge" then
        return need
    end

    return math.min(need, bankAvailable)
end

--- How many items to pull from a bank slot this move, and whether to split.
--- `want` is the task's live remaining need (never exceed this).
function Rules.ComputeWithdrawAmount(want, maxStack, liveCount)
    want = tonumber(want) or 0
    maxStack = tonumber(maxStack) or want
    liveCount = tonumber(liveCount) or 0
    if want <= 0 or liveCount <= 0 or maxStack <= 0 then
        return 0, false
    end

    local pull = math.min(want, maxStack)
    if liveCount <= pull then
        return liveCount, false
    end

    return pull, true
end

--- Final withdraw amount for execution (never whole bank stack when pull < liveCount).
function Rules.ResolveWithdrawAmount(want, maxStack, liveCount)
    return Rules.ComputeWithdrawAmount(want, maxStack, liveCount)
end

--- Highest allowed charge total when a whole stack must be taken (target + maxCharges - 1).
function Rules.GetChargeMaxAllowed(target, maxCharges)
    target = tonumber(target) or 0
    maxCharges = tonumber(maxCharges) or 1
    return target + math.max(0, maxCharges - 1)
end

--- True when withdrawing a whole charge stack would exceed the allowed overshoot cap.
function Rules.ChargeWithdrawWouldOvershoot(bagCount, target, stackCharges, maxCharges)
    bagCount = tonumber(bagCount) or 0
    target = tonumber(target) or 0
    stackCharges = tonumber(stackCharges) or 0
    if stackCharges <= 0 then
        return true
    end
    local maxAllowed = Rules.GetChargeMaxAllowed(target, maxCharges)
    if bagCount >= maxAllowed then
        return true
    end
    return (bagCount + stackCharges) > maxAllowed
end

--- Always pick the bank stack with the fewest remaining charges (ties: bag/slot order).
function Rules.PickChargeWithdrawStack(stacks, isSkipped, opts)
    opts = type(opts) == "table" and opts or {}
    local bagCount = tonumber(opts.bagCount) or 0
    local target = tonumber(opts.target) or 0
    local maxCharges = tonumber(opts.maxCharges) or 999
    local best
    for _, st in ipairs(stacks or {}) do
        if not st.locked and not (isSkipped and isSkipped(st)) then
            local charges = tonumber(st.charges) or 0
            if charges > 0 then
                if Rules.ChargeWithdrawWouldOvershoot(bagCount, target, charges, maxCharges) then
                    -- skip stacks that would blow past the single-stack overshoot cap
                elseif not best
                    or charges < (tonumber(best.charges) or 0)
                    or (charges == (tonumber(best.charges) or 0)
                        and ((st.bag or 0) < (best.bag or 0)
                            or ((st.bag or 0) == (best.bag or 0) and (st.slot or 0) < (best.slot or 0)))) then
                    best = st
                end
            end
        end
    end
    return best
end

--- Item-wide no-split flag (server confirmed split rejection for this itemID).
local function itemIsNoSplit(st, itemID, isNoSplit)
    if not isNoSplit then
        return false
    end
    if st and isNoSplit(st) then
        return true
    end
    itemID = tonumber(itemID)
    if itemID and isNoSplit({ itemID = itemID }) then
        return true
    end
    return false
end

--- True when any bank stack can supply a merge step without requiring split.
--- No-split items only count stacks whose whole count fits merge room, unless
--- overlayTail (need fits in merge room — whole-stack overlay clip-merge).
function Rules.HasMergeBankSupply(stacks, mergeRoom, mergeItemID, tierKind, isSkipped, isNoSplit, overlayTail)
    mergeRoom = tonumber(mergeRoom) or 0
    if mergeRoom <= 0 then
        return false
    end
    mergeItemID = tonumber(mergeItemID)
    overlayTail = overlayTail == true
    for _, st in ipairs(stacks or {}) do
        if st and not st.locked and not (isSkipped and isSkipped(st)) then
            local count = tonumber(st.count) or 0
            if count > 0 then
                local matches = false
                if mergeItemID then
                    matches = st.itemID == mergeItemID
                elseif tierKind then
                    matches = tierStackMatches(tierKind, st.itemID)
                else
                    matches = true
                end
                if matches then
                    if itemIsNoSplit(st, st.itemID, isNoSplit) then
                        if count <= mergeRoom then
                            return true
                        end
                    else
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function sortStacksByCountAsc(stacks)
    table.sort(stacks, function(a, b)
        local ca, cb = tonumber(a.count) or 0, tonumber(b.count) or 0
        if ca ~= cb then
            return ca < cb
        end
        if (a.itemID or 0) ~= (b.itemID or 0) then
            return (a.itemID or 0) < (b.itemID or 0)
        end
        return (a.slot or 0) < (b.slot or 0)
    end)
end

--- Splitting a single item off a larger stack is fragile in the client, but
--- required for tail fills (need exactly 1 more to hit target).
local function splitAmountViable(amt, liveCount, needWant)
    amt = tonumber(amt) or 0
    liveCount = tonumber(liveCount) or 0
    needWant = tonumber(needWant) or 0
    if amt <= 0 or liveCount <= 0 then
        return false
    end
    if amt >= liveCount then
        return false
    end
    if amt == 1 and liveCount > 1 then
        return needWant == 1
    end
    return true
end

--- Bank stacks eligible to fund a merge into a specific target slot. Same
--- exact-item-first rule as HasMergeBankSupply above: once the target
--- slot's real occupant (mergeItemID) is known, only THAT exact item can
--- ever be picked up and merged into it — a tier match alone is never
--- enough, since two different itemIDs can't share one stack. Falls back
--- to tier-wide matching only when mergeItemID isn't known yet.
local function buildMergePool(pool, mergeItemID, tierKind, mergeRoom, isNoSplit)
    mergeRoom = tonumber(mergeRoom) or 0
    local mergePool = {}
    if mergeItemID then
        for _, st in ipairs(pool) do
            if (tonumber(st.itemID) or mergeItemID) == mergeItemID then
                mergePool[#mergePool + 1] = st
            end
        end
    elseif tierKind then
        for _, st in ipairs(pool) do
            if tierStackMatches(tierKind, st.itemID) then
                mergePool[#mergePool + 1] = st
            end
        end
    else
        for _, st in ipairs(pool) do
            mergePool[#mergePool + 1] = st
        end
    end
    return mergePool
end

--- Merge fill: exact whole stack, smallest whole under need, whole stack that
--- fits merge room, smallest whole that covers the gap, then split from smallest.
local function pickMergeSupplier(mergePool, needAmt, want, isNoSplit, mergeRoom, skipSplitRequired, allowStaging, mergeRoomFull)
    needAmt = tonumber(needAmt) or 0
    want = tonumber(want) or needAmt
    mergeRoom = tonumber(mergeRoom) or 0
    mergeRoomFull = tonumber(mergeRoomFull) or mergeRoom
    skipSplitRequired = skipSplitRequired == true
    allowStaging = allowStaging == true
    if needAmt <= 0 then
        return nil, 0
    end
    sortStacksByCountAsc(mergePool)
    for _, st in ipairs(mergePool) do
        local count = tonumber(st.count) or 0
        if count > 0 and count == needAmt then
            return st, math.min(count, want)
        end
    end
    for _, st in ipairs(mergePool) do
        local count = tonumber(st.count) or 0
        if count > 0 and count < needAmt then
            return st, math.min(count, want)
        end
    end
    -- Entire stack fits in the bag partial's real room — whole pickup (no split).
    if mergeRoomFull > 0 then
        for _, st in ipairs(mergePool) do
            local count = tonumber(st.count) or 0
            if itemIsNoSplit(st, st.itemID, isNoSplit) then
                local cap = math.min(needAmt, mergeRoomFull)
                if count > 0 and count <= cap then
                    return st, count
                end
            elseif count > needAmt and count <= mergeRoomFull then
                return st, count
            end
        end
    end
    -- Entire stack fits in capped merge step room.
    if mergeRoom > 0 then
        for _, st in ipairs(mergePool) do
            local count = tonumber(st.count) or 0
            if count > needAmt and count <= mergeRoom then
                return st, math.min(count, want)
            end
        end
    end
    if not skipSplitRequired then
        for _, st in ipairs(mergePool) do
            local count = tonumber(st.count) or 0
            if count > needAmt then
                if itemIsNoSplit(st, st.itemID, isNoSplit) then
                    if count <= mergeRoomFull or count == needAmt then
                        return st, count
                    end
                elseif splitAmountViable(needAmt, count, needAmt) then
                    return st, math.min(needAmt, want)
                end
            end
        end
    elseif allowStaging and mergeRoom > 0 then
        for _, st in ipairs(mergePool) do
            local count = tonumber(st.count) or 0
            if count > needAmt and count <= mergeRoom then
                return st, math.min(count, want)
            end
        end
    end
    -- Tail top-off: oversized bank stack when merge room matches need (split path in mover).
    if mergeRoom > 0 and needAmt == mergeRoom and not skipSplitRequired then
        local hasWholeFit = false
        for _, st in ipairs(mergePool) do
            local c = tonumber(st.count) or 0
            if c > needAmt and c <= mergeRoomFull then
                hasWholeFit = true
                break
            end
        end
        if not hasWholeFit then
            for _, st in ipairs(mergePool) do
                local count = tonumber(st.count) or 0
                if count > needAmt and not itemIsNoSplit(st, st.itemID, isNoSplit)
                    and splitAmountViable(needAmt, count, want) then
                    return st, math.min(needAmt, want)
                end
            end
        end
    end
    return nil, 0
end

--- Pick bank stack + amount for one withdraw step.
--- `want` = total items still needed. `take` = min(want, maxStack) this step.
--- `isNoSplit(st)` flags a slot the server has confirmed rejects splitting
--- (e.g. repeated "Couldn't split those items"); such a slot may still be
--- picked, but only for a whole-stack move that needs no split.
function Rules.PickStackWithdrawStack(stacks, want, isSkipped, maxStack, mergeRoom, mergeItemID, take, tierKind, isNoSplit, plainWithdrawFirst, preferMaxStacks, mergeSplitBlocked, allowMergeStaging, mergeRoomFull)
    want = tonumber(want) or 0
    maxStack = tonumber(maxStack) or want
    mergeRoom = tonumber(mergeRoom) or 0
    mergeRoomFull = tonumber(mergeRoomFull) or mergeRoom
    mergeItemID = tonumber(mergeItemID)
    take = tonumber(take) or math.min(want, maxStack)
    take = math.min(take, want, maxStack)

    mergeSplitBlocked = mergeSplitBlocked == true
    allowMergeStaging = allowMergeStaging == true

    if want <= 0 or maxStack <= 0 or take <= 0 then
        return nil, 0, false
    end

    local function eligible(st)
        return st and not st.locked and not (isSkipped and isSkipped(st))
            and (tonumber(st.count) or 0) > 0
    end

    local pool = {}
    for _, st in ipairs(stacks or {}) do
        if eligible(st) then
            pool[#pool + 1] = st
        end
    end
    if #pool == 0 then
        return nil, 0, false
    end
    sortStacksByCountAsc(pool)

    --- Smallest-first stack pick for a plain (non-merge) withdraw step.
    local function pickSmallest(poolIn, needWant, needTake)
        needWant = tonumber(needWant) or 0
        needTake = math.min(tonumber(needTake) or 0, needWant, maxStack)
        if needWant <= 0 or needTake <= 0 then
            return nil, 0
        end
        for _, st in ipairs(poolIn) do
            local count = tonumber(st.count) or 0
            if count > 0 and count <= needWant then
                return st, count
            end
        end
        -- Split from the smallest stack that can supply this step.
        for _, st in ipairs(poolIn) do
            local count = tonumber(st.count) or 0
            if count > needTake then
                if itemIsNoSplit(st, st.itemID, isNoSplit) then
                    if count <= needWant then
                        return st, count
                    end
                else
                    local amt = math.min(needTake, needWant)
                    if splitAmountViable(amt, count, needWant) then
                        return st, amt
                    end
                end
            end
        end
        return nil, 0
    end

    --- Prefer full maxStack-sized pulls, then the largest whole stack that fits.
    local function pickLargestWhole(poolIn, needWant)
        needWant = tonumber(needWant) or 0
        if needWant <= 0 then
            return nil, 0
        end
        local bestSt, bestAmt
        for _, st in ipairs(poolIn) do
            local count = tonumber(st.count) or 0
            if count > 0 and count <= needWant then
                if not bestSt then
                    bestSt, bestAmt = st, count
                else
                    local bestIsMax = bestAmt >= maxStack
                    local countIsMax = count >= maxStack
                    if countIsMax and not bestIsMax then
                        bestSt, bestAmt = st, count
                    elseif countIsMax == bestIsMax and count > bestAmt then
                        bestSt, bestAmt = st, count
                    end
                end
            end
        end
        return bestSt, bestAmt or 0
    end

    local function pickPlain(poolIn, needWant, needTake)
        if preferMaxStacks then
            local st, amt = pickLargestWhole(poolIn, needWant)
            if st and amt > 0 then
                return st, amt
            end
        end
        return pickSmallest(poolIn, needWant, needTake)
    end

    if mergeRoom > 0 then
        local mergeWantProbe = math.min(want, mergeRoom, take)
        local overlayTailProbe = mergeWantProbe > 0 and mergeWantProbe == mergeRoom
        local hasSupply = Rules.HasMergeBankSupply(pool, mergeRoom, mergeItemID, tierKind, isSkipped, isNoSplit,
            overlayTailProbe)
        -- Tail top-off (need fits merge room) must still try merge — including
        -- split_merge for oversized bank stacks — even when no whole no-split
        -- supply exists yet.
        if hasSupply or overlayTailProbe then
        local mergeWant = mergeWantProbe
        local overlayTail = overlayTailProbe
        if mergeWant > 0 then
            local mergePool = buildMergePool(pool, mergeItemID, tierKind, mergeRoom, isNoSplit)
            local picked, amt = pickMergeSupplier(mergePool, mergeWant, want, isNoSplit, mergeRoom, mergeSplitBlocked, allowMergeStaging, mergeRoomFull)
            if picked and amt > 0 then
                local liveCount = tonumber(picked.count) or 0
                if itemIsNoSplit(picked, picked.itemID, isNoSplit) and amt < liveCount then
                    local room = tonumber(mergeRoomFull) or tonumber(mergeRoom) or 0
                    if liveCount > room then
                        picked, amt = nil, 0
                    end
                elseif not splitAmountViable(amt, liveCount, want) and amt < liveCount then
                    picked, amt = nil, 0
                end
            end
            if picked and amt > 0 then
                local liveCount = tonumber(picked.count) or 0
                local outAmt = amt
                if liveCount > 0 and liveCount <= mergeRoomFull and amt >= liveCount then
                    outAmt = liveCount
                else
                    outAmt = math.min(amt, want, mergeRoom)
                end
                return picked, outAmt, true
            end
        end
        end
    end

    local picked, amt = pickPlain(pool, want, take)
    if not picked and want > 0 and mergeRoom > 0 and mergeItemID then
        -- Merge was viable but could not pick a supplier; try exact-item stacks only.
        local exactPool = buildMergePool(pool, mergeItemID, nil, mergeRoom, isNoSplit)
        picked, amt = pickPlain(exactPool, want, take)
    end
    if not picked and want > 0 and mergeRoom > 0 and not mergeSplitBlocked then
        -- Still nothing: partial pull from smallest oversized stack (exact item first).
        local scanPool = mergeItemID and buildMergePool(pool, mergeItemID, nil, mergeRoom, isNoSplit) or pool
        if #scanPool == 0 then
            scanPool = pool
        end
        for _, st in ipairs(scanPool) do
            local count = tonumber(st.count) or 0
            if count > take then
                if itemIsNoSplit(st, st.itemID, isNoSplit) and count > mergeRoomFull then
                    -- no-split oversized stacks cannot fund a partial pull
                else
                    local pull = math.min(take, want)
                    if splitAmountViable(pull, count, want)
                        and not itemIsNoSplit(st, st.itemID, isNoSplit) then
                        picked, amt = st, pull
                        break
                    end
                end
            end
        end
    end
    if picked and amt > 0 then
        return picked, amt, false
    end

    return nil, 0, false
end

--- Single authoritative withdraw step from live bank/bag layout.
--- ctx: task, remaining, stacks, tierKind, itemID, maxStack, resolveMaxStack,
---       isSkipped, mode, getMergeTarget, getMaxPlaceable, canPlace, enrichChargeStacks
--- Returns step table or nil, reason.
function Rules.ResolveNextStep(ctx)
    ctx = type(ctx) == "table" and ctx or {}
    local task = ctx.task
    local entry = task and task.entry
    local remaining = tonumber(ctx.remaining) or 0
    if not entry or remaining <= 0 then
        return nil, "task_complete"
    end

    local stacks = ctx.stacks or {}
    if ctx.enrichChargeStacks then
        ctx.enrichChargeStacks(stacks)
    end

    local tierKind = ctx.tierKind
    if tierKind == nil and entry.isTierBankEntry then
        tierKind = entry.tierKind
    end
    local itemID = tonumber(ctx.itemID) or entry.itemID
    local maxStack = tonumber(ctx.maxStack) or 20
    local isSkipped = ctx.isSkipped
    local mode = ctx.mode or task.mode or entry.mode or "stack"

    if mode == "charge" then
        local target = tonumber(ctx.target) or tonumber(entry.target) or 0
        local bagCount = tonumber(ctx.bagCount)
        if bagCount == nil then
            bagCount = math.max(0, target - remaining)
        end
        if bagCount >= target then
            return nil, "at_target"
        end
        local maxCharges = tonumber(ctx.getMaxCharges and ctx.getMaxCharges(itemID)) or maxStack
        local picked = Rules.PickChargeWithdrawStack(stacks, isSkipped, {
            bagCount = bagCount,
            target = target,
            maxCharges = maxCharges,
        })
        if not picked then
            return nil, "no_stack"
        end
        local moveCount = tonumber(picked.count) or 0
        if moveCount <= 0 then
            return nil, "no_stack"
        end
        local stackCharges = tonumber(picked.charges) or moveCount
        if Rules.ChargeWithdrawWouldOvershoot(bagCount, target, stackCharges, maxCharges) then
            return nil, "would_overshoot"
        end
        local moveItemID = tonumber(picked.itemID) or itemID
        local liveMax = ctx.resolveMaxStack and ctx.resolveMaxStack(moveItemID, entry) or maxStack
        if ctx.canPlace and not ctx.canPlace(moveItemID, moveCount, liveMax, tierKind) then
            return nil, "no_room"
        end
        local credit = stackCharges
        return {
            bankBag = picked.bag,
            bankSlot = picked.slot,
            itemID = moveItemID,
            amount = moveCount,
            maxStack = liveMax,
            mustSplit = false,
            mergeBag = nil,
            mergeSlot = nil,
            tierKind = tierKind,
            mode = "charge",
            sourceCount = moveCount,
            chargeCredit = math.min(credit, remaining),
            task = task,
        }
    end

    if #stacks == 0 then
        return nil, "no_stacks"
    end

    local hasOpen, hasEligible = false, false
    for _, st in ipairs(stacks) do
        if (tonumber(st.count) or 0) > 0 and not (isSkipped and isSkipped(st)) then
            hasOpen = true
            if not st.locked then
                hasEligible = true
            end
        end
    end
    if hasOpen and not hasEligible then
        return nil, "locked"
    end

    local stepCap = math.min(remaining, maxStack)
    if stepCap <= 0 then
        return nil, "zero_amount"
    end

    local hasEmpty = ctx.hasEmptyBagSlot and ctx.hasEmptyBagSlot()
    local isNoSplit = ctx.isNoSplit
    local itemNoSplitOnly = itemIsNoSplit(nil, itemID, isNoSplit)

    -- preferWithdraw only makes sense as "grab a fresh stack instead of
    -- topping off partials" when a fresh/empty slot actually exists to grab
    -- into. If the bag has no empty slots left, merging into an existing
    -- partial stack may be the ONLY way to place anything — forcing
    -- preferWithdraw in that case would permanently block all progress
    -- (NoteTaskProgress only clears preferWithdraw once progress is made,
    -- so this would otherwise be a stall that can never resolve itself).
    -- preferWithdraw skips merge-first only for splittable items (max-stack to empty slot).
    -- No-split items still need merge-first for whole-stack fills into partial bags.
    -- Also keep merge-first when any bag partial can absorb the full remaining need
    -- (e.g. 17/20 in bag 2 with 3 left — must top off before grabbing a fresh stack).
    local discoveryItemID = tierKind and nil or itemID
    local tailMergeRoom = 0
    local tailMergeItemID = nil
    if ctx.getMergeTarget and remaining > 0 then
        local _, _, room, _, mergeItem = ctx.getMergeTarget(discoveryItemID, remaining, maxStack, tierKind)
        tailMergeRoom = tonumber(room) or 0
        tailMergeItemID = mergeItem
    end
    local tailTopOff = tailMergeRoom >= remaining and remaining > 0
    local totalMergeRoom = 0
    if ctx.getTotalMergeRoom then
        totalMergeRoom = tonumber(ctx.getTotalMergeRoom(discoveryItemID, maxStack, tierKind)) or 0
    end
    local spreadMergeFinish = totalMergeRoom >= remaining and remaining > 0
    local mergeSupplyPossible = tailMergeRoom > 0 and Rules.HasMergeBankSupply(
        stacks, tailMergeRoom, tailMergeItemID, tierKind, isSkipped, isNoSplit, tailTopOff)
    local partialCanFinish = tailMergeRoom >= remaining and remaining > 0 and mergeSupplyPossible
    -- Topping off a partial bag stack (tail fill) must stay merge-first even when
    -- preferWithdraw is set — plain withdraw cannot pull a partial amount and
    -- oversized bank stacks have no whole-stack merge path under no-split.
    -- Spread partials (e.g. 20+19+17, need 4): merge-first when combined room fits.
    local mustMergeFirst = tailTopOff
        or spreadMergeFinish
        or not hasEmpty
        or (itemNoSplitOnly and mergeSupplyPossible)
    local skipMergeFirst = ctx.preferWithdraw and hasEmpty
        and not mustMergeFirst
        and (not itemNoSplitOnly or not mergeSupplyPossible)

    local mergeBag, mergeSlot, mergeRoom, mergeRoomFull, mergeItemID
    if skipMergeFirst then
        mergeRoom = 0
        mergeRoomFull = 0
        mergeBag, mergeSlot, mergeItemID = nil, nil, nil
        local d = _G.FluxBankRestockDebug
        if d and d.Print then
            d.Print("step", "preferWithdraw active — skipping merge-first")
        end
    elseif ctx.getMergeTarget then
        mergeBag, mergeSlot, mergeRoom, mergeRoomFull, mergeItemID = ctx.getMergeTarget(
            discoveryItemID, stepCap, maxStack, tierKind)
    end
    mergeRoom = tonumber(mergeRoom) or 0
    mergeRoomFull = tonumber(mergeRoomFull) or mergeRoom

    local mergeSplitBlocked = task and task._bulkSplitFailed == true
    if mergeSplitBlocked then
        if itemNoSplitOnly then
            mergeSplitBlocked = false
        else
            mergeRoom = 0
            mergeRoomFull = 0
            mergeBag, mergeSlot, mergeItemID = nil, nil, nil
        end
    end

    if mergeRoom > 0 and mergeItemID then
        local hasExact = false
        for _, st in ipairs(stacks) do
            if tonumber(st.itemID) == tonumber(mergeItemID)
                and (tonumber(st.count) or 0) > 0
                and not st.locked
                and not (isSkipped and isSkipped(st)) then
                hasExact = true
                break
            end
        end
        if not hasExact then
            mergeBag, mergeSlot, mergeRoom, mergeRoomFull, mergeItemID = nil, nil, 0, 0, nil
        end
    end

    local stepOverlayTail = mergeRoom > 0
        and math.min(remaining, mergeRoom, stepCap) == mergeRoom
    if mergeRoom > 0 and not Rules.HasMergeBankSupply(stacks, mergeRoom, mergeItemID, tierKind, isSkipped, isNoSplit,
        stepOverlayTail) then
        mergeRoom = 0
        mergeRoomFull = 0
        mergeBag, mergeSlot, mergeItemID = nil, nil, nil
    end

    -- Bags full with a merge target: never withdraw a different tier item into limbo.
    local pickStacks = stacks
    if mergeRoom > 0 and mergeItemID and ctx.hasEmptyBagSlot and not ctx.hasEmptyBagSlot() then
        local exactOnly = {}
        for _, st in ipairs(stacks) do
            if tonumber(st.itemID) == tonumber(mergeItemID) then
                exactOnly[#exactOnly + 1] = st
            end
        end
        if #exactOnly > 0 then
            pickStacks = exactOnly
        end
    end

    local preferMaxStacks = hasEmpty and not skipMergeFirst
    local plainWithdrawFirst = preferMaxStacks
    local stagingOK = ctx.hasEmptyBagSlot and ctx.hasEmptyBagSlot() or false
    local st, amt, isMergePick = Rules.PickStackWithdrawStack(
        pickStacks, remaining, isSkipped, maxStack, mergeRoom, mergeItemID, stepCap, tierKind, isNoSplit, plainWithdrawFirst, preferMaxStacks, mergeSplitBlocked, stagingOK, mergeRoomFull)
    if not st or not amt or amt <= 0 then
        return nil, "no_stack"
    end

    if isSkipped and isSkipped(st) then
        return nil, "skipped"
    end

    local moveItemID = tonumber(st.itemID) or itemID
    local liveMax = ctx.resolveMaxStack and ctx.resolveMaxStack(moveItemID, entry) or maxStack
    local liveCount = tonumber(st.count) or 0

    -- No-split items never use SplitContainerItem — only whole-stack moves.
    local itemNoSplit = itemIsNoSplit(st, moveItemID, isNoSplit)
    local wholeStackNoSplit = itemNoSplit and amt >= liveCount and liveCount > 0
    if itemNoSplit and amt < liveCount then
        local room = tonumber(mergeRoomFull) or tonumber(mergeRoom) or 0
        if liveCount > room then
            return nil, "no_stack"
        end
    end
    if not splitAmountViable(amt, liveCount, remaining) and amt < liveCount and not itemNoSplit then
        return nil, "no_stack"
    end
    if wholeStackNoSplit and amt > remaining then
        return nil, "no_stack"
    end
    if not wholeStackNoSplit then
        amt = math.min(amt, remaining, stepCap)
    end

    local placeCap = stepCap
    if ctx.getMaxPlaceable then
        -- Whole-stack no-split moves need room for the FULL amount, not just
        -- the incremental need, since we can't split off a smaller piece.
        local placeWant = wholeStackNoSplit and amt or stepCap
        placeCap = tonumber(ctx.getMaxPlaceable(placeWant, moveItemID, liveMax, tierKind)) or 0
    end

    local outMergeBag, outMergeSlot
    local stepMode = "withdraw"

    if isMergePick then
        local savedBag, savedSlot, savedRoom, savedRoomFull = mergeBag, mergeSlot, mergeRoom, mergeRoomFull
        if ctx.getMergeTarget then
            -- Whole-stack no-split moves must query room for the FULL amount;
            -- querying with the small task-remaining amount could return a
            -- too-small target and wrongly shrink amt back into split territory.
            local queryAmt = wholeStackNoSplit and amt or math.min(stepCap, amt, remaining)
            mergeBag, mergeSlot, mergeRoom, mergeRoomFull, mergeItemID = ctx.getMergeTarget(
                moveItemID, queryAmt, liveMax, tierKind)
            mergeRoom = tonumber(mergeRoom) or 0
            mergeRoomFull = tonumber(mergeRoomFull) or mergeRoom
        end
        if (not mergeBag or not mergeSlot or mergeRoom <= 0)
            and savedBag and savedSlot and (tonumber(savedRoom) or 0) > 0 then
            mergeBag, mergeSlot, mergeRoom, mergeRoomFull = savedBag, savedSlot, savedRoom, savedRoomFull
        end
        if mergeBag and mergeSlot and mergeRoom > 0 and (not wholeStackNoSplit or mergeRoomFull >= amt) then
            amt = wholeStackNoSplit and amt or math.min(amt, mergeRoom, remaining)
            -- Whole stack fits the bag partial — pull entire stack (mover whole_merge path).
            if liveCount > 0 and liveCount <= mergeRoomFull then
                amt = liveCount
            end
            if amt <= 0 then
                return nil, "no_room"
            end
            outMergeBag = mergeBag
            outMergeSlot = mergeSlot
            stepMode = "merge"
        elseif wholeStackNoSplit then
            -- Merge room can't fit the whole un-splittable stack — fall back
            -- to a plain withdraw (empty-slot placement) instead of shrinking.
            stepMode = "withdraw"
        else
            -- Merge pick but no merge slot yet (bag layout still settling) — retry.
            return nil, "no_room"
        end
    end

    if stepMode == "withdraw" then
        if placeCap <= 0 then
            return nil, "no_room"
        end
        if amt > placeCap then
            if wholeStackNoSplit then
                -- Can't split off a smaller piece for this slot; if the
                -- whole stack doesn't fit, there's nothing safe to do yet.
                return nil, "no_room"
            end
            amt = math.min(amt, placeCap, remaining)
        end
        if ctx.canPlace and not ctx.canPlace(moveItemID, amt, liveMax, tierKind) then
            return nil, "no_room"
        end
    end

    if amt <= 0 then
        return nil, "zero_amount"
    end

    -- Re-read live count after merge/amount adjustments.
    liveCount = tonumber(st.count) or liveCount

    if task and task._bulkSplitFailed and stepMode == "merge" and not itemNoSplit
        and amt > 1 and liveCount > 1 and not stagingOK then
        amt = math.min(1, remaining, tonumber(mergeRoom) or remaining, amt)
    end

    return {
        bankBag = st.bag,
        bankSlot = st.slot,
        itemID = moveItemID,
        amount = amt,
        maxStack = liveMax,
        mustSplit = amt > 0 and amt < liveCount and not itemNoSplit
            and (stepMode == "merge" or splitAmountViable(amt, liveCount, remaining)
                or (task and task._bulkSplitFailed and amt == 1)),
        mergeBag = outMergeBag,
        mergeSlot = outMergeSlot,
        mergeRoom = tonumber(mergeRoom) or 0,
        mergeRoomFull = tonumber(mergeRoomFull) or tonumber(mergeRoom) or 0,
        tierKind = tierKind,
        mode = stepMode,
        sourceCount = liveCount,
        itemNoSplit = itemNoSplit,
        task = task,
    }
end

--- True when a stack-mode step would place more than `remaining` items.
function Rules.StepWouldOvershoot(step, remaining, liveCount, mode)
    remaining = tonumber(remaining) or 0
    liveCount = tonumber(liveCount) or 0
    local amount = tonumber(step and step.amount) or 0
    mode = mode or (step and step.mode) or "stack"
    if mode == "charge" then
        return false
    end
    if amount <= remaining then
        return false
    end
    if amount >= liveCount and liveCount > remaining then
        return true
    end
    return amount > remaining
end

--- Reject or trim a step so stack items never exceed `remaining`.
function Rules.ClampStep(step, remaining, mode)
    if not step then
        return nil
    end
    remaining = tonumber(remaining) or 0
    mode = mode or step.mode or "stack"
    if remaining <= 0 then
        return nil
    end
    if mode == "charge" then
        step.chargeCredit = math.min(tonumber(step.chargeCredit) or step.amount or 0, remaining)
        return step
    end
    local amount = tonumber(step.amount) or 0
    if amount > remaining then
        if step.mustSplit and remaining > 0 then
            step.amount = remaining
            return step
        end
        if step.itemNoSplit and step.mode == "merge" then
            local src = tonumber(step.sourceCount) or amount
            local room = tonumber(step.mergeRoomFull) or tonumber(step.mergeRoom) or 0
            if src > 0 and src <= room then
                return step
            end
        end
        return nil
    end
    step.amount = amount
    return step
end

--- Find one bag-to-bag merge to consolidate partial stacks after restock.
function Rules.FindBagConsolidateStep(ctx)
    ctx = type(ctx) == "table" and ctx or {}
    local task = ctx.task
    local entry = task and task.entry or ctx.entry
    if not entry or not ctx.bagIDs or not ctx.inv then
        return nil
    end
    local mode = ctx.mode or (task and task.mode) or entry.mode or "stack"
    if mode == "charge" then
        return nil
    end

    local tierKind = ctx.tierKind
    local itemID = tonumber(ctx.itemID) or entry.itemID
    local inv = ctx.inv
    local isNoSplit = ctx.isNoSplit
    local maxStackDefault = tonumber(ctx.maxStack) or 20
    local resolveMaxStack = ctx.resolveMaxStack

    local stacks = {}
    for _, bag in ipairs(ctx.bagIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local info = inv.GetContainerItemInfo(bag, slot)
            if info and (info.count or 0) > 0 and info.itemID then
                local matches = tierKind and tierStackMatches(tierKind, info.itemID)
                    or (tonumber(info.itemID) == itemID)
                if matches then
                    stacks[#stacks + 1] = {
                        bag = bag,
                        slot = slot,
                        count = info.count or 0,
                        itemID = info.itemID,
                        locked = info.locked,
                    }
                end
            end
        end
    end
    if #stacks < 2 then
        return nil
    end

    -- At target with a full stack plus separate partial(s), keep the spread
    -- (e.g. one max stack + 10) instead of merging into a single pile.
    local target = tonumber(ctx.target) or tonumber(entry and entry.target) or 0
    local bagTotal = tonumber(ctx.bagCount)
    if target > 0 and bagTotal and bagTotal >= target then
        local fullStacks, partialStacks = 0, 0
        for _, st in ipairs(stacks) do
            local destMax = resolveMaxStack and resolveMaxStack(st.itemID, entry) or maxStackDefault
            if (st.count or 0) >= destMax then
                fullStacks = fullStacks + 1
            else
                partialStacks = partialStacks + 1
            end
        end
        if fullStacks >= 1 and partialStacks >= 1 then
            return nil
        end
    end

    -- Destination: fullest partial first. Source: smallest stack first.
    table.sort(stacks, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        if a.bag ~= b.bag then
            return a.bag < b.bag
        end
        return a.slot < b.slot
    end)

    local sources = {}
    for i = 1, #stacks do
        sources[i] = stacks[i]
    end
    table.sort(sources, function(a, b)
        if a.count ~= b.count then
            return a.count < b.count
        end
        if a.bag ~= b.bag then
            return a.bag < b.bag
        end
        return a.slot < b.slot
    end)

    for _, dest in ipairs(stacks) do
        if not dest.locked then
            local destMax = resolveMaxStack and resolveMaxStack(dest.itemID, entry) or maxStackDefault
            local room = destMax - dest.count
            if room > 0 then
                for _, src in ipairs(sources) do
                    if not (src.bag == dest.bag and src.slot == dest.slot)
                        and not src.locked and src.count > 0
                        and tonumber(src.itemID) == tonumber(dest.itemID) then
                        -- Only whole-stack moves that empty the source slot — partial
                        -- bag-to-bag pulls ping-pong between the same two slots forever.
                        if src.count > room then
                            -- source does not fit; try another pair
                        else
                            local moveAmt = src.count
                            if itemIsNoSplit(src, src.itemID, isNoSplit)
                                and moveAmt < src.count then
                                moveAmt = 0
                            end
                            if moveAmt > 0 then
                                return {
                                    fromBag = src.bag,
                                    fromSlot = src.slot,
                                    toBag = dest.bag,
                                    toSlot = dest.slot,
                                    itemID = src.itemID,
                                    amount = moveAmt,
                                    maxStack = destMax,
                                    tierKind = tierKind,
                                    mode = "bag_consolidate",
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

--- Derive execution kind from a Rules step or planned move (item-agnostic).
--- sourceCount: bank/bag stack size before the move (optional; falls back to step.sourceCount).
function Rules.DeriveExecKind(step, sourceCount)
    if not step then
        return nil
    end
    local mode = step.mode or "withdraw"
    local amt = tonumber(step.amount) or 0
    local srcCount = tonumber(sourceCount)
    if srcCount == nil then
        srcCount = tonumber(step.sourceCount)
    end
    if mode == "bag_consolidate" then
        if srcCount and amt > 0 and srcCount > amt then
            return "split_withdraw"
        end
        return "bag_consolidate"
    end
    if step.itemNoSplit then
        if mode == "charge" then
            return "charge"
        end
        if mode == "merge" then
            local mergeRoomFull = tonumber(step.mergeRoomFull) or tonumber(step.mergeRoom)
            if srcCount and mergeRoomFull and srcCount > 0 and srcCount <= mergeRoomFull then
                return "whole_merge"
            end
            if srcCount and amt > 0 and srcCount <= amt then
                return "whole_merge"
            end
            return "whole_merge"
        end
        return "whole_withdraw"
    end
    if mode == "charge" then
        return "charge"
    end
    if mode == "merge" then
        local mergeRoomFull = tonumber(step.mergeRoomFull) or tonumber(step.mergeRoom)
        -- Whole bank stack fits the bag partial's real room — whole pickup, not split.
        if mergeRoomFull and srcCount and srcCount > 0 and srcCount <= mergeRoomFull then
            return "whole_merge"
        end
        local mergeRoom = tonumber(step.mergeRoom)
        if mergeRoom and srcCount and srcCount > 0 and srcCount <= mergeRoom then
            return "whole_merge"
        end
        if step.mustSplit or (srcCount and srcCount > amt) then
            return "split_merge"
        end
        return "whole_merge"
    end
    if step.mustSplit or (srcCount and srcCount > amt) then
        return "split_withdraw"
    end
    return "whole_withdraw"
end

--- True when the move must use FluxItemMover async split/merge path.
function Rules.NeedsMoverLane(move)
    local kind = move and (move.execKind or Rules.DeriveExecKind(move, move and move.sourceCount))
    return kind == "split_withdraw" or kind == "split_merge"
end

--- True when PlanExecutor may fire the move on the burst (whole-stack) path.
function Rules.CanBurstExecute(move)
    local kind = move and (move.execKind or Rules.DeriveExecKind(move, move and move.sourceCount))
    return kind == "whole_withdraw" or kind == "whole_merge" or kind == "charge"
end

_G.FluxBankRestockRules = Rules
return Rules
