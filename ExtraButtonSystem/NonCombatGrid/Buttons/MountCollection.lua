--[[
    ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua
    Mount Journal / companion path helpers (SmartMount + VendorMount).

    Owns collected name→mountID/icon map. Full button lifecycle lives in Mount.lua.
    Bag-item flyout lives in MountItems.lua.
]]

FluxNCMountCollection = FluxNCMountCollection or {}
local Coll = FluxNCMountCollection

local VENDOR_MOUNT_NAMES = {
    "Trader's Gilded Brutosaur",
    "Grand Expedition Yak",
    "Traveler's Tundra Mammoth",
}

local BRUTOSAUR_NAME = "Trader's Gilded Brutosaur"
local YAK_NAME = "Grand Expedition Yak"

-- Spell identity is locale independent. Priority and supported vendors are
-- unchanged; names/icons/macros always come from the client's collection.
-- Both faction variants of Traveler's Tundra Mammoth share one priority.
local VENDOR_SPELLS = { { 465235 }, { 122708 }, { 61425, 61447 } }

Coll.VENDOR_MOUNT_NAMES = VENDOR_MOUNT_NAMES
Coll.BRUTOSAUR_NAME = BRUTOSAUR_NAME
Coll.YAK_NAME = YAK_NAME
Coll.MODE_SMART = "SmartMount"
Coll.MODE_VENDOR = "VendorMount"

-- name (lower) → { id, name, spellID, icon, isUsable }
local collectedByName = nil
local collectedBySpell = nil
-- companion index map (lower name → { id=index, name, spellID, icon, isUsable=true })
local companionByName = nil
local companionBySpell = nil

local function GetMajorVersion()
    if FLUX_API and FLUX_API.majorVersion then
        return FLUX_API.majorVersion
    end
    local v = GetBuildInfo and GetBuildInfo()
    return tonumber(type(v) == "string" and v:match("^(%d+)") or 0) or 0
end

function Coll.HasMountJournalAPI()
    if FLUX_API and FLUX_API.hasC_MountJournal ~= nil then
        return FLUX_API.hasC_MountJournal and C_MountJournal ~= nil
    end
    return C_MountJournal and C_MountJournal.GetMountIDs ~= nil
end

function Coll.HasCompanionAPI()
    return type(GetNumCompanions) == "function"
end

--- True when mounts come from journal/companions (not bag items).
function Coll.HasMountUI()
    if FLUX_API then
        if FLUX_API.isClassicEra or FLUX_API.isTBC then
            return false
        end
    end
    if GetMajorVersion() <= 2 then
        return false
    end
    return Coll.HasMountJournalAPI() or Coll.HasCompanionAPI()
end

function Coll.InvalidateCollectedMountMap()
    collectedByName = nil
    collectedBySpell = nil
    companionByName = nil
    companionBySpell = nil
end

local function EnsureCollectedMountMap()
    if collectedByName then
        return
    end
    collectedByName = {}
    collectedBySpell = {}
    if Coll.HasMountJournalAPI() and C_MountJournal and C_MountJournal.GetMountIDs then
        local ids = C_MountJournal.GetMountIDs()
        if type(ids) == "table" then
            for _, mountID in ipairs(ids) do
                local creatureName, spellID, icon, _, isUsable, _, _, _, _, _, isCollected =
                    C_MountJournal.GetMountInfoByID(mountID)
                if isCollected and creatureName then
                    local entry = {
                        id = mountID,
                        name = creatureName,
                        spellID = spellID,
                        icon = icon,
                        isUsable = isUsable,
                    }
                    collectedByName[creatureName:lower()] = entry
                    if spellID then collectedBySpell[spellID] = entry end
                end
            end
        end
    end
end

local function EnsureCompanionMountMap()
    if companionByName then
        return
    end
    companionByName = {}
    companionBySpell = {}
    if not Coll.HasCompanionAPI() then
        return
    end
    local n = GetNumCompanions("MOUNT") or 0
    for i = 1, n do
        local creatureID, creatureName, spellID, icon = GetCompanionInfo("MOUNT", i)
        if creatureName then
            local entry = {
                id = i,
                name = creatureName,
                spellID = spellID,
                icon = icon,
                isUsable = true,
                creatureID = creatureID,
            }
            companionByName[creatureName:lower()] = entry
            if spellID then companionBySpell[spellID] = entry end
        end
    end
end

--- @return table|nil { id, name, spellID, icon, isUsable }
function Coll.GetCollectedMountByName(mountName)
    if not mountName then
        return nil
    end
    local key = mountName:lower()
    EnsureCollectedMountMap()
    local entry = collectedByName[key]
    if entry then
        return entry
    end
    EnsureCompanionMountMap()
    return companionByName[key]
end

local function VendorEntry(priority)
    EnsureCollectedMountMap()
    EnsureCompanionMountMap()
    local fallback
    for _, spellID in ipairs(VENDOR_SPELLS[priority]) do
        local entry = collectedBySpell[spellID] or companionBySpell[spellID]
        if entry then
            if entry.isUsable ~= false then return entry end
            fallback = fallback or entry
        end
    end
    return fallback
end

local function MountOwned(entry)
    if entry then
        return true, entry.id, entry.isUsable ~= false
    end
    return false
end

function Coll.HasAnyVendorMount()
    return Coll.GetBestVendorMount() ~= nil
end

function Coll.HasBrutosaur()
    return MountOwned(VendorEntry(1))
end

function Coll.HasYak()
    return MountOwned(VendorEntry(2))
end

function Coll.GetBestVendorMount()
    for priority = 1, #VENDOR_SPELLS do
        local entry = VendorEntry(priority)
        if entry then
            return entry
        end
    end
    return nil
end

function Coll.GetBrutosaur()
    return VendorEntry(1)
end

function Coll.GetYak()
    return VendorEntry(2)
end

-- Soft-attach onto FluxNCMount when present (Mount.lua may redefine with richer logic)
local function AttachToMountModule()
    local M = _G.FluxNCMount
    if not M then
        return
    end
    M.HasMountUI = M.HasMountUI or Coll.HasMountUI
    if not M.HasAnyVendorMount then
        M.HasAnyVendorMount = Coll.HasAnyVendorMount
    end
    if not M.HasBrutosaur then
        M.HasBrutosaur = Coll.HasBrutosaur
    end
    if not M.HasYak then
        M.HasYak = Coll.HasYak
    end
    if not M.GetBestVendorMount then
        M.GetBestVendorMount = Coll.GetBestVendorMount
    end
    if not M.GetBrutosaur then
        M.GetBrutosaur = Coll.GetBrutosaur
    end
    if not M.GetYak then
        M.GetYak = Coll.GetYak
    end
end

AttachToMountModule()
_G.FluxNCMountCollection = Coll
return Coll
