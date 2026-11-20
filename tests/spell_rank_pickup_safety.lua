-- Exercise the production rank manager with cursor/slot boundaries. A spell
-- cursor's second field is a book index; the stable spell ID is fourth.
local root = arg[1] or "."
local selection = arg[2]
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function read(path)
    local f = assert(io.open(path, "rb")); local source = f:read("*a"); f:close(); return source
end
local function compile(source, env)
    if setfenv then local fn = assert(loadstring(source)); setfenv(fn, env); return fn end
    return assert(load(source, "@spell_rank_pickup_safety", "t", env))
end
local OLD, NEW, FOREIGN = 101, 202, 909
local function fixture(client, mode)
    local s = { slot = OLD, pickups = 0, placements = 0, clears = 0, messages = {}, timers = {}, events = {}, applies = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local flux = { Bars = {}, Client = { isEra = client == "era", isForever = client == "forever",
        isLiveMidnight = client == "live", isCata = client == "classic" },
        Spell = { GetName = function() return "Test Spell" end,
            GetSubtext = function(id) return id == NEW and "Rank 2" or "Rank 1" end },
        AfterLoad = function() end, AfterLogin = function() end,
        Events = { Register = function(event, fn) s.events[event] = fn end } }
    env.C_Timer = { After = function(delay, fn) s.timers[#s.timers + 1] = { delay = delay, fn = fn } end }
    env.C_SpellBook = { IsSpellBookItemLowRank = client ~= "live" and client ~= "classic" and function() end or nil }
    env.print = function(message) s.messages[#s.messages + 1] = message end
    env.InCombatLockdown = function() return s.combat == true end
    env.GetNumSpellTabs = function() return 1 end
    env.GetSpellTabInfo = function() return "Spells", nil, 0, 2 end
    env.GetSpellBookItemInfo = function(index) return "SPELL", index == 1 and OLD or NEW end
    env.HasAction = function(slot) return slot == 1 and s.slot ~= nil end
    env.GetActionInfo = function(slot)
        if slot == 1 and s.slot then return "spell", s.slot end
    end
    env.issecretvalue = function(value) return type(value) == "table" and value.secret == true end
    env.GetCursorInfo = function()
        if mode == "cursor_throw" or (mode == "cursor_throw_after" and s.pickups > 0) then error("cursor unavailable") end
        local cursor = s.cursor
        if cursor then return cursor.kind, cursor.bookIndex, "spell", cursor.id end
    end
    env.ClearCursor = function() s.clears = s.clears + 1; s.cursor = nil end
    local function pickup(id)
        s.pickups = s.pickups + 1
        if mode == "pickup_throw" then error("pickup failed") end
        if mode == "pickup_false" then return false end
        if mode == "pickup_noop" then return end
        s.cursor = { kind = "spell", bookIndex = 7, id = id }
        if mode == "wrong_spell" then s.cursor.id = FOREIGN; s.cursor.bookIndex = NEW end
        if mode == "unknown_spell" then s.cursor.id = nil; s.cursor.bookIndex = NEW end
        if mode == "wrong_type" then s.cursor.kind = "item" end
        if mode == "secret_spell" then s.cursor.id = { secret = true } end
        if mode == "pickup_changes_slot" then s.slot = FOREIGN end
        if mode == "pickup_combat" then s.combat = true end
    end
    if client == "era" then env.PickupSpell = pickup else env.C_Spell = { PickupSpell = pickup } end
    if mode == "missing_pickup" then env.PickupSpell = nil; env.C_Spell = nil end
    if mode == "missing_cursor" then env.GetCursorInfo = nil end
    env.PlaceAction = function(slot)
        check(not s.combat, client .. " native placement stays outside combat")
        check(slot == 1, client .. " original slot identity retained")
        s.placements = s.placements + 1
        if mode == "place_throw" then error("placement failed") end
        if mode == "place_noop" then return end
        local old = s.slot
        -- This models the destructive native behavior behind the bug: placing
        -- an empty cursor picks up/removes the existing action.
        s.slot = s.cursor and s.cursor.id or nil
        s.cursor = old and { kind = "spell", bookIndex = 3, id = old } or nil
        if mode == "place_wrong" then s.slot = FOREIGN end
        if mode == "place_foreign_cursor" then s.cursor = { kind = "item", id = FOREIGN } end
    end
    s.binding = { action = { type = "spell", id = OLD } }
    env.FluxBindingDB3API = { All = function() return { s.binding } end }
    env.FluxBinding = { RequestApplyAll = function() s.applies = s.applies + 1 end }
    env._FluxUI_CharSavedVars = { spellRankManager = { autoRankUp = mode == "automatic", blacklist = {} } }
    compile(read(root .. "/Bars/SpellRank.lua"), env)("_FluxUI", { Flux = flux })
    s.manager = flux.Bars.SpellRank
    if mode == "busy_cursor" then s.cursor = { kind = "item", id = FOREIGN } end
    if mode == "busy_spell" then s.cursor = { kind = "spell", bookIndex = 13, id = OLD } end
    if mode == "combat" then s.combat = true end
    return s, env
end

for _, client in ipairs({ "era", "forever" }) do
    for _, mode in ipairs({ "pickup_noop", "pickup_false", "pickup_throw", "wrong_spell", "unknown_spell", "wrong_type",
        "secret_spell", "cursor_throw", "cursor_throw_after", "missing_cursor", "missing_pickup", "busy_cursor", "busy_spell",
        "pickup_changes_slot", "pickup_combat", "place_noop", "place_throw", "place_wrong", "combat" }) do
        if not selection or selection == mode then
            local s = fixture(client, mode)
            s.manager:RankUpAllSpells(true)
            local expected = (mode == "pickup_changes_slot" or mode == "place_wrong") and FOREIGN or OLD
            check(s.slot == expected, client .. " " .. mode .. " retains the destination action")
            check(s.binding.action.id == OLD and s.applies == 0, client .. " " .. mode .. " does not advance saved binding IDs")
            check(#s.messages == 0, client .. " " .. mode .. " does not report a failed upgrade as success")
            if not mode:match("^place_") then check(s.placements == 0, client .. " " .. mode .. " never places unverified cursor") end
            if mode == "busy_cursor" or mode == "busy_spell" then
                check(s.pickups == 0 and s.clears == 0 and s.cursor.id == (mode == "busy_spell" and OLD or FOREIGN),
                    client .. " " .. mode .. " preserves the player's cursor")
            elseif mode == "wrong_spell" or mode == "unknown_spell" or mode == "wrong_type" or mode == "secret_spell" then
                check(s.clears == 0 and s.cursor ~= nil, client .. " " .. mode .. " leaves an unexpected cursor untouched")
            end
            if mode:match("^place_") then
                check(s.clears == 0 and s.cursor ~= nil, client .. " " .. mode .. " preserves the cursor for recovery after failure")
            end
        end
    end
    if not selection then
        for _, mode in ipairs({ "success", "place_foreign_cursor", "automatic" }) do
            local s = fixture(client, mode)
            if mode == "automatic" then
                s.events.SPELLS_CHANGED()
                check(s.slot == OLD and s.placements == 0, client .. " auto rank retains existing debounce")
                local timer
                for _, candidate in ipairs(s.timers) do if candidate.delay == 0.45 then timer = candidate end end
                check(timer ~= nil, client .. " automatic rank event retains 450ms timer")
                timer.fn()
            else s.manager:RankUpAllSpells(true) end
            check(s.slot == NEW and s.placements == 1, client .. " " .. mode .. " places the fourth-field spell identity")
            check(s.binding.action.id == NEW and s.applies == 1, client .. " " .. mode .. " advances bindings after verified replacement")
            check(#s.messages == 1 and s.messages[1]:find("Upgraded 2 spell", 1, true), client .. " " .. mode .. " counts only successful upgrades")
            if mode == "place_foreign_cursor" then
                check(s.cursor and s.cursor.kind == "item" and s.clears == 0, client .. " foreign cursor after placement is retained")
            else check(s.cursor == nil and s.clears == 1, client .. " displaced old action cursor is cleaned up once") end
        end
        do
            local s = fixture(client, "disabled")
            s.events.SPELLS_CHANGED()
            check(s.placements == 0 and s.pickups == 0 and s.binding.action.id == OLD, client .. " default-disabled rank policy retains actions/bindings")
            for _, timer in ipairs(s.timers) do check(timer.delay ~= 0.45, client .. " disabled auto rank queues no upgrade") end
        end
        do
            local s = fixture(client, "busy_cursor")
            s.slot = nil
            s.manager:RankUpAllSpells(true)
            check(s.binding.action.id == OLD and s.applies == 0 and s.pickups == 0 and s.clears == 0,
                client .. " busy cursor also prevents binding-only rank rewrites with no native slots")
        end
    end
end
if not selection then
    for _, client in ipairs({ "live", "classic" }) do
        local s = fixture(client, "success")
        s.manager:RankUpAllSpells(true)
        check(s.pickups == 0 and s.placements == 0 and s.binding.action.id == OLD, client .. " existing no-rank policy remains")
    end
end
print("spell_rank_pickup_safety: " .. checks .. " checks PASS")
