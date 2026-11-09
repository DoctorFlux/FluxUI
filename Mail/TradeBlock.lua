-- Temporarily suppress trades while the mailbox is open; restore the player's CVar.
local _, ns = ...
local Mail = ns.Flux.Mail
local frame = CreateFrame("Frame")
local opened = false
local previous

local function Restore()
	if previous ~= nil and SetCVar then SetCVar("BlockTrades", previous) end
	previous = nil
end

local function Update()
	if not opened or (Mail.IsEnabled and not Mail.IsEnabled("TradeBlock")) then
		Restore()
		return
	end
	if previous == nil and GetCVar and SetCVar then
		previous = GetCVar("BlockTrades")
		if previous == "0" then SetCVar("BlockTrades", "1") end
	end
end

if Mail.OnSettingsChanged then
	Mail.OnSettingsChanged(function(group, key)
		if group == "Modules" and key == "TradeBlock" then Update() end
	end)
end

frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
frame:SetScript("OnEvent", function(_, event, interactionType)
	local mailType = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
	if event == "MAIL_SHOW" or (mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and interactionType == mailType) then
		opened = true
		Update()
	elseif event == "MAIL_CLOSED" or event == "PLAYER_LEAVING_WORLD" or
		(mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and interactionType == mailType) then
		opened = false
		Update()
	end
end)
