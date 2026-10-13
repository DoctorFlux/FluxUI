-- FluxBaganator_GearSets.lua
-- Maps Flux Respec profiles/presets into Baganator equipment-set categories.

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local equipmentSetInfo = {}
local equipmentSetNames = {}
local categoryIcons = {}
local fluxManagedSetNames = {}

-- Double buffer: a rebuild fills the spare table so it can be compared against
-- the live one. Baganator only needs a layout pass when the map actually moved.
local spareSetInfo = {}

local function GetRespec()
    return _G.FluxRespec
end

--- New inventory facts (Syndicator or builtin). Never the unused FluxInv scanner.
local function GetRespecInv()
    local R = GetRespec()
    return R and R.Inv
end

local function GetContainer()
    local Flux = _G.Flux
    return Flux and Flux.Container
end

local function GetBagItemID(bag, slot)
    local ri = GetRespecInv()
    if ri and ri.GetItemID then
        local id = tonumber(ri.GetItemID(bag, slot))
        if id and id > 0 then
            return id
        end
    end
    local C = GetContainer()
    if C and C.GetItemID then
        local id = tonumber(C.GetItemID(bag, slot))
        if id and id > 0 then
            return id
        end
    end
    return nil
end

local function EquipmentSlotMax()
    local R = GetRespec()
    local equip = R and R.Equipment
    if equip and equip.GetSlotMax then
        return equip.GetSlotMax()
    end
    return _G.INVSLOT_LAST_EQUIPPED or 19
end

function Compat.GetCategoryIcon(setName)
    if not setName then
        return nil
    end
    return categoryIcons[setName]
end

function Compat.IsFluxManagedSetName(setName)
    if not setName or setName == "" then
        return false
    end
    return fluxManagedSetNames[setName] == true
end

