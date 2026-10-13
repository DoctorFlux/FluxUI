-- Bars/SpellRank.lua — lower-rank grayscale + rank-up + spellbook controls.
-- Forever, Classic Era, Anniversary, Wrath. Live Midnight has no spell ranks
-- (wow-ui-source-live vs wow-ui-source-forever / classic_era / classic_anniversary).
-- Visual: SetDesaturated(true) for a learned-but-not-highest rank. Usable/OOR
-- stay vertex color. Walks the rewrite strip and Extra Buttons, not LAB.
local addonName, ns = ...
local Flux = ns.Flux
local Bars = Flux.Bars

local SpellRank = {}
Bars.SpellRank = SpellRank
ns.FluxSpellRankManager = SpellRank

local function RankSupported()
	local Chrome = Flux.SpellBookChrome
	if Chrome and Chrome.RankChromeAllowed then
		return Chrome.RankChromeAllowed()
	end
	local C = Flux.Client
	if C then
		if C.isLiveMidnight == true or C.isCata == true or C.isMists == true then
			return false
		end
		if C.isEra == true or C.isAnniversary == true or C.isTBC == true or C.isWrath == true then
			return true
		end
	end
	if C_SpellBook and type(C_SpellBook.IsSpellBookItemLowRank) == "function" then
		return true
	end
	local cap = Flux.Cap
	if cap and cap.supportsPerRankSpellBarFeatures == true then
		return true
	end
	local api = _G.FLUX_API
	if api then
		if api.isLiveMidnight == true then
			return false
		end
		return api.supportsPerRankSpellBarFeatures == true
	end
	return false
end

local rankSupported = RankSupported()
local spellBlacklistPanelRefresh = nil

local function notifySpellBlacklistPanel()
	if spellBlacklistPanelRefresh then
		pcall(spellBlacklistPanelRefresh)
	end
end

local function After(delay, fn)
	if C_Timer and C_Timer.After then
		C_Timer.After(delay, fn)
		return
	end
	if Flux.Timer and Flux.Timer.After then
		Flux.Timer.After(delay, fn)
	end
end

-- ---------------------------------------------------------------------------
-- Saved variables
-- ---------------------------------------------------------------------------

local function EnsureDB()
	if not _FluxUI_CharSavedVars then
		_FluxUI_CharSavedVars = {}
	end
	if not _FluxUI_CharSavedVars.spellRankManager then
		_FluxUI_CharSavedVars.spellRankManager = {
			autoRankUp = false,
			blacklist = {},
		}
	end
	if not _FluxUI_CharSavedVars.spellRankManager.blacklist then
		_FluxUI_CharSavedVars.spellRankManager.blacklist = {}
	end
end

local function MigrateAutoRankFromLegacy(t)
	if not t or t.autoRankUp ~= nil then
		return
	end
	EnsureDB()
	local legacy = _FluxUI_CharSavedVars.spellRankManager and _FluxUI_CharSavedVars.spellRankManager.autoRankUp
	t.autoRankUp = legacy == true
end

local function GetAutoRankUpEnabled()
	EnsureDB()
	if FluxOptions and FluxOptions.GetActionbarsDB then
		local t = FluxOptions:GetActionbarsDB()
		if t then
			MigrateAutoRankFromLegacy(t)
			return t.autoRankUp == true
		end
	end
	return _FluxUI_CharSavedVars.spellRankManager.autoRankUp == true
end

local function SetAutoRankUpEnabled(enabled)
	EnsureDB()
	local on = enabled == true
	if FluxOptions and FluxOptions.GetActionbarsDB then
		local t = FluxOptions:GetActionbarsDB()
		if t then
			MigrateAutoRankFromLegacy(t)
			t.autoRankUp = on
			if _FluxUI_CharSavedVars.spellRankManager then
				_FluxUI_CharSavedVars.spellRankManager.autoRankUp = on
			end
			return
		end
	end
	_FluxUI_CharSavedVars.spellRankManager.autoRankUp = on
end

local function NormalizeSpellID(spellID)
	if not spellID then
		return nil
	end
	local n = tonumber(spellID)
	if n and n > 0 then
		return math.floor(n)
	end
	return nil
end

local function IsSpellBlacklisted(spellID)
	EnsureDB()
	local id = NormalizeSpellID(spellID)
	if not id then
		return false
	end
	return _FluxUI_CharSavedVars.spellRankManager.blacklist[id] == true
end

local function ToggleSpellBlacklist(spellID)
	EnsureDB()
	local id = NormalizeSpellID(spellID)
	if not id then
		return false
	end
	if IsSpellBlacklisted(id) then
		_FluxUI_CharSavedVars.spellRankManager.blacklist[id] = nil
		notifySpellBlacklistPanel()
		return false
	end
	_FluxUI_CharSavedVars.spellRankManager.blacklist[id] = true
	notifySpellBlacklistPanel()
	return true
end

-- ---------------------------------------------------------------------------
-- Rank cache
-- ---------------------------------------------------------------------------

local spellRankCache = {}
local cacheDirty = true

local function Trim(str)
	if type(str) ~= "string" then
		return str
	end
	return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function SpellName(spellID)
	if not spellID then
		return nil
	end
	if Flux.Spell and Flux.Spell.GetName then
		return Flux.Spell.GetName(spellID)
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		if info then
			return info.name
		end
	end
	if GetSpellInfo then
		return GetSpellInfo(spellID)
	end
	return nil
end

local function GetSpellBaseName(spellID)
	local spellName = SpellName(spellID)
	if not spellName then
		return nil
	end
	local baseName = spellName:match("^(.+)%s*%(%s*Rank%s*%d+%s*%)%s*$")
	if baseName then
		return Trim(baseName)
	end
	return Trim(spellName)
end

local function GetSpellRank(spellID)
	if not spellID then
		return nil
	end
	local subtext
	if Flux.Spell and Flux.Spell.GetSubtext then
		subtext = Flux.Spell.GetSubtext(spellID)
	elseif C_Spell and C_Spell.GetSpellSubtext then
		subtext = C_Spell.GetSpellSubtext(spellID)
	elseif GetSpellSubtext then
		subtext = GetSpellSubtext(spellID)
	end
	if subtext and subtext ~= "" then
		local rankNum = tonumber(subtext:match("Rank%s*(%d+)"))
		if rankNum then
			return rankNum
		end
	end
	local spellName = SpellName(spellID)
	if spellName then
		local rankNum = tonumber(spellName:match("%(%s*Rank%s*(%d+)%s*%)"))
		if rankNum then
			return rankNum
		end
	end
	return nil
end

local function NoteCachedRank(spellID)
	local baseName = GetSpellBaseName(spellID)
	local rank = GetSpellRank(spellID)
	if not baseName or not rank then
		return
	end
	local cur = spellRankCache[baseName]
	if not cur then
		spellRankCache[baseName] = { highestRank = rank, spellID = spellID }
		return
	end
	if rank > cur.highestRank then
		cur.highestRank = rank
		cur.spellID = spellID
	end
