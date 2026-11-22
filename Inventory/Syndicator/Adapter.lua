-- Inventory/Syndicator/Adapter.lua — Syndicator facts → same snapshots as builtin
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Adapter = Inv.Syndicator

local bound = false
local waiting = false
local MAIL_DEBOUNCE = 0.2
local mailPending, mailFirst, mailDue
local inboxScan, inboxObservation, observedMail, physicalMail
local pendingInboxScans = 0
local firstWorldObserved, inboxBeforeBind, watchingInboxHistory
local auctionsPending = false

-- Last rebuild classification per region, so Syndicator and builtin hand
-- listeners the same ctx (changeKind / added / removed / dirtyBags).
local bagsChange = { kind = "none", added = nil, removed = nil, dirty = {} }
local bankChange = { kind = "none", added = nil, removed = nil, dirty = {} }
local keyBuf = {}
local C = Inv.Containers
local slotDiffCapability = rawget(ns, "InventorySlotDiff")
local slotDiffOwner, ownedSlotDiff
if type(slotDiffCapability) == "table" then
	slotDiffOwner = rawget(slotDiffCapability, "owner")
	ownedSlotDiff = rawget(slotDiffCapability, "diff")
end
local bankRowsReusable = C == slotDiffOwner
	and rawget(Inv, "Containers") == C
	and type(ownedSlotDiff) == "function"
	and rawget(C, "DiffSlots") == ownedSlotDiff
local bagsItemSets = C.NewItemSetLog()
local bankItemSets = C.NewItemSetLog()

local function Wipe(t)
	if wipe then
		return wipe(t)
	end
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

local function NumericItemID(value)
	local n = tonumber(value)
	if n and n > 0 then
		return n
	end
	local Secrets = Flux and Flux.Secrets
	if Secrets and Secrets.SafeGetNumber then
		n = Secrets.SafeGetNumber(value, 0)
		if n and n > 0 then
			return n
		end
	end
	return nil
end

local function FillFromSlots(bagID, slotArray, byBag, counts, previous, beforeKeys)
	local dest = {}
	byBag[bagID] = dest
	if type(slotArray) ~= "table" then
		return
	end
	for slot, rec in pairs(slotArray) do
		local id = rec and NumericItemID(rec.itemID)
		if id then
			local n = tonumber(rec.itemCount or rec.count) or 1
			local link = rec.itemLink or rec.link
			local old = previous and previous[slot]
			if old and old.itemID == id and old.count == n and old.link == link then
				dest[slot] = old
			else
				dest[slot] = { itemID = id, count = n, link = link }
			end
			if beforeKeys and beforeKeys[id] == nil then beforeKeys[id] = counts[id] ~= nil end
			counts[id] = (counts[id] or 0) + n
		end
	end
end

local function Constants()
	local syn = rawget(_G, "Syndicator")
	return syn and syn.Constants
end

local function API()
	local syn = rawget(_G, "Syndicator")
	return syn and syn.API
end

local function CurrentCharacter()
	local api = API()
	if not api or not api.GetCurrentCharacter or not api.GetCharacter then
		return nil
	end
	local name = api.GetCurrentCharacter()
	if not name then
		return nil
	end
	return api.GetCharacter(name), name
end

local function SubtractBagCounts(byBag, bagID, counts, beforeKeys)
	local dest = byBag[bagID]
	if not dest then
		return
	end
	for _, rec in pairs(dest) do
		local id = rec and NumericItemID(rec.itemID)
		if id then
			if beforeKeys and beforeKeys[id] == nil then beforeKeys[id] = counts[id] ~= nil end
			local n = (counts[id] or 0) - (rec.count or 0)
			if n <= 0 then
				counts[id] = nil
			else
				counts[id] = n
			end
		end
	end
end

local function CharacterBankSlotArray(char, cons, index)
	if not char or not index then
		return nil
	end
	if cons and cons.CharacterBankTabsActive then
		local tab = char.bankTabs and char.bankTabs[index]
		if type(tab) == "table" then
			return tab.slots or tab
		end
		return nil
	end
	return char.bank and char.bank[index]
end

local function BagIndexMap(indexes)
	local map = {}
	if type(indexes) ~= "table" then
		return map
	end
	for i, bagID in ipairs(indexes) do
		map[bagID] = i
	end
	return map
end

