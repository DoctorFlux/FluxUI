-- UnitFrames/FluxClassPower.lua
local addonName, ns = ...
local UF = ns.UnitFrames

ns.ClassPower = {}

-- Universal scale for all power bars
local UNIVERSAL_POWER_BAR_SCALE = 2.0

-- Scale for arcane charges (smaller than universal scale)
local ARCANE_CHARGES_SCALE = 1.5

-- Totem frame positioning at top-left of player frame (0.75x prior 0.85 scale)
local TOTEM_FRAME_SCALE = 0.6375
local TOTEM_FRAME_X_OFFSET = 2
local TOTEM_FRAME_Y_OFFSET = 2

-- Universal positioning offset (pixels above outer border)
local UNIVERSAL_POWER_BAR_Y_OFFSET = 4

-- Live/Forever renamed PlayerFrameBottomManagedFramesContainer. Classic still uses the old global.
local CLASS_BAR_NAMES = {
    "PaladinPowerBarFrame",
    "MageArcaneChargesFrame",
    "RogueComboPointBarFrame",
    "DruidComboPointBarFrame",
    "ComboPointPlayerFrame",
    "MonkHarmonyBarFrame",
    "WarlockPowerFrame",
    "RuneFrame",
    "EssencePlayerFrame",
    "TotemFrame",
}

-- [[----------------------------------------------------------------------------
--     Class Power Module
--     Anchors Blizzard's own class resource bars above the Flux player frame.
--     Does not replace GetUnit, and does not hooksecurefunc SetPoint / SetScale.
--     Scale locks are instance wraps. Position is reapplied from this module's
--     event frame so Blizzard UpdatePower keeps its own execution.
-- ------------------------------------------------------------------------------]]

-- Never hooksecurefunc Frame C methods (SetScale / SetParent / SetPoint / Show).
-- Those can bind the shared widget method; nameplate RefreshList calls them
-- before Layout, then GetScaledRect fails on restricted plates (Lua Taint: _FluxUI).
local function LockFrameScale(frame, targetScale, flagKey)
    if not frame or frame[flagKey] then
        return
    end
    local orig = frame.SetScale
    if type(orig) ~= "function" then
        return
    end
    frame[flagKey] = true
    frame.SetScale = function(self, scale)
        if scale ~= targetScale then
            orig(self, targetScale)
            return
        end
        orig(self, scale)
    end
end

local function GetAnchor(parentFrame)
    if parentFrame and parentFrame.outerBorderFrame then
        return parentFrame.outerBorderFrame
    end
    return parentFrame
end

local function ResolvePowerContainer()
    if type(GetPlayerBottomManagedFrameContainer) == "function" then
        local ok, frame = pcall(GetPlayerBottomManagedFrameContainer)
        if ok and frame then
            return frame
        end
    end
    return _G.PlayerBottomManagedFrameContainer or _G.PlayerFrameBottomManagedFramesContainer
end

local function ResolveClassPowerParent(preferred)
    local f = preferred or ns.ClassPower.Frame or ns.PlayerFrame
    if f and f.unit and f.unit ~= "player" then
        f = ns.PlayerFrame or ns.ClassPower.Frame
    end
    return f
end

local function ResolveClassPowerAnchor(preferred)
    return GetAnchor(ResolveClassPowerParent(preferred))
end

local function EnsureClassPowerUnit(frame)
    if frame and not frame.unit then
        frame.unit = "player"
    end
end

local function FrameIsInContainer(frame, container)
    if not frame or not container then
        return false
    end
    local parent = frame:GetParent()
    while parent do
        if parent == container then
            return true
        end
        parent = parent:GetParent()
    end
    return false
end

-- Personal Resource Display builds a second frame from the same class template, and
-- nameplate bars inherit the player managed-frame template. Both land in the holder
-- Flux anchors. PlayerFrame.classPowerBar often points at the clone, not the named bar.
local DUPLICATE_CLASS_BAR_NAMES = {
    ClassNameplateBarPaladinFrame = true,
    ClassNameplateBarMageFrame = true,
    ClassNameplateBarRogueFrame = true,
    ClassNameplateBarFeralDruidFrame = true,
    ClassNameplateBarWarlockFrame = true,
    ClassNameplateBarWindwalkerMonkFrame = true,
    ClassNameplateBarDracthyrFrame = true,
    DeathKnightResourceOverlayFrame = true,
}

