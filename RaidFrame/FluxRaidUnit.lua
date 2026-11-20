local addonName, ns = ...

-- Flux-owned raid unit buttons: event paint, secret-safe bars, auras, MT/MA minis.
-- Does not call CompactUnitFrame_Update* / SetUnit / OnUpdate.

local Compat = FluxRaidCompat
local State = FluxRaidState
local pairs, ipairs, type, pcall, tostring = pairs, ipairs, type, pcall, tostring
local max, floor, abs, huge = math.max, math.floor, math.abs, math.huge
local sort = table.sort

local DISPEL_TYPES = { Magic = true, Curse = true, Disease = true, Poison = true, Bleed = true }
local ROLE_ATLAS = {
    TANK = "roleicon-tiny-tank",
    HEALER = "roleicon-tiny-healer",
    DAMAGER = "roleicon-tiny-dps",
}

local rangePollTicker = nil
local rangeDiscoveryPending = false
local EnsureRangePoll

local function IsSecret(v)
    return Compat.IsSecret and Compat.IsSecret(v)
end

local function RegisterUnitRegen(frame)
    frame._fluxClearedUnitEvents = nil
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function UnitOf(frame)
    return frame and (frame.displayedUnit or frame.unit)
end

local function ShowRegion(region, shown)
    if not region then return end
    shown = not not shown
    if region.IsShown then
        local ok, current = pcall(region.IsShown, region)
        if ok and not IsSecret(current) and current == shown then return end
    end
    if region.SetShown then
        pcall(region.SetShown, region, shown)
    elseif shown and region.Show then
        pcall(region.Show, region)
    elseif region.Hide then
        pcall(region.Hide, region)
    end
end

local function EnsurePercentRange(bar)
    if bar.GetMinMaxValues then
        local ok, minimum, maximum = pcall(bar.GetMinMaxValues, bar)
        if ok and not IsSecret(minimum) and not IsSecret(maximum) and minimum == 0 and maximum == 100 then return end
    end
    pcall(bar.SetMinMaxValues, bar, 0, 100)
end

local function SetStatusBarValue(bar, value)
    if not bar or (not IsSecret(value) and value == nil) then return end
    if IsSecret(value) or value ~= nil then
        pcall(bar.SetValue, bar, value)
    end
end

-- Shared separators belong to the cell on their right/below. Only owned
-- textures change; protected cell rectangles and native handlers remain intact.
local joinedLayout, joinedCount, joinedOverlap = {}, nil, nil
local function ByLeft(a, b) return a.left < b.left end
local function ByTop(a, b) return a.top < b.top end

local function UpdateVerticalNeighbors(cell, other, overlap, change)
    if abs(cell.right - other.right) >= 0.5 then return end
    if abs(cell.bottom + overlap - other.top) < 0.75 then
        cell.below, other.above = cell.below + change, other.above + change
    end
    if abs(other.bottom + overlap - cell.top) < 0.75 then
        cell.above, other.below = cell.above + change, other.below + change
    end
end

local function UpdateHorizontalNeighbors(cell, other, change)
    if abs(cell.bottom - other.bottom) >= 0.75 then return end
    if abs(cell.right - other.left) < 0.75 then
        cell.rightNeighbor, other.leftNeighbor = cell.rightNeighbor + change, other.leftNeighbor + change
    end
    if abs(other.right - cell.left) < 0.75 then
        cell.leftNeighbor, other.rightNeighbor = cell.leftNeighbor + change, other.rightNeighbor + change
    end
end

local function ResetJoinCounts(cell)
    cell.below, cell.above, cell.rightNeighbor, cell.leftNeighbor = 0, 0, 0, 0
end

local function FractionalCoordinate(value)
    -- Keep small fractions exact on both sides of zero. Only shift a
    -- remainder by one when its magnitude is at least one half.
    local fraction = value < 0 and -(-value % 1) or value % 1
    if fraction > 0.5 then return fraction - 1 end
    if fraction <= -0.5 then return fraction + 1 end
    return fraction
end

