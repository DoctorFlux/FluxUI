-- Inventory/Index.lua — snapshot + live counts / find
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory

local Index = {}
Inv.Index = Index

local EMPTY_OPTS = {}

local function ReadOpts(opts)
	opts = opts or EMPTY_OPTS
	-- Bags-only unless the caller opts into bank / warband / equipped
	-- (same default as GetUniqueItems). includeBank remains a legacy alias.
	local bags = opts.bags ~= false
	local bank = opts.bank == true
	local warband = opts.warband == true
	local equipped = opts.equipped == true
	local mail = opts.mail == true
	local void = opts.void == true
	local auctions = opts.auctions == true
	local guild = opts.guild == true
	if opts.includeBank == false then
		bank = false
		warband = false
	elseif opts.includeBank == true then
		bank = true
	end
	if not Inv.HasWarband() then
		warband = false
	end
	return bags, bank, warband, equipped, mail, void, auctions, guild, opts.charges
end

local function SnapCount(region, itemID)
	local snap = Inv.snapshots[region]
	if not snap or not snap.counts then
		return 0
	end
	return snap.counts[itemID] or 0
end

local function CountFromFlags(itemID, bags, bank, warband, equipped, mail, void, auctions, guild)
	local n = 0
	if bags then
		n = n + SnapCount("bags", itemID)
	end
	if bank then
		n = n + SnapCount("bank", itemID)
	end
	if warband then
		n = n + SnapCount("warband", itemID)
	end
	if equipped then
		n = n + SnapCount("equip", itemID)
	end
	if mail then
		n = n + SnapCount("mail", itemID)
	end
	if void then
		n = n + SnapCount("void", itemID)
	end
	if auctions then
		n = n + SnapCount("auctions", itemID)
	end
	if guild then
		n = n + SnapCount("guild", itemID)
	end
	return n
end

function Index.GetCount(itemID, opts)
	itemID = tonumber(itemID)
	if not itemID then
		return 0
	end
	local bags, bank, warband, equipped, mail, void, auctions, guild = ReadOpts(opts)
	local n = 0
	if bags then
		n = n + SnapCount("bags", itemID)
	end
	if bank then
		n = n + SnapCount("bank", itemID)
	end
	if warband then
		n = n + SnapCount("warband", itemID)
	end
	if equipped then
		n = n + SnapCount("equip", itemID)
	end
	if mail then
		n = n + SnapCount("mail", itemID)
	end
	if void then
		n = n + SnapCount("void", itemID)
	end
	if auctions then
		n = n + SnapCount("auctions", itemID)
	end
	if guild then
		n = n + SnapCount("guild", itemID)
	end
	return n
end

local canonicalGetCount = Index.GetCount

local function asCount(n)
	local num = tonumber(n)
	if num then
		return num
	end
	if Flux.Secrets and Flux.Secrets.SafeGetNumber then
		return Flux.Secrets.SafeGetNumber(n, 0)
	end
	return 0
end

local function OwnedCarriedIndexGetLiveCount(itemID, opts)
	itemID = tonumber(itemID)
	if not itemID then
		return 0
	end
	local bags, bank, warband, equipped, mail, void, auctions, guild, charges = ReadOpts(opts)
	local includeCharges = not (opts and opts.charges == false)
	local includeBank = bank or warband
	-- Select the public getter after both original charge-option reads. A
	-- replacement still receives its own fresh, normalized options table.
	local getCount = Index.GetCount
	local o, snap
	if getCount == canonicalGetCount then
		-- The canonical call used to convert the ID and read capability again.
		-- Keep those callbacks and their order, without rebuilding the flags.
		local snapshotID = tonumber(itemID)
		if snapshotID then
			local snapshotWarband = warband
			if not Inv.HasWarband() then snapshotWarband = false end
			snap = CountFromFlags(snapshotID, bags, bank, snapshotWarband, equipped, mail, void, auctions, guild)
		else
			snap = 0
		end
	else
		o = {
			bags = bags, bank = bank, warband = warband, equipped = equipped,
			mail = mail, void = void, auctions = auctions, guild = guild,
			charges = charges,
		}
		snap = getCount(itemID, o)
	end
	-- Portal/loading: live GetItemCount can be 0 while the snapshot still
	-- has stacks. Prefer snapshot only when it actually has a count.
	-- Empty snapshot + live stacks (Syndicator lag, post-buy) must use live.
	if Inv.IsReliable and not Inv.IsReliable() and snap > 0 then
		return snap
	end
	if Flux.Item and Flux.Item.GetCount then
		local n
		if o then
			-- An override may retain this row and mutate it during the current
			-- native getter lookup. Read warband at its original argument point.
			n = asCount(Flux.Item.GetCount(itemID, includeBank, includeCharges, includeBank, o.warband))
		else
			n = asCount(Flux.Item.GetCount(itemID, includeBank, includeCharges, includeBank, warband))
		end
		if n > 0 then
			return n
		end
		if snap > 0 then
			-- Load-screen flicker: live 0 while the snapshot still has stacks.
			-- Once bags are trustworthy, live 0 is the last charge / last potion.
			if Inv.IsReliable and Inv.IsReliable() then
				return n
			end
			return snap
		end
		return n
	end
	return snap