end

local function BuildSpellRankCache()
	if not RankSupported() then
		return
	end
	rankSupported = true
	spellRankCache = {}
	if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
		local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 1
		local i = 1
		while true do
			local info = C_SpellBook.GetSpellBookItemInfo(i, bank)
			if not info then
				break
			end
			if info.itemType == Enum.SpellBookItemType.Spell and info.actionID then
				NoteCachedRank(info.actionID)
			end
			i = i + 1
		end
	elseif GetNumSpellTabs then
		for tabIndex = 1, GetNumSpellTabs() do
			local _, _, offset, numSpells = GetSpellTabInfo(tabIndex)
			for i = 1, numSpells do
				local slotIndex = offset + i
				local spellType, spellID = GetSpellBookItemInfo(slotIndex, "spell")
				if spellType == "SPELL" and spellID then
					NoteCachedRank(spellID)
				end
			end
		end
	end
	cacheDirty = false
end

local function GetHighestRankForSpell(baseName)
	if cacheDirty then
		BuildSpellRankCache()
	end
	if not baseName or not spellRankCache[baseName] then
		return nil, nil
	end
	return spellRankCache[baseName].highestRank, spellRankCache[baseName].spellID
end

local function IsLowerRank(spellID)
	if not spellID then
		return false
	end
	local baseName = GetSpellBaseName(spellID)
	if not baseName then
		return false
	end
	local currentRank = GetSpellRank(spellID)
	local highestRank = GetHighestRankForSpell(baseName)
	if not currentRank or not highestRank then
		return false
	end
	return currentRank < highestRank
end

local function GetBlacklistDisplayText()
	EnsureDB()
	local blacklist = _FluxUI_CharSavedVars.spellRankManager.blacklist
	local count = 0
	local spellList = {}
	for spellID in pairs(blacklist) do
		count = count + 1
		local baseName = GetSpellBaseName(spellID)
		local rank = GetSpellRank(spellID)
		local displayName = baseName or ("Spell " .. tostring(spellID))
		if rank then
			displayName = displayName .. " (Rank " .. rank .. ")"
		end
		spellList[#spellList + 1] = displayName
	end
	if count == 0 then
		return nil, 0
	end
	table.sort(spellList)
	return table.concat(spellList, ", "), count
end

local function FormatSpellCastName(spellId)
	if Flux.Spell and Flux.Spell.FormatCastAttribute then
		local ok, attr = pcall(Flux.Spell.FormatCastAttribute, spellId)
		if ok and type(attr) == "string" then
			return attr
		end
	end
	return GetSpellBaseName(spellId)
end

-- ---------------------------------------------------------------------------
-- Spell id from macros / surfaces
-- ---------------------------------------------------------------------------

local function ResolveSpellTokenToSpellID(spellToken)
	if not spellToken or spellToken == "" then
		return nil
	end
	if type(spellToken) == "number" then
		if spellToken > 0 then
			return spellToken
		end
		return nil
	end
	if Flux.Spell and Flux.Spell.GetInfo then
		local _, _, _, _, _, _, spellID = Flux.Spell.GetInfo(spellToken)
		if type(spellID) == "number" and spellID > 0 then
			return spellID
		end
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellToken)
		if info and info.spellID then
			return info.spellID
		end
	end
	if GetSpellInfo then
		local _, _, _, _, _, _, spellID = GetSpellInfo(spellToken)
		if type(spellID) == "number" then
			return spellID
		end
	end
	return nil
end

local function GetSpellIDFromMacroBody(body)
	if type(body) ~= "string" or body == "" then
		return nil
	end
	for line in body:gmatch("[^\r\n]+") do
		local trimmed = line:match("^%s*(.-)%s*$") or line
		local castMatch = trimmed:match("^/cast%s+(.+)") or trimmed:match("^/use%s+(.+)")
		if castMatch then
			local token = castMatch
			if SecureCmdOptionParse then
				local chosen = SecureCmdOptionParse(castMatch)
				if chosen and chosen ~= "" then
					token = chosen
				else
					token = nil
				end
			else
				local withoutBrackets = castMatch:gsub("%[.-%]", ""):match("^%s*(.-)%s*$") or castMatch
				token = withoutBrackets:match("^([^;]+)") or withoutBrackets
			end
			if token then
				token = token:gsub("@[%w_]+", "")
				token = token:match("^%s*(.-)%s*$") or token
				token = token:gsub("^!", "")
				if token ~= "" and not token:match("^item:") and not token:match("^equip:") then
					local spellID = ResolveSpellTokenToSpellID(token)
					if spellID then
						return spellID
					end
				end
			end
		end
	end
	return nil
end

local function GetButtonIcon(frame)
	if not frame then
		return nil
	end
	if frame.WIcon and frame.WIcon.SetDesaturated then
		return frame.WIcon
	end
	if frame.icon and frame.icon.SetDesaturated then
		return frame.icon
	end
	if frame.Icon and frame.Icon.SetDesaturated then
		return frame.Icon
	end
	if frame.GetIcon then
		local icon = frame:GetIcon()
		if icon and icon.SetDesaturated then
			return icon
		end
	end
	local widget = frame.Widget
	if widget then
		if widget.icon and widget.icon.SetDesaturated then
			return widget.icon
		end
		if widget.Icon and widget.Icon.SetDesaturated then
			return widget.Icon
		end
		if widget.WIcon and widget.WIcon.SetDesaturated then
			return widget.WIcon
		end
	end
	return nil
end

local function SetRankFlag(frame, flag)
	frame._fluxRankDesaturated = flag
	if frame.Widget then
		frame.Widget._fluxRankDesaturated = flag
	end
	if frame.widget then
		frame.widget._fluxRankDesaturated = flag
	end
end

local function ExtraShownSpellId(fb)
	if not fb then
		return nil
	end
	local extraKey = fb._fluxBadgeKey or (fb.Widget and fb.Widget._fluxBadgeKey)
	if type(extraKey) == "string" and extraKey:sub(1, 6) == "extra:" then
		return tonumber(fb.SpellId or fb._fluxWantSpellId or fb.ActionValue)
	end
	local aspect = tonumber(fb._fluxAspectDisplaySpellId)
	if aspect and aspect > 0 then
		return aspect
	end
	if fb.ActionType == "spell" then
		return tonumber(fb.SpellId or fb.ActionValue)
	end
	if fb.ActionType == "macro" or fb.ActionType == "macrotext" or fb.MacroMode == "spell" then
		local sid = tonumber(fb.SpellId)
		if sid then
			return sid
		end
		if type(fb.MacroBody) == "string" then
			return GetSpellIDFromMacroBody(fb.MacroBody)
		end
	end
	return tonumber(fb.SpellId)
end

