-- FluxBattlefieldMapPinRouter.lua
-- Routes HereBeDragons world-map pins (Questie, NovaInstanceTracker, TomTom, etc.) to
-- BattlefieldMapFrame when the Battlezone map is active and the world map is closed.
-- World map takes priority while open. Also mirrors third-party WorldMapFrame pin pools
-- onto the battlefield map so AcquirePin does not fail on missing XML templates.

local addonName, addonTable = ...

FluxBattlefieldMapPinRouter = {}

-- Questie ships a renamed HBD pins lib/template; most other addons use the stock names.
local HBD_LIBS = {
    { name = "HereBeDragonsQuestie-Pins-2.0", template = "HereBeDragonsPinsTemplateQuestie" },
    { name = "HereBeDragons-Pins-2.0", template = "HereBeDragonsPinsTemplate" },
}

local function SecureCall(func, ...)
    if not func then
        return
    end
    if securecall then
        return securecall(func, ...)
    end
    return func(...)
end

local state = {
    installed = false,
    hbdAvailable = false,
    -- [worldProvider] = { HBDPins, template, libName, battlefieldProvider, origHandlePin, origRefreshAllData, removeIconHooked }
    hbdRoutes = {},
    worldMapShowHooked = false,
    worldMapHideHooked = false,
    worldMapOnHideHooked = false,
    acquirePinGuarded = false,
    acquirePinPostHooked = false,
    origAcquirePin = nil,
    worldMapOpen = false,
    restorePending = false,
    questieQueueHooked = false,
    questieCatchupScheduled = false,
}

local KICKSTART_DELAYS = { 0, 0.25, 0.5, 1.0, 2.0, 3.0, 5.0, 8.0 }
local kickstartGeneration = 0

local function BlizzardHasQuestPins()
    return type(QuestDataProviderMixin) == "table"
end

local function IsPinRouterWanted()
    if BlizzardHasQuestPins() then
        return false
    end
    if not FluxBattlefieldMapWorldFeatures or not FluxBattlefieldMapWorldFeatures.IsEnabled then
        return false
    end
    if not FluxBattlefieldMapWorldFeatures:IsEnabled() then
        return false
    end
    if not FluxBattlefieldMap or not FluxBattlefieldMap.IsActive or not FluxBattlefieldMap:IsActive() then
        return false
    end
    return true
end

local function IsProviderOnMap(mapFrame, provider)
    if not mapFrame or not provider then
        return false
    end
    if mapFrame.dataProviders and mapFrame.dataProviders[provider] then
        return true
    end
    if mapFrame.dataProviders then
        for registered in pairs(mapFrame.dataProviders) do
            if registered == provider then
                return true
            end
        end
    end
    return false
end

local function GetBattlefieldMap()
    if FluxBattlefieldMap and FluxBattlefieldMap.GetMapFrame then
        return FluxBattlefieldMap:GetMapFrame()
    end
    return _G.BattlefieldMapFrame
end

local function SyncWorldMapOpenState()
    local worldMap = _G.WorldMapFrame
    if not worldMap then
        state.worldMapOpen = false
        return false
    end
    if worldMap.IsShown and worldMap:IsShown() then
        state.worldMapOpen = true
        return true
    end
    if worldMap.IsVisible and worldMap:IsVisible() then
        state.worldMapOpen = true
        return true
    end
    state.worldMapOpen = false
    return false
end

function FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield()
    if not state.installed then
        return false
    end
    if not FluxBattlefieldMapWorldFeatures or not FluxBattlefieldMapWorldFeatures.IsEnabled then
        return false
    end
    if not FluxBattlefieldMapWorldFeatures:IsEnabled() then
        return false
    end
    if not FluxBattlefieldMap or not FluxBattlefieldMap.IsActive or not FluxBattlefieldMap:IsActive() then
        return false
    end
    if state.worldMapOpen then
        return false
    end
    return true
end

function FluxBattlefieldMapPinRouter:IsHBDAvailable()
    return state.hbdAvailable
end