--- Record which bags this rebuild touched. Syndicator hands us the dirty set,
--- so a full rebuild reports every bag it walked.
local function NoteDirty(change, dirtyBags, ids, itemSets)
	if not (itemSets and itemSets.any) then
		Wipe(change.dirty)
	end
	if dirtyBags then
		for bagID in pairs(dirtyBags) do
			change.dirty[bagID] = true
		end
	elseif type(ids) == "table" then
		for i = 1, #ids do
			change.dirty[ids[i]] = true
		end
	end
end

local function Classify(change, snap, beforeKeys, itemSets)
	local kind, added, removed = Inv.ClassifyCountKeys(beforeKeys, snap.counts)
	-- Several cache callbacks can precede one inventory publication. Retain
	-- every ownership change until TakeBagsItemSets consumes that batch.
	if itemSets and itemSets.any then
		kind, added, removed = Inv.MergeChangeKind(change.kind, change.added, change.removed, kind, added, removed)
	end
	change.kind, change.added, change.removed = kind, added, removed
end

local function ClassifyTouched(change, counts, beforeKeys, itemSets)
	local added, removed
	for id, existed in pairs(beforeKeys) do
		local exists = counts[id] ~= nil
		if exists and not existed then added = added or {}; added[id] = true
		elseif existed and not exists then removed = removed or {}; removed[id] = true end
	end
	local kind = (added or removed) and "identityChanged" or "countOnly"
	if itemSets and itemSets.any then
		kind, added, removed = Inv.MergeChangeKind(change.kind, change.added, change.removed, kind, added, removed)
	end
	change.kind, change.added, change.removed = kind, added, removed
end

function Adapter.RebuildBags(dirtyBags)
	local char = CurrentCharacter()
	local cons = Constants()
	local snap = Inv.snapshots.bags
	local doFull = not dirtyBags or not next(dirtyBags) or not next(snap.byBag)
	if doFull then
		Inv.SnapshotCountKeys(snap.counts, keyBuf)
		Wipe(snap.byBag)
		local counts = {}
		if char and cons and cons.AllBagIndexes then
			local bags = char.bags
			for i, bagID in ipairs(cons.AllBagIndexes) do
				FillFromSlots(bagID, bags and bags[i], snap.byBag, counts)
			end
		end
		snap.counts = counts
		snap.generation = (snap.generation or 0) + 1
		NoteDirty(bagsChange, dirtyBags, cons and cons.AllBagIndexes, bagsItemSets)
		Classify(bagsChange, snap, keyBuf, bagsItemSets)
		C.NoteItemSets(bagsItemSets, nil)
		if Inv.NoteRefreshSettling then
			Inv.NoteRefreshSettling()
		end
		return
	end
	local counts = snap.counts
	if not counts then
		counts = {}
		snap.counts = counts
	end
	local bags = char and char.bags
	local indexByBag = BagIndexMap(cons and cons.AllBagIndexes)
	local touched, delta, beforeKeys = {}, {}, {}
	for bagID in pairs(dirtyBags) do
		local old = snap.byBag[bagID]
		SubtractBagCounts(snap.byBag, bagID, counts, beforeKeys)
		local i = indexByBag[bagID]
		FillFromSlots(bagID, bags and i and bags[i], snap.byBag, counts, old, beforeKeys)
		C.DiffSlots(old, snap.byBag[bagID], touched, delta)
	end
	snap.generation = (snap.generation or 0) + 1
	NoteDirty(bagsChange, dirtyBags, nil, bagsItemSets)
	ClassifyTouched(bagsChange, counts, beforeKeys, bagsItemSets)
	C.NoteItemSets(bagsItemSets, touched, C.ChangedFromDelta(delta))
	if Inv.NoteRefreshSettling then
		Inv.NoteRefreshSettling()
	end
end

