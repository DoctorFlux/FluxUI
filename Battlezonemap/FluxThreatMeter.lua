-- The native meter's threat pane uses Flux threat data, without Details objects.
local _, ns = ...
local Flux = ns and ns.Flux or _G.Flux
local Meter = {}
FluxThreatMeter = Meter

local pane, host, enabled, scale = nil, nil, false, 1
local data, rows, offset, nextPoll, dirty = {}, {}, 0, 0, false
local rowHeight, headerHeight = 21, 25.6 -- Native 32-unit header at the shared .8 meter scale.
local ranked = true
local workActive = false

local function Shared() return Flux and Flux.Threat end
local function IsSecret(value)
    local secrets = Flux and Flux.Secrets
    if secrets and secrets.IsSecretValue then return secrets.IsSecretValue(value) end
    return issecretvalue and issecretvalue(value) or false
end
local function Present(value)
    if IsSecret(value) then return true end
    return value ~= nil
end
local function PlainBool(value)
    local secrets = Flux and Flux.Secrets
    if secrets and secrets.SafeBooleanTest then return secrets.SafeBooleanTest(value, false) end
    if IsSecret(value) then return false end
    if secrets and secrets.CanAccessValue and not secrets.CanAccessValue(value) then return false end
    return value == true
end
local function IsPlayer(unit) return PlainBool(UnitIsUnit(unit, "player")) end

function Meter:IsAvailable()
    local client = Flux and Flux.Client
    if not (client and (client.isForever or client.isCamelot)) then return false end
    if FluxMeterLayout and FluxMeterLayout.IsDetailsAddonLoaded then
        if FluxMeterLayout.IsDetailsAddonLoaded() then return false end
    elseif _G.Details then
        return false
    end
    local threat = Shared()
    return threat and type(threat.GetMeterRow) == "function" and type(threat.SetBarValue) == "function"
        and type(threat.UnitExists) == "function" and type(threat.UnitCanAttack) == "function"
        and type(threat.AccessibleNumber) == "function" and type(threat.SetPercentText) == "function" or false
end

local function HostVisible()
    if not enabled or not host or not host:IsVisible() or not Meter:IsAvailable() then return false end
    local tab = FluxWindowFrame and FluxWindowFrame.GetActiveTab and FluxWindowFrame:GetActiveTab()
    return not tab or tab == "Meter"
end

local function InCombat()
    local threat = Shared()
    if threat and threat.PlayerInCombat then return threat.PlayerInCombat() end
    return InCombatLockdown and InCombatLockdown() or false
end

local function TargetUnit()
    local threat = Shared()
    local function hostile(unit) return threat.UnitExists(unit) and threat.UnitCanAttack(unit) end
    if hostile("target") then return "target" end
    if hostile("targettarget") then return "targettarget" end
    return nil
end

local function UnitNameForRow(unit)
    local names = Flux and Flux.PlayerName
    if names and names.GetDisplayName then return names.GetDisplayName(unit, true) or UNKNOWN end
    return GetUnitName(unit, true) or UNKNOWN
end