local hidPrdClassRow = false

local function IsDuplicateClassBar(frame)
    if not frame then
        return false
    end
    local name = frame.GetName and frame:GetName()
    if name and DUPLICATE_CLASS_BAR_NAMES[name] then
        return true
    end
    local prd = _G.PersonalResourceDisplayFrame
    if not prd then
        return false
    end
    if frame == prd.classFrame or frame == prd.ClassFrameContainer then
        return true
    end
    return FrameIsInContainer(frame, prd)
end

local function EachClassBar(visitor)
    local seen = {}
    local function visit(frame)
        if frame and not seen[frame] and not IsDuplicateClassBar(frame) then
            seen[frame] = true
            visitor(frame)
        end
    end
    for i = 1, #CLASS_BAR_NAMES do
        visit(_G[CLASS_BAR_NAMES[i]])
    end
end

-- Personal resource display can hide the player-frame bar. Flux owns that frame,
-- so the class-power option is what shows or hides the Blizzard widgets.
-- Do not call Setup(), RegisterUnitEvent, or SetScript on these bars.
-- Midnight marks that registration tainted. Essence UpdatePower then cannot
-- compare secret regen (peace), and the same path covers combo points, holy
-- power, chi, shards, runes, and arcane charges. Blizzard's own OnLoad Setup
-- keeps the handlers untainted. We only move the holder.
local function PrepareClassBar(frame)
    if not frame then
        return
    end
    EnsureClassPowerUnit(frame)
    -- Flux replaces the player frame, so the personal-resource option must not hide these bars.
    frame.canBeHiddenByPersonalResourceDisplay = false
    if frame.hiddenByPersonalResourceDisplay then
        frame.hiddenByPersonalResourceDisplay = false
    end
end

local function PrepareAllClassBars()
    EachClassBar(PrepareClassBar)
end

local petIgnorePrev

local function SetPetIgnoredInClassLayout(ignored)
    local pet = _G.PetFrame
    if not pet then
        return
    end
    if ignored then
        if petIgnorePrev == nil then
            petIgnorePrev = pet.ignoreInLayout and true or false
        end
        pet.ignoreInLayout = true
    elseif petIgnorePrev ~= nil then
        pet.ignoreInLayout = petIgnorePrev
        petIgnorePrev = nil
    end
end

local function RestorePersonalResourceClassRow()
    if not hidPrdClassRow or InCombatLockdown() then
        return
    end
    hidPrdClassRow = false
    local prd = _G.PersonalResourceDisplayFrame
    local row = prd and prd.ClassFrameContainer
    if not row or prd.hideClassInfo then
        return
    end
    -- Hide() while the clone was in the player holder leaves it parented there.
    -- Put it back on the personal resource row before that row is shown again.
    local classFrame = prd.classFrame
    if classFrame then
        if classFrame.Show and not classFrame:IsShown() then
            classFrame:Show()
        end
        if classFrame.GetParent and classFrame:GetParent() ~= row then
            classFrame:SetParent(row)
            classFrame:ClearAllPoints()
            classFrame:SetPoint("CENTER", row, "CENTER")
        end
    end
    row:Show()
end

local function HidePersonalResourceClassRow()
    if InCombatLockdown() then
        return
    end
    local prd = _G.PersonalResourceDisplayFrame
    local row = prd and prd.ClassFrameContainer
    if not row or not row:IsShown() then
        return
    end
    hidPrdClassRow = true
    row:Hide()
end

local function EvictDuplicateClassBars(container)
    if not container or InCombatLockdown() then
        return
    end
    local function walk(parent)
        if not parent or not parent.GetChildren then
            return
        end
        local ok, children = pcall(function()
            return { parent:GetChildren() }
        end)
        if not ok or not children then
            return
        end
        for i = 1, #children do
            local frame = children[i]
            if IsDuplicateClassBar(frame) and frame.Hide then
                frame:Hide()
            end
        end
    end
    walk(container)
    walk(container.BottomManagedLayoutContainer)
end

