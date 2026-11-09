-- Production startup/visibility ownership, before the first Meter-tab embed.
-- Frame Show/Hide dispatch and native visibility events are explicit mocks;
-- this does not emulate rendering, secure execution or engine cache restoration.
-- lua tests/native_meter_startup.lua [alternate backend source] [--measure]
local source = arg[1] or "Battlezonemap/FluxBlizzardMeter.lua"
local measure = arg[2] == "--measure"
local originalArgs = arg; arg = { source, "--harness" }
local harness = assert(loadfile("tests/native_meter_ownership.lua"))(); arg = originalArgs
local checks, failures = 0, 0
local function check(value, label)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. label) end
end

local function boot(gamepad, tab)
    local e, s = harness(gamepad)
    s.activeTab = tab or "Map"
    e._FluxUI_CharSavedVars = { fluxWindowActiveTab = s.activeTab == "Meter" and 2 or 1 }
    s.tabEnabled, s.cvarWrites = true, 0
    function e.FluxWindowFrame:IsTabEnabled(name) assert(name == "Meter"); return s.tabEnabled end
    e.C_CVar = {
        GetCVar = function(name) assert(name == "damageMeterEnabled"); return s.enabled and "1" or "0" end,
        GetCVarInfo = function() return s.enabled and "1" or "0", "0", false, false, false, false, false end,
        SetCVar = function(name, value)
            assert(name == "damageMeterEnabled" and value == "1" and not s.combat)
            s.cvarWrites = s.cvarWrites + 1; s.enabled = true; return true
        end,
    }
    return e, s, e.FluxBlizzardMeter
end

