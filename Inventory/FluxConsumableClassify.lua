--[[
    Inventory/FluxConsumableClassify.lua

    Slim consumable restore/kind parser for FluxItemClass + FluxConsumableBest.
    Replaces missing FluxNCItemDetection / FluxItemDetection restore hooks.
]]

FluxConsumableClassify = FluxConsumableClassify or {}
local C = FluxConsumableClassify

local ITEM_CLASS_CONSUMABLE = 0
local SUBCLASS_POTION = 1
local SUBCLASS_FOOD_DRINK = 5 -- retail / modern; Classic food often uses Other
local SUBCLASS_BANDAGE = 7
-- Classic Era Enum can map Food & Drink to 4. Retail subclass 4 is Scroll.
local SUBCLASS_FOOD_DRINK_CLASSIC_ALT = 4

local function SafeNum(v)
    if FluxAPICompat and FluxAPICompat.API and FluxAPICompat.API.SafeGetNumber then
        return FluxAPICompat.API.SafeGetNumber(v) or 0
    end
    return tonumber(v) or 0
end

local function GetMaxHealth()
    local api = FluxAPICompat and FluxAPICompat.API
    if api and api.SafeUnitHealthMax then
        return math.max(1, SafeNum(api.SafeUnitHealthMax("player")))
    end
    return math.max(1, UnitHealthMax("player") or 1)
end

local function GetMaxMana()
    local api = FluxAPICompat and FluxAPICompat.API
    if api and api.SafeUnitPowerMax then
        return math.max(0, SafeNum(api.SafeUnitPowerMax("player", 0)))
    end
    return math.max(0, UnitPowerMax("player", 0) or 0)
end

local function SanitizeTooltipNumber(s)
    if not s then
        return nil
    end
    s = tostring(s):gsub(",", ""):gsub("%s", "")
    return tonumber(s)
end

local function LineHasPercentRatePerSecond(line)
    line = line or ""
    return line:find("every%s+second", 1)
        or line:find("per%s+second", 1)
        or line:find("per%s+sec", 1)
end

local function NewAxis()
    return { mode = nil, flat = 0, percent = 0, perSecond = false, durationSec = 0, effective = 0 }
end

local function MergeAxis(axis, mode, flat, percent, perSecond, durationSec, effective)
    if not effective or effective <= 0 then
        return
    end
    if effective > (axis.effective or 0) then
        axis.mode = mode
        axis.flat = flat or 0
        axis.percent = percent or 0
        axis.perSecond = perSecond and true or false
        axis.durationSec = durationSec or 0
        axis.effective = effective
    end
end

local function NormalizeLine(line)
    return (line or ""):gsub("up%s+to%s+", "")
end

local function LineLooksLikeFoodWater(line)
    line = line or ""
    return line:find("eat", 1, true) or line:find("eating", 1, true)
        or line:find("drink", 1, true) or line:find("drinking", 1, true)
        or line:find("remain seated", 1, true) or line:find("food and drink", 1, true)
end

-- Buffet locale restore keywords: retail / classic_era / classic_anniversary only.
local function BuffetLocaleAllowed()
    local Flux = _G.Flux
    local Client = Flux and Flux.Client
    if not Client then
        return false
    end
    return Client.isRetail or Client.isEra or Client.isAnniversary
end

local BUFFET_LOCALE = {
    deDE = { restores = { "stellt" }, health = { "gesundheit", "leben" }, mana = { "mana" } },
    frFR = { restores = { "rend" }, health = { "vie" }, mana = { "mana" } },
    esES = { restores = { "restaura" }, health = { "salud" }, mana = { "mana" } },
    esMX = { restores = { "restaura" }, health = { "salud" }, mana = { "mana" } },
    ptBR = { restores = { "restaura", "recupera" }, health = { "vida" }, mana = { "mana" } },
    itIT = { restores = { "rigenera" }, health = { "salute" }, mana = { "mana" } },
    ruRU = { restores = { "восстанавливает" }, health = { "здоровья", "здоровье" }, mana = { "маны", "мана" } },
    zhCN = { restores = { "恢复" }, health = { "生命" }, mana = { "法力" } },
    koKR = { restores = { "회복" }, health = { "생명력" }, mana = { "마나" } },
}

local function NormalizeBuffetLocaleText(text)
    if type(text) ~= "string" or text == "" then
        return text
    end
    if not BuffetLocaleAllowed() then
        return text
    end
    local loc = GetLocale and GetLocale() or "enUS"
    if loc == "enUS" or loc == "enGB" then
        return text
    end
    local words = BUFFET_LOCALE[loc]
    if not words then
        return text
    end
    local out = text
    local function replaceWord(src, dst)
        if type(src) ~= "string" then
            return
        end
        out = out:gsub(src, dst)
    end
    if type(words.restores) == "table" then
        for i = 1, #words.restores do
            replaceWord(words.restores[i], "restores")
        end
    end
    if type(words.health) == "table" then
        for i = 1, #words.health do
            replaceWord(words.health[i], "health")
        end
    end
    if type(words.mana) == "table" then
        for i = 1, #words.mana do
            replaceWord(words.mana[i], "mana")
        end
    end
    return out
end

-- Buff pots: "Increases your maximum health by 10%." is not a restore.
local function LineLooksLikeMaxHealthBuff(line)
    line = line or ""
    if line:find("restores", 1, true) then
        return false
    end
    return line:find("increase", 1, true)
        and line:find("maximum", 1, true)
        and line:find("health", 1, true)
end

