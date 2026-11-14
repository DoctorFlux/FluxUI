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
-- A failed slot scan may leave newer bag rows beside the previous aggregate.
-- Remember only complete views, so the next successful pass rebuilds totals.
local aggregateState = {}
local publicationPending = false
local publicationRevision = 0

local function OwePublication()
	publicationPending = true
	publicationRevision = publicationRevision + 1
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
		return allDirtyFlag, "none", nil, nil, false
	end
	-- Do not wipe Syndicator / last-visit snapshots with an empty scan when
	-- bank bags are not readable yet (open tick) or IDs were wrong.
	if allDirtyFlag and not AnyReadable(ids) then
		return true, "none", nil, nil, false
	end
	local byBag = snap.byBag
	local state = aggregateState[snap]
	local wasCoherent = state and type(snap.counts) == "table"
		and state.byBag == byBag and state.counts == snap.counts
	local kind, added, removed
	if allDirtyFlag then
		Inv.SnapshotCountKeys(snap.counts, keyBuf)
		if state then state.counts = nil end
		Wipe(byBag)
		for i = 1, #ids do
			local bag = ids[i]
			byBag[bag] = C.ScanBag(bag)
			lastRefreshedDirty[bag] = true
		end
		Wipe(dirtyMap)
		snap.counts = C.CountsFromByBag(byBag)
		kind, added, removed = Inv.ClassifyCountKeys(keyBuf, snap.counts)
	else
		-- Keep the old aggregate immutable for retained readers and nested scans.
		-- Stage all deltas before publishing, as a slot read can fail or reenter.
		local previous, generation = snap.counts, snap.generation
		local delta = {}
		for bag in pairs(dirtyMap) do
			local old = byBag[bag]
			local scanned = C.ScanBag(bag)
			for _, rec in pairs(old or {}) do
				local id = tonumber(rec.itemID)
				if id then delta[id] = (delta[id] or 0) - (rec.count or 1) end
			end
			for _, rec in pairs(scanned) do
				local id = tonumber(rec.itemID)
				if id then delta[id] = (delta[id] or 0) + (rec.count or 1) end
			end
			if state then state.counts = nil end
			byBag[bag] = scanned
			lastRefreshedDirty[bag] = true
		end
		Wipe(dirtyMap)
		local counts = {}
		if snap.generation ~= generation or not wasCoherent then
			-- Nested/failed reads or replaced maps require the completed live view,
			-- rather than a delta based on an obsolete or partial aggregate.
			counts = C.CountsFromByBag(byBag)
			kind, added, removed = Inv.ClassifyCountKeys(previous or {}, counts)
		else
			for id, count in pairs(previous) do counts[id] = count end
			kind = "countOnly"
			for id, change in pairs(delta) do
				local before = previous[id]
				local after = (before or 0) + change
				counts[id] = after > 0 and after or nil
				if before == nil and after > 0 then
					added = added or {}; added[id] = true
				elseif before ~= nil and after <= 0 then
					removed = removed or {}; removed[id] = true
				end
			end
			if added or removed then kind = "identityChanged" end
		end
		snap.counts = counts
	end
	snap.generation = (snap.generation or 0) + 1
	state = state or {}
	state.byBag, state.counts = byBag, snap.counts
	aggregateState[snap] = state
	return false, kind, added, removed, true
end

local function PublishBankFacts()
	local published = false
	local Store = Inv.Store
	if Store and Store.BindLive then
		Store.BindLive("bank", Inv.snapshots.bank.byBag)
		Store.MarkPending(nil, "all")
		if Inv.HasWarband() then
			Store.BindWarbandBank(Inv.snapshots.warband.byBag)
			Store.MarkWarbandPending()
		end
		published = true
	end
	if Inv.PersistBankCounts then
		Inv.PersistBankCounts()
	else
		published = false
	end
	return published
end

function Bank.Refresh()
	if not open and not (C.IsBankReadable and C.IsBankReadable()) then
		return
	end
	open = true
	Wipe(lastRefreshedDirty)
	local charKind, charAdd, charRem, charRefreshed
	allCharDirty, charKind, charAdd, charRem, charRefreshed =
		RefreshRegion(C.GetCharacterBankIDs(), Inv.snapshots.bank, allCharDirty, dirtyChar, charKeys)
	if charRefreshed then OwePublication() end
	local warKind, warAdd, warRem, warRefreshed = "none", nil, nil, false
	if Inv.HasWarband() then
		allWarDirty, warKind, warAdd, warRem, warRefreshed =
			RefreshRegion(C.GetWarbandBankIDs(), Inv.snapshots.warband, allWarDirty, dirtyWar, warKeys)
		if warRefreshed then OwePublication() end
	end
	lastChangeKind, lastAdded, lastRemoved =
		Inv.MergeChangeKind(charKind, charAdd, charRem, warKind, warAdd, warRem)
	if not publicationPending then return end
	-- Publication may fail after the slot maps committed, or reenter Refresh.
	-- Keep its retry owed without suppressing the original error or nested call.
	local revision = publicationRevision
	local ok, published = pcall(PublishBankFacts)
	if not ok then
		OwePublication()
		error(published, 0)
	end
	if not published then
		OwePublication()
	elseif publicationRevision == revision then
		-- A completed outer attempt must not erase a newer nested failure.
		publicationPending = false
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
