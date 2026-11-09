-- Forever keeps combo points on the target and supplies the modern red-pip
-- template, but no RogueComboPointBarFrame / DruidComboPointBarFrame instances.
-- Own both Flux rows; never run native bar Setup or modify PlayerFrame.unit.
local addonName, ns = ...
local client = ns.Flux and ns.Flux.Client or FLUX_API or {}
if not (client.isCamelot or client.isForever) then return end

local Combo = {}
ns.ForeverComboPoints = Combo
local rows, pending = {}, {}
local eventFrame
local MAX_POINTS = 5 -- Matches Forever's ComboFrameMixin.
local POINT_SIZE, SPACING = 20, 4

local function Accessible(value)
    if issecretvalue and issecretvalue(value) then return false end
    if canaccessvalue and not canaccessvalue(value) then return false end
    return true
end

function Combo.CanShowForPlayer()
    local _, class = UnitClass("player")
    if class == "ROGUE" then return true end
    if class == "DRUID" then
        local powerType = UnitPowerType("player")
        return Accessible(powerType) and powerType == Enum.PowerType.Energy
    end
    return false
end

local function ShouldShow(row)
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux(row.unit) then return false end
    if row.unit == "player" then
        if FluxUnitFrames_ShouldShowClassPower and not FluxUnitFrames_ShouldShowClassPower() then return false end
    elseif FluxUnitFrames_ShouldShowPortrait and not FluxUnitFrames_ShouldShowPortrait("target") then
        return false
    end
    return Combo.CanShowForPlayer()
end

-- SetValue accepts secret numbers. A separate bar for each native active
-- texture clamps integer counts to a full/empty pip without a Lua comparison.
-- Do not feed secret booleans to RogueComboPointMixin's animation state machine.
local function CreateRestrictedFill(point, atlas, index)
    local info = C_Texture.GetAtlasInfo(atlas)
    local bar = CreateFrame("StatusBar", nil, point)
    bar:SetSize(info.width, info.height)
    bar:SetPoint("CENTER", point, "CENTER")
    bar:SetStatusBarTexture(atlas)
    bar:SetMinMaxValues(index - 1, index)
    bar:SetValue(0)
    bar:Hide()
    return bar
end

-- Shared with the target nameplate row. These helpers only touch owned frames;
-- unit-frame options are deliberately kept in ShouldShow, outside the renderer.
function Combo.UpdatePoints(row, count, maxPoints, suppressTransitions)
    local restricted = not Accessible(count)
    -- Keep the empty sockets visible on rogues and in Cat Form, including
    -- zero points / no target. Only the class/form and display options hide it.
    -- All children are addon-owned and unprotected. Updating their art is safe
    -- during combat; layout never touches Blizzard's native resource handlers.
    row:Show()
    for i, point in ipairs(row.points) do
        point:SetShown(i <= maxPoints)
        if restricted then
            point:SetActiveNoAnimation(false)
            for _, fill in ipairs(point.restrictedFills) do
                fill:SetValue(count)
                fill:Show()
            end
        else
            for _, fill in ipairs(point.restrictedFills) do fill:Hide() end
            local active = i <= count
            if suppressTransitions or row.previousRestricted or not row.hasUpdated then
                point:SetActiveNoAnimation(active)
            else
                point:SetActive(active)
            end
        end
    end
    row.previousRestricted = restricted
    row.hasUpdated = true
end

function Combo.GetValues()
    local unit = UnitHasVehicleUI and UnitHasVehicleUI("player") and "vehicle" or "player"
    local count = GetComboPoints(unit, "target")
    local maxPoints = UnitPowerMax(unit, Enum.PowerType.ComboPoints)
    if not Accessible(maxPoints) or type(maxPoints) ~= "number" or maxPoints <= 0 then
        maxPoints = MAX_POINTS
    else
        maxPoints = math.min(MAX_POINTS, maxPoints)
    end
    return count, maxPoints
end

function Combo.RefreshAll(suppressTransitions)
    if not next(rows) then return end
    local count, maxPoints = Combo.GetValues()
    for _, row in pairs(rows) do
        if not InCombatLockdown() then
            row:SetScale(1.6 * (FluxUnitFrames_GetClassPowerScale and FluxUnitFrames_GetClassPowerScale() or 1))
        end
        if ShouldShow(row) then
            Combo.UpdatePoints(row, count, maxPoints, suppressTransitions)
        else
            row:Hide()
            row.previousRestricted = nil
            row.hasUpdated = false
        end
    end
end

local function RegisterEvents()
    if eventFrame then return end
    eventFrame = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "COMBO_TARGET_CHANGED",
        "UPDATE_SHAPESHIFT_FORM", "PLAYER_REGEN_ENABLED" }) do
        eventFrame:RegisterEvent(event)
    end
    for _, event in ipairs({ "UNIT_POWER_FREQUENT", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER",
        "UNIT_POWER_POINT_CHARGE", "UNIT_DISPLAYPOWER", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE" }) do
        eventFrame:RegisterUnitEvent(event, "player", "vehicle")
    end
    eventFrame:SetScript("OnEvent", function(_, event, unit, powerType)
        if event:find("^UNIT_") and unit ~= "player" and unit ~= "vehicle" then return end
        if (event == "UNIT_POWER_FREQUENT" or event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER")
            and powerType and powerType ~= "COMBO_POINTS" then return end
        if event == "PLAYER_REGEN_ENABLED" then
            for key, parent in pairs(pending) do
                pending[key] = nil
                Combo.Initialize(parent)
            end
        end
        Combo.RefreshAll(event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD")
    end)
end

function Combo.CreatePoints(row)
    row.points = {}
    row:SetSize(MAX_POINTS * POINT_SIZE + (MAX_POINTS - 1) * SPACING, POINT_SIZE)
    for i = 1, MAX_POINTS do
        local point = CreateFrame("Frame", nil, row, "RogueComboPointTemplate")
        point:SetPoint("LEFT", row, "LEFT", (i - 1) * (POINT_SIZE + SPACING), 0)
        point:Setup()
        point:SetActiveNoAnimation(false)
        point.restrictedFills = {
            CreateRestrictedFill(point, "uf-roguecp-bg", i),
            CreateRestrictedFill(point, "uf-roguecp-icon-red", i),
        }
        -- The icon belongs above the active background, just like the template.
        point.restrictedFills[2]:SetFrameLevel(point.restrictedFills[1]:GetFrameLevel() + 1)
        row.points[i] = point
    end
end

function Combo.Initialize(parent)
    local unit = parent and parent.unit
    if unit ~= "player" then return end
    local _, class = UnitClass("player")
    if class ~= "ROGUE" and class ~= "DRUID" then return end
    RegisterEvents()
    if rows[unit] then
        Combo.RefreshAll(true)
        return
    end
    if InCombatLockdown() then
        pending[unit] = parent
        return
    end
    local anchor = parent.outerBorderFrame or parent
    if not anchor then return end
    local row = CreateFrame("Frame", "FluxForeverCombo" .. (unit == "player" and "Player" or "Target"), anchor)
    row.unit = unit
    row:SetFrameStrata("DIALOG")
    local model = parent.Portrait
    row:SetFrameLevel(math.max(anchor:GetFrameLevel(), model and model:GetFrameLevel() or 0) + 12)
    row:SetScale(1.6 * (FluxUnitFrames_GetClassPowerScale and FluxUnitFrames_GetClassPowerScale() or 1))
    row:SetPoint("BOTTOM", anchor, "TOP", 0, 0)
    Combo.CreatePoints(row)
    rows[unit] = row
    row:Hide()
    Combo.RefreshAll(true)
end
