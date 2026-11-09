-- Live stat providers for Retail/Forever. Reuse the info frame's existing native
-- text sink: restricted arguments never enter Lua formatting or layout metrics.
local Info = FluxInfoFrame
if not Info then return end
local unpackArgs = unpack or table.unpack
local schoolColors = { [2] = "ffff99", [3] = "ff8000", [4] = "33ff33",
    [5] = "66ccff", [6] = "cc66ff", [7] = "99ccff" }
local spellSchool, spellColor, movementMode
local apOverride, apSchool

local function opaque(value)
    return (issecretvalue and issecretvalue(value))
        or (canaccessvalue and not canaccessvalue(value))
end
local function number(value)
    return opaque(value) or type(value) == "number"
end
local function result(ok, ...)
    if ok then return ... end
end
local function read(name, ...)
    local fn = _G[name]
    if type(fn) ~= "function" then return end
    return result(pcall(fn, ...))
end
local function firstNumber(a, b)
    if number(a) then return a end
    if number(b) then return b end
end
local function visibleText(key)
    local function take(row)
        if not row or row._FluxInfoStatKey ~= key or not row.IsVisible or not row:IsVisible() then return end
        local data = row.GetElementData and row:GetElementData()
        if data and (opaque(data) or (canaccesstable and not canaccesstable(data))) then return end
        local unit = data and data.unit or row.unit
        if opaque(unit) or (unit ~= nil and unit ~= "player") then return end
        local value = row.Value
        if not value or not value.GetText then return end
        local text = value:GetText()
        if opaque(text) or (type(text) == "string" and text ~= "") then return text end
    end
    local root = _G.CharacterStatsPaneScrollBox
    if root and root.IsVisible and root:IsVisible() then
        local box = root.ScrollBox
        local view = box and box.GetView and box:GetView()
        local rows = view and view.GetFrames and view:GetFrames()
        if type(rows) == "table" then
            for _, row in ipairs(rows) do local value = take(row); if opaque(value) or type(value) == "string" then return value end end
        end
    end
    root = _G.CharacterStatsPane
    if root and root.IsVisible and root:IsVisible() then
        local pool = root.statsFramePool
        if pool and pool.EnumerateActive then
            for row in pool:EnumerateActive() do local value = take(row); if opaque(value) or type(value) == "string" then return value end end
        end
    end
end

-- Every item has an ordinary measurement sample and separately held arguments.
local function display(label, fmt, sample, ...)
    local args, restricted = { ... }, false
    for i = 1, select("#", ...) do
        local value = args[i]
        if opaque(value) then restricted = true
        elseif type(value) ~= "number" and type(value) ~= "string" then return end
    end
    local format = label .. ": " .. fmt
    if not restricted then
        local text = string.format(format, unpackArgs(args))
        return { text = text, compact = text }
    end
    sample = label .. ": " .. sample
    return { text = sample, compact = sample, live = { format = format, sample = sample, args = args } }
end
local function scalar(label, fmt, value, color)
    if not number(value) then return end
    color = color or "ffffff"
    local suffix = fmt:find("%%", 1, true) and "%" or ""
    return display(label, "|cff" .. color .. fmt .. "|r", "|cff" .. color .. "999999.99" .. suffix .. "|r", value)
end
local function sum(label, fmt, ...)
    local args, total, restricted = { ... }, 0, false
    for i = 1, select("#", ...) do
        local value = args[i]
        if not number(value) then return end
        if opaque(value) then restricted = true else total = total + value end
    end
    if not restricted then return scalar(label, fmt, total) end
    local formats, samples = {}, {}
    for i = 1, #args do
        formats[i] = i == 1 and fmt or (fmt:gsub("%%", "%%+", 1))
        samples[i] = i == 1 and "999999.99" or "+999999.99"
    end
    return display(label, "|cffffffff" .. table.concat(formats, " ") .. "|r",
        "|cffffffff" .. table.concat(samples, " ") .. "|r", unpackArgs(args))
end

local function spellDamage()
    local best, selected, ties, restricted = nil, nil, 0, false
    for school = 2, 7 do
        local value = read("GetSpellBonusDamage", school)
        if opaque(value) or not number(value) then restricted = true
        elseif best == nil or value > best then best, selected, ties = value, school, 1
        elseif value == best then ties = ties + 1 end
    end
    if not restricted then
        spellSchool, spellColor = selected, ties == 1 and schoolColors[selected] or "ffffff"
        return best, spellColor
    end
    if spellSchool then return read("GetSpellBonusDamage", spellSchool), spellColor end
