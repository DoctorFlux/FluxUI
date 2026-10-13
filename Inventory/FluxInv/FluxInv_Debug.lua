--[[
    Inventory/FluxInv/FluxInv_Debug.lua

    Bank↔bag transfer lag diagnostics for FluxInv pulse fan-out.
    Zero cost when disabled (Events checks IsEnabled before timing).

    /fluxinvdebug on|off|toggle
    /fluxinvdebug quiet|normal|verbose
    /fluxinvdebug report|reset|stuck|listeners
    /fluxinvdebug watch [sec]
    /fluxinvdebug threshold [ms]
    Alias: /fluxbanklag
]]

FluxInvDebug = FluxInvDebug or {}
local D = FluxInvDebug

local PREFIX = "|cff00ccffFluxInv|r |cff6699ff[LagDbg]|r"

local enabled = false
local verbosity = "quiet" -- quiet | normal | verbose
local thresholdMs = 8
local watchUntil = 0
local POST_CLOSE_SETTLE_SEC = 3

local stats = {
    bagUpdateEvents = 0,
    bagUpdateDelayed = 0,
    dispatches = 0,
    dispatchesBankOpen = 0,
    dispatchesBankClosed = 0,
    dispatchesPostClose = 0,
    totalDispatchMs = 0,
    maxDispatchMs = 0,
    totalBagsRefreshMs = 0,
    totalBankRefreshMs = 0,
    totalEquipRefreshMs = 0,
    totalOtherRefreshMs = 0,
    maxBagsRefreshMs = 0,
    maxBankRefreshMs = 0,
    listeners = {}, -- key -> { calls, totalMs, maxMs }
    lastBankOpenAt = 0,
    lastBankCloseAt = 0,
    postCloseDispatchMs = 0,
    postCloseMaxMs = 0,
    fpsAtEnable = nil,
    fpsAtReport = nil,
}

local function now()
    return (GetTime and GetTime()) or 0
end

local function fps()
    return (GetFramerate and GetFramerate()) or nil
end

local function profilestart()
    if debugprofilestart then
        debugprofilestart()
        return true
    end
    return false
end

local function profilestop()
    if debugprofilestop then
        return debugprofilestop() or 0
    end
    return 0
end

