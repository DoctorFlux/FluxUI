local addonName, ns = ...

-- Flux-owned raid unit buttons: event paint, secret-safe bars, auras, MT/MA minis.
-- Does not call CompactUnitFrame_Update* / SetUnit / OnUpdate.

local Compat = FluxRaidCompat
local State = FluxRaidState
local pairs, ipairs, type, pcall, tostring = pairs, ipairs, type, pcall, tostring
local max, floor = math.max, math.floor

local DISPEL_TYPES = { Magic = true, Curse = true, Disease = true, Poison = true, Bleed = true }
local ROLE_ATLAS = {
    TANK = "roleicon-tiny-tank",
    HEALER = "roleicon-tiny-healer",
    DAMAGER = "roleicon-tiny-dps",
}

local rangePollTicker = nil
local EnsureRangePoll

local function IsSecret(v)
    return Compat.IsSecret and Compat.IsSecret(v)
end

local function UnitOf(frame)
    return frame and (frame.displayedUnit or frame.unit)
end

local function ShowRegion(region, shown)
    if not region then return end
    if region.SetShown then
        pcall(region.SetShown, region, shown and true or false)
    elseif shown and region.Show then
        pcall(region.Show, region)
    elseif region.Hide then
        pcall(region.Hide, region)
    end
end

local function SetStatusBarValue(bar, value)
    if not bar or (not IsSecret(value) and value == nil) then return end
    if IsSecret(value) or value ~= nil then
        pcall(bar.SetValue, bar, value)
    end
end

-- Shared separators belong to the cell on their right/below. Only owned
-- textures change; protected cell rectangles and native handlers remain intact.
function FluxRaid_RefreshJoinedBorders()
    if not FluxRaidVisuals.SetJoinedEdges then return end
    local overlap = FluxRaidVisuals.CELL_JOIN_OVERLAP or Compat.HEADER_UNIT_YOFFSET or 4
    local cells={}
    local function number(value) return not IsSecret(value) and type(value)=="number" end
    for frame in pairs(State.frameArray) do
        local visible=frame.IsVisible and frame:IsVisible()
        if not IsSecret(visible) and visible and frame.GetLeft and frame.unit and frame.unitExists~=false then
            local l,r,t,b=frame:GetLeft(),frame:GetRight(),frame:GetTop(),frame:GetBottom()
            if number(l) and number(r) and number(t) and number(b) then
                cells[#cells+1]={frame=frame,left=l,right=r,top=t,bottom=b}
            end
        end
    end
    for i,cell in ipairs(cells) do
        local below,right,above,left=false,false,false,false
        for j,other in ipairs(cells) do
            if i~=j then
                if math.abs(cell.left-other.left)<0.5 and math.abs(cell.right-other.right)<0.5
                    and math.abs(cell.bottom+overlap-other.top)<0.75 then below=true end
                if math.abs(cell.right-other.left)<0.75 and math.abs(cell.top-other.top)<0.75
                    and math.abs(cell.bottom-other.bottom)<0.75 then right=true end
                if math.abs(cell.left-other.left)<0.5 and math.abs(cell.right-other.right)<0.5
                    and math.abs(other.bottom+overlap-cell.top)<0.75 then above=true end
                if math.abs(other.right-cell.left)<0.75 and math.abs(cell.top-other.top)<0.75
                    and math.abs(cell.bottom-other.bottom)<0.75 then left=true end
            end
        end
        FluxRaidVisuals.SetJoinedEdges(cell.frame,{bottom=not below,right=not right,exteriorTop=not above,exteriorLeft=not left})
    end
end

function FluxRaid_RequestJoinedBorderRefresh()
    if not FluxRaidVisuals.SetJoinedEdges then return end
    local driver=State.joinedBorderDriver
    if not driver then driver=CreateFrame("Frame"); State.joinedBorderDriver=driver end
    if State.joinedBorderPending then return end
    State.joinedBorderPending=true
    driver:SetScript("OnUpdate",function(self)
        self:SetScript("OnUpdate",nil)
        State.joinedBorderPending=nil
        FluxRaid_RefreshJoinedBorders()
    end)
end

function FluxRaid_ShouldShowPowerBar(frame)
    if frame and frame._fluxRaidMini and not frame._fluxExtraPet then return false end
    if frame and frame._fluxExtraPet then return false end
    local opt = frame and frame.optionTable
    if opt and opt.displayPowerBar == false then
        return false
    end
    return not (frame and frame._fluxNoMainPower)
end

local function ApplyPowerVisibility(frame)
    local show = FluxRaid_ShouldShowPowerBar(frame)
    if frame.powerBar then
        ShowRegion(frame.powerBar, show)
    end
    local pbh = show and (FluxRaidVisuals.POWER_BAR_HEIGHT or 0) or 0
    if frame.powerBarUsedHeight ~= pbh and frame.healthBar then
        if InCombatLockdown and InCombatLockdown() then
            frame._fluxPowerLayoutPending = true
            if frame.RegisterEvent then frame:RegisterEvent("PLAYER_REGEN_ENABLED") end
            return
        end
        frame._fluxPowerLayoutPending = nil
        frame.powerBarUsedHeight = pbh
        FluxRaidVisuals.ApplyCellChrome(frame, { showPower = show,
            height = frame._fluxRaidMini and not frame._fluxExtraPet and (FluxRaidVisuals.MINI_FRAME_HEIGHT or Compat.MTMA_TARGET_HEIGHT or 18) or nil })
    end
end

local function ClassColor(unit)
    if not UnitClass then return nil end
    local ok, _, token = pcall(UnitClass, unit)
    if not ok or IsSecret(token) or type(token) ~= "string" then
        return nil
    end
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if not c then return nil end
    return c.r, c.g, c.b, token
end

function FluxRaid_UpdateHealth(frame)
    local bar = frame and frame.healthBar
    local unit = UnitOf(frame)
    if not bar or type(unit) ~= "string" or unit == "" then return end
    pcall(bar.SetMinMaxValues, bar, 0, 100)
    SetStatusBarValue(bar, Compat.GetHealthPercent(unit))

    local r, g, b = 0.2, 0.8, 0.2
    local useClass = frame.optionTable and frame.optionTable.useClassColors
    local connected = UnitIsConnected and UnitIsConnected(unit)
    local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)
    if not IsSecret(connected) and connected == false then
        r, g, b = 0.22, 0.22, 0.22
    elseif not IsSecret(dead) and dead then
        r, g, b = 0.22, 0.22, 0.22
    elseif useClass then
        local cr, cg, cb = ClassColor(unit)
        if cr then r, g, b = cr * 0.72, cg * 0.72, cb * 0.72 end
    end
    pcall(bar.SetStatusBarColor, bar, r, g, b)
