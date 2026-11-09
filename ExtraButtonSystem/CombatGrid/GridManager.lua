--[[
    ExtraButtonSystem/CombatGrid/GridManager.lua
    Init + anchor for Inventory-backed combat consumable buttons.

    No shapeshift / UNIT_DISPLAYPOWER listeners by design: mana pot/gem visibility is
    pool-based (GetPlayerHasMana via IsManaKindRelevant), stable across Druid forms.
]]

FluxCombatManager = FluxCombatManager or {}
local Manager = FluxCombatManager
local Flux = _G.Flux
local managedStartup = Flux and Flux.Module and Flux.Module.Register

local GRID_NAME = "FluxCombatGrid_Main"
local ANCHOR_OFFSET_X = -4

local function GetActionStripBottomY()
    local y = (_G.FluxExtraButtonSystem_GetActionStripBottomOffset
        and _G.FluxExtraButtonSystem_GetActionStripBottomOffset()) or 0
    if type(y) ~= "number" or y ~= y then
        y = 0
    end
    return y
end

local function Initialize()
    if InCombatLockdown() or (managedStartup and not Flux.securePhaseReady) then
        return false
    end
    local Grid = FluxCombatGrid
    if not Grid or not Grid.New then
        return false
    end
    if Manager._startupReady then return true end
    if not Manager.Grid then
        Manager.Grid = Grid.New(UIParent, {
            name = GRID_NAME,
            rows = 2,
            cols = 3,
            size = 44,
            spacing = 2,
        })
    end
    if not Manager.Grid then return false end
    Manager:UpdateAnchor()
    if not Manager.ButtonsInitialized then
        if Manager.Grid.BeginLayout then Manager.Grid:BeginLayout() end
        local ok, err = pcall(Manager.InitializeButtons, Manager)
        if Manager.Grid.EndLayout then Manager.Grid:EndLayout(ok) end
        if not ok then error(err) end
        Manager.ButtonsInitialized = true
    end
    if Manager.Grid.Show then
        Manager.Grid:Show()
    elseif Manager.Grid.Frame then
        Manager.Grid.Frame:Show()
    end
    Manager._startupReady = true
    if Flux and Flux.Startup then Flux.Startup.Mark("combat_grid_infrastructure_ready") end
    return true
end

function Manager:UpdateAnchor()
    if not self.Grid or not self.Grid.Frame then
        return
    end
    if InCombatLockdown() then
        self.Grid._pendingRegenRelayout = true
        return
    end
    local gridFrame = self.Grid.Frame
    gridFrame:ClearAllPoints()
    -- Beside the action bar, combat stays on the bar's left. The non-combat
    -- grid is its own column at the screen edge and is not this frame's parent.
    local Cap = _G.Flux and _G.Flux.Cap
    local gamepad = Cap and Cap.GamepadHudActive and Cap.GamepadHudActive()
    local bar = _G.FluxActionStrip or _G.FluxMainActionBar
    if bar and bar:IsShown() and not gamepad then
        gridFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", ANCHOR_OFFSET_X + 4, 0)
        return
    end
    -- No 19-column bar (gamepad HUD). Continue the row to the right of non-combat.
    local nc = _G.FluxNonCombatAPI and FluxNonCombatAPI.DefaultGrid and FluxNonCombatAPI.DefaultGrid.Frame
    if nc and nc.IsShown and nc:IsShown() then
        gridFrame:SetPoint("BOTTOMLEFT", nc, "BOTTOMRIGHT", 8, 0)
        return
    end
    gridFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", -196, GetActionStripBottomY())
end

function Manager:FinalizeLayout()
    if not self.Grid then
        return
    end
    if InCombatLockdown() then
        self.Grid._pendingRegenRelayout = true
        return
    end
    self:UpdateAnchor()
    if self.Grid.Relayout then
        self.Grid:Relayout()
    end
end

