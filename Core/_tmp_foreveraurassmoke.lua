-- lua Core/_tmp_foreveraurassmoke.lua
-- Exercise supplied Forever Lua, not a replacement aura painter. Widget/API
-- mocks cannot reproduce the game engine's taint rules; validate combat in game.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local sourceRoot = root .. "../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/"
local function Load(path, env, ns)
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, env)
    else chunk = assert(loadfile(path, "t", env)) end
    return chunk("_FluxUI", ns)
end
local function Mix(...)
    local result = {}
    for i = 1, select("#", ...) do
        for key, value in pairs(select(i, ...)) do result[key] = value end
    end
    return result
end
local function Widget()
    local w = { shown = true, scripts = {}, events = {} }
    function w:Show() self.shown = true end
    function w:Hide() self.shown = false end
    function w:IsShown() return self.shown end
    function w:SetShown(value) self.shown = value end
    function w:SetScript(key, value) self.scripts[key] = value end
    function w:RegisterEvent(event) self.events[event] = true end
    function w:UnregisterAllEvents() self.events = {} end
    function w:RegisterUnitEvent(event, ...) self.events[event] = { ... } end
    function w:SetTexture(value) self.texture = value end
    function w:SetText(value) self.text = value end
    function w:SetFormattedText(fmt, ...) self.text = string.format(fmt, ...) end
    function w:SetVertexColor() end
    function w:SetAlpha() end
    function w:ClearAllPoints() end
    function w:SetPoint() end
    function w:GetScale() return 1 end
    return w
end

