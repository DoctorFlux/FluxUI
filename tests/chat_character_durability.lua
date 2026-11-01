-- Exercise the loaded character-button durability painter with readable gear,
-- fully repaired gear, and no readable durability data.
local file = assert(io.open("Other/FluxChatColumnMicros.lua", "rb"))
local source = file:read("*a")
file:close()
local first = assert(source:find("    local worldDurabilityPending = false", 1, true))
local last = assert(source:find("    if IsCamelotClient() and not classicFamily then", first, true))
local painter = source:sub(first, last - 1) .. "\nreturn UpdateDurability, events"

local values = {}
local label = {
    Hide = function(self) self.shown = false end,
    Show = function(self) self.shown = true end,
    SetText = function(self, value) self.text = value end,
    SetTextColor = function(self, ...) self.color = { ... } end,
}
local button = { icon = { SetVertexColor = function() end } }
local timers = {}
local env = setmetatable({
    btn = button,
    pct = label,
    GetInventoryItemDurability = function(slot)
        local row = values[slot]
        if row then return row[1], row[2] end
    end,
    issecretvalue = function(value) return value == "secret" end,
    DurabilityTextColor = function(value) return value / 100, 0, 0 end,
    C_Timer = { After = function(delay, callback)
        timers[#timers + 1] = { delay = delay, callback = callback }
    end },
    CreateFrame = function()
        return {
            RegisterEvent = function(self, event) self[event] = true end,
            SetScript = function(self, _, callback) self.script = callback end,
        }
    end,
}, { __index = _G })
local update, events = assert(load(painter, "character durability painter", "t", env))()
local function emit(event, unit)
    assert(events[event])
    events.script(events, event, unit)
end
local function runTimer(delay)
    local timer = table.remove(timers, 1)
    assert(timer and timer.delay == delay)
    timer.callback()
end

values = { [1] = { 100, 100 }, [16] = { 50, 50 } }
update()
assert(button._fluxDurabilityPct == 100 and label.shown and label.text == "100%")

values[16] = { 3, 4 }
update()
assert(button._fluxDurabilityPct == 75 and label.shown and label.text == "75%")

values[16] = { 0, 4 }
update()
assert(button._fluxDurabilityPct == 0 and label.shown and label.text == "0%")

values = { [1] = { "secret", 100 } }
update()
assert(not label.shown)

values = {}
update()
assert(not label.shown)

-- World entry can briefly return no gear. Keep the last readable text until
-- a player inventory event or the bounded world retry finds the gear again.
values = { [1] = { 50, 100 } }
emit("PLAYER_EQUIPMENT_CHANGED")
assert(label.shown and label.text == "50%")
values = {}
emit("PLAYER_ENTERING_WORLD")
assert(label.shown and label.text == "50%")
values = { [1] = { 100, 100 } }
runTimer(0.5)
assert(label.shown and label.text == "100%" and #timers == 0)

values = {}
emit("PLAYER_ENTERING_WORLD")
runTimer(0.5)
assert(label.shown and label.text == "100%")
values = { [1] = { 3, 4 } }
emit("UNIT_INVENTORY_CHANGED", "target")
assert(label.text == "100%")
emit("UNIT_INVENTORY_CHANGED", "player")
assert(label.shown and label.text == "75%")
runTimer(1.5)
assert(label.shown and label.text == "75%")

values = {}
emit("PLAYER_ENTERING_WORLD")
runTimer(0.5)
runTimer(1.5)
assert(not label.shown)

values = { [1] = { 100, 100 } }
update()
values = {}
emit("PLAYER_ENTERING_WORLD")
emit("PLAYER_ENTERING_WORLD")
runTimer(0.5) -- Older world entry must not schedule another retry.
values = { [1] = { 25, 100 } }
runTimer(0.5)
assert(label.shown and label.text == "25%" and #timers == 0)
print("chat character durability passed")