local function FluxCombatGrid_ShouldCreateAmmoButton()
    local EBV = FluxExtraButtonVisibility
    if EBV and type(EBV.ClientHasAmmoSlot) == "function" then
        return EBV.ClientHasAmmoSlot()
    end
    local API = _G.FLUX_API
    if API and type(API.ClientSupportsCombatAmmoExtraButton) == "function" then
        return API.ClientSupportsCombatAmmoExtraButton()
    end
    return true
end

function Manager:InitializeButtons()
    local grid = self.Grid
    if not grid then
        return
    end
    self._startupRegistrations = self._startupRegistrations or {}
    local function Create(key, module)
        if module and module.Create and not self._startupRegistrations[key] then
            module.Create(grid)
            self._startupRegistrations[key] = true
        end
    end
    -- Order: bandage / pots / gem / HS / ammo — column groups drive layout.
    Create("bandage", FluxCombatBandage)
    Create("healPotion", FluxCombatHealPotion)
    Create("manaPotion", FluxCombatManaPotion)
    Create("manaGem", FluxCombatManaGem)
    Create("healthstone", FluxCombatHealthstone)
    -- Ammo last: display-only count for equipped ammo / thrown.
    if FluxCombatAmmo and FluxCombatAmmo.Create and FluxCombatGrid_ShouldCreateAmmoButton() then
        Create("ammo", FluxCombatAmmo)
    end
    if grid.Relayout then
        grid:Relayout()
    end
end

if managedStartup then
    Flux.Module.Register("CombatGrid", {
        phase = "secure", priority = 46, protected = true, OnEnable = Initialize,
    })
end

if Flux and Flux.AfterLogin then
    Flux.AfterLogin(function()
        if InCombatLockdown() then return end
        local wasReady = Manager._startupReady
        if not Initialize() or not wasReady then return end
        local grid = Manager.Grid
        if grid.BeginLayout then grid:BeginLayout() end
        for _, module in ipairs({ FluxCombatBandage, FluxCombatHealPotion, FluxCombatManaPotion,
            FluxCombatManaGem, FluxCombatHealthstone, FluxCombatAmmo }) do
            if module.Update then Flux.Safecall(module.Update, true) end
        end
        Manager:FinalizeLayout()
        if grid.EndLayout then grid:EndLayout() end
    end)
end

Manager._combatRefreshers = Manager._combatRefreshers or {}
Manager._combatRefreshTicker = Manager._combatRefreshTicker or nil

function Manager:RegisterCombatRefresh(key, fn)
    if not key or type(fn) ~= "function" then
        return
    end
    self._combatRefreshers[key] = fn
    if InCombatLockdown() then
        self:_StartCombatRefreshTicker()
    end
end

function Manager:UnregisterCombatRefresh(key)
    if key then
        self._combatRefreshers[key] = nil
    end
end

function Manager:_RunCombatRefreshers()
    for k, fn in pairs(self._combatRefreshers) do
        if fn then
            pcall(fn)
        end
    end
end

function Manager:_StartCombatRefreshTicker()
    if self._combatRefreshTicker then
        return
    end
    if not next(self._combatRefreshers) then
        return
    end
    self._combatRefreshTicker = C_Timer.NewTicker(0.5, function()
        if not InCombatLockdown() then
            Manager:_StopCombatRefreshTicker()
            return
        end
        Manager:_RunCombatRefreshers()
    end)
end

function Manager:_StopCombatRefreshTicker()
    if self._combatRefreshTicker then
        self._combatRefreshTicker:Cancel()
        self._combatRefreshTicker = nil
    end
end

--- Coalesce Best/FluxInv fan-out: six CombatGrid Attach listeners → one Update batch.
Manager._moduleUpdatePending = false
Manager._moduleUpdateForce = false

