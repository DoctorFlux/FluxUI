-- UnitFrames/FluxUnitFrames_OptionsBridge.lua
-- Options DB access for per-unit Flux vs Blizzard and optional feature toggles.
local addonName, ns = ...

--- True when this character should use the Flux replacement for `unit` (player, target, pet, ...).
function FluxUnitFrames_ShouldUseFlux(unit)
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if not db then
        return true
    end

    if unit == "pet" and db.useFluxPlayer == false then
        return false
    end
    if unit == "targettarget" and db.useFluxTarget == false then
        return false
    end
    if unit == "pettarget" then
        if db.useFluxPlayer == false or db.useFluxPet == false then
            return false
        end
    end
    if unit == "focustarget" then
        if db.useFluxFocus == false then
            return false
        end
        if FLUX_API and not FLUX_API.hasFocusUnit then
            return false
        end
    end

    local map = {
        player = "useFluxPlayer",
        target = "useFluxTarget",
        targettarget = "useFluxTargetOfTarget",
        focus = "useFluxFocus",
        focustarget = "useFluxFocusTarget",
        pet = "useFluxPet",
        pettarget = "useFluxPetTarget",
    }
    local key = map[unit]
    if not key then
        return true
    end
    if db[key] == false then
        return false
    end
    return true
end

--- Optional feature flags (Phase B); missing keys default to enabled.
function FluxUnitFrames_IsFeatureEnabled(featureId)
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if not db then
        return true
    end
    if featureId == "healthLossOverlay" then
        return db.enableHealthLossOverlay ~= false
    end
    if featureId == "powerCostOverlay" then
        return db.enablePowerCostOverlay ~= false
    end
    if featureId == "mp5Overlay" then
        return db.enableMP5Overlay ~= false
    end
    if featureId == "swingTimer" then
        local cap = ns.Flux and ns.Flux.Cap
        if cap and cap.disableSwingTimer then
            return false
        end
        return db.enableSwingTimer ~= false
    end
    if featureId == "flightPathTimers" then
        return db.enableFlightPathTimers ~= false
    end
    return true
end

--- Per-unit side portrait strip (player / target / focus / pet). When false, layout uses bar width only (centered anchor for player/target; pet re-anchors to the player frame). 3D vs flat rendering is FluxUnitFrames_ShouldUse3DPortrait / General → Features.
function FluxUnitFrames_ShouldShowPortrait(unit)
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if not db then
        return true
    end
    if unit == "player" then
        return db.showPortraitPlayer ~= false
    end
    if unit == "target" then
        return db.showPortraitTarget ~= false
    end
    if unit == "focus" then
        return db.showPortraitFocus ~= false
    end
    if unit == "pet" then
        return db.showPortraitPet ~= false
    end
    return true
end

local function FluxUnitFrames_DisplayRow(unit)
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    return db and db.display and db.display[unit]
end

--- Missing display keys stay on, which is how the frames draw today.
function FluxUnitFrames_DisplayEnabled(unit, key)
    local row = FluxUnitFrames_DisplayRow(unit)
    if not row or row[key] == nil then
        return true
    end
    return row[key] and true or false
end

function FluxUnitFrames_GetHealthTextMode(unit)
    local row = FluxUnitFrames_DisplayRow(unit)
    local mode = row and row.healthText
    if mode == "both" or mode == "percent" or mode == "values" or mode == "none" then
        return mode
    end
    if unit == "player" or unit == "target" then
        return "both"
    end
    return "percent"
end

function FluxUnitFrames_ShouldShowCastTime(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "castTime")
end

function FluxUnitFrames_ShouldShowPowerText(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "powerText")
end

function FluxUnitFrames_ShouldShowHealPrediction(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "healPrediction")
end

function FluxUnitFrames_ShouldShowAbsorbs(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "absorbs")
end

function FluxUnitFrames_ShouldShowClassPower()
    return FluxUnitFrames_DisplayEnabled("player", "classPower")
end

function FluxUnitFrames_GetClassPowerScale()
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    local scale = tonumber(db and db.classPowerScale) or 1
    if scale ~= scale then scale = 1 end
    return math.max(0.5, math.min(2, scale))
end

function FluxUnitFrames_ShouldShowLevel(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "level")
end

function FluxUnitFrames_ShouldShowClassIcon(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "classIcon")
end

function FluxUnitFrames_ShouldShowPvp(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "pvp")
end

function FluxUnitFrames_ShouldShowCombatIcon(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "combat")
end

function FluxUnitFrames_ShouldShowRaidIcon(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "raidIcon")
end

function FluxUnitFrames_ShouldShowPortraitCombat(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "portraitCombat")
end

function FluxUnitFrames_ShouldShowMouseover(unit)
    return FluxUnitFrames_DisplayEnabled(unit, "mouseover")
end

--- Per-unit cast bar. Pet defaults off (`showCastBarPet == true` required).
function FluxUnitFrames_ShouldShowCastBar(unit)
    if unit == "pet" then
        local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
        return db and db.showCastBarPet == true
    end
    if unit == "player" or unit == "target" or unit == "focus" then
        return FluxUnitFrames_DisplayEnabled(unit, "castBar")
    end
    return false
end

--- Pet frame mouseover buff/debuff icon strip (default on; Blizzard pet tip parity).
function FluxUnitFrames_ShouldShowPetTooltipAuras()
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if not db then
        return true
    end
    return db.showPetTooltipAuras ~= false
end

--- Global portrait render: 3D PlayerModel vs 2D SetPortraitTexture (General → Features).
function FluxUnitFrames_ShouldUse3DPortrait()
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if not db then
        return true
    end
    return db.use3DPortraits ~= false
end

--- Portrait border and backdrop turn red while that unit is in combat (General → Features). Default on.
function FluxUnitFrames_IsPortraitCombatTintEnabled()
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if not db then
        return true
    end
    return db.enablePortraitCombatTint ~= false
end

