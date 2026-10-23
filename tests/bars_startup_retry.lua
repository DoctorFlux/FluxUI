-- lua tests/bars_startup_retry.lua -- deterministic protected-startup fault injection.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local checks = 0
local function check(value, message) assert(value, message); checks = checks + 1 end
local function envFor(flux)
    local env = setmetatable({ SlashCmdList = {}, UIParent = {}, InCombatLockdown = function() return flux.locked end,
        ClearOverrideBindings = function() end, GetBindingKey = function() return "KEY" end,
        SetOverrideBindingClick = function() end, GetCVarBool = function() return false end }, { __index = _G })
    env._G = env
    env.created, env.mutated = {}, {}
    local methods = {}
    function methods:GetName() return self.name end
    function methods:GetAttribute(key) return self.attributes[key] end
    function methods:SetAttribute(key, value) self.attributes[key] = value end
    function methods:SetScript(key, fn) self.scripts[key] = fn end
    function methods:HookScript(key, fn) self.hooks[key] = (self.hooks[key] or 0) + 1 end
    function methods:GetParent() return self.parent end
    function methods:SetParent(parent) self.parent = parent end
    function methods:GetFrameLevel() return 1 end
    function methods:GetScale() return 1 end
    function methods:GetEffectiveScale() return 1 end
    function methods:GetHeight() return 44 end
    function methods:GetWidth() return 44 end
    function methods:GetAlpha() return self.alpha or 1 end
    function methods:SetAlpha(alpha) self.alpha = alpha; env.mutated[self.name] = true end
    function methods:IsShown() return not self.hidden end
    function methods:Hide() self.hidden = true end
    function methods:Show() self.hidden = false end
    function methods:IsEnabled() return true end
    function methods:GetNumChildren() return 0 end
    function methods:GetChildren() end
    function methods:GetNormalTexture() end
    function methods:GetHighlightTexture() end
    function methods:GetCheckedTexture() end
    function methods:IsProtected() return false end
    local noOp = function() end
    local mt = { __index = function(_, key)
        if methods[key] then return methods[key] end
        if key:match("^Set") or key:match("^Clear") or key:match("^Register") or key:match("^Unregister")
            or key:match("^Enable") or key == "Hide" or key == "Show" or key == "Execute" or key == "WrapScript"
            or key == "UnwrapScript" then return noOp end
    end }
    env.CreateFrame = function(_, name, parent)
        check(not flux.locked, "mock catches protected frame creation during lockdown")
        if name then check(env[name] == nil, "named frames must be reused: " .. name) end
        local frame = setmetatable({ name = name, parent = parent, attributes = {}, scripts = {}, hooks = {} }, mt)
        if name then env[name] = frame; env.created[name] = 1 end
        return frame
    end
    flux.Combat = { InLockdown = function() return flux.locked end, Defer = function(key, fn)
        flux.pending = flux.pending or {}; flux.pending[key] = fn
    end }
    flux.Module = { Register = function() end }
    flux.Action = { DetachFromCollectors = function() end, LeaveBlizzardCollector = function() return false end }
    return env
end
local function module(path, env, flux)
    assert(loadfile(root .. path, "t", env))("_FluxUI", { Flux = flux })
end

