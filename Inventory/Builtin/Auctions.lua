-- Inventory/Builtin/Auctions.lua — owned listings and sale notifications.
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
local queryAttempted = false
local scanFrame, scan, scanAt, firstQueued, lastList
local cancelledScans = 0
local soldAuctionIDs
local legacySalePending = false

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

local function PrepareRecord(job, savedIndex)
	local i = #job.list
	local rec = job.list[i]
	local old = lastList and lastList[i]
	if not old or old.itemID ~= rec.itemID or old.itemCount ~= rec.itemCount
		or (old.auctionID ~= rec.auctionID
			and tostring(old.auctionID or "") ~= tostring(rec.auctionID or "")) then
		job.changed = true
	end
	local id, n, link = rec.itemID, rec.itemCount, rec.itemLink or rec.link
	if savedIndex then
		id, n = tonumber(id), tonumber(n or rec.count) or 1
	end
	if id and id > 0 then
		local snap = Inv.snapshots.auctions
		local row = snap and snap.byIndex and snap.byIndex[savedIndex or i]
		if not row or row.itemID ~= id or row.count ~= n or row.link ~= link then
			row = { itemID = id, count = n, link = link }
		end
		job.byIndex[i] = row
		job.counts[id] = (job.counts[id] or 0) + n
	end
end

local function ApplyList(job, char)
	local list = job.list
	if not job.changed and #list == #lastList then return false end
	lastList = list
	local snap = Inv.snapshots.auctions
	if snap then
		-- Keep incomplete generations private; publication must not copy every row.
		snap.byIndex, snap.counts = job.byIndex, job.counts
		snap.generation = (snap.generation or 0) + 1
	end
	if not Store.UsesSyndicator() then
		char = char or Store.EnsureCurrentCharacter()
		if char then
			char.auctions = list
			Store.MarkPending(nil, "all")
		end
	end
	return true
end

