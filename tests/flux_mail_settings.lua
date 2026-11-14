-- Mail settings: Postal speed/reserve values, menu entries, and profile isolation.
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local frames = {}
local function frame(name)
	local f = { name = name, events = {} }
	function f:RegisterEvent(event) self.events[event] = true end
	function f:SetScript(kind, callback) self[kind] = callback end
	function f:SetSize() end
	function f:SetPoint() end
	function f:GetFrameLevel() return 1 end
	function f:SetFrameLevel(level) self.frameLevel = level end
	function f:EnableMouse(value) self.mouseEnabled = value end
	function f:RegisterForClicks(value) self.clicks = value end
	function f:SetHitRectInsets() end
	function f:SetNormalTexture() end
	function f:SetHighlightTexture() end
	function f:SetDisabledTexture() end
	function f:SetPushedTexture() end
	function f:GetName() return self.name end
	frames[#frames + 1] = f
	if name then _G[name] = f end
	return f
end
CreateFrame = function(_, name) return frame(name) end
UIParent, MailFrame = frame("UIParent"), frame("MailFrame")
UIDropDownMenu_CreateInfo = function() return {} end
local entries = {}
UIDropDownMenu_AddButton = function(info, level) entries[#entries + 1] = { text = info.text, level = level,
	value = info.value, func = info.func, checked = info.checked } end
local menuFills = {}
UIDropDownMenu_Initialize = function(menu, callback) menuFills[menu.name] = callback end
local openedMenu
ToggleDropDownMenu = function(_, _, menu) openedMenu = menu end
local ns = { Flux = { Client = { isEra = true } } }
assert(loadfile("Mail/Settings.lua"))("_FluxUI", ns)
local mail = ns.Flux.Mail
local eventFrame
for _, f in ipairs(frames) do if f.events.MAIL_SHOW then eventFrame = f end end
eventFrame.OnEvent(eventFrame, "MAIL_SHOW")
check(FluxMailSettingsButton.mouseEnabled and FluxMailSettingsButton.clicks == "LeftButtonUp"
	and FluxMailSettingsButton.frameLevel >= 501, "main arrow owns a clickable layer")
local function Main(level, value)
	entries = {}; UIDROPDOWNMENU_MENU_VALUE = value
	menuFills.FluxMailSettingsDropdown(FluxMailSettingsDropdown, level)
end
local function OpenAll(level, value)
	entries = {}; UIDROPDOWNMENU_MENU_VALUE = value
	menuFills.FluxMailOpenAllDropdown(FluxMailOpenAllDropdown, level)
end
check(mail.GetSetting("OpenSpeed") == 0.5, "Postal default speed")
check(mail.GetSetting("Select", "KeepFreeSpace") == 1, "Select reserve default")
check(mail.GetSetting("OpenAll", "KeepFreeSpace") == 1, "Open All reserve default")
check(mail.IsEnabled("OpenAll"), "module default enabled")
mail.SetSetting("OpenSpeed", nil, 0)
check(mail.GetSetting("OpenSpeed") == 0, "zero-delay speed persists")
mail.SetSetting("Select", "KeepFreeSpace", 5)
check(mail.GetSetting("Select", "KeepFreeSpace") == 5, "Select reserve persists")
check(mail.GetSetting("OpenAll", "KeepFreeSpace") == 1, "reserves remain independent")
mail.SwitchProfile("Fast")
check(mail.GetSetting("OpenSpeed") == 0.5, "new profile gets default speed")
mail.SetSetting("OpenSpeed", nil, 0)
mail.SwitchProfile("Default")
check(mail.GetSetting("Select", "KeepFreeSpace") == 5, "old profile restored")
mail.SetSetting("OpenSpeed", nil, 2)
mail.CopyProfile("Fast")
check(mail.GetSetting("OpenSpeed") == 0, "profile copy replaces settings")
mail.ResetProfile()
check(mail.GetSetting("OpenSpeed") == 0.5, "profile reset uses defaults")
mail.SetSetting("Modules", "OpenAll", false)
check(not mail.IsEnabled("OpenAll"), "module toggle persists")
Main(1)
local function has(label) for _, item in ipairs(entries) do if item.text == label then return true end end end
check(has("Opening Speed") and has("Profile") and has("QuickAttach"), "main menu entries")
check(has("Restock"), "mail settings retain the Restock submenu without a mailbox restock panel")
Main(2, "Restock")
check(#entries == 1 and entries[1].text == "Automatically collect auction-restock items" and entries[1].checked,
    "Restock submenu retains the saved automatic collection setting")
entries[1].func()
check(not mail.GetSetting("Restock", "AutoCollect"), "settings menu can disable automatic restock collection")
Main(2, "Restock"); entries[1].func()
check(mail.GetSetting("Restock", "AutoCollect"), "settings menu can reenable automatic restock collection")
Main(2, "OpenSpeed")
check(#entries == 24, "Postal speed choices")
check(entries[1].text == "0.00" and entries[#entries].text == "5.00", "speed extrema")
Main(3, "SelectKeepFree")
check(entries[1].text == "0" and entries[#entries].text == "30", "bag reserve menu")
Main(2, "BlackBook")
check(has("Name auto-completion options"), "BlackBook options")
Main(2, "QuickAttach")
check(has("Enable for backpack") and not has("Enable for reagent bag"), "Era bags")
FluxMailSettingsButton.OnClick(FluxMailSettingsButton)
check(openedMenu == FluxMailSettingsDropdown, "top arrow opens main menu")
mail.OpenModuleMenu(FluxMailSettingsButton, "OpenAll")
check(openedMenu == FluxMailOpenAllDropdown, "Open All arrow opens separate dropdown")
OpenAll(1)
check(has("AH-related mail") and has("Non-AH related mail") and has("Other options"), "Open All root choices")
OpenAll(2, "AHMail")
check(has("Open all Auction cancelled mail") and has("Open all Auction won mail"), "Open All auction filters")
OpenAll(2, "NonAHMail")
check(has("Open all mail with attachments"), "Open All attachment filter")
OpenAll(2, "OpenAllOther")
check(has("Keep free space") and has("Verbose mode"), "Open All other submenu")
OpenAll(3, "OpenAllKeepFree")
check(#entries == 10 and entries[#entries].text == "30", "Open All reserve submenu")
Main(2, "OpenAll")
check(has("AH-related mail") and has("Other options"), "main menu Open All branch")
Main(3, "AHMail")
check(has("Open all Auction successful mail"), "main menu nested auction filters")
print("Flux mail settings: " .. checks .. " checks passed")
