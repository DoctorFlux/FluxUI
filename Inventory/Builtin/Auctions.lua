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
local queryAttempted = false
local scanFrame, scan, scanAt, firstQueued, lastList
local cancelledScans = 0

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

local function PrepareRecord(job)
	local i = #job.list
	local rec = job.list[i]
	local old = lastList and lastList[i]
	if not old or old.itemID ~= rec.itemID or old.itemCount ~= rec.itemCount
		or (old.auctionID ~= rec.auctionID
			and tostring(old.auctionID or "") ~= tostring(rec.auctionID or "")) then
		job.changed = true
	end
	local id, n, link = rec.itemID, rec.itemCount, rec.itemLink or rec.link
	if id > 0 then
		local snap = Inv.snapshots.auctions
		local row = snap and snap.byIndex and snap.byIndex[i]
		if not row or row.itemID ~= id or row.count ~= n or row.link ~= link then
			row = { itemID = id, count = n, link = link }
		end
		job.byIndex[i] = row
		job.counts[id] = (job.counts[id] or 0) + n
	end
end

local function ApplyList(job)
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

local function ReadLegacy(index, list, job)
	local info = { GetAuctionItemInfo("owner", index) }
	if scan ~= job or Store.UsesSyndicator() then return end
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
	if not houseOpen then
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
		Request()
	end)
	Flux.Events.Register("OWNED_AUCTIONS_UPDATED", function()
		Request()
	end)
end