function FluxUnitFrames_RefreshPortraitCombatTint()
    local UF = ns.UnitFrames
    if not UF or not UF.UpdatePortraitCombatTint then
        return
    end
    local frames = { ns.PlayerFrame, ns.TargetFrame, ns.FocusFrame, ns.PetFrame }
    for i = 1, #frames do
        local fr = frames[i]
        if fr then
            UF.UpdatePortraitCombatTint(fr)
        end
    end
end

--- Target frame: subtle gray placeholder outline when nothing is targeted (Target tab).
function FluxUnitFrames_ShouldShowTargetNoTargetPlaceholder()
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if not db then
        return true
    end
    return db.showTargetNoTargetPlaceholder ~= false
end

function FluxUnitFrames_RefreshTargetPlaceholderFromDB()
    local fr = ns.TargetFrame
    if fr and fr.UpdateFluxTargetPlaceholderVisibility then
        fr:UpdateFluxTargetPlaceholderVisibility()
    end
end

--- Horizontal offset so the combined [portrait + bar] block stays visually centered on screen (0 when portrait off).
--- Layout tab (GetLayoutDB): 1 = target top / player bottom stack; 2 = target right of player (same bottom lift).
function FluxUnitFrames_GetPlayerTargetPlacement()
    if FluxOptions and FluxOptions.GetPlayerTargetPlacement then
        return FluxOptions:GetPlayerTargetPlacement()
    end
    return 1
end

--- Full gap between player and target inner edges when side-by-side; each half offsets from screen bottom center so the seam is centered.
local FLUX_PLAYER_TARGET_SIDE_BY_SIDE_GAP = 6

function FluxUnitFrames_GetScreenAnchorCenterOffsetX(unit, portraitPosition, frameWidth, frameHeight)
    if not FluxUnitFrames_ShouldShowPortrait(unit) then
        return 0
    end
    local ph = tonumber(frameHeight) or 0
    if ph <= 0 then
        return 0
    end
    local portraitOffset = 2
    return (ph + portraitOffset) / 2
end

local function FluxUnitFrames_NotifyThirdPartyUnitFrameLayout()
    local bd = _G.BigDebuffs
    if bd then
        if bd.Refresh then
            pcall(bd.Refresh, bd)
        end
        if bd.RefreshFrames then
            pcall(bd.RefreshFrames, bd)
        end
    end
end

local function FluxUnitFrames_EnsurePortraitCreated(fr, unit)
    local UF = ns.UnitFrames
    if not fr or not UF or not UF.CreatePortrait or fr.PortraitFrame then
        return
    end
    if not FluxUnitFrames_ShouldShowPortrait(unit) then
        return
    end
    UF.CreatePortrait(fr)
    if UF.CreatePortraitCombatFeedback then
        UF.CreatePortraitCombatFeedback(fr)
    end
    local API = ns.API
    if API and API.NeedsPortraitCompat and API.NeedsPortraitCompat()
        and API.SetupPortraitModel and fr.Portrait and FluxUnitFrames_ShouldUse3DPortrait() then
        API.SetupPortraitModel(fr.Portrait, unit)
    end
    if UF.CreateThreatBar and (unit == "target" or unit == "focus") and not fr.ThreatBar then
        UF.CreateThreatBar(fr)
    end
end

--- Player frame bottom offset from UIParent bottom.
--- Default layout (status pos 3) lifts the action strip off the bottom; sit on that stack.
--- Status pos 2: sit on the status strip. Always prefer live FluxActionStrip over a stale 96px fallback.
function _G.FluxUnitFrames_GetPlayerScreenBottomOffset()
    local y = 96
    local function RaiseFromFrame(frame)
        if not frame or not frame.GetTop or not UIParent or not UIParent.GetBottom then
            return
        end
        if frame.IsShown and not frame:IsShown() then
            return
        end
        local t, b = frame:GetTop(), UIParent:GetBottom()
        if type(t) == "number" and type(b) == "number" and t == t and b == b then
            local v = t - b
            if v > y then
                y = v
            end
        end
    end
    RaiseFromFrame(_G.FluxActionStrip or _G.FluxMainActionBar)
    RaiseFromFrame(_G.FluxUnifiedBorderFrame)
    local loc2 = _G.FluxStatusBar_GetLocation2MinBottomOffset and _G.FluxStatusBar_GetLocation2MinBottomOffset()
    if type(loc2) == "number" and loc2 == loc2 and loc2 > y then
        y = loc2
    end
    local Cap = ns.Flux and ns.Flux.Cap
    local floor = Cap and Cap.GetGamepadActionBarFloor and Cap.GetGamepadActionBarFloor()
    if type(floor) == "number" and floor == floor and floor > y then
        y = floor
    end
    return y
end

function _G.FluxUnitFrames_ApplyPlayerStatusBarLayout()
    if InCombatLockdown() then
        return
    end
    if ns.PlayerFrame and FluxUnitFrames_ReanchorUnitFrameScreenPosition then
        FluxUnitFrames_ReanchorUnitFrameScreenPosition(ns.PlayerFrame, "player")
    end
    if ns.TargetFrame and FluxUnitFrames_ShouldUseFlux("target") and FluxUnitFrames_ReanchorUnitFrameScreenPosition then
        FluxUnitFrames_ReanchorUnitFrameScreenPosition(ns.TargetFrame, "target")
    end
end

--- Side-by-side layout: match target chrome to player — name/cast/auras at top (outerBorderAlignment BOTTOM). Classic target uses TOP.
function FluxUnitFrames_SyncTargetChromeForPlacement()
    local fr = ns.TargetFrame
    if not fr or not FluxUnitFrames_ShouldUseFlux("target") then
        return
    end
    local matchPlayerChrome = FluxUnitFrames_GetPlayerTargetPlacement() == 2
        and FluxUnitFrames_ShouldUseFlux("player")
        and FluxUnitFrames_ShouldUseFlux("target")
    fr.outerBorderAlignment = matchPlayerChrome and "BOTTOM" or "TOP"
    -- Side-by-side: vertical threat must not sit on the inward (left) edge.
    if matchPlayerChrome then
        local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
        if db and db.threatBarPositionTarget == "left" then
            db.threatBarPositionTarget = "right"
        end
    end
    local UF = ns.UnitFrames
    if fr.UpdateOuterBorder then
        pcall(fr.UpdateOuterBorder, fr)
    end
    if fr.CastBar and fr.CastBar.UpdateLayout then
        pcall(fr.CastBar.UpdateLayout, fr.CastBar)
    end
    if UF and UF.LayoutThreatBar then
        pcall(UF.LayoutThreatBar, fr)
    elseif UF and UF.LayoutThreatBarForPortraitState then
        pcall(UF.LayoutThreatBarForPortraitState, fr)
    end
    if UF and UF.UpdateFrameVisualElements then
        pcall(UF.UpdateFrameVisualElements, fr)
    end
    FluxUnitFrames_RefreshTargetOfTargetAnchor()
