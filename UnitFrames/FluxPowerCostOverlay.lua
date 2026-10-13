-- UnitFrames/FluxPowerCostOverlay.lua
-- HUD clients: cast-cost segment (ManaCostPredictionBar) and BuilderSpender spend/gain flash.
-- Era, Anniversary, and Mists unit frames do not mount either widget.
local addonName, ns = ...
ns.PowerCostOverlay = ns.PowerCostOverlay or {}
local PCO = ns.PowerCostOverlay
local API = ns.API
local UF = ns.UnitFrames

local TEXTURE_BAR = "Interface\\TargetingFrame\\UI-StatusBar"
local TEXTURE_GLOW = "Interface\\TargetingFrame\\UI-StatusBar-Glow"
local LOSS_TIME_END = 0.6
local LOSS_GLOW_FADE = 0.25
local LOSS_BAR_FADE = 0.4
local GAIN_TIME_END = 0.5

local function UsesHud()
    return UF and UF.UsesHudUnitBars and UF.UsesHudUnitBars()
end

local function IsSecretValue(value)
    return API and API.IsSecretValue and API.IsSecretValue(value)
end

local _issecrettable = issecrettable

local function SafeCostTableLength(t)
    if not t then return 0 end
    if _issecrettable and _issecrettable(t) then return 0 end
    if API.CanAccessValue and not API.CanAccessValue(t) then return 0 end
    local ok, n = pcall(function() return #t end)
    return ok and n or 0
end

local function SafeNumber(value)
    if API.CoerceNumberLoose then
        return API.CoerceNumberLoose(value, 0)
    end
    return API.SafeGetNumber(value, 0)
end

local function TryLayoutWidth(region)
    if not region then return nil end
    local ok, w = pcall(function()
        local x = region:GetWidth()
        return math.min(math.max(x + 0, 0), 100000)
    end)
    if ok and type(w) == "number" and w == w and w > 0 then
        return w
    end
    return nil
end

local function TryLayoutHeight(region)
    if not region then return 1 end
    local ok, h = pcall(function()
        return math.max(1, region:GetHeight() + 0)
    end)
    if ok and type(h) == "number" and h > 0 then
        return h
    end
    return 1
end

local function CVarEnabled(name)
    if not GetCVar then return true end
    local raw = GetCVar(name)
    if raw == nil or raw == "" then return true end
    if GetCVarBool then
        return GetCVarBool(name) and true or false
    end
    return raw == "1"
end

local function HasSpellCostAPI()
    return C_Spell and C_Spell.GetSpellPowerCost
end

local function CostFromTable(spellID, matchType, unit)
    if not HasSpellCostAPI() or not spellID or not unit then return 0 end
    if IsSecretValue(spellID) then return 0 end
    if API.CanAccessValue and not API.CanAccessValue(spellID) then return 0 end

    local ok, costTable = pcall(C_Spell.GetSpellPowerCost, spellID)
    if not ok or not costTable then return 0 end

    local tableLen = SafeCostTableLength(costTable)
    if tableLen == 0 then return 0 end

    local checkAura = tableLen > 1
    for _, entry in next, costTable do
        local okRow, costAmt = pcall(function()
            if checkAura and not entry.hasRequiredAura then return nil end
            local want = matchType
            if want == nil then
                want = select(1, UnitPowerType(unit))
            end
            if entry.type ~= want then return nil end
            local c = entry.cost
            if c == nil then return nil end
            if IsSecretValue(c) then return c end
            local n = tonumber(c)
            if type(n) ~= "number" then
                local addedOk, added = pcall(function() return c + 0 end)
                if addedOk and type(added) == "number" then
                    n = added
                end
            end
            if type(n) == "number" and n > 0 then return n end
            return nil
        end)
        if okRow and costAmt ~= nil and (IsSecretValue(costAmt) or (type(costAmt) == "number" and costAmt > 0)) then
            return costAmt
        end
    end
    return 0
end

local function GetSpellCost(spellID, unit)
    return CostFromTable(spellID, nil, unit)
end

local function GetSpellCostMana(spellID, unit)
    return CostFromTable(spellID, 0, unit)
end

-- ---------------------------------------------------------------------------
-- Prediction segment
-- ---------------------------------------------------------------------------
function PCO.CreateOverlay(powerBar)
    if not powerBar or powerBar.CostOverlay then return end
    local seg = powerBar:CreateTexture(nil, "OVERLAY", nil, 3)
    seg:SetTexture(TEXTURE_BAR)
    seg:SetWidth(1)
    seg:Hide()
    powerBar.CostOverlay = seg
    return seg
end

function PCO.ApplySegmentArt(bar)
    local seg = bar and bar.CostOverlay
    if not seg or not UF then return end
    local info = bar._fluxPowerInfo
    local atlas = UF.GetPowerStatusAtlas and UF.GetPowerStatusAtlas(info)
    if atlas and seg.SetAtlas then
        seg:SetAtlas(atlas)
    else
        seg:SetTexture(TEXTURE_BAR)
    end
    if UF.GetPowerPredictionColor then
        local r, g, b, a = UF.GetPowerPredictionColor(info)
        seg:SetVertexColor(r, g, b, a or 1)
    end
end

function PCO.UpdateOverlayColor(powerBar, r, g, b)
    if not powerBar or not powerBar.CostOverlay then return end
    if r == 0.5 and g == 0.5 and b == 0.5 then
        powerBar.CostOverlay:SetVertexColor(0.5, 0.5, 0.5, 1)
        return
    end
    PCO.ApplySegmentArt(powerBar)
end

local function CostActive(cost)
    if cost == nil then return false end
    if IsSecretValue(cost) then return true end
    return type(cost) == "number" and cost > 0
end

local function ImmediateInterp()
    return Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate
end

-- Hidden meter turns a secret cost into a pixel width via SetValue, with no Lua math.
local function EnsureCostMeter(bar)
    if bar._fluxCostMeter then return bar._fluxCostMeter end
    local meter = CreateFrame("StatusBar", nil, bar)
    meter:SetAllPoints(bar)
    meter:SetAlpha(0)
    meter:SetStatusBarTexture(TEXTURE_BAR)
    meter:Hide()
    bar._fluxCostMeter = meter
    return meter
end

local function EnsurePowerGhost(bar)
    if bar.PowerGhost then return bar.PowerGhost end
    local parent = bar:GetParent() or bar
    local ghost = CreateFrame("StatusBar", nil, parent)
    ghost:SetAllPoints(bar)
    ghost:SetFrameLevel(math.max(0, (bar:GetFrameLevel() or 1) - 1))
    ghost:SetAlpha(0)
    ghost:SetStatusBarTexture(TEXTURE_BAR)
    bar.PowerGhost = ghost
    return ghost
end

local function MatchGhostArt(bar, ghost)
    if bar._fluxBarAtlas and ghost.SetStatusBarTexture then
        ghost:SetStatusBarTexture(bar._fluxBarAtlas)
        ghost:SetStatusBarColor(1, 1, 1)
    else
        ghost:SetStatusBarTexture(TEXTURE_BAR)
        local r, g, b = bar:GetStatusBarColor()
        ghost:SetStatusBarColor(r or 1, g or 1, b or 1)
    end
end

local function CommitPowerGhost(bar)
    local ghost = EnsurePowerGhost(bar)
    local value = bar._fluxGhostValue
    local maxValue = bar._fluxGhostMax
    if value == nil or maxValue == nil then return end
    MatchGhostArt(bar, ghost)
    ghost:Show()
    pcall(function()
        ghost:SetMinMaxValues(0, maxValue)
    end)
    local interp = ImmediateInterp()
    if interp then
        local ok = pcall(ghost.SetValue, ghost, value, interp)
        if ok then return end
    end
    pcall(ghost.SetValue, ghost, value)
end

local function StopBarFeedback(bar)
    if not bar then return end
    bar._fluxCastFinish = nil
    bar._fluxGhostHolding = false
    bar._fluxGhostSeq = (bar._fluxGhostSeq or 0) + 1
    bar._fluxPrevFillW = nil
    local f = bar.FeedbackFrame
    if not f then return end
    f.updatingGain = false
    f.updatingLoss = false
    f.secretPlaying = false
    if f.SecretLossAnim and f.SecretLossAnim.Stop then
        pcall(function() f.SecretLossAnim:Stop() end)
    end
    if f.SecretBarAnim and f.SecretBarAnim.Stop then
        pcall(function() f.SecretBarAnim:Stop() end)
    end
    if f.GainGlowTexture then f.GainGlowTexture:Hide() end
    if f.LossGlowTexture then f.LossGlowTexture:Hide() end
    if f.BarTexture then f.BarTexture:Hide() end
    f:Hide()
end

local function HideSegment(bar)
    if bar and bar.CostOverlay then
        bar.CostOverlay:Hide()
    end
    if bar then
        bar._fluxPredictedCost = nil
        bar._fluxPredictionShortened = false
    end
end

local function ClampCostWidth(bar, fill, width, shortened)
    local bw = TryLayoutWidth(bar)
    local fw = TryLayoutWidth(fill)
    if type(width) ~= "number" or width ~= width or width <= 0 then
        return nil
    end
    local cap = width
    if bw and bw > 0 then
        cap = math.min(cap, bw)
    end
    if shortened then
        if bw and fw and fw >= 0 then
            cap = math.min(cap, math.max(0, bw - fw))
        end
    elseif fw and fw > 0 then
        cap = math.min(cap, fw)
    end
    if cap < 1 then
        return nil
    end
    return cap
end

local function PlaceCostSegment(bar, seg, fill, width)
    local cap = ClampCostWidth(bar, fill, width, bar._fluxPredictionShortened)
    if not cap then
        seg:Hide()
        return
    end
    seg:ClearAllPoints()
    if bar._fluxPredictionShortened then
        seg:SetPoint("TOPLEFT", fill, "TOPRIGHT", 0, 0)
        seg:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT", 0, 0)
    else
        seg:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)
        seg:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)
    end
    seg:SetWidth(cap)
    seg:Show()
