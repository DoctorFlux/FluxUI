-- FluxBuffDebuffFrames.lua
-- Player buffs and debuffs beside the minimap are Blizzard's BuffFrame and DebuffFrame.
-- Flux does not move those system frames and does not write an Edit Mode layout.
-- Moving the system frame taints it, and Edit Mode enter then fails the party-frame
-- secret health-color compare. The collapse button is shifted right with the icon row,
-- and only while that frame is still on the stock screen anchor. Edit Mode can still move the
-- system frame. The nudge is skipped while Edit Mode is open.
--
-- Live and Forever stock anchors are -255 / -270. Classic Era and Anniversary are -187 / -202.
-- The 15px gap between those pairs is kept. Debuffs have no collapse button, so the shift
-- sits on AuraContainer. That anchor is cleared back to zero whenever the debuff row
-- refreshes. Re-applying from a timer lets the row jump. The shift is an absolute offset
-- from that zero anchor and is put back before the frame is drawn, so it cannot stack
-- and the row stays put.

local M = FluxBuffDebuffFrames or {}
FluxBuffDebuffFrames = M

local GAP = 10
local STOCK = {
    { buff = -255, debuff = -270 },
    { buff = -187, debuff = -202 },
}

local function MapWidth()
    if FLUX_API and FLUX_API.isLegacyClient then
        return 175
    end
    return 190
end

local function EditModeOpen()
    local mgr = EditModeManagerFrame
    if not mgr then
        return false
    end
    if mgr.editModeActive then
        return true
    end
    return mgr.IsShown and mgr:IsShown()
end

-- Same delta for buffs and debuffs, taken from whichever stock pair this frame is on.
local function StockShift(frame, key)
    if not frame or not frame.GetPoint then
        return nil
    end
    local point, _, relPoint, x = frame:GetPoint(1)
    if point ~= "TOPRIGHT" or relPoint ~= "TOPRIGHT" or type(x) ~= "number" then
        return nil
    end
    local target = -(MapWidth() + GAP)
    for i = 1, #STOCK do
        if math.abs(x - STOCK[i][key]) < 1 then
            return target - STOCK[i].buff
        end
    end
    return nil
end

local function PointOffset(region)
    if not region or not region.GetPoint or not region.SetPoint then
        return nil
    end
    local point, rel, relPoint, x, y = region:GetPoint(1)
    if not point or not rel or not relPoint then
        return nil
    end
    if type(x) ~= "number" then
        x = 0
    end
    if type(y) ~= "number" then
        y = 0
    end
    return point, rel, relPoint, x, y
end

-- Blizzard anchors this child at x = 0. Set that x to the shift once.
-- Any other offset is a custom anchor and is left alone, so a missed
-- remember cannot keep adding the shift.
local function PinFromZero(region, shift)
    if shift == 0 then
        return
    end
    local point, rel, relPoint, x, y = PointOffset(region)
    if not point then
        return
    end
    if math.abs(x - shift) < 1 or math.abs(x) > 1 then
        return
    end
    region:SetPoint(point, rel, relPoint, shift, y)
end

-- A previous pass shifted the icon row off the collapse button.
local function ReleaseShifted(region, shift)
    if shift == 0 then
        return
    end
    local point, rel, relPoint, x, y = PointOffset(region)
    if not point then
        return
    end
    if math.abs(x - shift) < 1 then
        region:SetPoint(point, rel, relPoint, 0, y)
    end
end

local function NudgeFrame(frame, key)
    local shift = StockShift(frame, key)
    if not shift then
        return
    end
    local button = frame.CollapseAndExpandButton
    if button and button.GetPoint and button.SetPoint then
        ReleaseShifted(frame.AuraContainer, shift)
        PinFromZero(button, shift)
        return
    end
    PinFromZero(frame.AuraContainer, shift)
end

function M:RefreshBlizzardAuraFrames()
end

function M:TryInstallBlizzardAuraSqueezeHooks()
end

function M:RefreshBlizzardBuffDebuffSqueeze()
end

function M:PositionBuffFrames()
    if EditModeOpen() then
        return
    end
    pcall(NudgeFrame, BuffFrame, "buff")
    pcall(NudgeFrame, DebuffFrame, "debuff")
end

function M:HookConsolidatedBuffs()
end

function M:InstallOnMinimap(minimap)
    if not minimap then
        return
    end
    minimap.RefreshBlizzardAuraFrames = function()
        M:RefreshBlizzardAuraFrames()
    end
    minimap.TryInstallBlizzardAuraSqueezeHooks = function()
        M:TryInstallBlizzardAuraSqueezeHooks()
    end
    minimap.RefreshBlizzardBuffDebuffSqueeze = function()
        M:RefreshBlizzardBuffDebuffSqueeze()
    end
    minimap.PositionBuffFrames = function()
        M:PositionBuffFrames()
    end
end

if FluxMinimap then
    M:InstallOnMinimap(FluxMinimap)
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function()
    M:PositionBuffFrames()
end)
watcher:SetScript("OnUpdate", function()
    M:PositionBuffFrames()
end)

_G.FluxBuffDebuffFrames = M