end

Index.GetLiveCount = OwnedCarriedIndexGetLiveCount

local function FindInByBag(byBag, itemID, region, out)
	if not byBag then
		return
	end
	for bag, slots in pairs(byBag) do
		for slot, rec in pairs(slots) do
			if rec.itemID == itemID then
				out[#out + 1] = {
					bag = bag,
					slot = slot,
					count = rec.count,
					region = region,
					link = rec.link,
				}
			end
		end
	end
end

local function FindInByIndex(byIndex, itemID, region, out)
	if not byIndex then
		return
	end
	for index, rec in pairs(byIndex) do
		if rec.itemID == itemID then
			out[#out + 1] = {
				bag = nil,
				slot = index,
				count = rec.count,
				region = region,
				link = rec.link,
			}
		end
	end
end

function Index.Find(itemID, opts)
	itemID = tonumber(itemID)
	local locations = {}
	if not itemID then
		return locations
	end
	local bags, bank, warband, equipped, mail, void, auctions, guild = ReadOpts(opts)
	if bags then
		FindInByBag(Inv.snapshots.bags.byBag, itemID, "bags", locations)
	end
	if bank then
		FindInByBag(Inv.snapshots.bank.byBag, itemID, "bank", locations)
	end
	if warband then
		FindInByBag(Inv.snapshots.warband.byBag, itemID, "warband", locations)
	end
	if equipped then
		local bySlot = Inv.snapshots.equip.bySlot
		for slot, rec in pairs(bySlot) do
			if rec.itemID == itemID then
				locations[#locations + 1] = {
					bag = nil,
					slot = slot,
					count = rec.count,
					region = "equip",
					invSlot = slot,
					link = rec.link,
				}
			end
		end
	end
	if mail then
		FindInByIndex(Inv.snapshots.mail and Inv.snapshots.mail.byIndex, itemID, "mail", locations)
	end
	if void then
		FindInByBag(Inv.snapshots.void and Inv.snapshots.void.byBag, itemID, "void", locations)
	end
	if auctions then
		FindInByIndex(Inv.snapshots.auctions and Inv.snapshots.auctions.byIndex, itemID, "auctions", locations)
	end
	if guild then
		FindInByBag(Inv.snapshots.guild and Inv.snapshots.guild.byBag, itemID, "guild", locations)
	end
	return locations
end

local FindAllLocations = Index.Find

local function FirstInByBag(byBag, itemID, region)
	if not byBag then return nil end
	for bag, slots in pairs(byBag) do
		for slot, rec in pairs(slots) do
			if rec.itemID == itemID then
				return { bag = bag, slot = slot, count = rec.count, region = region, link = rec.link }
			end
		end
	end
end

local function FirstInByIndex(byIndex, itemID, region)
	if not byIndex then return nil end
	for index, rec in pairs(byIndex) do
		if rec.itemID == itemID then
			return { bag = nil, slot = index, count = rec.count, region = region, link = rec.link }
		end
	end
end

