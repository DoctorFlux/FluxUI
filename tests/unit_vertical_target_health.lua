-- Production vertical health helpers and loss overlay, including hostile opaque
-- values. Desktop models do not certify native protected frames or rendering.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local checks = 0
local function check(ok, label) assert(ok, label); checks = checks + 1 end
local function near(a, b, label) check(math.abs(a - b) < .00001, label) end
local base = read("tests/unit_overlay_secret_identity.lua")
base = base:sub(1, assert(base:find("local function healthCases()", 1, true)) - 1)
local make = assert(load(base .. "\nreturn fixture", "@vertical-overlay-fixture", "t", _G))()
local shared = read(os.getenv("FLUX_VERTICAL_SOURCE") or "UnitFrames/FluxUnitFrames_Shared.lua")
local first = assert(shared:find("function UF.LayoutVerticalTargetHealth", 1, true))
local last = assert(shared:find("function UF.UpdateHealth(self, unit)", first, true))
local helperSource = shared:sub(first, last - 1)

local function fixture(client, unit, withExistingLoss, initiallyDisabled)
    local s = make(client == "live" or client == "forever")
    local e, ns, f = s.env, s.ns, s.player
    local UF = ns.UnitFrames
    e.UF, e.ns, e.API = UF, ns, ns.API
    e.TEXTURE_BAR, e.TEXTURE_BG = "Interface\\TargetingFrame\\UI-StatusBar", "Interface\\Buttons\\WHITE8X8"
    e.ValueIsSecret = ns.API.IsSecretValue
    e.PublicGeometryNumber = function(v) if not ns.API.IsSecretValue(v) and type(v) == "number" then return v end end
    e.StatusBarSetMinMaxImmediate = function(bar, a, b) bar:SetMinMaxValues(a, b) end
    e.StatusBarSetValueImmediate = function(bar, v) bar:SetValue(v) end
    e.InCombatLockdown = function() return s.combat end
    e.UnitIsConnected = function() return s.connected end
    e.UnitIsDead = function() return s.dead end
    e.UnitIsGhost = function() return s.ghost end
    e.UnitIsAFK = function() return s.afk end
    e.UnitGetTotalAbsorbs = function() return s.absorbs or 0 end
    e.UnitIsDeadOrGhost = function() return s.dead or s.ghost end
    e.FluxUnitFrames_ShouldShowAbsorbs = function() return s.showAbsorbs ~= false end
    ns.API.isMidnight = client == "live" or client == "forever"
    ns.API.SafeUnitGetTotalAbsorbs = e.UnitGetTotalAbsorbs
    ns.API.SafeUnitGetTotalHealAbsorbs = function() return s.healAbsorbs or 0 end
    ns.API.CreateUnitHealPredictionCalculator = function()
        assert(not s.combat, "calculator allocated before combat")
        return {
            SetDamageAbsorbClampMode = function(self, mode) self.mode = mode end,
            SetHealAbsorbClampMode = function(self, mode) self.healClamp = mode end,
            SetHealAbsorbMode = function(self, mode) self.healMode = mode end,
            GetDamageAbsorbs = function(self)
                if ns.API.IsSecretValue(s.absorbs) then return s.absorbs end
                if ns.API.IsSecretValue(s.healthMax) or ns.API.IsSecretValue(s.health) then return s:secret("number") end
                return math.min(s.absorbs or 0, self.mode == 1 and (s.healthMax - s.health) or s.healthMax)
            end,
            GetHealAbsorbs = function(self)
                check(self.healClamp == 0 and self.healMode == 1, "native heal absorb uses total amount clamped to health")
                if ns.API.IsSecretValue(s.healAbsorbs) then return s.healAbsorbs end
                if ns.API.IsSecretValue(s.health) then return s:secret("number") end
                return math.min(s.healAbsorbs or 0, s.health)
            end,
        }
    end
    ns.API.UnitGetDetailedHealPrediction = function(unit) check(unit == f.unit, "calculator follows live unit token") end
    e.ApplyBlizzardShieldFillToStatusBar = function(overlay) overlay:SetStatusBarColor(.14, .33, .7, .7) end
    e.ApplyBlizzardHealAbsorbFillToStatusBar = function(overlay) overlay:SetStatusBarColor(.5, 0, 0, .7) end
    e.FluxUnitFrames_GetTargetClassHealthColor = function() if s.classColor then return .2, .4, .8 end end
    UF.RecordFrameDimensions = function(frame, w, h) frame._publicWidth, frame._publicHeight = w, h end
    UF.GetFramePublicDimensions = function(frame) return frame._publicWidth, frame._publicHeight end
    UF.DeferProtected = function(key, fn) s.deferred = s.deferred or {}; s.deferred[key] = fn end
    local methods = getmetatable(f).__index
    function methods:SetOrientation(v) self.orientation = v end
    function methods:GetOrientation() return self.orientation end
    function methods:SetReverseFill(v) self.reverseFill = v end
    function methods:SetClipsChildren(v) self.clipsChildren = v end
    function methods:SetSize(w, h) self.width, self.height = w, h end
    function methods:GetValue() return self.value end
    function methods:GetMinMaxValues() return self.low, self.high end
    function methods:SetTexCoord(...) self.texCoords = {...} end
    local oldPoint = methods.SetPoint
    function methods:SetPoint(...) oldPoint(self, ...); self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    local create = e.CreateFrame
    e.CreateFrame = function(...) assert(not s.combat, "new effects allocated in combat"); return create(...) end
    assert(load(helperSource, "@vertical-health-helpers", "t", e))()
    f.unit, f._publicWidth, f._publicHeight = unit, 24, 56
    s.connected, s.dead, s.ghost, s.afk = true, false, false, false
    s.enabled = not initiallyDisabled
    if not withExistingLoss then f.Health.AnimatedLossBar = nil end
    UF.ConfigureVerticalTargetHealth(f, f.Health)
    function s:sample(h)
        self.health = h
        UF.UpdateVerticalTargetHealth(f, unit)
    end
    function s:step(dt)
        self.now = self.now + dt
        local tex = f.Health.ClassicLossTex
        if tex._driver:IsShown() then tex._driver.scripts.OnUpdate(tex._driver, dt) end
    end
    s:sample(100)
    s.combat = true
    return s, UF, f, f.Health
