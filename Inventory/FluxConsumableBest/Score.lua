--[[
    Inventory/FluxConsumableBest/Score.lua

    Effective restore vs max HP/mana and ranking ladder.
    Usability gate: level + IsUsableItem + tooltip Requires (skill / First Aid).
]]

FluxConsumableBest = FluxConsumableBest or {}
local Best = FluxConsumableBest
Best.Score = Best.Score or {}
local Score = Best.Score

local usableCache = {} -- [itemID] = { level = n, ok = bool }

-- Healthstone ranks best→worst (Classic/TBC/WotLK + Improved Healthstone talent variants).
-- Higher Score.HealthstoneRank = better. Used by Bridge ladder + IsBetter.
Score.HEALTHSTONE_TIER = {
    -- Fel (best)
    { id = 36894 }, { id = 36893 }, { id = 36892 },
    -- Demonic
    { id = 36891 }, { id = 36890 }, { id = 36889 },
    -- Master
    { id = 22105 }, { id = 22104 }, { id = 22103 },
    -- Major
    { id = 19013 }, { id = 19012 }, { id = 9421 },
    -- Greater
    { id = 19011 }, { id = 19010 }, { id = 5510 },
    -- Healthstone
    { id = 19009 }, { id = 19008 }, { id = 5509 },
    -- Lesser
    { id = 19007 }, { id = 19006 }, { id = 5511 },
    -- Minor (also retail single Healthstone id 5512)
    { id = 19005 }, { id = 19004 }, { id = 5512 },
}

-- Rank: Fel=8 … Minor=1 (talent variants share rank with base).
Score.HEALTHSTONE_RANK = {
    [36894] = 8, [36893] = 8, [36892] = 8,
    [36891] = 7, [36890] = 7, [36889] = 7,
    [22105] = 6, [22104] = 6, [22103] = 6,
    [19013] = 5, [19012] = 5, [9421] = 5,
    [19011] = 4, [19010] = 4, [5510] = 4,
    [19009] = 3, [19008] = 3, [5509] = 3,
    [19007] = 2, [19006] = 2, [5511] = 2,
    [19005] = 1, [19004] = 1, [5512] = 1,
}

function Score.HealthstoneRank(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    return Score.HEALTHSTONE_RANK[itemID] or 0
end

local function SafeNum(v)
    local api = FluxAPICompat and FluxAPICompat.API
    if api and api.SafeGetNumber then
        return api.SafeGetNumber(v) or 0
    end
    return tonumber(v) or 0
end

function Score.GetPools()
    local api = FluxAPICompat and FluxAPICompat.API
    local maxHP = 1
    local maxMana = 0
    if api and api.SafeUnitHealthMax then
        maxHP = math.max(1, SafeNum(api.SafeUnitHealthMax("player")))
    else
        maxHP = math.max(1, UnitHealthMax("player") or 1)
    end
    if Best.IsManaKindRelevant("water") then
        if api and api.SafeUnitPowerMax then
            maxMana = math.max(0, SafeNum(api.SafeUnitPowerMax("player", 0)))
        else
            maxMana = math.max(0, UnitPowerMax("player", 0) or 0)
        end
    end
    return maxHP, maxMana
end

--- Recompute effective restore for a classify result against current pools.
function Score.EffectiveFromClassify(cls, maxHP, maxMana)
    if not cls then
        return 0
    end
    maxHP = maxHP or select(1, Score.GetPools())
    maxMana = maxMana or select(2, Score.GetPools())
    local kind = cls.kind
    local useMana = Best.IsManaKind(kind)
    local pool = useMana and maxMana or maxHP
    if cls.isPercent and (cls.restorePct or 0) > 0 and pool > 0 then
        return (cls.restorePct / 100) * pool
    end
    if cls.isPercent and pool > 0 then
        local raw = cls.effective or 0
        if raw > 0 then
            return raw
        end
    end
    return cls.effective or (useMana and (cls.mana or 0) or (cls.health or 0)) or 0
end

function Score.InvalidateUsableCache(itemID)
    itemID = tonumber(itemID)
    if itemID then
        usableCache[itemID] = nil
    else
        wipe(usableCache)
    end
end

local function PlayerLevel()
    return UnitLevel("player") or 1
end

local function PlayerDeadOrTaxi()
    return (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))
        or (UnitOnTaxi and UnitOnTaxi("player"))
