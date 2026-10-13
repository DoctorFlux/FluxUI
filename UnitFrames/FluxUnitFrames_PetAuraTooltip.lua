-- FluxUnitFrames_PetAuraTooltip.lua
-- Embed pet buff/debuff icons + cooldown countdown inside the same GameTooltip
-- shown on pet-frame mouseover. Icons are non-mouse so they cannot dismiss the tip.
local addonName, ns = ...

local UF = ns.UnitFrames
if not UF then return end

local API = ns.API
local FLUX_API = _G.FLUX_API or {}

local MAX_BUFFS = 16
local MAX_DEBUFFS = 8
local PER_ROW = 8
local ICON_SIZE = 20
local ICON_PAD = 2
local ROW_GAP = 2
local PAD = 4
local LINE_PX = 12 -- approximate GameTooltip line height for spacer reserve

local host -- child of GameTooltip
local buffButtons = {}
local debuffButtons = {}
local shown = false
local pendingCreate = false
local durationButtons = {}
local auraRefreshQueued = false

local function IsPreDF()
    if not UnitAura then
        return false
    end
    if FLUX_API.isCamelot or FLUX_API.isForever then
        return false
    end
    if FLUX_API.isPreDF ~= nil then return FLUX_API.isPreDF end
    return (FLUX_API.majorVersion or 12) < 10
end

local function ShouldShow()
    if FluxUnitFrames_ShouldShowPetTooltipAuras then
        return FluxUnitFrames_ShouldShowPetTooltipAuras()
    end
    return true
end

local function SafeNumber(v, fallback)
    if API and API.SafeGetNumber then
        return API.SafeGetNumber(v, fallback or 0)
    end
    if type(v) == "number" then return v end
    return fallback or 0
end

local function FetchDurationRegion(cooldown)
    if not cooldown then return end
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then return region end
    end
end

local function FormatRemaining(remaining)
    if remaining >= 3600 then
        return string.format("%.0fh", remaining / 3600)
    elseif remaining >= 60 then
        return string.format("%.0fm", remaining / 60)
    elseif remaining >= 10 then
        return string.format("%.0f", remaining)
    else
        return string.format("%.1f", remaining)
    end
end

local function UpdateDurationText(cooldown)
    if not cooldown or not cooldown:IsShown() then return end
    local textRegion = cooldown.durationText
    if not textRegion then return end

    local remaining
    -- Prefer aura expiration (seconds). GetCooldownTimes is ms on modern clients and
    -- is unreliable / secret after SetCooldownFromDurationObject.
    local expireAt = SafeNumber(cooldown._fluxExpireAt, 0)
    if expireAt > 0 then
        remaining = expireAt - GetTime()
    else
        local startTime, durationTime = cooldown:GetCooldownTimes()
        local safeStart = SafeNumber(startTime, 0)
        local safeDur = SafeNumber(durationTime, 0)
        if safeStart > 0 and safeDur > 0 then
            -- Normalize ms → seconds when values look like milliseconds.
            if safeDur > 1000 or safeStart > 100000 then
                safeStart = safeStart / 1000
                safeDur = safeDur / 1000
            end
            remaining = (safeStart + safeDur) - GetTime()
        end
    end

    if remaining and remaining > 0 then
        textRegion:SetText(FormatRemaining(remaining))
        textRegion:Show()
        return
    end
    textRegion:SetText("")
    textRegion:Hide()
end

local durationTicker
local function SyncDurationTicker()
    if next(durationButtons) then
        if not durationTicker then
            durationTicker = C_Timer.NewTicker(0.1, function()
                if not shown then return end
                for cd in pairs(durationButtons) do
                    UpdateDurationText(cd)
                end
            end)
        end
    elseif durationTicker then
        durationTicker:Cancel()
        durationTicker = nil
    end
end

local function ApplyDuration(cooldown)
    if not cooldown then return end
    -- Prefer our own FontString (Blizzard countdown region is hidden via SetHideCountdownNumbers).
    local textRegion = cooldown._fluxDurationFS or FetchDurationRegion(cooldown)
    if not textRegion then
        C_Timer.After(0.01, function()
            if cooldown:IsShown() then
                ApplyDuration(cooldown)
            end
        end)
        return
    end
    textRegion:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    textRegion:SetTextColor(1, 1, 1, 1)
    textRegion:ClearAllPoints()
    textRegion:SetPoint("CENTER", cooldown, "CENTER", 0, 0)
    textRegion:SetShadowColor(0, 0, 0, 1)
    textRegion:SetShadowOffset(1, -1)
    textRegion:SetDrawLayer("OVERLAY", 7)
    cooldown.durationText = textRegion
    durationButtons[cooldown] = true
    UpdateDurationText(cooldown)
    SyncDurationTicker()
