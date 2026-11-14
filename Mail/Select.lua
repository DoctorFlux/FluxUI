-- Select visible inbox rows and take only their money/attachments, one server action at a time.
local _, ns = ...
local Flux = ns.Flux
local Mail = Flux.Mail or {}
Flux.Mail = Mail

local selected, checks = {}, {}
local lastCheck
local takeButton, returnButton, worker
local opened = false
local run = 0
local pendingWakes = {}
local lastRestockTake
local Step, Schedule
local MAX_WAIT = 8
local originalFirstPoint, originalWidths, originalExpiry = nil, {}, {}

local function Option(group, key, fallback)
	if group == "Restock" and (key == "KeepFreeSpace" or key == "SpamChat") then group = "OpenAll" end
	local value = Mail.GetSetting and Mail.GetSetting(group, key)
	return value == nil and fallback or value
end

local function Header(index)
	if not GetInboxHeaderInfo then return nil end
	local _, _, sender, subject, money, cod, _, items, _, _, _, _, isGM = GetInboxHeaderInfo(index)
	if not sender and not subject then return nil end
	return { sender = sender or "", subject = subject or "", money = tonumber(money) or 0,
		cod = tonumber(cod) or 0, items = tonumber(items) or 0, gm = isGM == true }
end

local function Same(a, b)
	return a and b and a.sender == b.sender and a.subject == b.subject and a.cod == b.cod
end

local function Notice(message)
	if Mail.Print then Mail.Print(message); return end
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cff70d7ffFlux Mail:|r " .. message)
	end
end

local function RefreshRows()
	if not InboxFrame then return end
	local page = tonumber(InboxFrame.pageNum) or 1
	local count = GetInboxNumItems and GetInboxNumItems() or 0
	for row = 1, #checks do
		local checkbox = checks[row]
		local index = (page - 1) * (INBOXITEMS_TO_DISPLAY or 7) + row
		local h = index <= count and Header(index) or nil
		checkbox.mailIndex = index
		checkbox:SetShown(h ~= nil and (not Mail.IsEnabled or Mail.IsEnabled("Select")))
		if h then
			local old = selected[index]
			if old and not Same(old, h) then selected[index] = nil end
			checkbox:SetChecked(selected[index] ~= nil)
			if checkbox.indexText then checkbox.indexText:SetText(index) end
		end
	end
	if takeButton then
		local visible = not Mail.IsEnabled or Mail.IsEnabled("Select")
		takeButton:SetShown(visible)
		if returnButton then returnButton:SetShown(visible) end
		local n = 0
		for _ in pairs(selected) do n = n + 1 end
		takeButton:SetText(worker and "In Progress" or "Open")
		takeButton:SetEnabled(opened and (worker ~= nil or n > 0))
		if returnButton then
			returnButton:SetText(worker and "In Progress" or "Return")
			returnButton:SetEnabled(opened and worker == nil and n > 0)
		end
	end
end

local function ApplyLayout()
	if not InboxFrame or not originalFirstPoint then return end
	local enabled = not Mail.IsEnabled or Mail.IsEnabled("Select")
	local first = _G.MailItem1
	if first then
		first:ClearAllPoints()
		if enabled then first:SetPoint("TOPLEFT", InboxFrame, "TOPLEFT", 29, -68)
		else first:SetPoint(unpack(originalFirstPoint)) end
	end
	for i = 1, #originalWidths do
		local row = _G["MailItem" .. i]
		if row then row:SetWidth(enabled and 280 or originalWidths[i]) end
		local expiry = _G["MailItem" .. i .. "ExpireTime"]
		if expiry and originalExpiry[i] then
			expiry:ClearAllPoints()
			if enabled then expiry:SetPoint("TOPRIGHT", row, "TOPRIGHT", 10, -4)
			else expiry:SetPoint(unpack(originalExpiry[i])) end
		end
	end
end

local function Stop(message)
	local group = worker and worker.group or "Select"
	local callbacks = worker and worker.callbacks
	if worker and worker.items and (not message or not message:find("Finished", 1, true)) then
		lastRestockTake = nil -- A cancelled/failed session has no next take deadline.
	end
	for key, wake in pairs(pendingWakes) do
		if wake.timer and wake.timer.Cancel then wake.timer:Cancel() end
		pendingWakes[key] = nil
	end
	worker = nil
	run = run + 1
	RefreshRows()
	if Mail.OnJobStateChanged then Mail.OnJobStateChanged(false, group, message) end
	if callbacks and callbacks.OnStop then callbacks.OnStop(message) end
	if message and (Option(group, "SpamChat", true) or message:find("Stopped", 1, true)) then Notice(message) end
