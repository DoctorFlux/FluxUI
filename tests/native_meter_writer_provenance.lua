-- Explicit native-field provenance model, not WoW's secure VM. Native callbacks
-- from C++ widget geometry/visibility remain a separate required client check.
local source = arg[1] or "Battlezonemap/FluxBlizzardMeter.lua"
local originalArgs = arg; arg = { source, "--harness" }
local harness = assert(loadfile("tests/native_meter_ownership.lua"))(); arg = originalArgs
local checks, failures = 0, 0
local function check(value, label)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. label) end
end
for _, gamepad in ipairs({ false, true }) do
    local e, s = harness(gamepad)
    local trusted, writes, tainted = false, {}, {}
    local privateFields = { meterType = true, damageMeterType = true, sessionType = true, sessionID = true,
        useClassColor = true, showBarIcons = true, barHeight = true, barSpacing = true, minimized = true, locked = true }
    for _, window in ipairs(s.windows) do
        local config = {}
        for key in pairs(privateFields) do config[key] = rawget(window, key); rawset(window, key, nil) end
        setmetatable(window, { __index = config, __newindex = function(object, key, value)
            if privateFields[key] then
                config[key] = value
                if not trusted then writes[#writes + 1] = key; tainted[object] = true end
            else rawset(object, key, value) end
        end })
    end
    local function write(window, field, original, ...)
        local result = original(...)
        if not trusted then
            writes[#writes + 1] = field
            tainted[window] = true
            -- Native row/type setters can synchronously Refresh. A pcall around
            -- the writer cannot undo its persisted field/provider provenance.
            error("modeled native Refresh: secret specIconID comparison under _FluxUI", 0)
        end
        return result
    end
    local function nativeEvent()
        -- Pinned native OnEvent reads the stored type before Refresh; Init then
        -- compares the always-secret specIconID before painting name/value/bar.
        if next(tainted) then error("modeled later native event: secret specIconID under _FluxUI", 0) end
    end
    local function wrapOwner(name, field)
        local original = s.dm[name]
        if original then s.dm[name] = function(self, window, ...)
            return write(window or self, field, original, self, window, ...)
        end end
    end
    for name, field in pairs({ SetSessionWindowDamageMeterType = "damageMeterType",
        SetSessionWindowSessionID = "sessionType", SetSessionWindowLocked = "locked",
        SetSessionWindowMinimized = "minimized", HideSessionWindow = "shown",
        ShowNewSecondarySessionWindow = "newWindow" }) do wrapOwner(name, field) end
    for _, window in ipairs(s.windows) do
        for _, name in ipairs({ "SetUseClassColor", "SetShowBarIcons", "SetBarHeight", "SetBarSpacing" }) do
            local original = window[name]
            window[name] = function(self, ...) return write(self, name, original, self, ...) end
        end
    end
    e.C_DamageMeter = e.C_DamageMeter or {}
    e.C_DamageMeter.ResetAllCombatSessions = function()
        writes[#writes + 1] = "reset"; error("unexpected native combat-data reset")
    end
    local nativeMethods = {}
    for _, object in ipairs({ s.dm, s.windows[1], s.windows[2] }) do
        nativeMethods[object] = {}
        for key, value in pairs(object) do if type(value) == "function" then nativeMethods[object][key] = value end end
    end
    local meter = e.FluxBlizzardMeter
    check(type(meter.GetCallBoundaryStatus) == "function", "scratch boundary diagnostic is available on demand")
    if meter.GetCallBoundaryStatus then
        local originalBoundary, originalSecurity, originalRawset, originalTypes = e.securecallfunction, e.issecurevariable, e.rawset, e.SecureTypes
        local calls, probeTarget, luaBoundaryTarget, wrappers = 0, nil, nil, {}
        local methods = {}; methods.__index = methods
        function methods:SetValue(value) assert(wrappers[self] and value == 1); self.value = value end
        e.SecureTypes = { CreateSecureValue = function(value)
            local wrapper = setmetatable({ value = value }, methods); wrappers[wrapper] = true; return wrapper
        end }
        e.securecallfunction = nil
        check(meter:GetCallBoundaryStatus().available == false, "missing VM metadata APIs leave the optional probe unavailable")
        for _, modeledBoundaryState in ipairs({ false, true }) do
            e.rawset = function(target, key, value)
                assert(target ~= s.dm and target ~= s.windows[1] and target ~= s.windows[2], "native state must not be written")
                probeTarget = target; return rawset(target, key, value)
            end
            e.securecallfunction = function(fn, target, key, value)
                if fn == e.rawset then
                    assert(key == "viaBoundary" and value == 1); calls = calls + 1
                    return fn(target, key, value)
                end
                assert(fn == methods.SetValue and wrappers[target] and key == 1 and value == nil)
                luaBoundaryTarget = target; return fn(target, key)
            end
            e.issecurevariable = function(object, key)
                if object == "rawset" or object == "securecallfunction" then return true end
                if object == e.SecureTypes then assert(key == "CreateSecureValue"); return true end
                if object == methods then assert(key == "SetValue"); return true end
                if wrappers[object] then assert(key == "value"); return object == luaBoundaryTarget and modeledBoundaryState or false end
                if object == s.dm then assert(key == "SetSessionWindowSessionID"); return true end
                if object == s.windows[1] or object == s.windows[2] then
                    assert(key == "sessionType" or key == "damageMeterType"); return true
                end
                assert(object == probeTarget, "only scratch or requested native configuration metadata may be inspected")
                if key == "direct" then return false end
                assert(key == "viaBoundary"); return modeledBoundaryState
            end
            local frames, timers = #s.frames, s.timerCreates
            local probe = meter:GetCallBoundaryStatus()
            check(probe.available and probe.rawsetSecure and probe.directSecure == false
                and probe.boundarySecure == modeledBoundaryState and probe.boundaryWritten,
                "C scratch diagnostic reports supplied VM metadata without assuming barrier behavior")
            check(probe.luaFunctionSecure and probe.luaDirectSecure == false
                and probe.luaBoundarySecure == modeledBoundaryState and probe.luaBoundaryWritten,
                "optional Blizzard-Lua control reports its own metadata independently from the C control")
            check(probeTarget.direct == 1 and probeTarget.viaBoundary == 1 and #writes == 0
                and #s.frames == frames and s.timerCreates == timers,
                "scratch controls change no native fields, resources, settings or recurring work")
            local beforeStatus = calls
            e.SlashCmdList.FLUXBLIZZMETER("status")
            check(calls == beforeStatus, "ordinary status never runs the optional scratch probe")
            e.SlashCmdList.FLUXBLIZZMETER("callcontext")
            check(calls == beforeStatus + 1, "the explicit callcontext command runs one bounded scratch probe")
        end
        local beforeProbe = calls
        e.issecurevariable = function(object)
            assert(object == "rawset" or object == "securecallfunction"); return object ~= "rawset"
        end
        check(meter:GetCallBoundaryStatus().available == false and calls == beforeProbe,
            "an unverified rawset reference is never invoked through the boundary")
        e.securecallfunction, e.issecurevariable, e.rawset, e.SecureTypes = originalBoundary, originalSecurity, originalRawset, originalTypes
    end
    local layout = { topSlots = {{ kind = "blizzard", damageMeterType = 0 }},
        bottomSlots = {{ kind = "blizzard", damageMeterType = 2 }} }
    local ok, errorText = pcall(function() meter:Embed(s.host, layout); s.drain() end)
    check(ok, "initial docking invokes no native data/configuration writer: " .. tostring(errorText))
    check(#writes == 0, "native initialized settings and provider state have no addon-origin writes")
    check(pcall(nativeEvent), "later native event is not contaminated by addon configuration")
    if ok then
        local oldSkin, regenCalls = e.FluxMeterSkin, 0
        e.FluxMeterSkin = { RefreshHeaderControls = function() regenCalls = regenCalls + 1 end }
        s.event("PLAYER_REGEN_ENABLED")
        check(regenCalls == 1 and #writes == 0, "existing combat-exit dispatch reconciles header geometry without a new driver")
        e.FluxMeterSkin = oldSkin
        local initialStatus = meter:GetLayoutStatus()
        local choices = initialStatus.sessionChoices or {}
        check(#choices == 2 and choices[1].selection == "Overall" and choices[2].selection == "Overall"
            and initialStatus.perFightSetupRequired == true,
            "mapped native Overall choices are reported as needing Current for a per-fight view")
        if choices[1] then choices[1].selection = "Current" end
        check(meter:GetLayoutStatus().sessionChoices and meter:GetLayoutStatus().sessionChoices[1].selection == "Overall",
            "session diagnostics do not alias native configuration or another status result")
        local messagesBeforeStatus = #s.messages
        e.SlashCmdList.FLUXBLIZZMETER("status")
        local currentInstruction = false
        for i = messagesBeforeStatus + 1, #s.messages do
            if tostring(s.messages[i][1]):find("select Current in Blizzard's session menu", 1, true) then currentInstruction = true end
        end
        check(currentInstruction and #writes == 0,
            "status explains native Current setup without changing sessions or resetting history")
        local height, spacing, types, sessions = s.barHeightCalls, s.barSpacingCalls, s.typeCalls, s.sessionCalls
        for _ = 1, 500 do meter:RefreshEmbeddedLayout() end
        meter:Hide(); meter:Show(); meter:Embed(s.host, layout); s.drain()
        check(#writes == 0 and s.barHeightCalls == height and s.barSpacingCalls == spacing
            and s.typeCalls == types and s.sessionCalls == sessions,
            "500 layouts and reopening retain native settings without refreshing native data")
        local missing = { topSlots = {{ kind = "blizzard", damageMeterType = 1 }},
            bottomSlots = {{ kind = "blizzard", damageMeterType = 4 }} }
        meter:Embed(s.host, missing)
        local status = meter:GetLayoutStatus()
        check(status.configurationRequired and #status.missingTypes == 2 and status.visibleNativePanes == 2
            and status.setupPanes == 2,
            "missing types keep native menus accessible with explicit setup panes instead of wrong data")
        check(s.windows[1].meterType == 0 and s.windows[2].meterType == 2 and #s.windows == 2,
            "missing types never create or repurpose native windows")
        local messages = #s.messages
        for _ = 1, 500 do meter:RefreshEmbeddedLayout() end
        check(#s.messages == messages, "an unchanged configuration notice is not repeated")
        status.missingTypes[1] = 99
        check(meter:GetLayoutStatus().missingTypes[1] == 1, "public status copies do not alias owned state")
        e.SlashCmdList.FLUXBLIZZMETER("status")
        check(#s.messages > messages, "the missing-configuration limitation has a public diagnostic")
        trusted = true
        s.dm:SetSessionWindowDamageMeterType(s.windows[1], 1)
        s.dm:SetSessionWindowSessionID(s.windows[1], e.Enum.DamageMeterSessionType.Current, nil)
        trusted = false
        layout.topSlots[1].damageMeterType = 1
        meter:Embed(s.host, layout)
        check(not meter:GetLayoutStatus().configurationRequired and s.windows[1]:IsShown() and s.windows[2]:IsShown(),
            "original native menu choices make requested views available without addon setters")
        check(s.windows[1].sessionType == e.Enum.DamageMeterSessionType.Current and s.windows[1].sessionID == nil,
            "Current per-fight selection remains owned by the native menu")
        status = meter:GetLayoutStatus(); choices = status.sessionChoices or {}
        check(choices[1] and choices[1].selection == "Current" and choices[2].selection == "Overall"
            and status.perFightSetupRequired == true, "each pane reports its own native session selection")
        trusted = true
        s.dm:SetSessionWindowSessionID(s.windows[2], e.Enum.DamageMeterSessionType.Current, nil)
        trusted = false
        status = meter:GetLayoutStatus(); choices = status.sessionChoices or {}
        check(#choices == 2 and choices[1].selection == "Current" and choices[2].selection == "Current"
            and status.perFightSetupRequired == false,
            "all native Current choices clear setup guidance without an addon configuration write")
        trusted = true; s.dm:SetSessionWindowSessionID(s.windows[2], nil, 72); trusted = false
        status = meter:GetLayoutStatus(); choices = status.sessionChoices or {}
        check(choices[2] and choices[2].selection == "Historical" and status.perFightSetupRequired == true
            and s.windows[2].sessionID == 72,
            "a selected historical session is diagnosed and preserved rather than silently switched")
        trusted = true; s.dm:SetSessionWindowSessionID(s.windows[2], e.Enum.DamageMeterSessionType.Expired, nil); trusted = false
        status = meter:GetLayoutStatus(); choices = status.sessionChoices or {}
        check(choices[2] and choices[2].selection == "Historical" and status.perFightSetupRequired == true
            and s.windows[2].sessionType == e.Enum.DamageMeterSessionType.Expired,
            "the source-pinned Expired session enum is reported without modifying the native choice")
        local opaque = setmetatable({}, { __eq = function() error("secret comparison") end,
            __lt = function() error("secret comparison") end, __tostring = function() error("secret formatting") end })
        e.issecretvalue = function(value) return rawequal(value, opaque) end
        trusted = true; s.dm:SetSessionWindowSessionID(s.windows[1], opaque, nil); trusted = false
        local statusOK, opaqueStatus = pcall(meter.GetLayoutStatus, meter)
        choices = statusOK and opaqueStatus.sessionChoices or {}
        check(statusOK and choices[1] and choices[1].selection == "Unavailable" and opaqueStatus.unavailableSessionChoices == 1,
            "opaque session selection is reported unavailable without comparison or formatting")
        trusted = true; s.dm:SetSessionWindowSessionID(s.windows[1], e.Enum.DamageMeterSessionType.Current, nil); trusted = false
        meter:Cleanup(); meter:Embed(s.host, layout); s.combat = true; meter:Cleanup()
        s.combat = false; s.event("PLAYER_REGEN_ENABLED"); s.drain()
        check(#writes == 0 and pcall(nativeEvent), "cleanup, handoff and deferred cleanup never restore private configuration")
        local intact = true
        for object, methods in pairs(nativeMethods) do for key, value in pairs(methods) do
            if object[key] ~= value then intact = false end
        end end
        check(intact, "native functions and menu methods retain their identities")
    end
end
-- Native Forever testing rejected the configuration experiment despite positive
-- mocked guards. These commands must stay read-only even when every API exists.
for _, gamepad in ipairs({ false, true }) do
    for _, mode in ipairs({ "ready", "combat", "missing", "retail" }) do
        local e, s = harness(gamepad)
        local counts = { writes = 0, reads = 0, barriers = 0, metadata = 0, permissions = 0, errors = 0, resets = 0, builds = 0 }
        local function record(values)
            return setmetatable({}, {
                __index = function(_, key) counts.reads = counts.reads + 1; return values[key] end,
                __newindex = function() counts.writes = counts.writes + 1; error("native configuration write forbidden") end,
            })
        end
        local function nativeSetter()
            counts.writes = counts.writes + 1; error("rejected native selection experiment must remain removed")
        end
        s.dm.SetSessionWindowSessionID = nativeSetter
        e.DamageMeterMixin = { SetSessionWindowSessionID = nativeSetter }
        e.GetBuildInfo = function()
            counts.builds = counts.builds + 1
            if mode == "retail" then return "12.1.5", "70783", "", 120105 end
            return "1.60.1", "70790", "", 16001
        end
        e.C_RestrictedActions = { CheckAllowProtectedFunctions = function()
            counts.permissions = counts.permissions + 1; return true
        end }
        e.issecretvalue, e.canaccesstable = function() return false end, function() return true end
        e.issecurevariable = function() counts.metadata = counts.metadata + 1; return true end
        e.securecallmethod = function() counts.barriers = counts.barriers + 1; error("native method barrier forbidden") end
        e.securecallfunction = function() counts.barriers = counts.barriers + 1; error("native function barrier forbidden") end
        e.BugTabs = { GetSessionCounts = function() counts.errors = counts.errors + 1; return 0 end }
        e.C_DamageMeter = { ResetAllCombatSessions = function() counts.resets = counts.resets + 1; error("history reset forbidden") end }
        e.FluxBlizzardMeter:Embed(s.host, { topSlots = {{kind="blizzard",damageMeterType=0}}, bottomSlots = {{kind="blizzard",damageMeterType=2}} })
        s.drain()
        s.dm.windowDataList = record({ [1] = record({sessionType=0, sessionID=nil, sessionWindow=s.windows[1]}) })
        e.DamageMeterPerCharacterSettings = record({windowDataList = record({ [1] = record({sessionType=0}) })})
        e.Enum.DamageMeterSessionType = record({ Overall=0, Current=1, Expired=2 })
        for _, window in ipairs(s.windows) do
            local getSessionType = window.GetSessionType
            window.GetSessionType = function(self) counts.reads = counts.reads + 1; return getSessionType(self) end
        end
        if mode == "combat" then s.combat = true end
        if mode == "missing" then e.securecallmethod, e.securecallfunction, e.issecurevariable = nil, nil, nil end
        for key in pairs(counts) do counts[key] = 0 end
        local frames, timers, windowType, windowSession = #s.frames, s.timerCreates, s.windows[1].meterType, s.windows[1].sessionType
        local meter = e.FluxBlizzardMeter
        check(type(meter.TestCurrentSelection) == "function" and type(meter.GetCurrentSelectionTestStatus) == "function",
            "compatibility commands retain read-only unsupported replies")
        if meter.TestCurrentSelection and meter.GetCurrentSelectionTestStatus then
            local result = meter:TestCurrentSelection()
            check(result.status == "UNSUPPORTED" and result.attempted == false,
                "failed native experiment is unavailable regardless of otherwise permissive guards: " .. mode)
            result.status = "CHANGED_FIELDS_CLEAN"
            check(meter:GetCurrentSelectionTestStatus().status == "UNSUPPORTED",
                "mutating a returned diagnostic cannot revive the removed experiment")
            local lines = #s.messages
            for _ = 1, 20 do
                e.SlashCmdList.FLUXBLIZZMETER("currenttest")
                e.SlashCmdList.FLUXBLIZZMETER("currentteststatus")
            end
            check(#s.messages - lines == 80, "repeated current commands only print their two-line unsupported reports")
            check(counts.writes == 0 and counts.barriers == 0 and counts.resets == 0,
                "current commands never invoke native selection, call barriers or history reset")
            check(counts.reads == 0 and counts.metadata == 0 and counts.permissions == 0 and counts.errors == 0 and counts.builds == 0,
                "unsupported replies do not touch native argument data, metadata, error roots or capability probes")
            check(#s.frames == frames and s.timerCreates == timers and s.windows[1].meterType == windowType
                and s.windows[1].sessionType == windowSession,
                "read-only current commands preserve native choices and add no resources")
        end
    end
end
print(string.format("native writer provenance: %d checks, %d failures; explicit model, native secure VM unverified", checks, failures))
assert(failures == 0, "native data ownership regressions")
