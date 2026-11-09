-- Production native utility attributes, saved-ID face selection and painter; frames are models.
local source = arg[1] or "ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua"
local paintSource = arg[3] or "ExtraButtonSystem/Engine/Paint.lua"
local checks, failures = 0, 0
local workTotals = { transitions = 0, icon = 0, count = 0, usable = 0, checked = 0, duplicate = 0, aura = 0 }
local measure = arg[2] == "--measure"
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local chords = { "", "SHIFT", "CTRL", "ALT", "SHIFT-CTRL", "SHIFT-ALT", "CTRL-ALT", "SHIFT-CTRL-ALT" }
local prefixes = { "", "shift-", "ctrl-", "alt-", "ctrl-shift-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }
do
    local f = assert(io.open("Core/API/Spell.lua", "rb")); local body = f:read("*a"); f:close()
    local first = assert(body:find("function Spell.GetCount", 1, true))
    local last = assert(body:find("function Spell.GetCharges", first, true))
    local api = {}; local provider = { GetSpellReagentCount = function(_, id) return id == 101 and 19 or nil end }
    local env = setmetatable({ LibStub = function() return provider end }, { __index = _G })
    assert(load("local Spell, Flux = ...\n" .. body:sub(first, last - 1), "@shared-spell-count", "t", env))(api, {})
    check(api.GetCount(101) == 19, "optional Classic reagent provider preserved")
    check(api.GetCount(999) == 0, "unknown Classic reagent count remains zero")
    env.GetSpellCount = function() return 6 end
    check(api.GetCount(101) == 6, "native legacy count takes precedence over provider")
    env.C_Spell = { GetSpellCastCount = function() return 4 end }
    check(api.GetCount(101) == 4, "modern native count takes precedence over provider")
end
for _, family in ipairs({ "retail", "forever", "era", "anniversary", "mists" }) do
    local s = { mod = "", combat = false, timers = {}, frames = {}, copies = 8, uses = 3, reagent = 12, charges = 2, writes = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local function held(key) return ("-" .. s.mod .. "-"):find("-" .. key .. "-", 1, true) ~= nil end
    env.IsShiftKeyDown = function() return held("SHIFT") end
    env.IsControlKeyDown = function() return held("CTRL") end
    env.IsAltKeyDown = function() return held("ALT") end
    env.InCombatLockdown = function() return s.combat end
    env.GetTime = function() return 100 end
    env.GetBindingKey = function() end
    env.UnitClass = function() return "Mage", "MAGE" end
    env.UnitExists = function(unit) return unit == "target" end
    env.GameTooltip = { GetOwner = function() return true end, Show = function() end,
        SetSpellByID = function(_, id) s.tipKind, s.tipID = "spell", id end,
        SetItemByID = function(_, id) s.tipKind, s.tipID = "item", id end }
    env.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    env.CreateFrame = function()
        local f = { events = {}, scripts = {} }
        function f:RegisterEvent(e) self.events[e] = true end
        function f:RegisterUnitEvent(e) self.events[e] = true end
        function f:SetScript(e, fn) self.scripts[e] = fn end
        s.frames[#s.frames + 1] = f; return f
    end
    -- Native conditional parser model. Expected selections below come from an
    -- independent eight-chord table, not from the generated clauses.
    env.SecureCmdOptionParse = function(options)
        for fragment in (options .. ";"):gmatch("(.-);") do
            local token = fragment:gsub("%b[]", ""):match("^%s*(.-)%s*$")
            local any, matched = false, false
            for cond in fragment:gmatch("%[(.-)%]") do
                any = true
                local ok = true
                for term in cond:gmatch("[^,]+") do
                    local yes = term:match("^mod:(.+)$")
                    local no = term:match("^nomod:(.+)$")
                    if yes and not held(yes:upper()) then ok = false end
                    if no and held(no:upper()) then ok = false end
                    if term == "exists" then ok = false end -- no mouseover
                end
                matched = matched or ok
            end
            if token ~= "" and (not any or matched) then return token, "target" end
        end
    end
    local modifier, inventory
    env.FluxInv = { RegisterListener = function(_, fn) inventory = fn end }
    local flux = { EBS = { buttons = {} }, Client = { isForever = family == "forever" },
        Combat = { InLockdown = function() return s.combat end } }
    env.Flux = flux; env.FluxButton = {}
    flux.Spell = {
        FormatCastAttribute = function(id) return "Spell" .. id end,
        GetOverrideSpell = function(id) return id end,
        GetTexture = function(id) return 1000 + tonumber(id) end,
        GetInfo = function(id) return { name = "Spell" .. id } end,
        GetCount = function(id) return id == 101 and s.reagent or 0 end,
        GetCharges = function(id) if id == 102 then return s.charges, 3, 90, 20 end end,
        GetCooldown = function() return 90, 30, true end,
        IsUsable = function() return true, false end,
    }
    flux.Item = {
        GetIcon = function(id) return 2000 + id end,
        GetCount = function(id, _, charge) if id == 201 then return s.copies end; return charge and s.uses or 1 end,
        UsesConsumableCharges = function(id) return id == 202 end,
        IsConsumable = function() return true end,
        IsUsable = function() return true, false end,
        GetCooldown = function() return 80, 60, true end,
    }
    env.C_Spell = { GetSpellInfo = function(token)
        local id = type(token) == "number" and token or tonumber(tostring(token):match("^Spell(%d+)$"))
        if id then return { spellID = id, name = "Spell" .. id } end
    end }
    flux.ButtonFX = { Charges = { Apply = function(_, data) s.cooldown = data end, ClearCache = function() end } }
    flux.Range = {
        CheckSpell = function(id) s.rangeKind, s.rangeID = "spell", id; return true end,
        CheckItem = function(id) s.rangeKind, s.rangeID = "item", id; return true end,
    }
    local ns = { Flux = flux }
    assert(loadfile(paintSource, "t", env))("_FluxUI", ns)
    assert(loadfile("ExtraButtonSystem/Engine/Action.lua", "t", env))("_FluxUI", ns)
    assert(loadfile("ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua", "t", env))("_FluxUI", ns)
    flux.Safecall = function(fn) return fn() end
    assert(loadfile("Core/Engine/Modifier.lua", "t", env))("_FluxUI", ns)
    local bus = s.frames[#s.frames]
    modifier = function()
        bus.scripts.OnEvent(bus, "MODIFIER_STATE_CHANGED")
        if bus.scripts.OnUpdate then bus.scripts.OnUpdate(bus, 0) end
        check(bus.scripts.OnUpdate == nil, "modifier bus parks after the event; no permanent polling")
    end
    assert(loadfile(source, "t", env))()
    local manager, assign, paint, action = env.FluxNCUtilitySlotsManager, env.FluxNCUtilitySlots, flux.EBS.Paint, flux.EBS.Action
    local paints = {}
    for _, lane in ipairs({ "Icon", "Count", "Usable", "Checked" }) do
        local name, original = "Update" .. lane, paint["Update" .. lane]
        paint[name] = function(...)
            paints[lane] = (paints[lane] or 0) + 1
            return original(...)
        end
    end
    local function paintedSwitch(chord)
        for k in pairs(paints) do paints[k] = nil end
        s.mod = chord; modifier()
        workTotals.transitions = workTotals.transitions + 1
        for _, lane in ipairs({ "Icon", "Count", "Usable", "Checked" }) do
            local n = paints[lane] or 0
            workTotals[lane:lower()] = workTotals[lane:lower()] + n
            -- Cooldown readiness may request its own usability refresh; the
            -- manager must add no duplicate icon/count/checked passes.
            if not measure then check(n <= (lane == "Usable" and 2 or 1), "bounded shared " .. lane .. " passes per modifier transition") end
        end
    end
    local w = { attrs = {} }
    function w:SetAttribute(k, v) check(not s.combat, "no protected combat writes"); s.writes = s.writes + 1; self.attrs[k] = v end
    function w:GetAttribute(k) return self.attrs[k] end
    function w:SetChecked(v) s.checked = v end
    local noop = function() end
    local icon = { SetTexture = function(_, v) s.icon = v end, SetTexCoord = noop, Show = noop, Hide = noop,
        SetDesaturated = noop, SetVertexColor = function(_, r) s.tint = r end }
    local count = { SetText = function(_, v) s.count = v end, Show = noop }
    local cd = { ClearAllPoints = noop, SetPoint = noop }
    local btn = { Widget = w, WIcon = icon, WCount = count, WCooldown = cd, slotIndex = 1, IsUtilitySlotButton = true }
    function btn:SetAction(t, v)
        check(not s.combat, "no combat action rebuild")
        self.ActionType, self.ActionValue, self.MacroBody, self.MacroMode = t, v, v, ""
        self.MacroAction, self.MacroTexture = nil, nil
        action.TranslateMacro(self)
    end
    function btn:TranslateMacro() action.TranslateMacro(self) end
    function btn:SetCount(v) self._forcedCount = v; paint.UpdateCount(self) end
    manager.buttons[1] = btn; flux.EBS.buttons[1] = btn
    assign.Manager = nil; manager.UpdateAllSlots = noop
    local pending = s.timers; s.timers = {}; for _, fn in ipairs(pending) do fn() end
    local function runTimers() local pending = s.timers; s.timers = {}; for _, fn in ipairs(pending) do fn() end end
    local function setup(map)
        s.combat = false; s.mod = ""; manager.UpdateButton(btn, map)
        check(btn._forcedCount == nil, "utility does not latch a count")
    end
    local function verify(map, expected)
        setup(map)
        local body, writes = btn.MacroBody, s.writes
        for i, chord in ipairs(chords) do
            s.combat = true; paintedSwitch(chord)
            local entry = expected[i]
            check(btn.MacroMode == entry.type, family .. " selected kind " .. chord)
            check((entry.type == "spell" and btn.SpellId or btn.ItemId) == entry.id, "selected identity " .. chord)
            check(s.icon == (entry.type == "spell" and 1000 or 2000) + entry.id, "selected icon " .. chord)
            check(s.count == (entry.id == 101 and "12" or entry.id == 102 and "2" or entry.id == 201 and "8" or "3"), "selected count " .. chord .. " got " .. tostring(s.count))
            check(s.cooldown and s.cooldown.duration == (entry.type == "spell" and 30 or 60), "selected cooldown " .. chord)
            action.UpdateTooltip(btn)
            check(s.tipKind == entry.type and s.tipID == entry.id, "selected tooltip " .. chord)
            check(s.rangeKind == entry.type and s.rangeID == entry.id, "selected range query " .. chord)
            local kind = w.attrs[prefixes[i] .. "type1"]
            local token = w.attrs[prefixes[i] .. (kind == "spell" and "spell1" or "item1")]
            local id = tonumber(tostring(token):match("%d+$"))
            check(kind == entry.type and id == entry.id, "prepared click identity " .. chord)
            check(w.attrs.macrotext == nil and w.attrs.clickbutton == nil,
                "native utility does not execute a macro/delegate " .. chord)
            -- Release every chord while still locked, rather than testing
            -- only the last modifier or waiting for combat to end.
            paintedSwitch("")
            local base = expected[1]
            check(btn.MacroMode == base.type, "combat release restores normal kind")
            check((base.type == "spell" and btn.SpellId or btn.ItemId) == base.id, "combat release restores normal identity")
            check(s.icon == (base.type == "spell" and 1000 or 2000) + base.id, "combat release restores normal icon")
            check(s.count == (base.id == 101 and "12" or base.id == 102 and "2" or base.id == 201 and "8" or "3"), "combat release restores normal count")
            local n = (paints.Icon or 0) + (paints.Count or 0) + (paints.Usable or 0) + (paints.Checked or 0)
            modifier()
            local duplicate = (paints.Icon or 0) + (paints.Count or 0) + (paints.Usable or 0) + (paints.Checked or 0) - n
            workTotals.duplicate = workTotals.duplicate + duplicate
            if not measure then check(duplicate == 0, "unchanged chord has no repeated visual work") end
        end
        check(s.writes == writes and btn.MacroBody == body, "combat face swaps keep secure actions intact")
        s.mod = ""; modifier()
        check(btn.SpellId == expected[1].id or btn.ItemId == expected[1].id, "release restores base")
    end
    local spell = { type = "spell", id = 101 }
    local stack = { type = "item", id = 201 }
    local charges = { type = "spell", id = 102 }
    local gem = { type = "item", id = 202 }
    verify({ [""] = spell, SHIFT = stack, CTRL = charges, ["SHIFT-CTRL"] = gem },
        { spell, stack, charges, spell, gem, spell, spell, spell })
    verify({ [""] = stack, SHIFT = spell, ALT = gem },
        { stack, spell, stack, gem, stack, stack, stack, stack })
    verify({ SHIFT = charges, CTRL = gem },
        { charges, charges, gem, charges, charges, charges, charges, charges })
    verify({ [""] = spell, SHIFT = stack, CTRL = charges, ALT = gem,
        ["SHIFT-CTRL"] = stack, ["SHIFT-ALT"] = charges, ["CTRL-ALT"] = spell, ["SHIFT-CTRL-ALT"] = gem },
        { spell, stack, charges, gem, stack, charges, spell, gem })
    setup({ [""] = spell, SHIFT = stack })
    s.combat = true; s.reagent = 7; inventory()
    check(s.count == "7", "combat bag pulse refreshes spell reagent")
    s.mod = "SHIFT"; modifier(); s.copies = 4; inventory()
    check(s.count == "4", "combat bag pulse refreshes item stack")
    s.copies = 0; inventory(); check(s.count == "0", "depleted item keeps zero")
    s.mod = ""; modifier(); check(s.count == "7", "item depletion does not latch onto spell")
    setup({ [""] = charges, SHIFT = gem })
    s.combat = true; s.charges = 1
    for _, frame in ipairs(s.frames) do
        if frame.events.SPELL_UPDATE_CHARGES then frame.scripts.OnEvent(frame, "SPELL_UPDATE_CHARGES") end
    end
    runTimers(); check(s.count == "1", "live charge event refreshes active spell")
    s.mod = "SHIFT"; modifier(); s.uses = 0; inventory()
    check(s.count == "0", "single charged item exhausts in combat")
    s.mod = ""; modifier(); check(s.count == "1", "spell charge restored after item zero")
    setup({ [""] = stack, SHIFT = charges, ["SHIFT-CTRL"] = gem })
    s.combat = true; s.mod = "SHIFT-CTRL"; modifier()
    s.copies = 5; s.mod = "SHIFT"; modifier()
    check(s.icon == 1102 and s.count == "1", "partial release restores remaining modifier spell/charges")
    s.mod = ""; modifier()
    check(s.icon == 2201 and s.count == "5", "full combat release restores latest normal item icon/count")
    s.mod = "SHIFT"; modifier(); s.copies = 0; inventory()
    s.mod = ""; modifier()
    check(s.icon == 2201 and s.count == "0", "combat release restores normal item depletion")
    setup({ [""] = spell, SHIFT = stack })
    s.combat = true; s.mod = "SHIFT"; modifier(); s.reagent = 3; inventory()
    s.mod = ""; modifier()
    check(s.icon == 1101 and s.count == "3", "combat release reads reagents changed while item was selected")
    local frameCount, pendingCount, writes = #s.frames, #s.timers, s.writes
    for i = 1, 50 do s.mod = "SHIFT"; modifier(); s.mod = ""; modifier() end
    check(#s.frames == frameCount and #s.timers == pendingCount and s.writes == writes,
        "repeated combat hold/release adds no frames/timers/protected writes")
    local formatter, parser = flux.Spell.FormatCastAttribute, env.SecureCmdOptionParse
    flux.Spell.FormatCastAttribute = function(id) return id == 101 and "Arcane Intellect(Rank 2)" or "Spell" .. id end
    env.SecureCmdOptionParse = function() error("native utility face must not parse a macro") end
    setup({ [""] = spell, SHIFT = stack, CTRL = charges })
    s.combat = true
    for _, chord in ipairs({ "", "SHIFT", "CTRL", "SHIFT-CTRL", "" }) do
        s.mod = chord; modifier()
        local entry = chord == "SHIFT" and stack or chord == "CTRL" and charges or spell
        check((entry.type == "spell" and btn.SpellId or btn.ItemId) == entry.id,
            "ranked utility retains exact saved identity without reverse name lookup")
        check(s.icon == (entry.type == "spell" and 1000 or 2000) + entry.id,
            "rank lookup miss cannot corrupt selected utility icon")
        check(s.count == (entry.id == 101 and "3" or entry.id == 102 and "1" or "0"),
            "rank lookup miss cannot corrupt selected reagent/charge/stack count")
    end
    flux.Spell.FormatCastAttribute, env.SecureCmdOptionParse = formatter, parser
    -- A consumable's active buff must never replace a utility item's lockout.
    -- Exercise the real modifier bus with both a short lockout and a ready item.
    local itemCooldown = flux.Item.GetCooldown
    local itemDuration, auraQueries = 1, 0
    flux.Item.GetCooldown = function() return 99, itemDuration, true end
    flux.Item.GetSpell = function() return "Consumable buff", 301 end
    flux.Aura = { GetPlayerAuraBySpellID = function()
        auraQueries = auraQueries + 1
        return { expirationTime = 400, duration = 300, auraInstanceID = 10 }
    end }
    setup({ [""] = spell, SHIFT = stack })
    s.combat = true; s.mod = "SHIFT"; modifier()
    check(s.cooldown.itemCooldown and s.cooldown.duration == 1 and not s.cooldown.expirationTime,
        "utility consumable shows short item cooldown while buff is active")
    itemDuration = 0; paint.UpdateCooldown(btn)
    check(s.cooldown.itemCooldown and s.cooldown.duration == 0 and not btn.FluxConsumableAuraCooldown,
        "ready utility consumable stays ready while buff is active")
    check(auraQueries == 0, "utility cooldown skips consumable aura lookups")
    workTotals.aura = workTotals.aura + auraQueries
    local function latchAura()
        btn.FluxConsumableAuraCooldown = true
        btn.StanceBuffCooldownStart, btn.StanceBuffCooldownDuration = 100, 300
        btn.StanceBuffExpirationTime, btn.StanceBuffTimeMod = 400, 1
        btn.StanceBuffDurationObject = {}
    end
    latchAura(); paint.UpdateCooldown(btn)
    check(not btn.FluxConsumableAuraCooldown and not btn.StanceBuffCooldownStart
        and not btn.StanceBuffCooldownDuration and not btn.StanceBuffExpirationTime
        and not btn.StanceBuffTimeMod and not btn.StanceBuffDurationObject,
        "utility clears all stale consumable aura fields during combat")
    check(s.cooldown.itemCooldown and s.cooldown.duration == 0,
        "clearing stale aura immediately restores item cooldown")
    latchAura(); s.mod = ""; modifier()
    check(s.cooldown.duration == 30 and not s.cooldown.expirationTime and not btn.FluxConsumableAuraCooldown,
        "combat modifier release restores spell cooldown despite stale item aura")
    -- The dedicated consumables button still owns its supplied aura countdown.
    btn.IsUtilitySlotButton, btn.IsConsumableButton = nil, true
    latchAura(); paint.UpdateCooldown(btn)
    check(s.cooldown.expirationTime == 400 and s.cooldown.duration == 300,
        "dedicated consumables button retains its aura countdown")
    btn.IsConsumableButton = nil
    btn.FluxConsumableAuraCooldown = nil; btn.StanceBuffDurationObject = nil
    btn.StanceBuffCooldownStart, btn.StanceBuffCooldownDuration = nil, nil
    btn.StanceBuffExpirationTime, btn.StanceBuffTimeMod = nil, nil
    btn.IsUtilitySlotButton = true
    flux.Item.GetCooldown, flux.Item.GetSpell, flux.Aura = itemCooldown, nil, nil
    flux.Spell.GetDisplayCount = function() return "" end
    paint.UpdateCount(btn); check(s.count == "", "authoritative empty spell display clears old digits")
    flux.Spell.GetDisplayCount = function() return "SECRET-DISPLAY" end
    flux.Secrets = { IsSecretValue = function(v) return v == "SECRET-DISPLAY" end }
    paint.UpdateCount(btn); check(s.count == "SECRET-DISPLAY", "opaque display reaches text setter")
end
print(("Utility mixed faces: %d checks, %d failures"):format(checks, failures))
print(("Modifier work: transitions=%d icon=%d count=%d usable=%d checked=%d duplicate=%d"):format(
    workTotals.transitions, workTotals.icon, workTotals.count, workTotals.usable, workTotals.checked, workTotals.duplicate))
print(("Utility consumable aura queries: %d"):format(workTotals.aura))
os.exit(failures > 0 and 1 or 0)