end

local function RestockDelay()
	local speed = tonumber(Mail.GetSetting and Mail.GetSetting("OpenSpeed")) or 0.5
	if speed < 0 or speed ~= speed or speed == math.huge then speed = 0.5 end
	return lastRestockTake and math.max(0, lastRestockTake + speed - (GetTime and GetTime() or 0)) or 0
end

if Mail.OnSettingsChanged then
	Mail.OnSettingsChanged(function(group, key)
		if worker and worker.items and (group == "OpenSpeed" or group == "Modules") and Schedule then
			Schedule(RestockDelay())
		end
		if group ~= "Modules" then return end
		if worker and Mail.IsEnabled and not Mail.IsEnabled(worker.group) then
			Stop("Stopped: mail module disabled.")
		end
		if key == "Select" or key == nil then ApplyLayout(); RefreshRows() end
	end)
end

Schedule = function(delay, timeout)
	if not C_Timer or (not C_Timer.After and not C_Timer.NewTimer) then Stop("Mail timer unavailable."); return end
	if not worker then return end
	local key = timeout and "timeout" or "progress"
	local id, action = run, worker.pending
	local when = GetTime and (GetTime() + delay)
	local old = pendingWakes[key]
	if old and old.run == id and old.action == action
		and (not when or not old.when or old.when <= when) then return end
	if old and old.timer and old.timer.Cancel then old.timer:Cancel() end
	local wake = { run = id, action = action, when = when }
	pendingWakes[key] = wake
	local function Resume()
		if pendingWakes[key] ~= wake then return end
		pendingWakes[key] = nil
		-- Inbox updates can repeat, and an old action's watchdog can outlive it.
		-- Only its current action may resume at the originally requested delay.
		if worker and run == id and worker.pending == action then Step() end
	end
	if C_Timer.NewTimer then wake.timer = C_Timer.NewTimer(delay, Resume)
	else C_Timer.After(delay, Resume) end
end

local function ProgressPending()
	local p = worker and worker.pending
	if not p then return true end
	local h = Header(p.index)
	if worker.items and p.itemID then
		local remaining = worker.callbacks.GetItems()[p.itemID] or 0
		if remaining <= (worker.items[p.itemID] or 0) - p.count then
			-- The receipt owner already proved this arrival. An identical next
			-- mail can occupy the same index/slot; do not credit it a second time.
			worker.items[p.itemID] = math.max(0, (worker.items[p.itemID] or 0) - p.count)
			worker.pending = nil
			if not Same(h, p.header) then Stop("Finished taking selected mail."); return false end
			return true
		end
	end
	if not Same(h, p.header) then
		if worker.items then
			Stop("Stopped: mailbox messages changed before the attachment was confirmed.")
			return false
		end
		selected[p.index] = nil
		worker.pending = nil
		worker.position = worker.position + 1
		return true
	end
	if p.action == "return" or p.action == "delete" then
		if GetTime and GetTime() - p.started >= MAX_WAIT then
			Stop("Stopped: the last mailbox action was not confirmed.")
		end
		return false
	end
	if p.action == "money" and h.money < p.header.money then
		worker.pending = nil
		return true
	end
	if p.action == "item" and GetInboxItem then
		local name, itemID, _, count, _, _, isCurrency = GetInboxItem(p.index, p.slot)
		local removed = h.items < p.header.items or (not name and not isCurrency) or (tonumber(count) or 0) < p.count
		if worker.items then removed = not name or itemID ~= p.itemID or (tonumber(count) or 0) < p.count end
		if removed then
			if worker.items then
				worker.items[p.itemID] = math.max(0, (worker.items[p.itemID] or 0) - p.count)
				if worker.callbacks.OnTaken then worker.callbacks.OnTaken(p.itemID, p.count) end
			end
			worker.pending = nil
			return true
		end
	end
	if GetTime and GetTime() - p.started >= MAX_WAIT then
		Stop("Stopped: the last mailbox action was not confirmed. Check your bags.")
	end
	return false
end

