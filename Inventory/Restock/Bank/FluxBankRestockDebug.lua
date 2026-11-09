--[[
    Restock/Bank/FluxBankRestockDebug.lua

    Chat debug for bank restock. Default is quiet: important moves + failures
    only; repetitive wait/stall/burst lines are throttled or hidden.

    /fluxbankdebug on|off|toggle
    /fluxbankdebug quiet|normal|verbose
    /fluxbankdebug cat <name> on|off
    /fluxbankdebug dump
]]

FluxBankRestockDebug = FluxBankRestockDebug or {}
local Dbg = FluxBankRestockDebug

local PREFIX = "|cff00ccffFluxRestock|r |cff6699ff[BankDbg]|r"
local enabled = false
local verbosity = "quiet" -- quiet | normal | verbose
local categoriesCustomized = false

local categories = {
    session = true,
    step = true,
    exec = true,
    pending = false,
    split = true,
    merge = true,
    progress = false,
    replan = true,
    event = true,
    mover = false,
    pace = false,
}

local repeatState = {}

local QUIET_CATEGORIES = {
    session = true, step = true, exec = false, pending = false,
    split = true, merge = true, progress = false, replan = false,
    mover = false, event = true, pace = false,
}

local NORMAL_CATEGORIES = {
    session = true, step = true, exec = true, pending = true,
    split = true, merge = true, progress = true, replan = true,
    mover = false, event = true, pace = false,
}

local VERBOSE_CATEGORIES = {
    session = true, step = true, exec = true, pending = true,
    split = true, merge = true, progress = true, replan = true,
    mover = true, event = true, pace = true,
}

local function now()
    return GetTime and GetTime() or 0
end

local function catEnabled(cat)
    if not enabled then
        return false
    end
    if not cat then
        return true
    end
    return categories[cat] ~= false
end

local function applyCategoryDefaults(src)
    for name, on in pairs(src) do
        categories[name] = on
    end
end

local function throttleInterval(cat, msg)
    if verbosity == "verbose" then
        return 0
    end
    if cat == "progress" then
        return -1
    end
    if cat == "session" then
        if msg:find("burst frame=", 1, true) then
            return verbosity == "quiet" and 3.0 or 1.5
        end
        if msg:find("watchdog resume", 1, true) then
            return verbosity == "quiet" and 5.0 or 2.0
        end
    end
    if cat == "step" then
        if msg:find("^resolve ", 1, false)
            or msg:find("^resolved ", 1, false)
            or msg:find("^split%-retry ", 1, false) then
            return verbosity == "quiet" and 2.0 or 1.0
        end
    end
    if cat == "split" then
        if msg:find("MarkSplitFailed", 1, true) then
            return verbosity == "quiet" and 5.0 or 2.0
        end
    end
    if cat == "mover" or cat == "merge" or cat == "exec" then
        if categoriesCustomized and categories[cat] then
            return 0
        end
        return verbosity == "quiet" and -2 or 0
    end
    return 0
end

local function shouldSuppress(cat, msg)
    local interval = throttleInterval(cat, msg)
    if interval == -2 then
        return true, nil
    end
    if interval == -1 then
        local key = "change:" .. cat
        local st = repeatState[key]
        if st and st.msg == msg then
            st.suppressed = (st.suppressed or 0) + 1
            return true, st
        end
        repeatState[key] = { msg = msg, at = now(), suppressed = 0 }
        return false, nil
    end
    if interval <= 0 then
        return false, nil
    end
    local key = "throttle:" .. cat .. "\0" .. msg:sub(1, 120)
    local t = now()
    local st = repeatState[key]
    if st and st.msg == msg and (t - (st.at or 0)) < interval then
        st.suppressed = (st.suppressed or 0) + 1
        return true, st
    end
    if st and (st.suppressed or 0) > 0 then
        print(PREFIX .. " |cff888888(" .. st.suppressed .. " similar suppressed)|r")
    end
    repeatState[key] = { msg = msg, at = t, suppressed = 0 }
    return false, nil
