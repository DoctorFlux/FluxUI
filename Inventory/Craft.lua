--[[
    Inventory/Craft.lua

    Right-click crafts only the best heal/mana potion or bandage already in the
    scanned tradeskill list, and only when bags can afford that top recipe.
    Never falls back to a worse known recipe. Does not open the profession as
    a consolation click. Classic reagent tables only fill missing itemIDs on
    scanned rows.

    Forever (camelot): healing potions live on First Aid, not Alchemy. Bandages
    stay on First Aid too — live post-DF moved them to Tailoring, Forever did not.
    Recipe cache comes from GetFilteredRecipeIDs once the skill line is open.
]]
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory

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

local function ProfessionEnumSkillLine(enumValue, fallback)
    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionSkillLineID and enumValue ~= nil then
        local ok, id = pcall(C_TradeSkillUI.GetProfessionSkillLineID, enumValue)
        if ok then
            id = tonumber(id)
            if id and id > 0 then
                return id
            end
        end
    end
    return fallback
end

local function AlchemySkillLineID()
    local E = Enum and Enum.Profession
    return ProfessionEnumSkillLine(E and E.Alchemy, ALCHEMY_SKILL_LINE_ID)
end

local function TailoringSkillLineID()
    local E = Enum and Enum.Profession
    return ProfessionEnumSkillLine(E and E.Tailoring, TAILORING_SKILL_LINE_ID)
end

local function FirstAidSkillLineID()
    local E = Enum and Enum.Profession
    return ProfessionEnumSkillLine(E and E.FirstAid, FIRST_AID_SKILL_LINE_ID)
end

local function Prof()
    return Inv.Professions
end

local function Classify()
    return _G.FluxConsumableClassify
end

local function ClientFlags()
    local C = Flux.Client
    local api = _G.FLUX_API
    return {
        isPostDF = (C and C.isPostDF) or (api and api.isPostDF) or false,
        isCamelot = (C and (C.isCamelot or C.isForever)) or (api and (api.isCamelot or api.isForever)) or false,
        isEra = (C and (C.isEra or C.isClassicEra)) or (api and api.isClassicEra) or false,
        isTBC = (C and C.isTBC) or (api and api.isTBC) or false,
        isWrath = (C and C.isWrath) or (api and api.isWrath) or false,
        isCata = (C and C.isCata) or (api and api.isCata) or false,
        isMists = (C and C.isMists) or (api and api.isMists) or false,
        isRetail = (C and C.isRetail) or (api and api.isRetail) or false,
    }
end

local function IsCamelot()
    return ClientFlags().isCamelot and true or false
end

--- Live Dragonflight+ dropped First Aid. Forever kept it (camelot isPostDF is true).
local function UsesFirstAidProfession()
    return IsCamelot() or not ClientFlags().isPostDF
end

--- Forever moved healing potion recipes onto First Aid.
local function HealPotionsUseFirstAid()
    return IsCamelot()
end

local function LiveBagCount(itemID)
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID, false, false) or 0
    end
    if GetItemCount then
        return GetItemCount(itemID, false, false) or 0
    end
    return 0
end

