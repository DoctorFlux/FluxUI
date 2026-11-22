local _, ns = ...
local Flux = ns.Flux
local Policy = { version = 1 }
Flux.RestockPolicy = Policy

local revision = 0
local listeners = {}
local planner
local changesQueued = false
local changeReason
local demandCache
local supplyReservations
local craftMaterialIDs = {}
local emptySettings = {}
local strength = { normal = 1, openworld = 2, raid = 3 }

Policy.Text = {
    normal = "Normal",
    openworld = "Open world",
    raid = "Raid/dungeon",
    all = "All modes",
    managed = "Passive restock",
    enabled = "Preset restock enabled",
    restock = "Order restock",
    craft = "Craft missing",
    view = "View plan",
    plans = "Restock plans",
    trigger = "Refill when below %d",
    plan = "FluxLogistics",
    chooseThreshold = "Refill when below",
    tierLocked = "No qualified item for this tier is available.",
    noTargets = "No restock targets in this mode.",
    shopping = "Accepted auction shopping",
    shoppingEntry = "%s × %d  (Plan %s)",
    materialQuantity = "%s × %d",
    bankReceiptPending = "%s  •  %d waiting for bags",
    shoppingReady = "Native auction search filled for %s. Accepted quantity still needed: %d.",
    shoppingMore = "More accepted requirements are listed in the crafting queue.",
    shoppingChanged = "That auction requirement changed. Review your plan.",
    auctionUnavailable = "Open the Auction House to look up this item.",
    itemLoading = "The item name is still loading.",
    ready = "%s  %d/%d ready, %d covered, %d missing",
    busy = "Another inventory action is still running.",
    unavailable = "FluxLogistics is unavailable.",
    unseen = "Inventory has not finished updating.",
    satisfied = "This restock target is covered.",
    changed = "The supply offer changed. Review the plan before continuing.",
    unsupported = "This acquisition requires a different supply context.",
    declined = "The plan changed. Review it before continuing.",
    failed = "The restock action could not start.",
}

local function Amount(value)
    local number = tonumber(value)
    if not number or number ~= number or number <= 0 or number == math.huge then return 0 end
    return math.floor(number)
end

local function Settings(write)
    local saved = _G._FluxUI_CharSavedVars
    if not write then
        return type(saved) == "table" and type(saved.RestockPolicy) == "table" and saved.RestockPolicy or emptySettings
    end
    if type(saved) ~= "table" then
        saved = {}
        _G._FluxUI_CharSavedVars = saved
    end
    if type(saved.RestockPolicy) ~= "table" then saved.RestockPolicy = {} end
    return saved.RestockPolicy
end

local function Inventory()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

function Policy.GetMode()
    local mode = Settings().mode
    return strength[mode] and mode or "normal"
end

function Policy.GetRevision()
    return revision
end

function Policy.Subscribe(key, callback)
    if type(key) == "string" then
        listeners[key] = type(callback) == "function" and callback or nil
    end
end

function Policy.NotifyChanged(reason)
    revision = revision + 1
    demandCache, supplyReservations = nil, nil
    if changeReason ~= "settings" then changeReason = reason or "settings" end
    if changesQueued then return end
    changesQueued = true
    local function Notify()
        changesQueued = false
        local initialReason = changeReason
        changeReason = nil
        for _, callback in pairs(listeners) do
            local ok, err = pcall(callback, revision, initialReason)
            if not ok and geterrorhandler then geterrorhandler()(err) end
        end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0, Notify) else Notify() end
end

function Policy.SetMode(mode)
    if not strength[mode] then return false end
    if mode ~= Policy.GetMode() then
        Settings(true).mode = mode
        Policy.NotifyChanged()
    end
    return true
end

function Policy.GetManaged()
    return Settings().managed == true
end

function Policy.SetManaged(enabled)
    enabled = enabled == true
    if Policy.GetManaged() ~= enabled then
        Settings(true).managed = enabled
        Policy.NotifyChanged()
    end
    return true
