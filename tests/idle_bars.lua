-- Production idle-path replay; operation counts are not in-game FPS claims.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local checks = 0
local function check(value, message)
    assert(value, "idle bars: " .. message)
    checks = checks + 1
end
local function source(path)
    local file = assert(io.open(root .. path, "rb"))
    local value = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return value
end
local function fixture(branch, change)
    change = change or FLUX_IDLE_MUTATION
    local f = { now = 1, frames = {}, timers = {}, probes = 0, callbacks = 0,
        class = "-", scheduled = 0, native = 0, unitQueries = 0, parses = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local flux = { Bars = {}, EBS = { buttons = {} }, Client = { isForever = branch == "forever", isCamelot = branch == "forever" },
        Cap = { hasRestrictedClosures = branch ~= "forever" } }
    f.flux, f.env = flux, env
    env.GetTime = function() return f.now end
    env.InCombatLockdown = function() return f.combat end
    env.CreateFrame = function(_, name)
        local frame = { name = name, shown = true, scripts = {}, attributes = {}, events = {} }
        function frame:Hide() self.shown = false end
        function frame:Show() self.shown = true end
        function frame:IsShown() return self.shown end
        function frame:SetScript(event, callback) self.scripts[event] = callback end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:GetName() return self.name end
        function frame:GetAttribute(key) return self.attributes[key] end
        function frame:SetAttribute(key, value)
            assert(not f.combat, "protected mutation in lockdown")
            self.attributes[key] = value
        end
        function frame:SetAlpha(value) assert(not f.combat); self.alpha = value end
        function frame:Execute() self.attributes["flux-paging-probe"] = 1 end
        f.frames[#f.frames + 1] = frame
        return frame
    end
    local function after(delay, callback)
        f.timers[#f.timers + 1] = { at = f.now + delay, callback = callback }
    end
    flux.Timer = { After = after }
    flux.Range = { UnitReactionClass = function() f.probes = f.probes + 1; return f.class end,
        MouseoverReactionClass = function() f.probes = f.probes + 1; return f.class end }
    flux.Scheduler = { Request = function(_, _, callback)
        f.scheduled = f.scheduled + 1
        if callback then callback() end
    end }
    flux.Safecall = function(callback, ...) return callback(...) end
    f.events = {}
    flux.Events = { Register = function(event, callback)
        f.events[event] = f.events[event] or {}
        table.insert(f.events[event], callback)
    end, IsValid = function() return true end }
    f.body = "/cast [@mouseover,help,nodead] Heal; Damage"
    flux.Bars.SlotProgram = { GetAll = function() return { [1] = f.body } end,
        Get = function(slot) if slot == 1 then return f.body end end }
    flux.Bars.ForEachHost = function() end
    env.UnitExists = function(unit)
        f.unitQueries = f.unitQueries + 1
        if f.context then return unit == "mouseover" and f.class ~= "-" end
        return f.exists
    end
    env.UnitIsDead = function() return f.class == "d" end
    env.UnitCanAttack = function() return f.class == "e" end
    env.UnitCanAssist = function() return f.class == "f" end
    env.SecureCmdOptionParse = function(values)
        f.parses = f.parses + 1
        if values:find("petbattle", 1, true) then return f.petbattle and "hide" or "show" end
        if values == "nil-result" then return nil end
        return f.value or "1"
    end
    for _, name in ipairs({ "RegisterAttributeDriver", "UnregisterAttributeDriver", "RegisterStateDriver",
        "UnregisterStateDriver", "RegisterUnitWatch", "UnregisterUnitWatch" }) do
        env[name] = function() f.native = f.native + 1 end
    end
    function f.load(path)
        local value = source(path)
        if change then value = change(path, value) end
        assert(load(value, "@" .. path, "t", env))("_FluxUI", { Flux = flux })
    end
    function f.step(elapsed)
        f.now = f.now + elapsed
        for _, frame in ipairs(f.frames) do
            if frame.shown and frame.scripts.OnUpdate then
                f.callbacks = f.callbacks + 1
                frame.scripts.OnUpdate(frame, elapsed)
            end
        end
        for i = #f.timers, 1, -1 do
            if f.timers[i].at <= f.now then table.remove(f.timers, i).callback() end
        end
    end
    function f.idle(seconds, fps)
        for _ = 1, seconds * fps do f.step(1 / fps) end
    end
    function f.event(event)
        for _, callback in ipairs(f.events[event] or {}) do callback(event) end
        for _, frame in ipairs(f.frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event) end
        end
    end
    f.load("Core/Engine/Ticker.lua")
    return f
end

local baseline = arg[1] == "--baseline"
local function replace(value, old, replacement)
    local at = assert(value:find(old, 1, true), "mutation anchor missing: " .. old)
    return value:sub(1, at - 1) .. replacement .. value:sub(at + #old)
end
local function before(path, value)
    if path == "Bars/ProgramFace.lua" then
        value = replace(value, '\tif ReactionClass() == "-" then\n\t\tDisarmMouseoverPoll()\n\t\treturn\n\tend\n', '')
        local first = assert(value:find('\t\tif class == "-" then', 1, true))
        local last = assert(value:find('\t\tif class == moPollName then', first, true))
        value = value:sub(1, first - 1) .. value:sub(last)
    elseif path == "Core/Engine/Restricted.lua" then
        local first = assert(value:find('\tlocal newValue = parsedDrivers[values]', 1, true))
        local last = assert(value:find('\tif attribute == "state-visibility" then', first, true))
        value = value:sub(1, first - 1) .. '\tlocal newValue = SecureCmdOptionParse(values)\n' .. value:sub(last)
        value = replace(value, '\tif asState then\n', '\tlocal unit = FrameUnit(frame)\n\tlocal exists = unit and UnitExists(unit)\n\tif asState then\n')
        value = replace(value, '\t\tlocal unit = FrameUnit(frame)\n\t\tlocal exists = unit and UnitExists(unit)\n', '')
    end
    return value
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    local f = fixture(branch, baseline and before)
    f.load("Bars/ProgramFace.lua")
    local PF = f.flux.Bars.ProgramFace
    PF.RebuildIndex()
    local startProbes = f.probes
    f.idle(60, 240)
    if baseline then
        print(branch .. " mouseover idle: " .. f.callbacks .. " frame callbacks, " .. (f.probes - startProbes) .. " reaction probes")
    else
        check(f.callbacks == 0 and f.probes == startProbes, branch .. " mouseover poll sleeps with no unit")
        f.class = "e"
        PF.NoteMouseoverEvent()
        check(f.flux.Ticker.Count() == 1, branch .. " mouseover arrival wakes without a layout pass")
        f.idle(1, 240)
        check(f.scheduled == 1, branch .. " arrival translates after existing debounce")
        local callbacks, probes, scheduled = f.callbacks, f.probes, f.scheduled
        f.idle(1, 240)
        check(f.callbacks - callbacks == 240 and f.probes - probes >= 14 and f.probes - probes <= 15,
            branch .. " existing active watch cadence retained")
        check(f.scheduled == scheduled, branch .. " stable active reaction does not retranslate")
        f.class = "f"
        f.idle(0.1, 240)
        check(f.scheduled == scheduled + 1, branch .. " live reaction changes still translate")
        f.class = "d"
        f.idle(0.1, 240)
        check(f.scheduled == scheduled + 2, branch .. " mouseover death without UMU still translates")
        f.class = "-"
        f.idle(0.1, 240)
        check(f.flux.Ticker.Count() == 0 and f.scheduled == scheduled + 3,
            branch .. " omitted leave event clears face once and sleeps")
        callbacks, probes = f.callbacks, f.probes
        f.idle(1, 240)
        check(f.callbacks == callbacks and f.probes == probes, branch .. " remains asleep after missing leave")
        f.class = "e"
        PF.NoteMouseoverEvent()
        for _ = 1, 60 do f.step(0.005); PF.NoteMouseoverEvent() end
        check(f.scheduled == scheduled + 3, branch .. " hop storm keeps trailing debounce")
        f.idle(0.3, 240)
        check(f.scheduled == scheduled + 4 and f.flux.Ticker.Count() == 1,
            branch .. " return after sleep resumes normal parsing")
        f.body = "/cast Heal"
        PF.InvalidateIndex(); PF.RebuildIndex()
        check(f.flux.Ticker.Count() == 0, branch .. " removal of last mouseover macro disarms")
        f.body = "/cast [@mouseover] Heal"
        PF.InvalidateIndex(); PF.NoteMouseoverEvent()
        f.idle(0.3, 240)
        check(f.flux.Ticker.Count() == 1, branch .. " dirty index wakes after coalesced rebuild")
        local cf = fixture(branch)
        cf.context = true
        cf.load("Core/Engine/Context.lua"); cf.load("Bars/ProgramFace.lua")
        local cpf = cf.flux.Bars.ProgramFace
        cpf.RebuildIndex(); cpf.Start()
        cf.class = "e"; cf.event("UPDATE_MOUSEOVER_UNIT")
        check(cf.flux.Ticker.Count() == 1, branch .. " subscribed Context wakes missing-leave watchdog")
        cf.idle(1, 240)
        cf.class = "-"; cf.idle(0.1, 240)
        check(cf.flux.Ticker.Count() == 0, branch .. " Context-owned mouseover still sleeps after missing leave")
        cf.class = "e"; cf.event("UPDATE_MOUSEOVER_UNIT")
        check(cf.flux.Ticker.Count() == 1, branch .. " unchanged Context fingerprint still wakes watchdog")
    end
end

local rf = fixture("forever", baseline and before)
rf.load("Core/Engine/Restricted.lua")
local R = rf.flux.Restricted
local drivers = {}
for i = 1, 12 do
    local frame = rf.env.CreateFrame("Frame", "FluxIdleDriver" .. i)
    drivers[i] = frame
    R.RegisterStateDriver(frame, "visibility", "[petbattle] hide; show")
    R.RegisterStateDriver(frame, "native", "[form:1] 7; 1")
    R.RegisterStateDriver(frame, "empty", "nil-result")
end
for i = 1, 57 do
    local frame = rf.env.CreateFrame("Frame", "FluxIdleWatch" .. i)
    frame.attributes.unit = "target"
    R.RegisterUnitWatch(frame)
end
rf.parses, rf.unitQueries, rf.callbacks = 0, 0, 0
rf.idle(60, 240)
print("Forever fallback: " .. rf.callbacks .. " frame callbacks, " .. rf.parses .. " parses, " .. rf.unitQueries .. " unit queries")
if not baseline then
    check(rf.parses == 900, "repeated fallback driver bodies parse once per sweep, including nil")
    check(rf.unitQueries == 0, "normal fallback watches never query existence they do not use")
    for _, frame in ipairs(drivers) do
        check(frame:IsShown() and frame:GetAttribute("state-native") == 1,
            "deduplicated parser still applies every frame's driver")
    end
    rf.petbattle, rf.value = true, "7"
    rf.event("UPDATE_SHAPESHIFT_FORM")
    for _, frame in ipairs(drivers) do
        check(not frame:IsShown() and frame:GetAttribute("state-native") == 7,
            "event invalidates shared parse snapshot immediately")
    end
    rf.combat, rf.petbattle, rf.value = true, false, "2"
    local parses = rf.parses
    rf.event("MODIFIER_STATE_CHANGED"); rf.idle(1, 240)
    check(rf.parses == parses, "Forever fallback attempts no parsing or protected writes in lockdown")
    for _, frame in ipairs(drivers) do
        check(not frame:IsShown() and frame:GetAttribute("state-native") == 7, "combat retains legally configured state")
    end
    rf.combat = false; rf.event("PLAYER_REGEN_ENABLED")
    for _, frame in ipairs(drivers) do
        check(frame:IsShown() and frame:GetAttribute("state-native") == 2, "regen reconciles existing driver frames")
    end
    local stateWatch = rf.env.CreateFrame("Frame", "FluxStateWatch")
    stateWatch.attributes.unit = "target"; rf.exists = true
    R.RegisterUnitWatch(stateWatch, true)
    check(stateWatch.attributes["state-unitexists"] == true, "as-state unitwatch preserves existence handling")
    rf.exists = false; rf.event("PLAYER_TARGET_CHANGED")
    check(stateWatch.attributes["state-unitexists"] == false, "as-state unitwatch reacts to unit loss")
    R.UnregisterUnitWatch(stateWatch)
    for _, frame in ipairs(rf.frames) do
        if frame.name and frame.name:match("^FluxIdleWatch") then R.UnregisterUnitWatch(frame) end
    end
    for _, frame in ipairs(drivers) do R.UnregisterAttributeDriver(frame) end
    local callbacks = rf.callbacks; rf.idle(1, 240)
    check(callbacks == rf.callbacks, "last fallback unregister disarms its frame")
    for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic" }) do
        local nf = fixture(branch); nf.load("Core/Engine/Restricted.lua")
        local native = nf.env.CreateFrame("Frame", "FluxNativeDriver")
        check(nf.flux.Restricted.Works() and nf.flux.Restricted.PagingWorks(), branch .. " keeps native restricted policy")
        nf.flux.Restricted.RegisterStateDriver(native, "native", "[mod] 2; 1")
        nf.flux.Restricted.RegisterUnitWatch(native)
        nf.idle(1, 240)
        check(nf.native == 2 and nf.parses == 0 and nf.callbacks == 0, branch .. " bypasses Forever compatibility fallback")
    end
    local ff = fixture("forever"); ff.load("Core/Engine/Restricted.lua")
    ff.combat = true
    local frames = #ff.frames
    check(not ff.flux.Restricted.PagingWorks() and #ff.frames == frames, "Forever defers secure capability probe in combat")
    ff.combat = false
    check(not ff.flux.Restricted.Works() and ff.flux.Restricted.PagingWorks(),
        "Forever native paging support remains distinct from legacy restricted policy")
    local header = ff.env.CreateFrame("Frame", "FluxPagingHeader")
    check(ff.flux.Restricted.RegisterPagingDriver(header, "native", "[mod] 2; 1") and ff.native == 1,
        "repaired Forever paging uses captured Blizzard native entry point")
    ff.flux.Restricted.RegisterUnitWatch(header)
    check(ff.native == 1, "Forever unitwatch still uses compatibility fallback despite repaired paging")
    local mutations = {
        { "idle watchdog", "mouseover poll sleeps with no unit", function(path, value)
            if path == "Bars/ProgramFace.lua" then
                return replace(value, '\tif ReactionClass() == "-" then\n\t\tDisarmMouseoverPoll()\n\t\treturn\n\tend\n', '')
            end
            return value
        end },
        { "missing leave", "omitted leave event clears face once and sleeps", function(path, value)
            if path == "Bars/ProgramFace.lua" then
                return replace(value, '\t\t\tRequestMouseoverNow()\n\t\t\tDisarmMouseoverPoll()\n', '\t\t\tRequestMouseoverNow()\n')
            end
            return value
        end },
        { "fallback wake", "mouseover arrival wakes without a layout pass", function(path, value)
            if path == "Bars/ProgramFace.lua" then
                return replace(value, '\tProgramFace.WakeMouseoverPoll()\n', '')
            end
            return value
        end },
        { "Context wake", "subscribed Context wakes missing-leave watchdog", function(path, value)
            if path == "Core/Engine/Context.lua" then
                return replace(value, '\t\tPF.WakeMouseoverPoll()\n', '')
            end
            return value
        end },
        { "nil parse memo", "repeated fallback driver bodies parse once per sweep", function(path, value)
            if path == "Core/Engine/Restricted.lua" then
                return replace(value, 'parsedDrivers[values] = newValue == nil and NO_DRIVER_VALUE or newValue',
                    'parsedDrivers[values] = newValue')
            end
            return value
        end },
        { "unused existence", "normal fallback watches never query existence", function(path, value)
            if path == "Core/Engine/Restricted.lua" then
                value = replace(value, '\tif asState then\n', '\tlocal unit = FrameUnit(frame)\n\tlocal exists = unit and UnitExists(unit)\n\tif asState then\n')
                return replace(value, '\t\tlocal unit = FrameUnit(frame)\n\t\tlocal exists = unit and UnitExists(unit)\n', '')
            end
            return value
        end },
        { "combat safety", "attempts no parsing or protected writes in lockdown", function(path, value)
            if path == "Core/Engine/Restricted.lua" then
                return replace(value, 'return InCombatLockdown and InCombatLockdown() or false', 'return false')
            end
            return value
        end },
    }
    if arg[1] ~= "--mutant" then
        for _, mutation in ipairs(mutations) do
            local scope = setmetatable({ FLUX_IDLE_MUTATION = mutation[3],
                arg = { [0] = arg[0], "--mutant" }, print = function() end }, { __index = _G })
            scope._G = scope
            local ok, err = pcall(assert(load(source("tests/idle_bars.lua"), "@idle mutation", "t", scope)))
            check(not ok and tostring(err):find(mutation[2], 1, true),
                mutation[1] .. " mutation must fail the intended contract: " .. tostring(err))
        end
        print("idle bars: " .. checks .. " checks passed; " .. #mutations .. " production mutations rejected")
    end
end