local function regionsStr(regions)
    if not regions then
        return "-"
    end
    local parts = {}
    for name in pairs(regions) do
        parts[#parts + 1] = name
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

local function ensureListener(key)
    local row = stats.listeners[key]
    if not row then
        row = { calls = 0, totalMs = 0, maxMs = 0 }
        stats.listeners[key] = row
    end
    return row
end

local function inWatchWindow()
    return watchUntil > 0 and now() < watchUntil
end

local function shouldChat()
    return enabled or inWatchWindow()
end

local function printLine(msg)
    print(PREFIX .. " " .. tostring(msg))
end

function D.IsEnabled()
    return enabled
end

function D.GetThresholdMs()
    return thresholdMs
end

function D.Reset()
    local keepThresh = thresholdMs
    local keepVerb = verbosity
    local keepEnabled = enabled
    stats = {
        bagUpdateEvents = 0,
        bagUpdateDelayed = 0,
        dispatches = 0,
        dispatchesBankOpen = 0,
        dispatchesBankClosed = 0,
        dispatchesPostClose = 0,
        totalDispatchMs = 0,
        maxDispatchMs = 0,
        totalBagsRefreshMs = 0,
        totalBankRefreshMs = 0,
        totalEquipRefreshMs = 0,
        totalOtherRefreshMs = 0,
        maxBagsRefreshMs = 0,
        maxBankRefreshMs = 0,
        listeners = {},
        lastBankOpenAt = stats.lastBankOpenAt or 0,
        lastBankCloseAt = stats.lastBankCloseAt or 0,
        postCloseDispatchMs = 0,
        postCloseMaxMs = 0,
        fpsAtEnable = keepEnabled and fps() or nil,
        fpsAtReport = nil,
    }
    thresholdMs = keepThresh
    verbosity = keepVerb
    enabled = keepEnabled
    printLine("counters reset.")
end

function D.SetEnabled(on)
    enabled = on and true or false
    if enabled then
        stats.fpsAtEnable = fps()
        if verbosity ~= "quiet" and verbosity ~= "normal" and verbosity ~= "verbose" then
            verbosity = "quiet"
        end
    end
    printLine("debug " .. (enabled and ("|cff00ff00ON|r (" .. verbosity .. ", threshold=" .. thresholdMs .. "ms)") or "|cffff4444OFF|r"))
end

function D.Toggle()
    D.SetEnabled(not enabled)
end

function D.SetVerbosity(level)
    level = level and tostring(level):lower() or "quiet"
    if level ~= "quiet" and level ~= "normal" and level ~= "verbose" then
        level = "quiet"
    end
    verbosity = level
    printLine("verbosity |cff00ff00" .. level .. "|r")
end

function D.SetThreshold(ms)
    ms = tonumber(ms)
    if not ms or ms < 0 then
        ms = 8
    end
    thresholdMs = ms
    printLine("threshold |cff00ff00" .. thresholdMs .. "|r ms")
end

function D.StartWatch(sec)
    sec = tonumber(sec) or 15
    if sec < 1 then
        sec = 15
    end
    local wasEnabled = enabled
    watchUntil = now() + sec
    if not enabled then
        enabled = true
        stats.fpsAtEnable = fps()
        printLine(string.format("watch |cff00ff00%.0fs|r (debug ON for watch, threshold=%sms)", sec, thresholdMs))
    else
        printLine(string.format("watch |cff00ff00%.0fs|r (threshold=%sms)", sec, thresholdMs))
    end
    if C_Timer and C_Timer.After then
        local untilT = watchUntil
        C_Timer.After(sec + 0.05, function()
            if watchUntil ~= untilT then
                return
            end
            watchUntil = 0
            if not wasEnabled then
                enabled = false
                printLine("watch ended — debug OFF. Run |cff99ff99/fluxinvdebug report|r (counters kept)")
            else
                printLine("watch ended — run |cff99ff99/fluxinvdebug report|r")
            end
        end)
    end
end

function D.OnBagUpdateEvent(isDelayed)
    if not enabled then
        return
    end
    if isDelayed then
        stats.bagUpdateDelayed = stats.bagUpdateDelayed + 1
    else
        stats.bagUpdateEvents = stats.bagUpdateEvents + 1
    end
end

function D.OnBankOpened()
    stats.lastBankOpenAt = now()
    if shouldChat() and verbosity ~= "quiet" then
        printLine("BANKFRAME_OPENED")
    end
end

function D.OnBankClosed()
    stats.lastBankCloseAt = now()
    if shouldChat() then
        printLine(string.format("BANKFRAME_CLOSED — settle window %.1fs (tag postClose)", POST_CLOSE_SETTLE_SEC))
    end
end

local function isPostClose()
    local t = stats.lastBankCloseAt
    if not t or t <= 0 then
        return false
    end
    -- Prefer post-close over bank-open if close is more recent and within settle.
    if stats.lastBankOpenAt > t then
        return false
    end
    return (now() - t) <= POST_CLOSE_SETTLE_SEC
end

function D.OnDispatchStart(tier, regions, bankOpen)
    -- Called only when enabled (Events gates).
end

function D.OnRefreshMs(bagsMs, bankMs, equipMs, otherMs)
    if not enabled then
        return
    end
    bagsMs = bagsMs or 0
    bankMs = bankMs or 0
    equipMs = equipMs or 0
    otherMs = otherMs or 0
    stats.totalBagsRefreshMs = stats.totalBagsRefreshMs + bagsMs
    stats.totalBankRefreshMs = stats.totalBankRefreshMs + bankMs
    stats.totalEquipRefreshMs = stats.totalEquipRefreshMs + equipMs
    stats.totalOtherRefreshMs = stats.totalOtherRefreshMs + otherMs
    if bagsMs > stats.maxBagsRefreshMs then
        stats.maxBagsRefreshMs = bagsMs
    end
    if bankMs > stats.maxBankRefreshMs then
        stats.maxBankRefreshMs = bankMs
    end
end

function D.OnListener(key, ms)
    if not enabled then
        return
    end
    key = key or "?"
    ms = ms or 0
    local row = ensureListener(key)
    row.calls = row.calls + 1
    row.totalMs = row.totalMs + ms
    if ms > row.maxMs then
        row.maxMs = ms
    end
    if verbosity == "verbose" and (ms >= thresholdMs or inWatchWindow()) then
        printLine(string.format("  listener %-32s %.2f ms", key, ms))
    elseif (verbosity == "quiet" or inWatchWindow()) and ms >= thresholdMs then
        printLine(string.format("|cffffaa00SLOW|r listener %-28s %.2f ms", key, ms))
    end
end

function D.OnDispatchEnd(info)
    if not enabled then
        return
    end
    info = info or {}
    local totalMs = info.totalMs or 0
    local bankOpen = info.bankOpen and true or false
    local postClose = info.postClose
    if postClose == nil then
        postClose = isPostClose()
    end

    stats.dispatches = stats.dispatches + 1
    stats.totalDispatchMs = stats.totalDispatchMs + totalMs
    if totalMs > stats.maxDispatchMs then
        stats.maxDispatchMs = totalMs
    end
    if bankOpen then
        stats.dispatchesBankOpen = stats.dispatchesBankOpen + 1
    else
        stats.dispatchesBankClosed = stats.dispatchesBankClosed + 1
    end
    if postClose then
        stats.dispatchesPostClose = stats.dispatchesPostClose + 1
        stats.postCloseDispatchMs = stats.postCloseDispatchMs + totalMs
        if totalMs > stats.postCloseMaxMs then
            stats.postCloseMaxMs = totalMs
        end
    end

    local show = false
    if verbosity == "verbose" then
        show = true
    elseif verbosity == "normal" then
        show = true
    elseif verbosity == "quiet" or inWatchWindow() then
        show = totalMs >= thresholdMs
    end
    if show then
        local tag = postClose and "|cffff8800postClose|r" or (bankOpen and "bankOpen" or "closed")
        printLine(string.format(
            "dispatch #%d %s tier=%s regions=%s total=|cffffffff%.2f|r ms (bags=%.2f bank=%.2f equip=%.2f other=%.2f listeners=%.2f)",
            stats.dispatches,
            tag,
            tostring(info.tier or "?"),
            regionsStr(info.regions),
            totalMs,
            info.bagsMs or 0,
            info.bankMs or 0,
            info.equipMs or 0,
            info.otherMs or 0,
            info.listenersMs or 0
        ))
    end
end

local function topListeners(n)
    n = n or 8
    local rows = {}
    for key, row in pairs(stats.listeners) do
        rows[#rows + 1] = { key = key, calls = row.calls, totalMs = row.totalMs, maxMs = row.maxMs }
    end
    table.sort(rows, function(a, b)
        if a.totalMs ~= b.totalMs then
            return a.totalMs > b.totalMs
        end
        return a.maxMs > b.maxMs
    end)
    local out = {}
    for i = 1, math.min(n, #rows) do
        out[i] = rows[i]
    end
    return out
end

function D.GetSummary()
    local top = topListeners(1)[1]
    return {
        enabled = enabled,
        dispatches = stats.dispatches,
        maxDispatchMs = stats.maxDispatchMs,
        avgDispatchMs = stats.dispatches > 0 and (stats.totalDispatchMs / stats.dispatches) or 0,
        topListener = top and top.key or nil,
        topListenerMs = top and top.totalMs or 0,
        bagEvents = stats.bagUpdateEvents + stats.bagUpdateDelayed,
        postCloseDispatches = stats.dispatchesPostClose,
        postCloseMaxMs = stats.postCloseMaxMs,
    }
end

local function frameHasOnUpdate(f)
    return f and f.GetScript and f:GetScript("OnUpdate") ~= nil
end

local function extraButtonFullArmed()
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

function D.PrintStuck()
    printLine("— stuck / pending snapshot —")
    local inv = _G.FluxInv
    local bankOpen = inv and inv.IsBankOpen and inv.IsBankOpen()
    if inv and inv.Bank and inv.Bank.IsOpen then
        bankOpen = inv.Bank.IsOpen()
    end
    printLine(string.format("bankOpen=%s", tostring(bankOpen)))

    local Events = inv and inv.Events
    local debounce = Events and Events.IsDebouncePending and Events.IsDebouncePending()
    printLine(string.format("FluxInv debouncePending=%s", tostring(debounce)))

    local deferHeavy = inv and inv.ShouldDeferHeavyWork and inv.ShouldDeferHeavyWork()
    printLine(string.format("ShouldDeferHeavyWork=%s", tostring(deferHeavy)))

    local armed, flags = extraButtonFullArmed()
    printLine(string.format("ExtraButton Full OnUpdate armed=%s%s",
        tostring(armed),
        (armed and flags ~= "" and (" flags=" .. flags)) or ""))

    local cons = _G.FluxNCConsumables
    if cons then
        printLine(string.format("Consumables _pendingUpdate=%s  _registered=%s",
            tostring(cons._pendingUpdate),
            tostring(cons._registered)))
    end

    local mount = _G.FluxNCMount
    if mount then
        printLine(string.format("Mount _pendingUpdate=%s  bagMountNeedsFullRefresh=%s",
            tostring(mount._pendingUpdate),
            tostring(mount._bagMountNeedsFullRefresh)))
    end

    local hearth = _G.FluxNCHearthstone
    if hearth then
        printLine(string.format("Hearthstone _pendingUpdate=%s", tostring(hearth._pendingUpdate)))
    end

    local Best = _G.FluxConsumableBest
    if Best then
        local pendingLoad = (Best.GetPendingLoadCount and Best.GetPendingLoadCount()) or 0
        if pendingLoad == 0 and Best._pendingLoad then
            for _ in pairs(Best._pendingLoad) do
                pendingLoad = pendingLoad + 1
            end
        end
        local classifyQ = (Best.GetClassifyQueueCount and Best.GetClassifyQueueCount()) or -1
        printLine(string.format("Best pendingLoad=%d  classifyQueue=%s  settled=%s  RequestRecompute=%s  ShouldDefer=%s",
            pendingLoad,
            classifyQ >= 0 and tostring(classifyQ) or "?",
            tostring(Best.IsSettled and Best.IsSettled() or (pendingLoad == 0)),
            tostring(Best.RequestRecompute ~= nil),
            tostring(Best.ShouldDefer and Best.ShouldDefer() or (inv and inv.ShouldDeferHeavyWork and inv.ShouldDeferHeavyWork()))))
    end

    local Spells = inv and inv.Spells
    if Spells and Spells.GetDebugStats then
        local ss = Spells.GetDebugStats()
        printLine(string.format(
            "Spells dirty=%s warm=%s reagentsWarm=%s pending=%d lastCore=%.2fms tips=%d rebuilds=%d",
            tostring(ss.dirty),
            tostring(ss.warmDone),
            tostring(ss.reagentsWarmDone),
            ss.reagentPending or 0,
            ss.lastCoreMs or 0,
            ss.lastCoreTooltips or 0,
            ss.coreRebuilds or 0))
    end

    local CM = _G.FluxCombatManager
    if CM and CM.GetDebugStats then
        local cs = CM:GetDebugStats()
        printLine(string.format(
            "CombatGrid coalesced=%d pendingBatch=%s bestPending=%d modulesPending=%d ticker=%s",
            cs.coalescedUpdates or 0,
            tostring(cs.moduleUpdatePending),
            cs.bestPendingLoad or 0,
            cs.modulesPendingUpdate or 0,
            tostring(cs.combatTicker)))
    end

    local Tiers = _G.FluxRestockTiers
    if Tiers then
        printLine(string.format("Tiers _loginSettleDeferred=%s  SettleDeferredInferior=%s",
            tostring(Tiers._loginSettleDeferred),
            tostring(Tiers.SettleDeferredInferior ~= nil)))
    end

    local BR = _G.FluxBankRestock
    if BR then
        printLine(string.format("BankRestock IsRunning=%s  ScheduleIdleButtonRefresh=%s",
            tostring(BR.IsRunning and BR.IsRunning()),
            tostring(BR.ScheduleIdleButtonRefresh ~= nil)))
    end

    local Overlay = _G.FluxJunkOverlay
    if Overlay then
        printLine(string.format("JunkOverlay present=%s  ScheduleBankTransferPaint=%s",
            tostring(true),
            tostring(Overlay.ScheduleBankTransferPaint ~= nil)))
    end

    local fr = fps()
    if fr then
        printLine(string.format("FPS now=%.1f", fr))
    end

    if stats.lastBankCloseAt > 0 then
        printLine(string.format("sec since bank close=%.2f  postClose settle left=%.2f",
            now() - stats.lastBankCloseAt,
            math.max(0, POST_CLOSE_SETTLE_SEC - (now() - stats.lastBankCloseAt))))
    end
end

function D.PrintListeners()
    local inv = _G.FluxInv
    local Events = inv and inv.Events
    if not Events or not Events.GetListeners then
        printLine("Events.GetListeners not available")
        return
    end
    local list = Events.GetListeners()
    printLine(string.format("— registered listeners (%d) —", #list))
    table.sort(list, function(a, b)
        return (a.key or "") < (b.key or "")
    end)
    for _, row in ipairs(list) do
        local regs = "-"
        if row.regions then
            local parts = {}
            for name in pairs(row.regions) do
                parts[#parts + 1] = name
            end
            table.sort(parts)
            regs = table.concat(parts, ",")
            if regs == "" then
                regs = "*"
            end
        else
            regs = "*"
        end
        printLine(string.format("  %-36s tier=%-7s regions=%s", row.key, tostring(row.tier), regs))
    end
end

function D.PrintReport()
    stats.fpsAtReport = fps()
    printLine("— FluxInv lag report —")
    printLine(string.format("enabled=%s  verbosity=%s  threshold=%sms",
        tostring(enabled), verbosity, thresholdMs))

    if stats.fpsAtEnable or stats.fpsAtReport then
        printLine(string.format("FPS at enable=%s  now=%s",
            stats.fpsAtEnable and string.format("%.1f", stats.fpsAtEnable) or "?",
            stats.fpsAtReport and string.format("%.1f", stats.fpsAtReport) or "?"))
    end

    local avg = stats.dispatches > 0 and (stats.totalDispatchMs / stats.dispatches) or 0
    printLine(string.format(
        "dispatches=%d  avg=%.2f ms  max=%.2f ms  total=%.2f ms",
        stats.dispatches, avg, stats.maxDispatchMs, stats.totalDispatchMs))
    printLine(string.format(
        "  bankOpen=%d  bankClosed=%d  postClose=%d (postClose total=%.2f max=%.2f)",
        stats.dispatchesBankOpen,
        stats.dispatchesBankClosed,
        stats.dispatchesPostClose,
        stats.postCloseDispatchMs,
        stats.postCloseMaxMs))
    printLine(string.format(
        "BAG_UPDATE=%d  BAG_UPDATE_DELAYED=%d  (ratio events/dispatch=%.2f)",
        stats.bagUpdateEvents,
        stats.bagUpdateDelayed,
        stats.dispatches > 0 and ((stats.bagUpdateEvents + stats.bagUpdateDelayed) / stats.dispatches) or 0))
    printLine(string.format(
        "refresh totals: bags=%.2f (max %.2f)  bank=%.2f (max %.2f)  equip=%.2f  other=%.2f",
        stats.totalBagsRefreshMs, stats.maxBagsRefreshMs,
        stats.totalBankRefreshMs, stats.maxBankRefreshMs,
        stats.totalEquipRefreshMs, stats.totalOtherRefreshMs))

    local tops = topListeners(10)
    printLine("top listeners by total ms:")
    if #tops == 0 then
        printLine("  (none yet — enable debug and move items)")
    else
        for i, row in ipairs(tops) do
            local avgL = row.calls > 0 and (row.totalMs / row.calls) or 0
            printLine(string.format(
                "  %2d. %-32s calls=%d  total=%.2f  avg=%.2f  max=%.2f",
                i, row.key, row.calls, row.totalMs, avgL, row.maxMs))
        end
    end

    if stats.lastBankOpenAt > 0 or stats.lastBankCloseAt > 0 then
        printLine(string.format("last bank open=%.1fs ago  close=%.1fs ago",
            stats.lastBankOpenAt > 0 and (now() - stats.lastBankOpenAt) or -1,
            stats.lastBankCloseAt > 0 and (now() - stats.lastBankCloseAt) or -1))
    end

    printLine("next: /fluxinvdebug stuck")
end

function D.PrintHelp()
    printLine("Usage:")
    printLine("  /fluxinvdebug on|off|toggle")
    printLine("  /fluxinvdebug quiet|normal|verbose")
    printLine("  /fluxinvdebug threshold [ms]   (default 8)")
    printLine("  /fluxinvdebug watch [sec]      (default 15)")
    printLine("  /fluxinvdebug report|reset|stuck|listeners")
    printLine("Alias: /fluxbanklag")
    printLine("Bank flow: on → quiet/watch → move bank items → close bank → report + stuck")
    printLine("Loot/craft baseline:")
    printLine("  1) /fluxinvdebug on  then  /fluxinvdebug reset")
    printLine("  2) Loot a pack or craft a queue (bags open or closed)")
    printLine("  3) /fluxinvdebug report  — check max dispatch + top listenersMs")
    printLine("  Target: lower peak totalMs/listenersMs; counts stay live")
end

local function handleSlash(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$") or ""
    local cmd, rest = msg:match("^(%S+)%s*(.-)$")
    cmd = cmd and cmd:lower() or ""
    rest = rest or ""

    if cmd == "" or cmd == "help" then
        D.PrintHelp()
        return
    end
    if cmd == "on" then
        D.SetEnabled(true)
        return
    end
    if cmd == "off" then
        D.SetEnabled(false)
        watchUntil = 0
        return
    end
    if cmd == "toggle" then
        D.Toggle()
        return
    end
    if cmd == "quiet" or cmd == "normal" or cmd == "verbose" then
        D.SetVerbosity(cmd)
        return
    end
    if cmd == "threshold" then
        D.SetThreshold(rest)
        return
    end
    if cmd == "watch" then
        D.StartWatch(rest)
        return
    end
    if cmd == "reset" then
        D.Reset()
        return
    end
    if cmd == "report" then
        D.PrintReport()
        return
    end
    if cmd == "stuck" then
        D.PrintStuck()
        return
    end
    if cmd == "listeners" then
        D.PrintListeners()
        return
    end
    D.PrintHelp()
end

SLASH_FLUXINVDEBUG1 = "/fluxinvdebug"
SLASH_FLUXINVDEBUG2 = "/fluxbanklag"
SlashCmdList["FLUXINVDEBUG"] = handleSlash

-- Timing helpers for Events (cheap when disabled — Events checks IsEnabled first).
D.ProfileStart = profilestart
D.ProfileStop = profilestop

_G.FluxInvDebug = D