local function JoinAlignedCells(cells, overlap)
    local first = cells[1]
    if not first then return true end
    local xFraction = FractionalCoordinate(first.left)
    local yFraction = FractionalCoordinate(first.top)
    for _, cell in ipairs(cells) do
        local below = cell.bottom + overlap
        -- If every coordinate differs by whole UI units on its axis, the
        -- original sub-unit tolerances can only match equal coordinates.
        if FractionalCoordinate(cell.left) ~= xFraction or FractionalCoordinate(cell.right) ~= xFraction
            or FractionalCoordinate(cell.top) ~= yFraction or FractionalCoordinate(cell.bottom) ~= yFraction
            or FractionalCoordinate(below) ~= yFraction then return false end
    end
    local columns = {}
    for _, cell in ipairs(cells) do
        local column = columns[cell.left]
        if not column then column = {}; columns[cell.left] = column end
        if column[cell.top] then return false end
        column[cell.top] = cell
    end
    for _, cell in ipairs(cells) do ResetJoinCounts(cell) end
    for _, cell in ipairs(cells) do
        local lower = columns[cell.left][cell.bottom + overlap]
        if lower and lower ~= cell and lower.right == cell.right then
            cell.below, lower.above = cell.below + 1, lower.above + 1
        end
        local column = columns[cell.right]
        local right = column and column[cell.top]
        if right and right ~= cell and right.bottom == cell.bottom then
            cell.rightNeighbor, right.leftNeighbor = cell.rightNeighbor + 1, right.leftNeighbor + 1
        end
    end
    return true
end

local function JoinRaidCells(cells, overlap)
    if JoinAlignedCells(cells, overlap) then return end
    for _, cell in ipairs(cells) do ResetJoinCounts(cell) end
    -- A vertical seam can only join matching column bounds. Once the left
    -- edges differ by the tolerance, every later cell is outside that column.
    sort(cells, ByLeft)
    for i, cell in ipairs(cells) do
        for j = i + 1, #cells do
            local other = cells[j]
            if other.left - cell.left >= 0.5 then break end
            UpdateVerticalNeighbors(cell, other, overlap, 1)
        end
    end
    sort(cells, ByTop)
    for i, cell in ipairs(cells) do
        for j = i + 1, #cells do
            local other = cells[j]
            if other.top - cell.top >= 0.75 then break end
            UpdateHorizontalNeighbors(cell, other, 1)
        end
    end
end

local function UpdateNeighbors(cell, other, overlap, change)
    if abs(other.left - cell.left) < 0.5 then UpdateVerticalNeighbors(cell, other, overlap, change) end
    if abs(other.top - cell.top) < 0.75 then UpdateHorizontalNeighbors(cell, other, change) end
end

local function UpdateJoinedEdges(cell)
    local bottom, right = cell.below == 0, cell.rightNeighbor == 0
    local top, left = cell.above == 0, cell.leftNeighbor == 0
    local edges = cell.edges
    if not edges or bottom ~= edges.bottom or right ~= edges.right or top ~= edges.exteriorTop or left ~= edges.exteriorLeft then
        cell.edges = { bottom = bottom, right = right, exteriorTop = top, exteriorLeft = left }
    end
end

local function PublicCoordinate(value)
    return not IsSecret(value) and type(value) == "number" and value > -huge and value < huge
end

local function MatchesJoinedBounds(frame, cell)
    if not cell then return false end
    local getRect = frame.GetRect
    if IsSecret(getRect) or type(getRect) ~= "function" then return false end
    local left, bottom, width, height = getRect(frame)
    -- A single rectangle can confirm a retained cell. New or moved cells
    -- still use the exact native edges for the join tolerances.
    return not IsSecret(left) and left == cell.left
        and not IsSecret(bottom) and bottom == cell.bottom
        and not IsSecret(width) and type(width) == "number" and left + width == cell.right
        and not IsSecret(height) and type(height) == "number" and bottom + height == cell.top
end

