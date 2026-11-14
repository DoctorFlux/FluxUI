-- Combat keeps the prepared action at dark/zero; OOC promotes or placeholders.
local function read(path)
    local f = assert(io.open(path)); local text = f:read("*a"); f:close(); return text
end
local smoke = read("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua")
local stop = assert(smoke:find("-- PLAYER_LOGIN bag priming", 1, true))
local fixtureEnv = setmetatable({ arg = { [0] = "ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua" } }, { __index = _G })
if arg[1] then
    fixtureEnv.io = { open = function(path, ...)
        for _, file in ipairs({ "ExtraButtonSystem/Engine/ConsumableBind.lua", "ExtraButtonSystem/Engine/Paint.lua",
            "ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua", "ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua" }) do
            if path:gsub("\\", "/"):sub(-#file) == file then path = arg[1] .. "/" .. file; break end
        end
        return io.open(path, ...)
    end }
end
local boot, items = assert(load(smoke:sub(1, stop - 1) .. "return boot, items", "@depletion-fixture", "t", fixtureEnv))()
local helper = read("tests/combat_grid_live_counts.lua")
local helperStop = assert(helper:find("for _, family in ipairs", 1, true))
local _, provider, entries = assert(load(helper:sub(1, helperStop - 1) .. "return boot, provider, entries", "@provider-fixture", "t", setmetatable({arg={}}, {__index=_G})))()
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
for _, family in ipairs({ "forever", "retail", "mists", "era", "anniversary" }) do
 for _, source in ipairs({ "builtin", "syndicator" }) do
  for _, entry in ipairs(entries) do
    local kind, id, key = entry[1], entry[2], entry[3]
    local fallback = 30000 + id
    if kind == "managem" then
        id = entry[4] and 22044 or 5513; fallback = 5514
        items[5513] = { kind="managem", effective=200, maxStack=1 }
    elseif kind == "healthstone" then
        id, fallback = 5511, 5512
        items[5511] = { kind="healthstone", effective=200, maxStack=1 }
    else
        items[fallback] = { kind=kind, effective=1 }
    end
    local charged = entry[4] or kind == "healthstone" and (family == "retail" or family == "mists")
    local s = boot(family, family == "era" or family == "anniversary")
    if source == "syndicator" then provider(s) end
    s:set(0, 1, id, 1); s:set(0, 2, fallback, 1)
    s.uses[id], s.uses[fallback] = charged and 1 or 0, kind == "healthstone" and charged and 1 or 0
    if s.publish then s:publish() else s:bags() end
    s:advance(9)
    s.bridge.GetPreferredCreateSpell = function() return 1, "Create fixture" end
    s.bridge.GetNextManaGemConjureSpell = s.bridge.GetPreferredCreateSpell
    s.bridge.KnowsManaGemConjureSpell = function() return true end
    s.bridge.ShouldStickyManaGemItem = function() return true end
    s.env.FluxExtraButtonVisibility = { QuickGate = function() return true end, Apply = function() return true end }
    local path = kind == "managem" and "ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua"
        or kind == "healthstone" and "ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua" or nil
    local btn, module = s:button(kind, false, path); s.env[key] = module
    s:advance(0.4)
    local label = family .. "/" .. source .. "/" .. kind .. "/" .. id
    check(btn.ItemId == id, label .. " best initial item")
    if kind == "managem" then
        s:set(0, 2, fallback, 0); s.paint.UpdateUsable(btn)
        check(btn.WIcon.color[1] == 1, label .. " owned gem stays bright with the other tier missing")
        s:set(0, 2, fallback, 1)
    end
    s.combat = true; local writes = s.writes
    s:set(0, 1, id, 0); s.uses[id] = 0
    s:event("BAG_UPDATE_COOLDOWN"); s:advance(0.11)
    s.paint.UpdateCount(btn); s.paint.UpdateUsable(btn)
    check(btn.ItemId == id and s.writes == writes, label .. " combat preserves prepared action")
    check(btn.WCount.value == "0" and btn.WIcon.color[1] == 0.4, label .. " combat is dark zero even with a different fallback owned")
    if kind == "managem" then
        local action, mode, body = btn.ActionType, btn.MacroMode, btn.MacroBody
        btn.ActionType, btn.MacroMode = "macrotext", "item"
        btn.MacroBody = "/castsequence item:" .. id .. ", item:" .. fallback
        s.paint.UpdateCount(btn); s.paint.UpdateUsable(btn)
        check(btn.WCount.value == "0" and btn.WIcon.color[1] == 0.4, label .. " prepared macro face also tints its displayed zero")
        btn.ActionType, btn.MacroMode, btn.MacroBody = action, mode, body
    end
    s.combat = false; s:event("PLAYER_REGEN_ENABLED"); s:advance(0.2)
    check(btn.ItemId == fallback and not btn.PlaceholderTexture, label .. " regen promotes next owned item before provider publication")
    check(btn.WCount.value == "1", label .. " fallback count belongs to displayed item")
    s:set(0, 2, fallback, 0); s.uses[fallback] = 0
    s:event("BAG_UPDATE_COOLDOWN"); s:advance(0.2)
    check(not btn.ItemId and btn.PlaceholderTexture, label .. " OOC last use clears to empty placeholder")
    check(not module._trackedItemID and not module._latchItemID, label .. " no exhausted identity survives OOC")
    if kind == "managem" or kind == "healthstone" then
        s:set(0, 2, fallback, 1); s.uses[fallback] = kind == "healthstone" and charged and 1 or 0
        s:event("BAG_UPDATE_COOLDOWN"); s:advance(0.2)
        check(btn.ItemId == fallback and not btn.PlaceholderTexture and btn.WCount.value == "1", label .. " known conjured refill returns from placeholder before publication")
    end
    if charged then
        s:set(0, 1, id, 1); s:set(0, 2, fallback, 0); s.uses[id] = 1
        if s.publish then s:publish() else s:bags() end
        check(btn.ItemId == id, label .. " charged primary restored")
        s.uses[id] = 0
        if s.publish then s:publish() else s:bags() end
        check(not btn.ItemId and btn.PlaceholderTexture, label .. " zero-charge remnant uses placeholder OOC")
        s.uses[id] = 3
        if s.publish then s:publish() else s:bags() end
        check(btn.ItemId == id and btn.WCount.value == "3", label .. " stack-unchanged recharge returns from placeholder")
    end
  end
 end
end
print(("Combat grid depletion transitions: %d checks, %d failures"):format(checks, failures))
assert(failures == 0, "combat grid depletion transition regression")
return { combatZero = true, nextOwned = true, emptyPlaceholder = true, recharge = true, ownedGemUsable = true }
