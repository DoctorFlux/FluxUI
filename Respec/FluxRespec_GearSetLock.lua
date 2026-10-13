-- FluxRespec_GearSetLock.lua
-- Protects bag slots and equipped gear needed for saved gear sets from vendor sell and disenchant.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.GearSetLock = R.GearSetLock or {}
local GearSetLock = R.GearSetLock

local DISENCHANT_SPELL_ID = 13262

GearSetLock.MESSAGE = "Protected gear set item"

local protectedSlots = {}
local protectedInvSlots = {}
local protectedCount = 0
local lastFingerprint = ""
local rebuildTimer = nil
local REBUILD_DEBOUNCE_SEC = 0.12
local REBUILD_DEBOUNCE_BANK_OPEN_SEC = 0.28
local REBUILD_DEBOUNCE_MERCHANT_SEC = 0.45
local lastBlockContext = false
local lastGuardMode = nil
local clickGuardFrameLevelCache = {}
local clickGuardContextToken = 0

-- Snapshot for a protection paint pass (avoids N merchant/DE API hits).
local contextSnapshotActive = false
local snapMerchantSell = false
local snapManualDE = false
local snapDisenchant = false
local snapGuardMode = nil

local function SlotKey(bag, slot)
    return ("%d:%d"):format(bag, slot)
end

local function BumpClickGuardContext()
    -- Token bump only — keep frame-level cache across merchant open/close.
    clickGuardContextToken = clickGuardContextToken + 1
end

local function GetSettings()
    local store = R.GetStore and R.GetStore()
    if not store then
        return nil
    end
    store.settings = store.settings or {}
    return store.settings
end

function GearSetLock.IsEnabled()
    local settings = GetSettings()
    if not settings then
        return true
    end
    if settings.protectGearSetItems == nil then
        settings.protectGearSetItems = true
    end
    return settings.protectGearSetItems ~= false
end

function GearSetLock.SetEnabled(enabled)
    local settings = GetSettings()
    if settings then
        settings.protectGearSetItems = enabled and true or false
    end
    if rebuildTimer and rebuildTimer.Cancel then
        rebuildTimer:Cancel()
        rebuildTimer = nil
    end
    GearSetLock.Rebuild()
end

function GearSetLock.GetProtectedSlotCount()
    return protectedCount
end

function GearSetLock.IsInventorySlotProtected(invSlot)
    if not GearSetLock.IsEnabled() then
        return false
    end
    invSlot = tonumber(invSlot)
    if not invSlot then
        return false
    end
    return protectedInvSlots[invSlot] == true
end

function GearSetLock.IsSlotProtected(bag, slot)
    if not GearSetLock.IsEnabled() then
        return false
    end
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return false
    end
    return protectedSlots[SlotKey(bag, slot)] == true
end

function GearSetLock.NotifyBlocked()
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(GearSetLock.MESSAGE, 1.0, 0.1, 0.1)
    end
end

function GearSetLock.IsMerchantSellContext()
    if C_PlayerInteractionManager and C_PlayerInteractionManager.IsInteractingWithNpcOfType
        and Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Merchant then
        local ok, interacting = pcall(
            C_PlayerInteractionManager.IsInteractingWithNpcOfType,
            Enum.PlayerInteractionType.Merchant
        )
        if ok and interacting then
            return true
        end
    end
    if MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown() then
        if MerchantFrame.selectedTab and MerchantFrame.selectedTab == 2 then
            return false
        end
        return true
    end
    return false
end

local manualDisenchantPending = false

