-- Real core/countdown replay: readable and opaque labels, native reuse and work counts.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local source, measure, mutation = "NamePlates/Countdown.lua", false
for i, value in ipairs(arg or {}) do
    if value == "--source" then source = assert(arg[i + 1]) end
    if value == "--measure" then measure = true end
    if value == "--mutation" then mutation = assert(arg[i + 1]) end
end
local body = read(source)
local mutations = {
    duplicate_lookup = { "fs = fs or (cooldown and GetBlizzardDigits(cooldown))", "fs = cooldown and GetBlizzardDigits(cooldown)" },
    stale_region = { "local function GetBlizzardDigits(cooldown)",
        "local cachedRegion\nlocal function GetBlizzardDigits(cooldown)\nif cachedRegion then return cachedRegion end" },
    secret_label = { "return txt", "return nil" },
    slow_poll = { "interval = 0.1", "interval = 0.2" },
    wrong_level = { "+ NP.FRAME_LEVEL_OFFSET", "+ 0" },
}
if mutation then
    local edit = assert(mutations[mutation], "unknown mutation")
    local at = assert(body:find(edit[1], 1, true), "mutation anchor missing")
    body = body:sub(1, at - 1) .. edit[2] .. body:sub(at + #edit[1])
    if mutation == "stale_region" then
        body = body:gsub("return fs", "cachedRegion = fs; return fs", 1)
    end
end
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function secret()
    return setmetatable({ opaque = true }, {
        __tostring = function() error("serialized secret") end,
        __lt = function() error("compared secret") end,
        __le = function() error("compared secret") end,
        __add = function() error("arithmetic on secret") end,
        __sub = function() error("arithmetic on secret") end,
    })
end
local function boot(branch)
    local s = { frames = {}, plates = {}, now = 200, fontReads = 0, regionReads = 0,
        levelReads = 0, labelWrites = 0, alphaWrites = 0, anchors = 0, errors = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    s.appearance = setmetatable({}, { __index = { auraCountdown = "bottom" } })
    s.ownedAuras, s.ownershipReads, s.itemWrites = {}, 0, 0
    env.FluxUI_DB = { nameplateAppearance = s.appearance }
    env.C_UnitAuras = {
        IsAuraFilteredOutByInstanceID = function(unit, id, filter)
            assert(unit == "nameplate1" and filter == "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY")
            s.ownershipReads = s.ownershipReads + 1
            if s.ownedAuras[id] == "restricted" then error("aura access unavailable") end
            return s.ownedAuras[id] ~= true
        end,
    }
    local client = { isRetail = branch == "live" or branch == "forever", isForever = branch == "forever",
        isCamelot = branch == "forever", isEra = branch == "era", majorVersion = branch == "live" and 12 or 1,
        isAnyClassic = branch ~= "live" and branch ~= "forever" }
    local ns = { Flux = { Client = client } }
    env.GetTime = function() return s.now end
    env.issecretvalue = function(v) return type(v) == "table" and rawget(v, "opaque") == true end
    env.geterrorhandler = function() return function(err) s.errors = s.errors + 1; error(err, 0) end end
    env.C_NamePlate = { GetNamePlateForUnit = function(unit) return s.plates[unit] end,
        GetNamePlates = function() local t = {}; for _, p in pairs(s.plates) do t[#t + 1] = p end; return t end }
    env.CreateFrame = function(_, _, parent)
        local f = { parent = parent, shown = true, scripts = {}, hooks = {}, events = {} }
        function f:SetScript(k, v) self.scripts[k] = v end
        function f:HookScript(k, v) self.hooks[k] = v end
        function f:RegisterEvent(k) self.events[k] = true end
        function f:SetSize(w, h) self.width, self.height = w, h end
        function f:EnableMouse(v) self.mouse = v end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:IsShown() return self.shown end
        function f:GetParent() return self.parent end
        function f:SetParent(p) if self.rejectParent then error("parent unavailable") end; self.parent = p end
        function f:ClearAllPoints() self.point = nil end
        function f:SetPoint(p, rel, rp, x, y)
            if self.rejectPoint then error("point unavailable") end
            self.point, self.relative, self.relativePoint, self.x, self.y = p, rel, rp, x, y
            s.anchors = s.anchors + 1
        end
        function f:SetFrameLevel(n) self.level = n end
        function f:CreateFontString()
            local t = {}
            function t:SetFont(font, size, flags) self.font, self.size, self.flags = font, size, flags end
            function t:SetPoint(...) end
            function t:SetJustifyH(v) self.justifyH = v end
            function t:SetJustifyV(v) self.justifyV = v end
            function t:SetTextColor(r, g, b, a) self.r, self.g, self.b, self.a = r, g, b, a end
            function t:SetText(v)
                if self.rejectText then error("label unavailable") end
                self.value = v; s.labelWrites = s.labelWrites + 1
            end
            return t
        end
        s.frames[#s.frames + 1] = f
        return f
    end
    local function native(fields)
        return setmetatable({}, { __index = fields,
            __newindex = function() error("wrote native frame field") end })
    end
    env.UIParent = native({})
    assert(load(read("NamePlates/Core.lua"), "@NamePlates/Core.lua", "t", env))("_FluxUI", ns)
    assert(load(body, "@countdown-source", "t", env))("_FluxUI", ns)
    s.np, s.driver, s.events = ns.Flux.NamePlates, s.frames[1], s.frames[2]
    function s:event(event, unit) self.events.scripts.OnEvent(self.events, event, unit) end
    function s:tick(elapsed)
        if not self.driver.shown then return end
        self.driver.scripts.OnUpdate(self.driver, elapsed)
        if self.driver.hooks.OnUpdate then self.driver.hooks.OnUpdate(self.driver, elapsed) end
    end
    function s:aura(legacy)
        local d = { shown = true, accessible = true, text = "8", start = 199, duration = 5, level = 14,
            alpha = 1, motion = true }
        local function digits()
            local data = { r = 1, g = 1, b = 1, alpha = 1 }
            local fs = native({ GetText = function() return d.text end,
                CanBeAccessedInContext = function() return not d.protectedDigits end,
                GetTextColor = function() return data.r, data.g, data.b, data.alpha end,
                SetTextColor = function(_, r, g, b, a)
                    if d.rejectAlpha or d.protectedDigits then error("digits unavailable") end
                    data.r, data.g, data.b, data.alpha = r, g, b, a
                    s.alphaWrites = s.alphaWrites + 1
                end, GetObjectType = function() return "FontString" end })
            return fs, data
        end
        d.digits, d.digitData = digits()
        d.replaceDigits = function() d.digits, d.digitData = digits() end
        local texture = native({ GetObjectType = function() return "Texture" end })
        local fields = { GetFrameLevel = function()
            s.levelReads = s.levelReads + 1
            if d.levelError then error("level unavailable") end
            return d.level
        end, CanBeAccessedInContext = function() return d.accessible end,
            GetCooldownTimes = function() return d.start, d.duration end,
            GetRegions = function() s.regionReads = s.regionReads + 1; return texture, d.digits end }
        if not legacy then fields.GetCountdownFontString = function() s.fontReads = s.fontReads + 1; return d.digits end end
        d.cooldown = native(fields)
        local item = { Cooldown = d.cooldown, IsShown = function() return d.shown end,
            CanBeAccessedInContext = function() return d.accessible end,
            GetFrameLevel = function() s.levelReads = s.levelReads + 1; return 11 end,
            GetAlpha = function() return d.alpha end,
            SetAlpha = function(_, alpha) d.alpha = alpha; s.itemWrites = s.itemWrites + 1 end,
            IsMouseMotionEnabled = function() return d.motion end,
            SetMouseMotionEnabled = function(_, motion) d.motion = motion; s.itemWrites = s.itemWrites + 1 end,
        }
        d.frame = setmetatable({}, {
            __index = function(_, key)
                if key == "auraInstanceID" then return d.id end
                return item[key]
            end,
            __newindex = function() error("wrote native frame field") end,
        })
        return d
    end
    function s:plate(unit, auras)
        local p = { level = 7 }
        local frame = native({ AurasFrame = auras, unit = unit })
        p.native = native({ UnitFrame = frame, unitToken = unit,
            GetFrameLevel = function() s.levelReads = s.levelReads + 1; return p.level end })
        self.plates[unit] = p.native
        return p
    end
    function s:host(aura)
        for _, f in ipairs(self.frames) do if f.relative == aura.cooldown then return f end end
    end
    function s:pool(items, indexed)
        local entries = {}; for i, a in ipairs(items) do entries[indexed and i or a.frame] = indexed and a.frame or true end
        return { EnumerateActive = function() return next, entries, nil end }
    end
    function s:list(items)
        local children = {}; for i, a in ipairs(items) do children[i] = a.frame end
        return native({ GetChildren = function() return table.unpack(children) end })
    end
    return s
end
for _, branch in ipairs({ "era", "anniversary", "progression", "live", "forever" }) do
    if not mutation then
        local f = boot(branch)
        local mine, other, otherCC, myCC, helpful, denied, unconfirmed = f:aura(), f:aura(), f:aura(), f:aura(),
            f:aura(), f:aura(), f:aura()
        mine.id, other.id, otherCC.id, myCC.id, helpful.id, denied.id = 101, 102, 103, 104, 105, 106
        unconfirmed.id = secret()
        f.ownedAuras[101], f.ownedAuras[104], f.ownedAuras[106] = true, true, "restricted"
        other.alpha = 0.65
        f:plate("nameplate1", { DebuffListFrame = f:list({ mine, other, denied, unconfirmed }),
            CrowdControlListFrame = f:list({ otherCC }), LossOfControlFrame = { AuraItemFrame = myCC.frame },
            BuffListFrame = f:list({ helpful }) })
        f:event("NAME_PLATE_UNIT_ADDED", "nameplate1")
        check(f.ownershipReads == 0 and other.alpha == 0.65 and otherCC.alpha == 1,
            branch .. " default leaves stock slots and costs alone")
        f.appearance.onlyMyDebuffs = true
        f.np.RefreshAll()
        check(mine.alpha == 1 and myCC.alpha == 1 and helpful.alpha == 1 and f.ownershipReads == 5,
            branch .. " keeps own debuff and CC, skips the helpful row and secret ID")
        check(other.alpha == 0 and otherCC.alpha == 0 and denied.alpha == 0 and unconfirmed.alpha == 0
            and not other.motion and not otherCC.motion and not f:host(other).shown,
            branch .. " mutes other and unconfirmed stock icons, tooltip motion and countdowns")
        local reads, writes = f.ownershipReads, f.itemWrites
        f:tick(0.1)
        check(f.ownershipReads == reads and f.itemWrites == writes,
            branch .. " stable filtered icons cause no more ownership queries or writes")
        other.motion = true
        f:tick(0.1)
        check(not other.motion and other.alpha == 0, branch .. " re-enabled pooled hover stays muted")
        other.id = 101
        f:tick(0.1)
        check(other.motion and other.alpha == 0.65 and f:host(other).shown,
            branch .. " replacing a pooled debuff with an owned one restores exact alpha and hover")
        other.id = 102
        f:tick(0.1)
        check(other.alpha == 0 and not other.motion, branch .. " pooled slot can be filtered again")
        f.appearance.onlyMyDebuffs = false
        f.np.RefreshAll()
        check(other.alpha == 0.65 and other.motion and otherCC.alpha == 1 and otherCC.motion
            and denied.alpha == 1 and unconfirmed.alpha == 1,
            branch .. " disabling restores every concealed stock item")
        f.appearance.onlyMyDebuffs = true
        f.np.RefreshAll()
        f:event("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        check(other.alpha == 0.65 and other.motion and otherCC.alpha == 1 and otherCC.motion,
            branch .. " plate release restores pooled alpha and motion")
    end
    local s = boot(branch)
    local a, b, c = s:aura(), s:aura(true), s:aura()
    c.text = secret()
    local p = s:plate("nameplate1", { auraItemFramePool = s:pool({ a }), DebuffListFrame = s:list({ b }),
        LossOfControlFrame = { AuraItemFrame = c.frame } })
    s:event("NAME_PLATE_UNIT_ADDED", "nameplate1")
    check(#s.frames == 5, branch .. " two core frames and three reusable hosts")
    check(s.driver.shown, branch .. " active driver wakes")
    local ah, bh, ch = s:host(a), s:host(b), s:host(c)
    check(ah.text.value == "8" and bh.text.value == "8" and ch and rawequal(ch.text.value, c.text), branch .. " native/legacy/opaque labels")
    check(ah.text.font == "Fonts\\FRIZQT__.TTF" and ah.text.size == 12 and ah.text.flags == "OUTLINE", branch .. " exact font")
    check(ah.width == 28 and ah.height == 18 and ah.mouse == false, branch .. " exact host size and input")
    check(ah.parent == p.native and ah.point == "CENTER" and ah.relative == a.cooldown and ah.x == 0 and ah.y == 0,
        branch .. " exact anchor")
    check(ah.level == 19 and a.digitData.alpha == 0, branch .. " level and native fade")
    local writes = s.labelWrites
    s:tick(0.099); check(s.labelWrites == writes, branch .. " no early poll")
    s:tick(0.0011); check(s.labelWrites == writes + 1 and ah.text.value == "8" and bh.text.value == "8",
        branch .. " original tenth-second poll forwards opaque text and reuses readable output")
    a.text = "7.9"; a.replaceDigits(); s:tick(0.1)
    check(ah.text.value == "7.9" and a.digitData.alpha == 0, branch .. " rereads replacement text region next poll")
    a.text = ""; s:tick(0.1); check(ah.text.value == "4.0", branch .. " readable-time fallback")
    a.duration = 25; s:tick(0.1); check(ah.text.value == "24", branch .. " whole seconds above ten")
    a.start, a.duration = 199000, 5000; s:tick(0.1); check(ah.text.value == "4.0", branch .. " millisecond fallback")
    for _, duration in ipairs({ 0, 61, secret() }) do
        a.start, a.duration = 199, duration; s:tick(0.1)
        check(not ah.shown and a.digitData.alpha == 1, branch .. " absent/long/opaque duration restores native digits")
    end
    a.duration, a.text, a.level = 5, "5", secret(); s:tick(0.1)
    check(ah.shown and ah.level == 16, branch .. " opaque level ignored")
    a.levelError = true; s:tick(0.1); check(ah.level == 16, branch .. " unavailable level ignored")
    a.levelError = false; a.level = 25; s:tick(0.1); check(ah.level == 30, branch .. " level change read immediately")
    a.accessible = false; s:tick(0.1); check(not ah.shown and a.digitData.alpha == 1, branch .. " inaccessible restores digits")
    a.accessible = true; a.shown = false; s:tick(0.1); check(not ah.shown, branch .. " hidden aura stays hidden")
    a.shown = true; s:tick(0.1); check(ah.shown, branch .. " reuses visible host")
    ah.rejectPoint = true; ah.parent = nil; s:tick(0.1); check(not ah.shown and a.digitData.alpha == 1, branch .. " failed placement restores digits")
    ah.rejectPoint = false; s:tick(0.1)
    local cycleFonts, cycleRegions, cycleLevels, cycleLabels, cycleAnchors = s.fontReads, s.regionReads,
        s.levelReads, s.labelWrites, s.anchors
    for _ = 1, 100 do
        a.shown, b.shown, c.shown = false, false, false
        s:event("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        check(not s.driver.shown and not ah.shown, branch .. " removal sleeps and hides")
        local before = s.labelWrites; s:tick(1); check(s.labelWrites == before, branch .. " inactive does no countdown work")
        a.shown, b.shown, c.shown = true, true, true
        s:event("NAME_PLATE_UNIT_ADDED", "nameplate1")
    end
    check(#s.frames == 5 and s.errors == 0, branch .. " no lifecycle growth/errors")
    print(("METRIC %s_lifecycle font_reads=%d region_reads=%d level_reads=%d label_writes=%d anchors=%d frames=%d")
        :format(branch, s.fontReads - cycleFonts, s.regionReads - cycleRegions, s.levelReads - cycleLevels,
            s.labelWrites - cycleLabels, s.anchors - cycleAnchors, #s.frames))
    s:plate("preview", { auraItemFramePool = s:pool({ s:aura() }) })
    s:event("NAME_PLATE_UNIT_ADDED", "preview"); check(#s.frames == 5, branch .. " preview has no host")
    if source == "NamePlates/Countdown.lua" and not mutation then
        check(ah.text.size == 12, branch .. " the published native countdown size is the default")
        s.appearance.countdownSize = 17
        s.np.RefreshUnit("nameplate1")
        check(ah.text.size == 17 and bh.text.size == 17 and #s.frames == 5,
            branch .. " resizing updates reused Flux labels without creating frames")
        s.appearance.countdownSize = 400
        s.np.RefreshUnit("nameplate1")
        check(ah.text.size == 24, branch .. " oversized saved countdown font is bounded")
        s.appearance.countdownSize = nil
        s.np.RefreshUnit("nameplate1")
        check(ah.text.size == 12, branch .. " resetting the font size restores 12 pixels")
        s.appearance.auraCountdown = "bottom"
        s.np.RefreshUnit("nameplate1")
        check(ah.shown and ah.point == "CENTER" and ah.relativePoint == "BOTTOM" and ah.y == 7,
            branch .. " the bottom setting moves the Flux text inside the native aura icon")
        s.appearance.auraCountdown = "below"
        s.np.RefreshUnit("nameplate1")
        check(ah.shown and ah.point == "TOP" and ah.relativePoint == "BOTTOM" and ah.y == -1,
            branch .. " the below setting moves countdowns outside the icon")
        s.appearance.auraCountdown = "middle"
        s.np.RefreshUnit("nameplate1")
        check(ah.shown and ah.point == "CENTER" and ah.relativePoint == "CENTER" and ah.y == 0,
            branch .. " the center setting returns to the Flux default anchor")
        s.appearance.auraCountdown = "none"
        s.np.RefreshUnit("nameplate1")
        check(not ah.shown and not ch.shown and a.digitData.alpha == 0,
            branch .. " Off hides both Flux text and available native countdown digits")
        a.rejectAlpha = true
        s:event("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        check(a.digitData.alpha == 0 and b.digitData.alpha == 1,
            branch .. " removal restores native digits that accept the change")
        a.rejectAlpha = false
        s:event("PLAYER_REGEN_ENABLED")
        check(a.digitData.alpha == 1, branch .. " regen retries restoration if native digits refused it during removal")
        s.appearance.auraCountdown = nil
        s:event("NAME_PLATE_UNIT_ADDED", "nameplate1")
        ch.text.rejectText = true
        s:tick(0.1)
        check(not ch.shown and c.digitData.alpha == 1,
            branch .. " a rejected opaque label leaves the native countdown visible")
        ch.text.rejectText = false
        s:tick(0.1)
        check(ch.shown and c.digitData.alpha == 0,
            branch .. " the original cadence recovers a countdown after its label accepts the write")

        local off = boot(branch)
        off.appearance.auraCountdown = "none"
        local colored = off:aura()
        colored.digitData.r, colored.digitData.g, colored.digitData.b, colored.digitData.alpha = 0.25, 0.5, 0.75, 0.6
        local protected = off:aura()
        protected.protectedDigits = true
        off:plate("nameplate1", { auraItemFramePool = off:pool({ colored, protected }) })
        off:event("NAME_PLATE_UNIT_ADDED", "nameplate1")
        check(colored.digitData.alpha == 0 and colored.digitData.r == 0.25 and colored.digitData.g == 0.5
            and colored.digitData.b == 0.75 and protected.digitData.alpha == 1 and #off.frames == 2,
            branch .. " Off retains native RGB, respects unreadable digits and skips overlay allocation")
        off:plate("nameplate2", { auraItemFramePool = off:pool({ colored }) })
        local previousWrites = off.alphaWrites
        off:event("NAME_PLATE_UNIT_ADDED", "nameplate2")
        check(colored.digitData.alpha == 0 and off.alphaWrites == previousWrites + 2,
            branch .. " pooled aura releases its old mute and leases its current owner")
        off:event("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        check(colored.digitData.alpha == 0, branch .. " old unit removal leaves the new unit's mute intact")
        local previousDigits = colored.digitData
        colored.replaceDigits()
        off.np.RefreshUnit("nameplate2")
        check(previousDigits.alpha == 0.6 and previousDigits.r == 0.25 and colored.digitData.alpha == 0,
            branch .. " replacing the digits restores the previous region's precise color and alpha")
        colored.digitData.r, colored.digitData.alpha = 0.4, 0.7
        off:event("NAME_PLATE_UNIT_REMOVED", "nameplate2")
        check(colored.digitData.r == 0.4 and colored.digitData.alpha == 0.7,
            branch .. " releasing the mute preserves later native formatting")
    end
    -- Independent steady scenario: warm all native/Flux widgets before stopping GC.
    for _, mode in ipairs({ "modern", "legacy" }) do
    local m = boot(branch); local items = {}; for i = 1, 100 do items[i] = m:aura(mode == "legacy") end
    m:plate("nameplate1", { auraItemFramePool = m:pool(items, true) })
    m:event("NAME_PLATE_UNIT_ADDED", "nameplate1")
    print(("METRIC %s_%s_startup font_reads=%d region_reads=%d level_reads=%d label_writes=%d anchors=%d frames=%d")
        :format(branch, mode, m.fontReads, m.regionReads, m.levelReads, m.labelWrites, m.anchors, #m.frames))
    for _ = 1, 20 do m:tick(0.1) end
    local fonts, regions, levels, labels, anchors = m.fontReads, m.regionReads, m.levelReads, m.labelWrites, m.anchors
    collectgarbage("collect"); collectgarbage("stop")
    local heap, began = collectgarbage("count"), os.clock()
    for _ = 1, 100 do m:tick(0.1) end
    local seconds, allocated = os.clock() - began, collectgarbage("count") - heap
    collectgarbage("restart")
    check((mode == "modern" and m.fontReads - fonts == 10000 and m.regionReads == regions)
        or (mode == "legacy" and m.regionReads - regions == 10000 and m.fontReads == fonts),
        branch .. " " .. mode .. " one font-region lookup per visible aura per poll")
    check(m.levelReads - levels == 30000 and m.labelWrites - labels == 0 and m.anchors - anchors == 0,
        branch .. " native levels retain cadence while stable owned output avoids writes")
    check(#m.frames == 102, branch .. " steady frame count bounded")
    if mode == "modern" then check(allocated < 16, branch .. " no per-aura temporary frame-level tables") end
    print(("METRIC %s_%s font_reads=%d region_reads=%d level_reads=%d label_writes=%d anchors=%d frames=%d heap_kib=%.6f cpu_seconds=%.6f")
        :format(branch, mode, m.fontReads - fonts, m.regionReads - regions, m.levelReads - levels, m.labelWrites - labels,
            m.anchors - anchors, #m.frames, allocated, seconds))
    end
end
print(("Nameplate countdown work: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
