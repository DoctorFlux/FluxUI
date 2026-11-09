-- Inventory/Tooltip.lua — Syndicator-style location lines. No-op if Syndicator is loaded.
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Store = Inv.Store
local Summaries = Inv.Summaries
local Ledger = Inv.Ledger

local Tooltip = {}
Inv.Tooltip = Tooltip

local started = false
local CHARACTER_LIMIT = 20

local function Defaults()
	return {
		showItems = true,
		showCurrencies = true,
		shiftOnly = false,
		connectedRealmsOnly = false,
		factionOnly = false,
		showEquipped = true,
		showGuild = true,
		blankLine = true,
		raceIcons = true,
	}
end

function Inv.GetAwarenessOptions()
	local out = Defaults()
	local opts = FluxOptions
	local db = opts and opts.GetStatusBarSettingsDB and opts:GetStatusBarSettingsDB()
	if type(db) ~= "table" then
		return out
	end
	if db.invTipShowItems == false then
		out.showItems = false
	end
	if db.invTipShowCurrencies == false then
		out.showCurrencies = false
	end
	if db.invTipShiftOnly then
		out.shiftOnly = true
	end
	if db.invTipConnectedRealms then
		out.connectedRealmsOnly = true
	end
	if db.invTipFactionOnly then
		out.factionOnly = true
	end
	if db.invTipShowEquipped == false then
		out.showEquipped = false
	end
	if db.invTipShowGuild == false then
		out.showGuild = false
	end
	if db.invTipBlankLine == false then
		out.blankLine = false
	end
	if db.invTipRaceIcons == false then
		out.raceIcons = false
	end
	return out
end

function Tooltip.IsDelegated()
	if Store.UsesSyndicator() then
		return true
	end
	local syn = Flux.Optional and Flux.Optional.Get("Syndicator")
	return syn and syn.loaded and true or false
end

local function ShiftOk(cfg)
	if not cfg.shiftOnly then
		return true
	end
	return IsShiftKeyDown and IsShiftKeyDown()
end

local RACE_ATLAS_CORR = {
	scourge = "undead",
	zandalaritroll = "zandalari",
	highmountaintauren = "highmountain",
	lightforgeddraenei = "lightforged",
	earthendwarf = "earthen",
	harronir = "haranir",
}

local GENDERS = { "unknown", "male", "female" }

local function CharacterIcon(race, sex)
	if type(race) ~= "string" or race == "" then
		return ""
	end
	race = race:gsub("%s+", ""):lower()
	race = RACE_ATLAS_CORR[race] or race
	local gender = GENDERS[tonumber(sex) or 2] or "male"
	local prefix = (Flux.Client and Flux.Client.isRetail) and "raceicon128" or "raceicon"
	return "|A:" .. prefix .. "-" .. race .. "-" .. gender .. ":13:13|a"
end

local function GuildIcon()
	return "|A:communities-guildbanner-background:13:13|a"
end

local function WarbandIcon()
	return "|A:warbands-icon:17:13|a"
end

local function ClassColorName(name, classFile)
	if type(classFile) == "string" then
		local colors = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)
		local c = colors and colors[classFile]
		if c and c.colorStr then
			return "|c" .. c.colorStr .. name .. "|r"
		end
	end
	return name
end

local function White(text)
	return "|cffffffff" .. tostring(text) .. "|r"
end

local function LinkColor(text)
	return "|cff66bbff" .. tostring(text) .. "|r"
end

local function AddDouble(tooltip, left, right)
	if tooltip.AddDoubleLine then
		tooltip:AddDoubleLine(left, right)
	elseif tooltip.AddLine then
		tooltip:AddLine(left .. "  " .. tostring(right))
	end
end

local function CharComparator(a, b)
	if a.realmNormalized == b.realmNormalized then
		return tostring(a.character) < tostring(b.character)
	end
	return tostring(a.realmNormalized) < tostring(b.realmNormalized)
end

local function TotalOf(s)
	return (s.bags or 0) + (s.bank or 0) + (s.mail or 0) + (s.equipped or 0) + (s.void or 0) + (s.auctions or 0)
end