function Adapter.RebuildBank(dirtyBags)
	local char = CurrentCharacter()
	local cons = Constants()
	local snap = Inv.snapshots.bank
	local doFull = not dirtyBags or not next(dirtyBags) or not next(snap.byBag)
	if doFull then
		Inv.SnapshotCountKeys(snap.counts, keyBuf)
		Wipe(snap.byBag)
		local counts = {}
		if char and cons and cons.AllBankIndexes then
			for i, bagID in ipairs(cons.AllBankIndexes) do
				FillFromSlots(bagID, CharacterBankSlotArray(char, cons, i), snap.byBag, counts)
			end
		end
		snap.counts = counts
		snap.generation = (snap.generation or 0) + 1
		NoteDirty(bankChange, dirtyBags, cons and cons.AllBankIndexes)
		Classify(bankChange, snap, keyBuf)
		C.NoteItemSets(bankItemSets, nil)
		if Inv.PersistBankCounts then
			Inv.PersistBankCounts()
		end
		return
	end
	local counts = snap.counts
	if not counts then
		counts = {}
		snap.counts = counts
	end
	local indexByBag = BagIndexMap(cons and cons.AllBankIndexes)
	local touched, delta, beforeKeys = {}, {}, {}
	for bagID in pairs(dirtyBags) do
		local old = snap.byBag[bagID]
		SubtractBagCounts(snap.byBag, bagID, counts, beforeKeys)
		local i = indexByBag[bagID]
		if bankRowsReusable and (rawget(Inv, "Containers") ~= C
			or rawget(C, "DiffSlots") ~= ownedSlotDiff) then
			bankRowsReusable = false
		end
		local previous = bankRowsReusable and old or nil
		FillFromSlots(bagID, CharacterBankSlotArray(char, cons, i), snap.byBag, counts, previous, beforeKeys)
		if bankRowsReusable and (rawget(Inv, "Containers") ~= C
			or rawget(C, "DiffSlots") ~= ownedSlotDiff) then
			bankRowsReusable = false
		end
		if previous and not bankRowsReusable then
			local slots = snap.byBag[bagID]
			for slot, row in pairs(slots) do
				if row == previous[slot] then
					slots[slot] = { itemID = row.itemID, count = row.count, link = row.link }
				end
			end
		end
		C.DiffSlots(old, snap.byBag[bagID], touched, delta)
	end
	snap.generation = (snap.generation or 0) + 1
	NoteDirty(bankChange, dirtyBags, nil)
	ClassifyTouched(bankChange, counts, beforeKeys)
	C.NoteItemSets(bankItemSets, touched, C.ChangedFromDelta(delta))
	if Inv.MarkBankCountsDirty then
		Inv.MarkBankCountsDirty()
	end
end

--- Same accessor shape as Builtin.Bags / Builtin.Bank.
function Adapter.GetLastBagsChangeKind()
	return bagsChange.kind
end

function Adapter.GetLastBagsAddedItemIDs()
	return bagsChange.added
end

function Adapter.GetLastBagsRemovedItemIDs()
	return bagsChange.removed
end

function Adapter.GetLastBagsDirtyBags()
	return bagsChange.dirty
end

function Adapter.GetLastBankChangeKind()
	return bankChange.kind
end

function Adapter.GetLastBankAddedItemIDs()
	return bankChange.added
end

function Adapter.GetLastBankRemovedItemIDs()
	return bankChange.removed
end

function Adapter.GetLastBankDirtyBags()
	return bankChange.dirty
end

function Adapter.TakeBagsItemSets()
	return C.TakeItemSets(bagsItemSets)
end

function Adapter.TakeBankItemSets()
	return C.TakeItemSets(bankItemSets)
end

function Adapter.RebuildWarband()
	local snap = Inv.snapshots.warband
	C.NoteItemSets(bankItemSets, nil)
	Wipe(snap.byBag)
	local counts = {}
	if Inv.HasWarband() then
		local api = API()
		local cons = Constants()
		local war = api and api.GetWarband and api.GetWarband(1)
		local indexes = cons and cons.AllWarbandIndexes
		if war and war.bank and indexes then
			for i, bagID in ipairs(indexes) do
				local tab = war.bank[i]
				local slots = tab and (tab.slots or tab)
				FillFromSlots(bagID, slots, snap.byBag, counts)
			end
		end
	end
	snap.counts = counts
	snap.generation = (snap.generation or 0) + 1
	if Inv.MarkBankCountsDirty then
		Inv.MarkBankCountsDirty()
	end
end

function Adapter.RebuildEquip()
	local char = CurrentCharacter()
	local cons = Constants()
	local snap = Inv.snapshots.equip
	Wipe(snap.bySlot)
	local counts = {}
	local offset = (cons and cons.EquippedInventorySlotOffset) or 1
	local equipped = char and char.equipped
	if type(equipped) == "table" then
		for stored, rec in pairs(equipped) do
			local slot = tonumber(stored)
			if slot then
				slot = slot - offset
			end
			local id = rec and NumericItemID(rec.itemID)
			if slot and id then
				local n = tonumber(rec.itemCount or rec.count) or 1
				snap.bySlot[slot] = { itemID = id, count = n, link = rec.itemLink or rec.link }
				counts[id] = (counts[id] or 0) + n
			end
		end
	end
	snap.counts = counts
	snap.generation = (snap.generation or 0) + 1