end

function PCO.RefreshPrediction(bar)
    local seg = bar and bar.CostOverlay
    if not seg then return end
    local cost = bar._fluxPredictedCost
    local maxPower = bar._fluxPredictMax
    if not CostActive(cost) or maxPower == nil then
        seg:Hide()
        return
    end
    local fill = bar:GetStatusBarTexture()
    if not fill then
        seg:Hide()
        return
    end

    if not UsesHud() or type(cost) == "number" then
        local costN = (type(cost) == "number") and cost or SafeNumber(cost)
        local maxN = (type(maxPower) == "number") and maxPower or SafeNumber(maxPower)
        local bw = TryLayoutWidth(bar)
        if not bw or not maxN or maxN <= 0 or not costN or costN <= 0 then
            seg:Hide()
            return
        end
        if not UsesHud() then
            seg:SetTexture(TEXTURE_BAR)
        end
        PCO.ApplySegmentArt(bar)
        if not UsesHud() then
            local r, g, b = bar:GetStatusBarColor()
            r = (type(r) == "number") and r or 0.25
            g = (type(g) == "number") and g or 0.5
            b = (type(b) == "number") and b or 1
            if r > 0.95 and g > 0.95 and b > 0.95 and bar._fluxPowerInfo then
                r = bar._fluxPowerInfo.r or 0.25
                g = bar._fluxPowerInfo.g or 0.5
                b = bar._fluxPowerInfo.b or 1
            end
            seg:SetVertexColor(r * 0.35, g * 0.35, b * 0.35, 1)
        end
        PlaceCostSegment(bar, seg, fill, (costN / maxN) * bw)
        return
    end

    local meter = EnsureCostMeter(bar)
    meter:Show()
    local width
    local sized = pcall(function()
        meter:SetMinMaxValues(0, maxPower)
        local interp = ImmediateInterp()
        if interp then
            meter:SetValue(cost, interp)
        else
            meter:SetValue(cost)
        end
        width = meter:GetStatusBarTexture():GetWidth() + 0
    end)
    if not sized or type(width) ~= "number" then
        seg:Hide()
        return
    end
    PCO.ApplySegmentArt(bar)
    PlaceCostSegment(bar, seg, fill, width)
