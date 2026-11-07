local addonName, ns = ...

-- Healer feedback for Flux-owned cells. Native calculators own restricted
-- arithmetic; fixed-size bars follow fill textures without reading their width.
-- Only these owned widgets receive secret values. No Blizzard frame is written.
FluxRaidPrediction = {}
local Prediction = FluxRaidPrediction
local min, max = math.min, math.max
local TEXTURE = "Interface\\Buttons\\WHITE8X8"
local OVERHEAL_RATIOS = { 1.10, 1.25, 1.50 }
local OVERHEAL_COLORS = {
    { 0.80, 0.55, 0.32, 0.45 }, { 0.94, 0.76, 0.48, 0.50 },
    { 0.90, 0.58, 0.28, 0.60 }, { 0.80, 0.45, 0.22, 0.75 },
}

local function Secret(value)
    -- Native predicate must precede any nil comparison in older compat helpers.
    if issecretvalue then return issecretvalue(value) end
    return FluxRaidCompat and FluxRaidCompat.IsSecret and FluxRaidCompat.IsSecret(value) or false
end

local function Locked()
    return InCombatLockdown and InCombatLockdown()
end

local function Number(value)
    if Secret(value) or type(value) ~= "number" then return nil end
    return value
end

local function Read(fn, ...)
    if not fn then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
end

local function Present(value)
    return Secret(value) or value ~= nil
end

local function HideHealth(frame)
    local state = frame and frame._fluxPrediction
    if not state then return end
    for _, bar in ipairs(state.bars) do bar:Hide() end
    for _, indicator in ipairs(state.indicators) do indicator:Hide() end
end

local function NewBar(host, existing, color, level)
    local bar = existing or CreateFrame("StatusBar", nil, host)
    if bar.SetParent then bar:SetParent(host) end
    bar:SetStatusBarTexture(TEXTURE)
    bar:SetStatusBarColor(color[1], color[2], color[3], color[4])
    if bar.SetFrameLevel and host.GetFrameLevel then
        bar:SetFrameLevel(host:GetFrameLevel() + level)
    end
    if bar.EnableMouse then bar:EnableMouse(false) end
    bar:Hide()
    return bar
end

local function NewIndicator(host, point, color, offset)
    local region = host:CreateTexture(nil, "OVERLAY", nil, 7)
    region:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    region:SetPoint("TOP" .. point, host, "TOP" .. point, offset or 0, 0)
    region:SetPoint("BOTTOM" .. point, host, "BOTTOM" .. point, offset or 0, 0)
    region:SetWidth(2)
    region:Hide()
    return region
end

local function AnchorBar(bar, texture, backwards, width)
    bar:ClearAllPoints()
    if backwards then
        bar:SetPoint("TOPRIGHT", texture, "TOPRIGHT", 0, 0)
        bar:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", 0, 0)
    else
        bar:SetPoint("TOPLEFT", texture, "TOPRIGHT", 0, 0)
        bar:SetPoint("BOTTOMLEFT", texture, "BOTTOMRIGHT", 0, 0)
    end
    bar:SetWidth(width)
    if bar.SetReverseFill then bar:SetReverseFill(backwards) end
end

local function ConfigureOverflow(region, health, right)
    region:ClearAllPoints()
    local edge, target, offset = right and "LEFT" or "RIGHT", right and "RIGHT" or "LEFT", right and -7 or 7
    region:SetPoint("TOP" .. edge, health, "TOP" .. target, offset, 0)
    region:SetPoint("BOTTOM" .. edge, health, "BOTTOM" .. target, offset, 0)
    region:SetWidth(16)
    if region.SetAtlas then region:SetAtlas(right and "RaidFrame-Shield-Overshield" or "RaidFrame-Absorb-Overabsorb", false) end
    if region.SetVertexColor then region:SetVertexColor(1, 1, 1) end
    if region.SetBlendMode then region:SetBlendMode("ADD") end
end