local now, combat = 100, false
local queued, watchers, anchors, callbacks = {}, {}, {}, {}
local auras = { player = { HELPFUL = {}, HARMFUL = {} }, vehicle = { HELPFUL = {}, HARMFUL = {} } }
local originalText = function() end
local health, mana = { UpdateTextStringWithValues = originalText }, { UpdateTextStringWithValues = originalText }
local env = setmetatable({
    WOW_PROJECT_ID = 1, WOW_PROJECT_MAINLINE = 1,
    GetBuildInfo = function() return "1.16.1", "70391", "", 16001 end,
    GetTime = function() return now end,
    InCombatLockdown = function() return combat end,
    UnitAffectingCombat = function() return combat end,
    PlayerFrame = { unit = "player", healthbar = health, manabar = mana },
    TextStatusBarMixin = { UpdateTextStringWithValues = originalText },
    UIParent = {}, C_Spell = {}, InputUtil = { IsGamepadUIEnabled = function() return false end },
    C_Timer = { NewTimedSignalMap = function() end, After = function(_, fn) queued[#queued + 1] = fn end },
    C_Item = {}, HelpTip = { ButtonStyle = {}, Point = {}, Alignment = {} },
    Enum = { FrameTutorialAccount = {}, WeaponSlot = {} },
    EnumUtil = { MakeEnum = function(...) local r = {}; for i, v in ipairs({ ... }) do r[v] = i end; return r end },
    CVarCallbackRegistry = { SetCVarCachable = function() end, GetCVarValueBool = function(_, name) return name == "buffDurations" end },
    EventRegistry = {
        RegisterFrameEvent = function() end,
        RegisterFrameEventAndCallback = function() end,
        RegisterCallback = function(_, name, fn) callbacks[name] = fn end,
    },
    CreateFromMixins = Mix, unpack = table.unpack or unpack,
    GameTooltip = { IsOwned = function() return false end },
    DeadlyDebuffFrame = Widget(),
    HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 }, NORMAL_FONT_COLOR = { r = 1, g = 0.8, b = 0 },
    SecondsToTimeAbbrev = function(seconds) return "%d", math.floor(seconds) end,
    securecall = function(fn, ...) return fn(...) end,
    CreateFrame = function(kind, name, parent, template)
        assert(kind == "Frame" and not name and not template, "addon created replacement aura frames")
        local frame = Widget(); watchers[#watchers + 1] = frame; return frame
    end,
}, { __index = _G })
env._G = env
env.hooksecurefunc = function(frame, key, fn)
    assert((frame == env.BuffFrame or frame == env.DebuffFrame) and key == "ApplySystemAnchor")
    assert(not anchors[frame]); anchors[frame] = fn
end
env.C_UnitAuras = {
    GetAuraSlots = function(unit, filter)
        local slots = {}
        for i = 1, #auras[unit][filter] do slots[i] = i + (filter == "HARMFUL" and 100 or 0) end
        return nil, (table.unpack or unpack)(slots)
    end,
    GetAuraDataBySlot = function(unit, slot)
        return slot > 100 and auras[unit].HARMFUL[slot - 100] or auras[unit].HELPFUL[slot]
    end,
}
Load(sourceRoot .. "Blizzard_FrameXMLUtil/AuraUtil.lua", env)
Load(sourceRoot .. "Blizzard_BuffFrame/BuffFrame.lua", env)
Load(sourceRoot .. "Blizzard_UnitFrame/Mainline/UnitFrame.lua", env)
-- Native aura visuals are irrelevant to enumeration; keep the real buttons,
-- duration calculation, event handler, update methods, and ForEachAura traversal.
env.AuraUtil.SetAuraBorderAtlas = function() end
env.AuraUtil.SetAuraSymbol = function() end
local function AuraFrame(mixin)
    local frame = Mix(env.AuraFrameEditModeMixin, env.BaseAuraFrameMixin, mixin, Widget())
    frame.auraFrames, frame.PrivateAuraAnchors = {}, {}
    frame.maxAuras, frame.isExpanded, frame.hiddenBuffUpdatePeriod = 4, true, 0.2
    frame.AuraContainer = Widget()
    function frame.AuraContainer:UpdateGridLayout() end
    frame.ConsolidatedBuffs = Widget()
    function frame.ConsolidatedBuffs:IsEnabled() return false end
    function frame.ConsolidatedBuffs:ShouldShow() return false end
    frame.CollapseAndExpandButton = Widget()
    function frame.CollapseAndExpandButton:IsEnabled() return false end
    function frame.CollapseAndExpandButton:UpdateOrientation() end
    frame.ApplySystemAnchor = function() end
    frame.ClearAllPointsBase, frame.SetPointBase = frame.ClearAllPoints, frame.SetPoint
    for i = 1, frame.maxAuras do
        local button = Mix(env.AuraButtonMixin, Widget())
        for _, name in ipairs({ "Icon", "Duration", "Count", "DebuffBorder", "TempEnchantBorder", "Symbol" }) do button[name] = Widget() end
        function button:GetParent() return frame.AuraContainer end
        frame.auraFrames[i] = button
    end
    env.AuraFrameEventListenerMixin.AuraFrameEventListener_OnLoad(frame)
    return frame
end
env.BuffFrame, env.DebuffFrame = AuraFrame(env.BuffFrameMixin), AuraFrame(env.DebuffFrameMixin)
local nativeFunctions = {}
for _, name in ipairs({ "UnitFrameHealthBar_Update", "UnitFrameManaBar_Update", "UnitFrameManaBar_UpdateType", "UnitFrameHealPredictionBars_Update" }) do
    nativeFunctions[name] = assert(env[name])
end
local originalEvent = env.AuraFrameEventListenerMixin.AuraFrameEventListener_OnEvent
local ns = { Flux = {}, UnitFrames = {} }
Load(root .. "Core/Client_Camelot.lua", env, ns)
Load(root .. "Minimap/FluxBuffDebuffFrames.lua", env, ns)
local function EmitLifecycle(event)
    for _, w in ipairs(watchers) do if w.events[event] then w.scripts.OnEvent(w, event) end end
    local batch = queued; queued = {}; for _, fn in ipairs(batch) do fn() end
end
EmitLifecycle("PLAYER_LOGIN")
EmitLifecycle("PLAYER_ENTERING_WORLD")
for name, fn in pairs(nativeFunctions) do assert(env[name] == fn, "Forever replaced native " .. name) end
assert(health.UpdateTextStringWithValues == originalText and mana.UpdateTextStringWithValues == originalText
    and env.TextStatusBarMixin.UpdateTextStringWithValues == originalText, "Forever tainted native status text")
assert(env.PlayerFrame.unit == "player" and env.AuraFrameEventListenerMixin.AuraFrameEventListener_OnEvent == originalEvent)
local function Aura(id, count, expiration)
    return { auraInstanceID = id, spellId = id, icon = id, applications = count, duration = 30, expirationTime = expiration, timeMod = 1 }
end
local function EmitAuras(payload, unit)
    for _, frame in ipairs({ env.BuffFrame, env.DebuffFrame }) do originalEvent(frame, "UNIT_AURA", unit or env.PlayerFrame.unit, payload) end
end
local buff, debuff = env.BuffFrame.auraFrames[1], env.DebuffFrame.auraFrames[1]
combat = true
auras.player.HELPFUL = { Aura(1, 1, 130) }
auras.player.HARMFUL = { Aura(2, 2, 125) }
EmitAuras({ addedAuras = { auras.player.HELPFUL[1], auras.player.HARMFUL[1] } })
assert(buff:IsShown() and debuff:IsShown() and debuff.Count.text == 2)
now = 105
buff:OnUpdate(5); debuff:OnUpdate(5)
assert(buff.timeLeft == 25 and debuff.timeLeft == 20 and buff.Duration.text == "25", "combat duration stopped")
auras.player.HELPFUL[1] = Aura(1, 3, 140)
EmitAuras({ updatedAuraInstanceIDs = { 1 } })
assert(buff.Count.text == 3 and buff.timeLeft == 35, "combat stack/refresh did not update")
auras.player.HARMFUL = {}
EmitAuras({ removedAuraInstanceIDs = { 2 } })
assert(not debuff:IsShown() and buff:IsShown(), "combat removal did not update")
now = 141; auras.player.HELPFUL = {}
EmitAuras({ removedAuraInstanceIDs = { 1 } })
assert(not buff:IsShown(), "combat expiration did not remove the aura")
-- Native vehicle routing and the first post-combat update need no Flux refresh.
env.PlayerFrame.unit = "vehicle"
auras.vehicle.HELPFUL = { Aura(3, 1, 160) }
EmitAuras({ isFullUpdate = true })
assert(buff.buttonInfo.auraInstanceID == 3 and buff.unit == "vehicle")
combat = false; env.PlayerFrame.unit = "player"
auras.player.HELPFUL = { Aura(4, 1, 170) }
EmitAuras({ isFullUpdate = true })
assert(buff.buttonInfo.auraInstanceID == 4 and buff.unit == "player")
print("Forever native aura smoke OK (original native methods, gains, stacks, refresh, timers, removals, expiration, vehicles, post-combat)")
