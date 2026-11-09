-- Inventory/Builtin/Currency.lua — money always; token list when the client has it.
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Builtin = Inv.Builtin
local Store = Inv.Store
local Cap = Flux.Cap

local Currency = {}
Builtin.Currency = Currency

local started = false
local currencyDirty = false

local function Request()
	Flux.Scheduler.Request("inventory", "currencies")
end

local function ApplyMoney(copper)
	copper = tonumber(copper) or 0
	Store.SetCurrentMoney(copper)
	local snap = Inv.snapshots.currencies
	if snap then
		snap.money = copper
		snap.generation = (snap.generation or 0) + 1
	end
end

local function ScanTokens()
	if not Cap.hasCurrencyTokens then
		return
	end
	local char = Store.EnsureCurrentCharacter()
	if not char then
		return
	end
	local counts = {}
	if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize and C_CurrencyInfo.GetCurrencyListInfo then
		local size = C_CurrencyInfo.GetCurrencyListSize() or 0
		local toCollapse = {}
		local index = 0
		while index < size do
			index = index + 1
			local info = C_CurrencyInfo.GetCurrencyListInfo(index)
			if info then
				if info.isHeader then
					if not info.isHeaderExpanded and C_CurrencyInfo.ExpandCurrencyList then
						toCollapse[#toCollapse + 1] = index
						C_CurrencyInfo.ExpandCurrencyList(index, true)
						size = C_CurrencyInfo.GetCurrencyListSize() or size
					end
				elseif info.discovered then
					local link = C_CurrencyInfo.GetCurrencyListLink and C_CurrencyInfo.GetCurrencyListLink(index)
					local id = link and tonumber(link:match("|Hcurrency:(%d+)"))
					if not id and C_CurrencyInfo.GetCurrencyIDFromLink and link then
						id = C_CurrencyInfo.GetCurrencyIDFromLink(link)
					end
					id = tonumber(id)
					if id then
						counts[id] = tonumber(info.quantity) or 0
					end
				end
			end
		end
		for i = #toCollapse, 1, -1 do
			C_CurrencyInfo.ExpandCurrencyList(toCollapse[i], false)
		end
	elseif GetCurrencyListSize and GetCurrencyListInfo then
		local size = GetCurrencyListSize() or 0
		local toCollapse = {}
		local index = 0
		while index < size do
			index = index + 1
			local name, isHeader, isExpanded, _, _, quantity = GetCurrencyListInfo(index)
			if isHeader then
				if not isExpanded and ExpandCurrencyList then
					toCollapse[#toCollapse + 1] = index
					ExpandCurrencyList(index, 1)
					size = GetCurrencyListSize() or size
				end
			else
				local link = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListLink and C_CurrencyInfo.GetCurrencyListLink(index)
				local id = link and tonumber(link:match("|Hcurrency:(%d+)"))
				if id then
					counts[id] = tonumber(quantity) or 0
				end
			end
		end
		for i = #toCollapse, 1, -1 do
			ExpandCurrencyList(toCollapse[i], 0)
		end
	end
	char.currencies = counts
	local snap = Inv.snapshots.currencies
	if snap then
		snap.counts = counts
		snap.generation = (snap.generation or 0) + 1
	end
end

function Currency.Refresh()
	if Store.UsesSyndicator() then
		return
	end
	if GetMoney then
		ApplyMoney(GetMoney())
	end
	if Inv.HasWarband and Inv.HasWarband() and C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType then
		local ok, n = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
		if ok and type(n) == "number" then
			Store.SetWarbandMoney(n)
		end
	end
	if currencyDirty then
		currencyDirty = false
		ScanTokens()
	end
end

function Currency.Start()
	if started or Store.UsesSyndicator() then
		return
	end
	started = true
	if GetMoney then
		ApplyMoney(GetMoney())
	end
	currencyDirty = Cap.hasCurrencyTokens and true or false
	if currencyDirty then
		ScanTokens()
		currencyDirty = false
	end
	Request()
	-- Builtin may start while Syndicator is still loading. Once ready, its
	-- callbacks own currency snapshots; these shared-bus handlers stay inert.
	Flux.Events.Register("PLAYER_MONEY", function()
		if Store.UsesSyndicator() then return end
		if GetMoney then
			ApplyMoney(GetMoney())
		end
		Request()
	end)
	Flux.Events.Register("CURRENCY_DISPLAY_UPDATE", function()
		if Store.UsesSyndicator() then return end
		currencyDirty = true
		Request()
	end)
	Flux.Events.Register("ACCOUNT_MONEY", function()
		if Store.UsesSyndicator() then return end
		Request()
	end)
	Flux.Events.Register("BANKFRAME_OPENED", function()
		if Store.UsesSyndicator() then return end
		if Inv.HasWarband and Inv.HasWarband() then
			Request()
		end
	end)
end
