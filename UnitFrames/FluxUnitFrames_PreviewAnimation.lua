local _, ns = ...
local UF = ns.UnitFrames

local DURATION = 4
local PAINT_INTERVAL = 1 / 15

local function Clear(driver)
    local run = driver.run
    driver.run = nil
    driver:SetScript("OnUpdate", nil)
    if run and run.restore then run.restore() end
end

local function Stop(driver)
    Clear(driver)
    driver:Hide()
end

local function Update(driver, elapsed)
    local run = driver.run
    local now = math.min(DURATION, run.elapsed + elapsed)
    run.elapsed = now
    if now < DURATION and now < run.nextPaint then return end
    run.nextPaint = now + PAINT_INTERVAL
    run.step(now / DURATION, now)
    if now == DURATION and driver.run == run then
        Stop(driver)
        if run.finish then run.finish() end
    end
end

function UF.PlayOptionsPreviewAnimation(owner, step, finish, restore)
    if not owner:IsVisible() then return end
    local driver = owner._fluxPreviewAnimationDriver
    if not driver then
        driver = CreateFrame("Frame", nil, owner)
        driver:SetScript("OnHide", Clear)
        owner._fluxPreviewAnimationDriver = driver
    end
    if driver.run then Stop(driver) end
    driver.run = { elapsed = 0, nextPaint = PAINT_INTERVAL, step = step, finish = finish, restore = restore }
    driver:SetScript("OnUpdate", Update)
    driver:Show()
    step(0, 0)
    return true
end

function UF.StopOptionsPreviewAnimation(owner)
    local driver = owner._fluxPreviewAnimationDriver
    if driver and driver.run then Stop(driver) end
end

local function GetCompactHealthMode()
    if FluxRaidVisuals.UseOwnRaidSettings and FluxRaidVisuals.UseOwnRaidSettings() then
        local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
        return db and db.healthText or "perc"
    end
    local mode = C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("raidFramesHealthText")
    return mode and mode ~= "" and mode or "perc"
end

local function PaintPartyBar(bar, value)
    bar:SetValue(value)
    if bar.Percent and bar.Percent:IsShown() then bar.Percent:SetFormattedText("%.0f%%", value) end
    if bar.Value and bar.Value:IsShown() then bar.Value:SetFormattedText("%.0f / 10000", value * 100) end
end

local function AnimateGroupSample(sample, amount, compactHealthMode)
    local hp = math.max(1, sample.hp - amount * 32)
    local power = math.max(0, (sample.powerValue or 0) - amount * 28)
    if compactHealthMode then
        sample.health:SetValue(hp)
        FluxRaidVisuals.SetHealthStatus(sample.frame, compactHealthMode, math.floor(hp * 1000), 100000, hp, true, false)
        if sample.power then sample.power:SetValue(power) end
    else
        PaintPartyBar(sample.health, hp)
        if sample.power then PaintPartyBar(sample.power, power) end
    end
    if sample.aura then sample.aura:SetAlpha(sample.alpha * (1 - amount * .65)) end
end

function UF.PlayOptionsGroupAnimation(root, members, count, compact, onFinish)
    if not root:IsVisible() then return end
    UF.StopOptionsPreviewAnimation(root)
    local samples = {}
    local healthMode = compact and GetCompactHealthMode() or nil
    for i = 1, count do
        local frame = members[i]
        if frame and frame:IsVisible() then
            local state = frame._fluxPreviewState
            local eligible = compact and frame._fluxOptionsPreview and state and state ~= 6 and state ~= 7 and state ~= 8
                or not compact and frame._fluxPartyPreview and frame._fluxPreviewLayerParent == root and not frame._fluxPartyStatusText
            if eligible then
                local health = compact and frame.healthBar or frame.Health
                local power = compact and frame.powerBar or frame.Power
                if power and not power:IsShown() then power = nil end
                local aura = frame._fluxAuraDebuff and frame._fluxAuraDebuff[1]
                if not (aura and aura:IsShown()) then aura = frame._fluxAuraBuff and frame._fluxAuraBuff[1] end
                if aura and not aura:IsShown() then aura = nil end
                samples[#samples + 1] = {
                    frame = frame, health = health, hp = health:GetValue(),
                    power = power, powerValue = power and power:GetValue(),
                    aura = aura, alpha = aura and aura:GetAlpha(),
                }
                if #samples == 3 then break end
            end
        end
    end
    if #samples == 0 then return end
    local castFrame = not compact and samples[1].frame
    local cast = castFrame and ns.CastBar and ns.CastBar.PaintOptionsSample(castFrame, true, "Healing Wave")
    local function Paint(progress)
        local amount = progress < .45 and (progress / .45) or ((1 - progress) / .55)
        amount = amount * amount * (3 - 2 * amount)
        for _, sample in ipairs(samples) do AnimateGroupSample(sample, amount, healthMode) end
        if cast then ns.CastBar.SetOptionsSampleProgress(cast, progress) end
    end
    local function Restore()
        if cast then ns.CastBar.PaintOptionsSample(castFrame, false) end
        Paint(0)
    end
    return UF.PlayOptionsPreviewAnimation(root, Paint, onFinish, Restore)
end
