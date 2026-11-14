-- Reproduce use/cooldown-only updates and another writer restoring a stale digit.
local f = assert(io.open("tests/combat_grid_live_counts.lua"))
local source = f:read("*a"); f:close()
local original = '{ "ExtraButtonSystem/Engine/Paint.lua", "ExtraButtonSystem/Engine/ConsumableBind.lua" }'
local start, finish = assert(source:find(original, 1, true))
source = source:sub(1, start - 1) .. '{ "ExtraButtonSystem/Engine/Paint.lua", "ExtraButtonSystem/Engine/ConsumableBind.lua", "ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua", "ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua" }' .. source:sub(finish + 1)
local stop = assert(source:find('for _, family in ipairs', 1, true))
local env = setmetatable({ arg = arg }, { __index = _G })
local boot, provider, entries = assert(load(source:sub(1, stop - 1) .. "return boot, provider, entries", "@use-event-fixture", "t", env))()
local checks, failures, immediate, settled = 0, 0, 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
for _, family in ipairs({ "forever", "retail", "mists", "era", "anniversary" }) do
 for _, inventory in ipairs({ "builtin", "syndicator" }) do
  for _, entry in ipairs(entries) do
    local kind, id, key = entry[1], entry[2], entry[3]
    local charged = entry[4] or kind == "healthstone" and (family == "retail" or family == "mists")
    local s = boot(family, family == "era" or family == "anniversary")
    if inventory == "syndicator" then provider(s) end
    s:set(0, 1, id, 1); s:set(1, 1, id == 159 and 118 or 159, 3); s.uses[id] = charged and 1 or 0
    if s.publish then s:publish() else s:bags() end
    s:advance(9)
    s.bridge.GetPreferredCreateSpell = function() return 1, "Create fixture" end
    s.bridge.GetNextManaGemConjureSpell = s.bridge.GetPreferredCreateSpell
    s.bridge.KnowsManaGemConjureSpell = function() return true end
    s.bridge.ShouldStickyManaGemItem = function() return true end
    local path = kind == "managem" and "ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua"
        or kind == "healthstone" and "ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua" or nil
    local btn, module = s:button(kind, false, path)
    s.env[key] = module; s:advance(0.4); s.combat = true
    local label = family .. "/" .. inventory .. "/" .. kind .. "/" .. id
    local writes, scans, frames = s.writes, s.scans, #s.frames
    check(btn.ItemId == id and btn.WCount.value == "1", label .. " owned single use")
    -- No BAG_UPDATE, BAG_UPDATE_DELAYED or companion publication accompanies use.
    s:set(0, 1, id, 0); s.uses[id] = 0
    s:event("BAG_UPDATE_COOLDOWN"); s:advance(0)
    check(btn.WCount.value == "0", label .. " cooldown-only depletion")
    check(btn.WIcon.color[1] == 0.4, label .. " cooldown-only empty tint")
    check(s.bridge.BagCount(id, { charges = true, kind = kind }) == 0, label .. " native event releases stale owned use")
    check(s.inv.GetCount(id) == 1, label .. " provider deliberately remains stale")
    if family == "forever" or family == "retail" then
        s:set(0, 1, id, 1); s.uses[id] = charged and 1 or 0
        s:event("ITEM_COUNT_CHANGED", id); s:advance(0)
        check(btn.WCount.value == "1" and btn.WIcon.color[1] == 1, label .. " item-count-only refill")
        s:set(0, 1, id, 0); s.uses[id] = 0
        s:event("ITEM_COUNT_CHANGED", id); s:advance(0)
        check(btn.WCount.value == "0", label .. " item-count-only depletion")
    end
    -- Native count may settle one frame after the cooldown event.
    s:set(0, 1, id, 1); s.uses[id] = charged and 1 or 0
    module.RefreshCountOnly(); s:advance(0.2)
    s:event("BAG_UPDATE_COOLDOWN"); s:advance(0)
    s:set(0, 1, id, 0); s.uses[id] = 0; s:advance(0.11)
    check(btn.WCount.value == "0", label .. " late native count settles without another bag event")
    check(s.writes == writes and s.scans == scans and #s.frames == frames, label .. " no protected writes/scans/new frames")
    -- Cache says zero, but another real SetCount writer has restored one.
    -- Use an up-to-date snapshot to isolate this painter regression.
    s:bags(0.4); s.paint.UpdateCount(btn)
    btn:SetCount(1, { live = true, itemId = id })
    check(btn._lastCountText == "0" and btn.WCount.value == "1", label .. " second writer creates stale visible one")
    s.paint.UpdateCount(btn)
    check(btn.WCount.value == "0", label .. " cached zero repairs wrong nonblank visible digit")
    s:set(0, 1, id, 1); s.uses[id] = charged and 1 or 0
    s:bags(0.4); s.paint.UpdateCount(btn)
    btn:SetCount(0, { live = true, itemId = id }); s.paint.UpdateCount(btn)
    check(btn.WCount.value == "1", label .. " cached refill repairs wrong zero")
    -- Do not predict successful use from a cooldown notification.
    s:event("BAG_UPDATE_COOLDOWN"); s:advance(0.2)
    check(btn.WCount.value == "1", label .. " unchanged native count stays one")
    -- Drain selector work requested by the explicit setup bag publications.
    -- The use-event/idle budget begins after that unrelated setup has settled.
    s:advance(1); scans = s.scans
    local recounts = 0
    local refresh = module.RefreshCountOnly
    module.RefreshCountOnly = function(...) recounts = recounts + 1; return refresh(...) end
    for _ = 1, 100 do
        s:event("BAG_UPDATE_COOLDOWN")
        if family == "forever" or family == "retail" then s:event("ITEM_COUNT_CHANGED", id) end
    end
    s:advance(0); immediate = immediate + recounts
    check(recounts == 1, label .. " same-frame use burst recounts once")
    s:advance(0.11); settled = settled + recounts
    check(recounts == 2, label .. " one bounded settle recount")
    s:advance(10)
    check(recounts == 2 and s.writes == writes and s.scans == scans and #s.frames == frames, label .. " no idle polling/scans/rebinds")
    if family == "forever" or family == "retail" then
        s:event("ITEM_COUNT_CHANGED", 999998); s:advance(0.2)
        check(recounts == 2, label .. " unrelated item-count event does no recount")
    end
  end
 end
end
for _, family in ipairs({ "mists", "era", "anniversary" }) do
    local s = boot(family, family == "era" or family == "anniversary")
    local create = s.env.CreateFrame
    s.env.CreateFrame = function(...)
        local frame = create(...)
        local register = frame.RegisterEvent
        frame.RegisterEvent = function(self, name)
            if name == "ITEM_COUNT_CHANGED" then error("event unavailable on this client") end
            return register(self, name)
        end
        return frame
    end
    check(pcall(s.load, "ExtraButtonSystem/Engine/ConsumableBind.lua"), family .. " absent optional item-count event does not break initialization")
end
print(("Combat grid use events: %d checks, %d failures; immediateRecounts=%d totalWithSettle=%d"):format(checks, failures, immediate, settled))
os.exit(failures > 0 and 1 or 0)
