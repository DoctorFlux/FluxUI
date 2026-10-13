--[[
    ExtraButtonSystem/NonCombatGrid/GridInit.lua
    NonCombat grid: Hearthstone + class Teleport/Portal + Food/Water (inventory-backed).
    Anchor: screen LEFT + action-strip BOTTOM (NC_GRID_SCREEN_BOTTOM_X = 4).
]]

FluxNonCombatAPI = FluxNonCombatAPI or {}
local API = FluxNonCombatAPI

local NC_GRID_SCREEN_BOTTOM_X = 4

local function GetActionStripBottomY()
    local y = (_G.FluxExtraButtonSystem_GetActionStripBottomOffset
        and _G.FluxExtraButtonSystem_GetActionStripBottomOffset())
        or (_G.FluxActionBar_GetBottomScreenOffset and _G.FluxActionBar_GetBottomScreenOffset())
        or 0
    if type(y) ~= "number" or y ~= y then
        y = 0
    end
    return y
end

local function ApplyLeftAnchor(grid)
    if InCombatLockdown() or not grid or not grid.Frame then
        return
    end
    local frame = grid.Frame
    local bottomY = GetActionStripBottomY()
    frame:ClearAllPoints()
    local Cap = _G.Flux and _G.Flux.Cap
    local gamepad = Cap and Cap.GamepadHudActive and Cap.GamepadHudActive()
    local bar = _G.FluxMainActionBar
    if bar and bar:IsShown() and not gamepad then
        -- Same Y as action strip, pinned to the left edge of the screen (V9).
        frame:SetPoint("LEFT", UIParent, "LEFT", NC_GRID_SCREEN_BOTTOM_X, 0)
        frame:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
    else
        -- This frame is scaled. SetPoint offsets are in its own scale, so a
        -- UIParent-space Y has to be divided by that scale or the row never rises.
        local pointY = bottomY
        local es = frame.GetEffectiveScale and frame:GetEffectiveScale()
        local ps = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()
        if type(es) == "number" and es > 0 and type(ps) == "number" and ps > 0 then
            pointY = bottomY * ps / es
        end
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", NC_GRID_SCREEN_BOTTOM_X, pointY)
    end
end

function API.UpdateAnchor()
    ApplyLeftAnchor(API.DefaultGrid)
end

local function Initialize()
    if InCombatLockdown() then
        return
    end
    local Grid = FluxNonCombatGrid
    if not Grid or not Grid.New then
        return
    end
    if API.DefaultGrid then
        ApplyLeftAnchor(API.DefaultGrid)
        return
    end
    local grid = Grid.New(UIParent, {
        name = "FluxNonCombatGrid_Main",
        rows = 2,
        cols = 4,
        size = 44,
        spacing = 2,
    })
    API.DefaultGrid = grid
    -- V9 order: Hearth → Mount → Teleport → Food/Water → Consumables
    if FluxNCHearthstone and FluxNCHearthstone.Register then
        FluxNCHearthstone.Register(grid)
    end
    if FluxNCMount and FluxNCMount.Register then
        FluxNCMount.Register(grid)
    end
    if FluxNCTeleportPortal and FluxNCTeleportPortal.Register then
        FluxNCTeleportPortal.Register(grid)
    end
    if FluxNCWater and FluxNCWater.Create then
        FluxNCWater.Create(grid)
    end
    if FluxNCFood and FluxNCFood.Create then
        FluxNCFood.Create(grid)
    end
    if FluxNCConsumables and FluxNCConsumables.Register then
        FluxNCConsumables.Register(grid)
    end
    if FluxNCUtilitySlotsManager and FluxNCUtilitySlotsManager.OnNonCombatGridReady then
        FluxNCUtilitySlotsManager.OnNonCombatGridReady(grid)
    end
    ApplyLeftAnchor(grid)
    if grid.Frame then
        grid.Frame:Show()
    end
    if grid.Relayout then
        _G.FluxNCRegenRelayoutInit = (_G.FluxNCRegenRelayoutInit or 0) + 1
        grid:Relayout()
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if not API.DefaultGrid then
            if not InCombatLockdown() then
                Initialize()
            end
            return
        end
        if API.DefaultGrid._pendingRegenRelayout then
            _G.FluxNCRegenRelayoutFull = (_G.FluxNCRegenRelayoutFull or 0) + 1
            ApplyLeftAnchor(API.DefaultGrid)
            if API.DefaultGrid.Relayout then
                API.DefaultGrid:Relayout()
            end
        else
            _G.FluxNCRegenRelayoutSkipped = (_G.FluxNCRegenRelayoutSkipped or 0) + 1
        end
        return
    end
    if InCombatLockdown() then
        return
    end
    Initialize()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if not InCombatLockdown() then
                ApplyLeftAnchor(API.DefaultGrid)
                if API.DefaultGrid and API.DefaultGrid.Relayout then
                    API.DefaultGrid:Relayout()
                end
            end
        end)
        C_Timer.After(0.15, function()
            if API.DefaultGrid and API.DefaultGrid.Relayout and not InCombatLockdown() then
                ApplyLeftAnchor(API.DefaultGrid)
                API.DefaultGrid:Relayout()
            end
            if FluxCombatManager and FluxCombatManager.FinalizeLayout then
                FluxCombatManager:FinalizeLayout()
            end
        end)
    end
end)

_G.FluxNonCombatAPI = API
_G.FluxNonCombatGrid_ApplyScreenBottomAnchor = function()
    ApplyLeftAnchor(API.DefaultGrid)
end

return API
