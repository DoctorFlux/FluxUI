-- FluxRespec_Includes.lua
-- Apply-mask for respec profiles and equipment/rune presets.
-- Unchecked sections/slots skip both Save and Load; existing snapshot data is kept.
-- Checkbox toggles persist immediately (PROFILE_UPDATED / preset changed).

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.Includes = R.Includes or {}
local Includes = R.Includes

local SLOT_MIN = 1
local SLOT_MAX = 19
local INVSLOT_SHIRT = 4
local INVSLOT_TABARD = 19

Includes.SECTIONS = {
    "equipment",
    "talents",
    "bars",
    "runes",
    "consumables",
    "utilitySlots",
    "spellBindings",
    "infoFrame",
}

local DEFAULT_TRUE = {
    equipment = true,
    talents = true,
    bars = true,
    runes = true,
    consumables = true,
    utilitySlots = true,
    spellBindings = true,
    infoFrame = true,
}

local function SlotMax()
    local eq = R.Equipment
    if eq and eq.GetSlotMax then
        return eq.GetSlotMax() or SLOT_MAX
    end
    return SLOT_MAX
end

local function EngravableSlots()
    local runes = R.Runes
    if runes and runes.ENGRAVABLE_SLOTS then
        return runes.ENGRAVABLE_SLOTS
    end
    return { 5, 7, 10, 6, 8, 15, 1, 9, 11, 12 }
end

local function FindProfileName(profile)
    if type(profile) ~= "table" then
        return nil
    end
    local store = R.GetStore and R.GetStore()
    local profiles = store and store.profiles
    if type(profiles) ~= "table" then
        return nil
    end
    for name, p in pairs(profiles) do
        if p == profile then
            return name
        end
    end
    return nil
end

local function TouchProfile(profile, field)
    if type(profile) ~= "table" then
        return
    end
    profile.updatedAt = time()
    local name = FindProfileName(profile)
    if name and R.Fire then
        R.Fire("PROFILE_UPDATED", name, field or "includes")
    end
end

local function FillEquipmentSlotsFromSnapshot(equipment, dest)
    local smax = SlotMax()
    local hasEquip = type(equipment) == "table"
    for slotID = SLOT_MIN, smax do
        if dest[slotID] == nil then
            if hasEquip and equipment[slotID] ~= nil then
                dest[slotID] = true
            elseif hasEquip and (slotID == INVSLOT_SHIRT or slotID == INVSLOT_TABARD) then
                -- Old Capture omitted empty shirt/tabard (Load did not unequip).
                dest[slotID] = false
            else
                dest[slotID] = true
            end
        else
            dest[slotID] = dest[slotID] and true or false
        end
    end
end

local function FillRuneSlots(dest)
    for _, slotID in ipairs(EngravableSlots()) do
        if dest[slotID] == nil then
            dest[slotID] = true
        else
            dest[slotID] = dest[slotID] and true or false
        end
    end
end

--- Ensure `profile.includes` exists and is migrated. Returns the includes table.
function Includes.Ensure(profile)
    if type(profile) ~= "table" then
        return nil
    end
    if type(profile.includes) ~= "table" then
        profile.includes = {}
    end
    local inc = profile.includes
    for _, key in ipairs(Includes.SECTIONS) do
        if inc[key] == nil then
            inc[key] = DEFAULT_TRUE[key] ~= false
        else
            inc[key] = inc[key] and true or false
        end
    end
    if type(inc.equipmentSlots) ~= "table" then
        inc.equipmentSlots = {}
    end
    FillEquipmentSlotsFromSnapshot(profile.equipment, inc.equipmentSlots)
    if type(inc.runeSlots) ~= "table" then
        inc.runeSlots = {}
    end
    FillRuneSlots(inc.runeSlots)
    if type(inc.blizzardSet) ~= "table" then
        inc.blizzardSet = { id = nil, name = nil, managed = false }
    end
    return inc
end

function Includes.EnsureEquipmentPreset(preset)
    if type(preset) ~= "table" then
        return nil
    end
    if type(preset.equipmentSlots) ~= "table" then
        preset.equipmentSlots = {}
    end
    FillEquipmentSlotsFromSnapshot(preset.equipment, preset.equipmentSlots)
    if type(preset.blizzardSet) ~= "table" then
        preset.blizzardSet = { id = nil, name = nil, managed = false }
    end
    return preset
