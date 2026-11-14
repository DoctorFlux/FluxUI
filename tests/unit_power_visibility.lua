-- Focused desktop model for zero-capacity resource layout on Flux unit and raid frames.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a")
    file:close()
    return source
end

local function slice(source, first, last)
    local a = assert(source:find(first, 1, true), first)
    local b = assert(source:find(last, a + #first, true), last)
    return source:sub(a, b - 1)
end

local shared = read(os.getenv("FLUX_UNIT_POWER_SOURCE") or "UnitFrames/FluxUnitFrames_Shared.lua")
local maximum, current, combat, modern = 0, 0, false, false
local secret = {}
local UF = {}
local API = {
    SafeUnitPower = function() return current end,
    SafeUnitPowerMax = function() return maximum end,
    IsSecretValue = function(value) return value == secret end,
    GetPowerPercent100 = function() return 0 end,
}
local ns = { UnitFrames = UF, API = API }
local env = setmetatable({ ns = ns, UF = UF, API = API,
    UnitPowerType = function() return 0, "MANA" end,
    StatusBarSetMinMaxAndValueImmediate = function() end,
    IsFluxUnitFrame = function() return true end,
    InCombatLockdown = function() return combat end,
    UnitExists = function() return true end,
    GetChromeSeparatorRGB = function() return 1, 1, 1 end,
    FluxUnitFrames_GetHealthPartitionPct = function() return 0.6 end,
    TargetUnitUsesSideBySideTotTextLayout = function() return true end,
}, { __index = _G })
UF.UnitIsAFKDisplay = function() return false end
local healthRefreshes = 0
UF.UpdateHealth = function() healthRefreshes = healthRefreshes + 1 end
UF.UsesHudUnitBars = function() return modern end
UF.PowerValueForDisplay = function(_, value) return value end
UF.ApplyResourceBarStyle = function() end
UF.RefreshResourceConnection = function() end
UF.UpdateResourceSpark = function() end
UF.UpdateFullResourcePulse = function() end
UF.FrameUsesPortraitLayout = function() return false end
UF.UpdateAtlasBorder = function() end
UF.UpdateOuterBorder = function() end
UF.LayoutThreatBar = function() end
assert(load(slice(shared, "local function ValueIsSecret(value)", "local function PlayerDeadOrGhost(unit)"),
    "@shared:public-geometry", "t", env))()
assert(load(slice(shared, "function UF.UpdatePower(self, unit)", "function UF.CreatePowerBar(frame)"), "@shared:power", "t", env))()
assert(load(slice(shared, "function UF.UpdateFramePartitionSeparators(self", "function UF.GetFluxStylePartitionHealthHeight"), "@shared:separators", "t", env))()
assert(load(slice(shared, "function UF.UpdateFramePartition(self)", "-- Event Handling"), "@shared:partition", "t", env))()

local function region(protected)
    local r = { shown = true, protected = protected }
    local function structure(self)
        assert(not (combat and self.protected), "ordinary combat mutation of protected StatusBar/Frame")
    end
    function r:Show() structure(self); self.shown = true end
    function r:Hide() structure(self); self.shown = false end
    function r:SetHeight(height) structure(self); self.height = height end
    function r:ClearAllPoints() structure(self) end
    function r:SetPoint() structure(self) end
    function r:SetWidth() structure(self) end
    -- Model a client repaint that replaces the separator's alpha aspect.
    function r:SetVertexColor(_, _, _, alpha) self.alpha = alpha end
    function r:SetAlpha(value) self.alpha = value end
    function r:GetNumPoints() return 2 end
    return r
end

local frame = {
    unit = "focus", Health = region(true), Power = region(true),
    HealthPowerSeparator = region(), PowerAdditionalSeparator = region(),
}
function frame:GetHeight() return 100 end
function frame:GetWidth() return 325 end
function frame:IsEventRegistered() return false end
function frame:RegisterEvent() end
function frame:UpdatePartition() UF.UpdateFramePartition(self) end

UF.UpdatePower(frame, "focus")
assert(frame._fluxHasMainPower == false and not frame.Power.shown)
assert(frame.Health.height == 92 and not frame.HealthPowerSeparator.shown)

current, maximum = 0, 100
UF.UpdatePower(frame, "focus")
assert(frame._fluxHasMainPower == true and frame.Power.shown)
assert(frame.Health.height < 92 and frame.HealthPowerSeparator.shown)

local appliedHeight = frame.Health.height
combat, maximum = true, 0
UF.UpdatePower(frame, "focus")
assert(frame.Power.shown and frame.Health.height == appliedHeight and frame.needsPartitionRelayout,
    "combat retains prepared geometry and queues structural changes; values keep updating")
combat, maximum = false, secret
UF.UpdatePower(frame, "focus")
assert(frame._fluxHasMainPower == nil and frame.Power.shown)
modern, maximum = true, secret
frame.Health._fluxTextAnchor = region(true)
UF.UpdatePower(frame, "focus")
frame:UpdatePartition()
assert(frame.Power.alpha == secret and frame.HealthPowerSeparator.alpha == secret)
assert(frame.Health.height == 92 and frame.Health._fluxTextAnchor.height < 92)
maximum = 100
UF.UpdatePower(frame, "focus")
assert(frame.Power.alpha == 100 and frame.Health.height == 92)
assert(frame.Health._fluxTextAnchor.height < 92 and frame.HealthPowerSeparator.shown)
maximum = secret
UF.UpdatePower(frame, "focus")
assert(frame._fluxHasMainPower == nil and frame.Health._fluxTextAnchor.height < 92)
assert(frame.HealthPowerSeparator.shown and frame.HealthPowerSeparator.alpha == secret)
frame.unit = "target"
maximum = 0
UF.UpdatePower(frame, frame.unit)
assert(healthRefreshes == 1 and frame.Health._fluxTextAnchor.height == 92)
maximum = 100
UF.UpdatePower(frame, frame.unit)
assert(healthRefreshes == 2 and frame.Health._fluxTextAnchor.height < 92)

maximum = 0
UF.UpdatePower(frame, "focus")
assert(not frame.Power.shown and not frame.HealthPowerSeparator.shown)
assert(frame.Health._fluxTextAnchor.height == 92)
frame.unit = "targettarget"
maximum = 100
UF.UpdatePower(frame, frame.unit)
assert(frame.HealthPowerSeparator.shown and frame.HealthPowerSeparator.alpha == 100)
maximum = 0
UF.UpdatePower(frame, frame.unit)
assert(not frame.HealthPowerSeparator.shown)
maximum = secret
UF.UpdatePower(frame, frame.unit)
frame:UpdatePartition()
assert(frame.HealthPowerSeparator.shown and frame.HealthPowerSeparator.alpha == secret)

-- Exercise the actual HP text layout with a nested target and a centered ToT.
local healthUF = {
    UpdateHealPrediction = function() end,
    ShouldShowAFKHealthOverlay = function() return false end,
    GetHealthDeadGhostStatusText = function() return nil end,
    UpdateHealthColor = function() end,
}
local healthEnv = setmetatable({
    UF = healthUF,
    API = { SafeUnitHealth = function() return 50 end,
        SafeUnitHealthMax = function() return 100 end,
        GetHealthPercent100 = function() return 50 end },
    ns = {},
    StatusBarSetMinMaxImmediate = function() end,
    StatusBarSetValueImmediate = function() end,
    FormatValue = tostring,
    IsPercentScaledHealthMax = function() return false end,
    SetCurMaxLabel = function() end,
    SetPercentLabel = function() end,
    TargetUnitUsesSideBySideTotTextLayout = function() return true end,
    PlaceBarText = function(fs, _, point, relative)
        fs.point, fs.relative = point, relative
    end,
}, { __index = _G })
assert(load(slice(shared, "function UF.UpdateHealth(self, unit)", "function UF.CreateHealthBar(frame)"),
    "@shared:health", "t", healthEnv))()
local hp = region()
hp._fluxTextAnchor = region()
hp.Value, hp.Percent = region(), region()
for _, label in ipairs({ hp.Value, hp.Percent }) do
    function label:IsShown() return self.shown end
    function label:SetText() end
    function label:SetPoint(point, relative) self.point, self.relative = point, relative end
end
local textFrame = { unit = "target", Health = hp, _fluxHasMainPower = false }
healthUF.UpdateHealth(textFrame, "target")
assert(hp.Value.point == "RIGHT" and hp.Percent.point == "LEFT")
assert(hp.Value.relative == hp._fluxTextAnchor and hp.Percent.relative == hp._fluxTextAnchor)
textFrame._fluxHasMainPower = true
healthUF.UpdateHealth(textFrame, "target")
assert(hp.Value.point == "TOPRIGHT" and hp.Percent.point == "TOPLEFT")
textFrame.unit = "targettarget"
textFrame._fluxHasMainPower = false
healthUF.UpdateHealth(textFrame, "targettarget")
assert(hp.Percent.point == "CENTER" and hp.Percent.relative == hp._fluxTextAnchor)

-- Compact focus uses a decorative divider independent of the Power child.
-- Drive actual UpdatePower through no-resource/empty-resource/combat changes.
local focus = {unit = "focus", _fluxCompactFocus = true,
    Health = region(true), Power = region(true), _fluxPartyDivider = region()}
for key, value in pairs(frame) do if type(value) == "function" then focus[key] = value end end
focus.Health._fluxTextAnchor = region(true)
for _, hud in ipairs({false, true}) do
    modern, combat, current, maximum = hud, false, 0, 100
    focus._fluxHasMainPower = false
    UF.UpdatePower(focus)
    assert(focus._fluxPartyDivider.alpha == (hud and 100 or 1), "zero current resource retains the focus divider")
    maximum = 0
    UF.UpdatePower(focus)
    assert(focus._fluxPartyDivider.alpha == 0 and not focus.Power.shown and focus.Health.height == 92,
        "focus without resource has uninterrupted full-height HP")
    maximum = 100
    UF.UpdatePower(focus)
    local prepared = focus.Health.height
    combat, maximum = true, 0
    UF.UpdatePower(focus)
    assert(focus._fluxPartyDivider.alpha == 0 and focus.Health.height == prepared and focus.needsPartitionRelayout,
        "combat hides the focus divider immediately while protected geometry remains deferred")
    combat = false
    focus:UpdatePartition()
    maximum = secret
    UF.UpdatePower(focus)
    assert(rawequal(focus._fluxPartyDivider.alpha, hud and secret or 1),
        "opaque HUD resource opacity passes directly to the focus divider")
end

local raidSource = slice(read("RaidFrame/FluxRaidUnit.lua"), "local addonName, ns = ...", "function FluxRaid_UpdateHealPrediction")
local raidMaximum, raidCurrent = 0, 0
local raidVisuals = { POWER_BAR_HEIGHT = 8, ApplyCellChrome = function(f, opts)
    f.powerBarUsedHeight = opts.showPower and 8 or 0
end }
local raidEnv = setmetatable({
    FluxRaidCompat = { IsSecret = function(value) return value == secret end,
        GetPowerPercent = function() return raidCurrent end },
    FluxRaidState = {}, FluxRaidVisuals = raidVisuals,
    UnitPowerType = function() return 0, "MANA" end,
    UnitPowerMax = function() return raidMaximum end,
    UnitIsConnected = function() return true end,
    InCombatLockdown = function() return combat end,
}, { __index = _G })
assert(load(raidSource, "@raid:power", "t", raidEnv))("_FluxUI", { UnitFrames = UF })
local raid = { unit = "raid1", powerBar = region(), healthBar = region() }
function raid:RegisterEvent(event) self.registered = event end
function raid.powerBar:SetShown(shown) self.shown = shown end
function raid.powerBar:IsShown() return self.shown end
function raid.powerBar:SetMinMaxValues() end
function raid.powerBar:SetStatusBarColor() end
function raid.powerBar:SetValue() end
raidEnv.FluxRaid_UpdatePower(raid)
assert(not raid.powerBar.shown and raid.powerBarUsedHeight == 0)
raidMaximum = 100
raidEnv.FluxRaid_UpdatePower(raid)
assert(raid.powerBar.shown and raid.powerBarUsedHeight == 8)
raidMaximum = secret
raidEnv.FluxRaid_UpdatePower(raid)
assert(raid.powerBar.shown and raid.powerBar.alpha ~= secret, "opaque maximum must never become raid bar opacity")
combat, raidMaximum = true, 0
raidEnv.FluxRaid_UpdatePower(raid)
assert(not raid.powerBar.shown and raid.powerBarUsedHeight == 8)
assert(raid._fluxPowerLayoutPending and raid.registered == "PLAYER_REGEN_ENABLED")
combat = false
raidEnv.FluxRaid_UpdatePower(raid)
assert(raid.powerBarUsedHeight == 0 and not raid._fluxPowerLayoutPending)
raid.optionTable = { displayPowerBar = false }
raidEnv.FluxRaid_UpdatePower(raid)
assert(not raid.powerBar.shown and raid.powerBarUsedHeight == 0)
print("unit power visibility: main split, combat, secret and raid checks passed")