end

function FluxRaid_UpdatePower(frame)
    local bar = frame and frame.powerBar
    if frame and frame._fluxRaidMini and not frame._fluxExtraPet then ApplyPowerVisibility(frame);return end
    local unit = UnitOf(frame)
    if not bar or type(unit) ~= "string" or unit == "" then return end
    local powerType, powerToken
    if UnitPowerType then
        local ok, pt, token = pcall(UnitPowerType, unit)
        if ok and not IsSecret(pt) then powerType = pt end
        if ok and not IsSecret(token) then powerToken = token end
    end
    -- A zero current value is still a valid resource. Unknown or secret maxima
    -- keep the bar visible because addon code cannot safely classify them.
    frame._fluxNoMainPower = false
    if UnitPowerMax then
        local ok, maximum = pcall(UnitPowerMax, unit, powerType)
        if ok then
            if not IsSecret(maximum) and type(maximum) == "number" then
                frame._fluxNoMainPower = maximum <= 0
            end
        end
    end
    ApplyPowerVisibility(frame)
    if not bar:IsShown() then return end
    pcall(bar.SetMinMaxValues, bar, 0, 100)
    if powerType or powerToken then
        if powerType == 0 or powerToken == "MANA" then
            bar:SetStatusBarColor(0.16, 0.33, 0.78)
        elseif powerToken and PowerBarColor and PowerBarColor[powerToken] then
            local c = PowerBarColor[powerToken]
            pcall(bar.SetStatusBarColor, bar, c.r * 0.72, c.g * 0.72, c.b * 0.72)
        elseif powerType and FluxRaidVisuals.POWER_COLORS and FluxRaidVisuals.POWER_COLORS[powerType] then
            local c = FluxRaidVisuals.POWER_COLORS[powerType]
            pcall(bar.SetStatusBarColor, bar, c.r * 0.72, c.g * 0.72, c.b * 0.72)
        end
    end
    local connected = UnitIsConnected and UnitIsConnected(unit)
    if not IsSecret(connected) and connected == false then
        pcall(bar.SetStatusBarColor, bar, 0.4, 0.4, 0.4)
    end
    SetStatusBarValue(bar, Compat.GetPowerPercent(unit, powerType))
    if FluxRaidPrediction and FluxRaidPrediction.UpdatePowerCost then FluxRaidPrediction.UpdatePowerCost(frame) end
end


function FluxRaid_UpdateHealPrediction(frame)
    if FluxRaidPrediction then FluxRaidPrediction.Update(frame) end
end


function FluxRaid_UpdateName(frame)
    local fs = frame and frame.name
    local unit = UnitOf(frame)
    if not fs or type(unit) ~= "string" or unit == "" then return end
    local name
    local playerName = ns.Flux and ns.Flux.PlayerName
    if playerName and playerName.GetDisplayName then
        name = playerName.GetDisplayName(unit)
    end
    if not IsSecret(name) and name == nil and GetUnitName then name = GetUnitName(unit, true) end
    if not IsSecret(name) and name == nil then name = "" end
    frame._fluxDisplayName = name
    local role = frame.optionTable and frame.optionTable.showRoleIcon ~= false and frame._fluxRole or nil
    if FluxRaidVisuals.SetUnitName then FluxRaidVisuals.SetUnitName(frame, name, role)
    else fs:SetText(name) end
    local r,g,b = 1,1,1
    local connected = UnitIsConnected and UnitIsConnected(unit)
    if not IsSecret(connected) and connected == false then r,g,b=.55,.55,.55
    elseif FluxRaid_ShouldClassColorNames and FluxRaid_ShouldClassColorNames() then
        local cr,cg,cb=ClassColor(unit)
        if cr then r,g,b=cr,cg,cb end
    end
    fs:SetTextColor(r,g,b)
end


function FluxRaid_UpdateStatusText(frame)
    local fs=frame and frame.statusText
    if not fs then return end
    local opt=frame.optionTable or {}
    local function formatted(format,...)
        if FluxRaidVisuals.SetUnitStatus then FluxRaidVisuals.SetUnitStatus(frame,format,...)
        else fs:SetFormattedText(format,...) end
    end
    local mode=opt._fluxHealthText or opt.healthText or "perc"
    if not (FluxRaidVisuals and FluxRaidVisuals.UseOwnRaidSettings and FluxRaidVisuals.UseOwnRaidSettings())
        and C_CVar and C_CVar.GetCVar then
        local cv=C_CVar.GetCVar("raidFramesHealthText")
        if type(cv)=="string" and cv~="" then mode=cv end
    end
    local unit=UnitOf(frame)
    if type(unit)~="string" or unit=="" then fs:Hide(); return end
    if frame._fluxRaidMini and not frame._fluxExtraPet then
        local percent=Compat.GetHealthPercent(unit)
        if not IsSecret(percent) and percent==nil then fs:Hide();return end
        formatted("%.0f%%",percent);fs:Show();return
    end
    local connected=UnitIsConnected and UnitIsConnected(unit)
    local dead=UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)
    if FluxRaidVisuals.SetHealthStatus then
        FluxRaidVisuals.SetHealthStatus(frame,mode,UnitHealth and UnitHealth(unit),UnitHealthMax and UnitHealthMax(unit),
            Compat.GetHealthPercent(unit),connected,dead)
        return
    end
    -- Dead/offline are independent of the health-number preference.
    if not IsSecret(connected) and connected==false then fs:SetText(PLAYER_OFFLINE or "Offline"); fs:Show(); return end
    if not IsSecret(dead) and dead then fs:SetText(DEAD or "Dead"); fs:Show(); return end
    if mode=="none" or opt.displayStatusText==false then fs:Hide(); return end
    local percent=Compat.GetHealthPercent(unit)
    if mode=="health" then
        local health=UnitHealth and UnitHealth(unit)
        if not IsSecret(health) and health==nil then fs:Hide(); return end
        fs:SetText(health)
    elseif mode=="healthandpercent" then
        local health=UnitHealth and UnitHealth(unit)
        if not IsSecret(percent) and percent==nil then fs:Hide(); return end
        if not IsSecret(health) and health==nil then formatted("%.0f%%",percent)
        else formatted("%s / %.0f%%",health,percent) end
    elseif mode=="losthealth" then
        local health=UnitHealth and UnitHealth(unit)
        local maximum=UnitHealthMax and UnitHealthMax(unit)
        if not IsSecret(health) and not IsSecret(maximum) and type(health)=="number" and type(maximum)=="number" then
            local lost=maximum-health
            if lost<=0 then fs:Hide(); return end
            formatted("-%s",lost)
        elseif IsSecret(percent) or percent~=nil then formatted("%.0f%%",percent)
        else fs:Hide(); return end
    elseif IsSecret(percent) or percent~=nil then formatted("%.0f%%",percent)
    else fs:Hide(); return end
    fs:Show()