end

function Includes.EnsureRunePreset(preset)
    if type(preset) ~= "table" then
        return nil
    end
    if type(preset.runeSlots) ~= "table" then
        preset.runeSlots = {}
    end
    FillRuneSlots(preset.runeSlots)
    return preset
end

function Includes.MigrateAll()
    local store = R.GetStore and R.GetStore()
    if store and type(store.profiles) == "table" then
        for _, profile in pairs(store.profiles) do
            if type(profile) == "table" then
                Includes.Ensure(profile)
            end
        end
    end
    local root = _G._FluxUI_CharSavedVars
    local ep = root and root.equipmentPresets
    if type(ep) == "table" and type(ep.presets) == "table" then
        for name, preset in pairs(ep.presets) do
            if type(preset) == "table" and name ~= "default" then
                Includes.EnsureEquipmentPreset(preset)
            end
        end
    end
    local rp = root and root.runePresets
    if type(rp) == "table" and type(rp.presets) == "table" then
        for name, preset in pairs(rp.presets) do
            if type(preset) == "table" and name ~= "default" then
                Includes.EnsureRunePreset(preset)
            end
        end
    end
end

--- Profile-shaped include mask used when "No profile" is selected. Save copies it onto the new profile.
function Includes.GetDraft(create)
    local store = R.GetStore and R.GetStore()
    if not store then
        return nil
    end
    if type(store.pendingDraft) ~= "table" then
        if not create then
            return nil
        end
        store.pendingDraft = {}
    end
    Includes.Ensure(store.pendingDraft)
    return store.pendingDraft
end

function Includes.SectionOwner(profile)
    if type(profile) == "table" then
        Includes.Ensure(profile)
        return profile, "profile"
    end
    local draft = Includes.GetDraft(true)
    return draft, "draft"
end

--- Copy the No-profile include mask onto a newly created profile.
function Includes.ApplyDraftToProfile(profile)
    if type(profile) ~= "table" then
        return false
    end
    local draft = Includes.GetDraft(false)
    if type(draft) ~= "table" or type(draft.includes) ~= "table" then
        Includes.Ensure(profile)
        return false
    end
    local Compat = R.Compat
    if Compat and Compat.DeepCopy then
        profile.includes = Compat.DeepCopy(draft.includes)
    else
        profile.includes = draft.includes
    end
    Includes.Ensure(profile)
    return true
end

function Includes.SectionEnabled(profile, section)
    local owner = Includes.SectionOwner(profile)
    if type(owner) ~= "table" or type(section) ~= "string" then
        return true
    end
    local inc = Includes.Ensure(owner)
    if inc[section] == false then
        return false
    end
    return true
end

function Includes.SetSection(profile, section, enabled)
    local owner = Includes.SectionOwner(profile)
    if type(owner) ~= "table" or type(section) ~= "string" then
        return false
    end
    local inc = Includes.Ensure(owner)
    inc[section] = enabled and true or false
    TouchProfile(owner, "includes")
    return true
end

local function SlotFlag(tbl, slotID)
    slotID = tonumber(slotID)
    if not slotID or type(tbl) ~= "table" then
        return true
    end
    if tbl[slotID] == false then
        return false
    end
    return true
end

function Includes.EquipSlotEnabled(profile, slotID)
    local owner = Includes.SectionOwner(profile)
    if type(owner) ~= "table" then
        return true
    end
    local inc = Includes.Ensure(owner)
    if inc.equipment == false then
        return false
    end
    return SlotFlag(inc.equipmentSlots, slotID)
end

function Includes.SetEquipSlot(profile, slotID, enabled)
    slotID = tonumber(slotID)
    local owner = Includes.SectionOwner(profile)
    if type(owner) ~= "table" or not slotID then
        return false
    end
    local inc = Includes.Ensure(owner)
    inc.equipmentSlots[slotID] = enabled and true or false
    TouchProfile(owner, "includes")
    return true
end

function Includes.RuneSlotEnabled(profile, slotID)
    local owner = Includes.SectionOwner(profile)
    if type(owner) ~= "table" then
        return true
    end
    local inc = Includes.Ensure(owner)
    if inc.runes == false then
        return false
    end
    return SlotFlag(inc.runeSlots, slotID)
end

