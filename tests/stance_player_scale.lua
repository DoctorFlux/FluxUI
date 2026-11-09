-- Real stance anchor/layout entrypoints with independent parent scales.
local source = arg[1] or "Bars/Stance/Layout.lua"
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local locked, attached, deferred = false, true, {}
local root = { GetEffectiveScale = function() return 0.8 end }
local player = { scale = 0.5, outerBorderFrame = {} }
function player:GetEffectiveScale() return self.scale * root:GetEffectiveScale() end
local frame = { scale = 1, writes = 0, points = 0 }
function frame:GetParent() return root end
function frame:GetScale() return self.scale end
function frame:GetEffectiveScale() return self.scale * root:GetEffectiveScale() end
function frame:SetScale(s) check(not locked, "no protected scale writes in combat"); self.scale = s; self.writes = self.writes + 1 end
function frame:ClearAllPoints() check(not locked, "no protected anchor writes in combat") end
function frame:SetPoint(_, relative) self.relative = relative; self.points = self.points + 1 end
local stance = { GetFrame = function() return frame end,
    ShouldAnchorToPlayerBorder = function() return attached end,
    ApplyBorderChrome = function() end, STANCE_ANCHOR_GAP = -4,
    STANCE_WINDOW_GAP_X = -4, STANCE_WINDOW_GAP_Y = -4 }
local ns = { PlayerFrame = player, Flux = { Bars = { Stance = stance }, Combat = {
    InLockdown = function() return locked end,
    Defer = function(key, fn) deferred[key] = fn end } } }
local env = setmetatable({ UIParent = root }, { __index = _G })
assert(loadfile(source, "t", env))("_FluxUI", ns)
stance.Anchor()
check(frame.scale == 0.5, "attached stance follows reduced player scale")
check(frame.relative == player.outerBorderFrame, "player border anchor retained")
local writes = frame.writes
stance.Anchor()
check(frame.writes == writes, "unchanged scale avoids a write")
player.scale = 1.35; stance.Anchor()
check(frame.scale == 1.35, "attached stance follows increased player scale")
attached = false; stance.Anchor()
check(frame.scale == 1 and frame.relative == root, "detaching restores original scale")
attached = true; ns.PlayerFrame = nil; stance.Anchor()
check(frame.scale == 1, "missing player uses normal fallback scale")
ns.PlayerFrame = player; locked = true; local points = frame.points
stance.Anchor()
check(frame.scale == 1 and frame.points == points and deferred["bars.stance.anchor"], "combat queues anchor without writes")
locked = false; deferred["bars.stance.anchor"]()
check(frame.scale == 1.35, "deferred anchor picks up current player scale")
-- Layout metrics must see the detached scale before fitting the pet height.
attached = false
stance.Catalog = function() check(frame.scale == 1, "layout resets scale before measuring"); error("layout entry checked", 0) end
local ok, err = pcall(stance.ApplyLayout)
check(not ok and tostring(err):find("layout entry checked", 1, true), "layout reached measurement after scale sync")
print("stance player scale: " .. checks .. " checks")
