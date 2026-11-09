-- Production mover/options replay; modeled frames do not certify native UI/taint.
-- --baseline uses retained pre-fix sources; --measure retains failed assertions.
local baseline, measure = false, false
for _, value in ipairs(arg or {}) do
    if value == "--baseline" then baseline = true end
    if value == "--measure" then measure = true end
end
local checks, failures = 0, 0
local function check(value, label)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. label) end
end
local function boot(enabled)
    local h = { frames = {}, timers = {}, hooks = 0, resolves = 0, catalogCalls = 0,
        polls = 0, updates = 0, writes = 0, now = 0, available = {}, combat = false, deferred = {} }
    local db = { enabled = enabled, scaleEnabled = true, saveScale = true, savePosition = true,
        frames = { PlayerSpellsFrame = { scale = 1.2 }, CharacterFrame = { scale = 1.1 } } }
    h.db = db
    local function frame(name)
        local f = { name = name, shown = true, scripts = {}, events = {}, scale = 1 }
        function f:GetName() return self.name end
        function f:IsShown() if name == "PlayerSpellsFrame" then h.polls = h.polls + 1 end; return self.shown end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:SetScript(key, fn) self.scripts[key] = fn end
        function f:HookScript(key, fn) h.hooks = h.hooks + 1; self.scripts[key] = fn end
        function f:RegisterEvent(key) self.events[key] = true end
        function f:UnregisterEvent(key) self.events[key] = nil end
        function f:IsMouseEnabled() return true end
        function f:IsProtected() return true end
        function f:EnableMouse() end
        function f:GetScale() return self.scale end
        function f:SetScale(value) self.scale = value; h.writes = h.writes + 1 end
        function f:SetPoint() end
        function f:SetFrameStrata() end
        function f:SetFrameLevel() end
        function f:SetMovable() end
        function f:SetClampedToScreen() end
        function f:StopMovingOrSizing() end
        h.frames[#h.frames + 1] = f
        return f
    end
    h.panel, h.character = frame("PlayerSpellsFrame"), frame("CharacterFrame")
    h.available.PlayerSpellsFrame, h.available.CharacterFrame = h.panel, h.character
    local mover = {
        IsFrame = function(f) return type(f) == "table" and f.GetName ~= nil end,
        Resolve = function(name) h.resolves = h.resolves + 1; return h.available[name] end,
        FindDragHandles = function(f) return { f } end,
    }
    local flux = { WindowMover = mover, Client = { Matches = function(mask) return mask.midnight end },
        Module = { Register = function(_, spec) h.module = spec end },
        Combat = { InLockdown = function() return h.combat end,
            Defer = function(key, fn) h.deferred[key] = fn end } }
    local env = setmetatable({ Flux = flux, SlashCmdList = {},
        FluxOptions = { GetWindowMoverDB = function() return db end,
            RegisterModuleOptions = function(_, _, builder) h.options = builder().args end },
        CreateFrame = function(_, name) return frame(name) end,
        C_Timer = { After = function(delay, fn) h.timers[#h.timers + 1] = { at = h.now + delay, fn = fn } end },
        hooksecurefunc = function() h.hooks = h.hooks + 1 end,
        GetCursorPosition = function() return h.cursor or 100, 100 end,
        UIParent = { GetEffectiveScale = function() return 1 end },
    }, { __index = _G })
    env._G = env
    local ns = { Flux = flux }
    local function load(path) assert(loadfile(path, "t", env))("_FluxUI", ns) end
    load("WindowMover/Catalog.lua")
    local catalog = mover.Catalog
    mover.Catalog = function() h.catalogCalls = h.catalogCalls + 1; return catalog() end
    load(baseline and "tests/fixtures/window_mover_engine_before.txt" or "WindowMover/Engine.lua")
    load(baseline and "tests/fixtures/window_mover_init_before.txt" or "WindowMover/Init.lua")
    load("AddonOptions/FluxOptionsWindows.lua")
    function h:event(key, ...)
        local snapshot = {}; for i, f in ipairs(self.frames) do snapshot[i] = f end
        for _, f in ipairs(snapshot) do
            if f.events[key] and f.scripts.OnEvent then f.scripts.OnEvent(f, key, ...) end
        end
    end
    function h:tick(dt)
        self.now = self.now + dt
        local timers = self.timers; self.timers = {}
        for _, timer in ipairs(timers) do
            if timer.at <= self.now then timer.fn() else self.timers[#self.timers + 1] = timer end
        end
        for _, f in ipairs(self.frames) do
            if f.shown and f.scripts.OnUpdate then self.updates = self.updates + 1; f.scripts.OnUpdate(f, dt) end
        end
    end
    function h:seconds(n) for _ = 1, n * 10 do self:tick(0.1) end end
    h:event("ADDON_LOADED", "_FluxUI")
    h.mover = mover
    return h
end

-- Disabled at login: real module startup, delayed scans and addon events.
do
    local h = boot(false)
    local frames = h.db.frames
    h.module.OnEnable()
    h:event("PLAYER_ENTERING_WORLD")
    for _ = 1, 20 do h:event("ADDON_LOADED", "FixtureLOD") end
    h:seconds(6)
    print(("METRIC disabled_start catalog=%d resolves=%d hooks=%d polls=%d updates=%d attached=%d")
        :format(h.catalogCalls, h.resolves, h.hooks, h.polls, h.updates, h.mover.AttachedCount()))
    check(h.catalogCalls == 0, "disabled startup skips catalog discovery")
    check(h.resolves == 0 and h.hooks == 0, "disabled startup leaves native hooks alone")
    check(h.polls == 0 and h.updates == 0, "disabled startup has no panel polling")
    check(h.mover.AttachedCount() == 0, "disabled startup creates no attachments")
    check(h.db.frames == frames and frames.PlayerSpellsFrame.scale == 1.2, "disabled startup preserves saved records")
    -- Real options enable uses Refresh, not SetEnabled or another module start.
    h.options.enabled.set(nil, true)
    check(h.mover.AttachedCount() == 2, "options enable discovers panels after disabled login")
    check(h.character.scale == 1.1, "enable restores saved character scale")
    h:tick(0.1)
    check(h.panel.scale == 1.2, "enabled watcher restores saved spell panel scale")
end

-- Enabled behavior, suppression, combat recovery and repeated option cycles.
do
    local h = boot(true)
    h.module.OnEnable(); h:seconds(6)
    check(h.mover.AttachedCount() == 2, "enabled startup retains eligible attachments")
    check(h.character.scale == 1.1 and h.panel.scale == 1.2, "enabled startup retains saved scales")
    local frameCount, hookCount = #h.frames, h.hooks
    h.options.enabled.set(nil, false)
    local resolves, catalog, writes, polls, updates = h.resolves, h.catalogCalls, h.writes, h.polls, h.updates
    for _ = 1, 20 do h:event("ADDON_LOADED", "FixtureLOD") end
    h:seconds(10)
    print(("METRIC disabled_after_enable catalog=%d resolves=%d polls=%d updates=%d writes=%d")
        :format(h.catalogCalls - catalog, h.resolves - resolves, h.polls - polls, h.updates - updates, h.writes - writes))
    check(h.catalogCalls == catalog and h.resolves == resolves, "disabled options stop event-driven discovery")
    check(h.polls == polls and h.updates == updates, "disabled options disarm panel watcher")
    check(h.writes == writes, "disabled options perform no geometry writes")
    check(h.mover.AttachedCount() == 2, "existing attachments retained for reuse")
    for cycle = 1, 100 do
        h.panel.shown = false
        h.options.enabled.set(nil, true); h:tick(0.1)
        h.panel.shown = true; h:tick(0.1)
        check(h.panel.scale == 1.2, "re-enabled watcher keeps saved scale " .. cycle)
        h.options.enabled.set(nil, false)
        local before = h.polls; h:tick(0.1)
        check(h.polls == before, "cycle disables watcher " .. cycle)
    end
    check(#h.frames == frameCount and h.hooks == hookCount, "100 cycles reuse frames and permanent hooks")
    h.mover.SetEnabled(true)
    h.panel.shown = false; h:tick(0.1)
    h.combat = true; h.panel.shown = true
    local before = h.writes; h:tick(0.1)
    check(h.writes == before and h.deferred["windowmover.apply.PlayerSpellsFrame"], "protected panel defers scale in combat")
    h.mover.SetEnabled(false)
    h.combat = false; h.deferred["windowmover.apply.PlayerSpellsFrame"]()
    check(h.writes == before, "disabled state gates pending combat apply")
    h.mover.SetEnabled(true)
    check(h.panel.scale == 1.2, "reenable restores scale after combat deferral")
    print(("METRIC cycles frames=%d hooks=%d saved_scale=%.1f"):format(#h.frames, h.hooks, h.db.frames.PlayerSpellsFrame.scale))
end

-- Public SetEnabled(false) must stop the current scale gesture, like options.
do
    local h = boot(true)
    h.module.OnEnable(); h:seconds(6)
    h.character.scripts.OnMouseDown(h.character, "RightButton")
    h.cursor = 120; h:tick(0.1)
    local saved = h.db.frames.CharacterFrame.scale
    h.mover.SetEnabled(false)
    local polls, updates = h.polls, h.updates
    h.cursor = 160; h:seconds(1)
    print(("METRIC disabled_api polls=%d updates=%d saved_changes=%d")
        :format(h.polls - polls, h.updates - updates, h.db.frames.CharacterFrame.scale ~= saved and 1 or 0))
    check(h.db.frames.CharacterFrame.scale == saved, "public disable ends gesture before further saved writes")
    check(h.polls == polls and h.updates == updates, "public disable hides active driver and watcher")
end

print(("Window mover disabled: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
