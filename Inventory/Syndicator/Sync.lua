-- Provider transitions only. While delegated, the saved mirror IS Syndicator's
-- live root: cache updates (including alts/deletions) need no extra callbacks.
local _, ns = ...
local Inv = ns.Flux.Inventory
local Sync = {}
Inv.Syndicator.Sync = Sync

local prepared = setmetatable({}, { __mode = "k" })
local attachedDB, attachedData
local characterFields = { "bags", "bank", "equipped", "mail", "auctions", "void", "currencies", "money" }

local function Copy(value)
	if type(value) ~= "table" then return value end
	local out = {}
	for key, entry in pairs(value) do out[key] = Copy(entry) end
	return out
end

local function Equal(a, b)
	if a == b then return true end
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	for key, value in pairs(a) do if not Equal(value, b[key]) then return false end end
	for key in pairs(b) do if a[key] == nil then return false end end
	return true
end

local function Slots(rows, offset, metadata)
	if type(rows) ~= "table" then return nil end
	local out = {}
	for slot, row in pairs(rows) do
		if type(slot) == "number" and type(row) == "table" and row.itemID then
			local value = metadata and Copy(row) or {}
			value.itemID, value.count, value.link = row.itemID, row.itemCount or row.count or 1, row.itemLink or row.link
			value.itemCount, value.itemLink = nil, nil
			out[slot - (offset or 0)] = value
		end
	end
	return out
end

local function Containers(rows, indexes, tabs)
	if type(rows) ~= "table" then return nil end
	local out = {}
	for index, bag in ipairs(indexes or {}) do
		local row = rows[index]
		if row then out[bag] = Slots(tabs and row.slots or row) end
	end
	return out
end

local function Field(record, field, constants, kind)
	if not record then return nil end
	if field == "bags" then return Containers(record.bags, constants.AllBagIndexes) end
	if field == "bank" then
		if kind == "Warband" then return Containers(record.bank, constants.AllWarbandIndexes, true) end
		if kind == "Guilds" then
			local out = {}
			for tab, row in pairs(record.bank or {}) do out[tab] = Slots(row.slots or row) end
			return out
		end
		return Containers(constants.CharacterBankTabsActive and record.bankTabs or record.bank,
			constants.AllBankIndexes, constants.CharacterBankTabsActive)
	end
	if field == "equipped" then return Slots(record.equipped, constants.EquippedInventorySlotOffset or 1) end
	if field == "mail" or field == "auctions" then return Slots(record[field], nil, true) end
	if field == "void" then
		if type(record.void) ~= "table" then return nil end
		local out = {}
		for page, rows in pairs(record.void) do out[page] = Slots(rows) end
		return out
	end
	return record[field]
end

local function Normalize(record, constants, kind)
	local out = {}
	local mapped = { bags = true, bank = true, bankTabs = true, equipped = true, mail = true, auctions = true, void = true, currencies = true, money = true }
	for key, value in pairs(record) do if not mapped[key] then out[key] = Copy(value) end end
	out.money = record.money
	out.currencies = Copy(record.currencies)
	if kind == "Characters" then
		for _, field in ipairs(characterFields) do
			if field ~= "money" and field ~= "currencies" then out[field] = Field(record, field, constants, kind) end
		end
	elseif kind == "Warband" then
		out.bank = Containers(record.bank, constants.AllWarbandIndexes, true) or {}
	else
		-- Guild records already use the same tab/slot schema as the built-in.
		out.bank = Copy(record.bank or {})
	end
	return out
end

local function Valid(data, constants)
	return type(data) == "table" and data.Version == 2 and type(data.Characters) == "table"
		and type(data.Guilds) == "table" and type(data.Warband) == "table"
		and type(constants) == "table" and type(constants.AllBagIndexes) == "table"
		and type(constants.AllBankIndexes) == "table" and type(constants.AllWarbandIndexes) == "table"
end

