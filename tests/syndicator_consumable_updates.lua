-- Production Syndicator adapter, inventory fan-out and consumable selection listener.
local source = arg[1] or "Inventory/Syndicator/Adapter.lua"
local checks, failed = 0, 0
local function check(ok, label)
 checks = checks + 1
 if not ok then failed = failed + 1; print("FAIL " .. label) end
end
local kinds = { "food", "water", "healPotion", "manaPotion", "bandage" }
local function boot(kind, client)
 local h = { now = 100, timers = {}, callbacks = {}, scans = 0 }
 local env = setmetatable({}, { __index = _G }); env._G = env
 env.GetTime = function() return h.now end
 env.SlashCmdList = {}
 env.C_Timer = { After = function(delay, fn) h.timers[#h.timers + 1] = { due = h.now + delay, fn = fn } end }
 env.CreateFrame = function()
  return { SetScript = function() end, RegisterEvent = function() end }
 end
 local flux = { Cap = {}, Client = { isRetail = client == "retail" or client == "forever",
  isForever = client == "forever", isAnyClassic = client ~= "retail" and client ~= "forever" }, Module = { Register = function() end },
  Safecall = function(fn, ...) return fn(...) end,
  Scheduler = { Request = function() end },
  Timer = { After = env.C_Timer.After } }
 env.Flux = flux
 local ns = { Flux = flux }
 for _, p in ipairs({ "Inventory/Init.lua", "Inventory/Containers.lua", "Inventory/Index.lua", "Inventory/LegacyBridge.lua" }) do
  assert(loadfile(p, "t", env))("_FluxUI", ns)
 end
 local inv = flux.Inventory
 local char = { bags = { { { itemID = 100, itemCount = 5 } }, { { itemID = 900, itemCount = 1 } } } }
 env.Syndicator = { Constants = { AllBagIndexes = { 0, 1 }, AllBankIndexes = {} },
  API = { IsReady = function() return true end, GetCurrentCharacter = function() return "Fixture-Realm" end,
   GetCharacter = function() return char end },
  CallbackRegistry = { RegisterCallback = function(_, event, fn) h.callbacks[event] = fn end } }
 assert(loadfile(source, "t", env))("_FluxUI", ns)
 local adapter = inv.Syndicator
 adapter.RebuildAll = function() adapter.RebuildBags() end -- excluded regions are not exercised
 adapter.Start()
 inv.Notify({ bags = true })
 local best = { _runtime = { [kind] = { itemID = 100, source = "owned" } }, _listeners = {}, _dirty = false,
  KINDS = kinds, Persist = { GetRoot = function() end }, VendorMemory = { HookMerchantIndex = function() end } }
 env.FluxConsumableBest = best
 env.FluxItemClass = { GetStatic = function(id) return { classID = id < 900 and 0 or 2 } end }
 assert(loadfile("Inventory/FluxConsumableBest/FluxConsumableBest.lua", "t", env))()
 best.RequestRecompute = function() h.scans = h.scans + 1; best._dirty = false end
 best.Init()
 local latest
 inv.Register("Fixture", function(ctx) latest = ctx end, { tier = "light", regions = { "bags" }, sync = true })
 function h.pulse(slots, bag, full)
  char.bags[bag + 1] = slots
  h.callbacks.BagCacheUpdate(nil, "Fixture-Realm", { bags = { [bag] = true }, containerBags = { bags = full } })
 end
 function h.flush()
  inv.Notify({ bags = true })
  local n = 0
  while #h.timers > 0 do
   table.sort(h.timers, function(a,b) return a.due < b.due end)
   local t = table.remove(h.timers, 1); h.now = t.due; t.fn(); n = n + 1; assert(n < 100)
  end
  return latest
 end
 h.inv, h.adapter = inv, adapter
 h.callbacksCount = function() local n = 0; for _ in pairs(h.callbacks) do n = n + 1 end; return n end
 return h
end
for _, client in ipairs({ "retail", "forever", "era", "anniversary", "mists" }) do
for _, kind in ipairs(kinds) do
 local h = boot(kind, client)
 h.pulse({ { itemID = 100, itemCount = 5 }, { itemID = 200, itemCount = 2 } }, 0)
 h.pulse({ { itemID = 900, itemCount = 2 } }, 1)
 local ctx = h.flush()
 check(ctx.changeKind == "identityChanged" and ctx.addedItemIDs and ctx.addedItemIDs[200], kind .. ": better-item identity survives later count pulse")
 check(h.scans == 1, kind .. ": better-item acquisition requests one selector scan")
 check(ctx.dirtyBags[0] and ctx.dirtyBags[1], kind .. ": both changed bags retained")
 check(h.inv.GetCount(200) == 2, kind .. ": new stack count current")
 -- No previous addition may leak into another publication.
 local scans = h.scans
 h.pulse({ { itemID = 900, itemCount = 3 } }, 1)
 ctx = h.flush()
 check(ctx.changeKind == "countOnly" and not ctx.addedItemIDs and h.scans == scans, kind .. ": unrelated count-only pulse avoids rescan")
 -- Losing the last owned consumable followed by an unrelated identity update.
 local d = boot(kind, client)
 d.pulse({}, 0)
 d.pulse({ { itemID = 901, itemCount = 1 } }, 1)
 ctx = d.flush()
 check(ctx.removedItemIDs and ctx.removedItemIDs[100], kind .. ": last-use removal survives later identity pulse")
 check(d.inv.GetCount(100) == 0 and ctx.changedItemIDs[100], kind .. ": zero count and changed-item set reach consumers")
 check(d.scans == 1, kind .. ": last-use depletion requests one selector scan")
 -- Full cache updates must preserve an earlier incremental acquisition too.
 local f = boot(kind, client)
 f.pulse({ { itemID = 100, itemCount = 5 }, { itemID = 200, itemCount = 1 } }, 0)
 f.pulse({ { itemID = 900, itemCount = 2 } }, 1, true)
 ctx = f.flush()
 check(ctx.addedItemIDs and ctx.addedItemIDs[200] and f.scans == 1, kind .. ": full snapshot retains pending acquisition")
 check(ctx.changedItemIDs == nil, kind .. ": full snapshot retains unknown item-diff semantics")
 -- A sequence of distinct cache callbacks still owes only one selection scan.
 local b = boot(kind, client)
 local callbacks = b.callbacksCount()
 for cycle = 1, 100 do
  b.pulse({ { itemID = 100, itemCount = 5 }, { itemID = 200, itemCount = cycle } }, 0)
  b.pulse({ { itemID = 900, itemCount = cycle + 1 } }, 1)
 end
 ctx = b.flush()
 check(b.scans == 1 and b.inv.GetCount(200) == 100, kind .. ": 200-callback burst coalesces with latest counts")
 check(b.callbacksCount() == callbacks and #b.timers == 0, kind .. ": burst adds no subscriptions or retained timers")
 -- Ignore other characters and retain the last publication's public metadata.
 local generation = b.inv.GetBagGeneration()
 b.callbacks.BagCacheUpdate(nil, "Other-Realm", { bags = { [0] = true } })
 check(b.inv.GetBagGeneration() == generation, kind .. ": other-character callback cannot replace current bags")
 check(b.adapter.GetLastBagsAddedItemIDs() and b.adapter.GetLastBagsAddedItemIDs()[200], kind .. ": last-change accessor remains available after publication")
 local c = boot(kind, client)
 c.pulse({ { itemID = 100, itemCount = 4 } }, 0)
 ctx = c.flush()
 check(c.inv.GetCount(100) == 4 and ctx.changedItemIDs[100] and c.scans == 0, kind .. ": nonempty stack change refreshes counts without selection scan")
 c.pulse({}, 0); ctx = c.flush()
 check(c.inv.GetCount(100) == 0 and c.scans == 1, kind .. ": single last-item use still clears selection")
end
end
print(("Syndicator consumable updates: %d checks, %d failures"):format(checks, failed))
os.exit(failed > 0 and 1 or 0)
