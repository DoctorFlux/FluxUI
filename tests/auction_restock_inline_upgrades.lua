-- Exercise independent cell choices through the actual UI and shared tier/junk services.
local checks, profiles = 0, 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local export = setmetatable({ FLUX_AH_POTIONS_FIXTURE_EXPORT = true }, { __index = _G })
local fixture = assert(loadfile('tests/auction_restock_potions.lua', 't', export))()
local function boot(legacy, auctionator, syndicator)
    local A, s, env, best = fixture(legacy, auctionator, syndicator)
    s.upgradeChoice, s.bags[100], s.bags[101], s.bags[400] = nil, 19, 19, 19
    A.SetUpgradeEnabled('bandage', true) -- This regression explicitly exercises all three enabled types.
    s.data[400] = { name = 'Dressing A', kind = 'bandage', amount = 100, level = 1 }
    s.data[401] = { name = 'Dressing B', kind = 'bandage', amount = 300, level = 20 }
    s.data[402] = { name = 'Dressing C', kind = 'bandage', amount = 900, level = 20 }
    s.data[403] = { name = 'Dressing D', kind = 'bandage', amount = 1000, level = 60 }
    s.restricted[402] = true
    s.entries[3] = { isTierRestock = true, tierKind = 'bandage', target = 20, name = 'Dressings' }
    check(best.Persist.MaybeUpdateRef('bandage', { itemID = 400, effective = 100, source = 'owned' }), 'fixture has a real bandage reference')
    A.SetMaxPrice(400, 100)
    local browse, offers = {}, {}
    for id = 400, 403 do
        s.itemIDsByName[s.data[id].name] = id
        s.books[id] = { commodity = not legacy, offers = legacy
            and { { itemID = id, quantity = 20, total = 1200 } }
            or { { itemID = id, quantity = 20, unitPrice = 60, numOwnerItems = 0 } } }
        browse[#browse + 1] = { itemKey = env.C_AuctionHouse.MakeItemKey(id), totalQuantity = 20, minPrice = 60 }
        offers[#offers + 1] = { itemID = id, quantity = 20, total = 1200 }
    end
    s.potionCatalog.bandage = { browse = browse, offers = offers }
    local function open() s.emit('AUCTION_HOUSE_SHOW'); A.Toggle(); s.drain() end
    local function find(kind)
        for _, cell in ipairs(A.frame.cells) do
            local card = cell.upgrade
            if card and card.proposal and card.proposal.kind == kind then return card, card.proposal, cell end
        end
    end
    return A, s, env, best, open, find
end
local function noBuys(s) return not s.calls.quote and not s.calls.confirm and not s.calls.buyStack end
for _, client in ipairs({ 'Retail', 'Forever', 'MoP', 'Era', 'Anniversary' }) do
 local legacy = client == 'Era' or client == 'Anniversary'
 for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
    profiles = profiles + 1
    local A, s, env, best, open, find = boot(legacy, auctionator, syndicator)
    open()
    check(#A.GetUpgradeProposals() == 3 and A.state == 'upgrade' and not s.popup and not s.popupShows,
        'healing, mana and bandage choices coexist in cells without a modal popup: ' .. client)
    for _, kind in ipairs({ 'healPotion', 'manaPotion', 'bandage' }) do
        local card, proposal, cell = find(kind)
        check(card and card:IsShown() and card.upgrade:IsEnabled() and card.keep:IsEnabled() and card.blacklist:IsEnabled(),
            'each kind owns three reachable ordinary cell actions')
        check(card.icon.texture == proposal.candidate.itemID and cell.upgradeHeight > 0 and card:GetHeight() <= 48,
            'each cell has a compact candidate icon and independent actions')
        local item, lines
        env.GameTooltip.SetItemByID = function(_, id) item, lines = id, {} end
        env.GameTooltip.AddLine = function(_, text) lines[#lines + 1] = text end
        card.item:Fire('OnEnter')
        check(item == proposal.candidate.itemID and table.concat(lines, '\n'):find(('%.0f → %.0f'):format(proposal.previousRestore, proposal.candidate.effective), 1, true)
            and table.concat(lines, '\n'):find('per item', 1, true),
            'candidate tooltip retains the correct restore comparison and price without tall grid text')
        card.keep:Fire('OnEnter')
        check(table.concat(lines, '\n'):find('Keep current', 1, true), 'compact Keep action exposes its full meaning on hover')
    end
    check(best.GetBestRef('bandage').itemID == 400 and best.GetBestRef('healPotion').itemID == 100
        and best.GetBestRef('manaPotion').itemID == 101 and noBuys(s), 'collecting all choices never commits or buys')
    check(not s.searchedIDs[402] and not s.searchedIDs[403], 'bandages obey First Aid/class and level restrictions before offer pricing')
    local _, stale = find('bandage')
    s.decide(true, 'bandage'); s.drain()
    check(best.GetBestRef('bandage').itemID == 401 and s.settings.restockCombat.savedBandageTier == 300
        and not env.FluxJunk.IsExplicitJunk(400) and #A.GetUpgradeProposals() == 2,
        'one bandage press commits its saved tier without creating a premature explicit junk mark')
    check(best.GetBestRef('healPotion').itemID == 100 and best.GetBestRef('manaPotion').itemID == 101
        and A.state == 'upgrade' and noBuys(s), 'accepting bandages leaves both potion choices pending and does not purchase')
    check(not A.ResolveUpgrade(stale, 'upgrade'), 'a resolved cell action is idempotent')
    s.decide('blacklist', 'healPotion'); s.drain()
    local card, proposed = find('healPotion')
    check(A.IsUpgradeBlacklisted(201) and proposed.candidate.itemID == 200 and #A.GetUpgradeProposals() == 2,
        'blacklisting one unwanted item offers the next eligible restorative while preserving mana')
    check(best.GetBestRef('healPotion').itemID == 100 and not env.FluxJunk.IsExplicitJunk(201)
        and not env.FluxJunk.IsExplicitJunk(100) and noBuys(s), 'blacklist changes neither current tier nor junk and never buys')
    s.decide(false, 'manaPotion'); s.drain()
    check(#A.GetUpgradeProposals() == 1 and best.GetBestRef('manaPotion').itemID == 101
        and not env.FluxJunk.IsExplicitJunk(101), 'keeping mana resolves only its own cell')
    s.bags[101] = 20; s.generation = s.generation + 1; s.emit('BAG_UPDATE_DELAYED') -- A carried refill must not restart the remaining choice.
    s.decide(true, 'healPotion'); s.drain()
    check(#A.GetUpgradeProposals() == 0 and best.GetBestRef('healPotion').itemID == 200
        and A.offer and (A.offer.itemID == 200 or A.offer.itemID == 401) and A.offer.quantity == 20 and noBuys(s),
        ('after individual choices the next purchase still needs a separate player press: %s proposals=%d ref=%s offer=%s quantity=%s state=%s status=%s')
            :format(client, #A.GetUpgradeProposals(), tostring(best.GetBestRef('healPotion').itemID), tostring(A.offer and A.offer.itemID),
                tostring(A.offer and A.offer.quantity), A.state, A.status))
    check(A.GetMaxPrice(401) == 100 and not A.IsPriceUnlimited(401), 'accepted bandage inherits its source unit-price policy')
    local first, total, unit = A.offer.itemID, A.offer.total, A.offer.total / A.offer.quantity
    s.press()
    if legacy then s.legacyReceipt() else s.emit('COMMODITY_PRICE_UPDATED', unit, total); s.emit('COMMODITY_PURCHASE_SUCCEEDED') end
    s.drain()
    check(A.offer and A.offer.itemID == (first == 200 and 401 or 200) and (s.calls.confirm or s.calls.buyStack) == 1,
        'one accepted-tier purchase prepares the other item and cannot purchase it automatically')

    A, s, env, best, open, find = boot(legacy, auctionator, syndicator)
    check(A.SetUpgradeBlacklisted('|cff00ff00|Hitem:201:0|h[Unwanted]|h|r', true), 'an arbitrary item link can be excluded before scanning')
    open()
    check(select(2, find('healPotion')).candidate.itemID == 200 and #A.GetUpgradeProposals() == 3,
        'saved item exclusion filters discovery without hiding other kinds')
    A.frame:Hide(); A.frame:Show(); s.drain()
    check(A.IsUpgradeBlacklisted(201) and select(2, find('healPotion')).candidate.itemID == 200,
        'blacklist persists across Restock sessions')
    local namespace = { Flux = s.flux }
    assert(loadfile('Inventory/Restock/Auction/FluxAuctionRestockLocale.lua', 't', env))('_FluxUI', namespace)
    local build
    env.FluxOptions = { RegisterModuleOptions = function(_, key, fn) if key == 'vendor' then build = fn end end }
    assert(loadfile('AddonOptions/FluxOptionsVendor.lua', 't', env))('_FluxUI', namespace)
    local controls = {}
    local function walk(node)
        for key, child in pairs(node.args or {}) do controls[key] = child; walk(child) end
    end
    walk(build())
    local add, list = controls.auctionUpgradeBlacklistAdd, controls.auctionUpgradeBlacklist
    check(controls.auctionExcludeDiscolored and controls.auctionExcludeDiscolored.get(),
        'the real restock options expose a default-on automatic Discolored healing exclusion')
    controls.auctionExcludeDiscolored.set(nil, false)
    check(not A.ExcludesDiscoloredHealing() and A.IsUpgradeBlacklisted(201),
        'automatic opt-out does not clear the explicit blacklist')
    controls.auctionExcludeDiscolored.set(nil, true)
    check(controls.keepWeaker_bandage.get() and controls.keepWeaker_healPotion.get() and controls.keepWeaker_manaPotion.get(),
        'global bandage/healing/mana protection defaults on in the real registered settings')
    controls.keepWeaker_bandage.set(nil, false)
    check(not controls.keepWeaker_bandage.get() and controls.keepWeaker_healPotion.get() and controls.keepWeaker_manaPotion.get(),
        'global protection is independently configurable for each consumable kind')
    controls.keepWeaker_bandage.set(nil, true)
    check(add and list and list.values()[201] and list.get(nil, 201), 'real registered addon settings expose saved exclusions')
    check(add.validate(nil, '0') ~= true and add.validate(nil, 'not an item') ~= true and add.validate(nil, '201') == true,
        'settings validate item IDs rather than hardcoded names')
    list.set(nil, 201, false); s.drain()
    check(not A.IsUpgradeBlacklisted(201) and select(2, find('healPotion')).candidate.itemID == 201,
        'removing an exclusion in real options reconsiders that item')
    local _, pending = find('healPotion')
    s.combat = true; s.emit('PLAYER_REGEN_DISABLED')
    check(#A.GetUpgradeProposals() == 0 and not A.ResolveUpgrade(pending, 'upgrade')
        and best.GetBestRef('healPotion').itemID == 100 and noBuys(s), 'combat cancels all independent proposals and stale controls cannot commit')

    A, s, env, best, open, find = boot(legacy, auctionator, syndicator)
    best.Persist.GetRoot().refs.bandage = nil; s.bags[400] = 0
    s.entries[#s.entries + 1] = { itemID = 690, name = 'AA configured consumable', target = 1, restockSource = 'consumable' }
    open()
    local _, proposal, cell = find('bandage')
    check(proposal and not proposal.sourceID and cell.row.upgradeOnly and #A.GetUpgradeProposals() == 3,
        'an unremembered bandage tier still has its own inline choice alongside both potions')
    check(A.frame.cells[1].row.tierKind == 'healPotion' and A.frame.cells[2].row.tierKind == 'manaPotion'
        and A.frame.cells[3] == cell, 'virtual preset upgrade rows retain potion-then-bandage order')
    check(A.Settings().maxUnitPrices[401] == nil and A.Settings().noPriceLimit[401] == nil,
        'painting an unremembered candidate does not inherit or create candidate price policy')

    A, s, env, best, open, find = boot(legacy, auctionator, syndicator)
    s.entries = { s.entries[3] }; best.Persist.GetRoot().refs.bandage = nil; s.bags[400] = 0
    local ic = env.FluxItemClass
    ic.GetStatic = function(id) return { classID = 0, subClassID = ic.GetSubClassID(id) } end
    ic.GetTooltipText = function(id)
        local data = s.data[id]; if not data then return end
        return 'Requires Level ' .. data.level .. '\nUse: Heals ' .. data.amount .. ' damage over 8 sec.'
    end
    assert(loadfile('Inventory/FluxConsumableClassify.lua', 't', env))('_FluxUI', {})
    open()
    local _, real = find('bandage')
    check(real and real.candidate.itemID == 401 and real.candidate.effective == 300 and real.kind == 'bandage',
        'real parser recognizes bandage healing from its subclass and effect without a bandage item name')
    check(not A.frame.currencyGroup.itemID and A.Settings().maxUnitPrices[401] == nil and A.Settings().noPriceLimit[401] == nil,
        'a lone unremembered bandage suggestion cannot create candidate price settings through the editor')

    A, s, env, best, open, find = boot(legacy, auctionator, syndicator)
    s.data[201].name = 'A dIsCoLoReD healing restorative'
    s.itemIDsByName[s.data[201].name] = 201
    open()
    check(select(2, find('healPotion')).candidate.itemID == 200,
        'the automatic substring rule excludes an AH candidate without a fixed tier name or ID')
    A.SetExcludeDiscoloredHealing(false); s.drain()
    check(select(2, find('healPotion')).candidate.itemID == 201,
        'disabling the automatic rule reconsiders the stronger candidate but still asks first: ' .. client)
    check(noBuys(s) and best.GetBestRef('healPotion').itemID == 100,
        'changing automatic exclusions never accepts an upgrade or buys it')

    A, s, env, best = boot(legacy, auctionator, syndicator)
    s.data[201].name = 'Another discolored restorative'
    s.bags[201], s.bags[100] = 1, 1
    check(env.FluxRestockTiers.GetJunkReferenceTier('healPotion', nil, 100) == 0,
        'an excluded carried healing potion cannot make the remaining permitted tier automatic junk')
    A.SetExcludeDiscoloredHealing(false)
    check(env.FluxRestockTiers.GetJunkReferenceTier('healPotion', nil, 100) == 600,
        'automatic opt-out immediately restores the ordinary carried-upgrade comparison')

    A, s, env, best, open, find = boot(legacy, auctionator, syndicator)
    -- Deliberately interleave names and sources. A manual target sharing the
    -- healing reference must still occupy its preset's first position.
    s.entries[#s.entries + 1] = { itemID = 100, name = 'ZZ manual potion', target = 20, restockSource = 'manual' }
    s.entries[#s.entries + 1] = { itemID = 620, name = 'AA other', target = 1, restockSource = 'manual' }
    s.entries[#s.entries + 1] = { itemID = 621, name = 'ZZ reagent', target = 1, restockSource = 'spellReagent' }
    s.entries[#s.entries + 1] = { itemID = 622, name = 'AA consumable', target = 1, restockSource = 'consumable' }
    s.entries[#s.entries + 1] = { itemID = 623, name = 'AA reagent', target = 1, restockSource = 'spellReagent' }
    s.entries[#s.entries + 1] = { itemID = 624, name = 'AA other', target = 1, restockSource = 'manual' }
    open()
    local expected = { 100, 101, 400, 623, 621, 622, 620, 624 }
    for i, id in ipairs(expected) do
        check(A.GetRows(false)[i].itemID == id and A.frame.cells[i].row.itemID == id,
            'real targets and cells keep preset/source order, then name/ID within each group')
    end
    local _, healProposal, healCell = find('healPotion')
    check(healCell == A.frame.cells[1] and healProposal.sourceID == 100 and not healCell.row.isTierRestock,
        'merged manual/preset rows keep their own proposal after sorting')
 end end
end
print(('AH inline upgrades: %d checks PASS/%d profiles; independent cells, bandages, blacklist, options and real purchase owners'):format(checks, profiles))
