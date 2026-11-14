-- Tab opening scans shortages only; explicit restocking discovers usable upgrades.
local checks, profiles = 0, 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local export = setmetatable({ FLUX_AH_POTIONS_FIXTURE_EXPORT = true }, { __index = _G })
local fixture = assert(loadfile('tests/auction_restock_potions.lua', 't', export))()
local function open(A, s) s.emit('AUCTION_HOUSE_SHOW'); A.Toggle(); s.drain() end
local function buys(s) return (s.calls.confirm or 0) + (s.calls.buyStack or 0) end
local function ack(s, legacy, unit)
    if legacy then s.legacyReceipt()
    else s.emit('COMMODITY_PRICE_UPDATED', unit, unit * 20); s.emit('COMMODITY_PURCHASE_SUCCEEDED') end
    s.drain()
end
for _, client in ipairs({ 'Retail', 'Forever', 'MoP', 'Era', 'Anniversary' }) do
 local legacy = client == 'Era' or client == 'Anniversary'
 for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
    profiles = profiles + 1
    local A, s, env, best = fixture(legacy, auctionator, syndicator)
    s.bags[100], s.bags[101] = 20, 20
    open(A, s)
    check(not A.offer and not s.calls.potionBrowse and not s.calls.legacyPotionSearch,
        'opening with filled potion targets does not scan for upgrades: ' .. client)
    s.bags[100], s.bags[101], s.generation = 19, 19, s.generation + 1
    s.emit('BAG_UPDATE_DELAYED'); s.drain()
    check(not s.calls.potionBrowse and not s.calls.legacyPotionSearch,
        'a new shortage updates counts without restarting an idle queue')
    s.press(); s.drain()
    check(A.offer and A.offer.itemID == 201 and A.offer.quantity == 20,
        'starting a missing weaker target prepares the complete stronger usable target: ' .. client)
    check(best.GetBestRef('healPotion').itemID == 201 and s.settings.restockCombat.savedHealPotionTier == 600,
        'automatic per-item discovery updates the persisted healing tier')
    check(best.GetBestRef('manaPotion').itemID == 300 and (s.calls.potionBrowse or s.calls.legacyPotionSearch) == 2,
        'the independent mana choice is gathered alongside healing without bulk restock pricing')
    check(not s.searchedIDs[202] and not s.searchedIDs[203] and not s.searchedIDs[205] and not s.searchedIDs[302]
        and buys(s) == 0, 'unusable, over-limit, non-discount vendor and restricted tiers cannot be bought')
    local searches = s.calls.potionBrowse or s.calls.legacyPotionSearch
    A.Invalidate('changed'); A.PrepareNext(); s.drain()
    check((s.calls.potionBrowse or s.calls.legacyPotionSearch) == searches and buys(s) == 0,
        'unchanged preparation reuses the fresh per-kind catalogue without spending')
    s.press(); ack(s, legacy, 80)
    check(buys(s) == 1 and A.offer and A.offer.itemID == 300 and A.offer.quantity == 20
        and best.GetBestRef('manaPotion').itemID == 300 and s.settings.restockCombat.savedManaPotionTier == 500,
        'one healing buy prepares the next missing stronger mana tier')
    s.press(); ack(s, legacy, 70)
    check(buys(s) == 2, 'each upgraded potion purchase still requires its own physical press')
    s.bags[201], s.bags[300], s.generation = 20, 20, s.generation + 1
    A.Settings().pending = {}; A.Invalidate('changed'); A.PrepareNext(); s.drain()
    check(not A.offer, 'a filled best usable tier does not buy more of itself')
    s.level = 60
    s.bags[201], s.generation = 19, s.generation + 1
    A.PrepareNext(true); s.drain()
    check(best.GetBestRef('healPotion').itemID == 202 and s.settings.restockCombat.savedHealPotionTier == 900
        and A.offer and A.offer.itemID == 202 and A.offer.quantity == 20,
        'new character eligibility invalidates the fresh old-level catalogue and advances the tier')
    check(buys(s) == 2, 'level-based tier discovery never authorizes an automatic purchase')

    A, s, env, best = fixture(legacy, auctionator, syndicator)
    s.entries[1].target, s.entries[2].target = 0, 0
    open(A, s)
    check(not s.calls.potionBrowse and not s.calls.legacyPotionSearch and not A.offer,
        'disabled potion targets do not launch upgrade scans')

    A, s, env, best = fixture(legacy, auctionator, syndicator)
    s.bags[100], s.bags[101] = 20, 20
    A.SetMaxPrice(100, 0, false); A.SetMaxPrice(101, 0, false)
    open(A, s)
    check(not A.offer and best.GetBestRef('healPotion').itemID == 100 and best.GetBestRef('manaPotion').itemID == 101,
        'a limited zero still refuses paid upgrades even when the old target is full')
 end end
end
print(('AH usable potion upgrades: %d checks PASS/%d client-addon-provider profiles; native scanning/tier UI NOT RUN'):format(checks, profiles))
