-- FluxRespec_EquipmentSets.lua
-- Blizzard C_EquipmentSet bridge for Respec profiles and named gear presets.
-- Same-name adopt (including sets that existed before Flux). Cap 10 → Flux-only.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.EquipmentSets = R.EquipmentSets or {}
local EquipmentSets = R.EquipmentSets

local NAME_MAX = 16
local DEFAULT_MAX_SETS = 10
local QUESTION_MARK = 134400
local SLOT_MIN = 1
local SLOT_MAX = 19

EquipmentSets.NAME_MAX = NAME_MAX
EquipmentSets.QUESTION_MARK = QUESTION_MARK

local function Compat()
    return R.Compat
end

function EquipmentSets.CanUse()
    local c = Compat()
    if c and c.CanUseEquipmentSets then
        return c.CanUseEquipmentSets() == true
    end
    local api = _G.C_EquipmentSet
    return type(api) == "table" and type(api.UseEquipmentSet) == "function"
end

local function API()
    if not EquipmentSets.CanUse() then
        return nil
    end
    return _G.C_EquipmentSet
end

local function SlotMax()
    local eq = R.Equipment
    if eq and eq.GetSlotMax then
        return eq.GetSlotMax() or SLOT_MAX
    end
    return SLOT_MAX
end

function EquipmentSets.NameMaxLetters()
    if EquipmentSets.CanUse() then
        return NAME_MAX
    end
    return 40
end

function EquipmentSets.TruncName(name)
    if type(name) ~= "string" then
        return ""
    end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        return ""
    end
    if _G.utf8sub then
        return _G.utf8sub(name, 1, NAME_MAX)
    end
    local n = 0
    local i = 1
    local len = #name
    while i <= len and n < NAME_MAX do
        local c = name:byte(i)
        if not c then
            break
        end
        local step = 1
        if c >= 240 then
            step = 4
        elseif c >= 224 then
            step = 3
        elseif c >= 192 then
            step = 2
        end
        i = i + step
        n = n + 1
    end
    return name:sub(1, i - 1)
end

local function MaxSets()
    return tonumber(_G.MAX_EQUIPMENT_SETS_PER_PLAYER) or DEFAULT_MAX_SETS
end

local GetInfo