function Index.GetFirst(itemID, opts)
	-- Preserve the existing extension seam when a caller replaces Find.
	if Index.Find ~= FindAllLocations then
		local locs = Index.Find(itemID, opts)
		return locs[1]
	end
	itemID = tonumber(itemID)
	if not itemID then return nil end
	local bags, bank, warband, equipped, mail, void, auctions, guild = ReadOpts(opts)
	local row
	if bags then
		row = FirstInByBag(Inv.snapshots.bags.byBag, itemID, "bags")
		if row then return row end
	end
	if bank then
		row = FirstInByBag(Inv.snapshots.bank.byBag, itemID, "bank")
		if row then return row end
	end
	if warband then
		row = FirstInByBag(Inv.snapshots.warband.byBag, itemID, "warband")
		if row then return row end
	end
	if equipped then
		for slot, rec in pairs(Inv.snapshots.equip.bySlot) do
			if rec.itemID == itemID then
				return { bag = nil, slot = slot, count = rec.count, region = "equip", invSlot = slot, link = rec.link }
			end
		end
	end
	if mail then
		row = FirstInByIndex(Inv.snapshots.mail and Inv.snapshots.mail.byIndex, itemID, "mail")
		if row then return row end
	end
	if void then
		row = FirstInByBag(Inv.snapshots.void and Inv.snapshots.void.byBag, itemID, "void")
		if row then return row end
	end
	if auctions then
		row = FirstInByIndex(Inv.snapshots.auctions and Inv.snapshots.auctions.byIndex, itemID, "auctions")
		if row then return row end
	end
	if guild then
		return FirstInByBag(Inv.snapshots.guild and Inv.snapshots.guild.byBag, itemID, "guild")
	end
end

--- Unique item map from snapshots. Default: bags only.
--- Shape: { [itemID] = { count, link, bag, slot } }
local function AddUniqueRegion(out, region, byBag)
	if not byBag then
		return
	end
	for bag, slots in pairs(byBag) do
		for slot, rec in pairs(slots) do
			local id = rec and tonumber(rec.itemID)
			if id then
				local cur = out[id]
				if cur then
					cur.count = (cur.count or 0) + (tonumber(rec.count) or 0)
					if not cur.link and rec.link then
						cur.link = rec.link
					end
				else
					out[id] = {
						count = tonumber(rec.count) or 0,
						link = rec.link,
						bag = bag,
						slot = slot,
					}
				end
			end
		end
	end
end

local function AddUniqueByIndex(out, byIndex, region)
	if not byIndex then
		return
	end
	for index, rec in pairs(byIndex) do
		local id = rec and tonumber(rec.itemID)
		if id then
			local cur = out[id]
			if cur then
				cur.count = (cur.count or 0) + (tonumber(rec.count) or 0)
				if not cur.link and rec.link then
					cur.link = rec.link
				end
			else
				out[id] = {
					count = tonumber(rec.count) or 0,
					link = rec.link,
					bag = nil,
					slot = index,
					region = region,
				}
			end
		end
	end
end

function Index.GetUniqueItems(opts)
	opts = opts or EMPTY_OPTS
	local bags = opts.bags ~= false
	local bank = opts.bank == true or opts.includeBank == true
	local warband = opts.warband == true
	local equipped = opts.equipped == true
	local mail = opts.mail == true
	local void = opts.void == true
	local auctions = opts.auctions == true
	local guild = opts.guild == true
	if opts.includeBank == false then
		bank = false
		warband = false
	end
	if warband and not Inv.HasWarband() then
		warband = false
	end
	local out = {}
	if bags then
		AddUniqueRegion(out, "bags", Inv.snapshots.bags.byBag)
	end
	if bank then
		AddUniqueRegion(out, "bank", Inv.snapshots.bank.byBag)
	end
	if warband then
		AddUniqueRegion(out, "warband", Inv.snapshots.warband.byBag)
	end
	if equipped then
		local bySlot = Inv.snapshots.equip.bySlot
		if bySlot then
			for slot, rec in pairs(bySlot) do
				local id = rec and tonumber(rec.itemID)
				if id then
					local cur = out[id]
					if cur then
						cur.count = (cur.count or 0) + (tonumber(rec.count) or 0)
					else
						out[id] = {
							count = tonumber(rec.count) or 0,
							link = rec.link,
							bag = nil,
							slot = slot,
						}
					end
				end
			end
		end
	end
	if mail then
		AddUniqueByIndex(out, Inv.snapshots.mail and Inv.snapshots.mail.byIndex, "mail")
	end
	if void then
		AddUniqueRegion(out, "void", Inv.snapshots.void and Inv.snapshots.void.byBag)
	end
	if auctions then
		AddUniqueByIndex(out, Inv.snapshots.auctions and Inv.snapshots.auctions.byIndex, "auctions")
	end
	if guild then
		AddUniqueRegion(out, "guild", Inv.snapshots.guild and Inv.snapshots.guild.byBag)
	end
	return out
