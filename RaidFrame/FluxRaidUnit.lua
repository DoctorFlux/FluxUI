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
    if not bar or value == nil then return end
    if IsSecret(value) or value ~= nil then
        pcall(bar.SetValue, bar, value)
    end
end

function FluxRaid_ShouldShowPowerBar(frame)
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
        FluxRaidVisuals.ApplyCellChrome(frame, { showPower = show })
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
        r, g, b = 0.5, 0.5, 0.5
    elseif not IsSecret(dead) and dead then
        r, g, b = 0.5, 0.5, 0.5
    elseif useClass then
        local cr, cg, cb = ClassColor(unit)
        if cr then r, g, b = cr, cg, cb end
    end
    pcall(bar.SetStatusBarColor, bar, r, g, b)
end

function FluxRaid_UpdatePower(frame)
    local bar = frame and frame.powerBar
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
            if ns and ns.UnitFrames and ns.UnitFrames.UsesHudUnitBars
                and ns.UnitFrames.UsesHudUnitBars() then
                -- SetAlpha is an allowed secret sink; zero reveals the HP
                -- underneath without comparing a restricted maximum in Lua.
                bar:SetAlpha(maximum)
            end
            if not IsSecret(maximum) and type(maximum) == "number" then
                frame._fluxNoMainPower = maximum <= 0
            end
        end
    end
    ApplyPowerVisibility(frame)
    if not bar:IsShown() then return end
    pcall(bar.SetMinMaxValues, bar, 0, 100)
    if powerType or powerToken then
        if powerToken and PowerBarColor and PowerBarColor[powerToken] then
            local c = PowerBarColor[powerToken]
            pcall(bar.SetStatusBarColor, bar, c.r, c.g, c.b)
        elseif powerType and FluxRaidVisuals.POWER_COLORS and FluxRaidVisuals.POWER_COLORS[powerType] then
            local c = FluxRaidVisuals.POWER_COLORS[powerType]
            pcall(bar.SetStatusBarColor, bar, c.r, c.g, c.b)
        end
    end
    local connected = UnitIsConnected and UnitIsConnected(unit)
    if not IsSecret(connected) and connected == false then
        pcall(bar.SetStatusBarColor, bar, 0.4, 0.4, 0.4)
    end
    SetStatusBarValue(bar, Compat.GetPowerPercent(unit, powerType))
end

