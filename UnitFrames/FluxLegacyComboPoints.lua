-- UnitFrames/FluxLegacyComboPoints.lua
-- Pre-Dragonflight / Classic: Blizzard ComboFrame + ComboPoint1..N on target, duplicate row above player.
-- Mirrors TPerl_Target approach (ComboFrame reparent, layout, ComboFrame_Update + shine animations).
local addonName, ns = ...

ns.LegacyComboPoints = {}

local FLUX_API = FLUX_API or {}

local FADE_IN = COMBOFRAME_FADE_IN or 0.3
local HIGHLIGHT_FADE_IN = COMBOFRAME_HIGHLIGHT_FADE_IN or 0.4

-- Player row: larger than default combo pips (FluxClassPower uses ~2.0 for power bars)
local PLAYER_COMBO_ROW_SCALE = 2.75

-- Vertical: BOTTOM of row to TOP of outer border — lower Y moves the row down (closer to the frame)
local PLAYER_COMBO_Y_OFFSET = 0

-- Target: scale combo pips on portrait. Anchor TOPLEFT→TOPLEFT (not TOP→TOP): centering on TOP
-- placed half the row over the HP bar when portrait is on the right; insets keep pips inside the portrait.
local TARGET_COMBO_SCALE = 1.4
local TARGET_COMBO_LEFT_INSET = 4
local TARGET_COMBO_TOP_INSET = -12

local playerComboHost
local playerComboPoints = {}
local lastPlayerComboCount = -1
local legacyEventFrame
local targetComboHooked

local function GetAnchor(parentFrame)
    if parentFrame and parentFrame.outerBorderFrame then
        return parentFrame.outerBorderFrame
    end
    return parentFrame
end

local function PlayerShouldShowComboUI()
    local _, c = UnitClass("player")
    if c == "ROGUE" then
        return true
    end
    if c == "DRUID" then
        if Enum and Enum.PowerType then
            return UnitPowerType("player") == Enum.PowerType.Energy
        end
    end
    return false
end

local function GetComboCount()
    local vehicleUnit = (UnitHasVehicleUI and UnitHasVehicleUI("player")) and "vehicle" or "player"
    if GetComboPoints then
        return GetComboPoints(vehicleUnit, "target") or 0
    end
    if Enum and Enum.PowerType and UnitPower then
        return UnitPower(vehicleUnit, Enum.PowerType.ComboPoints) or 0
    end
    return 0
end

local function GetComboMax()
    if UnitPowerMax and Enum and Enum.PowerType then
        local m = UnitPowerMax("player", Enum.PowerType.ComboPoints)
        if m and m > 0 then
            return m
        end
    end
    return 5
end

local function EnsurePlayerFrameUnit()
    local pf = _G.PlayerFrame
    if not pf then return end
    if UnitHasVehicleUI and UnitHasVehicleUI("player") then
        pf.unit = "vehicle"
    else
        pf.unit = "player"
    end
end

-- Layout ComboPoint1..5 inside ComboFrame (TPerl "top" arrangement for classic 5-pip row)
-- Anchored inside the portrait top so pips sit within the border, above the model
local function LayoutBlizzardComboFrameTop(portraitFrame)
    local cf = _G.ComboFrame
    if not cf or not portraitFrame then return end

    cf:ClearAllPoints()
    cf:SetPoint("TOPLEFT", portraitFrame, "TOPLEFT", TARGET_COMBO_LEFT_INSET, TARGET_COMBO_TOP_INSET)

    for i = 1, 9 do
        local cp = _G["ComboPoint" .. i]
        if cp and cp.ClearAllPoints then
            cp:ClearAllPoints()
            if i < 6 then
                cp:SetAlpha(1)
            elseif cp.SetAlpha then
                cp:SetAlpha(0.5)
            end
        end
    end

    local ComboPoint1 = _G.ComboPoint1
    local ComboPoint2 = _G.ComboPoint2
    local ComboPoint3 = _G.ComboPoint3
    local ComboPoint4 = _G.ComboPoint4
    local ComboPoint5 = _G.ComboPoint5
    if not (ComboPoint1 and ComboPoint2 and ComboPoint3 and ComboPoint4 and ComboPoint5) then return end

    ComboPoint1:SetPoint("TOPLEFT", cf, "TOPLEFT", 0, 0)
    ComboPoint2:SetPoint("LEFT", ComboPoint1, "RIGHT", 0, 1)
    ComboPoint3:SetPoint("LEFT", ComboPoint2, "RIGHT", 0, 1)
    ComboPoint4:SetPoint("LEFT", ComboPoint3, "RIGHT", 0, -1)
    ComboPoint5:SetPoint("LEFT", ComboPoint4, "RIGHT", 0, -1)

    if _G.ComboPoint6 and _G.ComboPoint2 then
        _G.ComboPoint6:SetPoint("TOPLEFT", _G.ComboPoint2, "BOTTOMLEFT", 0, 0)
    end
    if _G.ComboPoint7 and _G.ComboPoint3 then
        _G.ComboPoint7:SetPoint("TOPLEFT", _G.ComboPoint3, "BOTTOMLEFT", 0, 0)
    end
    if _G.ComboPoint8 and _G.ComboPoint4 then
        _G.ComboPoint8:SetPoint("TOPLEFT", _G.ComboPoint4, "BOTTOMLEFT", 0, 0)
    end
