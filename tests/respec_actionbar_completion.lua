-- Execute the real action-bar owner and profile orchestrator with public API mocks.
local root = arg[1] or ((arg[0]:match("^(.*)[/\\]") or ".") .. "/../")
if not root:match("[/\\]$") then root = root .. "/" end
local selection = arg[2]
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for k, v in pairs(value) do out[k] = copy(v) end; return out
end
local function fixture(client, mode)
    local s = { combat = mode == "combat", frames = {}, slots = {}, events = {}, placements = 0, pickups = 0, clears = 0, store = {} }
    local modern = client == "live" or client == "forever"
    local profile = { bars = { slots = { [1] = { type = "spell", id = 133 } }, stanceSlotOrder = { "spell:133" },
        stanceHiddenSlots = { ["spell:133"] = true }, stanceCustomSlots = { { type = "spell", id = 133 } } } }
    local R = {
        Compat = { HasTalentLoadouts = function() return modern end, IsSoD = function() return false end },
        GetProfile = function() return profile end, GetStore = function() return s.store end,
        ApplyInfoFrameForProfile = function() end, LinkProfilePresets = function() end, On = function() end,
        Print = function() end, Warn = function(message) s.warning = message end,
        Fire = function(...) s.events[#s.events + 1] = { ... } end,
        SetLoadCheckpoint = function(name, step) s.checkpoint = { name = name, step = step } end,
        ClearLoadCheckpoint = function() s.checkpoint = nil; s.clears = s.clears + 1 end,
    }
    local stance = {
        GetSavedOrder = function() return s.order end, GetHiddenSlots = function() return s.hidden end,
        GetSavedCustomSlots = function() return s.custom end,
        SetSavedOrder = function(value) s.order = value end,
        SetSlotHidden = function(key, value) s.hidden = s.hidden or {}; s.hidden[key] = value or nil; return true end,
        SetSavedCustomSlots = function(value)
            if mode == "stance_throw" then error("injected stance error") end
            if mode == "stance_false" then return false end
            s.custom = value; return true
        end,
        RequestLayout = function() s.layouts = (s.layouts or 0) + 1 end,
    }
    local env = setmetatable({ FluxRespec = R, time = function() return 1 end }, { __index = _G }); env._G = env
    function env.InCombatLockdown() return s.combat end
    function env.GetActionInfo(slot)
        if mode == "read_throw" then error("injected read error") end
        local entry = s.slots[slot]
        if entry then return entry.type, entry.id, entry.subType end
    end
    function env.GetMacroInfo(id) return "Macro" .. tostring(id), 1, "/cast Test" end
    function env.GetMacroIndexByName(name) return tonumber(name:match("%d+")) end
    function env.GetCursorInfo() return s.cursor and s.cursor.type end
    function env.ClearCursor() if mode == "clear_throw" then error("injected clear error") end; s.cursor = nil end
    local function pickup(kind, id, subType)
        check(not s.combat, "no protected pickup during combat")
        s.pickups = s.pickups + 1
        if mode == "pickup_throw" then error("injected pickup error") end
        if mode == "pickup_false" then return false end
        if mode ~= "pickup_noop" then s.cursor = { type = kind, id = id, subType = subType } end
    end
    function env.PickupSpell(id) return pickup("spell", id) end
    function env.PickupItem(id) return pickup("item", id) end
    function env.PickupMacro(id) return pickup("macro", id) end
    function env.PickupAction(slot) s.cursor = s.slots[slot]; s.slots[slot] = nil end
    function env.PlaceAction(slot)
        check(not s.combat, "no protected placement during combat")
        if mode == "place_throw" then error("injected placement error") end
        if mode ~= "place_noop" then s.slots[slot] = copy(s.cursor) end
        s.placements = s.placements + 1
    end
    env.C_EquipmentSet = { PickupEquipmentSet = function(id) return pickup("equipmentset", id) end,
        GetEquipmentSetInfo = function(id) return "Set" .. tostring(id) end }
    env.C_MountJournal = { Pickup = function(id) return pickup("mount", id) end }
    env.C_PetJournal = { PickupPet = function(id) return pickup("summonpet", id) end }
    function env.PickupCompanion(kind, id) return pickup("companion", id, kind) end
    function env.CreateFrame()
        local frame = { events = {} }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:SetScript(key, fn) self[key] = fn end
        s.frames[#s.frames + 1] = frame; return frame
    end
    local ns = { Flux = { Bars = { Stance = stance } } }
    for _, path in ipairs({ "Respec/FluxRespec_ActionBars.lua", "Respec/FluxRespec_Apply.lua", "Respec/FluxRespec_PresetBundle.lua" }) do
        assert(loadfile(root .. path, "t", env))("_FluxUI", ns)
    end
    function s.done()
        local out = {}; for _, event in ipairs(s.events) do if event[1] == "APPLY_DONE" then out[#out + 1] = event end end; return out
    end
    function s.regen()
        for _, frame in ipairs(s.frames) do if frame.OnEvent and frame.events.PLAYER_REGEN_ENABLED then frame.OnEvent(frame, "PLAYER_REGEN_ENABLED") end end
    end
    return s, R, profile, env, modern
end

for _, client in ipairs({ "classic_era", "classic_anniversary", "classic", "live", "forever" }) do
    if selection == "SEC-03-mutable" then
        local s, R, profile, _, modern = fixture(client, "combat")
        R.ActionBars.Apply(profile.bars)
        profile.bars.slots[1].id = 116; profile.bars.stanceCustomSlots[1].id = 116
        s.combat = false; s.regen()
        check(s.custom[1].id == 133 and (modern or s.slots[1].id == 133), "queued restore must use its original detached snapshot")
    end
    if selection == "SEC-03-cancel" then
        local s, R = fixture(client, "combat")
        R.Apply.Run("Cancelled")
        R.Apply.Cancel(); s.combat = false; s.regen()
        check(s.placements == 0 and not s.custom, "cancelled profile must not restore action bars after combat")
    end
    if selection == "SEC-02-bundle" then
        local _, R, profile = fixture(client, "stance_false")
        check(R.PresetBundle.ApplyBarsSnapshot(profile.bars) == false, "preset bundle must propagate the restore result rather than pcall status")
    end
    if not selection or selection == "SEC-02" then
        for _, mode in ipairs({ "stance_throw", "stance_false" }) do
            local s, R = fixture(client, mode)
            check(R.Apply.Run("Test"), "load request accepted")
            local done = s.done()
            check(#done == 1 and done[1][2] == false, client .. " " .. mode .. " must report failure")
            check(not R.Apply.IsRunning() and s.checkpoint and s.checkpoint.step == "bars" and s.clears == 0,
                client .. " failed bars retain retry checkpoint")
        end
        local _, _, _, _, modern = fixture(client)
        if not modern then
            for _, mode in ipairs({ "pickup_throw", "pickup_false", "pickup_noop", "place_throw", "place_noop", "read_throw", "clear_throw" }) do
                local s, R = fixture(client, mode)
                R.Apply.Run("Failure")
                check(#s.done() == 1 and not s.done()[1][2] and s.checkpoint and s.clears == 0, client .. " " .. mode .. " is a retryable failure")
                check(not R.Apply.IsRunning(), "failed restore releases active profile")
            end
        end
        do
            local s, R, profile = fixture(client, "stance_false")
            local ok = R.PresetBundle.ApplyBarsSnapshot(profile.bars)
            check(ok == false, client .. " preset bundle propagates actual action-bar failure")
        end
    end
    if not selection or selection == "SEC-03" then
        do
            local s, R, profile, _, modern = fixture(client, "combat")
            R.Apply.Run("Deferred")
            check(R.Apply.IsRunning() and #s.done() == 0 and s.placements == 0 and not s.custom, client .. " deferred bars keep profile pending")
            profile.bars.slots[1].id = 116; profile.bars.stanceCustomSlots[1].id = 116
            s.regen()
            check(R.Apply.IsRunning() and #s.done() == 0 and not s.custom, "spurious regen in combat remains pending")
            s.combat = false; s.regen()
            check(#s.done() == 1 and s.done()[1][2] and not R.Apply.IsRunning() and not s.checkpoint, "real completion advances once")
            check(s.custom[1].id == 133, "deferred stance data detached from editable profile")
            check(modern and s.placements == 0 or (not modern and s.slots[1].id == 133), "deferred slots detached; modern loadouts still own native slots")
        end
        do
            local s, R = fixture(client, "combat")
            R.Apply.Run("Cancelled")
            local stale = s.frames[1].OnEvent
            R.Apply.Cancel()
            check(#s.done() == 1 and not s.done()[1][2] and s.done()[1][3] == "CANCELLED", "cancel reports once")
            check(not s.frames[1].OnEvent and not next(s.frames[1].events), "cancel retires owned combat watcher")
            s.combat = false; stale(s.frames[1], "PLAYER_REGEN_ENABLED"); s.regen()
            check(s.placements == 0 and not s.custom and #s.done() == 1, "cancelled stale callback cannot restore bars")
            R.Apply.Run("Next")
            check(#s.done() == 2 and s.done()[2][2], "new profile can complete after cancellation")
        end
        do
            local s, R, profile = fixture(client, "combat")
            local first, second = {}, {}
            local function owner1(...) first[#first + 1] = { ... } end
            local function owner2(...) second[#second + 1] = { ... } end
            local ok, reason = R.ActionBars.Apply(profile.bars, owner1)
            check(not ok and reason == "IN_COMBAT", "queue exposes deferred result")
            local stale = s.frames[1].OnEvent
            profile.bars.stanceCustomSlots[1].id = 116
            R.ActionBars.Apply(profile.bars, owner2)
            check(#first == 1 and not first[1][1] and first[1][2] == "SUPERSEDED", "superseded request settles exactly once")
            check(not R.ActionBars.CancelPendingApply(owner1), "old owner cannot cancel newer request")
            s.combat = false; stale(s.frames[1], "PLAYER_REGEN_ENABLED")
            check(not s.custom and #second == 0, "old event cannot consume replacement")
            s.regen()
            check(#second == 1 and second[1][1] and s.custom[1].id == 116, "new owner completes its own detached snapshot")
        end
        do
            local s, R, profile = fixture(client, "combat")
            local incoming, nested = {}, {}
            R.ActionBars.Apply(profile.bars, function(ok, reason)
                check(not ok and reason == "SUPERSEDED", "old request settles before reentrant replacement")
                local nextSnap = copy(profile.bars); nextSnap.stanceCustomSlots[1].id = 1459
                R.ActionBars.Apply(nextSnap, function(...) nested[#nested + 1] = { ... } end)
            end)
            local ok, reason = R.ActionBars.Apply(profile.bars, function(...) incoming[#incoming + 1] = { ... } end)
            check(not ok and reason == "SUPERSEDED" and #incoming == 1, "reentrant newer request supersedes the interrupted incoming call")
            s.combat = false; s.regen()
            check(#nested == 1 and nested[1][1] and s.custom[1].id == 1459, "reentrant latest owner survives the older caller's return")
        end
    end
    if not selection then
        do
            local s, R, profile = fixture(client, "combat")
            local completions, successes = 0, 0
            for i = 1, 1000 do
                profile.bars.stanceCustomSlots[1].id = i
                R.ActionBars.Apply(profile.bars, function(ok)
                    completions = completions + 1
                    if ok then successes = successes + 1 end
                end)
            end
            check(#s.frames == 1 and completions == 999 and successes == 0, "combat spam retains one watcher and one pending owner")
            s.combat = false; s.regen()
            check(completions == 1000 and successes == 1 and s.custom[1].id == 1000, "latest spam request completes exactly once")
            s.combat = true; R.ActionBars.Apply(profile.bars)
            check(#s.frames == 1, "later combat cycle reuses the dormant watcher")
            R.ActionBars.CancelPendingApply()
            check(not s.frames[1].OnEvent and not next(s.frames[1].events), "idle watcher retains no active closure/event")
        end
        local s, R, profile, _, modern = fixture(client)
        profile.bars.slots = {
            [1] = { type = "spell", id = 133 }, [2] = { type = "item", id = 6948 },
            [3] = { type = "macro", id = 1, name = "Macro1" }, [4] = { type = "equipmentset", id = 1, name = "Set1" },
            [5] = { empty = true }, [6] = { type = "mount", id = 10 }, [7] = { type = "companion", id = 11, subType = "MOUNT" },
            [8] = { type = "summonpet", id = "pet-id" },
        }
        s.slots[5] = { type = "spell", id = 116 }
        R.Apply.Run("Public controls")
        check(#s.done() == 1 and s.done()[1][2] and not s.checkpoint, client .. " ordinary restore succeeds once")
        check(s.custom[1].id == 133 and s.order[1] == "spell:133" and s.hidden["spell:133"], "stance order/hidden/custom features retained")
        if modern then
            check(s.placements == 0 and s.pickups == 0 and s.slots[5].id == 116, "modern native loadout slots untouched")
        else
            check(not s.slots[5] and s.slots[1].id == 133 and s.slots[2].id == 6948 and s.slots[3].type == "macro"
                and s.slots[4].type == "equipmentset" and s.slots[6].type == "mount" and s.slots[7].type == "companion"
                and s.slots[8].type == "summonpet", "classic spell/item/macro/equipment/mount/companion/pet/clear restore retained")
            local placements = s.placements
            R.Apply.Run("Matching")
            check(s.placements == placements and #s.done() == 2 and s.done()[2][2], "already matching fast path avoids rewrites")
        end
    end
end
print("respec action-bar completion: " .. checks .. " checks passed (" .. (selection or "all cases") .. "; five client models; native pending)")
