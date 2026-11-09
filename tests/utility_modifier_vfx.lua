-- Production modifier bus, utility manager, macro translator, painter and Cast.
-- Overlay/Glow rendering and native unit data are modeled; no pixel/taint claim.
local sourceRoot = arg[1]
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s
end
for _, family in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    local s = { time = 10, mod = "", combat = false, frames = {}, timers = {}, tickers = {}, proc = {}, writes = 0, sync = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local noop = function() end
    env.GetTime = function() return s.time end
    env.InCombatLockdown = function() return s.combat end
    env.IsShiftKeyDown = function() return s.mod:find("SHIFT", 1, true) ~= nil end
    env.IsControlKeyDown = function() return s.mod:find("CTRL", 1, true) ~= nil end
    env.IsAltKeyDown = function() return s.mod:find("ALT", 1, true) ~= nil end
    env.UnitClass = function() return "Mage", "MAGE" end
    env.GetBindingKey = noop
    env.UnitExists = function() return false end
    env.UnitCastingInfo = function()
        if s.kind == "cast" then return "Spell" .. s.sid, nil, nil, s.start * 1000, (s.start + 8) * 1000, nil, nil, nil, s.sid end
    end
    env.UnitChannelInfo = function()
        if s.kind == "channel" then return "Spell" .. s.sid, nil, nil, s.start * 1000, (s.start + 8) * 1000, nil, nil, s.sid end
    end
    env.SpellIsTargeting = function() return s.targeting end
    env.geterrorhandler = function() return function(err) error(err) end end
    env.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    env.CreateFrame = function()
        check(not s.combat, "no frame creation during combat face changes")
        local f = { events = {}, scripts = {} }
        function f:RegisterEvent(e) self.events[e] = true end
        function f:RegisterUnitEvent(e) self.events[e] = true end
        function f:SetScript(e, fn) self.scripts[e] = fn end
        s.frames[#s.frames + 1] = f; return f
    end
    env.SecureCmdOptionParse = function(options)
        for fragment in (options .. ";"):gmatch("(.-);") do
            local value = fragment:gsub("%b[]", ""):match("^%s*(.-)%s*$")
            local any, matched = false, false
            for cond in fragment:gmatch("%[(.-)%]") do
                any = true; local ok = true
                for term in cond:gmatch("[^,]+") do
                    local yes, no = term:match("^mod:(.+)$"), term:match("^nomod:(.+)$")
                    if yes and not s.mod:find(yes:upper(), 1, true) then ok = false end
                    if no and s.mod:find(no:upper(), 1, true) then ok = false end
                    if term == "exists" then ok = false end
                end
                matched = matched or ok
            end
            if value ~= "" and (not any or matched) then return value, "target" end
        end
    end
    local flux = { EBS = { buttons = {} }, Safecall = function(fn) return fn() end,
        Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end },
        Client = { isPostDF = family == "live" or family == "forever" },
        Combat = { InLockdown = env.InCombatLockdown },
        Ticker = { Add = function(k, fn) s.tickers[k] = fn end, Remove = function(k) s.tickers[k] = nil end } }
    env.Flux, env.FluxButton = flux, {}; local ns = { Flux = flux }
    local itemSpells = { [201] = 301, [203] = 101 }
    flux.Spell = { FormatCastAttribute = function(id) return "Spell" .. id end,
        GetOverrideSpell = function(id) return id end, GetName = function(id) return "Spell" .. id end,
        GetTexture = function(id) return 1000 + tonumber(id) end,
        GetCooldown = function() return 0, 0, true end, GetCount = function() return 0 end,
        IsUsable = function() return true, false end }
    flux.Item = { GetIcon = function(id) return 2000 + id end, GetCount = function() return 4 end,
        UsesConsumableCharges = function() return false end, IsConsumable = function() return true end,
        IsUsable = function() return true, false end, GetCooldown = function() return 0, 0, true end,
        GetSpell = function(id) local sid = itemSpells[id]; if sid then return "Spell" .. sid, sid end end }
    env.C_Item = { GetItemSpell = flux.Item.GetSpell }
    env.C_Spell = { GetSpellInfo = function(v)
        local id = tonumber(v) or tonumber(tostring(v):match("^Spell(%d+)$"))
        if id then return { spellID = id, name = "Spell" .. id } end
    end }
    local ov = { CAST = 1, CHANNEL = 2, EMPOWER = 3, BURST_DURATION = 0.45 }
    local function set(w, mode) w.mode = mode; w._fluxVfxMode = mode end
    ov.IsLiveCast = function(w) return w.mode == "cast" end
    ov.IsLiveReticle = function(w) return w.mode == "reticle" end
    ov.IsLiveInterrupt = function(w) return w.mode == "interrupt" and s.time < (w.untilTime or 0) end
    ov.IsLiveBurst = function(w) return w.mode == "finish" and s.time < (w.untilTime or 0) end
    ov.PlayCast = function(w, kind) set(w, "cast"); w.actionButtonCastType = kind; w.progressStart = s.start end
    ov.SyncCast = function(w, kind) s.sync = s.sync + 1; ov.PlayCast(w, kind) end
    ov.TickFill = noop
    ov.PlayReticle = function(w) set(w, "reticle") end
    ov.ClearReticle = function(w) if w.mode == "reticle" then set(w, nil) end end
    ov.ForceClear = function(w) set(w, nil); w.actionButtonCastType = nil end
    ov.HideCastFill = function(w) if w.mode == "cast" then ov.ForceClear(w) end end
    ov.PlayInterrupt = function(w) set(w, "interrupt"); w.untilTime = s.time + 0.2 end
    ov.SyncInterrupt = ov.PlayInterrupt
    ov.SyncBurst = function(w) set(w, "finish"); w.untilTime = s.time + 0.45 end
    ov.StopCast = function(w, interrupted) if interrupted then ov.ForceClear(w) else ov.SyncBurst(w) end end
    local glow = { Want = function(id) return s.proc[id] == true end,
        FaceShowsSpell = function(texture, id) return texture == 1000 + id end,
        IsLive = function(w) return w.glow == true end,
        Set = function(w, on) w.glow = on end,
        NoteShown = function(w, id) w._fluxGlowSpell = id end,
        NoteHidden = function(w) w._fluxGlowSpell = nil end }
    flux.ButtonFX = { Overlay = ov, Glow = glow, Charges = { Apply = noop, ClearCache = noop } }
    local function loadFile(path)
        local override = sourceRoot and (sourceRoot .. "/" .. path)
        local f = override and io.open(override, "rb")
        local body = f and f:read("*a") or read(path); if f then f:close() end
        return assert(load(body, "@" .. path, "t", env))("_FluxUI", ns)
    end
    loadFile("Core/ButtonFX/Cast.lua")
    loadFile("ExtraButtonSystem/Engine/Paint.lua")
    loadFile("ExtraButtonSystem/Engine/Action.lua")
    loadFile("ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua")
    loadFile("Core/Engine/Modifier.lua"); local bus = s.frames[#s.frames]
    loadFile("ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua")
    local manager, paint, action, cast = env.FluxNCUtilitySlotsManager, flux.EBS.Paint, flux.EBS.Action, flux.ButtonFX.Cast
    local follow = cast.FollowExtra
    s.follow = 0
    if follow then cast.FollowExtra = function(...) s.follow = s.follow + 1; return follow(...) end end
    local w = { attrs = {}, shown = true }
    function w:SetAttribute(k, v) check(not s.combat, "no protected VFX modifier write"); self.attrs[k] = v; s.writes = s.writes + 1 end
    function w:GetAttribute(k) return self.attrs[k] end
    function w:SetChecked() end
    function w:IsShown() return self.shown end
    local icon = { SetTexture = function(_, v) s.icon = v end, GetTexture = function() return s.icon end,
        SetTexCoord = noop, SetDesaturated = noop, SetVertexColor = noop, Show = noop, Hide = noop }
    local b = { Widget = w, WIcon = icon, WCooldown = { ClearAllPoints = noop, SetPoint = noop }, slotIndex = 1,
        IsUtilitySlotButton = true, ActionType = "macrotext", WCount = { SetText = noop, Show = noop } }
    w.FluxButton = b
    function b:SetAction(t, v) self.ActionType, self.ActionValue, self.MacroBody = t, v, v; self.MacroAction = nil; action.TranslateMacro(self) end
    function b:TranslateMacro() action.TranslateMacro(self) end
    manager.buttons[1] = b; flux.EBS.buttons[1] = b
    cast.Register(w, function() return flux.ButtonFX.SpellIdFromEBS(b) end, cast.RANK_EBS)
    local other = { mode = "cast", _fluxCastSpell = 999 }
    cast.Register(other, function() return 999 end, cast.RANK_MAIN)
    local pet = { mode = "cast", _fluxCastSpell = 101 }
    cast.Register(pet, function() return 101 end, cast.RANK_EBS, "pet")
    local pending = s.timers; s.timers = {}; for _, fn in ipairs(pending) do fn() end
    local map = { [""] = { type = "spell", id = 101 }, SHIFT = { type = "item", id = 201 },
        CTRL = { type = "spell", id = 102 }, ALT = { type = "item", id = 202 }, ["SHIFT-CTRL"] = { type = "item", id = 203 } }
    manager.UpdateButton(b, map)
    s.combat = true
    local function mod(chord)
        s.mod = chord; bus.scripts.OnEvent(bus)
        if bus.scripts.OnUpdate then bus.scripts.OnUpdate(bus, 0) end
    end
    local function emit(event, sid) cast._frame.scripts.OnEvent(cast._frame, event, "player", "Cast-guid", sid) end
    local function start(kind, sid)
        s.kind, s.sid, s.start = kind, sid, s.time
        emit(kind == "channel" and "UNIT_SPELLCAST_CHANNEL_START" or kind == "empower" and "UNIT_SPELLCAST_EMPOWER_START" or "UNIT_SPELLCAST_START", sid)
    end
    start("cast", 101); check(w.mode == "cast", "base cast begins on utility")
    s.time = 12; mod("SHIFT"); check(w.mode == nil, "item modifier clears prior spell cast")
    mod(""); check(w.mode == "cast" and w.progressStart == 10, "release resumes normal cast at existing progress")
    mod("SHIFT-CTRL"); check(w.mode == "cast", "item sharing use-spell preserves matching effect")
    mod("ALT"); check(w.mode == nil, "item without use spell clears cast instead of retaining old stamp")
    emit("UNIT_SPELLCAST_INTERRUPTED", 101); check(w.mode == nil, "old interrupted owner cannot repaint replacement item")
    s.kind = nil; mod(""); check(w.mode == "interrupt", "return during live interrupt window shows matching interrupt")
    mod("SHIFT"); check(w.mode == nil, "interrupt clears when face leaves")
    s.time = 13; mod(""); check(w.mode == nil, "expired interrupt cannot reappear")
    mod("SHIFT"); start("channel", 301); check(w.mode == "cast" and w.actionButtonCastType == 2, "item use-spell channel VFX starts")
    mod(""); check(w.mode == nil, "release clears modifier-item channel")
    mod("SHIFT"); check(w.mode == "cast" and w.actionButtonCastType == 2, "repress resumes live item channel")
    s.kind = nil; emit("UNIT_SPELLCAST_CHANNEL_STOP", 301)
    mod(""); check(w.mode == nil, "channel terminal VFX never leaks to normal spell")
    s.time = 20; start("cast", 101); s.kind = nil; emit("UNIT_SPELLCAST_SUCCEEDED", 101)
    check(w.mode == "finish", "cast completion burst starts")
    mod("SHIFT"); check(w.mode == nil, "modifier clears mismatched finish burst")
    mod(""); check(w.mode == "finish", "release within finish window restores matching burst")
    mod("SHIFT"); s.time = 21; mod(""); check(w.mode == nil, "expired burst stays cleared")
    s.targeting = true; emit("UNIT_SPELLCAST_RETICLE_TARGET", 101)
    check(w.mode == "reticle", "base targeting effect starts")
    mod("SHIFT"); check(w.mode == nil, "modifier clears reticle")
    if s.tickers["buttonfx.reticle"] then s.tickers["buttonfx.reticle"]() end
    check(w.mode == nil, "reticle watch cannot restore departed owner")
    mod(""); check(w.mode == "reticle", "release restores active targeting effect")
    s.targeting = false; emit("UNIT_SPELLCAST_RETICLE_CLEAR", 101); check(w.mode == nil, "target cancel clears restored effect")
    mod("CTRL"); start("empower", 102); check(w.mode == "cast" and w.actionButtonCastType == 3, "empower starts")
    mod(""); check(w.mode == nil, "release clears modifier empower")
    mod("CTRL"); check(w.mode == "cast" and w.actionButtonCastType == 3, "empower can return before unit data arrives")
    s.kind = nil; cast._active = nil; ov.ForceClear(w)
    s.proc[101], s.proc[301] = true, true
    mod(""); check(w.glow and w._fluxGlowSpell == 101, "normal spell proc restored")
    mod("SHIFT"); check(w.glow and w._fluxGlowSpell == 301, "item proc follows known use spell despite different item art")
    mod("ALT"); check(not w.glow and w._fluxGlowSpell == nil, "passive item clears old proc")
    mod(""); check(w.glow and w._fluxGlowSpell == 101, "release restores normal spell proc")
    local n, writes, timers = #s.frames, s.writes, #s.timers
    for i = 1, 50 do mod("SHIFT"); mod("") end
    check(#s.frames == n and s.writes == writes and #s.timers == timers, "repeated VFX changes add no frame/timer/secure writes")
    local sync = s.sync; for i = 1, 20 do mod("") end
    check(s.sync == sync, "duplicate chord events do no cast refresh")
    local follows = s.follow
    for i = 1, 20 do action.TranslateMacro(b) end
    check(s.follow == follows, "unchanged macro context does not query or settle cast VFX")
    if follow then cast.FollowExtra(other); cast.FollowExtra(pet) end
    check(other.mode == "cast" and pet.mode == "cast", "strip and pet VFX owners remain independent")
    if not flux.Client.isPostDF then
        s.time = 30; start("cast", 101); mod("SHIFT")
        env.FluxOptions = { GetActionbarsDB = function() return { spellCastVFX = false } end }
        mod(""); check(w.mode == nil, "disabled pre-DF VFX cannot reappear on release")
    end
    s.combat = false; s.kind = "cast"; s.sid = 101; s.start = s.time
    env.FluxOptions = nil; b.MacroMode, b.SpellId, b.ItemId = "spell", 101, nil
    if follow then cast.FollowExtra(w) end
    action.Clear(b)
    check(w.mode == nil and not w.glow, "clearing utility removes both cast and proc effects: " .. tostring(w.mode) .. "/" .. tostring(w.glow))
end
print(("Utility modifier VFX: %d checks; five clients; cast/channel/empower/reticle/burst/interrupt/proc lifecycle PASS"):format(checks))
