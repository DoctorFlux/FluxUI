-- Inventory/Builtin/Watch.lua — bag/bank/equip events → Scheduler inventory tier
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Builtin = Inv.Builtin
local C = Inv.Containers

local started = false

local function Request(token)
	Flux.Scheduler.Request("inventory", token)
end

local function RefreshCaps()
	if Flux.Cap then
		if Flux.Cap.RefreshKeyring then
			Flux.Cap.RefreshKeyring()
		end
		if Flux.Cap.RefreshUnifiedBank then
			Flux.Cap.RefreshUnifiedBank()
		end
	end
end

function Builtin.Flush(tokens)
	if not tokens then
		Builtin.Bags.Refresh()
		Builtin.Bank.Refresh()
		Builtin.Equip.Refresh()
		if Builtin.Mail and Builtin.Mail.Refresh then
			Builtin.Mail.Refresh()
		end
		if Builtin.Auctions and Builtin.Auctions.Refresh then
			Builtin.Auctions.Refresh()
		end
		if Builtin.Void and Builtin.Void.Refresh then
			Builtin.Void.Refresh()
		end
		if Builtin.Guild and Builtin.Guild.Refresh then
			Builtin.Guild.Refresh()
		end
		if Builtin.Currency and Builtin.Currency.Refresh then
			Builtin.Currency.Refresh()
		end
		if Inv.NoteRefreshSettling then
			Inv.NoteRefreshSettling()
		end
		return
	end
	if tokens.bags then
		Builtin.Bags.Refresh()
		if Inv.NoteRefreshSettling then
			Inv.NoteRefreshSettling()
		end
	end
	if tokens.bank or tokens.warband then
		Builtin.Bank.Refresh()
	end
	if tokens.equip or tokens.equipped then
		Builtin.Equip.Refresh()
	end
	if tokens.mail and Builtin.Mail and Builtin.Mail.Refresh then
		Builtin.Mail.Refresh()
	end
	if tokens.auctions and Builtin.Auctions and Builtin.Auctions.Refresh then
		Builtin.Auctions.Refresh()
	end
	if tokens.void and Builtin.Void and Builtin.Void.Refresh then
		Builtin.Void.Refresh()
	end
	if tokens.guild and Builtin.Guild and Builtin.Guild.Refresh then
		Builtin.Guild.Refresh()
	end
	if tokens.currencies and Builtin.Currency and Builtin.Currency.Refresh then
		Builtin.Currency.Refresh()
	end
end

local classicDropBags, classicDropBank, classicDropWarband

local function IsEraOrAnniversary()
	local client = Flux.Client
	return client and (client.isEra or client.isAnniversary) or false
end

--- FluxInv's own frame already marks these dirty and pulses once on DELAYED.
local function FluxInvOwnsBagUpdate()
	local frame = _G.FluxInvEventFrame
	return frame and frame.IsEventRegistered and frame:IsEventRegistered("BAG_UPDATE") or false
end

local function BankIsOpen()
	return Builtin.Bank and Builtin.Bank.IsOpen and Builtin.Bank.IsOpen()
end

local function OnBagUpdate(_, bag)
	if Inv.source ~= "builtin" then
		return
	end
	if FluxInvOwnsBagUpdate() then
		return
	end
	bag = tonumber(bag)
	local settle = IsEraOrAnniversary()
	if bag == nil then
		Builtin.Bags.MarkDirty()
		if settle then
			classicDropBags = true
			if BankIsOpen() then
				Builtin.Bank.MarkDirty()
				classicDropBank = true
				classicDropWarband = true
			end
			return
		end
		Inv.NotifyBagStorm()
		Request("bags")
		return
	end
	if C.IsCarriedBag(bag) then
		Builtin.Bags.MarkDirty(bag)
		if settle then
			classicDropBags = true
			return
		end
		-- Loot / craft / use arrives as a burst; let heavy listeners batch.
		Inv.NotifyBagStorm()
		Request("bags")
	elseif C.IsWarbandBankContainer(bag) then
		if settle then
			if not BankIsOpen() then
				return
			end
			Builtin.Bank.MarkDirty(bag)
			classicDropWarband = true
			return
		end
		Builtin.Bank.MarkDirty(bag)
		Request("warband")
	elseif C.IsCharacterBankContainer(bag) then
		if settle then
			if not BankIsOpen() then
				return
			end
			Builtin.Bank.MarkDirty(bag)
			classicDropBank = true
			return
		end
		Builtin.Bank.MarkDirty(bag)
		Request("bank")
	elseif Flux.Cap and Flux.Cap.IsUnifiedBankTabBag and Flux.Cap.IsUnifiedBankTabBag(bag) then
		-- Newly purchased Camelot tabs can miss the cached ID lists until Invalidate.
		C.Invalidate()
		Builtin.Bank.MarkDirty(bag)
		Request("bank")
		if Inv.HasWarband() then
			Request("warband")
		end
	else
		Inv.NotifyBagStorm()
		Builtin.Bags.MarkDirty(bag)
		Request("bags")
	end
end

--- One light pass after the drop. Heavy listeners stay on their debounce.
local function OnBagUpdateDelayed()
	if Inv.source ~= "builtin" or not IsEraOrAnniversary() or FluxInvOwnsBagUpdate() then
		return
	end
	if not classicDropBags and not classicDropBank and not classicDropWarband then
		return
	end
	local tokens = { tier = "light" }
	if classicDropBags then
		tokens.bags = true
	end
	if classicDropBank then
		tokens.bank = true
	end
	if classicDropWarband then
		tokens.warband = true
	end
	classicDropBags, classicDropBank, classicDropWarband = false, false, false
	if Builtin.Flush then
		Builtin.Flush(tokens)
	end
	if Inv.Notify then
		Inv.Notify(tokens)
	end
