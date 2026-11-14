-- Inventory/Init.lua — facade + module registration. Old FluxInv files stay unused.
local addonName, ns = ...
local Flux = ns.Flux

local Inv = Flux.Inventory or {}
Flux.Inventory = Inv
Inv.Builtin = Inv.Builtin or {}
Inv.Syndicator = Inv.Syndicator or {}

Inv.source = nil
Inv.ready = false
Inv.started = false
Inv.itemDataRevision = "20261105.1"

Inv.snapshots = {
	bags = { byBag = {}, counts = {}, generation = 0 },
	bank = { byBag = {}, counts = {}, generation = 0 },
	warband = { byBag = {}, counts = {}, generation = 0 },
	equip = { bySlot = {}, counts = {}, generation = 0 },
	mail = { byIndex = {}, counts = {}, generation = 0 },
	void = { byBag = {}, counts = {}, generation = 0 },
	auctions = { byIndex = {}, counts = {}, generation = 0 },
	guild = { byBag = {}, counts = {}, generation = 0 },
	currencies = { counts = {}, money = 0, warbandMoney = 0, generation = 0 },
}

local listeners = {}
local schedulerHooked = false

local function CopyCountMap(src, dst)
	if type(dst) ~= "table" then
		return
	end
	if type(src) ~= "table" then
		return
	end
	for k, v in pairs(src) do
		local id = tonumber(k)
		local n = tonumber(v)
		if id and n and n > 0 then
			dst[id] = n
		end
	end
end

local function SnapshotCountMap(src)
	local out = {}
	CopyCountMap(src, out)
	return out
end

local function GetBankSV()
	_G._FluxUI_CharSavedVars = _G._FluxUI_CharSavedVars or {}
	local root = _G._FluxUI_CharSavedVars
	if type(root.Bank) ~= "table" then
		root.Bank = {}
	end
	return root.Bank
end

--- Fill empty bank/warband snapshots from last visit (backup FluxInv_Bank shape).
function Inv.LoadPersistedBankCounts()
	local sv = _G._FluxUI_CharSavedVars and _G._FluxUI_CharSavedVars.Bank
	if type(sv) ~= "table" then
		return
	end
	local bank = Inv.snapshots and Inv.snapshots.bank
	if bank and (not bank.counts or not next(bank.counts)) then
		bank.counts = bank.counts or {}
		CopyCountMap(sv.charCounts, bank.counts)
		if next(bank.counts) then
			bank.generation = (bank.generation or 0) + 1
		end
	end
	local war = Inv.snapshots and Inv.snapshots.warband
	if war and (not war.counts or not next(war.counts)) then
		war.counts = war.counts or {}
		CopyCountMap(sv.warCounts, war.counts)
		if next(war.counts) then
			war.generation = (war.generation or 0) + 1
		end
	end
end

function Inv.PersistBankCounts()
	local sv = GetBankSV()
	local bank = Inv.snapshots and Inv.snapshots.bank
	if bank and type(bank.counts) == "table" and next(bank.counts) then
		sv.charCounts = SnapshotCountMap(bank.counts)
	end
	local war = Inv.snapshots and Inv.snapshots.warband
	if war and type(war.counts) == "table" and next(war.counts) then
		sv.warCounts = SnapshotCountMap(war.counts)
	end
	local RIBank = _G.FluxRestock and _G.FluxRestock.Inv and _G.FluxRestock.Inv.Bank
	if RIBank and RIBank.Persist then
		RIBank.Persist()
	end
end

-- Change classification -------------------------------------------------------
-- Listeners must be able to tell "a stack grew" from "a new item appeared".
-- Loot / use / craft is overwhelmingly the former, and the cheap path in most
-- consumers is gated on it. Comparing the key set of the aggregate counts table
-- is O(unique items) and needs no per-slot bookkeeping.

local function WipeTable(t)
	if wipe then
		return wipe(t)
	end
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

Inv.WipeTable = WipeTable

--- Capture the item-ID key set of a counts table, reusing `into`.
function Inv.SnapshotCountKeys(counts, into)
	into = WipeTable(into or {})
	if type(counts) == "table" then
		for id in pairs(counts) do
			into[id] = true
		end
	end
	return into
end

--- "countOnly" when the same item IDs are present (only totals moved), or
--- "identityChanged" plus added/removed sets when IDs appeared or disappeared.
--- @return string kind, table|nil added, table|nil removed
function Inv.ClassifyCountKeys(beforeKeys, counts)
	local added, removed
	if type(counts) == "table" then
		for id in pairs(counts) do
			if not beforeKeys[id] then
				added = added or {}
				added[id] = true
			end
		end
	end
	if type(beforeKeys) == "table" then
		for id in pairs(beforeKeys) do
			if not (counts and counts[id]) then
				removed = removed or {}
				removed[id] = true
			end
		end
	end
	if added or removed then
		return "identityChanged", added, removed
	end
	return "countOnly", nil, nil
end

local function CopyKeySet(src)
	if type(src) ~= "table" then
		return nil
	end
	local out = {}
	for id in pairs(src) do
		out[id] = true
	end
	return out
end

--- Merge two classifications. identityChanged wins; added/removed sets union.
--- Copies first: callers keep their own last-change tables.
function Inv.MergeChangeKind(kindA, addA, remA, kindB, addB, remB)
	local function union(a, b)
		if not b then
			return a
		end
		a = a or {}
		for id in pairs(b) do
			a[id] = true
		end
		return a
	end
	local added = union(CopyKeySet(addA), addB)
	local removed = union(CopyKeySet(remA), remB)
	if kindA == "identityChanged" or kindB == "identityChanged" then
		return "identityChanged", added, removed
	end
	if kindA == "countOnly" or kindB == "countOnly" then
		return "countOnly", nil, nil
	end
	return kindA ~= "none" and kindA or (kindB or "none"), added, removed
end

-- Async item data ------------------------------------------------------------
-- A slot whose item data is not cached yet answers GetContainerItemInfo with a
-- partial record, so the item looks absent and then "appears" on the next
-- refresh — a spurious identityChanged, the exact pulse consumers pay most for.
-- Request the real data and rescan that bag when it lands.

local pendingItemData = {}
local itemDataBagObservers = {}
local pendingItemDataCount = 0
local itemDataFrame
local itemDataListening = false
local itemDataElapsed = 0
local itemDataDeadline
local ITEM_DATA_RETRY = 0.4
local ITEM_DATA_MAX_REQUESTS, ITEM_DATA_MAX_WAIT = 4, 8
local ClearItemData

--- True during the bounded active wait for item data requested by a scan. Mirrors
--- Syndicator.API.IsBagEventPending() so movers can avoid acting mid-scan.
function Inv.IsScanPending()
	if Inv.source == "syndicator" then ClearItemData(); return false end
	return pendingItemDataCount > 0
end

local function StopIdleItemData()
	if pendingItemDataCount == 0 and itemDataFrame then
		itemDataElapsed = 0
		itemDataDeadline = nil
		itemDataFrame:SetScript("OnUpdate", nil)
	end
	if not next(pendingItemData) and not next(itemDataBagObservers) and itemDataFrame and itemDataListening then
		itemDataFrame:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
		itemDataListening = false
	end
end

ClearItemData = function()
	if not next(pendingItemData) and not next(itemDataBagObservers) then return end
	WipeTable(pendingItemData)
	WipeTable(itemDataBagObservers)
	pendingItemDataCount = 0
	StopIdleItemData()
end

