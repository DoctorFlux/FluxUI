-- Exercise the production options bridge with lightweight frame doubles.
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end

local db = { frameScalePlayerTarget = 1.35, frameScaleFocus = 0.8 }
FluxOptions = { GetUnitFrameDB = function() return db end }
UIParent = { GetEffectiveScale = function() return 1 end }
InCombatLockdown = function() return false end
FLUX_API = { hasFocusUnit = true }
local ns = { UnitFrames = {} }
assert(loadfile("UnitFrames/FluxUnitFrames_OptionsBridge.lua"))("_FluxUI", ns)
local reanchor = FluxUnitFrames_ReanchorUnitFrameScreenPosition
local stripFloor = FluxUnitFrames_GetPlayerScreenBottomOffset

check(FluxUnitFrames_GetWholeFrameScale("player") == 1.35, "player scale")
check(FluxUnitFrames_GetWholeFrameScale("targettarget") == 1.35, "target dependent scale")
check(FluxUnitFrames_GetWholeFrameScale("focustarget") == 0.8, "focus dependent scale")
db.frameScaleFocus = 5
check(FluxUnitFrames_GetWholeFrameScale("focus") == 2, "scale upper bound")
db.frameScaleFocus = 0.1
check(FluxUnitFrames_GetWholeFrameScale("focus") == 0.5, "scale lower bound")
db.frameScaleFocus = 0.8

local function frame(parent)
    local f = { parent = parent, scale = 1, SeparatorContainer = {}, atlasBorderFrame = {} }
    function f:SetScale(value) self.scale = value end
    function f:GetEffectiveScale() return self.scale * (self.parent and self.parent.GetEffectiveScale and self.parent:GetEffectiveScale() or 1) end
    function f:GetParent() return self.parent end
    function f:SetHeight(value) self.height = value end
    function f:SetWidth(value) self.width = value end
    function f:UpdatePartition() end
    function f:UpdateAtlasBorder() end
    function f:UpdateOuterBorder() end
    function f.SeparatorContainer:SetScale(value) self.scale = value end
    function f.atlasBorderFrame:SetScale(value) self.scale = value end
    return f
end

ns.PlayerFrame = frame(UIParent)
ns.TargetFrame = frame(UIParent)
ns.FocusFrame = frame(UIParent)
ns.FocusTargetFrame = frame(UIParent)
ns.TargetOfTargetFrame = frame(ns.TargetFrame)
ns.TargetFrame.placeholderBorder = frame(UIParent)
ns.PlayerFrame.Portrait = {}
ns.FocusFrame.Portrait = {}
local portraitRefreshes = 0
ns.UnitFrames.RefreshPortraitAfterDisplayMetrics = function() portraitRefreshes = portraitRefreshes + 1 end
local anchors = 0
ns.TargetOfTargetFrame._fluxRefreshTotAnchor = function() anchors = anchors + 1 end
FluxUnitFrames_GetConfiguredFrameSize = function() return 200, 60 end
FluxUnitFrames_ReanchorUnitFrameScreenPosition = function() end
FluxUnitFrames_MatchFocusTargetToFocus = function() end
FluxUnitFrames_ApplyFrameSizesFromDB()
check(ns.PlayerFrame.scale == 1.35 and ns.TargetFrame.scale == 1.35, "player and target roots")
check(ns.FocusFrame.scale == 0.8 and ns.FocusTargetFrame.scale == 0.8, "focus and focus target roots")
check(ns.TargetOfTargetFrame.scale == 1 and ns.TargetOfTargetFrame:GetEffectiveScale() == 1.35, "side-by-side ToT inherits once")
check(ns.TargetOfTargetFrame.SeparatorContainer.scale == 1.35, "detached ToT separator follows effective scale")
check(ns.TargetFrame.atlasBorderFrame.scale == 1.35, "detached atlas border follows target scale")
check(ns.TargetFrame.placeholderBorder.scale == 1.35, "empty target outline follows scale")
check(anchors == 1, "ToT anchor refreshes")
check(portraitRefreshes == 2, "player and focus 3D portraits reframe after scaling")

ns.TargetOfTargetFrame.parent = UIParent
db.frameScalePlayerTarget = 0.7
FluxUnitFrames_ApplyFrameSizesFromDB()
check(ns.TargetOfTargetFrame.scale == 0.7, "stacked ToT receives target scale")
check(ns.TargetOfTargetFrame.SeparatorContainer.scale == 0.7, "stacked separator follows target scale")
check(ns.TargetOfTargetFrame.atlasBorderFrame.scale == 0.7, "stacked atlas border follows target scale")
check(portraitRefreshes == 3, "unchanged focus portrait avoids another reframe")

local anchor = { scale = 1.35, unit = "player", portraitPosition = "LEFT" }
function anchor:GetWidth() return 200 end
function anchor:GetHeight() return 60 end
function anchor:ClearAllPoints() end
function anchor:SetPoint(point, _, _, x, y) self.point, self.x, self.y = point, x, y end
FluxUnitFrames_GetScreenAnchorCenterOffsetX = function() return 31 end
FluxUnitFrames_GetPlayerScreenBottomOffset = function() return 96 end
db.frameScalePlayerTarget = 1.35
reanchor(anchor, "player")
check(anchor.x == 31, "portrait center offset uses one frame scale")
check(math.abs(anchor.y * 1.35 - 100) < 0.001, "large player bottom clears strip")
db.frameScalePlayerTarget = 0.5
reanchor(anchor, "player")
check(math.abs(anchor.y * 0.5 - 100) < 0.001, "small player bottom clears strip")
db.frameScalePlayerTarget = 1
reanchor(anchor, "player")
check(anchor.y == 96, "default player anchor stays unchanged")

UIParent.GetBottom = function() return 0 end
UIParent.GetEffectiveScale = function() return 0.75 end
FluxActionStrip = { GetTop = function() return 100 end, GetEffectiveScale = function() return 0.9 end,
    IsShown = function() return true end }
check(stripFloor() == 120, "strip top converts to UIParent anchor units")
FluxActionStrip = nil
UIParent.GetEffectiveScale = function() return 1 end

ns.UnitFrames.RegisterInitializer = function() end
assert(loadfile("UnitFrames/FluxUnitFrames_Focus.lua"))("_FluxUI", ns)
local focus = { BuffContainer = { GetLeft = function() return 250 / 1.5 end,
    GetTop = function() return 380 / 1.5 end, GetEffectiveScale = function() return 1.5 end } }
function focus:ClearAllPoints() end
function focus:SetPoint(_, _, _, x, y) self.x, self.y = x, y end
function focus:GetEffectiveScale() return 1.5 end
function focus:UpdatePartition() end
function focus:UpdateOuterBorder() end
ns.FocusFrame = focus
ChatFrame1 = { GetRight = function() return 300 end, GetTop = function() return 400 end,
    GetEffectiveScale = function() return 1 end }
FluxUIPositionFocusFrameDefault()
check(math.abs(focus.x * 1.5 - 50) < 0.001 and math.abs(focus.y * 1.5 - 20) < 0.001,
    "focus aura alignment converts chat and portrait scales")
print("unit frame whole scale: " .. checks .. " checks")