local function FeedOverlayBar(bar, maxHealth, value, r, g, b)
    if not bar then return end
    if maxHealth == nil or value == nil then
        ShowRegion(bar, false)
        return
    end
    local parent = bar:GetParent()
    bar:ClearAllPoints()
    if parent then
        bar:SetAllPoints(parent)
        if bar.SetFrameLevel and parent.GetFrameLevel then
            bar:SetFrameLevel((parent:GetFrameLevel() or 0) + 3)
        end
    end
    pcall(bar.SetMinMaxValues, bar, 0, maxHealth)
    pcall(bar.SetValue, bar, value)
    if bar.SetStatusBarTexture then
        pcall(bar.SetStatusBarTexture, bar, "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
    end
    if r and bar.SetStatusBarColor then
        pcall(bar.SetStatusBarColor, bar, r, g, b, 0.55)
    end
    ShowRegion(bar, true)
end

function FluxRaid_UpdateHealPrediction(frame)
    local unit = UnitOf(frame)
    local health = frame and frame.healthBar
    if not health or type(unit) ~= "string" then return end
    local opt = frame.optionTable
    local enabled = not opt or opt.displayHealPrediction ~= false
    local function hideAll()
        ShowRegion(health.myHealPrediction, false)
        ShowRegion(health.otherHealPrediction, false)
        ShowRegion(health.totalAbsorb, false)
        ShowRegion(health.healAbsorb, false)
    end
    if not enabled or not UnitHealthMax or not UnitGetIncomingHeals then
        hideAll()
        return
    end
    local okM, maxH = pcall(UnitHealthMax, unit)
    if not okM or maxH == nil then
        hideAll()
        return
    end
    local function read(fn, ...)
        if not fn then return nil end
        local ok, v = pcall(fn, ...)
        if ok then return v end
        return nil
    end
    local mine = read(UnitGetIncomingHeals, unit, "player")
    local all = read(UnitGetIncomingHeals, unit)
    local absorb = UnitGetTotalAbsorbs and read(UnitGetTotalAbsorbs, unit) or nil
    local healAbsorb = UnitGetTotalHealAbsorbs and read(UnitGetTotalHealAbsorbs, unit) or nil
    FeedOverlayBar(health.myHealPrediction, maxH, mine, 0.0, 0.65, 0.32)
    FeedOverlayBar(health.otherHealPrediction, maxH, all, 0.0, 0.45, 0.25)
    FeedOverlayBar(health.totalAbsorb, maxH, absorb, 0.7, 0.85, 1.0)
    FeedOverlayBar(health.healAbsorb, maxH, healAbsorb, 0.55, 0.15, 0.15)
end

function FluxRaid_UpdateName(frame)
    local fs = frame and frame.name
    local unit = UnitOf(frame)
    if not fs or type(unit) ~= "string" or unit == "" then return end
    local name
    local playerName = ns.Flux and ns.Flux.PlayerName
    if playerName and playerName.GetDisplayName then
        local ok, v = pcall(playerName.GetDisplayName, unit)
        if ok then name = v end
    end
    if name == nil and GetUnitName then
        local ok, v = pcall(GetUnitName, unit, true)
        if ok then name = v end
    end
    if name == nil or (not IsSecret(name) and name == "") then
        fs:SetText("")
        return
    end
    pcall(fs.SetText, fs, name)
    local r, g, b = 1, 1, 1
    if FluxRaid_ShouldClassColorNames and FluxRaid_ShouldClassColorNames() then
        local cr, cg, cb = ClassColor(unit)
        if cr then r, g, b = cr, cg, cb end
    end
    pcall(fs.SetTextColor, fs, r, g, b)
end

function FluxRaid_UpdateStatusText(frame)
    local fs = frame and frame.statusText
    if not fs then return end
    local opt = frame.optionTable
    local mode = (opt and (opt._fluxHealthText or opt.healthText)) or "perc"
    if C_CVar and C_CVar.GetCVar then
        local cv = C_CVar.GetCVar("raidFramesHealthText")
        if type(cv) == "string" and cv ~= "" then mode = cv end
    end
    if mode == "none" or (opt and opt.displayStatusText == false) then
        fs:Hide()
        return
    end
    local unit = frame.unit
    local displayed = UnitOf(frame)
    if type(displayed) ~= "string" then
        fs:Hide()
        return
    end
    local connected = UnitIsConnected and UnitIsConnected(unit or displayed)
    if not IsSecret(connected) and connected == false then
        fs:SetText(PLAYER_OFFLINE or "Offline")
        fs:Show()
        return
    end
    local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost(displayed)
    if not IsSecret(dead) and dead then
        fs:SetText(DEAD or "Dead")
        fs:Show()
        return
    end
    local function setPercent()
        local perc = Compat.GetHealthPercent(displayed)
        if perc == nil and not IsSecret(perc) then
            fs:Hide()
            return
        end
        if not pcall(fs.SetFormattedText, fs, "%.0f%%", perc) then
            pcall(fs.SetText, fs, perc)
        end
        fs:Show()
    end
    if mode == "perc" or mode == "healthandpercent" then
        setPercent()
        return
    end
    if mode == "health" then
        local h = UnitHealth and UnitHealth(displayed)
        if h ~= nil then
            pcall(fs.SetText, fs, h)
            fs:Show()
        else
            fs:Hide()
        end
        return
    end
    if mode == "losthealth" then
        local maxH = UnitHealthMax and UnitHealthMax(displayed)
        local h = UnitHealth and UnitHealth(displayed)
        local ok, lost, positive = pcall(function()
            local v = maxH - h
            return v, type(v) == "number" and v > 0
        end)
        if ok and not IsSecret(lost) and positive then
            if LOST_HEALTH then
                fs:SetFormattedText(LOST_HEALTH, lost)
            else
                fs:SetText("-" .. tostring(lost))
            end
            fs:Show()
        else
            setPercent()
        end
        return
    end
    fs:Hide()
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
    local icon = frame and frame.roleIcon
    local unit = UnitOf(frame)
    if not icon then return end
    local opt = frame.optionTable
    if opt and opt.showRoleIcon == false then
        ShowRegion(icon, false)
        return
    end
    if type(unit) ~= "string" or not UnitGroupRolesAssigned then
        ShowRegion(icon, false)
        return
    end
    local ok, role = pcall(UnitGroupRolesAssigned, unit)
    if not ok or IsSecret(role) or type(role) ~= "string" then
        ShowRegion(icon, false)
        return
    end
    local atlas = ROLE_ATLAS[role]
    if not atlas then
        ShowRegion(icon, false)
        return
    end
    local shown = pcall(icon.SetAtlas, icon, atlas)
    ShowRegion(icon, shown and true or false)
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
    if UnitHasIncomingResurrection then
        local ok, inc = pcall(UnitHasIncomingResurrection, unit)
        if ok and not IsSecret(inc) and inc then
            if SetCenterTexture(frame, "Raid-Icon-Rez") then return end
        end
    end
    if GetRaidTargetIndex then
        local ok, idx = pcall(GetRaidTargetIndex, unit)
        if ok and not IsSecret(idx) and type(idx) == "number" and idx > 0 then
            if SetRaidTargetIconTexture and frame.centerStatusIcon.texture then
                pcall(SetRaidTargetIconTexture, frame.centerStatusIcon.texture, idx)
                ShowRegion(frame.centerStatusIcon, true)
                return
            end
        end
    end
    if UnitIsGroupLeader then
        local ok, lead = pcall(UnitIsGroupLeader, unit)
        if ok and not IsSecret(lead) and lead then
            if SetCenterTexture(frame, nil, "Interface\\GroupFrame\\UI-Group-LeaderIcon") then return end
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
    if not ok or IsSecret(status) or status == nil or status == "waiting" then
        ShowRegion(icon, false)
        return
    end
    local tex = icon.texture or icon
    local path = (READY_CHECK_READY_TEXTURE or "Interface\\RaidFrame\\ReadyCheck-Ready")
    if status == "notready" then
        path = READY_CHECK_NOT_READY_TEXTURE or "Interface\\RaidFrame\\ReadyCheck-NotReady"
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

local function EnsureClassicAuraButtons(frame)
    if frame._fluxAuraButtons or frame._fluxPrivateAuraMixed then return end
    if FluxRaidVisuals.UsesPrivateAuras(frame) and FluxRaidVisuals.ConfigurePrivateAuras(frame) then
        return
    end
    local host = frame.auraHost or frame
    frame.buffFrames = {}
    frame.debuffFrames = {}
    frame.dispelDebuffFrames = {}
    local function make(list, n)
        for i = 1, n do
            local b = CreateFrame("Frame", nil, host)
            b:SetSize(FluxRaidVisuals.AURA_ICON_WIDTH or 11, FluxRaidVisuals.AURA_ICON_HEIGHT or 15)
            local icon = b:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints()
            b.icon = icon
            b:Hide()
            list[i] = b
        end
    end
    FluxRaidVisuals.EnsureAuraMaxSlots(frame)
    make(frame.buffFrames, frame.maxBuffs or 3)
    make(frame.debuffFrames, frame.maxDebuffs or 3)
    make(frame.dispelDebuffFrames, frame.maxDispelDebuffs or 3)
    frame._fluxAuraButtons = true
end

local function LayoutClassicAuras(frame)
    if not frame._fluxAuraButtons then return end
    local aw = FluxRaidVisuals.AURA_ICON_WIDTH or 11
    local ah = FluxRaidVisuals.AURA_ICON_HEIGHT or 15
    local gap = 1
    local focus = FluxRaidVisuals.GetAuraFocusMode()
    local function place(list, point, xSign, yBase)
        for i = 1, #list do
            local b = list[i]
            local col = (i - 1) % 3
            local row = floor((i - 1) / 3)
            b:SetSize(aw, ah)
            b:ClearAllPoints()
            b:SetPoint(point, frame, point, xSign * (col * (aw + gap) + 1), yBase + row * (ah + gap))
            b:SetAlpha(FluxRaidVisuals.AURA_ICON_ALPHA or 1)
        end
    end
    if focus == "buff" then
        place(frame.buffFrames, "TOPLEFT", 1, -1)
        place(frame.debuffFrames, "BOTTOMRIGHT", -1, 2)
    else
        place(frame.debuffFrames, "BOTTOMLEFT", 1, 2)
        place(frame.buffFrames, "BOTTOMRIGHT", -1, 2)
    end
    place(frame.dispelDebuffFrames, "TOPRIGHT", -1, -1)
end

local function ReadAura(unit, index, filter)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if ok then return data end
        return nil
    end
    if not UnitAura then return nil end
    local ok, name, icon, count, dispelType, duration, expiration, source, _, _, spellId = pcall(UnitAura, unit, index, filter)
    if not ok or not name then return nil end
    return {
        name = name,
        icon = icon,
        applications = count,
        dispelName = dispelType,
        spellId = spellId,
    }
end

local function FillAuraButton(button, aura, dispellableOnly)
    if not button then return false end
    if not aura or IsSecret(aura.icon) or not aura.icon then
        button:Hide()
        return false
    end
    if dispellableOnly then
        local can = aura.canActivePlayerDispel
        if IsSecret(can) or can == false then
            button:Hide()
            return false
        end
    end
    pcall(button.icon.SetTexture, button.icon, aura.icon)
    button:Show()
    return true
end

function FluxRaid_UpdateAuras(frame)
    if not frame or frame._fluxRaidMini then return end
    if frame._fluxPrivateAuraMixed or (FluxRaidVisuals.ConfigurePrivateAuras and FluxRaidVisuals.ConfigurePrivateAuras(frame)) then
        FluxRaidVisuals.UpdatePrivateAuraUnit(frame)
        return
    end
    EnsureClassicAuraButtons(frame)
    LayoutClassicAuras(frame)
    local unit = UnitOf(frame)
    if type(unit) ~= "string" then return end
    local opt = frame.optionTable or {}
    local dispellableOnly = opt.displayOnlyDispellableDebuffs and true or false
    local function fill(list, filter, harmful)
        local shown = 0
        local maxN = list and #list or 0
        if (filter == "HELPFUL" and opt.displayBuffs == false) or (harmful and opt.displayDebuffs == false) then
            for i = 1, maxN do list[i]:Hide() end
            return
        end
        if harmful and dispellableOnly then
            filter = "HARMFUL|RAID"
        end
        for i = 1, 40 do
            if shown >= maxN then break end
            local aura = ReadAura(unit, i, filter)
            if not aura then break end
            if IsSecret(aura) then break end
            if FillAuraButton(list[shown + 1], aura, harmful and dispellableOnly) then
                shown = shown + 1
            end
        end
        for i = shown + 1, maxN do
            list[i]:Hide()
        end
    end
    fill(frame.buffFrames, "HELPFUL", false)
    fill(frame.debuffFrames, "HARMFUL", true)
end

function FluxRaid_UpdateDispelHighlight(frame)
    if not frame then return end
    FluxRaidVisuals.EnsureFluxOverlays(frame)
    local highlight = frame.dispelHighlight
    if not highlight then return end
    local function hide()
        ShowRegion(highlight, false)
    end
    if not FluxRaid_IsDispelHighlightEnabled or not FluxRaid_IsDispelHighlightEnabled() then
        hide()
        return
    end
    if frame._fluxPrivateAuraMixed then
        hide()
        return
    end
    local unit = UnitOf(frame)
    if not (Compat.UnitTokenValid and Compat.UnitTokenValid(unit)) then
        hide()
        return
    end
    local bestType
    if AuraUtil and AuraUtil.ForEachAura then
        pcall(function()
            AuraUtil.ForEachAura(unit, "HARMFUL", nil, function(aura)
                if not aura then return end
                local name = aura.dispelName
                local can = aura.canActivePlayerDispel
                if IsSecret(name) or IsSecret(can) then return end
                if name and DISPEL_TYPES[name] and can == true then
                    bestType = name
                    return true
                end
            end)
        end)
    end
    if not bestType then
        hide()
        return
    end
    local fill = highlight.fill
    local border = highlight.border or highlight
    if AuraUtil and AuraUtil.SetAuraBorderColor then
        if fill then pcall(AuraUtil.SetAuraBorderColor, fill, bestType) end
        if border then pcall(AuraUtil.SetAuraBorderColor, border, bestType) end
    end
    ShowRegion(highlight, true)
end

function FluxRaid_PaintUnit(frame)
    if not frame then return end
    local unit = UnitOf(frame)
    frame.unitExists = Compat.UnitTokenValid and Compat.UnitTokenValid(unit) or false
    if not frame.unitExists then
        FluxRaid_UpdateHealPrediction(frame)
        ShowRegion(frame.aggroHighlight, false)
        return
    end
    FluxRaid_UpdateHealth(frame)
    FluxRaid_UpdatePower(frame)
    FluxRaid_UpdateName(frame)
    FluxRaid_UpdateStatusText(frame)
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
    "UNIT_IN_RANGE_UPDATE",
}

