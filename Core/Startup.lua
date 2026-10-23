-- Opt-in startup measurements. No polling or native API wrapping.
local _, ns = ...
local Flux = ns.Flux
local Startup = {}
Flux.Startup = Startup
local clock = ns.startupClock or debugprofilestop or function() return (GetTime and GetTime() or 0) * 1000 end
local began = Flux.startupBegan or clock()
local memory = Flux.startupMemory
local data
local layoutRevision = 0
local settleQueued = false
local QueueSettle
local settleAttempts = 0

function Startup.Configure()
    if data or not (_G.FluxUI_DB and _G.FluxUI_DB.startupDiagnostics == true) then return end
    data = { marks = {}, counters = {}, startedInCombat = InCombatLockdown and InCombatLockdown() and true or false }
    if not _G.FluxOptions or Flux.optionsBootstrapComplete then Startup.Mark("saved_configuration_ready") end
    if Flux.Optional then Flux.Optional.Snapshot() end
end

function Startup.Mark(name)
    if not data or data.marks[name] then return end
    data.marks[name] = clock() - began
    if memory and collectgarbage and (not data.finished or name == "bottom_hud_initially_stable") then
        data.allocationKB = collectgarbage("count") - memory
    end
    if QueueSettle and layoutRevision > 0 then QueueSettle() end
end

function Startup.Count(name, amount)
	if not data or data.finished then return end
    data.counters[name] = (data.counters[name] or 0) + (amount or 1)
end

function Startup.ObserveOptional(name, info)
    if not data then return end
    if info.loaded then Startup.Mark("optional." .. name .. ".loaded_observed") end
    if info.ready then Startup.Mark("optional." .. name .. ".ready_observed") end
end

-- Only armed by actual startup layout work. No permanent OnUpdate. Two
-- unchanged frame boundaries, no queued structural work, and completed
-- eligible HUD modules are required before recording initial stability.
QueueSettle = function()
    if not data or data.finished or settleQueued or not Flux.Timer then return end
    settleQueued = true
    local revision = layoutRevision
    Flux.Timer.After(0, function()
        Flux.Timer.After(0, function()
            settleQueued = false
            if not data or data.finished then return end
            if revision ~= layoutRevision then QueueSettle(); return end
            if not Flux.deferredPhaseReady then return end
            if Flux.Combat and (Flux.Combat.InLockdown() or Flux.Combat.HasPending()) then return end
            if Flux.Scheduler and (Flux.Scheduler.HasPending("layout") or Flux.Scheduler.HasPending("structural")) then
                settleAttempts = settleAttempts + 1
                if settleAttempts < 8 then QueueSettle() end
                return
            end
            for _, module in ipairs(Flux.Module.List()) do
                if module.phase ~= "deferred" and module.eligible and not module.enabled then return end
            end
            data.finished = true
            Startup.Mark("bottom_hud_initially_stable")
        end)
    end)
end

function Startup.Layout(name)
    if not data or data.finished then return end
    Startup.Count(name or "bottom_layout_passes")
    layoutRevision = layoutRevision + 1
    settleAttempts = 0
    QueueSettle()
end

function Startup.CheckLayout()
    if layoutRevision > 0 then QueueSettle() end
end

function Startup.IsRecording()
    return data ~= nil and not data.finished
end

function Startup.Snapshot()
    if not data then return { enabled = false } end
    local out = { enabled = true, marks = {}, counters = {}, startedInCombat = data.startedInCombat, allocationKB = data.allocationKB, finished = data.finished or false }
    for k, v in pairs(data.marks) do out.marks[k] = v end
    for k, v in pairs(data.counters) do out.counters[k] = v end
    out.elapsedMS = clock() - began
    out.pendingCombat = Flux.Combat and Flux.Combat.PendingCount() or 0
    out.modules = Flux.Module and Flux.Module.List() or {}
    out.optional = Flux.Optional and Flux.Optional.Snapshot() or {}
    return out
end

-- Explicit command persists only the diagnostic flag, not player settings.
SLASH_FLUXSTARTUP1 = "/fluxstartup"
SlashCmdList.FLUXSTARTUP = function(msg)
    if msg == "on" or msg == "off" then
        local db = Flux.DB.GetAccount()
        db.startupDiagnostics = msg == "on"
        Flux.Print("Startup diagnostics " .. (db.startupDiagnostics and "enabled; /reload to capture." or "disabled."))
        if not db.startupDiagnostics then data = nil end
        return
    end
    if not data then Flux.Print("Startup diagnostics disabled. /fluxstartup on, then /reload."); return end
    local snapshot = Startup.Snapshot()
    Flux.Print("Startup (milliseconds since first Flux file; visual and input readiness measured separately)")
    local names = {}
    for name in pairs(snapshot.marks) do names[#names + 1] = name end
    table.sort(names)
    for i = 1, #names do print(string.format("  %s: %.2f", names[i], snapshot.marks[names[i]])) end
    for name, value in pairs(snapshot.counters) do print("  " .. name .. ": " .. value) end
    print("  pending combat operations: " .. snapshot.pendingCombat)
    if snapshot.allocationKB then print(string.format("  Lua heap delta: %.1f KB (includes other addons/GC)", snapshot.allocationKB)) end
end