end

-- ComboFrame must be a child of PortraitFrame with level above PlayerModel (portrait+2 in shared).
-- Sibling-of-portrait on the unit frame loses to the 3D model's draw order; model is not a normal 2D sibling.
local function ApplyTargetComboFrameLayer(cf, parentFrame, portrait)
    if not cf or not parentFrame or not portrait then return end
    local model = parentFrame.Portrait
    local lvl
    if model and model.GetFrameLevel then
        lvl = model:GetFrameLevel() + 12
    else
        lvl = portrait:GetFrameLevel() + 10
    end
    cf:SetFrameStrata("DIALOG")
    cf:SetFrameLevel(lvl)
    cf:SetScale(TARGET_COMBO_SCALE)
end

-- Player mirror row: same template, local last-count for shine
local function UpdatePlayerComboRow()
    if not playerComboHost then return end
    if not PlayerShouldShowComboUI() then
        playerComboHost:Hide()
        lastPlayerComboCount = -1
        return
    end

    local numPts = #playerComboPoints
    if numPts == 0 then return end

    local maxPts = math.min(GetComboMax(), numPts)
    local comboPoints = GetComboCount()

    if comboPoints <= 0 then
        for i = 1, numPts do
            local cp = playerComboPoints[i]
            if cp then
                if cp.Highlight then cp.Highlight:SetAlpha(0) end
                if cp.Shine then cp.Shine:SetAlpha(0) end
                cp:Hide()
            end
        end
        playerComboHost:Hide()
        lastPlayerComboCount = comboPoints
        return
    end

    if not playerComboHost:IsShown() then
        playerComboHost:Show()
        if UIFrameFadeIn then
            UIFrameFadeIn(playerComboHost, FADE_IN)
        end
    end

    local prevLast = lastPlayerComboCount or 0
    for i = 1, maxPts do
        local cp = playerComboPoints[i]
        if not cp then break end
        if i <= comboPoints then
            cp:Show()
            if i > prevLast and cp.Highlight and cp.Shine and UIFrameFade and ComboPointShineFadeIn then
                local fadeInfo = {}
                fadeInfo.mode = "IN"
                fadeInfo.timeToFade = HIGHLIGHT_FADE_IN
                fadeInfo.finishedFunc = ComboPointShineFadeIn
                fadeInfo.finishedArg1 = cp.Shine
                UIFrameFade(cp.Highlight, fadeInfo)
            end
        else
            if cp.Highlight then cp.Highlight:SetAlpha(0) end
            if cp.Shine then cp.Shine:SetAlpha(0) end
            cp:Hide()
        end
    end

    lastPlayerComboCount = comboPoints
end

local function RefreshTargetComboFrame()
    local cf = _G.ComboFrame
    if not cf then return end
    EnsurePlayerFrameUnit()
    cf.unit = (UnitHasVehicleUI and UnitHasVehicleUI("player")) and "vehicle" or "player"
    if ComboFrame_UpdateMax then
        pcall(ComboFrame_UpdateMax, cf)
    end
    if ComboFrame_Update then
        pcall(ComboFrame_Update, cf)
    end
    local pf = cf.FluxLegacyTargetUnitFrame
    if pf and pf.PortraitFrame then
        LayoutBlizzardComboFrameTop(pf.PortraitFrame)
        ApplyTargetComboFrameLayer(cf, pf, pf.PortraitFrame)
    end
end

function ns.LegacyComboPoints.RefreshAll()
    if not ns.API or not ns.API.ShouldUseLegacyComboFrameUI or not ns.API.ShouldUseLegacyComboFrameUI() then
        return
    end
    if not PlayerShouldShowComboUI() then
        if playerComboHost then playerComboHost:Hide() end
        if _G.ComboFrame then _G.ComboFrame:Hide() end
        return
    end
    UpdatePlayerComboRow()
    RefreshTargetComboFrame()
