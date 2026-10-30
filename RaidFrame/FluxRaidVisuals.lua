local addonName, ns = ...

-- Flux raid visuals: tunables, compact-cell chrome, and private-aura slot counts.
-- Unit buttons are Flux-owned SecureUnitButtons. This file does not call CompactUnitFrame_Update*.

FluxRaidVisuals = {}

local floor = math.floor
local max = math.max
local min = math.min

local FRAME_WIDTH_DEFAULT = 72
local FRAME_HEIGHT_BASE = 36
local FRAME_HEIGHT_SCALE = 1.2
local POWER_BAR_HEIGHT_BASE = 8
local NATIVE_UNIT_FRAME_AURA_SIZE = 11
local RAID_AURA_ICON_X_SQUEEZE = 0.75
local NATIVE_CENTER_STATUS_SCALE = 2

local function ComputePowerBarHeightPx(scale)
    scale = tonumber(scale)
    if not scale then scale = 1 end
    return max(1, floor(POWER_BAR_HEIGHT_BASE * 0.75 * scale + 0.5))
end

FluxRaidVisuals.FRAME_WIDTH = FRAME_WIDTH_DEFAULT
FluxRaidVisuals.FRAME_HEIGHT = floor(FRAME_HEIGHT_BASE * FRAME_HEIGHT_SCALE + 0.5)
FluxRaidVisuals.FRAME_HEIGHT_BASE = FRAME_HEIGHT_BASE
FluxRaidVisuals.FRAME_HEIGHT_SCALE = FRAME_HEIGHT_SCALE
FluxRaidVisuals.POWER_BAR_HEIGHT = ComputePowerBarHeightPx(1)
FluxRaidVisuals.AURA_ICON_HEIGHT = floor(NATIVE_UNIT_FRAME_AURA_SIZE * 1.4 + 0.5)
FluxRaidVisuals.AURA_ICON_WIDTH = max(1, floor(FluxRaidVisuals.AURA_ICON_HEIGHT * RAID_AURA_ICON_X_SQUEEZE + 0.5))
FluxRaidVisuals.ROLE_ICON_SIZE = 14
FluxRaidVisuals.BLIZZARD_RAID_MANAGER_SCALE = 0.9
FluxRaidVisuals.FRAME_BASE_ALPHA = 1
FluxRaidVisuals.RANGE_ALPHA_IN_RANGE = 0.9
FluxRaidVisuals.RANGE_ALPHA_OUT_OF_RANGE = 0.44
FluxRaidVisuals.AURA_ICON_ALPHA = 1
FluxRaidVisuals.HIGHLIGHT_COLOR_TARGET = { 1.0, 0.82, 0.15 }
FluxRaidVisuals.HIGHLIGHT_COLOR_MOUSEOVER = { 0.45, 0.78, 1.0 }

-- Used by world preview (non-CUF) power bars.
FluxRaidVisuals.POWER_COLORS = {
    [0] = { r = 0.00, g = 0.00, b = 1.00 }, -- Mana
    [1] = { r = 1.00, g = 0.00, b = 0.00 }, -- Rage
    [2] = { r = 1.00, g = 0.50, b = 0.25 }, -- Focus
    [3] = { r = 1.00, g = 1.00, b = 0.00 }, -- Energy
    [6] = { r = 0.00, g = 0.82, b = 1.00 }, -- Runic Power
    [17] = { r = 0.79, g = 0.26, b = 0.99 }, -- Fury
}

