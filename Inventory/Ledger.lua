-- Inventory/Ledger.lua — gold / currency across characters for status bars.
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Store = Inv.Store

local Ledger = {}
Inv.Ledger = Ledger

local SHARED_CURRENCIES = {
	[2032] = true, -- Trader's Tender
	[3292] = true, -- Infinite Knowledge
}

local function SplitKey(key)
	if type(key) ~= "string" then
		return nil, nil
	end
	local PN = Flux and Flux.PlayerName
	if PN and PN.SplitCharKey then
		return PN.SplitCharKey(key)
	end
	return key:match("^(.+)%-([^-]+)$")
end

local function FoldGoldId(name, realm)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	name = name:gsub("%s+", "-"):lower()
	realm = tostring(realm or ""):gsub("%s+", ""):gsub("%-+", ""):lower()
	return name .. "@" .. realm
end

local function GoldVisible(details, fullName)
	if Store.IsGoldDeleted and Store.IsGoldDeleted(fullName) then
		return false
	end
	if details and details.show and details.show.gold == false then
		return false
	end
	return true
end

function Ledger.GetGoldRows()
	local rows = {}
	local seen = {}
	local names = Store.GetAllCharacters()
	for i = 1, #names do
		local full = names[i]
		local char = Store.GetCharacter(full)
		if type(char) == "table" then
			local details = char.details or {}
			if GoldVisible(details, full) then
				local name = details.character
				local realmN = details.realmNormalized
				if not name or not realmN then
					name, realmN = SplitKey(full)
				end
				local money = tonumber(char.money) or 0
				local id = FoldGoldId(name, realmN)
				local prev = id and seen[id]
				if prev then
					if money > (prev.m or 0) then
						prev.m = money
					end
					if (not prev.name or prev.name == "?") and name then
						prev.name = name
					end
				else
					local row = {
						key = full,
						name = name or "?",
						realm = details.realm or realmN,
						realmN = realmN,
						faction = details.faction,
						classFile = details.className,
						raceFile = details.race,
						sex = details.sex,
						m = money,
					}
					rows[#rows + 1] = row
					if id then
						seen[id] = row
					end
				end
			end
		end
	end
	return rows
end

function Ledger.GetCurrentMoney()
	if GetMoney then
		local ok, n = pcall(GetMoney)
		if ok and type(n) == "number" then
			return n
		end
	end
	local snap = Inv.snapshots and Inv.snapshots.currencies
	return snap and tonumber(snap.money) or 0
end

function Ledger.GetWarbandMoney()
	local war = Store.GetWarband and Store.GetWarband()
	if war then
		return tonumber(war.money) or 0
	end
	local snap = Inv.snapshots and Inv.snapshots.currencies
	return snap and tonumber(snap.warbandMoney) or 0
end

function Ledger.GetCurrencyRows(currencyID, connected, faction)
	currencyID = tonumber(currencyID)
	local rows = {}
	if not currencyID or SHARED_CURRENCIES[currencyID] then
		return rows
	end
	if Store.UsesSyndicator() then
		local api = rawget(_G, "Syndicator")
		api = api and api.API
		if api and api.GetCurrencyInfo then
			local ok, info = pcall(api.GetCurrencyInfo, currencyID, connected == true, faction == true)
			if ok and type(info) == "table" then
				return info
			end
		end
		return rows
	end
	local realmSet
	if connected then
		local _, seen = Store.GetConnectedRealms()
		realmSet = seen
	end
	local currentFaction = UnitFactionGroup and UnitFactionGroup("player") or nil
	local names = Store.GetAllCharacters()
	for i = 1, #names do
		local full = names[i]
		local char = Store.GetCharacter(full)
		if char and type(char.currencies) == "table" then
			local qty = tonumber(char.currencies[currencyID]) or 0
			local details = char.details or {}
			local realmN = details.realmNormalized
			if qty > 0 and details.show and details.show.inventory ~= false then
				if (not realmSet or realmSet[realmN])
					and (not faction or not currentFaction or details.faction == currentFaction)
				then
					rows[#rows + 1] = {
						character = details.character,
						realmNormalized = realmN,
						className = details.className,
						race = details.race,
						sex = details.sex,
						quantity = qty,
					}
				end
			end
		end
	end
	return rows
end

Inv.GetMoney = Ledger.GetCurrentMoney