end

--- Re-anchor Target of Target after target size/screen position changes (placement 1 vs 2 use different parents/points).
function FluxUnitFrames_RefreshTargetOfTargetAnchor()
    local tot = ns.TargetOfTargetFrame
    if not tot or InCombatLockdown() then
        return
    end
    local fn = tot._fluxRefreshTotAnchor
    if fn then
        pcall(fn)
    end
end

--- Reposition player/target on screen when portrait toggles (bar-only = centered; with portrait = offset).
function FluxUnitFrames_ReanchorUnitFrameScreenPosition(fr, unit)
    if not fr or InCombatLockdown() then
        return
    end
    unit = unit or fr.unit
    if unit == "focus" then
        if FluxUIPositionFocusFrameDefault then
            FluxUIPositionFocusFrameDefault()
        end
        return
    end
    local pw = fr:GetWidth() or 100
    local ph = fr:GetHeight() or 50
    local pos = fr.portraitPosition or "LEFT"
    local cx = FluxUnitFrames_GetScreenAnchorCenterOffsetX(unit, pos, pw, ph)
    local py = _G.FluxUnitFrames_GetPlayerScreenBottomOffset and _G.FluxUnitFrames_GetPlayerScreenBottomOffset() or 96
    local sideBySide = FluxUnitFrames_GetPlayerTargetPlacement() == 2
        and FluxUnitFrames_ShouldUseFlux("player")
        and FluxUnitFrames_ShouldUseFlux("target")

    if sideBySide and (unit == "player" or unit == "target") then
        --- Seam between frames at horizontal screen center: BOTTOMRIGHT(player) and BOTTOMLEFT(target) to UIParent BOTTOM with +/- half gap.
        local halfGap = FLUX_PLAYER_TARGET_SIDE_BY_SIDE_GAP / 2
        fr:ClearAllPoints()
        if unit == "player" then
            fr:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -halfGap, py)
        else
            fr:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", halfGap, py)
        end
    elseif unit == "player" then
        fr:ClearAllPoints()
        if pos == "LEFT" then
            fr:SetPoint("BOTTOM", UIParent, "BOTTOM", cx, py)
        else
            fr:SetPoint("BOTTOM", UIParent, "BOTTOM", -cx, py)
        end
    elseif unit == "target" then
        fr:ClearAllPoints()
        if pos == "LEFT" then
            fr:SetPoint("TOP", UIParent, "TOP", cx, 2)
        else
            fr:SetPoint("TOP", UIParent, "TOP", -cx, 2)
        end
    end

    --- One sync per layout pass (runs when target screen position is applied; updates cast/aura/name chrome for side-by-side vs classic).
    if unit == "target" and ns.TargetFrame and FluxUnitFrames_ShouldUseFlux("target") then
        FluxUnitFrames_SyncTargetChromeForPlacement()
    end
end

function FluxUnitFrames_ApplyThreatBarOptionsFromDB()
    if InCombatLockdown() then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, FluxUnitFrames_ApplyThreatBarOptionsFromDB)
        end
        return
    end
    local UF = ns.UnitFrames
    if not UF or not UF.CreateThreatBar then
        return
    end

    local function proc(fr, unit)
        if not fr or not FluxUnitFrames_ShouldUseFlux(unit) then
            return
        end
        -- Side-by-side target: migrate saved "left" to "right" so options stay consistent.
        if unit == "target" then
            local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
            if db and db.threatBarPositionTarget == "left"
                and FluxUnitFrames_GetPlayerTargetPlacement
                and FluxUnitFrames_GetPlayerTargetPlacement() == 2 then
                db.threatBarPositionTarget = "right"
            end
        end
        if not fr.ThreatBar then
            UF.CreateThreatBar(fr)
        end
        if UF.LayoutThreatBar then
            pcall(UF.LayoutThreatBar, fr)
        elseif UF.LayoutThreatBarForPortraitState then
            pcall(UF.LayoutThreatBarForPortraitState, fr)
        end
        if UF.UpdateAuraPosition then
            pcall(UF.UpdateAuraPosition, fr)
        end
    end

    if ns.TargetFrame then
        proc(ns.TargetFrame, "target")
    end
    if ns.FocusFrame and FLUX_API and FLUX_API.hasFocusUnit then
        proc(ns.FocusFrame, "focus")
    end
end

