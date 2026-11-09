--[[
    Inventory/FluxConsumableBest/VendorMemory.lua

    Soft vendor memory from merchant index (non-conjured only).
]]

FluxConsumableBest = FluxConsumableBest or {}
local Best = FluxConsumableBest
Best.VendorMemory = Best.VendorMemory or {}
local VM = Best.VendorMemory

local hooked = false

local function MerchantLink(info)
    if type(info) ~= "table" then
        return nil
    end
    if info.link then
        return info.link
    end
    if info.slot and GetMerchantItemLink then
        return GetMerchantItemLink(info.slot)
    end
    return nil
end

local function ClassifyVendorItem(itemID, info)
    local Classify = _G.FluxConsumableClassify
    if not Classify or not Classify.Classify then
        return nil
    end
    local link = MerchantLink(info)
    local cls = Classify.Classify(itemID, link)
    if not cls or not Best.IsValidKind(cls.kind) then
        return nil
    end
    if not Best.IsManaKindRelevant(cls.kind) then
        return nil
    end
    if cls.isConjured then
        return nil
    end
    local Score = Best.Score
    if Score.IsUsableForVendor then
        if not Score.IsUsableForVendor(itemID, cls.kind) then
            return nil
        end
    elseif Score.IsUsable and not Score.IsUsable(itemID, cls.kind) then
        return nil
    end
    local maxHP, maxMana = Score.GetPools()
    local effective = Score.EffectiveFromClassify(cls, maxHP, maxMana)
    if effective <= 0 then
        return nil
    end
    local price = type(info) == "table" and (info.unitPrice or info.price) or nil
    return {
        itemID = itemID,
        kind = cls.kind,
        effective = effective,
        isPercent = cls.isPercent and true or false,
        restoreRaw = cls.effective or effective,
        isConjured = false,
        price = tonumber(price),
        source = "vendor",
    }
end

--- Process a merchant index map: itemID -> { slot, price, unitPrice, ... }
--- Chunked across frames so browsing a large vendor does not hitch.
function VM.OnMerchantIndex(merchantIndex)
    if type(merchantIndex) ~= "table" then
        return
    end
    local Persist = Best.Persist
    local list = {}
    for itemID, info in pairs(merchantIndex) do
        itemID = tonumber(itemID) or (type(info) == "table" and tonumber(info.itemID))
        if itemID and type(info) == "table" and info.isPurchasable ~= false then
            list[#list + 1] = { itemID = itemID, info = info }
        end
    end
    if #list == 0 then
        return
    end

    VM._indexWorkGen = (VM._indexWorkGen or 0) + 1
    local myGen = VM._indexWorkGen
    local CHUNK = 8
    local i = 1
    local changed = false

    local function After(delay, fn)
        if C_Timer and C_Timer.After then
            C_Timer.After(delay, fn)
        else
            fn()
        end
    end

    local function step()
        if myGen ~= VM._indexWorkGen then
            return
        end
        local limit = math.min(i + CHUNK - 1, #list)
        while i <= limit do
            local entry = list[i]
            local cand = ClassifyVendorItem(entry.itemID, entry.info)
            if cand then
                if Persist.RememberVendorItem(entry.itemID, cand) then
                    changed = true
                end
                if Persist.MaybeUpdateRef(cand.kind, cand) then
                    changed = true
                end
            end
            i = i + 1
        end
        if i <= #list then
            After(0, step)
            return
        end
        if changed and Best.RequestRecompute then
            Best.RequestRecompute({ reason = "vendor" })
        elseif changed then
            Best._dirty = true
        end
    end

    -- Defer first chunk off the index-ready frame.
    After(0, step)
end

function VM.HookMerchantIndex()
    if hooked then
        return
    end
    local register = nil
    local Auto = _G.FluxVendorAuto
    local Buy = _G.FluxVendorBuy
    if Auto and Auto.RegisterMerchantIndexListener then
        register = Auto.RegisterMerchantIndexListener
    elseif Buy and Buy.RegisterMerchantIndexListener then
        register = Buy.RegisterMerchantIndexListener
    end
    if register then
        register(function(index)
            pcall(VM.OnMerchantIndex, index)
        end)
        hooked = true
        return
    end
    -- Soft retry until Restock vendor module loads.
    if C_Timer and C_Timer.After then
        C_Timer.After(2, function()
            if not hooked then
                VM.HookMerchantIndex()
            end
        end)
    end
end

--- Candidate entries from persisted vendorSeen for ranking when not owned.
function VM.GetVendorCandidates(kind)
    local out = {}
    if not Best.IsValidKind(kind) or not Best.IsManaKindRelevant(kind) then
        return out
    end
    local seen = Best.Persist.GetAllVendorSeen()
    local Score = Best.Score
    for itemID, info in pairs(seen) do
        if type(info) == "table" and info.kind == kind then
            itemID = tonumber(itemID)
            local usable = Score.IsUsableForVendor and Score.IsUsableForVendor(itemID, kind)
                or (Score.IsUsable and Score.IsUsable(itemID, kind))
            if itemID and usable then
                -- Prefer persisted effective; avoid re-Classify on every Best scan.
                local effective = tonumber(info.effective) or 0
                out[#out + 1] = {
                    itemID = itemID,
                    kind = kind,
                    effective = effective,
                    isPercent = info.isPercent and true or false,
                    isConjured = false,
                    price = info.price,
                    count = 0,
                    source = "vendor",
                    locations = {},
                }
            end
        end
    end
    return out
end

_G.FluxConsumableBest = Best
return VM
