-- Inventory/Syndicator/Adapter.lua — Syndicator facts → same snapshots as builtin
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Adapter = Inv.Syndicator

local bound = false
local waiting = false
local lastMailFingerprint
local mailDebounceGen = 0
local MAIL_DEBOUNCE = 0.2

-- Last rebuild classification per region, so Syndicator and builtin hand
-- listeners the same ctx (changeKind / added / removed / dirtyBags).
local bagsChange = { kind = "none", added = nil, removed = nil, dirty = {} }
local bankChange = { kind = "none", added = nil, removed = nil, dirty = {} }
local keyBuf = {}
local C = Inv.Containers
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

local function FillFromSlots(bagID, slotArray, byBag, counts)
	local dest = {}
	byBag[bagID] = dest
	if type(slotArray) ~= "table" then
		return
	end
	for slot, rec in pairs(slotArray) do
		local id = rec and NumericItemID(rec.itemID)
		if id then
			local n = tonumber(rec.itemCount or rec.count) or 1
			dest[slot] = { itemID = id, count = n, link = rec.itemLink or rec.link }
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

local function SubtractBagCounts(byBag, bagID, counts)
	local dest = byBag[bagID]
	if not dest then
		return
	end
	for _, rec in pairs(dest) do
		local id = rec and NumericItemID(rec.itemID)
		if id then
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
local function NoteDirty(change, dirtyBags, ids)
	Wipe(change.dirty)
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

local function Classify(change, snap, beforeKeys)
	change.kind, change.added, change.removed = Inv.ClassifyCountKeys(beforeKeys, snap.counts)
end

function Adapter.RebuildBags(dirtyBags)
	local char = CurrentCharacter()
	local cons = Constants()
	local snap = Inv.snapshots.bags
	local doFull = not dirtyBags or not next(dirtyBags) or not next(snap.byBag)
	Inv.SnapshotCountKeys(snap.counts, keyBuf)
	if doFull then
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
		NoteDirty(bagsChange, dirtyBags, cons and cons.AllBagIndexes)
		Classify(bagsChange, snap, keyBuf)
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
	local touched, delta = {}, {}
	for bagID in pairs(dirtyBags) do
		local old = snap.byBag[bagID]
		SubtractBagCounts(snap.byBag, bagID, counts)
		local i = indexByBag[bagID]
		FillFromSlots(bagID, bags and i and bags[i], snap.byBag, counts)
		C.DiffSlots(old, snap.byBag[bagID], touched, delta)
	end
	snap.generation = (snap.generation or 0) + 1
	NoteDirty(bagsChange, dirtyBags, nil)
	Classify(bagsChange, snap, keyBuf)
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
	Inv.SnapshotCountKeys(snap.counts, keyBuf)
	if doFull then
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
	local touched, delta = {}, {}
	for bagID in pairs(dirtyBags) do
		local old = snap.byBag[bagID]
		SubtractBagCounts(snap.byBag, bagID, counts)
		local i = indexByBag[bagID]
		FillFromSlots(bagID, CharacterBankSlotArray(char, cons, i), snap.byBag, counts)
		C.DiffSlots(old, snap.byBag[bagID], touched, delta)
	end
	snap.generation = (snap.generation or 0) + 1
	NoteDirty(bankChange, dirtyBags, nil)
	Classify(bankChange, snap, keyBuf)
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

local function FillFromList(slotArray, snap)
	if not snap then
		return
	end
	if not snap.byIndex then
		snap.byIndex = {}
	end
	Wipe(snap.byIndex)
	local counts = {}
	if type(slotArray) == "table" then
		for index, rec in pairs(slotArray) do
			local id = rec and NumericItemID(rec.itemID)
			if id then
				local n = tonumber(rec.itemCount or rec.count) or 1
				snap.byIndex[index] = {
					itemID = id,
					count = n,
					link = rec.itemLink or rec.link,
				}
				counts[id] = (counts[id] or 0) + n
			end
		end
	end
	snap.counts = counts
	snap.generation = (snap.generation or 0) + 1
end

local function MailListFingerprint(slotArray)
	if type(slotArray) ~= "table" then
		return ""
	end
	local parts = {}
	for index, rec in pairs(slotArray) do
		local id = rec and NumericItemID(rec.itemID)
		if id then
			local n = tonumber(rec.itemCount or rec.count) or 1
			parts[#parts + 1] = tostring(index) .. "=" .. id .. ":" .. n
		end
	end
	table.sort(parts)
	return table.concat(parts, ";")
end

--- Returns true when the live mail snapshot actually changed.
function Adapter.RebuildMail()
	local char = CurrentCharacter()
	local mail = char and char.mail
	local fp = MailListFingerprint(mail)
	if fp == lastMailFingerprint then
		return false
	end
	lastMailFingerprint = fp
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
	FillFromList(char and char.auctions, Inv.snapshots.auctions)
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

local function Bind()
	if bound then
		return
	end
	if Inv.source == "builtin" then
		return
	end
	local syn = rawget(_G, "Syndicator")
	local cb = syn and syn.CallbackRegistry
	if not cb or not cb.RegisterCallback then
		return
	end
	bound = true
	Inv.source = "syndicator"
	if Inv.Store and Inv.Store.SetUsesSyndicator then
		Inv.Store.SetUsesSyndicator(true)
	end
	Adapter.RebuildAll()
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
		if not IsCurrentCharacter(character) then
			return
		end
		if Inv.NotifyBagStorm then
			Inv.NotifyBagStorm()
		end
		mailDebounceGen = mailDebounceGen + 1
		local gen = mailDebounceGen
		local function flushMail()
			if gen ~= mailDebounceGen then
				return
			end
			if Adapter.RebuildMail() then
				Request("mail")
			end
		end
		if C_Timer and C_Timer.After then
			C_Timer.After(MAIL_DEBOUNCE, flushMail)
		else
			flushMail()
		end
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
		Adapter.RebuildAuctions()
		Request("auctions")
	end)
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
end

function Adapter.Start()
	if waiting or bound then
		return
	end
	waiting = true
	local syn = rawget(_G, "Syndicator")
	local api = syn and syn.API
	local cb = syn and syn.CallbackRegistry
	if api and api.IsReady and api.IsReady() then
		Bind()
		return
	end
	if cb and cb.RegisterCallback then
		cb:RegisterCallback("Ready", function()
			Bind()
		end)
	end
	Flux.Events.Register("PLAYER_ENTERING_WORLD", function()
		if bound or Inv.source then
			return
		end
		if api and api.IsReady and api.IsReady() then
			Bind()
		end
	end)
	Flux.Timer.After(3, function()
		if Inv.source then
			return
		end
		if api and api.IsReady and api.IsReady() then
			Bind()
			return
		end
		if Inv.Builtin and Inv.Builtin.Start then
			if Inv.Store and Inv.Store.SetUsesSyndicator then
				Inv.Store.SetUsesSyndicator(false)
			end
			Inv.Builtin.Start()
			if Inv.Tooltip and Inv.Tooltip.Start then
				Inv.Tooltip.Start()
			end
		end
	end)
end
