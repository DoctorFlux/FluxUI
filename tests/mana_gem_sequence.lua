local file = assert(io.open("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua"))
local fixture = file:read("*a")
file:close()
local stop = assert(fixture:find("-- PLAYER_LOGIN bag priming", 1, true))
local env = setmetatable({ arg = { [0] = "ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua" } }, { __index = _G })
if arg[1] then
    local baseline = { ["ManaGem.lua"] = true, ["ConsumableBind.lua"] = true }
    env.io = { open = function(path, ...)
        local name = path:match("([^/\\]+)$")
        if baseline[name] then path = arg[1] .. "/working-" .. name end
        return io.open(path, ...)
    end }
end
local boot = assert(load(fixture:sub(1, stop - 1) .. "return boot", "@mana-gem-fixture", "t", env))()

local failures, checks = 0, 0
local function check(value, label)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. label) end
end

local function sequenceMacro(items)
    return "/castsequence [combat] reset=combat " .. items .. "\n/use [nocombat] " .. items:match("^[^,]+")
end

for _, family in ipairs({ "retail", "forever", "mists", "era", "anniversary" }) do
    local s = boot(family, family == "era" or family == "anniversary")
    local step, queries = 1, 0
    s.env.QueryCastSequence = function(options)
        queries = queries + 1
        check(type(options) == "string" and options:match("^reset=combat item:"), family .. " native query arguments")
        return step
    end
    s.bridge.KnowsManaGemConjureSpell = function() return true end
    s.bridge.IsManaGemConjureFree = function() return true end
    s.bridge.GetNextManaGemConjureSpell = function() return 1, "Conjure fixture" end
    s:set(0, 1, 8008, 1)
    s:bags(); s:advance(9)
    local btn, module = s:button("managem", false, "ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua")
    s:advance(0.4)
    for _, key in ipairs({ "FluxCombatBandage", "FluxCombatHealPotion", "FluxCombatManaPotion", "FluxCombatHealthstone", "FluxCombatAmmo" }) do
        s.env[key] = { _trackedItemID = 1 }
    end
    local manager = s.load("ExtraButtonSystem/CombatGrid/GridManager.lua")
    manager._startupReady = true
    manager._lastBestGeneration = s.best._generation
    check(btn.ActionType == "item" and btn.ActionValue == 8008, family .. " single Ruby uses the native item")
    local conjure = btn.Widget:GetAttribute("type2")

    s:set(0, 3, 5513, 1)
    s:set(0, 4, 5514, 1)
    s:bags()
    local body = sequenceMacro("item:8008,item:5513,item:5514")
    check(btn.ActionType == "macrotext" and btn.ActionValue == body, family .. " skips absent Citrine while the best gem stays Ruby")
    s:set(0, 2, 8007, 1); s:bags()
    check(btn.ActionValue == sequenceMacro("item:8008,item:8007,item:5513,item:5514"), family .. " all four ranks use best-to-worst order")
    s:set(0, 2, 8007, 0); s:bags()
    s:set(0, 1, 8008, 2)
    s:bags()
    body = sequenceMacro("item:8008,item:8008,item:5513,item:5514")
    check(btn.ActionValue == body, family .. " one step per carried copy")
    s:set(0, 4, 5514, 0)
    s:bags()
    body = sequenceMacro("item:8008,item:8008,item:5513")
    check(btn.ActionValue == body, family .. " removes a lower gem without changing best")
    check(not module._pendingUpdate, family .. " grid coalescer clears pending sequence work")
    check(btn.Widget:GetAttribute("type2") == conjure, family .. " right-click conjure persists")
    local writes = s.writes
    s:set(0, 8, 117, 1); s:bags()
    check(s.writes == writes, family .. " unrelated bag change does not rewrite use action")
    check(queries == 0, family .. " no native sequence queries outside combat")

    s.combat = true
    s:event("PLAYER_REGEN_DISABLED")
    s:event("BAG_UPDATE_COOLDOWN"); s:advance(0.12)
    check(btn.ItemId == 8008 and btn.WCount.value == "2", family .. " cooldown alone does not advance the face")
    step = 2
    s:set(0, 1, 8008, 1); s:bags()
    check(btn.ItemId == 8008 and btn.WCount.value == "1", family .. " next copy remains Ruby")
    step = 3
    s:set(0, 1, 8008, 0); s:bags()
    check(btn.ItemId == 5513 and btn.WCount.value == "1", family .. " native step paints Jade during combat")
    check(s.writes == writes and btn.ActionValue == body, family .. " no action rewrites during combat")

    s:set(0, 2, 8007, 1); s:bags()
    check(s.writes == writes and btn.ActionValue == body and btn.ItemId == 5513, family .. " gem gained in combat waits for regen")
    local combatQueries = queries
    s.combat = false
    s:event("PLAYER_REGEN_ENABLED"); s:advance(0.4)
    check(btn.ActionValue == sequenceMacro("item:8007,item:5513") and btn.ItemId == 8007, family .. " regen picks up the new gem and starts at best")
    check(queries == combatQueries, family .. " regen ignores a stale native step")

    -- Replenish a consumed copy before regen so the macro text ends up identical.
    step = 1
    body = btn.ActionValue
    writes = s.writes
    s.combat = true; s:event("PLAYER_REGEN_DISABLED")
    step = 2
    s:set(0, 2, 8007, 0); s:bags()
    check(btn.ItemId == 5513, family .. " combat cursor follows the consumed Citrine")
    s:set(0, 2, 8007, 1); s:bags()
    s.combat = false; s:event("PLAYER_REGEN_ENABLED"); s:advance(0.4)
    check(btn.ActionValue == body and btn.ItemId == 8007 and s.writes == writes,
        family .. " same stock resets its face without a secure rebind")

    s:set(0, 1, 8008, 1); s:bags()
    check(btn.ActionValue == sequenceMacro("item:8008,item:8007,item:5513") and btn.ItemId == 8008,
        family .. " new best rank restarts the out-of-combat action")
    s:set(0, 1, 8008, 0); s:set(0, 2, 8007, 0); s:bags()
    check(btn.ActionType == "item" and btn.ActionValue == 5513, family .. " last carried copy returns to direct use")

    s:set(0, 1, 22044, 1); s.uses[22044] = 3; s:bags()
    check(btn.ActionType == "item" and btn.ActionValue == 22044 and btn.WCount.value == "3", family .. " charged Emerald uses the native item")
    s.bridge.ShouldUseChargeBasedManaGemOnly = function() return true end
    s.uses[22044] = 0; s:bags()
    check(btn.ActionType == "item" and btn.ActionValue == 5513, family .. " having learned Emerald still permits carrying and using Jade")
end
print(("Mana Gem sequence: %d checks, %d failures"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
