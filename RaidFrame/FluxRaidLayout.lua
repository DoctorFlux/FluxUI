local addonName, ns = ...

-- Keep the Forever compatibility fallback local to Flux-owned frames.
local FluxDrivers = ((ns and ns.Flux) or _G.Flux or {}).Restricted
local useFluxDrivers = FluxDrivers and FluxDrivers.Works and not FluxDrivers.Works()
local RegisterStateDriver = (useFluxDrivers and FluxDrivers.RegisterStateDriver) or RegisterStateDriver

-- Reverse-column dock, header attributes, combat queue, Blizzard mute/restore.
-- Positions and group order match the previous Flux raid layout.

local Compat = FluxRaidCompat
local State = FluxRaidState
local min, max, floor = math.min, math.max, math.floor

local GROUP_COUNT = Compat.GROUP_COUNT or 8
local GRP_SPACING = Compat.GRP_SPACING or 0
local UNITS_PER_COLUMN = Compat.UNITS_PER_COLUMN or 5
local GROUP_LABEL_EXTRA = Compat.GROUP_LABEL_EXTRA or 14
local HEADER_PREFIX = "FluxRaidGrp"
local FLUX_RAID_STACK_LEFT_OFFSET = 0
local FLUX_FOCUS_PLACEMENT2_ABOVE_RAID_GAP = 4
local FLUX_FOCUS_PLACEMENT2_EXTRA_UP = 28
local MTMA_UNITS_PER_COLUMN = Compat.MTMA_UNITS_PER_COLUMN or 4
local MTMA_MAX_COLUMNS = Compat.MTMA_MAX_COLUMNS or 10
local MTMA_EXTRA_Y_FOR_FOUR_PLUS = Compat.MTMA_EXTRA_Y_FOR_FOUR_PLUS or 60
local MTMA_CHAT_OVERLAP_GAP = 2
local MAX_RAID_ROSTER_SLOTS = _G.MAX_RAID_MEMBERS or 40

local pendingCombatWork = State.pendingCombatWork
local managerRepositionScheduled = false
local gridHideScheduled = false
local fluxRaidManagerHooksInstalled = false
local fluxRaidPartyHideHooked = false
local configureAndRefreshQueued = false
local refreshScheduled = false
local managerOriginal = setmetatable({}, {__mode="k"})
local managerRevealHooked = setmetatable({}, {__mode="k"})

local function Secret(value)
    return Compat.IsSecret and Compat.IsSecret(value)
end

local function ReadNumber(frame,method)
    if not frame or type(frame[method])~="function" then return nil end
    local value=frame[method](frame)
    if not Secret(value) and type(value)=="number" then return value end
end

local function PhysicalTop(frame)
    local top=ReadNumber(frame,"GetTop")
    local scale=ReadNumber(frame,"GetEffectiveScale") or 1
    return top and top*scale
end

local function ColumnHeight()
    local fh = FluxRaidVisuals.FRAME_HEIGHT
    local step = -(FluxRaidVisuals.CELL_JOIN_OVERLAP or Compat.HEADER_UNIT_YOFFSET or 4)
    return (UNITS_PER_COLUMN - 1) * (fh + step) + fh
end

local function TargetHeight() return FluxRaidVisuals.MINI_FRAME_HEIGHT or Compat.MTMA_TARGET_HEIGHT or 18 end
local function TargetGap()
    if FluxRaidVisuals.CELL_JOIN_OVERLAP then return -FluxRaidVisuals.CELL_JOIN_OVERLAP end
    return Compat.MTMA_TARGET_GAP or -4
end

local function MTMAChildStep()
    return FluxRaidVisuals.FRAME_HEIGHT + 2 * TargetGap() + TargetHeight()
end

function FluxRaid_GetColumnHeight()
    return ColumnHeight()
end

function FluxRaid_GetMTMAChildStep()
    return MTMAChildStep()
end

local function Queue(fn)
    pendingCombatWork[fn] = true
end

function FluxRaid_QueueWork(fn)
    if fn then Queue(fn) end
end

local function GetBorderTop()
    local border = _G["FluxUnifiedBorderFrame"]
    if border and border:IsShown() and border.GetTop then
        local top = border:GetTop()
        if top and top > 0 then return top end
    end
    local statusBorder = _G["FluxStatusBarUnifiedBorderFrame"]
    if statusBorder and statusBorder:IsShown() and statusBorder.GetTop then
        local top = statusBorder:GetTop()
        if top and top > 0 then return top end
    end
    return 0
end

local function GetEditBoxHeight()
    local editBox = _G["ChatFrame1EditBox"]
    if editBox and editBox.GetHeight then
        local h = editBox:GetHeight()
        if h and h > 0 then return h end
    end
    return 32
end

local function GetChatHeight()
    if FluxWindowFrame and FluxWindowFrame.WINDOW_HEIGHT then
        return max(120, FluxWindowFrame.WINDOW_HEIGHT - 100)
    end
    return max(120, 200 * 1.35 - 100)
end

local function GetContainerBottomY()
    if _G.FluxChatFrame_GetPrimaryBottomInsetY then
        local okY, y = pcall(_G.FluxChatFrame_GetPrimaryBottomInsetY)
        local h
        if _G.FluxChatFrame_GetPrimaryChatHeight then
            local okH, chatH = pcall(_G.FluxChatFrame_GetPrimaryChatHeight)
            if okH and type(chatH) == "number" and chatH == chatH then
                h = chatH
            end
        end
        if okY and type(y) == "number" and y == y then
            return y + (h or GetChatHeight())
        end
    end
    return GetBorderTop() + GetEditBoxHeight() + GetChatHeight()
end

local function GetRaidRosterOccupiedSubgroup(i)
    local name, _, subgroup, level, _, classFileName = GetRaidRosterInfo(i)
    if not subgroup or subgroup < 1 or subgroup > GROUP_COUNT then return nil end
    if name and name ~= "" then return subgroup end
    if classFileName and classFileName ~= "" then return subgroup end
    if level and level > 0 then return subgroup end
    if UnitInRaid and UnitInRaid("player") == i then return subgroup end
    return nil
end

local function UnitIsMTMA(i)
    local unit = "raid" .. i
    if GetPartyAssignment then
        local ok1, isMT = pcall(GetPartyAssignment, "MAINTANK", unit)
        local ok2, isMA = pcall(GetPartyAssignment, "MAINASSIST", unit)
        if (ok1 and isMT) or (ok2 and isMA) then return true end
    end
    local _, _, _, _, _, _, _, _, _, role, _, assignedRole = GetRaidRosterInfo(i)
    return role == "MAINTANK" or role == "MAINASSIST" or assignedRole == "MAINTANK" or assignedRole == "MAINASSIST"
end

function FluxRaid_GetMTMARosterCount()
    if not IsInRaid() then return 0 end
    local count = 0
    for i = 1, MAX_RAID_ROSTER_SLOTS do
        local unit = "raid" .. i
        local unitOk = (UnitInRaid and UnitInRaid("player") == i) or UnitExists(unit)
        if GetRaidRosterOccupiedSubgroup(i) and unitOk and UnitIsMTMA(i) then
            count = count + 1
        end
    end
    return count
