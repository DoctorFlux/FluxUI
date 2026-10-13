-- Inventory/Builtin/Auctions.lua — owned listings while the AH is open.
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Builtin = Inv.Builtin
local Store = Inv.Store
local Cap = Flux.Cap

local Auctions = {}
Builtin.Auctions = Auctions

local started = false
local houseOpen = false

local function Request()
	Flux.Scheduler.Request("inventory", "auctions")
end

local function NumericID(value)
	local n = tonumber(value)
	if n and n > 0 then
		return n
	end
	if Flux.Secrets and Flux.Secrets.SafeGetNumber then
		n = Flux.Secrets.SafeGetNumber(value, 0)
		if n and n > 0 then
			return n
		end
	end
	return nil
end

local function ApplyList(list)
	local snap = Inv.snapshots.auctions
	if snap then
		if not snap.byIndex then
			snap.byIndex = {}
		end
		if wipe then
			wipe(snap.byIndex)
		else
			for k in pairs(snap.byIndex) do
				snap.byIndex[k] = nil
			end
		end
		local counts = {}
		for i = 1, #list do
			local rec = list[i]
			local id = rec and NumericID(rec.itemID)
			if id then
				local n = tonumber(rec.itemCount or rec.count) or 1
				snap.byIndex[i] = { itemID = id, count = n, link = rec.itemLink or rec.link }
				counts[id] = (counts[id] or 0) + n
			end
		end
		snap.counts = counts
		snap.generation = (snap.generation or 0) + 1
	end
	if not Store.UsesSyndicator() then
		local char = Store.EnsureCurrentCharacter()
		if char then
			char.auctions = list
			Store.MarkPending(nil, "all")
		end
	end
end

local function IsAuctioneer(kind)
	local e = Enum and Enum.PlayerInteractionType
	return e and kind == e.Auctioneer
end

local function ScanLegacy()
	if not GetNumAuctionItems then
		return
	end
	local list = {}
	local n = GetNumAuctionItems("owner") or 0
	for index = 1, n do
		local info = { GetAuctionItemInfo("owner", index) }
		-- texture, name, count, quality, ..., itemID at 17 on modern classic
		local count = tonumber(info[3]) or 1
		local quality = info[4]
		local itemID = NumericID(info[17] or info[1])
		local link = GetAuctionItemLink and GetAuctionItemLink("owner", index)
		if not itemID and link then
			itemID = tonumber(link:match("item:(%d+)"))
		end
		if itemID then
			list[#list + 1] = {
				itemID = itemID,
				itemCount = count,
				iconTexture = info[2],
				itemLink = link,
				quality = quality,
			}
		end
	end
	ApplyList(list)
end

local function ScanModern()
	if not C_AuctionHouse or not C_AuctionHouse.GetNumOwnedAuctions then
		return
	end
	local list = {}
	local n = C_AuctionHouse.GetNumOwnedAuctions() or 0
	for index = 1, n do
		local info = C_AuctionHouse.GetOwnedAuctionInfo(index)
		if info and (not Enum.AuctionStatus or info.status == Enum.AuctionStatus.Active) then
			local key = info.itemKey
			local itemID = key and NumericID(key.itemID)
			if itemID then
				local count = tonumber(info.quantity) or 1
				local link = info.itemLink
				if not link and GetItemInfo then
					link = select(2, GetItemInfo(itemID))
				end
				list[#list + 1] = {
					itemID = itemID,
					itemCount = count,
					itemLink = link,
					auctionID = info.auctionID,
					expirationTime = info.timeLeftSeconds and ((time and time() or 0) + info.timeLeftSeconds) or nil,
				}
			end
		end
	end
	ApplyList(list)
end

function Auctions.Refresh()
	if Store.UsesSyndicator() then
		return
	end
	if not houseOpen then
		return
	end
	if Cap.hasLegacyAuctionHouse then
		ScanLegacy()
	else
		ScanModern()
	end
end

function Auctions.Start()
	if started or Store.UsesSyndicator() then
		return
	end
	if not (Cap.hasAuctionHouse or Cap.hasLegacyAuctionHouse or Cap.hasModernAuctionHouse) then
		return
	end
	started = true

	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
		if not IsAuctioneer(kind) then
			return
		end
		houseOpen = true
		if Cap.hasLegacyAuctionHouse and GetOwnerAuctionItems then
			pcall(GetOwnerAuctionItems)
		elseif C_AuctionHouse and C_AuctionHouse.QueryOwnedAuctions then
			pcall(C_AuctionHouse.QueryOwnedAuctions, {})
		end
	end)
	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
		if IsAuctioneer(kind) then
			houseOpen = false
		end
	end)
	Flux.Events.Register("AUCTION_HOUSE_SHOW", function()
		houseOpen = true
		if Cap.hasLegacyAuctionHouse and GetOwnerAuctionItems then
			pcall(GetOwnerAuctionItems)
		end
	end)
	Flux.Events.Register("AUCTION_HOUSE_CLOSED", function()
		houseOpen = false
	end)
	Flux.Events.Register("AUCTION_OWNED_LIST_UPDATE", function()
		houseOpen = true
		Request()
	end)
	Flux.Events.Register("OWNED_AUCTIONS_UPDATED", function()
		houseOpen = true
		Request()
	end)
end