function FluxRaid_RefreshJoinedBorders()
    if not FluxRaidVisuals.SetJoinedEdges then return end
    local overlap = FluxRaidVisuals.CELL_JOIN_OVERLAP or Compat.HEADER_UNIT_YOFFSET or 4
    local cells,current={},{}
    local entering
    local rebuild=overlap~=joinedOverlap
    for frame in pairs(State.frameArray) do
        local unit=frame.unit
        if frame.unitExists~=false and not IsSecret(unit) and unit and frame.GetLeft then
            local visible=frame.IsVisible and frame:IsVisible()
            if not IsSecret(visible) and visible then
                local cell=joinedLayout[frame]
                if not MatchesJoinedBounds(frame, cell) then
                    local l,r,t,b=frame:GetLeft(),frame:GetRight(),frame:GetTop(),frame:GetBottom()
                    if PublicCoordinate(l) and PublicCoordinate(r) and PublicCoordinate(t) and PublicCoordinate(b) then
                        if not cell or cell.left~=l or cell.right~=r or cell.top~=t or cell.bottom~=b then
                            cell={frame=frame,left=l,right=r,top=t,bottom=b}
                            if entering then rebuild=true else entering=cell end
                        end
                    else
                        cell=nil
                    end
                end
                if cell then
                    cells[#cells+1]=cell;current[frame]=cell
                end
            end
        end
    end
    if rebuild or entering or #cells~=joinedCount then
        local leaving
        if not rebuild then
            for frame,cell in pairs(joinedLayout) do
                if current[frame]~=cell then
                    if leaving then rebuild=true;break end
                    leaving=cell
                end
            end
        end
        if rebuild then
            JoinRaidCells(cells, overlap)
        else
            -- Retain counts for pairs of unchanged cells. Multiple neighbours
            -- can cover the same seam, so losing one cannot expose it early.
            if entering then ResetJoinCounts(entering) end
            for _,cell in ipairs(cells) do
                if cell~=entering then
                    if leaving then UpdateNeighbors(leaving,cell,overlap,-1) end
                    if entering then UpdateNeighbors(entering,cell,overlap,1) end
                end
            end
        end
        for _,cell in ipairs(cells) do UpdateJoinedEdges(cell) end
    end
    -- Publish counts before native paint so a later retry cannot apply the
    -- same join or leave twice if a paint sink raises.
    joinedLayout, joinedCount, joinedOverlap = current, #cells, overlap
    for _,cell in ipairs(cells) do
        -- Validate the paint sink even when a unit reuses its cached edges.
        FluxRaidVisuals.SetJoinedEdges(cell.frame,cell.edges,true)
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
        if rangeDiscoveryPending then EnsureRangePoll() end
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
            if frame.RegisterEvent then RegisterUnitRegen(frame) end
            return
        end
        frame._fluxPowerLayoutPending = nil
        frame.powerBarUsedHeight = pbh
        FluxRaidVisuals.ApplyCellChrome(frame, { showPower = show,
            height = frame._fluxRaidMini and not frame._fluxExtraPet and (FluxRaidVisuals.MINI_FRAME_HEIGHT or Compat.MTMA_TARGET_HEIGHT or 18) or nil })
    end
end

local function ReadClassColor(unit)
    if not UnitClass then return nil end
    local ok, _, token = pcall(UnitClass, unit)
    if not ok or IsSecret(token) or type(token) ~= "string" then
        return nil
    end
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if not c then return nil end
    return c.r, c.g, c.b
end

local function ClassColor(unit, sample)
    if not sample then return ReadClassColor(unit) end
    if not sample.classRead then
        sample.classR, sample.classG, sample.classB = ReadClassColor(unit)
        sample.classRead = true
    end
    return sample.classR, sample.classG, sample.classB
end

-- One synchronous paint can use the same values for the bar, color and text.
-- Leave opaque results untouched for the existing native setters.
local function SampleHealth(unit, sample)
    sample = sample or {}
    sample.percent = Compat.GetHealthPercent(unit)
    sample.connected = UnitIsConnected and UnitIsConnected(unit)
    sample.dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)
    sample.classRead = nil
    return sample
end

local function HealthPercent(unit, sample)
    if sample then return sample.percent end
    return Compat.GetHealthPercent(unit)
end

local function Connected(unit, sample)
    if sample then return sample.connected end
    return UnitIsConnected and UnitIsConnected(unit)
end

function FluxRaid_UpdateHealth(frame, sample)
    local bar = frame and frame.healthBar
    local unit = UnitOf(frame)
    if not bar or type(unit) ~= "string" or unit == "" then return end
    EnsurePercentRange(bar)
    sample = sample or SampleHealth(unit)
    SetStatusBarValue(bar, sample.percent)

    local r, g, b = 0.2, 0.8, 0.2
    local useClass = frame.optionTable and frame.optionTable.useClassColors
    local connected, dead = sample.connected, sample.dead
    if not IsSecret(connected) and connected == false then
        r, g, b = 0.22, 0.22, 0.22
    elseif not IsSecret(dead) and dead then
        r, g, b = 0.22, 0.22, 0.22
    elseif useClass then
        local cr, cg, cb = ClassColor(unit, sample)
        if cr then r, g, b = cr * 0.72, cg * 0.72, cb * 0.72 end
    end
    pcall(bar.SetStatusBarColor, bar, r, g, b)
end

