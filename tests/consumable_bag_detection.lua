-- Replay real metadata, inventory, selector and grid owners; client data is mocked.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a")
    file:close()
    return text
end

local replacements = {}
for i, value in ipairs(arg or {}) do
    if value == "--item-class" then replacements["Inventory/FluxItemClass.lua"] = arg[i + 1] end
    if value == "--scan" then replacements["Inventory/FluxConsumableBest/Scan.lua"] = arg[i + 1] end
end
local fixture = read("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua")
local stop = assert(fixture:find("-- PLAYER_LOGIN bag priming", 1, true))
local fixtureEnv = setmetatable({ arg = { [0] = "ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua" } }, { __index = _G })
fixtureEnv.io = { open = function(path, ...)
    local normalized = path:gsub("\\", "/")
    for source, candidate in pairs(replacements) do
        if normalized:sub(-#source) == source then path = candidate; break end
    end
    return io.open(path, ...)
end }
local boot, items = assert(load(fixture:sub(1, stop - 1) .. "return boot, items", "@consumable-fixture", "t", fixtureEnv))()
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end

local moduleNames = {
    food = "FluxNCFood", water = "FluxNCWater", bandage = "FluxCombatBandage",
    healPotion = "FluxCombatHealPotion", manaPotion = "FluxCombatManaPotion",
}
local function addProvider(s)
    local char, callbacks = { bags = {} }, {}
    s.env.Syndicator = {
        Constants = { AllBagIndexes = { 0, 1 }, AllBankIndexes = {} },
        API = {
            IsReady = function() return true end,
            GetCurrentCharacter = function() return "Fixture-Realm" end,
            GetCharacter = function() return char end,
        },
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

local kinds = { { "healPotion", 118 }, { "manaPotion", 2455 }, { "bandage", 1251 }, { "food", 117 }, { "water", 159 } }
for _, family in ipairs({ "forever", "retail", "era", "anniversary", "mists" }) do
    for _, provider in ipairs({ "builtin", "syndicator" }) do
        for _, spec in ipairs(kinds) do
            local kind, id = spec[1], spec[2]
            local s = boot(family, family == "era" or family == "anniversary")
            local create = s.env.CreateFrame
            local function completeFrame(frame)
                function frame:UnregisterEvent(event) self.events[event] = nil end
                return frame
            end
            for _, frame in ipairs(s.frames) do completeFrame(frame) end
            s.env.CreateFrame = function(...) return completeFrame(create(...)) end
            if provider == "syndicator" then addProvider(s) end
            local ready, pending = false, {}
            local class = s.env.FluxConsumableClassify
            class.Classify = function(itemID)
                if itemID == id and not ready then pending[itemID] = true; return nil end
                return items[itemID]
            end
            class.IsPending = function(itemID) return pending[itemID] == true end
            class.InvalidateCache = function(itemID) pending[itemID] = nil end
            s.env.ITEM_CLASS_CONSUMABLE = 0
            s.env.C_Item.GetItemInfoInstant = function(itemID) return itemID, "Consumable", "Other", "", 1, 0, 0 end
            s.env.C_Item.RequestLoadItemDataByID = function() end
            -- includeUses changes charge-bearing items; ordinary stacks still
            -- report their physical copies with this native option enabled.
            local count = s.env.C_Item.GetItemCount or s.env.GetItemCount
            local function nativeCount(itemID, bank, uses, ...)
                if uses and items[itemID] and not items[itemID].maxStack then uses = false end
                return count(itemID, bank, uses, ...)
            end
            if s.env.C_Item.GetItemCount then s.env.C_Item.GetItemCount = nativeCount
            else s.env.GetItemCount = nativeCount end
            local function tooltip() return { lines = { { leftText = "Item" }, { leftText = "Use: Restores health or mana." } } } end
            s.env.C_TooltipInfo = { GetItemByID = tooltip, GetHyperlink = tooltip }
            s.load("Inventory/FluxItemClass.lua")
            s.load("ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua")
            s:set(0, 1, id, 3)
            if s.publish then s:publish() else s:bags() end
            s:advance(10)
            local btn, module = s:button(kind, false)
            s.env[moduleNames[kind]] = module
            local actualPotion
            if kind == "healPotion" then
                s.env.FluxExtraButtonVisibility = {
                    Apply = function(_, smart) return smart end,
                    SetSlotShown = function(button, shown)
                        if not s.combat then button.testShown = shown end
                    end,
                }
                s.env.FluxCombatHealPotion = nil
                actualPotion = s:button(kind, false, "ExtraButtonSystem/CombatGrid/Buttons/HealPotion.lua")
            end
            s:advance(10) -- Exhaust the existing finite cold-start retries.
            local label = family .. " " .. provider .. " " .. kind
            check(not btn.ItemId and pending[id], label .. " awaits classification after startup retries")
            check(not s.best._pendingLoad[id] and not next(s.best._pendingAdded), label .. " has no item-data/addition shortcut")
            local bestGen, scans = s.best._generation, s.scans
            local metadataRequests = 0
            local request = s.best.RequestRecompute
            s.best.RequestRecompute = function(opts)
                if opts and opts.reason == "itemData" then metadataRequests = metadataRequests + 1 end
                return request(opts)
            end
            ready = true
            s.env.FluxItemClass.RequestLoad(id)
            -- Exercise the metadata owner's callback independently of native
            -- inventory observers that can otherwise mask the lost wake-up.
            s.env.FluxItemClass.OnItemDataEvent(id, true)
            check(metadataRequests == 1, label .. " pending classification completion reaches selector")
            s:advance(0.6)
            check(btn.ItemId == id and module._trackedItemID == id, label .. " metadata completion binds without another bag event")
            if actualPotion then check(actualPotion.ItemId == id and actualPotion.testShown, label .. " actual healing potion module becomes visible") end
            check(btn.WCount.value == "3", label .. " displays carried copies")
            check(s.inv.GetCount(id) == 3 and s.best._generation > bestGen, label .. " metadata wakes selection with unchanged bag contents")
            check(s.scans > scans and s.scans <= scans + 2, label .. " metadata uses existing bounded coalescer")
            local settledScans, writes, frames = s.scans, s.writes, #s.frames
            for _ = 1, 100 do
                s:event("GET_ITEM_INFO_RECEIVED", id, true)
                s:event("ITEM_DATA_LOAD_RESULT", id, true)
            end
            s:advance(1)
            check(s.scans == settledScans and s.writes == writes and #s.frames == frames, label .. " duplicate completions add no work/resources")

            -- Better copies in any other location must never win or inflate counts.
            local better = 100000 + id
            items[better] = { kind = kind, effective = 2000 }
            for _, region in ipairs({ "bank", "warband", "equip", "mail", "auctions", "guild", "void" }) do
                local snap = s.inv.snapshots[region]
                snap.counts[id], snap.counts[better] = 80, 90
                if snap.byBag then snap.byBag[100] = { { itemID = better, count = 90 } } end
                if snap.bySlot then snap.bySlot[1] = { itemID = better, count = 90 } end
                if snap.byIndex then snap.byIndex[1] = { itemID = better, count = 90 } end
            end
            module.Update(true)
            check(btn.ItemId == id and s.bridge.BagCount(id) == 3, label .. " nonbag copies excluded")
            check(s.bridge.BagCount(better) == 0, label .. " bank/mail/auction-only better item not owned")
            check(s.env.FluxNCConsumables.GetPhysicalItemCount(id) == 3, label .. " configured noncombat consumable count is bag-only")
            check(s.env.FluxNCConsumables.GetPhysicalItemCount(better) == 0, label .. " configured noncombat consumable excludes stored-only item")
            local pick = s.bridge.GetBestOwned(kind)
            check(pick and pick.itemID == id and pick.count == 3, label .. " bag-only ranking")
            s:set(0, 2, better, 2)
            if s.publish then s:publish() else s:bags() end
            s:advance(0.6)
            check(btn.ItemId == better and btn.WCount.value == "2", label .. " better carried item promotes using bag count")
            s:set(0, 2, better, 0)
            if s.publish then s:publish() else s:bags() end
            s:advance(0.6)
            check(btn.ItemId == id and btn.WCount.value == "3", label .. " stored-only better item releases to lower bag tier")

            s:set(0, 1, id, 0)
            if s.publish then s:publish() else s:bags() end
            s:advance(0.6)
            check(not btn.ItemId and not module._trackedItemID, label .. " last carried copy clears despite stored copies")
            if actualPotion then check(not actualPotion.testShown, label .. " actual empty potion module hides in Auto mode") end
            check(s.env.FluxNCConsumables.GetPhysicalItemCount(id) == 0, label .. " configured noncombat consumable clears at bag zero")
            ready, s.combat = false, true
            local combatWrites = s.writes
            s:set(0, 1, id, 2)
            if s.publish then s:publish() else s:bags() end
            s:advance(0.6)
            ready = true
            local beforeRequests = metadataRequests
            s.env.FluxItemClass.RequestLoad(id)
            s.env.FluxItemClass.OnItemDataEvent(id, true)
            s:advance(0.6)
            check(metadataRequests == beforeRequests + 1, label .. " metadata completion also wakes selector in combat")
            check(s.writes == combatWrites and module._pendingUpdate, label .. " combat queues action change without protected writes")
            s.combat = false
            s:event("PLAYER_REGEN_ENABLED")
            s:advance(0.6)
            check(btn.ItemId == id and btn.WCount.value == "2", label .. " reacquisition restores")
            if actualPotion then check(actualPotion.ItemId == id and actualPotion.testShown, label .. " actual potion module reappears after combat") end
            print(("SAMPLE %s %s %s recoveryScans=%d metadataRequests=%d"):format(family, provider, kind, settledScans - scans, metadataRequests))
        end
    end
end
print(("Consumable bag detection: %d checks, %d failures; native acceptance pending"):format(checks, failures))
assert(failures == 0, "consumable bag detection regression")
