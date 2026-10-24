-- Run production dispatchers with deterministic WoW boundaries. No client required.
local root = (arg[0]:match("^(.*)[/\\]") or ".")
if root:match("[/\\]?Bars$") or root:match("[/\\]?tests$") then
    root = root .. "/../"
else
    root = "./"
end
local checks = 0
local function check(value, message)
    assert(value, "bars refresh expectation: " .. message)
    checks = checks + 1
end
local function source(path)
    local file = assert(io.open(root .. path, "rb"))
    local value = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return value
end

local function fixture(mutation, insecure, context, namespaced)
    local f = { now = 1, page = 1, form = 0, combat = false, timers = {}, events = {},
        tokens = {}, counts = {}, notifications = {}, layout = 0, applies = 0, swept = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local flux = { Bars = { hosts = {}, NUM_NATIVE = 12, NUM_COLUMNS = 19, secureReady = true } }
    local B = flux.Bars
    f.flux, f.env, f.B = flux, env, B
    local function after(delay, callback)
        f.timers[#f.timers + 1] = { at = f.now + delay, callback = callback }
    end
    function f.advance(delay)
        local untilTime, callbacks = f.now + (delay or 0), 0
        while true do
            local index, earliest
            for i, timer in ipairs(f.timers) do
                if timer.at <= untilTime and (not earliest or timer.at < earliest) then
                    index, earliest = i, timer.at
                end
            end
            if not index then break end
            local timer = table.remove(f.timers, index)
            f.now = timer.at
            timer.callback()
            callbacks = callbacks + 1
            assert(callbacks < 1000, "timer work must terminate")
        end
        f.now = untilTime
    end
    function f.emit(event, ...)
        for _, callback in ipairs(f.events[event] or {}) do callback(event, ...) end
    end
    flux.Timer = { After = after, Defer = function(callback) after(0, callback) end }
    flux.Events = { Register = function(event, callback)
        f.events[event] = f.events[event] or {}
        table.insert(f.events[event], callback)
    end, IsValid = function() return true end }
    flux.Combat = { InLockdown = function() return f.combat end,
        Defer = function(key, callback) f.pending = f.pending or {}; f.pending[key] = callback end }
    flux.Safecall = function(callback, ...) return callback(...) end
    flux.AfterLoad = function(callback) callback() end
    flux.Action = { HasAction = function(slot) return not (f.emptySlots and f.emptySlots[slot]) end,
        LeaveBlizzardCollector = function() return f.forever end,
        SweepFluxFromCollectors = function()
            assert(not f.combat, "collector sweeping is protected in combat")
            f.swept = f.swept + 1
        end }
    env.GetTime = function() return f.now end
    env.InCombatLockdown = function() return f.combat end
    env.GetShapeshiftForm = function() return f.form end
    env.GetBonusBarOffset = function() return 0 end
    env.GetActionBarPage = function() return f.page end
    env.UnitExists = function() return false end
    env.GetActionInfo = function() return "spell", 1 end
    env.HasAction = function() return true end
    env.IsShiftKeyDown = function() return f.shift end
    env.HasVehicleActionBar = function() return f.vehicle end
    env.GetVehicleBarIndex = function() return 12 end
    env.HasOverrideActionBar = function() return f.override end
    env.GetOverrideBarIndex = function() return 14 end
    env.HasTempShapeshiftActionBar = function() return f.temp end
    env.GetTempShapeshiftBarIndex = function() return 13 end
    env.HasBonusActionBar = function() return f.bonus end
    env.GetBonusBarIndex = function() return f.bonusPage or 11 end
    env.IsPossessBarVisible = function() return f.possess end
    if namespaced then
        env.C_ActionBar = {}
        for _, name in ipairs({ "HasVehicleActionBar", "GetVehicleBarIndex", "HasOverrideActionBar", "GetOverrideBarIndex",
            "HasTempShapeshiftActionBar", "GetTempShapeshiftBarIndex", "HasBonusActionBar", "GetBonusBarIndex", "IsPossessBarVisible" }) do
            env.C_ActionBar[name], env[name] = env[name], nil
        end
    end
    env.ActionBarButtonEventsFrame = { UnregisterEvent = function() f.collectorHeld = true end }
    env.ActionBarActionEventsFrame = { UnregisterAllEvents = function() f.collectorHeld = true end }
    B.ForEachHost = function(callback)
        for column = 1, 19 do
            for _, row in ipairs({ "main", "sec", "tert" }) do callback(B.hosts[column][row]) end
        end
    end
    for column = 1, 19 do
        B.hosts[column] = {}
        for rowIndex, row in ipairs({ "main", "sec", "tert" }) do
            B.hosts[column][row] = { column = column, row = row, slot = (rowIndex - 1) * 60 + column,
                widget = {}, values = {}, paints = {} }
        end
    end
    B.Hosts = { IndexSlot = function(host, slot) host.slot = slot end,
        LiveSlot = function(host) return host.slot end }
    B.State = { UsesSecurePaging = function() return not insecure end,
        GetCurrentPage = function() return f.page end,
        GetMainSlot = function(column, page) return (page - 1) * 12 + column end,
        ForceApply = function()
            assert(not f.combat, "secure paging must not restamp during combat")
            f.applies = f.applies + 1
        end,
        IndexLiveSlots = function()
            for column = 1, 12 do
                local host, slot = B.hosts[column].main, (f.page - 1) * 12 + column
                if host.slot ~= slot then B.Hosts.IndexSlot(host, slot); B.Paint.Dirty(host) end
            end
        end,
        ApplySlotsInsecure = function()
            if not f.combat then f.applies = f.applies + 1 end
            B.State.IndexLiveSlots()
        end }
    B.SlotProgram = { ApplyLiveType = function(host) host.faceSlot = host.slot end }
    B.Layout = { Request = function() f.layout = f.layout + 1 end }
    B.Strip = { SyncVisibility = function() end }
    B.Blizzard = { QueueLeftoverMouse = function() f.leftovers = (f.leftovers or 0) + 1 end }
    B.BadgeHost = { RefreshFormVisibility = function() f.badgeRefresh = (f.badgeRefresh or 0) + 1 end }
    B.RequestPaint = function(token) f.tokens[token] = true end
    B.RequestLayout = function() f.layout = f.layout + 1 end
    function f.load(path)
        local value = source(path)
        if mutation and mutation.path == path then value = mutation.change(value) end
        assert(load(value, "@" .. root .. path, "t", env))("_FluxUI", { Flux = flux })
    end
    f.load("Bars/Paint.lua")
    -- Replace only rendering/API boundary methods. Actual UpdateAll, Dirty and Flush run.
    for _, lane in ipairs({ "Icon", "Count", "Name", "Cooldown", "Usable", "Equipped", "Range", "Checked", "Hotkey",
        "AssistedCombat", "AssistedHighlight" }) do
        B.Paint["Update" .. lane] = function(host)
            host.values[lane] = host.slot * 1000 + (f.revision or 0)
            host.paints[lane] = (host.paints[lane] or 0) + 1
        end
    end
    B.Paint.NeedsRange = function() return false end
    function f.flush()
        local tokens = f.tokens; f.tokens = {}
        B.Paint.Flush(tokens)
    end
    f.load("Core/Engine/FormStorm.lua")
    local onSettled = flux.FormStorm.OnSettled
    flux.FormStorm.OnSettled = function(key, callback)
        if key == "bars.page" then f.settle = callback end
        onSettled(key, callback)
    end
    if context then
        if context ~= "fallback" then f.load("Core/Engine/Context.lua") end
        f.load("Bars/ProgramFace.lua")
        local extra = { ActionType = "macrotext", MacroBody = "/cast [form:1] FormSpell; BaseSpell" }
        flux.EBS = { buttons = { extra }, Action = { TranslateMatching = function(kinds)
            B.ProgramFace.EachExtraMatching(kinds, function(button)
                button.display = f.form == 1 and "FormSpell" or "BaseSpell"
                f.extraRefresh = (f.extraRefresh or 0) + 1
            end)
        end } }
        f.extra = extra
        B.ProgramFace.Start()
        if flux.Context then
            flux.Context.Subscribe(function(info) f.notifications[#f.notifications + 1] = info end)
            flux.Context.Request(true); f.advance(0)
        else
            B.ProgramFace.Request("form")
            f.advance(0.1) -- initial parse is outside the next form's normal rate window
        end
        f.extraRefresh = 0; f.notifications = {}
    else
        B.ProgramFace = { Request = function(kind) f.lastKind = kind end }
    end
    f.load("Bars/Watch.lua"); B.Watch.Start()
    f.load("Bars/Vehicle.lua")
    return f
end

local function pageRefresh(mutation, insecure, preindexed)
    local f = fixture(mutation, insecure, true)
    local B = f.B
    f.page, f.form, f.revision = 2, 1, 1
    if preindexed then
        f.revision = 0; B.State.IndexLiveSlots(); f.flush(); f.revision = 1
    end
    f.emit("UPDATE_SHAPESHIFT_FORM"); f.emit("UPDATE_BONUS_ACTIONBAR"); f.emit("ACTIONBAR_PAGE_CHANGED")
    f.advance(0); f.flush()
    for column = 1, 12 do
        local host = B.hosts[column].main
        check(host.slot == 12 + column, "native mains follow the new form/page")
        for _, lane in ipairs({ "Icon", "Count", "Cooldown", "Usable", "Equipped", "Checked" }) do
            check(host.values[lane] == host.slot * 1000 + 1, "form/page refreshes " .. lane .. " on every changed main")
        end
        if not insecure and not preindexed then check(host.faceSlot == host.slot, "live face rebinds before display") end
    end
    check(f.layout == 0, "any-state promotion requires no form/page relayout")
    check(f.extra.display == "FormSpell" and f.extraRefresh == 1, "Context refreshes Extra faces once at the form burst")
    check(#f.notifications == 1 and f.notifications[1].form and not f.notifications[1].force,
        "form option reaches subscribers despite an unchanged fingerprint without a forced reset")
    f.advance(0.25); f.flush()
    check(f.extraRefresh == 1, "quiet settle does not repeat conditional parsing")
    return f
end

local function heldRefresh(mutation, event, lane, quiet)
    local f = pageRefresh(mutation)
    -- Open a new form burst, flush it, then deliver an unrelated late value event.
    f.form, f.page, f.revision = 2, 3, 2
    f.emit("UPDATE_SHAPESHIFT_FORM"); f.advance(0); f.flush()
    local host = f.B.hosts[19].sec -- not a paged/dirty main
    f.revision = 3
    f.emit(event)
    check(not f.tokens["bars." .. lane:lower()], "form-window companions stay coalesced")
    if quiet == false then
        -- Also exercise the production subscriber's nonquiet delivery. The
        -- coalescer often makes native bursts quiet by consuming their tail.
        local before = #f.notifications
        f.settle(false); f.advance(0)
        check(#f.notifications == before + 1 and f.notifications[#f.notifications].form,
            "nonquiet settle delivers one Context form refresh")
    end
    f.advance(0.25); f.flush()
    check(host.values[lane] == host.slot * 1000 + 3, "held " .. event .. " replays " .. lane .. " after form settle")
    local paints = host.paints[lane]
    f.advance(1); f.flush()
    check(host.paints[lane] == paints, "held value replay occurs exactly once")
end

local function coalescedLanes(mutation)
    local f = fixture(mutation)
    local first, other = f.B.hosts[1].main, f.B.hosts[19].sec
    f.revision = 7
    f.B.Paint.Dirty(first)
    for _, lane in ipairs({ "icon", "count", "cooldown", "usable", "checked", "equipped", "range", "hotkey" }) do
        f.tokens["bars." .. lane] = true
    end
    f.flush()
    for _, lane in ipairs({ "Icon", "Count", "Cooldown", "Usable", "Checked", "Equipped", "Range", "Hotkey" }) do
        check(other.values[lane] == other.slot * 1000 + 7, "dirty paint preserves coalesced " .. lane .. " on unrelated hosts")
        check(first.paints[lane] == 1, "dirty host is painted once for coalesced " .. lane)
    end
    local before = other.paints.Icon
    f.B.Paint.Dirty(first); f.flush()
    check(other.paints.Icon == before, "dirty-only pass stays restricted to dirty hosts")
    f.revision = 8
    f.B.Paint.Dirty(first); f.tokens["bars.count"] = true; f.flush()
    check(other.values.Count == other.slot * 1000 + 8, "mixed dirty/count delivers the requested count")
    for _, lane in ipairs({ "Icon", "Cooldown", "Usable", "Checked", "Equipped", "Range", "Hotkey" }) do
        check(other.values[lane] == other.slot * 1000 + 7, "mixed dirty/count does not broaden the " .. lane .. " lane")
    end
end

local function iconEvents(mutation)
    local f = fixture(mutation)
    for revision, event in ipairs({ "SPELLS_CHANGED", "SPELL_UPDATE_ICON" }) do
        f.revision = revision
        f.emit(event); f.flush()
        local host = f.B.hosts[19].main
        check(host.values.Icon == host.slot * 1000 + revision, event .. " refreshes the actual icon lane")
    end
end

local function emptyMainHotkey(mutation)
    local f = fixture(mutation)
    local host = f.B.hosts[1].main
    f.emptySlots = { [host.slot] = true }
    f.tokens["bars.hotkey"] = true
    f.flush()
    check(host.values.Hotkey == host.slot * 1000, "empty main still paints its binding key")
    check(host.values.Icon == nil and host.values.Cooldown == nil, "hotkey-only empty pass does not broaden value lanes")
end

local function fallbackExtraFaces(mutation)
    local f = fixture(mutation, false, "fallback")
    f.form, f.page = 1, 2
    f.emit("UPDATE_SHAPESHIFT_FORM"); f.emit("ACTIONBAR_PAGE_CHANGED")
    f.advance(0); f.flush()
    check(f.extra.display == "FormSpell" and f.extraRefresh == 1,
        "shared ProgramFace hub refreshes Extra faces once when Context has no subscription")
    check(f.layout == 0, "fallback Extra form refresh does not restamp layout")
end

local function vehicleRefresh(mutation)
    local f = fixture(mutation)
    local B = f.B
    B.Vehicle.Start(); f.advance(0); f.flush()
    local applies = f.applies
    f.vehicle, f.page, f.revision, f.combat = true, 12, 1, true
    B.Vehicle.QueueApply()
    check(f.applies == applies, "vehicle event stack never forces secure attributes")
    f.advance(0); f.flush()
    check(f.applies == applies, "combat vehicle refresh does not force insecure paging")
    for column = 1, 12 do
        local host = B.hosts[column].main
        for _, lane in ipairs({ "Icon", "Count", "Cooldown", "Usable", "Equipped" }) do
            check(host.values[lane] == host.slot * 1000 + 1, "vehicle dirty path refreshes " .. lane)
        end
    end
    f.emit("UNIT_ENTERED_VEHICLE", "player"); f.emit("UPDATE_VEHICLE_ACTIONBAR"); f.emit("VEHICLE_UPDATE")
    f.advance(0); f.flush()
    check(f.applies == applies, "coalesced vehicle companion events stay combat safe")
    f.combat = false; f.emit("PLAYER_REGEN_ENABLED"); f.advance(0); f.flush()
    check(f.applies == applies + 1, "vehicle combat restamp flushes exactly once on regen")
    f.emit("PLAYER_REGEN_ENABLED"); f.emit("VEHICLE_UPDATE"); f.advance(0)
    check(f.applies == applies + 1, "unchanged vehicle and repeated regen do not restamp")
    f.combat, B.secureReady, f.collectorHeld = true, false, false
    B.Vehicle.OnReplacementsReady(); f.advance(0)
    check(not f.collectorHeld, "fresh combat startup preserves native collectors before replacements exist")
    f.forever, B.secureReady, f.collectorHeld = true, true, false
    B.Vehicle.OnReplacementsReady(); f.advance(0)
    check(not f.collectorHeld, "Forever preserves the native controller's collector updates")
end

local function controlTransitions(namespaced)
    local f = fixture(nil, false, nil, namespaced)
    local B = f.B
    B.Vehicle.Start(); f.advance(0); f.flush()
    local applies = f.applies
    f.combat = true
    for _, transition in ipairs({
        { "possess", 11 }, { "bonus", 11 }, { "temp", 13 },
        { "override", 14 }, { "vehicle", 12 }, { "bonus", 11 }, { "normal", 1 },
    }) do
        f.vehicle, f.override, f.bonus, f.temp, f.possess = false, false, false, false, false
        f[transition[1]], f.page = true, transition[2]
        f.revision = transition[2]
        local leftovers = f.leftovers
        f.emit("UPDATE_POSSESS_BAR"); f.emit("UPDATE_POSSESS_BAR")
        check(f.leftovers == leftovers, "possession event never performs native layout inline")
        f.advance(0); f.flush()
        check(f.leftovers == leftovers + 1, "all temporary control entries/exits refresh once, including possession-only changes")
        check(f.applies == applies, "temporary control changes never force insecure combat paging")
        for column = 1, 12 do
            local host = B.hosts[column].main
            check(host.slot == (f.page - 1) * 12 + column and host.values.Icon == host.slot * 1000 + f.revision,
                "possession/bonus/temporary/override/vehicle entry and exit refresh the live action")
        end
    end
    f.combat = false; f.emit("PLAYER_REGEN_ENABLED"); f.advance(0); f.flush()
    check(f.applies == applies + 1, "temporary control combat work drains once on regen")
    local leftovers = f.leftovers
    f.emit("UPDATE_POSSESS_BAR"); f.advance(0)
    check(f.leftovers == leftovers, "unchanged possession notification remains idle after recovery")
    local syncedPage = B.State.GetCurrentPage
    B.State.GetCurrentPage = function() return 1 end
    f.possess, f.page = true, 11
    f.emit("UPDATE_POSSESS_BAR"); f.advance(0)
    check(f.applies == applies + 2, "out-of-combat possession-only entry repairs a stale ordinary page")
    B.State.GetCurrentPage = function() return 11 end
    f.possess, f.page = false, 1
    f.emit("UPDATE_POSSESS_BAR"); f.advance(0)
    check(f.applies == applies + 3, "out-of-combat possession exit repairs a stale control page")
    B.State.GetCurrentPage = syncedPage
    f.load("Bars/SlotMath.lua"); f.load("Bars/State.lua")
    for _, native in ipairs({ "possess", "shapeshift", "dragon" }) do
        B.State.headers = { main = { GetAttribute = function(_, name)
            if name == "state-native" then return native end
        end } }
        check(B.State.GetCurrentPage() == 11, "temporary token without a usable index matches the secure resolver fallback")
    end
end

local function upvalue(fn, wanted, seen)
    seen = seen or {}
    if type(fn) ~= "function" or seen[fn] then return end
    seen[fn] = true
    for i = 1, math.huge do
        local name, value = debug.getupvalue(fn, i)
        if not name then break end
        if name == wanted then return value end
        if type(value) == "function" then
            local found = upvalue(value, wanted, seen)
            if found then return found end
        end
    end
end

local function promotedPages(mutation, insecure, client)
    local f = fixture(mutation)
    local B, env, flux = f.B, f.env, f.flux
    flux.Client = { branch = client or "live", isForever = client == "forever", isCamelot = client == "forever" }
    local onAction
    local function widget(host)
        local frame = { attributes = {}, _fluxHost = host }
        function frame:GetAttribute(name) return self.attributes[name] end
        function frame:SetAttribute(name, value)
            assert(not f.combat or f.secureExecuting, "promoted protected writes require a secure snippet in combat")
            self.attributes[name] = value
            if name == "flux-promoted" or name == "flux-has-sec" or name == "flux-has-tert" then
                f.mappingWrites = (f.mappingWrites or 0) + 1
            end
            if name == "action" and onAction then onAction(self, name, value) end
        end
        return frame
    end
    flux.Restricted = { PagingWorks = function() return not insecure end,
        SetPagingSnippet = function(frame, name, body)
            if insecure then return false end
            frame:SetAttribute(name, body); return true
        end }
    f.load("Bars/SlotMath.lua")
    f.load("Bars/State.lua")
    f.load("Bars/Hosts.lua")
    f.load("Bars/Layout.lua")
    local State, Layout = B.State, B.Layout
    onAction = assert(upvalue(B.Hosts.CreateSurface, "OnActionAttribute"), "real action attribute callback is reachable")
    local header = { GetAttribute = function(_, name)
        if name == "actionpage" then return f.page end
        if name == "state-native" then return tostring(f.page) end
    end }
    State.headers = { main = header }
    B.SlotProgram.ApplyLiveType = function(host) host.faceSlot, host._fluxFaceSlot = host.slot, host.slot end
    local modes = { [1] = 1, [2] = 2, [3] = 3, [13] = 1, [14] = 2, [15] = 3 }
    local occupied = {}
    for column, mode in pairs(modes) do
        if mode ~= 2 then occupied[State.GetSecondarySlot(column)] = true end
        if mode ~= 1 then occupied[State.GetTertiarySlot(column)] = true end
    end
    -- Column 4 is empty on the current page but populated on another form.
    -- Its minis must never promote, including after temporary vehicle contents.
    occupied[76], occupied[64], occupied[28] = true, true, true
    flux.Action.HasAction = function(slot) return occupied[slot] or false end
    env.HasAction = flux.Action.HasAction
    env.IsControlKeyDown = function() return f.ctrl end
    env.GetCursorInfo = function() return nil end
    B.ForEachHost(function(host)
        host.widget = widget(host)
        State.Attach(header, host.widget, host.column, host.row)
    end)
    Layout.ApplyMappings()
    for column, mode in pairs(modes) do
        check(B.hosts[column].main._fluxPromoted == mode, "real mapping establishes secondary/tertiary/both promotion")
    end
    check(not B.hosts[4].main._fluxPromoted and not Layout.GetPromotedMode(4),
        "main occupancy on another form prevents promotion on an empty current page")
    local function runChildren()
        B.ForEachHost(function(host)
            local body = host.widget:GetAttribute("_childupdate-state")
            check(type(body) == "string", "secure promotion runs the production stored child snippet")
            env.self, env.message = host.widget, tostring(B.SlotMath.Pack(f.page, f.swap or 0))
            f.secureExecuting = true
            assert(load(body, "promoted-child-update", "t", env))()
            f.secureExecuting = false
        end)
    end
    if insecure then State.ApplySlotsInsecure() else runChildren() end
    f.flush()
    f.layout, f.mappingWrites = 0, 0
    local function assertSelection()
        for column, mode in pairs(modes) do
            local host = B.hosts[column].main
            local secondary, tertiary
            if column <= 12 then secondary, tertiary = 60 + column, 24 + column
            else secondary, tertiary = 48 + column - 12, 36 + column - 12 end
            local takeover = column <= 12 and f.page >= 11
            local expected = mode == 2 and tertiary or secondary
            if mode == 3 and f.swap ~= 0 then expected = tertiary end
            if takeover then expected = (f.page - 1) * 12 + column end
            check(host.slot == expected, "promoted display preserves ordinary pages and follows vehicle/override takeover")
            if not (insecure and f.combat) then
                check(host.widget:GetAttribute("action") == expected,
                    "promoted input follows the actual secure snippet or legal fallback")
                for swap, prefix in ipairs({ "action*", "shift-action*", "ctrl-action*" }) do
                    local click = mode == 2 and tertiary or secondary
                    if mode == 3 and swap ~= 1 then click = tertiary end
                    if takeover then click = (f.page - 1) * 12 + column end
                    check(host.widget:GetAttribute(prefix) == click,
                        "promoted nomod/SHIFT/CTRL click sets survive native page transitions")
                end
            end
            check(host._fluxPromoted == mode and host.widget:GetAttribute("flux-promoted") == mode,
                "temporary vehicle/override contents preserve ordinary promotion flags")
            if mode == 3 then
                local leftover = B.hosts[column].tert
                local leftoverSlot = takeover and tertiary or (f.swap == 0 and tertiary or secondary)
                check(leftover.slot == leftoverSlot, "both-promoted leftover mini preserves inversion and vehicle reset")
            end
        end
        check(not B.hosts[4].main._fluxPromoted, "form occupancy never creates temporary promotion")
        check(f.layout == 0 and f.mappingWrites == 0, "form/page promotion requires no layout or structural flag restamp")
    end
    -- Test real slot math and secure bodies before and after the insecure Watch
    -- burst, including already-in-combat visual-only fallback on old clients.
    for _, transition in ipairs({ { page = 7 }, { page = 9, combat = true },
        { page = 12, vehicle = true, combat = true }, { page = 14, override = true, combat = true },
        { page = 1, combat = true }, { page = 10 } }) do
        f.page, f.vehicle, f.override, f.combat = transition.page, transition.vehicle, transition.override, transition.combat or false
        for swap = 0, 2 do
            f.swap, f.shift, f.ctrl = swap, swap == 1, swap == 2
            -- Execute true secure click configuration only through its stored
            -- body. The insecure fallback reindexes displays legally in combat.
            if insecure then State.ApplySlotsInsecure() else runChildren() end
            State.IndexLiveSlots()
            f.emit("ACTIONBAR_PAGE_CHANGED"); f.emit("UPDATE_SHAPESHIFT_FORM")
            f.advance(0); f.flush()
            assertSelection()
            f.advance(0.25); f.flush()
            assertSelection()
        end
    end
end

pageRefresh(nil, false, false)
pageRefresh(nil, false, true)
pageRefresh(nil, true, false)
coalescedLanes()
iconEvents()
emptyMainHotkey()
fallbackExtraFaces()
vehicleRefresh()
controlTransitions(false)
controlTransitions(true)
for _, client in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    promotedPages(nil, false, client)
end
promotedPages(nil, true, "forever")
for _, quiet in ipairs({ true, false }) do
    heldRefresh(nil, "SPELL_UPDATE_ICON", "Icon", quiet)
    heldRefresh(nil, "SPELLS_CHANGED", "Icon", quiet)
    heldRefresh(nil, "SPELL_UPDATE_CHARGES", "Count", quiet)
    heldRefresh(nil, "ACTIONBAR_UPDATE_COOLDOWN", "Cooldown", quiet)
    heldRefresh(nil, "ACTIONBAR_UPDATE_USABLE", "Usable", quiet)
    heldRefresh(nil, "ACTIONBAR_UPDATE_STATE", "Checked", quiet)
end

-- Deliberately break production paths: each behavioral assertion must reject it.
local mutations = {
    { name = "dirty lane loss", path = "Bars/Paint.lua", run = coalescedLanes,
        change = function(src)
            local n; src, n = src:gsub("if not anyLane then", "if hasDirty or not anyLane then", 1)
            assert(n == 1); return src
        end },
    { name = "lost held icon", path = "Bars/Watch.lua", run = function(m) heldRefresh(m, "SPELL_UPDATE_ICON", "Icon", true) end,
        change = function(src)
            local n; src, n = src:gsub('local needIcon = formIconHeld', 'local needIcon = false', 1)
            assert(n == 1); return src
        end },
    { name = "lost held usable", path = "Bars/Watch.lua", run = function(m) heldRefresh(m, "ACTIONBAR_UPDATE_USABLE", "Usable", true) end,
        change = function(src)
            local n; src, n = src:gsub('local needUsable = formUsableHeld', 'local needUsable = false', 1)
            assert(n == 1); return src
        end },
    { name = "lost held cooldown", path = "Bars/Watch.lua", run = function(m) heldRefresh(m, "ACTIONBAR_UPDATE_COOLDOWN", "Cooldown", true) end,
        change = function(src)
            local n; src, n = src:gsub('local needCooldown = formCooldownHeld', 'local needCooldown = false', 1)
            assert(n == 1); return src
        end },
    { name = "lost held count", path = "Bars/Watch.lua", run = function(m) heldRefresh(m, "SPELL_UPDATE_CHARGES", "Count", true) end,
        change = function(src)
            local n; src, n = src:gsub('local needCount = formCountHeld', 'local needCount = false', 1)
            assert(n == 1); return src
        end },
    { name = "lost held checked", path = "Bars/Watch.lua", run = function(m) heldRefresh(m, "ACTIONBAR_UPDATE_STATE", "Checked", true) end,
        change = function(src)
            local n; src, n = src:gsub('local needChecked = formCheckedHeld', 'local needChecked = false', 1)
            assert(n == 1); return src
        end },
    { name = "lost icon owner", path = "Bars/Watch.lua", run = iconEvents,
        change = function(src)
            local n; src, n = src:gsub('Ev.Register%("SPELLS_CHANGED", OnIconEvent%)', '', 1)
            assert(n == 1); return src
        end },
    { name = "lost Context form option", path = "Core/Engine/Context.lua", run = pageRefresh,
        change = function(src)
            local n; src, n = src:gsub('refreshForm = true', 'refreshForm = false', 1)
            assert(n == 1); return src
        end },
    { name = "lost Extra fanout", path = "Bars/ProgramFace.lua", run = pageRefresh,
        change = function(src)
            local n; src, n = src:gsub('if extraHit and Action and Action.TranslateMatching then', 'if false then', 1)
            assert(n == 1); return src
        end },
    { name = "lost page dirty", path = "Bars/Watch.lua", run = function(m) pageRefresh(m, false, true) end,
        change = function(src)
            local n; src, n = src:gsub('Bars.Paint.Dirty%(mainHost%)', '', 1)
            assert(n == 1); return src
        end },
    { name = "lost vehicle dirty", path = "Bars/Vehicle.lua", run = vehicleRefresh,
        change = function(src)
            local n; src, n = src:gsub('Bars.State.IndexLiveSlots%(%)', '', 1)
            assert(n == 1); return src
        end },
    { name = "lost empty main hotkey", path = "Bars/Paint.lua", run = emptyMainHotkey,
        change = function(src)
            local n; src, n = src:gsub('if applyHotkey and hotkey then', 'if false then', 1)
            assert(n == 1); return src
        end },
    { name = "lost fallback Extra fanout", path = "Bars/ProgramFace.lua", run = fallbackExtraFaces,
        change = function(src)
            local n; src, n = src:gsub('if Action and Action.TranslateMatching then', 'if false then', 1)
            assert(n == 1); return src
        end },
    { name = "lost promotion preservation", path = "Bars/Watch.lua", run = promotedPages,
        change = function(src)
            local n; src, n = src:gsub('if mainHost and %(not mainHost%._fluxPromoted or page >= 11%) then',
                'if mainHost then', 1)
            assert(n == 1); return src
        end },
    { name = "lost secure promotion takeover", path = "Bars/State.lua", run = promotedPages,
        change = function(src)
            local n; src, n = src:gsub('if static == 0 and page >= 11 then', 'if false then', 1)
            assert(n == 1); return src
        end },
    { name = "lost slot promotion", path = "Bars/SlotMath.lua", run = promotedPages,
        change = function(src)
            local n; src, n = src:gsub('local promoted = tonumber%(opts%.promoted%) or 0', 'local promoted = 0', 1)
            assert(n == 1); return src
        end },
    { name = "lost any-state occupancy", path = "Bars/Layout.lua", run = promotedPages,
        change = function(src)
            local n; src, n = src:gsub('if not expanding and not Layout%.HasContentInAnyState%(column%) then',
                'if not expanding and not Layout.HasContentOnMain(column) then', 1)
            assert(n == 1); return src
        end },
    { name = "lost fallback promotion", path = "Bars/State.lua", run = function(m) promotedPages(m, true, "forever") end,
        change = function(src)
            local n; src, n = src:gsub('promoted = tonumber%(widget:GetAttribute%("flux%-promoted"%)%) or 0',
                'promoted = 0', 1)
            assert(n == 1); return src
        end },
    { name = "unnecessary page relayout", path = "Bars/Watch.lua", run = promotedPages,
        change = function(src)
            local n; src, n = src:gsub('local function OnPageOrForm%(%)',
                'local function OnPageOrForm()\n        Bars.Layout.Request("page")', 1)
            assert(n == 1); return src
        end },
}
local expectedFailures = {
    ["dirty lane loss"] = "dirty paint preserves coalesced Icon on unrelated hosts",
    ["lost held icon"] = "held SPELL_UPDATE_ICON replays Icon after form settle",
    ["lost held usable"] = "held ACTIONBAR_UPDATE_USABLE replays Usable after form settle",
    ["lost held cooldown"] = "held ACTIONBAR_UPDATE_COOLDOWN replays Cooldown after form settle",
    ["lost held count"] = "held SPELL_UPDATE_CHARGES replays Count after form settle",
    ["lost held checked"] = "held ACTIONBAR_UPDATE_STATE replays Checked after form settle",
    ["lost icon owner"] = "SPELLS_CHANGED refreshes the actual icon lane",
    ["lost Context form option"] = "Context refreshes Extra faces once at the form burst",
    ["lost Extra fanout"] = "Context refreshes Extra faces once at the form burst",
    ["lost page dirty"] = "form/page refreshes Count on every changed main",
    ["lost vehicle dirty"] = "vehicle dirty path refreshes Icon",
    ["lost empty main hotkey"] = "empty main still paints its binding key",
    ["lost fallback Extra fanout"] = "shared ProgramFace hub refreshes Extra faces once when Context has no subscription",
    ["lost promotion preservation"] = "promoted display preserves ordinary pages and follows vehicle/override takeover",
    ["lost secure promotion takeover"] = "promoted input follows the actual secure snippet or legal fallback",
    ["lost slot promotion"] = "promoted display preserves ordinary pages and follows vehicle/override takeover",
    ["lost any-state occupancy"] = "main occupancy on another form prevents promotion on an empty current page",
    ["lost fallback promotion"] = "promoted display preserves ordinary pages and follows vehicle/override takeover",
    ["unnecessary page relayout"] = "form/page promotion requires no layout or structural flag restamp",
}
for _, mutation in ipairs(mutations) do
    mutation.expected = assert(expectedFailures[mutation.name], "mutation requires its intended failed expectation")
    local ok, err = pcall(mutation.run, mutation)
    check(not ok and tostring(err):find("bars refresh expectation: " .. mutation.expected, 1, true),
        "regression must reject mutation at its intended assertion: " .. mutation.name .. "; got " .. tostring(err))
end

print("bars refresh: " .. checks .. " checks passed; " .. #mutations .. " production mutations rejected")
return { pagePromotion = true, formBurstLanes = true, formSettleLanes = true, contextBurst = true,
    contextSettle = true, sharedExtraRefresh = true, iconEvents = true, vehicleLanes = true,
    mixedDirtyLanes = true, emptyMainHotkey = true, mutationChecks = #mutations }
