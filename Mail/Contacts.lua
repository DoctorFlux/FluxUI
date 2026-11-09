-- Flux-owned contacts and recent recipients. The native mail autocomplete stays intact.
local _, ns = ...
local Flux = ns.Flux
local Mail = Flux.Mail or {}
Flux.Mail = Mail

local frame = CreateFrame("Frame")
local picker, popup, rows, dropdown
local offset = 0
local pendingRecipient
local pendingDraft
local MAX_RECENT = 20
local PAGE_SIZE = 8

local function DB()
	if type(FluxMailDB) ~= "table" then FluxMailDB = {} end
	local db = FluxMailDB
	if type(db.contacts) ~= "table" then db.contacts = {} end
	if type(db.recent) ~= "table" then db.recent = {} end
	if type(db.alts) ~= "table" then db.alts = {} end
	return db
end

local function CleanName(name)
	if type(name) ~= "string" then return nil end
	name = name:match("^%s*(.-)%s*$")
	if name == "" or #name > 77 or name:find("[%c|]", 1) then return nil end
	return name
end

local function Key(name)
	return name:lower()
end

local function CurrentRecipient()
	return SendMailNameEditBox and CleanName(SendMailNameEditBox:GetText())
end

local function IsSelf(name)
	local store = Flux.Inventory and Flux.Inventory.Store
	local selfName = store and store.GetCharacterFullName and store.GetCharacterFullName()
	if selfName then
		return Key(name) == Key(selfName)
	end
	return false
end

function Mail.AddContact(name)
	name = CleanName(name)
	if not name or IsSelf(name) then return false end
	DB().contacts[Key(name)] = name
	return true
end

function Mail.RemoveContact(name)
	name = CleanName(name)
	if not name then return false end
	DB().contacts[Key(name)] = nil
	return true
end

function Mail.RecordRecipient(name)
	name = CleanName(name)
	if not name then return false end
	local recent = DB().recent
	for i = #recent, 1, -1 do
		if type(recent[i]) ~= "string" or Key(recent[i]) == Key(name) then
			table.remove(recent, i)
		end
	end
	table.insert(recent, 1, name)
	while #recent > MAX_RECENT do table.remove(recent) end
	return true
end

