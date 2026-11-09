-- FluxBattlefieldMapQuestPins.lua
-- Flux-owned quest-tracker pins on BattlefieldMapFrame.
-- Retail/Midnight: POIButtonTemplate + C_QuestLog / C_SuperTrack / C_TaskQuest.
-- Classic family: QuestPOI_GetButton numbered pins when C_QuestLog.GetQuestsOnMap exists.
-- Does not call MapCanvas AcquirePin or AddDataProvider (unsafe on Midnight).

local addonName, addonTable = ...

FluxBattlefieldMapQuestPins = {}

local Secrets = addonTable and addonTable.Flux and addonTable.Flux.Secrets

local PIN_SCALE = (BATTLEFIELD_MAP_POI_SCALE or 0.6)
local MAX_LIST_SCAN = 400

local state = {
    started = false,
    eventsRegistered = false,
    canvasSizeHooked = false,
    refreshQueued = false,
    lastMapID = nil,
    lastSkipReason = nil,
    backend = nil,
    poiTemplateOk = nil,
    blobFrame = nil,
    userPin = nil,
    questPoiHolder = nil,
    counts = {
        quest = 0,
        worldquest = 0,
        bonus = 0,
        threat = 0,
        waypoint = 0,
        navwaypoint = 0,
        userwaypoint = 0,
        blob = 0,
    },
}

local poiActive = {}
local poiPool = {}
local eventFrame = CreateFrame("Frame")
local registryOwner = {}

-- Forward declarations: RefreshAll -> HookCanvasSize -> QueueRefresh -> RefreshAll
local RefreshAll, QueueRefresh, HookCanvasSize, HasPOITemplate

local function GetSecrets()
    if Secrets then
        return Secrets
    end
    if addonTable and addonTable.Flux and addonTable.Flux.Secrets then
        Secrets = addonTable.Flux.Secrets
        return Secrets
    end
    if addonTable and addonTable.API and addonTable.API.Secrets then
        Secrets = addonTable.API.Secrets
        return Secrets
    end
    return nil
end

local function SafeNum(value)
    if value == nil then
        return nil
    end
    local S = GetSecrets()
    if S then
        if S.IsSecretValue and S.IsSecretValue(value) then
            return nil
        end
        if S.CanAccessValue and not S.CanAccessValue(value) then
            return nil
        end
    end
    local ok, num = pcall(tonumber, value)
    if not ok or num == nil then
        return nil
    end
    if S and S.IsSecretValue and S.IsSecretValue(num) then
        return nil
    end
    return num
end

local function SafeBool(value, default)
    local S = GetSecrets()
    if S and S.SafeBooleanTest then
        return S.SafeBooleanTest(value, default and true or false)
    end
    if value then
        return true
    end
    return default and true or false
end

local function TableUsable(value)
    if type(value) ~= "table" then
        return false
    end
    local S = GetSecrets()
    if not S then
        return true
    end
    if S.CanAccessTable and not S.CanAccessTable(value) then
        return false
    end
    return true
end

local function GetBattlefieldMap()
    if FluxBattlefieldMap and FluxBattlefieldMap.GetMapFrame then
        local mapFrame = FluxBattlefieldMap:GetMapFrame()
        if mapFrame then
            return mapFrame
        end
    end
    return _G.BattlefieldMapFrame
end

local function GetCanvas(mapFrame)
    mapFrame = mapFrame or GetBattlefieldMap()
    if not mapFrame then
        return nil
    end
    if mapFrame.GetCanvas then
        local canvas = mapFrame:GetCanvas()
        if canvas then
            return canvas, mapFrame
        end
    end
    if mapFrame.ScrollContainer and mapFrame.ScrollContainer.GetCanvas then
        local canvas = mapFrame.ScrollContainer:GetCanvas()
        if canvas then
            return canvas, mapFrame
        end
    end
    if mapFrame.ScrollContainer and mapFrame.ScrollContainer.Child then
        return mapFrame.ScrollContainer.Child, mapFrame
    end
    return nil, mapFrame
end

local function GetMapID(mapFrame)
    mapFrame = mapFrame or GetBattlefieldMap()
    if not mapFrame then
        return nil
    end
    if mapFrame.GetMapID then
        return mapFrame:GetMapID()
    end
    return mapFrame.mapID
end

local function CVarEnabled(name, defaultValue)
    if GetCVarBool then
        local ok, value = pcall(GetCVarBool, name)
        if ok then
            return value and true or false
        end
    end
    if GetCVar then
        local ok, value = pcall(GetCVar, name)
        if ok and value ~= nil then
            return value == "1" or value == 1 or value == true
        end
    end
    if defaultValue ~= nil then
        return defaultValue and true or false
    end
    return true
end

local function Call(fn, ...)
    if not fn then
        return nil
    end
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then
        return a, b, c, d
    end
    return nil
end

local function GetFluxEvents()
    if addonTable and addonTable.Flux and addonTable.Flux.Events then
        return addonTable.Flux.Events
    end
    return nil
end

-- Unknown events still hit BugSack inside pcall(RegisterEvent). Never probe-register.
local function SafeRegisterEvent(frame, eventName)
    if not frame or not eventName then
        return false
    end
    local Events = GetFluxEvents()
    if Events and Events.SafeRegister then
        return Events.SafeRegister(frame, eventName) and true or false
    end
    if _G.FluxSafeRegisterEvent then
        return _G.FluxSafeRegisterEvent(frame, eventName) and true or false
    end
    if C_EventUtils and C_EventUtils.IsEventValid then
        local ok, valid = pcall(C_EventUtils.IsEventValid, eventName)
        if not ok or valid ~= true then
            return false
        end
    else
        return false
    end
    local ok = pcall(frame.RegisterEvent, frame, eventName)
    return ok and true or false
end

local function CVarExists(name)
    if C_CVar and C_CVar.GetCVarInfo then
        local ok, info = pcall(C_CVar.GetCVarInfo, name)
        if ok and info ~= nil then
            return true
        end
    end
    if GetCVar then
        local ok, value = pcall(GetCVar, name)
        if ok and value ~= nil then
            return true
        end
    end
    return false
end

local function HasMapQuestAPI()
    return C_QuestLog and C_QuestLog.GetQuestsOnMap and true or false
end

local function HasQuestPOIBackend()
    return type(QuestPOI_GetButton) == "function" and type(QuestPOI_Initialize) == "function"
end

