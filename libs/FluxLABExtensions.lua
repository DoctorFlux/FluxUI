local addonName, ns = ...

local LAB = LibStub and LibStub("LibActionButton-1.0", true)
if not LAB then return end

local lib = LAB
local GetTime = GetTime
local next, pairs, wipe, type, tonumber = next, pairs, wipe, type, tonumber
local C_Timer = C_Timer

local ActiveButtons = lib.activeButtons
local ButtonRegistry = lib.buttonRegistry

-- ---------------------------------------------------------------------------
-- 2. Deferred ACTIONBAR_SLOT_CHANGED coalescing
-- DISABLED: LAB already coalesces ASC via FlushActionBarSlotChangedSlots → Update.
-- This HookScript ran a second UpdateAction pass on the same buttons during
-- shapeshift bonus-bar storms (major hitch). Keep FluxLABApplySlotChangedButton
-- for callers that need a targeted refresh.
-- ---------------------------------------------------------------------------

lib.fluxDeferSlotDirty = lib.fluxDeferSlotDirty or {}

local function FluxLABApplySlotChangedButton(button)
    if not button or button._state_type ~= "action" then return end
    local oldTex = button.icon and button.icon:GetTexture()
    local newTex = button:GetTexture()
    local hadAction = (ActiveButtons[button] ~= nil)
    local hasAction = button:HasAction()
    if oldTex ~= newTex or hadAction ~= hasAction then
        button:UpdateAction(true)
    end
end
_G.FluxLABApplySlotChangedButton = FluxLABApplySlotChangedButton

--[[
local slotFlushPending = false
local function FlushSlotDirtyQueue()
    ...
end
if lib.eventFrame then
    lib.eventFrame:HookScript("OnEvent", ...)
end
--]]

-- ---------------------------------------------------------------------------
-- 3. Range polling — removed (LAB owns lib.rangeButtons + SampleButtonRange).
--    The previous fluxRangeButtons OnUpdate raced LAB and called button:UpdateUsable
--    which LAB buttons do not expose, leaving stuck outOfRange without paint.
-- ---------------------------------------------------------------------------

lib.fluxRangeButtons = nil

-- ---------------------------------------------------------------------------
-- 3b. Demand-drive LAB eventFrame OnUpdate (idle: no per-frame cost)
--     Range polling uses a C_Timer ticker so target-selected idle does not
--     keep eventFrame OnUpdate armed (was a major FPS cliff).
-- ---------------------------------------------------------------------------

function lib.FluxLABNeedsOnUpdate()
    -- VFX / flash only. Range is owned by FluxLABEnsureRangeTicker.
    if next(lib.fluxVFXButtons) or next(lib.fluxFlashingButtons) then
        return true
    end
    return false
end

local labRangeTicker = nil

local function LabShouldPollRange()
    if FluxMouseoverRefresh and FluxMouseoverRefresh.ShouldSkipBackgroundRangePoll
        and FluxMouseoverRefresh.ShouldSkipBackgroundRangePoll() then
        return false
    end
    if InCombatLockdown() then
        return true
    end
    return UnitExists("mouseover") or UnitExists("target")
end

local function LabCancelRangeTicker()
    if labRangeTicker then
        labRangeTicker:Cancel()
        labRangeTicker = nil
    end
    _G.FluxLABRangeTicker = nil
end

function lib.FluxLABEnsureRangeTicker()
    if not next(lib.rangeButtons) or not LabShouldPollRange() then
        LabCancelRangeTicker()
        return
    end
    if labRangeTicker or not C_Timer or not C_Timer.NewTicker then
        return
    end
    local interval = tonumber(_G.FluxLABRangeCheckInterval) or 0.2
    if interval < 0.05 then interval = 0.05 end
    labRangeTicker = C_Timer.NewTicker(interval, function()
        if not next(lib.rangeButtons) or not LabShouldPollRange() then
            LabCancelRangeTicker()
            return
        end
        if lib.ForceRangeSample then
            -- Sample without re-arming OnUpdate for range.
            pcall(function()
                for button in next, lib.rangeButtons do
                    if lib.SampleButtonRange then
                        lib.SampleButtonRange(button)
                    end
                end
                if lib.FluxLABScrubParkedRangeButtons then
                    lib.FluxLABScrubParkedRangeButtons()
                end
            end)
        end
    end)
    _G.FluxLABRangeTicker = labRangeTicker