end

-- ---------------------------------------------------------------------------
-- BuilderSpender flash (loss 0.6s, gain 0.5s). 10% threshold is measured in fill width.
-- ---------------------------------------------------------------------------
local function EndFeedbackGain(f)
    f.GainGlowTexture:Hide()
    f.updatingGain = false
end

local function EndFeedbackLoss(f)
    f.LossGlowTexture:Hide()
    f.BarTexture:Hide()
    f.updatingLoss = false
end

local function FeedbackOnUpdate(f)
    if f.updatingGain then
        local elapsed = GetTime() - f.animGainStartTime
        if elapsed > GAIN_TIME_END then
            EndFeedbackGain(f)
        else
            local t = elapsed / GAIN_TIME_END
            local current = f.gainOld + (f.gainNew - f.gainOld) * t
            local width = f.gainNew - current
            if width < 0.5 then
                f.GainGlowTexture:Hide()
                f.updatingGain = false
            else
                local barW = math.max(f.barW or 1, 1)
                f.GainGlowTexture:ClearAllPoints()
                f.GainGlowTexture:SetPoint("TOPLEFT", f, "TOPLEFT", current, 0)
                f.GainGlowTexture:SetHeight(f.barH or 1)
                f.GainGlowTexture:SetWidth(width)
                f.GainGlowTexture:SetTexCoord(current / barW, f.gainNew / barW, 0, 1)
                f.GainGlowTexture:Show()
            end
        end
    end
    if f.updatingLoss then
        local elapsed = GetTime() - f.animLossStartTime
        if elapsed > LOSS_TIME_END then
            EndFeedbackLoss(f)
        else
            local glowAlpha
            if elapsed < LOSS_GLOW_FADE then
                glowAlpha = (elapsed / LOSS_GLOW_FADE) * 0.75
            else
                local span = LOSS_TIME_END - LOSS_GLOW_FADE
                glowAlpha = 0.75 * (1 - ((elapsed - LOSS_GLOW_FADE) / span))
            end
            f.LossGlowTexture:SetAlpha(glowAlpha)
            local barAlpha = 1
            if elapsed >= LOSS_BAR_FADE then
                barAlpha = 1 - ((elapsed - LOSS_BAR_FADE) / (LOSS_TIME_END - LOSS_BAR_FADE))
            end
            f.BarTexture:SetAlpha(barAlpha)
        end
    end
    if not f.updatingGain and not f.updatingLoss and not f.secretPlaying then
        f:Hide()
    end
