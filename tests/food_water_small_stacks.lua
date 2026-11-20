-- Exercise the loaded button refresh and click hooks with physical bag slots.
local env = setmetatable({}, { __index = _G })
env._G = env
local timers, listeners = {}, {}
local combat, cursor, hold = false, false, false
local swap = {}
env.InCombatLockdown = function() return combat end
env.CursorHasItem = function() return cursor end
env.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
env.FluxOptions = { GetActionbarsDB = function() return { consumableCombatSwap = swap } end }

local function frame()
    local w = { attrs = {}, scripts = {} }
    function w:RegisterEvent() end
    function w:SetScript(key, fn) self.scripts[key] = fn end
    function w:HookScript(key, fn) self.scripts[key] = fn end
    function w:GetAttribute(key) return self.attrs[key] end
    function w:SetAttribute(key, value)
        assert(not combat, "protected write in combat")
        self.attrs[key] = value
    end
    return w
end
env.CreateFrame = frame

local inventory = { snapshots = { bags = {} } }
local live = {}
local reads = 0
function inventory.GetLiveCount(id)
    local total = 0
    for _, slots in pairs(live) do
        for _, item in pairs(slots) do
            if item.itemID == id then total = total + item.stackCount end
        end
    end
    return total
end
inventory.IsReliable = function() return not hold end
inventory.Containers = { GetCarriedBagIDs = function() return { 0, 1 } end }
inventory.RegisterListener = function(key, fn) listeners[key] = fn end
env.FluxInv = inventory
env.Flux = {
    Inventory = inventory,
    Container = {
        GetNumSlots = function() return 4 end,
        GetItemInfo = function(bag, slot)
            reads = reads + 1
            return live[bag] and live[bag][slot]
        end,
    },
}

local function stack(id, n, locked)
    return { itemID = id, stackCount = n, isLocked = locked }
end
local function publish(bags)
    live = bags
    local snapshot = {}
    for bag, slots in pairs(live) do
        snapshot[bag] = {}
        for slot, item in pairs(slots) do
            snapshot[bag][slot] = { itemID = item.itemID, count = item.stackCount }
        end
    end
    inventory.snapshots.bags.byBag = snapshot
end

local function loadAddon(path)
    return assert(loadfile(path, "t", env))("_FluxUI", {})
end
loadAddon("Inventory/FluxConsumableBest/Score.lua")
loadAddon("ExtraButtonSystem/Engine/ConsumableBind.lua")
local best = env.FluxConsumableBest
local score = best.Score
local bridge = env.FluxEBSConsumableBridge
local blocked = {}
score.IsBlockedForBest = function(id) return blocked[id] end
best.IsValidKind = function() return true end
best.ShouldSoftHoldOwned = function() return hold end
local function item(id, kind, strength, conjured, mana)
    return { itemID = id, kind = kind, effective = strength, isConjured = conjured,
        maxStack = 20, health = kind == "food" and strength or nil, mana = mana }
end
local foodA, foodB, weakFood, conjuredFood =
    item(10, "food", 1000), item(11, "food", 1000), item(12, "food", 500), item(13, "food", 700, true)
