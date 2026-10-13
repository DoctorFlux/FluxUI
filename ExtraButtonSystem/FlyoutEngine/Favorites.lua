-- ExtraButtonSystem/FlyoutEngine/Favorites.lua — per-modifier flyout favorites.
local addonName, ns = ...
local Flux = ns.Flux
local Flyout = Flux.EBS and Flux.EBS.Flyout
if not Flyout then
	return
end

local Favorites = {}
Flyout.Favorites = Favorites
_G.FluxFlyoutFavorites = Favorites

local FAVORITES_SAVED_VAR = "FluxFlyoutFavorites_Data"
local PRIORITY_ORDER = { "nomod", "shift", "ctrl", "alt", "ctrl+shift", "shift+alt", "ctrl+alt", "ctrl+shift+alt" }

local registeredButtons = {}
local categoryConfigs = {}
local listeners = {}
local syncInProgress = false

local function GetCharKey()
	local PN = Flux and Flux.PlayerName
	if PN and PN.GetCharKey then
		return PN.GetCharKey("hyphen")
	end
	local name = UnitName("player")
	local realm = GetRealmName()
	if not name or not realm then
		return nil
	end
	return name .. "-" .. realm
end

local function GetFavoritesTable()
	if not _G[FAVORITES_SAVED_VAR] then
		_G[FAVORITES_SAVED_VAR] = {}
	end
	local charKey = GetCharKey()
	if not charKey then
		return {}
	end
	if not _G[FAVORITES_SAVED_VAR][charKey] then
		_G[FAVORITES_SAVED_VAR][charKey] = {}
	end
	return _G[FAVORITES_SAVED_VAR][charKey]
end