end

-- Keys-only fresh snapshot view for metadata harvesters. Keep original count/link
-- reads and duplicate branches; only discard the unused returned record objects.
-- Replaced public queries retain their original result/arguments/error behavior.
local OwnedUniqueItemQuery = Index.GetUniqueItems
function Index.GetUniqueItemIDs(opts)
	local getItems = Index.GetUniqueItems
	if getItems ~= OwnedUniqueItemQuery then return getItems(opts) end
	opts = opts or EMPTY_OPTS
	local bags = opts.bags ~= false
	local bank = opts.bank == true or opts.includeBank == true
	local warband = opts.warband == true
	local equipped = opts.equipped == true
	local mail = opts.mail == true
	local void = opts.void == true
	local auctions = opts.auctions == true
	local guild = opts.guild == true
	if opts.includeBank == false then
		bank = false
		warband = false
	end
	if warband and not Inv.HasWarband() then
		warband = false
	end
	local out = {}
	local counts, links
	local uniqueCount = 0
	local function AddRegion(region, byBag)
		if not byBag then
			return
		end
		for bag, slots in pairs(byBag) do
			for slot, rec in pairs(slots) do
				local id = rec and tonumber(rec.itemID)
				if id then
					local cur = out[id]
					if cur then
						counts[cur] = (counts[cur] or 0) + (tonumber(rec.count) or 0)
						if not links[cur] and rec.link then
							links[cur] = rec.link
						end
					else
						local count = tonumber(rec.count) or 0
						local link = rec.link
						if not counts then counts, links = {}, {} end
						uniqueCount = uniqueCount + 1
						counts[uniqueCount], links[uniqueCount] = count, link
						out[id] = uniqueCount
					end
				end
			end
		end
	end
	if bags then
		AddRegion("bags", Inv.snapshots.bags.byBag)
	end
	if bank then
		AddRegion("bank", Inv.snapshots.bank.byBag)
	end
	if warband then
		AddRegion("warband", Inv.snapshots.warband.byBag)
	end
	if equipped then
		local bySlot = Inv.snapshots.equip.bySlot
		if bySlot then
			for slot, rec in pairs(bySlot) do
				local id = rec and tonumber(rec.itemID)
				if id then
					local cur = out[id]
					if cur then
						counts[cur] = (counts[cur] or 0) + (tonumber(rec.count) or 0)
					else
						local count = tonumber(rec.count) or 0
						local link = rec.link
						if not counts then counts, links = {}, {} end
						uniqueCount = uniqueCount + 1
						counts[uniqueCount], links[uniqueCount] = count, link
						out[id] = uniqueCount
					end
				end
			end
		end
	end
	local function AddByIndex(byIndex, region)
		if not byIndex then
			return
		end
		for index, rec in pairs(byIndex) do
			local id = rec and tonumber(rec.itemID)
			if id then
				local cur = out[id]
				if cur then
					counts[cur] = (counts[cur] or 0) + (tonumber(rec.count) or 0)
					if not links[cur] and rec.link then
						links[cur] = rec.link
					end
				else
					local count = tonumber(rec.count) or 0
					local link = rec.link
					if not counts then counts, links = {}, {} end
					uniqueCount = uniqueCount + 1
					counts[uniqueCount], links[uniqueCount] = count, link
					out[id] = uniqueCount
				end
			end
		end
	end
	if mail then
		AddByIndex(Inv.snapshots.mail and Inv.snapshots.mail.byIndex, "mail")
	end
	if void then
		AddRegion("void", Inv.snapshots.void and Inv.snapshots.void.byBag)
	end
	if auctions then
		AddByIndex(Inv.snapshots.auctions and Inv.snapshots.auctions.byIndex, "auctions")
	end
	if guild then
		AddRegion("guild", Inv.snapshots.guild and Inv.snapshots.guild.byBag)
	end
	return out