end

function FluxRaid_UpdateSelectionHighlight(frame)
    local hl = frame and frame.selectionHighlight
    local unit = UnitOf(frame)
    if not hl or type(unit) ~= "string" or not UnitIsUnit then return end
    local opt = frame.optionTable
    if opt and opt.showTargetHighlight == false then
        ShowRegion(hl, false)
        return
    end
    local ok, isTarget = pcall(UnitIsUnit, unit, "target")
    if not ok or IsSecret(isTarget) then
        ShowRegion(hl, false)
        return
    end
    ShowRegion(hl, isTarget and true or false)
end

function FluxRaid_UpdateAggroHighlight(frame)
    local tex = frame and frame.aggroHighlight
    if not tex then return end
    local opt = frame.optionTable
    if opt and opt.showAggroHighlight == false then
        ShowRegion(tex, false)
        return
    end
    local unit = UnitOf(frame)
    if type(unit) ~= "string" or unit == "" then
        ShowRegion(tex, false)
        return
    end
    local status
    local ThreatAPI = ns.Flux and ns.Flux.Threat
    if ThreatAPI and ThreatAPI.GetSituation then
        status = ThreatAPI.GetSituation(unit)
    elseif UnitThreatSituation then
        local ok, v = pcall(UnitThreatSituation, unit)
        if ok then status = v end
    end
    if IsSecret(status) or status == nil then
        ShowRegion(tex, false)
        return
    end
    local statusN = ThreatAPI and ThreatAPI.AccessibleNumber and ThreatAPI.AccessibleNumber(status)
    if statusN == nil then
        if type(status) ~= "number" then
            ShowRegion(tex, false)
            return
        end
        statusN = status
    end
    if statusN <= 0 then
        ShowRegion(tex, false)
        return
    end
    local r, g, b = 1, 0, 0
    if statusN < 3 then r, g, b = 1, 1, 0.47 end
    pcall(tex.SetVertexColor, tex, r, g, b)
    ShowRegion(tex, true)
end


function FluxRaid_UpdateRoleIcon(frame)
    local unit=UnitOf(frame)
    frame._fluxRole=nil
    if type(unit)=="string" and UnitGroupRolesAssigned then
        local role=UnitGroupRolesAssigned(unit)
        if not IsSecret(role) and ROLE_ATLAS[role] then frame._fluxRole=role end
    end
    if frame.roleIcon then frame.roleIcon:Hide() end
    FluxRaid_UpdateName(frame)
    FluxRaid_UpdateStatusText(frame)
end

local function SetCenterTexture(frame, atlas, texPath)
    local icon = frame.centerStatusIcon
    local tex = icon and (icon.texture or icon)
    if not tex then return false end
    local ok = false
    if atlas and tex.SetAtlas then
        ok = pcall(tex.SetAtlas, tex, atlas)
    end
    if not ok and texPath and tex.SetTexture then
        ok = pcall(tex.SetTexture, tex, texPath)
    end
    ShowRegion(icon, ok and true or false)
    return ok
end

function FluxRaid_UpdateCenterStatus(frame)
    local unit = UnitOf(frame)
    if not frame or not frame.centerStatusIcon or type(unit) ~= "string" then return end
    -- Leader/raid markers are small independent corner indicators. A crown
    -- must never replace the resurrection/summon icon in the middle of a cell.
    if frame.leaderIcon then
        local leader=UnitIsGroupLeader and UnitIsGroupLeader(unit)
        local assist=UnitIsGroupAssistant and UnitIsGroupAssistant(unit)
        local isLeader=not IsSecret(leader) and leader==true
        local isAssist=not IsSecret(assist) and assist==true
        if isLeader or isAssist then
            frame.leaderIcon:SetTexture(isLeader and "Interface\\GroupFrame\\UI-Group-LeaderIcon" or "Interface\\GroupFrame\\UI-Group-AssistantIcon")
        end
        ShowRegion(frame.leaderIcon,isLeader or isAssist)
    end
    if frame.raidTargetIcon then
        local index=GetRaidTargetIndex and GetRaidTargetIndex(unit)
        local icon=frame.raidTargetIcon
        local opaque=IsSecret(index)
        local show=type(index)~="nil" and (opaque and icon.SetSpriteSheetCell~=nil
            or not opaque and type(index)=="number" and index>=1 and index<=8)
        if show then
            icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
            if icon.SetSpriteSheetCell then icon:SetSpriteSheetCell(index,4,4)
            elseif SetRaidTargetIconTexture then SetRaidTargetIconTexture(icon,index) end
        end
        ShowRegion(icon,show)
    end
    if frame.masterLooterIcon then
        local master
        local party=C_PartyInfo
        if party and party.GetLootMethod then
            local ok,_,partyID,raidID=pcall(party.GetLootMethod)
            if ok then
                if not IsSecret(raidID) and type(raidID)=="number" and raidID>0 then master="raid"..raidID
                elseif not IsSecret(partyID) and type(partyID)=="number" and partyID>=0 then
                    master=partyID==0 and "player" or "party"..partyID
                end
            end
        end
        local match=master and UnitIsUnit and UnitIsUnit(unit,master)
        local show=not IsSecret(match) and match==true
        if show then frame.masterLooterIcon:SetTexture("Interface\\GroupFrame\\UI-Group-MasterLooter") end
        ShowRegion(frame.masterLooterIcon,show)
    end
    if C_IncomingSummon and C_IncomingSummon.HasIncomingSummon then
        local ok,summon=pcall(C_IncomingSummon.HasIncomingSummon,unit)
        if ok and not IsSecret(summon) and summon then
            local status=C_IncomingSummon.IncomingSummonStatus(unit)
            if not IsSecret(status) then
                local atlases={[1]="RaidFrame-Icon-SummonPending",[2]="RaidFrame-Icon-SummonAccepted",[3]="RaidFrame-Icon-SummonDeclined"}
                if atlases[status] and SetCenterTexture(frame,atlases[status]) then return end
            end
        end
    end
    if UnitHasIncomingResurrection then
        local ok, inc = pcall(UnitHasIncomingResurrection, unit)
        if ok and not IsSecret(inc) and inc then
            if SetCenterTexture(frame, "Raid-Icon-Rez") then return end
        end
    end
    ShowRegion(frame.centerStatusIcon, false)
