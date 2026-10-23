-- Live / Forever / Cata+ stats pane: ilvl X.Y, short Crit/Haste, Info Frame pins.
-- Live: CharacterStatsPane.statsFramePool.
-- Forever Camelot: visible rows live in CharacterStatsPaneScrollBox (pool is scratch).
local _, ns = ...
local module = ns.CharacterStats
if not (module and module.useRetailPaneHooks) then
	return
end

_G.FluxCSC_RetailPanelSkipped = true

local ilvlHookDone = false
local critHasteLabelHookDone = false
local updateStatsHookDone = false
local scrollBoxHookDone = false
local paperDollShowHooked = false
local foreverRowInitHooked = false

-- PAPERDOLL_STATINFO keys on Forever ScrollBox rows → Info Frame STAT_REGISTRY.
local FOREVER_STAT_TO_KEY = {
	HEALTH = "health",
	POWER = "power",
	ALTERNATEMANA = "power",
	ITEMLEVEL = "itemLevel",
	MOVESPEED = "speed",
	STRENGTH = "strength",
	AGILITY = "agility",
	INTELLECT = "intellect",
	STAMINA = "stamina",
	SPIRIT = "spirit",
	CRITCHANCE = "crit",
	HASTE = "haste",
	MASTERY = "mastery",
	VERSATILITY = "versatility",
	LIFESTEAL = "leech",
	AVOIDANCE = "avoidance",
	SPEED = "speed",
	ARMORPEN = "meleeArmorPenetration",
	ATTACK_DAMAGE = "weaponDamage",
	ATTACK_AP = "attackPower",
	RANGED_ATTACK_AP = "rangedAttackPower",
	ATTACK_ATTACKSPEED = "weaponSpeed",
	MAINHAND_DAMAGE = "weaponDamage",
	OFFHAND_DAMAGE = "weaponDamage",
	RANGED_DAMAGE = "rangedWeaponDamage",
	EXPERTISE = "expertise",
	HITCHANCE = "meleeHit",
	HITCHANCE_MELEE = "meleeHit",
	HITCHANCE_RANGED = "rangedHit",
	HITCHANCE_SPELL = "spellHit",
	SPELLPOWER = "spellPower",
	SPELL_POWER = "spellPower",
	SPELLDAMAGE = "spellPower",
	SPELL_DAMAGE = "spellPower",
	SPELLHEALING = "healPower",
	SPELL_HEALING = "healPower",
	MANAREGEN = "mp5",
	SPELLPENETRATION = "spellPenetration",
	DEFENSE = "defense",
	ARMOR = "armor",
	DODGE = "dodge",
	PARRY = "parry",
	BLOCK = "block",
}

do
	local info = rawget(_G, "FluxInfoFrame")
	if info then
		info._foreverPaperDollStatToKey = FOREVER_STAT_TO_KEY
	end
end

local function NotifyInfoPins()
	local info = rawget(_G, "FluxInfoFrame")
	if info and not info._foreverPaperDollStatToKey then
		info._foreverPaperDollStatToKey = FOREVER_STAT_TO_KEY
	end
	if info and info.RefreshRetailPinIndicators then
		info.RefreshRetailPinIndicators()
	elseif info and info.InstallCharacterInfoPinHooks then
		info.InstallCharacterInfoPinHooks()
	end
end

local function IsPetStatsAncestry(frame)
	local pet = rawget(_G, "CharacterStatsPanePetScrollBox")
	if not pet or not frame then
		return false
	end
	local p = frame
	local guard = 0
	while p and guard < 16 do
		if p == pet then
			return true
		end
		p = p.GetParent and p:GetParent()
		guard = guard + 1
	end
	return false
end

local function CategoriesIncludeStat(statName)
	local cats = rawget(_G, "PAPERDOLL_STATCATEGORIES")
	if type(cats) ~= "table" or type(statName) ~= "string" then
		return false
	end
	for _, cat in pairs(cats) do
		local stats = cat and cat.stats
		if type(stats) == "table" then
			for _, entry in pairs(stats) do
				if type(entry) == "table" and entry.stat == statName then
					return true
				end
			end
		end
	end
	return false
