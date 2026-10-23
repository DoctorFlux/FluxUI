-- Executes production raid Compat/Layout/Frame with protected-write mocks.
-- Header child construction, native secure handlers and taint require real WoW.
local unpack = table.unpack or unpack
local assertions = 0
local function check(ok, message) assertions = assertions + 1; assert(ok, message) end
local function load(path, env, ns)
    local fn, err
    if _VERSION == "Lua 5.1" then fn, err = loadfile(path); if fn then setfenv(fn, env) end
    else fn, err = loadfile(path, "t", env) end
    assert(fn, err)("_FluxUI", ns)
end

local function fixture(client, inCombat, enabled)
    local e = setmetatable({}, { __index = _G }); e._G = e
    e.combat, e.enabled = inCombat, enabled ~= false
    e.InCombatLockdown = function() return e.combat end
    e.IsInGroup = function() return true end
    e.IsInRaid = function() return false end
    e.UnitExists = function(unit) return unit == "player" or unit == "party1" end
    e.UnitInRaid = function() return nil end
    e.GetRaidRosterInfo = function() end
    local timers, frames, specs = {}, {}, {}
    local metrics = { headers = 0, hides = 0, attributes = 0, fonts = 0 }
    local methods = {}
    local noop = function() end
    for name in ("SetFrameStrata SetFrameLevel SetAllPoints SetClipsChildren SetShadowOffset SetTextColor SetFont SetScale"):gmatch("%S+") do methods[name] = noop end
    local function legal(self)
        check(not (e.combat and self.protected), client .. ": no protected mutation during lockdown (" .. (self.name or self.kind) .. ")")
    end
    function methods:SetID(id) legal(self); self.id = id end
    function methods:GetID() return self.id end
    function methods:GetName() return self.name end
    function methods:SetAttribute(key, value) legal(self); self.attributes[key] = value; metrics.attributes = metrics.attributes + 1 end
    function methods:GetAttribute(key) return self.attributes[key] end
    function methods:SetPoint(...) legal(self); self.point = { ... } end
    function methods:ClearAllPoints() legal(self); self.point = nil end
    function methods:SetSize(w, h) legal(self); self.width, self.height = w, h end
    function methods:SetWidth(w) legal(self); self.width = w end
    function methods:SetHeight(h) legal(self); self.height = h end
    function methods:GetWidth() return self.width end
    function methods:GetHeight() return self.height end
    function methods:GetTop() return 400 end
    function methods:GetBottom() return 200 end
    function methods:GetLeft() return 0 end
    function methods:GetRight() return self.width end
    function methods:Show() legal(self); self.shown = true end
    function methods:Hide() legal(self); self.shown = false end
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown end
    function methods:IsForbidden() return false end
    function methods:IsProtected() return self.protected end
    function methods:GetAlpha() return self.alpha or 1 end
    function methods:SetAlpha(value)
        legal(self); self.alpha = value
        if self.name == "CompactRaidFrameContainer" and value == 0 then
            check(e.FluxRaidState.secureConfigured, "native grid remains until secure configuration completes")
            metrics.hides = metrics.hides + 1
        end
    end
    function methods:IsMouseEnabled() return self.mouse ~= false end
    function methods:EnableMouse(value) legal(self); self.mouse = value end
    function methods:SetParent(parent) legal(self); self.parent = parent end
    function methods:GetParent() return self.parent end
    function methods:GetChildren() return unpack(self.children) end
    function methods:SetText(text) self.text = text end
    function methods:CreateFontString()
        metrics.fonts = metrics.fonts + 1
        return e.CreateFrame("FontString", nil, self)
    end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:UnregisterEvent(event) self.events[event] = nil end
    function methods:SetScript(key, callback) self.scripts[key] = callback end
    function methods:GetScript(key) return self.scripts[key] end
    e.CreateFrame = function(kind, name, parent, template)
        local protected = template == "FluxRaidGroupHeaderTemplate" or template == "SecureHandlerStateTemplate"
        check(not (protected and e.combat), "secure headers must not be created during lockdown")
        local frame = setmetatable({ kind = kind, name = name, parent = parent, protected = protected,
            children = {}, attributes = {}, scripts = {}, events = {}, shown = false, width = 72, height = 10 }, { __index = methods })
        if name then e[name] = frame end
        frames[#frames + 1] = frame
        if protected and template == "FluxRaidGroupHeaderTemplate" then metrics.headers = metrics.headers + 1 end
        return frame
    end
    e.UIParent = e.CreateFrame("Frame", "UIParent")
    e.FluxRaidContainer = e.CreateFrame("Frame", "FluxRaidContainer", e.UIParent)
    e.CompactRaidFrameContainer = e.CreateFrame("Frame", "CompactRaidFrameContainer", e.UIParent)
    e.CompactRaidFrameContainer.shown = true
    e.CompactRaidFrameContainer.protected = true
    e.C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
    local ns = { Flux = {
        Client = { key = client },
        Module = { Register = function(name, spec) specs[name] = spec end },
        Timer = e.C_Timer,
        Startup = { Mark = noop },
    } }
    e.Flux = ns.Flux
    e.FluxOptions = { GetRaidFrameDB = function() return { useFluxRaidFrames = e.enabled } end }
    e.FluxRaidVisuals = { FRAME_WIDTH = 72, FRAME_HEIGHT = 43, ApplyRaidFrameTunables = noop }
    e.geterrorhandler = function() return function(err) error(err) end end
    function e.Advance()
        local work = timers; timers = {}
        for _, callback in ipairs(work) do callback() end
    end
    function e.FlushNative()
        for _, frame in ipairs(frames) do
            if frame.events.PLAYER_REGEN_ENABLED and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, "PLAYER_REGEN_ENABLED") end
        end
    end
    load("Blizzard/Hide.lua", e, ns)
    load("RaidFrame/FluxRaidCompat.lua", e, ns)
    load("RaidFrame/FluxRaidLayout.lua", e, ns)
    load("RaidFrame/FluxRaidFrame.lua", e, ns)
    e.FluxRaid_OnLoad(e.CreateFrame("Frame", "FluxRaidEventFrame"))
    e.metrics, e.specs = metrics, specs
    return e