local function Collect()
    wipe(data)
    ranked = true
    local threat, target = Shared(), TargetUnit()
    if not target or (threat.IsExcludedThreatUnit and threat.IsExcludedThreatUnit(target)) then return end
    local function add(unit)
        if not threat.UnitExists(unit) then return end
        local sample = threat.GetMeterRow(unit, target)
        if not sample then return end
        local value = threat.AccessibleNumber(sample.threatVal)
        local percent = threat.AccessibleNumber(sample.threatPct)
        -- An opaque cohort retains roster order; its positions are not ranks.
        if sample.secret or (Present(sample.threatVal) and value == nil)
            or (Present(sample.threatPct) and percent == nil) then ranked = false end
        local _, class = UnitClass(unit)
        if IsSecret(class) then class = nil end
        data[#data + 1] = { unit = unit, name = UnitNameForRow(unit), class = class,
            threatVal = sample.threatVal, threatPct = sample.threatPct,
            isTanking = PlainBool(sample.isTanking), secret = sample.secret,
            sort = percent or value or 0, order = #data + 1 }
    end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do add("raid" .. i); add("raidpet" .. i) end
    elseif IsInGroup() then
        add("player"); add("pet")
        for i = 1, GetNumSubgroupMembers() do add("party" .. i); add("partypet" .. i) end
    else
        add("player"); add("pet")
    end
    if ranked then
        table.sort(data, function(a, b)
            if a.isTanking ~= b.isTanking then return a.isTanking end
            if a.sort ~= b.sort then return a.sort > b.sort end
            return a.order < b.order
        end)
    end
end

local function FormatNumber(value)
    -- Keep the existing FluxThreat plugin's threshold and truncation rules.
    if value > 1e10 then return math.floor(value / 1e9) .. "b"
    elseif value > 1e9 then return (math.floor(value / 1e9 * 10) / 10) .. "b"
    elseif value > 1e7 then return math.floor(value / 1e6) .. "m"
    elseif value > 1e6 then return (math.floor(value / 1e6 * 10) / 10) .. "m"
    elseif value > 1e4 then return math.floor(value / 1e3) .. "k"
    elseif value > 1e3 then return (math.floor(value / 1e3 * 10) / 10) .. "k"
    end
    return tostring(math.floor(value))
end

local function StyleFont(fs, size)
    if FluxMeterSkin and FluxMeterSkin.StyleFont then
        FluxMeterSkin:StyleFont(fs, size)
    else
        fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, "OUTLINE")
        fs:SetShadowColor(0, 0, 0, 1); fs:SetShadowOffset(1, -1)
    end
end

local function NewRow(index)
    local row = CreateFrame("StatusBar", nil, pane.Body)
    row:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    row:SetMinMaxValues(0, 100)
    row.Background = row:CreateTexture(nil, "BACKGROUND")
    row.Background:SetAllPoints()
    if FluxMeterSkin and FluxMeterSkin.StyleRowBackground then FluxMeterSkin:StyleRowBackground(row.Background)
    else row.Background:SetColorTexture(.619607, .619607, .619607, .116164) end
    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.Name = row:CreateFontString(nil, "OVERLAY")
    row.Name:SetJustifyH("LEFT")
    row.Name:SetWordWrap(false); row.Name:SetNonSpaceWrap(false)
    row.Value = row:CreateFontString(nil, "OVERLAY")
    row.Value:SetJustifyH("RIGHT")
    row.Value:SetWordWrap(false); row.Value:SetNonSpaceWrap(false)
    rows[index] = row
    return row
end

local function VisibleRows()
    return math.max(0, math.floor((pane.Body:GetHeight() or 0) / (rowHeight / scale)))
end

local function PlayerRow()
    for i = 1, #data do if IsPlayer(data[i].unit) then return data[i], i end end
end