function Includes.SetRuneSlot(profile, slotID, enabled)
    slotID = tonumber(slotID)
    local owner = Includes.SectionOwner(profile)
    if type(owner) ~= "table" or not slotID then
        return false
    end
    local inc = Includes.Ensure(owner)
    inc.runeSlots[slotID] = enabled and true or false
    TouchProfile(owner, "includes")
    return true
end

function Includes.PresetEquipSlotEnabled(preset, slotID)
    if type(preset) ~= "table" then
        return true
    end
    Includes.EnsureEquipmentPreset(preset)
    return SlotFlag(preset.equipmentSlots, slotID)
end

function Includes.SetPresetEquipSlot(preset, slotID, enabled)
    slotID = tonumber(slotID)
    if type(preset) ~= "table" or not slotID then
        return false
    end
    Includes.EnsureEquipmentPreset(preset)
    preset.equipmentSlots[slotID] = enabled and true or false
    if R.Fire then
        R.Fire("EQUIPMENT_PRESET_CHANGED")
    end
    return true
end

function Includes.PresetRuneSlotEnabled(preset, slotID)
    if type(preset) ~= "table" then
        return true
    end
    Includes.EnsureRunePreset(preset)
    return SlotFlag(preset.runeSlots, slotID)
end

function Includes.SetPresetRuneSlot(preset, slotID, enabled)
    slotID = tonumber(slotID)
    if type(preset) ~= "table" or not slotID then
        return false
    end
    Includes.EnsureRunePreset(preset)
    preset.runeSlots[slotID] = enabled and true or false
    if R.Fire then
        R.Fire("RUNE_PRESET_CHANGED")
    end
    return true
end

--- Named equipment preset currently driving the gear strip, or nil for profile/default.
function Includes.ActiveEquipmentPreset()
    local EP = R.EquipmentPresets
    if not EP or not EP.GetActivePreset then
        return nil, nil
    end
    local name = EP.GetActivePreset()
    if not name or name == "default" then
        return nil, nil
    end
    local preset = EP.GetPreset and EP.GetPreset(name)
    if type(preset) ~= "table" then
        return nil, nil
    end
    Includes.EnsureEquipmentPreset(preset)
    return preset, name
end

function Includes.ActiveRunePreset()
    local RP = R.RunePresets
    if not RP or not RP.GetActivePreset then
        return nil, nil
    end
    local name = RP.GetActivePreset()
    if not name or name == "default" then
        return nil, nil
    end
    local preset = RP.GetPreset and RP.GetPreset(name)
    if type(preset) ~= "table" then
        return nil, nil
    end
    Includes.EnsureRunePreset(preset)
    return preset, name
end

--- Owner of gear-strip slot checks: named preset if selected, else the profile, else the No-profile draft.
function Includes.GearStripOwner(profile)
    local preset, pname = Includes.ActiveEquipmentPreset()
    if preset then
        return preset, "preset", pname
    end
    if type(profile) == "table" then
        Includes.Ensure(profile)
        return profile, "profile", FindProfileName(profile)
    end
    local draft = Includes.GetDraft(true)
    return draft, "draft", nil
end

function Includes.RuneStripOwner(profile)
    local preset, pname = Includes.ActiveRunePreset()
    if preset then
        return preset, "preset", pname
    end
    if type(profile) == "table" then
        Includes.Ensure(profile)
        return profile, "profile", FindProfileName(profile)
    end
    local draft = Includes.GetDraft(true)
    return draft, "draft", nil
end

function Includes.GearStripSlotEnabled(profile, slotID)
    local owner, kind = Includes.GearStripOwner(profile)
    if not owner then
        return true
    end
    if kind == "preset" then
        return Includes.PresetEquipSlotEnabled(owner, slotID)
    end
    return Includes.EquipSlotEnabled(owner, slotID)
end

function Includes.SetGearStripSlot(profile, slotID, enabled)
    local owner, kind = Includes.GearStripOwner(profile)
    if not owner then
        return false
    end
    if kind == "preset" then
        return Includes.SetPresetEquipSlot(owner, slotID, enabled)
    end
    return Includes.SetEquipSlot(owner, slotID, enabled)
end

function Includes.RuneStripSlotEnabled(profile, slotID)
    local owner, kind = Includes.RuneStripOwner(profile)
    if not owner then
        return true
    end
    if kind == "preset" then
        return Includes.PresetRuneSlotEnabled(owner, slotID)
    end
    return Includes.RuneSlotEnabled(owner, slotID)
