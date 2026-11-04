-- Expiry icon chooses return or delete and confirms mail with value.
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local frames = {}
local function widget(name)
	local w = { name = name, events = {}, shown = true }
	function w:RegisterEvent(event) self.events[event] = true end
	function w:SetScript(kind, fn) self[kind] = fn end
	function w:SetSize() end
	function w:SetPoint() end
	function w:SetAllPoints() end
	function w:SetTexCoord() end
	function w:SetTexture(texture) self.textureValue = texture end
	function w:CreateTexture() return widget() end
	function w:SetShown(value) self.shown = value end
	frames[#frames + 1] = w
	if name then _G[name] = w end
	return w
end
CreateFrame = function(_, name) return widget(name) end
InboxFrame = widget("InboxFrame")
InboxFrame.pageNum = 1
MailItem1ExpireTime = widget("MailItem1ExpireTime")
MailItem2ExpireTime = widget("MailItem2ExpireTime")
INBOXITEMS_TO_DISPLAY = 2
StaticPopupDialogs = {}
local popup
StaticPopup_Show = function(name) popup = StaticPopupDialogs[name] end
local deleted, returned = {}, {}
DeleteInboxItem = function(index) deleted[#deleted + 1] = index end
ReturnInboxItem = function(index) returned[#returned + 1] = index end
GetInboxNumItems = function() return 2 end
InboxItemCanDelete = function(index) return index == 1 end
GetInboxHeaderInfo = function(index)
	if index == 1 then return nil, nil, "Sender", "Value", 100, 0, nil, 0 end
	if index == 2 then return nil, nil, "Sender", "Return", 0, 0, nil, 0 end
end
local ns = { Flux = { Mail = { IsEnabled = function() return true end } } }
assert(loadfile("Mail/DoNotWant.lua"))("_FluxUI", ns)
local eventFrame
for _, w in ipairs(frames) do if w.events.MAIL_SHOW then eventFrame = w end end
eventFrame.OnEvent(eventFrame, "MAIL_SHOW")
check(FluxMailExpiryAction1 and FluxMailExpiryAction2, "both expiry icons created")
check(FluxMailExpiryAction1.shown and FluxMailExpiryAction2.shown, "icons shown at mailbox")
check(FluxMailExpiryAction1.texture.textureValue:find("NotReady"), "delete icon")
check(FluxMailExpiryAction2.texture.textureValue:find("ExpandArrow"), "return icon")
FluxMailExpiryAction1.OnClick()
check(popup and #deleted == 0, "value mail requires confirmation")
popup.OnAccept()
check(deleted[1] == 1, "confirmed delete uses selected index")
FluxMailExpiryAction2.OnClick()
check(returned[1] == 2, "return uses native API")
eventFrame.OnEvent(eventFrame, "MAIL_CLOSED")
check(not FluxMailExpiryAction1.shown, "icons hidden after close")
print("Flux mail expiry action: " .. checks .. " checks passed")
