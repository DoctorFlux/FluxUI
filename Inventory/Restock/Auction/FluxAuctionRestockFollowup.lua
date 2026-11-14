-- Persist this restock's receipts and selected recipes. Mail/vendor/bank work
-- stays with its existing owner; only the exact craft is dispatched here.
local _, ns = ...
local A, Flux = FluxAuctionRestock, ns.Flux
local Inv, Events = Flux.Inventory, Flux.Events
local F = {}
A.Followup = F
local N = A.Number
local listening, refreshing, dispatching, current
local currentJob, countMemo
local mailOpen, merchantOpen = false, false
local busy, taking, buying
local bankTargets = {}
local publishedBankGoals = {}
local automaticAttempt, requestedStage
local Dispatch
local function Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for k, v in pairs(value) do out[k] = Copy(v) end; return out
end
local function Count(id, charges)
    local ri = _G.FluxRestock and FluxRestock.Inv
    if not ri or not ri.IsReliable or not ri.IsReliable() or (Inv.IsBagStorm and Inv.IsBagStorm()) then return end
    local memo = countMemo and countMemo[charges == true and 2 or 1]
    if memo and memo[id] ~= nil then return memo[id] end
    local value = ri.GetLiveCount and N(ri.GetLiveCount(id, {
        bags = true, bank = false, warband = false, equipped = false, charges = charges == true,
    }))
    if memo then memo[id] = value end
    return value
end
local function Name(id)
    local ic = _G.FluxItemClass
    return ic and ic.GetName and ic.GetName(id) or tostring(id)
end
local function MailCount(id)
    local count = N(A.MailUnits({ itemID = id, isCharge = false }))
    local builtin = Inv.Builtin and Inv.Builtin.Mail
    local predicted = builtin and builtin.GetPredictedCount and N(builtin.GetPredictedCount(id)) or 0
    return count and math.max(0, count - (predicted or 0))
end
local function Job()
    local job = A.Settings().followup
    if type(job) == "table" and job.version == 1 and type(job.receipts) == "table" and type(job.outputs) == "table" then return job end