end

local function emit(cat, tag, msg)
    print(PREFIX .. " " .. tag .. msg)
end

function Dbg.IsEnabled()
    return enabled
end

function Dbg.GetVerbosity()
    return verbosity
end

function Dbg.SetVerbosity(level)
    level = level and tostring(level):lower() or "quiet"
    if level ~= "quiet" and level ~= "normal" and level ~= "verbose" then
        level = "quiet"
    end
    verbosity = level
    if not categoriesCustomized then
        if level == "verbose" then
            applyCategoryDefaults(VERBOSE_CATEGORIES)
        elseif level == "normal" then
            applyCategoryDefaults(NORMAL_CATEGORIES)
        else
            applyCategoryDefaults(QUIET_CATEGORIES)
        end
    end
    print(PREFIX .. " verbosity |cff00ff00" .. level .. "|r")
end

function Dbg.SetEnabled(on)
    enabled = on and true or false
    if enabled and not categoriesCustomized then
        verbosity = "quiet"
        applyCategoryDefaults(QUIET_CATEGORIES)
    end
    print(PREFIX .. " debug " .. (enabled and "|cff00ff00ON|r (" .. verbosity .. ")" or "|cffff4444OFF|r"))
end

function Dbg.Toggle()
    Dbg.SetEnabled(not enabled)
end

function Dbg.SetCategory(cat, on)
    cat = cat and tostring(cat):lower() or nil
    if not cat then
        return
    end
    categoriesCustomized = true
    categories[cat] = on and true or false
    print(PREFIX .. " category '" .. cat .. "' " .. (on and "on" or "off"))
end

--- Always printed when debug is on (successes, failures, session boundaries).
function Dbg.PrintImportant(cat, fmt, ...)
    if not catEnabled(cat) then
        return
    end
    local tag = cat and ("|cff99aaff[" .. cat .. "]|r ") or ""
    if select("#", ...) > 0 then
        emit(cat, tag, string.format(tostring(fmt or ""), ...))
    else
        emit(cat, tag, tostring(fmt or ""))
    end
end

function Dbg.Print(cat, fmt, ...)
    if not catEnabled(cat) then
        return
    end
    local tag = cat and ("|cff99aaff[" .. cat .. "]|r ") or ""
    local msg
    if select("#", ...) > 0 then
        msg = string.format(tostring(fmt or ""), ...)
    else
        msg = tostring(fmt or "")
    end
    local suppress = shouldSuppress(cat, msg)
    if suppress then
        return
    end
    emit(cat, tag, msg)
end

--- Throttle by explicit signature (e.g. step resolve while waiting).
function Dbg.PrintThrottled(cat, signature, intervalSec, fmt, ...)
    if not catEnabled(cat) then
        return
    end
    intervalSec = tonumber(intervalSec) or 1.0
    if verbosity == "verbose" then
        intervalSec = 0
    end
    local tag = cat and ("|cff99aaff[" .. cat .. "]|r ") or ""
    local msg
    if select("#", ...) > 0 then
        msg = string.format(tostring(fmt or ""), ...)
    else
        msg = tostring(fmt or "")
    end
    if intervalSec > 0 then
        local key = "sig:" .. cat .. "\0" .. tostring(signature)
        local t = now()
        local st = repeatState[key]
        if st and (t - (st.at or 0)) < intervalSec then
            st.suppressed = (st.suppressed or 0) + 1
            return
        end
        if st and (st.suppressed or 0) > 0 then
            print(PREFIX .. " |cff888888(" .. st.suppressed .. " similar suppressed)|r")
        end
        repeatState[key] = { at = t, suppressed = 0 }
    end
    emit(cat, tag, msg)
end

