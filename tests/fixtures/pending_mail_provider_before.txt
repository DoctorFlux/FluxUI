-- Inventory/Builtin/Mail.lua — inbox while mailbox is open; outgoing to known alts.
-- MAIL_INBOX_UPDATE is spammy (open, take, take-all). Scan once after it settles,
-- skip empty mails, and never call GetInboxItemLink on the hot path.
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Builtin = Inv.Builtin
local Store = Inv.Store

local Mail = {}
Builtin.Mail = Mail

local started = false
local mailboxOpen = false
local pendingOutgoing
local pendingFrame
local lastFingerprint
local scanFrame
local scan, scanAt, firstQueued
local retryCount = 0
local QUIET_TIME, MAX_WAIT = 0.15, 0.6
local MAX_CALLS_PER_FRAME, BUDGET_MS = 48, 1

local MAIL_EXPIRY = 30 * 24 * 60 * 60
local MAX_SEND = tonumber(_G.ATTACHMENTS_MAX_SEND) or 12

local function MaxReceiveSlots()
	local receive = tonumber(_G.ATTACHMENTS_MAX_RECEIVE)
	local attach = tonumber(_G.ATTACHMENTS_MAX)
	local n = 12
	if receive and receive > n then
		n = receive
	end
	if attach and attach > n then
		n = attach
	end
	return n
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

local function MailHasAttachments(hasItem)
	if hasItem == true then
		return true
	end
	local n = tonumber(hasItem)
	return n and n > 0
end