local function HostShownSpellId(host)
	if not host then
		return nil
	end
	local Paint = Bars.Paint
	if Paint and Paint.ShownSpellId then
		return Paint.ShownSpellId(host)
	end
	local nextId = tonumber(host.AssistedNextSpellId)
	if nextId and nextId > 0 then
		return nextId
	end
	local face = host._fluxFace
	if face then
		if face.MacroMode == "spell" and face.SpellId then
			return tonumber(face.SpellId)
		end
		if type(face.MacroBody) == "string" then
			local sid = GetSpellIDFromMacroBody(face.MacroBody)
			if sid then
				return sid
			end
		end
	end
	local slot = host.slot
	if Bars.Hosts and Bars.Hosts.LiveSlot then
		slot = Bars.Hosts.LiveSlot(host) or slot
	end
	if slot and GetActionInfo then
		local actionType, id, subType = GetActionInfo(slot)
		if actionType == "spell" then
			return tonumber(id)
		end
		if actionType == "macro" then
			if subType == "spell" and type(id) == "number" then
				return id
			end
			if GetMacroSpell then
				local ms = GetMacroSpell(id)
				if type(ms) == "number" then
					return ms
				end
			end
			if GetMacroBody then
				return GetSpellIDFromMacroBody(GetMacroBody(id))
			end
		end
	end
	return nil
end

local function IsFormStorm()
	local FS = Flux.FormStorm
	if FS then
		if FS.IsBursting and FS.IsBursting() then
			return true
		end
		if FS.IsSettling and FS.IsSettling() then
			return true
		end
	end
	local BE = _G.FluxButtonEvents
	if BE and BE.IsFormStormActive and BE.IsFormStormActive() then
		return true
	end
	if BE and BE.IsVehicleStormActive and BE.IsVehicleStormActive() then
		return true
	end
	return false
end

local ApplyRankDesaturation
local UpdateAllButtonDesaturation
local UpdateHostDesaturation
local UpdateFluxButtonDesaturation

function ApplyRankDesaturation(self, frame, spellId)
	if not RankSupported() or not frame then
		return false
	end
	rankSupported = true
	if frame.PlaceholderTexture and not frame.IsWispLockPlaceholder then
		return false
	end
	local key = frame._fluxBadgeKey or (frame.Widget and frame.Widget._fluxBadgeKey)
	if type(key) == "string" and key:sub(1, 6) == "extra:" then
		SetRankFlag(frame, false)
		local icon = GetButtonIcon(frame)
		if icon then
			icon:SetDesaturated(false)
		end
		return false
	end
	local aspect = tonumber(frame._fluxAspectDisplaySpellId)
	if aspect and aspect > 0 then
		spellId = aspect
	else
		spellId = tonumber(spellId) or (frame.SpellId and tonumber(frame.SpellId))
		if not spellId and type(frame.MacroBody) == "string" then
			spellId = GetSpellIDFromMacroBody(frame.MacroBody)
		end
	end
	local icon = GetButtonIcon(frame)
	if not icon then
		return false
	end
	if not spellId then
		SetRankFlag(frame, false)
		icon:SetDesaturated(false)
		return false
	end
	local shouldDesaturate = IsLowerRank(spellId)
	SetRankFlag(frame, shouldDesaturate)
	icon:SetDesaturated(shouldDesaturate)
	return shouldDesaturate
end

function UpdateHostDesaturation(host)
	if not RankSupported() or not host then
		return
	end
	ApplyRankDesaturation(SpellRank, host, HostShownSpellId(host))
end

function UpdateFluxButtonDesaturation(fb)
	if not RankSupported() or not fb then
		return
	end
	if fb.PlaceholderTexture and not fb.IsWispLockPlaceholder then
		return
	end
	ApplyRankDesaturation(SpellRank, fb, ExtraShownSpellId(fb))
end

function UpdateAllButtonDesaturation()
	if not RankSupported() then
		return
	end
	rankSupported = true
	if Bars.ForEachHost then
		Bars.ForEachHost(function(host)
			UpdateHostDesaturation(host)
		end)
	end
	local EBS = Flux.EBS
	local function touchList(list)
		if type(list) ~= "table" then
			return
		end
		for i = 1, #list do
			local fb = list[i]
			if fb then
				UpdateFluxButtonDesaturation(fb)
			end
		end
	end
	if EBS then
		touchList(EBS.buttons)
		touchList(EBS.badges)
	end
end

-- ---------------------------------------------------------------------------
-- Rank-up
-- ---------------------------------------------------------------------------

local function ResolveHighestUpgradeSpellId(spellID)
	if not spellID then
		return nil
	end
	local baseName = GetSpellBaseName(spellID)
	if not baseName then
		return nil
	end
	local currentRank = GetSpellRank(spellID)
	local highestRank, highestSpellID = GetHighestRankForSpell(baseName)
	if not currentRank or not highestRank or not highestSpellID then
		return nil
	end
	if currentRank >= highestRank then
		return nil
	end
	if IsSpellBlacklisted(spellID) or IsSpellBlacklisted(highestSpellID) then
		return nil
	end
	return highestSpellID
end

local function UpgradeSavedSpellEntry(entry)
	if type(entry) ~= "table" then
		return false
	end
	local aType = entry.dataType or entry.actionType or entry.type
	local aVal = entry.data or entry.actionValue or entry.id
	if aType ~= "spell" then
		return false
	end
	local spellID = tonumber(aVal)
	local newId = ResolveHighestUpgradeSpellId(spellID)
	if not newId then
		return false
	end
	if entry.data ~= nil then
		entry.data = newId
	end
	if entry.actionValue ~= nil then
		entry.actionValue = newId
	end
	if entry.id ~= nil then
		entry.id = newId
	end
	if entry.name ~= nil then
		entry.name = FormatSpellCastName(newId) or entry.name
	end
	return true
end

local function SetExtraSpell(fb, newId)
	local EBS = Flux.EBS
	if EBS and EBS.Action and EBS.Action.SetAction then
		EBS.Action.SetAction(fb, "spell", newId)
		return true
	end
	if fb.SetAction then
		fb:SetAction("spell", newId)
		return true
	end
	return false
end