end

local function EnsureFeedback(bar)
    if bar.FeedbackFrame then return bar.FeedbackFrame end
    local f = CreateFrame("Frame", nil, bar)
    f:SetAllPoints(bar)
    -- Under the amount / percent text (TextOverlay is bar level + 20).
    f:SetFrameLevel(bar:GetFrameLevel() + 4)
    local barTex = f:CreateTexture(nil, "ARTWORK", nil, 0)
    barTex:SetTexture(TEXTURE_BAR)
    barTex:Hide()
    local loss = f:CreateTexture(nil, "ARTWORK", nil, 1)
    loss:SetTexture(TEXTURE_GLOW)
    loss:SetBlendMode("ADD")
    loss:Hide()
    local gain = f:CreateTexture(nil, "ARTWORK", nil, 1)
    gain:SetTexture(TEXTURE_GLOW)
    gain:SetBlendMode("ADD")
    gain:SetAlpha(0.75)
    gain:Hide()
    f.BarTexture = barTex
    f.LossGlowTexture = loss
    f.GainGlowTexture = gain
    f:SetScript("OnUpdate", FeedbackOnUpdate)
    f:Hide()
    bar.FeedbackFrame = f
    return f
end

local function SyncFeedbackArt(bar, f)
    if bar._fluxBarAtlas and f.BarTexture.SetAtlas then
        f.BarTexture:SetAtlas(bar._fluxBarAtlas)
        f.BarTexture:SetVertexColor(1, 1, 1, 1)
    else
        f.BarTexture:SetTexture(TEXTURE_BAR)
        local r, g, b = bar:GetStatusBarColor()
        r = SafeNumber(r)
        g = SafeNumber(g)
        b = SafeNumber(b)
        if r == 0 and g == 0 and b == 0 then
            r, g, b = 1, 1, 1
        end
        f.BarTexture:SetVertexColor(r, g, b, 1)
    end
end

local function PlaceSlice(tex, parent, left, width, height, texMin, texMax, alpha)
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", parent, "TOPLEFT", left, 0)
    tex:SetWidth(math.max(width, 0.5))
    tex:SetHeight(height)
    tex:SetTexCoord(texMin, texMax, 0, 1)
    tex:SetAlpha(alpha)
    tex:Show()
end

local function StopSecretGlow(f)
    if not f then return end
    f.secretPlaying = false
    if f.SecretLossAnim and f.SecretLossAnim:IsPlaying() then
        f.SecretLossAnim:Stop()
    end
    if f.SecretBarAnim and f.SecretBarAnim:IsPlaying() then
        f.SecretBarAnim:Stop()
    end
end

local function SecretGlowFinished(f)
    if not f then return end
    if (f.SecretLossAnim and f.SecretLossAnim:IsPlaying()) or (f.SecretBarAnim and f.SecretBarAnim:IsPlaying()) then
        return
    end
    f.secretPlaying = false
    if f.LossGlowTexture then f.LossGlowTexture:Hide() end
    if f.BarTexture then f.BarTexture:Hide() end
    if not f.updatingGain and not f.updatingLoss then
        f:Hide()
    end
end

local function EnsureSecretAnims(f)
    if f.SecretLossAnim then return end

    local function alpha(group, childKey, fromAlpha, toAlpha, duration, order)
        local anim = group:CreateAnimation("Alpha")
        anim:SetChildKey(childKey)
        anim:SetOrder(order)
        anim:SetDuration(duration)
        anim:SetFromAlpha(fromAlpha)
        anim:SetToAlpha(toAlpha)
        return anim
    end

    local lossAnim = f:CreateAnimationGroup()
    lossAnim:SetToFinalAlpha(true)
    alpha(lossAnim, "LossGlowTexture", 0, 0.75, 0.25, 1)
    alpha(lossAnim, "LossGlowTexture", 0.75, 0, 0.35, 2)
    lossAnim:SetScript("OnFinished", function()
        SecretGlowFinished(f)
    end)
    f.SecretLossAnim = lossAnim

    local barAnim = f:CreateAnimationGroup()
    barAnim:SetToFinalAlpha(true)
    alpha(barAnim, "BarTexture", 1, 1, 0.4, 1)
    alpha(barAnim, "BarTexture", 1, 0, 0.2, 2)
    barAnim:SetScript("OnFinished", function()
        SecretGlowFinished(f)
    end)
    f.SecretBarAnim = barAnim