local function ParseLinePercentAxis(line, unit, maxResource, axis)
    line = NormalizeLine(line)
    if maxResource <= 0 then
        return
    end
    if LineLooksLikeMaxHealthBuff(line) then
        return
    end
    local unitPat = unit
    local pct, dur

    -- Retail mage-table / conjured food: "Restores 100% health ... over 20 sec"
    -- (no "maximum" / "of your" wording).
    pct, dur = line:match("(%d+)%s*%%%s*" .. unitPat .. "[^%n]*over%s+(%d+)%s*sec")
    if pct and dur and not LineHasPercentRatePerSecond(line) then
        local p = tonumber(pct)
        if p then
            MergeAxis(axis, "percent", 0, p, false, tonumber(dur), (p / 100) * maxResource)
        end
    end
    pct = line:match("(%d+)%s*%%%s*" .. unitPat)
    if pct and not LineHasPercentRatePerSecond(line) and not line:match("over%s+%d+")
        and not line:find("maximum", 1, true) and not line:find("of your", 1, true) then
        local p = tonumber(pct)
        if p then
            MergeAxis(axis, "percent", 0, p, false, 0, (p / 100) * maxResource)
        end
    end

    pct, dur = line:match("(%d+)%s*%%[^%n]*maximum%s+" .. unitPat .. "[^%n]*every%s+second[^%n]*over%s+(%d+)%s*sec")
    if pct and dur then
        local p, d = tonumber(pct), tonumber(dur)
        if p and d then
            MergeAxis(axis, "percent_rate", 0, p, true, d, (p / 100) * maxResource * d)
        end
    end
    pct, dur = line:match("(%d+)%s*%%[^%n]*maximum%s+" .. unitPat .. "[^%n]*over%s+(%d+)%s*sec")
    if pct and dur and not LineHasPercentRatePerSecond(line) then
        local p = tonumber(pct)
        if p then
            MergeAxis(axis, "percent", 0, p, false, tonumber(dur), (p / 100) * maxResource)
        end
    end
    pct = line:match("(%d+)%s*%%[^%n]*maximum%s+" .. unitPat)
    if pct and not LineHasPercentRatePerSecond(line) and not line:match("over%s+%d+") then
        local p = tonumber(pct)
        if p then
            MergeAxis(axis, "percent", 0, p, false, 0, (p / 100) * maxResource)
        end
    end

    -- Always try "of your health/mana" percent forms (retail food tooltips).
    pct, dur = line:match("(%d+)%s*%%[^%n]*of%s+your%s+" .. unitPat .. "[^%n]*every%s+second[^%n]*over%s+(%d+)%s*sec")
    if pct and dur then
        local p, d = tonumber(pct), tonumber(dur)
        if p and d then
            MergeAxis(axis, "percent_rate", 0, p, true, d, (p / 100) * maxResource * d)
        end
    end
    pct, dur = line:match("(%d+)%s*%%[^%n]*of%s+your%s+" .. unitPat .. "[^%n]*over%s+(%d+)%s*sec")
    if pct and dur and not LineHasPercentRatePerSecond(line) then
        local p = tonumber(pct)
        if p then
            MergeAxis(axis, "percent", 0, p, false, tonumber(dur), (p / 100) * maxResource)
        end
    end
    pct = line:match("(%d+)%s*%%[^%n]*of%s+your%s+" .. unitPat)
    if pct and not LineHasPercentRatePerSecond(line) and not line:match("over%s+%d+") then
        local p = tonumber(pct)
        if p then
            MergeAxis(axis, "percent", 0, p, false, 0, (p / 100) * maxResource)
        end
    end
end

local function ParseLineComboPercent(line, maxH, maxM, healthAxis, manaAxis)
    line = NormalizeLine(line)
    -- Retail mage-table food: "Restores 100% health and 100% Mana over 20 sec"
    local hp, mp, dur = line:match("(%d+)%s*%%%s*health%s+and%s+(%d+)%s*%%%s*mana[^%n]*over%s+(%d+)%s*sec")
    if hp and mp and dur and not LineHasPercentRatePerSecond(line) then
        local ph, pm = tonumber(hp), tonumber(mp)
        if ph then
            MergeAxis(healthAxis, "percent", 0, ph, false, tonumber(dur), (ph / 100) * maxH)
        end
        if pm then
            MergeAxis(manaAxis, "percent", 0, pm, false, tonumber(dur), (pm / 100) * maxM)
        end
        return
    end
    hp, mp = line:match("(%d+)%s*%%%s*health%s+and%s+(%d+)%s*%%%s*mana")
    if hp and mp and not LineHasPercentRatePerSecond(line) and not line:match("over%s+%d+") then
        local ph, pm = tonumber(hp), tonumber(mp)
        if ph then
            MergeAxis(healthAxis, "percent", 0, ph, false, 0, (ph / 100) * maxH)
        end
        if pm then
            MergeAxis(manaAxis, "percent", 0, pm, false, 0, (pm / 100) * maxM)
        end
        return
    end
    -- Shared percent for both: "N% maximum health and mana"
    if not line:find("health%s+and%s+mana", 1) then
        return
    end
    local pct, sharedDur = line:match("(%d+)%s*%%[^%n]*maximum%s+health%s+and%s+mana[^%n]*over%s+(%d+)%s*sec")
    if pct and sharedDur and not LineHasPercentRatePerSecond(line) then
        local p = tonumber(pct)
        if p then
            MergeAxis(healthAxis, "percent", 0, p, false, tonumber(sharedDur), (p / 100) * maxH)
            MergeAxis(manaAxis, "percent", 0, p, false, tonumber(sharedDur), (p / 100) * maxM)
        end
        return
    end
    pct = line:match("(%d+)%s*%%[^%n]*maximum%s+health%s+and%s+mana")
    if pct and not LineHasPercentRatePerSecond(line) and not line:match("over%s+%d+") then
        local p = tonumber(pct)
        if p then
            MergeAxis(healthAxis, "percent", 0, p, false, 0, (p / 100) * maxH)
            MergeAxis(manaAxis, "percent", 0, p, false, 0, (p / 100) * maxM)
        end
    end
end

local function ParseLineFlatAxis(line, unit, axis)
    line = NormalizeLine(line)
    local amt, dur = line:match("restores?%s+([%d,%.]+)%s+" .. unit .. "%s+over%s+(%d+)%s*sec")
    if amt and dur then
        local n = SanitizeTooltipNumber(amt)
        if n and n > 0 then
            MergeAxis(axis, "flat", n, 0, false, tonumber(dur), n)
        end
    end
    amt, dur = line:match("([%d,%.]+)%s+" .. unit .. "%s+over%s+(%d+)%s*sec")
    if amt and dur and not LineHasPercentRatePerSecond(line) then
        local n = SanitizeTooltipNumber(amt)
        if n and n > 0 then
            MergeAxis(axis, "flat", n, 0, false, tonumber(dur), n)
        end
    end
    amt, dur = line:match("([%d,%.]+)%s+" .. unit .. "[^%n]*every%s+second[^%n]*over%s+(%d+)%s*sec")
    if amt and dur then
        local n, d = SanitizeTooltipNumber(amt), tonumber(dur)
        if n and n > 0 and d then
            MergeAxis(axis, "flat_rate", n, 0, true, d, n * d)
        end
    end
