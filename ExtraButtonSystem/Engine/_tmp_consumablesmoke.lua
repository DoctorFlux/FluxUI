-- lua ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua
-- Real count API, inventory snapshots/dispatch, Best listener, binding and paint.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../../"
local checks = 0
local function eq(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, (label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function read(path)
    local file = assert(io.open(root .. path)); local source = file:read("*a"); file:close(); return source
end
local function compile(source, env)
    if setfenv then local chunk = assert(loadstring(source)); setfenv(chunk, env); return chunk end
    return assert(load(source, "consumables fixture", "t", env))
end
local families = {
    forever = { "1.16.0", 1, 16001 }, retail = { "12.0.1", 1, 120001 },
    era = { "1.15.9", 2, 11509 }, anniversary = { "2.5.6", 5, 20506 },
    wrath = { "3.4.3", 11, 30403 }, cata = { "4.4.2", 14, 40402 }, mists = { "5.5.4", 19, 50504 },
}
local items = {
    [117] = { kind = "food", effective = 60 }, [2287] = { kind = "food", effective = 120 },
    [159] = { kind = "water", effective = 100 }, [1251] = { kind = "bandage", effective = 66 },
    [2581] = { kind = "bandage", effective = 114 }, [118] = { kind = "healPotion", effective = 80 },
    [2455] = { kind = "manaPotion", effective = 120 }, [999] = { kind = "food", effective = 1000, minLevel = 80 },
    [5512] = { kind = "healthstone", effective = 90, maxStack = 1 },
    [5514] = { kind = "managem", effective = 100, maxStack = 1 },
    [22044] = { kind = "managem", effective = 1000, maxStack = 1 },
}
local kinds = { food = "IsFoodButton", water = "IsWaterButton", bandage = "IsBandageButton",
    healPotion = "IsHealPotionButton", manaPotion = "IsManaPotionButton", healthstone = "IsHealthstoneButton", managem = "IsManaGemButton" }
local function boot(family, legacy)
    local s = { now = 10, timers = {}, events = {}, frames = {}, tokens = {}, slots = { [0] = {}, [1] = {} }, bagSizes = { [0] = 16, [1] = 8 },
        uses = {}, combat = false, cached = true, writes = 0, scans = 0, bankOpen = false }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local Flux = { EBS = { buttons = {}, badges = {} }, Cap = {}, Module = { Register = function() end } }
    local ns = { Flux = Flux }; env.Flux = Flux; env.FluxButton = {}; env.SlashCmdList = {}
    local function load(path) return compile(read(path), env)("_FluxUI", ns) end
    env.wipe = function(t) for key in pairs(t) do t[key] = nil end; return t end
    env.GetTime = function() return s.now end
    env.C_Timer = { After = function(delay, fn) s.timers[#s.timers + 1] = { at = s.now + delay, fn = fn } end }
    Flux.Timer = env.C_Timer
    env.CreateFrame = function()
        local f = { events = {}, scripts = {}, attrs = {} }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:RegisterUnitEvent(event) self.events[event] = true end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:HookScript(event, fn) self.scripts[event] = fn end
        function f:RegisterForDrag() assert(not s.combat, "protected drag in combat") end
        function f:SetAttribute(key, value) assert(not s.combat, "protected attribute in combat"); self.attrs[key] = value end
        function f:GetAttribute(key) return self.attrs[key] end
        s.frames[#s.frames + 1] = f; return f
    end
    Flux.Safecall = function(fn, ...) return fn(...) end
    Flux.Events = { Register = function(event, fn)
        s.events[event] = s.events[event] or {}; table.insert(s.events[event], fn)
    end, RegisterUnit = function(event, _, fn)
        s.events[event] = s.events[event] or {}; table.insert(s.events[event], fn); return true
    end }
    Flux.Scheduler = { Request = function(_, token) s.tokens[token] = true end }
    function s:event(event, ...)
        for _, fn in ipairs(self.events[event] or {}) do fn(event, ...) end
        for _, f in ipairs(self.frames) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end end
    end
    function s:advance(seconds)
        local target, iterations = self.now + seconds, 0
        while true do
            iterations = iterations + 1; assert(iterations < 1000, "unbounded refresh loop")
            if next(self.tokens) then
                local tokens = self.tokens; self.tokens = {}
                if Flux.Inventory.source == "builtin" then Flux.Inventory.Builtin.Flush(tokens) end
                Flux.Inventory.Notify(tokens)
            end
            local first, at
            for i, t in ipairs(self.timers) do if t.at <= target and (not at or t.at < at) then first, at = i, t.at end end
            if not first then break end
            local t = table.remove(self.timers, first); self.now = t.at; t.fn()
        end
        self.now = target
    end
    env.WOW_PROJECT_ID = families[family][2]
    env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC, env.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 1, 2, 5
    env.WOW_PROJECT_WRATH_CLASSIC, env.WOW_PROJECT_CATACLYSM_CLASSIC, env.WOW_PROJECT_MISTS_CLASSIC = 11, 14, 19
    env.GetBuildInfo = function() return families[family][1], "70000", "", families[family][3] end
    env.InCombatLockdown = function() return s.combat end
    env.UnitHealthMax = function() return 500 end; env.UnitPowerMax = function() return 1000 end
    env.UnitLevel = function() return 10 end
    env.UnitClass = function() return "Mage", "MAGE" end
    local function info(id)
        local d = items[id]; if not d or not s.cached then return end
        return "item" .. id, "item:" .. id, 1, 1, d.minLevel or 1, "Consumable", "Other", d.maxStack or 20, "", 1, 0, 0, 0
    end
    local function count(id, bank, uses, ...)
        if legacy then assert(select("#", ...) == 0, "legacy count called with unsupported arguments") end
        if uses then return s.uses[id] or 0 end
        local n = bank and 100 or 0
        for _, bag in pairs(s.slots) do for _, slot in pairs(bag) do if slot.itemID == id then n = n + slot.stackCount end end end
        return n
    end
    local function slots(bag) return s.bagSizes[bag] or 0 end
    env.C_Item = { GetItemInfo = info, GetItemCount = not legacy and count or nil,
        IsConsumableItem = function(id) return items[id] ~= nil end, IsUsableItem = function() return true, false end }
    env.GetItemInfo = info; env.GetItemCount = legacy and count or nil
    if legacy then
        env.GetContainerNumSlots = slots
        env.GetContainerItemInfo = function(bag, slot)
            local rec = s.slots[bag] and s.slots[bag][slot]
            if rec then return 1, rec.stackCount, false, 1, false, false, rec.hyperlink, false, false, rec.itemID end
        end
    else
        env.C_Container = { GetContainerNumSlots = slots,
            GetContainerItemInfo = function(bag, slot) return s.slots[bag] and s.slots[bag][slot] end,
            GetContainerItemID = function(bag, slot) local rec = s.slots[bag] and s.slots[bag][slot]; return rec and rec.itemID end }
    end
    load("Core/Client.lua"); load("Core/API/Item.lua"); load("Core/API/Container.lua")
    load("Inventory/Init.lua"); load("Inventory/Containers.lua"); load("Inventory/Index.lua")
    local Inv = Flux.Inventory; s.inv = Inv
    Inv.Builtin.Bank = { Refresh = function() end, IsOpen = function() return s.bankOpen end }
    Inv.Builtin.Equip = { Refresh = function() end, Invalidate = function() end }
    load("Inventory/Builtin/Bags.lua"); load("Inventory/Builtin/Watch.lua"); load("Inventory/LegacyBridge.lua")
    load("Inventory/Craft.lua")
    Inv.Builtin.Start(); s:advance(0)
    load("Inventory/FluxConsumableBest/Init.lua"); load("Inventory/FluxConsumableBest/Score.lua")
    local Best = env.FluxConsumableBest; s.best = Best
    Best.Persist = { GetRoot = function() end, GetRef = function() end, MaybeUpdateRef = function() end }
    Best.VendorMemory = { HookMerchantIndex = function() end, GetVendorCandidates = function() return {} end }
    env.FluxConsumableClassify = { Classify = function(id) return items[id] end }
    -- Only item classification data and persistence are fixtures; use the real
    -- bounded scanner, ranking, owned ladders, event dispatch and button code.
    load("Inventory/FluxConsumableBest/Scan.lua")
    local recompute = Best.Scan.Recompute
    Best.Scan.Recompute = function(opts) s.scans = s.scans + 1; return recompute(opts) end
    load("Inventory/FluxConsumableBest/FluxConsumableBest.lua"); s:advance(0)
    load("ExtraButtonSystem/Engine/Paint.lua"); load("ExtraButtonSystem/Engine/ConsumableBind.lua")
    local paint = Flux.EBS.Paint; s.paint = paint; s.bridge = env.FluxEBSConsumableBridge
    Inv.Register("smoke.counts", function(ctx) paint.FlushCounts(ctx) end, { tier = "instant", sync = true, regions = { "bags" } })
    local gridSource = read("ExtraButtonSystem/CombatGrid/Grid.lua")
    local first = assert(gridSource:find("function btn:SetCount(count, opts)", 1, true))
    local last = assert(gridSource:find("function btn:ShowTooltip()", first, true))
    function s:button(kind, craft, modulePath)
        local text = { value = "", Show = function() end, IsShown = function() return true end,
            SetText = function(self, value) self.value = tostring(value) end, GetText = function(self) return self.value end, SetAlpha = function() end }
        local icon = { SetVertexColor = function(self, r, g, b) self.color = { r, g, b } end,
            SetDesaturated = function() end, SetTexture = function() end, Show = function() end, SetTexCoord = function() end }
        local btn = { Widget = env.CreateFrame(), WCount = text, WIcon = icon }
        function btn:SetAction(action, id)
            assert(not s.combat, "rebound a consumable in combat"); s.writes = s.writes + 1
            self.ActionType, self.ActionValue, self.ItemId = action, id, id
        end
        function btn:ClearPlaceholder() self.PlaceholderTexture = nil; self.PlaceholderHideCount = nil end
        function btn:SetPlaceholder(texture)
            assert(not s.combat, "placeholder in combat")
            self.PlaceholderTexture = texture; self.PlaceholderHideCount = true
            self.ActionType, self.ActionValue = nil, nil
        end
        function btn:SetLocked() end
        function btn:FullRefresh() paint.UpdateCount(self); paint.UpdateUsable(self) end
        compile("local btn = ...\n" .. gridSource:sub(first, last - 1), env)(btn)
        btn.UpdateUsable = function(self) paint.UpdateUsable(self) end
        local module = {}
        Flux.EBS.buttons[#Flux.EBS.buttons + 1] = btn
        if modulePath then
            module = load(modulePath)
            module.Create({ ButtonSize = 44, CreateButton = function() return btn end })
        else
            env.FluxEBSButtonRefresh.Attach({ module = module, btn = btn, kind = kind, kindFlag = kinds[kind],
                charges = kind == "managem" or kind == "healthstone", listenerKey = "smoke." .. kind,
                placeholderIcon = "placeholder", placeholderLabel = kind, reapplyCraftOnBag = craft,
                applyRightClick = function()
                    s.rightClicks = (s.rightClicks or 0) + 1
                    if craft then s.bridge.ApplyCraftOrRestockRightClick(btn, kind) end
                end })
        end
        return btn, module
    end
    function s:set(bag, slot, id, n)
        self.slots[bag] = self.slots[bag] or {}
        self.slots[bag][slot] = n > 0 and { itemID = id, stackCount = n, hyperlink = "item:" .. id } or nil
    end
    function s:bags(delay)
        self:event("BAG_UPDATE", 0); self:event("BAG_UPDATE", 1); self:event("BAG_UPDATE_DELAYED")
        self:advance(delay or 0.4)
    end
    function s:expect(btn, id, n, label)
        eq(btn.ItemId, id, label .. " item"); eq(btn.WCount.value, tostring(n), label .. " count")
        paint.UpdateUsable(btn); eq(btn.WIcon.color[1], n > 0 and 1 or 0.4, label .. " tint")
    end
    s.load, s.env = load, env
    return s
end

for family in pairs(families) do
    local s = boot(family, family == "era" or family == "anniversary" or family == "wrath")
    for _, pair in ipairs({ { "food", 117 }, { "water", 159 }, { "bandage", 1251 }, { "healPotion", 118 }, { "manaPotion", 2455 } }) do
        local kind, id = pair[1], pair[2]
        local btn, module = s:button(kind, kind == "bandage" or kind == "healPotion" or kind == "manaPotion")
        for _, n in ipairs({ 20, 2, 1 }) do s:set(0, 1, id, n); s:bags(); s:expect(btn, id, n, family .. " " .. kind) end
        -- Combat can only change the displayed count, never secure attributes.
        s.combat = true; local writes = s.writes
        s:set(0, 1, id, 0); s:bags(); s:expect(btn, id, 0, "combat last use")
        eq(s.writes, writes, "combat action writes"); eq(module._pendingUpdate, true, "combat pending")
        s:set(0, 1, id, 7); s:bags(); s:expect(btn, id, 7, "combat refill")
        eq(btn._forcedCount, 7, "live count cache recovered")
        s.combat = false; s:event("PLAYER_REGEN_ENABLED"); s:advance(0.4)
        s:set(0, 1, id, 0); s:bags(); eq(btn.ItemId, nil, "depletion clears action")
        s:set(0, 1, id, 1); s:bags(); s:expect(btn, id, 1, "purchase/conjure refill")
        eq(s.bridge.DisplayItemCount(id), 1, "generic item count")
        s.cached = false; s:expect(btn, id, 1, "uncached kind count"); s.cached = true
        s:set(0, 1, id, 0); s:bags()
    end
    -- A legacy gem and original healthstone remain usable with a zero use query.
    s:set(0, 1, 5514, 1); s:bags()
    eq(s.bridge.BagCount(5514, { charges = true }), 1, "single-use gem")
    s:set(0, 1, 5512, 1); s:bags()
    local chargedStone = family == "retail" or family == "mists"
    eq(s.bridge.BagCount(5512, { charges = true }), chargedStone and 0 or 1, "client healthstone policy")
    local gem = s:button("managem")
    s:set(0, 1, 22044, 1)
    for _, n in ipairs({ 3, 2, 1, 0 }) do
        s.uses[22044] = n; s:bags()
        eq(s.bridge.BagCount(22044, { charges = true }), n, "charged gem ownership")
        eq(s.bridge.DisplayItemCount(22044), n, "charged gem digit")
    end
    s:set(0, 1, 22044, 0); s.uses[22044] = 3; s:bags()
    eq(s.bridge.BagCount(22044, { charges = true }), 0, "bank-only uses excluded")
    eq(s.bridge.DisplayItemCount(22044), 0, "bank-only digit")
    s:set(0, 1, 5512, 0); s:set(0, 2, 117, 1); s:bags()
    local btn, module = s:button("food")
    s:set(0, 3, 2287, 1); s:set(0, 4, 999, 1); s:bags()
    s:expect(btn, 2287, 1, "better eligible food")
    s:set(0, 3, 2287, 0); s:bags(); s:expect(btn, 117, 1, "fallback food")
    s:set(0, 2, 117, 0); s:set(1, 1, 117, 1); s:bags(); s:expect(btn, 117, 1, "move between bags")
    s:set(0, 2, 117, 2); s:bags(); s:expect(btn, 117, 3, "split stacks aggregate")
    -- Paint-only refill must not retain an old forced zero or gray tint.
    btn._forcedCount = 0; btn._lastCountText = "0"; btn.WCount.value = "0"
    s.paint.UpdateUsable(btn); eq(btn.WIcon.color[1], 1, "usable before count paint")
    s.paint.UpdateCount(btn); eq(btn._forcedCount, 3, "paint-only count cache")
    -- Swap face uses its item, even while the potion/food home item differs.
    s:set(0, 5, 118, 9); s:bags()
    btn.ActionType, btn.ActionValue, btn.MacroMode = "macrotext", "swap", "item"
    btn._fluxCombatSwapBody, btn.ItemId = "/use [combat] item:118\n/use [nocombat] item:117", 118
    s.paint.UpdateCount(btn); eq(btn.WCount.value, "9", "combat-swap face count")
    btn:SetCount(9); s.inv.MarkUnreliable("zone"); s.inv.snapshots.bags.counts = {}
    s.paint.UpdateCount(btn); eq(btn.WCount.value, "9", "swap load-screen latch")
    -- Without another bag event, the deadline must release a collapsed hold.
    s:set(0, 2, 117, 0); s:set(0, 4, 999, 0); s:set(0, 5, 118, 0); s:set(1, 1, 117, 0)
    btn._fluxCombatSwapBody = nil
    s:advance(8.2)
    eq(s.inv.IsReliable(), true, "hold deadline reliability")
    eq(s.inv.SnapshotLooksCollapsed(), false, "hold deadline collapse")
    eq(s.best.ShouldSoftHoldOwned(), false, "hold deadline Best")
    eq(btn.ItemId, nil, "hold deadline clears stale identity")
    print(family .. " consumables passed")
end

-- Exercise the specialized Healthstone/ManaGem modules, including their count
-- overrides and right-click attributes, rather than just the shared attachment.
for _, family in ipairs({ "forever", "retail" }) do
    local s = boot(family, false)
    s:set(0, 1, 5512, 1); s.uses[5512] = family == "retail" and 3 or 0; s:bags()
    local stone = s:button("healthstone", false, "ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua")
    s:advance(0.4); s:expect(stone, 5512, family == "retail" and 3 or 1, "real healthstone module")
    s.combat = true; local writes = s.writes
    s:set(0, 1, 5512, 0); s.uses[5512] = 0; s:bags(); s:expect(stone, 5512, 0, "real stone combat depletion")
    eq(s.writes, writes, "real stone combat actions")
    s:set(0, 1, 5512, 1); s.uses[5512] = family == "retail" and 3 or 0; s:bags()
    s:expect(stone, 5512, family == "retail" and 3 or 1, "real stone combat refill")
    s.combat = false; s:event("PLAYER_REGEN_ENABLED"); s:advance(0.4)
    s.inv.CreateSpells = { HasCreateKind = function(kind) return kind == "managem" end,
        IsKnownByName = function(name) return name == "Conjure Mana Emerald", 27101 end }
    s:set(0, 1, 5512, 0); s:set(0, 2, 22044, 1); s.uses[22044] = 3; s:bags()
    local gem = s:button("managem", false, "ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua")
    for _, n in ipairs({ 3, 2, 1, 0 }) do
        s.uses[22044] = n; s:bags(); s:expect(gem, 22044, n, "real gem charge change")
    end
    s.uses[22044] = 3; s:bags(); s:expect(gem, 22044, 3, "real gem refill")
end

-- Login data arrives after the initial empty snapshot. A second load must not
-- be released by the first load's timer; no bag pulse is required at expiry.
do
    local s = boot("forever", false)
    s.inv.BeginLoginHold(); local btn = s:button("food")
    eq(btn.ItemId, nil, "login empty placeholder")
    s:event("PLAYER_ENTERING_WORLD", true, false)
    s:set(0, 1, 117, 1); s:bags(0.05); s.inv.NoteLoginBagsDelayed(); s:advance(0.6)
    s:expect(btn, 117, 1, "login late bags")
    s.inv.MarkUnreliable("zone"); s:advance(2); s.inv.MarkUnreliable("zone again")
    s.inv.snapshots.bags.counts = {}; s:advance(1.1)
    eq(s.inv.IsReliable(), false, "old hold timer cannot release new load")
    s:advance(7); eq(s.inv.IsReliable(), true, "second load deadline")
    eq(s.best.ShouldSoftHoldOwned(), false, "second load stops holding")
end

-- Syndicator supplies the same light pulse while bank moves are in progress.
do
    local s = boot("forever", false)
    local btn = s:button("bandage", true)
    local char = { bags = { {} } }
    s.env.Syndicator = { Constants = { AllBagIndexes = { 0 } }, API = {
        GetCurrentCharacter = function() return "player" end, GetCharacter = function() return char end } }
    s.load("Inventory/Syndicator/Adapter.lua"); s.inv.source = "syndicator"; s.inv.SetMerchantOpen(true)
    local scans = s.scans
    for _, n in ipairs({ 5, 1, 0, 4 }) do
        char.bags[1] = n > 0 and { { itemID = 1251, itemCount = n } } or {}
        s.inv.Syndicator.RebuildBags(); s.inv.Notify({ bags = true, tier = "light" }); s:advance(0.4)
        if n > 0 then s:expect(btn, 1251, n, "Syndicator bank transfer") else eq(btn.ItemId, nil, "Syndicator empty") end
    end
    assert(s.scans > scans, "merchant hold starved Best recompute")
    s.env.FluxItemClass = { GetStatic = function(id) return { classID = items[id] and 0 or 7 } end }
    local beforeScans, beforeCraft = s.scans, s.rightClicks
    for n = 1, 100 do
        char.bags[1][2] = { itemID = 123456, itemCount = n }
        s.inv.Syndicator.RebuildBags({ [0] = true })
        s.inv.Notify({ bags = true, tier = "light" }); s:advance(0.01)
    end
    s:advance(0.4)
    eq(s.scans, beforeScans, "Syndicator unrelated updates skip scans")
    eq(s.rightClicks, beforeCraft, "Syndicator unrelated updates skip crafting")
    s:expect(btn, 1251, 4, "Syndicator burst preserves count")
end

-- Realistic seven-button burst: changed-item context must keep unrelated loot
-- off selection/tooltip/recipe paths, while counts update on the same pulse.
for _, family in ipairs({ "forever", "retail", "era", "anniversary", "mists" }) do
    local s = boot(family, family == "era" or family == "anniversary")
    s.env.FluxItemClass = { GetStatic = function(id) return { classID = items[id] and 0 or 7 } end }
    local specs = {
        { "food", 117, "FluxNCFood" }, { "water", 159, "FluxNCWater" },
        { "bandage", 1251, "FluxCombatBandage" }, { "healPotion", 118, "FluxCombatHealPotion" },
        { "manaPotion", 2455, "FluxCombatManaPotion" }, { "healthstone", nil, "FluxCombatHealthstone" },
        { "managem", nil, "FluxCombatManaGem" },
    }
    for i, spec in ipairs(specs) do if spec[2] then s:set(0, i, spec[2], 20) end end
    s:bags()
    local buttons = {}
    for _, spec in ipairs(specs) do
        local craft = spec[1] == "bandage" or spec[1] == "healPotion" or spec[1] == "manaPotion"
        local btn, module = s:button(spec[1], craft); s.env[spec[3]] = module; buttons[spec[1]] = btn
    end
    s:advance(3)
    -- These are legitimate unowned suggestions and must not force rescans.
    s.best._runtime.managem = { itemID = 22044, source = "create", count = 0 }
    s.best._runtime.healthstone = { itemID = 5512, source = "vendor", count = 0 }
    local picks, parses = 0, 0
    local selectItem = s.bridge.GetBestOwned
    s.bridge.GetBestOwned = function(...) picks = picks + 1; return selectItem(...) end
    local classify = s.env.FluxConsumableClassify.Classify
    s.env.FluxConsumableClassify.Classify = function(...) parses = parses + 1; return classify(...) end
    local scans, writes, rightClicks = s.scans, s.writes, s.rightClicks
    for n = 1, 100 do s:set(1, 1, 123456, n); s:bags(0.01) end
    s:advance(1)
    eq(s.scans - scans, 0, family .. " unrelated burst scans")
    eq(picks, 0, family .. " unrelated burst selections")
    eq(parses, 0, family .. " unrelated burst classifications")
    eq(s.writes - writes, 0, family .. " unrelated burst binds")
    eq(s.rightClicks - rightClicks, 0, family .. " unrelated burst craft refreshes")
    for n = 19, 1, -1 do
        s:set(0, 1, 117, n); s:bags(0)
        eq(buttons.food.WCount.value, tostring(n), "same-pulse food count")
        s:advance(0.01)
    end
    s:advance(0.4)
    eq(s.scans - scans, 0, "count-only updates avoid scans")
    eq(picks, 0, "count-only updates avoid selection")
    -- New consumable identities coalesce, and the best is still selected.
    s:set(0, 8, 2287, 1); s:bags(0)
    for n = 2, 100 do s:set(0, 8, 2287, n); s:bags(0.001) end
    s:advance(0.4); s:expect(buttons.food, 2287, 100, "batched better food")
    eq(s.scans - scans, 1, "new-item burst scans once")
    print(family .. " burst: 100 unrelated updates, 0 scans/selections/classifications/binds")
end

-- Real recipe dependencies: unrelated items never rebuild recipes, but changing
-- cloth enables/disables the right-click craft without rebinding the main item.
do
    local s = boot("forever", false)
    s.env.FluxItemClass = { GetStatic = function(id) return { classID = items[id] and 0 or 7 } end }
    s.inv.Professions = { ListAllCachedRecipes = function() return {
        { name = "Linen Bandage", outputItemID = 1251, skillLineID = 129,
            reagents = { { itemID = 2589, count = 1 } } },
    } end }
    s:set(0, 1, 1251, 3); s:bags()
    local btn = s:button("bandage", true); s:advance(0.5)
    eq(btn.Widget:GetAttribute("macrotext2"), nil, "no cloth no craft")
    local scans, writes = s.scans, s.writes
    s:set(0, 2, 2589, 5); s:bags(0.2)
    eq(btn.Widget:GetAttribute("macrotext2"), s.bridge.GetCraftMacro("bandage"), "cloth enables craft")
    eq(s.scans, scans, "reagent loot skips consumable scan")
    eq(s.writes, writes, "reagent loot does not rebind bandage")
    s:set(0, 2, 2589, 0); s:bags(0.2)
    eq(btn.Widget:GetAttribute("macrotext2"), nil, "cloth depletion disables craft")
end

-- Charged custom Extra buttons still repaint when stack totals did not move.
do
    local s = boot("retail", false)
    s:set(0, 1, 22044, 1); s.uses[22044] = 3; s:bags()
    local btn = s:button("managem")
    s.env.FluxInv.UnregisterListener("smoke.managem")
    s.uses[22044] = 2; s:bags(0)
    eq(btn.WCount.value, "2", "charged count without stack delta")
end

-- A mostly full inventory must not spend the consumable classification budget
-- on gear/materials, or keep restarting its backlog on ordinary stack updates.
do
    local s = boot("forever", false)
    s.bagSizes[1] = 100
    s.env.FluxItemClass = { GetStatic = function(id) return { classID = items[id] and 0 or 7 } end }
    for slot = 1, 100 do s:set(1, slot, 200000 + slot, 1) end
    s:set(0, 1, 117, 20); s:bags()
    local btn = s:button("food"); s:advance(0.4)
    eq(s.best.GetClassifyQueueCount(), 0, "full bags exclude non-consumable backlog")
    local scans = s.scans
    s:set(0, 2, 2287, 1); s:bags(0)
    for n = 2, 100 do s:set(0, 2, 2287, n); s:set(1, 1, 200001, n); s:bags(0.01) end
    s:advance(0.4)
    s:expect(btn, 2287, 100, "full bags better consumable")
    eq(s.scans - scans, 1, "full bags new-item burst scans once")
    eq(s.best.GetClassifyQueueCount(), 0, "full bags leave no irrelevant classify queue")
end

-- A bag-only refresh at an open bank must not force a bank megawalk. A real
-- bank pulse arriving in the same batch must still widen the requested regions.
do
    local s = boot("forever", false)
    s.inv.IsBankOpen = function() return true end
    local queries = 0
    local unique = s.inv.GetUniqueItems
    s.inv.GetUniqueItems = function(opts)
        if opts and opts.bank then queries = queries + 1 end
        return unique(opts)
    end
    s:set(0, 1, 117, 1); s:bags(0.4)
    eq(queries, 0, "bag-only update skips open bank")
    s:set(0, 2, 2287, 1); s:bags(0)
    s.inv.Notify({ bank = true, tier = "light" }); s:advance(0.4)
    assert(queries > 0, "bank pulse was lost while merging bag-only scan")
end
print("Consumable smoke passed: " .. checks .. " checks")