function FluxRaid_UpdatePower(frame, sample)
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
    EnsurePercentRange(bar)
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
    local connected = Connected(unit, sample)
    if not IsSecret(connected) and connected == false then
        pcall(bar.SetStatusBarColor, bar, 0.4, 0.4, 0.4)
    end
    SetStatusBarValue(bar, Compat.GetPowerPercent(unit, powerType))
    if FluxRaidPrediction and FluxRaidPrediction.UpdatePowerCost then FluxRaidPrediction.UpdatePowerCost(frame) end
end


function FluxRaid_UpdateHealPrediction(frame)
    if FluxRaidPrediction then FluxRaidPrediction.Update(frame) end
end


local function ClassColoredNames(batch)
    if batch and batch.classColorNames ~= nil then return batch.classColorNames end
    local enabled = FluxRaid_ShouldClassColorNames and FluxRaid_ShouldClassColorNames() and true or false
    if batch then batch.classColorNames = enabled end
    return enabled
end

function FluxRaid_UpdateName(frame, sample, batch)
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
    local connected = Connected(unit, sample)
    if not IsSecret(connected) and connected == false then r,g,b=.55,.55,.55
    elseif ClassColoredNames(batch) then
        local cr,cg,cb=ClassColor(unit, sample)
        if cr then r,g,b=cr,cg,cb end
    end
    fs:SetTextColor(r,g,b)
end


local function NativeHealthTextMode(batch)
    if batch and batch.nativeHealthText ~= nil then return batch.nativeHealthText end
    local mode = false
    if not (FluxRaidVisuals and FluxRaidVisuals.UseOwnRaidSettings and FluxRaidVisuals.UseOwnRaidSettings())
        and C_CVar and C_CVar.GetCVar then
        local cv = C_CVar.GetCVar("raidFramesHealthText")
        if not IsSecret(cv) and type(cv) == "string" and cv ~= "" then mode = cv end
    end
    if batch then batch.nativeHealthText = mode end
    return mode
end

function FluxRaid_UpdateStatusText(frame, sample, batch)
    local fs=frame and frame.statusText
    if not fs then return end
    local opt=frame.optionTable or {}
    local function formatted(format,...)
        if FluxRaidVisuals.SetUnitStatus then FluxRaidVisuals.SetUnitStatus(frame,format,...)
        else fs:SetFormattedText(format,...) end
    end
    local mode=NativeHealthTextMode(batch) or opt._fluxHealthText or opt.healthText or "perc"
    local unit=UnitOf(frame)
    if type(unit)~="string" or unit=="" then fs:Hide(); return end
    if frame._fluxRaidMini and not frame._fluxExtraPet then
        local percent=HealthPercent(unit, sample)
        if not IsSecret(percent) and percent==nil then fs:Hide();return end
        formatted("%.0f%%",percent);fs:Show();return
    end
    local connected=Connected(unit, sample)
    local dead
    if sample then dead=sample.dead
    else dead=UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) end
    if FluxRaidVisuals.SetHealthStatus then
        local health, maximum
        if mode=="health" or mode=="healthandpercent" or mode=="losthealth" then
            health=UnitHealth and UnitHealth(unit)
        end
        if mode=="losthealth" then maximum=UnitHealthMax and UnitHealthMax(unit) end
        FluxRaidVisuals.SetHealthStatus(frame,mode,health,maximum,HealthPercent(unit,sample),connected,dead)
        return
    end
    -- Dead/offline are independent of the health-number preference.
    if not IsSecret(connected) and connected==false then fs:SetText(PLAYER_OFFLINE or "Offline"); fs:Show(); return end
    if not IsSecret(dead) and dead then fs:SetText(DEAD or "Dead"); fs:Show(); return end
    if mode=="none" or opt.displayStatusText==false then fs:Hide(); return end
    local percent=HealthPercent(unit,sample)
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


function FluxRaid_UpdateRoleIcon(frame, sample, batch)
    local unit=UnitOf(frame)
    frame._fluxRole=nil
    if type(unit)=="string" and UnitGroupRolesAssigned then
        local role=UnitGroupRolesAssigned(unit)
        if not IsSecret(role) and ROLE_ATLAS[role] then frame._fluxRole=role end
    end
    -- The name painter retires the standalone icon after drawing the name.
    if frame.roleIcon and not (frame.name and type(unit) == "string" and unit ~= "" and FluxRaidVisuals.SetUnitName) then
        frame.roleIcon:Hide()
    end
    FluxRaid_UpdateName(frame, sample, batch)
    FluxRaid_UpdateStatusText(frame, sample, batch)
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