local function MaxOffset(capacity)
    local lastPage = math.max(0, #data - capacity)
    local _, playerIndex = PlayerRow()
    if capacity > 1 and playerIndex and playerIndex <= lastPage then return lastPage + 1 end
    return lastPage
end

local function PaintRow(row, sample, index, pinned)
    row.unit = sample.unit
    if row.presentationScale ~= scale then
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", pane.Body, "TOPLEFT", 0, -((index - 1) * rowHeight / scale))
        row:SetPoint("TOPRIGHT", pane.Body, "TOPRIGHT", 0, -((index - 1) * rowHeight / scale))
        row:SetHeight(rowHeight / scale)
        row.Icon:SetSize(14 / scale, 14 / scale)
        row.Value:ClearAllPoints(); row.Value:SetPoint("RIGHT", row, "RIGHT", -2 / scale, 0)
        row.Name:ClearAllPoints()
        row.Name:SetPoint("LEFT", row.Icon, "RIGHT", 2 / scale, 0)
        row.Name:SetPoint("RIGHT", row.Value, "LEFT", -2 / scale, 0)
        StyleFont(row.Name, 14 / scale); StyleFont(row.Value, 14 / scale)
        row.presentationScale, row.bodyWidth = scale, nil
    end
    row.Icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    local coords = sample.class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[sample.class]
    if coords then row.Icon:SetTexCoord(unpack(coords))
    else row.Icon:SetTexture("Interface\\Icons\\Ability_Druid_Cower"); row.Icon:SetTexCoord(0, 1, 0, 1) end
    local threat = Shared()
    local value, percent = threat.AccessibleNumber(sample.threatVal), threat.AccessibleNumber(sample.threatPct)
    if sample.secret or (Present(sample.threatVal) and value == nil) or (Present(sample.threatPct) and percent == nil) then
        if Present(sample.threatVal) and Present(sample.threatPct) then
            row.Value:SetFormattedText("%.0f||%.0f%%", sample.threatVal, sample.threatPct)
        elseif Present(sample.threatPct) then
            threat.SetPercentText(row.Value, sample.threatPct)
        elseif Present(sample.threatVal) then
            row.Value:SetFormattedText("%.0f", sample.threatVal)
        else row.Value:SetText("") end
    else
        local amount = value and FormatNumber(value) or ""
        if percent then amount = amount .. "||" .. math.floor(math.max(0, percent) + .5) .. "%" end
        row.Value:SetText(amount)
    end
    local prefix = ranked and (sample.rank .. ". ") or ""
    row.Name:SetFormattedText("%s%s", prefix, sample.name)
    local width = pane.Body:GetWidth()
    if row.bodyWidth ~= width then
        row.Value:SetWidth(math.min(115 / scale, math.max(35 / scale, width * .48)))
        row.bodyWidth = width
    end
    local color = sample.class and RAID_CLASS_COLORS[sample.class]
    row:SetStatusBarColor(color and color.r or .5, color and color.g or .5, color and color.b or .5)
    threat.SetBarValue(row, sample.threatPct, sample.isTanking)
    row.Value:SetTextColor(1, 1, 1, 1)
    if IsPlayer(sample.unit) then row.Name:SetTextColor(0, 1, 0, 1)
    else row.Name:SetTextColor(1, 1, 1, 1) end
    row:SetAlpha(pinned and .5 or 1)
    row:Show()
end

local function Paint()
    if not pane or not HostVisible() or not pane:IsVisible() then return end
    local capacity = VisibleRows()
    if capacity < 1 then for i = 1, #rows do rows[i]:Hide() end; return end
    offset = math.min(offset, MaxOffset(capacity))
    local player, playerIndex = PlayerRow()
    local pin = capacity > 1 and player and (playerIndex <= offset or playerIndex > offset + capacity)
    local count = math.min(capacity, #data - offset + (pin and 1 or 0))
    if pin then count = math.min(capacity, math.max(1, count)) end
    for i = 1, count do
        local sample = pin and i == count and player or data[offset + i]
        PaintRow(rows[i] or NewRow(i), sample, i, pin and i == count)
    end
    for i = count + 1, #rows do rows[i]:Hide() end
end

local function ClearRows()
    wipe(data); offset = 0
    for i = 1, #rows do rows[i]:Hide() end
end

local function Refresh()
    if not InCombat() then ClearRows(); return end
    Collect()
    for i = 1, #data do data[i].rank = i end
    Paint()
end

local function StopWork()
    if not pane then return end
    pane:UnregisterAllEvents(); pane:SetScript("OnUpdate", nil)
    dirty, workActive = false, false
end

local function OnUpdate()
    if not HostVisible() or not pane:IsVisible() then StopWork(); return end
    local now = GetTime()
    if dirty or (InCombat() and now >= nextPoll) then
        dirty = false; nextPoll = now + .2; Refresh()
    end
    if not InCombat() then pane:SetScript("OnUpdate", nil) end
end

local function RequestRefresh()
    if not HostVisible() or not pane:IsVisible() then return end
    if not InCombat() then
        if #data > 0 then ClearRows() end
        return
    end
    dirty = true; pane:SetScript("OnUpdate", OnUpdate)
end

local function StartWork()
    if not HostVisible() or not pane:IsVisible() then StopWork(); return end
    if workActive then return end
    workActive = true
    if not InCombat() then ClearRows() end
    StyleFont(pane.Title, 12 / scale)
    if FluxMeterSkin and FluxMeterSkin.ApplyToOwnedPane then FluxMeterSkin:ApplyToOwnedPane(pane, "Threat", scale) end
    for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "GROUP_ROSTER_UPDATE", "UNIT_THREAT_LIST_UPDATE", "ADDON_LOADED" }) do pane:RegisterEvent(event) end
    pane:RegisterUnitEvent("UNIT_TARGET", "target")
    RequestRefresh()