function FluxUnitFrames_ApplyPortraitOptionsFromDB()
    if InCombatLockdown() then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, FluxUnitFrames_ApplyPortraitOptionsFromDB)
        end
        return
    end
    local UF = ns.UnitFrames

    local function proc(fr, unit)
        if not fr or not UF then
            return
        end
        FluxUnitFrames_EnsurePortraitCreated(fr, unit)
        local want = FluxUnitFrames_ShouldShowPortrait(unit)
        if fr.PortraitFrame then
            fr._fluxPortraitDisabled = not want
            if want then
                fr.PortraitFrame:Show()
                if UF.UpdatePortrait then
                    pcall(UF.UpdatePortrait, fr, unit)
                end
            else
                fr.PortraitFrame:Hide()
                if fr.Portrait then
                    fr.Portrait:Hide()
                end
                if fr.Portrait2D then
                    fr.Portrait2D:Hide()
                end
            end
        end
        if unit == "player" or unit == "target" or unit == "focus" then
            FluxUnitFrames_ReanchorUnitFrameScreenPosition(fr, unit)
        end
        if fr.UpdatePartition then
            pcall(fr.UpdatePartition, fr)
        end
        if fr.UpdateOuterBorder then
            pcall(fr.UpdateOuterBorder, fr)
        end
        if unit == "pet" and fr._fluxRefreshAnchor then
            fr._fluxRefreshAnchor()
        end
        if UF.UpdateAuraPosition and (unit == "target" or unit == "focus") then
            pcall(UF.UpdateAuraPosition, fr)
        end
        if unit == "player" and ns.ClassPower and ns.ClassPower.UpdatePosition and ns.PlayerFrame then
            pcall(ns.ClassPower.UpdatePosition, ns.PlayerFrame)
        end
    end

    if ns.PlayerFrame and FluxUnitFrames_ShouldUseFlux("player") then
        proc(ns.PlayerFrame, "player")
    end
    if ns.TargetFrame and FluxUnitFrames_ShouldUseFlux("target") then
        proc(ns.TargetFrame, "target")
    end
    if ns.FocusFrame and FluxUnitFrames_ShouldUseFlux("focus") and FLUX_API and FLUX_API.hasFocusUnit then
        proc(ns.FocusFrame, "focus")
    end
    if ns.PetFrame and FluxUnitFrames_ShouldUseFlux("pet") then
        proc(ns.PetFrame, "pet")
    end
    if FluxUnitFrames_MatchFocusTargetToFocus then
        FluxUnitFrames_MatchFocusTargetToFocus()
    end
    FluxUnitFrames_NotifyThirdPartyUnitFrameLayout()
end

function FluxUnitFrames_RefreshPortraitRenderModeFromDB()
    if InCombatLockdown() then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, FluxUnitFrames_RefreshPortraitRenderModeFromDB)
        end
        return
    end
    local UF = ns.UnitFrames
    if not UF or not UF.UpdatePortrait then
        return
    end
    local list = {
        { ns.PlayerFrame, "player" },
        { ns.TargetFrame, "target" },
        { ns.FocusFrame, "focus" },
        { ns.PetFrame, "pet" },
    }
    for i = 1, #list do
        local fr, u = list[i][1], list[i][2]
        if fr and fr.PortraitFrame and fr.Portrait and FluxUnitFrames_ShouldUseFlux(u) and FluxUnitFrames_ShouldShowPortrait(u) then
            pcall(UF.UpdatePortrait, fr, u)
        end
    end
end

--- Re-apply overlay/cast bar/swing settings to already-created Flux frames (live; no reload).
-- Target/focus aura panels (FluxUnitFrames_Auras EnableAuras); sizes and caps from Unit frames options.
local DEFAULT_AURA_TARGET = {
    buffSize = 35,
    debuffSize = 35,
    buffSpacing = 2,
    debuffSpacing = 2,
    maxBuffs = 32,
    maxDebuffs = 16,
    minAuraPx = 10,
    lockOwnDebuffSize = true,
    ownDebuffMinScale = 0.75,
}
local DEFAULT_AURA_FOCUS = {
    buffSize = 20,
    debuffSize = 20,
    buffSpacing = 2,
    debuffSpacing = 2,
    maxBuffs = 32,
    maxDebuffs = 16,
    minAuraPx = 10,
    lockOwnDebuffSize = true,
    ownDebuffMinScale = 0.75,
}

--- @return table buffConfig, table debuffConfig for UF.EnableAuras / UF.ApplyAuraOptionsToFrame
function FluxUnitFrames_GetAuraConfigTables(unit)
    local DEFAULT_BUFFS_PER_ROW = 8
    local DEFAULT_DEBUFFS_PER_ROW = 6
    local base = unit == "focus" and DEFAULT_AURA_FOCUS or DEFAULT_AURA_TARGET
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    local key = unit == "focus" and "auraFocus" or "auraTarget"
    local t = (db and db[key]) or {}
    local buffSize = tonumber(t.buffSize) or base.buffSize
    local debuffSize = tonumber(t.debuffSize) or base.debuffSize
    local buffSpacing = tonumber(t.buffSpacing) or base.buffSpacing
    local debuffSpacing = tonumber(t.debuffSpacing) or base.debuffSpacing
    local maxBuffs = tonumber(t.maxBuffs) or base.maxBuffs
    local maxDebuffs = tonumber(t.maxDebuffs) or base.maxDebuffs
    local minAuraPx = tonumber(t.minAuraPx) or base.minAuraPx or 10
    local lockOwnDebuffSize = t.lockOwnDebuffSize
    if lockOwnDebuffSize == nil then
        lockOwnDebuffSize = base.lockOwnDebuffSize
    end
    local ownDebuffMinScale = tonumber(t.ownDebuffMinScale) or base.ownDebuffMinScale or 0.75
    maxBuffs = math.max(4, math.min(40, math.floor(maxBuffs)))
    maxDebuffs = math.max(4, math.min(24, math.floor(maxDebuffs)))
    minAuraPx = math.max(6, math.min(32, math.floor(minAuraPx)))
    if ownDebuffMinScale > 1 then
        ownDebuffMinScale = 1
    elseif ownDebuffMinScale < 0.5 then
        ownDebuffMinScale = 0.5
    end
    local auraScale = FluxUnitFrames_GetPlayerTargetPlacement2RelativeUIScale()
    if auraScale ~= 1 then
        buffSize = math.max(8, math.floor(buffSize * auraScale + 0.5))
        debuffSize = math.max(8, math.floor(debuffSize * auraScale + 0.5))
        buffSpacing = math.max(1, math.floor(buffSpacing * auraScale + 0.5))
        debuffSpacing = math.max(1, math.floor(debuffSpacing * auraScale + 0.5))
        minAuraPx = math.max(6, math.floor(minAuraPx * auraScale + 0.5))
    end
    --- Side-by-side player/target (placement 2): match debuff row to buff icon size/spacing on target.
    if unit == "target"
        and FluxOptions and FluxOptions.GetPlayerTargetPlacement
        and FluxOptions:GetPlayerTargetPlacement() == 2
    then
        debuffSize = buffSize
        debuffSpacing = buffSpacing
    end
    return {
        size = buffSize,
        max = maxBuffs,
        perRow = DEFAULT_BUFFS_PER_ROW,
        spacing = buffSpacing,
        minAuraPx = minAuraPx,
    }, {
        size = debuffSize,
        max = maxDebuffs,
        perRow = DEFAULT_DEBUFFS_PER_ROW,
        spacing = debuffSpacing,
        minAuraPx = minAuraPx,
        lockOwnDebuffSize = lockOwnDebuffSize and true or false,
        ownDebuffMinScale = ownDebuffMinScale,
    }
