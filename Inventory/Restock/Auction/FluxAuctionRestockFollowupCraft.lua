-- Exact AH follow-up recipe execution. Only CraftClick issues actions, from the
-- visible button's hardware click; events may inspect/refresh but never craft.
local _, ns = ...
local A = FluxAuctionRestock
A.Followup = A.Followup or {}
local F, Inv, Flux = A.Followup, ns.Flux.Inventory, ns.Flux
local Number = A.Number

-- Same defining-function contract as auction rows; keep foreign getters live.
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
local function Hidden(frame)
    return frame and frame.IsShown and not frame:IsShown()
end
local function ModernProfessionMatches(skillLineID)
    if not Integer(skillLineID) then return false end
    local ts, prof = C_TradeSkillUI, Inv and Inv.Professions
    if not ts then return false end
    local frame = _G.ProfessionsFrame or _G.TradeSkillFrame
    if Hidden(frame) or frame and Hidden(frame.CraftingPage) then return false end
    if ts.IsTradeSkillReady and not ts.IsTradeSkillReady() then return false end
    local info = prof and prof.GetOpenProfessionInfo and prof.GetOpenProfessionInfo()
    if type(info) ~= "table" then return false end
    return Number(info.professionID) == skillLineID or Number(info.parentProfessionID) == skillLineID
        or Number(info.skillLineID) == skillLineID
end
local function ProfessionIDForRecipe(task)
    local ts = C_TradeSkillUI
    local lookup = ts.GetProfessionInfoByRecipeID
    local info = lookup and Integer(task.recipeID) and lookup(task.recipeID)
    if type(info) == "table" then
        if Integer(info.parentProfessionID) then return info.parentProfessionID end
        if Integer(info.professionID) then return info.professionID end
    end
    if Integer(task.skillLineID) then return task.skillLineID end
end

-- Both reminder owners use the native Recipes entry point for a retained
-- profession. New sessions and switches still require the engine's acceptance.
function F.OpenProfession(skillLineID)
    local ts = C_TradeSkillUI
    if not Integer(skillLineID) or not ts or not ts.OpenTradeSkill or Foreign()
        or (InCombatLockdown and InCombatLockdown())
        or (ts.IsDataSourceChanging and ts.IsDataSourceChanging()) then return false end
    if not _G.ProfessionsFrame and ProfessionsFrame_LoadUI and not ProfessionsFrame_LoadUI() then return false end
    local frame = _G.ProfessionsFrame
    if frame and (Hidden(frame) or Hidden(frame.CraftingPage))
        and (not ts.IsTradeSkillReady or ts.IsTradeSkillReady()) then
        local base = ts.GetBaseProfessionInfo and ts.GetBaseProfessionInfo()
        if type(base) == "table" and Number(base.professionID) == skillLineID then
            -- Forever can retain the current skill while showing its Book page.
            -- Its native right tab reveals Recipes without recasting that skill.
            if not Hidden(frame) and frame.rightProfessionTabs then
                for _, tab in ipairs(frame.rightProfessionTabs) do
                    if not Hidden(tab) and Number(tab.skillLine) == skillLineID and type(tab.OnClick) == "function" then
                        tab:OnClick()
                        return true
                    end
                end
            end
            if frame.recipesTabID and OpenProfessionUIToSkillLine then
                OpenProfessionUIToSkillLine(skillLineID)
                return true
            end
        end
    end
    return ts.OpenTradeSkill(skillLineID) == true
end
local function LegacyProfessionMatches(task)
    return type(task.skillName) == "string" and task.skillName ~= ""
        and not Hidden(_G.TradeSkillFrame) and GetTradeSkillLine and GetTradeSkillLine() == task.skillName
end

function F.GetProfessionSpell(skillLineID)
    local client, ts, book = Flux.Client, C_TradeSkillUI, C_SpellBook
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    if not (client and (client.isCamelot or client.isForever) and Integer(skillLineID)
        and ts and ts.CanTradeSkillShowCraftingUI and book and book.GetSpellBookItemInfo
        and bank ~= nil and GetProfessions and GetProfessionInfo) then return end
    local frame = _G.ProfessionsFrame
    if frame and not Hidden(frame) and Hidden(frame.CraftingPage) then
        local base = ts.GetBaseProfessionInfo and ts.GetBaseProfessionInfo()
        if type(base) == "table" and Number(base.professionID) == skillLineID then return end
    end
    -- Use the same owned profession spellbook slot as the native Forever tab.
    local function Find(...)
        for i = 1, select("#", ...) do
            local index = select(i, ...)
            if index then
                local _, _, _, _, _, offset, id = GetProfessionInfo(index)
                if Number(id) == skillLineID and Number(offset) and offset >= 0 and offset % 1 == 0 then
                    local info = book.GetSpellBookItemInfo(offset + 1, bank)
                    local spellID = type(info) == "table" and info.spellID
                    if Integer(spellID) and ts.CanTradeSkillShowCraftingUI(spellID) == true then return spellID end
                end
            end
        end
    end
    return Find(GetProfessions())