local function GetSetIDs()
    local api = API()
    local out = {}
    if not api then
        return out
    end
    if api.GetEquipmentSetIDs then
        local ok, ids = pcall(api.GetEquipmentSetIDs)
        if ok and type(ids) == "table" then
            for k, v in pairs(ids) do
                local setID
                if type(v) == "number" then
                    setID = v
                elseif type(k) == "number" and v then
                    setID = k
                end
                if setID then
                    out[#out + 1] = setID
                end
            end
            return out
        end
    end
    local n = 0
    if api.GetNumEquipmentSets then
        local ok, count = pcall(api.GetNumEquipmentSets)
        if ok and type(count) == "number" then
            n = count
        end
    end
    for i = 0, math.max(n - 1, MaxSets() - 1) do
        if GetInfo(i) then
            out[#out + 1] = i
        end
    end
    return out
end

function EquipmentSets.GetNum()
    local api = API()
    if not api then
        return 0
    end
    if api.GetNumEquipmentSets then
        local ok, n = pcall(api.GetNumEquipmentSets)
        if ok and type(n) == "number" then
            return n
        end
    end
    return #GetSetIDs()
end

function EquipmentSets.HasQuotaForNew()
    return EquipmentSets.GetNum() < MaxSets()
end

function GetInfo(setID)
    local api = API()
    if not api or setID == nil or not api.GetEquipmentSetInfo then
        return nil
    end
    local ok, name, iconFileID, id, isEquipped, numItems, numEquipped, numInInventory, numLost, numIgnored =
        pcall(api.GetEquipmentSetInfo, setID)
    if not ok or not name then
        return nil
    end
    return {
        name = name,
        icon = iconFileID,
        id = id or setID,
        isEquipped = isEquipped,
        numItems = numItems,
        numEquipped = numEquipped,
        numInInventory = numInInventory,
        numLost = numLost,
        numIgnored = numIgnored,
    }
end

function EquipmentSets.GetInfo(setID)
    return GetInfo(setID)
end

local function GetIdByName(setName)
    local api = API()
    if not api or not setName or setName == "" or not api.GetEquipmentSetID then
        return nil
    end
    local ok, id = pcall(api.GetEquipmentSetID, setName)
    if ok and type(id) == "number" then
        return id
    end
    return nil
end

local function Inc()
    return R.Includes
end

function EquipmentSets.GetLink(owner)
    local I = Inc()
    if I and I.GetBlizzardSet then
        return I.GetBlizzardSet(owner)
    end
    return nil
end

local function WantedSlots(owner, isPreset)
    local I = Inc()
    if not I then
        return {}
    end
    if isPreset then
        return I.WantedPresetEquipmentSlotSet and I.WantedPresetEquipmentSlotSet(owner) or {}
    end
    return I.WantedEquipmentSlotSet and I.WantedEquipmentSlotSet(owner) or {}
end

function EquipmentSets.GetIgnoredSlotSet(setID)
    local api = API()
    local out = {}
    if not api or not setID or not api.GetIgnoredSlots then
        return out
    end
    local ok, ignored = pcall(api.GetIgnoredSlots, setID)
    if not ok or type(ignored) ~= "table" then
        return out
    end
    for slot, v in pairs(ignored) do
        local sid = tonumber(slot) or slot
        if v then
            out[sid] = true
        end
    end
    return out
end

--- True when UseEquipmentSet would change a slot Flux wants to leave alone.
function EquipmentSets.WouldViolateWanted(setID, wantedSlots)
    if not setID then
        return true
    end
    wantedSlots = wantedSlots or {}
    local ignored = EquipmentSets.GetIgnoredSlotSet(setID)
    local smax = SlotMax()
    for slotID = SLOT_MIN, smax do
        if not wantedSlots[slotID] and not ignored[slotID] then
            return true
        end
    end
    return false
end

local function ApplyIgnoreMask(wantedSlots)
    local api = API()
    if not api then
        return
    end
    wantedSlots = wantedSlots or {}
    if api.ClearIgnoredSlotsForSave then
        pcall(api.ClearIgnoredSlotsForSave)
    end
    local smax = SlotMax()
    for slotID = SLOT_MIN, smax do
        if not wantedSlots[slotID] then
            if api.IgnoreSlotForSave then
                pcall(api.IgnoreSlotForSave, slotID)
            end
        elseif api.UnignoreSlotForSave then
            pcall(api.UnignoreSlotForSave, slotID)
        end
    end
end

local mute = 0

local function Mute()
    mute = mute + 1
end

local function Unmute()
    local function dec()
        mute = mute - 1
        if mute < 0 then
            mute = 0
        end
    end
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, dec)
    else
        dec()
    end
end

function EquipmentSets.IsMuted()
    return mute > 0
end

local function IconFromLive(wanted)
    wanted = wanted or {}
    local smax = SlotMax()
    for slotID = SLOT_MIN, smax do
        if wanted[slotID] then
            local tex = _G.GetInventoryItemTexture and _G.GetInventoryItemTexture("player", slotID)
            if tex then
                return tex
            end
        end
    end
    return QUESTION_MARK
end

local function OwnerIsPreset(owner)
    if type(owner) ~= "table" then
        return false
    end
    if owner.includes then
        return false
    end
    return true
end

function EquipmentSets.PickIcon(owner, isPreset)
    if type(owner) ~= "table" then
        return QUESTION_MARK
    end
    if not isPreset and owner.icon then
        return owner.icon
    end
    if isPreset and owner.icon then
        return owner.icon
    end
    local wanted = WantedSlots(owner, isPreset)
    return IconFromLive(wanted)
end

local function StoreIcon(owner, isPreset, icon)
    if type(owner) ~= "table" or icon == nil then
        return
    end
    owner.icon = icon
    if not isPreset then
        -- profile.icon is the picker source
    end
end

function EquipmentSets.DisplayIcon(owner, label)
    local bs = EquipmentSets.GetLink(owner)
    local id = bs and bs.id
    local info = id and GetInfo(id)
    if info and info.icon then
        return info.icon
    end
    if type(owner) == "table" and owner.icon then
        return owner.icon
    end
    if type(label) == "string" and label ~= "" then
        local byName = GetIdByName(EquipmentSets.TruncName(label))
        info = byName and GetInfo(byName)
        if info and info.icon then
            return info.icon
        end
    end
    return nil
end

function EquipmentSets.DisplayName(owner, label)
    local bs = EquipmentSets.GetLink(owner)
    local id = bs and bs.id
    local info = id and GetInfo(id)
    if info and info.name and info.name ~= "" then
        return info.name
    end
    if type(label) == "string" and label ~= "" then
        return label
    end
    return bs and bs.name or ""
end

--- Resolve stored id, else adopt by truncated name. Does not create.
function EquipmentSets.ResolveId(owner, label, allowAdopt)
    local bs = EquipmentSets.GetLink(owner)
    if not bs then
        return nil
    end
    if bs.id and GetInfo(bs.id) then
        return bs.id
    end
    if allowAdopt == false then
        bs.id = nil
        return nil
    end
    local setName = EquipmentSets.TruncName(label or bs.name or "")
    if setName == "" then
        bs.id = nil
        return nil
    end
    local id = GetIdByName(setName)
    if id then
        bs.id = id
        bs.name = setName
        bs.managed = false
        return id
    end
    bs.id = nil
    return nil
end

local quotaWarned = false

local function WarnQuota()
    if quotaWarned then
        return
    end
    quotaWarned = true
    if R.Print then
        R.Print("Blizzard equipment set cap is full — Flux will equip this from bags.")
    end
end

--- Create or update the Blizzard set for this owner. Returns ok, reason.
function EquipmentSets.SyncManaged(owner, label, isPreset)
    if not EquipmentSets.CanUse() then
        return true
    end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        return false, "COMBAT"
    end
    local bs = EquipmentSets.GetLink(owner)
    if not bs then
        return false, "NOLINK"
    end
    local setName = EquipmentSets.TruncName(label or "")
    if setName == "" then
        return false, "NAME"
    end
    local wanted = WantedSlots(owner, isPreset)
    local icon = EquipmentSets.PickIcon(owner, isPreset)
    StoreIcon(owner, isPreset, icon)

    local api = API()
    if not api then
        return false, "API"
    end

    Mute()
    local created = false
    local id = EquipmentSets.ResolveId(owner, label, true)
    if not id then
        if not EquipmentSets.HasQuotaForNew() then
            Unmute()
            WarnQuota()
            return false, "QUOTA"
        end
        ApplyIgnoreMask(wanted)
        if api.CreateEquipmentSet then
            pcall(api.CreateEquipmentSet, setName, icon)
        end
        id = GetIdByName(setName)
        if not id then
            Unmute()
            return false, "CREATE"
        end
        created = true
        bs.managed = true
    else
        if api.ModifyEquipmentSet then
            pcall(api.ModifyEquipmentSet, id, setName, icon)
        end
    end
    ApplyIgnoreMask(wanted)
    if api.SaveEquipmentSet then
        pcall(api.SaveEquipmentSet, id, icon)
    end
    bs.id = id
    bs.name = setName
    if created then
        bs.managed = true
    end
    local info = GetInfo(id)
    if info and info.icon then
        StoreIcon(owner, isPreset, info.icon)
    end
    Unmute()
    quotaWarned = false
    return true
end

function EquipmentSets.PushIcon(owner, icon)
    if not EquipmentSets.CanUse() or type(owner) ~= "table" or icon == nil then
        return false
    end
    local bs = EquipmentSets.GetLink(owner)
    local id = bs and bs.id
    if not id or not GetInfo(id) then
        return false
    end
    local api = API()
    if not api then
        return false
    end
    Mute()
    local name = (bs and bs.name) or (GetInfo(id) and GetInfo(id).name)
    if api.ModifyEquipmentSet and name then
        pcall(api.ModifyEquipmentSet, id, name, icon)
    elseif api.SaveEquipmentSet then
        pcall(api.SaveEquipmentSet, id, icon)
    end
    StoreIcon(owner, OwnerIsPreset(owner), icon)
    Unmute()
    return true
end

function EquipmentSets.PushName(owner, newLabel)
    if not EquipmentSets.CanUse() or type(owner) ~= "table" then
        return false
    end
    local setName = EquipmentSets.TruncName(newLabel or "")
    if setName == "" then
        return false
    end
    local bs = EquipmentSets.GetLink(owner)
    local id = bs and bs.id
    if not id or not GetInfo(id) then
        return false
    end
    local api = API()
    if not api or not api.ModifyEquipmentSet then
        return false
    end
    Mute()
    local icon = EquipmentSets.PickIcon(owner, OwnerIsPreset(owner))
    pcall(api.ModifyEquipmentSet, id, setName, icon)
    bs.name = setName
    Unmute()
    return true
end

function EquipmentSets.DeleteIfManaged(owner)
    if not EquipmentSets.CanUse() or type(owner) ~= "table" then
        return false
    end
    local bs = EquipmentSets.GetLink(owner)
    if not bs or not bs.managed or not bs.id then
        if bs then
            bs.id = nil
            bs.name = nil
            bs.managed = false
        end
        return false
    end
    local info = GetInfo(bs.id)
    local api = API()
    if info and api and api.DeleteEquipmentSet then
        Mute()
        pcall(api.DeleteEquipmentSet, bs.id)
        Unmute()
    end
    bs.id = nil
    bs.name = nil
    bs.managed = false
    return true
end

function EquipmentSets.QuotaTooltip(owner, label)
    if not EquipmentSets.CanUse() then
        return "This client has no Blizzard equipment sets. Flux equips from bags."
    end
    local n = EquipmentSets.GetNum()
    local maxN = MaxSets()
    local bs = EquipmentSets.GetLink(owner)
    local id = bs and bs.id
    if id and not GetInfo(id) then
        id = nil
    end
    if not id then
        id = GetIdByName(EquipmentSets.TruncName(label or (bs and bs.name) or ""))
    end
    if id then
        return ("Blizzard sets: %d / %d. This name matches a character-pane set (same icon and items on Save)."):format(n, maxN)
    end
    if EquipmentSets.HasQuotaForNew() then
        return ("Blizzard sets: %d / %d. Save creates a set with this name."):format(n, maxN)
    end
    return ("Blizzard sets: %d / %d (full). Flux keeps its own snapshot and equips from bags."):format(n, maxN)
end

-- -----------------------------------------------------------------------------
-- TryApply: UseEquipmentSet, then onDone (Flux leftovers)
-- -----------------------------------------------------------------------------

local pendingApply

local function FinishTryApply()
    local p = pendingApply
    pendingApply = nil
    if p and p.frame then
        p.frame:UnregisterAllEvents()
        p.frame:SetScript("OnEvent", nil)
        p.frame:SetScript("OnUpdate", nil)
    end
    if p and p.onDone then
        pcall(p.onDone)
    end
end

--- Fast path: UseEquipmentSet when it cannot touch unchecked slots. Always calls onDone.
function EquipmentSets.TryApply(owner, wantedSlots, onDone, label)
    if type(onDone) ~= "function" then
        onDone = function() end
    end
    if not EquipmentSets.CanUse() or type(owner) ~= "table" then
        onDone()
        return
    end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        onDone()
        return
    end
    local bs = EquipmentSets.GetLink(owner)
    local id = EquipmentSets.ResolveId(owner, label or (bs and bs.name), true)
    if not id then
        onDone()
        return
    end
    if EquipmentSets.WouldViolateWanted(id, wantedSlots) then
        onDone()
        return
    end
    local api = API()
    if not api or not api.UseEquipmentSet then
        onDone()
        return
    end
    if api.EquipmentSetContainsLockedItems then
        local okLock, locked = pcall(api.EquipmentSetContainsLockedItems, id)
        if okLock and locked then
            onDone()
            return
        end
    end
    if pendingApply then
        FinishTryApply()
    end
    local f = CreateFrame("Frame")
    pendingApply = { onDone = onDone, frame = f, setID = id }
    f:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
    f:SetScript("OnEvent", function(_, event, result, setID)
        if event ~= "EQUIPMENT_SWAP_FINISHED" then
            return
        end
        if pendingApply and pendingApply.setID and setID and setID ~= pendingApply.setID then
            return
        end
        FinishTryApply()
    end)
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(2.5, function()
            if pendingApply and pendingApply.frame == f then
                FinishTryApply()
            end
        end)
    else
        local elapsed = 0
        f:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + (dt or 0)
            if elapsed > 2.5 then
                self:SetScript("OnUpdate", nil)
                if pendingApply and pendingApply.frame == self then
                    FinishTryApply()
                end
            end
        end)
    end
    local okUse, equipped = pcall(api.UseEquipmentSet, id)
    if not okUse or equipped == false then
        FinishTryApply()
    end
