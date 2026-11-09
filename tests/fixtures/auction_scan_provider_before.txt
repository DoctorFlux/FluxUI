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
local scanFrame, scan, scanAt, firstQueued, lastFingerprint

local function Request()
	Auctions.Refresh()
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
	local parts = {}
	for i, rec in ipairs(list) do
		parts[i] = rec.itemID .. ":" .. rec.itemCount .. ":" .. (rec.auctionID or "")
	end
	local fp = table.concat(parts, ";")
	if fp == lastFingerprint then return false end
	lastFingerprint = fp
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
	return true
end

local function IsAuctioneer(kind)
	local e = Enum and Enum.PlayerInteractionType
	return e and kind == e.Auctioneer
end

local function ReadLegacy(index, list)
	local info = { GetAuctionItemInfo("owner", index) }
	-- name, texture, count, quality, ..., itemID at 17 on modern Classic
	local count = tonumber(info[3]) or 1
	local quality = info[4]
	local itemID = NumericID(info[17] or info[1])
	local link
	if not itemID and GetAuctionItemLink then link = GetAuctionItemLink("owner", index) end
	if not itemID and link then itemID = tonumber(link:match("item:(%d+)")) end
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

local function ReadModern(index, list)
	local info = C_AuctionHouse.GetOwnedAuctionInfo(index)
	if info and (not Enum or not Enum.AuctionStatus or info.status == Enum.AuctionStatus.Active) then
		local key = info.itemKey
		local itemID = key and NumericID(key.itemID)
		if itemID then
			list[#list + 1] = {
				itemID = itemID,
				itemCount = tonumber(info.quantity) or 1,
				itemLink = info.itemLink,
				auctionID = info.auctionID,
				expirationTime = info.timeLeftSeconds and ((time and time() or 0) + info.timeLeftSeconds) or nil,
			}
		end
	end
end

local function Now()
	return (GetTime and GetTime()) or 0
end

local function StepScan(self)
	if Now() < scanAt then return end
	if not scan then
		local n = 0
		if Cap.hasLegacyAuctionHouse then
			n = GetNumAuctionItems and GetNumAuctionItems("owner") or 0
		elseif C_AuctionHouse and C_AuctionHouse.GetNumOwnedAuctions then
			n = C_AuctionHouse.GetNumOwnedAuctions() or 0
		end
		scan = { list = {}, index = 1, n = n }
		firstQueued = nil
	end
	local startedAt = debugprofilestop and debugprofilestop()
	local calls = 0
	while scan.index <= scan.n and calls < 32 do
		if Cap.hasLegacyAuctionHouse then ReadLegacy(scan.index, scan.list) else ReadModern(scan.index, scan.list) end
		scan.index, calls = scan.index + 1, calls + 1
		if startedAt and debugprofilestop() - startedAt >= 1 then break end
	end
	if scan.index <= scan.n then return end
	local list = scan.list
	scan = nil
	self:SetScript("OnUpdate", nil)
	if ApplyList(list) then Inv.Notify({ auctions = true }) end
end

local function Close()
	houseOpen, scan, firstQueued = false, nil, nil
	if scanFrame then scanFrame:SetScript("OnUpdate", nil) end
end

function Auctions.Refresh()
	if Store.UsesSyndicator() then
		return
	end
	if not houseOpen then
		return
	end
	local now = Now()
	firstQueued = firstQueued or now
	scanAt = math.min(now + 0.15, firstQueued + 0.6)
	scan = nil
	scanFrame = scanFrame or CreateFrame("Frame")
	scanFrame:SetScript("OnUpdate", StepScan)
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
		Request()
	end)
	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
		if IsAuctioneer(kind) then
			Close()
		end
	end)
	Flux.Events.Register("AUCTION_HOUSE_SHOW", function()
		houseOpen = true
		if Cap.hasLegacyAuctionHouse and GetOwnerAuctionItems then
			pcall(GetOwnerAuctionItems)
		end
		Request()
	end)
	Flux.Events.Register("AUCTION_HOUSE_CLOSED", Close)
	Flux.Events.Register("AUCTION_OWNED_LIST_UPDATE", function()
		Request()
	end)
	Flux.Events.Register("OWNED_AUCTIONS_UPDATED", function()
		Request()
	end)
end