end

local function RegisterLegacyComboEvents()
    if legacyEventFrame then return end
    legacyEventFrame = CreateFrame("Frame")

    local function onEvent(self, event, ...)
        if not ns.API.ShouldUseLegacyComboFrameUI() then return end
        if not PlayerShouldShowComboUI() then return end

        if event == "UNIT_POWER_FREQUENT" or event == "UNIT_POWER_UPDATE" then
            local unit, powerType = ...
            if unit and unit ~= "player" and unit ~= "vehicle" then return end
            if powerType and powerType ~= "COMBO_POINTS" then return end
        end

        ns.LegacyComboPoints.RefreshAll()
    end

    legacyEventFrame:SetScript("OnEvent", onEvent)

    legacyEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    legacyEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    legacyEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    legacyEventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
    legacyEventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")

    if legacyEventFrame.RegisterUnitEvent then
        legacyEventFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player", "vehicle")
        legacyEventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player", "vehicle")
        legacyEventFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player", "vehicle")
    else
        legacyEventFrame:RegisterEvent("UNIT_POWER_FREQUENT")
        legacyEventFrame:RegisterEvent("UNIT_POWER_UPDATE")
        legacyEventFrame:RegisterEvent("UNIT_MAXPOWER")
    end
end

-- Fallback when bounds are not ready yet (login / first frame)
local PLAYER_COMBO_HOST_FALLBACK_W = 260
local PLAYER_COMBO_HOST_FALLBACK_H = 48

