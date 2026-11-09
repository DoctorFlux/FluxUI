-- Actual craft service, visibility policy and grid modules; native data mocked.
local function read(path)
    local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close(); return text
end
local replacements = {}
for i, value in ipairs(arg or {}) do
    if value == "--craft" then replacements["Inventory/Craft.lua"] = arg[i + 1] end
    if value == "--bind" then replacements["ExtraButtonSystem/Engine/ConsumableBind.lua"] = arg[i + 1] end
end
local source = read("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua")
local stop = assert(source:find("-- PLAYER_LOGIN bag priming", 1, true))
local env = setmetatable({ arg = { [0] = "ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua" } }, { __index = _G })
env.io = { open = function(path, ...)
    local normalized = path:gsub("\\", "/")
    for original, replacement in pairs(replacements) do
        if normalized:sub(-#original) == original then path = replacement; break end
    end
    return io.open(path, ...)
end }
local boot, items = assert(load(source:sub(1, stop - 1) .. "return boot, items", "@craft-grid-fixture", "t", env))()
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local specs = {
    { kind = "healPotion", id = 118, module = "FluxCombatHealPotion", path = "HealPotion.lua" },
    { kind = "manaPotion", id = 2455, module = "FluxCombatManaPotion", path = "ManaPotion.lua" },
    { kind = "bandage", id = 1251, module = "FluxCombatBandage", path = "Bandage.lua" },
}
local function provider(s)
    local char, callbacks = { bags = {} }, {}
    s.env.Syndicator = {
        Constants = { AllBagIndexes = { 0, 1 }, AllBankIndexes = {} },
        API = { IsReady = function() return true end, GetCurrentCharacter = function() return "Fixture-Realm" end,
            GetCharacter = function() return char end },
        CallbackRegistry = { RegisterCallback = function(_, event, fn) callbacks[event] = fn end },
    }
    s.load("Inventory/Syndicator/Adapter.lua")
    s.inv.Syndicator.RebuildAll = function() s.inv.Syndicator.RebuildBags() end
    s.inv.Syndicator.Start()
    function s:publish()
        for i, bag in ipairs({ 0, 1 }) do
            char.bags[i] = {}
            for slot, rec in pairs(self.slots[bag]) do
                char.bags[i][slot] = { itemID = rec.itemID, itemCount = rec.stackCount, itemLink = rec.hyperlink }
            end
        end
        callbacks.BagCacheUpdate(nil, "Fixture-Realm", { bags = { [0] = true, [1] = true } })
        self:advance(0.5)
    end
end

for _, family in ipairs({ "forever", "retail", "era", "anniversary", "mists" }) do
    for _, sourceName in ipairs({ "builtin", "syndicator" }) do
        for _, spec in ipairs(specs) do
            local s = boot(family, family == "era" or family == "anniversary")
            if sourceName == "syndicator" then provider(s) end
            local label = family .. " " .. sourceName .. " " .. spec.kind
            local skill = spec.kind == "bandage" and (family == "retail" and 197 or 129)
                or (family == "forever" and spec.kind == "healPotion" and 129 or 171)
            local rows = { { recipeID = 9001, outputItemID = spec.id, skillLineID = skill,
                reagents = { { itemID = 70001, count = 2 }, { itemID = 70002, count = 1 } } } }
            s.inv.Professions = { ListAllCachedRecipes = function() return rows end,
                HasProfessionName = function(names) return names[1] == (skill == 129 and "first aid" or skill == 197 and "tailoring" or "alchemy") end }
            s.env.FluxItemClass = { GetStatic = function(id) return { classID = items[id] and 0 or 7 } end }
            s:set(0, 1, 70001, 4); s:set(0, 2, 70002, 2); s:set(1, 1, 80001, 1)
            if s.publish then s:publish() else s:bags() end
            s:advance(9)
            s.load("ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua")
            local visibility = s.env.FluxExtraButtonVisibility
            local mode = "auto"
            visibility.GetRawMode = function() return mode end
            visibility.GetBindingForce = function() return false end
            visibility.SetSlotShown = function(btn, show) if not s.combat then btn.testShown = show end end
            local btn, module = s:button(spec.kind, true, "ExtraButtonSystem/CombatGrid/Buttons/" .. spec.path)
            s.env[spec.module] = module
            s:advance(0.5)
            local craft = s.inv.Craft
            check(craft.CanCraftKind(spec.kind) and btn.testShown, label .. " Auto shows currently craftable recipe")
            check(not module._trackedItemID, label .. " craft-only fixture owns no output item")
            local scans = s.scans
            s:set(0, 1, 70001, 1) -- Count-only: same IDs, now below recipe cost.
            if s.publish then s:publish() else s:bags() end
            s:advance(0.5)
            check(not craft.CanCraftKind(spec.kind), label .. " insufficient bag materials are not craftable")
            check(not btn.testShown, label .. " Auto hides after reagent count-only depletion")
            check(s.scans == scans, label .. " reagent-only change avoids consumable rescan")
            s:event("PLAYER_REGEN_ENABLED"); s:advance(0.6)
            check(not btn.testShown, label .. " settled empty Auto slot remains hidden")
            s:set(0, 1, 70001, 4)
            if s.publish then s:publish() else s:bags() end
            s:advance(0.5)
            check(craft.CanCraftKind(spec.kind) and btn.testShown, label .. " count-only reagent gain restores Auto slot")
            if sourceName == "syndicator" then
                s:set(0, 1, 70001, 1)
                s:event("BAG_UPDATE_DELAYED"); s:advance(0.4)
                check(craft.GetCraftableCount(rows[1]) == 0 and not btn.testShown,
                    label .. " live count below recipe cost hides before provider publication")
                local scansBefore, writesBefore, framesBefore = s.scans, s.writes, #s.frames
                s:set(0, 1, 70001, 0)
                for _ = 1, 100 do s:event("BAG_UPDATE_DELAYED"); s:advance(0.001) end
                s:advance(0.4)
                check(s.inv.GetCount(70001) == 4, label .. " delayed provider snapshot retained in fixture")
                check(craft.GetCraftableCount(rows[1]) == 0, label .. " live bag zero overrides stale provider reagent count")
                check(not craft.CanCraftKind(spec.kind) and not btn.testShown, label .. " no phantom craft/Auto slot before provider callback")
                check(s.scans == scansBefore and s.writes == writesBefore and #s.frames == framesBefore,
                    label .. " native reagent burst adds no selector scans/main binds/frames")
                s:publish()
            else
                s:set(0, 1, 70001, 0); s:bags()
            end
            s.inv.snapshots.bank.counts[70001], s.inv.snapshots.warband.counts[70001] = 80, 90
            craft.InvalidateCanCraftCache(); module.Update(true)
            check(not craft.CanCraftKind(spec.kind) and not btn.testShown, label .. " bank materials cannot keep empty Auto slot visible")
            mode = "always"; module.Update(true)
            check(btn.testShown, label .. " Always retains placeholder feature")
            mode = "off"; module.Update(true)
            check(not btn.testShown, label .. " Off remains hidden")
            s:advance(0.5)
            local pendingTimers = #s.timers
            for _ = 1, 50 do s:event("BAG_UPDATE_DELAYED") end
            check(#s.timers == pendingTimers, label .. " Off does not schedule native craft refresh work")
            mode = "auto"
            s:set(0, 3, spec.id, 1)
            if s.publish then s:publish() else s:bags() end
            s:advance(0.6)
            check(btn.ItemId == spec.id and btn.testShown, label .. " owned output shows without craft materials")
            if family == "forever" and spec.kind == "healPotion" then
                s:set(0, 1, 70001, 4)
                if s.publish then s:publish() else s:bags() end
                craft.InvalidateCanCraftCache()
                local best = craft.GetBestCraftable("healPotion")
                check(best and best.skillLineID == 129 and craft.HasProfessionForKind("healPotion"), label .. " healing potion crafting uses First Aid")
                rows = { { recipeID = 9002, outputItemID = 118, skillLineID = 171,
                    reagents = { { itemID = 70001, count = 1 } } } }
                craft.InvalidateCanCraftCache()
                check(not craft.CanCraftKind("healPotion"), label .. " stale Alchemy recipe is not Forever healing craft")
            end
        end
    end
end
print(("Consumable craft visibility: %d checks, %d failures; native acceptance pending"):format(checks, failures))
assert(failures == 0, "consumable craft visibility regression")
