-- lua Core/_tmp_forevercombosmoke.lua
-- Actual Flux component + Forever's actual point animation mixin. Secret
-- sentinels reject Lua arithmetic/comparisons; only mock native widgets unwrap.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function Read(path)
    local f = assert(io.open(root .. path)); local value = f:read("*a"); f:close(); return value
end
local function Compile(source, env)
    if setfenv then local fn = assert(loadstring(source)); setfenv(fn, env); return fn end
    return assert(load(source, "Forever combo smoke", "t", env))
end
local source = Read("UnitFrames/FluxForeverComboPoints.lua")
local nativePath = "../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_UnitFrame/"
local nativePoints = Read(nativePath .. "Mainline/RogueComboPoint.lua")
local nativeXML = Read(nativePath .. "Mainline/RogueComboPoint.xml")
for _, atlas in ipairs({ "uf-roguecp-bg", "uf-roguecp-icon-red" }) do
    assert(nativeXML:find('atlas="' .. atlas .. '"', 1, true))
end
local function Secret(number)
    return setmetatable({ secret = number }, {
        __lt = function() error("compared secret") end,
        __le = function() error("compared secret") end,
        __add = function() error("added secret") end,
        __sub = function() error("subtracted secret") end,
        __tostring = function() error("serialized secret") end,
    })