end

function Policy.IsPlannerRegistered()
    return planner ~= nil
end

function Policy.AllowsPassive()
    -- Existing FluxUI automation remains available when FluxLogistics is absent.
    return not planner or Policy.GetMode() ~= "normal" and Policy.GetManaged()
end

function Policy.IncludesMode(membership, mode, legacyActive)
    if type(membership) ~= "table" then return legacyActive == true end
    if membership.all == true then return true end
    local rank = strength[mode]
    if not rank then return false end
    for member, threshold in pairs(strength) do
        if membership[member] == true and rank >= threshold then return true end
    end
    return false
end

function Policy.RuleID(entry)
    local tier = entry and entry.tierKind
    if tier then return "tier:" .. tostring(tier) end
    local itemID = entry and tonumber(entry.itemID)
    if itemID and itemID > 0 then return "item:" .. tostring(itemID) end
end

-- Read-only quantity resolver. Each coverage identity can be counted once.
-- A transfer out of the counted bank cannot add coverage to a bags+bank target.
function Policy.Resolve(rule, ready, bank, coverage)
    ready, bank = Amount(ready), rule.countBank and Amount(bank) or 0
    local target = Amount(rule.target)
    local trigger = rule.trigger and math.min(target, Amount(rule.trigger)) or target
    local accepted, seen = 0, {}
    for _, allocation in ipairs(coverage or {}) do
        local id = allocation.id
        if id and (not rule.countBank or allocation.kind ~= "bank")
            and (not allocation.units or allocation.units == rule.units)
            and (not allocation.demandId or allocation.demandId == rule.id) then
            local quantity = Amount(allocation.quantity)
            local previous = seen[id] or 0
            if quantity > previous then
                accepted = accepted + quantity - previous
                seen[id] = quantity
            end
        end
    end
    local uncovered = math.max(0, target - ready - bank - accepted)
    return uncovered, accepted, ready, bank, trigger, uncovered > 0 and (ready + bank < trigger or accepted > 0)
end

local function Copy(entry)
    local result = {}
    for key, value in pairs(entry) do result[key] = value end
    return result
end