local function NormalizeModKey(modKey)
	if type(modKey) ~= "string" or modKey == "" then
		return "nomod"
	end
	local s = string.lower(modKey):gsub("control", "ctrl")
	local parts = {}
	for token in string.gmatch(s, "[^+]+") do
		token = token:gsub("%s+", "")
		if token == "ctrl" or token == "shift" or token == "alt" or token == "nomod" then
			parts[token] = true
		end
	end
	local ordered = {}
	if parts.ctrl then
		ordered[#ordered + 1] = "ctrl"
	end
	if parts.shift then
		ordered[#ordered + 1] = "shift"
	end
	if parts.alt then
		ordered[#ordered + 1] = "alt"
	end
	if #ordered == 0 then
		return "nomod"
	end
	return table.concat(ordered, "+")
end

local function GetCurrentModKey()
	local tokens = {}
	if IsControlKeyDown and IsControlKeyDown() then
		tokens[#tokens + 1] = "ctrl"
	end
	if IsShiftKeyDown and IsShiftKeyDown() then
		tokens[#tokens + 1] = "shift"
	end
	if IsAltKeyDown and IsAltKeyDown() then
		tokens[#tokens + 1] = "alt"
	end
	if #tokens == 0 then
		return "nomod"
	end
	return table.concat(tokens, "+")
end

local function NotifyListeners(category)
	for i = 1, #listeners do
		pcall(listeners[i], category)
	end
end

local function GetSpellNameById(spellId)
	if type(spellId) == "string" and spellId ~= "" and not tonumber(spellId) then
		return spellId
	end
	spellId = tonumber(spellId)
	if not spellId then
		return nil
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellId)
		if type(info) == "table" and info.name then
			return info.name
		end
		if type(info) == "string" then
			return info
		end
	end
	if GetSpellInfo then
		local name = GetSpellInfo(spellId)
		if name and name ~= "" then
			return name
		end
	end
	return nil
end

local function GetDestinationFromSpellName(spellName)
	if not spellName then
		return nil
	end
	return spellName:match("^Teleport:%s*(.+)$")
		or spellName:match("^Portal:%s*(.+)$")
		or spellName:match("^Teleport：%s*(.+)$")
		or spellName:match("^Portal：%s*(.+)$")
end

local function SpellKindFromName(spellName)
	if not spellName then
		return nil
	end
	if spellName:find("^Teleport:", 1, true) or spellName:find("^Teleport：", 1, true) then
		return "Teleport"
	end
	if spellName:find("^Portal:", 1, true) or spellName:find("^Portal：", 1, true) then
		return "Portal"
	end
	return nil
end

local function PairNameFromSpellName(spellName)
	local dest = GetDestinationFromSpellName(spellName)
	if not dest then
		return nil
	end
	local kind = SpellKindFromName(spellName)
	if kind == "Teleport" then
		return "Portal: " .. dest
	end
	if kind == "Portal" then
		return "Teleport: " .. dest
	end
	return nil
end

local function PairFromKnownLists(spellId)
	local M = _G.FluxNCTeleportPortal
	if not M then
		return nil
	end
	local name = GetSpellNameById(spellId)
	local dest = GetDestinationFromSpellName(name)
	if not dest then
		return nil
	end
	local wantKind = SpellKindFromName(name) == "Teleport" and "Portal" or "Teleport"
	local list
	if wantKind == "Portal" and M.GetKnownPortalSpells then
		list = M.GetKnownPortalSpells()
	elseif wantKind == "Teleport" and M.GetKnownTeleportSpells then
		list = M.GetKnownTeleportSpells()
	end
	for i = 1, #(list or {}) do
		local sp = list[i]
		if sp and GetDestinationFromSpellName(sp.name) == dest then
			return tonumber(sp.spellID) or sp.spellID
		end
	end
	return nil
end

local function GetPairedTeleportPortalSpellID(spellId)
	spellId = tonumber(spellId) or spellId
	if not spellId then
		return nil
	end
	local fromLists = PairFromKnownLists(spellId)
	if fromLists then
		return fromLists
	end
	local spellName = GetSpellNameById(spellId)
	local pairName = PairNameFromSpellName(spellName)
	if not pairName then
		return nil
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(pairName)
		if type(info) == "table" and info.spellID then
			return info.spellID
		end
	end
	if GetSpellInfo then
		local _, _, _, _, _, _, id = GetSpellInfo(pairName)
		if id then
			return id
		end
	end
	return nil
end

local function CoerceFavoriteToCategory(category, id)
	if not id or (category ~= "Teleport" and category ~= "Portal") then
		return id
	end
	local kind = SpellKindFromName(GetSpellNameById(id))
	if kind == category then
		return id
	end
	return GetPairedTeleportPortalSpellID(id)
end

local function SameFavoriteId(category, stored, kidId)
	if stored == nil or kidId == nil then
		return false
	end
	if tostring(stored) == tostring(kidId) then
		return true
	end
	local coercedStored = CoerceFavoriteToCategory(category, stored)
	if coercedStored and tostring(coercedStored) == tostring(kidId) then
		return true
	end
	local coercedKid = CoerceFavoriteToCategory(category, kidId)
	if coercedStored and coercedKid and tostring(coercedStored) == tostring(coercedKid) then
		return true
	end
	if coercedKid and tostring(stored) == tostring(coercedKid) then
		return true
	end
	local destA = GetDestinationFromSpellName(GetSpellNameById(stored))
	local destB = GetDestinationFromSpellName(GetSpellNameById(kidId))
	return destA and destB and destA == destB
end

local function GetPairedID(category, itemIdOrSpellId)
	local config = categoryConfigs[category] or {}
	if config.getPairedID then
		return config.getPairedID(itemIdOrSpellId, itemIdOrSpellId)
	end
	return nil
end

function Favorites.RegisterCategory(category, config)
	if not category or type(category) ~= "string" then
		return
	end
	categoryConfigs[category] = config or categoryConfigs[category] or {}
end

function Favorites.RegisterListener(callback)
	if type(callback) == "function" then
		listeners[#listeners + 1] = callback
	end
end

function Favorites.RegisterButton(widget, category, config)
	if not widget or not category then
		return
	end
	Favorites.RegisterCategory(category, config)
	registeredButtons[widget] = { category = category, config = config or {} }
	widget._fluxFlyoutFavoritesCategory = category
	widget._fluxFlyoutFavoritesEnabled = true
end

function Favorites.UnregisterButton(widget)
	if not widget then
		return
	end
	registeredButtons[widget] = nil
	widget._fluxFlyoutFavoritesCategory = nil
	widget._fluxFlyoutFavoritesEnabled = nil
end

function Favorites.GetButtonCategory(widget)
	local reg = widget and registeredButtons[widget]
	return (reg and reg.category) or (widget and widget._fluxFlyoutFavoritesCategory) or nil
end

function Favorites.GetFavorite(category, modKey)
	if not category then
		return nil
	end
	local key = NormalizeModKey(modKey)
	local root = GetFavoritesTable()
	local favs = root[category]
	local id = type(favs) == "table" and favs[key] or nil
	id = CoerceFavoriteToCategory(category, id)
	-- Backup Teleport↔Portal sync: if this mode has no favorite yet, use the
	-- paired destination from the other category so the host face can swap.
	if not id and (category == "Teleport" or category == "Portal") then
		local partner = (category == "Teleport") and "Portal" or "Teleport"
		local partnerFavs = root[partner]
		local partnerId = type(partnerFavs) == "table" and partnerFavs[key] or nil
		id = CoerceFavoriteToCategory(category, partnerId)
		if id then
			root[category] = root[category] or {}
			root[category][key] = id
		end
	end
	return id
end

function Favorites.SetFavorite(category, itemIdOrSpellId, modKey)
	if not category or not itemIdOrSpellId then
		return
	end
	Favorites.RegisterCategory(category)
	local key = NormalizeModKey(modKey)
	local root = GetFavoritesTable()
	root[category] = root[category] or {}
	root[category][key] = tonumber(itemIdOrSpellId) or itemIdOrSpellId
	local config = categoryConfigs[category] or {}
	if config.syncPartner and not syncInProgress then
		local paired = GetPairedID(category, itemIdOrSpellId) or CoerceFavoriteToCategory(config.syncPartner, itemIdOrSpellId)
		if paired then
			syncInProgress = true
			root[config.syncPartner] = root[config.syncPartner] or {}
			root[config.syncPartner][key] = paired
			syncInProgress = false
			NotifyListeners(config.syncPartner)
		end
	end
	Favorites.UpdateAllVisibleStars()
	Favorites.RefreshFlyoutTooltip()
	NotifyListeners(category)
end

function Favorites.ClearFavorite(category, modKey)
	if not category then
		return
	end
	local key = NormalizeModKey(modKey)
	local root = GetFavoritesTable()
	local favs = root[category]
	local itemIdOrSpellId = type(favs) == "table" and favs[key] or nil
	if type(favs) == "table" then
		favs[key] = nil
		local hasAny = false
		for _, v in pairs(favs) do
			if v then
				hasAny = true
				break
			end
		end
		if not hasAny then
			root[category] = nil
		end
	end
	local config = categoryConfigs[category] or {}
	local partner = config.syncPartner
	if (category == "Teleport" or category == "Portal") then
		partner = (category == "Teleport") and "Portal" or "Teleport"
	end
	if partner and not syncInProgress then
		syncInProgress = true
		local partnerFavs = root[partner]
		if type(partnerFavs) == "table" then
			if itemIdOrSpellId then
				local paired = GetPairedID(category, itemIdOrSpellId)
				local current = partnerFavs[key]
				if current and (not paired or tostring(current) == tostring(paired) or SameFavoriteId(partner, current, itemIdOrSpellId)) then
					partnerFavs[key] = nil
				end
			else
				partnerFavs[key] = nil
			end
			local hasAny = false
			for _, v in pairs(partnerFavs) do
				if v then
					hasAny = true
					break
				end
			end
			if not hasAny then
				root[partner] = nil
			end
		end
		syncInProgress = false
		NotifyListeners(partner)
	end
	Favorites.UpdateAllVisibleStars()
	Favorites.RefreshFlyoutTooltip()
	NotifyListeners(category)
end

function Favorites.ToggleFavorite(category, itemIdOrSpellId, modKey)
	if not category or not itemIdOrSpellId then
		return
	end
	local key = NormalizeModKey(modKey or GetCurrentModKey())
	local current = Favorites.GetFavorite(category, key)
	if current and SameFavoriteId(category, current, itemIdOrSpellId) then
		Favorites.ClearFavorite(category, key)
	else
		Favorites.SetFavorite(category, itemIdOrSpellId, key)
	end
end

function Favorites.GetBestAvailableFavorite(category, requestedModKey, inBagsSet)
	if not category or type(inBagsSet) ~= "table" then
		return nil, nil
	end
	local key = NormalizeModKey(requestedModKey)
	local exactFav = Favorites.GetFavorite(category, key)
	if exactFav and inBagsSet[exactFav] then
		return exactFav, key
	end
	for i = 1, #PRIORITY_ORDER do
		local modKey = PRIORITY_ORDER[i]
		local fav = Favorites.GetFavorite(category, modKey)
		if fav and inBagsSet[fav] then
			return fav, modKey
		end
	end
	return nil, nil
end

function Favorites.GetFavoritesTable()
	return GetFavoritesTable()
end

local function DefId(def)
	if not def then
		return nil
	end
	return tonumber(def.spellID) or tonumber(def.item) or tonumber(def.spell) or def.item or def.spell
end

local function EnsureStar(kid)
	if kid.FluxFlyoutFavStar_Custom then
		return kid.FluxFlyoutFavStar_Custom
	end
	local star = kid:CreateTexture(nil, "OVERLAY", nil, 7)
	local ok = pcall(function()
		star:SetAtlas("PetJournal-FavoritesIcon", true)
	end)
	if not ok then
		star:SetTexture("Interface\\COMMON\\FavoritesIcon")
		star:SetSize(18, 18)
	end
	star:SetPoint("TOPLEFT", kid, "TOPLEFT", -2, 2)
	star:Hide()
	kid.FluxFlyoutFavStar_Custom = star
	return star
end

function Favorites.PaintKidStar(kid, category)
	if not kid then
		return
	end
	local star = EnsureStar(kid)
	if kid._fluxSkipFavorites or (kid._fluxFlyoutDef and kid._fluxFlyoutDef.skipFavorite) then
		star:Hide()
		return
	end
	local id = DefId(kid._fluxFlyoutDef)
	if category and id and Favorites.IsFavoritedAnyMod(category, id, id) then
		star:Show()
		return
	end
	star:Hide()
end

function Favorites.UpdateAllVisibleStars()
	if not Flyout.attached then
		return
	end
	for widget, rec in pairs(Flyout.attached) do
		local popup = rec and rec.popup
		local category = Favorites.GetButtonCategory(widget) or (rec.opts and rec.opts.favoriteCategory)
		if popup and popup.kids then
			for i = 1, #popup.kids do
				Favorites.PaintKidStar(popup.kids[i], category)
			end
		end
	end
end

function Favorites.PromoteAvailable(list, category)
	if type(list) ~= "table" or not category then
		return list
	end
	local inBags = {}
	for i = 1, #list do
		local id = DefId(list[i])
		if id then
			inBags[id] = true
			inBags[tonumber(id) or id] = true
		end
	end
	local favId = Favorites.GetBestAvailableFavorite(category, GetCurrentModKey(), inBags)
	if not favId then
		return list
	end
	local promoted
	local rest = {}
	for i = 1, #list do
		local id = DefId(list[i])
		if id and tostring(id) == tostring(favId) and not promoted then
			promoted = list[i]
		else
			rest[#rest + 1] = list[i]
		end
	end
	if not promoted then
		return list
	end
	local out = { promoted }
	for i = 1, #rest do
		out[#out + 1] = rest[i]
	end
	return out
end

function Favorites.IsFavoritedAnyMod(category, itemId, spellId)
	if not category then
		return false
	end
	local want = tonumber(itemId) or tonumber(spellId) or itemId or spellId
	if not want then
		return false
	end
	local root = GetFavoritesTable()
	local function tableHas(favs)
		if type(favs) ~= "table" then
			return false
		end
		for _, v in pairs(favs) do
			if SameFavoriteId(category, v, want) then
				return true
			end
		end
		return false
	end
	if tableHas(root[category]) then
		return true
	end
	if category == "Teleport" or category == "Portal" then
		local partner = (category == "Teleport") and "Portal" or "Teleport"
		if tableHas(root[partner]) then
			return true
		end
	end
	return false
end

function Favorites.RefreshFlyoutTooltip()
	if not GameTooltip or not GameTooltip:IsShown() then
		return
	end
	local owner = GameTooltip:GetOwner()
	if not owner or not owner.FluxFlyoutFavStar_Custom then
		return
	end
	local function rebuild()
		if owner:IsVisible() and owner.IsMouseOver and owner:IsMouseOver() then
			local onEnter = owner.GetScript and owner:GetScript("OnEnter")
			if onEnter then
				pcall(onEnter, owner)
			end
		end
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0.01, rebuild)
	else
		rebuild()
	end
end

function Favorites.AppendTooltip(kid, category, itemId, spellId)
	if not kid or not category or not GameTooltip then
		return
	end
	if GameTooltip.IsOwned and not GameTooltip:IsOwned(kid) then
		return
	end
	local want = tonumber(itemId) or tonumber(spellId) or itemId or spellId
	local root = GetFavoritesTable()
	local favs = root[category]
	if type(favs) ~= "table" then
		favs = {}
	end
	local modList = {}
	local seen = {}
	local function collect(from)
		if type(from) ~= "table" then
			return
		end
		for key, v in pairs(from) do
			if want and SameFavoriteId(category, v, want) then
				local label = (key == "" or key == "nomod") and "no mod" or key
				if not seen[label] then
					seen[label] = true
					modList[#modList + 1] = label
				end
			end
		end
	end
	collect(favs)
	if category == "Teleport" or category == "Portal" then
		local partner = (category == "Teleport") and "Portal" or "Teleport"
		collect(root[partner])
	end
	if #modList > 0 then
		table.sort(modList, function(a, b)
			local order = {
				["no mod"] = 0,
				ctrl = 1,
				shift = 2,
				alt = 3,
				["ctrl+shift"] = 4,
				["ctrl+alt"] = 5,
				["shift+alt"] = 6,
				["ctrl+shift+alt"] = 7,
			}
			return (order[a] or 99) < (order[b] or 99)
		end)
		GameTooltip:AddLine("|cff33ff33Favorites: " .. table.concat(modList, ", ") .. "|r")
	end
	local modLabel = GetCurrentModKey()
	if modLabel == "" or modLabel == "nomod" then
		modLabel = "no mod"
	end
	if Favorites.IsFavoritedAnyMod(category, itemId, spellId) then
		GameTooltip:AddLine("|cffaaaaaaRight-click: Clear favorite|r")
	else
		GameTooltip:AddLine("|cffaaaaaaRight-click: Favorite (for " .. modLabel .. ")|r")
	end
	GameTooltip:Show()
end

function Favorites.OnKidRightClick(kid, widget)
	local def = kid and kid._fluxFlyoutDef
	if def and (def.skipFavorite or kid._fluxSkipFavorites) then
		return
	end
	local category = Favorites.GetButtonCategory(widget)
		or (widget and widget._fluxFlyoutFavoritesCategory)
	if not category then
		local rec = Flyout.HostOf and Flyout.HostOf(widget)
		category = rec and rec.opts and rec.opts.favoriteCategory
	end
	local id = DefId(kid and kid._fluxFlyoutDef)
	if not category or not id then
		return
	end
	Favorites.ToggleFavorite(category, id, GetCurrentModKey())
	Favorites.PaintKidStar(kid, category)
end

Favorites.RegisterCategory("Mount", { itemType = "item" })
Favorites.RegisterCategory("TeleportItem", { itemType = "item" })
Favorites.RegisterCategory("Teleport", {
	itemType = "spell",
	syncPartner = "Portal",
	getPairedID = function(_, spellId)
		return GetPairedTeleportPortalSpellID(spellId)
	end,
})
Favorites.RegisterCategory("Portal", {
	itemType = "spell",
	syncPartner = "Teleport",
	getPairedID = function(_, spellId)
		return GetPairedTeleportPortalSpellID(spellId)
	end,
})

return Favorites
