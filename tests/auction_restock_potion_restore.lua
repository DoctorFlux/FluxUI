-- Real tooltip parser, score/tier/junk owners and native query/decision flow.
local checks, profiles = 0, 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local export = setmetatable({ FLUX_AH_POTIONS_FIXTURE_EXPORT = true }, { __index = _G })
local fixture = assert(loadfile('tests/auction_restock_potions.lua', 't', export))()
local function boot(legacy, auctionator, syndicator, kind)
    local A, s, env, best = fixture(legacy, auctionator, syndicator)
    s.upgradeChoice, s.level = nil, 35
    s.bags[100], s.bags[101] = 20, 20
    s.bags[kind == 'healPotion' and 100 or 101] = 19
    s.entries[kind == 'healPotion' and 2 or 1].target = 0
    s.data[100].amount, s.data[101].amount = 585, 585
    s.data[201].amount, s.data[201].level = 900, 35
    s.data[300].amount, s.data[300].level = 1050, 31
    best.Persist.GetRoot().refs.healPotion.effective = 585
    best.Persist.GetRoot().refs.manaPotion.effective = 585
    for id, data in pairs(s.data) do data.name = 'Restorative ' .. tostring(id) end
    env.FluxItemClass.GetStatic = function() return { classID = 0, subClassID = 1 } end
    env.FluxItemClass.GetTooltipText = function(id)
        local d = s.data[id]; if not d then return end
        if s.missingRestore == id then return 'Requires Level ' .. d.level end
        local text = 'Requires Level ' .. d.level .. '\nUse: Restores ' .. math.floor(d.amount * 0.7) .. ' to ' .. d.amount
            .. (d.kind == 'manaPotion' and ' mana.' or ' health.')
        if id == 201 then text = text .. '\nRestores 400 to 600 mana.\nCooldown 3,600 sec.' end
        if id == 300 then text = text .. '\nRestores 35 to 65 health.\nCooldown 3,600 sec.' end
        return text
    end
    assert(loadfile('Inventory/FluxConsumableClassify.lua', 't', env))('_FluxUI', {})
    local function open()
        s.emit('AUCTION_HOUSE_SHOW'); A.Toggle()
        if not (A.search and A.search.waiting) then s.drain() end
    end
    return A, s, env, best, open