local function Coverage(rule, entry, ownerQuantity)
    local result = {}
    local auction = _G.FluxAuctionRestock
    -- An explicit pending count belongs to the row's actual listing SKU.
    -- A tier can plan its next purchase using a different preferred item.
    local ownerItemID = ownerQuantity ~= nil and (entry.itemID or entry.merchantItemID) or rule.itemID
    if ownerQuantity == nil and auction and auction.GetPolicyCoverage and rule.itemID
        and not (entry.policyExactItems and entry.policyExactItems[rule.itemID]) then
        ownerQuantity = auction.GetPolicyCoverage(entry, rule.units, rule.itemID)
    end
    if ownerQuantity and ownerQuantity > 0 then
        result[1] = { id = "auction:" .. rule.id, quantity = ownerQuantity, units = rule.units, kind = "auction" }
    end
    if planner and planner.GetCoverage then
        local allocations = planner.GetCoverage(rule, ownerQuantity, ownerItemID)
        for _, allocation in ipairs(allocations or {}) do result[#result + 1] = allocation end
    end
    return result
end

local function CurrentActor()
    local guid = UnitGUID and UnitGUID("player")
    if guid and (not issecretvalue or not issecretvalue(guid)) and guid ~= "" then return guid end
    local name = UnitName and UnitName("player")
    local realm = GetNormalizedRealmName and GetNormalizedRealmName()
    if not realm or realm == "" then realm = GetRealmName and GetRealmName() end
    if name and realm then return name .. "-" .. realm end
end

function Policy.GetActor()
    return CurrentActor()
end

function Policy.GetTrigger(id)
    local triggers = Settings().triggers
    return triggers and triggers[id]
end

function Policy.SetTrigger(id, value)
    if type(id) ~= "string" then return false end
    if value ~= nil and (type(value) ~= "number" or value ~= 0 and value ~= Amount(value)) then return false end
    local settings = Settings(true)
    settings.triggers = settings.triggers or {}
    if settings.triggers[id] ~= value then
        settings.triggers[id] = value
        Policy.NotifyChanged()
    end
    return true
end

function Policy.DemandForEntry(entry, ownerQuantity)
    local id = Policy.RuleID(entry)
    if not id then return nil end
    local tiers = _G.FluxRestockTiers
    local itemID = entry.itemID or entry.merchantItemID
    local rules = _G.FluxRestockItemRegistry
    local charges = entry.isCharge or entry.mode == "charge"
    if not charges and not entry.tierKind and itemID and rules and rules.IsChargeItem then
        charges = rules.IsChargeItem(itemID)
    end
    local flags = itemID and not entry.tierKind and _G.FluxVendorAuto
        and _G.FluxVendorAuto.GetRestockItemFlags and _G.FluxVendorAuto.GetRestockItemFlags(itemID)
    local rule = {
        id = id, itemID = itemID, tierKind = entry.tierKind, name = entry.name,
        owner = entry.restockSource or (entry.tierKind and "tier" or "manual"),
        revision = revision, actorKey = CurrentActor(), destination = "bags",
        countBank = entry.countBank == true, units = charges and "charge" or "item",
        bankRestock = flags and flags.bankRestock or false, bankStash = flags and flags.bankStash or false,
        target = Amount(entry.target), trigger = Policy.GetTrigger(id), mode = Policy.GetMode(),
        maxPrice = entry.maxPrice,
    }
    if rule.tierKind and tiers then
        rule.target = Amount(tiers.GetTarget and tiers.GetTarget(rule.tierKind) or rule.target)
        if tiers.GetCountBankFlag then rule.countBank = tiers.GetCountBankFlag(rule.tierKind) == true end
        local best = _G.FluxConsumableBest
        local ref = best and best.GetBestRef and best.GetBestRef(rule.tierKind)
        rule.itemID = ref and not ref.isConjured and ref.itemID or itemID
        rule.eligible = tiers.ItemMatchesRestockKind
        if rule.itemID and rule.eligible and not rule.eligible(rule.tierKind, rule.itemID) then
            rule.itemID = nil
        end
        -- The tier's owner authorizes withdrawals by target and strict
        -- restock threshold, independently of exact-item settings.
        rule.bankRestock = rule.itemID ~= nil and rule.target > 0
            and tiers.IsTierEligible and tiers.IsTierEligible(rule.tierKind)
            and tiers.StackMatchesBankRestockKind
            and tiers.StackMatchesBankRestockKind(rule.tierKind, rule.itemID) == true or false
    end
    local ready = math.max(0, Amount(entry.bagCount) - Amount(entry.policyTierOffset))
    local stored = math.max(0, Amount(entry.bankCount) - Amount(entry.policyTierBankOffset))
    rule.uncovered, rule.covered, rule.ready, rule.bank, rule.trigger, rule.passive =
        Policy.Resolve(rule, ready, stored, Coverage(rule, entry, ownerQuantity))
    return rule
end

-- Allocate overlapping ready stock to the exact requirement before broader
-- tiers. A compatible item in excess of its exact target can serve one tier.
function Policy.ApplyTierOverlap(entries, matches)
    if not matches then return end
    local tiers = {}
    for _, entry in ipairs(entries) do
        if entry.isTierRestock and Amount(entry.target) > 0 then
            entry.policyTierOffset, entry.policyTierBankOffset, entry.policyExactItems = 0, 0, {}
            tiers[#tiers + 1] = entry
        end
    end
    for _, entry in ipairs(entries) do
        if not entry.isTierRestock and entry.itemID and Amount(entry.target) > 0 then
            for _, tier in ipairs(tiers) do
                if matches(tier.tierKind, entry.itemID) then
                    tier.policyExactItems[entry.itemID] = true
                    local bags = Amount(entry.physicalBagCount or entry.bagCount)
                    local reserve = entry.isCharge and bags or math.min(bags, Amount(entry.target))
                    tier.policyTierOffset = tier.policyTierOffset + reserve
                    if entry.countBank and tier.countBank and not entry.isCharge then
                        local bank = Amount(entry.bankCount)
                        tier.policyTierBankOffset = tier.policyTierBankOffset
                            + math.min(bank, math.max(0, Amount(entry.target) - reserve))
                    end
                    break
                end
            end
        end
    end
end

function Policy.GetDemands(opts)
    local manual = opts and opts.manual == true
    local inv = Inventory()
    if not inv or not inv.IsReliable or not inv.IsReliable() then return {}, Policy.Text.unseen end
    local owner = _G.FluxVendorAuto
    if not owner or not owner.GetRestockTargetItems then return {}, Policy.Text.unavailable end
    if not demandCache then
        demandCache = {}
        for _, entry in ipairs(owner.GetRestockTargetItems({ policyOnly = true })) do
            local rule = Policy.DemandForEntry(entry)
            if rule and rule.target > 0 then demandCache[#demandCache + 1] = rule end
        end
    end
    local result = {}
    for _, rule in ipairs(demandCache) do
        if manual or Policy.AllowsPassive() and rule.passive then
            result[#result + 1] = Copy(rule)
        end
    end
    return result
end

function Policy.GetDemand(id)
    local results = Policy.GetDemands({ manual = true })
    for _, rule in ipairs(results) do
        if rule.id == id then return rule end
    end
end

local function SameCraftMaterials(left, right)
    for itemID in pairs(left) do
        if not right[itemID] then return false end
    end
    for itemID in pairs(right) do
        if not left[itemID] then return false end
    end
    return true
end

local function UpdateCraftMaterials()
    local getMaterials = planner and planner.GetCraftMaterialIDs
    if type(getMaterials) ~= "function" then return end
    local items = getMaterials()
    if type(items) ~= "table" or items == craftMaterialIDs then return end
    local changed = not SameCraftMaterials(craftMaterialIDs, items)
    craftMaterialIDs = items
    if not changed then return end
    local junk = _G.FluxVendorJunk
    if junk and junk.OnCraftMaterialProtectionChanged then junk.OnCraftMaterialProtectionChanged() end
end

function Policy.IsCraftMaterialProtected(itemID)
    return craftMaterialIDs[itemID] == true
end

function Policy.RegisterPlanner(provider)
    if type(provider) ~= "table" or type(provider.GetCoverage) ~= "function"
        or type(provider.Request) ~= "function" or planner and planner ~= provider then
        return false
    end
    planner = provider
    UpdateCraftMaterials()
    Policy.NotifyChanged()
    return true
end

function Policy.NotifyCoverageChanged()
    UpdateCraftMaterials()
    Policy.NotifyChanged("coverage")
end

function Policy.GetReservedSupply(kind, itemID)
    if not planner or not planner.GetRequirements then return 0 end
    if not supplyReservations then
        supplyReservations = {}
        for _, requirement in ipairs(planner.GetRequirements() or {}) do
            local key = tostring(requirement.kind) .. ":" .. tostring(requirement.itemID)
            supplyReservations[key] = (supplyReservations[key] or 0) + Amount(requirement.quantity)
        end
    end
    return supplyReservations[tostring(kind) .. ":" .. tostring(itemID)] or 0
end


local requestsInProgress = {}
function Policy.Request(id, action, context)
    if not planner then return false, Policy.Text.unavailable end
    if action ~= "restock" and action ~= "craft" and action ~= "view" then return false, Policy.Text.unsupported end
    local manual = not context or context.manual ~= false
    if not manual and not Policy.AllowsPassive() then return false, Policy.Text.unsupported end
    demandCache = nil
    local rule = Policy.GetDemand(id)
    if not rule then return false, Policy.Text.unseen end
    if action ~= "view" and rule.tierKind and not rule.itemID then return false, Policy.Text.tierLocked end
    if action ~= "view" and (rule.uncovered <= 0 or not manual and not rule.passive) then
        return false, Policy.Text.satisfied
    end
    if requestsInProgress[id] or action ~= "view" and Policy.IsWorkflowBusy() then
        return false, Policy.Text.busy
    end
    requestsInProgress[id] = true
    local called, ok, message = pcall(planner.Request, rule, action, context or { manual = true })
    requestsInProgress[id] = nil
    if not called then
        if geterrorhandler then geterrorhandler()(ok) end
        return false, Policy.Text.failed
    end
    if ok and action ~= "view" then
        -- Refresh synchronously before another entry point can order the same deficit.
        Policy.NotifyChanged("coverage")
    end
    return ok, message
end

function Policy.IsWorkflowBusy(source)
    local bank = _G.FluxBankRestock
    local vendor = _G.FluxVendorAuto
    local auction = _G.FluxAuctionRestock
    return (source ~= "bank" and bank and bank.IsRunning and bank.IsRunning())
        or (source ~= "vendor" and vendor and vendor.IsAuctionFollowupBusy and vendor.IsAuctionFollowupBusy())
        or (source ~= "auction" and auction and auction.transaction ~= nil)
        or (source ~= "planner" and planner and planner.IsWorkflowBusy and planner.IsWorkflowBusy())
        or false
end

local function Status(message)
    if message and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(Policy.Text.plan .. "  " .. message)
    end
end

local function EditTrigger(rule)
    if not StaticPopupDialogs or not StaticPopup_Show then return end
    StaticPopupDialogs.FLUX_RESTOCK_TRIGGER = {
        text = Policy.Text.chooseThreshold,
        button1 = ACCEPT or "Accept",
        button2 = CANCEL or "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(frame, data)
            local field = frame.editBox or frame.EditBox
            field:SetNumeric(true)
            field:SetMaxLetters(6)
            field:SetText(data.trigger)
            field:HighlightText()
        end,
        OnAccept = function(frame, data)
            local field = frame.editBox or frame.EditBox
            local value = tonumber(field:GetText())
            if value and value >= 0 and value <= data.target then Policy.SetTrigger(data.id, value) end
        end,
    }
    StaticPopup_Show("FLUX_RESTOCK_TRIGGER", nil, nil, rule)
end

Policy.Report = Status

local function IsAuctionRequirement(entry)
    return entry and (entry.kind == "buy" or entry.kind == "auction")
end

function Policy.GetAcquisitionRequirements(surface)
    local result = {}
    if (surface ~= "bank" and surface ~= "vendor") or not planner or not planner.GetRequirements then return result end
    local source = planner.GetAcquisitionRequirements and planner.GetAcquisitionRequirements(surface) or planner.GetRequirements()
    for _, entry in ipairs(source or {}) do
        local job = entry.job
        local pending, quantity = entry.pending == true, Amount(entry.quantity)
        local acquisition = job and job.acquisition
        if surface == "vendor" and acquisition and acquisition.kind == "vendor" and acquisition.index == entry.id then
            pending = true
            quantity = math.min(quantity, Amount(acquisition.quantity) - Amount(acquisition.credited))
        end
        if entry.kind == surface and job and job.status == "queued" and (not acquisition or pending)
            and job.id and entry.id and Amount(entry.itemID) > 0 and quantity > 0 then
            result[#result + 1] = {itemID = entry.itemID, quantity = quantity,
                jobId = job.id, id = entry.id, kind = surface, planRevision = job.planRevision, pending = pending,
                groupKey = type(entry.groupKey) == "string" and entry.groupKey or nil, groupCount = entry.groupCount}
        end
    end
    return result
end

function Policy.AcquireRequirement(surface, selection)
    if not planner or not planner.AcquireRequirement or not selection then return false, Policy.Text.unavailable end
    if Policy.IsWorkflowBusy() then return false, Policy.Text.busy end
    for _, entry in ipairs(Policy.GetAcquisitionRequirements(surface)) do
        if not entry.pending and entry.jobId == selection.jobId and entry.id == selection.id and entry.itemID == selection.itemID
            and entry.quantity == selection.quantity and entry.planRevision == selection.planRevision
            and entry.groupKey == selection.groupKey then
            return planner.AcquireRequirement(surface, entry)
        end
    end
    return false, Policy.Text.shoppingChanged
end

function Policy.CanBuyVendorRequirements()
    if not planner or Policy.IsWorkflowBusy() then return false end
    if planner.GetVendorStage then
        local stage = planner.GetVendorStage()
        return stage and stage.canBuy == true or false
    end
    for _, entry in ipairs(Policy.GetAcquisitionRequirements("vendor")) do
        if not entry.pending then return true end
    end
    return false
end

function Policy.BuyVendorRequirements()
    if not planner or Policy.IsWorkflowBusy() then return false end
    if planner.BuyVendorRequirements then return planner.BuyVendorRequirements(false) end
    for _, entry in ipairs(Policy.GetAcquisitionRequirements("vendor")) do
        if not entry.pending then return Policy.AcquireRequirement("vendor", entry) end
    end
    return false
end

function Policy.GetShoppingRequirements(surface)
    local result = {}
    if surface ~= "auction" or not planner then return result end
    local projection = planner.GetShoppingRequirements
    if type(projection) ~= "function" then projection = planner.GetRequirements end
    if type(projection) ~= "function" then return result end
    for _, entry in ipairs(projection() or {}) do
        local itemID = Amount(entry.itemID)
        local quantity = Amount(entry.quantity)
        local jobId = entry.job and entry.job.id
        if IsAuctionRequirement(entry) and jobId and entry.id and itemID > 0 and quantity > 0 then
            result[#result + 1] = {
                itemID = itemID, quantity = quantity, jobId = jobId, id = entry.id, kind = entry.kind,
                planRevision = entry.job.planRevision,
            }
        end
    end
    return result
end

local function CurrentAuctionRequirement(entry)
    if not IsAuctionRequirement(entry) then return end
    local jobId = entry.jobId or entry.job and entry.job.id
    local expected = entry.planRevision or entry.job and entry.job.planRevision
    for _, candidate in ipairs(Policy.GetShoppingRequirements("auction")) do
        if candidate.jobId == jobId and candidate.id == entry.id and candidate.itemID == entry.itemID
            and candidate.quantity == entry.quantity and (expected == nil or expected == candidate.planRevision) then
            return candidate
        end
    end
end

function Policy.OpenAuctionRequirement(entry)
    local current = CurrentAuctionRequirement(entry)
    if not current then return false, Policy.Text.shoppingChanged end
    if Policy.IsWorkflowBusy() then return false, Policy.Text.busy end
    local auction = _G.FluxAuctionRestock
    if not auction or not auction.PrepareLogisticsSearch then return false, Policy.Text.auctionUnavailable end
    local ok, name = auction.PrepareLogisticsSearch(current.itemID)
    if not ok then return false, name end
    return true, Policy.Text.shoppingReady:format(name, current.quantity)
end

function Policy.CreateActions(parent, surface)
    local dropdowns = _G.FluxBlizzardDropdown
    if not dropdowns or not dropdowns.Create then return nil end
    local dropdown = dropdowns.Create(parent, "FluxLogisticsRestock" .. surface, 144)
    dropdown:FluxSetText(Policy.Text.plans)
    dropdown:FluxSetMenu(function()
        local entries = {}
        local shopping = Policy.GetShoppingRequirements(surface)
        if #shopping > 0 then
            local items = {}
            local itemClass = _G.FluxItemClass
            for index = 1, math.min(24, #shopping) do
                local item = shopping[index]
                local name = itemClass and itemClass.GetName and itemClass.GetName(item.itemID)
                items[#items + 1] = {
                    text = Policy.Text.shoppingEntry:format(name or item.itemID, item.quantity, item.jobId),
                    func = function()
                        local _, message
                        if planner and type(planner.OpenAuctionShopping) == "function" then
                            local current = CurrentAuctionRequirement(item)
                            if current then _, message = planner.OpenAuctionShopping(parent, current)
                            else message = Policy.Text.shoppingChanged end
                        else
                            _, message = Policy.OpenAuctionRequirement(item)
                        end
                        Status(message)
                    end,
                }
            end
            if #shopping > 24 then items[#items + 1] = { text = Policy.Text.shoppingMore, disabled = true } end
            entries[1] = { text = Policy.Text.shopping, submenu = items, submenuId = "auction-shopping" }
        end
        local demands, reason = Policy.GetDemands({ manual = true })
        for _, rule in ipairs(demands) do
            local planStatus = planner and planner.GetPlanStatus and planner.GetPlanStatus(rule)
            local children = {}
            if planStatus then children[#children + 1] = { text = planStatus, disabled = true } end
            for _, action in ipairs({ "restock", "craft", "view" }) do
                children[#children + 1] = {
                    text = Policy.Text[action],
                    disabled = action ~= "view" and rule.uncovered == 0,
                    func = function()
                        local _, message = Policy.Request(rule.id, action, { source = surface, manual = true })
                        Status(message)
                    end,
                }
            end
            children[#children + 1] = {
                text = Policy.Text.trigger:format(rule.trigger),
                func = function() EditTrigger(rule) end,
            }
            entries[#entries + 1] = {
                text = Policy.Text.ready:format(rule.name or rule.id, rule.ready, rule.target, rule.covered, rule.uncovered),
                submenu = children, submenuId = rule.id,
            }
        end
        if #entries == 0 then entries[1] = { text = reason or Policy.Text.noTargets, disabled = true } end
        return entries
    end)
    dropdown:SetShown(Policy.IsPlannerRegistered())
    Policy.Subscribe("actions:" .. surface, function() dropdown:SetShown(Policy.IsPlannerRegistered()) end)
    return dropdown
end

function Policy.GetVendorPriceEstimate(itemID)
    if type(itemID) ~= "number" or itemID <= 0 or Amount(itemID) ~= itemID then return nil end
    local owner = _G.FluxAuctionRestock
    if not owner or not owner.VendorSource or not owner.VendorTerms then return nil end
    local unlimited, price, profile, provenance = owner.VendorSource(itemID)
    if unlimited ~= true then return nil end
    local bundlePrice, bundleSize = owner.VendorTerms(itemID)
    if Amount(bundlePrice) <= 0 or Amount(bundlePrice) ~= bundlePrice
        or Amount(bundleSize) <= 0 or Amount(bundleSize) ~= bundleSize
        or price ~= bundlePrice / bundleSize then return nil end
    return {
        itemID = itemID, unit = "item", unitPrice = price,
        bundlePrice = bundlePrice, bundleSize = bundleSize,
        source = "vendor", profile = profile, provenance = provenance, estimate = true,
    }
end

function Policy.GetAcquisitions(itemID, actorKey)
    local actor = CurrentActor()
    itemID = Amount(itemID)
    if not actor or actorKey and actorKey ~= actor or itemID <= 0 then return {} end
    local inv = Inventory()
    if not inv or not inv.IsReliable or not inv.IsReliable() then return {} end
    local result = {}
    local vendor = _G.FluxVendorAuto
    local offer = vendor and vendor.GetLogisticsOffer and vendor.GetLogisticsOffer(itemID)
    if offer then
        offer.actorKey = actor
        result[#result + 1] = offer
    end
    local bank = inv.Bank
    if bank and bank.IsLive and bank.IsLive() then
        local available = Amount(bank.GetCount(itemID, { bank = true, warband = false, allowCached = false }))
        if available > 0 then
            local location = "bank:" .. actor
            result[#result + 1] = {
                offerId = location .. ":" .. itemID, kind = "bank", itemID = itemID,
                actorKey = actor, locationKey = location, qualified = true, unit = "item",
                bundleSize = 1, bundlePrice = 0, availableUnits = available,
                marketContext = location, revision = bank.GetGeneration and bank.GetGeneration(),
            }
        end
    end
    return result
end

function Policy.AllowsAutomaticVendorPurchase()
    local vendor = _G.FluxVendorAuto
    return not (vendor and vendor.AllowsLogisticsAutomaticPurchase) or vendor.AllowsLogisticsAutomaticPurchase() == true
end

function Policy.ExecuteAcquisition(offer, quantity, validate)
    if type(offer) ~= "table" or type(validate) ~= "function" or Amount(quantity) ~= quantity or quantity <= 0 then
        return false, Policy.Text.unsupported
    end
    if offer.actorKey ~= CurrentActor() or InCombatLockdown and InCombatLockdown()
        or GetCursorInfo and GetCursorInfo() or Policy.IsWorkflowBusy("planner") then
        return false, Policy.Text.busy
    end
    if not validate(offer, quantity) then return false, Policy.Text.declined end
    for _, current in ipairs(Policy.GetAcquisitions(offer.itemID, offer.actorKey)) do
        if current.offerId == offer.offerId and current.marketContext == offer.marketContext
            and current.bundleSize == offer.bundleSize and current.bundlePrice == offer.bundlePrice
            and (not current.availableUnits or current.availableUnits >= quantity) then
            if current.kind == "vendor" and _G.FluxVendorAuto.BuyForLogistics then
                return _G.FluxVendorAuto.BuyForLogistics(current, quantity, validate)
            end
            if current.kind == "bank" and _G.FluxBankRestock and _G.FluxBankRestock.StartLogistics then
                return _G.FluxBankRestock.StartLogistics(current, quantity, validate)
            end
        end
    end
    return false, Policy.Text.changed
end

-- Passive order creation is opt-in for the activity mode. It commits the
-- same plans as a manual request but never runs their physical actions.
local managedPass
local function CanRunManagedRestock()
    return planner and Policy.AllowsPassive() and not Policy.IsWorkflowBusy()
        and not (InCombatLockdown and InCombatLockdown())
end

local function RunManagedRestockBatch(pass)
    if pass ~= managedPass or pass.running or pass.scheduled then return end
    if pass.mode ~= Policy.GetMode() or not CanRunManagedRestock() then
        managedPass = nil
        return
    end

    pass.running = true
    local visited, more = 0, false
    -- Read current eligible rules on each batch. Stable IDs let processing
    -- continue when refreshed coverage changes the list's order or length.
    for _, rule in ipairs(Policy.GetDemands()) do
        if not pass.considered[rule.id] then
            if visited == 12 then
                more = true
                break
            end
            visited = visited + 1
            pass.considered[rule.id] = true
            Policy.Request(rule.id, "restock", { manual = false, source = "mode" })
        end
    end
    pass.running = nil
    if pass ~= managedPass then return end
    if not more then
        managedPass = nil
    elseif C_Timer and C_Timer.After then
        pass.scheduled = true
        C_Timer.After(0, function()
            pass.scheduled = nil
            RunManagedRestockBatch(pass)
        end)
    end
end

Policy.Subscribe("FluxLogisticsManagedDemand", function(_, reason)
    if reason == "coverage" then return end
    if not CanRunManagedRestock() then
        managedPass = nil
        return
    end
    local mode = Policy.GetMode()
    if not managedPass or managedPass.mode ~= mode then
        managedPass = { mode = mode, considered = {} }
    end
    RunManagedRestockBatch(managedPass)
end)

local inv = Flux.Inventory
if inv and inv.RegisterListener then
    inv.RegisterListener("FluxRestockPolicy", function()
        if planner then Policy.NotifyChanged("inventory") else demandCache = nil end
    end, { tier = "light", regions = { "bags", "bank", "warband", "mail", "spells" } })
end
