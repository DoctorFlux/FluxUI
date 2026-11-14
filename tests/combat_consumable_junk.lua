-- Real tier/junk/sell owners; native items and provider publication are modeled.
local function read(path)
    local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close(); return text
end
local replace = {}
for i, flag in ipairs(arg or {}) do
    if flag == "--match" then replace["Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua"] = arg[i + 1] end
    if flag == "--inferior" then replace["Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua"] = arg[i + 1] end
    if flag == "--junk" then replace["Inventory/Restock/Junk/FluxJunk.lua"] = arg[i + 1] end
end
local function replacement(path)
    local normalized = path:gsub("\\", "/")
    for original, candidate in pairs(replace) do
        if normalized:sub(-#original) == original then return candidate end
    end
    return path
end
local fixture = read("Inventory/Restock/Junk/_tmp_junksmoke.lua")
local stop = assert(fixture:find('for _, family in ipairs(', 1, true))
local fixtureEnv = setmetatable({ arg = { [0] = "Inventory/Restock/Junk/_tmp_junksmoke.lua" },
    loadfile = function(path, ...) return loadfile(replacement(path), ...) end }, { __index = _G })
local boot = assert(load(fixture:sub(1, stop - 1) .. "return Boot", "@combat-junk-fixture", "t", fixtureEnv))()
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local kinds = { "bandage", "healPotion", "manaPotion" }
for _, family in ipairs({ "forever", "live", "era", "anniversary", "mists" }) do
    for _, timing in ipairs({ "immediate", "delayed-provider" }) do
        for _, kind in ipairs(kinds) do
            local t = boot(family)
            local e, inv, cls = t.env, t.inv, {}
            e.UnitLevel = function() return 60 end
            t.settings.junkFilters.consumable, t.settings.junkFilters.consumableLvl = true, 0.15
            local generation, unique, walks, liveQueries = 1, {}, 0, 0
            local function physical(id)
                liveQueries = liveQueries + 1
                local n = 0
                for _, slots in pairs(t.bags) do for _, rec in pairs(slots) do
                    if rec.itemID == id then n = n + rec.count end
                end end
                return n
            end
            inv.Bags = inv.Bags or {}
            inv.Bags.GetUniqueItems = function() walks = walks + 1; return unique end
            inv.Bags.GetGeneration = function() return generation end
            inv.GetLiveCount = function(id, opts)
                assert(opts.bags and not opts.bank and not opts.warband and opts.charges == false, "live replacement count is bags-only copies")
                return physical(id)
            end
            e.Flux.Inventory.GetLiveCount = inv.GetLiveCount
            inv.Bank = { GetCharacterCounts = function() return { [710004] = 80 } end,
                GetWarbandCounts = function() return { [710004] = 90 } end, IsOpen = function() return false end }
            local blocked, pending = {}, {}
            e.FluxConsumableClassify = { Classify = function(id) return not pending[id] and cls[id] or nil end,
                IsRejected = function() return false end }
            e.FluxConsumableBest = {
                _generation = 1,
                GetBest = function(k) return { itemID = 710004, effective = 1000, count = 0, source = "vendor", kind = k } end,
                GetBestRef = function(k) return { itemID = 710004, effective = 1000, kind = k } end,
                Score = { IsKnownUnusable = function(id) return blocked[id] == true end,
                    IsUsable = function(id) return not blocked[id] end },
                Persist = { GetAllVendorSeen = function() return { [710004] = true } end },
            }
            -- Recipe availability is not ownership. This record is deliberately
            -- better than every carried output throughout the first scenario.
            inv.Craft = { GetBestCraftable = function() return { outputItemID = 710004, craftable = 20 } end }
            local function loadOwner(name)
                return assert(load(read(replacement(name)), "@" .. name, "t", e))("_FluxUI", t.ns)
            end
            loadOwner("Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua")
            loadOwner("Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua")
            loadOwner("Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua")
            loadOwner("Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua")
            local tiers, fj = e.FluxRestockTiers, t.fj
            local p = tiers._Private
            p.GetMerchantCacheGen = function() return 1 end
            p.GetVendorBestTier = function() return 1000, 710004 end
            tiers.IsTierEligible = function() return true end
            tiers.EnsureStores()
            local function add(slot, id, value, itemKind)
                itemKind = itemKind or kind
                cls[id] = { kind = itemKind, health = itemKind == "manaPotion" and 0 or value,
                    mana = itemKind == "manaPotion" and value or 0, effective = value }
                t.add(slot, id, { name = itemKind .. id, classID = 0, quality = 1, itemLevel = 3,
                    subClassID = itemKind == "bandage" and 7 or 1, equipLoc = "" })
            end
            local function publish()
                unique = {}
                for _, slots in pairs(t.bags) do for _, rec in pairs(slots) do
                    local entry = unique[rec.itemID] or { count = 0 }
                    entry.count = entry.count + rec.count; unique[rec.itemID] = entry
                end end
                generation = generation + 1
            end
            local function recompute()
                tiers.RecomputeInferior(nil, { sync = true, bagsOnly = true, skipRemember = true })
            end
            local label = family .. " " .. timing .. " " .. kind
            p.SetSavedTier(kind, 1000)
            add(1, 710001, 100); publish(); recompute()
            check(not fj.IsUpgradeInferior(710001), label .. " current best carried tier is not inferior to remembered/vendor/recipe tiers")
            check(not fj.IsJunk(710001) and not fj.IsJunkForDisplay(710001), label .. " low item level cannot junk the only carried tier")
            check(not fj.IsFiltered(710001), label .. " direct automatic-rule query also protects current best")
            check(p.GetTierRestockThreshold(kind) == 1000, label .. " purchase threshold retained independently")
            check(tiers.IsCarriedUpgradeRequired(kind), label .. " global carried-replacement protection defaults on")
            check(tiers.SetCarriedUpgradeRequired(kind, false), label .. " per-kind global safety can be changed")
            recompute()
            check(tiers.GetJunkReferenceTier(kind) >= 1000, label .. " opt-out restores remembered/vendor tier comparisons")
            check(fj.IsJunk(710001) and fj.IsJunkForDisplay(710001), label .. " explicit opt-out permits ordinary automatic rules without a carried upgrade")
            for _, other in ipairs(kinds) do
                if other ~= kind then check(tiers.IsCarriedUpgradeRequired(other), label .. " opt-out preserves " .. other .. " protection") end
            end
            tiers.SetCarriedUpgradeRequired(kind, true); recompute()
            check(not fj.IsJunk(710001) and not fj.IsJunkForDisplay(710001), label .. " re-enabling protects immediately despite a warmed junk verdict")
            local initialWalks, initialQueries = walks, liveQueries
            for _ = 1, 100 do fj.IsJunk(710001); fj.IsJunkForDisplay(710001) end
            check(walks == initialWalks, label .. " repeated overlays/verdicts add no bag walks")
            local warmWalks, warmQueries = walks - initialWalks, liveQueries - initialQueries
            check(warmQueries == 0, label .. " highest-tier display skips unnecessary live replacement counts")
            fj.MarkUpgradeInferior(710001)
            fj.SetInferiorSet({ [710001] = true })
            check(not fj.IsUpgradeInferior(710001) and not fj.IsJunk(710001), label .. " direct/stale mark cannot bypass carried upgrade requirement")
            fj.ClearUpgradeInferiorList()
            add(2, 710002, 200); publish(); recompute()
            check(fj.IsUpgradeInferior(710001) and fj.IsJunk(710001), label .. " real higher carried tier permits lower-tier junk")
            check(not fj.IsJunk(710002) and not fj.IsJunkForDisplay(710002), label .. " current best stays useful despite higher remembered tier")
            t.bags[0][2] = nil
            if timing == "immediate" then publish() end
            check(not fj.IsJunk(710001) and not fj.IsJunkForDisplay(710001), label .. " losing last better copy immediately protects remaining tier")
            t.facts[710001].classID = nil -- Cached classification may outlive partial native metadata.
            check(not fj.IsJunk(710001) and not fj.IsJunkForDisplay(710001), label .. " missing class metadata cannot bypass carried-tier protection")
            t.facts[710001].classID = 0
            check(not fj.AnyUpgradeInferiorInBags() and fj.GetUpgradeInferiorSlotCount() == 0,
                label .. " inferior availability and queue counts drop the remaining best tier")
            local filter = { [kind] = { value = 1000, itemID = 710004 } }
            tiers.ForcePublishInferiorForKinds(filter)
            check(not fj.IsJunk(710001), label .. " pending vendor upgrade cannot mark without delivered output")
            check(not tiers.BagsHaveInferiorForPendingKinds(filter), label .. " stale pending upgrade cannot keep sell session active")
            publish(); recompute()
            add(3, 710003, 100); publish(); recompute()
            check(not fj.IsJunk(710001) and not fj.IsJunk(710003), label .. " equal tiers remain useful across different item IDs")
            add(5, 710005, 1000, kind == "bandage" and "manaPotion" or "bandage"); publish(); recompute()
            check(not fj.IsJunk(710001), label .. " higher item of another kind cannot set this cutoff")
            t.bags[0][5] = nil; publish(); recompute()
            add(4, 710004, 1000); blocked[710004] = true; publish(); recompute()
            check(not fj.IsJunk(710001), label .. " unusable higher stock does not invalidate current tier")
            t.bags[0][4] = nil; publish(); recompute()
            -- A finished craft counts, while merely knowing/crafting toward a
            -- higher recipe does not. Routing belongs to the unchanged Craft owner.
            for _, profession in ipairs(kind == "bandage" and { "First Aid", "Tailoring" } or { "Alchemy", "First Aid" }) do
                add(2, 710002, 200); publish(); recompute()
                check(fj.IsJunk(710001) and not fj.IsJunk(710002), label .. " finished " .. profession .. " craft upgrades carried cutoff")
                t.bags[0][2] = nil; publish(); recompute()
                check(not fj.IsJunk(710001), label .. " spent crafted upgrade restores lower carried tier")
            end
            add(2, 710002, 200); add(4, 710006, 400); publish(); recompute()
            check(fj.IsJunk(710001) and fj.IsJunk(710002) and not fj.IsJunk(710006), label .. " only current highest of three tiers is protected")
            t.bags[0][4] = nil
            check(fj.IsJunk(710001) and not fj.IsJunk(710002), label .. " stale candidate list falls back to next live tier")
            local cachedWalks = walks
            blocked[710002] = true
            check(not fj.IsJunk(710001), label .. " cached candidates retain live usability gate")
            blocked[710002] = nil
            check(fj.IsJunk(710001) and walks == cachedWalks, label .. " recovered usability reuses candidates without another walk")
            local store, fields = p.KindStore(kind)
            store[fields.mark] = false; fj.ClearUpgradeInferiorList(); fj.InvalidateRules()
            check(fj.IsJunk(710001) and not fj.IsJunk(710002), label .. " independent low-level option still applies with a real carried upgrade")
            t.settings.junkFilters.consumable = false; fj.InvalidateRules()
            check(not fj.IsJunk(710001), label .. " disabling both automatic rules keeps lower tier useful")
            store[fields.mark], t.settings.junkFilters.consumable = true, true; fj.InvalidateRules()
            t.bags[0][2] = nil; publish(); recompute()
            pending[710001] = true
            check(not fj.IsJunk(710001) and not fj.IsJunkForDisplay(710001), label .. " unresolved potion/bandage metadata is protected")
            pending[710001] = nil
            t.settings.junkList[710001] = true
            check(fj.IsJunk(710001) and fj.IsJunkForDisplay(710001), label .. " explicit Junk retains precedence")
            t.settings.junkList[710001] = nil
            t.settings.restockItems[710001] = { targetQuantity = 10 }
            add(2, 710002, 200); publish(); recompute()
            check(not fj.IsJunk(710001), label .. " manual restock protection retained")
            t.settings.restockItems[710001] = nil; t.settings.junkList[710001] = false
            check(not fj.IsJunk(710001), label .. " explicit Useful retains precedence")
            t.settings.junkList[710001] = nil; t.bags[0][2] = nil; t.bags[0][3] = nil
            publish(); recompute(); fj.InvalidateRules()
            t.sj.Start("all"); t.advance(1)
            check(#t.calls == 0 and t.bags[0][1], label .. " Sell All leaves only carried tier intact")
            add(2, 710002, 200); publish(); recompute()
            t.sj.Start("all"); t.advance(2)
            check(#t.calls == 1 and t.calls[1].itemID == 710001 and t.bags[0][2], label .. " Sell All sells lower tier and retains actual upgrade")
            check(#t.errors == 0, label .. " seller remains bounded and avoids duplicate use")
            print(("SAMPLE %s %s %s bagWalks=%d liveQueries=%d sells=%d warmWalks=%d warmLiveQueries=%d"):format(
                family, timing, kind, walks, liveQueries, #t.calls, warmWalks, warmQueries))
        end
    end
end
print(("Combat consumable junk: %d checks, %d failures; native acceptance pending"):format(checks, failures))
assert(failures == 0, "combat consumable junk regression")