local function WaitForNativeCommand()
	if not (C_Mail and type(C_Mail.IsCommandPending) == "function" and C_Mail.IsCommandPending()) then
		if worker.nativeWaitStarted and not worker.pending then
			local wake = pendingWakes.timeout
			if wake and wake.action == nil then
				if wake.timer and wake.timer.Cancel then wake.timer:Cancel() end
				pendingWakes.timeout = nil
			end
		end
		worker.nativeWaitStarted = nil
		return false
	end
	local now = GetTime()
	local since = worker.pending and worker.pending.started or worker.nativeWaitStarted or now
	worker.nativeWaitStarted = since
	local remaining = MAX_WAIT - (now - since)
	if remaining <= 0 then
		Stop("Stopped: a mailbox command is still pending. Try again when it finishes.")
	else
		Schedule(math.min(0.1, remaining))
		Schedule(remaining, true)
	end
	return true
end

Step = function()
	if not worker then return end
	if not opened or not MailFrame or not MailFrame:IsShown() then Stop(); return end
	if Mail.IsEnabled and not Mail.IsEnabled(worker.group) then Stop("Stopped: mail module disabled."); return end
	if worker.items and InCombatLockdown and InCombatLockdown() then Stop(); return end
	if worker.items and OpenAllMail and OpenAllMail.timeUntilNextRetrieval ~= nil then Stop(); return end
	-- Header/item updates can arrive before the client's command completes.
	-- Like native Open All, wait for its command gate before advancing the job.
	if WaitForNativeCommand() then return end
	if worker.items and not next(worker.callbacks.GetItems()) then Stop("Finished taking selected mail."); return end
	if not ProgressPending() then return end
	if worker.items and not next(worker.callbacks.GetItems()) then Stop("Finished taking selected mail."); return end
	if worker.callbacks and worker.callbacks.OnSnapshot and not worker.snapshotReady then
		local ready = worker.callbacks.OnSnapshot()
		if ready == nil then Stop("Stopped: mailbox data was not available. Try again after it updates."); return end
		if ready == false then Schedule(MAX_WAIT, true); return end
		-- The initial list has a complete snapshot. Each later attachment keeps
		-- its live header/slot and receipt proof checks below; the background
		-- snapshot must not add a second opening interval to every proven take.
		worker.snapshotReady = true
	end
	while worker.position <= #worker.list do
		local row = worker.list[worker.position]
		local h = Header(row.index)
		if h and not worker.announced[row.index] and Option(worker.group, "SpamChat", true) then
			worker.announced[row.index] = true
			Notice("Processing Message " .. row.index .. ": " .. h.subject)
		end
		if Same(h, row.header) and not h.gm and worker.mode ~= "take" then
			local allowed = worker.mode == "return" and ReturnInboxItem
				or worker.mode == "delete" and DeleteInboxItem and h.money == 0 and h.items == 0
					and InboxItemCanDelete and InboxItemCanDelete(row.index)
			if allowed then
				worker.pending = { action = worker.mode, index = row.index, header = h,
					started = GetTime and GetTime() or 0 }
				if worker.mode == "return" then ReturnInboxItem(row.index) else DeleteInboxItem(row.index) end
				Schedule(MAX_WAIT, true)
				return
			end
			worker.skipped = true
		elseif worker.mode == "take" and Same(h, row.header) and not h.gm and h.cod == 0 then
			local action, slot, count
			if h.money > 0 and not worker.items then
				action = "money"
			elseif h.items > 0 and GetInboxItem then
				local free = Flux.Container and Flux.Container.GetTotalFreeBagSlots
				if not free or free() > (tonumber(Option(worker.group, "KeepFreeSpace", 1)) or 1) then
					local wanted = worker.items and worker.callbacks.GetItems()
					local known = 0
					for i = (ATTACHMENTS_MAX_RECEIVE or 12), 1, -1 do
						local name, itemID, _, itemCount, _, _, isCurrency = GetInboxItem(row.index, i)
						if name or isCurrency then known = known + 1 end
						local allowed = not worker.items or (name and not isCurrency and itemID and wanted
							and (tonumber(itemCount) or 0) > 0
							and itemCount <= math.min(worker.items[itemID] or 0, wanted[itemID] or 0))
						if (name or isCurrency) and allowed then
							action, slot, count = "item", i, tonumber(itemCount) or 1
							break
						end
					end
					if not action and (not worker.items or known < h.items) then
						local attempts = (worker.unavailableAttempts[row.index] or 0) + 1
						worker.unavailableAttempts[row.index] = attempts
						if attempts < 20 then Schedule(math.max(0.3, tonumber(Mail.GetSetting and Mail.GetSetting("OpenSpeed")) or 0.5)); return end
						worker.skippedUnavailable = true
					end
				else
					worker.skippedFull = true
				end
			end
			if action then
				if worker.items then
					local delay = RestockDelay()
					if delay > 0 then Schedule(delay); return end
				end
				worker.pending = { action = action, index = row.index, slot = slot,
					count = count, header = h, started = GetTime and GetTime() or 0 }
				if worker.items then
					local _, itemID = GetInboxItem(row.index, slot)
					worker.pending.itemID = itemID
					if worker.callbacks.OnTake(itemID, count) == false then worker.pending = nil; Stop(); return end
				end
				if worker.items then lastRestockTake = worker.pending.started end
				if action == "money" then TakeInboxMoney(row.index) else TakeInboxItem(row.index, slot) end
				Schedule(MAX_WAIT, true)
				return
			end
		end
		if not worker.items then selected[row.index] = nil end
		worker.position = worker.position + 1
	end
	local mode, skippedFull, skipped = worker.mode, worker.skippedFull, worker.skipped
	local skippedUnavailable = worker.skippedUnavailable
	if mode == "take" then
		Stop((skippedFull or skippedUnavailable) and
			"Finished; some selected items remain in the mailbox." or "Finished taking selected mail.")
	else
		local verb = mode == "return" and "returning" or "deleting"
		Stop("Finished " .. verb .. " selected mail." .. (skipped and " Some messages were not eligible." or ""))
	end