local function FingerprintList(list)
	if type(list) ~= "table" or #list == 0 then
		return ""
	end
	local parts = {}
	for i = 1, #list do
		local rec = list[i]
		local id = rec and NumericID(rec.itemID)
		if id then
			parts[#parts + 1] = id .. ":" .. (tonumber(rec.itemCount or rec.count) or 1)
		end
	end
	return table.concat(parts, ";")
end

local function ApplyList(list, characterName)
	local snap = Inv.snapshots.mail
	if snap and (not characterName or characterName == Store.GetCurrentCharacterName()) then
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
		local char = characterName and Store.GetCharacter(characterName) or Store.EnsureCurrentCharacter()
		if char then
			char.mail = list
			Store.MarkPending(characterName or Store.GetCurrentCharacterName(), "all")
		end
	end
end

-- GetInboxItem only. GetInboxItemLink hitchs the client on a full inbox.
local function CaptureAttachment(into, mailIndex, attachIndex, expiration)
	if not GetInboxItem then
		return
	end
	local _, itemID, texture, count, quality = GetInboxItem(mailIndex, attachIndex)
	itemID = NumericID(itemID)
	if not itemID then
		return
	end
	-- ID and quantity are sufficient for storage. Asking for item data here
	-- caused auction mail to continually reload metadata and rescan the inbox.
	into[#into + 1] = {
		itemID = itemID,
		itemCount = tonumber(count) or 1,
		iconTexture = texture,
		quality = quality,
		expirationTime = expiration,
	}
	return true
end

function Mail.IsOpen()
	return mailboxOpen and true or false
end

local function Now()
	return (GetTime and GetTime()) or 0
end

local ArmInboxScan
local function StepScan(self)
	-- Readiness can transfer ownership while this scan waits or spans frames.
	if Store.UsesSyndicator() then
		scan, scanAt, firstQueued = nil, nil, nil
		retryCount = 0
		self:SetScript("OnUpdate", nil)
		return
	end
	if Now() < scanAt then return end
	if not scan then
		scan = { list = {}, index = 1, n = GetInboxNumItems() or 0,
			maxAttach = MaxReceiveSlots(), now = (time and time()) or 0 }
		firstQueued = nil
	end
	local job = scan
	local calls, startedAt = 0, debugprofilestop and debugprofilestop()
	while job.index <= job.n and calls < MAX_CALLS_PER_FRAME do
		if not job.attach then
			local daysLeft, hasItem
			if GetInboxHeaderInfo then
				local _, _, _, _, _, _, days, has = GetInboxHeaderInfo(job.index)
				daysLeft, hasItem = days, has
			end
			calls = calls + 1
			if MailHasAttachments(hasItem) then
				job.expiration = job.now + math.floor((tonumber(daysLeft) or 0) * 86400)
				job.attach, job.captured = 1, 0
				job.expected = tonumber(hasItem) or 1
			else
				job.index = job.index + 1
			end
		else
			if CaptureAttachment(job.list, job.index, job.attach, job.expiration) then
				job.captured = job.captured + 1
			end
			calls = calls + 1
			job.attach = job.attach + 1
			if job.attach > job.maxAttach then
				if job.captured < math.min(job.expected, job.maxAttach) then job.incomplete = true end
				job.index, job.attach = job.index + 1, nil
			end
		end
		if startedAt and debugprofilestop() - startedAt >= BUDGET_MS then break end
	end
	if job.index <= job.n then return end
	scan = nil
	self:SetScript("OnUpdate", nil)
	-- Never publish a partial inbox or recurse through Scheduler -> Refresh.
	-- Truly missing IDs get at most two retries, not an expanding timer tree.
	if job.incomplete then
		if mailboxOpen and retryCount < 2 then
			retryCount = retryCount + 1
			ArmInboxScan(nil, true)
			scanAt = Now() + 0.5
		end
		return
	end
	local fp = FingerprintList(job.list)
	if fp ~= lastFingerprint then
		lastFingerprint = fp
		ApplyList(job.list)
		Inv.Notify({ mail = true })
	end
end

ArmInboxScan = function(force, retry)
	if Store.UsesSyndicator() or not GetInboxNumItems or (not mailboxOpen and not force) then return end
	local now = Now()
	firstQueued = firstQueued or now
	scanAt = math.min(now + QUIET_TIME, firstQueued + MAX_WAIT)
	-- An inbox event can shift every mail index. Discard an interrupted scan;
	-- only a complete view from one event generation may become the snapshot.
	scan = nil
	if not retry then retryCount = 0 end
	scanFrame = scanFrame or CreateFrame("Frame")
	scanFrame:SetScript("OnUpdate", StepScan)
end

--- Queue a bounded scan; publication notifies listeners after the snapshot lands.
function Mail.Refresh(opts)
	ArmInboxScan(type(opts) == "table" and opts.force)
	return false
end

local function PersistThenClose()
	if not mailboxOpen then
		return
	end
	-- Finish the last take, even if close arrives before the pending scan starts.
	ArmInboxScan(true)
	mailboxOpen = false
end

local function CaptureSendAttachments()
	local items = {}
	if not GetSendMailItem then
		return items
	end
	local expiration = (time and time() or 0) + MAIL_EXPIRY
	for index = 1, MAX_SEND do
		local _, itemID, icon, count, quality = GetSendMailItem(index)
		itemID = NumericID(itemID)
		if itemID then
			items[#items + 1] = {
				itemID = itemID,
				iconTexture = icon,
				itemCount = tonumber(count) or 1,
				quality = quality,
				expirationTime = expiration,
			}
		end
	end
	return items
end

local function EnsurePendingFrame()
	if pendingFrame then
		return pendingFrame
	end
	pendingFrame = CreateFrame("Frame")
	pendingFrame:SetScript("OnEvent", function(_, event)
		if event == "MAIL_FAILED" then
			pendingOutgoing = nil
			pendingFrame:UnregisterEvent("MAIL_SEND_SUCCESS")
			pendingFrame:UnregisterEvent("MAIL_FAILED")
			pendingFrame:UnregisterEvent("MAIL_SUCCESS")
			return
		end
		if (event == "MAIL_SEND_SUCCESS" or event == "MAIL_SUCCESS") and pendingOutgoing then
			local dest = Store.GetCharacter(pendingOutgoing.recipient)
			if dest then
				dest.mail = dest.mail or {}
				for i = 1, #pendingOutgoing.items do
					dest.mail[#dest.mail + 1] = pendingOutgoing.items[i]
				end
				Store.MarkPending(pendingOutgoing.recipient, "all")
			end
			pendingOutgoing = nil
			pendingFrame:UnregisterEvent("MAIL_SEND_SUCCESS")
			pendingFrame:UnregisterEvent("MAIL_FAILED")
			pendingFrame:UnregisterEvent("MAIL_SUCCESS")
		end
	end)
	return pendingFrame
end

function Mail.Start()
	if started or Store.UsesSyndicator() then
		return
	end
	started = true
	if Flux.Events and Flux.Events.Register then
		Flux.Events.Register("MAIL_SHOW", function()
			mailboxOpen = true
			ArmInboxScan()
		end)
		Flux.Events.Register("MAIL_INBOX_UPDATE", function()
			ArmInboxScan()
		end)
		Flux.Events.Register("MAIL_CLOSED", PersistThenClose)
		Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
			local e = Enum and Enum.PlayerInteractionType
			if e and kind == e.MailInfo then
				mailboxOpen = true
				ArmInboxScan()
			end
		end)
		Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
			local e = Enum and Enum.PlayerInteractionType
			if e and kind == e.MailInfo then
				PersistThenClose()
			end
		end)
	end

	if hooksecurefunc and SendMail then
		hooksecurefunc("SendMail", function(recipient)
			if Store.UsesSyndicator() then
				return
			end
			local full = Store.NormalizeRecipient(recipient)
			if not full or not Store.HasCharacter(full) then
				return
			end
			local items = CaptureSendAttachments()
			if #items == 0 then
				return
			end
			pendingOutgoing = { recipient = full, items = items }
			local f = EnsurePendingFrame()
			f:RegisterEvent("MAIL_SEND_SUCCESS")
			f:RegisterEvent("MAIL_FAILED")
		end)
	end
	if hooksecurefunc and ReturnInboxItem then
		hooksecurefunc("ReturnInboxItem", function(mailIndex)
			if Store.UsesSyndicator() or not GetInboxHeaderInfo then
				return
			end
			local _, _, recipient, _, _, _, daysLeft, hasItem = GetInboxHeaderInfo(mailIndex)
			local full = Store.NormalizeRecipient(recipient)
			if not full or not Store.HasCharacter(full) then
				return
			end
			local items = {}
			if MailHasAttachments(hasItem) then
				local expiration = (time and time() or 0) + math.floor((tonumber(daysLeft) or 30) * 24 * 60 * 60)
				local maxAttach = MaxReceiveSlots()
				for attachIndex = 1, maxAttach do
					CaptureAttachment(items, mailIndex, attachIndex, expiration)
				end
			end
			if #items == 0 then
				return
			end
			pendingOutgoing = { recipient = full, items = items }
			local f = EnsurePendingFrame()
			f:RegisterEvent("MAIL_SUCCESS")
			f:RegisterEvent("MAIL_FAILED")
		end)
	end
end
