-- FluxExtraAbilityHUD.lua
-- Retail post-DF: hosts ExtraAbilityContainer on a secure host frame near FluxWindowFrame
-- (Bartender4 ExtraActionBar pattern — avoids tainting ExtraActionButton UseAction clicks).
-- ---------------------------------------------------------------------------

local addonName, ns = ...

local EXTRA_ABILITY_ANCHOR_X = -60
local EXTRA_ABILITY_ANCHOR_Y = 30
local HOST_SIZE = 128
local CONTENT_CENTER_X = 64
local CONTENT_CENTER_Y = -64

if not (FLUX_API and FLUX_API.isPostDF and ExtraAbilityContainer) then
    return
end

local container = ExtraAbilityContainer

local state = {
    host = nil,
    installed = false,
    hooksInstalled = false,
    pendingLayout = false,
    layoutFromFlux = false,
    layoutScheduled = false,
}

-- Ellesmere: ignoreFramePositionManager + ignoreInLayout is enough for Blizzard
-- to skip ExtraAbilityContainer. Never write showingFrames or RemoveManagedFrame
-- — that taints ManageFramePositions → RightManagedFrameContainer:SetSize.
local function MarkIgnoredInLayout()
    container.ignoreFramePositionManager = true
    container.ignoreInLayout = true
end

local function GetFluxWindow()
    if FluxWindowFrame and FluxWindowFrame.GetFrame then
        return FluxWindowFrame:GetFrame()
    end
    return nil
end

local function StripContainerAnchors()
    if state.installed then
        return
    end
    if InCombatLockdown() then
        state.pendingLayout = true
        return
    end

    container:SetToplevel(false)

    -- Do not nil SetPoint/ClearAllPoints: InitSystemAnchors calls them on spec/level
    -- (PLAYER_SPECIALIZATION_CHANGED → UpdateLayoutInfo). Wiping the mixin leaves
    -- SetPointBase, which ADDON BLOCKs while tainted.
    -- Do not nil OnShow/OnHide: those scripts stay Blizzard's.

    state.installed = true
end

local function PerformLayout()
    if InCombatLockdown() then
        state.pendingLayout = true
        return
    end
    local em = _G.EditModeManagerFrame
    if em and em.layoutApplyInProgress then
        state.pendingLayout = true
        if C_Timer and C_Timer.After then
            SchedulePerformLayout()
        end
        return
    end

    local win = GetFluxWindow()
    if not win or not state.host then
        state.pendingLayout = true
        return
    end

    StripContainerAnchors()
    MarkIgnoredInLayout()

    local host = state.host
    host:SetSize(HOST_SIZE, HOST_SIZE)
    host:ClearAllPoints()
    host:SetPoint("BOTTOMLEFT", win, "TOPLEFT", EXTRA_ABILITY_ANCHOR_X, EXTRA_ABILITY_ANCHOR_Y)

    state.layoutFromFlux = true

    container:SetParent(host)
    if container.ClearAllPointsBase then
        container:ClearAllPointsBase()
    else
        container:ClearAllPoints()
    end
    if container.SetPointBase then
        container:SetPointBase("CENTER", host, "TOPLEFT", CONTENT_CENTER_X, CONTENT_CENTER_Y)
    else
        container:SetPoint("CENTER", host, "TOPLEFT", CONTENT_CENTER_X, CONTENT_CENTER_Y)
    end

    state.layoutFromFlux = false
    state.pendingLayout = false
end

local function HideEditModeSelection()
    local sel = container.Selection
    if not sel then
        return
    end
    if sel.SetAlpha then
        sel:SetAlpha(0)
    end
    if sel.EnableMouse then
        sel:EnableMouse(false)
    end
end

local function SchedulePerformLayout()
    if state.layoutScheduled then
        return
    end
    state.layoutScheduled = true

    local function run()
        state.layoutScheduled = false
        HideEditModeSelection()
        PerformLayout()
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

local function OnExtraActionBarUpdate()
    -- Layout only; artwork left to Blizzard defaults.
    SchedulePerformLayout()
end

local function OnZoneAbilitiesUpdated()
    SchedulePerformLayout()
end

local function InstallHooks()
    if state.hooksInstalled then
        return
    end
    state.hooksInstalled = true

    if hooksecurefunc then
        -- Do not hook HighlightSystem: OnEditModeEnter calls it before
        -- RefreshPartyFrames, and that hook taints TargetUnit and the secret
        -- health-color compare. Selection is hidden from the deferred layout.
        if _G.ExtraActionBar_Update then
            hooksecurefunc("ExtraActionBar_Update", OnExtraActionBarUpdate)
        end

        if ZoneAbilityFrame and ZoneAbilityFrame.UpdateDisplayedZoneAbilities then
            hooksecurefunc(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities", OnZoneAbilitiesUpdated)
        end
    end

    if FluxWindowFrame then
        hooksecurefunc(FluxWindowFrame, "SetOffset", SchedulePerformLayout)
        hooksecurefunc(FluxWindowFrame, "ApplyBottomLiftFromStatusBar", SchedulePerformLayout)
    end
end

local function SetupEditModeOverride()
    if FLUX_API.hasEditMode and FluxRemoveFrameFromEditMode then
        FluxRemoveFrameFromEditMode(container)
    end

    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Enter", SchedulePerformLayout)
        EventRegistry:RegisterCallback("EditMode.Exit", SchedulePerformLayout)
    end
end

local function EnsureHost()
    if state.host then
        return state.host
    end
    local host = CreateFrame("Frame", "FluxExtraAbilityHost", UIParent, "SecureHandlerStateTemplate")
    host:SetSize(HOST_SIZE, HOST_SIZE)
    state.host = host
    return host
end

local function Initialize()
    EnsureHost()
    InstallHooks()
    SetupEditModeOverride()
    MarkIgnoredInLayout()
    SchedulePerformLayout()
end

local regenFrame = CreateFrame("Frame")
regenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
regenFrame:RegisterEvent("PLAYER_LOGIN")
pcall(regenFrame.RegisterUnitEvent, regenFrame, "PLAYER_SPECIALIZATION_CHANGED", "player")
local lastSpecToken
local function CurrentSpecToken()
    if GetSpecialization then
        local ok, spec = pcall(GetSpecialization)
        if ok and spec ~= nil then
            return spec
        end
    end
    if GetActiveTalentGroup then
        local ok, group = pcall(GetActiveTalentGroup)
        if ok and group ~= nil then
            return group
        end
    end
    return nil
end
regenFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if FluxWindowFrame and FluxWindowFrame.GetFrame then
            FluxWindowFrame:GetFrame()
        end
        lastSpecToken = CurrentSpecToken()
        Initialize()
        if C_Timer and C_Timer.After then
            C_Timer.After(2, SchedulePerformLayout)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if state.pendingLayout then
            SchedulePerformLayout()
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        -- Forever dings fire this event with the same spec. Extra Ability does
        -- not move with level; skip unless the spec/talent group actually changed.
        local spec = CurrentSpecToken()
        if spec ~= nil and spec == lastSpecToken then
            return
        end
        lastSpecToken = spec
        -- After Edit Mode InitSystemAnchors / UpdateSystems, not inside them.
        SchedulePerformLayout()
    end
end)