end

--- Bank-only slot events sometimes arrive without a following BAG_UPDATE_DELAYED.
local classicDropFallback = false

local function ArmClassicDropFallback()
	if classicDropFallback or not (C_Timer and C_Timer.After) then
		return
	end
	classicDropFallback = true
	C_Timer.After(0.05, function()
		classicDropFallback = false
		OnBagUpdateDelayed()
	end)
end

local function OnBagContainer()
	if Inv.source ~= "builtin" then
		return
	end
	if Inv.MarkUnreliable then
		Inv.MarkUnreliable("bagContainer")
	end
	C.Invalidate()
	Builtin.Bags.Invalidate()
	Request("bags")
	if Builtin.Bank.IsOpen() then
		Builtin.Bank.Invalidate()
		Request("bank")
		if Inv.HasWarband() then
			Request("warband")
		end
	end
end

local function OnEquip()
	if Inv.source ~= "builtin" then
		return
	end
	Builtin.Equip.MarkDirty()
	Request("equip")
end

local function OnBankOpen()
	if Inv.SetBankOpenLatch then
		Inv.SetBankOpenLatch(true)
	end
	if Inv.source ~= "builtin" then
		return
	end
	Builtin.Bank.SetOpen(true)
	Request("bank")
	if Inv.HasWarband() then
		Request("warband")
	end
end

local function OnBankClose()
	if Inv.ShouldKeepBankOpen and Inv.ShouldKeepBankOpen() then
		return
	end
	if Inv.SetBankOpenLatch then
		Inv.SetBankOpenLatch(false)
	end
	if Inv.source ~= "builtin" then
		return
	end
	Builtin.Bank.SetOpen(false)
end

local function OnBankSlots(event)
	if Inv.source ~= "builtin" then
		return
	end
	if not Builtin.Bank.IsOpen() then
		return
	end
	-- A bag↔bank move fires this once per slot. The arg is a slot index, which
	-- overlaps bank-bag ids, so only the main bank container is dirty.
	if event == "PLAYERBANKSLOTS_CHANGED" and IsEraOrAnniversary() and not FluxInvOwnsBagUpdate() then
		local main = C.GetBankMainContainerID and C.GetBankMainContainerID()
		if main then
			Builtin.Bank.MarkDirty(main)
		else
			Builtin.Bank.MarkDirty()
		end
		classicDropBank = true
		ArmClassicDropFallback()
		return
	end
	Builtin.Bank.MarkDirty()
	Request("bank")
	if Inv.HasWarband() then
		Request("warband")
	end
end

local function OnBankTabsChanged()
	if Inv.source ~= "builtin" then
		return
	end
	C.Invalidate()
	if Flux.Cap and Flux.Cap.RefreshUnifiedBank then
		Flux.Cap.RefreshUnifiedBank()
	end
	OnBankSlots()
end

local function IsBankerInteraction(kind)
	local e = Enum and Enum.PlayerInteractionType
	if not e then
		return false
	end
	return kind == e.Banker or kind == e.AccountBanker or kind == e.CharacterBanker
end

local function OnInteractionShow(_, kind)
	if IsBankerInteraction(kind) then
		OnBankOpen()
	end
end

local function OnInteractionHide(_, kind)
	if IsBankerInteraction(kind) then
		OnBankClose()
	end
end

function Builtin.Start()
	if started then
		return
	end
	started = true
	Inv.source = "builtin"
	RefreshCaps()
	if Inv.Store and Inv.Store.HydrateSnapshots then
		Inv.Store.HydrateSnapshots()
	end
	Flux.Events.Register("BAG_UPDATE", OnBagUpdate)
	Flux.Events.Register("BAG_UPDATE_DELAYED", OnBagUpdateDelayed)
	Flux.Events.Register("BAG_CONTAINER_UPDATE", OnBagContainer)
	Flux.Events.Register("PLAYER_EQUIPMENT_CHANGED", OnEquip)
	Flux.Events.RegisterUnit("UNIT_INVENTORY_CHANGED", "player", OnEquip)
	Flux.Events.Register("BANKFRAME_OPENED", OnBankOpen)
	Flux.Events.Register("BANKFRAME_CLOSED", OnBankClose)
	Flux.Events.Register("PLAYERBANKSLOTS_CHANGED", OnBankSlots)
	Flux.Events.Register("PLAYERBANKBAGSLOTS_CHANGED", OnBankSlots)
	Flux.Events.Register("REAGENTBANK_UPDATE", OnBankSlots)
	Flux.Events.Register("PLAYERREAGENTBANKSLOTS_CHANGED", OnBankSlots)
	Flux.Events.Register("BANK_TABS_CHANGED", OnBankTabsChanged)
	Flux.Events.Register("BANK_TAB_SETTINGS_UPDATED", OnBankTabsChanged)
	Flux.Events.Register("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", OnBankSlots)
	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", OnInteractionShow)
	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", OnInteractionHide)

	Builtin.Bags.Invalidate()
	Builtin.Equip.Invalidate()
	Request("bags")
	Request("equip")
	if Builtin.Mail and Builtin.Mail.Start then
		Builtin.Mail.Start()
	end
	if Builtin.Auctions and Builtin.Auctions.Start then
		Builtin.Auctions.Start()
	end
	if Builtin.Void and Builtin.Void.Start then
		Builtin.Void.Start()
	end
	if Builtin.Guild and Builtin.Guild.Start then
		Builtin.Guild.Start()
	end
	if Builtin.Currency and Builtin.Currency.Start then
		Builtin.Currency.Start()
	end
	Inv.ready = true
end
