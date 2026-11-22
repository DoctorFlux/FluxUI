-- Persist this restock's receipts and selected recipes. Mail/vendor/bank work
-- stays with its existing owner; only the exact craft is dispatched here.
local _, ns = ...
local A, Flux = FluxAuctionRestock, ns.Flux
local Inv, Events = Flux.Inventory, Flux.Events
local F = {}
A.Followup = F
local N = A.Number

-- Share the defining carried-count query; replacements keep fresh options.
local carriedRestockRecord = rawget(ns, "RestockCarriedLiveQuery")
local carriedRestockFlux = rawget(ns, "Flux")
local carriedRestockGetter, carriedRestockQuery
if type(carriedRestockRecord) == "table" and type(carriedRestockFlux) == "table"
    and rawequal(rawget(carriedRestockRecord, "namespace"), ns)
    and rawequal(rawget(carriedRestockRecord, "flux"), carriedRestockFlux) then
    local getter = rawget(carriedRestockRecord, "getter")
    local query = rawget(carriedRestockRecord, "query")
    if type(getter) == "function" and type(query) == "function" then
        carriedRestockGetter, carriedRestockQuery = getter, query
    end
end

local listening, refreshing, dispatching, current
local currentJob, countMemo
local logisticsCraft, currentCraftProvider
local companionBagSettlePending
local professionAction, professionWindowAction
local professionWindowListeners = {}
local pendingNativeCraft
local nativeCraftRefresh = {}
local observedNativePages = {}
local logisticsIncoming, logisticsMailTaken = {}, {}
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
    local value = ri.GetLiveCount
    if value then
        local getLiveCount = ri.GetLiveCount
        if carriedRestockQuery and getLiveCount == carriedRestockGetter then
            value = N(carriedRestockQuery(id, charges == true))
        else
            value = N(getLiveCount(id, {
                bags = true, bank = false, warband = false, equipped = false, charges = charges == true,
            }))
        end
    end
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
local function SameCraftTask(a, b)
    return a and b and a.parentID == b.parentID and a.recipeID == b.recipeID and a.recipeName == b.recipeName
        and a.skillLineID == b.skillLineID and a.skillName == b.skillName and a.legacy == b.legacy
        and a.operations == b.operations and a.yield == b.yield and SameMap(a.required, b.required)
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

local function PositiveInteger(value)
    local number = N(value)
    return number and number > 0 and number % 1 == 0
end

local function PublicKey(value)
    return not (issecretvalue and issecretvalue(value)) and type(value) == "string" and value ~= ""
end

local function LogisticsVendorState()
    local provider = logisticsCraft
    if not provider or not provider.GetVendorStage or A.transaction or A.ownsQuote or A.state == "quoting" then return end
    local ok, stage = pcall(provider.GetVendorStage)
    if not ok or type(stage) ~= "table" or type(stage.items) ~= "table" or not PublicKey(stage.key) then return end
    local items = {}
    for id, quantity in pairs(stage.items) do
        if not PositiveInteger(id) or not PositiveInteger(quantity) then return end
        items[id] = quantity
    end
    if not next(items) then return end
    local state = State("vendor", items)
    state.vendorProvider, state.vendorKey = provider, stage.key
    state.contextOpen = not (issecretvalue and issecretvalue(stage.canBuy)) and stage.canBuy == true
    return state
end

