-- Metadata contracts only: this does not execute WoW's taint VM or use an item.
local checks = 0
local function check(ok, message) checks = checks + 1; assert(ok, message) end
local function forbidden() error("diagnostics invoked a native action or installed a driver") end
local env = setmetatable({}, { __index = _G }); env._G = env
local secret, inaccessible = {}, {}
local callbacks, messages = {}, {}
local targeting = false
env.issecretvalue = function(value) return value == secret end
env.canaccesstable = function(value) return value ~= inaccessible end
env.InCombatLockdown = function() return false end
env.GetBuildInfo = function() return "1.60.1", "70862", "Nov 6 2026", 16001 end
env.GetCursorInfo = function() return targeting and "spell" or nil end
env.SpellIsTargeting = function() return targeting end
env.SpellCanTargetItem = function() return targeting end
env.SpellCanTargetItemID = function() return false end
env.C_Spell = { TargetSpellIsEnchanting = function() return false end }
env.C_Container = { UseContainerItem = forbidden, GetContainerItemInfo = forbidden }
env.C_CVar = { GetCVar = function(key) check(key == "taintLog", "only reads logging mode"); return "0" end,
    SetCVar = forbidden }
env.ItemButtonUtil = { MarkItemSelectionFromBag = forbidden, ClearPendingItemSelectionSource = forbidden }
env.ContainerFrameItemButtonMixin = { OnClick = forbidden, SetBagID = forbidden, Initialize = forbidden }
env.CreateFrame = forbidden
env.C_Timer = { After = function(delay, callback)
    check(delay == 10, "one bounded ten-second capture")
    callbacks[#callbacks + 1] = callback
end }
env.SlashCmdList = {}
env.print = function(message) messages[#messages + 1] = message end
env.issecurevariable = function(object, key)
    if object == secret then error("secret object read") end
    if key == "bagID" then return false, "ExampleWriter" end
    return true
end
local button = { bagID = 0, GetName = function() return "ContainerFrameCombinedBagsItem1" end,
    GetBagID = function() return 0 end, GetID = function() return 5 end,
    GetAttribute = function(_, key) check(key == "bagid", "only reads bag attribute"); return 0 end,
    IsVisible = function() return true end, OnClick = forbidden, Initialize = forbidden,
    SetBagID = forbidden, UpdateTooltip = forbidden }
local container = { IsVisible = function() return true end, Items = { button, secret, inaccessible },
    Update = forbidden, UpdateItems = forbidden, UpdateItemSlots = forbidden, UpdateItemLayout = forbidden }
env.ContainerFrameCombinedBags = container
env.ContainerFrame1 = { IsVisible = function() return false end, Items = setmetatable({}, { __index = forbidden }) }
env.BankFrame = { IsShown = function() return false end, GetActiveBankType = forbidden,
    BankPanel = { IsShown = function() return false end, GetActiveBankType = forbidden } }
env.GetMouseFoci = function() return { button, secret } end
env.FluxPerfCaptureDB = { inputDebug = { retained = true }, editModeDebug = { retained = true }, other = { retained = true } }
local roots = env.FluxPerfCaptureDB
local ns = { Flux = {} }
assert(loadfile(arg[1] or "Other/FluxInputDebug.lua", "t", env))("_FluxUI", ns)
check(#callbacks == 0 and roots.bagInputDebug == nil, "bag capture stays inactive until requested")
local debug = ns.Flux.InputDebug
check(type(debug.CaptureBags) == "function", "bag targeting metadata entry point exists")
local snapshot = debug.CaptureBags()
check(snapshot.build == "70862" and snapshot.interface == 16001, "records actual native build")
check(snapshot.targeting.spell == false and snapshot.targeting.item == false, "preserves false targeting state")
check(snapshot.targeting.itemID == false and snapshot.targeting.enchanting == false, "separates item target predicates")
check(snapshot.taintLog == "0" and snapshot.complete, "records logging without changing it")
local record = snapshot.frames.ContainerFrameCombinedBags.buttons[1]
check(record.bag == 0 and record.slot == 5 and record.bagAttribute == 0, "preserves backpack zero and slot")
check(record.security.bagID.secure == false and record.security.bagID.owner == "ExampleWriter", "records writer ownership correctly")
check(record.security.OnClick.secure == true, "distinguishes secure fields from tainted fields")
check(snapshot.frames.ContainerFrameCombinedBags.buttons[2].restricted, "skips secret button fields")
check(snapshot.frames.ContainerFrameCombinedBags.buttons[3].restricted, "skips inaccessible button fields")
check(#snapshot.frames.ContainerFrame1.buttons == 0, "does not traverse hidden native lists")
check(snapshot.bank.shown == false and snapshot.bank.panel.shown == false, "bank visibility read without invoking active-type helper")
check(snapshot.foci[1].slot == 5 and snapshot.foci[2].restricted, "records hovered target and skips secret focus")
check(roots.bagInputDebug == nil, "direct metadata query has no saved-variable side effect")
env.SlashCmdList.FLUXINPUT(" bags ")
check(#callbacks == 1 and roots.bagInputDebug.latest.targeting.spell == false, "slash captures immediate pre-use state")
env.SlashCmdList.FLUXINPUT("bags")
env.SlashCmdList.FLUXINPUT("grid")
check(#callbacks == 1, "pending requests cannot accumulate callbacks")
targeting = true
callbacks[1]()
local first = roots.bagInputDebug.latest
check(first.before.targeting.spell == false and first.targeting.spell == true and first.targeting.item == true,
    "retains before/after transition to item-targeting cursor")
check(first.targeting.cursor == "spell" and first.before.targeting.cursor == nil, "cursor type recorded without payload")
check(roots.inputDebug.retained and roots.editModeDebug.retained and roots.other.retained, "preserves prior diagnostic roots")
env.SlashCmdList.FLUXINPUT("bags"); callbacks[2]()
local second = roots.bagInputDebug.latest
check(roots.bagInputDebug.previous == first, "retains previous diagnostic sample")
env.SlashCmdList.FLUXINPUT("bags"); callbacks[3]()
check(roots.bagInputDebug.previous == second and roots.bagInputDebug.previous.previous == nil,
    "history remains bounded at two capture runs")
env.SpellCanTargetItem = function() return secret end
env.SpellIsTargeting = function() error("restricted target predicate") end
button.GetBagID = function() return secret end
button.GetID = function() error("restricted slot getter") end
snapshot = debug.CaptureBags()
check(snapshot.targeting.item == "secret" and snapshot.targeting.spell == nil, "restricted queries cannot abort capture")
record = snapshot.frames.ContainerFrameCombinedBags.buttons[1]
check(record.bag == "secret" and record.slot == nil, "restricted bag getters omitted without conversion")
container.Items = inaccessible
check(#debug.CaptureBags().frames.ContainerFrameCombinedBags.buttons == 0, "inaccessible native list is not indexed")
container.Items = {}
for i = 1, 400 do container.Items[i] = button end
snapshot = debug.CaptureBags()
check(#snapshot.frames.ContainerFrameCombinedBags.buttons == 256, "native button sampling is bounded")
env.C_Timer, env.C_Container, env.C_Spell = nil, nil, nil
env.SpellCanTargetItem, env.SpellCanTargetItemID, env.SpellIsTargeting = nil, nil, nil
env.GetMouseFoci = nil
env.GetMouseFocus = function() return button end
env.canaccesstable, env.issecurevariable = nil, nil
env.SlashCmdList.FLUXINPUT("bags")
snapshot = roots.bagInputDebug.latest
check(snapshot.complete and snapshot.foci[1].name == button:GetName(), "timerless/legacy queries retain useful metadata")
check(next(snapshot.mixin) == nil and next(snapshot.containerAPI) == nil, "missing diagnostics/APIs remain unavailable")
check(#callbacks == 3 and #messages == 7, "no persistent driver or extra callback")
print("Bag item-targeting diagnostics: " .. checks .. " checks PASS; native taint reproduction pending")