end

local function ParseFlatComboExplicit(text, healthAxis, manaAxis)
    local h, m = text:match("restores?%s+([%d,%.]+)%s+health%s+and%s+([%d,%.]+)%s+mana")
    if not h then
        h, m = text:match("restores?%s+([%d,%.]+)%s+health%s*,%s*([%d,%.]+)%s+mana")
    end
    if not h then
        h, m = text:match("([%d,%.]+)%s+health%s+and%s+([%d,%.]+)%s+mana")
    end
    if h and m then
        local nh, nm = SanitizeTooltipNumber(h), SanitizeTooltipNumber(m)
        if nh and nh > 0 then
            MergeAxis(healthAxis, "flat", nh, 0, false, 0, nh)
        end
        if nm and nm > 0 then
            MergeAxis(manaAxis, "flat", nm, 0, false, 0, nm)
        end
    end
end

local function ParseGenericFlatAmounts(text, healthAxis, manaAxis)
    for amount, unit in text:gmatch("(%d[%d,%.]*)%s*(health|mana)") do
        local n = SanitizeTooltipNumber(amount)
        if n and n > 0 then
            if unit == "health" then
                MergeAxis(healthAxis, "flat", n, 0, false, 0, n)
            else
                MergeAxis(manaAxis, "flat", n, 0, false, 0, n)
            end
        end
    end
end

local function ParseBandageDamage(text, healthAxis)
    local single = text:match("heals%s+(%d[%d,%.]*)%s+damage")
    if single then
        local n = SanitizeTooltipNumber(single)
        if n and n > 0 then
            MergeAxis(healthAxis, "flat", n, 0, false, 0, n)
        end
    end
    local a, b = text:match("([%d,%.]+)%s*to%s*([%d,%.]+)%s*damage")
    if a and b then
        local best = math.max(SanitizeTooltipNumber(a) or 0, SanitizeTooltipNumber(b) or 0)
        if best > 0 then
            MergeAxis(healthAxis, "flat", best, 0, false, 0, best)
        end
    end
end

local function IsNonFoodWaterConsumable(itemID, text, itemName)
    local lname = (itemName or ""):lower()
    if lname:find("bandage", 1, true) or lname:find("potion", 1, true) then
        return true
    end
    if lname:find("healthstone", 1, true) or lname:find("health stone", 1, true) then
        return true
    end
    if lname:find("mana gem", 1, true) or (lname:find("mana", 1, true) and lname:find("gem", 1, true)) then
        return true
    end
    text = text or ""
    if text:find("healthstone", 1, true) or text:find("bandage", 1, true) or text:find("first aid", 1, true) then
        return true
    end
    if text:find("wrap your wounds", 1, true) or text:find("potion", 1, true) then
        return true
    end
    if text:find("user's health", 1, true) or text:find("instantly restores", 1, true) then
        return true
    end
    if itemID then
        local IC = _G.FluxItemClass
        local st = IC and IC.GetStatic and IC.GetStatic(itemID)
        if st and st.classID == ITEM_CLASS_CONSUMABLE then
            local sc = st.subClassID or st.subclassID
            if sc == SUBCLASS_POTION or sc == SUBCLASS_BANDAGE then
                return true
            end
        end
    end
    return false
end

local function IsRetailClient()
    local Client = _G.Flux and _G.Flux.Client
    if Client and Client.isRetail ~= nil then
        return Client.isRetail == true
    end
    return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
end

local function IsFoodDrinkSubclass(subclassID)
    if subclassID == SUBCLASS_FOOD_DRINK then
        return true
    end
    -- Classic Era Enum can map Food & Drink to 4; retail 4 is Scroll.
    return subclassID == SUBCLASS_FOOD_DRINK_CLASSIC_ALT and not IsRetailClient()
end

-- Retail consumable subclass 4 is Scroll. The same id can be Food & Drink on Classic.
local function IsRetailScrollSubclass(subclassID)
    return subclassID == SUBCLASS_FOOD_DRINK_CLASSIC_ALT and IsRetailClient()
end

-- Name fragments and item-type lines. "Rolle der/des" is classic deDE ("Rolle der Intelligenz").
local SCROLL_NAME_NEEDLES = {
    "scroll",
    "schriftrolle",
    "parchemin",
    "pergamino",
    "pergaminho",
    "pergamena",
    "свиток",
    "卷轴",
    "卷軸",
    "두루마리",
}

local SCROLL_TYPE_LINES = {
    scroll = true,
    schriftrolle = true,
    parchemin = true,
    pergamino = true,
    pergaminho = true,
    pergamena = true,
    ["свиток"] = true,
    ["卷轴"] = true,
    ["卷軸"] = true,
    ["두루마리"] = true,
}

local function NameLooksLikeScroll(name)
    local lname = (name or ""):lower()
    if lname == "" then
        return false
    end
    for i = 1, #SCROLL_NAME_NEEDLES do
        if lname:find(SCROLL_NAME_NEEDLES[i], 1, true) then
            return true
        end
    end
    return lname:find("rolle der", 1, true) ~= nil or lname:find("rolle des", 1, true) ~= nil
end

local function TooltipHasScrollTypeLine(text)
    text = (text or ""):lower()
    if text == "" then
        return false
    end
    for line in text:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$") or line
        if SCROLL_TYPE_LINES[line] then
            return true
        end
    end
    return false
end

--- Scrolls can read "Restores N mana over 4 sec" and must not join food/water
--- tiers, the food/water button, or lower-tier junk.
local function LooksLikeScroll(name, text, subclassID)
    if IsRetailScrollSubclass(subclassID) then
        return true
    end
    return NameLooksLikeScroll(name) or TooltipHasScrollTypeLine(text)
end

-- Sit-and-drink duration, not cooldown "N sec". English plus Buffet locales.
local function SafeFind(text, pat)
    if type(text) ~= "string" or type(pat) ~= "string" or pat == "" then
        return nil
    end
    local ok, i = pcall(string.find, text, pat)
    if ok then
        return i
    end
    return nil