end

function FluxRaid_UpdateReadyCheck(frame)
    local icon = frame and frame.readyCheckIcon
    local unit = UnitOf(frame)
    if not icon then return end
    if type(unit) ~= "string" or not GetReadyCheckStatus then
        ShowRegion(icon, false)
        return
    end
    local ok, status = pcall(GetReadyCheckStatus, unit)
    if not ok or IsSecret(status) or status == nil then
        ShowRegion(icon, false)
        return
    end
    local tex = icon.texture or icon
    local path = (READY_CHECK_READY_TEXTURE or "Interface\\RaidFrame\\ReadyCheck-Ready")
    if status == "notready" then
        path = READY_CHECK_NOT_READY_TEXTURE or "Interface\\RaidFrame\\ReadyCheck-NotReady"
    elseif status == "waiting" then
        path = READY_CHECK_WAITING_TEXTURE or "Interface\\RaidFrame\\ReadyCheck-Waiting"
    end
    if tex and tex.SetTexture then
        pcall(tex.SetTexture, tex, path)
    end
    ShowRegion(icon, true)
end

function FluxRaid_UpdateRange(frame)
    if Compat.ApplyRangeAlpha then
        Compat.ApplyRangeAlpha(frame)
    end
end


function FluxRaid_UpdateAuras(frame)
    if FluxRaidAuras then FluxRaidAuras.Update(frame) end
    if FluxRaidHealerExtras then FluxRaidHealerExtras.Update(frame) end
    if FluxRaidHoTs then FluxRaidHoTs.Update(frame) end
end

function FluxRaid_UpdateDispelHighlight(frame)
    if FluxRaidAuras then FluxRaidAuras.UpdateDispel(frame) end
end

function FluxRaid_PaintUnit(frame)
    if not frame then return end
    local unit = UnitOf(frame)
    frame.unitExists = Compat.UnitTokenValid and Compat.UnitTokenValid(unit) or false
    if not frame.unitExists then
        if FluxRaidPrediction then FluxRaidPrediction.Clear(frame) end
        if FluxRaidAuras then FluxRaidAuras.Clear(frame) end
        if FluxRaidHealerExtras then FluxRaidHealerExtras.Clear(frame) end
        if FluxRaidHoTs then FluxRaidHoTs.Clear(frame) end
        if frame.name then frame.name:SetText("") end
        if frame.statusText then frame.statusText:Hide() end
        for _,key in ipairs({"aggroHighlight","selectionHighlight","mouseOverHighlight",
            "centerStatusIcon","readyCheckIcon","leaderIcon","raidTargetIcon","masterLooterIcon"}) do ShowRegion(frame[key],false) end
        return
    end
    FluxRaid_UpdateHealth(frame)
    FluxRaid_UpdatePower(frame)
    FluxRaid_UpdateSelectionHighlight(frame)
    FluxRaid_UpdateAggroHighlight(frame)
    FluxRaid_UpdateRoleIcon(frame)
    FluxRaid_UpdateCenterStatus(frame)
    FluxRaid_UpdateReadyCheck(frame)
    FluxRaid_UpdateHealPrediction(frame)
    FluxRaid_UpdateRange(frame)
    if not frame._fluxRaidMini then
        FluxRaid_UpdateAuras(frame)
        FluxRaid_UpdateDispelHighlight(frame)
        if FluxRaidFrame_BigDebuffs_TryUpdate then
            FluxRaidFrame_BigDebuffs_TryUpdate(frame)
        end
    end
end

_G.FluxRaid_UpdateAll = FluxRaid_PaintUnit
_G.FluxRaid_PaintUnit = FluxRaid_PaintUnit

local UNIT_EVENTS = {
    "UNIT_HEALTH",
    "UNIT_MAXHEALTH",
    "UNIT_POWER_UPDATE",
    "UNIT_MAXPOWER",
    "UNIT_DISPLAYPOWER",
    "UNIT_NAME_UPDATE",
    "UNIT_CONNECTION",
    "UNIT_FLAGS",
    "UNIT_AURA",
    "UNIT_THREAT_SITUATION_UPDATE",
    "UNIT_THREAT_LIST_UPDATE",
    "UNIT_HEAL_PREDICTION",
    "UNIT_ABSORB_AMOUNT_CHANGED",
    "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
    "UNIT_TARGET",
    "INCOMING_RESURRECT_CHANGED",
    "INCOMING_SUMMON_CHANGED",
    "UNIT_IN_RANGE_UPDATE",
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP",
}

local function RegisterUnitEvents(frame, unit)
    if not frame or not frame.RegisterUnitEvent or type(unit) ~= "string" or unit == "" then return end
    for i = 1, #UNIT_EVENTS do
        local ok=pcall(frame.RegisterUnitEvent, frame, UNIT_EVENTS[i], unit)
        if UNIT_EVENTS[i]=="UNIT_IN_RANGE_UPDATE" then frame._fluxRangeEventSupported=ok end
    end
    if frame._fluxPowerLayoutPending or frame._fluxNeedsChromeRefresh then frame:RegisterEvent("PLAYER_REGEN_ENABLED") end
end

local pendingPaint, paintDriver, paintArmed = {}, nil, false
local function ReleasePaintFlags(frame, dirty)
    if not dirty then return end
    for key in pairs(dirty) do dirty[key] = nil end
    -- Keep one spare per cell. A paint may synchronously queue another buffer;
    -- the buffer being painted never becomes available until that paint ends.
    if not frame._fluxPaintFlagsSpare then frame._fluxPaintFlagsSpare = dirty end
end

