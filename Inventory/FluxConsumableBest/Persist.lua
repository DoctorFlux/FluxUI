--[[
    Inventory/FluxConsumableBest/Persist.lua

    Per-character SavedVariables: non-conjured best refs + vendorSeen only.
]]

FluxConsumableBest = FluxConsumableBest or {}
local Best = FluxConsumableBest
Best.Persist = Best.Persist or {}
local Persist = Best.Persist

local function EnsureRoot()
    _G._FluxUI_CharSavedVars = _G._FluxUI_CharSavedVars or {}
    local root = _G._FluxUI_CharSavedVars.ConsumableBest
    if type(root) ~= "table" then
        root = { refs = {}, vendorSeen = {} }
        _G._FluxUI_CharSavedVars.ConsumableBest = root
    end
    root.refs = root.refs or {}
    root.vendorSeen = root.vendorSeen or {}
    return root
end

function Persist.GetRoot()
    return EnsureRoot()
end

function Persist.GetRef(kind)
    if not Best.IsValidKind(kind) then
        return nil
    end
    local refs = EnsureRoot().refs
    local ref = refs[kind]
    if type(ref) ~= "table" or not tonumber(ref.itemID) then
        return nil
    end
    -- Scrub legacy/bad writes: conjured IDs must never live in refs.
    if ref.isConjured then
        refs[kind] = nil
        return nil
    end
    -- Scrub refs on known level/skill/class gates and combat-utility potions
    -- that used to classify as healPotion (Holy Protection persist).
    -- Never use IsUsableItem: cold login false-negatives deleted last-session food/potion refs.
    local Score = Best.Score
    if Score and Score.IsBlockedForBest and Score.IsBlockedForBest(ref.itemID, kind) then
        refs[kind] = nil
        return nil
    end
    return ref
end

function Persist.GetAllRefs()
    return EnsureRoot().refs
end

--- Ratchet a non-conjured owned/vendor discovery into refs if better.
--- Never writes conjured itemIDs. Never writes items the player cannot use yet.
function Persist.MaybeUpdateRef(kind, candidate)
    if not Best.IsValidKind(kind) or type(candidate) ~= "table" then
        return false
    end
    if candidate.isConjured then
        return false
    end
    local itemID = tonumber(candidate.itemID)
    if not itemID then
        return false
    end
    local Score = Best.Score
    -- Vendor discoveries are not owned yet; IsUsableItem often lies for those IDs.
    local usableOk = true
    if candidate.source == "vendor" and Score and Score.IsUsableForVendor then
        usableOk = Score.IsUsableForVendor(itemID, kind)
    elseif Score and Score.IsUsable then
        usableOk = Score.IsUsable(itemID, kind)
    end
    if not usableOk then
        return false
    end
    local existing = Persist.GetRef(kind)
    local nextRef = {
        itemID = itemID,
        effective = candidate.effective or 0,
        isPercent = candidate.isPercent and true or false,
        restoreRaw = candidate.restoreRaw or candidate.effective or 0,
        count = tonumber(candidate.count) or 0,
        source = candidate.source or "owned",
    }
    if existing then
        local a = {
            itemID = nextRef.itemID,
            effective = nextRef.effective,
            isConjured = false,
            price = candidate.price,
        }
        local b = {
            itemID = existing.itemID,
            effective = existing.effective or 0,
            isConjured = false,
            price = nil,
        }
        if not Score.IsBetter(a, b, false) then
            return false
        end
    end
    EnsureRoot().refs[kind] = nextRef
    return true
end

function Persist.GetVendorSeen(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    return EnsureRoot().vendorSeen[itemID]
end

--- Remember a non-conjured vendor item. Never stores conjured IDs.
function Persist.RememberVendorItem(itemID, info)
    itemID = tonumber(itemID)
    if not itemID or type(info) ~= "table" then
        return false
    end
    if info.isConjured then
        return false
    end
    local root = EnsureRoot()
    root.vendorSeen[itemID] = {
        kind = info.kind,
        effective = info.effective or 0,
        isPercent = info.isPercent and true or false,
        restoreRaw = info.restoreRaw or info.effective or 0,
        price = info.price,
        lastSeen = time and time() or 0,
    }
    return true
end

function Persist.GetAllVendorSeen()
    return EnsureRoot().vendorSeen
end

_G.FluxConsumableBest = Best
return Persist
