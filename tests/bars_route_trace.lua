-- Native route diagnostics must expose disagreements, never execute an action.
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local lines, private = {}, {}
local e = setmetatable({ SlashCmdList = {} }, { __index = _G }); e._G = e
local flux = { Module = { Register = function() end }, Combat = {} }
e.InCombatLockdown = function() return e.combat end; flux.Combat.InLockdown = e.InCombatLockdown
e.issecretvalue = function(v) return v == private end
e.print = function(s) lines[#lines + 1] = s end; flux.Print = e.print
for _, name in ipairs({ "CreateFrame", "SetOverrideBindingClick", "PlaceAction", "PickupAction", "RunMacroText", "CastSpellByName" }) do
    e[name] = function() error("trace attempted " .. name) end
end
assert(loadfile("Bars/Init.lua", "t", e))("_FluxUI", { Flux = flux })
assert(loadfile("Bars/SlotMath.lua", "t", e))("_FluxUI", { Flux = flux })
local bars = flux.Bars
bars.State = { GetCurrentPage = function() return 1 end }
local host = { attrs = { action = 6, ["flux-has-sec"] = 1, ["flux-has-tert"] = 1 } }
function host:GetAttribute(k) return self.attrs[k] end
function host:CalculateAction() return 6 end
function host:SetAttribute() error("trace changed attributes") end
local proxy = { CalculateAction = function() return 6 end }
bars.hosts[6] = { main = { widget = host, slot = 6, bindingCommand = "ACTIONBUTTON6" } }
e.FluxActionStripKey6 = proxy
e.GetBindingKey = function() return "HALF" end
e.GetBindingAction = function(key, overrides)
    check(overrides == true, "reads actual override route")
    return key == "SHIFT-HALF" and "CLICK alternate_HC:LeftButton" or "CLICK strip:LeftButton"
end
e.SecureButton_GetModifierPrefix = function() return "shift-" end
local delegate = { GetName = function() return "wrongMain6" end,
    GetAttribute = function() return "/stopcasting\n/cast Mana Shield" end }
e.SecureButton_GetModifiedAttribute = function(frame, name, button, prefix, suffix)
    check(button == "LeftButton" and (suffix == nil or suffix == "1"), "uses actual native LeftButton resolution")
    -- Deliberate native-helper disagreement with expected SlotMath. A useful
    -- trace exposes this result rather than substituting its own model.
    if name == "action" then return 6 end
    if name == "type" then return e.private and private or "click" end
    if name == "clickbutton" then return e.private and private or delegate end
    if name == "macrotext" then return e.private and private or "/cast Main" end
end
e.SlashCmdList.FLUXBARS("trace 6")
local output = table.concat(lines, "\n")
check(output:find("Action route trace r2: column=6", 1, true), "identifies loaded diagnostic revision")
check(output:find("shift- expected=66 binding=CLICK alternate_HC:LeftButton", 1, true), "exposes independent expected slot and alternate override owner")
check(output:find("key type=click action=6 delegate=wrongMain6", 1, true), "preserves observed wrong native selector")
check(output:find("/stopcasting | /cast Mana Shield", 1, true), "shows selected delegate body")
check(#lines == 26, "bounded eight-mask trace")
lines = {}; e.private = true
check(bars.TraceColumn(6), "private selectors are handled")
output = table.concat(lines, "\n")
check(output:find("type=<private>", 1, true) and not output:find("wrongMain6", 1, true), "private delegate is never indexed")
lines = {}; e.combat = true
check(bars.TraceColumn(6) == false and #lines == 1, "combat guard has no diagnostic writes")
lines = {}; e.combat = false
check(bars.TraceColumn(99) == false and #lines == 1, "invalid column is bounded")
local timers = {}; e.C_Timer = { After = function(delay, fn)
    check(delay == 12, "explicit input observation has bounded lifetime"); timers[#timers + 1] = fn
end }
e.private = false; lines = {}
check(bars.TraceNextKey(6) and type(bars.TraceKeyClick) == "function", "explicit operator request arms one observation")
local callback = bars.TraceKeyClick
callback(5, host, "LeftButton", true)
check(bars.TraceKeyClick == callback, "another column cannot consume observation")
callback(6, host, "LeftButton", true)
check(bars.TraceKeyClick == nil, "first observed input retires callback before logging")
check(table.concat(lines, "\n"):find("down=true held=shift-", 1, true), "records actual event phase and hardware prefix")
local count = #lines; timers[1](); check(#lines == count, "retired observation timeout does no work")
lines = {}; check(bars.TraceNextKey(6), "rearm independent observation")
timers[2](); check(bars.TraceKeyClick == nil and #lines == 2, "missing input expires and reports no observation")
print(("Bar route trace: %d checks PASS; read-only; native helper result is never replaced by model"):format(checks))
