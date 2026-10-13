--[[
  FluxPerfDebug — lightweight performance diagnostics for _FluxUI.

  Slash: /fluxperf [report|reset|probe|combat|regen|spells|help]

  Passive-lag baseline (do this before/after perf changes):
    1. /console scriptProfile 1
    2. /reload
    3. Stand idle ~30s with a target (open world)
    4. /fluxperf report
    5. /script print(GetAddOnCPUUsage("_FluxUI"))
    6. Repeat in a party/raid with Flux raid frames enabled

  Macro/usable churn: /fmacrolag report
  Login hitch: /fluxinvdebug on → /fluxinvdebug watch 30 → /reload → /fluxperf spells|combat

  Note: does NOT hook C_Timer.NewTicker (global hooks break other addons and
    ticker.Cancel is read-only on retail).
]]

local PREFIX = "|cff00ccffFluxPerf|r"

FluxPerfDebug = FluxPerfDebug or {}
local P = FluxPerfDebug

local function countTable(t)
    local n = 0
    if t then
        for _ in pairs(t) do
            n = n + 1
        end
    end
    return n
end

local function frameHasOnUpdate(f)
    if not (f and f.GetScript and f:GetScript("OnUpdate") ~= nil) then
        return false
    end
    -- Hidden frames do not receive OnUpdate; only count live cost.
    if f.IsVisible and not f:IsVisible() then
        return false
    end
    return true
end

local function countLabMouseoverMacroButtons()
    local lib = LibStub and LibStub("LibActionButton-1.0", true)
    if not lib or not lib.fluxMouseoverMacroButtons then
        return 0
    end
    return countTable(lib.fluxMouseoverMacroButtons)
end

local function countExtraMouseoverMacroButtons()
    if FluxButtonEvents and FluxButtonEvents.mouseoverMacroButtons then
        return countTable(FluxButtonEvents.mouseoverMacroButtons)
    end
    return 0
end

local function countLabRangeButtons()
    local lib = LibStub and LibStub("LibActionButton-1.0", true)
    if not lib or not lib.rangeButtons then
        return 0, 0
    end
    return countTable(lib.rangeButtons), countTable(lib.fluxVFXButtons)
end

local function countExtraRangeButtons()
    if FluxButtonEvents and FluxButtonEvents.rangeButtons then
        return countTable(FluxButtonEvents.rangeButtons)
    end
    return 0
end

