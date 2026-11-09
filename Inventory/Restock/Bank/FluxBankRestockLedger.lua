--[[
    Restock/Bank/FluxBankRestockLedger.lua

    Per bank-slot lifecycle for restock: idle → reserved/moving → confirm or
    release. Replaces overloaded session.inFlight / isSkipped / cooldown maps.
]]

FluxBankRestockLedger = FluxBankRestockLedger or {}
local Ledger = FluxBankRestockLedger

local STATE_RESERVED = "reserved"
local STATE_MOVING = "moving"
local STATE_COOLDOWN = "cooldown"
local STATE_SKIPPED = "skipped"

local entries = {}

local function slotKey(bag, slot)
    return tostring(bag) .. ":" .. tostring(slot)
end

local function now()
    if GetTime then
        return GetTime()
    end
    return 0
end

function Ledger.Reset()
    wipe(entries)
end

--- Reserve a bank slot for an in-flight move (whole async or split cursor).
function Ledger.Reserve(bag, slot, info)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return
    end
    info = type(info) == "table" and info or {}
    local key = slotKey(bag, slot)
    entries[key] = {
        state = info.async and STATE_MOVING or STATE_RESERVED,
        kind = info.kind or "whole",
        credit = tonumber(info.credit) or 0,
        itemID = info.itemID,
        at = info.at or now(),
        until_ = nil,
    }
end

--- Credit confirmed — slot is selectable again.
function Ledger.Confirm(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return
    end
    entries[slotKey(bag, slot)] = nil
end

--- Release reservation; optional transient cooldown on soft failures.
function Ledger.Release(bag, slot, reason, cooldownSecs)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return
    end
    local key = slotKey(bag, slot)
    if reason == "cooldown" or reason == "place_failed" then
        entries[key] = {
            state = STATE_COOLDOWN,
            until_ = now() + (tonumber(cooldownSecs) or 2),
        }
    else
        entries[key] = nil
    end
end

function Ledger.MarkSkipped(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return
    end
    entries[slotKey(bag, slot)] = { state = STATE_SKIPPED }
end

function Ledger.SetCooldown(bag, slot, secs)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return
    end
    entries[slotKey(bag, slot)] = {
        state = STATE_COOLDOWN,
        until_ = now() + (tonumber(secs) or 2),
    }
end

function Ledger.ClearSkipped(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return
    end
    local key = slotKey(bag, slot)
    local e = entries[key]
    if e and e.state == STATE_SKIPPED then
        entries[key] = nil
    end
end

function Ledger.IsReserved(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return false
    end
    local e = entries[slotKey(bag, slot)]
    return e ~= nil
        and (e.state == STATE_RESERVED or e.state == STATE_MOVING)
end

function Ledger.IsSelectable(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return true
    end
    local key = slotKey(bag, slot)
    local e = entries[key]
    if not e then
        return true
    end
    if e.state == STATE_COOLDOWN then
        if e.until_ and now() >= e.until_ then
            entries[key] = nil
            return true
        end
        return false
    end
    if e.state == STATE_SKIPPED then
        return false
    end
    if e.state == STATE_RESERVED or e.state == STATE_MOVING then
        return false
    end
    return true
end

function Ledger.HasAnyReserved()
    for _, e in pairs(entries) do
        if e.state == STATE_RESERVED or e.state == STATE_MOVING then
            return true
        end
    end
    return false
end

function Ledger.ClearStale(maxAge)
    maxAge = tonumber(maxAge) or 5
    local t = now()
    for key, e in pairs(entries) do
        if e and (e.state == STATE_RESERVED or e.state == STATE_MOVING) then
            if (t - (e.at or 0)) > maxAge then
                entries[key] = nil
            end
        end
    end
end

function Ledger.ReleaseAll()
    wipe(entries)
end

function Ledger.WipeSkipped()
    for key, e in pairs(entries) do
        if e and e.state == STATE_SKIPPED then
            entries[key] = nil
        end
    end
end

function Ledger.IsSkippedStack(st)
    if not st or not st.bag or not st.slot then
        return false
    end
    return not Ledger.IsSelectable(st.bag, st.slot)
end

_G.FluxBankRestockLedger = Ledger
return Ledger
