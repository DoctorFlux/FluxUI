-- lua Core/_tmp_classpowerscalesmoke.lua
-- Actual options builder/getter, native-resource positioning, and Classic row.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function Read(path)
    local f = assert(io.open(root .. path)); local s = f:read("*a"); f:close(); return s
end
local function Compile(s, env)
    if setfenv then local f = assert(loadstring(s)); setfenv(f, env); return f end
    return assert(load(s, "class power scale fixture", "t", env))
end
local bridge = Read("UnitFrames/FluxUnitFrames_OptionsBridge.lua")
local start = assert(bridge:find("function FluxUnitFrames_GetClassPowerScale()", 1, true))
local finish = assert(bridge:find("\nend", start, true)) + 3
local scaleGetter = bridge:sub(start, finish)
local function Boot(class, legacy)
    local s = { combat = false, frames = {}, timers = {}, db = {}, characterDB = {}, character = false, class = class, count = 0, power = 3 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local ns = { Flux = { Client = { isEra = legacy } }, UnitFrames = {}, API = {
        ShouldUseLegacyComboFrameUI = function() return legacy end,
    } }
    env.FLUX_API = {}
    env.FluxOptions = { GetUnitFrameDB = function() return s.character and s.characterDB or s.db end,
        GetPlayerTargetPlacement = function() return 1 end,
        RegisterModuleOptions = function(_, name, fn) assert(name == "unitframes"); s.builder = fn end }
    env.InCombatLockdown = function() return s.combat end
    env.UnitClass = function() return class, class end
    env.Enum = { PowerType = { Energy = 3, ComboPoints = 4 } }
    env.UnitPowerType = function() return s.power end
    env.GetComboPoints, env.UnitPowerMax = function() return s.count end, function() return 5 end
    env.FluxUnitFrames_ShouldShowClassPower = function() return true end
    env.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    local function Frame(name, parent)
        local f = { name = name, parent = parent, shown = true, scripts = {}, events = {} }
        function f:GetName() return self.name end
        function f:GetParent() return self.parent end
        function f:SetParent(value) assert(not s.combat); self.parent = value end
        function f:GetFrameLevel() return 5 end
        function f:SetFrameLevel() assert(not s.combat) end
        function f:SetFrameStrata() assert(not s.combat) end
        function f:SetScale(value) assert(not s.combat, "changed class-resource layout in combat"); self.scale = value end
        function f:SetSize(w, h) self.width, self.height = w, h end
        function f:SetPoint() assert(not s.combat) end
        function f:ClearAllPoints() assert(not s.combat) end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:SetShown(value) self.shown = value end
        function f:IsShown() return self.shown end
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:UnregisterAllEvents() self.events = {} end
        function f:RegisterUnitEvent(event) self.events[event] = true end
        function f:SetScript(key, fn) self.scripts[key] = fn end
        function f:Layout() end
        function f:GetChildren() return end
        function f:GetLeft() return 0 end
        function f:GetRight() return 60 end
        function f:GetTop() return 16 end
        function f:GetBottom() return 0 end
        function f:GetHeight() return 16 end
        s.frames[#s.frames + 1] = f
        if name then env[name] = f end
        return f
    end
    env.CreateFrame = function(_, name, parent, template)
        local f = Frame(name, parent)
        if template then
            assert(template == "ComboPointTemplate")
            f.Highlight, f.Shine = { SetAlpha = function(self, v) self.alpha = v end }, { SetAlpha = function(self, v) self.alpha = v end }
        end
        return f
    end
    env.UIParent = Frame("UIParent")
    local player = Frame("FluxPlayer", env.UIParent); player.unit = "player"
    player.outerBorderFrame = Frame(nil, player)
    ns.PlayerFrame = player
    env.ComboFrame = Frame("ComboFrame")
    s.nativeComboSetParent = env.ComboFrame.SetParent
    env.PlayerFrame = { unit = "player" }
    Compile(scaleGetter, env)()
    Compile(Read("UnitFrames/FluxClassPower.lua"), env)("_FluxUI", ns)
    ns.ClassPower.Frame = player
    if legacy then
        Compile(Read("UnitFrames/FluxLegacyComboPoints.lua"), env)("_FluxUI", ns)
        ns.LegacyComboPoints.Initialize({ unit = "target" })
        assert(not env.FluxLegacyComboPlayerHost, "target initialization created combo points")
        ns.LegacyComboPoints.Initialize(player)
    else
        env.PlayerBottomManagedFrameContainer = Frame("PlayerBottomManagedFrameContainer", env.UIParent)
        local names = { "PaladinPowerBarFrame", "MageArcaneChargesFrame", "RogueComboPointBarFrame",
            "DruidComboPointBarFrame", "MonkHarmonyBarFrame", "WarlockPowerFrame", "RuneFrame", "EssencePlayerFrame", "TotemFrame" }
        for _, name in ipairs(names) do Frame(name, env.UIParent) end
    end
    function s:flush()
        local t = self.timers; self.timers = {}
        for _, fn in ipairs(t) do fn() end
    end
    function s:regen()
        self.combat = false
        for _, f in ipairs(self.frames) do if f.events.PLAYER_REGEN_ENABLED and f.scripts.OnEvent then f.scripts.OnEvent(f, "PLAYER_REGEN_ENABLED") end end
        self:flush()
    end
    s:flush()
    return s, ns, env
end
local classes = { MAGE = "MageArcaneChargesFrame", ROGUE = "RogueComboPointBarFrame", DRUID = "DruidComboPointBarFrame",
    PALADIN = "PaladinPowerBarFrame", MONK = "MonkHarmonyBarFrame", WARLOCK = "WarlockPowerFrame",
    DEATHKNIGHT = "RuneFrame", EVOKER = "EssencePlayerFrame", SHAMAN = "TotemFrame" }
for class, name in pairs(classes) do
    local s, ns, env = Boot(class, false)
    for _, scale in ipairs({ 0.5, 1, 1.5, 2 }) do
        s.db.classPowerScale = scale; ns.ClassPower.ApplyVisibility()
        assert(env.PlayerBottomManagedFrameContainer.scale == 2 * scale, class .. " container not scaled")
        local base = class == "MAGE" and 1.5 or class == "SHAMAN" and 0.6375 or 2
        assert(math.abs(env[name].scale - base * scale) < 0.00001, class .. " resource not scaled")
    end
    s.combat, s.db.classPowerScale = true, 0.75
    ns.ClassPower.ApplyVisibility()
    assert(env.PlayerBottomManagedFrameContainer.scale == 4)
    s:regen(); assert(env.PlayerBottomManagedFrameContainer.scale == 1.5, "native pending scale did not apply")
end
do
    local s, ns, env = Boot("ROGUE", true)
    local row = assert(env.FluxLegacyComboPlayerHost)
    assert(row.scale == 2.75 and not env.ComboFrame.shown and next(env.ComboFrame.events) == nil)
    local function CheckPoints(count)
        assert(row.shown, "Classic player row disappeared at zero points")
        for i = 1, 5 do
            local point = env["FluxLegacyPlayerComboPoint" .. i]
            assert(point.shown and point.Highlight.alpha == (i <= count and 1 or 0), "Classic empty socket or filled point incorrect")
        end
    end
    CheckPoints(0)
    s.combat = true
    for _, count in ipairs({ 1, 5, 2, 0 }) do
        s.count = count; ns.LegacyComboPoints.RefreshAll(); CheckPoints(count)
    end
    s.combat = false
    for _, scale in ipairs({ 0.5, 1.25, 2 }) do
        s.db.classPowerScale = scale; ns.ClassPower.ApplyVisibility(); assert(row.scale == 2.75 * scale)
    end
    s.combat, s.db.classPowerScale = true, 0.75; ns.ClassPower.ApplyVisibility(); assert(row.scale == 5.5)
    s:regen(); assert(row.scale == 2.75 * 0.75)
    assert(env.PlayerFrame.unit == "player" and env.ComboFrame.SetParent == s.nativeComboSetParent, "native player/target combo methods changed")
end
do
    local s, ns, env = Boot("DRUID", true)
    local row = assert(env.FluxLegacyComboPlayerHost)
    assert(row.shown, "Cat Form should show empty combo sockets")
    s.combat, s.power = true, 0
    ns.LegacyComboPoints.RefreshAll()
    assert(not row.shown, "Druid combo sockets visible outside Cat Form")
    s.power = 3
    ns.LegacyComboPoints.RefreshAll()
    assert(row.shown, "Returning to Cat Form at zero points did not show sockets")
    for i = 1, 5 do
        local point = env["FluxLegacyPlayerComboPoint" .. i]
        assert(point.shown and point.Highlight.alpha == 0)
    end
end

do
    local s, ns, env = Boot("MAGE", false)
    Compile(Read("AddonOptions/FluxOptionsUnitFrames.lua"), env)("_FluxUI", ns)
    local loader = s.frames[#s.frames]; loader.scripts.OnEvent(loader, "ADDON_LOADED", "_FluxUI")
    local options = assert(s.builder)()
    local function Find(t)
        if type(t) ~= "table" then return end
        if t.name == "Class power size (%)" then return t end
        for _, child in pairs(t) do if type(child) == "table" then local found = Find(child); if found then return found end end end
    end
    local slider = assert(Find(options), "class power slider missing from actual options")
    assert(slider.min == 50 and slider.max == 200 and slider.step == 5 and slider.get() == 100)
    slider.set(nil, 125); assert(s.db.classPowerScale == 1.25 and slider.get() == 125)
    assert(env.MageArcaneChargesFrame.scale == 1.875)
    s.character = true; assert(slider.get() == 100, "account scale leaked into character settings")
    slider.set(nil, 75); assert(s.characterDB.classPowerScale == 0.75 and s.db.classPowerScale == 1.25)
    s.character = false; assert(slider.get() == 125)
    s.db.classPowerScale = 999; assert(slider.get() == 200)
    s.db.classPowerScale = -3; assert(slider.get() == 50)
    s.db.classPowerScale = "invalid"; assert(slider.get() == 100)
end
print("Class power scale OK: actual scoped options/getter; 9 native classes, container/loose/arcane/totems; Classic row; target suppression; 50-200% and combat deferral")
