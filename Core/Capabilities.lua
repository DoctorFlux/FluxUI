-- Capabilities.lua — feature probes. Capability-first; later modules ask these, not flavor names.
local addonName, ns = ...
local Flux = ns.Flux
local Client = Flux.Client

local pcall = pcall
local type = type
local rawget = rawget

local Cap = {}
Flux.Cap = Cap
Flux.Capabilities = Cap

local function Exists(v)
	return v ~= nil
end

--- True only while the client is presenting the gamepad HUD.
--- False when the style API is missing, so retail and classic stay on the keyboard bars.
function Cap.IsGamepadUIEnabled()
	if not Cap.hasGamepadUI then
		return false
	end
	local ok, style = pcall(C_InputInterfaceStyle.GetCurrentStyle)
	if not ok then
		return false
	end
	return style == Enum.InputDeviceInterfaceType.Gamepad
end

--- Style API, or the gamepad action bar actually on screen.
function Cap.GamepadHudActive()
	if Cap.IsGamepadUIEnabled() then
		return true
	end
	local bar = _G.GamepadMainActionBarFrame
	return bar and bar.IsShown and bar:IsShown() and true or false
end

--- Bottom-offset of the top of Blizzard's gamepad action bar, in UIParent space.
--- Read-only, so a scale or drag from another addon is included. Nil until that
--- frame is shown. Never anchors, scales, or scripts the frame.
function Cap.GetGamepadActionBarFloor()
	if not Cap.IsGamepadUIEnabled() then
		return nil
	end
	local bar = _G.GamepadMainActionBarFrame
	if type(bar) ~= "table" or type(bar.GetTop) ~= "function" then
		return nil
	end
	if bar.IsShown and not bar:IsShown() then
		return nil
	end
	if not UIParent or type(UIParent.GetBottom) ~= "function" then
		return nil
	end
	local top, bottom = bar:GetTop(), UIParent:GetBottom()
	if type(top) ~= "number" or type(bottom) ~= "number" or top ~= top or bottom ~= bottom then
		return nil
	end
	local scale = bar.GetEffectiveScale and bar:GetEffectiveScale()
	local parentScale = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()
	if type(scale) == "number" and scale > 0 and type(parentScale) == "number" and parentScale > 0 then
		top = top * scale / parentScale
	end
	local y = top - bottom
	if y ~= y or y <= 0 then
		return nil
	end
	return y
end

Cap.hasC_Spell = Exists(C_Spell)
Cap.hasC_Item = Exists(C_Item)
Cap.hasC_Container = Exists(C_Container)
Cap.hasC_ActionBar = Exists(C_ActionBar)
-- Gamepad HUD style, not a plugged-in controller. Live and classic ship the
-- device API without this HUD; the style API is what later clients would add.
Cap.hasGamepadUI = C_InputInterfaceStyle ~= nil
	and type(C_InputInterfaceStyle.GetCurrentStyle) == "function"
	and Enum ~= nil
	and Enum.InputDeviceInterfaceType ~= nil
	and Enum.InputDeviceInterfaceType.Gamepad ~= nil
Cap.hasC_UnitAuras = Exists(C_UnitAuras)
Cap.hasC_UnitAuras_GetAuraSlots = C_UnitAuras ~= nil and C_UnitAuras.GetAuraSlots ~= nil
	Cap.hasC_UnitAuras_GetAuraDataBySlot = C_UnitAuras ~= nil and C_UnitAuras.GetAuraDataBySlot ~= nil
	Cap.hasC_UnitAuras_GetAuraDataByIndex = C_UnitAuras ~= nil and C_UnitAuras.GetAuraDataByIndex ~= nil
	Cap.hasC_UnitAuras_GetAuraDataByAuraInstanceID = C_UnitAuras ~= nil and C_UnitAuras.GetAuraDataByAuraInstanceID ~= nil
	Cap.hasC_UnitAuras_GetPlayerAuraBySpellID = C_UnitAuras ~= nil and C_UnitAuras.GetPlayerAuraBySpellID ~= nil
	Cap.hasC_UnitAuras_GetCooldownAuraBySpellID = C_UnitAuras ~= nil and C_UnitAuras.GetCooldownAuraBySpellID ~= nil
	Cap.hasC_UnitAuras_GetAuraDuration = C_UnitAuras ~= nil and C_UnitAuras.GetAuraDuration ~= nil