for _, client in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    local flux = { Client = { isForever = client == "forever", isCamelot = client == "forever" } }
    local env = envFor(flux)
    module("Bars/Init.lua", env, flux)
    module("Bars/Hosts.lua", env, flux)
    module("Bars/Minis.lua", env, flux)
    local Bars, firstFailure = flux.Bars, true
    local rawCreate = Bars.Hosts.CreateSurface
    Bars.Hosts.CreateSurface = function(column, row, name, parent)
        return env[name] or env.CreateFrame("CheckButton", name, parent)
    end
    Bars.State = { Create = function() end, HeaderFor = function() return env.UIParent end,
        GetMainSlot = function(i) return i end, GetSecondarySlot = function(i) return 60 + i end,
        GetTertiarySlot = function(i) return 24 + i end, Attach = function() end }
    Bars.Hosts.FinishSurface = function(host, column, row)
        if row == "main" and column == 7 and firstFailure then firstFailure = false; error("surface configuration failure") end
        host.finished = (host.finished or 0) + 1
    end
    check(not pcall(Bars.Hosts.Build), client .. ": injected initial host configuration fails")
    local firstHost, partialHost = Bars.hosts[1].main, Bars.hosts[7].main
    check(Bars.Hosts.Build(), client .. ": incomplete host build retries")
    check(Bars.hosts[1].main == firstHost and Bars.hosts[7].main == partialHost and firstHost.finished == 1,
        client .. ": host retry preserves completed and partial identities")
    local finish, miniFailure = Bars.Hosts.FinishSurface, true
    Bars.Hosts.FinishSurface = function(host, column, row)
        if row == "sec" and column == 4 and miniFailure then miniFailure = false; error("mini configuration failure") end
        finish(host, column, row)
    end
    check(not pcall(Bars.Minis.Build), client .. ": injected mini configuration fails")
    local firstMini, partialMini = Bars.hosts[1].sec, Bars.hosts[4].sec
    check(Bars.Minis.Build(), client .. ": incomplete mini build retries")
    check(Bars.hosts[1].sec == firstMini and Bars.hosts[4].sec == partialMini and firstMini.finished == 1,
        client .. ": mini retry preserves identities and skips completed configuration")
    local count = 0
    for _ in pairs(env.created) do count = count + 1 end
    check(count == 57 and Bars.Hosts.Build() and Bars.Minis.Build(), client .. ": exactly 57 reusable surfaces after failures")
    Bars.Hosts.CreateSurface = rawCreate
end

-- Exercise the real CreateSurface hook idempotence and combat entry guard.
do
    local flux = { Bars = { CONFIG = { buttonSize = 44 } } }
    local env = envFor(flux)
    module("Bars/Hosts.lua", env, flux)
    local Hosts = flux.Bars.Hosts
    local fail = true
    flux.Bars.Clicks = { Prepare = function() if fail then fail = false; return false end; return true end }
    check(Hosts.CreateSurface(1, "main", "FluxRetrySurface", env.UIParent) == nil, "failed click setup leaves surface incomplete")
    local widget = assert(Hosts.CreateSurface(1, "main", "FluxRetrySurface", env.UIParent))
    check(Hosts.CreateSurface(1, "main", "FluxRetrySurface", env.UIParent) == widget and widget.hooks.OnMouseDown == 1,
        "successful surface retry installs one mouse-down hook")
    flux.locked = true
    check(Hosts.CreateSurface(2, "main", "FluxForbiddenSurface", env.UIParent) == nil and not env.FluxForbiddenSurface,
        "combat surface creation is rejected before any protected mutation")
end

-- Failed layout cannot mark startup complete or retire the native controls.
do
    local flux = { Bars = { CONFIG = { strata = "MEDIUM", level = 5, scale = 1 } } }
    local env = envFor(flux)
    module("Bars/Strip.lua", env, flux)
    local Strip, failLayout = flux.Bars.Strip, true
    Strip.Layout = function() if failLayout then error("strip layout failed") end end
    check(not pcall(Strip.Create), "failed strip layout retains its three named containers")
    failLayout = false
    local frame = Strip.Create()
    check(frame == env.FluxActionStrip and Strip.Create() == frame and Strip.inner == env.FluxActionStripContent,
        "strip retry reuses partial containers and completes once")
    flux.Bars.secureReady = false
    Strip.SyncVisibility()
    check(not frame:IsShown(), "incomplete strip stays hidden while native controls provide fallback")
    flux.Bars.secureReady = true
    Strip.SyncVisibility()
    check(frame:IsShown(), "completed strip can present its secure input surfaces")
end

do
    local flux, layoutFails, nativeRetired = {}, true, 0
    local env = envFor(flux)
    module("Bars/Init.lua", env, flux)
    local Bars = flux.Bars
    for i = 1, 19 do Bars.hosts[i] = { main = { widget = {} }, sec = { widget = {} }, tert = { widget = {} } } end
    Bars.Layout = { Apply = function() if layoutFails then error("layout failure") end end }
    Bars.Blizzard = { Prepare = function() nativeRetired = nativeRetired + 1 end }
    check(not pcall(Bars.Start) and not Bars.started and not Bars.secureReady and nativeRetired == 0,
        "layout exception preserves native fallback and retry state")
    layoutFails = false
    flux.locked = true
    check(Bars.Start() == false and Bars.Start() == false and nativeRetired == 0, "combat start attempts only defer")
    local jobs = 0
    for _ in pairs(flux.pending) do jobs = jobs + 1 end
    check(jobs == 1, "repeated blocked startup coalesces to one deferred job")
    flux.locked = false
    flux.pending["bars.start"]()
    check(Bars.started and Bars.secureReady and nativeRetired == 1 and Bars.Start(), "successful retry commits readiness once")
