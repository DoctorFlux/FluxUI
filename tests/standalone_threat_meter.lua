-- Production standalone pane with mocked frames, native threat and display APIs.
-- No Details objects exist in these fixtures. This is not a secure-VM/render test.
local checks = 0
local source = arg[1] or "Battlezonemap/FluxThreatMeter.lua"
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local opaque = setmetatable({}, { __add = function() error("opaque arithmetic") end,
    __sub = function() error("opaque arithmetic") end, __lt = function() error("opaque comparison") end,
    __le = function() error("opaque comparison") end, __concat = function() error("opaque concatenation") end,
    __tostring = function() error("opaque conversion") end })
local function boot(client)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local s = { frames = {}, textures = 0, fonts = 0, now = 0, combat = false, queries = 0,
        details = false, tab = "Meter", samples = {}, exists = { player = true, target = true },
        attack = { target = true }, group = 0, raid = false, identities = {}, names = {}, targets = {}, classes = {}, draws = 0,
        registrationCalls = 0 }
    local function nativeString(fs, fmt, ...)
        fs.format, fs.args = fmt, { ... }
        for i = 1, select("#", ...) do if select(i, ...) == opaque then fs.text = "opaque native display"; return end end
        fs.text = string.format(fmt, ...)
    end
    local function region()
        local r = {}
        local function noop() end
        r.SetPoint, r.ClearAllPoints, r.SetAllPoints, r.SetSize = noop, noop, noop, noop
        r.SetColorTexture, r.SetJustifyH, r.SetFont, r.SetShadowColor, r.SetShadowOffset = noop, noop, noop, noop, noop
        function r:SetTexture(value) self.texture = value end
        function r:SetTexCoord(...) self.coords = { ... } end
        function r:SetText(value) assert(value ~= opaque, "opaque text must use native display formatting"); self.text = value end
        function r:SetFormattedText(...) nativeString(self, ...) end
        function r:SetWidth(value) self.width = value end
        function r:SetTextColor(...) self.color = { ... } end
        return r
    end
    local function frame(kind, name, parent)
        local f = { kind = kind, name = name, parent = parent, shown = true, scripts = {}, events = {},
            width = 150, height = 150, scale = 1, anchors = {} }
        s.frames[#s.frames + 1] = f
        function f:IsShown() return self.shown end
        function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        local function visibility(value)
            local old = {}; for _, w in ipairs(s.frames) do old[w] = w:IsVisible() end
            f.shown = value
            for _, w in ipairs(s.frames) do
                local current = w:IsVisible()
                if old[w] ~= current then
                    local fn = w.scripts[current and "OnShow" or "OnHide"]
                    if fn then fn(w) end
                end
            end
        end
        function f:Show() visibility(true) end
        function f:Hide() visibility(false) end
        function f:SetScript(key, value) self.scripts[key] = value end
        function f:GetScript(key) return self.scripts[key] end
        function f:RegisterEvent(key) s.registrationCalls = s.registrationCalls + 1; self.events[key] = true end
        function f:RegisterUnitEvent(key, unit) s.registrationCalls = s.registrationCalls + 1; self.events[key] = unit end
        function f:UnregisterAllEvents() self.events = {} end
        function f:SetParent(value) self.parent = value end
        function f:GetParent() return self.parent end
        function f:SetScale(value) self.scale = value end
        function f:GetScale() return self.scale end
        function f:SetSize(w, h) self.width, self.height = w, h; if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self) end end
        function f:SetHeight(h) self.height = h end
        function f:GetHeight()
            if self.anchors.TOPLEFT and self.anchors.BOTTOMRIGHT then
                return self.parent.height + self.anchors.TOPLEFT[5] - self.anchors.BOTTOMRIGHT[5]
            end
            return self.height
        end
        function f:GetWidth()
            if self.anchors.TOPLEFT and self.anchors.BOTTOMRIGHT then
                return self.parent.width - self.anchors.TOPLEFT[4] + self.anchors.BOTTOMRIGHT[4]
            end
            return self.width
        end
        function f:SetPoint(...) local args = { ... }; self.anchors[args[1]] = args end
        function f:ClearAllPoints() self.anchors = {} end
        function f:CreateTexture() s.textures = s.textures + 1; return region() end
        function f:CreateFontString() s.fonts = s.fonts + 1; return region() end
        function f:SetValue(value) self.value = value end
        function f:SetStatusBarColor(...) self.color = { ... } end
        function f:SetAlpha(value) self.alpha = value end
        f.SetStatusBarTexture, f.SetMinMaxValues, f.SetClipsChildren, f.EnableMouseWheel = function() end, function() end, function() end, function() end
        return f
    end
    e.CreateFrame = frame
    e.C_Timer = setmetatable({}, { __index = function() error("standalone pane added a timer") end })
    e.GetTime = function() return s.now end
    e.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    e.unpack, e.UNKNOWN = table.unpack, "Unknown"
    e.UnitExists = function(unit) return s.exists[unit] or false end
    e.UnitAffectingCombat = function() return s.combat end
    e.InCombatLockdown = function() return s.combat == true end
    e.UnitIsUnit = function(unit) return s.identities[unit] or unit == "player" end
    e.UnitClass = function(unit) if s.classes[unit] == false then return end; return "Mage", s.classes[unit] or "MAGE" end
    e.GetUnitName = function(unit) return s.names[unit] or unit end
    e.IsInRaid = function() return s.raid end
    e.IsInGroup = function() return s.group > 0 end
    e.GetNumGroupMembers = function() return s.group end
    e.GetNumSubgroupMembers = function() return math.max(0, s.group - 1) end
    e.RAID_CLASS_COLORS = { MAGE = { r = .2, g = .6, b = 1 } }
    e.CLASS_ICON_TCOORDS = { MAGE = { 0, .25, 0, .25 } }
    e.FluxWindowFrame = { GetActiveTab = function() return s.tab end }
    e.FluxMeterLayout = { IsDetailsAddonLoaded = function() return s.details end }
    local ns = { Flux = { Client = { isForever = client ~= "retail" },
        Secrets = { IsSecretValue = function(value) return value == opaque end } } }
    ns.Flux.Threat = {
        UnitExists = function(unit) return s.exists[unit] == true end,
        UnitCanAttack = function(unit) return s.attack[unit] == true end,
        PlayerInCombat = function() return s.combat == true end,
        AccessibleNumber = function(value) if type(value) == "number" then return value end end,
        GetMeterRow = function(unit, target)
            s.queries = s.queries + 1; s.targets[target] = true; return s.samples[unit]
        end,
        SetBarValue = function(bar, value) s.draws = s.draws + 1; bar:SetValue(value) end,
        SetPercentText = function(fs, value) fs:SetFormattedText("%.0f%%", value) end,
    }
    assert(loadfile(source, "t", e))("_FluxUI", ns)
    s.meter, s.env = e.FluxThreatMeter, e
    s.host = frame("Frame")
    function s.tick(seconds)
        s.now = s.now + (seconds or 0)
        local frames = {}; for i, f in ipairs(s.frames) do frames[i] = f end
        for _, f in ipairs(frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f, seconds or 0) end end
    end
    function s.event(event, unit)
        for _, f in ipairs(s.frames) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, unit) end end
    end
    function s.visible()
        local result = {}
        for _, f in ipairs(s.frames) do if f.kind == "StatusBar" and f:IsVisible() then result[#result + 1] = f end end
        return result
    end
    function s.sample(unit, value, percent, tanking)
        s.exists[unit] = true
        s.samples[unit] = { threatVal = value, threatPct = percent, isTanking = tanking or false,
            secret = value == opaque or percent == opaque }
    end
    return s
end

local s = boot("forever")
check(s.env.Details == nil and s.env.DetailsFramework == nil and s.meter:IsAvailable(), "no Details dependency")
check(#s.frames == 1 and s.meter:GetFrame() == nil, "module allocates nothing before embed")
s.sample("player", 100, 10); s.sample("party1", 500, 50); s.sample("pet", 30, 3); s.sample("partypet1", 20, 2)
s.group = 2
local pane = s.meter:Embed(s.host, .8)
check(pane and pane:GetParent() == s.host and pane:GetScale() == .8, "owned pane uses host and explicit presentation scale")
check(s.queries == 0, "embed defers native scans")
for _ = 1, 500 do s.event("UNIT_THREAT_LIST_UPDATE", "target") end
s.tick(0)
check(s.queries == 4, "500 events coalesce to one group and pet scan")
local visible = s.visible()
check(#visible == 4 and visible[1].unit == "party1", "readable rows rank by actual threat")
check(visible[2].Name.color[2] == 1 and visible[2].Name.color[1] == 0, "local-player name stays green")
check(visible[1].Name.color[1] == 1 and visible[1].color[3] == 1, "other names white and bars class colored")
check(visible[1].height == 21 / .8, "threat rows compensate presentation scale")
for _, case in ipairs({ { 1000, "1000" }, { 1001, "1.0k" }, { 10000, "10.0k" }, { 10001, "10k" },
    { 1000000, "1000k" }, { 1000001, "1.0m" }, { 10000000, "10.0m" }, { 10000001, "10m" },
    { 1000000000, "1000m" }, { 1000000001, "1.0b" }, { 10000000000, "10.0b" }, { 10000000001, "10b" } }) do
    s.samples.party1.threatVal = case[1]; s.event("UNIT_THREAT_LIST_UPDATE", "target"); s.tick(0)
    check(s.visible()[1].Value.text == case[2] .. "||50%", "existing FluxThreat abbreviation boundary " .. case[2])
end
s.samples.party1.threatVal, s.samples.party1.threatPct = 500, 120
s.event("UNIT_THREAT_LIST_UPDATE", "target"); s.tick(0)
check(s.visible()[1].Value.text == "500||120%", "Forever readable percent above100 remains visible")
s.classes.party1 = false; s.event("UNIT_THREAT_LIST_UPDATE", "target"); s.tick(0)
check(s.visible()[1].Icon.texture == "Interface\\Icons\\Ability_Druid_Cower" and s.visible()[1].Icon.coords[1] == 0
    and s.visible()[1].Icon.coords[2] == 1, "recycled unknown-class icon resets its full texture coordinates")
s.classes.party1, s.samples.party1.threatPct = "MAGE", 50
s.event("UNIT_THREAT_LIST_UPDATE", "target"); s.tick(0)
local queries = s.queries; s.tick(10)
check(s.queries == queries and pane:GetScript("OnUpdate") == nil, "no idle polling")
local registrationCalls = s.registrationCalls
for _ = 1, 500 do s.meter:Show(); s.tick(0) end
check(s.registrationCalls == registrationCalls and s.queries == queries and pane:GetScript("OnUpdate") == nil,
    "500 repeated Show calls preserve event ownership and do not request more scans")
s.combat = true; s.event("PLAYER_REGEN_DISABLED"); s.tick(0)
queries = s.queries; s.tick(.19)
check(s.queries == queries, "combat polling waits 0.2 seconds")
s.tick(.011)
check(s.queries == queries + 4, "active visible combat polls once at its deadline")
local frames = #s.frames
for _ = 1, 500 do s.tick(.2) end
check(#s.frames == frames, "500 combat updates retain the same row pool")
s.meter:Hide(); queries = s.queries; s.event("PLAYER_TARGET_CHANGED"); s.tick(10)
check(s.queries == queries and next(pane.events) == nil and pane:GetScript("OnUpdate") == nil, "hide stops all owned work")
local hiddenFrames = #s.frames
for _ = 1, 500 do pane:SetSize(150, 8500); s.meter:RefreshLayout(); pane:SetSize(150, 150) end
check(#s.frames == hiddenFrames and s.queries == queries and pane:GetScript("OnUpdate") == nil,
    "hidden resize and layout bursts allocate no rows and do no scans")
s.meter:Show(); s.tick(0); check(s.queries == queries + 4, "show restores current facts")
s.host:Hide(); queries = s.queries; s.tick(10)
check(s.queries == queries and next(pane.events) == nil, "ancestor hide stops events and polling")
s.host:Show(); s.tick(0); check(s.queries == queries + 4, "ancestor reveal resumes once")
s.tab = "Map"; s.tick(.2); queries = s.queries; s.tick(1)
check(s.queries == queries and pane:GetScript("OnUpdate") == nil, "inactive tab stops scans")
s.tab = "Meter"; s.meter:Show(); s.tick(0)
s.details = true; s.event("ADDON_LOADED", "Details"); queries = s.queries; s.tick(10)
check(not pane:IsShown() and not s.meter:IsAvailable() and s.queries == queries and next(pane.events) == nil,
    "Details takeover retires the standalone pane")

local opaqueState = boot("forever")
opaqueState.sample("player", opaque, opaque); opaqueState.sample("party1", 800, 80); opaqueState.group = 2
opaqueState.names.player = opaque; opaqueState.identities.party1 = opaque
local op = opaqueState.meter:Embed(opaqueState.host)
opaqueState.tick(0)
visible = opaqueState.visible()
check(#visible == 2 and visible[1].unit == "player", "opaque cohort keeps roster order")
check(visible[1].Name.args[1] == "" and visible[1].Name.args[2] == opaque, "opaque name uses native formatting without a false rank")
check(visible[1].Value.args[1] == opaque and visible[1].Value.args[2] == opaque and visible[1].value == opaque,
    "opaque amount percent and fill pass directly to display methods")
check(visible[2].Name.color[1] == 1, "opaque identity does not pretend to be the player")
opaqueState.combat = opaque; opaqueState.event("PLAYER_REGEN_DISABLED"); opaqueState.tick(0)
check(op:GetScript("OnUpdate") == nil, "opaque combat observation is handled by the shared adapter")
local opaqueQueries = opaqueState.queries
opaqueState.event("UNIT_THREAT_LIST_UPDATE", opaque); opaqueState.tick(0)
check(opaqueState.queries == opaqueQueries + 2, "opaque event identity coalesces a refresh without comparing it")
opaqueState.attack.target = false; opaqueState.exists.targettarget = true; opaqueState.attack.targettarget = true
opaqueState.event("PLAYER_TARGET_CHANGED"); opaqueState.tick(0)
check(opaqueState.targets.targettarget, "friendly target uses hostile targettarget")

local raid = boot("forever"); raid.raid, raid.group = true, 40
for i = 1, 40 do raid.sample("raid" .. i, 10000 - i, 100 - i); raid.sample("raidpet" .. i, 1000 - i, 10) end
raid.identities.raid1 = true
local rp = raid.meter:Embed(raid.host)
rp:SetSize(150, 85); raid.tick(0)
check(raid.queries == 80 and #raid.visible() == 3, "full 40-player and pet facts with only viewport rows allocated")
raid.meter:Hide(); local hiddenAllocation = #raid.frames; local hiddenQueries = raid.queries
rp:SetSize(150, 8500); raid.meter:RefreshLayout(); raid.tick(10)
check(#raid.frames == hiddenAllocation and raid.queries == hiddenQueries, "hidden full-roster resize creates no unused row pool")
rp:SetSize(150, 85); raid.meter:Show(); raid.tick(0)
rp.scripts.OnMouseWheel(rp, -1000)
visible = raid.visible(); local foundLast, pinned = false, false
for _, row in ipairs(visible) do foundLast = foundLast or row.unit == "raidpet40"; pinned = pinned or (row.unit == "raid1" and row.alpha == .5) end
check(foundLast and pinned, "last fact remains scrollable beside the pinned player")
raid.identities.raid1, raid.identities.raid40 = nil, true
raid.samples.raid40.threatVal = 1
raid.event("GROUP_ROSTER_UPDATE"); raid.tick(0); rp.scripts.OnMouseWheel(rp, -1000)
visible = raid.visible()
check(#visible == 3 and visible[3].unit == "raid40" and visible[3].alpha == 1,
    "player in the last page keeps a full page without reserving another pin row")
raid.identities.raid1, raid.identities.raid40 = true, nil
raid.samples.raid40.threatVal = 10000 - 40
raid.event("GROUP_ROSTER_UPDATE"); raid.tick(0)
rp:SetSize(150, 43); rp.scripts.OnMouseWheel(rp, -1000)
visible = raid.visible()
check(#visible == 1 and visible[1].unit == "raidpet40", "one-row viewport scrolls every fact without player pin replacing it")
rp:SetSize(150, 8500)
check(#raid.visible() == 80 and #raid.frames == 83, "oversized viewport creates no more rows than real group facts")
local allocation = #raid.frames
for _ = 1, 500 do rp:SetSize(150, 85); rp:SetSize(150, 8500) end
check(#raid.frames == allocation, "resize cycles reuse the existing bounded pool")
raid.meter:Cleanup(); queries = raid.queries; raid.tick(20)
check(raid.queries == queries and next(rp.events) == nil and #raid.visible() == 0, "cleanup stops work and clears visible rows")
local retail = boot("retail")
check(not retail.meter:IsAvailable() and retail.meter:Embed(retail.host) == nil and #retail.frames == 1,
    "Forever feature remains absent on other clients")
print(string.format("standalone threat meter: %d checks passed; 500-event scans=1; raid facts=80; retained rows=%d", checks, allocation - 3))
