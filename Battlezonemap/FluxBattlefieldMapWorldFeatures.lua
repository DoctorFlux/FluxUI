-- FluxBattlefieldMapWorldFeatures.lua
-- Mirrors World Map data providers (Blizzard layers + third-party addon pins) onto the
-- embedded BattlefieldMapFrame. Addons that only register on WorldMapFrame are cloned
-- onto the battlefield map while the feature is enabled.
--
-- Limitations:
--   - Addons that parent frames directly to WorldMapFrame (not AddDataProvider) are not mirrored.
--   - Some exotic custom providers may fail to clone cleanly.

local addonName, addonTable = ...

FluxBattlefieldMapWorldFeatures = {}

local SAVED_VAR_KEY = "fluxBattlefieldWorldMapFeatures"
local TOGGLE_LABEL = "Map Pins"

local MAP_ADDON_LOAD_ORDER = {
    "Blizzard_MapCanvas",
    "Blizzard_SharedMapDataProviders",
    "Blizzard_HelpPlate",
    "Blizzard_BattlefieldMap",
    "Blizzard_WorldMap",
}

local MAP_ADDON_RELOAD_NAMES = {
    Blizzard_MapCanvas = true,
    Blizzard_SharedMapDataProviders = true,
    Blizzard_BattlefieldMap = true,
    Blizzard_WorldMap = true,
}

local state = {
    isActive = false,
    hooksInstalled = false,
    standardProvidersApplied = false,
    pendingActivate = false,
    pendingDeactivate = false,
    pendingCanvasRefresh = false,
    pendingCanvasRefreshFull = false,
    parentFrame = nil,
    lastDepFailure = nil,
    canMirror = false,
}

-- worldProvider -> battlefield clone
local worldToBattlefield = {}
-- providers added by WorldMapMixin.AddStandardDataProviders (not pre-existing on battlefield)
local addedStandardProviders = {}
local shadowWrappedProviders = {}

local ProviderHasValidMap
local SafeProviderMethod

local function SecureCall(func, ...)
    if not func then
        return
    end
    if securecall then
        return securecall(func, ...)
    end
    return func(...)
end

local function IsHBDWorldProvider(provider)
    if not provider then
        return false
    end
    if FluxBattlefieldMapPinRouter and FluxBattlefieldMapPinRouter.IsHBDWorldProvider then
        return FluxBattlefieldMapPinRouter:IsHBDWorldProvider(provider)
    end
    if not LibStub then
        return false
    end
    for _, libName in ipairs({
        "HereBeDragonsQuestie-Pins-2.0",
        "HereBeDragons-Pins-2.0",
    }) do
        local ok, pins = pcall(LibStub, libName, true)
        if ok and pins and pins.worldmapProvider == provider then
            return true
        end
    end
    return false
end

local function UnwrapProviderRefreshShadow(worldProvider)
    if not worldProvider or not worldProvider._fluxOrigRefreshAllData then
        return
    end
    worldProvider.RefreshAllData = worldProvider._fluxOrigRefreshAllData
    worldProvider._fluxOrigRefreshAllData = nil
    shadowWrappedProviders[worldProvider] = nil
end

ProviderHasValidMap = function(provider)
    if not provider or not provider.GetMap then
        return false
    end
    return provider:GetMap() ~= nil
end

SafeProviderMethod = function(provider, method, ...)
    if not provider or not provider[method] then
        return
    end
    if not ProviderHasValidMap(provider) then
        return
    end
    -- Calling Blizzard RefreshAllData/OnEvent under Flux taint in combat →
    -- AcquirePin → SetPassThroughButtons ADDON_ACTION_BLOCKED.
    if (method == "RefreshAllData" or method == "OnEvent" or method == "SignalEvent")
        and InCombatLockdown and InCombatLockdown() then
        return
    end
    pcall(SecureCall, provider[method], provider, ...)
end

-- Providers inserted via addon AddDataProvider are marked insecure in dataProviders.
-- MapCanvas secureexecuterange then runs their methods under Flux taint; Blizzard
-- RefreshAllData that ipairs() secret map tables errors with a secret stack.
-- ADDON_ACTION_BLOCKED (SetPassThroughButtons) is an event — pcall cannot catch it —
-- so pin-acquiring paths must no-op while InCombatLockdown.
local FLUX_PROVIDER_HARDEN_METHODS = {
    "RefreshAllData",
    "OnEvent",
    "SignalEvent",
    "RemoveAllData",
    "OnMapChanged",
    "OnShow",
    "OnHide",
}

local FLUX_PROVIDER_COMBAT_SKIP = {
    RefreshAllData = true,
    OnEvent = true,
    SignalEvent = true,
}

local function HardenFluxDataProvider(provider)
    if not provider or provider._fluxTaintHardened then
        return
    end
    provider._fluxTaintHardened = true
    for _, methodName in ipairs(FLUX_PROVIDER_HARDEN_METHODS) do
        local orig = provider[methodName]
        if type(orig) == "function" then
            local origKey = "_fluxOrig_" .. methodName
            if not provider[origKey] then
                provider[origKey] = orig
                local skipInCombat = FLUX_PROVIDER_COMBAT_SKIP[methodName]
                provider[methodName] = function(self, ...)
                    if skipInCombat and InCombatLockdown and InCombatLockdown() then
                        return
                    end
                    local ok, a, b, c, d = pcall(orig, self, ...)
                    if ok then
                        return a, b, c, d
                    end
                end
            end
        end
    end
