-- Replay production heal/absorb painting and portrait geometry against retained
-- earlier bodies. Models native widgets, not WoW's secure/taint/rendering VM.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local function slice(s, first, last)
    local a = assert(s:find(first, 1, true), first)
    return s:sub(a, assert(s:find(last, a + #first, true), last) - 1)
end
local function replace(s, old, new)
    local a = assert(s:find(old, 1, true), old)
    return s:sub(1, a - 1) .. new .. s:sub(a + #old)
end
local source = read("UnitFrames/FluxUnitFrames_Shared.lua")
local prediction = slice(source, "local MAX_INCOMING_HEAL_OVERFLOW", "-- AFK: safe boolean")
local geometry = slice(source, "function UF.SyncPortraitModelGeometry(self)", "--- Full portrait refresh after resolution")
local overlayStart, overlayEnd = "local function AnchorOverlayToStatusBarFill(", "local function FrameHasPositiveTotalAbsorbs("
local positionStart, positionEnd = "local function UpdateFillPosition(", "\n\n\n\n--- Hide heal and absorb overlays"
local oldPrediction = replace(prediction, slice(prediction, overlayStart, overlayEnd), read("tests/fixtures/unit_overlay_geometry_before.txt"))
oldPrediction = replace(oldPrediction, slice(oldPrediction, positionStart, positionEnd), read("tests/fixtures/unit_prediction_geometry_before.txt"))
local oldGeometry = read("tests/fixtures/unit_portrait_geometry_before.txt")
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function native(v) return type(v) == "table" and rawget(v, "secretValue") or v end
local secretMeta = {
    __lt = function() error("secret comparison") end, __le = function() error("secret comparison") end,
    __eq = function() error("secret equality") end,
}
local function secret(value) return setmetatable({ secretValue = value }, secretMeta) end
secretMeta.__div = function(a, b) return secret(native(a) / native(b)) end
secretMeta.__add = function(a, b) return secret(native(a) + native(b)) end
secretMeta.__mul = function(a, b) return secret(native(a) * native(b)) end
local function fixture(branch, code, portraitCode)
    local s = { ops = { anchor = 0, uv = 0, size = 0, values = 0 }, regions = {}, heal = 0, mine = 0,
        absorb = 0, healAbsorb = 0, hp = 70, max = 100, width = 200, height = 24, showHeal = true, showAbsorb = true }
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.API = { isMidnight = branch == "live" or branch == "forever" }
    env.ValueIsSecret = function(v) return type(v) == "table" and rawget(v, "secretValue") ~= nil end
    env.API.IsSecretValue = env.ValueIsSecret
    env.API.SafeGetNumber = function(v) check(not env.ValueIsSecret(v), "legacy receives readable API values"); return v or 0 end
    env.FluxUnitFrames_ShouldShowHealPrediction = function() return s.showHeal end
    env.FluxUnitFrames_ShouldShowAbsorbs = function() return s.showAbsorb end
    env.UnitIsDeadOrGhost = function() return s.dead end
    env.UnitGetTotalAbsorbs = function() return s.absorb end
    env.API.SafeUnitGetIncomingHeals = function(_, who) return who and s.mine or s.heal end
    env.API.SafeUnitGetTotalAbsorbs = function() return s.absorb end
    env.API.SafeUnitGetTotalHealAbsorbs = function() return s.healAbsorb end
    env.ABSORB_OVERLAY_TILE, env.SHIELD_OVERLAY_TILE = 32, 32
    env.UF = {}
    env.C_Timer = setmetatable({}, { __index = function() error("geometry must not schedule timers") end })
    env.CreateFrame = function() error("paint must reuse existing widgets") end
    env.PlayerFrame = setmetatable({}, { __newindex = function() error("native frame write") end })
    local calc = {}
    function calc:GetIncomingHeals() return s.heal, s.mine, s.other or (native(s.heal) - native(s.mine)), false end
    function calc:GetHealAbsorbs() return s.healAbsorb, false end
    function calc:SetDamageAbsorbClampMode(mode) self.mode = mode end
    function calc:GetDamageAbsorbs() return s.absorb end
    env.API.CreateUnitHealPredictionCalculator = function() return calc end
    env.API.UnitGetDetailedHealPrediction = function() s.calcCalls = (s.calcCalls or 0) + 1 end
    local methods = {}
    local function region(name, parent)
        local r = setmetatable({ name = name, parent = parent, shown = true, points = {}, width = 200, height = 24, value = 0, max = 100 }, { __index = methods })
        s.regions[#s.regions + 1] = r
        return r
    end
    function methods:IsShown() return self.shown end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false end
    function methods:SetShown(v) self.shown = v and true or false end
    function methods:GetParent() return self.parent end
    function methods:ClearAllPoints() self.points = {}; s.ops.anchor = s.ops.anchor + 1 end
    function methods:SetPoint(p, relative, rp, x, y)
        if self.failAnchor then error("transient anchor failure") end
        self.points[p] = { relative.name, rp, native(x), native(y) }; s.ops.anchor = s.ops.anchor + 1
    end
    function methods:SetHeight(h) self.height = native(h); s.ops.size = s.ops.size + 1 end
    function methods:SetWidth(w) self.width = native(w); s.ops.size = s.ops.size + 1 end
    function methods:SetSize(w, h)
        if self.failSize then error("transient portrait resize") end
        self.width, self.height = native(w), native(h); s.ops.size = s.ops.size + 1
        self.sizeWrites = (self.sizeWrites or 0) + 1
    end
    function methods:GetWidth()
        if self == s.frame.Health then return s.width end
        local w = self.width
        if self.fillOwner then
            local owner = self.fillOwner; w = owner.width * math.max(0, math.min(1, owner.value / owner.max))
        elseif self.overlayOwner then w = self.overlayOwner:GetStatusBarTexture():GetWidth() end
        return self.secretWidth and secret(w) or w
    end
    function methods:GetHeight()
        if self == s.frame.Health then return s.height end
        local height = self.overlayOwner and self.overlayOwner.height or self.height
        return self.secretHeight and secret(height) or height
    end
    function methods:GetMinMaxValues() return 0, self == s.frame.Health and s.max or self.max end
    function methods:GetValue() return self == s.frame.Health and s.hp or self.value end
    function methods:SetMinMaxValues(_, value) self.max = native(value) end
    function methods:SetValue(value) self.value = native(value); s.ops.values = s.ops.values + 1 end
    function methods:GetStatusBarTexture() return self.fill end
    function methods:SetTexCoord(a, b, c, d)
        if self.failUV then error("transient texcoord failure") end
        self.uv = { native(a), native(b), native(c), native(d) }; s.ops.uv = s.ops.uv + 1
    end
    local frame = { unit = "player" }; s.frame = frame
    frame.Health = region("health"); frame.Health.fill = region("health.fill", frame.Health)
    for _, name in ipairs({ "myHealPredictionBar", "otherHealPredictionBar", "healAbsorbBar", "totalAbsorbBar", "absorbOverflow" }) do
        local bar = region(name, frame.Health); frame[name] = bar
        bar.fill = region(name .. ".fill", bar); bar.fill.fillOwner = bar
    end
    for _, name in ipairs({ "overHealAbsorbGlow", "overAbsorbGlow" }) do frame[name] = region(name) end
    for _, name in ipairs({ "totalAbsorbBar", "absorbOverflow" }) do
        local bar = frame[name]; bar.shieldOverlay = region(name .. ".shield", bar); bar.shieldOverlay.overlayOwner = bar
    end
    local ha = frame.healAbsorbBar
    ha.absorbOverlay = region("healAbsorb.overlay", ha); ha.absorbOverlay.overlayOwner = ha
    ha.healAbsorbOverlayActive = true
    ha.healAbsorbLeftShadow, ha.healAbsorbRightShadow = region("leftShadow"), region("rightShadow")
    frame.PortraitFrame = region("portrait.container"); frame.PortraitFrame.width = 110
    frame.Portrait, frame.Portrait2D = region("portrait.3d"), region("portrait.2d")
    frame.GetHeight = function() return 110 end
    s.region = region
    s.api = assert(load(code .. portraitCode .. "\nreturn { anchor = AnchorOverlayToStatusBarFill, tile = RefreshTiledOverlayTexCoords, position = UpdateFillPosition }",
        "@unit-owned-geometry-" .. branch, "t", env))()
    s.uf, s.env = env.UF, env
    function s:paint()
        self.uf.UpdateHealPrediction(self.frame)
        self.uf.SyncPortraitModelGeometry(self.frame)
    end
    return s
end
local function state(s)
    local out = {}
    for _, r in ipairs(s.regions) do
        local parts = { r.name, tostring(r.shown), tostring(r.width), tostring(r.height), tostring(r.value) }
        for _, point in ipairs({ "CENTER", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
            if r.points[point] then parts[#parts + 1] = point .. ":" .. table.concat(r.points[point], ",") end
        end
        if r.uv then parts[#parts + 1] = "uv:" .. table.concat(r.uv, ",") end
        out[#out + 1] = table.concat(parts, "|")
    end
    return table.concat(out, "\n")
end
local idleBefore, idleAfter
local function exercise(branch, code, portraitCode)
    local before, after = fixture(branch, oldPrediction, oldGeometry), fixture(branch, code or prediction, portraitCode or geometry)
    local function both(fn)
        fn(before); fn(after); before:paint(); after:paint()
        check(state(before) == state(after), branch .. ": live values, geometry and visibility match prior painter")
        check(before.ops.values == after.ops.values, branch .. ": status bar values retain every live update")
    end
    both(function(s) s.heal, s.mine, s.absorb, s.healAbsorb = 20, 8, 30, 5 end)
    local b, a = before.ops.anchor + before.ops.uv, after.ops.anchor + after.ops.uv
    local sizes = after.frame.Portrait.sizeWrites
    for _ = 1, 300 do both(function() end) end
    idleBefore, idleAfter = before.ops.anchor + before.ops.uv - b, after.ops.anchor + after.ops.uv - a
    -- Edge shadows and status bar live widths still update; only owned stable
    -- fill anchors, UVs and portrait geometry are cached by this change.
    check(idleAfter < idleBefore, branch .. ": unchanged updates reduce native geometry writes")
    check(after.frame.Portrait._fluxPortraitGeometrySize == 106 and after.frame.Portrait.sizeWrites == sizes,
        branch .. ": portrait geometry is stable while live bar sizes keep updating")
    both(function(s) s.heal, s.mine, s.other, s.absorb, s.healAbsorb = 31, 15, 16, 60, 12 end)
    both(function(s) s.width, s.height = 410, 37; s.frame.PortraitFrame.width = 90 end)
    both(function(s) s.height = 45 end)
    both(function(s) s.frame.myHealPredictionBar.fill = s.region("replacement.fill"); s.frame.myHealPredictionBar.fill.fillOwner = s.frame.myHealPredictionBar end)
    both(function(s)
        for _, name in ipairs({ "healAbsorbBar", "totalAbsorbBar" }) do
            local bar = s.frame[name]; bar.fill = s.region(name .. ".replacement.fill"); bar.fill.fillOwner = bar
        end
    end)
    both(function(s) s.showHeal = false; s.showAbsorb = false end)
    both(function(s) s.showHeal = true; s.showAbsorb = true end)
    both(function(s) s.dead = true end); both(function(s) s.dead = false end)
    both(function(s) s.heal, s.mine, s.other, s.absorb, s.healAbsorb = 0, 0, 0, 0, 0 end)
    both(function(s) s.heal, s.mine, s.other, s.absorb, s.healAbsorb = 8, 4, 4, 20, 3 end)
    -- Same region, changed tile dimensions/size and new fill identities must
    -- invalidate without suppressing the next paint or changing return values.
    local overlay = after.frame.totalAbsorbBar.shieldOverlay
    after.api.tile(overlay, 16)
    local uv = after.ops.uv; after.api.tile(overlay, 16)
    check(after.ops.uv == uv, branch .. ": unchanged UVs avoid native writes")
    overlay.secretWidth = true
    for _ = 1, 4 do after.api.tile(overlay, 16) end
    check(after.ops.uv == uv + 4 and overlay._fluxTileWidth == nil, branch .. ": secret dimensions are never cached or compared")
    overlay.secretWidth = false; after.api.tile(overlay, 16)
    check(overlay._fluxTileSize == 16, branch .. ": readable UV recovery repaints")
    uv = after.ops.uv; overlay.secretHeight = true
    for _ = 1, 3 do after.api.tile(overlay, 16) end
    check(after.ops.uv == uv + 3 and overlay._fluxTileHeight == nil, branch .. ": secret heights also retain native updates")
    overlay.secretHeight = false; overlay.failUV = true; after.api.tile(overlay, 8)
    check(overlay._fluxTileSize == nil, "failed UV write is not cached")
    overlay.failUV = false; after.api.tile(overlay, 8)
    check(overlay._fluxTileSize == 8, "failed UV write retries at the same dimensions")
    local moving = after.frame.myHealPredictionBar
    local anchors = after.ops.anchor
    for _ = 1, 3 do after.api.position(moving, after.frame.Health.fill, 10, secret(.1)) end
    check(after.ops.anchor == anchors + 9 and moving._fluxPredictionOffset == nil,
        "secret offsets never become comparison/cache keys")
    local fresh = after.region("fresh.overlay")
    local bar = after.frame.totalAbsorbBar
    fresh.failAnchor = true
    check(not pcall(after.api.anchor, bar, fresh), "failed anchors remain visible to the caller")
    fresh.failAnchor = false; after.api.anchor(bar, fresh)
    check(fresh._fluxAbsorbFillAnchor == bar.fill, "failed anchor retries successfully")
    local newFill = after.region("failed.replacement.fill")
    bar.fill = newFill; fresh.failAnchor = true; pcall(after.api.anchor, bar, fresh)
    check(fresh._fluxAbsorbFillAnchor == nil, "partial anchor failure invalidates the earlier fill")
    fresh.failAnchor = false; after.api.anchor(bar, fresh)
    check(fresh.points.TOPLEFT[1] == newFill.name, "replacement fill receives its actual anchor")
    local p = after.frame.Portrait; p.failSize = true; after.frame.PortraitFrame.width = 72
    after.uf.SyncPortraitModelGeometry(after.frame)
    check(p._fluxPortraitGeometrySize == nil, "failed model resize stays retryable")
    p.failSize = false; after.uf.SyncPortraitModelGeometry(after.frame)
    check(p.width == 68 and p._fluxPortraitGeometrySize == 68, "model resize recovers without replacing the model")
    local replaced = after.region("replacement.portrait")
    after.frame.Portrait = replaced; after.uf.SyncPortraitModelGeometry(after.frame)
    check(replaced.width == 68, "replacement portrait receives geometry even at unchanged size")
    local container = after.region("replacement.container"); container.width = 72
    after.frame.PortraitFrame = container; after.uf.SyncPortraitModelGeometry(after.frame)
    check(replaced.points.CENTER[1] == container.name, "new portrait container reanchors at unchanged size")
    if after.env.API.isMidnight then
        local values = after.ops.values
        for _ = 1, 5 do
            after.heal, after.mine, after.other, after.absorb, after.healAbsorb = secret(20), secret(8), secret(12), secret(30), secret(5)
            after:paint()
        end
        check(after.ops.values > values, branch .. ": secret healing/absorb values continue painting every update")
        check(after.frame.myHealPredictionBar.value == 8 and after.frame.totalAbsorbBar.value == 30,
            branch .. ": secrets reach native status bars directly")
    end
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do exercise(branch) end
local measuredBefore, measuredAfter = idleBefore, idleAfter
local mutants = 0
local function reject(body, old, new, portraitBody, message)
    local ok, err = pcall(exercise, "forever", replace(body, old, new), portraitBody)
    check(not ok and tostring(err):find(message, 1, true), "mutation rejected: " .. message .. ": " .. tostring(err)); mutants = mutants + 1
end
reject(prediction, "overlay._fluxAbsorbFillAnchor == fill", "overlay._fluxAbsorbFillAnchor ~= nil", nil, "live values, geometry and visibility")
reject(prediction, "and overlay._fluxTileHeight == h", "", nil, "live values, geometry and visibility")
reject(prediction, "type(w) == \"number\" and not ValueIsSecret(w)", "true", nil, "secret dimensions are never cached")
reject(prediction, "overlay._fluxAbsorbFillAnchor = nil", "", nil, "partial anchor failure invalidates")
local offsetOK, offsetErr = pcall(exercise, "classic_era",
    replace(prediction, "or self._fluxPredictionOffset ~= barOffsetX", ""))
check(not offsetOK and tostring(offsetErr):find("live values, geometry and visibility", 1, true),
    "mutation rejected: live legacy heal-absorb offset invalidation"); mutants = mutants + 1
local ok, err = pcall(exercise, "forever", prediction,
    replace(geometry, "region._fluxPortraitGeometrySize == contentSize", "region._fluxPortraitGeometrySize ~= nil"))
check(not ok and tostring(err):find("live values, geometry and visibility", 1, true), "mutation rejected: portrait resize invalidation"); mutants = mutants + 1
print(string.format("idle unit geometry: %d checks; five clients; %d mutations rejected; 300 unchanged updates anchor/UV writes %d -> %d", checks, mutants, measuredBefore, measuredAfter))
