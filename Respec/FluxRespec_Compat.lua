-- FluxRespec_Compat.lua
-- Client capability helpers for the Respec system.
-- Must load before FluxRespec_Core.lua because Core reads these flags at
-- namespace boot time.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.Compat = R.Compat or {}
local Compat = R.Compat

local addonName, addonTable = ...
local ns = addonTable or {}

-- Safe access to FLUX_API (populated by FluxAPICompat.lua earlier in the TOC).
local function Flux()
    return _G.FLUX_API or {}
end

--- Is the current client Season of Discovery (i.e. Engraving enabled)?
function Compat.IsSoD()
    if C_Engraving and C_Engraving.IsEngravingEnabled then
        local ok, enabled = pcall(C_Engraving.IsEngravingEnabled)
        if ok then
            return enabled == true
        end
    end
    return false
end

--- Does the current client support the dual talent group API?
--- Classic Era and SoD do NOT have dual spec.
--- Wrath Classic / Cata Classic and Retail do.
--- Uses the same source as GetNumGroups() (including _G.GetNumTalentGroups fallback);
--- the old check only trusted ns.API and could miss dual spec when globals still report 2.
function Compat.HasDualSpec()
    local api = Flux()
    local projectSupports =
        api.isWrath == true
        or api.isCata == true
        or (api.isRetail == true)

    if not projectSupports then
        return false
    end

    local n = Compat.GetNumGroups()
    return type(n) == "number" and n >= 2
end

--- Does the current client require a trainer visit to reset talents?
--- Classic Era and SoD do. TBC/Wrath/Cata/Retail auto-unlearn when learning
--- a conflicting build.
function Compat.NeedsTrainerReset()
    local api = Flux()
    if api.isClassicEra == true then
        return true
    end
    if Compat.IsSoD and Compat.IsSoD() then
        return true
    end
    return false
end

--- Retail-specific loadout system check (for future-proofing).
function Compat.HasTalentLoadouts()
    local api = Flux()
    return api.isRetail == true and api.isV12 == true
        or (api.isRetail == true and C_ClassTalents ~= nil)
end

function Compat.CanUseEquipmentSets()
    local api = _G.C_EquipmentSet
    if type(api) ~= "table" then
        return false
    end
    if type(api.CanUseEquipmentSets) == "function" then
        local ok, can = pcall(api.CanUseEquipmentSets)
        return ok and can == true
    end
    return type(api.UseEquipmentSet) == "function"
end

function Compat.EquipmentSlotMax()
    local last = _G.INVSLOT_LAST_EQUIPPED or 19
    local sec = rawget(_G, "INVSLOT_SECONDARY_SHOULDER")
    if type(sec) == "number" and sec > last then
        return sec
    end
    if Compat.IsSoD() then
        return math.max(last, 20)
    end
    return last
end

--- Short textual identifier of the active client, for stamping profiles.
function Compat.ClientTag()
    local api = Flux()
    if Compat.IsSoD() then
        return "SoD"
    end
    if api.isClassicEra then return "ClassicEra" end
    if api.isWrath then return "Wrath" end
    if api.isCata then return "Cata" end
    if api.isRetail then return "Retail" end
    return "Unknown"
end

--- Cross-client pcall'd talent group accessors. Prefer ns.API.* but fall
--- back to raw globals.
function Compat.GetActiveGroup()
    if ns.API and ns.API.GetActivePlayerTalentGroup then
        local ok, g = pcall(ns.API.GetActivePlayerTalentGroup)
        if ok and type(g) == "number" then return g end
    end
    if _G.GetActiveTalentGroup then
        local ok, g = pcall(_G.GetActiveTalentGroup, false, false)
        if ok and type(g) == "number" then return g end
    end
    return 1
end

function Compat.GetNumGroups()
    if ns.API and ns.API.GetNumPlayerTalentGroups then
        local ok, n = pcall(ns.API.GetNumPlayerTalentGroups)
        if ok and type(n) == "number" then return n end
    end
    if _G.GetNumTalentGroups then
        local ok, n = pcall(_G.GetNumTalentGroups, false, false)
        if ok and type(n) == "number" then return n end
    end
    return 1
