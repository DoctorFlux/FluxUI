-- Inventory/Builtin/Bank.lua — scan while bank is open; keep last snapshot when closed
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Builtin = Inv.Builtin
local C = Inv.Containers

local Bank = {}
Builtin.Bank = Bank

local open = false
local dirtyChar = {}
local dirtyWar = {}
local allCharDirty = true
local allWarDirty = true

-- Last Refresh() classification (character + warband merged), for the fan-out.
local lastChangeKind = "none"
local lastAdded, lastRemoved
local lastRefreshedDirty = {}
local charKeys = {}
local warKeys = {}

local function Wipe(t)
	if wipe then
		return wipe(t)
	end
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

function Bank.IsOpen()
	return open
end

function Bank.SetOpen(isOpen)
	isOpen = isOpen and true or false
	if isOpen == open then
		return
	end
	open = isOpen
	if open then
		C.Invalidate()
		allCharDirty = true
		allWarDirty = true
		Wipe(dirtyChar)
		Wipe(dirtyWar)
	end
end

function Bank.MarkDirty(bag)
	if bag == nil then
		allCharDirty = true
		allWarDirty = true
		Wipe(dirtyChar)
		Wipe(dirtyWar)
		return
	end
	bag = tonumber(bag)
	if not bag then
		return
	end
	if C.IsWarbandBankContainer(bag) then
		dirtyWar[bag] = true
	elseif C.IsCharacterBankContainer(bag) then
		dirtyChar[bag] = true
	else
		allCharDirty = true
		allWarDirty = true
	end
end

function Bank.Invalidate()
	allCharDirty = true
	allWarDirty = true
	Wipe(dirtyChar)
	Wipe(dirtyWar)
	C.Invalidate()
end

local function AnyReadable(ids)
	if type(ids) ~= "table" then
		return false
	end
	for i = 1, #ids do
		local bag = ids[i]
		if bag and not (C.IsKeyringBag and C.IsKeyringBag(bag)) then
			if (Flux.Container.GetNumSlots(bag) or 0) > 0 then
				return true
			end
		end
	end
	return false
end

--- @return boolean stillAllDirty, string kind, table|nil added, table|nil removed
local function RefreshRegion(ids, snap, allDirtyFlag, dirtyMap, keyBuf)
	if not allDirtyFlag and not next(dirtyMap) then
		return allDirtyFlag, "none", nil, nil
	end
	-- Do not wipe Syndicator / last-visit snapshots with an empty scan when
	-- bank bags are not readable yet (open tick) or IDs were wrong.
	if allDirtyFlag and not AnyReadable(ids) then
		return true, "none", nil, nil
	end
	Inv.SnapshotCountKeys(snap.counts, keyBuf)
	local byBag = snap.byBag
	if allDirtyFlag then
		Wipe(byBag)
		for i = 1, #ids do
			local bag = ids[i]
			byBag[bag] = C.ScanBag(bag)
			lastRefreshedDirty[bag] = true
		end
		Wipe(dirtyMap)
	else
		for bag in pairs(dirtyMap) do
			byBag[bag] = C.ScanBag(bag)
			lastRefreshedDirty[bag] = true
		end
		Wipe(dirtyMap)
	end
	snap.counts = C.CountsFromByBag(byBag)
	snap.generation = (snap.generation or 0) + 1
	local kind, added, removed = Inv.ClassifyCountKeys(keyBuf, snap.counts)
	return false, kind, added, removed
end

function Bank.Refresh()
	if not open and not (C.IsBankReadable and C.IsBankReadable()) then
		return
	end
	open = true
	Wipe(lastRefreshedDirty)
	local charKind, charAdd, charRem
	allCharDirty, charKind, charAdd, charRem =
		RefreshRegion(C.GetCharacterBankIDs(), Inv.snapshots.bank, allCharDirty, dirtyChar, charKeys)
	local warKind, warAdd, warRem = "none", nil, nil
	if Inv.HasWarband() then
		allWarDirty, warKind, warAdd, warRem =
			RefreshRegion(C.GetWarbandBankIDs(), Inv.snapshots.warband, allWarDirty, dirtyWar, warKeys)
	end
	lastChangeKind, lastAdded, lastRemoved =
		Inv.MergeChangeKind(charKind, charAdd, charRem, warKind, warAdd, warRem)
	local Store = Inv.Store
	if Store and Store.BindLive then
		Store.BindLive("bank", Inv.snapshots.bank.byBag)
		Store.MarkPending(nil, "all")
		if Inv.HasWarband() then
			Store.BindWarbandBank(Inv.snapshots.warband.byBag)
			Store.MarkWarbandPending()
		end
	end
	if Inv.PersistBankCounts then
		Inv.PersistBankCounts()
	end
end

--- "none" | "countOnly" | "identityChanged"
function Bank.GetLastChangeKind()
	return lastChangeKind
end

function Bank.GetLastAddedItemIDs()
	return lastAdded
end

function Bank.GetLastRemovedItemIDs()
	return lastRemoved
end

function Bank.GetLastRefreshedDirtyBags()
	return lastRefreshedDirty
end

--- Overlay live container contents into the bank snapshot (main grid + bank bags).
function Bank.ScanOpenContainers()
	if not (open or (C.IsBankReadable and C.IsBankReadable())) then
		return false
	end
	open = true
	C.Invalidate()
	allCharDirty = true
	allWarDirty = true
	Bank.Refresh()
	return true
end