local function ReadMasterLooterUnit()
    local party = C_PartyInfo
    if not party or not party.GetLootMethod then return end
    local ok, _, partyID, raidID = pcall(party.GetLootMethod)
    if not ok then return end
    if not IsSecret(raidID) and type(raidID) == "number" and raidID > 0 then
        return "raid" .. raidID
    end
    if not IsSecret(partyID) and type(partyID) == "number" and partyID >= 0 then
        return partyID == 0 and "player" or "party" .. partyID
    end
end

local function MasterLooterUnit(batch)
    if type(batch) ~= "table" or IsSecret(batch) then return ReadMasterLooterUnit() end
    if not batch.lootRead then
        batch.masterLooter = ReadMasterLooterUnit()
        batch.lootRead = true
    end
    return batch.masterLooter
end

function FluxRaid_UpdateCenterStatus(frame, batch)
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
        local master=MasterLooterUnit(batch)
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

function FluxRaid_UpdateRange(frame, sampledUnit, sampledConnection)
    if Compat.ApplyRangeAlpha then
        Compat.ApplyRangeAlpha(frame, sampledUnit, sampledConnection)
    end
end


function FluxRaid_UpdateAuras(frame)
    local dispelPainted = FluxRaidAuras and FluxRaidAuras.Update(frame)
    if FluxRaidHealerExtras then FluxRaidHealerExtras.Update(frame) end
    if FluxRaidHoTs then FluxRaidHoTs.Update(frame) end
    return dispelPainted
end

function FluxRaid_UpdateDispelHighlight(frame)
    if FluxRaidAuras then FluxRaidAuras.UpdateDispel(frame) end
end

function FluxRaid_PaintUnit(frame, batch, healthSample)
    if not frame then return end
    if type(batch) ~= "table" or IsSecret(batch) then batch = nil end
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
    local sample=SampleHealth(unit, healthSample)
    FluxRaid_UpdateHealth(frame, sample)
    FluxRaid_UpdatePower(frame, sample)
    FluxRaid_UpdateSelectionHighlight(frame)
    FluxRaid_UpdateAggroHighlight(frame)
    FluxRaid_UpdateRoleIcon(frame, sample, batch)
    FluxRaid_UpdateCenterStatus(frame, batch)
    FluxRaid_UpdateReadyCheck(frame)
    FluxRaid_UpdateHealPrediction(frame)
    FluxRaid_UpdateRange(frame, unit, sample.connected)
    if not frame._fluxRaidMini then
        if FluxRaid_UpdateAuras(frame) ~= true then FluxRaid_UpdateDispelHighlight(frame) end
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
    local register = frame and frame.RegisterUnitEvent
    if not register or IsSecret(unit) or type(unit) ~= "string" or unit == "" then return end
    if frame._fluxRegisteredEventUnit ~= unit or frame._fluxRegisteredEventWriter ~= register then
        frame._fluxClearedUnitEvents = nil
        local registered = true
        for i = 1, #UNIT_EVENTS do
            local event = UNIT_EVENTS[i]
            local ok = pcall(register, frame, event, unit)
            if event == "UNIT_IN_RANGE_UPDATE" then
                frame._fluxRangeEventSupported = ok
            elseif not ok then
                registered = false
            end
        end
        -- A native unit-attribute update can bind immediately before OnShow.
        -- Reuse a successful registration until the frame is unbound or hidden.
        frame._fluxRegisteredEventUnit=registered and unit or nil
        frame._fluxRegisteredEventWriter=registered and register or nil
    elseif frame._fluxRangeEventSupported == false then
        -- Give range support another chance on reveal without reinstalling
        -- the unit routes that already succeeded during the native bind.
        frame._fluxClearedUnitEvents = nil
        frame._fluxRangeEventSupported = pcall(register, frame, "UNIT_IN_RANGE_UPDATE", unit)
    end
    if frame._fluxPowerLayoutPending or frame._fluxNeedsChromeRefresh then RegisterUnitRegen(frame) end
end

local function ClearUnitEvents(frame)
    frame._fluxRegisteredEventUnit = nil
    frame._fluxRegisteredEventWriter = nil
    local clear = frame.UnregisterAllEvents
    if not clear or (frame._fluxRaidUnit and frame._fluxClearedUnitEvents == clear) then return end
    -- Hide and unit unbind can retire the same owned event set. A failed
    -- writer or a registration during cleanup leaves the next clear armed.
    frame._fluxClearedUnitEvents = false
    clear(frame)
    if frame._fluxClearedUnitEvents == false then
        frame._fluxClearedUnitEvents = frame._fluxRaidUnit and clear or nil
    end