end

local function AnchorSecretSlice(tex, fill, anchor)
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", fill, "TOPRIGHT", 0, 0)
    tex:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT", 0, 0)
    tex:SetPoint("RIGHT", anchor, "RIGHT", 0, 0)
end

local function ShowSecretSpend(bar)
    if not CVarEnabled("showSpenderFeedback") then return end
    local fill = bar:GetStatusBarTexture()
    local anchor = bar._fluxSpendAnchor
    if not fill or not anchor or not bar._fluxSpendSnapOK then return end

    local f = EnsureFeedback(bar)
    StopSecretGlow(f)
    f.updatingGain = false
    f.updatingLoss = false
    SyncFeedbackArt(bar, f)
    f.LossGlowTexture:SetTexture(TEXTURE_GLOW)
    f.LossGlowTexture:SetBlendMode("ADD")
    AnchorSecretSlice(f.LossGlowTexture, fill, anchor)
    AnchorSecretSlice(f.BarTexture, fill, anchor)
    f.LossGlowTexture:SetAlpha(0)
    f.BarTexture:SetAlpha(1)
    f.LossGlowTexture:Show()
    f.BarTexture:Show()
    f.secretPlaying = true
    f:Show()
    EnsureSecretAnims(f)
    f.SecretLossAnim:Play()
    f.SecretBarAnim:Play()
end

function PCO.BeforePowerApplied(bar)
    if not bar or bar.isStaggerBar then return end
    local fill = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if not fill then return end
    if not bar._fluxSpendAnchor then
        local anchor = CreateFrame("Frame", nil, bar)
        anchor:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        anchor:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        anchor:SetWidth(1)
        bar._fluxSpendAnchor = anchor
    end
    local ok = pcall(function()
        bar._fluxSpendAnchor:SetWidth(fill:GetWidth())
    end)
    bar._fluxSpendSnapOK = ok and true or false
end

local function StartFeedback(bar, oldW, newW, force)
    local bw = TryLayoutWidth(bar)
    if not bw or bw <= 0 then return end
    local delta = math.abs(newW - oldW) / bw
    if delta < 0.004 then return end
    if not force and delta <= 0.1 then return end

    local gaining = newW > oldW
    if gaining and not CVarEnabled("showBuilderFeedback") then return end
    if not gaining and not CVarEnabled("showSpenderFeedback") then return end

    local f = EnsureFeedback(bar)
    StopSecretGlow(f)
    local height = TryLayoutHeight(bar)
    f.barW = bw
    f.barH = height
    SyncFeedbackArt(bar, f)

    if gaining then
        f.updatingGain = true
        f.gainOld = oldW
        f.gainNew = newW
        f.animGainStartTime = GetTime()
        f.GainGlowTexture:SetAlpha(0.75)
        f:Show()
    else
        local left = newW
        local width = oldW - newW
        if width < 0.5 then return end
        local texMin = math.max(0, newW / bw)
        local texMax = math.min(1, oldW / bw)
        PlaceSlice(f.LossGlowTexture, f, left, width, height, texMin, texMax, 0)
        PlaceSlice(f.BarTexture, f, left, width, height, texMin, texMax, 1)
        f.updatingLoss = true
        f.animLossStartTime = GetTime()
        f:Show()
    end
end

local function ShowSecretSpendBetween(bar)
    if not CVarEnabled("showSpenderFeedback") then return end
    local fill = bar:GetStatusBarTexture()
    local ghost = bar.PowerGhost
    local ghostFill = ghost and ghost:GetStatusBarTexture()
    if not fill or not ghostFill then return end

    local f = EnsureFeedback(bar)
    StopSecretGlow(f)
    f.updatingGain = false
    f.updatingLoss = false
    SyncFeedbackArt(bar, f)
    f.LossGlowTexture:SetTexture(TEXTURE_GLOW)
    f.LossGlowTexture:SetBlendMode("ADD")
    -- Spend: current fill is left of the previous fill. A gain collapses this region.
    AnchorSecretSlice(f.LossGlowTexture, fill, ghostFill)
    AnchorSecretSlice(f.BarTexture, fill, ghostFill)
    f.LossGlowTexture:SetAlpha(0)
    f.BarTexture:SetAlpha(1)
    f.LossGlowTexture:Show()
    f.BarTexture:Show()
    f.secretPlaying = true
    f:Show()
    EnsureSecretAnims(f)
    f.SecretLossAnim:Play()
    f.SecretBarAnim:Play()