end
local function spellLine(key)
    local damage, color = spellDamage()
    if key == "spellPowerOnly" then return scalar("S.P.", "%d", damage, color) end
    local heal = read("GetSpellBonusHealing")
    local mode = Info.GetCharDB().spellDisplayMode
    local classicLine = Info._UseClassicSpellPowerLine()
    if classicLine and mode == "heal" then return scalar("Heal", "%d", heal, "20ff20") end
    if (classicLine and mode == "both") or (not classicLine and number(heal) and (opaque(heal) or heal > 0)) then
        local item
        if number(damage) and number(heal) then
            item = display("Spell", "|cff" .. (color or "ffffff") .. "%d|r / |cff20ff20%d|r",
                "|cff" .. (color or "ffffff") .. "999999|r / |cff20ff20999999|r", damage, heal)
        elseif number(damage) then
            item = display("Spell", "|cff" .. (color or "ffffff") .. "%d|r / |cff888888--|r",
                "|cff" .. (color or "ffffff") .. "999999|r / |cff888888--|r", damage)
        elseif number(heal) then
            item = display("Spell", "|cff888888--|r / |cff20ff20%d|r",
                "|cff888888--|r / |cff20ff20999999|r", heal)
        end
        if item then
            item.compact = item.text:gsub(" / ", "/")
            if item.live then
                item.live.compactSample = item.compact
                item.live.compactFormat = item.live.format:gsub(" / ", "/")
            end
        end
        return item
    end
    return scalar(classicLine and "S.P." or "Spell", "%d", damage, color)
end

local providers = {}
providers.spellPower = function() return spellLine("spellPower") end
providers.spellPowerOnly = function() return spellLine("spellPowerOnly") end
providers.healPower = function() return scalar("Heal", "%d", read("GetSpellBonusHealing"), "20ff20") end
local direct = { mastery = "GetMasteryEffect", dodge = "GetDodgeChance", parry = "GetParryChance",
    block = "GetBlockChance", expertise = "GetExpertise", spellPenetration = "GetSpellPenetration",
    meleeArmorPenetration = "GetArmorPenetration", rangedArmorPenetration = "GetArmorPenetration",
    leech = "GetLifesteal", avoidance = "GetAvoidance" }
for key, api in pairs(direct) do
    providers[key] = function(reg) return scalar(reg.label, reg.fmt, (read(api))) end
end
providers.versatility = function(reg)
    local index = _G.CR_VERSATILITY_DAMAGE_DONE
    if type(index) ~= "number" then return end
    return sum(reg.label, "%.2f%%", read("GetCombatRatingBonus", index), read("GetVersatilityBonus", index))
end
local function attackPower(reg, api)
    local override = read("GetOverrideAPBySpellPower")
    if type(GetOverrideAPBySpellPower) == "function" and not number(override) then return end
    if opaque(override) and apOverride == nil then return end
    if number(override) and not opaque(override) then apOverride = override > 0 end
    if apOverride then
        local lowest, channel, restricted
        for school = 2, 8 do
            local value
            if school == 8 then value = read("GetSpellBonusHealing") else value = read("GetSpellBonusDamage", school) end
            if not number(value) or opaque(value) then restricted = true
            elseif lowest == nil or value < lowest then lowest, channel = value, school end
        end
        if not restricted then apSchool = channel
        elseif apSchool == 8 then lowest = read("GetSpellBonusHealing")
        elseif apSchool then lowest = read("GetSpellBonusDamage", apSchool) else lowest = nil end
        if not number(lowest) or not number(override) then return end
        if not opaque(lowest) and not opaque(override) then return scalar(reg.label, "%d", lowest * override) end
        return display(reg.label, "|cffffffff%.0f × %.2f|r", "|cffffffff999999 × 999.99|r", lowest, override)
    end
    local base, positive, negative = read(api, "player")
    -- Negative buffs are already signed; subtracting them inflated the old AP.
    return sum(reg.label, "%d", base, positive, negative)
end
providers.attackPower = function(reg) return attackPower(reg, "UnitAttackPower") end
providers.rangedAttackPower = function(reg) return attackPower(reg, "UnitRangedAttackPower") end
providers.armor = function(reg)
    local base, effective = read("UnitArmor", "player")
    return scalar(reg.label, "%d", firstNumber(effective, base))
end
providers.health = function(reg) return scalar(reg.label, "%.0f", read("UnitHealthMax", "player")) end
providers.power = function(reg) return scalar(reg.label, "%.0f", read("UnitPowerMax", "player")) end
for index, key in ipairs({ "strength", "agility", "stamina", "intellect", "spirit" }) do
    providers[key] = function(reg)
        local base, effective = read("UnitStat", "player", index)
        return scalar(reg.label, "%d", firstNumber(effective, base))
    end