end

local pendingPaint, paintDriver, paintArmed = {}, nil, false
local function ReleasePaintFlags(frame, dirty)
    if not dirty then return end
    for key in pairs(dirty) do dirty[key] = nil end
    -- Keep one spare per cell. A paint may synchronously queue another buffer;
    -- the buffer being painted never becomes available until that paint ends.
    if not frame._fluxPaintFlagsSpare then frame._fluxPaintFlagsSpare = dirty end
end

local function ClearPendingPaint(frame)
    local discarded = pendingPaint[frame]
    pendingPaint[frame] = nil
    ReleasePaintFlags(frame, discarded)
end

local function FlushPaint()
    paintArmed = false
    paintDriver:SetScript("OnUpdate", nil)
    local batch, healthSample, enabled
    for frame, dirty in pairs(pendingPaint) do
        pendingPaint[frame] = nil
        local visible = enabled ~= false and frame.unit and (not frame.IsVisible or frame:IsVisible())
        if visible and enabled == nil then
            enabled = (not FluxRaid_IsFluxRaidEnabled or FluxRaid_IsFluxRaidEnabled()) and true or false
        end
        if visible and enabled then
            if dirty.full or dirty.health or dirty.center then batch = batch or {} end
            if dirty.full then
                healthSample=healthSample or {}
                FluxRaid_PaintUnit(frame, batch, healthSample)
            else
                local sample
                if dirty.health then
                    healthSample=SampleHealth(UnitOf(frame), healthSample)
                    sample=healthSample
                    FluxRaid_UpdateHealth(frame, sample)
                    FluxRaid_UpdateStatusText(frame, sample, batch)
                end
                if dirty.prediction or dirty.health then FluxRaid_UpdateHealPrediction(frame) end
                if dirty.power then FluxRaid_UpdatePower(frame, sample) end
                if dirty.aura then
                    if FluxRaid_UpdateAuras(frame) ~= true then FluxRaid_UpdateDispelHighlight(frame) end
                    if FluxRaidFrame_BigDebuffs_TryUpdate then FluxRaidFrame_BigDebuffs_TryUpdate(frame) end
                elseif dirty.missingBuff and FluxRaidHealerExtras then
                    FluxRaidHealerExtras.Update(frame)
                end
                if dirty.threat then FluxRaid_UpdateAggroHighlight(frame) end
                if dirty.range then FluxRaid_UpdateRange(frame) end
                if dirty.center then FluxRaid_UpdateCenterStatus(frame, batch) end
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

function ns.FluxRaidQueueMissingBuffRefresh(frame)
    if frame.unit and (not frame.IsVisible or frame:IsVisible()) then
        MarkPaint(frame,"missingBuff")
    end
end

function ns.FluxRaidQueueRosterPaint(frame)
    local visible = not frame.IsVisible or frame:IsVisible()
    if IsSecret(visible) then
        FluxRaid_PaintUnit(frame)
    elseif visible and frame.unit then
        MarkPaint(frame, "full")
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

function FluxRaid_BindUnit(frame, unit, fromAttribute)
    if not frame then return end
    if unit == "" then unit = nil end
    ClearPendingPaint(frame)
    ClearUnitEvents(frame)
    frame.unit = unit
    frame.displayedUnit = unit
    if unit then
        RegisterUnitEvents(frame, unit)
        if frame._fluxRaidMini and not frame._fluxSecureTargetAttached and unit and not (InCombatLockdown and InCombatLockdown()) then
            pcall(frame.SetAttribute, frame, "unit", unit)
        end
        local visible = fromAttribute and frame.IsVisible and frame:IsVisible()
        if fromAttribute and not IsSecret(visible) and visible == false then
            -- Native headers can bind a child while its parent is hidden.
            -- OnShow paints the new unit from live data before it is drawn.
            frame.unitExists = false
        elseif fromAttribute and not IsSecret(visible) and visible == true and frame._fluxRaidUnit and not frame._fluxRaidMini then
            -- Publish the new unit for joined borders before the visual pass.
            -- Native token changes and roster reconciliation share that pass.
            frame.unitExists = Compat.UnitTokenValid and Compat.UnitTokenValid(unit) or false
            MarkPaint(frame, "full")
        else
            FluxRaid_PaintUnit(frame)
        end
    else
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
    if EnsureRangePoll then EnsureRangePoll(frame, true) end
end