end

local function HasRestoreOverTime(text)
    text = text or ""
    if SafeFind(text, "over%s+%d+%s*sec") then
        return true
    end
    -- deDE: "über 30 Sek."
    if SafeFind(text, "über%s+%d+%s*sek") or SafeFind(text, "Über%s+%d+%s*sek") then
        return true
    end
    -- frFR: "pendant 21 sec" (avoid "en N sec" — matches English "when N sec")
    if SafeFind(text, "pendant%s+%d+") then
        return true
    end
    -- esES / esMX / ptBR
    if SafeFind(text, "durante%s+%d+") then
        return true
    end
    -- ruRU
    if SafeFind(text, "в%s+течение") or SafeFind(text, "за%s+%d+%s*сек") then
        return true
    end
    -- zhCN
    if SafeFind(text, "持续%s*%d+%s*秒") or SafeFind(text, "%d+%s*秒内") then
        return true
    end
    -- koKR
    if SafeFind(text, "%d+%s*초%s*동안") or SafeFind(text, "%d+%s*초에%s*걸쳐") then
        return true
    end
    return false
end

local function IsFoodWaterTooltip(text, itemName, subclassID)
    text = text or ""
    if LooksLikeScroll(itemName, text, subclassID) then
        return false
    end
    if IsNonFoodWaterConsumable(nil, text, itemName) then
        return false
    end
    local overTime = HasRestoreOverTime(text)
    local hasEat = text:find("eat", 1, true) or text:find("eating", 1, true)
    local hasDrink = text:find("drink", 1, true) or text:find("drinking", 1, true)
    local hasFoodAndDrink = text:find("food and drink", 1, true)
    local remainSeated = text:find("remain seated", 1, true)
    local hasHealth = text:find("health", 1, true)
    local hasMana = text:find("mana", 1, true)
    -- Retail: "restores X% of your health/mana ... over N sec" without "eat"
    local pctRestore = text:find("%d+%s*%%", 1)
        and (hasHealth or hasMana)
        and overTime
    -- Timed health/mana restore is sit-and-consume even without English eat/drink
    -- (Classic fish: "Restores 28 health over 18 sec", often subclass Other).
    -- Scrolls are rejected above; a 4 sec mana scroll is not a drink.
    if remainSeated or hasFoodAndDrink or pctRestore
        or (overTime and (hasEat or hasDrink or hasHealth or hasMana)) then
        return true
    end
    -- Non-English vendor food/water: Food & Drink subclass + restore duration.
    -- Subclass alone is not enough (instant "Use: Restores Mana." is not a drink).
    return overTime and IsFoodDrinkSubclass(subclassID)
end

local function ParseFoodWaterFallbackNumbers(text, healthAxis, manaAxis)
    if (healthAxis.effective or 0) > 0 or (manaAxis.effective or 0) > 0 then
        return
    end
    if text:find("%%", 1, true) then
        return
    end
    if LineLooksLikeMaxHealthBuff(text) then
        return
    end
    if text:find("health", 1, true) then
        for num in text:gmatch("(%d[%d,%.]*)") do
            local n = SanitizeTooltipNumber(num)
            if n and n > 0 then
                MergeAxis(healthAxis, "flat", n, 0, false, 0, n)
            end
        end
    end
    if text:find("mana", 1, true) then
        for num in text:gmatch("(%d[%d,%.]*)") do
            local n = SanitizeTooltipNumber(num)
            if n and n > 0 then
                MergeAxis(manaAxis, "flat", n, 0, false, 0, n)
            end
        end
    end
end

local function LooksLikeHealthstone(name, text)
    local lname = (name or ""):lower()
    text = text or ""
    return lname:find("healthstone", 1, true) or lname:find("health stone", 1, true)
        or text:find("healthstone", 1, true) or text:find("user's health", 1, true)
end

local function LooksLikeManaGem(name, text)
    local lname = (name or ""):lower()
    text = text or ""
    -- Engineering potion injectors are potions, not mana gems.
    if lname:find("injector", 1, true) or text:find("injector", 1, true) then
        return false
    end
    if lname:find("mana gem", 1, true) then
        return true
    end
    if lname:find("mana", 1, true) and (lname:find("ruby", 1, true) or lname:find("citrine", 1, true)
        or lname:find("jade", 1, true) or lname:find("agate", 1, true)
        or lname:find("emerald", 1, true) or lname:find("sapphire", 1, true)) then
        return true
    end
    return text:find("mana gem", 1, true) or text:find("conjure mana", 1, true)
end

-- Known conjured mana-gem item IDs (best → worst). Classify even before tooltip mana parses.
C.MANA_GEM_IDS = {
    [36799] = true, -- Mana Gem
    [33312] = true, -- Mana Sapphire
    [22044] = true, -- Mana Emerald
    [8008] = true, -- Mana Ruby
    [8007] = true, -- Mana Citrine
    [5513] = true, -- Mana Jade
    [5514] = true, -- Mana Agate
}

function C.IsManaGemItem(itemID)
    itemID = tonumber(itemID)
    return itemID and C.MANA_GEM_IDS[itemID] == true
end

local function LooksLikePotion(name, text, subclassID)
    if subclassID == SUBCLASS_POTION then
        return true
    end
    local lname = (name or ""):lower()
    text = text or ""
    -- Engineering injectors (Healing/Mana Potion Injector) restore like potions.
    return lname:find("potion", 1, true) or text:find("potion", 1, true)
        or lname:find("injector", 1, true) or text:find("injector", 1, true)
        or text:find("instantly restores", 1, true)
end

-- Same needles as Craft RecipeMatchesKindHeuristic. find("heal") also hits health/healing.
local function PotionHealNamed(name)
    local lname = (name or ""):lower()
    return (lname:find("heal", 1, true)
        or lname:find("health", 1, true)
        or lname:find("healing", 1, true)
        or lname:find("rejuvenation", 1, true)) ~= nil
end

local function PotionManaNamed(name)
    return (name or ""):lower():find("mana", 1, true) ~= nil
end

local function PotionHasRestoreVerb(text)
    text = text or ""
    return text:find("restores", 1, true) or text:find("instantly restores", 1, true)
end

