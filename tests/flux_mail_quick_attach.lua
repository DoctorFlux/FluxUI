-- Alt-click attachment uses the Flux container adapter and one hook per client family.
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end

local function Run(retail)
	local hooks = {}
	local eventFrame
	CreateFrame = function()
		eventFrame = { events = {} }
		function eventFrame:RegisterEvent(event) self.events[event] = true end
		function eventFrame:SetScript(_, fn) self.onEvent = fn end
		return eventFrame
	end
	hooksecurefunc = function(name, fn) hooks[name] = fn end
	HandleModifiedItemClick = function() end
	ContainerFrameItemButton_OnModifiedClick = function() end
	SendMailFrame = { IsShown = function() return true end }
	local alt, cursor, full, bound, locked, combat = true, false, false, false, false, false
	IsAltKeyDown = function() return alt end
	CursorHasItem = function() return cursor end
	InCombatLockdown = function() return combat end
	IsModifiedClick = function() return false end
	GetMouseButtonClicked = function() return "LeftButton" end
	HasSendMailItem = function(i) return full and i <= 12 end
	ATTACHMENTS_MAX_SEND = 12
	local attached, picked = 0, 0
	ClickSendMailItemButton = function() attached = attached + 1; cursor = false end
	ClearCursor = function() cursor = false end
	local ns = { Flux = {
		Client = { isRetail = retail },
		Container = {
			GetItemInfo = function() return { itemID = 42, isBound = bound, isLocked = locked } end,
			PickupItem = function() picked = picked + 1; cursor = true end,
		},
	} }
	assert(loadfile("Mail/QuickAttach.lua"))("_FluxUI", ns)
	local mail = ns.Flux.Mail
	check(eventFrame.events.MAIL_SHOW and eventFrame.events.MAIL_CLOSED, "mail lifecycle registered")
	check(not mail.AttachBagItem(0, 1), "closed mailbox blocks attach")
	eventFrame.onEvent(eventFrame, "MAIL_SHOW")
	check(mail.AttachBagItem(0, 1), "attaches through Flux adapter")
	check(attached == 1 and picked == 1, "one pickup and one native attach")
	alt = false
	check(not mail.AttachBagItem(0, 1), "requires alt")
	alt = true; bound = true
	check(not mail.AttachBagItem(0, 1), "bound item skipped")
	bound = false; locked = true
	check(not mail.AttachBagItem(0, 1), "locked item skipped")
	locked = false; full = true
	check(not mail.AttachBagItem(0, 1), "full outgoing mail skipped")
	full = false; combat = true
	check(not mail.AttachBagItem(0, 1), "combat skipped")
	combat = false
	local location = { IsBagAndSlot = function() return true end, GetBagAndSlot = function() return 0, 1 end }
	local parent = { GetID = function() return 0 end }
	local button = { GetParent = function() return parent end, GetID = function() return 1 end }
	local before = attached
	hooks.HandleModifiedItemClick(nil, location)
	hooks.ContainerFrameItemButton_OnModifiedClick(button, "LeftButton")
	check(attached == before + 1, "only client-family hook acts")
	eventFrame.onEvent(eventFrame, "MAIL_CLOSED")
	check(not mail.AttachBagItem(0, 1), "close disarms attach")
end

Run(true)
Run(false)
print("Flux mail quick attach: " .. checks .. " checks passed")
