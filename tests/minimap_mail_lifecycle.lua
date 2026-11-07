-- Actual PositionIndicators, with native frames/events explicitly mocked.
-- lua tests/minimap_mail_lifecycle.lua [alternate FluxMinimap.lua] [--measure]
-- This establishes Lua ownership and geometry contracts, not native rendering,
-- secure behavior, FPS, or transaction latency.
local path = arg[1] or "Minimap/FluxMinimap.lua"
local measure = arg[2] == "--measure"
local file = assert(io.open(path, "r")); local source = file:read("*a"); file:close()
local block = assert(source:match("(function FluxMinimap:PositionIndicators%(%)%s.-)\n%-%-%- Hide classic/legacy LFG"))
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; if not measure then print("FAIL " .. label) end end
end
local function boot(shape, provider, tracking, calendar)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local h = { frames = 0, textures = 0, registrations = 0, hooks = 0,
        calls = 0, deliveries = 0, newMail = true, events = {}, tooltipCalls = 0,
        tooltipOwners = 0, tooltipHides = 0, combat = false, all = {}, cap = 32768 }
    local noop = function() end
    local function widget(name, parent)
        local w = { name = name, parent = parent, scripts = {}, hooks = {},
            registered = {}, shown = true }
        h.all[#h.all + 1] = w
        function w:SetScript(k, v) self.scripts[k] = v end
        function w:GetScript(k) return self.scripts[k] end
        function w:HookScript(k, v)
            h.hooks = h.hooks + 1; self.hooks[k] = self.hooks[k] or {}
            self.hooks[k][#self.hooks[k] + 1] = v
        end
        function w:RegisterEvent(k)
            if self.registered[k] then return end
            self.registered[k] = true
            local list = h.events[k] or {}; h.events[k] = list
            h.registrations = h.registrations + 1; list[#list + 1] = self
        end
        function w:UnregisterEvent(k)
            if not self.registered[k] then return end
            self.registered[k] = nil
            for i, entry in ipairs(h.events[k] or {}) do
                if entry == self then table.remove(h.events[k], i); break end
            end
        end
        function w:IsShown() return self.shown end
        function w:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function w:Fire(k)
            if self.scripts[k] then self.scripts[k](self) end
            for _, cb in ipairs(self.hooks[k] or {}) do cb(self) end
        end
        function w:Show()
            local visible = self:IsVisible(); self.shown = true
            if not visible and self:IsVisible() then self:Fire("OnShow") end
        end
        function w:Hide()
            local visible = self:IsVisible(); self.shown = false
            if visible then self:Fire("OnHide") end
        end
        function w:SetParent(p) self.parent = p end
        function w:GetParent() return self.parent end
        function w:SetPoint(...) self.point = { ... } end
        function w:ClearAllPoints() self.point = nil end
        function w:SetSize(a, b) self.width, self.height = a, b end
        function w:GetFrameLevel() return self.level or 1 end
        function w:SetFrameLevel(n) self.level = n end
        function w:CreateTexture()
            h.textures = h.textures + 1
            local t = { shown = true }
            function t:SetAtlas(a) self.atlas = a end
            function t:SetAllPoints() self.allPoints = true end
            function t:Show() self.shown = true end
            function t:Hide() self.shown = false end
            return t
        end
        w.EnableMouse, w.SetBorderHidden = noop, noop
        return w
    end
    e.UIParent = widget("UIParent")
    e.InCombatLockdown = function() return h.combat end
    e.HasNewMail = function() return h.newMail end
    e.FLUX_API = { isClassicEra = false, isForever = true, isCamelot = true }
    e.FluxBorder = { CanUseAtlases = function() return true end }
    -- Presence-only fixtures: no provider API is invoked by this controller.
    e.Syndicator = provider and { API = {} } or nil
    e.Baganator = provider and {} or nil
    e.GameTooltip = { SetOwner = function(_, owner, anchor)
        h.tooltipOwners = h.tooltipOwners + 1; h.tooltipOwner, h.tooltipAnchor = owner, anchor
    end }
    e.GameTooltip_Hide = function() h.tooltipHides = h.tooltipHides + 1 end
    e.MinimapMailFrameUpdate = function() h.tooltipCalls = h.tooltipCalls + 1 end
    e.CreateFrame = function(_, name, parent)
        if h.frames >= h.cap then error("AUDIT_FRAME_CAP", 0) end
        h.frames = h.frames + 1
        local w = widget(name, parent); if name then e[name] = w end
        return w
    end
    e.Minimap = widget("Minimap", e.UIParent)
    -- The unrelated difficulty/queue paths stay available and perform no work
    -- in this mail-focused replay. Native Minimap.Layout is not assumed.
    e.Minimap.InstanceDifficulty = { ClearAllPoints = noop, SetPoint = noop,
        SetFrameLevel = noop, Update = noop, Show = noop }
    local cluster = widget("MinimapCluster", e.UIParent)
    cluster.Tracking = tracking ~= false and widget("Tracking", e.Minimap) or nil
    cluster.IndicatorFrame = widget("IndicatorFrame", cluster)
    local native = widget("NativeMail", cluster.IndicatorFrame)
    native.width, native.height = 32, 24
    native.MailIcon = { Show = noop, atlas = "ui-hud-minimap-mail-icon" }
    local nativeHide = function() h.nativeHides = (h.nativeHides or 0) + 1 end
    native:SetScript("OnHide", nativeHide)
    cluster.IndicatorFrame.MailFrame = shape ~= "missing" and native or nil
    e.NativeMail = native
    e.MinimapCluster = cluster
    if shape == "global" then e.MiniMapMailFrame = native
    elseif shape == "minimap" then e.Minimap.MailFrame = native
    elseif shape == "both" then
        e.MiniMapMailFrame = native
        e.Minimap.MailFrame = widget("OtherNative", e.Minimap)
    end
    e.FluxMinimap = { PositionQueueStatusEye = noop }
    e.ToggleCalendar = nil
    if calendar then
        e.GameTimeFrame = widget("GameTimeFrame", cluster)
        e.GameTimeFrame:SetSize(23, 23)
        e.GameTimeFrame.StateTexture = { atlas = "ui-hud-minimap-calendar-button" }
        e.GameTimeFrame.enabled = false -- Native rule/kiosk disable must survive.
        for _, script in ipairs({ "OnClick", "OnEnter", "OnLeave", "OnEvent", "OnUpdate", "OnShow" }) do
            e.GameTimeFrame:SetScript(script, function() h[script] = (h[script] or 0) + 1 end)
        end
        if calendar == "available" then
            e.ToggleCalendar = function() h.calendarToggles = (h.calendarToggles or 0) + 1 end
            e.GameTimeFrame:SetScript("OnClick", e.ToggleCalendar)
        end
    end
    e.FluxMinimapHiddenFrame = widget("Hidden", e.UIParent)
    e.FluxMinimapHiddenFrame:Hide()
    local cleanup = assert(source:match("(function FluxMinimap:CleanupBlizzardFrames%(%)%s.-)\nfunction FluxMinimap:CleanupTimeManager"))
    local text = "local embeddedState = { isEmbedded = false }\n" .. cleanup .. "\n" .. block
    local chunk
    if loadstring then chunk = assert(loadstring(text)); setfenv(chunk, e)
    else chunk = assert(load(text, "@actual PositionIndicators", "t", e)) end
    chunk()
    local actual = e.FluxMinimap.PositionIndicators
    e.FluxMinimap.PositionIndicators = function(self) h.calls = h.calls + 1; return actual(self) end
    function h:position() e.FluxMinimap:PositionIndicators() end
    function h:mailFrame() return e.MiniMapMailFrame or e.Minimap.MailFrame
        or e.MinimapCluster.IndicatorFrame.MailFrame or e.FluxMinimapMailFrame end
    function h:event(name)
        -- Conservative snapshot: a new registration receives the next event.
        -- Native same-dispatch registration semantics are not assumed.
        local list = {}; for i, w in ipairs(self.events[name] or {}) do list[i] = w end
        for _, w in ipairs(list) do
            self.deliveries = self.deliveries + 1; w.scripts.OnEvent(w, name)
        end
    end
    return h, e, native, nativeHide
end

for _, provider in ipairs({ false, true }) do
    for _, shape in ipairs({ "cluster", "global", "minimap", "missing" }) do
        for _, n in ipairs({ 10, 100, 500 }) do
            for _, kind in ipairs({ "layout", "unchanged", "toggle" }) do
                local h = boot(shape, provider)
                local completed = 0
                local ok, err = pcall(function()
                    if kind ~= "layout" then h:position() end
                    for i = 1, n do
                        if kind == "layout" then h:position()
                        else
                            if kind == "toggle" then h.newMail = not h.newMail end
                            h:event("UPDATE_PENDING_MAIL")
                        end
                        completed = i
                    end
                end)
                local label = string.format("provider=%s shape=%s %s n=%d", tostring(provider), shape, kind, n)
                check(ok and completed == n, label .. " completes")
                check(h.frames == (shape == "missing" and 1 or 0), label .. " one owned fallback at most")
                check(h.textures == h.frames, label .. " texture lifetime matches fallback")
                check(h.registrations == 2 and h.hooks == 2, label .. " registrations and hooks remain bounded")
                check(#(h.events.UPDATE_PENDING_MAIL or {}) == 1, label .. " one mail listener")
                check(#(h.events.PLAYER_ENTERING_WORLD or {}) == 1, label .. " one world listener")
                check(h.tooltipCalls == 0, label .. " mail states do not scan tooltip senders")
                local expectedCalls = kind == "layout" and n or (kind == "toggle" and 1 + 2 * n or 1 + n)
                check(h.calls == expectedCalls, label .. " existing layout cadence")
                if ok then check(h:mailFrame().shown == h.newMail, label .. " current visibility") end
                print(string.format("CURVE %s completed=%d status=%s frames=%d textures=%d registrations=%d hooks=%d calls=%d deliveries=%d listeners=%d",
                    label, completed, ok and "complete" or tostring(err), h.frames, h.textures,
                    h.registrations, h.hooks, h.calls, h.deliveries, #(h.events.UPDATE_PENDING_MAIL or {})))
            end
        end
    end
end

local h, e, native = boot("missing", false)
h:position(); local mail = h:mailFrame()
check(mail ~= native and mail.width == 20 and mail.height == 15, "clients without a native indicator keep the fallback size")
check(mail.MailIcon.atlas == "ui-hud-minimap-mail-up" and mail.MailIcon.allPoints, "fallback artwork is unchanged")
check(mail.parent == e.Minimap and mail.point[1] == "RIGHT" and mail.point[2] == e.MinimapCluster.Tracking
    and mail.point[3] == "LEFT" and mail.point[4] == -2 and mail.point[5] == 0, "tracking-relative geometry is unchanged")
check(mail.level == e.Minimap:GetFrameLevel() + 10, "mail level is unchanged")
mail.scripts.OnEnter(mail); mail.scripts.OnLeave(mail)
check(h.tooltipCalls == 1 and h.tooltipOwners == 1 and h.tooltipOwner == mail
    and h.tooltipAnchor == "ANCHOR_BOTTOMLEFT" and h.tooltipHides == 1, "hover tooltip and leave remain functional")
local oldCalls = h.calls; h.newMail = false; h:event("PLAYER_ENTERING_WORLD")
check(not mail.shown and h.calls == oldCalls + 2 and h.frames == 1, "world event updates mail and retains transition cadence")
local oldFrame = mail
for _ = 1, 500 do h:position() end
check(h:mailFrame() == oldFrame and h.frames == 1 and h.hooks == 2, "identity survives repeated embedding/layout reconciliation")
e.Minimap:Hide(); h.newMail = true; h:event("UPDATE_PENDING_MAIL")
check(not e.Minimap:IsShown() and not mail:IsVisible() and h.frames == 1, "mail update does not reveal a hidden minimap")
h.combat = true; local calls = h.calls; h:position()
check(h.calls == calls + 1 and h.frames == 1 and not e.Minimap:IsShown(), "combat positioning is still skipped")
h.newMail = false; h:event("UPDATE_PENDING_MAIL")
check(not mail:IsShown() and h.frames == 1, "mail visibility still responds during combat")
h.combat = false; e.Minimap:Show(); h:position()
check(h.frames == 1 and h:mailFrame() == oldFrame, "combat recovery retains the same mail frame")

local cold, ce = boot("missing", false)
cold.newMail, cold.combat = false, true; cold:position()
check(cold.frames == 0 and cold.registrations == 0, "cold combat entry creates no indicator")
cold.combat = false; cold:position()
check(cold.frames == 1 and not cold:mailFrame():IsShown(), "cold no-mail initialization stays hidden")
local fallback = cold:mailFrame()
ce.MiniMapMailFrame = ce.NativeMail; cold:position()
check(cold:mailFrame() == ce.MiniMapMailFrame and fallback ~= ce.MiniMapMailFrame
    and cold.frames == 1 and ce.MiniMapMailFrame.fluxMailRegistered,
    "late native global retains existing preference")
check(not fallback:IsShown() and not fallback:GetScript("OnEvent")
    and not fallback.fluxMailRegistered and #(cold.events.UPDATE_PENDING_MAIL or {}) == 1,
    "late native handoff retires the fallback and its listeners")

local legacy, le, ln, nativeHide = boot("both", false)
legacy:position()
check(legacy:mailFrame() == ln and not le.Minimap.MailFrame.fluxMailRegistered,
    "native global remains preferred over Minimap.MailFrame")
check(ln.width == 32 and ln.height == 24 and ln:GetScript("OnHide") == nativeHide,
    "existing native dimensions and hide script remain owned by native code")
legacy.newMail = false; legacy:event("UPDATE_PENDING_MAIL")
check(legacy.nativeHides == 1 and legacy.frames == 0, "native hide still runs once")
local noTrack, ne = boot("cluster", false, false); noTrack:position(); local nt = noTrack:mailFrame()
check(nt.point[1] == "BOTTOMRIGHT" and nt.point[2] == ne.Minimap and nt.point[3] == "BOTTOMRIGHT"
    and nt.point[4] == 0 and nt.point[5] == 0, "no-tracking fallback geometry is unchanged")
-- Native Forever art is reused without creating or resizing its controls.
for _, shape in ipairs({ "cluster", "global", "minimap" }) do
    local nh, env, nm, hide = boot(shape, false, true, "available")
    local cal = env.GameTimeFrame
    local scripts = {}; for k, v in pairs(cal.scripts) do scripts[k] = v end
    env.MinimapCluster:Hide()
    env.FluxMinimap:CleanupBlizzardFrames()
    nh:position()
    check(nh:mailFrame() == nm and nh.frames == 0 and nh.textures == 0,
        shape .. " reuses native mail without a fallback")
    check(nm.width == 32 and nm.height == 24 and nm.MailIcon.atlas == "ui-hud-minimap-mail-icon"
        and nm:GetScript("OnHide") == hide, shape .. " retains native mail art/size/hide owner")
    check(cal.parent == env.Minimap and cal:IsVisible() and not cal.fluxHooked,
        shape .. " calendar survives cleanup and hidden cluster")
    check(cal.point[1] == "TOPLEFT" and cal.point[2] == env.Minimap and cal.point[3] == "TOPLEFT"
        and cal.point[4] == 4 and cal.point[5] == -4, shape .. " calendar has its own corner")
    check(cal.width == 23 and cal.height == 23 and cal.StateTexture.atlas == "ui-hud-minimap-calendar-button"
        and not cal.enabled, shape .. " native calendar artwork/size/disable state retained")
    cal.scripts.OnClick(cal)
    check(nh.calendarToggles == 1, shape .. " native click reaches calendar bootstrap")
    for _ = 1, 100 do env.FluxMinimap:CleanupBlizzardFrames(); nh:position() end
    for k, v in pairs(scripts) do check(cal.scripts[k] == v, shape .. " preserves " .. k) end
    check(nh.frames == 0 and nh.registrations == 2 and nh.hooks == 2,
        shape .. " repeated calendar layout adds no resources")
    env.Minimap:Hide(); nh:event("UPDATE_PENDING_MAIL")
    check(not cal:IsVisible() and not nm:IsVisible(), shape .. " indicators follow hidden embedded map")
    env.Minimap:Show(); nh.combat = true
    cal.point = nil; nh:position()
    check(cal.point == nil, shape .. " calendar geometry defers in combat")
    nh.combat = false; nh:position()
    check(cal.point and cal:IsVisible(), shape .. " calendar geometry recovers after combat")
end
local unsupported, ue = boot("missing", false, false, "clock")
ue.FluxMinimap:CleanupBlizzardFrames(); unsupported:position()
check(not ue.GameTimeFrame:IsVisible() and ue.GameTimeFrame.parent == ue.FluxMinimapHiddenFrame,
    "clock-only client keeps its existing cleanup without a calendar substitute")
local late, lateEnv = boot("missing", false)
late:position(); local retired = late:mailFrame()
lateEnv.MinimapCluster.IndicatorFrame.MailFrame = lateEnv.NativeMail
late:position(); late.newMail = false; late:event("UPDATE_PENDING_MAIL")
check(late:mailFrame() == lateEnv.NativeMail and not retired:IsShown()
    and #(late.events.UPDATE_PENDING_MAIL or {}) == 1 and not lateEnv.NativeMail:IsShown(),
    "late cluster native mail becomes the sole active indicator")
print(string.format("minimap mail lifecycle: %d checks, %d failures; desktop production-function replay only", checks, failures))
if not measure then assert(failures == 0, "minimap mail lifecycle regressions") end
