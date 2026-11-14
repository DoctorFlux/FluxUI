-- Learned-recipe price comparison. Information queries only; never crafts/buys.
local _, ns = ...
local A, Inv = FluxAuctionRestock, ns.Flux.Inventory
local N = A.Number
local plans = {}
A.craftPlans = plans
local decisions, booksCache, recipeCache = {}, {}, {}
A.craftDecisions, A.priceBooks = decisions, booksCache
local pricing
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok then return value end
end
local function Paint() if A.UpdateUI then A.UpdateUI() end end

local function RecipeItem(row)
    if row.isCraftMaterial then return false end
    local ic = _G.FluxItemClass
    local class = ic and ic.GetClassID and ic.GetClassID(row.itemID)
    local subclass = ic and ic.GetSubClassID and ic.GetSubClassID(row.itemID)
    -- Same item-class contracts already used by Inventory.Craft/Classify.
    return class == 0 and (subclass == 1 or subclass == 7)
end

local function CopyMap(source)
    local copy = {}; for id, quantity in pairs(source) do copy[id] = quantity end; return copy
end
local function Integer(value)
    return N(value) and value > 0 and value % 1 == 0
end
local function Contains(list, id)
    for _, value in ipairs(list or {}) do if value == id then return true end end
end

local function NativeRecipeContext(raw)
    if raw.legacy or not C_TradeSkillUI then return false end
    local ts = C_TradeSkillUI
    local frame = _G.ProfessionsFrame or _G.TradeSkillFrame
    if not frame or Read(frame.IsShown, frame) ~= true then return false end
    for _, query in pairs({ IsTradeSkillLinked, ts.IsTradeSkillLinked, ts.IsTradeSkillGuild, ts.IsNPCCrafting }) do
        if type(query) == "function" and Read(query) ~= false then return false end
    end
    if ts.IsDataSourceChanging and Read(ts.IsDataSourceChanging) ~= false then return false end
    if ts.IsTradeSkillReady and Read(ts.IsTradeSkillReady) ~= true then return false end
    local prof = Inv and Inv.Professions
    local info = prof and Read(prof.GetOpenProfessionInfo)
    if type(info) ~= "table" then return false end
    local id = N(raw.skillLineID)
    if id and id > 0 then
        return N(info.professionID) == id or N(info.parentProfessionID) == id or N(info.skillLineID) == id
    end
    -- Old character records may only have the localized profession name.
    local name = raw.skillName
    return type(name) == "string" and name ~= "" and (name == info.parentProfessionName
        or name == info.professionName or name == info.displayName)
end