local function RankUpExtraButtonSystemSpells()
	local upgraded = 0
	local EBS = Flux.EBS
	local function walkLive(list)
		if type(list) ~= "table" then
			return
		end
		for i = 1, #list do
			local fb = list[i]
			if fb and fb.ActionType == "spell" then
				local spellID = tonumber(fb.SpellId or fb.ActionValue)
				local newId = ResolveHighestUpgradeSpellId(spellID)
				if newId and SetExtraSpell(fb, newId) then
					if type(fb.btnData) == "table" then
						UpgradeSavedSpellEntry(fb.btnData)
					end
					upgraded = upgraded + 1
				end
			end
		end
	end
	if EBS then
		walkLive(EBS.buttons)
		walkLive(EBS.badges)
	end

	local function walkFlatEntries(entries)
		if type(entries) ~= "table" then
			return
		end
		for _, entry in ipairs(entries) do
			if type(entry) == "table" and (entry.type == "button" or not entry.type
				or entry.dataType == "spell" or entry.actionType == "spell") then
				if UpgradeSavedSpellEntry(entry) then
					upgraded = upgraded + 1
				end
			end
		end
	end

	if _G._FluxUI_CharSavedVars and type(_G._FluxUI_CharSavedVars.ExtraButtonCategories) == "table" then
		walkFlatEntries(_G._FluxUI_CharSavedVars.ExtraButtonCategories.entries)
	end
	local db = _G.FluxUI_DB and _G.FluxUI_DB.ExtraButtonCategories
	if type(db) == "table" then
		if db.Account then
			walkFlatEntries(db.Account.entries)
		end
		if type(db.Class) == "table" then
			for _, classTbl in pairs(db.Class) do
				if type(classTbl) == "table" then
					walkFlatEntries(classTbl.entries)
				end
			end
		end
		if type(db.Realm) == "table" then
			for _, realmTbl in pairs(db.Realm) do
				if type(realmTbl) == "table" then
					walkFlatEntries(realmTbl.entries)
				end
			end
		end
	end

	if _G._FluxUI_CharSavedVars and type(_G._FluxUI_CharSavedVars.minimapExtraButtons) == "table" then
		for _, saved in pairs(_G._FluxUI_CharSavedVars.minimapExtraButtons) do
			if UpgradeSavedSpellEntry(saved) then
				upgraded = upgraded + 1
			end
		end
	end

	if _G.FluxNCUtilitySlotsDB and type(_G.FluxNCUtilitySlotsDB.slots) == "table" then
		local any = false
		for _, slotMap in pairs(_G.FluxNCUtilitySlotsDB.slots) do
			if type(slotMap) == "table" then
				for _, entry in pairs(slotMap) do
					if UpgradeSavedSpellEntry(entry) then
						upgraded = upgraded + 1
						any = true
					end
				end
			end
		end
		if any then
			local UM = _G.FluxNCUtilitySlotsManager
			if UM and UM.UpdateAllSlots then
				pcall(UM.UpdateAllSlots)
			end
		end
	end

	local DB = _G.FluxBindingDB3API
	local anyBind = false
	if DB and DB.All then
		for _, b in pairs(DB.All()) do
			if type(b) == "table" and type(b.action) == "table" and b.action.type == "spell" then
				local spellID = tonumber(b.action.id)
				local newId = ResolveHighestUpgradeSpellId(spellID)
				if newId then
					b.action.id = newId
					local attr = FormatSpellCastName(newId)
					if type(attr) == "string" then
						b.action.name = attr
					end
					upgraded = upgraded + 1
					anyBind = true
				end
			end
		end
	end
	if anyBind and _G.FluxBinding and _G.FluxBinding.RequestApplyAll then
		pcall(_G.FluxBinding.RequestApplyAll, "spellRankUp")
	end

	return upgraded
end

local function CollectStanceSpellIds(bucket, snap)
	if type(snap) ~= "table" or type(snap.stanceCustomSlots) ~= "table" then
		return
	end
	for i = 1, #snap.stanceCustomSlots do
		local entry = snap.stanceCustomSlots[i]
		if type(entry) == "table" and entry.type == "spell" then
			local id = tonumber(entry.id)
			if id and id > 0 then
				bucket[id] = true
			end
		end
	end
end

local function RankUpStanceCustomSpells()
	local Stance = Bars and Bars.Stance
	if not (Stance and Stance.GetSavedCustomSlots and Stance.ReplaceCustomSpellId) then
		return 0
	end
	local bucket = {}
	local live = Stance.GetSavedCustomSlots()
	for i = 1, #live do
		local entry = live[i]
		if type(entry) == "table" and entry.type == "spell" then
			local id = tonumber(entry.id)
			if id and id > 0 then
				bucket[id] = true
			end
		end
	end
	local R = _G.FluxRespec
	if R and R.GetProfileNames and R.GetProfile then
		local names = R.GetProfileNames()
		for i = 1, #names do
			local profile = R.GetProfile(names[i])
			CollectStanceSpellIds(bucket, profile and profile.bars)
		end
	end
	local Presets = R and R.RunePresets
	if Presets and Presets.GetPresetNames and Presets.GetPreset then
		local names = Presets.GetPresetNames()
		for i = 1, #names do
			local preset = Presets.GetPreset(names[i])
			local groups = preset and preset.barsByGroup
			if type(groups) == "table" then
				for _, bars in pairs(groups) do
					CollectStanceSpellIds(bucket, bars)
				end
			end
		end
	end

	local upgraded = 0
	local liveChanged = false
	local AB = R and R.ActionBars
	for oldId in pairs(bucket) do
		local newId = ResolveHighestUpgradeSpellId(oldId)
		if newId then
			local newName = FormatSpellCastName(newId)
			local didLive = Stance.ReplaceCustomSpellId(oldId, newId, newName)
			local didSaved = 0
			if AB and AB.RewriteSavedStanceSpellId then
				didSaved = AB.RewriteSavedStanceSpellId(oldId, newId, newName) or 0
			end
			if didLive or didSaved > 0 then
				upgraded = upgraded + 1
				liveChanged = liveChanged or didLive
			end
		end
	end
	if liveChanged then
		if Stance.RequestLayout then
			Stance.RequestLayout("rank")
		end
		if _G.FluxStanceBarOrderPanel_RequestRefresh then
			pcall(_G.FluxStanceBarOrderPanel_RequestRefresh)
		end
	end
	return upgraded
end

function SpellRank:RankUpAllSpells(silent)
	if not RankSupported() then
		return
	end
	rankSupported = true
	if InCombatLockdown and InCombatLockdown() then
		if not silent then
			print("|cff00ffff[FluxUI]|r Cannot rank up spells during combat.")
		end
		return
	end
	cacheDirty = true
	BuildSpellRankCache()

	local upgradedCount = 0
	for slot = 1, 120 do
		if HasAction and HasAction(slot) then
			local actionType, id = GetActionInfo(slot)
			if actionType == "spell" and id then
				local newId = ResolveHighestUpgradeSpellId(id)
				if newId then
					ClearCursor()
					if C_Spell and C_Spell.PickupSpell then
						C_Spell.PickupSpell(newId)
					else
						PickupSpell(newId)
					end
					PlaceAction(slot)
					ClearCursor()
					upgradedCount = upgradedCount + 1
				end
			end
		end
	end

	upgradedCount = upgradedCount + RankUpExtraButtonSystemSpells()
	upgradedCount = upgradedCount + RankUpStanceCustomSpells()
	After(0.2, UpdateAllButtonDesaturation)

	if upgradedCount > 0 then
		print(string.format("|cff00ffff[FluxUI]|r Upgraded %d spell(s) to highest rank", upgradedCount))
	elseif not silent then
		print("|cff00ffff[FluxUI]|r All spells are already at highest rank")
	end
end

-- ---------------------------------------------------------------------------
-- Spellbook UI
-- ---------------------------------------------------------------------------

local rankUpButton = nil
local autoRankUpCheckbox = nil