end

local function IsSecretTableClient()
    if FLUX_API and FLUX_API.isV12 then
        return true
    end
    return canaccesstable ~= nil or issecrettable ~= nil
end

local function WrapProviderRefreshShadow(worldProvider, clone)
    if shadowWrappedProviders[worldProvider] or not worldProvider.RefreshAllData then
        return
    end
    local origRefresh = worldProvider.RefreshAllData
    worldProvider._fluxOrigRefreshAllData = origRefresh
    shadowWrappedProviders[worldProvider] = clone
    worldProvider.RefreshAllData = function(self, fromOnShow)
        if InCombatLockdown and InCombatLockdown() then
            -- Avoid tainted AcquirePin → SetPassThroughButtons while locked down.
            if FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield() then
                SafeProviderMethod(self, "RemoveAllData")
            end
            return
        end
        if FluxBattlefieldMapPinRouter and FluxBattlefieldMapPinRouter.ShouldRouteToBattlefield
            and FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield() then
            SafeProviderMethod(clone, "RefreshAllData", fromOnShow)
            SafeProviderMethod(self, "RemoveAllData")
        else
            pcall(SecureCall, origRefresh, self, fromOnShow)
            SafeProviderMethod(clone, "RemoveAllData")
        end
    end
end

local function UnwrapAllShadowProviders()
    for worldProvider in pairs(shadowWrappedProviders) do
        UnwrapProviderRefreshShadow(worldProvider)
    end
    table.wipe(shadowWrappedProviders)
end

local toggleHoverZone = nil
local toggleFrame = nil
local toggleCheck = nil
local toggleCombatFrame = nil
local toggleHideGeneration = 0

local function AddonExists(name)
    if C_AddOns and C_AddOns.DoesAddOnExist then
        return C_AddOns.DoesAddOnExist(name)
    end
    if GetAddOnInfo then
        local _, _, _, enabled = GetAddOnInfo(name)
        return enabled ~= nil
    end
    return true
end

local function LoadAddon(name)
    if not AddonExists(name) then
        return true
    end

    if C_AddOns and C_AddOns.IsAddOnLoaded then
        if C_AddOns.IsAddOnLoaded(name) then
            return true
        end
        if C_AddOns.LoadAddOn then
            local loaded = C_AddOns.LoadAddOn(name)
            return loaded and true or false
        end
    elseif IsAddOnLoaded then
        if IsAddOnLoaded(name) then
            return true
        end
        if LoadAddOn then
            local loaded = LoadAddOn(name)
            return loaded and true or false
        end
    end
    return false
end

local function HasMapCanvasAPI()
    return CreateFromMixins ~= nil
end

local function GetClientLabel()
    if FLUX_API and FLUX_API.isRetail then
        return "Retail"
    end
    if FLUX_API and FLUX_API.isClassicEra then
        return "ClassicEra"
    end
    if FLUX_API and FLUX_API.isAnyClassic then
        return "Classic"
    end
    return "Unknown"
end

local function EnsureDependencies()
    state.lastDepFailure = nil
    state.canMirror = false

    if not HasMapCanvasAPI() then
        state.lastDepFailure = "CreateFromMixins"
        return false
    end

    for _, addonName in ipairs(MAP_ADDON_LOAD_ORDER) do
        if not LoadAddon(addonName) then
            state.lastDepFailure = addonName
            return false
        end
    end

    if not _G.BattlefieldMapFrame then
        state.lastDepFailure = "BattlefieldMapFrame"
        return false
    end
    if not _G.WorldMapFrame then
        state.lastDepFailure = "WorldMapFrame"
        return false
    end
    if not MapCanvasMixin or not MapCanvasDataProviderMixin then
        state.lastDepFailure = "MapCanvasMixins"
        return false
    end

    state.canMirror = true
    state.lastDepFailure = nil
    return true
end

local function CanMirrorProviders()
    if state.canMirror then
        return true
    end
    return EnsureDependencies()
end

local function GetBattlefieldMap()
    if FluxBattlefieldMap and FluxBattlefieldMap.GetMapFrame then
        return FluxBattlefieldMap:GetMapFrame()
    end
    return _G.BattlefieldMapFrame
end

local function GetWorldAddStandardProviders()
    if WorldMapMixin and WorldMapMixin.AddStandardDataProviders then
        return WorldMapMixin.AddStandardDataProviders
    end
    if WorldMapFrame and WorldMapFrame.AddStandardDataProviders then
        return WorldMapFrame.AddStandardDataProviders
    end
    return nil
end

function FluxBattlefieldMapWorldFeatures:IsEnabled()
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end
    return _FluxUI_CharSavedVars[SAVED_VAR_KEY] ~= false
end

local function UpdateToggleVisual()
    if not toggleCheck then
        return
    end
    local mirrorReady = CanMirrorProviders()
    if mirrorReady then
        toggleCheck:SetAlpha(1)
        if toggleCheck.text then
            toggleCheck.text:SetAlpha(1)
        end
    else
        toggleCheck:SetAlpha(0.55)
        if toggleCheck.text then
            toggleCheck.text:SetAlpha(0.55)
        end
    end
end

