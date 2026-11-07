-- Full production profile/utility/consumables owners under public-state mocks.
local root = arg[1] or ((arg[0]:match("^(.*)[/\\]") or ".") .. "/../")
if not root:match("[/\\]$") then root = root .. "/" end
local selected, checks = arg[2], 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function boot(client, kind, options)
    options = options or {}
    local s = { combat = options.combat, events = {}, timers = {}, frames = {}, switches = 0, store = {}, active = options.matched and "Known" or "Other", warnings = {} }
    local profile = kind == "utility" and { utilitySlots = { slots = { [1] = { [""] = { type = "spell", id = 133 } } } } }
        or { consumables = "Known" }
    if options.disabled then profile.includes = { [kind == "utility" and "utilitySlots" or "consumables"] = false } end
    if options.uncaptured then profile.utilitySlots = nil; profile.consumables = nil end
    local R = { GetProfile = function() return profile end, GetStore = function() return s.store end,
        ApplyInfoFrameForProfile = function() end, LinkProfilePresets = function() end, On = function() end, Print = function() end,
        Warn = function(message) s.warnings[#s.warnings + 1] = message end,
        Fire = function(...) s.events[#s.events + 1] = { ... } end,
        SetLoadCheckpoint = function(name, step) s.checkpoint = { name, step } end,
        ClearLoadCheckpoint = function() s.checkpoint = nil; s.cleared = (s.cleared or 0) + 1 end }
    local e = setmetatable({ FluxRespec = R, time = function() return 1 end }, { __index = _G }); e._G = e
    e.FLUX_API = { isRetail = client == "live" or client == "forever", isV12 = client == "live", isClassicEra = client == "classic_era" }
    function e.InCombatLockdown() return s.combat end
    function e.CreateFrame()
        local f = { events = {} }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:SetScript(key, fn) self[key] = fn end
        s.frames[#s.frames + 1] = f; return f
    end
    local flux = { Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end } }
    flux.Safecall = function(fn, ...) local ok, why = pcall(fn, ...); check(ok, "owned callback must not throw: " .. tostring(why)); return ok end
    e.Flux = flux
    function s.regen()
        for _, f in ipairs(s.frames) do if f.events.PLAYER_REGEN_ENABLED and f.OnEvent then f.OnEvent(f, "PLAYER_REGEN_ENABLED") end end
        while #s.timers > 0 do local work = s.timers; s.timers = {}; for _, fn in ipairs(work) do fn() end end
    end
    function s.done()
        local result = {}; for _, event in ipairs(s.events) do if event[1] == "APPLY_DONE" then result[#result + 1] = event end end; return result
    end
    if not options.unavailable then
        e.FluxNCConsumables = {
            GetActivePreset = function() return s.active end,
            GetPresetNames = function() return options.missing and {} or { "Known", "Other" } end,
            SetActivePreset = function(name)
                s.switches = s.switches + 1
                if options.throw then error("injected preset error") end
                if options.refuse then return false end
                if not options.noop then s.active = name end
                return true
            end }
    end
    local ns = { Flux = flux }
    for _, path in ipairs({ "Core/Engine/Combat.lua", "Respec/FluxRespec_Compat.lua", "Respec/FluxRespec_Includes.lua",
        "ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua", "Respec/FluxRespec_Consumables.lua",
        "Respec/FluxRespec_PresetBundle.lua", "Respec/FluxRespec_Apply.lua" }) do
        assert(loadfile(root .. path, "t", e))("_FluxUI", ns)
    end
    if kind == "utility" and options.unavailable then
        e.FluxNCUtilitySlots_ApplySnapshot = nil; e.FluxSpellBookSlots_ApplySnapshot = nil
        if options.noMatch then e.FluxNCUtilitySlots_MatchesSnapshot = nil; e.FluxSpellBookSlots_MatchesSnapshot = nil end
    end
    if kind == "utility" and options.invalid then profile.utilitySlots = { bad = true } end
    return s, R, profile, e
end

for _, client in ipairs({ "classic_era", "classic_anniversary", "classic", "live", "forever" }) do
    if not selected or selected == "utility" then
        local s, R, profile, e = boot(client, "utility", { combat = true })
        R.Apply.Run("Utility")
        check(R.Apply.IsRunning() and #s.done() == 0 and s.checkpoint[2] == "spellbook", "combat-refused utility restore must remain pending at its checkpoint")
        profile.utilitySlots.slots[1][""].id = 116
        s.regen(); check(R.Apply.IsRunning() and not (e.FluxNCUtilitySlotsDB and e.FluxNCUtilitySlotsDB.slots[1][""]), "combat still blocks utility assignment")
        s.combat = false; s.regen()
        check(e.FluxNCUtilitySlotsDB.slots[1][""].id == 133, "deferred utility request uses detached snapshot")
        check(#s.done() == 1 and s.done()[1][2] and not s.checkpoint, "utility completion advances exactly once")
        local c, C, _, ce = boot(client, "utility", { combat = true })
        C.Apply.Run("Cancel utility"); C.Apply.Cancel(); c.combat = false; c.regen()
        check(not (ce.FluxNCUtilitySlotsDB and ce.FluxNCUtilitySlotsDB.slots[1][""]) and #c.done() == 1 and not c.done()[1][2], "cancelled utility request cannot write later")
    end
    if not selected or selected == "consumables" then
        for _, options in ipairs({ { missing = true }, { unavailable = true }, { refuse = true }, { noop = true }, { throw = true } }) do
            local s, R = boot(client, "consumables", options)
            R.Apply.Run("Consumables failure")
            check(#s.done() == 1 and not s.done()[1][2] and not R.Apply.IsRunning(), "missing/refused/no-op/throwing consumables cannot complete the profile")
            check(s.checkpoint and s.checkpoint[2] == "consumables" and not s.cleared, "consumables failure keeps retry checkpoint")
        end
    end
    if not selected or selected == "bundle" then
        local s, R, profile = boot(client, "utility", { combat = true })
        local preset = { utilitySlotsByGroup = { [1] = profile.utilitySlots } }
        local ok, reason = R.PresetBundle.ApplySpellBookForActiveGroup(preset)
        check(not ok and reason == "IN_COMBAT", "preset bundle must propagate utility false result")
    end
    if not selected then
        do
            local s, R, profile = boot(client, "utility")
            profile.utilitySlots, profile.bars, R.ActionBars = nil, { slots = {} }, nil
            check(not R.Apply.IsProfileFullyApplied("Missing bar owner"), "captured bars with no owner cannot use the completed-profile fast path")
            R.Apply.Run("Missing bar owner")
            check(#s.done() == 1 and not s.done()[1][2] and s.checkpoint[2] == "bars", "captured bars with no owner report recoverable failure")
        end
        do
            local s, R = boot(client, "consumables"); R.Consumables = nil
            R.Apply.Run("Missing consumables owner")
            check(#s.done() == 1 and not s.done()[1][2] and s.checkpoint[2] == "consumables", "captured consumables with no owner fail instead of silently skipping")
        end
        do
            local s, R, profile, e = boot(client, "utility", { combat = true })
            R.Apply.Run("First utility"); R.Apply.Cancel()
            profile.utilitySlots.slots[1][""].id = 116
            R.Apply.Run("Replacement utility"); s.combat = false; s.regen()
            check(#s.done() == 2 and not s.done()[1][2] and s.done()[2][2] and e.FluxNCUtilitySlotsDB.slots[1][""].id == 116,
                "new utility owner replaces cancelled pending work without stale writes")
        end
        do
            local s, R, profile, e = boot(client, "utility")
            profile.spellBookSlots, profile.utilitySlots = profile.utilitySlots, nil
            R.Apply.Run("Legacy profile field")
            check(#s.done() == 1 and s.done()[1][2] and e.FluxNCUtilitySlotsDB.slots[1][""].id == 133, "legacy spellBookSlots profile field still restores")
        end
        do
            local s, R = boot(client, "consumables", { matched = true })
            R.Apply.Run("Already matched")
            check(#s.done() == 1 and s.done()[1][2] and s.switches == 1, "matched consumables retain the original single early switch cadence")
        end
        for _, noOp in ipairs({ false, true }) do
            local s, R, profile, e = boot(client, "consumables")
            profile.bars = {}
            R.ActionBars = { MatchesSnapshot = function() return false end,
                Apply = function(_, done)
                    -- Another completed setup step changes the active preset;
                    -- the late consumables step must validate its own result.
                    s.active = "Other"
                    e.FluxNCConsumables.SetActivePreset = function() s.switches = s.switches + 1; return noOp end
                    done(true); return true
                end }
            R.Apply.Run("Late preset failure")
            check(s.switches == 2 and #s.done() == 1 and not s.done()[1][2] and s.checkpoint[2] == "consumables",
                "late refused/no-op preset switch cannot complete a partially applied profile")
        end
        for _, mode in ipairs({ "throw", "refuse" }) do
            local s, R, _, e = boot(client, "utility")
            e.FluxNCUtilitySlots_ApplySnapshot = function()
                if mode == "throw" then error("injected utility API failure") end
                return false, "DENIED"
            end
            R.Apply.Run("Utility API failure")
            check(#s.done() == 1 and not s.done()[1][2] and s.checkpoint[2] == "spellbook", "utility throw/refusal preserves truthful failure")
        end
        for _, kind in ipairs({ "utility", "consumables" }) do
            for _, options in ipairs({ { disabled = true, unavailable = true }, { uncaptured = true, unavailable = true } }) do
                local s, R = boot(client, kind, options); R.Apply.Run("Skip")
                check(#s.done() == 1 and s.done()[1][2], "disabled/uncaptured optional section stays skipped")
            end
            local s, R, profile, e = boot(client, kind)
            R.Apply.Run("Ordinary")
            check(#s.done() == 1 and s.done()[1][2] and not s.checkpoint, "ordinary section restore completes")
            if kind == "consumables" then check(s.switches == 1 and s.active == "Known", "successful preset preserves one early switch and skips matched later step")
            else check(e.FluxNCUtilitySlotsDB.slots[1][""].id == 133, "ordinary utility assignment retained") end
        end
        for _, options in ipairs({ { unavailable = true }, { unavailable = true, noMatch = true }, { invalid = true } }) do
            local s, R = boot(client, "utility", options); R.Apply.Run("Utility failure")
            check(#s.done() == 1 and not s.done()[1][2] and s.checkpoint and s.checkpoint[2] == "spellbook", "requested unrestorable utility section fails with recovery")
        end
    end
end
print("respec section results: " .. checks .. " checks passed; five clients; production owners, native pending")