local function AddItemLines(tooltip, itemLink)
	local cfg = Inv.GetAwarenessOptions()
	if not cfg.showItems or not ShiftOk(cfg) then
		return
	end
	local info = Summaries.GetTooltipInfoByLink(itemLink, cfg.connectedRealmsOnly, cfg.factionOnly)
	if type(info) ~= "table" then
		return
	end
	if not cfg.showEquipped then
		for i = 1, #(info.characters or {}) do
			info.characters[i].equipped = 0
		end
	end
	if not cfg.showGuild then
		info.guilds = {}
	end

	table.sort(info.characters or {}, function(a, b)
		local left, right = TotalOf(a), TotalOf(b)
		if left == right then
			return CharComparator(a, b)
		end
		return left > right
	end)
	table.sort(info.guilds or {}, function(a, b)
		if (a.bank or 0) == (b.bank or 0) then
			if a.realmNormalized == b.realmNormalized then
				return tostring(a.guild) < tostring(b.guild)
			end
			return tostring(a.realmNormalized) < tostring(b.realmNormalized)
		end
		return (a.bank or 0) > (b.bank or 0)
	end)

	local totals = 0
	local seenRealms = {}
	for i = 1, #(info.characters or {}) do
		local s = info.characters[i]
		totals = totals + TotalOf(s)
		seenRealms[s.realmNormalized or ""] = true
	end
	for i = 1, #(info.guilds or {}) do
		totals = totals + (info.guilds[i].bank or 0)
		seenRealms[info.guilds[i].realmNormalized or ""] = true
	end
	totals = totals + ((info.warband and info.warband[1]) or 0)
	if totals <= 0 then
		return
	end
	if GetNormalizedRealmName then
		seenRealms[GetNormalizedRealmName() or ""] = true
	end
	local realmCount = 0
	for _ in pairs(seenRealms) do
		realmCount = realmCount + 1
	end
	local appendRealm = realmCount > 1

	if cfg.blankLine then
		tooltip:AddLine(" ")
	end
	AddDouble(tooltip, "Inventory", LinkColor("Total " .. White(totals)))

	local shown = 0
	for i = 1, #(info.characters or {}) do
		local s = info.characters[i]
		local parts = {}
		if (s.bags or 0) > 0 then
			parts[#parts + 1] = "Bags " .. White(s.bags)
		end
		if (s.bank or 0) > 0 then
			parts[#parts + 1] = "Bank " .. White(s.bank)
		end
		if (s.mail or 0) > 0 then
			parts[#parts + 1] = "Mail " .. White(s.mail)
		end
		if (s.equipped or 0) > 0 then
			parts[#parts + 1] = "Equipped " .. White(s.equipped)
		end
		if (s.void or 0) > 0 then
			parts[#parts + 1] = "Void " .. White(s.void)
		end
		if (s.auctions or 0) > 0 then
			parts[#parts + 1] = "Auctions " .. White(s.auctions)
		end
		if #parts > 0 then
			if shown >= CHARACTER_LIMIT then
				tooltip:AddLine("  ...")
				break
			end
			local label = s.character or "?"
			if appendRealm and s.realmNormalized then
				label = label .. "-" .. s.realmNormalized
			end
			label = ClassColorName(label, s.className)
			if cfg.raceIcons and s.race then
				local icon = CharacterIcon(s.race, s.sex)
				if icon ~= "" then
					label = icon .. " " .. label
				end
			end
			AddDouble(tooltip, "  " .. label, LinkColor(table.concat(parts, ", ")))
			shown = shown + 1
		end
	end

	for i = 1, math.min(#(info.guilds or {}), CHARACTER_LIMIT) do
		local s = info.guilds[i]
		local label = s.guild or "Guild"
		if appendRealm and s.realmNormalized then
			label = label .. "-" .. s.realmNormalized
		end
		if TRANSMOGRIFY_FONT_COLOR and TRANSMOGRIFY_FONT_COLOR.WrapTextInColorCode then
			label = TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(label)
		end
		if cfg.raceIcons then
			label = GuildIcon() .. " " .. label
		end
		AddDouble(tooltip, "  " .. label, LinkColor("Bank " .. White(s.bank or 0)))
	end

	if info.warband and (info.warband[1] or 0) > 0 then
		local label = "Warband"
		if PASSIVE_SPELL_FONT_COLOR and PASSIVE_SPELL_FONT_COLOR.WrapTextInColorCode then
			label = PASSIVE_SPELL_FONT_COLOR:WrapTextInColorCode(label)
		end
		if cfg.raceIcons then
			label = WarbandIcon() .. " " .. label
		end
		AddDouble(tooltip, "  " .. label, LinkColor("Bank " .. White(info.warband[1])))
	end

	local Client = Flux.Client
	if Client and not Client.isRetail and tooltip.Show then
		tooltip:Show()
	end
end

local function AddCurrencyLines(tooltip, currencyID)
	local cfg = Inv.GetAwarenessOptions()
	if not cfg.showCurrencies or not ShiftOk(cfg) then
		return
	end
	currencyID = tonumber(currencyID)
	if not currencyID then
		return
	end
	local rows = Ledger.GetCurrencyRows(currencyID, cfg.connectedRealmsOnly, cfg.factionOnly)
	if type(rows) ~= "table" or #rows == 0 then
		return
	end
	table.sort(rows, function(a, b)
		if (a.quantity or 0) == (b.quantity or 0) then
			return tostring(a.character) < tostring(b.character)
		end
		return (a.quantity or 0) > (b.quantity or 0)
	end)
	local total = 0
	local seenRealms = {}
	for i = 1, #rows do
		total = total + (rows[i].quantity or 0)
		seenRealms[rows[i].realmNormalized or ""] = true
	end
	if total <= 0 then
		return
	end
	if GetNormalizedRealmName then
		seenRealms[GetNormalizedRealmName() or ""] = true
	end
	local realmCount = 0
	for _ in pairs(seenRealms) do
		realmCount = realmCount + 1
	end
	local appendRealm = realmCount > 1
	if cfg.blankLine then
		tooltip:AddLine(" ")
	end
	AddDouble(tooltip, "Currencies", LinkColor("Total " .. White(total)))
	for i = 1, math.min(#rows, CHARACTER_LIMIT) do
		local s = rows[i]
		local label = s.character or "?"
		if appendRealm and s.realmNormalized then
			label = label .. "-" .. s.realmNormalized
		end
		label = ClassColorName(label, s.className)
		if cfg.raceIcons and s.race then
			local icon = CharacterIcon(s.race, s.sex)
			if icon ~= "" then
				label = icon .. " " .. label
			end
		end
		AddDouble(tooltip, "  " .. label, White(s.quantity))
	end
	if #rows > CHARACTER_LIMIT then
		tooltip:AddLine("  ...")
	end
	local Client = Flux.Client
	if Client and not Client.isRetail and tooltip.Show then
		tooltip:Show()
	end
end

local function ValidateTooltip(tooltip)
	if not tooltip or tooltip.IsForbidden and tooltip:IsForbidden() then
		return false
	end
	if tooltip == GameTooltip or tooltip == ItemRefTooltip then
		return true
	end
	local name = tooltip.GetName and tooltip:GetName() or ""
	return name == "GameTooltipTooltip" or name:match("^NotGameTooltip")
end

local function HookClassicItem(tooltip)
	local ready = true
	tooltip:HookScript("OnTooltipSetItem", function(self)
		if not ready then
			return
		end
		ready = false
		local _, link = self:GetItem()
		if link then
			AddItemLines(self, link)
		end
	end)
	tooltip:HookScript("OnTooltipCleared", function()
		ready = true
	end)
end

local function SetupTooltips()
	if TooltipDataProcessor and C_TooltipInfo and Enum and Enum.TooltipDataType then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
			if not ValidateTooltip(tooltip) then
				return
			end
			local link
			if TooltipUtil and TooltipUtil.GetDisplayedItem then
				local _, displayed = TooltipUtil.GetDisplayedItem(tooltip)
				link = displayed
			end
			if not link and tooltip.GetItem then
				local _, displayed = tooltip:GetItem()
				link = displayed
			end
			if link then
				AddItemLines(tooltip, link)
			end
		end)
		if Enum.TooltipDataType.Currency then
			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, function(tooltip)
				if not ValidateTooltip(tooltip) then
					return
				end
				local data = tooltip.GetPrimaryTooltipData and tooltip:GetPrimaryTooltipData()
				if data and data.id then
					AddCurrencyLines(tooltip, data.id)
				end
			end)
		end
		return
	end
	if GameTooltip then
		HookClassicItem(GameTooltip)
	end
	if ItemRefTooltip then
		HookClassicItem(ItemRefTooltip)
	end
	local function CurrencyFromToken(tooltip, index)
		if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyListLink then
			return
		end
		local link = C_CurrencyInfo.GetCurrencyListLink(index)
		if not link then
			return
		end
		local id = tonumber(link:match("|Hcurrency:(%d+)"))
		if id then
			AddCurrencyLines(tooltip, id)
		end
	end
	if GameTooltip and GameTooltip.SetCurrencyToken then
		hooksecurefunc(GameTooltip, "SetCurrencyToken", CurrencyFromToken)
	end
	if GameTooltip and GameTooltip.SetCurrencyByID then
		hooksecurefunc(GameTooltip, "SetCurrencyByID", function(self, id)
			AddCurrencyLines(self, id)
		end)
	end
end

function Tooltip.Start()
	if started then
		return
	end
	if Tooltip.IsDelegated() then
		started = true
		return
	end
	started = true
	Flux.Safecall(SetupTooltips)
end
