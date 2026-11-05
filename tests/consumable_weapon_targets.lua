-- Desktop contract for configured consumables and equipped weapon targets.
local checks = 0
local function eq(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, (label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local source = assert(io.open(arg[1] or "ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua", "rb"))
local body = source:read("*a")
source:close()
local equipped = { [16] = 2001 }
local tooltipReads = {}
local frames = {}
local inCombat = false
local tooltip = {
    [1001] = "Use: Apply a temporary enchant to a staff.",
    [1002] = "Use: Apply a temporary enchant to your weapon.",
    [1003] = "Use: Drink this flask.",
    [1004] = "Use: Eat this food and become Well Fed.",
    [1005] = "Use: Drink this elixir.",
    [1006] = "Use: Apply a temporary enchant to a staff.",
}
local items = {
    [1001] = { name = "Staff Coating", class = 0 },
    [1002] = { name = "Simple Weapon Oil", class = 0 },
    [1003] = { name = "Flask of Testing", class = 0 },
    [1004] = { name = "Hearty Meal", class = 0 },
    [1005] = { name = "Elixir of Testing", class = 0 },
    [1006] = { name = "Unlisted Arcane Coating", class = 0 },
    [2001] = { name = "Dagger", class = 2, sub = 15, loc = "INVTYPE_WEAPON" },
    [2002] = { name = "Staff", class = 2, sub = 10, loc = "INVTYPE_2HWEAPON" },
    [2003] = { name = "Sword", class = 2, sub = 7, loc = "INVTYPE_WEAPON" },
}
local env = setmetatable({}, { __index = _G })
env._G = env
env.SlashCmdList = {}
env.CreateFrame = function()
    local frame = { events = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:RegisterUnitEvent(event) self.events[event] = true end
    function frame:SetScript(_, fn) self.onEvent = fn end
    frames[#frames + 1] = frame
    return frame
end
env.InCombatLockdown = function() return inCombat end
env.GetTime = function() return 100 end
env.GetInventorySlotInfo = function(name)
    return ({ MainHandSlot = 16, SecondaryHandSlot = 17, RangedSlot = 18 })[name]
end
env.GetInventoryItemID = function(_, slot) return equipped[slot] end
env.GetWeaponEnchantInfo = function() return nil end
env.GetItemInfo = function(id)
    local item = items[id]
    if not item then return nil end
    return item.name, "item:" .. id, 1, 1, 1,
        item.class == 2 and "Weapon" or "Consumable", item.name, 1, item.loc, 1
end
env.C_Item = {
    GetItemInfoInstant = function(id)
        local item = items[id]
        if not item then return nil end
        return id, "", "", item.loc, 1, item.class, item.sub
    end,
}
env.FluxFlyoutData = { ItemEnchantTemp = { [1001] = true, [1002] = true } }
env.FluxItemClass = {
    GetTooltipText = function(id)
        tooltipReads[id] = (tooltipReads[id] or 0) + 1
        return tooltip[id]
    end,
    GetRestore = function(id) return { ready = true, wellFed = id == 1004 } end,
}
env.Flux = { Inventory = { GetLiveCount = function(id) return id < 2000 and 4 or 0 end } }
local chunk = assert(load(body, "Consumables.lua", "t", env))
chunk("_FluxUI", {})
local cons = env.FluxNCConsumables

if arg[2] == "baseline" then
    eq(cons.CanEnchantApplyToSlot(1001, 16), true, "old broad melee rule accepts dagger")
    eq(cons.GetWeaponEnchantSlot(1001), 16, "old broad rule selects dagger")
    print("Baseline weapon target reproduction: " .. checks .. " checks passed")
    return
end

eq(cons.GetPhysicalItemCount(1001), 4, "physical coating count")
eq(cons.GetItemCount(1001), 0, "staff coating with dagger")
eq(cons.IsWeaponEnchantItem(1006), true, "unlisted staff coating detected from tooltip")
eq(cons.GetItemCount(1006), 0, "unlisted staff coating rejects dagger")
eq(cons.GetWeaponEnchantSlot(1001), nil, "staff coating has no dagger target")
local kind, target, nextTarget = cons.GetConsumableDescription(1001)
eq(kind, "Weapon enchant", "coating category")
eq(target, "Staff only", "specific weapon type")
eq(nextTarget, "None now", "no target label")

equipped[16] = 2002
eq(cons.GetItemCount(1001), 4, "staff coating with staff")
eq(cons.GetItemCount(1006), 4, "unlisted staff coating accepts staff")
eq(cons.GetWeaponEnchantSlot(1001), 16, "staff main hand target")
_, _, nextTarget = cons.GetConsumableDescription(1001)
eq(nextTarget, "Main hand", "main hand label")

equipped[16], equipped[17] = 2003, 2002
eq(cons.GetWeaponEnchantSlot(1001), 17, "compatible off hand wins")
eq(cons.GetItemCount(1001), 4, "compatible off hand count")
equipped[17] = nil
eq(cons.GetItemCount(1001), 0, "sword cannot take staff coating")

eq(cons.GetItemCount(1002), 4, "general oil accepts sword")
kind, target = cons.GetConsumableDescription(1002)
eq(kind, "Weapon enchant", "general oil category")
eq(target, "Melee weapon (specific type not detected)", "general target label")
eq(cons.GetItemCount(1003), 4, "flask count unchanged")
eq(cons.GetConsumableDescription(1003), "Flask", "flask category")
eq(cons.GetConsumableDescription(1004), "Well Fed food", "food category")
eq(cons.GetConsumableDescription(1005), "Elixir", "elixir category")
cons.GetItemCount(1003)
eq(tooltipReads[1003], 1, "ordinary flask classification cached")

equipped[16] = nil
eq(cons.GetItemCount(1001), 0, "empty weapon slot")
eq(cons.GetItemCount(1002), 0, "general oil has no weapon")
local updates = 0
cons.UpdateButtonState = function(force) if force then updates = updates + 1 end end
cons._registered, cons._button = true, {}
cons.RegisterEvents()
local eventFrame = frames[#frames]
eq(eventFrame.events.PLAYER_EQUIPMENT_CHANGED, true, "equipment event registered")
eventFrame.onEvent(eventFrame, "PLAYER_EQUIPMENT_CHANGED", 16)
eq(updates, 1, "main hand change refreshes selection")
eventFrame.onEvent(eventFrame, "PLAYER_EQUIPMENT_CHANGED", 17)
eq(updates, 2, "off hand change refreshes selection")
eventFrame.onEvent(eventFrame, "PLAYER_EQUIPMENT_CHANGED", 19)
eq(updates, 2, "unrelated equipment ignored")
inCombat = true
eventFrame.onEvent(eventFrame, "PLAYER_EQUIPMENT_CHANGED", 16)
eq(cons._pendingUpdate, true, "combat defers protected update")
print("Consumable weapon targets: " .. checks .. " checks passed")
