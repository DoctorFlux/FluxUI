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

Coll.VENDOR_MOUNT_NAMES = VENDOR_MOUNT_NAMES
Coll.BRUTOSAUR_NAME = BRUTOSAUR_NAME
Coll.YAK_NAME = YAK_NAME
Coll.MODE_SMART = "SmartMount"
Coll.MODE_VENDOR = "VendorMount"

-- name (lower) → { id, name, spellID, icon, isUsable }
local collectedByName = nil
-- companion index map (lower name → { id=index, name, spellID, icon, isUsable=true })
local companionByName = nil

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
    companionByName = nil
end

local function EnsureCollectedMountMap()
    if collectedByName then
        return
    end
    collectedByName = {}
    if Coll.HasMountJournalAPI() and C_MountJournal and C_MountJournal.GetMountIDs then
        local ids = C_MountJournal.GetMountIDs()
        if type(ids) == "table" then
            for _, mountID in ipairs(ids) do
                local creatureName, spellID, icon, _, isUsable, _, _, _, _, _, isCollected =
                    C_MountJournal.GetMountInfoByID(mountID)
                if isCollected and creatureName then
                    collectedByName[creatureName:lower()] = {
                        id = mountID,
                        name = creatureName,
                        spellID = spellID,
                        icon = icon,
                        isUsable = isUsable,
                    }
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
    if not Coll.HasCompanionAPI() then
        return
    end
    local n = GetNumCompanions("MOUNT") or 0
    for i = 1, n do
        local creatureID, creatureName, spellID, icon = GetCompanionInfo("MOUNT", i)
        if creatureName then
            companionByName[creatureName:lower()] = {
                id = i,
                name = creatureName,
                spellID = spellID,
                icon = icon,
                isUsable = true,
                creatureID = creatureID,
            }
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

local function MountNameOwned(name)
    local entry = Coll.GetCollectedMountByName(name)
    if entry then
        return true, entry.id, entry.isUsable ~= false
    end
    return false
end

function Coll.HasAnyVendorMount()
    for _, name in ipairs(VENDOR_MOUNT_NAMES) do
        if MountNameOwned(name) then
            return true
        end
    end
    return false
end

function Coll.HasBrutosaur()
    return MountNameOwned(BRUTOSAUR_NAME)
end

function Coll.HasYak()
    return MountNameOwned(YAK_NAME)
end

function Coll.GetBestVendorMount()
    for _, name in ipairs(VENDOR_MOUNT_NAMES) do
        local entry = Coll.GetCollectedMountByName(name)
        if entry then
            return entry
        end
    end
    return nil
end

function Coll.GetBrutosaur()
    return Coll.GetCollectedMountByName(BRUTOSAUR_NAME)
end

function Coll.GetYak()
    return Coll.GetCollectedMountByName(YAK_NAME)
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