local function ResolvePinBackend()
    if state.poiTemplateOk ~= false and HasPOITemplate() and _G.POIButtonMixin then
        return "poibutton"
    end
    if HasQuestPOIBackend() then
        return "questpoi"
    end
    return nil
end

local function QuestOverlayCVarsEnabled()
    if not CVarEnabled("questPOI", true) then
        return false, "cvar-questPOI"
    end
    if CVarExists("questHelper") and not CVarEnabled("questHelper", true) then
        return false, "cvar-questHelper"
    end
    return true
end

local function IsQuestTurnInReady(questID)
    if not questID or questID <= 0 then
        return false
    end
    if C_QuestLog and C_QuestLog.IsComplete then
        return SafeBool(Call(C_QuestLog.IsComplete, questID), false)
    end
    if C_QuestLog and C_QuestLog.ReadyForTurnIn then
        return SafeBool(Call(C_QuestLog.ReadyForTurnIn, questID), false)
    end
    if _G.IsQuestComplete then
        return SafeBool(Call(_G.IsQuestComplete, questID), false)
    end
    return false
end

local function GetQuestLogIndex(questID)
    if not questID then
        return nil
    end
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        return SafeNum(Call(C_QuestLog.GetLogIndexForQuestID, questID))
    end
    if GetQuestLogIndexByID then
        return SafeNum(Call(GetQuestLogIndexByID, questID))
    end
    return nil
end

local function GetQuestTitle(questID)
    if not questID then
        return nil
    end
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local title = Call(C_QuestLog.GetTitleForQuestID, questID)
        if title and title ~= "" then
            return title
        end
    end
    if C_QuestLog and C_QuestLog.GetQuestInfo then
        local title = Call(C_QuestLog.GetQuestInfo, questID)
        if title and title ~= "" then
            return title
        end
    end
    if C_TaskQuest and C_TaskQuest.GetQuestInfoByQuestID then
        local title = Call(C_TaskQuest.GetQuestInfoByQuestID, questID)
        if title and title ~= "" then
            return title
        end
    end
    local logIndex = GetQuestLogIndex(questID)
    if logIndex and GetQuestLogTitle then
        local title = Call(GetQuestLogTitle, logIndex)
        if title and title ~= "" then
            return title
        end
    end
    return nil
end

local function SetQuestHighlight(questID)
    if POIButtonHighlightManager and POIButtonHighlightManager.SetHighlight then
        pcall(POIButtonHighlightManager.SetHighlight, POIButtonHighlightManager, questID)
    end
    if QuestPOIHighlightManager and QuestPOIHighlightManager.SetHighlight then
        pcall(QuestPOIHighlightManager.SetHighlight, QuestPOIHighlightManager, questID)
    end
end

local function ClearQuestHighlight()
    if POIButtonHighlightManager and POIButtonHighlightManager.ClearHighlight then
        pcall(POIButtonHighlightManager.ClearHighlight, POIButtonHighlightManager)
    end
    if QuestPOIHighlightManager and QuestPOIHighlightManager.ClearHighlight then
        pcall(QuestPOIHighlightManager.ClearHighlight, QuestPOIHighlightManager)
    end
end

local function GetHighlightedQuestID()
    if POIButtonHighlightManager and POIButtonHighlightManager.GetQuestID then
        local id = SafeNum(POIButtonHighlightManager:GetQuestID())
        if id and id > 0 then
            return id
        end
    end
    if QuestPOIHighlightManager and QuestPOIHighlightManager.GetQuestID then
        return SafeNum(QuestPOIHighlightManager:GetQuestID())
    end
    return nil
end

local function HasQuestData(questID)
    if not questID or questID <= 0 then
        return false
    end
    if HaveQuestData then
        local ok, result = pcall(HaveQuestData, questID)
        if ok then
            return result and true or false
        end
    end
    return true
end

local function IsWorldQuest(questID)
    if not questID then
        return false
    end
    if QuestUtils_IsQuestWorldQuest then
        local ok, result = pcall(QuestUtils_IsQuestWorldQuest, questID)
        if ok then
            return result and true or false
        end
    end
    return false
end

local function IsBonusObjective(questID)
    if not questID then
        return false
    end
    if QuestUtils_IsQuestBonusObjective then
        local ok, result = pcall(QuestUtils_IsQuestBonusObjective, questID)
        if ok then
            return result and true or false
        end
    end
    return false
end

local function GetQuestClassification(questID)
    if not questID or not C_QuestInfoSystem or not C_QuestInfoSystem.GetQuestClassification then
        return nil
    end
    return Call(C_QuestInfoSystem.GetQuestClassification, questID)
end

local function GetSuperTrackedQuestID()
    if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID then
        return SafeNum(Call(C_SuperTrack.GetSuperTrackedQuestID)) or 0
    end
    if QuestSuperTracking_GetSuperTrackedQuestID then
        return SafeNum(Call(QuestSuperTracking_GetSuperTrackedQuestID)) or 0
    end
    local globalGet = rawget(_G, "GetSuperTrackedQuestID")
    if type(globalGet) == "function" and globalGet ~= GetSuperTrackedQuestID then
        return SafeNum(Call(globalGet)) or 0
    end
    local details = QuestMapFrame and QuestMapFrame.DetailsFrame
    if details then
        return SafeNum(details.questID) or 0
    end
    return 0
end

local function GetFocusedQuestID()
    if QuestMapFrame_GetFocusedQuestID then
        return SafeNum(Call(QuestMapFrame_GetFocusedQuestID))
    end
    return nil
end

local function MapTypeShowsQuests(mapType)
    if MapUtil and MapUtil.ShouldMapTypeShowQuests then
        local ok, result = pcall(MapUtil.ShouldMapTypeShowQuests, mapType)
        if ok then
            return result and true or false
        end
    end
    if Enum and Enum.UIMapType then
        return mapType ~= Enum.UIMapType.World
            and mapType ~= Enum.UIMapType.Continent
            and mapType ~= Enum.UIMapType.Cosmic
    end
    return true
end

local function GetMapType(mapID)
    if not mapID or not C_Map or not C_Map.GetMapInfo then
        return nil
    end
    local info = Call(C_Map.GetMapInfo, mapID)
    if type(info) == "table" then
        return info.mapType
    end
    return nil
end

local function ForEachList(list, fn)
    if not TableUsable(list) then
        return false
    end
    local i = 1
    while i <= MAX_LIST_SCAN do
        local ok, info = pcall(function()
            return list[i]
        end)
        if not ok or info == nil then
            break
        end
        if type(info) == "table" and TableUsable(info) then
            fn(info, i)
        end
        i = i + 1
    end
    return true