end

-- -----------------------------------------------------------------------------
-- World → Flux name/icon pull
-- -----------------------------------------------------------------------------

local function RenameFluxProfile(oldName, newName)
    if not oldName or not newName or oldName == newName then
        return false
    end
    if R.RenameProfile then
        return R.RenameProfile(oldName, newName, true)
    end
    return false
end

local function RenameFluxPreset(oldName, newName)
    if not oldName or not newName or oldName == newName then
        return false
    end
    local EP = R.EquipmentPresets
    if EP and EP.RenamePreset then
        return EP.RenamePreset(oldName, newName, true)
    end
    return false
end

local EMPTY_SLOT = 0
local IGNORED_SLOT = 1
local MISSING_ITEM = -1

local function BagItemLink(bag, slot)
    local c = Compat()
    if c and c.GetContainerItemLink then
        return c.GetContainerItemLink(bag, slot)
    end
    return nil
end

local function WantFromBlizzardSlot(slot, itemID, locations)
    local want = { itemID = itemID }
    local loc = locations and locations[slot]
    if type(loc) ~= "number" or loc < 0 then
        return want
    end
    if not _G.EquipmentManager_GetLocationData then
        return want
    end
    local ok, data = pcall(_G.EquipmentManager_GetLocationData, loc)
    if not ok or type(data) ~= "table" then
        return want
    end
    if data.isBags and data.bag and data.slot then
        local link = BagItemLink(data.bag, data.slot)
        if type(link) == "string" and link ~= "" then
            want.itemLink = link
        end
    elseif data.isPlayer and data.slot then
        local link = GetInventoryItemLink("player", data.slot)
        if type(link) == "string" and link ~= "" then
            want.itemLink = link
        end
        if R.Equipment and R.Equipment.GetItemKeyForInventorySlot then
            want.itemKey = R.Equipment.GetItemKeyForInventorySlot(data.slot)
        end
    end
    return want