function FluxBattlefieldMapPinRouter:IsHBDWorldProvider(provider)
    if not provider then
        return false
    end
    if state.hbdRoutes[provider] then
        return true
    end
    if not LibStub then
        return false
    end
    for _, entry in ipairs(HBD_LIBS) do
        local ok, pins = pcall(LibStub, entry.name, true)
        if ok and pins and pins.worldmapProvider == provider then
            return true
        end
    end
    return false
end

function FluxBattlefieldMapPinRouter:GetRouteLabel()
    if state.worldMapOpen then
        return "World"
    end
    if self:ShouldRouteToBattlefield() then
        return "BF"
    end
    return "Off"
end

local function EnumerateHBDLibs()
    local found = {}
    if not LibStub then
        return found
    end
    for _, entry in ipairs(HBD_LIBS) do
        local ok, pins = pcall(LibStub, entry.name, true)
        if ok and pins and pins.worldmapProvider then
            found[#found + 1] = {
                name = entry.name,
                template = entry.template,
                pins = pins,
            }
        end
    end
    return found
end

local function CloneHBDProvider(source)
    if CreateFromMixins and MapCanvasDataProviderMixin then
        local clone = CreateFromMixins(MapCanvasDataProviderMixin)
        for k, v in pairs(source) do
            clone[k] = v
        end
        return clone
    end
    local clone = {}
    for k, v in pairs(source) do
        clone[k] = v
    end
    return clone
end

local function CreateBattlefieldPinPool(mapFrame, template, providerPin)
    if not mapFrame or not mapFrame.GetCanvas or not template then
        return nil
    end
    if not mapFrame.pinPools then
        mapFrame.pinPools = {}
    end
    if mapFrame.pinPools[template] then
        return mapFrame.pinPools[template]
    end

    local pool
    if CreateUnsecuredRegionPoolInstance then
        pool = CreateUnsecuredRegionPoolInstance(template)
    elseif CreateFramePool then
        pool = CreateFramePool("FRAME")
    else
        return nil
    end

    local canvas = mapFrame:GetCanvas()
    pool.parent = canvas
    pool.createFunc = function()
        local frame = CreateFrame("Frame", nil, canvas)
        frame:SetSize(1, 1)
        if providerPin and Mixin then
            Mixin(frame, providerPin)
        end
        frame:EnableMouse(false)
        if frame.SetMouseMotionEnabled then
            frame:SetMouseMotionEnabled(false)
        end
        if frame.SetMouseClickEnabled then
            frame:SetMouseClickEnabled(false)
        end
        if providerPin then
            local origOnAcquired = frame.OnAcquired
            frame.OnAcquired = function(self, icon, ...)
                if origOnAcquired then
                    origOnAcquired(self, icon, ...)
                end
                if FluxBattlefieldMapPinTooltips and FluxBattlefieldMapPinTooltips.OnHBDPinAcquired then
                    FluxBattlefieldMapPinTooltips:OnHBDPinAcquired(self, icon)
                end
            end
        end
        return frame
    end
    pool.resetFunc = function(_, pin)
        pin:Hide()
        pin:ClearAllPoints()
        if pin.OnReleased then
            pin:OnReleased()
        end
        pin.pinTemplate = nil
        pin.owningMap = nil
    end
    pool.creationFunc = pool.createFunc
    pool.resetterFunc = pool.resetFunc
    mapFrame.pinPools[template] = pool
    return pool
end

local function EnsureBattlefieldHBDPinPool(mapFrame, HBDPins, template)
    if not HBDPins or not HBDPins.worldmapProviderPin or not template then
        return false
    end
    return CreateBattlefieldPinPool(mapFrame, template, HBDPins.worldmapProviderPin) ~= nil
end

-- True when template is a real XML frame template (e.g. AreaPOIPinTemplate).
-- HereBeDragonsPinsTemplate is NOT XML — C_XMLUtil returns nil and needs a custom pool.
local function IsXmlPinTemplate(template)
    if not template or not C_XMLUtil or not C_XMLUtil.GetTemplateInfo then
        return false
    end
    return C_XMLUtil.GetTemplateInfo(template) ~= nil
end

