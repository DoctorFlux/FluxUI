-- Capabilities.lua — FLUX_API flags and capability probes (modern clients only)
local addonName, ns = ...
local H = ns._FluxAPICompat
local _pcall = H.pcall
local _type = H.type

local isRetail = FLUX_API.isRetail
local isCamelot = FLUX_API.isCamelot
local isClassicEra = FLUX_API.isClassicEra
local isTBC = FLUX_API.isTBC
local isWrath = FLUX_API.isWrath
local isCata = FLUX_API.isCata
local isMists = FLUX_API.isMists
local isPreDF = FLUX_API.isPreDF
local isPostDF = FLUX_API.isPostDF
local majorVersion = FLUX_API.majorVersion
local _issecretvalue = H.issecretvalue

-- Consumer-facing API detection flags (subset only).
FLUX_API.hasC_Spell = (C_Spell ~= nil)
FLUX_API.hasC_Item = (C_Item ~= nil)
FLUX_API.hasC_Container = (C_Container ~= nil)
FLUX_API.hasC_ActionBar = (C_ActionBar ~= nil)
FLUX_API.hasC_UnitAuras = (C_UnitAuras ~= nil)
FLUX_API.hasC_UnitAuras_GetAuraSlots = (C_UnitAuras ~= nil and C_UnitAuras.GetAuraSlots ~= nil)
FLUX_API.hasC_UnitAuras_GetAuraDataBySlot = (C_UnitAuras ~= nil and C_UnitAuras.GetAuraDataBySlot ~= nil)
FLUX_API.hasC_UnitAuras_GetAuraDataByAuraInstanceID = (C_UnitAuras ~= nil and C_UnitAuras.GetAuraDataByAuraInstanceID ~= nil)
FLUX_API.hasC_UnitAuras_GetAuraDataByIndex = (C_UnitAuras ~= nil and C_UnitAuras.GetAuraDataByIndex ~= nil)
FLUX_API.hasC_UnitAuras_GetAuraDuration = (C_UnitAuras ~= nil and C_UnitAuras.GetAuraDuration ~= nil)
FLUX_API.hasC_UnitAuras_GetPlayerAuraBySpellID = (C_UnitAuras ~= nil and C_UnitAuras.GetPlayerAuraBySpellID ~= nil)
FLUX_API.hasC_UnitAuras_GetCooldownAuraBySpellID = (C_UnitAuras ~= nil and C_UnitAuras.GetCooldownAuraBySpellID ~= nil)
FLUX_API.hasC_UnitAuras_GetAuraApplicationDisplayCount = (C_UnitAuras ~= nil and C_UnitAuras.GetAuraApplicationDisplayCount ~= nil)
FLUX_API.hasC_UnitAuras_GetAuraDispelTypeColor = (C_UnitAuras ~= nil and C_UnitAuras.GetAuraDispelTypeColor ~= nil)
FLUX_API.hasC_UnitAuras_GetRefreshExtendedDuration = (C_UnitAuras ~= nil and C_UnitAuras.GetRefreshExtendedDuration ~= nil)
FLUX_API.hasC_UnitAuras_GetAuraBaseDuration = (C_UnitAuras ~= nil and C_UnitAuras.GetAuraBaseDuration ~= nil)
FLUX_API.hasSecretValueAPI = (_issecretvalue ~= nil)
FLUX_API.hasCanAccessValue = (canaccessvalue ~= nil)
FLUX_API.hasEditMode = (C_EditMode ~= nil) and (EditModeManagerFrame ~= nil)
FLUX_API.hasToyBox = (C_ToyBox ~= nil) and (C_ToyBox.GetToyInfo ~= nil) and (PlayerHasToy ~= nil)
FLUX_API.hasC_MountJournal = (C_MountJournal ~= nil)
FLUX_API.hasToggleCollectionsJournal = (ToggleCollectionsJournal ~= nil)
FLUX_API.hasC_Timer_NewTicker = (C_Timer ~= nil and C_Timer.NewTicker ~= nil)
FLUX_API.hasBackdropTemplateMixin = (BackdropTemplateMixin ~= nil)
FLUX_API.hasSecureActionButtonTemplate = (SecureActionButtonTemplate ~= nil)
FLUX_API.hasC_AddOns = (C_AddOns ~= nil)
FLUX_API.hasC_AddOns_IsAddOnLoaded = (C_AddOns ~= nil and C_AddOns.IsAddOnLoaded ~= nil)
FLUX_API.hasHelpTip_Show = (HelpTip ~= nil and HelpTip.Show ~= nil)
FLUX_API.hasC_CurveUtil_CreateColorCurve = (C_CurveUtil ~= nil and C_CurveUtil.CreateColorCurve ~= nil)
FLUX_API.hasTalentTreeSpec = (GetSpecialization == nil and GetTalentTabInfo ~= nil)
FLUX_API.hasInspectTalents = (NotifyInspect ~= nil and GetTalentTabInfo ~= nil)
FLUX_API.hasGetBackpackCurrencyInfo = (C_CurrencyInfo ~= nil and C_CurrencyInfo.GetBackpackCurrencyInfo ~= nil)
FLUX_API.hasGetCurrencyListSize = (type(GetCurrencyListSize) == "function")
FLUX_API.hasC_PetJournal = (C_PetJournal ~= nil)
FLUX_API.hasC_SpellActivationOverlay = (C_SpellActivationOverlay ~= nil)