end

for _, client in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    local e = fixture(client, true)
    local spec = e.specs.RaidFrames
    check(spec and spec.phase == "secure" and spec.protected and spec.priority == 70, "raid registers a protected secure phase")
    check(e.metrics.headers == 0 and e.metrics.hides == 0, "file load preserves native combat fallback")
    check(spec.OnEnable() == false and not e.FluxRaidState.isInitialized, "direct combat initialize stays incomplete")
    e.FluxRaid_ApplyOptionsFromDB(); e.FluxRaid_RunPendingCombatWork(); e.Advance()
    check(e.metrics.headers == 0 and e.CompactRaidFrameContainer:IsShown(), "combat options and pending work preserve native fallback")
    e.combat = false
    check(spec.OnEnable(), "raid can initialize after combat")
    check(e.metrics.headers == 9 and e.FluxRaidState.secureConfigured, "all nine headers configure before handoff")
    local fonts = e.metrics.fonts
    e.Advance(); e.Advance()
    check(e.metrics.hides > 0 and e.CompactRaidFrameContainer:GetAlpha() == 0
        and not e.CompactRaidFrameContainer:IsMouseEnabled(), "native fallback hands over after secure initialization")
    check(e.CompactRaidFrameContainer:IsShown() and e.CompactRaidFrameContainer:GetParent() == e.UIParent
        and e.CompactRaidFrameContainer:GetScript("OnShow") == nil, "native grid retains its own shown state, parent and scripts")
    check(spec.OnEnable() and e.metrics.headers == 9 and e.metrics.fonts == fonts, "repeated enable reuses headers and labels")

    -- Combat can start between the coalesced request and its next-frame callback.
    e.FluxRaid_QueueConfigureAndRefresh(); e.FluxRaid_QueueConfigureAndRefresh()
    e.combat = true
    e.Advance(); e.FluxRaid_RunPendingCombatWork()
    e.combat = false
    e.FluxRaid_RunPendingCombatWork(); e.FlushNative(); e.Advance(); e.Advance()
    check(e.metrics.headers == 9 and e.metrics.fonts == fonts, "combat interruption reconciles without UI allocation")

    e.enabled = false
    e.FluxRaid_ApplyOptionsFromDB()
    check(e.CompactRaidFrameContainer:IsShown() and e.CompactRaidFrameContainer:GetAlpha() == 1
        and e.CompactRaidFrameContainer:IsMouseEnabled(), "disabling Flux restores native group controls")
end

local disabled = fixture("forever", false, false)
check(disabled.specs.RaidFrames.OnEnable(), "disabled raid profile still initializes safely")
check(disabled.metrics.hides == 0 and disabled.CompactRaidFrameContainer:IsShown(), "disabled saved profile never hides native raid controls")
local partial = fixture("live", false)
partial.FluxRaidCompat.CanUsePetBattleStateDriver = function() return true end
local snippetReady, drivers = false, 0
partial.Flux.Restricted = { Works = function() return true end, SetSnippet = function() return snippetReady end }
partial.RegisterStateDriver = function() drivers = drivers + 1 end
local create = partial.CreateFrame
partial.CreateFrame = function(...)
    local f = create(...)
    f.SetFrameRef = function() assert(not partial.combat) end
    return f
end
check(partial.specs.RaidFrames.OnEnable() == false and partial.metrics.hides == 0, "failed pet-battle setup retains native fallback")
local driver = partial.FluxRaidState.petBattleDriver
snippetReady = true
check(partial.specs.RaidFrames.OnEnable() and partial.FluxRaidState.petBattleDriver == driver and drivers == 1,
    "partial pet-battle setup reuses its frame and commits its driver once")
print("Raid startup: " .. assertions .. " assertions passed across 5 mocked clients; live secure-header/taint testing pending")