end

local function CreateAuraIcon(parent, index, kind)
    local button = CreateFrame("Frame", parent:GetName() .. kind .. index, parent)
    button:SetSize(ICON_SIZE, ICON_SIZE)
    button:EnableMouse(false)
    button:Hide()

    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetAllPoints()
    button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.Cooldown:SetAllPoints()
    button.Cooldown:SetDrawEdge(false)
    button.Cooldown:SetDrawBling(false)
    button.Cooldown:SetReverse(true)
    button.Cooldown:EnableMouse(false)
    -- Hide Blizzard numbers; we draw our own FS so it always shows above the swipe.
    if button.Cooldown.SetHideCountdownNumbers then
        button.Cooldown:SetHideCountdownNumbers(true)
    end

    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button)
    overlay:SetFrameLevel(button:GetFrameLevel() + 5)
    overlay:EnableMouse(false)

    button.Count = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.Count:SetPoint("BOTTOMRIGHT", -1, 0)
    button.Count:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")

    local durationFS = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    durationFS:SetPoint("CENTER", overlay, "CENTER", 0, 0)
    durationFS:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    durationFS:SetTextColor(1, 1, 1, 1)
    durationFS:SetShadowColor(0, 0, 0, 1)
    durationFS:SetShadowOffset(1, -1)
    durationFS:Hide()
    button.Cooldown._fluxDurationFS = durationFS
    button.Cooldown.durationText = durationFS

    -- Thin 1px edge only (no ActionButton glow overlay).
    button.Border = CreateFrame("Frame", nil, button, "BackdropTemplate")
    button.Border:SetAllPoints()
    button.Border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    button.Border:SetBackdropBorderColor(0, 0, 0, 0.85)
    button.Border:SetFrameLevel(button:GetFrameLevel() + 3)

    return button
end

local function EnsureHost()
    if host then return host end
    if InCombatLockdown() then
        pendingCreate = true
        return nil
    end
    if not GameTooltip or GameTooltip:IsForbidden() then return nil end

    host = CreateFrame("Frame", "FluxPetAuraTooltipHost", GameTooltip)
    host:EnableMouse(false)
    host:Hide()

    for i = 1, MAX_BUFFS do
        buffButtons[i] = CreateAuraIcon(host, i, "Buff")
    end
    for i = 1, MAX_DEBUFFS do
        debuffButtons[i] = CreateAuraIcon(host, i, "Debuff")
    end

    if not GameTooltip._fluxPetAuraHideHooked then
        GameTooltip._fluxPetAuraHideHooked = true
        GameTooltip:HookScript("OnHide", function()
            -- Ignore hide during SetUnit/rebuild; only clear when tip is truly dismissed.
            if GameTooltip._fluxUnitTipRebuilding then return end
            if shown then
                UF.HidePetAuraTooltip()
            end
        end)
    end

    pendingCreate = false
    return host
end

local function AuraDataIsValid(data)
    -- Prefer auraInstanceID (post-DF). Avoid truthy checks on icon alone —
    -- icon can be secret/restricted on Midnight without meaning the aura is missing.
    if not data then return false end
    if data.auraInstanceID or data.auraInstanceId then return true end
    if data.icon or data.spellId or data.name then return true end
    return false
end

