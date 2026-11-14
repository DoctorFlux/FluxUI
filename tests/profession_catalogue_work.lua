-- Whole production profession owner; native recipe data is supplied by the
-- shared character-cache fixture. No native crafting or saved settings writes.
local source = arg[1] or "Inventory/Professions.lua"
local baseline = arg[2] == "baseline"
local function ownerLoad(path, ...)
    if path:gsub("\\", "/"):match("Inventory/Professions.lua$") then path = source end
    return loadfile(path, ...)
end
local export = setmetatable({ FLUX_CHARACTER_RECIPE_FIXTURE_EXPORT = true, loadfile = ownerLoad }, { __index = _G })
local Fixture = assert(loadfile("tests/character_recipe_cache.lua", "t", export))()
local checks, models = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function clone(value)
    if type(value) ~= "table" then return value end
    local out = {}; for key, item in pairs(value) do out[key] = clone(item) end; return out
end
local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do if not equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
local function expected(P, id, character)
    local out = {}
    for _, recipe in ipairs(P.ListAllCachedRecipes(character)) do
        local matches = recipe.outputItemID == id
        for _, quality in ipairs(recipe.craftingData and recipe.craftingData.qualityItemIDs or {}) do
            if quality == id then matches = true end
        end
        if matches and recipe.learned == true then out[#out + 1] = recipe end
    end
    return out
end
local function query(P, id, character)
    local want = expected(P, id, character)
    local got = P.ListRecipesForOutput(id, character)
    check(#got == #want, "output query retains winning-alias count")
    for i, recipe in ipairs(want) do check(got[i] == recipe, "winning recipe references and encounter order are retained") end
    return got
end
local file = assert(io.open(source, "rb")); local text = file:read("*a"); file:close()
local collectLine, mergeLine, rankLine, line = nil, nil, nil, 0
for contents in (text .. "\n"):gmatch("(.-)\n") do
    line = line + 1
    if contents:find("local function collect(basicOnly)", 1, true) or contents:find("local function CollectModernReagentRows(", 1, true) then collectLine = line end
    if contents:find("local merged = {}; for field, value in pairs(prior)", 1, true) then mergeLine = line end
    if contents:find("local function Rank(", 1, true) or contents:find("local function RecipeCatalogueRank(", 1, true) then rankLine = line end
end
local normalizedSource = "@" .. source:gsub("\\", "/")
local function sample(fn)
    local calls, identities, mergeIdentities, ranks = 0, {}, {}, 0
    debug.sethook(function(event, currentLine)
        local info = debug.getinfo(2, "fS")
        if not info or info.source:gsub("\\", "/") ~= normalizedSource then return end
        if event == "call" then
            if info.linedefined == collectLine then calls = calls + 1; identities[info.func] = true end
            if info.linedefined == rankLine then ranks = ranks + 1 end
        elseif currentLine == mergeLine then
            for i = 1, 40 do
                local name, value = debug.getlocal(2, i)
                if not name then break end
                if name == "merged" and type(value) == "table" then mergeIdentities[value] = true end
            end
        end
    end, "cl")
    local ok, err = pcall(fn)
    debug.sethook()
    assert(ok, err)
    local count, merges = 0, 0
    for _ in pairs(identities) do count = count + 1 end
    for _ in pairs(mergeIdentities) do merges = merges + 1 end
    return calls, count, merges, ranks
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    for _, provider in ipairs({ false, true }) do
        models = models + 1
        local A, s, e, P = Fixture(client, false, provider)
        local legacy = client == "Era" or client == "Anniversary"
        s.ids, s.recipeData = {}, {}
        for i = 1, 64 do
            local id = i + 1000; s.ids[i] = id
            s.recipeData[id] = { name = "Recipe" .. id, output = id + 100000, yield = 2, learned = true, mats = { { 200, 2 } } }
        end
        check(P.ForceScanOpen() ~= nil, "complete native recipe scan warms the owned catalogue")
        local before = clone(e.FluxInvDB)
        local invalidates, notifies = 0, 0
        s.inventory.Craft = { InvalidateCanCraftCache = function() invalidates = invalidates + 1 end }
        s.inventory.Notify = function(changed) check(changed.professions, "publication payload retained"); notifies = notifies + 1 end
        local calls, identities, merges = sample(function()
            for _ = 1, 3 do P.OnProfessionEvent("TRADE_SKILL_UPDATE") end
        end)
        check(equal(before, e.FluxInvDB), "unchanged native facts retain complete persisted data")
        check(invalidates == (legacy and 6 or 9) and notifies == 3, "all live craft invalidation/publication pulses retain cadence")
        if not baseline then
            check(identities == (legacy and 0 or 1), "one stateless collector replaces per-recipe closures")
            check(merges == 0, "complete fresh facts do not allocate redundant prior merge records")
        end
        local _, _, _, ranks = sample(function()
            for id = 101001, 101020 do check(#P.ListRecipesForOutput(id) == 1, "each learned output remains available") end
        end)
        if not baseline and not legacy then check(ranks <= 40, "output query ranks only matching aliases without a retained index") end
        print(("PROF_WORK %s provider=%s events=3 collectCalls=%d identities=%d mergedRecords=%d outputRanks=%d invalidations=%d publications=%d"):format(
            client, tostring(provider), calls, identities, merges, ranks, invalidates, notifies))

        -- Each query reads mutable current facts; no generation or native craft
        -- availability is retained across invocations.
        query(P, 101001); query(P, 999999); query(P, 101020)
        local key = P.GetCharacterKey(); local db = e.FluxInvDB.professions[key]
        for _, data in pairs(db.bySkillLine) do
            for _, recipe in ipairs(data.recipes) do
                if recipe.outputItemID == 101001 then
                    recipe.outputItemID = 900001
                    recipe.craftingData = recipe.craftingData or {}
                    recipe.craftingData.qualityItemIDs = { 900002 }
                end
            end
        end
        check(#query(P, 101001) == 0 and #query(P, 900001) == 1 and #query(P, 900002) == 1,
            "direct mutable output and quality changes are visible on the next query")
        local rows = query(P, 900001); rows[1] = nil
        check(#query(P, 900001) == 1, "returned output arrays have independent ownership")

        local own = P.ListAllCachedRecipes; local overrides = 0
        local alternate = { recipeID = 999, learned = true, outputItemID = 777 }
        P.ListAllCachedRecipes = function(character) overrides = overrides + 1; check(character == "other", "override character argument retained"); return { alternate } end
        check(P.ListRecipesForOutput(777, "other")[1] == alternate and overrides == 1, "public catalogue override remains authoritative")
        alternate.outputItemID = 778
        check(#P.ListRecipesForOutput(777, "other") == 0 and overrides == 2, "override output remains fresh on every call")
        P.ListAllCachedRecipes = function() error("catalogue-marker") end
        local ok, err = pcall(P.ListRecipesForOutput, 777)
        check(not ok and tostring(err):find("catalogue-marker", 1, true), "public override error propagates")
        P.ListAllCachedRecipes = own
        check(#P.ListRecipesForOutput(0) == 0 and #P.ListRecipesForOutput("invalid") == 0, "invalid output keys retain empty replies")

        -- Complete, partial, changed, unlearned and alias observations still use
        -- the original merge policy. Unknown/custom inherited facts are retained.
        s.ids = { 1001 }; s.recipeData[1001].mats[1][2] = 7
        P.ForceScanOpen()
        local first = query(P, 101001)[1]
        check(first and first.reagents[1].count == 7, "changed native reagent facts replace old quantities")
        first.customFact = "retain-me"
        s.dataMode = "partial"; P.ForceScanOpen()
        first = query(P, 101001)[1]
        check(first and first.customFact == "retain-me" and first.reagents[1].count == 7, "partial facts retain unknown inherited fields and materials")
        s.dataMode = "open"; s.recipeData[1001].learned = false; P.ForceScanOpen()
        if not legacy then check(#query(P, 101001) == 0, "explicit unlearn cannot resurrect through an alias") end
        check(#P.ListRecipesForOutput(101002, "missing-character") == 0, "missing character does not inherit current recipes")

        -- All fallback paths resolve the character only once, as the original
        -- full query does; this matters for public character-name providers.
        local charCalls = 0
        s.flux.PlayerName.GetCharKey = function() charCalls = charCalls + 1; return key end
        P.ListRecipesForOutput(101002)
        check(charCalls == 1, "query resolves the mutable character provider once")
    end
end
-- Conflicting modern aliases must be ranked before the output filter. An old
-- alias with a different output must not resurrect a stale recipe.
do
    local _, _, e, P = Fixture("Retail", false, false)
    local good = { recipeID = 11, learned = true, outputItemID = 101, skillLineID = 171,
        quantityMin = 1, reagents = { { itemID = 200, count = 1 } } }
    local old = { recipeID = 11, learned = true, outputItemID = 100, skillLineID = 171 }
    e.FluxInvDB.professions = { [P.GetCharacterKey()] = { bySkillLine = {
        ["171"] = { source = "open", recipes = { good } }, Alchemy = { source = "login", recipes = { old } },
    } } }
    check(#query(P, 100) == 0 and query(P, 101)[1] == good, "winning alias is chosen before output matching")
    e.FluxInvDB.professions[P.GetCharacterKey()].bySkillLine.Alchemy.unlearnedRecipeIDs = { [11] = true }
    check(#query(P, 101) == 0, "unlearning from any alias revokes the output")
    e.FluxInvDB.professions[P.GetCharacterKey()].bySkillLine = { unknown = { recipes = {
        { name = "Unknown identity", outputItemID = 123, learned = true },
    } } }
    check(#query(P, 123) == 1, "unknown recipe identity keeps the complete catalogue fallback")
end
print("Profession catalogue work: " .. checks .. " checks; " .. models .. " client/provider models PASS; native crafting/FPS NOT RUN")