end

function PCO.AfterPowerApplied(bar, unit, displayValue, maxValue)
    if not bar then return end
    if bar.isStaggerBar then
        if UsesHud() then
            PCO.RefreshPrediction(bar)
        end
        return
    end
    local enabled = not FluxUnitFrames_IsFeatureEnabled or FluxUnitFrames_IsFeatureEnabled("powerCostOverlay")
    if not enabled then
        HideSegment(bar)
        bar._fluxSpendFlashUntil = nil
        return
    end

    if displayValue ~= nil then
        bar._fluxGhostValue = displayValue
    end
    if maxValue ~= nil then
        bar._fluxGhostMax = maxValue
    end

    if unit and UnitGUID then
        local guid = UnitGUID(unit)
        if bar._fluxFeedbackGUID ~= guid then
            bar._fluxFeedbackGUID = guid
            bar._fluxPrevFillW = nil
            bar._fluxGhostPrimed = nil
            bar._fluxCastFinish = nil
            bar._fluxCastUnitGUID = nil
            bar._fluxGhostSeq = (bar._fluxGhostSeq or 0) + 1
            StopBarFeedback(bar)
        end
    end

    local castFinish = bar._fluxCastFinish and bar._fluxCastUnitGUID == (unit and UnitGUID and UnitGUID(unit) or nil)
    bar._fluxCastFinish = nil

    if not bar._fluxGhostPrimed then
        bar._fluxGhostPrimed = true
        CommitPowerGhost(bar)
        PCO.RefreshPrediction(bar)
        return
    end

    local fillW
    local okW, w = pcall(function()
        local fill = bar:GetStatusBarTexture()
        if not fill then return nil end
        return fill:GetWidth() + 0
    end)
    if okW and type(w) == "number" and w == w and w >= 0 then
        fillW = w
    end

    local prev = bar._fluxPrevFillW
    bar._fluxPrevFillW = fillW
    local readable = type(prev) == "number" and type(fillW) == "number"
    local bw = readable and TryLayoutWidth(bar) or nil
    local bigChange = bw and bw > 0 and math.abs(fillW - prev) / bw > 0.1

    local function holdGhost()
        bar._fluxGhostHolding = true
        bar._fluxGhostSeq = (bar._fluxGhostSeq or 0) + 1
        local seq = bar._fluxGhostSeq
        if C_Timer and C_Timer.After then
            C_Timer.After(LOSS_TIME_END, function()
                if bar._fluxGhostSeq ~= seq then return end
                bar._fluxGhostHolding = false
                CommitPowerGhost(bar)
            end)
        else
            bar._fluxGhostHolding = false
            CommitPowerGhost(bar)
        end
    end

    local function commitGhostLater()
        if bar._fluxGhostHolding then return end
        bar._fluxGhostSeq = (bar._fluxGhostSeq or 0) + 1
        local seq = bar._fluxGhostSeq
        if C_Timer and C_Timer.After then
            -- After spell events in this frame, so a finished cast still sees the old ghost.
            C_Timer.After(0, function()
                if bar._fluxGhostSeq ~= seq or bar._fluxGhostHolding then return end
                CommitPowerGhost(bar)
            end)
        else
            CommitPowerGhost(bar)
        end
    end

    local watchedUnit = unit == "target" or unit == "targettarget" or unit == "focus" or unit == "focustarget"
    if castFinish then
        -- Finished cast (instant or timed). Flash even if the texture width did not change much.
        if not UsesHud() then
            if readable and math.abs(fillW - prev) > 0.5 then
                StartFeedback(bar, prev, fillW, true)
            end
            commitGhostLater()
        else
            if bigChange then
                StartFeedback(bar, prev, fillW)
            else
                ShowSecretSpendBetween(bar)
            end
            holdGhost()
        end
    elseif readable and bigChange and not watchedUnit then
        StartFeedback(bar, prev, fillW)
        commitGhostLater()
    else
        commitGhostLater()
    end
    PCO.RefreshPrediction(bar)
end

local function SafeRegisterUnit(watcher, event, unit)
    pcall(function() watcher:RegisterUnitEvent(event, unit) end)
end