end

local function ReadQuestRecord(info)
    local questID = SafeNum(info.questID)
    local x = SafeNum(info.x)
    local y = SafeNum(info.y)
    if not questID or questID <= 0 or not x or not y then
        return nil
    end
    return {
        questID = questID,
        x = x,
        y = y,
        mapID = SafeNum(info.mapID),
        numObjectives = SafeNum(info.numObjectives),
        childDepth = SafeNum(info.childDepth),
        isMapIndicatorQuest = SafeBool(info.isMapIndicatorQuest, false),
        isQuestStart = SafeBool(info.isQuestStart, false),
        inProgress = SafeBool(info.inProgress, false),
    }
end

local function GetQuestsOnMap(mapID)
    if not mapID or not C_QuestLog or not C_QuestLog.GetQuestsOnMap then
        return nil, "no-api"
    end
    local list = Call(C_QuestLog.GetQuestsOnMap, mapID)
    if list == nil then
        return {}, nil
    end
    if not TableUsable(list) then
        return nil, "secret"
    end
    local out = {}
    if not ForEachList(list, function(info)
        local rec = ReadQuestRecord(info)
        if rec then
            out[#out + 1] = rec
        end
    end) then
        return nil, "secret"
    end
    return out, nil
end

local function GetTasksOnMap(mapID)
    if not mapID or not C_TaskQuest or not C_TaskQuest.GetQuestsOnMap then
        return {}
    end
    local list = Call(C_TaskQuest.GetQuestsOnMap, mapID)
    local out = {}
    if list and TableUsable(list) then
        ForEachList(list, function(info)
            local rec = ReadQuestRecord(info)
            if rec then
                out[#out + 1] = rec
            end
        end)
    end
    return out
end

local function PositionPin(pin, canvas, x, y, extraScale)
    if not pin or not canvas or not x or not y then
        return
    end
    local scale = pin:GetScale()
    if not scale or scale == 0 then
        scale = extraScale or PIN_SCALE
    end
    local width = canvas:GetWidth() or 0
    local height = canvas:GetHeight() or 0
    if width <= 0 or height <= 0 then
        pin:Hide()
        return
    end
    pin:ClearAllPoints()
    local anchor = canvas
    if pin.poiParent then
        anchor = pin.poiParent
    else
        pin:SetParent(canvas)
    end
    pin:SetPoint("CENTER", anchor, "TOPLEFT", (width * x) / scale, -(height * y) / scale)
    pin:Show()
end

function HasPOITemplate()
    if state.poiTemplateOk == true then
        return true
    end
    if _G.POIButtonMixin and (not C_XMLUtil or not C_XMLUtil.GetTemplateInfo or Call(C_XMLUtil.GetTemplateInfo, "POIButtonTemplate")) then
        state.poiTemplateOk = true
        return true
    end
    if state.poiTemplateOk == false then
        return false
    end
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_POIButton")
    elseif LoadAddOn then
        pcall(LoadAddOn, "Blizzard_POIButton")
    end
    if C_XMLUtil and C_XMLUtil.GetTemplateInfo then
        local info = Call(C_XMLUtil.GetTemplateInfo, "POIButtonTemplate")
        state.poiTemplateOk = info ~= nil
    else
        state.poiTemplateOk = _G.POIButtonMixin ~= nil
    end
    return state.poiTemplateOk
end

local function ShowQuestTooltip(pin)
    local questID = pin and pin.questID
    if not questID or not GameTooltip then
        return
    end
    local title = GetQuestTitle(questID)
    title = title or ("Quest " .. tostring(questID))
    if SetQuestTitleLevelAndDifficultyColor then
        title = Call(SetQuestTitleLevelAndDifficultyColor, questID, title) or title
    end

    GameTooltip:SetOwner(pin, "ANCHOR_CURSOR_RIGHT", 5, 2)
    GameTooltip:SetText(title)
    if QuestUtils_AddQuestTypeToTooltip then
        pcall(QuestUtils_AddQuestTypeToTooltip, GameTooltip, questID, NORMAL_FONT_COLOR)
    end
    if GameTooltip_CheckAddQuestTimeToTooltip then
        pcall(GameTooltip_CheckAddQuestTimeToTooltip, GameTooltip, questID)
    end

    local superID = GetSuperTrackedQuestID()
    local focusedID = GetFocusedQuestID()
    local showWaypoint = (questID == superID) or (focusedID and questID == focusedID)
    if showWaypoint and C_QuestLog and C_QuestLog.GetNextWaypointText then
        local waypointText = Call(C_QuestLog.GetNextWaypointText, questID)
        if waypointText and QUEST_DASH then
            if GameTooltip_AddColoredLine then
                GameTooltip_AddColoredLine(GameTooltip, QUEST_DASH .. waypointText, HIGHLIGHT_FONT_COLOR)
            else
                GameTooltip:AddLine(QUEST_DASH .. waypointText, 1, 1, 1, true)
            end
        end
    elseif pin.fluxKind == "quest" then
        local questLogIndex = GetQuestLogIndex(questID)
        if questLogIndex and GetNumQuestLeaderBoards then
            local numObjectives = Call(GetNumQuestLeaderBoards, questLogIndex) or 0
            for i = 1, numObjectives do
                local text, _, finished = GetQuestLogLeaderBoard(i, questLogIndex)
                if text and not finished then
                    GameTooltip:AddLine((QUEST_DASH or "- ") .. text, 1, 1, 1, true)
                end
            end
        end
    end
    GameTooltip:Show()
    SetQuestHighlight(questID)
end

local function HideQuestTooltip(pin)
    if GameTooltip and GameTooltip:GetOwner() == pin then
        GameTooltip:Hide()
    end
    ClearQuestHighlight()
end

local function OnPOIEnter(pin)
    if pin.fluxKind == "worldquest" or pin.fluxKind == "bonus" or pin.fluxKind == "threat" then
        if TaskPOI_OnEnter then
            pcall(TaskPOI_OnEnter, pin)
        else
            ShowQuestTooltip(pin)
        end
        if POIButtonMixin and POIButtonMixin.OnEnter then
            POIButtonMixin.OnEnter(pin)
        end
        return
    end
    if pin.fluxKind == "navwaypoint" then
        local name, description
        if C_SuperTrack and C_SuperTrack.GetSuperTrackedItemName then
            name, description = Call(C_SuperTrack.GetSuperTrackedItemName)
        end
        if name and GameTooltip then
            GameTooltip:SetOwner(pin, "ANCHOR_RIGHT", -16, -4)
            GameTooltip:SetText(name)
            if description then
                GameTooltip:AddLine(description, 1, 0.82, 0, true)
            end
            if pin.waypointText then
                GameTooltip:AddLine((QUEST_DASH or "- ") .. pin.waypointText, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end
        return
    end
    ShowQuestTooltip(pin)
end

local function OnPOILeave(pin)
    if pin.fluxKind == "worldquest" or pin.fluxKind == "bonus" or pin.fluxKind == "threat" then
        if TaskPOI_OnLeave then
            pcall(TaskPOI_OnLeave, pin)
        end
        if POIButtonMixin and POIButtonMixin.OnLeave then
            POIButtonMixin.OnLeave(pin)
        else
            HideQuestTooltip(pin)
        end
        return
    end
    HideQuestTooltip(pin)
end

local function OnPOIClick(pin, button)
    if pin.fluxKind == "navwaypoint" then
        if button == "LeftButton" and C_SuperTrack and C_SuperTrack.ClearAllSuperTracked then
            C_SuperTrack.ClearAllSuperTracked()
            if PlaySound and SOUNDKIT then
                PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_OFF or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
            end
        end
        return
    end
    if POIButtonMixin and POIButtonMixin.OnClick then
        pcall(POIButtonMixin.OnClick, pin, button)
    end
end

local function CreatePOI(canvas)
    local ok, pin = pcall(CreateFrame, "Button", nil, canvas, "POIButtonTemplate")
    if not ok or not pin then
        state.poiTemplateOk = false
        return nil
    end
    pin.shouldShowGlow = false
    if pin.SetPinScale then
        pin:SetPinScale(1)
    end
    pin:SetScale(PIN_SCALE)
    pin:EnableMouse(true)
    if pin.SetMouseMotionEnabled then
        pin:SetMouseMotionEnabled(true)
    end
    if pin.SetMouseClickEnabled then
        pin:SetMouseClickEnabled(true)
    end
    if not pin.LinkGlow then
        local glow = pin:CreateTexture(nil, "BACKGROUND")
        glow:SetSize(75, 75)
        glow:SetPoint("CENTER")
        glow:SetAtlas("ui-questpoi-outerglow")
        glow:SetBlendMode("ADD")
        glow:Hide()
        pin.LinkGlow = glow
    end
    pin:SetScript("OnEnter", OnPOIEnter)
    pin:SetScript("OnLeave", OnPOILeave)
    pin:SetScript("OnClick", OnPOIClick)
    return pin
end

local function AcquirePOI(canvas, kind)
    local pin = table.remove(poiPool)
    if not pin then
        pin = CreatePOI(canvas)
        if not pin then
            return nil
        end
    else
        pin:SetParent(canvas)
        pin:SetScale(PIN_SCALE)
    end
    pin.fluxKind = kind
    pin.waypointText = nil
    pin.worldQuest = (kind == "worldquest")
    pin.numObjectives = nil
    pin.tagInfo = nil
    pin.worldQuestType = nil
    if pin.LinkGlow then
        pin.LinkGlow:Hide()
    end
    poiActive[#poiActive + 1] = pin
    return pin
end

local function ReleaseAllPOI()
    for i = #poiActive, 1, -1 do
        local pin = poiActive[i]
        poiActive[i] = nil
        pin:Hide()
        pin:ClearAllPoints()
        if GameTooltip and GameTooltip:GetOwner() == pin then
            GameTooltip:Hide()
        end
        if pin.Reset then
            pcall(pin.Reset, pin)
        end
        pin.fluxKind = nil
        poiPool[#poiPool + 1] = pin
    end
end

local function EnsureBlob(canvas)
    if state.blobFrame then
        state.blobFrame:SetParent(canvas)
        return state.blobFrame
    end
    local blob
    local ok = pcall(function()
        blob = CreateFrame("QuestPOIFrame", "FluxBattlefieldMapQuestBlob", canvas)
    end)
    if not ok or not blob then
        return nil
    end
    blob:SetAllPoints(canvas)
    blob:EnableMouse(false)
    blob:SetFrameLevel(20)
    if blob.SetFillTexture then
        blob:SetFillTexture("Interface\\WorldMap\\UI-QuestBlob-Inside")
    end
    if blob.SetBorderTexture then
        blob:SetBorderTexture("Interface\\WorldMap\\UI-QuestBlob-Outside")
    end
    if blob.SetFillAlpha then
        blob:SetFillAlpha(128)
    end
    if blob.SetBorderAlpha then
        blob:SetBorderAlpha(192)
    end
    if blob.SetBorderScalar then
        blob:SetBorderScalar(1.0)
    end
    state.blobFrame = blob
    return blob
end

local function RefreshBlob(canvas, mapID, mapType)
    local blob = EnsureBlob(canvas)
    if not blob then
        state.counts.blob = 0
        return
    end
    blob:SetParent(canvas)
    blob:ClearAllPoints()
    blob:SetAllPoints(canvas)
    local width = canvas:GetWidth() or 0
    local height = canvas:GetHeight() or 0
    if width > 0 and height > 0 and blob.SetSize then
        blob:SetSize(width, height)
    end
    blob:Show()
    if blob.DrawNone then
        pcall(blob.DrawNone, blob)
    end
    if not CVarEnabled("questPOI", true) or not MapTypeShowsQuests(mapType) then
        state.counts.blob = 0
        return
    end
    if CVarExists("questHelper") and not CVarEnabled("questHelper", true) then
        state.counts.blob = 0
        return
    end
    if blob.SetMapID then
        pcall(blob.SetMapID, blob, mapID)
    end
    local questID = GetSuperTrackedQuestID()
    if questID and questID > 0 and blob.DrawBlob then
        if not IsWorldQuest(questID) and not IsBonusObjective(questID) then
            pcall(blob.DrawBlob, blob, questID, true)
            state.counts.blob = 1
            return
        end
    end
    local highlightID = GetHighlightedQuestID()
    if highlightID and highlightID > 0 and blob.DrawBlob then
        pcall(blob.DrawBlob, blob, highlightID, true)
        state.counts.blob = 1
        return
    end
    state.counts.blob = 0
end

local function EnsureUserPin(canvas)
    if state.userPin then
        state.userPin:SetParent(canvas)
        return state.userPin
    end
    local pin = CreateFrame("Button", nil, canvas)
    pin:SetSize(30, 30)
    pin:SetScale(PIN_SCALE)
    pin:EnableMouse(true)
    pin:RegisterForClicks("LeftButtonUp")
    pin.Icon = pin:CreateTexture(nil, "ARTWORK")
    pin.Icon:SetAllPoints()
    pin.Icon:SetAtlas("Waypoint-MapPin-Untracked")
    pin:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -16, -4)
        GameTooltip:SetText(MAP_PIN_SHARING or "Map Pin")
        if MAP_PIN_SHARING_TOOLTIP then
            GameTooltip:AddLine(MAP_PIN_SHARING_TOOLTIP, 1, 0.82, 0, true)
        end
        if MAP_PIN_REMOVE then
            GameTooltip:AddLine(MAP_PIN_REMOVE, 0.1, 1, 0.1, true)
        end
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function(self)
        if GameTooltip and GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)
    pin:SetScript("OnClick", function(_, button)
        if button ~= "LeftButton" then
            return
        end
        if IsModifiedClick and IsModifiedClick("CHATLINK") and C_Map and C_Map.GetUserWaypointHyperlink then
            local link = Call(C_Map.GetUserWaypointHyperlink)
            if link and ChatFrameUtil and ChatFrameUtil.InsertLink then
                ChatFrameUtil.InsertLink(link)
            elseif link and ChatEdit_InsertLink then
                ChatEdit_InsertLink(link)
            end
            return
        end
        if C_SuperTrack and C_SuperTrack.IsSuperTrackingUserWaypoint and C_SuperTrack.SetSuperTrackedUserWaypoint then
            local shouldTrack = not C_SuperTrack.IsSuperTrackingUserWaypoint()
            C_SuperTrack.SetSuperTrackedUserWaypoint(shouldTrack)
        end
    end)
    pin:SetFrameLevel(280)
    state.userPin = pin
    return pin
end

local function RefreshUserWaypoint(canvas, mapID)
    state.counts.userwaypoint = 0
    if not mapID or not C_Map or not C_Map.GetUserWaypointPositionForMap then
        if state.userPin then
            state.userPin:Hide()
        end
        return
    end
    local pos = Call(C_Map.GetUserWaypointPositionForMap, mapID)
    local x, y
    if pos then
        if pos.GetXY then
            x, y = Call(pos.GetXY, pos)
        else
            x, y = SafeNum(pos.x), SafeNum(pos.y)
        end
    end
    if not x or not y then
        if state.userPin then
            state.userPin:Hide()
        end
        return
    end
    local pin = EnsureUserPin(canvas)
    local tracked = C_SuperTrack and C_SuperTrack.IsSuperTrackingUserWaypoint and C_SuperTrack.IsSuperTrackingUserWaypoint()
    pin.Icon:SetAtlas(tracked and "Waypoint-MapPin-Tracked" or "Waypoint-MapPin-Untracked")
    PositionPin(pin, canvas, x, y)
    pin:SetFrameLevel(280)
    state.counts.userwaypoint = 1
end

local function StyleQuestPin(pin, questID, style, selected, frameLevel)
    if not pin then
        return
    end
    if pin.SetQuestID then
        pcall(pin.SetQuestID, pin, questID)
    end
    if pin.Display then
        pin.Display:ClearAllPoints()
        pin.Display:SetPoint("CENTER")
    end
    if pin.SetSelected then
        pin:SetSelected(selected and true or false)
    end
    if pin.SetStyle then
        pin:SetStyle(style)
    end
    if pin.UpdateButtonStyle then
        pcall(pin.UpdateButtonStyle, pin)
    end
    if pin.EvaluateManagedHighlight then
        pcall(pin.EvaluateManagedHighlight, pin)
    end
    pin:SetFrameLevel(frameLevel or 160)
end

local function ShouldShowQuestPin(questID, mapType, isMapIndicatorQuest)
    local focused = GetFocusedQuestID()
    if focused and focused ~= questID then
        return false
    end
    if IsWorldQuest(questID) then
        return false
    end
    if IsBonusObjective(questID) then
        return false
    end
    if isMapIndicatorQuest or not HasQuestData(questID) then
        return false
    end
    if Enum and Enum.UIMapType and mapType == Enum.UIMapType.Continent then
        return questID == GetSuperTrackedQuestID()
    end
    return MapTypeShowsQuests(mapType)
end

local function GetPOIStyle(questID)
    if POIButtonUtil and POIButtonUtil.GetStyle then
        local ok, style = pcall(POIButtonUtil.GetStyle, questID)
        if ok and style then
            return style
        end
    end
    if POIButtonUtil and POIButtonUtil.Style then
        return POIButtonUtil.Style.QuestInProgress
    end
    return 2
end

local function ShouldShowTask(mapID, rec)
    if MapUtil and MapUtil.ShouldShowTask then
        local ok, result = pcall(MapUtil.ShouldShowTask, mapID, rec)
        if ok then
            return result and true or false
        end
    end
    if rec.isQuestStart and rec.inProgress then
        return false
    end
    if not HasQuestData(rec.questID) then
        return false
    end
    if rec.mapID and rec.mapID ~= mapID then
        return rec.childDepth ~= nil
    end
    return true
end

local function ShouldMapShowWorldQuest(mapID, rec, mapType)
    if rec.childDepth and Enum and Enum.UIMapType and mapType == Enum.UIMapType.Zone then
        return true
    end
    if rec.questID == GetSuperTrackedQuestID() and Enum and Enum.UIMapType and mapType == Enum.UIMapType.Continent then
        return true
    end
    return false
end

local function WorldQuestPassesFilters(mapID, rec)
    if WorldMap_DoesWorldQuestInfoPassFilters then
        local ignoreType = true
        if mapID and MapUtil and MapUtil.MapShouldShowWorldQuestFilters then
            local okMatch, match = pcall(MapUtil.MapShouldShowWorldQuestFilters, mapID)
            if okMatch then
                ignoreType = not match
            end
        end
        local ok, result = pcall(WorldMap_DoesWorldQuestInfoPassFilters, rec, ignoreType)
        if ok then
            return result and true or false
        end
    end
    return true
end

local function ApplyHighlight(pin, questID)
    if not pin or not pin.LinkGlow then
        return
    end
    local highlightID = GetHighlightedQuestID()
    pin.LinkGlow:SetShown(highlightID ~= nil and highlightID == questID)
end

local function OnClassicPOIEnter(pin)
    if QuestPOIButton_OnEnter then
        pcall(QuestPOIButton_OnEnter, pin)
    end
    ShowQuestTooltip(pin)
end

local function OnClassicPOILeave(pin)
    if QuestPOIButton_OnLeave then
        pcall(QuestPOIButton_OnLeave, pin)
    end
    HideQuestTooltip(pin)
end

local function HideClassicQuestPOI()
    local holder = state.questPoiHolder
    if not holder then
        return
    end
    if QuestPOI_HideAllButtons then
        pcall(QuestPOI_HideAllButtons, holder)
    end
    holder:Hide()
end

local function ClearOverlayPins()
    ReleaseAllPOI()
    HideClassicQuestPOI()
end

local function EnsureQuestPOIHolder(canvas)
    if state.questPoiHolder then
        state.questPoiHolder:SetParent(canvas)
        state.questPoiHolder:ClearAllPoints()
        state.questPoiHolder:SetAllPoints(canvas)
        state.questPoiHolder:Show()
        return state.questPoiHolder
    end
    if not QuestPOI_Initialize then
        return nil
    end
    local holder = CreateFrame("Frame", "FluxBattlefieldMapQuestPOIHolder", canvas)
    holder:SetAllPoints(canvas)
    holder:EnableMouse(false)
    holder:SetFrameLevel(50)
    pcall(QuestPOI_Initialize, holder, function(poiButton)
        poiButton:SetScale(PIN_SCALE)
        poiButton:EnableMouse(true)
        poiButton:SetScript("OnEnter", OnClassicPOIEnter)
        poiButton:SetScript("OnLeave", OnClassicPOILeave)
    end, true)
    state.questPoiHolder = holder
    return holder
end

local function NextFreeQuestNumber(usedNumbers)
    local maxNum = 25
    if C_QuestLog and C_QuestLog.GetMaxNumQuests then
        maxNum = SafeNum(Call(C_QuestLog.GetMaxNumQuests)) or maxNum
    end
    for n = 1, maxNum do
        if not usedNumbers[n] then
            usedNumbers[n] = true
            return n
        end
    end
    return 1
end

local function GetClassicQuestNumber(questID, usedNumbers)
    local contents = QuestScrollFrame and QuestScrollFrame.Contents
    if contents and QuestPOI_FindButton then
        local tracker = Call(QuestPOI_FindButton, contents, questID)
        if tracker and tracker.style == "numeric" then
            local n = SafeNum(tracker.index)
            if n and n > 0 then
                usedNumbers[n] = true
                return n
            end
        end
    end
    return nil
end

local function PlaceClassicPOI(holder, canvas, questID, style, index, x, y, frameLevel, kind)
    local pin = Call(QuestPOI_GetButton, holder, questID, style, index)
    if not pin then
        return nil
    end
    pin.fluxKind = kind or "quest"
    pin.questID = questID
    if QuestPOI_SetPinScale then
        pcall(QuestPOI_SetPinScale, pin, PIN_SCALE)
    end
    pin:SetScale(PIN_SCALE)
    pin:SetFrameLevel(frameLevel or 160)
    PositionPin(pin, canvas, x, y)
    return pin
end

local function RefreshClassicQuestPOI(canvas, mapID, mapType, quests, superID)
    local holder = EnsureQuestPOIHolder(canvas)
    if not holder then
        state.lastSkipReason = "no-quest-pin-backend"
        return
    end
    if QuestPOI_ResetUsage then
        pcall(QuestPOI_ResetUsage, holder)
    end

    local usedNumbers = {}
    local selectedPin
    local shownQuest = {}

    for i, rec in ipairs(quests) do
        if ShouldShowQuestPin(rec.questID, mapType, rec.isMapIndicatorQuest) then
            local complete = IsQuestTurnInReady(rec.questID)
            local style = complete and "normal" or "numeric"
            local index
            if style == "numeric" then
                index = GetClassicQuestNumber(rec.questID, usedNumbers) or NextFreeQuestNumber(usedNumbers)
            end
            local selected = rec.questID == superID
            local pin = PlaceClassicPOI(
                holder,
                canvas,
                rec.questID,
                style,
                index,
                rec.x,
                rec.y,
                selected and 240 or (160 + i),
                "quest"
            )
            if pin then
                if selected then
                    selectedPin = pin
                end
                shownQuest[rec.questID] = true
                state.counts.quest = state.counts.quest + 1
            end
        end
    end

    local waypointQuestID = GetFocusedQuestID() or superID
    if waypointQuestID and waypointQuestID > 0 and C_QuestLog and C_QuestLog.GetNextWaypointForMap then
        local x, y = Call(C_QuestLog.GetNextWaypointForMap, waypointQuestID, mapID)
        x, y = SafeNum(x), SafeNum(y)
        if x and y then
            local pin = PlaceClassicPOI(
                holder,
                canvas,
                waypointQuestID,
                "waypoint",
                nil,
                x,
                y,
                250,
                "waypoint"
            )
            if pin then
                if waypointQuestID == superID then
                    selectedPin = pin
                end
                state.counts.waypoint = state.counts.waypoint + 1
            end
        end
    end

    local tasks = GetTasksOnMap(mapID)
    for _, rec in ipairs(quests) do
        if rec.isMapIndicatorQuest then
            rec.inProgress = true
            rec.mapID = rec.mapID or mapID
            tasks[#tasks + 1] = rec
        end
    end

    local bonusIndex = 0
    for _, rec in ipairs(tasks) do
        local classification = GetQuestClassification(rec.questID)
        local isThreat = Enum and Enum.QuestClassification and classification == Enum.QuestClassification.Threat
        if isThreat and not shownQuest[rec.questID] and ShouldShowTask(mapID, rec) then
            bonusIndex = bonusIndex + 1
            local selected = rec.questID == superID
            local pin = PlaceClassicPOI(
                holder,
                canvas,
                rec.questID,
                "threat",
                nil,
                rec.x,
                rec.y,
                selected and 245 or (180 + bonusIndex),
                "threat"
            )
            if pin then
                if selected then
                    selectedPin = pin
                end
                shownQuest[rec.questID] = true
                state.counts.threat = state.counts.threat + 1
            end
        end
    end

    if selectedPin and QuestPOI_SelectButton then
        pcall(QuestPOI_SelectButton, selectedPin)
    end
    if QuestPOI_HideUnusedButtons then
        pcall(QuestPOI_HideUnusedButtons, holder)
    end
end

function RefreshAll()
    if not state.started then
        return
    end

    for k in pairs(state.counts) do
        state.counts[k] = 0
    end
    state.lastSkipReason = nil
    state.backend = nil

    local canvas, mapFrame = GetCanvas()
    if not canvas or not mapFrame then
        state.lastSkipReason = "no-canvas"
        ClearOverlayPins()
        return
    end
    HookCanvasSize()

    if not HasMapQuestAPI() then
        state.lastSkipReason = "no-quest-map-api"
        ClearOverlayPins()
        return
    end

    local backend = ResolvePinBackend()
    state.backend = backend
    if not backend then
        state.lastSkipReason = "no-quest-pin-backend"
        ClearOverlayPins()
        return
    end

    local mapID = GetMapID(mapFrame)
    state.lastMapID = mapID
    if not mapID then
        state.lastSkipReason = "no-mapid"
        ClearOverlayPins()
        if state.blobFrame then
            state.blobFrame:Hide()
        end
        if state.userPin then
            state.userPin:Hide()
        end
        return
    end

    if backend == "poibutton" then
        HideClassicQuestPOI()
        ReleaseAllPOI()
    else
        ReleaseAllPOI()
    end

    local mapType = GetMapType(mapID)
    RefreshBlob(canvas, mapID, mapType)
    RefreshUserWaypoint(canvas, mapID)

    local cvarOk, cvarSkip = QuestOverlayCVarsEnabled()
    if not cvarOk then
        state.lastSkipReason = cvarSkip
        if backend == "questpoi" then
            HideClassicQuestPOI()
        end
        return
    end

    local quests, questErr = GetQuestsOnMap(mapID)
    if questErr then
        state.lastSkipReason = questErr
        if questErr == "secret" then
            if backend == "questpoi" then
                HideClassicQuestPOI()
            end
            return
        end
    end
    quests = quests or {}

    local superID = GetSuperTrackedQuestID()

    if backend == "questpoi" then
        RefreshClassicQuestPOI(canvas, mapID, mapType, quests, superID)
        return
    end

    local shownQuest = {}

    for i, rec in ipairs(quests) do
        if ShouldShowQuestPin(rec.questID, mapType, rec.isMapIndicatorQuest) then
            local pin = AcquirePOI(canvas, "quest")
            if pin then
                local selected = rec.questID == superID
                StyleQuestPin(
                    pin,
                    rec.questID,
                    GetPOIStyle(rec.questID),
                    selected,
                    selected and 240 or (160 + i)
                )
                PositionPin(pin, canvas, rec.x, rec.y)
                ApplyHighlight(pin, rec.questID)
                shownQuest[rec.questID] = true
                state.counts.quest = state.counts.quest + 1
            end
        end
    end

    local waypointQuestID = GetFocusedQuestID() or superID
    if waypointQuestID and waypointQuestID > 0 and C_QuestLog and C_QuestLog.GetNextWaypointForMap then
        local x, y = Call(C_QuestLog.GetNextWaypointForMap, waypointQuestID, mapID)
        x, y = SafeNum(x), SafeNum(y)
        if x and y then
            local pin = AcquirePOI(canvas, "waypoint")
            if pin then
                local style = POIButtonUtil and POIButtonUtil.Style and POIButtonUtil.Style.Waypoint or GetPOIStyle(waypointQuestID)
                StyleQuestPin(pin, waypointQuestID, style, waypointQuestID == superID, 250)
                PositionPin(pin, canvas, x, y)
                state.counts.waypoint = state.counts.waypoint + 1
            end
        end
    end

    local tasks = GetTasksOnMap(mapID)
    for _, rec in ipairs(quests) do
        if rec.isMapIndicatorQuest then
            rec.inProgress = true
            rec.mapID = rec.mapID or mapID
            tasks[#tasks + 1] = rec
        end
    end

    local showWQ = CVarEnabled("questPOIWQ", C_TaskQuest ~= nil)
    local wqIndex = 0
    local bonusIndex = 0
    for _, rec in ipairs(tasks) do
        local classification = GetQuestClassification(rec.questID)
        local isThreat = Enum and Enum.QuestClassification and classification == Enum.QuestClassification.Threat
        local isBonus = Enum and Enum.QuestClassification and classification == Enum.QuestClassification.BonusObjective
        if not isBonus and IsBonusObjective(rec.questID) then
            isBonus = true
        end

        if isThreat or isBonus then
            if not shownQuest[rec.questID] and ShouldShowTask(mapID, rec) then
                bonusIndex = bonusIndex + 1
                local kind = isThreat and "threat" or "bonus"
                local pin = AcquirePOI(canvas, kind)
                if pin then
                    local style
                    if isThreat and POIButtonUtil and POIButtonUtil.Style then
                        style = POIButtonUtil.Style.QuestThreat
                    elseif POIButtonUtil and POIButtonUtil.Style then
                        style = POIButtonUtil.Style.BonusObjective
                    else
                        style = GetPOIStyle(rec.questID)
                    end
                    local selected = rec.questID == superID
                    pin.numObjectives = rec.numObjectives
                    StyleQuestPin(pin, rec.questID, style, selected, selected and 245 or (180 + bonusIndex))
                    PositionPin(pin, canvas, rec.x, rec.y)
                    shownQuest[rec.questID] = true
                    if kind == "threat" then
                        state.counts.threat = state.counts.threat + 1
                    else
                        state.counts.bonus = state.counts.bonus + 1
                    end
                end
            end
        elseif showWQ and not shownQuest[rec.questID] and (IsWorldQuest(rec.questID) or rec.isMapIndicatorQuest) and HasQuestData(rec.questID) then
            local mapShow = ShouldMapShowWorldQuest(mapID, rec, mapType)
            if (mapShow or ShouldShowTask(mapID, rec)) and WorldQuestPassesFilters(mapID, rec) then
                wqIndex = wqIndex + 1
                local pin = AcquirePOI(canvas, "worldquest")
                if pin then
                    local style = POIButtonUtil and POIButtonUtil.Style and POIButtonUtil.Style.WorldQuest or GetPOIStyle(rec.questID)
                    local selected = rec.questID == superID
                    pin.numObjectives = rec.numObjectives
                    pin.worldQuest = true
                    if C_QuestLog and C_QuestLog.GetQuestTagInfo then
                        pin.tagInfo = Call(C_QuestLog.GetQuestTagInfo, rec.questID)
                        if pin.tagInfo then
                            pin.worldQuestType = pin.tagInfo.worldQuestType
                        end
                    end
                    if C_TaskQuest and C_TaskQuest.RequestPreloadRewardData and not (HaveQuestRewardData and HaveQuestRewardData(rec.questID)) then
                        pcall(C_TaskQuest.RequestPreloadRewardData, rec.questID)
                    end
                    StyleQuestPin(pin, rec.questID, style, selected, selected and 246 or (190 + wqIndex))
                    PositionPin(pin, canvas, rec.x, rec.y)
                    shownQuest[rec.questID] = true
                    state.counts.worldquest = state.counts.worldquest + 1
                end
            end
        end
    end

    local showNavWaypoint = true
    if superID and superID > 0 and not IsWorldQuest(superID) then
        showNavWaypoint = false
    end
    if showNavWaypoint and C_Navigation and C_Navigation.GetNextWaypointForMap then
        local x, y, waypointText = Call(C_Navigation.GetNextWaypointForMap, mapID)
        x, y = SafeNum(x), SafeNum(y)
        if x and y then
            local pin = AcquirePOI(canvas, "navwaypoint")
            if pin then
                local style = POIButtonUtil and POIButtonUtil.Style and POIButtonUtil.Style.Waypoint or 1
                if pin.SetQuestID then
                    pcall(pin.SetQuestID, pin, nil)
                end
                if pin.Display then
                    pin.Display:ClearAllPoints()
                    pin.Display:SetPoint("CENTER")
                end
                pin:SetSelected(true)
                pin:SetStyle(style)
                pcall(pin.UpdateButtonStyle, pin)
                pin.waypointText = waypointText
                pin:SetFrameLevel(255)
                PositionPin(pin, canvas, x, y)
                state.counts.navwaypoint = 1
            end
        end
    end
end

function QueueRefresh()
    if not state.started then
        return
    end
    if state.refreshQueued then
        return
    end
    state.refreshQueued = true
    local function run()
        state.refreshQueued = false
        RefreshAll()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

function HookCanvasSize()
    if state.canvasSizeHooked then
        return
    end
    local canvas = GetCanvas()
    if not canvas or not canvas.HookScript then
        return
    end
    canvas:HookScript("OnSizeChanged", function()
        if state.started then
            QueueRefresh()
        end
    end)
    state.canvasSizeHooked = true
end

local function RegisterEvents()
    if state.eventsRegistered then
        return
    end
    local function registerAlways(eventName)
        if SafeRegisterEvent(eventFrame, eventName) then
            return
        end
        if C_EventUtils and C_EventUtils.IsEventValid then
            return
        end
        pcall(eventFrame.RegisterEvent, eventFrame, eventName)
    end
    registerAlways("QUEST_LOG_UPDATE")
    registerAlways("CVAR_UPDATE")
    registerAlways("ZONE_CHANGED_NEW_AREA")
    SafeRegisterEvent(eventFrame, "QUEST_WATCH_LIST_CHANGED")
    SafeRegisterEvent(eventFrame, "QUEST_POI_UPDATE")
    SafeRegisterEvent(eventFrame, "QUEST_WATCH_UPDATE")
    SafeRegisterEvent(eventFrame, "SUPER_TRACKING_CHANGED")
    SafeRegisterEvent(eventFrame, "SUPER_TRACKED_QUEST_CHANGED")
    SafeRegisterEvent(eventFrame, "SUPER_TRACKING_PATH_UPDATED")
    SafeRegisterEvent(eventFrame, "USER_WAYPOINT_UPDATED")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if not state.started then
            return
        end
        if event == "CVAR_UPDATE" then
            local cvar = ...
            if cvar ~= "questPOI" and cvar ~= "questPOIWQ" and cvar ~= "questHelper" then
                return
            end
        end
        QueueRefresh()
    end)
    if EventRegistry and EventRegistry.RegisterCallback then
        pcall(EventRegistry.RegisterCallback, EventRegistry, "Supertracking.OnChanged", QueueRefresh, registryOwner)
        pcall(EventRegistry.RegisterCallback, EventRegistry, "SetHighlightedQuestPOI", QueueRefresh, registryOwner)
        pcall(EventRegistry.RegisterCallback, EventRegistry, "ClearHighlightedQuestPOI", QueueRefresh, registryOwner)
    end
    state.eventsRegistered = true
end

local function UnregisterEvents()
    if not state.eventsRegistered then
        return
    end
    eventFrame:UnregisterAllEvents()
    eventFrame:SetScript("OnEvent", nil)
    if EventRegistry and EventRegistry.UnregisterCallback then
        pcall(EventRegistry.UnregisterCallback, EventRegistry, "Supertracking.OnChanged", registryOwner)
        pcall(EventRegistry.UnregisterCallback, EventRegistry, "SetHighlightedQuestPOI", registryOwner)
        pcall(EventRegistry.UnregisterCallback, EventRegistry, "ClearHighlightedQuestPOI", registryOwner)
    end
    state.eventsRegistered = false
end

function FluxBattlefieldMapQuestPins:IsStarted()
    return state.started
end

function FluxBattlefieldMapQuestPins:Refresh()
    QueueRefresh()
end

function FluxBattlefieldMapQuestPins:GetDiagnostics()
    return {
        started = state.started,
        mapID = state.lastMapID,
        skip = state.lastSkipReason,
        backend = state.backend,
        hasMapQuestAPI = HasMapQuestAPI(),
        poiTemplate = HasPOITemplate(),
        questPOI = CVarEnabled("questPOI", true),
        questHelper = not CVarExists("questHelper") or CVarEnabled("questHelper", true),
        questPOIWQ = CVarEnabled("questPOIWQ", C_TaskQuest ~= nil),
        quest = state.counts.quest,
        worldquest = state.counts.worldquest,
        bonus = state.counts.bonus,
        threat = state.counts.threat,
        waypoint = state.counts.waypoint,
        navwaypoint = state.counts.navwaypoint,
        userwaypoint = state.counts.userwaypoint,
        blob = state.counts.blob,
        active = #poiActive,
    }
end

function FluxBattlefieldMapQuestPins:Start()
    state.started = true
    HookCanvasSize()
    if HasMapQuestAPI() then
        RegisterEvents()
    else
        state.lastSkipReason = "no-quest-map-api"
    end
    QueueRefresh()
    return true
end

function FluxBattlefieldMapQuestPins:Stop()
    state.started = false
    state.refreshQueued = false
    UnregisterEvents()
    ClearOverlayPins()
    if state.blobFrame then
        state.blobFrame:Hide()
        if state.blobFrame.DrawNone then
            pcall(state.blobFrame.DrawNone, state.blobFrame)
        end
    end
    if state.userPin then
        state.userPin:Hide()
    end
    state.lastSkipReason = "stopped"
    state.backend = nil
end
