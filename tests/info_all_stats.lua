-- Exercise every built-in stat through the actual display path. Opaque token
-- errors model forbidden Lua operations; native VM/rendering remain untested.
local function read(path)
    local f = assert(io.open(path)); local s = f:read("*a"); f:close(); return s
end
local fixture = read("CharacterInfo/_tmp_foreverstatssmoke.lua")
fixture = fixture:sub(1, assert(fixture:find("local env, info = Load(true)", 1, true)) - 1)
local loaderEnv = setmetatable({ arg = { [0] = "tests/info_all_stats.lua" } }, { __index = _G })
if arg[1] then
    loaderEnv.io = setmetatable({ open = function(path, ...)
        if path:find("StatusBars/FluxInfoFrame.lua", 1, true) then path = arg[1] end
        return io.open(path, ...)
    end }, { __index = io })
end
local Load = assert(load(fixture .. "\nreturn Load", "@all-stats-fixture", "t", loaderEnv))()
local function upvalue(fn, name, replacement)
    for i = 1, 100 do
        local key, value = debug.getupvalue(fn, i)
        if not key then break end
        if key == name then
            if replacement ~= nil then debug.setupvalue(fn, i, replacement) end
            return value
        end
    end
    error("missing " .. name)
end
local checks, categories = 0, {}
local function check(ok, msg) checks = checks + 1; assert(ok, msg) end
local function setup(forever, project)
    local env, info = Load(forever, project)
    local opaqueValues, restricted, revision, reads = {}, false, 0, 0
    local function value(n)
        reads = reads + 1
        n = n + revision
        if not restricted then return n end
        local token = setmetatable({}, { __add = function() error("secret sum") end,
            __sub = function() error("secret subtraction") end, __mul = function() error("secret multiplication") end,
            __div = function() error("secret division") end, __lt = function() error("secret comparison") end,
            __le = function() error("secret comparison") end, __tostring = function() error("secret stringify") end })
        opaqueValues[token] = n; return token
    end
    env.issecretvalue = function(v) return opaqueValues[v] ~= nil end
    env.canaccessvalue = function(v) return opaqueValues[v] == nil end
    local function constant(n) return function() return value(n) end end
    for name, n in pairs({ GetSpellBonusHealing = 700, GetMasteryEffect = 12, GetDodgeChance = 3,
        GetParryChance = 4, GetBlockChance = 5, GetExpertise = 6, GetSpellPenetration = 7,
        GetArmorPenetration = 8, GetLifesteal = 9, GetAvoidance = 10, UnitHealthMax = 3000,
        UnitPowerMax = 2000, GetVersatilityBonus = 4, GetCombatRating = 18 }) do env[name] = constant(n) end
    env.GetOverrideAPBySpellPower = function() return 0 end
    env.GetSpellBonusDamage = function(school) return value(school == 3 and 1000 or 800) end
    env.UnitStat = function(unit, index) check(unit == "player", "primary unit"); return value(1), value(100 + index) end
    env.UnitArmor = function() return value(50), value(150) end
    env.UnitAttackPower = function() return value(100), value(20), value(-5) end
    env.UnitRangedAttackPower = function() return value(200), value(30), value(-10) end
    env.UnitDamage = function() return value(100), value(150), value(50), value(75) end
    env.UnitRangedDamage = function() return value(2), value(80), value(120) end
    env.UnitAttackSpeed = function() return value(2), value(3) end
    env.GetManaRegen = function() return value(20), value(10) end
    env.GetUnitSpeed = function() return value(0), value(7), value(14), value(4) end
    env.IsSwimming, env.IsFlying = function() return false end, function() return false end
    env.UnitDefenseSkill = function() return value(300), value(-5) end
    env.GetCombatRatingBonus = function() return value(1) end
    env.GetHitModifier, env.GetRangedHitModifier, env.GetSpellHitModifier = constant(2), constant(3), constant(4)
    env.CR_VERSATILITY_DAMAGE_DONE, env.CR_RESILIENCE_CRIT_TAKEN = 29, 15
    env.FluxCSC_GetPlayerItemLevel, env.FluxCSC_GetPlayerGearScore = function() return 100 end, function() return 1000 end
    env.CSC_InfoFrame_BuildSpellPowerData = function() error("partial CSC provider must not run") end
    info._camelotSpellSnapshot = { bonus = { [3] = 9999 }, shown = 9999, heal = 9999, shownText = "9999", healText = "9999" }
    info._foreverStatCache = setmetatable({}, { __index = function() return 9999 end })
    info._foreverStatText = setmetatable({}, { __index = function() return "9999" end })
    local beforeFrames = #env.frames
    assert(load(read(arg[2] or "StatusBars/FluxInfoFrameStats.lua"), "@live-stat-providers", "t", env))()
    check(#env.frames == beforeFrames, "stat providers allocated a frame")
    local update = upvalue(info._FlushPlayerStatRefresh, "UpdateStats")
    local keyText = upvalue(update, "_GetKeyText")
    local function draw(key, compact, prefix)
        local full, short = keyText(key)
        local sink = { _fluxEntryRef = { text = (prefix or "") .. (compact and short or full), keys = { key } } }
        function sink:SetFormattedText(fmt, ...)
            local args = { ... }
            for i, v in ipairs(args) do args[i] = opaqueValues[v] or v end
            self.text = string.format(fmt, table.unpack(args))
        end
        info._RenderCamelotLiveText(sink)
        return sink.text or sink._fluxEntryRef.text, full, sink
    end
    return env, info, draw, function(r, rev) restricted, revision, env.combat = r, rev or 0, r end,
        function() return reads end, update
end

local expected = { spellPower = "1000", spellPowerOnly = "1000", healPower = "700", mastery = "12.00%",
    versatility = "5.00%", spellPenetration = "7", weaponDamage = "100-150 (50-75)", rangedWeaponDamage = "80-120",
    attackPower = "115", rangedAttackPower = "220", armor = "150", dodge = "3.00%", parry = "4.00%", block = "5.00%",
    mp5 = "50", meleeArmorPenetration = "8.00%", rangedArmorPenetration = "8.00%", expertise = "6", defense = "295",
    resilience = "18", speed = "100%", moveSpeed = "100%", health = "3000", power = "2000", weaponSpeed = "2.00 / 3.00",
    rangedWeaponSpeed = "2.00", leech = "9.00%", avoidance = "10.00%", strength = "101", agility = "102", stamina = "103",
    intellect = "104", spirit = "105", itemLevel = "100.0", gearScore = "1000" }
for _, forever in ipairs({ true, false }) do
    local env, info, draw, state, reads, update = setup(forever)
    info.GetCharDB().spellDisplayMode = "both"
    for key in pairs(info.GetStatRegistry()) do
        check(expected[key] or ({ crit = true, meleeCrit = true, rangedCrit = true, haste = true,
            spellHit = true, meleeHit = true, rangedHit = true })[key], "unclassified built-in: " .. key)
    end
    for key, text in pairs(expected) do
        state(false)
        local public = draw(key)
        check(public:find(text, 1, true), key .. " public native total: " .. public)
        check(not public:find("9999", 1, true), key .. " used old snapshot")
        state(true)
        local combat, sample = draw(key)
        check(not combat:find("--", 1, true), key .. " disappeared in combat")
        local beforeReads = reads()
        state(true, 10)
        local proc = draw(key)
        if key ~= "itemLevel" and key ~= "gearScore" then
            check(proc ~= combat, key .. " combat value froze")
            check(reads() > beforeReads, key .. " did not query live")
        end
        state(true)
        check(draw(key) == combat, key .. " did not expire the proc")
        categories[key] = true
    end
    check(draw("attackPower"):find("100 +20 -5", 1, true), "all signed AP components retained")
    check(draw("versatility"):find("1.00% +4.00%", 1, true), "versatility includes live rating and aura bonus")
    check(draw("mp5"):find("10.00 × 5", 1, true), "MP5 has live casting-rate multiplier")
    check(draw("speed"):find("7.00 yd/s", 1, true), "restricted speed keeps meaningful units")
    local compact = draw("spellPower", true, "Dur: 80% / ")
    check(compact:find("1000|r/|cff20ff20700", 1, true), "compact merged spell/heal text was not replaced")
    check(not compact:find("999999", 1, true), "layout sample leaked to renderer")
    if not forever then
        for key, total in pairs({ spellHit = 5, meleeHit = 3, rangedHit = 4 }) do
            state(false)
            check(draw(key):find(string.format("%.2f%%", total), 1, true), "independent Retail hit total " .. key)
            state(true)
            check(draw(key):find(string.format("1.00%% +%.2f%%", total - 1), 1, true), "independent live hit components " .. key)
        end
    end
    -- The real unchanged-geometry return must keep refreshing this new stat too.
    local text, sample, sink = draw("spellPower")
    sink.IsShown = function() return true end
    local pool = upvalue(info._RefreshCamelotLiveText, "linePool")
    local active = upvalue(update, "activeLines")
    pool[1], active[1] = sink, { key = "spellPower", fs = sink, fullText = sample, compactText = sample:gsub(" / ", "/") }
    upvalue(update, "frame", { IsShown = function() return true end, GetWidth = function() return 200 end, GetHeight = function() return 80 end })
    upvalue(update, "activeLineCount", 1); upvalue(update, "_lastLayoutMode", "vertical")
    upvalue(update, "_lastLayoutW", 200); upvalue(update, "_lastLayoutH", 80)
    state(true, 50); update()
    check(sink.text:find("1050", 1, true), "unchanged layout froze spell-power proc")
    -- An unknown dynamic row has no independent API. Only a visible player row
    -- is current; hidden/pet rows and saved numeric/text snapshots are rejected.
    local reg = info.GetStatRegistry()
    reg.custom = { label = "Custom", _dynamic = true, get = function() return 9999 end }
    local shown, unit, current = true, "player", "123%"
    local row = { _FluxInfoStatKey = "custom", IsVisible = function() return shown end,
        GetElementData = function() return { unit = unit } end, Value = { GetText = function() return current end } }
    env.CharacterStatsPaneScrollBox = { IsVisible = function() return shown end,
        ScrollBox = { GetView = function() return { GetFrames = function() return { row } end } end } }
    check(draw("custom"):find("123%", 1, true), "visible native custom source")
    state(true)
    current = env.UnitHealthMax("player")
    check(draw("custom"):find("3000", 1, true), "restricted native custom text reaches sink")
    shown = false; check(draw("custom"):find("--", 1, true), "hidden custom source must not appear live")
    shown, unit = true, "pet"; check(draw("custom"):find("--", 1, true), "pet custom source must not replace player")
    -- Zero/negative values are real; failed native reads must not revive caches.
    env.GetSpellBonusHealing = function() return 0 end
    check(draw("healPower"):find("20ff200|r", 1, true), "zero healing is valid")
    env.GetSpellBonusHealing = function() error("temporarily unavailable") end
    check(draw("healPower"):find("--", 1, true), "failed native read used stale healing")
    env.GetSpellBonusDamage = function(school) return 123 end
    info.GetCharDB().spellDisplayMode = "both"
    if forever then
        local partial = draw("spellPower")
        check(partial:find("123", 1, true) and partial:find("--", 1, true), "available spell damage lost when healing is unavailable")
    end
    -- New native notifications use the existing coalescer and skip hidden or
    -- non-player updates. Verify no extra frame/ticker is created by the module.
    local driver
    for _, frame in ipairs(env.frames) do if frame.events.COMBAT_RATING_UPDATE then driver = frame end end
    local requests = 0
    info.RequestStatRefresh = function() requests = requests + 1 end
    info.GetCharDB().pinnedStats = { rangedWeaponSpeed = true }
    for _, event in ipairs({ "UNIT_ATTACK_POWER", "UNIT_RANGED_ATTACK_POWER", "UNIT_DAMAGE", "UNIT_RANGEDDAMAGE",
        "UNIT_ATTACK_SPEED", "UNIT_MAXHEALTH", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_DEFENSE", "UNIT_RESISTANCES" }) do
        check(driver.events[event], "missing native event " .. event)
        local before = requests
        driver.scripts.OnEvent(driver, event, "target"); check(requests == before, "non-player event leaked")
        driver.scripts.OnEvent(driver, event, "player"); check(requests == before + 1, "player stat event lost")
    end
    driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
    check(requests == 11, "new weapon-speed pin skipped aura refresh")
end
do
    local env, info, draw, state = setup(true)
    state(true)
    env.GetOverrideAPBySpellPower = function() return env.UnitHealthMax("player") end
    check(draw("attackPower"):find("--", 1, true), "unknown restricted AP conversion must not invent base AP total")
    local pending, refreshes = {}, 0
    env.C_Timer.After = function(_, fn) pending[#pending + 1] = fn end
    info._FlushPlayerStatRefresh = function() refreshes = refreshes + 1 end
    for i = 1, 100 do info.RequestStatRefresh() end
    check(#pending == 1 and refreshes == 0, "stat event burst did not coalesce")
    pending[1](); check(refreshes == 1, "coalesced stat refresh lost")
end
do
    local env, info, draw, state = setup(true)
    env.GetOverrideAPBySpellPower = function() return 2 end
    state(false); check(draw("attackPower"):find("1400", 1, true), "AP conversion includes minimum damage/healing")
    state(true, 50); check(draw("attackPower"):find("750 × 2.00", 1, true), "restricted AP conversion stays live")
end
for _, project in ipairs({ 2, 11 }) do
    local env, info = setup(false, project)
    check(info.GetLiveStatText("strength", info.GetStatRegistry().strength) == false, "Classic providers must be preserved")
end
local covered = 0; for _ in pairs(categories) do covered = covered + 1 end
check(read("_FluxUI.toc"):find("StatusBars\\FluxInfoFrameStats.lua", 1, true), "provider module must ship")
print("all info stats: " .. checks .. " checks PASS; " .. covered .. " additional built-in keys; Retail/Forever desktop, native pending")