do
    local testFrame = CreateFrame("Frame")
    local okTarget = _pcall(function()
        testFrame:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_TARGET", "player")
    end)
    local okClear = _pcall(function()
        testFrame:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_CLEAR", "player")
    end)
    local valid = true
    if C_EventUtils and C_EventUtils.IsEventValid then
        valid = C_EventUtils.IsEventValid("UNIT_SPELLCAST_RETICLE_TARGET")
            and C_EventUtils.IsEventValid("UNIT_SPELLCAST_RETICLE_CLEAR")
    end
    FLUX_API.hasUnitSpellcastReticleEvents = isPostDF and valid and okTarget and okClear
    _pcall(function() testFrame:UnregisterAllEvents() end)
end
ns.API.hasUnitSpellcastReticleEvents = FLUX_API.hasUnitSpellcastReticleEvents

FLUX_API.auraDebuffBorderWidth = isPreDF and 33 or 40
FLUX_API.auraDebuffBorderHeight = isPreDF and 32 or 40
FLUX_API.actionBarPushedTextureMatchNormalPreDF = isRetail and isPreDF
FLUX_API.actionBarPushedTextureProportionalDF = isRetail and isPostDF
FLUX_API.skipFluxThreatMeterLayouts = isRetail and isPostDF and not isCamelot
FLUX_API.hasBlizzardObjectiveTrackerScroll = isRetail and isPostDF
do
	local Cap = ns.Flux and ns.Flux.Cap
	FLUX_API.disableSwingTimer = ((isRetail and isPostDF) and not isCamelot) or isCata or isMists
	FLUX_API.hasSwingTimer = not FLUX_API.disableSwingTimer
	if Cap then
		FLUX_API.hasCombatLogUnfiltered = Cap.hasCombatLogUnfiltered and true or false
		FLUX_API.hasDurationUtil = Cap.hasDurationUtil and true or false
		FLUX_API.hasStatusBarTimerDuration = Cap.hasStatusBarTimerDuration and true or false
		FLUX_API.hasRestrictedClosures = Cap.hasRestrictedClosures ~= false
		FLUX_API.hasNativePlayerSwing = Cap.hasNativePlayerSwing and true or false
	else
		FLUX_API.hasCombatLogUnfiltered = false
		FLUX_API.hasDurationUtil = C_DurationUtil ~= nil and type(C_DurationUtil.CreateDuration) == "function"
		local testBar = CreateFrame("StatusBar")
		FLUX_API.hasStatusBarTimerDuration = type(testBar.SetTimerDuration) == "function"
		FLUX_API.hasRestrictedClosures = not (FLUX_API.isCamelot == true)
		FLUX_API.hasNativePlayerSwing = C_SwingTimer ~= nil
			and type(C_SwingTimer.EnableRangeCheck) == "function"
			and type(C_SwingTimer.IsTargetWithinSwingRange) == "function"
			and Enum ~= nil
			and Enum.PlayerSwingType ~= nil
			and Enum.PlayerSwingType.MainHand ~= nil
			and Enum.PlayerSwingType.Ranged ~= nil
	end
end
FLUX_API.avoidAddonForcedBuffFrameUpdate = isRetail and FLUX_API.hasSecretValueAPI == true
FLUX_API.useLibButtonGlowPagingCompat = (not FLUX_API.hasC_SpellActivationOverlay) or FLUX_API.isAnyClassic
FLUX_API.hasQuickJoinToastButton = (QuickJoinToastButton ~= nil)

function ns.API.GetMaxBagIndex()
    if NUM_BAG_SLOTS then return NUM_BAG_SLOTS end
    return isRetail and 5 or 4
end

function ns.API.hasBlizzardSettingsKeybindings()
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.HasBlizzardSettingsKeybindings then
        return Cap.HasBlizzardSettingsKeybindings()
    end
    return Settings ~= nil
        and KeybindingsOverrides ~= nil
        and type(KeybindingsOverrides.AddBindingCategories) == "function"
end