function FluxRaidVisuals.ApplyRaidFrameTunables(opts)
    opts = opts or {}
    local wScale = tonumber(opts.memberWidthScale) or 1
    local hScale = tonumber(opts.frameHeightScale) or 1.2
    local pbScale = tonumber(opts.powerBarHeightScale)
    if pbScale == nil then pbScale = 1 end
    pbScale = max(0.5, min(2.5, pbScale))
    local auraScale = tonumber(opts.auraIconScale) or 1.4
    local mgrScale = tonumber(opts.raidManagerScale)
    if mgrScale == nil then mgrScale = 0.9 end

    local baseA = tonumber(opts.frameBaseAlpha)
    if baseA == nil then baseA = 1 end
    FluxRaidVisuals.FRAME_BASE_ALPHA = max(0.1, min(1, baseA))

    local rIn = tonumber(opts.rangeAlphaInRange)
    if rIn == nil then rIn = 0.9 end
    FluxRaidVisuals.RANGE_ALPHA_IN_RANGE = max(0.05, min(1, rIn))

    local rOut = tonumber(opts.rangeAlphaOutOfRange)
    if rOut == nil then rOut = 0.44 end
    FluxRaidVisuals.RANGE_ALPHA_OUT_OF_RANGE = max(0.05, min(1, rOut))

    local auraA = tonumber(opts.auraIconAlpha)
    if auraA == nil then auraA = 1 end
    FluxRaidVisuals.AURA_ICON_ALPHA = max(0.1, min(1, auraA))

    FluxRaidVisuals.FRAME_WIDTH = max(1, floor(FRAME_WIDTH_DEFAULT * wScale + 0.5))
    FluxRaidVisuals.FRAME_HEIGHT = max(1, floor(FRAME_HEIGHT_BASE * hScale + 0.5))
    FluxRaidVisuals.POWER_BAR_HEIGHT = ComputePowerBarHeightPx(pbScale)

    FluxRaidVisuals.AURA_ICON_HEIGHT = max(8, floor(NATIVE_UNIT_FRAME_AURA_SIZE * auraScale + 0.5))
    FluxRaidVisuals.AURA_ICON_WIDTH = max(6, floor(FluxRaidVisuals.AURA_ICON_HEIGHT * RAID_AURA_ICON_X_SQUEEZE + 0.5))

    FluxRaidVisuals.BLIZZARD_RAID_MANAGER_SCALE = mgrScale

    local ht = opts.highlightTarget
    if type(ht) == "table" then
        FluxRaidVisuals.HIGHLIGHT_COLOR_TARGET = {
            tonumber(ht.r) or 1,
            tonumber(ht.g) or 0.82,
            tonumber(ht.b) or 0.15,
        }
    end
    local hm = opts.highlightMouseover
    if type(hm) == "table" then
        FluxRaidVisuals.HIGHLIGHT_COLOR_MOUSEOVER = {
            tonumber(hm.r) or 0.45,
            tonumber(hm.g) or 0.78,
            tonumber(hm.b) or 1,
        }
    end
end

function FluxRaidVisuals.ApplyRaidHighlightVertexColors(frame)
    if not frame then return end
    local ct = FluxRaidVisuals.HIGHLIGHT_COLOR_TARGET
    local cm = FluxRaidVisuals.HIGHLIGHT_COLOR_MOUSEOVER
    if frame.selectionHighlight and frame.selectionHighlight.SetVertexColor then
        pcall(frame.selectionHighlight.SetVertexColor, frame.selectionHighlight, ct[1], ct[2], ct[3])
    end
    if frame.mouseOverHighlight and frame.mouseOverHighlight.SetVertexColor then
        pcall(frame.mouseOverHighlight.SetVertexColor, frame.mouseOverHighlight, cm[1], cm[2], cm[3])
    end
    if frame.targetHighlight and frame.targetHighlight.SetVertexColor then
        pcall(frame.targetHighlight.SetVertexColor, frame.targetHighlight, ct[1], ct[2], ct[3])
    end
end

--- Combat-safe SetSize for secure CUF unit buttons. Queues retry when locked.
function FluxRaidVisuals.SafeSetUnitFrameSize(frame, width, height)
    if not frame or not frame.SetSize then
        return false
    end
    width = tonumber(width) or FluxRaidVisuals.FRAME_WIDTH
    height = tonumber(height) or FluxRaidVisuals.FRAME_HEIGHT
    if InCombatLockdown and InCombatLockdown() then
        frame._fluxNeedsSizeRefresh = true
        if FluxRaid_QueueConfigureAndRefresh then
            FluxRaid_QueueConfigureAndRefresh()
        end
        return false
    end
    local ok = pcall(frame.SetSize, frame, width, height)
    if ok then
        frame._fluxNeedsSizeRefresh = nil
    else
        -- Out of combat but still blocked (taint): mark dirty; do not re-queue here
        -- (would recurse through ConfigureAndRefresh).
        frame._fluxNeedsSizeRefresh = true
    end
    return ok
end