-- Mirror a WorldMapFrame pin pool onto the battlefield map (re-parent createFunc to BF canvas).
-- Covers third-party addons that register custom pools on WorldMapFrame but not BattlefieldMapFrame.
-- Never mirrors Blizzard XML templates — those must be created by AcquirePin via CreateFramePool(..., template).
local function TryMirrorPinPoolFromWorldMap(mapFrame, template)
    if not mapFrame or not template then
        return false
    end
    if IsXmlPinTemplate(template) then
        return false
    end
    if not mapFrame.pinPools then
        mapFrame.pinPools = {}
    end
    if mapFrame.pinPools[template] then
        return true
    end

    local worldMap = _G.WorldMapFrame
    local sourcePool = worldMap and worldMap.pinPools and worldMap.pinPools[template]
    if not sourcePool or not mapFrame.GetCanvas then
        return false
    end

    local canvas = mapFrame:GetCanvas()
    local pool
    if CreateUnsecuredRegionPoolInstance then
        pool = CreateUnsecuredRegionPoolInstance(template)
    elseif CreateFramePool then
        pool = CreateFramePool("FRAME")
    else
        return false
    end

    local sourceCreate = sourcePool.createFunc or sourcePool.creationFunc
    local sourceReset = sourcePool.resetFunc or sourcePool.resetterFunc

    pool.parent = canvas
    pool.createFunc = function()
        local frame
        if sourceCreate then
            local ok, result = pcall(sourceCreate, sourcePool)
            if ok and result then
                frame = result
            else
                ok, result = pcall(sourceCreate, pool)
                if ok and result then
                    frame = result
                else
                    ok, result = pcall(sourceCreate)
                    if ok and result then
                        frame = result
                    end
                end
            end
        end
        if not frame then
            frame = CreateFrame("Frame", nil, canvas)
            frame:SetSize(1, 1)
        else
            frame:SetParent(canvas)
            frame:ClearAllPoints()
        end
        return frame
    end
    pool.resetFunc = sourceReset or function(_, pin)
        pin:Hide()
        pin:ClearAllPoints()
        if pin.OnReleased then
            pin:OnReleased()
        end
        pin.pinTemplate = nil
        pin.owningMap = nil
    end
    pool.creationFunc = pool.createFunc
    pool.resetterFunc = pool.resetFunc
    mapFrame.pinPools[template] = pool
    return true
end

local function IsKnownHBDTemplate(template)
    for _, entry in ipairs(HBD_LIBS) do
        if entry.template == template then
            return true
        end
    end
    return false
end

local function EnsureKnownHBDTemplatePool(mapFrame, template)
    if not IsKnownHBDTemplate(template) then
        return false
    end
    for _, entry in ipairs(EnumerateHBDLibs()) do
        if entry.template == template then
            return EnsureBattlefieldHBDPinPool(mapFrame, entry.pins, template)
        end
    end
    return false
end