function ns.API.hasBlizzardActionBarsOverrides()
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.HasBlizzardActionBarsOverrides then
        return Cap.HasBlizzardActionBarsOverrides()
    end
    return ActionBarsOverrides ~= nil
        and type(ActionBarsOverrides.CreateActionBarVisibilitySettings) == "function"
end

function ns.API.GetFluxBlizzardActionBarUIMode()
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.GetFluxBlizzardActionBarUIMode then
        return Cap.GetFluxBlizzardActionBarUIMode()
    end
    if not ns.API.hasBlizzardSettingsKeybindings() then
        return "unsupported"
    end
    if isRetail then
        return "mainline"
    end
    local isMists = FLUX_API and FLUX_API.isMists
    if isClassicEra or isTBC or isWrath or isCata or isMists then
        return "classic_style"
    end
    return "unsupported"
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
    if isClassicEra then
        return false
    end
    if type(ExpandCurrencyList) == "function" and type(GetCurrencyListSize) == "function" then
        return true
    end
    return false
end

function FLUX_API.HasUnifiedBankUI()
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.HasUnifiedBankUI then
        return Cap.HasUnifiedBankUI()
    end
    if not (isRetail and isPostDF) then
        return false
    end
    if C_Bank and type(C_Bank.FetchPurchasedBankTabIDs) == "function" then
        return true
    end
    return type(rawget(_G, "BankPanelMixin")) == "table"
        and type(rawget(_G, "BankPanelItemButtonMixin")) == "table"
end
ns.API.HasUnifiedBankUI = FLUX_API.HasUnifiedBankUI

function FLUX_API.UseLegacyBankSlotsUI()
    return not FLUX_API.HasUnifiedBankUI()
end
ns.API.UseLegacyBankSlotsUI = FLUX_API.UseLegacyBankSlotsUI

function FLUX_API.UsesPlayerBagsInBank()
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.UsesPlayerBagsInBank then
        return Cap.UsesPlayerBagsInBank()
    end
    if not FLUX_API.HasUnifiedBankUI() then
        return false
    end
    if C_Bank and type(C_Bank.ShouldUsePlayerBagsInBank) == "function" then
        local ok, use = _pcall(C_Bank.ShouldUsePlayerBagsInBank)
        if ok then
            return use and true or false
        end
    end
    return isCamelot == true
end
ns.API.UsesPlayerBagsInBank = FLUX_API.UsesPlayerBagsInBank

function FLUX_API.HasReagentBankContainer()
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.HasReagentBankContainer then
        return Cap.HasReagentBankContainer()
    end
    local id = rawget(_G, "REAGENTBANK_CONTAINER")
    if type(id) ~= "number" then
        return false
    end
    local sentinel = Enum and Enum.BagIndex and Enum.BagIndex.Accountbanktab
    return id ~= sentinel
end
ns.API.HasReagentBankContainer = FLUX_API.HasReagentBankContainer

function FLUX_API.GetReagentBankContainerID()
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.GetReagentBankContainerID then
        return Cap.GetReagentBankContainerID()
    end
    if not FLUX_API.HasReagentBankContainer() then
        return nil
    end
    return _G.REAGENTBANK_CONTAINER
end
ns.API.GetReagentBankContainerID = FLUX_API.GetReagentBankContainerID

function FLUX_API.EnumerateBankTabIDs(bankType)
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.EnumerateBankTabIDs then
        return Cap.EnumerateBankTabIDs(bankType)
    end
    return {}
end
ns.API.EnumerateBankTabIDs = FLUX_API.EnumerateBankTabIDs

function FLUX_API.IsBankTabSentinel(bag)
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.IsBankTabSentinel then
        return Cap.IsBankTabSentinel(bag)
    end
    bag = tonumber(bag)
    if not bag then
        return false
    end
    local idx = Enum and Enum.BagIndex
    return idx ~= nil and (bag == idx.Characterbanktab or bag == idx.Accountbanktab)
end
ns.API.IsBankTabSentinel = FLUX_API.IsBankTabSentinel

function FLUX_API.IsUnifiedBankTabBag(bag)
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.IsUnifiedBankTabBag then
        return Cap.IsUnifiedBankTabBag(bag)
    end
    return false
end
ns.API.IsUnifiedBankTabBag = FLUX_API.IsUnifiedBankTabBag