end

local PositionBlizzardRaidManager
local PositionContainer
local LayoutHeaders
local ConfigureRaidMode
local RefreshGroupVisibility
local ConfigureAndRefresh
local DisableBlizzardRaidFrames
local RetainNativeFallback

local function PetBattleBlocksReadiness()
    local driver = State.petBattleDriver
    return State.petBattleDriverReady and driver and driver.GetAttribute
        and driver:GetAttribute("state-groupupdate") == "hide"
end

PositionBlizzardRaidManager = function()
    if not FluxRaid_IsFluxRaidEnabled() then return end
    if not (Compat.CanPositionRaidManager and Compat.CanPositionRaidManager()) then return end
    local mgr = _G.CompactRaidFrameManager
    if not mgr then return end
    if InCombatLockdown() then
        Queue(PositionBlizzardRaidManager)
        return
    end
    -- Edit Mode's raid refresh expands / collapses the manager inside its pass.
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(PositionBlizzardRaidManager)
        return
    end
    local top
    local function include(header)
        if not header or not header.GetAttribute then return end
        if header.IsShown then
            local shown=header:IsShown()
            if Secret(shown) or not shown then return end
        end
        local child=header:GetAttribute("child1")
        if not child then return end
        local unit
        if child.GetAttribute then unit=child:GetAttribute("unit") else unit=child.unit end
        if Secret(unit) or type(unit)~="string" or unit=="" then return end
        local y=PhysicalTop(child)
        if y then top=top and max(top,y) or y end
    end
    for i=1,GROUP_COUNT do include(State.raidHeaders[i]) end
    include(State.mtmaHeader)
    -- Solo startup still prepares the future secure group grid. Position its
    -- manager now: a native reveal after a combat join cannot move it then.
    if not top then top=PhysicalTop(State.containerFrame) end
    if not top then return end
    if not managerOriginal[mgr] then
        managerOriginal[mgr]={scale=ReadNumber(mgr,"GetScale")}
    end
    local scale = (FluxRaidVisuals and FluxRaidVisuals.BLIZZARD_RAID_MANAGER_SCALE) or 0.7
    mgr:SetScale(scale)
    local collapsed=mgr.collapsed
    if Secret(collapsed) then return end
    local effective=ReadNumber(mgr,"GetEffectiveScale") or scale
    if effective<=0 then return end
    local db=FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    local clearance=((not db or db.showGroupLabels~=false) and GROUP_LABEL_EXTRA or 0)+6
    local uiScale=ReadNumber(UIParent,"GetEffectiveScale") or 1
    -- Retain old native X and one full-panel bottom reference for every
    -- collapsed/expanded/hidden state. Toggle-face height must not shift Y.
    local fa=FLUX_API
    local classic=fa and (fa.isAnyClassic or fa.isClassicEra or fa.isTBC or fa.isWrath or fa.isCata)
    local x=collapsed and (classic and -182 or -200) or (classic and -7 or 0)
    mgr:ClearAllPoints()
    mgr:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",
        x,
        (top+clearance*uiScale)/effective)
end

local function ScheduleBlizzardRaidManagerReposition()
    if not FluxRaid_IsFluxRaidEnabled() then return end
    if managerRepositionScheduled then return end
    managerRepositionScheduled = true
    C_Timer.After(0, function()
        managerRepositionScheduled = false
        PositionBlizzardRaidManager()
    end)
end

PositionContainer = function()
    if not FluxRaid_IsFluxRaidEnabled() then return end
    if InCombatLockdown() then
        Queue(PositionContainer)
        return
    end
    local containerFrame = State.containerFrame
    if not containerFrame then return end
    local yBottom = GetContainerBottomY()
    yBottom = yBottom + (Compat.GetChatTabLift and Compat.GetChatTabLift() or 28)
    containerFrame:SetFrameStrata("MEDIUM")
    containerFrame:SetFrameLevel(20)
    containerFrame:SetHeight(ColumnHeight() + GROUP_LABEL_EXTRA)
    containerFrame:ClearAllPoints()
    containerFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", FLUX_RAID_STACK_LEFT_OFFSET, yBottom)
    PositionBlizzardRaidManager()
    if _G.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack then
        _G.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack()
    end
    if _G.FluxUIPositionFocusFrameDefault and _G.FluxUnitFrames_GetPlayerTargetPlacement
        and _G.FluxUnitFrames_GetPlayerTargetPlacement() == 2 then
        C_Timer.After(0, _G.FluxUIPositionFocusFrameDefault)
    end
end

function FluxRaid_GetPreviewStackVerticalPosition()
    local yBottom = GetContainerBottomY()
    return yBottom + (Compat.GetChatTabLift and Compat.GetChatTabLift() or 28)
end

function FluxRaidFrame_UpdatePosition()
    PositionContainer()
end

local function DistributeRaidMembers_FocusAnchor(n)
    local counts = { 0, 0, 0, 0, 0, 0, 0, 0 }
    local left = n
    for g = 1, GROUP_COUNT do
        local c = min(UNITS_PER_COLUMN, left)
        if c > 0 then
            counts[g] = c
            left = left - c
        end
        if left <= 0 then break end
    end
    return counts
end

function FluxRaid_ComputeSyntheticGroup2ColumnLeftX()
    local db = {}
    if FluxOptions and FluxOptions.GetRaidFrameDB then
        db = FluxOptions:GetRaidFrameDB() or {}
    end
    if FluxRaidVisuals and FluxRaidVisuals.ApplyRaidFrameTunables then
        FluxRaidVisuals.ApplyRaidFrameTunables(db)
    end
    local fw = FluxRaidVisuals.FRAME_WIDTH
    local colStep = fw + GRP_SPACING
    local counts = DistributeRaidMembers_FocusAnchor(10)
    if (counts[2] or 0) <= 0 then return nil end
    local visible = Compat.BuildVisibleGroupsReverse(function(g)
        return (counts[g] or 0) > 0
    end)
    local showMT = db.previewShowMTColumn ~= false
    local mtCount = 0
    if showMT then
        local m = tonumber(db.previewMainTankCount) or 2
        mtCount = max(1, min(8, floor(m)))
    end
    local layout = Compat.ComputeReverseColumnLayout(visible, showMT, mtCount, colStep, {
        groupCount = GROUP_COUNT,
        mtUnitsPerColumn = MTMA_UNITS_PER_COLUMN,
    })
    return layout.groupX and layout.groupX[2] or nil
end