local function LogisticsCraftState()
    if not logisticsCraft or A.transaction or A.ownsQuote or A.state == "quoting" then return end
    if logisticsCraft.GetPreparedNativeCraft then
        local ok, prepared = pcall(logisticsCraft.GetPreparedNativeCraft)
        if ok and type(prepared) == "table" and PositiveInteger(prepared.itemID)
            and PositiveInteger(prepared.quantity) and PositiveInteger(prepared.outputQuantity) then
            local state = State("craft", { [prepared.itemID] = prepared.outputQuantity })
            state.quantity, state.nativeCraftPrepared, state.logisticsPrepared = prepared.quantity, prepared.quantity, true
            return state
        end
    end
    local ok, ready = pcall(logisticsCraft.GetReady)
    if not ok or type(ready) ~= "table" or not PositiveInteger(ready.jobId)
        or not PublicKey(ready.taskId) or not PublicKey(ready.planRevision)
        or not PositiveInteger(ready.itemID) or not PositiveInteger(ready.quantity)
        or not PositiveInteger(ready.outputQuantity) then return end
    local state = State("craft", { [ready.itemID] = ready.outputQuantity })
    state.quantity = ready.quantity
    state.logistics = { jobId = ready.jobId, taskId = ready.taskId, planRevision = ready.planRevision,
        itemID = ready.itemID, quantity = ready.quantity, outputQuantity = ready.outputQuantity }
    if not (issecretvalue and issecretvalue(ready.direct)) and ready.direct == true then
        state.logistics.direct = true
    end
    if issecretvalue and issecretvalue(ready.resume) then return end
    if PublicKey(ready.resume) and PositiveInteger(ready.carriedOutput) and N(ready.remainingOutput)
        and ready.remainingOutput >= 0 and ready.remainingOutput % 1 == 0 then
        state.logistics.resume = ready.resume
        state.logistics.carriedOutput, state.logistics.remainingOutput = ready.carriedOutput, ready.remainingOutput
    elseif ready.resume ~= nil then
        return
    end
    currentCraftProvider = logisticsCraft
    return state
end

local function NativeProfessionAction(job)
    local task = current and current.kind == "craft" and not current.settling and current.task
    local plan = task and job and job.outputs[task.parentID]
    if not plan or not F.GetProfessionToOpen then return end
    local target = F.GetProfessionToOpen(plan)
    if not target then return end
    local state = State("profession", { [task.parentID] = 1 })
    state.name = PublicKey(target.name) and target.name or state.name
    state.profession, state.plan, state.canAct = target, plan, true
    return state
end

local function LogisticsProfessionAction()
    local provider = logisticsCraft
    if not provider or not provider.GetProfession then return end
    local ok, ready = pcall(provider.GetProfession)
    if not ok or type(ready) ~= "table" or not PositiveInteger(ready.jobId)
        or not PublicKey(ready.taskId) or not PublicKey(ready.planRevision) or not PositiveInteger(ready.itemID)
        or not PositiveInteger(ready.quantity) or not PositiveInteger(ready.outputQuantity)
        or not PositiveInteger(ready.professionID) then return end
    local state = State("profession", { [ready.itemID] = 1 })
    local name = PublicKey(ready.professionName) and ready.professionName or state.name
    local queueSwitch = not (issecretvalue and issecretvalue(ready.queueSwitch)) and ready.queueSwitch == true
    state.name, state.provider, state.canAct = name, provider, true
    state.profession = { id = ready.professionID, name = name }
    -- The tracked queue opener needs the original physical click, not a spell overlay.
    if not queueSwitch and F.GetProfessionSpell then
        state.profession.spellID = F.GetProfessionSpell(ready.professionID)
    end
    state.logistics = { jobId = ready.jobId, taskId = ready.taskId, planRevision = ready.planRevision,
        itemID = ready.itemID, quantity = ready.quantity, outputQuantity = ready.outputQuantity,
        professionID = ready.professionID, professionName = name, queueSwitch = queueSwitch or nil }
    return state
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
    if not state.companionMail and not state.vendorProvider and automaticAttempt
        and automaticAttempt.submitted and automaticAttempt.kind == state.kind
        and SameMap(automaticAttempt.items, state.items) then return false end
    if state.kind == "auction" then return state.offer == A.GetFollowupOffer() end
    if state.kind == "craft" then
        if state.logisticsPrepared then return false end
        if state.logistics then
            return currentCraftProvider == logisticsCraft and not A.transaction and not A.ownsQuote
                and A.IsInventoryReliable()
        end
        if not F.CanCraft then return false end
        local canCraft, operations = F.CanCraft(state.task)
        return canCraft == true, operations
    end
    if not state.contextOpen or not next(state.items or {}) then return false end
    if state.kind == "mail" then
        local mail = Flux.Mail
        return mail and mail.CanTakeRestockItems and mail.CanTakeRestockItems(state.companionMail) == true or false
    elseif state.kind == "vendor" then
        if state.vendorProvider then return state.vendorProvider == logisticsCraft and A.IsInventoryReliable() == true end
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
function F.GetMailItems(companion)
    if companion then
        local items = {}
        for id, quantity in pairs(logisticsIncoming) do
            local remaining = quantity - (logisticsMailTaken[id] or 0)
            if remaining > 0 then items[id] = remaining end
        end
        return items
    end
    local job, items = Job(), {}
    if job then
        Reconcile(job)
        for id, receipt in pairs(job.receipts) do
            if receipt.remaining > 0 then items[id] = receipt.remaining end
        end
    end
    return items