Cap.hasSecretValueAPI = (issecretvalue or IsSecretValue) ~= nil
-- Forever (camelot) C API; live / classic trees do not ship this global.
Cap.hasRegionalUniqueNames = type(RegionalUniqueNamesEnabled) == "function"
Cap.hasCanAccessValue = canaccessvalue ~= nil
Cap.hasCanAccessSecrets = canaccesssecrets ~= nil
Cap.hasEditMode = (C_EditMode ~= nil) and (EditModeManagerFrame ~= nil)
Cap.hasToyBox = C_ToyBox ~= nil and C_ToyBox.GetToyInfo ~= nil and PlayerHasToy ~= nil
Cap.hasC_MountJournal = C_MountJournal ~= nil
-- [flyable] / IsFlyableArea: Wrath 3.0.2+. Era and TBC Anniversary bag mounts cannot use the macro option.
Cap.hasIsFlyableArea = type(IsFlyableArea) == "function"
Cap.hasFlyableMacro = not Client.isEra and not Client.isTBC
	and (Client.isRetail or Client.isMists or Client.isCata or Client.isWrath or (Client.majorVersion or 0) >= 3)
Cap.hasToggleCollectionsJournal = ToggleCollectionsJournal ~= nil
Cap.hasC_Timer = C_Timer ~= nil and C_Timer.After ~= nil
Cap.hasC_Timer_NewTicker = C_Timer ~= nil and C_Timer.NewTicker ~= nil
Cap.hasBackdropTemplateMixin = BackdropTemplateMixin ~= nil
Cap.hasSecureActionButtonTemplate = SecureActionButtonTemplate ~= nil
-- Legacy policy for click wrappers and other modules. Bars independently
-- probe the repaired restricted environment via Restricted.PagingWorks;
-- this flag must not prevent secure paging on newer Forever clients.
Cap.hasRestrictedClosures = not Client.isCamelot
Cap.hasC_AddOns = C_AddOns ~= nil
Cap.hasC_PetJournal = C_PetJournal ~= nil
Cap.hasC_SpellActivationOverlay = C_SpellActivationOverlay ~= nil
Cap.hasC_AssistedCombat = C_AssistedCombat ~= nil
Cap.hasTalentTreeSpec = GetSpecialization == nil and GetTalentTabInfo ~= nil
Cap.hasInspectTalents = NotifyInspect ~= nil and GetTalentTabInfo ~= nil
Cap.hasGetBackpackCurrencyInfo = C_CurrencyInfo ~= nil and C_CurrencyInfo.GetBackpackCurrencyInfo ~= nil
Cap.hasGetCurrencyListSize = type(GetCurrencyListSize) == "function"
Cap.hasTalkingHead = Client.isRetail
Cap.hasSkyriding = Client.isRetail and Client.isPostDF and not Client.isCamelot
-- Weapon swing cast-bar overlay: Era / TBC Anniversary / Wrath / Forever.
-- Live post-DF retail, Cata, and Mists stay gated off. Camelot is post-DF retail
-- family but ships PLAYER_SWING / C_SwingTimer, so it must not inherit that gate.
Cap.disableSwingTimer = ((Client.isRetail and Client.isPostDF) and not Client.isCamelot) or Client.isCata or Client.isMists
Cap.hasSwingTimer = not Cap.disableSwingTimer
Cap.hasNativePlayerSwing = C_SwingTimer ~= nil
	and type(C_SwingTimer.EnableRangeCheck) == "function"
	and type(C_SwingTimer.IsTargetWithinSwingRange) == "function"
	and Enum ~= nil
	and Enum.PlayerSwingType ~= nil
	and Enum.PlayerSwingType.MainHand ~= nil
	and Enum.PlayerSwingType.Ranged ~= nil
Cap.hasDurationUtil = C_DurationUtil ~= nil and type(C_DurationUtil.CreateDuration) == "function"
do
	local testBar = CreateFrame("StatusBar")
	Cap.hasStatusBarTimerDuration = type(testBar.SetTimerDuration) == "function"
	pcall(function()
		testBar:Hide()
	end)
