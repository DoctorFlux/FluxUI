-- Production standalone pane with mocked frames, native threat and display APIs.
-- No Details objects exist in these fixtures. This is not a secure-VM/render test.
local checks = 0
local source = arg[1] or "Battlezonemap/FluxThreatMeter.lua"
local skinSource = arg[2] or "Battlezonemap/FluxMeterSkin.lua"
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local opaque = setmetatable({}, { __add = function() error("opaque arithmetic") end,
    __sub = function() error("opaque arithmetic") end, __lt = function() error("opaque comparison") end,
    __le = function() error("opaque comparison") end, __concat = function() error("opaque concatenation") end,
    __tostring = function() error("opaque conversion") end })
local function boot(client, withSkin)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local s = { frames = {}, textures = 0, fonts = 0, now = 0, combat = false, queries = 0,
        details = false, tab = "Meter", samples = {}, exists = { player = true, target = true },
        attack = { target = true }, group = 0, raid = false, identities = {}, names = {}, targets = {}, classes = {}, draws = 0,
        registrationCalls = 0, fontSets = 0, fontErrors = 0 }
    local function nativeString(fs, fmt, ...)
        fs.format, fs.args = fmt, { ... }
        for i = 1, select("#", ...) do if select(i, ...) == opaque then fs.text = "opaque native display"; return end end
        fs.text = string.format(fmt, ...)
    end
    local function region()
        local r = { wordWrap = true, nonSpaceWrap = true }
        local function noop() end
        r.ClearAllPoints, r.SetAllPoints, r.SetSize = noop, noop, noop
        function r:SetPoint(...) self.point = { ... } end
        function r:SetJustifyH(value) self.justifyH = value end
        function r:GetJustifyH() return self.justifyH or "CENTER" end
        r.SetShadowColor, r.SetShadowOffset = noop, noop
        function r:SetColorTexture(...) self.fill = { ... } end
        function r:CanWordWrap() return self.wordWrap end
        function r:CanNonSpaceWrap() return self.nonSpaceWrap end
        function r:SetWordWrap(value) self.wordWrap = value end
        function r:SetNonSpaceWrap(value) self.nonSpaceWrap = value end
        r.GetText, r.GetStringHeight = function() error("text inspection is not presentation") end,
            function() error("text measurement is not presentation") end
        function r:GetStringWidth()
            assert(self.publicHeading, "actor/timer text measurement is forbidden")
            return 42 * self.font[2] / 12
        end
        function r:SetFont(path, size, flags)
            s.fontSets = s.fontSets + 1; self.fontSets = (self.fontSets or 0) + 1
            if s.rejectArial and (path == "Fonts\\ARIALN.TTF" or path:find("Accidental", 1, true)) then return false end
            assert(type(path) == "string" and type(size) == "number" and size > 0, "valid font required")
            self.font = { path, size, flags }; return true
        end
        function r:GetFont() return table.unpack(self.font or {}) end
        local function requireFont(self, method)
            if not self.font then
                s.fontErrors = s.fontErrors + 1
                error("FontString:" .. method .. "(): Font not set", 2)
            end
        end
        function r:SetHeight(value) self.height = value end
        function r:SetVertexColor(...) self.vertex = { ... }; if select("#", ...) == 4 then self.alpha = self.vertex[4] end end
        function r:SetAlpha(value) self.alpha = value; if self.vertex then self.vertex[4] = value end end
        function r:Show() self.shown = true end
        function r:Hide() self.shown = false end
        function r:SetTexture(value) self.texture = value; return true end
        function r:SetTexCoord(...) self.coords = { ... } end
        function r:SetText(value)
            requireFont(self, "SetText"); assert(value ~= opaque, "opaque text must use native display formatting")
            self.text = value; self.textWrites = (self.textWrites or 0) + 1
        end
        function r:SetFormattedText(...) requireFont(self, "SetFormattedText"); nativeString(self, ...) end
        function r:SetWidth(value) self.width = value end
        function r:SetTextColor(...) self.color = { ... } end
        return r
    end
    local function frame(kind, name, parent)
        local f = { kind = kind, name = name, parent = parent, shown = true, scripts = {}, events = {},
            width = 150, height = 150, scale = 1, anchors = {}, hooks = {} }
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
                    for _,hook in ipairs(w.hooks[current and "OnShow" or "OnHide"] or {}) do hook(w) end
                end
            end
        end
        function f:Show() visibility(true) end
        function f:Hide() visibility(false) end
        function f:SetScript(key, value) self.scripts[key] = value end
        function f:GetScript(key) return self.scripts[key] end
        function f:HookScript(key, fn) self.hooks[key] = self.hooks[key] or {}; table.insert(self.hooks[key],fn) end
        function f:RegisterEvent(key) s.registrationCalls = s.registrationCalls + 1; self.events[key] = true end
        function f:RegisterUnitEvent(key, unit) s.registrationCalls = s.registrationCalls + 1; self.events[key] = unit end
        function f:UnregisterAllEvents() self.events = {} end
        function f:SetParent(value) self.parent = value end
        function f:GetParent() return self.parent end
        function f:SetScale(value) self.scale = value end
        function f:GetScale() return self.scale end
        function f:SetSize(w, h)
            self.width, self.height = w, h
            if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self) end
            for _,hook in ipairs(self.hooks.OnSizeChanged or {}) do hook(self) end
        end
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
        function f:CreateFontString()
            s.fonts = s.fonts + 1; local fs = region()
            self.fontStrings = self.fontStrings or {}; self.fontStrings[#self.fontStrings + 1] = fs
            if self.name == "FluxStandaloneThreatMeter" and #self.fontStrings == 1 then fs.publicHeading = true end
            return fs
        end
        function f:SetValue(value) self.value = value end
        function f:SetStatusBarColor(...) self.color = { ... } end
        function f:SetAlpha(value) self.alpha = value end
        f.SetStatusBarTexture, f.SetMinMaxValues, f.SetClipsChildren, f.EnableMouseWheel = function() end, function() end, function() end, function() end
        return f
    end
    e.issecretvalue = function(value) return value == opaque end
    e.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
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
    if withSkin then assert(loadfile(skinSource, "t", e))() end
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
s.group = 2; s.combat = true
s.names.party1 = "Mario Super"
local pane = s.meter:Embed(s.host, .8)
check(pane and pane:GetParent() == s.host and pane:GetScale() == .8, "owned pane uses host and explicit presentation scale")
check(pane.Title.font and pane.Title.font[2] == 12 / .8 and pane.Title.text == "Threat" and s.fontErrors == 0,
    "first title text has its presentation font before native SetText")
check(pane.Title.point[1] == "BOTTOMLEFT" and pane.Title.point[5] == -13 / .8
    and pane.Body.anchors.TOPLEFT[5] == -14 / .8,
    "owned title and body follow the current compact header anchors")
check(s.queries == 0, "embed defers native scans")
for _ = 1, 500 do s.event("UNIT_THREAT_LIST_UPDATE", "target") end
s.tick(0)
check(s.queries == 4, "500 events coalesce to one group and pet scan")
local visible = s.visible()
check(#visible == 4 and visible[1].unit == "party1", "readable rows rank by actual threat")
check(visible[1].Name.font and visible[1].Value.font and visible[1].Name.font[2] == 14 / .8
    and visible[1].Value.font[2] == 14 / .8 and s.fontErrors == 0, "all initial row text is font-initialized")
check(visible[2].Name.color[2] == 1 and visible[2].Name.color[1] == 0, "local-player name stays green")
check(visible[1].Name.color[1] == 1 and visible[1].color[3] == 1, "other names white and bars class colored")
check(visible[1].height == 21 / .8, "threat rows compensate presentation scale")
check(visible[1].Name.text == "1. Mario Super" and not visible[1].Name.wordWrap and not visible[1].Name.nonSpaceWrap,
    "multiword threat names retain one line without rewriting or measuring their text")
check(visible[1].Background.fill[1] == .619607 and visible[1].Background.fill[4] == .116164,
    "owned threat rows match the common FluxDetails background fill")
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
local queries = s.queries
s.combat = false; s.event("PLAYER_REGEN_ENABLED"); s.tick(10)
check(s.queries == queries and pane:GetScript("OnUpdate") == nil and #s.visible() == 0,
    "combat end clears rows and stops polling without an out-of-combat scan")
local registrationCalls = s.registrationCalls
for _ = 1, 500 do s.meter:Show(); s.tick(0) end
check(s.registrationCalls == registrationCalls and s.queries == queries and pane:GetScript("OnUpdate") == nil,
    "500 repeated Show calls preserve event ownership and do not request more scans")
s.combat = true; s.event("PLAYER_REGEN_DISABLED"); s.tick(0)
check(#s.visible() == 4, "new combat repopulates the cleared pane")
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

local opaqueState = boot("forever"); opaqueState.combat = true
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
opaqueState.combat = true
local opaqueQueries = opaqueState.queries
opaqueState.event("UNIT_THREAT_LIST_UPDATE", opaque); opaqueState.tick(0)
check(opaqueState.queries == opaqueQueries + 2, "opaque event identity coalesces a refresh without comparing it")
opaqueState.attack.target = false; opaqueState.exists.targettarget = true; opaqueState.attack.targettarget = true
opaqueState.event("PLAYER_TARGET_CHANGED"); opaqueState.tick(0)
check(opaqueState.targets.targettarget, "friendly target uses hostile targettarget")

local raid = boot("forever"); raid.raid, raid.group, raid.combat = true, 40, true
for i = 1, 40 do raid.sample("raid" .. i, 10000 - i, 100 - i); raid.sample("raidpet" .. i, 1000 - i, 10) end
raid.identities.raid1 = true
local rp = raid.meter:Embed(raid.host)
rp:SetSize(150, 92); raid.tick(0)
check(raid.queries == 80 and #raid.visible() == 3, "full 40-player and pet facts with only viewport rows allocated")
raid.meter:Hide(); local hiddenAllocation = #raid.frames; local hiddenQueries = raid.queries
rp:SetSize(150, 8500); raid.meter:RefreshLayout(); raid.tick(10)
check(#raid.frames == hiddenAllocation and raid.queries == hiddenQueries, "hidden full-roster resize creates no unused row pool")
rp:SetSize(150, 92); raid.meter:Show(); raid.tick(0)
rp.scripts.OnMouseWheel(rp, -1000)
visible = raid.visible(); local foundLast, pinned = false, false
for _, row in ipairs(visible) do foundLast = foundLast or row.unit == "raidpet40"; pinned = pinned or (row.unit == "raid1" and row.alpha == .5) end
check(foundLast and pinned, "last fact remains scrollable beside the pinned player")
raid.identities.raid1, raid.identities.raid40 = nil, true
raid.samples.raid40.threatVal, raid.samples.raid40.threatPct = 1, 0
raid.event("GROUP_ROSTER_UPDATE"); raid.tick(0); rp.scripts.OnMouseWheel(rp, -1000)
visible = raid.visible()
check(#visible == 3 and visible[3].unit == "raid40" and visible[3].alpha == 1,
    "player in the last page keeps a full page without reserving another pin row")
raid.identities.raid1, raid.identities.raid40 = true, nil
raid.samples.raid40.threatVal, raid.samples.raid40.threatPct = 10000 - 40, 100 - 40
raid.event("GROUP_ROSTER_UPDATE"); raid.tick(0)
rp:SetSize(150, 49); rp.scripts.OnMouseWheel(rp, -1000)
visible = raid.visible()
check(#visible == 1 and visible[1].unit == "raidpet40", "one-row viewport scrolls every fact without player pin replacing it")
rp:SetSize(150, 8500)
check(#raid.visible() == 80 and #raid.frames == 83, "oversized viewport creates no more rows than real group facts")
local allocation = #raid.frames
for _ = 1, 500 do rp:SetSize(150, 92); rp:SetSize(150, 8500) end
check(#raid.frames == allocation, "resize cycles reuse the existing bounded pool")
queries = raid.queries; raid.combat = false; raid.event("PLAYER_REGEN_ENABLED")
check(#raid.visible() == 0 and raid.queries == queries and rp:GetScript("OnUpdate") == nil and rp:IsShown(),
    "all80 lingering raid facts clear at combat end while the header stays visible")
for _ = 1, 500 do raid.event("UNIT_THREAT_LIST_UPDATE", "target"); raid.event("GROUP_ROSTER_UPDATE"); raid.tick(.2) end
check(raid.queries == queries and #raid.visible() == 0 and rp:GetScript("OnUpdate") == nil,
    "out-of-combat events do not query or repaint lingering native facts")
raid.combat = true; raid.event("PLAYER_REGEN_DISABLED"); raid.tick(0)
check(#raid.visible() == 80 and raid.queries == queries + 80, "combat restart refreshes all80 facts from the adapter")
raid.meter:Cleanup(); queries = raid.queries; raid.tick(20)
check(raid.queries == queries and next(rp.events) == nil and #raid.visible() == 0, "cleanup stops work and clears visible rows")
local retail = boot("retail")
check(not retail.meter:IsAvailable() and retail.meter:Embed(retail.host) == nil and #retail.frames == 1,
    "Forever feature remains absent on other clients")
-- Readable Forever percentages determine the same ordering as the Details plugin.
local ordering = boot("forever"); ordering.combat, ordering.group = true, 2
ordering.sample("player", 200, 50); ordering.sample("party1", 100, 80)
ordering.meter:Embed(ordering.host); ordering.tick(0)
check(ordering.visible()[1].unit == "party1" and ordering.visible()[2].unit == "player",
    "readable percentage wins over a divergent absolute threat amount")

-- Compose the real shared skin and pane with preferred and fallback fonts.
local preferred = boot("forever", true); preferred.sample("player", 100, 10)
local preferredPane = preferred.meter:Embed(preferred.host); preferred.tick(0)
check(preferredPane.Title.font and preferred.queries == 0 and #preferred.visible() == 0
    and preferredPane:GetScript("OnUpdate") == nil, "quiet real-skin startup initializes only the pane header")
preferred.combat = true; preferred.event("PLAYER_REGEN_DISABLED"); preferred.tick(0)
check(preferredPane.Title.font[1] == "Fonts\\FRIZQT__.TTF" and preferred.visible()[1].Name.font[1] == "Interface\\AddOns\\Details\\fonts\\Accidental Presidency.ttf"
    and preferred.fontErrors == 0, "real skin matches FluxDetails stock title font and installed Details row font")
local titleFontSets = preferredPane.Title.fontSets
for _ = 1, 500 do
    preferred.meter:Hide(); preferred.meter:Show(); preferred.meter:RefreshLayout(); preferred.tick(0)
end
check(preferredPane.Title.fontSets == titleFontSets,
    "500 real-skin reveals and layouts do not swap title and row fonts")
local styled = boot("forever", true); styled.rejectArial, styled.combat = true, true
styled.sample("player", 100, 10)
local sp = styled.meter:Embed(styled.host, .8); styled.tick(0)
check(sp.Title.font[1] == styled.env.STANDARD_TEXT_FONT and sp.Title.text == "Threat" and styled.fontErrors == 0,
    "real skin supplies a fallback font before the first title text")
local styledRow = styled.visible()[1]
check(styledRow.Name.font[1] == styled.env.STANDARD_TEXT_FONT and styledRow.Value.font[1] == styled.env.STANDARD_TEXT_FONT
    and styledRow.Name.font[2] == 14 / .8 and styled.fontErrors == 0, "real skin fallback covers both row FontStrings")
styled.meter:Embed(styled.host, 1); styled.tick(0)
styledRow = styled.visible()[1]
check(sp.Title.font[2] == 12 and styledRow.Name.font[2] == 14 and styledRow.Value.font[2] == 14,
    "re-embed changes title and row fonts with the presentation scale")
check(sp.Title.point[5] == -13 and sp.Body.anchors.TOPLEFT[5] == -14,
    "header and body retain the same visible separation after a scale change")
local styledFrames = #styled.frames
for _ = 1, 500 do styled.meter:Hide(); styled.meter:Show(); styled.tick(0) end
check(#styled.frames == styledFrames and styled.fontErrors == 0, "500 composed reveals reuse initialized fonts and rows")
styled.sample("player", opaque, opaque); styled.names.player = opaque
styled.event("PLAYER_TARGET_CHANGED"); styled.tick(0); styledRow = styled.visible()[1]
check(styledRow.Value.args[1] == opaque and styledRow.Name.args[2] == opaque and styled.fontErrors == 0,
    "composed initialized fonts preserve opaque native text formatting")
-- Compare row geometry with the actual existing Details plugin, without
-- loading Details or its data/paint path into this desktop fixture.
local pluginFile = assert(io.open("Battlezonemap/FluxThreat.lua", "r"))
local pluginSource = pluginFile:read("*a"); pluginFile:close()
local rowStart = assert(pluginSource:find("function Threat:RefreshRow(row)", 1, true))
local rowEnd = assert(pluginSource:find("\n    function Threat:RefreshRows()", rowStart, true))
local reference = {
    ThreatFrame = {},
    SharedMedia = { Fetch = function() return "reference-font" end },
    applyTexturesFromRowInfo = function() end,
}
reference.Threat = { GetPluginInstance = function()
    return { baseframe = { GetWidth = function() return 150 end },
        row_info = { height = 21, font_size = 14, font_face = "reference-font", textL_outline = true } }
end }
assert(load(pluginSource:sub(rowStart, rowEnd - 1), "@Details threat row geometry", "t", reference))()
local geometry = boot("forever", true); geometry.combat, geometry.group = true, 2
geometry.sample("player", 100, 100); geometry.sample("party1", 50, 50)
local geometryPane = geometry.meter:Embed(geometry.host, .8); geometry.tick(0)
local geometryRows = geometry.visible()
for i = 1, 2 do
    local expected = { rowId = i, points = {} }
    function expected:ClearAllPoints() self.points = {} end
    function expected:SetPoint(point, _, _, x, y) self.points[point] = {x, y} end
    reference.Threat:RefreshRow(expected)
    local actual = geometryRows[i]
    check(actual.height * .8 == expected.height
        and actual.anchors.TOPLEFT[4] * .8 == expected.points.topleft[1]
        and actual.anchors.TOPLEFT[5] * .8 == expected.points.topleft[2]
        and actual.anchors.TOPRIGHT[4] * .8 == expected.points.topright[1],
        "standalone row matches the existing Details plugin height, pitch and side insets " .. i)
end
check(geometryPane.Body.anchors.TOPLEFT[4] == 0
    and geometryPane.Body.anchors.BOTTOMRIGHT[4] == 0
    and geometryPane.Body.anchors.BOTTOMRIGHT[5] == 0,
    "standalone viewport uses the complete reference body area")

local elapsed = boot("forever",true); elapsed.sample("player",100,100)
local ep = elapsed.meter:Embed(elapsed.host,1)
local clock = ep.fontStrings and ep.fontStrings[2]
check(clock and clock.font and clock.text == "" and elapsed.queries == 0,
    "Threat-only clock is font-ready and quiet before combat")
check(ep.Title:GetJustifyH() == "LEFT" and ep.Title.point[4] == 5 and ep.Title.point[5] == -13
    and ep.Title.width == 42, "Threat's public heading is measured without moving or centering its visible name")
check(clock.point[1] == "BOTTOMLEFT" and clock.point[2] == ep.Title and clock.point[3] == "BOTTOMRIGHT"
    and clock.point[4] == 5 and clock.point[5] == 0 and clock.justifyH == "LEFT" and clock.width == 93,
    "Threat clock follows the heading immediately and receives the remaining width for full native time text")
elapsed.now, elapsed.combat = 10, true; elapsed.event("PLAYER_REGEN_DISABLED"); elapsed.tick(0)
check(clock.text == "[0:00] " and elapsed.queries == 1, "observed combat starts the fallback without a second threat scan")
local clockWrites, clockQueries = clock.textWrites, elapsed.queries
for _=1,500 do elapsed.tick(.001) end
check(clock.textWrites == clockWrites and elapsed.queries <= clockQueries + 3,
    "sub-second clock updates neither repaint unchanged seconds nor add threat scans")
elapsed.tick(.75)
check(clock.text == "[0:01] ", "fallback displays elapsed player-combat seconds through the existing driver")
elapsed.event("PLAYER_TARGET_CHANGED"); elapsed.tick(0)
check(clock.text == "[0:01] ", "changing targets does not restart the current fight clock")
clockQueries = elapsed.queries; elapsed.combat = false; elapsed.event("PLAYER_REGEN_ENABLED")
check(clock.text == "" and ep:GetScript("OnUpdate") == nil and elapsed.queries == clockQueries,
    "combat exit clears the clock and stops updates without scanning")
elapsed.tick(20)
check(clock.text == "" and elapsed.queries == clockQueries, "out-of-combat time does not leave a hidden clock running")
elapsed.combat = true; elapsed.event("PLAYER_REGEN_DISABLED"); elapsed.tick(0)
check(clock.text == "[0:00] ", "a later fight starts at zero rather than retaining the previous elapsed time")
elapsed.tick(2.1)
check(clock.text == "[0:02] ", "second-fight elapsed time belongs to its own observed interval")
elapsed.meter:Hide(); clockQueries = elapsed.queries; elapsed.tick(20)
check(clock.text == "" and next(ep.events) == nil and ep:GetScript("OnUpdate") == nil and elapsed.queries == clockQueries,
    "hidden Threat stops clock/events/data work and clears its observed-interval fallback")
elapsed.meter:Show(); elapsed.tick(0)
check(clock.text == "[0:00] ", "revealing during combat starts a new observed interval rather than inventing its unseen start")
elapsed.meter:Cleanup(); clockQueries = elapsed.queries; elapsed.tick(20)
check(clock.text == "" and clock.alpha == 0 and elapsed.queries == clockQueries,
    "cleanup retires the owned timer with no subsequent scans")
print(string.format("standalone threat meter: %d checks passed; 500-event scans=1; raid facts=80; retained rows=%d", checks, allocation - 3))
