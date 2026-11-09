-- Client_Camelot.lua — Forever (game type camelot) only.
-- The TOC filter is only a loading hint: verify the runtime before any mutations.
local addonName, ns = ...

local project = WOW_PROJECT_ID
local function IsProject(id)
	return id ~= nil and project == id
end
local isClassic = IsProject(WOW_PROJECT_CLASSIC) or IsProject(WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
	or IsProject(WOW_PROJECT_WRATH_CLASSIC) or IsProject(WOW_PROJECT_CATACLYSM_CLASSIC)
	or IsProject(WOW_PROJECT_MISTS_CLASSIC)
local version = GetBuildInfo and GetBuildInfo()
local major = type(version) == "string" and tonumber(version:match("^(%d+)")) or nil
local legacyMainline = IsProject(WOW_PROJECT_MAINLINE) and major and major > 0 and major < 10
local foreverTimer = C_Timer and type(C_Timer.NewTimedSignalMap) == "function"
-- Forever's supplied source has the timed-signal API and the legacy mainline
-- version family. A 12.x Retail client must never receive these native patches,
-- even if this TOC entry executes or another addon supplies a matching API name.
if isClassic or not major or major >= 12 or not (legacyMainline or foreverTimer) then
	return
end

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

-- Keep native status-text and unit-frame update functions untouched. Forever
-- calls them from PlayerFrame/PetFrame refreshes immediately before updating
-- BuffFrame and DebuffFrame. Replacing shared methods taints that native
-- path and its cached state; hidden Flux-replaced artwork is handled by the
-- unit-frame runtime without installing native Lua replacements.