local waterA, waterB = item(20, "water", 1000, false, 1000), item(21, "water", 1000, false, 1000)
local comboA, comboB = item(40, "food", 400, true, 900), item(41, "food", 600, true, 900)
local potion = item(30, "healPotion", 1000)
local candidates = { food = { foodA, foodB, weakFood, conjuredFood }, water = { waterA, waterB }, healPotion = { potion } }
best.GetLadder = function(kind, opts)
    local out = {}
    for _, rec in ipairs(candidates[kind] or {}) do
        if inventory.GetLiveCount(rec.itemID) > 0 and not blocked[rec.itemID] then out[#out + 1] = rec end
    end
    table.sort(out, function(a, b) return score.IsBetter(a, b, opts) end)
    return out
end
best.GetBest = function(kind) return best.GetLadder(kind)[1] end

local function attach(kind)
    local module, btn = {}, { Widget = frame() }
    function btn:SetAction(typ, value)
        self.ActionType, self.ActionValue = typ, value
        self.Widget:SetAttribute("item", typ == "item" and "item:" .. value or nil)
    end
    env.FluxEBSButtonRefresh.Attach({ module = module, btn = btn, kind = kind, listenerKey = kind })
    return module, btn
end
local function click(btn, button, attr, expected)
    local w = btn.Widget
    local before = w:GetAttribute(attr)
    w.scripts.PreClick(w, button, true)
    assert(w:GetAttribute(attr) == expected, tostring(w:GetAttribute(attr)) .. " expected " .. tostring(expected))
    w.scripts.PostClick(w, button, true)
    assert(w:GetAttribute(attr) == before, "restore the persistent button action")
end
local function flush()
    local pending = timers
    timers = {}
    for _, fn in ipairs(pending) do fn() end
end

publish({ [0] = { stack(10, 16), stack(11, 4), stack(12, 1) }, [1] = { stack(20, 18), stack(21, 2) } })
local food, foodButton = attach("food")
local water, waterButton = attach("water")
assert(food._trackedItemID == 11 and water._trackedItemID == 21, "smaller equal-tier stack owns each button")
assert(bridge.GetBestOwned("food").itemID == 10, "general best-item ranking stays available")
assert(reads == 0, "button updates use snapshot records")
click(foodButton, "LeftButton", "item", "0 2")
click(waterButton, "KeyBind", "item", "1 2")
click(foodButton, "RightButton", "item", "item:11")
click(foodButton, "ConjureBind", "item", "item:11")
click(foodButton, "MiddleButton", "item", "item:11")
local pressReads = reads
foodButton.Widget.scripts.PreClick(foodButton.Widget, "LeftButton", false)
assert(reads == pressReads and foodButton.Widget:GetAttribute("item") == "item:11", "release skips stack lookup")

publish({ [0] = { stack(10, 20), stack(11, 20), stack(11, 10), stack(12, 1) } })
food.Update()
assert(food._trackedItemID == 11 and food._latchCount == 30, "physical stack ranking keeps total display stock")
click(foodButton, "LeftButton", "item", "0 3")
-- Reorder live slots before the inventory provider publishes the move.
live[0][3], live[1] = stack(12, 1), { stack(11, 10) }
click(foodButton, "LeftButton", "item", "1 1")
live[1][1].isLocked = true
click(foodButton, "LeftButton", "item", "0 1")

publish({ [0] = { stack(10, 18), stack(10, 2), stack(11, 20), stack(11, 10) } })
flush()
listeners.food({ regions = { bags = true }, touchedItemIDs = { [99] = true }, changedItemIDs = {} })
assert(#timers == 0, "unrelated bag moves skip button selection work")
listeners.food({ regions = { bags = true }, touchedItemIDs = { [10] = true }, changedItemIDs = {} })
flush()
assert(food._trackedItemID == 10, "count-neutral split promotes the newly smallest stack")

publish({ [0] = { stack(11, 20), stack(11, 10), stack(12, 1), stack(13, 20) } })
food.Update()
assert(food._trackedItemID == 13, "conjured tier stays first")
click(foodButton, "LeftButton", "item", "0 4")
blocked[13] = true
food.Update()
assert(food._trackedItemID == 11, "unusable conjured food is skipped")
click(foodButton, "LeftButton", "item", "0 2")

combat = true
click(foodButton, "LeftButton", "item", "item:11")
combat, cursor = false, true
click(foodButton, "LeftButton", "item", "item:11")
cursor, hold = false, true
click(foodButton, "LeftButton", "item", "item:11")
hold = false

-- Existing combat swap macros keep the potion side and target the food stack
-- only on the out-of-combat side of the current click.
publish({ [0] = { stack(10, 20), stack(11, 20), stack(11, 10), stack(30, 2) } })
swap.foodWater, swap.potions = true, true
food.Update()
local _, potionButton = attach("healPotion")
local swapClick = "/use [combat] item:30\n/use [nocombat] 0 3"
click(foodButton, "LeftButton", "macrotext", swapClick)
click(potionButton, "KeyBind", "macrotext", swapClick)
combat = true
click(foodButton, "LeftButton", "macrotext", foodButton._fluxCombatSwapBody)
combat = false

-- Recuperate mode permits combo food for water and compares its mana strength.
env.FluxNCFood = { HasRecuperate = function() return true end, GetPreferRecuperate = function() return true end }
candidates.water = { waterA, comboA, comboB }
publish({ [0] = { stack(40, 3), stack(41, 18), stack(20, 1) } })
water.Update()
assert(water._trackedItemID == 40, "equal mana combo drinks prefer the smaller stack")
click(waterButton, "LeftButton", "macrotext", "/use [nocombat] 0 1")
print("Food and water use the smallest eligible physical stack")