end

local function GetMinLevel(itemID)
    local IC = _G.FluxItemClass
    local info = IC and IC.GetInfo and IC.GetInfo(itemID)
    if info and info.minLevel ~= nil then
        return tonumber(info.minLevel) or 0, info.name ~= nil
    end
    if GetItemInfo then
        local name, _, _, _, reqLevel = GetItemInfo(itemID)
        if name then
            return tonumber(reqLevel) or 0, true
        end
    end
    return 0, false
end

local function ColorLooksRed(color)
    if not color then
        return false
    end
    if RED_FONT_COLOR and color.IsRGBEqualTo then
        local ok, eq = pcall(color.IsRGBEqualTo, color, RED_FONT_COLOR)
        if ok and eq then
            return true
        end
    end
    local r, g, b = color.r, color.g, color.b
    if type(r) ~= "number" then
        return false
    end
    return r > 0.9 and (g or 0) < 0.35 and (b or 0) < 0.35
end

--- Locale-proof: red RestrictedLevel / Skill / Class / Faction tooltip lines.
local function TooltipRestrictionRed(itemID)
    itemID = tonumber(itemID)
    if not itemID or not C_TooltipInfo then
        return false
    end
    local data
    if C_TooltipInfo.GetItemByID then
        local ok, result = pcall(C_TooltipInfo.GetItemByID, itemID)
        if ok then
            data = result
        end
    end
    if (not data or not data.lines) and C_TooltipInfo.GetHyperlink then
        local IC = _G.FluxItemClass
        local link = (IC and IC.GetLink and IC.GetLink(itemID)) or ("item:" .. itemID)
        local ok, result = pcall(C_TooltipInfo.GetHyperlink, link)
        if ok then
            data = result
        end
    end
    local lines = data and data.lines
    if not lines then
        return false
    end
    local lineTypes = Enum and Enum.TooltipDataLineType
    if not lineTypes then
        return false
    end
    for i = 1, #lines do
        local line = lines[i]
        if line and TooltipUtil and TooltipUtil.SurfaceArgs then
            pcall(TooltipUtil.SurfaceArgs, line)
        end
        if line then
            local typ = line.type
            if typ == lineTypes.RestrictedRaceClass
                or typ == lineTypes.RestrictedLevel
                or typ == lineTypes.RestrictedSkill
                or typ == lineTypes.RestrictedFaction then
                if ColorLooksRed(line.leftColor) then
                    return true
                end
            end
        end
    end
    return false
end

local function ProfessionRank(needles)
    local Flux = _G.Flux
    local Prof = Flux and Flux.Inventory and Flux.Inventory.Professions
    if not Prof then
        local inv = _G.FluxInv
        Prof = inv and inv.Professions
    end
    if Prof and Prof.GetProfessionRank then
        return tonumber(Prof.GetProfessionRank(needles)) or 0
    end
    return 0
end

--- Parse tooltip for level / profession skill / class gates the player fails.
--- Inconclusive (no tooltip) → false; do not guess.
local function TooltipBlocksUse(itemID, playerLevel)
    if TooltipRestrictionRed(itemID) then
        return true
    end
    local IC = _G.FluxItemClass
    local text
    if IC and IC.GetTooltipText then
        local link = IC.GetLink and IC.GetLink(itemID) or ("item:" .. itemID)
        text = IC.GetTooltipText(itemID, link)
    end
    if not text or text == "" then
        return false -- inconclusive
    end
    text = text:lower()
    local reqLevel = text:match("requires%s*:?%s*level%s*(%d+)")
        or text:match("requires%s+level%s+(%d+)")
        or text:match("level%s+(%d+)%s+required")
    if reqLevel then
        local n = tonumber(reqLevel)
        if n and n > playerLevel then
            return true
        end
    end
    -- "Requires First Aid (225)" / "Requires Cooking (1)" vs live profession rank.
    for skillName, req in text:gmatch("requires%s+([%a][%a%s]-)%s*%(?%s*(%d+)%s*%)?") do
        skillName = skillName:gsub("^%s+", ""):gsub("%s+$", "")
        if skillName ~= "" and skillName ~= "level" and not skillName:find("level", 1, true) then
            local n = tonumber(req)
            if n and ProfessionRank({ skillName }) < n then
                return true
            end
        end
    end
    return false
