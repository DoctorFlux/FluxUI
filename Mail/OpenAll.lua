-- Postal-style Open All placement with Flux-owned filtering and native take actions.
local _, ns = ...
local Flux = ns.Flux
local Mail = Flux.Mail or {}
Flux.Mail = Mail

local button, menuButton
local opened = false

local subjectGlobals = {
	AHCancelled = "AUCTION_REMOVED_MAIL_SUBJECT",
	AHExpired = "AUCTION_EXPIRED_MAIL_SUBJECT",
	AHOutbid = "AUCTION_OUTBID_MAIL_SUBJECT",
	AHSuccess = "AUCTION_SOLD_MAIL_SUBJECT",
	AHWon = "AUCTION_WON_MAIL_SUBJECT",
}

local function SubjectIs(subject, template)
	if type(subject) ~= "string" or type(template) ~= "string" then return false end
	local start, pos, wildcard = 1, 1, false
	while true do
		local marker = template:find("%s", start, true)
		local token = marker and template:sub(start, marker - 1) or template:sub(start)
		if token ~= "" then
			local at = subject:find(token, pos, true)
			if not at then return false end
			if start == 1 and at ~= 1 then return false end
			pos = at + #token
		end
		if not marker then return (token == "" and wildcard) or pos > #subject end
		wildcard = true
		start = marker + 2
	end
end

local function MailType(subject)
	for key, global in pairs(subjectGlobals) do
		if SubjectIs(subject, _G[global]) then return key end
	end
	return "NonAHMail"
end
Mail.GetMailType = MailType

local function Header(index)
	local _, _, sender, subject, money, cod, _, items, _, _, _, _, isGM = GetInboxHeaderInfo(index)
	if not sender and not subject then return nil end
	return { sender = sender or "", subject = subject or "", money = tonumber(money) or 0,
		cod = tonumber(cod) or 0, items = tonumber(items) or 0, gm = isGM == true }
end

local function Eligible(header, override)
	if not header or header.gm or header.cod > 0 or (header.money == 0 and header.items == 0) then return false end
	if override then return true end
	local kind = MailType(header.subject)
	if kind ~= "NonAHMail" then return Mail.GetSetting("OpenAll", kind) ~= false end
	if Mail.GetSetting("OpenAll", "Attachments") ~= false then return true end
	if Mail.GetSetting("OpenAll", "Postmaster") ~= false then
		local postmaster = _G.POSTMASTER or "The Postmaster"
		if header.items > 0 and (header.sender:find(postmaster, 1, true)
			or header.sender:find("Thaumaturge Vashreen", 1, true)) then return true end
	end
	return false
end

local function UpdateButton()
	local enabled = Mail.IsEnabled and Mail.IsEnabled("OpenAll")
	if button then
		button:SetShown(opened and enabled)
		button:SetText(Mail.openAllRunning and "In Progress" or "Open All")
	end
	if menuButton then menuButton:SetShown(opened and enabled) end
	if OpenAllMail then OpenAllMail:SetShown(opened and not enabled) end
end

function Mail.OpenAll()
	if not opened or not Mail.IsEnabled("OpenAll") or not GetInboxNumItems or not GetInboxHeaderInfo then return end
	local count = GetInboxNumItems() or 0
	local override = IsShiftKeyDown and IsShiftKeyDown() or false
	local list = {}
	for i = count, 1, -1 do
		local header = Header(i)
		if Eligible(header, override) then list[#list + 1] = { index = i, header = header } end
	end
	if #list == 0 then return end
	Mail.ProcessSelected("take", list, "OpenAll")
end

local previousStateChanged = Mail.OnJobStateChanged
Mail.OnJobStateChanged = function(running, group, message)
	if previousStateChanged then previousStateChanged(running, group, message) end
	if group == "OpenAll" then
		Mail.openAllRunning = running
		UpdateButton()
	end
end

local function Install()
	if button or not InboxFrame then return end
	button = CreateFrame("Button", "FluxMailOpenAllButton", InboxFrame, "UIPanelButtonTemplate")
	button:SetSize(120, 25)
	button:SetPoint("CENTER", InboxFrame, "TOP", -36, -399)
	if OpenAllMail and OpenAllMail.GetFrameLevel then button:SetFrameLevel(OpenAllMail:GetFrameLevel() + 1) end
	button:SetScript("OnClick", Mail.OpenAll)
	menuButton = CreateFrame("Button", "FluxMailOpenAllMenuButton", InboxFrame)
	menuButton:SetSize(30, 30)
	menuButton:SetPoint("LEFT", button, "RIGHT", -2, 0)
	menuButton:SetFrameLevel(button:GetFrameLevel() + 1)
	menuButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	menuButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Round")
	menuButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
	menuButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	menuButton:SetScript("OnClick", function(self) if Mail.OpenModuleMenu then Mail.OpenModuleMenu(self, "OpenAll") end end)
	if hooksecurefunc then
		if type(InboxFrame_Update) == "function" then hooksecurefunc("InboxFrame_Update", UpdateButton) end
		if type(InboxFrame.Update) == "function" then hooksecurefunc(InboxFrame, "Update", UpdateButton) end
	end
	UpdateButton()
end

if Mail.OnSettingsChanged then
	Mail.OnSettingsChanged(function(group, key)
		if group == "Modules" and key == "OpenAll" then UpdateButton() end
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
		opened = true
		Install()
		UpdateButton()
		if not button and C_Timer and C_Timer.After then C_Timer.After(0, Install) end
	elseif event == "MAIL_INBOX_UPDATE" then
		UpdateButton()
	elseif event == "MAIL_CLOSED" or (mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and interactionType == mailType) then
		opened = false
		UpdateButton()
	end
end)
