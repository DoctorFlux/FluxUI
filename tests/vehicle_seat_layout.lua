-- The production seat frame must move with the layout without changing native ownership.
local frames = {}
local methods = {}
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetScale(scale) self.scale = scale end
function methods:SetFrameStrata() end
function methods:SetFrameLevel() end
function methods:Hide() self.hidden = true end
function methods:CreateTexture()
    return { SetAllPoints = function() end }
end
function methods:ClearAllPoints() self.anchor = nil end
function methods:SetPoint(...) self.anchor = { ... } end
function methods:SetScript() end
function methods:RegisterEvent() end

CreateFrame = function(_, name)
    local frame = setmetatable({}, { __index = methods })
    if name then frames[name] = frame end
    return frame
end
UIParent = {}
FluxDurabilityFrame = {}
local combat = false
InCombatLockdown = function() return combat end

assert(loadfile("Other/FluxVehicleSeats.lua"))("_FluxUI", {})
local indicator = assert(frames.FluxVehicleSeatIndicator)
local function anchor(point, relativePoint, relativeFrame, x, y)
    local a = assert(indicator.anchor)
    assert(a[1] == point and a[2] == relativeFrame and a[3] == relativePoint
        and math.abs(a[4] - x) < 0.001 and a[5] == y)
end

assert(indicator.scale == 0.7 and indicator.width == 128 and indicator.height == 128)
anchor("TOPRIGHT", "TOPLEFT", FluxDurabilityFrame, -4 / 0.7, 0)

FluxVehicleSeats_UpdateAnchor()
anchor("TOPRIGHT", "TOPLEFT", FluxDurabilityFrame, -4 / 0.7, 0)

combat = true
FluxVehicleSeats_UpdateAnchor()
anchor("TOPRIGHT", "TOPLEFT", FluxDurabilityFrame, -4 / 0.7, 0)
assert(indicator._fluxNeedsAnchor)
combat = false
FluxVehicleSeats_UpdateAnchor()
anchor("TOPRIGHT", "TOPLEFT", FluxDurabilityFrame, -4 / 0.7, 0)
assert(not indicator._fluxNeedsAnchor)

FluxDurabilityFrame = nil
FluxVehicleSeats_UpdateAnchor()
anchor("TOPLEFT", "TOPLEFT", UIParent, 0, 0)
print("vehicle seat layout passed")