-- Clear XML-template pools that lack MapCanvasPinMixin methods (or empty mirrors that block
-- Blizzard's CreateFramePool(..., template) path) so AcquirePin can recreate them properly.
local function PurgePoisonedXmlPinPools(mapFrame)
    if not mapFrame or not mapFrame.pinPools then
        return
    end
    local toClear = {}
    for template, pool in pairs(mapFrame.pinPools) do
        if IsXmlPinTemplate(template) then
            local hasPin = false
            local poisoned = false
            local function inspect(pin)
                if not pin then
                    return
                end
                hasPin = true
                if not pin.OnLoad or not pin.OnCanvasSizeChanged or not pin.OnAcquired then
                    poisoned = true
                end
            end
            if pool.EnumerateActive then
                for pin in pool:EnumerateActive() do
                    inspect(pin)
                    if poisoned then
                        break
                    end
                end
            end
            if not poisoned and pool.EnumerateInactive then
                for pin in pool:EnumerateInactive() do
                    inspect(pin)
                    if poisoned then
                        break
                    end
                end
            end
            -- Empty mirrored pools still poison pinPools and must be removed.
            if poisoned or not hasPin then
                toClear[#toClear + 1] = template
            end
        end
    end
    for _, template in ipairs(toClear) do
        local pool = mapFrame.pinPools[template]
        if pool and pool.ReleaseAll then
            pcall(pool.ReleaseAll, pool)
        end
        mapFrame.pinPools[template] = nil
    end
end

local function InstallAcquirePinGuard(mapFrame)
    if not mapFrame or not mapFrame.AcquirePin then
        return
    end

    -- If an older Flux build replaced AcquirePin with a tainted closure, restore Blizzard's
    -- method immediately. Calling SetPassThroughButtons from a Flux-wrapped AcquirePin in
    -- combat causes ADDON_ACTION_BLOCKED (EncounterJournal / map pins).
    if state.origAcquirePin then
        mapFrame.AcquirePin = state.origAcquirePin
        state.origAcquirePin = nil
    end

    -- Do NOT hooksecurefunc AcquirePin. On modern clients any addon touch of the
    -- map-canvas acquire path can taint pin setup so Blizzard's own
    -- SetPassThroughButtons is ADDON_ACTION_BLOCKED and blamed on Flux.
    -- Third-party pools are prepared eagerly via SyncThirdPartyPinPools instead.
    state.acquirePinGuarded = true
end

local function SyncThirdPartyPinPools(mapFrame)
    local worldMap = _G.WorldMapFrame
    if not mapFrame or not worldMap or not worldMap.pinPools then
        return
    end
    for template in pairs(worldMap.pinPools) do
        if not IsXmlPinTemplate(template) then
            if not mapFrame.pinPools or not mapFrame.pinPools[template] then
                TryMirrorPinPoolFromWorldMap(mapFrame, template)
            end
        end
    end
    for _, entry in ipairs(HBD_LIBS) do
        if not mapFrame.pinPools or not mapFrame.pinPools[entry.template] then
            EnsureKnownHBDTemplatePool(mapFrame, entry.template)
        end
    end
end

local ClearProviderFromIcon
local RouteHandlePin
local RouteRefreshAllData

ClearProviderFromIcon = function(provider, icon)
    if provider and provider.RemovePinByIcon and icon then
        pcall(provider.RemovePinByIcon, provider, icon)
    end
end

RouteHandlePin = function(route, worldProvider, icon, data, ...)
    if FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield() then
        if route.battlefieldProvider and route.battlefieldProvider.HandlePin then
            pcall(SecureCall, route.battlefieldProvider.HandlePin, route.battlefieldProvider, icon, data, ...)
            if FluxBattlefieldMapPinTooltips and FluxBattlefieldMapPinTooltips.OnHBDPinAcquired and icon then
                pcall(function()
                    local mapFrame = GetBattlefieldMap()
                    if mapFrame and mapFrame.EnumeratePinsByTemplate then
                        for pin in mapFrame:EnumeratePinsByTemplate(route.template) do
                            if pin.icon == icon then
                                FluxBattlefieldMapPinTooltips:OnHBDPinAcquired(pin, icon)
                                break
                            end
                        end
                    end
                end)
            end
        end
        ClearProviderFromIcon(worldProvider, icon)
    elseif route.origHandlePin then
        pcall(SecureCall, route.origHandlePin, worldProvider, icon, data, ...)
        ClearProviderFromIcon(route.battlefieldProvider, icon)
    end
end

RouteRefreshAllData = function(route, worldProvider, fromOnShow)
    if FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield() then
        if worldProvider then
            worldProvider.forceUpdate = true
        end
        if route.battlefieldProvider then
            route.battlefieldProvider.forceUpdate = true
            -- Skip pin acquire under Flux taint while locked down (SetPassThroughButtons).
            if route.battlefieldProvider.RefreshAllData
                and not (InCombatLockdown and InCombatLockdown()) then
                pcall(SecureCall, route.battlefieldProvider.RefreshAllData, route.battlefieldProvider, fromOnShow)
            end
        end
        -- Do not call worldProvider:RemoveAllData() while routing: GetMap may be shimmed to
        -- BattlefieldMapFrame, which would wipe pins we just placed on the battlefield map.
        local worldMap = _G.WorldMapFrame
        if worldMap and worldMap.RemoveAllPinsByTemplate then
            pcall(worldMap.RemoveAllPinsByTemplate, worldMap, route.template)
        end
    elseif route.origRefreshAllData then
        if not (InCombatLockdown and InCombatLockdown()) then
            pcall(SecureCall, route.origRefreshAllData, worldProvider, fromOnShow)
        end
        if route.battlefieldProvider and route.battlefieldProvider.RemoveAllData then
            pcall(SecureCall, route.battlefieldProvider.RemoveAllData, route.battlefieldProvider)
        end
    end
end

local function InstallOneHBDProvider(mapFrame, libEntry)
    local HBDPins = libEntry.pins
    local template = libEntry.template
    local worldProvider = HBDPins.worldmapProvider
    if not worldProvider then
        return
    end

    EnsureBattlefieldHBDPinPool(mapFrame, HBDPins, template)

    local route = state.hbdRoutes[worldProvider]
    if not route then
        route = {
            HBDPins = HBDPins,
            template = template,
            libName = libEntry.name,
            battlefieldProvider = CloneHBDProvider(worldProvider),
            origHandlePin = worldProvider.HandlePin,
            origRefreshAllData = worldProvider.RefreshAllData,
            removeIconHooked = false,
        }
        state.hbdRoutes[worldProvider] = route

        worldProvider.HandlePin = function(self, icon, data, ...)
            RouteHandlePin(route, self, icon, data, ...)
        end
        worldProvider.RefreshAllData = function(self, fromOnShow)
            RouteRefreshAllData(route, self, fromOnShow)
        end
    else
        route.HBDPins = HBDPins
        route.template = template
        EnsureBattlefieldHBDPinPool(mapFrame, HBDPins, template)
    end

    if not IsProviderOnMap(mapFrame, route.battlefieldProvider) then
        pcall(mapFrame.AddDataProvider, mapFrame, route.battlefieldProvider)
    end

    if hooksecurefunc and not route.removeIconHooked then
        hooksecurefunc(HBDPins, "RemoveWorldMapIcon", function(_, ref, icon)
            ClearProviderFromIcon(route.battlefieldProvider, icon)
        end)
        route.removeIconHooked = true
    end
end

local function InstallHBDProvider(mapFrame)
    PurgePoisonedXmlPinPools(mapFrame)
    InstallAcquirePinGuard(mapFrame)
    SyncThirdPartyPinPools(mapFrame)

    local libs = EnumerateHBDLibs()
    state.hbdAvailable = #libs > 0
    for _, libEntry in ipairs(libs) do
        InstallOneHBDProvider(mapFrame, libEntry)
    end
end

local function OnWorldMapOpened()
    state.worldMapOpen = true
    state.restorePending = false
    for _, route in pairs(state.hbdRoutes) do
        if route.battlefieldProvider and route.battlefieldProvider.RemoveAllData then
            pcall(route.battlefieldProvider.RemoveAllData, route.battlefieldProvider)
        end
    end
    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.ClearShadowClonesOnBattlefield then
        FluxBattlefieldMapWorldFeatures:ClearShadowClonesOnBattlefield()
    end
    for worldProvider, route in pairs(state.hbdRoutes) do
        if route.origRefreshAllData then
            worldProvider.forceUpdate = true
            pcall(SecureCall, route.origRefreshAllData, worldProvider, true)
        end
    end
end

local function ScheduleBattlefieldPinRestore()
    if not state.installed or state.restorePending then
        return
    end
    state.restorePending = true

    local function tryRestore()
        if not state.installed then
            state.restorePending = false
            return
        end
        if state.worldMapOpen then
            return
        end
        if FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield() then
            FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins()
        end
    end

    local function finishRestore()
        state.restorePending = false
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            tryRestore()
            C_Timer.After(0.1, function()
                tryRestore()
                finishRestore()
            end)
        end)
    else
        tryRestore()
        finishRestore()
    end
end

local function OnWorldMapClosed()
    state.worldMapOpen = false
    ScheduleBattlefieldPinRestore()
end

local function InstallWorldMapPriorityHooks()
    local worldMap = _G.WorldMapFrame
    if not worldMap or not worldMap.HookScript then
        return
    end
    if not state.worldMapShowHooked then
        worldMap:HookScript("OnShow", OnWorldMapOpened)
        state.worldMapShowHooked = true
    end
    if not state.worldMapHideHooked then
        worldMap:HookScript("OnHide", OnWorldMapClosed)
        state.worldMapHideHooked = true
    end
    SyncWorldMapOpenState()
end

local worldMapEventFrame = CreateFrame("Frame")
for _, eventName in ipairs({ "WORLD_MAP_OPEN", "WORLD_MAP_CLOSE" }) do
    pcall(worldMapEventFrame.RegisterEvent, worldMapEventFrame, eventName)
end
worldMapEventFrame:SetScript("OnEvent", function(_, event)
    if not state.installed then
        return
    end
    if event == "WORLD_MAP_OPEN" then
        OnWorldMapOpened()
    elseif event == "WORLD_MAP_CLOSE" then
        OnWorldMapClosed()
    end
end)

local function TryHookQuestieQueueInit()
    if not hooksecurefunc or not QuestieLoader then
        return
    end
    local ok, QuestieMap = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieMap")
    if not ok or not QuestieMap then
        return
    end

    if not state.questieQueueHooked and QuestieMap.InitializeQueue then
        hooksecurefunc(QuestieMap, "InitializeQueue", function()
            if not state.installed or not IsPinRouterWanted() then
                return
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0.5, function()
                    if state.installed and IsPinRouterWanted() then
                        FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins()
                    end
                end)
                C_Timer.After(2.0, function()
                    if state.installed and IsPinRouterWanted() then
                        FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins()
                    end
                end)
            end
        end)
        state.questieQueueHooked = true
    end

    if not state.questieCatchupScheduled and IsPinRouterWanted() and C_Timer and C_Timer.After then
        state.questieCatchupScheduled = true
        C_Timer.After(1.0, function()
            if state.installed and IsPinRouterWanted() then
                FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins()
            end
        end)
        C_Timer.After(3.0, function()
            if state.installed and IsPinRouterWanted() then
                FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins()
            end
        end)
    end
