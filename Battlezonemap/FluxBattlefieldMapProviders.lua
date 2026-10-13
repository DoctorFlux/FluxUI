-- FluxBattlefieldMapProviders.lua
-- Adds the same Blizzard data providers the world map uses onto BattlefieldMapFrame.
-- A mixin is added only when this client actually has it. Pins stay on the map canvas,
-- so zoom uses MapCanvas OnCanvasScaleChanged. Flux does not call RefreshAllData.

FluxBattlefieldMapProviders = {}

local QUEST_MIXINS = {
    "QuestOfferDataProviderMixin",
    "BonusObjectiveDataProviderMixin",
    "QuestDataProviderMixin",
    "WaypointLocationDataProviderMixin",
    "SuperTrackWaypointDataProviderMixin",
}

local FEATURE_MIXINS = {
    "AreaPOIDataProviderMixin",
    "VignetteDataProviderMixin",
    "FlightPointDataProviderMixin",
    "GossipDataProviderMixin",
    "DigSiteDataProviderMixin",
    "DungeonEntranceDataProviderMixin",
}

local FRAME_LEVELS = {
    { "PIN_FRAME_LEVEL_BONUS_OBJECTIVE" },
    { "PIN_FRAME_LEVEL_WORLD_QUEST", 500 },
    { "PIN_FRAME_LEVEL_QUEST_PING" },
    { "PIN_FRAME_LEVEL_SUPER_TRACKED_QUEST" },
    { "PIN_FRAME_LEVEL_SUPER_TRACKED_CONTENT" },
    { "PIN_FRAME_LEVEL_WAYPOINT_LOCATION" },
}

local added = {}

local function GetMap(mapFrame)
    if mapFrame and mapFrame.AddDataProvider then
        return mapFrame
    end
    if FluxBattlefieldMap and FluxBattlefieldMap.GetMapFrame then
        return FluxBattlefieldMap:GetMapFrame()
    end
    return _G.BattlefieldMapFrame
end

local function MapHasMixin(mapFrame, mixin)
    if not mapFrame or not mapFrame.dataProviders or not mixin or not mixin.RefreshAllData then
        return false
    end
    for provider in pairs(mapFrame.dataProviders) do
        if provider._fluxSourceMixin == mixin or provider.RefreshAllData == mixin.RefreshAllData then
            return true
        end
    end
    return false
end

local BLOB_LEVEL_ANCHORS = {
    "PIN_FRAME_LEVEL_SCENARIO_BLOB",
    "PIN_FRAME_LEVEL_MAP_HIGHLIGHT",
    "PIN_FRAME_LEVEL_FOG_OF_WAR",
}

local function InsertBlobFrameLevel(manager)
    if manager.InsertFrameLevelBelow then
        for i = 1, #BLOB_LEVEL_ANCHORS do
            local ok, inserted = pcall(manager.InsertFrameLevelBelow, manager, "PIN_FRAME_LEVEL_QUEST_BLOB", BLOB_LEVEL_ANCHORS[i])
            if ok and inserted then
                return
            end
        end
    end
    if manager.AddFrameLevel then
        pcall(manager.AddFrameLevel, manager, "PIN_FRAME_LEVEL_QUEST_BLOB")
    end
end

local function RegisterFrameLevels(mapFrame)
    if not mapFrame or not mapFrame.GetPinFrameLevelsManager then
        return
    end
    local ok, manager = pcall(mapFrame.GetPinFrameLevelsManager, mapFrame)
    if not ok or not manager or not manager.AddFrameLevel then
        return
    end
    InsertBlobFrameLevel(manager)
    for i = 1, #FRAME_LEVELS do
        pcall(manager.AddFrameLevel, manager, FRAME_LEVELS[i][1], FRAME_LEVELS[i][2])
    end
    if QuestOfferDataProviderMixin and QuestOfferDataProviderMixin.PIN_LEVEL_RANGE then
        pcall(manager.AddFrameLevel, manager, "PIN_FRAME_LEVEL_QUEST_OFFER", QuestOfferDataProviderMixin.PIN_LEVEL_RANGE)
    end
    if C_QuestLog and C_QuestLog.GetMaxNumQuests then
        local maxOk, maxQuests = pcall(C_QuestLog.GetMaxNumQuests)
        if maxOk and type(maxQuests) == "number" then
            pcall(manager.AddFrameLevel, manager, "PIN_FRAME_LEVEL_ACTIVE_QUEST", maxQuests)
        end
    end
end

local MAX_QUEST_SCAN = 400