local function KnownAlts()
	local db = DB()
	local store = Flux.Inventory and Flux.Inventory.Store
	if store and store.GetAllCharacters then
		local known = store.GetAllCharacters()
		for i = 1, #known do
			local name = CleanName(known[i])
			if name then db.alts[Key(name)] = name end
		end
	end
	local names = {}
	for _, name in pairs(db.alts) do
		if not IsSelf(name) then names[#names + 1] = name end
	end
	table.sort(names)
	return names
end

function Mail.GetRecipients()
	local db = DB()
	local result, seen = {}, {}
	local function Add(name, source)
		name = CleanName(name)
		if not name or IsSelf(name) or seen[Key(name)] then return end
		seen[Key(name)] = true
		result[#result + 1] = { name = name, source = source }
	end
	for i = 1, #db.recent do Add(db.recent[i], "Recent") end
	local contacts = {}
	for _, name in pairs(db.contacts) do contacts[#contacts + 1] = name end
	table.sort(contacts)
	for i = 1, #contacts do Add(contacts[i], "Contact") end
	local alts = KnownAlts()
	for i = 1, #alts do Add(alts[i], "Alt") end
	return result
end

local function SelectRecipient(name)
	if not SendMailNameEditBox then return end
	SendMailNameEditBox:SetText(name)
	SendMailNameEditBox:SetCursorPosition(#name)
	if popup then popup:Hide() end
	if SendMailSubjectEditBox then SendMailSubjectEditBox:SetFocus() end
end

local function BodyField()
	return SendMailBodyEditBox or MailEditBox
end

local function BodyText()
	local field = BodyField()
	if not field then return "" end
	if field.GetInputText then return field:GetInputText() or "" end
	return field:GetText() or ""
end

function Mail.FillDraft(recipient, subject, body)
	if not SendMailNameEditBox or not SendMailSubjectEditBox or not BodyField() then return false end
	if SendMailNameEditBox:GetText() ~= "" or SendMailSubjectEditBox:GetText() ~= "" or BodyText() ~= "" then
		return false
	end
	if recipient then SendMailNameEditBox:SetText(recipient) end
	SendMailSubjectEditBox:SetText(subject or "")
	BodyField():SetText(body or "")
	if SendMailNameEditBox.SetFocus then SendMailNameEditBox:SetFocus() end
	return true
end

local function RefreshPopup()
	if not popup or not popup:IsShown() then return end
	local entries = Mail.GetRecipients()
	local current = CurrentRecipient()
	local db = DB()
	local actions = {}
	if db.lastSend and type(db.lastSend) == "table" then
		actions[#actions + 1] = { text = "Use last sent text", action = function()
			if Mail.FillDraft(db.lastSend.recipient, db.lastSend.subject, db.lastSend.body) then
				popup:Hide()
			end
		end }
	end
	if current and not IsSelf(current) then
		if db.contacts[Key(current)] then
			actions[#actions + 1] = { text = "Remove contact: " .. current, action = function() Mail.RemoveContact(current); RefreshPopup() end }
		else
			actions[#actions + 1] = { text = "Save contact: " .. current, action = function() Mail.AddContact(current); RefreshPopup() end }
		end
	end
	local all = {}
	for i = 1, #actions do all[#all + 1] = actions[i] end
	for i = 1, #entries do
		local entry = entries[i]
		all[#all + 1] = { text = entry.source .. ": " .. entry.name,
			action = function() SelectRecipient(entry.name) end }
	end
	if offset > math.max(0, #all - PAGE_SIZE) then offset = math.max(0, #all - PAGE_SIZE) end
	for i = 1, PAGE_SIZE do
		local row = rows[i]
		local entry = all[i + offset]
		if entry then
			row:SetText(entry.text)
			row.action = entry.action
			row:Show()
		else
			row.action = nil
			row:Hide()
		end
	end
	popup.total = #all
	popup:SetHeight(math.max(1, math.min(PAGE_SIZE, #all)) * 21 + 12)
end

local function CreatePicker()
	if picker or not SendMailFrame or not SendMailNameEditBox then return end
	picker = CreateFrame("Button", "FluxMailContactsButton", SendMailFrame)
	picker:SetSize(25, 25)
	picker:SetPoint("RIGHT", SendMailNameEditBox, "RIGHT", -2, 2)
	picker:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	picker:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Round")
	picker:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
	picker:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	if UIDropDownMenu_Initialize then
		dropdown = CreateFrame("Frame", "FluxMailContactsDropdown", UIParent, "UIDropDownMenuTemplate")
		dropdown.displayMode = "MENU"
		UIDropDownMenu_Initialize(dropdown, function(_, level)
			local function Add(text, value, action, arrow)
				local info = UIDropDownMenu_CreateInfo()
				info.text, info.value, info.func = text, value, action
				info.notCheckable, info.hasArrow = true, arrow
				UIDropDownMenu_AddButton(info, level)
			end
			if level == 1 then
				Add("BlackBook", nil, nil, false)
				local name = CurrentRecipient()
				if name and not IsSelf(name) then
					if DB().contacts[Key(name)] then
						Add("Remove contact: " .. name, nil, function() Mail.RemoveContact(name) end)
					else
						Add("Save contact: " .. name, nil, function() Mail.AddContact(name) end)
					end
				end
				Add("Contacts", "Contact", nil, true)
				Add("Recently Mailed", "Recent", nil, true)
				Add("Alts", "Alt", nil, true)
				Add(CLOSE or "Close", nil, function() if CloseDropDownMenus then CloseDropDownMenus() end end)
			elseif level == 2 then
				local source = UIDROPDOWNMENU_MENU_VALUE
				for _, entry in ipairs(Mail.GetRecipients()) do
					if entry.source == source then
						local name = entry.name
						Add(name, nil, function() SelectRecipient(name) end)
					end
				end
			end
		end, "MENU")
	end
	picker:SetScript("OnClick", function()
		if dropdown and ToggleDropDownMenu then
			ToggleDropDownMenu(1, nil, dropdown, picker:GetName(), 0, 0)
		elseif popup:IsShown() then popup:Hide() else offset = 0; popup:Show(); RefreshPopup() end
	end)
	picker:SetScript("OnEnter", function(self)
		if not GameTooltip then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Recent recipients, saved contacts and known alts")
		GameTooltip:Show()
	end)
	picker:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

	popup = CreateFrame("Frame", "FluxMailContactsPopup", SendMailFrame)
	popup:SetSize(204, 180)
	popup:SetPoint("TOPLEFT", SendMailNameEditBox, "BOTTOMLEFT", 0, -2)
	popup:SetFrameStrata("DIALOG")
	popup:EnableMouse(true)
	popup:EnableMouseWheel(true)
	local background = popup:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0.06, 0.07, 0.09, 0.96)
	rows = {}
	for i = 1, PAGE_SIZE do
		local row = CreateFrame("Button", nil, popup)
		row:SetSize(196, 20)
		row:SetPoint("TOPLEFT", popup, "TOPLEFT", 4, -6 - (i - 1) * 21)
		row:SetNormalFontObject(GameFontNormalSmall)
		row:SetHighlightFontObject(GameFontHighlightSmall)
		row:SetScript("OnClick", function(self) if self.action then self.action() end end)
		rows[i] = row
	end
	popup:SetScript("OnMouseWheel", function(_, delta)
		offset = math.max(0, math.min(math.max(0, (popup.total or 0) - PAGE_SIZE), offset - delta))
		RefreshPopup()
	end)
	popup:Hide()
	picker:SetShown(not Mail.IsEnabled or Mail.IsEnabled("BlackBook"))
end

if Mail.OnSettingsChanged then
	Mail.OnSettingsChanged(function(group, key)
		if picker and group == "Modules" and key == "BlackBook" then picker:SetShown(Mail.IsEnabled("BlackBook")) end
	end)
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
frame:RegisterEvent("MAIL_SEND_SUCCESS")
frame:RegisterEvent("MAIL_FAILED")
frame:SetScript("OnEvent", function(_, event, interactionType)
	if event == "PLAYER_LOGIN" then
		local store = Flux.Inventory and Flux.Inventory.Store
		local name = store and store.GetCharacterFullName and store.GetCharacterFullName()
		name = CleanName(name)
		if name then DB().alts[Key(name)] = name end
	elseif event == "MAIL_SHOW" or (event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW"
		and Enum and Enum.PlayerInteractionType and interactionType == Enum.PlayerInteractionType.MailInfo) then
		CreatePicker()
		if not picker and C_Timer and C_Timer.After then C_Timer.After(0, CreatePicker) end
	elseif event == "MAIL_CLOSED" or event == "MAIL_FAILED" or
		(event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and Enum and Enum.PlayerInteractionType
			and interactionType == Enum.PlayerInteractionType.MailInfo) then
		pendingRecipient = nil
		pendingDraft = nil
		if popup then popup:Hide() end
	elseif event == "MAIL_SEND_SUCCESS" then
		if pendingRecipient then Mail.RecordRecipient(pendingRecipient) end
		if pendingDraft then DB().lastSend = pendingDraft end
		pendingRecipient = nil
		pendingDraft = nil
		if popup then RefreshPopup() end
	end
end)

-- Capture the actual send argument before Blizzard clears the edit box on success.
if hooksecurefunc then
	hooksecurefunc("SendMail", function(recipient, subject, body)
		pendingRecipient = CleanName(recipient)
		pendingDraft = pendingRecipient and { recipient = pendingRecipient,
			subject = type(subject) == "string" and subject or "",
			body = type(body) == "string" and body or "" } or nil
	end)
end
