-- lua CharacterInfo/_tmp_foreverstatssmoke.lua
-- Run the real Info frame providers, saved pins, and character-row click handlers.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function Read(path)
    local f = assert(io.open(root .. path)); local source = f:read("*a"); f:close(); return source
end
local function Compile(source, env)
    if setfenv then local f = assert(loadstring(source)); setfenv(f, env); return f end
    return assert(load(source, "Forever shared stats fixture", "t", env))
end
local function Noop() end
local function Frame()
    local frame = { scripts = {}, events = {} }
    function frame:RegisterEvent(name) self.events[name] = true end
    frame.RegisterUnitEvent = frame.RegisterEvent
    frame.EnableMouse, frame.SetMouseClickEnabled = Noop, Noop
    function frame:SetScript(name, fn) self.scripts[name] = fn end
    function frame:GetScript(name) return self.scripts[name] end
    function frame:HookScript(name, fn)
        local previous = self.scripts[name]
        self.scripts[name] = function(...)
            if previous then previous(...) end
            fn(...)
        end
    end
    function frame:CreateTexture()
        local texture = { SetTexture = Noop, SetSize = Noop, SetPoint = Noop,
            ClearAllPoints = Noop, SetVertexColor = Noop }
        function texture:Show() self.shown = true end
        function texture:Hide() self.shown = false end
        return texture
    end
    return frame