--- Ensure Flux-only overlays exist on a CUF (mouseover ring + optional dispel tint).
function FluxRaidVisuals.EnsureFluxOverlays(frame)
    if not frame then return end

    if not frame.mouseOverHighlight then
        local tex = frame:CreateTexture(nil, "OVERLAY", nil, 5)
        tex:SetAllPoints(frame)
        tex:SetAtlas("RaidFrame-TargetFrame")
        tex:SetIgnoreParentAlpha(true)
        tex:Hide()
        frame.mouseOverHighlight = tex
    end

    -- CompactUnitFrame.xml leaves aggro/selection shown; CUF Update* hides them.
    -- Flux owns those updates now â€” start hidden so they are not a white ring out of combat.
    if frame.aggroHighlight and frame.aggroHighlight.Hide then
        pcall(frame.aggroHighlight.Hide, frame.aggroHighlight)
    end
    if frame.selectionHighlight and frame.selectionHighlight.Hide then
        pcall(frame.selectionHighlight.Hide, frame.selectionHighlight)
    end

    -- raidframe-hp-bg-white is meant to be vertex-tinted. Untinted = white 1px ring.
    local function tintBg(tex, r, g, b)
        if tex and tex.SetVertexColor then
            pcall(tex.SetVertexColor, tex, r, g, b)
        end
    end
    tintBg(frame.background, 0.07, 0.07, 0.08)
    if frame.healthBar then
        tintBg(frame.healthBar.background, 0.07, 0.07, 0.08)
    end
    if frame.TotalAbsorbLeftShadow and frame.TotalAbsorbLeftShadow.Hide then
        pcall(frame.TotalAbsorbLeftShadow.Hide, frame.TotalAbsorbLeftShadow)
    end

    -- Migrate pre-fix texture-only highlight to Blizzard-style fill + border frame.
    if frame.dispelHighlight and not frame.dispelHighlight.fill then
        pcall(function()
            if frame.dispelHighlight.Hide then
                frame.dispelHighlight:Hide()
            end
        end)
        frame.dispelHighlight = nil
    end

    -- Type-colored dispel fallback (Blizzard DispelOverlay style fill + border).
    -- Used when native DispelOverlay is missing or not shown (esp. Classic PA gaps).
    if not frame.dispelHighlight then
        local overlay = CreateFrame("Frame", nil, frame)
        overlay:SetAllPoints(frame)
        overlay:Hide()
        if overlay.SetIgnoreParentAlpha then
            overlay:SetIgnoreParentAlpha(true)
        end

        local fill = overlay:CreateTexture(nil, "ARTWORK", nil, 0)
        fill:SetAllPoints(overlay)
        if not pcall(fill.SetAtlas, fill, "RaidFrame-Dispel-Fill") then
            fill:SetColorTexture(1, 1, 1, 0.2)
        else
            fill:SetAlpha(0.2)
        end
        overlay.fill = fill

        local border = overlay:CreateTexture(nil, "OVERLAY", nil, 1)
        border:SetAllPoints(overlay)
        if not pcall(border.SetAtlas, border, "RaidFrame-DispelHighlight") then
            pcall(border.SetAtlas, border, "RaidFrame-TargetFrame")
        end
        overlay.border = border

        frame.dispelHighlight = overlay
    end

    frame._fluxOverlaysReady = true
    FluxRaidVisuals.ApplyRaidHighlightVertexColors(frame)
end

local function GetFluxAuraIconScale()
    return max(0.5, min(2.5, (FluxRaidVisuals.AURA_ICON_HEIGHT or NATIVE_UNIT_FRAME_AURA_SIZE) / NATIVE_UNIT_FRAME_AURA_SIZE))
end

--- "debuff" (default) or "buff" from Raid Frame options.
function FluxRaidVisuals.GetAuraFocusMode()
    if FluxOptions and FluxOptions.GetRaidFrameDB then
        local db = FluxOptions:GetRaidFrameDB()
        if db and db.auraFocusMode == "buff" then
            return "buff"
        end
    end
    return "debuff"
end

