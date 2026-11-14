-- Exact AH follow-up recipe execution. Only CraftClick issues actions, from the
-- visible button's hardware click; events may inspect/refresh but never craft.
local _, ns = ...
local A = FluxAuctionRestock
A.Followup = A.Followup or {}
local F, Inv = A.Followup, ns.Flux.Inventory
local Number = A.Number

local function Integer(value)
    return Number(value) and value > 0 and value % 1 == 0
end
local function ItemID(link)
    return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end
local function SameMap(a, b)
    for id, count in pairs(a) do if b[id] ~= count then return false end end
    for id, count in pairs(b) do if a[id] ~= count then return false end end
    return true
end
local function ValidTask(task)
    if type(task) ~= "table" or not Integer(task.parentID) or not Integer(task.operations)
        or not Integer(task.yield) or type(task.required) ~= "table" or not next(task.required) then return false end
    for id, count in pairs(task.required) do if not Integer(id) or not Integer(count) then return false end end
    return type(task.recipeName) == "string" and task.recipeName ~= ""
end
local function Foreign()
    local ts = C_TradeSkillUI
    return (IsTradeSkillLinked and IsTradeSkillLinked())
        or (ts and ts.IsTradeSkillLinked and ts.IsTradeSkillLinked())
        or (ts and ts.IsTradeSkillGuild and ts.IsTradeSkillGuild())
        or (ts and ts.IsNPCCrafting and ts.IsNPCCrafting()) or false
end
local function ModernProfessionMatches(task)
    if not Integer(task.skillLineID) then return false end
    local ts, prof = C_TradeSkillUI, Inv and Inv.Professions
    if not ts then return false end
    if ts.IsDataSourceChanging and ts.IsDataSourceChanging() then return false end
    if ts.IsTradeSkillReady and not ts.IsTradeSkillReady() then return false end
    local info = prof and prof.GetOpenProfessionInfo and prof.GetOpenProfessionInfo()
    if type(info) ~= "table" then return false end
    return Number(info.professionID) == task.skillLineID or Number(info.parentProfessionID) == task.skillLineID
        or Number(info.skillLineID) == task.skillLineID
end
local function LegacyProfessionMatches(task)
    return type(task.skillName) == "string" and task.skillName ~= ""
        and GetTradeSkillLine and GetTradeSkillLine() == task.skillName
end
local function BagOperations(task)
    local inv = _G.FluxRestock and _G.FluxRestock.Inv
    if not inv or not inv.GetLiveCount then return 0 end
    local count = task.operations
    for id, required in pairs(task.required) do
        local have
        if A.GetCraftBagAvailable then have = Number(A.GetCraftBagAvailable(id))
        else have = Number(inv.GetLiveCount(id, {
            bags = true, bank = false, warband = false, equipped = false, charges = false,
        })) end
        if not have then return 0 end
        count = math.min(count, math.floor(have / required))
    end
    return count
end

function F.CraftIsBusy(task)
    -- These are observations, not authorization for a new protected action.
    if UnitCastingInfo then
        local name = UnitCastingInfo("player")
        if (issecretvalue and issecretvalue(name)) or name ~= nil then return true end
    end
    if UnitChannelInfo then
        local name = UnitChannelInfo("player")
        if (issecretvalue and issecretvalue(name)) or name ~= nil then return true end
    end
    -- All three pinned legacy windows display this engine batch counter.
    -- No equivalent modern repeat counter is assumed across inter-cast gaps.
    if task and task.legacy and GetTradeskillRepeatCount then
        local count = Number(GetTradeskillRepeatCount())
        if count and count > 0 then return true end
    end
    return false
end

local function LegacyIndex(task)
    if not LegacyProfessionMatches(task) or not GetNumTradeSkills or not GetTradeSkillInfo
        or not GetTradeSkillItemLink or not GetTradeSkillNumMade or not GetTradeSkillNumReagents
        or not GetTradeSkillReagentInfo or not GetTradeSkillReagentItemLink then return nil end
    local count = Number(GetNumTradeSkills())
    if not count then return nil end
    for index = 1, count do
        local name, kind = GetTradeSkillInfo(index)
        if name == task.recipeName and kind and kind ~= "header" and kind ~= "subheader"
            and ItemID(GetTradeSkillItemLink(index)) == task.parentID
            and GetTradeSkillNumMade(index) == task.yield then
            local reagents, valid = {}, true
            local reagentCount = Number(GetTradeSkillNumReagents(index))
            if not reagentCount or reagentCount < 1 then valid = false else
                for slot = 1, reagentCount do
                    local _, _, quantity = GetTradeSkillReagentInfo(index, slot)
                    local id = ItemID(GetTradeSkillReagentItemLink(index, slot))
                    if not Integer(id) or not Integer(quantity) then valid = false; break end
                    reagents[id] = (reagents[id] or 0) + quantity
                end
            end
            if valid and SameMap(reagents, task.required) then return index end
        end
    end
end

