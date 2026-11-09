-- Inventory/Builtin/Guild.lua — guild bank while the vault is open.
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Builtin = Inv.Builtin
local Store = Inv.Store
local Cap = Flux.Cap

local Guild = {}
Builtin.Guild = Guild

local started = false
local open = false
local currentGuild
local MAX_SLOTS = 98

local function Request()
	Flux.Scheduler.Request("inventory", "guild")
end

local function NumericID(value)
	local n = tonumber(value)
	if n and n > 0 then
		return n
	end
	if Flux.Secrets and Flux.Secrets.SafeGetNumber then
		n = Flux.Secrets.SafeGetNumber(value, 0)
		if n and n > 0 then
			return n
		end
	end
	return nil
end

local function GuildKey()
	if not IsInGuild or not IsInGuild() or not GetGuildInfo then
		return nil
	end
	local guildName, _, _, realm = GetGuildInfo("player")
	if not guildName then
		return nil
	end
	realm = realm or (GetNormalizedRealmName and GetNormalizedRealmName())
	if not realm or realm == "" then
		return nil
	end
	return guildName .. "-" .. realm, guildName, realm
end

local function ApplySnapshot(guildRec)
	local snap = Inv.snapshots.guild
	if not snap then
		return
	end
	if wipe then
		wipe(snap.byBag)
	else
		for k in pairs(snap.byBag) do
			snap.byBag[k] = nil
		end
	end
	local counts = {}
	local bank = guildRec and guildRec.bank
	if type(bank) == "table" then
		for tabIndex, tab in pairs(bank) do
			local dest = {}
			snap.byBag[tabIndex] = dest
			local slots = tab and (tab.slots or tab)
			if type(slots) == "table" then
				for slot, rec in pairs(slots) do
					local id = rec and NumericID(rec.itemID)
					if id then
						local n = tonumber(rec.itemCount or rec.count) or 1
						dest[slot] = { itemID = id, count = n, link = rec.itemLink or rec.link }
						counts[id] = (counts[id] or 0) + n
					end
				end
			end
		end
	end
	snap.counts = counts
	snap.money = guildRec and tonumber(guildRec.money) or 0
	snap.generation = (snap.generation or 0) + 1
end

function Guild.Refresh()
	if Store.UsesSyndicator() or not Cap.hasGuildBank then
		return
	end
	if not open then
		return
	end
	local key, guildName, realm = GuildKey()
	if not key then
		return
	end
	currentGuild = key
	local rec = Store.EnsureGuild(key, guildName, realm)
	if not rec then
		return
	end
	Store.SetCurrentGuild(key)
	rec.details.visited = true
	if GetGuildBankMoney then
		rec.money = GetGuildBankMoney() or rec.money or 0
	end
	local numTabs = GetNumGuildBankTabs and GetNumGuildBankTabs() or 0
	rec.bank = rec.bank or {}
	for tabIndex = 1, numTabs do
		local name, icon, isViewable = GetGuildBankTabInfo(tabIndex)
		rec.bank[tabIndex] = rec.bank[tabIndex] or { slots = {} }
		local tab = rec.bank[tabIndex]
		tab.name = name
		tab.iconTexture = icon
		tab.isViewable = isViewable and true or false
		tab.slots = tab.slots or {}
		if wipe then
			wipe(tab.slots)
		else
			for k in pairs(tab.slots) do
				tab.slots[k] = nil
			end
		end
		if tab.isViewable and GetGuildBankItemLink then
			for slot = 1, MAX_SLOTS do
				local link = GetGuildBankItemLink(tabIndex, slot)
				if link then
					local texture, count, _, _, quality = GetGuildBankItemInfo(tabIndex, slot)
					local itemID = tonumber(link:match("item:(%d+)"))
					if C_Item and C_Item.GetItemInfoInstant then
						itemID = C_Item.GetItemInfoInstant(link) or itemID
					end
					itemID = NumericID(itemID)
					if itemID then
						tab.slots[slot] = {
							itemID = itemID,
							itemCount = tonumber(count) or 1,
							iconTexture = texture,
							itemLink = link,
							quality = quality,
						}
					end
				end
			end
		end
	end
	Store.MarkGuildPending(key)
	ApplySnapshot(rec)
end

function Guild.Start()
	if started or Store.UsesSyndicator() or not Cap.hasGuildBank then
		return
	end
	started = true

	local function OpenVault()
		open = true
		local key, guildName, realm = GuildKey()
		if key then
			currentGuild = key
			Store.EnsureGuild(key, guildName, realm)
			Store.SetCurrentGuild(key)
			if QueryGuildBankTab and GetNumGuildBankTabs then
				local n = GetNumGuildBankTabs() or 0
				for i = 1, n do
					pcall(QueryGuildBankTab, i)
				end
			end
		end
		Request()
	end

	local function CloseVault()
		open = false
	end

	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
		local e = Enum and Enum.PlayerInteractionType
		if e and kind == e.GuildBanker then
			OpenVault()
		end
	end)
	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
		local e = Enum and Enum.PlayerInteractionType
		if e and kind == e.GuildBanker then
			CloseVault()
		end
	end)
	Flux.Events.Register("GUILDBANKFRAME_OPENED", OpenVault)
	Flux.Events.Register("GUILDBANKFRAME_CLOSED", CloseVault)
	Flux.Events.Register("GUILDBANKBAGSLOTS_CHANGED", function()
		if open then
			Request()
		end
	end)
	Flux.Events.Register("GUILDBANK_UPDATE_TABS", function()
		if open then
			Request()
		end
	end)
	Flux.Events.Register("GUILDBANK_UPDATE_MONEY", function()
		if open then
			Request()
		end
	end)
	Flux.Events.Register("PLAYER_GUILD_UPDATE", function()
		local key, guildName, realm = GuildKey()
		if key then
			currentGuild = key
			Store.EnsureGuild(key, guildName, realm)
			Store.SetCurrentGuild(key)
		else
			Store.SetCurrentGuild(nil)
		end
	end)
end
