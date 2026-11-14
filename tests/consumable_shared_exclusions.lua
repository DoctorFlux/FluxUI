-- Shared exclusions must reach the real Best scanner and secure consumable button.
local file = assert(io.open('ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua'))
local source = file:read('*a'); file:close()
local stop = assert(source:find('-- PLAYER_LOGIN bag priming', 1, true))
local fixtureEnv = setmetatable({ arg = { [0] = 'ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua' } }, { __index = _G })
local boot, items = assert(load(source:sub(1, stop - 1) .. 'return boot, items', '@shared-exclusions-fixture', 't', fixtureEnv))()
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function provider(s)
    local char, callbacks = { bags = {} }, {}
    s.env.Syndicator = {
        Constants = { AllBagIndexes = { 0, 1 }, AllBankIndexes = {} },
        API = { IsReady = function() return true end, GetCurrentCharacter = function() return 'Fixture-Realm' end,
            GetCharacter = function() return char end },
        CallbackRegistry = { RegisterCallback = function(_, event, fn) callbacks[event] = fn end },
    }
    s.load('Inventory/Syndicator/Adapter.lua')
    s.inv.Syndicator.RebuildAll = function() s.inv.Syndicator.RebuildBags() end
    s.inv.Syndicator.Start()
    function s:publish()
        for i, bag in ipairs({ 0, 1 }) do
            char.bags[i] = {}
            for slot, rec in pairs(self.slots[bag]) do
                char.bags[i][slot] = { itemID = rec.itemID, itemCount = rec.stackCount, itemLink = rec.hyperlink }
            end
        end
        callbacks.BagCacheUpdate(nil, 'Fixture-Realm', { bags = { [0] = true, [1] = true } })
        self:advance(0.4)
    end
end
for id, data in pairs({
    [770001] = { name = 'A discolored restorative', kind = 'healPotion', effective = 400 },
    [770002] = { name = 'Restorative dIsCoLoReD of healing', kind = 'healPotion', effective = 350 },
    [770003] = { name = 'Discolored Superior Healing Potion', kind = 'healPotion', effective = 300 },
    [770004] = { name = 'Clear Healing Potion', kind = 'healPotion', effective = 200 },
    [770005] = { name = 'Discolored Mana Potion', kind = 'manaPotion', effective = 400 },
    [770006] = { name = 'Discolored Dressing', kind = 'bandage', effective = 400 },
}) do items[id] = data end
for _, family in ipairs({ 'retail', 'forever', 'mists', 'era', 'anniversary' }) do
 for _, sourceKind in ipairs({ 'builtin', 'syndicator' }) do
    profiles = profiles + 1
    local s = boot(family, family == 'era' or family == 'anniversary')
    if sourceKind == 'syndicator' then provider(s) end
    local env, best, settings = s.env, s.best, {}
    env.FluxRestockSettings = { Get = function() return settings end }
    env.FluxItemClass = {
        GetName = function(id) return items[id] and items[id].name or ('item' .. id) end,
        GetInfo = function(id) return { name = items[id] and items[id].name or ('item' .. id), minLevel = 1 } end,
        GetClassID = function() return 0 end,
        GetSubClassID = function(id) return items[id] and items[id].kind == 'bandage' and 7 or 1 end,
    }
    s.load('Inventory/FluxConsumableBest/Persist.lua')
    s.load('Inventory/FluxConsumableBest/VendorMemory.lua')
    s.load('Inventory/Restock/Auction/FluxAuctionRestockData.lua')
    local A = env.FluxAuctionRestock
    for slot, id in ipairs({ 118, 770001, 770002, 770003, 770004, 770005, 770006 }) do s:set(0, slot, id, 3) end
    if sourceKind == 'syndicator' then s:publish() else s:bags() end
    s:advance(9)
    local btn = s:button('healPotion', true, 'ExtraButtonSystem/CombatGrid/Buttons/HealPotion.lua')
    s:advance(0.4)
    check(A.ExcludesDiscoloredHealing(), 'automatic exclusion defaults on')
    for id = 770001, 770003 do
        check(best.Score.IsExcludedFromBest(id) and A.IsUpgradeBlacklisted(id), 'all name positions, cases and synthetic tiers share exclusion')
        check(not best.Persist.MaybeUpdateRef('healPotion', { itemID = id, effective = 400, source = 'auction' }),
            'excluded AH discoveries cannot ratchet persisted best')
    end
    check(not best.Score.IsExcludedFromBest(770005) and not best.Score.IsExcludedFromBest(770006),
        'the automatic healing rule leaves mana and bandages eligible')
    check(btn.ItemId == 770004 and best.GetBestOwned('healPotion').itemID == 770004,
        'real healing button and owned scanner choose the best permitted potion')
    check(s.bridge.GetOwnedLadder('healPotion')[1].itemID == 770004, 'live bridge ladder excludes stronger blocked potions')
    best.Persist.GetRoot().refs.healPotion = { itemID = 770001, effective = 400 }
    check(not best.GetBestRef('healPotion'), 'old persisted excluded reference is scrubbed')
    best.Persist.RememberVendorItem(770001, { kind = 'healPotion', effective = 400 })
    check(#best.VendorMemory.GetVendorCandidates('healPotion') == 0, 'vendor memories cannot reintroduce an excluded item')
    check(A.SetExcludeDiscoloredHealing(false), 'the automatic rule can be disabled')
    s:advance(0.6)
    check(btn.ItemId == 770001 and best.GetBestOwned('healPotion').itemID == 770001,
        'turning the rule off promotes an owned excluded tier without a bag event')
    local writes = s.writes
    s.combat = true
    check(A.SetExcludeDiscoloredHealing(true), 'combat can save the preference')
    check(not best.GetBest('healPotion'), 'stale runtime answers are suppressed immediately')
    s:advance(0.6)
    check(s.writes == writes and btn.ItemId == 770001, 'combat never changes the protected binding')
    s.combat = false; s:event('PLAYER_REGEN_ENABLED'); s:advance(0.6)
    check(btn.ItemId == 770004, 'regen demotes a previously latched stronger excluded potion')
    check(A.SetUpgradeBlacklisted(770004, true), 'arbitrary per-item exclusions use the same shared service')
    s:advance(0.6)
    check(btn.ItemId == 118 and best.GetBestOwned('healPotion').itemID == 118,
        'manual blacklist demotes to the remaining eligible carried tier')
    check(A.SetExcludeDiscoloredHealing(false) and A.SetUpgradeBlacklisted(770001, true), 'manual exclusions survive automatic opt-out')
    s:advance(0.6)
    check(btn.ItemId == 770002 and best.Score.IsExcludedFromBest(770004) and best.Score.IsExcludedFromBest(770001),
        'automatic opt-out preserves both explicit item exclusions')
    check(A.SetUpgradeBlacklisted(770001, false), 'explicit exclusion can be removed')
    s:advance(0.6)
    check(btn.ItemId == 770001, 'removing the explicit exclusion reconsiders the item immediately')
 end
end
print(('Shared consumable exclusions: %d checks PASS/%d profiles; actual Best, persist, vendor and healing-button owners'):format(checks, profiles))