function FluxBattlefieldMapWorldFeatures:SetEnabled(enabled)
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end
    _FluxUI_CharSavedVars[SAVED_VAR_KEY] = enabled and true or false
    if toggleCheck then
        toggleCheck:SetChecked(enabled)
        UpdateToggleVisual()
    end
    if state.isActive then
        if enabled then
            self:Activate()
        else
            self:Deactivate()
        end
    end
end

local function IsDuplicateProvider(mapFrame, dataProvider)
    if not mapFrame or not mapFrame.dataProviders or not dataProvider then
        return false
    end
    for old in pairs(mapFrame.dataProviders) do
        if old == dataProvider then
            return true
        end
        local sameType = true
        for k, v in pairs(MapCanvasDataProviderMixin) do
            if type(v) == "function" and old[k] ~= dataProvider[k] then
                sameType = false
                break
            end
        end
        if sameType then
            return true
        end
    end
    return false
end

local function IsAreaLabelDataProvider(provider)
    return provider
        and AreaLabelDataProviderMixin
        and provider.GetOffsetY == AreaLabelDataProviderMixin.GetOffsetY
        and provider.SetOffsetY == AreaLabelDataProviderMixin.SetOffsetY
end

local function IsContentTrackingDataProvider(provider)
    return provider
        and ContentTrackingDataProviderMixin
        and provider.GetPinTemplate == ContentTrackingDataProviderMixin.GetPinTemplate
end

-- Flux-created clones of EncounterJournalDataProvider run OnEvent via MapCanvas
-- secureexecuterange as Flux-tainted execution. AcquirePin → SetPassThroughButtons
-- then ADDON_ACTION_BLOCKED in combat. Do not mirror this provider onto BattlefieldMap.
local function IsEncounterJournalDataProvider(provider)
    if not provider or not EncounterJournalDataProviderMixin then
        return false
    end
    local m = EncounterJournalDataProviderMixin
    local refresh = provider._fluxOrig_RefreshAllData or provider.RefreshAllData
    if refresh == m.RefreshAllData then
        return true
    end
    local onEvent = provider._fluxOrig_OnEvent or provider.OnEvent
    if onEvent == m.OnEvent then
        return true
    end
    local remove = provider._fluxOrig_RemoveAllData or provider.RemoveAllData
    if remove == m.RemoveAllData then
        return true
    end
    return false
end

local QUEST_OVERLAY_PIN_TEMPLATES = {
    QuestPinTemplate = true,
    QuestBlobPinTemplate = true,
    WorldQuestPinTemplate = true,
    WorldMap_WorldQuestPinTemplate = true,
    BonusObjectivePinTemplate = true,
    ThreatObjectivePinTemplate = true,
    SuperTrackWaypointPinTemplate = true,
    WaypointLocationPinTemplate = true,
}

local QUEST_OVERLAY_MIXIN_NAMES = {
    "QuestDataProviderMixin",
    "QuestBlobDataProviderMixin",
    "WorldQuestDataProviderMixin",
    "WorldMap_WorldQuestDataProviderMixin",
    "BonusObjectiveDataProviderMixin",
    "SuperTrackWaypointDataProviderMixin",
    "WaypointLocationDataProviderMixin",
}

local function ProviderMethod(provider, methodName)
    if not provider then
        return nil
    end
    return provider["_fluxOrig_" .. methodName] or provider[methodName]
end

local function IsQuestOverlayOwnedProvider(provider)
    if not provider then
        return false
    end
    local getTemplate = ProviderMethod(provider, "GetPinTemplate")
    if type(getTemplate) == "function" then
        local ok, template = pcall(getTemplate, provider)
        if ok and QUEST_OVERLAY_PIN_TEMPLATES[template] then
            return true
        end
    end
    local base = MapCanvasDataProviderMixin
    local baseRefresh = base and base.RefreshAllData
    local baseRemove = base and base.RemoveAllData
    local baseOnAdded = base and base.OnAdded
    for _, mixinName in ipairs(QUEST_OVERLAY_MIXIN_NAMES) do
        local mixin = _G[mixinName]
        if mixin then
            if mixin.RefreshAllData and mixin.RefreshAllData ~= baseRefresh
                and ProviderMethod(provider, "RefreshAllData") == mixin.RefreshAllData then
                return true
            end
            if mixin.RemoveAllData and mixin.RemoveAllData ~= baseRemove
                and ProviderMethod(provider, "RemoveAllData") == mixin.RemoveAllData then
                return true
            end
            if mixin.OnAdded and mixin.OnAdded ~= baseOnAdded
                and ProviderMethod(provider, "OnAdded") == mixin.OnAdded then
                return true
            end
        end
    end
    return false
end

local function IsBlockedWorldMapProvider(provider)
    return IsAreaLabelDataProvider(provider)
        or IsContentTrackingDataProvider(provider)
        or IsEncounterJournalDataProvider(provider)
        or IsQuestOverlayOwnedProvider(provider)
end

-- NOTE: Do not wrap MapCanvasPinMixin.CheckMouseButtonPassthrough — a Flux
-- replacement taints Blizzard's clean AcquirePin path and causes
-- ADDON_ACTION_BLOCKED on SetPassThroughButtons. EncounterJournal is stripped
-- from the embedded BattlefieldMap instead (see RemoveBlockedProvidersFromBattlefield).

