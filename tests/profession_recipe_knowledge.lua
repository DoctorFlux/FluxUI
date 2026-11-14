-- Actual per-character profession store across reload and unavailable live APIs.
-- No profession is opened and no native command is submitted by these queries.
local checks, profiles, context = 0, 0, ""
local function check(value, label) checks = checks + 1; assert(value, label .. " [" .. context .. "]") end
local export = setmetatable({ FLUX_CHARACTER_RECIPE_FIXTURE_EXPORT = true }, { __index = _G })
local source = assert(loadfile("tests/character_recipe_cache.lua", "t", export)); if setfenv then setfenv(source, export) end
local boot = source()
local function Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for key, entry in pairs(value) do out[key] = Copy(entry) end; return out
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1; context = client .. "/" .. tostring(auctionator) .. "/" .. tostring(syndicator)
        local A, st, env, P = boot(client, auctionator, syndicator)
        check(P.ForceScanOpen() ~= nil, "the real owned profession scanner establishes learned facts")
        local saved = Copy(env.FluxInvDB)
        local descriptor = { recipeID = legacy and 1 or 11, recipeName = "Potion A", legacy = legacy,
            skillName = "Alchemy", skillLineID = 171, outputItemID = 100 }
        A, st, env, P = boot(client, auctionator, syndicator, saved, "Alice", true)
        env.GetProfessions = function() return nil end
        env.GetProfessionInfo = function() return nil end
        check(P.GetCharacterKey() == "Realm-Alice", "knowledge exposes only the resolved current character key")
        check(P.GetProfessionKnowledge({ "Alchemy" }) == true and P.HasProfessionName("Alchemy"),
            "a closed unavailable profession roster preserves current-character learned ownership")
        local known, recipe = P.GetRecipeKnowledge(descriptor)
        check(known == true and recipe.outputItemID == 100 and recipe.quantityMin == 2
            and recipe.reagents[1].count == 2 and recipe.reagents[2].count == 1,
            "reloaded learned recipe retains its exact output yield and complete materials without live APIs")
        check(#A.CraftRecipes({ itemID = 100, name = "Item100" }) == 1,
            "the actual AH recipe consumer works while both roster and trade-skill APIs are closed")
        check(P.GetRecipeKnowledge({ recipeID = 999, recipeName = "Unknown", legacy = legacy,
            skillName = "Alchemy" }) == nil, "missing cache facts are unknown rather than a recipe revocation")
        env.GetProfessions = function() return 1, 2 end
        env.GetProfessionInfo = function(index) if index == 1 then return "Tailoring", 1, 150 end end
        check(P.GetProfessionKnowledge("Alchemy") == true and P.GetProfessionKnowledge("Engineering") == nil,
            "an incomplete roster cannot disprove a cached profession or invent another")
        env.GetProfessions = function() return nil, nil, 3, nil, nil, nil end
        env.GetProfessionInfo = function(index) if index == 3 then return "First Aid", 1, 150 end end
        check(P.GetProfessionKnowledge("First Aid") == true,
            "nil primary slots cannot hide a later learned secondary profession")
        env.GetProfessions = function() return nil, nil, 3, 4, 5 end
        env.GetProfessionInfo = function(index)
            local names = { [3] = "First Aid", [4] = "Fishing", [5] = "Cooking" }
            return names[index], 1, index * 10, 300, 2, 0, index + 100
        end
        check(P.GetProfessionKnowledge("First Aid") == true and P.GetProfessionRank("First Aid") == 30
            and P.GetProfessionKnowledge("Fishing") == true and P.GetProfessionKnowledge("Cooking") == true,
            "Forever five-slot nil-primary book resolves First Aid Fishing and Cooking from native metadata")
        local _, _, retailEnv, retailP = boot(client, auctionator, syndicator, saved, "Alice", true)
        retailEnv.GetProfessions = function() return nil, nil, 3, 4, 5, 6 end
        retailEnv.GetProfessionInfo = function(index)
            local names = { [3] = "Archaeology", [4] = "Fishing", [5] = "Cooking", [6] = "First Aid" }
            return names[index], 1, index * 10, 300, 2, 0, index + 100
        end
        check(retailP.GetProfessionKnowledge("Archaeology") == true and retailP.GetProfessionRank("First Aid") == 60
            and retailP.GetProfessionKnowledge("First Aid") == true,
            "Retail six-slot book keeps Archaeology distinct from the later First Aid slot")
        env.GetProfessions = function() return 1, nil, nil, nil, nil, nil end
        env.GetProfessionInfo = function() return "Tailoring", 1, 150 end
        check(P.GetProfessionKnowledge("Alchemy") == false and P.GetRecipeKnowledge(descriptor) == false,
            "a complete resolved nonmatching native profession roster invalidates old ownership")

        local _, other, otherEnv, otherP = boot(client, auctionator, syndicator, saved, "Bob", true)
        otherEnv.GetProfessions = function() return nil end; otherEnv.GetProfessionInfo = function() return nil end
        check(otherP.GetProfessionKnowledge("Alchemy") == nil and otherP.GetRecipeKnowledge(descriptor) == nil,
            "another character never borrows a saved learned profession or recipe")
        check(#otherP.ListRecipesForOutput(100, "Realm-Alice") == 1 and otherP.GetRecipeKnowledge(descriptor) == nil,
            "explicit foreign-character browsing cannot contaminate current-character knowledge")
        other.flux.PlayerName.GetCharKey = function() return nil end
        check(otherP.GetCharacterKey() == nil, "unresolved character identity is not exported as an owner")

        A, st, env, P = boot(client, auctionator, syndicator, saved, "Alice", true)
        if legacy then
            local moved = Copy(descriptor); moved.recipeID = 999
            check(P.GetRecipeKnowledge(moved) == true,
                "legacy recipe row indices are not treated as persistent recipe identity")
        else
            local onlyChild = Copy(saved)
            local oldChild = onlyChild.professions["Realm-Alice"].bySkillLine.Alchemy
            oldChild.name = "Cataclysm Alchemy"
            for _, cachedRecipe in ipairs(oldChild.recipes) do
                cachedRecipe.skillName, cachedRecipe.skillLineID = "Cataclysm Alchemy", 2871
            end
            onlyChild.professions["Realm-Alice"].bySkillLine = { ["Cataclysm Alchemy"] = oldChild }
            local aliasA, aliasState, aliasEnv, aliasP = boot(client, auctionator, syndicator, onlyChild, "Alice", true)
            aliasEnv.GetProfessions = function() return 1, nil, nil, nil, nil, nil end
            aliasEnv.GetProfessionInfo = function() return "Alchemy", 1, 150, 300, 2, 0, 171 end
            check(aliasP.GetRecipeKnowledge(descriptor) == true and #aliasP.ListRecipesForOutput(100) == 1,
                "the only old expansion-key cache is valid before a new parent-key observation")
            aliasState.dataMode, aliasState.ids = "partial", { 11 }; aliasP.ForceScanOpen(); aliasState.dataMode = "offline"
            local aliasKnown, aliasRecipe = aliasP.GetRecipeKnowledge(descriptor)
            check(aliasKnown == true and #aliasP.ListRecipesForOutput(100) == 1 and aliasRecipe.outputItemID == 100
                and aliasRecipe.quantityMin == 2 and #aliasRecipe.reagents == 2
                and #aliasA.CraftRecipes({ itemID = 100, name = "Item100" }) == 1,
                "an uninformative own parent-key scan preserves the only old alias output yield and materials")
            aliasState.dataMode = "open"; aliasState.recipeData[11].yield = 3; aliasState.recipeData[11].mats[1][2] = 4
            aliasP.ForceScanOpen(); aliasState.dataMode = "offline"
            local _, changedRecipe = aliasP.GetRecipeKnowledge(descriptor)
            check(changedRecipe.quantityMin == 3 and changedRecipe.reagents[1].count == 4,
                "new complete own observations still supersede the retained old alias facts")
            local oldAlias = Copy(saved)
            for _, cachedRecipe in ipairs(oldAlias.professions["Realm-Alice"].bySkillLine.Alchemy.recipes) do
                if cachedRecipe.recipeID == 11 then cachedRecipe.craftingData = { version = 1, complete = false }; cachedRecipe.reagents = {} end
            end
            local _, _, _, bestCache = boot(client, auctionator, syndicator, oldAlias, "Alice", true)
            local bestKnown, bestRecipe = bestCache.GetRecipeKnowledge(descriptor)
            check(bestKnown == true and bestRecipe.craftingData.complete == true and #bestRecipe.reagents == 2,
                "a stale incomplete name alias cannot hide the complete canonical saved recipe after reload")
            local childNamed = Copy(saved)
            for _, data in pairs(childNamed.professions["Realm-Alice"].bySkillLine) do
                data.name = "Cataclysm Alchemy"
                for _, cachedRecipe in ipairs(data.recipes) do cachedRecipe.skillName = "Cataclysm Alchemy" end
            end
            local childLines = childNamed.professions["Realm-Alice"].bySkillLine
            childLines["Cataclysm Alchemy"], childLines["Alchemy"] = childLines["Alchemy"], nil
            childLines["First Aid"] = { source = "open", name = "First Aid", recipes = {
                { recipeID = 11, legacy = true, name = "Bandage", skillName = "First Aid", outputItemID = 999,
                    quantityMin = 1, learned = true, reagents = { { itemID = 998, count = 1 } } },
            } }
            local childA, childState, childEnv, childP = boot(client, auctionator, syndicator, childNamed, "Alice", true)
            childEnv.GetProfessions = function() return 1, nil, nil, nil, nil, nil end
            childEnv.GetProfessionInfo = function() return "Alchemy", 1, 150, 300, 2, 0, 171 end
            local childDescriptor = Copy(descriptor); childDescriptor.skillName = "Cataclysm Alchemy"
            check(childP.GetProfessionKnowledge("Cataclysm Alchemy") == true
                and childP.GetProfessionKnowledge("Cataclysm Alchemy", 171) == true
                and childP.GetRecipeKnowledge(childDescriptor) == true
                and #childA.CraftRecipes({ itemID = 100, name = "Item100" }) == 1,
                "an old complete expansion-named record remains usable beside the live root profession without opening it")
            childEnv.GetProfessionInfo = function() return "Tailoring", 1, 150, 300, 2, 0, 197 end
            check(childP.GetProfessionKnowledge("Cataclysm Alchemy", 171) == false
                and childP.GetRecipeKnowledge(childDescriptor) == false,
                "root-name alias tolerance cannot retain a recipe when the complete owned roster is unrelated")
            childEnv.GetProfessionInfo = function() return "Alchemy", 1, 150, 300, 2, 0, 171 end
            childState.dataMode, childState.recipeData[11].learned = "open", false
            childP.ForceScanOpen(); childState.dataMode = "offline"
            check(#childP.ListRecipesForOutput(100) == 0 and childP.GetRecipeKnowledge(childDescriptor) == false,
                "an own root-profession unlearn also revokes the older expansion-name cache alias")
            check(#childP.ListCachedRecipes("Cataclysm Alchemy") == 1,
                "direct old-alias consumers cannot recover the unlearned recipe through its previous skill key")
            check(#childP.ListRecipesForOutput(999) == 1,
                "a modern recipe observation never changes a legacy profession row with the same transient index")
            childState.dataMode, childState.recipeData[11].learned = "open", true
            childState.recipeData[11].mats[1][2] = 3; childP.ForceScanOpen(); childState.dataMode = "offline"
            check(childP.GetRecipeKnowledge(childDescriptor) == true
                and childP.ListRecipesForOutput(100)[1].reagents[1].count == 3,
                "relearning clears old alias tombstones and publishes the new material facts through every alias")
            local ts = env.C_TradeSkillUI
            st.dataMode, st.recipeData[11].learned = "open", false
            ts.IsTradeSkillReady = function() return false end
            check(P.ForceScanOpen() == nil and P.GetRecipeKnowledge(descriptor) == true,
                "a not-ready own profession cannot record learned-false as revocation")
            ts.IsTradeSkillReady = nil
            for _, field in ipairs({ "IsTradeSkillLinked", "IsTradeSkillGuild", "IsNPCCrafting" }) do
                local prior = ts[field]; ts[field] = function() return true end
                check(P.ForceScanOpen() == nil and P.GetRecipeKnowledge(descriptor) == true,
                    "foreign linked guild or NPC views cannot revoke the character recipe")
                ts[field] = prior
            end
            local child = ts.GetChildProfessionInfo; ts.GetChildProfessionInfo = function() return {} end
            P.ForceScanOpen()
            check(P.GetRecipeKnowledge(descriptor) == true,
                "unresolved modern profession identity cannot revoke a cached recipe through a stale legacy line")
            ts.GetChildProfessionInfo = child
            check(P.ForceScanOpen() ~= nil and #P.ListRecipesForOutput(100) == 0 and P.GetRecipeKnowledge(descriptor) == false,
                "an explicit own resolved open learned-false scan records recipe revocation")
            local revoked = Copy(env.FluxInvDB)
            local _, _, reloadEnv, reloadP = boot(client, auctionator, syndicator, revoked, "Alice", true)
            reloadEnv.GetProfessions = function() return nil end; reloadEnv.GetProfessionInfo = function() return nil end
            check(reloadP.GetRecipeKnowledge(descriptor) == false,
                "explicit recipe revocation survives reload while the native profession APIs are closed")
            st.recipeData[11].learned = true; P.ForceScanOpen()
            check(P.GetRecipeKnowledge(descriptor) == true,
                "learning the recipe again clears its persisted revocation")
        end
        check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack and not st.calls.buyItem,
            "profession knowledge reads never submit an auction or craft command")
    end end
end
print(("Profession recipe knowledge: %d checks PASS; %d profiles; native persistence/profession ownership NOT RUN"):format(checks, profiles))