end

function Includes.SetRuneStripSlot(profile, slotID, enabled)
    local owner, kind = Includes.RuneStripOwner(profile)
    if not owner then
        return false
    end
    if kind == "preset" then
        return Includes.SetPresetRuneSlot(owner, slotID, enabled)
    end
    return Includes.SetRuneSlot(owner, slotID, enabled)
end

local function CopyEnabledSlots(snapshot, isEnabled)
    local out = {}
    if type(snapshot) ~= "table" then
        return out
    end
    for slotID, want in pairs(snapshot) do
        local sid = tonumber(slotID) or slotID
        if isEnabled(sid) then
            out[sid] = want
        end
    end
    return out
end

--- Equipment snapshot containing only slots Load/Equip should touch.
function Includes.CopyEnabledEquipment(snapshot, profile)
    if type(snapshot) ~= "table" then
        return nil
    end
    if type(profile) == "table" and not Includes.SectionEnabled(profile, "equipment") then
        return {}
    end
    return CopyEnabledSlots(snapshot, function(slotID)
        if type(profile) ~= "table" then
            return true
        end
        return Includes.EquipSlotEnabled(profile, slotID)
    end)
end

function Includes.CopyEnabledPresetEquipment(snapshot, preset)
    if type(snapshot) ~= "table" then
        return nil
    end
    if type(preset) ~= "table" then
        return snapshot
    end
    Includes.EnsureEquipmentPreset(preset)
    return CopyEnabledSlots(snapshot, function(slotID)
        return Includes.PresetEquipSlotEnabled(preset, slotID)
    end)
end

function Includes.CopyEnabledRunes(snapshot, profile)
    if type(snapshot) ~= "table" then
        return nil
    end
    if type(profile) == "table" and not Includes.SectionEnabled(profile, "runes") then
        return {}
    end
    return CopyEnabledSlots(snapshot, function(slotID)
        if type(profile) ~= "table" then
            return true
        end
        return Includes.RuneSlotEnabled(profile, slotID)
    end)
end

function Includes.CopyEnabledPresetRunes(snapshot, preset)
    if type(snapshot) ~= "table" then
        return nil
    end
    if type(preset) ~= "table" then
        return snapshot
    end
    Includes.EnsureRunePreset(preset)
    return CopyEnabledSlots(snapshot, function(slotID)
        return Includes.PresetRuneSlotEnabled(preset, slotID)
    end)
end

--- Write live capture into dest only for enabled equipment slots. Unchecked slots keep dest.
function Includes.MergeEnabledEquipment(dest, live, profile)
    if type(profile) == "table" and not Includes.SectionEnabled(profile, "equipment") then
        return dest
    end
    dest = type(dest) == "table" and dest or {}
    live = type(live) == "table" and live or {}
    local smax = SlotMax()
    for slotID = SLOT_MIN, smax do
        if type(profile) ~= "table" or Includes.EquipSlotEnabled(profile, slotID) then
            dest[slotID] = live[slotID]
        end
    end
    return dest
end

function Includes.MergeEnabledPresetEquipment(dest, live, preset)
    dest = type(dest) == "table" and dest or {}
    live = type(live) == "table" and live or {}
    if type(preset) ~= "table" then
        for slotID = SLOT_MIN, SlotMax() do
            dest[slotID] = live[slotID]
        end
        return dest
    end
    Includes.EnsureEquipmentPreset(preset)
    local smax = SlotMax()
    for slotID = SLOT_MIN, smax do
        if Includes.PresetEquipSlotEnabled(preset, slotID) then
            dest[slotID] = live[slotID]
        end
    end
    return dest
end

function Includes.MergeEnabledRunes(dest, live, profile)
    if type(profile) == "table" and not Includes.SectionEnabled(profile, "runes") then
        return dest
    end
    dest = type(dest) == "table" and dest or {}
    live = type(live) == "table" and live or {}
    for _, slotID in ipairs(EngravableSlots()) do
        if type(profile) ~= "table" or Includes.RuneSlotEnabled(profile, slotID) then
            dest[slotID] = live[slotID]
        end
    end
    return dest
end

