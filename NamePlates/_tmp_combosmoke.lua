-- lua NamePlates/_tmp_combosmoke.lua
-- Actual nameplate core/component + actual Forever renderer/native point mixins.
-- Native plate/frame proxies reject all writes and region measurements.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function Read(path)
    local f = assert(io.open(root .. path)); local s = f:read("*a"); f:close(); return s
end
local function Compile(s, env)
    if setfenv then local f = assert(loadstring(s)); setfenv(f, env); return f end
    return assert(load(s, "nameplate combo fixture", "t", env))
end
local function Secret(value)
    return setmetatable({ secretNumber = value }, {
        __lt = function() error("compared secret") end, __le = function() error("compared secret") end,
        __add = function() error("added secret") end, __sub = function() error("subtracted secret") end,
        __tostring = function() error("serialized secret") end,
    })
end
local function Boot(family, class, strayCamelot)
    local state = { frames = {}, plates = {}, target = nil, count = 0, maximum = 5, power = 3,
        fades = 0, reads = 0, class = class, vehicle = false, combat = false }
    local client = { isEra = family == "era", isAnniversary = family == "anniversary",
        isCamelot = family == "forever" or strayCamelot, isForever = family == "forever",
        isRetail = family == "forever" or family == "live", isMists = family == "mists",
        isLiveMidnight = family == "live", majorVersion = family == "live" and 12 or 1 }
    client.isAnyClassic = client.isEra or client.isAnniversary or client.isMists
    local env = setmetatable({}, { __index = _G }); env._G = env
    local ns = { Flux = { Client = client, EBS = {} } }
    env.Flux, env.FLUX_API = ns.Flux, client
    env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC, env.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 1, 2, 5
    env.WOW_PROJECT_ID = client.isAnyClassic and (client.isAnniversary and 5 or 2) or 1
    env.Enum = { PowerType = { Energy = 3, ComboPoints = 4 } }
    env.issecretvalue = function(v) return type(v) == "table" and v.secretNumber ~= nil end
    env.canaccessvalue = function(v) return not env.issecretvalue(v) end
    env.InCombatLockdown = function() return state.combat end
    env.UnitClass = function() return state.class, state.class end
    env.UnitPowerType = function() return state.power end
    env.UnitHasVehicleUI = function() return state.vehicle end
    env.UnitPowerMax = function(unit, power)
        assert(unit == (state.vehicle and "vehicle" or "player") and power == 4); return state.maximum
    end
    env.GetComboPoints = function(unit, target)
        assert(unit == (state.vehicle and "vehicle" or "player") and target == "target")
        state.reads = state.reads + 1; return state.count
    end
    env.UnitPower = function() error("target-bound combo count used raw player power") end
    env.UnitIsUnit = function() error("compared restricted nameplate unit tokens") end
    env.hooksecurefunc = function() error("installed native hook") end
    env.geterrorhandler = function() return function(err) error(err, 0) end end
    local function Native(fields)
        fields = fields or {}
        fields.GetWidth = function() error("measured restricted native region") end
        fields.GetHeight = fields.GetWidth
        fields.SetPoint = function() error("moved native region") end
        fields.SetScript, fields.HookScript, fields.SetParent = fields.SetPoint, fields.SetPoint, fields.SetPoint
        return setmetatable({}, { __index = fields, __newindex = function() error("wrote native frame field") end })
    end
    env.UIParent = Native()
    env.PlayerFrame, env.ComboFrame = Native({ unit = "player" }), Native()
    -- Native unit-frame options must not govern an independent nameplate row.
    env.FluxUnitFrames_ShouldUseFlux = function() return false end
    env.FluxUnitFrames_ShouldShowClassPower = function() return false end
    env.FluxUnitFrames_ShouldShowPortrait = function() return false end
    env.FluxUnitFrames_GetClassPowerScale = function() return 2 end
    env.C_NamePlate = {
        GetNamePlateForUnit = function(unit) return state.plates[unit == "target" and state.target or unit] end,
        GetNamePlates = function() local t = {}; for _, p in pairs(state.plates) do t[#t + 1] = p end; return t end,
    }
    local nativeRoot = "../__AddonsForRef/wow-ui-source-"
        .. (family == "anniversary" and "classic_anniversary" or family == "era" and "classic_era" or "forever")
        .. "/Interface/AddOns/Blizzard_UnitFrame/"
    local pointXML
    if family == "era" or family == "anniversary" then
        pointXML = Read(nativeRoot .. "Classic/ComboFrame.xml")
        Compile(Read(nativeRoot .. "Classic/ComboFrame.lua"), env)()
    else
        pointXML = Read(nativeRoot .. "Mainline/RogueComboPoint.xml")
        Compile(Read(nativeRoot .. "Mainline/RogueComboPoint.lua"), env)()
    end
    env.C_Texture = { GetAtlasInfo = function(atlas)
        assert(pointXML:find('atlas="' .. atlas .. '"', 1, true)); return { width = 20, height = 20 }
    end }
    local function Texture()
        return { owned = true, alpha = 0, SetAlpha = function(self, v) self.alpha = v end }
    end
    env.UIFrameFadeRemoveFrame = function(texture) assert(texture.owned); texture.fade = nil end
    env.UIFrameFade = function(texture, info)
        assert(texture.owned and info.finishedArg1.owned, "faded native combo point")
        state.fades = state.fades + 1; texture.fade = info; texture.alpha = 1
    end
    env.CreateFrame = function(kind, name, parent, template)
        local frame = { kind = kind, parent = parent, name = name, level = 1, shown = true, events = {}, scripts = {} }
        function frame:SetSize(w, h) self.width, self.height = w, h end
        function frame:EnableMouse(v) self.mouse = v end
        function frame:SetScale(v) self.scale = v end
        function frame:GetParent() return self.parent end
        function frame:SetParent(v) self.parent = v end
        function frame:GetFrameLevel() return self.level end
        function frame:SetFrameLevel(v) self.level = v end
        function frame:SetPoint(...) self.anchor = { ... } end
        function frame:ClearAllPoints() self.anchor = nil end
        function frame:Show() self.shown = true end
        function frame:Hide() self.shown = false end
        function frame:SetShown(v) self.shown = v end
        function frame:SetScript(key, fn) self.scripts[key] = fn end
        function frame:HookScript(key, fn)
            local old = self.scripts[key]; self.scripts[key] = function(...) if old then old(...) end; fn(...) end
        end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:RegisterUnitEvent(event, ...) self.events[event] = { ... } end
        function frame:SetStatusBarTexture(atlas) self.atlas = atlas end
        function frame:SetMinMaxValues(low, high) self.low, self.high = low, high end
        function frame:SetValue(v)
            self.value = v
            local n = env.issecretvalue(v) and v.secretNumber or v
            self.fill = math.max(0, math.min(1, (n - self.low) / (self.high - self.low)))
        end
        if template == "ComboPointTemplate" then
            assert(client.isEra or client.isAnniversary, "Forever got Classic combo art")
            assert(pointXML:find('file="Interface\\ComboFrame\\ComboPoint"', 1, true))
            frame.Highlight, frame.Shine = Texture(), Texture()
        elseif template == "RogueComboPointTemplate" then
            assert(family == "forever" and not client.isAnyClassic, "Classic got Forever combo art")
            for k, v in pairs(env.RogueComboPointMixin) do frame[k] = v end
            frame.fxTextures, frame.transitionAnims = { Texture() }, {}
            for key in pointXML:gmatch('<AnimationGroup parentKey="([^"]+)"') do
                local group = { Stop = function() end, Play = function() end, Finish = function() end, Restart = function() end }
                frame[key] = group; frame.transitionAnims[#frame.transitionAnims + 1] = group
            end
        else assert(not template, "created an unexpected template") end
        state.frames[#state.frames + 1] = frame
        return frame
    end
    Compile(Read("UnitFrames/FluxForeverComboPoints.lua"), env)("_FluxUI", ns)
    Compile(Read("NamePlates/Core.lua"), env)("_FluxUI", ns)
    Compile(Read("NamePlates/ComboPoints.lua"), env)("_FluxUI", ns)
    for _, frame in ipairs(state.frames) do if frame.points then state.host = frame end end
    function state:event(event, ...)
        for _, frame in ipairs(self.frames) do if frame.events[event] then frame.scripts.OnEvent(frame, event, ...) end end
    end
    function state:add(unit, plate)
        plate = plate or Native({ unitToken = unit, GetFrameLevel = function() return 25 end,
            UnitFrame = Native({ unit = unit, HealthBarsContainer = Native({ healthBar = Native() }) }) })
        self.plates[unit] = plate; self:event("NAME_PLATE_UNIT_ADDED", unit); return plate
    end
    function state:remove(unit)
        self:event("NAME_PLATE_UNIT_REMOVED", unit); self.plates[unit] = nil
    end
    function state:select(unit)
        self.target = unit; self:event("PLAYER_TARGET_CHANGED")
    end
    function state:filled(count)
        assert(self.host.shown, "target row hidden at zero/in combat")
        for i, point in ipairs(self.host.points) do
            if family == "forever" then
                if env.issecretvalue(self.count) then
                    assert(not point.isFull)
                    for _, fill in ipairs(point.restrictedFills) do assert(fill.fill == (i <= count and 1 or 0)) end
                else assert(point.isFull == (i <= count)) end
            else assert(point.Highlight.alpha == (i <= count and 1 or 0)) end
        end
    end
    return state, ns
end

for _, family in ipairs({ "era", "anniversary", "forever" }) do
    for _, class in ipairs({ "ROGUE", "DRUID" }) do
        local s, ns = Boot(family, class)
        local host = assert(s.host); assert(not host.shown)
        s.combat = true -- including first plate and first target during combat
        local p1, p2 = s:add("nameplate1"), s:add("nameplate2")
        assert(not host.shown, "non-target plate received combo points")
        s:select("nameplate1"); s:filled(0)
        assert(host.parent == p1 and host.mouse == false and host.level == 32)
        assert(host.anchor[1] == "CENTER" and host.anchor[2] == p1.UnitFrame.HealthBarsContainer.healthBar
            and host.anchor[3] == "TOP" and host.anchor[5] == 4, "combo row not above the health bar")
        assert(host.scale == (family == "forever" and 0.675 or 1.5), "client-specific nameplate combo size incorrect")
        for _, count in ipairs({ 1, 5, 2, 0, 3 }) do
            s.count = count; s:event("UNIT_POWER_FREQUENT", "player", "COMBO_POINTS"); s:filled(count)
        end
        local reads = s.reads
        s:event("UNIT_POWER_FREQUENT", "target", "COMBO_POINTS")
        s:event("UNIT_POWER_FREQUENT", "player", "ENERGY")
        assert(s.reads == reads, "unrelated power event refreshed points")
        s.count = 2; s:select("nameplate2"); s:filled(2)
        assert(host.parent == p2, "old target kept the combo row")
        s.count = 4; s:event("COMBO_TARGET_CHANGED"); s:filled(4)
        local before = #s.frames
        for _ = 1, 10 do s:select("nameplate1"); s:select("nameplate2") end
        assert(#s.frames == before, "target swaps created extra rows")
        s:remove("nameplate1"); assert(host.shown and host.parent == p2, "unrelated removal cleared target row")
        s:remove("nameplate2"); assert(not host.shown and host.parent ~= p2)
        -- Pooled frame reuse must reset points and attach only to the target.
        s.target, s.count = nil, 0; s:add("nameplate3", p2); assert(not host.shown)
        s:select("nameplate3"); s:filled(0)
        s.count = 3; s:event("UNIT_POWER_UPDATE", "player", "COMBO_POINTS"); s:filled(3)
        if class == "DRUID" then
            s.power = 0; s:event("UNIT_DISPLAYPOWER", "player"); assert(not host.shown)
            s.power = 1; s:event("UPDATE_SHAPESHIFT_FORM"); assert(not host.shown)
            s.power, s.count = 3, 0; s:event("UNIT_DISPLAYPOWER", "player"); s:filled(0)
        end
        if family == "forever" then
            s.maximum = Secret(5)
            for _, count in ipairs({ 0, 5, 2, 0 }) do
                s.count = Secret(count); s:event("UNIT_POWER_UPDATE", "player", "COMBO_POINTS"); s:filled(count)
            end
            s.count, s.maximum = 3, 5; s:event("COMBO_TARGET_CHANGED"); s:filled(3)
        end
        s.vehicle, s.count = true, 1; s:event("UNIT_ENTERED_VEHICLE", "player"); s:filled(1)
        s.vehicle = false; s:event("UNIT_EXITED_VEHICLE", "player"); s:filled(1)
        -- Nameplate reload/style refresh uses the new health-bar reference.
        local replacement = s:add("nameplate3")
        ns.Flux.NamePlates.RefreshAll(); s:filled(1)
        assert(host.parent == replacement and host.anchor[2] == replacement.UnitFrame.HealthBarsContainer.healthBar)
        s:select(nil); assert(not host.shown, "clearing target left sockets visible")
        s:select("preview"); assert(not host.shown, "preview plate received points")
        -- Selecting an off-screen target before its plate is added must recover
        -- as soon as the roster reports that plate, without another target event.
        s:select("nameplate4"); assert(not host.shown)
        s:add("nameplate4"); s:filled(1)
    end
end
for _, family in ipairs({ "live", "mists" }) do
    local s = Boot(family, "ROGUE", family == "live")
    s:add("nameplate1"); s:select("nameplate1"); assert(not s.host and s.reads == 0, "unsupported client loaded combo overlay")
end
do
    local s = Boot("era", "ROGUE", true)
    assert(s.host and s.host.points[1].Highlight, "stray Forever flag replaced Era artwork")
end
do
    local s = Boot("forever", "MAGE"); assert(not s.host and s.reads == 0)
end
print("Nameplate combos OK: Era/Anniversary/Forever native templates; target-only top-of-health anchors; zero/gains/spends/transfers; combat/forms/vehicles; secret counts; removal/reuse; native frames untouched; independent of unit-frame options")