end

function Index.UniqueCount(region)
	region = region or "bags"
	local counts = Inv.snapshots[region] and Inv.snapshots[region].counts
	if not counts then
		return 0
	end
	local n = 0
	for _ in pairs(counts) do
		n = n + 1
	end
	return n
end

local function SkipEquipBag(bag, region)
	if region ~= "bags" and region ~= "bank" then
		return false
	end
	local C = Inv.Containers
	if C and C.SkipEquipCandidateBag then
		return C.SkipEquipCandidateBag(bag)
	end
	return false
end

-- Private walkers receive the current callback; emitted location rows stay fresh.
local function WalkByBag(fn, byBag, region)
	if not byBag then
		return
	end
	for bag, slots in pairs(byBag) do
		if not SkipEquipBag(bag, region) then
			for slot, rec in pairs(slots) do
				local id = rec and tonumber(rec.itemID)
				if id then
					fn({
						bag = bag,
						slot = slot,
						count = rec.count,
						region = region,
						itemID = id,
						link = rec.link,
					})
				end
			end
		end
	end
end

local function WalkByIndex(fn, byIndex, region)
	if not byIndex then
		return
	end
	for index, rec in pairs(byIndex) do
		local id = rec and tonumber(rec.itemID)
		if id then
			fn({
				bag = nil,
				slot = index,
				count = rec.count,
				region = region,
				itemID = id,
				link = rec.link,
			})
		end
	end
end

--- Every occupied snapshot slot (duplicates kept). Default: bags only.
function Index.ForEachLocation(fn, opts)
	if type(fn) ~= "function" then
		return
	end
	local bags, bank, warband, equipped, mail, void, auctions, guild = ReadOpts(opts)
	if bags then
		WalkByBag(fn, Inv.snapshots.bags.byBag, "bags")
	end
	if bank then
		WalkByBag(fn, Inv.snapshots.bank.byBag, "bank")
	end
	if warband then
		WalkByBag(fn, Inv.snapshots.warband.byBag, "warband")
	end
	if equipped then
		local bySlot = Inv.snapshots.equip.bySlot
		if bySlot then
			for slot, rec in pairs(bySlot) do
				local id = rec and tonumber(rec.itemID)
				if id then
					fn({
						bag = nil,
						slot = slot,
						count = rec.count,
						region = "equip",
						invSlot = slot,
						itemID = id,
						link = rec.link,
					})
				end
			end
		end
	end
	if mail then
		WalkByIndex(fn, Inv.snapshots.mail and Inv.snapshots.mail.byIndex, "mail")
	end
	if void then
		WalkByBag(fn, Inv.snapshots.void and Inv.snapshots.void.byBag, "void")
	end
	if auctions then
		WalkByIndex(fn, Inv.snapshots.auctions and Inv.snapshots.auctions.byIndex, "auctions")
	end
	if guild then
		WalkByBag(fn, Inv.snapshots.guild and Inv.snapshots.guild.byBag, "guild")
	end
end

function Index.GetSnapshotGeneration(region)
	region = region or "bags"
	local snap = Inv.snapshots and Inv.snapshots[region]
	return snap and (tonumber(snap.generation) or 0) or 0
end

--- First empty player-bag slot, skipping keyring and reagent bag.
function Index.GetFirstFreeBagSlot()
	local C = Inv.Containers
	local Container = Flux.Container
	if not C or not C.GetCarriedBagIDs or not Container then
		return nil, nil
	end
	local byBag = Inv.snapshots.bags and Inv.snapshots.bags.byBag
	for _, bag in ipairs(C.GetCarriedBagIDs()) do
		if not SkipEquipBag(bag, "bags") then
			local n = Container.GetNumSlots(bag) or 0
			local slots = byBag and byBag[bag]
			for slot = 1, n do
				if not (slots and slots[slot]) then
					if not Container.GetItemID(bag, slot) then
						return bag, slot
					end
				end
			end
		end
	end
	return nil, nil