local function RegisterUnitEvents(frame, unit)
    if not frame or not frame.RegisterUnitEvent or type(unit) ~= "string" or unit == "" then return end
    for i = 1, #UNIT_EVENTS do
        pcall(frame.RegisterUnitEvent, frame, UNIT_EVENTS[i], unit)
    end
end

local function OnUnitEvent(self, event, arg1)
    if event == "PLAYER_REGEN_ENABLED" then
        if self.UnregisterEvent then self:UnregisterEvent("PLAYER_REGEN_ENABLED") end
        if self._fluxPowerLayoutPending then ApplyPowerVisibility(self) end
        return
    end
    if event == "UNIT_TARGET" and self._fluxRaidUnit and not self._fluxRaidMini then
        if FluxRaid_AttachOrUpdateMTMATarget then
            FluxRaid_AttachOrUpdateMTMATarget(self, UnitOf(self))
        end
    end
    if type(arg1) == "string" and arg1 ~= "" and arg1 ~= self.unit and arg1 ~= self.displayedUnit then
        if event ~= "UNIT_TARGET" then
            return
        end
    end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        FluxRaid_UpdateHealth(self)
        FluxRaid_UpdateStatusText(self)
        FluxRaid_UpdateHealPrediction(self)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        FluxRaid_UpdatePower(self)
    elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_CONNECTION" or event == "UNIT_FLAGS" then
        FluxRaid_UpdateName(self)
        FluxRaid_UpdateHealth(self)
        FluxRaid_UpdateStatusText(self)
        FluxRaid_UpdateCenterStatus(self)
    elseif event == "UNIT_AURA" then
        FluxRaid_UpdateAuras(self)
        FluxRaid_UpdateDispelHighlight(self)
        if FluxRaidFrame_BigDebuffs_TryUpdate then
            FluxRaidFrame_BigDebuffs_TryUpdate(self)
        end
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then
        FluxRaid_UpdateAggroHighlight(self)
    elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        FluxRaid_UpdateHealPrediction(self)
    elseif event == "UNIT_IN_RANGE_UPDATE" then
        FluxRaid_UpdateRange(self)
    elseif event == "INCOMING_RESURRECT_CHANGED" then
        FluxRaid_UpdateCenterStatus(self)
    elseif event == "UNIT_TARGET" and self._fluxRaidMini then
        FluxRaid_PaintUnit(self)
    end