local function CreateRankUpButton()
	if not RankSupported() then
		return
	end
	if rankUpButton then
		return
	end
	local button = CreateFrame("Button", "FluxRankUpAllButton", UIParent, "UIPanelButtonTemplate")
	button:SetSize(80, 22)
	button:SetText("Rank Up All")
	local fontString = button:GetFontString()
	if fontString then
		fontString:SetFontObject("GameFontHighlightSmall")
	end
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnReceiveDrag", function()
		local cursorType, id, _, subSubType = GetCursorInfo()
		if cursorType == "spell" then
			local spellID = NormalizeSpellID(subSubType or id)
			if spellID then
				local baseName = GetSpellBaseName(spellID)
				local rank = GetSpellRank(spellID)
				local isNowBlacklisted = ToggleSpellBlacklist(spellID)
				local displayName = baseName or ("Spell " .. tostring(spellID))
				if rank then
					displayName = displayName .. " (Rank " .. rank .. ")"
				end
				if isNowBlacklisted then
					print(string.format("|cff00ffff[FluxUI]|r %s added to rank-up blacklist", displayName))
				else
					print(string.format("|cff00ffff[FluxUI]|r %s removed from rank-up blacklist", displayName))
				end
				ClearCursor()
			end
		end
	end)
	button:SetScript("OnClick", function()
		local cursorType, id, _, subSubType = GetCursorInfo()
		if cursorType == "spell" then
			local spellID = NormalizeSpellID(subSubType or id)
			if spellID then
				local baseName = GetSpellBaseName(spellID)
				local rank = GetSpellRank(spellID)
				local isNowBlacklisted = ToggleSpellBlacklist(spellID)
				local displayName = baseName or ("Spell " .. tostring(spellID))
				if rank then
					displayName = displayName .. " (Rank " .. rank .. ")"
				end
				if isNowBlacklisted then
					print(string.format("|cff00ffff[FluxUI]|r %s added to rank-up blacklist", displayName))
				else
					print(string.format("|cff00ffff[FluxUI]|r %s removed from rank-up blacklist", displayName))
				end
				ClearCursor()
				return
			end
		end
		SpellRank:RankUpAllSpells()
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Rank Up All Spells", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Upgrades all lower-ranked spells on action bars to their highest learned rank.", 1, 1, 1, true)
		GameTooltip:AddLine(" ", 1, 1, 1)
		GameTooltip:AddLine("Blacklist:", 1, 0.82, 0, true)
		GameTooltip:AddLine("Drag spells here to blacklist them from auto rank-up and 'Rank Up All'.", 1, 1, 1, true)
		GameTooltip:AddLine("Drag the same spell again to remove it from the blacklist.", 1, 1, 1, true)
		local blacklistText, blacklistCount = GetBlacklistDisplayText()
		if blacklistCount > 0 then
			GameTooltip:AddLine(" ", 1, 1, 1)
			GameTooltip:AddLine(string.format("Blacklisted (%d):", blacklistCount), 0.8, 0.8, 0.8, true)
			if string.len(blacklistText) > 60 then
				for spell in blacklistText:gmatch("([^,]+)") do
					GameTooltip:AddLine("  " .. spell:match("^%s*(.-)%s*$"), 0.7, 0.7, 0.7, true)
				end
			else
				GameTooltip:AddLine("  " .. blacklistText, 0.7, 0.7, 0.7, true)
			end
		end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	rankUpButton = button
	button:Hide()
end

local function CreateAutoRankUpCheckbox()
	if not RankSupported() then
		return
	end
	if autoRankUpCheckbox then
		return
	end
	local checkbox = CreateFrame("CheckButton", "FluxAutoRankUpCheckbox", UIParent, "UICheckButtonTemplate")
	checkbox:SetSize(20, 20)
	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
	label:SetText("Auto Rank Up")
	label:SetTextColor(1.0, 0.82, 0.0, 1)
	checkbox.label = label
	checkbox:SetHitRectInsets(-5, -label:GetStringWidth() - 10, -5, -5)
	checkbox:SetChecked(GetAutoRankUpEnabled())
	checkbox:SetScript("OnClick", function(self)
		SpellRank:SetAutoRankUpEnabled(self:GetChecked())
	end)
	checkbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Auto Rank Up", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Automatically upgrades spells on action bars when you learn a higher rank.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	checkbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	autoRankUpCheckbox = checkbox
	checkbox:Hide()
end

local fluxCreatedShowAllRanks = false

local function ClassHidesSpellRanks()
	local _, class = UnitClass("player")
	return class == "ROGUE" or class == "WARRIOR"
end

local function HideRankChrome()
	if rankUpButton then
		rankUpButton:Hide()
	end
	if autoRankUpCheckbox then
		autoRankUpCheckbox:Hide()
	end
	local Chrome = Flux.SpellBookChrome
	if Chrome and Chrome.HideRankChrome then
		Chrome.HideRankChrome()
	elseif fluxCreatedShowAllRanks then
		local checkbox = _G.ShowAllSpellRanksCheckbox or _G.ShowAllSpellRanksCheckBox
		if checkbox and checkbox._fluxCreatedShowAllRanks then
			checkbox:Hide()
		end
	end
end

local function RefreshBlizzardSpellBookRanks()
	local frame = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
	if frame and frame.UpdateDisplayedSpells then
		frame:UpdateDisplayedSpells(true, false)
		return
	end
	if SpellBookFrame then
		if SpellBookFrame.UpdateSpells then
			SpellBookFrame:UpdateSpells()
		end
		if SpellBookFrame.UpdatePages then
			SpellBookFrame:UpdatePages()
		elseif SpellBookFrame.Update then
			SpellBookFrame:Update()
		end
	end
end