end

function Compat.SetActiveGroup(groupIndex)
    if ns.API and ns.API.SetActivePlayerTalentGroup then
        local ok, ret = pcall(ns.API.SetActivePlayerTalentGroup, groupIndex)
        if ok then return ret ~= false end
    end
    if _G.SetActiveTalentGroup then
        local ok = pcall(_G.SetActiveTalentGroup, groupIndex)
        return ok
    end
    return false
end

--- Cross-client container item info (C_Container in Wrath+ / retail,
--- legacy globals in Classic Era).
function Compat.GetContainerNumSlots(bag)
    if _G.C_Container and _G.C_Container.GetContainerNumSlots then
        local ok, n = pcall(_G.C_Container.GetContainerNumSlots, bag)
        if ok and type(n) == "number" then return n end
    end
    if _G.GetContainerNumSlots then
        local ok, n = pcall(_G.GetContainerNumSlots, bag)
        if ok and type(n) == "number" then return n end
    end
    return 0
end

function Compat.GetContainerItemID(bag, slot)
    if _G.C_Container and _G.C_Container.GetContainerItemID then
        local ok, id = pcall(_G.C_Container.GetContainerItemID, bag, slot)
        if ok then return id end
    end
    if _G.GetContainerItemID then
        local ok, id = pcall(_G.GetContainerItemID, bag, slot)
        if ok then return id end
    end
    return nil
end

function Compat.GetContainerItemLink(bag, slot)
    if _G.C_Container and _G.C_Container.GetContainerItemLink then
        local ok, link = pcall(_G.C_Container.GetContainerItemLink, bag, slot)
        if ok then return link end
    end
    if _G.GetContainerItemLink then
        local ok, link = pcall(_G.GetContainerItemLink, bag, slot)
        if ok then return link end
    end
    return nil
end

function Compat.PickupContainerItem(bag, slot)
    local lock = _G.FluxRespec and _G.FluxRespec.GearSetLock
    if lock and lock.ShouldBlockContainerPickup and lock.ShouldBlockContainerPickup(bag, slot) then
        if lock.NotifyBlocked then
            lock.NotifyBlocked()
        end
        return false
    end
    if _G.C_Container and _G.C_Container.PickupContainerItem then
        local ok = pcall(_G.C_Container.PickupContainerItem, bag, slot)
        return ok
    end
    if _G.PickupContainerItem then
        local ok = pcall(_G.PickupContainerItem, bag, slot)
        return ok
    end
    return false
end

--- Extract an itemID from a link or string. Returns nil if not parseable.
function Compat.ParseItemID(link)
    if not link then return nil end
    if type(link) == "number" then return link end
    if type(link) ~= "string" then return nil end
    local id = link:match("|Hitem:(%d+):")
    if id then return tonumber(id) end
    id = link:match("^item:(%d+):")
    if id then return tonumber(id) end
    return tonumber(link)
end

--- Shallow table copy (for persisting snapshots into saved vars safely).
function Compat.ShallowCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do out[k] = v end
    return out
end

--- Deep copy (for nested snapshots).
function Compat.DeepCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = Compat.DeepCopy(v)
        else
            out[k] = v
        end
    end
    return out
end

--- True while the ESC game menu or Edit Mode UI is active. Respec must not run insecure layout, UI.Refresh,
--- unit-frame spec hooks, or StaticPopup_Show post-hook work in that window — it taints secure Log Out / menu
--- callbacks (GameMenuFrame InitButtons, etc.).
function Compat.SecureUIPanelsBlockRespecWork()
    local gm = _G.GameMenuFrame
    if gm then
        if gm.IsShown and gm:IsShown() then
            return true
        end
        if gm.IsVisible and gm:IsVisible() then
            return true
        end
    end
    local em = _G.EditModeManagerFrame
    if em then
        if em.IsShown and em:IsShown() then
            return true
        end
        if em.IsVisible and em:IsVisible() then
            return true
        end
        if em.IsEditModeActive then
            local ok, active = pcall(em.IsEditModeActive, em)
            if ok and active then
                return true
            end
        end
    end
    return false
end

R.Compat = Compat