end

local function ApplySpeedLabel(statFrame)
	if not statFrame or not statFrame.Label or not statFrame.Label.SetText then
		return
	end
	local fmt = type(_G.STAT_FORMAT) == "string" and _G.STAT_FORMAT or "%s"
	statFrame.Label:SetText(format(fmt, "Speed"))
end

local function HookForeverVisibleRow(statFrame, elementData)
	if not statFrame or IsPetStatsAncestry(statFrame) then
		return
	end
	if elementData and elementData.isHeader then
		return
	end
	-- Rating "Speed" and "Movement Speed" are one stat. Keep the movement row, labeled Speed.
	if elementData and elementData.name == "SPEED" and CategoriesIncludeStat("MOVESPEED") then
		statFrame:Hide()
		return
	end
	local info = rawget(_G, "FluxInfoFrame")
	if not info then
		return
	end
	if not info._foreverPaperDollStatToKey then
		info._foreverPaperDollStatToKey = FOREVER_STAT_TO_KEY
	end
	local key
	if elementData and type(elementData.name) == "string" then
		key = FOREVER_STAT_TO_KEY[elementData.name]
	end
	if info.HookForeverScrollBoxStatFrame then
		info.HookForeverScrollBoxStatFrame(statFrame, key)
	elseif key and info.HookRetailPaperDollPoolStatFrame then
		info.HookRetailPaperDollPoolStatFrame(statFrame, key)
	end
	if elementData and (elementData.name == "MOVESPEED" or elementData.name == "SPEED") then
		ApplySpeedLabel(statFrame)
	end
	if key and info.RememberPinnedStatValue then
		local nv = statFrame.numericValue
		if nv == nil and elementData then
			nv = elementData.numericValue
		end
		info.RememberPinnedStatValue(key, nv, statFrame)
	end
end

local function InstallPaperDollItemLevelDecimalHook()
	if ilvlHookDone or type(hooksecurefunc) ~= "function" then
		return
	end
	if type(_G.PaperDollFrame_SetItemLevel) ~= "function" then
		return
	end
	ilvlHookDone = true

	hooksecurefunc("PaperDollFrame_SetItemLevel", function(statFrame, unit)
		if unit == "player" and statFrame and statFrame.Value then
			local info = rawget(_G, "FluxInfoFrame")
			if info and info.HookRetailPaperDollStatFrame then
				info.HookRetailPaperDollStatFrame(statFrame)
			end
		end
		if unit ~= "player" or not statFrame or not statFrame.Value then
			return
		end
		if type(GetAverageItemLevel) ~= "function" then
			return
		end
		local _, avgEquipped = GetAverageItemLevel()
		if type(avgEquipped) ~= "number" then
			return
		end
		local minIlvl = 0
		if C_PaperDollInfo and C_PaperDollInfo.GetMinItemLevel then
			local ok, m = pcall(C_PaperDollInfo.GetMinItemLevel)
			if ok and type(m) == "number" then
				minIlvl = m
			end
		end
		local display = math.max(minIlvl, avgEquipped)
		if statFrame.Value.SetFormattedText then
			statFrame.Value:SetFormattedText("%.1f", display)
		end
		statFrame.numericValue = display
	end)
end