end

-- The adapter exclusively owns these private mail/auction index maps. A known
-- map's cardinality avoids walking it again after every unchanged provider list.
local listSizes = setmetatable({}, { __mode = "k" })

local function FillFromList(slotArray, snap)
	if not snap then
		return
	end
	local previous = snap.byIndex
	local byIndex, counts, size = {}, {}, 0
	if type(slotArray) == "table" then
		for index, rec in pairs(slotArray) do
			local id = rec and NumericItemID(rec.itemID)
			if id then
				size = size + 1
				local n = tonumber(rec.itemCount or rec.count) or 1
				local link = rec.itemLink or rec.link
				local old = previous and previous[index]
				if old and old.itemID == id and old.count == n and old.link == link then
					byIndex[index] = old
				else
					byIndex[index] = { itemID = id, count = n, link = link }
				end
				counts[id] = (counts[id] or 0) + n
			end
		end
	end
	-- Publish completed maps together; matching rows remain immutable across generations.
	snap.byIndex, snap.counts = byIndex, counts
	snap.generation = (snap.generation or 0) + 1
	listSizes[snap] = { map = byIndex, generation = snap.generation, size = size }
end

local function ListMatchesSnapshot(slotArray, snap)
	if not snap or not snap.byIndex or not snap.generation or snap.generation == 0 then return false end
	local known = listSizes[snap]
	if not known or known.map ~= snap.byIndex or known.generation ~= snap.generation then
		local size = 0
		for _ in pairs(snap.byIndex) do size = size + 1 end
		known = { map = snap.byIndex, generation = snap.generation, size = size }
		listSizes[snap] = known
	end
	local remaining = 0
	if type(slotArray) == "table" then
		for index, rec in pairs(slotArray) do
			local id = rec and NumericItemID(rec.itemID)
			if id then
				local old = snap.byIndex[index]
				if not old or old.itemID ~= id or old.count ~= (tonumber(rec.itemCount or rec.count) or 1)
					or old.link ~= (rec.itemLink or rec.link) then return false end
				remaining = remaining + 1
			end
		end
	end
	return remaining == known.size
end

--- Returns true when the live mail snapshot actually changed.
function Adapter.RebuildMail()
	local char = CurrentCharacter()
	local mail = char and char.mail
	if ListMatchesSnapshot(mail, Inv.snapshots.mail) then
		return false
	end
	FillFromList(mail, Inv.snapshots.mail)
	return true
end

function Adapter.RebuildVoid()
	local snap = Inv.snapshots.void
	if not snap then
		return
	end
	local char = CurrentCharacter()
	Wipe(snap.byBag)
	local counts = {}
	local void = char and char.void
	if type(void) == "table" then
		for page, slots in pairs(void) do
			FillFromSlots(page, slots, snap.byBag, counts)
		end
	end
	snap.counts = counts
	snap.generation = (snap.generation or 0) + 1
end

function Adapter.RebuildAuctions()
	local char = CurrentCharacter()
	local auctions = char and char.auctions
	if ListMatchesSnapshot(auctions, Inv.snapshots.auctions) then return false end
	FillFromList(auctions, Inv.snapshots.auctions)
	return true
end

function Adapter.RebuildGuild()
	local snap = Inv.snapshots.guild
	if not snap then
		return
	end
	Wipe(snap.byBag)
	local counts = {}
	local api = API()
	local name = api and api.GetCurrentGuild and api.GetCurrentGuild()
	local guild = name and api.GetGuild and select(1, api.GetGuild(name))
	local bank = guild and guild.bank
	if type(bank) == "table" then
		for tabIndex, tab in pairs(bank) do
			local slots = tab and (tab.slots or tab)
			FillFromSlots(tabIndex, slots, snap.byBag, counts)
		end
	end
	snap.counts = counts
	snap.money = guild and tonumber(guild.money) or 0
	snap.generation = (snap.generation or 0) + 1
end