end
local function Boot(family, class)
    local state = { class = class, count = 0, max = 5, power = 3, use = { player = true, target = true },
        showPower = true, portrait = true, frames = {}, combat = false, reads = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local ns = { Flux = { Client = { isCamelot = family == "forever" } }, API = {
        ShouldUseLegacyComboFrameUI = function() return family == "classic" end,
    }, UnitFrames = {} }
    env.C_Timer = { After = function() end }
    env.FLUX_API = ns.Flux.Client
    env.Enum = { PowerType = { Energy = 3, ComboPoints = 4 } }
    env.issecretvalue = function(v) return type(v) == "table" and v.secret ~= nil end
    env.canaccessvalue = function(v) return not env.issecretvalue(v) end
    env.UnitClass = function() return state.class, state.class end
    env.UnitPowerType = function() return state.power end
    env.UnitPower = function() error("target-bound points must not use UnitPower") end
    env.UnitPowerMax = function(unit, power) assert(power == 4); return state.max end
    env.GetComboPoints = function(unit, target)
        assert(unit == (state.vehicle and "vehicle" or "player") and target == "target")
        state.reads = state.reads + 1
        return state.count
    end
    env.UnitHasVehicleUI = function() return state.vehicle end
    env.InCombatLockdown = function() return state.combat end
    env.FluxUnitFrames_ShouldUseFlux = function(unit) return state.use[unit] end
    env.FluxUnitFrames_ShouldShowClassPower = function() return state.showPower end
    env.FluxUnitFrames_GetClassPowerScale = function() return state.scale or 1 end
    env.FluxUnitFrames_ShouldShowPortrait = function() return state.portrait end
    env.C_Texture = { GetAtlasInfo = function(atlas)
        assert(nativeXML:find('atlas="' .. atlas .. '"', 1, true)); return { width = 20, height = 20 }
    end }
    local native = setmetatable({}, { __newindex = function() error("wrote native frame") end })
    env.PlayerFrame, env.ComboFrame = native, native
    local function Texture()
        return { SetAlpha = function(self, v) self.alpha = v end }
    end
    local function Frame(kind, name, parent, template)
        local frame = { kind = kind, name = name, parent = parent, template = template,
            level = parent and parent.level + 1 or 1, events = {}, shown = true, scripts = {} }
        function frame:GetFrameLevel() return self.level end
        function frame:SetFrameLevel(v) self.level = v end
        function frame:SetFrameStrata(v) self.strata = v end
        function frame:SetSize(w, h) self.width, self.height = w, h end
        function frame:SetScale(v) assert(not state.combat, "resized combo row in combat"); self.scale = v end
        function frame:SetPoint(...) self.anchor = { ... } end
        function frame:SetShown(v) self.shown = v end
        function frame:Show() self.shown = true end
        function frame:Hide() self.shown = false end
        function frame:SetScript(key, value) self.scripts[key] = value end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:RegisterUnitEvent(event, ...) self.events[event] = { ... } end
        function frame:SetStatusBarTexture(atlas) self.atlas = atlas end
        function frame:SetMinMaxValues(low, high) self.low, self.high = low, high end
        function frame:SetValue(value)
            self.value = value
            local n = env.issecretvalue(value) and value.secret or value
            self.fill = math.max(0, math.min(1, (n - self.low) / (self.high - self.low)))
        end
        if template then
            assert(template == "RogueComboPointTemplate", "created native bar with unsafe Setup")
            for key, value in pairs(env.RogueComboPointMixin) do frame[key] = value end
            frame.transitionAnims, frame.fxTextures = {}, { Texture() }
            for anim in nativeXML:gmatch('<AnimationGroup parentKey="([^"]+)"') do
                local ag = { Play = function(self) self.played = true end,
                    Finish = function(self) self.finished = true end,
                    Restart = function(self) self.restarted = true end,
                    Stop = function(self) self.stopped = true end }
                frame[anim] = ag
                frame.transitionAnims[#frame.transitionAnims + 1] = ag
            end
        end
        state.frames[#state.frames + 1] = frame
        if name then env[name] = frame end
        return frame
    end
    env.CreateFrame = Frame
    Compile(nativePoints, env)()
    Compile(source, env)("_FluxUI", ns)
    local player = Frame("Frame"); player.unit = "player"; player.outerBorderFrame = Frame("Frame", nil, player)
    local target = Frame("Frame"); target.unit = "target"; target.PortraitFrame = Frame("Frame", nil, target)
    target.Portrait = Frame("Frame", nil, target.PortraitFrame)
    state.player, state.target = player, target
    function state:init()
        -- Actual player class-resource setup must initialize combo points even
        -- when the managed container / named modern class bars do not exist.
        if not ns.ClassPower then Compile(Read("UnitFrames/FluxClassPower.lua"), env)("_FluxUI", ns) end
        ns.ClassPower.Initialize(player)
        -- Calling the old target entry point must no longer create a row.
        Compile(Read("UnitFrames/FluxLegacyComboPoints.lua"), env)("_FluxUI", ns)
        ns.LegacyComboPoints.Initialize(target)
    end
    function state:event(event, ...)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] then frame.scripts.OnEvent(frame, event, ...) end
        end
    end
    function state:rows() return env.FluxForeverComboPlayer, env.FluxForeverComboTarget end
    return state, ns, env
end

for _, class in ipairs({ "ROGUE", "DRUID" }) do
    local s, ns = Boot("forever", class)
    s:init()
    local player, target = s:rows()
    assert(player and player.shown and not target, "player sockets missing or target unit-frame row created")
    assert(player.parent == s.player.outerBorderFrame and player.scale == 1.6)
    assert(player.anchor[1] == "BOTTOM" and player.anchor[3] == "TOP")
    local initialFrames = #s.frames
    s:init(); assert(#s.frames == initialFrames, "duplicate initialization created another row")
    s.scale = 1.25; ns.ClassPower.ApplyVisibility()
    assert(player.scale == 2, "Forever player scale did not multiply its new 1.6 base")
    s.combat, s.scale = true, 0.75; ns.ClassPower.ApplyVisibility()
    assert(player.scale == 2, "slider resized player pips during combat")
    s.combat = false; s:event("PLAYER_REGEN_ENABLED")
    assert(math.abs(player.scale - 1.2) < 0.0001, "pending size did not apply after combat")
    s.scale = 1; ns.ForeverComboPoints.RefreshAll(true)
    local function CheckAccessible(count)
        for _, row in ipairs({ player }) do
            assert(row.shown, "eligible combo row disappeared at zero points")
            for i, point in ipairs(row.points) do
                assert(point.isFull == (i <= count) and point.isCharged == false)
                assert(not point.restrictedFills[1].shown and not point.restrictedFills[2].shown)
            end
        end
    end
    s.combat = true
    for _, count in ipairs({ 1, 3, 5, 2, 0, 4 }) do
        s.count = count; s:event("UNIT_POWER_FREQUENT", "player", "COMBO_POINTS"); CheckAccessible(count)
    end
    s.count = 2; s:event("PLAYER_TARGET_CHANGED"); CheckAccessible(2)
    s.count = 4; s:event("COMBO_TARGET_CHANGED"); CheckAccessible(4)
    local reads = s.reads
    s:event("UNIT_POWER_FREQUENT", "target", "COMBO_POINTS")
    s:event("UNIT_POWER_FREQUENT", "player", "ENERGY")
    assert(s.reads == reads, "irrelevant power event refreshed points")
    -- Neither the raw count nor a restricted maximum may be compared by Lua.
    s.max = Secret(5)
    for _, count in ipairs({ 0, 1, 5, 3, 0 }) do
        s.count = Secret(count); s:event("UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
        for _, row in ipairs({ player }) do
            assert(row.shown, "restricted zero-point row was hidden")
            for i, point in ipairs(row.points) do
                assert(point.isFull == false)
                for _, fill in ipairs(point.restrictedFills) do
                    assert(fill.shown and fill.value == s.count and fill.fill == (i <= count and 1 or 0))
                end
            end
        end
    end
    s.max, s.count = 5, 2; s:event("PLAYER_REGEN_ENABLED"); CheckAccessible(2)
    s.max = 3; s:event("UNIT_MAXPOWER", "player", "COMBO_POINTS")
    assert(not player.points[4].shown and not player.points[5].shown)
    s.max = 5
    if class == "DRUID" then
        for _, power in ipairs({ 0, 1 }) do
            s.power = power; s:event("UNIT_DISPLAYPOWER", "player")
            assert(not player.shown and not target, "combo row persisted outside Cat Form")
        end
        s.power = 3; s:event("UPDATE_SHAPESHIFT_FORM"); CheckAccessible(2)
    end
    s.vehicle = true; s:event("UNIT_ENTERED_VEHICLE", "player"); CheckAccessible(2)
    s.vehicle = false; s:event("UNIT_EXITED_VEHICLE", "player"); CheckAccessible(2)
    s.showPower = false; ns.ForeverComboPoints.RefreshAll(true)
    assert(not player.shown and not target)
    s.showPower, s.portrait = true, false; ns.ForeverComboPoints.RefreshAll(true)
    assert(player.shown and not target)
    s.use.player, s.use.target = false, false; ns.ForeverComboPoints.RefreshAll(true)
    assert(not player.shown and not target)
    s.use.player, s.use.target, s.portrait = true, true, true
    ns.ForeverComboPoints.RefreshAll(true); CheckAccessible(2)
end
-- A druid logging in outside Cat Form starts hidden; entering Cat at zero
-- shows all empty sockets and leaving Cat hides them immediately in combat.
do
    local s = Boot("forever", "DRUID")
    s.power = 0; s:init()
    local player, target = s:rows(); assert(not player.shown and not target)
    s.combat, s.power = true, 3; s:event("UNIT_DISPLAYPOWER", "player")
    assert(player.shown and not target)
    for _, point in ipairs(player.points) do assert(point.shown and not point.isFull) end
    s.power = 1; s:event("UPDATE_SHAPESHIFT_FORM"); assert(not player.shown and not target)
end
-- Initial creation defers during combat; updates thereafter never defer.
do
    local s, ns = Boot("forever", "DRUID")
    s.combat, s.count = true, 3
    ns.ForeverComboPoints.Initialize(s.player)
    ns.ForeverComboPoints.Initialize(s.target)
    assert(not s:rows())
    s.combat = false; s:event("PLAYER_REGEN_ENABLED")
    local player, target = s:rows(); assert(player.shown and not target)
    s.combat, s.count = true, 5; s:event("COMBO_TARGET_CHANGED"); assert(player.points[5].isFull)
end
for _, family in ipairs({ "live", "classic", "anniversary", "mists" }) do
    local _, ns = Boot(family, "ROGUE")
    assert(not ns.ForeverComboPoints, family .. " loaded Forever component")
end
do
    local s = Boot("forever", "MAGE"); s:init(); assert(not s:rows())
end
print("Forever combos OK: real native point mixin; rogue/cat, player-only layout, combat gains/spends, target transfers, secret count/max, forms, vehicles, options, deferred init, client guards")
