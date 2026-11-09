-- Desktop Lua fixture. No WoW secure/taint VM or live rendering is simulated.
-- lua tests/window_runtime_spec.lua [--baseline]
local baseline = arg and arg[1] == "--baseline"
local unpack = table.unpack or unpack
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL: " .. message) end
end

local function Fixture()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.SlashCmdList = {}
    env.RAID_CLASS_COLORS = { MAGE = { r = 0.4, g = 0.8, b = 1 } }
    env.UnitClass = function() return "Mage", "MAGE" end
    env.combat = false
    env.InCombatLockdown = function() return env.combat end
    env._FluxUI_CharSavedVars = { fluxWindowActiveTab = 2, fluxWindowTabOrderRespecBeforeButtons = true }
    local now, timers, frames = 0, {}, {}
    env.metrics = { fonts = 0, detach = 0, native = 0, positions = 0, embeds = 0, layouts = 0 }
    local noOp = function() end
    local methods = {}
    for name in ("SetAllPoints SetFrameStrata SetFrameLevel EnableMouse RegisterForClicks SetTexture SetVertexColor SetHorizTile SetBlendMode SetTextColor SetToplevel"):gmatch("%S+") do
        methods[name] = noOp
    end
    local function Object(kind, parent)
        local obj = setmetatable({ kind = kind, parent = parent, children = {}, regions = {}, scripts = {}, events = {}, shown = true, width = 405, height = 270 }, { __index = methods })
        if parent then
            local list = (kind == "FontString" or kind == "Texture") and parent.regions or parent.children
            list[#list + 1] = obj
        end
        return obj
    end
    function methods:GetObjectType() return self.kind end
    function methods:GetChildren() return unpack(self.children) end
    function methods:GetRegions() return unpack(self.regions) end
    function methods:GetParent() return self.parent end
    function methods:SetParent(parent)
        if parent == nil then env.metrics.detach = env.metrics.detach + 1 end
        if self.parent then
            local list = (self.kind == "FontString" or self.kind == "Texture") and self.parent.regions or self.parent.children
            for i = #list, 1, -1 do if list[i] == self then table.remove(list, i) end end
        end
        self.parent = parent
        if parent then
            local list = (self.kind == "FontString" or self.kind == "Texture") and parent.regions or parent.children
            list[#list + 1] = self
        end
    end
    function methods:CreateFontString() env.metrics.fonts = env.metrics.fonts + 1; return Object("FontString", self) end
    function methods:CreateTexture() return Object("Texture", self) end
    function methods:SetText(text) self.text = text end
    function methods:GetStringWidth() return #(self.text or "") * 6 end
    function methods:SetWidth(w) self.width = w end
    function methods:GetWidth() return self.width end
    function methods:SetHeight(h) self.height = h end
    function methods:GetHeight() return self.height end
    function methods:SetSize(w, h) self.width, self.height = w, h end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false end
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function methods:SetScript(key, fn) self.scripts[key] = fn end
    function methods:GetScript(key) return self.scripts[key] end
    function methods:HookScript(key, fn)
        local old = self.scripts[key]
        self.scripts[key] = function(...) if old then old(...) end; fn(...) end
    end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:UnregisterEvent(event) self.events[event] = nil end
    function methods:ClearAllPoints() self.pointsCleared = (self.pointsCleared or 0) + 1 end
    function methods:SetPoint() if self.isMirror then env.metrics.positions = env.metrics.positions + 1 end end
    env.CreateFrame = function(kind, name, parent, template)
        if template and template:find("Secure") then
            assert(not env.combat, "secure frame creation during combat")
            env.metrics.secureCreates = (env.metrics.secureCreates or 0) + 1
        end
        local frame = Object(kind, parent)
        if name and not rawget(env, name) then env[name] = frame end
        frames[#frames + 1] = frame
        return frame
    end
    env.UIParent = env.CreateFrame("Frame", "UIParent")
    local function newTimer(delay, fn)
        local timer = { at = now + delay, fn = fn }
        function timer:Cancel() self.cancelled = true end
        timers[#timers + 1] = timer
        return timer
    end
    env.C_Timer = {
        After = function(delay, fn) newTimer(delay, fn) end,
        NewTimer = newTimer,
    }
    function env.Advance(seconds)
        local untilTime = now + seconds
        while true do
            local index, earliest
            for i, timer in ipairs(timers) do
                if timer.at <= untilTime and (not earliest or timer.at < earliest) then index, earliest = i, timer.at end
            end
            if not index then break end
            local timer = table.remove(timers, index)
            now = timer.at
            if not timer.cancelled then timer.fn() end
        end
        now = untilTime
    end
    function env.PendingTimers()
        local n = 0
        for _, timer in ipairs(timers) do if not timer.cancelled then n = n + 1 end end
        return n
    end
    function env.Fire(event, ...)
        local count = #frames
        for i = 1, count do
            local f = frames[i]
            if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
        end
    end
    function env.Load(path, namespace)
        local fn, err
        if _VERSION == "Lua 5.1" then fn, err = loadfile(path); if fn then setfenv(fn, env) end
        else fn, err = loadfile(path, "t", env) end
        assert(fn, err)("_FluxUI", namespace or { API = {} })
    end
    return env
end

local e = Fixture()
e.FluxOptions = { GetPlayerTargetPlacement = function() return 1 end }
for i = 1, 3 do
    e["MirrorTimer" .. i] = e.CreateFrame("StatusBar")
    e["MirrorTimer" .. i].isMirror = true
    e["MirrorTimer" .. i]:SetScript("OnEvent", function() e.metrics.native = e.metrics.native + 1 end)
end
e.MirrorTimer_Show = function() e.metrics.native = e.metrics.native + 1; return e.MirrorTimer1 end
e.Load("Other/FluxDurationBars.lua")
e.Fire("PLAYER_LOGIN"); e.Fire("PLAYER_ENTERING_WORLD"); e.Fire("PLAYER_ENTERING_WORLD")
e.metrics.positions = 0
check(e.MirrorTimer_Show() == e.MirrorTimer1, "MirrorTimer_Show preserves native returned frame")
local showPositions = e.metrics.positions
e.MirrorTimer1:GetScript("OnEvent")(e.MirrorTimer1, "MIRROR_TIMER_START")
local eventPositions = e.metrics.positions - showPositions
check(e.metrics.native == 2, "native mirror show/event run once")
check(showPositions == 1 and eventPositions == 1, "repeated lifecycle events install mirror hooks once")
local replacement = e.CreateFrame("StatusBar")
replacement.isMirror = true
replacement:SetScript("OnEvent", function() end)
e.MirrorTimer1 = replacement
e.Fire("PLAYER_ENTERING_WORLD")
e.metrics.positions = 0
replacement:GetScript("OnEvent")(replacement, "MIRROR_TIMER_START")
check(e.metrics.positions == 1, "replacement mirror frame is hooked")
print((baseline and "BASELINE " or "") .. "Mirror repositions after 3 lifecycle events: show=" .. showPositions .. ", event=" .. eventPositions)

local function WindowFixture()
    local w = Fixture()
    w.ready = false
    w.FluxMeterLayout = { GetMeterBackend = function() return "Details" end, Init = function() end }
    w.FluxDetails = {
        IsDetailsUIReady = function() return w.ready end,
        Embed = function() assert(not w.combat, "meter Embed attempted during combat"); w.metrics.embeds = w.metrics.embeds + 1; return true end,
        Hide = function() end,
    }
    w.FluxExtraButtons = { UI = {
        AttachTo = function(self, parent)
            if not self.frame then self.frame = w.CreateFrame("Frame", nil, parent) end
            self.frame:SetParent(parent)
        end,
        Show = function() end, Hide = function() end,
    } }
    w.Load("Battlezonemap/FluxWindowFrame.lua")
    w.Fire("ADDON_LOADED", "_FluxUI")
    return w
end

local w = WindowFixture()
local fontsAtStart = w.metrics.fonts
w.Advance(6.2)
local retryFonts = w.metrics.fonts - fontsAtStart
check(retryFonts == 0, "meter retries reuse the initial status FontString")
w.FluxWindowFrame:SwitchToTab("Buttons")
local parent = w.FluxWindowFrame:GetTabContent("Buttons")
local hosted = w.FluxExtraButtons.UI.frame
w.FluxWindowFrame:SwitchToTab("Map")
w.FluxWindowFrame:SwitchToTab("Buttons")
check(w.FluxWindowFrame:GetTabContent("Buttons") == parent, "tab content frame remains persistent")
check(hosted:GetParent() == parent and w.metrics.detach == 0, "tab switching preserves hosted children")
check(not w.FluxWindowFrame:GetTabContent("Map"):IsShown(), "inactive fallback content stays hidden")
print((baseline and "BASELINE " or "") .. "Meter retry extra FontStrings=" .. retryFonts .. "; tab-switch detached objects=" .. w.metrics.detach)

local late = WindowFixture()
late.FluxWindowFrame:SwitchToTab("Buttons")
late.ready = true
late.Advance(1)
check(late.metrics.embeds == 0, "meter retries cannot embed after leaving Meter")
late.FluxWindowFrame:SwitchToTab("Meter")
check(late.metrics.embeds == 1, "returning to Meter retries immediately")

local combat = WindowFixture()
combat.combat = true; combat.ready = true
local ok, err = pcall(combat.Advance, 1)
check(ok, "combat beginning during initialization suspends structural retry: " .. tostring(err))
combat.combat = false
combat.Fire("PLAYER_REGEN_ENABLED"); combat.Fire("PLAYER_REGEN_ENABLED")
check(combat.metrics.embeds == 1, "combat-end retry runs exactly once")

local native = Fixture()
native.Load("Battlezonemap/FluxBlizzardMeter.lua")
local availabilityCalls = 0
native.FluxBlizzardMeter.IsAvailable = function() availabilityCalls = availabilityCalls + 1; return false end
native.combat = true
for i = 1, 100 do native.FluxBlizzardMeter:Embed(native.UIParent, { request = i }) end
check(native.PendingTimers() == 0 and availabilityCalls == 0, "native meter queues one structure without combat polling or native API work")
native.combat = false
native.Fire("PLAYER_REGEN_ENABLED"); native.Fire("PLAYER_REGEN_ENABLED")
check(availabilityCalls == 1, "native pending embed coalesces 100 requests and drains once")
native.combat = true
native.FluxBlizzardMeter:Embed(native.UIParent)
native.FluxBlizzardMeter:Hide()
native.combat = false
native.Fire("PLAYER_REGEN_ENABLED")
check(availabilityCalls == 1, "leaving Meter cancels combat-pending native embed")

local function DetailsOrdering(providerFirst)
    local d = Fixture()
    local ready, sourceCalls, started = false, 0, 0
    local flux = { Client = { isForever = true }, Cap = { hasCombatLogUnfiltered = true } }
    local function provider()
        d.DetailsFramework = { IsAddonApocalypseWow = function() return true end }
        d.Details222 = {
            UpdateIsAllowed = function() return false end, StartUp = {},
            Apocalypse = { TypeDetails = 3 }, BParser = {}, parser_frame = d.CreateFrame("Frame"),
        }
        d.Details = {
            InstallOkey = function() return ready end,
            IsUsingBlizzardAPI = function() return true end,
            tabela_instancias = { { SetApocalypseSourceType = function(_, value) sourceCalls = sourceCalls + 1; check(value == 3, "Forever keeps Details source type") end } },
        }
        local restore = d.CreateFrame("Frame")
        restore:RegisterEvent("ADDON_LOADED")
        restore:SetScript("OnEvent", function(self, _, name)
            if name == "Details" then
                check(d.DetailsFramework.IsAddonApocalypseWow(), "provider restores its own profile before Forever adaptation")
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
        -- Real provider ordering from Tercioo/Details-Damage-Meter core/parser.lua
        -- d1e8ad7226616b4a796eebc6ca3ed905ef410b64: PLAYER_LOGIN -> After(0) StartMeUp.
        local login = d.CreateFrame("Frame")
        login:RegisterEvent("PLAYER_LOGIN")
        login:SetScript("OnEvent", function()
            d.C_Timer.After(0, function()
                check(not d.DetailsFramework.IsAddonApocalypseWow(), "Forever patch precedes native provider startup in either addon order")
                started = started + 1; ready = true
            end)
        end)
    end
    if providerFirst then provider(); d.Fire("ADDON_LOADED", "Details") end
    d.Load("Battlezonemap/FluxDetailsForever.lua", { Flux = flux })
    if not providerFirst then provider(); d.Fire("ADDON_LOADED", "Details") end
    d.Fire("PLAYER_LOGIN"); d.Advance(0.3)
    check(started == 1 and sourceCalls == 1, "Forever startup adaptation runs once")
    check(d.Details222.parser_frame.events.COMBAT_LOG_EVENT_UNFILTERED, "Forever combat log parser registration survives optional load ordering")
    d.Fire("ADDON_LOADED", "Details"); d.Advance(1)
    check(sourceCalls == 1, "repeated Details load notification is idempotent")
end
DetailsOrdering(true); DetailsOrdering(false)

local profile = Fixture()
profile.restored = false
profile.Details = { CreateProfile = function()
    check(profile.restored, "Flux profile setup runs after provider ADDON_LOADED restoration")
    profile.profileCalls = (profile.profileCalls or 0) + 1
end }
profile.Load("Battlezonemap/FluxDetails.lua")
local providerAL = profile.CreateFrame("Frame")
providerAL:RegisterEvent("ADDON_LOADED")
providerAL:SetScript("OnEvent", function() profile.restored = true end)
profile.Fire("ADDON_LOADED", "Details"); profile.Advance(0)
profile.Fire("ADDON_LOADED", "_FluxUI"); profile.Advance(0)
check(profile.profileCalls == 1 and profile.Details.always_use_profile_name == "FluxUI", "late Details profile setup is idempotent and preserves integration behavior")

local meterLayout = Fixture()
local active = "Meter"
meterLayout.FluxWindowFrame = { GetActiveTab = function() return active end, GetFrame = function() return meterLayout.UIParent end }
meterLayout.Details = {}
meterLayout.IsAddOnLoaded = function(name) return name == "Details" end
meterLayout.FluxDetails = { Embed = function() meterLayout.metrics.embeds = meterLayout.metrics.embeds + 1 end }
meterLayout.Load("Battlezonemap/FluxMeterLayout.lua")
meterLayout.FluxMeterLayout.Init()
for i = 1, 100 do meterLayout.FluxMeterLayout.ScheduleReembed() end
meterLayout.Advance(0.2)
check(meterLayout.metrics.embeds == 1, "100 meter editor refresh requests coalesce to one layout")
meterLayout.FluxMeterLayout.ScheduleReembed(); active = "Buttons"; meterLayout.Advance(0.2)
check(meterLayout.metrics.embeds == 1, "delayed editor refresh cannot resurface Meter after tab change")
active = "Meter"; meterLayout.FluxMeterLayout.ScheduleReembed(); meterLayout.FluxMeterLayout.CancelPendingWork(); meterLayout.Advance(0.2)
check(meterLayout.metrics.embeds == 1, "tab hide cancels editor's delayed layout")

local ability = Fixture()
local abilitySpec
ability.FluxWindowFrame = { GetFrame = function() return ability.UIParent end }
ability.hooksecurefunc = function() end
ability.FLUX_API = { isPostDF = true }
ability.ExtraAbilityContainer = ability.CreateFrame("Frame")
ability.Load("Other/FluxExtraAbilityHUD.lua", { Flux = { Module = { Register = function(_, spec) abilitySpec = spec end } } })
check(abilitySpec and abilitySpec.phase == "secure" and abilitySpec.protected, "extra ability host joins protected secure startup")
ability.combat = true
check(abilitySpec.OnEnable() == false and not ability.metrics.secureCreates, "extra ability host preserves native container during combat load")
ability.combat = false
abilitySpec.OnEnable(); ability.Advance(0)
check(ability.metrics.secureCreates == 1, "extra ability host creates once at first legal opportunity")
abilitySpec.OnEnable(); ability.Advance(0)
check(ability.metrics.secureCreates == 1, "extra ability retry reuses its secure host")

print("Window/runtime checks: " .. checks .. ", failures: " .. failures)
if failures > 0 and not baseline then os.exit(1) end