end

--- Flux snapshot + ignored-slot map from a character-pane equipment set.
function EquipmentSets.SnapshotFromSet(setID)
    local equipment = {}
    local ignored = EquipmentSets.GetIgnoredSlotSet(setID)
    local api = API()
    if not api or not setID then
        return equipment, ignored
    end
    local itemIDs = {}
    if api.GetItemIDs then
        local ok, t = pcall(api.GetItemIDs, setID)
        if ok and type(t) == "table" then
            itemIDs = t
        end
    end
    local locations
    if api.GetItemLocations then
        local ok, t = pcall(api.GetItemLocations, setID)
        if ok and type(t) == "table" then
            locations = t
        end
    end
    local emptySent = tonumber(_G.EQUIPMENT_SET_EMPTY_SLOT) or EMPTY_SLOT
    local ignoredSent = tonumber(_G.EQUIPMENT_SET_IGNORED_SLOT) or IGNORED_SLOT
    local missingSent = tonumber(_G.EQUIPMENT_SET_ITEM_MISSING) or MISSING_ITEM
    local shirt = _G.INVSLOT_SHIRT or 4
    local tabard = _G.INVSLOT_TABARD or 19
    local smax = SlotMax()
    for slot = SLOT_MIN, smax do
        local id = itemIDs[slot]
        if ignored[slot] or id == ignoredSent then
            ignored[slot] = true
        elseif id == nil or id == emptySent then
            if slot ~= shirt and slot ~= tabard then
                equipment[slot] = { empty = true }
            end
        elseif id == missingSent then
            -- Slot is in the set but the item is not in bags/equipped; keep the slot included.
        elseif type(id) == "number" and id > ignoredSent then
            equipment[slot] = WantFromBlizzardSlot(slot, id, locations)
        end
    end
    return equipment, ignored