function FluxRaid_GetPlacement2FocusAnchorBottomRight()
    local gap = FLUX_FOCUS_PLACEMENT2_ABOVE_RAID_GAP + FLUX_FOCUS_PLACEMENT2_EXTRA_UP
    local xSynth = FluxRaid_ComputeSyntheticGroup2ColumnLeftX()
    if not xSynth then return nil, nil end
    local rightX = FLUX_RAID_STACK_LEFT_OFFSET + xSynth
    local bottomY
    local containerFrame = State.containerFrame
    if containerFrame and containerFrame:IsShown() and containerFrame.GetTop then
        local t = containerFrame:GetTop()
        if type(t) == "number" and t == t then
            bottomY = t + gap
        end
    end
    if not bottomY then
        local yBottom = GetContainerBottomY() + (Compat.GetChatTabLift and Compat.GetChatTabLift() or 28)
        bottomY = yBottom + ColumnHeight() + GROUP_LABEL_EXTRA + gap
    end
    return rightX, bottomY
end

local function GetGroupColumnLabelText(groupIndex)
    if groupIndex == 1 and IsInGroup() and not IsInRaid() then
        return "Party"
    end
    return tostring(groupIndex)
end

local function EnsureGroupColumnLabels()
    local containerFrame = State.containerFrame
    if containerFrame and containerFrame._fluxGroupLabelsReady then return end
    local function makeLabel(header, text)
        if not header or header._fluxGroupLabel then return end
        local fs = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("BOTTOM", header, "TOP", 0, 4)
        fs:SetShadowOffset(1, -1)
        fs:SetText(text)
        header._fluxGroupLabel = fs
    end
    if State.mtmaHeader then
        makeLabel(State.mtmaHeader, "MT")
    end
    for i = 1, GROUP_COUNT do
        local h = State.raidHeaders[i]
        if h then makeLabel(h, GetGroupColumnLabelText(i)) end
    end
    if containerFrame then
        containerFrame._fluxGroupLabelsReady = true
    end
end

local function RaidGroupLabelsEnabled()
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    if not db or db.showGroupLabels == nil then
        return true
    end
    return db.showGroupLabels and true or false
end

local function UpdateGroupColumnLabels()
    local enabled = RaidGroupLabelsEnabled()
    local mtmaHeader = State.mtmaHeader
    if mtmaHeader and mtmaHeader._fluxGroupLabel then
        if enabled then
            mtmaHeader._fluxGroupLabel:Show()
        else
            mtmaHeader._fluxGroupLabel:Hide()
        end
    end
    for i = 1, GROUP_COUNT do
        local h = State.raidHeaders[i]
        if h and h._fluxGroupLabel then
            if not enabled then
                h._fluxGroupLabel:Hide()
            else
                h._fluxGroupLabel:SetText(GetGroupColumnLabelText(i))
                h._fluxGroupLabel:Show()
            end
        end
    end
end

local function ApplyMTMAChatOverlapLift()
    if InCombatLockdown() then return end
    local mtmaHeader = State.mtmaHeader
    local containerFrame = State.containerFrame
    if not mtmaHeader or not mtmaHeader:IsShown() or not containerFrame then return end
    local chat = _G.ChatFrame1
    if not chat or not chat.GetTop or not mtmaHeader.GetBottom then return end
    if not chat:IsVisible() then return end
    local chatTop = chat:GetTop()
    local mtBottom = mtmaHeader:GetBottom()
    if not chatTop or not mtBottom then return end
    if mtBottom >= chatTop + MTMA_CHAT_OVERLAP_GAP then return end
    local lift = (chatTop + MTMA_CHAT_OVERLAP_GAP) - mtBottom
    if lift < 0.5 then return end
    local pt, relTo, relPt, xOfs, yOfs = mtmaHeader:GetPoint(1)
    if pt ~= "TOPLEFT" or relTo ~= containerFrame or relPt ~= "TOPLEFT" then return end
    mtmaHeader:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", xOfs or 0, (yOfs or 0) + lift)
    PositionBlizzardRaidManager()
end

LayoutHeaders = function()
    if InCombatLockdown() then
        Queue(LayoutHeaders)
        return
    end
    local containerFrame = State.containerFrame
    if not containerFrame then return end
    local gc = { 0, 0, 0, 0, 0, 0, 0, 0 }
    if IsInRaid() then
        for ri = 1, MAX_RAID_ROSTER_SLOTS do
            local sg = GetRaidRosterOccupiedSubgroup(ri)
            local unit = "raid" .. ri
            local unitOk = (UnitInRaid and UnitInRaid("player") == ri)
                or (Compat.UnitTokenValid and Compat.UnitTokenValid(unit))
                or UnitExists(unit)
            if sg and unitOk then
                gc[sg] = (gc[sg] or 0) + 1
            end
        end
    elseif IsInGroup() then
        gc[1] = 1
    end

    local colStep = FluxRaidVisuals.FRAME_WIDTH + GRP_SPACING
    local visible = Compat.BuildVisibleGroupsReverse(function(g)
        return (gc[g] or 0) > 0 and State.raidHeaders[g] ~= nil
    end)
    local mtmaHeader = State.mtmaHeader
    local mtShown = mtmaHeader and mtmaHeader:IsShown()
    local mtCount = (mtShown and IsInRaid()) and FluxRaid_GetMTMARosterCount() or 0
    local mtStackHeight = 0
    if mtShown then
        if mtCount >= 1 then
            mtStackHeight = min(4, mtCount) * MTMAChildStep()
        else
            mtStackHeight = MTMAChildStep()
        end
    end
    local yAlignMT = 0
    if mtShown and mtCount >= 4 then
        yAlignMT = max(0, ColumnHeight() - mtStackHeight) + MTMA_EXTRA_Y_FOR_FOUR_PLUS
    end
    local layout = Compat.ComputeReverseColumnLayout(visible, mtShown, mtCount, colStep, {
        groupCount = GROUP_COUNT,
        mtUnitsPerColumn = MTMA_UNITS_PER_COLUMN,
    })
    if mtmaHeader then
        mtmaHeader:ClearAllPoints()
        if mtShown and layout.x_lo and layout.k >= 1 then
            mtmaHeader:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", layout.xMT, yAlignMT)
        else
            mtmaHeader:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 0, 0)
        end
    end
    for g = 1, GROUP_COUNT do
        local header = State.raidHeaders[g]
        if header then
            header:ClearAllPoints()
            local gx = layout.groupX and layout.groupX[g]
            if (gc[g] or 0) > 0 and gx then
                header:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", gx, 0)
                if header._fluxGroupLabel then header._fluxGroupLabel:Show() end
            else
                header:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", -10000, 0)
                if header._fluxGroupLabel then header._fluxGroupLabel:Hide() end
            end
        end
    end
    containerFrame:SetWidth(layout.totalSlots * colStep)
    if State.secureRosterPrepared and FluxRaidSecure then
        local ready=FluxRaidSecure.RefreshRosterLayout(containerFrame,State.raidHeaders,
            FluxRaid_DisplayMainTankAndAssistCVarEnabled() and State.mtmaHeader or nil,
            {colStep=colStep,columnHeight=ColumnHeight(),mtChildStep=MTMAChildStep(),mtExtraY=MTMA_EXTRA_Y_FOR_FOUR_PLUS})
        if not ready then
            State.secureRosterError="Secure roster layout is unavailable"
            return false
        end
    end
    if mtShown and mtmaHeader then
        C_Timer.After(0, ApplyMTMAChatOverlapLift)
    end
    return true
