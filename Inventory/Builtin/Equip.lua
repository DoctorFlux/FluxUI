-- Inventory/Builtin/Equip.lua — equipped slot snapshot
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Builtin = Inv.Builtin

local Equip = {}
Builtin.Equip = Equip

local dirty = true

local FIRST = 0
local LAST = _G.INVSLOT_LAST_EQUIPPED or 19

local function SlotRange()
	local last = LAST
	if _G.INVSLOT_RANGED ~= nil then
		last = math.max(last, _G.INVSLOT_RANGED)
	end
	if _G.INVSLOT_FIRST_EQUIPPED ~= nil then
		last = math.max(last, _G.INVSLOT_FIRST_EQUIPPED)
	end
	return FIRST, last
end

local function Wipe(t)
	if wipe then
		return wipe(t)
	end
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

local function NumericID(value)
	local n = tonumber(value)
	if n and n > 0 then
		return n
	end
	if Flux.Secrets and Flux.Secrets.SafeGetNumber then
		n = Flux.Secrets.SafeGetNumber(value, 0)
		if n and n > 0 then
			return n
		end
	end
	return nil
end

local lastSignature

local function Signature()
	local first, last = SlotRange()
	local parts = {}
	for slot = first, last do
		local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
		local count = GetInventoryItemCount and GetInventoryItemCount("player", slot)
		parts[#parts + 1] = (link or "-") .. "#" .. tostring(count or 0)
	end
	return table.concat(parts, "|")
end

--- True when an equipped link or count differs from the last Refresh.
function Equip.HasChanged()
	local ok, sig = pcall(Signature)
	return not ok or sig ~= lastSignature
end

function Equip.MarkDirty()
	dirty = true
end

function Equip.Invalidate()
	dirty = true
end

function Equip.Refresh()
	if not dirty then
		return
	end
	local snap = Inv.snapshots.equip
	local bySlot = snap.bySlot
	local counts = {}
	Wipe(bySlot)
	local first, last = SlotRange()
	for slot = first, last do
		local itemID = GetInventoryItemID and GetInventoryItemID("player", slot)
		itemID = NumericID(itemID)
		if not itemID and GetInventoryItemLink then
			local link = GetInventoryItemLink("player", slot)
			if link then
				itemID = tonumber(string.match(link, "item:(%d+)"))
			end
		end
		if itemID then
			local count = 1
			if GetInventoryItemCount then
				count = GetInventoryItemCount("player", slot) or 1
			end
			local link = GetInventoryItemLink and GetInventoryItemLink("player", slot) or nil
			bySlot[slot] = { itemID = itemID, count = count, link = link }
			counts[itemID] = (counts[itemID] or 0) + count
		end
	end
	snap.counts = counts
	snap.generation = (snap.generation or 0) + 1
	dirty = false
	local ok, sig = pcall(Signature)
	lastSignature = ok and sig or nil
	local Store = Inv.Store
	if Store and Store.BindLive then
		Store.BindLive("equipped", bySlot)
		Store.MarkPending(nil, "all")
	end
end
