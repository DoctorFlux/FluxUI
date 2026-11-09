-- Alt-left-click a bag item to attach it to the open native send-mail form.
local _, ns = ...
local Flux = ns.Flux
local Mail = Flux.Mail or {}
Flux.Mail = Mail

local mailboxOpen = false
local function CanAttach(category)
	if not mailboxOpen or not SendMailFrame or not SendMailFrame:IsShown() then return false end
	if InCombatLockdown and InCombatLockdown() then return false end
	if category then
		if Mail.IsEnabled and not Mail.IsEnabled("QuickAttach") then return false end
	else
		if Mail.IsEnabled and not Mail.IsEnabled("Express") then return false end
		if Mail.GetSetting and Mail.GetSetting("Express", "EnableAltClick") == false then return false end
		if not IsAltKeyDown or not IsAltKeyDown() then return false end
	end
	if CursorHasItem and CursorHasItem() then return false end
	if not ClickSendMailItemButton then return false end
	if not category and IsModifiedClick and (IsModifiedClick("CHATLINK") or IsModifiedClick("DRESSUP")) then return false end
	local slots = ATTACHMENTS_MAX_SEND or 12
	if HasSendMailItem then
		for i = 1, slots do if not HasSendMailItem(i) then return true end end
		return false
	end
	return true
end

function Mail.AttachBagItem(bag, slot, category)
	if not CanAttach(category) then return false end
	local container = Flux.Container
	if not container or not container.GetItemInfo or not container.PickupItem then return false end
	local info = container.GetItemInfo(bag, slot)
	if not info or not info.itemID or info.isLocked or info.isBound then return false end
	container.PickupItem(bag, slot)
	if CursorHasItem and not CursorHasItem() then return false end
	ClickSendMailItemButton()
	if CursorHasItem and CursorHasItem() then
		if ClearCursor then ClearCursor() end
		return false
	end
	return true
end

local function FromItemLocation(_, location)
	if Flux.Client and not (Flux.Client.isRetail or Flux.Client.isCamelot) then return end
	if not location or not location.IsBagAndSlot or not location:IsBagAndSlot() then return end
	if GetMouseButtonClicked and GetMouseButtonClicked() ~= "LeftButton" then return end
	local bag, slot = location:GetBagAndSlot()
	if type(bag) == "number" and type(slot) == "number" then Mail.AttachBagItem(bag, slot) end
end

-- Old client container buttons pass their own frame instead of ItemLocation.
local function FromClassicButton(button, mouseButton)
	if Flux.Client and (Flux.Client.isRetail or Flux.Client.isCamelot) then return end
	if mouseButton ~= "LeftButton" or not button or not button.GetParent then return end
	local parent = button:GetParent()
	local bag = parent and parent.GetID and parent:GetID()
	local slot = button.GetID and button:GetID()
	if type(bag) == "number" and type(slot) == "number" then Mail.AttachBagItem(bag, slot) end
end

if hooksecurefunc then
	if type(HandleModifiedItemClick) == "function" then
		hooksecurefunc("HandleModifiedItemClick", FromItemLocation)
	end
	if type(ContainerFrameItemButton_OnModifiedClick) == "function" then
		hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", FromClassicButton)
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:SetScript("OnEvent", function(_, event, interactionType)
	local interaction = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
	if event == "MAIL_SHOW" or (interaction and event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and interactionType == interaction) then
		mailboxOpen = true
	elseif event == "MAIL_CLOSED" or event == "PLAYER_LEAVING_WORLD" or
		(interaction and event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and interactionType == interaction) then
		mailboxOpen = false
	end
end)
