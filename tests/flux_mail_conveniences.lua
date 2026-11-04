-- Mail conveniences use the five-client GetInboxText position and native money editor.
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local frames = {}
local function widget(name)
	local w = { shown = true, events = {}, name = name }
	function w:RegisterEvent(event) self.events[event] = true end
	function w:SetScript(kind, fn) self[kind] = fn end
	function w:HookScript(kind, fn) self["hook" .. kind] = fn end
	function w:SetSize() end
	function w:SetPoint() end
	function w:SetNormalTexture() end
	function w:SetEnabled(value) self.enabled = value end
	function w:SetFrameStrata() end
	function w:EnableMouse() end
	function w:SetMovable() end
	function w:RegisterForDrag() end
	function w:CreateTexture() return widget() end
	function w:CreateFontString() return widget() end
	function w:SetAllPoints() end
	function w:SetColorTexture() end
	function w:SetText(text) self.text = text end
	function w:GetText() return self.text end
	function w:SetMultiLine() end
	function w:SetAutoFocus() end
	function w:SetFontObject() end
	function w:SetTextInsets() end
	function w:HighlightText() end
	function w:SetFocus() end
	function w:Show() self.shown = true end
	function w:Hide() self.shown = false end
	function w:IsShown() return self.shown end
	function w:SetShown(show) self.shown = show end
	frames[#frames + 1] = w
	if name then _G[name] = w end
	return w
end
CreateFrame = function(_, name) return widget(name) end
UIParent = widget("UIParent")
OpenMailFrame = widget("OpenMailFrame")
InboxFrame = widget("InboxFrame")
InboxFrame.openMailID = 2
SendMailMoney = widget("SendMailMoney")
SendMailMoney.onValueChangedFunc = function() end
SendMailSubjectEditBox = widget("SendMailSubjectEditBox")
SendMailSubjectEditBox:SetText("")
ChatFontNormal = {}
FROM, MAIL_SUBJECT_LABEL = "From:", "Subject:"
local balance, copper, invoice = 1000, 12345, false
GetMoney = function() return balance end
GetCoinTextureString = function(amount) return tostring(amount) .. "c" end
MoneyInputFrame_GetCopper = function() return copper end
GetInboxHeaderInfo = function(index)
	if index == 2 then return nil, nil, "Friend", "Hello" end
end
GetInboxText = function(index)
	if index == 2 then return "The body", nil, nil, true, invoice end
end
GetInboxInvoiceInfo = function() return "seller", "Potion", "Buyer", 1000, 1200, 20, 30 end
local messages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) messages[#messages + 1] = msg end }
local moneyHook
hooksecurefunc = function(object, method, callback)
	check(object == SendMailMoney and method == "onValueChangedFunc", "hooks native money change")
	moneyHook = callback
end
local ns = { Flux = {} }
assert(loadfile("Mail/Conveniences.lua"))("_FluxUI", ns)
local eventFrame
for _, f in ipairs(frames) do if f.events.MAIL_SHOW then eventFrame = f; break end end
local mail = ns.Flux.Mail

check(mail.MoneySubject(0) == "", "zero money leaves empty subject")
check(mail.MoneySubject(12345) == "[1g 23s 45c]", "gold formatting")
check(mail.MoneySubject(205) == "[2s 5c]", "silver formatting")
check(mail.MoneySubject(5) == "[5c]", "copper formatting")
check(mail.GetCopyText() == "From: Friend\nSubject: Hello\n\nThe body", "body from five-return API")
invoice = true
check(mail.GetCopyText():find("seller: Potion", 1, true) ~= nil, "invoice fifth return handled")
invoice = false

eventFrame.OnEvent(eventFrame, "MAIL_SHOW")
check(FluxMailCopyButton and moneyHook, "mail controls installed")
moneyHook()
check(SendMailSubjectEditBox:GetText() == "[1g 23s 45c]", "money fills empty subject")
copper = 250
moneyHook()
check(SendMailSubjectEditBox:GetText() == "[2s 50c]", "generated subject updates")
SendMailSubjectEditBox:SetText("My subject")
copper = 300
moneyHook()
check(SendMailSubjectEditBox:GetText() == "My subject", "custom subject preserved")
FluxMailCopyButton.OnClick(FluxMailCopyButton)
check(FluxMailCopyFrame:IsShown(), "copy frame opens")
balance = 1750
eventFrame.OnEvent(eventFrame, "MAIL_CLOSED")
check(#messages == 1 and messages[1]:find("750c", 1, true), "positive mailbox gain reported")
check(not FluxMailCopyFrame:IsShown(), "copy frame closes with mailbox")

print("Flux mail conveniences: " .. checks .. " checks passed")
