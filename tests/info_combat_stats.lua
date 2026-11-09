-- Real info-frame providers and text renderer; opaque tokens model secrets,
-- not the native secure VM. Optional argv[1] supplies a baseline source file.
local function read(path)
    local f = assert(io.open(path)); local text = f:read("*a"); f:close(); return text
end
local fixture = read("CharacterInfo/_tmp_foreverstatssmoke.lua")
fixture = fixture:sub(1, assert(fixture:find("local env, info = Load(true)", 1, true)) - 1)
local loaderEnv = setmetatable({ arg = { [0] = "tests/info_combat_stats.lua" } }, { __index = _G })
if arg[1] then
    loaderEnv.io = setmetatable({ open = function(path, ...)
        if path:find("StatusBars/FluxInfoFrame.lua", 1, true) then path = arg[1] end
        return io.open(path, ...)
    end }, { __index = io })
end
local Load = assert(load(fixture .. "\nreturn Load", "@info-combat-fixture", "t", loaderEnv))()
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function upvalue(fn, name)
    for i = 1, 100 do
        local key, value = debug.getupvalue(fn, i)
        if not key then break end
        if key == name then return value end
    end
    error("missing upvalue " .. name)
end
local function setup(forever)
    local env, info = Load(forever)
    local secrets = {}
    local function secret(value)
        local token = setmetatable({}, {
            __lt = function() error("secret comparison") end,
            __le = function() error("secret comparison") end,
            __add = function() error("secret addition") end,
            __tostring = function() error("secret Lua formatting") end,
        })
        secrets[token] = value
        return token
    end
    env.issecretvalue = function(value) return secrets[value] ~= nil end
    local keyText = upvalue(upvalue(info._FlushPlayerStatRefresh, "UpdateStats"), "_GetKeyText")
    local function text(key)
        local sample = keyText(key)
        local sink = { _fluxEntryRef = { text = sample, keys = { key } } }
        function sink:SetFormattedText(fmt, ...)
            local values = { ... }
            for i, value in ipairs(values) do values[i] = secrets[value] or value end
            self.text = string.format(fmt, table.unpack(values))
        end
        info._RenderCamelotLiveText(sink)
        return sink.text or sample, sample
    end
    return env, info, secret, text
end

for _, forever in ipairs({ true, false }) do
    for _, channel in ipairs({ "melee", "ranged", "spell" }) do
        local env, info, secret, text = setup(forever)
        local values = { melee = 1, ranged = 1, spell = 1 }
        values[channel] = 5
        local restricted, proc = false, 5
        local function value(category)
            local v = category == channel and proc or values[category]
            return restricted and secret(v) or v
        end
        env.GetCritChance = function() return value("melee") end
        env.GetRangedCritChance = function() return value("ranged") end
        env.GetSpellCritChance = function(index)
            if forever then check(index == nil, "Forever spell crit is school-free")
            else check(index >= 2 and index <= 7, "Retail spell school argument") end
            return value("spell")
        end
        -- Deliberately misleading supplemental providers must be ignored.
        env.CSC_InfoFrame_BuildSpellCritData = function() return 1 end
        env.CSC_InfoFrame_GetDisplayMeleeCritPercent = function() return 1 end
        check(text("crit"):find("5.00%%"), "pre-combat total uses native winner")
        restricted, env.combat = true, true
        local previousSample
        for _, current in ipairs({ 5, 8, 5, 0 }) do
            proc = current
            local actual, sample = text("crit")
            check(actual:find(string.format("%.2f%%", current), 1, true), "combat category changed or proc froze")
            if previousSample then check(sample == previousSample, "live number must not alter layout sample") end
            previousSample = sample
        end
        restricted, env.combat, proc = false, false, 5
        values.melee, values.ranged, values.spell = 9, 1, 1
        -- The formerly selected category no longer wins after restrictions lift.
        if channel == "melee" then proc = 9 end
        check(text("crit"):find("9.00%%"), "public maximum must be recomputed")
        for _, frame in ipairs(env.frames) do
            if frame.events.COMBAT_RATING_UPDATE then
                check(frame.events.PLAYER_REGEN_DISABLED and frame.events.PLAYER_REGEN_ENABLED
                    and frame.events.UNIT_SPELL_HASTE, "both clients refresh at combat/haste transitions")
            end
        end
    end