-- Import once after an external-provider session, before live tables are bound.
-- Subsequent standalone reloads retain their own changes and the frozen ancestor.
function Sync.Restore(db)
	if prepared[db] then return end
	prepared[db] = true
	local state = db.SyndicatorSync
	if not (state and state.Version == 1 and state.active and Valid(state.data, state.constants)) then return end
	for _, kind in ipairs({ "Characters", "Guilds", "Warband" }) do
		local records = {}
		for name, record in pairs(state.data[kind]) do records[name] = Normalize(record, state.constants, kind) end
		db[kind] = records
	end
	db.Pending = { Characters = {}, Guilds = {}, Warband = true }
	for name in pairs(db.Characters) do db.Pending.Characters[name] = 1 end
	for name in pairs(db.Guilds) do db.Pending.Guilds[name] = true end
	db.Summaries = { Characters = { ByRealm = {} }, Guilds = { ByRealm = {} }, Warband = { Summary = {}, Pending = true } }
	state.active = false
	state.capacities = {}
end

-- Capture the capacity the existing scanner already read; no extra native query.
function Sync.NoteCapacity(bag, capacity)
	if Inv.source ~= "builtin" or capacity < 0 then return end
	local db = rawget(_G, "FluxUIInventoryDB")
	local name = Inv.Store.GetCurrentCharacterName()
	if not db or not name then return end
	local state = db.SyndicatorSync
	if state and state.Version ~= 1 then return end
	if not state then state = { Version = 1 }; db.SyndicatorSync = state end
	state.capacities = state.capacities or {}
	local sizes = state.capacities[name]
	if not sizes then sizes = {}; state.capacities[name] = sizes end
	sizes[bag] = capacity
end

local function ShouldPush(localValue, base, remote)
	if localValue == nil then return false end
	if base == nil then return remote == nil end
	return not Equal(localValue, base) and Equal(remote, base)
end

