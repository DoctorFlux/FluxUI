-- Loaded mail module: persistence, send-success ownership, and recipient choices.
local checks = 0
local function check(ok, label)
	checks = checks + 1
	assert(ok, label)
end

local frames = {}
local function NewFrame(name)
	local f = { name = name, shown = true, events = {} }
	function f:RegisterEvent(event) self.events[event] = true end
	function f:SetScript(kind, fn) self[kind] = fn end
	function f:SetSize() end
	function f:SetHeight() end
	function f:SetPoint() end
	function f:SetNormalTexture() end
	function f:SetHighlightTexture() end
	function f:SetDisabledTexture() end
	function f:SetPushedTexture() end
	function f:SetShown(show) self.shown = show end
	function f:SetText(text) self.text = text end
	function f:GetText() return self.text end
	function f:SetNormalFontObject() end
	function f:SetHighlightFontObject() end
	function f:SetFrameStrata() end
	function f:EnableMouse() end
	function f:EnableMouseWheel() end
	function f:SetAllPoints() end
	function f:SetColorTexture() end
	function f:SetOwner() end
	function f:Show() self.shown = true end
	function f:Hide() self.shown = false end
	function f:IsShown() return self.shown end
	function f:CreateTexture() return NewFrame() end
	function f:SetCursorPosition() end
	function f:SetFocus() end
	frames[#frames + 1] = f
	if name then _G[name] = f end
	return f
end
CreateFrame = function(_, name) return NewFrame(name) end
GameFontNormalSmall, GameFontHighlightSmall = {}, {}
SendMailFrame = NewFrame("SendMailFrame")
SendMailNameEditBox = NewFrame("SendMailNameEditBox")
SendMailSubjectEditBox = NewFrame("SendMailSubjectEditBox")
GameTooltip = NewFrame("GameTooltip")

local sendHook
hooksecurefunc = function(name, fn) check(name == "SendMail", "hooks actual send"); sendHook = fn end
local known = { "Other-Realm", "Me-Realm" }
local ns = { Flux = { Inventory = { Store = {
	GetCharacterFullName = function() return "Me-Realm" end,
	GetAllCharacters = function() return known end,
} } } }
local module = assert(loadfile("Mail/Contacts.lua"))
module("_FluxUI", ns)
local mail = ns.Flux.Mail
local eventFrame = frames[#frames - 1] -- frame before the hook does not create another frame
for _, f in ipairs(frames) do if f.events.PLAYER_LOGIN then eventFrame = f; break end end

check(eventFrame.events.MAIL_SEND_SUCCESS, "registers successful send")
check(eventFrame.events.MAIL_FAILED, "registers failed send")
eventFrame.OnEvent(eventFrame, "PLAYER_LOGIN")
check(FluxMailDB.alts["me-realm"] == "Me-Realm", "records current character")
check(mail.AddContact(" Friend-Realm "), "saves contact")
check(FluxMailDB.contacts["friend-realm"] == "Friend-Realm", "normalizes contact")
check(not mail.AddContact("Me-Realm"), "does not list self as contact")
check(not mail.AddContact("bad|name"), "rejects markup control")

eventFrame.OnEvent(eventFrame, "MAIL_SHOW")
check(FluxMailContactsButton ~= nil and FluxMailContactsPopup ~= nil, "creates native mail picker")
SendMailNameEditBox:SetText("Friend-Realm")
FluxMailContactsButton.OnClick(FluxMailContactsButton)
check(FluxMailContactsPopup:IsShown(), "opens contacts")
local choices = mail.GetRecipients()
check(#choices == 2, "contact and known alt listed once")
check(choices[1].name == "Friend-Realm", "saved contact first")
check(choices[2].name == "Other-Realm", "known alt listed")

sendHook("Failed-Realm")
eventFrame.OnEvent(eventFrame, "MAIL_FAILED")
eventFrame.OnEvent(eventFrame, "MAIL_SEND_SUCCESS")
check(#FluxMailDB.recent == 0, "failed send is not recorded")
sendHook("Friend-Realm")
eventFrame.OnEvent(eventFrame, "MAIL_SEND_SUCCESS")
check(FluxMailDB.recent[1] == "Friend-Realm", "confirmed send becomes recent")
sendHook("friend-realm")
eventFrame.OnEvent(eventFrame, "MAIL_SEND_SUCCESS")
check(#FluxMailDB.recent == 1 and FluxMailDB.recent[1] == "friend-realm", "recent deduplicates case")
for i = 1, 25 do
	sendHook("Person" .. i)
	eventFrame.OnEvent(eventFrame, "MAIL_SEND_SUCCESS")
end
check(#FluxMailDB.recent == 20, "recent list is bounded")
check(FluxMailDB.recent[1] == "Person25", "newest recipient first")
check(FluxMailDB.recent[20] == "Person6", "oldest recipient discarded")
check(mail.RemoveContact("Friend-Realm") and not FluxMailDB.contacts["friend-realm"], "removes contact")
eventFrame.OnEvent(eventFrame, "MAIL_CLOSED")
check(not FluxMailContactsPopup:IsShown(), "close hides picker")

print("Flux mail contacts: " .. checks .. " checks passed")
