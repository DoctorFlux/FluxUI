-- Flux mail preferences and the mailbox dropdown. Uses Blizzard dropdown chrome.
local _, ns = ...
local Flux = ns.Flux
local Mail = Flux.Mail or {}
Flux.Mail = Mail

local defaults = {
	OpenSpeed = 0.5, ChatOutput = 1,
	Profile = { Default = false },
	Select = { KeepFreeSpace = 1, SpamChat = true },
	OpenAll = { KeepFreeSpace = 1, SpamChat = true, AHCancelled = true,
		AHExpired = true, AHOutbid = true, AHSuccess = true, AHWon = true,
		Postmaster = true, Attachments = true },
	Express = { EnableAltClick = true, AutoSend = true, BulkSend = true,
		MouseWheel = true, MultiItemTooltip = true },
	BlackBook = { AutoFill = true, UseAutoComplete = true,
		AutoCompleteAlts = true, AutoCompleteAllAlts = true,
		AutoCompleteRecent = true, AutoCompleteContacts = true,
		AutoCompleteFriends = true, AutoCompleteGuild = true,
		ExcludeRandoms = true, DisableBlizzardAutoComplete = false },
	QuickAttach = { EnableBag0 = true, EnableBag1 = true, EnableBag2 = true,
		EnableBag3 = true, EnableBag4 = true, EnableBag5 = true },
}
local modules = { "Express", "OpenAll", "Wire", "Select", "TradeBlock", "Rake",
	"BlackBook", "DoNotWant", "CarbonCopy", "Forward", "QuickAttach" }
local keepFreeChoices = { 0, 1, 2, 3, 5, 10, 15, 20, 25, 30 }
local configurable = { Express = true, OpenAll = true, Select = true,
	BlackBook = true, QuickAttach = true }
local listeners = {}
local function CopyTable(source)
	local copy = {}
	if type(source) ~= "table" then return copy end
	for key, value in pairs(source) do
		copy[key] = type(value) == "table" and CopyTable(value) or value
	end
	return copy
end

local function NotifyProfile()
	for i = 1, #modules do
		for j = 1, #listeners do listeners[j]("Modules", modules[i]) end
	end
end

local function Root()
	if type(FluxMailDB) ~= "table" then FluxMailDB = {} end
	if type(FluxMailDB.settings) ~= "table" then FluxMailDB.settings = {} end
	if type(FluxMailDB.profiles) ~= "table" then FluxMailDB.profiles = {} end
	if type(FluxMailDB.profileName) ~= "string" then FluxMailDB.profileName = "Default" end
	return FluxMailDB
end

local function DB()
	return Root().settings
end

function Mail.GetProfileName() return Root().profileName end

function Mail.SwitchProfile(name)
	if type(name) ~= "string" or name == "" or #name > 50 then return false end
	local root = Root()
	if name == root.profileName then return true end
	root.profiles[root.profileName] = CopyTable(root.settings)
	root.settings = CopyTable(root.profiles[name])
	root.profileName = name
	NotifyProfile()
	return true
end

function Mail.CopyProfile(name)
	local root = Root()
	if name == root.profileName or type(root.profiles[name]) ~= "table" then return false end
	root.settings = CopyTable(root.profiles[name])
	NotifyProfile()
	return true
end

function Mail.ResetProfile()
	Root().settings = {}
	NotifyProfile()
end

function Mail.DeleteProfile(name)
	local root = Root()
	if name == root.profileName or name == "Default" or not root.profiles[name] then return false end
	root.profiles[name] = nil
	return true
end

function Mail.GetSetting(group, key)
	if group == "Profile" and key == "Default" then return Root().useDefaultProfile == true end
	local db = DB()
	if key == nil then
		if db[group] ~= nil then return db[group] end
		return defaults[group]
	end
	local saved = db[group]
	if type(saved) == "table" and saved[key] ~= nil then return saved[key] end
	return defaults[group] and defaults[group][key]
end

