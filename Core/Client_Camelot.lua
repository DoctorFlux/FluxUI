-- Client_Camelot.lua — Forever (game type camelot) only.
-- AllowLoadGameType camelot. Live / Era / Anniversary never load this file.
local addonName, ns = ...

ns._isCamelotGameType = true

-- Live ships Blizzard_DeprecatedItemScript (`GetItemInfo = C_Item.GetItemInfo`, …).
-- Forever does not, so those globals are nil and crash any unguarded call.
local function AliasIfMissing(name, fn)
	if type(fn) == "function" and type(_G[name]) ~= "function" then
		_G[name] = fn
	end
end

if C_Item then
	AliasIfMissing("GetItemQualityColor", C_Item.GetItemQualityColor)
	AliasIfMissing("GetItemInfoInstant", C_Item.GetItemInfoInstant)
	AliasIfMissing("GetItemSetInfo", C_Item.GetItemSetInfo)
	AliasIfMissing("GetItemChildInfo", C_Item.GetItemChildInfo)
	AliasIfMissing("DoesItemContainSpec", C_Item.DoesItemContainSpec)
	AliasIfMissing("GetItemGem", C_Item.GetItemGem)
	AliasIfMissing("GetItemCreationContext", C_Item.GetItemCreationContext)
	AliasIfMissing("GetItemIcon", C_Item.GetItemIconByID)
	AliasIfMissing("GetItemFamily", C_Item.GetItemFamily)
	AliasIfMissing("GetItemSpell", C_Item.GetItemSpell)
	AliasIfMissing("IsArtifactPowerItem", C_Item.IsArtifactPowerItem)
	AliasIfMissing("IsCurrentItem", C_Item.IsCurrentItem)
	AliasIfMissing("IsUsableItem", C_Item.IsUsableItem)
	AliasIfMissing("IsHelpfulItem", C_Item.IsHelpfulItem)
	AliasIfMissing("IsHarmfulItem", C_Item.IsHarmfulItem)
	AliasIfMissing("IsConsumableItem", C_Item.IsConsumableItem)
	AliasIfMissing("IsEquippableItem", C_Item.IsEquippableItem)
	AliasIfMissing("IsEquippedItem", C_Item.IsEquippedItem)
	AliasIfMissing("IsEquippedItemType", C_Item.IsEquippedItemType)
	AliasIfMissing("ItemHasRange", C_Item.ItemHasRange)
	AliasIfMissing("IsItemInRange", C_Item.IsItemInRange)
	AliasIfMissing("GetItemClassInfo", C_Item.GetItemClassInfo)
	AliasIfMissing("GetItemInventorySlotInfo", C_Item.GetItemInventorySlotInfo)
	AliasIfMissing("BindEnchant", C_Item.BindEnchant)
	AliasIfMissing("ActionBindsItem", C_Item.ActionBindsItem)
	AliasIfMissing("ReplaceEnchant", C_Item.ReplaceEnchant)
	AliasIfMissing("ReplaceTradeEnchant", C_Item.ReplaceTradeEnchant)
	AliasIfMissing("ConfirmBindOnUse", C_Item.ConfirmBindOnUse)
	AliasIfMissing("ConfirmOnUse", C_Item.ConfirmOnUse)
	AliasIfMissing("ConfirmNoRefundOnUse", C_Item.ConfirmNoRefundOnUse)
	AliasIfMissing("DropItemOnUnit", C_Item.DropItemOnUnit)
	AliasIfMissing("EndBoundTradeable", C_Item.EndBoundTradeable)
	AliasIfMissing("EndRefund", C_Item.EndRefund)
	AliasIfMissing("GetItemInfo", C_Item.GetItemInfo)
	AliasIfMissing("GetDetailedItemLevelInfo", C_Item.GetDetailedItemLevelInfo)
	AliasIfMissing("GetItemSpecInfo", C_Item.GetItemSpecInfo)
	AliasIfMissing("GetItemUniqueness", C_Item.GetItemUniqueness)
	AliasIfMissing("GetItemCount", C_Item.GetItemCount)
	AliasIfMissing("PickupItem", C_Item.PickupItem)
	AliasIfMissing("GetItemSubClassInfo", C_Item.GetItemSubClassInfo)
	AliasIfMissing("UseItemByName", C_Item.UseItemByName)
	AliasIfMissing("EquipItemByName", C_Item.EquipItemByName)
	AliasIfMissing("ReplaceTradeskillEnchant", C_Item.ReplaceTradeskillEnchant)
	AliasIfMissing("GetItemCooldown", C_Item.GetItemCooldown)
	AliasIfMissing("IsCorruptedItem", C_Item.IsCorruptedItem)
	AliasIfMissing("IsCosmeticItem", C_Item.IsCosmeticItem)
	AliasIfMissing("IsDressableItem", C_Item.IsDressableItem)