end
function F.LogisticsMailTaken(id, quantity)
    local incoming = logisticsIncoming[id]
    if incoming and PositiveInteger(quantity) then
        logisticsMailTaken[id] = math.min(incoming, (logisticsMailTaken[id] or 0) + quantity)
    end
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
    if currentJob ~= job or not current or current.logistics or (current.kind ~= "craft" and current.kind ~= "crafting")
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
    local waiting
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
        else waiting = true end
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
    if waiting then return State("waiting", {}) end
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
local function CompanionNativeCraftBusy()
    local check = logisticsCraft and logisticsCraft.IsNativeCraftBusy
    if not check then return false end
    local ok, occupied = pcall(check)
    if not ok and geterrorhandler then geterrorhandler()(occupied) end
    return not ok or occupied == true
end
local function ScheduleNativeCraftBatch(stockReset)
    local pending = pendingNativeCraft
    if not pending then return end
    if stockReset then pending.stockReset = true end
    if pending.refreshQueued or not (C_Timer and C_Timer.After) then return end
    -- The native event handlers can reset the field while updating their form.
    pending.refreshQueued = true
    C_Timer.After(0, function()
        pending.refreshQueued = nil
        if pendingNativeCraft == pending then F.Refresh(nativeCraftRefresh) end
    end)
end
local function ObserveNativeCraftPage(page)
    if not hooksecurefunc or observedNativePages[page] then return end
    observedNativePages[page] = true
    if type(page.SetupMultipleInputBox) == "function" then
        hooksecurefunc(page, "SetupMultipleInputBox", function()
            if pendingNativeCraft and pendingNativeCraft.page == page then ScheduleNativeCraftBatch(true) end
        end)
    end
    local input = page.CreateMultipleInputBox
    if input and type(input.SetValue) == "function" then
        hooksecurefunc(input, "SetValue", function()
            local pending = pendingNativeCraft
            if pending and pending.page == page and not pending.writing then ScheduleNativeCraftBatch() end
        end)
    end
    if type(page.CreateInternal) == "function" then
        hooksecurefunc(page, "CreateInternal", function()
            if not pendingNativeCraft or pendingNativeCraft.page ~= page then return end
            pendingNativeCraft = nil
            -- A native press consumes the preparation. Only carried output
            -- advances ordinary Restock.
            if C_Timer and C_Timer.After then C_Timer.After(0, F.Refresh) end
        end)
    end
end
local function UpdateNativeCraftBatch(state, wake)
    if state and not state.logisticsPrepared then state.nativeCraftPrepared = nil end
    local pending = pendingNativeCraft
    if not pending then return end
    if not state or not state.nativeCraft or currentJob ~= pending.job
        or (pending.expires and GetTime() > pending.expires)
        or not SameCraftTask(pending.task, state.task) then
        pendingNativeCraft = nil
        return
    end
    local recipeID, quantity = F.GetNativeCraftSelection(pending.page)
    if pending.prepared and recipeID and recipeID ~= pending.task.recipeID then
        pendingNativeCraft = nil
        return
    end
    if wake then
        if CompanionNativeCraftBusy() then pendingNativeCraft = nil; return end
        local reset = pending.stockReset
        if pending.prepared and recipeID == pending.task.recipeID and quantity ~= pending.prepared and not reset then
            -- Respect the amount chosen directly in Blizzard's controls.
            pendingNativeCraft = nil
            return
        end
        if state.canAct and recipeID == pending.task.recipeID and (not pending.prepared or reset) then
            pending.writing = true
            pending.stockReset = nil
            pending.prepared = F.SetNativeCraftBatch(pending.page, recipeID,
                math.min(pending.operations, state.nativeCraftOperations))
            pending.writing = nil
            if pending.prepared then
                pending.operations, quantity = pending.prepared, pending.prepared
            end
        end
    end
    if state.canAct and recipeID == pending.task.recipeID and quantity == pending.prepared then
        state.nativeCraftPrepared = pending.prepared
        if pending.prepared then state.canAct = false end
    end