local function Secrets()
    return _G.Flux and _G.Flux.Secrets
end

local function HasSecretValues()
    if issecretvalue then
        return true
    end
    local secrets = Secrets()
    return secrets and secrets.CanAccessSecrets and secrets.CanAccessSecrets() or false
end

local function ReadField(info, key)
    if type(info) ~= "table" then
        return nil
    end
    local ok, value = pcall(function()
        return info[key]
    end)
    if not ok then
        return nil
    end
    return value
end

local function HasValue(value)
    local ok, missing = pcall(function()
        return value == nil
    end)
    if not ok then
        return true
    end
    return not missing
end

local function AsBool(value, default)
    local secrets = Secrets()
    if secrets and secrets.SafeBooleanTest then
        return secrets.SafeBooleanTest(value, default and true or false)
    end
    local ok, truthy = pcall(function()
        return value and true or false
    end)
    if not ok then
        return default and true or false
    end
    return truthy
end

local function SameID(a, b)
    local ok, same = pcall(function()
        return a == b
    end)
    if not ok then
        return false
    end
    return AsBool(same, false)
end

local function IsSecretList(list)
    if type(list) ~= "table" then
        return false
    end
    if issecrettable then
        local ok, secret = pcall(issecrettable, list)
        if ok and secret then
            return true
        end
    end
    local secrets = Secrets()
    if secrets and secrets.IsSecretTable and secrets.IsSecretTable(list) then
        return true
    end
    if secrets and secrets.CanAccessTable and not secrets.CanAccessTable(list) then
        return true
    end
    local ok = pcall(function()
        for _ in ipairs(list) do
            break
        end
    end)
    return not ok
end

local function FetchQuestList(mapID)
    if GetQuestsOnMapCached then
        local ok, list = pcall(GetQuestsOnMapCached, mapID)
        if ok then
            return list
        end
    end
    if C_QuestLog and C_QuestLog.GetQuestsOnMap then
        local ok, list = pcall(C_QuestLog.GetQuestsOnMap, mapID)
        if ok then
            return list
        end
    end
    return nil
end

local function Invoke(fn, ...)
    if not fn then
        return nil
    end
    if securecall then
        return securecall(fn, ...)
    end
    return fn(...)
end

local function InstallQuestFilters(provider)
    function provider:ShouldShowQuest(questID, mapType, _doesMapShowTaskObjectives, isMapIndicatorQuest)
        if QuestUtils_IsQuestWorldQuest then
            local ok, world = pcall(QuestUtils_IsQuestWorldQuest, questID)
            if ok and AsBool(world, false) then
                return false
            end
        end
        if QuestUtils_IsQuestBonusObjective then
            local ok, bonus = pcall(QuestUtils_IsQuestBonusObjective, questID)
            if ok and AsBool(bonus, false) then
                return false
            end
        end
        if AsBool(isMapIndicatorQuest, false) then
            return false
        end
        return true
    end
end

-- Tainted AcquirePin reaches two protected calls. pcall does not stop
-- ADDON_ACTION_BLOCKED:
--   CheckMouseButtonPassthrough -> Button:SetPassThroughButtons
--   UpdateMousePropagation -> Frame:SetPropagateMouseClicks
-- CreateFromMixins copies both onto the pin mixins the frame actually searches,
-- so replacing only MapCanvasPinMixin / SuperTrackablePinMixin misses AreaPOI.
-- Skip every copy while the pin is acquired, then leave the skip on that pin so
-- a reused pool frame does not call them again. Secure acquires are left alone.
local pinAcquireGuardDepth = 0
local pinAcquireGuardSaved

local PIN_METHOD_MIXINS = {
    "MapCanvasPinMixin",
    "BaseMapPoiPinMixin",
    "SuperTrackablePinMixin",
    "SuperTrackablePoiPinMixin",
    "SuperTrackableVignettePinMixin",
    "VignettePinMixin",
    "VignettePinBaseMixin",
    "FyrakkFlightVignettePinMixin",
    "QuestPinMixin",
    "QuestOfferPinMixin",
    "BonusObjectivePinMixin",
    "WaypointLocationPinMixin",
    "SuperTrackWaypointPinMixin",
    "QuestBlobPinMixin",
    "MapPinPingMixin",
}

local GUARDED_PIN_METHODS = {
    "CheckMouseButtonPassthrough",
    "UpdateMousePropagation",
}

local function PinMethodNoop()
end