end
local function Load(camelot, project)
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC, env.WOW_PROJECT_WRATH_CLASSIC = 1, 2, 11
    env.WOW_PROJECT_ID = project or 1
    env.Flux = { Client = { isCamelot = camelot } }
    env.FLUX_API = { isCamelot = camelot, isRetail = env.WOW_PROJECT_ID == 1 }
    env.C_Timer = { After = Noop }
    env.wipe = function(values) for key in pairs(values) do values[key] = nil end end
    env.frames = {}
    env.CreateFrame = function()
        local frame = Frame(); env.frames[#env.frames + 1] = frame; return frame
    end
    env.GetTime, env.InCombatLockdown = function() return 10 end, function() return env.combat == true end
    env.GetCritChance = function() return 11 end
    env.GetRangedCritChance = function() return 13 end
    env.GetSpellCritChance = function(...) assert(select("#", ...) == 0); return 17 end
    env.GetMeleeHaste = function() return 4 end
    env.GetRangedHaste = function() return 5, 2 end
    env.UnitSpellHaste = function(unit) assert(unit == "player"); return 6 end
    env.GetHaste = function() return 99 end
    env.CR_HIT_MELEE, env.CR_HIT_RANGED, env.CR_HIT_SPELL = 6, 7, 8
    env.GetCombatRatingBonus = function(index) return ({ [6] = 1, [7] = 2, [8] = 3 })[index] end
    env.GetHitModifier = function() return 1 end
    env.GetOffhandHitModifier = function() return 4 end
    env.GetRangedHitModifier = function() return 2 end
    env.GetSpellHitModifier = function() return 3 end
    Compile(Read("StatusBars/FluxInfoFrame.lua"), env)()
    env.originalForceRebuild = env.FluxInfoFrame.ForceRebuild
    env.FluxInfoFrame.ForceRebuild = Noop -- Layout needs the WoW renderer; pin logic does not.
    return env, env.FluxInfoFrame
end

local env, info = Load(true)
local registry = info.GetStatRegistry()
assert(registry.crit.get() == 17 and registry.rangedCrit.get() == 17 and registry.meleeCrit.get() == 17)
assert(registry.haste.get() == 7, "Forever haste must include ammo and use native channels before GetHaste")
assert(registry.meleeHit.get() == 6 and registry.spellHit.get() == 6 and registry.rangedHit.get() == 6)
env.GetOffhandHitModifier = function() return 8 end
assert(registry.meleeHit.get() == 9, "combined hit must match the native row's offhand calculation")
for _, key in ipairs({ "crit", "meleeCrit", "rangedCrit", "spellCrit" }) do assert(info.StatLabel(key) == "Crit") end
for _, key in ipairs({ "meleeHit", "rangedHit", "spellHit", "hit" }) do assert(info.StatLabel(key) == "Hit") end
assert(info.StatLabel("rangedHaste") == "Haste")

env._FluxUI_CharSavedVars = { infoFrame = {
    showFPS = false, showPing = false, showDurability = false, spellDisplayMode = "off",
    pinnedStats = { meleeHit = true, rangedHit = true, spellHit = true,
        meleeCrit = true, rangedCrit = true, spellCrit = true, crit = true,
        rangedHaste = true, spell_haste = true, haste = true, gearScore = true },
    statOrder = { "rangedHit", "gearScore", "spellHit", "spellCrit", "rangedHaste", "meleeCrit", "crit", "haste" },
} }
local visible = info.GetOrderedVisibleStats()
assert(#visible == 4 and visible[1].key == "meleeHit" and visible[2].key == "gearScore"
    and visible[3].key == "crit" and visible[4].key == "haste", "saved pins must fold without losing order")
local snapshot = info.SerializeRespecProfileSnapshot()
assert(snapshot.pinnedStats.meleeHit and snapshot.pinnedStats.crit and snapshot.pinnedStats.haste)
assert(not snapshot.pinnedStats.spellHit and not snapshot.pinnedStats.meleeCrit and not snapshot.pinnedStats.rangedHaste)
for _, group in ipairs({ { "meleeHit", "rangedHit", "spellHit", "hit_chance" },
    { "crit", "meleeCrit", "rangedCrit", "spellCrit" }, { "haste", "meleeHaste", "rangedHaste", "spell_haste" } }) do
    for _, key in ipairs(group) do assert(info.IsStatPinned(key)) end
    info.TogglePinnedStat(group[2])
    for _, key in ipairs(group) do assert(not info.IsStatPinned(key), "unpin left a duplicate enabled: " .. key) end
    info.TogglePinnedStat(group[3])
    for _, key in ipairs(group) do assert(info.IsStatPinned(key)) end
end

local function Text(value)
    return { text = value, GetText = function(self) return self.text end,
        SetText = function(self, text) self.text = text end }
end
local rows = {}
for i, key in ipairs({ "meleeHit", "rangedHit", "spellHit", "meleeCrit", "rangedCrit", "spellHaste" }) do
    local row = Frame()
    row.Label, row.Value, row.numericValue = Text(key), Text("9.0%"), 9
    info.HookForeverScrollBoxStatFrame(row, key)
    assert(row._FluxInfoStatKey == info._CamelotCombatStatKey(key))
    assert(row.Label:GetText() == info.StatLabel(key) and row._fluxPinIndicatorTex.shown)
    rows[i] = row
end
env.CharacterStatsPaneScrollBox = { ScrollBox = { GetView = function()
    return { GetFrames = function() return rows end }
end } }
rows[2].scripts.OnMouseUp(rows[2], "RightButton")
assert(info.IsStatPinned("meleeHit"), "right click changed a pin")
rows[2].scripts.OnMouseUp(rows[2], "LeftButton")
for i = 1, 3 do assert(not rows[i]._fluxPinIndicatorTex.shown) end
rows[3].scripts.OnMouseUp(rows[3], "LeftButton")
for i = 1, 3 do assert(rows[i]._fluxPinIndicatorTex.shown) end
assert(info._foreverStatCache.meleeHit == 9 and info._foreverStatCache.spellHit == nil)
assert(info.ReadForeverDisplayText("spellHit") == "9.0%")
assert(#info.ResolveStatFramesForTooltip("rangedHit", false) == 3, "shared pin tooltip lost its source rows")

-- Respec imports can reintroduce legacy aliases after the initial migration.
info.ApplyRespecProfileSnapshot({ pinnedStats = { spellHit = true, spellCrit = true, spellHaste = true },
    statOrder = { "spellHaste", "spellHit", "spellCrit" } })
visible = info.GetOrderedVisibleStats()
assert(#visible == 3 and visible[1].key == "haste" and visible[2].key == "meleeHit" and visible[3].key == "crit")

-- Restricted channels cannot be replaced by a lower channel or an old row snapshot.
local secretValues = {}
local function Secret(value)
    local token = setmetatable({}, { __lt = function() error("compared secret") end,
        __add = function() error("added secret") end, __tostring = function() error("formatted secret in Lua") end })
    secretValues[token] = value
    return token
end
local secret = Secret(32.25)
env.issecretvalue = function(value) return secretValues[value] ~= nil end
env.GetCritChance, env.GetRangedCritChance, env.GetSpellCritChance = function() return secret end, function() error("unavailable") end, function() return secret end
assert(registry.crit.get() == nil)
env.GetRangedCritChance = function() return 0 end
assert(registry.crit.get() == nil, "a readable channel must not replace restricted shared crit")
local function Upvalue(fn, name)
    for i = 1, 100 do
        local key, value = debug.getupvalue(fn, i)
        if not key then break end
        if key == name then return value end
    end
end
local keyText = assert(Upvalue(assert(Upvalue(info._FlushPlayerStatRefresh, "UpdateStats")), "_GetKeyText"))
info._foreverStatCache.crit, info._foreverStatText.crit = 999, "999.0%"
local function Sink(entry)
    return { _fluxEntryRef = entry, SetFormattedText = function(self, fmt, ...)
        -- Stand in for the native text renderer, the only consumer allowed to
        -- unwrap these values. Addon code must forward the original tokens.
        self.arguments = { ... }
        local nativeArgs = {}
        for i, value in ipairs(self.arguments) do nativeArgs[i] = secretValues[value] or value end
        self.text = string.format(fmt, (unpack or table.unpack)(nativeArgs))
    end }
end
local critSample = keyText("crit")
assert(not critSample:find("--", 1, true))
local critSink = Sink({ text = critSample, keys = { "crit" } })
info._RenderCamelotLiveText(critSink)
assert(critSink.arguments[1] == secret and critSink.text == "Crit: |cffffffff32.25%|r")
local nextCrit = Secret(63.75)
env.GetCritChance = function() return nextCrit end
assert(keyText("crit") == critSample, "live values changed the layout measurement sample")
info._RenderCamelotLiveText(critSink)
assert(critSink.arguments[1] == nextCrit and critSink.text:find("63.75%", 1, true), "combat crit froze")

-- The real update loop must redraw secret text even when layout samples have
-- not changed. Otherwise the first displayed combat number would freeze.
local updateStats = assert(Upvalue(info._FlushPlayerStatRefresh, "UpdateStats"))
local function SetUpvalue(fn, name, value)
    for i = 1, 100 do
        local key, previous = debug.getupvalue(fn, i)
        if not key then break end
        if key == name then debug.setupvalue(fn, i, value); return previous end
    end
    error("missing upvalue: " .. name)
end
local active = assert(Upvalue(updateStats, "activeLines"))
local pool = assert(Upvalue(info._RefreshCamelotLiveText, "linePool"))
critSink.IsShown = function() return true end
pool[1], active[1] = critSink, { key = "crit", fs = critSink, fullText = critSample, compactText = critSample }
SetUpvalue(updateStats, "frame", { IsShown = function() return true end,
    GetWidth = function() return 200 end, GetHeight = function() return 80 end })
SetUpvalue(updateStats, "activeLineCount", 1)
SetUpvalue(updateStats, "_lastLayoutMode", "vertical")
SetUpvalue(updateStats, "_lastLayoutW", 200)
SetUpvalue(updateStats, "_lastLayoutH", 80)
local combatCrit = Secret(85.5)
env.GetCritChance = function() return combatCrit end
updateStats()
assert(critSink.arguments[1] == combatCrit and critSink.text:find("85.50%", 1, true), "unchanged layout froze a live combat value")
pool[1], active[1] = nil, nil
SetUpvalue(updateStats, "frame", nil)
SetUpvalue(updateStats, "activeLineCount", 0)
SetUpvalue(updateStats, "_lastLayoutMode", nil)
SetUpvalue(updateStats, "_lastLayoutW", nil)
SetUpvalue(updateStats, "_lastLayoutH", nil)
env.GetCritChance, env.GetSpellCritChance = function() return 0 end, function() return 0 end
assert(registry.crit.get() == 0, "zero is a valid shared stat")
assert(keyText("crit"):find("0.00%", 1, true), "crit failed to recover when values became readable")
env.GetRangedHaste = function() return 5, secret end
env.GetSpellHitModifier = function() return secret end
local liveHaste = Secret(7.25)
env.GetMeleeHaste = function() return liveHaste end
env.GetHitModifier = function() return secret end
assert(registry.haste.get() == nil and registry.meleeHit.get() == nil)
info._foreverStatCache.haste, info._foreverStatText.haste = 888, "888.0%"
local hasteSample, hitSample = keyText("haste"), keyText("meleeHit")
local merged = Sink({ text = "Dur: 80% / " .. hasteSample .. " / " .. hitSample, keys = { "durability", "haste", "meleeHit" } })
info._RenderCamelotLiveText(merged)
assert(merged.text == "Dur: 80% / Haste: |cffffffff7.25%|r / Hit: |cffffffff1.00% + 32.25%|r",
    "merged combat stats did not reach the native renderer with live rating and modifier")

-- Prefer a current native total when it is visible. A hidden row is not a live source.
local nativeHit = Secret("33.25%")
local nativeRow = { GetElementData = function() return { name = "HITCHANCE", unit = "player" } end,
    Value = Text(nativeHit) }
env.CharacterStatsPaneScrollBox = { IsVisible = function() return env.nativeVisible end,
    ScrollBox = { GetView = function() return { GetFrames = function() return { nativeRow } end } end } }
env.nativeVisible = true
local nativeSink = Sink({ text = keyText("meleeHit"), keys = { "meleeHit" } })
info._RenderCamelotLiveText(nativeSink)
assert(nativeSink.arguments[1] == nativeHit and nativeSink.text == "Hit: |cffffffff33.25%|r")
env.nativeVisible = false
nativeSink._fluxEntryRef.text = keyText("meleeHit")
info._RenderCamelotLiveText(nativeSink)
assert(nativeSink.text:find("1.00% + 32.25%", 1, true), "hidden native row was treated as a current total")
info.RememberPinnedStatValue("crit", secret)
assert(info._foreverStatCache.crit == nil and info._foreverStatText.crit == nil)
info.RememberPinnedStatValue("haste", 7, { Value = Text(secret) })
assert(info._foreverStatCache.haste == nil and info._foreverStatText.haste == nil)

-- Open/close and combat transitions must never edit native rows during lockdown.
local watch, events
for _, frame in ipairs(env.frames) do
    if frame.scripts.OnUpdate and Upvalue(frame.scripts.OnUpdate, "wasShown") ~= nil then watch = frame end
    if frame.events.COMBAT_RATING_UPDATE then events = frame end
end
assert(watch and events and events.events.PLAYER_REGEN_ENABLED and events.events.UNIT_SPELL_HASTE)
local opens = 0
info.AfterCharacterShown(function() opens = opens + 1 end)
env.CharacterFrame = { shown = false, IsShown = function(self) return self.shown end }
watch.scripts.OnUpdate()
env.combat, env.CharacterFrame.shown = true, true
watch.scripts.OnUpdate(); watch.scripts.OnUpdate()
assert(opens == 0, "post-open callback ran in combat")
local combatRow = Frame(); combatRow.Label, combatRow.Value = Text("Crit"), Text("0.0%")
info.HookForeverScrollBoxStatFrame(combatRow, "crit")
assert(not combatRow._FluxInfoStatKey and not combatRow.scripts.OnMouseUp)
info.ForceRebuild = env.originalForceRebuild
info.TogglePinnedStat("crit")
assert(info._rebuildAfterCombat, "combat pin changes were not deferred")
env.combat = false
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
assert(not info._rebuildAfterCombat)
watch.scripts.OnUpdate(); watch.scripts.OnUpdate()
assert(opens == 1, "open in combat did not refresh once after combat")
env.combat = true; watch.scripts.OnUpdate()
env.combat = false; watch.scripts.OnUpdate()
assert(opens == 2, "window left open through combat did not refresh")
env.CharacterFrame.shown = false; watch.scripts.OnUpdate()
env.combat, env.CharacterFrame.shown = true, true; watch.scripts.OnUpdate()
env.CharacterFrame.shown = false; watch.scripts.OnUpdate()
env.combat = false; watch.scripts.OnUpdate()
assert(opens == 2, "closed window retained a combat refresh")

for _, project in ipairs({ 1, 2, 11 }) do
    local otherEnv, other = Load(false, project)
    local otherRegistry = other.GetStatRegistry()
    other.TogglePinnedStat("rangedHit")
    assert(other.IsStatPinned("rangedHit") and not other.IsStatPinned("meleeHit") and not other.IsStatPinned("spellHit"))
    assert(other.StatLabel("spellHit") == "S.Hit" and other.StatLabel("meleeHit") == "M.Hit")
    assert(otherRegistry.crit.get() == 11 and otherRegistry.rangedCrit.get() == 13)
    assert(otherRegistry.haste.get() == 99)
    assert(otherRegistry.meleeHit.get() == 2 and otherRegistry.rangedHit.get() == 4)
    assert(other._CamelotCombatStatKey("spellHaste") == "spellHaste")
    otherEnv.FLUX_API.isCamelot = true
    assert(not other._IsCamelotClient(), "compatibility flags must not override the canonical client")
    if project ~= 1 then
        other.TogglePinnedStat("rangedCrit")
        assert(other.IsStatPinned("rangedCrit") and not other.IsStatPinned("meleeCrit"))
    end
end
local _, dedicated = Load(true, 17)
dedicated.TogglePinnedStat("spellCrit")
dedicated.TogglePinnedStat("rangedHit")
dedicated.TogglePinnedStat("spellHaste")
assert(dedicated.IsStatPinned("meleeCrit") and dedicated.IsStatPinned("spellHit") and dedicated.IsStatPinned("haste"))
assert(dedicated.StatLabel("crit") == "Crit" and dedicated.StatLabel("haste") == "Haste")
print("Forever shared stats OK: native values, live combat text/merged rows, native totals, saved order, row clicks/tooltips; Live/Era/Wrath isolated")