end

do
    local flux, failStyle, failBinding, retired = { Bars = {} }, true, true, 0
    local env = envFor(flux)
    flux.EBS = { Widget = { Create = function(parent, config)
        return { Widget = env.CreateFrame("CheckButton", config.name, parent) }
    end }, Action = { SetAction = function() end }, Style = { Apply = function(btn)
        if btn.Widget.name == "FluxPetButton4" and failStyle then failStyle = false; error("pet style failure") end
    end } }
    flux.Bars.Blizzard = { HideUnusedBars = function() retired = retired + 1 end }
    env.SetOverrideBindingClick = function() if failBinding then error("binding blocked") end end
    module("Bars/Pet/Init.lua", env, flux)
    module("Bars/Pet/Keys.lua", env, flux)
    local Pet = flux.Bars.Pet
    check(not pcall(Pet.Start) and not Pet.secureReady and retired == 0, "partial pet setup retains native controls")
    local first = Pet.GetButton(1)
    check(Pet.Start() == false and not Pet.secureReady and retired == 0 and not Pet.GetFrame():IsShown(),
        "failed pet binding setup cannot declare readiness or present partial controls")
    failBinding = false
    check(Pet.Start() and Pet.secureReady and retired == 1 and Pet.GetButton(1) == first, "pet retries reuse buttons before native retirement")
    local count = 0
    for _ in pairs(env.created) do count = count + 1 end
    check(count == 11 and Pet.Start() and retired == 1, "pet retries allocate exactly one container and ten buttons")
end

do
    local flux, missingForm, failBinding, retired = { Bars = {} }, true, true, 0
    local env = envFor(flux)
    flux.Bars.Blizzard = { HideUnusedBars = function() retired = retired + 1 end }
    env.SetOverrideBindingClick = function() if failBinding then error("stance binding blocked") end end
    module("Bars/Stance/Init.lua", env, flux)
    module("Bars/Stance/Layout.lua", env, flux)
    local Stance = flux.Bars.Stance
    Stance.Catalog = function() return 1, {}, {}, 1 end
    Stance.GetSavedOrder = function() return {} end
    Stance.BuildPermutation = function() return { 1 } end
    local form = { Widget = env.CreateFrame("CheckButton", "FluxTestForm", env.UIParent) }
    Stance.EnsureFormButton = function() if missingForm then return nil end; return form end
    check(Stance.Start() == false and not Stance.secureReady and retired == 0, "missing stance button retains native controls")
    missingForm = false
    check(Stance.Start() == false and not Stance.secureReady and retired == 0 and not Stance.GetFrame():IsShown(),
        "failed stance binding setup cannot declare readiness or present partial controls")
    failBinding = false
    check(Stance.Start() and Stance.secureReady and retired == 1, "stance controls become ready after synchronous layout and bindings")
    check(Stance.Start() and retired == 1, "completed stance startup is idempotent")
end

-- Failure inside protected click setup must propagate on native and wrap clients.
for _, wrapped in ipairs({ false, true }) do
    local flux, failWrap = {}, true
    local env = envFor(flux)
    flux.Restricted = { Works = function() return wrapped end,
        WrapScript = function() return not failWrap end, Execute = function() return true end }
    module("Core/ButtonFX/Click.lua", env, flux)
    local button = env.CreateFrame("CheckButton", "FluxClickCheck", env.UIParent)
    local nativeSet = button.SetAttribute
    button.SetAttribute = function() error("protected write blocked") end
    check(flux.ButtonFX.Click.Apply(button) == false, "protected click attribute failure is reported")
    button.SetAttribute = nativeSet
    if wrapped then
        check(flux.ButtonFX.Click.Apply(button) == false, "failed secure click wrapper is reported")
        failWrap = false
    end
    check(flux.ButtonFX.Click.Apply(button) == true, "successful native/wrapped click setup reports readiness")
