-- lua tests/owned_item_detection.lua
-- Real item metadata, tooltip classifier and mount-item selection. Reproduces
-- the reported Era counts/class pairs with empty hyperlink tooltip responses.
local checks = 0
local function eq(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local specs = {
    [18772] = { name = "Swift Green Mechanostrider", class = 15, text = "Use: Summons and dismisses a rideable Swift Green Mechanostrider. This is a very fast mount." },
    [22895] = { name = "Conjured Cinnamon Roll", class = 0, text = "Use: Restores 2148 health over 30 sec. Must remain seated while eating." },
    [8079] = { name = "Conjured Crystal Water", class = 0, text = "Use: Restores 4200 mana over 30 sec. Must remain seated while drinking." },
    [13446] = { name = "Major Healing Potion", class = 0, text = "Use: Restores 1050 to 1750 health." },
    [13444] = { name = "Major Mana Potion", class = 0, text = "Use: Restores 1350 to 2250 mana." },
}
for _, mode in ipairs({ "modern-bag", "legacy-bag", "hyperlink" }) do
    local env = setmetatable({}, { __index = _G }); env._G = env
    local slots, unique, ready, reads = {}, {}, false, 0
    local locByID, loaded = {}, {}
    for id, spec in pairs(specs) do
        local slot = #slots + 1; slots[slot] = id
        locByID[id] = { bag = 0, slot = slot }
        unique[id] = { bag = 0, slot = slot, count = id == 18772 and 1 or 20 }
    end
    env.Flux = { Inventory = {
        GetFirst = function(id, opts)
            assert(opts.bags and not opts.bank and not opts.warband, "bag tooltip query escaped carried bags")
            return locByID[id]
        end,
        GetUniqueItems = function() return unique end,
        GetBagGeneration = function() return 1 end,
    } }
    env.GetTime = function() return 10 end
    env.UnitHealthMax = function() return 4000 end
    env.UnitPowerMax = function() return 6000 end
    env.InCombatLockdown = function() return false end
    env.wipe = function(t) for key in pairs(t) do t[key] = nil end; return t end
    local function info(id)
        local spec = specs[id]
        if not spec then return end
        return spec.name, "item:" .. id, 1, 1, 1, "Item", "Other", 20, "", 1, 0, spec.class, 0
    end
    env.GetItemInfo = info
    env.GetItemInfoInstant = function(id) return id, "Item", "Other", "", 1, specs[id].class, 0 end
    env.GetItemIcon = function() return 1 end
    env.C_Item = { GetItemInfo = function() return nil end, -- modern metadata still cold, legacy complete
        GetItemInfoInstant = env.GetItemInfoInstant, RequestLoadItemDataByID = function(id) loaded[id] = true end }
    local function tooltip(id)
        return { lines = { { leftText = specs[id].name }, { leftText = specs[id].text } } }
    end
    env.C_TooltipInfo = {
        GetHyperlink = function(link)
            if mode == "hyperlink" and ready then return tooltip(tonumber(link:match("item:(%d+)"))) end
        end,
        GetBagItem = mode == "modern-bag" and function(bag, slot)
            reads = reads + 1; assert(bag == 0)
            if ready then return tooltip(slots[slot]) end
        end or nil,
    }
    env.CreateFrame = function(kind)
        local f = {}
        function f:RegisterEvent() end
        function f:SetScript() end
        if kind == "GameTooltip" then
            function f:SetOwner() end
            function f:ClearLines() self.lines = 0 end
            function f:SetHyperlink() self.lines = 0 end
            function f:SetBagItem(bag, slot)
                reads = reads + 1; assert(bag == 0)
                if mode == "legacy-bag" and ready then
                    self.lines = 2
                    env.FluxItemClassScanTooltipTextLeft2 = { GetText = function() return specs[slots[slot]].text end }
                end
            end
            function f:NumLines() return self.lines or 0 end
        end
        return f
    end
    local function load(path)
        local fn
        if setfenv then fn = assert(loadfile(path)); setfenv(fn, env)
        else fn = assert(loadfile(path, "t", env)) end
        return fn()
    end
    local IC = load("Inventory/FluxItemClass.lua")
    local C = load("Inventory/FluxConsumableClassify.lua")
    local mounts = load("ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua")
    eq(IC.GetInfo(18772).name, specs[18772].name, "legacy metadata survives empty modern API")
    eq(IC.GetTooltipText(22895), nil, "cold tooltip is unresolved")
    eq(mounts.GetBestAvailableMount(), nil, "cold mount tooltip is unresolved")
    eq(loaded[18772], true, "subclass-zero mount requests missing data")
    ready = true
    local expected = { [22895] = "food", [8079] = "water", [13446] = "healPotion", [13444] = "manaPotion" }
    for id, kind in pairs(expected) do
        IC.OnItemDataLoaded(id); C.ResetParseBudget()
        local result = C.Classify(id)
        eq(result and result.kind, kind, mode .. " real " .. kind .. " classification")
    end
    mounts.InvalidateCache()
    eq(mounts.GetBestAvailableMount().itemId, 18772, mode .. " real subclass-zero mount detection")
    if mode ~= "hyperlink" then eq(reads > 0, true, "owned bag tooltip path used") end
end
print("Owned item detection passed: " .. checks .. " checks")
