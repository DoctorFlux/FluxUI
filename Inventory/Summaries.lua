-- Inventory/Summaries.lua — pending item-location index for tooltips.
-- Rebuilds on tooltip show, not on every bag pulse.
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Store = Inv.Store

local Summaries = {}
Inv.Summaries = Summaries

local function EmptyLoc()
	return {
		bags = 0,
		bank = 0,
		mail = 0,
		equipped = 0,
		void = 0,
		auctions = 0,
	}
end

local function AddCount(summary, key, field, n)
	if not key or not n or n <= 0 then
		return
	end
	local row = summary[key]
	if not row then
		row = EmptyLoc()
		summary[key] = row
	end
	row[field] = (row[field] or 0) + n
end

local function WalkSlots(slots, summary, field)
	if type(slots) ~= "table" then
		return
	end
	for _, rec in pairs(slots) do
		if type(rec) == "table" then
			local key = Store.GetItemKey(rec.link or rec.itemLink, rec.itemID)
			local n = tonumber(rec.count or rec.itemCount) or 0
			AddCount(summary, key, field, n)
		end
	end
end

local function WalkByBag(byBag, summary, field)
	if type(byBag) ~= "table" then
		return
	end
	for _, slots in pairs(byBag) do
		WalkSlots(slots, summary, field)
	end
end

local function GenerateCharacter(fullName, state)
	local char = Store.GetCharacter(fullName)
	if not char or not char.details then
		return
	end
	local db = Store.GetDB()
	if not db then
		return
	end
	local realm = char.details.realmNormalized
	local name = char.details.character
	if not realm or not name then
		return
	end
	db.Summaries.Characters.ByRealm[realm] = db.Summaries.Characters.ByRealm[realm] or {}
	local summary = {}
	if state == Store.PendingBags() then
		summary = db.Summaries.Characters.ByRealm[realm][name] or summary
		for _, row in pairs(summary) do
			if type(row) == "table" then
				row.bags = 0
			end
		end
	end
	WalkByBag(char.bags, summary, "bags")
	if state ~= Store.PendingBags() then
		WalkByBag(char.bank, summary, "bank")
		WalkSlots(char.mail, summary, "mail")
		WalkSlots(char.equipped, summary, "equipped")
		WalkByBag(char.void, summary, "void")
		WalkSlots(char.auctions, summary, "auctions")
	end
	db.Summaries.Characters.ByRealm[realm][name] = summary
end

local function GenerateGuild(fullName)
	local guild = Store.GetGuild(fullName)
	if not guild or not guild.details then
		return
	end
	local db = Store.GetDB()
	if not db then
		return
	end
	local realm = guild.details.realm
	local name = guild.details.guild
	if not realm or not name then
		return
	end
	local summary = {}
	local bank = guild.bank
	if type(bank) == "table" then
		for _, tab in pairs(bank) do
			if type(tab) == "table" and tab.isViewable ~= false then
				WalkSlots(tab.slots or tab, summary, "bank")
			end
		end
	end
	db.Summaries.Guilds.ByRealm[realm] = db.Summaries.Guilds.ByRealm[realm] or {}
	db.Summaries.Guilds.ByRealm[realm][name] = summary
end

local function GenerateWarband()
	local db = Store.GetDB()
	if not db then
		return
	end
	local war = Store.GetWarband()
	local summary = {}
	local bank = war and war.bank
	if type(bank) == "table" then
		local _, first = next(bank)
		if type(first) == "table" and first.slots then
			for _, tab in pairs(bank) do
				WalkSlots(tab.slots, summary, "bank")
			end
		else
			WalkByBag(bank, summary, "bank")
		end
	end
	-- Flatten to key -> count (warband tooltip is a single number).
	local flat = {}
	for key, row in pairs(summary) do
		flat[key] = (type(row) == "table" and (row.bank or 0)) or (tonumber(row) or 0)
	end
	db.Summaries.Warband.Summary = flat
end

local function FlushPending()
	if Store.UsesSyndicator() then
		return
	end
	local chars = Store.TakeCharacterPending()
	for name, kind in pairs(chars) do
		GenerateCharacter(name, kind)
	end
	local guilds = Store.TakeGuildPending()
	for name in pairs(guilds) do
		GenerateGuild(name)
	end
	if Store.TakeWarbandPending() then
		GenerateWarband()
	end
