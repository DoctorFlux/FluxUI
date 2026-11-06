-- Production meter integration with ordinary frame/timer mocks. This does not
-- emulate WoW's secure VM, secret values, rendering or native-client support.
-- Optional argument: alternate FluxBlizzardMeter.lua source for baseline replay.
local source = arg[1] or "Battlezonemap/FluxBlizzardMeter.lua"
-- Optional arg2 is an external pinned source prefix, e.g. .../forever.
-- Only the requested native methods are replayed; source is not bundled here.
local exportHarness = arg[2] == "--harness"
local nativePrefix = not exportHarness and arg[2] or nil
local nativeRoot, nativeSession
local function read(path)
    local f = assert(io.open(path, "r")); local text = f:read("*a"); f:close(); return text
end
if nativePrefix then
    nativeRoot = read(nativePrefix .. "-DamageMeter.lua")
    nativeSession = read(nativePrefix .. "-DamageMeterSessionWindow.lua")
end
local function nativeMethod(text, mixin, name)
    local start = assert(text:find("function " .. mixin .. ":" .. name .. "(", 1, true))
    local finish = text:find("\nfunction ", start + 1, true) or (#text + 1)
    return text:sub(start, finish - 1)
end
local checks, failures = 0, 0
local totals = { typeCalls = 0, sessionCalls = 0, entryWalks = 0 }
local gamepadPatchTimers = 0
local function check(value, message)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. message) end
end
local noop = function() end