end

function FluxUnitFrames_ApplyAuraLayoutFromDB()
    if InCombatLockdown() then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, FluxUnitFrames_ApplyAuraLayoutFromDB)
        end
        return
    end
    local UF = ns.UnitFrames
    if not UF or not UF.ApplyAuraOptionsToFrame then
        return
    end
    local function AuraShown(unit, flag)
        local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
        local key = unit == "focus" and "auraFocus" or "auraTarget"
        local t = db and db[key]
        if not t or t[flag] == nil then
            return true
        end
        return t[flag] and true or false
    end
    if ns.TargetFrame and FluxUnitFrames_ShouldUseFlux("target") then
        local b, d = FluxUnitFrames_GetAuraConfigTables("target")
        UF.ApplyAuraOptionsToFrame(ns.TargetFrame, AuraShown("target", "showBuffs"), AuraShown("target", "showDebuffs"), b, d)
    end
    if ns.FocusFrame and FluxUnitFrames_ShouldUseFlux("focus") and FLUX_API and FLUX_API.hasFocusUnit then
        local b, d = FluxUnitFrames_GetAuraConfigTables("focus")
        UF.ApplyAuraOptionsToFrame(ns.FocusFrame, AuraShown("focus", "showBuffs"), AuraShown("focus", "showDebuffs"), b, d)
    end
end

function FluxUnitFrames_ApplyOptionsFromDB()
    local HLO = ns.HealthLossOverlay
    local PCO = ns.PowerCostOverlay
    local MP5 = ns.MP5Overlay
    local CB = ns.CastBar
    local ST = ns.SwingTimer

    local units = {
        { ns.PlayerFrame, "player" },
        { ns.TargetFrame, "target" },
        { ns.TargetOfTargetFrame, "targettarget" },
        { ns.PetFrame, "pet" },
        { ns.FocusFrame, "focus" },
        { ns.FocusTargetFrame, "focustarget" },
    }

    for i = 1, #units do
        local fr = units[i][1]
        local unit = units[i][2]
        if fr then
            if HLO and HLO.Initialize then
                HLO.Initialize(fr)
            end
            if PCO and PCO.Initialize and fr.Power then
                PCO.Initialize(fr)
            end
            if CB and CB.CreateCastBar and (unit == "player" or unit == "target" or unit == "focus" or unit == "pet") then
                local showCast = FluxUnitFrames_ShouldShowCastBar and FluxUnitFrames_ShouldShowCastBar(unit)
                if showCast then
                    if not fr.CastBar then
                        CB.CreateCastBar(fr, unit)
                    elseif fr.CastBar.RegisterPetCastEvents then
                        fr.CastBar:RegisterPetCastEvents()
                    end
                    if fr.CastBar then
                        fr.CastBar._fluxPetCastDisabled = nil
                    end
                elseif fr.CastBar then
                    if fr.CastBar.DisablePetCastBar then
                        fr.CastBar:DisablePetCastBar()
                    else
                        fr.CastBar:Hide()
                        fr.CastBar:UnregisterAllEvents()
                        fr.CastBar._fluxPetCastDisabled = true
                    end
                end
            end
        end
    end

    if ns.PlayerFrame then
        if MP5 and MP5.Initialize then
            MP5.Initialize(ns.PlayerFrame)
        end
        if ST and ST.SetPlayerSwingTimerEnabled then
            ST.SetPlayerSwingTimerEnabled(FluxUnitFrames_IsFeatureEnabled("swingTimer"))
        end
    end

    FluxUnitFrames_ApplyFrameSizesFromDB()
    FluxUnitFrames_ApplyAuraLayoutFromDB()
    FluxUnitFrames_ApplyPortraitOptionsFromDB()
    FluxUnitFrames_RefreshPortraitCombatTint()
    if FluxUnitFrames_ApplyThreatBarOptionsFromDB then
        FluxUnitFrames_ApplyThreatBarOptionsFromDB()
    end
    FluxUnitFrames_RefreshTargetPlaceholderFromDB()

    local UF = ns.UnitFrames
    local refreshFrames = {
        ns.PlayerFrame,
        ns.TargetFrame,
        ns.TargetOfTargetFrame,
        ns.FocusFrame,
        ns.FocusTargetFrame,
        ns.PetFrame,
        ns.PetTargetFrame,
    }
    for i = 1, #refreshFrames do
        local fr = refreshFrames[i]
        if fr and UF then
            if UF.UpdateHealth then
                UF.UpdateHealth(fr, fr.unit)
            end
            if UF.UpdatePower then
                UF.UpdatePower(fr, fr.unit)
            end
            if UF.UpdateHealPrediction then
                UF.UpdateHealPrediction(fr)
            end
            if fr.UpdateOuterBorder then
                fr:UpdateOuterBorder()
            end
            if fr.mouseoverHighlight and FluxUnitFrames_ShouldShowMouseover and not FluxUnitFrames_ShouldShowMouseover(fr.unit) then
                fr.mouseoverHighlight:Hide()
            end
        end
    end
    if ns.ClassPower and ns.ClassPower.ApplyVisibility then
        ns.ClassPower.ApplyVisibility()
    end
end

-- ---------------------------------------------------------------------------
-- Frame dimensions & health/power split (Unit frames options tab)
-- ---------------------------------------------------------------------------