local function GatherAuras(filter, maxCount)
    local list = {}
    if not UnitExists("pet") then return list end

    -- Pre-DF / clients that still expose UnitAura (index-based returns).
    if IsPreDF() then
        if not UnitAura then return list end
        for i = 1, 40 do
            if #list >= maxCount then break end
            local name, icon, count, dispelType, duration, expirationTime, source, isStealable, _, spellId =
                UnitAura("pet", i, filter)
            if not name then break end
            list[#list + 1] = {
                name = name,
                icon = icon,
                applications = count or 0,
                dispelName = dispelType,
                duration = duration or 0,
                expirationTime = expirationTime or 0,
                sourceUnit = source,
                isStealable = isStealable,
                spellId = spellId,
                -- Slot index is NOT an auraInstanceID; omit so we use SetCooldown path.
            }
        end
        return list
    end

    -- Post-DF / Midnight: UnitAura is removed — use C_UnitAuras via Core API helpers.
    -- Match FluxUnitFrames_Auras: slots first, then index fallback. Never call UnitAura.
    local slots, accessible
    if API and API.SafeGetAuraSlots then
        slots, accessible = API.SafeGetAuraSlots("pet", filter)
    end
    if accessible == false then
        return list
    end
    slots = slots or {}
    local useIndexFallback = false
    if #slots < 2 and API and API.SafeGetAuraDataByIndex then
        local probe = API.SafeGetAuraDataByIndex("pet", 1, filter)
        if AuraDataIsValid(probe) then
            useIndexFallback = true
        end
    end

    if useIndexFallback and API.SafeGetAuraDataByIndex then
        for i = 1, 40 do
            if #list >= maxCount then break end
            local data = API.SafeGetAuraDataByIndex("pet", i, filter)
            if not AuraDataIsValid(data) then break end
            list[#list + 1] = data
        end
        return list
    end

    if API and API.SafeGetAuraDataBySlot and #slots >= 2 then
        -- GetAuraSlots returns [continuationToken, slot1, slot2, ...]
        for i = 2, #slots do
            if #list >= maxCount then break end
            local data = API.SafeGetAuraDataBySlot("pet", slots[i], filter)
            if AuraDataIsValid(data) then
                list[#list + 1] = data
            end
        end
        if #list > 0 then return list end
    end

    if API and API.SafeGetAuraDataByIndex then
        for i = 1, 40 do
            if #list >= maxCount then break end
            local data = API.SafeGetAuraDataByIndex("pet", i, filter)
            if not AuraDataIsValid(data) then break end
            list[#list + 1] = data
        end
        return list
    end

    -- Last resort only if UnitAura still exists (some transitional clients).
    if UnitAura then
        for i = 1, 40 do
            if #list >= maxCount then break end
            local name, icon, count, dispelType, duration, expirationTime, source, isStealable, _, spellId =
                UnitAura("pet", i, filter)
            if not name then break end
            list[#list + 1] = {
                name = name,
                icon = icon,
                applications = count or 0,
                dispelName = dispelType,
                duration = duration or 0,
                expirationTime = expirationTime or 0,
                sourceUnit = source,
                isStealable = isStealable,
                spellId = spellId,
            }
        end
    end
    return list
end

local function PaintButton(button, data, isDebuff)
    if not button or not AuraDataIsValid(data) then
        if button then button:Hide() end
        return
    end

    if data.icon then
        button.Icon:SetTexture(data.icon)
        button.Icon:Show()
    end

    local apps = SafeNumber(data.applications, 0)
    if apps >= 2 then
        if apps > 999 then
            button.Count:SetText("*")
        else
            button.Count:SetText(tostring(apps))
        end
        button.Count:Show()
    else
        button.Count:SetText("")
        button.Count:Hide()
    end

    if button.Border and button.Border.SetBackdropBorderColor then
        if isDebuff then
            local dt = data.dispelName
            if dt == "Magic" then
                button.Border:SetBackdropBorderColor(0.2, 0.6, 1, 1)
            elseif dt == "Curse" then
                button.Border:SetBackdropBorderColor(0.6, 0.0, 1, 1)
            elseif dt == "Disease" then
                button.Border:SetBackdropBorderColor(0.6, 0.4, 0, 1)
            elseif dt == "Poison" then
                button.Border:SetBackdropBorderColor(0, 0.6, 0, 1)
            else
                button.Border:SetBackdropBorderColor(0.85, 0.1, 0.1, 1)
            end
        else
            button.Border:SetBackdropBorderColor(0, 0, 0, 0.85)
        end
    end

    local cd = button.Cooldown
    durationButtons[cd] = nil
    cd._fluxExpireAt = nil
    local duration = SafeNumber(data.duration, 0)
    local expirationTime = SafeNumber(data.expirationTime, 0)
    local auraInstanceID = data.auraInstanceID or data.auraInstanceId

    local function ShowTimedCooldown()
        cd._fluxExpireAt = (expirationTime > 0) and expirationTime or nil
        cd:SetDrawEdge(false)
        cd:SetDrawBling(false)
        cd:SetReverse(true)
        ApplyDuration(cd)
        cd:Show()
    end

    if API and API.isV12 and API.SafeGetAuraDuration and cd.SetCooldownFromDurationObject
        and auraInstanceID then
        local durationObject = API.SafeGetAuraDuration("pet", auraInstanceID)
        if durationObject then
            cd:SetCooldownFromDurationObject(durationObject)
            -- Duration objects may also expose expiration; prefer readable aura data.
            if expirationTime <= 0 and durationObject.expirationTime then
                expirationTime = SafeNumber(durationObject.expirationTime, 0)
            end
            ShowTimedCooldown()
        elseif duration > 0 and expirationTime > 0 then
            if cd.SetCooldownFromExpirationTime then
                cd:SetCooldownFromExpirationTime(expirationTime, duration)
            else
                cd:SetCooldown(expirationTime - duration, duration)
            end
            ShowTimedCooldown()
        else
            cd:Hide()
            if cd.durationText then cd.durationText:Hide() end
        end
    elseif duration > 0 and expirationTime > 0 then
        if cd.SetCooldownFromExpirationTime then
            cd:SetCooldownFromExpirationTime(expirationTime, duration)
        else
            cd:SetCooldown(expirationTime - duration, duration)
        end
        ShowTimedCooldown()
    else
        cd:Hide()
        if cd.durationText then cd.durationText:Hide() end
    end

    button:Show()
end

local function LayoutRow(buttons, count, offsetY)
    for i = 1, #buttons do
        local btn = buttons[i]
        if i <= count then
            local col = ((i - 1) % PER_ROW)
            local row = math.floor((i - 1) / PER_ROW)
            btn:ClearAllPoints()
            btn:SetPoint(
                "TOPLEFT",
                host,
                "TOPLEFT",
                col * (ICON_SIZE + ICON_PAD),
                -(offsetY + row * (ICON_SIZE + ICON_PAD))
            )
        else
            btn:Hide()
            if btn.Cooldown then
                durationButtons[btn.Cooldown] = nil
            end
        end
    end
    if count <= 0 then return 0 end
    local rows = math.ceil(count / PER_ROW)
    return rows * ICON_SIZE + (rows - 1) * ICON_PAD
end

local function AuraBlockHeight(buffCount, debuffCount)
    local buffRows = buffCount > 0 and math.ceil(buffCount / PER_ROW) or 0
    local debuffRows = debuffCount > 0 and math.ceil(debuffCount / PER_ROW) or 0
    local h = 0
    if buffRows > 0 then
        h = h + buffRows * ICON_SIZE + (buffRows - 1) * ICON_PAD
    end
    if buffRows > 0 and debuffRows > 0 then
        h = h + ROW_GAP
    end
    if debuffRows > 0 then
        h = h + debuffRows * ICON_SIZE + (debuffRows - 1) * ICON_PAD
    end
    return h
end

local function ReserveTooltipSpace(tt, pixelHeight)
    if not tt or tt:IsForbidden() or pixelHeight <= 0 then
        return
    end
    -- Tight reserve: only enough blank lines for the icon block (+ bottom pad).
    local linesNeeded = math.max(1, math.ceil((pixelHeight + PAD) / LINE_PX))
    for _ = 1, linesNeeded do
        tt:AddLine(" ")
    end
end

local function TipIsPetUnit()
    if not GameTooltip or GameTooltip:IsForbidden() or not GameTooltip:IsShown() then
        return false
    end
    if GameTooltip.GetUnit then
        local _, unit = GameTooltip:GetUnit()
        if unit == "pet" then return true end
    end
    -- Fallback: owner is pet outer border while we marked shown.
    return shown
end

local function PaintIntoTooltip()
    if not shown or not ShouldShow() or not UnitExists("pet") then
        if host then host:Hide() end
        SyncDurationTicker()
        return
    end
    if not TipIsPetUnit() then
        if host then host:Hide() end
        SyncDurationTicker()
        return
    end

    local frame = EnsureHost()
    if not frame then return end

    local buffs = GatherAuras("HELPFUL", MAX_BUFFS)
    local debuffs = GatherAuras("HARMFUL", MAX_DEBUFFS)
    if #buffs == 0 and #debuffs == 0 then
        frame:Hide()
        SyncDurationTicker()
        return
    end

    for i = 1, MAX_BUFFS do
        PaintButton(buffButtons[i], buffs[i], false)
    end
    for i = 1, MAX_DEBUFFS do
        PaintButton(debuffButtons[i], debuffs[i], true)
    end

    local buffH = LayoutRow(buffButtons, #buffs, 0)
    local debuffOffset = buffH > 0 and (buffH + ROW_GAP) or 0
    local debuffH = LayoutRow(debuffButtons, #debuffs, debuffOffset)
    local blockH = debuffOffset + debuffH
    local cols = math.min(PER_ROW, math.max(#buffs, #debuffs, 1))
    local blockW = cols * (ICON_SIZE + ICON_PAD) - ICON_PAD

    frame:SetSize(blockW, blockH)
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", GameTooltip, "BOTTOMLEFT", PAD, PAD)
    frame:Show()

    local ttW = GameTooltip:GetWidth() or 0
    local needW = blockW + PAD * 2 + 4
    if ttW < needW and GameTooltip.SetMinimumWidth then
        GameTooltip:SetMinimumWidth(needW)
    end
    SyncDurationTicker()
end

function UF.ShowPetAuraTooltip()
    if not ShouldShow() then return end
    if not UnitExists("pet") then return end
    if not GameTooltip or GameTooltip:IsForbidden() then return end
    if not GameTooltip:IsShown() then return end

    shown = true
    if not EnsureHost() then
        return
    end

    local buffs = GatherAuras("HELPFUL", MAX_BUFFS)
    local debuffs = GatherAuras("HARMFUL", MAX_DEBUFFS)
    if #buffs == 0 and #debuffs == 0 then
        if host then host:Hide() end
        SyncDurationTicker()
        return
    end

    local blockH = AuraBlockHeight(#buffs, #debuffs)

    -- SetUnit already ran; append spacers into this tip then paint icons inside it.
    GameTooltip._fluxUnitTipRebuilding = true
    ReserveTooltipSpace(GameTooltip, blockH)
    GameTooltip:Show()
    if ns.ApplyHUDTooltipPosition then
        ns.ApplyHUDTooltipPosition()
    end
    GameTooltip._fluxUnitTipRebuilding = nil

    PaintIntoTooltip()
end

function UF.HidePetAuraTooltip()
    shown = false
    wipe(durationButtons)
    SyncDurationTicker()
    if host then
        host:Hide()
        for i = 1, MAX_BUFFS do
            if buffButtons[i] then buffButtons[i]:Hide() end
        end
        for i = 1, MAX_DEBUFFS do
            if debuffButtons[i] then debuffButtons[i]:Hide() end
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UNIT_PET")
local auraUnitOk = pcall(function() eventFrame:RegisterUnitEvent("UNIT_AURA", "pet") end)
if not auraUnitOk then
    eventFrame:RegisterEvent("UNIT_AURA")
end
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_REGEN_ENABLED" then
        if pendingCreate then
            EnsureHost()
            if shown and TipIsPetUnit() then
                PaintIntoTooltip()
            end
        end
        return
    end
    if event == "UNIT_PET" then
        if arg1 == "player" and shown and not UnitExists("pet") then
            UF.HidePetAuraTooltip()
        end
        return
    end
    if event == "UNIT_AURA" and (not arg1 or arg1 == "pet") and shown then
        -- Paint only — do not SetUnit/rebuild (that caused fade/flicker while hovering).
        if not auraRefreshQueued then
            auraRefreshQueued = true
            C_Timer.After(0, function()
                auraRefreshQueued = false
                if shown and TipIsPetUnit() then
                    PaintIntoTooltip()
                end
            end)
        end
    end
end)

local _origShow = UF.ShowUnitTooltip
local _origHide = UF.HideUnitTooltip

function UF.ShowUnitTooltip(anchorFrame, unit, fromUpdate)
    if _origShow then
        _origShow(anchorFrame, unit, fromUpdate)
    end
    if unit == "pet" then
        UF.ShowPetAuraTooltip()
    else
        UF.HidePetAuraTooltip()
    end
end

function UF.HideUnitTooltip()
    UF.HidePetAuraTooltip()
    if _origHide then
        _origHide()
    end
end

_G.FluxUnitFrames_ShowPetAuraTooltip = UF.ShowPetAuraTooltip
_G.FluxUnitFrames_HidePetAuraTooltip = UF.HidePetAuraTooltip
