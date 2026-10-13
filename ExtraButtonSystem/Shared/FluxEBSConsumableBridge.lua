--[[
    ExtraButtonSystem/Shared/FluxEBSConsumableBridge.lua

    Inventory-backed helpers for combat / food-water ExtraButtons.
    Owned-only best selection, lower-tier ladders, create/conjure spells.
]]

FluxEBSConsumableBridge = FluxEBSConsumableBridge or {}
local Bridge = FluxEBSConsumableBridge

-- Mana Gem tiers (best → worst). hasCharges: TBC/WotLK+ (3 charges); Vanilla = single-use.
local MANA_GEM_TIER = {
    { id = 36799, name = "Mana Gem", spell = "Conjure Mana Gem", hasCharges = true },
    { id = 33312, name = "Mana Sapphire", spell = "Conjure Mana Sapphire", hasCharges = true },
    { id = 22044, name = "Mana Emerald", spell = "Conjure Mana Emerald", hasCharges = true },
    { id = 8008, name = "Mana Ruby", spell = "Conjure Mana Ruby", hasCharges = false },
    { id = 8007, name = "Mana Citrine", spell = "Conjure Mana Citrine", hasCharges = false },
    { id = 5513, name = "Mana Jade", spell = "Conjure Mana Jade", hasCharges = false },
    { id = 5514, name = "Mana Agate", spell = "Conjure Mana Agate", hasCharges = false },
}

local MANA_GEM_CHARGE_BASED_IDS = {
    [36799] = true,
    [33312] = true,
    [22044] = true,
}

local MANA_GEM_SPELL_RANK = {
    ["conjure mana gem"] = 100,
    ["conjure mana sapphire"] = 90,
    ["conjure mana emerald"] = 80,
    ["conjure mana ruby"] = 70,
    ["conjure mana citrine"] = 60,
    ["conjure mana jade"] = 50,
    ["conjure mana agate"] = 40,
}

local function Best()
    return _G.FluxConsumableBest
end

local function Inv()
    return _G.FluxInv
end

local function Spells()
    local inv = Inv()
    return inv and inv.Spells
end

local function BagCount(itemID, includeCharges)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local inv = Inv()
    if not inv then
        return 0
    end
    -- FluxInv is the only SoT for Extra Buttons (no Blizzard GetItemCount bypass).
    if includeCharges then
        if inv.GetLiveCount then
            return inv.GetLiveCount(itemID, { charges = true, includeBank = false }) or 0
        end
        if inv.Index and inv.Index.GetLiveCount then
            return inv.Index.GetLiveCount(itemID, { charges = true, includeBank = false }) or 0
        end
        return 0
    end
    if inv.Bags and inv.Bags.GetCount then
        return inv.Bags.GetCount(itemID) or 0
    end
    if inv.GetCount then
        return inv.GetCount(itemID, { bags = true, charges = false }) or 0
    end
    return 0
end

function Bridge.BagCount(itemID, opts)
    opts = opts or {}
    return BagCount(itemID, opts.charges == true)
end

function Bridge.IsManaGemChargeBased(itemID)
    itemID = tonumber(itemID)
    return itemID and MANA_GEM_CHARGE_BASED_IDS[itemID] == true
end

--- True when bags hold a charge-based gem OR the mage knows a charge-based conjure spell.
--- In that mode Vanilla single-use gems (Ruby and below) must not be used/conjured.
function Bridge.ShouldUseChargeBasedManaGemOnly()
    local _, class = UnitClass("player")
    if class ~= "MAGE" then
        return false
    end
    for i = 1, #MANA_GEM_TIER do
        local gem = MANA_GEM_TIER[i]
        if gem.hasCharges and BagCount(gem.id, true) > 0 then
            return true
        end
    end
    local sp = Spells()
    for i = 1, #MANA_GEM_TIER do
        local gem = MANA_GEM_TIER[i]
        if gem.hasCharges and gem.spell then
            if sp and sp.IsKnownByName then
                local known = sp.IsKnownByName(gem.spell)
                if known then
                    return true
                end
            elseif IsSpellKnown and GetSpellInfo then
                local spellID = select(7, GetSpellInfo(gem.spell))
                if spellID and IsSpellKnown(spellID) then
                    return true
                end
            end
        end
    end
    return false
end

local function IsManaGemSpellKnown(spellName)
    if not spellName or spellName == "" then
        return false, nil
    end
    local sp = Spells()
    if sp and sp.IsKnownByName then
        local known, spellID = sp.IsKnownByName(spellName)
        if known then
            return true, spellID
        end
        return false, nil
    end
    if IsSpellKnown and GetSpellInfo then
        local spellID = select(7, GetSpellInfo(spellName))
        if spellID and IsSpellKnown(spellID) then
            return true, spellID
        end
    end
    return false, nil
end

