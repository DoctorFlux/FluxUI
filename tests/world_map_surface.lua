-- Original WorldMapFrame surface hosting with arbitrary addon children. These
-- desktop lifecycle/operation checks do not certify native rendering or taint.
local source = (arg and arg[1]) or "Battlezonemap/FluxBattlefieldWorldMap.lua"
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local unpack = table.unpack or unpack

local function Runtime(client, initiallyShown)
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.unpack = unpack
    local s = { frames = {}, timers = {}, hooks = {}, panels = {}, combat = false, reads = 0, scans = 0, nativeShows = 0, nativeHides = 0, mapWrites = 0, timerSchedules = 0, active = true, enabled = true }
    env.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    env.table = setmetatable({ wipe = env.wipe }, { __index = table })
    env.InCombatLockdown = function() return s.combat end
    env.Flux = { Client = { isRetail = client == "retail", isForever = client == "forever",
        isAnyClassic = client == "classic" or client == "era" or client == "anniversary",
        isClassicEra = client == "era" or client == "anniversary" } }
    env.FLUX_API = env.Flux.Client
    env.Enum = { AddOnRestrictionType = { Combat = 0, Map = 4 }, AddOnRestrictionState = { Inactive = 0, Activating = 1 } }
    env.C_Timer = { After = function(_, fn) s.timerSchedules = s.timerSchedules + 1; s.timers[#s.timers + 1] = fn end }
    env.C_AddOns = { IsAddOnLoaded = function() return true end, LoadAddOn = function() return true end, DoesAddOnExist = function() return true end }
    env.GetTime = function() return 1 end
    env.GetCVarBool = function() return false end
    env.GetCVar = function() return "0" end
    env.GetUIPanel = function(area) return s.panels[area] end
    env.C_Map = { GetBestMapForUnit = function() return 37 end }
    local function visibleBefore()
        local before = {}; for _, f in ipairs(s.frames) do before[f] = f:IsVisible() end; return before
    end
    local function dispatch(before)
        for _, f in ipairs(s.frames) do
            local visible = f:IsVisible()
            if before[f] ~= visible then
                local fn = f.scripts[visible and "OnShow" or "OnHide"]
                if fn then fn(f) end
            end
        end
    end
    local function Frame(parent)
        local f = { parent = parent, shown = true, scripts = {}, events = {}, points = {}, width = 500, height = 300, scale = 1, alpha = 1, level = 2, strata = "MEDIUM", left = 80, bottom = 120 }
        s.frames[#s.frames + 1] = f
        function f:IsShown() return self.shown end
        function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function f:Show() local before = visibleBefore(); self.shown = true; dispatch(before) end
        function f:Hide() local before = visibleBefore(); self.shown = false; dispatch(before) end
        function f:SetShown(v) if v then self:Show() else self:Hide() end end
        function f:SetParent(v)
            check(not s.combat or not self.native, "native root parent never changes in combat")
            self.geometryWrites = (self.geometryWrites or 0) + 1
            local before = visibleBefore(); self.parent = v; dispatch(before)
        end
        function f:GetParent() return self.parent end
        function f:SetAllPoints(v)
            self.geometryWrites = (self.geometryWrites or 0) + 1
            self.allPoints = v or self.parent
            self.points = { { "TOPLEFT", self.allPoints, "TOPLEFT", 0, 0 },
                { "BOTTOMRIGHT", self.allPoints, "BOTTOMRIGHT", 0, 0 } }
        end
        function f:ClearAllPoints()
            check(not s.combat or not self.native, "native root points never change in combat")
            self.geometryWrites = (self.geometryWrites or 0) + 1
            self.points, self.allPoints = {}, nil
        end
        function f:SetPoint(...)
            check(not s.combat or not self.native, "native root anchors never change in combat")
            self.geometryWrites = (self.geometryWrites or 0) + 1
            self.points[#self.points + 1] = { ... }
        end
        function f:GetNumPoints() return #self.points end
        function f:GetPoint(i) return unpack(self.points[i or 1] or {}) end
        function f:SetSize(w, h)
            check(not s.combat or not self.native, "native root size never changes in combat")
            self.geometryWrites = (self.geometryWrites or 0) + 1
            local changed = self.width ~= w or self.height ~= h
            self.width, self.height = w, h
            if changed and self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self, w, h) end
        end
        function f:SetWidth(w) self:SetSize(w, self.height) end
        function f:SetHeight(h) self:SetSize(self.width, h) end
        function f:GetWidth()
            return self.allPoints and self.allPoints:GetWidth() * self.allPoints:GetEffectiveScale() / self:GetEffectiveScale() or self.width
        end
        function f:GetHeight()
            return self.allPoints and self.allPoints:GetHeight() * self.allPoints:GetEffectiveScale() / self:GetEffectiveScale() or self.height
        end
        function f:GetSize() return self:GetWidth(), self:GetHeight() end
        function f:GetLeft() return self.allPoints and self.allPoints:GetLeft() or self.left end
        function f:GetBottom() return self.allPoints and self.allPoints:GetBottom() or self.bottom end
        function f:GetRight() return self:GetLeft() + self:GetWidth() end
        function f:GetTop() return self:GetBottom() + self:GetHeight() end
        function f:GetRect() return self:GetLeft(), self:GetBottom(), self:GetWidth(), self:GetHeight() end
        function f:GetCenter() return self:GetLeft() + self:GetWidth()/2, self:GetBottom() + self:GetHeight()/2 end
        function f:SetScale(v)
            check(not s.combat or not self.native, "native root scale never changes in combat")
            self.geometryWrites = (self.geometryWrites or 0) + 1; self.scale = v
        end
        function f:GetScale() return self.scale end
        function f:GetEffectiveScale() return self.scale * (not self.ignoreParentScale and self.parent and self.parent:GetEffectiveScale() or 1) end
        function f:IsIgnoringParentScale() return self.ignoreParentScale and true or false end
        function f:SetIgnoreParentScale(v)
            check(not s.combat or not self.native, "native root scale inheritance never changes in combat")
            self.geometryWrites = (self.geometryWrites or 0) + 1
            self.ignoreParentScale = v
        end
        function f:SetAlpha(v) self.alpha = v end
        function f:GetAlpha() return self.alpha end
        function f:SetFrameLevel(v) self.level = v end
        function f:GetFrameLevel() return self.level end
        function f:SetFrameStrata(v) self.strata = v end
        function f:GetFrameStrata() return self.strata end
        function f:SetClipsChildren(v) self.clipsChildren = v end
        function f:DoesClipChildren() return self.clipsChildren end
        function f:EnableMouse(v) self.mouse = v end
        function f:IsMouseEnabled() return self.mouse and true or false end
        function f:SetMouseMotionEnabled(v) self.motion = v end
        function f:SetMouseClickEnabled(v) self.click = v end
        function f:SetPropagateMouseClicks(v) self.propagateClick = v end
        function f:SetPropagateMouseMotion(v) self.propagateMotion = v end
        function f:IsProtected() return false end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:GetScript(event) return self.scripts[event] end
        function f:HookScript(event, fn)
            s.hooks[#s.hooks + 1] = { self, event }
            local old = self.scripts[event]
            self.scripts[event] = function(...) if old then old(...) end; fn(...) end
        end
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:IsEventRegistered(event) return self.events[event] == true end
        function f:GetChildren()
            s.scans = s.scans + 1
            local list = {}; for _, child in ipairs(s.frames) do if child.parent == self then list[#list+1] = child end end
            return unpack(list)
        end
        return f
    end
    s.Frame = Frame
    env.CreateFrame = function(kind, _, parent, template)
        check((kind == "Frame" or kind == "FRAME") and not template, "surface host/native service uses ordinary frames")
        return Frame(parent)
    end
    env.UIParent = Frame()
    env.UIParent:SetSize(1920, 1080)
    local map = Frame(env.UIParent)
    map:SetSize(1000, 800); map:SetScale(0.9); map:SetFrameStrata("HIGH"); map:SetFrameLevel(11)
    map:SetIgnoreParentScale(true)
    map:SetPoint("TOPLEFT", env.UIParent, "TOPLEFT", 64, -100)
    map:SetPoint("BOTTOMRIGHT", env.UIParent, "BOTTOMRIGHT", -600, 180)
    map.mapID = 84
    map.ScrollContainer = Frame(map)
    map.ScrollContainer:SetSize(900, 600)
    map.ScrollContainer.left, map.ScrollContainer.bottom = 110, 170
    -- Native world-map scroll anchors follow all four root edges. Its viewport
    -- changes when the source root is resized; a fixed child-size stub hides
    -- both shrinkage and oversized hit-region regressions.
    local scroll = map.ScrollContainer
    scroll.nativeInsets = { left = 30, right = 70, top = 150, bottom = 50 }
    scroll:SetPoint("TOPLEFT", map, "TOPLEFT", 30, -150)
    scroll:SetPoint("BOTTOMRIGHT", map, "BOTTOMRIGHT", -70, 50)
    local setScrollSize = scroll.SetSize
    function scroll:GetWidth()
        if self.allPoints then return self.allPoints:GetWidth() * self.allPoints:GetEffectiveScale() / self:GetEffectiveScale() end
        local insets = self.nativeInsets
        return (map:GetWidth() - insets.left - insets.right) * map:GetEffectiveScale() / self:GetEffectiveScale()
    end
    function scroll:GetHeight()
        if self.allPoints then return self.allPoints:GetHeight() * self.allPoints:GetEffectiveScale() / self:GetEffectiveScale() end
        local insets = self.nativeInsets
        return (map:GetHeight() - insets.top - insets.bottom) * map:GetEffectiveScale() / self:GetEffectiveScale()
    end
    function scroll:GetLeft()
        if self.allPoints then
            local left = self.allPoints:GetLeft()
            return left and left * self.allPoints:GetEffectiveScale() / self:GetEffectiveScale()
        end
        local left = map:GetLeft()
        return left and (left + self.nativeInsets.left) * map:GetEffectiveScale() / self:GetEffectiveScale()
    end
    function scroll:GetTop()
        if self.allPoints then
            local top = self.allPoints:GetTop()
            return top and top * self.allPoints:GetEffectiveScale() / self:GetEffectiveScale()
        end
        local top = map:GetTop()
        return top and (top - self.nativeInsets.top) * map:GetEffectiveScale() / self:GetEffectiveScale()
    end
    function scroll:GetBottom() local top = self:GetTop(); return top and top - self:GetHeight() end
    function scroll:SetSize(w, h)
        local ratio = self:GetEffectiveScale() / map:GetEffectiveScale()
        self.nativeInsets.right = map:GetWidth() - self.nativeInsets.left - w * ratio
        self.nativeInsets.bottom = map:GetHeight() - self.nativeInsets.top - h * ratio
        setScrollSize(self, w, h)
    end
    map.canvas = Frame(map.ScrollContainer)
    map.canvas:SetSize(900, 600)
    map.dataProviders, map.pinPools = { immutableProvider = {} }, { immutablePool = {} }
    map.providerIdentity, map.poolIdentity = map.dataProviders, map.pinPools
    function map:GetMapID() s.reads = s.reads + 1; return self.mapID end
    function map:SetMapID(id) check(not s.combat, "world map identity never written in combat"); self.mapID = id; s.mapWrites = s.mapWrites + 1 end
    function map:GetCanvas() return self.canvas end
    function map:GetCanvasContainer() return self.ScrollContainer end
    function map:IsMaximized() return false end
    for _, key in ipairs({ "AcquirePin", "AddDataProvider", "RemoveDataProvider", "RegisterPin" }) do map[key] = function() error("surface host used clone/pin API " .. key) end end
    map:Hide()
    if initiallyShown then map:Show() end
    env.WorldMapFrame, s.world = map, map
    local battlefield = Frame(env.UIParent)
    battlefield:SetSize(440, 320)
    battlefield.ScrollContainer = Frame(battlefield)
    battlefield.ScrollContainer:SetSize(420, 280)
    battlefield.mapID = 37
    function battlefield:GetMapID() return self.mapID end
    function battlefield:SetMapID(id) self.mapID = id end
    function battlefield:GetCanvasContainer() return self.ScrollContainer end
    local function InputPolicy(frame, navigate)
        frame.inputPolicy = { ZoomIn = false, Pan = false, Navigate = navigate }
        for _, name in ipairs({ "ZoomIn", "Pan", "Navigate" }) do
            local key = name
            local function get() return frame.inputPolicy[key] end
            local function set(_, value)
                check(not s.combat, "native map input policy never changes during combat")
                frame.inputPolicy[key] = value
                frame.inputWrites = (frame.inputWrites or 0) + 1
            end
            frame["Should" .. key .. "OnClick"], frame.ScrollContainer["Should" .. key .. "OnClick"] = get, get
            frame["SetShould" .. key .. "OnClick"], frame.ScrollContainer["SetShould" .. key .. "OnClick"] = set, set
        end
    end
    InputPolicy(map, true); InputPolicy(battlefield, false)
    env.BattlefieldMapFrame, s.battlefield = battlefield, battlefield
    env.FluxBattlefieldMap = { IsActive = function() return s.active end, GetMapFrame = function() return battlefield end }
    env.FluxBattlefieldMapWorldFeatures = { IsEnabled = function() return s.enabled end }
    env.ShowUIPanel = function(frame)
        s.nativeShows = s.nativeShows + 1
        frame:Show()
        return "native-show-result"
    end
    env.HideUIPanel = function(frame)
        s.nativeHides = s.nativeHides + 1
        for area, current in pairs(s.panels) do if current == frame then s.panels[area] = nil end end
        frame:Hide()
    end
    env.ToggleWorldMap = function()
        if map.HandleUserActionToggleSelf then return map:HandleUserActionToggleSelf() end
        if s.nativeToggleAlternate and map:IsShown() then
            -- QuestLogOwner can switch between open display states rather
            -- than closing when its current quest-log state differs.
            env.ShowUIPanel(map)
        elseif map:IsShown() then env.HideUIPanel(map) else env.ShowUIPanel(map) end
        return "native-toggle-result"
    end
    env.OpenWorldMap = function(id) env.ShowUIPanel(map); if id then map:SetMapID(id) end end
    env.hooksecurefunc = function(object, key, fn)
        if type(object) == "string" then object, key, fn = env, object, key end
        s.hooks[#s.hooks + 1] = { object, key }
        local old = assert(object[key], "missing secure-hook target " .. tostring(key))
        object[key] = function(...)
            local result = { old(...) }; fn(...); return unpack(result)
        end
    end
    -- Unknown addons draw both directly under the root and in deeply nested
    -- canvas trees. Their scripts, regions and data must remain the originals.
    s.arbitrary = { Frame(map), Frame(map.canvas) }
    s.arbitrary[3] = Frame(s.arbitrary[2])
    s.arbitrary[4] = Frame(s.arbitrary[3])
    s.updates = 0
    for i, f in ipairs(s.arbitrary) do
        f.marker = { text = "guide " .. i, texture = "custom-" .. i, line = { 0.1, 0.2, 0.7, 0.8 } }
        f:SetScript("OnUpdate", function(self) s.updates = s.updates + 1; self.marker.text = "step-" .. s.updates end)
    end
    map.native = true
    s.originalFrames = #s.frames
    local fn
    if setfenv then fn = assert(loadfile(source)); setfenv(fn, env)
    else fn = assert(loadfile(source, "t", env)) end
    fn("_FluxUI", { Flux = env.Flux })
    s.bridge = assert(env.FluxBattlefieldWorldMap, "original world-map surface public owner missing")
    function s:Flush()
        for _ = 1, 12 do
            if #self.timers == 0 then return end
            local list = self.timers; self.timers = {}
            for _, fn in ipairs(list) do fn() end
        end
        error("surface host scheduled recursive timers")
    end
    function s:DispatchEvent(event, ...)
        local list = {}; for _, f in ipairs(self.frames) do list[#list+1] = f end
        for _, f in ipairs(list) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end end
    end
    function s:Event(event, ...)
        self:DispatchEvent(event, ...)
        self:Flush()
    end
    function s:Tick()
        self:Flush()
        for _, f in ipairs(self.frames) do if f:IsVisible() and f.scripts.OnUpdate then f.scripts.OnUpdate(f, 0.016) end end
    end
    function s:CheckRestored(label)
        local world = self.world
        check(world:GetParent() == env.UIParent, label .. " restores native parent")
        check(world:GetScale() == 0.9 and world:GetFrameStrata() == "HIGH" and world:GetFrameLevel() == 11, label .. " restores scale and draw order")
        check(world:GetNumPoints() == 2, label .. " restores all native anchors")
        local p, r, rp, x, y = world:GetPoint(1)
        check(p == "TOPLEFT" and r == env.UIParent and rp == "TOPLEFT" and x == 64 and y == -100, label .. " restores first native anchor exactly")
        p, r, rp, x, y = world:GetPoint(2)
        check(p == "BOTTOMRIGHT" and r == env.UIParent and rp == "BOTTOMRIGHT" and x == -600 and y == 180, label .. " restores second native anchor exactly")
        check(world:GetWidth() == 1000 and world:GetHeight() == 800 and world:GetAlpha() == 1, label .. " retains native root size and opacity")
        check(world:IsIgnoringParentScale(), label .. " restores native scale inheritance")
    end
    return env, s
end

if arg and arg[2] == "--fixture" then return Runtime end

local function AnchorCoordinates(env, s)
    local factors = { TOPLEFT = {0,1}, TOPRIGHT = {1,1}, BOTTOMLEFT = {0,0}, BOTTOMRIGHT = {1,0}, CENTER = {.5,.5} }
    local rect
    rect = function(frame)
        if frame.allPoints then return rect(frame.allPoints) end
        local scale = frame:GetEffectiveScale()
        local w, h = frame:GetWidth() * scale, frame:GetHeight() * scale
        if frame.nativeInsets then
            local owner = frame:GetParent()
            local left, bottom, _, ownerHeight = rect(owner)
            local ownerScale, inset = owner:GetEffectiveScale(), frame.nativeInsets
            return left + inset.left * ownerScale, bottom + ownerHeight - inset.top * ownerScale - h, w, h
        end
        local point = frame.points[1]
        if not point then return frame.left * scale, frame.bottom * scale, w, h end
        local relative = point[2] or frame:GetParent()
        local left, bottom, rw, rh = rect(relative)
        local own, other = factors[point[1]], factors[point[3] or point[1]]
        return left + other[1] * rw + (point[4] or 0) * scale - own[1] * w,
            bottom + other[2] * rh + (point[5] or 0) * scale - own[2] * h, w, h
    end
    local function coordinates(frame)
        function frame:GetLeft() local left = rect(self); return left / self:GetEffectiveScale() end
        function frame:GetBottom() local _, bottom = rect(self); return bottom / self:GetEffectiveScale() end
        function frame:GetTop() local _, bottom, _, h = rect(self); return (bottom + h) / self:GetEffectiveScale() end
        function frame:GetRight() local left, _, w = rect(self); return (left + w) / self:GetEffectiveScale() end
        return frame
    end
    for _, frame in ipairs(s.frames) do coordinates(frame) end
    local create = env.CreateFrame
    env.CreateFrame = function(...) return coordinates(create(...)) end
    return rect
end

local function CheckSceneFit(rect, scene, viewport, label)
    local l, b, w, h = rect(viewport)
    local sl, sb, sw, sh = rect(scene)
    check(sl >= l-.001 and sb >= b-.001 and sl+sw <= l+w+.001 and sb+sh <= b+h+.001,
        label .. " stays inside the battlefield viewport")
    check(math.abs(sl+sw/2-l-w/2) < .001 and math.abs(sb+sh/2-b-h/2) < .001,
        label .. " is centered without stretching")
    check(math.abs(sw-w) < .001 or math.abs(sh-h) < .001,
        label .. " fits one viewport axis exactly")
end

for _, client in ipairs({ "retail", "forever", "classic", "era", "anniversary" }) do
    local env, s = Runtime(client)
    local bridge, world = s.bridge, s.world
    local parents, markers, scripts = {}, {}, {}
    for i, f in ipairs(s.arbitrary) do parents[i], markers[i], scripts[i] = f:GetParent(), f.marker, f:GetScript("OnUpdate") end
    bridge:Activate(s.battlefield); s:Flush()
    check(bridge:IsEmbedded() and world:IsVisible(), client .. " original world map visible in Flux host")
    check(world:GetMapID() == 37, client .. " original source canvas shows battlefield map identity")
    check(world:GetParent() ~= env.UIParent, client .. " root belongs to owned clipped host")
    local host = world:GetParent()
    check(math.abs(world:GetScale() - math.min(host:GetWidth()/900, host:GetHeight()/600)) < .000001
        and world:GetWidth() == 900 and world:GetHeight() == 600,
        client .. " entire original scene uses one uniform fit with its native logical viewport")
    check(world.dataProviders == world.providerIdentity and world.pinPools == world.poolIdentity, client .. " original pools and providers retained")
    for i, f in ipairs(s.arbitrary) do
        check(f:GetParent() == parents[i] and f.marker == markers[i] and f:GetScript("OnUpdate") == scripts[i], client .. " arbitrary addon identity/layout/scripts retained")
        check(f:IsVisible(), client .. " arbitrary direct and nested addon content visible")
    end
    s:Tick()
    check(s.updates == 4, client .. " original addon scripts draw without cloning")
    local late = s.Frame(world.canvas)
    late.marker = { text = "late source pin", line = { 0.3, 0.5, 0.6, 0.7 } }
    s.lateUpdates = 0
    late:SetScript("OnUpdate", function() s.lateUpdates = s.lateUpdates + 1 end)
    s:Tick()
    check(late:IsVisible() and s.lateUpdates == 1, client .. " source addon late drawing appears without registration or discovery")
    local frames, hooks = #s.frames, #s.hooks
    for _ = 1, 50 do
        bridge:Deactivate(); s:Flush()
        check(not bridge:IsEmbedded() and not world:IsVisible(), client .. " feature-off returns hidden native map")
        check(world:GetMapID() == 84, client .. " feature-off restores prior source map")
        s:CheckRestored(client)
        bridge:Activate(s.battlefield); s:Flush()
        check(bridge:IsEmbedded(), client .. " map tab re-entry hosts original source again")
    end
    check(#s.frames == frames and #s.hooks == hooks, client .. " 50 toggles allocate no extra hosts or hooks")
    local mapWrites = s.mapWrites
    for _ = 1, 1000 do bridge:Sync() end
    s:Flush()
    check(s.mapWrites == mapWrites, client .. " unchanged sync performs no map writes")
    check(s.scans == 0 and #s.frames == frames and #s.hooks == hooks, client .. " idle sync has no child scans, frames or permanent hooks")
    for i = s.originalFrames + 1, #s.frames do
        local frame = s.frames[i]
        if frame ~= late then check(not frame.scripts.OnUpdate, client .. " Flux host adds no recurring render or discovery loop") end
    end
    s.battlefield:SetMapID(49); bridge:Sync(); s:Flush()
    check(world:GetMapID() == 49, client .. " zone change reaches original addon map identity")
    local result = env.ToggleWorldMap(); s:Flush()
    check(result == "native-toggle-result", client .. " native toggle result preserved")
    check(not bridge:IsEmbedded() and world:IsVisible(), client .. " native map key transfers original map to full window")
    s:CheckRestored(client .. " full-map handoff")
    env.OpenWorldMap(62); s:Flush()
    check(not bridge:IsEmbedded() and world:IsVisible() and world:GetMapID() == 62, client .. " normal full-map targeting remains native")
    env.HideUIPanel(world); s:Flush()
    check(bridge:IsEmbedded() and world:IsVisible() and world:GetMapID() == 49, client .. " full-map close returns original canvas to Flux")
    bridge:Deactivate(); s:Flush()
    check(not world:IsShown(), client .. " map pins off does not leave full map open")
    s:CheckRestored(client .. " final release")
    local updates = s.updates
    for _ = 1, 100 do s:Tick() end
    check(s.updates == updates, client .. " hidden original addon subtree performs no ticks")
end

do
    local env, s = Runtime("forever", true)
    s.bridge:Activate(s.battlefield); s:Flush()
    check(not s.bridge:IsEmbedded() and s.world:GetParent() == env.UIParent, "already open full world map keeps priority")
    env.HideUIPanel(s.world); s:Flush()
    check(s.bridge:IsEmbedded(), "closing preexisting full map acquires the original canvas")
    env.ShowUIPanel(s.world); s:Flush()
    check(not s.bridge:IsEmbedded() and s.world:IsVisible(), "direct native ShowUIPanel request restores full-map window")
    s.bridge:Deactivate(); s:Flush()
    check(s.world:IsVisible(), "Map Pins off preserves explicitly open full map")
end

do
    local _, s = Runtime("forever")
    s.combat = true
    s.bridge:Activate(s.battlefield); s:Flush()
    check(not s.bridge:IsEmbedded() and not s.world:IsShown(), "combat-time activation defers native surface writes")
    s.combat = false; s:Event("PLAYER_REGEN_ENABLED")
    check(s.bridge:IsEmbedded(), "combat-end event acquires deferred surface")
    local parent, scale = s.world:GetParent(), s.world:GetScale()
    s.combat = true; s.bridge:Deactivate(); s:Flush()
    check(s.world:GetParent() == parent and s.world:GetScale() == scale, "combat release keeps native hierarchy and scale untouched")
    check(not s.world:IsVisible(), "combat release hides owned viewport immediately")
    s.combat = false; s:Event("PLAYER_REGEN_ENABLED")
    check(not s.bridge:IsEmbedded() and not s.world:IsShown(), "combat-end event restores disabled source exactly once")
    s:CheckRestored("deferred release")
end

do
    local _, s = Runtime("forever")
    s.bridge:Activate(s.battlefield); s:Flush()
    s.combat = true
    s.bridge:Deactivate(); s.bridge:Activate(s.battlefield); s:Flush()
    s.combat = false; s:Event("PLAYER_REGEN_ENABLED")
    check(s.bridge:IsEmbedded() and s.world:IsVisible(), "combat-time disable/re-enable restores owned viewport after combat")
end

do
    local _, s = Runtime("forever")
    s.bridge:Activate(s.battlefield); s:Flush()
    local viewport, hide = s.world:GetParent(), s.world:GetParent().Hide
    function viewport:IsProtected() return true end
    function viewport:Hide()
        check(not s.combat, "adopted protected subtree is never hidden on addon stack in combat")
        return hide(self)
    end
    s.combat = true; s.bridge:Deactivate(); s:Flush()
    check(s.world:IsVisible(), "protected subtree waits for combat instead of illegal parent hiding")
    s.combat = false; s:Event("PLAYER_REGEN_ENABLED")
    check(not s.bridge:IsEmbedded() and not s.world:IsShown(), "protected subtree returns to native hidden state after combat")
    s:CheckRestored("protected deferred release")
end

-- Native first-show display initialization can create positions and resize the
-- map after load. Measure the original surface only after that native reflow.
do
    local _, s = Runtime("forever")
    local initialized, left = false, s.world.GetLeft
    function s.world:GetLeft() if initialized then return left(self) end end
    s.world:SetScript("OnShow", function(self)
        initialized = true
        self:SetSize(1200, 900)
        self.ScrollContainer:SetSize(1200, 800)
    end)
    s.bridge:Activate(s.battlefield); s:Flush()
    check(initialized and s.bridge:IsEmbedded(), "freshly loaded world map initializes absent geometry before embedding")
    local viewport = s.world:GetParent()
    local scale = s.world.ScrollContainer:GetEffectiveScale() / viewport:GetEffectiveScale()
    check(s.world.ScrollContainer:GetWidth() * scale <= viewport:GetWidth() + 0.001,
        "native first-show width reflow fits inside Flux viewport")
    check(s.world.ScrollContainer:GetHeight() * scale <= viewport:GetHeight() + 0.001,
        "native first-show height reflow fits inside Flux viewport")
end

do
    local _, s = Runtime("retail")
    local first = true
    s.world:SetScript("OnShow", function(self)
        if not first then return end
        first = false
        self:SetSize(1200, 900)
        self.ScrollContainer:SetSize(1200, 800)
    end)
    s.bridge:Activate(s.battlefield); s:Flush()
    check(s.bridge:IsEmbedded(), "existing pre-show geometry permits native display initialization")
    local viewport = s.world:GetParent()
    local scale = s.world.ScrollContainer:GetEffectiveScale() / viewport:GetEffectiveScale()
    check(s.world.ScrollContainer:GetWidth() * scale <= viewport:GetWidth() + 0.001,
        "existing geometry is remeasured after native first-show reflow")
end

for _, area in ipairs({ "left", "center", "right", "doublewide", "fullscreen" }) do
    local env, s = Runtime("forever")
    local occupant, shown = s.Frame(env.UIParent), 0
    occupant:SetPoint("TOPLEFT", env.UIParent, "TOPLEFT", 18, -31)
    occupant:SetSize(320, 540)
    s.panels[area] = occupant
    s.world:SetScript("OnShow", function()
        shown = shown + 1
        for _, current in pairs(s.panels) do
            check(current == s.world, "automatic native World Map OnShow cannot relocate an unrelated occupied panel")
        end
    end)
    s.bridge:Activate(s.battlefield); s:Flush()
    check(shown == 0 and not s.bridge:IsEmbedded() and not s.world:IsShown(), area .. " occupant defers first native map show")
    check(occupant:IsVisible() and occupant:GetWidth() == 320 and occupant:GetHeight() == 540, area .. " occupant remains unchanged")
    env.HideUIPanel(occupant); s:Flush()
    check(shown == 1 and s.bridge:IsEmbedded(), area .. " native panel close resumes deferred original map host once")
end

do
    local _, s = Runtime("forever")
    local customParent = s.Frame(s.world:GetParent())
    s.world:SetParent(customParent); customParent:Hide()
    s.bridge:Activate(s.battlefield); s:Flush()
    check(not s.bridge:IsEmbedded() and not s.world:IsShown() and s.world:GetParent() == customParent,
        "hidden custom source owner is not opened or bypassed")
    local hooks = #s.hooks
    for _ = 1, 20 do s.bridge:Sync() end
    check(#s.hooks == hooks, "hidden source-owner retries retain one visibility hook")
    customParent:Show(); s:Flush()
    check(s.bridge:IsEmbedded() and s.world:IsVisible(), "custom source-owner show resumes original map acquisition")
    s.bridge:Deactivate(); s:Flush()
    check(s.world:GetParent() == customParent and not s.world:IsShown() and customParent:IsVisible(),
        "source release restores custom owner without changing owner visibility")
end

do
    local function read(path)
        local f = assert(io.open(path, "rb")); local text = f:read("*a"); f:close()
        return text:gsub("\r\n", "\n")
    end
    local function section(text, first, last)
        local begin = assert(text:find(first, 1, true), first)
        return text:sub(begin, assert(text:find(last, begin + #first, true), last) - 1)
    end
    local function execute(text, env)
        local fn
        if setfenv then fn = assert(loadstring(text)); setfenv(fn, env)
        else fn = assert(load(text, "world-map-feature-integration", "t", env)) end
        return fn()
    end
    local env, s = Runtime("retail")
    local installs, kickstarts = 0, 0
    env.FluxBattlefieldMapProviders = {
        Attach = function() s.providerAttached = true end,
        Detach = function() s.providerAttached = false end,
    }
    env.FluxBattlefieldMapPinRouter = {
        Install = function() s.routeInstalled = true; installs = installs + 1 end,
        Uninstall = function() s.routeInstalled = false end,
    }
    env.state = { isActive = true }
    env.GetBattlefieldMap = function() return s.battlefield end
    env.UpdateToggleVisual = function() end
    local featureSource = read(arg and arg[3] or "Battlezonemap/FluxBattlefieldMapWorldFeatures.lua")
    local activation = section(featureSource, "function FluxBattlefieldMapWorldFeatures:Activate()", "function FluxBattlefieldMapWorldFeatures:OnMapShown(")
        .. "\nreturn ScheduleActivateRetry"
    local retry = execute(activation, env)
    -- Replay the router's actual eligibility and delayed kickstart code, with
    -- ordinary provider setup represented by the explicit mocks above.
    local routerSource = read("Battlezonemap/FluxBattlefieldMapPinRouter.lua")
    local routerBody = "local KICKSTART_DELAYS = { 0, 0.25, 0.5, 1, 2, 3, 5, 8 }\nlocal kickstartGeneration = 0\nlocal state = { installed = false, hbdAvailable = false }\n"
        .. section(routerSource, "local function IsPinRouterWanted()", "local function IsProviderOnMap(")
        .. section(routerSource, "function FluxBattlefieldMapPinRouter:ScheduleKickstart()", "function FluxBattlefieldMapPinRouter:Install()")
    execute(routerBody, env)
    local actualKickstart = env.FluxBattlefieldMapPinRouter.ScheduleKickstart
    function env.FluxBattlefieldMapPinRouter:ScheduleKickstart()
        kickstarts = kickstarts + 1
        return actualKickstart(self)
    end
    s.world:SetScript("OnShow", function()
        check(not s.routeInstalled and not s.providerAttached, "original source OnShow runs only after both fallback owners detach")
    end)
    local occupant = s.Frame(env.UIParent)
    s.panels.left = occupant
    env.FluxBattlefieldMapWorldFeatures:Activate()
    check(s.providerAttached and s.routeInstalled and not s.bridge:IsEmbedded(), "actual feature owner retains fallback while native surface is deferred")
    retry()
    check(kickstarts == 1 and #s.timers == 8, "deferred fallback retains original bounded discovery callbacks")
    local delayed = s.timers; s.timers = {}
    env.HideUIPanel(occupant); s:Flush()
    check(s.bridge:IsEmbedded() and not s.providerAttached and not s.routeInstalled, "delayed native readiness releases fallback before source acquisition")
    local before = installs
    for _, fn in ipairs(delayed) do fn() end
    check(installs == before and not s.routeInstalled, "already queued actual kickstart callbacks cannot reinstall fallback over source surface")
    retry()
    check(kickstarts == 1, "actual feature retry adds no discovery work while source surface owns display")
    env.FluxBattlefieldMapWorldFeatures:Deactivate(); s:Flush()
    check(not s.bridge:IsEmbedded() and not s.providerAttached and not s.routeInstalled, "actual feature owner releases source and both fallback owners")

    local forever, f = Runtime("forever")
    local world = f.world
    local questEvent, logEvent = "QUEST_WATCH_LIST_CHANGED", "QUEST_LOG_UPDATE"
    local fallbackInstalls, refreshes, unrelatedEvents = 0, 0, 0
    forever.FluxBattlefieldMapProviders = {
        Attach = function() fallbackInstalls = fallbackInstalls + 1 end,
        Detach = function() end,
    }
    forever.FluxBattlefieldMapPinRouter = {
        Install = function() fallbackInstalls = fallbackInstalls + 1 end,
        Uninstall = function() end,
    }
    forever.state = { isActive = true }
    forever.GetBattlefieldMap = function() return f.battlefield end
    forever.UpdateToggleVisual = function() end
    local features = forever.FluxBattlefieldMapWorldFeatures
    execute(activation, forever)
    execute(section(featureSource, 'local eventFrame = CreateFrame("Frame")', "SLASH_FLUXWORLDMAP1"), forever)
    world:SetScript("OnShow", function(self)
        self:RegisterEvent(questEvent)
        self:RegisterEvent(logEvent)
    end)
    world:SetScript("OnHide", function(self)
        self:UnregisterEvent(questEvent)
        self:UnregisterEvent(logEvent)
    end)
    function world:RefreshAllDataProviders()
        check(not f.combat, "quest pin refresh remains outside lockdown")
        refreshes = refreshes + 1
    end
    world:SetScript("OnEvent", function(self, event)
        if event == questEvent or event == logEvent then self:RefreshAllDataProviders()
        else unrelatedEvents = unrelatedEvents + 1 end
    end)
    world:RegisterEvent("DISPLAY_SIZE_CHANGED")
    features:Activate(); f:Flush()
    check(f.bridge:IsEmbedded() and world:IsVisible() and fallbackInstalls == 0,
        "Forever uses the original World Map through the actual Map Pins entry point")
    local viewport = world:GetParent()
    local pin = f.arbitrary[4]
    local originalEventScript = world:GetScript("OnEvent")
    f:Event("ADDON_RESTRICTION_STATE_CHANGED", 4, 1)
    check(world:IsEventRegistered(questEvent), "unrelated restriction leaves quest updates registered")
    f:DispatchEvent("ADDON_RESTRICTION_STATE_CHANGED", 0, 1)
    check(not world:IsEventRegistered(questEvent) and not world:IsEventRegistered(logEvent),
        "Forever holds native quest events before lockdown starts")
    f.combat = true
    f:Event("PLAYER_REGEN_DISABLED")
    for _ = 1, 5 do f:Event(questEvent); f:Event(logEvent) end
    f:Event("DISPLAY_SIZE_CHANGED")
    check(refreshes == 0 and unrelatedEvents == 1 and world:GetScript("OnEvent") == originalEventScript,
        "combat holds native quest refreshes while unrelated map events keep their original script")
    check(world:IsVisible() and world:GetParent() == viewport and pin:IsVisible(),
        "original terrain and addon drawings remain mounted and visible in combat")
    f:DispatchEvent("PLAYER_REGEN_ENABLED")
    local nextFrame = table.remove(f.timers, 1)
    nextFrame()
    check(refreshes == 0 and not world:IsEventRegistered(questEvent) and #f.timers == 1,
        "an early regen notification keeps the hold while lockdown stays active")
    f.combat = false
    f.bridge:Sync()
    check(refreshes == 0 and not world:IsEventRegistered(questEvent),
        "ordinary map sync cannot resume quest callbacks ahead of the deferred exit")
    f:Flush()
    check(refreshes == 1 and world:IsEventRegistered(questEvent) and world:IsEventRegistered(logEvent)
        and not world:IsEventRegistered("QUEST_POI_UPDATE"),
        "combat exit restores only displaced quest registrations and refreshes once")
    f:Event(questEvent)
    check(refreshes == 2 and world:GetParent() == viewport, "normal quest events reach Blizzard again")
    f.combat = true
    f:Event("PLAYER_REGEN_DISABLED")
    f.combat = false
    f:Event("PLAYER_REGEN_ENABLED")
    check(refreshes == 2 and world:IsEventRegistered(questEvent),
        "combat with no missed quest events adds no refresh")
    forever.ToggleWorldMap(); f:Flush()
    check(world:IsVisible() and world:GetParent() == forever.UIParent, "native toggle opens the normal World Map")
    f.combat = true
    f:Event("PLAYER_REGEN_DISABLED"); f:Event(questEvent)
    f:DispatchEvent("PLAYER_REGEN_ENABLED")
    f:DispatchEvent("PLAYER_REGEN_DISABLED")
    f:Flush()
    check(refreshes == 2 and not world:IsEventRegistered(questEvent), "combat reentry cancels the deferred resume")
    world:Hide()
    f.combat = false
    f:Event("ADDON_RESTRICTION_STATE_CHANGED", 0, 0)
    check(f.bridge:IsEmbedded() and world:IsEventRegistered(questEvent) and refreshes == 2,
        "closing the map lets the next native show register its own events")
    features:Deactivate(); f:Flush()
    check(not f.bridge:IsRequested() and not world:IsVisible() and not world:IsEventRegistered(questEvent),
        "disabling Map Pins returns the original map to its hidden native state")
    forever.ToggleWorldMap()
    f.combat = true
    f:Event("PLAYER_REGEN_DISABLED")
    check(world:IsEventRegistered(questEvent), "disabled Map Pins leaves the normal World Map subscribed")
end

do
    local env, s = Runtime("forever")
    local old = s.world
    s.bridge:Activate(s.battlefield); s:Flush()
    local replacement = s.Frame(env.UIParent)
    replacement:SetSize(720, 640)
    replacement:SetScale(1.3); replacement:SetFrameStrata("LOW"); replacement:SetFrameLevel(8)
    replacement:SetPoint("CENTER", env.UIParent, "CENTER", -92, 27)
    replacement.mapID = 93
    replacement.ScrollContainer = s.Frame(replacement)
    replacement.ScrollContainer:SetSize(660, 440)
    replacement.canvas = s.Frame(replacement.ScrollContainer)
    replacement.dataProviders, replacement.pinPools = {}, {}
    for _, name in ipairs({ "GetMapID", "SetMapID", "GetCanvas", "GetCanvasContainer", "IsMaximized",
        "AcquirePin", "AddDataProvider", "RemoveDataProvider", "RegisterPin" }) do replacement[name] = old[name] end
    replacement:Hide(); replacement.native = true
    env.WorldMapFrame = replacement
    s.bridge:Sync(); s:Flush()
    check(not old:IsShown() and old:GetMapID() == 84, "source replacement releases and restores old root identity")
    s:CheckRestored("replaced original root")
    check(s.bridge:IsEmbedded() and replacement:IsVisible() and replacement:GetMapID() == 37,
        "source replacement hosts new original root with battlefield identity")
    check(replacement:GetParent() ~= env.UIParent and replacement.ScrollContainer:GetParent() == replacement,
        "replacement descendants retain their original ownership")
    local frames, hooks = #s.frames, #s.hooks
    for _ = 1, 25 do s.bridge:Sync() end
    check(#s.frames == frames and #s.hooks == hooks, "replacement sync retains one host and one set of source hooks")
    old:Show(); old:Hide()
    check(#s.timers == 0, "retired source visibility callbacks cannot schedule work for replacement")
    local schedules = s.timerSchedules
    old:ClearAllPoints()
    old:SetPoint("TOPLEFT", env.UIParent, "TOPLEFT", 64, -100)
    old:SetPoint("BOTTOMRIGHT", env.UIParent, "BOTTOMRIGHT", -600, 180)
    old:SetParent(env.UIParent); old:SetScale(.9)
    old.ScrollContainer:ClearAllPoints()
    old.ScrollContainer:SetPoint("TOPLEFT",old,"TOPLEFT",30,-150)
    old.ScrollContainer:SetPoint("BOTTOMRIGHT",old,"BOTTOMRIGHT",-70,50)
    check(#s.timers==0 and s.timerSchedules==schedules,
        "retired source root and scroll geometry callbacks cannot schedule work for replacement")
    s.bridge:Deactivate(); s:Flush()
    check(not replacement:IsShown() and replacement:GetMapID() == 93 and replacement:GetParent() == env.UIParent,
        "replacement release restores its own hidden state, identity and parent")
    check(replacement:GetScale() == 1.3 and replacement:GetFrameStrata() == "LOW" and replacement:GetFrameLevel() == 8,
        "replacement release restores its own scale and draw order")
    local p, r, rp, x, y = replacement:GetPoint(1)
    check(replacement:GetNumPoints() == 1 and p == "CENTER" and r == env.UIParent and rp == "CENTER" and x == -92 and y == 27,
        "replacement release restores its own anchor rather than retired source anchors")
    check(replacement:GetWidth() == 720 and replacement:GetHeight() == 640,
        "replacement release retains its native dimensions")
    s.bridge:Activate(s.battlefield); s:Flush()
    env.WorldMapFrame = old
    s.bridge:Sync(); s:Flush()
    check(old:IsVisible() and old:GetMapID() == 37 and not replacement:IsShown() and replacement:GetMapID() == 93,
        "returning original source restores replacement before reacquiring retired source")
    check(#s.frames == frames and #s.hooks == hooks, "source replacement round trip reuses existing hosts and hook registrations")
    s.bridge:Deactivate(); s:Flush()
end

-- Native WorldMapFrame owns an explicit LOW fullscreen black backdrop. Its
-- normal HIGH root paints above that child; a BACKGROUND battlefield host is
-- lower. Keep this source-owned backdrop out of the embedded render surface.
do
    local rank = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5 }
    local function physicalRect(frame)
        if frame.allPoints then return physicalRect(frame.allPoints) end
        local scale = frame:GetEffectiveScale()
        return frame:GetLeft() * scale, frame:GetBottom() * scale,
            frame:GetWidth() * scale, frame:GetHeight() * scale
    end
    local function covers(frame, viewport)
        local l, b, w, h = physicalRect(frame)
        local vl, vb, vw, vh = physicalRect(viewport)
        return l <= vl and b <= vb and l + w >= vl + vw and b + h >= vb + vh
    end
    for _, maximized in ipairs({ true, false }) do
        local env, s = Runtime("forever")
        local world = s.world
        s.battlefield:SetFrameStrata("BACKGROUND")
        local blackout = s.Frame(world)
        world.BlackoutFrame = blackout
        blackout:SetFrameStrata("LOW")
        function blackout:GetFrameLevel() return world:GetFrameLevel() + 1 end
        blackout:SetAllPoints(env.UIParent)
        blackout:SetShown(maximized)
        world:SetScript("OnShow", function() blackout:SetShown(maximized) end)
        check(rank[world:GetFrameStrata()] > rank[blackout:GetFrameStrata()],
            "normal native World Map root paints above explicit LOW blackout")
        s.bridge:Activate(s.battlefield); s:Flush()
        local viewport = world:GetParent()
        check(covers(blackout, viewport), "native fullscreen blackout rectangle covers the entire Flux crop")
        local paintsAbove = rank[blackout:GetFrameStrata()] > rank[world:GetFrameStrata()]
            or (rank[blackout:GetFrameStrata()] == rank[world:GetFrameStrata()] and blackout:GetFrameLevel() > world:GetFrameLevel())
        check(paintsAbove, "native fullscreen blackout paints above adopted World Map root")
        check(not (blackout:IsVisible() and covers(blackout, viewport)
            and paintsAbove),
            "native fullscreen blackout cannot obscure embedded map surface")
        check(not blackout:IsShown(), "embedded surface hides only native fullscreen blackout")
        for _, frame in ipairs(s.arbitrary) do check(frame:IsVisible(), "native blackout suppression retains original addon drawings") end
        local hooks = #s.hooks
        for _ = 1, 25 do
            blackout:Show(); s:Flush()
            check(not blackout:IsShown(), "native blackout re-show stays suppressed while embedded")
        end
        check(#s.hooks == hooks, "native blackout re-show does not accumulate permanent hooks")
        env.ToggleWorldMap(); s:Flush()
        check(not s.bridge:IsEmbedded() and world:IsVisible() and blackout:IsShown() == maximized,
            "normal full-map handoff restores native maximized/minimized blackout state")
        env.HideUIPanel(world); s:Flush()
        check(s.bridge:IsEmbedded() and not blackout:IsShown(), "return from full map suppresses native fullscreen blackout again")
        s.bridge:Deactivate(); s:Flush()
        check(not world:IsShown() and blackout:IsShown() == maximized,
            "feature release restores exact original native blackout shown state")
    end
    do
        local _, s = Runtime("forever")
        local blackout = s.Frame(s.world)
        s.world.BlackoutFrame = blackout
        blackout:SetFrameStrata("LOW"); blackout:SetAllPoints(s.world:GetParent())
        s.bridge:Activate(s.battlefield); s:Flush()
        local hide = blackout.Hide
        function blackout:IsProtected() return true end
        function blackout:Hide()
            check(not s.combat, "native protected blackout is never hidden on an addon stack in combat")
            return hide(self)
        end
        s.combat = true
        blackout:Show(); s:Flush()
        check(blackout:IsShown(), "protected native blackout suppression waits for combat end")
        s.combat = false; s:Event("PLAYER_REGEN_ENABLED")
        check(not blackout:IsShown(), "deferred native blackout suppression resumes after combat")
        s.bridge:Deactivate(); s:Flush()
        check(blackout:IsShown(), "protected native blackout original state restored on release")
    end
end

do
    local env, s = Runtime("forever")
    local world = s.world
    world.frameBuffer = true -- Native WorldMapFrame XML ownership stays intact.
    s.battlefield:SetFrameStrata("BACKGROUND")
    s.battlefield.ScrollContainer.isNativeScrollFrame = true
    local hud = s.Frame(env.UIParent); hud:SetFrameStrata("MEDIUM")
    local parents = {}; for i, frame in ipairs(s.arbitrary) do parents[i] = frame:GetParent() end
    s.bridge:Activate(s.battlefield); s:Flush()
    local viewport = world:GetParent()
    check(viewport:GetParent() == env.UIParent and not viewport.isNativeScrollFrame,
        "native source uses a regular UIParent viewport rather than a ScrollFrame overlay child")
    check(viewport.allPoints == s.battlefield.ScrollContainer,
        "regular source viewport follows native battlefield scroll rectangle")
    check(world:GetFrameStrata() == "LOW" and viewport:GetFrameStrata() == "LOW"
        and s.battlefield:GetFrameStrata() == "BACKGROUND" and hud:GetFrameStrata() == "MEDIUM",
        "original source draws above battlefield terrain and below HUD/combat blocker")
    check(world.frameBuffer == true, "native source framebuffer setting stays owned by its original frame")
    for i, frame in ipairs(s.arbitrary) do
        check(frame:GetParent() == parents[i], "source layering preserves every original addon-owned subtree")
    end
end

do
    local env, s = Runtime("forever")
    s.world:SetScript("OnShow", function()
        env.C_Timer.After(0, function()
            -- Native child anchoring changes on the next layout turn without
            -- changing root size or firing its OnSizeChanged handler.
            s.world.ScrollContainer.nativeInsets = { left = 2, right = 336, top = 67, bottom = 2 }
            s.world.ScrollContainer:ClearAllPoints()
            s.world.ScrollContainer:SetPoint("TOPLEFT", s.world, "TOPLEFT", 2, -67)
            s.world.ScrollContainer:SetPoint("BOTTOMRIGHT", s.world, "BOTTOMRIGHT", -336, 2)
        end)
    end)
    s.bridge:Activate(s.battlefield); s:Flush()
    local point = { s.world:GetPoint(1) }
    check(s.bridge:IsEmbedded() and point[1] == "TOPLEFT" and math.abs(s.world:GetWidth()-662) < .000001 and math.abs(s.world:GetHeight()-731) < .000001
        and s.world.ScrollContainer.allPoints == s.world,
        "map-only source mount follows settled native next-frame layout")
    check(math.abs(s.world.ScrollContainer:GetWidth()-662) < .000001 and math.abs(s.world.ScrollContainer:GetHeight()-731) < .000001,
        "settled child-inset acquisition preserves native logical scene dimensions")
end

do
    local env, s = Runtime("forever")
    local getLeft = s.world.GetLeft
    s.world:ClearAllPoints()
    function s.world:GetLeft() if self:GetNumPoints() > 0 then return getLeft(self) end end
    s.world:SetAlpha(0.72)
    s.bridge:Activate(s.battlefield)
    local p, parent, rp = s.world:GetPoint(1)
    check(p == "CENTER" and parent == env.UIParent and rp == "CENTER" and s.world:GetAlpha() == 0,
        "unanchored native source gets only a temporary centered invisible preparation anchor")
    s:Flush()
    check(s.bridge:IsEmbedded() and s.world:GetAlpha() == 1,
        "zero-anchor source initializes fully opaque inside Flux")
    s.bridge:Deactivate(); s:Flush()
    check(not s.world:IsShown() and s.world:GetNumPoints() == 0 and s.world:GetAlpha() == 0.72,
        "zero-anchor source release restores original empty anchors and hidden state")
    s.bridge:Activate(s.battlefield); s.bridge:Deactivate(); s:Flush()
    check(not s.world:IsShown() and s.world:GetNumPoints() == 0 and s.world:GetAlpha() == 0.72,
        "cancelled zero-anchor preparation removes its temporary seed anchor")
end

-- Anchor-aware native inset model: render-space equality, normal icon/text
-- size, and source input ownership are distinct from matching mock counts.
do
    local env, s = Runtime("forever")
    local world = s.world
    env.UIParent.left, env.UIParent.bottom = 0, 0
    world:ClearAllPoints(); world:SetPoint("TOPLEFT", env.UIParent, "TOPLEFT", 64, -100)
    world.ScrollContainer.nativeInsets = { left = 2, right = 336, top = 67, bottom = 2 }
    world.ScrollContainer:ClearAllPoints()
    world.ScrollContainer:SetPoint("TOPLEFT", world, "TOPLEFT", 2, -67)
    world.ScrollContainer:SetPoint("BOTTOMRIGHT", world, "BOTTOMRIGHT", -336, 2)
    world:SetSize(1035, 534)
    world.canvas:SetAllPoints(world.ScrollContainer)
    s.battlefield:ClearAllPoints(); s.battlefield:SetPoint("BOTTOMRIGHT", env.UIParent, "BOTTOMRIGHT", -20, 80)
    s.battlefield.ScrollContainer:SetPoint("TOPLEFT", s.battlefield, "TOPLEFT", 0, 0)
    world:EnableMouse(true)
    local names, wanted, chrome = { "BorderFrame", "NavBar", "QuestLog" }, { true, false, true }, {}
    for i, name in ipairs(names) do chrome[i] = s.Frame(world); chrome[i]:SetShown(wanted[i]); world[name] = chrome[i] end
    world:SetScript("OnShow", function() for i, frame in ipairs(chrome) do frame:SetShown(wanted[i]) end end)
    local rect = AnchorCoordinates(env, s)
    local pin, marker = s.arbitrary[4], s.arbitrary[4].marker
    marker.glyphWidth, marker.fontHeight = 14, 12
    pin:EnableMouse(true)
    local handler = function(self) self.marker.activations = (self.marker.activations or 0) + 1 end
    pin:SetScript("OnMouseDown", handler)
    local sizeRefreshes = 0
    function world:OnFrameSizeChanged() sizeRefreshes = sizeRefreshes + 1 end
    local sourceNavigate = world.ShouldNavigateOnClick
    s.bridge:Activate(s.battlefield); s:Flush()
    local viewport = world:GetParent()
    CheckSceneFit(rect, world.ScrollContainer, viewport, "native source scene")
    local wantedFit = math.min(viewport:GetWidth()/697, viewport:GetHeight()/465)
    check(math.abs(world:GetScale()-wantedFit) < .000001 and math.abs(world:GetWidth()-697) < .000001
        and math.abs(world:GetHeight()-465) < .000001 and world.ScrollContainer.allPoints == world,
        "native source scene keeps its settled logical viewport and uses one outer fit")
    check(pin.marker == marker and pin:GetScript("OnMouseDown") == handler and pin:IsMouseEnabled(),
        "native source preserves original addon pin data and input callbacks")
    check(math.abs(pin:GetEffectiveScale()-world:GetEffectiveScale()) < .000001
        and math.abs(marker.glyphWidth*pin:GetEffectiveScale()-14*wantedFit) < .000001
        and math.abs(marker.fontHeight*pin:GetEffectiveScale()-12*wantedFit) < .000001,
        "original addon glyphs and labels share the entire scene's outer scale")
    handler(pin); check(marker.activations == 1, "original source addon callback still activates its own pin")
    check(not world:IsMouseEnabled(), "embedded native root cannot intercept mouse outside its map content")
    check(world.ShouldNavigateOnClick == sourceNavigate and not world:ShouldNavigateOnClick()
        and world:ShouldZoomInOnClick() == s.battlefield:ShouldZoomInOnClick()
        and world:ShouldPanOnClick() == s.battlefield:ShouldPanOnClick(),
        "original source adopts battlefield input policy through unchanged native methods")
    check(world.inputWrites == 1, "unchanged battlefield click policies require no redundant native setter calls")
    check(sizeRefreshes == 1, "map-only source performs one native size refresh after its body settles")
    local writes, refreshes = world.inputWrites, sizeRefreshes
    for _ = 1, 50 do s.bridge:Sync() end
    s:Flush()
    check(world.inputWrites == writes and sizeRefreshes == refreshes,
        "unchanged map-only source has no repeated input-policy or native-size work")
    for _, frame in ipairs(chrome) do check(not frame:IsShown(), "embedded source hides only known stock window chrome") end
    for _, frame in ipairs(s.arbitrary) do check(frame:IsVisible(), "native chrome removal retains every original addon drawing") end
    env.ToggleWorldMap(); s:Flush()
    check(world:IsMouseEnabled() and world:GetWidth() == 1035 and world:GetHeight() == 534 and world:GetScale() == .9,
        "full native map restores original root dimensions, scale and mouse state")
    check(world:ShouldNavigateOnClick() and not world:ShouldZoomInOnClick() and not world:ShouldPanOnClick(),
        "full native map restores original source click policy")
    local ap, ar, arp, ax, ay = world.ScrollContainer:GetPoint(1)
    check(world.ScrollContainer:GetParent() == world and world.ScrollContainer:GetNumPoints() == 2
        and ap == "TOPLEFT" and ar == world and arp == "TOPLEFT" and ax == 2 and ay == -67,
        "full native map restores original scroll owner and first anchor tuple")
    ap, ar, arp, ax, ay = world.ScrollContainer:GetPoint(2)
    check(ap == "BOTTOMRIGHT" and ar == world and arp == "BOTTOMRIGHT" and ax == -336 and ay == 2,
        "full native map restores original second scroll anchor tuple")
    for i, frame in ipairs(chrome) do check(frame:IsShown() == wanted[i], "full native map restores each stock chrome shown state") end
    env.HideUIPanel(world); s:Flush()
    check(s.bridge:IsEmbedded() and not world:IsMouseEnabled(), "return to Flux restores map-only root input ownership")
    s.bridge:Deactivate(); s:Flush()
    check(world:IsMouseEnabled() and world:GetWidth() == 1035 and world:GetHeight() == 534,
        "feature release restores original source dimensions and mouse state")
    check(world.ScrollContainer:GetNumPoints() == 2 and world.ScrollContainer.allPoints == nil
        and world:ShouldNavigateOnClick(), "feature release restores native scroll anchoring and navigation policy")
    for i, frame in ipairs(chrome) do check(frame:IsShown() == wanted[i], "feature release restores stock chrome states") end
end

-- Native layout resolves after a shown frame reaches the renderer. A Show /
-- GetLeft / Hide sequence in one Lua stack never permits that resolution.
do
    local function StagedRuntime(requiredFrames)
        local env, s = Runtime("forever")
        local world, getLeft = s.world, s.world.GetLeft
        s.nativeLayoutFrames, s.nativeLayoutPending, s.nativeLayoutReady = 0, false, false
        world:HookScript("OnShow", function()
            if not s.nativeLayoutReady then s.nativeLayoutFrames, s.nativeLayoutPending = 0, true end
        end)
        world:HookScript("OnHide", function()
            if not s.nativeLayoutReady then s.nativeLayoutFrames, s.nativeLayoutPending = 0, false end
        end)
        function world:GetLeft()
            if s.nativeLayoutReady then return getLeft(self) end
        end
        world:SetScript("OnUpdate", function()
            if s.nativeLayoutPending then
                s.nativeLayoutFrames = s.nativeLayoutFrames + 1
                if s.nativeLayoutFrames >= requiredFrames then s.nativeLayoutReady, s.nativeLayoutPending = true, false end
            end
        end)
        -- One timer generation and one native update per actual frame. The
        -- standard Flush helper intentionally has no native layout boundary.
        function s:NativeFrame()
            local timers = self.timers; self.timers = {}
            for _, fn in ipairs(timers) do fn() end
            for _, frame in ipairs(self.frames) do
                if frame:IsVisible() and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 0.016) end
            end
        end
        function s:NoExtraUpdateScripts(label)
            for i = self.originalFrames + 1, #self.frames do
                check(not self.frames[i].scripts.OnUpdate, label .. " leaves no Flux polling driver")
            end
        end
        return env, s
    end
    for _, required in ipairs({ 1, 2 }) do
        local _, s = StagedRuntime(required)
        s.bridge:Activate(s.battlefield)
        check(s.world:IsShown() and not s.bridge:IsEmbedded(),
            "unsettled native source remains shown across its layout boundary")
        for _ = 1, 8 do s:NativeFrame() end
        check(s.bridge:IsEmbedded() and s.world:IsVisible() and s.nativeLayoutFrames >= required,
            "native source settles for " .. required .. " frame(s) before original surface adoption")
        check(#s.timers == 0, "settled native acquisition stops deferred layout retries")
        s:NoExtraUpdateScripts("settled acquisition")
    end
    do
        local env, s = StagedRuntime(2)
        s.world:SetAlpha(0.73)
        s.bridge:Activate(s.battlefield)
        s.bridge:Deactivate()
        for _ = 1, 8 do s:NativeFrame() end
        check(not s.bridge:IsEmbedded() and not s.world:IsShown() and s.world:GetParent() == env.UIParent,
            "cancellation during native preparation restores hidden source and parent")
        check(s.world:GetAlpha() == 0.73, "cancellation during native preparation restores original source opacity")
        check(#s.timers == 0, "cancelled native preparation leaves no retries")
        s:NoExtraUpdateScripts("cancelled acquisition")
    end
    do
        local env, s = StagedRuntime(2)
        s.world:SetAlpha(0.61)
        s.bridge:Activate(s.battlefield)
        env.OpenWorldMap(62)
        for _ = 1, 8 do s:NativeFrame() end
        check(not s.bridge:IsEmbedded() and s.world:IsVisible() and s.world:GetParent() == env.UIParent,
            "native full-map request during preparation keeps original normal window")
        check(s.world:GetAlpha() == 0.61 and s.world:GetMapID() == 62,
            "native full-map request during preparation preserves opacity and requested map")
        check(#s.timers == 0, "stale acquisition callbacks cannot steal requested full map")
        s:NoExtraUpdateScripts("full-map preparation handoff")
    end
    do
        local _, s = StagedRuntime(1000)
        s.world:SetAlpha(0.42)
        s.bridge:Activate(s.battlefield)
        for _ = 1, 100 do s:NativeFrame() end
        check(not s.bridge:IsEmbedded() and #s.timers == 0,
            "unavailable native layout exhausts bounded retries without permanent polling")
        check(not s.world:IsShown() and s.world:GetAlpha() == 0.42,
            "unavailable native layout restores hidden source and original opacity")
        s:NoExtraUpdateScripts("exhausted acquisition")
    end
    do
        local _, s = StagedRuntime(2)
        s.world:SetAlpha(0.37)
        local setAlpha = s.world.SetAlpha
        function s.world:SetAlpha(value)
            check(not s.combat, "native preparation opacity is never changed during combat")
            return setAlpha(self, value)
        end
        s.bridge:Activate(s.battlefield)
        s.combat = true; s.bridge:Deactivate()
        for _ = 1, 4 do s:NativeFrame() end
        check(s.world:GetAlpha() == 0, "combat-time cancellation defers native preparation cleanup")
        s.combat = false; s:Event("PLAYER_REGEN_ENABLED")
        check(not s.world:IsShown() and s.world:GetAlpha() == 0.37,
            "deferred preparation cleanup restores original opacity after combat")
    end
    do
        local env, s = StagedRuntime(2)
        local old = s.world
        old:SetAlpha(0.81)
        s.bridge:Activate(s.battlefield)
        local replacement = s.Frame(env.UIParent)
        replacement:SetPoint("CENTER", env.UIParent, "CENTER", 0, 0)
        replacement.mapID = 93
        replacement.ScrollContainer = s.Frame(replacement)
        replacement.canvas = s.Frame(replacement.ScrollContainer)
        for _, name in ipairs({ "GetMapID", "SetMapID", "GetCanvas", "GetCanvasContainer" }) do replacement[name] = old[name] end
        replacement:Hide()
        env.WorldMapFrame = replacement
        s.bridge:Sync(); s:Flush()
        check(not old:IsShown() and old:GetAlpha() == 0.81 and old:GetParent() == env.UIParent,
            "source replacement during preparation restores retired root opacity and hidden state")
        check(s.bridge:IsEmbedded() and replacement:IsVisible() and replacement:GetMapID() == s.battlefield:GetMapID(),
            "source replacement during preparation adopts only the replacement original root")
    end
end

-- A native toggle can select another open QuestLogOwner display state. The
-- posthook must close an already-full map rather than treating that as reopen.
do
    local env, s = Runtime("forever")
    s.bridge:Activate(s.battlefield); s:Flush()
    local frames, hooks = #s.frames, #s.hooks
    for _ = 1, 5 do
        s.nativeToggleAlternate = false
        env.ToggleWorldMap(); s:Flush()
        check(not s.bridge:IsEmbedded() and s.world:IsShown() and s.world:GetParent() == env.UIParent,
            "native map key opens the normal full window from Flux")
        s.nativeToggleAlternate = true
        env.ToggleWorldMap()
        check(not s.world:IsShown(), "map key closes full window even when native toggle selected another open state")
        s:Flush()
        check(s.bridge:IsEmbedded() and s.world:GetParent() ~= env.UIParent and s.world.ScrollContainer.allPoints == s.world,
            "full-map close resumes only the embedded source on the next frame")
    end
    check(#s.frames == frames and #s.hooks == hooks, "full-map open/close cycles retain existing source hooks and viewport")
end

do
    local env, s = Runtime("forever")
    s.bridge:Activate(s.battlefield); s:Flush()
    s.nativeToggleAlternate = true
    env.ToggleWorldMap(); s:Flush()
    check(not s.bridge:IsEmbedded() and s.world:GetParent() == env.UIParent and s.world:IsShown(),
        "legacy first open can call ShowUIPanel inside native toggle without closing the requested full map")
    env.ToggleWorldMap()
    check(not s.world:IsShown(), "legacy alternate native toggle still closes the already-full window")
    s:Flush()
    check(s.bridge:IsEmbedded(), "legacy alternate close resumes only the embedded original source")
end

do
    local env, s = Runtime("forever")
    local nativeCalls = 0
    function s.world:HandleUserActionToggleSelf()
        nativeCalls = nativeCalls + 1
        if s.nativeToggleAlternate then env.ShowUIPanel(self)
        elseif self:IsShown() then env.HideUIPanel(self)
        else env.ShowUIPanel(self) end
        return "native-toggle-result"
    end
    s.bridge:Activate(s.battlefield); s:Flush()
    s.nativeToggleAlternate = true
    local frames, hooks = #s.frames, #s.hooks
    for i = 1, 10 do
        local before = nativeCalls
        local result
        if i % 2 == 0 then result = s.world:HandleUserActionToggleSelf()
        else result = env.ToggleWorldMap() end
        s:Flush()
        check(nativeCalls == before + 1 and result == "native-toggle-result",
            "native root toggle and global wrapper retain one native invocation and return value")
        check(not s.bridge:IsEmbedded() and s.world:IsShown() and s.world:GetParent() == env.UIParent,
            "root-method and global toggle posthooks cannot double-transfer first open")
        before = nativeCalls
        if i % 2 == 0 then env.ToggleWorldMap() else s.world:HandleUserActionToggleSelf() end
        check(nativeCalls == before + 1 and not s.world:IsShown(),
            "direct root method and global wrapper close full map exactly once")
        s:Flush()
        check(s.bridge:IsEmbedded(), "native method close returns only the embedded source")
    end
    check(#s.frames == frames and #s.hooks == hooks, "native root toggle cycles retain one method hook and viewport")
end

for _, case in ipairs({ { 1.35, 1 }, { .75, 1.25 }, { 2, .75 } }) do
    local env, s = Runtime("forever")
    env.UIParent.left, env.UIParent.bottom = 0, 0
    env.UIParent:SetScale(case[2])
    s.battlefield:SetScale(case[1])
    s.world:ClearAllPoints(); s.world:SetPoint("TOPLEFT", env.UIParent, "TOPLEFT", 64, -100)
    s.world.canvas:SetAllPoints(s.world.ScrollContainer)
    s.battlefield:ClearAllPoints(); s.battlefield:SetPoint("BOTTOMRIGHT", env.UIParent, "BOTTOMRIGHT", -20, 80)
    s.battlefield.ScrollContainer:SetPoint("TOPLEFT", s.battlefield, "TOPLEFT", 0, 0)
    local rect = AnchorCoordinates(env, s)
    local sizeRefreshes = 0
    function s.world:OnFrameSizeChanged() sizeRefreshes = sizeRefreshes + 1 end
    s.bridge:Activate(s.battlefield); s:Flush()
    local world, viewport = s.world, s.world:GetParent()
    local wantedScale = math.min(viewport:GetWidth()/900, viewport:GetHeight()/600)
    check(math.abs(world:GetScale() - wantedScale) < .000001,
        "source outer scene fit follows battlefield physical extent across UI scales")
    check(world:GetWidth() == 900 and world:GetHeight() == 600,
        "source logical scene dimensions stay at the captured native viewport")
    CheckSceneFit(rect, world.ScrollContainer, viewport, "scaled native source scene")
    local pin = s.arbitrary[4]
    check(math.abs(pin:GetEffectiveScale() - wantedScale*viewport:GetEffectiveScale()) < .000001,
        "original source pin and font pixels share the complete scene fit")
    s.battlefield:SetScale(case[1] * 1.1); s.bridge:Sync(); s:Flush()
    wantedScale = math.min(viewport:GetWidth()/900, viewport:GetHeight()/600)
    check(math.abs(world:GetScale()-wantedScale) < .000001 and world:GetWidth() == 900 and world:GetHeight() == 600,
        "battlefield scale changes update only the outer original scene transform")
    check(sizeRefreshes == 1, "host scale changes do not reset native canvas zoom or pin sizing")
    CheckSceneFit(rect, world.ScrollContainer, viewport, "resized native source scene")
    world:SetSize(1200, 800); s:Flush()
    check(world:GetWidth() == 900 and world:GetHeight() == 600,
        "dirty embedded geometry cannot replace the captured source scene dimensions")
    s.bridge:Deactivate(); s:Flush()
    check(world:GetScale() == .9 and world:GetWidth() == 1000 and world:GetHeight() == 800,
        "scaled source release restores original full-map scale and dimensions")
end

-- Native pin/UI formulas counteract canvas zoom. Keep that native canvas
-- viewport stable, then compare the entire scene's relative pixel transform.
do
    local nativeEnv = setmetatable({ MapCanvasPinMixin = {}, GroupMembersPinMixin = {},
        Lerp = function(a,b,p) return a+(b-a)*p end,
        Saturate = function(value) return math.max(0,math.min(1,value)) end }, { __index = _G })
    local function NativeMethod(path, first, following, owner, name)
        local file = io.open(path, "rb")
        if not file then return nil end
        local text = file:read("*a"); file:close()
        local begin = assert(text:find(first,1,true), first)
        local finish = assert(text:find(following,begin+#first,true), following)
        local chunk = text:sub(begin,finish-1)
        local fn
        if setfenv then fn = assert(loadstring(chunk)); setfenv(fn,nativeEnv)
        else fn = assert(load(chunk,"native-map-scale-contract","t",nativeEnv)) end
        fn()
        return nativeEnv[owner][name]
    end
    local reference = "F:/World of Warcraft/_retail_/Interface/AddOns/__AddonsForRef/wow-ui-source-forever/Interface/AddOns/"
    local applyPin = NativeMethod(reference.."Blizzard_MapCanvas/MapCanvas_DataProviderBase.lua",
        "function MapCanvasPinMixin:ApplyCurrentScale()", "function MapCanvasPinMixin:ApplyCurrentAlpha()",
        "MapCanvasPinMixin", "ApplyCurrentScale")
    local synchronizeUnits = NativeMethod(reference.."Blizzard_SharedMapDataProviders/GroupMembersDataProvider.lua",
        "function GroupMembersPinMixin:SynchronizePinSizes()", "function GroupMembersPinMixin:OnCanvasSizeChanged()",
        "GroupMembersPinMixin", "SynchronizePinSizes")
    local actualNativeMethods = applyPin and synchronizeUnits
    -- Portable formula contracts when the optional source mirror is absent.
    -- Installed-source runs above execute the actual native Lua methods.
    applyPin = applyPin or function(self)
        self:SetScale(1/self:GetMap():GetCanvasScale())
        self:ApplyCurrentPosition()
    end
    synchronizeUnits = synchronizeUnits or function(self)
        local scale = self:GetMap():GetCanvasScale()
        for unit,size in self.dataProvider:EnumerateUnitPinSizes() do self:SetPinSize(unit,size/scale) end
        self:SetPlayerPingScale(.65/scale)
    end
    for _, case in ipairs({ { 1, 1 }, { 1.35, .75 }, { .75, 1.25 } }) do
        local env, s = Runtime("forever")
        local world, scroll = s.world, s.world.ScrollContainer
        env.UIParent.left, env.UIParent.bottom = 0, 0
        env.UIParent:SetScale(case[2]); s.battlefield:SetScale(case[1])
        world:ClearAllPoints(); world:SetPoint("TOPLEFT",env.UIParent,"TOPLEFT",64,-100)
        scroll.nativeInsets = { left=2,right=336,top=67,bottom=2 }
        scroll:ClearAllPoints(); scroll:SetPoint("TOPLEFT",world,"TOPLEFT",2,-67)
        scroll:SetPoint("BOTTOMRIGHT",world,"BOTTOMRIGHT",-336,2)
        world:SetSize(1035,534)
        s.battlefield:ClearAllPoints(); s.battlefield:SetPoint("BOTTOMRIGHT",env.UIParent,"BOTTOMRIGHT",-20,80)
        s.battlefield.ScrollContainer:SetPoint("TOPLEFT",s.battlefield,"TOPLEFT",0,0)
        local rect = AnchorCoordinates(env,s)
        local canvas = world.canvas
        canvas:ClearAllPoints(); canvas:SetSize(1002,668)
        canvas:SetPoint("TOPLEFT",scroll,"TOPLEFT",0,0)
        local nativePin, player, guideGlyph, text, route, area = s.Frame(canvas),s.Frame(canvas),s.Frame(canvas),s.Frame(world),s.Frame(world),s.Frame(canvas)
        function world:GetCanvasScale() return s.nativeCanvasScale end
        function world:GetCanvasZoomPercent() return 0 end
        function world:GetGlobalPinScale() return 1 end
        nativePin.startScale,nativePin.endScale,nativePin.scaleFactor = 1,1,1
        function nativePin:GetMap() return world end
        function nativePin:IsIgnoringGlobalPinScale() return false end
        function nativePin:GetGlobalPinScale() return 1 end
        function nativePin:ApplyCurrentPosition() end
        function player:GetMap() return world end
        player.dataProvider = {
            EnumerateUnitPinSizes=function() return next,{player=27,party=11,raid=8.25} end,
            ShouldShowUnit=function() return true end,
        }
        player.unitSizes = {}
        function player:SetPinSize(unit,size) self.unitSizes[unit]=size end
        function player:SetPlayerPingScale(value) self.pingScale=value end
        local refreshes = 0
        function world:OnFrameSizeChanged()
            refreshes = refreshes+1
            s.nativeCanvasScale = math.min(scroll:GetWidth()/1002,scroll:GetHeight()/668)
            canvas:SetScale(s.nativeCanvasScale)
            applyPin(nativePin); synchronizeUnits(player)
            -- Polestar.MapCanvas.View:PinScale(1,1) uses the same inverse
            -- canvas factor; its direct text/route/area objects stay original.
            guideGlyph:SetScale(1/s.nativeCanvasScale)
        end
        world:OnFrameSizeChanged()
        local function Pixels()
            return { pin=16*nativePin:GetEffectiveScale(), player=player.unitSizes.player*player:GetEffectiveScale(),
                guide=14*guideGlyph:GetEffectiveScale(), text=12*text:GetEffectiveScale(),
                line=2*route:GetEffectiveScale(), area=100*area:GetEffectiveScale() }
        end
        local baseline, originalEffective = Pixels(),world:GetEffectiveScale()
        local baselineCanvas = s.nativeCanvasScale
        local nativePlayerSize,nativePinScale = player.unitSizes.player,nativePin:GetScale()
        local members = { nativePin,player,guideGlyph,text,route,area }
        s.bridge:Activate(s.battlefield); s:Flush()
        local mountedRefreshes = refreshes
        check(mountedRefreshes == 2,"native logical scene mounts with one native size refresh")
        local frames,hooks = #s.frames,#s.hooks
        for _, extent in ipairs({ {420,280},{280,420},{650,160},{360,240} }) do
            s.battlefield:SetSize(extent[1]+20,extent[2]+40)
            s.battlefield.ScrollContainer:SetSize(extent[1],extent[2])
            s.bridge:Sync(); s:Flush()
            local viewport = world:GetParent()
            CheckSceneFit(rect,scroll,viewport,"uniform native scene")
            check(math.abs(world:GetWidth()-697)<.000001 and math.abs(world:GetHeight()-465)<.000001,
                "all host aspect ratios preserve the original native logical scene")
            check(math.abs(s.nativeCanvasScale-baselineCanvas)<.000000001
                and player.unitSizes.player==nativePlayerSize and nativePin:GetScale()==nativePinScale,
                "host resize never changes native canvas zoom or inverse pin/player sizing")
            local ratio = world:GetEffectiveScale()/originalEffective
            local current = Pixels()
            for name,before in pairs(baseline) do
                check(math.abs(current[name]/before-ratio)<.000001,
                    "entire native world-map "..name.." uses the same relative pixel transform")
            end
            check(refreshes==mountedRefreshes,"host resize adds no native canvas-size refresh or zoom reset")
            check(nativePin:GetParent()==canvas and player:GetParent()==canvas and guideGlyph:GetParent()==canvas
                and text:GetParent()==world and route:GetParent()==world and area:GetParent()==canvas,
                "uniform scene scaling preserves all original native and addon object owners")
        end
        check(#s.frames==frames and #s.hooks==hooks,"uniform scene resize does not add frames or hooks")
        s.bridge:Deactivate(); s:Flush()
        world:SetSize(1200,800); world:OnFrameSizeChanged()
        s.bridge:Activate(s.battlefield); s:Flush()
        check(math.abs(world:GetWidth()-862)<.000001 and math.abs(world:GetHeight()-731)<.000001,
            "new source ownership captures its new normal native viewport instead of stale field geometry")
        s.bridge:Deactivate(); s:Flush()
        check(world:GetWidth()==1200 and world:GetHeight()==800,"new scene ownership restores its own full native dimensions")
    end
    print(actualNativeMethods and "Read-only native pin/player scale methods executed; GPU rendering remains unverified"
        or "Native map scale formula contracts modeled; optional native source mirror unavailable")
end

-- Public rendering-flag ownership only. These checks do not model GPU caches,
-- flattening semantics, or claim that changing flags fixes native rendering.
do
    local function NativeFlags(s, framebuffer, flatten)
        local world = s.world
        world.frameBuffer, world.flatten = framebuffer, flatten
        s.flagWrites = { framebuffer = 0, flatten = 0 }
        function world:IsFrameBuffer() return self.frameBuffer end
        function world:GetFlattensRenderLayers() return self.flatten end
        local function set(self, key, value)
            check(type(value) == "boolean", "native render flag receives an ordinary boolean")
            check(not s.combat, "native render flag is never changed in combat")
            check(not self:IsShown(), "native render flag changes only while original root is hidden")
            self[key] = value
            local counter = key == "frameBuffer" and "framebuffer" or "flatten"
            s.flagWrites[counter] = s.flagWrites[counter] + 1
        end
        function world:SetIsFrameBuffer(value) set(self, "frameBuffer", value) end
        function world:SetFlattensRenderLayers(value) set(self, "flatten", value) end
    end
    for _, original in ipairs({ {true,true}, {true,false}, {false,true}, {false,false} }) do
        local env, s = Runtime("forever")
        NativeFlags(s, original[1], original[2])
        local wantedFull = false
        s.world:HookScript("OnShow", function(self)
            check(self:IsFrameBuffer() == (wantedFull and original[1] or false)
                and self:GetFlattensRenderLayers() == (wantedFull and original[2] or false),
                "native source OnShow observes already-configured rendering flags")
        end)
        local marker, handler = s.arbitrary[4].marker, s.arbitrary[4]:GetScript("OnUpdate")
        s.bridge:Activate(s.battlefield); s:Flush()
        check(not s.world:IsFrameBuffer() and not s.world:GetFlattensRenderLayers(),
            "embedded native source disables framebuffer and flattening when APIs exist")
        local bw, fw = s.flagWrites.framebuffer, s.flagWrites.flatten
        check(bw == (original[1] and 1 or 0) and fw == (original[2] and 1 or 0),
            "initial native render flags change only when their saved values differ")
        for _ = 1, 50 do s.bridge:Sync() end
        s:Flush()
        check(s.flagWrites.framebuffer == bw and s.flagWrites.flatten == fw,
            "unchanged native source performs no repeated render-flag writes")
        wantedFull = true
        env.ToggleWorldMap(); s:Flush()
        check(s.world:IsFrameBuffer() == original[1] and s.world:GetFlattensRenderLayers() == original[2],
            "full native map restores exact original render flags before showing")
        wantedFull = false
        env.HideUIPanel(s.world); s:Flush()
        check(s.bridge:IsEmbedded() and not s.world:IsFrameBuffer() and not s.world:GetFlattensRenderLayers(),
            "return to Flux configures rendering while hidden before source show")
        s.bridge:Deactivate(); s:Flush()
        check(s.world:IsFrameBuffer() == original[1] and s.world:GetFlattensRenderLayers() == original[2],
            "feature release restores exact original native rendering flags")
        check(s.flagWrites.framebuffer == bw * 4 and s.flagWrites.flatten == fw * 4,
            "native rendering flag handoffs avoid redundant setter work")
        check(s.arbitrary[4].marker == marker and s.arbitrary[4]:GetScript("OnUpdate") == handler,
            "native rendering policy leaves original addon members and callbacks untouched")
    end
    do
        local _, s = Runtime("forever")
        NativeFlags(s, true, true)
        s.combat = true; s.bridge:Activate(s.battlefield); s:Flush()
        check(s.flagWrites.framebuffer == 0 and s.flagWrites.flatten == 0,
            "combat activation leaves original native render flags untouched")
        s.combat = false; s:Event("PLAYER_REGEN_ENABLED")
        s.combat = true; s.bridge:Deactivate(); s:Flush()
        check(not s.world:IsFrameBuffer() and not s.world:GetFlattensRenderLayers(),
            "combat release defers native render-flag restoration")
        s.combat = false; s:Event("PLAYER_REGEN_ENABLED")
        check(s.world:IsFrameBuffer() and s.world:GetFlattensRenderLayers(),
            "combat-end cleanup restores native render flags while hidden")
    end
    do
        local env, s = Runtime("forever")
        NativeFlags(s, true, true)
        s.bridge:Activate(s.battlefield)
        env.OpenWorldMap(62); s:Flush()
        check(not s.bridge:IsEmbedded() and s.world:IsShown() and s.world:IsFrameBuffer()
            and s.world:GetFlattensRenderLayers() and s.world:GetMapID() == 62,
            "full-map request during preparation restores hidden render state before normal show")
    end
end

-- The real native movement fader owns its active and deferred registrations.
-- Removing the adopted source must stop that existing driver from fading it;
-- another Flux opacity driver would merely mask the underlying ownership bug.
do
    local path = "F:/World of Warcraft/_retail_/Interface/AddOns/__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_FrameXMLBase/PlayerMovementFrameFader.lua"
    local file = io.open(path,"rb")
    if file then
        local nativeSource = file:read("*a"); file:close()
        local function NativeFader()
            local env,s = Runtime("forever")
            s.moving,s.mapFade,s.alphaWrites,s.removals,s.faderDrivers = false,true,0,0,0
            env.IsPlayerMoving = function() return s.moving end
            env.GetCVarBool = function(name) return name=="mapFade" and s.mapFade or false end
            env.SetCVar = function() error("embedded opacity must not change client preferences") end
            env.DeltaLerp = function(a,b,amount,elapsed)
                return a+(b-a)*math.max(0,math.min(1,amount*elapsed*60))
            end
            local create = env.CreateFrame
            env.CreateFrame = function(kind,...)
                local frame = create(kind,...)
                if kind=="FRAME" then s.faderDriver=frame; s.faderDrivers=s.faderDrivers+1 end
                return frame
            end
            local fn
            if setfenv then fn=assert(loadstring(nativeSource)); setfenv(fn,env)
            else fn=assert(load(nativeSource,"native-player-movement-fader","t",env)) end
            fn()
            local service = env.PlayerMovementFrameFader
            local remove = service.RemoveFrame
            function service.RemoveFrame(frame,...)
                if frame==s.world then s.removals=s.removals+1 end
                return remove(frame,...)
            end
            local setAlpha = s.world.SetAlpha
            function s.world:SetAlpha(value)
                s.alphaWrites=s.alphaWrites+1
                return setAlpha(self,value)
            end
            function s.world:IsMouseOver() return false end
            s.world:SetScript("OnShow",function(self)
                service.AddDeferredFrame(self,.5,1,.5,function() return env.GetCVarBool("mapFade") and not self:IsMouseOver() end)
            end)
            s.world:SetScript("OnHide",function(self) service.RemoveFrame(self) end)
            function s:Movement(moving)
                self.moving=moving
                local event=moving and "PLAYER_STARTED_MOVING" or "PLAYER_STOPPED_MOVING"
                if self.faderDriver then self.faderDriver.scripts.OnEvent(self.faderDriver,event) end
            end
            function s:FadeTicks(count)
                if self.faderDriver then
                    for _=1,count do self.faderDriver.scripts.OnUpdate(self.faderDriver,1/60) end
                end
            end
            return env,s,service
        end
        do
            local env,s,service = NativeFader()
            s.world:SetAlpha(.73)
            local other=s.Frame(env.UIParent)
            service.AddFrame(other,.2,1,.5)
            local add,addDeferred,remove = service.AddFrame,service.AddDeferredFrame,service.RemoveFrame
            local marker,handler = s.arbitrary[4].marker,s.arbitrary[4]:GetScript("OnUpdate")
            s.bridge:Activate(s.battlefield)
            check(s.world:GetAlpha()==0,"native movement-fader removal preserves invisible source preparation")
            s:Movement(true); s:FadeTicks(3)
            check(s.world:GetAlpha()==0,"native movement events cannot reveal a still-preparing source")
            s:Flush()
            check(s.bridge:IsEmbedded() and s.world:GetAlpha()==1,"embedded original source is always fully opaque despite its prior alpha")
            s:Movement(true); s:FadeTicks(30)
            check(s.world:GetAlpha()==1 and other:GetAlpha()<1,"native driver still fades unrelated frames while adopted source stays opaque")
            s:Movement(false); s:FadeTicks(30)
            check(s.world:GetAlpha()==1,"native stop-moving events keep the embedded source fully opaque")
            s.world:Hide(); s.world:Show()
            check(s.world:GetAlpha()==1,"late native OnShow remains fully opaque after its deferred registration")
            s:Movement(true); s:FadeTicks(10)
            check(s.world:GetAlpha()==1,"late native OnShow deferred entry is removed before movement can merge it")
            s:Flush()
            local removals,writes,hooks,frames = s.removals,s.alphaWrites,#s.hooks,#s.frames
            for _=1,1000 do s.bridge:Sync() end
            s:Flush()
            check(s.removals==removals and s.alphaWrites==writes,"1000 unchanged syncs perform no native fader removals or opacity writes")
            check(#s.hooks==hooks and #s.frames==frames and s.faderDrivers==1,"opaque source adds no recurring opacity driver or hook growth")
            check(service.AddFrame==add and service.AddDeferredFrame==addDeferred and service.RemoveFrame==remove,
                "embedded opacity preserves shared native movement-fader methods")
            check(s.arbitrary[4].marker==marker and s.arbitrary[4]:GetScript("OnUpdate")==handler,
                "opaque presentation preserves original addon pin data and callbacks")
            s.bridge:Deactivate(); s:Flush()
            check(not s.world:IsShown() and s.world:GetAlpha()==.73,"feature release restores source opacity captured before preparation")
            local alpha=s.world:GetAlpha()
            s:Movement(true); s:FadeTicks(10)
            check(s.world:GetAlpha()==alpha,"released hidden source retains no stale deferred movement-fader entry")
        end
        do
            local env,s = NativeFader()
            s.world:SetAlpha(.64)
            s.bridge:Activate(s.battlefield); s:Flush()
            env.ToggleWorldMap(); s:Flush()
            check(not s.bridge:IsEmbedded() and s.world:IsShown() and s.world:GetAlpha()==.64,
                "normal full-map handoff restores original alpha before native fading resumes")
            s:Movement(true); s:FadeTicks(20)
            local faded=s.world:GetAlpha()
            check(faded<.64 and faded>=.5,"normal full World Map retains its native movement fade")
            s:Movement(false); s:FadeTicks(20)
            check(s.world:GetAlpha()>faded,"normal full World Map retains native stop-moving fade recovery")
            env.HideUIPanel(s.world); s:Flush()
            s:Movement(true); s:FadeTicks(20)
            check(s.bridge:IsEmbedded() and s.world:GetAlpha()==1,"return from normally faded full map is opaque only inside Flux")
        end
        do
            local env,s = NativeFader()
            s.world:SetAlpha(.61)
            s.bridge:Activate(s.battlefield)
            s.bridge:Deactivate(); s:Flush()
            s:Movement(true); s:FadeTicks(20)
            check(not s.world:IsShown() and s.world:GetAlpha()==.61,"cancelling source preparation preserves alpha and removes native deferred fade")
            s.bridge:Activate(s.battlefield)
            env.OpenWorldMap(62); s:Flush()
            s:Movement(true); s:FadeTicks(20)
            check(not s.bridge:IsEmbedded() and s.world:IsShown() and s.world:GetMapID()==62 and s.world:GetAlpha()<.61,
                "full-map request during preparation retains native fade and requested map")
        end
        do
            local _,s = NativeFader()
            s.world:SetAlpha(.69); s.world:Show()
            s.bridge:Activate(s.battlefield); s:Flush()
            s:Movement(true); s:FadeTicks(20)
            check(not s.bridge:IsEmbedded() and s.world:GetAlpha()<.69,
                "preexisting normal full World Map keeps native fading when Flux feature activates")
            s.bridge:Deactivate(); s:Flush()
            local faded=s.world:GetAlpha()
            s:Movement(false); s:FadeTicks(20)
            check(s.world:IsShown() and s.world:GetAlpha()>faded,
                "disabling Flux while normal full map is open preserves its native fader registration")
        end
        do
            local env,s = NativeFader()
            s.mapFade=false; s.world:SetAlpha(.71)
            s.bridge:Activate(s.battlefield); s:Flush()
            env.ToggleWorldMap(); s:Flush()
            s:Movement(true); s:FadeTicks(20)
            check(not s.bridge:IsEmbedded() and s.world:GetAlpha()>.71 and not s.mapFade,
                "normal full-map native predicate retains disabled mapFade preference")
        end
        print("Read-only native PlayerMovementFrameFader executed; no native pixels/FPS claim")
    else
        print("Optional native movement-fader source unavailable; native fade integration not run")
    end
end

-- A later native panel/layout writer can leave the original root at native
-- coordinates even though Flux still owns its parent and its fit cache matches.
-- Validate actual anchor tuples and event ownership; these are Lua geometry
-- checks, not a substitute for native clipping/compositor acceptance.
do
    local function RootAnchored(world, host)
        if world:GetParent() ~= host or world:GetNumPoints() ~= 1 then return false end
        local p,r,rp,x,y = world:GetPoint(1)
        local scale = world:GetScale()
        local wantedX = (host:GetWidth()/scale-world:GetWidth())/2
        local wantedY = -(host:GetHeight()/scale-world:GetHeight())/2
        return p=="TOPLEFT" and r==host and rp=="TOPLEFT" and type(x)=="number" and type(y)=="number"
            and math.abs(x-wantedX)<.000001 and math.abs(y-wantedY)<.000001
    end
    local function ScrollAnchored(world)
        local scroll = world.ScrollContainer
        if scroll:GetNumPoints()~=2 then return false end
        local corners = {}
        for i=1,2 do
            local p,r,rp,x,y = scroll:GetPoint(i)
            if (p~="TOPLEFT" and p~="BOTTOMRIGHT") or r~=world or rp~=p or x~=0 or y~=0 or corners[p] then return false end
            corners[p] = true
        end
        return corners.TOPLEFT and corners.BOTTOMRIGHT
    end
    local function Writes(world)
        return (world.geometryWrites or 0)+(world.ScrollContainer.geometryWrites or 0)
    end
    for _,client in ipairs({"retail","forever","classic","era","anniversary"}) do
        local env,s = Runtime(client)
        local rect = AnchorCoordinates(env,s)
        local canvasRefreshes = 0
        function s.world:OnFrameSizeChanged() canvasRefreshes = canvasRefreshes+1 end
        local hiddenOwner = s.Frame(env.UIParent); hiddenOwner:Hide()
        local chrome = s.Frame(s.world); s.world.BorderFrame = chrome
        local rewriteOnShow,reflows = false,0
        s.world:HookScript("OnShow",function(self)
            if not rewriteOnShow then return end
            rewriteOnShow,reflows = false,reflows+1
            self:SetSize(1200,900); self:SetScale(.9); self:SetIgnoreParentScale(true)
            self:ClearAllPoints(); self:SetPoint("TOPLEFT",env.UIParent,"TOPLEFT",16,-374)
            self.ScrollContainer:ClearAllPoints()
            self.ScrollContainer:SetPoint("TOPLEFT",self,"TOPLEFT",30,-150)
            self.ScrollContainer:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",-70,50)
            self:EnableMouse(true); self:SetShouldNavigateOnClick(true)
            chrome:Show()
        end)
        env.UIParent:SetScale(.75)
        s.battlefield.ScrollContainer.left,s.battlefield.ScrollContainer.bottom = 1543.543,19.35
        s.battlefield.ScrollContainer:SetSize(402.3,268.65)
        s.bridge:Activate(s.battlefield); s:Flush()
        local world,host = s.world,s.world:GetParent()
        local width,height,scale = world:GetWidth(),world:GetHeight(),world:GetScale()
        local mountedRefreshes = canvasRefreshes
        check(RootAnchored(world,host) and ScrollAnchored(world),client.." initial fit exposes native root/scroll anchor tuples")
        -- Bypass hooks deliberately: an explicit Sync must verify actual layout,
        -- independently of whether any setter callback invalidated the cache.
        world.points = {{"TOPLEFT",env.UIParent,"TOPLEFT",16,-374}}
        check(world:GetParent()==host and world:GetWidth()==width and world:GetHeight()==height and world:GetScale()==scale,
            client.." reproduced missing scene retains cached fit dimensions and owned parent")
        s.bridge:Sync(); s:Flush()
        check(RootAnchored(world,host),client.." explicit sync repairs native-coordinate root anchor despite a matching fit cache")
        CheckSceneFit(rect,world,host,client.." recovered original root")
        local p,r,rp,x,y = world:GetPoint(1)
        world.points = {{p,r,rp,x+8,y-5}}
        s.bridge:Sync(); s:Flush()
        check(RootAnchored(world,host),client.." explicit sync repairs incorrect centered offsets")
        world.points[#world.points+1] = {"BOTTOMRIGHT",env.UIParent,"BOTTOMRIGHT",0,0}
        s.bridge:Sync(); s:Flush()
        check(RootAnchored(world,host),client.." explicit sync rejects an extra root anchor")
        world.points = {}
        s.bridge:Sync(); s:Flush()
        check(RootAnchored(world,host),client.." explicit sync repairs missing root anchors")
        check(canvasRefreshes==mountedRefreshes,client.." root anchor-only corrections do not resize or reset the native canvas")
        local scroll = world.ScrollContainer
        scroll.allPoints = nil
        scroll.points = {{"TOPLEFT",world,"TOPLEFT",30,-150},{"BOTTOMRIGHT",world,"BOTTOMRIGHT",-70,50}}
        s.bridge:Sync(); s:Flush()
        check(ScrollAnchored(world),client.." explicit sync repairs native inset scroll anchors despite a mounted cache")
        scroll.points[1],scroll.points[2] = scroll.points[2],scroll.points[1]
        local writes = Writes(world)
        s.bridge:Sync(); s:Flush()
        check(ScrollAnchored(world) and Writes(world)==writes,client.." valid reversed scroll corner order needs no layout writes")
        local callbacks = {
            {"root SetPoint",function() world:SetPoint("BOTTOMRIGHT",env.UIParent,"BOTTOMRIGHT",0,0) end},
            {"root ClearAllPoints",function() world:ClearAllPoints() end},
            {"root SetAllPoints",function() world:SetAllPoints(env.UIParent) end},
            {"root SetParent",function() world:SetParent(env.UIParent) end},
            {"root SetScale",function() world:SetScale(scale*1.3) end},
            {"root SetIgnoreParentScale",function() world:SetIgnoreParentScale(true) end},
            {"scroll SetPoint",function() scroll:SetPoint("CENTER",env.UIParent,"CENTER",12,9) end},
            {"scroll ClearAllPoints",function() scroll:ClearAllPoints() end},
            {"scroll SetAllPoints",function() scroll:SetAllPoints(env.UIParent) end},
        }
        for _,entry in ipairs(callbacks) do
            check(#s.timers==0,client.." stable layout has no pending repair before "..entry[1])
            local schedules = s.timerSchedules
            entry[2]()
            check(#s.timers==1 and s.timerSchedules==schedules+1,client.." "..entry[1].." queues one deferred geometry repair")
            s:Flush()
            check(s.bridge:IsEmbedded() and RootAnchored(world,host) and ScrollAnchored(world),
                client.." "..entry[1].." repairs only the currently hosted original scene")
            CheckSceneFit(rect,world,host,client.." "..entry[1].." recovered root")
            check(#s.timers==0,client.." own fit writes do not leave recursive repair callbacks")
        end
        local frames,hooks,scans,schedules = #s.frames,#s.hooks,s.scans,s.timerSchedules
        for i=1,1000 do
            world:ClearAllPoints()
            world:SetPoint("TOPLEFT",env.UIParent,"TOPLEFT",16+i,-374)
        end
        check(#s.timers==1 and s.timerSchedules==schedules+1,client.." 1000 native positioning bursts coalesce into one queued repair")
        s:Flush()
        check(RootAnchored(world,host) and ScrollAnchored(world),client.." positioning burst restores actual scene anchors")
        check(#s.frames==frames and #s.hooks==hooks and s.scans==scans,
            client.." geometry recovery adds no frames, hooks or canvas scans")
        writes = Writes(world)
        schedules = s.timerSchedules
        for _=1,1000 do s.bridge:Sync() end
        s:Flush()
        check(Writes(world)==writes and s.timerSchedules==schedules,
            client.." 1000 unchanged syncs write no root/scroll geometry and schedule no repairs")
        local originalPin = s.arbitrary[4]
        local pinPixels = originalPin:GetWidth()*originalPin:GetEffectiveScale()
        local marker,handler = originalPin.marker,originalPin:GetScript("OnUpdate")
        rewriteOnShow = true
        schedules = s.timerSchedules
        world:SetParent(hiddenOwner)
        check(not world:IsVisible() and #s.timers==1,client.." a hidden foreign owner queues one current-source repair")
        s:Flush()
        check(reflows==1 and world:IsVisible() and s.bridge:IsEmbedded() and RootAnchored(world,host) and ScrollAnchored(world),
            client.." parent repair settles synchronous native OnShow root and scroll rewrites")
        check(world:GetWidth()==width and world:GetHeight()==height and math.abs(world:GetScale()-scale)<.000001
            and not world:IsIgnoringParentScale(),client.." native OnShow cannot replace the captured uniformly scaled scene")
        check(not chrome:IsShown() and not world:IsMouseEnabled() and not world:ShouldNavigateOnClick(),
            client.." parent repair settles native OnShow chrome and battlefield input presentation")
        check(math.abs(originalPin:GetWidth()*originalPin:GetEffectiveScale()-pinPixels)<.000001
            and originalPin.marker==marker and originalPin:GetScript("OnUpdate")==handler,
            client.." parent repair preserves original addon pin identity and relative pixel scale")
        CheckSceneFit(rect,world,host,client.." native OnShow recovered root")
        check(#s.timers==0 and s.timerSchedules-schedules<=3 and #s.frames==frames and #s.hooks==hooks,
            client.." native OnShow parent recovery settles within three queued turns without owner growth")
        writes,schedules = Writes(world),s.timerSchedules
        for _=1,1000 do s.bridge:Sync() end
        s:Flush()
        check(Writes(world)==writes and s.timerSchedules==schedules,
            client.." settled parent recovery adds no steady geometry writes or repair loop")
        -- The queued field repair must lose to an explicit normal-map request.
        world:ClearAllPoints(); world:SetPoint("TOPLEFT",env.UIParent,"TOPLEFT",16,-374)
        env.ToggleWorldMap(); s:Flush()
        check(not s.bridge:IsEmbedded() and world:IsVisible() and world:GetParent()==env.UIParent,
            client.." full-map key preempts an already queued field-anchor repair")
        world:ClearAllPoints(); world:SetPoint("CENTER",env.UIParent,"CENTER",44,-28); world:SetScale(.8)
        check(#s.timers==0,client.." normal full-map geometry writers do not schedule field repair")
        s.bridge:Sync(); s:Flush()
        p,r,rp,x,y = world:GetPoint(1)
        check(world:GetParent()==env.UIParent and p=="CENTER" and r==env.UIParent and x==44 and y==-28 and world:GetScale()==.8,
            client.." field ownership never reclaims the open normal World Map")
        env.ToggleWorldMap(); s:Flush()
        check(s.bridge:IsEmbedded() and RootAnchored(world,host),client.." normal-map close resumes actual field fit")
        -- Simulate native geometry settling just before lockdown: no Flux
        -- correction is allowed until the existing regen event resumes it.
        world:ClearAllPoints(); world:SetPoint("TOPLEFT",env.UIParent,"TOPLEFT",16,-374)
        s.combat = true
        writes = Writes(world)
        s:Flush()
        check(Writes(world)==writes and not RootAnchored(world,host) and #s.timers==0,
            client.." combat defers queued root repair without timer churn or native writes")
        scroll:ClearAllPoints(); scroll:SetPoint("TOPLEFT",world,"TOPLEFT",30,-150)
        writes = Writes(world)
        s:Flush()
        check(Writes(world)==writes and not ScrollAnchored(world),client.." combat-time scroll writer cannot trigger restricted fit writes")
        s.combat=false; s:Event("PLAYER_REGEN_ENABLED")
        check(RootAnchored(world,host) and ScrollAnchored(world),client.." combat-end event repairs deferred actual scene geometry")
        world:ClearAllPoints(); world:SetPoint("TOPLEFT",env.UIParent,"TOPLEFT",16,-374)
        s.bridge:Deactivate(); s:Flush()
        check(not s.bridge:IsEmbedded() and world:GetParent()==env.UIParent and not world:IsShown(),
            client.." disabling the feature cancels an already queued field repair")
        schedules = s.timerSchedules
        world:ClearAllPoints(); world:SetPoint("CENTER",env.UIParent,"CENTER",7,11); world:SetScale(.85)
        scroll:ClearAllPoints(); scroll:SetAllPoints(world)
        check(#s.timers==0 and s.timerSchedules==schedules,client.." disabled source geometry callbacks schedule no work")
        check(#s.frames==frames and #s.hooks==hooks and s.scans==scans,
            client.." recovery and handoff retain bounded geometry ownership")
    end
end

print("Original world-map surface lifecycle PASS: " .. checks .. " checks")