function H.RefreshUnifiedBankUIFlags()
    local Cap = ns.Flux and ns.Flux.Cap
    if Cap and Cap.RefreshUnifiedBank then
        Cap.RefreshUnifiedBank()
    end
    local unified = FLUX_API.HasUnifiedBankUI()
    FLUX_API.hasUnifiedBankUI = unified
    FLUX_API.useLegacyBankSlotsUI = not unified
    FLUX_API.usesPlayerBagsInBank = FLUX_API.UsesPlayerBagsInBank()
    FLUX_API.hasReagentBankContainer = FLUX_API.HasReagentBankContainer()
    ns.API.hasUnifiedBankUI = unified
    ns.API.useLegacyBankSlotsUI = FLUX_API.useLegacyBankSlotsUI
    ns.API.usesPlayerBagsInBank = FLUX_API.usesPlayerBagsInBank
    ns.API.hasReagentBankContainer = FLUX_API.hasReagentBankContainer
end
H.RefreshUnifiedBankUIFlags()

FLUX_API.hasCharacterCurrencyList = (FLUX_API.hasGetBackpackCurrencyInfo or FLUX_API.hasGetCurrencyListSize) and true or false
FLUX_API.hasCharacterCurrencyTab = ClientHasCharacterCurrencyTab() and true or false
ns.API.hasCharacterCurrencyTab = FLUX_API.hasCharacterCurrencyTab
FLUX_API.canOpenCharacterCurrencyPanel = FLUX_API.hasCharacterCurrencyTab and (ToggleCharacter ~= nil)

function FLUX_API.HasCompactRaidFrameManager()
    return type(rawget(_G, "CompactRaidFrameManager")) == "table"
end
ns.API.HasCompactRaidFrameManager = FLUX_API.HasCompactRaidFrameManager

function FLUX_API.IsAssistedCombatLabButton(button)
    if type(button) ~= "table" or button._state_type ~= "action" then
        return false
    end
    local slot = button._state_action
    if type(slot) ~= "number" then
        return false
    end
    if not (C_ActionBar and C_ActionBar.IsAssistedCombatAction) then
        return false
    end
    return C_ActionBar.IsAssistedCombatAction(slot) and true or false
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
        local ok = _pcall(function()
            test:RegisterUnitEvent("UNIT_HEALTH", "focus")
        end)
        test:UnregisterAllEvents()
        if not ok then
            has = true
        end
    end
    return has and true or false
end

FLUX_API.hasFocusUnit = ComputeFocusUnitCapability()
ns.API.hasFocusUnit = FLUX_API.hasFocusUnit

function FLUX_API.RefreshFocusUnitCapability()
    local v = ComputeFocusUnitCapability()
    FLUX_API.hasFocusUnit = v
    ns.API.hasFocusUnit = v
    return v
end
ns.API.RefreshFocusUnitCapability = FLUX_API.RefreshFocusUnitCapability

do
    local kc = rawget(_G, "KEYRING_CONTAINER")
    FLUX_API.keyringBagId = (type(kc) == "number") and kc or nil
    function FLUX_API.RefreshKeyringContainerState()
        local n = 0
        if FLUX_API.keyringBagId and (GetContainerNumSlots or (C_Container and C_Container.GetContainerNumSlots)) then
            local fn = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
            local ok, slots = _pcall(fn, FLUX_API.keyringBagId)
            if ok and type(slots) == "number" and slots > 0 then
                n = slots
            end
        end
        FLUX_API.hasKeyringContainer = n > 0
    end
    FLUX_API.RefreshKeyringContainerState()
end

function FLUX_API.ClientSupportsCombatAmmoExtraButton()
    local pd = rawget(_G, "C_PaperDollInfo")
    if type(pd) == "table" and type(pd.IsRangedSlotShown) == "function" then
        local ok, shown = _pcall(pd.IsRangedSlotShown)
        if ok then
            return shown and true or false
        end
    end
    local fn = rawget(_G, "GetInventorySlotInfo")
    if type(fn) ~= "function" then
        return false
    end
    local function slotNumber(token)
        local ok, slot = _pcall(fn, token)
        return ok and type(slot) == "number"
    end
    return slotNumber("AmmoSlot") or slotNumber("RangedSlot")
end

function FLUX_API.ClientSupportsSingleButtonAssistant()
    if majorVersion < 10 then
        return false
    end
    return C_AssistedCombat ~= nil
end

function FLUX_API.ApplyAssistedCombatCustomActionBarCompat()
    -- Disabled: hooksecurefunc AssistedCombatManager.OnUpdate + EventRegistry under
    -- _FluxUI has no Settings link, but keep retail Core free of Blizzard framework hooks.
    return
end
ns.API.ApplyAssistedCombatCustomActionBarCompat = FLUX_API.ApplyAssistedCombatCustomActionBarCompat

FLUX_API.canOpenMountCollection = (C_MountJournal ~= nil)
FLUX_API.canOpenCompanionMounts = (GetNumCompanions ~= nil and type(GetNumCompanions) == "function")

_G.FluxProcGlowCompatEnableLabOverlay = true
