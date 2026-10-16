-- Native client artwork on the current target only. All points/hosts belong to
-- Flux; never reparent ComboFrame or hook/replace a Blizzard nameplate handler.
local addonName, ns = ...
local Flux = ns.Flux
local NP = Flux.NamePlates
local client = Flux.Client or {}
local classic = client.isEra or client.isClassicEra or client.isAnniversary
local forever = not classic and not NP.IsLiveClient() and (client.isCamelot or client.isForever)
if not (classic or forever) then return end
local _, class = UnitClass("player")
if class ~= "ROGUE" and class ~= "DRUID" then return end

local Modern = forever and ns.ForeverComboPoints
if forever and not Modern then return end
local Combo = NP.RegisterModule("comboPoints", {})
local MAX_POINTS = 5
local host = NP.CreateHost(68, 12)
local currentPlate, currentUnit, currentBar
local lastCount = 0

if Modern then
    Modern.CreatePoints(host)
    host:SetScale(0.675)
else
    host:SetScale(1.5)
    host.points = {}
    for i = 1, MAX_POINTS do
        local point = CreateFrame("Frame", nil, host, "ComboPointTemplate")
        -- Center the sockets on both axes around the same host anchor as Forever.
        point:SetPoint("CENTER", host, "CENTER", (i - (MAX_POINTS + 1) / 2) * 14, -4)
        point.Highlight:SetAlpha(0)
        point.Shine:SetAlpha(0)
        host.points[i] = point
    end
end

local function ClearPointFades(point)
    if UIFrameFadeRemoveFrame then
        UIFrameFadeRemoveFrame(point.Highlight)
        UIFrameFadeRemoveFrame(point.Shine)
    end
    point.Highlight:SetAlpha(0)
    point.Shine:SetAlpha(0)
end

local function Clear()
    NP.ReleaseHost(host)
    currentPlate, currentUnit, currentBar = nil, nil, nil
    lastCount = 0
    host.previousRestricted, host.hasUpdated = nil, false
    if not Modern then
        for _, point in ipairs(host.points) do ClearPointFades(point) end
    end
end

local function Eligible()
    if Modern then return Modern.CanShowForPlayer() end
    if class == "ROGUE" then return true end
    local power = UnitPowerType("player")
    return NP.IsUsable(power) and power == Enum.PowerType.Energy
end

local function GetValues()
    if Modern then return Modern.GetValues() end
    local unit = UnitHasVehicleUI and UnitHasVehicleUI("player") and "vehicle" or "player"
    local count = GetComboPoints(unit, "target")
    local maximum = UnitPowerMax(unit, Enum.PowerType.ComboPoints)
    if not NP.IsUsable(count) then count = 0 end
    if not NP.IsUsable(maximum) or maximum <= 0 then maximum = MAX_POINTS end
    return count, math.min(MAX_POINTS, maximum)
end

local function UpdateClassic(count, maximum, suppressTransitions)
    for i, point in ipairs(host.points) do
        point:SetShown(i <= maximum)
        if i <= count and i <= maximum then
            if suppressTransitions then
                ClearPointFades(point)
                point.Highlight:SetAlpha(1)
            elseif i > lastCount then
                if UIFrameFade and ComboPointShineFadeIn then
                    UIFrameFade(point.Highlight, {
                        mode = "IN", timeToFade = COMBOFRAME_HIGHLIGHT_FADE_IN or 0.4,
                        finishedFunc = ComboPointShineFadeIn, finishedArg1 = point.Shine,
                    })
                else
                    point.Highlight:SetAlpha(1)
                end
            end
        else
            ClearPointFades(point)
        end
    end
    lastCount = count
    host:Show()
end

local function Refresh(suppressTransitions)
    if not Eligible() then Clear(); return end
    -- Resolve by frame identity instead of comparing restricted unit tokens.
    -- C_NamePlate supports "target"; only plates in the live roster qualify.
    local _, plate, _, bar = NP.GetParts("target")
    local token
    if plate and bar then
        for unit in pairs(NP.activeUnits) do
            if NP.GetPlate(unit) == plate then token = unit; break end
        end
    end
    if not token then Clear(); return end
    local switched = currentPlate ~= plate or currentUnit ~= token
    if switched or currentBar ~= bar then
        host:Hide()
        if not NP.AttachHost(host, plate, 2) then Clear(); return end
        host:ClearAllPoints()
        if not pcall(host.SetPoint, host, "CENTER", bar, "TOP", 0, 4) then Clear(); return end
        currentPlate, currentUnit, currentBar = plate, token, bar
    end
    local count, maximum = GetValues()
    if Modern then
        Modern.UpdatePoints(host, count, maximum, suppressTransitions or switched)
    else
        UpdateClassic(count, maximum, suppressTransitions or switched)
    end
end

function Combo.Added() Refresh(true) end
function Combo.Removed(unit)
    if currentUnit == unit then Clear() end
end
function Combo.Refresh(unit)
    if currentUnit == unit or not currentUnit then Refresh(true) end
end
function Combo.RefreshAll() Refresh(true) end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "COMBO_TARGET_CHANGED", "PLAYER_ENTERING_WORLD", "UPDATE_SHAPESHIFT_FORM" }) do
    events:RegisterEvent(event)
end
for _, event in ipairs({ "UNIT_POWER_FREQUENT", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
    "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE" }) do
    events:RegisterUnitEvent(event, "player", "vehicle")
end
if forever then
    events:RegisterUnitEvent("UNIT_POWER_POINT_CHARGE", "player", "vehicle")
end
events:SetScript("OnEvent", function(_, event, unit, power)
    if event:find("^UNIT_") and unit ~= "player" and unit ~= "vehicle" then return end
    if (event == "UNIT_POWER_FREQUENT" or event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER")
        and power and power ~= "COMBO_POINTS" then return end
    Refresh(event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD")
end)
