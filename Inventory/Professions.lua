--[[
    Inventory/Professions.lua

    Layered profession recipe cache:
      Tier C — live API when data is loaded
      Tier B — paced login/reload scan (best-effort; aborts in combat)
      Tier A — authoritative scan when profession UI is open

    Forever (camelot) lists recipes with GetFilteredRecipeIDs / GetProfessionSpells
    and identifies the open skill via GetChildProfessionInfo / GetBaseProfessionInfo.
    GetAllRecipeIDs and GetProfessionInfo are Classic/live leftovers and may be missing.
]]
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory

Inv.Professions = Inv.Professions or {}
local Prof = Inv.Professions

local wipe = table.wipe or wipe
local HAS_MODERN_PROF = (C_TradeSkillUI ~= nil and type(C_TradeSkillUI.GetRecipeInfo) == "function")
local scanBusy = false

local function HasModernRecipeList()
    return C_TradeSkillUI and (
        type(C_TradeSkillUI.GetAllRecipeIDs) == "function"
        or type(C_TradeSkillUI.GetFilteredRecipeIDs) == "function"
        or type(C_TradeSkillUI.GetProfessionSpells) == "function"
    ) and true or false
end

--- Forever has no C_TradeSkillUI.GetProfessionInfo. Blizzard uses child, then base.
function Prof.GetOpenProfessionInfo()
    if not C_TradeSkillUI then
        return nil
    end
    local info
    if C_TradeSkillUI.GetChildProfessionInfo then
        local ok, child = pcall(C_TradeSkillUI.GetChildProfessionInfo)
        if ok and type(child) == "table" and (tonumber(child.professionID) or 0) ~= 0 then
            info = child
        end
    end
    if (not info or (tonumber(info.professionID) or 0) == 0) and C_TradeSkillUI.GetBaseProfessionInfo then
        local ok, base = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
        if ok and type(base) == "table" and (tonumber(base.professionID) or 0) ~= 0 then
            info = base
        end
    end
    if (not info or (tonumber(info.professionID) or 0) == 0) and C_TradeSkillUI.GetProfessionInfo then
        local ok, legacy = pcall(C_TradeSkillUI.GetProfessionInfo)
        if ok and type(legacy) == "table" then
            info = legacy
        end
    end
    if type(info) ~= "table" then
        return nil
    end
    return info
end