end

local function DrainQuestieMapQueue()
    if not QuestieLoader then
        return
    end
    local ok, QuestieMap = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieMap")
    if not ok or not QuestieMap or not QuestieMap.ProcessQueue then
        return
    end
    for _ = 1, 64 do
        QuestieMap.ProcessQueue()
    end
end

function FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins()
    if not state.installed then
        return
    end

    local mapFrame = GetBattlefieldMap()
    if mapFrame then
        InstallHBDProvider(mapFrame)
    end

    for worldProvider, route in pairs(state.hbdRoutes) do
        worldProvider.forceUpdate = true
        RouteRefreshAllData(route, worldProvider, false)
    end

    DrainQuestieMapQueue()

    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.RefreshShadowClones then
        FluxBattlefieldMapWorldFeatures:RefreshShadowClones()
    end

    if FluxBattlefieldMapWorldFeatures and FluxBattlefieldMapWorldFeatures.RefreshBattlefieldMapPublic then
        FluxBattlefieldMapWorldFeatures:RefreshBattlefieldMapPublic(true)
    end
end

function FluxBattlefieldMapPinRouter:ScheduleKickstart()
    if not IsPinRouterWanted() or not C_Timer or not C_Timer.After then
        return
    end

    kickstartGeneration = kickstartGeneration + 1
    local generation = kickstartGeneration

    for _, delay in ipairs(KICKSTART_DELAYS) do
        C_Timer.After(delay, function()
            if generation ~= kickstartGeneration then
                return
            end
            if not IsPinRouterWanted() then
                return
            end
            FluxBattlefieldMapPinRouter:Install()
        end)
    end
