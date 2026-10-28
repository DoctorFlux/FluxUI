-- Inventory/Containers.lua — client bag / bank / warband / keyring IDs
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Cap = Flux.Cap
local Client = Flux.Client

local C = {}
Inv.Containers = C

local BACKPACK = (_G.BACKPACK_CONTAINER ~= nil) and _G.BACKPACK_CONTAINER or 0
local BANK_MAIN = (_G.BANK_CONTAINER ~= nil) and _G.BANK_CONTAINER or -1

local cachedCarried
local cachedCharBank
local cachedWarband
local carriedSet
local charBankSet
local warbandSet

local function Append(ids, seen, bagID)
	bagID = tonumber(bagID)
	if not bagID or seen[bagID] then
		return false
	end
	if Cap.IsBankTabSentinel and Cap.IsBankTabSentinel(bagID) then
		return false
	end
	ids[#ids + 1] = bagID
	seen[bagID] = true
	return true
end

local function HasReagentBag()
	if not Client.isRetail then
		return false
	end
	if (_G.NUM_REAGENTBAG_SLOTS or 0) > 0 then
		return true
	end
	return Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag ~= nil
end

local function ReagentBagID()
	if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
		return Enum.BagIndex.ReagentBag
	end
	return 5
end

local function NumWornBags()
	if Cap.GetMaxBagIndex then
		local n = Cap.GetMaxBagIndex()
		local reagent = HasReagentBag() and ReagentBagID() or nil
		if reagent and n == reagent then
			return n - 1
		end
		return n
	end
	return _G.NUM_BAG_SLOTS or 4
end

local function GetNumSlots(bag)
	return Flux.Container.GetNumSlots(bag) or 0
end

--- Worn bag count only (backpack extras). Never use Cap.GetMaxBagIndex: on
--- retail that can be 5 (reagent bag), which would shift classic bank bag IDs.
--- Classic BankFrame: first bank bag is NUM_BAG_SLOTS+1, and
--- ITEM_INVENTORY_BANK_BAG_OFFSET is 4. Cap worn bags so bag 5 stays a bank bag.
local function WornBagCount()
	local n = tonumber(_G.NUM_BAG_SLOTS) or 4
	if not HasReagentBag() then
		local offset = tonumber(_G.ITEM_INVENTORY_BANK_BAG_OFFSET) or 4
		if n > offset then
			n = offset
		end
	end
	return n
end

--- Era: 6 bank bags. Anniversary / other classic bags-in-bank: 7.
local function MaxBankBagSlots()
	local n = tonumber(_G.NUM_BANKBAGSLOTS)
	if type(n) == "number" and n > 0 then
		return n
	end
	if Client.isEra then
		return 6
	end
	return 7
end

function C.Invalidate()
	cachedCarried = nil
	cachedCharBank = nil
	cachedWarband = nil
	carriedSet = nil
	charBankSet = nil
	warbandSet = nil
end

local function SyndicatorConstants()
	local syn = rawget(_G, "Syndicator")
	return syn and syn.Constants
end

--- Same IDs Baganator Transfer / Syndicator cache use. Never Enum.BagIndex.BankBag_*.
function C.GetSyndicatorBankIndexes()
	local cons = SyndicatorConstants()
	local list = cons and cons.AllBankIndexes
	if type(list) == "table" and #list > 0 then
		return list
	end
	return nil
end

function C.GetSyndicatorWarbandIndexes()
	local cons = SyndicatorConstants()
	local list = cons and cons.AllWarbandIndexes
	if type(list) == "table" and #list > 0 then
		return list
	end
	return nil
end

function C.GetSyndicatorBagIndexes()
	local cons = SyndicatorConstants()
	local list = cons and cons.AllBagIndexes
	if type(list) == "table" and #list > 0 then
		return list
	end
	return nil
end

function C.IsLegacyBankLayout()
	-- Live War Within+: character bank is tabs 6–11. Bag -1 is the keyring.
	-- Era / anniversary BankFrame: BANK_CONTAINER (-1) + NUM_BAG_SLOTS+i (5–10/11).
	if Cap.HasUnifiedBankUI and Cap.HasUnifiedBankUI() then
		return false
	end
	if Cap.hasUnifiedBankUI and Enum and Enum.BagIndex and Enum.BagIndex.CharacterBankTab_1 then
		return false
	end
	return true
end

function C.GetBankMainContainerID()
	if not C.IsLegacyBankLayout() then
		return nil
	end
	if Enum and Enum.BagIndex and Enum.BagIndex.Bank ~= nil then
		return Enum.BagIndex.Bank
	end
	if _G.BANK_CONTAINER ~= nil then
		return _G.BANK_CONTAINER
	end
	return BANK_MAIN
end

--- Slot count for an open classic bank walk. GetContainerNumSlots(-1) can be 0
--- on the open tick while GetContainerItemInfo still answers 1..NUM_BANKGENERIC_SLOTS.
--- Do not use this for IsBankReadable: the fallback would look "open" while closed.
function C.GetOpenBankScanNumSlots(bag)
	bag = tonumber(bag)
	if not bag then
		return 0
	end
	local n = GetNumSlots(bag)
	if n > 0 then
		return n
	end
	if not C.IsLegacyBankLayout() then
		return 0
	end
	local main = C.GetBankMainContainerID()
	if main and bag == main then
		return tonumber(_G.NUM_BANKGENERIC_SLOTS) or 24
	end
	local numBags = tonumber(_G.NUM_BAG_SLOTS) or 4
	local maxBags = MaxBankBagSlots()
	if bag >= numBags + 1 and bag <= numBags + maxBags then
		return 36
	end
	return 0
end

--- Classic BankFrame walks NUM_BAG_SLOTS+1 .. NUM_BAG_SLOTS+NUM_BANKBAGSLOTS.
--- Enum.BagIndex.BankBag_* is retail-shifted (starts at 6) and skips bag 5.
local function BankBagSlotCount()
	local n = MaxBankBagSlots()
	if GetNumBankSlots then
		local purchased = GetNumBankSlots()
		if type(purchased) == "number" and purchased > n then
			n = purchased
		end
	end
	return n
end

--- Uncached. Syndicator formula: BANK_CONTAINER plus NUM_BAG_SLOTS+i.
--- Never Enum.BagIndex.BankBag_* (retail-shifted, skips classic bag 5).
function C.BuildLegacyBankContainerIDs()
	local ids, seen = {}, {}
	local syn = C.GetSyndicatorBankIndexes and C.GetSyndicatorBankIndexes()
	if syn then
		for i = 1, #syn do
			Append(ids, seen, syn[i])
		end
		return ids
	end
	local main = (Enum and Enum.BagIndex and Enum.BagIndex.Bank) or BANK_MAIN
	Append(ids, seen, main)
	local numBags = tonumber(_G.NUM_BAG_SLOTS) or 4
	local n = BankBagSlotCount()
	for i = 1, n do
		Append(ids, seen, numBags + i)
	end
	return ids
end

--- True while Blizzard will answer GetContainerItemInfo for bank containers.
function C.IsBankReadable()
	-- Classic retains bank/bank-bag capacities away from the banker. Require
	-- live access before interpreting those sizes as readable containers.
	if Inv.CanTakeFromBank and not Inv.CanTakeFromBank() then
		return false
	end
	local function readable(bag)
		bag = tonumber(bag)
		if not bag then
			return false
		end
		if C.IsKeyringBag and C.IsKeyringBag(bag) then
			return false
		end
		return GetNumSlots(bag) > 0
	end
	if C.IsLegacyBankLayout() then
		local ids = C.BuildLegacyBankContainerIDs()
		for i = 1, #ids do
			if readable(ids[i]) then
				return true
			end
		end
		return false
	end
	local ids = C.GetCharacterBankIDs()
	for i = 1, #ids do
		if readable(ids[i]) then
			return true
		end
	end
	local war = C.GetWarbandBankIDs()
	for i = 1, #war do
		if readable(war[i]) then
			return true
		end
	end
	return false
end

function C.GetCarriedBagIDs()
	if cachedCarried then
		return cachedCarried
	end
	local ids, seen = {}, {}
	Append(ids, seen, BACKPACK)
	for i = 1, WornBagCount() do
		Append(ids, seen, i)
	end
	if HasReagentBag() then
		local rid = ReagentBagID()
		if GetNumSlots(rid) > 0 then
			Append(ids, seen, rid)
		end
	end
	if Cap.hasKeyringContainer and Cap.keyringBagId then
		if GetNumSlots(Cap.keyringBagId) > 0 then
			Append(ids, seen, Cap.keyringBagId)
		end
	end
	cachedCarried = ids
	carriedSet = {}
	for i = 1, #ids do
		carriedSet[ids[i]] = true
	end
	return ids
end

--- Restock destinations: backpack + bags 1–4, plus the reagent bag on retail.
--- Never bag 5 on classic (that is the first bank bag). Never the keyring.
function C.GetPlayerRestockBagIDs()
	local ids, seen = {}, {}
	local syn = C.GetSyndicatorBagIndexes and C.GetSyndicatorBagIndexes()
	if syn then
		for i = 1, #syn do
			local bag = tonumber(syn[i])
			if bag and not C.IsKeyringBag(bag) then
				if HasReagentBag() then
					Append(ids, seen, bag)
				elseif bag == BACKPACK or (bag >= 1 and bag <= WornBagCount()) then
					Append(ids, seen, bag)
				end
			end
		end
	end
	if #ids == 0 then
		Append(ids, seen, BACKPACK)
		for i = 1, WornBagCount() do
			Append(ids, seen, i)
		end
		if HasReagentBag() then
			Append(ids, seen, ReagentBagID())
		end
	end
	return ids
end

local function FetchBankTabs(bankType)
	if not (C_Bank and C_Bank.FetchPurchasedBankTabIDs and Enum and Enum.BankType) then
		return nil
	end
	local ok, tabs = pcall(C_Bank.FetchPurchasedBankTabIDs, bankType)
	if ok and type(tabs) == "table" then
		return tabs
	end
	return nil
end

function C.GetCharacterBankIDs()
	if cachedCharBank then
		return cachedCharBank
	end
	local ids, seen = {}, {}
	local syn = C.GetSyndicatorBankIndexes and C.GetSyndicatorBankIndexes()
	if syn then
		for i = 1, #syn do
			Append(ids, seen, syn[i])
		end
	end
	if not C.IsLegacyBankLayout() then
		local tabs
		if Cap.EnumerateBankTabIDs then
			tabs = Cap.EnumerateBankTabIDs(Enum.BankType and Enum.BankType.Character)
		else
			tabs = FetchBankTabs(Enum.BankType and Enum.BankType.Character)
		end
		if tabs then
			for i = 1, #tabs do
				Append(ids, seen, tabs[i])
			end
		end
	elseif #ids == 0 then
		local built = C.BuildLegacyBankContainerIDs()
		for i = 1, #built do
			Append(ids, seen, built[i])
		end
	end
	cachedCharBank = ids
	charBankSet = {}
	for i = 1, #ids do
		charBankSet[ids[i]] = true
	end
	return ids
end

function C.GetWarbandBankIDs()
	if cachedWarband then
		return cachedWarband
	end
	local ids, seen = {}, {}
	if Cap.hasWarbandBank then
		local syn = C.GetSyndicatorWarbandIndexes and C.GetSyndicatorWarbandIndexes()
		if syn then
			for i = 1, #syn do
				Append(ids, seen, syn[i])
			end
		end
		local tabs
		if Cap.EnumerateBankTabIDs then
			tabs = Cap.EnumerateBankTabIDs(Enum.BankType and Enum.BankType.Account)
		else
			tabs = Enum.BankType and FetchBankTabs(Enum.BankType.Account)
		end
		if tabs then
			for i = 1, #tabs do
				Append(ids, seen, tabs[i])
			end
		end
	end
	cachedWarband = ids
	warbandSet = {}
	for i = 1, #ids do
		warbandSet[ids[i]] = true
	end
	return ids
end

function C.IsCarriedBag(bag)
	bag = tonumber(bag)
	if not bag then
		return false
	end
	C.GetCarriedBagIDs()
	return carriedSet and carriedSet[bag] and true or false
end

function C.IsCharacterBankContainer(bag)
	bag = tonumber(bag)
	if not bag then
		return false
	end
	C.GetCharacterBankIDs()
	return charBankSet and charBankSet[bag] and true or false
end

function C.IsWarbandBankContainer(bag)
	bag = tonumber(bag)
	if not bag then
		return false
	end
	C.GetWarbandBankIDs()
	return warbandSet and warbandSet[bag] and true or false
end

function C.IsBankContainer(bag)
	return C.IsCharacterBankContainer(bag) or C.IsWarbandBankContainer(bag)
end

function C.GetBankTypeForContainer(bag)
	bag = tonumber(bag)
	if not bag then
		return nil
	end
	if not (Enum and Enum.BankType) then
		return nil
	end
	if not (Cap.hasUnifiedBankUI or Cap.hasWarbandBank) then
		return nil
	end
	if C.IsWarbandBankContainer(bag) then
		return Enum.BankType.Account
	end
	if C.IsCharacterBankContainer(bag) then
		return Enum.BankType.Character
	end
	return nil
end

function C.GetKeyringBagID()
	if Cap and Cap.keyringBagId then
		return Cap.keyringBagId
	end
	if Enum and Enum.BagIndex and Enum.BagIndex.Keyring
		and not (Cap.IsBankTabSentinel and Cap.IsBankTabSentinel(Enum.BagIndex.Keyring)) then
		return Enum.BagIndex.Keyring
	end
	local kc = _G.KEYRING_CONTAINER
	if type(kc) == "number" and not (Cap.IsBankTabSentinel and Cap.IsBankTabSentinel(kc)) then
		return kc
	end
	-- Classic keyring is -2. Unified Forever/Retail keyring is Enum.BagIndex.Keyring (-1).
	if C.IsLegacyBankLayout() then
		return -2
	end
	return nil
end

function C.GetReagentBagID()
	if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
		return Enum.BagIndex.ReagentBag
	end
	if _G.REAGENTBAG_CONTAINER then
		return _G.REAGENTBAG_CONTAINER
	end
	if Client.isRetail then
		return 5
	end
	return nil
end

function C.IsKeyringBag(bag)
	bag = tonumber(bag)
	if not bag then
		return false
	end
	if Cap.IsBankTabSentinel and Cap.IsBankTabSentinel(bag) then
		return false
	end
	-- Classic BANK_CONTAINER is -1. Retail/Forever keyring is also -1. Never
	-- treat the classic main bank as a keyring.
	if C.IsLegacyBankLayout() then
		if bag == BANK_MAIN then
			return false
		end
		if Enum and Enum.BagIndex and Enum.BagIndex.Bank and bag == Enum.BagIndex.Bank then
			return false
		end
	end
	local keyring = C.GetKeyringBagID()
	return keyring ~= nil and bag == keyring
end

function C.IsReagentBag(bag)
	bag = tonumber(bag)
	if not bag then
		return false
	end
	local rid = C.GetReagentBagID()
	return rid ~= nil and bag == rid
end

function C.IsReagentBank(bag)
	bag = tonumber(bag)
	if not bag then
		return false
	end
	if Cap.IsReagentBankContainer then
		return Cap.IsReagentBankContainer(bag)
	end
	if Cap.IsBankTabSentinel and Cap.IsBankTabSentinel(bag) then
		return false
	end
	local reagent = Cap.GetReagentBankContainerID and Cap.GetReagentBankContainerID()
	if reagent == nil then
		reagent = rawget(_G, "REAGENTBANK_CONTAINER")
	end
	return type(reagent) == "number" and bag == reagent
end

--- Gear flyouts skip keyring, reagent bag, and reagent bank.
function C.SkipEquipCandidateBag(bag)
	return C.IsKeyringBag(bag) or C.IsReagentBag(bag) or C.IsReagentBank(bag)
end

--- itemID / stack count straight off the item location. These answer even when
--- the item's data is not cached yet, unlike GetContainerItemInfo, so a freshly
--- looted unknown item is never missing from the snapshot.
local function LocationItemIDAndCount(bag, slot)
	if not (C_Item and C_Item.DoesItemExist) then
		return nil, nil
	end
	local location = { bagID = bag, slotIndex = slot }
	local ok, exists = pcall(C_Item.DoesItemExist, location)
	if not ok or not exists then
		return nil, nil
	end
	local id
	if C_Item.GetItemID then
		local gotID, raw = pcall(C_Item.GetItemID, location)
		if gotID then
			id = tonumber(raw)
		end
	end
	if not id or id <= 0 then
		return nil, nil
	end
	local count
	if C_Item.GetStackCount then
		local gotCount, raw = pcall(C_Item.GetStackCount, location)
		if gotCount then
			count = tonumber(raw)
		end
	end
	return id, count
end

local function RecordFromInfo(bag, slot, info, empty, inv)
	if not info and not empty then
		local locID, locCount = LocationItemIDAndCount(bag, slot)
		if locID then
			if inv and inv.RequestItemData and C_Item and C_Item.IsItemDataCachedByID
				and not C_Item.IsItemDataCachedByID(locID) then
				inv.RequestItemData(locID, function()
					inv.NoteItemDataArrived(bag)
				end)
			end
			return { itemID = locID, count = (locCount and locCount > 0) and locCount or 1 }
		end
		return nil
	end
	if not info then
		return nil
	end
	local id = info.itemID
	if not id and info.hyperlink then
		id = tonumber(string.match(info.hyperlink, "item:(%d+)"))
	end
	id = tonumber(id)
	if (not id or id <= 0) and Flux.Secrets and Flux.Secrets.SafeGetNumber then
		id = Flux.Secrets.SafeGetNumber(info.itemID, 0)
	end
	if not id or id <= 0 then
		return nil
	end
	local count = tonumber(info.stackCount) or tonumber(info.count)
	if (not count or count <= 0) and Flux.Secrets and Flux.Secrets.SafeGetNumber then
		count = Flux.Secrets.SafeGetNumber(info.stackCount, 0)
		if not count or count <= 0 then
			count = Flux.Secrets.SafeGetNumber(info.count, 0)
		end
	end
	return {
		itemID = id,
		count = (count and count > 0) and count or 1,
		link = info.hyperlink,
	}
end

--- One slot, or nil when it is empty.
function C.ReadSlot(bag, slot)
	local info, empty = Flux.Container.GetItemInfo(bag, slot)
	return RecordFromInfo(bag, slot, info, empty, Flux.Inventory)
end

--- Write `slotSet` into an existing slot table and diff just those slots.
function C.PatchSlots(slots, bag, slotSet, touched, delta)
	slots = slots or {}
	for slot in pairs(slotSet) do
		local old = slots[slot]
		local new = C.ReadSlot(bag, slot)
		if old then
			local id = old.itemID
			if not new or new.itemID ~= id or new.count ~= old.count or new.link ~= old.link then
				touched[id] = true
			end
			delta[id] = (delta[id] or 0) - (old.count or 1)
		end
		if new then
			local id = new.itemID
			if not old or old.itemID ~= id or old.count ~= new.count or old.link ~= new.link then
				touched[id] = true
			end
			delta[id] = (delta[id] or 0) + (new.count or 1)
			slots[slot] = new
		else
			slots[slot] = nil
		end
	end
	return slots
end

--- Scan one container into { [slot] = { itemID, count, link } }.
function C.ScanBag(bag)
	local bySlot = {}
	local n = GetNumSlots(bag)
	if n <= 0 then
		local inv = Flux.Inventory
		if inv and inv.IsBankOpen and inv.IsBankOpen() and C.IsBankContainer(bag) then
			n = C.GetOpenBankScanNumSlots(bag)
		end
	end
	if n <= 0 then
		return bySlot
	end
	for slot = 1, n do
		local rec = C.ReadSlot(bag, slot)
		if rec then
			bySlot[slot] = rec
		end
	end
	return bySlot
end

function C.CountsFromByBag(byBag)
	local counts = {}
	for _, slots in pairs(byBag) do
		for _, rec in pairs(slots) do
			local id = tonumber(rec.itemID)
			if id then
				counts[id] = (counts[id] or 0) + (rec.count or 1)
			end
		end
	end
	return counts
end

-- Per-move item sets ---------------------------------------------------------
-- touched: item IDs whose slot record changed (moved, restacked, relinked).
-- changed: touched IDs whose region total moved. Listeners that only care about
-- a few items skip a pulse when none of theirs are in it.

local function SameRecord(a, b)
	return a.itemID == b.itemID and a.count == b.count and a.link == b.link
end

--- Diff one bag's old and new slot records into `touched`, and add new minus
--- old count per item ID into `delta`.
function C.DiffSlots(oldSlots, newSlots, touched, delta)
	if type(oldSlots) == "table" then
		for slot, rec in pairs(oldSlots) do
			local id = rec.itemID
			local new = type(newSlots) == "table" and newSlots[slot]
			if not new or not SameRecord(rec, new) then
				touched[id] = true
			end
			delta[id] = (delta[id] or 0) - (rec.count or 1)
		end
	end
	if type(newSlots) == "table" then
		for slot, rec in pairs(newSlots) do
			local id = rec.itemID
			local old = type(oldSlots) == "table" and oldSlots[slot]
			if not old or not SameRecord(rec, old) then
				touched[id] = true
			end
			delta[id] = (delta[id] or 0) + (rec.count or 1)
		end
	end
end

function C.ChangedFromDelta(delta)
	local changed = {}
	for id, d in pairs(delta) do
		if d ~= 0 then
			changed[id] = true
		end
	end
	return changed
end

local function UnionInto(into, src)
	if not into then
		return src
	end
	for id in pairs(src) do
		into[id] = true
	end
	return into
end

--- Sets accumulate across refreshes until a Notify takes them, so two scans
--- before one pulse still report both moves. A full rescan makes them unknown.
function C.NewItemSetLog()
	return { any = false, known = true }
end

--- touched == nil records a full rescan.
function C.NoteItemSets(log, touched, changed)
	log.any = true
	if not touched then
		log.known = false
		log.touched, log.changed = nil, nil
		return
	end
	if not log.known then
		return
	end
	log.touched = UnionInto(log.touched, touched)
	log.changed = UnionInto(log.changed, changed or {})
end

--- @return table|nil touched, table|nil changed  (nil = unknown, do full work)
function C.TakeItemSets(log)
	local known = log.any and log.known
	local touched, changed = log.touched, log.changed
	log.any, log.known, log.touched, log.changed = false, true, nil, nil
	if not known then
		return nil, nil
	end
	return touched or {}, changed or {}
end