end
local function RefreshAfterStorm()
    F.Refresh()
    ScheduleNativeCraftBatch()
end

local function RefreshCompanionWhenBagsSettle(state)
    if not state.logistics or state.kind ~= "craft" or state.canAct or companionBagSettlePending
        or not Inv.OnStormSettled or not (Inv.IsBagStorm and Inv.IsBagStorm()) then return end
    -- Companion-only orders do not install the standalone job's storm listener.
    companionBagSettlePending = true
    Inv.OnStormSettled(function()
        companionBagSettlePending = nil
        if logisticsCraft and not listening then F.Refresh() end
    end)
end

local function OnChange(event, unit, action, spellID)
    if event == "OPEN_RECIPE_RESPONSE" then
        if pendingNativeCraft and N(unit) == pendingNativeCraft.task.recipeID then ScheduleNativeCraftBatch() end
        return
    end
    if event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" or event == "BAG_UPDATE_DELAYED" then
        ScheduleNativeCraftBatch()
    end
    if event == "TRADE_SKILL_CLOSE" or (event == "TRADE_SKILL_DATA_SOURCE_CHANGING"
        and pendingNativeCraft and pendingNativeCraft.prepared) then pendingNativeCraft = nil end
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
    "MERCHANT_UPDATE", "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED",
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED", "UPDATE_TRADESKILL_CAST_STOPPED", "UI_ERROR_MESSAGE",
    "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "BANKFRAME_OPENED", "BANKFRAME_CLOSED",
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE", "PLAYER_MONEY" }
local function Listen(enabled)
    if listening == enabled then return end
    listening = enabled
    for _, event in ipairs(WATCH) do if enabled then Events.Register(event, OnChange) else Events.Unregister(event, OnChange) end end
    if F.UsesNativeCraftHandoff and F.UsesNativeCraftHandoff() then
        for _, event in ipairs({ "OPEN_RECIPE_RESPONSE", "TRADE_SKILL_DATA_SOURCE_CHANGING" }) do
            if enabled then Events.Register(event, OnChange) else Events.Unregister(event, OnChange) end
        end
    end
    if enabled and Inv.Register then Inv.Register("AuctionRestock.Followup", F.Refresh, { tier = "light", regions = { "bags", "bank", "mail", "professions" } })
    elseif Inv.Unregister then Inv.Unregister("AuctionRestock.Followup") end
    -- Mail close/attachment publication can finish its existing bag-storm hold
    -- without another BAG_UPDATE. Resume from that owner's settled callback.
    if enabled and Inv.RegisterStormSettled then Inv.RegisterStormSettled("AuctionRestock.Followup", RefreshAfterStorm)
    elseif Inv.UnregisterStormSettled then Inv.UnregisterStormSettled("AuctionRestock.Followup") end
end
function F.GetState() return current end
function F.GetProfessionWindowAction() return professionWindowAction end

local function PublishProfessionWindowAction(state)
    if state and (state.settling or state.kind ~= "craft" and state.kind ~= "crafting"
        and state.kind ~= "profession") then state = nil end
    local previous = professionWindowAction
    if previous == state or previous and state and previous.kind == state.kind
        and previous.name == state.name and previous.quantity == state.quantity and previous.canAct == state.canAct
        and previous.nativeCraft == state.nativeCraft and previous.nativeCraftPrepared == state.nativeCraftPrepared
        and previous.nativeCraftOperations == state.nativeCraftOperations and previous.plan == state.plan
        and previous.provider == state.provider and SameMap(previous.items, state.items)
        and (not previous.task and not state.task or SameCraftTask(previous.task, state.task))
        and (not previous.profession and not state.profession or SameMap(previous.profession, state.profession))
        and (not previous.logistics and not state.logistics or SameMap(previous.logistics, state.logistics)) then return end
    professionWindowAction = state
    for listener in pairs(professionWindowListeners) do
        local ok, err = pcall(listener, state)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end