end

local function HasEquipmentSnapshot(preset)
    local eq = preset and preset.equipment
    if type(eq) ~= "table" then
        return false
    end
    for _, v in pairs(eq) do
        if type(v) == "table" and (v.itemID or v.itemLink or v.empty) then
            return true
        end
    end
    return false
end

local function FindPresetForBlizzardSet(store, setID, setName)
    if type(store) ~= "table" or type(store.presets) ~= "table" then
        return nil, nil
    end
    for name, preset in pairs(store.presets) do
        if name ~= "default" and type(preset) == "table" then
            local bs = preset.blizzardSet
            if type(bs) == "table" and bs.id and setID and bs.id == setID then
                return name, preset
            end
        end
    end
    if setName and type(store.presets[setName]) == "table" then
        return setName, store.presets[setName]
    end
    if setName then
        for name, preset in pairs(store.presets) do
            if name ~= "default" and type(preset) == "table" then
                if EquipmentSets.TruncName(name) == setName then
                    return name, preset
                end
            end
        end
    end
    return nil, nil
end

local function ApplySnapshotToPreset(preset, equipment, ignored)
    preset.equipment = equipment
    if type(preset.equipmentSlots) ~= "table" then
        preset.equipmentSlots = {}
    end
    for slot, ign in pairs(ignored) do
        if ign then
            preset.equipmentSlots[slot] = false
        end
    end
    if R.Includes and R.Includes.EnsureEquipmentPreset then
        R.Includes.EnsureEquipmentPreset(preset)
    end