local function InstallPaperDollCritHasteShortLabels()
	if critHasteLabelHookDone or type(hooksecurefunc) ~= "function" then
		return
	end
	if type(_G.PaperDollFrame_SetCritChance) ~= "function" or type(_G.PaperDollFrame_SetHaste) ~= "function" then
		return
	end
	critHasteLabelHookDone = true

	local function applyShortLabel(statFrame)
		if not statFrame or not statFrame.Label or not statFrame.Label.SetText then
			return
		end
		local fmt = type(_G.STAT_FORMAT) == "string" and _G.STAT_FORMAT or "%s"
		return fmt
	end

	hooksecurefunc("PaperDollFrame_SetCritChance", function(statFrame, unit)
		if unit ~= "player" then
			return
		end
		local fmt = applyShortLabel(statFrame)
		if fmt then
			statFrame.Label:SetText(format(fmt, "Crit"))
		end
		local info = rawget(_G, "FluxInfoFrame")
		if info and info.HookRetailPaperDollPoolStatFrame and statFrame then
			info.HookRetailPaperDollPoolStatFrame(statFrame, "crit")
		end
	end)

	hooksecurefunc("PaperDollFrame_SetHaste", function(statFrame, unit)
		if unit ~= "player" then
			return
		end
		local fmt = applyShortLabel(statFrame)
		if fmt then
			statFrame.Label:SetText(format(fmt, "Haste"))
		end
		local info = rawget(_G, "FluxInfoFrame")
		if info and info.HookRetailPaperDollPoolStatFrame and statFrame then
			info.HookRetailPaperDollPoolStatFrame(statFrame, "haste")
		end
	end)

	if type(_G.PaperDollFrame_SetMovementSpeed) == "function" then
		hooksecurefunc("PaperDollFrame_SetMovementSpeed", function(statFrame, unit)
			if unit and unit ~= "player" then
				return
			end
			ApplySpeedLabel(statFrame)
			local info = rawget(_G, "FluxInfoFrame")
			if info and info.HookRetailPaperDollPoolStatFrame and statFrame then
				info.HookRetailPaperDollPoolStatFrame(statFrame, "speed")
			end
		end)
	end
	if type(_G.PaperDollFrame_SetSpeed) == "function" then
		hooksecurefunc("PaperDollFrame_SetSpeed", function(statFrame, unit)
			if unit and unit ~= "player" then
				return
			end
			if CategoriesIncludeStat("MOVESPEED") then
				statFrame:Hide()
				return
			end
			ApplySpeedLabel(statFrame)
			local info = rawget(_G, "FluxInfoFrame")
			if info and info.HookRetailPaperDollPoolStatFrame and statFrame then
				info.HookRetailPaperDollPoolStatFrame(statFrame, "speed")
			end
		end)
	end
end

local function InstallUpdateStatsHook()
	if updateStatsHookDone or type(hooksecurefunc) ~= "function" then
		return
	end
	if type(_G.PaperDollFrame_UpdateStats) ~= "function" then
		return
	end
	updateStatsHookDone = true
	hooksecurefunc("PaperDollFrame_UpdateStats", function()
		if C_Timer and C_Timer.After then
			C_Timer.After(0, NotifyInfoPins)
		else
			NotifyInfoPins()
		end
	end)
end

local function InstallForeverScrollBoxHook()
	if scrollBoxHookDone then
		return
	end
	local box = rawget(_G, "CharacterStatsPaneScrollBox")
	if not box or type(box.UpdateStats) ~= "function" or type(hooksecurefunc) ~= "function" then
		return
	end
	scrollBoxHookDone = true
	hooksecurefunc(box, "UpdateStats", function(self)
		if self == rawget(_G, "CharacterStatsPanePetScrollBox") then
			return
		end
		if C_Timer and C_Timer.After then
			C_Timer.After(0, NotifyInfoPins)
		else
			NotifyInfoPins()
		end
	end)
end

local function InstallForeverRowInitHook()
	if foreverRowInitHooked or type(hooksecurefunc) ~= "function" then
		return
	end
	local mixin = rawget(_G, "CharacterStatFrameScrollBoxBaseElementMixin")
	if not mixin or type(mixin.Init) ~= "function" then
		return
	end
	foreverRowInitHooked = true
	hooksecurefunc(mixin, "Init", function(self, elementData)
		HookForeverVisibleRow(self, elementData)
	end)
end

local function InstallPaperDollShowHook()
	local pd = rawget(_G, "PaperDollFrame")
	if paperDollShowHooked or not pd or not pd.HookScript then
		return
	end
	paperDollShowHooked = true
	pd:HookScript("OnShow", function()
		if C_Timer and C_Timer.After then
			C_Timer.After(0.1, NotifyInfoPins)
		else
			NotifyInfoPins()
		end
	end)
