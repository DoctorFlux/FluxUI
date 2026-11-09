-- Mail text copy, money subject, and session earnings. Blizzard owns send/take actions.
local _, ns = ...
local Flux = ns.Flux
local Mail = Flux.Mail or {}
Flux.Mail = Mail

local eventFrame = CreateFrame("Frame")
local copyButton, forwardButton, copyFrame, copyEdit
local moneyHooked = false
local autoSubject
local startMoney

local function Notice(message)
	if Mail.Print then Mail.Print(message); return end
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cff70d7ffFlux Mail:|r " .. message)
	end
end

local function MoneySubject(copper)
	copper = tonumber(copper) or 0
	if copper <= 0 then return "" end
	local gold = math.floor(copper / 10000)
	local silver = math.floor(copper / 100) % 100
	local coin = copper % 100
	if gold > 0 then return string.format("[%dg %ds %dc]", gold, silver, coin) end
	if silver > 0 then return string.format("[%ds %dc]", silver, coin) end
	return string.format("[%dc]", coin)
end
Mail.MoneySubject = MoneySubject

local function UpdateMoneySubject()
	if Mail.IsEnabled and not Mail.IsEnabled("Wire") then return end
	if not SendMailSubjectEditBox or not SendMailMoney or not MoneyInputFrame_GetCopper then return end
	local current = SendMailSubjectEditBox:GetText()
	if current ~= "" and current ~= autoSubject then return end
	local wanted = MoneySubject(MoneyInputFrame_GetCopper(SendMailMoney))
	if wanted ~= current then SendMailSubjectEditBox:SetText(wanted) end
	autoSubject = wanted
end

local function HookMoney()
	if moneyHooked or not SendMailMoney or not hooksecurefunc then return end
	if type(SendMailMoney.onValueChangedFunc) == "function" then
		hooksecurefunc(SendMailMoney, "onValueChangedFunc", UpdateMoneySubject)
		moneyHooked = true
	end
end

local function CopyText()
	if not InboxFrame or not GetInboxText or not GetInboxHeaderInfo then return nil end
	local index = InboxFrame.openMailID
	if type(index) ~= "number" or index < 1 then return nil end
	local _, _, sender, subject = GetInboxHeaderInfo(index)
	if not sender and not subject then return nil end
	local body, _, _, _, isInvoice = GetInboxText(index)
	if not body and not isInvoice then return nil end
	local text = (FROM or "From:") .. " " .. (sender or UNKNOWN or "Unknown") .. "\n"
		.. (MAIL_SUBJECT_LABEL or "Subject:") .. " " .. (subject or "") .. "\n\n" .. (body or "")
	if isInvoice and GetInboxInvoiceInfo then
		local invoiceType, itemName, playerName, bid, buyout, deposit, consignment = GetInboxInvoiceInfo(index)
		text = text .. "\n\n" .. (invoiceType or "Invoice") .. ": " .. (itemName or "")
		if playerName then text = text .. " — " .. playerName end
		if bid then text = text .. "\nAmount: " .. tostring(bid) end
		if buyout then text = text .. "\nBuyout: " .. tostring(buyout) end
		if deposit then text = text .. "\nDeposit: " .. tostring(deposit) end
		if consignment then text = text .. "\nFee: " .. tostring(consignment) end
	end
	return text
end
Mail.GetCopyText = CopyText

local function CreateCopyFrame()
	if copyFrame then return end
	copyFrame = CreateFrame("Frame", "FluxMailCopyFrame", UIParent)
	copyFrame:SetSize(430, 330)
	copyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	copyFrame:SetFrameStrata("DIALOG")
	copyFrame:EnableMouse(true)
	copyFrame:SetMovable(true)
	copyFrame:RegisterForDrag("LeftButton")
	copyFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	copyFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	local background = copyFrame:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0.05, 0.06, 0.08, 0.98)
	local title = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 14, -14)
	title:SetText("Copy mail text (Ctrl+C)")
	local close = CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -3, -3)
	close:SetScript("OnClick", function() copyFrame:Hide() end)
	copyEdit = CreateFrame("EditBox", nil, copyFrame)
	copyEdit:SetPoint("TOPLEFT", 14, -42)
	copyEdit:SetSize(400, 272)
	copyEdit:SetMultiLine(true)
	copyEdit:SetAutoFocus(false)
	copyEdit:SetFontObject(ChatFontNormal)
	copyEdit:SetTextInsets(4, 4, 4, 4)
	copyEdit:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
	copyFrame:Hide()
end