end

if C_PvP then
	AliasIfMissing("IsSubZonePVPPOI", C_PvP.IsSubZonePVPPOI)
	AliasIfMissing("GetZonePVPInfo", C_PvP.GetZonePVPInfo)
	AliasIfMissing("TogglePVP", C_PvP.TogglePVP)
	AliasIfMissing("SetPVP", C_PvP.SetPVP)
end

local function SpellRankSubtext(spell)
	if C_Spell and C_Spell.GetSpellSubtext then
		local ok, sub = pcall(C_Spell.GetSpellSubtext, spell)
		if ok and type(sub) == "string" and sub ~= "" then
			return sub
		end
	end
	return nil
end

if type(GetSpellInfo) ~= "function" and C_Spell and C_Spell.GetSpellInfo then
	GetSpellInfo = function(spell)
		local info = C_Spell.GetSpellInfo(spell)
		if type(info) == "table" then
			return info.name, SpellRankSubtext(spell), info.iconID or info.originalIconID, info.castTime,
				info.minRange, info.maxRange, info.spellID, info.originalIconID
		end
		return info
	end
elseif type(GetSpellInfo) == "function" then
	local origGetSpellInfo = GetSpellInfo
	GetSpellInfo = function(spell)
		local name, rank, icon, castTime, minRange, maxRange, spellID, originalIconID = origGetSpellInfo(spell)
		if type(name) == "string" and (rank == nil or rank == "") then
			rank = SpellRankSubtext(spell) or rank
		end
		return name, rank, icon, castTime, minRange, maxRange, spellID, originalIconID
	end
end

local function UnpackAuraData(data)
	if not data then
		return nil
	end
	if AuraUtil and AuraUtil.UnpackAuraData then
		return AuraUtil.UnpackAuraData(data)
	end
	return data.name, data.icon, data.applications, data.dispelName, data.duration, data.expirationTime,
		data.sourceUnit, data.isStealable, data.nameplateShowPersonal, data.spellId, data.canApplyAura,
		data.isBossAura, data.isFromPlayerOrPlayerPet, data.nameplateShowAll, data.timeMod
end

if C_UnitAuras then
	if type(UnitAura) ~= "function" and C_UnitAuras.GetAuraDataByIndex then
		UnitAura = function(unit, index, filter)
			return UnpackAuraData(C_UnitAuras.GetAuraDataByIndex(unit, index, filter))
		end
	end
	if type(UnitBuff) ~= "function" and C_UnitAuras.GetBuffDataByIndex then
		UnitBuff = function(unit, index, filter)
			return UnpackAuraData(C_UnitAuras.GetBuffDataByIndex(unit, index, filter))
		end
	end
	if type(UnitDebuff) ~= "function" and C_UnitAuras.GetDebuffDataByIndex then
		UnitDebuff = function(unit, index, filter)
			return UnpackAuraData(C_UnitAuras.GetDebuffDataByIndex(unit, index, filter))
		end
	end
end

-- ComboFrame_Update does `GetComboPoints() > 0`. On Forever that value is secret,
-- and Flux unit-frame taint makes the compare error. Park the stock frame; class
-- power bars own combo points on this UI family.
if type(ComboFrame_OnEvent) == "function" then
	ComboFrame_OnEvent = function() end
end
if type(ComboFrame_Update) == "function" then
	ComboFrame_Update = function() end
end
if type(ComboFrame_UpdateMax) == "function" then
	ComboFrame_UpdateMax = function() end
end
local function ParkComboFrame()
	if ComboFrame then
		ComboFrame:UnregisterAllEvents()
		ComboFrame:Hide()
	end
end
ParkComboFrame()
if not ComboFrame then
	local waiter = CreateFrame("Frame")
	waiter:RegisterEvent("PLAYER_LOGIN")
	waiter:SetScript("OnEvent", function(self)
		ParkComboFrame()
		self:UnregisterAllEvents()
	end)
end