end

function FluxRaid_BindUnit(frame, unit)
    if not frame then return end
    if unit == "" then unit = nil end
    frame.unit = unit
    frame.displayedUnit = unit
    if unit then
        RegisterUnitEvents(frame, unit)
        if frame._fluxRaidMini and unit and not (InCombatLockdown and InCombatLockdown()) then
            pcall(frame.SetAttribute, frame, "unit", unit)
        end
        FluxRaid_PaintUnit(frame)
    else
        if frame.UnregisterAllEvents then
            pcall(frame.UnregisterAllEvents, frame)
        end
        frame.unitExists = false
        if frame._fluxPrivateAuraMixed then
            FluxRaidVisuals.UpdatePrivateAuraUnit(frame)
        end
    end
    State.frameArray[frame] = frame
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
        if not self:GetAttribute("type2") then
            self:SetAttribute("type2", "togglemenu")
        end
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
    EnsureRangePoll(self)
end

function FluxRaidUnit_OnShow(self)
    local unit = self:GetAttribute("unit") or self.unit
    if unit and unit ~= self.unit then
        FluxRaid_BindUnit(self, unit)
    else
        FluxRaid_PaintUnit(self)
    end
end

function FluxRaidUnit_OnHide(self)
    ShowRegion(self.aggroHighlight, false)