--- Bags only (never bank / bank bags / warband / equipped).
--- Snapshot (Syndicator or builtin) first; live bags-only fills gaps.
local function BagCount(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local snap = 0
    if Inv.GetCount then
        snap = Inv.GetCount(itemID, {
            bags = true,
            bank = false,
            warband = false,
            equipped = false,
            charges = false,
            includeBank = false,
        }) or 0
    end
    snap = tonumber(snap) or 0
    local live = LiveBagCount(itemID)
    if live > snap then
        return live
    end
    return snap
end

local function ReagentItemID(r)
    if type(r) ~= "table" then
        return nil
    end
    local id = tonumber(r.itemID)
    if id then
        return id
    end
    local name = r.name
    if type(name) ~= "string" or name == "" or not Inv.GetUniqueItems then
        return nil
    end
    local unique = Inv.GetUniqueItems({
        bags = true,
        bank = false,
        warband = false,
        equipped = false,
    })
    if type(unique) ~= "table" then
        return nil
    end
    for itemID in pairs(unique) do
        local iname
        if GetItemInfo then
            iname = GetItemInfo(itemID)
        end
        if iname == name then
            r.itemID = itemID
            return itemID
        end
    end
    return nil
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
        local itemID = ReagentItemID(r)
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

local function IsPostDF()
    return ClientFlags().isPostDF and true or false
end

local function Reagents(pairsList)
    local out = {}
    for i = 1, #pairsList, 2 do
        out[#out + 1] = { itemID = pairsList[i], count = pairsList[i + 1] }
    end
    return out
end

-- Classic/TBC/Wrath/Cata/MoP trainer ladders. Item IDs are locale-safe; names
-- are English fallbacks used only until the profession UI is scanned.
local STATIC_RECIPES = {
    bandage = {
        { name = "Linen Bandage", outputItemID = 1251, skillReq = 1, exp = 0, reagents = Reagents({ 2589, 1 }) },
        { name = "Heavy Linen Bandage", outputItemID = 2581, skillReq = 40, exp = 0, reagents = Reagents({ 2589, 2 }) },
        { name = "Wool Bandage", outputItemID = 3530, skillReq = 80, exp = 0, reagents = Reagents({ 2592, 1 }) },
        { name = "Heavy Wool Bandage", outputItemID = 3531, skillReq = 115, exp = 0, reagents = Reagents({ 2592, 2 }) },
        { name = "Silk Bandage", outputItemID = 6450, skillReq = 150, exp = 0, reagents = Reagents({ 4306, 1 }) },
        { name = "Heavy Silk Bandage", outputItemID = 6451, skillReq = 180, exp = 0, reagents = Reagents({ 4306, 2 }) },
        { name = "Mageweave Bandage", outputItemID = 8544, skillReq = 210, exp = 0, reagents = Reagents({ 4338, 1 }) },
        { name = "Heavy Mageweave Bandage", outputItemID = 8545, skillReq = 240, exp = 0, reagents = Reagents({ 4338, 2 }) },
        { name = "Runecloth Bandage", outputItemID = 14529, skillReq = 260, exp = 0, reagents = Reagents({ 14047, 1 }) },
        { name = "Heavy Runecloth Bandage", outputItemID = 14530, skillReq = 290, exp = 0, reagents = Reagents({ 14047, 2 }) },
        { name = "Netherweave Bandage", outputItemID = 21990, skillReq = 300, exp = 1, reagents = Reagents({ 21877, 1 }) },
        { name = "Heavy Netherweave Bandage", outputItemID = 21991, skillReq = 330, exp = 1, reagents = Reagents({ 21877, 2 }) },
        { name = "Frostweave Bandage", outputItemID = 34721, skillReq = 350, exp = 2, reagents = Reagents({ 33470, 1 }) },
        { name = "Heavy Frostweave Bandage", outputItemID = 34722, skillReq = 400, exp = 2, reagents = Reagents({ 33470, 2 }) },
        { name = "Embersilk Bandage", outputItemID = 53049, skillReq = 425, exp = 3, reagents = Reagents({ 53010, 1 }) },
        { name = "Heavy Embersilk Bandage", outputItemID = 53050, skillReq = 475, exp = 3, reagents = Reagents({ 53010, 2 }) },
        { name = "Dense Embersilk Bandage", outputItemID = 53051, skillReq = 525, exp = 3, reagents = Reagents({ 53010, 3 }) },
        { name = "Windwool Bandage", outputItemID = 72985, skillReq = 500, exp = 4, reagents = Reagents({ 72988, 1 }) },
        { name = "Heavy Windwool Bandage", outputItemID = 72986, skillReq = 550, exp = 4, reagents = Reagents({ 72988, 2 }) },
    },
    healPotion = {
        { name = "Minor Healing Potion", outputItemID = 118, skillReq = 1, exp = 0, reagents = Reagents({ 2447, 1, 765, 1, 3371, 1 }) },
        { name = "Lesser Healing Potion", outputItemID = 858, skillReq = 55, exp = 0, reagents = Reagents({ 118, 1, 2450, 1 }) },
        { name = "Healing Potion", outputItemID = 929, skillReq = 110, exp = 0, reagents = Reagents({ 2453, 1, 2450, 1, 3372, 1 }) },
        { name = "Greater Healing Potion", outputItemID = 1710, skillReq = 155, exp = 0, reagents = Reagents({ 3357, 1, 3356, 1, 3372, 1 }) },
        { name = "Superior Healing Potion", outputItemID = 3928, skillReq = 215, exp = 0, reagents = Reagents({ 8838, 1, 3358, 1, 8925, 1 }) },
        { name = "Major Healing Potion", outputItemID = 13446, skillReq = 275, exp = 0, reagents = Reagents({ 13464, 2, 13465, 1, 8925, 1 }) },
        { name = "Super Healing Potion", outputItemID = 22829, skillReq = 325, exp = 1, reagents = Reagents({ 22791, 2, 22785, 1, 18256, 1 }) },
    },
    manaPotion = {
        { name = "Minor Mana Potion", outputItemID = 2455, skillReq = 25, exp = 0, reagents = Reagents({ 785, 1, 765, 1, 3371, 1 }) },
        { name = "Lesser Mana Potion", outputItemID = 3385, skillReq = 120, exp = 0, reagents = Reagents({ 785, 1, 3820, 1, 3371, 1 }) },
        { name = "Mana Potion", outputItemID = 3827, skillReq = 160, exp = 0, reagents = Reagents({ 3820, 1, 3356, 1, 3372, 1 }) },
        { name = "Greater Mana Potion", outputItemID = 6149, skillReq = 185, exp = 0, reagents = Reagents({ 3357, 1, 3358, 1, 3372, 1 }) },
        { name = "Superior Mana Potion", outputItemID = 13443, skillReq = 260, exp = 0, reagents = Reagents({ 8838, 2, 8839, 2, 8925, 1 }) },
        { name = "Major Mana Potion", outputItemID = 13444, skillReq = 275, exp = 0, reagents = Reagents({ 13463, 3, 13467, 1, 8925, 1 }) },
        { name = "Super Mana Potion", outputItemID = 22832, skillReq = 340, exp = 1, reagents = Reagents({ 22786, 2, 22785, 1, 18256, 1 }) },
    },
}

local function ProfessionNeedlesForKind(kind)
    if kind == "healPotion" then
        if HealPotionsUseFirstAid() then
            return { "first aid" }
        end
        return { "alchemy" }
    end
    if kind == "manaPotion" then
        return { "alchemy" }
    end
    if kind == "bandage" then
        if UsesFirstAidProfession() then
            return { "first aid" }
        end
        return { "tailoring" }
    end
    return nil
end

local PROFESSION_SPELLS_BANDAGE = { 3273, 3274, 7924, 10846, 27028, 45542, 74559, 110406 }
local PROFESSION_SPELLS_TAILORING = { 3908, 3909, 3910, 12180, 26790, 51309, 75156, 110426 }
local PROFESSION_SPELLS_ALCHEMY = { 2259, 3101, 3464, 11611, 28596, 51304, 80731, 105206 }

local function AnyProfessionSpellKnown(ids)
    if type(ids) ~= "table" then
        return false
    end
    for i = 1, #ids do
        local id = ids[i]
        if id and IsPlayerSpell and IsPlayerSpell(id) then
            return true
        end
        if id and IsSpellKnown and IsSpellKnown(id) then
            return true
        end
    end
    return false
end

local function SpellLooksKnown(spellName)
    if not spellName or spellName == "" or not GetSpellInfo then
        return false
    end
    local _, _, _, _, _, _, spellID = GetSpellInfo(spellName)
    if spellID then
        if IsPlayerSpell and IsPlayerSpell(spellID) then
            return true
        end
        if IsSpellKnown and IsSpellKnown(spellID) then
            return true
        end
    end
    return false
end

function Craft.HasProfessionForKind(kind)
    kind = kind and tostring(kind) or nil
    local needles = ProfessionNeedlesForKind(kind)
    if not needles then
        return false
    end
    local P = Prof()
    if P and P.HasProfessionName and P.HasProfessionName(needles) then
        return true
    end
    local function HasFirstAid()
        return AnyProfessionSpellKnown(PROFESSION_SPELLS_BANDAGE)
            or SpellLooksKnown("First Aid")
            or SpellLooksKnown("Apprentice First Aid")
            or SpellLooksKnown("Expert First Aid")
            or SpellLooksKnown("Artisan First Aid")
    end
    if kind == "bandage" then
        if UsesFirstAidProfession() then
            return HasFirstAid()
        end
        return AnyProfessionSpellKnown(PROFESSION_SPELLS_TAILORING) or SpellLooksKnown("Tailoring")
    end
    if kind == "healPotion" and HealPotionsUseFirstAid() then
        return HasFirstAid()
    end
    return AnyProfessionSpellKnown(PROFESSION_SPELLS_ALCHEMY)
        or SpellLooksKnown("Alchemy")
        or SpellLooksKnown("Apprentice Alchemy")
end

local function FillReagentsFromStatic(recipe, kind)
    if type(recipe) ~= "table" then
        return recipe and recipe.reagents
    end
    local reagents = recipe.reagents
    local missing = type(reagents) ~= "table" or #reagents == 0
    if not missing then
        for i = 1, #reagents do
            if not tonumber(reagents[i] and reagents[i].itemID) then
                missing = true
                break
            end
        end
    end
    if not missing then
        return reagents
    end
    local ladders = STATIC_RECIPES[kind]
    if type(ladders) ~= "table" then
        return reagents
    end
    local oid = tonumber(recipe.outputItemID)
    local rname = recipe.name
    for i = 1, #ladders do
        local s = ladders[i]
        if (oid and s.outputItemID == oid) or (rname and s.name == rname) then
            recipe.reagents = s.reagents
            return s.reagents
        end
    end
    return reagents
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

local function IsFirstAidRecipe(entry)
    if not entry then
        return false
    end
    local sid = tonumber(entry.skillLineID)
    local firstAidID = FirstAidSkillLineID()
    if sid and (sid == FIRST_AID_SKILL_LINE_ID or sid == firstAidID) then
        return true
    end
    local name = (entry.skillName or ""):lower()
    return name:find("first", 1, true) and name:find("aid", 1, true) and true or false
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
    local raw = {}
    for i = 1, #all do
        local recipe = all[i]
        local ok, eff = RecipeMatchesKind(recipe, kind)
        if ok then
            raw[#raw + 1] = { recipe = recipe, effective = eff }
        end
    end
    -- Forever heal potions (and Classic/Forever bandages) must not lose to a
    -- leftover Alchemy/Tailoring row of the same item sitting in the cache.
    local preferFirstAid = (kind == "healPotion" and HealPotionsUseFirstAid())
        or (kind == "bandage" and UsesFirstAidProfession())
    if preferFirstAid then
        local firstAidOnly = {}
        for i = 1, #raw do
            if IsFirstAidRecipe(raw[i].recipe) then
                firstAidOnly[#firstAidOnly + 1] = raw[i]
            end
        end
        if #firstAidOnly > 0 then
            raw = firstAidOnly
        else
            local untagged = {}
            for i = 1, #raw do
                local r = raw[i].recipe
                if not r.skillLineID and (not r.skillName or r.skillName == "") then
                    untagged[#untagged + 1] = raw[i]
                end
            end
            raw = untagged
        end
    end
    local out = {}
    for i = 1, #raw do
        local recipe = raw[i].recipe
        local eff = raw[i].effective
        local outputItemID = tonumber(recipe.outputItemID)
        EnsureRecipeReagents(recipe)
        local reagents = FillReagentsFromStatic(recipe, kind)
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

--- Absolute best known tradeskill recipe for kind, only when bags afford THAT recipe.
--- Never falls back to a worse recipe when mats are short for the top one.
local bestCraftCache = {} -- [kind] = { bagGen = number, best = entry|false }

function Craft.InvalidateCanCraftCache()
    wipe(bestCraftCache)
end

-- Cached recipe dependencies let HUD bag listeners skip unrelated loot/restacks.
-- Unknown or incomplete recipe data stays conservative until the next scan.
function Craft.BagChangesAffectKind(kind, changedItemIDs)
    local cached = bestCraftCache[kind]
    if not changedItemIDs or not cached or not cached.reagentIDs then
        return true
    end
    for id in pairs(changedItemIDs) do
        if cached.reagentIDs[id] then
            return true
        end
    end
    return false
end

function Craft.GetBestCraftable(kind)
    kind = kind and tostring(kind) or nil
    if kind ~= "healPotion" and kind ~= "manaPotion" and kind ~= "bandage" then
        return nil
    end
    local bagGen = 0
    if Inv.GetBagGeneration then
        bagGen = Inv.GetBagGeneration() or 0
    elseif Inv.Bags and Inv.Bags.GetGeneration then
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
    local reagentIDs = {}
    for _, recipe in ipairs(list) do
        if not recipe.reagents or #recipe.reagents == 0 then
            reagentIDs = nil
            break
        end
        for _, reagent in ipairs(recipe.reagents) do
            local id = ReagentItemID(reagent)
            if not id then
                reagentIDs = nil
                break
            end
            reagentIDs[id] = true
        end
        if not reagentIDs then break end
    end
    bestCraftCache[kind] = { bagGen = bagGen, best = best or false, reagentIDs = reagentIDs }
    return best
end

--- True when bags can afford the single best scanned recipe for kind.
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
        if UsesFirstAidProfession() then
            return "First Aid"
        end
        return "Tailoring"
    end
    if kind == "healPotion" and HealPotionsUseFirstAid() then
        return "First Aid"
    end
    return "Alchemy"
end

local function SkillLineForKind(kind, entry)
    if entry and entry.skillLineID then
        return tonumber(entry.skillLineID) or entry.skillLineID
    end
    if kind == "bandage" then
        if UsesFirstAidProfession() then
            return FirstAidSkillLineID()
        end
        return TailoringSkillLineID()
    end
    if kind == "healPotion" and HealPotionsUseFirstAid() then
        return FirstAidSkillLineID()
    end
    return AlchemySkillLineID()
end

--- Resolve First Aid / Tailoring spell the player actually knows.
--- Bandages: First Aid except live post-DF Tailoring. Forever heal pots: First Aid.
function Craft.GetBandageProfessionSpellName()
    local useFirstAid = UsesFirstAidProfession()
    local tryNames = useFirstAid
        and { "First Aid", "Apprentice First Aid", "Expert First Aid", "Artisan First Aid" }
        or { "Tailoring" }
    if GetSpellInfo and (IsSpellKnown or IsPlayerSpell) then
        for _, spellName in ipairs(tryNames) do
            local id = select(7, GetSpellInfo(spellName))
            if id and ((IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id))) then
                return spellName
            end
        end
    end
    if GetProfessions and GetProfessionInfo then
        local indices = { GetProfessions() }
        for i = 1, #indices do
            local idx = indices[i]
            if idx then
                local name = select(1, GetProfessionInfo(idx))
                if name then
                    local lname = name:lower()
                    if not useFirstAid and lname:find("tailoring", 1, true) then
                        return name
                    end
                    if useFirstAid and lname:find("first", 1, true) and lname:find("aid", 1, true) then
                        return name
                    end
                end
            end
        end
    end
    if GetNumSkillLines and GetSkillLineInfo then
        local n = GetNumSkillLines() or 0
        for i = 1, n do
            local name, isHeader = GetSkillLineInfo(i)
            if name and not isHeader then
                local lname = name:lower()
                if not useFirstAid and lname:find("tailoring", 1, true) then
                    return name
                end
                if useFirstAid and lname:find("first", 1, true) and lname:find("aid", 1, true) then
                    return name
                end
            end
        end
    end
    return useFirstAid and "First Aid" or "Tailoring"
end

local function FindLegacySkillIndex(recipeName)
    if not recipeName or recipeName == "" then
        return nil
    end
    if not GetNumTradeSkills or not GetTradeSkillInfo then
        return nil
    end
    local num = GetNumTradeSkills() or 0
    local want = recipeName:lower()
    for i = 1, num do
        local name = GetTradeSkillInfo(i)
        if name and (name == recipeName or name:lower() == want) then
            return i
        end
    end
    return nil
end

--- DoTradeSkill is protected. Call only from a hardware click (the RC proxy),
--- never from TRADE_SKILL_* / timers. Opening the window from this click can
--- fill the list before we return; then craft in the same click.
local function CraftLegacyByName(recipeName, professionName)
    local function tryCraft()
        local index = FindLegacySkillIndex(recipeName)
        if not index or not DoTradeSkill then
            return false
        end
        local ok = pcall(DoTradeSkill, index, 1)
        return ok and true or false
    end
    if tryCraft() then
        return true
    end
    if CastSpellByName and professionName then
        pcall(CastSpellByName, professionName)
    end
    return tryCraft()
end

-- CraftRecipe / DoTradeSkill are protected. Never flush a craft from
-- TRADE_SKILL_* (that is what triggered ADDON_ACTION_BLOCKED).
function Craft.ClearPendingCraft()
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

local function OpenProfessionInfo()
    local P = Prof()
    if P and P.GetOpenProfessionInfo then
        return P.GetOpenProfessionInfo()
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfo then
        local ok, info = pcall(C_TradeSkillUI.GetProfessionInfo)
        if ok and type(info) == "table" then
            return info
        end
    end
    return nil
end

local function OpenSkillLineMatches(skillLineID)
    skillLineID = tonumber(skillLineID)
    if not skillLineID then
        return true
    end
    local info = OpenProfessionInfo()
    if type(info) ~= "table" then
        return true
    end
    local hasAny = info.professionID or info.skillLineID or info.parentProfessionID
    if not hasAny or hasAny == 0 then
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
    if IsPostDF() then
        local ready = (not C_TradeSkillUI.IsTradeSkillReady) or C_TradeSkillUI.IsTradeSkillReady()
        local matches = OpenSkillLineMatches(skillLineID)
        if (not ready or not matches) and C_TradeSkillUI.OpenTradeSkill and skillLineID then
            -- User click context: OpenTradeSkill is allowed. Craft in this same
            -- click if the list is already live; do not queue CraftRecipe on events.
            pcall(C_TradeSkillUI.OpenTradeSkill, skillLineID)
        end
    end
    -- Always attempt craft (matches pre-FluxInv scanner). Opening alone used to
    -- return false and required a second right-click.
    pcall(C_TradeSkillUI.CraftRecipe, recipeID, 1)
    return true
end

local function KindOpensFirstAid(kind)
    return kind == "bandage" and UsesFirstAidProfession()
        or (kind == "healPotion" and HealPotionsUseFirstAid())
end

local function DispatchBest(kind, best)
    local professionName = ProfessionNameForKind(kind, best)
    if KindOpensFirstAid(kind) and Craft.GetBandageProfessionSpellName then
        professionName = Craft.GetBandageProfessionSpellName() or professionName
    end
    local skillLineID = SkillLineForKind(kind, best)
    if best.legacy or best.static or type(best.recipeID) ~= "number" then
        return CraftLegacyByName(best.name, professionName)
    end
    return CraftModern(best.recipeID, skillLineID)
end

--- Profession events may scan recipes; they must not call DoTradeSkill/CraftRecipe.
function Craft.TryFlushPendingCraft()
    Craft.InvalidateCanCraftCache()
    return false
end

-- Two overlapping HUD hosts must not run heal and mana in the same press.
-- Same-kind retry is allowed when the first dispatch failed (open profession,
-- then craft on the matching up). A successful dispatch blocks a second
-- craft of that same kind so AnyDown+AnyUp /click cannot make two items.
local lastCraftAt = 0
local lastCraftKind = nil
local lastCraftSucceeded = false
local CRAFT_CLICK_LOCK_SEC = 0.2

--- Craft the top scanned recipe only when bags afford it. Does not open the
--- profession as a consolation click.
function Craft.ExecuteCraft(kind)
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    kind = kind and tostring(kind) or nil
    if kind ~= "healPotion" and kind ~= "manaPotion" and kind ~= "bandage" then
        return false
    end
    local now = GetTime and GetTime() or 0
    if lastCraftAt > 0 and (now - lastCraftAt) < CRAFT_CLICK_LOCK_SEC then
        if lastCraftKind ~= kind then
            return false
        end
        if lastCraftSucceeded then
            return false
        end
    end
    local P = Prof()
    if P and P.ForceScanOpen then
        pcall(P.ForceScanOpen)
        Craft.InvalidateCanCraftCache()
    end
    local best = Craft.GetBestCraftable(kind)
    -- Forever caches nothing until C_TradeSkillUI.GetFilteredRecipeIDs can run.
    -- Hardware click may open the skill line, scan learned recipes, then craft.
    if not best then
        local known = Craft.ListRecipesForKind(kind)
        if (not known or #known == 0) and Craft.HasProfessionForKind(kind) then
            local skillLineID = tonumber(SkillLineForKind(kind))
            if skillLineID and C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
                pcall(C_TradeSkillUI.OpenTradeSkill, skillLineID)
                if P and P.ForceScanOpen then
                    pcall(P.ForceScanOpen)
                    Craft.InvalidateCanCraftCache()
                end
                best = Craft.GetBestCraftable(kind)
            end
        end
    end
    if not best then
        return false
    end
    lastCraftAt = now
    lastCraftKind = kind
    local ok = DispatchBest(kind, best)
    lastCraftSucceeded = ok and true or false
    return ok
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

local FluxInv = _G.FluxInv
if FluxInv then
    FluxInv.Craft = Craft
end
return Craft