end
do
	-- Live Midnight forbids the event methods themselves, including cleanup.
	-- Do not probe them even when the restriction query is absent or says false.
	local restricted = Client.isLiveMidnight == true
	if not restricted and C_CombatLog and C_CombatLog.IsCombatLogRestricted then
		local ok, res = pcall(C_CombatLog.IsCombatLogRestricted)
		if ok and res then
			restricted = true
		end
	end
	if restricted then
		Cap.hasCombatLogUnfiltered = false
	else
		local testFrame = CreateFrame("Frame")
		local ok = pcall(function()
			testFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end)
		if ok then
			pcall(function()
				testFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			end)
		end
		Cap.hasCombatLogUnfiltered = ok and true or false
	end
end
-- Post-DF live and Forever share the Flux scroll viewport. GetAvailableHeight
-- stays Blizzard's; layout height is pinned so modules are not truncated.
-- Forever still waits for ObjectiveTrackerManager.Init and a non-zero height
-- before the tracker is reparented (a height of 0 makes Update Hide the body).
Cap.hasBlizzardObjectiveTrackerScroll = Client.isRetail and Client.isPostDF
Cap.avoidAddonForcedBuffFrameUpdate = Client.isRetail and Cap.hasSecretValueAPI
Cap.hasQuickJoinToastButton = QuickJoinToastButton ~= nil
Cap.canOpenMountCollection = C_MountJournal ~= nil
Cap.canOpenCompanionMounts = type(GetNumCompanions) == "function"
Cap.useAccountWideGoldLedger = Client.isRetail and Client.isPostDF
-- Per-rank spells (auto rank-up + Show All Ranks): Forever, Classic Era,
-- Anniversary, Wrath. Live Midnight (wow-ui-source-live) has no
-- C_SpellBook.IsSpellBookItemLowRank; do not trust a false Camelot flag.
Cap.hasSpellBookItemLowRank = C_SpellBook and type(C_SpellBook.IsSpellBookItemLowRank) == "function"
do
	if Client.isCata or Client.isMists or Client.isLiveMidnight then
		Cap.supportsPerRankSpellBarFeatures = false
	elseif Client.isEra or Client.isAnniversary or Client.isTBC or Client.isWrath then
		Cap.supportsPerRankSpellBarFeatures = true
	else
		Cap.supportsPerRankSpellBarFeatures = Cap.hasSpellBookItemLowRank == true
	end
end

do
	local testFrame = CreateFrame("Frame")
	local okTarget = pcall(function()
		testFrame:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_TARGET", "player")
	end)
	local okClear = pcall(function()
		testFrame:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_CLEAR", "player")
	end)
	local valid = true
	if C_EventUtils and C_EventUtils.IsEventValid then
		valid = C_EventUtils.IsEventValid("UNIT_SPELLCAST_RETICLE_TARGET")
			and C_EventUtils.IsEventValid("UNIT_SPELLCAST_RETICLE_CLEAR")
	end
	Cap.hasUnitSpellcastReticleEvents = Client.isPostDF and valid and okTarget and okClear
	pcall(function()
		testFrame:UnregisterAllEvents()
	end)
end

function Cap.GetMaxBagIndex()
	if NUM_BAG_SLOTS then
		return NUM_BAG_SLOTS
	end
	return Client.isRetail and 5 or 4
end

function Cap.HasBlizzardSettingsKeybindings()
	return Settings ~= nil
		and KeybindingsOverrides ~= nil
		and type(KeybindingsOverrides.AddBindingCategories) == "function"
end

function Cap.HasBlizzardActionBarsOverrides()
	return ActionBarsOverrides ~= nil
		and type(ActionBarsOverrides.CreateActionBarVisibilitySettings) == "function"
end

--- Blizzard Key Bindings / Action Bars options reshape.
--- unsupported: no Settings keybind categories
--- mainline: Live / Forever — labels + extra bars off; never replace Settings functions
---   (a Flux function inside Settings registration taints pooled rows, and the
---   nameplate options preview then lays out auras tainted)
--- classic_style: Era / Anniversary / MoP (and leftover Wrath/Cata) — full list reshape
function Cap.GetFluxBlizzardActionBarUIMode()
	if not Cap.HasBlizzardSettingsKeybindings() then
		return "unsupported"
	end
	if Client.isRetail then
		return "mainline"
	end
	if Client.isEra or Client.isTBC or Client.isWrath or Client.isCata or Client.isMists then
		return "classic_style"
	end
	return "unsupported"