function FluxRaid_OnUnitAttributeChanged(self, name, value)
    if name ~= "unit" then return end
    if value == self.unit then return end
    FluxRaid_BindUnit(self, value, true)
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
    if self.IsVisible and self:IsVisible() then EnsureRangePoll(self, true) end
end

local function RestoreMTMAWrapAlpha(frame)
    local wrap = frame._fluxWrap
    if not wrap then return end
    local ok, alpha = pcall(wrap.GetAlpha, wrap)
    if not ok or IsSecret(alpha) or alpha ~= 1 then wrap:SetAlpha(1) end
end

function FluxRaidUnit_OnShow(self)
    if self._fluxRaidMini then RestoreMTMAWrapAlpha(self) end
    local unit = self:GetAttribute("unit") or self.unit
    if unit and unit ~= self.unit then
        FluxRaid_BindUnit(self, unit)
    else
        if unit then RegisterUnitEvents(self,unit) end
        FluxRaid_RequestJoinedBorderRefresh()
        EnsureRangePoll(self, true)
        ClearPendingPaint(self)
        FluxRaid_PaintUnit(self)
    end
end

function FluxRaidUnit_OnHide(self)
    ClearPendingPaint(self)
    ClearUnitEvents(self)
    ShowRegion(self.aggroHighlight, false)
    ShowRegion(self.mouseOverHighlight, false)
    if FluxRaidAuras then FluxRaidAuras.Clear(self) end
    if FluxRaidPrediction then FluxRaidPrediction.Clear(self) end
    if FluxRaidHealerExtras then FluxRaidHealerExtras.Clear(self) end
    if FluxRaidHoTs then FluxRaidHoTs.Clear(self) end
    self.UpdateTooltip=nil
    local uf = ns.UnitFrames
    if uf and uf.HideUnitTooltip then uf.HideUnitTooltip(self) end
    FluxRaid_RequestJoinedBorderRefresh()
    EnsureRangePoll(nil, true)
end

-- Blizzard tooltip. Native UnitFrame_UpdateTooltip throws on a nil unit
-- (unbound header children); replacing that global would taint every unit frame.
local function FluxRaidUnit_UpdateTooltip(self)
    local unit = self.unit
    local uf = ns.UnitFrames
    if IsSecret(unit) or type(unit) ~= "string" or unit == "" then
        self.UpdateTooltip = nil
        if uf and uf.HideUnitTooltip then uf.HideUnitTooltip(self) end
        return
    end
    local tooltip = uf and uf.BeginUnitTooltip and uf.BeginUnitTooltip(self)
    if not tooltip then self.UpdateTooltip = nil; return end
    if tooltip:SetUnit(unit, self.hideStatusOnTooltip) then
        if GameTooltip_AddBlankLineToTooltip and GameTooltip_AddInstructionLine and UNIT_POPUP_RIGHT_CLICK then
            GameTooltip_AddBlankLineToTooltip(tooltip)
            GameTooltip_AddInstructionLine(tooltip, UNIT_POPUP_RIGHT_CLICK)
        end
        tooltip:Show()
        if ns.ApplyHUDTooltipPosition then ns.ApplyHUDTooltipPosition(tooltip) end
        uf.SetUnitTooltipRefresh(self, function()
            if not uf.IsUnitTooltipOwner(self) then return end
            if (self.IsVisible and not self:IsVisible()) or (self.IsShown and not self:IsShown())
                or (self.IsMouseOver and not self:IsMouseOver()) then
                if uf.HideUnitTooltip then uf.HideUnitTooltip(self) end
                return
            end
            FluxRaidUnit_UpdateTooltip(self)
        end)
    else
        self.UpdateTooltip = nil
        uf.UnitTooltipState.rebuilding = nil
        uf.HideUnitTooltip(self)
    end
    uf.UnitTooltipState.rebuilding = nil
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
    if uf and uf.HideUnitTooltip then uf.HideUnitTooltip(self, true) end
    ShowRegion(self.mouseOverHighlight, false)
end

function ns.FluxRaidRegisterAllMouseoverKeybindFrames()
    local kb = ns and ns.FluxMouseoverKeybind
    if not kb or not kb.RegisterFrame then return end
    local isRegistered = kb.IsFrameRegistered
    for frame in pairs(State.frameArray) do
        if frame and not (isRegistered and isRegistered(kb, frame)) and frame.RegisterForClicks
            and not (frame.IsForbidden and frame:IsForbidden()) then
            kb:RegisterFrame(frame)
        end
    end
end