local function harness(gamepad, policy, hasVisibilitySetter)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local s = { available = true, details = false, combat = false, activeTab = "Meter",
        frames = {}, timers = {}, timerCreates = 0, typeCalls = 0, sessionCalls = 0,
        classCalls = 0, iconCalls = 0, entryWalks = 0, points = 0, hooks = {}, windows = {},
        barHeightCalls = 0, barSpacingCalls = 0, rowRefreshes = 0, messages = {},
        visibility = policy or 0, policyWrites = 0, setterCalls = 0, rootShows = 0, savedSessions = {},
        timerDispatches = 0, timerWrites = 0, enabled = true, inGroup = false }
    local function geometryAfter(object, method, ...)
        for _, fn in ipairs(s.hooks[object] and s.hooks[object][method] or {}) do fn(object, ...) end
    end
    local function frame(parent)
        local f = { parent = parent, shown = true, scripts = {}, events = {}, hooks = {},
            width = 300, height = 270, scale = 1, points = {} }
        function f:IsShown() return self.shown end
        function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function f:Show()
            local changed = not self.shown; self.shown = true
            if changed then for _, fn in ipairs(self.hooks.OnShow or {}) do fn(self) end end
        end
        function f:Hide()
            local changed = self.shown; self.shown = false
            if changed then for _, fn in ipairs(self.hooks.OnHide or {}) do fn(self) end end
        end
        function f:SetShown(value) if value then self:Show() else self:Hide() end end
        function f:SetParent(value) self.parent = value; geometryAfter(self, "SetParent", value) end
        function f:GetParent() return self.parent end
        function f:GetWidth() return self.width end
        function f:GetHeight() return self.height end
        function f:GetSize() return self.width, self.height end
        function f:SetSize(w, h) self.width, self.height = w, h; geometryAfter(self, "SetSize", w, h) end
        function f:GetEffectiveScale() return self.scale end
        function f:SetScale(value) self.scale = value; geometryAfter(self, "SetScale", value) end
        function f:ClearAllPoints() self.points = {} end
        function f:SetPoint(...)
            self.points[#self.points + 1] = {...}; s.points = s.points + 1
            geometryAfter(self, "SetPoint", ...)
        end
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
    e.Enum = { DamageMeterVisibility = { Always = 0, InCombat = 1, Hidden = 2, InGroup = 3 },
        DamageMeterSessionType = { Overall = 0, Current = 1, Expired = 3 },
        DamageMeterType = { DamageDone = 0, HealingDone = 2, Dps = 1, Hps = 3 } }
    e.InCombatLockdown = function() return s.combat end
    e.UnitAffectingCombat = function() return s.combat end
    e.wipe = function(t) for key in pairs(t) do t[key] = nil end end
    e.SlashCmdList = {}
    e.print = function(...) s.messages[#s.messages + 1] = { ... } end
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
    -- Keep the native policy in a proxy so every addon write is observable,
    -- including the old fallback assignment. This is not a secure-VM emulator.
    setmetatable(dm, {
        __index = function(_, key) if key == "visibility" then return s.visibility end end,
        __newindex = function(t, key, value)
            if key == "visibility" then s.visibility = value; s.policyWrites = s.policyWrites + 1
            else rawset(t, key, value) end
        end,
    })
    local showFrame = dm.Show
    function dm:Show() s.rootShows = s.rootShows + 1; showFrame(self) end
    if hasVisibilitySetter then
        function dm:SetVisibility(value)
            s.setterCalls = s.setterCalls + 1; self.visibility = value
        end
    end
    function dm:IsEditing() return false end
    function dm:IsPlayerInCombat() return s.combat end
    function dm:IsPlayerInGroup() return s.inGroup end
    function dm:ShouldBeShown()
        if not s.enabled or not s.available then return false end
        local visibility = self.visibility
        if visibility == e.Enum.DamageMeterVisibility.InCombat then return s.combat end
        if visibility == e.Enum.DamageMeterVisibility.Hidden then return false end
        if visibility == e.Enum.DamageMeterVisibility.InGroup then return s.inGroup end
        return true
    end
    local updateShown = function(self)
        self:SetShown(self:ShouldBeShown()); self:UpdateSessionTimerState()
    end
    local updateTimers = function(self)
        self:ForEachSessionWindow(function(win) win:UpdateSessionTimerState() end)
    end
    function dm:OnEvent(event)
        if event == "PLAYER_IN_COMBAT_CHANGED" or event == "GROUP_JOINED" or event == "GROUP_LEFT"
            or event == "PLAYER_LEVEL_CHANGED" then self:UpdateShownState() end
    end
    if nativeRoot then
        e.DamageMeterMixin = {}
        e.CVarCallbackRegistry = { GetCVarValueBool = function() return s.enabled end }
        e.C_DamageMeter = { IsDamageMeterAvailable = function() return s.available end }
        local chunk = 'local DAMAGE_METER_ENABLED_CVAR = "damageMeterEnabled"\n'
        for _, name in ipairs({"ShouldBeShown", "UpdateShownState", "UpdateSessionTimerState", "OnEvent"}) do
            chunk = chunk .. nativeMethod(nativeRoot, "DamageMeterMixin", name) .. "\n"
        end
        assert(load(chunk, "@pinned native meter dispatch", "t", e))()
        dm.ShouldBeShown, dm.OnEvent = e.DamageMeterMixin.ShouldBeShown, e.DamageMeterMixin.OnEvent
        updateShown, updateTimers = e.DamageMeterMixin.UpdateShownState, e.DamageMeterMixin.UpdateSessionTimerState
    end
    function dm:UpdateShownState()
        updateShown(self); after(self, "UpdateShownState")
    end
    function dm:UpdateSessionTimerState()
        s.timerDispatches = s.timerDispatches + 1; updateTimers(self)
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
        -- Native SetSessionWindowSessionID persists this choice before SetSession.
        s.savedSessions[win] = { sessionType = value, sessionID = id }
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
        -- Native new window data inherits Overall/nil unless a saved choice exists.
        win.meterType, win.sessionType, win.sessionID = 0, e.Enum.DamageMeterSessionType.Overall, nil
        s.savedSessions[win] = { sessionType = win.sessionType }
        function win:GetDamageMeterType() return self.meterType end
        function win:GetSessionType() return self.sessionType end
        function win:GetSessionID() return self.sessionID end
        function win:GetBarHeight() return self.barHeight or 25 end
        function win:GetBarSpacing() return self.barSpacing or 4 end
        function win:SetBarHeight(height)
            assert(not s.combat, "bar height changes stay out of combat")
            s.barHeightCalls = s.barHeightCalls + 1; s.rowRefreshes = s.rowRefreshes + 1
            self.barHeight = height
            if self.sourceWindow then self.sourceWindow.barHeight = height end
        end
        function win:SetBarSpacing(spacing)
            assert(not s.combat, "bar spacing changes stay out of combat")
            s.barSpacingCalls = s.barSpacingCalls + 1; s.rowRefreshes = s.rowRefreshes + 1
            self.barSpacing = spacing
            if self.sourceWindow then self.sourceWindow.barSpacing = spacing end
        end
        win.background = { alpha = 0 }
        function win.background:SetAlpha(alpha) self.alpha = alpha end
        function win:GetBackground() return self.background end
        function win:GetBackgroundAlpha() return self.backgroundAlpha or 1 end
        function win:UpdateBackground()
            self:GetBackground():SetAlpha(self:GetBackgroundAlpha())
            after(self, "UpdateBackground")
        end
        function win:ShouldUseClassColor() return self.useClassColor end
        function win:SetUseClassColor(value) s.classCalls = s.classCalls + 1; self.useClassColor = value end
        function win:ShouldShowBarIcons() return self.showBarIcons end
        function win:SetShowBarIcons(value) s.iconCalls = s.iconCalls + 1; self.showBarIcons = value end
        win.SetSessionDuration = e.DamageMeterSessionWindowMixin.SetSessionDuration
        win.timerFont = { SetText = function(_, text)
            s.timerWrites = s.timerWrites + 1; win.timerText = text
        end }
        function win:GetSessionTimerFontString() return self.timerFont end
        function win:GetCombatSession() return { durationSeconds = 65 } end
        function win:IsPlayerInCombat() return s.combat end
        function win:SetOnUpdateReason(_, value) self.timerOnUpdate = value end
        function win:UpdateSessionTimerState()
            self.timerOnUpdate = s.combat
            self.timerFont:SetText(s.combat and "[01:05] " or "")
        end
        if nativeSession then
            e.DamageMeterSessionWindowMixin = {}
            e.SecondsToClock = function(seconds)
                return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
            end
            local start = assert(nativeSession:find("local function ShouldDisplaySessionTimer(", 1, true))
            local finish = assert(nativeSession:find("\nfunction DamageMeterSessionWindowMixin:IsPlayerInCombat(", start, true))
            local chunk = nativeSession:sub(start, finish - 1)
            for _, name in ipairs({"SetSessionDuration", "ShowSessionTimerFromCombatSession", "ShowSessionTimer",
                "ClearSessionTimer", "UpdateSessionTimerState"}) do
                chunk = chunk .. nativeMethod(nativeSession, "DamageMeterSessionWindowMixin", name) .. "\n"
            end
            assert(load(chunk, "@pinned native session timer", "t", e))()
            for name, fn in pairs(e.DamageMeterSessionWindowMixin) do win[name] = fn end
        end
        win.entry = entry(true)
        function win:ForEachEntryFrame(fn) s.entryWalks = s.entryWalks + 1; fn(self.entry) end
        function win:InitEntry(row, data)
            e.DamageMeterSourceEntryMixin.Init(row, data)
            after(self, "InitEntry", row, data)
        end
        win.sourceWindow = frame(win)
        win.sourceWindow.background = { alpha = 0 }
        function win.sourceWindow:GetBackground() return self.background end
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
    s.windows[2].meterType = 2 -- A user-configured native Healing window.
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

if exportHarness then return harness end

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
    s.windows[1].meterType = 1 -- Native menu choice, not an addon writer.
    local beforeType = s.typeCalls
    meter:SyncGeometryFromLayout(layout)
    check(s.windows[1].meterType == 1 and s.typeCalls == beforeType,
        label .. " changed layout uses the native-selected type without writing it")
    s.windows[1].meterType, s.windows[1].sessionType, s.windows[1].sessionID = 3, 2, 72
    beforeType = s.typeCalls; local beforeSession = s.sessionCalls
    meter:RefreshEmbeddedLayout()
    check(s.windows[1].meterType == 3 and s.windows[1].sessionType == 2
        and s.windows[1].sessionID == 72 and s.typeCalls == beforeType
        and s.sessionCalls == beforeSession and meter:GetLayoutStatus().configurationRequired,
        label .. " missing requested type preserves native choices and reports configuration")
    s.windows[1].meterType = 1
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

for _, gamepad in ipairs({ false, true }) do
    for _, choice in ipairs({ "current", "historical", "overall" }) do
        local e, s = harness(gamepad)
        local meter, win = e.FluxBlizzardMeter, s.windows[1]
        local selectedType = choice == "current" and e.Enum.DamageMeterSessionType.Current
            or choice == "overall" and e.Enum.DamageMeterSessionType.Overall or nil
        local selectedID = choice == "historical" and 42 or nil
        s.dm:SetSessionWindowSessionID(win, selectedType, selectedID)
        s.sessionCalls = 0
        local label = (gamepad and "gamepad " or "ordinary ") .. choice
        local function retained(stage)
            local saved = s.savedSessions[win]
            check(win.sessionType == selectedType and win.sessionID == selectedID
                and saved.sessionType == selectedType and saved.sessionID == selectedID,
                label .. " retains native and saved session through " .. stage)
            check(s.sessionCalls == 0, label .. " makes no session-setting writes through " .. stage)
        end
        local layout = { topSlots = {{ kind = "blizzard", damageMeterType = 0 }},
            bottomSlots = {{ kind = "blizzard", damageMeterType = 2 }} }
        check(meter:Embed(s.host, layout), label .. " embeds with its existing selection")
        retained("embed")
        for _ = 1, 500 do meter:RefreshEmbeddedLayout() end
        retained("500 relayouts")
        s.activeTab = "Map"; meter:Hide(); s.activeTab = "Meter"; meter:Show(); s.drain()
        retained("tab hide and reveal")
        layout.topSlots[1].damageMeterType = 1
        win.meterType = 1
        meter:SyncGeometryFromLayout(layout)
        check(win.meterType == 1, label .. " still follows an explicit display-type layout change")
        retained("display-type change")
        s.combat = true; check(not meter:Embed(s.host, layout), label .. " defers combat layout")
        s.combat = false; s.event("PLAYER_REGEN_ENABLED"); s.drain()
        retained("combat-deferred layout")
        meter:Cleanup(); meter:Embed(s.host, layout); s.drain()
        retained("cleanup and re-embed")
        check(s.windows[2].sessionType == e.Enum.DamageMeterSessionType.Overall and s.windows[2].sessionID == nil,
            label .. " preserves the native Overall default of another pane")
    end
end

local visibilityTotals = { writes = 0, setters = 0, nativeEvents = 0, timerDispatches = 0,
    redundantShows = 0, timerWrites = 0 }
local function visibilityFixture(policy, setter)
    local e, s = harness(false, policy, setter)
    local meter = e.FluxBlizzardMeter
    local layout = { topSlots = {{kind = "blizzard", damageMeterType = 0}}, bottomSlots = {} }
    local label = "policy=" .. policy .. " setter=" .. tostring(setter)
    check(meter:Embed(s.host, layout), label .. " embeds")
    check(s.visibility == policy and s.policyWrites == 0 and s.setterCalls == 0,
        label .. " addon leaves native visibility ownership untouched")
    check(s.dm:IsShown() == (policy == 0), label .. " out-of-combat native policy retained")
    local events, dispatches = 0, s.timerDispatches
    local function event(name)
        events = events + 1; s.dm:OnEvent(name)
    end
    s.combat = true; event("PLAYER_IN_COMBAT_CHANGED")
    check(s.dm:IsShown() == (policy == 0 or policy == 1), label .. " native combat visibility")
    check(s.windows[1].timerText == "[01:05] " and s.windows[1].timerOnUpdate,
        label .. " native combat timer still renders and updates")
    for _ = 1, 500 do event("PLAYER_IN_COMBAT_CHANGED") end
    check(s.policyWrites == 0 and s.visibility == policy,
        label .. " repeated native combat dispatch reads unmodified policy")
    check(s.timerDispatches == dispatches + events, label .. " each native event retains one timer dispatch")
    local frameCount, timerCount = #s.frames, s.timerCreates
    local shows = s.rootShows
    for _ = 1, 500 do meter:Show() end
    local repeatedShows = s.rootShows - shows
    check(s.rootShows == shows and s.timerDispatches == dispatches + events,
        label .. " repeated addon Show neither re-shows root nor invokes native timer")
    check(#s.frames == frameCount and s.timerCreates == timerCount,
        label .. " repeated Show adds no frames or timers")
    s.activeTab = "Map"; meter:Hide(); event("PLAYER_IN_COMBAT_CHANGED")
    check(not s.dm:IsShown(), label .. " native combat event respects inactive Flux tab")
    meter:Show(); check(not s.dm:IsShown(), label .. " explicit Show respects inactive Flux tab")
    s.activeTab = "Meter"; s.host.shown = false; meter:Show()
    check(not s.dm:IsShown(), label .. " explicit Show respects hidden Flux host")
    s.host.shown = true; meter:Show()
    check(s.dm:IsShown() == (policy == 0 or policy == 1), label .. " active combat tab can reopen under native policy")
    s.combat = false; event("PLAYER_IN_COMBAT_CHANGED")
    check(s.dm:IsShown() == (policy == 0), label .. " native combat exit restores configured policy")
    check(s.windows[1].timerText == "" and not s.windows[1].timerOnUpdate,
        label .. " native combat exit clears timer normally")
    s.inGroup = true; event("GROUP_JOINED")
    check(s.dm:IsShown() == (policy == 0 or policy == 3), label .. " native group policy remains available")
    s.enabled = false; meter:Show()
    check(not s.dm:IsShown(), label .. " native disabled setting remains effective")
    s.enabled = true; s.available = false; meter:Show()
    check(not s.dm:IsShown(), label .. " unavailable native content remains hidden")
    check(s.nativeMethodsIntact(), label .. " visibility and timer functions remain unchanged")
    visibilityTotals.writes = visibilityTotals.writes + s.policyWrites
    visibilityTotals.setters = visibilityTotals.setters + s.setterCalls
    visibilityTotals.nativeEvents = visibilityTotals.nativeEvents + events
    visibilityTotals.timerDispatches = visibilityTotals.timerDispatches + s.timerDispatches
    visibilityTotals.redundantShows = visibilityTotals.redundantShows + repeatedShows
    visibilityTotals.timerWrites = visibilityTotals.timerWrites + s.timerWrites
end
for policy = 0, 3 do
    visibilityFixture(policy, false)
    visibilityFixture(policy, true)
end
print(string.format("meter visibility: policyWrites=%d setterCalls=%d nativeEvents=%d timerDispatches=%d repeatedAddonRootShows=%d timerWrites=%d pinnedNative=%s",
    visibilityTotals.writes, visibilityTotals.setters, visibilityTotals.nativeEvents,
    visibilityTotals.timerDispatches, visibilityTotals.redundantShows, visibilityTotals.timerWrites,
    tostring(nativePrefix ~= nil)))

-- Shared paint follows native configuration and later native alpha refreshes.
local backgroundTotals = { updates = 0, skins = 0 }
local function backgroundFixture(gamepad)
    local e, s = harness(gamepad)
    local meter, paints = e.FluxBlizzardMeter, 0
    local released = 0
    local assetsReady, entriesBeforeAssets, entryPaints = false, 0, 0
    e.FluxMeterSkin = {
        ApplyToEntry = function()
            entryPaints = entryPaints + 1
            if not assetsReady then entriesBeforeAssets = entriesBeforeAssets + 1 end
        end,
        ApplyToWindow = function(_, window, scale)
            assetsReady = true
            paints = paints + 1
            s.skinScaleValid = s.skinScaleValid ~= false and scale == .8
            window:GetBackground().alpha = 1
            window:GetBackground().paint = "Flux"
            local session = window.GetSessionID and window or window:GetParent()
            window.configuredAtPaint = session.meterType ~= nil and session.sessionType == 0
                and session.useClassColor == nil and session.showBarIcons == nil
        end,
        ReleaseAllNative = function() released = released + 1 end,
    }
    local layout = { topSlots = {{kind = "blizzard", damageMeterType = 0}},
        bottomSlots = {{kind = "blizzard", damageMeterType = 2}} }
    check(meter:Embed(s.host, layout), "background fixture embeds")
    check(entryPaints > 0 and entriesBeforeAssets == 0,
        "owned window establishes asset availability before existing pooled entries are styled")
    for _, win in ipairs(s.windows) do
        check(win.configuredAtPaint and win.sourceWindow.configuredAtPaint,
            "native session and source receive paint without rewriting native display flags")
        check(#(s.hooks[win] and s.hooks[win].UpdateBackground or {}) == 1,
            "one native background posthook is installed per session")
        check(not (s.hooks[win.sourceWindow] and s.hooks[win.sourceWindow].UpdateBackground),
            "source windows without UpdateBackground receive no invented method hook")
    end
    local frames, timers, types, sessions, walks = #s.frames, s.timerCreates, s.typeCalls, s.sessionCalls, s.entryWalks
    local before = paints
    for _ = 1, 500 do
        for _, win in ipairs(s.windows) do win.backgroundAlpha = 0; win:UpdateBackground() end
    end
    check(paints == before + 1000 and s.windows[1]:GetBackground().alpha == 1 and s.windows[2]:GetBackground().alpha == 1,
        "late native alpha refreshes regain shared presentation")
    check(#s.frames == frames and s.timerCreates == timers and s.typeCalls == types
        and s.sessionCalls == sessions and s.entryWalks == walks and s.policyWrites == 0,
        "background posthooks add no frames timers entry scans or native content/policy writes")
    check(s.skinScaleValid, "native shared skin retains accepted presentation scale")
    check(s.nativeMethodsIntact(), "background styling retains native method identities")
    s.details = true; before = paints; s.windows[1]:UpdateBackground()
    check(paints == before and s.windows[1]:GetBackground().alpha == 0, "Details availability immediately stops native skin callbacks")
    meter:Hide(); s.details = false; s.windows[1]:UpdateBackground()
    check(paints == before and released == 1, "Details handoff retires active skin membership")
    meter:Embed(s.host, layout); before = paints; s.windows[1]:UpdateBackground()
    check(paints == before + 1 and #(s.hooks[s.windows[1]].UpdateBackground or {}) == 1,
        "re-embed resumes one existing background hook")
    meter:Cleanup(); before = paints; s.windows[1]:UpdateBackground()
    check(paints == before and s.windows[1]:GetBackground().alpha == 0,
        "cleanup stops permanent background hooks from repainting released windows")
    meter:Embed(s.host, layout); before = paints; s.windows[1]:UpdateBackground()
    check(paints == before + 1 and #(s.hooks[s.windows[1]].UpdateBackground or {}) == 1,
        "cleanup and re-embed keep background hook registration bounded")
    check(s.nativeMethodsIntact(), "background handoff never replaces a native method")
    backgroundTotals.updates = backgroundTotals.updates + 1000
    backgroundTotals.skins = backgroundTotals.skins + paints
end
backgroundFixture(false); backgroundFixture(true)
print(string.format("native backgrounds: updates=%d skinCalls=%d", backgroundTotals.updates, backgroundTotals.skins))

-- SwitchToTab runs the previous onHide before it changes GetActiveTab().
local tabHideTotals = { cycles = 0, threatResurrections = 0, rootResurrections = 0 }
local function tabHideFixture(gamepad, threatOnly, policy)
    local e, s = harness(gamepad, policy)
    local meter = e.FluxBlizzardMeter
    local threat = e.CreateFrame("Frame"); threat:Hide()
    e.FluxThreatMeter = {
        IsAvailable = function() return not s.details end,
        GetFrame = function() return threat end,
        Embed = function(_, host, scale) threat:SetParent(host); threat:SetScale(scale); return threat end,
        RefreshLayout = noop,
        Show = function() if s.activeTab == "Meter" and s.host:IsVisible() then threat:Show() else threat:Hide() end end,
        Hide = function() threat:Hide() end,
        Cleanup = function() threat:Hide() end,
    }
    local slot = { kind = "plugin", plugin = "DETAILS_PLUGIN_FLUX_THREAT" }
    local layout = { topSlots = threatOnly and {slot} or {{kind = "blizzard", damageMeterType = 0}},
        bottomSlots = threatOnly and {} or {slot} }
    local label = "tab hide gamepad=" .. tostring(gamepad) .. " threatOnly=" .. tostring(threatOnly) .. " policy=" .. policy
    check(meter:Embed(s.host, layout) and threat:IsShown(), label .. " owned threat starts visible")
    check(s.dm:IsShown() == (not threatOnly and policy == 0), label .. " native visibility remains independent")
    -- Native-reproduced ordering: activeTab and Content are still Meter/visible.
    meter:Hide()
    check(not s.dm:IsShown() and not threat:IsShown(), label .. " onHide hides both panes before activeTab changes")
    s.dm:UpdateShownState()
    check(not s.dm:IsShown() and not threat:IsShown(), label .. " native refresh cannot undo explicit Hide during tab transition")
    s.activeTab = "Map"; s.dm:UpdateShownState()
    check(not s.dm:IsShown() and not threat:IsShown(), label .. " panes remain hidden after the tab changes")
    s.activeTab = "Meter"; meter:Show()
    check(threat:IsShown() and s.dm:IsShown() == (not threatOnly and policy == 0), label .. " explicit Show restores the selected panes")
    local frames, timers, types, sessions = #s.frames, s.timerCreates, s.typeCalls, s.sessionCalls
    for _ = 1, 500 do
        meter:Hide(); s.dm:UpdateShownState()
        if threat:IsShown() then tabHideTotals.threatResurrections = tabHideTotals.threatResurrections + 1 end
        if s.dm:IsShown() then tabHideTotals.rootResurrections = tabHideTotals.rootResurrections + 1 end
        s.activeTab = "Map"; s.dm:UpdateShownState()
        s.activeTab = "Meter"; meter:Show()
        tabHideTotals.cycles = tabHideTotals.cycles + 1
    end
    check(#s.frames == frames and s.timerCreates == timers and s.typeCalls == types and s.sessionCalls == sessions,
        label .. " repeated tab transitions reuse frames without timers or content rebuilds")
    check(#(s.hooks[s.dm] and s.hooks[s.dm].UpdateShownState or {}) == 1 and s.nativeMethodsIntact(),
        label .. " transitions retain one posthook and all native functions")
    meter:Hide(); meter:Embed(s.host, layout)
    check(threat:IsShown() and s.dm:IsShown() == (not threatOnly and policy == 0), label .. " a new Embed resumes explicit display")
    s.details = true; meter:Hide(); s.dm:UpdateShownState()
    check(not threat:IsShown() and not s.dm:IsShown(), label .. " Details handoff leaves owned threat hidden")
    meter:Cleanup(); s.details = false; s.dm:UpdateShownState()
    check(not threat:IsShown() and s.dm:IsShown() == (policy == 0), label .. " cleanup releases native ownership without restoring owned threat")
    meter:Embed(s.host, layout)
    check(threat:IsShown(), label .. " re-embed after cleanup restores owned threat")
end
for _, gamepad in ipairs({false, true}) do
    for _, threatOnly in ipairs({false, true}) do
        for _, policy in ipairs({0, 2}) do tabHideFixture(gamepad, threatOnly, policy) end
    end
end
check(tabHideTotals.threatResurrections == 0 and tabHideTotals.rootResurrections == 0,
    "explicit Hide prevents all repeated pane resurrections before activeTab changes")
print(string.format("meter tab transitions: cycles=%d threatResurrections=%d rootResurrections=%d",
    tabHideTotals.cycles, tabHideTotals.threatResurrections, tabHideTotals.rootResurrections))

for _, client in ipairs({"retail", "forever", "era", "anniversary", "mists"}) do
    -- Capability fixtures exercise shared code; labels do not certify that a
    -- client ships this Blizzard module. Each also checks the absent backend.
    fixture(client, false, true)
end
fixture("forever-gamepad", true, false)
print(string.format("native meter ownership: %d checks, %d failures; geometry typeCalls=%d sessionCalls=%d entryWalks=%d gamepadPatchTimers=%d",
    checks, failures, totals.typeCalls, totals.sessionCalls, totals.entryWalks, gamepadPatchTimers))
if failures > 0 then os.exit(1) end