local function PotionTooltipHeal(text)
    text = text or ""
    if not PotionHasRestoreVerb(text) then
        return false
    end
    return text:find("health", 1, true) or text:find("rejuvenation", 1, true)
end

local function PotionTooltipMana(text)
    text = text or ""
    return PotionHasRestoreVerb(text) and text:find("mana", 1, true) ~= nil
end

-- Alchemy combat-utility potions must not occupy heal/mana extra-button slots.
local COMBAT_UTILITY_POTION_NEEDLES = {
    "protection",
    "absorb",
    "resistance",
    "invisibility",
    "swiftness",
    "rage",
    "dreamless",
    "free action",
    "invulnerability",
    "stoneshield",
    "swim speed",
    "living action",
    "potion of mysterious",
    "holy protection",
    "increases your maximum",
    "increase your maximum",
    "maximum health by",
    "health regeneration",
}

-- Locale-stable school protection potions (Classic / TBC). Name needles miss non-English.
local PROTECTION_POTION_IDS = {
    [6051] = true, [13457] = true, [22845] = true, -- Holy / Greater Holy / Major Holy
    [6048] = true, [6049] = true, [6050] = true, [6052] = true,
    [13456] = true, [13458] = true, [13459] = true, [13460] = true, [13461] = true,
    [22841] = true, [22842] = true, [22844] = true, [22846] = true, [22847] = true,
}

local function IsCombatUtilityPotion(name, text, itemID)
    itemID = tonumber(itemID)
    if itemID and PROTECTION_POTION_IDS[itemID] then
        return true
    end
    local s = ((name or "") .. "\n" .. (text or "")):lower()
    for i = 1, #COMBAT_UTILITY_POTION_NEEDLES do
        if s:find(COMBAT_UTILITY_POTION_NEEDLES[i], 1, true) then
            return true
        end
    end
    return false
end

function C.IsCombatUtilityPotion(name, text, itemID)
    return IsCombatUtilityPotion(name, text, itemID)
end

function C.IsHealingPotionName(name, text)
    return not IsCombatUtilityPotion(name, text) and PotionHealNamed(name)
end

function C.IsManaPotionName(name, text)
    return not IsCombatUtilityPotion(name, text) and PotionManaNamed(name)
end

local function LooksLikeBandage(name, text)
    local lname = (name or ""):lower()
    text = text or ""
    return lname:find("bandage", 1, true) or text:find("bandage", 1, true)
        or text:find("first aid", 1, true) or text:find("wrap your wounds", 1, true)
end

local function AllowRestoreFallbackNumbers(text, name, subclassID, itemID)
    if LooksLikePotion(name, text, subclassID)
        or LooksLikeBandage(name, text) or subclassID == SUBCLASS_BANDAGE
        or LooksLikeHealthstone(name, text)
        or LooksLikeManaGem(name, text)
        or C.IsManaGemItem(itemID) then
        return true
    end
    -- Real sit-and-drink food/water with an oddly formatted restore number.
    return HasRestoreOverTime(text)
        or text:find("remain seated", 1, true)
        or text:find("food and drink", 1, true)
        or text:find("while drinking", 1, true)
        or text:find("while eating", 1, true)
end

--- Parse tooltip text into restore axes (effective already scaled for %).
function C.ParseFoodWaterRestore(text, itemLink, itemName)
    text = NormalizeBuffetLocaleText((text or ""):lower())
    local healthAxis, manaAxis = NewAxis(), NewAxis()
    local isConjured, isBandage, isWellFed = false, false, false

    if text:find("well fed", 1, true) then
        isWellFed = true
    end
    local nameFromLink = type(itemLink) == "string" and itemLink:match("%[(.-)%]")
    local name = itemName or nameFromLink
    local lname = name and name:lower() or ""
    if lname:find("conjured", 1, true) or text:find("conjured", 1, true) then
        isConjured = true
    end
    if lname:find("bandage", 1, true) or text:find("bandage", 1, true) or text:find("first aid", 1, true) then
        isBandage = true
    end
    if text:find("wrap your wounds", 1, true) or text:find("protective cloth", 1, true) then
        isBandage = true
    end
    if text:find("while channeling", 1, true) and text:find("heal", 1, true) and text:find("damage", 1, true) then
        isBandage = true
    end

    local maxH, maxM = GetMaxHealth(), GetMaxMana()
    ParseFlatComboExplicit(text, healthAxis, manaAxis)
    ParseGenericFlatAmounts(text, healthAxis, manaAxis)
    -- Absorb "N to N … damage" must not become potion health.
    if isBandage then
        ParseBandageDamage(text, healthAxis)
    end
    for line in text:gmatch("[^\n]+") do
        ParseLineComboPercent(line, maxH, maxM, healthAxis, manaAxis)
        ParseLinePercentAxis(line, "health", maxH, healthAxis)
        ParseLinePercentAxis(line, "mana", maxM, manaAxis)
        ParseLineFlatAxis(line, "health", healthAxis)
        ParseLineFlatAxis(line, "mana", manaAxis)
    end

    local subclassID = nil
    local itemID = type(itemLink) == "string" and tonumber(itemLink:match("item:(%d+)"))
    do
        local IC = _G.FluxItemClass
        local st = itemID and IC and IC.GetStatic and IC.GetStatic(itemID)
        subclassID = st and (st.subClassID or st.subclassID)
    end

    -- Combat consumes still need digit fallback when "N health/mana" is split.
    -- Instant "Use: Restores Mana." + required-level digits must not invent water.
    if AllowRestoreFallbackNumbers(text, name, subclassID, itemID) then
        ParseFoodWaterFallbackNumbers(text, healthAxis, manaAxis)
    end

    local exclude = IsNonFoodWaterConsumable(itemID, text, name)
        or LooksLikeScroll(name, text, subclassID)
    local isFoodWater = not exclude and IsFoodWaterTooltip(text, name, subclassID)

    return {
        effectiveH = healthAxis.effective or 0,
        effectiveM = manaAxis.effective or 0,
        health = healthAxis,
        mana = manaAxis,
        isFoodWater = isFoodWater,
        isConjured = isConjured,
        isBandage = isBandage,
        excludeFromFoodWater = exclude,
        isWellFed = isWellFed,
        subclassID = subclassID,
    }