end

function F.GetProfessionToOpen(task)
    if type(task) ~= "table" or Foreign() or F.CraftIsBusy(task)
        or (InCombatLockdown and InCombatLockdown()) then return end
    if task.legacy then
        if CastSpellByName and type(task.skillName) == "string" and task.skillName ~= "" and not LegacyProfessionMatches(task) then
            return { name = task.skillName, legacy = true }
        end
        return
    end
    local ts = C_TradeSkillUI
    if not ts or (ts.IsDataSourceChanging and ts.IsDataSourceChanging()) then return end
    local id = ProfessionIDForRecipe(task)
    if not id or ModernProfessionMatches(id) then return end
    local spellID = F.GetProfessionSpell(id)
    if ts.OpenTradeSkill or spellID then return { id = id, name = task.skillName, spellID = spellID } end
end

function F.OpenProfessionTarget(target)
    if target.legacy then CastSpellByName(target.name)
    else return F.OpenProfession(target.id) end
end

function F.UsesNativeCraftHandoff()
    local client = Flux.Client
    return client and (client.isCamelot or client.isForever) or false
end

local function NativeCraftPage()
    local frame = _G.ProfessionsFrame
    local page = frame and frame.CraftingPage
    if not page or Hidden(frame) or Hidden(page) then return end
    if page.SchematicForm then return page end
end

local function NativeRecipe(page)
    local form = page.SchematicForm
    local recipe = form.GetRecipeInfo and form:GetRecipeInfo()
    if type(recipe) == "table" then return recipe end
end

function F.GetNativeCraftSelection(page)
    if not page or page ~= NativeCraftPage() then return end
    local recipe = NativeRecipe(page)
    local quantity = page.CreateMultipleInputBox
    return recipe and Number(recipe.recipeID), quantity and quantity.GetValue and Number(quantity:GetValue())
end

-- Blizzard's Create button reads this field. Create All ignores it.
function F.SetNativeCraftBatch(page, recipeID, operations)
    if not page or page ~= NativeCraftPage() or not Integer(operations) or (InCombatLockdown and InCombatLockdown()) then return end
    local selected = NativeRecipe(page)
    if not selected or Number(selected.recipeID) ~= recipeID then return end
    local quantity = page.CreateMultipleInputBox
    local create = page.CreateButton
    if selected.canCreateMultiple == false and create and create.IsEnabled and create:IsEnabled()
        and quantity and quantity.GetValue and Number(quantity:GetValue()) == 1 then return 1 end
    if not quantity or not quantity.IsEnabled or not quantity:IsEnabled() or not quantity.GetValue
        or not quantity.SetValue or not page.GetCraftableCount then return end
    local craftable = Number(page:GetCraftableCount())
    if not craftable or craftable < 1 then return end
    local count = math.min(operations, math.floor(craftable), selected.canCreateMultiple == false and 1 or 999)
    if Number(quantity:GetValue()) ~= count then quantity:SetValue(count) end
    if Number(quantity:GetValue()) == count then return count end
end