end

-- Native Pet/Stance controls remain available while only the main strip is ready.
do
    local flux = { Bars = { NUM_NATIVE = 12, secureReady = true, Pet = { secureReady = false }, Stance = { secureReady = false } } }
    local env = envFor(flux)
    for _, name in ipairs({ "MainActionBar", "PetActionBar", "StanceBar", "ActionBarParent" }) do
        env.CreateFrame("Frame", name, env.UIParent)
    end
    module("Bars/Blizzard.lua", env, flux)
    flux.Bars.Blizzard.HideUnusedBars()
    check(not env.mutated.PetActionBar and not env.mutated.StanceBar and not env.mutated.ActionBarParent,
        "main-strip readiness cannot suppress incomplete native Pet/Stance controls or their shared parent")
    flux.Bars.Pet.secureReady = true
    flux.Bars.Blizzard.HideUnusedBars()
    check(env.mutated.PetActionBar and not env.mutated.ActionBarParent, "native pet retires independently after Pet readiness")
end

-- Native driver and snippet failures cannot be masked by a complete widget set.
do
    local flux, collectorWrites, applied = { Bars = { secureReady = false } }, 0, 0
    local env = envFor(flux)
    env.ActionBarButtonEventsFrame = { UnregisterEvent = function() collectorWrites = collectorWrites + 1 end }
    env.ActionBarActionEventsFrame = { UnregisterAllEvents = function() collectorWrites = collectorWrites + 1 end }
    flux.Bars.State = { ForceApply = function() applied = applied + 1 end }
    module("Bars/Vehicle.lua", env, flux)
    flux.Bars.Vehicle.Start()
    check(collectorWrites == 0 and applied == 0, "file load and incomplete vehicle startup preserve native collector updates")
    flux.Bars.secureReady = true
    flux.Bars.Vehicle.OnReplacementsReady()
    check(collectorWrites > 0 and applied == 1, "vehicle suppression and forced initialization activate after secure readiness")
end

do
    local flux, failDriver, failSnippet = { Bars = {} }, true, false
    local env = envFor(flux)
    env.UnitClass = function() return "Warrior", "WARRIOR" end
    flux.Bars.Strip = { inner = env.CreateFrame("Frame", "FluxStateInner", env.UIParent) }
    flux.Restricted = { PagingWorks = function() return true end,
        RegisterPagingDriver = function() return not failDriver end, UnregisterPagingDriver = function() return true end,
        SetPagingSnippet = function() return not failSnippet end }
    module("Bars/State.lua", env, flux)
    check(flux.Bars.State.RegisterDrivers() == false, "failed native paging driver registration reports incomplete input")
    failDriver, failSnippet = false, true
    check(flux.Bars.State.RegisterDrivers() == false, "failed secure snippet installation reports incomplete input")
    failSnippet = false
    check(flux.Bars.State.RegisterDrivers() == true, "paging setup can retry successfully on the same headers")
end

-- Actual Extra Widget.Create/Attach can recover after named creation and partial attachment.
do
    local flux, failRegistration, registered = { EBS = {} }, true, 0
    local env = envFor(flux)
    env.FluxButton = {}
    flux.EBS.RegisterBadge = function()
        if failRegistration then failRegistration = false; error("badge registration failed") end
        registered = registered + 1
    end
    module("ExtraButtonSystem/Engine/Widget.lua", env, flux)
    local Widget = flux.EBS.Widget
    local config = { name = "FluxPartialBadge", kind = "badge", size = 20, skipScripts = true }
    check(not pcall(Widget.Create, env.UIParent, config), "partial Extra attachment failure is observable")
    local partial = env.FluxPartialBadge.FluxButton
    check(partial and not partial._fluxWidgetAttached, "partial attachment is not marked ready")
    local result = Widget.Create(env.UIParent, config)
    check(result == partial and result._fluxWidgetAttached and result._fluxWidgetCreated,
        "Extra retry completes attachment on the original named frame and button record")
    check(Widget.Create(env.UIParent, config) == result and registered == 1,
        "completed named Extra creation is idempotent")
end