end

function lib.FluxLABSyncOnUpdateArm()
    -- Emergency: drop a stuck condition-flip latch (mods up, age > 2s).
    local Coord = _G.FluxPagingCoordinator
    if Coord and Coord.ClearStalePagingLatch then
        pcall(Coord.ClearStalePagingLatch)
    end
    -- Keep range ticker in sync independently of OnUpdate arm.
    if lib.FluxLABEnsureRangeTicker then
        lib.FluxLABEnsureRangeTicker()
    end
    if not lib.eventFrame then return end
    local need = lib.FluxLABNeedsOnUpdate()
    if need == (lib._fluxOnUpdateArmed == true) then
        return
    end
    lib._fluxOnUpdateArmed = need
    if need then
        if lib._fluxBumpRangeTimer then lib._fluxBumpRangeTimer() end
        lib.eventFrame:SetScript("OnUpdate", lib._fluxOnUpdate)
    else
        lib.eventFrame:SetScript("OnUpdate", nil)
    end
end

-- Ensure arm helpers exist even if InitializeEventHandler already ran.
if lib.eventFrame and not lib._fluxOnUpdateArmed then
    lib.eventFrame:SetScript("OnUpdate", nil)
    lib._fluxOnUpdateArmed = false
end
if lib.FluxLABSyncOnUpdateArm then
    lib.FluxLABSyncOnUpdateArm()
end

-- ---------------------------------------------------------------------------
-- 4. Spell-to-button O(1) maps
-- ---------------------------------------------------------------------------

lib.fluxSpellIdToButtons = lib.fluxSpellIdToButtons or {}

local function ResolveButtonSpellId(button)
    if not button then return nil end
    if button._fluxGetSpellIdRaw then
        return button._fluxGetSpellIdRaw(button)
    end
    if button._fluxAspectDisplaySpellId and button._fluxAspectDisplaySpellId > 0 then
        return button._fluxAspectDisplaySpellId
    end
    if button._fluxLabGetSpellIdOrig then
        return button._fluxLabGetSpellIdOrig(button)
    end
    return button.GetSpellId and button:GetSpellId()
end

local function RebuildSpellIdMap(button)
    local map = lib.fluxSpellIdToButtons
    for _, btns in pairs(map) do
        btns[button] = nil
    end
    if not ActiveButtons[button] then return end
    local spellId = ResolveButtonSpellId(button)
    if spellId then
        if not map[spellId] then map[spellId] = {} end
        map[spellId][button] = true
    end
end
_G.FluxLAB_RebuildSpellIdMap = RebuildSpellIdMap

-- ---------------------------------------------------------------------------
-- 5. Mouseover macro tracking
-- ---------------------------------------------------------------------------

lib.fluxMouseoverMacroButtons = lib.fluxMouseoverMacroButtons or {}

local function ClassifyMouseoverMacro(button)
    lib.fluxMouseoverMacroButtons[button] = nil
    if not button or not button:HasAction() then return end
    if button._state_type ~= "action" then return end
    local action = button._state_action
    if not action or action <= 0 then return end
    local actionType, id = GetActionInfo(action)
    if actionType ~= "macro" or not id then return end
    local body = GetMacroBody and GetMacroBody(id)
    if body and body:find("@mouseover") then
        lib.fluxMouseoverMacroButtons[button] = true
    end
end

local mouseoverUsableLastFlush = 0

local function CoalescedMouseoverUsableRefresh()
    local floor = _G.FluxLABMouseoverUsableMinInterval or 0.07
    local now = GetTime()
    if (now - mouseoverUsableLastFlush) < floor then return end
    mouseoverUsableLastFlush = now
    for button in next, lib.fluxMouseoverMacroButtons do
        if button.UpdateUsable then
            button:UpdateUsable()
        end
    end
