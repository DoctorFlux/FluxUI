-- Production inventory dispatch, watches and count painters. Native count APIs
-- and widget sinks are deterministic boundaries; no WoW client is controlled.
-- Optional first argument: external source root for exact checkpoint comparison.
local selected = arg[1] or "."
local checks, failures, profiles, bursts = 0, 0, 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local function read(path)
    local f = assert(io.open(path, "rb")); local text = f:read("*a"); f:close(); return text
end
local fixture = read("tests/passive_ebs_visibility.lua")
fixture = fixture:sub(1, assert(fixture:find("\nlocal summary = {}", 1, true)) - 1)
local boot = assert(load(fixture .. "\nreturn boot", "@action-count-fixture", "t",
    setmetatable({ arg = { [0] = "tests/action_count_refresh.lua", selected } }, { __index = _G })))()
local FEATHER, ITEM, CHARGE = 17056, 5514, 999991

local function model(family, provider, usesUnavailable)
    local s = boot(family)
    local F, e = s.flux, s.env
    local ns = { Flux = F }
    function s:load(path) assert(load(read(selected .. "/" .. path), "@" .. path, "t", e))("_FluxUI", ns) end
    -- Restart the watches against a shared event owner and form-window boundary.
    -- The real Events service accepts multiple listeners and silently declines
    -- unavailable events; test that old clients do not require native USES delivery.
    s.events, s.timers, s.tokens = {}, {}, {}
    F.Events.Register = function(name, fn)
        if usesUnavailable and name == "SPELL_UPDATE_USES" then return false end
        s.events[name] = s.events[name] or {}; table.insert(s.events[name], fn); return true
    end
    F.Events.RegisterUnit = function(name, _, fn) return F.Events.Register(name, fn) end
    function s:emit(name, ...) for _, fn in ipairs(self.events[name] or {}) do fn(name, ...) end end
    local settled = {}
    F.FormStorm = { IsSettling = function() return s.formHeld == true end,
        OnBurst = function() end, OnSettled = function(key, fn) settled[key] = fn end }
    function s:settle()
        self.formHeld = false
        for _, fn in pairs(settled) do fn(true) end
    end
    F.Timer.Defer = function(fn) F.Timer.After(0, fn) end
    F.Module = { Register = function() end }; F.Safecall = function(fn, ...) return fn(...) end
    F.Combat = { InLockdown = function() return s.combat end, Defer = function() error("unexpected protected work") end }
    e.SlashCmdList = {}; e.UnitExists = function() return false end
    e.C_Timer = F.Timer
    s:load("Inventory/Init.lua")
    local inv = F.Inventory; inv.source = provider
    inv.Builtin.Bags = { GetLastChangeKind = function() return "count" end,
        GetLastAddedItemIDs = function() end, GetLastRemovedItemIDs = function() end,
        GetLastRefreshedDirtyBags = function() end,
        TakeItemSets = function() return s.changed, s.changed end }
    inv.Syndicator.GetLastBagsChangeKind = function() return "count" end
    inv.Syndicator.GetLastBagsAddedItemIDs = function() end
    inv.Syndicator.GetLastBagsRemovedItemIDs = function() end
    inv.Syndicator.GetLastBagsDirtyBags = function() end
    inv.Syndicator.TakeBagsItemSets = function() return s.changed, s.changed end
    F.Item.GetCount = function(id) return s.values[id] or 0 end
    F.Item.IsConsumable = function(id) return id == ITEM end
    local spellCount = F.Spell.GetDisplayCount
    F.Spell.GetDisplayCount = function(id)
        if s.legacy then return nil end
        s.countQueries = (s.countQueries or 0) + 1
        return spellCount(id)
    end
    F.Spell.GetCount = function(id)
        s.countQueries = (s.countQueries or 0) + 1
        return s.values[id] or 0
    end
    F.Spell.GetCharges = function(id) if id == CHARGE then return s.values[id] or 0, 2 end end
    F.Spell.IsUsable = function(id)
        return type(s.values[id]) ~= "number" or s.values[id] > 0, false
    end
    F.Secrets = { IsSecretValue = function(value) return type(value) == "table" and value.opaque == true end,
        SafeGetNumber = function(value, default) return type(value) == "number" and value or default end }
    s.legacy = family == "era" or family == "anniversary"
    -- Spell identity here represents the shown Levitate/Slow Fall spell. Native
    -- spell count follows reagent stock, independently of any action-slot API.
    s.values[FEATHER], s.values[ITEM], s.values[CHARGE] = 19, 4, 2
    s.live = s.values -- native carried-count boundary agrees with the current bag facts
    local hosts = {}
    F.Bars = { hosts = {}, NUM_COLUMNS = 3, ProgramFace = {
        Request = function() s.macroRequests = (s.macroRequests or 0) + 1 end,
        Shown = function(host) return host.kind, host.id end },
        Hosts = { LiveSlot = function(host) return host.slot end }, Strip = {}, Effects = {} }
    local B = F.Bars
    F.Action = { HasAction = function(slot) return hosts[slot] ~= nil end }
    B.ForEachHost = function(fn) for _, host in ipairs(hosts) do fn(host) end end
    B.RequestPaint = function(token) F.Scheduler.Request("eval", token) end
    B.RequestLayout = function() error("count event requested layout") end
    s:load("Bars/Paint.lua")
    -- Keep the real count lane and its dispatch; unrelated rendering lanes are
    -- covered by their existing native-boundary tests.
    for _, name in ipairs({ "UpdateName", "UpdateAssistedCombat", "UpdateAssistedHighlight",
        "UpdateUsable", "UpdateEquipped", "UpdateCooldown", "PaintAssistedHosts", "PaintAssistedHighlights" }) do
        B.Paint[name] = function() end
    end
    B.Paint.NeedsRange = function() return false end
    B.Paint.HostIsLive = function(host) return host.visible ~= false end
    function s:host(kind, id)
        local fs = { text = "", shown = true,
            Show = function(self) self.shown = true end,
            IsShown = function(self) return self.shown end,
            SetText = function(self, value) self.text = value end,
            GetText = function(self) return self.text end }
        local host = { slot = #hosts + 1, kind = kind, id = id, WCount = fs, widget = {} }
        hosts[#hosts + 1] = host; B.hosts[#hosts] = { main = host }; return host
    end
    s:load("Bars/Watch.lua"); B.Watch.Start()
    s:load("ExtraButtonSystem/Engine/Watch.lua")
    s:load("ExtraButtonSystem/Init.lua")
    -- Scheduler registration remains real at the consumers. Flush all pending
    -- lanes once, as the shared scheduler does at its next dispatch.
    local subscribers = {}
    F.Scheduler.Register = function(lane, fn) subscribers[lane] = fn end
    F.EBS.Start()
    function s:flush()
        local tokens = self.tokens; self.tokens = {}
        B.Paint.Flush(tokens)
        if subscribers.eval then subscribers.eval(tokens) end
    end
    function s:bag(tier, changed)
        self.changed = changed or { [FEATHER] = true, [ITEM] = true }
        inv.Notify({ bags = true, tier = tier or "light" })
    end
    local barSpell, barItem, barCharge = s:host("spell", FEATHER), s:host("item", ITEM), s:host("spell", CHARGE)
    local extra, badge, macro, item = s:button("spell"), s:button("spell", false, true), s:button("macrotext"), s:button("item")
    extra.SpellId, badge.SpellId = FEATHER, FEATHER
    macro.MacroMode, macro.MacroSpellId, macro.SpellId = "spell", FEATHER, FEATHER
    item.ItemId, item.ActionValue = ITEM, ITEM
    local hidden = s:button("spell", true); hidden.SpellId = FEATHER
    local charge = s:button("spell"); charge.SpellId = CHARGE
    s.faces = { barSpell, barItem, barCharge, extra, badge, macro, item, hidden, charge }
    s:bag("scan"); s:flush(); s.tokens = {}
    return s, inv, B
end

for _, family in ipairs({ "retail", "forever", "mists", "era", "anniversary" }) do
 for _, provider in ipairs({ "builtin", "syndicator" }) do
    local s, inv = model(family, provider)
    profiles = profiles + 1
    local label = family .. "/" .. provider .. " "
    local barSpell, barItem, barCharge, extra, badge, macro, item, hidden, charge = table.unpack(s.faces)
    local function spellFaces(expected, why)
        for _, pair in ipairs({ {barSpell, "bar"}, {extra, "extra"}, {badge, "badge"}, {macro, "macro"} }) do
            local value = pair[1].WCount.text
            check(tostring(value) == tostring(expected), label .. why .. " " .. pair[2] .. "=" .. tostring(expected))
        end
    end
    spellFaces(19, "initial")
    for _, acquisition in ipairs({ "loot", "vendor", "trade", "mail" }) do
        s.values[FEATHER] = 19; s:bag("scan"); s:flush()
        local macroRequests = s.macroRequests
        s.values[FEATHER], s.values[ITEM] = 20, 5
        s:bag("light"); s:flush()
        spellFaces(20, acquisition .. " light bag publication")
        check(barItem.WCount.text == "5" and item.WCount.text == "5", label .. acquisition .. " item count")
        check(s.macroRequests == macroRequests, label .. acquisition .. " no conditional parse/modifier")
    end
    -- Native spell-use data may settle after bags publish, or change without
    -- any inventory publication. Count+usability must share the next eval.
    s.values[FEATHER] = 19; s:bag(); s:flush()
    local writes = s:metric("textWrites")
    local queries = s.countQueries
    local timers = #s.timers
    s.values[FEATHER] = 20
    for _ = 1, 100 do s:emit("SPELL_UPDATE_USES") end
    check(s.tokens["bars.count"] and s.tokens["ebs.count"], label .. " uses requests both count lanes")
    check(s.tokens["bars.usable"] and s.tokens["ebs.usable"], label .. " uses requests usability")
    check(not s.tokens["bars.cooldown"] and not s.tokens["ebs.cooldown"], label .. " uses avoids cooldown work")
    s:flush(); spellFaces(20, "100 use events")
    check(s:metric("textWrites") - writes == 3, label .. " burst writes only three visible EBS spell faces")
    check(s.countQueries - queries == 6, label .. " burst reads each of six visible spell faces once")
    check(#s.timers == timers, label .. " use events add no timer")
    bursts = bursts + 1
    check(hidden.WCount.text == "", label .. " parked face performs no count paint")
    -- Charge-only signals retain their existing cooldown and count behavior.
    s.values[CHARGE] = 1; s:emit("SPELL_UPDATE_CHARGES")
    check(s.tokens["bars.cooldown"] and s.tokens["ebs.cooldown"], label .. " charge cooldown lanes retained")
    s:flush()
    check(barCharge.WCount.text == "1" and charge.WCount.text == "1", label .. " charge count 2 to 1")
    s.values[FEATHER], s.values[ITEM] = 1, 1; s:bag(); s:flush(); spellFaces(1, "one reagent")
    s.values[FEATHER], s.values[ITEM] = 0, 0; s:bag(); s:flush()
    check(barItem.WCount.text == "0" and item.WCount.text == "0", label .. " depleted items retain zero")
    spellFaces(s.legacy and "" or 0, "depleted reagent native formatting")
    s.values[FEATHER] = 19; s:bag(); s:flush()
    s.formHeld = true; s.values[FEATHER] = 20
    s:emit("SPELL_UPDATE_USES")
    check(not s.tokens["bars.count"] and not s.tokens["ebs.count"], label .. " held form defers counts")
    s:settle(); s:flush(); spellFaces(20, "quiet form settle replays uses")
    for _, count in ipairs({ 0, 1 }) do
        s.formHeld = true; s.values[FEATHER] = count
        s:emit("SPELL_UPDATE_USES"); s:settle(); s:flush()
        check(badge.WIcon.r == (count > 0 and 1 or 0.4), label .. " held badge tint reagent " .. count)
        check(extra.WIcon.r == (count > 0 and 1 or 0.4), label .. " held extra tint reagent " .. count)
    end
    local before = s:metric("spellCountQueries")
    inv.Notify({ mail = true, tier = "scan" }); s:flush()
    check(s:metric("spellCountQueries") == before and next(s.tokens) == nil, label .. " mail-only pulse has no count work")
    -- Changed-item pruning must never mistake a spell reagent for the action's
    -- item ID. Ordinary unrelated item faces keep their pruning contract.
    s.values[FEATHER] = 21; s:bag("light", { [12345] = true }); s:flush(); spellFaces(21, "spell face survives item pruning")
    if family == "retail" then
        local secret = { opaque = true }
        s.values[FEATHER] = secret; s:emit("SPELL_UPDATE_USES"); s:flush()
        check(barSpell.WCount.text == secret and extra.WCount.text == secret and badge.WCount.text == secret
            and macro.WCount.text == secret, label .. " opaque native display count writes through")
    end
    check(s.blocked == 0, label .. " count refresh attempts no protected structure")
    -- Removed/disabled EBS owners do not retain ongoing work.
    s.flux.EBS.buttons, s.flux.EBS.badges = {}, {}
    before = s:metric("spellCountQueries")
    s:emit("SPELL_UPDATE_USES")
    s.flux.EBS.Paint.FlushEval(s.tokens); s.tokens = {}
    check(s:metric("spellCountQueries") == before, label .. " empty EBS owners perform no spell queries")
 end
end
for _, family in ipairs({ "forever", "era" }) do
    local s = model(family, "builtin", true)
    s.values[FEATHER] = 20; s:bag("light"); s:flush()
    check(s.faces[1].WCount.text == "20" and s.faces[4].WCount.text == "20" and s.faces[5].WCount.text == "20",
        family .. " optional missing native USES retains bag-driven refresh")
    check(s.events.SPELL_UPDATE_USES == nil, family .. " unavailable event registration remains optional")
end
print(("Action count refresh: %d checks, %d failures; %d profiles, %d coalesced 100-event bursts"):format(checks, failures, profiles, bursts))
os.exit(failures > 0 and 1 or 0)