local function RemoveListing(char, list, index)
	if Store.UsesSyndicator() or char.auctions ~= list then return end
	local job = { list = {}, byIndex = {}, counts = {}, changed = true }
	local slots = {}
	for i in pairs(list) do
		if type(i) == "number" and i ~= index then slots[#slots + 1] = i end
	end
	table.sort(slots)
	for _, i in ipairs(slots) do
		job.list[#job.list + 1] = list[i]
		PrepareRecord(job, i)
	end
	ApplyList(job, char)
	Inv.Notify({ auctions = true })
end

local function OnAuctionSold(auctionID)
	if Store.UsesSyndicator() then return end
	if issecretvalue and issecretvalue(auctionID) then return end
	auctionID = tonumber(auctionID)
	if not auctionID or auctionID <= 0 or auctionID % 1 ~= 0 then return end

	-- An older native list can still be queued when the notification arrives.
	-- Only a subsequent owned-list update can replace this sale observation.
	soldAuctionIDs = soldAuctionIDs or {}
	if soldAuctionIDs[auctionID] then return end
	soldAuctionIDs[auctionID] = true
	if scan then Request() end

	local char = Store.GetCurrentCharacter()
	local list = char and char.auctions
	if not list then return end
	for i, row in pairs(list) do
		if type(i) == "number" and tonumber(row.auctionID) == auctionID then
			RemoveListing(char, list, i)
			return
		end
	end
end

local function LegacySalePattern()
	local format = ERR_AUCTION_SOLD_S
	if type(format) ~= "string" then return end
	local first, last = format:find("%s", 1, true)
	if not first then first, last = format:find("%1$s", 1, true) end
	if not first then return end
	local function Escape(text)
		return (text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
	end
	return "^" .. Escape(format:sub(1, first - 1)) .. "(.+)" .. Escape(format:sub(last + 1)) .. "$"
end

local function OnLegacyAuctionSold(itemName)
	if Store.UsesSyndicator() or (issecretvalue and issecretvalue(itemName))
		or type(itemName) ~= "string" or itemName == "" then return end
	if houseOpen then
		Request()
		return
	end
	-- The legacy notice names an item. The owner list decides ambiguous matches
	-- and supplies the first fresh snapshot when the Auction House opens again.
	legacySalePending = true
	itemName = itemName:match("|h%[(.-)%]|h") or itemName
	local char = Store.GetCurrentCharacter()
	local list = char and char.auctions
	if not list then return end
	local match
	for i, row in pairs(list) do
		if type(i) == "number" then
			local name = row.itemName
			if not name and Flux.Item and Flux.Item.GetInfo then
				name = Flux.Item.GetInfo(row.itemLink or row.link or row.itemID)
			end
			if not name or (name == itemName and match) then return end
			if name == itemName then match = i end
		end
	end
	if match then RemoveListing(char, list, match) end
end

local function IsAuctioneer(kind)
	local e = Enum and Enum.PlayerInteractionType
	return e and kind == e.Auctioneer
end

local function ReadLegacy(index, list, job)
	local info = { GetAuctionItemInfo("owner", index) }
	if scan ~= job or Store.UsesSyndicator() then return end
	if info[16] == 1 then return end -- sold, pending delivery
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
			itemName = info[1],
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
		if soldAuctionIDs and soldAuctionIDs[tonumber(info.auctionID)] then return end
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
	-- Readiness can transfer ownership while this scan waits or spans frames.
	if Store.UsesSyndicator() then
		scan, scanAt, firstQueued = nil, nil, nil
		cancelledScans = 0
		self:SetScript("OnUpdate", nil)
		return
	end
	if Now() < scanAt then return end
	if not scan then
		local job = { list = {}, byIndex = {}, counts = {}, index = 1, changed = lastList == nil }
		scan = job
		firstQueued = nil
		local n = 0
		if Cap.hasLegacyAuctionHouse then
			n = GetNumAuctionItems and GetNumAuctionItems("owner") or 0
		elseif C_AuctionHouse and C_AuctionHouse.GetNumOwnedAuctions then
			n = C_AuctionHouse.GetNumOwnedAuctions() or 0
		end
		-- Native getters may synchronously replace this generation or close the AH.
		if scan ~= job then return end
		if Store.UsesSyndicator() then
			scan, scanAt, firstQueued = nil, nil, nil
			cancelledScans = 0
			self:SetScript("OnUpdate", nil)
			return
		end
		job.n = n
	end
	local job = scan
	local startedAt = debugprofilestop and debugprofilestop()
	local calls = 0
	while job.index <= job.n and calls < 32 do
		local size = #job.list
		if Cap.hasLegacyAuctionHouse then ReadLegacy(job.index, job.list, job) else ReadModern(job.index, job.list) end
		if scan ~= job then return end
		if Store.UsesSyndicator() then
			scan, scanAt, firstQueued = nil, nil, nil
			cancelledScans = 0
			self:SetScript("OnUpdate", nil)
			return
		end
		if #job.list > size then PrepareRecord(job) end
		job.index, calls = job.index + 1, calls + 1
		if startedAt and debugprofilestop() - startedAt >= 1 then break end
	end
	if job.index <= job.n then return end
	scan = nil
	cancelledScans = 0
	self:SetScript("OnUpdate", nil)
	if ApplyList(job) then Inv.Notify({ auctions = true }) end
end

local function Close()
	houseOpen, queryAttempted, scan, firstQueued = false, false, nil, nil
	cancelledScans = 0
	if scanFrame then scanFrame:SetScript("OnUpdate", nil) end
end

local function Open(fromInteraction)
	if Store.UsesSyndicator() then return end
	houseOpen = true
	if not queryAttempted then
		-- Both show events can describe one opening. Latch before calling native
		-- code, which can deliver callbacks before it returns.
		if Cap.hasLegacyAuctionHouse and GetOwnerAuctionItems then
			queryAttempted = true
			pcall(GetOwnerAuctionItems)
		elseif fromInteraction and C_AuctionHouse and C_AuctionHouse.QueryOwnedAuctions then
			queryAttempted = true
			pcall(C_AuctionHouse.QueryOwnedAuctions, {})
		end
	end
	Request()
end

function Auctions.Refresh()
	if Store.UsesSyndicator() then
		return
	end
	if not houseOpen or legacySalePending then
		return
	end
	local now = Now()
	if scan then cancelledScans = cancelledScans + 1 end
	firstQueued = firstQueued or now
	-- Repeated genuine list mutations cannot safely publish a mixed generation.
	-- After two aborted scans wait for the existing quiet window instead of
	-- discarding another staged prefix every maximum-debounce interval.
	scanAt = cancelledScans >= 2 and (now + 0.15) or math.min(now + 0.15, firstQueued + 0.6)
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
	if Builtin.AuctionPurchases then Builtin.AuctionPurchases.Start() end

	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
		if not IsAuctioneer(kind) then
			return
		end
		Open(true)
	end)
	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
		if IsAuctioneer(kind) then
			Close()
		end
	end)
	Flux.Events.Register("AUCTION_HOUSE_SHOW", function()
		Open(false)
	end)
	Flux.Events.Register("AUCTION_HOUSE_CLOSED", Close)
	Flux.Events.Register("AUCTION_OWNED_LIST_UPDATE", function()
		if houseOpen then legacySalePending = false end
		Request()
	end)
	Flux.Events.Register("OWNED_AUCTIONS_UPDATED", function()
		if houseOpen then soldAuctionIDs = nil end
		Request()
	end)
	local notifications = Enum and Enum.AuctionHouseNotification
	local sold = notifications and notifications.AuctionSold
	if sold ~= nil then
		Flux.Events.Register("AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION", function(_, notification, text, auctionID)
			if (issecretvalue and issecretvalue(notification)) or notification ~= sold then return end
			if Cap.hasLegacyAuctionHouse then
				OnLegacyAuctionSold(text)
			else
				OnAuctionSold(auctionID)
			end
		end)
	end
	if Cap.hasLegacyAuctionHouse then
		local pattern = LegacySalePattern()
		if pattern then
			Flux.Events.Register("CHAT_MSG_SYSTEM", function(_, message)
				if Store.UsesSyndicator() or (issecretvalue and issecretvalue(message)) or type(message) ~= "string" then return end
				local itemName = message:match(pattern)
				if itemName then OnLegacyAuctionSold(itemName) end
			end)
		end
	end
end