local function FlushPaint()
    paintArmed = false
    paintDriver:SetScript("OnUpdate", nil)
    for frame, dirty in pairs(pendingPaint) do
        pendingPaint[frame] = nil
        if frame.unit and (not frame.IsVisible or frame:IsVisible())
            and (not FluxRaid_IsFluxRaidEnabled or FluxRaid_IsFluxRaidEnabled()) then
            if dirty.full then FluxRaid_PaintUnit(frame)
            else
                if dirty.health then FluxRaid_UpdateHealth(frame); FluxRaid_UpdateStatusText(frame) end
                if dirty.prediction or dirty.health then FluxRaid_UpdateHealPrediction(frame) end
                if dirty.power then FluxRaid_UpdatePower(frame) end
                if dirty.aura then
                    FluxRaid_UpdateAuras(frame)
                    FluxRaid_UpdateDispelHighlight(frame)
                    if FluxRaidFrame_BigDebuffs_TryUpdate then FluxRaidFrame_BigDebuffs_TryUpdate(frame) end
                end
                if dirty.threat then FluxRaid_UpdateAggroHighlight(frame) end
                if dirty.range then FluxRaid_UpdateRange(frame) end
                if dirty.center then FluxRaid_UpdateCenterStatus(frame) end
            end
        end
        ReleasePaintFlags(frame, dirty)
    end
end

local function MarkPaint(frame, part)
    local dirty = pendingPaint[frame]
    if not dirty then
        dirty = frame._fluxPaintFlagsSpare or {}
        frame._fluxPaintFlagsSpare = nil
        pendingPaint[frame] = dirty
    end
    dirty[part]=true
    if not paintDriver then paintDriver=CreateFrame("Frame") end
    if not paintArmed then
        paintArmed = true
        paintDriver:SetScript("OnUpdate",FlushPaint)
    end
end

local function OnUnitEvent(self, event, arg1)
    if event == "PLAYER_REGEN_ENABLED" then
        if self.UnregisterEvent then self:UnregisterEvent("PLAYER_REGEN_ENABLED") end
        if self._fluxPowerLayoutPending then ApplyPowerVisibility(self) end
        if self._fluxNeedsChromeRefresh then FluxRaidVisuals.ApplyCellChrome(self) end
        return
    end
    if event == "UNIT_TARGET" and self._fluxRaidUnit and not self._fluxRaidMini then
        if FluxRaid_AttachOrUpdateMTMATarget then
            FluxRaid_AttachOrUpdateMTMATarget(self, UnitOf(self))
        end
    end
    if not IsSecret(arg1) and type(arg1) == "string" and arg1 ~= "" and arg1 ~= self.unit and arg1 ~= self.displayedUnit then
        if event ~= "UNIT_TARGET" then
            return
        end
    end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        MarkPaint(self,"health")
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        MarkPaint(self,"power")
    elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_CONNECTION" or event == "UNIT_FLAGS" then
        MarkPaint(self,"full")
    elseif event == "UNIT_AURA" then
        MarkPaint(self,"aura")
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then
        MarkPaint(self,"threat")
    elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        MarkPaint(self,"prediction")
    elseif event == "UNIT_IN_RANGE_UPDATE" then
        MarkPaint(self,"range")
    elseif event == "INCOMING_RESURRECT_CHANGED" or event == "INCOMING_SUMMON_CHANGED" then
        MarkPaint(self,"center")
    elseif event == "UNIT_TARGET" and self._fluxRaidMini then
        MarkPaint(self,"full")
    elseif event:find("^UNIT_SPELLCAST") then
        MarkPaint(self,"power")
    end
end

function FluxRaid_BindUnit(frame, unit)
    if not frame then return end
    if unit == "" then unit = nil end
    local discarded = pendingPaint[frame]
    pendingPaint[frame]=nil
    ReleasePaintFlags(frame, discarded)
    if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
    frame.unit = unit
    frame.displayedUnit = unit
    if unit then
        RegisterUnitEvents(frame, unit)
        if frame._fluxRaidMini and not frame._fluxSecureTargetAttached and unit and not (InCombatLockdown and InCombatLockdown()) then
            pcall(frame.SetAttribute, frame, "unit", unit)
        end
        FluxRaid_PaintUnit(frame)
    else
        if frame.UnregisterAllEvents then
            pcall(frame.UnregisterAllEvents, frame)
        end
        frame.unitExists = false
        if frame.name then frame.name:SetText("") end
        if frame.statusText then frame.statusText:Hide() end
        if FluxRaidAuras then FluxRaidAuras.Clear(frame) end
        if FluxRaidPrediction then FluxRaidPrediction.Clear(frame) end
        if FluxRaidHealerExtras then FluxRaidHealerExtras.Clear(frame) end
        if FluxRaidHoTs then FluxRaidHoTs.Clear(frame) end
    end
    State.frameArray[frame] = frame
    FluxRaid_RequestJoinedBorderRefresh()
    if EnsureRangePoll then EnsureRangePoll(frame) end
end

function FluxRaid_OnUnitAttributeChanged(self, name, value)
    if name ~= "unit" then return end
    if value == self.unit then return end
    FluxRaid_BindUnit(self, value)
    if FluxRaid_IsMTMAChild and FluxRaid_IsMTMAChild(self) then
        FluxRaid_AttachOrUpdateMTMATarget(self, value)
    elseif self._fluxMTMATarget then
        FluxRaid_AttachOrUpdateMTMATarget(self, value)
    end
end

function FluxRaidUnit_OnLoad(self)
    self._fluxRaidUnit = true
    self:RegisterForClicks("AnyUp")
    if not InCombatLockdown() then
        if not self:GetAttribute("*type1") then
            self:SetAttribute("*type1", "target")
        end
        if ns.UnitFrames and ns.UnitFrames.ConfigureUnitMenu then ns.UnitFrames.ConfigureUnitMenu(self)
        elseif not self:GetAttribute("type2") then self:SetAttribute("type2", "togglemenu") end
        pcall(self.SetSize, self, FluxRaidVisuals.FRAME_WIDTH, FluxRaidVisuals.FRAME_HEIGHT)
    end
    if self.centerStatusIcon then
        self.centerStatusIcon:EnableMouse(false)
        if self.centerStatusIcon.SetPropagateMouseClicks then
            pcall(self.centerStatusIcon.SetPropagateMouseClicks, self.centerStatusIcon, true)
        end
    end
    self.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
    FluxRaidVisuals.ApplyCellChrome(self, { showPower = FluxRaid_ShouldShowPowerBar(self) })
    if FluxRaidPrediction then FluxRaidPrediction.Setup(self) end
    if FluxRaidHealerExtras then FluxRaidHealerExtras.Setup(self) end
    if FluxRaidHoTs then FluxRaidHoTs.Setup(self) end
    FluxRaidVisuals.ConfigurePrivateAuras(self)
    if not self._fluxAttrHooked and self.HookScript then
        self._fluxAttrHooked = true
        self:HookScript("OnAttributeChanged", FluxRaid_OnUnitAttributeChanged)
        self:SetScript("OnEvent", OnUnitEvent)
    end
    if ClickCastFrames then
        ClickCastFrames[self] = true
    end
    local kb = ns and ns.FluxMouseoverKeybind
    if kb and kb.RegisterFrame then
        kb:RegisterFrame(self)
    end
    State.frameArray[self] = self
    if self.IsVisible and self:IsVisible() then EnsureRangePoll(self) end