-- After points are laid out from host TOPLEFT (0,0), set host size to content bounds so
-- BOTTOM-center-on-anchor keeps the row horizontally centered on the unit frame.
-- Measure with host at scale 1, then apply PLAYER_COMBO_ROW_SCALE after SetSize.
-- Returns true if screen bounds were valid; false if caller should use fallback size.
local function ApplyPlayerComboHostSizeFromPoints()
    if not playerComboHost then return false end
    local p1 = playerComboPoints[1]
    local p5 = playerComboPoints[math.min(5, #playerComboPoints)]
    if not p1 or not p5 then return false end

    local l1, r5 = p1:GetLeft(), p5:GetRight()
    if not l1 or not r5 or (r5 - l1) <= 0 then return false end

    local w = math.max(1, r5 - l1)
    local t1, b1 = p1:GetTop(), p1:GetBottom()
    local h = (t1 and b1) and math.max(1, t1 - b1) or math.max(1, p1:GetHeight() or 24)

    if playerComboPoints[6] and playerComboPoints[6]:IsShown() then
        local p6 = playerComboPoints[6]
        local b6 = p6:GetBottom()
        if t1 and b6 then
            h = math.max(h, t1 - b6)
        end
    end

    playerComboHost:SetSize(w, h)
    return true
end

local function HookComboFrameParent(targetRootFrame)
    local cf = _G.ComboFrame
    if not cf or targetComboHooked or not targetRootFrame then return end
    targetComboHooked = true

    local origSetParent = cf.SetParent
    if type(origSetParent) ~= "function" then
        return
    end
    local parenting
    cf.SetParent = function(self, parent)
        if parenting or parent == targetRootFrame then
            return origSetParent(self, parent)
        end
        parenting = true
        origSetParent(self, targetRootFrame)
        parenting = nil
    end
end

local function InitPlayerComboRow(parentFrame)
    if playerComboHost or not parentFrame then return end

    local anchor = GetAnchor(parentFrame)
    if not anchor then return end

    playerComboHost = CreateFrame("Frame", "FluxLegacyComboPlayerHost", parentFrame)
    playerComboHost:SetFrameStrata("DIALOG")
    playerComboHost:SetFrameLevel(parentFrame:GetFrameLevel() + 80)
    playerComboHost:ClearAllPoints()
    playerComboHost:SetPoint("BOTTOM", anchor, "TOP", 0, PLAYER_COMBO_Y_OFFSET)

    local maxCreate = math.max(5, math.min(9, GetComboMax()))
    for i = 1, maxCreate do
        local ok, pt = pcall(CreateFrame, "Frame", "FluxLegacyPlayerComboPoint" .. i, playerComboHost, "ComboPointTemplate")
        if ok and pt then
            playerComboPoints[i] = pt
        else
            break
        end
    end

    if #playerComboPoints == 0 then
        playerComboHost:Hide()
        return
    end

    -- Show all pips briefly so GetLeft/GetRight resolve for sizing (hidden pips have no bounds)
    for i = 1, #playerComboPoints do
        if playerComboPoints[i] then
            playerComboPoints[i]:Show()
        end
    end

    local p1 = playerComboPoints[1]
    if p1 then
        p1:SetPoint("TOPLEFT", playerComboHost, "TOPLEFT", 0, 0)
    end
    for i = 2, math.min(5, #playerComboPoints) do
        local prev = playerComboPoints[i - 1]
        local cur = playerComboPoints[i]
        if prev and cur then
            if i == 2 or i == 3 then
                cur:SetPoint("LEFT", prev, "RIGHT", 0, 1)
            else
                cur:SetPoint("LEFT", prev, "RIGHT", 0, -1)
            end
        end
    end
    if playerComboPoints[6] and playerComboPoints[2] then
        playerComboPoints[6]:SetPoint("TOPLEFT", playerComboPoints[2], "BOTTOMLEFT", 0, 0)
    end
    if playerComboPoints[7] and playerComboPoints[3] then
        playerComboPoints[7]:SetPoint("TOPLEFT", playerComboPoints[3], "BOTTOMLEFT", 0, 0)
    end
    if playerComboPoints[8] and playerComboPoints[4] then
        playerComboPoints[8]:SetPoint("TOPLEFT", playerComboPoints[4], "BOTTOMLEFT", 0, 0)
    end

    playerComboHost:SetScale(1)

    -- Defer one tick so layout / GetLeft() resolve; then apply size and RefreshAll.
    -- Do NOT Hide() here: that raced with Initialize's C_Timer.After(0, RefreshAll) and cleared the row.
    local function finishLayout()
        if not playerComboHost then return end
        if not ApplyPlayerComboHostSizeFromPoints() then
            playerComboHost:SetSize(PLAYER_COMBO_HOST_FALLBACK_W, PLAYER_COMBO_HOST_FALLBACK_H)
        end
        playerComboHost:SetScale(PLAYER_COMBO_ROW_SCALE)
        ns.LegacyComboPoints.RefreshAll()
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, finishLayout)
        C_Timer.After(0.1, finishLayout)
    else
        finishLayout()
    end
end

local function InitTargetComboFrame(parentFrame)
    local cf = _G.ComboFrame
    local portrait = parentFrame and parentFrame.PortraitFrame
    if not cf or not portrait then return end

    -- Child of PortraitFrame so layering competes with PlayerModel; level set above model in ApplyTargetComboFrameLayer
    HookComboFrameParent(portrait)

    cf:SetParent(portrait)
    ApplyTargetComboFrameLayer(cf, parentFrame, portrait)

    LayoutBlizzardComboFrameTop(portrait)

    EnsurePlayerFrameUnit()
    if cf then
        cf.unit = (UnitHasVehicleUI and UnitHasVehicleUI("player")) and "vehicle" or "player"
    end
    if ComboFrame_UpdateMax then
        pcall(ComboFrame_UpdateMax, cf)
    end

    cf.FluxLegacyTargetUnitFrame = parentFrame

    if not cf.FluxLegacyComboLayoutHook then
        cf.FluxLegacyComboLayoutHook = true
        cf:HookScript("OnShow", function()
            if parentFrame.PortraitFrame then
                LayoutBlizzardComboFrameTop(parentFrame.PortraitFrame)
                ApplyTargetComboFrameLayer(cf, parentFrame, parentFrame.PortraitFrame)
            end
        end)
    end
end

function ns.LegacyComboPoints.Initialize(parentFrame)
    if not parentFrame or not parentFrame.unit then return end
    -- Era and Anniversary still have PlayerFrameBottomManagedFramesContainer.
    -- That container is not the combo UI; ComboFrame is. Forever must not enter
    -- here: ComboFrame_Update compares secret GetComboPoints once the frame is tainted.
    if not ns.API.ShouldUseLegacyComboFrameUI() then return end

    local _, cls = UnitClass("player")
    if cls ~= "ROGUE" and cls ~= "DRUID" then return end

    RegisterLegacyComboEvents()

    if parentFrame.unit == "player" then
        InitPlayerComboRow(parentFrame)
    elseif parentFrame.unit == "target" then
        InitTargetComboFrame(parentFrame)
    else
        return
    end

    C_Timer.After(0.15, function()
        ns.LegacyComboPoints.RefreshAll()
    end)
    C_Timer.After(0.35, function()
        ns.LegacyComboPoints.RefreshAll()
    end)
end
