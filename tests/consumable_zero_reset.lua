-- End-to-end button reset using the existing production consumer fixture.
local f = assert(io.open("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua")); local source = f:read("*a"); f:close()
local stop = assert(source:find("-- PLAYER_LOGIN bag priming", 1, true))
local fixtureEnv = setmetatable({ arg = { [0] = "ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua" } }, { __index = _G })
if arg[1] then
 fixtureEnv.io = { open = function(path, ...)
  local target = "ExtraButtonSystem/Engine/ConsumableBind.lua"
  if path:gsub("\\", "/"):sub(-#target) == target then path = arg[1] end
  return io.open(path, ...)
 end }
end
local boot, items = assert(load(source:sub(1, stop - 1) .. "return boot, items", "@consumable-fixture", "t", fixtureEnv))()
local checks, failures = 0, 0
local function check(ok, message) checks = checks + 1; if not ok then failures = failures + 1; print("FAIL " .. message) end end
local function provider(s)
 local char, callbacks = { bags = {} }, {}
 s.env.Syndicator = { Constants = { AllBagIndexes = { 0, 1 }, AllBankIndexes = {} },
  API = { IsReady = function() return true end, GetCurrentCharacter = function() return "Fixture-Realm" end,
   GetCharacter = function() return char end },
  CallbackRegistry = { RegisterCallback = function(_, event, fn) callbacks[event] = fn end } }
 s.load("Inventory/Syndicator/Adapter.lua")
 function s:publish()
  for i, bag in ipairs({0, 1}) do
   char.bags[i] = {}
   for slot, rec in pairs(self.slots[bag]) do char.bags[i][slot] = { itemID = rec.itemID, itemCount = rec.stackCount, itemLink = rec.hyperlink } end
  end
  if not self.bound then
   self.inv.Syndicator.RebuildAll = function() self.inv.Syndicator.RebuildBags() end
   self.inv.Syndicator.Start(); self.bound = true
  else callbacks.BagCacheUpdate(nil, "Fixture-Realm", { bags = { [0] = true, [1] = true } }) end
  self:advance(1)
 end
 function s:lateCallback()
  callbacks.BagCacheUpdate(nil, "Fixture-Realm", { bags = { [0] = true, [1] = true } })
  self:advance(1)
 end
end
for _, family in ipairs({ "forever", "retail", "era", "anniversary", "mists" }) do
 for _, entry in ipairs({{"food",117}, {"water",159}, {"healPotion",118}, {"manaPotion",2455}, {"bandage",1251}}) do
  local s = boot(family, family == "era" or family == "anniversary")
  provider(s)
  local kind, id = entry[1], entry[2]
  s:set(0,1,id,3); s:set(1,1,id == 118 and 159 or 118,5); s:publish(); s:advance(9)
  local btn, module = s:button(kind); s:advance(1)
  local keys = { food = "FluxNCFood", water = "FluxNCWater", healPotion = "FluxCombatHealPotion", manaPotion = "FluxCombatManaPotion", bandage = "FluxCombatBandage" }
  s.env[keys[kind]] = module; module.Button = btn
  check(btn.ItemId == id, family .. " " .. kind .. " starts owned")
  s:set(0,1,id,0)
  s:event("BAG_UPDATE_DELAYED"); s:advance(0.4)
  check(s.inv.GetCount(id) == 3, family .. " " .. kind .. " fixture keeps delayed provider snapshot")
  check(btn.ItemId == nil and not btn.ActionType and btn.PlaceholderTexture,
    family .. " " .. kind .. " live zero resets before provider callback")
  s:lateCallback()
  check(btn.ItemId == nil, family .. " " .. kind .. " stale callback cannot resurrect exhausted item")
  s:publish()
  check(btn.ItemId == nil and module._trackedItemID == nil and module._latchItemID == nil, family .. " " .. kind .. " zero clears item/latch")
  check(btn.PlaceholderTexture and not btn.ActionType, family .. " " .. kind .. " zero resets secure action and icon")
  s:set(0,1,id,2); s:publish()
  check(btn.ItemId == id, family .. " " .. kind .. " reacquisition binds again")
  s:set(0,1,id,1); s:event("BAG_UPDATE_DELAYED"); s:advance(0.1)
  s.paint.UpdateCount(btn)
  check(btn.WCount.value == "1" and s.inv.GetCount(id) == 2,
    family .. " " .. kind .. " repaint retains live count before provider catches up")
  local beforeScans, beforeWrites, frames = s.scans, s.writes, #s.frames
  for i = 1,100 do s:event("BAG_UPDATE_DELAYED"); s:advance(0.01) end
  check(s.scans == beforeScans and s.writes == beforeWrites and #s.frames == frames,
    family .. " " .. kind .. " repeated nonempty events add no scans/binds/frames")
  -- A new better stack can be used/removed before the companion publishes it.
  local better = 20000 + id
  items[better] = { kind = kind, effective = 2000 }
  s:set(0,2,better,2); s:publish()
  check(btn.ItemId == better, family .. " " .. kind .. " better item promotes")
  s:set(0,2,better,0); s:event("BAG_UPDATE_DELAYED"); s:advance(0.4)
  check(btn.ItemId == id, family .. " " .. kind .. " depleted better item falls back before callback")
  -- A hold must not erase items merely because native bag APIs flicker to zero.
  s.inv.MarkUnreliable("test load")
  s:set(0,1,id,0); s:event("BAG_UPDATE_DELAYED"); s:advance(0.1)
  check(btn.ItemId == id, family .. " " .. kind .. " loading-screen hold retained")
  s:set(0,1,id,2); s:publish(); s:advance(9)
  s.combat = true; local writes = s.writes
  s:set(0,1,id,0); s:event("BAG_UPDATE_DELAYED"); s:advance(0.4)
  check(btn.ItemId == id and s.writes == writes and btn.WCount.value == "0",
    family .. " " .. kind .. " combat paints zero without secure writes")
  s.combat = false; s:event("PLAYER_REGEN_ENABLED"); s:advance(0.4)
  check(btn.ItemId == nil and module._trackedItemID == nil and not btn.ActionType,
    family .. " " .. kind .. " combat exit clears exhausted action")
  s:set(0,1,id,2); s:publish()
  -- A swap can display the partner while its home kind has no latched item.
  btn._fluxCombatSwapBody, btn.MacroMode = "prepared partner face", "item"
  module._trackedItemID, module._latchItemID = nil, nil
  s:set(0,1,id,0); s:event("BAG_UPDATE_DELAYED"); s:advance(0.4)
  check(btn.ItemId == nil and not btn._fluxCombatSwapBody and btn.PlaceholderTexture,
    family .. " " .. kind .. " partner-only face also resets without a home latch")
 end
end
print(("Consumable zero reset: %d checks, %d failures"):format(checks, failures))
os.exit(failures > 0 and 1 or 0)