end

--- Unified kind classification for FluxConsumableBest.
--- Returns { kind, health, mana, effective, isPercent, isConjured, wellFed, bandage } or nil.
local classifyCache = {} -- [itemID] = result|false|{ _pending = true }
local pendingRetries = {} -- [itemID] = n
local PARSE_BUDGET = 24
local parseUsed = 0
local MAX_PENDING_RETRIES = 4

function C.ResetParseBudget(max)
    parseUsed = 0
    if type(max) == "number" and max > 0 then
        PARSE_BUDGET = max
    else
        PARSE_BUDGET = 24
    end
end

function C.InvalidateCache(itemID)
    itemID = tonumber(itemID)
    if itemID then
        classifyCache[itemID] = nil
        pendingRetries[itemID] = nil
    else
        wipe(classifyCache)
        wipe(pendingRetries)
    end
end

function C.IsPending(itemID)
    itemID = tonumber(itemID)
    local c = itemID and classifyCache[itemID]
    return type(c) == "table" and c._pending == true
end

--- Soft-clear a stuck pending flag without permanently rejecting the item.
--- (Hard false-cache broke CombatGrid detect after cold-load tooltip retries.)
function C.ForceReject(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return
    end
    local c = classifyCache[itemID]
    if type(c) == "table" and c._pending then
        classifyCache[itemID] = nil
    end
    pendingRetries[itemID] = nil
end

local function KindFromParsed(itemID, itemName, text, parsed, st)
    if type(parsed) ~= "table" then
        return nil
    end
    local h, m = 0, 0
    if type(parsed.health) == "number" then
        h = parsed.health
    elseif type(parsed.health) == "table" then
        h = tonumber(parsed.health.effective) or 0
    end
    if type(parsed.mana) == "number" then
        m = parsed.mana
    elseif type(parsed.mana) == "table" then
        m = tonumber(parsed.mana.effective) or 0
    end
    h = tonumber(parsed.effectiveH) or h
    m = tonumber(parsed.effectiveM) or m
    -- FluxItemClass.GetRestore shape mapped in
    if parsed.restoreHealth ~= nil then
        h = tonumber(parsed.restoreHealth) or h
    end
    if parsed.restoreMana ~= nil then
        m = tonumber(parsed.restoreMana) or m
    end

    local isPercent = (type(parsed.health) == "table" and parsed.health.mode
            and tostring(parsed.health.mode):find("percent", 1, true))
        or (type(parsed.mana) == "table" and parsed.mana.mode
            and tostring(parsed.mana.mode):find("percent", 1, true))
        or (parsed.isPercent == true)

    local subclassID = st and (st.subClassID or st.subclassID) or parsed.subclassID
    local isPotion = subclassID == SUBCLASS_POTION or LooksLikePotion(itemName, text, subclassID)
    local isBandage = parsed.isBandage or parsed.bandage
        or subclassID == SUBCLASS_BANDAGE
        or LooksLikeBandage(itemName, text)

    if LooksLikeHealthstone(itemName, text) then
        if h > 0 then
            return {
                kind = "healthstone", health = h, mana = 0, effective = h,
                isPercent = isPercent and true or false, isConjured = true, wellFed = false,
            }
        end
        -- Heal not parsed yet: leave nil so Classify can pending / tier-fallback.
        return nil
    end
    if C.IsManaGemItem(itemID) or LooksLikeManaGem(itemName, text) then
        local mana = m > 0 and m or 1
        return {
            kind = "managem", health = 0, mana = mana, effective = mana,
            isPercent = isPercent and true or false, isConjured = true, wellFed = false,
        }
    end
    if isBandage then
        local heal = h > 0 and h or 1
        return {
            kind = "bandage", health = heal, mana = 0, effective = heal,
            isPercent = false, isConjured = parsed.isConjured == true or parsed.conjured == true,
            wellFed = false, bandage = true,
        }
    end
    -- Potions: require a heal/mana name or restore line. Unmatched Alchemy
    -- (Holy Protection, Rage, Swiftness, ...) must not default to healPotion.
    -- Name-only still classifies Minor Healing Potion before tooltip numbers load.
    if isPotion then
        if IsCombatUtilityPotion(itemName, text, itemID) then
            return nil
        end
        local healNamed = PotionHealNamed(itemName)
        local manaNamed = PotionManaNamed(itemName)
        local tooltipHeal = PotionTooltipHeal(text)
        local tooltipMana = PotionTooltipMana(text)
        local conjured = parsed.isConjured == true or parsed.conjured == true
        local function FinishPot(kind, health, mana, effective, namedOnly)
            return {
                kind = kind, health = health, mana = mana, effective = effective,
                isPercent = (not namedOnly) and isPercent and true or false,
                isConjured = conjured,
                wellFed = false,
            }
        end
        -- Dual restore: Rejuvenation, Wildvine, Cavedweller's Delight.
        -- Buff pots with scraped numbers must not become healPotion.
        if h > 0 and m > 0 then
            local healSignal = healNamed or tooltipHeal
            local manaSignal = manaNamed or tooltipMana
            if healSignal or manaSignal then
                if h >= m and healSignal then
                    return FinishPot("healPotion", h, m, h, false)
                end
                if manaSignal then
                    return FinishPot("manaPotion", h, m, m, false)
                end
                if healSignal then
                    return FinishPot("healPotion", h, m, h, false)
                end
            end
        end
        if h > 0 and (healNamed or tooltipHeal) then
            return FinishPot("healPotion", h, m, h, false)
        end
        if m > 0 and (manaNamed or tooltipMana) then
            return FinishPot("manaPotion", h, m, m, false)
        end
        if healNamed and not manaNamed then
            return FinishPot("healPotion", 1, 0, 1, true)
        end
        if manaNamed and not healNamed then
            return FinishPot("manaPotion", 0, 1, 1, true)
        end
        if healNamed and manaNamed then
            return FinishPot("healPotion", 1, 0, 1, true)
        end
        return nil
    end

    local wellFed = parsed.wellFed == true or parsed.isWellFed == true
    local exclude = parsed.excludeFromFoodWater == true
    local lname = (itemName or ""):lower()
    local healthPct = type(parsed.health) == "table" and (tonumber(parsed.health.percent) or 0) or 0
    local manaPct = type(parsed.mana) == "table" and (tonumber(parsed.mana.percent) or 0) or 0
    local function FinishKind(rec)
        if not rec then
            return nil
        end
        rec.restoreHealthPct = healthPct > 0 and healthPct or nil
        rec.restoreManaPct = manaPct > 0 and manaPct or nil
        if rec.kind == "water" or rec.kind == "manaPotion" or rec.kind == "managem" then
            rec.restorePct = rec.restoreManaPct
        else
            rec.restorePct = rec.restoreHealthPct or rec.restoreManaPct
        end
        rec.restoreRaw = rec.effective
        return rec
    end
    local isCombo = (h > 0 and m > 0) or (healthPct > 0 and manaPct > 0)
    -- Mage refreshment names: "Conjured Mana Strudel/Pie/..." are always HP+mana food.
    local looksConjuredManaFood = lname:find("conjured", 1, true)
        and lname:find("mana", 1, true)
        and not lname:find("gem", 1, true)
        and not LooksLikeManaGem(itemName, text)
    if looksConjuredManaFood then
        isCombo = true
        if h <= 0 and healthPct <= 0 then
            h = math.max(1, GetMaxHealth())
        end
        if m <= 0 and manaPct <= 0 then
            m = math.max(0, GetMaxMana())
        end
    end

    local isFoodWater = parsed.isFoodWater == true
        or looksConjuredManaFood
        or (not exclude and not isPotion and not isBandage and not wellFed and (h > 0 or m > 0)
            and IsFoodWaterTooltip(text or "", itemName, subclassID))

    if isFoodWater and not wellFed and not exclude then
        if h > 0 or healthPct > 0 or looksConjuredManaFood then
            if h <= 0 and healthPct > 0 then
                h = (healthPct / 100) * GetMaxHealth()
            end
            if m <= 0 and manaPct > 0 then
                m = (manaPct / 100) * GetMaxMana()
            end
            if h <= 0 and isCombo then
                h = math.max(1, GetMaxHealth())
            end
            return FinishKind({
                kind = "food", health = h, mana = m, effective = h > 0 and h or m,
                isPercent = isPercent and true or false,
                isConjured = parsed.isConjured == true or parsed.conjured == true or lname:find("conjured", 1, true) ~= nil,
                isCombo = isCombo and true or false,
                wellFed = false,
            })
        end
        if m > 0 then
            return FinishKind({
                kind = "water", health = 0, mana = m, effective = m,
                isPercent = isPercent and true or false,
                isConjured = parsed.isConjured == true or parsed.conjured == true or lname:find("conjured", 1, true) ~= nil,
                wellFed = false,
            })
        end
    end
    return nil
end

function C.Classify(itemID, itemLink, tooltipText, itemName)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    local cached = classifyCache[itemID]
    if cached ~= nil then
        if cached == false then
            return nil
        end
        if type(cached) == "table" and not cached._pending then
            return cached
        end
        -- _pending: fall through and retry
    end

    local IC = _G.FluxItemClass
    local st = IC and IC.GetStatic and IC.GetStatic(itemID)
    if st and st.classID ~= nil and st.classID ~= ITEM_CLASS_CONSUMABLE then
        classifyCache[itemID] = false
        return nil
    end
    itemLink = itemLink or (IC and IC.GetLink and IC.GetLink(itemID)) or ("item:" .. itemID)
    itemName = itemName or (IC and IC.GetName and IC.GetName(itemID))

    -- Primary SoT: FluxItemClass tooltip text + ParseFoodWaterRestore (Inventory).
    local text = tooltipText
    if (not text or text == "") and IC and IC.GetTooltipText then
        if parseUsed >= PARSE_BUDGET then
            classifyCache[itemID] = { _pending = true }
            if IC.RequestLoad then
                IC.RequestLoad(itemID)
            end
            return nil
        end
        parseUsed = parseUsed + 1
        text = IC.GetTooltipText(itemID, itemLink)
    end

    -- Fast path: reuse ready restore record axes when tooltip unavailable this frame.
    if (not text or text == "") and IC and IC.GetRestore then
        local restore = IC.GetRestore(itemID, itemLink)
        if restore and restore.ready and ((restore.health or 0) > 0 or (restore.mana or 0) > 0
            or restore.bandage or restore.isFoodWater) then
            local parsed = {
                effectiveH = restore.health or 0,
                effectiveM = restore.mana or 0,
                health = restore.health or 0,
                mana = restore.mana or 0,
                isFoodWater = restore.isFoodWater == true,
                isConjured = restore.conjured == true,
                isBandage = restore.bandage == true,
                excludeFromFoodWater = restore.excludeFromFoodWater == true,
                isWellFed = restore.wellFed == true,
                conjured = restore.conjured == true,
                bandage = restore.bandage == true,
                subclassID = st and (st.subClassID or st.subclassID),
            }
            local result = KindFromParsed(itemID, itemName, (itemName or ""):lower(), parsed, st)
            if result then
                classifyCache[itemID] = result
                return result
            end
        end
        if IC.RequestLoad then
            IC.RequestLoad(itemID)
        end
        return nil -- do not cache false; retry when tooltip loads
    end

    if not text or text == "" then
        if IC and IC.RequestLoad then
            IC.RequestLoad(itemID)
        end
        return nil
    end

    text = text:lower()
    local ok, parsed = pcall(C.ParseFoodWaterRestore, text, itemLink, itemName)
    if not ok or type(parsed) ~= "table" then
        parsed = {
            effectiveH = 0,
            effectiveM = 0,
            health = 0,
            mana = 0,
            isFoodWater = false,
            isConjured = false,
            isBandage = false,
            excludeFromFoodWater = false,
            isWellFed = false,
            subclassID = st and (st.subClassID or st.subclassID),
        }
    end
    local result = KindFromParsed(itemID, itemName, text, parsed, st)
    if result then
        classifyCache[itemID] = result
        pendingRetries[itemID] = nil
        return result
    end

    -- Incomplete tooltips must not permanently reject. Mage-table loot and cold login
    -- often yield a short/partial tooltip before restore lines exist; caching false
    -- stuck the food button until /reload. Food & Drink subclass still retries even
    -- when the current snippet is not yet sit-and-drink (restore line loads later).
    local loaded = not IC or not IC.IsLoaded or IC.IsLoaded(itemID)
    local subclassID = st and (st.subClassID or st.subclassID)
    local lname = (itemName or ""):lower()
    local looksHS = LooksLikeHealthstone(itemName, text)
    local looksCombat = LooksLikePotion(itemName, text, subclassID)
        or LooksLikeBandage(itemName, text)
        or LooksLikeManaGem(itemName, text)
        or C.IsManaGemItem(itemID)
        or subclassID == SUBCLASS_POTION
        or subclassID == SUBCLASS_BANDAGE
    local looksFoodDrink = IsFoodDrinkSubclass(subclassID)
        or (lname:find("conjured", 1, true) ~= nil)
        or IsFoodWaterTooltip(text, itemName, subclassID)
        or looksHS
        or looksCombat
    local textTooShort = #text < 48
    local Best = _G.FluxConsumableBest
    local loginScan = Best and Best.IsLoginScanActive and Best.IsLoginScanActive()
    local classID = st and st.classID
    local looksConsumable = classID == nil or classID == ITEM_CLASS_CONSUMABLE
    local keepPending = (not loaded) or looksFoodDrink or textTooShort or looksHS or looksCombat
        or (loginScan and looksConsumable)
    local retries = pendingRetries[itemID] or 0
    if keepPending and (retries < MAX_PENDING_RETRIES or loginScan) then
        if retries < MAX_PENDING_RETRIES then
            pendingRetries[itemID] = retries + 1
        end
        classifyCache[itemID] = { _pending = true }
        if IC and IC.RequestLoad then
            IC.RequestLoad(itemID)
        end
        return nil
    end
    pendingRetries[itemID] = nil

    -- Named healthstone with no heal line after retries: still classify via create-rank.
    if looksHS then
        local Score = _G.FluxConsumableBest and _G.FluxConsumableBest.Score
        local rank = Score and Score.HealthstoneRank and Score.HealthstoneRank(itemID) or 0
        local eff = rank > 0 and (rank * 100) or 1
        local hs = {
            kind = "healthstone",
            health = eff,
            mana = 0,
            effective = eff,
            isPercent = false,
            isConjured = true,
            wellFed = false,
            hsRank = rank > 0 and rank or nil,
        }
        classifyCache[itemID] = hs
        return hs
    end

    if LooksLikeManaGem(itemName, text) or C.IsManaGemItem(itemID) then
        local gem = {
            kind = "managem",
            health = 0,
            mana = 1,
            effective = 1,
            isPercent = false,
            isConjured = true,
            wellFed = false,
        }
        classifyCache[itemID] = gem
        return gem
    end
    if LooksLikeBandage(itemName, text) or subclassID == SUBCLASS_BANDAGE then
        local band = {
            kind = "bandage",
            health = 1,
            mana = 0,
            effective = 1,
            isPercent = false,
            isConjured = false,
            wellFed = false,
            bandage = true,
        }
        classifyCache[itemID] = band
        return band
    end
    if LooksLikePotion(itemName, text, subclassID) or subclassID == SUBCLASS_POTION then
        if not IsCombatUtilityPotion(itemName, text, itemID) then
            local healNamed = PotionHealNamed(lname)
            local manaNamed = PotionManaNamed(lname)
            local pot
            if healNamed and not manaNamed then
                pot = {
                    kind = "healPotion", health = 1, mana = 0, effective = 1,
                    isPercent = false, isConjured = false, wellFed = false,
                }
            elseif manaNamed and not healNamed then
                pot = {
                    kind = "manaPotion", health = 0, mana = 1, effective = 1,
                    isPercent = false, isConjured = false, wellFed = false,
                }
            elseif healNamed and manaNamed then
                pot = {
                    kind = "healPotion", health = 1, mana = 0, effective = 1,
                    isPercent = false, isConjured = false, wellFed = false,
                }
            end
            if pot then
                classifyCache[itemID] = pot
                return pot
            end
        end
    end

    -- Confirmed non-match after full tooltip: cache negative.
    classifyCache[itemID] = false
    return nil
end

function C.ResolveCombatTierAxes(itemID, itemLink)
    local cls = C.Classify(itemID, itemLink)
    if not cls then
        return 0, 0, 0
    end
    local heal, mana, bandage = 0, 0, 0
    if cls.kind == "healPotion" then
        heal = cls.health or 0
    elseif cls.kind == "manaPotion" then
        mana = cls.mana or 0
    elseif cls.kind == "bandage" then
        bandage = cls.health or 0
    end
    return heal, mana, bandage
end

-- Soft shims for FluxItemClass (legacy global names).
FluxNCItemDetection = FluxNCItemDetection or {}
FluxNCItemDetection.ParseFoodWaterRestore = function(...)
    return C.ParseFoodWaterRestore(...)
end

--- Legacy: true if item tooltip grants Well Fed (buff food).
FluxNCItemDetection.ItemGrantsWellFed = function(itemIdOrLink)
    if not itemIdOrLink then return false end
    local IC = _G.FluxItemClass
    local itemID = tonumber(itemIdOrLink)
    if not itemID and type(itemIdOrLink) == "string" then
        itemID = tonumber(itemIdOrLink:match("item:(%d+)"))
    end
    if itemID and IC and IC.GetRestore then
        local restore = IC.GetRestore(itemID, type(itemIdOrLink) == "string" and itemIdOrLink or nil)
        if restore and restore.ready then
            return restore.wellFed == true
        end
    end
    if not IC or not IC.GetTooltipText then
        return false
    end
    local link = type(itemIdOrLink) == "string" and itemIdOrLink
        or (itemID and IC.GetLink and IC.GetLink(itemID))
        or (itemID and ("item:" .. tostring(itemID)))
    if not link then return false end
    local text = IC.GetTooltipText(itemID, link)
    if not text then return false end
    local name = itemID and IC.GetName and IC.GetName(itemID) or nil
    local parsed = C.ParseFoodWaterRestore(text, link, name)
    return parsed and parsed.isWellFed == true
end

FluxItemDetection = FluxItemDetection or {}
FluxItemDetection.ResolveCombatTierAxes = function(...)
    return C.ResolveCombatTierAxes(...)
end

_G.FluxConsumableClassify = C
return C