--- Map focus mode to Blizzard Enum.RaidAuraOrganizationType (all clients).
--- Debuff focused â†’ Legacy (debuffs bottom-left). Buff focused â†’ BuffsTopDebuffsBottom.
function FluxRaidVisuals.GetAuraOrganizationType()
    local enum = Enum and Enum.RaidAuraOrganizationType
    local mode = FluxRaidVisuals.GetAuraFocusMode()
    if mode == "buff" then
        if enum and enum.BuffsTopDebuffsBottom ~= nil then
            return enum.BuffsTopDebuffsBottom
        end
        return 1
    end
    if enum and enum.Legacy ~= nil then
        return enum.Legacy
    end
    return 0
end

local function ApplyFluxAuraOrganization(frame)
    if not frame then return end
    local org = FluxRaidVisuals.GetAuraOrganizationType()
    frame.auraOrganizationType = org
    if frame.SetAuraOrganizationType then
        pcall(frame.SetAuraOrganizationType, frame, org)
    end
end

local function CVarBool(name, defaultIfMissing)
    if FluxRaid_GetCVarBool then
        return FluxRaid_GetCVarBool(name, defaultIfMissing)
    end
    return defaultIfMissing
end

function FluxRaidVisuals.UsesPrivateAuras(frame)
    if frame and frame._fluxPrivateAuraMixed then
        return true
    end
    return FluxRaidCompat and FluxRaidCompat.HasPrivateAuraContainer and FluxRaidCompat.HasPrivateAuraContainer()
end

local fluxRaidOptionTable

function FluxRaidVisuals.GetFluxRaidOptionTable()
    if not fluxRaidOptionTable then
        fluxRaidOptionTable = {}
    end
    FluxRaidVisuals.SyncAuraDisplayOptions(fluxRaidOptionTable)
    return fluxRaidOptionTable
end

local function RaidOptionFlag(db, key, defaultOn)
    if not db or db[key] == nil then
        return defaultOn and true or false
    end
    return db[key] and true or false
end

function FluxRaidVisuals.SyncAuraDisplayOptions(opt)
    if type(opt) ~= "table" then return end
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    opt.displayBuffs = RaidOptionFlag(db, "displayBuffs", true)
    opt.displayDebuffs = RaidOptionFlag(db, "displayDebuffs", true)
    opt.displayOnlyDispellableDebuffs = RaidOptionFlag(db, "displayOnlyDispellableDebuffs", false)
    opt.displayDispelDebuffs = true
    if opt.displayNonBossDebuffs == nil then
        opt.displayNonBossDebuffs = true
    end
    local showOverlay = true
    if FluxRaid_IsDispelHighlightEnabled then
        showOverlay = FluxRaid_IsDispelHighlightEnabled() and true or false
    end
    opt.showDispelIndicatorOverlay = showOverlay
    local dispelEnum = Enum and Enum.RaidDispelDisplayType
    if dispelEnum and dispelEnum.DispellableByMe ~= nil then
        opt.raidFramesDispelIndicatorType = dispelEnum.DispellableByMe
    elseif dispelEnum and dispelEnum.DisplayAll ~= nil then
        opt.raidFramesDispelIndicatorType = dispelEnum.DisplayAll
    end
    opt.useClassColors = RaidOptionFlag(db, "useClassColors", true)
    opt.displayHealPrediction = RaidOptionFlag(db, "showHealPrediction", true)
    opt.fadeOutOfRange = RaidOptionFlag(db, "showRangeFade", true)
    opt.displayInOtherPhase = CVarBool("raidFramesDisplayInOtherPhase", true)
    opt.displayPowerBar = RaidOptionFlag(db, "displayPowerBar", true)
    opt.showAggroHighlight = RaidOptionFlag(db, "showAggroHighlight", true)
    opt.showRoleIcon = RaidOptionFlag(db, "showRoleIcon", true)
    opt.showTargetHighlight = RaidOptionFlag(db, "showTargetHighlight", true)
    opt.showMouseoverHighlight = RaidOptionFlag(db, "showMouseoverHighlight", true)
    opt.showGroupLabels = RaidOptionFlag(db, "showGroupLabels", true)
    local ht = db and db.healthText
    if ht ~= "none" and ht ~= "health" and ht ~= "perc" and ht ~= "healthandpercent" and ht ~= "losthealth" then
        ht = "perc"
    end
    opt._fluxHealthText = ht
    opt.healthText = ht
    opt.displayStatusText = (ht ~= "none")
