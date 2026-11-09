-- Inventory/Store.lua — account-wide character ledger (Flux's Syndicator facts).
-- When Syndicator is loaded this proxies Syndicator.API instead of writing FluxUIInventoryDB.
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory

local Store = {}
Inv.Store = Store

local currentName
local usesSyndicator = false

local PENDING_BAGS = 2
local PENDING_ALL = 1

local function Wipe(t)
	if type(t) ~= "table" then
		return t
	end
	if wipe then
		return wipe(t)
	end
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

local function SynAPI()
	local syn = rawget(_G, "Syndicator")
	return syn and syn.API
end

function Store.UsesSyndicator()
	return usesSyndicator
end

function Store.SetUsesSyndicator(on)
	usesSyndicator = on and true or false
end

local function EnsureDB()
	local db = _G.FluxUIInventoryDB
	if type(db) ~= "table" then
		db = {
			Version = 1,
			Characters = {},
			Guilds = {},
			Warband = { { bank = {}, money = 0, details = { gold = true, inventory = true } } },
			Pending = { Characters = {}, Guilds = {}, Warband = false },
			Summaries = {
				Characters = { ByRealm = {} },
				Guilds = { ByRealm = {} },
				Warband = { Summary = {}, Pending = true },
			},
		}
		_G.FluxUIInventoryDB = db
	end
	if type(db.Characters) ~= "table" then
		db.Characters = {}
	end
	if type(db.Guilds) ~= "table" then
		db.Guilds = {}
	end
	if type(db.Warband) ~= "table" then
		db.Warband = { { bank = {}, money = 0, details = { gold = true, inventory = true } } }
	end
	if not db.Warband[1] then
		db.Warband[1] = { bank = {}, money = 0, details = { gold = true, inventory = true } }
	end
	db.Warband[1].bank = db.Warband[1].bank or {}
	db.Warband[1].money = db.Warband[1].money or 0
	db.Warband[1].details = db.Warband[1].details or { gold = true, inventory = true }
	if type(db.Pending) ~= "table" then
		db.Pending = { Characters = {}, Guilds = {}, Warband = false }
	end
	db.Pending.Characters = db.Pending.Characters or {}
	db.Pending.Guilds = db.Pending.Guilds or {}
	if type(db.Summaries) ~= "table" then
		db.Summaries = {
			Characters = { ByRealm = {} },
			Guilds = { ByRealm = {} },
			Warband = { Summary = {}, Pending = true },
		}
	end
	db.Summaries.Characters = db.Summaries.Characters or { ByRealm = {} }
	db.Summaries.Characters.ByRealm = db.Summaries.Characters.ByRealm or {}
	db.Summaries.Guilds = db.Summaries.Guilds or { ByRealm = {} }
	db.Summaries.Guilds.ByRealm = db.Summaries.Guilds.ByRealm or {}
	db.Summaries.Warband = db.Summaries.Warband or { Summary = {}, Pending = true }
	return db
end

function Store.GetDB()
	if usesSyndicator then
		return nil
	end
	return EnsureDB()
end

function Store.GetCharacterFullName()
	local PN = Flux and Flux.PlayerName
	if PN and PN.GetFullName then
		local name = PN.GetFullName("player")
		local realm = PN.GetRealmToken and PN.GetRealmToken()
		if type(name) == "string" then
			name = name:gsub("%s+", "-")
		end
		if type(name) == "string" and name ~= "" and type(realm) == "string" and realm ~= "" then
			return name .. "-" .. realm, name, realm
		end
	end
	local name = UnitName and UnitName("player")
	local realm = GetNormalizedRealmName and GetNormalizedRealmName()
	if (not name or name == "") or (not realm or realm == "") then
		if UnitFullName and not (PN and PN.UsesRegionalUniqueNames and PN.UsesRegionalUniqueNames()) then
			local n2, r2 = UnitFullName("player")
			if not name or name == "" then
				name = n2
			end
			if not realm or realm == "" then
				realm = r2
			end
		end
	end
	if type(name) ~= "string" or name == "" then
		return nil
	end
	if type(realm) ~= "string" or realm == "" then
		return nil
	end
	name = name:gsub("%s+", "-")
	return name .. "-" .. realm, name, realm
end

function Store.NormalizeRecipient(recipient)
	if type(recipient) ~= "string" or recipient == "" then
		return nil
	end
	local PN = Flux and Flux.PlayerName
	if PN and PN.UsesRegionalUniqueNames and PN.UsesRegionalUniqueNames() then
		local realm = PN.GetRealmToken and PN.GetRealmToken()
		if not realm or realm == "" then
			return nil
		end
		local suffix = "-" .. realm
		if recipient:sub(-#suffix) == suffix then
			return recipient
		end
		return recipient .. suffix
	end
	if not recipient:find("-", 1, true) then
		local realm = GetNormalizedRealmName and GetNormalizedRealmName()
		if not realm or realm == "" then
			return nil
		end
		return recipient .. "-" .. realm
	end
	return recipient
end

function Store.GetCurrentCharacterName()
	if usesSyndicator then
		local api = SynAPI()
		if api and api.GetCurrentCharacter then
			return api.GetCurrentCharacter()
		end
	end
	return currentName or select(1, Store.GetCharacterFullName())
end

function Store.GetCharacter(fullName)
	if usesSyndicator then
		local api = SynAPI()
		if api and api.GetCharacter then
			return api.GetCharacter(fullName)
		end
		return nil
	end
	if type(fullName) ~= "string" then
		return nil
	end
	local db = EnsureDB()
	return db.Characters[fullName]
end

function Store.GetAllCharacters()
	if usesSyndicator then
		local api = SynAPI()
		if api and api.GetAllCharacters then
			return api.GetAllCharacters() or {}
		end
		return {}
	end
	local db = EnsureDB()
	local out = {}
	for name in pairs(db.Characters) do
		out[#out + 1] = name
	end
	return out
end

function Store.HasCharacter(fullName)
	return Store.GetCharacter(fullName) ~= nil
end

function Store.GetGuild(fullName)
	if usesSyndicator then
		local api = SynAPI()
		if api and api.GetGuild then
			return api.GetGuild(fullName)
		end
		return nil
	end
	if type(fullName) ~= "string" then
		return nil
	end
	return EnsureDB().Guilds[fullName]
end

function Store.GetAllGuilds()
	if usesSyndicator then
		local api = SynAPI()
		if api and api.GetAllGuilds then
			return api.GetAllGuilds() or {}
		end
		return {}
	end
	local out = {}
	for name in pairs(EnsureDB().Guilds) do
		out[#out + 1] = name
	end
	return out
end

function Store.GetCurrentGuildName()
	if usesSyndicator then
		local api = SynAPI()
		if api and api.GetCurrentGuild then
			return api.GetCurrentGuild()
		end
		return nil
	end
	local char = Store.GetCurrentCharacter()
	return char and char.details and char.details.guild or nil
end

function Store.GetWarband()
	if usesSyndicator then
		local api = SynAPI()
		if api and api.GetWarband then
			return api.GetWarband(1)
		end
		return nil
	end
	return EnsureDB().Warband[1]
end

local function EmptyChar(name, realm)
	return {
		bags = {},
		bank = {},
		mail = {},
		equipped = {},
		void = {},
		auctions = {},
		currencies = {},
		money = 0,
		details = {
			realmNormalized = realm,
			realm = (GetRealmName and GetRealmName()) or realm,
			character = name,
			show = { inventory = true, gold = true },
		},
	}
end

function Store.GetCurrentCharacter()
	local full = Store.GetCurrentCharacterName()
	if not full then
		return nil
	end
	return Store.GetCharacter(full)
end

function Store.EnsureCurrentCharacter()
	if usesSyndicator then
		currentName = Store.GetCurrentCharacterName()
		return Store.GetCurrentCharacter()
	end
	local full, name, realm = Store.GetCharacterFullName()
	if not full then
		return nil
	end
	currentName = full
	local db = EnsureDB()
	local char = db.Characters[full]
	if not char then
		char = EmptyChar(name, realm)
		db.Characters[full] = char
	end
	char.details = char.details or {}
	char.details.realmNormalized = realm
	char.details.realm = (GetRealmName and GetRealmName()) or realm
	char.details.character = name
	char.details.show = char.details.show or { inventory = true, gold = true }
	if UnitClass then
		local loc, file = UnitClass("player")
		char.details.class = loc
		char.details.className = file
	end
	if UnitFactionGroup then
		char.details.faction = UnitFactionGroup("player")
	end
	if UnitRace then
		local loc, file = UnitRace("player")
		char.details.race = file or loc
	end
	if UnitSex then
		char.details.sex = UnitSex("player")
	end
	char.bags = char.bags or {}
	char.bank = char.bank or {}
	char.mail = char.mail or {}
	char.equipped = char.equipped or {}
	char.void = char.void or {}
	char.auctions = char.auctions or {}
	char.currencies = char.currencies or {}
	return char
end

function Store.EnsureGuild(fullName, guildName, realm)
	if usesSyndicator or type(fullName) ~= "string" then
		return nil
	end
	local db = EnsureDB()
	local g = db.Guilds[fullName]
	if not g then
		g = {
			bank = {},
			money = 0,
			details = {
				guild = guildName or fullName,
				faction = UnitFactionGroup and UnitFactionGroup("player") or nil,
				show = { inventory = true, gold = false },
				visited = false,
				realm = realm or (GetNormalizedRealmName and GetNormalizedRealmName()),
			},
		}
		db.Guilds[fullName] = g
	end
	g.details = g.details or {}
	g.details.guild = guildName or g.details.guild
	g.details.realm = realm or g.details.realm
	g.bank = g.bank or {}
	return g
end

function Store.SetCurrentGuild(fullName)
	local char = Store.EnsureCurrentCharacter()
	if char and char.details then
		char.details.guild = fullName
	end
end

--- Bind a live snapshot table into the saved character record (same table = persist during scan).
function Store.BindLive(field, tbl)
	if usesSyndicator then
		return
	end
	local char = Store.EnsureCurrentCharacter()
	if not char or type(field) ~= "string" or type(tbl) ~= "table" then
		return
	end
	char[field] = tbl
end

function Store.BindWarbandBank(tbl)
	if usesSyndicator then
		return
	end
	local war = Store.GetWarband()
	if war and type(tbl) == "table" then
		war.bank = tbl
	end
end

function Store.MarkPending(fullName, kind)
	if usesSyndicator then
		return
	end
	fullName = fullName or Store.GetCurrentCharacterName()
	if not fullName then
		return
	end
	local db = EnsureDB()
	local pending = db.Pending.Characters
	if kind == "bags" and pending[fullName] ~= PENDING_ALL then
		pending[fullName] = PENDING_BAGS
	else
		pending[fullName] = PENDING_ALL
	end
end

function Store.MarkGuildPending(fullName)
	if usesSyndicator or not fullName then
		return
	end
	EnsureDB().Pending.Guilds[fullName] = true
end

function Store.MarkWarbandPending()
	if usesSyndicator then
		return
	end
	local db = EnsureDB()
	db.Pending.Warband = true
	if db.Summaries and db.Summaries.Warband then
		db.Summaries.Warband.Pending = true
	end
end

function Store.TakeCharacterPending()
	if usesSyndicator then
		return {}
	end
	local db = EnsureDB()
	local src = db.Pending.Characters
	local out = {}
	for name, kind in pairs(src) do
		out[name] = kind
	end
	Wipe(src)
	return out
end

function Store.TakeGuildPending()
	if usesSyndicator then
		return {}
	end
	local db = EnsureDB()
	local src = db.Pending.Guilds
	local out = {}
	for name in pairs(src) do
		out[name] = true
	end
	Wipe(src)
	return out
end

function Store.TakeWarbandPending()
	if usesSyndicator then
		return false
	end
	local db = EnsureDB()
	local pending = db.Pending.Warband
	db.Pending.Warband = false
	if db.Summaries and db.Summaries.Warband and db.Summaries.Warband.Pending then
		pending = true
		db.Summaries.Warband.Pending = false
	end
	return pending and true or false
end

function Store.PendingBags()
	return PENDING_BAGS
end

function Store.PendingAll()
	return PENDING_ALL
end

function Store.SetCurrentMoney(copper)
	copper = tonumber(copper)
	if not copper then
		return
	end
	if usesSyndicator then
		return
	end
	local char = Store.EnsureCurrentCharacter()
	if char then
		char.money = math.max(0, math.floor(copper))
	end
	local snap = Inv.snapshots and Inv.snapshots.currencies
	if snap then
		snap.money = copper
		snap.generation = (snap.generation or 0) + 1
	end
end

function Store.SetWarbandMoney(copper)
	copper = tonumber(copper) or 0
	if usesSyndicator then
		return
	end
	local war = Store.GetWarband()
	if war then
		war.money = copper
	end
	local snap = Inv.snapshots and Inv.snapshots.currencies
	if snap then
		snap.warbandMoney = copper
		snap.generation = (snap.generation or 0) + 1
	end
end

function Store.SetGoldHidden(fullName, hidden)
	local char = Store.GetCharacter(fullName)
	if char and char.details then
		char.details.show = char.details.show or {}
		char.details.show.gold = not hidden
	end
end

function Store.GetConnectedRealms()
	local out = {}
	local seen = {}
	local function add(r)
		if type(r) == "string" and r ~= "" and not seen[r] then
			seen[r] = true
			out[#out + 1] = r
		end
	end
	if GetAutoCompleteRealms then
		local ok, realms = pcall(GetAutoCompleteRealms)
		if ok and type(realms) == "table" then
			for i = 1, #realms do
				add(realms[i])
			end
		end
	end
	add(GetNormalizedRealmName and GetNormalizedRealmName())
	return out, seen
end

--- item:12345 / battlepet:species from a link or itemID.
function Store.GetItemKey(link, itemID)
	if type(link) == "string" and link ~= "" then
		local kind, id = link:match("|H([^:]+):(%-?%d+)")
		if kind and id then
			return kind .. ":" .. id
		end
		kind, id = link:match("^([^:]+):(%-?%d+)")
		if kind and id then
			return kind .. ":" .. id
		end
	end
	itemID = tonumber(itemID)
	if itemID and itemID > 0 then
		return "item:" .. itemID
	end
	return nil
end

function Store.GetItemKeyByItemID(itemID)
	itemID = tonumber(itemID)
	if not itemID then
		return nil
	end
	return "item:" .. itemID
end

function Store.ImportGoldLedgerStubs()
	if usesSyndicator then
		return
	end
	local ledger = rawget(_G, "FluxUIGoldLedger")
	local chars = ledger and ledger.chars
	if type(chars) ~= "table" then
		return
	end
	local db = EnsureDB()
	local function FoldId(name, realm)
		if type(name) ~= "string" or name == "" then
			return nil
		end
		return name:gsub("%s+", "-"):lower() .. "@" .. tostring(realm or ""):gsub("%s+", ""):gsub("%-+", ""):lower()
	end
	local function ExistingKey(name, realm)
		local want = FoldId(name, realm)
		if not want then
			return nil
		end
		for full, char in pairs(db.Characters) do
			local d = char and char.details
			local n = d and d.character
			local r = d and (d.realmNormalized or d.realm)
			if FoldId(n, r) == want then
				return full
			end
		end
		return nil
	end
	for key, row in pairs(chars) do
		if type(key) == "string" and type(row) == "table" then
			local name, realm
			local PN = Flux and Flux.PlayerName
			if PN and PN.SplitCharKey then
				name, realm = PN.SplitCharKey(key)
			else
				name, realm = key:match("^(.+)%-([^-]+)$")
			end
			name = name or row.name
			realm = realm or row.realmN or row.realm
			if type(name) == "string" then
				name = name:gsub("%s+", "-")
			end
			local existing = db.Characters[key] or ExistingKey(name, realm)
			if not existing and name and realm then
				local char = EmptyChar(name, realm)
				char.details.realm = row.realm or realm
				char.details.faction = row.faction
				char.details.className = row.classFile
				char.details.race = row.raceFile
				char.details.sex = row.sex
				local money = tonumber(row.m or row.money)
				if money then
					char.money = math.max(0, math.floor(money))
				end
				db.Characters[key] = char
			elseif type(row) == "table" and existing and db.Characters[existing] then
				local money = tonumber(row.m or row.money)
				if money and (not db.Characters[existing].money or db.Characters[existing].money == 0) then
					db.Characters[existing].money = math.max(0, math.floor(money))
				end
			end
		end
	end
end

function Store.IsGoldDeleted(fullName)
	local ledger = rawget(_G, "FluxUIGoldLedger")
	local deleted = ledger and ledger.deleted
	return type(deleted) == "table" and deleted[fullName] and true or false
end

local function FillSnapFromByBag(snap, byBag)
	if not snap then
		return
	end
	if type(byBag) ~= "table" then
		return
	end
	snap.byBag = byBag
	local counts = {}
	for _, slots in pairs(byBag) do
		if type(slots) == "table" then
			for _, rec in pairs(slots) do
				local id = rec and tonumber(rec.itemID)
				if id then
					counts[id] = (counts[id] or 0) + (tonumber(rec.count or rec.itemCount) or 1)
				end
			end
		end
	end
	snap.counts = counts
	snap.generation = (snap.generation or 0) + 1
end

local function FillSnapFromList(snap, list)
	if not snap then
		return
	end
	if not snap.byIndex then
		snap.byIndex = {}
	end
	if wipe then
		wipe(snap.byIndex)
	else
		for k in pairs(snap.byIndex) do
			snap.byIndex[k] = nil
		end
	end
	local counts = {}
	if type(list) == "table" then
		for index, rec in pairs(list) do
			local id = rec and tonumber(rec.itemID)
			if id then
				local n = tonumber(rec.itemCount or rec.count) or 1
				snap.byIndex[index] = { itemID = id, count = n, link = rec.itemLink or rec.link }
				counts[id] = (counts[id] or 0) + n
			end
		end
	end
	snap.counts = counts
	snap.generation = (snap.generation or 0) + 1
end

--- Last-visit regions into live snapshots so counts work before that window is opened this session.
function Store.HydrateSnapshots()
	if usesSyndicator then
		return
	end
	local char = Store.EnsureCurrentCharacter()
	if not char or not Inv.snapshots then
		return
	end
	if char.bags and next(char.bags) and Inv.snapshots.bags and not next(Inv.snapshots.bags.byBag) then
		FillSnapFromByBag(Inv.snapshots.bags, char.bags)
	end
	if char.bank and next(char.bank) and Inv.snapshots.bank and not next(Inv.snapshots.bank.byBag) then
		FillSnapFromByBag(Inv.snapshots.bank, char.bank)
	end
	if char.equipped and next(char.equipped) and Inv.snapshots.equip and not next(Inv.snapshots.equip.bySlot) then
		local snap = Inv.snapshots.equip
		snap.bySlot = char.equipped
		local counts = {}
		for _, rec in pairs(char.equipped) do
			local id = rec and tonumber(rec.itemID)
			if id then
				counts[id] = (counts[id] or 0) + (tonumber(rec.count or rec.itemCount) or 1)
			end
		end
		snap.counts = counts
		snap.generation = (snap.generation or 0) + 1
	end
	FillSnapFromList(Inv.snapshots.mail, char.mail)
	FillSnapFromList(Inv.snapshots.auctions, char.auctions)
	if char.void then
		FillSnapFromByBag(Inv.snapshots.void, char.void)
	end
	if type(char.currencies) == "table" then
		local snap = Inv.snapshots.currencies
		if snap then
			snap.counts = char.currencies
			snap.money = tonumber(char.money) or 0
			snap.generation = (snap.generation or 0) + 1
		end
	end
	local war = Store.GetWarband()
	if war and war.bank and Inv.HasWarband and Inv.HasWarband() then
		if Inv.snapshots.warband and not next(Inv.snapshots.warband.byBag) then
			FillSnapFromByBag(Inv.snapshots.warband, war.bank)
		end
		if Inv.snapshots.currencies then
			Inv.snapshots.currencies.warbandMoney = tonumber(war.money) or 0
		end
		Store.MarkWarbandPending()
	end
	Store.MarkPending(nil, "all")
end