local function ModernAllocation(task)
    local ts = C_TradeSkillUI
    if not Integer(task.recipeID) or not ModernProfessionMatches(task) or not ts.GetRecipeInfo
        or not ts.GetRecipeSchematic or not ts.GetRecipeOutputItemData then return nil end
    local info = ts.GetRecipeInfo(task.recipeID)
    if not info or info.learned ~= true or info.disabled or info.isDummyRecipe or info.isGatheringRecipe
        or info.isEnchantingRecipe or info.isSalvageRecipe or info.name ~= task.recipeName then return nil end
    local schematic = ts.GetRecipeSchematic(task.recipeID, false)
    if not schematic or schematic.quantityMin ~= task.yield or type(schematic.reagentSlotSchematics) ~= "table"
        or type(task.allocation) ~= "table" or #task.allocation == 0 then return nil end
    local basic = Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic
    local slots, allocation, totals = {}, {}, {}
    for _, slot in ipairs(schematic.reagentSlotSchematics) do
        if slot.required == true or (Number(slot.quantityRequired) or 0) > 0 then
            if not Integer(slot.dataSlotIndex) or slots[slot.dataSlotIndex] or not Integer(slot.quantityRequired)
                or (slot.reagentType ~= nil and (basic == nil or slot.reagentType ~= basic)) then return nil end
            local options = {}
            for _, reagent in ipairs(slot.reagents or {}) do
                if not Integer(reagent.itemID) then return nil end
                options[reagent.itemID] = true
            end
            slots[slot.dataSlotIndex] = { quantity = slot.quantityRequired, options = options, allocated = 0 }
        end
    end
    for _, reagent in ipairs(task.allocation) do
        if type(reagent) ~= "table" then return nil end
        local id = type(reagent.reagent) == "table" and reagent.reagent.itemID
        local slot = slots[reagent.dataSlotIndex]
        if not slot or not Integer(id) or not Integer(reagent.quantity) or not slot.options[id] then return nil end
        slot.allocated = slot.allocated + reagent.quantity
        totals[id] = (totals[id] or 0) + reagent.quantity
        allocation[#allocation + 1] = { reagent = { itemID = id }, dataSlotIndex = reagent.dataSlotIndex, quantity = reagent.quantity }
    end
    for _, slot in pairs(slots) do if slot.allocated ~= slot.quantity then return nil end end
    if not SameMap(totals, task.required) then return nil end
    local qualityID
    local qualities = ts.GetRecipeQualityItemIDs and ts.GetRecipeQualityItemIDs(task.recipeID)
    if info.supportsQualities or (type(qualities) == "table" and #qualities > 1) or schematic.hasCraftingOperationInfo then
        if not ts.GetCraftingOperationInfo then return nil end
        local operation = ts.GetCraftingOperationInfo(task.recipeID, allocation, nil, false)
        if not operation then return nil end
        if operation.isQualityCraft then
            qualityID = operation.guaranteedCraftingQualityID
            if not Integer(qualityID) then return nil end
        end
    end
    local output = ts.GetRecipeOutputItemData(task.recipeID, allocation, nil, qualityID)
    if not output or Number(output.itemID) ~= task.parentID then return nil end
    return allocation
end

local function Prepare(task)
    if not ValidTask(task) or (InCombatLockdown and InCombatLockdown())
        or not A.IsReliable() or Foreign() then return "unavailable" end
    if F.CraftIsBusy(task) then return "crafting" end
    local count = BagOperations(task)
    if count < 1 then return "unavailable" end
    if A.SavedRecipeKnowledge and A.SavedRecipeKnowledge(task, task.parentID) == false then return "unavailable" end
    if task.legacy then
        if not DoTradeSkill then return "unavailable" end
        if not LegacyProfessionMatches(task) then
            if not CastSpellByName or type(task.skillName) ~= "string" or task.skillName == "" then return "unavailable" end
            return "opening", count
        end
        local index = LegacyIndex(task)
        if not index or Foreign() then return "unavailable" end
        return "ready", count, index
    else
        local ts = C_TradeSkillUI
        if not ts or not ts.CraftRecipe then return "unavailable" end
        if not ModernProfessionMatches(task) then
            if not Integer(task.skillLineID) or not ts.OpenTradeSkill then return "unavailable" end
            return "opening", count
        end
        local allocation = ModernAllocation(task)
        if not allocation or Foreign() then return "unavailable" end
        return "ready", count, allocation
    end
end
function F.CanCraft(task)
    local status = Prepare(task)
    return status == "opening" or status == "ready"
end
function F.CraftClick(task)
    local status, count, recipe = Prepare(task)
    if status == "opening" then
        if task.legacy then CastSpellByName(task.skillName)
        elseif C_TradeSkillUI.OpenTradeSkill(task.skillLineID) == false then return "unavailable" end
        status, count, recipe = Prepare(task)
        if status == "opening" then return "opening" end
    end
    if status ~= "ready" then return status end
    task.operations = count
    if task.legacy then
        if SelectTradeSkill then SelectTradeSkill(recipe) end
        DoTradeSkill(recipe, count)
    else C_TradeSkillUI.CraftRecipe(task.recipeID, count, recipe, nil, nil, false) end
    return "crafting", count
end