end

function FluxRaidVisuals.EnsureAuraMaxSlots(frame)
    if not frame then return end
    local focus = FluxRaidVisuals.GetAuraFocusMode()
    local usePrivate = FluxRaidVisuals.UsesPrivateAuras(frame)
    local maxBuffs, maxDebuffs
    if focus == "buff" then
        maxBuffs, maxDebuffs = 6, 3
    else
        maxBuffs = 3
        maxDebuffs = usePrivate and 5 or 3
    end
    frame.maxBuffs = maxBuffs
    frame.maxDebuffs = maxDebuffs
    frame.maxDispelDebuffs = 3
end

local function QueuePrivateAuraSync(frame)
    if not frame then return end
    frame._fluxNeedsPrivateAuraSync = true
    if FluxRaid_QueueConfigureAndRefresh then
        FluxRaid_QueueConfigureAndRefresh()
    end
end

local function SetFluxPrivateAuraAnchorSettings(host)
    host._fluxNativeSetPrivateAuraAnchorSettings(host)
    if host.optionTable and host.optionTable.displayOnlyDispellableDebuffs then
        -- Blizzard's normal debuff row keeps boss/role/priority exceptions.
        -- Restrict icons to its HARMFUL|RAID dispel row for Flux's strict toggle.
        host:SetAttribute("ignore-debuffs", true)
    end
end

function FluxRaidVisuals.ConfigurePrivateAuras(frame)
    if not frame or frame._fluxRaidMini then
        return false
    end
    if not (FluxRaidCompat and FluxRaidCompat.HasPrivateAuraContainer and FluxRaidCompat.HasPrivateAuraContainer()) then
        return false
    end
    local mixin = rawget(_G, "ContainerPrivateAuraBehaviorMixin")
    local host = frame._fluxPrivateAuraHost
    if not host then
        if not mixin or not Mixin then return false end
        if InCombatLockdown and InCombatLockdown() then
            QueuePrivateAuraSync(frame)
            return true
        end
        -- Blizzard owns this child's OnAttributeChanged. The secure unit button
        -- has Flux's unit hook, which cannot also be the private-aura handler.
        host = frame.auraHost or CreateFrame("Frame", nil, frame)
        host:SetAllPoints(frame)
        host:EnableMouse(false)
        if not pcall(Mixin, host, mixin) then return false end
        host._fluxNativeSetPrivateAuraAnchorSettings = host.SetPrivateAuraAnchorSettings
        host.SetPrivateAuraAnchorSettings = SetFluxPrivateAuraAnchorSettings
        frame._fluxPrivateAuraHost = host
        frame._fluxPrivateAuraMixed = true
    end
    local auraSize = FluxRaidVisuals.AURA_ICON_HEIGHT or NATIVE_UNIT_FRAME_AURA_SIZE
    local borderScale = GetFluxAuraIconScale()
    if host.SetAuraSize then pcall(host.SetAuraSize, host, auraSize) end
    if host.SetDebuffAuraSize then pcall(host.SetDebuffAuraSize, host, auraSize) end
    if host.SetBuffAuraSize then pcall(host.SetBuffAuraSize, host, auraSize) end
    if host.SetBorderScale then pcall(host.SetBorderScale, host, borderScale) end
    if host.SetDebuffBorderScale then pcall(host.SetDebuffBorderScale, host, borderScale) end
    if host.SetBuffBorderScale then pcall(host.SetBuffBorderScale, host, borderScale) end
    ApplyFluxAuraOrganization(frame)
    ApplyFluxAuraOrganization(host)
    FluxRaidVisuals.EnsureAuraMaxSlots(frame)
    host.maxBuffs, host.maxDebuffs, host.maxDispelDebuffs = frame.maxBuffs, frame.maxDebuffs, frame.maxDispelDebuffs
    if CompactRaidGroupTypeEnum then
        frame.groupType = frame.groupType or CompactRaidGroupTypeEnum.Raid
    end
    host.groupType = frame.groupType
    frame.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
    host.optionTable = frame.optionTable
    host.displayedUnit = frame.displayedUnit or frame.unit
    local pbh = frame.powerBar and frame.powerBar:IsShown() and (FluxRaidVisuals.POWER_BAR_HEIGHT or 0) or 0
    frame.powerBarUsedHeight = pbh
    if host.SetPowerBarUsedHeight then
        pcall(host.SetPowerBarUsedHeight, host, pbh)
    end
    return true
