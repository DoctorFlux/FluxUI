-- Inline cell decisions wrap the real score/persist/tier/junk/queue owners.
local checks, profiles = 0, 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local export = setmetatable({ FLUX_AH_POTIONS_FIXTURE_EXPORT = true }, { __index = _G })
local fixture = assert(loadfile('tests/auction_restock_potions.lua', 't', export))()
local function buys(s) return (s.calls.quote or 0) + (s.calls.confirm or 0) + (s.calls.buyStack or 0) end
local function boot(legacy, auctionator, syndicator)
    local A, s, env, best = fixture(legacy, auctionator, syndicator)
    s.upgradeChoice = nil
    s.entries[2].target = 0
    s.bags[100], s.money = 19, 0
    local function open() s.emit('AUCTION_HOUSE_SHOW'); A.Toggle(); s.drain() end
    return A, s, env, best, open
end
for _, client in ipairs({ 'Retail', 'Forever', 'MoP', 'Era', 'Anniversary' }) do
 local legacy = client == 'Era' or client == 'Anniversary'
 for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
    profiles = profiles + 1
    local A, s, env, best, open = boot(legacy, auctionator, syndicator)
    open()
    check(A.GetUpgradeProposals()[1] and A.state == 'upgrade' and not A.offer and not A.frame.primary.enabled,
        'a discovered upgrade pauses buying for an explicit decision: ' .. client)
    check(best.GetBestRef('healPotion').itemID == 100 and not s.settings.restockCombat.savedHealPotionTier
        and not A.PotionReplacement(100) and not env.FluxJunk.IsExplicitJunk(100),
        'discovery alone changes neither saved tier, replacement nor real junk owner')
    check(A.Settings().maxUnitPrices[201] == nil and A.Settings().noPriceLimit[201] == nil,
        'the candidate receives no inherited cap/mode before acceptance')
    local tooltipItem, tooltipLines = nil, {}
    env.GameTooltip.SetItemByID = function(_, id) tooltipItem = id end
    env.GameTooltip.AddLine = function(_, text) tooltipLines[#tooltipLines + 1] = text end
    A.frame.cells[1].upgrade.item:Fire('OnEnter')
    check(A.GetUpgradeProposals()[1].sourceID == 100 and A.GetUpgradeProposals()[1].candidate.itemID == 201
        and tooltipItem == 201 and table.concat(tooltipLines, '\n'):find('100 → 600', 1, true)
        and table.concat(tooltipLines, '\n'):find('Available gold:', 1, true)
        and A.GetUpgradeProposals()[1].unitPrice == 80 and env.GetMoney() == 0,
        'the compact tooltip identifies the candidate and displays restore comparison, observed price and current funds')
    A.Primary()
    check(A.GetUpgradeProposals()[1] and buys(s) == 0 and best.GetBestRef('healPotion').itemID == 100,
        'direct primary invocation cannot bypass the pending tier decision')
    s.bags[100] = 20; s.generation = s.generation + 1; s.emit('BAG_UPDATE_DELAYED')
    s.decide(false); s.advance(0); s.drain()
    check(not A.GetUpgradeProposals()[1] and best.GetBestRef('healPotion').itemID == 100 and not A.offer
        and not A.PotionReplacement(100) and not env.FluxJunk.IsExplicitJunk(100) and buys(s) == 0,
        'keeping a full old tier with no money preserves its stock, tier and junk state')
    A.Invalidate('changed'); A.PrepareNext(); s.drain()
    check(not A.GetUpgradeProposals()[1] and not s.popup and A.Settings().maxUnitPrices[201] == nil,
        'ordinary preparation does not nag again or inherit declined candidate settings')
    s.bags[100] = 19; s.generation = s.generation + 1; A.frame:Hide(); A.frame:Show(); s.drain()
    check(A.GetUpgradeProposals()[1] and not s.popup, 'a fresh Restock session permits reconsidering an upgrade')
    s.decide('hide'); s.advance(0); s.drain()
    check(best.GetBestRef('healPotion').itemID == 100 and not env.FluxJunk.IsExplicitJunk(100),
        'dismissal/escape keeps the current tier and never marks it junk')

    A, s, env, best, open = boot(legacy, auctionator, syndicator)
    s.settings.junkList[100] = false
    open()
    local accepted = A.GetUpgradeProposals()[1]
    s.decide(true); s.advance(0); s.drain()
    check(best.GetBestRef('healPotion').itemID == 201 and s.settings.restockCombat.savedHealPotionTier == 600
        and A.PotionReplacement(100) == 201 and not env.FluxJunk.IsExplicitJunk(100) and s.settings.junkList[100] == false,
        'acceptance promotes the tier while preserving explicit Useful and awaiting a carried replacement')
    check(A.GetMaxPrice(201) == 100 and A.IsPriceUnlimited(201) == false and not env.FluxJunk.IsExplicitJunk(101)
        and not env.FluxJunk.IsExplicitJunk(201), 'accepted cap/mode inheritance preserves unrelated items')
    check(A.offer and A.offer.itemID == 201 and A.offer.quantity == 20 and buys(s) == 0,
        'accepting with no funds never buys; weaker stock does not fill the accepted stronger target')
    s.press()
    check(buys(s) == 0 and A.status == 'money', 'the later native purchase still checks available gold')
    A.ResolveUpgrade(accepted, 'upgrade')
    s.advance(0)
    check(buys(s) == 0 and s.tierUpdates == 1, 'duplicate acceptance is idempotent and cannot buy')

    A, s, env, best, open = boot(legacy, auctionator, syndicator)
    s.bags[100] = 19; s.money = 100000
    open(); s.decide(false); s.advance(0); s.drain()
    if legacy then
        check(not A.offer and best.GetBestRef('healPotion').itemID == 100,
            'declining does not silently allow an excess old stack when its setting is off')
    else
        check(A.offer and A.offer.itemID == 100 and A.offer.quantity == 1,
            'declining leaves the ordinary one-item current-tier shortage buyable')
        s.press(); s.emit('COMMODITY_PRICE_UPDATED', 20, 20); s.emit('COMMODITY_PURCHASE_SUCCEEDED'); s.drain()
        check((s.calls.confirm or 0) == 1 and best.GetBestRef('healPotion').itemID == 100
            and not env.FluxJunk.IsExplicitJunk(100), 'one current-tier buy keeps the declined upgrade and junk state unchanged')
    end

    for _, reason in ipairs({ 'close', 'tab', 'combat', 'foreign' }) do
        A, s, env, best, open = boot(legacy, auctionator, syndicator)
        open(); local stale = A.GetUpgradeProposals()[1]
        if reason == 'close' then s.emit('AUCTION_HOUSE_CLOSED')
        elseif reason == 'tab' then A.frame:Hide()
        elseif reason == 'combat' then s.combat = true; s.emit('PLAYER_REGEN_DISABLED')
        else A.Invalidate('otherSearch') end
        check(not A.GetUpgradeProposals()[1], 'invalidating ' .. reason .. ' hides the pending confirmation immediately')
        A.ResolveUpgrade(stale, 'upgrade'); s.advance(0); s.drain()
        check(not A.GetUpgradeProposals()[1] and best.GetBestRef('healPotion').itemID == 100 and not env.FluxJunk.IsExplicitJunk(100)
            and not A.PotionReplacement(100) and buys(s) == 0, 'cancelled/stale ' .. reason .. ' confirmation cannot commit or buy')
    end

    for _, change in ipairs({ 'level', 'restricted', 'cap', 'mode', 'target', 'reference', 'tier-service' }) do
        A, s, env, best, open = boot(legacy, auctionator, syndicator)
        open()
        if change == 'level' then s.level = 1
        elseif change == 'restricted' then s.restricted[201] = true; best.Score.IsKnownUnusable = function(id) return id == 201 end
        elseif change == 'cap' then A.Settings().maxUnitPrices[100] = 0
        elseif change == 'mode' then A.Settings().noPriceLimit[100] = true
        elseif change == 'target' then s.entries[1].target = 0
        elseif change == 'reference' then
            s.bags[200] = 1
            check(best.Persist.MaybeUpdateRef('healPotion', { itemID = 200, effective = 300, source = 'owned' }), 'the stale-reference fixture really changes the persisted reference')
        else env.FluxRestockTiers.ApplyAuctionTierUpgrade = nil end
        s.decide(true); s.advance(0); s.drain()
        check(best.GetBestRef('healPotion').itemID ~= 201 and s.settings.junkList[100] ~= true
            and not A.PotionReplacement(100) and A.Settings().maxUnitPrices[201] == nil and buys(s) == 0,
            'acceptance rechecks mutable ' .. change .. ' before any upgrade or junk mutation')
    end

    A, s, env, best, open = boot(legacy, auctionator, syndicator)
    env.StaticPopup_Show = nil
    open(); s.advance(0); s.drain()
    check(best.GetBestRef('healPotion').itemID == 100 and not env.FluxJunk.IsExplicitJunk(100) and buys(s) == 0,
        'inline confirmation needs no native popup service and cannot promote before a decision')
    env.FluxJunk, env.FluxVendorJunk = nil, nil
    s.decide(true); s.drain()
    check(best.GetBestRef('healPotion').itemID == 201 and s.settings.junkList[100] ~= true and buys(s) == 0,
        'tier acceptance does not require or bypass the separate global junk service')
 end end
end
print(('AH potion confirmation: %d checks PASS/%d client-addon-provider profiles; native inline controls/input tested separately'):format(checks, profiles))