local function HideClassPowerFrames()
    SetPetIgnoredInClassLayout(false)
    if _G.TotemFrame then
        _G.TotemFrame.ignoreInLayout = nil
    end
    local container = ResolvePowerContainer()
    if container then
        if UnregisterStateDriver then
            pcall(UnregisterStateDriver, container, "visibility")
        end
        container:Hide()
    end
    EachClassBar(function(frame)
        if frame.Hide then
            frame:Hide()
        end
    end)
    RestorePersonalResourceClassRow()
end

local function AnchorAbovePlayer(frame, parentFrame, scale)
    local anchor = GetAnchor(parentFrame)
    if not frame or not anchor or InCombatLockdown() then
        return
    end
    EnsureClassPowerUnit(frame)
    frame:SetParent(UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel((anchor:GetFrameLevel() or 0) + 20)
    -- Do not replace SetScale. UpdatePower compares secret numbers, and a
    -- wrapped SetScale taints the rest of that Blizzard call.
    frame:SetScale(scale)
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOM", anchor, "TOP", 0, UNIVERSAL_POWER_BAR_Y_OFFSET)
end

local function PositionArcaneCharges(parentFrame)
    local frame = _G.MageArcaneChargesFrame
    if not frame or not parentFrame or IsDuplicateClassBar(frame) then
        return
    end
    PrepareClassBar(frame)
    if not frame:IsShown() then
        return
    end
    AnchorAbovePlayer(frame, parentFrame, ARCANE_CHARGES_SCALE)
end

local function PositionTotemFrame(parentFrame)
    local totemFrame = _G.TotemFrame
    if not totemFrame or not parentFrame then
        return
    end
    local anchorFrame = ResolveClassPowerAnchor(parentFrame)
    if not anchorFrame or InCombatLockdown() then
        return
    end
    EnsureClassPowerUnit(totemFrame)
    totemFrame.ignoreInLayout = true
    -- Blizzard shows this only while a totem is active.
    if not totemFrame:IsShown() then
        return
    end
    totemFrame:SetParent(anchorFrame)
    totemFrame:SetScale(TOTEM_FRAME_SCALE)
    totemFrame:ClearAllPoints()
    totemFrame:SetPoint("BOTTOMRIGHT", anchorFrame, "TOPLEFT", TOTEM_FRAME_X_OFFSET, TOTEM_FRAME_Y_OFFSET)
end

local LOOSE_BARS_BY_CLASS = {
    DEATHKNIGHT = { RuneFrame = true },
    MAGE = { MageArcaneChargesFrame = true },
    MONK = { MonkHarmonyBarFrame = true },
    PALADIN = { PaladinPowerBarFrame = true },
    WARLOCK = { WarlockPowerFrame = true },
    EVOKER = { EssencePlayerFrame = true },
    ROGUE = { RogueComboPointBarFrame = true, ComboPointPlayerFrame = true },
    DRUID = { DruidComboPointBarFrame = true, ComboPointPlayerFrame = true },
}

local function IsLooseBarForPlayer(frame)
    if not frame or IsDuplicateClassBar(frame) then
        return false
    end
    local _, class = UnitClass("player")
    local allowed = LOOSE_BARS_BY_CLASS[class]
    local name = frame.GetName and frame:GetName()
    return allowed and name and allowed[name] or false
end

local function AnchorLooseBars(parentFrame, container)
    EachClassBar(function(frame)
        if frame == _G.MageArcaneChargesFrame or frame == _G.TotemFrame or IsDuplicateClassBar(frame) then
            return
        end
        if not frame:IsShown() or not IsLooseBarForPlayer(frame) then
            return
        end
        if FrameIsInContainer(frame, container) then
            return
        end
        -- Still parented to the alpha-0 PlayerFrame, so the container never received it.
        AnchorAbovePlayer(frame, parentFrame, UNIVERSAL_POWER_BAR_SCALE)
    end)
end

local function AnchorPowerContainer(container, parentFrame)
    local anchor = ResolveClassPowerAnchor(parentFrame)
    if not anchor then
        return false
    end
    SetPetIgnoredInClassLayout(true)
    container:SetParent(UIParent)
    container:SetFrameStrata("MEDIUM")
    container:SetFrameLevel((anchor:GetFrameLevel() or 0) + 20)
    container:SetScale(UNIVERSAL_POWER_BAR_SCALE)
    container:ClearAllPoints()
    container:SetPoint("BOTTOM", anchor, "TOP", 0, UNIVERSAL_POWER_BAR_Y_OFFSET)
    container:Show()
    if RegisterStateDriver then
        pcall(RegisterStateDriver, container, "visibility", "[petbattle] hide; show")
    end
    if container.Layout then
        pcall(container.Layout, container)
    end
    return true
end

local function TryLegacyCombo(parentFrame)
    if not (ns.API and ns.API.ShouldUseLegacyComboFrameUI and ns.API.ShouldUseLegacyComboFrameUI()) then
        return
    end
    if not (ns.LegacyComboPoints and ns.LegacyComboPoints.Initialize) then
        return
    end
    local _, cls = UnitClass("player")
    if cls ~= "ROGUE" and cls ~= "DRUID" then
        return
    end
    pcall(ns.LegacyComboPoints.Initialize, parentFrame)
end

local function SchedulePosition(parentFrame, delay)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, function()
            pcall(ns.ClassPower.UpdatePosition, parentFrame)
        end)
    end