end

function F.RegisterProfessionWindowListener(listener)
    if type(listener) ~= "function" then return false end
    professionWindowListeners[listener] = true
    return true
end

function F.UnregisterProfessionWindowListener(listener)
    professionWindowListeners[listener] = nil
end

function F.ClickProfessionWindowAction(shown)
    if not shown or shown ~= professionWindowAction or shown.canAct ~= true or shown.nativeCraftPrepared then return end
    if shown.kind == "profession" then return F.ClickProfession(professionAction) end
    return F.Click()
end

function F.GetBankTargets()
    if not refreshing then F.Refresh() end
    return Copy(bankTargets)
end
function F.GetVendorTargets()
    -- A context/paint query must not restart Refresh through the vendor owner.
    -- Lifecycle notifications own publication; execution revalidates live needs.
    return current and current.kind == "vendor" and not current.vendorProvider and Copy(current.items) or {}
end
function F.Refresh(reason)
    if refreshing or dispatching then return end
    if InCombatLockdown() then
        PublishProfessionWindowAction(nil)
        if F.Paint then F.Paint(nil) end
        return
    end
    refreshing = true
    local job = Job()
    -- Only Build consumes these per-refresh counts. An idle job query has
    -- no counts to memoize, including the bank button's read path.
    countMemo = job and { {}, {} } or nil
    current = job and Build(job) or nil
    countMemo, currentJob = nil, job and Job()
    currentCraftProvider = nil
    if not current or current.kind == "waiting" then
        local offer = A.GetFollowupOffer and A.GetFollowupOffer()
        if offer then
            current = State("auction", { [offer.itemID] = offer.quantity })
            current.offer = offer
        elseif next(logisticsIncoming) then
            current = State("mail", Copy(logisticsIncoming))
            current.companionMail = true
        else
            current = LogisticsVendorState() or LogisticsCraftState() or current
        end
    end
    if not currentJob then automaticAttempt, requestedStage = nil, nil end
    if automaticAttempt and current and current.kind ~= "waiting" and current.kind ~= automaticAttempt.kind then automaticAttempt = nil end
    if requestedStage and (not current or requestedStage ~= current.kind) then requestedStage = nil end
    if current then
        if not current.vendorProvider then current.contextOpen = F.IsContextOpen(current.kind) end
        local canAct, operations = F.CanAct(current)
        current.canAct = canAct
        RefreshCompanionWhenBagsSettle(current)
        if current.kind == "craft" and F.UsesNativeCraftHandoff
            and not (current.logistics and (current.logistics.direct or current.logistics.resume)) then
            current.nativeCraft = F.UsesNativeCraftHandoff() == true and not (current.task and current.task.legacy)
            if current.nativeCraft then
                current.nativeCraftOperations = current.nativeCraftPrepared or current.logistics and current.logistics.quantity
                    or operations or (current.task and current.task.operations)
            end
        end
    end
    UpdateNativeCraftBatch(current, reason == nativeCraftRefresh)
    if not job and next(bankTargets) then bankTargets = {} end
    local hadBankGoals = next(publishedBankGoals) ~= nil
    if hadBankGoals or next(bankTargets) then
        local goals = {}
        for _, entry in ipairs(bankTargets) do goals[entry.itemID] = entry.target end
        if not SameMap(goals, publishedBankGoals) then
            publishedBankGoals = goals
            local bank = _G.FluxBankRestock
            if bank and bank.InvalidateCanRunCache then bank.InvalidateCanRunCache() end
            if bank and bank.RunFastButtonRefresh then bank.RunFastButtonRefresh() end
        end
    end
    -- An idle pass with no published goals has run no job-changing callbacks.
    Listen((job ~= nil or hadBankGoals) and Job() ~= nil)
    professionAction = nil
    local kind = current and current.kind
    if not busy and not A.transaction and not A.ownsQuote and A.state ~= "quoting"
        and not (current and (current.logisticsPrepared or current.settling))
        and (not kind or kind == "waiting" or kind == "craft") then
        professionAction = NativeProfessionAction(currentJob)
        if not professionAction and (kind ~= "craft" or current.logistics) then
            professionAction = LogisticsProfessionAction()
        end
    end
    PublishProfessionWindowAction(professionAction or current)
    refreshing = nil
    if F.Paint then F.Paint(professionAction or current) end
    local state = current
    local sameAttempt = state and automaticAttempt and automaticAttempt.kind == state.kind
        and SameMap(automaticAttempt.items, state.items)
        and (automaticAttempt.submitted or SameMap(automaticAttempt.facts, AttemptFacts()))
    if state and not state.companionMail and not state.vendorProvider and not state.settling and state.contextOpen
        and (state.kind == "mail" or state.kind == "bank" or state.kind == "vendor")
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