function Adapter.RebuildCurrencies()
	local snap = Inv.snapshots.currencies
	if not snap then
		return
	end
	local char = CurrentCharacter()
	local counts = {}
	local money = 0
	if char then
		money = tonumber(char.money) or 0
		if type(char.currencies) == "table" then
			for id, n in pairs(char.currencies) do
				id = tonumber(id)
				n = tonumber(n) or 0
				if id and n > 0 then
					counts[id] = n
				end
			end
		end
	end
	snap.counts = counts
	snap.money = money
	snap.generation = (snap.generation or 0) + 1
end

function Adapter.RebuildWarbandCurrency()
	local snap = Inv.snapshots.currencies
	if not snap then
		return
	end
	local api = API()
	local war = api and api.GetWarband and api.GetWarband(1)
	snap.warbandMoney = war and tonumber(war.money) or 0
	snap.generation = (snap.generation or 0) + 1
end

function Adapter.RebuildAll()
	Adapter.RebuildBags()
	Adapter.RebuildBank()
	Adapter.RebuildWarband()
	Adapter.RebuildEquip()
	Adapter.RebuildMail()
	Adapter.RebuildVoid()
	Adapter.RebuildAuctions()
	Adapter.RebuildGuild()
	Adapter.RebuildCurrencies()
	Adapter.RebuildWarbandCurrency()
end

local function Request(token)
	Flux.Scheduler.Request("inventory", token)
end

local function FlushAuctions(tokens)
	auctionsPending = false
	if Inv.source ~= "syndicator" then return end
	if Adapter.RebuildAuctions() then tokens.auctions = true end
end

local function QueueAuctions()
	if Inv.source ~= "syndicator" or auctionsPending then return end
	auctionsPending = true
	-- Syndicator emits a callback for every row while rebuilding owned auctions.
	-- Read the final list once, before this bucket's existing inventory listeners.
	Flux.Scheduler.Request("inventory", "syndicatorAuctionRefresh", FlushAuctions)
end

local function FlushMail()
	local now = (GetTime and GetTime()) or 0
	if now < mailDue and C_Timer and C_Timer.After then
		C_Timer.After(mailDue - now, FlushMail)
		return
	end
	mailPending = false
	local changed = Adapter.RebuildMail()
	if inboxObservation then
		local char, name = CurrentCharacter()
		if char and char.mail == inboxObservation.mail and name == inboxObservation.character
			and Inv.source == "syndicator" and (inboxObservation.complete ~= nil or changed) then
			local snap = Inv.snapshots.mail
			local source = inboxObservation.complete and "syndicator" or nil
			if snap and snap.observedSource ~= source then
				snap.observedSource = source
				changed = true
			end
		end
		inboxObservation = nil
	end
	if changed then Request("mail") end
end

local function QueueMail()
	local now = (GetTime and GetTime()) or 0
	if not mailPending then mailFirst = now end
	mailDue = math.min(now + MAIL_DEBOUNCE, mailFirst + 0.6)
	if mailPending then return end
	mailPending = true
	if C_Timer and C_Timer.After then C_Timer.After(MAIL_DEBOUNCE, FlushMail) else FlushMail() end
end

local function OnMailboxUpdateBeforeBind()
	if not bound then inboxBeforeBind = true end
end

-- A ready provider can be selected after FluxUI's deferred startup. Tracking
-- from the first world entry distinguishes that case from an unobserved late load.
if GetFramesRegisteredForEvent and hooksecurefunc and GetInboxNumItems
	and Flux.Events and Flux.Events.Register then
	local ok, registered = pcall(Flux.Events.Register, "MAIL_INBOX_UPDATE", OnMailboxUpdateBeforeBind)
	watchingInboxHistory = ok and registered == true
	if watchingInboxHistory then
		pcall(Flux.Events.Register, "PLAYER_ENTERING_WORLD", function(_, firstLogin, reload)
			if firstLogin == true or reload == true then firstWorldObserved = true end
		end)
	end
end

local function IsMailboxCount(value)
	return type(value) == "number" and not (issecretvalue and issecretvalue(value))
		and value >= 0 and value < math.huge and value % 1 == 0
end

local function CountInboxAttachments(messages)
	local expected = 0
	for index = 1, messages do
		local _, _, _, _, _, _, daysLeft, attachments = GetInboxHeaderInfo(index)
		-- A loaded header with no items returns nil for the attachment count.
		-- Missing header data is not proof of an empty message.
		if type(daysLeft) ~= "number" or (issecretvalue and issecretvalue(daysLeft))
			or not (daysLeft > -math.huge and daysLeft < math.huge) then return end
		if attachments ~= nil then
			if not IsMailboxCount(attachments) then return end
			expected = expected + attachments
		end
	end
	return expected
