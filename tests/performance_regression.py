"""Run with Python + lupa (Lua 5.1). Executes production functions with WoW mocks."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def source(name):
    return (ROOT / name).read_text(encoding="utf-8-sig")


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute("""
        now = 10
        function GetTime() return now end
        timers = {}
        C_Timer = {}
        function C_Timer.NewTimer(delay, fn)
            local t = { due = now + delay, fn = fn }
            function t:Cancel() self.cancelled = true end
            timers[#timers + 1] = t
            return t
        end
        C_Timer.NewTicker = C_Timer.NewTimer
        function Advance(t)
            now = t
            for _, timer in ipairs(timers) do
                if not timer.cancelled and not timer.fired and timer.due <= now then
                    timer.fired = true
                    timer.fn()
                end
            end
        end
    """)
    return lua


def test_auras():
    lua = runtime()
    text = source("UnitFrames/FluxUnitFrames_Auras.lua")
    block = text[text.index("local function CancelAuraDebounce("):text.index("-- Refresh dispel overlays")]
    lua.execute("""
        local UNIT_AURA_DEBOUNCE_SEC = 0.1
        refreshes = 0
        function UnitExists() return true end
        local function RefreshFrameAuras() refreshes = refreshes + 1 end
    """ + block + "\nrequest = RequestAuraRefreshThrottled; cancel = CancelAuraDebounce")
    lua.execute("""
        frame = {unit = 'target'}
        request(frame, 'target')
        assert(refreshes == 1)
        now = 10.01
        for i = 1, 100 do request(frame, 'target') end
        assert(#timers == 1, 'burst must allocate only one timer')
        Advance(10.11)
        assert(refreshes == 2 and not frame._fluxAuraDebounceHandle)
        now = 10.12
        request(frame, 'target')
        cancel(frame)
        Advance(10.3)
        assert(refreshes == 2, 'cancelled work must not refresh after disable')
        request(frame, 'target')
        now = 10.31
        request(frame, 'target')
        frame.unit = 'focus'
        Advance(10.42)
        assert(refreshes == 3, 'old unit must not refresh a reassigned frame')
        frame.unit = 'target'
        now = 10.43
        request(frame, 'target')
        now = 10.44
        request(frame, 'target')
        now = 10.6 -- event arrives before a delayed timer is serviced
        request(frame, 'target')
        local count = refreshes
        Advance(10.61)
        assert(refreshes == count, 'leading refresh must cancel overdue trailing work')
    """)


def test_layout_hooks():
    lua = runtime()
    text = source("StatusBars/FluxInfoFrame.lua")
    block = text[text.index("local function HookGridRelayout()"):text.index("-- Try to hook immediately")]
    lua.execute("""
        callbacks = {}
        function hooksecurefunc(obj, key, fn) callbacks[#callbacks + 1] = fn end
        function NewGridFrame()
            return {HookScript = function(self, key, fn) callbacks[#callbacks + 1] = fn end}
        end
        FluxNonCombatGrid = {Relayout = function() end}
        FluxCombatGrid = {Relayout = function() end}
        FluxCombatManager = {Grid = {Frame = NewGridFrame()}}
        FluxNonCombatAPI = {DefaultGrid = {Frame = NewGridFrame()}}
        local initialized = true
        local frame = {IsShown = function() return true end}
        updates = 0
        local function UpdatePosition() updates = updates + 1 end
    """ + block + """
        for i = 1, 30 do HookGridRelayout() end
        assert(#callbacks == 4, 'loading screens must not accumulate hooks')
        for _, fn in ipairs(callbacks) do fn() end
        assert(updates == 4)
        FluxCombatManager.Grid.Frame = NewGridFrame()
        HookGridRelayout()
        assert(#callbacks == 5, 'replacement frames must still be hooked')
    """)


def test_capture():
    for client in ("Retail", "Forever", "Era", "Anniversary"):
        lua = runtime()
        lua.execute("""
            output = {}
            function print(...) output[#output + 1] = {...} end
            function GetFramerate() return 150 end
            function GetBuildInfo() return 'test', '123' end
            function GetCVar(name) return name == 'scriptProfile' and '1' or '0' end
            function UpdateAddOnCPUUsage() end
            function GetAddOnCPUUsage() return now * 10 end
            function GetFunctionCPUUsage() return now * 2, now * 10 end
            function GetFrameCPUUsage(f, includeChildren)
                assert(not includeChildren)
                assert(not f.forbidden, 'forbidden frames must be skipped')
                return now * 3, now * 20
            end
            function OnUpdate() end
            frames = {}
            for i = 1, 3 do
                local f = {idx = i, forbidden = i == 3}
                function f:IsForbidden() return self.forbidden end
                function f:GetName() return 'TestFrame' .. self.idx end
                function f:IsVisible() return self.idx == 1 end
                function f:GetScript(kind)
                    assert(not self.forbidden)
                    return kind == 'OnUpdate' and OnUpdate or nil
                end
                frames[i] = f
            end
            function EnumerateFrames(f) return frames[f and f.idx + 1 or 1] end
            ns = {Flux = {Client = {}, Ticker = {
                GetSubscribers = function() return {range = OnUpdate} end
            }, Perf = {Snapshot = function()
                return {passMs = {paint = now}, passCalls = {paint = now * 5}}
            end}}}
            Flux = ns.Flux
        """)
        key = {"Retail": "isRetail", "Forever": "isCamelot", "Era": "isEra", "Anniversary": "isTBC"}[client]
        lua.execute(f"ns.Flux.Client.{key} = true")
        lua.execute(source("Other/FluxPerfCapture.lua"), "_FluxUI", lua.globals().ns)
        lua.execute("""
            assert(#timers == 0, 'loading diagnostics must do no background work')
            Flux.PerfCapture.Start(20)
            Flux.PerfCapture.Start(20)
            assert(#timers == 2, 'duplicate capture must not arm another timer')
            Advance(30)
            local r = FluxPerfCaptureDB
            assert(r.seconds == 20 and r.addonMsPerSecond == 10)
            assert(r.liveBefore == 1 and r.liveAfter == 1)
            assert(#r.frames == 2 and r.frames[1].msPerSecond == 3)
            assert(r.fpsAverage == 150 and r.fpsMin == 150)
            assert(#r.passes == 1 and r.passes[1].msPerSecond == 1)
            assert(timers[1].cancelled)
            Flux.PerfCapture.Start(5)
            Flux.PerfCapture.Cancel()
            assert(timers[3].cancelled and timers[4].cancelled)
            Advance(40)
            assert(FluxPerfCaptureDB == r, 'cancel must retain the completed report')
        """)
        assert lua.globals().FluxPerfCaptureDB.client == client


def test_nameplate_lifecycle():
    lua = runtime()
    text = source("Other/FluxNamePlates.lua")
    block = text[text.index("local function StartTicker()"):text.index("local function HookPlateLifecycle()")]
    preview = text[text.index("local function RefreshPreviewOverlay()"):text.index("local function ShowPreviewNpcThreat()")]
    lua.execute("""
        local ticker
        local previewActive = false
        local POLL_INTERVAL, REASSERT_INTERVAL, COUNTDOWN_INTERVAL = 0.25, 0.05, 0.1
        local PREVIEW_UNIT = 'preview'
        local function IsFluxNameplateRuntimeSupported() return true end
        local function IsFluxAuraCountdownSupported() return true end
        local function ReassertAllTints() end
        local function ReassertAllLevelOverlays() end
        local function ApplyAllNameplateAuraCountdownOverlays() end
        local function UpdateThreatUnit() end
        local function EnsureDB() end
        sweeps = 0
        local function UpdateAll() sweeps = sweeps + 1 end
        visiblePlates = {}
        C_NamePlate = {GetNamePlates = function() return visiblePlates end}
        function CreateFrame()
            driver = {shown = true, scripts = {}, events = {}}
            function driver:RegisterEvent(e) self.events[e] = true end
            function driver:SetScript(k, v) self.scripts[k] = v end
            function driver:Show() self.shown = true end
            function driver:Hide() self.shown = false end
            return driver
        end
    """ + block + preview + """
        StartTicker()
        driver.scripts.OnUpdate(driver, 0.25)
        assert(not driver.shown and sweeps == 1)
        assert(driver.events.NAME_PLATE_UNIT_ADDED and driver.events.NAME_PLATE_UNIT_REMOVED)
        visiblePlates[1] = {}
        driver.scripts.OnEvent(driver, 'NAME_PLATE_UNIT_ADDED')
        driver.scripts.OnUpdate(driver, 0.25)
        assert(driver.shown and sweeps == 2)
        visiblePlates[1] = nil
        driver.scripts.OnEvent(driver, 'NAME_PLATE_UNIT_REMOVED')
        driver.scripts.OnUpdate(driver, 0.25)
        assert(not driver.shown and sweeps == 3)
        previewActive = true
        RefreshPreviewOverlay()
        driver.scripts.OnUpdate(driver, 0.25)
        assert(driver.shown, 'preview must wake and retain the ticker')
        previewActive = false
        driver.scripts.OnUpdate(driver, 0.25)
        assert(not driver.shown)
    """)


def test_ticker_snapshot():
    lua = runtime()
    lua.execute("""
        function CreateFrame()
            return {Hide = function() end, Show = function() end, SetScript = function() end}
        end
        ns = {Flux = {}}
    """)
    lua.execute(source("Core/Engine/Ticker.lua"), "_FluxUI", lua.globals().ns)
    lua.execute("""
        local t = ns.Flux.Ticker
        local fn = function() end
        t.Add('test', fn)
        local copy = t.GetSubscribers()
        assert(copy.test == fn)
        copy.test = nil
        assert(t.GetSubscribers().test == fn and t.Count() == 1)
        t.Remove('test')
        assert(next(t.GetSubscribers()) == nil)
    """)


if __name__ == "__main__":
    for test in (test_auras, test_layout_hooks, test_capture, test_nameplate_lifecycle, test_ticker_snapshot):
        test()
        print(test.__name__, "PASS")