end

function Cap.AllowBlizzardActionBarSettingsReplace()
	return Cap.GetFluxBlizzardActionBarUIMode() == "classic_style"
		and not (Client.isRetail and Client.isPostDF)
end

function Cap.HasUnifiedBankUI()
	if not (Client.isRetail and Client.isPostDF) then
		return false
	end
	if C_Bank and type(C_Bank.FetchPurchasedBankTabIDs) == "function" then
		return true
	end
	return type(rawget(_G, "BankPanelMixin")) == "table"
		and type(rawget(_G, "BankPanelItemButtonMixin")) == "table"
end

function Cap.UseLegacyBankSlotsUI()
	return not Cap.HasUnifiedBankUI()
end

function Cap.HasWarbandBank()
	if not Client.isRetail then
		return false
	end
	if Enum and Enum.BagIndex and Enum.BagIndex.AccountBankTab_1 ~= nil then
		return true
	end
	return Cap.HasUnifiedBankUI()
end

--- Forever Camelot: BankPanel + bags-in-bank paging, not live Midnight named tabs.
function Cap.UsesPlayerBagsInBank()
	if not Cap.HasUnifiedBankUI() then
		return false
	end
	if C_Bank and type(C_Bank.ShouldUsePlayerBagsInBank) == "function" then
		local ok, use = pcall(C_Bank.ShouldUsePlayerBagsInBank)
		if ok then
			return use and true or false
		end
	end
	return Client.isCamelot == true
end

function Cap.GetCharacterBankTabSentinel()
	return Enum and Enum.BagIndex and Enum.BagIndex.Characterbanktab or nil
end

function Cap.GetAccountBankTabSentinel()
	return Enum and Enum.BagIndex and Enum.BagIndex.Accountbanktab or nil
end

function Cap.IsBankTabSentinel(bag)
	bag = tonumber(bag)
	if not bag then
		return false
	end
	local character = Cap.GetCharacterBankTabSentinel()
	local account = Cap.GetAccountBankTabSentinel()
	return bag == character or bag == account
end

--- Reagent bank container only. Forever Accountbanktab is also -3; never treat that as a reagent bank.
function Cap.HasReagentBankContainer()
	local id = rawget(_G, "REAGENTBANK_CONTAINER")
	if type(id) ~= "number" then
		return false
	end
	if Cap.IsBankTabSentinel(id) then
		return false
	end
	return true
end

function Cap.GetReagentBankContainerID()
	if not Cap.HasReagentBankContainer() then
		return nil
	end
	return _G.REAGENTBANK_CONTAINER
end

function Cap.IsReagentBankContainer(bag)
	bag = tonumber(bag)
	local id = Cap.GetReagentBankContainerID()
	return id ~= nil and bag == id
end