function Mail.SetSetting(group, key, value)
	if group == "Profile" and key == "Default" then
		Root().useDefaultProfile = value == true
		if value then Mail.SwitchProfile("Default") end
		for i = 1, #listeners do listeners[i](group, key, value) end
		return
	end
	local db = DB()
	if key == nil then
		db[group] = value
	else
		if type(db[group]) ~= "table" then db[group] = {} end
		db[group][key] = value
	end
	for i = 1, #listeners do listeners[i](group, key, value) end
end

function Mail.IsEnabled(module)
	return Mail.GetSetting("Modules", module) ~= false
end

function Mail.Print(message)
	local index = tonumber(Mail.GetSetting("ChatOutput")) or 1
	local chat = _G["ChatFrame" .. index] or DEFAULT_CHAT_FRAME
	if chat and chat.AddMessage then chat:AddMessage("|cff70d7ffFlux Mail:|r " .. tostring(message)) end
end

function Mail.OnSettingsChanged(fn)
	if type(fn) == "function" then listeners[#listeners + 1] = fn end
end

local button, dropdown, openAllDropdown
function Mail.OpenSettingsMenu(anchor)
	if dropdown and ToggleDropDownMenu and anchor and anchor.GetName then
		if openAllDropdown and UIDROPDOWNMENU_OPEN_MENU == openAllDropdown and CloseDropDownMenus then CloseDropDownMenus() end
		ToggleDropDownMenu(1, nil, dropdown, anchor:GetName(), 0, 0)
	end
end
function Mail.OpenModuleMenu(anchor, module)
	if module == "OpenAll" and openAllDropdown and ToggleDropDownMenu and anchor and anchor.GetName then
		if dropdown and UIDROPDOWNMENU_OPEN_MENU == dropdown and CloseDropDownMenus then CloseDropDownMenus() end
		ToggleDropDownMenu(1, nil, openAllDropdown, anchor:GetName(), 0, 0)
	end
end
local function Add(level, text, opts)
	local info = UIDropDownMenu_CreateInfo()
	info.text = text
	info.notCheckable = opts and opts.noCheck or nil
	info.isTitle = opts and opts.title or nil
	info.disabled = opts and opts.disabled or nil
	info.checked = opts and opts.checked or nil
	info.isNotRadio = opts and opts.toggle or nil
	info.keepShownOnClick = opts and opts.keepOpen or nil
	info.hasArrow = opts and opts.submenu or nil
	info.value = opts and opts.value or nil
	info.func = opts and opts.func or nil
	UIDropDownMenu_AddButton(info, level)
end

local function Choice(level, group, key, value, text)
	Add(level, text or tostring(value), { checked = Mail.GetSetting(group, key) == value,
		func = function() Mail.SetSetting(group, key, value) end, keepOpen = true })
end

local function Toggle(level, group, key, text)
	Add(level, text, { checked = Mail.GetSetting(group, key) == true, toggle = true,
		keepOpen = true, func = function() Mail.SetSetting(group, key, not Mail.GetSetting(group, key)) end })
end

local function OpenAllCategories(level)
	Add(level, "AH-related mail", { noCheck = true, submenu = true, value = "AHMail" })
	Add(level, "Non-AH related mail", { noCheck = true, submenu = true, value = "NonAHMail" })
	Add(level, "Other options", { noCheck = true, submenu = true, value = "OpenAllOther" })
end

local function OpenAllOptions(level, value)
	if value == "AHMail" then
		Toggle(level, "OpenAll", "AHCancelled", "Open all Auction cancelled mail")
		Toggle(level, "OpenAll", "AHExpired", "Open all Auction expired mail")
		Toggle(level, "OpenAll", "AHOutbid", "Open all Outbid on mail")
		Toggle(level, "OpenAll", "AHSuccess", "Open all Auction successful mail")
		Toggle(level, "OpenAll", "AHWon", "Open all Auction won mail")
	elseif value == "NonAHMail" then
		Toggle(level, "OpenAll", "Postmaster", "Open mail from the Postmaster")
		Toggle(level, "OpenAll", "Attachments", "Open all mail with attachments")
	elseif value == "OpenAllOther" then
		Add(level, "Keep free space", { noCheck = true, submenu = true, value = "OpenAllKeepFree" })
		Toggle(level, "OpenAll", "SpamChat", "Verbose mode")
	end
end

local function Fill(self, level)
	local value = UIDROPDOWNMENU_MENU_VALUE
	if self == openAllDropdown then
		if level == 1 then OpenAllCategories(level)
		elseif level == 2 then OpenAllOptions(level, value)
		elseif level == 3 and value == "OpenAllKeepFree" then
			for i = 1, #keepFreeChoices do Choice(level, "OpenAll", "KeepFreeSpace", keepFreeChoices[i]) end
		end
		return
	end
	if level == 1 then
		Add(level, "Postal", { title = true, noCheck = true })
		for i = 1, #modules do
			local name = modules[i]
			Add(level, name, { checked = Mail.IsEnabled(name), toggle = true, keepOpen = true,
				submenu = configurable[name],
				value = name,
				func = function() Mail.SetSetting("Modules", name, not Mail.IsEnabled(name)) end })
		end
		Add(level, "Opening Speed", { noCheck = true, submenu = true, value = "OpenSpeed" })
		Add(level, "Chat Output", { noCheck = true, submenu = true, value = "ChatOutput" })
		Add(level, "Profile", { noCheck = true, submenu = true, value = "Profile" })
		Add(level, "Help", { noCheck = true, func = function()
			Mail.Print("See /fluxui and docs/MAIL_INTEGRATION.md")
		end })
		Add(level, CLOSE or "Close", { noCheck = true, func = function() if CloseDropDownMenus then CloseDropDownMenus() end end })
	elseif level == 2 then
		if value == "OpenSpeed" then
			Choice(level, "OpenSpeed", nil, 0, "0.00")
			for i = 0, 13 do local n = 0.3 + i * 0.05; Choice(level, "OpenSpeed", nil, n, string.format("%.2f", n)) end
			for i = 0, 8 do local n = 1 + i * 0.5; Choice(level, "OpenSpeed", nil, n, string.format("%.2f", n)) end
		elseif value == "ChatOutput" then
			for i = 1, (NUM_CHAT_WINDOWS or 1) do
				local tab = _G["ChatFrame" .. i .. "Tab"]
				if tab and tab.GetText then Choice(level, "ChatOutput", nil, i, i .. ". " .. (tab:GetText() or "")) end
			end
		elseif value == "OpenAll" then
			OpenAllCategories(level)
		elseif value == "Select" then
			Add(level, "Keep free space", { noCheck = true, submenu = true, value = "SelectKeepFree" })
			Toggle(level, "Select", "SpamChat", "Verbose mode")
		elseif value == "Express" then
			Toggle(level, "Express", "EnableAltClick", "Enable Alt-Click to send mail")
			Toggle(level, "Express", "AutoSend", "Auto-Send on Alt-Click")
			Toggle(level, "Express", "BulkSend", "Auto-Attach similar items on Control-Click")
			Toggle(level, "Express", "MultiItemTooltip", "Add multiple item mail tooltips")
		elseif value == "BlackBook" then
			Toggle(level, "BlackBook", "AutoFill", "Autofill last person mailed")
			Add(level, "Name auto-completion options", { noCheck = true, submenu = true, value = "AutoComplete" })
		elseif value == "QuickAttach" then
			for bag = 0, 5 do
				if bag < 5 or (Flux.Client and Flux.Client.isRetail) then
					Toggle(level, "QuickAttach", "EnableBag" .. bag,
						bag == 0 and "Enable for backpack" or (bag == 5 and "Enable for reagent bag"
							or "Enable for bag " .. ({ "one", "two", "three", "four" })[bag]))
				end
			end
		elseif value == "Profile" then
			Add(level, "Choose", { noCheck = true, submenu = true, value = "ProfileChoose" })
			Add(level, "Copy From", { noCheck = true, submenu = true, value = "ProfileCopy" })
			Add(level, "Delete", { noCheck = true, submenu = true, value = "ProfileDelete" })
			Add(level, "New Profile", { noCheck = true, func = function()
				if StaticPopup_Show then StaticPopup_Show("FLUX_MAIL_NEW_PROFILE") end
			end })
			Add(level, "Reset Profile", { noCheck = true, func = Mail.ResetProfile })
			Toggle(level, "Profile", "Default", "Default")
		end
	elseif level == 3 then
		if value == "SelectKeepFree" or value == "OpenAllKeepFree" then
			local group = value == "SelectKeepFree" and "Select" or "OpenAll"
			for i = 1, #keepFreeChoices do Choice(level, group, "KeepFreeSpace", keepFreeChoices[i]) end
		elseif value == "AHMail" or value == "NonAHMail" or value == "OpenAllOther" then
			OpenAllOptions(level, value)
		elseif value == "AutoComplete" then
			Toggle(level, "BlackBook", "UseAutoComplete", "Use Postal's auto-complete")
			local entries = { {"AutoCompleteAlts", "Alts"}, {"AutoCompleteAllAlts", "All Alts"},
				{"AutoCompleteRecent", "Recently Mailed"}, {"AutoCompleteContacts", "Contacts"},
				{"AutoCompleteFriends", "Friends"}, {"AutoCompleteGuild", "Guild"},
				{"ExcludeRandoms", "Exclude randoms you interacted with"},
				{"DisableBlizzardAutoComplete", "Disable Blizzard's auto-completion popup menu"} }
			for i = 1, #entries do Toggle(level, "BlackBook", entries[i][1], entries[i][2]) end
		elseif value == "ProfileChoose" or value == "ProfileCopy" or value == "ProfileDelete" then
			local root = Root()
			local names = { "Default" }
			for name in pairs(root.profiles) do if name ~= "Default" then names[#names + 1] = name end end
			table.sort(names)
			for i = 1, #names do
				local name = names[i]
				if value == "ProfileChoose" or name ~= root.profileName then
					Add(level, name, { checked = value == "ProfileChoose" and name == root.profileName,
						func = function()
							if value == "ProfileChoose" then Mail.SwitchProfile(name)
							elseif value == "ProfileCopy" then Mail.CopyProfile(name)
							else Mail.DeleteProfile(name) end
						end })
				end
			end
		end
	elseif level == 4 and value == "OpenAllKeepFree" then
		for i = 1, #keepFreeChoices do Choice(level, "OpenAll", "KeepFreeSpace", keepFreeChoices[i]) end
	end
end

if StaticPopupDialogs then
	StaticPopupDialogs.FLUX_MAIL_NEW_PROFILE = {
		text = "New Profile Name:", button1 = ACCEPT or "Accept", button2 = CANCEL or "Cancel",
		hasEditBox = 1, maxLetters = 50, timeout = 0, hideOnEscape = 1,
		OnAccept = function(self)
			local edit = self.editBox or (self.GetName and _G[self:GetName() .. "EditBox"])
			if edit then Mail.SwitchProfile((edit:GetText() or ""):match("^%s*(.-)%s*$")) end
		end,
	}
end

local function Install()
	if button or not MailFrame or not UIDropDownMenu_Initialize then return end
	dropdown = CreateFrame("Frame", "FluxMailSettingsDropdown", UIParent, "UIDropDownMenuTemplate")
	dropdown.displayMode = "MENU"
	UIDropDownMenu_Initialize(dropdown, Fill, "MENU")
	openAllDropdown = CreateFrame("Frame", "FluxMailOpenAllDropdown", UIParent, "UIDropDownMenuTemplate")
	openAllDropdown.displayMode = "MENU"
	UIDropDownMenu_Initialize(openAllDropdown, Fill, "MENU")
	button = CreateFrame("Button", "FluxMailSettingsButton", MailFrame)
	button:SetSize(25, 25)
	button:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -22, 2)
	button:SetFrameLevel(math.max(501, MailFrame:GetFrameLevel() + 5))
	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonUp")
	button:SetHitRectInsets(0, 0, 0, 0)
	button:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Round")
	button:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
	button:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	button:SetScript("OnClick", function(self) Mail.OpenSettingsMenu(self) end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:SetScript("OnEvent", function(_, event, interactionType)
	local mailType = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
	if event == "MAIL_SHOW" or (mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and interactionType == mailType) then
		Install()
		if not button and C_Timer and C_Timer.After then C_Timer.After(0, Install) end
	end
end)