end

local function OwnedCount(itemID)
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.GetCount then
        return api.GetCount(itemID, { bags = true, bank = false, warband = false }) or 0
    end
    local inv = _G.FluxInv
    if inv then
        if inv.Bags and inv.Bags.GetCount then
            return inv.Bags.GetCount(itemID) or 0
        end
        if inv.GetCount then
            return inv.GetCount(itemID, { bags = true, bank = false }) or 0
        end
    end
    return 0
end

--- True when required level is known and the player is below it.
--- False when item data is not loaded yet (do not scrub persist refs).
function Score.IsBelowRequiredLevel(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local reqLevel, loaded = GetMinLevel(itemID)
    if not loaded then
        return false
    end
    return reqLevel > 0 and PlayerLevel() < reqLevel
end

--- True when we know the player cannot use this item (level / skill / class).
--- False when usable OR when item data is not loaded yet (do not scrub refs).
--- Do not trust IsUsableItem==false here: cold login often reports false for
--- owned food/pots and that used to delete last-session persist refs.
function Score.IsKnownUnusable(itemID, kind)
    itemID = tonumber(itemID)
    if not itemID then
        return true
    end
    if Score.IsBelowRequiredLevel(itemID) then
        return true
    end
    local _, loaded = GetMinLevel(itemID)
    if not loaded then
        return false
    end
    if PlayerDeadOrTaxi() then
        return false
    end
    return TooltipBlocksUse(itemID, PlayerLevel())
end

--- True when this ID must not win Best / grid bind / live owned ladder.
--- Unloaded item data still competes. Only permanent gates (level / skill / class).
--- Never raw IsUsableItem — it is false in combat for food/water and would
--- drop a still-owned stack to the Extra-button placeholder.
function Score.IsBlockedForBest(itemID, kind)
    itemID = tonumber(itemID)
    if not itemID then
        return true
    end
    if Score.IsKnownUnusable(itemID, kind) then
        return true
    end
    -- Persist/latch can keep a previous healPotion ID after classify rejects it
    -- (Holy Protection, Mysterious Tenacity). Re-validate combat potion kinds.
    if kind == "healPotion" or kind == "manaPotion" then
        local C = _G.FluxConsumableClassify
        if C then
            local IC = _G.FluxItemClass
            local name = (IC and IC.GetName and IC.GetName(itemID)) or ""
            if C.IsCombatUtilityPotion and C.IsCombatUtilityPotion(name, "", itemID) then
                return true
            end
            if C.Classify then
                local cls = C.Classify(itemID)
                if type(cls) == "table" and cls.kind and cls.kind ~= kind then
                    return true
                end
                if not cls and C.IsPending and not C.IsPending(itemID) then
                    return true
                end
            end
        end
    end
    return false
end

--- Vendor scan: reject only on known level/skill gates.
--- Do not use IsUsableItem for merchant-only IDs (often false when not owned).
function Score.IsUsableForVendor(itemID, kind)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local lvl = PlayerLevel()
    local reqLevel, loaded = GetMinLevel(itemID)
    if not loaded then
        local IC = _G.FluxItemClass
        if IC and IC.RequestLoad then
            IC.RequestLoad(itemID)
        end
        return true
    end
    if reqLevel > 0 and lvl < reqLevel then
        return false
    end
    -- If the player owns the item, honor full usable checks (First Aid / skill).
    if OwnedCount(itemID) > 0 then
        return Score.IsUsable(itemID, kind)
    end
    return true
end

--- True when the player can use this consumable (level + skill / First Aid).
--- Unknown / unloaded item data → false (exclude from best / tiers until known).
function Score.IsUsable(itemID, kind)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local lvl = PlayerLevel()
    local cached = usableCache[itemID]
    if cached and cached.level == lvl then
        return cached.ok
    end

    if Score.IsKnownUnusable(itemID, kind) then
        usableCache[itemID] = { level = lvl, ok = false }
        return false
    end

    local reqLevel, loaded = GetMinLevel(itemID)
    if not loaded then
        local IC = _G.FluxItemClass
        if IC and IC.RequestLoad then
            IC.RequestLoad(itemID)
        end
        -- Not verified yet — exclude from best/tier; do not cache (retry when loaded).
        return false
    end

    -- Dead / taxi: IsUsableItem lies for all items; trust level only.
    if not PlayerDeadOrTaxi() then
        local usable, notEnoughMana
        if FluxIsItemUsable then
            usable, notEnoughMana = FluxIsItemUsable(itemID)
        elseif C_Item and C_Item.IsUsableItem then
            usable, notEnoughMana = C_Item.IsUsableItem(itemID)
        elseif IsUsableItem then
            usable, notEnoughMana = IsUsableItem(itemID)
        end
        if usable == true or notEnoughMana then
            usableCache[itemID] = { level = lvl, ok = true }
            return true
        end
        if usable == false then
            -- Combat / eating / login: API is situational. Do not cache.
            return false
        end
        -- API nil: refine via tooltip Requires lines (bandages / skill).
        if TooltipBlocksUse(itemID, lvl) then
            usableCache[itemID] = { level = lvl, ok = false }
            return false
        end
        -- Inconclusive API: do not cache true (retry when tooltip/API settle).
        return true
    end

    usableCache[itemID] = { level = lvl, ok = true }
    return true
end

--- Item max stack size for Best tie-breaks (Injector 20 vs Super Mana 5).
function Score.GetMaxStack(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    if C_Item and C_Item.GetItemMaxStackSizeByID then
        local ok, n = pcall(C_Item.GetItemMaxStackSizeByID, itemID)
        if ok and type(n) == "number" and n > 0 then
            return n
        end
    end
    local IC = _G.FluxItemClass
    if IC and IC.GetStackSize then
        local n = tonumber(IC.GetStackSize(itemID))
        if n and n > 0 then
            return n
        end
    end
    local Reg = _G.FluxRestockList
    if Reg and Reg.GetItemMaxStack then
        local n = tonumber(Reg.GetItemMaxStack(itemID))
        if n and n > 0 then
            return n
        end
    end
    return 0
end

local function CandIsCombo(cand)
    if not cand then
        return false
    end
    if cand.isCombo == true then
        return true
    end
    return (tonumber(cand.mana) or 0) > 0 and (tonumber(cand.health) or 0) > 0
end

--- Food button tier (conjured always beats combo / vendor food):
---   4 = conjured pure (HP only)
---   3 = conjured combo (refreshment)
---   2 = non-conjured combo
---   1 = normal non-conjured food
function Score.FoodTier(cand)
    if not cand then
        return 0
    end
    local isCombo = CandIsCombo(cand)
    if cand.isConjured then
        if isCombo then
            return 3
        end
        return 4
    end
    if isCombo then
        return 2
    end
    return 1
end

--- Water button tier (conjured water always beats combo / vendor drinks):
---   4 = conjured water
---   3 = conjured combo
---   2 = normal combo
---   1 = normal water
function Score.WaterDrinkTier(cand)
    if not cand then
        return 0
    end
    local isCombo = CandIsCombo(cand)
    if cand.isConjured then
        if isCombo then
            return 3
        end
        return 4
    end
    if isCombo then
        return 2
    end
    return 1
end

--- Compare two candidates. Returns true if a is strictly better than b.
--- Food: conjured-pure > conjured-combo > combo > vendor, then higher heal.
--- Water drinks (allowComboDrinks): conjured water > conjured combo > combo > vendor, then mana.
--- Other: higher effective → prefer conjured → larger maxStack → lower price → lower itemID.
--- preferConjuredKinds may be bool, or opts table { preferConjured=, allowComboDrinks= }.
function Score.IsBetter(a, b, preferConjuredKinds)
    if not a then
        return false
    end
    if not b then
        return true
    end
    local allowComboDrinks = false
    if type(preferConjuredKinds) == "table" then
        allowComboDrinks = preferConjuredKinds.allowComboDrinks == true
        if preferConjuredKinds.preferConjured ~= nil then
            preferConjuredKinds = preferConjuredKinds.preferConjured
        else
            preferConjuredKinds = true
        end
    end
    local aKind = a.kind
    local bKind = b.kind
    local bothFood = (aKind == "food" or not aKind) and (bKind == "food" or not bKind)
        and (aKind == "food" or bKind == "food")
    local bothDrink = allowComboDrinks
        and (aKind == "water" or aKind == "food" or not aKind)
        and (bKind == "water" or bKind == "food" or not bKind)
        and (aKind == "water" or bKind == "water" or CandIsCombo(a) or CandIsCombo(b))
    local bothWater = (aKind == "water") and (bKind == "water")
    -- Healthstone: explicit create-rank before heal / itemID (Classic IDs are not heal-ordered).
    local bothHS = (aKind == "healthstone" and bKind == "healthstone")
        or ((aKind == "healthstone" or bKind == "healthstone")
            and (aKind == "healthstone" or not aKind)
            and (bKind == "healthstone" or not bKind))
    if bothHS then
        local ar = tonumber(a.hsRank) or Score.HealthstoneRank(a.itemID)
        local br = tonumber(b.hsRank) or Score.HealthstoneRank(b.itemID)
        if ar ~= br and (ar > 0 or br > 0) then
            return ar > br
        end
    end
    -- Food/water: conjured (pure first) always outranks combo and non-conjured,
    -- even when the vendor/combo restore number is higher.
    if bothDrink then
        local at, bt = Score.WaterDrinkTier(a), Score.WaterDrinkTier(b)
        if at ~= bt then
            return at > bt
        end
    elseif bothFood and not allowComboDrinks then
        local at, bt = Score.FoodTier(a), Score.FoodTier(b)
        if at ~= bt then
            return at > bt
        end
    elseif bothWater then
        local at, bt = Score.WaterDrinkTier(a), Score.WaterDrinkTier(b)
        if at ~= bt then
            return at > bt
        end
    end
    local ae, be = a.effective or 0, b.effective or 0
    if bothDrink then
        ae = tonumber(a.mana) or ae
        be = tonumber(b.mana) or be
    end
    if ae ~= be then
        return ae > be
    end
    -- Equal effective: prefer percent restore (conjured table food) over weaker-looking flat.
    local apct, bpct = a.isPercent and true or false, b.isPercent and true or false
    if apct ~= bpct then
        return apct
    end
    preferConjuredKinds = preferConjuredKinds ~= false
    if preferConjuredKinds then
        local ac, bc = a.isConjured and true or false, b.isConjured and true or false
        if ac ~= bc then
            return ac
        end
        if bothFood and not allowComboDrinks then
            local aCombo = CandIsCombo(a)
            local bCombo = CandIsCombo(b)
            if aCombo ~= bCombo then
                return not aCombo
            end
        end
    end
    local am = tonumber(a.maxStack)
    if not am or am <= 0 then
        am = Score.GetMaxStack(a.itemID)
    end
    local bm = tonumber(b.maxStack)
    if not bm or bm <= 0 then
        bm = Score.GetMaxStack(b.itemID)
    end
    if am ~= bm then
        return am > bm
    end
    local ap, bp = tonumber(a.price) or math.huge, tonumber(b.price) or math.huge
    if ap ~= bp then
        return ap < bp
    end
    -- Known healthstones: prefer higher itemID (Improved variants), never lower-ID Classic trap.
    if bothHS then
        local ar = Score.HealthstoneRank(a.itemID)
        local br = Score.HealthstoneRank(b.itemID)
        if ar > 0 or br > 0 then
            return (tonumber(a.itemID) or 0) > (tonumber(b.itemID) or 0)
        end
    end
    return (tonumber(a.itemID) or 0) < (tonumber(b.itemID) or 0)
end

_G.FluxConsumableBest = Best
return Score