end

for _, channel in ipairs({ "melee", "ranged", "spell" }) do
    local env, info, secret, text = setup(true)
    local restricted, proc = false, 5
    local function value(category, v)
        if category == channel then v = proc end
        return restricted and secret(v) or v
    end
    env.GetMeleeHaste = function() return value("melee", 1) end
    env.UnitSpellHaste = function() return value("spell", 1) end
    env.GetRangedHaste = function() return value("ranged", 1), 2 end
    local total = channel == "ranged" and 7 or 5
    check(text("haste"):find(string.format("%.2f%%", total), 1, true), "public haste includes ammo")
    restricted = true
    for _, current in ipairs({ 5, 8, 5 }) do
        proc = current
        local expected = string.format("%.2f%%", current)
        if channel == "ranged" then expected = expected .. " + 2.00%" end
        check(text("haste"):find(expected, 1, true), "live haste lost its selected channel/ammo")
    end
end

for _, channel in ipairs({ "melee", "offhand", "ranged", "spell" }) do
    local env, info, secret, text = setup(true)
    local restricted, proc = false, 4
    env.GetCombatRatingBonus = function(index) return restricted and secret(1) or 1 end
    for category, api in pairs({ melee = "GetHitModifier", offhand = "GetOffhandHitModifier",
        ranged = "GetRangedHitModifier", spell = "GetSpellHitModifier" }) do
        env[api] = function()
            local v = category == channel and proc or 0
            return restricted and secret(v) or v
        end
    end
    check(text("meleeHit"):find("5.00%%"), "public hit includes rating and modifier")
    restricted = true
    for _, current in ipairs({ 4, 7, 4 }) do
        proc = current
        check(text("meleeHit"):find(string.format("1.00%% + %.2f%%", current), 1, true), "hit changed category or lost a contribution")
    end
end

do
    local env, info, secret, text = setup(false)
    local restricted = false
    env.GetCritChance = function() return 1 end
    env.GetRangedCritChance = function() return 2 end
    env.GetSpellCritChance = function(school)
        local v = school == 4 and 5 or 20
        return restricted and secret(v) or v
    end
    check(text("crit"):find("5.00%%"), "Retail uses the minimum spell school before comparing categories")
    restricted = true
    check(text("crit"):find("5.00%%"), "mixed readable/restricted channels must keep the spell source")
    env.GetSpellCritChance = function() error("temporarily unavailable") end
    info._foreverStatCache = { crit = 99 }
    info._foreverStatText = { crit = "99.0%" }
    check(text("crit"):find("--", 1, true), "missing selected channel must not use lower melee or old cache")
end

do
    local env, info, secret, text = setup(true)
    env.GetCritChance = function() return 1 end
    env.GetRangedCritChance = function() return 2 end
    env.GetSpellCritChance = function() return secret(5) end
    check(text("crit"):find("--", 1, true), "Forever entering with no readable source must not select melee")
    env.GetSpellCritChance = function() return 5 end
    check(text("crit"):find("5.00%%"), "Forever recovers when the full set becomes readable")
    env.GetSpellCritChance = function() return secret(8) end
    check(text("crit"):find("8.00%%"), "Forever mixed-channel live proc")
end

do
    local env, info, secret, text = setup(false)
    env.CSC_InfoFrame_GetDisplayHastePercent = function() return 1 end
    local v = 5
    env.GetHaste = function() return secret(v) end
    for _, current in ipairs({ 5, 8, 5, -2, 0 }) do
        v = current
        check(text("haste"):find(string.format("%.2f%%", current), 1, true), "Retail haste partial provider/frozen/negative/zero")
    end
    env.GetCritChance = function() return secret(5) end
    env.GetRangedCritChance = env.GetCritChance
    env.GetSpellCritChance = env.GetCritChance
    check(text("crit"):find("--", 1, true), "no known category must not invent a current total")
end
print("info combat stats: " .. checks .. " checks PASS (desktop; native secrets/taint/pixels/performance pending)")