function Dbg.FormatStep(step)
    if not step then
        return "step=nil"
    end
    return string.format(
        "item=%s bank=%s:%s amt=%s mode=%s mustSplit=%s merge=%s:%s max=%s tier=%s",
        tostring(step.itemID),
        tostring(step.bankBag), tostring(step.bankSlot),
        tostring(step.amount),
        tostring(step.mode or "withdraw"),
        step.mustSplit and "Y" or "N",
        tostring(step.mergeBag or "-"), tostring(step.mergeSlot or "-"),
        tostring(step.maxStack or "?"),
        tostring(step.tierKind or "-"))
end

function Dbg.FormatAction(a)
    if not a then
        return "action=nil"
    end
    return string.format(
        "item=%s bank=%s:%s amt=%s cursorAmt=%s mode=%s phase=%s splitIssued=%s ticks=%d async=%d lockW=%d stuck=%d merge=%s:%s before=%s",
        tostring(a.itemID),
        tostring(a.bag or "-"), tostring(a.slot or "-"),
        tostring(a.amount),
        tostring(a.cursorAmount or "-"),
        tostring(a.stepMode or "withdraw"),
        tostring(a.phase or "-"),
        a.splitIssued and "Y" or "N",
        tonumber(a.ticks) or 0,
        tonumber(a.asyncWaitTicks) or 0,
        tonumber(a.lockWaitTicks) or 0,
        tonumber(a.stuckTicks) or 0,
        tostring(a.mergeBag or "-"), tostring(a.mergeSlot or "-"),
        tostring(a.splitCountBefore or "-"))
end

