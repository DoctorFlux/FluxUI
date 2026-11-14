-- Postal category-button geometry, independently implemented with Flux container facts.
local _, ns = ...
local Flux = ns.Flux
local Mail = Flux.Mail or {}
Flux.Mail = Mail

local buttons = {}
local activeKey
local function SpellIcon(id)
	return Flux.Spell and Flux.Spell.GetIcon and Flux.Spell.GetIcon(id)
end

local function Categories()
	local client = Flux.Client or {}
	if client.isEra then
		return { { "Trade Goods", SpellIcon(2018) or 136241, 7, -1 },
			{ "Reagent", "Interface/Icons/inv_misc_food_02", 5, -1 } }
	end
	local list = {
		{ "Cloth", SpellIcon(3908) or 136249, 7, 5 },
		{ "Leather", SpellIcon(2108) or 136247, 7, 6 },
		{ "Metal & Stone", SpellIcon(2656) or 136248, 7, 7 },
		{ "Cooking", SpellIcon(2550) or 133971, 7, 8 },
		{ "Herb", SpellIcon(2383) or 136054, 7, 9 },
		{ "Enchanting", SpellIcon(7411) or 136244, 7, 12 },
	}
	if client.isRetail or client.isCamelot then
		list[1][2], list[2][2], list[3][2] = 4620681, 4620678, 4625105
		list[4][2], list[5][2], list[6][2] = 4620671, 133939, 4620672
		list[#list + 1] = { "Inscription", 4620676, 7, 16 }
		list[#list + 1] = { "Jewelcrafting", 4620677, 7, 4 }
	else
		list[#list + 1] = { "Jewelcrafting", SpellIcon(25229) or 134071, 7, 4 }
	end
	list[#list + 1] = { "Parts", "Interface/Icons/INV_Gizmo_FelIronCasing", 7, 1 }
	list[#list + 1] = { "Elemental", "Interface/Icons/INV_Elemental_Primal_Air", 7, 10 }
	if client.isRetail or client.isCamelot then
		list[#list + 1] = { "Optional Reagents", "Interface/Icons/INV_Bijou_Green", 7, 18 }
	else
		list[#list + 1] = { "Devices", "Interface/Icons/inv_gizmo_goblingtonkcontroller", 7, 3 }
		list[#list + 1] = { "Explosives", "Interface/Icons/INV_Misc_Ammo_Gunpowder_01", 7, 2 }
		if client.isMists then
			list[#list + 1] = { "Materials", "Interface/Icons/INV_Elemental_Primal_Nether", 7, 13 }
		end
	end
	list[#list + 1] = { "Other", "Interface/Icons/INV_Misc_Rune_09", 7, 11 }
	if client.isMists then list[#list + 1] = { "Item Enchantment", 237050, 7, 14 } end
	list[#list + 1] = { "Trade Goods", "Interface/Icons/Ability_Ensnare", 7, -1 }
	return list
end

local function RecipientKey(classID, subClassID)
	return tostring(classID) .. ":" .. tostring(subClassID)
end

local function RecipientDB()
	if type(FluxMailDB) ~= "table" then FluxMailDB = {} end
	if type(FluxMailDB.categoryRecipients) ~= "table" then FluxMailDB.categoryRecipients = {} end
	return FluxMailDB.categoryRecipients
end

local function SetRecipient(key, value)
	value = type(value) == "string" and value:match("^%s*(.-)%s*$") or ""
	if value == "" then RecipientDB()[key] = nil else RecipientDB()[key] = value end
end

local function FreeSendSlots(firstOnly)
	if not HasSendMailItem then return 0 end
	local free = 0
	for i = 1, (ATTACHMENTS_MAX_SEND or 12) do
		if not HasSendMailItem(i) then
			free = free + 1
			-- The per-slot gate needs current availability, not a full recount.
			if firstOnly then return free end
		end
	end
	return free
end

function Mail.AttachCategory(classID, subClassID)
	if not Mail.IsEnabled or not Mail.IsEnabled("QuickAttach") then return 0 end
	if not SendMailFrame or not SendMailFrame:IsShown() or not Flux.Container then return 0 end
	if CursorHasItem and CursorHasItem() then return 0 end
	local key = RecipientKey(classID, subClassID)
	local recipient = RecipientDB()[key]
	if recipient and SendMailNameEditBox then SendMailNameEditBox:SetText(recipient) end
	local added = 0
	local limit = FreeSendSlots()
	local maxBag = (Flux.Client and (Flux.Client.isRetail or Flux.Client.isCamelot)) and 5 or (NUM_BAG_SLOTS or 4)
	for bag = 0, maxBag do
		if Mail.GetSetting("QuickAttach", "EnableBag" .. bag) ~= false then
			local slots = Flux.Container.GetNumSlots and Flux.Container.GetNumSlots(bag) or 0
			for slot = 1, slots do
				if added >= limit or FreeSendSlots(true) == 0 then return added end
				local info = Flux.Container.GetItemInfo and Flux.Container.GetItemInfo(bag, slot)
				if info and info.itemID and not info.isLocked and not info.isBound then
					local _, _, _, _, _, _, _, _, _, _, _, itemClass, itemSubclass, bindType = Flux.Item.GetInfo(info.itemID)
					if itemClass == classID and (subClassID == -1 or itemSubclass == subClassID)
						and bindType ~= (LE_ITEM_BIND_ON_ACQUIRE or 1) then
						if Mail.AttachBagItem(bag, slot, true) then added = added + 1 end
					end
				end
			end
		end
	end
	return added
end

if StaticPopupDialogs then
	StaticPopupDialogs.FLUX_MAIL_CATEGORY_RECIPIENT = {
		text = "Default recipient:", button1 = ACCEPT, button2 = CANCEL,
		hasEditBox = 1, maxLetters = 77, timeout = 0, hideOnEscape = true,
		OnShow = function(self)
			local edit = self.editBox or _G[self:GetName() .. "EditBox"]
			if edit then edit:SetText(RecipientDB()[activeKey] or ""); edit:HighlightText(); edit:SetFocus() end
		end,
		OnAccept = function(self)
			local edit = self.editBox or _G[self:GetName() .. "EditBox"]
			if edit then SetRecipient(activeKey, edit:GetText()) end
		end,
	}
end

local function UpdateVisibility()
	local enabled = Mail.IsEnabled and Mail.IsEnabled("QuickAttach")
	for i = 1, #buttons do buttons[i]:SetShown(enabled and SendMailFrame and SendMailFrame:IsShown()) end
end

local function Install()
	if #buttons > 0 or not SendMailFrame or not MailFrame then return end
	local categories = Categories()
	for i = 1, #categories do
		local entry = categories[i]
		local button = CreateFrame("Button", "FluxMailCategory" .. i, SendMailFrame, "ActionButtonTemplate")
		local height = math.floor((button:GetHeight() or 36) + 0.5)
		button:SetScale(0.73)
		local icon = button.icon or button.Icon or _G[button:GetName() .. "Icon"]
		if icon then icon:SetTexture(entry[2]) end
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 0, -(i - 1) * height)
		button:RegisterForClicks("AnyUp")
		button:SetScript("OnClick", function(_, mouseButton)
			if mouseButton == "RightButton" then
				activeKey = RecipientKey(entry[3], entry[4])
				if StaticPopup_Show then StaticPopup_Show("FLUX_MAIL_CATEGORY_RECIPIENT") end
			else
				Mail.AttachCategory(entry[3], entry[4])
			end
		end)
		button:SetScript("OnEnter", function(self)
			if not GameTooltip then return end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(entry[1])
			local recipient = RecipientDB()[RecipientKey(entry[3], entry[4])]
			if recipient then GameTooltip:AddLine("Default recipient: " .. recipient, 1, 1, 1) end
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
		buttons[i] = button
	end
	UpdateVisibility()
end

if Mail.OnSettingsChanged then
	Mail.OnSettingsChanged(function(group, key)
		if group == "Modules" and key == "QuickAttach" then UpdateVisibility() end
	end)
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:SetScript("OnEvent", function(_, event, interactionType)
	local mailType = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
	if event == "MAIL_SHOW" or (mailType and event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and interactionType == mailType) then
		Install()
		UpdateVisibility()
		if #buttons == 0 and C_Timer and C_Timer.After then C_Timer.After(0, Install) end
	end
end)