local function PushPinAcquireGuard()
    if pinAcquireGuardDepth == 0 then
        local saved = {}
        for i = 1, #PIN_METHOD_MIXINS do
            local mixin = _G[PIN_METHOD_MIXINS[i]]
            if type(mixin) == "table" then
                for j = 1, #GUARDED_PIN_METHODS do
                    local methodName = GUARDED_PIN_METHODS[j]
                    local method = mixin[methodName]
                    if type(method) == "function" and method ~= PinMethodNoop then
                        mixin[methodName] = PinMethodNoop
                        saved[#saved + 1] = { mixin, methodName, method }
                    end
                end
            end
        end
        pinAcquireGuardSaved = saved
    end
    pinAcquireGuardDepth = pinAcquireGuardDepth + 1
end

local function PopPinAcquireGuard()
    if pinAcquireGuardDepth == 0 then
        return
    end
    pinAcquireGuardDepth = pinAcquireGuardDepth - 1
    if pinAcquireGuardDepth ~= 0 or not pinAcquireGuardSaved then
        return
    end
    local saved = pinAcquireGuardSaved
    pinAcquireGuardSaved = nil
    for i = 1, #saved do
        local mixin, methodName, method = saved[i][1], saved[i][2], saved[i][3]
        if mixin[methodName] == PinMethodNoop then
            mixin[methodName] = method
        end
    end
end

local function InstallAcquirePinGuard(mapFrame)
    if not mapFrame or mapFrame._fluxPassThroughGuard or not mapFrame.AcquirePin then
        return
    end
    if not MapCanvasPinMixin or not MapCanvasPinMixin.CheckMouseButtonPassthrough then
        return
    end
    mapFrame._fluxPassThroughGuard = true
    local origAcquire = mapFrame.AcquirePin
    function mapFrame:AcquirePin(pinTemplate, ...)
        if issecure and issecure() then
            return origAcquire(self, pinTemplate, ...)
        end
        PushPinAcquireGuard()
        local ok, pin = pcall(origAcquire, self, pinTemplate, ...)
        PopPinAcquireGuard()
        if not ok or not pin then
            return nil
        end
        pin.CheckMouseButtonPassthrough = PinMethodNoop
        if pin.UpdateMousePropagation ~= nil then
            pin.UpdateMousePropagation = PinMethodNoop
        end
        return pin
    end
end

local function PlaceQuestPin(provider, questID, x, y, offset, isWaypoint)
    local map = provider.GetMap and provider:GetMap()
    if not map or not map.AcquirePin or not provider.GetPinTemplate then
        return nil
    end
    InstallAcquirePinGuard(map)
    local template = provider:GetPinTemplate()
    local acquired, pin = pcall(map.AcquirePin, map, template)
    if not acquired or not pin then
        return nil
    end
    pin.dataProvider = provider
    if pin.SetQuestID then
        pcall(pin.SetQuestID, pin, questID)
    end
    local super = false
    if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID then
        local idOk, tracked = pcall(C_SuperTrack.GetSuperTrackedQuestID)
        super = idOk and SameID(questID, tracked) or false
    end
    pin.isSuperTracked = super
    if pin.UseFrameLevelType then
        if super then
            pcall(pin.UseFrameLevelType, pin, "PIN_FRAME_LEVEL_SUPER_TRACKED_QUEST")
        else
            pcall(pin.UseFrameLevelType, pin, "PIN_FRAME_LEVEL_ACTIVE_QUEST", offset)
        end
    end
    if pin.ApplyFrameLevel then
        pcall(pin.ApplyFrameLevel, pin)
    end
    if pin.Display then
        pin.Display:ClearAllPoints()
        pin.Display:SetPoint("CENTER")
    end
    if pin.SetSelected then
        pcall(pin.SetSelected, pin, super)
    end
    if pin.SetStyle and POIButtonUtil and POIButtonUtil.Style then
        local style = isWaypoint and POIButtonUtil.Style.Waypoint or nil
        if not style and POIButtonUtil.GetStyle then
            local styleOk, result = pcall(POIButtonUtil.GetStyle, questID)
            if styleOk then
                style = result
            end
        end
        if style == nil then
            style = POIButtonUtil.Style.QuestInProgress or POIButtonUtil.Style.Normal
        end
        if style ~= nil then
            pcall(pin.SetStyle, pin, style)
        end
    end
    if pin.UpdateButtonStyle then
        pcall(pin.UpdateButtonStyle, pin)
    end
    if pin.EvaluateManagedHighlight then
        pcall(pin.EvaluateManagedHighlight, pin)
    end
    if pin.SetMapPinScale then
        pin:SetMapPinScale(0.7, 1, 0.7, 0.7)
    elseif pin.SetScalingLimits then
        pin:SetScalingLimits(1, 0.7, 0.7)
    end
    if pin.ApplyCurrentScale then
        pcall(pin.ApplyCurrentScale, pin)
    end
    if pin.SetPosition then
        pcall(pin.SetPosition, pin, x, y)
    end
    if pin.Show then
        pin:Show()
    end
    return pin
end

local function RefreshSecretQuests(provider)
    if not provider.GetMap or not provider:GetMap() then
        return
    end
    if POIButtonHighlightManager then
        POIButtonHighlightManager.questID = nil
    end
    if provider.RemoveAllData then
        pcall(provider.RemoveAllData, provider)
    end
    local map = provider:GetMap()
    if not map or not map.GetMapID then
        return
    end
    local mapID = map:GetMapID()
    if not HasValue(mapID) then
        return
    end
    if GetCVarBool then
        local ok, enabled = pcall(GetCVarBool, "questPOI")
        if ok and not AsBool(enabled, true) then
            return
        end
    end

    local mapType
    if C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, mapID)
        if ok and type(info) == "table" then
            mapType = info.mapType
        end
    end
    local showTasks = false
    if C_TaskQuest and C_TaskQuest.DoesMapShowTaskQuestObjectives then
        local ok, shown = pcall(C_TaskQuest.DoesMapShowTaskQuestObjectives, mapID)
        if ok then
            showTasks = AsBool(shown, false)
        end
    end

    local pins = {}
    local count = 0
    local function Add(questID, x, y, isIndicator, offset, isWaypoint)
        if not HasValue(questID) or not HasValue(x) or not HasValue(y) then
            return
        end
        if not isWaypoint then
            local showOk, show = pcall(provider.ShouldShowQuest, provider, questID, mapType, showTasks, isIndicator)
            if showOk and not show then
                return
            end
        end
        local pin = PlaceQuestPin(provider, questID, x, y, offset, isWaypoint)
        if pin then
            pins[#pins + 1] = pin
        end
    end

    local list = FetchQuestList(mapID)
    if type(list) == "table" then
        local i = 1
        while i <= MAX_QUEST_SCAN do
            local ok, info = pcall(function()
                return list[i]
            end)
            if not ok or info == nil then
                break
            end
            count = count + 1
            Add(ReadField(info, "questID"), ReadField(info, "x"), ReadField(info, "y"), ReadField(info, "isMapIndicatorQuest"), i, false)
            i = i + 1
        end
    end
    if #pins == 0 and C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo and C_QuestLog.GetNextWaypointForMap then
        local numOk, numEntries = pcall(C_QuestLog.GetNumQuestLogEntries)
        if numOk and type(numEntries) == "number" then
            for logIndex = 1, numEntries do
                local infoOk, info = pcall(C_QuestLog.GetInfo, logIndex)
                if infoOk and type(info) == "table" and not AsBool(ReadField(info, "isHeader"), false) then
                    local questID = ReadField(info, "questID")
                    if HasValue(questID) and not SameID(questID, 0) then
                        local wayOk, wayX, wayY = pcall(C_QuestLog.GetNextWaypointForMap, questID, mapID)
                        if wayOk then
                            Add(questID, wayX, wayY, false, logIndex, false)
                        end
                    end
                end
            end
        end
    end

    local waypointQuestID
    local haveWaypoint = false
    local function TakeWaypoint(fn)
        if haveWaypoint or not fn then
            return
        end
        local ok, id = pcall(fn)
        if ok and HasValue(id) and not SameID(id, 0) then
            waypointQuestID = id
            haveWaypoint = true
        end
    end
    TakeWaypoint(QuestMapFrame_GetFocusedQuestID)
    if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID then
        TakeWaypoint(C_SuperTrack.GetSuperTrackedQuestID)
    end
    if haveWaypoint and C_QuestLog and C_QuestLog.GetNextWaypointForMap then
        local ok, x, y = pcall(C_QuestLog.GetNextWaypointForMap, waypointQuestID, mapID)
        if ok then
            Add(waypointQuestID, x, y, false, count + 1, true)
        end
    end

    pcall(function()
        if not provider.poiQuantizer or not provider.poiQuantizer.ClearAndQuantize then
            return
        end
        provider.poiQuantizer:ClearAndQuantize(pins)
        for i = 1, #pins do
            local pin = pins[i]
            if pin and pin.SetPosition then
                local posOk, px, py = pcall(function()
                    return pin.quantizedX or pin.normalizedX, pin.quantizedY or pin.normalizedY
                end)
                if posOk and px ~= nil and py ~= nil then
                    pin:SetPosition(px, py)
                end
            end
        end
    end)
    if provider.UpdatePing then
        Invoke(provider.UpdatePing, provider)
    end
end

local function InstallSecretQuestRefresh(provider)
    if not HasSecretValues() then
        return
    end
    local queued = false
    local nextAt = 0
    local function Run()
        queued = false
        if provider.GetMap and provider:GetMap() then
            RefreshSecretQuests(provider)
        end
        nextAt = (GetTime and GetTime() or 0) + 0.25
    end
    function provider:RefreshAllData()
        local now = GetTime and GetTime() or 0
        if now >= nextAt then
            Run()
            return
        end
        if queued or not C_Timer or not C_Timer.After then
            return
        end
        queued = true
        C_Timer.After(nextAt - now, Run)
    end
end

local function SetupProvider(name, provider)
    provider._fluxMixinName = name
    if name == "QuestDataProviderMixin" then
        InstallQuestFilters(provider)
        InstallSecretQuestRefresh(provider)
        local originalHighlight = provider.OnHighlightedQuestPOIChange
        if originalHighlight then
            function provider:OnHighlightedQuestPOIChange(...)
                if not self.GetMap or not self:GetMap() then
                    return
                end
                return originalHighlight(self, ...)
            end
        end
        local originalSize = provider.OnCanvasSizeChanged
        function provider:OnCanvasSizeChanged(...)
            if not self.poiQuantizer then
                return
            end
            if originalSize then
                return originalSize(self, ...)
            end
        end
    end
end

local function EventValid(event)
    if C_EventUtils and C_EventUtils.IsEventValid then
        local ok, valid = pcall(C_EventUtils.IsEventValid, event)
        if ok then
            return valid and true or false
        end
    end
    return true
end

local function ProviderCanStart(name)
    if name == "BonusObjectiveDataProviderMixin" then
        return QuestMapFrame and C_TaskQuest and C_TaskQuest.GetQuestsOnMap and true or false
    end
    if name == "VignetteDataProviderMixin" then
        return C_VignetteInfo and EventValid("VIGNETTES_UPDATED") and true or false
    end
    if name == "FlightPointDataProviderMixin" then
        -- Classic Era and Anniversary world maps leave flight points commented out.
        return WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and true or false
    end
    return true
end

local function CallMethod(obj, methodName)
    local method = obj and obj[methodName]
    if not method then
        return
    end
    if securecall then
        pcall(securecall, method, obj)
    else
        pcall(method, obj)
    end
end

local function HasQuestID(questID)
    if not HasValue(questID) or SameID(questID, 0) then
        return false
    end
    return true
end

local function BlobQuestID(pin)
    if HasQuestID(pin.focusedQuestID) then
        return pin.focusedQuestID
    end
    if QuestMapFrame_GetFocusedQuestID then
        local ok, focused = pcall(QuestMapFrame_GetFocusedQuestID)
        if ok and HasQuestID(focused) then
            pin.focusedQuestID = focused
            return focused
        end
    end
    if HasQuestID(pin.questID) then
        return pin.questID
    end
    if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID then
        local ok, tracked = pcall(C_SuperTrack.GetSuperTrackedQuestID)
        if ok and HasQuestID(tracked) then
            pin.questID = tracked
            return tracked
        end
    end
    return nil
end

local function CoverBlobCanvas(pin)
    local map = pin.GetMap and pin:GetMap()
    if not map or not map.GetCanvas then
        return false
    end
    local canvas = map:GetCanvas()
    if not canvas then
        return false
    end
    local widthOk, width = pcall(canvas.GetWidth, canvas)
    local heightOk, height = pcall(canvas.GetHeight, canvas)
    if not widthOk or not heightOk or type(width) ~= "number" or type(height) ~= "number" or width <= 1 or height <= 1 then
        return false
    end
    pin:SetScale(1)
    if pin.SetIgnoreGlobalPinScale then
        pin:SetIgnoreGlobalPinScale(true)
    end
    pin:SetParent(canvas)
    pin:ClearAllPoints()
    pin:SetSize(width, height)
    pin:SetPoint("CENTER", canvas, "CENTER", 0, 0)
    if pin.ApplyFrameLevel then
        pcall(pin.ApplyFrameLevel, pin)
    end
    pin:Show()
    return true
end

local function InstallBlobRefresh(pin)
    if not pin or pin._fluxBlobRefresh then
        return
    end
    pin._fluxBlobRefresh = true
    if pin.EnableMouse then
        pin:EnableMouse(false)
    end
    function pin:OnCanvasSizeChanged()
        self:Refresh()
    end
    function pin:OnMapChanged()
        self:Refresh()
    end
    function pin:Refresh()
        local map = self.GetMap and self:GetMap()
        if not map then
            return
        end
        if not CoverBlobCanvas(self) then
            return
        end
        self.mapAllowsBlobs = true
        local mapID = map.GetMapID and map:GetMapID()
        if HasValue(mapID) and self.SetMapID then
            pcall(self.SetMapID, self, mapID)
        end
        if self.DrawNone then
            pcall(self.DrawNone, self)
        end
        if not self.DrawBlob then
            return
        end
        local function Draw(questID)
            if HasQuestID(questID) then
                pcall(self.DrawBlob, self, questID, true)
            end
        end
        Draw(BlobQuestID(self))
        Draw(self.highlightedQuestID)
        if POIButtonHighlightManager and POIButtonHighlightManager.GetQuestID then
            local ok, id = pcall(POIButtonHighlightManager.GetQuestID, POIButtonHighlightManager)
            if ok then
                Draw(id)
            end
        end
    end
end

local function AllowBlobOnMap(pin)
    local map = pin.GetMap and pin:GetMap()
    if not map or not map.GetMapID then
        return
    end
    local mapID = map:GetMapID()
    if not HasValue(mapID) then
        return
    end
    local mapType
    if C_Map and C_Map.GetMapInfo then
        local infoOk, info = pcall(C_Map.GetMapInfo, mapID)
        if infoOk and type(info) == "table" then
            mapType = info.mapType
        end
    end
    if MapUtil and MapUtil.ShouldMapTypeShowQuests then
        local allowOk, allow = pcall(MapUtil.ShouldMapTypeShowQuests, mapType)
        pin.mapAllowsBlobs = allowOk and AsBool(allow, false) or false
    else
        pin.mapAllowsBlobs = true
    end
    if pin.SetMapID then
        pcall(pin.SetMapID, pin, mapID)
    end
end

local function StartBlobPin(pin, retried)
    InstallBlobRefresh(pin)
    AllowBlobOnMap(pin)
    local sized = CoverBlobCanvas(pin)
    CallMethod(pin, "OnShow")
    if pin.Refresh then
        pcall(pin.Refresh, pin)
    end
    if not sized and not retried and C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if pin.GetMap and pin:GetMap() then
                StartBlobPin(pin, true)
            end
        end)
    end
