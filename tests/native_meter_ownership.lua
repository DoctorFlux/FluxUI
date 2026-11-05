-- Production meter integration with ordinary frame/timer mocks. This does not
-- emulate WoW's secure VM, secret values, rendering or native-client support.
-- Optional argument: alternate FluxBlizzardMeter.lua source for baseline replay.
local source = arg[1] or "Battlezonemap/FluxBlizzardMeter.lua"
local checks, failures = 0, 0
local totals = { typeCalls = 0, sessionCalls = 0, entryWalks = 0 }
local gamepadPatchTimers = 0
local function check(value, message)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. message) end
end
local noop = function() end

local function harness(gamepad)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local s = { available = true, details = false, combat = false, activeTab = "Meter",
        frames = {}, timers = {}, timerCreates = 0, typeCalls = 0, sessionCalls = 0,
        classCalls = 0, iconCalls = 0, entryWalks = 0, points = 0, hooks = {}, windows = {} }
    local function frame(parent)
        local f = { parent = parent, shown = true, scripts = {}, events = {}, hooks = {},
            width = 300, height = 270, scale = 1, points = {} }
        function f:IsShown() return self.shown end
        function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:SetParent(value) self.parent = value end
        function f:GetParent() return self.parent end
        function f:GetWidth() return self.width end
        function f:GetHeight() return self.height end
        function f:GetSize() return self.width, self.height end
        function f:SetSize(w, h) self.width, self.height = w, h end
        function f:GetEffectiveScale() return self.scale end
        function f:SetScale(value) self.scale = value end
        function f:ClearAllPoints() self.points = {} end
        function f:SetPoint(...) self.points[#self.points + 1] = {...}; s.points = s.points + 1 end
        function f:GetFrameStrata() return "MEDIUM" end
        function f:GetFrameLevel() return 10 end
        f.SetFrameStrata, f.SetFrameLevel, f.SetMovable, f.SetResizable = noop, noop, noop, noop
        function f:HookScript(event, fn)
            self.hooks[event] = self.hooks[event] or {}
            table.insert(self.hooks[event], fn)
        end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        return f
    end
    e.UIParent = frame()
    s.host = frame(e.UIParent)
    e.FluxWindowFrame = { GetActiveTab = function() return s.activeTab end,
        frame = { Content = s.host } }
    e.FluxMeterLayout = { HasBlizzardDamageMeterClient = function() return s.available end,
        IsDetailsAddonLoaded = function() return s.details end }
    e.Flux = { Cap = { IsForeverGamepadUI = function() return gamepad end } }
    e.Enum = { DamageMeterVisibility = { Always = 0 }, DamageMeterSessionType = { Overall = 0 },
        DamageMeterType = { DamageDone = 0, HealingDone = 2, Dps = 1, Hps = 3 } }
    e.InCombatLockdown = function() return s.combat end
    e.UnitAffectingCombat = function() return s.combat end
    e.wipe = function(t) for key in pairs(t) do t[key] = nil end end
    e.SlashCmdList = {}
    e.CreateFrame = function()
        local f = frame(); s.frames[#s.frames + 1] = f; return f
    end
    e.C_Timer = { After = function(delay, fn)
        s.timerCreates = s.timerCreates + 1
        s.timers[#s.timers + 1] = { delay = delay, fn = fn }
    end }
    e.hooksecurefunc = function(target, method, fn)
        -- Model an after-only hook separately: the original method stays native.
        s.hooks[target] = s.hooks[target] or {}
        s.hooks[target][method] = s.hooks[target][method] or {}
        table.insert(s.hooks[target][method], fn)
    end
    local function after(target, method, ...)
        for _, fn in ipairs(s.hooks[target] and s.hooks[target][method] or {}) do fn(target, ...) end
    end
    e.GREEN_FONT_COLOR = { r = 0, g = 1, b = 0 }
    e.DamageMeterEntryMixin = { GetSourceTypeAtlasElement = function() return "native" end,
        UpdateName = function() end, UpdateValue = function() end, UpdateStatusBar = function() end,
        GetDesiredBarColor = function() return "native" end }
    e.DamageMeterSourceEntryMixin = { Init = function(entry, data)
        entry.isLocalPlayer = data.isLocalPlayer; entry:UpdateName()
    end }
    e.DamageMeterSpellEntryMixin = { Init = function(entry)
        entry.isLocalPlayer = false; entry:UpdateName()
    end }
    e.DamageMeterSessionWindowMixin = { SetSessionDuration = function() end }
    local dm = frame(e.UIParent); e.DamageMeter = dm; s.dm = dm
    function dm:ShouldBeShown() return true end
    function dm:UpdateShownState()
        if self:ShouldBeShown() then self:Show() else self:Hide() end
        after(self, "UpdateShownState")
    end
    function dm:GetPrimarySessionWindow() return s.windows[1] end
    function dm:GetSessionWindow(index) return s.windows[index] end
    function dm:GetWindowDataList() return s.windows end
    function dm:GetMaxSessionWindowCount() return 3 end
    function dm:GetCurrentSessionWindowCount()
        local count = 0
        for _, win in ipairs(s.windows) do if win:IsShown() then count = count + 1 end end
        return count
    end
    function dm:ForEachSessionWindow(fn) for _, win in ipairs(s.windows) do fn(win) end end
    function dm:SetSessionWindowDamageMeterType(win, value)
        s.typeCalls = s.typeCalls + 1; win.meterType = value
    end
    function dm:SetSessionWindowSessionID(win, value, id)
        s.sessionCalls = s.sessionCalls + 1; win.sessionType, win.sessionID = value, id
    end
    dm.SetSessionWindowLocked, dm.SetSessionWindowMinimized = noop, noop
    function dm:CanHideSessionWindow(win) return win ~= s.windows[1] end
    function dm:HideSessionWindow(win) win:Hide() end
    function dm:CanShowNewSecondarySessionWindow() return #s.windows < 3 end
    local function entry(localPlayer)
        local value = { isLocalPlayer = localPlayer, font = {} }
        for name, fn in pairs(e.DamageMeterEntryMixin) do value[name] = fn end
        function value.font:SetTextColor(r, g, b) self.r, self.g, self.b = r, g, b end
        function value.font:SetText(text) self.text = text end
        function value:GetName() return self.font end
        function value:GetNameText() return "Synthetic row" end
        return value
    end
    local function window()
        local win = frame(dm)
        win.meterType, win.sessionType, win.sessionID = 0, 1, 99
        function win:GetDamageMeterType() return self.meterType end
        function win:GetSessionType() return self.sessionType end
        function win:GetSessionID() return self.sessionID end
        function win:ShouldUseClassColor() return self.useClassColor end
        function win:SetUseClassColor(value) s.classCalls = s.classCalls + 1; self.useClassColor = value end
        function win:ShouldShowBarIcons() return self.showBarIcons end
        function win:SetShowBarIcons(value) s.iconCalls = s.iconCalls + 1; self.showBarIcons = value end
        win.SetSessionDuration = e.DamageMeterSessionWindowMixin.SetSessionDuration
        win.entry = entry(true)
        function win:ForEachEntryFrame(fn) s.entryWalks = s.entryWalks + 1; fn(self.entry) end
        function win:InitEntry(row, data)
            e.DamageMeterSourceEntryMixin.Init(row, data)
            after(self, "InitEntry", row, data)
        end
        win.sourceWindow = frame(win)
        win.sourceWindow.entry = entry(false)
        function win.sourceWindow:ForEachEntryFrame(fn) s.entryWalks = s.entryWalks + 1; fn(self.entry) end
        function win.sourceWindow:InitEntry(row, data)
            e.DamageMeterSpellEntryMixin.Init(row, data)
            after(self, "InitEntry", row, data)
        end
        function win:GetSourceWindow() return self.sourceWindow end
        return win
    end
    function dm:ShowNewSecondarySessionWindow() s.windows[#s.windows + 1] = window() end
    s.windows[1], s.windows[2] = window(), window()
    s.originals = {}
    for _, object in ipairs({e.DamageMeterEntryMixin, e.DamageMeterSourceEntryMixin,
            e.DamageMeterSpellEntryMixin, e.DamageMeterSessionWindowMixin, dm,
            s.windows[1], s.windows[1].entry, s.windows[1].sourceWindow,
            s.windows[1].sourceWindow.entry}) do
        local saved = {}
        for name, fn in pairs(object) do if type(fn) == "function" then saved[name] = fn end end
        s.originals[object] = saved
    end
    function s.nativeMethodsIntact()
        for object, names in pairs(s.originals) do
            for name, fn in pairs(names) do if object[name] ~= fn then return false end end
        end
        return true
    end
    function s.event(event, value)
        for _, f in ipairs(s.frames) do
            if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, value) end
        end
    end
    function s.drain()
        local limit = 30
        while #s.timers > 0 do
            limit = limit - 1; assert(limit > 0, "bounded meter fixture timers")
            local pending = s.timers; s.timers = {}
            for _, timer in ipairs(pending) do timer.fn() end
        end
    end
    assert(loadfile(source, "t", e))("_FluxUI", { Flux = e.Flux })
    return e, s
end

local function fixture(label, gamepad, measure)
    local e, s = harness(gamepad)
    local meter = e.FluxBlizzardMeter
    s.event("ADDON_LOADED", "Blizzard_DamageMeter"); s.drain()
    if gamepad then gamepadPatchTimers = s.timerCreates end
    check(s.nativeMethodsIntact(), label .. " addon load retains native methods")
    check(s.timerCreates == 0, label .. " addon load creates no patch retry timers")
    local layout = { topSlots = {{kind = "blizzard", damageMeterType = 0}},
        bottomSlots = {{kind = "blizzard", damageMeterType = 2}},
        topColFracs = {1}, bottomColFracs = {1}, topRowFrac = .6 }
    check(meter:Embed(s.host, layout), label .. " embeds existing native windows")
    check(s.nativeMethodsIntact(), label .. " embed retains entry/init/duration/visibility methods")
    check(s.windows[2].meterType == 2 and s.windows[1].sessionType == 0,
        label .. " initial pane type and Overall selection retained")
    local player, other = s.windows[1].entry, s.windows[1].sourceWindow.entry
    check(player.font.r == 0 and player.font.g == 1 and player.font.b == 0,
        label .. " already pooled local-player names retain green")
    check(other.font.r == 1 and other.font.g == 1 and other.font.b == 1,
        label .. " already pooled other names retain white")
    s.windows[1]:InitEntry(player, { isLocalPlayer = false })
    check(player.font.r == 1 and player.font.g == 1 and player.font.b == 1,
        label .. " native row reuse restyles after native initialization")
    s.windows[1]:InitEntry(player, { isLocalPlayer = true })
    check(player.font.r == 0 and player.font.g == 1 and player.font.b == 0,
        label .. " newly initialized local-player names regain green")
    local points = s.points
    s.typeCalls, s.sessionCalls, s.entryWalks = 0, 0, 0
    for i = 1, 100 do
        if i % 2 == 1 then
            meter:RefreshEmbeddedLayout()
        else
            s.host.width = 300 + i
            for _, fn in ipairs(s.host.hooks.OnSizeChanged or {}) do fn(s.host) end
        end
    end
    check(s.typeCalls == 0 and s.sessionCalls == 0, label .. " geometry avoids native content rebuilds")
    check(s.entryWalks == 0, label .. " geometry does not walk native entry pools")
    check(s.points > points and s.dm.scale == .8 and s.windows[1].scale == 1,
        label .. " geometry and accepted scales still update")
    if measure then for key in pairs(totals) do totals[key] = totals[key] + s[key] end end
    layout.topSlots[1].damageMeterType = 1
    local beforeType = s.typeCalls
    meter:SyncGeometryFromLayout(layout)
    check(s.windows[1].meterType == 1 and s.typeCalls == beforeType + 1,
        label .. " changed layout applies one native type change")
    s.windows[1].meterType, s.windows[1].sessionType, s.windows[1].sessionID = 3, 2, 72
    beforeType = s.typeCalls; local beforeSession = s.sessionCalls
    meter:RefreshEmbeddedLayout()
    check(s.windows[1].meterType == 1 and s.windows[1].sessionType == 0
        and s.windows[1].sessionID == nil and s.typeCalls == beforeType + 1
        and s.sessionCalls == beforeSession + 1, label .. " native menu changes reconcile with Flux layout")
    s.activeTab = "Map"; meter:Hide(); s.dm:UpdateShownState()
    check(not s.dm:IsShown(), label .. " native visibility event keeps inactive Meter tab hidden")
    s.host.shown = false; s.activeTab = "Meter"; s.dm:UpdateShownState()
    check(not s.dm:IsShown(), label .. " native visibility event keeps hidden Flux host hidden")
    s.host.shown = true; s.activeTab = "Meter"
    beforeType, beforeSession = s.typeCalls, s.sessionCalls
    meter:Show(); meter:Embed(s.host, layout)
    check(s.dm:IsShown() and s.typeCalls == beforeType and s.sessionCalls == beforeSession,
        label .. " reopen retains current content without extra rebuilds")
    check(s.nativeMethodsIntact(), label .. " reopen retains native methods")
    check(#(s.hooks[s.windows[1]] and s.hooks[s.windows[1]].InitEntry or {}) == 1
        and #(s.hooks[s.windows[1].sourceWindow] and s.hooks[s.windows[1].sourceWindow].InitEntry or {}) == 1,
        label .. " row-style hooks do not multiply across re-embed")
    local hooks = s.hooks[s.dm] and s.hooks[s.dm].UpdateShownState or {}
    check(#hooks == 1, label .. " native visibility posthook installed once")
    s.combat = true; beforeType, beforeSession = s.typeCalls, s.sessionCalls
    check(not meter:Embed(s.host, layout), label .. " combat embed defers")
    meter:RefreshEmbeddedLayout(); meter:SyncGeometryFromLayout(layout)
    check(s.typeCalls == beforeType and s.sessionCalls == beforeSession and #s.timers == 0,
        label .. " combat geometry defers without polling")
    s.combat = false; s.event("PLAYER_REGEN_ENABLED")
    check(meter:IsEmbedded() and s.nativeMethodsIntact(), label .. " deferred embed recovers after combat")
    meter:Cleanup(); s.dm:UpdateShownState()
    check(s.dm:IsShown() and not meter:IsEmbedded(), label .. " cleanup releases native visibility ownership")
    player.font:SetTextColor(.5, .5, .5)
    s.windows[1]:InitEntry(player, { isLocalPlayer = true })
    check(player.font.r == .5 and player.font.g == .5 and player.font.b == .5,
        label .. " native rows stop Flux styling after cleanup")
    check(s.nativeMethodsIntact(), label .. " cleanup never restores addon replacements")

    for _, unavailable in ipairs({"absent", "Details"}) do
        local x, state = harness(gamepad)
        state.available, state.details = unavailable ~= "absent", unavailable == "Details"
        check(not x.FluxBlizzardMeter:Embed(state.host, layout), label .. " " .. unavailable .. " backend declines")
        state.event("ADDON_LOADED", "Blizzard_DamageMeter"); state.drain()
        check(state.nativeMethodsIntact() and state.typeCalls == 0 and state.sessionCalls == 0
            and state.timerCreates == 0, label .. " " .. unavailable .. " path leaves native renderer inert")
    end
end

for _, client in ipairs({"retail", "forever", "era", "anniversary", "mists"}) do
    -- Capability fixtures exercise shared code; labels do not certify that a
    -- client ships this Blizzard module. Each also checks the absent backend.
    fixture(client, false, true)
end
fixture("forever-gamepad", true, false)
print(string.format("native meter ownership: %d checks, %d failures; geometry typeCalls=%d sessionCalls=%d entryWalks=%d gamepadPatchTimers=%d",
    checks, failures, totals.typeCalls, totals.sessionCalls, totals.entryWalks, gamepadPatchTimers))
if failures > 0 then os.exit(1) end