end

local function HookCanvasScale(mapFrame)
    if not mapFrame or mapFrame._fluxHBDScaleHooked or not hooksecurefunc or not mapFrame.OnCanvasScaleChanged then
        return
    end
    mapFrame._fluxHBDScaleHooked = true
    hooksecurefunc(mapFrame, "OnCanvasScaleChanged", function()
        if FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield() then
            FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins()
        end
    end)
end

function FluxBattlefieldMapPinRouter:Install()
    if BlizzardHasQuestPins() or not IsPinRouterWanted() then
        return false
    end

    local mapFrame = GetBattlefieldMap()
    if not mapFrame or not mapFrame.AddDataProvider then
        return false
    end

    HookCanvasScale(mapFrame)
    InstallHBDProvider(mapFrame)
    InstallWorldMapPriorityHooks()
    TryHookQuestieQueueInit()

    if FluxBattlefieldMapPinTooltips and FluxBattlefieldMapPinTooltips.Install then
        FluxBattlefieldMapPinTooltips:Install()
    end

    if not state.installed then
        state.installed = true
    end

    self:RefreshAllThirdPartyPins()
    return true
end

function FluxBattlefieldMapPinRouter:Uninstall()
    kickstartGeneration = kickstartGeneration + 1

    if not state.installed then
        if FluxBattlefieldMapPinTooltips and FluxBattlefieldMapPinTooltips.Uninstall then
            FluxBattlefieldMapPinTooltips:Uninstall()
        end
        return
    end

    if FluxBattlefieldMapPinTooltips and FluxBattlefieldMapPinTooltips.Uninstall then
        FluxBattlefieldMapPinTooltips:Uninstall()
    end

    local mapFrame = GetBattlefieldMap()
    for worldProvider, route in pairs(state.hbdRoutes) do
        if route.battlefieldProvider and mapFrame and mapFrame.RemoveDataProvider then
            pcall(mapFrame.RemoveDataProvider, mapFrame, route.battlefieldProvider)
        end
        if route.battlefieldProvider and route.battlefieldProvider.RemoveAllData then
            pcall(route.battlefieldProvider.RemoveAllData, route.battlefieldProvider)
        end
        if route.origHandlePin then
            worldProvider.HandlePin = route.origHandlePin
        end
        if route.origRefreshAllData then
            worldProvider.RefreshAllData = route.origRefreshAllData
        end
    end

    if state.acquirePinGuarded and mapFrame and state.origAcquirePin then
        mapFrame.AcquirePin = state.origAcquirePin
    end

    state.installed = false
    table.wipe(state.hbdRoutes)
    state.hbdAvailable = false
    state.acquirePinGuarded = false
    state.acquirePinPostHooked = false
    state.origAcquirePin = nil
    state.questieCatchupScheduled = false