end
providers.weaponDamage = function(reg)
    local low, high, offLow, offHigh = read("UnitDamage", "player")
    if not number(low) or not number(high) then return end
    if not opaque(low) then low = math.floor(low) end
    if not opaque(high) then high = math.floor(high) end
    if number(offLow) and number(offHigh) and (opaque(offLow) or opaque(offHigh) or offLow > 0 or offHigh > 0) then
        if not opaque(offLow) then offLow = math.floor(offLow) end
        if not opaque(offHigh) then offHigh = math.floor(offHigh) end
        return display(reg.label, "|cffffffff%.0f-%.0f (%.0f-%.0f)|r", "|cffffffff999999-999999 (999999-999999)|r", low, high, offLow, offHigh)
    end
    return display(reg.label, "|cffffffff%.0f-%.0f|r", "|cffffffff999999-999999|r", low, high)
end
providers.rangedWeaponDamage = function(reg)
    local _, low, high = read("UnitRangedDamage", "player")
    if not number(low) or not number(high) then return end
    if not opaque(low) then low = math.floor(low) end
    if not opaque(high) then high = math.floor(high) end
    return display(reg.label, "|cffffffff%.0f-%.0f|r", "|cffffffff999999-999999|r", low, high)
end
providers.weaponSpeed = function(reg)
    local main, off = read("UnitAttackSpeed", "player")
    if number(off) and (opaque(off) or off > 0) then return display(reg.label, "|cffffffff%.2f / %.2f|r", "|cffffffff99.99 / 99.99|r", main, off) end
    return scalar(reg.label, "%.2f", main)
end
providers.rangedWeaponSpeed = function(reg) return scalar(reg.label, "%.2f", (read("UnitRangedDamage", "player"))) end
providers.mp5 = function(reg)
    local base, casting = read("GetManaRegen")
    local value = firstNumber(casting, base)
    if not number(value) then return end
    if opaque(value) then return display(reg.label, "|cffffffff%.2f × 5|r", "|cffffffff99999.99 × 5|r", value) end
    return scalar(reg.label, "%.0f", value * 5)
end
providers.speed = function(reg)
    local _, run, flight, swim = read("GetUnitSpeed", "player")
    local swimming, flying = read("IsSwimming", "player"), read("IsFlying", "player")
    if not opaque(swimming) and not opaque(flying) then movementMode = swimming and "swim" or flying and "flight" or "run" end
    local value = movementMode == "swim" and swim or movementMode == "flight" and flight or run
    if not number(value) then return end
    if opaque(value) then return display(reg.label, "|cffffffff%.2f yd/s|r", "|cffffffff999.99 yd/s|r", value) end
    return scalar(reg.label, "%.0f%%", value / (_G.BASE_MOVEMENT_SPEED or 7) * 100)
end
providers.moveSpeed = providers.speed
providers.defense = function(reg)
    if type(UnitDefenseSkill) == "function" then
        local base, modifier = read("UnitDefenseSkill", "player")
        return sum(reg.label, "%d", base, modifier)
    end
    return scalar(reg.label, "%d", firstNumber(read("GetDefenseSkill"), read("UnitDefense", "player")))
end
providers.resilience = function(reg)
    local index = _G.CR_RESILIENCE_CRIT_TAKEN or _G.COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN
    if type(index) == "number" then return scalar(reg.label, "%d", read("GetCombatRating", index)) end
end
-- Native shared hit keeps the prior category policy. Independent Retail pins
-- must not use melee modifiers for spell/ranged hit or silently omit ratings.
for key, spec in pairs({ spellHit = { "CR_HIT_SPELL", "GetSpellHitModifier" },
    meleeHit = { "CR_HIT_MELEE", "GetHitModifier" }, rangedHit = { "CR_HIT_RANGED", "GetRangedHitModifier" } }) do
    providers[key] = function(reg)
        local index = _G[spec[1]]
        if type(index) ~= "number" then return end
        return sum(reg.label, "%.2f%%", read("GetCombatRatingBonus", index), read(spec[2]))
    end
end

function Info.GetLiveStatText(key, reg)
    if not (Info._IsCamelotClient() or Info._IsRetailStatClient()) then return false end
    if Info._IsCamelotClient() and (key == "meleeHit" or key == "rangedHit" or key == "spellHit") then return false end
    local provider = providers[key]
    if not provider and not reg._dynamic then return false end
    local item = provider and provider(reg)
    if item and item.live and (key == "attackPower" or key == "rangedAttackPower"
        or key == "versatility" or key == "defense" or key == "mp5" or key == "speed" or key == "moveSpeed") then
        local value = visibleText(key)
        if opaque(value) or type(value) == "string" then item = display(reg.label, "%s", "999999.99%", value) end
    end
    if not item then
        local value = visibleText(key)
        if opaque(value) or type(value) == "string" then
            item = display(reg.label, "%s", "999999.99%", value)
        end
    end
    if not item then
        local text = (reg.label or key) .. ": |cff888888--|r"
        return true, text, text
    end
    return true, item.text, item.compact, item.live
end