end

function Inv.GetCount(itemID, opts)
	return Index.GetCount(itemID, opts)
end

-- The snapshot count defaults already select just the carried bags. Keep the
-- options allocation in the caller when either public count function changes.
ns.InventoryCarriedSnapshotQuery = {
	owner = Inv,
	facade = Inv.GetCount,
	query = function(itemID)
		if rawget(Index, "GetCount") == canonicalGetCount then
			return canonicalGetCount(itemID)
		end
	end,
}

local function OwnedCarriedInventoryGetLiveCount(itemID, opts)
	return Index.GetLiveCount(itemID, opts)
end

Inv.GetLiveCount = OwnedCarriedInventoryGetLiveCount

-- Only the selected actual defining closure receives these private rows.
-- A copied public alias still invokes the same closed original implementation.
local CARRIED_PHYSICAL_OPTS = { bags = true, bank = false, warband = false, equipped = false, charges = false }
local CARRIED_CHARGE_OPTS = { bags = true, bank = false, warband = false, equipped = false, charges = true }
local function QueryCarriedLiveCount(itemID, charges)
	-- Preserve the facade's one ordinary lookup on its CLOSED original Index.
	local getLiveCount = Index.GetLiveCount
	if getLiveCount == OwnedCarriedIndexGetLiveCount then
		return getLiveCount(itemID, charges and CARRIED_CHARGE_OPTS or CARRIED_PHYSICAL_OPTS)
	end
	return getLiveCount(itemID, {
		bags = true, bank = false, warband = false, equipped = false, charges = charges,
	})
end
ns.InventoryCarriedLiveQuery = {
	namespace = ns, flux = Flux,
	facade = OwnedCarriedInventoryGetLiveCount, query = QueryCarriedLiveCount,
}


function Inv.Find(itemID, opts)
	return Index.Find(itemID, opts)
end

function Inv.GetFirst(itemID, opts)
	return Index.GetFirst(itemID, opts)
end

function Inv.GetUniqueItems(opts)
	return Index.GetUniqueItems(opts)
end

local OwnedInventoryUniqueQuery = Inv.GetUniqueItems
local OwnedIndexUniqueItemIDs = Index.GetUniqueItemIDs
function Inv.GetUniqueItemIDs(opts)
	local getItems = Inv.GetUniqueItems
	if getItems ~= OwnedInventoryUniqueQuery then return getItems(opts) end
	return OwnedIndexUniqueItemIDs(opts)
end

-- The addon-private namespace vouches for this exact owner/helper pair.
-- Copied or replaced public helpers must retain the legacy public query path.
ns.InventoryUniqueItemIDQuery = { owner = Inv, query = Inv.GetUniqueItemIDs }

local function FirstSnapshotLink(itemID, byBag)
	if not byBag then return nil end
	for _, slots in pairs(byBag) do
		for _, rec in pairs(slots) do
			if rec and tonumber(rec.itemID) == itemID then
				local link = rec.link
				if link then return link end
			end
		end
	end
end

-- The full map's representative link is the first present link in these
-- regions. This projection reads it without building unrelated item records.
ns.InventoryUniqueItemIDQuery.carriedOrBankLink = function(itemID)
	if rawget(Inv, "GetUniqueItems") ~= OwnedInventoryUniqueQuery
		or rawget(Index, "GetUniqueItems") ~= OwnedUniqueItemQuery
		or (issecretvalue and issecretvalue(itemID)) then
		return false
	end
	local warband = Inv.HasWarband()
	local snaps = Inv.snapshots
	local link = FirstSnapshotLink(itemID, snaps.bags.byBag) or FirstSnapshotLink(itemID, snaps.bank.byBag)
	if not link and warband then link = FirstSnapshotLink(itemID, snaps.warband.byBag) end
	return true, link
end