end

local zoneRefresher = CreateFrame("Frame")
zoneRefresher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneRefresher:RegisterEvent("ADDON_LOADED")
zoneRefresher:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneRefresher:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "PLAYER_ENTERING_WORLD" then
        if IsPinRouterWanted() then
            FluxBattlefieldMapPinRouter:ScheduleKickstart()
        end
        return
    end

    if not state.installed and event ~= "ADDON_LOADED" then
        return
    end
    if not IsPinRouterWanted() and event ~= "ADDON_LOADED" then
        return
    end

    if event == "ZONE_CHANGED_NEW_AREA" then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.2, function()
                if state.installed and IsPinRouterWanted() then
                    FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins()
                end
            end)
        end
        return
    end

    if event == "ADDON_LOADED" then
        if not IsPinRouterWanted() then
            return
        end
        local needsInstall = false
        for _, entry in ipairs(EnumerateHBDLibs()) do
            if entry.pins.worldmapProvider and not state.hbdRoutes[entry.pins.worldmapProvider] then
                needsInstall = true
                break
            end
        end
        if not needsInstall then
            local mapFrame = GetBattlefieldMap()
            local worldMap = _G.WorldMapFrame
            if mapFrame and worldMap and worldMap.pinPools then
                for template in pairs(worldMap.pinPools) do
                    if not mapFrame.pinPools or not mapFrame.pinPools[template] then
                        needsInstall = true
                        break
                    end
                end
            end
        end
        if not needsInstall and loadedAddon ~= "Questie" then
            return
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, function()
                if IsPinRouterWanted() then
                    FluxBattlefieldMapPinRouter:Install()
                    FluxBattlefieldMapPinRouter:ScheduleKickstart()
                end
            end)
        end
    end
end)

