-- Settings persistence, Postal button geometry, and safe mail-type filtering.
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local frames = {}
local function widget(name)
	local f = { events = {}, shown = true, name = name }
	function f:RegisterEvent(event) self.events[event] = true end
	function f:SetScript(kind, fn) self[kind] = fn end
	function f:SetSize(w, h) self.width, self.height = w, h end
	function f:SetPoint(...) self.point = { ... } end
	function f:SetFrameLevel(level) self.frameLevel = level end
	function f:GetFrameLevel() return self.frameLevel or 0 end
	function f:EnableMouse() end
	function f:RegisterForClicks() end
	function f:SetHitRectInsets() end
	function f:SetNormalTexture() end
	function f:SetHighlightTexture() end
	function f:SetDisabledTexture() end
	function f:SetPushedTexture() end
	function f:SetShown(on) self.shown = on end
	function f:IsShown() return self.shown end
	function f:SetText(text) self.text = text end
	function f:GetName() return self.name end
	frames[#frames + 1] = f
	if name then _G[name] = f end
	return f
end
CreateFrame = function(_, name) return widget(name) end
UIParent = widget("UIParent")
MailFrame = widget("MailFrame")
InboxFrame = widget("InboxFrame")
OpenAllMail = widget("OpenAllMail")
UIDropDownMenu_Initialize = function(frame, fill) frame.fill = fill end
UIDropDownMenu_CreateInfo = function() return {} end
local menuEntries = {}
UIDropDownMenu_AddButton = function(info) menuEntries[#menuEntries + 1] = info end
ToggleDropDownMenu = function(_, _, frame) frame.fill(frame, 1) end
local shifted = false
IsShiftKeyDown = function() return shifted end
AUCTION_SOLD_MAIL_SUBJECT = "Auction sold: %s"
local inbox = {
	{ sender = "COD", subject = "Pay", money = 0, cod = 50, items = 1 },
	{ sender = "Auction House", subject = "Auction sold: Sword", money = 100, cod = 0, items = 0 },
	{ sender = "Alt", subject = "Supplies", money = 0, cod = 0, items = 1 },
}
GetInboxNumItems = function() return #inbox, #inbox end
GetInboxHeaderInfo = function(i)
	local h = inbox[i]
	return nil, nil, h.sender, h.subject, h.money, h.cod, 20, h.items, false, false, false, false, false
end
local calls = {}
local ns = { Flux = { Mail = { ProcessSelected = function(mode, list, group)
	calls[#calls + 1] = { mode = mode, list = list, group = group }
end } } }
assert(loadfile("Mail/Settings.lua"))("_FluxUI", ns)
assert(loadfile("Mail/OpenAll.lua"))("_FluxUI", ns)
local mail = ns.Flux.Mail
check(mail.GetSetting("OpenSpeed") == 0.5, "opening speed default")
check(mail.GetSetting("OpenAll", "KeepFreeSpace") == 1, "one free bag slot default")
mail.SetSetting("OpenSpeed", nil, 0)
mail.SetSetting("OpenAll", "KeepFreeSpace", 5)
check(mail.GetSetting("OpenSpeed") == 0, "zero-delay preference persists")
check(mail.GetSetting("OpenAll", "KeepFreeSpace") == 5, "bag reserve preference persists")
check(mail.GetMailType("Auction sold: Sword") == "AHSuccess", "auction subject classified")
check(mail.GetMailType("Supplies") == "NonAHMail", "ordinary subject classified")
for _, frame in ipairs(frames) do
	if frame.events.MAIL_SHOW and frame.OnEvent then frame.OnEvent(frame, "MAIL_SHOW") end
end
check(FluxMailSettingsButton and FluxMailSettingsButton.width == 25, "top settings icon is 25 wide")
check(FluxMailOpenAllButton and FluxMailOpenAllButton.width == 120, "Open All matches button width")
check(not OpenAllMail:IsShown(), "native Open All yields to Flux button")
menuEntries = {}
FluxMailOpenAllMenuButton.OnClick(FluxMailOpenAllMenuButton)
check(#menuEntries == 3 and menuEntries[1].text == "AH-related mail", "Open All arrow opens its own filters")
mail.OpenAll()
check(#calls == 1 and #calls[1].list == 2 and calls[1].group == "OpenAll", "eligible mail selected for worker")
check(calls[1].list[1].index == 3 and calls[1].list[2].index == 2, "descending index order")
mail.SetSetting("OpenAll", "AHSuccess", false)
mail.OpenAll()
check(#calls[2].list == 1 and calls[2].list[1].index == 3, "auction filter applied")
shifted = true
mail.OpenAll()
check(#calls[3].list == 2, "shift overrides filter but not COD guard")
mail.SetSetting("Modules", "OpenAll", false)
check(OpenAllMail:IsShown() and not FluxMailOpenAllButton:IsShown(), "module switch restores native button")

menuEntries = {}
FluxMailSettingsButton.OnClick(FluxMailSettingsButton)
check(#menuEntries > 10 and menuEntries[1].text == "Postal", "settings menu has modules")
menuEntries = {}
UIDROPDOWNMENU_MENU_VALUE = "OpenAllKeepFree"
FluxMailSettingsDropdown.fill(FluxMailSettingsDropdown, 4)
check(#menuEntries == 10 and menuEntries[5].text == "5" and menuEntries[5].checked,
	"keep-free submenu exposes selected five-slot reserve")
menuEntries = {}
UIDROPDOWNMENU_MENU_VALUE = "OpenSpeed"
FluxMailSettingsDropdown.fill(FluxMailSettingsDropdown, 2)
check(#menuEntries == 24 and menuEntries[1].checked and menuEntries[1].text == "0.00",
	"opening-speed submenu includes zero delay")
print("Flux mail open all: " .. checks .. " checks passed")