end

function FluxRaidVisuals.UpdatePrivateAuraUnit(frame)
    if not frame then return end
    if InCombatLockdown and InCombatLockdown() then
        QueuePrivateAuraSync(frame)
        return
    end
    local host = frame._fluxPrivateAuraHost
    if not host then return end
    if frame._fluxNeedsPrivateAuraSync then
        FluxRaidVisuals.SyncPrivateAuraSettings(frame, false, true)
        return
    end
    local unit = frame.displayedUnit or frame.unit
    host.displayedUnit = unit
    -- Live/Forever use this field; Era/Anniversary use the third argument.
    -- Neither may preserve an anchor when its unit changes (including nil).
    host.avoidPrivateAuraAnchorChange = nil
    local ok = pcall(host.SetPrivateAuraAnchorUnit, host, unit, unit ~= nil and not host.anchorID, false)
    frame._fluxNeedsPrivateAuraSync = not ok or nil
end

--- Settings-only attribute push. avoidRebuild=true does not tear down an existing anchor.
function FluxRaidVisuals.SyncPrivateAuraSettings(frame, force, avoidRebuild)
    if not frame or not frame._fluxPrivateAuraMixed then
        return
    end
    FluxRaidVisuals.ConfigurePrivateAuras(frame)
    if InCombatLockdown and InCombatLockdown() then
        QueuePrivateAuraSync(frame)
        return
    end
    local host = frame._fluxPrivateAuraHost
    if not host then return end
    local unit = frame.displayedUnit or frame.unit
    host.avoidPrivateAuraAnchorChange = nil
    local ok
    if avoidRebuild and host.anchorID and host.privateAuraUnit == unit then
        -- The public settings trigger preserves the anchor on every client.
        ok = pcall(host.TriggerPrivateAuraSettingsUpdate, host)
    else
        local forceUpdate = force or not avoidRebuild or (unit ~= nil and not host.anchorID)
        ok = pcall(host.SetPrivateAuraAnchorUnit, host, unit, forceUpdate, false)
    end
    frame._fluxNeedsPrivateAuraSync = not ok or nil
end

function FluxRaidVisuals.PushAuraDisplayToFrame(frame)
    if not frame or frame._fluxRaidMini then return end
    frame.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
    ApplyFluxAuraOrganization(frame)
    FluxRaidVisuals.EnsureAuraMaxSlots(frame)
    if frame._fluxPrivateAuraMixed or FluxRaidVisuals.ConfigurePrivateAuras(frame) then
        FluxRaidVisuals.SyncPrivateAuraSettings(frame, true, true)
    end
end

function FluxRaidVisuals.NeutralizeBlizzardSharedUpdateAllSetup()
end

function FluxRaidVisuals.ResealCompactUnitFrameOnUpdate(_frame)
end