local function GetContainerItemID(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return
    end
    local inv = R.Inv
    if inv and inv.GetItemID then
        return inv.GetItemID(bag, slot)
    end
    if C_Container and C_Container.GetContainerItemID then
        return C_Container.GetContainerItemID(bag, slot)
    end
    -- Must use _G: local GetContainerItemID would recurse into this function.
    if _G.GetContainerItemID then
        return _G.GetContainerItemID(bag, slot)
    end
end

local function IsDisenchantSpellID(spellID)
    return tonumber(spellID) == DISENCHANT_SPELL_ID
end

local function IsDisenchantSpellCurrent()
    if C_Spell and C_Spell.IsCurrentSpell then
        local ok, val = pcall(C_Spell.IsCurrentSpell, DISENCHANT_SPELL_ID)
        if ok and val then
            return true
        end
        if C_Spell.GetSpellName then
            local name = C_Spell.GetSpellName(DISENCHANT_SPELL_ID)
            if name then
                ok, val = pcall(C_Spell.IsCurrentSpell, name)
                if ok and val then
                    return true
                end
            end
        end
    end
    if IsCurrentSpell then
        if IsCurrentSpell(DISENCHANT_SPELL_ID) then
            return true
        end
        local name = GetSpellInfo and GetSpellInfo(DISENCHANT_SPELL_ID)
        if name and IsCurrentSpell(name) then
            return true
        end
    end
    return false
end

local function IsSalvageModifierActive()
    local salvage = _G.FluxSalvage
    if not salvage or not salvage.IsEnabled or not salvage.IsEnabled() then
        return false
    end
    return salvage.ModifierActive and salvage.ModifierActive() or false
end

function GearSetLock.IsSalvageDisenchantHoverContext(bag, slot)
    if not IsSalvageModifierActive() then
        return false
    end
    local salvage = _G.FluxSalvage
    if not salvage or not salvage.IsDisenchantable then
        return false
    end
    local itemID = GetContainerItemID(bag, slot)
    if not itemID then
        return false
    end
    local spellID = salvage.IsDisenchantable(itemID)
    return spellID == DISENCHANT_SPELL_ID
end

function GearSetLock.IsManualDisenchantTargeting()
    local targeting = false
    if SpellIsTargeting then
        local ok, val = pcall(SpellIsTargeting)
        targeting = ok and val
    end
    if targeting and IsDisenchantSpellCurrent() then
        manualDisenchantPending = true
        return true
    end
    if manualDisenchantPending and targeting then
        return true
    end
    if not targeting then
        manualDisenchantPending = false
    end
    return false
end

function GearSetLock.IsDisenchantContext()
    if GearSetLock.IsManualDisenchantTargeting() then
        return true
    end
    return IsSalvageModifierActive()
end

function GearSetLock.ShouldBlockContainerUse(bag, slot)
    if not GearSetLock.IsSlotProtected(bag, slot) then
        return false
    end
    return GearSetLock.IsMerchantSellContext() or GearSetLock.IsDisenchantContext()
end

function GearSetLock.ShouldBlockContainerPickup(bag, slot)
    if not GearSetLock.IsSlotProtected(bag, slot) then
        return false
    end
    if GearSetLock.IsMerchantSellContext() and GetCursorInfo then
        local cursorType = GetCursorInfo()
        if cursorType == "merchant" then
            return true
        end
    end
    return false
end

local itemButtonClickGuards = {}

-- SetPropagateMouseMotion/Clicks and SetPassThroughButtons are protected; calling
-- them in combat fires ADDON_ACTION_BLOCKED (BugGrabber). Skip while locked down.
local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function ApplyMousePropagateOnce(guard)
    if guard._fluxMousePropagateSet or InCombat() then
        return
    end
    if guard.SetPropagateMouseMotion then
        guard:SetPropagateMouseMotion(true)
    end
    if guard.SetPropagateMouseClicks then
        guard:SetPropagateMouseClicks(false)
    end
    guard._fluxMousePropagateSet = true
end

local function TrySetPassThroughButtons(guard, ...)
    if not guard.SetPassThroughButtons or InCombat() then
        return false
    end
    if select("#", ...) == 0 then
        guard:SetPassThroughButtons()
    else
        guard:SetPassThroughButtons(...)
    end
    return true
end

local function ConfigureItemButtonClickGuard(guard, button, mode, hooks)
    hooks = hooks or {}

    ApplyMousePropagateOnce(guard)
    -- Clear passthrough when safe; in combat leave prior state alone.
    TrySetPassThroughButtons(guard)
    guard.ShouldButtonPassThrough = nil

    guard:SetScript("OnEnter", function()
        if hooks.onEnter then
            hooks.onEnter(button)
        end
    end)
    guard:SetScript("OnLeave", function()
        if hooks.onLeave then
            hooks.onLeave(button)
        end
    end)

    if mode == "vendor" then
        if not guard.RegisterForClicks then
            return false
        end
        TrySetPassThroughButtons(guard)
        guard:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        return true
    end

    if mode == "right" then
        if not guard.RegisterForClicks then
            return false
        end
        -- Prefer selective passthrough; if combat-blocked, still capture right-clicks.
        TrySetPassThroughButtons(guard, "LeftButton", "MiddleButton", "Button4", "Button5")
        guard:RegisterForClicks("RightButtonUp")
        return true
    end

    if mode == "merchant" or mode == "de" then
        if guard.ShouldButtonPassThrough then
            guard.ShouldButtonPassThrough = function(_, mouseButton)
                if mouseButton == "LeftButtonDown" then
                    return true
                end
                if mouseButton == "LeftButtonUp" or mouseButton == "LeftButton" then
                    return false
                end
                return true
            end
            guard:RegisterForClicks("LeftButtonUp")
            return true
        end
        return false
    end

    return false
end

function GearSetLock.HideItemButtonClickGuard(button)
    local guard = button and itemButtonClickGuards[button]
    if guard then
        guard:Hide()
    end
end

function GearSetLock.UpdateItemButtonClickGuard(button, bag, slot, hooks)
    if not button then
        return
    end

    if not GearSetLock.ShouldShowManualClickGuard or not GearSetLock.ShouldShowManualClickGuard(bag, slot) then
        GearSetLock.HideItemButtonClickGuard(button)
        return
    end

    local mode = GearSetLock.GetManualClickGuardModeForSlot and GearSetLock.GetManualClickGuardModeForSlot(bag, slot)
        or GearSetLock.GetManualClickGuardMode and GearSetLock.GetManualClickGuardMode()
        or "right"
    local guard = itemButtonClickGuards[button]
    if not guard then
        guard = CreateFrame("Button", nil, button)
        guard:SetAllPoints(button)
        local strata = button.GetFrameStrata and button:GetFrameStrata() or "HIGH"
        guard:SetFrameStrata(strata)
        guard:EnableMouse(true)
        guard:SetScript("OnClick", function()
            if CursorHasItem and CursorHasItem() then
                return
            end
            if GetCursorInfo then
                local cursorType = GetCursorInfo()
                if cursorType == "item" then
                    return
                end
            end
            GearSetLock.NotifyBlocked()
        end)
        itemButtonClickGuards[button] = guard
    end

    if not clickGuardFrameLevelCache[button] then
        -- Prefer the button's own level; avoid recursive child walks.
        clickGuardFrameLevelCache[button] = (button.GetFrameLevel and button:GetFrameLevel()) or 0
    end
    guard:SetFrameLevel(clickGuardFrameLevelCache[button] + 50)
    if hooks and hooks.highPriority then
        guard:SetFrameStrata("TOOLTIP")
    end

    if guard.clickMode ~= mode or not guard.clickConfigured then
        guard.clickMode = mode
        guard.clickConfigured = ConfigureItemButtonClickGuard(guard, button, mode, hooks)
        if not guard.clickConfigured then
            guard:Hide()
            return
        end
    end
    guard:Show()
end

function GearSetLock.ResolveBagSlotFromOwner(owner)
    if not owner then
        return
    end

    local slotID = owner.GetID and owner:GetID()
    local bagID = (owner.GetBagID and owner:GetBagID()) or owner.bagID
    if not bagID and owner.GetParent then
        local parent = owner:GetParent()
        if parent and parent.GetID then
            bagID = parent:GetID()
        end
    end

    bagID = tonumber(bagID)
    slotID = tonumber(slotID)
    if not bagID or not slotID then
        return
    end

    return bagID, slotID
end

function GearSetLock.ResolveBagSlotFromTooltip(tooltip, tooltipData)
    if tooltipData and tooltipData.guid and C_Item and C_Item.GetItemLocation then
        local location = C_Item.GetItemLocation(tooltipData.guid)
        if location and location.IsBagAndSlot and location:IsBagAndSlot() then
            return location:GetBagAndSlot()
        end
    end

    if tooltip and tooltip.GetOwner then
        return GearSetLock.ResolveBagSlotFromOwner(tooltip:GetOwner())
    end
end

local function BuildFingerprint()
    if protectedCount == 0 and not next(protectedInvSlots) then
        return "0"
    end
    local keys = {}
    for key in pairs(protectedSlots) do
        keys[#keys + 1] = "b:" .. key
    end
    for invSlot in pairs(protectedInvSlots) do
        keys[#keys + 1] = "i:" .. tostring(invSlot)
    end
    table.sort(keys)
    return table.concat(keys, ";")
end

local function NotifyProtectionChanged()
    if R.Fire then
        R.Fire("GEAR_SET_LOCK_CHANGED")
    end
    local fj = _G.FluxJunk
    if not (fj and fj.InvalidateJunkWorklist) then
        return
    end
    fj.InvalidateJunkWorklist()
end

local function ScanProtectedGearSetSlots(index, slotMax)
    -- Index already refreshed allocations on GEAR_SET_INDEX_CHANGED; skip duplicate
    -- full RefreshAllocations when bag/equip identity is unchanged.
    if index.RefreshAllocations then
        if not (index.AreAllocationsFresh and index.AreAllocationsFresh()) then
            index.RefreshAllocations()
        end
    end

    for invSlot = 1, slotMax do
        if index.IsInventorySlotAllocatedForGearSet and index.IsInventorySlotAllocatedForGearSet(invSlot) then
            protectedInvSlots[invSlot] = true
        end
    end

    if index.ForEachAllocatedBagSlot then
        index.ForEachAllocatedBagSlot(function(bag, slot)
            protectedSlots[SlotKey(bag, slot)] = true
            protectedCount = protectedCount + 1
        end)
    end
end

local function RebuildProtection()
    wipe(protectedSlots)
    wipe(protectedInvSlots)
    protectedCount = 0

    if not GearSetLock.IsEnabled() then
        if lastFingerprint ~= "0" then
            lastFingerprint = "0"
            NotifyProtectionChanged()
        end
        return
    end

    local index = R.GearSetIndex
    if not index or not index.IsBagSlotInSavedGearSet or not index.IsInventorySlotInSavedGearSet then
        return
    end

    if not R.Inv then
        return
    end

    local equip = R.Equipment
    local slotMax = (equip and equip.GetSlotMax and equip.GetSlotMax())
        or (R.Compat and R.Compat.EquipmentSlotMax and R.Compat.EquipmentSlotMax())
        or 19

    ScanProtectedGearSetSlots(index, slotMax)

    local fp = BuildFingerprint()
    if fp ~= lastFingerprint then
        lastFingerprint = fp
        NotifyProtectionChanged()
    end
end

function GearSetLock.Rebuild()
    local Perf = _G.Flux and _G.Flux.Perf
    if Perf then
        Perf.Begin("gearset.rebuild")
    end
    RebuildProtection()
    if Perf then
        Perf.Stop("gearset.rebuild")
    end
end

local function ScheduleRebuild(opts)
    opts = type(opts) == "table" and opts or nil
    local inv = R.Inv

    if rebuildTimer and rebuildTimer.Cancel then
        rebuildTimer:Cancel()
        rebuildTimer = nil
    end
    local delay = (opts and opts.delay) or REBUILD_DEBOUNCE_SEC
    if inv and inv.IsBankOpen and inv.IsBankOpen() then
        delay = math.max(delay, REBUILD_DEBOUNCE_BANK_OPEN_SEC)
    end
    if (inv and inv.IsMerchantOpen and inv.IsMerchantOpen())
        or (_G.MerchantFrame and _G.MerchantFrame.IsShown and _G.MerchantFrame:IsShown()) then
        delay = math.max(delay, REBUILD_DEBOUNCE_MERCHANT_SEC)
    end
    local scheduleNewTimer = _G.C_Timer and _G.C_Timer.NewTimer
    if scheduleNewTimer then
        rebuildTimer = scheduleNewTimer(delay, function()
            rebuildTimer = nil
            GearSetLock.Rebuild()
        end)
        return
    end
    local scheduleAfter = (_G.C_Timer and _G.C_Timer.After)
        or (_G.FLUX_API and _G.FLUX_API.After)
    if scheduleAfter then
        scheduleAfter(delay, function()
            GearSetLock.Rebuild()
        end)
        return
    end
    GearSetLock.Rebuild()
end

local function IsManualBlockContext()
    if contextSnapshotActive then
        return snapMerchantSell or snapDisenchant
    end
    return GearSetLock.IsMerchantSellContext() or GearSetLock.IsDisenchantContext()
end

local function BeginContextSnapshot()
    contextSnapshotActive = true
    snapMerchantSell = GearSetLock.IsMerchantSellContext()
    snapManualDE = GearSetLock.IsManualDisenchantTargeting()
    snapDisenchant = GearSetLock.IsDisenchantContext()
    if snapManualDE then
        snapGuardMode = "de"
    elseif snapMerchantSell then
        snapGuardMode = "vendor"
    else
        snapGuardMode = nil
    end
end

local function EndContextSnapshot()
    contextSnapshotActive = false
end

--- Run fn once with merchant/DE context snapshotted (avoids N API hits per button paint).
function GearSetLock.WithContextSnapshot(fn)
    if type(fn) ~= "function" then
        return
    end
    if contextSnapshotActive then
        return fn()
    end
    BeginContextSnapshot()
    local ok, a, b, c = pcall(fn)
    EndContextSnapshot()
    if not ok then
        error(a)
    end
    return a, b, c
end

local function CancelPendingRebuild()
    if rebuildTimer and rebuildTimer.Cancel then
        rebuildTimer:Cancel()
    end
    rebuildTimer = nil
end

local function RefreshManualBlockContext()
    BeginContextSnapshot()
    local ctx = IsManualBlockContext()
    local mode = ctx and (snapGuardMode or GearSetLock.GetManualClickGuardMode()) or nil
    if ctx == lastBlockContext and mode == lastGuardMode then
        EndContextSnapshot()
        return
    end
    lastBlockContext = ctx
    lastGuardMode = mode
    BumpClickGuardContext()
    local overlay = _G.FluxJunkOverlay
    if overlay and overlay.RefreshProtectionContext then
        pcall(overlay.RefreshProtectionContext)
    elseif overlay and overlay.RepaintSlotDecorators then
        -- Fallback only if light API missing.
        pcall(overlay.RepaintSlotDecorators)
    end
    EndContextSnapshot()
    local equipGuard = R.GearSetEquipGuard
    if equipGuard and equipGuard.RefreshAll then
        pcall(equipGuard.RefreshAll)
    end
    local bagCompat = _G.FluxBaganatorCompat
    if bagCompat then
        if bagCompat.RequestBaganatorProtectionRefresh then
            pcall(bagCompat.RequestBaganatorProtectionRefresh)
        elseif bagCompat.RefreshBaganatorGearSetProtection then
            pcall(bagCompat.RefreshBaganatorGearSetProtection)
        end
    end
end

function GearSetLock.ShouldShowManualInventoryClickGuard(invSlot)
    if not GearSetLock.IsInventorySlotProtected(invSlot) then
        return false
    end
    if contextSnapshotActive then
        return snapManualDE
    end
    return GearSetLock.IsManualDisenchantTargeting()
end

function GearSetLock.GetManualInventoryClickGuardMode()
    return "de"
end

function GearSetLock.ShouldShowManualClickGuard(bag, slot)
    if not GearSetLock.IsSlotProtected(bag, slot) then
        return false
    end
    if contextSnapshotActive then
        if snapManualDE or snapMerchantSell then
            return true
        end
        -- Salvage hover is slot-specific; still check live when snapshot has no merchant/DE.
        return GearSetLock.IsSalvageDisenchantHoverContext(bag, slot)
    end
    if GearSetLock.IsManualDisenchantTargeting() then
        return true
    end
    if GearSetLock.IsMerchantSellContext() then
        return true
    end
    if GearSetLock.IsSalvageDisenchantHoverContext(bag, slot) then
        return true
    end
    return false
end

function GearSetLock.ShouldShowShieldVisual(bag, slot)
    return GearSetLock.ShouldShowManualClickGuard(bag, slot)
end

function GearSetLock.GetManualClickGuardModeForSlot(bag, slot)
    if contextSnapshotActive then
        if snapManualDE then
            return "de"
        end
        if bag and slot and GearSetLock.IsSalvageDisenchantHoverContext(bag, slot) then
            return "de"
        end
        if snapMerchantSell then
            return "vendor"
        end
        return snapGuardMode
    end
    if GearSetLock.IsManualDisenchantTargeting() then
        return "de"
    end
    if bag and slot and GearSetLock.IsSalvageDisenchantHoverContext(bag, slot) then
        return "de"
    end
    if GearSetLock.IsMerchantSellContext() then
        return "vendor"
    end
end

function GearSetLock.GetManualClickGuardMode()
    return GearSetLock.GetManualClickGuardModeForSlot()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
-- No PLAYER_EQUIPMENT_CHANGED: equipment changes arrive on the shared inventory
-- pulse as the equip region, and a second handler doubled every rebuild.
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
eventFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
pcall(function()
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
end)
eventFrame:SetScript("OnEvent", function(_, event, unitTarget, castGUID, spellID)
    if event == "PLAYER_LOGIN" then
        ScheduleRebuild()
        local inv = R.Inv
        if inv and inv.Register and not GearSetLock._inventoryListenerRegistered then
            GearSetLock._inventoryListenerRegistered = true
            local function onInventoryMaybeGear(ctx)
                if ctx and ctx.force then
                    ScheduleRebuild({ delay = REBUILD_DEBOUNCE_BANK_OPEN_SEC })
                    return
                end
                local regions = ctx and ctx.regions
                if regions and (regions.equip or regions.equipped) then
                    ScheduleRebuild()
                    return
                end
                if regions and (regions.bags or regions.bank or regions.warband) then
                    ScheduleRebuild()
                    return
                end
                ScheduleRebuild()
            end
            inv.Register("FluxGearSetLock", onInventoryMaybeGear)
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        ScheduleRebuild()
    elseif event == "MERCHANT_SHOW" then
        RefreshManualBlockContext()
    elseif event == "MERCHANT_CLOSED" then
        CancelPendingRebuild()
        RefreshManualBlockContext()
    elseif event == "SPELL_UPDATE_USABLE" or event == "CURRENT_SPELL_CAST_CHANGED" then
        RefreshManualBlockContext()
    elseif event == "UNIT_SPELLCAST_SENT" then
        if unitTarget == "player" and IsDisenchantSpellID(spellID) then
            manualDisenchantPending = true
            RefreshManualBlockContext()
        end
    end
end)

local function RegisterSalvageModifierCallback()
    local salvage = _G.FluxSalvage
    if not salvage or not salvage.RegisterModifierCallback or salvage._fluxGearSetLockModifierHooked then
        return
    end
    salvage._fluxGearSetLockModifierHooked = true
    salvage.RegisterModifierCallback(function()
        RefreshManualBlockContext()
    end)
end

if C_Timer and C_Timer.After then
    C_Timer.After(0, RegisterSalvageModifierCallback)
else
    RegisterSalvageModifierCallback()
end

if R.On then
    R.On("GEAR_SET_INDEX_CHANGED", function()
        ScheduleRebuild()
    end)
end