--- Built-in defaults per Layout → player/target placement (1 = classic, 2 = side-by-side).
local FLUX_FRAME_SIZES_BY_PLACEMENT = {
    [1] = {
        player = { 325, 100 },
        target = { 500, 100 },
        targettarget = { 125, 60 },
        focus = { 119, 50 },
        pet = { 100, 50 },
    },
    [2] = {
        player = { 340, 125 },
        target = { 340, 125 },
        targettarget = { 125, 64 },
        focus = { 119, 50 },
        pet = { 125, 64 },
    },
}

local FLUX_DEFAULT_PETTARGET_BAR_WIDTH = 23

--- Side-by-side (placement 2): on-screen widths/heights/spacings are this fraction of stored "design" values (30% smaller).
local FLUX_POS2_RELATIVE_UI_SCALE = 0.7

local function fluxUF_NormalizePlacement(placement)
    return placement == 2 and 2 or 1
end

--- Global multiplier for placement 2 (for other modules that need the same factor).
function FluxUnitFrames_GetPlayerTargetPlacement2RelativeUIScale()
    if fluxUF_NormalizePlacement(FluxUnitFrames_GetPlayerTargetPlacement()) == 2 then
        return FLUX_POS2_RELATIVE_UI_SCALE
    end
    return 1
end

--- Stored unit-frame dimension (options DB) → pixels applied to frames.
function FluxUnitFrames_UnitFrameStorageToEffectiveDimension(placement, value)
    if not value then
        return nil
    end
    if fluxUF_NormalizePlacement(placement) ~= 2 then
        return value
    end
    return math.max(1, math.floor(value * FLUX_POS2_RELATIVE_UI_SCALE + 0.5))
end

--- Slider / effective pixel value → stored design value for placement 2.
function FluxUnitFrames_UnitFrameEffectiveToStorageDimension(placement, value)
    if not value then
        return nil
    end
    if fluxUF_NormalizePlacement(placement) ~= 2 then
        return value
    end
    return math.max(1, math.floor(value / FLUX_POS2_RELATIVE_UI_SCALE + 0.5))
end

local function fluxUF_CopyLegacyFrameSizesToBucket(dest, leg, placementDefaults)
    leg = leg or {}
    local units = { "player", "target", "targettarget", "focus", "pet" }
    for i = 1, #units do
        local u = units[i]
        local def = placementDefaults[u]
        dest[u] = dest[u] or {}
        if leg[u] then
            if leg[u].width then
                dest[u].width = leg[u].width
            end
            if leg[u].height then
                dest[u].height = leg[u].height
            end
        end
        if def then
            dest[u].width = dest[u].width or def[1]
            dest[u].height = dest[u].height or def[2]
        end
    end
    dest.pettarget = dest.pettarget or {}
    local ptw = (leg.pettarget and leg.pettarget.width) or FLUX_DEFAULT_PETTARGET_BAR_WIDTH
    dest.pettarget.width = dest.pettarget.width or ptw
end

--- Migrate legacy `frameSizes` into `frameSizesByPlacement["1"]` / `["2"]` once; returns the bucket for `placement`.
function FluxUnitFrames_EnsureAndGetFrameSizesBucket(db, placement)
    if not db then
        return nil
    end
    placement = fluxUF_NormalizePlacement(placement)
    if not db.frameSizesByPlacement then
        local leg = db.frameSizes or {}
        db.frameSizesByPlacement = { ["1"] = {}, ["2"] = {} }
        fluxUF_CopyLegacyFrameSizesToBucket(db.frameSizesByPlacement["1"], leg, FLUX_FRAME_SIZES_BY_PLACEMENT[1])
        fluxUF_CopyLegacyFrameSizesToBucket(db.frameSizesByPlacement["2"], {}, FLUX_FRAME_SIZES_BY_PLACEMENT[2])
        if leg.focus then
            local f2 = db.frameSizesByPlacement["2"].focus
            f2.width = leg.focus.width or f2.width
            f2.height = leg.focus.height or f2.height
        end
        if leg.pettarget and leg.pettarget.width then
            db.frameSizesByPlacement["1"].pettarget.width = leg.pettarget.width
            db.frameSizesByPlacement["2"].pettarget.width = leg.pettarget.width
        end
    end
    local key = placement == 2 and "2" or "1"
    return db.frameSizesByPlacement[key]
end

--- X coordinate of the Flux target frame's left edge in UIParent space, as if player/target placement were 1
--- (TOP-centered stack). Uses placement bucket "1" width/height only — stable without a unit targeted and
--- independent of the current Layout "player/target placement" (1 vs 2). Returns nil when Flux target is off.
function FluxUnitFrames_GetPlacement1TargetLeftForMicroMenuCap()
    if not FluxUnitFrames_ShouldUseFlux or not FluxUnitFrames_ShouldUseFlux("target") then
        return nil
    end
    local up = UIParent
    if not up or not up.GetWidth then
        return nil
    end
    local parentW = up:GetWidth()
    if not parentW or parentW <= 0 then
        return nil
    end
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    local bucket = FluxUnitFrames_EnsureAndGetFrameSizesBucket(db, 1)
    local d1 = FLUX_FRAME_SIZES_BY_PLACEMENT[1] and FLUX_FRAME_SIZES_BY_PLACEMENT[1].target
    local fs = bucket and bucket.target
    local w = (fs and fs.width) or (d1 and d1[1])
    local h = (fs and fs.height) or (d1 and d1[2])
    if not w or not h or w <= 0 or h <= 0 then
        return nil
    end
    local portraitPos = "RIGHT"
    local tf = ns.TargetFrame
    if tf and tf.portraitPosition then
        portraitPos = tf.portraitPosition
    end
    local cx = FluxUnitFrames_GetScreenAnchorCenterOffsetX("target", portraitPos, w, h)
    local centerX = parentW * 0.5
    local offsetX = (portraitPos == "LEFT") and cx or -cx
    return centerX + offsetX - w * 0.5
end

