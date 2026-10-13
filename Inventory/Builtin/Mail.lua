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
local scanScheduled = false

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

local function Request()
	Flux.Scheduler.Request("inventory", "mail")
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
	-- Check if item data is cached to avoid lag
	if C_Item and C_Item.IsItemDataCachedByID and not C_Item.IsItemDataCachedByID(itemID) then
		-- Item data not cached yet, request it for next scan
		if C_Item.RequestLoadItemDataByID then
			C_Item.RequestLoadItemDataByID(itemID)
		end
		-- Skip this item for now, will be picked up on next scan
		return
	end
	into[#into + 1] = {
		itemID = itemID,
		itemCount = tonumber(count) or 1,
		iconTexture = texture,
		quality = quality,
		expirationTime = expiration,
	}
end

function Mail.IsOpen()
	return mailboxOpen and true or false
end

--- Scan inbox into the mail snapshot. Returns true when the list changed.
--- opts.force: persist even after MAIL_CLOSED so the last take is not dropped.
function Mail.Refresh(opts)
	if Store.UsesSyndicator() then
		return false
	end
	opts = type(opts) == "table" and opts or nil
	if not mailboxOpen and not (opts and opts.force) then
		return false
	end
	if not GetInboxNumItems then
		return false
	end
	local list = {}
	local n = GetInboxNumItems() or 0
	local maxAttach = MaxReceiveSlots()
	local now = (time and time()) or 0
	local hadUncachedItems = false
	for mailIndex = 1, n do
		local daysLeft, hasItem = 0, nil
		if GetInboxHeaderInfo then
			local _, _, _, _, _, _, headerDays, headerHas = GetInboxHeaderInfo(mailIndex)
			daysLeft = headerDays or 0
			hasItem = headerHas
		end
		if MailHasAttachments(hasItem) then
			local expiration = now + math.floor((tonumber(daysLeft) or 0) * 24 * 60 * 60)
			local beforeCount = #list
			for attachIndex = 1, maxAttach do
				CaptureAttachment(list, mailIndex, attachIndex, expiration)
			end
			-- If no items were captured but mail has attachments, data might be uncached
			if #list == beforeCount and C_Item and C_Item.IsItemDataCachedByID then
				hadUncachedItems = true
			end
		end
	end
	-- If we had uncached items, schedule another scan for when they load
	if hadUncachedItems and mailboxOpen then
		if C_Timer and C_Timer.After then
			C_Timer.After(0.5, function()
				if mailboxOpen then
					Mail.Refresh()
					Request()
				end
			end)
		end
	end
	local fp = FingerprintList(list)
	if fp == lastFingerprint then
		return false
	end
	lastFingerprint = fp
	ApplyList(list)
	return true
end

local function EnsureScanFrame()
	if scanFrame then
		return scanFrame
	end
	scanFrame = CreateFrame("Frame")
	scanFrame:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil)
		scanScheduled = false
		Request()
	end)
	return scanFrame
end

local function CancelScheduledScan()
	scanScheduled = false
	if scanFrame then
		scanFrame:SetScript("OnUpdate", nil)
	end
end

local function ArmInboxScan()
	if scanScheduled then
		return
	end
	scanScheduled = true
	local frame = EnsureScanFrame()
	-- Scan on next frame, similar to Syndicator's approach
	frame:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil)
		scanScheduled = false
		Request()
	end)
end

local function PersistThenClose()
	if not mailboxOpen then
		return
	end
	CancelScheduledScan()
	mailboxOpen = false
	-- Defer the final scan to next frame to avoid lag spike on close
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			local changed = Mail.Refresh({ force = true })
			if changed then
				Request()
			end
		end)
	else
		local changed = Mail.Refresh({ force = true })
		if changed then
			Request()
		end
	end
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
		end)
		Flux.Events.Register("MAIL_INBOX_UPDATE", function()
			mailboxOpen = true
			ArmInboxScan()
		end)
		Flux.Events.Register("MAIL_CLOSED", PersistThenClose)
		Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
			local e = Enum and Enum.PlayerInteractionType
			if e and kind == e.MailInfo then
				mailboxOpen = true
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