-- Production Watch subscribers: same cadence, one manager sample per ticker dispatch.
do
    local flux, handlers = { Client = { isPreDF = true, isAnyClassic = true } }, {}
    local env = envFor(flux)
    flux.Events = { Register = function(event, fn) handlers[event] = fn end }
    module("Core/ButtonFX/Glow.lua", env, flux)
    local Glow = flux.ButtonFX.Glow
    Glow.Start()
    check(type(handlers.ADDON_LOADED) == "function", "proc-glow integration subscribes before its optional addon loads")
    local sao = { AddGlow = function() end, AddGlowNumber = function() end, RemoveGlow = function() end }
    env.SpellActivationOverlayAddon = sao
    handlers.ADDON_LOADED("ADDON_LOADED", "SpellActivationOverlay")
    check(sao._fluxGlowHooked, "late SAO load installs its integration without a TOC startup dependency")
    sao:AddGlowNumber(7, 4242)
    check(Glow.Want(4242), "late SAO glow membership reaches Flux feedback")
end

do
    local function capturePolling(barSource, extraSource)
    local flux, samples, frame, mainPaint, extraPaint = { Bars = {}, EBS = {} }, 0, 0, 0, 0
    local env = envFor(flux)
    local subscribers = {}
    flux.Ticker = { Add = function(key, fn) subscribers[key] = fn end, Remove = function(key) subscribers[key] = nil end,
        Ticks = function() return frame end }
    flux.Cap = { ClientSupportsSingleButtonAssistant = function() return true end }
    flux.Bars.ForEachHost = function(fn) fn({ slot = 1 }) end
    flux.Action.IsAssistedCombat = function() return true end
    flux.Bars.Paint = { PaintAssistedHosts = function() mainPaint = mainPaint + 1 end }
    flux.EBS.buttons = { { IsAssistedCombat = true } }
    flux.EBS.Action = { PaintAssistantButtons = function() extraPaint = extraPaint + 1 end }
    env.AssistedCombatManager = { GetUpdateRate = function() samples = samples + 1; return 0.1 end }
    assert(load(barSource, "Bars/Watch.lua polling fixture", "t", env))("_FluxUI", { Flux = flux })
    assert(load(extraSource, "ExtraButtonSystem/Engine/Watch.lua polling fixture", "t", env))("_FluxUI", { Flux = flux })
    flux.Bars.Watch.SyncAssistantTicker()
    flux.EBS.Watch.SyncAssistantTicker()
    for i = 1, 600 do
        frame = i
        subscribers["bars.assistant"](1 / 60)
        subscribers["ebs.assistant"](1 / 60)
    end
    return samples, mainPaint, extraPaint
    end
    local function read(path)
        local file = assert(io.open(root .. path, "r"))
        local source = file:read("*a")
        file:close()
        return source
    end
    local samples, mainPaint, extraPaint = capturePolling(read("Bars/Watch.lua"), read("ExtraButtonSystem/Engine/Watch.lua"))
    check(samples == 600, "two assistant consumers share one manager sample per frame")
    check(mainPaint == extraPaint and mainPaint > 80 and mainPaint < 101, "assistant paint cadences remain equal and responsive")
    if arg[1] == "--baseline" then
        local function baseline(path)
            local pipe = assert(io.popen("git show HEAD:" .. path, "r"))
            local source = pipe:read("*a")
            check(pipe:close(), "git HEAD baseline must be available")
            return source
        end
        local before, beforeMainPaint, beforeExtraPaint = capturePolling(baseline("Bars/Watch.lua"), baseline("ExtraButtonSystem/Engine/Watch.lua"))
        check(before == 1200 and samples == before / 2, "production HEAD baseline demonstrates 50 percent fewer manager samples")
        check(mainPaint == beforeMainPaint and extraPaint == beforeExtraPaint, "production HEAD and working-copy paint cadence is identical")
        print(("assistant rate samples: %d HEAD baseline, %d working copy; %d paints per consumer (600 frames)"):format(before, samples, mainPaint))
    else
        print(("assistant rate samples: %d; %d paints per consumer (600 frames; use --baseline for HEAD comparison)"):format(samples, mainPaint))
    end
end

print(("bars startup retry: %d checks passed"):format(checks))