end

local SPELL_SCHOOL_ORDER = { 2, 3, 4, 5, 6, 7 }
local SPELL_SCHOOL_NAME = {
	[2] = "Holy",
	[3] = "Fire",
	[4] = "Nature",
	[5] = "Frost",
	[6] = "Shadow",
	[7] = "Arcane",
}
local SPELL_SCHOOL_COLOR = {
	[2] = "ffff99",
	[3] = "ff8000",
	[4] = "3A9E3A",
	[5] = "66ccff",
	[6] = "cc66ff",
	[7] = "99ccff",
}
local SPELL_RELEVANT_BY_CLASS = {
	[11] = { [4] = true, [7] = true },
	[5] = { [2] = true, [6] = true },
	[9] = { [3] = true, [6] = true },
	[8] = { [3] = true, [5] = true, [7] = true },
	[7] = { [3] = true, [4] = true, [5] = true },
	[2] = { [2] = true },
	[3] = { [4] = true },
}

local function IsForeverCharacterPane()
	local client = ns.Flux and ns.Flux.Client
	if client and (client.isCamelot or client.isForever) then
		return true
	end
	local api = rawget(_G, "FLUX_API")
	return api and (api.isCamelot or api.isForever) and true or false
end

local function AnniversarySpellNumbers()
	local info = rawget(_G, "FluxInfoFrame")
	if info and info._CamelotSpellBonus then
		return info._CamelotSpellBonus()
	end
	local bonus, maxD, heal = {}, 0, 0
	if type(GetSpellBonusDamage) == "function" then
		for i = 2, 7 do
			local v = tonumber(GetSpellBonusDamage(i)) or 0
			bonus[i] = v
			if v > maxD then
				maxD = v
			end
		end
	end
	if type(GetSpellBonusHealing) == "function" then
		heal = tonumber(GetSpellBonusHealing()) or 0
	end
	return maxD, heal, 0, bonus
end