local function UpdateCopyButton()
	local copyEnabled = not Mail.IsEnabled or Mail.IsEnabled("CarbonCopy")
	local forwardEnabled = not Mail.IsEnabled or Mail.IsEnabled("Forward")
	local visible = false
	if OpenMailFrame then
		if OpenMailFrame.IsVisible then visible = OpenMailFrame:IsVisible()
		elseif OpenMailFrame.IsShown then visible = OpenMailFrame:IsShown() end
	end
	if not visible or (not copyEnabled and not forwardEnabled) then
		if copyButton then copyButton:Hide() end
		if forwardButton then forwardButton:Hide() end
		return
	end

	local available = false
	local money, cod, items
	local index = InboxFrame and InboxFrame.openMailID
	if type(index) == "number" and index > 0 and GetInboxHeaderInfo and GetInboxText then
		local _, _, sender, subject, headerMoney, headerCOD, _, headerItems = GetInboxHeaderInfo(index)
		money, cod, items = headerMoney, headerCOD, headerItems
		if sender or subject then
			local body, _, _, _, isInvoice = GetInboxText(index)
			available = not not (body or isInvoice)
		end
	end
	-- Availability needs no invoice expansion or copy string. Build fresh text
	-- only when the user requests Copy, and reuse this header for Forward.
	if copyButton then copyButton:SetShown(available and copyEnabled) end
	if forwardButton then
		forwardButton:SetShown(available and forwardEnabled)
		forwardButton:SetEnabled(available and forwardEnabled and (tonumber(money) or 0) == 0
			and (tonumber(cod) or 0) == 0 and (tonumber(items) or 0) == 0)
	end
end

function Mail.ForwardOpenText()
	if not InboxFrame or not GetInboxHeaderInfo or not GetInboxText then return false end
	local index = InboxFrame.openMailID
	if not index then return false end
	local body = GetInboxText(index)
	if type(body) ~= "string" then return false end
	if #body > 500 then
		Notice("This message is too long to forward as mail text; use Copy instead.")
		return false
	end
	local _, _, _, subject = GetInboxHeaderInfo(index)
	if not Mail.FillDraft or not Mail.FillDraft(nil, subject or "", body) then
		Notice("The outgoing draft is not empty. Clear it before forwarding text.")
		return false
	end
	if MailFrameTab_OnClick and MailFrameTab2 then MailFrameTab_OnClick(MailFrameTab2, 2) end
	if OpenMailFrame and HideUIPanel then HideUIPanel(OpenMailFrame) end
	return true
end

local function CreateCopyButton()
	if copyButton or not OpenMailFrame then return end
	copyButton = CreateFrame("Button", "FluxMailCopyButton", OpenMailScrollFrame or OpenMailFrame)
	copyButton:SetSize(10, 10)
	copyButton:SetPoint("TOPRIGHT", OpenMailScrollFrame or OpenMailFrame, "TOPRIGHT", 0, 0)
	copyButton:SetNormalTexture(135994)
	copyButton:SetScript("OnEnter", function(self) self:SetSize(28, 28) end)
	copyButton:SetScript("OnLeave", function(self) self:SetSize(10, 10) end)
	copyButton:SetScript("OnClick", function()
		local text = CopyText()
		if not text then return end
		CreateCopyFrame()
		copyEdit:SetText(text)
		copyFrame:Show()
		copyEdit:HighlightText()
		copyEdit:SetFocus()
	end)
	forwardButton = CreateFrame("Button", "FluxMailForwardTextButton", OpenMailFrame, "UIPanelButtonTemplate")
	forwardButton:SetSize(82, 22)
	forwardButton:SetPoint("RIGHT", OpenMailReplyButton or OpenMailFrame, "LEFT", 0, 0)
	forwardButton:SetText("Forward")
	forwardButton:SetScript("OnClick", Mail.ForwardOpenText)
	OpenMailFrame:HookScript("OnShow", UpdateCopyButton)
	UpdateCopyButton()
end

if Mail.OnSettingsChanged then
	Mail.OnSettingsChanged(function(group, key)
		if group == "Modules" and (key == "CarbonCopy" or key == "Forward") then UpdateCopyButton() end
	end)
end

eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
eventFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:RegisterEvent("MAIL_SEND_SUCCESS")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, interactionType)
	local interaction = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
	if event == "MAIL_SHOW" or (interaction and event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and interactionType == interaction) then
		if (not Mail.IsEnabled or Mail.IsEnabled("Rake")) and not startMoney and GetMoney then startMoney = tonumber(GetMoney()) end
		HookMoney()
		CreateCopyButton()
		if not copyButton and C_Timer and C_Timer.After then
			C_Timer.After(0, function() HookMoney(); CreateCopyButton() end)
		end
		UpdateCopyButton()
	elseif event == "MAIL_INBOX_UPDATE" then
		if OpenMailFrame and OpenMailFrame:IsShown() then UpdateCopyButton() end
	elseif event == "MAIL_SEND_SUCCESS" then
		autoSubject = nil
	elseif event == "MAIL_CLOSED" or event == "PLAYER_LEAVING_WORLD" or
		(interaction and event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and interactionType == interaction) then
		if event ~= "PLAYER_LEAVING_WORLD" and startMoney and GetMoney
			and (not Mail.IsEnabled or Mail.IsEnabled("Rake")) then
			local gained = (tonumber(GetMoney()) or startMoney) - startMoney
			if gained > 0 then
				local amount = GetCoinTextureString and GetCoinTextureString(gained) or tostring(gained) .. " copper"
				Notice("Collected " .. amount .. " this mailbox visit.")
			end
		end
		startMoney = nil
		autoSubject = nil
		if copyFrame then copyFrame:Hide() end
	end
end)