for _, gamepad in ipairs({ false, true }) do
    local label = gamepad and "gamepad" or "ordinary"
    local e, s, meter = boot(gamepad, "Map")
    check(s.dm:IsShown() and not meter:IsEmbedded(), label .. " native enabled root exists before any embed")
    s.event("ADDON_LOADED", "_FluxUI"); s.drain()
    check(not s.dm:IsShown() and not meter:IsEmbedded(), label .. " saved Map claims and hides the native root before first Meter click")
    s.event("VARIABLES_LOADED"); s.event("PLAYER_ENTERING_WORLD"); s.drain()
    check(not s.dm:IsShown() and s.typeCalls == 0 and s.sessionCalls == 0 and s.entryWalks == 0,
        label .. " Map startup events do not configure or embed native sessions")
    check(s.cvarWrites == 0 and #s.timers == 0, label .. " already-enabled Map startup has no CVar write or polling")
    local frameCount, timers = #s.frames, s.timerCreates
    for _ = 1, 100 do s.dm:UpdateShownState(); s.dm:Show() end
    s.drain()
    check(not s.dm:IsShown() and not meter:IsEmbedded(), label .. " repeated native visibility and Show cannot float outside the active Map tab")
    check(#s.frames == frameCount and s.timerCreates == timers and s.typeCalls == 0 and s.sessionCalls == 0,
        label .. " pre-embed visibility corrections add no frames, timers or content refreshes")
    check(#(s.hooks[s.dm] and s.hooks[s.dm].UpdateShownState or {}) == 1
        and #(s.dm.hooks.OnShow or {}) == 1, label .. " startup visibility observers install once")
    meter:Hide(); s.dm:UpdateShownState()
    check(not s.dm:IsShown() and not meter:IsEmbedded(), label .. " public hide works before the first embed")

    s.activeTab = "Meter"
    check(meter:Embed(s.host), label .. " first Meter click embeds native sessions")
    s.drain()
    check(meter:IsEmbedded() and s.dm:IsShown() and s.windows[1]:IsShown(), label .. " first embed can reveal the native pane normally")
    s.host:Hide(); s.dm:UpdateShownState(); s.dm:Show(); s.drain()
    check(not s.dm:IsShown(), label .. " hidden Flux host suppresses a native reveal")
    s.host:Show(); meter:Show(); s.drain()
    check(s.dm:IsShown(), label .. " explicit Meter show recovers when its host returns")
    meter:Cleanup(); s.dm:UpdateShownState(); s.drain()
    check(s.dm:IsShown() and not meter:IsEmbedded(), label .. " cleanup releases visibility to the native meter")
    s.activeTab = "Map"; s.event("PLAYER_ENTERING_WORLD"); s.dm:UpdateShownState(); s.drain()
    check(s.dm:IsShown(), label .. " later startup events do not silently reclaim explicit cleanup")
    s.activeTab = "Meter"; meter:Embed(s.host); s.drain(); s.activeTab = "Map"; s.dm:UpdateShownState()
    check(not s.dm:IsShown() and meter:IsEmbedded(), label .. " later explicit embed reclaims visibility ownership")
    check(s.nativeMethodsIntact() and s.policyWrites == 0, label .. " lifecycle keeps native methods and visibility policy unchanged")

    local disabledEnv, disabled, disabledMeter = boot(gamepad, "Map")
    disabled.tabEnabled = false
    disabled.event("ADDON_LOADED", "_FluxUI"); disabled.event("VARIABLES_LOADED")
    disabled.event("PLAYER_ENTERING_WORLD"); disabled.dm:UpdateShownState(); disabled.drain()
    check(disabled.dm:IsShown() and not disabledMeter:IsEmbedded(), label .. " disabled Meter tab leaves the standalone native meter alone")
    check(disabled.typeCalls == 0 and disabled.sessionCalls == 0 and disabled.cvarWrites == 0,
        label .. " disabled tab has no native configuration or enable writes")
    check(disabled.nativeMethodsIntact(), label .. " disabled startup preserves original methods")

    local detailsEnv, details, detailsMeter = boot(gamepad, "Map")
    details.details = true
    details.event("ADDON_LOADED", "Details"); details.event("VARIABLES_LOADED")
    details.dm:UpdateShownState(); details.dm:Show(); details.drain()
    check(not detailsMeter:IsAvailable() and not detailsMeter:IsEmbedded() and not details.dm:IsShown(),
        label .. " Details priority suppresses floating native panes without embedding them")
    check(details.typeCalls == 0 and details.sessionCalls == 0 and details.cvarWrites == 0,
        label .. " Details startup does not configure or auto-enable the native backend")

    local lateEnv, late, lateMeter = boot(gamepad, "Map")
    lateEnv.DamageMeter = nil
    late.event("ADDON_LOADED", "_FluxUI"); late.event("VARIABLES_LOADED"); late.drain()
    check(not lateMeter:IsEmbedded() and late.typeCalls == 0 and late.sessionCalls == 0,
        label .. " missing native addon causes no forced load or partial embed")
    lateEnv.DamageMeter = late.dm
    late.event("ADDON_LOADED", "Blizzard_DamageMeter"); late.drain()
    check(not late.dm:IsShown() and not lateMeter:IsEmbedded(), label .. " late native addon is hidden while Map remains selected")
    late.dm:Show(); check(not late.dm:IsShown(), label .. " late native OnShow obeys pre-embed ownership")

    local hostEnv, hostState, hostMeter = boot(gamepad, "Map")
    local savedWindow = hostEnv.FluxWindowFrame
    hostEnv.FluxWindowFrame = nil
    hostState.event("VARIABLES_LOADED"); hostState.drain()
    check(not hostMeter:IsEmbedded() and hostState.typeCalls == 0,
        label .. " missing Flux window does not create a partial embed")
    hostEnv.FluxWindowFrame = savedWindow
    hostState.event("ADDON_LOADED", "_FluxUI"); hostState.event("PLAYER_ENTERING_WORLD"); hostState.drain()
    check(not hostState.dm:IsShown() and not hostMeter:IsEmbedded(), label .. " late Flux host claims the active Map boundary")

    local selectedEnv, selected, selectedMeter = boot(gamepad, "Meter")
    selected.event("VARIABLES_LOADED"); selected.drain()
    check(selectedMeter:IsEmbedded() and selected.dm:IsShown(), label .. " saved Meter startup still embeds and shows normally")
    check(selected.nativeMethodsIntact() and selected.policyWrites == 0, label .. " saved Meter startup leaves native data methods and policy intact")

    local combatEnv, combat, combatMeter = boot(gamepad, "Meter")
    combat.combat = true
    combat.event("VARIABLES_LOADED"); combat.event("PLAYER_ENTERING_WORLD"); combat.drain()
    check(not combatMeter:IsEmbedded() and not combat.dm:IsShown() and combat.typeCalls == 0
        and combat.sessionCalls == 0 and combat.cvarWrites == 0,
        label .. " combat login holds an unpositioned native meter hidden without configuring it")
    check(#combat.timers == 0, label .. " combat startup waits for regen without polling")
    combat.combat = false; combat.event("PLAYER_REGEN_ENABLED"); combat.drain()
    check(combatMeter:IsEmbedded() and combat.dm:IsShown(), label .. " deferred saved Meter startup recovers on regen")

    local missingEnv, missing, missingMeter = boot(gamepad, "Map")
    missing.available = false
    missing.event("ADDON_LOADED", "_FluxUI"); missing.event("VARIABLES_LOADED"); missing.drain()
    check(not missingMeter:IsEmbedded() and missing.typeCalls == 0 and missing.sessionCalls == 0
        and missing.cvarWrites == 0, label .. " unsupported native backend stays inert")
end

print(string.format("native meter startup: %d checks, %d failures; pre-embed ownership, explicit cleanup and deferred startup mocked",
    checks, failures))
if not measure then assert(failures == 0, "native meter startup regressions") end
