-- Reproduce a reliable inventory with a loading latch still pinning old digits.
local function read(path)
    local f = assert(io.open(path)); local text = f:read("*a"); f:close(); return text
end
local source = read("tests/consumable_hold_reconciliation.lua")
local stop = assert(source:find("for _,family in ipairs", 1, true))
local setup, entries = assert(load(source:sub(1, stop - 1) .. "return setup, entries",
    "@loading-end-fixture", "t", setmetatable({arg = arg}, {__index = _G})))()
local checks, failures, scenarios = 0, 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local function publish(s)
    if s.publish then s:publish() else s:bags() end
end
local function start(family, provider, entry)
    local s, btn, module, id = setup(family, provider, entry)
    s.inv.Start(); s:event("PLAYER_ENTERING_WORLD", true, false); s:advance(9)
    return s, btn, module, id
end
for _, family in ipairs({"forever", "retail", "mists", "era", "anniversary"}) do
 for _, provider in ipairs({"builtin", "syndicator"}) do
  for _, entry in ipairs(entries) do
   for _, order in ipairs({"no-world-entry", "world-entry-before-enabled", "disabled-before-world-entry"}) do
    scenarios = scenarios + 1
    local s, btn, module, id = start(family, provider, entry)
    local label = family .. "/" .. provider .. "/" .. entry[1] .. "/" .. id .. "/" .. order
    if order == "world-entry-before-enabled" then
        s:event("PLAYER_ENTERING_WORLD", false, false); s:advance(0.1)
    end
    s.combat = true
    local writes, digit = s.writes, btn.WCount.value
    s:event("LOADING_SCREEN_ENABLED")
    s:set(0, 1, id, 0); s.uses[id] = 0; publish(s); s:advance(9)
    check(s.inv.IsReliable() and s.best._loadHoldOpen and s.best.ShouldSoftHoldOwned(), label .. " native reliable/open hold state")
    check(s.inv.GetCount(id) == 0 and s.env.Flux.Item.GetCount(id, false, false) == 0
        and s.inv.GetLiveCount(id, {charges=true, bank=false, warband=false}) == 0, label .. " all count sources are zero")
    check(btn.WCount.value == digit and digit ~= "0", label .. " genuine loading retains prior digit")
    s:event("LOADING_SCREEN_DISABLED")
    if order == "disabled-before-world-entry" then s:event("PLAYER_ENTERING_WORLD", false, false) end
    check(not s.best._loadHoldOpen and s.best.ShouldSoftHoldOwned(), label .. " screen completion starts bounded settle")
    s:advance(3.2)
    check(s.inv.IsReliable() and not s.best.ShouldSoftHoldOwned(), label .. " settled inventory releases hold")
    check(btn.WCount.value == "0" and btn.WIcon.color[1] == 0.4, label .. " exhausted face is dark zero in combat")
    check(s.writes == writes and btn.ItemId == id, label .. " no protected combat action change")
    s.combat = false; s:event("PLAYER_REGEN_ENABLED"); s:advance(0.3)
    check(not btn.ItemId and btn.PlaceholderTexture and not module._trackedItemID, label .. " regen clears exhausted item to placeholder")
    s:advance(12)
    local timers, scans, frames = #s.timers, s.scans, #s.frames
    s:event("LOADING_SCREEN_DISABLED"); s:event("LOADING_SCREEN_DISABLED"); s:advance(9)
    check(#s.timers == timers and s.scans == scans and #s.frames == frames,
        label .. " duplicate completion adds no work or driver")
   end
  end
  -- Completing a normal PEW must not restart its world-refresh generation.
  do
    local s, btn, module, id = start(family, provider, entries[1])
    s:event("LOADING_SCREEN_ENABLED"); s:event("PLAYER_ENTERING_WORLD", false, false)
    local timers, untilT = #s.timers, s.best._portalHoldUntil
    s:event("LOADING_SCREEN_DISABLED")
    check(#s.timers == timers and s.best._portalHoldUntil == untilT,
        family .. provider .. " normal world entry already completed the load")
  end
  -- Recovery cancelled by a later loading screen must restart its slot reads.
  do
    local s, btn, module, id = start(family, provider, entries[1])
    local bags, refreshes = s.inv.Builtin.Bags, 0
    if provider == "builtin" then
        local refresh = bags.Refresh
        bags.Refresh = function(...) refreshes = refreshes + 1; return refresh(...) end
    else
        local refresh = s.inv.Syndicator.RebuildBags
        s.inv.Syndicator.RebuildBags = function(...) refreshes = refreshes + 1; return refresh(...) end
    end
    s:event("PLAYER_ENTERING_WORLD", false, false)
    s:event("LOADING_SCREEN_ENABLED"); s:advance(0.2)
    check(refreshes == 0, family .. provider .. " loading cancels old world slot work")
    s:event("LOADING_SCREEN_DISABLED"); s:advance(0.2)
    check(refreshes > 0, family .. provider .. " screen completion restarts cancelled slot reads")
    s:event("LOADING_SCREEN_ENABLED"); s:advance(3)
    check(s.best._loadHoldOpen and s.best.ShouldSoftHoldOwned(), family .. provider .. " old completion cannot release a newer screen")
    s:event("LOADING_SCREEN_DISABLED"); s:advance(9)
    check(not s.best._loadHoldOpen and not s.best.ShouldSoftHoldOwned(), family .. provider .. " latest completion recovers")
  end
  -- An unavailable optional event leaves ordinary world-entry recovery intact.
  do
    local s, btn, module, id = setup(family, provider, entries[1])
    local register = s.env.Flux.Events.Register
    s.env.Flux.Events.Register = function(event, ...)
        if event == "LOADING_SCREEN_DISABLED" then return false end
        return register(event, ...)
    end
    s.inv.Start(); s:event("LOADING_SCREEN_ENABLED"); s:advance(9)
    check(s.best._loadHoldOpen, family .. provider .. " absent optional event preserves loading protection")
    s:event("PLAYER_ENTERING_WORLD", true, false); s:advance(9)
    check(not s.best._loadHoldOpen and not s.best.ShouldSoftHoldOwned(), family .. provider .. " world entry remains a supported fallback")
  end
 end
end
print(("Consumable loading completion: %d checks, %d failures; scenarios=%d"):format(checks, failures, scenarios))
assert(failures == 0, "consumable loading completion regression")
