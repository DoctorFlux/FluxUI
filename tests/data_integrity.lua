-- Run from the addon root with Lua 5.4: lua tests/data_integrity.lua
-- These isolated fixtures exercise addon-owned behavior, not WoW secure APIs.
local passed = 0
local function check(value, message)
    assert(value, message)
    passed = passed + 1
end

local function environment()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.frames = {}
    env.CreateFrame = function()
        local frame = { events = {} }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:SetScript(_, fn) self.onEvent = fn end
        env.frames[#env.frames + 1] = frame
        return frame
    end
    env.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
    env.fire = function(event, ...)
        for _, frame in ipairs(env.frames) do
            if frame.events[event] then frame.onEvent(frame, event, ...) end
        end
    end
    return env
end

local function run(file, env)
    return assert(loadfile(file, "t", env))()
end

local SETTINGS = "Inventory/Restock/Core/FluxRestockSettings.lua"
local function settingsFixture(root, account)
    local env = environment()
    env._FluxUI_CharSavedVars = root
    env.FluxRestockDB = account
    run(SETTINGS, env)
    env.fire("ADDON_LOADED", "_FluxUI")
    return env, env.FluxRestockSettings.Get()
end

do
    local legacy = {
        autoRepair = true, autoRestock = false, repairPriority = "guild",
        restockItems = { [123] = { targetQuantity = 7, bankRestock = true } },
        junkList = { [321] = false },
        restockFoodWater = { foodTarget = 40, markInferiorFood = false },
        pendingVendorTierSell = { kinds = { food = { itemID = 123 } } },
        customFutureOption = "retained",
    }
    local bank = { [123] = 99 }
    local account = { targets = { [456] = 10 } }
    local root = { VendorAuto = legacy, bankSnapshot = bank, bankSnapshotTime = 88 }
    local env, current = settingsFixture(root, account)
    check(current.autoRepair == true and current.autoRestock == false, "legacy booleans preserved")
    check(current.repairPriority == "guild", "legacy repair priority preserved")
    check(current.restockItems[123].targetQuantity == 7, "legacy restock target preserved")
    check(current.junkList[321] == false, "explicit junk protection preserved")
    check(current.restockFoodWater.foodTarget == 40 and current.restockFoodWater.markInferiorFood == false,
        "tier preferences preserved")
    check(root.VendorAuto == legacy and legacy.customFutureOption == "retained", "legacy source retained intact")
    check(root.bankSnapshot == bank and root.bankSnapshotTime == 88, "bank snapshot retained")
    check(current.bankSnapshot == nil and next(current.pendingVendorTierSell.kinds) == nil,
        "stale bank facts and vendor work not imported")
    check(env.FluxRestockDB == account and root._restockMigrationV1.legacyAccount.targets[456] == 10,
        "undeclared account legacy retained and archived")
    current.restockItems[123].targetQuantity = 3
    check(legacy.restockItems[123].targetQuantity == 7, "import has no writable alias to legacy")
    legacy.restockItems[123].targetQuantity = 22
    env.FluxRestockSettings.Get()
    env.fire("ADDON_LOADED", "_FluxUI")
    check(current.restockItems[123].targetQuantity == 3, "migration is idempotent")
    check(root._restockMigrationV1.version == 1 and root._restockMigrationV1.imported,
        "migration checkpoint versioned")
end

do
    local current = {
        autoRepair = false, autoRestock = false,
        restockItems = { [123] = { targetQuantity = 3 } },
        bankSnapshot = { [123] = 4 }, bankSnapshotTime = 77,
        unknownSetting = { preserved = true },
    }
    local root = { Restock = current, VendorAuto = {
        autoRepair = true, restockItems = { [123] = { targetQuantity = 7 }, [456] = { targetQuantity = 9 } },
    }, Bank = { tabs = { "Forever topology" } } }
    local _, actual = settingsFixture(root)
    check(actual == current and actual.autoRepair == false, "current store identity and choices authoritative")
    check(actual.restockItems[123].targetQuantity == 3 and actual.restockItems[456] == nil,
        "stale targets cannot resurrect in current settings")
    check(actual.bankSnapshot[123] == 4 and actual.bankSnapshotTime == 77, "nested legacy snapshot retained")
    check(actual.unknownSetting.preserved and root.Bank.tabs[1] == "Forever topology", "unknown options and bank topology intact")
end

do
    local root = { VendorAuto = {
        autoRepair = "true", repairPriority = {}, restockItems = {
            bad = { targetQuantity = 10 }, [123] = true,
            [456] = { targetQuantity = -4, countBank = "yes" },
            [789] = { targetQuantity = 6 }, ["789"] = { targetQuantity = 9 },
        },
        junkFilters = "bad", junkList = { [123] = "false", ["321"] = false },
        alreadyKnown = { r = math.huge },
    } }
    local _, actual = settingsFixture(root)
    check(actual.autoRepair == false and actual.repairPriority == "personal", "malformed scalar preferences rejected")
    check(actual.restockItems.bad == nil and actual.restockItems[123] == nil, "malformed rows rejected")
    check(actual.restockItems[456].targetQuantity == nil and actual.restockItems[456].countBank == nil,
        "invalid target and flag not activated")
    check(actual.restockItems[789].targetQuantity == 6, "numeric item key deterministically wins")
    check(actual.junkList[321] == false and actual.junkList[123] == nil, "junk list validated")
    check(actual.alreadyKnown.r == 0 and type(actual.junkFilters) == "table", "invalid nested fields use defaults")
    check(root.VendorAuto.autoRepair == "true" and root.VendorAuto.restockItems[123] == true,
        "rejected originals retained for recovery")
    local broken = { Restock = "recover me" }
    settingsFixture(broken)
    check(broken._restockMigrationV1.previousRestock == "recover me", "malformed current root archived before repair")
end

local LOADER = "BaganatorCompat/Loader.lua"
do
    local env = environment()
    env.Baganator = { API = {} }
    env.FluxRespec = { GearSetLock = {}, GearSetIndex = {}, Inv = {} }
    env.Flux = { Inventory = {} }
    local nativeGUID = function() return "trade-good-guid" end
    local nativeExists = function() return true end
    env.C_Item = { GetItemGUID = nativeGUID, DoesItemExist = nativeExists }
    run(LOADER, env)
    check(env.C_Item.GetItemGUID == nativeGUID and env.C_Item.DoesItemExist == nativeExists,
        "Blizzard item APIs retain native ownership")
    check(env.C_Item.GetItemGUID({ bagID = 0, slotIndex = 1 }) == "trade-good-guid",
        "non-gear GUID semantics preserved")
end

do
    local env = environment()
    env.Baganator = { API = {} }
    env.FluxBaganatorCompat = {}
    run(LOADER, env)
    local frames = #env.frames
    env.FluxBaganatorCompat.Init()
    env.FluxBaganatorCompat.Init()
    check(#env.frames == frames, "only one dependency wait frame")
    env.FluxRespec = { GearSetLock = {}, GearSetIndex = {}, Inv = {} }
    env.Flux = { Inventory = {} }
    local attempts = 0
    env.FluxBaganatorCompat.InitProtection = function()
        attempts = attempts + 1
        if attempts == 1 then error("fixture initialization failure") end
    end
    check(not pcall(env.FluxBaganatorCompat.Init) and not env.FluxBaganatorCompat._initialized,
        "failed initialization stays retryable")
    env.FluxBaganatorCompat.Init()
    check(env.FluxBaganatorCompat._initialized and attempts == 2, "initialization retries successfully")
    env.fire("PLAYER_LOGIN")
    check(attempts == 2, "successful early initialization cancels stale dependency waiter")
end

do
    local env = environment()
    env.Baganator = { API = {} }
    env.IsLoggedIn = function() return true end
    run(LOADER, env)
    check(env.FluxBaganatorCompat._initialized, "late optional load does not wait for a past login event")
end

-- Same fixture can run the pre-change source to capture native-query counts:
-- lua tests/data_integrity.lua path/to/baseline-gearsets.lua
local function gearQueryCounts(source)
    local env = environment()
    local guidCalls, existsCalls, refreshes = 0, 0, 0
    local sourceLookup, sourceNames
    local entry = { sourceKind = "profile", sourceName = "Raid", want = { itemID = 100042 } }
    env._FluxUI_CharSavedVars = { respec = { profiles = { Raid = {} } } }
    env.FluxRespec = {
        GearSetIndex = {
            AreAllocationsFresh = function() return true end,
            GetEntriesForItemID = function(id) if id == 100042 then return { entry } end end,
            IsBagSlotAllocatedForEntry = function(_, slot) return slot == 42 end,
        },
        Inv = {
            GetItemID = function(_, slot) return 100000 + slot end,
            ForEachLocation = function(fn) for slot = 1, 100 do fn({ bag = 0, slot = slot }) end end,
        },
    }
    env.ItemLocation = {
        CreateFromEquipmentSlot = function(_, slot) return { equipmentSlotIndex = slot } end,
        CreateFromBagAndSlot = function(_, bag, slot) return { bagID = bag, slotIndex = slot } end,
    }
    env.C_Item = {
        DoesItemExist = function(loc) existsCalls = existsCalls + 1; return loc.slotIndex ~= nil end,
        GetItemGUID = function(loc) guidCalls = guidCalls + 1; return "GUID-" .. loc.slotIndex end,
    }
    env.Baganator = { API = { RegisterItemSetSource = function(_, _, lookup, names)
        sourceLookup, sourceNames = lookup, names
    end } }
    env.FluxBaganatorCompat = { RequestBaganatorRefresh = function() refreshes = refreshes + 1 end }
    run(source, env)
    env.FluxBaganatorCompat.InitGearSets()
    check(refreshes == 1, "gear mapping refresh produced")
    check(sourceLookup(nil, "GUID-42")[1].name == "Raid" and sourceNames()[1] == "Raid",
        "native GUID still resolves the saved Respec set")
    check(sourceLookup(nil, "GUID-41") == nil, "unmatched GUID is not added to a set")
    guidCalls, existsCalls = 0, 0
    env.FluxBaganatorCompat.RebuildGearSetInfo()
    env.FluxBaganatorCompat.RebuildGearSetInfo()
    check(refreshes == 1, "unchanged gear map skips repeated layout refresh")
    return guidCalls / 2, existsCalls / 2
end

local guids, exists = gearQueryCounts("BaganatorCompat/FluxBaganator_GearSets.lua")
check(guids == 1 and exists == 1, "only matched set slots query native identity")
print(("PASS: %d data-integrity checks; gear rebuild: %d GUID + %d existence queries (100 bag slots)")
    :format(passed, guids, exists))
if arg and arg[1] then
    local beforeGUID, beforeExists = gearQueryCounts(arg[1])
    print(("Baseline gear rebuild: %d GUID + %d existence queries; candidate: %d + %d")
        :format(beforeGUID, beforeExists, guids, exists))
end