end

local function SynTooltipByItemID(itemID, connected, faction)
	local api = rawget(_G, "Syndicator")
	api = api and api.API
	if not api or not api.GetInventoryInfoByItemID then
		return nil
	end
	local ok, info = pcall(api.GetInventoryInfoByItemID, itemID, connected == true, faction == true)
	if ok then
		return info
	end
	return nil
end

local function SynTooltipByLink(link, connected, faction)
	local api = rawget(_G, "Syndicator")
	api = api and api.API
	if not api or not api.GetInventoryInfo then
		return nil
	end
	local ok, info = pcall(api.GetInventoryInfo, link, connected == true, faction == true)
	if ok then
		return info
	end
	return nil
end

function Summaries.GetTooltipInfo(key, connected, faction)
	if not key then
		return { characters = {}, guilds = {}, warband = { 0 } }
	end
	if Store.UsesSyndicator() then
		local itemID = tonumber(tostring(key):match(":(%-?%d+)$"))
		if itemID then
			return SynTooltipByItemID(itemID, connected, faction)
				or { characters = {}, guilds = {}, warband = { 0 } }
		end
		return { characters = {}, guilds = {}, warband = { 0 } }
	end

	FlushPending()
	local db = Store.GetDB()
	if not db then
		return { characters = {}, guilds = {}, warband = { 0 } }
	end

	local realmSet
	if connected then
		local _, seen = Store.GetConnectedRealms()
		realmSet = seen
	end
	local currentFaction = UnitFactionGroup and UnitFactionGroup("player") or nil
	local result = { characters = {}, guilds = {}, warband = { 0 } }

	for realm, byChar in pairs(db.Summaries.Characters.ByRealm) do
		if not realmSet or realmSet[realm] then
			for charName, summary in pairs(byChar) do
				local byKey = summary[key]
				local character = Store.GetCharacter(charName .. "-" .. realm)
				local details = character and character.details
				if byKey and details and details.show and details.show.inventory ~= false then
					if not faction or not currentFaction or details.faction == currentFaction then
						result.characters[#result.characters + 1] = {
							character = details.character or charName,
							realmNormalized = details.realmNormalized or realm,
							className = details.className,
							race = details.race,
							sex = details.sex,
							bags = byKey.bags or 0,
							bank = byKey.bank or 0,
							mail = byKey.mail or 0,
							equipped = byKey.equipped or 0,
							void = byKey.void or 0,
							auctions = byKey.auctions or 0,
						}
					end
				end
			end
		end
	end

	for realm, byGuild in pairs(db.Summaries.Guilds.ByRealm) do
		if not realmSet or realmSet[realm] then
			for guildName, summary in pairs(byGuild) do
				local byKey = summary[key]
				local guild = Store.GetGuild(guildName .. "-" .. realm)
				local details = guild and guild.details
				if byKey and details and details.show and details.show.inventory ~= false then
					if not faction or not currentFaction or details.faction == currentFaction then
						result.guilds[#result.guilds + 1] = {
							guild = details.guild or guildName,
							realmNormalized = realm,
							bank = byKey.bank or 0,
						}
					end
				end
			end
		end
	end

	local war = db.Summaries.Warband and db.Summaries.Warband.Summary
	if type(war) == "table" then
		result.warband[1] = tonumber(war[key]) or 0
	end
	return result
end

function Summaries.GetTooltipInfoByItemID(itemID, connected, faction)
	itemID = tonumber(itemID)
	if not itemID then
		return { characters = {}, guilds = {}, warband = { 0 } }
	end
	if Store.UsesSyndicator() then
		return SynTooltipByItemID(itemID, connected, faction)
			or { characters = {}, guilds = {}, warband = { 0 } }
	end
	return Summaries.GetTooltipInfo(Store.GetItemKeyByItemID(itemID), connected, faction)
end

function Summaries.GetTooltipInfoByLink(link, connected, faction)
	if Store.UsesSyndicator() then
		return SynTooltipByLink(link, connected, faction)
			or { characters = {}, guilds = {}, warband = { 0 } }
	end
	local key = Store.GetItemKey(link)
	return Summaries.GetTooltipInfo(key, connected, faction)
end