end

function ns.ClassPower.ApplyVisibility()
    local show = not FluxUnitFrames_ShouldShowClassPower or FluxUnitFrames_ShouldShowClassPower()
    if not show then
        if InCombatLockdown() then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.5, ns.ClassPower.ApplyVisibility)
            end
            return
        end
        HideClassPowerFrames()
        return
    end
    local parent = ns.ClassPower.Frame or ns.PlayerFrame
    if parent then
        ns.ClassPower.UpdatePosition(parent)
    end
end

function ns.ClassPower.UpdatePosition(parentFrame)
    if FluxUnitFrames_ShouldShowClassPower and not FluxUnitFrames_ShouldShowClassPower() then
        if not InCombatLockdown() then
            HideClassPowerFrames()
        end
        return
    end
    if ns.ClassPower._applying then
        return
    end
    parentFrame = ResolveClassPowerParent(parentFrame)
    local powerContainer = ResolvePowerContainer()
    if not powerContainer or not parentFrame then
        return
    end
    if InCombatLockdown() then
        SchedulePosition(parentFrame, 0.5)
        return
    end

    ns.ClassPower._applying = true
    pcall(function()
        -- Do not call Blizzard Setup. Arcane charges are pulled out for scale.
        -- Totems sit at the corner, so they must not take a slot in the row.
        if _G.TotemFrame then
            _G.TotemFrame.ignoreInLayout = true
        end
        PrepareAllClassBars()
        if not AnchorPowerContainer(powerContainer, parentFrame) then
            return
        end
        PrepareAllClassBars()
        if powerContainer.Layout then
            pcall(powerContainer.Layout, powerContainer)
        end
        EvictDuplicateClassBars(powerContainer)
        HidePersonalResourceClassRow()
        local _, class = UnitClass("player")
        if class == "MAGE" then
            PositionArcaneCharges(parentFrame)
        end
        PositionTotemFrame(parentFrame)
        AnchorLooseBars(parentFrame, powerContainer)
    end)
    ns.ClassPower._applying = false
end

local function WatchPersonalResourceHide()
    if ns.ClassPower._prdWatch or not EventRegistry or not EventRegistry.RegisterCallback then
        return
    end
    ns.ClassPower._prdWatch = true
    pcall(EventRegistry.RegisterCallback, EventRegistry, "PersonalResourceDisplay.HideClassInfoOnPlayerFrameChanged", function()
        local parent = ResolveClassPowerParent(nil)
        if not parent then
            return
        end
        -- Do not call Setup from here. Re-registering UNIT_POWER_FREQUENT taints
        -- the next OnEvent, and essence regen compares then throw.
        local function refresh()
            PrepareAllClassBars()
            pcall(ns.ClassPower.UpdatePosition, parent)
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, refresh)
        else
            refresh()
        end
    end)
end