local function UnregisterProviderEventRegistryCallbacks(provider)
    if not provider or not EventRegistry or not EventRegistry.UnregisterCallback then
        return
    end
    pcall(EventRegistry.UnregisterCallback, EventRegistry, "Supertracking.OnChanged", provider)
    pcall(EventRegistry.UnregisterCallback, EventRegistry, "MapCanvas.PingQuestID", provider)
    pcall(EventRegistry.UnregisterCallback, EventRegistry, "SetHighlightedQuestPOI", provider)
    pcall(EventRegistry.UnregisterCallback, EventRegistry, "ClearHighlightedQuestPOI", provider)
end

local function DetachBattlefieldProvider(mapFrame, provider)
    if not provider then
        return
    end
    if provider.OnHide then
        pcall(provider.OnHide, provider)
    end
    UnregisterProviderEventRegistryCallbacks(provider)
    if mapFrame and mapFrame.RemoveDataProvider then
        pcall(mapFrame.RemoveDataProvider, mapFrame, provider)
    end
end

local function CloneDataProvider(source)
    local clone = CreateFromMixins(MapCanvasDataProviderMixin)
    for k, v in pairs(source) do
        clone[k] = v
    end
    return clone
end

local RefreshBattlefieldMap

RefreshBattlefieldMap = function()
    -- SetMapID already runs OnMapChanged through secureexecuterange.
end

function FluxBattlefieldMapWorldFeatures:RefreshBattlefieldMapPublic(skipProviderRefresh)
    RefreshBattlefieldMap(GetBattlefieldMap(), skipProviderRefresh)
end

function FluxBattlefieldMapWorldFeatures:RefreshShadowClones()
    if not FluxBattlefieldMapPinRouter or not FluxBattlefieldMapPinRouter.ShouldRouteToBattlefield then
        return
    end
    if not FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield() then
        return
    end
    for worldProvider in pairs(shadowWrappedProviders) do
        if worldProvider.RefreshAllData then
            pcall(worldProvider.RefreshAllData, worldProvider)
        end
    end
end

function FluxBattlefieldMapWorldFeatures:ClearShadowClonesOnBattlefield()
    for _, clone in pairs(worldToBattlefield) do
        SafeProviderMethod(clone, "RemoveAllData")
    end
end

local function RemoveMirroredClone(worldProvider)
    local clone = worldToBattlefield[worldProvider]
    if not clone then
        return
    end
    UnwrapProviderRefreshShadow(worldProvider)
    local mapFrame = GetBattlefieldMap()
    DetachBattlefieldProvider(mapFrame, clone)
    worldToBattlefield[worldProvider] = nil
end

local function MirrorWorldProvider(worldProvider)
    if not worldProvider or worldToBattlefield[worldProvider] then
        return
    end
    -- Midnight+: AddDataProvider from addon code marks the entry insecure.
    -- MapCanvas then runs that provider's RefreshAllData under _FluxUI taint;
    -- Blizzard clones ipairs() secret C_Map tables →
    -- "attempted to iterate a table that cannot be accessed while tainted".
    if IsSecretTableClient() then
        return
    end
    if not FluxBattlefieldMapWorldFeatures:IsEnabled() or not state.isActive then
        return
    end
    if not CanMirrorProviders() then
        return
    end
    local mapFrame = GetBattlefieldMap()
    if not mapFrame or not mapFrame.AddDataProvider then
        return
    end
    if mapFrame.dataProviders and mapFrame.dataProviders[worldProvider] then
        return
    end
    if IsDuplicateProvider(mapFrame, worldProvider) then
        return
    end

    if IsHBDWorldProvider(worldProvider) then
        return
    end

    if IsBlockedWorldMapProvider(worldProvider) then
        return
    end

    local clone = CloneDataProvider(worldProvider)
    local ok = pcall(mapFrame.AddDataProvider, mapFrame, clone)
    if ok then
        HardenFluxDataProvider(clone)
        worldToBattlefield[worldProvider] = clone
        WrapProviderRefreshShadow(worldProvider, clone)
    end
end

local function SyncExistingWorldProviders()
    if IsSecretTableClient() then
        return
    end
    local worldMap = _G.WorldMapFrame
    if not worldMap or not worldMap.dataProviders then
        return
    end
    for provider in pairs(worldMap.dataProviders) do
        MirrorWorldProvider(provider)
    end
end

local function RemoveAddedStandardProviders()
    local mapFrame = GetBattlefieldMap()
    if not mapFrame or not mapFrame.RemoveDataProvider then
        table.wipe(addedStandardProviders)
        return
    end
    for provider in pairs(addedStandardProviders) do
        if mapFrame.dataProviders and mapFrame.dataProviders[provider] then
            DetachBattlefieldProvider(mapFrame, provider)
        else
            UnregisterProviderEventRegistryCallbacks(provider)
        end
    end
    table.wipe(addedStandardProviders)
    state.standardProvidersApplied = false
end

local function RemoveAllMirroredProviders()
    for worldProvider in pairs(worldToBattlefield) do
        RemoveMirroredClone(worldProvider)
    end
    table.wipe(worldToBattlefield)
end

