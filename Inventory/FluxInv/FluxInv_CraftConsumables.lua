--[[
    Inventory/FluxInv/FluxInv_CraftConsumables.lua

    Absolute-best heal/mana potion and bandage recipes from FluxInv.Professions
    cache + FluxConsumableClassify. Right-click crafts only when bags afford that
    top recipe — never falls back to a worse craftable recipe.
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Craft = Inv.Craft or {}
local Craft = Inv.Craft

local DREAMLESS_SLEEP_IDS = {
    [12190] = true,
    [20002] = true,
    [22836] = true,
}

local ALCHEMY_SKILL_LINE_ID = 171
local TAILORING_SKILL_LINE_ID = 197
local FIRST_AID_SKILL_LINE_ID = 129

local function Prof()
    return Inv.Professions
end

local function Classify()
    return _G.FluxConsumableClassify
end

--- Bags only (never bank / bank bags / warband / equipped).
local function BagCount(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    -- Prefer FluxInv bag snapshot — Index.GetCount defaults bank=true when bank is omitted.
    if Inv.Bags and Inv.Bags.GetCount then
        return Inv.Bags.GetCount(itemID) or 0
    end
    if Inv.GetCount then
        return Inv.GetCount(itemID, {
            bags = true,
            bank = false,
            warband = false,
            equipped = false,
            charges = false,
            includeBank = false,
        }) or 0
    end
    -- Blizzard: includeBank=false (2nd arg).
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID, false, false) or 0
    end
    if GetItemCount then
        return GetItemCount(itemID, false, false) or 0
    end
    return 0
end

--- How many times the recipe can be run from bags. Requires every reagent present
--- (min across all reagents); 0 if any reagent is missing/unresolved.
function Craft.GetCraftableCount(reagentsOrRecipe)
    local reagents = reagentsOrRecipe
    if type(reagentsOrRecipe) == "table" and reagentsOrRecipe.reagents then
        reagents = reagentsOrRecipe.reagents
    end
    if type(reagents) ~= "table" or #reagents == 0 then
        return 0
    end
    local minCraftable = math.huge
    local reagentSlots = 0
    for i = 1, #reagents do
        local r = reagents[i]
        local need = tonumber(r and r.count) or 0
        local itemID = r and tonumber(r.itemID)
        -- Incomplete reagent data → cannot claim craftable (need ALL materials known + in bags).
        if not itemID or need <= 0 then
            return 0
        end
        reagentSlots = reagentSlots + 1
        local have = BagCount(itemID)
        if have < need then
            return 0
        end
        local canMake = math.floor(have / need)
        if canMake < minCraftable then
            minCraftable = canMake
        end
    end
    if reagentSlots == 0 or minCraftable == math.huge or minCraftable ~= minCraftable then
        return 0
    end
    if minCraftable < 1 then
        return 0
    end
    return minCraftable
end

local function EffectiveForKind(kind, cls)
    if not cls then
        return 0
    end
    if kind == "healPotion" then
        return tonumber(cls.health) or tonumber(cls.effective) or 0
    end
    if kind == "manaPotion" then
        return tonumber(cls.mana) or 0
    end
    if kind == "bandage" then
        return tonumber(cls.health) or tonumber(cls.effective) or 0
    end
    return tonumber(cls.effective) or 0
end

local SUBCLASS_POTION = 1
local SUBCLASS_BANDAGE = 7

--- Name / subclass fallback when tooltip classify is pending or unavailable.
--- Keeps craft detection working before item tooltips finish loading.
local function RecipeMatchesKindHeuristic(recipe, kind, itemID)
    local name = (recipe and recipe.name or ""):lower()
    local IC = _G.FluxItemClass
    local st = IC and IC.GetStatic and IC.GetStatic(itemID)
    local subclassID = st and (st.subClassID or st.subclassID)
    if kind == "bandage" then
        if subclassID == SUBCLASS_BANDAGE or name:find("bandage", 1, true) then
            return true, 1
        end
        return false, 0
    end
    if kind == "healPotion" then
        local looksPotion = subclassID == SUBCLASS_POTION
            or name:find("potion", 1, true)
            or name:find("injector", 1, true)
        if looksPotion and not name:find("mana", 1, true)
            and (name:find("heal", 1, true) or name:find("health", 1, true)
                or name:find("healing", 1, true) or name:find("rejuvenation", 1, true)) then
            return true, 1
        end
        return false, 0
    end
    if kind == "manaPotion" then
        local looksPotion = subclassID == SUBCLASS_POTION
            or name:find("potion", 1, true)
            or name:find("injector", 1, true)
        if looksPotion and name:find("mana", 1, true) then
            return true, 1
        end
        return false, 0
    end
    return false, 0
end

local function RecipeMatchesKind(recipe, kind)
    if not recipe or not recipe.outputItemID then
        return false, 0
    end
    local itemID = tonumber(recipe.outputItemID)
    if not itemID or DREAMLESS_SLEEP_IDS[itemID] then
        return false, 0
    end
    local C = Classify()
    if C and C.Classify then
        local cls = C.Classify(itemID, recipe.outputLink, nil, recipe.name)
        if cls and cls.kind == kind then
            return true, EffectiveForKind(kind, cls)
        end
        -- Confirmed different kind: do not heuristic-override.
        if cls and cls.kind and cls.kind ~= kind then
            return false, 0
        end
        -- cls nil → tooltip pending / unloaded; fall through to heuristic.
    end
    return RecipeMatchesKindHeuristic(recipe, kind, itemID)
end

local function EnsureRecipeReagents(recipe)
    if type(recipe) ~= "table" then
        return nil
    end
    if type(recipe.reagents) == "table" and #recipe.reagents > 0 then
        return recipe.reagents
    end
    local recipeID = tonumber(recipe.recipeID)
    if not recipeID or recipe.legacy then
        return recipe.reagents
    end
    local P = Prof()
    if P and P.GetRecipeLive then
        local live = P.GetRecipeLive(recipeID)
        if live and type(live.reagents) == "table" and #live.reagents > 0 then
            recipe.reagents = live.reagents
            return recipe.reagents
        end
    end
    if P and P.GetReagents then
        local reagents = P.GetReagents(recipeID)
        if type(reagents) == "table" and #reagents > 0 then
            recipe.reagents = reagents
            return recipe.reagents
        end
    end
    return recipe.reagents
end

--- Engineering skill line (Classic/Retail). Prefer over Alchemy when both craftable at same restore.
local SKILL_ENGINEERING = 202

local function IsEngineeringRecipe(entry)
    if not entry then
        return false
    end
    local sid = tonumber(entry.skillLineID)
    if sid == SKILL_ENGINEERING then
        return true
    end
    local name = (entry.skillName or ""):lower()
    return name:find("engineering", 1, true) and true or false
end

local function OutputMaxStack(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local Best = _G.FluxConsumableBest
    local Score = Best and Best.Score
    if Score and Score.GetMaxStack then
        return Score.GetMaxStack(itemID) or 0
    end
    if C_Item and C_Item.GetItemMaxStackSizeByID then
        local ok, n = pcall(C_Item.GetItemMaxStackSizeByID, itemID)
        if ok and type(n) == "number" then
            return n
        end
    end
    return 0
end

--- Items produced per single craft (Injector = 20, Super Mana = 1).
function Craft.GetOutputPerCraft(recipeOrEntry)
    if type(recipeOrEntry) ~= "table" then
        return 1
    end
    local amin = tonumber(recipeOrEntry.quantityMin)
    local amax = tonumber(recipeOrEntry.quantityMax)
    local n = amin or amax or tonumber(recipeOrEntry.outputPerCraft)
    if not n or n < 1 then
        n = 1
    end
    return n
end

--- All cached recipes for kind, sorted by restore value desc.
--- Tie-break: Engineering over Alchemy, then larger output maxStack, then higher outputItemID.
function Craft.ListRecipesForKind(kind)
    kind = kind and tostring(kind) or nil
    if kind ~= "healPotion" and kind ~= "manaPotion" and kind ~= "bandage" then
        return {}
    end
    local P = Prof()
    local all = P and P.ListAllCachedRecipes and P.ListAllCachedRecipes() or {}
    local out = {}
    for i = 1, #all do
        local recipe = all[i]
        local ok, eff = RecipeMatchesKind(recipe, kind)
        if ok then
            local outputItemID = tonumber(recipe.outputItemID)
            local reagents = EnsureRecipeReagents(recipe)
            local craftableOps = Craft.GetCraftableCount(reagents)
            local outputPerCraft = Craft.GetOutputPerCraft(recipe)
            out[#out + 1] = {
                recipeID = recipe.recipeID,
                name = recipe.name,
                outputItemID = outputItemID,
                outputLink = recipe.outputLink,
                reagents = reagents,
                legacy = recipe.legacy and true or false,
                skillLineID = recipe.skillLineID,
                skillName = recipe.skillName,
                quantityMin = recipe.quantityMin,
                quantityMax = recipe.quantityMax,
                effective = eff,
                maxStack = OutputMaxStack(outputItemID),
                outputPerCraft = outputPerCraft,
                craftable = craftableOps,
                craftableItems = craftableOps * outputPerCraft,
            }
        end
    end
    table.sort(out, function(a, b)
        if a.effective ~= b.effective then
            return a.effective > b.effective
        end
        -- Same restore: Engineering (injectors) before Alchemy when both listed.
        local aEng, bEng = IsEngineeringRecipe(a), IsEngineeringRecipe(b)
        if aEng ~= bEng then
            return aEng
        end
        local am, bm = tonumber(a.maxStack) or 0, tonumber(b.maxStack) or 0
        if am ~= bm then
            return am > bm
        end
        return (a.outputItemID or 0) > (b.outputItemID or 0)
    end)
    return out
end

--- Absolute best known recipe for kind, only when bags can afford THAT recipe.
--- Never falls back to a worse recipe when mats are short for the top one
--- (e.g. 1 cloth must not unlock the 1-cloth bandage when the best needs 2).
--- Cached per kind + bag generation so bag pulses stay cheap.
local bestCraftCache = {} -- [kind] = { bagGen = number, best = entry|false }

function Craft.InvalidateCanCraftCache()
    wipe(bestCraftCache)
end

function Craft.GetBestCraftable(kind)
    kind = kind and tostring(kind) or nil
    if kind ~= "healPotion" and kind ~= "manaPotion" and kind ~= "bandage" then
        return nil
    end
    local bagGen = 0
    if Inv.Bags and Inv.Bags.GetGeneration then
        bagGen = Inv.Bags.GetGeneration() or 0
    end
    local cached = bestCraftCache[kind]
    if cached and cached.bagGen == bagGen then
        return cached.best ~= false and cached.best or nil
    end
    local list = Craft.ListRecipesForKind(kind)
    local best = nil
    local top = list[1]
    if top then
        local n = top.craftable or Craft.GetCraftableCount(top.reagents)
        if n and n > 0 then
            top.craftable = n
            top.outputPerCraft = top.outputPerCraft or Craft.GetOutputPerCraft(top)
            top.craftableItems = n * (top.outputPerCraft or 1)
            best = top
        end
    end
    bestCraftCache[kind] = { bagGen = bagGen, best = best or false }
    return best
end

--- True when the absolute best known recipe for kind is craftable from bags.
function Craft.CanCraftKind(kind)
    kind = kind and tostring(kind) or nil
    if kind ~= "healPotion" and kind ~= "manaPotion" and kind ~= "bandage" then
        return false
    end
    local best = Craft.GetBestCraftable(kind)
    return best and (tonumber(best.craftable) or 0) > 0
end

local function ProfessionNameForKind(kind, entry)
    if entry and entry.skillName and entry.skillName ~= "" then
        return entry.skillName
    end
    if kind == "bandage" then
        local api = _G.FLUX_API
        if api and api.isPostDF then
            return "Tailoring"
        end
        return "First Aid"
    end
    return "Alchemy"
end

local function SkillLineForKind(kind, entry)
    if entry and entry.skillLineID then
        return tonumber(entry.skillLineID) or entry.skillLineID
    end
    if kind == "bandage" then
        local api = _G.FLUX_API
        if api and api.isPostDF then
            return TAILORING_SKILL_LINE_ID
        end
        return FIRST_AID_SKILL_LINE_ID
    end
    return ALCHEMY_SKILL_LINE_ID
end

--- Resolve bandage profession spell/name the player actually knows (Tailoring post-DF).
function Craft.GetBandageProfessionSpellName()
    local api = _G.FLUX_API
    local isPostDF = api and api.isPostDF
    local tryNames = isPostDF and { "Tailoring" }
        or { "First Aid", "Apprentice First Aid", "Expert First Aid", "Artisan First Aid" }
    if GetSpellInfo and (IsSpellKnown or IsPlayerSpell) then
        for _, spellName in ipairs(tryNames) do
            local id = select(7, GetSpellInfo(spellName))
            if id and ((IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id))) then
                return spellName
            end
        end
    end
    if GetProfessions and GetProfessionInfo then
        local p1, p2, arch, fish, cook, first = GetProfessions()
        if not isPostDF and first then
            local name = select(1, GetProfessionInfo(first))
            if name then
                return name
            end
        end
        for _, idx in ipairs({ p1, p2 }) do
            if idx then
                local name = select(1, GetProfessionInfo(idx))
                if name then
                    local lname = name:lower()
                    if isPostDF and lname:find("tailoring", 1, true) then
                        return name
                    end
                    if not isPostDF and lname:find("first", 1, true) and lname:find("aid", 1, true) then
                        return name
                    end
                end
            end
        end
    end
    return isPostDF and "Tailoring" or "First Aid"
end

local function CraftLegacyByName(recipeName, professionName)
    if not recipeName or recipeName == "" then
        if CastSpellByName and professionName then
            pcall(CastSpellByName, professionName)
        end
        return false
    end
    if not GetNumTradeSkills or not GetTradeSkillInfo or not DoTradeSkill then
        if CastSpellByName and professionName then
            pcall(CastSpellByName, professionName)
        end
        return false
    end
    local num = GetNumTradeSkills() or 0
    if num == 0 then
        if CastSpellByName and professionName then
            pcall(CastSpellByName, professionName)
        end
        return false
    end
    for i = 1, num do
        if GetTradeSkillInfo(i) == recipeName then
            DoTradeSkill(i, 1)
            return true
        end
    end
    if CastSpellByName and professionName then
        pcall(CastSpellByName, professionName)
    end
    return false
end

-- When OpenTradeSkill runs from a click but CraftRecipe needs the UI ready,
-- queue one craft and flush on the next profession-data event.
local pendingCraftRecipeID = nil
local pendingCraftSkillLineID = nil
local pendingCraftExpires = 0

function Craft.ClearPendingCraft()
    pendingCraftRecipeID = nil
    pendingCraftSkillLineID = nil
    pendingCraftExpires = 0
end

local function SkillLineInfoMatches(info, skillLineID)
    if type(info) ~= "table" or not skillLineID then
        return false
    end
    local want = tonumber(skillLineID)
    if not want then
        return false
    end
    -- Parent vs expansion skill lines: match any of the open profession IDs.
    local ids = {
        tonumber(info.professionID),
        tonumber(info.skillLineID),
        tonumber(info.parentProfessionID),
    }
    for i = 1, #ids do
        if ids[i] and ids[i] == want then
            return true
        end
    end
    return false
end

function Craft.TryFlushPendingCraft()
    local recipeID = tonumber(pendingCraftRecipeID)
    if not recipeID then
        return false
    end
    local now = GetTime and GetTime() or 0
    if pendingCraftExpires > 0 and now > pendingCraftExpires then
        Craft.ClearPendingCraft()
        return false
    end
    if not (C_TradeSkillUI and C_TradeSkillUI.CraftRecipe) then
        Craft.ClearPendingCraft()
        return false
    end
    if C_TradeSkillUI.IsTradeSkillReady and not C_TradeSkillUI.IsTradeSkillReady() then
        return false
    end
    local want = tonumber(pendingCraftSkillLineID)
    if want and C_TradeSkillUI.GetProfessionInfo then
        local ok, info = pcall(C_TradeSkillUI.GetProfessionInfo)
        if ok and type(info) == "table" then
            local hasAny = info.professionID or info.skillLineID or info.parentProfessionID
            if hasAny and not SkillLineInfoMatches(info, want) then
                return false
            end
        end
    end
    Craft.ClearPendingCraft()
    pcall(C_TradeSkillUI.CraftRecipe, recipeID, 1)
    return true
end

local function OpenSkillLineMatches(skillLineID)
    skillLineID = tonumber(skillLineID)
    if not skillLineID or not (C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfo) then
        return true
    end
    local ok, info = pcall(C_TradeSkillUI.GetProfessionInfo)
    if not ok or type(info) ~= "table" then
        return true
    end
    local hasAny = info.professionID or info.skillLineID or info.parentProfessionID
    if not hasAny then
        return true
    end
    return SkillLineInfoMatches(info, skillLineID)
end

local function CraftModern(recipeID, skillLineID)
    recipeID = tonumber(recipeID)
    skillLineID = tonumber(skillLineID)
    if not recipeID or not (C_TradeSkillUI and C_TradeSkillUI.CraftRecipe) then
        return false
    end
    local api = _G.FLUX_API
    if api and api.isPostDF then
        local ready = (not C_TradeSkillUI.IsTradeSkillReady) or C_TradeSkillUI.IsTradeSkillReady()
        local matches = OpenSkillLineMatches(skillLineID)
        if (not ready or not matches) and C_TradeSkillUI.OpenTradeSkill and skillLineID then
            -- User click context: OpenTradeSkill is allowed. Queue a follow-up craft
            -- in case the immediate CraftRecipe needs the profession fully ready.
            pcall(C_TradeSkillUI.OpenTradeSkill, skillLineID)
            pendingCraftRecipeID = recipeID
            pendingCraftSkillLineID = skillLineID
            pendingCraftExpires = (GetTime and GetTime() or 0) + 5
        end
    end
    -- Always attempt craft (matches pre-FluxInv scanner). Opening alone used to
    -- return false and required a second right-click.
    pcall(C_TradeSkillUI.CraftRecipe, recipeID, 1)
    return true
end

--- Craft one of the best craftable recipe for kind. Returns true if a craft was attempted.
function Craft.ExecuteCraft(kind)
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    local best = Craft.GetBestCraftable(kind)
    if not best then
        return false
    end
    local professionName = ProfessionNameForKind(kind, best)
    if kind == "bandage" and Craft.GetBandageProfessionSpellName then
        professionName = Craft.GetBandageProfessionSpellName() or professionName
    end
    local skillLineID = SkillLineForKind(kind, best)
    if best.legacy then
        return CraftLegacyByName(best.name, professionName)
    end
    if type(best.recipeID) == "number" then
        return CraftModern(best.recipeID, skillLineID)
    end
    return CraftLegacyByName(best.name, professionName)
end

function Craft.ExecuteHealPotionCraft()
    return Craft.ExecuteCraft("healPotion")
end

function Craft.ExecuteManaPotionCraft()
    return Craft.ExecuteCraft("manaPotion")
end

function Craft.ExecuteBandageCraft()
    return Craft.ExecuteCraft("bandage")
end

_G.FluxInv = Inv
return Craft