end

local function ReadPublishedAttachments(rows)
	local count, counts = 0, {}
	for _, row in pairs(rows) do
		if type(row) == "table" and IsMailboxCount(row.itemID) and row.itemID > 0
			and IsMailboxCount(row.itemCount) and row.itemCount > 0 then
			if count then count = count + 1 end
			counts[row.itemID] = (counts[row.itemID] or 0) + row.itemCount
		else
			count = nil
		end
	end
	return count, counts
end

local function MailCountsChanged(before, after)
	if not before then return next(after) ~= nil end
	for itemID, count in pairs(after) do if before[itemID] ~= count then return true end end
	for itemID in pairs(before) do if after[itemID] == nil then return true end end
	return false
end

function Adapter.GetObservedMailCount(itemID, cached)
	if Inv.source ~= "syndicator" then return end
	local char, name = CurrentCharacter()
	if not char or not name then return end
	if not physicalMail then
		-- The warm list can also include expected auction deliveries. Offer it
		-- separately as pending stock, without claiming an observed attachment.
		if char.mail == observedMail and IsMailboxCount(cached) and cached > 0 then return nil, cached end
		return
	end
	if char.mail ~= physicalMail.mail or name ~= physicalMail.character then return end
	local count = physicalMail.counts[itemID]
	if count then return count end
	if physicalMail.complete and Inv.Mail and Inv.Mail.HasObservedInbox() then return 0 end
end

local function ObserveSyndicatorInbox(fromReady)
	if not fromReady and (not watchingInboxHistory or inboxBeforeBind) then return end
	local mixin = _G.SyndicatorMailCacheMixin
	if type(mixin) ~= "table" or type(mixin.ScanMail) ~= "function" or type(mixin.OnEvent) ~= "function"
		or not GetFramesRegisteredForEvent or not hooksecurefunc or not Inv.IsMailboxOpen
		or not GetInboxNumItems or not GetInboxHeaderInfo or not (Flux.Events and Flux.Events.Register) then return end

	local owner
	for _, frame in ipairs({ GetFramesRegisteredForEvent("MAIL_INBOX_UPDATE") }) do
		if not (frame.IsForbidden and frame:IsForbidden()) and frame.ScanMail == mixin.ScanMail
			and frame.GetScript and frame:GetScript("OnEvent") == mixin.OnEvent then
			if owner then return end
			owner = frame
		end
	end
	if not owner or owner:GetScript("OnUpdate") ~= nil then return end

	-- Only this instance uses the wrapped method. A callback is conclusive only
	-- when the same ScanMail invocation published it and returned successfully.
	-- An item-data callback delivered after ScanMail returns has no scan identity.
	local armed, closedWhileArmed, enabled
	local onComplete = function(frame)
		if not enabled or frame ~= owner then return end
		local scan = inboxScan
		inboxScan = nil
		-- ScanMail cannot publish deferred rows if its inbox loop aborted.
		-- Only a returned invocation can leave another publication pending.
		if scan and not scan.received then
			pendingInboxScans = pendingInboxScans + 1
		end
		if scan and scan.observation and not scan.multiple then
			local observation = scan.observation
			observation.complete = false
			if scan.messages ~= nil and scan.published ~= nil then
				-- The provider owns the item scan. Headers supply only the expected
				-- number of rows so skipped item slots cannot look like an empty inbox.
				local ok, expected = pcall(CountInboxAttachments, scan.messages)
				observation.complete = ok and expected == scan.published
			end
			inboxObservation = observation
			QueueMail()
		end
	end
	hooksecurefunc(owner, "ScanMail", onComplete)
	local scanMail = owner.ScanMail
	local onScript = function(frame, script, handler)
		if not enabled or frame ~= owner or script ~= "OnUpdate" or Inv.source ~= "syndicator" then return end
		if handler == scanMail then
			armed, closedWhileArmed, inboxScan, inboxObservation = true, nil, nil, nil
			local snap = Inv.snapshots.mail
			if snap and snap.observedSource == "syndicator" then
				snap.observedSource = nil
				Request("mail")
			end
		else
			local wasArmed, wasClosed = armed, closedWhileArmed
			armed, closedWhileArmed, inboxScan = nil, nil, nil
			-- ScanMail clears its own OnUpdate before it reads the inbox.
			if wasArmed and handler == nil then
				inboxScan = { character = frame.currentCharacter }
				if pendingInboxScans == 0 and not wasClosed and (fromReady or firstWorldObserved) and Inv.IsMailboxOpen() then
					local ok, n, total = pcall(GetInboxNumItems)
					if ok and IsMailboxCount(n) and IsMailboxCount(total) and n == total then
						inboxScan.messages = n
					end
				end
			end
		end
	end
	hooksecurefunc(owner, "SetScript", onScript)
	enabled = Flux.Events.Register("MAIL_CLOSED", function()
		closedWhileArmed = true
		if inboxScan then inboxScan.messages = nil end
	end) == true