function F.RefreshLogistics()
    local incoming = {}
    if logisticsCraft and logisticsCraft.GetIncoming then
        local ok, items = pcall(logisticsCraft.GetIncoming)
        if ok and type(items) == "table" then
            for id, quantity in pairs(items) do
                if PositiveInteger(id) and PositiveInteger(quantity) then incoming[id] = quantity end
            end
        end
    end
    for id, taken in pairs(logisticsMailTaken) do
        -- The queue retires receipts when its carried observation settles.
        local confirmed = math.max(0, (logisticsIncoming[id] or 0) - (incoming[id] or 0))
        logisticsMailTaken[id] = taken > confirmed and taken - confirmed or nil
    end
    local changed = not SameMap(logisticsIncoming, incoming)
    logisticsIncoming = incoming
    F.Refresh()
    local mail = Flux.Mail
    if changed and mail and mail.NotifyRestockTargetsChanged then mail.NotifyRestockTargetsChanged() end
end

function F.RegisterLogisticsCraft(provider)
    if provider ~= nil and (type(provider) ~= "table" or type(provider.GetReady) ~= "function"
        or type(provider.Process) ~= "function"
        or provider.GetPreparedNativeCraft ~= nil and type(provider.GetPreparedNativeCraft) ~= "function"
        or provider.GetIncoming ~= nil and type(provider.GetIncoming) ~= "function"
        or provider.RevealNativeCraft ~= nil and type(provider.RevealNativeCraft) ~= "function"
        or provider.IsNativeCraftBusy ~= nil and type(provider.IsNativeCraftBusy) ~= "function"
        or (provider.GetVendorStage ~= nil or provider.BuyVendorStage ~= nil)
            and (type(provider.GetVendorStage) ~= "function" or type(provider.BuyVendorStage) ~= "function")
        or (provider.GetProfession ~= nil or provider.OpenProfession ~= nil)
            and (type(provider.GetProfession) ~= "function" or type(provider.OpenProfession) ~= "function")) then return false end
    logisticsCraft = provider and { GetReady = provider.GetReady, Process = provider.Process, GetIncoming = provider.GetIncoming,
        GetVendorStage = provider.GetVendorStage, BuyVendorStage = provider.BuyVendorStage,
        GetProfession = provider.GetProfession, OpenProfession = provider.OpenProfession, RevealNativeCraft = provider.RevealNativeCraft,
        IsNativeCraftBusy = provider.IsNativeCraftBusy, GetPreparedNativeCraft = provider.GetPreparedNativeCraft }
    logisticsMailTaken = {}
    F.RefreshLogistics()
    return true
end

function F.RevealCompanionNativeCraft(recipeID, operations)
    if logisticsCraft and logisticsCraft.RevealNativeCraft then
        local ok, revealed, reason = pcall(logisticsCraft.RevealNativeCraft, recipeID, operations)
        if ok then return revealed == true, reason end
        if geterrorhandler then geterrorhandler()(revealed) end
    end
    return false