-- Tier totals consume only counts. Walk the same bag rows without allocating
-- a location record for every unique ID; never retain this view across calls.
-- Public query replacements keep their ordinary result and argument contract.
local function QueryUniqueBagCounts()
	if Inv.GetUniqueItems ~= OwnedInventoryUniqueQuery or Index.GetUniqueItems ~= OwnedUniqueItemQuery then
		return nil
	end
	local out = {}
	-- Preserve source link reads/duplicate branches even though callers discard links.
	local links
	local byBag = Inv.snapshots.bags.byBag
	if byBag then
		for bag, slots in pairs(byBag) do
			for slot, rec in pairs(slots) do
				local id = rec and tonumber(rec.itemID)
				if id then
					local count = out[id]
					if count then
						out[id] = (count or 0) + (tonumber(rec.count) or 0)
						if not links[id] and rec.link then
							links[id] = rec.link
						end
					else
						out[id] = tonumber(rec.count) or 0
						if not links then links = {} end
						links[id] = rec.link
					end
				end
			end
		end
	end
	return out
end
ns.InventoryUniqueItemIDQuery.bagCounts = QueryUniqueBagCounts

function Inv.ForEachLocation(fn, opts)
	return Index.ForEachLocation(fn, opts)
end

function Inv.GetSnapshotGeneration(region)
	return Index.GetSnapshotGeneration(region)
end

function Inv.GetFirstFreeBagSlot()
	return Index.GetFirstFreeBagSlot()
end

function Inv.GetBagGeneration()
	return Index.GetSnapshotGeneration("bags")
end

-- The bridge may defer the pure bag-record builder until its ladder cache
-- misses. Replacement public builders/generation getters retain eager queries.
ns.InventoryUniqueItemIDQuery.fullQuery = OwnedInventoryUniqueQuery
ns.InventoryUniqueItemIDQuery.index = Index
ns.InventoryUniqueItemIDQuery.indexQuery = OwnedUniqueItemQuery
ns.InventoryUniqueItemIDQuery.bagGeneration = Inv.GetBagGeneration
ns.InventoryUniqueItemIDQuery.indexGeneration = Index.GetSnapshotGeneration

local function RegionGetCount(region, itemID)
	itemID = tonumber(itemID)
	if not itemID then
		return 0
	end
	return SnapCount(region, itemID)
end

Inv.Mail = {
	GetCount = function(itemID)
		return RegionGetCount("mail", itemID)
	end,
	HasObservedInbox = function()
		local snap = Inv.snapshots and Inv.snapshots.mail
		return snap ~= nil and Inv.source ~= nil and snap.observedSource == Inv.source
	end,
}

-- Positive physical stock can be known before the source has covered the
-- whole inbox. Only a qualified observation can establish an empty result.
-- A second result can report positive cached incoming stock while Syndicator
-- has yet to replace its saved inbox list during this session.
function Inv.Mail.GetObservedCount(itemID)
	if issecretvalue and issecretvalue(itemID) then return end
	if type(itemID) ~= "number" or itemID <= 0 or itemID % 1 ~= 0 then return end
	if Inv.source == "syndicator" then
		local adapter = Inv.Syndicator
		if adapter and adapter.GetObservedMailCount then
			return adapter.GetObservedMailCount(itemID, RegionGetCount("mail", itemID))
		end
	elseif Inv.source == "builtin" then
		local builtin = Inv.Builtin and Inv.Builtin.Mail
		if not builtin or not builtin.GetPredictedCount then return end
		local observed = RegionGetCount("mail", itemID) - builtin.GetPredictedCount(itemID)
		if observed > 0 then return observed end
		if Inv.Mail.HasObservedInbox() then return 0 end
	end
end

Inv.Void = {
	GetCount = function(itemID)
		return RegionGetCount("void", itemID)
	end,
}

Inv.Auctions = {
	GetCount = function(itemID)
		return RegionGetCount("auctions", itemID)
	end,
}

Inv.Guild = {
	GetCount = function(itemID)
		return RegionGetCount("guild", itemID)
	end,
}

Inv.Equip = {
	GetCount = function(itemID)
		return RegionGetCount("equip", itemID)
	end,
}

Inv.Currency = {
	GetCount = function(id)
		id = tonumber(id)
		if not id then
			return 0
		end
		local snap = Inv.snapshots.currencies
		if not snap or not snap.counts then
			return 0
		end
		return snap.counts[id] or 0
	end,
}