end

-- Restock shares the existing command owner and cadence, but never expands a
-- matched attachment into a whole-message money/item collection.
function Mail.GetJobGroup() return worker and worker.group end
function Mail.NotifyRestockSnapshotReady()
	-- Publish through the same command owner. Stop/close/action identity still
	-- invalidates stale wakes, and Step rechecks the native pending command.
	if worker and worker.items then Schedule(RestockDelay()) end
end
function Mail.StopRestockItems()
	if worker and worker.group == "Restock" then Stop() end
end
function Mail.ProcessRestockItems(items, callbacks)
	if worker or not opened or not MailFrame or not MailFrame:IsShown() then return false end
	if InCombatLockdown and InCombatLockdown() then return false end
	if OpenAllMail and OpenAllMail.timeUntilNextRetrieval ~= nil then return false end
	if Mail.IsEnabled and not Mail.IsEnabled("Restock") then return false end
	if type(items) ~= "table" or type(callbacks) ~= "table" or type(callbacks.GetItems) ~= "function"
		or type(callbacks.OnTake) ~= "function" or not GetInboxNumItems then return false end
	local subset, list = {}, callbacks.list or {}
	for id, quantity in pairs(items) do
		if type(id) == "number" and id > 0 and type(quantity) == "number" and quantity > 0 then subset[id] = math.floor(quantity) end
	end
	if not next(subset) then return false end
	if not callbacks.list then
		for index = GetInboxNumItems(), 1, -1 do
			local h = Header(index)
			if h and not h.gm and h.cod == 0 and h.items > 0 then list[#list + 1] = { index = index, header = h } end
		end
	end
	if #list == 0 then return false end
	table.sort(list, function(a, b) return a.index > b.index end)
	run = run + 1
	worker = { list = list, position = 1, mode = "take", group = "Restock", items = subset,
		callbacks = callbacks, announced = {}, unavailableAttempts = {} }
	RefreshRows()
	if Mail.OnJobStateChanged then Mail.OnJobStateChanged(true, "Restock") end
	Step()
	return true
end

function Mail.ProcessSelected(mode, providedList, group)
	if mode ~= "take" and mode ~= "return" and mode ~= "delete" then return end
	if worker then Stop("Stopped selected mail job."); return end
	if not opened or not MailFrame or not MailFrame:IsShown() or not GetInboxNumItems then return end
	local list = providedList or {}
	if not providedList then
		local shown = GetInboxNumItems() or 0
		for index, h in pairs(selected) do
			if index <= shown and Same(Header(index), h) then
				list[#list + 1] = { index = index, header = h }
			end
		end
	end
	if #list == 0 then RefreshRows(); return end
	table.sort(list, function(a, b) return a.index > b.index end)
	run = run + 1
	worker = { list = list, position = 1, mode = mode, group = group or "Select",
		announced = {}, unavailableAttempts = {} }
	RefreshRows()
	if Mail.OnJobStateChanged then Mail.OnJobStateChanged(true, worker.group) end
	Step()
end

function Mail.TakeSelected() Mail.ProcessSelected("take") end

local function Install()
	if takeButton or not InboxFrame then return end
	local first = _G.MailItem1
	if first then
		originalFirstPoint = { first:GetPoint() }
	end
	for i = 1, (INBOXITEMS_TO_DISPLAY or 7) do
		local row = _G["MailItem" .. i]
		if row then
			originalWidths[i] = row:GetWidth()
			local expiry = _G["MailItem" .. i .. "ExpireTime"]
			if expiry then
				originalExpiry[i] = { expiry:GetPoint() }
			end
			local checkbox = CreateFrame("CheckButton", "FluxMailSelect" .. i, row, "InterfaceOptionsCheckButtonTemplate")
			checkbox:SetSize(24, 24)
			checkbox:SetPoint("RIGHT", row, "LEFT", 1, -5)
			checkbox:SetHitRectInsets(0, 0, 0, 0)
			local text = checkbox:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
			text:SetPoint("BOTTOM", checkbox, "TOP", 0, 0)
			checkbox.indexText = text
			checkbox:SetScript("OnClick", function(self)
				local index = self.mailIndex
				if lastCheck and IsShiftKeyDown and IsShiftKeyDown() then
					for current = math.min(lastCheck, index), math.max(lastCheck, index) do
						selected[current] = Header(current)
					end
				elseif IsControlKeyDown and IsControlKeyDown() then
					local header = Header(index)
					if header then
						for current = 1, (GetInboxNumItems and GetInboxNumItems() or 0) do
							local candidate = Header(current)
							if candidate and candidate.sender == header.sender then
								selected[current] = self:GetChecked() and candidate or nil
							end
						end
					end
				elseif self:GetChecked() then selected[index] = Header(index); lastCheck = index
				else selected[index] = nil end
				RefreshRows()
			end)
			checks[i] = checkbox
		end
	end
	takeButton = CreateFrame("Button", "FluxMailTakeSelected", InboxFrame, "UIPanelButtonTemplate")
	takeButton:SetSize(120, 25)
	takeButton:SetPoint("RIGHT", InboxFrame, "TOP", 0, -42)
	takeButton:SetScript("OnClick", Mail.TakeSelected)
	returnButton = CreateFrame("Button", "FluxMailReturnSelected", InboxFrame, "UIPanelButtonTemplate")
	returnButton:SetSize(120, 25)
	returnButton:SetPoint("LEFT", InboxFrame, "TOP", 5, -42)
	returnButton:SetText("Return")
	returnButton:SetScript("OnClick", function() Mail.ProcessSelected("return") end)
	if hooksecurefunc then
		if type(InboxFrame_Update) == "function" then hooksecurefunc("InboxFrame_Update", RefreshRows) end
		if type(InboxFrame.Update) == "function" then hooksecurefunc(InboxFrame, "Update", RefreshRows) end
	end
	ApplyLayout()
	RefreshRows()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("MAIL_INBOX_UPDATE")
frame:RegisterEvent("MAIL_FAILED")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:SetScript("OnEvent", function(_, event, interactionType)
	local mailType = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
	if event == "MAIL_SHOW" or (mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and interactionType == mailType) then
		opened = true
		Install()
		if not takeButton and C_Timer and C_Timer.After then C_Timer.After(0, Install) end
	elseif event == "MAIL_CLOSED" or event == "PLAYER_LEAVING_WORLD" or
		(mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and interactionType == mailType) then
		opened = false
		lastRestockTake = nil
		lastCheck = nil
		for index in pairs(selected) do selected[index] = nil end
		Stop()
	elseif event == "MAIL_FAILED" then
		if worker and worker.items then Stop("Stopped: the mailbox rejected the attachment request.") end
	elseif event == "MAIL_INBOX_UPDATE" then
		RefreshRows()
		if worker and worker.items then Schedule(RestockDelay())
		elseif worker and worker.pending then Schedule(tonumber(Mail.GetSetting and Mail.GetSetting("OpenSpeed")) or 0.5) end
	end
end)
