--[[
    ExtraButtonSystem/NonCombatGrid/GridInit.lua
    NonCombat grid: Hearthstone + class Teleport/Portal + Food/Water (inventory-backed).
    Anchor: screen LEFT + action-strip BOTTOM (NC_GRID_SCREEN_BOTTOM_X = 4).
]]

FluxNonCombatAPI = FluxNonCombatAPI or {}
local API = FluxNonCombatAPI
local Flux = _G.Flux
local managedStartup = Flux and Flux.Module and Flux.Module.Register

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
    if not grid or not grid.Frame then return end
    if InCombatLockdown() then
        grid._pendingRegenRelayout = true
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
    if InCombatLockdown() or (managedStartup and not Flux.securePhaseReady) then
        return false
    end
    local Grid = FluxNonCombatGrid
    if not Grid or not Grid.New then
        return false
    end
    if API._startupReady then return true end
    local grid = API.DefaultGrid or Grid.New(UIParent, {
        name = "FluxNonCombatGrid_Main",
        rows = 2,
        cols = 4,
        size = 44,
        spacing = 2,
    })
    if not grid then return false end
    API.DefaultGrid = grid
    API._startupRegistrations = API._startupRegistrations or {}
    local function Register(key, module, method)
        if module and module[method] and not API._startupRegistrations[key] then
            if module[method](grid) == false then
                error("NonCombatGrid registration incomplete: " .. key)
            end
            API._startupRegistrations[key] = true
        end
    end
    if grid.BeginLayout then grid:BeginLayout() end
    local ok, err = pcall(function()
        -- V9 order: Hearth → Mount → Teleport → Food/Water → Consumables
        Register("hearth", FluxNCHearthstone, "Register")
        Register("mount", FluxNCMount, "Register")
        Register("teleport", FluxNCTeleportPortal, "Register")
        Register("water", FluxNCWater, "Create")
        Register("food", FluxNCFood, "Create")
        Register("consumables", FluxNCConsumables, "Register")
        Register("utility", FluxNCUtilitySlotsManager, "OnNonCombatGridReady")
        ApplyLeftAnchor(grid)
        if grid.Frame then grid.Frame:Show() end
        if grid.Relayout then
            _G.FluxNCRegenRelayoutInit = (_G.FluxNCRegenRelayoutInit or 0) + 1
            grid:Relayout()
        end
    end)
    if grid.EndLayout then grid:EndLayout(ok) end
    if not ok then error(err) end
    API._startupReady = true
    if Flux and Flux.Startup then Flux.Startup.Mark("noncombat_grid_infrastructure_ready") end
    return true
end

if managedStartup then
    Flux.Module.Register("NonCombatGrid", {
        phase = "secure", priority = 45, protected = true, OnEnable = Initialize,
    })
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if not API._startupReady then
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
        ApplyLeftAnchor(API.DefaultGrid)
        return
    end
    if not API._startupReady then
        Initialize()
    else
        ApplyLeftAnchor(API.DefaultGrid)
    end
end)

_G.FluxNonCombatAPI = API
_G.FluxNonCombatGrid_ApplyScreenBottomAnchor = function()
    ApplyLeftAnchor(API.DefaultGrid)
end

return API
