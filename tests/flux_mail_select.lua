-- Selected inbox collection: descending indexes, COD guard and native action confirmations.
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local frames, timers, hooks = {}, {}, {}
local now = 0
local function widget(name)
	local f = { events = {}, shown = true, checked = false }
	function f:RegisterEvent(event) self.events[event] = true end
	function f:SetScript(kind, fn) self[kind] = fn end
	function f:SetSize() end
	function f:SetWidth() end
	function f:GetWidth() return 280 end
	function f:SetPoint() end
	function f:GetPoint() return "TOPLEFT", InboxFrame, "TOPLEFT", 0, 0 end
	function f:ClearAllPoints() end
	function f:SetHitRectInsets() end
	function f:CreateFontString() return widget() end
	function f:SetText(text) self.text = text end
	function f:SetEnabled(on) self.enabled = on end
	function f:SetShown(on) self.shown = on end
	function f:IsShown() return self.shown end
	function f:SetChecked(on) self.checked = on end
	function f:GetChecked() return self.checked end
	frames[#frames + 1] = f
	if name then _G[name] = f end
	return f
end
CreateFrame = function(_, name) return widget(name) end
MailFrame = widget("MailFrame")
InboxFrame = widget("InboxFrame")
InboxFrame.pageNum = 1
for i = 1, 7 do widget("MailItem" .. i) end
INBOXITEMS_TO_DISPLAY = 7
C_Timer = { After = function(delay, fn) timers[#timers + 1] = { at = now + delay, fn = fn } end }
GetTime = function() return now end
local notices = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) notices[#notices + 1] = msg end }
hooksecurefunc = function(name, fn) hooks[name] = fn end
InboxFrame_Update = function() end
local inbox = {
	{ sender = "COD", subject = "Pay", money = 0, cod = 100, items = { 42 } },
	{ sender = "Friend", subject = "Gold", money = 250, cod = 0, items = {} },
	{ sender = "Alt", subject = "Potion", money = 0, cod = 0, items = { 17 } },
}
GetInboxNumItems = function() return #inbox, #inbox end
GetInboxHeaderInfo = function(i)
	local h = inbox[i]
	if not h then return end
	return nil, nil, h.sender, h.subject, h.money, h.cod, 20, h.count or #h.items, false, false, false, false, false
end
local delayedItem
GetInboxItem = function(i, slot)
	local h = inbox[i]
	if delayedItem and i == delayedItem.index and not delayedItem.ready then return end
	if h and h.items[slot] then return "Item", h.items[slot], nil, 1 end
end
local taken = {}
TakeInboxMoney = function(i)
	taken[#taken + 1] = "money:" .. i
	inbox[i].money = 0
end
TakeInboxItem = function(i, slot)
	taken[#taken + 1] = "item:" .. i
	if inbox[i].count then
		inbox[i].items[slot] = nil
		inbox[i].count = inbox[i].count - 1
	else
		table.remove(inbox[i].items, slot)
	end
	if inbox[i].money == 0 and (inbox[i].count or #inbox[i].items) == 0 then table.remove(inbox, i) end
end
ReturnInboxItem = function(i) taken[#taken + 1] = "return:" .. i; table.remove(inbox, i) end
DeleteInboxItem = function(i) taken[#taken + 1] = "delete:" .. i; table.remove(inbox, i) end
InboxItemCanDelete = function() return true end
local freeSlots = 4
local ns = { Flux = {
	Container = { GetTotalFreeBagSlots = function() return freeSlots end },
	Mail = { GetSetting = function(group, key)
		if group == "OpenSpeed" then return 0 end
		if group == "Select" and key == "KeepFreeSpace" then return 1 end
		if group == "Select" and key == "SpamChat" then return true end
	end },
} }
assert(loadfile("Mail/Select.lua"))("_FluxUI", ns)
local eventFrame
for _, f in ipairs(frames) do if f.events.MAIL_SHOW then eventFrame = f; break end end
local function Fire(event)
	eventFrame.OnEvent(eventFrame, event)
end
local function Pump(seconds)
	local untilTime = now + seconds
	for _ = 1, 40 do
		if #timers == 0 then break end
		table.sort(timers, function(a, b) return a.at < b.at end)
		if timers[1].at > untilTime then break end
		local nextTimer = table.remove(timers, 1)
		now = nextTimer.at
		nextTimer.fn()
	end
	now = untilTime
end
Fire("MAIL_SHOW")
check(FluxMailTakeSelected ~= nil and FluxMailSelect2 and FluxMailSelect3, "selection controls created")
check(not FluxMailTakeSelected.enabled, "take disabled before selection")
FluxMailSelect2:SetChecked(true); FluxMailSelect2.OnClick(FluxMailSelect2)
FluxMailSelect3:SetChecked(true); FluxMailSelect3.OnClick(FluxMailSelect3)
check(FluxMailTakeSelected.enabled, "take enabled after selection")
check(FluxMailTakeSelected.text == "Open", "Postal-style Open label")
ns.Flux.Mail.TakeSelected()
check(taken[1] == "item:3", "highest selected index first")
Fire("MAIL_INBOX_UPDATE"); Pump(0.2)
check(taken[2] == "money:2", "next selected money taken")
Fire("MAIL_INBOX_UPDATE"); Pump(0.2)
check(#taken == 2, "COD mail untouched")
check(#notices == 3 and notices[#notices]:find("Finished taking selected", 1, true), "verbose progress and completion reported")
check(not FluxMailTakeSelected.enabled, "selection cleared after collection")
FluxMailSelect1:SetChecked(true); FluxMailSelect1.OnClick(FluxMailSelect1)
FluxMailReturnSelected.OnClick(FluxMailReturnSelected)
check(taken[3] == "return:1", "returns selected COD mail when explicitly confirmed")
Fire("MAIL_INBOX_UPDATE"); Pump(0.2)
check(#inbox == 1 and inbox[1].subject == "Gold", "return removes selected COD mail")
inbox[2] = { sender = "Alt", subject = "Reserved", money = 0, cod = 0, items = { 23 } }
freeSlots = 1
Fire("MAIL_INBOX_UPDATE")
FluxMailSelect2:SetChecked(true); FluxMailSelect2.OnClick(FluxMailSelect2)
ns.Flux.Mail.TakeSelected()
check(#taken == 3, "one-slot reserve prevents attachment take")
check(not FluxMailTakeSelected.enabled, "reserved item selection finishes without retry")
freeSlots = 4
inbox[3] = { sender = "Alt", subject = "Sparse slots", money = 0, cod = 0,
	items = { [4] = 31, [12] = 32 }, count = 2 }
Fire("MAIL_INBOX_UPDATE")
FluxMailSelect3:SetChecked(true); FluxMailSelect3.OnClick(FluxMailSelect3)
ns.Flux.Mail.TakeSelected()
check(taken[4] == "item:3" and inbox[3].items[12] == nil, "takes high attachment slot")
Fire("MAIL_INBOX_UPDATE"); Pump(0.2)
check(taken[5] == "item:3" and inbox[3] == nil, "takes remaining sparse attachment")
Fire("MAIL_INBOX_UPDATE"); Pump(0.2)
check(notices[#notices]:find("Finished taking selected", 1, true), "completion follows all attachments")
inbox[3] = { sender = "Alt", subject = "Loading item", money = 0, cod = 0, items = { 44 } }
delayedItem = { index = 3 }
Fire("MAIL_INBOX_UPDATE")
FluxMailSelect3:SetChecked(true); FluxMailSelect3.OnClick(FluxMailSelect3)
ns.Flux.Mail.TakeSelected()
check(#taken == 5, "waits for attachment metadata")
delayedItem.ready = true
Pump(0.4)
check(taken[6] == "item:3", "takes item once metadata arrives")
Fire("MAIL_INBOX_UPDATE"); Pump(0.2)
delayedItem = nil
inbox[3] = { sender = "Alt", subject = "First", money = 0, cod = 0, items = {} }
inbox[4] = { sender = "Alt", subject = "Second", money = 0, cod = 0, items = {} }
inbox[5] = { sender = "Other", subject = "Third", money = 0, cod = 0, items = {} }
Fire("MAIL_INBOX_UPDATE")
FluxMailSelect3:SetChecked(true); FluxMailSelect3.OnClick(FluxMailSelect3)
IsControlKeyDown = function() return true end
FluxMailSelect4:SetChecked(true); FluxMailSelect4.OnClick(FluxMailSelect4)
check(FluxMailSelect3.checked and FluxMailSelect4.checked, "control selects same sender")
IsControlKeyDown = nil
IsShiftKeyDown = function() return true end
FluxMailSelect5:SetChecked(true); FluxMailSelect5.OnClick(FluxMailSelect5)
check(FluxMailSelect4.checked and FluxMailSelect5.checked, "shift selects inclusive range")
IsShiftKeyDown = nil
Fire("MAIL_CLOSED")
check(not FluxMailTakeSelected.enabled, "close leaves collection disabled")

print("Flux mail select: " .. checks .. " checks passed")