function Manager:ScheduleAllUpdates(force)
    if force then
        self._moduleUpdateForce = true
    end
    if self._moduleUpdatePending then
        return
    end
    self._moduleUpdatePending = true
    local function run()
        self._moduleUpdatePending = false
        local doForce = self._moduleUpdateForce
        self._moduleUpdateForce = false
        if InCombatLockdown and InCombatLockdown() then
            self._moduleUpdateOnRegen = true
            self._moduleUpdateForce = doForce
            return
        end
        local Best = _G.FluxConsumableBest
        local gen = Best and Best._generation or 0
        local mods = {
            FluxCombatBandage,
            FluxCombatHealPotion,
            FluxCombatManaPotion,
            FluxCombatManaGem,
            FluxCombatHealthstone,
            FluxCombatAmmo,
        }
        local unbound, pending = false, false
        for i = 1, #mods do
            local m = mods[i]
            if m and m._pendingUpdate then pending = true end
            if m and not (m._trackedItemID or m._latchItemID) then
                unbound = true
            end
        end
        local loginScan = Best and Best.IsLoginScanActive and Best.IsLoginScanActive()
        local unsettled = Best and Best.IsSettled and not Best.IsSettled()
        if not doForce and self._lastBestGeneration == gen and gen ~= 0 then
            -- Best identity unchanged: skip full module Update megawalk,
            -- unless a combat slot is still empty during login settle.
            -- Still recount. Buying or looting more of the same potion does
            -- not bump generation, and a skipped Update left the digit stale.
            if not pending and not (unbound and (loginScan or unsettled)) then
                self._skippedUnchangedUpdates = (self._skippedUnchangedUpdates or 0) + 1
                for i = 1, #mods do
                    local m = mods[i]
                    if m and m.RefreshCountOnly then
                        pcall(m.RefreshCountOnly)
                    end
                end
                return
            end
        end
        self._lastBestGeneration = gen
        for i = 1, #mods do
            local m = mods[i]
            if m and m.Update then
                pcall(m.Update, doForce)
            end
        end
        self._lastCoalescedUpdateAt = (GetTime and GetTime()) or 0
        self._coalescedUpdateCount = (self._coalescedUpdateCount or 0) + 1
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, run)
    else
        run()
    end
end

function Manager:GetDebugStats()
    local pendingBest = 0
    local classifyQ = 0
    local Best = _G.FluxConsumableBest
    if Best then
        if Best.GetPendingLoadCount then
            pendingBest = Best.GetPendingLoadCount()
        elseif Best._pendingLoad then
            for _ in pairs(Best._pendingLoad) do
                pendingBest = pendingBest + 1
            end
        end
        if Best.GetClassifyQueueCount then
            classifyQ = Best.GetClassifyQueueCount()
        end
    end
    local pendingUpdates = 0
    local mods = {
        FluxCombatBandage,
        FluxCombatHealPotion,
        FluxCombatManaPotion,
        FluxCombatManaGem,
        FluxCombatHealthstone,
        FluxCombatAmmo,
    }
    for i = 1, #mods do
        local m = mods[i]
        if m and m._pendingUpdate then
            pendingUpdates = pendingUpdates + 1
        end
    end
    return {
        coalescedUpdates = self._coalescedUpdateCount or 0,
        lastCoalescedAt = self._lastCoalescedUpdateAt or 0,
        moduleUpdatePending = self._moduleUpdatePending and true or false,
        combatTicker = self._combatRefreshTicker ~= nil,
        bestPendingLoad = pendingBest,
        bestClassifyQueue = classifyQ,
        bestSettled = Best and Best.IsSettled and Best.IsSettled() or (pendingBest == 0 and classifyQ == 0),
        modulesPendingUpdate = pendingUpdates,
        buttonsInitialized = self.ButtonsInitialized and true or false,
        skippedUnchanged = self._skippedUnchangedUpdates or 0,
    }
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        Manager:_StartCombatRefreshTicker()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        Manager:_StopCombatRefreshTicker()
        if not Manager._startupReady then
            Initialize()
            return
        end
        if Manager._moduleUpdateOnRegen then
            Manager._moduleUpdateOnRegen = nil
            Manager:ScheduleAllUpdates(Manager._moduleUpdateForce)
        end
        if Manager.Grid and Manager.Grid._pendingRegenRelayout then
            pcall(function()
                Manager:FinalizeLayout()
            end)
        end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        if Manager._startupReady then
            Manager:UpdateAnchor()
            return
        end
        if InCombatLockdown() then
            return
        end
        Initialize()
    end
end)

_G.FluxCombatManager = Manager
return Manager
