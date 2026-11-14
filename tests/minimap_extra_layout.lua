-- Exercises the actual minimap extra-button controller with strict structural
-- combat guards. Desktop geometry/state-driver checks do not certify engine taint,
-- native pixels, secure input, controller navigation or FPS.
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function near(a, b, why) check(math.abs(a - b) < .001, why .. ": " .. tostring(a) .. " / " .. tostring(b)) end
local function read(path)
    local f = assert(io.open(path, "rb")); local value = f:read("*a"):gsub("\r\n", "\n"); f:close(); return value
end
local source = read(os.getenv("FLUX_MINIMAP_EXTRA_SOURCE") or "Minimap/FluxMinimapButtons.lua")
local unpack = table.unpack or unpack

local function boot(saved, change)
    local env = setmetatable({}, {__index = _G}); env._G = env
    local t = {combat = false, frames = {}, widgets = {}, creates = 0, actions = 0,
        deferred = {}, timers = {}, tickers = {}, drivers = {}, secure = false, supported = true, structuralWrites = 0,
        embedded = false, mapVisible = true, saved = saved or {}}
    local function structural(what)
        t.structuralWrites = t.structuralWrites + 1
        assert(not t.combat or t.secure, "no insecure combat mutation: " .. what)
    end
    local anchor = {
        TOPLEFT = {0, 1}, TOP = {.5, 1}, TOPRIGHT = {1, 1}, LEFT = {0, .5},
        CENTER = {.5, .5}, RIGHT = {1, .5}, BOTTOMLEFT = {0, 0},
        BOTTOM = {.5, 0}, BOTTOMRIGHT = {1, 0},
    }
    local frameID = 0
    local function frame(name, parent, template)
        frameID = frameID + 1
        local f = {name = name, parent = parent, template = template, width = 0,
            height = 0, scale = 1, shown = true, points = {}, scripts = {}, events = {},
            attributes = {}, id = frameID}
        function f:GetName() return self.name end
        function f:GetParent() return self.parent end
        function f:SetParent(value) structural("SetParent"); self.parent = value end
        function f:SetSize(w, h) structural("SetSize"); self.width, self.height = w, h end
        function f:SetWidth(w) structural("SetWidth"); self.width = w end
        function f:SetHeight(h) structural("SetHeight"); self.height = h end
        function f:GetWidth() return self.width end
        function f:GetHeight() return self.height end
        function f:GetSize() return self.width, self.height end
        function f:SetScale(value) structural("SetScale"); self.scale = value end
        function f:GetScale() return self.scale end
        function f:GetEffectiveScale() return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end
        function f:ClearAllPoints() structural("ClearAllPoints"); self.points = {}; self.allPoints = nil end
        function f:SetPoint(point, relative, relativePoint, x, y)
            structural("SetPoint")
            if type(relative) == "string" then relative = assert(env[relative]) end
            self.points[#self.points + 1] = {point, relative or self.parent, relativePoint or point, x or 0, y or 0}
        end
        function f:GetPoint(i) return unpack(self.points[i or 1] or {}) end
        function f:GetNumPoints() return #self.points end
        function f:SetAllPoints(relative) structural("SetAllPoints"); self.allPoints = relative or self.parent end
        function f:rect()
            local s = self:GetEffectiveScale()
            if self.allPoints then return self.allPoints:rect() end
            local w, h = self.width * s, self.height * s
            local p = self.points[1]
            if not p then return self.left or 0, self.bottom or 0, w, h end
            local x, y, rw, rh = p[2]:rect()
            local own, rel = assert(anchor[p[1]]), assert(anchor[p[3]])
            return x + rw * rel[1] + p[4] * s - w * own[1],
                y + rh * rel[2] + p[5] * s - h * own[2], w, h
        end
        function f:GetLeft() local x = self:rect(); return x / self:GetEffectiveScale() end
        function f:GetBottom() local _, y = self:rect(); return y / self:GetEffectiveScale() end
        function f:GetRight() local x, _, w = self:rect(); return (x + w) / self:GetEffectiveScale() end
        function f:GetTop() local _, y, _, h = self:rect(); return (y + h) / self:GetEffectiveScale() end
        function f:GetRect() local x, y, w, h = self:rect(); local s = self:GetEffectiveScale(); return x/s, y/s, w/s, h/s end
        function f:Show() structural("Show"); self.shown = true end
        function f:Hide() structural("Hide"); self.shown = false end
        function f:SetShown(on) if on then self:Show() else self:Hide() end end
        function f:IsShown() return self.shown end
        function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function f:SetAttribute(key, value) structural("SetAttribute"); self.attributes[key] = value end
        function f:GetAttribute(key) return self.attributes[key] end
        function f:SetFrameStrata(value) structural("SetFrameStrata"); self.strata = value end
        function f:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or "MEDIUM" end
        function f:SetFrameLevel(value) structural("SetFrameLevel"); self.level = value end
        function f:GetFrameLevel() return self.level or 0 end
        function f:EnableMouse(value) structural("EnableMouse"); self.mouse = value end
        function f:SetClipsChildren(value) structural("SetClipsChildren"); self.clips = value end
        function f:SetClampedToScreen(value) structural("SetClampedToScreen"); self.clamped = value end
        function f:SetScript(key, fn) self.scripts[key] = fn end
        function f:GetScript(key) return self.scripts[key] end
        function f:HookScript(key, fn)
            local previous = self.scripts[key]
            self.scripts[key] = function(...) if previous then previous(...) end; fn(...) end
        end
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:IsEventRegistered(event) return self.events[event] end
        t.frames[#t.frames + 1] = f
        if name then env[name] = f end
        return f
    end
    env.CreateFrame = function(_, name, parent, template) structural("CreateFrame"); return frame(name, parent, template) end
    env.UIParent = frame("UIParent"); env.UIParent:SetSize(1920, 1080)
    env.Minimap = frame("Minimap", env.UIParent); env.Minimap:SetSize(190, 190)
    env.Minimap:SetPoint("TOPRIGHT", env.UIParent, "TOPRIGHT", -24, -30)
    t.window = frame("FluxWindow", env.UIParent); t.window:SetSize(540, 292)
    t.window:SetPoint("BOTTOMRIGHT", env.UIParent, "BOTTOMRIGHT", -20, 25)
    env.FluxWindowFrame = {frame = t.window, GetFrame = function() return t.window end}
    env.FluxMinimap = {
        IsEmbedded = function() return t.embedded end,
        IsEmbeddedVisible = function() return t.mapVisible end,
        GetNormalWidth = function() return 190 end,
        UpdateQuestTrackerPosition = function() t.trackerUpdates = (t.trackerUpdates or 0) + 1 end,
        EnforcePosition = function() t.positionUpdates = (t.positionUpdates or 0) + 1 end,
        RefreshEmbeddedLayout = function()
            t.embeddedUpdates = (t.embeddedUpdates or 0) + 1
            if env.FluxMinimapButtons then env.FluxMinimapButtons:RefreshLayout() end
        end,
    }
    env._FluxUI_CharSavedVars = t.saved
    env.InCombatLockdown = function() return t.combat end
    env.wipe = function(tab) for key in pairs(tab) do tab[key] = nil end; return tab end
    env.GetMacroInfo = function(i) if i == 1 then return "Saved Macro", nil, "/say preserved" end end
    env.GetCursorInfo = function() return t.cursorType, t.cursorValue end
    env.GetCursorPosition = function() return t.cursorX or 0, t.cursorY or 0 end
    env.C_Timer = {
        After = function(_, fn) t.timers[#t.timers + 1] = fn end,
        NewTicker = function(interval, fn)
            local timer = {interval = interval, callback = fn}
            function timer:Cancel() self.cancelled = true end
            t.tickers[#t.tickers + 1] = timer
            return timer
        end,
    }
    env.Flux = {Combat = {Defer = function(key, fn) t.deferred[key] = fn end}}
    env.Flux.Restricted = {
        PagingWorks = function() return t.supported end,
        RegisterPagingDriver = function(host, state, values)
            structural("RegisterPagingDriver")
            check(t.supported, "unsupported secure engine cannot register visibility")
            t.drivers[host] = {state = state, values = values}
            return true
        end,
        UnregisterPagingDriver = function(host) structural("UnregisterPagingDriver"); t.drivers[host] = nil; return true end,
        SetPagingSnippet = function(host, key, value) host:SetAttribute(key, value); return true end,
    }
    env.Flux.Engine = {Restricted = env.Flux.Restricted}
    env.Flux.EBS = {
        Widget = {Create = function(parent, config)
            structural("EBS.Create"); t.creates = t.creates + 1
            local w = frame(config.name, parent, "SecureActionButtonTemplate"); w:SetSize(config.size, config.size)
            local b = {Widget = w, config = config}
            t.widgets[#t.widgets + 1] = b
            return b
        end},
        Action = {
            SetAction = function(btn, actionType, value)
                structural("SetAction"); t.actions = t.actions + 1; btn.actionType, btn.actionValue = actionType, value
            end,
            Clear = function(btn) structural("ClearAction"); btn.actionType, btn.actionValue = nil, nil end,
        },
        Style = {Apply = function() structural("Style.Apply") end},
        Flyout = {BindHost = function(widget, options)
            structural("Flyout.BindHost")
            assert(options.visibilityParent == widget:GetParent(), "flyout joins slot visibility gate, including hidden excess slots")
        end},
        UnregisterButton = function() error("shrinking/repositioning must reuse existing registered buttons") end,
    }
    if change then change(t, env) end
    assert(load(source, "@minimap extra-button runtime", "t", env))("_FluxUI", {Flux = env.Flux})
    t.api, t.env = assert(env.FluxMinimapButtons), env
    function t:event(name)
        local listeners = {}; for _, f in ipairs(self.frames) do listeners[#listeners + 1] = f end
        for _, f in ipairs(listeners) do if f.events[name] and f.scripts.OnEvent then f.scripts.OnEvent(f, name) end end
    end
    function t:flush()
        local q = self.deferred; self.deferred = {}; for _, fn in pairs(q) do fn() end
        local timers = self.timers; self.timers = {}; for _, fn in ipairs(timers) do fn() end
    end
    function t:tick()
        local timers = {}; for _, timer in ipairs(self.tickers) do timers[#timers + 1] = timer end
        for _, timer in ipairs(timers) do if not timer.cancelled then timer.callback() end end
    end
    function t:combatState(on)
        self.combat = on
        self.secure = true
        for host, driver in pairs(self.drivers) do
            check(driver.state == "visibility" and driver.values == "[combat] hide; show", "native visibility driver contract")
            host:SetShown(not on)
        end
        self.secure = false
        self:event(on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
        if not on then self:flush() end
    end
    function t:visible()
        local result = {}; for _, b in ipairs(self.widgets) do if b.Widget:IsVisible() then result[#result + 1] = b end end; return result
    end
    function t:embed(mapSize)
        self.embedded, self.mapVisible = true, true
        self.env.Minimap:SetParent(self.window)
        self.env.Minimap:SetScale(1)
        self.env.Minimap:SetSize(mapSize or 256, mapSize or 256)
        self.env.Minimap:ClearAllPoints(); self.env.Minimap:SetPoint("TOPRIGHT", self.window, "TOPRIGHT", 0, -22)
        self.api:PositionInWindow(self.window, mapSize or 256, 22, 0)
        self.api:OnEmbedStateChanged(true)
    end
    function t:normal()
        self.embedded = false
        self.env.Minimap:SetParent(self.env.UIParent); self.env.Minimap:SetSize(190, 190)
        self.env.Minimap:ClearAllPoints(); self.env.Minimap:SetPoint("TOPRIGHT", self.env.UIParent, "TOPRIGHT", -24, -30)
        self.api:OnEmbedStateChanged(false); self.api:RefreshLayout()
    end
    t:event("PLAYER_LOGIN"); t:flush()
    return t
end

local function physical(frame)
    local x, y, w, h = frame:rect(); return {left=x, bottom=y, right=x+w, top=y+h, width=w, height=h}
end
local function within(buttons, left, bottom, right, top, why)
    for i, b in ipairs(buttons) do
        local p = physical(b.Widget)
        check(p.left >= left-.001 and p.right <= right+.001 and p.bottom >= bottom-.001 and p.top <= top+.001,
            why .. ": button " .. i .. " outside bounds")
    end
end

local t = boot({unrelated = {keep = true}, minimapExtraButtons = {
    [1] = {dataType = "spell", data = 123}, [15] = {dataType = "item", data = 456},
    [60] = {dataType = "macro", data = 1, macroName = "Saved Macro", macroBody = "/say preserved"},
}})
check(t.api:GetSetting("count") == 15 and t.api:GetSetting("embeddedColumns") == nil, "shared count default and automatic embedded columns")
check(t.api:GetSetting("sideEnabled") == false and t.api:GetSetting("hideInCombat") == false, "new side/combat features opt in")
near(t.api:GetSetting("sideScale"),100,"missing layout table reads new scale default safely")
check(#t:visible() == 0, "normal minimap has no side strip by default")
check(t.creates == 0 and #t.timers == 0, "disabled side strip allocates no buttons or timer work")
t:embed()
check(#t:visible() == 15 and t.creates == 15, "existing embed creates fifteen real EBS widgets")
t.window:Hide(); t.api:RefreshLayout()
check(#t:visible() == 0, "hidden Flux Window hides embedded widgets through inherited visibility")
t.window:Show(); t.api:RefreshLayout()
check(#t:visible() == 15, "showing Flux Window restores embedded widgets")
check(t.widgets[1].actionType == "spell" and t.widgets[1].actionValue == 123, "legacy first assignment hydrated")
check(t.widgets[15].actionType == "item" and t.widgets[15].actionValue == 456, "legacy last assignment hydrated")
local identities = {}; for i, b in ipairs(t.widgets) do identities[i] = b.Widget end
local first, second, fourth = physical(t.widgets[1].Widget), physical(t.widgets[2].Widget), physical(t.widgets[4].Widget)
check(second.left > first.left and second.top == first.top and fourth.top < first.top,
    "embedded original row-major assignment order")
local window, map = physical(t.window), physical(t.env.Minimap)
within(t:visible(), window.left, window.bottom, map.left, window.top, "default embed remaining area")
local defaultSize = first.width
t.api:SetSetting("count", 60)
check(#t:visible() == 60 and t.creates == 60, "count may grow beyond original fifteen")
check(physical(t.widgets[1].Widget).width < defaultSize, "more embedded rows auto-shrink")
within(t:visible(), window.left, window.bottom, map.left, window.top, "expanded embed remains inside map-free area")
check(t.widgets[60].actionType == "macro" and t.widgets[60].actionValue.body == "/say preserved", "higher saved slots survive old count")
t.api:SetSetting("count", 4)
check(#t:visible() == 4 and t.creates == 60, "count shrink hides excess without recreation")
check(t.saved.minimapExtraButtons[60].macroBody == "/say preserved", "shrink preserves hidden action records")
t.api:SetSetting("count", 60)
check(#t:visible() == 60 and t.creates == 60, "regrow reuses all existing buttons")
for i, widget in ipairs(identities) do check(t.widgets[i].Widget == widget, "original widget identity " .. i) end
check(t.saved.unrelated.keep, "unrelated character data retained")
local hydrated = t.actions
for _ = 1, 20 do t.api:RefreshLayout() end
check(t.actions == hydrated and t.creates == 60, "settled layout refresh does not rehydrate or recreate actions")

t:normal()
check(#t:visible() == 0, "returning to normal keeps opt-in side mode disabled")
t.api:SetSetting("count", 8)
t.api:SetSetting("sideEnabled", true)
check(#t:visible() == 8, "optional side strip shares existing widgets")
check(t.creates == 60 and t.widgets[1].Widget == identities[1], "embed-to-side does not duplicate set")
local before = physical(t.widgets[1].Widget)
near(before.width, 44*.85, "new default uses old85percent standard button size")
local sideWidth = t.api:GetSideWidth()
check(sideWidth >= 44*.85 and sideWidth <= 60, "one-column reserve has only button plus padding")
local offset = t.api:GetTrackerOffset()
check(offset < 0, "below-minimap mode reserves tracker space to its left")
local above = physical(t.window).top
local below = physical(t.env.Minimap).bottom
within(t:visible(), 1920-sideWidth, above, 1920, below, "below-minimap side bounds")
local a, b = physical(t.widgets[1].Widget), physical(t.widgets[2].Widget)
check(a.left == b.left and a.top > b.top, "side fills downward first")

t.api:SetSetting("count", 20)
check(#t:visible() == 20, "two columns preserve shared count")
check(physical(t.widgets[1].Widget).width > 0 and physical(t.widgets[1].Widget).width <= 44, "automatic full-height buttons stay within standard size")
local previous, wrapped, usedLeft = nil, false, {}
for _, btn in ipairs(t:visible()) do
    local p = physical(btn.Widget); usedLeft[p.left] = true
    if previous then
        if p.left < previous.left-.001 then
            wrapped = true
            check(p.top > previous.top, "next side column restarts at top")
            check(previous.bottom < above + 44 + 12, "first column fills available vertical space")
        else
            check(not wrapped or p.left <= previous.left+.001, "never return to right column")
            near(p.left, previous.left, "same column x")
            check(p.top < previous.top, "same column descends")
        end
    end
    previous = p
end
check(wrapped, "two-column below-map layout wraps once first column fills")
local twoWidth = t.api:GetSideWidth()
t.api:SetSetting("count", 40)
check(t.api:GetSideWidth() <= 88 + .001, "automatic dense columns fit two standard columns of width")
check(physical(t.widgets[1].Widget).width < 44, "automatic dense layout shrinks standard buttons")
t.api:SetSetting("sideStart", "top")
check(t.api:GetMinimapOffset() < 0, "screen-top side mode reserves minimap space to its left")
check(t.api:GetTrackerOffset() == 0, "screen-top tracker follows moved map without duplicate offset")
local topFirst = physical(t.widgets[1].Widget)
check(topFirst.top > below, "screen-top mode starts alongside minimap")
within(t:visible(), 1920-t.api:GetSideWidth(), above, 1920, 1080, "screen-top side bounds")
t.api:SetSetting("count", 120)
check(#t:visible() == 120, "maximum requested shared count allocated")
within(t:visible(), 1920-t.api:GetSideWidth(), above, 1920, 1080, "dense side fits top-to-window bounds")

-- Effective UI/window/map scales must share one screen-space coordinate system.
for _, scale in ipairs({.75, 1.25}) do
    local scaled = boot({minimapExtraLayout = {count = 42, sideEnabled = true, sideColumns = 3, sideStart = "below"}})
    scaled.env.UIParent:SetScale(scale)
    scaled.window:SetScale(.9)
    scaled.env.Minimap:SetScale(1.1)
    scaled.api:RefreshLayout()
    local screen = physical(scaled.env.UIParent)
    local minimap = physical(scaled.env.Minimap)
    local windowTop = physical(scaled.window).top
    within(scaled:visible(), screen.right-scaled.api:GetSideWidth()*scale, windowTop, screen.right, minimap.bottom,
        "side scale conversion " .. scale)
    near(physical(scaled.widgets[1].Widget).top, minimap.bottom,
        "below-map start follows actual scaled minimap bottom")
    scaled:embed(220)
    local host, embeddedMap = physical(scaled.window), physical(scaled.env.Minimap)
    within(scaled:visible(), host.left, host.bottom, embeddedMap.left, host.top,
        "embedded independent host scale " .. scale)
end

-- A fit is maximal when a slightly larger square cannot hold the same number
-- within the rectangle. This capacity witness is independent of the chooser's
-- per-column search and checks every supported count.
local function optimal(size, count, width, height, maximum, label)
    check(size > 0 and size <= maximum + .001, label .. ": bounded positive button size")
    if size < maximum - .01 then
        local larger = size + .01
        local capacity = math.floor((width + .00001) / larger) * math.floor((height + .00001) / larger)
        check(capacity < count, label .. ": no larger square grid fits all buttons")
    end
end
for _, mode in ipairs({"embedded", "below", "top"}) do
    local auto = boot({minimapExtraLayout = {sideEnabled = true, embeddedColumns = 1,
        embeddedMapScale = 40, sideColumns = 8, sideScale = 100},
        minimapExtraButtons = {[1] = {dataType="spell", data=123},
            [120] = {dataType="macro", data=1, macroName="Saved Macro", macroBody="/say preserved"}}})
    if mode == "embedded" then auto:embed(256)
    else auto.api:SetSetting("sideStart", mode) end
    local previousSize = math.huge
    for count = 1, 120 do
        auto.api:SetSetting("count", count)
        local first = physical(auto.widgets[1].Widget)
        local unit = auto.env.UIParent:GetEffectiveScale()
        local width, height, maximum, boundaryLeft, boundaryRight, boundaryBottom, boundaryTop
        if mode == "embedded" then
            local host, map = physical(auto.window), physical(auto.env.Minimap)
            local scale = auto.window:GetEffectiveScale()
            width, height, maximum = (host.width-map.width), host.height, 45*1.13*scale
            boundaryLeft, boundaryRight, boundaryBottom, boundaryTop = host.left, map.left, host.bottom, host.top
        else
            local host, map, screen = physical(auto.window), physical(auto.env.Minimap), physical(auto.env.UIParent)
            local top = mode == "below" and map.bottom or screen.top
            width, height, maximum = 88*unit, top-host.top, 44*unit
            boundaryLeft, boundaryRight, boundaryBottom, boundaryTop = screen.right-auto.api:GetSideWidth()*unit,
                screen.right, host.top, top
        end
        if mode == "embedded" then
            optimal(first.width, count, width, height, maximum, mode .. " count " .. count)
            near(physical(auto.env.FluxMinimapButtonsContainer).right, boundaryRight, "embedded buttons touch minimap edge")
        else
            check(first.width > 0 and first.width <= maximum+.001, "side size remains bounded")
            if count*first.width >= height-.001 then
                local rows = math.floor(height/first.width+.5)
                near(rows*first.width,height,"completed side columns exactly fill available height")
                if rows>1 then
                    local larger=height/(rows-1)
                    check(larger>maximum+.001 or math.floor((width+.00001)/larger)*(rows-1)<count,
                        "no larger full-height square grid fits all buttons")
                end
                near(physical(auto.env.FluxMinimapButtonsContainer).bottom,boundaryBottom,"completed grid touches Flux Window")
            end
            near(physical(auto.env.FluxMinimapButtonsContainer).right,boundaryRight,"side grid touches screen edge")
            near(first.top,boundaryTop,"side buttons touch chosen starting edge")
        end
        check(first.width <= previousSize + .001, mode .. ": higher count cannot enlarge buttons")
        previousSize = first.width
        within(auto:visible(), boundaryLeft, boundaryBottom, boundaryRight, boundaryTop, mode .. ": automatic count bounds")
        local prior
        for _, button in ipairs(auto:visible()) do
            local current = physical(button.Widget)
            if prior then
                if mode == "embedded" then
                    check((current.left > prior.left and math.abs(current.top-prior.top)<.001)
                        or (current.left < prior.left+.001 and current.top < prior.top), "automatic embedded row-major order")
                else
                    check((math.abs(current.left-prior.left)<.001 and current.top < prior.top)
                        or (current.left < prior.left and current.top > prior.top), "automatic side completes column downward")
                end
            end
            prior=current
        end
    end
    local identities = {}; for i, b in ipairs(auto.widgets) do identities[i] = b.Widget end
    auto:combatState(true)
    local writes, size = auto.structuralWrites, physical(auto.widgets[1].Widget).width
    auto.api:SetSetting("count", 25); auto.api:SetSetting("count", 2)
    check(auto.structuralWrites == writes, "automatic geometry defers all combat writes")
    near(physical(auto.widgets[1].Widget).width, size, "combat keeps applied automatic size")
    auto:combatState(false)
    check(#auto:visible() == 2, "regen applies latest count and automatic fit")
    auto.api:SetSetting("count", 120)
    for i, identity in ipairs(identities) do check(auto.widgets[i].Widget == identity, "automatic reflow reuses slot " .. i) end
    check(auto.saved.minimapExtraButtons[120].macroBody == "/say preserved", "automatic reflow retains higher saved actions")
    for _, retired in ipairs({"embeddedColumns", "embeddedMapScale", "sideColumns"}) do
        check(auto.api:GetSetting(retired) == nil, "retired manual layout key ignored: " .. retired)
    end
    check(auto.saved.minimapExtraLayout.sideScale == 100 and auto.saved.minimapExtraLayout.embeddedColumns == 1,
        "retired saved preferences preserved without influencing automatic fit")
end

-- Whole-grid scaling is separate from the automatic choice of button grid.
-- Every scale refits to the available height; completed columns touch the
-- window while short lists retain capped standard button sizing.
for _, count in ipairs({8, 120}) do
    for _, start in ipairs({"below", "top"}) do
        local scaled = boot({minimapExtraLayout={count=count, sideEnabled=true, sideStart=start}})
        local root = scaled.env.FluxMinimapButtonsContainer
        local full = physical(root)
        local button = physical(scaled.widgets[1].Widget)
        local identities = {}; for i,b in ipairs(scaled.widgets) do identities[i]=b.Widget end
        for _, percentage in ipairs({10, 25, 50, 85, 100, 150, 200}) do
            scaled.api:SetSetting("sideScale", percentage)
            local current, screen = physical(root), physical(scaled.env.UIParent)
            local map, window = physical(scaled.env.Minimap), physical(scaled.window)
            near(root:GetScale(), percentage*.85/100, "whole side-grid frame scale")
            if percentage <= 100 and count==8 then
                near(current.width, full.width*percentage/100, "whole grid width scales proportionally")
                near(current.height, full.height*percentage/100, "whole grid height scales proportionally")
                near(physical(scaled.widgets[1].Widget).width, button.width*percentage/100, "whole grid scales button face")
            end
            near(current.right, screen.right, "scaled grid has no screen-edge margin")
            local top = start=="top" and screen.top or map.bottom
            near(current.top, top, "scaled grid has no minimap/start margin")
            within(scaled:visible(), screen.right-scaled.api:GetSideWidth(), window.top, screen.right, top,
                "scaled automatic grid stays above window and inside its reservation")
            check(current.width <= 88*percentage*.85/100+.001, "scaled grid has no container padding")
            if count*physical(scaled.widgets[1].Widget).width >= top-window.top-.001 then
                near(current.bottom,window.top,"completed scaled columns touch Flux Window")
            end
            check(#scaled:visible()==count, "scaled automatic grid retains every action")
            for i,identity in ipairs(identities) do check(scaled.widgets[i].Widget==identity, "whole-grid scaling retains action identity") end
        end
        if count==8 then check(physical(scaled.widgets[1].Widget).width > button.width, "200percent enlarges standard buttons while refitting") end
        scaled:combatState(true)
        local writes, applied = scaled.structuralWrites, root:GetScale()
        scaled.api:SetSetting("sideScale", 25); scaled.api:SetSetting("sideScale", 150)
        check(scaled.structuralWrites==writes and root:GetScale()==applied, "combat grid scaling waits without protected writes")
        scaled:combatState(false)
        near(root:GetScale(),1.275,"regen applies latest whole-grid scale")
        scaled:embed(256)
        near(root:GetScale(),1,"side grid scale does not affect embedded layout")
    end
end

-- New100 is exactly old85; reading legacy saved choices does not rewrite
-- them, and new choices are versioned so repeated refreshes cannot rescale them.
local defaultGrid = boot({minimapExtraLayout={sideEnabled=true,count=8}})
near(defaultGrid.api:GetSetting("sideScale"),100,"rebased default displays100percent")
near(defaultGrid.env.FluxMinimapButtonsContainer:GetScale(),.85,"rebased default applies old85percent")
for _, old in ipairs({25,50,85,100,150,170,200}) do
    local legacy = boot({minimapExtraLayout={sideEnabled=true,count=8,sideScale=old}})
    near(legacy.api:GetSetting("sideScale"),math.min(200,old/.85),"legacy percentage converts to new units")
    near(legacy.env.FluxMinimapButtonsContainer:GetScale(),math.min(1.7,old/100),"legacy effective scale retained within new ceiling")
    check(legacy.saved.minimapExtraLayout.sideScale==old and legacy.saved.minimapExtraLayout.sideScaleVersion==nil,
        "legacy scale read preserves original saved data")
    legacy.api:SetSetting("sideScale",100)
    check(legacy.saved.minimapExtraLayout.sideScaleVersion==2,"new scale writes mark rebased units")
    for _=1,3 do legacy.api:RequestRefresh() end
    near(legacy.api:GetSetting("sideScale"),100,"versioned scale is not converted twice")
    near(legacy.env.FluxMinimapButtonsContainer:GetScale(),.85,"explicit new100 remains old85 after repeated refresh")
end
local modern = boot({minimapExtraLayout={sideEnabled=true,count=8,sideScale=10,sideScaleVersion=2}})
near(modern.env.FluxMinimapButtonsContainer:GetScale(),.085,"new10percent reaches8.5percent of original scale")
modern.api:SetSetting("sideScale",999)
near(modern.api:GetSetting("sideScale"),200,"new upper bound remains200percent")
modern.api:SetSetting("sideScale",-1)
near(modern.api:GetSetting("sideScale"),10,"new lower bound remains10percent")

-- Protected writes fail loudly in this fixture; the secure driver alone handles
-- combat visibility, and pending settings/layout run after regen.
t.api:SetSetting("count", 15)
t.api:SetSetting("hideInCombat", true)
check(t.api:CanHideInCombat(), "supported secure engine advertises hide option")
check(next(t.drivers), "hide option installs native secure visibility state driver")
local creations, previousFirst = t.creates, t.widgets[1].Widget
t:combatState(true)
check(#t:visible() == 0, "combat completely hides clickable widgets through secure parent")
t.api:SetSetting("count", 80)
t.api:RefreshLayout()
check(t.creates == creations, "combat settings defer structural changes")
t:combatState(false)
check(#t:visible() == 80 and t.widgets[1].Widget == previousFirst, "regen applies latest settings and preserves actions")
t.api:SetSetting("hideInCombat", false)
check(not next(t.drivers), "turning combat hide off unregisters secure driver")
t:combatState(true)
check(#t:visible() == 80, "combat remains visible when hide option off")
t:combatState(false)

t:embed(220)
t.api:OnEmbedStateChanged(false)
t.mapVisible = false
t.api:RefreshLayout()
check(#t:visible() == 0, "hidden embedded map tab never exposes side layout")
t:normal()
check(#t:visible() == 80, "normal minimap restores opted-in side after embed release")
t.api:SetSetting("sideStart", "below")
t.window:ClearAllPoints(); t.window:SetPoint("TOPRIGHT", t.env.UIParent, "TOPRIGHT", -20, -10)
t.api:RefreshLayout()
check(#t:visible() == 0, "side strip has no clickable widgets when map-to-window space is exhausted")
check(t.saved.minimapExtraButtons[60].macroBody == "/say preserved", "no-space hiding retains saved assignments")
t.window:ClearAllPoints(); t.window:SetPoint("BOTTOMRIGHT", t.env.UIParent, "BOTTOMRIGHT", -20, 25)
t.api:RefreshLayout()
check(#t:visible() == 80, "making vertical room restores same side widgets")

local unavailable = boot({minimapExtraLayout = {sideEnabled = true, hideInCombat = true}}, function(model)
    model.supported = false
end)
check(not unavailable.api:CanHideInCombat() and not next(unavailable.drivers), "unavailable secure engine never pretends combat hide works")
check(#unavailable:visible() == 15, "unsupported hide retains ordinary side buttons")

local clamped = boot({minimapExtraLayout = {count = 999, embeddedColumns = -4, sideColumns = 99, sideScale = 0, sideScaleVersion = 2}})
check(clamped.api:GetSetting("count") == 120 and clamped.api:GetSetting("embeddedColumns") == nil,
    "count bounded and retired embedded setting ignored")
check(clamped.api:GetSetting("sideColumns") == nil and clamped.api:GetSetting("sideScale") == 10,
    "side columns stay automatic and whole-grid scale is bounded")

local callbacks = boot({minimapExtraLayout = {sideEnabled = true, count = 25}})
local slot = callbacks.widgets[25]
slot.OnReceiveDragCallback("item", 876)
check(callbacks.saved.minimapExtraButtons[25].data == 876, "new high-index drag assignment saved")
slot.MacroIndex, slot.MacroName, slot.MacroBody = 1, "Saved Macro", "/say preserved"
slot.OnMacroRebound()
check(callbacks.saved.minimapExtraButtons[25].data == 1
    and callbacks.saved.minimapExtraButtons[25].macroBody == "/say preserved", "high-index macro rebound retains recovery data")
callbacks.api:SetSetting("count", 2)
callbacks.api:SetSetting("count", 25)
check(callbacks.saved.minimapExtraButtons[25].macroName == "Saved Macro", "hidden macro callback assignment survives count round trip")
slot.OnDelete()
check(callbacks.saved.minimapExtraButtons[25].data == nil
    and callbacks.saved.minimapExtraButtons[25].macroBody == nil, "delete clears only selected high slot")

-- Combat hiding belongs only to the external layout; the stored preference
-- survives embedding, and returning to the side layout restores its driver.
for _, start in ipairs({"below", "top"}) do
    local scoped = boot({minimapExtraLayout={sideEnabled=true,hideInCombat=true,sideStart=start}})
    check(next(scoped.drivers)~=nil,"screen-side preference initially installs driver")
    scoped:embed(220)
    check(not next(scoped.drivers),"embedding unregisters screen-side combat driver")
    check(scoped.api:GetSetting("hideInCombat"),"embedding keeps saved combat preference")
    local first, writes = scoped.widgets[1].Widget, scoped.structuralWrites
    scoped:combatState(true)
    check(#scoped:visible()==15 and scoped.widgets[1].Widget==first,"embedded buttons remain visible during combat")
    check(scoped.structuralWrites==writes,"embedded combat entry performs no insecure visibility writes")
    scoped.api:SetSetting("hideInCombat",false);scoped.api:SetSetting("hideInCombat",true)
    check(#scoped:visible()==15 and not next(scoped.drivers),"editing visible preference in combat cannot hide embedded buttons")
    scoped:combatState(false)
    check(#scoped:visible()==15 and not next(scoped.drivers),"embedded regen keeps grid visible without combat driver")
    scoped:normal()
    check(next(scoped.drivers)~=nil and scoped.api:GetSetting("hideInCombat"),"returning to side layout restores saved hide choice")
    scoped:combatState(true)
    check(#scoped:visible()==0,"restored screen-side layout still fully hides in combat")
    scoped:combatState(false)
    scoped:embed(220);scoped:combatState(true)
    scoped.api:OnEmbedStateChanged(false)
    check(#scoped:visible()==15,"tab changes retain existing protected-layout deferral during combat")
    scoped:combatState(false)
    check(#scoped:visible()==0,"closed embedded tab hides when deferred layout safely applies")
    scoped.api:OnEmbedStateChanged(true)
    check(#scoped:visible()==15 and not next(scoped.drivers),"reopening embedded tab does not rearm combat hiding")
end

print("minimap extra layout: " .. checks .. " checks PASS (runtime geometry, saved actions, reuse, deferred combat writes and state-driver model; native acceptance pending)")