end

local function AdoptBlizzardLink(preset, setID, info)
    if type(preset.blizzardSet) ~= "table" then
        preset.blizzardSet = { id = nil, name = nil, managed = false }
    end
    local bs = preset.blizzardSet
    bs.id = setID
    bs.name = info.name
    if bs.managed ~= true then
        bs.managed = false
    end
    if info.icon then
        preset.icon = info.icon
    end
end

--- Copy character-pane sets into the Gear dropdown (Flux presets) so they are visible without a prior Flux Save.
function EquipmentSets.ImportBlizzardAsPresets()
    if not EquipmentSets.CanUse() then
        return 0
    end
    local EP = R.EquipmentPresets
    if not EP or not EP.EnsureStore then
        return 0
    end
    local store = EP.EnsureStore()
    if type(store.presets) ~= "table" then
        return 0
    end
    local added = 0
    local ids = GetSetIDs()
    for i = 1, #ids do
        local setID = ids[i]
        local info = GetInfo(setID)
        if info and type(info.name) == "string" and info.name ~= "" and info.name ~= "default" then
            local name, preset = FindPresetForBlizzardSet(store, setID, info.name)
            if not preset then
                name = info.name
                store.presets[name] = {}
                preset = store.presets[name]
                added = added + 1
            end
            AdoptBlizzardLink(preset, setID, info)
            if not HasEquipmentSnapshot(preset) then
                local equipment, ignored = EquipmentSets.SnapshotFromSet(setID)
                ApplySnapshotToPreset(preset, equipment, ignored)
            elseif R.Includes and R.Includes.EnsureEquipmentPreset then
                R.Includes.EnsureEquipmentPreset(preset)
            end
        end
    end
    return added
end

local function PullOwner(owner, fluxName, isPreset, renameFn)
    local bs = EquipmentSets.GetLink(owner)
    if not bs then
        return
    end
    local id = EquipmentSets.ResolveId(owner, fluxName, true)
    if not id then
        bs.id = nil
        bs.name = nil
        return
    end
    local info = GetInfo(id)
    if not info then
        bs.id = nil
        bs.name = nil
        return
    end
    bs.id = info.id or id
    bs.name = info.name
    if info.icon then
        StoreIcon(owner, isPreset, info.icon)
    end
    if info.name and fluxName and info.name ~= fluxName then
        if EquipmentSets.TruncName(fluxName) ~= info.name then
            renameFn(fluxName, info.name)
        end
    end
end

function EquipmentSets.ReconcileAll()
    if not EquipmentSets.CanUse() then
        return
    end
    if mute > 0 then
        return
    end
    EquipmentSets.ImportBlizzardAsPresets()
    local store = R.GetStore and R.GetStore()
    if store and type(store.profiles) == "table" then
        local snapshot = {}
        for name, profile in pairs(store.profiles) do
            snapshot[#snapshot + 1] = { name = name, profile = profile }
        end
        for i = 1, #snapshot do
            local e = snapshot[i]
            if type(e.profile) == "table" then
                PullOwner(e.profile, e.name, false, RenameFluxProfile)
            end
        end
    end
    local EP = R.EquipmentPresets
    if EP and EP.EnsureStore and EP.GetPresetNames then
        local names = EP.GetPresetNames()
        for i = 1, #names do
            local pname = names[i]
            local preset = EP.GetPreset and EP.GetPreset(pname)
            if type(preset) == "table" then
                PullOwner(preset, pname, true, RenameFluxPreset)
            end
        end
    end
    if R.Fire then
        R.Fire("EQUIPMENT_SETS_SYNCED")
    end
end

local worldFrame = CreateFrame("Frame")
worldFrame:RegisterEvent("PLAYER_LOGIN")
worldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
worldFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
worldFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        EquipmentSets.ReconcileAll()
        return
    end
    if event == "EQUIPMENT_SETS_CHANGED" then
        if mute > 0 then
            if R.UI and R.UI.Refresh then
                pcall(R.UI.Refresh)
            end
            return
        end
        EquipmentSets.ReconcileAll()
        if R.UI and R.UI.Refresh then
            pcall(R.UI.Refresh)
        end
    end
end)

R.EquipmentSets = EquipmentSets