end

local function CreatePane()
    pane = CreateFrame("Frame", "FluxStandaloneThreatMeter", host)
    pane:SetSize(150, 150)
    pane.Title = pane:CreateFontString(nil, "OVERLAY")
    pane.Title:SetPoint("LEFT", pane, "TOPLEFT", 3 / scale, -headerHeight / (2 * scale))
    StyleFont(pane.Title, 12 / scale)
    pane.Title:SetText("Threat")
    pane.Body = CreateFrame("Frame", nil, pane)
    pane.Body:SetClipsChildren(true)
    pane.Body:SetPoint("TOPLEFT", pane, "TOPLEFT", 2, -headerHeight)
    pane.Body:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -2, 2)
    pane:EnableMouseWheel(true)
    pane:SetScript("OnMouseWheel", function(_, delta)
        local capacity = VisibleRows()
        offset = math.max(0, math.min(MaxOffset(capacity), offset - delta)); Paint()
    end)
    pane:SetScript("OnShow", StartWork)
    pane:SetScript("OnHide", StopWork)
    pane:SetScript("OnSizeChanged", function() Paint() end)
    pane:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_REGEN_ENABLED" then
            ClearRows(); dirty = false; pane:SetScript("OnUpdate", nil)
            return
        end
        if event == "ADDON_LOADED" and not Meter:IsAvailable() then Meter:Hide(); return end
        if event == "UNIT_THREAT_LIST_UPDATE" and not IsSecret(unit) and unit ~= TargetUnit() then return end
        RequestRefresh()
    end)
end

function Meter:RefreshLayout()
    if not pane then return end
    pane.Title:ClearAllPoints(); pane.Title:SetPoint("LEFT", pane, "TOPLEFT", 3 / scale, -headerHeight / (2 * scale))
    pane.Body:ClearAllPoints()
    pane.Body:SetPoint("TOPLEFT", pane, "TOPLEFT", 2 / scale, -headerHeight / scale)
    pane.Body:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -2 / scale, 2 / scale)
    if HostVisible() and pane:IsVisible() then
        StyleFont(pane.Title, 12 / scale)
        if FluxMeterSkin and FluxMeterSkin.ApplyToOwnedPane then FluxMeterSkin:ApplyToOwnedPane(pane, "Threat", scale) end
    end
    Paint()
end

function Meter:Embed(parentFrame, presentationScale)
    if not parentFrame or not self:IsAvailable() then return nil end
    if IsSecret(presentationScale) then return nil end
    if presentationScale ~= nil and (type(presentationScale) ~= "number" or presentationScale <= 0) then return nil end
    host, scale, enabled = parentFrame, presentationScale or 1, true
    if not pane then CreatePane() else pane:SetParent(host) end
    pane:SetScale(scale)
    self:RefreshLayout()
    self:Show()
    return pane
end

function Meter:GetFrame() return pane end

function Meter:Show()
    enabled = true
    if not pane then return end
    if HostVisible() then
        if not pane:IsShown() then pane:Show() else StartWork() end
    else pane:Hide(); StopWork() end
end

function Meter:Hide()
    enabled = false
    if pane then pane:Hide(); StopWork() end
end

function Meter:Cleanup()
    self:Hide(); host = nil; offset = 0; wipe(data)
    if pane and FluxMeterSkin and FluxMeterSkin.ReleaseWindow then FluxMeterSkin:ReleaseWindow(pane) end
    for i = 1, #rows do rows[i].unit = nil; rows[i]:Hide() end
end