local function OpenNativeCraftRecipe(task, operations)
    local page = NativeCraftPage()
    if not page then return false end
    local recipeID = task.recipeID
    local revealed, reason
    if F.RevealCompanionNativeCraft then revealed, reason = F.RevealCompanionNativeCraft(recipeID, operations) end
    if reason == "busy" then return false end
    local selected = NativeRecipe(page)
    if revealed and Integer(reason) and reason <= operations and selected and Number(selected.recipeID) == recipeID then
        return true, reason, page
    end
    if not (selected and Number(selected.recipeID) == recipeID) and not revealed then
        local lookup = C_TradeSkillUI.GetRecipeInfo
        local info = lookup and lookup(recipeID)
        local highest = type(info) == "table" and Professions and Professions.GetHighestLearnedRecipe
            and Professions.GetHighestLearnedRecipe(info)
        if page.SelectRecipe and type(info) == "table" and Number(info.recipeID) == recipeID and info.learned == true
            and not info.disabled and not info.isRecraft and not info.isDummyRecipe and not info.isGatheringRecipe
            and not info.isEnchantingRecipe and not info.isSalvageRecipe and info.name == task.recipeName
            and (not highest or Number(highest.recipeID) == recipeID) then
            -- Selecting the exact learned recipe can initialize the form even
            -- when an active search keeps its row out of the native list.
            page:SelectRecipe(info, true)
        elseif C_TradeSkillUI.OpenRecipe then C_TradeSkillUI.OpenRecipe(recipeID)
        else return false end
    end
    local count = F.SetNativeCraftBatch(page, recipeID, operations)
    return true, count, page
end
local function BagOperations(task)
    local inv = _G.FluxRestock and _G.FluxRestock.Inv
    if not inv or not inv.GetLiveCount then return 0 end
    local count = task.operations
    for id, required in pairs(task.required) do
        local have
        if A.GetCraftBagAvailable then have = Number(A.GetCraftBagAvailable(id))
        else
            local getLiveCount = inv.GetLiveCount
            if carriedRestockQuery and getLiveCount == carriedRestockGetter then
                have = Number(carriedRestockQuery(id, false))
            else
                have = Number(getLiveCount(id, {
                    bags = true, bank = false, warband = false, equipped = false, charges = false,
                }))
            end
        end
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
    -- Both repeat counters can stay positive between individual player casts.
    if task and task.legacy and GetTradeskillRepeatCount then
        local count = Number(GetTradeskillRepeatCount())
        if count and count > 0 then return true end
    elseif task and F.UsesNativeCraftHandoff() and C_TradeSkillUI and C_TradeSkillUI.GetRemainingRecasts then
        local count = Number(C_TradeSkillUI.GetRemainingRecasts())
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
    if not Integer(task.recipeID) or not ts.GetRecipeInfo
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
        or not A.IsInventoryReliable() or Foreign() then return "unavailable" end
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
        local nativeHandoff = F.UsesNativeCraftHandoff()
        if not ts or (not nativeHandoff and not ts.CraftRecipe) then return "unavailable" end
        if ts.IsDataSourceChanging and ts.IsDataSourceChanging() then return "unavailable" end
        local skillLineID = ProfessionIDForRecipe(task)
        if not skillLineID then return "unavailable" end
        if not ModernProfessionMatches(skillLineID) then
            if not ts.OpenTradeSkill then return "unavailable" end
            return "opening", count, skillLineID
        end
        -- The native handoff selects an already planned recipe. Blizzard's
        -- form validates the live allocations when the player actually crafts.
        if nativeHandoff then
            local page = NativeCraftPage()
            if page and Integer(task.recipeID) then
                local selected = NativeRecipe(page)
                if selected and Number(selected.recipeID) == task.recipeID and selected.canCreateMultiple == false then count = 1 end
                return "ready", count
            end
            return "unavailable"
        end
        local allocation = ModernAllocation(task)
        if not allocation or Foreign() then return "unavailable" end
        return "ready", count, allocation
    end
end
function F.CanCraft(task)
    local status, count = Prepare(task)
    return status == "opening" or status == "ready", count
end
function F.CraftClick(task)
    local status, count, recipe = Prepare(task)
    if status == "opening" then
        if task.legacy then CastSpellByName(task.skillName)
        elseif not F.OpenProfession(recipe) then return "unavailable" end
        status, count, recipe = Prepare(task)
        if status == "opening" then return "opening" end
    end
    if status ~= "ready" then return status end
    -- Forever rejects addon-issued CraftRecipe. Prepare the exact recipe for
    -- the player's press on Blizzard's Create button. Bag evidence credits it.
    if not task.legacy and F.UsesNativeCraftHandoff() then
        local opened, preparedCount, page = OpenNativeCraftRecipe(task, count)
        if opened then return "native_click", preparedCount or count, page, preparedCount end
        return "unavailable"
    end
    task.operations = count
    if task.legacy then
        if SelectTradeSkill then SelectTradeSkill(recipe) end
        DoTradeSkill(recipe, count)
    else C_TradeSkillUI.CraftRecipe(task.recipeID, count, recipe, nil, nil, false) end
    return "crafting", count
end