end

function FluxRaidUnit_OnShow(self)
    if self._fluxRaidMini and self._fluxWrap then self._fluxWrap:SetAlpha(1) end
    local unit = self:GetAttribute("unit") or self.unit
    if unit then RegisterUnitEvents(self,unit) end
    EnsureRangePoll(self)
    FluxRaid_RequestJoinedBorderRefresh()
    if unit and unit ~= self.unit then
        FluxRaid_BindUnit(self, unit)
    else
        FluxRaid_PaintUnit(self)
    end
end

function FluxRaidUnit_OnHide(self)
    pendingPaint[self]=nil
    if self.UnregisterAllEvents then self:UnregisterAllEvents() end
    ShowRegion(self.aggroHighlight, false)
    ShowRegion(self.mouseOverHighlight, false)
    if FluxRaidAuras then FluxRaidAuras.Clear(self) end
    if FluxRaidPrediction then FluxRaidPrediction.Clear(self) end
    if FluxRaidHealerExtras then FluxRaidHealerExtras.Clear(self) end
    if FluxRaidHoTs then FluxRaidHoTs.Clear(self) end
    self.UpdateTooltip=nil
    local uf = ns.UnitFrames
    if uf and uf.HideUnitTooltip then uf.HideUnitTooltip(self) end
    EnsureRangePoll()
    FluxRaid_RequestJoinedBorderRefresh()
end

-- Flux-owned tooltip. Blizzard's UnitFrame_UpdateTooltip throws on a nil unit
-- (unbound header children); replacing that global would taint every unit frame.
local function FluxRaidUnit_UpdateTooltip(self)
    local unit = self.unit
    local uf = ns.UnitFrames
    if IsSecret(unit) or type(unit) ~= "string" or unit == "" then
        self.UpdateTooltip = nil
        if uf and uf.HideUnitTooltip then uf.HideUnitTooltip(self) end
        return
    end
    local tooltip = uf and uf.GetUnitTooltip and uf.GetUnitTooltip(true)
    if not tooltip or tooltip:IsForbidden() then self.UpdateTooltip = nil; return end
    -- UIParent ownership avoids retaining an addon callback on a secure cell;
    -- the tooltip's own update callback keeps the existing native cadence.
    tooltip._fluxUnitTipRebuilding = true
    GameTooltip_SetDefaultAnchor(tooltip, UIParent)
    tooltip._fluxUnitTipOwner = self
    if tooltip:SetUnit(unit, self.hideStatusOnTooltip) then
        if GameTooltip_AddBlankLineToTooltip and GameTooltip_AddInstructionLine and UNIT_POPUP_RIGHT_CLICK then
            GameTooltip_AddBlankLineToTooltip(tooltip)
            GameTooltip_AddInstructionLine(tooltip, UNIT_POPUP_RIGHT_CLICK)
        end
        tooltip:Show()
        if ns.ApplyHUDTooltipPosition then ns.ApplyHUDTooltipPosition(tooltip) end
        self.UpdateTooltip = FluxRaidUnit_UpdateTooltip
        tooltip.UpdateTooltip = function()
            if (self.IsShown and not self:IsShown()) or (self.IsMouseOver and not self:IsMouseOver()) then
                self.UpdateTooltip = nil
                if uf.HideUnitTooltip then uf.HideUnitTooltip(self) end
                return
            end
            FluxRaidUnit_UpdateTooltip(self)
        end
    else
        self.UpdateTooltip = nil
        tooltip.UpdateTooltip = nil
    end
    tooltip._fluxUnitTipRebuilding = nil
end

function FluxRaidUnit_OnEnter(self)
    FluxRaidUnit_UpdateTooltip(self)
    local opt = self.optionTable
    if not opt or opt.showMouseoverHighlight ~= false then
        ShowRegion(self.mouseOverHighlight, true)
    end
end

function FluxRaidUnit_OnLeave(self)
    self.UpdateTooltip = nil
    local uf = ns.UnitFrames
    local tooltip = uf and uf.GetUnitTooltip and uf.GetUnitTooltip(false)
    if tooltip and not tooltip:IsForbidden() and tooltip._fluxUnitTipOwner == self then
        tooltip.UpdateTooltip = nil
        if tooltip.FadeOut then tooltip:FadeOut() else tooltip:Hide() end
    end
    ShowRegion(self.mouseOverHighlight, false)
end

function ns.FluxRaidRegisterAllMouseoverKeybindFrames()
    local kb = ns and ns.FluxMouseoverKeybind
    if not kb or not kb.RegisterFrame then return end
    for frame in pairs(State.frameArray) do
        if frame and frame.RegisterForClicks and not (frame.IsForbidden and frame:IsForbidden()) then
            kb:RegisterFrame(frame)
        end
    end
end