--- Lay out Flux-owned cell widgets. Missing children are skipped (preview template).
function FluxRaidVisuals.ApplyCellChrome(frame, opts)
    if not frame then return end
    opts = opts or {}
    local fw = tonumber(opts.width) or FluxRaidVisuals.FRAME_WIDTH
    local fh = tonumber(opts.height) or FluxRaidVisuals.FRAME_HEIGHT
    local showPower = opts.showPower
    if showPower == nil then
        showPower = CVarBool("raidFramesDisplayPowerBars", true)
    end
    local pbh = showPower and (tonumber(FluxRaidVisuals.POWER_BAR_HEIGHT) or 0) or 0
    frame.powerBarUsedHeight = pbh
    local hudBars = ns and ns.UnitFrames and ns.UnitFrames.UsesHudUnitBars
        and ns.UnitFrames.UsesHudUnitBars()

    if frame.background and frame.background.SetColorTexture then
        frame.background:SetColorTexture(0.07, 0.07, 0.08, 1)
    end

    if frame.healthBar then
        frame.healthBar:ClearAllPoints()
        frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        -- Live/Forever may restrict max power. Keep HP behind the resource
        -- layer so a secret zero can reveal the full bar through native alpha.
        frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, hudBars and 1 or 1 + pbh)
        if frame.healthBar.SetStatusBarTexture then
            pcall(frame.healthBar.SetStatusBarTexture, frame.healthBar, "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
        end
        if frame.healthBar.SetMinMaxValues then
            pcall(frame.healthBar.SetMinMaxValues, frame.healthBar, 0, 100)
        end
        if frame.healthBar.background and frame.healthBar.background.SetColorTexture then
            frame.healthBar.background:SetColorTexture(0.07, 0.07, 0.08, 1)
        end
    end

    if frame.powerBar then
        if hudBars and not frame._fluxPowerAboveHealth
            and not (InCombatLockdown and InCombatLockdown())
            and frame.healthBar and frame.healthBar.GetFrameLevel then
            frame.powerBar:SetFrameLevel(frame.healthBar:GetFrameLevel() + 2)
            frame._fluxPowerAboveHealth = true
        end
        if showPower then
            frame.powerBar:ClearAllPoints()
            if hudBars then
                frame.powerBar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 1, 1 + pbh)
            else
                frame.powerBar:SetPoint("TOPLEFT", frame.healthBar or frame, frame.healthBar and "BOTTOMLEFT" or "BOTTOMLEFT", 0, 0)
            end
            frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
            if frame.powerBar.SetStatusBarTexture then
                pcall(frame.powerBar.SetStatusBarTexture, frame.powerBar, "Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
            end
            if frame.powerBar.SetMinMaxValues then
                pcall(frame.powerBar.SetMinMaxValues, frame.powerBar, 0, 100)
            end
            frame.powerBar:Show()
        else
            frame.powerBar:Hide()
        end
    end

    if frame.name then
        frame.name:ClearAllPoints()
        frame.name:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -2)
        frame.name:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -2)
        frame.name:SetJustifyH("LEFT")
        frame.name:SetWordWrap(false)
    end
    if frame.statusText then
        frame.statusText:ClearAllPoints()
        frame.statusText:SetPoint("BOTTOMRIGHT", frame.healthBar or frame, "BOTTOMRIGHT", -2, 1)
        frame.statusText:SetJustifyH("RIGHT")
    end
    if frame.roleIcon then
        local s = FluxRaidVisuals.ROLE_ICON_SIZE or 12
        frame.roleIcon:ClearAllPoints()
        frame.roleIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        frame.roleIcon:SetSize(s, s)
    end
    if frame.centerStatusIcon then
        frame.centerStatusIcon:ClearAllPoints()
        frame.centerStatusIcon:SetPoint("CENTER", frame, "BOTTOM", 0, 8)
        frame.centerStatusIcon:SetSize(16, 16)
    end
    if frame.readyCheckIcon then
        frame.readyCheckIcon:ClearAllPoints()
        frame.readyCheckIcon:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.readyCheckIcon:SetSize(18, 18)
    end

    local function atlas(tex, name)
        if tex and tex.SetAtlas then
            pcall(tex.SetAtlas, tex, name)
        end
    end
    if frame.aggroHighlight and frame.aggroHighlight.SetAtlas then
        if not pcall(frame.aggroHighlight.SetAtlas, frame.aggroHighlight, "RaidFrame-AggroFrame") then
            pcall(frame.aggroHighlight.SetAtlas, frame.aggroHighlight, "RaidFrame-TargetFrame")
        end
    end
    atlas(frame.selectionHighlight, "RaidFrame-TargetFrame")
    atlas(frame.mouseOverHighlight, "RaidFrame-TargetFrame")
    FluxRaidVisuals.ApplyRaidHighlightVertexColors(frame)
    FluxRaidVisuals.EnsureFluxOverlays(frame)
end

function FluxRaidVisuals.ApplyVisuals(frame)
    FluxRaidVisuals.ApplyCellChrome(frame)
    FluxRaidVisuals.PushAuraDisplayToFrame(frame)
end

function FluxRaidVisuals.SetupHealAbsorbLayers(_frame)
end

function FluxRaidVisuals.SetupReadyCheckIcon(_frame)
end

function FluxRaidVisuals.RefreshNeutralBarTracks(_frame)
end

_G.FluxRaidVisuals = FluxRaidVisuals

