--[[
    ExtraButtonSystem/Shared/FluxEBSButtonRefresh.lua

    Per-button identity isolation + lag-free refresh for consumable ExtraButtons.
    Each module owns trackedItemID / kind; unrelated bag moves do not rebind.
]]

FluxEBSButtonRefresh = FluxEBSButtonRefresh or {}
local Refresh = FluxEBSButtonRefresh

local Bridge = function()
    return _G.FluxEBSConsumableBridge
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

--- Wire a consumable button module.
--- opts: {
---   module, btn, kind, charges?,
---   placeholderIcon, placeholderLabel,
---   kindFlag,           -- e.g. "IsBandageButton"
---   applyRightClick(btn, state),  -- after SetAction
---   showTooltipExtras(btn, tooltip),
---   shouldShow(),       -- optional visibility
---   listenerKey,
---   bindingName,        -- e.g. FLUXCOMBAT_BANDAGE (SetOverrideBindingClick + hotkey text)
---   middleClickDeleteConjured, -- food/water: middle-click destroys conjured stack
---   middleClickDelete,  -- HS/gem: middle-click destroys any owned stack
---   combatGridCoalesce, -- route ScheduleUpdate through FluxCombatManager (one batch for 6 buttons)
--- }
function Refresh.Attach(opts)
    if type(opts) ~= "table" or not opts.btn or not opts.module or not opts.kind then
        return
    end
    local Module = opts.module
    local btn = opts.btn
    local kind = opts.kind
    local charges = opts.charges == true
    local listenerKey = opts.listenerKey or ("EBS:" .. kind)
    local bindingName = opts.bindingName
    local wantsMiddleDelete = opts.middleClickDelete or opts.middleClickDeleteConjured
    btn._fluxMiddleDelete = opts.middleClickDelete and true or nil
    btn._fluxMiddleDeleteConjured = opts.middleClickDeleteConjured and true or nil

    if opts.kindFlag then
        btn[opts.kindFlag] = true
    end
    -- Prefer SetItemByID for non-isolated tooltips; isolated consumables use C_TooltipInfo.
    btn._fluxPreferItemByIdTooltip = true
    -- Food/water/pots/HS/gem/bandage: Blizzard + FluxUI lines only (no other-addon inject).
    btn._fluxIsolatedTooltip = true
    Module.Button = btn
    Module._kind = kind
    Module._trackedItemID = nil
    Module._pendingUpdate = false
    Module._debounceGen = 0
    Module._bindingName = bindingName

    local function AssertLocked()
        btn.ButtonLocked = true
        if btn.SetLocked then
            btn:SetLocked(true)
        end
        local w = btn.Widget
        if w and w.RegisterForDrag and not InCombat() then
            w:RegisterForDrag()
            w:SetScript("OnDragStart", nil)
            w:SetScript("OnReceiveDrag", nil)
            w:SetScript("OnDragStop", nil)
        end
    end

    local function BagsReliable()
        local inv = _G.FluxInv
        if inv and inv.Bags and inv.Bags.IsReliable then
            return inv.Bags.IsReliable()
        end
        local BestMod = _G.FluxConsumableBest
        if BestMod and BestMod.ShouldSoftHoldOwned then
            return not BestMod.ShouldSoftHoldOwned()
        end
        return inv and inv.Bags and inv.Bags.IsReady and inv.Bags.IsReady()
    end

    local function SoftHoldOwned()
        return not BagsReliable()
    end

    --- Commit real ownership into the display latch (item + last good count).
    local function CommitLatch(itemID, count)
        itemID = tonumber(itemID)
        count = tonumber(count) or 0
        if itemID and count > 0 then
            Module._latchItemID = itemID
            Module._latchCount = count
            btn._fluxLastCount = count
            Module._trackedItemID = itemID
        end
    end

    local function ClearLatch()
        Module._latchItemID = nil
        Module._latchCount = nil
    end

    local function ApplyCount(itemID, count, opts)
        opts = opts or {}
        count = tonumber(count) or 0
        if count > 0 then
            btn._fluxLastCount = count
        end
        if not btn.SetCount then
            return
        end
        local freeze = opts.freeze or SoftHoldOwned()
        if freeze and itemID then
            local held = count > 0 and count or (tonumber(btn._fluxLastCount) or tonumber(Module._latchCount) or 0)
            if held > 0 then
                btn:SetCount(held, nil)
                return
            end
        end
        -- Reliable path: snapshot count, avoid live API (portal 0 poison).
        btn:SetCount(count, nil)
    end

    local function ApplyRightClick()
        if type(opts.applyRightClick) == "function" then
            pcall(opts.applyRightClick, btn, {
                trackedItemID = Module._trackedItemID,
                kind = kind,
            })
        end
    end

    local function ApplyMiddleNoUse()
        if not wantsMiddleDelete then
            return
        end
        local B = Bridge()
        if B and B.ApplyMiddleClickNoUse then
            B.ApplyMiddleClickNoUse(btn)
        end
    end

    local function ApplyBinding()
        if not bindingName then
            return
        end
        local B = Bridge()
        if B and B.ApplyBinding then
            B.ApplyBinding(btn, bindingName)
        end
    end
    Module.UpdateKeybinding = ApplyBinding

    --- Prefer Module.UpdateKeybinding so modules that add a conjure RightButton
    --- bind (Healthstone / Mana Gem) are not wiped by the use-only ApplyBinding.
    local function RunKeybinding()
        if type(Module.UpdateKeybinding) == "function" then
            Module.UpdateKeybinding()
        else
            ApplyBinding()
        end
    end

    local function AfterSecureWrites()
        -- ClearAction / SetPlaceholder can wipe craft macrotext2 while the memo
        -- still matches; always re-evaluate craft RC after secure writes.
        if opts.reapplyCraftOnBag then
            btn._fluxCraftBindKey = nil
        end
        ApplyRightClick()
        ApplyMiddleNoUse()
        RunKeybinding()
        AssertLocked()
    end

    local function ShowPlaceholder()
        if not opts.placeholderIcon then
            return
        end
        if InCombat() then
            return
        end
        if btn.SetPlaceholder then
            btn:SetPlaceholder(opts.placeholderIcon, opts.placeholderLabel)
        elseif btn.WIcon then
            btn.PlaceholderTexture = opts.placeholderIcon
            btn.PlaceholderLabel = opts.placeholderLabel
            btn.WIcon:SetTexture(opts.placeholderIcon)
            btn.WIcon:SetDesaturated(true)
            btn.WIcon:SetVertexColor(0.25, 0.25, 0.25)
            btn.WIcon:Show()
        end
        AssertLocked()
        ApplyMiddleNoUse()
    end

    local function BindItem(itemID, count)
        if InCombat() then
            Module._pendingUpdate = true
            ApplyCount(Module._trackedItemID, count, { freeze = SoftHoldOwned() })
            return
        end
        itemID = tonumber(itemID)
        if itemID and (count or 0) > 0 then
            CommitLatch(itemID, count)
            btn.ItemId = itemID
            if btn.ClearPlaceholder then
                btn:ClearPlaceholder()
            end
            btn.PlaceholderTexture = nil
            btn.PlaceholderLabel = nil
            if btn.SetAction then
                btn:SetAction("item", itemID)
            end
            ApplyCount(itemID, count)
            if btn.FullRefresh then
                btn:FullRefresh()
            end
            AfterSecureWrites()
        else
            -- While unreliable, never clear a latched consumable.
            if SoftHoldOwned() and (Module._latchItemID or Module._trackedItemID) then
                local keepID = Module._latchItemID or Module._trackedItemID
                Module._trackedItemID = keepID
                btn.ItemId = keepID
                ApplyCount(keepID, Module._latchCount or btn._fluxLastCount or 1, { freeze = true })
                AfterSecureWrites()
                Module._pendingUpdate = true
                return
            end
            Module._trackedItemID = nil
            btn.ItemId = nil
            ClearLatch()
            ShowPlaceholder()
            ApplyCount(nil, 0)
            AfterSecureWrites()
        end
    end

    local function HoldLatchedDisplay()
        local keepID = Module._latchItemID or Module._trackedItemID
        if not keepID then
            return false
        end
        Module._trackedItemID = keepID
        btn.ItemId = keepID
        ApplyCount(keepID, Module._latchCount or btn._fluxLastCount or 1, { freeze = true })
        AfterSecureWrites()
        Module._pendingUpdate = true
        return true
    end

    local function RefreshCountOnly()
        local B = Bridge()
        local id = Module._trackedItemID or Module._latchItemID
        if not id then
            ApplyCount(nil, 0)
            return
        end
        if SoftHoldOwned() then
            HoldLatchedDisplay()
            return
        end
        local n = B and B.BagCount(id, { charges = charges }) or 0
        if n > 0 then
            CommitLatch(id, n)
            ApplyCount(id, n)
            return
        end
        -- Reliable + zero: allow a full Update to clear or promote.
        ApplyCount(id, 0)
        if not InCombat() then
            Module.Update(true)
        end
    end

    local function BestSettled()
        local BestMod = _G.FluxConsumableBest
        if BestMod and BestMod.IsSettled then
            return BestMod.IsSettled()
        end
        if BestMod and BestMod._pendingLoad and next(BestMod._pendingLoad) then
            return false
        end
        return true
    end

    local BEST_SETTLE_MAX_RETRIES = 10
    local bestSettleRetries = 0
    local wasUnreliable = false

    function Module.Update(force)
        if not _G.FluxInv then
            ShowPlaceholder()
            Module._trackedItemID = nil
            ClearLatch()
            return
        end
        if opts.shouldShow and not opts.shouldShow() then
            local EBV = _G.FluxExtraButtonVisibility
            if EBV and EBV.SetSlotShown then
                EBV.SetSlotShown(btn, false)
            elseif btn.SlotFrame then
                btn.SlotFrame:Hide()
            end
            -- Clear craft RC even when hiding (mats gone → no craft bind left sticky).
            if opts.reapplyCraftOnBag and not InCombat() then
                btn._fluxCraftBindKey = nil
                ApplyRightClick()
            end
            return
        end
        do
            local EBV = _G.FluxExtraButtonVisibility
            if EBV and EBV.SetSlotShown then
                EBV.SetSlotShown(btn, true)
            elseif btn.SlotFrame then
                btn.SlotFrame:Show()
            end
        end

        if InCombat() then
            Module._pendingUpdate = true
            RefreshCountOnly()
            return
        end

        local unreliable = SoftHoldOwned()
        -- Rising edge unreliable→reliable: force one commit from real bag counts.
        if wasUnreliable and not unreliable then
            force = true
        end
        wasUnreliable = unreliable

        -- While bags are unreliable: freeze latched identity; never promote/clear.
        if unreliable then
            local BestMod = _G.FluxConsumableBest
            local softKind = not BestMod or not BestMod.IsSoftHoldKind or BestMod.IsSoftHoldKind(kind)
            if softKind and HoldLatchedDisplay() then
                return
            end
        end

        -- Avoid committing a weak/empty identity while Best classify is pending.
        if not BestSettled() and not Module._trackedItemID and not Module._latchItemID then
            Module._pendingUpdate = true
            ShowPlaceholder()
            AfterSecureWrites()
            local B = Bridge()
            local after = B and B.After or function(_, fn) fn() end
            if B and B.GetBestOwned then
                local live = B.GetBestOwned(kind, { charges = charges })
                if live and live.itemID and (live.count or 0) > 0 then
                    BindItem(live.itemID, live.count)
                    Module._pendingUpdate = false
                    bestSettleRetries = 0
                    return
                end
            end
            bestSettleRetries = bestSettleRetries + 1
            if bestSettleRetries > BEST_SETTLE_MAX_RETRIES then
                -- Stop unbounded 0.1s retries (sticky FPS after teleport/login).
                Module._pendingUpdate = false
                return
            end
            local delay = 0.10 * math.min(bestSettleRetries, 5)
            after(delay, function()
                Module.Update(false)
            end)
            return
        end
        bestSettleRetries = 0

        local B = Bridge()
        if not B then
            return
        end
        local nextID, nextCount = B.PromoteIfBetter(kind, Module._trackedItemID or Module._latchItemID, { charges = charges })
        -- Only bind when bags confirm a real count.
        local realNext = 0
        if nextID and B.BagCount then
            realNext = B.BagCount(nextID, { charges = charges }) or 0
        end
        if nextID and realNext > 0 then
            nextCount = realNext
            local changed = force or nextID ~= Module._trackedItemID
            if changed then
                BindItem(nextID, nextCount)
            else
                CommitLatch(nextID, nextCount)
                ApplyCount(nextID, nextCount)
                AfterSecureWrites()
            end
            Module._pendingUpdate = false
            return
        end
        -- Reliable and empty: clear to placeholder.
        BindItem(nil, 0)
        Module._pendingUpdate = false
    end

    function Module.RefreshCountOnly()
        RefreshCountOnly()
    end

    local function ScheduleUpdate()
        if opts.combatGridCoalesce then
            local M = _G.FluxCombatManager
            if M and M.ScheduleAllUpdates then
                M:ScheduleAllUpdates(false)
                return
            end
        end
        Module._debounceGen = Module._debounceGen + 1
        local gen = Module._debounceGen
        local B = Bridge()
        local after = B and B.After or function(_, fn) fn() end
        -- Near-immediate: identity must settle on login/reload without multi-second lag.
        after(0.02, function()
            if gen ~= Module._debounceGen then
                return
            end
            Module.Update(false)
        end)
    end

    local BestMod = _G.FluxConsumableBest
    if BestMod and BestMod.RegisterListener then
        BestMod.RegisterListener(listenerKey, function()
            ScheduleUpdate()
        end)
    end

    local inv = _G.FluxInv
    if inv and inv.RegisterListener then
        local regions = opts.listenerRegions or { "bags" }
        inv.RegisterListener(listenerKey, function(ctx)
            if InCombat() then
                RefreshCountOnly()
                Module._pendingUpdate = true
                return
            end
            local regionsHit = ctx and ctx.regions
            if regionsHit and regionsHit.professions then
                -- Full Update → AfterSecureWrites rebinds craft RC; skip early craft
                -- refresh that would race ClearAction at after(0) vs Update at after(0.02).
                ScheduleUpdate()
                return
            end
            -- Craft buttons: bag mat changes must rebind RC craft vs restock promptly.
            if opts.reapplyCraftOnBag then
                ScheduleUpdate()
                return
            end
            -- Stack size only: refresh counts; still promote/demote if best identity moved.
            if ctx and ctx.changeKind == "countOnly" and not ctx.force then
                local B = Bridge()
                local id = Module._trackedItemID or Module._latchItemID
                if id and B and B.BagCount then
                    local n = B.BagCount(id, { charges = charges }) or 0
                    if n <= 0 then
                        ScheduleUpdate()
                        return
                    end
                    local best = B.GetBestOwned and B.GetBestOwned(kind, { charges = charges })
                    if best and best.itemID and best.itemID ~= id then
                        ScheduleUpdate()
                        return
                    end
                end
                RefreshCountOnly()
                return
            end
            local B = Bridge()
            if not B then
                ScheduleUpdate()
                return
            end
            local id = Module._trackedItemID or Module._latchItemID
            if id and (B.BagCount(id, { charges = charges }) or 0) > 0 then
                local best = B.GetBestOwned(kind, { charges = charges })
                if best and best.itemID == id then
                    RefreshCountOnly()
                    return
                end
            end
            ScheduleUpdate()
        end, { tier = "scan", regions = regions, deferHeavy = true })
    end

    local leave = CreateFrame("Frame")
    leave:RegisterEvent("PLAYER_REGEN_ENABLED")
    leave:RegisterEvent("UPDATE_BINDINGS")
    leave:RegisterEvent("PLAYER_ENTERING_WORLD")
    leave:SetScript("OnEvent", function(_, event, arg1, arg2)
        if event == "UPDATE_BINDINGS"
            and _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            return
        end
        if event == "UPDATE_BINDINGS" then
            if leave._bindRefreshPending then
                return
            end
            leave._bindRefreshPending = true
            C_Timer.After(0.15, function()
                leave._bindRefreshPending = false
                if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
                    and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
                    return
                end
                if InCombat() then
                    btn._pendingKeybindUpdate = true
                    return
                end
                RunKeybinding()
                AssertLocked()
                ApplyMiddleNoUse()
                ApplyRightClick()
            end)
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            RunKeybinding()
            AssertLocked()
            ApplyMiddleNoUse()
            ApplyRightClick()
            if not InCombat() then
                -- Login/reload: force rebind. Portal/zone: soft update + arm hold.
                local isLogin = (arg1 == true or arg2 == true)
                if not isLogin and not Module._fluxSeenPew then
                    isLogin = true
                end
                Module._fluxSeenPew = true
                if not isLogin then
                    local BestMod = _G.FluxConsumableBest
                    if BestMod and BestMod.ArmPortalSoftHold then
                        BestMod.ArmPortalSoftHold()
                    end
                end
                Module.Update(isLogin and true or false)
            end
            return
        end
        if Module._pendingUpdate then
            Module.Update(true)
        end
        if btn._pendingKeybindUpdate then
            RunKeybinding()
        end
        AssertLocked()
        ApplyMiddleNoUse()
    end)

    -- Middle-click destroy only (type3 is /stopmacro so item is not used).
    if wantsMiddleDelete then
        local w = btn.Widget
        if w then
            local function ClearChecked()
                local B = Bridge()
                if B and B.SuppressCheckedVisual then
                    B.SuppressCheckedVisual(btn)
                end
            end
            w:HookScript("OnMouseDown", function(_, button)
                if button == "MiddleButton" then
                    ClearChecked()
                    -- Snapshot ownership for this click. Recuperate toggle rebinds on down
                    -- before up; without this, up would delete the newly shown conjured stack.
                    btn._fluxMiddleDownRecupMode = btn._fluxRecuperateClickMode
                    btn._fluxMiddleDownRestockMode = btn._fluxRestockEditClickMode
                    btn._fluxMiddleDownShift = IsShiftKeyDown and IsShiftKeyDown() or false
                end
            end)
            w:HookScript("OnMouseUp", function(_, button)
                if button ~= "MiddleButton" then
                    return
                end
                ClearChecked()
                local recupMode = btn._fluxMiddleDownRecupMode or btn._fluxRecuperateClickMode
                local mode = btn._fluxMiddleDownRestockMode or btn._fluxRestockEditClickMode
                local shiftDown = btn._fluxMiddleDownShift
                if shiftDown == nil and IsShiftKeyDown then
                    shiftDown = IsShiftKeyDown()
                end
                btn._fluxMiddleDownRecupMode = nil
                btn._fluxMiddleDownRestockMode = nil
                btn._fluxMiddleDownShift = nil

                if btn._fluxSkipNextMiddleDelete then
                    btn._fluxSkipNextMiddleDelete = nil
                    return
                end
                -- Restock edit owns this middle-click (or Shift+middle).
                if mode == "middle" then
                    return
                end
                if mode == "shift-middle" and shiftDown then
                    return
                end
                -- Recuperate toggle owns middle (or Shift+middle when conjured food is shown).
                if recupMode == "middle" then
                    return
                end
                if recupMode == "shift-middle" and shiftDown then
                    return
                end
                local id = Module._trackedItemID or btn.ItemId
                local B = Bridge()
                if not B then
                    return
                end
                if opts.middleClickDeleteConjured then
                    B.DeleteOneConjuredOwned(id)
                else
                    B.DeleteOneOwned(id)
                end
                ClearChecked()
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, ClearChecked)
                    C_Timer.After(0.05, ClearChecked)
                end
            end)
            w:HookScript("OnClick", function(_, button)
                if button == "MiddleButton" then
                    ClearChecked()
                end
            end)
        end
    end

    if type(opts.showTooltipExtras) == "function" and btn.ShowTooltip then
        local orig = btn.ShowTooltip
        btn.ShowTooltip = function(self)
            orig(self)
            local tip = self._fluxActiveTooltip or GameTooltip
            if tip then
                local Bridge = _G.FluxEBSConsumableBridge
                if Bridge and Bridge.ResetFluxTooltipGap then
                    Bridge.ResetFluxTooltipGap(tip)
                else
                    tip._fluxEbsGapDone = nil
                end
                pcall(opts.showTooltipExtras, self, tip)
                if FluxSafeGameTooltipShow then
                    FluxSafeGameTooltipShow(tip)
                else
                    tip:Show()
                end
            end
        end
    end

    if bindingName and btn.Widget then
        local BM = _G.FluxBindingMode
        if BM and BM.RegisterButton then
            pcall(BM.RegisterButton, BM, btn.Widget, bindingName)
        end
    end

    AssertLocked()
    ApplyMiddleNoUse()
    ApplyBinding()
    -- Placeholder then bind immediately so login/reload is never blank or multi-second late.
    ShowPlaceholder()
    AfterSecureWrites()
    Module.Update(true)

    local B = Bridge()
    local after = B and B.After or function(_, fn) fn() end
    local function ForceBestThenUpdate(force)
        local BestMod = _G.FluxConsumableBest
        -- Never force+immediate sync recompute on timer ticks (portal lag). Debounce only.
        if BestMod and BestMod.IsSettled and not BestMod.IsSettled() and BestMod.RequestRecompute then
            BestMod.RequestRecompute({ reason = "buttonLogin", delay = 0.2 })
        end
        Module.Update(force)
        AfterSecureWrites()
    end
    -- Short recovery: item data / Best may arrive a frame or two later.
    -- Extra ~2s pass covers late spell/item streams after login/reload.
    after(0.12, function()
        ForceBestThenUpdate(false)
    end)
    after(0.45, function()
        ForceBestThenUpdate(true)
    end)
    after(2.0, function()
        ForceBestThenUpdate(true)
    end)

    return Module
end

_G.FluxEBSButtonRefresh = Refresh
return Refresh
