-- Real inventory/selection/bind/paint modules; delayed provider facts are intentional.
local file = assert(io.open("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua"))
local fixture = file:read("*a"); file:close()
local stop = assert(fixture:find("-- PLAYER_LOGIN bag priming", 1, true))
local fixtureEnv = setmetatable({ arg = { [0] = "ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua" } }, { __index = _G })
if arg[1] then
    fixtureEnv.io = { open = function(path, ...)
        for _, name in ipairs({ "ExtraButtonSystem/Engine/Paint.lua", "ExtraButtonSystem/Engine/ConsumableBind.lua" }) do
            if path:gsub("\\", "/"):sub(-#name) == name then path = arg[1] .. "/" .. name; break end
        end
        return io.open(path, ...)
    end }
end
local boot = assert(load(fixture:sub(1, stop - 1) .. "return boot", "@live-count-fixture", "t", fixtureEnv))()
local checks, failures, liveQueries, bursts = 0, 0, 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local function provider(s)
    local char, callbacks = { bags = {} }, {}
    s.env.Syndicator = {
        Constants = { AllBagIndexes = { 0, 1 }, AllBankIndexes = {} },
        API = { IsReady = function() return true end, GetCurrentCharacter = function() return "Fixture-Realm" end,
            GetCharacter = function() return char end },
        CallbackRegistry = { RegisterCallback = function(_, event, fn) callbacks[event] = fn end },
    }
    s.load("Inventory/Syndicator/Adapter.lua")
    s.inv.Syndicator.RebuildAll = function() s.inv.Syndicator.RebuildBags() end
    s.inv.Syndicator.Start()
    function s:publish(stale)
        if not stale then
            for i, bag in ipairs({ 0, 1 }) do
                char.bags[i] = {}
                for slot, rec in pairs(self.slots[bag]) do
                    char.bags[i][slot] = { itemID = rec.itemID, itemCount = rec.stackCount, itemLink = rec.hyperlink }
                end
            end
        end
        callbacks.BagCacheUpdate(nil, "Fixture-Realm", { bags = { [0] = true, [1] = true } })
        self:advance(0.4)
    end
end
local entries = {
    { "food", 117, "FluxNCFood" }, { "water", 159, "FluxNCWater" },
    { "bandage", 1251, "FluxCombatBandage" }, { "healPotion", 118, "FluxCombatHealPotion" },
    { "manaPotion", 2455, "FluxCombatManaPotion" },
    { "managem", 5514, "FluxCombatManaGem" }, { "managem", 22044, "FluxCombatManaGem", true },
    { "healthstone", 5512, "FluxCombatHealthstone" },
}
for _, family in ipairs({ "retail", "forever", "mists", "era", "anniversary" }) do
 for _, source in ipairs({ "builtin", "syndicator" }) do
  for _, entry in ipairs(entries) do
    local kind, id, key = entry[1], entry[2], entry[3]
    local charged = entry[4] or kind == "healthstone" and (family == "retail" or family == "mists")
    local s = boot(family, family == "era" or family == "anniversary")
    if source == "syndicator" then provider(s) end
    local function publish(stale)
        if source == "syndicator" then s:publish(stale) else s:bags() end
    end
    local function pulse(delay)
        if source == "syndicator" then s:event("BAG_UPDATE_DELAYED"); s:advance(delay or 0.1) else s:bags(delay) end
    end
    s:set(0, 1, id, 3); s:set(1, 1, id == 159 and 118 or 159, 5); s.uses[id] = charged and 9 or 0
    publish(); s:advance(9)
    local path = kind == "healthstone" and "ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua"
        or kind == "managem" and "ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua" or nil
    -- Keep specialized item-count overrides, using fixed known conjure capability.
    s.bridge.GetPreferredCreateSpell = function() return 1, "Create fixture" end
    s.bridge.GetNextManaGemConjureSpell = s.bridge.GetPreferredCreateSpell
    s.bridge.KnowsManaGemConjureSpell = function() return true end
    s.bridge.ShouldStickyManaGemItem = function() return true end
    local btn, module = s:button(kind, false, path)
    s.env[key] = module; s:advance(0.4)
    local label = family .. "/" .. source .. "/" .. kind .. "/" .. id
    check(btn.ItemId == id, label .. " initial real module identity")
    s.combat = true
    local writes = s.writes
    for _, n in ipairs({ 2, 1, 0 }) do
        s:set(0, 1, id, n); s.uses[id] = charged and n or 0
        pulse()
        check(s.bridge.BagCount(id, { charges = true, kind = kind }) == n, label .. " live owned uses " .. n)
        check(btn.WCount.value == tostring(n), label .. " native event count " .. n)
        s.paint.UpdateCount(btn); s.paint.UpdateUsable(btn)
        check(btn.WCount.value == tostring(n), label .. " repaint count " .. n)
        check(btn.WIcon.color[1] == (n > 0 and 1 or 0.4), label .. " current tint " .. n)
        check(btn.ItemId == id and s.writes == writes, label .. " no secure changes " .. n)
    end
    -- An unchanged stale callback must not resurrect the old copies/charges.
    if source == "syndicator" then
        publish(true); s.paint.UpdateCount(btn)
        check(s.inv.GetCount(id) == 3 and btn.WCount.value == "0", label .. " stale callback stays zero")
    end
    s.uses[id] = charged and 9 or 0; pulse(); s.paint.UpdateCount(btn)
    check(btn.WCount.value == "0", label .. " noncarried charge answers cannot restore count")
    check(module._pendingUpdate, label .. " combat defers selection work")
    s:set(0, 1, id, 1); s.uses[id] = charged and 3 or 0; pulse()
    check(btn.WCount.value == (charged and "3" or "1"), label .. " refill before callback")
    s.cached = false; s.paint.UpdateCount(btn)
    check(btn.WCount.value == (charged and "3" or "1"), label .. " known kind survives metadata gap")
    s.cached = true
    -- Ordinary paints can race the next bag event; they must not freeze a
    -- previously positive native count or show an already exhausted stack.
    if source == "syndicator" then
        s:set(0, 1, id, 0); s.uses[id] = 0
        s.paint.UpdateCount(btn); s.paint.UpdateUsable(btn)
        check(btn.WCount.value == "0" and btn.WIcon.color[1] == 0.4, label .. " paint-only depletion")
        s:set(0, 1, id, 1); s.uses[id] = charged and 3 or 0
        s.paint.UpdateCount(btn); s.paint.UpdateUsable(btn)
        check(btn.WCount.value == (charged and "3" or "1") and btn.WIcon.color[1] == 1, label .. " paint-only refill")
    end
    -- Last charge can disappear without changing stack identity or copy count.
    if charged then
        s.uses[id] = 0; pulse(); s.paint.UpdateCount(btn); s.paint.UpdateUsable(btn)
        check(btn.WCount.value == "0" and btn.WIcon.color[1] == 0.4, label .. " zero-charge remnant")
        s.uses[id] = 3; pulse()
    end
    -- A loading-screen zero retains the last count until recovery is reliable.
    publish(); s.inv.MarkUnreliable("load fixture")
    s:set(0, 1, id, 0); s.uses[id] = 0; pulse(0.01)
    check(btn.WCount.value == (charged and "3" or "1"), label .. " load hold retains count")
    s:advance(9); pulse(); s.paint.UpdateCount(btn)
    check(btn.WCount.value == "0", label .. " expired hold releases zero")
    check(s.writes == writes, label .. " all combat paths avoid protected writes")
    s.combat = false; s:event("PLAYER_REGEN_ENABLED"); s:advance(0.4)
    publish()
    check(btn.WCount.value == "0" or not btn.ItemId, label .. " regen keeps exhausted count empty")
    -- Native-event bursts coalesce counts and never scan bags or rebind in combat.
    s:set(0, 1, id, 3); s.uses[id] = charged and 9 or 0; publish(); s:advance(1)
    s.combat = true
    local queries, refreshes = 0, 0
    local get = s.env.Flux.Item.GetCount
    s.env.Flux.Item.GetCount = function(...) queries = queries + 1; return get(...) end
    local refresh = module.RefreshCountOnly
    module.RefreshCountOnly = function(...) refreshes = refreshes + 1; return refresh(...) end
    local scans, beforeWrites, frames = s.scans, s.writes, #s.frames
    for _ = 1, 100 do s:event("BAG_UPDATE_DELAYED") end
    s:advance(0)
    check(s.scans == scans and s.writes == beforeWrites and #s.frames == frames, label .. " burst bounded ownership")
    if source == "syndicator" then
        check(refreshes == 1, label .. " 100 native pulses coalesce to one recount")
        liveQueries = liveQueries + queries; bursts = bursts + refreshes
    end
  end
 end
end
-- Generic equipped/nonconsumable faces keep the snapshot ownership contract.
do
    local s = boot("forever", false)
    s:set(0, 1, 117, 1); s:bags(); s:advance(9)
    s.inv.source = "syndicator"
    local queries = 0
    s.inv.GetLiveCount = function() queries = queries + 1; return 7 end
    check(s.paint.DisplayItemCount(999001) == nil and queries == 0, "nonconsumable display does not adopt native equipped counts")
end
print(("Combat grid live counts: %d checks, %d failures; provider burst recounts=%d nativeCountQueries=%d"):format(checks, failures, bursts, liveQueries))
os.exit(failures > 0 and 1 or 0)