end

local function PrecreateHeaderChildren(header)
    if not header then return false end
    if InCombatLockdown() then return false end
    local maxColumns = header:GetAttribute("maxColumns") or 1
    local unitsPerColumn = header:GetAttribute("unitsPerColumn") or 5
    local startingIndex = header:GetAttribute("startingIndex") or 1
    local maxUnits = maxColumns * unitsPerColumn
    if header:GetAttribute("child" .. maxUnits) then
        header._fluxPrecreated = true
        return true
    end
    local container = State.containerFrame
    local containerWasShown = container and container:IsShown()
    local wasShown = header:IsShown()
    -- Native attribute updates allocate only while effectively visible. The
    -- owned container starts hidden; showing just its child cannot seed a pool.
    if container and not containerWasShown then container:Show() end
    if not wasShown then header:Show() end
    if not header.IsVisible or header:IsVisible() then
        header:SetAttribute("startingIndex", -maxUnits + 1)
        header:SetAttribute("startingIndex", startingIndex)
    end
    header._fluxPrecreated = header:GetAttribute("child" .. maxUnits) ~= nil
    if not wasShown then header:Hide() end
    if container and not containerWasShown then container:Hide() end
    return header._fluxPrecreated
end

local function SetHeaderAttributes(header, groupFilter, showRaid, showParty, showPlayer)
    if InCombatLockdown() then
        Queue(function() SetHeaderAttributes(header, groupFilter, showRaid, showParty, showPlayer) end)
        return
    end
    header:Hide()
    header:SetAttribute("template", "FluxRaidUnitTemplate")
    header:SetAttribute("templateType", "Button")
    header:SetAttribute("groupFilter", groupFilter)
    header:SetAttribute("showRaid", showRaid)
    header:SetAttribute("showParty", showParty)
    header:SetAttribute("showPlayer", showPlayer)
    header:SetAttribute("showSolo", false)
    header:SetAttribute("point", "TOP")
    header:SetAttribute("xOffset", 0)
    header:SetAttribute("yOffset", FluxRaidVisuals.CELL_JOIN_OVERLAP or Compat.HEADER_UNIT_YOFFSET or 4)
    -- Native discrete raid groups preserve roster index; party order starts
    -- with player followed by party1..4. Names must not reorder group rows.
    header:SetAttribute("sortMethod", "INDEX")
    header:SetAttribute("sortDir", "ASC")
    header:SetAttribute("unitsPerColumn", UNITS_PER_COLUMN)
    header:SetAttribute("maxColumns", 1)
    header:SetAttribute("startingIndex", 1)
    header:SetAttribute("minWidth", FluxRaidVisuals.FRAME_WIDTH)
    header:SetAttribute("minHeight", 10)
    if header ~= State.mtmaHeader then
        header:SetAttribute("roleFilter", nil)
    end
    header:Hide()
end

ConfigureRaidMode = function()
    if InCombatLockdown() then
        Queue(ConfigureRaidMode)
        return
    end
    local inRaid = IsInRaid()
    local inGroup = IsInGroup()
    local ready = true
    if FluxRaidSecure and FluxRaidSecure.ConfigureHeader then
        -- Prepare every future mode and all native child capacity while OOC.
        -- Leaving the container alive lets secure drivers reveal a roster when
        -- the player joins a group during combat, including from solo startup.
        for i=1,GROUP_COUNT do
            local header=State.raidHeaders[i]
            SetHeaderAttributes(header,tostring(i),true,i==1,true)
            ready=PrecreateHeaderChildren(header) and ready
        end
        local mt=State.mtmaHeader
        if mt then
            SetHeaderAttributes(mt,"MAINTANK,MAINASSIST",true,false,true)
            mt:SetAttribute("roleFilter","MAINTANK,MAINASSIST")
            mt:SetAttribute("unitsPerColumn",MTMA_UNITS_PER_COLUMN)
            mt:SetAttribute("maxColumns",MTMA_MAX_COLUMNS)
            mt:SetAttribute("columnAnchorPoint","LEFT")
            mt:SetAttribute("columnSpacing",GRP_SPACING)
            mt:SetAttribute("xOffset",0)
            mt:SetAttribute("yOffset",-(TargetHeight()+2*TargetGap()))
            ready=PrecreateHeaderChildren(mt) and ready
        else ready=false end
        if not ready then State.secureRosterPrepared=false; return false end
        for i=1,GROUP_COUNT do
            local header=State.raidHeaders[i]
            ready=FluxRaidSecure.ConfigureHeader(header,i,false) and ready
            for childIndex=1,UNITS_PER_COLUMN do
                local child=header:GetAttribute("child"..childIndex)
                ready=FluxRaidSecure.AttachHeaderChild(child) and ready
            end
        end
        for childIndex=1,MTMA_UNITS_PER_COLUMN*MTMA_MAX_COLUMNS do
            local child=mt:GetAttribute("child"..childIndex)
            ready=FluxRaidSecure.AttachHeaderChild(child) and ready
        end
        if FluxRaid_DisplayMainTankAndAssistCVarEnabled() then
            ready=FluxRaidSecure.ConfigureHeader(mt,9,true) and ready
        else FluxRaidSecure.DisableHeader(mt) end
        State.secureRosterPrepared=ready
        return ready
    end
    if inRaid then
        for i = 1, GROUP_COUNT do
            SetHeaderAttributes(State.raidHeaders[i], tostring(i), true, false, false)
            ready = PrecreateHeaderChildren(State.raidHeaders[i]) and ready
        end
        local mtmaHeader = State.mtmaHeader
        if mtmaHeader then
            SetHeaderAttributes(mtmaHeader, "MAINTANK,MAINASSIST", true, false, false)
            mtmaHeader:SetAttribute("roleFilter", "MAINTANK,MAINASSIST")
            mtmaHeader:SetAttribute("unitsPerColumn", MTMA_UNITS_PER_COLUMN)
            mtmaHeader:SetAttribute("maxColumns", MTMA_MAX_COLUMNS)
            mtmaHeader:SetAttribute("columnAnchorPoint", "LEFT")
            mtmaHeader:SetAttribute("columnSpacing", GRP_SPACING)
            mtmaHeader:SetAttribute("xOffset", 0)
            mtmaHeader:SetAttribute("yOffset", -(TargetHeight() + 2 * TargetGap()))
            ready = PrecreateHeaderChildren(mtmaHeader) and ready
        else
            ready = false
        end
    elseif inGroup then
        SetHeaderAttributes(State.raidHeaders[1], "1", false, true, true)
        ready = PrecreateHeaderChildren(State.raidHeaders[1])
        for i = 2, GROUP_COUNT do
            State.raidHeaders[i]:Hide()
        end
        if State.mtmaHeader then State.mtmaHeader:Hide() end
    else
        for i = 1, GROUP_COUNT do
            State.raidHeaders[i]:Hide()
        end
        if State.mtmaHeader then State.mtmaHeader:Hide() end
    end
    return ready