local function AddAnniversarySpellPowerLines(tooltip)
	local maxD, heal, _, bonus = AnniversarySpellNumbers()
	local _, _, classId = UnitClass("player")
	local relevant = SPELL_RELEVANT_BY_CLASS[classId]
	local topD = 0
	if relevant then
		for _, school in ipairs(SPELL_SCHOOL_ORDER) do
			if relevant[school] and (bonus[school] or 0) > topD then
				topD = bonus[school]
			end
		end
	else
		topD = maxD or 0
		relevant = { [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true }
	end
	tooltip:AddLine("Power", 1, 1, 1)
	tooltip:AddLine(string.format("Spell Power: |cffffff00%d|r", topD))
	tooltip:AddLine(string.format("Healing: |cff20ff20%d|r", heal or 0))
	tooltip:AddLine(" ")
	local grouped, order = {}, {}
	for _, school in ipairs(SPELL_SCHOOL_ORDER) do
		if relevant[school] and bonus[school] ~= nil then
			local key = tostring(bonus[school])
			if not grouped[key] then
				grouped[key] = { value = bonus[school], schools = {} }
				order[#order + 1] = key
			end
			grouped[key].schools[#grouped[key].schools + 1] = school
		end
	end
	for i = 1, #order do
		local entry = grouped[order[i]]
		local names = {}
		for s = 1, #entry.schools do
			local school = entry.schools[s]
			local hex = SPELL_SCHOOL_COLOR[school] or "ffffff"
			names[#names + 1] = string.format("|cff%s%s|r", hex, SPELL_SCHOOL_NAME[school] or "Unknown")
		end
		tooltip:AddLine(string.format("%s: %d", table.concat(names, " / "), entry.value))
	end
end

--- Info panel uses this as the whole tooltip. Forever Spell Damage keeps Blizzard's tooltip and appends these lines.
function _G.FluxAnniversarySpellPowerTooltip(owner, append)
	if not owner or not GameTooltip then
		return
	end
	if not append then
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()
	elseif not GameTooltip:IsShown() then
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()
	else
		GameTooltip:AddLine(" ")
	end
	AddAnniversarySpellPowerLines(GameTooltip)
	GameTooltip:Show()
end

local foreverSpellDamageTipHooked = false
local function InstallForeverSpellDamageTooltip()
	if foreverSpellDamageTipHooked or not IsForeverCharacterPane() then
		return
	end
	if type(hooksecurefunc) ~= "function" or type(_G.PaperDollFrame_SetSpellPower) ~= "function" then
		return
	end
	foreverSpellDamageTipHooked = true
	hooksecurefunc("PaperDollFrame_SetSpellPower", function(statFrame, unit)
		if not statFrame or (unit and unit ~= "player") then
			return
		end
		local original = statFrame.onEnterFunc
		if not original or original == statFrame._fluxAnniversarySpellEnter then
			return
		end
		local wrapped
		wrapped = function(self)
			original(self)
			if _G.FluxAnniversarySpellPowerTooltip then
				_G.FluxAnniversarySpellPowerTooltip(self, true)
			end
		end
		statFrame._fluxAnniversarySpellEnter = wrapped
		statFrame.onEnterFunc = wrapped
	end)
end

local function CollapsedCategories()
	_FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
	if type(_FluxUI_CharSavedVars.paperDollCollapsed) ~= "table" then
		_FluxUI_CharSavedVars.paperDollCollapsed = {}
	end
	return _FluxUI_CharSavedVars.paperDollCollapsed
end

local function FindStatsScrollBox(frame)
	local player = rawget(_G, "CharacterStatsPaneScrollBox")
	local pet = rawget(_G, "CharacterStatsPanePetScrollBox")
	local parent = frame
	local guard = 0
	while parent and guard < 16 do
		if parent == player or parent == pet then
			return parent
		end
		parent = parent.GetParent and parent:GetParent()
		guard = guard + 1
	end
	return player
end

local function ApplyCollapsedCategories(scrollBox)
	if not scrollBox or scrollBox._fluxApplyingCollapse then
		return
	end
	local data = scrollBox.elementData
	if type(data) ~= "table" or type(CreateDataProvider) ~= "function" then
		return
	end
	local scroll = scrollBox.ScrollBox
	if not scroll or type(scroll.SetDataProvider) ~= "function" then
		return
	end
	local collapsed = CollapsedCategories()
	local out = {}
	local hiding = false
	local changed = false
	for i = 1, #data do
		local row = data[i]
		if type(row) == "table" and row.isHeader then
			hiding = type(row.name) == "string" and collapsed[row.name] and true or false
			out[#out + 1] = row
		elseif not hiding then
			out[#out + 1] = row
		else
			changed = true
		end
	end
	if not changed then
		return
	end
	scrollBox.elementData = out
	scrollBox._fluxApplyingCollapse = true
	local retain = ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition
	pcall(scroll.SetDataProvider, scroll, CreateDataProvider(out), retain)
	scrollBox._fluxApplyingCollapse = nil
end

local BindForeverStatRows

local function ToggleCollapsedCategory(name, scrollBox)
	if type(name) ~= "string" or name == "" or not scrollBox or type(scrollBox.UpdateStats) ~= "function" then
		return
	end
	local collapsed = CollapsedCategories()
	if collapsed[name] then
		collapsed[name] = nil
	else
		collapsed[name] = true
	end
	scrollBox:UpdateStats()
	if BindForeverStatRows then
		BindForeverStatRows()
	end
end

local categoryCollapseHooked = false
local function InstallForeverCategoryCollapse()
	if categoryCollapseHooked or not IsForeverCharacterPane() or type(hooksecurefunc) ~= "function" then
		return
	end
	local categoryMixin = rawget(_G, "CharacterStatFrameCategoryScrollBoxElementMixin")
	local playerBox = rawget(_G, "CharacterStatsPaneScrollBox")
	if not categoryMixin or type(categoryMixin.Init) ~= "function" or not playerBox or type(playerBox.UpdateStats) ~= "function" then
		return
	end
	categoryCollapseHooked = true

	local function HookBox(box)
		if not box or box._fluxCollapseHooked or type(box.UpdateStats) ~= "function" then
			return
		end
		box._fluxCollapseHooked = true
		hooksecurefunc(box, "UpdateStats", function(self)
			ApplyCollapsedCategories(self)
		end)
	end
	HookBox(playerBox)
	HookBox(rawget(_G, "CharacterStatsPanePetScrollBox"))
	local playerMixin = rawget(_G, "CharacterStatsPaneScrollBoxMixin")
	local petMixin = rawget(_G, "CharacterStatsPanePetScrollBoxMixin")
	if playerMixin and playerMixin ~= playerBox then
		HookBox(playerMixin)
	end
	if petMixin then
		HookBox(petMixin)
	end

	hooksecurefunc(categoryMixin, "Init", function(self, elementData)
		local name = elementData and elementData.name
		self._fluxCategoryName = name
		if self.Title and self.Title.SetText and type(name) == "string" then
			local mark = CollapsedCategories()[name] and "+ " or "- "
			self.Title:SetText(mark .. name)
		end
		if self._fluxCategoryClick then
			return
		end
		self._fluxCategoryClick = true
		self:EnableMouse(true)
		self:SetScript("OnMouseUp", function(frame, button)
			if button and button ~= "LeftButton" then
				return
			end
			ToggleCollapsedCategory(frame._fluxCategoryName, FindStatsScrollBox(frame))
		end)
	end)
end

local foreverItemLevelRow

local function EnsureForeverItemLevelStat()
	if not IsForeverCharacterPane() then
		return
	end
	local pane = rawget(_G, "CharacterStatsPaneScrollBox")
	if not pane then return end
	-- CharacterFrame:OnShow refreshes these native categories before asking
	-- the player bars to show numeric text. Inserting into cat.stats taints that
	-- native path. Keep item level in the pane's reserved footer instead, with
	-- no native category/provider edits and no call to the native UpdateStats.
	if not foreverItemLevelRow then
		local row = CreateFrame("Frame", "FluxForeverItemLevelRow", pane)
		row:SetHeight(16)
		row:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 14, 7)
		row:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -30, 7)
		row.Label = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		row.Label:SetPoint("LEFT")
		row.Label:SetText(_G.STAT_AVERAGE_ITEM_LEVEL or "Item Level")
		row.Value = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.Value:SetPoint("RIGHT")
		row:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
		row:SetScript("OnEvent", EnsureForeverItemLevelStat)
		foreverItemLevelRow = row
	end
	local _, equipped = GetAverageItemLevel()
	foreverItemLevelRow.numericValue = nil
	if issecretvalue and issecretvalue(equipped) then
		foreverItemLevelRow.Value:SetText("")
	elseif type(equipped) == "number" then
		foreverItemLevelRow.numericValue = equipped
		foreverItemLevelRow.Value:SetFormattedText("%.1f", equipped)
	else
		foreverItemLevelRow.Value:SetText("")
	end
	local info = rawget(_G, "FluxInfoFrame")
	if info and info.HookForeverScrollBoxStatFrame then
		info.HookForeverScrollBoxStatFrame(foreverItemLevelRow, "itemLevel")
	end
end

local function PlainText(value)
	if type(value) ~= "string" or value == "" then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	return value
end

local function CategoryName(text)
	text = PlainText(text)
	if not text then
		return nil
	end
	return text:gsub("^[%+%-]%s+", "")
end

local function WrapSpellDamageRow(statFrame)
	local original = statFrame.onEnterFunc
	if type(original) ~= "function" or original == statFrame._fluxAnniversarySpellEnter then
		return
	end
	local wrapped
	wrapped = function(self)
		original(self)
		if _G.FluxAnniversarySpellPowerTooltip then
			_G.FluxAnniversarySpellPowerTooltip(self, true)
		end
	end
	statFrame._fluxAnniversarySpellEnter = wrapped
	statFrame.onEnterFunc = wrapped
end

local function EachVisibleStatRow(fn)
	local names = { "CharacterStatsPaneScrollBox", "CharacterStatsPanePetScrollBox" }
	for i = 1, #names do
		local scrollBox = rawget(_G, names[i])
		local scroll = scrollBox and scrollBox.ScrollBox
		local view = scroll and scroll.GetView and scroll:GetView()
		local frames = view and view.GetFrames and view:GetFrames()
		if type(frames) == "table" then
			for f = 1, #frames do
				fn(frames[f], scrollBox)
			end
		end
	end
end

function BindForeverStatRows()
	if not IsForeverCharacterPane() then
		return
	end
    if InCombatLockdown and InCombatLockdown() then return end
	EnsureForeverItemLevelStat()
	local player = rawget(_G, "CharacterStatsPaneScrollBox")
	local pet = rawget(_G, "CharacterStatsPanePetScrollBox")
	ApplyCollapsedCategories(player)
	ApplyCollapsedCategories(pet)
	EachVisibleStatRow(function(row, scrollBox)
		if not row then
			return
		end
		local title = row.Title and row.Title.GetText and row.Title:GetText()
		local category = (row.Title and not row.Label) and CategoryName(title) or nil
		if category then
			local mark = CollapsedCategories()[category] and "+ " or "- "
			if row.Title.SetText then
				row.Title:SetText(mark .. category)
			end
			row._fluxCategoryName = category
			if not row._fluxCategoryClick then
				row._fluxCategoryClick = true
				row:EnableMouse(true)
				row:SetScript("OnMouseUp", function(frame, button)
					if button and button ~= "LeftButton" then
						return
					end
					local name = frame._fluxCategoryName or CategoryName(frame.Title and frame.Title:GetText())
					ToggleCollapsedCategory(name, FindStatsScrollBox(frame))
				end)
			end
			return
		end
		if scrollBox == pet then return end
		if row.bonusDamage then
			WrapSpellDamageRow(row)
		end
		local data
		if row.GetElementData then
			local ok, element = pcall(row.GetElementData, row)
			if ok then
				data = element
			end
		end
		local statName = data and PlainText(data.name)
		if statName == "ITEMLEVEL" and row.Value and row.Value.SetFormattedText and type(GetAverageItemLevel) == "function" then
			local _, avgEquipped = GetAverageItemLevel()
			if type(avgEquipped) == "number" and not (issecretvalue and issecretvalue(avgEquipped)) then
				row.Value:SetFormattedText("%.1f", avgEquipped)
			end
		elseif statName == "CRITCHANCE" and row.Label and row.Label.SetText then
			row.Label:SetText("Crit")
		elseif statName == "HASTE" and row.Label and row.Label.SetText then
			row.Label:SetText("Haste")
		end
		local info = rawget(_G, "FluxInfoFrame")
		local key = statName and FOREVER_STAT_TO_KEY[statName] or nil
		if info and info.HookForeverScrollBoxStatFrame then
			info.HookForeverScrollBoxStatFrame(row, key)
		end
	end)
end

function module.InstallRetailPane()
	if not module.useRetailPaneHooks then
		return false
	end
	if IsForeverCharacterPane() then
		-- Do not hook UpdateStats / SetSpellPower / PaperDoll OnShow. ToggleCharacter
		-- shows the paper doll before CharacterFrame:OnShow compares secret health.
		EnsureForeverItemLevelStat()
		local info = rawget(_G, "FluxInfoFrame")
		if info and info.AfterCharacterShown and not module._foreverOpenBound then
			module._foreverOpenBound = true
			info.AfterCharacterShown(BindForeverStatRows)
		end
		return true
	end
	InstallPaperDollItemLevelDecimalHook()
	InstallPaperDollCritHasteShortLabels()
	InstallUpdateStatsHook()
	InstallForeverScrollBoxHook()
	InstallForeverRowInitHook()
	InstallForeverSpellDamageTooltip()
	EnsureForeverItemLevelStat()
	InstallForeverCategoryCollapse()
	InstallPaperDollShowHook()
	return ilvlHookDone or critHasteLabelHookDone or updateStatsHookDone or scrollBoxHookDone or foreverRowInitHooked
end