local function WalkBankTabEnum(prefix)
	local ids = {}
	local bagIndex = Enum and Enum.BagIndex
	if not bagIndex or type(prefix) ~= "string" then
		return ids
	end
	for i = 1, 32 do
		local id = bagIndex[prefix .. i]
		if id == nil then
			break
		end
		id = tonumber(id)
		if id and not Cap.IsBankTabSentinel(id) then
			ids[#ids + 1] = id
		end
	end
	return ids
end

function Cap.FetchPurchasedBankTabIDs(bankType)
	if not (C_Bank and type(C_Bank.FetchPurchasedBankTabIDs) == "function" and bankType ~= nil) then
		return nil
	end
	local ok, tabs = pcall(C_Bank.FetchPurchasedBankTabIDs, bankType)
	if not ok or type(tabs) ~= "table" then
		return nil
	end
	local ids = {}
	for i = 1, #tabs do
		local id = tonumber(tabs[i])
		if id and not Cap.IsBankTabSentinel(id) then
			ids[#ids + 1] = id
		end
	end
	if #ids == 0 then
		return nil
	end
	return ids
end

--- Purchased tab IDs when C_Bank answers, else CharacterBankTab_N / AccountBankTab_N until nil.
function Cap.EnumerateBankTabIDs(bankType)
	local prefix = "CharacterBankTab_"
	if Enum and Enum.BankType and bankType == Enum.BankType.Account then
		prefix = "AccountBankTab_"
	end
	local ids, seen = {}, {}
	local function append(id)
		id = tonumber(id)
		if not id or seen[id] or Cap.IsBankTabSentinel(id) then
			return
		end
		seen[id] = true
		ids[#ids + 1] = id
	end
	local purchased = Cap.FetchPurchasedBankTabIDs(bankType)
	if purchased then
		for i = 1, #purchased do
			append(purchased[i])
		end
	end
	local walked = WalkBankTabEnum(prefix)
	for i = 1, #walked do
		append(walked[i])
	end
	return ids
end

function Cap.IsUnifiedBankTabBag(bag)
	bag = tonumber(bag)
	if not bag or Cap.IsBankTabSentinel(bag) then
		return false
	end
	local bagIndex = Enum and Enum.BagIndex
	if not bagIndex then
		return false
	end
	for i = 1, 32 do
		local character = bagIndex["CharacterBankTab_" .. i]
		if character == nil then
			break
		end
		if bag == character then
			return true
		end
	end
	for i = 1, 32 do
		local account = bagIndex["AccountBankTab_" .. i]
		if account == nil then
			break
		end
		if bag == account then
			return true
		end
	end
	return false
end

function Cap.HasCompactRaidFrameManager()
	return type(rawget(_G, "CompactRaidFrameManager")) == "table"
end

function Cap.HasAtlas(name)
	if type(name) ~= "string" or name == "" then
		return false
	end
	if C_Texture and C_Texture.GetAtlasInfo then
		local ok, info = pcall(C_Texture.GetAtlasInfo, name)
		if not ok or info == nil then
			return false
		end
		if type(info) == "table" then
			local w = info.width or info.w
			if type(w) == "number" then
				return w > 0
			end
			return next(info) ~= nil
		end
		return true
	end
	if GetAtlasInfo then
		local ok, w = pcall(GetAtlasInfo, name)
		if not ok or w == nil then
			return false
		end
		if type(w) == "number" then
			return w > 0
		end
		return true
	end
	return false
end

function Cap.ClientSupportsSingleButtonAssistant()
	if Client.majorVersion < 10 then
		return false
	end
	return C_AssistedCombat ~= nil
end

function Cap.ClientSupportsCombatAmmoExtraButton()
	local pd = rawget(_G, "C_PaperDollInfo")
	if type(pd) == "table" and type(pd.IsRangedSlotShown) == "function" then
		local ok, shown = pcall(pd.IsRangedSlotShown)
		if ok then
			return shown and true or false
		end
	end
	local fn = rawget(_G, "GetInventorySlotInfo")
	if type(fn) ~= "function" then
		return false
	end
	local function slotNumber(token)
		local ok, slot = pcall(fn, token)
		return ok and type(slot) == "number"
	end
	return slotNumber("AmmoSlot") or slotNumber("RangedSlot")
end

local function ClientHasCharacterCurrencyTab()
	local subs = rawget(_G, "CHARACTERFRAME_SUBFRAMES")
	if type(subs) == "table" then
		for _, name in pairs(subs) do
			if name == "TokenFrame" then
				return true
			end
		end
		return false
	end
	if C_CurrencyInfo and type(C_CurrencyInfo.ExpandCurrencyList) == "function" then
		return true
	end
	if Client.isEra then
		return false
	end
	if type(ExpandCurrencyList) == "function" and type(GetCurrencyListSize) == "function" then
		return true
	end
	return false
end

local function ComputeFocusUnitCapability()
	local focusFrame = rawget(_G, "FocusFrame")
	local focusUnit = rawget(_G, "FocusUnit")
	local setFocusLegacy = rawget(_G, "SetFocus")
	local clearFocus = rawget(_G, "ClearFocus")
	local canAssignFocus = (type(focusUnit) == "function") or (type(setFocusLegacy) == "function")
	local has = focusFrame and canAssignFocus and type(clearFocus) == "function"
	if has then
		local test = CreateFrame("Frame")
		local ok = pcall(function()
			test:RegisterUnitEvent("UNIT_HEALTH", "focus")
		end)
		test:UnregisterAllEvents()
		if not ok then
			has = true
		end
	end
	return has and true or false
end

function Cap.RefreshFocusUnit()
	Cap.hasFocusUnit = ComputeFocusUnitCapability()
	return Cap.hasFocusUnit
end

function Cap.RefreshUnifiedBank()
	Cap.hasUnifiedBankUI = Cap.HasUnifiedBankUI()
	Cap.useLegacyBankSlotsUI = not Cap.hasUnifiedBankUI
	Cap.hasWarbandBank = Cap.HasWarbandBank()
	Cap.usesPlayerBagsInBank = Cap.UsesPlayerBagsInBank()
	Cap.hasReagentBankContainer = Cap.HasReagentBankContainer()
	return Cap.hasUnifiedBankUI
end

function Cap.RefreshKeyring()
	local kc = rawget(_G, "KEYRING_CONTAINER")
	if type(kc) == "number" and not Cap.IsBankTabSentinel(kc) then
		Cap.keyringBagId = kc
	else
		Cap.keyringBagId = nil
	end
	if not Cap.keyringBagId and Enum and Enum.BagIndex and Enum.BagIndex.Keyring
		and not Cap.IsBankTabSentinel(Enum.BagIndex.Keyring) then
		Cap.keyringBagId = Enum.BagIndex.Keyring
	end
	local n = 0
	if Cap.keyringBagId then
		local fn = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
		if fn then
			local ok, slots = pcall(fn, Cap.keyringBagId)
			if ok and type(slots) == "number" and slots > 0 then
				n = slots
			end
		end
	end
	Cap.hasKeyringContainer = n > 0
	return Cap.hasKeyringContainer
end

function Cap.HasVoidStorage()
	return type(CanUseVoidStorage) == "function" and type(GetVoidItemInfo) == "function"
end

function Cap.HasGuildBank()
	return type(GetGuildBankItemLink) == "function" and type(GetNumGuildBankTabs) == "function"
end

function Cap.HasAuctionHouse()
	if C_AuctionHouse ~= nil then
		return true
	end
	if type(GetNumAuctionItems) == "function" then
		return true
	end
	return rawget(_G, "AuctionHouseFrame") ~= nil or rawget(_G, "AuctionFrame") ~= nil
end

function Cap.HasLegacyAuctionHouse()
	if Client.isEra then
		return true
	end
	local fn = rawget(_G, "IsUsingLegacyAuctionClient")
	if type(fn) == "function" then
		local ok, legacy = pcall(fn)
		if ok and legacy then
			return true
		end
	end
	if C_AuctionHouse ~= nil then
		return false
	end
	return type(GetNumAuctionItems) == "function"
end

function Cap.RefreshInventoryCaps()
	Cap.hasVoidStorage = Cap.HasVoidStorage()
	Cap.hasGuildBank = Cap.HasGuildBank()
	Cap.hasAuctionHouse = Cap.HasAuctionHouse()
	Cap.hasLegacyAuctionHouse = Cap.HasLegacyAuctionHouse()
	Cap.hasModernAuctionHouse = (not Cap.hasLegacyAuctionHouse) and C_AuctionHouse ~= nil
	Cap.hasCurrencyTokens = ClientHasCharacterCurrencyTab() and true or false
	return Cap.hasAuctionHouse
end

function Cap.RefreshCharacterInfo()
	Cap.hasClassicPaperDollAttributes = rawget(_G, "CharacterAttributesFrame") ~= nil
	local pane = rawget(_G, "CharacterStatsPane")
	Cap.hasRetailCharacterStatsPane = pane ~= nil and pane.statsFramePool ~= nil
	Cap.hasForeverStatsScrollBox = rawget(_G, "CharacterStatsPaneScrollBox") ~= nil
	Cap.hasHelmCloakDisplay = type(ShowHelm) == "function"
		and type(ShowCloak) == "function"
		and type(ShowingHelm) == "function"
		and type(ShowingCloak) == "function"
	local head = rawget(_G, "CharacterHeadSlot")
	Cap.hasPaperDollQualityBorder = head ~= nil and head.IconBorder ~= nil
	Cap.hasAverageItemLevel = type(GetAverageItemLevel) == "function"
	local pd = rawget(_G, "C_PaperDollInfo")
	Cap.hasCursorCanGoInSlot = type(pd) == "table" and type(pd.CanCursorCanGoInSlot) == "function"
	Cap.hasCursorCanGoInSlotCamelot = type(pd) == "table" and type(pd.CursorCanGoInSlot) == "function"
	return Cap.hasClassicPaperDollAttributes or Cap.hasRetailCharacterStatsPane or Cap.hasForeverStatsScrollBox
end

Cap.hasCharacterCurrencyTab = ClientHasCharacterCurrencyTab() and true or false
Cap.canOpenCharacterCurrencyPanel = Cap.hasCharacterCurrencyTab and (ToggleCharacter ~= nil)
Cap.hasAssistedCombat = Cap.ClientSupportsSingleButtonAssistant()
Cap.hasCombatAmmo = Cap.ClientSupportsCombatAmmoExtraButton()
Cap.hasUnitThreatLeadSituation = type(UnitThreatLeadSituation) == "function"
Cap.hasUnitThreatPercentageOfLead = type(UnitThreatPercentageOfLead) == "function"
Cap.hasNameplateThreatDisplayCVar = C_CVar ~= nil and C_CVar.GetCVar ~= nil
	and C_CVar.GetCVar("nameplateThreatDisplay") ~= nil

Cap.RefreshFocusUnit()
Cap.RefreshUnifiedBank()
Cap.RefreshKeyring()
Cap.RefreshInventoryCaps()
Cap.RefreshCharacterInfo()

--- Forever with the gamepad HUD on. Its panels, bags and bindings end in the
--- protected SetPreferredGamepadInteractTarget(), so FluxUI code must not run
--- inside them or write state they read.
function Cap.IsForeverGamepadUI()
	return Client.isCamelot == true and Cap.IsGamepadUIEnabled()
end
_G.FluxUI_IsForeverGamepadUI = Cap.IsForeverGamepadUI

-- Bag and quest-tracker hooks are chosen at load. The Settings toggle switches
-- the style live, and those hooks cannot be removed, so ask for a reload.
-- Our own frame: never InputUtil's transition list.
Cap.foreverGamepadAtLoad = Cap.IsForeverGamepadUI()
if Client.isCamelot then
	local styleWatch = CreateFrame("Frame")
	local told = false
	pcall(styleWatch.RegisterEvent, styleWatch, "INPUT_DEVICE_INTERFACE_TRANSITION")
	styleWatch:SetScript("OnEvent", function()
		if told or Cap.IsForeverGamepadUI() == Cap.foreverGamepadAtLoad then
			return
		end
		told = true
		Flux.Print("Gamepad UI changed. Type /reload so FluxUI's bag and quest tracker handling matches it.")
	end)
end

-- Classic stubs can appear after SharedXML finishes.
Flux.AfterLogin(function()
	Cap.RefreshFocusUnit()
	Cap.RefreshUnifiedBank()
	Cap.RefreshKeyring()
	Cap.RefreshInventoryCaps()
	Cap.RefreshCharacterInfo()
	Cap.hasCharacterCurrencyTab = ClientHasCharacterCurrencyTab() and true or false
	Cap.canOpenCharacterCurrencyPanel = Cap.hasCharacterCurrencyTab and (ToggleCharacter ~= nil)
	Cap.hasAssistedCombat = Cap.ClientSupportsSingleButtonAssistant()
	Cap.hasCombatAmmo = Cap.ClientSupportsCombatAmmoExtraButton()
	Cap.hasUnitThreatLeadSituation = type(UnitThreatLeadSituation) == "function"
	Cap.hasUnitThreatPercentageOfLead = type(UnitThreatPercentageOfLead) == "function"
	Cap.hasNameplateThreatDisplayCVar = C_CVar ~= nil and C_CVar.GetCVar ~= nil
		and C_CVar.GetCVar("nameplateThreatDisplay") ~= nil
end)