function FluxRaid_ForEachHeaderChild(fn)
    if not fn then return end
    local headers = {}
    local groupCount = Compat.GROUP_COUNT or 8
    for i = 1, groupCount do
        local h = State.raidHeaders[i]
        if h then headers[#headers + 1] = h end
    end
    if State.mtmaHeader then headers[#headers + 1] = State.mtmaHeader end
    local seen = {}
    for _, header in ipairs(headers) do
        for ci = 1, 40 do
            local btn = header:GetAttribute("child" .. ci)
            if not btn then break end
            if not seen[btn] then
                seen[btn] = true
                fn(btn)
            end
            if btn._fluxMTMATarget then
                fn(btn._fluxMTMATarget)
            end
        end
    end
end

function FluxRaid_SyncHeaderChildUnits()
    FluxRaid_ForEachHeaderChild(function(btn)
        if btn._fluxRaidMini then return end
        local unit = btn:GetAttribute("unit")
        if unit ~= btn.unit then
            FluxRaid_BindUnit(btn, unit)
        elseif unit then
            MarkPaint(btn,"full")
        end
    end)
    FluxRaid_RequestJoinedBorderRefresh()
end

function FluxRaid_ApplyChromeToChildren(avoidRebuild)
    FluxRaid_ForEachHeaderChild(function(btn)
        if btn._fluxRaidMini then
            if FluxCompactMiniFrameSetup then
                FluxCompactMiniFrameSetup(btn)
            end
            return
        end
        btn.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
        if FluxRaidVisuals.SafeSetUnitFrameSize then
            FluxRaidVisuals.SafeSetUnitFrameSize(btn, FluxRaidVisuals.FRAME_WIDTH, FluxRaidVisuals.FRAME_HEIGHT)
        end
        FluxRaidVisuals.ApplyCellChrome(btn, { showPower = FluxRaid_ShouldShowPowerBar(btn) })
        if FluxRaidPrediction then FluxRaidPrediction.Setup(btn) end
        FluxRaidVisuals.PushAuraDisplayToFrame(btn)
        if avoidRebuild and btn._fluxPrivateAuraMixed then
            FluxRaidVisuals.SyncPrivateAuraSettings(btn, false, true)
        end
        if btn.unit then
            FluxRaid_PaintUnit(btn)
        end
    end)
end

function FluxRaid_SyncAllFluxUnitAuraSettings()
    FluxRaid_ForEachHeaderChild(function(btn)
        if btn and btn._fluxRaidUnit and not btn._fluxRaidMini then
            FluxRaidVisuals.PushAuraDisplayToFrame(btn)
        end
    end)
end

function FluxRaid_RefreshVisibleUnits(which)
    FluxRaid_ForEachHeaderChild(function(btn)
        if not btn.unit then return end
        if which == "target" then
            FluxRaid_UpdateSelectionHighlight(btn)
            FluxRaid_UpdateName(btn)
        elseif which == "role" then
            FluxRaid_UpdateRoleIcon(btn)
            FluxRaid_UpdatePower(btn)
        elseif which == "ready" then
            FluxRaid_UpdateReadyCheck(btn)
        elseif which == "raidtarget" then
            FluxRaid_UpdateCenterStatus(btn)
        else
            FluxRaid_PaintUnit(btn)
        end
    end)
end

function FluxRaid_RefreshSelfDisplayNames()
    FluxRaid_ForEachHeaderChild(function(frame)
        local unit = frame and (frame.unit or frame.displayedUnit)
        if type(unit) ~= "string" or not UnitIsUnit then return end
        local ok, isMe = pcall(UnitIsUnit, unit, "player")
        if ok and not IsSecret(isMe) and isMe then
            FluxRaid_UpdateName(frame)
        end
    end)
end

EnsureRangePoll = function(frame)
    local function NeedsPoll(btn)
        return btn and btn.unit and btn._fluxRangeEventSupported==false
            and btn.IsVisible and btn:IsVisible()
            and (not FluxRaid_IsFluxRaidEnabled or FluxRaid_IsFluxRaidEnabled())
    end
    local function PollSet(frames, paint)
        local any=false
        for btn in pairs(frames or {}) do
            if NeedsPoll(btn) then
                any=true
                if paint then FluxRaid_UpdateRange(btn) end
            end
        end
        return any
    end
    local active=NeedsPoll(frame)
    if not active then active=PollSet(State.frameArray,false) or PollSet(State.partyRangeFrames,false) end
    if not active then
        if rangePollTicker then rangePollTicker:Cancel(); rangePollTicker=nil end
        return
    end
    if rangePollTicker or not C_Timer or not C_Timer.NewTicker then return end
    rangePollTicker = C_Timer.NewTicker(0.25, function()
        local any=PollSet(State.frameArray,true)
        if PollSet(State.partyRangeFrames,true) then any=true end
        if not any and rangePollTicker then
            rangePollTicker:Cancel()
            rangePollTicker = nil
        end
    end)
end

function FluxRaid_EnsureRangePoll()
    EnsureRangePoll()
end

-- MT/MA target minis: insecure wrap on the container, secure button for clicks.
-- Unit token is tankUnit.."target" (set out of combat). UNIT_TARGET repaints. No OnUpdate.

local mtmaNameCounter = 0

function FluxRaid_IsMTMAChild(btn)
    if not btn then return false end
    local parent = btn.GetParent and btn:GetParent()
    if parent and parent == State.mtmaHeader then return true end
    local n = btn.GetName and btn:GetName()
    if n and string.match(n, "^FluxRaidMTMA") and not string.match(n, "Target") then
        return parent == State.mtmaHeader
    end
    return false
end

local function MiniAlpha(tf)
    if tf._fluxSecureTargetAttached then
        -- The native target-existence state owns actual button visibility.
        -- An alpha-zero wrapper must not survive a later secure reappearance.
        if tf._fluxWrap then tf._fluxWrap:SetAlpha(1) end
        return
    end
    local unit = UnitOf(tf)
    local exists = Compat.UnitTokenValid and Compat.UnitTokenValid(unit)
    local alpha = exists and 1 or 0
    local wrap = tf._fluxWrap or tf
    local alphaApplied = false
    if wrap.SetAlphaFromBoolean and UnitExists and type(unit) == "string" then
        local ok, ex = pcall(UnitExists, unit)
        if ok then
            alphaApplied = pcall(wrap.SetAlphaFromBoolean, wrap, ex, 1, 0)
        end
    end
    if not alphaApplied and wrap.SetAlpha then
        wrap:SetAlpha(alpha)
    end
    if tf.EnableMouse and not (InCombatLockdown and InCombatLockdown()) then
        pcall(tf.EnableMouse, tf, alpha > 0)
    end
end

function FluxCompactMiniFrameSetup(frame)
    if not frame then return end
    frame._fluxRaidMini = true
    -- Target wrappers and secure MT/MA spacing use the active sizing policy.
    local miniH = FluxRaidVisuals.MINI_FRAME_HEIGHT or Compat.MTMA_TARGET_HEIGHT or 18
    FluxRaidVisuals.ApplyCellChrome(frame, {
        width = FluxRaidVisuals.FRAME_WIDTH,
        height = miniH,
        showPower = false,
    })
    if not (InCombatLockdown and InCombatLockdown()) then
        local wrap, owner = frame._fluxWrap, frame._fluxMTMAOwner
        if wrap and owner then
            local gap = FluxRaidVisuals.CELL_JOIN_OVERLAP and -FluxRaidVisuals.CELL_JOIN_OVERLAP or (Compat.MTMA_TARGET_GAP or -4)
            wrap:SetSize(FluxRaidVisuals.FRAME_WIDTH, miniH)
            wrap:ClearAllPoints()
            wrap:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -gap)
            wrap:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -gap)
        end
        pcall(frame.SetSize, frame, FluxRaidVisuals.FRAME_WIDTH, miniH)
    end
    frame.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