local function AppendRecipeIDs(dst, seen, list)
    if type(list) ~= "table" then
        return
    end
    for i = 1, #list do
        local id = tonumber(list[i])
        if id and not seen[id] then
            seen[id] = true
            dst[#dst + 1] = id
        end
    end
end

--- Forever (camelot) lists recipes with GetFilteredRecipeIDs. GetAllRecipeIDs is
--- Classic C_TradeSkillUI and is missing there. Merge every available source.
local function ListOpenRecipeIDs()
    if not C_TradeSkillUI then
        return nil
    end
    local ids, seen, filtered = {}, {}, nil
    if type(C_TradeSkillUI.GetAllRecipeIDs) == "function" then
        local ok, list = pcall(C_TradeSkillUI.GetAllRecipeIDs)
        if ok then
            AppendRecipeIDs(ids, seen, list)
        end
    end
    if type(C_TradeSkillUI.GetFilteredRecipeIDs) == "function" then
        local ok, list = pcall(C_TradeSkillUI.GetFilteredRecipeIDs)
        if ok then
            AppendRecipeIDs(ids, seen, list)
            filtered = list
        end
    end
    local info = Prof.GetOpenProfessionInfo()
    if info and type(C_TradeSkillUI.GetProfessionSpells) == "function" then
        local profEnum = info.profession
        if profEnum ~= nil then
            local ok, list = pcall(C_TradeSkillUI.GetProfessionSpells, profEnum, info.professionID)
            if ok then
                AppendRecipeIDs(ids, seen, list)
            end
            if info.parentProfessionID then
                ok, list = pcall(C_TradeSkillUI.GetProfessionSpells, profEnum, info.parentProfessionID)
                if ok then
                    AppendRecipeIDs(ids, seen, list)
                end
            end
        end
    end
    if #ids == 0 then
        return nil
    end
    return ids, seen, filtered
end

local nativeTradeSkill, nativeSpellBook = C_TradeSkillUI, C_SpellBook
local nativeOpenProfession = Prof.GetOpenProfessionInfo
local spellInBook = nativeSpellBook and nativeSpellBook.IsSpellInSpellBook
local spellBookBank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
local learnedFilterValues = {
    GetShowLearned = true, GetShowUnlearned = false,
    GetOnlyShowMakeableRecipes = false, GetOnlyShowSkillUpRecipes = false,
    GetOnlyShowFirstCraftRecipes = false, AreAnyInventorySlotsFiltered = false,
    AnyRecipeCategoriesFiltered = false, GetRecipeItemNameFilter = "",
    IsTradeSkillReady = true, IsDataSourceChanging = false,
}
local function CaptureLearnedFilterReaders()
    if not nativeTradeSkill or type(spellInBook) ~= "function" or spellBookBank == nil
        or not issecurevariable or not issecurevariable(nativeSpellBook, "IsSpellInSpellBook") then return end
    local readers = {}
    for _, name in ipairs({ "GetAllRecipeIDs", "GetFilteredRecipeIDs", "GetRecipeInfo" }) do
        if type(nativeTradeSkill[name]) ~= "function" or not issecurevariable(nativeTradeSkill, name) then return end
        readers[name] = nativeTradeSkill[name]
    end
    for name in pairs(learnedFilterValues) do
        if type(nativeTradeSkill[name]) ~= "function" or not issecurevariable(nativeTradeSkill, name) then return end
        readers[name] = nativeTradeSkill[name]
    end
    return readers
end
local learnedFilterReaders = CaptureLearnedFilterReaders()

local settledRecipeList, recipeListRevision = nil, 0
local function ForgetSettledRecipeList()
    settledRecipeList = nil
    recipeListRevision = recipeListRevision + 1
end

local function ObserveLearnedRecipeList(info, ids, recipeIDs, filtered)
    if not learnedFilterReaders or C_TradeSkillUI ~= nativeTradeSkill or C_SpellBook ~= nativeSpellBook
        or nativeSpellBook.IsSpellInSpellBook ~= spellInBook or Prof.GetOpenProfessionInfo ~= nativeOpenProfession
        or type(filtered) ~= "table" or #filtered == 0 then return end
    for name, reader in pairs(learnedFilterReaders) do
        if nativeTradeSkill[name] ~= reader then return end
    end
    for name, expected in pairs(learnedFilterValues) do
        local ok, value = pcall(learnedFilterReaders[name])
        if not ok or (issecretvalue and issecretvalue(value)) or value ~= expected then return end
    end
    local ui = _G.Professions
    local sourcesUnfiltered = ui and ui.AreAllSourcesUnfiltered
    if type(sourcesUnfiltered) ~= "function" or not issecurevariable(ui, "AreAllSourcesUnfiltered") then return end
    local ok, allSources = pcall(sourcesUnfiltered)
    if not ok or (issecretvalue and issecretvalue(allSources)) or allSources ~= true then return end

    local visible = {}
    for _, id in ipairs(filtered) do
        if type(id) ~= "number" or (issecretvalue and issecretvalue(id)) or not recipeIDs[id] or visible[id] then return end
        visible[id] = true
    end
    return { parent = info.parentProfessionID, profession = info.professionID or info.skillLineID,
        ui = ui, sourcesUnfiltered = sourcesUnfiltered, ids = recipeIDs, count = #ids,
        visible = visible, visibleCount = #filtered, revision = recipeListRevision }
end

local function SameLearnedRecipeList(current, previous)
    if not current or not previous or current.parent ~= previous.parent or current.profession ~= previous.profession
        or current.ui ~= previous.ui or current.sourcesUnfiltered ~= previous.sourcesUnfiltered
        or current.revision ~= previous.revision or current.count ~= previous.count
        or current.visibleCount ~= previous.visibleCount then return false end
    for id in pairs(current.ids) do if not previous.ids[id] then return false end end
    for id in pairs(current.visible) do if not previous.visible[id] then return false end end
    return true
end

local function ConfirmStillUnlearned(recipeID)
    local ok, learned = pcall(spellInBook, recipeID, spellBookBank, false)
    return ok and not (issecretvalue and issecretvalue(learned)) and learned == false
end

local function TradeSkillDataNotReady()
    if not C_TradeSkillUI then
        return false
    end
    if C_TradeSkillUI.IsDataSourceChanging then
        local ok, changing = pcall(C_TradeSkillUI.IsDataSourceChanging)
        if ok and changing then
            return true
        end
    end
    if C_TradeSkillUI.IsTradeSkillReady then
        local ok, ready = pcall(C_TradeSkillUI.IsTradeSkillReady)
        if ok and ready == false then
            return true
        end
    end
    return false
end

local function IsForeignProfession()
    return (IsTradeSkillLinked and IsTradeSkillLinked())
        or (C_TradeSkillUI and C_TradeSkillUI.IsTradeSkillLinked and C_TradeSkillUI.IsTradeSkillLinked())
        or (C_TradeSkillUI and C_TradeSkillUI.IsTradeSkillGuild and C_TradeSkillUI.IsTradeSkillGuild())
        or (C_TradeSkillUI and C_TradeSkillUI.IsNPCCrafting and C_TradeSkillUI.IsNPCCrafting()) or false
end

local function After(delay, fn)
    if Flux.Timer and Flux.Timer.After then
        Flux.Timer.After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

local function InCombat()
    if Flux.Combat and Flux.Combat.InLockdown then
        return Flux.Combat.InLockdown()
    end
    return (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) or false
end

local function SafeRegisterEvent(frame, eventName)
    if not frame or not eventName or eventName == "" then
        return false
    end
    local ok = pcall(frame.RegisterEvent, frame, eventName)
    return ok
end

FluxInvDB = FluxInvDB or {}

local sessionCache = {} -- skillKey -> { recipes, scannedAt, source, name }
local loginScanQueued = false
local loginScanRunning = false
local loginScanAbort = false
local loginScanCompleted = false
local openSkillKey = nil

local function CharKey()
    local PN = Flux and Flux.PlayerName
    if PN and PN.GetCharKey then
        local key = PN.GetCharKey("professions")
        if key then
            return key
        end
    end
    local realm = GetRealmName and GetRealmName() or "Unknown"
    local character = UnitName and UnitName("player") or "Unknown"
    return realm .. "-" .. character
end

function Prof.GetCharacterKey()
    local PN = Flux and Flux.PlayerName
    if PN and PN.GetCharKey then
        local key = PN.GetCharKey("professions")
        return type(key) == "string" and key ~= "" and key or nil
    end
    local realm = GetRealmName and GetRealmName()
    local character = UnitName and UnitName("player")
    if type(realm) ~= "string" or realm == "" or type(character) ~= "string" or character == "" then return nil end
    return realm .. "-" .. character
end

local function EnsureDB()
    FluxInvDB = FluxInvDB or {}
    FluxInvDB.professions = FluxInvDB.professions or {}
    local key = CharKey()
    FluxInvDB.professions[key] = FluxInvDB.professions[key] or { bySkillLine = {} }
    return FluxInvDB.professions[key]
end

local BuildCachedRecipeCatalogue, OwnedListAllCachedRecipes, RankObservedRecipes

local function PlainModernAliasRecipe(recipe)
    if type(recipe) ~= "table" or getmetatable(recipe) ~= nil or recipe.legacy then return false end
    local id = recipe.recipeID
    return type(id) == "number" and (not issecretvalue or not issecretvalue(id))
        and id >= 1 and id <= 2147483647 and id % 1 == 0
end

local function AliasNeedsSync(data, observations, numericOnly)
    if getmetatable(data) ~= nil then return true end
    local recipes, removed = data.recipes, data.unlearnedRecipeIDs
    if getmetatable(recipes) ~= nil or getmetatable(removed) ~= nil then return true end
    -- The numeric and named entries can reconcile the same observation during one scan.
    for _, recipe in ipairs(recipes or {}) do
        if getmetatable(recipe) ~= nil then return true end
        if numericOnly and not PlainModernAliasRecipe(recipe) then return true end
        if not recipe.legacy then
            local observed = observations[recipe.recipeID]
            if observed ~= nil and (not removed or not rawequal(observed, recipe)) then return true end
        end
    end
    for id, tombstone in pairs(removed or {}) do
        local observed = observations[id]
        if observed ~= nil and (not recipes or observed ~= false or tombstone ~= true) then return true end
    end
    return false
end

-- The first save can already have propagated every observed recipe to the
-- named alias. Reuse only complete reconciliations with the original catalogue.
local function ReuseNamedAliasRecipes(db, previous, payload)
    if math.type or not payload.ownedRecipeScan or Prof.ListAllCachedRecipes ~= OwnedListAllCachedRecipes
        or type(previous) ~= "table" or getmetatable(previous) ~= nil
        or type(db.bySkillLine) ~= "table" or getmetatable(db.bySkillLine) ~= nil then return end
    local recipes, observed, old = payload.recipes, payload.observedRecipes, previous.recipes
    if type(observed) ~= "table" or type(old) ~= "table" or getmetatable(old) ~= nil
        or #recipes == 0 or #recipes ~= #observed or #recipes ~= #old then return end

    local observations = {}
    local out = {}
    for index, recipe in ipairs(recipes) do
        local fresh = observed[index]
        if not PlainModernAliasRecipe(recipe) or not PlainModernAliasRecipe(fresh)
            or fresh.recipeID ~= recipe.recipeID or observations[recipe.recipeID] ~= nil then return end
        local reagents, crafting = recipe.reagents, recipe.craftingData
        if (reagents ~= nil and (type(reagents) ~= "table" or getmetatable(reagents) ~= nil))
            or (crafting ~= nil and type(crafting) == "table" and getmetatable(crafting) ~= nil) then return end
        observations[recipe.recipeID] = recipe
        out[index] = recipe
    end
    for id, removed in pairs(payload.removedRecipeIDs or {}) do
        if removed == true then
            if observations[id] ~= nil then return end
            observations[id] = false
        end
    end
    for _, recipe in ipairs(old) do
        if not PlainModernAliasRecipe(recipe) or not rawequal(observations[recipe.recipeID], recipe) then return end
    end
    for key, data in pairs(db.bySkillLine) do
        if type(data) ~= "table" or AliasNeedsSync(data, observations, true) then return end
        local cached = sessionCache[key]
        if cached ~= nil and cached ~= data and AliasNeedsSync(cached, observations, true) then return end
    end
    return out
end

local function StoreSkill(skillKey, payload, reuseNamedAlias)
    skillKey = tostring(skillKey)
    local db = EnsureDB()
    local previous = sessionCache[skillKey] or db.bySkillLine[skillKey]
    -- An owned scan can be indexed under an older expansion name as well as
    -- its current parent ID/name. Keep observations coherent across aliases;
    -- otherwise a stale alias can resurrect an unlearned recipe after reload.
    local function SyncOwnedAliases()
        if not payload.ownedRecipeScan then return end
        local observations, observedIDs = {}, {}
        for _, recipe in ipairs(payload.observedRecipes or {}) do observedIDs[recipe.recipeID] = true end
        for _, recipe in ipairs(payload.recipes or {}) do
            if observedIDs[recipe.recipeID] then observations[recipe.recipeID] = recipe end
        end
        for id, removed in pairs(payload.removedRecipeIDs or {}) do if removed == true then observations[id] = false end end
        local function SyncAlias(data)
            if type(data) ~= "table" then return end
            -- Another profession's alias cannot change without a shared recipe or tombstone.
            if not AliasNeedsSync(data, observations) then return end
            local recipes, touched, included = {}, false, {}
            local unlearned = {}
            for id, removed in pairs(data.unlearnedRecipeIDs or {}) do unlearned[id] = removed end
            for _, recipe in ipairs(data.recipes or {}) do
                local observed
                if not recipe.legacy then observed = observations[recipe.recipeID] end
                if observed ~= nil then
                    touched = true
                    if observed then recipes[#recipes + 1] = observed; included[recipe.recipeID] = true else unlearned[recipe.recipeID] = true end
                else recipes[#recipes + 1] = recipe end
            end
            for id, observed in pairs(observations) do
                if unlearned[id] ~= nil then
                    touched = true
                    if observed and not included[id] then recipes[#recipes + 1] = observed end
                    unlearned[id] = observed == false and true or nil
                end
            end
            if touched then data.recipes, data.unlearnedRecipeIDs = recipes, unlearned end
        end
        for key, data in pairs(db.bySkillLine or {}) do
            if key ~= skillKey then
                SyncAlias(data)
                if sessionCache[key] ~= data then SyncAlias(sessionCache[key]) end
            end
        end
    end
    local observed = #(payload.recipes or {})
    local recipes = reuseNamedAlias and ReuseNamedAliasRecipes(db, previous, payload)
    if recipes then
        payload.recipes = recipes
    else
        -- Filters and half-ready recipe lists are observations, not a replacement
        -- for the character's learned catalogue. Only an explicit unlearn removes it.
        local function Identity(recipe)
            return recipe.legacy and ("legacy:" .. tostring(recipe.name or recipe.outputItemID or recipe.recipeID))
                or ("recipe:" .. tostring(recipe.recipeID))
        end
        local seen = {}
        recipes = {}
        local old = {}
        for _, recipe in ipairs(previous and previous.recipes or {}) do old[Identity(recipe)] = recipe end
        local aliasPrior = {}
        if payload.ownedRecipeScan and Prof.ListAllCachedRecipes then
            -- Lua versions with separate integer/float text keys retain the text lookup.
            local observedIDs, numeric = {}, not math.type
            for _, recipe in ipairs(payload.recipes or {}) do
                if not recipe.legacy then
                    local id = recipe.recipeID
                    observedIDs[id] = true
                    if type(id) ~= "number" or id < 1 or id > 2147483647 or id % 1 ~= 0 then numeric = false end
                end
            end
            -- The saved alias winner can retain facts that a half-ready scan omits.
            -- Plain modern recipe IDs can be ranked directly into the merge lookup.
            local ownsCatalogue = Prof.ListAllCachedRecipes == OwnedListAllCachedRecipes
            aliasPrior = numeric and ownsCatalogue and RankObservedRecipes(db, observedIDs)
            if not aliasPrior then
                aliasPrior = {}
                local catalogue
                if ownsCatalogue then
                    local recipeKeys = {}
                    for id in pairs(observedIDs) do recipeKeys["recipe:" .. tostring(id)] = true end
                    catalogue = BuildCachedRecipeCatalogue(db, nil, nil, recipeKeys)
                else
                    catalogue = Prof.ListAllCachedRecipes()
                end
                for _, recipe in ipairs(catalogue) do
                    if not recipe.legacy and observedIDs[recipe.recipeID] then aliasPrior[recipe.recipeID] = recipe end
                end
            end
        end
        for _, recipe in ipairs(payload.recipes or {}) do
            local key = Identity(recipe)
            local prior = not recipe.legacy and aliasPrior[recipe.recipeID] or old[key]
            local needsMerge = false
            -- The first alias can already point at this exact record. In a plain
            -- record there are no missing fields or reagents to recover from itself.
            local sameRecord = prior and rawequal(prior, recipe) and getmetatable(recipe) == nil
            local reagents = sameRecord and rawget(recipe, "reagents")
            if prior and (not sameRecord or (reagents ~= nil
                and (type(reagents) ~= "table" or getmetatable(reagents) ~= nil))) then
                for field, value in pairs(prior) do
                    if recipe[field] == nil or field == "reagents" and #recipe[field] == 0 and value and #value > 0 then
                        needsMerge = true; break
                    end
                end
            end
            if needsMerge then
                local merged = {}; for field, value in pairs(prior) do merged[field] = value end
                for field, value in pairs(recipe) do
                    if field ~= "reagents" or #value > 0 or not prior.reagents or #prior.reagents == 0 then merged[field] = value end
                end
                recipe = merged
            end
            recipes[#recipes + 1], seen[key] = recipe, true
        end
        for key, recipe in pairs(old) do
            if not seen[key] and not (payload.removedRecipeIDs and payload.removedRecipeIDs[recipe.recipeID]) then
                recipes[#recipes + 1] = recipe
            end
        end
        payload.recipes = recipes
        SyncOwnedAliases()
    end
    local unlearned = {}
    for id, removed in pairs(previous and previous.unlearnedRecipeIDs or {}) do if removed == true then unlearned[id] = true end end
    for id, removed in pairs(payload.removedRecipeIDs or {}) do if removed == true then unlearned[id] = true end end
    for _, recipe in ipairs(recipes) do
        if not recipe.legacy and recipe.learned == true and recipe.recipeID ~= nil then unlearned[recipe.recipeID] = nil end
    end
    payload.unlearnedRecipeIDs = unlearned
    if observed == 0 and #recipes > 0 then
        payload.needsOpen = true
        payload.scannedAt = previous and previous.scannedAt or payload.scannedAt
    end
    sessionCache[skillKey] = payload
    db.bySkillLine[skillKey] = {
        recipes = payload.recipes,
        scannedAt = payload.scannedAt,
        source = payload.source,
        name = payload.name,
        needsOpen = payload.needsOpen,
        unlearnedRecipeIDs = unlearned,
    }
    local Craft = Inv.Craft
    if Craft and Craft.InvalidateCanCraftCache then
        Craft.InvalidateCanCraftCache()
    end
end

local function LoadSkill(skillKey)
    skillKey = tostring(skillKey)
    if sessionCache[skillKey] then
        return sessionCache[skillKey]
    end
    local db = EnsureDB()
    local stored = db.bySkillLine[skillKey]
    if stored then
        sessionCache[skillKey] = stored
        return stored
    end
    return nil
end

-- A previous removal needs no new observation if both primary aliases
-- already retain it and no alias has a row or a flag that it could change.
local function RetainableRecipeRemovals(previous, named, list)
    if type(previous) ~= "table" or getmetatable(previous) or previous.source ~= "open" or previous.needsOpen
        or type(named) ~= "table" or getmetatable(named) or named.source ~= "open" or named.needsOpen then return end
    local byID, byName = previous.unlearnedRecipeIDs, named.unlearnedRecipeIDs
    if type(byID) ~= "table" or getmetatable(byID) or type(byName) ~= "table" or getmetatable(byName) then return end
    local candidates = {}
    for id, removed in pairs(byID) do
        if removed == true and byName[id] == true and list.ids[id] and not list.visible[id] then
            candidates[id] = true
        end
    end
    if not next(candidates) then return end

    local function ExcludeConflicts(data)
        if type(data) ~= "table" or getmetatable(data) then return false end
        local recipes, removed = data.recipes, data.unlearnedRecipeIDs
        if (recipes ~= nil and (type(recipes) ~= "table" or getmetatable(recipes)))
            or (removed ~= nil and (type(removed) ~= "table" or getmetatable(removed))) then return false end
        for _, recipe in ipairs(recipes or {}) do
            if type(recipe) ~= "table" or getmetatable(recipe) then return false end
            local id = recipe.recipeID
            if issecretvalue and issecretvalue(id) then return false end
            if candidates[id] then candidates[id] = nil end
        end
        for id, value in pairs(removed or {}) do
            if value ~= true or not recipes then candidates[id] = nil end
        end
        return true
    end

    local db = EnsureDB().bySkillLine
    if type(db) ~= "table" or getmetatable(db) or not ExcludeConflicts(previous) or not ExcludeConflicts(named) then return end
    for key, data in pairs(db) do
        local cached = sessionCache[key]
        if not ExcludeConflicts(data) or (cached and cached ~= data and cached ~= previous
            and cached ~= named and not ExcludeConflicts(cached)) then return end
    end
    return next(candidates) and candidates or nil
end

local function Now()
    return GetTime and GetTime() or 0
end

-- ---------------------------------------------------------------------------
-- Recipe extraction helpers
-- ---------------------------------------------------------------------------

local function CollectModernReagentRows(schematic, basicOnly)
    local out = {}
    for _, slot in ipairs(schematic.reagentSlotSchematics) do
        local isBasic = true
        if Enum and Enum.CraftingReagentType and slot.reagentType then
            isBasic = (slot.reagentType == Enum.CraftingReagentType.Basic)
        end
        if (not basicOnly or isBasic)
            and slot.reagents and slot.reagents[1] and slot.reagents[1].itemID and slot.quantityRequired then
            out[#out + 1] = {
                itemID = slot.reagents[1].itemID,
                count = slot.quantityRequired,
            }
        end
    end
    return out
end

local function ExtractModernReagents(recipeID, knownSchematic)
    if not (C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic) then
        return {}
    end
    local ok, schematic = true, knownSchematic
    if not schematic then ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false) end
    if not ok or type(schematic) ~= "table" or not schematic.reagentSlotSchematics then
        return {}
    end
    local reagents = CollectModernReagentRows(schematic, true)
    if #reagents == 0 then
        reagents = CollectModernReagentRows(schematic, false)
    end
    return reagents
end

local function ExtractModernOutput(recipeID)
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeOutputItemData then
        local ok, data = pcall(C_TradeSkillUI.GetRecipeOutputItemData, recipeID)
        if ok and type(data) == "table" and data.itemID then
            return data.itemID, data.hyperlink
        end
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
        local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if ok and type(info) == "table" then
            if info.hyperlink and type(info.hyperlink) == "string" then
                local id = tonumber(info.hyperlink:match("item:(%d+)"))
                if id then
                    return id, info.hyperlink
                end
            end
            if info.qualityItemIDs and type(info.qualityItemIDs) == "table" and info.qualityItemIDs[1] then
                return info.qualityItemIDs[1], nil
            end
        end
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic then
        local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
        if ok and type(schematic) == "table" and schematic.outputItemID then
            return schematic.outputItemID, nil
        end
    end
    return nil, nil
end

--- Items produced per craft (e.g. Mana Potion Injector = 20). Defaults to 1.
local function ExtractModernQuantity(recipeID, knownSchematic)
    local qtyMin, qtyMax
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic then
        local ok, schematic = true, knownSchematic
        if not schematic then ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false) end
        if ok and type(schematic) == "table" then
            local amin = tonumber(schematic.quantityMin)
            local amax = tonumber(schematic.quantityMax)
            if amin and amin > 0 then
                qtyMin = amin
            end
            if amax and amax > 0 then
                qtyMax = amax
            elseif amin and amin > 0 then
                qtyMax = amin
            end
            return qtyMin, qtyMax, schematic
        end
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
        local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if ok and type(info) == "table" then
            local amin = tonumber(info.quantityMin) or tonumber(info.numItems)
            local amax = tonumber(info.quantityMax) or amin
            if amin and amin > 0 then
                qtyMin = amin
            end
            if amax and amax > 0 then
                qtyMax = amax
            end
        end
    end
    return qtyMin, qtyMax
end

-- Save plain recipe facts, never native tables, allocations, prices or bag counts.
-- Quality operations remain live checks because equipment/skill can change them.
local function ExtractModernRecipeData(recipeID, info, schematic)
    if type(schematic) ~= "table" or type(schematic.reagentSlotSchematics) ~= "table"
        or not tonumber(schematic.quantityMin) or schematic.quantityMin <= 0 then
        return ExtractModernReagents(recipeID, schematic)
    end
    local reagents = {}
    local reagentTypes = Enum and Enum.CraftingReagentType
    local basicType = reagentTypes and reagentTypes.Basic
    local copy = { quantityMin = schematic.quantityMin, quantityMax = schematic.quantityMax,
        outputItemID = schematic.outputItemID, hasCraftingOperationInfo = schematic.hasCraftingOperationInfo == true,
        reagentSlotSchematics = {} }
    for index, slot in ipairs(schematic.reagentSlotSchematics) do
        local options, count, kind = slot.reagents, slot.quantityRequired, slot.reagentType
        local first = options and options[1]
        if first and first.itemID and count and (not reagentTypes or not kind or kind == basicType) then
            reagents[#reagents + 1] = { itemID = first.itemID, count = count }
        end
        local saved = { required = slot.required == true, reagentType = kind,
            quantityRequired = count, dataSlotIndex = slot.dataSlotIndex, reagents = {} }
        for _, reagent in ipairs(options or {}) do
            if tonumber(reagent.itemID) then saved.reagents[#saved.reagents + 1] = { itemID = reagent.itemID } end
        end
        if (saved.required or (tonumber(count) or 0) > 0)
            and (#saved.reagents == 0 or not tonumber(saved.dataSlotIndex)) then
            return ExtractModernReagents(recipeID, schematic), { version = 1, complete = false }
        end
        copy.reagentSlotSchematics[index] = saved
    end
    if #reagents == 0 then reagents = CollectModernReagentRows(schematic, false) end
    local qualities = {}
    if C_TradeSkillUI.GetRecipeQualityItemIDs then
        local ok, ids = pcall(C_TradeSkillUI.GetRecipeQualityItemIDs, recipeID)
        if ok and type(ids) == "table" then
            for _, id in ipairs(ids) do if tonumber(id) then qualities[#qualities + 1] = id end end
        end
    end
    return reagents, { version = 1, complete = true, schematic = copy, qualityItemIDs = qualities,
        supportsQualities = info.supportsQualities == true or #qualities > 1 }
end

local function PulseProfessionsChanged()
    -- Recipe load/change must drop craft best cache even when bag gen is unchanged.
    local Craft = Inv.Craft
    if Craft and Craft.InvalidateCanCraftCache then
        Craft.InvalidateCanCraftCache()
    end
    if Inv.Notify then
        Inv.Notify({ professions = true })
    end
end

local function ScanModernOpenProfession(source, allowSettledList, allowSavedRemovals)
    if not HasModernRecipeList() then
        return nil
    end
    if TradeSkillDataNotReady() then
        return nil
    end
    local recipeIDs, allIDs, filtered = ListOpenRecipeIDs()
    if type(recipeIDs) ~= "table" or #recipeIDs == 0 then
        return nil
    end
    local skillLineID, skillName
    local info = Prof.GetOpenProfessionInfo()
    if type(info) == "table" then
        -- OpenTradeSkill wants the parent skill line when child expansion lines exist.
        skillLineID = info.parentProfessionID or info.professionID or info.skillLineID
        skillName = info.parentProfessionName or info.professionName or info.displayName
    end
    if not skillLineID and GetTradeSkillLine then
        skillName = select(1, GetTradeSkillLine())
        skillLineID = skillName
    end
    skillLineID = skillLineID or skillName or "current"
    local frame = ProfessionsFrame or TradeSkillFrame
    local resolvedOpen = type(info) == "table" and tonumber(info.parentProfessionID or info.professionID or info.skillLineID)
    local ownOpen = frame and frame.IsShown and frame:IsShown() == true and resolvedOpen and resolvedOpen > 0
        and skillLineID ~= "current" and skillName and Prof.GetProfessionKnowledge
        and Prof.GetProfessionKnowledge({ skillName }) == true
    local list = source == "open" and ownOpen and ObserveLearnedRecipeList(info, recipeIDs, allIDs, filtered)
    local reuse = allowSettledList and SameLearnedRecipeList(list, settledRecipeList)
    local retainedBefore = reuse and settledRecipeList.retainedRemovals
    local verified = list and true or false
    local prevByRecipeID = {}
    local prevData = LoadSkill(skillLineID)
    local savedRemovals
    if list and (allowSavedRemovals or retainedBefore) and tostring(skillName) ~= tostring(skillLineID)
        and Prof.ListAllCachedRecipes == OwnedListAllCachedRecipes then
        savedRemovals = RetainableRecipeRemovals(prevData, LoadSkill(skillName), list)
    end
    if prevData and prevData.recipes then
        for _, prev in ipairs(prevData.recipes) do
            if prev and prev.recipeID then
                prevByRecipeID[prev.recipeID] = prev
            end
        end
    end
    local recipes, removedRecipeIDs = {}, {}
    for _, recipeID in ipairs(recipeIDs) do
        -- A complete scan already established these removals. The unchanged
        -- learned list and a fresh spellbook negative both have to agree.
        local retain = savedRemovals and savedRemovals[recipeID]
        local confirmed = (retain or reuse and not (retainedBefore and retainedBefore[recipeID]))
            and not list.visible[recipeID] and ConfirmStillUnlearned(recipeID)
        local okInfo, info
        if not confirmed then okInfo, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID) end
        if confirmed then
            if retain then
                -- Keep the saved removal, without presenting it as a fresh
                -- observation. Recheck alias safety on subsequent events.
                list.retainedRemovals = list.retainedRemovals or {}
                list.retainedRemovals[recipeID] = true
            else
                removedRecipeIDs[recipeID] = true
            end
        elseif okInfo and type(info) == "table"
            and not info.isDummyRecipe
            and not info.isGatheringRecipe
            and not info.isEnchantingRecipe
            and not info.isSalvageRecipe then
            -- Persist known recipes only (matches "character know").
            local learned = info.learned == true
            if list and info.learned ~= (list.visible[recipeID] == true) then verified = false end
            if info.learned == false and ownOpen then removedRecipeIDs[recipeID] = true end
            if learned then
                local schematic
                if C_TradeSkillUI.GetRecipeSchematic then
                    local ok, data = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
                    if ok then schematic = data end
                end
                local outputItemID, link = ExtractModernOutput(recipeID)
                local qtyMin, qtyMax = ExtractModernQuantity(recipeID, schematic)
                local reagents, craftingData = ExtractModernRecipeData(recipeID, info, schematic)
                -- Half-ready opens can return empty reagents; keep prior known mats.
                if #reagents == 0 then
                    local prev = prevByRecipeID[recipeID]
                    if prev and type(prev.reagents) == "table" and #prev.reagents > 0 then
                        reagents = prev.reagents
                    end
                end
                recipes[#recipes + 1] = {
                    recipeID = recipeID,
                    name = info.name,
                    learned = true,
                    craftable = info.craftable and true or false,
                    outputItemID = outputItemID or (prevByRecipeID[recipeID] and prevByRecipeID[recipeID].outputItemID),
                    outputLink = link or (prevByRecipeID[recipeID] and prevByRecipeID[recipeID].outputLink),
                    quantityMin = qtyMin,
                    quantityMax = qtyMax,
                    reagents = reagents,
                    craftingData = craftingData,
                    legacy = false,
                    skillLineID = skillLineID,
                    skillName = skillName,
                }
            end
        else
            verified = false
        end
    end
    if list and list.revision ~= recipeListRevision then verified = false end
    if (reuse or list and list.retainedRemovals) and not verified then
        -- Read the entire list before publishing when either native view disagrees.
        ForgetSettledRecipeList()
        return ScanModernOpenProfession(source, false)
    end
    local payload = {
        recipes = recipes,
        scannedAt = Now(),
        source = source or "open",
        name = skillName,
        needsOpen = false,
        removedRecipeIDs = removedRecipeIDs,
        ownedRecipeScan = ownOpen == true,
        observedRecipes = ownOpen and recipes or nil,
    }
    StoreSkill(skillLineID, payload)
    -- Also index by profession name for Classic-style lookups.
    if skillName and tostring(skillName) ~= tostring(skillLineID) then
        StoreSkill(skillName, payload, true)
    end
    settledRecipeList = verified and list and list.revision == recipeListRevision and list or nil
    openSkillKey = tostring(skillLineID)
    if source == "open" then
        PulseProfessionsChanged()
    end
    return payload
end

local function ExtractLegacyReagents(skillIndex)
    local reagents = {}
    if not GetTradeSkillNumReagents or not GetTradeSkillReagentInfo then
        return reagents
    end
    local n = GetTradeSkillNumReagents(skillIndex) or 0
    for i = 1, n do
        local name, _, reagentCount, playerCount = GetTradeSkillReagentInfo(skillIndex, i)
        local itemID
        if GetTradeSkillReagentItemLink then
            local link = GetTradeSkillReagentItemLink(skillIndex, i)
            if link then
                itemID = tonumber(link:match("item:(%d+)"))
            end
        end
        reagents[#reagents + 1] = {
            itemID = itemID,
            name = name,
            count = reagentCount or 1,
            playerCount = playerCount,
        }
    end
    return reagents
end

local function ScanLegacyOpenProfession(source)
    if not (GetNumTradeSkills and GetTradeSkillInfo) then
        return nil
    end
    local skillName = GetTradeSkillLine and select(1, GetTradeSkillLine()) or "legacy"
    if not skillName or skillName == "" or skillName == "UNKNOWN" then
        return nil
    end
    local recipes = {}
    local num = GetNumTradeSkills() or 0
    for i = 1, num do
        local name, skillType = GetTradeSkillInfo(i)
        if name and skillType and skillType ~= "header" and skillType ~= "subheader" then
            local itemLink = GetTradeSkillItemLink and GetTradeSkillItemLink(i)
            local itemID = itemLink and tonumber(itemLink:match("item:(%d+)")) or nil
            local qtyMin, qtyMax = 1, 1
            if GetTradeSkillNumMade then
                qtyMin, qtyMax = GetTradeSkillNumMade(i)
            end
            recipes[#recipes + 1] = {
                recipeID = i,
                name = name,
                learned = true,
                craftable = true,
                outputItemID = itemID,
                outputLink = itemLink,
                quantityMin = qtyMin,
                quantityMax = qtyMax,
                reagents = ExtractLegacyReagents(i),
                legacy = true,
                skillName = skillName,
            }
        end
    end
    local payload = {
        recipes = recipes,
        scannedAt = Now(),
        source = source or "open",
        name = skillName,
        needsOpen = false,
    }
    StoreSkill(skillName, payload)
    openSkillKey = skillName
    if source == "open" then
        PulseProfessionsChanged()
    end
    return payload
end

-- Reuse the worker without moving live backend queries outside pcall.
local function ScanOpenProfessionProtected(source, allowSettledList, allowSavedRemovals)
    if HAS_MODERN_PROF and HasModernRecipeList() then
        local modern = ScanModernOpenProfession(source, allowSettledList, allowSavedRemovals)
        if modern then
            return modern
        end
    end
    ForgetSettledRecipeList()
    return ScanLegacyOpenProfession(source)
end

local function ScanOpenProfession(source, allowSettledList, allowSavedRemovals)
    if scanBusy then
        return nil
    end
    if IsForeignProfession() then return nil end
    scanBusy = true
    local ok, payload = pcall(ScanOpenProfessionProtected, source, allowSettledList, allowSavedRemovals)
    scanBusy = false
    if ok then
        return payload
    end
    ForgetSettledRecipeList()
    return nil
end

-- ---------------------------------------------------------------------------
-- Tier C — live lookups
-- ---------------------------------------------------------------------------

function Prof.GetRecipeLive(recipeID)
    if IsForeignProfession() then return nil, "none" end
    recipeID = tonumber(recipeID) or recipeID
    if not recipeID then
        return nil, "none"
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
        local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if ok and type(info) == "table" then
            if info.learned == nil then return nil, "none" end
            local outputItemID = ExtractModernOutput(recipeID)
            local qtyMin, qtyMax, schematic = ExtractModernQuantity(recipeID)
            return {
                recipeID = recipeID,
                name = info.name,
                learned = info.learned and true or false,
                craftable = info.craftable and true or false,
                outputItemID = outputItemID,
                quantityMin = qtyMin,
                quantityMax = qtyMax,
                reagents = ExtractModernReagents(recipeID, schematic),
                legacy = false,
                source = "live",
            }, "live"
        end
    end
    return nil, "none"
end

function Prof.GetCompleteness(skillKey)
    skillKey = skillKey and tostring(skillKey) or openSkillKey
    if not skillKey then
        return "none"
    end
    -- Live: if this skill is currently open and modern APIs return recipes
    if openSkillKey and tostring(openSkillKey) == skillKey then
        local ids = ListOpenRecipeIDs()
        if type(ids) == "table" and #ids > 0 then
            return "live"
        end
        if GetNumTradeSkills and (GetNumTradeSkills() or 0) > 0 then
            return "live"
        end
    end
    local data = LoadSkill(skillKey)
    if not data or not data.recipes then
        return "none"
    end
    if data.needsOpen then
        return "partial"
    end
    if data.source == "open" then
        return "cached"
    end
    if data.source == "login" then
        return "cached"
    end
    if data.source == "live" then
        return "live"
    end
    return #data.recipes > 0 and "cached" or "none"
end

-- ---------------------------------------------------------------------------
-- Public query API (Tier C then cache)
-- ---------------------------------------------------------------------------

function Prof.GetRecipe(recipeID, skillKey)
    local live, completeness = Prof.GetRecipeLive(recipeID)
    if live and (live.learned == false or (live.outputItemID and live.quantityMin and #live.reagents > 0)) then
        return live, completeness
    end
    skillKey = skillKey and tostring(skillKey) or openSkillKey
    if skillKey then
        local data = LoadSkill(skillKey)
        if data and data.recipes then
            for _, r in ipairs(data.recipes) do
                if r.recipeID == recipeID then
                    return r, Prof.GetCompleteness(skillKey)
                end
            end
        end
    end
    -- Search all cached skills
    local db = EnsureDB()
    for key, data in pairs(db.bySkillLine) do
        if data.recipes then
            for _, r in ipairs(data.recipes) do
                if r.recipeID == recipeID then
                    return r, Prof.GetCompleteness(key)
                end
            end
        end
    end
    return live, live and "partial" or "none"
end

function Prof.GetReagents(recipeID, skillKey)
    local recipe = Prof.GetRecipe(recipeID, skillKey)
    return recipe and recipe.reagents or nil
end

function Prof.GetOutput(recipeID, skillKey)
    local recipe = Prof.GetRecipe(recipeID, skillKey)
    if not recipe then
        return nil
    end
    return recipe.outputItemID, recipe.outputLink
end

function Prof.IsLearned(recipeID, skillKey)
    local recipe = Prof.GetRecipe(recipeID, skillKey)
    if recipe then
        return recipe.learned == true
    end
    if C_TradeSkillUI and C_TradeSkillUI.IsRecipeProfessionLearned then
        local ok, learned = pcall(C_TradeSkillUI.IsRecipeProfessionLearned, recipeID)
        if ok then
            return learned and true or false
        end
    end
    return false
end

function Prof.ListCachedRecipes(skillKey)
    skillKey = skillKey and tostring(skillKey) or openSkillKey
    if not skillKey then
        return {}, "none"
    end
    local data = LoadSkill(skillKey)
    if not data or not data.recipes then
        return {}, Prof.GetCompleteness(skillKey)
    end
    return data.recipes, Prof.GetCompleteness(skillKey)
end

function Prof.ListSkillKeys()
    local db = EnsureDB()
    local keys = {}
    for key in pairs(db.bySkillLine) do
        keys[#keys + 1] = key
    end
    return keys
end

function Prof.GetSkillInfo(skillKey)
    skillKey = tostring(skillKey)
    return LoadSkill(skillKey)
end

-- ---------------------------------------------------------------------------
-- Tier A — profession UI open (authoritative)
-- ---------------------------------------------------------------------------

function Prof.OnProfessionEvent(event, arg1, arg2)
    local listUpdate = event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_UPDATE"
    if not listUpdate or scanBusy then ForgetSettledRecipeList() end
    if TradeSkillDataNotReady() then
        ForgetSettledRecipeList()
        return
    end
    if event == "NEW_RECIPE_LEARNED" then
        -- Rescan if profession is open; else mark needs refresh
        if TradeSkillFrame and TradeSkillFrame:IsShown()
            or (ProfessionsFrame and ProfessionsFrame:IsShown()) then
            ScanOpenProfession("open")
        elseif openSkillKey then
            local data = LoadSkill(openSkillKey)
            if data then
                data.needsOpen = true
                StoreSkill(openSkillKey, data)
            end
            PulseProfessionsChanged()
        end
        if Inv.Craft and Inv.Craft.TryFlushPendingCraft then
            Inv.Craft.TryFlushPendingCraft()
        end
        return
    end
    ScanOpenProfession("open", listUpdate, event == "TRADE_SKILL_DATA_SOURCE_CHANGED")
    if Inv.Craft and Inv.Craft.TryFlushPendingCraft then
        Inv.Craft.TryFlushPendingCraft()
    end
end

local catalogueToString = tostring

local function RecipeCatalogueRank(recipe, key, data, textKey)
    local crafting = recipe.craftingData
    local complete = type(crafting) == "table" and crafting.version == 1 and crafting.complete == true
    local flat = recipe.outputItemID and (tonumber(recipe.quantityMin) or 0) > 0
        and type(recipe.reagents) == "table" and #recipe.reagents > 0
    local canonical = recipe.skillLineID and tostring(recipe.skillLineID)
        == (textKey and tostring == catalogueToString and textKey or tostring(key))
        or recipe.legacy and recipe.skillName == key
    return (complete and 16 or 0) + (flat and 8 or 0) + (canonical and 4 or 0)
        + (data.source == "open" and 2 or 0) + (recipe.learned == true and 1 or 0)
end

--- All cached recipes across every skill line for this character.
BuildCachedRecipeCatalogue = function(db, recipeKey, floatKey, recipeKeys)
    local out = {}
    local seen, revoked = {}, {}
    local ranks, keys
    -- Full scans can use numeric keys without allocating a string for every
    -- modern recipe. Targeted lookups still compare their original text keys.
    local numericKeys = recipeKey == nil and recipeKeys == nil and tostring == catalogueToString
        and (not issecurevariable or issecurevariable(_G, "tostring"))
    local numberType = math.type
    for _, data in pairs(db and db.bySkillLine or {}) do
        for id, removed in pairs(data.unlearnedRecipeIDs or {}) do if removed == true then revoked[id] = true end end
    end
    for key, data in pairs(db and db.bySkillLine or {}) do
        -- Saved skill aliases are normally already text. Keep conversion when
        -- a provider replaces tostring, including during a recipe field read.
        local textKey = numericKeys and type(key) == "string"
            and (not issecretvalue or not issecretvalue(key)) and key
        if data and data.recipes then
            for _, r in ipairs(data.recipes) do
                local id = r.recipeID
                local legacy = r.legacy
                local uniq
                if numericKeys and not legacy and type(id) == "number"
                    and (not issecretvalue or not issecretvalue(id)) and tostring == catalogueToString
                    and id >= 1 and id <= 2147483647 and id % 1 == 0
                    and (not numberType or numberType(id) == "integer") then
                    uniq = id
                else
                    uniq = legacy and (tostring(r.skillName or key) .. ":" .. tostring(r.name or r.outputItemID or id))
                        or ("recipe:" .. tostring(id))
                    -- Older saves can mix numeric and textual IDs. A legacy
                    -- record can also spell the same key. Keep those collisions.
                    if numericKeys and (not issecretvalue or not issecretvalue(uniq)) and uniq:sub(1, 7) == "recipe:" then
                        local digits = uniq:sub(8)
                        local number = tonumber(digits)
                        if number and number >= 1 and number <= 2147483647 and number % 1 == 0
                            and (not numberType or numberType(number) == "integer")
                            and catalogueToString(number) == digits then
                            uniq = number
                        end
                    end
                end
                if (not recipeKeys or recipeKeys[uniq])
                    and (recipeKey == nil or uniq == recipeKey or uniq == floatKey)
                    and (r.legacy or not revoked[id]) then
                    local rank = RecipeCatalogueRank(r, key, data, textKey)
                    local old = seen[uniq]
                    if not old then
                        out[#out + 1] = r
                        local index = #out
                        if not ranks then ranks, keys = {}, {} end
                        ranks[index], keys[index] = rank,
                            (textKey and tostring == catalogueToString and textKey or tostring(key))
                        seen[uniq] = index
                    elseif rank > ranks[old] or rank == ranks[old]
                        and (textKey and tostring == catalogueToString and textKey or tostring(key)) < keys[old] then
                        out[old] = r
                        ranks[old], keys[old] = rank,
                            (textKey and tostring == catalogueToString and textKey or tostring(key))
                    end
                end
            end
        end
    end
    return out
end

RankObservedRecipes = function(db, observedIDs)
    local prior, ranks, aliases, revoked = {}, {}, {}, {}
    for _, data in pairs(db.bySkillLine or {}) do
        for id, removed in pairs(data.unlearnedRecipeIDs or {}) do
            if observedIDs[id] and removed == true then revoked[id] = true end
        end
    end
    for key, data in pairs(db.bySkillLine or {}) do
        local alias = tostring(key)
        for _, recipe in ipairs(data.recipes or {}) do
            local id = recipe.recipeID
            if recipe.legacy or type(id) ~= "number" or id < 1 or id > 2147483647 or id % 1 ~= 0 then return nil end
            if observedIDs[id] and not revoked[id] then
                local rank = RecipeCatalogueRank(recipe, key, data)
                local old = ranks[id]
                if not old or rank > old or rank == old and alias < aliases[id] then
                    prior[id], ranks[id], aliases[id] = recipe, rank, alias
                end
            end
        end
    end
    return prior
end

function Prof.ListAllCachedRecipes(characterKey)
    local db = characterKey and FluxInvDB.professions and FluxInvDB.professions[characterKey] or (not characterKey and EnsureDB())
    return BuildCachedRecipeCatalogue(db)
end

OwnedListAllCachedRecipes = Prof.ListAllCachedRecipes

local function RecipeProduces(recipe, itemID)
    local matches = recipe.outputItemID == itemID
    for _, id in ipairs(recipe.craftingData and recipe.craftingData.qualityItemIDs or {}) do
        if id == itemID then matches = true end
    end
    return matches
end

local function FilterRecipesForOutput(recipes, itemID)
    local out = {}
    for _, recipe in ipairs(recipes) do
        local matches = recipe.outputItemID == itemID
        for _, id in ipairs(recipe.craftingData and recipe.craftingData.qualityItemIDs or {}) do
            if id == itemID then matches = true end
        end
        if matches and recipe.learned == true then out[#out + 1] = recipe end
    end
    return out
end

--- Shared per-character catalogue query for AH and future recipe consumers.
function Prof.ListRecipesForOutput(itemID, characterKey)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then return {} end
    if not HAS_MODERN_PROF or Prof.ListAllCachedRecipes ~= OwnedListAllCachedRecipes then
        return FilterRecipesForOutput(Prof.ListAllCachedRecipes(characterKey), itemID)
    end
    local db = characterKey and FluxInvDB.professions and FluxInvDB.professions[characterKey] or (not characterKey and EnsureDB())
    local candidates, revoked = {}, {}
    for _, data in pairs(db and db.bySkillLine or {}) do
        for id, removed in pairs(data.unlearnedRecipeIDs or {}) do if removed == true then revoked[id] = true end end
    end
    for _, data in pairs(db and db.bySkillLine or {}) do
        for _, recipe in ipairs(data.recipes or {}) do
            -- Legacy names and unknown identities retain the complete catalogue
            -- path. Modern IDs let unrelated recipes avoid alias rank records.
            if recipe.legacy or type(recipe.recipeID) ~= "number" or recipe.recipeID <= 0 or recipe.recipeID % 1 ~= 0 then
                return FilterRecipesForOutput(BuildCachedRecipeCatalogue(db), itemID)
            end
            if not revoked[recipe.recipeID] and RecipeProduces(recipe, itemID) then candidates[recipe.recipeID] = true end
        end
    end
    local order, seen = {}, {}
    for key, data in pairs(db and db.bySkillLine or {}) do
        for _, recipe in ipairs(data.recipes or {}) do
            local id = recipe.recipeID
            if candidates[id] and not revoked[id] then
                local uniq = "recipe:" .. tostring(id)
                local rank = RecipeCatalogueRank(recipe, key, data)
                local old = seen[uniq]
                if not old then
                    order[#order + 1] = uniq
                    seen[uniq] = { recipe = recipe, rank = rank, key = tostring(key) }
                elseif rank > old.rank or rank == old.rank and tostring(key) < old.key then
                    old.recipe, old.rank, old.key = recipe, rank, tostring(key)
                end
            end
        end
    end
    local out = {}
    for _, uniq in ipairs(order) do
        local recipe = seen[uniq].recipe
        if RecipeProduces(recipe, itemID) and recipe.learned == true then out[#out + 1] = recipe end
    end
    return out
end

local OwnedListRecipesForOutput = Prof.ListRecipesForOutput

-- A single owned snapshot is enough for the auction comparison of several
-- distinct items. Resolve aliases before grouping so a lower-ranked saved
-- recipe cannot add an output that the canonical recipe no longer produces.
function ns.ListOwnedRecipesByOutput(outputIDs)
    if Inv.Professions ~= Prof or getmetatable(Prof) ~= nil
        or Prof.ListAllCachedRecipes ~= OwnedListAllCachedRecipes
        or Prof.ListRecipesForOutput ~= OwnedListRecipesForOutput then
        return nil
    end

    local grouped = {}
    for itemID in pairs(outputIDs) do grouped[itemID] = {} end
    for _, recipe in ipairs(OwnedListAllCachedRecipes()) do
        if recipe.learned == true then
            local items = grouped[recipe.outputItemID]
            if items then items[#items + 1] = recipe end

            local groupedQualities
            for _, qualityID in ipairs(recipe.craftingData and recipe.craftingData.qualityItemIDs or {}) do
                local qualityItems = grouped[qualityID]
                if qualityItems and qualityID ~= recipe.outputItemID
                    and (not groupedQualities or not groupedQualities[qualityID]) then
                    if not groupedQualities then groupedQualities = {} end
                    groupedQualities[qualityID] = true
                    qualityItems[#qualityItems + 1] = recipe
                end
            end
        end
    end
    return grouped
end

function Prof.OnProfessionClosed()
    ForgetSettledRecipeList()
    openSkillKey = nil
end

function Prof.OnEventPulse()
    -- no-op; scan happens in OnProfessionEvent
end

-- ---------------------------------------------------------------------------
-- Tier B — paced login scan
-- ---------------------------------------------------------------------------

local function SkillNameMatches(name, needles)
    if type(name) ~= "string" or name == "" or type(needles) ~= "table" then
        return false
    end
    local n = name:lower()
    for i = 1, #needles do
        local needle = needles[i]
        if type(needle) == "string" and needle ~= "" then
            needle = needle:lower()
            if n:find(needle, 1, true) then
                return true
            end
        end
    end
    return false
end

-- Rank lookup includes skill-pane lines (Comprehension, weapons, etc.) that
-- GetProfessions never returns. Login recipe scans still use the profession
-- book only — do not open those extra lines with OpenTradeSkill.
local rankLinesCache = nil
local itemReqCache = {} -- [itemID] = false | { skillName, required, color }

local COLOR_WHITE = CreateColor and CreateColor(1, 1, 1)

local function ColorLooksWhite(c)
    if not c then
        return false
    end
    if COLOR_WHITE and c.IsRGBEqualTo then
        return c:IsRGBEqualTo(COLOR_WHITE) and true or false
    end
    local r, g, b = c.r, c.g, c.b
    if type(c.GetRGB) == "function" then
        r, g, b = c:GetRGB()
    end
    return (tonumber(r) or 0) > 0.9 and (tonumber(g) or 0) > 0.9 and (tonumber(b) or 0) > 0.9
end

local function ColorLooksRed(c)
    if not c then
        return false
    end
    local r, g, b = c.r, c.g, c.b
    if type(c.GetRGB) == "function" then
        r, g, b = c:GetRGB()
    end
    r, g, b = tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0
    return r > 0.9 and g < 0.35 and b < 0.35
end

local function ParseSkillRequirementFromText(text)
    if type(text) ~= "string" or text == "" then
        return nil, nil
    end
    local lower = text:lower()
    for skillName, req in lower:gmatch("requires%s*:?%s*([%a][%a%s%-%']-)%s*%(?%s*(%d+)%s*%)?") do
        skillName = skillName:gsub("^%s+", ""):gsub("%s+$", "")
        if skillName ~= "" and skillName ~= "level" and not skillName:find("level", 1, true) then
            return skillName, tonumber(req)
        end
    end
    -- "Requires Comprehension" with no number yet, or "Comprehension (75)" alone.
    local skillOnly, reqOnly = lower:match("([%a][%a%s%-%']-)%s*%(%s*(%d+)%s*%)")
    if skillOnly then
        skillOnly = skillOnly:gsub("^%s+", ""):gsub("%s+$", "")
        if skillOnly ~= "" and skillOnly ~= "level" and not skillOnly:find("level", 1, true) then
            return skillOnly, tonumber(reqOnly)
        end
    end
    local named = lower:match("requires%s*:?%s*([%a][%a%s%-%']+)")
    if named then
        named = named:gsub("^%s+", ""):gsub("%s+$", "")
        if named ~= "" and named ~= "level" and not named:find("level", 1, true) then
            return named, 1
        end
    end
    return nil, nil
end

function Prof.InvalidateSkillCaches()
    rankLinesCache = nil
    wipe(itemReqCache)
end

--- Forever C_SkillInfo returns a SkillLineAttributes table. Classic GetSkillLineInfo
--- still returns name, isHeader, _, rank. Accept both so Comprehension is visible.
local function SkillLineNameAndRank(index)
    if C_SkillInfo and C_SkillInfo.GetSkillLineInfo then
        local ok, info = pcall(C_SkillInfo.GetSkillLineInfo, index)
        if ok and type(info) == "table" then
            local name = info.name
            local rank = tonumber(info.rank) or tonumber(info.currentRank) or tonumber(info.skillRank) or 0
            if type(name) == "string" and name ~= "" then
                if info.isHeader and rank <= 0 then
                    return
                end
                return name, rank, tonumber(info.skillID)
            end
            return
        end
    end
    if not GetSkillLineInfo then
        return
    end
    local a, b, _, d = GetSkillLineInfo(index)
    if type(a) == "table" then
        if a.isHeader then
            return
        end
        local name = a.name
        if type(name) == "string" and name ~= "" then
            return name, tonumber(a.rank) or 0, tonumber(a.skillID)
        end
        return
    end
    if type(a) == "string" and a ~= "" and not b then
        return a, tonumber(d) or 0
    end
end

local function PackProfessionIndices(...)
    return { n = select("#", ...), ... }
end

-- Resolve the current roster function inside the protected call.
local function ReadProfessionIndices()
    return PackProfessionIndices(GetProfessions())
end

local function GetPlayerProfessionSkillLines()
    local lines = {}
    local seen = {}
    local function addLine(id, name, modern, rank)
        local key = id or name
        if not key or seen[tostring(key)] then
            return
        end
        if name and seen["n:" .. name:lower()] then
            return
        end
        seen[tostring(key)] = true
        if name then
            seen["n:" .. name:lower()] = true
        end
        lines[#lines + 1] = {
            id = key,
            name = name,
            modern = modern and true or false,
            rank = tonumber(rank) or 0,
        }
    end
    -- Prefer GetProfessions: only skills the player actually has.
    -- GetAllProfessionTradeSkillLines can return a broader set and caused
    -- login scans to open unrelated lines / wipe caches on failure.
    if GetProfessions and GetProfessionInfo then
        -- Forever book: prof1, prof2, firstAid, fishing, cooking.
        -- Live: prof1, prof2, archaeology, fishing, cooking, firstAid.
        -- Iterate every returned index instead of assuming a slot map.
        local indices = PackProfessionIndices(GetProfessions())
        for i = 1, indices.n do
            local idx = indices[i]
            if idx then
                local name, _, rank, _, _, _, skillLine = GetProfessionInfo(idx)
                addLine(skillLine or name, name, HAS_MODERN_PROF and type(skillLine) == "number", rank)
            end
        end
        if #lines > 0 then
            return lines
        end
    end
    -- Classic Era / TBC: First Aid and professions live on the skill pane.
    if GetNumSkillLines and GetSkillLineInfo then
        local n = GetNumSkillLines() or 0
        for i = 1, n do
            local name, isHeader, _, rank = GetSkillLineInfo(i)
            if name and not isHeader then
                local lname = name:lower()
                if lname:find("alchemy", 1, true)
                    or lname:find("first aid", 1, true)
                    or lname:find("tailoring", 1, true)
                    or lname:find("engineering", 1, true) then
                    addLine(name, name, false, rank)
                end
            end
        end
        if #lines > 0 then
            return lines
        end
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines then
        local ok, all = pcall(C_TradeSkillUI.GetAllProfessionTradeSkillLines)
        if ok and type(all) == "table" then
            for _, id in ipairs(all) do
                if id and not seen[tostring(id)] then
                    addLine(id, nil, true, 0)
                end
            end
        end
    end
    return lines
end

--- GetProfessions plus every non-header skill-pane row (Comprehension, etc.).
local function GetPlayerRankSkillLines()
    if rankLinesCache then
        return rankLinesCache
    end
    local lines = {}
    local seen = {}
    local function addLine(id, name, modern, rank, fromSkillPane)
        local key = id or name
        if not key or seen[tostring(key)] then
            return
        end
        if name and seen["n:" .. name:lower()] then
            return
        end
        seen[tostring(key)] = true
        if name then
            seen["n:" .. name:lower()] = true
        end
        lines[#lines + 1] = {
            id = key,
            name = name,
            modern = modern and true or false,
            rank = tonumber(rank) or 0,
            fromSkillPane = fromSkillPane,
        }
    end
    if GetProfessions and GetProfessionInfo then
        local indices = PackProfessionIndices(GetProfessions())
        for i = 1, indices.n do
            local idx = indices[i]
            if idx then
                local name, _, rank, _, _, _, skillLine = GetProfessionInfo(idx)
                addLine(skillLine or name, name, HAS_MODERN_PROF and type(skillLine) == "number", rank)
            end
        end
    end
    local n = 0
    if C_SkillInfo and C_SkillInfo.GetNumSkillLines then
        local ok, count = pcall(C_SkillInfo.GetNumSkillLines)
        if ok then
            n = tonumber(count) or 0
        end
    end
    if n <= 0 and GetNumSkillLines then
        n = tonumber(GetNumSkillLines()) or 0
    end
    for i = 1, n do
        local name, rank, skillID = SkillLineNameAndRank(i)
        if name then
            addLine(skillID or name, name, false, rank, true)
        end
    end
    -- An empty login roster can be transient. Do not make it a session-long
    -- negative until a profession UI/skill event happens to refresh it.
    if #lines > 0 then rankLinesCache = lines end
    return lines
end

-- Read-only planning knowledge: an unavailable roster is not an unlearn.
-- Durable learned facts belong only to the selected character's existing store.
function Prof.GetProfessionKnowledge(needles, skillLineID)
    if type(needles) == "string" then
        needles = { needles }
    end
    if type(needles) ~= "table" or #needles == 0 then return nil end
    local hasBook = GetProfessions and GetProfessionInfo
    local bookMissing
    local skillID = tonumber(skillLineID)
    if hasBook then
        local ok, indices = pcall(ReadProfessionIndices)
        local observed, incomplete, alias = false, not ok, false
        if ok then
            for i = 1, indices.n do
                local index = indices[i]
                if index ~= nil then
                    local valid, name, icon, rank, maxRank, spells, offset, id = pcall(GetProfessionInfo, index)
                    if valid and type(name) == "string" and name ~= "" then
                        observed = true
                        if skillID and skillID > 0 and tonumber(id) == skillID then return true end
                        if SkillNameMatches(name, needles) then return true end
                        -- Older complete records can name an expansion skill
                        -- while the native book reports its root profession.
                        -- Reverse containment is ambiguity, not positive proof
                        -- or a reason to revoke the saved learned ownership.
                        for _, needle in ipairs(needles) do
                            if SkillNameMatches(needle, { name }) then alias = true end
                        end
                    else incomplete = true end
                end
            end
        end
        -- The native book exposes five/six slots. A shortened/unready result
        -- can still prove a positive match, never a missing profession.
        bookMissing = observed and not incomplete and not alias and indices.n >= 5
    end
    -- A learned skill can be present in the skill pane while omitted from the
    -- profession book. Use positive pane evidence before accepting that miss.
    -- A cached book entry cannot override the live book's removal.
    if (C_SkillInfo and C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo)
        or (GetNumSkillLines and GetSkillLineInfo) then
        local ok, lines = pcall(GetPlayerRankSkillLines)
        if ok then
            for _, line in ipairs(lines) do
                if line.fromSkillPane and (line.rank > 0 or not hasBook)
                    and ((skillID and skillID > 0 and line.id == skillID) or SkillNameMatches(line.name, needles)) then
                    return true
                end
            end
        end
    end
    if bookMissing then return false end
    local db = EnsureDB()
    for _, data in pairs(db.bySkillLine or {}) do
        for _, recipe in ipairs(data.recipes or {}) do
            if recipe.learned == true and SkillNameMatches(recipe.skillName or data.name, needles) then return true end
        end
    end
    return nil
end

-- True + the cached record, false only for recorded revocation, nil if unknown.
-- Legacy row indices are not durable recipe identities; use name/profession.
function Prof.GetRecipeKnowledge(descriptor)
    if type(descriptor) ~= "table" then return nil end
    local id, name = descriptor.recipeID, descriptor.recipeName or descriptor.name
    local skillName = descriptor.skillName
    if skillName and Prof.GetProfessionKnowledge({ skillName }, descriptor.skillLineID) == false then return false end
    local db = EnsureDB()
    if not descriptor.legacy and id then
        for _, data in pairs(db.bySkillLine or {}) do
            if data.unlearnedRecipeIDs and data.unlearnedRecipeIDs[id] == true then return false end
        end
    end
    local list = Prof.ListAllCachedRecipes
    local recipes
    if list == OwnedListAllCachedRecipes and getmetatable(descriptor) == nil and not descriptor.legacy
        and type(id) == "number" and not (issecretvalue and issecretvalue(id))
        and id > 0 and id < 2147483648 and id % 1 == 0 then
        -- Rank every alias of the requested catalogue key, including older
        -- records with differently typed IDs that share the same key.
        recipes = BuildCachedRecipeCatalogue(EnsureDB(), "recipe:" .. tostring(math.floor(id)), "recipe:" .. tostring(id + 0.0))
    else
        recipes = list()
    end
    for _, recipe in ipairs(recipes) do
        local matches = descriptor.legacy and recipe.legacy and type(name) == "string" and name == recipe.name
            and (not skillName or recipe.skillName == skillName)
            or not descriptor.legacy and not recipe.legacy and id ~= nil and id == recipe.recipeID
        if matches then
            if recipe.learned == false then return false end
            if recipe.learned == true then
                if recipe.skillName and Prof.GetProfessionKnowledge({ recipe.skillName }, recipe.skillLineID) == false then return false end
                return true, recipe
            end
        end
    end
    return nil
end

--- Boolean compatibility query; planning consumers use the tri-state API above.
function Prof.HasProfessionName(needles)
    return Prof.GetProfessionKnowledge(needles) == true
end

--- Current rank for a profession name, or 0 if unknown / unlearned.
function Prof.GetProfessionRank(needles)
    if type(needles) == "string" then
        needles = { needles }
    end
    local lines = GetPlayerRankSkillLines()
    for i = 1, #lines do
        if SkillNameMatches(lines[i].name, needles) then
            return tonumber(lines[i].rank) or 0
        end
    end
    return 0
end

--- Secondary / weapon / class skill-pane rank (Forever C_SkillInfo). Not GetProfessions.
--- Comprehension lives here; it is not a crafting profession.
function Prof.GetSkillLineRank(needles)
    if type(needles) == "string" then
        needles = { needles }
    end
    local n = 0
    if C_SkillInfo and C_SkillInfo.GetNumSkillLines then
        local ok, count = pcall(C_SkillInfo.GetNumSkillLines)
        if ok then
            n = tonumber(count) or 0
        end
    end
    if n <= 0 and GetNumSkillLines then
        n = tonumber(GetNumSkillLines()) or 0
    end
    local best = 0
    for i = 1, n do
        local name, rank = SkillLineNameAndRank(i)
        if SkillNameMatches(name, needles) then
            rank = tonumber(rank) or 0
            if rank > best then
                best = rank
            end
        end
    end
    return best
end

local function RequirementRecord(parsed)
    if not parsed or not parsed.skillName then
        return nil
    end
    local rank = Prof.GetSkillLineRank({ parsed.skillName })
    if rank <= 0 then
        rank = Prof.GetProfessionRank({ parsed.skillName })
    end
    local required = tonumber(parsed.required) or 0
    local met = false
    if parsed.color == "white" then
        met = true
    elseif parsed.color == "red" then
        met = false
    else
        met = rank >= required
    end
    if not met and rank >= required and parsed.color ~= "red" then
        met = true
    end
    return {
        skillName = parsed.skillName,
        required = parsed.required,
        met = met,
    }
end

--- Parse a single tooltip line / blob for "Requires Skill (N)".
function Prof.GetSkillRequirementFromText(text, colorHint)
    local skillName, required = ParseSkillRequirementFromText(text)
    if not skillName then
        return nil
    end
    return RequirementRecord({
        skillName = skillName,
        required = required or 1,
        color = colorHint or "other",
    })
end

--- Read the live GameTooltip (Alt-hover) so Forever RestrictedSkill lines are not missed.
function Prof.GetSkillRequirementFromTooltip(tooltip)
    if not tooltip or not tooltip.NumLines then
        return nil, false
    end
    local n = tooltip:NumLines() or 0
    if n < 2 then
        return nil, false
    end
    local prefix = tooltip.GetName and tooltip:GetName()
    for i = 2, math.min(n, 40) do
        local fs = prefix and _G[prefix .. "TextLeft" .. i]
        if not fs then
            fs = tooltip["TextLeft" .. i]
        end
        local text = fs and fs.GetText and fs:GetText()
        local colorHint = "other"
        if fs and fs.GetTextColor then
            local r, g, b = fs:GetTextColor()
            if r and g and b then
                if r > 0.9 and g > 0.9 and b > 0.9 then
                    colorHint = "white"
                elseif r > 0.9 and g < 0.35 and b < 0.35 then
                    colorHint = "red"
                end
            end
        end
        local rec = Prof.GetSkillRequirementFromText(text, colorHint)
        if rec then
            return rec, true
        end
    end
    return nil, true
end

function Prof.GetSkillRequirementFromTooltipData(data)
    if type(data) ~= "table" or type(data.lines) ~= "table" then
        return nil, false
    end
    local lineTypes = Enum and Enum.TooltipDataLineType
    for i = 1, #data.lines do
        local line = data.lines[i]
        if line and TooltipUtil and TooltipUtil.SurfaceArgs then
            pcall(TooltipUtil.SurfaceArgs, line)
        end
        local text = line and (line.leftText or line.rightText)
        local colorHint = "other"
        if lineTypes and line and line.type == lineTypes.RestrictedSkill then
            if ColorLooksWhite(line.leftColor) then
                colorHint = "white"
            elseif ColorLooksRed(line.leftColor) then
                colorHint = "red"
            end
        end
        local rec = Prof.GetSkillRequirementFromText(text, colorHint)
        if rec then
            return rec, true
        end
    end
    return nil, true
end

--- Forever combined bags: RestrictedSkill often exists on the bag-slot tooltip, not GetItemByID.
function Prof.GetSkillRequirementFromBagSlot(bagID, slotID)
    bagID = tonumber(bagID)
    slotID = tonumber(slotID)
    if not bagID or not slotID or not C_TooltipInfo or not C_TooltipInfo.GetBagItem then
        return nil, false
    end
    local ok, data = pcall(C_TooltipInfo.GetBagItem, bagID, slotID)
    if not ok or type(data) ~= "table" then
        return nil, false
    end
    if TooltipUtil and TooltipUtil.SurfaceArgs then
        pcall(TooltipUtil.SurfaceArgs, data)
    end
    return Prof.GetSkillRequirementFromTooltipData(data)
end

local function TooltipDataForItem(itemID)
    itemID = tonumber(itemID)
    if not itemID or not C_TooltipInfo then
        return nil
    end
    if C_TooltipInfo.GetItemByID then
        local ok, data = pcall(C_TooltipInfo.GetItemByID, itemID)
        if ok and type(data) == "table" and data.lines then
            return data
        end
    end
    if C_TooltipInfo.GetHyperlink then
        local IC = _G.FluxItemClass
        local link = (IC and IC.GetLink and IC.GetLink(itemID)) or ("item:" .. itemID)
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
        if ok and type(data) == "table" and data.lines then
            return data
        end
    end
    return nil
end

local function RequirementFromRestrictedSkill(data)
    local lineTypes = Enum and Enum.TooltipDataLineType
    if not (data and data.lines and lineTypes and lineTypes.RestrictedSkill) then
        return nil
    end
    for i = 1, #data.lines do
        local line = data.lines[i]
        if line and TooltipUtil and TooltipUtil.SurfaceArgs then
            pcall(TooltipUtil.SurfaceArgs, line)
        end
        if line and line.type == lineTypes.RestrictedSkill then
            local text = line.leftText or line.rightText
            local skillName, required = ParseSkillRequirementFromText(text)
            if not skillName and type(text) == "string" then
                skillName = text:lower():gsub("^requires%s+", ""):gsub("%s*%(%s*%d+%s*%).*$", ""):gsub("%s+$", "")
                if skillName == "" or skillName == "level" then
                    skillName = nil
                end
            end
            if skillName then
                local color = "other"
                if ColorLooksWhite(line.leftColor) then
                    color = "white"
                elseif ColorLooksRed(line.leftColor) then
                    color = "red"
                end
                return {
                    skillName = skillName,
                    required = tonumber(required) or 1,
                    color = color,
                }
            end
        end
    end
    return nil
end

--- Parse "Requires Comprehension (X)" (and the same form for other skills).
--- Returns `{ skillName, required, met }, ready`. Inconclusive tooltip → nil, false
--- (do not cache a miss). Loaded tooltip with no skill line → nil, true.
function Prof.GetItemSkillRequirement(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil, false
    end
    local cached = itemReqCache[itemID]
    if cached ~= nil then
        if cached == false then
            return nil, true
        end
        return RequirementRecord(cached), true
    end

    local data = TooltipDataForItem(itemID)
    local parsed = RequirementFromRestrictedSkill(data)
    if not parsed then
        local IC = _G.FluxItemClass
        local text
        if IC and IC.GetTooltipText then
            local link = IC.GetLink and IC.GetLink(itemID) or ("item:" .. itemID)
            text = IC.GetTooltipText(itemID, link)
        end
        if (not text or text == "") and data and data.lines then
            local parts = {}
            for i = 1, #data.lines do
                local line = data.lines[i]
                local t = line and (line.leftText or line.rightText)
                if t and t ~= "" then
                    parts[#parts + 1] = t
                end
            end
            if #parts > 0 then
                text = table.concat(parts, "\n")
            end
        end
        if text and text ~= "" then
            local skillName, required = ParseSkillRequirementFromText(text)
            if skillName and required then
                parsed = {
                    skillName = skillName,
                    required = required,
                    color = "other",
                }
            end
        end
        local linesReady = data and data.lines and #data.lines >= 2
        if not parsed and not linesReady and (not text or text == "") then
            return nil, false
        end
    end

    if not parsed then
        -- Forever bag tooltips carry RestrictedSkill that GetItemByID often omits.
        local Client = Flux and Flux.Client
        if Client and (Client.isCamelot or Client.isForever) then
            return nil, false
        end
        itemReqCache[itemID] = false
        return nil, true
    end

    itemReqCache[itemID] = {
        skillName = parsed.skillName,
        required = parsed.required,
        color = parsed.color or "other",
    }
    return Prof.GetItemSkillRequirement(itemID)
end

local function CanAttemptOpen()
    if InCombat() then
        return false
    end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
        return false
    end
    return true
end

local function CloseTradeSkillQuiet()
    if C_TradeSkillUI and C_TradeSkillUI.CloseTradeSkill then
        pcall(C_TradeSkillUI.CloseTradeSkill)
    elseif CloseTradeSkill then
        pcall(CloseTradeSkill)
    end
end

local function OpenModernSkill(skillLineID)
    if C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
        return pcall(C_TradeSkillUI.OpenTradeSkill, skillLineID)
    end
    return false
end

local function OpenLegacyByName(name)
    if not name or name == "" then
        return false
    end
    if CastSpellByName then
        local ok = pcall(CastSpellByName, name)
        return ok
    end
    return false
end

--- Mark player professions that lack recipe data. Do NOT call OpenTradeSkill from
--- timers — it is protected on retail and used to wipe good caches with {}.
function Prof.ScheduleLoginScan()
    if loginScanCompleted or loginScanQueued or loginScanRunning then
        return
    end
    loginScanQueued = true
    loginScanAbort = false
    After(3.0, function()
        loginScanQueued = false
        if loginScanCompleted then
            return
        end
        local queue = GetPlayerProfessionSkillLines()
        for _, entry in ipairs(queue) do
            local key = entry.id or entry.name
            if key then
                local existing = LoadSkill(key)
                local recipes = (existing and existing.recipes) or {}
                if #recipes == 0 then
                    StoreSkill(key, {
                        recipes = recipes,
                        scannedAt = (existing and existing.scannedAt) or Now(),
                        source = (existing and existing.source) or "login",
                        name = entry.name or (existing and existing.name),
                        needsOpen = true,
                    })
                end
            end
        end
        loginScanCompleted = true
        loginScanRunning = false
        -- Soft pulse so ExtraButtons re-evaluate craft binds against existing cache.
        PulseProfessionsChanged()
    end)
end

function Prof.AbortLoginScan()
    loginScanAbort = true
    loginScanRunning = false
end

-- Kept for ForceScan / manual callers; login path no longer auto-opens.
local function RunLoginScanStep(queue, index)
    if loginScanAbort or not loginScanRunning then
        loginScanRunning = false
        return
    end
    if InCombat() then
        loginScanRunning = false
        return
    end
    if index > #queue then
        loginScanRunning = false
        loginScanCompleted = true
        CloseTradeSkillQuiet()
        return
    end
    local entry = queue[index]
    if not CanAttemptOpen() then
        local key = entry.id or entry.name or index
        local existing = LoadSkill(key)
        StoreSkill(key, {
            recipes = (existing and existing.recipes) or {},
            scannedAt = Now(),
            source = "login",
            name = entry.name,
            needsOpen = true,
        })
        After(0.35, function()
            RunLoginScanStep(queue, index + 1)
        end)
        return
    end

    local opened = false
    if entry.modern and entry.id then
        opened = OpenModernSkill(entry.id)
    elseif entry.name then
        opened = OpenLegacyByName(entry.name)
    elseif entry.id and type(entry.id) == "number" then
        opened = OpenModernSkill(entry.id)
    end

    After(0.6, function()
        if loginScanAbort then
            loginScanRunning = false
            CloseTradeSkillQuiet()
            return
        end
        local payload = ScanOpenProfession("login")
        if not payload then
            local key = entry.id or entry.name or index
            local existing = LoadSkill(key)
            StoreSkill(key, {
                recipes = (existing and existing.recipes) or {},
                scannedAt = Now(),
                source = "login",
                name = entry.name,
                needsOpen = true,
            })
        end
        CloseTradeSkillQuiet()
        After(0.45, function()
            RunLoginScanStep(queue, index + 1)
        end)
    end)
end

--- Force a fresh open-profession scan (ignores once-per-session login flag).
function Prof.ForceScanOpen()
    return ScanOpenProfession("open")
end

--- Allow a new login-style profession scan (e.g. after learning a profession).
function Prof.ResetLoginScanState()
    loginScanCompleted = false
    loginScanQueued = false
    loginScanRunning = false
    loginScanAbort = false
end

local eventFrame = CreateFrame("Frame")
SafeRegisterEvent(eventFrame, "PLAYER_ENTERING_WORLD")
SafeRegisterEvent(eventFrame, "PLAYER_REGEN_DISABLED")
SafeRegisterEvent(eventFrame, "TRADE_SKILL_SHOW")
SafeRegisterEvent(eventFrame, "TRADE_SKILL_CLOSE")
SafeRegisterEvent(eventFrame, "TRADE_SKILL_UPDATE")
SafeRegisterEvent(eventFrame, "TRADE_SKILL_LIST_UPDATE")
SafeRegisterEvent(eventFrame, "NEW_RECIPE_LEARNED")
SafeRegisterEvent(eventFrame, "TRADE_SKILL_DATA_SOURCE_CHANGED")
SafeRegisterEvent(eventFrame, "SKILL_LINES_CHANGED")
if learnedFilterReaders then SafeRegisterEvent(eventFrame, "SPELLS_CHANGED") end
eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "SPELLS_CHANGED" then
        ForgetSettledRecipeList()
        return
    end
    if event == "SKILL_LINES_CHANGED" then
        ForgetSettledRecipeList()
        Prof.InvalidateSkillCaches()
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        ForgetSettledRecipeList()
        Prof.ScheduleLoginScan()
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        Prof.AbortLoginScan()
        return
    end
    if event == "TRADE_SKILL_CLOSE" then
        Prof.OnProfessionClosed()
        return
    end
    Prof.OnProfessionEvent(event, arg1, arg2)
end)

local FluxInv = _G.FluxInv
if FluxInv then
    FluxInv.Professions = Prof
end