function Includes.MergeEnabledPresetRunes(dest, live, preset)
    dest = type(dest) == "table" and dest or {}
    live = type(live) == "table" and live or {}
    if type(preset) ~= "table" then
        for slotID, entry in pairs(live) do
            dest[slotID] = entry
        end
        return dest
    end
    Includes.EnsureRunePreset(preset)
    for _, slotID in ipairs(EngravableSlots()) do
        if Includes.PresetRuneSlotEnabled(preset, slotID) then
            dest[slotID] = live[slotID]
        end
    end
    return dest
end

function Includes.WantedEquipmentSlotSet(profile)
    local wanted = {}
    if type(profile) ~= "table" or not Includes.SectionEnabled(profile, "equipment") then
        return wanted
    end
    local inc = Includes.Ensure(profile)
    local smax = SlotMax()
    for slotID = SLOT_MIN, smax do
        if SlotFlag(inc.equipmentSlots, slotID) then
            wanted[slotID] = true
        end
    end
    return wanted
end

function Includes.WantedPresetEquipmentSlotSet(preset)
    local wanted = {}
    if type(preset) ~= "table" then
        return wanted
    end
    Includes.EnsureEquipmentPreset(preset)
    local smax = SlotMax()
    for slotID = SLOT_MIN, smax do
        if Includes.PresetEquipSlotEnabled(preset, slotID) then
            wanted[slotID] = true
        end
    end
    return wanted
end

function Includes.GetBlizzardSet(owner)
    if type(owner) ~= "table" then
        return nil
    end
    if owner.includes then
        Includes.Ensure(owner)
        return owner.includes.blizzardSet
    end
    Includes.EnsureEquipmentPreset(owner)
    return owner.blizzardSet
end

local function TablesEqualBoolMap(a, b)
    a = a or {}
    b = b or {}
    for k, v in pairs(a) do
        if (v and true or false) ~= (b[k] and true or false) then
            return false
        end
    end
    for k, v in pairs(b) do
        if (v and true or false) ~= (a[k] and true or false) then
            return false
        end
    end
    return true
end

function Includes.InfoFrameMatches(profile)
    if type(profile) ~= "table" or profile.infoFrame == nil then
        return true
    end
    local fn = _G.FluxInfoFrame and _G.FluxInfoFrame.SerializeRespecProfileSnapshot
    if type(fn) ~= "function" then
        return true
    end
    local live = fn()
    local saved = profile.infoFrame
    if type(live) ~= "table" or type(saved) ~= "table" then
        return false
    end
    if (not not live.showFPS) ~= (not not saved.showFPS) then
        return false
    end
    if (not not live.showDurability) ~= (not not saved.showDurability) then
        return false
    end
    if (not not live.showPing) ~= (not not saved.showPing) then
        return false
    end
    if (live.spellDisplayMode or "off") ~= (saved.spellDisplayMode or "off") then
        return false
    end
    if type(saved.statOrder) == "table" then
        local liveOrder = type(live.statOrder) == "table" and live.statOrder or {}
        if #liveOrder ~= #saved.statOrder then
            return false
        end
        for i = 1, #saved.statOrder do
            if liveOrder[i] ~= saved.statOrder[i] then
                return false
            end
        end
    end
    return TablesEqualBoolMap(live.pinnedStats, saved.pinnedStats)
end

function Includes.InfoFrameSummary(profile)
    if type(profile) ~= "table" or type(profile.infoFrame) ~= "table" then
        return "—", nil
    end
    local data = profile.infoFrame
    local n = 0
    if type(data.pinnedStats) == "table" then
        for _, v in pairs(data.pinnedStats) do
            if v then
                n = n + 1
            end
        end
    end
    local bits = {}
    if n > 0 then
        bits[#bits + 1] = n == 1 and "1 pin" or (n .. " pins")
    end
    if data.showFPS then
        bits[#bits + 1] = "FPS"
    end
    if data.showDurability then
        bits[#bits + 1] = "dura"
    end
    if data.showPing then
        bits[#bits + 1] = "ping"
    end
    local text = (#bits > 0) and table.concat(bits, ", ") or "saved"
    local tag = Includes.InfoFrameMatches(profile) and "[matches]" or "[diff]"
    if not Includes.SectionEnabled(profile, "infoFrame") then
        tag = nil
    end
    return text, tag
end

R.Includes = Includes