local function IsKnownHiddenHeader(header)
    local isShown = header.IsShown
    if IsSecret(isShown) or type(isShown) ~= "function" then return false end
    local ok, shown = pcall(isShown, header)
    return ok and not IsSecret(shown) and shown == false
end

function FluxRaid_ForEachHeaderChild(fn, onlyHeader, shownHeadersOnly)
    if not fn then return end
    local headers = {}
    if onlyHeader then
        headers[1] = onlyHeader
    else
        local groupCount = Compat.GROUP_COUNT or 8
        for i = 1, groupCount do
            local h = State.raidHeaders[i]
            if h then headers[#headers + 1] = h end
        end
        if State.mtmaHeader then headers[#headers + 1] = State.mtmaHeader end
    end
    local seen = {}
    for _, header in ipairs(headers) do
        if not shownHeadersOnly or not IsKnownHiddenHeader(header) then
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
end

function FluxRaid_SyncHeaderChildUnits(onlyHeader, shownHeadersOnly)
    FluxRaid_ForEachHeaderChild(function(btn)
        if btn._fluxRaidMini then return end
        local unit = btn:GetAttribute("unit")
        if unit ~= btn.unit then
            FluxRaid_BindUnit(btn, unit)
        elseif unit then
            MarkPaint(btn,"full")
        end
    end, onlyHeader, shownHeadersOnly)
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
    local batch
    FluxRaid_ForEachHeaderChild(function(btn)
        if not btn.unit then return end
        if which == "spells" then
            if not btn._fluxRaidMini then MarkPaint(btn,"aura") end
        elseif which == "target" then
            FluxRaid_UpdateSelectionHighlight(btn)
            FluxRaid_UpdateName(btn)
        elseif which == "role" then
            FluxRaid_UpdateRoleIcon(btn)
            FluxRaid_UpdatePower(btn)
        elseif which == "ready" then
            FluxRaid_UpdateReadyCheck(btn)
        elseif which == "raidtarget" then
            batch = batch or {}
            FluxRaid_UpdateCenterStatus(btn, batch)
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

-- Shared range helpers keep per-discovery state in arguments only.
local function RangeFallbackNeedsPoll(btn)
    return btn and btn.unit and btn._fluxRangeEventSupported==false
        and btn.IsVisible and btn:IsVisible()
        and (not FluxRaid_IsFluxRaidEnabled or FluxRaid_IsFluxRaidEnabled())
end
local function RangeFallbackPollSet(frames, paint)
    local any=false
    for btn in pairs(frames or {}) do
        if RangeFallbackNeedsPoll(btn) then
            -- Discovery only needs one live owner; ticker paints still
            -- visit every eligible cell at the existing cadence.
            if not paint then return true end
            any=true
            if paint then FluxRaid_UpdateRange(btn) end
        end
    end
    return any
end

EnsureRangePoll = function(frame, deferDiscovery)
    local active=RangeFallbackNeedsPoll(frame)
    if not active then
        -- A visible fallback owner can start the ticker immediately. Other
        -- lifecycle callbacks share one discovery of the settled roster.
        if deferDiscovery and State.joinedBorderPending then
            rangeDiscoveryPending = true
            return
        end
        rangeDiscoveryPending = false
        active=RangeFallbackPollSet(State.frameArray,false) or RangeFallbackPollSet(State.partyRangeFrames,false)
    end
    if not active then
        if rangePollTicker then rangePollTicker:Cancel(); rangePollTicker=nil end
        return
    end
    if rangePollTicker or not C_Timer or not C_Timer.NewTicker then return end
    rangePollTicker = C_Timer.NewTicker(0.25, function()
        local any=RangeFallbackPollSet(State.frameArray,true)
        if RangeFallbackPollSet(State.partyRangeFrames,true) then any=true end
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
        RestoreMTMAWrapAlpha(tf)
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

function FluxRaid_RefreshMTMATargetAttachments(shownHeadersOnly)
    local header = State.mtmaHeader
    if not header then return end
    FluxRaid_ForEachHeaderChild(function(btn)
        if not btn._fluxRaidMini and FluxRaid_IsMTMAChild(btn) then
            local pending = btn._fluxMTMATarget and btn._fluxMTMATarget._fluxPendingUnit
            if pending and not (InCombatLockdown and InCombatLockdown()) then
                FluxRaid_BindUnit(btn._fluxMTMATarget, pending)
                btn._fluxMTMATarget._fluxPendingUnit = nil
            end
            FluxRaid_AttachOrUpdateMTMATarget(btn, btn.unit)
        end
    end, header, shownHeadersOnly)
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
