-- Provenance metadata only: native tooltip values/actions are deliberate traps.
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local function forbidden() error("native tooltip data read, action invoked or driver installed") end
local env = setmetatable({}, { __index = _G }); env._G = env
local callbacks, messages, observed = {}, {}, {}
local native = setmetatable({}, { __index = forbidden, __newindex = forbidden })
local secret = setmetatable({}, { __index = forbidden, __newindex = forbidden, __tostring = forbidden })
env.GameTooltip, env.GameTooltipDataMixin, env.TooltipDataHandlerMixin = native, native, native
env.GameTooltipStatusBar = secret
env.TooltipDataRules = native
env.InCombatLockdown = function() return true end
env.GetBuildInfo = function() return "12.1.5", "70783", "test", 120105 end
env.GetLocale = function() return "daDK" end
env.issecretvalue = function(value) return rawequal(value, secret) end
env.C_CVar = { GetCVar = function(key) check(key == "taintLog", "only reads logging mode"); return "0" end, SetCVar = forbidden }
env.C_Timer = { After = function(delay, fn)
    check(delay == 3, "one bounded three-second capture"); callbacks[#callbacks + 1] = fn
end }
env.CreateFrame, env.hooksecurefunc, env.SetCVar = forbidden, forbidden, forbidden
env.SlashCmdList = {}
env.print = function(text) messages[#messages + 1] = text end
local writer = "_FluxUI"
env.issecurevariable = function(object, key)
    check(not rawequal(object, secret), "secret object is never inspected")
    observed[key] = true
    if key == "marker" then return false, "_FluxUI" end
    if key == "insertedFrames" then return false, writer end
    return true
end
env.FluxPerfCaptureDB = { inputDebug = { retained = true }, bagInputDebug = { retained = true }, profiler = { retained = true } }
local roots = env.FluxPerfCaptureDB
local ns = { Flux = {} }
assert(loadfile(arg[1] or "Other/FluxInputDebug.lua", "t", env))("_FluxUI", ns)
local debug = ns.Flux.InputDebug
check(#callbacks == 0 and #messages == 0 and roots.tooltipDebug == nil, "tooltip diagnostic remains idle until requested")
local snapshot = debug.CaptureTooltip()
check(snapshot.complete and snapshot.build == "70783" and snapshot.interface == 120105, "records actual build")
check(snapshot.source == "tooltip-visual-followup-20261113-r1", "records loaded diagnostic revision")
check(snapshot.combat and snapshot.taintLog == "0", "records context without changing preferences")
check(snapshot.calibration.marker.secure == false, "records diagnostic return convention on owned data")
check(snapshot.frames.GameTooltip.security.insertedFrames.owner == "_FluxUI", "records the field writer without reading its value")
check(snapshot.frames.GameTooltipStatusBar.security.restricted, "secret object omitted")
check(observed.infoList and observed.processingInfo and observed.ClearLines and observed.GameTooltip_AddColoredLine,
    "queries relevant native fields and globals")
check(roots.tooltipDebug == nil, "direct metadata inspection does not persist by itself")
env.SlashCmdList.FLUXINPUT("tooltip")
check(#callbacks == 1 and #messages == 1, "explicit command arms one capture")
local before = roots.tooltipDebug.latest
writer = "OtherWriter"
env.SlashCmdList.FLUXINPUT("tooltip")
check(#callbacks == 1, "pending capture is not duplicated")
callbacks[1]()
snapshot = roots.tooltipDebug.latest
check(snapshot.before == before and snapshot.before.frames.GameTooltip.security.insertedFrames.owner == "_FluxUI"
    and snapshot.frames.GameTooltip.security.insertedFrames.owner == "OtherWriter", "retains before/after provenance")
check(roots.inputDebug.retained and roots.bagInputDebug.retained and roots.profiler.retained, "preserves prior diagnostics and profiler preferences")
check(messages[#messages]:find("70783", 1, true) and messages[1]:find("3 seconds", 1, true), "English fallback keeps diagnostics usable")
debug.TooltipMessages.daDK = { start = "Test af vaerktoejstip" }
local localizedNotice = #messages + 1
env.SlashCmdList.FLUXINPUT("tooltip"); callbacks[2]()
check(roots.tooltipDebug.previous == snapshot, "preserves previous capture")
check(messages[localizedNotice] == "Test af vaerktoejstip", "localized diagnostic text uses its catalog")
env.SlashCmdList.FLUXINPUT("tooltip"); callbacks[3]()
check(roots.tooltipDebug.previous.previous == nil, "history remains bounded")
env.C_Timer, env.issecurevariable = nil, nil
env.SlashCmdList.FLUXINPUT("tooltip")
check(roots.tooltipDebug.latest.complete and not roots.tooltipDebug.latest.securityAvailable, "missing diagnostic support remains unavailable")
check(messages[#messages]:find("unavailable", 1, true), "missing support is never reported as clean")
check(#callbacks == 3, "no ongoing timer or polling driver")
print("tooltip_taint_diagnostics: " .. checks .. " checks PASS; native taint VM NOT RUN")