end
local function IDs(map)
    local ids = {}; for id in pairs(map) do ids[#ids + 1] = id end; table.sort(ids); return ids
end
local function SameMap(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for id, quantity in pairs(a) do if b[id] ~= quantity then return false end end
    for id, quantity in pairs(b) do if a[id] ~= quantity then return false end end
    return true
end
local function AttemptFacts()
    local bags = Inv.snapshots and Inv.snapshots.bags
    local free = Flux.Container and Flux.Container.GetTotalFreeBagSlots
    local invoice = {}
    local vendor = current and current.kind == "vendor" and _G.FluxVendorAuto
    local index = vendor and vendor.GetMerchantItemIndex and vendor.GetMerchantItemIndex(false)
    for _, id in ipairs(index and IDs(current.items) or {}) do
        local meta = index[id] or {}
        invoice[#invoice + 1] = table.concat({ id, N(meta.price) or -1, N(meta.batchQty) or 0,
            N(meta.unitPrice) or -1, N(meta.numAvailable) or -1 }, ":")
    end
    return { bags = N(Inv.GetBagGeneration and Inv.GetBagGeneration()) or N(bags and bags.generation) or 0,
        vendor = table.concat(invoice, ";"),
        money = N(GetMoney and GetMoney()) or 0, free = N(free and free()) or -1 }
end
local function State(kind, items, task)
    local count, first = 0
    for _, id in ipairs(IDs(items)) do count = count + items[id]; first = first or id end
    return { kind = kind, items = items, itemID = first or (task and task.parentID),
        name = first and Name(first) or (task and task.recipeName) or "", quantity = first and count or (task and task.operations) or count, task = task }
end

-- Snapshot before the restricted purchase; a rejected/failed attempt never
-- activates the reminder. Keep the exact selected recipes, not a best-kind guess.
local function Snapshot(parent, output, plan)
    local recipe = plan.recipe
    local prices = {}
    for id in pairs(recipe.required) do
        local vendor = plan.vendorItems and plan.vendorItems[id] == true or not plan.vendorItems and A.IsVendorItem(id)
        if vendor then prices[id] = plan.vendorPrices and plan.vendorPrices[id] or A.VendorPrice(id) end
    end
    local savedRow = { itemID = parent, name = output.name, target = plan.targetAtPlan, countBank = output.countBank,
        isTierRestock = output.isTierRestock, tierKind = output.tierKind, auctionTier = output.auctionTier,
        upgradeFrom = output.upgradeFrom, bankCount = output.bankCount }
    if output.tiers then
        savedRow.tiers = {}
        for _, source in ipairs(output.tiers) do savedRow.tiers[#savedRow.tiers + 1] = {
            tierKind = source.tierKind, target = source.target, countBank = source.countBank,
        } end
    end
    return { row = savedRow, target = plan.targetAtPlan,
        outputItemID = parent, recipeVerified = true,
        recipeOwner = Inv.Professions and Inv.Professions.GetCharacterKey and Inv.Professions.GetCharacterKey(),
        countBank = plan.countBankAtPlan, cap = plan.capAtPlan, capUnlimited = plan.capUnlimitedAtPlan,
        recipeID = recipe.recipeID, recipeName = recipe.name, skillName = recipe.skillName,
        skillLineID = recipe.skillLineID, legacy = recipe.legacy, yield = recipe.yield,
        required = Copy(recipe.required), allocation = Copy(recipe.allocation), prices = prices,
        bankFlags = Copy(plan.bankFlags) }
end
local function Outputs()
    local outputs = {}
    for parent, plan in pairs(A.craftPlans or {}) do
        local output = A.FindRow(parent)
        if output then outputs[parent] = Snapshot(parent, output, plan) end
    end
    return outputs
end
function F.Capture(row)
    return { itemID = row.itemID, before = Count(row.itemID),
        mail = row.unitsPerItem and A.MailUnits(row) / row.unitsPerItem or 0, outputs = Outputs() }
end

-- Every exact owned-take proof uses the same credit path, regardless of
-- whether inbox or bag publication wins the race with the mail worker.
local function CreditTake(job, attempt, moved)
    local receipt = job.receipts[attempt.itemID]
    if not receipt then return end
    local already = math.max(0, attempt.remaining - receipt.remaining)
    receipt.collectedAwaitingBags = (N(receipt.collectedAwaitingBags) or 0) + math.max(0, moved - already)
    receipt.remaining = math.max(0, math.min(receipt.remaining, attempt.remaining - moved))
    if receipt.remaining == 0 then
        job.receipts[attempt.itemID] = nil
        local record = A.Settings().pending[attempt.itemID]
        if record and record.accepted == true and not A.transaction then A.Release(attempt.itemID, record.units) end
    end
end

local function Reconcile(job)
    if taking then
        local receipt = job.receipts[taking.itemID]
        local have = Count(taking.itemID)
        local generation = Inv.snapshots and Inv.snapshots.mail and Inv.snapshots.mail.generation
        local mail = MailCount(taking.itemID)
        if receipt and have and mail and generation ~= taking.generation then
            local moved = math.min(taking.quantity, math.max(0, taking.beforeMail - mail))
            if moved > 0 then
                -- An authoritative inbox change also proves our matching take
                -- when using an old last charge leaves net bag copies unchanged.
                CreditTake(job, taking, moved)
                if moved >= taking.quantity then taking = nil end
            end
        end
    end
    for id, receipt in pairs(job.receipts) do
        local have = Count(id)
        if have then
            local arrived = math.max(0, have - (receipt.lastBags or have))
            local collected = math.min(arrived, N(receipt.collectedAwaitingBags) or 0)
            receipt.collectedAwaitingBags = math.max(0, (N(receipt.collectedAwaitingBags) or 0) - collected)
            arrived = arrived - collected
            receipt.remaining = math.max(0, receipt.remaining - arrived)
            receipt.lastBags = have
            if receipt.remaining == 0 then job.receipts[id] = nil end
        end
    end
end

function F.Purchased(transaction)
    local intent = transaction.followup
    if not intent or not N(intent.before) or not N(transaction.quantity) then return end
    local job = Job() or { version = 1, receipts = {}, outputs = {} }
    Reconcile(job)
    local receipt = job.receipts[transaction.itemID]
    if receipt then
        receipt.remaining = receipt.remaining + transaction.quantity
        if taking and taking.itemID == transaction.itemID then taking.remaining = taking.remaining + transaction.quantity end
    else receipt = { remaining = transaction.quantity + (intent.mail or 0), lastBags = intent.before }; job.receipts[transaction.itemID] = receipt end
    for parent, plan in pairs(intent.outputs) do job.outputs[parent] = plan end
    A.Settings().followup = job
    F.Refresh()
end

function F.HasWork()
    return Job() ~= nil or next(A.Settings().pending) ~= nil
        or next(A.Settings().vendorCraftPlans or {}) ~= nil
end
function F.IsAutoEnabled() return A.Settings().autoFollowup == true end
function F.SetAutoEnabled(enabled)
    A.Settings().autoFollowup = enabled == true
    if automaticAttempt and not automaticAttempt.submitted then automaticAttempt = nil end
    F.Refresh()
end
function F.IsContextOpen(kind)
    if InCombatLockdown() then return false end
    if kind == "mail" then
        local mail = Flux.Mail
        if mail and mail.IsRestockContextOpen then return mail.IsRestockContextOpen() == true end
        return mailOpen or (Inv.IsMailboxOpen and Inv.IsMailboxOpen()) == true
    end
    local ri = _G.FluxRestock and FluxRestock.Inv
    if not ri or not ri.IsReliable or not ri.IsReliable() or (Inv.IsBagStorm and Inv.IsBagStorm()) then return false end
    if kind == "vendor" then
        local vendor = _G.FluxVendorAuto
        if (merchantOpen or (Inv.IsMerchantOpen and Inv.IsMerchantOpen())) ~= true
            or (vendor and vendor.IsMerchantIndexBuildPending and vendor.IsMerchantIndexBuildPending()) then return false end
        return not vendor or not vendor.CanAuctionFollowup or vendor.CanAuctionFollowup() == true
    elseif kind == "bank" then
        local bank = ri.Bank
        return bank and bank.IsOpen and bank.IsOpen() == true and bank.IsLive and bank.IsLive() == true or false
    end
    return false
end
-- Readiness is published once with each state. The UI reads canAct instead of
-- asking execution owners again while it lays out/recycles the item buttons.
function F.CanAct(state)
    state = state or current
    if not state or state ~= current or state.settling or InCombatLockdown() or busy or dispatching then return false end
    if automaticAttempt and automaticAttempt.submitted and automaticAttempt.kind == state.kind
        and SameMap(automaticAttempt.items, state.items) then return false end
    if state.kind == "craft" then return F.CanCraft and F.CanCraft(state.task) == true or false end
    if not state.contextOpen or not next(state.items or {}) then return false end
    if state.kind == "mail" then
        local mail = Flux.Mail
        return mail and mail.CanTakeRestockItems and mail.CanTakeRestockItems() == true or false
    elseif state.kind == "vendor" then
        local vendor = _G.FluxVendorAuto
        if not vendor or not vendor.DoAuctionFollowup then return false end
        if vendor.IsAuctionFollowupBusy and vendor.IsAuctionFollowupBusy() then return false end
        if vendor.IsRestockBuyActive and vendor.IsRestockBuyActive() then return false end
        return true -- contextOpen already verified the scoped current vendor queue
    elseif state.kind == "bank" then
        local bank = _G.FluxBankRestock
        if not bank or not bank.RunAuctionFollowup or (bank.IsRunning and bank.IsRunning()) then return false end
        return not bank.CanAuctionFollowup or bank.CanAuctionFollowup() == true
    end
    return false
end
function F.GetMailItems()
    local job, items = Job(), {}
    if job then
        Reconcile(job)
        for id, receipt in pairs(job.receipts) do
            if receipt.remaining > 0 then items[id] = receipt.remaining end
        end
    end
    return items
end
function F.MailTakeStarted(id, quantity)
    local job = Job()
    local receipt = job and job.receipts[id]
    quantity = N(quantity)
    if taking or not receipt or not quantity or quantity <= 0 or quantity > receipt.remaining then return false end
    -- Mail has exact native attachment proof even while a bag storm defers
    -- inventory publication. Keep the last reliable baseline until it settles.
    local have = Count(id) or receipt.lastBags
    local snapshot = Inv.snapshots and Inv.snapshots.mail
    taking = { itemID = id, before = have, quantity = quantity, remaining = receipt.remaining,
        generation = snapshot and snapshot.generation, beforeMail = math.max(quantity, receipt.remaining, MailCount(id) or 0) }
    return true
end
function F.MailTakeFinished(id, quantity)
    local job = Job()
    if job and taking and taking.itemID == id and N(quantity) and quantity >= taking.quantity then
        Reconcile(job)
        if taking then CreditTake(job, taking, taking.quantity); taking = nil end
    end
    F.Refresh()
end
function F.MailTakeCancelled()
    taking = nil
    if automaticAttempt and automaticAttempt.kind == "mail" then
        automaticAttempt.submitted, automaticAttempt.facts = false, AttemptFacts()
    end
    F.Refresh()
end
function F.OwnerRejected(kind)
    if automaticAttempt and automaticAttempt.kind == kind then
        automaticAttempt.submitted, automaticAttempt.facts = false, AttemptFacts()
    end
    F.Refresh()
end

-- The mailbox worker supplies a complete, settled native inbox, including with
-- Syndicator active. A cached/predicted provider map cannot prove an empty inbox.
function F.MailSnapshotComplete(counts)
    if type(counts) ~= "table" then return end
    local job = Job()
    if A.NoteRestockMailbox then A.NoteRestockMailbox(counts, job and job.receipts) end
    if not job then return end
    Reconcile(job)
    if taking then
        local actual = N(counts[taking.itemID]) or 0
        local moved = math.min(taking.quantity, math.max(0, taking.beforeMail - actual))
        if moved > 0 then
            CreditTake(job, taking, moved)
            if moved >= taking.quantity then taking = nil end
        end
    end
    for id, receipt in pairs(job.receipts) do
        if not (A.transaction and A.transaction.itemID == id) then
            local actual = N(counts[id]) or 0
            local removed = math.max(0, receipt.remaining - math.max(0, actual))
            receipt.collectedAwaitingBags = (N(receipt.collectedAwaitingBags) or 0) + removed
            receipt.remaining = math.min(receipt.remaining, math.max(0, actual))
            if receipt.remaining == 0 then
                job.receipts[id] = nil
                local record = A.Settings().pending[id]
                if record and record.accepted == true then A.Release(id, record.units) end
            end
        end
    end
    if taking and not job.receipts[taking.itemID] then taking = nil end
    F.Refresh()
end

function F.Planned()
    if not A.PreferCrafting() then return end
    local outputs = Outputs()
    if not next(outputs) then return end
    local job = Job() or { version = 1, receipts = {}, outputs = {} }
    for parent, plan in pairs(outputs) do job.outputs[parent] = plan end
    A.Settings().followup = job
    F.Refresh()
end
function F.Clear()
    if A.transaction or A.state == "quoting" then return false end
    local mail = Flux.Mail
    if mail and mail.StopRestockItems then mail.StopRestockItems() end
    local settings = A.Settings()
    settings.pending, settings.followup, settings.vendorCraftPlans = {}, nil, nil
    busy, taking, buying, bankTargets = nil, nil, nil, {}
    automaticAttempt, requestedStage = nil, nil
    if A.ResetCraftPlans then A.ResetCraftPlans() end
    if Inv.Unregister then Inv.Unregister("AuctionRestock.Followup.Resume") end
    if Inv.UnregisterStormSettled then Inv.UnregisterStormSettled("AuctionRestock.Followup.Resume") end
    A.GetRows(true)
    if A.Invalidate then A.Invalidate("changed") end
    F.Refresh()
    if A.UpdateUI then A.UpdateUI() end
    return true
end

local function PlanRow(parent, plan, rows)
    local source
    for _, row in ipairs(rows) do
        if row.itemID == parent or row.itemID == (plan.row and plan.row.upgradeFrom or parent) then source = row; break end
    end
    if not source then return nil, "waiting" end
    if (source.baseTarget or source.target) ~= plan.target
        or (source.countBank == true) ~= (plan.countBank == true) or not A.PreferCrafting() then return nil, "invalid" end
    if A.PricePolicyMatches then
        if not A.PricePolicyMatches(parent, plan.cap, plan.capUnlimited) then return nil, "invalid" end
    elseif A.GetMaxPrice(parent) ~= plan.cap then return nil, "invalid" end
    if A.CraftBankFlagsMatch and not A.CraftBankFlagsMatch(plan) then return nil, "invalid" end
    local row = Copy(plan.row or source)
    row.target, row.countBank = plan.target, plan.countBank
    A.SetItemUnits(row)
    local ri = _G.FluxRestock and FluxRestock.Inv
    if row.countBank and ri and ri.Bank and ri.Bank.GetCount then row.bankCount = ri.Bank.GetCount(parent, { charges = row.isCharge }) end
    local need = A.Need(row)
    if need == 0 then return row, nil, need end -- completed goals need no recipe/provider reply
    local knowledge = A.SavedRecipeKnowledge and A.SavedRecipeKnowledge(plan, parent)
    if knowledge ~= true then return nil, knowledge == false and "invalid" or "waiting" end
    local saved = A.Settings().vendorCraftPlans
    saved = type(saved) == "table" and saved[parent]
    if type(saved) ~= "table" or saved.recipeName ~= plan.recipeName or saved.yield ~= plan.yield
        or (not plan.legacy and saved.recipeID ~= plan.recipeID) or not SameMap(saved.required, plan.required) then return nil, "waiting" end
    local savedKnowledge = A.SavedRecipeKnowledge(saved, parent)
    if savedKnowledge ~= true then return nil, savedKnowledge == false and "invalid" or "waiting" end
    return row, nil, need
end

local function CraftState(kind, tasks, active)
    local items, operations = {}, 0
    for _, task in ipairs(tasks) do
        items[task.parentID] = task.outputNeeded
        operations = operations + task.operations
    end
    local state = State(kind, items, active or tasks[1])
    state.quantity = operations
    return state
end
local function SettlingState(job)
    if currentJob ~= job or not current or (current.kind ~= "craft" and current.kind ~= "crafting")
        or not A.PreferCrafting() then return State("waiting", {}) end
    for id in pairs(current.items or {}) do
        local plan = job.outputs[id]
        if not plan or (A.PricePolicyMatches and not A.PricePolicyMatches(id, plan.cap, plan.capUnlimited))
            or (A.CraftBankFlagsMatch and not A.CraftBankFlagsMatch(plan))
            or (A.SavedRecipeKnowledge and A.SavedRecipeKnowledge(plan, id) == false) then return State("waiting", {}) end
    end
    -- Unknown inventory is not completion. Preserve only this job's known item
    -- presentation, with all commands and proc readiness explicitly disabled.
    local state = {}; for key, value in pairs(current) do state[key] = value end
    state.settling, state.canAct, state.contextOpen = true, false, false
    return state
end
local function Build(job)
    bankTargets = {}
    Reconcile(job)
    local takenBags = taking and Count(taking.itemID)
    if taking and takenBags and takenBags ~= taking.before then taking = nil end
    if buying and Count(buying.itemID) ~= buying.before then buying = nil end
    local incoming = {}
    for id, receipt in pairs(job.receipts) do if receipt.remaining > 0 then incoming[id] = receipt.remaining end end
    if next(incoming) then return State("mail", incoming) end
    if not next(job.outputs) then
        A.Settings().followup = nil; busy, taking, buying = nil, nil, nil
        return
    end
    if not A.IsInventoryReliable() then return SettlingState(job) end
    local rows = A.GetRows(true)
    local totals, auctionTotals, vendorTotals, prices, tasks = {}, {}, {}, {}, {}
    for _, parent in ipairs(IDs(job.outputs)) do
        local plan = job.outputs[parent]
        local row, reason, need = PlanRow(parent, plan, rows)
        if reason == "invalid" or need == 0 then job.outputs[parent] = nil
        elseif need then
            local task = Copy(plan)
            task.parentID, task.operations = parent, math.ceil(need / plan.yield)
            task.outputNeeded = task.operations * plan.yield
            tasks[#tasks + 1] = task
            for id, quantity in pairs(plan.required) do
                local required = task.operations * quantity
                totals[id] = (totals[id] or 0) + required
                if plan.prices[id] then
                    vendorTotals[id] = (vendorTotals[id] or 0) + required
                    prices[id] = math.min(prices[id] or math.huge, plan.prices[id])
                else auctionTotals[id] = (auctionTotals[id] or 0) + required end
            end
        end
    end
    if #tasks == 0 then
        if next(job.outputs) then return State("waiting", {}) end
        A.Settings().followup = nil; busy, taking, buying = nil, nil, nil
        return
    end
    if busy then
        local have = Count(busy.parentID)
        if have and have >= busy.before + busy.expected then busy = nil
        elseif busy.stopped and have and (not busy.awaiting or have >= busy.awaiting)
            and F.CraftIsBusy and not F.CraftIsBusy(busy.task) then busy = nil
        else
            local state = CraftState("crafting", tasks, busy.task)
            if busy.awaiting and (not have or have < busy.awaiting) then state.settling = true end
            return state
        end
    end
    local vendor, missing, bank = {}, {}, {}
    for id in pairs(totals) do
        local have = Count(id)
        if not have then return State("waiting", {}) end
        local available = A.GetCraftBagAvailable and A.GetCraftBagAvailable(id) or have
        local stored = A.GetCraftBankAvailable and A.GetCraftBankAvailable(id) or 0
        local fromBank = math.min(math.max(0, totals[id] - available), stored)
        if fromBank > 0 then
            bank[id] = fromBank
            bankTargets[#bankTargets + 1] = { itemID = id, name = Name(id), target = have + fromBank,
                mode = "stack", restock = true, auctionCraft = true, restockSource = "craftMaterial" }
            available = available + fromBank
        end
        local auction = auctionTotals[id] or 0
        local shortage = math.max(0, auction - available)
        if shortage > 0 then missing[id] = shortage end
        local vendorShortage = math.max(0, (vendorTotals[id] or 0) - math.max(0, available - auction))
        if vendorShortage > 0 then
            if prices[id] and (A.HasUnlimitedVendor or A.IsVendorItem)(id) then vendor[id] = vendorShortage
            else missing[id] = (missing[id] or 0) + vendorShortage end
        end
    end
    if next(bank) then return State("bank", bank) end
    -- Finish the planned auction quantities first. Buying vendor stock while
    -- those are missing would repeatedly allocate it to the auction routes.
    if next(missing) then return State("waiting", missing) end
    if next(vendor) then local state = State("vendor", vendor); state.prices = prices; return state end
    local task = tasks[1]
    if F.CraftIsBusy and F.CraftIsBusy(task) then return CraftState("crafting", tasks, task) end
    return CraftState("craft", tasks, task)
end

local function PublicCast(token, spellID)
    return not (issecretvalue and issecretvalue(token)) and type(token) == "string" and token ~= ""
        and N(spellID) and spellID > 0 and spellID % 1 == 0
end
local function ObserveCast(token, spellID)
    if not busy or busy.cast or not PublicCast(token, spellID)
        or (busy.observed or 0) >= busy.task.operations or (busy.seen and busy.seen[token]) or not UnitCastingInfo then return end
    local name, _, _, _, _, tradeSkill, castID, _, castingSpellID = UnitCastingInfo("player")
    if (issecretvalue and issecretvalue(tradeSkill)) or tradeSkill ~= true
        or not PublicCast(castID, castingSpellID) or castID ~= token or castingSpellID ~= spellID then return end
    local modernRecipe = not busy.task.legacy and N(busy.task.recipeID) and castingSpellID == busy.task.recipeID
    if not modernRecipe and ((issecretvalue and issecretvalue(name)) or type(name) ~= "string"
        or name ~= busy.task.recipeName) then return end
    local have = Count(busy.parentID)
    if have == nil then return end
    busy.cast = { token = token, spellID = spellID, before = have }
    busy.observed, busy.seen = (busy.observed or 0) + 1, busy.seen or {}
    busy.seen[token] = true
end
local function StopCast(token, spellID)
    local cast = busy and busy.cast
    if not cast or not PublicCast(token, spellID) or cast.token ~= token or cast.spellID ~= spellID then return end
    -- STOP is not success or inventory credit. This lower bound only keeps
    -- the submitted item disabled until actual owned output facts catch up.
    busy.awaiting = math.min(busy.before + busy.expected,
        math.max(busy.awaiting or busy.before, cast.before) + busy.task.yield)
    busy.cast = nil
end
local function StopBatch()
    local have = Count(busy.parentID)
    if busy.awaiting and (not have or have < busy.awaiting) then busy.stopped = true
    else busy = nil end
end
local function OnChange(event, unit, action, spellID)
    if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" or event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        local kinds = Enum and Enum.PlayerInteractionType
        if not kinds or (unit ~= kinds.Banker and unit ~= kinds.AccountBanker) then return end
        if event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then automaticAttempt, requestedStage = nil, nil end
    end
    if event:find("UNIT_SPELLCAST_", 1, true) == 1 then
        if (issecretvalue and issecretvalue(unit)) or unit ~= "player"
            or (not busy and (not current or current.kind ~= "crafting")) then return end
        if event == "UNIT_SPELLCAST_START" then ObserveCast(action, spellID); return end
        if event == "UNIT_SPELLCAST_STOP" then StopCast(action, spellID) end
    end
    if (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED") and unit == "player" then busy = nil end
    -- Closing a profession is not proof that its engine batch stopped. The
    -- modern native crafting page uses this explicit non-scrapping stop signal.
    if event == "UPDATE_TRADESKILL_CAST_STOPPED" and unit == false and busy and not busy.task.legacy
        and F.CraftIsBusy and not F.CraftIsBusy(busy.task) then StopBatch() end
    if event == "UNIT_SPELLCAST_STOP" and busy and busy.task.legacy
        and F.CraftIsBusy and not F.CraftIsBusy(busy.task) then StopBatch() end
    if (event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN") and busy
        and (unit == "_FluxUI" or unit == "UNKNOWN" or unit == nil) and type(action) == "string"
        and (action:find("CraftRecipe", 1, true) or action:find("DoTradeSkill", 1, true)
            or action:find("OpenTradeSkill", 1, true) or action:find("CastSpellByName", 1, true)) then busy = nil end
    if event == "MAIL_SHOW" then mailOpen = true elseif event == "MAIL_CLOSED" then mailOpen, taking = false, nil end
    if event == "MERCHANT_SHOW" then merchantOpen = true elseif event == "MERCHANT_CLOSED" then merchantOpen, buying = false, nil end
    if event == "MAIL_CLOSED" or event == "MERCHANT_CLOSED" or event == "BANKFRAME_CLOSED" then automaticAttempt, requestedStage = nil, nil end
    if event == "UI_ERROR_MESSAGE" then taking, buying = nil, nil; if dispatching then busy = nil end end
    F.Refresh()
end
local WATCH = { "BAG_UPDATE_DELAYED", "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "MERCHANT_SHOW", "MERCHANT_CLOSED",
    "MERCHANT_UPDATE", "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_LIST_UPDATE", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED", "UPDATE_TRADESKILL_CAST_STOPPED", "UI_ERROR_MESSAGE",
    "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "BANKFRAME_OPENED", "BANKFRAME_CLOSED",
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE", "PLAYER_MONEY" }
local function Listen(enabled)
    if listening == enabled then return end
    listening = enabled
    for _, event in ipairs(WATCH) do if enabled then Events.Register(event, OnChange) else Events.Unregister(event, OnChange) end end
    if enabled and Inv.Register then Inv.Register("AuctionRestock.Followup", F.Refresh, { tier = "light", regions = { "bags", "bank", "mail", "professions" } })
    elseif Inv.Unregister then Inv.Unregister("AuctionRestock.Followup") end
    -- Mail close/attachment publication can finish its existing bag-storm hold
    -- without another BAG_UPDATE. Resume from that owner's settled callback.
    if enabled and Inv.RegisterStormSettled then Inv.RegisterStormSettled("AuctionRestock.Followup", F.Refresh)
    elseif Inv.UnregisterStormSettled then Inv.UnregisterStormSettled("AuctionRestock.Followup") end
end
function F.GetState() return current end
function F.GetBankTargets()
    if not refreshing then F.Refresh() end
    return Copy(bankTargets)
end
function F.GetVendorTargets()
    -- A context/paint query must not restart Refresh through the vendor owner.
    -- Lifecycle notifications own publication; execution revalidates live needs.
    return current and current.kind == "vendor" and Copy(current.items) or {}
end
function F.Refresh()
    if refreshing or dispatching then return end
    if InCombatLockdown() then if F.Paint then F.Paint(nil) end; return end
    refreshing = true
    local job = Job()
    countMemo = { {}, {} }
    current = job and Build(job) or nil
    countMemo, currentJob = nil, Job()
    if not Job() then automaticAttempt, requestedStage = nil, nil end
    if automaticAttempt and current and current.kind ~= "waiting" and current.kind ~= automaticAttempt.kind then automaticAttempt = nil end
    if requestedStage and (not current or requestedStage ~= current.kind) then requestedStage = nil end
    if current then
        current.contextOpen = F.IsContextOpen(current.kind)
        current.canAct = F.CanAct(current)
    end
    if not job then bankTargets = {} end
    local goals = {}
    for _, entry in ipairs(bankTargets) do goals[entry.itemID] = entry.target end
    if not SameMap(goals, publishedBankGoals) then
        publishedBankGoals = goals
        local bank = _G.FluxBankRestock
        if bank and bank.InvalidateCanRunCache then bank.InvalidateCanRunCache() end
        if bank and bank.RunFastButtonRefresh then bank.RunFastButtonRefresh() end
    end
    Listen(Job() ~= nil)
    refreshing = nil
    if F.Paint then F.Paint(current) end
    local state = current
    local sameAttempt = state and automaticAttempt and automaticAttempt.kind == state.kind
        and SameMap(automaticAttempt.items, state.items)
        and (automaticAttempt.submitted or SameMap(automaticAttempt.facts, AttemptFacts()))
    if state and not state.settling and state.contextOpen and (state.kind == "mail" or state.kind == "bank" or state.kind == "vendor")
        and (requestedStage == state.kind or F.IsAutoEnabled() and not sameAttempt) then
        dispatching = true
        local result = Dispatch(state, requestedStage == state.kind)
        dispatching = nil
        if result ~= "busy" then
            requestedStage = nil
            automaticAttempt = { kind = state.kind, items = Copy(state.items), submitted = result == true, facts = AttemptFacts() }
            F.Refresh()
        end
    end
end

Dispatch = function(state, manual)
    if not F.IsContextOpen(state.kind) then return false end
    if state.kind == "mail" then
        local mail = Flux.Mail
        return mail and mail.TakeRestockItems and mail.TakeRestockItems() or false
    elseif state.kind == "vendor" then
        local vendor = _G.FluxVendorAuto
        if vendor and vendor.DoAuctionFollowup then return vendor.DoAuctionFollowup(manual) end
        return false
    elseif state.kind == "bank" then
        local bank = _G.FluxBankRestock
        if bank and bank.RunAuctionFollowup then return bank.RunAuctionFollowup(manual) end
        return false
    end
end

function F.Click()
    if InCombatLockdown() then return end
    F.Refresh()
    local ri = _G.FluxRestock and FluxRestock.Inv
    if not current or current.kind ~= "mail" then
        if not ri or not ri.IsReliable or not ri.IsReliable() or (Inv.IsBagStorm and Inv.IsBagStorm()) then return end
    end
    local state = current
    if not state or state.settling then return end
    if automaticAttempt and automaticAttempt.submitted and automaticAttempt.kind == state.kind
        and SameMap(automaticAttempt.items, state.items) then return end
    dispatching = true
    if state.kind == "mail" or state.kind == "vendor" or state.kind == "bank" then
        local result = Dispatch(state, true)
        requestedStage = result == "busy" and state.kind or nil
        if result ~= "busy" then automaticAttempt = { kind = state.kind, items = Copy(state.items), submitted = result == true, facts = AttemptFacts() } end
    elseif state.kind == "craft" and F.CraftClick then
        local task = state.task
        local attempt = { parentID = task.parentID, before = Count(task.parentID) or 0,
            expected = task.operations * task.yield, task = task }
        busy = attempt
        local status, operations = F.CraftClick(task)
        if busy == attempt then
            if status == "crafting" and operations and operations > 0 then busy.expected = operations * task.yield else busy = nil end
        end
    end
    dispatching = nil
    F.Refresh()
end
function F.Resume()
    if Job() then
        if Inv.Unregister then Inv.Unregister("AuctionRestock.Followup.Resume") end
        if Inv.UnregisterStormSettled then Inv.UnregisterStormSettled("AuctionRestock.Followup.Resume") end
        F.Refresh(); return
    end
    -- A selected saved recipe may need only bank/vendor inputs. Restore it as
    -- well as acknowledged receipts; unrelated cached mail never creates work.
    local job = { version = 1, receipts = {}, outputs = {} }
    if next(A.Settings().vendorCraftPlans or {}) and not A.IsInventoryReliable() then
        if Inv.Register then Inv.Register("AuctionRestock.Followup.Resume", F.Resume,
            { tier = "light", regions = { "bags", "bank", "mail", "professions" } }) end
        if Inv.RegisterStormSettled then Inv.RegisterStormSettled("AuctionRestock.Followup.Resume", F.Resume) end
        return
    end
    for id, record in pairs(A.Settings().pending) do
        if type(record) == "table" and record.accepted == true and (N(record.units) or 0) > 0 and not Count(id) then
            if Inv.Register then Inv.Register("AuctionRestock.Followup.Resume", F.Resume,
                { tier = "light", regions = { "bags", "mail", "professions" } }) end
            if Inv.RegisterStormSettled then Inv.RegisterStormSettled("AuctionRestock.Followup.Resume", F.Resume) end
            return
        end
    end
    if Inv.Unregister then Inv.Unregister("AuctionRestock.Followup.Resume") end
    if Inv.UnregisterStormSettled then Inv.UnregisterStormSettled("AuctionRestock.Followup.Resume") end
    A.RefreshMailFacts()
    for id, record in pairs(A.Settings().pending) do
        if type(record) == "table" and record.accepted == true and (N(record.units) or 0) > 0 then
            local row = A.SetItemUnits({ itemID = id })
            local have, physical = Count(id, row.isCharge), Count(id)
            if row.unitsPerItem and (record.unitScale or not row.isCharge) and have and physical then
                local incoming = A.MailUnits(row) + math.max(0, A.Pending(row, have) - A.PredictedMailUnits(row))
                if incoming > 0 then job.receipts[id] = { remaining = math.ceil(incoming / row.unitsPerItem), lastBags = physical } end
            end
        end
    end
    if not next(job.receipts) and not next(A.Settings().vendorCraftPlans or {}) then F.Refresh(); return end
    local rows = A.GetRows(true)
    for parent, saved in pairs(A.Settings().vendorCraftPlans or {}) do
        if type(saved) == "table" then
            local source
            for _, row in ipairs(rows) do
                if row.itemID == parent or row.itemID == saved.sourceID then source = row; break end
            end
            -- Restore the exact previously selected facts, even before the
            -- profession provider answers. PlanRow validates provenance and
            -- configuration before a stage can authorize its owner queue.
            local output = Copy(source or { name = saved.parentName, target = saved.target, countBank = saved.countBank })
            output.itemID = parent
            if saved.sourceID ~= parent then output.upgradeFrom = saved.sourceID end
            local recipe = { recipeID = saved.recipeID, name = saved.recipeName, skillName = saved.skillName,
                skillLineID = saved.skillLineID, legacy = saved.legacy, yield = saved.yield,
                required = type(saved.required) == "table" and saved.required or {}, allocation = saved.allocation }
            local vendorItems = {}; for id in pairs(saved.prices or {}) do vendorItems[id] = true end
            local restored = Snapshot(parent, output, { recipe = recipe, targetAtPlan = saved.target,
                countBankAtPlan = saved.countBank, capAtPlan = saved.cap, capUnlimitedAtPlan = saved.capUnlimited,
                bankFlags = saved.bankFlags, vendorItems = vendorItems, vendorPrices = saved.prices })
            restored.prices, restored.recipeVerified, restored.recipeOwner = Copy(saved.prices or {}), saved.recipeVerified, saved.recipeOwner
            job.outputs[parent] = restored
        end
    end
    A.Settings().followup = job
    F.Refresh()
end
Events.Register("PLAYER_LOGIN", F.Resume)