local function CreateShowAllRanksCheckbox()
	local Chrome = Flux.SpellBookChrome
	if Chrome and Chrome.EnsureBlizzardShowAllRanks then
		Chrome.EnsureBlizzardShowAllRanks()
	end
	if not RankSupported() then
		return
	end
	if Chrome and Chrome.GetBlizzardShowAllRanksCheckbox and Chrome.GetBlizzardShowAllRanksCheckbox() then
		return
	end
	if Chrome and Chrome.ShouldCreateFluxShowAllRanks and not Chrome.ShouldCreateFluxShowAllRanks() then
		return
	end
	if _G.ShowAllSpellRanksCheckbox or _G.ShowAllSpellRanksCheckBox then
		local existing = _G.ShowAllSpellRanksCheckbox or _G.ShowAllSpellRanksCheckBox
		if existing._fluxCreatedShowAllRanks then
			fluxCreatedShowAllRanks = true
		end
		return
	end
	local checkbox = CreateFrame("CheckButton", "ShowAllSpellRanksCheckbox", UIParent, "UICheckButtonTemplate")
	checkbox._fluxCreatedShowAllRanks = true
	checkbox:SetSize(20, 20)
	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
	label:SetText(SHOW_ALL_SPELL_RANKS or "Show All Spell Ranks")
	label:SetTextColor(1.0, 0.82, 0.0, 1)
	checkbox.label = label
	checkbox:SetHitRectInsets(-5, -label:GetStringWidth() - 10, -5, -5)
	if GetCVarBool then
		checkbox:SetChecked(GetCVarBool("ShowAllSpellRanks"))
	end
	checkbox:SetScript("OnClick", function(self)
		if SetCVar then
			SetCVar("ShowAllSpellRanks", self:GetChecked() and "1" or "0")
		end
		RefreshBlizzardSpellBookRanks()
		if SOUNDKIT and PlaySound then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end
	end)
	checkbox:SetScript("OnEnter", function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(SHOW_ALL_SPELL_RANKS or "Show All Spell Ranks", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Show every learned rank in the spellbook. Unchecked keeps only the highest rank of each spell.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	checkbox:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	fluxCreatedShowAllRanks = true
	checkbox:Hide()
	if ClassHidesSpellRanks() then
		checkbox:Hide()
	end
end

local function PositionSpellBookUI()
	if not RankSupported() then
		HideRankChrome()
		local Chrome = Flux.SpellBookChrome
		if Chrome and Chrome.Layout then
			Chrome.Layout({ showRank = false })
		end
		return
	end
	local Chrome = Flux.SpellBookChrome
	if Chrome and Chrome.Layout then
		local showAll = Chrome.GetFluxShowAllRanksCheckbox and Chrome.GetFluxShowAllRanksCheckbox()
		if showAll and ClassHidesSpellRanks() then
			showAll:Hide()
			showAll = false
		end
		Chrome.Layout({
			autoRank = autoRankUpCheckbox,
			rankUp = rankUpButton,
			showAll = showAll or nil,
			showRank = true,
		})
	end
end

local function PatchSpellBookRankUI()
	if not RankSupported() then
		return
	end
	local mixin = _G.SpellBookFrameMixin
	if mixin and not mixin._fluxRankPatched then
		mixin._fluxRankPatched = true
		-- Do not replace SetupAllRanksCheckbox: Forever's settings gear owns
		-- Blizzard Show All Spell Ranks. EnsureBlizzardShowAllRanks fills the
		-- missing SHOW_ALL_SPELL_RANKS string and CVar.
		if mixin.ShouldDisplaySpellBookItem then
			local origFilter = mixin.ShouldDisplaySpellBookItem
			function mixin:ShouldDisplaySpellBookItem(isKioskEnabled, isHidingPassives, isHidingLowRank, isHidingFlyouts, slotIndex, spellBank)
				local lowRankApi = C_SpellBook and C_SpellBook.IsSpellBookItemLowRank
				local show = origFilter(self, isKioskEnabled, isHidingPassives, isHidingLowRank and lowRankApi, isHidingFlyouts, slotIndex, spellBank)
				if not show then
					return false
				end
				if isHidingLowRank and not lowRankApi then
					local info = C_SpellBook and C_SpellBook.GetSpellBookItemInfo and C_SpellBook.GetSpellBookItemInfo(slotIndex, spellBank)
					if info and info.spellID and IsLowerRank(info.spellID) then
						return false
					end
				end
				return true
			end
		end
	end
	local itemMixin = _G.SpellBookItemMixin
	if itemMixin and not itemMixin._fluxRankPatched then
		itemMixin._fluxRankPatched = true
		if itemMixin.UpdateVisuals then
			hooksecurefunc(itemMixin, "UpdateVisuals", function(self)
				if not RankSupported() then
					return
				end
				if not self.HasValidData or not self:HasValidData() then
					return
				end
				local info = self.spellBookItemInfo
				if not info then
					return
				end
				local sub = info.subName
				if type(sub) == "string" and sub ~= "" then
					return
				end
				local sid = info.spellID
				if not sid then
					return
				end
				local rankSub
				if Flux.Spell and Flux.Spell.GetSubtext then
					rankSub = Flux.Spell.GetSubtext(sid)
				elseif C_Spell and C_Spell.GetSpellSubtext then
					rankSub = C_Spell.GetSpellSubtext(sid)
				end
				if type(rankSub) == "string" and rankSub ~= "" and self.UpdateSubName then
					self:UpdateSubName(rankSub)
					if self.UpdateTextContainer then
						self:UpdateTextContainer()
					end
				end
			end)
		end
	end
end

local function OnSpellbookShow()
	if not RankSupported() then
		HideRankChrome()
		local Chrome = Flux.SpellBookChrome
		if Chrome and Chrome.Layout then
			Chrome.Layout({ showRank = false })
		end
		return
	end
	rankSupported = true
	PatchSpellBookRankUI()
	CreateShowAllRanksCheckbox()
	CreateRankUpButton()
	CreateAutoRankUpCheckbox()
	PositionSpellBookUI()
end

local function OnSpellbookHide()
	HideRankChrome()
end

-- ---------------------------------------------------------------------------
-- Auto rank-up
-- ---------------------------------------------------------------------------

local autoRankDebounceSeq = 0
local slotDesatSlotChangeToken = 0

local function ScheduleDebouncedAutoRankUpAll()
	if not RankSupported() or not GetAutoRankUpEnabled() then
		return
	end
	rankSupported = true
	autoRankDebounceSeq = autoRankDebounceSeq + 1
	local seq = autoRankDebounceSeq
	After(0.45, function()
		if seq ~= autoRankDebounceSeq then
			return
		end
		if not GetAutoRankUpEnabled() or (InCombatLockdown and InCombatLockdown()) then
			return
		end
		cacheDirty = true
		BuildSpellRankCache()
		SpellRank:RankUpAllSpells(true)
	end)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function SpellRank:IsRankFeaturesSupported()
	return RankSupported()
end

function SpellRank:IsLowerRankSpell(spellId)
	if not RankSupported() then
		return false
	end
	return IsLowerRank(spellId) and true or false
end

function SpellRank:ApplyRankDesaturation(frame, spellId)
	return ApplyRankDesaturation(self, frame, spellId)
end

local function HostsForColumn(col)
	local rec = Bars.GetHost and Bars.GetHost(col)
	if not rec then
		return nil
	end
	return rec
end

local function VisibleBadges(host)
	local BH = Bars.BadgeHost or _G.FluxBadgeHost
	local widget = host and (host.widget or host.Widget)
	if BH and BH.GetVisibleBadgesForButton and widget then
		return BH.GetVisibleBadgesForButton(widget)
	end
	return nil
end

function SpellRank:RefreshColumnSurfaces(lab, badges, skipUsable)
	if lab then
		if lab.WIcon or lab.slot or lab.widget then
			UpdateHostDesaturation(lab)
		else
			UpdateFluxButtonDesaturation(lab)
		end
		if not skipUsable then
			if lab.UpdateUsable then
				pcall(lab.UpdateUsable, lab)
			elseif Bars.Paint and Bars.Paint.UpdateUsable and lab.WIcon then
				Bars.Paint.UpdateUsable(lab)
			end
		end
	end
	if type(badges) == "table" then
		for i = 1, #badges do
			local b = badges[i]
			if b then
				UpdateFluxButtonDesaturation(b)
				if not skipUsable and b.UpdateUsable then
					pcall(b.UpdateUsable, b)
				elseif not skipUsable and Flux.EBS and Flux.EBS.Paint and Flux.EBS.Paint.UpdateUsable then
					Flux.EBS.Paint.UpdateUsable(b)
				end
			end
		end
	end
end

function SpellRank:RefreshColumnSurfacesPaging(lab, badges)
	return self:RefreshColumnSurfaces(lab, badges, true)
end

function SpellRank:RefreshColumnAllRows(col)
	if type(col) ~= "number" then
		return
	end
	local rec = HostsForColumn(col)
	if not rec then
		return
	end
	local function touchHost(host)
		if not host then
			return
		end
		UpdateHostDesaturation(host)
		if Bars.Paint and Bars.Paint.UpdateUsable then
			Bars.Paint.UpdateUsable(host)
		end
		local badges = VisibleBadges(host)
		if type(badges) == "table" then
			for i = 1, #badges do
				UpdateFluxButtonDesaturation(badges[i])
			end
		end
	end
	touchHost(rec.main)
	touchHost(rec.sec)
	touchHost(rec.tert)
end

function SpellRank:RefreshColumnUsable(col)
	if type(col) ~= "number" then
		return
	end
	local rec = HostsForColumn(col)
	if not rec then
		return
	end
	local function touchHost(host)
		if not host then
			return
		end
		if Bars.Paint and Bars.Paint.UpdateUsable then
			Bars.Paint.UpdateUsable(host)
		end
		local badges = VisibleBadges(host)
		if type(badges) == "table" then
			for i = 1, #badges do
				local b = badges[i]
				if b then
					if Flux.EBS and Flux.EBS.Paint and Flux.EBS.Paint.UpdateUsable then
						Flux.EBS.Paint.UpdateUsable(b)
					elseif b.UpdateUsable then
						pcall(b.UpdateUsable, b)
					end
				end
			end
		end
	end
	touchHost(rec.main)
	touchHost(rec.sec)
	touchHost(rec.tert)
end

function SpellRank:ClearHostRankState(lab, skipUsable)
	if not lab then
		return
	end
	lab._fluxAspectDisplaySpellId = nil
	if lab.Widget then
		lab.Widget._fluxAspectDisplaySpellId = nil
	end
	if lab.widget then
		lab.widget._fluxAspectDisplaySpellId = nil
	end
	if skipUsable then
		return
	end
	SetRankFlag(lab, false)
	UpdateHostDesaturation(lab)
end

function SpellRank:ReassertDesaturation(frame)
	if not frame then
		return
	end
	if frame.PlaceholderTexture and not frame.IsWispLockPlaceholder then
		local icon = GetButtonIcon(frame)
		if icon then
			icon:SetDesaturated(true)
			if icon.SetVertexColor then
				icon:SetVertexColor(0.25, 0.25, 0.25)
			end
		end
		return
	end
	local key = frame._fluxBadgeKey or (frame.Widget and frame.Widget._fluxBadgeKey)
	if type(key) == "string" and key:sub(1, 6) == "extra:" then
		SetRankFlag(frame, false)
		local icon = GetButtonIcon(frame)
		if icon then
			icon:SetDesaturated(false)
		end
		return
	end
	local icon = GetButtonIcon(frame)
	if not icon then
		return
	end
	local flag = frame._fluxRankDesaturated
	if flag == nil and frame.Widget then
		flag = frame.Widget._fluxRankDesaturated
	end
	if flag == nil then
		if frame.WIcon or frame.SpellId or frame._fluxIsActionBarBadge then
			UpdateFluxButtonDesaturation(frame)
		else
			UpdateHostDesaturation(frame)
		end
		return
	end
	icon:SetDesaturated(flag and true or false)
end

function SpellRank:GetAutoRankUpEnabled()
	if not RankSupported() then
		return false
	end
	return GetAutoRankUpEnabled()
end

function SpellRank:SetAutoRankUpEnabled(enabled)
	if not RankSupported() then
		return
	end
	SetAutoRankUpEnabled(enabled)
	if enabled then
		After(0, function()
			if not GetAutoRankUpEnabled() or (InCombatLockdown and InCombatLockdown()) then
				return
			end
			cacheDirty = true
			BuildSpellRankCache()
			SpellRank:RankUpAllSpells(true)
		end)
	end
	self:RefreshSpellBookRankUI()
	local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
	if ACR then
		ACR:NotifyChange("FluxUI")
	end
end

function SpellRank:GetBlacklistSpellIDs()
	EnsureDB()
	local bl = _FluxUI_CharSavedVars.spellRankManager.blacklist
	local fix = {}
	for key, v in pairs(bl) do
		if v and type(key) == "string" then
			local id = tonumber(key)
			if id and id > 0 then
				fix[#fix + 1] = key
			end
		end
	end
	for i = 1, #fix do
		local key = fix[i]
		if bl[key] then
			local id = tonumber(key)
			if id and id > 0 then
				bl[id] = true
				bl[key] = nil
			end
		end
	end
	local out = {}
	for spellID, v in pairs(bl) do
		if v then
			local id = type(spellID) == "number" and spellID or tonumber(spellID)
			if id and id > 0 then
				out[#out + 1] = id
			end
		end
	end
	table.sort(out)
	return out
end

function SpellRank:ToggleSpellBlacklist(spellID)
	if not RankSupported() then
		return false
	end
	return ToggleSpellBlacklist(spellID)
end

function SpellRank:ClearSpellFromBlacklist(spellID)
	if not RankSupported() then
		return
	end
	local id = NormalizeSpellID(spellID)
	if not id then
		return
	end
	EnsureDB()
	if not _FluxUI_CharSavedVars.spellRankManager.blacklist[id] then
		return
	end
	_FluxUI_CharSavedVars.spellRankManager.blacklist[id] = nil
	self:RefreshSpellBookRankUI()
	local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
	if ACR then
		ACR:NotifyChange("FluxUI")
	end
end

function SpellRank:SetSpellBlacklistPanelRefreshHandler(fn)
	spellBlacklistPanelRefresh = fn
end

function SpellRank:NotifySpellBlacklistPanelRefresh()
	notifySpellBlacklistPanel()
end

function SpellRank:RefreshSpellBookRankUI()
	if not RankSupported() then
		HideRankChrome()
		return
	end
	if autoRankUpCheckbox then
		autoRankUpCheckbox:SetChecked(GetAutoRankUpEnabled())
	end
	PositionSpellBookUI()
	notifySpellBlacklistPanel()
end

function SpellRank:RefreshAfterActionbarsScopedStorageChange()
	if not RankSupported() then
		return
	end
	cacheDirty = true
	BuildSpellRankCache()
	UpdateAllButtonDesaturation()
	self:RefreshSpellBookRankUI()
end

function SpellRank.RefreshAll()
	UpdateAllButtonDesaturation()
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

local lastUsableDesatRefresh = 0
local USABLE_DESAT_THROTTLE = 0.05
local loginRankUpDone = false
local spellbookHooked = false

local function RequestDesatRefreshFromUsable()
	if not RankSupported() then
		return
	end
	local t = GetTime and GetTime() or 0
	if t - lastUsableDesatRefresh < USABLE_DESAT_THROTTLE then
		return
	end
	lastUsableDesatRefresh = t
	UpdateAllButtonDesaturation()
end

local function BindSpellBookUI()
	if not RankSupported() then
		return
	end
	if spellbookHooked then
		return
	end
	spellbookHooked = true
	-- Forever HideUIPanel fires spellbook hide from the secure close. An
	-- OnUpdate edge sees the change after that execution has finished.
	local client = Flux.Client
	if client and (client.isCamelot or client.isForever) then
		local was = false
		if SpellBookFrame and SpellBookFrame.IsShown and SpellBookFrame:IsShown() then
			was = true
		end
		local modern = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
		if modern and modern.IsShown and modern:IsShown() then
			was = true
		end
		if was then
			OnSpellbookShow()
		end
		local watch = CreateFrame("Frame")
		watch:SetScript("OnUpdate", function()
			local page = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
			local shown = (SpellBookFrame and SpellBookFrame.IsShown and SpellBookFrame:IsShown())
				or (page and page.IsShown and page:IsShown())
			shown = shown and true or false
			if shown == was then
				return
			end
			was = shown
			if shown then
				OnSpellbookShow()
			else
				OnSpellbookHide()
			end
		end)
		return
	end
	if EventRegistry and EventRegistry.RegisterCallback then
		pcall(EventRegistry.RegisterCallback, EventRegistry, "PlayerSpellsFrame.SpellBookFrame.Show", OnSpellbookShow)
		pcall(EventRegistry.RegisterCallback, EventRegistry, "PlayerSpellsFrame.SpellBookFrame.Hide", OnSpellbookHide)
	end
	if SpellBookFrame then
		if SpellBookFrame.HookScript then
			SpellBookFrame:HookScript("OnShow", OnSpellbookShow)
			SpellBookFrame:HookScript("OnHide", OnSpellbookHide)
		end
		if SpellBookFrame.IsShown and SpellBookFrame:IsShown() then
			OnSpellbookShow()
		end
	end
	local modern = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
	if modern and modern.IsShown and modern:IsShown() then
		OnSpellbookShow()
	end
end

Flux.AfterLoad(function()
	EnsureDB()
	if not RankSupported() then
		HideRankChrome()
		return
	end
	local Chrome = Flux.SpellBookChrome
	if Chrome and Chrome.EnsureBlizzardShowAllRanks then
		Chrome.EnsureBlizzardShowAllRanks()
	end
	rankSupported = true
	cacheDirty = true
	BuildSpellRankCache()
	After(0, UpdateAllButtonDesaturation)
	PatchSpellBookRankUI()
	BindSpellBookUI()
end)

Flux.AfterLogin(function()
	EnsureDB()
	if not RankSupported() then
		HideRankChrome()
		return
	end
	local Chrome = Flux.SpellBookChrome
	if Chrome and Chrome.EnsureBlizzardShowAllRanks then
		Chrome.EnsureBlizzardShowAllRanks()
	end
	rankSupported = true
	cacheDirty = true
	BuildSpellRankCache()
	After(0, UpdateAllButtonDesaturation)
	PatchSpellBookRankUI()
	BindSpellBookUI()
end)

local Ev = Flux.Events
if Ev and Ev.Register then
	Ev.Register("ADDON_LOADED", function(_, loaded)
		if loaded ~= "Blizzard_PlayerSpells" then
			return
		end
		After(0, function()
			if not RankSupported() then
				HideRankChrome()
				local Chrome = Flux.SpellBookChrome
				if Chrome and Chrome.Layout then
					Chrome.Layout({ showRank = false })
				end
				return
			end
			PatchSpellBookRankUI()
			BindSpellBookUI()
			local spellBookFrame = (PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame) or SpellBookFrame
			local isShown = spellBookFrame and ((PlayerSpellsFrame and PlayerSpellsFrame:IsShown()) or (SpellBookFrame and SpellBookFrame:IsShown()))
			if isShown then
				OnSpellbookShow()
			end
		end)
	end)

	Ev.Register("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
		if not RankSupported() then
			return
		end
		rankSupported = true
		EnsureDB()
		cacheDirty = true
		BuildSpellRankCache()
		After(0, UpdateAllButtonDesaturation)
		if GetAutoRankUpEnabled() and (isInitialLogin or isReloadingUi) and not loginRankUpDone then
			loginRankUpDone = true
			After(0, function()
				if not GetAutoRankUpEnabled() then
					return
				end
				if InCombatLockdown and InCombatLockdown() then
					ScheduleDebouncedAutoRankUpAll()
					return
				end
				SpellRank:RankUpAllSpells(true)
			end)
		end
		BindSpellBookUI()
	end)

	local function OnSpellbookChange()
		if not RankSupported() then
			return
		end
		rankSupported = true
		cacheDirty = true
		if GetAutoRankUpEnabled() then
			ScheduleDebouncedAutoRankUpAll()
		end
		After(0.5, UpdateAllButtonDesaturation)
	end

	Ev.Register("SPELLS_CHANGED", OnSpellbookChange)
	Ev.Register("LEARNED_SPELL_IN_TAB", OnSpellbookChange)
	Ev.Register("LEARNED_SPELL_IN_SKILL_LINE", OnSpellbookChange)
	Ev.Register("PLAYER_TALENT_UPDATE", OnSpellbookChange)
	Ev.Register("ACTIVE_TALENT_GROUP_CHANGED", OnSpellbookChange)
	Ev.Register("PLAYER_SPECIALIZATION_CHANGED", OnSpellbookChange)
	if C_Engraving then
		Ev.Register("PLAYER_EQUIPMENT_CHANGED", OnSpellbookChange)
	end

	Ev.Register("ACTIONBAR_SLOT_CHANGED", function(_, slotNum)
		if not RankSupported() then
			return
		end
		if IsFormStorm() then
			return
		end
		slotNum = tonumber(slotNum)
		if slotNum and slotNum > 0 then
			local peek = _G.FluxActionBarPeekSlotOccupancyChanged
			if peek and not peek(slotNum) then
				return
			end
		end
		slotDesatSlotChangeToken = slotDesatSlotChangeToken + 1
		local tok = slotDesatSlotChangeToken
		After(0.25, function()
			if tok == slotDesatSlotChangeToken then
				UpdateAllButtonDesaturation()
			end
		end)
	end)
end

if _G.FluxSpellRankRefreshOnUsable == true and Ev and Ev.Register then
	Ev.Register("ACTIONBAR_UPDATE_USABLE", RequestDesatRefreshFromUsable)
	Ev.Register("SPELL_UPDATE_USABLE", RequestDesatRefreshFromUsable)
end

_G.FluxSpellRankManager = SpellRank
_G.FluxSpellRankManagerModule = SpellRank
FluxSpellRankManagerModule = SpellRank

