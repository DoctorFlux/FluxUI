-- FluxTalkingHead.lua
-- Retail-only: scale TalkingHeadFrame to 0.75 and park it top-left, sliding under the
-- micromenu / status stack whenever either (or both) is at layout position 1.
-- Classic clients never load this file (TOC AllowLoadGameType mainline).

local addonName, ns = ...

local SCALE = 0.75
local INSET_X = 2
local GAP_BELOW = -8

local hookedAlertFrame
local microHooksRegistered
local statusHooksRegistered
local blizzardHooksRegistered
local addonWatchRegistered
local applyingPosition
local sizeUpdateQueued

local function SafeTimerAfter(delay, callback)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, callback)
        return
    end
    local frame = CreateFrame("Frame")
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed >= delay then
            callback()
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end)
end

local function FrameUsable(frame)
    if not frame then
        return false
    end
    if frame.IsForbidden and frame:IsForbidden() then
        return false
    end
    return true
end

local function LayoutPositions()
    local menuPos, statusPos = 2, 3
    local fluxOpts = _G.FluxOptions
    if fluxOpts then
        if fluxOpts.GetMicroMenuLayoutPosition then
            menuPos = fluxOpts:GetMicroMenuLayoutPosition() or menuPos
        end
        if fluxOpts.GetStatusBarPosition then
            statusPos = fluxOpts:GetStatusBarPosition() or statusPos
        end
    end
    return menuPos, statusPos
end

local function ApplyScale(th)
    if th.SetScale then
        pcall(th.SetScale, th, SCALE)
    end
end

local function SetPointSafe(th, ...)
    if th.ClearAllPointsBase then
        pcall(th.ClearAllPointsBase, th)
    elseif th.ClearAllPoints then
        pcall(th.ClearAllPoints, th)
    end
    if th.SetPointBase then
        pcall(th.SetPointBase, th, ...)
    elseif th.SetPoint then
        pcall(th.SetPoint, th, ...)
    end
end

local UpdatePosition

-- Size hooks fire during micromenu Rebuild; applying on the same stack re-enters
-- layout (ScanButtons / Merge) until the Lua stack overflows.
local function QueueUpdatePosition()
    if sizeUpdateQueued then
        return
    end
    sizeUpdateQueued = true
    SafeTimerAfter(0, function()
        sizeUpdateQueued = false
        UpdatePosition()
    end)
end

local function EnsureFluxLayoutHooks()
    local mm = _G.FluxMicroMenu
    if not microHooksRegistered and mm and mm.HookScript then
        microHooksRegistered = true
        mm:HookScript("OnSizeChanged", QueueUpdatePosition)
        mm:HookScript("OnShow", QueueUpdatePosition)
        mm:HookScript("OnHide", QueueUpdatePosition)
    end
    local status = _G.FluxStatusBarContainer
    if not statusHooksRegistered and status and status.HookScript then
        statusHooksRegistered = true
        status:HookScript("OnSizeChanged", QueueUpdatePosition)
        status:HookScript("OnShow", QueueUpdatePosition)
        status:HookScript("OnHide", QueueUpdatePosition)
    end
end

UpdatePosition = function()
    if applyingPosition then
        return
    end
    -- Edit Mode shows and re-anchors TalkingHeadFrame inside its pass.
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(UpdatePosition)
        return
    end
    applyingPosition = true
    EnsureFluxLayoutHooks()
    local th = _G.TalkingHeadFrame
    if not FrameUsable(th) then
        applyingPosition = false
        return
    end
    -- Keep the VO on UIParent so SetPoint to micromenu/status cannot parent it into
    -- those layout frames (EditMode SetPointBase) and retrigger OnSizeChanged.
    if th.SetParent then
        pcall(th.SetParent, th, UIParent)
    end
    ApplyScale(th)

    local menuPos, statusPos = LayoutPositions()
    local micro = _G.FluxMicroMenu
    local status = _G.FluxStatusBarContainer

    -- Both pos 1, or status only: sit under the status strip (status already stacks under micro).
    if statusPos == 1 and FrameUsable(status) then
        SetPointSafe(th, "TOPLEFT", status, "BOTTOMLEFT", 0, GAP_BELOW)
    elseif menuPos == 1 and FrameUsable(micro) then
        SetPointSafe(th, "TOPLEFT", micro, "BOTTOMLEFT", 0, GAP_BELOW)
    else
        SetPointSafe(th, "TOPLEFT", UIParent, "TOPLEFT", INSET_X, 0)
    end
    applyingPosition = false
end

local function DetachFromBlizzard(th)
    if not FrameUsable(th) or th._fluxTalkingHeadDetached then
        return
    end
    th._fluxTalkingHeadDetached = true
    th.ignoreFramePositionManager = true
    -- Do not write isManagedFrame / isBottomManagedFrame: InitSystemAnchors reads
    -- those flags on spec/level and a Flux boolean taints MainActionBar:SetPointBase.
    if th.HookScript then
        pcall(th.HookScript, th, "OnShow", QueueUpdatePosition)
    end
end

local function EnsureBlizzardAnchorHooks(th)
    if blizzardHooksRegistered or not FrameUsable(th) then
        return
    end
    blizzardHooksRegistered = true
    if th.ApplySystemAnchor then
        hooksecurefunc(th, "ApplySystemAnchor", QueueUpdatePosition)
    end
    local alert = _G.AlertFrame
    if not hookedAlertFrame and alert and alert.UpdateAnchors then
        hookedAlertFrame = true
        hooksecurefunc(alert, "UpdateAnchors", QueueUpdatePosition)
    end
end

local Initialize

local function WatchTalkingHeadLoad()
    if addonWatchRegistered then
        return
    end
    addonWatchRegistered = true
    -- Never LoadAddOn Blizzard_TalkingHeadUI from Flux: OnSystemLoad then
    -- table.insert(registeredSystemFrames) taints InitSystemAnchors →
    -- MainActionBar:SetPointBase on spec/level.
    if EventUtil and EventUtil.ContinueOnAddOnLoaded then
        EventUtil.ContinueOnAddOnLoaded("Blizzard_TalkingHeadUI", Initialize)
        return
    end
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("ADDON_LOADED")
    watcher:SetScript("OnEvent", function(self, _, name)
        if name == "Blizzard_TalkingHeadUI" or _G.TalkingHeadFrame then
            self:UnregisterAllEvents()
            Initialize()
        end
    end)
end

Initialize = function()
    local th = _G.TalkingHeadFrame
    if not FrameUsable(th) then
        WatchTalkingHeadLoad()
        return
    end
    DetachFromBlizzard(th)
    EnsureBlizzardAnchorHooks(th)
    EnsureFluxLayoutHooks()
    UpdatePosition()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        SafeTimerAfter(0.1, Initialize)
        SafeTimerAfter(1.0, Initialize)
    end
end)

_G.FluxTalkingHead = {
    UpdatePosition = UpdatePosition,
    SCALE = SCALE,
}