-- CharacterFrame:OnShow turns on player/pet status text. On Forever that runs
-- while Flux is still on the stack (the character button is placed from addon
-- code, which taints the secure click). TextStatusBar then does `valueMax > 0`
-- on secret health and throws. SetFormattedText accepts those numbers.
-- UnitFrameHealthBar_OnUpdate calls the same text update, then compares secret
-- absorbs. Skip that follow-up when the numbers are secret so the text path
-- does not create a second error. Flux health bars own the combat display.
-- 12.0/12.1: tainted code must not compare secret numbers. issecretvalue is not
-- enough on its own; canaccessvalue is false for values that still throw.
local function UnsafeToCompare(value)
	if value == nil then
		return false
	end
	if issecretvalue then
		local ok, secret = pcall(issecretvalue, value)
		if ok and secret then
			return true
		end
	end
	if canaccessvalue then
		local ok, access = pcall(canaccessvalue, value)
		if ok and not access then
			return true
		end
	end
	return false
end

local function SecretNumber(value)
	return UnsafeToCompare(value)
end

local function BarIsSecret(bar)
	if not bar or not issecretvalue then
		return false
	end
	if bar.GetValue and SecretNumber(bar:GetValue()) then
		return true
	end
	if bar.GetMinMaxValues then
		local minValue, maxValue = bar:GetMinMaxValues()
		if SecretNumber(minValue) or SecretNumber(maxValue) then
			return true
		end
	end
	return false
end

local function PaintSecretStatusText(bar, textString, value, valueMax)
	if not textString then
		return
	end
	if bar.LeftText and bar.RightText then
		bar.LeftText:SetText("")
		bar.RightText:SetText("")
		bar.LeftText:Hide()
		bar.RightText:Hide()
	end
	if bar.pauseUpdates then
		return
	end
	local locked = type(bar.lockShow) == "number" and bar.lockShow > 0
	local forced = bar.forceShow or (bar.cvar and GetCVar(bar.cvar) == "1" and bar.textLockable)
	if bar.forceHideText or not (locked or forced) then
		textString:SetText("")
		textString:Hide()
		return
	end
	if textString.SetFormattedText then
		if bar.disableMaxValue then
			textString:SetFormattedText("%s", value)
		else
			textString:SetFormattedText("%s / %s", value, valueMax)
		end
	end
	textString:Show()
end

local function IsSecretErr(err)
	return type(err) == "string" and string.find(err, "secret", 1, true) ~= nil
end

local function GuardCall(orig, ...)
	local ok, err = pcall(orig, ...)
	if not ok and not IsSecretErr(err) then
		error(err, 0)
	end
	return ok
end

local function WrapTextMethod(bar, key)
	local orig = bar[key]
	if type(orig) ~= "function" or orig == bar._fluxCamelotTextWrap then
		return
	end
	local function wrapped(self, textString, value, valueMin, valueMax)
		-- Never call the Blizzard body. pcall does not hide 12.1 secret compares.
		PaintSecretStatusText(self, textString, value, valueMax)
	end
	bar._fluxCamelotTextWrap = wrapped
	bar[key] = wrapped
end

local function PatchBar(bar)
	if not bar or type(bar.UpdateTextStringWithValues) ~= "function" then
		return
	end
	WrapTextMethod(bar, "UpdateTextStringWithValues")
end

local function PatchUnitFrame(frame)
	if not frame then
		return
	end
	PatchBar(frame)
	PatchBar(frame.healthbar)
	PatchBar(frame.manabar)
	PatchBar(frame.HealthBar)
	PatchBar(frame.ManaBar)
	PatchBar(frame.PlayerFrameHealthBar)
	PatchBar(frame.PlayerFrameManaBar)
end

local function GuardGlobal(name, replace)
	local orig = _G[name]
	if type(orig) ~= "function" or orig == _G["FluxCamelotGuard_" .. name] then
		return
	end
	local wrapped = replace(orig)
	_G["FluxCamelotGuard_" .. name] = wrapped
	_G[name] = wrapped
end