local function ResolveItemData(itemID)
	local entry = pendingItemData[itemID]
	local callbacks = entry and entry.callbacks
	if entry then
		pendingItemData[itemID] = nil
		if entry.active then pendingItemDataCount = pendingItemDataCount - 1 end
	end
	for bag, observer in pairs(itemDataBagObservers) do
		if not observer.notified then
			local C, bank = Inv.Containers, Inv.Builtin and Inv.Builtin.Bank
			local readable = C and C.IsCarriedBag(bag)
				or (bank and bank.IsOpen and bank.IsOpen() and C and C.IsBankContainer(bag))
			if readable then
				observer.notified = true
				callbacks = callbacks or {}
				local duplicate = false
				for i = 1, #callbacks do if callbacks[i] == observer.callback then duplicate = true; break end end
				if not duplicate then callbacks[#callbacks + 1] = observer.callback end
			end
		end
	end
	StopIdleItemData()
	if callbacks then
		for i = 1, #callbacks do
			if Inv.source == "syndicator" then ClearItemData(); return end
			Flux.Safecall(callbacks[i])
		end
	end
end

local function OnItemDataUpdate(self, elapsed)
	if Inv.source == "syndicator" then ClearItemData(); return end
	itemDataElapsed = itemDataElapsed + (elapsed or 0)
	local retry = itemDataElapsed >= ITEM_DATA_RETRY
	local now = GetTime()
	if not retry and (not itemDataDeadline or now < itemDataDeadline) then return end
	if retry then itemDataElapsed = 0 end
	itemDataDeadline = nil
	local load = C_Item and C_Item.RequestLoadItemDataByID
	local requests
	for itemID, entry in pairs(pendingItemData) do
		if entry.active then
			if not load or now - entry.started >= ITEM_DATA_MAX_WAIT then
				entry.active = false
				pendingItemDataCount = pendingItemDataCount - 1
			else
				local deadline = entry.started + ITEM_DATA_MAX_WAIT
				itemDataDeadline = math.min(itemDataDeadline or deadline, deadline)
				if retry and entry.requests < ITEM_DATA_MAX_REQUESTS then
					requests = requests or {}
					requests[#requests + 1], requests[#requests + 2] = itemID, entry
				end
			end
		end
	end
	-- Native completion can run synchronously and mutate the pending map.
	if requests then
		for i = 1, #requests, 2 do
			if Inv.source == "syndicator" then ClearItemData(); return end
			local itemID, entry = requests[i], requests[i + 1]
			if pendingItemData[itemID] == entry and entry.active then
				entry.requests = entry.requests + 1
				load(itemID)
			end
		end
	end
	StopIdleItemData()
end

local function EnsureItemDataFrame()
	if not itemDataFrame then
		itemDataFrame = CreateFrame("Frame")
		itemDataFrame:SetScript("OnEvent", function(_, _, itemID, success)
			if Inv.source == "syndicator" then ClearItemData(); return end
			itemID = tonumber(itemID)
			if itemID and success ~= false then ResolveItemData(itemID) end
		end)
	end
	if not itemDataListening then
		itemDataFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
		itemDataListening = true
	end
	return itemDataFrame
end

--- Coalesce each item's initial request; retain each distinct callback once.
--- Bag-owned callbacks survive the bounded retry deadline for a late success.
function Inv.RequestItemData(itemID, callback, bag)
	if Inv.source == "syndicator" then ClearItemData(); return false end
	itemID = tonumber(itemID)
	local load = C_Item and C_Item.RequestLoadItemDataByID
	if not itemID or type(callback) ~= "function" or type(load) ~= "function" then
		return false
	end
	local entry = pendingItemData[itemID]
	if not entry then
		entry = { callbacks = {}, owners = {} }
		pendingItemData[itemID] = entry
	end
	local registered = entry.owners[callback] ~= nil
	if not registered then
		entry.callbacks[#entry.callbacks + 1] = callback
		entry.owners[callback] = tonumber(bag) or false
	end
	-- Normal scans cannot restart an expired request for the same bag owner.
	-- New owners and explicit callers without a bag can request another attempt.
	if entry.active or (registered and bag ~= nil) then return true end
	entry.active, entry.started, entry.requests = true, GetTime(), 1
	local deadline = entry.started + ITEM_DATA_MAX_WAIT
	itemDataDeadline = math.min(itemDataDeadline or deadline, deadline)
	pendingItemDataCount = pendingItemDataCount + 1
	local frame = EnsureItemDataFrame()
	frame:SetScript("OnUpdate", OnItemDataUpdate)
	load(itemID)
	return true
end

--- Retire bag callbacks absent from the container's last-known cold slot map.
--- Callers without a bag owner retain their explicit callback until completion.
function Inv.PruneItemDataForBag(bag, slots, ambiguous, scanned, callback)
	if Inv.source == "syndicator" then ClearItemData(); return end
	bag = tonumber(bag)
	if bag == nil then return end
	if not ambiguous then itemDataBagObservers[bag] = nil
	elseif not itemDataBagObservers[bag] and type(callback) == "function" then
		itemDataBagObservers[bag] = { callback = callback }
		EnsureItemDataFrame()
	elseif scanned and itemDataBagObservers[bag] then itemDataBagObservers[bag].notified = false end
	if not next(pendingItemData) then
		if itemDataListening and not next(itemDataBagObservers) then StopIdleItemData() end
		return
	end
	local present = {}
	if slots then for _, rec in pairs(slots) do present[rec.itemID] = true end end
	for itemID, entry in pairs(pendingItemData) do
		if not present[itemID] then
			for i = #entry.callbacks, 1, -1 do
				local callback = entry.callbacks[i]
				if entry.owners[callback] == bag then
					-- A cold item can move into an unidentified slot. Keep one
					-- bag observer instead of retaining every historical item ID.
					if ambiguous and not itemDataBagObservers[bag] then
						itemDataBagObservers[bag] = { callback = callback }
					end
					entry.owners[callback] = nil
					table.remove(entry.callbacks, i)
				end
			end
			if #entry.callbacks == 0 then
				pendingItemData[itemID] = nil
				if entry.active then pendingItemDataCount = pendingItemDataCount - 1 end
			end
		end
	end
	StopIdleItemData()
end

--- Item data for a scanned slot landed: rescan that container.
function Inv.NoteItemDataArrived(bag)
	local C = Inv.Containers
	local Builtin = Inv.Builtin
	if not C or not Builtin or Inv.source ~= "builtin" then
		return
	end
	if C.IsCarriedBag(bag) then
		if Builtin.Bags and Builtin.Bags.MarkDirty then
			Builtin.Bags.MarkDirty(bag)
		end
		Flux.Scheduler.Request("inventory", "bags")
	elseif C.IsBankContainer(bag) then
		if Builtin.Bank and Builtin.Bank.MarkDirty then
			Builtin.Bank.MarkDirty(bag)
		end
		Flux.Scheduler.Request("inventory", C.IsWarbandBankContainer(bag) and "warband" or "bank")
	end
end

-- Known region tokens only. Unknown keys (e.g. leftover "ebs") must not
-- fan out as bags+bank+warband+equip — that re-armed inventory every frame.
local function TokensToRegions(tokens)
	if not tokens then
		return { bags = true, bank = true, warband = true, equipped = true }
	end
	local regions = {}
	if tokens.bags then
		regions.bags = true
	end
	if tokens.bank then
		regions.bank = true
	end
	if tokens.warband then
		regions.warband = true
	end
	if tokens.equip or tokens.equipped then
		-- Set both spellings: consumers register regions as either "equip" or
		-- "equipped" and check ctx.regions with whichever they used.
		regions.equipped = true
		regions.equip = true
	end
	if tokens.mail then
		regions.mail = true
	end
	if tokens.void then
		regions.void = true
	end
	if tokens.auctions then
		regions.auctions = true
	end
	if tokens.guild then
		regions.guild = true
	end
	if tokens.currencies or tokens.currency then
		regions.currencies = true
	end
	if tokens.professions then
		regions.professions = true
	end
	return regions
end

-- Bag storms -----------------------------------------------------------------
-- Looting, crafting and vendor sweeps fire BAG_UPDATE repeatedly. While a storm
-- is up, heavy listeners go on the budgeted queue and drain once it settles.

local STORM_HOLD = 0.25
local MAILBOX_CLOSE_HOLD = 0.25
local bagStormUntil = 0
local stormSettleTimer = false
local stormSettleOneShots = {}
local stormSettlePermanent = {}
local merchantOpen = false
local mailboxOpen = false
local mailboxCloseGen = 0

local function Now()
	return (GetTime and GetTime()) or 0
end

function Inv.IsBagStorm()
	return Now() < bagStormUntil
end

local function FireStormSettled()
	stormSettleTimer = false
	if Inv.IsBagStorm() then
		stormSettleTimer = true
		if C_Timer and C_Timer.After then
			C_Timer.After(0.2, FireStormSettled)
		end
		return
	end
	-- A settled callback can retire its login subscription and publish a new
	-- listener. Dispatch the original registrations without iterating a table
	-- that those callbacks can mutate; replacements/additions wait for next time.
	local permanent = {}
	for key, fn in pairs(stormSettlePermanent) do permanent[key] = fn end
	local ones = stormSettleOneShots
	stormSettleOneShots = {}
	for i = 1, #ones do
		Flux.Safecall(ones[i])
	end
	for key, fn in pairs(permanent) do
		if stormSettlePermanent[key] == fn then Flux.Safecall(fn) end
	end
end

function Inv.NotifyBagStorm(seconds)
	local hold = tonumber(seconds) or STORM_HOLD
	local untilTime = Now() + hold
	if untilTime > bagStormUntil then
		bagStormUntil = untilTime
	end
	if not stormSettleTimer and C_Timer and C_Timer.After then
		stormSettleTimer = true
		C_Timer.After(hold + 0.05, FireStormSettled)
	end
end

--- The snapshot landed. Keep the existing settle timer as the sole owner of
--- callbacks: running them here too doubled work on every mail attachment.
function Inv.EndBagStorm()
	if bagStormUntil <= Now() and not stormSettleTimer then
		return
	end
	bagStormUntil = 0
end

--- One-shot callback once the current storm settles.
function Inv.OnStormSettled(fn)
	if type(fn) ~= "function" then
		return
	end
	if not Inv.IsBagStorm() then
		fn()
		return
	end
	stormSettleOneShots[#stormSettleOneShots + 1] = fn
	if not stormSettleTimer and C_Timer and C_Timer.After then
		stormSettleTimer = true
		C_Timer.After(0.3, FireStormSettled)
	end
end

function Inv.RegisterStormSettled(key, fn)
	if type(key) ~= "string" or type(fn) ~= "function" then
		return
	end
	stormSettlePermanent[key] = fn
end

function Inv.UnregisterStormSettled(key)
	stormSettlePermanent[key] = nil
end

function Inv.SetMerchantOpen(open)
	merchantOpen = open and true or false
end

function Inv.IsMerchantOpen()
	return merchantOpen
end

--- Mailbox open, plus a short hold after close so trailing BAG_UPDATE is still deferred.
function Inv.SetMailboxOpen(open)
	if open then
		mailboxCloseGen = mailboxCloseGen + 1
		mailboxOpen = true
		return
	end
	mailboxCloseGen = mailboxCloseGen + 1
	local gen = mailboxCloseGen
	if C_Timer and C_Timer.After then
		C_Timer.After(MAILBOX_CLOSE_HOLD, function()
			if gen ~= mailboxCloseGen then
				return
			end
			mailboxOpen = false
		end)
	else
		mailboxOpen = false
	end
end

function Inv.IsMailboxOpen()
	if mailboxOpen then
		return true
	end
	local Mail = Inv.Builtin and Inv.Builtin.Mail
	return Mail and Mail.IsOpen and Mail.IsOpen() or false
end

local function IsMailInteraction(kind)
	local e = Enum and Enum.PlayerInteractionType
	return e and kind == e.MailInfo
end

--- True when rebuilding indexes / classifying should wait for a calmer frame.
function Inv.ShouldDeferHeavyWork()
	return Inv.IsBagStorm() or merchantOpen or Inv.IsMailboxOpen() or Inv.IsBankOpen()
end

-- Listener fan-out ------------------------------------------------------------
-- One bag pulse reaches ~35 listeners. Without tier / region / deferHeavy gating
-- they all run inline in one frame, and without changeKind on the ctx every one
-- of them takes its full-rebuild branch. Both are what made looting stutter.

local TIER_RANK = { instant = 1, light = 2, scan = 3, heavy = 4 }

local DEBOUNCE = 0.05
local DEBOUNCE_BANK_OPEN = 0.12
local DEBOUNCE_STORM = 0.18
local HEAVY_MAX_WAIT = 0.6

--- How long the heavy queue waits after the last enqueue before draining. The
--- snapshot refresh and sync listeners are never held behind this.
local function CurrentDebounce()
	if Inv.IsMailboxOpen() or merchantOpen then
		return DEBOUNCE_STORM
	end
	if Inv.IsBagStorm() then
		return DEBOUNCE_STORM
	end
	if Inv.IsBankOpen and Inv.IsBankOpen() then
		return DEBOUNCE_BANK_OPEN
	end
	return DEBOUNCE
end

-- Count text and bag overlays must land in the same frame as the refresh, so
-- these never go on the deferred queue even if they ask for it.
local SYNC_KEYS = {
	EngineBagRefresh = true,
	FluxJunkOverlay = true,
	FluxJunkSlotCount = true,
	NCTeleportPortal = true,
	FluxBagMicroButton = true,
	FluxItemCurrencyTracking = true,
	FluxGoldLedger = true,
}

local heavyQueue = {}
local heavyOrder = {}
local heavyArmed = false
local heavyFrame
local heavyWakeAt, heavyWakeEpoch
local ArmHeavyQueue
local HEAVY_MAX_PER_FRAME = 2
local HEAVY_BUDGET_MS = 1.5

local function CancelHeavy(key)
	if not heavyQueue[key] then return end
	heavyQueue[key] = nil
	for i = #heavyOrder, 1, -1 do
		if heavyOrder[i] == key then table.remove(heavyOrder, i) end
	end
	if ArmHeavyQueue then ArmHeavyQueue() end
end

local function NormalizeRegions(regions)
	if type(regions) ~= "table" then
		return nil
	end
	local out = {}
	for _, name in ipairs(regions) do
		out[name] = true
	end
	for name, v in pairs(regions) do
		if type(name) == "string" and v == true then
			out[name] = true
		end
	end
	if out.equip or out.equipped then
		out.equip = true
		out.equipped = true
	end
	return next(out) and out or nil
end

--- No declared regions means "any". Otherwise at least one must be pulsing.
local function RegionMatches(wanted, pending)
	if not wanted then
		return true
	end
	for name in pairs(wanted) do
		if pending[name] then
			return true
		end
	end
	return false
end

local function IsSyncListener(entry)
	if entry.sync or SYNC_KEYS[entry.key] then
		return true
	end
	if entry.deferHeavy then
		return false
	end
	-- Instant tier is cheap by contract.
	return entry.tier == "instant"
end

local function ProcessHeavyQueue(self)
	local processed = 0
	local started = debugprofilestop and debugprofilestop() or nil
	local index = 1
	while processed < HEAVY_MAX_PER_FRAME and index <= #heavyOrder do
		local key = heavyOrder[index]
		local job = heavyQueue[key]
		if job and Now() < job.at then
			index = index + 1
		else
			table.remove(heavyOrder, index)
			heavyQueue[key] = nil
			if job and listeners[key] and listeners[key].fn == job.fn then
				Flux.Safecall(job.fn, job.ctx)
				processed = processed + 1
				if started and (debugprofilestop() - started) >= HEAVY_BUDGET_MS then
					break
				end
			end
		end
	end
	if #heavyOrder == 0 then
		heavyArmed = false
		self:SetScript("OnUpdate", nil)
	end
	ArmHeavyQueue()
end

ArmHeavyQueue = function()
	if not heavyFrame then return end
	local earliest
	for i = 1, #heavyOrder do
		local job = heavyQueue[heavyOrder[i]]
		local at = job and job.at or 0
		if not earliest or at < earliest then earliest = at end
	end
	if not earliest then
		heavyArmed = false
		heavyWakeAt, heavyWakeEpoch = nil, nil
		heavyFrame:SetScript("OnUpdate", nil)
		return
	end
	local after = Flux.Timer and Flux.Timer.HasNativeAfter ~= false and Flux.Timer.After
	if earliest <= Now() or not after then
		heavyWakeAt, heavyWakeEpoch = nil, nil
		heavyFrame:SetScript("OnUpdate", ProcessHeavyQueue)
		return
	end
	-- A quiet deadline needs no per-frame scan. Earlier wakes may harmlessly
	-- recheck a postponed deadline; a newly earlier job replaces ownership.
	if heavyWakeAt and heavyWakeAt <= earliest then return end
	local epoch = {}
	heavyWakeAt, heavyWakeEpoch = earliest, epoch
	heavyFrame:SetScript("OnUpdate", nil)
	after(math.max(0, earliest - Now()), function()
		if heavyWakeEpoch ~= epoch then return end
		heavyWakeAt, heavyWakeEpoch = nil, nil
		ArmHeavyQueue()
	end)
end

local function UnionSets(a, b)
	local out = CopyKeySet(a) or {}
	for key in pairs(b or {}) do out[key] = true end
	return out
end

local function CopyContext(ctx)
	local out = {}
	for key, value in pairs(ctx) do
		out[key] = type(value) == "table" and CopyKeySet(value) or value
	end
	return out
end

local function MergeContext(a, b)
	local out = CopyContext(b)
	out.regions = UnionSets(a.regions, b.regions)
	out.changeKind, out.addedItemIDs, out.removedItemIDs = Inv.MergeChangeKind(
		a.changeKind, a.addedItemIDs, a.removedItemIDs, b.changeKind, b.addedItemIDs, b.removedItemIDs)
	-- Missing metadata for a relevant region means unknown, not an empty set.
	for _, field in ipairs({ "dirtyBags", "touchedItemIDs", "changedItemIDs" }) do
		local aRelevant = a.regions.bags or (field == "dirtyBags" and (a.regions.bank or a.regions.warband))
		local bRelevant = b.regions.bags or (field == "dirtyBags" and (b.regions.bank or b.regions.warband))
		if (aRelevant and a[field] == nil) or (bRelevant and b[field] == nil) then
			out[field] = nil
		else
			out[field] = UnionSets(a[field], b[field])
		end
	end
	out.force = a.force or b.force
	out.recovery = a.recovery or b.recovery
	return out
end

-- Each listener has a quiet deadline and a maximum wait. New mail must not
-- starve an unrelated queued listener, and a count-only pulse must not erase
-- an earlier identity change or its dirty bags.
local function EnqueueHeavy(entry, ctx)
	local key = entry.key
	local job = heavyQueue[key]
	local now = Now()
	if not job then
		heavyOrder[#heavyOrder + 1] = key
		job = { fn = entry.fn, ctx = CopyContext(ctx), first = now }
		heavyQueue[key] = job
	else
		job.ctx = MergeContext(job.ctx, ctx)
	end
	job.at = math.min(now + CurrentDebounce(), job.first + HEAVY_MAX_WAIT)
	heavyArmed = true
	heavyFrame = heavyFrame or CreateFrame("Frame")
	ArmHeavyQueue()
end

--- @return string kind, table|nil added, table|nil removed, table|nil dirtyBags
local function BagsChangeMeta()
	if Inv.source == "syndicator" then
		local A = Inv.Syndicator
		if A and A.GetLastBagsChangeKind then
			return A.GetLastBagsChangeKind(), A.GetLastBagsAddedItemIDs(),
				A.GetLastBagsRemovedItemIDs(), A.GetLastBagsDirtyBags()
		end
		return "none", nil, nil, nil
	end
	local B = Inv.Builtin and Inv.Builtin.Bags
	if B and B.GetLastChangeKind then
		return B.GetLastChangeKind(), B.GetLastAddedItemIDs(),
			B.GetLastRemovedItemIDs(), B.GetLastRefreshedDirtyBags()
	end
	return "none", nil, nil, nil
end

--- Public last-added bag IDs from the most recent snapshot write (builtin or Syndicator).
function Inv.GetLastAddedItemIDs()
	local _, added = BagsChangeMeta()
	return added
end

local function BankChangeMeta()
	if Inv.source == "syndicator" then
		local A = Inv.Syndicator
		if A and A.GetLastBankChangeKind then
			return A.GetLastBankChangeKind(), A.GetLastBankAddedItemIDs(),
				A.GetLastBankRemovedItemIDs(), A.GetLastBankDirtyBags()
		end
		return "none", nil, nil, nil
	end
	local B = Inv.Builtin and Inv.Builtin.Bank
	if B and B.GetLastChangeKind then
		return B.GetLastChangeKind(), B.GetLastAddedItemIDs(),
			B.GetLastRemovedItemIDs(), B.GetLastRefreshedDirtyBags()
	end
	return "none", nil, nil, nil
end

local function MergeDirty(into, src)
	if not src or not next(src) then
		return into
	end
	into = into or {}
	for bag in pairs(src) do
		into[bag] = true
	end
	return into
end

local function TakeBagItemSets()
	local source = Inv.source == "syndicator" and Inv.Syndicator or (Inv.Builtin and Inv.Builtin.Bags)
	if Inv.source == "syndicator" and source and source.TakeBagsItemSets then
		return source.TakeBagsItemSets()
	end
	if source and source.TakeItemSets then
		return source.TakeItemSets()
	end
end

function Inv.Notify(tokens)
	local regions = TokensToRegions(tokens)
	if not next(regions) then
		return
	end

	local changeKind, added, removed = "none", nil, nil
	local dirtyBags
	local touchedItemIDs, changedItemIDs
	if regions.bags then
		local kind, add, rem, dirty = BagsChangeMeta()
		changeKind, added, removed = Inv.MergeChangeKind(changeKind, added, removed, kind, add, rem)
		dirtyBags = MergeDirty(dirtyBags, dirty)
		touchedItemIDs, changedItemIDs = TakeBagItemSets()
	end
	if regions.bank or regions.warband then
		local kind, add, rem, dirty = BankChangeMeta()
		changeKind, added, removed = Inv.MergeChangeKind(changeKind, added, removed, kind, add, rem)
		dirtyBags = MergeDirty(dirtyBags, dirty)
	end

	local force = (tokens and tokens.force) and true or nil
	local tier = (tokens and tokens.tier) or "scan"
	local ctx = {
		regions = regions,
		source = Inv.source,
		tier = tier,
		time = GetTime and GetTime() or 0,
		changeKind = changeKind,
		addedItemIDs = added,
		removedItemIDs = removed,
		dirtyBags = dirtyBags,
		touchedItemIDs = touchedItemIDs,
		changedItemIDs = changedItemIDs,
		force = force,
		recovery = tokens and tokens.recovery or nil,
	}

	-- Counts stay inline. Scan work uses the budgeted queue, including the
	-- eventual scan owed by Classic/Syndicator light notifications.
	local tierRank = TIER_RANK[tier] or TIER_RANK.scan

	for _, entry in pairs(listeners) do
		local wantRank = TIER_RANK[entry.tier] or TIER_RANK.scan
		if RegionMatches(entry.regions, regions) then
			local deferred = entry.deferHeavy or wantRank >= TIER_RANK.scan
			if force ~= true and deferred and not IsSyncListener(entry) then
				-- Classic/Syndicator light notifications also owe scan listeners
				-- a later pass. Keep count/overlay listeners inline below.
				local queued = ctx
				if tierRank < wantRank then
					queued = CopyContext(ctx)
					queued.tier = entry.tier
				end
				EnqueueHeavy(entry, queued)
			elseif tierRank >= wantRank then
				-- Deliver earlier pending regions too: a forced mail refresh
				-- must not drop a bag change waiting on the same listener.
				local job = heavyQueue[entry.key]
				local delivered = job and MergeContext(job.ctx, ctx) or ctx
				CancelHeavy(entry.key)
				Flux.Safecall(entry.fn, delivered)
			end
		end
	end
end

--- opts.tier      "instant" | "light" | "scan" | "heavy" (default "scan")
--- opts.regions   list or set of region names; omitted means every pulse
--- opts.deferHeavy run on the frame-budgeted queue (also the default for scan/heavy)
--- opts.sync      always run inline (count text, overlays)
function Inv.Register(key, fn, opts)
	if type(key) ~= "string" or type(fn) ~= "function" then
		return
	end
	opts = opts or {}
	CancelHeavy(key)
	listeners[key] = {
		key = key,
		fn = fn,
		tier = opts.tier or "scan",
		regions = NormalizeRegions(opts.regions),
		deferHeavy = opts.deferHeavy and true or false,
		sync = opts.sync and true or false,
	}
end

Inv.RegisterListener = Inv.Register

function Inv.Unregister(key)
	listeners[key] = nil
	CancelHeavy(key)
end

--- Read-only view for /fluxinv.
function Inv.GetListenerInfo()
	local out = {}
	for key, entry in pairs(listeners) do
		out[#out + 1] = {
			key = key,
			tier = entry.tier,
			regions = entry.regions,
			deferHeavy = entry.deferHeavy,
			sync = entry.sync,
		}
	end
	table.sort(out, function(a, b)
		return a.key < b.key
	end)
	return out
end

function Inv.GetSource()
	return Inv.source or "none"
end

function Inv.IsReady()
	return Inv.ready and true or false
end

-- Portal/zone: snapshot may be ready but empty/wrong for a beat.
-- Grid buttons freeze identity until IsReliable() rises.
local snapshotUnreliable = false
local unreliableGeneration = 0
local unreliableMarkedAt = 0
local uniqueAtUnreliable = 0
local settleGen = nil
local settleAt = 0
local RELIABLE_SETTLE_SEC = 0.25
local UNRELIABLE_MAX_SEC = 3.0
local COLLAPSED_MAX_SEC = 8.0
local LOGIN_HOLD_MAX_SEC = 5.0
local LOGIN_HOLD_AFTER_DELAYED = 0.15

local loginHold = false
local loginHoldUntil = 0
local loginHoldGen = 0
local loginSawDelayed = false

local function BagUniqueCount()
	if Inv.Index and Inv.Index.UniqueCount then
		return tonumber(Inv.Index.UniqueCount("bags")) or 0
	end
	local counts = Inv.snapshots and Inv.snapshots.bags and Inv.snapshots.bags.counts
	if type(counts) ~= "table" then
		return 0
	end
	local n = 0
	for _ in pairs(counts) do
		n = n + 1
	end
	return n
end

--- True when a populated bag snapshot collapsed to empty/near-empty (load-screen flicker).
function Inv.SnapshotLooksCollapsed()
	if not snapshotUnreliable or uniqueAtUnreliable <= 0 then
		return false
	end
	-- Callers consult collapse before IsReliable, so this predicate must also
	-- expire. Otherwise Best keeps holding and never reaches the clearing path.
	if ((GetTime and GetTime()) or 0) - unreliableMarkedAt >= COLLAPSED_MAX_SEC then
		return false
	end
	local n = BagUniqueCount()
	return n == 0 or n < math.max(1, math.floor(uniqueAtUnreliable * 0.25))
end

function Inv.MarkUnreliable(_reason)
	if not snapshotUnreliable then
		uniqueAtUnreliable = BagUniqueCount()
	end
	snapshotUnreliable = true
	unreliableMarkedAt = (GetTime and GetTime()) or 0
	settleGen = nil
	settleAt = 0
	unreliableGeneration = unreliableGeneration + 1
	local gen = unreliableGeneration
	if C_Timer and C_Timer.After then
		local function ExpireHold()
			if gen == unreliableGeneration and snapshotUnreliable then
				Inv.IsReliable()
			end
		end
		-- Publish recovery even if the last bag event was the empty snapshot.
		C_Timer.After(UNRELIABLE_MAX_SEC + 0.01, ExpireHold)
		C_Timer.After(COLLAPSED_MAX_SEC + 0.01, ExpireHold)
	end
end

local function BackpackSlotCount()
	if C_Container and C_Container.GetContainerNumSlots then
		return tonumber(C_Container.GetContainerNumSlots(0)) or 0
	end
	if GetContainerNumSlots then
		return tonumber(GetContainerNumSlots(0)) or 0
	end
	return 0
end

--- Cold login/reload: backpack often reports 0 unique items, so the portal
--- collapsed-snapshot test cannot gate empty-as-real. Hold until DELAYED.
function Inv.BeginLoginHold(worldEntered)
	-- LOADING_SCREEN_ENABLED may precede the first login/reload PEW. Release
	-- Best's open-ended load latch only once that world-entry event has arrived;
	-- ordinary deferred startup must keep a genuine loading screen protected.
	if worldEntered then
		local best = rawget(_G, "FluxConsumableBest")
		if best and best.EndLoadHold then best.EndLoadHold() end
	end
	loginHold = true
	loginSawDelayed = false
	loginHoldGen = loginHoldGen + 1
	local gen = loginHoldGen
	loginHoldUntil = Now() + LOGIN_HOLD_MAX_SEC
	Inv.MarkUnreliable("login")
	if C_Timer and C_Timer.After then
		C_Timer.After(LOGIN_HOLD_MAX_SEC + 0.05, function()
			if gen ~= loginHoldGen then
				return
			end
			if loginHold then
				loginHold = false
				Inv.Notify({ bags = true, recovery = true })
			end
		end)
	end
end

function Inv.IsLoginHold()
	if not loginHold then
		return false
	end
	if Now() >= loginHoldUntil then
		loginHold = false
		return false
	end
	return true
end

--- BAG_UPDATE_DELAYED after backpack slots exist: start the short settle, then drop the hold.
function Inv.NoteLoginBagsDelayed()
	if not loginHold then
		return
	end
	if BackpackSlotCount() <= 0 then
		return
	end
	loginSawDelayed = true
	local gen = loginHoldGen
	if C_Timer and C_Timer.After then
		C_Timer.After(LOGIN_HOLD_AFTER_DELAYED, function()
			if gen ~= loginHoldGen or not loginHold then
				return
			end
			loginHold = false
			Inv.Notify({ bags = true, recovery = true })
		end)
	else
		loginHold = false
	end
end

local function TryClearUnreliable()
	if not snapshotUnreliable then
		return
	end
	local now = (GetTime and GetTime()) or 0
	local collapsed = Inv.SnapshotLooksCollapsed()
	local maxSec = collapsed and COLLAPSED_MAX_SEC or UNRELIABLE_MAX_SEC
	local cleared = false
	if (now - unreliableMarkedAt) >= maxSec then
		snapshotUnreliable = false
		settleGen = nil
		settleAt = 0
		cleared = true
	elseif collapsed then
		-- Empty snapshot after a populated one is still the load-screen flicker.
		return
	else
		local gen = Inv.GetBagGeneration and Inv.GetBagGeneration() or (Inv.snapshots.bags and Inv.snapshots.bags.generation) or 0
		if Inv.ready and settleAt > 0 and now >= settleAt and settleGen == gen then
			snapshotUnreliable = false
			settleGen = nil
			settleAt = 0
			cleared = true
		end
	end
	if cleared then
		uniqueAtUnreliable = 0
		unreliableMarkedAt = 0
		Inv.Notify({ bags = true, recovery = true })
	end
end

--- True when bag counts are trustworthy for promote/clear (not mid-portal flicker).
function Inv.IsReliable()
	TryClearUnreliable()
	if Inv.IsLoginHold and Inv.IsLoginHold() then
		return false
	end
	if not Inv.ready then
		return false
	end
	return not snapshotUnreliable
end

--- After a bag snapshot write while unreliable — start the settle window.
function Inv.NoteRefreshSettling()
	if not snapshotUnreliable then
		return
	end
	if not Inv.ready then
		return
	end
	local gen = Inv.GetBagGeneration and Inv.GetBagGeneration() or (Inv.snapshots.bags and Inv.snapshots.bags.generation) or 0
	settleGen = gen
	settleAt = ((GetTime and GetTime()) or 0) + RELIABLE_SETTLE_SEC
	if C_Timer and C_Timer.After then
		local markedGen = settleGen
		local markedAt = settleAt
		C_Timer.After(RELIABLE_SETTLE_SEC + 0.02, function()
			if settleGen ~= markedGen or settleAt ~= markedAt then
				return
			end
			TryClearUnreliable()
		end)
	end
end

-- A load screen need not produce BAG_UPDATE after the container APIs recover.
-- Capture facts again, then verify as the carried bags finish loading. Further
-- retries are only needed while the snapshot is cold.
-- These are slot reads, with normal budgeted listener delivery, not tooltip scans.
local worldRefreshGeneration = 0
local worldLoading = false
local WORLD_REFRESH_DELAYS = { 0.1, 1.0, 2.5, 5.0, 8.0 }

local function CancelWorldRefresh()
	worldLoading = true
	worldRefreshGeneration = worldRefreshGeneration + 1
end

local function BeginWorldRefresh()
	worldLoading = false
	worldRefreshGeneration = worldRefreshGeneration + 1
	local generation = worldRefreshGeneration
	local function Refresh(attempt)
		if worldLoading or generation ~= worldRefreshGeneration then return end
		if Inv.source == "builtin" then
			Inv.Builtin.Bags.Invalidate()
			Inv.Builtin.Bags.Refresh()
			Inv.NoteRefreshSettling()
		elseif Inv.source == "syndicator" and Inv.Syndicator.RebuildBags then
			Inv.Syndicator.RebuildBags()
		else
			return
		end
		Inv.NoteLoginBagsDelayed()
		Inv.Notify({ bags = true })
		local cold = BackpackSlotCount() <= 0 or BagUniqueCount() == 0
			or Inv.IsScanPending() or not Inv.IsReliable()
		local nextDelay = WORLD_REFRESH_DELAYS[attempt + 1]
		if nextDelay and (attempt <= 2 or cold) and C_Timer and C_Timer.After then
			C_Timer.After(nextDelay - WORLD_REFRESH_DELAYS[attempt], function() Refresh(attempt + 1) end)
		end
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(WORLD_REFRESH_DELAYS[1], function() Refresh(1) end)
	end
end

function Inv.HasWarband()
	return Flux.Cap and Flux.Cap.hasWarbandBank and true or false
end

local bankOpenLatch = false
local baganatorLiveLatch = false
local lastEmittedBankOpen = false
local lastEmittedCanTake = false
local bankStateListeners = {}

local function IsBankerInteractionType(kind)
	local e = Enum and Enum.PlayerInteractionType
	if not e or kind == nil then
		return false
	end
	return kind == e.Banker or kind == e.AccountBanker or kind == e.CharacterBanker
end

local function IsInteractingWithBanker()
	local PIM = C_PlayerInteractionManager
	if not PIM or not PIM.IsInteractingWithNpcOfType then
		return false
	end
	local e = Enum and Enum.PlayerInteractionType
	if not e then
		return false
	end
	if e.Banker and PIM.IsInteractingWithNpcOfType(e.Banker) then
		return true
	end
	if e.AccountBanker and PIM.IsInteractingWithNpcOfType(e.AccountBanker) then
		return true
	end
	if e.CharacterBanker and PIM.IsInteractingWithNpcOfType(e.CharacterBanker) then
		return true
	end
	return false
end

local function IsBlizzardBankFrameShown()
	local bankFrame = rawget(_G, "BankFrame")
	if bankFrame and bankFrame.IsShown and bankFrame:IsShown() then
		return true
	end
	local panel = rawget(_G, "BankPanel")
	if panel and panel.IsShown and panel:IsShown() then
		return true
	end
	return false
end

-- Backup FluxInv.Bank.IsOpen treated any shown Baganator bank window as open.
-- liveBankActive can lag or live on a parent while TransferButton is already up.
local BAGANATOR_BANK_PREFIXES = {
	"Baganator_SingleViewBankViewFrame",
	"Baganator_CategoryViewBankViewFrame",
}
local BAGANATOR_BANK_SUFFIXES = {
	"1", "2",
	"blizzard", "blizzard_black", "dark", "elvui", "gw2_ui", "ndui",
}

local function FrameIsShown(frame)
	return frame and frame.IsShown and frame:IsShown()
end

local function BaganatorViewLooksLive(view)
	if not view then
		return false
	end
	if view.liveBankActive then
		return true
	end
	local tab = view.currentTab
	if tab and tab.isLive and not tab.isLocked then
		return true
	end
	return false
end

function Inv.IsBaganatorBankViewShown()
	local Compat = rawget(_G, "FluxBaganatorCompat")
	if Compat and Compat.ForEachBaganatorBankView then
		local shown = false
		Compat.ForEachBaganatorBankView(function(view)
			if FrameIsShown(view) then
				shown = true
			end
		end)
		if shown then
			return true
		end
	end
	for i = 1, #BAGANATOR_BANK_PREFIXES do
		local prefix = BAGANATOR_BANK_PREFIXES[i]
		if FrameIsShown(rawget(_G, prefix)) then
			return true
		end
		for s = 1, #BAGANATOR_BANK_SUFFIXES do
			if FrameIsShown(rawget(_G, prefix .. BAGANATOR_BANK_SUFFIXES[s])) then
				return true
			end
		end
	end
	return false
end

function Inv.IsBaganatorBankLiveShown()
	local Compat = rawget(_G, "FluxBaganatorCompat")
	if Compat and Compat.ForEachBaganatorBankView then
		local live, anyShown = false, false
		Compat.ForEachBaganatorBankView(function(view)
			if FrameIsShown(view) then
				anyShown = true
				if BaganatorViewLooksLive(view) then
					live = true
				end
			end
		end)
		if anyShown then
			return live
		end
	end
	return Inv.IsBaganatorBankViewShown() and IsInteractingWithBanker()
end

function Inv.RegisterBankStateListener(key, fn)
	if type(key) ~= "string" or type(fn) ~= "function" then
		return
	end
	bankStateListeners[key] = fn
end

local function EmitBankStateIfChanged()
	local open = Inv.IsBankOpen()
	local canTake = Inv.CanTakeFromBank and Inv.CanTakeFromBank() or false
	if open == lastEmittedBankOpen and canTake == lastEmittedCanTake then
		return
	end
	lastEmittedBankOpen = open
	lastEmittedCanTake = canTake
	for _, fn in pairs(bankStateListeners) do
		Flux.Safecall(fn, open)
	end
end

local function StillHasBankAccess()
	if baganatorLiveLatch then
		return true
	end
	if Inv.IsBaganatorBankViewShown and Inv.IsBaganatorBankViewShown() then
		return true
	end
	if IsInteractingWithBanker() then
		return true
	end
	if IsBlizzardBankFrameShown() then
		return true
	end
	return false
end

function Inv.ShouldKeepBankOpen()
	return StillHasBankAccess()
end

function Inv.SetBankOpenLatch(open)
	open = not not open
	if not open and bankOpenLatch then
		Inv.PersistBankCounts()
	end
	bankOpenLatch = open
	if not open and next(itemDataBagObservers) then
		local C = Inv.Containers
		for bag in pairs(itemDataBagObservers) do
			if C and not C.IsCarriedBag(bag) then itemDataBagObservers[bag] = nil end
		end
		StopIdleItemData()
	end
	if open and Inv.Containers and Inv.Containers.Invalidate then
		Inv.Containers.Invalidate()
	end
	EmitBankStateIfChanged()
end

function Inv.SetBaganatorBankLive(active)
	local nextLive = not not active
	if baganatorLiveLatch == nextLive then
		return
	end
	baganatorLiveLatch = nextLive
	if baganatorLiveLatch then
		bankOpenLatch = true
		if Inv.Containers and Inv.Containers.Invalidate then
			Inv.Containers.Invalidate()
		end
		if Inv.source == "builtin" and Inv.Builtin and Inv.Builtin.Bank and Inv.Builtin.Bank.SetOpen then
			Inv.Builtin.Bank.SetOpen(true)
		end
	elseif not StillHasBankAccess() then
		bankOpenLatch = false
		if Inv.source == "builtin" and Inv.Builtin and Inv.Builtin.Bank and Inv.Builtin.Bank.SetOpen then
			Inv.Builtin.Bank.SetOpen(false)
		end
	end
	EmitBankStateIfChanged()
end

function Inv.IsBaganatorBankLive()
	return baganatorLiveLatch and true or false
end

--- Live banker: BANKFRAME_OPENED / PIM Banker / Baganator liveBankActive.
--- A cached Baganator alt bank must not start restock moves.
function Inv.IsBankLive()
	if baganatorLiveLatch then
		return true
	end
	if Inv.IsBaganatorBankViewShown and Inv.IsBaganatorBankViewShown() then
		return Inv.IsBaganatorBankLiveShown and Inv.IsBaganatorBankLiveShown() or false
	end
	if IsInteractingWithBanker() then
		return true
	end
	if bankOpenLatch then
		return true
	end
	if Inv.Builtin and Inv.Builtin.Bank and Inv.Builtin.Bank.IsOpen and Inv.Builtin.Bank.IsOpen() then
		return true
	end
	return IsBlizzardBankFrameShown()
end

--- True when bank containers can be picked up (at the banker, or Baganator live).
--- Cached bank windows and readable-but-closed tabs do not count: flyouts must
--- not offer those items, because Equip/Pickup will fail.
function Inv.CanTakeFromBank()
	if baganatorLiveLatch then
		return true
	end
	if Inv.IsBaganatorBankViewShown and Inv.IsBaganatorBankViewShown() then
		return Inv.IsBaganatorBankLiveShown and Inv.IsBaganatorBankLiveShown() or false
	end
	if IsInteractingWithBanker() then
		return true
	end
	if bankOpenLatch then
		return true
	end
	if Inv.Builtin and Inv.Builtin.Bank and Inv.Builtin.Bank.IsOpen and Inv.Builtin.Bank.IsOpen() then
		return true
	end
	return IsBlizzardBankFrameShown()
end

function Inv.IsBankOpen()
	if bankOpenLatch or baganatorLiveLatch then
		return true
	end
	if Inv.IsBaganatorBankViewShown and Inv.IsBaganatorBankViewShown() then
		return true
	end
	if Inv.Builtin and Inv.Builtin.Bank and Inv.Builtin.Bank.IsOpen and Inv.Builtin.Bank.IsOpen() then
		return true
	end
	if IsInteractingWithBanker() then
		return true
	end
	return IsBlizzardBankFrameShown()
end

local function HookBankOpenEvents()
	if not (Flux.Events and Flux.Events.Register) then
		return
	end
	Flux.Events.Register("BANKFRAME_OPENED", function()
		Inv.SetBankOpenLatch(true)
	end)
	Flux.Events.Register("BANKFRAME_CLOSED", function()
		if StillHasBankAccess() then
			return
		end
		Inv.SetBankOpenLatch(false)
	end)
	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
		if IsBankerInteractionType(kind) then
			Inv.SetBankOpenLatch(true)
		end
	end)
	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
		if not IsBankerInteractionType(kind) then
			return
		end
		if StillHasBankAccess() then
			return
		end
		Inv.SetBankOpenLatch(false)
	end)
end

local function HookScheduler()
	if schedulerHooked then
		return
	end
	schedulerHooked = true
	Flux.Scheduler.Register("inventory", function(tokens)
		if Inv.source == "syndicator" then ClearItemData() end
		if Inv.source == "builtin" and Inv.Builtin.Flush then
			Inv.Builtin.Flush(tokens)
		end
		Inv.Notify(tokens)
	end)
end

-- One bags-only startup snapshot. No provider, bank scan or timer needs to
-- finish before the grid buttons can select and bind their carried items.
function Inv.PrepareHUD()
	if InCombatLockdown and InCombatLockdown() then return false end
	local bags = Inv.Builtin and Inv.Builtin.Bags
	if not (bags and bags.Invalidate and bags.Refresh) then return false end
	bags.Invalidate()
	bags.Refresh()
	local best = _G.FluxConsumableBest
	if best and best.RequestRecompute then
		best.RequestRecompute({ reason = "hudLogin", bagsOnly = true, force = true, immediate = true })
	end
	return true
end

function Inv.Start()
	if Inv.started then
		return
	end
	Inv.started = true
	Inv.BeginLoginHold()
	HookScheduler()
	HookBankOpenEvents()
	if Flux.Events and Flux.Events.Register then
		-- Merchant open keeps heavy listeners on the budgeted queue: vendor
		-- sweeps are the worst bag storm there is.
		Flux.Events.Register("MERCHANT_SHOW", function()
			Inv.SetMerchantOpen(true)
		end)
		Flux.Events.Register("MERCHANT_CLOSED", function()
			Inv.SetMerchantOpen(false)
		end)
		-- Mailbox: same hold, including Syndicator (builtin Mail.Start no-ops there).
		-- MAIL_INBOX_UPDATE also raises a bag storm so take-attachment identity
		-- changes do not rebuild consumables in the same frame as the inbox scan.
		local function OnMailboxOpened()
			Inv.SetMailboxOpen(true)
		end
		local function OnMailboxClosed()
			Inv.SetMailboxOpen(false)
			Inv.NotifyBagStorm(MAILBOX_CLOSE_HOLD)
		end
		Flux.Events.Register("MAIL_SHOW", OnMailboxOpened)
		Flux.Events.Register("MAIL_INBOX_UPDATE", function()
			if Inv.IsMailboxOpen() then Inv.NotifyBagStorm() end
		end)
		Flux.Events.Register("MAIL_CLOSED", OnMailboxClosed)
		Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
			if IsMailInteraction(kind) then
				OnMailboxOpened()
			end
		end)
		Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
			if IsMailInteraction(kind) then
				OnMailboxClosed()
			end
		end)
	end
	local bankFrameLatchHooked
	local function HookBankFrameLatch()
		if bankFrameLatchHooked then
			return
		end
		-- Native bank OnShow can purchase the free first tab. Keep its scripts
		-- untouched on Forever; BANKFRAME/PIM events above own our open latch.
		local client = Flux.Client
		if client and (client.isCamelot or client.isForever) then
			bankFrameLatchHooked = true
			return
		end
		local bankFrame = rawget(_G, "BankFrame")
		if not (bankFrame and bankFrame.HookScript) then
			return
		end
		bankFrameLatchHooked = true
		bankFrame:HookScript("OnShow", function()
			Inv.SetBankOpenLatch(true)
		end)
		bankFrame:HookScript("OnHide", function()
			if C_Timer and C_Timer.After then
				C_Timer.After(0, function()
					if Inv.ShouldKeepBankOpen and Inv.ShouldKeepBankOpen() then
						return
					end
					if Inv.IsBaganatorBankViewShown and Inv.IsBaganatorBankViewShown() then
						return
					end
					Inv.SetBankOpenLatch(false)
				end)
			end
		end)
	end
	HookBankFrameLatch()
	if not bankFrameLatchHooked and Flux.Events and Flux.Events.Register then
		Flux.Events.Register("ADDON_LOADED", function(_, name)
			if name == "Blizzard_UIPanels_Game" then
				HookBankFrameLatch()
			end
		end)
	end

	local Store = Inv.Store
	if Store and Store.EnsureCurrentCharacter then
		Store.EnsureCurrentCharacter()
		if Store.ImportGoldLedgerStubs then
			Store.ImportGoldLedgerStubs()
		end
	end

	local syn = Flux.Optional and Flux.Optional.Get("Syndicator")
	local api = rawget(_G, "Syndicator")
	if syn and syn.loaded and api and api.CallbackRegistry and Inv.Syndicator.Start then
		if Store and Store.SetUsesSyndicator then
			Store.SetUsesSyndicator(true)
		end
		Inv.Syndicator.Start()
	elseif Inv.Builtin.Start then
		Inv.Builtin.Start()
	end
	if Inv.Tooltip and Inv.Tooltip.Start then
		Inv.Tooltip.Start()
	end
	if Flux.Events then
		Flux.Events.Register("ADDON_LOADED", function(_, name)
			if name == "Syndicator" and Inv.Syndicator.Start then
				Flux.Timer.After(0, Inv.Syndicator.Start)
			end
		end)
	end
	Inv.LoadPersistedBankCounts()

	local sawPew = false
	local function ArmLoadHold()
		CancelWorldRefresh()
		Inv.MarkUnreliable("zone")
		local Best = rawget(_G, "FluxConsumableBest")
		if Best and Best.BeginLoadHold then
			Best.BeginLoadHold()
		elseif Best and Best.ArmPortalSoftHold then
			Best.ArmPortalSoftHold()
		end
	end
	local function ArmPortalSettle()
		Inv.MarkUnreliable("zone")
		local Best = rawget(_G, "FluxConsumableBest")
		if Best and Best.ArmPortalSoftHold then
			Best.ArmPortalSoftHold()
		end
	end
	local function OnLoadingScreenFinished()
		local Best = rawget(_G, "FluxConsumableBest")
		-- A loading screen need not have another world-entry event. Complete
		-- its hold and restart any refresh cancelled by the loading event.
		-- Normal PEW completion and duplicate disabled events need no new work.
		if worldLoading or (Best and Best._loadHoldOpen) then
			BeginWorldRefresh()
			ArmPortalSettle()
		end
	end
	if Flux.Events and Flux.Events.Register then
		-- Hold before bags flicker; either world entry or screen completion settles.
		Flux.Events.Register("PLAYER_LEAVING_WORLD", ArmLoadHold)
		pcall(Flux.Events.Register, "LOADING_SCREEN_ENABLED", ArmLoadHold)
		pcall(Flux.Events.Register, "LOADING_SCREEN_DISABLED", OnLoadingScreenFinished)
		Flux.Events.Register("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReload)
			BeginWorldRefresh()
			if not sawPew then
				sawPew = true
				if isInitialLogin == true or isReload == true then
					Inv.BeginLoginHold(true)
					return
				end
				-- Classic / missing args: first PEW of the session is login.
				if isInitialLogin == nil and isReload == nil then
					Inv.BeginLoginHold(true)
					return
				end
			end
			ArmPortalSettle()
		end)
		pcall(Flux.Events.Register, "BAG_UPDATE_DELAYED", function()
			-- Syndicator (and any source): DELAYED is the batch-complete signal.
			-- Builtin Watch also handles this; the helpers are idempotent.
			if Inv.NoteLoginBagsDelayed then
				Inv.NoteLoginBagsDelayed()
			end
			-- Era/Anniversary drops do not open a storm. Flushing here would run
			-- consumable best and the other settled callbacks in the drop frame.
			local client = Flux.Client
			if client and (client.isEra or client.isAnniversary) then
				return
			end
			if Inv.EndBagStorm then
				Inv.EndBagStorm()
			end
		end)
	end
	-- Inventory enables in the deferred startup phase and can miss the first PEW.
	BeginWorldRefresh()
end

Flux.Module.Register("Inventory", {
	phase = "deferred",
	clients = { era = true, anniversary = true, classic = true, midnight = true },
	optional = { Syndicator = "prefer" },
	OnEnable = function()
		Inv.Start()
	end,
})

local function yn(v)
	return v and "yes" or "no"
end

SLASH_FLUXINV1 = "/fluxinv"
SlashCmdList["FLUXINV"] = function(msg)
	msg = type(msg) == "string" and msg:match("^%s*(.-)%s*$") or ""
	local InvMod = Flux.Inventory
	if not InvMod then
		Flux.Print("inventory not loaded")
		return
	end
	local cmd, rest = msg:match("^(%S+)%s*(.*)$")
	cmd = cmd and cmd:lower() or ""
	if cmd == "buttons" then
		-- On-demand facts only. No events, polling, setting writes or secure
		-- mutations: keep the intermittent state available for diagnosis.
		local function value(v)
			local s = Flux.Secrets
			local secret = s and s.IsSecretValue or _G.issecretvalue
			if secret then
				local ok, hidden = pcall(secret, v)
				if not ok or hidden then return "restricted" end
			end
			return tostring(v)
		end
		local function read(fn, ...)
			if type(fn) ~= "function" then return "missing" end
			local ok, result = pcall(fn, ...)
			return ok and value(result) or "error"
		end
		local function number(v)
			if value(v) == "restricted" then return nil end
			local ok, n = pcall(tonumber, v)
			return ok and n or nil
		end
		local best = rawget(_G, "FluxConsumableBest")
		print("COUNTS/1 source=" .. value(InvMod.source)
			.. " reliable=" .. read(InvMod.IsReliable)
			.. " hold=" .. read(best and best.ShouldSoftHoldOwned)
			.. " load=" .. value(best and best._loadHoldOpen))
		local physical, unknown = {}, {}
		local container, bags = Flux.Container, InvMod.Containers
		if container and bags and bags.GetCarriedBagIDs then
			for _, bag in ipairs(bags.GetCarriedBagIDs()) do
				for slot = 1, container.GetNumSlots(bag) do
					local info = container.GetItemInfo(bag, slot)
					local id = number(info and info.itemID or container.GetItemID(bag, slot))
					if id then
						local n = info and number(info.stackCount)
						if n then physical[id] = (physical[id] or 0) + n
						else unknown[id] = true end
					end
				end
			end
		end
		local seen = {}
		local function row(label, btn, probe)
			if btn then seen[btn] = true end
			local id = btn and (btn.ItemId or btn._liveCountItemId) or probe
			id = number(id) or number(probe)
			local text = btn and btn.WCount
			local base = label .. " id=" .. value(id)
				.. " action=" .. value(btn and btn.ActionType)
				.. " text=" .. read(text and text.GetText, text)
				.. " forced=" .. value(btn and btn._forcedCount)
				.. " live=" .. value(btn and btn._forcedCountLive)
			if id then
				base = base .. " slots=" .. (unknown[id] and "pending" or value(physical[id] or 0))
					.. " snapshot=" .. read(InvMod.GetCount, id)
					.. " modern=" .. read(C_Item and C_Item.GetItemCount, id, false, false)
					.. " legacy=" .. read(_G.GetItemCount, id, false, false)
					.. " wrapped=" .. read(Flux.Item and Flux.Item.GetCount, id, false, false)
					.. " uses=" .. read(InvMod.GetLiveCount, id, { charges = true, bank = false, warband = false })
			end
			print(base)
		end
		for _, spec in ipairs({ { "food", "FluxNCFood" }, { "water", "FluxNCWater" },
			{ "healing", "FluxCombatHealPotion" }, { "mana", "FluxCombatManaPotion" },
			{ "bandage", "FluxCombatBandage" }, { "gem", "FluxCombatManaGem" },
			{ "stone", "FluxCombatHealthstone" } }) do
			local module = rawget(_G, spec[2])
			row(spec[1], module and module.Button, module and (module._trackedItemID or module._observedEmptyItemID))
		end
		local count = 0
		local function others(list)
			for _, btn in ipairs(list or {}) do
				local id = btn.ItemId or btn._liveCountItemId or (btn.ActionType == "item" and btn.ActionValue)
				if not seen[btn] and btn.kind ~= "strip" and number(id) and count < 12 then
					count = count + 1
					row("other" .. count, btn, id)
				end
			end
		end
		others(Flux.EBS and Flux.EBS.buttons)
		others(Flux.EBS and Flux.EBS.badges)
		return
	end
	if cmd == "count" then
		local itemID = tonumber(rest)
		if not itemID then
			Flux.Print("/fluxinv count <itemID>")
			return
		end
		local snap = InvMod.GetCount(itemID)
		local live = InvMod.GetLiveCount(itemID)
		Flux.Print("item", itemID, "snapshot=" .. tostring(snap), "live=" .. tostring(live))
		local locs = InvMod.Find(itemID)
		print("  locations: " .. tostring(#locs))
		for i = 1, math.min(#locs, 8) do
			local loc = locs[i]
			print("    " .. tostring(loc.region)
				.. " bag=" .. tostring(loc.bag)
				.. " slot=" .. tostring(loc.slot)
				.. " x" .. tostring(loc.count))
		end
		return
	end
	if cmd == "listeners" then
		local info = InvMod.GetListenerInfo and InvMod.GetListenerInfo() or {}
		Flux.Print("Inventory listeners: " .. tostring(#info))
		for i = 1, #info do
			local e = info[i]
			local regions = "any"
			if e.regions then
				local names = {}
				for name in pairs(e.regions) do
					names[#names + 1] = name
				end
				table.sort(names)
				regions = table.concat(names, "+")
			end
			print("  " .. e.key
				.. "  tier=" .. tostring(e.tier)
				.. " regions=" .. regions
				.. (e.deferHeavy and " deferHeavy" or "")
				.. (e.sync and " sync" or ""))
		end
		return
	end

	Flux.Print("Inventory")
	print("  source=" .. tostring(InvMod.GetSource())
		.. " ready=" .. yn(InvMod.IsReady())
		.. " bankOpen=" .. yn(InvMod.IsBankOpen())
		.. " bankLive=" .. yn(InvMod.IsBankLive and InvMod.IsBankLive())
		.. " canTakeFromBank=" .. yn(InvMod.CanTakeFromBank and InvMod.CanTakeFromBank())
		.. " warband=" .. yn(InvMod.HasWarband()))
	print("  storm=" .. yn(InvMod.IsBagStorm and InvMod.IsBagStorm())
		.. " mailbox=" .. yn(InvMod.IsMailboxOpen and InvMod.IsMailboxOpen())
		.. " deferHeavy=" .. yn(InvMod.ShouldDeferHeavyWork and InvMod.ShouldDeferHeavyWork())
		.. " scanPending=" .. yn(InvMod.IsScanPending and InvMod.IsScanPending())
		.. " itemDataRevision=" .. tostring(InvMod.itemDataRevision or "legacy")
		.. " listeners=" .. tostring(#(InvMod.GetListenerInfo and InvMod.GetListenerInfo() or {})))
	local unique = InvMod.Index and InvMod.Index.UniqueCount and InvMod.Index.UniqueCount("bags") or 0
	print("  unique bag items=" .. tostring(unique))
	local Store = InvMod.Store
	if Store and Store.GetAllCharacters then
		print("  known characters=" .. tostring(#Store.GetAllCharacters())
			.. " syndicator=" .. yn(Store.UsesSyndicator and Store.UsesSyndicator()))
	end
end