end
_G.FluxLABCoalescedMouseoverUsableRefresh = CoalescedMouseoverUsableRefresh

-- ---------------------------------------------------------------------------
-- 6. Assisted combat integration
-- ---------------------------------------------------------------------------

local function FluxMergeLabButtonsIntoAssistedHighlightCandidates()
    if not AssistedCombatManager then return end
    local spellID = AssistedCombatManager.lastNextCastSpellID
    if not spellID then return end
    local floor = _G.FluxAssistedCombatMinIconUpdateRate
    local map = lib.fluxSpellIdToButtons[spellID]
    if not map then return end
    for button in next, map do
        if button.config and button.config.actionButtonUI
            and button.config.assistedHighlight
        then
            if floor and button.AssistedCombatHighlightFrame then
                button.AssistedCombatHighlightFrame._fluxMinRate = floor
            end
        end
    end
end
_G.FluxMergeLabButtonsIntoAssistedHighlightCandidates = FluxMergeLabButtonsIntoAssistedHighlightCandidates

-- ---------------------------------------------------------------------------
-- 8. VFX button tracking
-- ---------------------------------------------------------------------------

lib.fluxVFXButtons = lib.fluxVFXButtons or {}

-- Post-DF VFX APIs are attached by FluxPostDFButtonVFX.lua (loads after this file).
-- Fallback attach if load order changes:
if C_Timer and C_Timer.After then
    C_Timer.After(0, function()
        if _G.FluxPostDFUpdateButtonSpellVFX and not lib.FluxUpdateButtonSpellVFX then
            function lib.FluxUpdateButtonSpellVFX(_, btn)
                return _G.FluxPostDFUpdateButtonSpellVFX(btn)
            end
        end
        if _G.FluxPostDFResumeCastVFX and not lib.FluxResumeCastVFX then
            function lib.FluxResumeCastVFX(_, button, preservedCastData, castType)
                return _G.FluxPostDFResumeCastVFX(button, preservedCastData, castType)
            end
        end
        if not lib.FluxRefreshCastVFXAfterLayout then
            function lib.FluxRefreshCastVFXAfterLayout(_)
                local ColumnVFX = _G.FluxActionBarColumnVFX
                if ColumnVFX and ColumnVFX.ResyncActiveCastColumns then
                    ColumnVFX.ResyncActiveCastColumns()
                end
            end
        end
        if _G.FluxBarCastState then
            lib.FluxBarCastState = _G.FluxBarCastState
        end
    end)
end

-- ---------------------------------------------------------------------------
-- 9. Callback forwarding
-- ---------------------------------------------------------------------------

local cbHandler = {}

local function OnLabButtonCreated(_, button)
    RebuildSpellIdMap(button)
    if type(_G.FluxLAB_OnButtonCreated) == "function" then
        _G.FluxLAB_OnButtonCreated("OnButtonCreated", button)
    end
end

local function OnLabButtonUpdate(_, button)
    RebuildSpellIdMap(button)
    ClassifyMouseoverMacro(button)
    if type(_G.FluxLAB_OnButtonUpdate) == "function" then
        _G.FluxLAB_OnButtonUpdate("OnButtonUpdate", button)
    end
end

local function OnLabButtonState(_, button)
    if type(_G.FluxLAB_OnButtonState) == "function" then
        _G.FluxLAB_OnButtonState("OnButtonState", button)
    end
end

LAB.RegisterCallback(cbHandler, "OnButtonCreated", OnLabButtonCreated)
LAB.RegisterCallback(cbHandler, "OnButtonUpdate", OnLabButtonUpdate)

pcall(function()
    LAB.RegisterCallback(cbHandler, "OnButtonState", OnLabButtonState)
end)

-- ---------------------------------------------------------------------------
-- Bootstrap: rebuild maps for any buttons already registered
-- ---------------------------------------------------------------------------

for button in next, ActiveButtons do
    RebuildSpellIdMap(button)
    ClassifyMouseoverMacro(button)
end
