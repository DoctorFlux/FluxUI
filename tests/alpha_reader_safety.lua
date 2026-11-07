-- Execute frozen production/candidate functions; model alpha secrecy, not WoW taint.
local baseline, candidate = "before", "."
local old = assert(loadfile("tests/fixtures/alpha_reader_before.txt"))()
local checks, rejected, failures = 0, 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function read(root, path)
    local f = assert(io.open(path, "rb")); local text = f:read("*a"); f:close()
    text = text:gsub("^\239\187\191", ""):gsub("\r\n", "\n")
    if root ~= baseline then return text end
    local function replacePart(first, last, replacement)
        local a = assert(text:find(first, 1, true)); local b = last and assert(text:find(last, a + #first, true)) or #text + 1
        text = text:sub(1, a - 1) .. replacement .. text:sub(b)
    end
    if path == "Bars/Blizzard.lua" then replacePart("function Blizzard.QuietGrid()", nil, old.grid)
    elseif path == "Core/ButtonFX/Cast.lua" then replacePart("local function ReadableAlpha(value)", "local function SpellOf(entry)", old.cast)
    elseif path == "Core/ButtonFX/Charges.lua" then replacePart("local function SetBling(cd, on)", "-- ButtonForge Classic:", old.bling)
    elseif path == "Bars/BadgeHost.lua" then replacePart("function BadgeHost.GetVisibleBadgesForButton(button)", "function BadgeHost.RefreshLayout()", old.badge)
    elseif path == "ExtraButtonSystem/Engine/Button.lua" then
        local count; text, count = text:gsub("local alpha = PublicCooldownAlpha%(cd%)", "local alpha = (cd.GetEffectiveAlpha and cd:GetEffectiveAlpha()) or 1")
        assert(count == 2, "both old Extra alpha-reader controls exist")
    elseif path == "ExtraButtonSystem/Engine/Style.lua" then replacePart("local function NormalRingVisible(tex)", "local function HideOverlayRing(widget)", old.ring)
    end
    return text
end

local function part(root, path, first, last)
    local s = read(root, path); local a = assert(s:find(first, 1, true), first)
    local b = last and assert(s:find(last, a + #first, true), last) or #s + 1
    return s:sub(a, b - 1)
end
local opaque = setmetatable({}, { __lt = function() error("OPAQUE_ALPHA_ORDER") end,
    __le = function() error("OPAQUE_ALPHA_ORDER") end, __div = function() error("OPAQUE_ALPHA_DIVISION") end })
local accessMode = "both"
local clientModel = "live"
local function stable(v)
    if type(v) ~= "table" then return tostring(v) end
    local keys = {}; for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local out = {}; for _, k in ipairs(keys) do out[#out + 1] = tostring(k) .. "=" .. stable(v[k]) end
    return "{" .. table.concat(out, ",") .. "}"
end
local function env()
    local e = setmetatable({}, { __index = _G }); e._G = e
    e.type = function(v) return rawequal(v, opaque) and "number" or type(v) end
    e.issecretvalue = function(v) return rawequal(v, opaque) and accessMode ~= "notsecret-denied" end
    e.canaccessvalue = function(v) return not rawequal(v, opaque) or accessMode == "secret-readable" end
    local ns = { Flux = { Client = { branch = clientModel,
        isAnyClassic = clientModel == "classic_era" or clientModel == "classic_anniversary" or clientModel == "classic" } }, _secretsBackend = {
        IsSecretValue = e.issecretvalue, CanAccessValue = e.canaccessvalue,
        CanAccessSecrets = function() return false end } }
    e.Flux = ns.Flux
    assert(load(read(baseline, "Core/API/Secrets.lua"), "@actual-Secrets", "t", e))("_FluxUI", ns)
    e.FluxAPICompat = { API = ns.Flux.Secrets, FLUX_API = {} }
    e.GetTime = function() return 100 end
    return e, ns
end
local function frame(alpha)
    local f = { alpha = alpha, shown = true, reads = 0, writes = 0, timers = 0, clears = 0,
        bling = false, edge = false, swipe = true, swipeAlpha = 0.64, points = {}, scripts = {} }
    function f:GetAlpha()
        self.reads = self.reads + 1
        if self.callDenied then error("MODELED_ALPHA_GETTER_DENIED") end
        return self.opaque and opaque or self.alpha
    end
    f.GetEffectiveAlpha = f.GetAlpha
    function f:SetAlpha(v) assert(not rawequal(v, opaque)); self.alpha = v; self.writes = self.writes + 1 end
    function f:IsShown() return self.shown end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
    function f:SetDrawBling(v) self.bling = v end
    function f:SetDrawEdge(v) self.edge = v end
    function f:SetDrawSwipe(v) self.swipe = v end
    function f:SetSwipeColor(_, _, _, a) self.swipeAlpha = a end
    function f:SetCooldown(start, duration) self.start, self.duration = start, duration; self.timers = self.timers + 1 end
    function f:SetCooldownFromDurationObject(obj) self.object = obj; self.timers = self.timers + 1 end
    function f:Clear() self.clears = self.clears + 1; self.start, self.duration = 0, 0 end
    function f:GetFrameLevel() return 1 end
    function f:SetFrameLevel(v) self.level = v end
    function f:ClearAllPoints() self.points = {} end
    function f:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function f:SetHideCountdownNumbers() end
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:GetParent() return self.parent end
    function f:SetParent(p) self.parent = p end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:GetSize() return self.width or 36, self.height or 36 end
    function f:IsVisible() return self.shown end
    return f
end
local function compile(root, path, first, last, e, ending)
    return assert(load(part(root, path, first, last) .. "\n" .. (ending or ""), "@" .. path, "t", e))()
end
local function quiet(root, alpha, secret, rounds)
    local e, ns = env(); local timers, objects = {}, {}
    e.Bars = { secureReady = true, NUM_NATIVE = 12, started = true }
    e.Blizzard = {}; ns.Flux.Bars = e.Bars; e.Bars.Blizzard = e.Blizzard
    for i = 1, 24 do objects[i] = frame(alpha); objects[i].opaque = secret == true; objects[i].callDenied = secret == "call-denied" end
    e.Blizzard.GetActionButton = function(i) return objects[i] end
    for i = 1, 12 do e["MainActionBarButtonContainer" .. i] = objects[12 + i] end
    local list = part(root, "Bars/Blizzard.lua", "local MULTI_BARS = {", "local MAIN_BAR_ART")
    e.MULTI_BARS = assert(load(list .. "\nreturn MULTI_BARS", "@native-list", "t", e))()
    for _, name in ipairs(e.MULTI_BARS) do
        local f = frame(alpha); f.opaque = secret == true; f.callDenied = secret == "call-denied"; e[name] = f; objects[#objects + 1] = f
    end
    e.CanReplaceBar = function() return true end
    compile(root, "Bars/Blizzard.lua", "function Blizzard.QuietGrid()", nil, e)
    -- Actual event sweep queue coalesces to the next frame and defers in combat.
    ns.Flux.Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
    e.Flux = ns.Flux; e.InLockdown = function() return false end
    compile(baseline, "Bars/Init.lua", "local function RunStockSweep()", "function Bars.RequestPaint(token)", e)
    for tick = 1, rounds or 1 do
        for i = 1, 1000 do e.Bars.RequestStockSweep() end
        check(#timers == 1, "actual stock sweep queue coalesces 1000 requests")
        local q = timers; timers = {}; for _, fn in ipairs(q) do fn() end
    end
    local reads, writes = 0, 0
    for _, f in ipairs(objects) do reads = reads + f.reads; writes = writes + f.writes end
    return { reads = reads, writes = writes, alpha = objects[1].alpha, excludedStanceAlpha = e.StanceBar.alpha }
end
local function castShown(root, alpha, secret, options)
    local e = env(); options = options or {}; local w = frame(alpha); w.opaque = secret == true; w.callDenied = secret == "call-denied"
    w._fluxParked = options.parked; w._fluxBadgeCombatVisHidden = options.hidden
    w.FluxButton = options.badgeAlpha ~= nil and { _fluxBadgeAlpha = options.badgeAlpha } or nil
    w.shown = options.shown ~= false
    local source = read(root, "Core/ButtonFX/Cast.lua")
    local first = source:find("local function ReadableAlpha(value)", 1, true) and "local function ReadableAlpha(value)" or "local function WidgetShown(widget)"
    local fn = compile(root, "Core/ButtonFX/Cast.lua", first, "local function SpellOf(entry)", e, "return WidgetShown")
    return { shown = fn(w), reads = w.reads }
end
local function badgeVisible(root, alpha, secret, configured, hidden)
    local e = env(); local w = frame(alpha); w.opaque = secret == true; w.callDenied = secret == "call-denied"; w._fluxBadgeCombatVisHidden = hidden
    local button, badge = { _fluxHost = {} }, { Widget = w, _fluxBadgeAlpha = configured }
    e.BadgeHost, e.instances, e.slotBadges = {}, { [button] = { [1] = { badge } } }, { [1] = { {} } }
    e.LiveSlotOf = function() return 1 end; e.ShouldShow = function() return true end
    local readable = part(root, "Bars/BadgeHost.lua", "local function CanRead(value)", "local function CooldownRunning(")
    local body = part(root, "Bars/BadgeHost.lua", "function BadgeHost.GetVisibleBadgesForButton(button)", "function BadgeHost.RefreshLayout()")
    assert(load(readable .. body, "@badge-visible-production", "t", e))()
    local got = e.BadgeHost.GetVisibleBadgesForButton(button)
    return { count = got and #got or 0, reads = w.reads }
end
local function bootCharges(root, alpha, secret)
    local e, ns = env(); local cd = frame(alpha); cd.opaque = secret == true; cd.callDenied = secret == "call-denied"
    e.CreateFrame = function(_, _, parent) local f = frame(alpha); f.opaque = secret == true; f.callDenied = secret == "call-denied"; f.parent = parent; return f end
    assert(load(read(root, "Core/ButtonFX/Charges.lua"), "@charges-complete", "t", e))("_FluxUI", ns)
    local widget = { cooldown = cd, GetFrameLevel = function() return 1 end }
    return ns.Flux.ButtonFX.Charges, widget, cd
end
local function charges(root, alpha, secret)
    local fx, w, cd = bootCharges(root, alpha, secret)
    local opts = { start = 100, duration = 8, enable = 1, skipDurationObject = true,
        current = 1, maxCharges = 1, chargeIsActive = false }
    fx.Apply(w, opts)
    return { bling = cd.bling, edge = cd.edge, swipe = cd.swipe, swipeAlpha = cd.swipeAlpha, timers = cd.timers, shown = cd.shown }
end
local function bootButton(root, alpha, secret)
    local e = env(); e.FluxButton = {}
    assert(load(read(root, "ExtraButtonSystem/Engine/Button.lua"), "@button-complete", "t", e))()
    local cd = frame(alpha); cd.opaque = secret == true; cd.callDenied = secret == "call-denied"
    local b = setmetatable({ WCooldown = cd }, { __index = e.FluxButton })
    return b, cd
end
local function extra(root, alpha, secret, durationObject, charge)
    local b, cd = bootButton(root, alpha, secret)
    if durationObject then b:CooldownFrame_SetFromDurationObject({}, charge)
    else b:CooldownFrame_SetTimer(100, 8, 1, charge and 1 or nil, charge and 2 or nil, false) end
    return { bling = cd.bling, edge = cd.edge, swipe = cd.swipe, swipeAlpha = cd.swipeAlpha,
        timers = cd.timers, shown = cd.shown, visible = b._lastCooldownVisible, duration = b._lastCooldownDuration }
end

for _, mode in ipairs({ "secret-readable", "notsecret-denied" }) do
    accessMode = mode
    for _, run in ipairs({ function() return quiet(candidate, .75, true) end,
        function() return charges(candidate, .75, true) end,
        function() return castShown(candidate, .75, true) end,
        function() return badgeVisible(candidate, .75, true, .75) end,
        function() return extra(candidate, .75, true, false, false) end,
        function() return extra(candidate, .75, true, true, true) end }) do
        local ok, err = pcall(run)
        check(ok, "separate secrecy/access guard " .. mode .. " " .. tostring(err))
    end
end
accessMode = "both"

-- Plain numbers retain exact state and side-effect counts for existing paths.
for _, model in ipairs({ "live", "forever", "classic_era", "classic_anniversary", "classic" }) do
clientModel = model
for _, alpha in ipairs({ 0, .01, .4, .40001, .75, 1 }) do
    for _, test in ipairs({ { "grid", function(root) return quiet(root, alpha, false, 2) end },
        { "cast", function(root) return castShown(root, alpha, false) end },
        { "badge", function(root) return badgeVisible(root, alpha, false, .75) end },
        { "bling", function(root) return charges(root, alpha, false) end },
        { "extra-numeric", function(root) return extra(root, alpha, false, false, false) end },
        { "extra-charge", function(root) return extra(root, alpha, false, false, true) end },
        { "extra-duration", function(root) return extra(root, alpha, false, true, false) end },
        { "extra-duration-charge", function(root) return extra(root, alpha, false, true, true) end } }) do
        local okB, b = pcall(test[2], baseline); local okC, c = pcall(test[2], candidate)
        check(okB and okC and stable(b) == stable(c), "public parity " .. model .. " " .. test[1] .. " alpha=" .. alpha .. " " .. tostring(b) .. " / " .. tostring(c))
    end
end
end
clientModel = "live"
for _, spec in ipairs({ { "ALPHA-01", function(root) return quiet(root, .75, true, 2) end },
    { "ALPHA-03", function(root) return charges(root, .75, true) end },
    { "ALPHA-04-cast", function(root) return castShown(root, .75, true) end },
    { "ALPHA-04-badge", function(root) return badgeVisible(root, .75, true, .75) end },
    { "ALPHA-05-numeric", function(root) return extra(root, .75, true, false, false) end },
    { "ALPHA-05-duration", function(root) return extra(root, .75, true, true, true) end } }) do
    local b, err = pcall(spec[2], baseline); local c, value = pcall(spec[2], candidate)
    check(not b and tostring(err):find("OPAQUE_ALPHA", 1, true), "baseline rejects " .. spec[1])
    check(c, "candidate avoids unreadable alpha operation " .. spec[1] .. " " .. tostring(value))
    if not b then rejected = rejected + 1 end
    print("REJECTION " .. spec[1] .. " baseline=" .. tostring(b) .. " candidate=" .. tostring(c))
end
for _, options in ipairs({ { parked = true }, { hidden = true }, { shown = false }, { badgeAlpha = 0 } }) do
    local ok, result = pcall(castShown, candidate, 1, true, options)
    check(ok and result.shown == false, "cast pruning uses public parked/hidden/logical/configured-zero facts")
end
check(badgeVisible(candidate, 1, true, 0).count == 0, "configured zero badge stays pruned when getter is private")
check(badgeVisible(candidate, 1, true, .75, true).count == 0, "hidden combat badge stays pruned")
do
    local fx, w, cd = bootCharges(candidate, .75, true)
    local opts = { start = 100, duration = 8, enable = 1, skipDurationObject = true, chargeIsActive = false }
    cd.bling = false; fx.Apply(w, opts)
    check(cd._fxBlingDeferred and cd.timers == 1 and not cd.bling, "private bling defers only appearance while timer progresses")
    cd.opaque, cd.alpha = false, 1; fx.Apply(w, opts)
    check(cd.bling and not cd._fxBlingDeferred and cd.timers == 1, "cache hit recovers public bling without restarting timer")
    cd.opaque = true; opts.start, opts.duration = 0, 0; fx.Apply(w, opts)
    check(not cd.bling and not cd._fxBlingDeferred and cd.clears > 0, "ready cooldown clears with bling off even when alpha is private")
end
-- Narrow guards contain denied getter calls; the permitted owner/timer path continues.
-- No guard is treated as permission to read or declassify a restricted result.
for _, test in ipairs({ { "grid", function() return quiet(candidate, 1, "call-denied") end },
    { "bling", function() return charges(candidate, 1, "call-denied") end },
    { "extra-numeric", function() return extra(candidate, 1, "call-denied", false, false) end },
    { "extra-duration", function() return extra(candidate, 1, "call-denied", true, true) end } }) do
    local ok, err = pcall(test[2])
    check(ok, "getter denial retains permitted owner/timer policy " .. test[1] .. " " .. tostring(err))
    print("HANDLED getter_call_denied=" .. test[1])
end
check(castShown(candidate, 1, "call-denied", { badgeAlpha = 0 }).shown == false,
    "existing narrow cast getter guard uses configured zero on denial")
check(badgeVisible(candidate, 1, "call-denied", 0).count == 0,
    "existing narrow badge getter guard uses configured zero on denial")
for _, durationObject in ipairs({ false, true }) do
    local b, cd = bootButton(candidate, .75, true)
    cd.bling, cd.edge, cd.swipeAlpha = false, false, .2
    if durationObject then b:CooldownFrame_SetFromDurationObject({}, true) else b:CooldownFrame_SetTimer(100, 8, 1, 1, 2) end
    check(cd.timers == 1 and not cd.bling and not cd.edge and cd.swipeAlpha == .2, "private Extra appearance stays while timer progresses")
    cd.opaque, cd.alpha = false, 1
    if durationObject then b:CooldownFrame_SetFromDurationObject({}, true) else b:CooldownFrame_SetTimer(100, 8, 1, 1, 2) end
    check(cd.bling and cd.edge and not cd.swipe and cd.swipeAlpha == 1, "Extra public reappearance restores edge/bling/swipe policy")
    b:ClearCooldownVisual(); check(not cd.shown and not b._lastCooldownVisible, "Extra cooldown completion still clears/hides")
end
do
    local z = quiet(candidate, 0, false, 100)
    local u = quiet(candidate, 1, true, 100)
    check(z.writes == 0, "stable public zero grid has no extra native writes")
    check(u.writes == 3600, "100 opaque grid sweeps reassert exactly36selected fixture objects each")
    print(("METRIC grid rounds=100 requests_per_round=1000 public_zero_reads=%d public_zero_writes=%d opaque_reads=%d opaque_writes=%d excluded_stance_alpha=%s")
        :format(z.reads, z.writes, u.reads, u.writes, tostring(u.excludedStanceAlpha)))
end

local textures = { "spark", "innerGlow", "innerGlowOver", "outerGlow", "outerGlowOver", "ants" }
local function glow(root, secret, foreignVersion, geometryMode)
    local e, ns = env(); e.lib = {}; local allTextures, allFrames, created, released = {}, {}, 0, 0
    local sharedCalls = 0
    e.LibStub = false; e.strmatch = string.match
    assert(load(read(root, "libs/LibStub/LibStub.lua"), "@actual-LibStub", "t", e))()
    local shared
    if foreignVersion then
        shared = assert(e.LibStub:NewLibrary("LibCustomGlow-1.0", foreignVersion))
        shared.ButtonGlow_Start = function() sharedCalls = sharedCalls + 1; error("foreign shared renderer called") end
    end
    local originalSharedStart = shared and shared.ButtonGlow_Start
    local function newGlow()
        local f = frame(1)
        if root ~= baseline then
            f.GetSize = function() error("owned glow callbacks must use recorded size arguments") end
        end
        function f:CreateTexture()
            local t = frame(0); t.opaque = secret == true; t.callDenied = secret == "call-denied"
            function t:SetTexture(v) self.texture = v end
            function t:SetTexCoord(...) self.coords = { ... } end
            function t:SetDesaturated(v) self.desaturated = v end
            function t:SetVertexColor(...) self.color = { ... } end
            allTextures[#allTextures + 1] = t; return t
        end
        function f:CreateAnimationGroup()
            local g = { parent = self, animations = {}, scripts = {}, playing = false }
            function g:GetParent() return self.parent end
            function g:CreateAnimation(kind)
                local a = { kind = kind }; self.animations[#self.animations + 1] = a
                for _, method in ipairs({ "ChildKey", "Order", "Duration", "Scale", "StartDelay", "FromAlpha", "ToAlpha" }) do
                    a["Set" .. method] = function(self, ...) self[method] = { ... } end
                end
                return a
            end
            function g:SetScript(k, fn) self.scripts[k] = fn end
            function g:IsPlaying() return self.playing end
            function g:Play() self.playing = true; if self.scripts.OnPlay then self.scripts.OnPlay(self) end end
            function g:Stop() self.playing = false; if self.scripts.OnStop then self.scripts.OnStop(self) end end
            function g:Finish() self.playing = false; if self.scripts.OnFinished then self.scripts.OnFinished(self) end end
            return g
        end
        allFrames[#allFrames + 1] = f
        return f
    end
    e.CreateFramePool = function(_, _, _, reset)
        local p = { inactive = {} }
        function p:Acquire()
            local f = table.remove(self.inactive); local new = not f
            if new then f = newGlow(); created = created + 1 end
            return f, new
        end
        function p:Release(f) released = released + 1; reset(self, f); self.inactive[#self.inactive + 1] = f end
        return p
    end
    if root == baseline then
        compile(root, "libs/LibCustomGlow-1.0/LibCustomGlow-1.0.lua", "local function ButtonGlowResetter(framePool,frame)", 'table.insert(lib.glowList, "Action Button Glow")', e)
    else
        assert(load(read(root, "Core/ButtonFX/ThreatGlow.lua"), "@private-threat-glow-complete", "t", e))("_FluxUI", ns)
        e.lib = ns.Flux.ButtonFX.ThreatGlow
        assert(load(read(root, "Core/ButtonFX/ThreatGlow.lua"), "@private-threat-glow-repeat-load", "t", e))("_FluxUI", ns)
        check(ns.Flux.ButtonFX.ThreatGlow == e.lib, "repeat private module load retains its renderer/pool owner")
        if foreignVersion == 20 then
            local upgraded, oldMinor = e.LibStub:NewLibrary("LibCustomGlow-1.0", 25)
            check(upgraded == shared and oldMinor == 20, "actual LibStub upgrades a later shared winner independently")
            shared.ButtonGlow_Start = function() sharedCalls = sharedCalls + 1; error("later winning shared renderer called") end
            originalSharedStart = shared.ButtonGlow_Start
        end
    end
    local glowKey = root == baseline and "_ButtonGlow" or "_fluxThreatButtonGlow"
    local r, snapshots = frame(1), {}
    if root ~= baseline then
        r._fluxPublicWidth, r._fluxPublicHeight = 36, 36
        r.GetSize = function() error("owned shell geometry should bypass native getter") end
    end
    local foreign = frame(1)
    if foreignVersion then r._ButtonGlow = foreign end
    if geometryMode then
        r._fluxPublicWidth, r._fluxPublicHeight = nil, nil
        local result = e.lib.ButtonGlow_Start(r, { 1, 1, 0, 1 }, .25, 16)
        check(result == false and not r[glowKey] and created == 0,
            "first denied geometry defers without fabricating a size or allocating a glow")
        r.GetSize = function() return opaque, opaque end
        result = e.lib.ButtonGlow_Start(r, { 1, 1, 0, 1 }, .25, 16)
        check(result == false and not r[glowKey] and created == 0,
            "first private geometry is never used in Lua arithmetic")
        r._fluxPublicWidth, r._fluxPublicHeight = 36, 36
        e.lib.ButtonGlow_Start(r, { 1, 1, 0, 1 }, .25, 16)
        local prepared = r[glowKey]
        check(prepared and prepared._fluxGlowWidth == 36 * 1.4, "public owned geometry completes the deferred glow")
        r._fluxPublicWidth, r._fluxPublicHeight = nil, nil
        e.lib.ButtonGlow_Start(r, { 1, 0, 0, 1 }, .25, 16)
        check(r[glowKey] == prepared and prepared.color[2] == 0 and prepared._fluxOwnerWidth == 36,
            "later private geometry retains known size while recoloring the same glow")
        r._fluxPublicWidth, r._fluxPublicHeight = 36, 36
        e.lib.ButtonGlow_Stop(r)
    end
    local function snap()
        local f = r[glowKey]; local state = { present = f ~= nil }
        if f then
            if f.scripts.OnUpdate then f.scripts.OnUpdate(f, .05) end
            state.frameAlpha = f.alpha
            state.throttle = f.throttle; state.color = f.color or false
            state.inPlaying, state.outPlaying = f.animIn.playing, f.animOut.playing
            for _, key in ipairs(textures) do state[key] = { alpha = f[key].alpha, color = f[key].color, desaturated = f[key].desaturated, coords = f[key].coords } end
            for _, group in ipairs({ "animIn", "animOut" }) do
                state[group] = {}
                for i, a in ipairs(f[group].animations) do
                    local declared = {}; for key, value in pairs(a) do if type(value) ~= "function" then declared[key] = value end end
                    state[group][i] = declared
                end
            end
        end
        snapshots[#snapshots + 1] = state
    end
    local colors = { false, { 1, 1, 0, .4 }, { 1, 0, 0, 1 }, { 0, 1, 0, 0 }, { 0, 0, 1, .75 } }
    for cycle = 1, 10 do
        e.lib.ButtonGlow_Start(r, colors[(cycle - 1) % #colors + 1] or nil, .25, 16); snap()
        r[glowKey].animIn:Finish(); snap()
        e.lib.ButtonGlow_Start(r, colors[cycle % #colors + 1] or nil, .5, 16); snap()
        e.lib.ButtonGlow_Stop(r); snap() -- fade-out path after finished appear
        e.lib.ButtonGlow_Start(r, nil, .25, 16); snap() -- restart while fading out
        r[glowKey].animIn:Finish(); e.lib.ButtonGlow_Stop(r); r[glowKey].animOut:Finish(); snap()
        e.lib.ButtonGlow_Start(r, colors[2], .25, 16); snap() -- pooled re-acquire
        e.lib.ButtonGlow_Stop(r); snap() -- stop/release during animIn
    end
    local reads = 0; for _, t in ipairs(allTextures) do reads = reads + t.reads end
    local ledgers, entries = 0, 0
    for _, f in ipairs(allFrames) do
        if f._lCGTextureAlpha then
            ledgers = ledgers + 1; for _ in pairs(f._lCGTextureAlpha) do entries = entries + 1 end
        end
    end
    if foreignVersion then
        check(sharedCalls == 0 and shared.ButtonGlow_Start == originalSharedStart, "private renderer does not call/replace winning shared minor" .. foreignVersion)
        local selected, minor = e.LibStub("LibCustomGlow-1.0", true)
        check(selected == shared and minor == 25, "real shared LibStub selection remains untouched")
        check(r._ButtonGlow == foreign and foreign.reads == 0 and foreign.writes == 0, "private pool never adopts foreign shared overlay")
    end
    return { states = snapshots, created = created, released = released }, reads, { tables = ledgers, entries = entries }
end
do
    local okB, b, baselineReads = pcall(glow, baseline, false)
    local okC, c, candidateReads, ledger = pcall(glow, candidate, false)
    check(okB and okC and stable(b) == stable(c), "glow public alpha/colors/animation declarations/stop/restart/pool parity " .. tostring(b) .. " / " .. tostring(c))
    check(okC and candidateReads == 0, "candidate glow never reads texture alpha")
    local old, err = pcall(glow, baseline, true); local new, got, reads = pcall(glow, candidate, true)
    check(not old and tostring(err):find("OPAQUE_ALPHA", 1, true), "ALPHA-06 baseline rejects private texture alpha")
    check(new and stable(got) == stable(c) and reads == 0, "ALPHA-06 candidate retains all owned phase state without getter")
    local denied, deniedState, deniedReads = pcall(glow, candidate, "call-denied")
    check(denied and stable(deniedState) == stable(c) and deniedReads == 0, "owned glow avoids getter-call denial by never reading")
    check(ledger and ledger.tables == 1 and ledger.entries == 6, "one six-entry alpha ledger remains owned by the one reused pool frame")
    for _, version in ipairs({ 20, 25 }) do
        local coexist, state, readCount = pcall(glow, candidate, true, version)
        check(coexist and stable(state) == stable(c) and readCount == 0, "private renderer coexists with winning shared version " .. version)
    end
    local geometryOK, geometryError = pcall(glow, candidate, true, nil, true)
    check(geometryOK, "private glow handles denied/private geometry and public completion " .. tostring(geometryError))
    if not old then rejected = rejected + 1 end
    print(("METRIC glow cycles=10 snapshots=80 baseline_public_reads=%s candidate_reads=%s frames_created=%s pool_releases=%s owned_ledger_tables=%s ledger_entries=%s")
        :format(tostring(baselineReads), tostring(candidateReads), tostring(okC and c.created), tostring(okC and c.released), tostring(ledger and ledger.tables), tostring(ledger and ledger.entries)))
end
local function ring(root, alpha, mode)
    local e = env(); local w = frame(alpha); w.opaque = mode == "private"; w.callDenied = mode == "denied"
    function w:GetTexture() return "Interface\\Buttons\\UI-Quickslot2" end
    local fn = compile(root, "ExtraButtonSystem/Engine/Style.lua", "local function NormalRingVisible(tex)", "local function HideOverlayRing(widget)", e, "return NormalRingVisible")
    return fn(w)
end
for _, alpha in ipairs({ 0, .005, .01, .4, .75, 1 }) do
    check(ring(baseline, alpha) == ring(candidate, alpha), "legacy ring public alpha parity " .. alpha)
end
local oldRing, oldRingError = pcall(ring, baseline, .75, "private")
check(not oldRing and tostring(oldRingError):find("OPAQUE_ALPHA", 1, true) and ring(candidate, .75, "private"), "legacy ring rejects old secret comparison and keeps public shown/texture policy")
if not oldRing then rejected = rejected + 1 end
check(ring(candidate, .75, "denied"), "legacy ring denied getter follows existing logical shown/texture policy")
print(("SUMMARY checks=%d failures=%d baseline_rejections=%d"):format(checks, failures, rejected))
os.exit(failures > 0 and 1 or 0)