local function Variants(raw, outputID)
    -- A closed/wrong profession can return learned=false or a stale schematic.
    -- Only the matching open owned profession may supersede this character's
    -- saved facts; comparison never opens a profession to obtain that context.
    local ts = NativeRecipeContext(raw) and C_TradeSkillUI or nil
    local info = ts and Read(ts.GetRecipeInfo, raw.recipeID)
    if info and info.learned == false then return {} end
    if not info or info.learned ~= true then ts, info = nil, nil end
    local saved = raw.craftingData
    local incomplete = type(saved) == "table" and saved.version == 1 and saved.complete == false
    if type(saved) ~= "table" or saved.version ~= 1 or saved.complete ~= true then saved = nil end
    if not info and saved then info = { learned = true, supportsQualities = saved.supportsQualities } end
    if info and info.learned ~= true then return {} end
    local qualityIDs = (not raw.legacy and ts and Read(ts.GetRecipeQualityItemIDs, raw.recipeID)) or (saved and saved.qualityItemIDs)
    if raw.outputItemID ~= outputID and not Contains(qualityIDs, outputID) then return {} end
    local nativeSchematic = not raw.legacy and ts and Read(ts.GetRecipeSchematic, raw.recipeID, false)
    if incomplete and not nativeSchematic then return {} end
    local schematic = nativeSchematic or (saved and saved.schematic)
    local yield = schematic and schematic.quantityMin or raw.quantityMin or raw.outputPerCraft
    if not Integer(yield) then return {} end
    local slots = {}
    if schematic and type(schematic.reagentSlotSchematics) == "table" then
        local basic = Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic
        for _, slot in ipairs(schematic.reagentSlotSchematics) do
            local required = slot.required == true or (N(slot.quantityRequired) or 0) > 0
            if required then
                if basic and slot.reagentType ~= basic then return {} end
                if not Integer(slot.quantityRequired) or not Integer(slot.dataSlotIndex) then return {} end
                local options = {}
                for _, reagent in ipairs(slot.reagents or {}) do
                    if not Integer(reagent.itemID) then return {} end
                    options[#options + 1] = reagent.itemID
                end
                if #options == 0 then return {} end
                slots[#slots + 1] = { options = options, count = slot.quantityRequired, index = slot.dataSlotIndex }
            end
        end
    else
        -- Flat cached recipes are sufficient only for deterministic, non-quality outputs.
        if not raw.legacy and not info then return {} end
        if qualityIDs and #qualityIDs > 1 or (info and info.supportsQualities) then return {} end
        for index, reagent in ipairs(raw.reagents or {}) do
            if not Integer(reagent.itemID) or not Integer(reagent.count) then return {} end
            slots[#slots + 1] = { options = { reagent.itemID }, count = reagent.count, index = index }
        end
    end
    if #slots == 0 then return {} end
    local variants = { { required = {}, allocation = {}, recipeID = raw.recipeID, yield = yield, name = raw.name } }
    for _, slot in ipairs(slots) do
        local nextSet = {}
        for _, variant in ipairs(variants) do
            for _, id in ipairs(slot.options) do
                if #nextSet >= 64 then return {} end
                local nextVariant = { required = CopyMap(variant.required), allocation = {}, recipeID = raw.recipeID, yield = yield, name = raw.name }
                for i, allocation in ipairs(variant.allocation) do nextVariant.allocation[i] = allocation end
                nextVariant.required[id] = (nextVariant.required[id] or 0) + slot.count
                nextVariant.allocation[#nextVariant.allocation + 1] = { reagent = { itemID = id }, dataSlotIndex = slot.index, quantity = slot.count }
                nextSet[#nextSet + 1] = nextVariant
            end
        end
        variants = nextSet
    end
    local verified = {}
    for _, variant in ipairs(variants) do
        local output = raw.outputItemID
        local quality = (qualityIDs and #qualityIDs > 1) or (info and info.supportsQualities)
        local fixedSavedOutput = saved and not nativeSchematic and not quality and raw.outputItemID == outputID
            and (schematic.outputItemID == nil or schematic.outputItemID == outputID)
        if schematic and (quality or (schematic.hasCraftingOperationInfo and not fixedSavedOutput)) then
            local operation = ts and Read(ts.GetCraftingOperationInfo, raw.recipeID, variant.allocation, nil, false)
            if not operation then output = nil
            else
                local qualityID = operation.guaranteedCraftingQualityID
                if operation.isQualityCraft and not Integer(qualityID) then output = nil
                else
                    local data = Read(ts.GetRecipeOutputItemData, raw.recipeID, variant.allocation, nil, operation.isQualityCraft and qualityID or nil)
                    output = data and data.itemID
                end
            end
        elseif schematic and ts and ts.GetRecipeOutputItemData then
            local data = Read(ts.GetRecipeOutputItemData, raw.recipeID, variant.allocation)
            output = data and data.itemID or schematic.outputItemID or raw.outputItemID
        end
        if output == outputID then
            variant.skillName, variant.skillLineID, variant.legacy = raw.skillName, raw.skillLineID, raw.legacy
            verified[#verified + 1] = variant
        end
    end
    return verified
end

function A.CraftRecipes(row)
    if not RecipeItem(row) or not Inv or not Inv.Professions or not Inv.Professions.ListAllCachedRecipes then return {} end
    local out = {}
    local catalogue = Inv.Professions.ListRecipesForOutput and Inv.Professions.ListRecipesForOutput(row.itemID)
        or Inv.Professions.ListAllCachedRecipes()
    for _, raw in ipairs(catalogue or {}) do
        if raw.learned == true and (raw.outputItemID == row.itemID or Contains(raw.craftingData and raw.craftingData.qualityItemIDs, row.itemID) or (raw.name and raw.name == row.name)) then
            local professionKnown = true
            if Inv.Professions.GetRecipeKnowledge then
                professionKnown = Inv.Professions.GetRecipeKnowledge(raw) ~= false
            end
            if raw.skillName and Inv.Professions.GetProfessionKnowledge then
                professionKnown = professionKnown and Inv.Professions.GetProfessionKnowledge({ raw.skillName }, raw.skillLineID) ~= false
            elseif raw.skillName and Inv.Professions.HasProfessionName then
                professionKnown = professionKnown and Inv.Professions.HasProfessionName({ raw.skillName }) == true
            end
            if professionKnown then for _, variant in ipairs(Variants(raw, row.itemID)) do out[#out + 1] = variant end end
        end
    end
    return out
end

-- These snapshots are produced only after a learned recipe has supplied its
-- exact output, yield and allocation. Missing live/cache replies do not revoke
-- those selected facts. Incomplete old records wait; positive contradictions
-- (including a different character) invalidate them. Execution still verifies
-- the live owned profession independently in FollowupCraft.
function A.SavedRecipeKnowledge(plan, parent)
    if type(plan) ~= "table" or not Integer(parent) or not Integer(plan.yield)
        or type(plan.recipeName) ~= "string" or plan.recipeName == ""
        or (plan.legacy ~= true and not Integer(plan.recipeID))
        or (plan.recipeVerified ~= true and not Integer(plan.skillLineID)
            and (type(plan.skillName) ~= "string" or plan.skillName == ""))
        or type(plan.required) ~= "table" or not next(plan.required) or type(plan.allocation) ~= "table"
        or plan.recipeVerified == false then return nil end
    local allocated = {}
    for id, quantity in pairs(plan.required) do if not Integer(id) or not Integer(quantity) then return nil end end
    for _, slot in ipairs(plan.allocation) do
        if type(slot) ~= "table" then return nil end
        local id = type(slot.reagent) == "table" and slot.reagent.itemID
        if not Integer(id) or not Integer(slot.quantity) or not Integer(slot.dataSlotIndex) then return nil end
        allocated[id] = (allocated[id] or 0) + slot.quantity
    end
    for id, quantity in pairs(plan.required) do if allocated[id] ~= quantity then return nil end end
    for id in pairs(allocated) do if not plan.required[id] then return nil end end
    if plan.outputItemID ~= nil and plan.outputItemID ~= parent then return false end
    local prof = Inv and Inv.Professions
    local owner = prof and prof.GetCharacterKey and prof.GetCharacterKey()
    if prof and prof.GetCharacterKey and owner == nil then return nil end
    if plan.recipeOwner ~= nil then
        if owner == nil then return nil end
        if owner ~= plan.recipeOwner then return false end
    end
    if prof and prof.GetProfessionKnowledge and plan.skillName
        and prof.GetProfessionKnowledge({ plan.skillName }, plan.skillLineID) == false then return false end
    local known, raw
    if prof and prof.GetRecipeKnowledge then known, raw = prof.GetRecipeKnowledge(plan, parent)
    elseif prof and prof.ListRecipesForOutput then
        for _, recipe in ipairs(prof.ListRecipesForOutput(parent) or {}) do
            if recipe.learned == true and (plan.legacy and recipe.legacy and recipe.name == plan.recipeName
                or not plan.legacy and not recipe.legacy and recipe.recipeID == plan.recipeID) then known, raw = true, recipe; break end
        end
    end
    if known == false then return false end
    if known == nil then return true end -- complete historical per-character snapshot
    if type(raw) ~= "table" then return nil end
    local craftingData = type(raw.craftingData) == "table" and raw.craftingData
    if raw.outputItemID ~= nil and raw.outputItemID ~= parent
        and not Contains(craftingData and craftingData.qualityItemIDs, parent) then return false end
    local variants = Variants(raw, parent)
    for _, recipe in ipairs(variants) do
        local same = recipe.yield == plan.yield
        for id, quantity in pairs(plan.required) do if recipe.required[id] ~= quantity then same = false end end
        for id in pairs(recipe.required) do if not plan.required[id] then same = false end end
        if same then return true end
    end
    -- A complete new schema that cannot be represented (required slot/quality
    -- changes included) still fails closed. A name/learned-only reply without
    -- yield/material/schema facts does not revoke the verified selected record.
    if #variants > 0 then return false end
    if raw.craftingData ~= nil or raw.supportsQualities == true
        or (type(raw.qualityItemIDs) == "table" and #raw.qualityItemIDs > 1) then return nil end
    if raw.quantityMin ~= nil then
        if not Integer(raw.quantityMin) then return nil end
        if raw.quantityMin ~= plan.yield then return false end
    end
    if raw.reagents ~= nil then
        if type(raw.reagents) ~= "table" then return nil end
        local observed = {}
        for _, reagent in ipairs(raw.reagents) do
            if type(reagent) ~= "table" or not Integer(reagent.itemID) or not Integer(reagent.count) then return nil end
            observed[reagent.itemID] = (observed[reagent.itemID] or 0) + reagent.count
        end
        for id, quantity in pairs(observed) do if plan.required[id] ~= quantity then return nil end end
    end
    return true
end

function A.RefreshCraftRecipes(rows)
    for _, row in ipairs(rows) do
        if not row.isCraftMaterial then recipeCache[row.itemID] = A.CraftRecipes(row) end
    end
end

-- Cost the actual required purchase, including whole-stack surplus when opted in.
function A.BookCost(book, quantity, cap, excess)
    if quantity <= 0 then return { cost = 0, quantity = 0, limit = 0 } end
    if not book then return end
    cap = cap or 1000000000000
    if book.commodity then
        local offer = A.CommodityOffer(book.offers, quantity, cap)
        if offer and offer.quantity == quantity then return { cost = offer.total, quantity = quantity, limit = offer.unitPrice } end
        return
    end
    local offers = {}
    for _, offer in ipairs(book.offers or {}) do
        local available = offer.availableQuantity ~= nil and N(offer.availableQuantity)
        if offer.availableQuantity == nil or (available and available >= 1 and available % 1 == 0) then
            local copy = {}; for key, value in pairs(offer) do copy[key] = value end
            if available then copy.quantity, copy.availableQuantity = 1, available end
            offers[#offers + 1] = copy
        end
    end
    local remaining, cost, bought, limit = quantity, 0, 0, 0
    while remaining > 0 do
        local offer = A.SelectStack(offers, remaining, cap, excess)
        if not offer then return end
        cost, bought, limit = cost + offer.total, bought + offer.quantity, math.max(limit, math.ceil(offer.total / offer.quantity))
        remaining = math.max(0, remaining - offer.quantity)
        local removed
        for i, old in ipairs(offers) do
            if old.auctionID == offer.auctionID and old.index == offer.index and old.page == offer.page
                and old.total == offer.total and old.quantity == offer.quantity then
                -- Modern item rows group several separately purchased items
                -- at one unit price. Cost each virtual item without changing
                -- the native book or claiming a bulk PlaceBid operation.
                if old.availableQuantity and old.availableQuantity > 1 then old.availableQuantity = old.availableQuantity - 1
                else table.remove(offers, i) end
                removed = true; break
            end
        end
        if not removed then return end
    end
    return { cost = cost, quantity = bought, limit = limit }
end

local function UnlimitedVendor(id) return (A.HasUnlimitedVendor or A.IsVendorItem)(id) end
local function VendorRoute(plan, id)
    if plan.vendorItems then return plan.vendorItems[id] == true end
    return A.IsVendorItem(id) -- older in-memory plans predate explicit routes
end
local function ItemBookCost(id, book, quantity, cap, excess)
    if not book then return end
    if book.at and (GetTime() - book.at < 0 or GetTime() - book.at >= 30) then return end
    if A.AllowExcessStacks then excess = excess and A.AllowExcessStacks(id) end
    local offers = A.FilterVendorOffers and A.FilterVendorOffers(id, book.offers, book.commodity) or book.offers
    return A.BookCost({ commodity = book.commodity, offers = offers }, quantity, cap, excess)
end

local function Carried(id, charges)
    local ri = _G.FluxRestock and _G.FluxRestock.Inv
    return ri and ri.GetLiveCount and N(ri.GetLiveCount(id, { bags = true, bank = false, warband = false, equipped = false, charges = charges == true })) or 0
end
function A.CraftCountsBank(id)
    local vendor = _G.FluxVendorAuto
    if vendor and vendor.GetRestockItemFlags then
        local flags = vendor.GetRestockItemFlags(id)
        return flags and flags.countBank == true or false
    end
    local settings = FluxRestockSettings.Get()
    local entry = settings and settings.restockItems and settings.restockItems[id]
    return type(entry) == "table" and entry.countBank == true or false
end
function A.CraftBankFlagsMatch(plan)
    for id in pairs(plan.required or {}) do
        local prior = type(plan.bankFlags) == "table" and plan.bankFlags[id] == true or plan.bankFlags == nil
        if prior ~= A.CraftCountsBank(id) then return false end
    end
    return true
end
local function Banked(id, charges)
    if not A.CraftCountsBank(id) then return 0 end
    local ri = _G.FluxRestock and _G.FluxRestock.Inv
    local bank = ri and ri.Bank
    return bank and bank.GetCount and N(bank.GetCount(id, {
        bank = true, warband = true, allowCached = true, charges = charges == true,
    })) or 0
end
local function Reserved(id)
    local row = A.FindRow(id)
    -- A material-only row deliberately counts physical recipe reagents. Other
    -- targets/reservations use the item's normal charge-aware stock units.
    if not row or not row.isCraftMaterial then row = A.SetItemUnits({ itemID = id }) end
    local units = row.unitsPerItem
    if not units then return 0 end
    local ri = _G.FluxRestock and _G.FluxRestock.Inv
    local have = ri and ri.GetLiveCount and N(ri.GetLiveCount(id, {
        bags = true, bank = false, warband = false, equipped = false, charges = row.isCharge == true,
    }))
    local pending = A.MailUnits(row) + math.max(0, A.Pending(row, have) - A.PredictedMailUnits(row))
    return math.ceil(pending / units)
end
local function DirectItems(row, allSources)
    local units = row.unitsPerItem
    if not units then return math.huge end
    local desired = math.max(0, (row.baseTarget or row.target or 0)
        - (not allSources and row.countBank and (row.bankCount or 0) or 0))
    if desired == 0 then return 0 end
    -- Partly used copies still occupy a reagent item. Protect the lost charge
    -- capacity too, so allocating a full copy cannot underfill its own target.
    local spent = 0
    if row.isCharge then
        local physical = Carried(row.itemID) + (allSources and Banked(row.itemID) or 0)
        local uses = Carried(row.itemID, true) + (allSources and Banked(row.itemID, true) or 0)
        spent = math.max(0, physical * units - uses)
    end
    return math.ceil((desired + spent) / units)
end
local function BankAvailable(id, row)
    local bank = Banked(id)
    if not row or row.isCraftMaterial or not row.countBank then return bank end
    local protectedBags = math.min(Carried(id), DirectItems(row))
    local protectedBank = math.max(0, DirectItems(row, true) - protectedBags)
    return math.max(0, bank - protectedBank)
end
function A.GetCraftBankAvailable(id)
    return BankAvailable(id, A.FindRow(id))
end
function A.GetCraftBagAvailable(id)
    local row = A.FindRow(id)
    local direct = row and not row.isCraftMaterial and DirectItems(row) or 0
    -- Execution may consume only carried physical copies above their own
    -- restock target; incoming mail is useful for planning, never crafting.
    return math.max(0, Carried(id) - direct)
end
local function Locked(id, except, allSources)
    local quantity = 0
    for parent, plan in pairs(plans) do if parent ~= except then quantity = quantity + (plan.required[id] or 0) end end
    local row = A.FindRow(id)
    if row and not row.isCraftMaterial then
        local direct = DirectItems(row, allSources)
        if allSources and not row.countBank then
            direct = math.min(Carried(id) + Reserved(id), DirectItems(row))
        end
        quantity = quantity + direct
    end
    return quantity
end

function A.CompareCraft(row, variants, books)
    local need = A.Need(row)
    local savedCap, unlimited = A.GetMaxPrice(row.itemID), A.IsPriceUnlimited(row.itemID)
    local cap = A.PriceLimit(row.itemID)
    if not need or need <= 0 then return end
    local excess = A.Settings().allowExcessStacks == true
    local finished = ItemBookCost(row.itemID, books[row.itemID], need, nil, excess)
    local best, alternative
    for _, variant in ipairs(variants) do
        local operations = math.ceil(need / variant.yield)
        local total, vendorCost, valid, limits, required, vendorItems, vendorPrices, vendorOwned, bankFlags = 0, 0, true, {}, {}, {}, {}, {}, {}
        for id, count in pairs(variant.required) do
            required[id] = count * operations
            bankFlags[id] = A.CraftCountsBank(id)
            local vendor = UnlimitedVendor(id)
            local price = vendor and A.VendorPrice(id)
            local available = math.max(0, Carried(id) + Banked(id) + Reserved(id) - Locked(id, row.itemID, true))
            local missing = math.max(0, required[id] - available)
            if missing == 0 and vendor then
                -- Source identity is independent of whether this scan needs to
                -- pay for it. Preserve the allocated owned share for any other
                -- recipe using this same reagent through the auction house.
                vendorItems[id], vendorPrices[id], vendorOwned[id] = true, price, required[id]
            end
            if missing > 0 then
                local explicit = A.PriceLimit(id)
                local cost = ItemBookCost(id, books[id], missing, explicit, excess)
                if vendor then
                    if price == nil then valid = false; break end
                    local invoice
                    if A.VendorTerms then
                        local numerator, denominator = A.VendorTerms(id)
                        if numerator and denominator then invoice = numerator * missing / denominator end
                    end
                    invoice = invoice or price * missing
                    if cost and cost.cost < invoice then
                        vendorItems[id], vendorPrices[id] = nil, nil
                        total, limits[id] = total + cost.cost, cost.limit
                    else
                        -- Ingredient limits govern AH offers. Vendor invoices
                        -- are instead checked against the finished-item budget.
                        vendorItems[id], vendorPrices[id] = true, price
                        vendorOwned[id] = math.min(required[id], available)
                        total, vendorCost = total + invoice, vendorCost + invoice
                    end
                else
                    if not cost then valid = false; break end
                    total, limits[id] = total + cost.cost, cost.limit
                end
            end
        end
        if valid then
            local candidate = { parentID = row.itemID, parentName = row.name, recipe = variant, operations = operations,
                required = required, cost = total, vendorCost = vendorCost, vendorItems = vendorItems,
                vendorPrices = vendorPrices, limits = limits, need = need,
                vendorOwned = vendorOwned, bankFlags = bankFlags,
                budget = math.min(cap * need, finished and finished.cost or total) - vendorCost,
                spent = 0, books = books, at = GetTime() }
            candidate.targetAtPlan, candidate.countBankAtPlan, candidate.capAtPlan = row.target, row.countBank, savedCap
            candidate.capUnlimitedAtPlan = unlimited
            if not alternative or total < alternative.cost then alternative = candidate end
            if total <= cap * need and ((finished and total <= finished.cost) or total == 0)
                and (not best or total < best.cost) then best = candidate end
        end
    end
    return best, finished, alternative
end

function A.ResetCraftPlans()
    for id in pairs(plans) do plans[id] = nil end
    for id in pairs(decisions) do decisions[id] = nil end
    for id in pairs(booksCache) do booksCache[id] = nil end
    for id in pairs(recipeCache) do recipeCache[id] = nil end
    pricing = nil
    A.Settings().vendorCraftPlans = nil
    if FluxVendorAuto and FluxVendorAuto.InvalidateRestockOptionsPanelCache then FluxVendorAuto.InvalidateRestockOptionsPanelCache() end
end
function A.CancelCraftPricing() pricing = nil end
function A.IsCraftOutput(id) return plans[id] ~= nil end
function A.HasCraftPlans() return next(plans) ~= nil end

function A.ClearVendorCraftPlan(parent)
    local saved = A.Settings().vendorCraftPlans
    if type(saved) == "table" then saved[parent] = nil end
end
local function SaveVendorCraftPlan(parent, plan, output)
    local existing = A.Settings().vendorCraftPlans
    if plan.vendorSnapshot and type(existing) == "table" and existing[parent] == plan.vendorSnapshot then return end
    local prices = {}
    for id in pairs(plan.recipe.required) do
        local price = plan.vendorPrices and plan.vendorPrices[id] or A.VendorPrice(id)
        if VendorRoute(plan, id) and price ~= nil then prices[id] = price end
    end
    local saved = A.Settings().vendorCraftPlans
    if type(saved) ~= "table" then saved = {}; A.Settings().vendorCraftPlans = saved end
    saved[parent] = { version = 1, sourceID = output.upgradeFrom or parent, parentName = output.name,
        outputItemID = parent, recipeVerified = true,
        recipeOwner = Inv.Professions and Inv.Professions.GetCharacterKey and Inv.Professions.GetCharacterKey(),
        recipeID = plan.recipe.recipeID, recipeName = plan.recipe.name, skillName = plan.recipe.skillName,
        skillLineID = plan.recipe.skillLineID, allocation = plan.recipe.allocation,
        legacy = plan.recipe.legacy, yield = plan.recipe.yield, required = CopyMap(plan.recipe.required), prices = prices,
        vendorOwned = CopyMap(plan.vendorOwned or {}),
        vendorRequiredAtPlan = CopyMap(plan.required),
        bankFlags = CopyMap(plan.bankFlags or {}),
        target = plan.targetAtPlan, countBank = plan.countBankAtPlan == true,
        cap = plan.capAtPlan, capUnlimited = plan.capUnlimitedAtPlan, auctionTier = output.auctionTier }
    plan.vendorSnapshot = saved[parent]
    if FluxVendorAuto and FluxVendorAuto.InvalidateRestockOptionsPanelCache then FluxVendorAuto.InvalidateRestockOptionsPanelCache() end
end

-- Called by the normal restock list with its base rows. Never re-enters GetRows.
-- These per-character plans survive the AH-to-vendor trip and reload, while the
-- permanent restockItems targets remain owned by their existing callers.
function A.GetVendorCraftTargets(baseRows)
    local saved = A.Settings().vendorCraftPlans
    if type(saved) ~= "table" or not next(saved) then return {} end
    if not A.PreferCrafting() then A.Settings().vendorCraftPlans = nil; return {} end
    if not A.IsInventoryReliable() then return {} end
    A.RefreshMailFacts()
    local result, otherRequired, invalidParents = {}, {}, {}
    for parent, plan in pairs(saved) do
        if type(plan) ~= "table" or plan.version ~= 1 or type(plan.required) ~= "table" or type(plan.prices) ~= "table" then
            saved[parent] = nil
        else
            local source
            for _, row in ipairs(baseRows) do
                local ref = row.isTierRestock and _G.FluxConsumableBest and FluxConsumableBest.GetBestRef(row.tierKind)
                if (row.itemID == plan.sourceID or (ref and ref.itemID == parent)) then source = row; break end
            end
            local valid = A.PricePolicyMatches(parent, plan.cap, plan.capUnlimited) and Integer(plan.yield) and A.CraftBankFlagsMatch(plan)
            if valid then
                valid = A.SavedRecipeKnowledge(plan, parent)
                if valid then
                    if not source then valid = nil -- a cold target provider is not a target change
                    else valid = source.target == plan.target and (source.countBank == true) == plan.countBank end
                end
            end
            local need
            if valid then
                local row = {}; for key, value in pairs(source) do row[key] = value end
                row.itemID, row.auctionTier = parent, plan.auctionTier
                A.SetItemUnits(row)
                if row.isTierRestock then row.tiers = { source } end
                need = A.Need(row)
            end
            if valid == nil or valid and need == nil then -- transient data: keep facts, do not buy
            elseif not valid or need <= 0 then saved[parent] = nil
            else
                local operations = math.ceil(need / plan.yield)
                for id, count in pairs(plan.required) do
                    if not plan.prices[id] then otherRequired[id] = (otherRequired[id] or 0) + operations * count end
                end
                for id, price in pairs(plan.prices or {}) do
                    if UnlimitedVendor(id) and N(price) and Integer(plan.required[id]) then
                        local entry = result[id] or { itemID = id, target = 0, owned = 0, maxUnitPrice = price, parents = {} }
                        local required = operations * plan.required[id]
                        local initial = plan.vendorRequiredAtPlan and plan.vendorRequiredAtPlan[id] or required
                        local consumed = math.max(0, initial - required)
                        entry.target = entry.target + required
                        entry.owned = entry.owned + math.min(required, math.max(0, (plan.vendorOwned and plan.vendorOwned[id] or 0) - consumed))
                        entry.parents[parent] = true
                        entry.maxUnitPrice = math.min(entry.maxUnitPrice, price)
                        result[id] = entry
                    end
                end
            end
        end
    end
    for id, entry in pairs(result) do
        local base
        for _, row in ipairs(baseRows) do if row.itemID == id then base = row; break end end
        if base then
            local copy = {}; for key, value in pairs(base) do copy[key] = value end
            A.SetItemUnits(copy); base = copy
        end
        local direct = base and DirectItems(base, true) or 0
        local pool = math.max(0, Carried(id) + Banked(id) + Reserved(id) - direct)
        local available = math.max(0, pool - (otherRequired[id] or 0), math.min(pool, entry.owned))
        if available < entry.owned then
            -- This source was chosen partly from already-owned stock. Losing
            -- that reserved share cannot authorize a new, unpriced invoice.
            -- Completed crafts reduce the share above; unexpected loss needs
            -- a fresh AH comparison before the normal vendor owner can buy.
            for parent in pairs(entry.parents) do
                saved[parent], plans[parent], invalidParents[parent] = nil, nil, true
            end
            result[id] = nil
        else
            entry.pending = Reserved(id)
            entry.bank = math.min(entry.target, BankAvailable(id, base))
            entry.need = math.max(0, entry.target - available)
        end
    end
    for id, entry in pairs(result) do
        for parent in pairs(entry.parents) do
            if invalidParents[parent] then result[id] = nil; break end
        end
    end
    return result
end

function A.MaterialRows(rows)
    local base, additions, vendorOwned = {}, {}, {}
    for _, row in ipairs(rows) do base[row.itemID] = row end
    for parent, plan in pairs(plans) do
        local output = base[parent]
        local need
        if output then need = A.Need(output) end
        local knowledge = true
        if plan.vendorSnapshot then knowledge = A.SavedRecipeKnowledge(plan.vendorSnapshot, parent) end
        if knowledge == false or not A.PricePolicyMatches(parent, plan.capAtPlan, plan.capUnlimitedAtPlan) or not A.CraftBankFlagsMatch(plan)
            or (output and (need == 0 or output.target ~= plan.targetAtPlan or output.countBank ~= plan.countBankAtPlan)) then plans[parent] = nil; A.ClearVendorCraftPlan(parent)
        elseif not output or need == nil or knowledge == nil then -- incomplete data does not revoke selected facts
        else
            SaveVendorCraftPlan(parent, plan, output)
            local operations = math.ceil(need / plan.recipe.yield)
            plan.operations, plan.required = operations, {}
            for id, count in pairs(plan.recipe.required) do
                local quantity = count * operations
                plan.required[id] = quantity
                if VendorRoute(plan, id) then
                    vendorOwned[id] = (vendorOwned[id] or 0) + math.min(quantity, plan.vendorOwned and plan.vendorOwned[id] or 0)
                end
                if not VendorRoute(plan, id) then
                    local add = additions[id] or { quantity = 0, parents = {}, limit = nil }
                    add.quantity, add.parents[parent] = add.quantity + quantity, true
                    local limit = plan.limits[id]
                    if limit then add.limit = add.limit and math.min(add.limit, limit) or limit end
                    additions[id] = add
                end
            end
        end
    end
    for id, add in pairs(additions) do
        -- A paid vendor invoice may already own part of this reagent. Keep
        -- those copies in the shared target without charging its AH budget.
        local heldVendor = vendorOwned[id] or 0
        add.quantity = add.quantity + heldVendor
        local row = base[id]
        if not row then
            local ic = _G.FluxItemClass
            row = { itemID = id, target = 0, baseTarget = 0, unitsPerItem = 1, isCraftMaterial = true,
                name = ic and ic.GetName(id) or tostring(id), texture = ic and ic.GetIcon and ic.GetIcon(id),
                countBank = A.CraftCountsBank(id), bankCount = Banked(id) }
            rows[#rows + 1], base[id] = row, row
        else row.baseTarget = row.target end
        row.target = row.target + add.quantity * (row.unitsPerItem or 0)
        local baseBank = row.countBank and math.min(N(row.bankCount) or 0, row.baseTarget or 0) or 0
        row.craftBankCount = math.min(Banked(id, row.isCharge), baseBank + add.quantity * (row.unitsPerItem or 0))
        row.craftVendorOwned = heldVendor
        row.craftParents, row.craftLimit = add.parents, add.limit or 0
        row.need, row.maxPrice = A.Need(row), add.limit or 0
    end
end

local function CraftPurchaseNeed(row)
    local required = 0
    for parent in pairs(row.craftParents or {}) do
        local plan = plans[parent]
        required = required + (plan and plan.required[row.itemID] or 0)
    end
    local carried = Carried(row.itemID) + Reserved(row.itemID)
    local direct = row.baseTarget and DirectItems(row, true) or 0
    if not row.countBank then direct = math.min(carried, row.baseTarget and DirectItems(row) or 0) end
    return math.max(0, required - math.max(0, carried + Banked(row.itemID) - direct - (row.craftVendorOwned or 0)))
end
function A.MaterialLimit(id)
    local row = A.FindRow(id)
    if row and row.craftParents then
        if CraftPurchaseNeed(row) == 0 then return end
        return math.min(A.PriceLimit(id), row.craftLimit)
    end
end

local function SpendShares(row, total, quantity)
    local ids = {}; for id in pairs(row.craftParents or {}) do ids[#ids + 1] = id end; table.sort(ids)
    local direct = row.baseTarget and DirectItems(row) or 0
    local available = Carried(row.itemID) + Reserved(row.itemID)
    local protected = row.baseTarget and DirectItems(row, true) or 0
    if not row.countBank then protected = math.min(available, direct) end
    local owned = math.max(0, available + Banked(row.itemID) - protected - (row.craftVendorOwned or 0))
    local weights, sum = {}, 0
    local forDirect = math.min(quantity, math.max(0, direct - available))
    local remaining = quantity - forDirect
    -- A shared row can refill its own target and supply a recipe in the same
    -- purchase. Only the recipe's share uses its budget; indivisible surplus
    -- remains charged to that route. Round its invoice share up conservatively.
    total = math.ceil(total * remaining / quantity)
    for _, id in ipairs(ids) do
        local p = plans[id]
        if p then
            local required = p.required[row.itemID] or 0
            local held = math.min(owned, required); owned = owned - held
            local missing = required - held
            local weight = math.min(remaining, missing)
            if weight > 0 then weights[id], sum, remaining = weight, sum + weight, remaining - weight end
        end
    end
    if sum == 0 then return {} end
    local allocation, remainder = {}, total
    for _, id in ipairs(ids) do
        if weights[id] then
            local amount = math.floor(total * weights[id] / sum)
            if amount > plans[id].budget - plans[id].spent then return end
            allocation[id], remainder = amount, remainder - amount
        end
    end
    for _, id in ipairs(ids) do
        if remainder > 0 and allocation[id] and allocation[id] < plans[id].budget - plans[id].spent then
            allocation[id], remainder = allocation[id] + 1, remainder - 1
        end
    end
    if remainder > 0 then return end
    return allocation
end
function A.CheckCraftSpend(row, offer)
    if not row.craftParents then return true end
    return SpendShares(row, offer.total, offer.quantity) ~= nil
end
function A.RecordCraftSpend(row, total, quantity)
    if not row.craftParents then return end
    local allocation = SpendShares(row, total, quantity)
    for id, amount in pairs(allocation or {}) do plans[id].spent = plans[id].spent + amount end
    return allocation
end
function A.ReleaseCraftSpend(allocation)
    for id, amount in pairs(allocation or {}) do if plans[id] then plans[id].spent = math.max(0, plans[id].spent - amount) end end
end

function A.StartCraftPricing(row, force, onDone)
    if row.isCraftMaterial or row.craftParents then return false end
    local known = recipeCache[row.itemID] or A.CraftRecipes(row)
    local variants = A.PreferCrafting() and known or {}
    if #variants == 0 and not onDone then return false end
    local need = A.Need(row)
    if not need or need <= 0 then return false end
    decisions[row.itemID] = { row = row, variants = known, need = need }
    local batch = { parent = row, variants = variants, known = known, books = {}, ids = { row.itemID }, need = { [row.itemID] = math.max(1, need) }, index = 0 }
    for _, variant in ipairs(variants) do
        local operations = math.ceil(need / variant.yield)
        for id, quantity in pairs(variant.required) do
            local available = math.max(0, Carried(id) + Banked(id) + Reserved(id) - Locked(id, row.itemID, true))
            if quantity * operations > available then
                if not batch.need[id] then batch.ids[#batch.ids + 1] = id end
                batch.need[id] = math.max(batch.need[id] or 0, quantity * operations)
            end
        end
    end
    -- Zero-cost owned/banked inputs already beat every positive AH buyout.
    -- Complete their plan without opening the profession or issuing a search.
    if A.PriceLimit(row.itemID) == 0 or (#variants > 0 and A.CompareCraft(row, variants, {})) then batch.ids = {} end
    if #batch.ids > 60 then return false end
    pricing = batch
    local function NextBook(book)
        if pricing ~= batch or not A.active or not A.houseOpen then return end
        if book then batch.books[book.itemID], booksCache[book.itemID] = book, book end
        batch.index = batch.index + 1
        local id = batch.ids[batch.index]
        if id then
            local cached = not force and booksCache[id]
            if cached and GetTime() - cached.at >= 0 and GetTime() - cached.at < 30 then NextBook(cached); return end
            A.BeginSearch({ itemID = id, target = batch.need[id], unitsPerItem = 1 }, NextBook)
            Paint()
            return
        end
        pricing = nil
        local original = A.FindRow(batch.parent.itemID, true)
        if not original then A.Invalidate("changed"); return end
        local selected, finished, alternative = A.CompareCraft(original, batch.variants, batch.books)
        decisions[original.itemID] = { row = original, variants = batch.known, selected = selected,
            finished = finished, alternative = alternative, need = need, complete = true }
        if selected then
            local old = plans[original.itemID]
            if old and old.recipe.recipeID == selected.recipe.recipeID then selected.spent = old.spent end
            plans[original.itemID] = selected
            A.GetRows(true)
            if onDone then onDone(); return end
            if A.PrepareNext then A.PrepareNext()
            else A.selectedID, A.status = original.itemID, "craftReady"; Paint() end
        else
            plans[original.itemID] = nil
            A.ClearVendorCraftPlan(original.itemID)
            A.selectedID = original.itemID
            A.GetRows(true)
            if onDone then onDone(); return end
            if A.PrepareNext then A.PrepareNext() else A.BeginSearch(original) end
        end
    end
    NextBook()
    return true
end

function A.RouteText(row)
    local known = recipeCache[row.itemID]
    if A.PreferCrafting() and (plans[row.itemID] or ((row.need or 0) == 0 and known and #known > 0)) then return ns.FluxOptionsLocale.AH_ROUTE_CRAFTABLE end
    return ns.FluxOptionsLocale.AH_ROUTE_DIRECT
end

function A.RepriceMaterial(row)
    if not row.craftParents then return false end
    if CraftPurchaseNeed(row) == 0 then return false end
    for id in pairs(row.craftParents) do
        local plan = plans[id]
        if plan and ((row.craftLimit or 0) <= 0 or GetTime() - plan.at > 30) then
            local original = A.FindRow(id)
            if original then return A.StartCraftPricing(original, true) end
        end
    end
    return false
end

function A.CraftStatus()
    if pricing then
        local id = pricing.ids[pricing.index]
        local name = _G.FluxItemClass and FluxItemClass.GetName(id) or tostring(id)
        return ns.FluxOptionsLocale.AH_PRICING:format(pricing.index, #pricing.ids, name)
    end
    local selected = A.selectedID and (plans[A.selectedID] or nil)
    if not selected then
        local row = A.FindRow(A.selectedID)
        if row and row.craftParents then for id in pairs(row.craftParents) do selected = plans[id]; break end end
    end
    if selected then
        local text = ns.FluxOptionsLocale.AH_MATERIAL_ROUTE:format(selected.parentName or tostring(selected.parentID), selected.operations, selected.operations * selected.recipe.yield)
        for id in pairs(selected.required) do
            local quantity, auction = 0, 0
            for _, plan in pairs(plans) do
                if VendorRoute(plan, id) then quantity = quantity + (plan.required[id] or 0)
                else auction = auction + (plan.required[id] or 0) end
            end
            local missing = math.max(0, quantity - math.max(0, Carried(id) + Reserved(id) - auction))
            if missing > 0 then
                local name = _G.FluxItemClass and FluxItemClass.GetName(id) or tostring(id)
                text = text .. " " .. ns.FluxOptionsLocale.AH_VENDOR_MATERIAL:format(missing, name)
            end
        end
        return text
    end
end

function A.RecipeDetails()
    local L, lines = ns.FluxOptionsLocale, {}
    local function Money(value)
        return value and (GetMoneyString and GetMoneyString(math.ceil(value)) or A.PriceText(value)) or L.AH_UNKNOWN_PRICE
    end
    for _, row in ipairs(A.GetRows(false)) do
        if not row.isCraftMaterial and RecipeItem(row) then
            local decision = decisions[row.itemID]
            local variants = decision and decision.variants or recipeCache[row.itemID] or {}
            lines[#lines + 1] = "|cffffd100" .. (row.name or tostring(row.itemID)) .. "|r"
            if #variants == 0 then lines[#lines + 1] = L.AH_RECIPE_UNKNOWN
            else
                local choice = decision and (decision.selected or decision.alternative)
                local recipe = choice and choice.recipe or variants[1]
                local operations = math.ceil((A.Need(row) or 0) / recipe.yield)
                lines[#lines + 1] = L.AH_RECIPE_KNOWN:format(recipe.name or row.name or tostring(recipe.recipeID), recipe.recipeID, recipe.yield, operations)
                lines[#lines + 1] = L.AH_COMPARE:format(Money(decision and decision.finished and decision.finished.cost), Money(choice and choice.cost))
                lines[#lines + 1] = not A.PreferCrafting() and L.AH_CRAFT_DISABLED or decision and decision.complete and (decision.selected and L.AH_ROUTE_MATERIALS or L.AH_ROUTE_FINISHED) or L.AH_COMPARE_PENDING
                local ids = {}; for id in pairs(recipe.required) do ids[#ids + 1] = id end; table.sort(ids)
                for _, id in ipairs(ids) do
                    local ic = _G.FluxItemClass
                    local name = ic and ic.GetName and ic.GetName(id) or tostring(id)
                    local required = recipe.required[id] * operations
                    lines[#lines + 1] = L.AH_REAGENT:format(required, name, Carried(id), Reserved(id)) .. ((choice and VendorRoute(choice, id) or not choice and A.IsVendorItem(id)) and L.AH_VENDOR_TAG or "")
                end
            end
            lines[#lines + 1] = ""
        end
    end
    return #lines > 0 and table.concat(lines, "\n") or L.AH_NO_CRAFT_TARGETS
end
