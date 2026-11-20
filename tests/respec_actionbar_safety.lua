-- Execute the production action-bar owner against explicit slot/cursor state.
-- Public API mocks establish data-loss guards, not native taint or client support.
local root = arg[1] or ((arg[0]:match("^(.*)[/\\]") or ".") .. "/../")
if not root:match("[/\\]$") then root = root .. "/" end
local selection = arg[2]
local checks, cases = 0, 0
local failures = {}
local function check(value, why)
    checks = checks + 1
    assert(value, why)
end
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = copy(v) end
    return out
end
local function loadModule(path, env, ns)
    local chunk
    if setfenv then
        chunk = assert(loadfile(root .. path))
        setfenv(chunk, env)
    else
        chunk = assert(loadfile(root .. path, "t", env))
    end
    return chunk("_FluxUI", ns)
end
local function fixture(client, mode)
    local state = { slots = {}, macros = {}, pickups = 0, placements = 0,
        actionPickups = 0, cursorClears = 0, combat = false, frames = {} }
    local modern = client ~= "classic"
    local R = { Compat = { HasTalentLoadouts = function() return modern end }, Print = function() end }
    local env = setmetatable({ FluxRespec = R, NUM_ACTIONBAR_PAGES = 18 }, { __index = _G })
    env._G = env
    function env.InCombatLockdown() return state.combat end
    function env.GetActionInfo(slot)
        if state.readFailure == slot then error("unreadable slot") end
        local entry = state.slots[slot]
        if entry then return entry.type, entry.id, entry.subType end
    end
    function env.GetMacroInfo(id)
        local macro = state.macros[id]
        if macro then return macro.name, 1, macro.body end
    end
    function env.GetMacroIndexByName(name)
        for id, macro in pairs(state.macros) do if macro.name == name then return id end end
        return 0
    end
    function env.GetNumMacros()
        local account, character = 0, 0
        for id in pairs(state.macros) do
            if id <= 120 then account = account + 1 else character = character + 1 end
        end
        return account, character
    end
    function env.GetCursorInfo()
        local entry = state.cursor
        if not entry then return end
        if entry.type == "spell" then
            if mode == "pickup-no-spell-id" then return "spell", entry.id, "spell" end
            return "spell", 1, "spell", entry.id
        end
        return entry.type, entry.id, entry.subType
    end
    function env.CursorHasItem() return state.cursor and state.cursor.type == "item" or false end
    function env.ClearCursor()
        state.cursorClears = state.cursorClears + 1
        state.cursor = nil
    end
    local function pickup(kind, id)
        check(not state.combat, "protected pickup must not run in combat")
        state.pickups = state.pickups + 1
        if mode == "pickup-empty" then return end
        if mode == "pickup-false" then return false end
        if mode == "pickup-wrong-type" then state.cursor = { type = "item", id = 6948 }; return end
        if mode == "pickup-wrong-spell" then state.cursor = { type = "spell", id = 116 }; return end
        state.cursor = { type = kind, id = id }
        if mode == "pickup-replaces-slot" then state.slots[1] = { type = "spell", id = 118 } end
        if mode == "pickup-enters-combat" then state.combat = true end
    end
    function env.PickupSpell(id) return pickup("spell", id) end
    function env.PickupItem(id) return pickup("item", id) end
    function env.PickupMacro(id)
        if type(id) == "string" then id = env.GetMacroIndexByName(id) end
        if not state.macros[id] then return end
        return pickup("macro", id)
    end
    function env.PickupAction(slot)
        check(not state.combat, "protected clear must not run in combat")
        state.actionPickups = state.actionPickups + 1
        state.cursor, state.slots[slot] = copy(state.slots[slot]), nil
    end
    function env.PlaceAction(slot)
        check(not state.combat, "protected place must not run in combat")
        state.placements = state.placements + 1
        -- Empty-cursor placement really is destructive: an unsafe implementation
        -- must not pass just because the mock quietly ignores it.
        local previous = state.slots[slot]
        state.slots[slot], state.cursor = copy(state.cursor), copy(previous)
        if mode == "place-replaces-cursor" then state.cursor = { type = "item", id = 19019 } end
        if mode == "place-enters-combat" then state.combat = true end
    end
    function env.CreateFrame()
        local frame = { events = {} }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:SetScript(key, callback) self[key] = callback end
        state.frames[#state.frames + 1] = frame
        return frame
    end
    if modern then
        env.C_Spell = { PickupSpell = env.PickupSpell }
        env.C_Item = { PickupItem = env.PickupItem }
    end
    local stance = {
        GetSavedOrder = function() return state.order end,
        GetHiddenSlots = function() return state.hidden end,
        GetSavedCustomSlots = function() return state.custom end,
        SetSavedOrder = function(value) state.order = value end,
        SetSlotHidden = function(key, value)
            state.hidden = state.hidden or {}; state.hidden[key] = value or nil
        end,
        SetSavedCustomSlots = function(value) state.custom = value end,
        RequestLayout = function() end,
    }
    loadModule("Respec/FluxRespec_ActionBars.lua", env, { Flux = { Bars = { Stance = stance } } })
    return state, R.ActionBars, env
end
local function snapshot(slots)
    return { slots = slots, stanceCustomSlots = {} }
end
local function noWrites(state, why)
    check(state.pickups == 0 and state.placements == 0 and state.actionPickups == 0
        and state.cursorClears == 0, why)
end
local function run(client, name, body)
    if selection and selection ~= name then return end
    cases = cases + 1
    local ok, why = pcall(body)
    if not ok then failures[#failures + 1] = client .. "/" .. name .. ": " .. tostring(why) end
end
for _, client in ipairs({ "live", "forever", "classic" }) do
    run(client, "capture", function()
        local s, bars = fixture(client)
        s.slots[1] = { type = "spell", id = 133 }
        s.slots[71] = { type = "item", id = 6948 }
        local snap = bars.Capture()
        check(snap and snap.slots and snap.slots[1].id == 133, "capture native slots even with talent-loadout API")
        check(snap.slots[71].id == 6948 and snap.slots[2].empty == true, "capture secondary slots and explicit empties")
        noWrites(s, "capture must be read-only")
        s.slots[1].id = 116
        check(snap.slots[1].id == 133, "saved action IDs are detached from live changes")
    end)
    run(client, "persistent-and-transient-slots", function()
        local s, bars = fixture(client)
        s.slots[145] = { type = "spell", id = 133 }
        s.slots[180] = { type = "item", id = 6948 }
        s.slots[121] = { type = "spell", id = 116 }
        s.slots[216] = { type = "item", id = 19019 }
        local snap = bars.Capture()
        check(snap and snap.slots[145].id == 133 and snap.slots[180].id == 6948,
            "persistent extra native pages retain slots145/180")
        check(snap.slots[121] == nil and snap.slots[216] == nil,
            "transient vehicle/override pages are excluded from new saves")
        local old = snapshot({ [1] = { type = "spell", id = 133 },
            [121] = { empty = true }, [216] = { type = "spell", id = 116 } })
        check(bars.Apply(old) == true and s.slots[1].id == 133, "old snapshots still restore their owned native slots")
        check(s.slots[121].id == 116 and s.slots[216].id == 19019,
            "old transient snapshot entries cannot clear or remap live vehicle/override actions")
        check(bars.MatchesSnapshot(old), "old out-of-scope transient entries do not make an unchanged profile differ")
    end)
    run(client, "read-failure", function()
        local s, bars = fixture(client)
        s.readFailure = 1
        local snap, reason = bars.Capture()
        check(snap == nil and type(reason) == "string" and reason ~= "", "unreadable capture must fail instead of saving an empty slot")
        noWrites(s, "failed capture must be read-only")
    end)
    run(client, "restore", function()
        local s, bars = fixture(client)
        s.slots[1] = { type = "spell", id = 116 }
        local snap = snapshot({ [1] = { type = "spell", id = 133 }, [71] = { type = "item", id = 6948 } })
        check(not bars.MatchesSnapshot(snap), "native slot differences must affect matching on every client")
        check(bars.Apply(snap) == true, "ordinary explicit restore succeeds")
        check(s.slots[1].id == 133 and s.slots[71].id == 6948, "restore original exact spell/item IDs")
        check(bars.MatchesSnapshot(snap), "restored state matches snapshot")
    end)
    run(client, "unchanged", function()
        local s, bars = fixture(client)
        s.slots[1] = { type = "spell", id = 133 }
        local snap = snapshot({ [1] = copy(s.slots[1]), [2] = { empty = true } })
        check(bars.MatchesSnapshot(snap) and bars.Apply(snap), "matching native actions remain a no-op")
        noWrites(s, "unchanged profile must not clear, pick up, place, or touch cursor")
    end)
    for _, mode in ipairs({ "pickup-empty", "pickup-false", "pickup-wrong-type", "pickup-wrong-spell", "pickup-no-spell-id" }) do
        run(client, mode, function()
            local s, bars = fixture(client, mode)
            s.slots[1] = { type = "spell", id = 116 }
            local ok, reason = bars.Apply(snapshot({ [1] = { type = "spell", id = 133 } }))
            check(ok == false and type(reason) == "string", "failed pickup must be reported")
            check(s.placements == 0 and s.actionPickups == 0, "unverified cursor must never reach PlaceAction")
            check(s.slots[1] and s.slots[1].id == 116, "failed pickup preserves original native action")
        end)
    end
    for _, mode in ipairs({ "pickup-replaces-slot", "pickup-enters-combat", "place-replaces-cursor", "place-enters-combat" }) do
        run(client, mode, function()
            local s, bars = fixture(client, mode)
            s.slots[1] = { type = "spell", id = 116 }
            local ok, reason = bars.Apply(snapshot({ [1] = { type = "spell", id = 133 } }))
            check(ok == false and type(reason) == "string", "native callback changes leave a failed/retryable restore")
            if mode == "pickup-replaces-slot" then
                check(s.placements == 0 and s.slots[1].id == 118,
                    "pickup callback changing destination cannot overwrite newly installed unrelated action")
            elseif mode == "pickup-enters-combat" then
                check(s.placements == 0 and s.slots[1].id == 116,
                    "combat starting inside pickup prevents protected destination placement")
            elseif mode == "place-replaces-cursor" then
                check(s.placements == 1 and s.slots[1].id == 133 and s.cursor and s.cursor.type == "item" and s.cursor.id == 19019,
                    "placement callback foreign cursor survives successful slot verification")
                check(s.cursorClears == 0, "foreign placement cursor must not be discarded")
            else
                check(s.placements == 1 and s.slots[1].id == 133 and s.cursor and s.cursor.id == 116,
                    "combat starting inside placement retains displaced action on cursor")
                check(s.cursorClears == 0, "placement transition into combat prevents protected cursor cleanup")
            end
        end)
    end
    run(client, "missing-cursor-api", function()
        local s, bars, env = fixture(client)
        env.GetCursorInfo = nil
        s.slots[1] = { type = "spell", id = 116 }
        local snap, reason = bars.Capture()
        check(snap == nil and type(reason) == "string", "capture requires readable cursor state")
        check(bars.Apply(snapshot({ [1] = { type = "spell", id = 133 } })) == false,
            "restore cannot place while cursor state is unavailable")
        noWrites(s, "missing cursor API must preserve all native state")
        check(s.slots[1].id == 116, "missing cursor API preserves existing action")
    end)
    for _, empty in ipairs({ false, true }) do
        run(client, empty and "busy-cursor-clear" or "busy-cursor-place", function()
            local s, bars = fixture(client)
            s.slots[1] = { type = "spell", id = 116 }
            local external = { type = "item", id = 19019 }
            s.cursor = copy(external)
            local entry = empty and { empty = true } or { type = "spell", id = 133 }
            local ok = bars.Apply(snapshot({ [1] = entry }))
            check(ok == false, "external cursor postpones action changes")
            noWrites(s, "busy cursor must be left entirely untouched")
            check(s.cursor and s.cursor.id == external.id and s.slots[1].id == 116, "busy cursor and original slot preserved")
        end)
    end
    run(client, "explicit-empty", function()
        local s, bars = fixture(client)
        s.slots[1] = { type = "spell", id = 116 }
        s.slots[2] = { type = "spell", id = 133 }
        check(bars.Apply(snapshot({ [1] = { empty = true } })) == true, "explicit saved empty clears requested slot")
        check(s.slots[1] == nil and s.slots[2].id == 133, "sparse restore leaves unspecified live slots intact")
        check(s.actionPickups == 1 and s.placements == 0, "clear uses only its owning slot pickup")
    end)
    run(client, "legacy-slot-only-stance", function()
        local s, bars = fixture(client)
        local order, hidden, custom = { "custom:spell:116" }, { ["custom:spell:116"] = true }, { { type = "spell", id = 116 } }
        s.order, s.hidden, s.custom = order, hidden, custom
        local snap = { slots = { [1] = { type = "spell", id = 133 } } }
        check(bars.Apply(snap) == true and s.slots[1].id == 133, "legacy native-slot-only snapshot still restores its slot")
        check(s.order == order and s.hidden == hidden and s.custom == custom,
            "absent stance fields retain existing stance order/hidden/custom collections")
        check(bars.MatchesSnapshot(snap), "absent stance fields do not make restored legacy snapshot differ")
    end)
    local malformed = {
        { [0] = { empty = true } }, { [-1] = { empty = true } },
        { [1.5] = { empty = true } }, { bad = { empty = true } },
        { [1] = {} }, { [1] = false }, { [1] = { type = "spell" } },
        { [1] = { empty = true }, [2] = { type = "spell" } },
        { [1] = { type = "macro", id = 1, name = true } },
        { [1] = { type = "macro", id = 1, name = "Keep", body = {} } },
        { [1] = { type = "spell", id = 133, name = 1 } },
        { [1] = { type = "spell", id = 133, body = false } },
    }
    for i, slots in ipairs(malformed) do
        run(client, "malformed-" .. i, function()
            local s, bars = fixture(client)
            s.slots[1] = { type = "spell", id = 116 }
            s.slots[2] = { type = "spell", id = 133 }
            local ok = bars.Apply(snapshot(slots))
            check(ok == false, "malformed snapshots fail before mutation")
            noWrites(s, "malformed snapshot must not partially clear an earlier slot")
            check(s.slots[1].id == 116 and s.slots[2].id == 133, "invalid input preserves live action IDs")
        end)
    end
    run(client, "macro-index-shift", function()
        local s, bars = fixture(client)
        s.macros[1] = { name = "Other", body = "/cast Other" }
        s.macros[2] = { name = "Keep", body = "/cast Keep" }
        local snap = snapshot({ [1] = { type = "macro", id = 1, name = "Keep", body = "/cast Keep" } })
        check(bars.Apply(snap) == true, "macro reordering restores by saved identity")
        check(s.slots[1] and s.slots[1].id == 2, "saved stale macro index must not select a different macro")
    end)
    run(client, "macro-missing", function()
        local s, bars = fixture(client)
        s.macros[1] = { name = "Other", body = "/cast Other" }
        s.slots[1] = { type = "spell", id = 116 }
        local ok = bars.Apply(snapshot({ [1] = { type = "macro", id = 1, name = "Keep", body = "/cast Keep" } }))
        check(ok == false and s.placements == 0, "missing saved macro must not fall back to reused numeric index")
        check(s.slots[1] and s.slots[1].id == 116, "missing macro preserves original slot")
    end)
    run(client, "macro-duplicate-name", function()
        local s, bars, env = fixture(client)
        s.macros[1] = { name = "Keep", body = "/cast Other" }
        s.macros[2] = { name = "Keep", body = "/cast Keep" }
        env.GetMacroIndexByName = function() return 1 end
        s.slots[1] = { type = "macro", id = 1 }
        local snap = snapshot({ [1] = { type = "macro", id = 1, name = "Keep", body = "/cast Keep" } })
        check(not bars.MatchesSnapshot(snap), "same macro name with a different body must not count as matching")
        check(bars.Apply(snap) == true and s.slots[1].id == 2,
            "reindexed duplicate macro resolves the saved name and body beyond reused original/name index")
        local writes = s.placements
        check(bars.MatchesSnapshot(snap) and bars.Apply(snap) == true and s.placements == writes,
            "resolved duplicate macro is an unchanged no-op on later load")
    end)
    run(client, "deferred-preflight-error", function()
        local s, bars, env = fixture(client)
        s.combat = true
        s.slots[1] = { type = "spell", id = 116 }
        s.macros[1] = { name = "Keep", body = "/cast Keep" }
        local completions = {}
        local ok, reason = bars.Apply(snapshot({ [1] = { type = "macro", id = 1, name = "Keep", body = "/cast Keep" } }),
            function(...) completions[#completions + 1] = { ... } end)
        check(ok == false and reason == "IN_COMBAT" and #completions == 0, "deferred preflight owns a pending completion")
        env.GetMacroInfo = function() error("native macro lookup failed") end
        local frame = assert(s.frames[1])
        local stale = assert(frame.OnEvent)
        s.combat = false
        check(pcall(stale, frame, "PLAYER_REGEN_ENABLED"), "native preflight exception is settled by restore owner")
        check(#completions == 1 and completions[1][1] == false and type(completions[1][2]) == "string",
            "deferred preflight failure settles callback false exactly once")
        check(frame.OnEvent == nil and next(frame.events) == nil and not bars.CancelPendingApply(),
            "failed deferred request retires watcher and pending owner")
        stale(frame, "PLAYER_REGEN_ENABLED")
        check(#completions == 1 and s.slots[1].id == 116, "stale deferred failure cannot repeat or alter original action")
        noWrites(s, "failed native preflight does not mutate action bars or cursor")
    end)
    run(client, "flyout-current-index", function()
        local s, bars, env = fixture(client)
        local flyoutID, currentIndex = 77, 5
        local function pickupBook(index, bank)
            s.bookPickup = { index = index, bank = bank }
            s.pickups = s.pickups + 1
            if index == currentIndex then s.cursor = { type = "flyout", id = flyoutID } end
        end
        env.BOOKTYPE_SPELL = "spell"
        if client == "classic" then
            function env.GetNumSpellTabs() return 1 end
            function env.GetSpellTabInfo() return "General", 1, 0, 6 end
            function env.GetSpellBookItemInfo(index)
                if index == currentIndex then return "FLYOUT", flyoutID end
                return "SPELL", 133
            end
            env.PickupSpellBookItem = pickupBook
        else
            env.Enum = { SpellBookSpellBank = { Player = 0 }, SpellBookItemType = { Spell = 1, Flyout = 4 } }
            env.C_SpellBook = {
                GetNumSpellBookSkillLines = function() return 1 end,
                GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = 6 } end,
                GetSpellBookItemInfo = function(index)
                    if index == currentIndex then return { itemType = 4, actionID = flyoutID } end
                    return { itemType = 1, actionID = 133, spellID = 133 }
                end,
                PickupSpellBookItem = pickupBook,
            }
        end
        s.slots[1] = { type = "spell", id = 116 }
        check(bars.Apply(snapshot({ [1] = { type = "flyout", id = flyoutID } })) == true,
            "flyout restores through its current spellbook position")
        check(s.bookPickup and s.bookPickup.index == currentIndex, "flyout identity must not be reused as a spellbook index")
        check(s.slots[1].type == "flyout" and s.slots[1].id == flyoutID, "flyout action identity survives placement")
    end)
    run(client, "mount-stable-identity", function()
        local s, bars, env = fixture(client)
        env.C_MountJournal = {
            GetMountInfoByID = function(id)
                check(id == 10, "mount lookup uses stable saved mountID")
                return "Saved mount", 32235
            end,
            Pickup = function() error("filtered mount display index must not be used for stable mountID") end,
        }
        local snap = snapshot({ [1] = { type = "mount", id = 10 } })
        check(bars.Apply(snap) == true, "saved mount restores through its stable summon spell")
        check(s.slots[1] and s.slots[1].type == "spell" and s.slots[1].id == 32235,
            "native mount summon action keeps stable spell identity")
        check(bars.MatchesSnapshot(snap), "native spell-backed mount matches saved mount identity")
        local writes = s.placements
        check(bars.Apply(snap) == true and s.placements == writes, "unchanged mount snapshot does not rewrite native slot")
    end)
    for _, mode in ipairs({ "normal", "noop" }) do
        run(client, "outfit-" .. mode, function()
            local s, bars, env = fixture(client)
            env.C_TransmogOutfitInfo = { PickupOutfit = function(id)
                check(not s.combat and id == 55, "outfit pickup uses exact saved identity out of combat")
                s.pickups = s.pickups + 1
                if mode == "normal" then s.cursor = { type = "outfit", id = id } end
            end }
            s.slots[1] = { type = "spell", id = 116 }
            local ok = bars.Apply(snapshot({ [1] = { type = "outfit", id = 55 } }))
            if mode == "normal" then
                check(ok == true and s.slots[1].type == "outfit" and s.slots[1].id == 55,
                    "available outfit API restores exact native outfit action")
                local snap = bars.Capture()
                check(snap and snap.slots[1].type == "outfit" and snap.slots[1].id == 55,
                    "native outfit action participates in complete bar saves")
            else
                check(ok == false and s.placements == 0 and s.slots[1].id == 116,
                    "void outfit pickup without a cursor cannot clear original action")
            end
        end)
    end
    run(client, "profile-save-preservation", function()
        local s, bars, env = fixture(client)
        local R = env.FluxRespec
        local originalBars = snapshot({ [1] = { type = "spell", id = 116 } })
        local originalEquipment, originalTalents, originalBindings = { marker = "gear" }, { marker = "talent" }, { version = 3 }
        local profile = { bars = originalBars, equipment = originalEquipment, talents = originalTalents,
            spellBindings = originalBindings, icon = 1, updatedAt = 42 }
        local store = { profiles = { Keep = profile }, activeName = "Before", unitFrameRespecArmedName = "Before" }
        local captures, events = 0, 0
        R.GetStore = function() return store end
        R.Warn = function() end
        R.Print = function() end
        R.Fire = function() events = events + 1 end
        R.Compat.ClientTag = function() return client end
        R.Equipment = { Capture = function() captures = captures + 1; return {} end }
        R.Talents = { Capture = function() captures = captures + 1; return {} end }
        env.FluxSpellBindings_CaptureSnapshot = function() captures = captures + 1; return {} end
        env.time = function() return 99 end
        -- Compile the complete production CaptureInto function in its documented
        -- local dependencies; unrelated Core initialization/UI boot is excluded.
        local file = assert(io.open(root .. "Respec/FluxRespec_Core.lua", "r"))
        local source = file:read("*a"); file:close()
        local first = assert(source:find("function R.CaptureInto(name)", 1, true))
        local after = assert(source:find("--- Apply a profile by name.", first, true))
        local body = "local R = FluxRespec; local Compat = R.Compat; local EnsureStore = R.GetStore;\n" .. source:sub(first, after - 1)
        local chunk
        if setfenv then chunk = assert(loadstring(body)); setfenv(chunk, env)
        else chunk = assert(load(body, "production CaptureInto", "t", env)) end
        chunk()
        s.readFailure = 1
        local ok, reason = R.CaptureInto("Keep")
        check(ok == false and reason == "ACTION_BARS_READ_FAILED", "profile save propagates action capture failure")
        check(profile.bars == originalBars and profile.equipment == originalEquipment and profile.talents == originalTalents
            and profile.spellBindings == originalBindings, "failed capture retains all existing profile sections")
        check(captures == 0 and events == 0 and profile.updatedAt == 42 and store.activeName == "Before"
            and store.unitFrameRespecArmedName == "Before", "failed capture publishes nothing and preserves save metadata")
        noWrites(s, "failed profile save cannot write protected action state")
        s.readFailure = nil
        s.slots[1] = { type = "unknown-native-action", id = 1 }
        ok, reason = R.CaptureInto("Keep")
        check(ok == false and reason == "ACTION_BARS_UNSUPPORTED_ACTION", "unsupported action capture fails explicitly")
        check(profile.bars == originalBars and profile.equipment == originalEquipment and profile.talents == originalTalents
            and profile.spellBindings == originalBindings and captures == 0 and events == 0,
            "unsupported native action cannot overwrite the last saved setup or publish other sections")
        s.slots[1] = nil
        R.Apply = { IsRunning = function() return true end }
        ok, reason = R.CaptureInto("Keep")
        check(ok == false and reason == "ACTION_BARS_APPLY_PENDING" and profile.bars == originalBars,
            "saving during profile transition preserves previous bars")
        local snap
        snap, reason = bars.Capture()
        check(snap == nil and reason == "ACTION_BARS_APPLY_PENDING", "direct bundle captures cannot save a partially loaded profile")
    end)
end
for _, why in ipairs(failures) do io.stderr:write(why .. "\n") end
if #failures > 0 then error("respec action-bar safety: " .. #failures .. "/" .. cases .. " cases failed", 0) end
print("respec action-bar safety: " .. checks .. " checks / " .. cases .. " cases passed (live/forever/classic; native pending)")