end

function F.ClickProfession(shown)
    if not shown or shown ~= professionAction or InCombatLockdown() then return end
    F.Refresh()
    local state = professionAction
    if not state or shown.plan ~= state.plan or shown.provider ~= state.provider
        or not SameMap(shown.profession, state.profession)
        or (shown.logistics and not SameMap(shown.logistics, state.logistics)) then return end
    local action = state.provider and state.provider.OpenProfession or F.OpenProfessionTarget
    dispatching = true
    local ok, err = pcall(action, state.logistics and Copy(state.logistics) or state.profession)
    dispatching = nil
    F.Refresh()
    if not ok and geterrorhandler then geterrorhandler()(err) end
end

Dispatch = function(state, manual)
    if not F.IsContextOpen(state.kind) then return false end
    if state.kind == "mail" then
        local mail = Flux.Mail
        return mail and mail.TakeRestockItems and mail.TakeRestockItems(state.companionMail) or false
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
    local shown = current
    if not shown then return end
    local displayed = shown.logistics
    local displayedProvider = currentCraftProvider
    if shown.companionMail then F.RefreshLogistics() else F.Refresh() end
    local state = current
    if not state or state.settling or shown.kind ~= state.kind or shown.companionMail ~= state.companionMail
        or shown.vendorProvider ~= state.vendorProvider then return end
    if shown.nativeCraftPrepared or state.nativeCraftPrepared then return end
    if state.kind == "auction" then
        if shown.offer ~= state.offer or not F.CanAct(state) then return end
        A.ClickFollowupOffer(shown.offer)
        return
    end
    local ri = _G.FluxRestock and FluxRestock.Inv
    if state.kind ~= "mail" then
        if not ri or not ri.IsReliable or not ri.IsReliable() or (Inv.IsBagStorm and Inv.IsBagStorm()) then return end
    end
    if state.vendorProvider then
        if shown.vendorKey ~= state.vendorKey or not SameMap(shown.items, state.items) or not F.CanAct(state) then return end
        dispatching = true
        local ok, err = pcall(state.vendorProvider.BuyVendorStage, state.vendorKey)
        dispatching = nil
        F.Refresh()
        if not ok and geterrorhandler then geterrorhandler()(err) end
        return
    end
    if displayed or state.logistics then
        -- A refresh may repaint this button for a different job. This press
        -- belongs to the exact companion task the player could already see.
        if not displayed or not state.logistics or displayedProvider ~= currentCraftProvider
            or not SameMap(displayed, state.logistics) or not F.CanAct(state) then return end
        dispatching = true
        local ok, err = pcall(currentCraftProvider.Process, Copy(state.logistics))
        dispatching = nil
        F.Refresh()
        if not ok and geterrorhandler then geterrorhandler()(err) end
        return
    end
    if not SameMap(shown.items, state.items) then return end
    if not state.companionMail and automaticAttempt and automaticAttempt.submitted and automaticAttempt.kind == state.kind
        and SameMap(automaticAttempt.items, state.items) then return end
    dispatching = true
    if state.kind == "mail" or state.kind == "vendor" or state.kind == "bank" then
        local result = Dispatch(state, true)
        if not state.companionMail then
            requestedStage = result == "busy" and state.kind or nil
            if result ~= "busy" then automaticAttempt = { kind = state.kind, items = Copy(state.items), submitted = result == true, facts = AttemptFacts() } end
        end
    elseif state.kind == "craft" and F.CraftClick and SameCraftTask(shown.task, state.task) then
        local task = state.task
        pendingNativeCraft = nil
        local attempt = { parentID = task.parentID, before = Count(task.parentID) or 0,
            expected = task.operations * task.yield, task = task }
        busy = attempt
        local status, operations, page, prepared = F.CraftClick(task)
        if status == "native_click" and page then
            pendingNativeCraft = { task = task, job = currentJob, operations = operations, page = page,
                prepared = prepared, expires = GetTime and GetTime() + 60 }
            ObserveNativeCraftPage(page)
            if not prepared then ScheduleNativeCraftBatch() end
        end
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