_G.FluxUnitFrames_GetPlacement1TargetLeftForMicroMenuCap = FluxUnitFrames_GetPlacement1TargetLeftForMicroMenuCap

--- "width" | "height" for a unit key; pettarget uses width only (bar strip).
function FluxUnitFrames_GetUnitFrameDefaultDimension(unit, dim)
    local placement = 1
    if FluxOptions and FluxOptions.GetPlayerTargetPlacement then
        placement = fluxUF_NormalizePlacement(FluxOptions:GetPlayerTargetPlacement())
    end
    if unit == "pettarget" then
        if dim ~= "width" then
            return nil
        end
        return FluxUnitFrames_UnitFrameStorageToEffectiveDimension(placement, FLUX_DEFAULT_PETTARGET_BAR_WIDTH)
    end
    local def = FLUX_FRAME_SIZES_BY_PLACEMENT[placement] and FLUX_FRAME_SIZES_BY_PLACEMENT[placement][unit]
    if not def then
        return nil
    end
    if dim == "width" then
        return FluxUnitFrames_UnitFrameStorageToEffectiveDimension(placement, def[1])
    end
    if dim == "height" then
        return FluxUnitFrames_UnitFrameStorageToEffectiveDimension(placement, def[2])
    end
    return nil
end

function FluxUnitFrames_GetConfiguredFrameSize(unit)
    local placement = fluxUF_NormalizePlacement(FluxUnitFrames_GetPlayerTargetPlacement())
    local defs = FLUX_FRAME_SIZES_BY_PLACEMENT[placement]
    local d = defs and defs[unit]
    if not d and unit ~= "pettarget" then
        return nil, nil
    end
    -- Placement 2: focus uses placement-1 bucket defaults (full config size, not 0.7 UI scale).
    if unit == "focus" and placement == 2 then
        local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
        local bucket1 = db and FluxUnitFrames_EnsureAndGetFrameSizesBucket(db, 1)
        local fs = bucket1 and bucket1.focus
        local d1 = FLUX_FRAME_SIZES_BY_PLACEMENT[1] and FLUX_FRAME_SIZES_BY_PLACEMENT[1].focus
        local w = (fs and fs.width) or (d1 and d1[1])
        local h = (fs and fs.height) or (d1 and d1[2])
        if w and h then
            return w, h
        end
    end
    if unit == "target" and placement == 2 then
        local pw, ph = FluxUnitFrames_GetConfiguredFrameSize("player")
        if pw and ph then
            return pw, ph
        end
    end
    if unit == "targettarget"
        and placement == 2
        and FluxUnitFrames_ShouldUseFlux("player")
        and FluxUnitFrames_ShouldUseFlux("target")
        and FluxUnitFrames_ShouldUseFlux("targettarget")
    then
        local pw, ph = FluxUnitFrames_GetConfiguredFrameSize("pet")
        if pw and ph then
            return pw, ph
        end
    end
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    local bucket = db and FluxUnitFrames_EnsureAndGetFrameSizesBucket(db, placement)
    local fs = bucket and bucket[unit]
    local w = (fs and fs.width) or (d and d[1])
    local h = (fs and fs.height) or (d and d[2])
    if placement == 2 and w and h then
        w = FluxUnitFrames_UnitFrameStorageToEffectiveDimension(2, w)
        h = FluxUnitFrames_UnitFrameStorageToEffectiveDimension(2, h)
    end
    return w, h
end

function FluxUnitFrames_GetConfiguredPetTargetBarWidth()
    local placement = fluxUF_NormalizePlacement(FluxUnitFrames_GetPlayerTargetPlacement())
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    local bucket = db and FluxUnitFrames_EnsureAndGetFrameSizesBucket(db, placement)
    local fs = bucket and bucket.pettarget
    local w = (fs and fs.width) or FLUX_DEFAULT_PETTARGET_BAR_WIDTH
    if placement == 2 and w then
        w = FluxUnitFrames_UnitFrameStorageToEffectiveDimension(2, w)
    end
    return w
end

--- After Layout tab player/target placement change: reapply sizes, auras, portraits, partitions, anchors.
function FluxUnitFrames_FullUnitFrameLayoutRefresh()
    if InCombatLockdown() then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, FluxUnitFrames_FullUnitFrameLayoutRefresh)
        end
        return
    end
    if FluxUnitFrames_ApplyFrameSizesFromDB then
        FluxUnitFrames_ApplyFrameSizesFromDB()
    end
    if FluxUnitFrames_ApplyAuraLayoutFromDB then
        FluxUnitFrames_ApplyAuraLayoutFromDB()
    end
    if FluxUnitFrames_ApplyPortraitOptionsFromDB then
        FluxUnitFrames_ApplyPortraitOptionsFromDB()
    end
    if FluxUnitFrames_RefreshBarPartitionsFromDB then
        FluxUnitFrames_RefreshBarPartitionsFromDB()
    end
    if FluxUnitFrames_RefreshTargetPlaceholderFromDB then
        FluxUnitFrames_RefreshTargetPlaceholderFromDB()
    end
    if FluxUnitFrames_RefreshTargetAndTotTogether then
        pcall(FluxUnitFrames_RefreshTargetAndTotTogether)
    end
    local mm = _G.FluxMicroMenu
    if mm and mm.RefreshLayout then
        pcall(mm.RefreshLayout, mm)
    end
end

_G.FluxUnitFrames_FullUnitFrameLayoutRefresh = FluxUnitFrames_FullUnitFrameLayoutRefresh
_G.FluxUnitFrames_GetPlayerTargetPlacement2RelativeUIScale = FluxUnitFrames_GetPlayerTargetPlacement2RelativeUIScale

local DEFAULT_HEALTH_PARTITION = 0.60