end

RefreshGroupVisibility = function(rosterOnly)
    if InCombatLockdown() then
        Queue(RefreshGroupVisibility)
        return
    end
    local containerFrame = State.containerFrame
    local inRaid = IsInRaid()
    local inGroup = IsInGroup()
    if State.secureRosterPrepared then
        containerFrame:Show()
        EnsureGroupColumnLabels()
        if LayoutHeaders()==false then return false end
        UpdateGroupColumnLabels()
        if FluxRaid_SyncHeaderChildUnits then FluxRaid_SyncHeaderChildUnits() end
        if FluxRaid_RefreshMTMATargetAttachments then FluxRaid_RefreshMTMATargetAttachments() end
        if not rosterOnly and FluxRaidHealerExtras then FluxRaidHealerExtras.RefreshLayout() end
        return
    end
    if not inRaid and not inGroup then
        if containerFrame then containerFrame:Hide() end
        return
    end
    if inRaid then
        local hasMTMA = false
        for i = 1, MAX_RAID_ROSTER_SLOTS do
            local sg = GetRaidRosterOccupiedSubgroup(i)
            local unit = "raid" .. i
            local unitOk = (UnitInRaid and UnitInRaid("player") == i) or UnitExists(unit)
            if sg and unitOk and UnitIsMTMA(i) then
                hasMTMA = true
                break
            end
        end
        for i = 1, GROUP_COUNT do
            if State.raidHeaders[i] and not State.raidHeaders[i]:IsShown() then
                State.raidHeaders[i]:Show()
            end
        end
        local mtmaHeader = State.mtmaHeader
        if hasMTMA and FluxRaid_DisplayMainTankAndAssistCVarEnabled() then
            if mtmaHeader and not mtmaHeader:IsShown() then
                mtmaHeader:Show()
            end
            if mtmaHeader then PrecreateHeaderChildren(mtmaHeader) end
        elseif mtmaHeader and mtmaHeader:IsShown() then
            mtmaHeader:Hide()
        end
    else
        if State.raidHeaders[1] and not State.raidHeaders[1]:IsShown() then
            State.raidHeaders[1]:Show()
        end
        for i = 2, GROUP_COUNT do
            if State.raidHeaders[i] and State.raidHeaders[i]:IsShown() then
                State.raidHeaders[i]:Hide()
            end
        end
        if State.mtmaHeader and State.mtmaHeader:IsShown() then
            State.mtmaHeader:Hide()
        end
    end
    containerFrame:Show()
    EnsureGroupColumnLabels()
    LayoutHeaders()
    UpdateGroupColumnLabels()
    if FluxRaid_SyncHeaderChildUnits then FluxRaid_SyncHeaderChildUnits() end
    if FluxRaid_RefreshMTMATargetAttachments then FluxRaid_RefreshMTMATargetAttachments() end
    if FluxRaidHealerExtras then FluxRaidHealerExtras.RefreshLayout() end
end

function FluxRaid_GetFirstGroupNthMemberBottomFromScreen(n)
    n = tonumber(n) or UNITS_PER_COLUMN
    if n < 1 then n = 1 end
    if n > UNITS_PER_COLUMN then n = UNITS_PER_COLUMN end
    if not FluxRaid_IsFluxRaidEnabled() then return nil end
    local h = State.raidHeaders[1]
    if not h or not h:IsShown() then return nil end
    local btn = h:GetAttribute("child" .. n)
    if not btn or not btn:IsShown() then
        for i = n - 1, 1, -1 do
            local b = h:GetAttribute("child" .. i)
            if b and b:IsShown() then
                btn = b
                break
            end
        end
    end
    if not btn or not btn:IsShown() or not btn.GetBottom then return nil end
    local bot = btn:GetBottom()
    if type(bot) ~= "number" or bot ~= bot then return nil end
    return bot
end

RetainNativeFallback = function()
    State.secureConfigured=false
    State.secureRosterPrepared=false
    for _,header in pairs(State.raidHeaders) do
        if FluxRaidSecure then FluxRaidSecure.DisableHeader(header) else header:Hide() end
    end
    if State.mtmaHeader then
        if FluxRaidSecure then FluxRaidSecure.DisableHeader(State.mtmaHeader) else State.mtmaHeader:Hide() end
    end
    if FluxRaid_RestoreBlizzardRaidFrames then FluxRaid_RestoreBlizzardRaidFrames() end
    Queue(ConfigureAndRefresh)
end

ConfigureAndRefresh = function()
    if InCombatLockdown() then
        Queue(ConfigureAndRefresh)
        return
    end
    if not State.isInitialized then return end
    if not FluxRaid_IsFluxRaidEnabled() then
        if State.containerFrame then State.containerFrame:Hide() end
        return
    end
    if not State.secureConfigured and PetBattleBlocksReadiness() then
        Queue(ConfigureAndRefresh)
        return
    end
    if configureAndRefreshQueued then return end
    configureAndRefreshQueued = true
    pendingCombatWork[ConfigureAndRefresh] = nil
    local ok, err = pcall(function()
        if ns.PartyFrames then ns.PartyFrames.ApplyOptions() end
        if not ConfigureRaidMode() then
            -- A hidden ancestor can prevent native pool allocation. Keep those
            -- headers hidden through a combat reveal and retain Blizzard's UI.
            State.secureConfigured = false
            if FluxRaidSecure then
                for _,header in pairs(State.raidHeaders) do FluxRaidSecure.DisableHeader(header) end
                if State.mtmaHeader then FluxRaidSecure.DisableHeader(State.mtmaHeader) end
                State.secureRosterPrepared=false
            end
            for i = 1, GROUP_COUNT do
                if State.raidHeaders[i] then State.raidHeaders[i]:Hide() end
            end
            if State.mtmaHeader then State.mtmaHeader:Hide() end
            if FluxRaid_RestoreBlizzardRaidFrames then FluxRaid_RestoreBlizzardRaidFrames() end
            Queue(ConfigureAndRefresh)
            -- An owned-container OnShow retries after its ancestor returns.
            if State.containerFrame then State.containerFrame:Show() end
            return
        end
        if RefreshGroupVisibility()==false then RetainNativeFallback(); return end
        PositionContainer()
        if FluxRaid_SyncHeaderChildUnits then FluxRaid_SyncHeaderChildUnits() end
        if FluxRaid_ForEachHeaderChild then
            FluxRaid_ForEachHeaderChild(function(btn)
                if btn._fluxRaidUnit and not btn._fluxRaidMini and FluxRaidVisuals.SafeSetUnitFrameSize then
                    FluxRaidVisuals.SafeSetUnitFrameSize(btn, FluxRaidVisuals.FRAME_WIDTH, FluxRaidVisuals.FRAME_HEIGHT)
                end
            end)
        end
        local needsPa = false
        if FluxRaid_ForEachHeaderChild then
            FluxRaid_ForEachHeaderChild(function(btn)
                if btn._fluxNeedsPrivateAuraSync or btn._fluxNeedsSizeRefresh or btn._fluxNeedsMTMA then
                    needsPa = true
                end
            end)
        end
        if needsPa and FluxRaid_ApplyChromeToChildren then
            FluxRaid_ApplyChromeToChildren(true)
            if FluxRaid_RefreshMTMATargetAttachments then
                FluxRaid_RefreshMTMATargetAttachments()
            end
        end
        local wasReady = State.secureConfigured
        State.secureConfigured = true
        if not wasReady and DisableBlizzardRaidFrames then DisableBlizzardRaidFrames() end
        C_Timer.After(0, function()
            if InCombatLockdown() then Queue(ConfigureAndRefresh); return end
            if not FluxRaid_IsFluxRaidEnabled() then return end
            if FluxRaid_SyncHeaderChildUnits then FluxRaid_SyncHeaderChildUnits() end
            if LayoutHeaders()==false then RetainNativeFallback(); return end
            PositionContainer()
        end)
    end)
    configureAndRefreshQueued = false
    if not ok then error(err) end
