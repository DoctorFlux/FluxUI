-- lua Battlezonemap/_tmp_questiepinsmoke.lua
-- Runs the real router + tooltip bridge against HBD-compatible map/frame mocks.
-- Checks shared icon ownership/settings and leaves native map methods/providers intact.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local unpack = table.unpack or unpack

local function Runtime(forever, nativeQuests)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local ns = { _isCamelotGameType = forever }
    local frames, timers, now, combat, active, enabled = {}, {}, 0, false, true, true
    local metrics = { visits = 0, acquisitions = 0, refreshes = 0 }
    env.table = setmetatable({ wipe = function(t) for k in pairs(t) do t[k] = nil end end }, { __index = table })
    env.InCombatLockdown = function() return combat end
    env.FLUX_API = { isForever = forever, isCamelot = forever }
    env.QuestDataProviderMixin = nativeQuests and {} or nil
    env.C_XMLUtil = { GetTemplateInfo = function(name) if name == "AreaPOIPinTemplate" then return {} end end }
    env.C_Timer = { After = function(delay, fn) timers[#timers + 1] = { at = now + delay, fn = fn } end }
    local function Copy(target, ...)
        for i = 1, select("#", ...) do for k, v in pairs(select(i, ...)) do target[k] = v end end
        return target
    end
    env.Mixin = Copy
    env.CreateFromMixins = function(...) return Copy({}, ...) end
    env.MapCanvasDataProviderMixin = { GetMap = function(self) return self.owningMap end }
    env.hooksecurefunc = function(obj, key, fn)
        local old = assert(obj[key]); obj[key] = function(...) local result = { old(...) }; fn(...); return unpack(result) end
    end
    local function Frame(parent)
        local f = { parent = parent, shown = true, scripts = {}, events = {}, width = 16, height = 16 }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:GetScript(event) return self.scripts[event] end
        function f:HookScript(event, fn)
            local old = self.scripts[event]
            self.scripts[event] = function(...) if old then old(...) end; fn(...) end
        end
        function f:Show()
            if self.fakeHidden then return end
            local old = self.shown; self.shown = true
            if not old and self.scripts.OnShow then self.scripts.OnShow(self) end
        end
        function f:Hide()
            local old = self.shown; self.shown = false
            if old and self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        function f:FakeHide() self:Hide(); self.fakeHidden = true end
        function f:FakeShow() self.fakeHidden = false; self:Show() end
        function f:IsShown() return self.shown end
        function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function f:SetParent(p) self.parent = p end
        function f:GetParent() return self.parent end
        function f:SetSize(w, h) self.width, self.height = w, h end
        function f:GetWidth() return self.width end
        function f:GetHeight() return self.height end
        function f:SetPoint(...) self.point = { ... } end
        function f:ClearAllPoints() self.point = nil end
        function f:EnableMouse(value) self.mouse = value end
        function f:SetMouseMotionEnabled(value) self.motion = value end
        function f:SetMouseClickEnabled(value) self.click = value end
        function f:UseFrameLevelType(value) self.frameLevelType = value end
        function f:SetPosition(x, y) self.x, self.y = x, y end
        frames[#frames + 1] = f
        return f
    end
    env.CreateFrame = function(_, _, parent) return Frame(parent) end
    env.CreateFramePool = function() return {} end
    env.UIParent = Frame()
    local function Map(id)
        local map = Frame(env.UIParent)
        map.mapID, map.pinPools, map.dataProviders, map.pins = id, {}, {}, {}
        map.canvas = Frame(map)
        function map:GetCanvas() return self.canvas end
        function map:GetMapID() return self.mapID end
        function map:AddDataProvider(provider) self.dataProviders[provider] = true; provider.owningMap = self end
        function map:RemoveDataProvider(provider) self.dataProviders[provider] = nil end
        function map:RegisterPin() end
        function map:OnCanvasScaleChanged() end
        function map:AcquirePin(template, icon, x, y, level)
            metrics.acquisitions = metrics.acquisitions + 1
            assert(not combat, "pin acquired on an addon stack in combat")
            local pool = assert(self.pinPools[template], "missing pin pool: " .. template)
            local pin = pool.createFunc(); pin.pinTemplate, pin.owningMap = template, self
            self.pins[pin] = true
            pin:OnAcquired(icon, x, y, level)
            return pin
        end
        function map:RemovePin(pin)
            if pin.OnReleased then pin:OnReleased() end
            self.pins[pin] = nil
        end
        function map:EnumeratePinsByTemplate(template)
            local previous
            return function()
                while true do
                    local pin = next(self.pins, previous); previous = pin
                    if not pin then return end
                    metrics.visits = metrics.visits + 1
                    if pin.pinTemplate == template then return pin end
                end
            end
        end
        function map:RemoveAllPinsByTemplate(template)
            for pin in self:EnumeratePinsByTemplate(template) do self:RemovePin(pin) end
        end
        return map
    end
    local world, battlefield = Map(10), Map(10); world.shown = false
    env.WorldMapFrame, env.BattlefieldMapFrame = world, battlefield
    env.FluxBattlefieldMap = { IsActive = function() return active end, GetMapFrame = function() return battlefield end }
    env.FluxBattlefieldMapWorldFeatures = { IsEnabled = function() return enabled end }
    env.Questie = { db = { profile = { enabled = true, enableMapIcons = true,
        enableMiniMapIcons = false, trackerEnabled = false, hideIconsOnContinents = false } } }
    local function Library(template)
        local lib = { worldmapPins = {} }
        local provider = Copy({}, env.MapCanvasDataProviderMixin)
        local pinMixin = {}
        -- Match HBD's ownership contract: OnAcquired uses the original Questie
        -- icon; OnReleased hides it and moves it back to UIParent.
        function pinMixin:OnAcquired(icon, x, y, level)
            self.icon = icon; self:SetPosition(x, y); self:UseFrameLevelType(level)
            icon:SetParent(self); icon:ClearAllPoints(); icon:SetPoint("CENTER", self, "CENTER"); icon:Show()
        end
        function pinMixin:OnReleased()
            if self.icon then self.icon:Hide(); self.icon:SetParent(env.UIParent); self.icon:ClearAllPoints(); self.icon = nil end
        end
        function pinMixin:SetPassThroughButtons() end
        function provider:RemoveAllData() self:GetMap():RemoveAllPinsByTemplate(template) end
        function provider:RemovePinByIcon(icon)
            for pin in self:GetMap():EnumeratePinsByTemplate(template) do if pin.icon == icon then self:GetMap():RemovePin(pin) end end
        end
        function provider:HandlePin(icon, data)
            local map = self:GetMap()
            if env.Questie.db.profile.hideIconsOnContinents and map.mapID == 20 then icon:Hide(); return end
            if map.mapID ~= data.mapID then return end
            map:AcquirePin(template, icon, data.x, data.y, "PIN_FRAME_LEVEL_AREA_POI")
        end
        function provider:RefreshAllData()
            metrics.refreshes = metrics.refreshes + 1
            self:RemoveAllData()
            for icon, data in pairs(lib.worldmapPins) do self:HandlePin(icon, data) end
            self.forceUpdate = false
        end
        function lib:AddWorldMapIconMap(_, icon, mapID, x, y)
            local data = { mapID = mapID, x = x, y = y }; self.worldmapPins[icon] = data
            provider:HandlePin(icon, data)
        end
        function lib:RemoveWorldMapIcon(_, icon) self.worldmapPins[icon] = nil; provider:RemovePinByIcon(icon) end
        world.pinPools[template] = { createFunc = function() return Copy(Frame(world.canvas), pinMixin) end }
        world:AddDataProvider(provider)
        lib.worldmapProvider, lib.worldmapProviderPin = provider, pinMixin
        return lib
    end
    local questie = Library("HereBeDragonsPinsTemplateQuestie")
    local stock = Library("HereBeDragonsPinsTemplate")
    local available = true
    env.LibStub = function(name)
        if name == "HereBeDragonsQuestie-Pins-2.0" then return available and questie or nil end
        if name == "HereBeDragons-Pins-2.0" then return stock end
    end
    local function Load(path, source)
        if not source then local f = assert(io.open(root .. path)); source = f:read("*a"); f:close() end
        local chunk
        if setfenv then chunk = assert(loadstring(source, path)); setfenv(chunk, env)
        else chunk = assert(load(source, path, "t", env)) end
        chunk("_FluxUI", ns)
    end
    Load("Battlezonemap/FluxBattlefieldMapPinTooltips.lua")
    Load("Battlezonemap/FluxBattlefieldMapPinRouter.lua")
    local function Drain()
        local count = 0
        while #timers > 0 do
            count = count + 1; assert(count < 200, "unbounded pin refresh")
            table.sort(timers, function(a, b) return a.at < b.at end)
            local t = table.remove(timers, 1); now = t.at; t.fn()
        end
    end
    local function Event(event, name)
        for _, frame in ipairs(frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, name) end
        end
    end
    return { env = env, router = env.FluxBattlefieldMapPinRouter, questie = questie, stock = stock,
        world = world, battlefield = battlefield, Frame = Frame, Drain = Drain, Event = Event, Load = Load, metrics = metrics,
        SetCombat = function(value) combat = value end, SetEnabled = function(value) enabled = value end,
        SetAvailable = function(value) available = value end }
end

local function Check(forever, native)
    local r = Runtime(forever, native); local env = r.env
    local q, wp = r.questie, r.questie.worldmapProvider
    local icon = r.Frame(env.UIParent); icon:SetSize(23, 23); icon.color = { .3, .6, .9 }
    local enter = function() end; icon:SetScript("OnEnter", enter)
    q:AddWorldMapIconMap(env.Questie, icon, 10, .4, .6)
    local nativePool = {}; r.battlefield.pinPools.AreaPOIPinTemplate = nativePool
    local acquire, register, getID = r.battlefield.AcquirePin, r.battlefield.RegisterPin, r.world.GetMapID
    local scaleChanged = r.battlefield.OnCanvasScaleChanged
    local stockHandle, stockGetMap = r.stock.worldmapProvider.HandlePin, r.stock.worldmapProvider.GetMap
    assert(r.router:Install()); r.Drain()
    assert(r.router:GetRouteLabel() == "BF" and wp:GetMap() == r.battlefield)
    assert(icon:IsVisible() and icon:GetParent().owningMap == r.battlefield, "handoff released the newly routed icon")
    assert(icon.width == 23 and icon.color[2] == .6 and icon:GetScript("OnEnter") == enter, "Questie appearance/tooltip was replaced")
    assert(r.battlefield.AcquirePin == acquire and r.world.GetMapID == getID, "native map methods changed")
    assert(r.battlefield.OnCanvasScaleChanged == scaleChanged, "zoom animation was hooked to rebuild pins")
    if native then
        assert(r.battlefield.RegisterPin == register and r.battlefield.pinPools.AreaPOIPinTemplate == nativePool)
        assert(r.stock.worldmapProvider.HandlePin == stockHandle and r.stock.worldmapProvider.GetMap == stockGetMap)
        assert(not r.battlefield.pinPools.HereBeDragonsPinsTemplate, "unrelated HBD library routed on Forever")
    end
    -- World Map visibility and filters act on these same icon objects; minimap
    -- visibility and trackerEnabled are deliberately unrelated to this route.
    env.Questie.db.profile.enableMapIcons = false; icon:FakeHide()
    r.router:RefreshAllThirdPartyPins(); assert(not icon:IsShown(), "routing overrode Questie's World Map hide")
    env.Questie.db.profile.enableMapIcons = true; icon:FakeShow()
    r.router:RefreshAllThirdPartyPins(); assert(icon:IsVisible())
    r.world:Show(); r.Drain()
    assert(r.router:GetRouteLabel() == "World" and icon:IsVisible() and icon:GetParent().owningMap == r.world)
    for provider in pairs(r.battlefield.dataProviders) do provider:RefreshAllData() end
    assert(icon:IsVisible() and icon:GetParent().owningMap == r.world, "inactive native map refresh stole World Map icons")
    local later = r.Frame(env.UIParent); q:AddWorldMapIconMap(env.Questie, later, 10, .2, .3)
    assert(later:GetParent().owningMap == r.world)
    r.world:Hide(); r.Drain()
    assert(icon:IsVisible() and later:IsVisible() and later:GetParent().owningMap == r.battlefield)
    q:RemoveWorldMapIcon(env.Questie, later); assert(not later:IsShown())
    r.battlefield.mapID = 20
    q.worldmapPins[icon].mapID = 20; env.Questie.db.profile.hideIconsOnContinents = true
    r.router:RefreshAllThirdPartyPins(); assert(not icon:IsShown(), "continent filter was ignored")
    env.Questie.db.profile.hideIconsOnContinents = false
    r.router:RefreshAllThirdPartyPins(); assert(icon:IsVisible())
    r.SetCombat(true)
    local deferred = r.Frame(env.UIParent); deferred:Hide()
    q:AddWorldMapIconMap(env.Questie, deferred, 20, .7, .8)
    r.router:RefreshAllThirdPartyPins(); assert(not deferred:IsShown())
    r.SetCombat(false); r.Event("PLAYER_REGEN_ENABLED"); r.Drain()
    assert(deferred:IsVisible() and deferred:GetParent().owningMap == r.battlefield, "combat-deferred pin was lost")
    r.SetEnabled(false); r.router:Uninstall()
    assert(wp:GetMap() == r.world and wp.forceUpdate and not icon:IsShown())
    r.world.mapID = 20; r.world:Show(); wp:RefreshAllData()
    assert(icon:IsVisible() and icon:GetParent().owningMap == r.world, "world pins did not recover after Map Pins off")
end
Check(true, true)
Check(false, false)

-- Live retail remains on its native provider path.
local live = Runtime(false, true)
local before = live.questie.worldmapProvider.HandlePin
assert(not live.router:Install() and live.questie.worldmapProvider.HandlePin == before)

-- Questie can finish loading after the battlefield map is already active.
local late = Runtime(true, true); late.SetAvailable(false)
assert(late.router:Install()); late.Drain()
late.SetAvailable(true); late.Event("ADDON_LOADED", "Questie"); late.Drain()
local icon = late.Frame(late.env.UIParent)
late.questie:AddWorldMapIconMap(late.env.Questie, icon, 10, .5, .5)
assert(icon:IsVisible() and icon:GetParent().owningMap == late.battlefield)

-- Exercise the actual WorldFeatures activation entry point with native quest
-- providers present, rather than calling the router alone.
local sourceFile = assert(io.open(root .. "Battlezonemap/FluxBattlefieldMapWorldFeatures.lua"))
local source = sourceFile:read("*a"); sourceFile:close()
local first = assert(source:find("function FluxBattlefieldMapWorldFeatures:Activate()", 1, true))
local last = assert(source:find("function FluxBattlefieldMapWorldFeatures:Deactivate()", first, true))
late.router:Uninstall()
late.Load("world features activation", "local state = {}; local GetBattlefieldMap = function() return BattlefieldMapFrame end; local UpdateToggleVisual = function() end\n"
    .. source:sub(first, last - 1))
late.env.FluxBattlefieldMapWorldFeatures:Activate(); late.Drain()
assert(late.router:IsHBDAvailable() and icon:IsVisible() and icon:GetParent().owningMap == late.battlefield)

-- Bursts coalesce; zoom and discovery retries on an installed route do no redraw.
local performance = Runtime(true, true); assert(performance.router:Install()); performance.Drain()
local metrics = performance.metrics
local refreshes = metrics.refreshes
for _ = 1, 100 do performance.router:RequestRefresh() end
assert(metrics.refreshes == refreshes, "refresh burst ran synchronously")
performance.Drain()
assert(metrics.refreshes == refreshes + 1, "refresh burst rebuilt pins more than once")
refreshes = metrics.refreshes
for _ = 1, 120 do performance.battlefield:OnCanvasScaleChanged() end
performance.router:ScheduleKickstart(); performance.Drain()
assert(metrics.refreshes == refreshes, "zoom/ready-route retries rebuilt the full map")
local forcedQueueCalls = 0
performance.env.QuestieLoader = { ImportModule = function()
    return { ProcessQueue = function() forcedQueueCalls = forcedQueueCalls + 1 end }
end }
performance.router:RefreshAllThirdPartyPins()
assert(forcedQueueCalls == 0, "Flux force-drained Questie's batched queue")
print("Questie battlefield pins smoke OK (Forever/native coexistence, Classic route, shared World Map settings/icons, handoff, filters, tooltips, late loading, combat recovery, Map Pins off and live retail isolation)")

if arg[1] == "--benchmark" then
    for _, count in ipairs({ 1000, 2000 }) do
        local r = Runtime(true, true); assert(r.router:Install()); r.Drain()
        for key in pairs(r.metrics) do r.metrics[key] = 0 end
        local started = os.clock()
        for i = 1, count do
            r.questie:AddWorldMapIconMap(r.env.Questie, r.Frame(r.env.UIParent), 10, .4, .6)
        end
        assert(r.metrics.visits == 0 and r.metrics.refreshes == 0, "incremental pins scanned/rebuilt the full map")
        assert(r.metrics.acquisitions == count, "each icon must acquire exactly one pin")
        print(string.format("%d incremental pins: %.2f ms mock CPU, %d pin-list visits, %d acquisitions, %d full refreshes",
            count, (os.clock() - started) * 1000, r.metrics.visits, r.metrics.acquisitions, r.metrics.refreshes))
    end
end