--- Best-effort count of known _FluxUI-owned tickers (no global C_Timer hook).
local function countKnownFluxTickers()
    local n = 0
    local names = {}
    local function note(label, ticker)
        if ticker then
            n = n + 1
            names[#names + 1] = label
        end
    end
    if FluxMinimap and FluxMinimap._enforcerTicker then
        note("Minimap.enforcer", FluxMinimap._enforcerTicker)
    end
    if FluxMinimap and FluxMinimap._clockTicker then
        note("Minimap.clock", FluxMinimap._clockTicker)
    end
    local vfx = _G.FluxButtonVFX or (FluxButtonEngine and FluxButtonEngine.VFX)
    if vfx and vfx.castingUpdateTicker then
        note("VFX.cast", vfx.castingUpdateTicker)
    end
    if FluxCombatManager and FluxCombatManager._combatRefreshTicker then
        note("CombatGrid.refresh", FluxCombatManager._combatRefreshTicker)
    end
    if _G.FluxRaidExtrasTicker then
        note("RaidFrame.extras", _G.FluxRaidExtrasTicker)
    end
    if _G.FluxEBSRangeTicker then
        note("EBS.range", _G.FluxEBSRangeTicker)
    end
    if _G.FluxLABRangeTicker then
        note("LAB.range", _G.FluxLABRangeTicker)
    end
    if _G.FluxUFAuraDurationTicker then
        note("UF.auraDuration", _G.FluxUFAuraDurationTicker)
    end
    local Best = _G.FluxConsumableBest
    if Best and Best._classifyResumeTicker then
        note("Best.classifyResume", Best._classifyResumeTicker)
    end
    if _G.FMacLag and _G.FMacLag.autoTicker then
        note("FMacLag", _G.FMacLag.autoTicker)
    end
    return n, names
end

local function reportOnUpdateSources()
    local rows = {}
    local function add(name, frame)
        if frameHasOnUpdate(frame) then
            rows[#rows + 1] = name
        end
    end

    local lab = LibStub and LibStub("LibActionButton-1.0", true)
    if lab and lab.eventFrame then
        if frameHasOnUpdate(lab.eventFrame) then
            rows[#rows + 1] = "LibActionButton.eventFrame"
        end
        -- Armed flag is diagnostic only — do not count as an OnUpdate source.
        rows[#rows + 1] = "LAB.onUpdateArmed=" .. tostring(lab._fluxOnUpdateArmed == true)
    end

    if UF_UnitFramePollFrame then
        add("UF_UnitFramePollFrame", UF_UnitFramePollFrame)
    end

    -- Flux perf T2.7: should be Hidden when GetPVPTimer()==0 (idle city).
    if FluxUI_PlayerPvpTimerDriver then
        add("UF_PlayerPvpTimerDriver", FluxUI_PlayerPvpTimerDriver)
    end

    if FluxButtonEvents and FluxButtonEvents.EventFrames and FluxButtonEvents.EventFrames.Full then
        add("ExtraButtonEngine.Full", FluxButtonEvents.EventFrames.Full)
    end

    if FluxRaid_MTMAPollFrame then
        add("FluxRaid_MTMAPollFrame", FluxRaid_MTMAPollFrame)
    end

    if FluxRaid_RangePollFrame then
        add("FluxRaid_RangePollFrame", FluxRaid_RangePollFrame)
    end

    if _G.FluxPostDFCastTickerFrame then
        add("PostDF.castTicker", _G.FluxPostDFCastTickerFrame)
    end
    if _G.FluxPostDFReticleWatcherFrame then
        add("PostDF.reticleWatcher", _G.FluxPostDFReticleWatcherFrame)
    end
    if _G.FluxPreDFCastTickerFrame then
        add("PreDF.castTicker", _G.FluxPreDFCastTickerFrame)
    end
    if _G.FluxPreDFReticleWatcherFrame then
        add("PreDF.reticleWatcher", _G.FluxPreDFReticleWatcherFrame)
    end
    if _G.FluxCooldownFontWatcherFrame then
        add("Effects.cooldownFontWatcher", _G.FluxCooldownFontWatcherFrame)
    end
    if _G.FluxEBSCooldownSqueezeDriver then
        add("EBS.cooldownSqueeze", _G.FluxEBSCooldownSqueezeDriver)
    end
    if _G.FluxEBSSingleButtonAssistantDriver then
        add("EBS.singleButtonAssistant", _G.FluxEBSSingleButtonAssistantDriver)
    end

    return rows
end

local function getRaidRangePollStats()
    if FluxRaid_GetRangePollStats then
        return FluxRaid_GetRangePollStats()
    end
    return { count = 0, interval = 0.2, frameActive = false }
end

local function getMTMAPollStats()
    if FluxRaid_GetMTMAPollStats then
        return FluxRaid_GetMTMAPollStats()
    end
    return { count = 0 }
end

local function getUnitFramePollStats()
    if FluxUI_GetUnitFramePollStats then
        return FluxUI_GetUnitFramePollStats()
    end
    return { healthUnits = 0, threatUnits = 0, active = false }
end

local function getExtraButtonFullOnUpdateArmed()
    if not FluxButtonEvents or not FluxButtonEvents.EventFrames then
        return false, nil
    end
    local full = FluxButtonEvents.EventFrames.Full
    if not full then
        return false, nil
    end
    local armed = frameHasOnUpdate(full)
    local flags = {}
    if armed then
        if full.RefreshButtons then flags[#flags + 1] = "RefreshButtons" end
        if full.RefChecked then flags[#flags + 1] = "RefChecked" end
        if full.RefEquipped then flags[#flags + 1] = "RefEquipped" end
        if full.RefUsable then flags[#flags + 1] = "RefUsable" end
        if full.RefCooldown then flags[#flags + 1] = "RefCooldown" end
        if full.RefText then flags[#flags + 1] = "RefText" end
        if full.RefConditional then flags[#flags + 1] = "RefConditional" end
        if full.RefSpells then flags[#flags + 1] = "RefSpells" end
    end
    return armed, table.concat(flags, ",")
end

local function macroLagDebugActive()
    return _G.FMacLag and _G.FMacLag.enabled == true
end

function P.ResetStats()
    if FluxMouseoverRefresh and FluxMouseoverRefresh.ResetStats then
        FluxMouseoverRefresh.ResetStats()
    end
    local Bus = _G.FluxActionBarRefreshBus
    if Bus and Bus.ResetStats then
        Bus.ResetStats()
    end
    if _G.FluxPagingCoordinator and _G.FluxPagingCoordinator.ResetStats then
        _G.FluxPagingCoordinator.ResetStats()
    end
    _G.FluxBindingApplyCoalesceHits = 0
    _G.FluxBindingTailSkipCount = 0
    if _G.FMacLag then
        _G.FMacLag.columnDragDropApplies = 0
        _G.FMacLag.columnDragDropEscalations = 0
        _G.FMacLag.lastApplyAllMs = nil
        _G.FMacLag.applyAllCount = 0
    end
    local lib = LibStub and LibStub("LibActionButton-1.0", true)
    if lib then
        lib._fluxRangePollCount = 0
        lib._fluxDbgSkippedBroadcast = 0
        lib._fluxDbgBroadcastUsable = 0
    end
    _G.FluxPerfModifierEvents = 0
    _G.FluxPerfModifierCoalesced = 0
    _G.FluxPerfSettleSkips = 0
    _G.FluxPerfRangePagingSkips = 0
    _G.FluxNCRegenRelayoutFull = 0
    _G.FluxNCRegenRelayoutLite = 0
    _G.FluxNCRegenRelayoutSkipped = 0
    _G.FluxNCRegenRelayoutInit = 0
    _G.FluxNCRegenDeferLight = 0
    _G.FluxNCRegenDeferHeavy = 0
    if _G.Flux and _G.Flux.Perf and _G.Flux.Perf.Regen and _G.Flux.Perf.Regen.Reset then
        _G.Flux.Perf.Regen.Reset()
    end
    _G.FluxPerfRaidExtrasTicks = 0
    _G.FluxPerfRaidExtrasApplies = 0
    _G.FluxPerfRaidExtrasAppliesEvent = 0
    _G.FluxPerfRaidExtrasAppliesTicker = 0
    _G.FluxPerfRaidExtrasAppliesMTMA = 0
    _G.FluxPerfRaidMTMAUpdates = 0
    _G.FluxPerfEBSBatchBudgetHits = 0
    _G.FluxPerfEBSCooldownSqueezeCount = 0
    print(PREFIX, "Coalescer counters reset.")
end

local function printReport()
    print(PREFIX, "— performance snapshot —")

    if UpdateAddOnCPUUsage then UpdateAddOnCPUUsage() end
    local cpu = GetAddOnCPUUsage and GetAddOnCPUUsage("_FluxUI")
    if cpu then
        print(PREFIX, string.format("GetAddOnCPUUsage(_FluxUI): %.2f ms (enable scriptProfile for meaningful values)", cpu))
    end

    local fps = GetFramerate and GetFramerate()
    if fps then
        print(PREFIX, string.format("FPS: %.1f", fps))
    end

    local rangeN, vfxN = countLabRangeButtons()
    print(PREFIX, string.format("LAB rangeButtons: %d  fluxVFXButtons: %d  mouseoverMacroButtons: %d",
        rangeN, vfxN, countLabMouseoverMacroButtons()))
    local ebActive = (FluxButtonEvents and FluxButtonEvents.ActiveButtons and #FluxButtonEvents.ActiveButtons) or 0
    local ebContent = 0
    if FluxButtonEvents and FluxButtonEvents.ActiveButtons then
        local list = FluxButtonEvents.ActiveButtons
        for i = 1, #list do
            local b = list[i]
            if b and b.ActionType and b.ActionValue then
                ebContent = ebContent + 1
            elseif b and b._fluxBadgeIconLeg and type(b._fluxSyncedActionSlot) == "number" and b._fluxSyncedActionSlot >= 1 then
                ebContent = ebContent + 1
            end
        end
    end
    print(PREFIX, string.format("ExtraButton rangeButtons: %d  mouseoverMacroButtons: %d  ActiveButtons: %d (content=%d)",
        countExtraRangeButtons(),
        countExtraMouseoverMacroButtons(),
        ebActive, ebContent))
    local coreN = (FluxButtonCore and FluxButtonCore.ActiveButtons and #FluxButtonCore.ActiveButtons)
        or (FluxButtonCore and FluxButtonCore.GetActiveButtons and #(FluxButtonCore.GetActiveButtons() or {}))
        or 0
    if coreN > 0 and coreN ~= ebActive then
        print(PREFIX, string.format("ExtraButton Core.ActiveButtons: %d (Events=%d) — glow/cast sweeps may walk empties",
            coreN, ebActive))
    end
    print(PREFIX, string.format(
        "ASC occupancy peek skips (Binding+BadgeHost+shared): %d",
        _G.FluxBindingTailSkipCount or 0))

    if FluxMouseoverRefresh and FluxMouseoverRefresh.GetStats then
        local st = FluxMouseoverRefresh.GetStats()
        print(PREFIX, string.format(
            "Mouseover coalescer: hasMacros=%s  interval=%.3fs  flushes=%d  coalesced=%d  skippedSameUnit=%d  skippedNoMacros=%d  requests=%d",
            tostring(FluxMouseoverRefresh.hasMouseoverMacros),
            (FluxMouseoverRefresh.GetInterval and FluxMouseoverRefresh.GetInterval()) or 0.07,
            st.flushes or 0, st.coalesced or 0, st.skippedSameUnit or 0, st.skippedNoMacros or 0, st.requests or 0))
    end

    local PC = _G.FluxPagingCoordinator
    if PC and PC.GetStats then
        local ps = PC.GetStats()
        print(PREFIX, string.format(
            "PagingCoordinator: notify=%d settle=%d cancel=%d oor=%d idForce=%d idSoft=%d dirty=%d paint=%d",
            ps.notify or 0, ps.settle or 0, ps.cancel or 0, ps.oorSamples or 0,
            ps.identityForce or 0, ps.identitySoft or 0, ps.dirtyCols or 0, ps.paintTransfers or 0))
        print(PREFIX, string.format(
            "Paging overlay: count=%d  narrowed=%d  emptySkip=%d  staleClears=%d  condition=%d",
            ps.conditionOverlay or 0,
            ps.overlayNarrowed or 0,
            ps.overlayEmptySkip or 0,
            ps.staleLatchClears or 0,
            ps.conditionOverlay or 0))
    end
    do
        local latch = _G._fluxPagingInProgress
        local mods = ((IsShiftKeyDown and IsShiftKeyDown()) and "S" or "")
            .. ((IsControlKeyDown and IsControlKeyDown()) and "C" or "")
        local age = ""
        if type(latch) == "number" and GetTime then
            age = string.format("  age=%.2fs", GetTime() - latch)
        end
        print(PREFIX, string.format(
            "Paging latch: %s%s  mods=%s  (idle expect clear)",
            latch and ("set@" .. tostring(latch)) or "clear",
            age,
            mods ~= "" and mods or "-"))
    end

    local Bus = _G.FluxActionBarRefreshBus
    if Bus and Bus.GetStats then
        local bst = Bus.GetStats()
        local tierRuns = bst.tierRuns or {}
        print(PREFIX, string.format(
            "RefreshBus flushes=%d  eval_flip=%d  paging=%d  cheap=%d  macro_slot=%d",
            bst.flushes or 0,
            tierRuns.eval_flip or 0,
            tierRuns.paging or 0,
            tierRuns.cheap or 0,
            tierRuns.macro_slot or 0))
    end

    local lib = LibStub and LibStub("LibActionButton-1.0", true)
    if lib then
        print(PREFIX, string.format(
            "LAB rangePolls=%d  skippedBroadcastUsable=%d  broadcastUsable=%d",
            lib._fluxRangePollCount or 0,
            lib._fluxDbgSkippedBroadcast or 0,
            lib._fluxDbgBroadcastUsable or 0))
    end

    local bindInfo = _G.FluxBinding and _G.FluxBinding.GetActiveWorkInfo and _G.FluxBinding.GetActiveWorkInfo()
    if bindInfo then
        print(PREFIX, string.format(
            "Binding applyCoalesceHits=%d  tailSkipHits=%d  hasContextNeed=%s",
            _G.FluxBindingApplyCoalesceHits or 0,
            _G.FluxBindingTailSkipCount or 0,
            tostring(_G.FluxHasMouseoverContextNeed)))
        print(PREFIX, string.format(
            "Binding activeWork=%s  appliedLive=%s  dbBindings=%d  lastApply slots=%d badges=%d free=%d",
            tostring(bindInfo.active),
            tostring(bindInfo.appliedLive),
            bindInfo.bindingCount or 0,
            bindInfo.lastSlots or 0,
            bindInfo.lastBadges or 0,
            bindInfo.lastFree or 0))
        if bindInfo.active and (bindInfo.bindingCount or 0) > 0 then
            print(PREFIX, "|cffffcc00Note:|r Binding idle gate is open because FluxBindingDB3 has",
                bindInfo.bindingCount, "binding(s). Empty editor ≠ empty DB — check /fluxbind.")
        elseif bindInfo.active and bindInfo.appliedLive then
            print(PREFIX, "|cffffcc00Note:|r Binding appliedLive residual (clearing secure state).")
        end
    else
        print(PREFIX, string.format(
            "Binding applyCoalesceHits=%d  tailSkipHits=%d  hasContextNeed=%s  hasActiveWork=%s",
            _G.FluxBindingApplyCoalesceHits or 0,
            _G.FluxBindingTailSkipCount or 0,
            tostring(_G.FluxHasMouseoverContextNeed),
            tostring(_G.FluxBinding and _G.FluxBinding.HasActiveWork and _G.FluxBinding.HasActiveWork())))
    end

    local function fmtArmed(fn)
        if type(fn) ~= "function" then
            return "missing"
        end
        return tostring(fn())
    end
    print(PREFIX, string.format(
        "PostDF load=%s  castTickerArmed=%s  reticleWatcherArmed=%s",
        tostring(_G.FluxPostDFLoadStatus or "missing"),
        fmtArmed(_G.FluxPostDFIsCastTickerArmed),
        fmtArmed(_G.FluxPostDFIsReticleWatcherArmed)))
    print(PREFIX, string.format(
        "PreDF load=%s  castTickerArmed=%s  reticleWatcherArmed=%s",
        tostring(_G.FluxPreDFLoadStatus or "missing"),
        fmtArmed(_G.FluxPreDFIsCastTickerArmed),
        fmtArmed(_G.FluxPreDFIsReticleWatcherArmed)))

    print(PREFIX, string.format(
        "NC regen relayout: full=%d  lite=%d  skipped=%d  init=%d",
        _G.FluxNCRegenRelayoutFull or 0,
        _G.FluxNCRegenRelayoutLite or 0,
        _G.FluxNCRegenRelayoutSkipped or 0,
        _G.FluxNCRegenRelayoutInit or 0))

    print(PREFIX, string.format(
        "NC regen defer: light=%d  heavy=%d",
        _G.FluxNCRegenDeferLight or 0,
        _G.FluxNCRegenDeferHeavy or 0))

    if _G.FMacLag then
        print(PREFIX, string.format(
            "Column drag/drop apply=%d  escalations=%d",
            _G.FMacLag.columnDragDropApplies or 0,
            _G.FMacLag.columnDragDropEscalations or 0))
        if _G.FMacLag.lastApplyAllMs then
            print(PREFIX, string.format(
                "Last ApplyAll: %.2f ms  (total runs=%d)",
                _G.FMacLag.lastApplyAllMs,
                _G.FMacLag.applyAllCount or 0))
        end
    end

    local EC = _G.FluxActionBarEvalCache
    if EC and EC.DebugStats then
        local hits, misses = EC.DebugStats()
        if hits ~= nil or misses ~= nil then
            print(PREFIX, string.format(
                "EvalCache hits=%s  misses=%s",
                tostring(hits or 0),
                tostring(misses or 0)))
        end
    end

    print(PREFIX, string.format(
        "Modifier paging: events=%d  coalesced=%d  settleSkips=%d  rangeSkips=%d",
        _G.FluxPerfModifierEvents or 0,
        _G.FluxPerfModifierCoalesced or 0,
        _G.FluxPerfSettleSkips or 0,
        _G.FluxPerfRangePagingSkips or 0))
    print(PREFIX, string.format(
        "Paging tunables: FluxPagingCoalesceMs=%s  FluxModifierCoalesceMs=%s",
        tostring(_G.FluxPagingCoalesceMs or "100 (default)"),
        tostring(_G.FluxModifierCoalesceMs or "30 (default)")))

    local cleu = _G.FluxSwingTimer_IsCleuRegistered and _G.FluxSwingTimer_IsCleuRegistered()
    print(PREFIX, string.format("SwingTimer CLEU registered: %s", cleu and "yes" or "no"))

    local tickerN, tickerNames = countKnownFluxTickers()
    print(PREFIX, string.format("Known FluxUI tickers active: %d", tickerN))
    for _, name in ipairs(tickerNames) do
        print(PREFIX, "  •", name)
    end
    if FluxMinimap and FluxMinimap.GetEnforcerBurstRemaining then
        local rem = FluxMinimap.GetEnforcerBurstRemaining()
        if rem and rem > 0 then
            print(PREFIX, string.format("Minimap enforcer burst remaining: %.1fs", rem))
        end
    end

    local raidRange = getRaidRangePollStats()
    print(PREFIX, string.format(
        "Raid range poll: %d buttons  interval=%.2fs  shared frame=%s",
        raidRange.count or 0,
        raidRange.interval or 0.2,
        (raidRange.frameActive and "active") or "idle"))

    local mtma = getMTMAPollStats()
    print(PREFIX, string.format("MT/MA poll targets: %d", mtma.count or 0))
    print(PREFIX, string.format(
        "Raid extras: ticks=%d  applies=%d (event=%d ticker=%d mtma=%d)  MTMA updates=%d  ticker=%s",
        _G.FluxPerfRaidExtrasTicks or 0,
        _G.FluxPerfRaidExtrasApplies or 0,
        _G.FluxPerfRaidExtrasAppliesEvent or 0,
        _G.FluxPerfRaidExtrasAppliesTicker or 0,
        _G.FluxPerfRaidExtrasAppliesMTMA or 0,
        _G.FluxPerfRaidMTMAUpdates or 0,
        _G.FluxRaidExtrasTicker and "active" or "idle"))

    print(PREFIX, string.format(
        "EBS Flash armed=%s  CD squeeze armed=%s count=%d  batchBudgetHits=%d",
        tostring(_G.FluxPerfEBSFlashArmed == true),
        tostring(_G.FluxPerfEBSCooldownSqueezeArmed == true),
        _G.FluxPerfEBSCooldownSqueezeCount or 0,
        _G.FluxPerfEBSBatchBudgetHits or 0))
    print(PREFIX, string.format(
        "MP5 driver armed=%s (idle expect false)",
        tostring(_G.FluxPerfMP5Armed == true)))

    local ufPoll = getUnitFramePollStats()
    print(PREFIX, string.format(
        "UF poll frame: active=%s  healthUnits=%d  threatUnits=%d  threatArmed=%s",
        tostring(ufPoll.active),
        ufPoll.healthUnits or 0,
        ufPoll.threatUnits or 0,
        tostring(ufPoll.threatArmed)))
    if FluxUI_PlayerPvpTimerDriver then
        print(PREFIX, string.format(
            "UF PvP timer driver shown: %s (idle city expect false)",
            tostring(FluxUI_PlayerPvpTimerDriver:IsShown())))
    end
    if not ufPoll.active then
        print(PREFIX, "UF idle: shared poll Hidden (expected with no ToT/threat units)")
    end

    print(PREFIX, string.format(
        "StatusBar layout: runs=%d  skipped=%d  goldSkip=%d  expSkip=%d  repSkip=%d",
        _G.FluxPerfStatusBarLayoutRuns or 0,
        _G.FluxPerfStatusBarLayoutSkipped or 0,
        _G.FluxPerfStatusBarGoldSkipped or 0,
        _G.FluxPerfStatusBarExpSkipped or 0,
        _G.FluxPerfStatusBarRepSkipped or 0))
    print(PREFIX, string.format(
        "Stance: layout=%d  skipped=%d  formVis=%d  extrasVis=%d  rediscover=%d  dedupHits=%d",
        _G.FluxPerfStanceLayoutRuns or 0,
        _G.FluxPerfStanceLayoutSkipped or 0,
        _G.FluxPerfStanceFormUpdates or 0,
        _G.FluxPerfStanceVisualOnly or 0,
        _G.FluxPerfStanceExtrasRediscover or 0,
        _G.FluxPerfStanceDedupCacheHits or 0))
    local isRetailCSC = type(WOW_PROJECT_ID) == "number"
        and type(WOW_PROJECT_MAINLINE) == "number"
        and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
    print(PREFIX, string.format(
        "CSC retail gate: retail=%s  skippedPanel=%s (retail expect true)",
        tostring(isRetailCSC),
        tostring(_G.FluxCSC_RetailPanelSkipped == true)))

    local extraArmed, extraFlags = getExtraButtonFullOnUpdateArmed()
    print(PREFIX, string.format(
        "ExtraButton Full OnUpdate armed: %s%s",
        tostring(extraArmed),
        (extraArmed and extraFlags ~= "" and ("  flags=" .. extraFlags)) or ""))

    local InvDbg = _G.FluxInvDebug
    if InvDbg and InvDbg.GetSummary then
        local s = InvDbg.GetSummary()
        print(PREFIX, string.format(
            "FluxInv: dispatches=%d  max=%.2fms  avg=%.2fms  top=%s (%.2fms)  bagEvents=%d  postClose=%d — see /fluxinvdebug report",
            s.dispatches or 0,
            s.maxDispatchMs or 0,
            s.avgDispatchMs or 0,
            tostring(s.topListener or "-"),
            s.topListenerMs or 0,
            s.bagEvents or 0,
            s.postCloseDispatches or 0))
    end

    local Spells = _G.FluxInv and _G.FluxInv.Spells
    if Spells and Spells.GetDebugStats then
        local ss = Spells.GetDebugStats()
        print(PREFIX, string.format(
            "Spells: dirty=%s  warm=%s  reagentsWarm=%s  pending=%d  rebuilds=%d  lastCore=%.2fms (spells=%d tips=%d)  create=%d",
            tostring(ss.dirty),
            tostring(ss.warmDone),
            tostring(ss.reagentsWarmDone),
            ss.reagentPending or 0,
            ss.coreRebuilds or 0,
            ss.lastCoreMs or 0,
            ss.lastCoreSpells or 0,
            ss.lastCoreTooltips or 0,
            ss.createCount or 0))
    end

    local CM = _G.FluxCombatManager
    if CM and CM.GetDebugStats then
        local cs = CM:GetDebugStats()
        print(PREFIX, string.format(
            "CombatGrid: coalesced=%d  pendingBatch=%s  ticker=%s  bestPending=%d  classifyQ=%d  settled=%s  modulesPending=%d  init=%s",
            cs.coalescedUpdates or 0,
            tostring(cs.moduleUpdatePending),
            tostring(cs.combatTicker),
            cs.bestPendingLoad or 0,
            cs.bestClassifyQueue or 0,
            tostring(cs.bestSettled),
            cs.modulesPendingUpdate or 0,
            tostring(cs.buttonsInitialized)))
    end

    if macroLagDebugActive() then
        print(PREFIX, "|cffff0000WARNING|r: /fmacrolag debug hooks WorldFrame OnUpdate — disable before profiling.")
    end

    local onUpdates = reportOnUpdateSources()
    local realOnUpdates = 0
    for _, name in ipairs(onUpdates) do
        if not tostring(name):find("^LAB%.onUpdateArmed=", 1) then
            realOnUpdates = realOnUpdates + 1
        end
    end
    print(PREFIX, string.format("Known OnUpdate sources active: %d", realOnUpdates))
    for _, name in ipairs(onUpdates) do
        print(PREFIX, "  •", name)
    end
    if _G.FluxMouseoverCast and _G.FluxMouseoverCast.GetDriverStats then
        local st = _G.FluxMouseoverCast.GetDriverStats()
        print(PREFIX, string.format(
            "MouseoverCast state drivers: enabled=%s  live=%s  headers=%d  buttons=%d",
            tostring(st.enabled), tostring(st.live), st.headers or 0, st.buttons or 0))
    end
    if _G.FluxActionBarState and _G.FluxActionBarState.GetModDriverStats then
        local md = _G.FluxActionBarState.GetModDriverStats()
        print(PREFIX, string.format(
            "Bar mod state drivers: shared=%s  modDrivers=%d (was 6)  nativeDrivers=%d",
            tostring(md.shared), md.modDrivers or 0, md.nativeDrivers or 0))
    end

    print(PREFIX, "Baseline: /console scriptProfile 1 → /reload → play 60s → /script print(GetAddOnCPUUsage(\"_FluxUI\"))")
    print(PREFIX, "Usable churn: /fmacrolag report")
    print(PREFIX, "Idle A/B probe: /fluxperf probe  (hides bars/Extra briefly; OOC only)")
    print(PREFIX, "Login hitch: /fluxperf spells | /fluxperf combat | /fluxinvdebug stuck")
    print(PREFIX, "Reset coalescer counters: /fluxperf reset")
    print(PREFIX, "FluxInv bank/bag lag: /fluxinvdebug on | /fluxinvdebug watch 30 | /fluxinvdebug report | /fluxinvdebug stuck")
end

-- Temporary visibility A/B: isolate Actionbars vs ExtraButton render/secure cost.
-- Does not disable Binding overrides (combat-safe restore). OOC only.
local probeRunning = false

local function probeSampleFps(seconds, onDone)
    local sum, n, t = 0, 0, 0
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(_, elapsed)
        t = t + elapsed
        sum = sum + (GetFramerate and GetFramerate() or 0)
        n = n + 1
        if t >= seconds then
            f:SetScript("OnUpdate", nil)
            onDone(n > 0 and (sum / n) or 0)
        end
    end)
end

local function probeSetBarsHidden(hidden)
    local bar = _G.FluxMainActionBar
    local sense = _G.FluxActionBarSensing
    if bar then
        if hidden then bar:Hide() else bar:Show() end
    end
    if sense then
        if hidden then sense:Hide() else sense:Show() end
    end
end

local function probeCollectExtraButtons()
    local list = {}
    local src = _G.FluxButtonEvents and _G.FluxButtonEvents.ActiveButtons
    if type(src) == "table" then
        for i = 1, #src do
            local b = src[i]
            if b and b.IsShown and b:IsShown() then
                list[#list + 1] = b
            end
        end
    end
    return list
end

local function probeSetExtraHidden(hidden, saved)
    if hidden then
        saved = probeCollectExtraButtons()
        for i = 1, #saved do
            saved[i]:Hide()
        end
        return saved
    end
    if saved then
        for i = 1, #saved do
            local b = saved[i]
            if b and b.Show then b:Show() end
        end
    end
    return nil
end

local function probeSetBadgesHidden(hidden, saved)
    local Host = _G.FluxBadgeHost
    if not (Host and Host.ForEachColumnBadge) then return saved end
    if hidden then
        saved = saved or {}
        for col = 1, 19 do
            Host.ForEachColumnBadge(col, function(badge)
                if badge and badge.IsShown and badge:IsShown() then
                    saved[#saved + 1] = badge
                    badge:Hide()
                end
            end)
        end
        return saved
    end
    if saved then
        for i = 1, #saved do
            local b = saved[i]
            if b and b.Show then b:Show() end
        end
    end
    return nil
end

local function runIdleProbe()
    if probeRunning then
        print(PREFIX, "Probe already running.")
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        print(PREFIX, "Probe requires out of combat.")
        return
    end
    probeRunning = true
    print(PREFIX, "Idle probe starting — stand still, no mods/target. ~12s.")

    local results = {}
    local extraSaved, badgeSaved

    local function restoreAll()
        probeSetBarsHidden(false)
        probeSetExtraHidden(false, extraSaved)
        extraSaved = nil
        probeSetBadgesHidden(false, badgeSaved)
        badgeSaved = nil
        probeRunning = false
    end

    local function step(name, apply, nextFn)
        apply()
        probeSampleFps(2.0, function(fps)
            results[name] = fps
            print(PREFIX, string.format("  %s: %.1f FPS", name, fps))
            nextFn()
        end)
    end

    step("baseline", function() end, function()
        step("bars_hidden", function()
            probeSetBarsHidden(true)
        end, function()
            probeSetBarsHidden(false)
            step("extra_hidden", function()
                extraSaved = probeSetExtraHidden(true)
            end, function()
                extraSaved = probeSetExtraHidden(false, extraSaved)
                step("badges_hidden", function()
                    badgeSaved = probeSetBadgesHidden(true)
                end, function()
                    badgeSaved = probeSetBadgesHidden(false, badgeSaved)
                    step("bars+extra_hidden", function()
                        probeSetBarsHidden(true)
                        extraSaved = probeSetExtraHidden(true)
                    end, function()
                        restoreAll()
                        local b = results.baseline or 0
                        print(PREFIX, "Probe done. Deltas vs baseline:")
                        local order = { "bars_hidden", "extra_hidden", "badges_hidden", "bars+extra_hidden" }
                        for _, k in ipairs(order) do
                            local v = results[k]
                            if v then
                                print(PREFIX, string.format("  %s: %+.1f FPS", k, v - b))
                            end
                        end
                        print(PREFIX, "Large +FPS on bars_hidden ⇒ Actionbar surface cost. On extra_hidden ⇒ ExtraButton. Flat ⇒ Binding/hooks/elsewhere.")
                    end)
                end)
            end)
        end)
    end)
end

SLASH_FLUXPERF1 = "/fluxperf"
SlashCmdList["FLUXPERF"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$") or ""
    local command, arg = msg:match("^(%S+)%s*(.-)$")
    local capture = _G.Flux and _G.Flux.PerfCapture
    if capture then
        if command == "capture" then capture.Start(arg) return end
        if command == "last" then capture.Print() return end
        if command == "cancel" then capture.Cancel() return end
    end
    if msg == "burst" or msg == "form" then
        local Perf = _G.Flux and _G.Flux.Perf
        if Perf and Perf.PrintLastBurst then
            Perf.PrintLastBurst()
        else
            print(PREFIX, "burst capture not loaded")
        end
        return
    end
    if msg == "help" then
        print(PREFIX, "capture [seconds]: measured CPU/FPS deltas; last: print saved capture; cancel: stop capture")
        print(PREFIX, "burst: timed passes of the last shapeshift / page / bag-drag burst (per inventory listener)")
        print(PREFIX, "Usage: /fluxperf [report|reset|probe|combat|regen|spells|burst|help]")
        print(PREFIX, "CPU ms requires: /console scriptProfile 1 → /reload → idle 30s → /fluxperf report")
        print(PREFIX, "Round3 idle expect: Full armed=false, LAB.onUpdateArmed=false, MouseoverCast live=false (clear target)")
        print(PREFIX, "Round4 idle expect: EBS.cooldownSqueeze armed=false (no active CD), classifyQ=0 settled=true")
        print(PREFIX, "Round3 with target: EBS.range/LAB.range tickers ok; Full OnUpdate still false unless batch flags")
        print(PREFIX, "Raid extras: appliesEvent should stay near UNIT_AURA volume, not UNIT_HEALTH storms")
        print(PREFIX, "CPU ms requires: /console scriptProfile 1 → /reload → idle 30s → /fluxperf report")
        print(PREFIX, "FPS A/B: /console scriptProfile 0 with the same maxFPS; do not use probe as the only test (it hides bars/Extra).")
        print(PREFIX, "Header is expansion + version (live|camelot). The _retail_ folder is not the client; spellRanks follows Forever/Classic only.")
        print(PREFIX, "combat: CombatGrid settle snapshot (Best pending, coalesce, module pending)")
        print(PREFIX, "regen: last PLAYER_REGEN_ENABLED timings (flush keys, same-tick vs next-frame)")
        print(PREFIX, "spells: FluxInv spell warm/rebuild snapshot (login hitch probe)")
        return
    end
    if msg == "reset" then
        P.ResetStats()
        return
    end
    if msg == "probe" then
        runIdleProbe()
        return
    end
    if msg == "regen" then
        local Regen = _G.Flux and _G.Flux.Perf and _G.Flux.Perf.Regen
        if not (Regen and Regen.Print) then
            print(PREFIX, "regen capture not loaded")
            return
        end
        Regen.Print()
        return
    end
    if msg == "combat" then
        local CM = _G.FluxCombatManager
        if not (CM and CM.GetDebugStats) then
            print(PREFIX, "CombatGrid manager not loaded")
            return
        end
        local cs = CM:GetDebugStats()
        print(PREFIX, "— CombatGrid —")
        print(PREFIX, string.format(
            "coalesced=%d  pendingBatch=%s  ticker=%s  bestPendingLoad=%d  classifyQ=%d  settled=%s  modulesPending=%d  init=%s",
            cs.coalescedUpdates or 0,
            tostring(cs.moduleUpdatePending),
            tostring(cs.combatTicker),
            cs.bestPendingLoad or 0,
            cs.bestClassifyQueue or 0,
            tostring(cs.bestSettled),
            cs.modulesPendingUpdate or 0,
            tostring(cs.buttonsInitialized)))
        local mods = {
            { "Bandage", _G.FluxCombatBandage },
            { "HealPotion", _G.FluxCombatHealPotion },
            { "ManaPotion", _G.FluxCombatManaPotion },
            { "ManaGem", _G.FluxCombatManaGem },
            { "Healthstone", _G.FluxCombatHealthstone },
            { "Ammo", _G.FluxCombatAmmo },
        }
        for _, row in ipairs(mods) do
            local m = row[2]
            if m then
                print(PREFIX, string.format(
                    "  %-12s pending=%s  tracked=%s",
                    row[1],
                    tostring(m._pendingUpdate),
                    tostring(m._trackedItemID)))
            end
        end
        return
    end
    if msg == "spells" then
        local Spells = _G.FluxInv and _G.FluxInv.Spells
        if not (Spells and Spells.GetDebugStats) then
            print(PREFIX, "FluxInv.Spells not loaded")
            return
        end
        local ss = Spells.GetDebugStats()
        print(PREFIX, "— FluxInv.Spells —")
        print(PREFIX, string.format(
            "dirty=%s  warmDone=%s  reagentsDirty=%s  reagentsWarmDone=%s  warmPending=%s",
            tostring(ss.dirty),
            tostring(ss.warmDone),
            tostring(ss.reagentsDirty),
            tostring(ss.reagentsWarmDone),
            tostring(ss.reagentWarmPending)))
        print(PREFIX, string.format(
            "rebuilds=%d  lastCore=%.2fms  spells=%d  tooltips=%d  create=%d  reagentPending=%d  batches=%d  scanned=%d",
            ss.coreRebuilds or 0,
            ss.lastCoreMs or 0,
            ss.lastCoreSpells or 0,
            ss.lastCoreTooltips or 0,
            ss.createCount or 0,
            ss.reagentPending or 0,
            ss.reagentBatches or 0,
            ss.reagentScanned or 0))
        if (ss.lastCoreMs or 0) > 15 then
            print(PREFIX, "|cffffcc00Note:|r lastCore >15ms — create/conjure tooltip pass still heavy; check spellbook size.")
        end
        if (ss.lastCoreTooltips or 0) > 40 then
            print(PREFIX, "|cffffcc00Note:|r many create-candidate tooltips; name filter may be too broad.")
        end
        return
    end
    printReport()
end
