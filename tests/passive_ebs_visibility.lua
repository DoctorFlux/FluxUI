-- Actual Paint / Watch / Badge functions; native API and frame sinks are fixtures.
-- Optional args: exact source root, "baseline" to record the old work budgets.
local root = arg[1] or ((arg[0]:match("^(.*)[/\\]") or ".") .. "/../")
if not root:match("[/\\]$") then root = root .. "/" end
local baseline = arg[2] == "baseline"
local checks, trace = 0, {}
local function eq(a, b, label)
    checks = checks + 1
    assert(a == b, (label or "value") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local function read(path)
    local f = assert(io.open(root .. path, "rb")); local value = f:read("*a"); f:close(); return value
end
local function compile(source, env)
    if setfenv then local f = assert(loadstring(source)); setfenv(f, env); return f end
    return assert(load(source, "EBS visibility production fixture", "t", env))
end
local paintSource, watchSource = read("ExtraButtonSystem/Engine/Paint.lua"), read("ExtraButtonSystem/Engine/Watch.lua")
local badgeSource, widgetSource = read("ExtraButtonSystem/Engine/Badge.lua"), read("ExtraButtonSystem/Engine/Widget.lua")
local showStart = assert(widgetSource:find('widget:SetScript("OnShow", function(w)', 1, true))
local showEnd = assert(widgetSource:find("\n\tend)", showStart, true)) + #"\n\tend)"
local widgetShowSource = widgetSource:sub(showStart, showEnd - 1)
local families = { "retail", "forever", "era", "anniversary", "mists" }
local function boot(family)
    local s = { now = 0, timers = {}, metrics = {}, events = {}, tokens = {}, values = {},
        icons = {}, active = true, combat = false, blocked = 0, charged = {}, live = {}, reliable = true }
    local function inc(key) s.metrics[key] = (s.metrics[key] or 0) + 1 end
    local env = setmetatable({}, { __index = _G }); env._G = env
    local Flux = { EBS = { buttons = {}, badges = {} }, Cap = {}, Client = {
        isForever = family == "forever", isMidnight = family == "retail",
        isPostDF = family == "retail" or family == "forever", isAnyClassic = family ~= "retail" and family ~= "forever",
        isEra = family == "era", isAnniversary = family == "anniversary", isMists = family == "mists" } }
    env.FluxButton = {}; env.GetTime = function() return s.now end
    env.InCombatLockdown = function() return s.combat end
    env.CreateFrame = function()
        if s.combat then s.blocked = s.blocked + 1; error("cold frame allocation in combat") end
        error("fixture requires prepared frames")
    end
    env.UnitClass = function() return "Mage", "MAGE" end
    env.UnitExists = function() return false end
    env.C_MountJournal = { GetMountInfoByID = function(id)
        inc("mountQueries"); return "mount", id, "mount-icon", s.active, true
    end }
    env.SpellIsTargeting = function() inc("targetingQueries"); return s.targeting == true end
    env.C_Item = { IsEquippedItem = function(id) inc("equipQueries"); return s.equipped == id end }
    Flux.Inventory = { GetCount = function(id) inc("bagQueries"); return s.values[id] or 5 end,
        GetLiveCount = function(id) inc("liveQueries"); return s.live[id] or 0 end,
        IsReliable = function() return s.reliable end }
    Flux.Item = { UsesConsumableCharges = function(id) inc("chargeClassifications"); return s.charged[id] == true end,
        GetSpell = function() return nil end, IsConsumable = function(id) return s.charged[id] == true end,
        GetIcon = function(id) inc("iconQueries"); return s.icons[id] or "item-icon" end,
        IsUsable = function() inc("usableQueries"); return s.usable ~= false, false end }
    Flux.Spell = { GetDisplayCount = function(id) inc("spellCountQueries"); return s.values[id] or 7 end,
        GetIcon = function() return "spell-icon" end, IsUsable = function() return true, false end }
    Flux.ButtonFX = { Overlay = {
        ApplyChecked = function(w, v) inc("checkedWrites"); w._fluxCheckedApplied, w.checked = v, v end,
        CheckedVisualOn = function(w) return w and w.checked == true end,
        IsLiveReticle = function(w) return w.reticle == true end,
        IsCheckedSuppressed = function(w) return w.suppressed == true end },
        Flash = { Set = function(w, value) inc("flashSets"); w.flashing = value end } }
    Flux.Scheduler = { Request = function(lane, token)
        inc("request:" .. lane .. ":" .. token); s.tokens[token] = true
        if s.immediateEval then
            -- Strict new synchronous-lane geometry guard ends at the scheduler
            -- boundary; the existing full cooldown painter is a separate scope.
            local observing = s.observingReveal; s.observingReveal = false
            s.paint.FlushEval({ [token] = true }); s.observingReveal = observing
        end
    end }
    Flux.Events = { Register = function(name, fn) s.events[name] = fn end,
        RegisterUnit = function(name, unit, fn) s.events[name] = fn end }
    Flux.Timer = { After = function(delay, fn)
        inc("timersQueued"); s.timers[#s.timers + 1] = { at = s.now + delay, fn = fn }
    end }
    local function region()
        local function anchor(self)
            if self.isCooldown and s.combat and s.observingReveal then
                s.blocked = s.blocked + 1; error("protected cooldown geometry during synchronous reveal")
            end
        end
        return { shown = true, text = "", alpha = 1,
            Show = function(self) self.shown = true end, Hide = function(self) self.shown = false end,
            IsShown = function(self) return self.shown end,
            SetText = function(self, value) inc("textWrites"); self.text = value end,
            GetText = function(self) return self.text end,
            SetVertexColor = function(self, r, g, b) inc("colorWrites"); self.r, self.g, self.b = r, g, b end,
            SetDesaturated = function(self, value) self.desaturated = value end,
            SetAlpha = function(self, value) self.alpha = value end,
            SetTexture = function(self, value) self.texture = value end, SetTexCoord = function() end,
            ClearAllPoints = anchor, SetPoint = anchor, SetAllPoints = anchor,
            SetDrawSwipe = function() end, SetDrawEdge = function() end, SetSwipeColor = function() end,
            EnableMouse = function() end, Clear = function() end, SetCooldown = function() end }
    end
    function s:button(kind, hidden, badge)
        local widget = { shown = true, visible = not hidden, checked = kind == "mount", scripts = {},
            _fluxCheckedApplied = kind == "mount", alpha = 1 }
        function widget:IsShown() return self.shown end
        function widget:IsVisible() return self.shown and self.visible end
        function widget:SetChecked(value) inc("checkedWrites"); self.checked = value end
        function widget:SetScript(event, fn) self.scripts[event] = fn end
        function widget:SetAlpha(value) self.alpha = value end
        function widget:Show()
            if s.combat then s.blocked = s.blocked + 1; error("protected widget Show") end
            self.shown = true
        end
        function widget:Hide()
            if s.combat then s.blocked = s.blocked + 1; error("protected widget Hide") end
            self.shown = false
        end
        local function protectedStructure()
            if s.combat then s.blocked = s.blocked + 1; error("protected widget structure") end
        end
        widget.SetFrameLevel, widget.SetParent, widget.SetScale = protectedStructure, protectedStructure, protectedStructure
        widget.SetPoint, widget.ClearAllPoints, widget.SetSize = protectedStructure, protectedStructure, protectedStructure
        widget.SetWidth, widget.SetHeight, widget.SetAttribute = protectedStructure, protectedStructure, protectedStructure
        local id = #Flux.EBS.buttons + #Flux.EBS.badges + 100
        local b = { Widget = widget, WCount = region(), WIcon = region(), WBorder = region(), WCooldown = region(),
            ActionType = kind, ActionValue = id, ItemId = kind == "item" and id or nil,
            SpellId = kind == "spell" and id or nil, MountId = kind == "mount" and id or nil,
            _lastChecked = kind == "mount" and true or nil, badgeMode = badge }
        widget.FluxButton = b
        b.WCooldown.isCooldown = true
        local list = badge and Flux.EBS.badges or Flux.EBS.buttons; list[#list + 1] = b
        compile("local EBS, widget = ...\n" .. widgetShowSource, env)(Flux.EBS, widget)
        return b
    end
    function s:advance(dt)
        local target, budget = self.now + dt, 10000
        while true do
            budget = budget - 1; assert(budget > 0, "timer budget exceeded")
            local at, index
            for i, t in ipairs(self.timers) do
                if t.at <= target and (not at or t.at < at) then at, index = t.at, i end
            end
            if not index then break end
            local t = table.remove(self.timers, index); self.now = t.at; inc("timerCallbacks"); t.fn()
        end
        self.now = target
    end
    function s:flush()
        local tokens = self.tokens; self.tokens = {}; self.paint.FlushEval(tokens)
    end
    function s:reveal(btn)
        btn.Widget.visible, btn.Widget.shown = true, true
        self.observingReveal = self.flux.Scheduler ~= nil
        assert(btn.Widget.scripts.OnShow, "actual Widget OnShow not installed")(btn.Widget)
        self.observingReveal = false
    end
    function s:showBadge(btn)
        self.observingReveal = self.flux.Scheduler ~= nil
        self.flux.EBS.Badge.ShowVisual(btn)
        self.observingReveal = false
    end
    function s:metric(key) return self.metrics[key] or 0 end
    function s:record(label, btn)
        -- Only visible presentation state: hidden caches intentionally stop changing.
        trace[#trace + 1] = table.concat({family, label, tostring(btn.WCount.text),
            tostring(btn.WIcon.texture), tostring(btn.WIcon.r), tostring(btn.WIcon.g), tostring(btn.WIcon.b),
            tostring(btn.Widget.checked), tostring(btn.WBorder.shown)}, ":")
    end
    local ns = { Flux = Flux }
    compile(paintSource, env)("_FluxUI", ns)
    compile(watchSource, env)("_FluxUI", ns)
    compile(badgeSource, env)("_FluxUI", ns)
    Flux.EBS.Watch.Start()
    s.paint, s.flux, s.env = Flux.EBS.Paint, Flux, env
    return s
end
local summary = {}
for _, family in ipairs(families) do
    local m = {}
    do
        local s = boot(family)
        for _ = 1, 40 do s:button("mount", true) end
        s.paint.ArmCheckedPoll(); s:advance(60)
        m.hiddenCheckedCallbacks, m.hiddenMountQueries = s:metric("timerCallbacks"), s:metric("mountQueries")
        eq(m.hiddenCheckedCallbacks, baseline and 120 or 0, "parked checked timer work budget")
        eq(m.hiddenMountQueries, baseline and 4800 or 0, "parked checked native query budget")
    end
    do
        local s = boot(family); local b = s:button("mount", false)
        s.paint.ArmCheckedPoll(); s:advance(0.499)
        eq(s:metric("mountQueries"), 0, "visible poll not early")
        s:advance(0.001); eq(s:metric("mountQueries"), 1, "visible exact .5 poll")
        eq(b.Widget.checked, true, "summoned remains checked")
        s:record("summoned", b)
        b.Widget.visible = false; b.Widget.flashing = true
        s:advance(0.5)
        eq(b.Widget.flashing, false, "parked terminal tick clears flash")
        eq(#s.timers, baseline and 1 or 0, "parked terminal tick stops watch")
        s.active, s.combat = false, true
        s:reveal(b); eq(s.tokens.ebs, true, "combat parent reveal requests full eval")
        s:flush(); eq(b.Widget.checked, false, "revealed dismissed summon immediately clears")
        eq(b._lastChecked, false, "revealed checked identity refreshed")
        eq(s.blocked, 0, "reveal adds no protected widget visibility attempts")
        s:record("dismissed-reveal", b)
    end
    do
        local s = boot(family); local b = s:button("mount", false)
        s.paint.RequestCheckedSettle(); s.paint.RequestCheckedSettle(); s:flush()
        eq(s:metric("timersQueued"), 2, "one settle plus one existing poll")
        s:advance(0.299); eq(s:metric("timerCallbacks"), 0, "settle not early")
        s:advance(0.001); eq(s:metric("timerCallbacks"), 1, "settle exact .3 deadline")
        s:flush(); s:advance(0.2)
        eq(s:metric("timerCallbacks"), 2, "poll keeps original .5 deadline")
        s.flux.EBS.buttons = {}; s:advance(1)
        eq(#s.timers, 0, "removed owners disarm pending poll")
        eq(s.paint.FlushCounts({ regions = { bags = true } }), false, "empty/disabled owners do no count work")
    end
    do
        local s = boot(family); local b = s:button("mount", false)
        s.active, b._lastChecked, b.Widget.checked = false, false, true
        s.paint.ArmCheckedPoll(); s:advance(0.5)
        eq(b.Widget.checked, false, "visible stuck checked visual still polled off")
        eq(#s.timers, 0, "stuck checked visual watch stops after repair")
        s.active, s.targeting, b.Widget.reticle = true, true, true
        s.paint.FlushChecked(); s.paint.ArmCheckedPoll()
        eq(b.Widget.checked, false, "visible reticle suppresses simultaneous checked art")
        eq(#s.timers, 0, "suppressed checked art does not create dismiss watch")
        s:record("reticle", b)
    end
    do
        local s = boot(family)
        for _ = 1, 40 do s:button("item", true) end
        for _ = 1, 8 do s:button("item", true, true) end
        for _ = 1, 4 do s:button("item", false) end
        for _ = 1, 2 do s:button("spell", false) end
        for n = 1, 1000 do
            for i = 100, 153 do s.values[i] = n % 2 + 5 end
            s.paint.FlushCounts({ regions = { bags = true, equipped = true } })
        end
        m.bagQueries, m.usableQueries, m.equipQueries, m.spellCountQueries =
            s:metric("bagQueries"), s:metric("usableQueries"), s:metric("equipQueries"), s:metric("spellCountQueries")
        eq(m.bagQueries, baseline and 52000 or 4000, "inventory visible item read budget")
        eq(m.usableQueries, baseline and 52000 or 4000, "inventory visible usability budget")
        eq(m.equipQueries, baseline and 96000 or 8000, "inventory visible equip read budget")
        eq(m.spellCountQueries, 2000, "visible spell reagent count cadence retained")
        for _, b in ipairs(s.flux.EBS.buttons) do if b.Widget.visible then s:record("count-burst", b) end end
    end
    do
        local s = boot(family); local b = s:button("item", false)
        s.paint.FlushEval({ ebs = true }); s:record("initial-item", b)
        b.Widget.visible = false
        b.IsConsumableButton = true
        s.values[b.ItemId], s.icons[b.ItemId], s.usable, s.equipped = 19, "new-hidden-icon", false, b.ItemId
        s.events.GET_ITEM_INFO_RECEIVED("GET_ITEM_INFO_RECEIVED", b.ItemId, true)
        s.paint.FlushCounts({ regions = { bags = true, equipped = true }, recovery = true })
        s:flush(); s.combat = true; s:reveal(b)
        eq(b._lastIcon, nil, "show clears stale icon cache before eval")
        eq(b.WCount.text, "19", "first visible count current BEFORE queued eval")
        eq(b.WBorder.shown, true, "first visible equipped art current BEFORE queued eval")
        eq(b.WIcon.r, 0.4, "first visible consumable tint current BEFORE queued eval")
        eq(s.blocked, 0, "synchronous count lane adds no protected structure attempts")
        s:record("first-visible-count", b)
        s:flush()
        eq(b.WCount.text, "19", "hidden provider replacement visible on reveal")
        eq(b.WIcon.texture, "new-hidden-icon", "metadata arriving hidden visible on reveal")
        eq(b.WBorder.shown, true, "hidden equipped change visible on reveal")
        eq(s.blocked, 0, "combat reveal no protected widget visibility")
        s:record("changed-item-reveal", b)
        -- Recycle the same hidden widget to another action before its native reveal.
        b.Widget.visible = false; b.ActionValue, b.ItemId = 800, 800
        s.values[800], s.icons[800] = 3, "recycled-icon"; s.usable = true
        s.paint.FlushCounts({ regions = { bags = true }, changedItemIDs = { [800] = true } })
        s:reveal(b); s:flush()
        eq(b.WCount.text, "3", "recycled hidden face count uses latest item")
        eq(b.WIcon.texture, "recycled-icon", "recycled hidden face icon uses latest item")
        s:record("recycled-reveal", b)
    end
    do
        local s = boot(family); local old = s:button("item", true)
        local latest = s:button("item", true)
        latest.Widget = old.Widget; latest.Widget.FluxButton = latest
        s.flux.EBS.buttons = { latest }
        latest.ActionValue, latest.ItemId = 901, 901
        s.values[901], s.icons[901], s.immediateEval, s.combat = 11, "rebound-widget-icon", true, true
        s:reveal(latest)
        eq(latest.WCount.text, "11", "reentrant reveal paints latest widget owner")
        eq(latest.WIcon.texture, "rebound-widget-icon", "reentrant reveal latest icon")
        eq(old.WCount.text, "", "retired widget identity is not repainted")
        eq(s.blocked, 0, "reentrant combat reveal adds no protected visibility")
        s:record("reentrant-rebound-widget", latest)
        old.WCount.text, s.immediateEval = "retired", false
        s.paint.RequestShown(old)
        eq(old.WCount.text, "retired", "explicit stale owner cannot synchronously repaint recycled widget")
        s:flush(); eq(latest.WCount.text, "11", "queued full eval still paints latest owner")
    end
    do
        local s = boot(family); local b = s:button("item", false, true)
        s.combat = true
        s.flux.EBS.Badge.HideVisual(b)
        eq(s.paint.IsParked(b), true, "alpha parked badge recognized")
        s.values[b.ItemId], s.icons[b.ItemId] = 27, "badge-new-icon"
        s.paint.FlushCounts({ regions = { bags = true }, recovery = true })
        s:showBadge(b)
        eq(s.tokens.ebs, true, "actual Badge.ShowVisual wakes full eval in combat")
        eq(b.WCount.text, "27", "badge count current BEFORE queued eval")
        eq(s.blocked, 0, "synchronous badge reveal adds no protected structure attempts")
        s:flush()
        eq(b.WCount.text, "27", "badge reveal current provider count")
        eq(b.WIcon.texture, "badge-new-icon", "badge reveal current metadata")
        eq(b.Widget.alpha, s.flux.EBS.Badge.DEFAULT_ALPHA, "badge appearance alpha retained")
        eq(s.blocked, 0, "badge reveal no protected widget visibility")
        s:record("badge-reveal", b)
    end
    do
        local s = boot(family); local b = s:button("item", true, true)
        s.combat = true; s.flux.EBS.Badge.HideVisual(b)
        s:showBadge(b)
        eq(s:metric("bagQueries"), 0, "explicit badge reveal under hidden parent keeps count parked")
        eq(s.tokens.ebs, true, "hidden-parent explicit reveal retains future eval request")
        eq(s.blocked, 0, "hidden-parent badge reveal no protected structure")
        s:reveal(b)
        if not baseline then eq(b.WCount.text, "5", "native parent reveal synchronously restores previously parked count") end
        s:flush(); eq(b.WCount.text, "5", "parent reveal full eval current count")
        s:record("hidden-parent-badge-show", b)
    end
    do
        local s = boot(family); local b = s:button("item", true)
        s.flux.Scheduler = nil; s.combat = true
        s.values[b.ItemId], s.icons[b.ItemId] = 33, "fallback-icon"
        s:reveal(b)
        eq(b.WCount.text, "33", "missing scheduler retains immediate full count paint")
        eq(b.WIcon.texture, "fallback-icon", "missing scheduler retains immediate full icon paint")
        eq(s.blocked, 0, "missing scheduler fallback no protected widget structure")
        s:record("no-scheduler-reveal", b)
    end
    do
        local s = boot(family); local b = s:button("item", true)
        for n = 1, 1000 do s.events.GET_ITEM_INFO_RECEIVED("GET_ITEM_INFO_RECEIVED", n, true) end
        m.hiddenIconRequests = s:metric("request:eval:ebs.icon")
        eq(m.hiddenIconRequests, baseline and 1000 or 0, "parked-only icon event budget")
        s:reveal(b); s:flush(); eq(b.WIcon.texture, "item-icon", "hidden pending face wakes on show")
        b._lastIcon = 134400
        local prior = s:metric("request:eval:ebs.icon")
        for n = 1, 1000 do s.events.GET_ITEM_INFO_RECEIVED("GET_ITEM_INFO_RECEIVED", n, true) end
        m.visibleIconRequests = s:metric("request:eval:ebs.icon") - prior
        eq(m.visibleIconRequests, 1000, "visible unresolved face retains every metadata request")
        s:flush(); s:record("pending-reveal", b)
        b.ActionType, b.ActionValue, b._lastIcon = "macrotext", "body", nil
        eq(s.paint.HasPendingIcon(), false, "macrotext remains excluded")
        b.ActionType, b.ActionValue = "item", 100
        b.Widget.IsVisible = nil
        eq(s.paint.HasPendingIcon(), true, "missing IsVisible preserves IsShown fallback")
        b.Widget.shown = false
        eq(s.paint.HasPendingIcon(), baseline, "own-hidden fallback obeys parked policy")
    end
    do
        local s = boot(family); local b = s:button("item", false)
        s.paint.FlushCounts({ regions = { bags = true } })
        local before = s:metric("bagQueries")
        s.paint.FlushCounts({ regions = { bags = true }, changedItemIDs = { [999] = true } })
        eq(s:metric("bagQueries"), before, "unrelated dirty IDs still filtered")
        s.charged[b.ItemId], s.live[b.ItemId] = true, 8
        s.paint.FlushCounts({ regions = { bags = true }, changedItemIDs = { [999] = true } })
        eq(b.WCount.text, "8", "charged item reads uses despite unrelated dirty ID")
        s.values[b.ItemId], s.live[b.ItemId] = 0, 0; b.IsHealthstoneButton = true
        s.paint.FlushCounts({ regions = { bags = true }, recovery = true })
        eq(b.WCount.text, "0", "visible zero/recovery count retained")
        eq(b._lastUsable, false, "zero charged recovery remains unusable")
        s:record("zero-recovery", b)
    end
    summary[family] = m
end
local hash = 0
for _, value in ipairs(trace) do for i = 1, #value do hash = (hash * 31 + value:byte(i)) % 2147483647 end end
if arg[3] then
    local out = assert(io.open(arg[3], "wb")); out:write(table.concat(trace, "\n"), "\n"); out:close()
end
local function json(value)
    if type(value) ~= "table" then
        if type(value) == "string" then return string.format("%q", value) end
        return tostring(value)
    end
    local keys, out = {}, {}; for k in pairs(value) do keys[#keys + 1] = k end; table.sort(keys)
    for _, key in ipairs(keys) do out[#out + 1] = string.format("%q", key) .. ":" .. json(value[key]) end
    return "{" .. table.concat(out, ",") .. "}"
end
print(json({ checks = checks, mode = baseline and "baseline" or "candidate", metrics = summary,
    visibleTraceHash = hash, visibleTraceSamples = #trace }))
