-- lua Inventory/Restock/Junk/_tmp_junksmoke.lua
-- Runs actual container compatibility, restock facade, classifier and seller.
-- The simulated merchant acknowledges sales asynchronously and rejects repeats.
-- This tests dispatch/state; WoW's protected execution still needs live testing.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../../../"
local function Load(path, env, ns)
    local f
    if setfenv then f = assert(loadfile(root .. path)); setfenv(f, env)
    else f = assert(loadfile(root .. path, "t", env)) end
    return f("_FluxUI", ns)
end
local function Boot(family, opts)
    opts = opts or {}
    local now, money, merchant, cursor = 10, 0, true, false
    local timers, bags, facts, hidden, calls, pending, errors, gear = {}, {}, {}, {}, {}, {}, {}, {}
    local ids = { 0, 1, 2, 3, 4 }
    local hasReagent = family == "live" or family == "forever"
    local modern = hasReagent or opts.modern
    if hasReagent then ids[#ids + 1] = 5 end
    for _, bag in ipairs(ids) do bags[bag] = {} end
    local function After(delay, fn) timers[#timers + 1] = { at = now + delay, fn = fn } end
    local settings = { junkList = {}, restockItems = {}, junkFilters = { safe = opts.safe ~= false, destroy = false } }
    local env = setmetatable({
        Enum = { ItemClass = { Weapon = 2, Armor = 4, Consumable = 0, Miscellaneous = 15 },
            ItemMiscellaneousSubclass = { CompanionPet = 2, Mount = 5 }, ItemWeaponSubclass = { Fishingpole = 20 },
            ItemBind = { OnEquip = 2 } },
        GetTime = function() return now end, GetMoney = function() return money end,
        UnitLevel = function() return 10 end,
        MerchantFrame = { IsShown = function() return merchant end },
        C_Timer = { After = After },
        FluxRestockSettings = { Get = function() return settings end },
        FluxVendorAuto = { AddBatchCopper = function(copper) assert(copper > 0) end },
        CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end,
        wipe = function(t) for k in pairs(t) do t[k] = nil end end,
        CursorHasItem = function() return cursor end,
        PickupMerchantItem = function() error("seller used a second cursor sale") end,
        ClearCursor = function() error("seller cleared the player's cursor") end,
        DeleteCursorItem = function() error("unknown item was destroyed") end,
        C_MerchantFrame = modern and { SellAllJunkItems = function() error("native bulk sale raced pending sales") end } or nil,
    }, { __index = _G })
    env._G = env
    local inventory = { Containers = {
        GetCarriedBagIDs = function() return ids end,
        IsKeyringBag = function(bag) return bag == -2 end,
        IsReagentBank = function(bag) return bag == -3 end,
        IsBankContainer = function() return false end,
    }, GetBagGeneration = function() return 1 end,
        GetCount = function(id)
            local count = 0
            for _, slots in pairs(bags) do for _, item in pairs(slots) do
                if item.itemID == id then count = count + item.count end
            end end
            return count
        end }
    local ns = { Flux = { Inventory = inventory, Client = { isForever = family == "forever", isLiveMidnight = family == "live" } } }
    env.Flux = ns.Flux
    env.FluxRespec = { GearSetLock = {
        IsSlotProtected = function(bag, slot) return gear[bag .. "_" .. slot] end,
        ShouldBlockContainerUse = function(bag, slot) return gear[bag .. "_" .. slot] end,
    } }
    local function Info(bag, slot)
        local item = bags[bag] and bags[bag][slot]
        if not item then return nil end
        return { itemID = item.itemID, stackCount = item.count, isLocked = item.locked or false,
            quality = facts[item.itemID].quality, hasNoValue = facts[item.itemID].sellPrice == 0,
            hyperlink = "item:" .. item.itemID }
    end
    local busyNext = opts.busyOnce
    local function Use(bag, slot)
        local item = bags[bag] and bags[bag][slot]
        local key = bag .. "_" .. slot
        if not item or pending[key] then errors[#errors + 1] = "item not owned or duplicate " .. key; return end
        calls[#calls + 1] = { bag = bag, slot = slot, itemID = item.itemID, at = now }
        if busyNext then
            busyNext = false
            env.FluxSellJunk.OnMerchantBusy()
            return
        end
        if opts.noopOnce and #calls == 1 then return end
        pending[key], item.locked = true, not opts.noLock
        local function Ack()
            assert(bags[bag][slot] == item, "test moved a stack with an in-flight sale")
            money = money + facts[item.itemID].sellPrice * item.count
            bags[bag][slot], pending[key] = nil, nil
            env.FluxSellJunk.ContinueIfNeeded()
        end
        if opts.immediate then Ack() else After(opts.latency or 0.35, Ack) end
    end
    env.GetContainerNumSlots = function() return 90 end
    if modern or opts.namespacedInfo then
        env.C_Container = {
            GetContainerNumSlots = env.GetContainerNumSlots,
            GetContainerItemInfo = Info,
            GetContainerItemID = function(bag, slot) local i = Info(bag, slot); return i and i.itemID end,
            UseContainerItem = modern and Use or nil,
        }
    end
    env.GetContainerItemInfo = function(bag, slot)
        local i = Info(bag, slot)
        if i then
            local noValue = i.hasNoValue
            if opts.legacyNoValueAbsent then noValue = nil end
            return 123, i.stackCount, i.isLocked, i.quality, nil, nil, i.hyperlink, false, noValue, i.itemID
        end
    end
    env.UseContainerItem = Use
    env.FluxItemClass = {
        GetInfo = function(id) if not hidden[id] then return facts[id] end end,
        GetName = function(id) return facts[id] and facts[id].name end,
        GetQuality = function(id) return not hidden[id] and facts[id] and facts[id].quality or nil end,
        GetSellPrice = function(id) return not hidden[id] and facts[id] and facts[id].sellPrice or 0 end,
    }
    Load("Core/API/Container.lua", env, ns)
    Load("Inventory/Restock/FluxRestock_Inv.lua", env, ns)
    Load("Inventory/Restock/Junk/FluxJunk.lua", env, ns)
    Load("Inventory/Restock/Junk/FluxSellJunk.lua", env, ns)
    local sj, fj = env.FluxSellJunk, env.FluxVendorJunk
    local function Advance(seconds)
        local target = now + seconds
        for _ = 1, 10000 do
            local idx, first
            for i, t in ipairs(timers) do if t.at <= target and (not first or t.at < first.at) then idx, first = i, t end end
            if not idx then now = target; return end
            table.remove(timers, idx); now = first.at; first.fn()
        end
        error("timer loop failed to settle")
    end
    local function Add(slot, id, attrs, bag)
        bag = bag or 0
        local info = { name = "Gray " .. id, quality = 0, sellPrice = 5, classID = 4,
            subClassID = 0, equipLoc = "INVTYPE_SHOULDER", itemLevel = 1, bindType = 2 }
        for k, v in pairs(attrs or {}) do info[k] = v end
        facts[id] = info
        bags[bag][slot] = { itemID = id, count = 2 }
        return bags[bag][slot]
    end
    return { sj = sj, fj = fj, inv = env.FluxRestock.Inv, env = env, ns = ns, settings = settings,
        calls = calls, errors = errors, bags = bags, hidden = hidden, facts = facts, gear = gear,
        add = Add, advance = Advance,
        close = function() merchant = false; sj.OnMerchantClosed() end,
        cursor = function(value) cursor = value end }
end

for _, family in ipairs({ "live", "forever", "era", "anniversary", "mists" }) do
    local t = Boot(family)
    for slot = 1, 65 do t.add(slot, 200000 + slot) end
    t.add(66, 200066, { quality = 2 }); t.settings.junkList[200066] = true
    t.add(67, 200067); t.settings.junkList[200067] = false
    t.add(68, 200068); t.settings.restockItems[200068] = { targetQuantity = 10 }
    t.add(69, 200069); t.gear['0_69'] = true
    t.add(70, 200070, { name = "Conjured Water", classID = 0 })
    t.add(71, 200071, { sellPrice = 0 })
    t.add(72, 200072); t.hidden[200072] = true
    t.facts[200002].equipLoc = "INVTYPE_BODY"
    t.facts[200003].classID, t.facts[200003].subClassID = 2, 20
    assert(t.fj.IsJunk(200002) and t.fj.IsJunk(200003), "gray shirt/fishing gear was excluded")
    local reagentItem = family == "live" or family == "forever"
    if reagentItem then t.add(1, 200100, nil, 5) end
    assert(t.fj.IsJunk(200001) and t.fj.IsJunkForDisplay(200001), family .. " low-level BoE gray was excluded")
    assert(t.fj.IsJunkForDisplay(200072, t.inv.GetContainerItemInfo(0, 72)), "uncached gray metadata ignored")
    local junkTab = {}; for _, id in ipairs(t.fj.GetJunkTabList()) do junkTab[id] = true end
    assert(junkTab[200001] and not junkTab[200067], "Junk tab disagrees with rules")
    t.hidden[200072] = nil; t.fj.OnItemDataLoaded(200072)
    assert(t.fj.IsJunk(200072), "item data did not refresh the junk rule")
    t.sj.Start("all")
    local sent = #t.calls
    assert(sent == 40, "hardware burst limit changed")
    t.sj.Start("all"); t.sj.Start("inferiorOnly")
    local requested = {}
    for _, call in ipairs(t.calls) do
        assert(not requested[call.itemID], "re-click restarted an in-flight request")
        requested[call.itemID] = true
    end
    t.advance(10)
    assert(not t.sj.IsSelling(), family .. " sell queue did not finish")
    assert(#t.calls == (reagentItem and 68 or 67) and #t.errors == 0, family .. " duplicated/missed a sale")
    for slot = 67, 71 do assert(t.bags[0][slot], "protected/unsellable stack was sold") end
    assert(not t.bags[0][1] and not t.bags[0][72])
end
for _, options in ipairs({ { busyOnce = true }, { noopOnce = true }, { immediate = true },
    { latency = 2.5 }, { latency = 0.5, noLock = true }, { namespacedInfo = true }, { modern = true } }) do
    local t = Boot("era", options)
    t.add(1, 210001); t.add(2, 210002)
    t.sj.Start("all"); t.advance(12)
    assert(not t.sj.IsSelling() and not next(t.bags[0]) and #t.errors == 0, "busy/no-op/latency/legacy dispatch failed")
end
do
    local t = Boot("anniversary", { legacyNoValueAbsent = true })
    t.add(1, 215001, { quality = 2 }); t.hidden[215001] = true
    t.settings.junkList[215001] = true; t.settings.junkFilters.destroy = true
    t.add(2, 215002, { sellPrice = 0 })
    assert(t.inv.GetContainerItemInfo(0, 1).noValue == nil, "missing legacy value flag became sellable")
    assert(not t.fj.IsJunk(215002, t.inv.GetContainerItemInfo(0, 2)), "unsellable legacy gray became vendor junk")
    t.sj.Start("all"); t.advance(0.4)
    assert(#t.calls == 0 and t.bags[0][1], "uncached legacy item was guessed sellable/unsellable")
    t.hidden[215001] = nil; t.fj.OnItemDataLoaded(215001); t.advance(3)
    assert(#t.calls == 1 and not t.bags[0][1] and t.bags[0][2] and not t.sj.IsSelling())
end
do
    local t = Boot("live")
    for bag = 0, 4 do for slot = 1, 36 do t.add(slot, 216000 + bag * 100 + slot, nil, bag) end end
    t.sj.Start("all"); t.advance(12)
    assert(#t.calls == 180 and #t.errors == 0 and not t.sj.IsSelling(), "large sale stopped while making progress")
end
do
    local t = Boot("forever")
    for i = 1, 60 do t.add(i, 220000 + i) end
    t.sj.Start("all")
    -- Move a not-yet-requested item; protect another while the first burst waits.
    t.bags[1][8], t.bags[0][55] = t.bags[0][55], nil
    t.settings.junkList[220050] = false
    t.advance(10)
    assert(not t.sj.IsSelling() and not t.bags[1][8] and t.bags[0][50], "relocation/protection recheck failed")
    assert(#t.calls == 59 and #t.errors == 0)
end
do
    local t = Boot("live")
    t.add(1, 230001); t.add(2, 230002)
    t.fj.MarkUpgradeInferior(230001)
    t.sj.Start("inferiorOnly"); t.sj.Start("all"); t.advance(6)
    assert(#t.calls == 2 and #t.errors == 0 and not t.sj.IsSelling(), "mode change resubmitted a pending sale")
end
do
    local t = Boot("anniversary")
    t.add(1, 240001); t.cursor(true); t.sj.Start("all"); t.advance(0.5)
    assert(#t.calls == 0, "seller used the player's cursor")
    t.cursor(false); t.advance(2)
    assert(#t.calls == 1 and not t.sj.IsSelling())
    t.add(1, 240002); t.sj.Start("all"); t.close(); t.advance(4)
    assert(not t.sj.IsSelling(), "closed merchant left timers active")
end
for _, family in ipairs({ "live", "forever", "era", "anniversary", "mists" }) do
    local t = Boot(family)
    local ids = { 3300, 3670, 6150, 11406, 11944, 25402 }
    for slot, id in ipairs(ids) do
        t.add(slot, id, { name = id == 3300 and "Rabbit's Foot" or ("Gray " .. id), classID = 15, sellPrice = 9 })
        assert(t.fj.IsJunk(id) and t.fj.IsJunkForDisplay(id) and t.fj.IsAutoJunk(id),
            family .. " built-in whitelist still blocks a gray item: " .. id)
    end
    local tab = {}; for _, id in ipairs(t.fj.GetJunkTabList()) do tab[id] = true end
    for _, id in ipairs(ids) do assert(tab[id], "whitelisted gray missing from Junk tab") end
    -- Explicit Useful remains authoritative, including string-keyed old saves.
    t.settings.junkList['3300'] = false
    assert(not t.fj.IsJunk(3300) and not t.fj.IsJunkForDisplay(3300))
    t.settings.junkList['3300'] = nil
    t.hidden[3300] = true; t.fj.InvalidateItemRules(3300)
    assert(t.fj.IsJunk(3300, t.inv.GetContainerItemInfo(0, 1))
        and t.fj.IsJunkForDisplay(3300, t.inv.GetContainerItemInfo(0, 1)), "uncached Rabbit's Foot still blocked")
    -- A non-gray default-protected consumable still stays out of all junk views.
    t.add(9, 2459, { quality = 1, classID = 0, itemLevel = 1.1 })
    assert(not t.fj.IsJunk(2459) and not t.fj.IsAutoJunk(2459))
    t.fj.InvalidateJunkTabListCache()
    for _, id in ipairs(t.fj.GetJunkTabList()) do assert(id ~= 2459, "non-gray protection ignored by Junk tab") end
    t.sj.Start('all'); t.advance(5)
    assert(#t.calls == #ids and #t.errors == 0 and not t.bags[0][1] and t.bags[0][9], "whitelisted gray sale regression")
end
local function VisualTexture(layer, sublevel)
    return {
        layer = layer, sublevel = sublevel,
        SetTexture = function(self, v) self.texture = v end,
        SetAtlas = function(self, v) self.atlas = v end,
        SetDrawLayer = function(self, l, s) self.layer, self.sublevel = l, s end,
        SetVertexColor = function() end, SetBlendMode = function() end,
        SetPoint = function() end, SetSize = function() end,
        Show = function(self) self.shown = true; self.shows = (self.shows or 0) + 1 end,
        Hide = function(self) self.shown = false end,
        SetShown = function(self, v) self.shown = v end,
    }
end
for _, family in ipairs({ "live", "forever", "era", "anniversary", "mists" }) do
    local t = Boot(family)
    local frame = { Items = {}, IsShown = function() return true end, GetID = function() return 0 end,
        GetName = function() return "FixtureBags" end, HookScript = function() end }
    local buttons = {}
    for slot = 1, 8 do
        if slot ~= 7 then t.add(slot, 250000 + slot) end
        local button = { textures = {}, GetBagID = function() return 0 end,
            GetID = function() return slot end, IsShown = function() return true end }
        function button:CreateTexture(_, layer, _, sublevel)
            local texture = VisualTexture(layer, sublevel)
            self.textures[#self.textures + 1] = texture
            return texture
        end
        if slot ~= 4 then button.JunkIcon = VisualTexture("OVERLAY", 1) end
        buttons[slot] = button
        if slot < 8 then frame.Items[slot] = button end
        t.env["FixtureBagsItem" .. slot] = button
    end
    t.add(1, 3300, { name = "Rabbit's Foot", classID = 15, sellPrice = 9 })
    t.settings.junkList[250002] = false
    t.gear['0_3'] = true
    t.facts[250004].quality = 2; t.settings.junkList[250004] = true
    t.hidden[250005] = true
    t.facts[250006].quality = 1
    -- Blizzard enumerates only part of this combined bag; extra pooled and
    -- named buttons still need their coin/highlight, without duplicate paints.
    function frame:EnumerateValidItems() return ipairs({ buttons[1], buttons[2] }) end
    t.env.ContainerFrameCombinedBags = frame
    local overlay = Load("Inventory/Restock/Junk/FluxJunkOverlay.lua", t.env, t.ns)
    local function Coin(button)
        if button.JunkIcon then return button.JunkIcon end
        for _, texture in ipairs(button.textures) do
            if texture.texture == t.fj.COIN_ICON then return texture end
        end
    end
    local function Glow(button)
        for _, texture in ipairs(button.textures) do
            if texture.texture == "Interface/Buttons/UI-ActionButton-Border" then return texture end
        end
    end
    overlay.UpdateContainer(frame, true)
    for slot, button in ipairs(buttons) do
        local junk = slot == 1 or slot == 4 or slot == 5 or slot == 8
        assert(Coin(button).shown == junk and Glow(button).shown == junk, family .. " missing/stale coin or highlight: " .. slot)
        if junk then assert(Coin(button).layer == "OVERLAY" and Coin(button).sublevel == 7) end
        assert(Glow(button).sublevel == 6)
    end
    assert(buttons[1].JunkIcon.shows == 1, "combined/pool/named enumeration painted a button twice")
    buttons[1].JunkIcon:Hide(); overlay.UpdateContainer(frame, true)
    assert(buttons[1].JunkIcon.shown, "Blizzard hid the coin despite an unchanged paint cache")
    t.settings.junkDisplay = { icons = false, glow = true }; overlay.UpdateContainer(frame, true)
    assert(not Coin(buttons[1]).shown and Glow(buttons[1]).shown)
    t.settings.junkDisplay = { icons = true, glow = false }; overlay.UpdateContainer(frame, true)
    assert(Coin(buttons[1]).shown and not Glow(buttons[1]).shown)
    t.settings.junkDisplay = nil
    t.bags[0][1] = nil; overlay.UpdateContainer(frame, true)
    assert(not Coin(buttons[1]).shown and not Glow(buttons[1]).shown, "recycled empty slot retained junk decorations")
end
do
    local t = Boot("live")
    local plugin, refreshes = nil, 0
    t.add(1, 3300, { name = "Rabbit's Foot", classID = 15, sellPrice = 9 }); t.hidden[3300] = true
    t.env.Baganator = { API = {
        RegisterJunkPlugin = function(_, _, fn) plugin = fn end,
        RequestItemButtonsRefresh = function() refreshes = refreshes + 1 end,
    } }
    Load("BaganatorCompat/FluxBaganator_Junk.lua", t.env, t.ns)
    t.env.FluxBaganatorCompat.InitJunk()
    assert(plugin and not plugin(0, 1, 3300))
    t.hidden[3300] = nil; t.fj.OnItemDataLoaded(3300)
    assert(refreshes > 0 and plugin(0, 1, 3300), "Baganator coin/highlight stayed stale after Rabbit's Foot data loaded")
    t.gear['0_1'] = true; assert(not plugin(0, 1, 3300))
end
print("Junk smoke OK: actual compatibility/facade/classifier/seller; Live/Forever/Era/Anniversary/Mists; gray rules/lists, async and immediate sales, no duplicates/bulk/cursor fallback, busy retry, protection, relocation, mode switch, close")
print("Junk visuals OK: native/fallback coin + highlight, pooled/named buttons, uncached grays, protected/empty slots, settings, native coin resets, Baganator item-data refresh")