end

local function ScheduleConfigureAndRefresh()
    if refreshScheduled then return end
    refreshScheduled = true
    local function Refresh()
        refreshScheduled = false
        ConfigureAndRefresh()
    end
    if ns.Flux and ns.Flux.Timer then ns.Flux.Timer.After(0, Refresh)
    elseif C_Timer and C_Timer.After then C_Timer.After(0, Refresh)
    else Refresh() end
end

function FluxRaid_QueueReadinessRetry()
    if not State.isInitialized or State.secureConfigured or not FluxRaid_IsFluxRaidEnabled() then return end
    ScheduleConfigureAndRefresh()
end

function FluxRaid_QueueConfigureAndRefresh()
    if configureAndRefreshQueued or InCombatLockdown() then
        Queue(ConfigureAndRefresh)
        return
    end
    if not State.secureConfigured then
        ConfigureAndRefresh()
        return
    end
    ScheduleConfigureAndRefresh()
end

-- Hide native grids in place and retain native events/visibility. Selection
-- textures ignore parent alpha, so suppress their own alpha separately. Never
-- assign TryUpdate / RefreshMembers, never SetScript, never
-- write frame.unit, never call CompactUnitFrame_*, and never edit raid profiles.

local BLIZZARD_GRID_FRAME_NAMES = {
    "CompactRaidFrameContainer",
    "CompactPartyFrame",
    "PartyFrame",
}

local function IsBlizzardPartyRaidChrome(frame)
    if not frame then return false end
    if frame._fluxRaidUnit then return false end
    if frame.GetParent then
        local parent=frame:GetParent()
        if parent and (parent==_G.CompactRaidFrameContainer or parent==_G.CompactPartyFrame) then return true end
    end
    local partyFrame = _G.PartyFrame
    if partyFrame and partyFrame.PartyMemberFramePool and partyFrame.PartyMemberFramePool.EnumerateActive then
        local ok, inPool = pcall(function()
            for memberFrame in partyFrame.PartyMemberFramePool:EnumerateActive() do
                if memberFrame == frame then return true end
            end
            return false
        end)
        if ok and inPool then return true end
    end
    if not frame.GetName then return false end
    local name = frame:GetName()
    if Secret(name) then return false end
    if name == "PartyFrame" or name == "CompactPartyFrame" then return true end
    if name and (name:match("^PartyMemberFrame") or name:match("^CompactPartyFrame") or name:match("^CompactRaidFrame") or name:match("^CompactRaidGroup")) then
        return true
    end
    return false
end

local function GetBlizz()
    local Flux = ns and ns.Flux
    return Flux and Flux.Blizz
end

local nativeOverlayAlphas=setmetatable({}, {__mode="k"})
local nativeOverlayParentAlphas=setmetatable({}, {__mode="k"})
local nativeOverlayHooks={}

local function SkipNativeAuraMouseChild(child)
    if child.IsForbidden then
        local forbidden=child:IsForbidden()
        if Secret(forbidden) or forbidden then return true end
    end
    if child.GetObjectType then
        local kind=child:GetObjectType()
        return Secret(kind) or kind=="AuraContainer" or kind=="AuraButton"
    end
    return false
end

local function SuppressNativeOverlay(region)
    if not region or not region.GetAlpha or not region.SetAlpha then return end
    -- These flags are static presentation metadata. Restore them on disable;
    -- inheriting the hidden grid's alpha also handles opaque native alpha.
    if region.IsIgnoringParentAlpha and region.SetIgnoreParentAlpha then
        if nativeOverlayParentAlphas[region]==nil then
            local ignore=region:IsIgnoringParentAlpha()
            if not Secret(ignore) and type(ignore)=="boolean" then nativeOverlayParentAlphas[region]=ignore end
        end
        if nativeOverlayParentAlphas[region]~=nil then region:SetIgnoreParentAlpha(false) end
    end
    if nativeOverlayAlphas[region]==nil then
        local alpha=region:GetAlpha()
        if Secret(alpha) or type(alpha)~="number" then return end
        nativeOverlayAlphas[region]=alpha
    end
    -- Native selection and ready-check handlers only Show/Hide these objects;
    -- alpha zero survives their updates without replacing native handlers.
    region:SetAlpha(0)
end

local function SuppressNativeSelection(frame)
    if not frame or frame._fluxRaidUnit then return end
    if frame.IsForbidden then
        local forbidden=frame:IsForbidden()
        if Secret(forbidden) or forbidden then return end
    end
    -- Exact native XML aliases marked ignoreParentAlpha. The ready-check
    -- texture ignores its frame alpha too, so both exposed objects are needed.
    -- Never enumerate regions or inspect restricted native aura descendants.
    SuppressNativeOverlay(frame.selectionHighlight)
    local ready=frame.readyCheckIcon
    SuppressNativeOverlay(ready)
    SuppressNativeOverlay(ready and ready.Icon)
end

local function SuppressNativeSelections()
    local container=_G.CompactRaidFrameContainer
    if container and type(container.ApplyToFrames)=="function" then
        container:ApplyToFrames("all",SuppressNativeSelection)
    end
    local party=_G.CompactPartyFrame
    for _,key in ipairs({"memberUnitFrames","petUnitFrames"}) do
        for _,frame in ipairs(party and party[key] or {}) do SuppressNativeSelection(frame) end
    end
    for i=1,40 do
        SuppressNativeSelection(_G["CompactRaidFrame"..i])
        if i<=5 then
            SuppressNativeSelection(_G["CompactPartyFrameMember"..i])
            SuppressNativeSelection(_G["CompactPartyFramePet"..i])
        end
    end
    for group=1,8 do for member=1,5 do
        SuppressNativeSelection(_G["CompactRaidGroup"..group.."Member"..member])
    end end
end

