-- Inventory/Builtin/Bags.lua — incremental dirty-bag snapshot
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Builtin = Inv.Builtin
local C = Inv.Containers

local Bags = {}
Builtin.Bags = Bags

local dirty = {}
local allDirty = true

-- Last Refresh() classification, for the listener fan-out.
local lastChangeKind = "none"
local lastAdded, lastRemoved
local lastRefreshedDirty = {}
local beforeKeys = {}
local itemSets = C.NewItemSetLog()

local function Wipe(t)
	if wipe then
		return wipe(t)
	end
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

function Bags.MarkDirty(bag)
	if bag == nil then
		allDirty = true
		Wipe(dirty)
		return
	end
	bag = tonumber(bag)
	if not bag or not C.IsCarriedBag(bag) then
		if bag == nil then
			allDirty = true
		end
		return
	end
	dirty[bag] = true
end

function Bags.Invalidate()
	allDirty = true
	Wipe(dirty)
	C.Invalidate()
end

function Bags.Refresh()
	local snap = Inv.snapshots.bags
	local byBag = snap.byBag
	Wipe(lastRefreshedDirty)
	lastChangeKind, lastAdded, lastRemoved = "none", nil, nil
	if not allDirty and not next(dirty) then
		C.NoteItemSets(itemSets, {}, {})
		return false
	end
	if allDirty then
		Inv.SnapshotCountKeys(snap.counts, beforeKeys)
		Wipe(byBag)
		for _, bag in ipairs(C.GetCarriedBagIDs()) do
			byBag[bag] = C.ScanBag(bag)
			lastRefreshedDirty[bag] = true
		end
		allDirty = false
		Wipe(dirty)
		C.NoteItemSets(itemSets, nil)
		snap.counts = C.CountsFromByBag(byBag)
		lastChangeKind, lastAdded, lastRemoved = Inv.ClassifyCountKeys(beforeKeys, snap.counts)
	else
		local touched, delta = {}, {}
		for bag in pairs(dirty) do
			if C.IsCarriedBag(bag) then
				local scanned = C.ScanBag(bag)
				C.DiffSlots(byBag[bag], scanned, touched, delta)
				byBag[bag] = scanned
				lastRefreshedDirty[bag] = true
			end
		end
		Wipe(dirty)
		C.NoteItemSets(itemSets, touched, C.ChangedFromDelta(delta))
		-- Patch aggregate totals from dirty bags only. Moving a stack between
		-- bags can have zero net delta while still changing its slot records.
		local counts = snap.counts
		lastChangeKind = "countOnly"
		for id, change in pairs(delta) do
			local old = counts[id] or 0
			local new = old + change
			counts[id] = new > 0 and new or nil
			if old <= 0 and new > 0 then
				lastAdded = lastAdded or {}; lastAdded[id] = true
			elseif old > 0 and new <= 0 then
				lastRemoved = lastRemoved or {}; lastRemoved[id] = true
			end
		end
		if lastAdded or lastRemoved then lastChangeKind = "identityChanged" end
	end
	snap.generation = (snap.generation or 0) + 1
	local Store = Inv.Store
	if Store and Store.BindLive then
		Store.BindLive("bags", byBag)
		Store.MarkPending(nil, "bags")
	end
	return true
end

--- "none" | "countOnly" | "identityChanged"
function Bags.GetLastChangeKind()
	return lastChangeKind
end

function Bags.GetLastAddedItemIDs()
	return lastAdded
end

function Bags.GetLastRemovedItemIDs()
	return lastRemoved
end

--- Bags actually rescanned by the last Refresh() — lets overlays repaint only these.
function Bags.GetLastRefreshedDirtyBags()
	return lastRefreshedDirty
end

--- Touched / changed item IDs since the last take (nil, nil = unknown).
function Bags.TakeItemSets()
	return C.TakeItemSets(itemSets)
end
