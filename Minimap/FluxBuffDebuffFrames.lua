-- FluxBuffDebuffFrames.lua
-- Use Blizzard's actual BuffFrame and DebuffFrame. Flux only places the two
-- system frames; all aura buttons, events, styling and behavior stay Blizzard's.
local M = FluxBuffDebuffFrames or {}
FluxBuffDebuffFrames = M

local GAP, TOP, DEBUFF_X, DEBUFF_Y = 10, -10, -15, -145
local hooked = setmetatable({}, { __mode = "k" })
local scheduled, editModeActive = false, false

local function Blocked()
    return InCombatLockdown() or editModeActive or (FluxEditModeBusy and FluxEditModeBusy())
end

local function Place(frame, x, y)
    if not frame then return end
    -- Edit Mode's SetPoint/ClearAllPoints overrides alter snapping/layout data.
    -- Use its saved widget methods so positioning does not write that state.
    local clear = frame.ClearAllPointsBase or frame.ClearAllPoints
    local point = frame.SetPointBase or frame.SetPoint
    local scale = frame.GetScale and frame:GetScale() or 1
    if scale == 0 then return end
    clear(frame)
    point(frame, "TOPRIGHT", UIParent, "TOPRIGHT", x / scale, y / scale)
end

function M:PositionBuffFrames()
    if Blocked() then self._pending = true; return end
    local minimap = _G.FluxMinimap
    local width = minimap and minimap.GetNormalWidth and minimap:GetNormalWidth() or 190
    -- EnforcePosition docks the normal minimap at screen x=0.
    local x = -(width + GAP)
    -- Screen anchors, independent of Minimap and its embedded parent/size.
    -- Preserve Blizzard's 15px horizontal and 145px vertical row separation.
    Place(_G.BuffFrame, x, TOP)
    Place(_G.DebuffFrame, x + DEBUFF_X, TOP + DEBUFF_Y)
    self._pending = nil
end

local function Schedule()
    if scheduled then return end
    scheduled = true
    C_Timer.After(0, function()
        scheduled = false
        M:RefreshBlizzardAuraFrames()
    end)
end

function M:RefreshBlizzardAuraFrames()
    for _, frame in pairs({ _G.BuffFrame, _G.DebuffFrame }) do
        if frame.ApplySystemAnchor and not hooked[frame] then
            hooked[frame] = true
            -- Lua layout method only. Defer our placement until Blizzard's pass
            -- ends; never hook widget methods or call the native aura updater.
            hooksecurefunc(frame, "ApplySystemAnchor", Schedule)
        end
    end
    self:PositionBuffFrames()
end

function M:TryInstallBlizzardAuraSqueezeHooks()
end

function M:RefreshBlizzardBuffDebuffSqueeze()
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
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "ADDON_LOADED", "EDIT_MODE_LAYOUT_APPLIED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do
    if not C_EventUtils or C_EventUtils.IsEventValid(event) then watcher:RegisterEvent(event) end
end
watcher:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name ~= "Blizzard_BuffFrame" then return end
    Schedule()
end)
if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("EditMode.Enter", function()
        editModeActive = true
    end)
    EventRegistry:RegisterCallback("EditMode.Exit", function()
        editModeActive = false
        Schedule()
    end)
end

_G.FluxBuffDebuffFrames = M