end

local function CreateMTMATarget(parentBtn)
    local container = State.containerFrame
    local wrap = CreateFrame("Frame", nil, container or parentBtn)
    local h = FluxRaidVisuals.MINI_FRAME_HEIGHT or Compat.MTMA_TARGET_HEIGHT or 18
    local gap = FluxRaidVisuals.CELL_JOIN_OVERLAP and -FluxRaidVisuals.CELL_JOIN_OVERLAP or (Compat.MTMA_TARGET_GAP or -4)
    wrap:SetSize(FluxRaidVisuals.FRAME_WIDTH, h)
    wrap:SetPoint("TOPLEFT", parentBtn, "BOTTOMLEFT", 0, -gap)
    wrap:SetPoint("TOPRIGHT", parentBtn, "BOTTOMRIGHT", 0, -gap)
    wrap:SetAlpha(0)
    mtmaNameCounter = mtmaNameCounter + 1
    local tf = CreateFrame("Button", "FluxRaidMTMATarget" .. mtmaNameCounter, wrap, "FluxRaidMiniUnitTemplate")
    tf:SetAllPoints(wrap)
    tf._fluxWrap = wrap
    tf._fluxMTMAOwner = parentBtn
    tf._fluxRaidMini = true
    tf._fluxRaidUnit = true
    if not InCombatLockdown() then
        tf:SetAttribute("*type1", "target")
        if ns.UnitFrames and ns.UnitFrames.ConfigureUnitMenu then ns.UnitFrames.ConfigureUnitMenu(tf)
        else tf:SetAttribute("type2", "togglemenu") end
        tf:RegisterForClicks("AnyUp")
    end
    FluxCompactMiniFrameSetup(tf)
    tf:SetScript("OnEvent", OnUnitEvent)
    if ClickCastFrames then
        ClickCastFrames[tf] = true
    end
    local kb=ns and ns.FluxMouseoverKeybind
    if kb and kb.RegisterFrame then kb:RegisterFrame(tf) end
    if FluxRaidPrediction then FluxRaidPrediction.Setup(tf) end
    tf:SetScript("OnEnter", FluxRaidUnit_OnEnter)
    tf:SetScript("OnLeave", FluxRaidUnit_OnLeave)
    tf:SetScript("OnHide", FluxRaidUnit_OnHide)
    tf:SetScript("OnShow", FluxRaidUnit_OnShow)
    if tf.HookScript and not tf._fluxAttrHooked then
        tf._fluxAttrHooked=true
        tf:HookScript("OnAttributeChanged",FluxRaid_OnUnitAttributeChanged)
    end
    parentBtn._fluxMTMATarget = tf
    State.frameArray[tf] = tf
    if FluxRaidSecure then FluxRaidSecure.AttachTarget(parentBtn,tf) end
    return tf
end

function FluxRaid_AttachOrUpdateMTMATarget(btn, unit)
    if not btn or btn._fluxRaidMini then return end
    if not FluxRaid_IsMTMAChild(btn) then
        if btn._fluxMTMATarget then
            MiniAlpha(btn._fluxMTMATarget)
        end
        return
    end
    local tf = btn._fluxMTMATarget
    if not tf then
        if InCombatLockdown and InCombatLockdown() then
            btn._fluxNeedsMTMA = true
            if FluxRaid_QueueConfigureAndRefresh then
                FluxRaid_QueueConfigureAndRefresh()
            end
            return
        end
        tf = CreateMTMATarget(btn)
    end
    if tf._fluxSecureTargetUnsupported then return end
    if tf._fluxSecureTargetAttached then
        local token=tf:GetAttribute("unit")
        if token~=tf.unit then FluxRaid_BindUnit(tf,token) end
        if token then MiniAlpha(tf) end
        return
    end
    local token = (type(unit) == "string" and unit ~= "") and (unit .. "target") or nil
    if token ~= tf.unit then
        if InCombatLockdown and InCombatLockdown() then
            tf._fluxPendingUnit = token
            if FluxRaid_QueueConfigureAndRefresh then
                FluxRaid_QueueConfigureAndRefresh()
            end
        else
            FluxRaid_BindUnit(tf, token)
        end
    else
        FluxRaid_PaintUnit(tf)
    end
    MiniAlpha(tf)
end

function FluxRaid_RefreshMTMATargetAttachments()
    FluxRaid_ForEachHeaderChild(function(btn)
        if FluxRaid_IsMTMAChild(btn) then
            local pending = btn._fluxMTMATarget and btn._fluxMTMATarget._fluxPendingUnit
            if pending and not (InCombatLockdown and InCombatLockdown()) then
                FluxRaid_BindUnit(btn._fluxMTMATarget, pending)
                btn._fluxMTMATarget._fluxPendingUnit = nil
            end
            FluxRaid_AttachOrUpdateMTMATarget(btn, btn.unit)
        end
    end)
end

_G.FluxCompactMiniFrameSetup = FluxCompactMiniFrameSetup
_G.FluxCompactUnitFrameSetup = function(frame, avoid)
    if not frame then return end
    if frame._fluxRaidMini then
        FluxCompactMiniFrameSetup(frame)
        return
    end
    frame.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
    FluxRaidVisuals.ApplyCellChrome(frame, { showPower = FluxRaid_ShouldShowPowerBar(frame) })
    FluxRaidVisuals.PushAuraDisplayToFrame(frame)
    if frame._fluxPrivateAuraMixed then
        FluxRaidVisuals.SyncPrivateAuraSettings(frame, false, avoid ~= false)
    end
    if frame.unit then
        FluxRaid_PaintUnit(frame)
    end
end

_G.FluxRaid_UpdateStatusText = FluxRaid_UpdateStatusText
_G.FluxRaid_UpdateDispelHighlight = FluxRaid_UpdateDispelHighlight
_G.FluxRaid_SyncAllFluxUnitAuraSettings = FluxRaid_SyncAllFluxUnitAuraSettings
_G.FluxRaid_RefreshSelfDisplayNames = FluxRaid_RefreshSelfDisplayNames
