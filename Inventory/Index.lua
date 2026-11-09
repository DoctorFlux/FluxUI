-- Inventory/Index.lua — snapshot + live counts / find
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory

local Index = {}
Inv.Index = Index

local function DefaultOpts(opts)
	opts = opts or {}
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
	return {
		bags = bags,
		bank = bank,
		warband = warband,
		equipped = equipped,
		mail = mail,
		void = void,
		auctions = auctions,
		guild = guild,
		charges = opts.charges,
	}
end

local function SnapCount(region, itemID)
	local snap = Inv.snapshots[region]
	if not snap or not snap.counts then
		return 0
	end
	return snap.counts[itemID] or 0
end

function Index.GetCount(itemID, opts)
	itemID = tonumber(itemID)
	if not itemID then
		return 0
	end
	opts = DefaultOpts(opts)
	local n = 0
	if opts.bags then
		n = n + SnapCount("bags", itemID)
	end
	if opts.bank then
		n = n + SnapCount("bank", itemID)
	end
	if opts.warband then
		n = n + SnapCount("warband", itemID)
	end
	if opts.equipped then
		n = n + SnapCount("equip", itemID)
	end
	if opts.mail then
		n = n + SnapCount("mail", itemID)
	end
	if opts.void then
		n = n + SnapCount("void", itemID)
	end
	if opts.auctions then
		n = n + SnapCount("auctions", itemID)
	end
	if opts.guild then
		n = n + SnapCount("guild", itemID)
	end
	return n
end

function Index.GetLiveCount(itemID, opts)
	itemID = tonumber(itemID)
	if not itemID then
		return 0
	end
	local o = DefaultOpts(opts)
	local includeCharges = not (opts and opts.charges == false)
	local includeBank = o.bank or o.warband
	-- Live GetItemCount is 0 during loading screens. Charge queries can stay 0
	-- even after the snapshot already has the stack (mana gem).
	local snap = Index.GetCount(itemID, o)
	-- Portal/loading: live GetItemCount can be 0 while the snapshot still
	-- has stacks. Prefer snapshot only when it actually has a count.
	-- Empty snapshot + live stacks (Syndicator lag, post-buy) must use live.
	if Inv.IsReliable and not Inv.IsReliable() and snap > 0 then
		return snap
	end
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
	if Flux.Item and Flux.Item.GetCount then
		local n = asCount(Flux.Item.GetCount(itemID, includeBank, includeCharges, includeBank, o.warband))
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
	opts = DefaultOpts(opts)
	if opts.bags then
		FindInByBag(Inv.snapshots.bags.byBag, itemID, "bags", locations)
	end
	if opts.bank then
		FindInByBag(Inv.snapshots.bank.byBag, itemID, "bank", locations)
	end
	if opts.warband then
		FindInByBag(Inv.snapshots.warband.byBag, itemID, "warband", locations)
	end
	if opts.equipped then
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
	if opts.mail then
		FindInByIndex(Inv.snapshots.mail and Inv.snapshots.mail.byIndex, itemID, "mail", locations)
	end
	if opts.void then
		FindInByBag(Inv.snapshots.void and Inv.snapshots.void.byBag, itemID, "void", locations)
	end
	if opts.auctions then
		FindInByIndex(Inv.snapshots.auctions and Inv.snapshots.auctions.byIndex, itemID, "auctions", locations)
	end
	if opts.guild then
		FindInByBag(Inv.snapshots.guild and Inv.snapshots.guild.byBag, itemID, "guild", locations)
	end
	return locations
end

function Index.GetFirst(itemID, opts)
	local locs = Index.Find(itemID, opts)
	return locs[1]
end

--- Unique item map from snapshots. Default: bags only.
--- Shape: { [itemID] = { count, link, bag, slot } }
function Index.GetUniqueItems(opts)
	opts = opts or {}
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
	local function AddByIndex(byIndex, region)
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

--- Every occupied snapshot slot (duplicates kept). Default: bags only.
function Index.ForEachLocation(fn, opts)
	if type(fn) ~= "function" then
		return
	end
	opts = DefaultOpts(opts)
	local function WalkByBag(byBag, region)
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
	if opts.bags then
		WalkByBag(Inv.snapshots.bags.byBag, "bags")
	end
	if opts.bank then
		WalkByBag(Inv.snapshots.bank.byBag, "bank")
	end
	if opts.warband then
		WalkByBag(Inv.snapshots.warband.byBag, "warband")
	end
	if opts.equipped then
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
	local function WalkByIndex(byIndex, region)
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
	if opts.mail then
		WalkByIndex(Inv.snapshots.mail and Inv.snapshots.mail.byIndex, "mail")
	end
	if opts.void then
		WalkByBag(Inv.snapshots.void and Inv.snapshots.void.byBag, "void")
	end
	if opts.auctions then
		WalkByIndex(Inv.snapshots.auctions and Inv.snapshots.auctions.byIndex, "auctions")
	end
	if opts.guild then
		WalkByBag(Inv.snapshots.guild and Inv.snapshots.guild.byBag, "guild")
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

function Inv.GetLiveCount(itemID, opts)
	return Index.GetLiveCount(itemID, opts)
end

function Inv.Find(itemID, opts)
	return Index.Find(itemID, opts)
end

function Inv.GetFirst(itemID, opts)
	return Index.GetFirst(itemID, opts)
end

function Inv.GetUniqueItems(opts)
	return Index.GetUniqueItems(opts)
end

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
}

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