local function ConfigureCalculator(calculator)
    local e = Enum or {}
    local incoming = e.UnitIncomingHealClampMode
    local absorb = e.UnitDamageAbsorbClampMode
    local healAbsorb = e.UnitHealAbsorbClampMode
    local processing = e.UnitHealAbsorbMode
    if calculator.SetIncomingHealClampMode and incoming then
        calculator:SetIncomingHealClampMode(incoming.MissingHealth)
    end
    if calculator.SetIncomingHealOverflowPercent then calculator:SetIncomingHealOverflowPercent(1) end
    if calculator.SetDamageAbsorbClampMode and absorb then
        calculator:SetDamageAbsorbClampMode(absorb.MissingHealth)
    end
    if calculator.SetHealAbsorbClampMode and healAbsorb then
        calculator:SetHealAbsorbClampMode(healAbsorb.CurrentHealth)
    end
    if calculator.SetHealAbsorbMode and processing then
        calculator:SetHealAbsorbMode(processing.ReducedByIncomingHeals)
    end
end

function Prediction.Setup(frame)
    if not frame or not frame.healthBar or Locked() then return false end
    local health = frame.healthBar
    local state = frame._fluxPrediction
    if not state then
        local host = CreateFrame("Frame", nil, health)
        host:SetAllPoints(health)
        if host.SetClipsChildren then host:SetClipsChildren(true) end
        if host.EnableMouse then host:EnableMouse(false) end
        if host.SetFrameLevel and health.GetFrameLevel then host:SetFrameLevel(health:GetFrameLevel() + 1) end
        state = { host = host }
        frame._fluxPrediction = state
        state.mine = NewBar(host, health.myHealPrediction, { 0.35, 1, 0.35, 0.55 }, 1)
        state.others = NewBar(host, health.otherHealPrediction, { 0.35, 1, 0.35, 0.55 }, 1)
        state.absorb = NewBar(host, health.totalAbsorb, { 0.8, 0.9, 1, 0.8 }, 2)
        local stripes=state.absorb:CreateTexture(nil,"OVERLAY")
        stripes:SetTexture("Interface\\RaidFrame\\Shield-Overlay")
        stripes:SetAllPoints(state.absorb:GetStatusBarTexture())
        if stripes.SetHorizTile then stripes:SetHorizTile(true) end
        if stripes.SetVertTile then stripes:SetVertTile(true) end
        state.absorbPattern=stripes
        state.healAbsorb = NewBar(host, health.healAbsorb, { 0.5, 0.08, 0.12, 0.8 }, 3)
        health.myHealPrediction, health.otherHealPrediction = state.mine, state.others
        health.totalAbsorb, health.healAbsorb = state.absorb, state.healAbsorb
        state.overheal = NewIndicator(host, "RIGHT", OVERHEAL_COLORS[1], -2)
        state.overAbsorb = NewIndicator(host, "RIGHT", { 0.65, 0.9, 1 }, 0)
        state.overHealAbsorb = NewIndicator(host, "LEFT", { 0.9, 0.15, 0.2 }, 0)
        state.bars = { state.mine, state.others, state.absorb, state.healAbsorb }
        state.indicators = { state.overheal, state.overAbsorb, state.overHealAbsorb }
        state.overhealLevels = { state.overheal }
        for i = 2, 4 do
            local region = NewIndicator(host, "RIGHT", OVERHEAL_COLORS[i], -2)
            state.overhealLevels[i] = region
            state.indicators[#state.indicators + 1] = region
        end
        if CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction then
            state.calculator = Read(CreateUnitHealPredictionCalculator)
            if state.calculator then
                ConfigureCalculator(state.calculator)
                state.overhealCalculators = {}
                for i, ratio in ipairs(OVERHEAL_RATIOS) do
                    local calculator = Read(CreateUnitHealPredictionCalculator)
                    if calculator and calculator.SetIncomingHealOverflowPercent then
                        ConfigureCalculator(calculator)
                        calculator:SetIncomingHealOverflowPercent(ratio)
                        state.overhealCalculators[i] = calculator
                    end
                end
            end
        end
    end
    -- Geometry is public and refreshed only out of combat. Fill texture edges
    -- subsequently move natively when health/prediction values are applied.
    local width = Number(health:GetWidth())
    if not width or width <= 0 then
        width = max(1, (FluxRaidVisuals and FluxRaidVisuals.FRAME_WIDTH or 98) - 2)
    end
    local fill = health:GetStatusBarTexture()
    AnchorBar(state.mine, fill, false, width)
    AnchorBar(state.others, state.mine:GetStatusBarTexture(), false, width)
    AnchorBar(state.absorb, state.others:GetStatusBarTexture(), false, width)
    AnchorBar(state.healAbsorb, fill, true, width)
    ConfigureOverflow(state.overAbsorb, health, true)
    ConfigureOverflow(state.overHealAbsorb, health, false)
    local power = frame.powerBar
    if power then
        if not state.cost then
            local host = CreateFrame("Frame", nil, power)
            host:SetAllPoints(power)
            if host.SetClipsChildren then host:SetClipsChildren(true) end
            if host.EnableMouse then host:EnableMouse(false) end
            if host.SetFrameLevel and power.GetFrameLevel then host:SetFrameLevel(power:GetFrameLevel() + 1) end
            state.cost = NewBar(host, nil, { 1, 1, 1, 0.3 }, 1)
        end
        AnchorBar(state.cost, power:GetStatusBarTexture(), true, width)
    end
    return true
end

local function Feed(bar, maximum, amount)
    if not Present(maximum) or not Present(amount) then bar:Hide(); return end
    bar:SetMinMaxValues(0, maximum)
    bar:SetValue(amount)
    bar:Show()
end

local function Indicator(region, value)
    if region.SetAlphaFromBoolean then
        region:SetAlphaFromBoolean(value, 1, 0)
        region:Show()
    elseif not Secret(value) then
        if value then region:Show() else region:Hide() end
    else
        region:Hide()
    end
end

local function NativeValues(unit, calculator, overflowCalculators)
    UnitGetDetailedHealPrediction(unit, "player", calculator)
    local _, mine, others, overheal = calculator:GetIncomingHeals()
    local absorb, overAbsorb = calculator:GetDamageAbsorbs()
    local healAbsorb, overHealAbsorb = calculator:GetHealAbsorbs()
    local levels = { overheal, false, false, false }
    -- Each owned calculator applies its public overflow boundary natively.
    -- Secret health/healing never participates in Lua arithmetic or branching.
    for i, overflowCalculator in ipairs(overflowCalculators or {}) do
        UnitGetDetailedHealPrediction(unit, "player", overflowCalculator)
        local _, _, _, clamped = overflowCalculator:GetIncomingHeals()
        levels[i + 1] = clamped
    end
    return calculator:GetMaximumHealth(), mine, others, absorb, healAbsorb,
        overheal, overAbsorb, overHealAbsorb, levels
end

local function LegacyValues(unit)
    local current = Number(Read(UnitHealth, unit))
    local maximum = Number(Read(UnitHealthMax, unit))
    if not current or not maximum or maximum <= 0 then return end
    local mine = Read(UnitGetIncomingHeals, unit, "player")
    local total = Read(UnitGetIncomingHeals, unit)
    local absorb = Read(UnitGetTotalAbsorbs, unit)
    local healAbsorb = Read(UnitGetTotalHealAbsorbs, unit)
    if Secret(mine) or Secret(total) or Secret(absorb) or Secret(healAbsorb) then return end
    mine, total = Number(mine) or 0, Number(total) or 0
    absorb, healAbsorb = Number(absorb) or 0, Number(healAbsorb) or 0
    -- Restriction-free clients use the same reductions and clamping as the
    -- calculator. Never turn an unreadable amount into invented health data.
    local visibleAbsorb = max(0, healAbsorb - total)
    local incoming = max(0, total - healAbsorb)
    local missing = max(0, maximum - current)
    local overheal = incoming > missing
    local levels = { overheal }
    for i, ratio in ipairs(OVERHEAL_RATIOS) do levels[i + 1] = current + incoming > maximum * ratio end
    incoming = min(incoming, missing)
    mine = min(mine, incoming)
    local others = max(0, incoming - mine)
    local absorbSpace = max(0, missing - incoming)
    return maximum, mine, others, min(absorb, absorbSpace), min(visibleAbsorb, current),
        overheal, absorb > absorbSpace, visibleAbsorb > current, levels
end

function Prediction.Update(frame)
    if not frame then return end
    local state = frame._fluxPrediction
    if not state then
        if not Prediction.Setup(frame) then return end
        state = frame._fluxPrediction
    end
    local unit = frame.displayedUnit or frame.unit
    if type(unit) ~= "string" or unit == "" or frame.unitExists == false
        or (frame.optionTable and frame.optionTable.displayHealPrediction == false) then
        HideHealth(frame)
        return
    end
    local ok, maximum, mine, others, absorb, healAbsorb, overheal, overAbsorb, overHealAbsorb, levels
    if state.calculator then
        ok, maximum, mine, others, absorb, healAbsorb, overheal, overAbsorb, overHealAbsorb, levels =
            pcall(NativeValues, unit, state.calculator, state.overhealCalculators)
    else
        ok, maximum, mine, others, absorb, healAbsorb, overheal, overAbsorb, overHealAbsorb, levels =
            pcall(LegacyValues, unit)
    end
    if not ok or not Present(maximum) then HideHealth(frame); return end
    Feed(state.mine, maximum, mine)
    Feed(state.others, maximum, others)
    Feed(state.absorb, maximum, absorb)
    Feed(state.healAbsorb, maximum, healAbsorb)
    for i, region in ipairs(state.overhealLevels) do Indicator(region, levels[i]) end
    Indicator(state.overAbsorb, overAbsorb)
    Indicator(state.overHealAbsorb, overHealAbsorb)
end

local function CastingSpell(unit)
    if UnitCastingInfo then
        local ok, name, _, _, _, _, _, _, _, spellID = pcall(UnitCastingInfo, unit)
        if ok and Present(name) then return spellID end
    end
    if UnitChannelInfo then
        local ok, name, _, _, _, _, _, _, spellID = pcall(UnitChannelInfo, unit)
        if ok and Present(name) then return spellID end
    end
end

function Prediction.UpdatePowerCost(frame)
    local state = frame and frame._fluxPrediction
    local bar = state and state.cost
    if not bar then return end
    local unit = frame.displayedUnit or frame.unit
    if type(unit) ~= "string" or unit == "" or frame.unitExists == false
        or (frame.optionTable and frame.optionTable.displayPowerBar == false) then bar:Hide(); return end
    local spellID = CastingSpell(unit)
    if Secret(spellID) or type(spellID) ~= "number" then bar:Hide(); return end
    local powerType = Number(Read(UnitPowerType, unit))
    if powerType == nil then bar:Hide(); return end
    local costAPI = C_Spell and C_Spell.GetSpellPowerCost or GetSpellPowerCost
    local costs = Read(costAPI, spellID)
    if Secret(costs) or type(costs) ~= "table" or (issecrettable and issecrettable(costs)) then bar:Hide(); return end
    for _, entry in ipairs(costs) do
        if not Secret(entry) and type(entry) == "table" and not (issecrettable and issecrettable(entry)) then
            local kind, required, amount = entry.type, entry.hasRequiredAura, entry.cost
            if not Secret(kind) and not Secret(required) and kind == powerType and required ~= false and Present(amount) then
                local maximum = Read(UnitPowerMax, unit, powerType)
                Feed(bar, maximum, amount)
                return
            end
        end
    end
    bar:Hide()
end

function Prediction.Clear(frame)
    HideHealth(frame)
    local state = frame and frame._fluxPrediction
    if state and state.cost then state.cost:Hide() end
end