function PCO.DisableForFrame(frame)
    if not frame then return end
    if frame.PowerCostWatcher then
        frame.PowerCostWatcher:UnregisterAllEvents()
        frame.PowerCostWatcher:SetScript("OnEvent", nil)
        frame.PowerCostWatcher = nil
    end
    local function hideBar(bar)
        if not bar then return end
        HideSegment(bar)
        if bar.FeedbackFrame then
            bar.FeedbackFrame.updatingGain = false
            bar.FeedbackFrame.updatingLoss = false
            bar.FeedbackFrame:Hide()
            if bar.FeedbackFrame.GainGlowTexture then bar.FeedbackFrame.GainGlowTexture:Hide() end
            if bar.FeedbackFrame.LossGlowTexture then bar.FeedbackFrame.LossGlowTexture:Hide() end
            if bar.FeedbackFrame.BarTexture then bar.FeedbackFrame.BarTexture:Hide() end
        end
        bar._fluxPrevFillW = nil
    end
    hideBar(frame.Power)
    hideBar(frame.AdditionalPower)
end

function PCO.Initialize(frame)
    if not frame or not frame.Power or not frame.unit then return end
    local enabled = not FluxUnitFrames_IsFeatureEnabled or FluxUnitFrames_IsFeatureEnabled("powerCostOverlay")
    if not enabled then
        PCO.DisableForFrame(frame)
        return
    end

    PCO.CreateOverlay(frame.Power)
    if frame.AdditionalPower then
        PCO.CreateOverlay(frame.AdditionalPower)
    end

    if frame.PowerCostWatcher then
        frame.PowerCostWatcher:UnregisterAllEvents()
        frame.PowerCostWatcher:SetScript("OnEvent", nil)
        frame.PowerCostWatcher = nil
    end

    local unit = frame.unit
    local watcher = CreateFrame("Frame")
    watcher.unit = unit
    watcher.parentFrame = frame

    SafeRegisterUnit(watcher, "UNIT_SPELLCAST_START", unit)
    SafeRegisterUnit(watcher, "UNIT_SPELLCAST_STOP", unit)
    SafeRegisterUnit(watcher, "UNIT_SPELLCAST_FAILED", unit)
    SafeRegisterUnit(watcher, "UNIT_SPELLCAST_INTERRUPTED", unit)
    SafeRegisterUnit(watcher, "UNIT_SPELLCAST_SUCCEEDED", unit)
    SafeRegisterUnit(watcher, "UNIT_SPELLCAST_CHANNEL_START", unit)
    SafeRegisterUnit(watcher, "UNIT_SPELLCAST_CHANNEL_STOP", unit)
    SafeRegisterUnit(watcher, "UNIT_POWER_UPDATE", unit)
    SafeRegisterUnit(watcher, "UNIT_DISPLAYPOWER", unit)

    local function CurrentCastSpell(which)
        which = which or unit
        if not which or not UnitExists(which) then return nil end
        local spellID
        pcall(function()
            local name, _, _, startTime, endTime, _, _, _, sid = UnitCastingInfo(which)
            if name and sid and startTime ~= endTime and not IsSecretValue(sid) then
                spellID = sid
                return
            end
            local cname, _, _, cs, ce, _, _, cid = UnitChannelInfo(which)
            if cname and cid and cs ~= ce and not IsSecretValue(cid) then
                spellID = cid
            end
        end)
        return spellID
    end

    local function ApplyCost(spellID, whichFrame, whichUnit)
        whichFrame = whichFrame or frame
        whichUnit = whichUnit or unit
        if not whichFrame then return end
        HideSegment(whichFrame.Power)
        if whichFrame.AdditionalPower then
            HideSegment(whichFrame.AdditionalPower)
        end
        if not spellID then return end

        local cost = GetSpellCost(spellID, whichUnit)
        local target = whichFrame.Power
        local powerType = 0
        pcall(function()
            powerType = select(1, UnitPowerType(whichUnit))
        end)

        -- Extra mana only on the player. Target, target of target, and focus
        -- only preview a cost that matches the bar's own power type.
        if whichUnit == "player" and not CostActive(cost) and powerType ~= 0 then
            local manaCost = GetSpellCostMana(spellID, whichUnit)
            if CostActive(manaCost) and whichFrame.AdditionalPower and not whichFrame.AdditionalPower.isStaggerBar then
                cost = manaCost
                target = whichFrame.AdditionalPower
                powerType = 0
            end
        end

        if not CostActive(cost) or not target or target.isStaggerBar then
            if UF.UpdatePower and whichFrame.Power then UF.UpdatePower(whichFrame, whichUnit) end
            if UF.UpdateAdditionalPower and whichFrame.AdditionalPower then
                UF.UpdateAdditionalPower(whichFrame, whichUnit)
            end
            return
        end

        local maxPower
        if target == whichFrame.AdditionalPower then
            maxPower = API.SafeUnitPowerMax(whichUnit, 0)
        else
            maxPower = API.SafeUnitPowerMax(whichUnit, powerType)
        end
        target._fluxPredictedCost = cost
        target._fluxPredictMax = maxPower
        target._fluxCastUnitGUID = UnitGUID and UnitGUID(whichUnit) or nil
        PCO.ApplySegmentArt(target)

        if UF.UpdatePower and whichFrame.Power then UF.UpdatePower(whichFrame, whichUnit) end
        if UF.UpdateAdditionalPower and whichFrame.AdditionalPower then
            UF.UpdateAdditionalPower(whichFrame, whichUnit)
        end
    end

    local function ClearCost()
        local still = CurrentCastSpell(unit)
        if still then
            ApplyCost(still)
            return
        end
        HideSegment(frame.Power)
        if frame.AdditionalPower then
            HideSegment(frame.AdditionalPower)
        end
        if UF.UpdatePower then UF.UpdatePower(frame, unit) end
        if UF.UpdateAdditionalPower then UF.UpdateAdditionalPower(frame, unit) end
    end

    if unit == "target" or unit == "targettarget" then
        watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
    if unit == "focus" or unit == "focustarget" then
        watcher:RegisterEvent("PLAYER_FOCUS_CHANGED")
    end
    if unit == "targettarget" then
        SafeRegisterUnit(watcher, "UNIT_TARGET", "target")
    end
    if unit == "focustarget" then
        SafeRegisterUnit(watcher, "UNIT_TARGET", "focus")
    end

    local function FrameForUnit(name)
        if name == "player" then return ns.PlayerFrame end
        if name == "target" then return ns.TargetFrame end
        if name == "targettarget" then return ns.TargetOfTargetFrame end
        if name == "focus" then return ns.FocusFrame end
        if name == "focustarget" then return ns.FocusTargetFrame end
    end

    local function SyncNamedUnit(name)
        local fr = FrameForUnit(name)
        if not fr then return end
        StopBarFeedback(fr.Power)
        if fr.AdditionalPower then
            StopBarFeedback(fr.AdditionalPower)
        end
        local sid = CurrentCastSpell(name)
        if sid then
            ApplyCost(sid, fr, name)
            return
        end
        StopBarFeedback(fr.Power)
        if fr.AdditionalPower then
            StopBarFeedback(fr.AdditionalPower)
        end
        HideSegment(fr.Power)
        if fr.AdditionalPower then
            HideSegment(fr.AdditionalPower)
        end
        if UF.UpdatePower and fr.Power then
            UF.UpdatePower(fr, fr.unit or name)
        end
        if UF.UpdateAdditionalPower and fr.AdditionalPower then
            UF.UpdateAdditionalPower(fr, fr.unit or name)
        end
    end

    watcher:SetScript("OnEvent", function(_, event, eventUnit, ...)
        if event == "PLAYER_TARGET_CHANGED" then
            SyncNamedUnit("target")
            SyncNamedUnit("targettarget")
            return
        end
        if event == "PLAYER_FOCUS_CHANGED" then
            SyncNamedUnit("focus")
            SyncNamedUnit("focustarget")
            return
        end
        if event == "UNIT_TARGET" then
            if unit == "targettarget" and eventUnit == "target" then
                SyncNamedUnit("targettarget")
            elseif unit == "focustarget" and eventUnit == "focus" then
                SyncNamedUnit("focustarget")
            end
            return
        end

        if eventUnit ~= unit then return end

        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            local castGUID, spellID = ...
            if not spellID then
                spellID = castGUID
            end
            if IsSecretValue(spellID) then spellID = nil end
            if not spellID then
                spellID = CurrentCastSpell()
            end
            ApplyCost(spellID)
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_SUCCEEDED"
            or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            local nowGUID = UnitGUID and UnitGUID(unit) or nil
            local function markFinish(bar)
                if bar and bar._fluxCastUnitGUID and bar._fluxCastUnitGUID == nowGUID then
                    bar._fluxCastFinish = true
                end
            end
            markFinish(frame.Power)
            if frame.AdditionalPower and not frame.AdditionalPower.isStaggerBar then
                markFinish(frame.AdditionalPower)
            end
            ClearCost()
        elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            ClearCost()
        elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_DISPLAYPOWER" then
            local spellID = CurrentCastSpell()
            if spellID then
                ApplyCost(spellID)
            end
        end
    end)

    frame.PowerCostWatcher = watcher
    local already = CurrentCastSpell(unit)
    if already then
        ApplyCost(already)
    end
end