local function InstallSecretStatusText()
	local mixin = _G.TextStatusBarMixin
	if mixin then
		PatchBar(mixin)
	end
	PatchUnitFrame(_G.PlayerFrame)
	PatchUnitFrame(_G.PetFrame)
	PatchUnitFrame(_G.TargetFrame)
	PatchUnitFrame(_G.FocusFrame)
	PatchBar(_G.PlayerFrameHealthBar)
	PatchBar(_G.PlayerFrameManaBar)
	PatchBar(_G.PetFrameHealthBar)
	PatchBar(_G.PetFrameManaBar)
	for i = 1, 5 do
		PatchUnitFrame(_G["PartyFrame" .. i] or _G["PartyMemberFrame" .. i])
		PatchUnitFrame(_G["ArenaEnemyFrame" .. i])
		PatchUnitFrame(_G["ArenaEnemyMatchFrame" .. i])
		PatchUnitFrame(_G["Boss" .. i .. "TargetFrame"])
	end

	-- SetMinMaxValues fires HealthBar_OnValueChanged, which compares `value`.
	-- That compare is not suppressible with pcall on 12.1. Skip it for secrets.
	if type(_G.HealthBar_OnValueChanged) == "function" and not _G.FluxCamelotHealthColorGuarded then
		_G.FluxCamelotHealthColorGuarded = true
		local origColor = _G.HealthBar_OnValueChanged
		_G.HealthBar_OnValueChanged = function(self, value, smooth)
			if value == nil or UnsafeToCompare(value) then
				return
			end
			local minValue, maxValue = self:GetMinMaxValues()
			if UnsafeToCompare(minValue) or UnsafeToCompare(maxValue) then
				return
			end
			return origColor(self, value, smooth)
		end
	end

	-- Do not call the original update. It compares maxValue and then
	-- SetMinMaxValues, which re-enters the color compare above.
	GuardGlobal("UnitFrameHealthBar_Update", function(_orig)
		return function(statusbar, unit)
			if not statusbar or statusbar.lockValues then
				return
			end
			PatchBar(statusbar)
			unit = unit or statusbar.unit
			if statusbar.unit and unit and not UnsafeToCompare(unit) and not UnsafeToCompare(statusbar.unit) and unit ~= statusbar.unit then
				return
			end
			if not unit then
				return
			end
			local maxValue = UnitHealthMax(unit)
			local currValue = UnitHealth(unit)
			statusbar.forceHideText = false
			statusbar:SetMinMaxValues(0, maxValue)
			statusbar:SetValue(currValue)
			statusbar.currValue = currValue
			if statusbar.TextString then
				PaintSecretStatusText(statusbar, statusbar.TextString, currValue, maxValue)
			end
		end
	end)

	-- Mana type refresh calls UpdateTextString, which compares secret power.
	GuardGlobal("UnitFrameManaBar_UpdateType", function(orig)
		return function(manaBar)
			PatchBar(manaBar)
			GuardCall(orig, manaBar)
		end
	end)
	GuardGlobal("UnitFrameManaBar_Update", function(orig)
		return function(statusbar, unit)
			PatchBar(statusbar)
			if statusbar and unit and unit == statusbar.unit and UnitPowerMax and SecretNumber(UnitPowerMax(unit, statusbar.powerType)) then
				if type(_G.UnitFrameManaBar_UpdateType) == "function" then
					pcall(_G.UnitFrameManaBar_UpdateType, statusbar)
				end
				local maxValue = UnitPowerMax(unit, statusbar.powerType)
				statusbar:SetMinMaxValues(0, maxValue)
				local currValue = UnitPower(unit, statusbar.powerType)
				statusbar:SetValue(currValue)
				statusbar.currValue = currValue
				if statusbar.UpdateTextString then
					pcall(statusbar.UpdateTextString, statusbar)
				end
				return
			end
			GuardCall(orig, statusbar, unit)
		end
	end)

	if type(_G.UnitFrameHealPredictionBars_Update) == "function" and not _G.FluxCamelotHealPredictGuarded then
		_G.FluxCamelotHealPredictGuarded = true
		local orig = _G.UnitFrameHealPredictionBars_Update
		_G.UnitFrameHealPredictionBars_Update = function(frame)
			local bar = frame and frame.healthbar
			if BarIsSecret(bar) then
				return
			end
			GuardCall(orig, frame)
		end
	end
end

InstallSecretStatusText()
local statusWait = CreateFrame("Frame")
statusWait:RegisterEvent("ADDON_LOADED")
statusWait:RegisterEvent("PLAYER_LOGIN")
statusWait:RegisterEvent("PLAYER_ENTERING_WORLD")
statusWait:SetScript("OnEvent", function()
	InstallSecretStatusText()
end)

