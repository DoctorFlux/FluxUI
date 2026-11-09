--[[
    Restock/Bank/FluxBankRestockMovePlan.lua

    TSM-style plan: for each need, assign bank source → exact qty → destination.
    Fill existing bag partials first (bags 9 + need 21 → split 11 onto the 9,
    then 10 to empty) so a whole-20 withdraw cannot leave a leftover-1 split.
    Then remaining wholes, then leftover splits onto merge or empty.
]]

FluxBankRestockMovePlan = FluxBankRestockMovePlan or {}
local Plan = FluxBankRestockMovePlan

local function Inv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

local function Bank()
    local inv = Inv()
    return inv and inv.Bank
end

local function Inventory()
    return _G.FluxBankRestockInventory
end

local function Mover()
    return _G.FluxItemMover
end

local function Tiers()
    return _G.FluxRestockTiers
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

local function slotKey(bag, slot)
    return tostring(bag) .. ":" .. tostring(slot)
end

local function resolveMaxStack(itemID, fallback, resolveFn, entry)
    itemID = tonumber(itemID)
    if resolveFn then
        local n = tonumber(resolveFn(itemID, entry))
        if n and n > 0 then
            return n
        end
    end
    return tonumber(fallback) or 20
end

--- Collect empty player bag slots (reserved via tremove like TSM).
local function collectEmptySlots(bagIDs)
    local inv = Inv()
    local empties = {}
    if not inv or not bagIDs then
        return empties
    end
    for _, bag in ipairs(bagIDs) do
        local numSlots = inv.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local info = inv.GetContainerItemInfo(bag, slot)
            if not info or not info.itemID or (info.count or 0) <= 0 then
                empties[#empties + 1] = { bag = bag, slot = slot }
            end
        end
    end
    return empties
end

--- Working partial map: key "bag:slot" → { bag, slot, count, itemID, maxStack }
local function buildPartials(playerSnap, resolveFn, entry)
    local partials = {}
    if not playerSnap or not playerSnap.slots then
        return partials
    end
    for _, list in pairs(playerSnap.slots) do
        for _, st in ipairs(list) do
            local maxStack = resolveMaxStack(st.itemID, 20, resolveFn, entry)
            local count = tonumber(st.count) or 0
            if count > 0 and count < maxStack then
                local key = slotKey(st.bag, st.slot)
                partials[key] = {
                    bag = st.bag,
                    slot = st.slot,
                    count = count,
                    itemID = st.itemID,
                    maxStack = maxStack,
                }
            end
        end
    end
    return partials
end

--- Restocker FindBestFit over simulated partials: exact itemID, room >= amount.
local function findBestFitPartial(partials, itemID, amount, tierKind)
    itemID = tonumber(itemID)
    amount = tonumber(amount) or 0
    if not itemID or amount <= 0 then
        return nil
    end
    local mover = Mover()
    local bestKey, bestRemainder
    for key, p in pairs(partials) do
        local ok = (tonumber(p.itemID) == itemID)
        if not ok and tierKind and mover and mover.ItemsCanMerge then
            ok = mover.ItemsCanMerge(p.itemID, itemID, tierKind)
        end
        if ok then
            local room = (tonumber(p.maxStack) or 20) - (tonumber(p.count) or 0)
            if room >= amount then
                local remainder = room - amount
                if not bestRemainder or remainder < bestRemainder then
                    bestRemainder = remainder
                    bestKey = key
                end
            end
        end
    end
    if bestKey then
        return partials[bestKey], bestKey
    end
    return nil, nil
end

--- Partial to fill first so a 20-stack pull does not leave a leftover-1 split
--- (bag 9 + need 21 → fill 11 onto the 9, then split 10 — not 20 + split 1).
local function findFillPartial(partials, itemID, remaining, fallbackMax, tierKind)
    itemID = tonumber(itemID)
    remaining = math.floor(tonumber(remaining) or 0)
    if not itemID or remaining <= 1 then
        return nil
    end
    local mover = Mover()
    local best, bestKey, bestWant
    for key, p in pairs(partials) do
        local ok = (tonumber(p.itemID) == itemID)
        if not ok and tierKind and mover and mover.ItemsCanMerge then
            ok = mover.ItemsCanMerge(p.itemID, itemID, tierKind)
        end
        if ok then
            local maxStack = tonumber(p.maxStack) or fallbackMax or 20
            local room = maxStack - (tonumber(p.count) or 0)
            if room >= 2 then
                local want = math.min(room, remaining)
                local left = remaining - want
                if want >= 2 and (left ~= 1 or want == remaining) then
                    if not bestWant or want > bestWant then
                        best, bestKey, bestWant = p, key, want
                    end
                end
            end
        end
    end
    return best, bestKey, bestWant
end

local function otherStackCovers(ordered, reservedSources, skipKey, amt)
    amt = math.floor(tonumber(amt) or 0)
    if amt <= 0 then
        return false
    end
    for _, st in ipairs(ordered) do
        local bag, slot = tonumber(st.bag), tonumber(st.slot)
        local key = bag and slot and slotKey(bag, slot)
        if key and key ~= skipKey and not reservedSources[key] then
            if math.floor(tonumber(st.count) or 0) >= amt then
                return true
            end
        end
    end
    return false
end

local function takeEmptySlot(empties)
    if not empties or #empties == 0 then
        return nil
    end
    return table.remove(empties, 1)
end

local function bankStacksForNeed(need, opts)
    local entry = need.entry
    if need.mode == "charge" and opts and opts.stacksForCharge then
        return opts.stacksForCharge(entry) or {}
    end
    if opts and opts.stacksForTask then
        return opts.stacksForTask(entry) or {}
    end
    local bank = Bank()
    if not bank then
        return {}
    end
    if need.tierKind then
        local T = Tiers()
        if T and T.FindBankStacksForKind then
            return T.FindBankStacksForKind(need.tierKind) or {}
        end
        return {}
    end
    return bank.FindStacks(need.itemID) or {}
end

local function playerSnapForNeed(need, opts)
    if opts and opts.playerSnapForTask and need.task then
        return opts.playerSnapForTask(need.task)
    end
    local inv = Inv()
    local invMod = Inventory()
    if not inv or not invMod then
        return { summary = {}, slots = {} }
    end
    local bagIDs = inv.GetBagContainerIDs and inv.GetBagContainerIDs()
    local matchFn
    if need.tierKind then
        matchFn = invMod.MatchTierKind(need.tierKind)
    else
        matchFn = invMod.MatchItemID(need.itemID)
    end
    return invMod.SnapshotPlayerBags(bagIDs, matchFn, function(itemID)
        return resolveMaxStack(itemID, need.maxStack, opts and opts.resolveMaxStack, need.entry)
    end)
end

--- Build ordered move list.
--- @param needs table[] from FluxBankRestockNeed.BuildFromTasks
--- @param opts table|nil resolveMaxStack, stacksForTask, stacksForCharge, playerSnapForTask, getSlotCharges
--- @return table[] moves, table stats
function Plan.Build(needs, opts)
    opts = opts or {}
    local inv = Inv()
    local bagIDs = inv and inv.GetBagContainerIDs and inv.GetBagContainerIDs() or {}
    local empties
    if opts.emptySlots then
        empties = {}
        for i, e in ipairs(opts.emptySlots) do
            empties[i] = { bag = e.bag, slot = e.slot }
        end
    else
        empties = collectEmptySlots(bagIDs)
    end
    local moves = {}
    local stats = { planned = 0, no_target = 0, locked = 0 }

    -- Shared empty pool across all needs; partials are per-need (item/tier scoped).
    for _, need in ipairs(needs or {}) do
        local remaining = math.floor(tonumber(need.remaining) or 0)
        if remaining > 0 then
            local snap = playerSnapForNeed(need, opts)
            local partials = buildPartials(snap, opts.resolveMaxStack, need.entry)
            local stacks = bankStacksForNeed(need, opts)
            local reservedSources = {}

            -- Prefer stacks that fit as wholes (UseContainerItem burst) before any split.
            local ordered = {}
            for _, st in ipairs(stacks) do
                ordered[#ordered + 1] = st
            end
            table.sort(ordered, function(a, b)
                local ca = math.floor(tonumber(a.count) or 0)
                local cb = math.floor(tonumber(b.count) or 0)
                local aWhole = ca > 0 and ca <= remaining
                local bWhole = cb > 0 and cb <= remaining
                if aWhole ~= bWhole then
                    return aWhole
                end
                -- Among wholes: larger first. Among splits: smaller first (less leftover).
                if aWhole then
                    return ca > cb
                end
                return ca < cb
            end)

            local function planOneStack(st, allowSplit)
                if remaining <= 0 then
                    return
                end
                local bag, slot = tonumber(st.bag), tonumber(st.slot)
                local count = math.floor(tonumber(st.count) or 0)
                local srcKey = bag and slot and slotKey(bag, slot)
                if not bag or not slot or count <= 0 or reservedSources[srcKey] then
                    return
                end
                if st.locked then
                    stats.locked = stats.locked + 1
                    return
                end

                local itemID = tonumber(st.itemID) or need.itemID
                local maxStack = resolveMaxStack(itemID, need.maxStack, opts.resolveMaxStack, need.entry)

                if need.mode == "charge" then
                    local charges = tonumber(st.charges)
                    if not charges and opts.getSlotCharges then
                        charges = opts.getSlotCharges(bag, slot, count)
                    end
                    charges = tonumber(charges) or count
                    local credit = math.min(charges, remaining)
                    if credit > 0 then
                        reservedSources[srcKey] = true
                        moves[#moves + 1] = {
                            kind = "charge",
                            fromBag = bag,
                            fromSlot = slot,
                            toBag = nil,
                            toSlot = nil,
                            qty = count,
                            endQty = 0,
                            itemID = itemID,
                            maxStack = maxStack,
                            tierKind = need.tierKind,
                            chargeCredit = credit,
                            task = need.task,
                            need = need,
                        }
                        remaining = remaining - credit
                        stats.planned = stats.planned + 1
                    end
                    return
                end

                local take = math.min(count, remaining, maxStack)
                if take <= 0 then
                    return
                end
                local isWhole = take >= count

                -- Safety: if a whole would leave leftover-1, skip it on the
                -- wholes pass (fill pass already preferred). Split pass may
                -- still reduce this take onto a bag partial.
                if isWhole and (remaining - take) == 1 then
                    local _, _, fillWant = findFillPartial(
                        partials, itemID, remaining, maxStack, need.tierKind)
                    if fillWant and fillWant >= 2
                        and otherStackCovers(ordered, reservedSources, srcKey, remaining - fillWant) then
                        if not allowSplit then
                            return
                        end
                        take = math.min(count, fillWant, maxStack)
                        isWhole = take >= count
                    end
                end

                if not isWhole and not allowSplit then
                    return
                end

                local toBag, toSlot, destKind
                if isWhole then
                    destKind = "auto"
                else
                    -- Prefer merging onto an existing bag partial (no extra empty needed).
                    local partial, pKey = findBestFitPartial(partials, itemID, take, need.tierKind)
                    if partial and pKey then
                        toBag, toSlot = partial.bag, partial.slot
                        destKind = "merge"
                        partial.count = (tonumber(partial.count) or 0) + take
                        if partial.count >= maxStack then
                            partials[pKey] = nil
                        end
                    else
                        local dest = takeEmptySlot(empties)
                        if dest then
                            toBag, toSlot = dest.bag, dest.slot
                            destKind = "empty"
                            if take < maxStack then
                                local nk = slotKey(toBag, toSlot)
                                partials[nk] = {
                                    bag = toBag,
                                    slot = toSlot,
                                    count = take,
                                    itemID = itemID,
                                    maxStack = maxStack,
                                }
                            end
                        end
                    end
                end

                if isWhole or (toBag and toSlot) then
                    reservedSources[srcKey] = true
                    local kind = isWhole and "whole" or "split_place"
                    moves[#moves + 1] = {
                        kind = kind,
                        fromBag = bag,
                        fromSlot = slot,
                        toBag = toBag,
                        toSlot = toSlot,
                        qty = take,
                        endQty = count - take,
                        itemID = itemID,
                        maxStack = maxStack,
                        tierKind = need.tierKind,
                        destKind = destKind,
                        task = need.task,
                        need = need,
                    }
                    remaining = remaining - take
                    stats.planned = stats.planned + 1
                    Dbg("plan", "move %s item=%s amt=%s bank=%s:%s -> %s:%s dest=%s",
                        kind, tostring(itemID), take, bag, slot,
                        tostring(toBag or "-"), tostring(toSlot or "-"), tostring(destKind))
                else
                    stats.no_target = stats.no_target + 1
                    DbgImportant("plan", "no_target item=%s want=%s bank=%s:%s count=%s",
                        tostring(itemID), take, bag, slot, count)
                end
            end

            -- Fill existing bag partials first (bags 9 + need 21 → split 11
            -- onto the 9, then 10 — never whole-20 + leftover-1).
            local function planFillOntoPartial(st)
                if remaining <= 0 or need.mode == "charge" then
                    return
                end
                local bag, slot = tonumber(st.bag), tonumber(st.slot)
                local count = math.floor(tonumber(st.count) or 0)
                local srcKey = bag and slot and slotKey(bag, slot)
                if not bag or not slot or count <= 0 or reservedSources[srcKey] then
                    return
                end
                if st.locked then
                    stats.locked = stats.locked + 1
                    return
                end
                local itemID = tonumber(st.itemID) or need.itemID
                local maxStack = resolveMaxStack(itemID, need.maxStack, opts.resolveMaxStack, need.entry)
                local fillP, fillKey, fillWant = findFillPartial(
                    partials, itemID, remaining, maxStack, need.tierKind)
                if not fillP or not fillKey or not fillWant or fillWant < 2 then
                    return
                end
                local take = math.min(count, fillWant, remaining, maxStack)
                if take < 2 then
                    return
                end
                local stillNeed = remaining - take
                if stillNeed > 0
                    and not otherStackCovers(ordered, reservedSources, srcKey, stillNeed) then
                    -- Filling would strand leftover that this source cannot
                    -- cover after we reserve it (e.g. only one 20 in bank).
                    return
                end
                fillP.count = (tonumber(fillP.count) or 0) + take
                if fillP.count >= maxStack then
                    partials[fillKey] = nil
                end
                reservedSources[srcKey] = true
                moves[#moves + 1] = {
                    kind = "split_place",
                    fromBag = bag,
                    fromSlot = slot,
                    toBag = fillP.bag,
                    toSlot = fillP.slot,
                    qty = take,
                    endQty = count - take,
                    itemID = itemID,
                    maxStack = maxStack,
                    tierKind = need.tierKind,
                    destKind = "merge",
                    task = need.task,
                    need = need,
                }
                remaining = remaining - take
                stats.planned = stats.planned + 1
                DbgImportant("plan", "fill-partial item=%s amt=%s bank=%s:%s -> %s:%s (left=%s)",
                    tostring(itemID), take, bag, slot, fillP.bag, fillP.slot, stillNeed)
            end

            local orderedFill = {}
            for i = 1, #ordered do
                orderedFill[i] = ordered[i]
            end
            table.sort(orderedFill, function(a, b)
                local ca = math.floor(tonumber(a.count) or 0)
                local cb = math.floor(tonumber(b.count) or 0)
                if ca ~= cb then
                    return ca < cb
                end
                if (a.bag or 0) ~= (b.bag or 0) then
                    return (a.bag or 0) < (b.bag or 0)
                end
                return (a.slot or 0) < (b.slot or 0)
            end)
            for _, st in ipairs(orderedFill) do
                planFillOntoPartial(st)
            end

            -- Pass 1: remaining wholes (burst). Pass 2: leftover splits to empty.
            for _, st in ipairs(ordered) do
                planOneStack(st, false)
            end
            if remaining > 0 then
                for _, st in ipairs(ordered) do
                    planOneStack(st, true)
                end
            end
        end
    end

    DbgImportant("plan", "plan built moves=%d no_target=%d locked=%d emptiesLeft=%d",
        #moves, stats.no_target, stats.locked, #empties)
    return moves, stats
end

_G.FluxBankRestockMovePlan = Plan
return Plan