function ns.ClassPower.Initialize(parentFrame)
    if not parentFrame then
        return
    end
    if parentFrame.unit and parentFrame.unit ~= "player" then
        return
    end
    if ns.ClassPower._initialized and ns.ClassPower.Frame == parentFrame then
        pcall(ns.ClassPower.UpdatePosition, parentFrame)
        return
    end
    ns.ClassPower._initialized = true
    ns.ClassPower.Frame = parentFrame

    local _, class = UnitClass("player")
    if class == "MAGE" then
        local frame = _G.MageArcaneChargesFrame
        if frame then
            EnsureClassPowerUnit(frame)
        end
    end

    local function DisableAlternatePowerBar()
        local framesToDisable = {}
        local namesToCheck = {
            "PlayerPowerBarAlt",
            "AlternatePowerBar",
            "PlayerFrameAlternateManaBar",
            "PlayerFrameAlternatePowerBar",
        }
        for _, name in ipairs(namesToCheck) do
            if _G[name] then
                table.insert(framesToDisable, _G[name])
            end
        end
        if _G.PlayerFrame then
            if _G.PlayerFrame.activeAlternatePowerBar then
                table.insert(framesToDisable, _G.PlayerFrame.activeAlternatePowerBar)
            end
            if _G.PlayerFrame.AlternatePowerBar then
                table.insert(framesToDisable, _G.PlayerFrame.AlternatePowerBar)
            end
            if _G.PlayerFrame.powerBarAlt then
                table.insert(framesToDisable, _G.PlayerFrame.powerBarAlt)
            end
        end
        local Blizz = ns.Flux and ns.Flux.Blizz
        if not Blizz then
            return
        end
        for _, frame in ipairs(framesToDisable) do
            if not Blizz.IsHidden(frame) then
                Blizz.Hide(frame)
            end
        end
    end

    DisableAlternatePowerBar()
    WatchPersonalResourceHide()

    local function Setup()
        parentFrame = ResolveClassPowerParent(parentFrame)
        if not parentFrame then
            return
        end
        if InCombatLockdown() then
            C_Timer.After(0.5, Setup)
            return
        end

        -- Era/Anniversary keep the old container for totems and still draw combo
        -- points on ComboFrame. Do not wait for the container to be missing.
        TryLegacyCombo(parentFrame)

        local powerContainer = ResolvePowerContainer()
        if not powerContainer then
            if FLUX_API and FLUX_API.isRetail then
                C_Timer.After(1.0, Setup)
            end
            return
        end

        local anchorFrame = ResolveClassPowerAnchor(parentFrame)
        if not anchorFrame then
            C_Timer.After(0.1, Setup)
            return
        end

        pcall(ns.ClassPower.UpdatePosition, parentFrame)
        SchedulePosition(parentFrame, 0.2)
        SchedulePosition(parentFrame, 0.5)

        if class == "MAGE" then
            local function TryArcane()
                if _G.MageArcaneChargesFrame then
                    pcall(PositionArcaneCharges, parentFrame)
                    return true
                end
                return false
            end
            if not TryArcane() then
                C_Timer.After(0.1, function()
                    if not TryArcane() then
                        C_Timer.After(0.5, function()
                            if not TryArcane() then
                                C_Timer.After(1.0, TryArcane)
                            end
                        end)
                    end
                end)
            end
        end
    end

    Setup()

    if not ns.ClassPower._eventFrame then
        local eventFrame = CreateFrame("Frame")
        ns.ClassPower._eventFrame = eventFrame
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        eventFrame:RegisterEvent("UNIT_DISPLAYPOWER")
        eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
        eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        eventFrame:RegisterEvent("PLAYER_TOTEM_UPDATE")
        eventFrame:RegisterEvent("RUNE_POWER_UPDATE")
        pcall(eventFrame.RegisterEvent, eventFrame, "UNIT_ENTERED_VEHICLE")
        pcall(eventFrame.RegisterEvent, eventFrame, "UNIT_EXITED_VEHICLE")

        eventFrame:SetScript("OnEvent", function(self, event, ...)
            local liveParent = ResolveClassPowerParent(nil)
            if not liveParent then
                return
            end
            if event == "UNIT_POWER_UPDATE" then
                local unit = ...
                if unit ~= "player" then
                    return
                end
            end

            if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED"
                or event == "PLAYER_TALENT_UPDATE" or event == "UNIT_DISPLAYPOWER"
                or event == "UPDATE_SHAPESHIFT_FORM" or event == "UNIT_EXITED_VEHICLE"
                or event == "UNIT_ENTERED_VEHICLE" then
                SchedulePosition(liveParent, 0.1)
                SchedulePosition(liveParent, 0.5)
                SchedulePosition(liveParent, 1.0)
            end

            pcall(ns.ClassPower.UpdatePosition, liveParent)
        end)
    end
end
