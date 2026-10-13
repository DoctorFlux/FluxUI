--[[
    Inventory/FluxInv/FluxInv_Equip.lua

    Equipped inventory slot snapshot for FluxInv.
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Equip = Inv.Equip or {}
local Equip = Inv.Equip

local wipe = table.wipe or wipe

local slots = {} -- [invSlot] = { itemID, count, link }
local counts = {} -- itemID -> count
local dirty = true
local generation = 0

local FIRST = _G.INVSLOT_FIRST_EQUIPPED or 1
local LAST = _G.INVSLOT_LAST_EQUIPPED or 19

local function slotRange()
    local first, last = FIRST, LAST
    -- Classic: include ammo (0) and ranged if defined
    if _G.INVSLOT_AMMO ~= nil then
        first = math.min(first, _G.INVSLOT_AMMO)
    end
    if _G.INVSLOT_RANGED ~= nil then
        last = math.max(last, _G.INVSLOT_RANGED)
    end
    return first, last
end

function Equip.MarkDirty()
    dirty = true
end

function Equip.Invalidate()
    dirty = true
end

function Equip.Refresh()
    if not dirty then
        return true
    end
    wipe(slots)
    wipe(counts)
    local first, last = slotRange()
    for slot = first, last do
        local itemID
        if GetInventoryItemID then
            itemID = GetInventoryItemID("player", slot)
        end
        if not itemID and GetInventoryItemLink then
            local link = GetInventoryItemLink("player", slot)
            if link then
                itemID = tonumber(link:match("item:(%d+)"))
            end
        end
        if itemID then
            local count = 1
            if GetInventoryItemCount then
                count = GetInventoryItemCount("player", slot) or 1
            end
            local link = GetInventoryItemLink and GetInventoryItemLink("player", slot) or nil
            slots[slot] = { itemID = itemID, count = count, link = link }
            counts[itemID] = (counts[itemID] or 0) + count
        end
    end
    dirty = false
    generation = generation + 1
    return true
end

function Equip.GetCount(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    Equip.Refresh()
    return counts[itemID] or 0
end

function Equip.GetCounts()
    Equip.Refresh()
    return counts
end

function Equip.GetSlot(invSlot)
    Equip.Refresh()
    return slots[invSlot]
end

function Equip.GetSlots()
    Equip.Refresh()
    return slots
end

function Equip.FindStacks(itemID)
    itemID = tonumber(itemID)
    local out = {}
    if not itemID then
        return out
    end
    Equip.Refresh()
    for slot, rec in pairs(slots) do
        if rec.itemID == itemID then
            out[#out + 1] = {
                bag = nil,
                slot = slot,
                count = rec.count,
                region = "equip",
                invSlot = slot,
                link = rec.link,
            }
        end
    end
    return out
end

function Equip.GetSnapshot()
    Equip.Refresh()
    return {
        counts = counts,
        slots = slots,
        generation = generation,
        region = "equip",
    }
end

_G.FluxInv = Inv