local function RemoveBlockedProvidersFromBattlefield()
    local mapFrame = GetBattlefieldMap()
    if not mapFrame then
        return
    end

    for worldProvider in pairs(worldToBattlefield) do
        if IsBlockedWorldMapProvider(worldProvider) then
            RemoveMirroredClone(worldProvider)
        end
    end

    local toRemoveAdded = {}
    for provider in pairs(addedStandardProviders) do
        if IsBlockedWorldMapProvider(provider) then
            toRemoveAdded[#toRemoveAdded + 1] = provider
        end
    end
    for _, provider in ipairs(toRemoveAdded) do
        DetachBattlefieldProvider(mapFrame, provider)
        addedStandardProviders[provider] = nil
    end

    -- Always strip EncounterJournal from the embedded BattlefieldMap. Flux embedding
    -- / provider mirroring taints map-canvas execution; EJ RefreshAllData → AcquirePin
    -- → SetPassThroughButtons then ADDON_ACTION_BLOCKED in combat (blamed on _FluxUI).
    -- Boss pins remain on the world map. Do not re-AddDataProvider (that would be tainted).
    if mapFrame.dataProviders and mapFrame.RemoveDataProvider then
        if not canaccesstable or canaccesstable(mapFrame.dataProviders) then
            local toStrip = {}
            local ok = pcall(function()
                for provider in pairs(mapFrame.dataProviders) do
                    if IsEncounterJournalDataProvider(provider) then
                        toStrip[#toStrip + 1] = provider
                    end
                end
            end)
            if ok then
                for _, provider in ipairs(toStrip) do
                    DetachBattlefieldProvider(mapFrame, provider)
                end
            end
        end
    end
end

-- Public so FluxBattlefieldMap can strip EJ even when world-feature mirroring is off.
function FluxBattlefieldMapWorldFeatures:StripCombatUnsafeProviders(mapFrame)
    mapFrame = mapFrame or GetBattlefieldMap()
    if not mapFrame or not mapFrame.dataProviders or not mapFrame.RemoveDataProvider then
        return
    end
    if canaccesstable and not canaccesstable(mapFrame.dataProviders) then
        return
    end
    if not EncounterJournalDataProviderMixin then
        EnsureDependencies()
    end
    if not EncounterJournalDataProviderMixin then
        return
    end
    local toStrip = {}
    local ok = pcall(function()
        for provider in pairs(mapFrame.dataProviders) do
            if IsEncounterJournalDataProvider(provider) then
                toStrip[#toStrip + 1] = provider
            end
        end
    end)
    if not ok then
        return
    end
    for _, provider in ipairs(toStrip) do
        DetachBattlefieldProvider(mapFrame, provider)
    end
end

local function ApplyWorldMapStandardProviders()
    if state.standardProvidersApplied then
        return
    end

    -- Midnight+: any AddDataProvider from addon code marks that entry insecure.
    -- MapCanvas then runs that provider's RefreshAllData under Flux taint →
    -- secret-table ipairs errors ("attempted to iterate a table that cannot be
    -- accessed while tainted") with secret debugstacks. BattlefieldMap already
    -- has its own standard providers from load; MirrorWorldProvider is also
    -- gated on IsSecretTableClient (no Blizzard clone injection on 12.x).
    if IsSecretTableClient() then
        state.standardProvidersApplied = true
        return
    end

    local mapFrame = GetBattlefieldMap()
    local addStandard = GetWorldAddStandardProviders()
    if not mapFrame or not addStandard then
        return
    end

    local before = {}
    if mapFrame.dataProviders then
        for provider in pairs(mapFrame.dataProviders) do
            before[provider] = true
        end
    end

    local originAddDataProvider = mapFrame.AddDataProvider
    mapFrame.AddDataProvider = function(self, dataProvider)
        if IsDuplicateProvider(self, dataProvider) or IsBlockedWorldMapProvider(dataProvider) then
            return
        end
        return originAddDataProvider(self, dataProvider)
    end

    pcall(addStandard, mapFrame)
    mapFrame.AddDataProvider = originAddDataProvider

    if mapFrame.dataProviders then
        for provider in pairs(mapFrame.dataProviders) do
            if not before[provider] then
                addedStandardProviders[provider] = true
                HardenFluxDataProvider(provider)
            end
        end
    end

    state.standardProvidersApplied = true
end

local function InstallWorldMapHooks()
    if state.hooksInstalled or not hooksecurefunc then
        return
    end
    local worldMap = _G.WorldMapFrame
    if not worldMap then
        return
    end

    hooksecurefunc(worldMap, "AddDataProvider", function(_, provider)
        if state.isActive and FluxBattlefieldMapWorldFeatures:IsEnabled() then
            MirrorWorldProvider(provider)
            RefreshBattlefieldMap(GetBattlefieldMap())
        end
    end)

    hooksecurefunc(worldMap, "RemoveDataProvider", function(_, provider)
        RemoveMirroredClone(provider)
    end)

    state.hooksInstalled = true
end

local function IsToggleCombatBlocked()
    return InCombatLockdown() or (UnitAffectingCombat and UnitAffectingCombat("player"))
end

local function IsMouseOverToggleArea()
    if toggleHoverZone and toggleHoverZone:IsShown() and toggleHoverZone:IsMouseOver() then
        return true
    end
    if toggleFrame and toggleFrame:IsShown() and toggleFrame:IsMouseOver() then
        return true
    end
    if toggleCheck and toggleCheck:IsShown() and toggleCheck:IsMouseOver() then
        return true
    end
    return false
end

local function SetToggleShownFromHover(wantShown)
    if not toggleFrame then
        return
    end
    if wantShown then
        toggleHideGeneration = toggleHideGeneration + 1
    end
    local show = wantShown and not IsToggleCombatBlocked()
    toggleFrame:Show()
    if show then
        toggleFrame:SetAlpha(1)
        toggleFrame:EnableMouse(true)
        if toggleCheck then
            toggleCheck:EnableMouse(true)
            toggleCheck:SetAlpha(1)
            if toggleCheck.text then
                toggleCheck.text:SetAlpha(1)
            end
        end
        UpdateToggleVisual()
    else
        toggleFrame:SetAlpha(0)
        toggleFrame:EnableMouse(false)
        if toggleCheck then
            toggleCheck:EnableMouse(false)
        end
        GameTooltip:Hide()
    end
end

local function ScheduleToggleHide()
    toggleHideGeneration = toggleHideGeneration + 1
    local generation = toggleHideGeneration
    if not C_Timer or not C_Timer.After then
        if not IsMouseOverToggleArea() then
            SetToggleShownFromHover(false)
        end
        return
    end
    C_Timer.After(0.12, function()
        if generation ~= toggleHideGeneration then
            return
        end
        if not IsMouseOverToggleArea() then
            SetToggleShownFromHover(false)
        end
    end)
end

local function BindToggleHoverFrame(frame, onEnterExtra)
    if not frame then
        return
    end
    frame:SetScript("OnEnter", function(self)
        SetToggleShownFromHover(true)
        if onEnterExtra then
            onEnterExtra(self)
        end
    end)
    frame:SetScript("OnLeave", function()
        ScheduleToggleHide()
    end)
end

local function EnsureToggleCombatWatcher()
    if toggleCombatFrame then
        return
    end
    toggleCombatFrame = CreateFrame("Frame")
    toggleCombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    toggleCombatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    toggleCombatFrame:SetScript("OnEvent", function()
        if IsToggleCombatBlocked() then
            SetToggleShownFromHover(false)
        elseif IsMouseOverToggleArea() then
            SetToggleShownFromHover(true)
        end
    end)
end

local function ResolveToggleAnchor(parentFrame)
    if state.parentFrame then
        return state.parentFrame
    end
    return parentFrame
end

local function PositionToggleHoverZone(anchorFrame)
    if not toggleHoverZone then
        return
    end
    local mapFrame = GetBattlefieldMap()
    local anchor = (mapFrame and mapFrame.IsShown and mapFrame:IsShown()) and mapFrame or anchorFrame
    if not anchor then
        return
    end
    toggleHoverZone:ClearAllPoints()
    toggleHoverZone:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -4, 4)
end

function FluxBattlefieldMapWorldFeatures:RefreshToggleLayout()
    if not state.isActive or not toggleHoverZone then
        return
    end
    local anchorFrame = ResolveToggleAnchor(state.parentFrame)
    PositionToggleHoverZone(anchorFrame)
end

local function UpdateToggleTooltip()
    if not toggleCheck then
        return
    end
    local function ShowToggleTooltip(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("World Map Features", 1, 1, 1)
        GameTooltip:AddLine("Show world map pins and layers on this map (quests, world quests, addon pins).", 1, 1, 1, true)
        if not CanMirrorProviders() then
            GameTooltip:AddLine(" ", 1, 1, 1)
            local reason = state.lastDepFailure or "map addons"
            GameTooltip:AddLine("Waiting for map addons (" .. tostring(reason) .. "). Open the world map once or /reload.", 1, 0.82, 0, true)
        else
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Addons that draw directly on the world map frame without data providers may not appear.", 0.7, 0.7, 0.7, true)
        end
        GameTooltip:Show()
    end
    BindToggleHoverFrame(toggleCheck, ShowToggleTooltip)
end

local function EnsureToggle(parentFrame)
    local anchorFrame = ResolveToggleAnchor(parentFrame)
    if not anchorFrame then
        return
    end

    EnsureToggleCombatWatcher()

    if not toggleHoverZone then
        toggleHoverZone = CreateFrame("Frame", "FluxBattlefieldMapWorldFeaturesToggleHover", UIParent)
        toggleHoverZone:SetSize(110, 32)
        toggleHoverZone:EnableMouse(true)
        toggleHoverZone:SetFrameStrata("HIGH")
        toggleHoverZone:SetFrameLevel(500)

        local hit = toggleHoverZone:CreateTexture(nil, "BACKGROUND")
        hit:SetAllPoints()
        hit:SetColorTexture(0, 0, 0, 0.001)

        toggleHoverZone:SetScript("OnEnter", function()
            SetToggleShownFromHover(true)
        end)
        toggleHoverZone:SetScript("OnLeave", function()
            ScheduleToggleHide()
        end)

        toggleFrame = CreateFrame("Frame", "FluxBattlefieldMapWorldFeaturesToggle", toggleHoverZone)
        toggleFrame:SetSize(76, 22)
        toggleFrame:SetPoint("BOTTOMRIGHT", toggleHoverZone, "BOTTOMRIGHT", 0, 0)
        toggleFrame:EnableMouse(false)
        toggleFrame:SetAlpha(0)
        toggleFrame:Show()

        toggleCheck = CreateFrame("CheckButton", nil, toggleFrame, "UICheckButtonTemplate")
        toggleCheck:SetSize(22, 22)
        toggleCheck:SetPoint("LEFT", toggleFrame, "LEFT", 0, 0)
        toggleCheck:SetHitRectInsets(0, 0, 0, 0)
        toggleCheck:EnableMouse(false)
        toggleCheck.text = toggleCheck:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        toggleCheck.text:SetPoint("LEFT", toggleCheck, "RIGHT", 2, 0)
        toggleCheck.text:SetText(TOGGLE_LABEL)

        BindToggleHoverFrame(toggleFrame)

        toggleCheck:SetScript("OnClick", function(self)
            if InCombatLockdown() then
                self:SetChecked(FluxBattlefieldMapWorldFeatures:IsEnabled())
                return
            end
            FluxBattlefieldMapWorldFeatures:SetEnabled(self:GetChecked())
        end)
    end

    PositionToggleHoverZone(anchorFrame)
    toggleCheck:SetChecked(FluxBattlefieldMapWorldFeatures:IsEnabled())
    UpdateToggleTooltip()
    SetToggleShownFromHover(false)
    toggleHoverZone:Show()
    if toggleHoverZone.Raise then
        toggleHoverZone:Raise()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.1, function()
            if state.isActive and toggleHoverZone then
                PositionToggleHoverZone(ResolveToggleAnchor(state.parentFrame))
            end
        end)
    end
end

local function HideToggle()
    toggleHideGeneration = toggleHideGeneration + 1
    SetToggleShownFromHover(false)
    if toggleHoverZone then
        toggleHoverZone:Hide()
    end
end

function FluxBattlefieldMapWorldFeatures:Activate()
    if not self:IsEnabled() then
        return
    end
    if InCombatLockdown() then
        state.pendingActivate = true
        state.pendingDeactivate = false
        return
    end
    if FluxBattlefieldMapProviders and FluxBattlefieldMapProviders.Attach then
        FluxBattlefieldMapProviders:Attach(GetBattlefieldMap())
    end
    if FluxBattlefieldMapPinRouter and FluxBattlefieldMapPinRouter.Install then
        FluxBattlefieldMapPinRouter:Install()
    end
    UpdateToggleVisual()
end

function FluxBattlefieldMapWorldFeatures:Deactivate()
    if InCombatLockdown() then
        state.pendingDeactivate = true
        state.pendingActivate = false
        return
    end
    if FluxBattlefieldMapProviders and FluxBattlefieldMapProviders.Detach then
        FluxBattlefieldMapProviders:Detach(GetBattlefieldMap())
    end
    if FluxBattlefieldMapPinRouter and FluxBattlefieldMapPinRouter.Uninstall then
        FluxBattlefieldMapPinRouter:Uninstall()
    end
    if FluxBattlefieldMapPinTooltips and FluxBattlefieldMapPinTooltips.Uninstall then
        FluxBattlefieldMapPinTooltips:Uninstall()
    end
end

local function ScheduleActivateRetry()
    if not state.isActive or not FluxBattlefieldMapWorldFeatures:IsEnabled() then
        return
    end
    if FluxBattlefieldMapPinRouter and FluxBattlefieldMapPinRouter.ScheduleKickstart then
        FluxBattlefieldMapPinRouter:ScheduleKickstart()
    end
end

function FluxBattlefieldMapWorldFeatures:OnMapShown(parentFrame)
    if not parentFrame then
        return
    end

    state.isActive = true
    state.parentFrame = parentFrame
    EnsureToggle(parentFrame)

    if self:IsEnabled() then
        self:Activate()
        ScheduleActivateRetry()
    end
end

function FluxBattlefieldMapWorldFeatures:OnMapHidden()
    state.isActive = false
    state.pendingActivate = false
    state.pendingDeactivate = false
    state.canMirror = false
    HideToggle()
    self:Deactivate()
    state.parentFrame = nil
end

function FluxBattlefieldMapWorldFeatures:SyncIfMapActive()
    if not FluxBattlefieldMap or not FluxBattlefieldMap.IsActive or not FluxBattlefieldMap:IsActive() then
        return false
    end

    local parentFrame = state.parentFrame
    if FluxBattlefieldMap.GetMapFrame and not parentFrame then
        parentFrame = FluxBattlefieldMap:GetMapFrame() and FluxWindowFrame and FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame()
    end
    if not parentFrame and FluxWindowFrame and FluxWindowFrame.GetFrame then
        parentFrame = FluxWindowFrame:GetFrame()
    end
    if not parentFrame then
        return false
    end

    if not state.isActive then
        self:OnMapShown(parentFrame)
        return true
    end

    EnsureToggle(parentFrame)
    if self:IsEnabled() and not CanMirrorProviders() then
        self:Activate()
        ScheduleActivateRetry()
    end
    return true
end

local function PrintStatus()
    FluxBattlefieldMapWorldFeatures:SyncIfMapActive()

    local mirrored = 0
    for _ in pairs(worldToBattlefield) do
        mirrored = mirrored + 1
    end
    local added = 0
    for _ in pairs(addedStandardProviders) do
        added = added + 1
    end

    local mirrorReady = CanMirrorProviders()
    print(string.format(
        "Flux %s: active=%s enabled=%s mirror=%s client=%s",
        TOGGLE_LABEL,
        tostring(state.isActive),
        tostring(FluxBattlefieldMapWorldFeatures:IsEnabled()),
        tostring(mirrorReady),
        GetClientLabel()
    ))
    print(string.format(
        "  BattlefieldMapFrame=%s WorldMapFrame=%s MapCanvas=%s",
        tostring(_G.BattlefieldMapFrame ~= nil),
        tostring(_G.WorldMapFrame ~= nil),
        tostring(_G.MapCanvasMixin ~= nil)
    ))
    if state.lastDepFailure then
        print("  lastFailure=" .. tostring(state.lastDepFailure))
    end
    print(string.format("  mirrored=%d added=%d", mirrored, added))
    if FluxBattlefieldMapPinRouter then
        local route = FluxBattlefieldMapPinRouter.GetRouteLabel and FluxBattlefieldMapPinRouter:GetRouteLabel() or "?"
        local hbd = FluxBattlefieldMapPinRouter.IsHBDAvailable and FluxBattlefieldMapPinRouter:IsHBDAvailable()
        print(string.format(
            "  route=%s hbd=%s worldOpen=%s",
            tostring(route),
            tostring(hbd),
            tostring(route == "World")
        ))
    end
    if FluxBattlefieldMapPinTooltips and FluxBattlefieldMapPinTooltips.GetDiagnostics then
        local diag = FluxBattlefieldMapPinTooltips:GetDiagnostics()
        print(string.format(
            "  tooltips=%s getMapShim=%s getMapIDShim=%s registerPinHook=%s",
            tostring(diag.installed),
            tostring(diag.getMapShim),
            tostring(diag.getMapIDShim),
            tostring(diag.registerPinHook)
        ))
    end
    if FluxBattlefieldMapQuestPins and FluxBattlefieldMapQuestPins.GetDiagnostics then
        local q = FluxBattlefieldMapQuestPins:GetDiagnostics()
        print(string.format(
            "  questPins started=%s mapID=%s skip=%s backend=%s poiTemplate=%s questPOI=%s questPOIWQ=%s",
            tostring(q.started),
            tostring(q.mapID),
            tostring(q.skip),
            tostring(q.backend),
            tostring(q.poiTemplate),
            tostring(q.questPOI),
            tostring(q.questPOIWQ)
        ))
        print(string.format(
            "  quest=%d wq=%d bonus=%d threat=%d waypoint=%d nav=%d user=%d blob=%d active=%d",
            q.quest or 0,
            q.worldquest or 0,
            q.bonus or 0,
            q.threat or 0,
            q.waypoint or 0,
            q.navwaypoint or 0,
            q.userwaypoint or 0,
            q.blob or 0,
            q.active or 0
        ))
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "PLAYER_ENTERING_WORLD" then
        if state.isActive and FluxBattlefieldMapWorldFeatures:IsEnabled() then
            ScheduleActivateRetry()
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if state.pendingDeactivate then
            state.pendingDeactivate = false
            state.pendingCanvasRefresh = false
            state.pendingCanvasRefreshFull = false
            FluxBattlefieldMapWorldFeatures:Deactivate()
        elseif state.pendingActivate and state.isActive and FluxBattlefieldMapWorldFeatures:IsEnabled() then
            state.pendingActivate = false
            state.pendingCanvasRefresh = false
            state.pendingCanvasRefreshFull = false
            FluxBattlefieldMapWorldFeatures:Activate()
        elseif state.pendingCanvasRefresh then
            local skipProviderRefresh = not state.pendingCanvasRefreshFull
            state.pendingCanvasRefresh = false
            state.pendingCanvasRefreshFull = false
            RefreshBattlefieldMap(GetBattlefieldMap(), skipProviderRefresh)
        end
        return
    end

    if event == "ADDON_LOADED" and state.isActive and FluxBattlefieldMapWorldFeatures:IsEnabled() then
        if MAP_ADDON_RELOAD_NAMES[loadedAddon] then
            ScheduleActivateRetry()
            return
        end
        if loadedAddon == "Questie" then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.5, function()
                    if state.isActive then
                        FluxBattlefieldMapWorldFeatures:Activate()
                        if FluxBattlefieldMapPinRouter and FluxBattlefieldMapPinRouter.ScheduleKickstart then
                            FluxBattlefieldMapPinRouter:ScheduleKickstart()
                        end
                    end
                end)
            end
            return
        end
        if FluxBattlefieldMapPinRouter and FluxBattlefieldMapPinRouter.RequestRefresh then
            FluxBattlefieldMapPinRouter:RequestRefresh()
        end
        UpdateToggleVisual()
    end
end)

SLASH_FLUXWORLDMAP1 = "/fluxwm"
SlashCmdList["FLUXWORLDMAP"] = function(msg)
    local cmd = msg and msg:lower():match("^(%S+)") or ""
    if cmd == "off" or cmd == "0" or cmd == "false" then
        FluxBattlefieldMapWorldFeatures:SetEnabled(false)
    elseif cmd == "on" or cmd == "1" or cmd == "true" then
        FluxBattlefieldMapWorldFeatures:SetEnabled(true)
    elseif cmd == "toggle" then
        FluxBattlefieldMapWorldFeatures:SetEnabled(not FluxBattlefieldMapWorldFeatures:IsEnabled())
    else
        PrintStatus()
    end
end

