-- UnitFrames/FluxPortraitCombatFeedback.lua
-- TPerl-style portrait damage/heal using Blizzard CombatFeedback animation + UNIT_COMBAT.
local addonName, ns = ...
local UF = ns.UnitFrames

local CombatFeedbackText = CombatFeedbackText
local CombatFeedback_Initialize = CombatFeedback_Initialize
local CombatFeedback_OnUpdate = CombatFeedback_OnUpdate

-- Flux perf T2.6: FluxUnitFrames_Shared previously drove CombatFeedback_OnUpdate
-- from its main per-frame OnUpdate, so that code ran every frame for every
-- unit frame even when no damage/heal text was being animated. We now attach
-- an OnUpdate to the frame's hitIndicator only while a feedback animation is
-- actually in flight (self.feedbackStartTime ~= nil). Blizzard's
-- CombatFeedback_OnUpdate clears feedbackStartTime when the animation
-- finishes, so we detect that and clear the OnUpdate script.
local function _FluxFeedbackTick(hit, elapsed)
    local owner = hit._fluxFeedbackOwner
    if not owner then
        hit:SetScript("OnUpdate", nil)
        return
    end
    if not owner.feedbackStartTime then
        hit:SetScript("OnUpdate", nil)
        return
    end
    if CombatFeedback_OnUpdate then
        CombatFeedback_OnUpdate(owner, elapsed)
    end
    if not owner.feedbackStartTime then
        hit:SetScript("OnUpdate", nil)
    end
end

local function _FluxStartFeedbackTick(frame)
    local hit = frame and frame.hitIndicator
    if not hit then return end
    hit._fluxFeedbackOwner = frame
    hit:SetScript("OnUpdate", _FluxFeedbackTick)
end

local API = ns.API

local function IsSecret(value)
    if API and API.IsSecretValue then
        return API.IsSecretValue(value) and true or false
    end
    local fn = issecretvalue or IsSecretValue
    if fn then
        local ok, res = pcall(fn, value)
        return ok and res and true or false
    end
    return false
end

local function FlagIs(flags, name)
    if flags == nil or IsSecret(flags) then
        return false
    end
    return flags == name
end

local function AmountIsNonzero(amount)
    if amount == nil then
        return false
    end
    -- Secret amounts still display via SetText; do not ~= 0 them.
    if IsSecret(amount) then
        return true
    end
    return amount ~= 0
end

local function IsPhysicalDamageSchool(damageType)
    if damageType == nil or IsSecret(damageType) then
        return true
    end
    if Enum and Enum.Damageclass and Enum.Damageclass.MaskPhysical ~= nil then
        return damageType == Enum.Damageclass.MaskPhysical
    end
    if SCHOOL_MASK_PHYSICAL ~= nil then
        return damageType == SCHOOL_MASK_PHYSICAL
    end
    return true
end

--- Mirrors Blizzard CombatFeedback_OnCombatEvent with FluxFormatPortraitCombatNumber for amounts.
function UF.PortraitCombatFeedback_OnCombatEvent(self, event, flags, amount, damageType)
    if not self or not self.feedbackText then
        return
    end
    if event == nil or IsSecret(event) then
        return
    end
    local feedbackText = self.feedbackText
    local fontHeight = self.feedbackFontHeight
    local text = ""
    local r, g, b = 1.0, 1.0, 1.0

    if event == "IMMUNE" then
        fontHeight = fontHeight * 0.5
        text = CombatFeedbackText[event]
    elseif event == "WOUND" then
        if AmountIsNonzero(amount) then
            if FlagIs(flags, "CRITICAL") or FlagIs(flags, "CRUSHING") then
                fontHeight = fontHeight * 1.5
            elseif FlagIs(flags, "GLANCING") then
                fontHeight = fontHeight * 0.75
            end
            if not IsPhysicalDamageSchool(damageType) then
                r, g, b = 1.0, 1.0, 0.0
            end
            text = FluxFormatPortraitCombatNumber(amount)
            if FlagIs(flags, "BLOCK_REDUCED") and COMBAT_TEXT_BLOCK_REDUCED and not IsSecret(text) then
                text = COMBAT_TEXT_BLOCK_REDUCED:format(text)
            end
        elseif FlagIs(flags, "ABSORB") then
            fontHeight = fontHeight * 0.75
            text = CombatFeedbackText["ABSORB"]
        elseif FlagIs(flags, "BLOCK") then
            fontHeight = fontHeight * 0.75
            text = CombatFeedbackText["BLOCK"]
        elseif FlagIs(flags, "RESIST") then
            fontHeight = fontHeight * 0.75
            text = CombatFeedbackText["RESIST"]
        else
            text = CombatFeedbackText["MISS"]
        end
    elseif event == "BLOCK" then
        fontHeight = fontHeight * 0.75
        text = CombatFeedbackText[event]
    elseif event == "HEAL" then
        text = FluxFormatPortraitCombatNumber(amount)
        r, g, b = 0.0, 1.0, 0.0
        if FlagIs(flags, "CRITICAL") then
            fontHeight = fontHeight * 1.5
        end
    elseif event == "ENERGIZE" then
        text = FluxFormatPortraitCombatNumber(amount)
        r, g, b = 0.41, 0.8, 0.94
        if FlagIs(flags, "CRITICAL") then
            fontHeight = fontHeight * 1.5
        end
    else
        text = CombatFeedbackText[event]
    end

    self.feedbackStartTime = GetTime()
    feedbackText:SetTextHeight(fontHeight)
    feedbackText:SetText(text)
    feedbackText:SetTextColor(r, g, b)
    feedbackText:SetAlpha(0.0)
    feedbackText:Show()

    -- Flux perf T2.6: start the feedback tick on the hitIndicator sub-frame
    -- only for as long as this animation runs.
    _FluxStartFeedbackTick(self)
end

function UF.CreatePortraitCombatFeedback(frame)
    if not frame or not frame.PortraitFrame then
        return
    end
    if frame.hitIndicator then
        return
    end

    local portrait = frame.PortraitFrame
    local hit = CreateFrame("Frame", nil, portrait)
    hit:SetFrameStrata(portrait:GetFrameStrata())
    hit:SetFrameLevel(portrait:GetFrameLevel() + 25)
    hit:SetAllPoints(portrait)
    hit:EnableMouse(false)

    local fs = hit:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
    fs:SetPoint("CENTER", portrait, "CENTER", 0, 0)
    local font, _size, flags = fs:GetFont()
    if font then
        fs:SetFont(font, 30, flags)
    end
    fs:SetTextColor(1, 1, 1)
    fs:Hide()

    hit.text = fs
    frame.hitIndicator = hit

    if CombatFeedback_Initialize then
        CombatFeedback_Initialize(frame, fs, 30)
    end

    frame.portraitCombatFeedbackEnabled = true

    local unit = frame.unit
    if unit == "player" then
        FluxSafeRegisterUnitEvent(frame, "UNIT_COMBAT", "player", "vehicle")
    elseif unit == "target" then
        FluxSafeRegisterUnitEvent(frame, "UNIT_COMBAT", "target")
    elseif unit == "focus" then
        FluxSafeRegisterUnitEvent(frame, "UNIT_COMBAT", "focus")
    end
end