--- @param unit string player|target|targettarget|focus|pet (and any frame with a standard HP/power column)
function FluxUnitFrames_GetHealthPartitionPct(unit)
    unit = unit or "player"
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    local p
    if db and db.healthPartitions and db.healthPartitions[unit] ~= nil then
        p = db.healthPartitions[unit]
    elseif db and db.healthPartition ~= nil then
        p = db.healthPartition
    else
        p = DEFAULT_HEALTH_PARTITION
    end
    p = tonumber(p) or DEFAULT_HEALTH_PARTITION
    --- Placement 2 ToT only: use the maximum allowed health share (same cap as global clamp: 85%).
    if unit == "targettarget"
        and FluxUnitFrames_GetPlayerTargetPlacement() == 2
        and FluxUnitFrames_ShouldUseFlux("player")
        and FluxUnitFrames_ShouldUseFlux("target")
        and FluxUnitFrames_ShouldUseFlux("targettarget")
    then
        p = 0.75
    end
    if p < 0.35 then
        p = 0.35
    elseif p > 0.85 then
        p = 0.85
    end
    return p
end

--- Re-run bar height split only (after health % changes; no full size apply).
function FluxUnitFrames_RefreshBarPartitionsFromDB()
    local list = {
        ns.PlayerFrame,
        ns.TargetFrame,
        ns.TargetOfTargetFrame,
        ns.PetFrame,
        ns.FocusFrame,
    }
    for i = 1, #list do
        local fr = list[i]
        if fr and fr.UpdatePartition then
            pcall(function()
                fr:UpdatePartition()
            end)
        end
    end
    if FluxUnitFrames_MatchFocusTargetToFocus then
        FluxUnitFrames_MatchFocusTargetToFocus()
    end
end

function FluxUnitFrames_ApplyFrameSizesFromDB()
    if InCombatLockdown() then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, FluxUnitFrames_ApplyFrameSizesFromDB)
        end
        return
    end

    local UFm = ns.UnitFrames

    local function refreshCastBar(fr)
        if fr and fr.CastBar and fr.CastBar.UpdateLayout then
            pcall(function()
                fr.CastBar:UpdateLayout()
            end)
        end
    end

    local function afterSize(fr)
        if not fr then
            return
        end
        if fr.UpdatePartition then
            fr:UpdatePartition()
        end
        if fr.UpdateAtlasBorder then
            fr:UpdateAtlasBorder()
        end
        if fr.UpdateOuterBorder then
            fr:UpdateOuterBorder()
        end
        refreshCastBar(fr)
    end

    local function applyWH(fr, unit)
        local w, h = FluxUnitFrames_GetConfiguredFrameSize(unit)
        if not fr or not w or not h then
            return
        end
        fr._fluxLayoutBaseWidth = w
        fr:SetHeight(h)
        if UFm and UFm.ApplyEmulatedHorizontalSqueezeForFrame then
            UFm.ApplyEmulatedHorizontalSqueezeForFrame(fr)
        else
            fr:SetWidth(w)
        end
        afterSize(fr)
        if unit == "player" and ns.ClassPower and ns.ClassPower.UpdatePosition and ns.PlayerFrame then
            pcall(ns.ClassPower.UpdatePosition, ns.PlayerFrame)
        end
    end

    if ns.PlayerFrame and FluxUnitFrames_ShouldUseFlux("player") then
        applyWH(ns.PlayerFrame, "player")
    end
    if ns.TargetFrame and FluxUnitFrames_ShouldUseFlux("target") then
        applyWH(ns.TargetFrame, "target")
    end
    if ns.TargetOfTargetFrame and FluxUnitFrames_ShouldUseFlux("targettarget") then
        applyWH(ns.TargetOfTargetFrame, "targettarget")
    end
    if ns.FocusFrame and FluxUnitFrames_ShouldUseFlux("focus") then
        applyWH(ns.FocusFrame, "focus")
    end
    if ns.PetFrame and FluxUnitFrames_ShouldUseFlux("pet") then
        applyWH(ns.PetFrame, "pet")
    end

    if ns.PetFrame and ns.PetFrame._fluxRefreshAnchor then
        ns.PetFrame._fluxRefreshAnchor()
    end

    if ns.PetTargetFrame and FluxUnitFrames_ShouldUseFlux("pettarget") then
        local pw = FluxUnitFrames_GetConfiguredPetTargetBarWidth()
        ns.PetTargetFrame._fluxLayoutBaseWidth = pw
        ns.PetTargetFrame:SetWidth(pw)
        if UFm and UFm.ApplyEmulatedHorizontalSqueezeForFrame then
            UFm.ApplyEmulatedHorizontalSqueezeForFrame(ns.PetTargetFrame)
        end
        if ns.PetTargetFrame._fluxRefreshLayout then
            ns.PetTargetFrame._fluxRefreshLayout()
        end
    end

    if ns.FocusTargetFrame and FluxUnitFrames_ShouldUseFlux("focustarget") and FluxUnitFrames_MatchFocusTargetToFocus then
        FluxUnitFrames_MatchFocusTargetToFocus()
    end

    -- Portrait-on screen centering uses frame height; re-apply anchor after width/height sliders change.
    if FluxUnitFrames_ReanchorUnitFrameScreenPosition then
        if ns.PlayerFrame and FluxUnitFrames_ShouldUseFlux("player") then
            FluxUnitFrames_ReanchorUnitFrameScreenPosition(ns.PlayerFrame, "player")
        end
        if ns.TargetFrame and FluxUnitFrames_ShouldUseFlux("target") then
            FluxUnitFrames_ReanchorUnitFrameScreenPosition(ns.TargetFrame, "target")
        end
        if ns.FocusFrame and FluxUnitFrames_ShouldUseFlux("focus") and FLUX_API and FLUX_API.hasFocusUnit then
            FluxUnitFrames_ReanchorUnitFrameScreenPosition(ns.FocusFrame, "focus")
        end
    end

    -- Recompute emulated dependent X factor (resolution / min UI scale) and reapply baseWidth * mult on every squeezed frame.
    if FluxUILayoutSqueeze and FluxUILayoutSqueeze.InvalidateEmulatedDependentCache then
        FluxUILayoutSqueeze.InvalidateEmulatedDependentCache()
    end
    if UFm and UFm.UpdateAllEmulatedHorizontalSqueeze then
        UFm.UpdateAllEmulatedHorizontalSqueeze()
    end
end
