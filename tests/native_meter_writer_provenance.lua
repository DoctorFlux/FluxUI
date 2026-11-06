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
    local layout = { topSlots = {{ kind = "blizzard", damageMeterType = 0 }},
        bottomSlots = {{ kind = "blizzard", damageMeterType = 2 }} }
    local ok, errorText = pcall(function() meter:Embed(s.host, layout); s.drain() end)
    check(ok, "initial docking invokes no native data/configuration writer: " .. tostring(errorText))
    check(#writes == 0, "native initialized settings and provider state have no addon-origin writes")
    check(pcall(nativeEvent), "later native event is not contaminated by addon configuration")
    if ok then
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
        check(status.configurationRequired and #status.missingTypes == 2 and status.visibleNativePanes == 0,
            "missing types request native UI configuration instead of displaying the wrong data")
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
print(string.format("native writer provenance: %d checks, %d failures; explicit model, native secure VM unverified", checks, failures))
assert(failures == 0, "native data ownership regressions")
