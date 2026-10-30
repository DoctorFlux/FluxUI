-- Execute the production durability anchor decision with top-left chrome fixtures.
local file = assert(io.open("StatusBars/FluxStatusBar.lua", "rb"))
local source = file:read("*a")
file:close()
local function section(first, last)
    local a = assert(source:find(first, 1, true))
    local b = assert(source:find(last, a, true))
    return source:sub(a, b - 1)
end
local code = section("local DURABILITY_TOPLEFT_PVP_GAP", "-- Create custom DurabilityFrame")
    .. section("local function FrameInTopLeft(", "EnsureDurabilityUsesStatusContainer = function()")

local function frame(top, left, bottom, right)
    return {
        top = top, left = left, bottom = bottom, right = right, shown = true,
        IsShown = function(self) return self.shown end,
        GetTop = function(self) return self.top end,
        GetLeft = function(self) return self.left end,
        GetBottom = function(self) return self.bottom end,
        GetRight = function(self) return self.right end,
        GetWidth = function(self) return self.width end,
        GetScale = function(self) return self.scale end,
        ClearAllPoints = function(self) self.anchor = nil end,
        SetPoint = function(self, ...) self.anchor = { ... } end,
    }
end
local ui = frame(1000, 0, 0, 1600)
ui.width = 1600
local menu = frame(1000, 2, 960, 330)
local status = frame(1000, 2, 930, 330)
local durability = frame(0, 0, 0, 0)
local pvp = frame(980, 10, 930, 120)
local seat = frame(0, 0, 0, 0)
seat.width, seat.scale = 128, 0.7
local refreshes = 0
local combat = false
local env = setmetatable({
    UIParent = ui,
    FluxMicroMenu = menu,
    FluxStatusBarContainer = status,
    FluxDurabilityFrame = durability,
    FluxVehicleSeatIndicator = seat,
    UIWidgetTopCenterContainerFrame = pvp,
    FluxVehicleSeats_UpdateAnchor = function() refreshes = refreshes + 1 end,
    InCombatLockdown = function() return combat end,
}, { __index = _G })
env._G = env
assert(load(code, "durability layout", "t", env))()

local function check(relative, x, y)
    env.UpdateFluxDurabilityFramePosition()
    local a = assert(durability.anchor)
    assert(a[1] == "TOPLEFT" and a[2] == relative and a[3] == (relative == ui and "TOPLEFT" or "BOTTOMLEFT"))
    assert(math.abs(a[4] - x) < 0.001 and a[5] == y)
end
local reserved = 128 * 0.7 + 4

-- Only menu position 1 occupies the top-left.
status.shown, pvp.shown = false, false
check(menu, reserved, -4)

-- Only status position 1 occupies the top-left.
menu.shown, status.shown = false, true
check(status, reserved, -4)

-- Both occupy it: choose whichever reaches lower.
menu.shown = true
check(status, reserved, -4)
status.bottom = 980
check(menu, reserved, -4)

-- Neither chrome frame occupies it; preserve PvP clearance if present.
menu.shown, status.shown, pvp.shown = false, false, true
check(pvp, reserved, -6)
pvp.shown = false
check(ui, reserved, 0)

-- Missing seat indicator still reserves its space during load-order transitions.
env.FluxVehicleSeatIndicator = nil
check(ui, reserved, 0)

-- Combat leaves the existing durability anchor intact.
combat = true
local before = durability.anchor
env.UpdateFluxDurabilityFramePosition()
assert(durability.anchor == before and refreshes == 8)
print("durability and vehicle layout passed")