end

for _, client in ipairs({"live", "forever", "classic", "classic_era", "classic_anniversary"}) do
    for _, unit in ipairs({"party1target", "party2target", "party3target", "party4target", "focustarget", "pettarget"}) do
        local s, UF, f, bar = fixture(client, unit, unit == "focustarget")
        local tex, loss = bar.ClassicLossTex, bar.AnimatedLossBar
        check(f.HealthBar == bar and bar.orientation == "VERTICAL" and loss.orientation == "VERTICAL", client .. " shared axis")
        check(bar.fill.texCoords[8] == 1 and loss.fill.texCoords[8] == 1, "both fills rotated")
        check(bar.bg.parent == bar.trough and bar.trough.level >= f.level and bar.trough.level < loss.level and loss.level < bar.level, "trough/loss/health layering above the target background")
        near(bar._fluxHealthLossExtent, 50, "public vertical extent")
        check(not tex:IsShown() and not tex._driver:IsShown() and not loss:IsShown(), "new target primes quietly")
        check(bar.value == 100 and bar.low == 0 and bar.high == 100, "shared HP values use native sinks")
        s:sample(80)
        check(tex:IsShown() and tex._driver:IsShown(), "vertical hit starts trail")
        near(tex.height, 10, "damage uses height rather than width")
        check(tex.points[1][1] == "BOTTOMLEFT" and tex.points[2][1] == "BOTTOMRIGHT", "gap spans bar width")
        near(tex.points[1][5], 40, "gap starts at current vertical health edge")
        s:step(.03); s:sample(60)
        near(tex._animFrom, 50, "second hit retains original edge")
        near(tex.height, 20, "second hit extends vertical gap")
        near(tex._animStart, 10.15, "native postpone cadence")
        s:step(.245)
        near(tex._displayedEdge, 40, "trail descends after delay")
        s:sample(40)
        near(tex._animFrom, 40, "in-flight hit resumes from edge, not gap size")
        near(tex._animStart, s.now + .05, "native pause cadence")
        s:step(.18)
        check(tex.height > 0 and tex.height < 20, "vertical loss interpolates")
        s:step(.13)
        check(not tex:IsShown() and not tex._driver:IsShown(), "idle driver parks")
        s:sample(20); s:sample(70)
        check(not tex:IsShown(), "healing clears loss")
        s:sample(30); s.healthMax = 200; s:sample(20)
        check(not tex:IsShown(), "max-health changes re-prime geometry")
        s.healthMax = 100; s:sample(100); s:sample(60)
        s.guid = "changed-target"; s:sample(30)
        check(not tex:IsShown(), "target GUID swap clears prior damage")
        s:sample(10); UF.ResetVerticalTargetHealth(f); s:sample(90)
        check(not tex:IsShown(), "identity event primes replacement target")
        s:sample(50); f:Hide()
        check(not tex:IsShown() and not tex._driver:IsShown(), "hide cancels animation")
        f:Show(); s:sample(100)
        s.classColor = true; s:sample(90)
        check(bar.color[1] == .2 and bar.color[3] == .8, "target class color retained")
        for _, key in ipairs({"dead", "ghost", "afk"}) do
            s[key] = true; s:sample(90)
            check(bar.color[1] == .5 and bar.color[2] == .5, key .. " target gray")
            s[key] = false
        end
        s.connected = false; s:sample(80)
        check(not tex:IsShown() and bar.color[1] == .5, "offline target clears trail and grays")
        s.connected = true; s:sample(100)
        s.absorbs = 10; s:sample(60)
        check(not tex:IsShown(), "readable absorbs suppress loss like native health bars")
        check(f.verticalAbsorbBar and f.verticalAbsorbBar:IsShown() and f.verticalAbsorbBar.value == 10, "shield appears on target without resizing health")
        check(f.verticalAbsorbBar.orientation == "VERTICAL" and f.verticalAbsorbBar.height == 50, "shield uses full height normalization")
        check(f.verticalAbsorbBar.point[1] == "BOTTOMLEFT" and f.verticalAbsorbBar.point[2] == bar.fill, "shield starts at live vertical health edge")
        check(f.verticalAbsorbOverflow.reverseFill and f.verticalAbsorbClip.allPoints == bar.fill and f.verticalAbsorbClip.clipsChildren,
            "overflow reverses inside native health-fill clip")
        s.absorbs = 80; s.healAbsorbs = 15; s:sample(60)
        check(f.verticalAbsorbBar.value == 40 and f.verticalAbsorbOverflow.value == 80, "large shield fills remaining space and spills over health")
        check(f.verticalHealAbsorbBar.value == 15 and f.verticalHealAbsorbBar.reverseFill, "heal absorb bites downward from health edge")
        s.showAbsorbs = false; UF.UpdateVerticalTargetAbsorbs(f)
        check(not f.verticalAbsorbBar:IsShown() and not f.verticalAbsorbOverflow:IsShown() and not f.verticalHealAbsorbBar:IsShown(), "absorb option hides every vertical overlay")
        s.showAbsorbs = true
        local allocated = #s.frames
        for _ = 1, 20 do UF.UpdateVerticalTargetAbsorbs(f) end
        check(#s.frames == allocated, "repeated combat shield changes allocate no frames")
        if s.ns.API.isMidnight then
            s.absorbs, s.healAbsorbs = s:secret("number"), s:secret("number")
            UF.UpdateVerticalTargetAbsorbs(f)
            check(f.verticalAbsorbBar.value == s.absorbs and f.verticalHealAbsorbBar.value == s.healAbsorbs and s.opaqueOps == 0,
                "opaque absorbs pass directly to vertical native value sinks")
        end
        s.absorbs, s.healAbsorbs = 0, 0; UF.UpdateVerticalTargetAbsorbs(f)
        check(not f.verticalAbsorbBar:IsShown() and not f.verticalAbsorbOverflow:IsShown(), "expired shields clear without health change")
        s.absorbs = 0
        s.enabled = false; s:sample(30)
        check(not bar._fluxHealthLossUnderlay and not tex:IsShown(), "feature toggle cancels effects")
        s.enabled = true; s:sample(90); s:sample(70)
        check(tex:IsShown(), "existing effects re-enable in combat without allocations")
        UF.LayoutVerticalTargetHealth(f)
        check(s.deferred["vertical.layout." .. unit] ~= nil, "protected target geometry defers in combat")
        s.guid, s.healthMax = s:secret("string"), s:secret("number")
        s.connected, s.dead, s.afk = s:secret("boolean"), s:secret("boolean"), s:secret("boolean")
        s:sample(s:secret("number"))
        check(loss:IsShown() and not tex:IsShown() and bar._fluxLossSecretPending and s.opaqueOps == 0, "opaque values use vertical native sink only")
        local callback = s.timers[#s.timers]
        callback()
        check(bar._fluxLossSecretPending == false and s.opaqueOps == 0, "opaque delayed sink does no arithmetic")
        local idle = s.timers[#s.timers]
        s.healthMax, s.connected, s.dead, s.afk = 100, true, false, false
        s:sample(30)
        check(not tex:IsShown(), "secret-to-readable transition does not invent a giant hit")
        UF.ResetVerticalTargetHealth(f)
        local writes = s.lossWrites; callback(); idle()
        check(s.lossWrites == writes and not loss:IsShown(), "stale callbacks cannot paint a replacement target")
        s:sample(100); s:sample(50)
        check(tex:IsShown() and s.opaqueOps == 0, "readable vertical loss resumes after identity reset")
        s.combat = false; f._publicHeight = 106; UF.LayoutVerticalTargetHealth(f); s.combat = true
        check(not tex:IsShown() and bar._fluxHealthLossExtent == 100, "resize cancels old pixel animation")
        s:sample(100); s:sample(80)
        near(tex.height, 20, "loss uses resized public height")
        s.healthMax = 0; s:sample(0)
        check(not tex:IsShown() and not loss:IsShown(), "missing target with zero maximum cannot flash red")
        s.healthMax = 100; s:sample(80)
        check(not tex:IsShown() and not loss:IsShown(), "target reappearance re-primes")
    end
    local s, UF, f, bar = fixture(client, "party1target", false, true)
    check(not bar._fluxHealthLossUnderlay and bar.ClassicLossTex and bar.AnimatedLossBar, "disabled initial configuration prewarms vertical effects")
    s.enabled = true; s:sample(100); s:sample(50)
    check(bar.ClassicLossTex:IsShown(), "initially disabled feature enables during combat without new frames")
end

-- The existing Classic horizontal path shares the corrected trailing-edge math.
local h = make(false)
h:healthSample(100, 200); h:healthSample(80, 160)
local t = h.player.Health.ClassicLossTex
check(t.point[1] == "BOTTOMLEFT" and t.width == 40, "horizontal gap remains horizontal")
h.now = h.now + .225; t._driver.scripts.OnUpdate()
near(t._displayedEdge, 180, "horizontal animation edge")
h:healthSample(60, 120)
near(t._animFrom, 180, "horizontal repeated hit retains active edge")
print("Vertical target health: " .. checks .. " checks; five client models, six target tokens; native taint/rendering pending")