end

-- At the bank every drag is a cache update. Light pulse next frame (counts,
-- overlays); scan-tier listeners run once the moves settle.
local bankMovePending
local function QueueBankMoveNotify(bags, bank)
	local pending = bankMovePending
	if not pending then
		pending = {}
		bankMovePending = pending
		Flux.Timer.After(0, function()
			bankMovePending = nil
			Inv.Notify({ tier = "light", bags = pending.bags, bank = pending.bank, settleAfter = true })
		end)
	end
	if bags then
		pending.bags = true
	end
	if bank then
		pending.bank = true
	end
end

local function Bind(fromReady)
	if bound then
		return
	end
	local syn = rawget(_G, "Syndicator")
	local cb = syn and syn.CallbackRegistry
	if not cb or not cb.RegisterCallback then
		return
	end
	local Sync, Store = Adapter.Sync, Inv.Store
	if Sync and Store and Store.GetSyncDB then
		local _, name = CurrentCharacter()
		Sync.Bind(Store.GetSyncDB(), rawget(_G, "SYNDICATOR_DATA"), syn.Constants, name)
	end
	bound = true
	Inv.source = "syndicator"
	if Inv.Store and Inv.Store.SetUsesSyndicator then
		Inv.Store.SetUsesSyndicator(true)
	end
	local snap = Inv.snapshots.mail
	if snap then snap.observedSource = nil end
	local char = CurrentCharacter()
	observedMail, physicalMail = char and char.mail, nil
	Adapter.RebuildAll()
	-- Optional hook errors must not interrupt the provider's inventory binding.
	pcall(ObserveSyndicatorInbox, fromReady)
	if watchingInboxHistory and Flux.Events.Unregister then
		pcall(Flux.Events.Unregister, "MAIL_INBOX_UPDATE", OnMailboxUpdateBeforeBind)
	end
	cb:RegisterCallback("BagCacheUpdate", function(_, character, updates)
		local _, currentName = CurrentCharacter()
		if character and currentName and character ~= currentName then
			return
		end
		updates = updates or {}
		local bagMap = updates.bags
		local bankMap = updates.bank
		local container = updates.containerBags or {}
		local bagsChanged = (bagMap and next(bagMap) ~= nil) or container.bags
		local bankChanged = (bankMap and next(bankMap) ~= nil) or container.bank
		if bagsChanged and Inv.NotifyBagStorm then
			-- Same batching signal the builtin path raises on BAG_UPDATE.
			Inv.NotifyBagStorm()
		end
		if bagsChanged then
			if container.bags or not (bagMap and next(bagMap)) then
				Adapter.RebuildBags()
			else
				Adapter.RebuildBags(bagMap)
			end
		end
		if bankChanged then
			if container.bank or not (bankMap and next(bankMap)) then
				Adapter.RebuildBank()
			else
				Adapter.RebuildBank(bankMap)
			end
		end
		if not (bagsChanged or bankChanged) then
			return
		end
		if Inv.IsBankOpen and Inv.IsBankOpen() then
			QueueBankMoveNotify(bagsChanged, bankChanged)
			return
		end
		if bagsChanged then
			Request("bags")
		end
		if bankChanged then
			Request("bank")
		end
	end)
	cb:RegisterCallback("EquippedCacheUpdate", function()
		Adapter.RebuildEquip()
		Request("equip")
	end)
	cb:RegisterCallback("WarbandBankCacheUpdate", function()
		Adapter.RebuildWarband()
		Request("warband")
	end)
	local function IsCurrentCharacter(character)
		if not character then
			return true
		end
		local _, currentName = CurrentCharacter()
		return not currentName or character == currentName
	end
	cb:RegisterCallback("MailCacheUpdate", function(_, character)
		local current, name = CurrentCharacter()
		if character and name and character ~= name then return end
		local inboxMail = current and current.mail
		-- The provider finishes an inbox scan by replacing its mail table.
		-- Auction receipts append to that table and cannot establish coverage.
		if character and character == name and type(inboxMail) == "table" and inboxMail ~= observedMail then
			local scan = inboxScan and inboxScan.character == name and inboxScan
			-- Apply opaque replacements to the older backlog first. A scan
			-- that started with a backlog cannot qualify either publication.
			if pendingInboxScans > 0 then
				pendingInboxScans = pendingInboxScans - 1
			elseif scan then
				scan.received = true
			end
			inboxObservation = { mail = inboxMail, character = name }
			local published, counts = ReadPublishedAttachments(inboxMail)
			local changed = MailCountsChanged(physicalMail and physicalMail.counts, counts)
			inboxObservation.counts, physicalMail = counts, inboxObservation
			if scan and scan.messages ~= nil then
				scan.multiple = scan.observation ~= nil
				scan.observation = inboxObservation
				scan.published = published
			end
			if changed then Request("mail") end
		end
		observedMail = inboxMail
		if Inv.NotifyBagStorm then
			Inv.NotifyBagStorm()
		end
		QueueMail()
	end)
	cb:RegisterCallback("VoidCacheUpdate", function(_, character)
		if not IsCurrentCharacter(character) then
			return
		end
		Adapter.RebuildVoid()
		Request("void")
	end)
	cb:RegisterCallback("AuctionsCacheUpdate", function(_, character)
		if not IsCurrentCharacter(character) then
			return
		end
		QueueAuctions()
	end)
	local cap = Flux.Cap
	if Flux.Events and Flux.Events.Register and cap
		and (cap.hasAuctionHouse or cap.hasLegacyAuctionHouse or cap.hasModernAuctionHouse) then
		-- A full owned-list refresh with zero rows emits no provider callback.
		-- Defer this fallback too, so provider event order cannot publish old data.
		local cons = Constants()
		local legacy = cons and cons.IsLegacyAH
		if legacy == nil then legacy = cap.hasLegacyAuctionHouse end
		Flux.Events.Register(legacy and "AUCTION_OWNED_LIST_UPDATE" or "OWNED_AUCTIONS_UPDATED", QueueAuctions)
	end
	cb:RegisterCallback("GuildCacheUpdate", function()
		Adapter.RebuildGuild()
		Request("guild")
	end)
	cb:RegisterCallback("CurrencyCacheUpdate", function(_, character)
		if not IsCurrentCharacter(character) then
			return
		end
		Adapter.RebuildCurrencies()
		Request("currencies")
	end)
	cb:RegisterCallback("WarbandCurrencyCacheUpdate", function()
		Adapter.RebuildWarbandCurrency()
		Request("currencies")
	end)
	Request("bags")
	Request("bank")
	Request("equip")
	Request("mail")
	Request("void")
	Request("auctions")
	Request("guild")
	Request("currencies")
	if Inv.HasWarband() then
		Request("warband")
	end
	Inv.ready = true
	if Flux.Startup then Flux.Startup.Mark("optional.Syndicator.ready_observed") end
end

function Adapter.Start()
	if waiting or bound then
		return
	end
	local syn = rawget(_G, "Syndicator")
	local api = syn and syn.API
	local cb = syn and syn.CallbackRegistry
	-- A late ADDON_LOADED can retry. Do not latch an absent provider forever.
	if not (api and cb and cb.RegisterCallback) then return false end
	waiting = true
	if api and api.IsReady and api.IsReady() then
		Bind()
		return
	end
	if cb and cb.RegisterCallback then
		cb:RegisterCallback("Ready", function()
			Bind(api and api.IsReady and api.IsReady() == false)
		end)
	end
	-- Live facts remain available while the companion builds its caches. Its
	-- Ready event owns the handoff; no three-second scan blackout or polling.
	if not Inv.source then
		if Inv.Builtin and Inv.Builtin.Start then
			if Inv.Store and Inv.Store.SetUsesSyndicator then
				Inv.Store.SetUsesSyndicator(false)
			end
			Inv.Builtin.Start()
			if Inv.Tooltip and Inv.Tooltip.Start then
				Inv.Tooltip.Start()
			end
		end
	end
end
