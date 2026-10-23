-- FluxBattlefieldMapPinTooltips.lua
-- Map-context shims and mouse fixes so third-party world-map pin tooltips work on
-- BattlefieldMapFrame when WM features route pins away from WorldMapFrame.

local addonName, addonTable = ...

FluxBattlefieldMapPinTooltips = {}

local HBD_LIBS = {
    { name = "HereBeDragonsQuestie-Pins-2.0", template = "HereBeDragonsPinsTemplateQuestie" },
    { name = "HereBeDragons-Pins-2.0", template = "HereBeDragonsPinsTemplate" },
}

local state = {
    installed = false,
    origWorldMapGetMapID = nil,
    registerPinHooked = false,
    -- [provider] = original GetMap
    hbdGetMapWrapped = {},
    -- [provider] = { orig = fn, template = string }
    hbdRemoveAllDataWrapped = {},
}

local function GetBattlefieldMap()
    if FluxBattlefieldMap and FluxBattlefieldMap.GetMapFrame then
        return FluxBattlefieldMap:GetMapFrame()
    end
    return _G.BattlefieldMapFrame
end

local function ShouldShimMapContext()
    if not state.installed then
        return false
    end
    if FluxBattlefieldMapPinRouter and FluxBattlefieldMapPinRouter.ShouldRouteToBattlefield then
        return FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield()
    end
    return false
end

local function EnumerateHBDLibs()
    local found = {}
    if not LibStub then
        return found
    end
    for _, entry in ipairs(HBD_LIBS) do
        local ok, pins = pcall(LibStub, entry.name, true)
        local router = FluxBattlefieldMapPinRouter
        local supported = not router or not router.IsLibrarySupported or router:IsLibrarySupported(entry.name)
        if supported and ok and pins and pins.worldmapProvider then
            found[#found + 1] = {
                name = entry.name,
                template = entry.template,
                pins = pins,
            }
        end
    end
    return found
end

local function ShimmedWorldMapGetMapID(self)
    if ShouldShimMapContext() then
        local bfMap = GetBattlefieldMap()
        if bfMap and bfMap.GetMapID then
            local mapID = bfMap:GetMapID()
            if mapID then
                return mapID
            end
        end
    end
    if state.origWorldMapGetMapID then
        return state.origWorldMapGetMapID(self)
    end
    return nil
end

local function ShimmedHBDRemoveAllData(provider)
    local wrap = state.hbdRemoveAllDataWrapped[provider]
    local worldMap = _G.WorldMapFrame
    if worldMap and worldMap.RemoveAllPinsByTemplate and wrap and wrap.template then
        pcall(worldMap.RemoveAllPinsByTemplate, worldMap, wrap.template)
        return
    end
    if wrap and wrap.orig then
        pcall(wrap.orig, provider)
    end
end

local function ShimmedHBDGetMap(provider)
    if ShouldShimMapContext() then
        local bfMap = GetBattlefieldMap()
        if bfMap then
            return bfMap
        end
    end
    local orig = state.hbdGetMapWrapped[provider]
    if orig then
        return orig(provider)
    end
    if provider.owningMap then
        return provider.owningMap
    end
    return _G.WorldMapFrame
end

local function EnablePinTooltipMouse(pin)
    if not pin then
        return
    end
    if pin.OnMouseEnter and not pin:GetScript("OnEnter") then
        if pin.SetMouseMotionEnabled then
            pin:SetMouseMotionEnabled(true)
        end
        pin:SetScript("OnEnter", pin.OnMouseEnter)
        if pin.OnMouseLeave then
            pin:SetScript("OnLeave", pin.OnMouseLeave)
        end
    end
end