--- Base mana cost for a conjure spell (0 = free). Uses C_Spell.GetSpellPowerCost when available.
local function GetSpellBaseManaCost(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end
    local getCost = (C_Spell and C_Spell.GetSpellPowerCost) or GetSpellPowerCost
    if not getCost then
        return nil
    end
    local ok, costTable = pcall(getCost, spellID)
    if not ok then
        return nil
    end
    if type(costTable) ~= "table" then
        -- No cost entries → free.
        return 0
    end
    local mana = 0
    local EnumPower = Enum and Enum.PowerType
    local MANA = (EnumPower and EnumPower.Mana) or 0
    for _, entry in pairs(costTable) do
        if type(entry) == "table" then
            local ptype = entry.type or entry.powerType
            if ptype == nil or ptype == MANA then
                local c = tonumber(entry.cost) or tonumber(entry.minCost) or 0
                if c > mana then
                    mana = c
                end
            end
        end
    end
    return mana
end

--- Best known mana-gem conjure (charge tiers only when in charge mode).
local function GetBestKnownManaGemConjure()
    local chargeOnly = Bridge.ShouldUseChargeBasedManaGemOnly()
    for i = 1, #MANA_GEM_TIER do
        local gem = MANA_GEM_TIER[i]
        if (not chargeOnly or gem.hasCharges) and gem.spell then
            local known, spellID = IsManaGemSpellKnown(gem.spell)
            if known then
                return spellID, gem.spell, gem
            end
        end
    end
    return nil, nil, nil
end

--- True when the best known conjure has base mana cost 0 (free re-conjure).
function Bridge.IsManaGemConjureFree()
    local spellID = GetBestKnownManaGemConjure()
    if not spellID then
        return false
    end
    local cost = GetSpellBaseManaCost(spellID)
    return cost ~= nil and cost <= 0
end

--- Charge gems or free conjure: keep item bind / conjure best only (no Vanilla missing-tier ladder).
function Bridge.ShouldStickyManaGemItem()
    return Bridge.ShouldUseChargeBasedManaGemOnly() or Bridge.IsManaGemConjureFree()
end

--- Item ID for the best known conjure product (for sticky empty bind).
function Bridge.GetPreferredManaGemItemID()
    local _, _, gem = GetBestKnownManaGemConjure()
    return gem and gem.id or nil
end

--- Next mana-gem conjure spell (V9 parity + free-conjure).
--- Charge mode or free (0 mana): best known conjure only.
--- Vanilla paid: first known conjure for a gem NOT currently in bags; else any known conjure.
function Bridge.GetNextManaGemConjureSpell()
    if Bridge.ShouldUseChargeBasedManaGemOnly() or Bridge.IsManaGemConjureFree() then
        local spellID, spellName = GetBestKnownManaGemConjure()
        return spellID, spellName
    end

    for i = 1, #MANA_GEM_TIER do
        local gem = MANA_GEM_TIER[i]
        if BagCount(gem.id, false) == 0 then
            local known, spellID = IsManaGemSpellKnown(gem.spell)
            if known then
                return spellID, gem.spell
            end
        end
    end

    for i = 1, #MANA_GEM_TIER do
        local gem = MANA_GEM_TIER[i]
        local known, spellID = IsManaGemSpellKnown(gem.spell)
        if known then
            return spellID, gem.spell
        end
    end

    return nil, nil
end

--- Best owned consumable for button binding (never vendor/create stubs).
--- Always prefers a live bag ladder over Best runtime so login sticky/partial
--- scans cannot pin a weaker bandage/potion on the button.
--- Ownership is FluxInv-only (BagCount); Persist refs bind only if FluxInv confirms count > 0.
--- O(1) best owned healthstone from the hard-coded create-rank table.
local function GetBestHealthstoneFromTier()
    local B = Best()
    local Score = B and B.Score
    local tier = Score and Score.HEALTHSTONE_TIER
    if not tier then
        return nil
    end
    for i = 1, #tier do
        local stone = tier[i]
        local id = stone and tonumber(stone.id)
        if id then
            local n = BagCount(id, false)
            if n > 0 then
                local rank = (Score.HealthstoneRank and Score.HealthstoneRank(id)) or (#tier - i + 1)
                return {
                    itemID = id,
                    count = n,
                    effective = 1000 - i,
                    hsRank = rank,
                    kind = "healthstone",
                    isConjured = true,
                    source = "owned",
                }
            end
        end
    end
    return nil
end

local function WaterAllowsComboDrinks(opts)
    if opts and opts.allowComboDrinks == true then
        return true
    end
    if opts and opts.allowComboDrinks == false then
        return false
    end
    local Food = _G.FluxNCFood
    return Food
        and Food.HasRecuperate and Food.HasRecuperate()
        and Food.GetPreferRecuperate and Food.GetPreferRecuperate()
        and true or false
end

local function ScoreCompareOpts(kind, opts)
    if kind == "water" and WaterAllowsComboDrinks(opts) then
        return { preferConjured = true, allowComboDrinks = true }
    end
    return true
end

function Bridge.GetBestOwned(kind, opts)
    opts = opts or {}
    kind = kind and tostring(kind) or nil
    if not kind then
        return nil
    end
    if not Inv() then
        return nil
    end
    local B = Best()
    if not B or not B.IsValidKind or not B.IsValidKind(kind) then
        return nil
    end
    if B.IsManaKindRelevant and not B.IsManaKindRelevant(kind) then
        return nil
    end

    local preferCharges = opts.charges == true or kind == "managem"
    local Score = B.Score
    local fromBest = nil
    local best = B.GetBest and B.GetBest(kind)
    if best and best.itemID and (best.source ~= "vendor") and (best.source ~= "create") then
        local n = BagCount(best.itemID, preferCharges)
        if n > 0 then
            fromBest = {}
            for k, v in pairs(best) do
                fromBest[k] = v
            end
            fromBest.count = n
            fromBest.source = "owned"
        elseif B.IsSoftHoldKind and B.IsSoftHoldKind(kind) then
            -- Portal/zone: keep prior Best *identity* with count 0 (uncertain).
            -- Do not fabricate owned counts — button latch paints the last real count.
            local softHold = B.ShouldSoftHoldOwned and B.ShouldSoftHoldOwned()
            if not softHold then
                local inv = Inv()
                softHold = inv and inv.Bags and inv.Bags.IsReliable and not inv.Bags.IsReliable()
            end
            if softHold then
                fromBest = {}
                for k, v in pairs(best) do
                    fromBest[k] = v
                end
                fromBest.count = 0
                fromBest.uncertain = true
                fromBest.source = "owned"
            end
        end
    end
    -- Persisted ref (previous session best) if still owned — helps login before scan settles.
    if not fromBest and B.GetBestRef then
        local ref = B.GetBestRef(kind)
        local refID = ref and (ref.itemID or ref.id)
        refID = tonumber(refID)
        if refID then
            local n = BagCount(refID, preferCharges)
            if n > 0 then
                fromBest = {
                    itemID = refID,
                    kind = kind,
                    effective = tonumber(ref.effective) or 0,
                    isConjured = ref.isConjured and true or false,
                    count = n,
                    source = "owned",
                }
            end
        end
    end

    -- Healthstone: hard-coded create-rank wins over sticky Best / heal-only picks.
    if kind == "healthstone" then
        local fromTier = GetBestHealthstoneFromTier()
        if fromTier then
            if fromBest then
                if Score and Score.IsBetter and Score.IsBetter(fromTier, fromBest, true) then
                    return fromTier
                end
                if Score and Score.IsBetter and Score.IsBetter(fromBest, fromTier, true) then
                    return fromBest
                end
                return fromTier
            end
            return fromTier
        end
    end

    -- Fast path only while bags are unreliable (portal freeze).
    -- When reliable, always consult gen-cached ladder so loot/use promote+demote
    -- without waiting on Best sticky or /reload.
    -- Combo-on-water (Recuperate) must always consult ladder — Best store is pure-water only.
    local allowComboDrinks = kind == "water" and WaterAllowsComboDrinks(opts)
    if fromBest and not opts.needLadder and kind ~= "managem" and kind ~= "healthstone" and not allowComboDrinks then
        local inv = Inv()
        local reliable = true
        if inv and inv.Bags and inv.Bags.IsReliable then
            reliable = inv.Bags.IsReliable()
        elseif B.ShouldSoftHoldOwned and B.ShouldSoftHoldOwned() then
            reliable = false
        end
        if not reliable then
            return fromBest
        end
        -- Reliable: fall through to ladder.
    end

    -- Ladder when Best has no owned pick, bags are reliable, or caller needs the full list.
    local ladder = Bridge.GetOwnedLadder(kind, opts)
    local fromLadder = ladder and ladder[1] or nil
    local compareOpts = ScoreCompareOpts(kind, opts)
    if fromLadder and fromBest then
        if Score and Score.IsBetter and Score.IsBetter(fromLadder, fromBest, compareOpts) then
            return fromLadder
        end
        if Score and Score.IsBetter and Score.IsBetter(fromBest, fromLadder, compareOpts) then
            return fromBest
        end
        return fromLadder
    end
    return fromLadder or fromBest
end

--- Cached owned ladders keyed by kind + bag generation (avoids Classify-all on every Update).
local ladderCache = {} -- [cacheKey] = { gen = number, list = table }

local function LadderCacheKey(kind, preferCharges, allowComboDrinks)
    return tostring(kind or "")
        .. (preferCharges and ":c" or "")
        .. (allowComboDrinks and ":combo" or "")
end

--- Owned items of kind sorted best→worst (for castsequence / fallback).
function Bridge.GetOwnedLadder(kind, opts)
    opts = opts or {}
    local preferCharges = opts.charges == true or kind == "managem"
    local allowComboDrinks = kind == "water" and WaterAllowsComboDrinks(opts)
    local out = {}
    if kind == "managem" then
        local chargeOnly = Bridge.ShouldUseChargeBasedManaGemOnly()
        for i = 1, #MANA_GEM_TIER do
            local gem = MANA_GEM_TIER[i]
            if chargeOnly and not gem.hasCharges then
                -- Skip Vanilla single-use when charge-based mode is active (V9 behavior).
            else
                local n = BagCount(gem.id, preferCharges)
                if n > 0 then
                    out[#out + 1] = {
                        itemID = gem.id,
                        count = n,
                        effective = 1000 - i,
                        source = "owned",
                        kind = kind,
                        hasCharges = gem.hasCharges and true or false,
                    }
                end
            end
        end
        if #out > 0 then
            return out
        end
    end
    -- Healthstone: O(1) BagCount walk — skip Classify-all when any known rank is owned.
    if kind == "healthstone" then
        local B = Best()
        local Score = B and B.Score
        local tier = Score and Score.HEALTHSTONE_TIER
        if tier then
            for i = 1, #tier do
                local stone = tier[i]
                local id = stone and tonumber(stone.id)
                if id then
                    local n = BagCount(id, false)
                    if n > 0 then
                        local rank = (Score.HealthstoneRank and Score.HealthstoneRank(id)) or (#tier - i + 1)
                        out[#out + 1] = {
                            itemID = id,
                            count = n,
                            effective = 1000 - i,
                            hsRank = rank,
                            kind = "healthstone",
                            isConjured = true,
                            source = "owned",
                        }
                    end
                end
            end
            if #out > 0 then
                return out
            end
        end
    end
    local inv = Inv()
    local Classify = _G.FluxConsumableClassify
    local B = Best()
    local Score = B and B.Score
    if not inv or not inv.Bags or not Classify then
        return out
    end

    local gen = inv.Bags.GetGeneration and inv.Bags.GetGeneration() or 0
    local bestGen = (B and B._generation) or 0
    local key = LadderCacheKey(kind, preferCharges, allowComboDrinks)
    local cached = ladderCache[key]
    if cached and cached.gen == gen and cached.bestGen == bestGen and cached.list then
        return cached.list
    end

    local maxHP, maxMana = 1, 0
    if Score and Score.GetPools then
        maxHP, maxMana = Score.GetPools()
    end
    local compareOpts = ScoreCompareOpts(kind, opts)
    for itemID, rec in pairs(inv.Bags.GetUniqueItems()) do
        itemID = tonumber(itemID)
        local bagN = rec and tonumber(rec.count) or 0
        if itemID and bagN > 0 then
            local cls = Classify.Classify(itemID, rec.link)
            local health = cls and (tonumber(cls.health) or 0) or 0
            local mana = cls and (tonumber(cls.mana) or 0) or 0
            local isCombo = cls and cls.isCombo
            if isCombo == nil then
                isCombo = health > 0 and mana > 0
            end
            local matches = cls and cls.kind == kind
            -- Recuperate on food: water ladder also accepts combo HP+mana food.
            if not matches and allowComboDrinks and cls and cls.kind == "food" and isCombo then
                matches = true
            end
            if matches then
                -- Owned bag scan: exclude only known-unusable. Unloaded item data
                -- must still compete so login can pick the best bandage.
                local blocked = Score and Score.IsKnownUnusable and Score.IsKnownUnusable(itemID, kind)
                if not blocked then
                    local effective
                    if allowComboDrinks and cls.kind == "food" then
                        -- Score combo drinks by mana restore on the water button.
                        effective = mana
                        if (effective or 0) <= 0 and Score and Score.EffectiveFromClassify then
                            effective = Score.EffectiveFromClassify(cls, maxHP, maxMana)
                        end
                    else
                        effective = Score and Score.EffectiveFromClassify
                            and Score.EffectiveFromClassify(cls, maxHP, maxMana)
                            or (cls.effective or 0)
                    end
                    local n = preferCharges and BagCount(itemID, true) or bagN
                    if n > 0 and effective > 0 then
                        local maxStack = (Score and Score.GetMaxStack and Score.GetMaxStack(itemID)) or 0
                        out[#out + 1] = {
                            itemID = itemID,
                            kind = (allowComboDrinks and cls.kind == "food") and "food" or kind,
                            effective = effective,
                            health = health,
                            mana = mana,
                            isCombo = isCombo and true or nil,
                            hsRank = (kind == "healthstone" and Score.HealthstoneRank and Score.HealthstoneRank(itemID)) or nil,
                            isConjured = cls.isConjured and true or false,
                            count = n,
                            maxStack = maxStack,
                            source = "owned",
                        }
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if Score and Score.IsBetter then
            return Score.IsBetter(a, b, compareOpts)
        end
        return (a.effective or 0) > (b.effective or 0)
    end)
    ladderCache[key] = { gen = gen, bestGen = bestGen, list = out }
    return out
end

--- Promote only when tracked is empty or a strictly better owned ID exists.
function Bridge.PromoteIfBetter(kind, trackedItemID, opts)
    local best = Bridge.GetBestOwned(kind, opts)
    trackedItemID = tonumber(trackedItemID)
    if not best or not best.itemID then
        return nil, trackedItemID and BagCount(trackedItemID, opts and opts.charges) or 0
    end
    if not trackedItemID then
        return best.itemID, best.count or 0
    end
    local trackedCount = BagCount(trackedItemID, opts and opts.charges)
    if trackedCount <= 0 then
        return best.itemID, best.count or 0
    end
    if best.itemID == trackedItemID then
        return trackedItemID, trackedCount
    end
    local B = Best()
    local Score = B and B.Score
    local tracked = {
        itemID = trackedItemID,
        kind = kind,
        effective = 0,
        isConjured = false,
        count = trackedCount,
    }
    -- Estimate tracked effective via classify if possible.
    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.Classify then
        local cls = Classify.Classify(trackedItemID)
        if cls and Score and Score.EffectiveFromClassify then
            tracked.effective = Score.EffectiveFromClassify(cls)
            tracked.isConjured = cls.isConjured and true or false
            tracked.health = tonumber(cls.health) or 0
            tracked.mana = tonumber(cls.mana) or 0
            tracked.isCombo = (tracked.health > 0 and tracked.mana > 0) or nil
            tracked.kind = cls.kind or kind
            -- Recuperate off: combo food must leave the water button.
            if kind == "water" and not WaterAllowsComboDrinks(opts) and cls.kind == "food" then
                return best.itemID, best.count or 0
            end
        end
    end
    if Score and Score.IsBetter and Score.IsBetter(best, tracked, ScoreCompareOpts(kind, opts)) then
        return best.itemID, best.count or 0
    end
    return trackedItemID, trackedCount
end

function Bridge.CanCreate(kind)
    local sp = Spells()
    if not sp or not sp.HasCreateKind then
        return false
    end
    return sp.HasCreateKind(kind)
end

--- Highest known create/conjure spell for kind (managem / healthstone).
function Bridge.GetPreferredCreateSpell(kind)
    local sp = Spells()
    if not sp then
        return nil
    end
    if sp.GetPreferredCreateSpell then
        return sp.GetPreferredCreateSpell(kind)
    end
    return nil, nil
end

function Bridge.GetFoodConjureSpell()
    local sp = Spells()
    if not sp or not sp.GetPreferredFoodConjureSpell then
        return nil
    end
    return sp.GetPreferredFoodConjureSpell()
end

function Bridge.GetFoodSecondaryConjureSpell()
    local sp = Spells()
    if not sp or not sp.GetSecondaryFoodConjureSpell then
        return nil
    end
    return sp.GetSecondaryFoodConjureSpell()
end

function Bridge.GetWaterConjureSpell()
    local sp = Spells()
    if not sp or not sp.GetPreferredWaterConjureSpell then
        return nil
    end
    return sp.GetPreferredWaterConjureSpell()
end

function Bridge.GetWaterSecondaryConjureSpell()
    local sp = Spells()
    if not sp or not sp.GetSecondaryWaterConjureSpell then
        return nil
    end
    return sp.GetSecondaryWaterConjureSpell()
end

--- Apply secure right-click macro/spell (call AFTER SetAction).
function Bridge.ApplyRightClickMacro(btn, macrotext)
    if not btn or not btn.Widget then
        return
    end
    local w = btn.Widget
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    if macrotext and macrotext ~= "" then
        w:SetAttribute("type2", "macro")
        w:SetAttribute("macrotext2", macrotext)
    else
        w:SetAttribute("type2", nil)
        w:SetAttribute("macrotext2", nil)
    end
end

function Bridge.ResolveSpellName(spellIDOrName)
    if not spellIDOrName then
        return nil
    end
    if type(spellIDOrName) == "string" and spellIDOrName ~= "" then
        return spellIDOrName
    end
    local spellID = tonumber(spellIDOrName)
    if not spellID then
        return nil
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then
            return info.name
        end
    end
    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    return tostring(spellID)
end

--- Prefer /cast macro for create/conjure: Classic SecureActionButton is more
--- reliable with spell names (incl. Rank N) than numeric spell2 on some clients.
--- Pass spellID when available so cold-login resolves a live localized cast string
--- instead of a hardcoded English name that may not cast yet.
function Bridge.ApplyRightClickSpell(btn, spellIDOrName)
    if not btn or not btn.Widget then
        return
    end
    local w = btn.Widget
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    if not spellIDOrName then
        w:SetAttribute("type2", nil)
        w:SetAttribute("spell2", nil)
        w:SetAttribute("macrotext2", nil)
        return
    end
    local spellID = tonumber(spellIDOrName)
    local castAttr
    if spellID then
        local Core = _G.FluxButtonCore
        if Core and Core.FormatSpellCastAttribute then
            castAttr = Core.FormatSpellCastAttribute(spellID)
        elseif _G.FluxFormatSpellCastAttribute then
            castAttr = _G.FluxFormatSpellCastAttribute(spellID)
        end
    end
    local spellName
    if type(castAttr) == "string" and castAttr ~= "" then
        spellName = castAttr
    elseif spellID then
        spellName = Bridge.ResolveSpellName(spellID)
    elseif type(spellIDOrName) == "string" then
        -- English fallback: resolve via spell info when possible so /cast is localized.
        if C_Spell and C_Spell.GetSpellInfo then
            local ok, info = pcall(C_Spell.GetSpellInfo, spellIDOrName)
            if ok and type(info) == "table" and info.name then
                spellName = info.name
            end
        end
        spellName = spellName or spellIDOrName
    end
    if spellName and spellName ~= "" then
        w:SetAttribute("type2", "macro")
        w:SetAttribute("macrotext2", "/cast " .. spellName)
        w:SetAttribute("spell2", nil)
        return
    end
    if spellID then
        w:SetAttribute("type2", "spell")
        w:SetAttribute("spell2", spellID)
        w:SetAttribute("macrotext2", nil)
        return
    end
    w:SetAttribute("type2", nil)
    w:SetAttribute("spell2", nil)
    w:SetAttribute("macrotext2", nil)
end

--- Shift-right conjure secondary (Ritual / alternate food-water conjure).
function Bridge.ApplyShiftRightClickSpell(btn, spellIDOrName)
    if not btn or not btn.Widget then
        return
    end
    local w = btn.Widget
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    if not spellIDOrName then
        w:SetAttribute("shift-type2", nil)
        w:SetAttribute("shift-spell2", nil)
        w:SetAttribute("shift-macrotext2", nil)
        return
    end
    local spellID = tonumber(spellIDOrName)
    local castAttr
    if spellID then
        local Core = _G.FluxButtonCore
        if Core and Core.FormatSpellCastAttribute then
            castAttr = Core.FormatSpellCastAttribute(spellID)
        elseif _G.FluxFormatSpellCastAttribute then
            castAttr = _G.FluxFormatSpellCastAttribute(spellID)
        end
    end
    local spellName
    if type(castAttr) == "string" and castAttr ~= "" then
        spellName = castAttr
    elseif spellID then
        spellName = Bridge.ResolveSpellName(spellID)
    elseif type(spellIDOrName) == "string" then
        if C_Spell and C_Spell.GetSpellInfo then
            local ok, info = pcall(C_Spell.GetSpellInfo, spellIDOrName)
            if ok and type(info) == "table" and info.name then
                spellName = info.name
            end
        end
        spellName = spellName or spellIDOrName
    end
    if spellName and spellName ~= "" then
        w:SetAttribute("shift-type2", "macro")
        w:SetAttribute("shift-macrotext2", "/cast " .. spellName)
        w:SetAttribute("shift-spell2", nil)
        return
    end
    if spellID then
        w:SetAttribute("shift-type2", "spell")
        w:SetAttribute("shift-spell2", spellID)
        w:SetAttribute("shift-macrotext2", nil)
        return
    end
    w:SetAttribute("shift-type2", nil)
    w:SetAttribute("shift-spell2", nil)
    w:SetAttribute("shift-macrotext2", nil)
end

--- Ctrl-right conjure tertiary (when Shift+Right is restock under Recuperate).
function Bridge.ApplyCtrlRightClickSpell(btn, spellIDOrName)
    if not btn or not btn.Widget then
        return
    end
    local w = btn.Widget
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    if not spellIDOrName then
        w:SetAttribute("ctrl-type2", nil)
        w:SetAttribute("ctrl-spell2", nil)
        w:SetAttribute("ctrl-macrotext2", nil)
        return
    end
    local spellID = tonumber(spellIDOrName)
    local castAttr
    if spellID then
        local Core = _G.FluxButtonCore
        if Core and Core.FormatSpellCastAttribute then
            castAttr = Core.FormatSpellCastAttribute(spellID)
        elseif _G.FluxFormatSpellCastAttribute then
            castAttr = _G.FluxFormatSpellCastAttribute(spellID)
        end
    end
    local spellName
    if type(castAttr) == "string" and castAttr ~= "" then
        spellName = castAttr
    elseif spellID then
        spellName = Bridge.ResolveSpellName(spellID)
    elseif type(spellIDOrName) == "string" then
        if C_Spell and C_Spell.GetSpellInfo then
            local ok, info = pcall(C_Spell.GetSpellInfo, spellIDOrName)
            if ok and type(info) == "table" and info.name then
                spellName = info.name
            end
        end
        spellName = spellName or spellIDOrName
    end
    if spellName and spellName ~= "" then
        w:SetAttribute("ctrl-type2", "macro")
        w:SetAttribute("ctrl-macrotext2", "/cast " .. spellName)
        w:SetAttribute("ctrl-spell2", nil)
        return
    end
    if spellID then
        w:SetAttribute("ctrl-type2", "spell")
        w:SetAttribute("ctrl-spell2", spellID)
        w:SetAttribute("ctrl-macrotext2", nil)
        return
    end
    w:SetAttribute("ctrl-type2", nil)
    w:SetAttribute("ctrl-spell2", nil)
    w:SetAttribute("ctrl-macrotext2", nil)
end

--- Left-click use binding + optional shared conjure RightButton binding (Mana Gem / Healthstone).
--- opts.conjureBindingName, opts.canConjure()
function Bridge.ApplyUseAndConjureBindings(btn, useBindingName, opts)
    if not btn or not useBindingName then
        return
    end
    opts = opts or {}
    local w = btn.Widget
    if not w or not w.GetName then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        btn._pendingKeybindUpdate = true
        return
    end
    local widgetName = w:GetName()
    if not widgetName then
        return
    end
    ClearOverrideBindings(w)
    local key1, key2 = GetBindingKey(useBindingName)
    if key1 then
        SetOverrideBindingClick(w, false, key1, widgetName, "LeftButton")
    end
    if key2 then
        SetOverrideBindingClick(w, false, key2, widgetName, "LeftButton")
    end
    local conjureBinding = opts.conjureBindingName
    local canConjure = true
    if type(opts.canConjure) == "function" then
        canConjure = opts.canConjure() and true or false
    end
    local keyConjure1, keyConjure2
    if conjureBinding and canConjure then
        keyConjure1, keyConjure2 = GetBindingKey(conjureBinding)
        if keyConjure1 then
            SetOverrideBindingClick(w, false, keyConjure1, widgetName, "RightButton")
        end
        if keyConjure2 then
            SetOverrideBindingClick(w, false, keyConjure2, widgetName, "RightButton")
        end
    end
    local HotkeyUtil = _G.FluxNCHotkeyUtil
    if HotkeyUtil then
        local showBoth = (key1 or key2) and (keyConjure1 or keyConjure2) and canConjure
        if showBoth and HotkeyUtil.UpdateHotkeyTextMultiple then
            HotkeyUtil.UpdateHotkeyTextMultiple(btn, { useBindingName, conjureBinding })
        elseif HotkeyUtil.UpdateHotkeyText then
            if key1 or key2 then
                HotkeyUtil.UpdateHotkeyText(btn, useBindingName)
            elseif (keyConjure1 or keyConjure2) and canConjure then
                HotkeyUtil.UpdateHotkeyText(btn, conjureBinding)
            else
                HotkeyUtil.UpdateHotkeyText(btn, useBindingName)
            end
        end
    end
    if _G.FluxDefaultSettings and _G.FluxDefaultSettings.RefreshConjureSharedBindingName then
        _G.FluxDefaultSettings.RefreshConjureSharedBindingName()
    end
    btn._pendingKeybindUpdate = false
end

function Bridge.BuildUseItemMacro(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    return "/use item:" .. itemID
end

function Bridge.BuildCastSequenceMacro(itemIDs)
    if type(itemIDs) ~= "table" or #itemIDs == 0 then
        return nil
    end
    local parts = {}
    for i = 1, #itemIDs do
        local id = tonumber(itemIDs[i]) or (type(itemIDs[i]) == "table" and tonumber(itemIDs[i].itemID))
        if id then
            parts[#parts + 1] = "item:" .. id
        end
    end
    if #parts == 0 then
        return nil
    end
    if #parts == 1 then
        return "/use " .. parts[1]
    end
    -- Mana gem multi-use: reset when combat ends (V9 parity).
    return "/castsequence reset=combat " .. table.concat(parts, ",")
end

function Bridge.After(delay, fn)
    if FluxAPICompat and FluxAPICompat.After then
        FluxAPICompat.After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

--- Pickup+delete one bag stack of itemID (middle-click destroy for HS/gem).
function Bridge.DeleteOneOwned(itemID)
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local inv = Inv()
    local bag, slot
    if inv and inv.FindFirstBagSlot then
        bag, slot = inv.FindFirstBagSlot(itemID)
    elseif inv and inv.Bags and inv.Bags.FindFirst then
        bag, slot = inv.Bags.FindFirst(itemID)
    end
    if not bag or not slot then
        return false
    end
    local PickupItem = C_Container and C_Container.PickupContainerItem or PickupContainerItem
    if PickupItem and DeleteCursorItem then
        PickupItem(bag, slot)
        if CursorHasItem and CursorHasItem() then
            DeleteCursorItem()
            return true
        end
        if ClearCursor then
            ClearCursor()
        end
    end
    return false
end

--- True when item is conjured (mage food/water, HS, gems, etc.).
function Bridge.IsConjured(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.Classify then
        local cls = Classify.Classify(itemID)
        if cls and cls.isConjured then
            return true
        end
    end
    local IC = _G.FluxItemClass
    if IC and IC.GetTooltipText then
        local text = IC.GetTooltipText(itemID)
        if type(text) == "string" and text:lower():find("conjured", 1, true) then
            return true
        end
    end
    local name = GetItemInfo and GetItemInfo(itemID)
    if type(name) == "string" and name:lower():find("conjured", 1, true) then
        return true
    end
    return false
end

--- Middle-click: destroy one owned stack only if it is conjured (food/water).
function Bridge.DeleteOneConjuredOwned(itemID)
    if not Bridge.IsConjured(itemID) then
        return false
    end
    return Bridge.DeleteOneOwned(itemID)
end

--- SetOverrideBindingClick + hotkey label for a FluxButton (V9 grid pattern).
function Bridge.ApplyBinding(btn, bindingName)
    if not btn or not bindingName then
        return
    end
    local w = btn.Widget
    if not w or not w.GetName then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        btn._pendingKeybindUpdate = true
        return
    end
    local widgetName = w:GetName()
    if not widgetName then
        return
    end
    ClearOverrideBindings(w)
    local key1, key2 = GetBindingKey(bindingName)
    if key1 then
        SetOverrideBindingClick(w, false, key1, widgetName, "LeftButton")
    end
    if key2 then
        SetOverrideBindingClick(w, false, key2, widgetName, "LeftButton")
    end
    local HotkeyUtil = _G.FluxNCHotkeyUtil
    if HotkeyUtil and HotkeyUtil.UpdateHotkeyText then
        HotkeyUtil.UpdateHotkeyText(btn, bindingName)
    end
    btn._pendingKeybindUpdate = false
end

--- Format a spell name with its icon (+ rank subtext when present).
function Bridge.FormatSpellTooltipLine(spellNameOrID)
    if not spellNameOrID then
        return nil
    end
    local name, icon, spellID
    if type(spellNameOrID) == "number" then
        spellID = spellNameOrID
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellID)
            if info then
                name = info.name
                icon = info.iconID
            end
        elseif GetSpellInfo then
            name, _, icon = GetSpellInfo(spellID)
        end
    else
        name = tostring(spellNameOrID)
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(name)
            if info then
                icon = info.iconID
                name = info.name or name
                spellID = info.spellID
            end
        elseif GetSpellInfo then
            local n, _, ic = GetSpellInfo(name)
            name = n or name
            icon = ic
        end
    end
    if not name or name == "" then
        return nil
    end
    local rank
    if spellID then
        if C_Spell and C_Spell.GetSpellSubtext then
            rank = C_Spell.GetSpellSubtext(spellID)
        elseif GetSpellSubtext then
            rank = GetSpellSubtext(spellID)
        end
    end
    if (not rank or rank == "") and GetSpellInfo and type(spellNameOrID) ~= "number" then
        -- Classic-style rank from GetSpellInfo 2nd return is unused above; try subtext by name.
        if GetSpellSubtext then
            rank = GetSpellSubtext(name)
        end
    end
    local label = name
    if rank and rank ~= "" then
        label = name .. " (" .. tostring(rank) .. ")"
    end
    if icon then
        return "|T" .. tostring(icon) .. ":16|t " .. label
    end
    return label
end

local CONJURE_BLUE = { 0.4, 0.7, 1 }

local function ResolveSpellID(spellNameOrID)
    if type(spellNameOrID) == "number" then
        return spellNameOrID
    end
    if not spellNameOrID then
        return nil
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellNameOrID)
        if info and info.spellID then
            return info.spellID
        end
    end
    if GetSpellInfo then
        local _, _, _, _, _, _, spellID = GetSpellInfo(spellNameOrID)
        return spellID
    end
    return nil
end

--- Reagent cast budget suffix: " (|Ticon|t N)" when the spell consumes reagents.
local function FormatReagentCastSuffix(spellNameOrID)
    local spellID = ResolveSpellID(spellNameOrID)
    if not spellID then
        return ""
    end
    local sp = Spells()
    local reagents = sp and sp.GetReagents and sp.GetReagents(spellID)
    if not reagents or #reagents == 0 then
        return ""
    end
    local castCount = 0
    if sp and sp.GetCastCount then
        castCount = sp.GetCastCount(spellID) or 0
    elseif C_Spell and C_Spell.GetSpellCastCount then
        castCount = C_Spell.GetSpellCastCount(spellID) or 0
    elseif GetSpellCount then
        castCount = GetSpellCount(spellID) or 0
    end
    local reagentID = reagents[1].itemID or 6265 -- Soul Shard fallback
    local icon
    if C_Item and C_Item.GetItemIconByID then
        icon = C_Item.GetItemIconByID(reagentID)
    elseif GetItemIcon then
        icon = GetItemIcon(reagentID)
    end
    if icon then
        return string.format(" (|T%s:14:14:0:0|t %d)", tostring(icon), castCount)
    end
    return string.format(" (%d)", castCount)
end

--- Append conjure spell lines: Right-click / Shift-Right + icon + rank (blue).
--- When the spell needs reagents, cast count is on the same line.
--- Spacing: one blank before the whole Flux block (via _EnsureFluxTooltipGap), none between lines.
function Bridge.ResetFluxTooltipGap(tip)
    if tip then
        tip._fluxEbsGapDone = nil
    end
end

--- Exactly one blank between item/placeholder body and the first Flux line for this tip show.
function Bridge._EnsureFluxTooltipGap(tip)
    if not tip or tip._fluxEbsGapDone then
        return
    end
    tip:AddLine(" ")
    tip._fluxEbsGapDone = true
end

function Bridge.AppendConjureSpellLines(tip, primary, secondary, opts)
    if not tip then
        return
    end
    opts = opts or {}
    local r, g, b = CONJURE_BLUE[1], CONJURE_BLUE[2], CONJURE_BLUE[3]
    local p = Bridge.FormatSpellTooltipLine(primary)
    local s = Bridge.FormatSpellTooltipLine(secondary)
    local hasSecondary = s and secondary and primary and tostring(secondary) ~= tostring(primary)
    if not p and not hasSecondary then
        return
    end

    local function KeyText(bindingName)
        if not bindingName then
            return nil
        end
        local HotkeyUtil = _G.FluxNCHotkeyUtil
        if HotkeyUtil and HotkeyUtil.GetBindingKeyText then
            local t = HotkeyUtil.GetBindingKeyText(bindingName)
            if t and t ~= "" then
                return t
            end
        end
        if GetBindingKey then
            local key = GetBindingKey(bindingName)
            if key then
                return (GetBindingText and GetBindingText(key, "KEY_")) or key
            end
        end
        return nil
    end

    local primaryKey = KeyText(opts.bindingName)
    local ritualKey = KeyText(opts.ritualBindingName)
    local secondaryIsRitual = hasSecondary and type(secondary) == "string"
        and secondary:lower():find("ritual", 1, true)

    Bridge._EnsureFluxTooltipGap(tip)
    if p then
        local left = "Right-click: " .. p .. FormatReagentCastSuffix(primary)
        if primaryKey then
            tip:AddDoubleLine(left, primaryKey, r, g, b, 0.2, 1, 0.2)
        else
            tip:AddLine(left, r, g, b)
        end
    end
    if hasSecondary then
        local secMod = opts.secondaryModifier == "ctrl" and "Ctrl-Right" or "Shift-Right"
        local left = secMod .. ": " .. s .. FormatReagentCastSuffix(secondary)
        local secKey
        if secondaryIsRitual and ritualKey and opts.secondaryModifier ~= "ctrl" then
            secKey = ritualKey
        elseif primaryKey then
            -- Same conjure bind + modifier on the grid button.
            local prefix = opts.secondaryModifier == "ctrl" and "Ctrl-" or "Shift-"
            secKey = prefix .. primaryKey
        end
        if secKey then
            tip:AddDoubleLine(left, secKey, r, g, b, 0.2, 1, 0.2)
        else
            tip:AddLine(left, r, g, b)
        end
    end
end

local function AxisForKind(kind)
    if kind == "water" or kind == "manaPotion" or kind == "managem" then
        return "mana"
    end
    return "health"
end

local function ItemEffective(kind, itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0, false
    end
    local Classify = _G.FluxConsumableClassify
    local B = Best()
    local Score = B and B.Score
    if not Classify or not Classify.Classify then
        return 0, Bridge.IsConjured(itemID)
    end
    local cls = Classify.Classify(itemID)
    -- Water button / tier lines: pure water only (combo food stays on the food button),
    -- unless Recuperate prefers spell-on-food and combo is allowed on water.
    local allowCombo = kind == "water" and WaterAllowsComboDrinks()
    local matches = cls and cls.kind == kind
    if not matches and allowCombo and cls and cls.kind == "food" then
        local h = tonumber(cls.health) or 0
        local m = tonumber(cls.mana) or 0
        local isCombo = cls.isCombo == true or (h > 0 and m > 0)
        matches = isCombo
    end
    if not matches then
        return 0, cls and cls.isConjured or Bridge.IsConjured(itemID)
    end
    local eff = 0
    if allowCombo and cls.kind == "food" then
        eff = tonumber(cls.mana) or 0
    elseif Score and Score.EffectiveFromClassify then
        eff = Score.EffectiveFromClassify(cls)
    else
        eff = tonumber(cls.effective) or 0
    end
    return eff, cls.isConjured and true or false
end

local function BestOwnedEffective(kind, conjuredOnly)
    local ladder = Bridge.GetOwnedLadder(kind, { charges = kind == "managem" })
    local bestEff = 0
    for i = 1, #(ladder or {}) do
        local e = ladder[i]
        local isConj = e.isConjured
        if isConj == nil then
            isConj = Bridge.IsConjured(e.itemID)
        end
        if conjuredOnly == true and not isConj then
        elseif conjuredOnly == false and isConj then
        else
            local eff = tonumber(e.effective) or 0
            if eff > bestEff then
                bestEff = eff
            end
        end
    end
    return bestEff
end

local RESTOCK_TIER_KINDS = {
    food = true,
    water = true,
    bandage = true,
    healPotion = true,
    manaPotion = true,
}

local EMPTY_KIND_LABEL = {
    food = "No food",
    water = "No water",
    bandage = "No bandages",
    healPotion = "No healing potions",
    manaPotion = "No mana potions",
}

--- Button tooltip tier status vs saved/vendor restock reference (+ conjured food/water).
--- Placeholder (no bound item): only "No food/water/…" — no Best tier lines.
--- Conjured stacks: Best conjured only (no Best tier).
--- Spacing: one leading Flux-block gap max; no blanks between Best / restock / set-target.
function Bridge.AppendTierStatusLines(tip, kind, itemID, btn)
    if not tip or not kind then
        return
    end
    itemID = tonumber(itemID)
    local bagN = itemID and Bridge.BagCount(itemID) or 0
    local Tiers = _G.FluxRestockTiers
    local round = (Tiers and Tiers.RoundTier) or function(v)
        return math.floor((tonumber(v) or 0) + 0.5)
    end

    local function appendRestock(hint)
        if RESTOCK_TIER_KINDS[kind] and Tiers and Tiers.AppendRestockTooltipLines then
            Bridge._EnsureFluxTooltipGap(tip)
            Tiers.AppendRestockTooltipLines(tip, kind, hint, nil, true)
        end
    end

    if not itemID or bagN <= 0 then
        local empty = EMPTY_KIND_LABEL[kind]
        if empty then
            Bridge._EnsureFluxTooltipGap(tip)
            tip:AddLine(empty, 1, 0.35, 0.35, true)
        end
        appendRestock((btn and btn._fluxRestockEditClickMode) or "right")
        return
    end

    local axis = AxisForKind(kind)
    local itemEff, isConjured = ItemEffective(kind, itemID)
    itemEff = round(itemEff)

    -- Same saved/vendor bar restock uses (not bag-ladder alone).
    local ref = 0
    if RESTOCK_TIER_KINDS[kind] and Tiers then
        if Tiers.GetEffectiveReferenceTier then
            ref = round(Tiers.GetEffectiveReferenceTier(kind) or 0)
        elseif Tiers.GetCachedTooltipReferenceTier then
            ref = round(Tiers.GetCachedTooltipReferenceTier(kind) or 0)
        end
    end

    -- Vendor/crafted: Best tier. Conjured food/water: Best conjured only (skip Best tier).
    if RESTOCK_TIER_KINDS[kind] and not isConjured then
        if itemEff > 0 and ref > 0 and itemEff < ref then
            Bridge._EnsureFluxTooltipGap(tip)
            tip:AddLine(
                string.format("Not best tier: %d / %d %s", itemEff, ref, axis),
                1, 0.55, 0.35, true
            )
        elseif ref > 0 then
            Bridge._EnsureFluxTooltipGap(tip)
            tip:AddLine(string.format("Best tier: %d %s", ref, axis), 0.4, 1, 0.4, true)
        elseif itemEff > 0 then
            Bridge._EnsureFluxTooltipGap(tip)
            tip:AddLine(string.format("Best tier: %d %s", itemEff, axis), 0.4, 1, 0.4, true)
        end
    elseif (kind == "food" or kind == "water") and isConjured then
        local bestConj = round(BestOwnedEffective(kind, true))
        if itemEff > 0 and bestConj > 0 and itemEff < bestConj then
            Bridge._EnsureFluxTooltipGap(tip)
            tip:AddLine(
                string.format("Not best conjured: %d / %d %s", itemEff, bestConj, axis),
                1, 0.55, 0.35, true
            )
        elseif bestConj > 0 then
            Bridge._EnsureFluxTooltipGap(tip)
            tip:AddLine(string.format("Best conjured: %d %s", bestConj, axis), 0.4, 1, 0.4, true)
        elseif itemEff > 0 then
            Bridge._EnsureFluxTooltipGap(tip)
            tip:AddLine(string.format("Best conjured: %d %s", itemEff, axis), 0.4, 1, 0.4, true)
        end
    end

    if RESTOCK_TIER_KINDS[kind] and Tiers and Tiers.AppendRestockTooltipLines then
        appendRestock((btn and btn._fluxRestockEditClickMode) or "right")
    elseif Tiers and Tiers.GetTarget then
        local target = Tiers.GetTarget(kind) or 0
        local owned = 0
        if Tiers.GetBagOwnedTier then
            owned = select(1, Tiers.GetBagOwnedTier(kind)) or 0
        end
        Bridge._EnsureFluxTooltipGap(tip)
        tip:AddLine(
            string.format("Restock target: %d (owned best ~%d).", target, round(owned)),
            0.5, 0.7, 0.5, true
        )
    end

    Bridge.AppendDeleteStackHint(tip, btn, itemID)
end

--- Pure-red middle-click destroy hint when middle is not owned by restock edit.
function Bridge.AppendDeleteStackHint(tip, btn, itemID)
    if not tip then
        return
    end
    itemID = tonumber(itemID)
    if not itemID then
        return
    end
    if not btn or not (btn._fluxMiddleDelete or btn._fluxMiddleDeleteConjured) then
        return
    end
    local mode = btn._fluxRestockEditClickMode
    if mode == "middle" then
        return
    end
    local n = Bridge.BagCount(itemID) or 0
    if n <= 0 then
        return
    end
    if btn._fluxMiddleDeleteConjured and not btn._fluxMiddleDelete then
        if not Bridge.IsConjured(itemID) then
            return
        end
    end
    Bridge._EnsureFluxTooltipGap(tip)
    tip:AddLine("Middle-click to remove 1 stack", 1, 0, 0)
end

--- Wire restock edit for ExtraButtons.
--- opts.mode = "right" | "middle" | "shift-middle" | "shift-right"
--- When mode is "right" and no conjure/craft, sets type2 to restock proxy.
--- When mode is "shift-right", sets shift-type2 (conjure keeps type2).
--- When mode is "middle"/"shift-middle", sets type3 / shift-type3 (conjure keeps type2).
function Bridge.WireRestockEdit(btn, kind, opts)
    opts = opts or {}
    if not btn or not btn.Widget or not kind then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local Tiers = _G.FluxRestockTiers
    local mode = opts.mode or "right"
    btn._fluxRestockKind = kind
    btn._fluxRestockEditClickMode = mode
    local proxy = Tiers and Tiers.GetRestockProxyMacro and Tiers.GetRestockProxyMacro(kind)
    if not proxy then
        local P = _G.FluxMacroClickProxies
        if kind == "food" then
            proxy = P and P.MACRO_FOOD_RESTOCK_TOGGLE or "/click FluxMacroProxy_FoodRestockToggle"
        elseif kind == "water" then
            proxy = P and P.MACRO_WATER_RESTOCK_TOGGLE or "/click FluxMacroProxy_WaterRestockToggle"
        elseif kind == "bandage" then
            proxy = P and P.MACRO_BANDAGE_RESTOCK_TOGGLE or "/click FluxMacroProxy_BandageRestockToggle"
        elseif kind == "healPotion" then
            proxy = P and P.MACRO_HEAL_POTION_RESTOCK_TOGGLE or "/click FluxMacroProxy_HealPotionRestockToggle"
        elseif kind == "manaPotion" then
            proxy = P and P.MACRO_MANA_POTION_RESTOCK_TOGGLE or "/click FluxMacroProxy_ManaPotionRestockToggle"
        end
    end
    if not proxy then
        return
    end
    local w = btn.Widget
    if mode == "right" then
        w:SetAttribute("type2", "macro")
        w:SetAttribute("macrotext2", proxy)
        w:SetAttribute("shift-type3", nil)
        w:SetAttribute("shift-macrotext3", nil)
        btn._fluxSkipMiddleNoUse = nil
    elseif mode == "shift-right" then
        -- Conjure owns plain right-click; restock on Shift+Right.
        w:SetAttribute("shift-type2", "macro")
        w:SetAttribute("shift-macrotext2", proxy)
        w:SetAttribute("shift-spell2", nil)
        w:SetAttribute("shift-type3", nil)
        w:SetAttribute("shift-macrotext3", nil)
        btn._fluxSkipMiddleNoUse = nil
    elseif mode == "middle" then
        w:SetAttribute("type3", "macro")
        w:SetAttribute("macrotext3", proxy)
        w:SetAttribute("shift-type3", nil)
        w:SetAttribute("shift-macrotext3", nil)
        btn._fluxSkipMiddleNoUse = true
    elseif mode == "shift-middle" then
        w:SetAttribute("shift-type3", "macro")
        w:SetAttribute("shift-macrotext3", proxy)
        -- Keep plain middle as /stopmacro for conjured-delete path.
        btn._fluxSkipMiddleNoUse = nil
    end
end

function Bridge.GetRestockClickHint(kind, mode)
    return mode or "right"
end

function Bridge.AppendRestockEditHint(tip, kind, mode)
    local Tiers = _G.FluxRestockTiers
    if Tiers and Tiers.AppendRestockTooltipLines then
        Bridge._EnsureFluxTooltipGap(tip)
        Tiers.AppendRestockTooltipLines(tip, kind, mode or "right", nil, true)
        return
    end
    if not tip then
        return
    end
    Bridge._EnsureFluxTooltipGap(tip)
    if mode == "middle" then
        tip:AddLine("Middle-click to set restock target.", 0.6, 0.6, 0.6)
    elseif mode == "shift-middle" then
        tip:AddLine("Shift + Middle-click to set restock target.", 0.6, 0.6, 0.6)
    elseif mode == "shift-right" then
        tip:AddLine("Shift + Right-click to set restock target.", 0.6, 0.6, 0.6)
    else
        tip:AddLine("Right-click to set restock target.", 0.6, 0.6, 0.6)
    end
end

--- Best craftable profession recipe for kind (healPotion / manaPotion / bandage).
function Bridge.GetBestCraftable(kind)
    local Craft = _G.FluxInv and _G.FluxInv.Craft
    if Craft and Craft.GetBestCraftable then
        return Craft.GetBestCraftable(kind)
    end
    return nil
end

--- True when bags have mats for a known heal/mana/bandage recipe (cached).
function Bridge.CanCraft(kind)
    local Craft = _G.FluxInv and _G.FluxInv.Craft
    if Craft and Craft.CanCraftKind then
        return Craft.CanCraftKind(kind) and true or false
    end
    local best = Bridge.GetBestCraftable(kind)
    return best and (tonumber(best.craftable) or 0) > 0
end

function Bridge.GetCraftMacro(kind)
    local P = _G.FluxMacroClickProxies
    if kind == "healPotion" then
        return P and P.MACRO_CRAFT_HEAL_POTION or "/click FluxMacroProxy_CraftHealPotion"
    end
    if kind == "manaPotion" then
        return P and P.MACRO_CRAFT_MANA_POTION or "/click FluxMacroProxy_CraftManaPotion"
    end
    if kind == "bandage" then
        return P and P.MACRO_CRAFT_BANDAGE or "/click FluxMacroProxy_CraftBandage"
    end
    return nil
end

local function GetRestockProxyMacro(kind)
    local Tiers = _G.FluxRestockTiers
    local proxy = Tiers and Tiers.GetRestockProxyMacro and Tiers.GetRestockProxyMacro(kind)
    if proxy then
        return proxy
    end
    local P = _G.FluxMacroClickProxies
    if kind == "food" then
        return P and P.MACRO_FOOD_RESTOCK_TOGGLE or "/click FluxMacroProxy_FoodRestockToggle"
    elseif kind == "water" then
        return P and P.MACRO_WATER_RESTOCK_TOGGLE or "/click FluxMacroProxy_WaterRestockToggle"
    elseif kind == "bandage" then
        return P and P.MACRO_BANDAGE_RESTOCK_TOGGLE or "/click FluxMacroProxy_BandageRestockToggle"
    elseif kind == "healPotion" then
        return P and P.MACRO_HEAL_POTION_RESTOCK_TOGGLE or "/click FluxMacroProxy_HealPotionRestockToggle"
    elseif kind == "manaPotion" then
        return P and P.MACRO_MANA_POTION_RESTOCK_TOGGLE or "/click FluxMacroProxy_ManaPotionRestockToggle"
    end
    return nil
end

--- Right-click crafts when mats allow; otherwise restock edit.
--- When craft is bound, restock moves to middle-click.
--- Rebinds whenever craftability / recipe identity changes (bag mat updates).
function Bridge.ApplyCraftOrRestockRightClick(btn, kind)
    if not btn or not btn.Widget or not kind then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local best = Bridge.GetBestCraftable(kind)
    local craftMacro = Bridge.GetCraftMacro(kind)
    local canCraft = best and (best.craftable or 0) > 0 and craftMacro
    local bindKey
    if canCraft then
        bindKey = "craft:" .. tostring(best.recipeID or best.outputItemID or "") .. ":" .. tostring(best.craftable or 0)
    else
        bindKey = "restock"
    end
    -- Skip secure writes when nothing changed (bag spam / shared cache).
    -- ClearAction / SetPlaceholder can wipe macrotext2 while leaving the memo —
    -- verify live attrs before early return so craft RC is never left unbound.
    if btn._fluxCraftBindKey == bindKey then
        local w = btn.Widget
        local live = w and w:GetAttribute("macrotext2")
        local liveOk
        if canCraft then
            liveOk = live == craftMacro
        else
            local restockProxy = GetRestockProxyMacro(kind)
            liveOk = restockProxy and live == restockProxy
        end
        if liveOk then
            return canCraft and true or false
        end
        -- Fall through and rewrite.
    end
    btn._fluxCraftBindKey = bindKey
    if canCraft then
        local w = btn.Widget
        w:SetAttribute("type2", "macro")
        w:SetAttribute("macrotext2", craftMacro)
        w:SetAttribute("shift-type2", nil)
        w:SetAttribute("shift-macrotext2", nil)
        Bridge.WireRestockEdit(btn, kind, { mode = "middle" })
        return true
    end
    Bridge.WireRestockEdit(btn, kind, { mode = "right" })
    return false
end

function Bridge.AppendCraftTooltipLines(tip, kind)
    if not tip or not kind then
        return
    end
    local best = Bridge.GetBestCraftable(kind)
    if not best or not best.outputItemID or not best.craftable or best.craftable <= 0 then
        return
    end
    local itemID = best.outputItemID
    local itemName = best.name
    if GetItemInfo then
        itemName = select(1, GetItemInfo(itemID)) or itemName
    end
    local itemIcon
    if C_Item and C_Item.GetItemIconByID then
        itemIcon = C_Item.GetItemIconByID(itemID)
    elseif GetItemIcon then
        itemIcon = GetItemIcon(itemID)
    end
    local iconStr = itemIcon and ("|T" .. tostring(itemIcon) .. ":14:14:0:0|t ") or ""
    -- Show items produced (ops × per-craft), not number of craft operations.
    local items = tonumber(best.craftableItems)
    if not items or items <= 0 then
        local per = tonumber(best.outputPerCraft) or 1
        if per < 1 then
            per = 1
        end
        items = (tonumber(best.craftable) or 0) * per
    end
    Bridge._EnsureFluxTooltipGap(tip)
    tip:AddLine(
        string.format("Right-click to craft: %s%s (%d)", iconStr, itemName or "Item", items),
        0.25, 0.78, 0.92
    )
end

--- Prevent middle-click from using the bound item (secure type3 no-op).
function Bridge.ApplyMiddleClickNoUse(btn)
    if not btn or not btn.Widget then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    if btn._fluxSkipMiddleNoUse then
        return
    end
    local w = btn.Widget
    w:SetAttribute("type3", "macro")
    w:SetAttribute("macrotext3", "/stopmacro")
end

--- Clear CheckButton checked highlight after middle-click delete.
function Bridge.SuppressCheckedVisual(btn)
    if not btn or not btn.Widget then
        return
    end
    local w = btn.Widget
    if w.SetChecked then
        w:SetChecked(false)
    end
    local checkedTexture = w.GetCheckedTexture and w:GetCheckedTexture()
    if checkedTexture then
        checkedTexture:Hide()
    end
    if w.SetButtonState then
        w:SetButtonState("NORMAL")
    end
end

_G.FluxEBSConsumableBridge = Bridge
return Bridge