local function RestoreNativeSelections()
    for region,alpha in pairs(nativeOverlayAlphas) do
        local current=region:GetAlpha()
        if Secret(current) or current==0 then region:SetAlpha(alpha) end
        nativeOverlayAlphas[region]=nil
    end
    for region,ignore in pairs(nativeOverlayParentAlphas) do
        local current=region:IsIgnoringParentAlpha()
        if not Secret(current) and current==false then region:SetIgnoreParentAlpha(ignore) end
        nativeOverlayParentAlphas[region]=nil
    end
end

local function HideBlizzardGrid()
    if not State.secureConfigured then return end
    if InCombatLockdown() then Queue(HideBlizzardGrid);return end
    -- Edit Mode's party / raid refresh shows these frames inside its pass.
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(HideBlizzardGrid)
        return
    end
    local Blizz = GetBlizz()
    if not Blizz then return end
    for i = 1, #BLIZZARD_GRID_FRAME_NAMES do
        local frame = _G[BLIZZARD_GRID_FRAME_NAMES[i]]
        local unavailable
        if frame and frame.IsForbidden then
            local forbidden=frame:IsForbidden()
            unavailable=Secret(forbidden) or forbidden
        end
        if frame and not unavailable then
            -- Edit Mode resets the same native party frames on save/close.
            -- Insecure hidden-parent visibility must not enter their setup pass.
            Blizz.Hide(frame, { keepEvents = true, keepParent = true, skipMouseChild=SkipNativeAuraMouseChild })
        end
    end
    SuppressNativeSelections()
end

local function ShowBlizzardGrid()
    local Blizz = GetBlizz()
    if not Blizz then return end
    for i = 1, #BLIZZARD_GRID_FRAME_NAMES do
        local frame = _G[BLIZZARD_GRID_FRAME_NAMES[i]]
        if frame then
            Blizz.Unhide(frame)
        end
    end
    RestoreNativeSelections()
end

-- CompactPartyFrame is created on demand; hide it again once Blizzard builds or shows it.
local function InstallBlizzardPartyHideHooks()
    for _,name in ipairs({"CompactUnitFrame_SetUpFrame","CompactUnitFrame_UpdateSelectionHighlight"}) do
        if hooksecurefunc and _G[name] and not nativeOverlayHooks[name] then
            nativeOverlayHooks[name]=true
            hooksecurefunc(name,function(frame)
                if not FluxRaid_IsFluxRaidEnabled() or not State.secureConfigured then return end
                if not IsBlizzardPartyRaidChrome(frame) then return end
                -- Alpha and parent-alpha inheritance are unprotected display
                -- methods. Late combat-created cells must not flash a ghost.
                if FluxEditModeBusy and FluxEditModeBusy() then
                    FluxRaid_ScheduleBlizzardGridHideCheck()
                else SuppressNativeSelection(frame) end
            end)
        end
    end
    if fluxRaidPartyHideHooked or not hooksecurefunc then return end
    fluxRaidPartyHideHooked = true
    if _G.CompactPartyFrame_Generate then
        hooksecurefunc("CompactPartyFrame_Generate", function()
            FluxRaid_ScheduleBlizzardGridHideCheck()
        end)
    end
    if _G.CompactRaidFrameManager_UpdateShown then
        hooksecurefunc("CompactRaidFrameManager_UpdateShown", function()
            FluxRaid_ScheduleBlizzardGridHideCheck()
        end)
    end
end

function FluxRaid_InstallManagerHooks()
    if InCombatLockdown() then Queue(FluxRaid_InstallManagerHooks);return end
    local manager=_G.CompactRaidFrameManager
    if manager and manager.HookScript and not managerRevealHooked[manager] then
        managerRevealHooked[manager]=true
        manager:HookScript("OnShow",ScheduleBlizzardRaidManagerReposition)
    end
    if fluxRaidManagerHooksInstalled then
        InstallBlizzardPartyHideHooks()
        return
    end
    if not hooksecurefunc then return end
    if CompactRaidFrameManager_Expand then
        hooksecurefunc("CompactRaidFrameManager_Expand", ScheduleBlizzardRaidManagerReposition)
    end
    if CompactRaidFrameManager_Collapse then
        hooksecurefunc("CompactRaidFrameManager_Collapse", ScheduleBlizzardRaidManagerReposition)
    end
    fluxRaidManagerHooksInstalled = true
    InstallBlizzardPartyHideHooks()
end

function FluxRaid_ScheduleBlizzardGridHideCheck()
    if not State.secureConfigured then return end
    if not FluxRaid_IsFluxRaidEnabled() then return end
    if gridHideScheduled then return end
    gridHideScheduled = true
    C_Timer.After(0, function()
        gridHideScheduled = false
        if not FluxRaid_IsFluxRaidEnabled() then return end
        InstallBlizzardPartyHideHooks()
        HideBlizzardGrid()
    end)
end

function FluxRaid_ApplyBlizzardCompactGridHidden()
    FluxRaid_ScheduleBlizzardGridHideCheck()
end

local function ResetCompactRaidFrameManagerToBlizzardLayout()
    if not (Compat.HasCompactRaidFrameManager and Compat.HasCompactRaidFrameManager()) then return end
    local mgr = _G.CompactRaidFrameManager
    if not mgr then return end
    if mgr.IsForbidden then
        local forbidden=mgr:IsForbidden()
        if Secret(forbidden) or forbidden then return end
    end
    local saved=managerOriginal[mgr]
    if saved and saved.scale then mgr:SetScale(saved.scale) end
    pcall(function()
        if Secret(mgr.collapsed) then return end
        if mgr.collapsed and CompactRaidFrameManager_Collapse then
            CompactRaidFrameManager_Collapse(mgr)
        elseif CompactRaidFrameManager_Expand then
            CompactRaidFrameManager_Expand(mgr)
        end
    end)
    managerOriginal[mgr]=nil
    if CompactRaidFrameManager_UpdateContainerBounds then
        pcall(CompactRaidFrameManager_UpdateContainerBounds)
    end
end

function FluxRaid_RestoreBlizzardRaidFrames()
    if InCombatLockdown() then
        Queue(FluxRaid_RestoreBlizzardRaidFrames)
        return
    end
    ShowBlizzardGrid()
    ResetCompactRaidFrameManagerToBlizzardLayout()
end

DisableBlizzardRaidFrames = function()
    if not State.secureConfigured then return end
    if not FluxRaid_IsFluxRaidEnabled() then return end
    if InCombatLockdown() then
        Queue(DisableBlizzardRaidFrames)
        return
    end
    local kb = ns and ns.FluxMouseoverKeybind
    if kb and kb.UnregisterBlizzardCompactRaidFrames then
        pcall(kb.UnregisterBlizzardCompactRaidFrames, kb)
    end
    FluxRaid_ScheduleBlizzardGridHideCheck()
end

function FluxRaid_RunPendingCombatWork()
    if InCombatLockdown() then return end
    local work = pendingCombatWork
    State.pendingCombatWork = {}
    pendingCombatWork = State.pendingCombatWork
    local function run()
        for func in pairs(work) do
            if type(func) == "function" then
                if InCombatLockdown() then Queue(func) else
                    local ok, err = pcall(func)
                    if not ok then
                        Queue(func)
                        if geterrorhandler then geterrorhandler()(tostring(err)) end
                    end
                end
            end
        end
    end
    local Regen = _G.Flux and _G.Flux.Perf and _G.Flux.Perf.Regen
    if Regen and Regen.Time then
        Regen.Time("raid.pending", run)
    else
        run()
    end