function Dbg.FormatResult(result)
    if not result then
        return "result=nil"
    end
    local parts = {
        "ok=" .. tostring(result.ok),
        "moved=" .. tostring(result.moved or 0),
        "reason=" .. tostring(result.reason or "-"),
    }
    if result.wasSplit then
        parts[#parts + 1] = "wasSplit=Y"
    end
    if result.hardFail then
        parts[#parts + 1] = "hardFail=Y"
    end
    return table.concat(parts, " ")
end

function Dbg.FormatTask(task, remaining)
    if not task then
        return "task=nil"
    end
    local entry = task.entry
    local label = entry and (entry.tierKind or entry.itemID) or "?"
    remaining = tonumber(remaining)
    if remaining == nil and task.withdraw then
        remaining = task.withdraw
    end
    local extra = ""
    if task._preferWithdraw then
        extra = " preferWithdraw=Y"
    end
    return string.format("task=%s rem=%s withdraw=%s%s",
        tostring(label),
        tostring(remaining or "?"),
        tostring(task.withdraw or "?"),
        extra)
end

local function slotCount(bag)
    bag = tonumber(bag)
    if not bag then
        return 0
    end
    if C_Container and C_Container.GetContainerNumSlots then
        local ok, n = pcall(C_Container.GetContainerNumSlots, bag)
        if ok and tonumber(n) and n > 0 then
            return n
        end
    end
    if GetContainerNumSlots then
        local ok, n = pcall(GetContainerNumSlots, bag)
        if ok then
            return tonumber(n) or 0
        end
    end
    return 0
end

local function slotInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
        if ok and type(info) == "table" then
            return tonumber(info.itemID), tonumber(info.stackCount or info.count) or 0
        end
    end
    if C_Container and C_Container.GetContainerItemID then
        local ok, id = pcall(C_Container.GetContainerItemID, bag, slot)
        if ok and tonumber(id) then
            return tonumber(id), 1
        end
    end
    return nil, 0
end

function Dbg.DumpLiveScan()
    print(PREFIX .. " --- live scan ---")
    local FR = _G.FluxRestock
    local inv = FR and FR.Inv
    local bank = inv and inv.Bank
    local FluxInv = _G.Flux and _G.Flux.Inventory
    print(PREFIX .. string.format(" FluxRestock.Inv=%s Bank=%s live=%s open=%s",
        inv and "yes" or "no",
        bank and "yes" or "no",
        tostring(bank and bank.IsLive and bank.IsLive()
            or (FluxInv and FluxInv.IsBankLive and FluxInv.IsBankLive()) or false),
        tostring(bank and bank.IsOpen and bank.IsOpen()
            or (FluxInv and FluxInv.IsBankOpen and FluxInv.IsBankOpen()) or false)))

    local scan = bank and bank.GetScanDebug and bank.GetScanDebug() or {}
    local C = FluxInv and FluxInv.Containers
    local ids = scan.ids
    if not ids or #ids == 0 then
        if C and C.GetCharacterBankIDs then
            ids = C.GetCharacterBankIDs()
        elseif bank and bank.GetContainerIDs then
            ids = bank.GetContainerIDs()
        else
            ids = {}
        end
    end
    local idStr = {}
    local slotStr = scan.slots or {}
    if #slotStr == 0 then
        slotStr = {}
        for i = 1, #ids do
            local bag = ids[i]
            local n = slotCount(bag)
            local fb = C and C.GetOpenBankScanNumSlots and C.GetOpenBankScanNumSlots(bag) or n
            slotStr[#slotStr + 1] = string.format("%s:%s/%s", tostring(bag), tostring(n), tostring(fb))
        end
    end
    for i = 1, #ids do
        idStr[#idStr + 1] = tostring(ids[i])
    end
    print(PREFIX .. " bank IDs: " .. (#idStr > 0 and table.concat(idStr, ",") or "(none)"))
    print(PREFIX .. " slots bag:GetContainerNumSlots/fallback: "
        .. (#slotStr > 0 and table.concat(slotStr, " ") or "(none)"))

    local firstMatch
    local br = _G.FluxBankRestock
    local reg = _G.FluxRestockItemRegistry
    local list = reg and reg.GetBankTargetList and reg.GetBankTargetList() or {}
    for _, entry in ipairs(list) do
        local itemID = tonumber(entry and entry.itemID)
        if itemID and bank and bank.FindStacks then
            local stacks = bank.FindStacks(itemID)
            local st = stacks and stacks[1]
            if st then
                firstMatch = st
                break
            end
        end
        if entry and entry.isTierBankEntry and entry.tierKind then
            local T = _G.FluxRestockTiers
            local stacks = T and T.FindBankStacksForKind and T.FindBankStacksForKind(entry.tierKind)
            local st = stacks and stacks[1]
            if st then
                firstMatch = st
                break
            end
        end
    end
    if not firstMatch then
        firstMatch = scan.firstStack
    end
    if not firstMatch then
        for i = 1, #ids do
            local bag = ids[i]
            local n = slotCount(bag)
            if n <= 0 and C and C.GetOpenBankScanNumSlots then
                n = C.GetOpenBankScanNumSlots(bag) or 0
            end
            for slot = 1, n do
                local itemID, count = slotInfo(bag, slot)
                if itemID and count > 0 then
                    firstMatch = { bag = bag, slot = slot, itemID = itemID, count = count }
                    break
                end
            end
            if firstMatch then
                break
            end
        end
    end
    if firstMatch then
        print(PREFIX .. string.format(" first stack %s:%s item=%s count=%s",
            tostring(firstMatch.bag), tostring(firstMatch.slot),
            tostring(firstMatch.itemID), tostring(firstMatch.count)))
    else
        print(PREFIX .. " first stack: (none)")
    end

    local last = scan.lastUse or (inv and inv.GetLastBankUse and inv.GetLastBankUse())
    if last and last.bag then
        print(PREFIX .. string.format(
            " last UseContainerItem %s:%s item=%s before=%s after=%s ok=%s api=%s err=%s",
            tostring(last.bag), tostring(last.slot), tostring(last.itemID),
            tostring(last.before), tostring(last.after), tostring(last.ok),
            tostring(last.api or "-"), tostring(last.err or "-")))
    else
        print(PREFIX .. " last UseContainerItem: (none)")
    end
    if br and br.CanRunNow then
        print(PREFIX .. " CanRunNow=" .. tostring(br.CanRunNow()))
    end
end

function Dbg.DumpSession(session)
    if not session then
        Dbg.PrintImportant("session", "dump: no session table")
        return
    end
    Dbg.PrintImportant("session", "running=%s aborted=%s activeTask=%s steps=%s replans=%s lastOp=%s",
        tostring(session.running), tostring(session.aborted),
        tostring(session.activeTaskIndex or 1),
        tostring(session.stepsCompleted or 0),
        tostring(session.replanAttempts or 0),
        tostring(session.lastOpKind or "-"))
    local mover = _G.FluxItemMover
    if mover then
        Dbg.Print("mover", "actionActive=%s backoffSteps=%s",
            tostring(mover.IsActionActive and mover.IsActionActive()),
            tostring(mover.GetBackoffSteps and mover.GetBackoffSteps() or "-"))
    end
    if session.taskProgress then
        for key, prog in pairs(session.taskProgress) do
            Dbg.PrintImportant("progress", "%s rem=%s stall=%s",
                tostring(key), tostring(prog.lastRemaining), tostring(prog.stall or 0))
        end
    end
    if session.splitFails then
        for key, fails in pairs(session.splitFails) do
            if fails and fails > 0 then
                Dbg.PrintImportant("split", "splitFails[%s]=%s", tostring(key), tostring(fails))
            end
        end
    end
    if session.skipped then
        for key, skipped in pairs(session.skipped) do
            if skipped then
                Dbg.PrintImportant("step", "skipped slot %s", tostring(key))
            end
        end
    end
end

SLASH_FLUXBANKRESTOCKDEBUG1 = "/fluxbankdebug"
SLASH_FLUXBANKRESTOCKDEBUG2 = "/fbrdebug"
SlashCmdList["FLUXBANKRESTOCKDEBUG"] = function(msg)
    msg = strtrim and strtrim(msg or "") or (msg or ""):match("^%s*(.-)%s*$") or ""
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    cmd = (cmd or msg or ""):lower()
    rest = rest or ""

    if cmd == "" or cmd == "help" then
        print(PREFIX .. " /fluxbankdebug on|off|toggle|dump|cats")
        print(PREFIX .. " /fluxbankdebug quiet|normal|verbose")
        print(PREFIX .. " /fluxbankdebug cat <name> on|off")
        print(PREFIX .. " quiet = moves/failures only (default); verbose = all categories")
        return
    end
    if cmd == "on" or cmd == "1" or cmd == "true" then
        Dbg.SetEnabled(true)
        return
    end
    if cmd == "off" or cmd == "0" or cmd == "false" then
        Dbg.SetEnabled(false)
        return
    end
    if cmd == "toggle" then
        Dbg.Toggle()
        return
    end
    if cmd == "quiet" or cmd == "normal" or cmd == "verbose" then
        categoriesCustomized = false
        Dbg.SetVerbosity(cmd)
        if not enabled then
            Dbg.SetEnabled(true)
        end
        return
    end
    if cmd == "dump" then
        Dbg.SetEnabled(true)
        Dbg.DumpLiveScan()
        local br = _G.FluxBankRestock
        if br and br.DebugDumpSession then
            br.DebugDumpSession()
        else
            Dbg.PrintImportant("session", "FluxBankRestock not loaded yet")
        end
        return
    end
    if cmd == "cat" or cmd == "category" then
        local name, state = rest:match("^(%S+)%s*(.*)$")
        if not name then
            print(PREFIX .. " usage: cat <name> on|off")
            return
        end
        state = (state or ""):lower()
        Dbg.SetCategory(name, state ~= "off" and state ~= "0" and state ~= "false")
        return
    end
    if cmd == "cats" then
        local names = {}
        for name, on in pairs(categories) do
            names[#names + 1] = name .. "=" .. (on and "on" or "off")
        end
        table.sort(names)
        Dbg.PrintImportant("session", "verbosity=%s categories: %s", verbosity, table.concat(names, ", "))
        return
    end
    print(PREFIX .. " unknown command '" .. cmd .. "' (try help)")
end

_G.FluxBankRestockDebug = Dbg
return Dbg