end

local function StartProvider(mapFrame, name, provider)
    if not mapFrame.IsShown or not mapFrame:IsShown() then
        return
    end
    if name == "QuestBlobDataProviderMixin" and provider.pin then
        StartBlobPin(provider.pin)
        return
    end
    CallMethod(provider, "OnShow")
    CallMethod(provider, "OnMapChanged")
end

local function TryAdd(mapFrame, name)
    local mixin = _G[name]
    if type(mixin) ~= "table" or not CreateFromMixins or not mapFrame.AddDataProvider then
        return
    end
    if not ProviderCanStart(name) or MapHasMixin(mapFrame, mixin) then
        return
    end
    local provider = CreateFromMixins(mixin)
    provider._fluxSourceMixin = mixin
    SetupProvider(name, provider)
    provider._fluxBattlefieldProvider = true
    local ok = pcall(mapFrame.AddDataProvider, mapFrame, provider)
    if not ok then
        if mapFrame.RemoveDataProvider then
            pcall(mapFrame.RemoveDataProvider, mapFrame, provider)
        end
        return
    end
    added[#added + 1] = provider
    StartProvider(mapFrame, name, provider)
end

local areaFrame
local areaWatcher
local areaHooks = false
local questAreaSupported
local areaDirty = false
local areaQueued = false
local areaWidth, areaHeight, areaMapID, areaScale, areaQuest

local function MapCanvas(mapFrame)
    mapFrame = GetMap(mapFrame)
    if not mapFrame then
        return nil, nil
    end
    local canvas
    if mapFrame.GetCanvas then
        local ok, value = pcall(mapFrame.GetCanvas, mapFrame)
        if ok then
            canvas = value
        end
    end
    if not canvas and mapFrame.ScrollContainer then
        canvas = mapFrame.ScrollContainer.Child
    end
    return mapFrame, canvas
end

local function QuestPOIFrameExists()
    if questAreaSupported ~= nil then
        return questAreaSupported
    end
    -- Classic Era and Anniversary define issecretvalue but do not have this frame.
    -- Creating it prints "Unknown frame type" even inside pcall.
    -- Forever is WOW_PROJECT_CAMELOT, not mainline, and still ships QuestPOIFrame
    -- (QuestBlobPinTemplate). The selected-quest blue area is this frame.
    local client = _G.Flux and _G.Flux.Client
    local retailFamily = client and client.isRetail and true or false
    local mainline = WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and true or false
    local camelot = WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT and true or false
    questAreaSupported = retailFamily or mainline or camelot
    return questAreaSupported
end

local function EnsureArea(canvas)
    if not QuestPOIFrameExists() then
        return nil
    end
    if areaFrame then
        if areaFrame:GetParent() ~= canvas then
            areaFrame:SetParent(canvas)
        end
        return areaFrame
    end
    local frame
    local ok = pcall(function()
        frame = CreateFrame("QuestPOIFrame", nil, canvas)
    end)
    if not ok or not frame or not frame.DrawBlob then
        questAreaSupported = false
        if frame and frame.Hide then
            frame:Hide()
            frame:SetParent(nil)
        end
        return nil
    end
    frame:SetFillTexture("Interface\\WorldMap\\UI-QuestBlob-Inside")
    frame:SetBorderTexture("Interface\\WorldMap\\UI-QuestBlob-Outside")
    frame:SetFillAlpha(128)
    frame:SetBorderAlpha(192)
    frame:SetBorderScalar(1)
    frame:EnableMouse(false)
    areaFrame = frame
    return frame
end

local function DrawQuestID(frame, questID)
    if not frame.DrawBlob or not HasQuestID(questID) then
        return
    end
    pcall(frame.DrawBlob, frame, questID, true)
end

local function CanvasScale(map)
    if map.GetCanvasScale then
        local ok, scale = pcall(map.GetCanvasScale, map)
        if ok and type(scale) == "number" then
            return scale
        end
    end
    return 0
end

local function DrawQuestArea(mapFrame)
    local map, canvas = MapCanvas(mapFrame)
    if not map or not canvas then
        return
    end
    local frame = EnsureArea(canvas)
    if not frame then
        return
    end
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    if type(width) ~= "number" or type(height) ~= "number" or width <= 1 or height <= 1 then
        return
    end
    local mapID = map.GetMapID and map:GetMapID()
    local layoutChanged = areaWidth ~= width or areaHeight ~= height or not SameID(areaMapID, mapID)
    if layoutChanged then
        frame:SetScale(1)
        frame:ClearAllPoints()
        frame:SetSize(width, height)
        frame:SetPoint("CENTER", canvas, "CENTER", 0, 0)
        local level
        if map.GetPinFrameLevelsManager then
            local ok, manager = pcall(map.GetPinFrameLevelsManager, map)
            if ok and manager and manager.GetValidFrameLevel then
                local levelOk, value = pcall(manager.GetValidFrameLevel, manager, "PIN_FRAME_LEVEL_QUEST_BLOB")
                if levelOk and type(value) == "number" and value > 1 then
                    level = value
                end
            end
        end
        if level then
            frame:SetFrameLevel(level)
        end
        if frame.SetMapID and HasValue(mapID) then
            pcall(frame.SetMapID, frame, mapID)
        end
        areaWidth, areaHeight, areaMapID = width, height, mapID
        areaScale, areaQuest = nil, nil
    end
    if not frame:IsShown() then
        frame:Show()
    end
    local tracked
    local focused
    if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID then
        local ok, id = pcall(C_SuperTrack.GetSuperTrackedQuestID)
        if ok then
            tracked = id
        end
    end
    if QuestMapFrame_GetFocusedQuestID then
        local ok, id = pcall(QuestMapFrame_GetFocusedQuestID)
        if ok then
            focused = id
        end
    end
    local questID = HasQuestID(focused) and focused or tracked
    local scale = CanvasScale(map)
    if not layoutChanged and scale == areaScale and SameID(questID, areaQuest) then
        return
    end
    if frame.DrawNone then
        pcall(frame.DrawNone, frame)
    end
    DrawQuestID(frame, questID)
    areaScale = scale
    areaQuest = questID
end

local function MarkAreaDirty()
    areaDirty = true
    if areaQueued or not C_Timer or not C_Timer.After then
        if not areaQueued then
            DrawQuestArea()
            areaDirty = false
        end
        return
    end
    areaQueued = true
    C_Timer.After(0, function()
        areaQueued = false
        if not areaDirty then
            return
        end
        areaDirty = false
        DrawQuestArea()
    end)
end

local function EnsureAreaHooks(mapFrame)
    if not QuestPOIFrameExists() or not mapFrame then
        return
    end
    if areaHooks then
        return
    end
    areaHooks = true
    if not areaWatcher then
        areaWatcher = CreateFrame("Frame")
        local event = EventValid("SUPER_TRACKING_CHANGED") and "SUPER_TRACKING_CHANGED" or "QUEST_LOG_UPDATE"
        pcall(areaWatcher.RegisterEvent, areaWatcher, event)
        areaWatcher:SetScript("OnEvent", function()
            areaScale = nil
            MarkAreaDirty()
        end)
    end
    if not hooksecurefunc then
        return
    end
    if mapFrame.OnCanvasScaleChanged then
        hooksecurefunc(mapFrame, "OnCanvasScaleChanged", function()
            areaScale = nil
            MarkAreaDirty()
        end)
    end
    if mapFrame.OnCanvasSizeChanged then
        hooksecurefunc(mapFrame, "OnCanvasSizeChanged", function()
            areaWidth = nil
            MarkAreaDirty()
        end)
    end
    if mapFrame.SetMapID then
        hooksecurefunc(mapFrame, "SetMapID", function()
            areaMapID = nil
            areaScale = nil
            MarkAreaDirty()
        end)
    end
end

local function HideQuestArea()
    if not areaFrame then
        return
    end
    if areaFrame.DrawNone then
        pcall(areaFrame.DrawNone, areaFrame)
    end
    areaFrame:Hide()
    areaWidth, areaHeight, areaMapID, areaScale, areaQuest = nil, nil, nil, nil, nil
    areaDirty = false
end

local focusForwarded = false

local function ForwardFocus(eventName, questID)
    local mapFrame = GetMap()
    if mapFrame and mapFrame.TriggerEvent then
        if HasValue(questID) then
            pcall(mapFrame.TriggerEvent, mapFrame, eventName, questID)
        else
            pcall(mapFrame.TriggerEvent, mapFrame, eventName)
        end
    end
    areaScale = nil
    MarkAreaDirty()
end

local function InstallFocusForward()
    if focusForwarded or not hooksecurefunc or not WorldMapMixin then
        return
    end
    focusForwarded = true
    if WorldMapMixin.SetFocusedQuestID then
        hooksecurefunc(WorldMapMixin, "SetFocusedQuestID", function(_, questID)
            ForwardFocus("SetFocusedQuestID", questID)
        end)
    end
    if WorldMapMixin.ClearFocusedQuestID then
        hooksecurefunc(WorldMapMixin, "ClearFocusedQuestID", function()
            ForwardFocus("ClearFocusedQuestID")
        end)
    end
end

local function ForwardCurrentFocus()
    if not QuestMapFrame_GetFocusedQuestID then
        return
    end
    local ok, questID = pcall(QuestMapFrame_GetFocusedQuestID)
    if ok and HasQuestID(questID) then
        ForwardFocus("SetFocusedQuestID", questID)
    end
end

function FluxBattlefieldMapProviders:Attach(mapFrame)
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    mapFrame = GetMap(mapFrame)
    if not mapFrame or not mapFrame.AddDataProvider then
        return false
    end
    InstallAcquirePinGuard(mapFrame)
    if #added == 0 then
        InstallFocusForward()
        RegisterFrameLevels(mapFrame)
        for i = 1, #QUEST_MIXINS do
            TryAdd(mapFrame, QUEST_MIXINS[i])
        end
        for i = 1, #FEATURE_MIXINS do
            TryAdd(mapFrame, FEATURE_MIXINS[i])
        end
        ForwardCurrentFocus()
    end
    EnsureAreaHooks(mapFrame)
    areaWidth = nil
    MarkAreaDirty()
    return #added > 0 or areaFrame ~= nil
end

function FluxBattlefieldMapProviders:Detach(mapFrame)
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    mapFrame = GetMap(mapFrame)
    if mapFrame and mapFrame.RemoveDataProvider then
        for i = 1, #added do
            local provider = added[i]
            if provider.OnHide then
                pcall(provider.OnHide, provider)
            end
            if provider.pin and provider.pin.OnHide then
                pcall(provider.pin.OnHide, provider.pin)
            end
            pcall(mapFrame.RemoveDataProvider, mapFrame, provider)
        end
    end
    wipe(added)
    HideQuestArea()
    return true
end

function FluxBattlefieldMapProviders:IsAttached()
    return #added > 0
end