end

-- Flux-owned tooltip. Blizzard's UnitFrame_UpdateTooltip throws on a nil unit
-- (unbound header children); replacing that global would taint every unit frame.
local function FluxRaidUnit_UpdateTooltip(self)
    local unit = self.unit
    if type(unit) ~= "string" or unit == "" then
        self.UpdateTooltip = nil
        return
    end
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    if GameTooltip:SetUnit(unit, self.hideStatusOnTooltip) then
        if GameTooltip_AddBlankLineToTooltip and GameTooltip_AddInstructionLine and UNIT_POPUP_RIGHT_CLICK then
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
            GameTooltip_AddInstructionLine(GameTooltip, UNIT_POPUP_RIGHT_CLICK)
        end
        GameTooltip:Show()
        self.UpdateTooltip = FluxRaidUnit_UpdateTooltip
    else
        self.UpdateTooltip = nil
    end
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
    if GameTooltip.FadeOut then
        GameTooltip:FadeOut()
    else
        GameTooltip:Hide()
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
            FluxRaid_PaintUnit(btn)
        end
    end)
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
    if rangePollTicker or not C_Timer or not C_Timer.NewTicker then return end
    if frame and Compat.HasRangeAlphaBoolean(frame) then return end
    rangePollTicker = C_Timer.NewTicker(1.0, function()
        if not FluxRaid_IsFluxRaidEnabled or not FluxRaid_IsFluxRaidEnabled() then return end
        local sawBooleanAlpha = false
        for btn in pairs(State.frameArray) do
            if btn and Compat.HasRangeAlphaBoolean(btn) then
                sawBooleanAlpha = true
            elseif btn and btn.unit and btn.IsShown and btn:IsShown() then
                FluxRaid_UpdateRange(btn)
                FluxRaid_UpdateStatusText(btn)
            end
        end
        if sawBooleanAlpha and rangePollTicker then
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
    local miniH = max(10, floor((FluxRaidVisuals.FRAME_HEIGHT or 36) * (18 / 36) + 0.5))
    FluxRaidVisuals.ApplyCellChrome(frame, {
        width = FluxRaidVisuals.FRAME_WIDTH,
        height = miniH,
        showPower = false,
    })
    if not (InCombatLockdown and InCombatLockdown()) then
        pcall(frame.SetSize, frame, FluxRaidVisuals.FRAME_WIDTH, miniH)
    end
    frame.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
end

local function CreateMTMATarget(parentBtn)
    local container = State.containerFrame
    local wrap = CreateFrame("Frame", nil, container or parentBtn)
    local h = Compat.MTMA_TARGET_HEIGHT or 18
    local gap = Compat.MTMA_TARGET_GAP or 2
    wrap:SetSize(FluxRaidVisuals.FRAME_WIDTH, h)
    wrap:SetPoint("TOPLEFT", parentBtn, "BOTTOMLEFT", 0, -gap)
    wrap:SetPoint("TOPRIGHT", parentBtn, "BOTTOMRIGHT", 0, -gap)
    wrap:SetAlpha(0)
    mtmaNameCounter = mtmaNameCounter + 1
    local tf = CreateFrame("Button", "FluxRaidMTMATarget" .. mtmaNameCounter, wrap, "SecureUnitButtonTemplate")
    tf:SetAllPoints(wrap)
    tf._fluxWrap = wrap
    tf._fluxRaidMini = true
    tf._fluxRaidUnit = true
    if not InCombatLockdown() then
        tf:SetAttribute("*type1", "target")
        tf:SetAttribute("type2", "togglemenu")
        tf:RegisterForClicks("AnyUp")
    end
    FluxCompactMiniFrameSetup(tf)
    tf:SetScript("OnEvent", OnUnitEvent)
    if ClickCastFrames then
        ClickCastFrames[tf] = true
    end
    parentBtn._fluxMTMATarget = tf
    State.frameArray[tf] = tf
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