local function ExportSlots(rows, old, capacity, offset, metadata)
	local out, last = {}, capacity or (old and #old or 0)
	for slot in pairs(rows or {}) do if type(slot) == "number" then last = math.max(last, slot + (offset or 0)) end end
	-- Equipment starts at offset, containers at one. Dense empty records retain
	-- the external consumer's capacity contract, including a now-empty last slot.
	for slot = 1, last do out[slot] = {} end
	for slot, row in pairs(rows or {}) do
		local target = slot + (offset or 0)
		local prior = old and old[target]
		local same = prior and prior.itemID == row.itemID and (prior.itemLink or prior.link) == (row.link or row.itemLink)
		local value = metadata and Copy(row) or (same and Copy(prior) or Copy(row))
		value.itemID, value.itemCount = row.itemID, row.count or row.itemCount or 1
		value.itemLink = row.link or row.itemLink
		-- A cold native record must not erase a known link for this same item.
		if not value.itemLink and prior and prior.itemID == row.itemID and prior.itemLink
			and prior.itemLink:find("|Hitem:", 1, true) then value.itemLink = prior.itemLink end
		-- Native mail deliberately stores ID/count without requesting item links.
		-- Syndicator summaries require a full hyperlink; a minimal ordinary-item
		-- link preserves that known identity without inventing pet/variant data.
		if not value.itemLink then value.itemLink = "|Hitem:" .. row.itemID .. "|h[]|h" end
		value.count, value.link = nil, nil
		out[target] = value
	end
	return out
end

local function MarkSummary(kind, name)
	local summaries = rawget(_G, "SYNDICATOR_SUMMARIES")
	local section = summaries and summaries.Version == 5 and summaries[kind]
	if section and type(section.Pending) == "table" then section.Pending[name] = kind == "Characters" and 1 or true end
end

local function RawContainer(record, field, bag, constants, kind)
	if not record then return nil end
	if kind == "Guilds" or field == "void" then return record[field] and record[field][bag] end
	local indexes = field == "bags" and constants.AllBagIndexes
		or (kind == "Warband" and constants.AllWarbandIndexes or constants.AllBankIndexes)
	local key = field == "bank" and kind == "Characters" and constants.CharacterBankTabsActive and "bankTabs" or field
	for index, id in ipairs(indexes) do if id == bag then return record[key] and record[key][index] end end
end

local function ContainerSize(record, field, bag, constants, kind)
	local value = RawContainer(record, field, bag, constants, kind)
	return value and #(value.slots or value) or nil
end

local function TabMetadataChanged(localTab, baseTab)
	for key, value in pairs(localTab or {}) do
		if key ~= "slots" and not Equal(value, baseTab and baseTab[key]) then return true end
	end
	return false
end

local function ExportContainer(record, field, bag, rows, constants, kind, sizes, localRecord, baseRecord)
	local indexes, tabs, key
	if field == "void" then
		indexes, key = nil, "void"
	elseif field == "bags" then
		indexes, key = constants.AllBagIndexes, "bags"
	elseif kind == "Warband" then
		indexes, tabs, key = constants.AllWarbandIndexes, true, "bank"
	elseif kind == "Guilds" then
		indexes, tabs, key = nil, true, "bank"
	else
		indexes, tabs = constants.AllBankIndexes, constants.CharacterBankTabsActive
		key = tabs and "bankTabs" or "bank"
	end
	local index = bag
	if indexes then
		index = nil
		for i, id in ipairs(indexes) do if id == bag then index = i; break end end
		if not index then return false end
	end
	record[key] = record[key] or {}
	local old = record[key][index]
	local capacity = field ~= "void" and sizes and sizes[bag] or nil
	-- Unpurchased native bank IDs appear as empty sparse maps too. An absent
	-- tab needs positive capacity or items; do not manufacture phantom tabs.
	if not old and tabs and kind ~= "Guilds" and not next(rows) and not (capacity and capacity > 0) then return false end
	if tabs then
		local tab = old or { name = "", iconTexture = 134400, depositFlags = 0 }
		if kind == "Guilds" then
			local before = baseRecord and baseRecord.bank and baseRecord.bank[bag]
			for name, value in pairs(localRecord.bank[bag] or {}) do
				if name ~= "slots" and ShouldPush(value, before and before[name], old and old[name]) then tab[name] = Copy(value) end
			end
		end
		tab.slots = ExportSlots(rows, old and old.slots, capacity)
		record[key][index] = tab
	else
		record[key][index] = ExportSlots(rows, old, capacity)
	end
	return true
end

local function Merge(record, localRecord, baseRecord, constants, oldConstants, kind, name, currentName, sizes)
	local changed = false
	local fields = kind == "Characters" and characterFields or { "bank", "money" }
	for _, field in ipairs(fields) do
		-- Current cash/tokens are already native observations before Ready.
		if not (kind == "Characters" and name == currentName and (field == "money" or field == "currencies")) then
			local base = baseRecord and Field(baseRecord, field, oldConstants, kind)
			local value = localRecord[field]
			if kind == "Guilds" and field == "bank" then value = Field(localRecord, field, constants, kind) end
			local remote
			if field == "bags" or field == "bank" or field == "void" then
				for bag, rows in pairs(value or {}) do
					local before = base and base[bag]
					local capacity = field ~= "void" and sizes and sizes[bag] or nil
					local oldSize = ContainerSize(baseRecord, field, bag, oldConstants, kind)
					local resized = capacity ~= nil and capacity ~= oldSize
					local metadataChanged = kind == "Guilds" and TabMetadataChanged(localRecord.bank[bag], baseRecord and baseRecord.bank and baseRecord.bank[bag])
					if resized or metadataChanged or not Equal(rows, before) then
						remote = remote or Field(record, field, constants, kind) or {}
						if (ShouldPush(rows, before, remote[bag]) or ((resized or metadataChanged) and Equal(remote[bag], before)))
							and ContainerSize(record, field, bag, constants, kind) == oldSize then
							changed = ExportContainer(record, field, bag, rows, constants, kind, sizes, localRecord, baseRecord) or changed
						end
					end
				end
			elseif not Equal(value, base) and ShouldPush(value, base, Field(record, field, constants, kind)) then
				if field == "equipped" or field == "mail" or field == "auctions" then
					record[field] = ExportSlots(value, record[field], field ~= "equipped" and 0 or nil,
						field == "equipped" and (constants.EquippedInventorySlotOffset or 1) or nil, field ~= "equipped")
				else record[field] = Copy(value) end
				changed = true
			end
		end
	end
	-- Keep native class identity and provider-only metadata. Only shared user
	-- visibility/guild fields participate in the existing-record detail merge.
	for _, field in ipairs({ "show", "guild" }) do
		local value = localRecord.details and localRecord.details[field]
		local base = baseRecord and baseRecord.details and baseRecord.details[field]
		local remote = record.details and record.details[field]
		if ShouldPush(value, base, remote) then record.details = record.details or {}; record.details[field] = Copy(value); changed = true end
	end
	if changed then MarkSummary(kind, name) end
	return changed
end

local function NotifyTransition(characters, warbands, constants, currentName)
	local syn = rawget(_G, "Syndicator")
	local cb = syn and syn.CallbackRegistry
	if not (cb and cb.TriggerEvent) then return end
	for name in pairs(characters) do
		if name == currentName then
			-- Baganator interprets a bag callback's character as the live player.
			-- Never broadcast an alt as a live-character bag update.
			cb:TriggerEvent("BagCacheUpdate", name, { bags = {}, bank = {}, containerBags = { bags = true, bank = true } })
			cb:TriggerEvent("EquippedCacheUpdate", name)
			cb:TriggerEvent("CurrencyCacheUpdate", name)
		end
		-- Also invalidates Syndicator's cached account search for mail/auctions
		-- and alt updates; it does not select a new live character in Baganator.
		cb:TriggerEvent("MailCacheUpdate", name)
	end
	for index in pairs(warbands) do
		local bags = {}
		for _, bag in ipairs(constants.AllWarbandIndexes) do bags[bag] = true end
		cb:TriggerEvent("WarbandBankCacheUpdate", index, { bags = bags, tabInfo = true })
		cb:TriggerEvent("WarbandCurrencyCacheUpdate", index)
	end
end

-- Exact three-way comparison: unchanged remote + changed local means local is
-- newer. Independent remote edits win when chronology cannot be established.
-- No clocks, hashes, per-event copies, timers, polling, or callback echo loops.
function Sync.Bind(db, data, constants, currentName)
	if attachedDB == db and attachedData == data then return true end
	if not Valid(data, constants) then return false end
	Sync.Restore(db)
	local state = db.SyndicatorSync
	if state and state.Version ~= 1 then return false end
	local baseline = state and state.Version == 1 and Valid(state.data, state.constants) and state.data
	local characters, warbands = {}, {}
	for _, kind in ipairs({ "Characters", "Guilds", "Warband" }) do
		for name, localRecord in pairs(db[kind] or {}) do
			local record = data[kind][name]
			local base = baseline and baseline[kind][name]
			local oldConstants = baseline and state.constants or constants
			-- A missing formerly-known remote entity was deleted: never resurrect it.
			if record or not base then
				if not record then
					record = { details = Copy(localRecord.details or {}), money = 0 }
					if kind == "Characters" then
						for _, field in ipairs({ "bags", "bank", "bankTabs", "containerInfo", "equipped", "mail", "void", "auctions", "currencies", "currencyByHeader" }) do record[field] = {} end
						if type(record.details.class) ~= "number" then record.details.class = nil end
					end
					data[kind][name] = record
					-- Missing entities have no known data; merge into a blank ancestor.
					base = Copy(record)
					oldConstants = constants
					MarkSummary(kind, name)
					if kind == "Characters" then characters[name] = true elseif kind == "Warband" then warbands[name] = true end
				end
				local sizes = state and state.capacities and state.capacities[kind == "Warband" and currentName or name]
				if Merge(record, localRecord, base, constants, oldConstants, kind, name, currentName, sizes) then
					if kind == "Characters" then characters[name] = true elseif kind == "Warband" then warbands[name] = true end
				end
			end
		end
	end
	db.SyndicatorSync = { Version = 1, data = data, constants = {
		AllBagIndexes = Copy(constants.AllBagIndexes), AllBankIndexes = Copy(constants.AllBankIndexes),
		AllWarbandIndexes = Copy(constants.AllWarbandIndexes), CharacterBankTabsActive = constants.CharacterBankTabsActive,
		EquippedInventorySlotOffset = constants.EquippedInventorySlotOffset,
	}, active = true }
	attachedDB, attachedData = db, data
	NotifyTransition(characters, warbands, constants, currentName)
	return true
end