end

local function RefreshPreparedRoster()
    if not State.isInitialized or not FluxRaid_IsFluxRaidEnabled() then return end
    -- Headers/party/pet drivers already cover every roster mode. Reinstalling
    -- them hides all children and reparses every aura when one member joins.
    if InCombatLockdown() then Queue(RefreshPreparedRoster); return end
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    local partyNotReady = db and db.partyAsRaid == false and ns.PartyFrames and not ns.PartyFrames.ready
    if not State.secureConfigured or not State.secureRosterPrepared or partyNotReady then
        ConfigureAndRefresh()
        return
    end
    if RefreshGroupVisibility(true)==false then RetainNativeFallback(); return end
    PositionContainer()
end

function FluxRaid_OnRosterOrPartyChanged()
    if State.rosterDirty then return end
    State.rosterDirty = true
    C_Timer.After(0, function()
        State.rosterDirty = false
        if FluxRaid_IsFluxRaidEnabled() then
            -- Labels can change during combat; membership/visibility continue
            -- in the prepared native drivers until this OOC reconciliation.
            if InCombatLockdown() then UpdateGroupColumnLabels() end
            RefreshPreparedRoster()
            ScheduleBlizzardRaidManagerReposition()
            FluxRaid_ScheduleBlizzardGridHideCheck()
            local kb = ns and ns.FluxMouseoverKeybind
            if kb and kb.UnregisterBlizzardCompactRaidFrames then
                pcall(kb.UnregisterBlizzardCompactRaidFrames, kb)
            end
        end
    end)
end

function FluxRaid_InitLayoutFrames()
    if InCombatLockdown() then Queue(FluxRaid_InitLayoutFrames); return false end
    State.containerFrame = _G["FluxRaidContainer"]
    local container = State.containerFrame
    if container and container.HookScript and not container._fluxRaidReadinessHooked then
        container._fluxRaidReadinessHooked = true
        container:HookScript("OnShow", function()
            if not State.isInitialized or State.secureConfigured or configureAndRefreshQueued
                or not FluxRaid_IsFluxRaidEnabled() then return end
            if PetBattleBlocksReadiness() or InCombatLockdown() then Queue(ConfigureAndRefresh); return end
            ScheduleConfigureAndRefresh()
        end)
    end
    if State.containerFrame and State.containerFrame.SetClipsChildren then
        pcall(State.containerFrame.SetClipsChildren, State.containerFrame, false)
    end
    for i = 1, GROUP_COUNT do
        local name = HEADER_PREFIX .. i
        local header = _G[name] or CreateFrame("Frame", name, State.containerFrame, "FluxRaidGroupHeaderTemplate")
        header:SetID(i)
        State.raidHeaders[i] = header
    end
    State.mtmaHeader = _G["FluxRaidMTMA"] or CreateFrame("Frame", "FluxRaidMTMA", State.containerFrame, "FluxRaidGroupHeaderTemplate")
    State.mtmaHeader:SetID(9)
    if State.mtmaHeader and State.mtmaHeader.SetClipsChildren then
        pcall(State.mtmaHeader.SetClipsChildren, State.mtmaHeader, false)
    end
    EnsureGroupColumnLabels()
    UpdateGroupColumnLabels()
end

function FluxRaid_InstallPetBattleDriver()
    if State.petBattleDriverReady then return true end
    if InCombatLockdown() then Queue(FluxRaid_InstallPetBattleDriver); return false end
    if not (Compat.CanUsePetBattleStateDriver and Compat.CanUsePetBattleStateDriver()) then return end
    local Restricted = ns.Flux and ns.Flux.Restricted
    if Restricted and Restricted.Works and not Restricted.Works() then return end
    local stateFrame = State.petBattleDriver or CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")
    State.petBattleDriver = stateFrame
    for i = 1, GROUP_COUNT do
        stateFrame:SetFrameRef("FluxRaidHeader" .. i, State.raidHeaders[i])
    end
    stateFrame:SetFrameRef("FluxRaidMTMA", State.mtmaHeader)
    local hideSnippet = ""
    for i = 1, GROUP_COUNT do
        hideSnippet = hideSnippet .. 'self:GetFrameRef("FluxRaidHeader' .. i .. '"):Hide()\n'
    end
    hideSnippet = hideSnippet .. 'self:GetFrameRef("FluxRaidMTMA"):Hide()\n'
    if Restricted and Restricted.SetSnippet then
        local ok = Restricted.SetSnippet(stateFrame, "_onstate-groupupdate", [[
            if newstate == "hide" then
                ]] .. hideSnippet .. [[
            end
        ]])
        if ok == false then return false end
    elseif not (ns.Flux and ns.Flux.Cap and ns.Flux.Cap.hasRestrictedClosures == false) then
        stateFrame:SetAttribute("_onstate-groupupdate", [[
            if newstate == "hide" then
                ]] .. hideSnippet .. [[
            end
        ]])
    end
    if Restricted and Restricted.Works and not Restricted.Works() then
        return
    end
    RegisterStateDriver(stateFrame, "groupupdate", "[petbattle] hide; show")
    State.petBattleDriverReady = true
    if stateFrame.HookScript and not stateFrame._fluxReadinessHooked then
        stateFrame._fluxReadinessHooked = true
        stateFrame:HookScript("OnAttributeChanged", function(_, name, value)
            -- The native driver may update after PET_BATTLE_CLOSE's next turn.
            if name == "state-groupupdate" and value == "show" then
                FluxRaid_QueueReadinessRetry()
            end
        end)
    end
    return true
end

function FluxRaid_DisableBlizzardNow()
    DisableBlizzardRaidFrames()
end

function FluxRaid_PositionContainer()
    PositionContainer()
end

if ns then
    ns.FluxRaid_GetColumnHeight = FluxRaid_GetColumnHeight
    ns.FluxRaid_GetMTMAChildStep = FluxRaid_GetMTMAChildStep
    ns.FluxRaid_GROUP_COUNT = GROUP_COUNT
    ns.FluxRaid_GetPlacement2FocusAnchorBottomRight = FluxRaid_GetPlacement2FocusAnchorBottomRight
    ns.FluxRaid_IsBlizzardPartyRaidChrome = IsBlizzardPartyRaidChrome
end

_G.FluxRaid_GetColumnHeight = FluxRaid_GetColumnHeight
_G.FluxRaid_GetMTMAChildStep = FluxRaid_GetMTMAChildStep
_G.FluxRaid_GetPlacement2FocusAnchorBottomRight = FluxRaid_GetPlacement2FocusAnchorBottomRight
_G.FluxRaid_ComputeSyntheticGroup2ColumnLeftX = FluxRaid_ComputeSyntheticGroup2ColumnLeftX