function Compat.IsFluxRespecCategorySourceKey(sourceKey)
    if type(sourceKey) ~= "string" then
        return false
    end
    local prefix = "default_auto_equipment_sets_"
    if sourceKey:sub(1, #prefix) ~= prefix then
        return false
    end
    local rest = sourceKey:sub(#prefix + 1)
    local bestLen = 0
    local matched = false
    for setName in pairs(fluxManagedSetNames) do
        if #setName > bestLen and rest:sub(1, #setName) == setName then
            local nextChar = rest:sub(#setName + 1, #setName + 1)
            if nextChar == "" or nextChar == "_" then
                bestLen = #setName
                matched = true
            end
        end
    end
    return matched
end

local function BuildSetNameList()
    local names = {}
    local seen = {}
    local root = _G._FluxUI_CharSavedVars
    if type(root) ~= "table" then
        return names
    end

    local respec = root.respec
    if type(respec) == "table" and type(respec.profiles) == "table" then
        for name in pairs(respec.profiles) do
            if name and not seen[name] then
                seen[name] = true
                names[#names + 1] = name
            end
        end
    end

    local presetStore = root.equipmentPresets
    if type(presetStore) == "table" and type(presetStore.presets) == "table" then
        for name in pairs(presetStore.presets) do
            if name and name ~= "default" and not seen[name] then
                seen[name] = true
                names[#names + 1] = name
            end
        end
    end

    table.sort(names, function(a, b)
        return (a or ""):lower() < (b or ""):lower()
    end)
    return names
end

local function RebuildFluxManagedSetNames()
    wipe(fluxManagedSetNames)
    local names = BuildSetNameList()
    for i = 1, #names do
        local name = names[i]
        if name then
            fluxManagedSetNames[name] = true
        end
    end
end

local function GetPresetCategoryIcon(presetName)
    local R = GetRespec()
    if not R or not R.EquipmentPresets or not R.EquipmentPresets.GetPreset then
        return nil
    end
    local preset = R.EquipmentPresets.GetPreset(presetName)
    local equipment = preset and preset.equipment
    if type(equipment) ~= "table" then
        return nil
    end
    local slotMax = EquipmentSlotMax()
    for invSlot = 1, slotMax do
        local want = equipment[invSlot]
        if want and want.itemID and not want.empty then
            if C_Item and C_Item.GetItemInfoInstant then
                local _, _, _, _, icon = C_Item.GetItemInfoInstant(want.itemID)
                if icon then
                    return icon
                end
            end
        end
    end
    if R.DefaultIcon then
        return R.DefaultIcon()
    end
end

local function RebuildCategoryIcons()
    wipe(categoryIcons)
    local R = GetRespec()
    if not R then
        return
    end

    if R.GetProfileNames and R.GetIcon then
        local names = R.GetProfileNames()
        for i = 1, #names do
            local name = names[i]
            if name then
                categoryIcons[name] = R.GetIcon(name)
            end
        end
    end

    local presetStore = _G._FluxUI_CharSavedVars and _G._FluxUI_CharSavedVars.equipmentPresets
    if type(presetStore) == "table" and type(presetStore.presets) == "table" then
        for name in pairs(presetStore.presets) do
            if name and name ~= "default" and not categoryIcons[name] then
                categoryIcons[name] = GetPresetCategoryIcon(name)
            end
        end
    end
end

local function AppendSetInfo(bucket, entry)
    if not entry or not entry.sourceName then
        return
    end
    for i = 1, #bucket do
        if bucket[i].name == entry.sourceName then
            return
        end
    end
    bucket[#bucket + 1] = { name = entry.sourceName }
end

local function CollectMatchesForSlot(kind, bag, invSlot, profiles, presets)
    local R = GetRespec()
    local index = R and R.GearSetIndex
    if not index or not index.GetEntriesForItemID then
        return
    end

    -- Ensure allocations exist before GUID→set mapping (cheap itemID pass).
    if index.RefreshAllocations and index.AreAllocationsFresh
        and not index.AreAllocationsFresh() then
        index.RefreshAllocations()
    end

    local itemID
    if kind == "inv" then
        itemID = GetInventoryItemID and GetInventoryItemID("player", invSlot)
    else
        itemID = GetBagItemID(bag, invSlot)
    end
    itemID = tonumber(itemID)
    if not itemID or itemID == 0 then
        return
    end

    local bucket = index.GetEntriesForItemID(itemID)
    if not bucket then
        return
    end

    for i = 1, #bucket do
        local entry = bucket[i]
        local want = entry.want
        if want and want.itemID and not want.empty then
            local matches = false
            if kind == "inv" then
                matches = index.IsInventorySlotAllocatedForEntry
                    and index.IsInventorySlotAllocatedForEntry(invSlot, entry)
            else
                matches = index.IsBagSlotAllocatedForEntry
                    and index.IsBagSlotAllocatedForEntry(bag, invSlot, entry)
            end
            if matches then
                if entry.sourceKind == "profile" then
                    AppendSetInfo(profiles, entry)
                else
                    AppendSetInfo(presets, entry)
                end
            end
        end
    end
end

local function MergeSetInfo(bucket, info)
    if not info or not info.name then
        return
    end
    for i = 1, #bucket do
        if bucket[i].name == info.name then
            return
        end
    end
    bucket[#bucket + 1] = info
end

local function AssignGuidSetInfo(guid, profiles, presets)
    if not guid or (#profiles == 0 and #presets == 0) then
        return
    end
    local bucket = equipmentSetInfo[guid]
    if not bucket then
        bucket = {}
        equipmentSetInfo[guid] = bucket
    end
    for i = 1, #profiles do
        MergeSetInfo(bucket, profiles[i])
    end
    for i = 1, #presets do
        MergeSetInfo(bucket, presets[i])
    end
end

--- Same GUIDs mapped to the same set names? Then nothing visible changed.
local function SetInfoEquals(a, b)
    for guid, bucketA in pairs(a) do
        local bucketB = b[guid]
        if not bucketB or #bucketB ~= #bucketA then
            return false
        end
        for i = 1, #bucketA do
            local found = false
            for j = 1, #bucketB do
                if bucketA[i].name == bucketB[j].name then
                    found = true
                    break
                end
            end
            if not found then
                return false
            end
        end
    end
    for guid in pairs(b) do
        if not a[guid] then
            return false
        end
    end
    return true
end

local function NameListEquals(a, b)
    if #a ~= #b then
        return false
    end
    for i = 1, #a do
        if a[i] ~= b[i] then
            return false
        end
    end
    return true
end

local function ScanInventorySlot(invSlot)
    if not C_Item or not ItemLocation then
        return
    end
    local location = ItemLocation:CreateFromEquipmentSlot(invSlot)
    if not location or not C_Item.DoesItemExist or not C_Item.DoesItemExist(location) then
        return
    end
    local guid = C_Item.GetItemGUID(location)
    if not guid then
        return
    end
    local profiles = {}
    local presets = {}
    CollectMatchesForSlot("inv", nil, invSlot, profiles, presets)
    AssignGuidSetInfo(guid, profiles, presets)
end

local function ScanBagSlot(bag, slot)
    if not C_Item or not ItemLocation then
        return
    end
    local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if not location or not C_Item.DoesItemExist or not C_Item.DoesItemExist(location) then
        return
    end
    local guid = C_Item.GetItemGUID(location)
    if not guid then
        return
    end
    local profiles = {}
    local presets = {}
    CollectMatchesForSlot("bag", bag, slot, profiles, presets)
    AssignGuidSetInfo(guid, profiles, presets)
end

function Compat.RebuildGearSetInfo()
    if not GetRespec() then
        return
    end

    -- Build into the spare table so the result can be diffed against the live map.
    local previousSetInfo = equipmentSetInfo
    equipmentSetInfo = wipe(spareSetInfo)
    spareSetInfo = previousSetInfo

    local previousNames = equipmentSetNames
    equipmentSetNames = BuildSetNameList()
    RebuildFluxManagedSetNames()
    RebuildCategoryIcons()

    local R = GetRespec()
    local index = R and R.GearSetIndex
    -- GearSetLock often refreshed allocations on the same pulse; skip duplicate
    -- tooltip-heavy RefreshAllocations when bag/bank gens are still fresh.
    if index and index.RefreshAllocations then
        if not (index.AreAllocationsFresh and index.AreAllocationsFresh()) then
            index.RefreshAllocations()
        end
    end

    local slotMax = EquipmentSlotMax()
    for invSlot = 1, slotMax do
        ScanInventorySlot(invSlot)
    end

    -- Bags plus open bank/warband. Closed-bank IDs must not be walked.
    local ri = GetRespecInv()
    if ri and ri.ForEachLocation then
        ri.ForEachLocation(function(loc)
            if loc and loc.bag ~= nil and loc.slot then
                ScanBagSlot(loc.bag, loc.slot)
            end
        end, "all")
    end

    -- A full Baganator layout pass is expensive. Only ask for one when the
    -- GUID map or the set list actually moved, not on every bag count change.
    if SetInfoEquals(previousSetInfo, equipmentSetInfo)
        and NameListEquals(previousNames, equipmentSetNames) then
        return
    end

    Compat.RequestBaganatorRefresh(true)
    local api = _G.Baganator and _G.Baganator.API
    if api and api.RequestLayoutUpdate then
        api.RequestLayoutUpdate()
    end
end

local rebuildTimer

--- Did anything equippable move? A looted stack of ore cannot change which item
--- belongs to a gear set, and this rebuild costs a GetItemGUID per occupied slot.
local function HasEquippableMovement(ctx)
    if not ctx then
        return false
    end
    local IsEquippableItem = (C_Item and C_Item.IsEquippableItem) or _G.IsEquippableItem
    if not IsEquippableItem then
        return true
    end
    local function scan(ids)
        if not ids then
            return false
        end
        for id in pairs(ids) do
            id = tonumber(id)
            if id and IsEquippableItem(id) then
                return true
            end
        end
        return false
    end
    if scan(ctx.addedItemIDs) or scan(ctx.removedItemIDs) then
        return true
    end
    -- Identity changed but no ID metadata: rebuild rather than go stale.
    if ctx.changeKind == "identityChanged"
        and not ctx.addedItemIDs and not ctx.removedItemIDs then
        return true
    end
    return false
end

local function InventoryPulseWantsRebuild(ctx)
    if not ctx then
        return true
    end
    if ctx.force then
        return true
    end
    -- Stack sizes moved but the same item IDs are present: gear identity is
    -- unchanged, so the GUID map cannot have moved.
    if ctx.changeKind == "countOnly" then
        return false
    end
    local regions = ctx.regions
    if not regions then
        return true
    end
    if regions.equip or regions.equipped then
        return true
    end
    if regions.bags or regions.bank or regions.warband then
        return HasEquippableMovement(ctx)
    end
    return false
end

local function ScheduleGearSetRebuild()
    if rebuildTimer and rebuildTimer.Cancel then
        rebuildTimer:Cancel()
        rebuildTimer = nil
    end
    if C_Timer and C_Timer.NewTimer then
        rebuildTimer = C_Timer.NewTimer(0.12, function()
            rebuildTimer = nil
            Compat.RebuildGearSetInfo()
        end)
        return
    end
    Compat.RebuildGearSetInfo()
end

function Compat.InitGearSets()
    local api = _G.Baganator and _G.Baganator.API
    if not api or not api.RegisterItemSetSource or Compat._gearSetsInitialized then
        return
    end
    Compat._gearSetsInitialized = true

    api.RegisterItemSetSource("Flux Respec", "flux_respec", function(_, guid)
        return equipmentSetInfo[guid]
    end, function()
        return equipmentSetNames
    end)

    local R = GetRespec()
    if R and R.On then
        R.On("GEAR_SET_INDEX_CHANGED", ScheduleGearSetRebuild)
        -- GEAR_SET_LOCK_CHANGED only means protected *slots* moved; GUID→set maps
        -- are unchanged, so do not rebuild (avoids Layout refresh on every gear move).
        R.On("PROFILE_SAVED", ScheduleGearSetRebuild)
        R.On("PROFILE_CREATED", ScheduleGearSetRebuild)
        R.On("PROFILE_DELETED", ScheduleGearSetRebuild)
        R.On("PROFILE_RENAMED", ScheduleGearSetRebuild)
        R.On("PROFILE_UPDATED", ScheduleGearSetRebuild)
        R.On("EQUIPMENT_PRESET_SAVED", ScheduleGearSetRebuild)
        R.On("EQUIPMENT_PRESET_CHANGED", ScheduleGearSetRebuild)
    end

    -- Cold login: bags may still be empty on first rebuild; refresh when Flux
    -- inventory facts change (same pulse GearSetLock uses). Bank open/close
    -- arrives as ctx.force from FluxRespec_Inv.EnsureBankWatch.
    local ri = GetRespecInv()
    if ri and ri.Register and not Compat._gearSetsInvListener then
        Compat._gearSetsInvListener = true
        -- Scan tier: at the bank this runs once per burst of moves (settle pulse),
        -- not on every drag.
        ri.Register("FluxBaganatorGearSets", function(ctx)
            if InventoryPulseWantsRebuild(ctx) then
                ScheduleGearSetRebuild()
            end
        end, {
            tier = "scan",
            regions = { "bags", "bank", "warband", "equip" },
            deferHeavy = true,
        })
    end

    -- No PLAYER_EQUIPMENT_CHANGED here: equipment changes already arrive on the
    -- shared pulse as the equip region, and a second handler doubled the rebuild.
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_LOGIN" then
            self:UnregisterEvent("PLAYER_LOGIN")
        end
        ScheduleGearSetRebuild()
    end)

    ScheduleGearSetRebuild()
    -- Cold login / late Init after PLAYER_LOGIN: bags and GUIDs settle after a beat.
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, ScheduleGearSetRebuild)
        C_Timer.After(2.0, ScheduleGearSetRebuild)
    end
end

