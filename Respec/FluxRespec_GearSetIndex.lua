-- FluxRespec_GearSetIndex.lua
-- Index of saved gear wants across all respec profiles and equipment presets.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.GearSetIndex = R.GearSetIndex or {}
local GearSetIndex = R.GearSetIndex

local SLOT_MIN = 1
local RESPEC_GEAR_SLOT_MAX = 19

local entries = {}
local byItemID = {}
local nameByKey = {}
local allocatedBagSlots = {}
local allocatedInvSlots = {}
local allocationByEntry = {}
local allocationsBagGen = nil
local allocationsBankOpen = false

local function SlotMax()
    local equip = R.Equipment
    if equip and equip.GetSlotMax then
        return equip.GetSlotMax()
    end
    return RESPEC_GEAR_SLOT_MAX
end

local function EntryKey(sourceKind, sourceName, invSlotID)
    return ("%s:%s:%d"):format(sourceKind, sourceName or "", invSlotID)
end

local function AddEntry(want, invSlotID, sourceKind, sourceName)
    if not want or not want.itemID or want.empty then
        return
    end
    local key = EntryKey(sourceKind, sourceName, invSlotID)
    if nameByKey[key] then
        return
    end
    local entry = {
        want = want,
        invSlotID = invSlotID,
        sourceKind = sourceKind,
        sourceName = sourceName,
    }
    entries[#entries + 1] = entry
    nameByKey[key] = true
    local id = want.itemID
    local bucket = byItemID[id]
    if not bucket then
        bucket = {}
        byItemID[id] = bucket
    end
    bucket[#bucket + 1] = entry
end

local function ScanEquipmentSnapshot(equipment, sourceKind, sourceName)
    if type(equipment) ~= "table" then
        return
    end
    local equip = R.Equipment
    local skipOH = equip and equip.ShouldIgnoreOffHandSlot and equip.ShouldIgnoreOffHandSlot(equipment)
    local slotMax = SlotMax()
    for invSlotID = SLOT_MIN, slotMax do
        if not (skipOH and invSlotID == 17) then
            local want = equipment[invSlotID]
            if want and want.itemID and not want.empty then
                AddEntry(want, invSlotID, sourceKind, sourceName)
            end
        end
    end
end

function GearSetIndex.Rebuild()
    wipe(entries)
    wipe(byItemID)
    wipe(nameByKey)

    local root = _G._FluxUI_CharSavedVars
    if type(root) ~= "table" then
        R.Fire("GEAR_SET_INDEX_CHANGED")
        return
    end

    local respec = root.respec
    if type(respec) == "table" and type(respec.profiles) == "table" then
        for name, profile in pairs(respec.profiles) do
            if type(profile) == "table" then
                ScanEquipmentSnapshot(profile.equipment, "profile", name)
            end
        end
    end

    local presetStore = root.equipmentPresets
    if type(presetStore) == "table" and type(presetStore.presets) == "table" then
        for name, preset in pairs(presetStore.presets) do
            if type(preset) == "table" and name ~= "default" then
                ScanEquipmentSnapshot(preset.equipment, "preset", name)
            end
        end
    end

    R.Fire("GEAR_SET_INDEX_CHANGED")
    GearSetIndex.RefreshAllocations()
end

function GearSetIndex.GetEntries()
    return entries
end

function GearSetIndex.GetEntriesForItemID(itemID)
    if not itemID then
        return nil
    end
    return byItemID[itemID]
end

local function NormalizeWantIdentityKey(want)
    if not want or not want.itemID then
        return nil
    end
    local equip = R.Equipment
    if equip and equip.WantHasItemKey and equip.WantHasItemKey(want) then
        local key = want.itemKey
        if type(key) == "string" then
            key = key:gsub("@@rune@@%d+$", "")
        end
        return ("key:%s"):format(key or "")
    end
    if equip and equip.WantHasSpecificLink and equip.WantHasSpecificLink(want) then
        local link = want.itemLink or ""
        link = link:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        return ("link:%s"):format(link)
    end
    return ("id:%s"):format(tostring(want.itemID))
end

function GearSetIndex.WantIdentityKey(want)
    return NormalizeWantIdentityKey(want)
end

function GearSetIndex.RequiredCopiesForWant(want)
    if not want or not want.itemID then
        return 0
    end
    local equip = R.Equipment
    if equip and equip.WantHasItemKey and equip.WantHasItemKey(want) then
        local slots = {}
        local count = 0
        for i = 1, #entries do
            local entry = entries[i]
            if equip.WantsSameIdentity and equip.WantsSameIdentity(entry.want, want) then
                local sid = entry.invSlotID
                if sid and not slots[sid] then
                    slots[sid] = true
                    count = count + 1
                end
            end
        end
        return count
    end
    if equip and equip.WantHasSpecificLink and equip.WantHasSpecificLink(want) then
        local slots = {}
        local count = 0
        for i = 1, #entries do
            local entry = entries[i]
            if equip.WantsSameIdentity and equip.WantsSameIdentity(entry.want, want) then
                local sid = entry.invSlotID
                if sid and not slots[sid] then
                    slots[sid] = true
                    count = count + 1
                end
            end
        end
        return count
    end
    local slots = {}
    local count = 0
    for i = 1, #entries do
        local entry = entries[i]
        if equip and equip.WantsSameIdentity and equip.WantsSameIdentity(entry.want, want) then
            local sid = entry.invSlotID
            if sid and not slots[sid] then
                slots[sid] = true
                count = count + 1
            end
        elseif entry.want and entry.want.itemID == want.itemID then
            local sid = entry.invSlotID
            if sid and not slots[sid] then
                slots[sid] = true
                count = count + 1
            end
        end
    end
    return count
end

local function BagSlotKey(bag, slot)
    return ("%d:%d"):format(bag, slot)
end

local function WantNeedsExactIdentity(want)
    local equip = R.Equipment
    if not equip or not want then
        return false
    end
    if equip.WantHasItemKey and equip.WantHasItemKey(want) then
        return true
    end
    if equip.WantHasSpecificLink and equip.WantHasSpecificLink(want) then
        return true
    end
    return false
end

local function ScoreBagSlotForEntry(bag, slot, entry, region)
    local want = entry and entry.want
    if not want or not want.itemID then
        return 0
    end
    -- Fast itemID gate first; tooltip identity only for contested same-ID stacks
    -- (keys are generation-cached in GetItemKeyForBagSlot).
    local inv = R.Inv
    local id = inv and inv.GetItemID and inv.GetItemID(bag, slot)
    id = tonumber(id)
    if not id or id ~= tonumber(want.itemID) then
        return 0
    end
    if WantNeedsExactIdentity(want) then
        local equip = R.Equipment
        if not equip or not equip.BagSlotMatchesSavedWant then
            return 0
        end
        if not equip.BagSlotMatchesSavedWant(bag, slot, want, entry.invSlotID) then
            return 0
        end
    end
    -- Prefer bags over bank when the same piece exists in both.
    if region == "bank" or region == "warband" then
        return 50
    end
    return 100
end

local function InventorySlotMatchesEntry(invSlot, entry)
    invSlot = tonumber(invSlot)
    if not invSlot or not entry or not entry.want then
        return false
    end
    local want = entry.want
    local wantID = want.itemID and tonumber(want.itemID)
    if not wantID then
        return false
    end

    -- Only the saved paperdoll slot (and jewelry peer) can satisfy this entry.
    if invSlot ~= tonumber(entry.invSlotID) then
        local equip = R.Equipment
        local peer = equip and equip.GetJewelryPeerSlot and equip.GetJewelryPeerSlot(entry.invSlotID)
        if not peer or invSlot ~= tonumber(peer) then
            return false
        end
    end

    -- Prefer link parse (same as Equipment.GetEquippedItemID) — safer than raw
    -- GetInventoryItemID on some Classic builds.
    local equippedID
    local link = _G.GetInventoryItemLink and _G.GetInventoryItemLink("player", invSlot)
    if link then
        local compat = R.Compat
        if compat and compat.ParseItemID then
            equippedID = tonumber(compat.ParseItemID(link))
        else
            equippedID = tonumber(link:match("item:(%d+)"))
        end
    end
    if not equippedID then
        local ok, id = pcall(_G.GetInventoryItemID, "player", invSlot)
        if ok then
            equippedID = tonumber(id)
        end
    end
    if not equippedID or equippedID ~= wantID then
        return false
    end

    -- itemKey / link wants: reject wrong-enchant equipped copies of the same itemID.
    if WantNeedsExactIdentity(want) then
        local equip = R.Equipment
        if not equip or not equip.PaperdollSlotMatchesWant then
            return false
        end
        return equip.PaperdollSlotMatchesWant(invSlot, want)
    end
    return true
end

local function AppendInvCandidates(entry, candidates, usedInv)
    local function trySlot(invSlot)
        invSlot = tonumber(invSlot)
        if not invSlot then
            return
        end
        if usedInv and usedInv[invSlot] then
            return
        end
        if InventorySlotMatchesEntry(invSlot, entry) then
            candidates[#candidates + 1] = {
                kind = "inv",
                invSlot = invSlot,
                score = 1000,
            }
        end
    end
    trySlot(entry.invSlotID)
    local equip = R.Equipment
    local peer = equip and equip.GetJewelryPeerSlot and equip.GetJewelryPeerSlot(entry.invSlotID)
    if peer then
        trySlot(peer)
    end
end

local function IsBankOpen()
    local inv = R.Inv
    return inv and inv.IsBankOpen and inv.IsBankOpen() or false
end

--- One pass over snapshots: itemID → { {bag, slot}, ... }
local function BuildItemIDLocationIndex()
    local byID = {}
    local inv = R.Inv
    if not inv or not inv.ForEachLocation then
        return byID
    end
    inv.ForEachLocation(function(loc)
        local itemID = tonumber(loc.itemID)
        if not itemID or itemID <= 0 then
            return
        end
        local list = byID[itemID]
        if not list then
            list = {}
            byID[itemID] = list
        end
        list[#list + 1] = { bag = loc.bag, slot = loc.slot, region = loc.region }
    end, "all")
    return byID
end

local function ScanLocationsForEntry(locations, entry, usedBag, candidates)
    if type(locations) ~= "table" then
        return
    end
    for i = 1, #locations do
        local loc = locations[i]
        local bag, slot = loc.bag, loc.slot
        local key = BagSlotKey(bag, slot)
        if not usedBag[key] then
            local score = ScoreBagSlotForEntry(bag, slot, entry, loc.region)
            if score > 0 then
                candidates[#candidates + 1] = {
                    kind = "bag",
                    bag = bag,
                    slot = slot,
                    score = score,
                }
            end
        end
    end
end

local function CurrentBagsGeneration()
    local inv = R.Inv
    if inv and inv.GetGeneration then
        return inv.GetGeneration()
    end
    return nil
end

function GearSetIndex.AreAllocationsFresh()
    if #entries == 0 then
        return true
    end
    local bagGen = CurrentBagsGeneration()
    if bagGen == nil or allocationsBagGen ~= bagGen then
        return false
    end
    if allocationsBankOpen ~= IsBankOpen() then
        return false
    end
    return true
end

function GearSetIndex.RefreshAllocations()
    wipe(allocatedBagSlots)
    wipe(allocatedInvSlots)
    wipe(allocationByEntry)

    if #entries == 0 then
        allocationsBagGen = CurrentBagsGeneration()
        allocationsBankOpen = IsBankOpen()
        return
    end

    local equip = R.Equipment
    local inv = R.Inv
    if not equip or not inv or not inv.ForEachLocation then
        return
    end

    -- Item-key cache is generation-keyed in GetItemKeyForBagSlot / GetItemKeyForInventorySlot.
    -- Do not wipe here — shared gear across profiles would re-tooltip every refresh.

    local usedBag = {}
    local usedInv = {}
    local sorted = {}
    for i = 1, #entries do
        sorted[i] = entries[i]
    end
    table.sort(sorted, function(a, b)
        local aName = a.sourceName or ""
        local bName = b.sourceName or ""
        if aName ~= bName then
            return aName:lower() < bName:lower()
        end
        if a.sourceKind ~= b.sourceKind then
            return (a.sourceKind or "") < (b.sourceKind or "")
        end
        return (a.invSlotID or 0) < (b.invSlotID or 0)
    end)

    local locIndex = BuildItemIDLocationIndex()

    for i = 1, #sorted do
        local entry = sorted[i]
        local entryKey = EntryKey(entry.sourceKind, entry.sourceName, entry.invSlotID)
        local candidates = {}

        AppendInvCandidates(entry, candidates, usedInv)

        local itemID = entry.want and tonumber(entry.want.itemID)
        if itemID then
            ScanLocationsForEntry(locIndex[itemID], entry, usedBag, candidates)
        end

        table.sort(candidates, function(a, b)
            if a.score ~= b.score then
                return a.score > b.score
            end
            if a.kind ~= b.kind then
                return a.kind == "inv"
            end
            if a.kind == "inv" then
                return (a.invSlot or 0) < (b.invSlot or 0)
            end
            if a.bag ~= b.bag then
                return (a.bag or 0) < (b.bag or 0)
            end
            return (a.slot or 0) < (b.slot or 0)
        end)

        local picked = candidates[1]
        if picked then
            allocationByEntry[entryKey] = picked
            if picked.kind == "inv" then
                usedInv[picked.invSlot] = true
                allocatedInvSlots[picked.invSlot] = true
            elseif picked.kind == "bag" then
                local key = BagSlotKey(picked.bag, picked.slot)
                usedBag[key] = true
                allocatedBagSlots[key] = true
            end
        end
    end

    allocationsBagGen = CurrentBagsGeneration()
    allocationsBankOpen = IsBankOpen()
end

function GearSetIndex.IsBagSlotAllocatedForEntry(bag, slot, entry)
    if not bag or not slot or not entry then
        return false
    end
    local entryKey = EntryKey(entry.sourceKind, entry.sourceName, entry.invSlotID)
    local picked = allocationByEntry[entryKey]
    return picked and picked.kind == "bag" and picked.bag == bag and picked.slot == slot
end

function GearSetIndex.IsInventorySlotAllocatedForEntry(invSlot, entry)
    invSlot = tonumber(invSlot)
    if not invSlot or not entry then
        return false
    end
    local entryKey = EntryKey(entry.sourceKind, entry.sourceName, entry.invSlotID)
    local picked = allocationByEntry[entryKey]
    return picked and picked.kind == "inv" and picked.invSlot == invSlot
end

function GearSetIndex.IsBagSlotAllocatedForGearSet(bag, slot)
    if not bag or not slot then
        return false
    end
    return allocatedBagSlots[BagSlotKey(bag, slot)] == true
end

function GearSetIndex.IsInventorySlotAllocatedForGearSet(invSlot)
    invSlot = tonumber(invSlot)
    if not invSlot then
        return false
    end
    return allocatedInvSlots[invSlot] == true
end

local function MatchesEntry(bag, slot, entry)
    local equip = R.Equipment
    if not equip or not equip.BagSlotMatchesSavedWant then
        return false
    end
    return equip.BagSlotMatchesSavedWant(bag, slot, entry.want, entry.invSlotID)
end

function GearSetIndex.ForEachAllocatedBagSlot(fn)
    if type(fn) ~= "function" then
        return
    end
    for key in pairs(allocatedBagSlots) do
        local bag, slot = key:match("^(%-?%d+):(%d+)$")
        bag, slot = tonumber(bag), tonumber(slot)
        if bag and slot then
            fn(bag, slot)
        end
    end
end

local function GetContainerItemID(bag, slot)
    local inv = R.Inv
    if inv and inv.GetItemID then
        return inv.GetItemID(bag, slot)
    end
    local compat = R.Compat
    if compat and compat.GetContainerItemID then
        return compat.GetContainerItemID(bag, slot)
    end
    if _G.C_Container and _G.C_Container.GetContainerItemID then
        return _G.C_Container.GetContainerItemID(bag, slot)
    end
    if _G.GetContainerItemID then
        return _G.GetContainerItemID(bag, slot)
    end
end

function GearSetIndex.GetMatchingIdentityKeyForBagSlot(bag, slot)
    if not bag or not slot then
        return nil
    end
    local itemID = GetContainerItemID(bag, slot)
    if not itemID or itemID == 0 then
        return nil
    end
    local bucket = byItemID[itemID]
    if not bucket then
        return nil
    end
    for i = 1, #bucket do
        local entry = bucket[i]
        if MatchesEntry(bag, slot, entry) then
            return GearSetIndex.WantIdentityKey(entry.want)
        end
    end
end

function GearSetIndex.GetMatchingIdentityKeyForInventorySlot(invSlot)
    invSlot = tonumber(invSlot)
    if not invSlot then
        return nil
    end
    local itemID = GetInventoryItemID and GetInventoryItemID("player", invSlot)
    if not itemID or itemID == 0 then
        return nil
    end
    local bucket = byItemID[itemID]
    if not bucket then
        return nil
    end
    local equip = R.Equipment
    if not equip or not equip.PaperdollSlotMatchesWant then
        return nil
    end
    for i = 1, #bucket do
        local entry = bucket[i]
        if equip.PaperdollSlotMatchesWant(invSlot, entry.want) then
            return GearSetIndex.WantIdentityKey(entry.want)
        end
    end
end

function GearSetIndex.IsBagSlotInSavedGearSet(bag, slot)
    if not bag or not slot then
        return false
    end
    if not next(allocationByEntry) then
        GearSetIndex.RefreshAllocations()
    end
    return GearSetIndex.IsBagSlotAllocatedForGearSet(bag, slot)
end

function GearSetIndex.IsInventorySlotInSavedGearSet(invSlot)
    invSlot = tonumber(invSlot)
    if not invSlot then
        return false
    end
    local itemID = GetInventoryItemID and GetInventoryItemID("player", invSlot)
    if not itemID or itemID == 0 then
        return false
    end
    local bucket = byItemID[itemID]
    if not bucket then
        return false
    end
    local equip = R.Equipment
    if not equip or not equip.PaperdollSlotMatchesWant then
        return false
    end
    for i = 1, #bucket do
        if equip.PaperdollSlotMatchesWant(invSlot, bucket[i].want) then
            return true
        end
    end
    return false
end

function GearSetIndex.GetMatchingSetNames(bag, slot)
    local out = {}
    local seen = {}
    if not bag or not slot then
        return out
    end
    if not next(allocationByEntry) then
        GearSetIndex.RefreshAllocations()
    end
    local itemID = GetContainerItemID(bag, slot)
    if not itemID or itemID == 0 then
        return out
    end
    local bucket = byItemID[itemID]
    if not bucket then
        return out
    end
    for i = 1, #bucket do
        local entry = bucket[i]
        if MatchesEntry(bag, slot, entry) and GearSetIndex.IsBagSlotAllocatedForEntry(bag, slot, entry) then
            local label = entry.sourceName
            if label and not seen[label] then
                seen[label] = true
                out[#out + 1] = label
            end
        end
    end
    table.sort(out, function(a, b)
        return (a or ""):lower() < (b or ""):lower()
    end)
    return out
end

local function ScheduleRebuild()
    if GearSetIndex._rebuildScheduled then
        return
    end
    GearSetIndex._rebuildScheduled = true
    local schedule = (_G.C_Timer and _G.C_Timer.After)
        or (_G.FLUX_API and _G.FLUX_API.After)
    if schedule then
        schedule(0, function()
            GearSetIndex._rebuildScheduled = false
            GearSetIndex.Rebuild()
        end)
    else
        GearSetIndex._rebuildScheduled = false
        GearSetIndex.Rebuild()
    end
end

local function HookRespecEvents()
    local events = {
        "PROFILES_CHANGED",
        "PROFILE_SAVED",
        "PROFILE_CREATED",
        "PROFILE_DELETED",
        "PROFILE_RENAMED",
        "EQUIPMENT_PRESET_CHANGED",
        "EQUIPMENT_PRESET_SAVED",
        "EQUIPMENT_SETS_SYNCED",
    }
    for i = 1, #events do
        R.On(events[i], ScheduleRebuild)
    end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    HookRespecEvents()
    GearSetIndex.Rebuild()
end)

_G.FluxRespec_GearSetIndex = GearSetIndex
R.GearSetIndex = GearSetIndex
return GearSetIndex