end
for _, client in ipairs({ 'Retail', 'Forever', 'MoP', 'Era', 'Anniversary' }) do
 local legacy = client == 'Era' or client == 'Anniversary'
 for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
    profiles = profiles + 1
    local A, s, env, best, open = boot(legacy, auctionator, syndicator, 'healPotion')
    local cls = env.FluxConsumableClassify.Classify(201)
    check(cls and cls.health == 630 and cls.mana == 400 and cls.effective == 630
        and cls.healthMax == 900 and cls.manaMax == 600 and cls.restoreKnown,
        'ranged health and mana are independent; cooldown/level numbers cannot inflate the tier: ' .. client)
    s.level = 34; open()
    check(not A.GetUpgradeProposals()[1] and best.GetBestRef('healPotion').itemID == 100 and not env.FluxJunk.IsExplicitJunk(100),
        'the next level35 health tier is not offered at level34')
    s.level = 35; A.PrepareNext(true); s.drain()
    check(A.GetUpgradeProposals()[1] and best.GetBestRef('healPotion').itemID == 100 and A.state == 'upgrade',
        'level35 discovers the stronger listed restorative without a potion name or tier list, then asks')
    s.decide(true); s.advance(0); s.drain()
    check(best.GetBestRef('healPotion').itemID == 201 and s.settings.restockCombat.savedHealPotionTier == 630
        and not env.FluxJunk.IsExplicitJunk(100) and A.offer and A.offer.quantity == 20,
        'acceptance saves the630-minimum-health tier without marking an undelivered replacement as junk')
    check(not s.calls.quote and not s.calls.confirm and not s.calls.buyStack, 'discovery and acceptance never submit a purchase')

    A, s, env, best, open = boot(legacy, auctionator, syndicator, 'manaPotion')
    cls = env.FluxConsumableClassify.Classify(300)
    check(cls and cls.health == 35 and cls.mana == 735 and cls.manaMax == 1050 and cls.kind == 'manaPotion' and cls.effective == 735,
        'mana ranking uses its735-minimum axis rather than health, maximum roll or cooldown digits')
    open()
    check(A.GetUpgradeProposals()[1] and best.GetBestRef('manaPotion').itemID == 101 and not env.FluxJunk.IsExplicitJunk(101),
        'a stronger mana listing also waits for its separate choice')
    s.decide(false); s.advance(0); s.drain()
    check(best.GetBestRef('manaPotion').itemID == 101 and not env.FluxJunk.IsExplicitJunk(101),
        'declining a real-parser mana upgrade leaves the current tier and junk state intact')

    A, s, env, best, open = boot(legacy, auctionator, syndicator, 'manaPotion')
    s.missingRestore, s.spellRequests = 300, 0
    s.flux.Item = { GetSpell = function(id) if id == 300 then return 'Restorative effect', 98765 end end }
    env.C_Spell = { RequestLoadSpellData = function(id)
        check(id == 98765, 'only the dynamically linked item spell is requested')
        s.spellRequests = s.spellRequests + 1; s.missingRestore = nil
    end }
    open()
    check(s.spellRequests == 1 and A.GetUpgradeProposals()[1] and best.GetBestRef('manaPotion').itemID == 101,
        'metadata-ready item with only a required-level tooltip loads its linked restore spell once, then asks')
    s.decide(true); s.advance(0); s.drain()
    check(best.GetBestRef('manaPotion').itemID == 300 and s.settings.restockCombat.savedManaPotionTier == 735
        and not env.FluxJunk.IsExplicitJunk(101) and not s.calls.quote and not s.calls.buyStack,
        'resolved native spell text can establish the stronger mana tier only after acceptance')

    A, s, env, best, open = boot(legacy, auctionator, syndicator, 'manaPotion')
    s.missingRestore, s.spellRequests = 300, 0
    s.flux.Item = { GetSpell = function(id) if id == 300 then return 'Restorative effect', 98765 end end }
    env.C_Spell = {
        RequestLoadSpellData = function() s.spellRequests = s.spellRequests + 1; s.spellReadyAt = s.time + 2 end,
        GetSpellDescription = function()
            if s.spellReadyAt and s.time >= s.spellReadyAt then
                s.missingRestore = nil; return 'Restores 735 to 1050 mana.'
            end
        end,
    }
    open()
    check(s.spellRequests == 1 and A.GetUpgradeProposals()[1] and best.GetBestRef('manaPotion').itemID == 101,
        'a slow linked spell revives a name-free negative parse once and still asks before upgrading')

    A, s, env, best, open = boot(legacy, auctionator, syndicator, 'healPotion')
    s.data[400] = { name = 'Restorative 400', amount = 0, level = 1 }
    local tooltip = env.FluxItemClass.GetTooltipText
    env.FluxItemClass.GetTooltipText = function(id)
        if id == 400 then return 'Use: Increases movement speed by 50 percent for 15 seconds. Requires Level 1.' end
        return tooltip(id)
    end
    local loads = 0
    env.FluxItemClass.RequestLoad = function(id)
        if id == 400 then loads = loads + 1; env.FluxConsumableClassify.InvalidateCache(id) end
    end
    local listed = s.potionCatalog['healing potion']
    listed.browse[#listed.browse + 1] = { itemKey = env.C_AuctionHouse.MakeItemKey(400), totalQuantity = 20, minPrice = 1 }
    listed.offers[#listed.offers + 1] = { itemID = 400, quantity = 20, total = 20 }
    open()
    check(loads == 0 and A.GetUpgradeProposals()[1] and not A.HasBlockedPotionTargets() and best.GetBestRef('healPotion').itemID == 100,
        'loaded non-restorative catalogue entry settles without duplicate metadata events resetting its retries')
    check(not s.calls.quote and not s.calls.buyStack and not env.FluxJunk.IsExplicitJunk(100),
        'utility rejection leaves the verified restorative upgrade awaiting an explicit decision')

    if not legacy then
        A, s, env, best, open = boot(false, auctionator, syndicator, 'healPotion')
        s.potionCatalog[''] = s.potionCatalog['healing potion']
        s.potionCatalog['healing potion'] = { browse = {}, offers = {} }
        open()
        check(s.calls.potionBrowse == 2 and s.browseTerm == '' and A.GetUpgradeProposals()[1] and A.state == 'upgrade',
            'an empty phrase result gets exactly one potion-category fallback with no item-name query')
        check(best.GetBestRef('healPotion').itemID == 100 and not env.FluxJunk.IsExplicitJunk(100),
            'category fallback still cannot upgrade or mark junk without a choice')

        A, s, env, best, open = boot(false, auctionator, syndicator, 'healPotion')
        s.throttle = false; open()
        check(A.search and A.search.waiting and not A.search.nativeGeneration and A.status == 'auctionWaiting'
            and not s.calls.potionBrowse, 'unready native queue is displayed and owns no result generation')
        s.emit('AUCTION_HOUSE_BROWSE_RESULTS_UPDATED'); s.emit('AUCTION_HOUSE_BROWSE_RESULTS_ADDED', {})
        check(A.search and A.search.waiting and not A.GetUpgradeProposals()[1] and not s.calls.potionBrowse,
            'late browse events cannot publish an empty catalogue for an unsent request')
        s.throttle = true; s.emit('AUCTION_HOUSE_THROTTLED_SYSTEM_READY')
        check(s.calls.potionBrowse == 1 and not A.search.waiting, 'native ready wakes the queued query immediately')
        s.drain(); local queried = s.calls.potionBrowse
        s.emit('AUCTION_HOUSE_THROTTLED_SYSTEM_READY')
        check(A.GetUpgradeProposals()[1] and s.calls.potionBrowse == queried and best.GetBestRef('healPotion').itemID == 100,
            'a repeated ready event does not resend a live query or skip its upgrade confirmation')

        A, s, env, best, open = boot(false, auctionator, syndicator, 'healPotion')
        s.throttle = false; open(); s.advance(16)
        check(A.state == 'idle' and A.status == 'auctionNotReady' and not s.calls.potionBrowse and not A.GetUpgradeProposals()[1],
            'native unavailability expires as unready, rather than no potions or a fabricated offer')
        check(best.GetBestRef('healPotion').itemID == 100 and not env.FluxJunk.IsExplicitJunk(100),
            'an unavailable native queue never changes current tier or junk')
        s.throttle = true; A.PrepareNext(true); s.drain()
        check(A.GetUpgradeProposals()[1] and s.calls.potionBrowse == 1, 'retry after real readiness has no cached synthetic empty result')
    end
 end end
end
print(('AH potion restore/browse: %d checks PASS/%d profiles; native server availability tested separately'):format(checks, profiles))
