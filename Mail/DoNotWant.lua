-- Inbox expiry action icons. The native mailbox API owns return and delete.
local _, ns = ...
local Mail = ns.Flux.Mail
local icons = {}
local open = false
local pending

local function Index(row)
	return ((tonumber(InboxFrame and InboxFrame.pageNum) or 1) - 1)
		* (INBOXITEMS_TO_DISPLAY or 7) + row
end

local function Refresh()
	local enabled = open and (not Mail.IsEnabled or Mail.IsEnabled("DoNotWant"))
	local count = GetInboxNumItems and GetInboxNumItems() or 0
	for row = 1, #icons do
		local icon = icons[row]
		local index = Index(row)
		local visible = enabled and index <= count
		icon:SetShown(visible)
		if visible and InboxItemCanDelete then
			local canDelete = InboxItemCanDelete(index)
			icon.texture:SetTexture(canDelete and "Interface\\RaidFrame\\ReadyCheck-NotReady"
				or "Interface\\ChatFrame\\ChatFrameExpandArrow")
			icon.tooltip = canDelete and (DELETE or "Delete") or (MAIL_RETURN or "Return")
		end
	end
end

if StaticPopupDialogs then
	StaticPopupDialogs.FLUX_MAIL_DELETE_CONFIRM = {
		text = DELETE_MAIL_CONFIRMATION or "Delete this mail?",
		button1 = ACCEPT or "Accept", button2 = CANCEL or "Cancel",
		showAlert = 1, timeout = 0, hideOnEscape = 1,
		OnAccept = function()
			if pending and open and DeleteInboxItem and GetInboxHeaderInfo then
				local _, _, sender, subject, money, _, _, items = GetInboxHeaderInfo(pending.index)
				if sender == pending.sender and subject == pending.subject
					and money == pending.money and items == pending.items then
					DeleteInboxItem(pending.index)
				end
			end
			pending = nil
		end,
		OnCancel = function() pending = nil end,
	}
end

local function Activate(row)
	if not open then return end
	local index = Index(row)
	if not GetInboxHeaderInfo then return end
	local _, _, sender, subject = GetInboxHeaderInfo(index)
	if not sender and not subject then return end
	if InboxItemCanDelete and InboxItemCanDelete(index) then
		local _, _, _, _, money, _, _, items = GetInboxHeaderInfo(index)
		if (tonumber(money) or 0) > 0 or (tonumber(items) or 0) > 0 then
			pending = { index = index, sender = sender, subject = subject, money = money, items = items }
			if StaticPopup_Show then StaticPopup_Show("FLUX_MAIL_DELETE_CONFIRM") end
		elseif DeleteInboxItem then
			DeleteInboxItem(index)
		end
	elseif ReturnInboxItem then
		ReturnInboxItem(index)
	end
end

local function Install()
	if #icons > 0 or not InboxFrame then return end
	for row = 1, (INBOXITEMS_TO_DISPLAY or 7) do
		local expiry = _G["MailItem" .. row .. "ExpireTime"]
		if expiry then
			local icon = CreateFrame("Button", "FluxMailExpiryAction" .. row, expiry)
			icon:SetSize(16, 16)
			icon:SetPoint("TOPRIGHT", expiry, "BOTTOMRIGHT", -5, -1)
			icon.texture = icon:CreateTexture(nil, "BACKGROUND")
			icon.texture:SetAllPoints()
			icon.texture:SetTexCoord(1, 0, 0, 1)
			icon:SetScript("OnClick", function() Activate(row) end)
			icon:SetScript("OnEnter", function(self)
				if GameTooltip then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.tooltip or ""); GameTooltip:Show() end
			end)
			icon:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
			icons[row] = icon
		end
	end
	if hooksecurefunc then
		if type(InboxFrame_Update) == "function" then hooksecurefunc("InboxFrame_Update", Refresh) end
		if type(InboxFrame.Update) == "function" then hooksecurefunc(InboxFrame, "Update", Refresh) end
	end
	Refresh()
end

if Mail.OnSettingsChanged then
	Mail.OnSettingsChanged(function(group, key)
		if group == "Modules" and key == "DoNotWant" then Refresh() end
	end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("MAIL_INBOX_UPDATE")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
frame:SetScript("OnEvent", function(_, event, interactionType)
	local mailType = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
	if event == "MAIL_SHOW" or (mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and interactionType == mailType) then
		open = true
		Install()
		Refresh()
		if #icons == 0 and C_Timer and C_Timer.After then C_Timer.After(0, Install) end
	elseif event == "MAIL_CLOSED" or (mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and interactionType == mailType) then
		open = false
		pending = nil
		Refresh()
	elseif event == "MAIL_INBOX_UPDATE" then
		pending = nil
		Refresh()
	end
end)