function FluxBattlefieldMapPinTooltips:OnHBDPinAcquired(pin, icon)
    if not pin then
        return
    end
    pin:EnableMouse(false)
    if pin.SetMouseMotionEnabled then
        pin:SetMouseMotionEnabled(false)
    end
    if pin.SetMouseClickEnabled then
        pin:SetMouseClickEnabled(false)
    end
    if icon then
        icon:EnableMouse(true)
        if icon.SetMouseMotionEnabled then
            icon:SetMouseMotionEnabled(true)
        end
    end
end

function FluxBattlefieldMapPinTooltips:IsInstalled()
    return state.installed
end

function FluxBattlefieldMapPinTooltips:GetDiagnostics()
    return {
        installed = state.installed,
        getMapShim = next(state.hbdGetMapWrapped) ~= nil,
        getMapIDShim = state.origWorldMapGetMapID ~= nil,
        registerPinHook = state.registerPinHooked,
    }
end

local function WrapHBDGetMap(HBDPins, template)
    if not HBDPins or not HBDPins.worldmapProvider then
        return
    end
    local provider = HBDPins.worldmapProvider
    if not state.hbdGetMapWrapped[provider] then
        state.hbdGetMapWrapped[provider] = provider.GetMap
        provider.GetMap = function(self)
            return ShimmedHBDGetMap(self)
        end
    end
    if provider.RemoveAllData and not state.hbdRemoveAllDataWrapped[provider] then
        state.hbdRemoveAllDataWrapped[provider] = {
            orig = provider.RemoveAllData,
            template = template,
        }
        provider.RemoveAllData = function(self)
            ShimmedHBDRemoveAllData(self)
        end
    end
end

local function WrapAllHBDLibs()
    for _, entry in ipairs(EnumerateHBDLibs()) do
        WrapHBDGetMap(entry.pins, entry.template)
    end
end

local function UnwrapHBDGetMap()
    for provider, origGetMap in pairs(state.hbdGetMapWrapped) do
        provider.GetMap = origGetMap
    end
    table.wipe(state.hbdGetMapWrapped)
    for provider, wrap in pairs(state.hbdRemoveAllDataWrapped) do
        if wrap and wrap.orig then
            provider.RemoveAllData = wrap.orig
        end
    end
    table.wipe(state.hbdRemoveAllDataWrapped)
end

local function WrapWorldMapGetMapID()
    local worldMap = _G.WorldMapFrame
    if not worldMap or not worldMap.GetMapID or state.origWorldMapGetMapID then
        return
    end
    state.origWorldMapGetMapID = worldMap.GetMapID
    worldMap.GetMapID = ShimmedWorldMapGetMapID
end

local function UnwrapWorldMapGetMapID()
    local worldMap = _G.WorldMapFrame
    if worldMap and state.origWorldMapGetMapID then
        worldMap.GetMapID = state.origWorldMapGetMapID
        state.origWorldMapGetMapID = nil
    end
end

local function WrapBattlefieldRegisterPin()
    -- Questie pins get their mouse setup directly from OnHBDPinAcquired. Leave
    -- the shared native registration path alone on modern Forever maps.
    if type(QuestDataProviderMixin) == "table" then return end
    if state.registerPinHooked or not hooksecurefunc then
        return
    end
    local mapFrame = GetBattlefieldMap()
    if not mapFrame or not mapFrame.RegisterPin then
        return
    end
    hooksecurefunc(mapFrame, "RegisterPin", function(_, pin)
        if state.installed then
            EnablePinTooltipMouse(pin)
        end
    end)
    state.registerPinHooked = true
end

function FluxBattlefieldMapPinTooltips:Install()
    UnwrapWorldMapGetMapID()

    if state.installed then
        WrapAllHBDLibs()
        WrapBattlefieldRegisterPin()
        return true
    end

    WrapAllHBDLibs()
    WrapBattlefieldRegisterPin()
    state.installed = true
    return true
end

function FluxBattlefieldMapPinTooltips:Uninstall()
    if not state.installed then
        return
    end

    UnwrapHBDGetMap()
    UnwrapWorldMapGetMapID()
    state.installed = false
end
