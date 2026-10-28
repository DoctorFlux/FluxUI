--[[
    ExtraButtonSystem/Engine/ConsumableBind.lua

    Inventory-backed food/water bind helpers (from unused Bridge + Refresh).
]]

FluxEBSConsumableBridge = FluxEBSConsumableBridge or {}
local Bridge = FluxEBSConsumableBridge
_G.FluxEBSConsumableBind = Bridge

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

-- Ruby and below: no item charges. Live GetItemCount(charges=true) is 0
-- while a bag copy is still a real use (Jade in bags, Agate still to conjure).
local VANILLA_MANA_GEM_IDS = {
    [8008] = true,
    [8007] = true,
    [5513] = true,
    [5514] = true,
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

local function ClickUsesWrap()
    local Flux = _G.Flux
    local Click = Flux and Flux.ButtonFX and Flux.ButtonFX.Click
    if Click and Click.UsesWrap then
        return Click.UsesWrap() and true or false
    end
    return true
end

--- Wrap clients remap KeyBind/ConjureBind. Forever has no WrapScript, so those
--- fake button names never become Left/Right and the key does nothing.
local function OverrideClickButtons()
    if ClickUsesWrap() then
        return "KeyBind", "ConjureBind"
    end
    return "LeftButton", "RightButton"
end

local function SoftHolding()
    local B = Best()
    return B and B.ShouldSoftHoldOwned and B.ShouldSoftHoldOwned() and true or false
end

local function SnapshotCollapsed()
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.SnapshotLooksCollapsed then
        return api.SnapshotLooksCollapsed() and true or false
    end
    return false
end

--- True while extra-button item identity must not drop to a placeholder
--- (dungeon/portal load screens: bags flicker empty before they settle).
function Bridge.ShouldHoldItemIdentity()
    return SoftHolding() or SnapshotCollapsed()
end

--- Keep the combat/NC grid slot painted while bags flicker empty on a load screen.
function Bridge.KeepConsumableSlot(kind, module)
    if module then
        local id = tonumber(module._latchItemID) or tonumber(module._trackedItemID)
        if id and (SoftHolding() or SnapshotCollapsed()) then
            return true
        end
    end
    if not SoftHolding() then
        return false
    end
    local B = Best()
    if not B then
        return false
    end
    local rec = B.GetBest and B.GetBest(kind)
    if rec and rec.itemID then
        return true
    end
    local ref = B.GetBestRef and B.GetBestRef(kind)
    if ref and (ref.itemID or ref.id) then
        return true
    end
    return false
end

local function Inv()
    local Flux = _G.Flux
    if Flux and Flux.Inventory then
        return Flux.Inventory
    end
    return _G.FluxInv
end

local function Spells()
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.CreateSpells then
        return api.CreateSpells
    end
    local inv = _G.FluxInv
    return inv and inv.Spells
end

local function BagCount(itemID, includeCharges, kind)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local inv = Inv()
    if not inv then
        return 0
    end
    local stacks = 0
    if inv.GetCount then
        stacks = inv.GetCount(itemID, { bags = true, bank = false, warband = false }) or 0
    elseif inv.Bags and inv.Bags.GetCount then
        stacks = inv.Bags.GetCount(itemID) or 0
    end
    stacks = tonumber(stacks) or 0
    local Item = _G.Flux and _G.Flux.Item
    if not includeCharges or (Item and Item.UsesConsumableCharges and Item.UsesConsumableCharges(itemID, kind) == false) then
        return stacks
    end
    if stacks <= 0 then
        return 0
    end
    local live = stacks
    if inv.GetLiveCount then
        live = inv.GetLiveCount(itemID, { charges = true, includeBank = false, bank = false, warband = false }) or stacks
    elseif inv.Index and inv.Index.GetLiveCount then
        live = inv.Index.GetLiveCount(itemID, { charges = true, includeBank = false, bank = false, warband = false }) or stacks
    end
    live = tonumber(live) or 0
    -- Charge APIs return 0 on zone load while the stack is still in the snapshot.
    if live > 0 then
        return live
    end
    if SoftHolding() or SnapshotCollapsed() then
        return stacks
    end
    -- Vanilla mana gems are single-use: live 0 with a bag copy is still owned.
    -- Charge leftovers (emerald / sapphire / Mana Gem at 0/3) stay empty.
    if stacks > 0 and VANILLA_MANA_GEM_IDS[itemID] then
        return stacks
    end
    -- Reliable: live 0 is last charge / leftover gem, even if a stack remnant remains.
    return live
end

--- Drop 0-count / leftover / unusable entries so the next owned item of the kind can bind.
local function FilterLiveOwned(list, preferCharges, kind)
    if type(list) ~= "table" then
        return {}
    end
    local Score = Best() and Best().Score
    local out = {}
    for i = 1, #list do
        local rec = list[i]
        local id = rec and tonumber(rec.itemID)
        if id then
            local n = BagCount(id, preferCharges, kind)
            local recKind = (rec and rec.kind) or kind
            local blocked = Score and Score.IsBlockedForBest and Score.IsBlockedForBest(id, recKind)
            if n > 0 and not blocked then
                local copy = {}
                for k, v in pairs(rec) do
                    copy[k] = v
                end
                copy.count = n
                copy.source = "owned"
                copy.uncertain = nil
                out[#out + 1] = copy
            end
        end
    end
    return out
end

function Bridge.BagCount(itemID, opts)
    opts = opts or {}
    return BagCount(itemID, opts.charges == true, opts.kind)
end

-- Extra digit. preferCopies: combat gem/HS bag copies. Else charged copies
-- show remaining uses (Flux window / minimap: 2×3 = 6, not 2).
function Bridge.DisplayItemCount(itemID, opts)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    opts = opts or {}
    local Flux = _G.Flux
    local Paint = Flux and Flux.EBS and Flux.EBS.Paint
    if Paint and Paint.DisplayItemCount then
        local n = Paint.DisplayItemCount(itemID, opts)
        if n ~= nil then
            return n
        end
    end
    local copies = BagCount(itemID, false)
    local uses = BagCount(itemID, true, opts.kind)
    if uses <= 0 and not SoftHolding() and not SnapshotCollapsed() then
        return 0
    end
    if copies > 1 then
        if opts.preferCopies then
            return copies
        end
        if uses > copies then
            return uses
        end
        return copies
    end
    return uses
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

--- Any Conjure Mana Gem rank, ignoring charge-tier filters and bag ownership.
function Bridge.KnowsManaGemConjureSpell()
    local sp = Spells()
    if sp and sp.HasCreateKind then
        local has = sp.HasCreateKind("managem")
        if has then
            return true
        end
    end
    for i = 1, #MANA_GEM_TIER do
        local gem = MANA_GEM_TIER[i]
        if gem.spell then
            local known = IsManaGemSpellKnown(gem.spell)
            if known then
                return true
            end
        end
    end
    if Bridge.CanCreate then
        return Bridge.CanCreate("managem") and true or false
    end
    return false
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
            local n = BagCount(id, true)
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

    local preferCharges = opts.charges == true or kind == "managem" or kind == "healthstone"
    local Score = B.Score
    local function blockedForBest(itemID)
        return Score and Score.IsBlockedForBest and Score.IsBlockedForBest(itemID, kind)
    end
    local fromBest = nil
    local best = B.GetBest and B.GetBest(kind)
    if best and best.itemID and (best.source ~= "vendor") and (best.source ~= "create") then
        local n = BagCount(best.itemID, preferCharges, kind)
        if n > 0 and not blockedForBest(best.itemID) then
            fromBest = {}
            for k, v in pairs(best) do
                fromBest[k] = v
            end
            fromBest.count = n
            fromBest.source = "owned"
        elseif n <= 0 and B.IsSoftHoldKind and B.IsSoftHoldKind(kind) and not blockedForBest(best.itemID) then
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
            local n = BagCount(refID, preferCharges, kind)
            if n > 0 and not blockedForBest(refID) then
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
    -- Mana gem / healthstone skip the *reliable* fast path so ladders can reorder,
    -- but they must still freeze on the owned identity while bags flicker to 0.
    local allowComboDrinks = kind == "water" and WaterAllowsComboDrinks(opts)
    if fromBest and not opts.needLadder and SoftHolding() then
        return fromBest
    end
    if fromBest and not opts.needLadder and kind ~= "managem" and kind ~= "healthstone" and not allowComboDrinks then
        local inv = Inv()
        local reliable = not SoftHolding()
        if inv and inv.IsReliable then
            reliable = inv.IsReliable()
        elseif inv and inv.Bags and inv.Bags.IsReliable then
            reliable = inv.Bags.IsReliable()
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
            local n = BagCount(fromBest.itemID, preferCharges, kind)
            if n > 0 then
                fromBest.count = n
                return fromBest
            end
            return fromLadder
        end
        return fromLadder
    end
    local pick = fromLadder or fromBest
    if pick and pick.itemID and not SoftHolding() then
        local n = BagCount(pick.itemID, preferCharges, kind)
        if n <= 0 then
            return nil
        end
        pick.count = n
    end
    return pick
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
    local preferCharges = opts.charges == true or kind == "managem" or kind == "healthstone"
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
        -- Zone/portal: keep the last owned / preferred gem identity while bags flicker.
        -- Reliable empty must not fabricate a count-1 leftover (placeholder instead).
        if SoftHolding() then
            local B = Best()
            local keep = B and B.GetBest and B.GetBest("managem")
            local keepID = keep and tonumber(keep.itemID)
            if not keepID then
                keepID = Bridge.GetPreferredManaGemItemID and Bridge.GetPreferredManaGemItemID()
            end
            if keepID then
                local keepN = BagCount(keepID, preferCharges)
                if keepN <= 0 then
                    keepN = tonumber(keep and keep.count) or 0
                end
                out[1] = {
                    itemID = keepID,
                    count = keepN > 0 and keepN or 1,
                    effective = tonumber(keep and keep.effective) or 1,
                    source = "owned",
                    kind = kind,
                    uncertain = keepN <= 0,
                    hasCharges = Bridge.IsManaGemChargeBased(keepID) and true or false,
                }
                return out
            end
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
                    local n = BagCount(id, preferCharges, kind)
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
    if B and B.GetLadder then
        local fromBest = B.GetLadder(kind, { allowComboDrinks = allowComboDrinks })
        if type(fromBest) == "table" and #fromBest > 0 then
            local bagGen = (inv and inv.GetBagGeneration and inv.GetBagGeneration()) or 0
            local scanGen = tonumber(B._bagGenAtScan)
            local stale = scanGen and bagGen ~= 0 and scanGen ~= bagGen
            local chasing = B._dirty
                or (B.IsConjureArmActive and B.IsConjureArmActive())
                or (B._pendingAdded and next(B._pendingAdded))
            local login = inv and inv.IsLoginHold and inv.IsLoginHold()
            local live = FilterLiveOwned(fromBest, preferCharges, kind)
            if #live > 0 and not (stale and (chasing or login)) then
                ladderCache[LadderCacheKey(kind, preferCharges, allowComboDrinks)] = {
                    gen = bagGen,
                    bestGen = B._generation or 0,
                    list = live,
                }
                return live
            end
            -- Empty/stale Best ladder: unique-walk so a 0-count best can promote.
        end
    end
    if not inv or not Classify then
        return out
    end

    local unique
    if inv.GetUniqueItems then
        unique = inv.GetUniqueItems({ bags = true, bank = false, warband = false })
    elseif inv.Bags and inv.Bags.GetUniqueItems then
        unique = inv.Bags.GetUniqueItems()
    end
    if type(unique) ~= "table" then
        return out
    end

    local gen = (inv.GetBagGeneration and inv.GetBagGeneration())
        or (inv.Bags and inv.Bags.GetGeneration and inv.Bags.GetGeneration())
        or 0
    local bestGen = (B and B._generation) or 0
    local key = LadderCacheKey(kind, preferCharges, allowComboDrinks)
    local cached = ladderCache[key]
    if cached and cached.gen == gen and cached.bestGen == bestGen and cached.list then
        return FilterLiveOwned(cached.list, preferCharges, kind)
    end

    local maxHP, maxMana = 1, 0
    if Score and Score.GetPools then
        maxHP, maxMana = Score.GetPools()
    end
    local compareOpts = ScoreCompareOpts(kind, opts)
    for itemID, rec in pairs(unique) do
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
                -- Unloaded item data must still compete so login can pick the
                -- best usable bandage. Drop known-unusable (level/skill) only —
                -- never situational IsUsableItem (false for food/water in combat).
                local blocked = Score and Score.IsBlockedForBest and Score.IsBlockedForBest(itemID, kind)
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
                    local n = preferCharges and BagCount(itemID, true, kind) or bagN
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
    local B = Best()
    local Score = B and B.Score
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
    -- Never keep a latched stack this character cannot use yet (level / skill).
    if Score and Score.IsBlockedForBest and Score.IsBlockedForBest(trackedItemID, kind) then
        return best.itemID, best.count or 0
    end
    if best.itemID == trackedItemID then
        return trackedItemID, trackedCount
    end
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

-- pressAndHoldAction mouse-up / key-up reads typerelease*, not type*.
local function SetClickType(w, typeKey, typeVal)
    w:SetAttribute(typeKey, typeVal)
    w:SetAttribute(typeKey:gsub("type", "typerelease", 1), typeVal)
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
        SetClickType(w, "type2", "macro")
        w:SetAttribute("macrotext2", macrotext)
        w:SetAttribute("spell2", nil)
    else
        SetClickType(w, "type2", nil)
        w:SetAttribute("macrotext2", nil)
        w:SetAttribute("spell2", nil)
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
        SetClickType(w, "type2", nil)
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
        SetClickType(w, "type2", "macro")
        w:SetAttribute("macrotext2", "/cast " .. spellName)
        w:SetAttribute("spell2", nil)
        return
    end
    if spellID then
        SetClickType(w, "type2", "spell")
        w:SetAttribute("spell2", spellID)
        w:SetAttribute("macrotext2", nil)
        return
    end
    SetClickType(w, "type2", nil)
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
        SetClickType(w, "shift-type2", nil)
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
        SetClickType(w, "shift-type2", "macro")
        w:SetAttribute("shift-macrotext2", "/cast " .. spellName)
        w:SetAttribute("shift-spell2", nil)
        return
    end
    if spellID then
        SetClickType(w, "shift-type2", "spell")
        w:SetAttribute("shift-spell2", spellID)
        w:SetAttribute("shift-macrotext2", nil)
        return
    end
    SetClickType(w, "shift-type2", nil)
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
        SetClickType(w, "ctrl-type2", nil)
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
        SetClickType(w, "ctrl-type2", "macro")
        w:SetAttribute("ctrl-macrotext2", "/cast " .. spellName)
        w:SetAttribute("ctrl-spell2", nil)
        return
    end
    if spellID then
        SetClickType(w, "ctrl-type2", "spell")
        w:SetAttribute("ctrl-spell2", spellID)
        w:SetAttribute("ctrl-macrotext2", nil)
        return
    end
    SetClickType(w, "ctrl-type2", nil)
    w:SetAttribute("ctrl-spell2", nil)
    w:SetAttribute("ctrl-macrotext2", nil)
end

--- Use binding + optional conjure key (right-click spell). Wrap clients click
--- KeyBind/ConjureBind; Forever has no wrap, so those names never fire — it
--- clicks LeftButton/RightButton instead.
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
    local conjureBinding = opts.conjureBindingName
    local canConjure = true
    if type(opts.canConjure) == "function" then
        canConjure = opts.canConjure() and true or false
    end
    local key1, key2 = GetBindingKey(useBindingName)
    local keyConjure1, keyConjure2
    if conjureBinding and canConjure then
        keyConjure1, keyConjure2 = GetBindingKey(conjureBinding)
    end
    local useClick, conjureClick = OverrideClickButtons()
    local memo = table.concat({
        widgetName,
        tostring(useBindingName),
        tostring(conjureBinding or ""),
        canConjure and "1" or "0",
        tostring(key1 or ""),
        tostring(key2 or ""),
        tostring(keyConjure1 or ""),
        tostring(keyConjure2 or ""),
        useClick,
        conjureClick,
    }, "\0")
    if btn._fluxBindMemo == memo then
        btn._pendingKeybindUpdate = false
        return
    end
    btn._fluxBindMemo = memo
    ClearOverrideBindings(w)
    if key1 then
        SetOverrideBindingClick(w, false, key1, widgetName, useClick)
    end
    if key2 then
        SetOverrideBindingClick(w, false, key2, widgetName, useClick)
    end
    if conjureBinding and canConjure then
        if keyConjure1 then
            SetOverrideBindingClick(w, false, keyConjure1, widgetName, conjureClick)
        end
        if keyConjure2 then
            SetOverrideBindingClick(w, false, keyConjure2, widgetName, conjureClick)
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
    local loc = inv and inv.GetFirst and inv.GetFirst(itemID, { bags = true, bank = false, warband = false })
    if loc then
        bag, slot = loc.bag, loc.slot
    elseif inv and inv.FindFirstBagSlot then
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
    local useClick = OverrideClickButtons()
    local key1, key2 = GetBindingKey(bindingName)
    if key1 then
        SetOverrideBindingClick(w, false, key1, widgetName, useClick)
    end
    if key2 then
        SetOverrideBindingClick(w, false, key2, widgetName, useClick)
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
    -- Restock UI is out of this pass; keep a no-op so food/water still bind.
    opts = opts or {}
    if btn then
        btn._fluxRestockKind = kind
        btn._fluxRestockEditClickMode = opts.mode or "right"
    end
    return
end

function Bridge.GetRestockClickHint(kind, mode)
    return mode or "right"
end

function Bridge.AppendRestockEditHint(tip, kind, mode)
    return
end

--- Best craftable profession recipe for kind (healPotion / manaPotion / bandage).
local function CraftApi()
    local inv = Inv()
    if inv and inv.Craft then
        return inv.Craft
    end
    return _G.FluxInv and _G.FluxInv.Craft
end

local tradeSkillCheckedFrame
local function EnsureTradeSkillCheckedClear()
    if tradeSkillCheckedFrame then
        return
    end
    tradeSkillCheckedFrame = CreateFrame("Frame")
    tradeSkillCheckedFrame:RegisterEvent("TRADE_SKILL_SHOW")
    if tradeSkillCheckedFrame.RegisterEvent then
        pcall(tradeSkillCheckedFrame.RegisterEvent, tradeSkillCheckedFrame, "TRADE_SKILL_UPDATE")
    end
    tradeSkillCheckedFrame:SetScript("OnEvent", function()
        local mods = {
            _G.FluxCombatBandage,
            _G.FluxCombatHealPotion,
            _G.FluxCombatManaPotion,
        }
        for i = 1, #mods do
            local m = mods[i]
            local b = m and m.Button
            if b and Bridge.SuppressCheckedVisual then
                Bridge.SuppressCheckedVisual(b, { keepButtonState = true })
            end
        end
    end)
end

--- Craft from the HUD widget's own hardware click. /click on a hidden proxy is
--- not a reliable hardware context for DoTradeSkill / CraftRecipe.
local function BindHardwareCraftClick(btn, kind)
    if not btn or not btn.Widget or not kind then
        return
    end
    local w = btn.Widget
    w._fluxHardwareCraftKind = kind
    EnsureTradeSkillCheckedClear()
    if w._fluxHardwareCraftHooked then
        return
    end
    w._fluxHardwareCraftHooked = true
    local function TryCraft(_, button)
        if button ~= "RightButton" then
            return
        end
        local k = w._fluxHardwareCraftKind
        if not k then
            return
        end
        local Craft = CraftApi()
        if Craft and Craft.ExecuteCraft then
            Craft.ExecuteCraft(k)
        end
        if Bridge.SuppressCheckedVisualSettle then
            Bridge.SuppressCheckedVisualSettle(btn)
        elseif Bridge.SuppressCheckedVisual then
            Bridge.SuppressCheckedVisual(btn)
        end
    end
    -- Click wrap only wraps OnClick. OnMouseDown always sees the press; PostClick
    -- sees it when the secure action is not swallowed. ExecuteCraft lock = one item.
    w:HookScript("OnMouseDown", TryCraft)
    w:HookScript("PostClick", TryCraft)
    -- Wrap swallows mouse-up OnClick; C++ still lights checked on up (empty bandage + First Aid).
    -- Do not SetButtonState(NORMAL) here — that cancels the up-click.
    w:HookScript("OnMouseUp", function(_, button)
        if button ~= "RightButton" then
            return
        end
        if Bridge.SuppressCheckedVisualSettle then
            Bridge.SuppressCheckedVisualSettle(btn, { keepButtonState = true })
        elseif Bridge.SuppressCheckedVisual then
            Bridge.SuppressCheckedVisual(btn, { keepButtonState = true })
        end
    end)
end

function Bridge.GetBestCraftable(kind)
    local Craft = CraftApi()
    if Craft and Craft.GetBestCraftable then
        return Craft.GetBestCraftable(kind)
    end
    return nil
end

--- True when bags have mats for a known heal/mana/bandage recipe (cached).
function Bridge.CanCraft(kind)
    local Craft = CraftApi()
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

--- Right-click crafts when mats allow (hardware OnMouseDown/PostClick).
--- type2 /click is a backup; ExecuteCraft lock keeps one item per press.
--- Restock UI is unused; when craft is unavailable RC is unbound.
function Bridge.ApplyCraftOrRestockRightClick(btn, kind)
    if not btn or not btn.Widget or not kind then
        return
    end
    BindHardwareCraftClick(btn, kind)
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local best = Bridge.GetBestCraftable(kind)
    local craftMacro = Bridge.GetCraftMacro(kind)
    local canCraft = craftMacro and best and (best.craftable or 0) > 0 and true or false
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
            liveOk = live == nil or live == false or live == ""
        end
        if liveOk then
            return canCraft and true or false
        end
        -- Fall through and rewrite.
    end
    btn._fluxCraftBindKey = bindKey
    if canCraft then
        local w = btn.Widget
        SetClickType(w, "type2", "macro")
        w:SetAttribute("macrotext2", craftMacro)
        SetClickType(w, "shift-type2", nil)
        w:SetAttribute("shift-macrotext2", nil)
        Bridge.WireRestockEdit(btn, kind, { mode = "middle" })
        return true
    end
    do
        local w = btn.Widget
        SetClickType(w, "type2", nil)
        w:SetAttribute("macrotext2", nil)
        w:SetAttribute("spell2", nil)
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
    SetClickType(w, "type3", "macro")
    w:SetAttribute("macrotext3", "/stopmacro")
end

--- C++ CheckButton can Show the checked region without Lua SetChecked (empty
--- HUD slots + opening First Aid / Alchemy). Hide it again while craft RC settles.
local function GuardCraftCheckedTexture(w)
    if not w then
        return
    end
    local function hookTex(tex)
        if not tex or tex._fluxCraftCheckedGuard or not tex.HookScript then
            return
        end
        tex._fluxCraftCheckedGuard = true
        tex:HookScript("OnShow", function(t)
            local untilT = w._fluxSuppressCraftCheckedUntil
            if untilT and GetTime and GetTime() < untilT then
                t:Hide()
            end
        end)
    end
    hookTex(w.GetCheckedTexture and w:GetCheckedTexture())
    hookTex(w.CheckedTexture)
    hookTex(w._fluxGoldChecked)
    local name = w.GetName and w:GetName()
    if name then
        hookTex(_G[name .. "Checked"])
    end
end

--- Clear CheckButton checked highlight (middle-click delete, craft RC / tradeskill open).
function Bridge.SuppressCheckedVisual(btn, opts)
    if not btn or not btn.Widget then
        return
    end
    local w = btn.Widget
    GuardCraftCheckedTexture(w)
    if GetTime then
        w._fluxSuppressCraftCheckedUntil = GetTime() + 1.5
    end
    w._fluxPaintChecked = false
    w._fluxCheckedApplied = false
    btn._lastChecked = false
    w._fluxCheckedFromPaint = true
    local ov = _G.Flux and _G.Flux.ButtonFX and _G.Flux.ButtonFX.Overlay
    if ov and ov.ApplyChecked then
        ov.ApplyChecked(w, false)
    elseif w.SetChecked then
        w:SetChecked(false)
    end
    w._fluxCheckedFromPaint = nil
    GuardCraftCheckedTexture(w)
    local checkedTexture = w.GetCheckedTexture and w:GetCheckedTexture()
    if checkedTexture then
        checkedTexture:Hide()
    end
    local namedChecked = w.GetName and _G[w:GetName() .. "Checked"]
    if namedChecked and namedChecked.Hide then
        namedChecked:Hide()
    end
    local gold = w._fluxGoldChecked
    if gold and gold.Hide then
        pcall(gold.Hide, gold)
    end
    -- OnMouseUp SetButtonState(NORMAL) cancels the up-click. Skip when settling from up.
    if not (opts and opts.keepButtonState) and w.SetButtonState then
        w:SetButtonState("NORMAL")
    end
end

--- Mouse-up and profession UI open re-light C++ checked after the first clear.
function Bridge.SuppressCheckedVisualSettle(btn, opts)
    if not btn or not Bridge.SuppressCheckedVisual then
        return
    end
    btn._fluxCheckedSettleGen = (btn._fluxCheckedSettleGen or 0) + 1
    local gen = btn._fluxCheckedSettleGen
    local function run()
        if btn._fluxCheckedSettleGen ~= gen then
            return
        end
        Bridge.SuppressCheckedVisual(btn, opts)
    end
    run()
    if not (C_Timer and C_Timer.After) then
        return
    end
    C_Timer.After(0, run)
    C_Timer.After(0.05, run)
    C_Timer.After(0.15, run)
    C_Timer.After(0.35, run)
end

-- Food/water can become potions in combat, and potion buttons can become
-- food/water out of combat. Left-click is a [combat]/[nocombat] macro so the
-- secure action is armed before combat. Default off: each button stays itself.
local SWAP_PARTNER = {
    food = { setting = "foodWater", partner = "healPotion", combatUsesPartner = true },
    water = { setting = "foodWater", partner = "manaPotion", combatUsesPartner = true },
    healPotion = { setting = "potions", partner = "food", combatUsesPartner = false },
    manaPotion = { setting = "potions", partner = "water", combatUsesPartner = false },
}

local function SwapSecureBusy()
    if InCombatLockdown and InCombatLockdown() then
        return true
    end
    local Flux = _G.Flux
    return Flux and Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown() and true or false
end

function Bridge.GetConsumableCombatSwap(key)
    local db = FluxOptions and FluxOptions.GetActionbarsDB and FluxOptions:GetActionbarsDB()
    local t = db and db.consumableCombatSwap
    if key then
        return t and t[key] == true or false
    end
    return {
        foodWater = t and t.foodWater == true or false,
        potions = t and t.potions == true or false,
    }
end

function Bridge.SetConsumableCombatSwap(key, value)
    if key ~= "foodWater" and key ~= "potions" then
        return
    end
    local db = FluxOptions and FluxOptions.GetActionbarsDB and FluxOptions:GetActionbarsDB()
    if not db then
        return
    end
    if type(db.consumableCombatSwap) ~= "table" then
        db.consumableCombatSwap = {}
    end
    db.consumableCombatSwap[key] = value and true or false
    Bridge.RefreshConsumableCombatSwap()
end

function Bridge.CombatSwapTooltipKind(btn, homeKind)
    if not btn or not btn._fluxCombatSwapBody or not homeKind then
        return homeKind
    end
    local spec = SWAP_PARTNER[homeKind]
    if not spec then
        return homeKind
    end
    local inCombat = InCombatLockdown and InCombatLockdown()
    if spec.combatUsesPartner then
        return inCombat and spec.partner or homeKind
    end
    return inCombat and homeKind or spec.partner
end

local function SwapOwnedItemID(kind)
    local best = Bridge.GetBestOwned(kind)
    local id = best and tonumber(best.itemID)
    if not id or best.uncertain then
        return nil
    end
    local n = tonumber(best.count) or Bridge.BagCount(id) or 0
    if n <= 0 then
        return nil
    end
    return id
end

local function SwapHomeItemID(module)
    local id = module and tonumber(module._trackedItemID)
    if not id then
        return nil
    end
    if (Bridge.BagCount(id) or 0) <= 0 then
        return nil
    end
    return id
end

local function SwapRecuperateName(module, kind)
    if kind ~= "food" or not module or not module.GetRecuperateSpellId then
        return nil
    end
    if module.HasRecuperate and not module.HasRecuperate() then
        return nil
    end
    if not (module.GetPreferRecuperate and module.GetPreferRecuperate()) then
        return nil
    end
    local name = Bridge.ResolveSpellName(module.GetRecuperateSpellId())
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if name:find("[%[%];\r\n]") then
        return nil
    end
    return name
end

local function SwapUseLine(cond, itemID)
    return "/use [" .. cond .. "] item:" .. tostring(itemID)
end

local function SwapCastLine(cond, spellName)
    return "/cast [" .. cond .. "] " .. spellName
end

local function SwapBuildBody(kind, module)
    local spec = SWAP_PARTNER[kind]
    local enabled = Bridge.GetConsumableCombatSwap()
    if not spec or not enabled[spec.setting] then
        return nil
    end
    local partnerID = SwapOwnedItemID(spec.partner)
    local homeID = SwapHomeItemID(module)
    local spellName = SwapRecuperateName(module, kind)
    local combatLine, peaceLine
    if spec.combatUsesPartner then
        if partnerID then
            combatLine = SwapUseLine("combat", partnerID)
        end
        if spellName then
            peaceLine = SwapCastLine("nocombat", spellName)
        elseif homeID then
            peaceLine = SwapUseLine("nocombat", homeID)
        end
    else
        if homeID then
            combatLine = SwapUseLine("combat", homeID)
        end
        if partnerID then
            peaceLine = SwapUseLine("nocombat", partnerID)
        end
    end
    if combatLine and peaceLine then
        return combatLine .. "\n" .. peaceLine
    end
    -- One side hit 0. Keep the side that is still owned.
    return combatLine or peaceLine
end

local function SwapActiveClause(body)
    if type(body) ~= "string" or body == "" then
        return nil
    end
    local inCombat = InCombatLockdown and InCombatLockdown()
    local want = inCombat and "[combat]" or "[nocombat]"
    for line in body:gmatch("[^\r\n]+") do
        if line:find(want, 1, true) then
            return line
        end
    end
    return nil
end

--- OOC with no [nocombat] line: gray placeholder, secure macro kept for combat.
--- In combat with no [combat] line: keep the last item and a live count (including 0).
function Bridge.SyncSwapEmptyFace(btn)
    if not btn or not btn._fluxCombatSwapBody then
        return
    end
    local inCombat = InCombatLockdown and InCombatLockdown()
    local clause = SwapActiveClause(btn._fluxCombatSwapBody)
    if clause then
        if btn.MacroMode == "item" and tonumber(btn.ItemId) then
            btn._fluxSwapLastFaceItem = tonumber(btn.ItemId)
        end
        if btn._fluxSwapEmptyFace then
            btn._fluxSwapEmptyFace = nil
            btn.PlaceholderTexture = nil
            btn.PlaceholderLabel = nil
            btn.PlaceholderHideCount = nil
        end
        return
    end
    if inCombat then
        local id = tonumber(btn._fluxSwapLastFaceItem)
        if not id then
            return
        end
        btn._fluxSwapEmptyFace = nil
        btn.PlaceholderTexture = nil
        btn.PlaceholderLabel = nil
        btn.PlaceholderHideCount = nil
        btn.MacroMode = "item"
        btn.ItemId = id
        local n = Bridge.BagCount(id) or 0
        btn._forcedCountLive = true
        btn._liveCountItemId = id
        btn._forcedCount = n
        local Paint = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint
        if Paint and Paint.Update then
            Paint.Update(btn)
        end
        return
    end
    local icon = btn._fluxPlaceholderIcon
    if not icon then
        return
    end
    btn._fluxSwapEmptyFace = true
    btn.PlaceholderTexture = icon
    btn.PlaceholderLabel = btn._fluxPlaceholderLabel
    btn.PlaceholderHideCount = true
    btn._forcedCount = nil
    btn._forcedCountLive = nil
    btn._liveCountItemId = nil
    if btn.WIcon then
        btn.WIcon:SetTexture(icon)
        if btn.WIcon.SetDesaturated then
            btn.WIcon:SetDesaturated(true)
        end
        btn.WIcon:SetVertexColor(0.25, 0.25, 0.25)
        btn.WIcon:Show()
    end
    if btn.WCount then
        btn.WCount:SetText("")
    end
end

local function SwapRestoreNative(btn, module, kind)
    if not btn or not btn.SetAction then
        return false
    end
    local homeID = SwapHomeItemID(module)
    if homeID then
        btn:SetAction("item", homeID)
        return true
    end
    if kind == "food" and btn.IsRecuperateMode and module and module.GetRecuperateSpellId then
        local spellID = module.GetRecuperateSpellId()
        if spellID then
            btn:SetAction("spell", spellID)
            return true
        end
    end
    return false
end

local function SwapTranslate(btn)
    local Flux = _G.Flux
    local Action = Flux and Flux.EBS and Flux.EBS.Action
    if Action and Action.TranslateMacro then
        Action.TranslateMacro(btn)
    end
    local PF = Flux and Flux.Bars and Flux.Bars.ProgramFace
    if PF and PF.InvalidateIndex then
        PF.InvalidateIndex()
    end
end

--- Writes the combat-swap macro, or restores the native item/spell when the
--- option or the paired consumable is gone. Returns "restore" when SetAction
--- cleared right-click and the caller must put it back.
function Bridge.ApplyCombatSwap(btn, kind, module)
    if not btn or not btn.Widget or not kind then
        return nil
    end
    local body = SwapBuildBody(kind, module)
    if not body then
        if not btn._fluxCombatSwapBody then
            return nil
        end
        if SwapSecureBusy() then
            return nil
        end
        local had = btn._fluxCombatSwapBody
        if btn.ActionType == "macrotext" and btn.ActionValue == had then
            if SwapRestoreNative(btn, module, kind) then
                btn._fluxCombatSwapBody = nil
                return "restore"
            end
            -- Nothing left to show. Drop the macro so the placeholder can stick.
            btn._fluxCombatSwapBody = nil
            btn._fluxSwapEmptyFace = nil
            if btn.ClearAction then
                btn:ClearAction()
            end
            return nil
        end
        btn._fluxCombatSwapBody = nil
        return nil
    end
    if SwapSecureBusy() then
        return nil
    end
    local w = btn.Widget
    local live = w.GetAttribute and w:GetAttribute("macrotext")
    if btn._fluxCombatSwapBody == body and live == body and btn.ActionType == "macrotext" then
        if btn.UpdateTextCount then
            btn:UpdateTextCount()
        end
        return nil
    end
    w:SetAttribute("type", "macro")
    w:SetAttribute("typerelease", "macro")
    w:SetAttribute("macrotext", body)
    w:SetAttribute("item", nil)
    w:SetAttribute("spell", nil)
    w:SetAttribute("macro", nil)
    btn.ActionType = "macrotext"
    btn.ActionValue = body
    btn.MacroBody = body
    btn._fluxCombatSwapBody = body
    btn.ShowTooltip = nil
    if SwapActiveClause(body) and (btn.PlaceholderTexture or btn.PlaceholderLabel or btn._fluxSwapEmptyFace) then
        btn._fluxSwapEmptyFace = nil
        btn.PlaceholderTexture = nil
        btn.PlaceholderLabel = nil
        btn.PlaceholderHideCount = nil
    end
    local MC = _G.Flux and _G.Flux.MouseoverCast
    if MC and MC.SetButtonSpell then
        MC.SetButtonSpell(w, nil)
    end
    SwapTranslate(btn)
    Bridge.SyncSwapEmptyFace(btn)
    return "macro"
end

function Bridge.RefreshConsumableCombatSwap()
    if SwapSecureBusy() then
        return
    end
    local keys = { "FluxNCFood", "FluxNCWater", "FluxCombatHealPotion", "FluxCombatManaPotion" }
    for i = 1, #keys do
        local module = _G[keys[i]]
        if module and module.Update then
            module.Update(true)
        end
    end
end

-- One short pass for food, water, and both potion buttons after conjure, loot,
-- or a purchase. Same item: digit only. New item, or the combat-swap partner:
-- one rebind. In combat, counts only; the regen Update rebinds.
local FACE_MODULES = {
    { key = "FluxNCFood", kind = "food" },
    { key = "FluxNCWater", kind = "water" },
    { key = "FluxCombatHealPotion", kind = "healPotion" },
    { key = "FluxCombatManaPotion", kind = "manaPotion" },
}
local faceRefreshQueued = false

local function MacroHasItem(body, itemID)
    if type(body) ~= "string" or not itemID then
        return false
    end
    return body:find("item:" .. itemID, 1, true) ~= nil
end

local function RefreshConsumableFaces()
    faceRefreshQueued = false
    local inCombat = SwapSecureBusy()
    local soft = false
    local BestMod = _G.FluxConsumableBest
    if BestMod and BestMod.ShouldSoftHoldOwned and BestMod.ShouldSoftHoldOwned() then
        soft = true
    end
    for i = 1, #FACE_MODULES do
        local spec = FACE_MODULES[i]
        local module = _G[spec.key]
        local btn = module and module.Button
        local swapSpec = SWAP_PARTNER[spec.kind]
        if module and btn and (btn._fluxCombatSwapBody or (swapSpec and Bridge.GetConsumableCombatSwap(swapSpec.setting))) then
            if inCombat then
                if module.RefreshCountOnly then
                    module.RefreshCountOnly()
                end
                module._pendingUpdate = true
            else
                local showingRecup = spec.kind == "food"
                    and module.GetPreferRecuperate and module.GetPreferRecuperate()
                local best = Bridge.GetBestOwned(spec.kind)
                local bestID = (best and not best.uncertain) and tonumber(best.itemID) or nil
                local tracked = tonumber(module._trackedItemID)
                local shown = tracked
                if btn._fluxCombatSwapBody and btn.MacroMode == "item" then
                    shown = tonumber(btn.ItemId) or shown
                end
                local shownN = shown and (Bridge.BagCount(shown) or 0) or 0
                local need = false
                if not soft and not showingRecup and bestID ~= tracked then
                    need = true
                end
                if not soft and not showingRecup and not bestID
                    and (tracked or btn.ActionType or btn._fluxCombatSwapBody or btn.ItemId) then
                    need = true
                end
                if not soft and not showingRecup and shown and shownN <= 0 then
                    need = true
                end
                local swapSpec = SWAP_PARTNER[spec.kind]
                local swapOn = swapSpec and Bridge.GetConsumableCombatSwap(swapSpec.setting)
                if not need and not soft and swapOn then
                    local partner = Bridge.GetBestOwned(swapSpec.partner)
                    local partnerID = (partner and not partner.uncertain) and tonumber(partner.itemID) or nil
                    local body = btn._fluxCombatSwapBody
                    if partnerID and (not body or not MacroHasItem(body, partnerID)) then
                        need = true
                    elseif not partnerID and body and body:find("[combat]", 1, true) and body:find("[nocombat]", 1, true) then
                        -- One side hit 0. Rebuild so only the owned side remains.
                        need = true
                    end
                end
                if need and module.Update then
                    module.Update(true)
                elseif shown and shownN > 0 and module.RefreshCountOnly then
                    module.RefreshCountOnly()
                elseif (soft or showingRecup) and module.RefreshCountOnly then
                    module.RefreshCountOnly()
                end
            end
        end
    end
end

function Bridge.QueueConsumableFaceRefresh()
    if faceRefreshQueued then
        return
    end
    faceRefreshQueued = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, RefreshConsumableFaces)
    else
        RefreshConsumableFaces()
    end
end

do
    local function queue()
        -- Best now receives light bag pulses itself and owns the recompute.
        Bridge.QueueConsumableFaceRefresh()
    end
    local BestMod = _G.FluxConsumableBest
    if BestMod and BestMod.RegisterListener then
        BestMod.RegisterListener("FluxConsumableFaces", queue)
    end
    -- Per-button light listeners own counts. Swap partners refresh once Best
    -- publishes, rather than selecting four items again after every bag pulse.
end

do
    local watch = CreateFrame("Frame")
    watch:RegisterEvent("PLAYER_REGEN_DISABLED")
    watch:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function PaintSwapFaces()
        local Flux = _G.Flux
        local Action = Flux and Flux.EBS and Flux.EBS.Action
        local list = Flux and Flux.EBS and Flux.EBS.buttons
        if not Action or not Action.TranslateMacro or not list then
            return
        end
        for i = 1, #list do
            local btn = list[i]
            if btn and btn._fluxCombatSwapBody then
                Action.TranslateMacro(btn)
                local Swap = _G.FluxEBSConsumableBridge
                if Swap and Swap.SyncSwapEmptyFace then
                    Swap.SyncSwapEmptyFace(btn)
                end
                if btn.UpdateTextCount then
                    btn:UpdateTextCount()
                end
            end
        end
    end
    watch:SetScript("OnEvent", function()
        PaintSwapFaces()
        -- [combat] can lag the regen event by a frame. Recount once it has flipped.
        if C_Timer and C_Timer.After then
            C_Timer.After(0, PaintSwapFaces)
        end
    end)
end

_G.FluxEBSConsumableBridge = Bridge

--[[
    ExtraButtonSystem/Shared/FluxEBSButtonRefresh.lua

    Per-button identity isolation + lag-free refresh for consumable ExtraButtons.
    Each module owns trackedItemID / kind; unrelated bag moves do not rebind.
]]

FluxEBSButtonRefresh = FluxEBSButtonRefresh or {}
local Refresh = FluxEBSButtonRefresh

local Bridge = function()
    return _G.FluxEBSConsumableBridge
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

--- Wire a consumable button module.
--- opts: {
---   module, btn, kind, charges?,
---   placeholderIcon, placeholderLabel,
---   kindFlag,           -- e.g. "IsBandageButton"
---   applyRightClick(btn, state),  -- after SetAction
---   showTooltipExtras(btn, tooltip),
---   shouldShow(),       -- optional visibility
---   listenerKey,
---   bindingName,        -- e.g. FLUXCOMBAT_BANDAGE (SetOverrideBindingClick + hotkey text)
---   middleClickDeleteConjured, -- food/water: middle-click destroys conjured stack
---   middleClickDelete,  -- HS/gem: middle-click destroys any owned stack
---   combatGridCoalesce, -- route ScheduleUpdate through FluxCombatManager (one batch for 6 buttons)
--- }
function Refresh.Attach(opts)
    if type(opts) ~= "table" or not opts.btn or not opts.module or not opts.kind then
        return
    end
    local Module = opts.module
    local btn = opts.btn
    local kind = opts.kind
    local charges = opts.charges == true
    local listenerKey = opts.listenerKey or ("EBS:" .. kind)
    local bindingName = opts.bindingName
    local wantsMiddleDelete = opts.middleClickDelete or opts.middleClickDeleteConjured
    btn._fluxMiddleDelete = opts.middleClickDelete and true or nil
    btn._fluxMiddleDeleteConjured = opts.middleClickDeleteConjured and true or nil

    if opts.kindFlag then
        btn[opts.kindFlag] = true
    end
    -- Prefer SetItemByID for non-isolated tooltips; isolated consumables use C_TooltipInfo.
    btn._fluxPreferItemByIdTooltip = true
    -- Food/water/pots/HS/gem/bandage: Blizzard + FluxUI lines only (no other-addon inject).
    btn._fluxIsolatedTooltip = true
    btn._fluxPlaceholderIcon = opts.placeholderIcon
    btn._fluxPlaceholderLabel = opts.placeholderLabel
    btn._fluxConsumableKind = kind
    Module.Button = btn
    Module._kind = kind
    Module._trackedItemID = nil
    Module._pendingUpdate = false
    Module._debounceGen = 0
    Module._bindingName = bindingName

    local function AssertLocked()
        btn.ButtonLocked = true
        if btn.SetLocked then
            btn:SetLocked(true)
        end
        local w = btn.Widget
        if w and w.RegisterForDrag and not InCombat() then
            w:RegisterForDrag()
            w:SetScript("OnDragStart", nil)
            w:SetScript("OnReceiveDrag", nil)
            w:SetScript("OnDragStop", nil)
        end
    end

    local function BagsReliable()
        if SoftHolding() then
            return false
        end
        local api = _G.Flux and _G.Flux.Inventory
        if api and api.IsReliable then
            return api.IsReliable()
        end
        local inv = _G.FluxInv
        if inv and inv.Bags and inv.Bags.IsReliable then
            return inv.Bags.IsReliable()
        end
        return inv and inv.Bags and inv.Bags.IsReady and inv.Bags.IsReady()
    end

    local function SoftHoldOwned()
        return not BagsReliable()
    end

    --- Commit real ownership into the display latch (item + last good count).
    local function CommitLatch(itemID, count)
        itemID = tonumber(itemID)
        count = tonumber(count) or 0
        if itemID and count > 0 then
            Module._latchItemID = itemID
            Module._latchCount = count
            btn._fluxLastCount = count
            Module._trackedItemID = itemID
        end
    end

    local function ClearLatch()
        Module._latchItemID = nil
        Module._latchCount = nil
    end

    local function SwapFaceItemID()
        if btn._fluxCombatSwapBody and btn.MacroMode == "item" then
            return tonumber(btn.ItemId)
        end
    end

    local function ApplyCount(itemID, count, opts)
        opts = opts or {}
        if not itemID then
            btn._forcedCount = nil
            btn._forcedCountLive = nil
            btn._liveCountItemId = nil
            if btn.SetCount then
                btn:SetCount(nil, nil)
            end
            return
        end
        -- Potion slots latch the potion. Out of combat the face is food or water,
        -- so a home-stack write would leave the wrong digit on that icon.
        -- A face stack at 0 must not be pinned; Update promotes or placeholders.
        local faceID = SwapFaceItemID()
        if faceID and faceID ~= tonumber(itemID) then
            local B = Bridge()
            local faceCount = (B and B.BagCount(faceID, { charges = charges })) or 0
            if faceCount <= 0 and not InCombat() then
                return
            end
            itemID = faceID
            count = faceCount
            opts.freeze = nil
        end
        count = tonumber(count) or 0
        if count > 0 then
            btn._fluxLastCount = count
        end
        if not btn.SetCount then
            return
        end
        local freeze = opts.freeze or SoftHoldOwned()
        if freeze and itemID then
            local held = count > 0 and count or (tonumber(btn._fluxLastCount) or tonumber(Module._latchCount) or 0)
            if held > 0 then
                -- Snapshot only: live charge APIs return 0 on zone load.
                btn:SetCount(held, nil)
                btn._lastIconR, btn._lastIconG, btn._lastIconB = nil, nil, nil
                if btn.UpdateUsable then
                    btn:UpdateUsable()
                end
                return
            end
        end
        -- Reliable path: copies when copies > 1, else remaining uses (including 0).
        -- keep live tracking at 0 so Paint does not blank the digit.
        if itemID then
            local B = Bridge()
            if B and B.DisplayItemCount then
                count = B.DisplayItemCount(itemID, { preferCopies = charges, kind = kind }) or count
            end
            btn:SetCount(count, { live = true, itemId = itemID })
        else
            btn:SetCount(count, nil)
        end
        btn._lastIconR, btn._lastIconG, btn._lastIconB = nil, nil, nil
        if btn.UpdateUsable then
            btn:UpdateUsable()
        end
    end

    local function ApplyRightClick()
        if type(opts.applyRightClick) == "function" then
            pcall(opts.applyRightClick, btn, {
                trackedItemID = Module._trackedItemID,
                kind = kind,
            })
        end
    end

    local function ApplyMiddleNoUse()
        if not wantsMiddleDelete then
            return
        end
        local B = Bridge()
        if B and B.ApplyMiddleClickNoUse then
            B.ApplyMiddleClickNoUse(btn)
        end
    end

    local function ApplyBinding()
        if not bindingName then
            return
        end
        local B = Bridge()
        if B and B.ApplyBinding then
            B.ApplyBinding(btn, bindingName)
        end
    end
    Module.UpdateKeybinding = ApplyBinding

    --- Prefer Module.UpdateKeybinding so modules that add a conjure ConjureBind
    --- bind (Healthstone / Mana Gem) are not wiped by the use-only ApplyBinding.
    local function RunKeybinding()
        if type(Module.UpdateKeybinding) == "function" then
            Module.UpdateKeybinding()
        else
            ApplyBinding()
        end
    end

    local function AfterSecureWrites()
        -- ClearAction / SetPlaceholder can wipe craft macrotext2 while the memo
        -- still matches; always re-evaluate craft RC after secure writes.
        if opts.reapplyCraftOnBag then
            btn._fluxCraftBindKey = nil
        end
        ApplyRightClick()
        ApplyMiddleNoUse()
        RunKeybinding()
        AssertLocked()
    end

    local function ShowPlaceholder()
        if not opts.placeholderIcon then
            return
        end
        if InCombat() then
            return
        end
        btn._fluxCombatSwapBody = nil
        btn._fluxSwapEmptyFace = nil
        btn._forcedCount = nil
        btn._forcedCountLive = nil
        btn._liveCountItemId = nil
        btn.PlaceholderHideCount = true
        if btn.SetPlaceholder then
            btn:SetPlaceholder(opts.placeholderIcon, opts.placeholderLabel)
        elseif btn.WIcon then
            btn.PlaceholderTexture = opts.placeholderIcon
            btn.PlaceholderLabel = opts.placeholderLabel
            btn.WIcon:SetTexture(opts.placeholderIcon)
            btn.WIcon:SetDesaturated(true)
            btn.WIcon:SetVertexColor(0.25, 0.25, 0.25)
            btn.WIcon:Show()
        end
        AssertLocked()
        ApplyMiddleNoUse()
    end

    local function BindItem(itemID, count)
        if InCombat() then
            Module._pendingUpdate = true
            ApplyCount(Module._trackedItemID, count, { freeze = SoftHoldOwned() })
            return
        end
        itemID = tonumber(itemID)
        if itemID and (count or 0) > 0 then
            CommitLatch(itemID, count)
            btn.ItemId = itemID
            if btn.ClearPlaceholder then
                btn:ClearPlaceholder()
            end
            btn.PlaceholderTexture = nil
            btn.PlaceholderLabel = nil
            if btn.SetAction then
                btn:SetAction("item", itemID)
            end
            ApplyCount(itemID, count)
            if btn.FullRefresh then
                btn:FullRefresh()
            end
            AfterSecureWrites()
        else
            -- While unreliable, never clear a latched consumable.
            if SoftHoldOwned() and (Module._latchItemID or Module._trackedItemID) then
                local keepID = Module._latchItemID or Module._trackedItemID
                Module._trackedItemID = keepID
                btn.ItemId = keepID
                ApplyCount(keepID, Module._latchCount or btn._fluxLastCount or 1, { freeze = true })
                AfterSecureWrites()
                Module._pendingUpdate = true
                return
            end
            Module._trackedItemID = nil
            btn.ItemId = nil
            ClearLatch()
            ShowPlaceholder()
            ApplyCount(nil)
            AfterSecureWrites()
        end
    end

    local function HoldLatchedDisplay()
        local keepID = Module._latchItemID or Module._trackedItemID
        if not keepID then
            return false
        end
        Module._trackedItemID = keepID
        if not (btn._fluxCombatSwapBody and btn.MacroMode == "item" and btn.ItemId) then
            btn.ItemId = keepID
        end
        ApplyCount(SwapFaceItemID() or keepID, Module._latchCount or btn._fluxLastCount or 1, { freeze = true })
        AfterSecureWrites()
        Module._pendingUpdate = true
        return true
    end

    local function RefreshCountOnly()
        local B = Bridge()
        local faceID = SwapFaceItemID()
        local id = faceID or Module._trackedItemID or Module._latchItemID
        if Module._fluxUpdating then
            -- Update already owns promote/placeholder. In combat, keep the 0.
            if id and InCombat() then
                local n = B and B.BagCount(id, { charges = charges }) or 0
                ApplyCount(id, n)
            end
            return
        end
        if not id then
            if not InCombat() then
                Module.Update(true)
            else
                ApplyCount(nil)
            end
            return
        end
        if SoftHoldOwned() then
            HoldLatchedDisplay()
            return
        end
        local n = B and B.BagCount(id, { charges = charges }) or 0
        if n > 0 then
            if not faceID then
                CommitLatch(id, n)
            end
            ApplyCount(id, n)
            return
        end
        if InCombat() then
            -- Keep the last item and show 0. Placeholder waits for regen.
            ApplyCount(id, 0)
            return
        end
        -- Owned stack is gone. Update promotes the next item or placeholders.
        Module.Update(true)
    end

    local function BestSettled()
        local BestMod = _G.FluxConsumableBest
        if BestMod and BestMod.IsSettled then
            return BestMod.IsSettled()
        end
        if BestMod and BestMod._pendingLoad and next(BestMod._pendingLoad) then
            return false
        end
        return true
    end

    local BEST_SETTLE_MAX_RETRIES = 10
    local bestSettleRetries = 0
    local wasUnreliable = false

    function Module.Update(force)
        if not _G.FluxInv then
            ShowPlaceholder()
            Module._trackedItemID = nil
            ClearLatch()
            return
        end
        if opts.shouldShow and not opts.shouldShow() then
            if (SoftHoldOwned() or SnapshotCollapsed()) and (Module._latchItemID or Module._trackedItemID) then
                HoldLatchedDisplay()
                return
            end
            local EBV = _G.FluxExtraButtonVisibility
            if EBV and EBV.SetSlotShown then
                EBV.SetSlotShown(btn, false)
            elseif btn.SlotFrame then
                btn.SlotFrame:Hide()
            end
            -- Clear craft RC even when hiding (mats gone → no craft bind left sticky).
            if opts.reapplyCraftOnBag and not InCombat() then
                btn._fluxCraftBindKey = nil
                ApplyRightClick()
            end
            return
        end
        do
            local EBV = _G.FluxExtraButtonVisibility
            if EBV and EBV.SetSlotShown then
                EBV.SetSlotShown(btn, true)
            elseif btn.SlotFrame then
                btn.SlotFrame:Show()
            end
        end

        if InCombat() then
            Module._pendingUpdate = true
            RefreshCountOnly()
            return
        end

        local unreliable = SoftHoldOwned()
        -- Rising edge unreliable→reliable: force one commit from real bag counts.
        if wasUnreliable and not unreliable then
            force = true
        end
        wasUnreliable = unreliable

        -- While bags are unreliable: freeze latched identity; never promote/clear.
        -- Login hold has no latch yet: still bind if bags already confirm a count.
        if unreliable then
            local B = Bridge()
            if B and B.GetBestOwned then
                local live = B.GetBestOwned(kind, { charges = charges })
                if live and live.itemID then
                    local n = (B.BagCount and B.BagCount(live.itemID, { charges = charges })) or (live.count or 0)
                    if n > 0 then
                        BindItem(live.itemID, n)
                        Module._pendingUpdate = false
                        bestSettleRetries = 0
                        return
                    end
                end
            end
            local BestMod = _G.FluxConsumableBest
            local softKind = not BestMod or not BestMod.IsSoftHoldKind or BestMod.IsSoftHoldKind(kind)
            if softKind and HoldLatchedDisplay() then
                return
            end
            Module._pendingUpdate = true
            return
        end

        -- Avoid committing a weak/empty identity while Best classify is pending.
        if not BestSettled() and not Module._trackedItemID and not Module._latchItemID then
            Module._pendingUpdate = true
            ShowPlaceholder()
            AfterSecureWrites()
            local B = Bridge()
            local after = B and B.After or function(_, fn) fn() end
            if B and B.GetBestOwned then
                local live = B.GetBestOwned(kind, { charges = charges })
                local n = 0
                if live and live.itemID and B.BagCount then
                    n = B.BagCount(live.itemID, { charges = charges }) or 0
                elseif live then
                    n = tonumber(live.count) or 0
                end
                if live and live.itemID and n > 0 then
                    BindItem(live.itemID, n)
                    Module._pendingUpdate = false
                    bestSettleRetries = 0
                    return
                end
            end
            bestSettleRetries = bestSettleRetries + 1
            local holding = SoftHoldOwned()
            local BestModHold = _G.FluxConsumableBest
            if not holding then
                local api = _G.Flux and _G.Flux.Inventory
                holding = api and api.IsLoginHold and api.IsLoginHold()
            end
            if not holding then
                holding = BestModHold and BestModHold.IsLoginScanActive and BestModHold.IsLoginScanActive()
            end
            if bestSettleRetries > BEST_SETTLE_MAX_RETRIES and not holding then
                -- Stop unbounded 0.1s retries (sticky FPS after teleport/login).
                Module._pendingUpdate = false
                return
            end
            local delay = 0.10 * math.min(bestSettleRetries, 5)
            after(delay, function()
                Module.Update(false)
            end)
            return
        end
        bestSettleRetries = 0

        local B = Bridge()
        if not B then
            return
        end
        local nextID, nextCount = B.PromoteIfBetter(kind, Module._trackedItemID or Module._latchItemID, { charges = charges })
        -- Only bind when bags confirm a real count. If the promoted ID is 0,
        -- walk the owned ladder so another item of this kind can take the slot.
        local realNext = 0
        if nextID and B.BagCount then
            realNext = B.BagCount(nextID, { charges = charges }) or 0
        end
        if (not nextID or realNext <= 0) and B.GetOwnedLadder then
            local ladder = B.GetOwnedLadder(kind, { charges = charges })
            if type(ladder) == "table" then
                for i = 1, #ladder do
                    local rec = ladder[i]
                    local id = rec and tonumber(rec.itemID)
                    local n = id and B.BagCount and B.BagCount(id, { charges = charges }) or 0
                    if n > 0 then
                        nextID, nextCount, realNext = id, n, n
                        break
                    end
                end
            end
        end
        if nextID and realNext > 0 then
            nextCount = realNext
            local changed = force or nextID ~= Module._trackedItemID
            if changed then
                BindItem(nextID, nextCount)
            else
                CommitLatch(nextID, nextCount)
                ApplyCount(nextID, nextCount)
                -- Identity unchanged: counts are live. Skip ClearOverrideBindings /
                -- conjure rebind unless craft RC or a pending keybind needs it.
                if opts.reapplyCraftOnBag or btn._pendingKeybindUpdate then
                    AfterSecureWrites()
                end
            end
            Module._pendingUpdate = false
            return
        end
        -- Still own the latched stack: keep it. Combat IsUsableItem=false used to
        -- empty Best/ladder and drop food/water to the placeholder.
        -- Never keep a latched utility potion on heal/mana slots.
        do
            local keepID = Module._latchItemID or Module._trackedItemID
            if keepID then
                local keepN = B.BagCount(keepID, { charges = charges }) or 0
                if keepN > 0 and (kind == "healPotion" or kind == "manaPotion") then
                    local Score = Best() and Best().Score
                    if Score and Score.IsBlockedForBest and Score.IsBlockedForBest(keepID, kind) then
                        keepN = 0
                    end
                end
                if keepN > 0 then
                    if force or keepID ~= Module._trackedItemID then
                        BindItem(keepID, keepN)
                    else
                        CommitLatch(keepID, keepN)
                        ApplyCount(keepID, keepN)
                    end
                    Module._pendingUpdate = false
                    return
                end
            end
        end
        -- Reliable-looking empty after a load screen: keep the last item until
        -- bags have a populated snapshot again.
        if (Module._latchItemID or Module._trackedItemID) and (SoftHoldOwned() or SnapshotCollapsed()) then
            HoldLatchedDisplay()
            return
        end
        -- Login hold / login-scan: never commit empty; keep placeholder until bags settle.
        do
            local api = _G.Flux and _G.Flux.Inventory
            local BestMod = _G.FluxConsumableBest
            local loginScan = BestMod and BestMod.IsLoginScanActive and BestMod.IsLoginScanActive()
            if SoftHoldOwned() or loginScan or (api and api.IsLoginHold and api.IsLoginHold()) then
                ShowPlaceholder()
                AfterSecureWrites()
                Module._pendingUpdate = true
                return
            end
        end
        -- Reliable and empty: clear to placeholder.
        BindItem(nil, 0)
        Module._pendingUpdate = false
    end

    function Module.RefreshCountOnly()
        RefreshCountOnly()
    end

    local scheduledForce = false
    local function ScheduleUpdate(force)
        if opts.combatGridCoalesce then
            local M = _G.FluxCombatManager
            if M and M.ScheduleAllUpdates then
                M:ScheduleAllUpdates(force == true)
                return
            end
        end
        scheduledForce = scheduledForce or force == true
        Module._debounceGen = Module._debounceGen + 1
        local gen = Module._debounceGen
        local B = Bridge()
        local after = B and B.After or function(_, fn) fn() end
        -- Near-immediate: identity must settle on login/reload without multi-second lag.
        after(0.02, function()
            if gen ~= Module._debounceGen then
                return
            end
            local doForce = scheduledForce
            scheduledForce = false
            Module.Update(doForce)
        end)
    end

    local craftRefreshQueued = false
    local craftLastPulse, craftStarted = 0, 0
    local function ScheduleCraftRefresh()
        craftLastPulse = GetTime and GetTime() or 0
        if craftRefreshQueued then
            return
        end
        craftRefreshQueued = true
        craftStarted = craftLastPulse
        local function run()
            local now = GetTime and GetTime() or 0
            local remaining = craftLastPulse + 0.10 - now
            if remaining > 0.001 and now - craftStarted < 0.30 and C_Timer and C_Timer.After then
                Bridge().After(math.min(remaining, 0.30 - (now - craftStarted)), run)
                return
            end
            craftRefreshQueued = false
            if InCombat() then
                Module._pendingUpdate = true
                return
            end
            ApplyRightClick()
        end
        Bridge().After(0.10, run)
    end

    local BestMod = _G.FluxConsumableBest
    if BestMod and BestMod.RegisterListener then
        BestMod.RegisterListener(listenerKey, function()
            if InCombat() then
                RefreshCountOnly()
                Module._pendingUpdate = true
                return
            end
            -- Selection stays off the publisher's callback stack and coalesces
            -- through the grid. Count-only bag events never enter this path.
            ScheduleUpdate()
        end)
    end

    local inv = _G.FluxInv
    if inv and inv.RegisterListener then
        local regions = opts.listenerRegions or { "bags" }
        inv.RegisterListener(listenerKey, function(ctx)
            local B = Bridge()
            local id = SwapFaceItemID() or Module._trackedItemID or Module._latchItemID
            local changed = ctx and ctx.changedItemIDs
            local countChanged = id and (charges or not changed or changed[id] or ctx.recovery)
            local depleted = false
            if B and countChanged then
                local n = B.BagCount(id, { charges = charges, kind = kind }) or 0
                depleted = n <= 0 and Module._observedEmptyItemID ~= id
                Module._observedEmptyItemID = n <= 0 and id or nil
                if n > 0 and not SwapFaceItemID() then
                    CommitLatch(id, n)
                end
                -- Count writes only. In particular, an empty slot must not call
                -- RefreshCountOnly -> Update -> classify every carried item.
                ApplyCount(id, n)
            end
            if InCombat() then
                Module._pendingUpdate = true
                return
            end
            local regionsHit = ctx and ctx.regions
            if regionsHit and regionsHit.professions then
                -- Full Update → AfterSecureWrites rebinds craft RC; skip early craft
                -- refresh that would race ClearAction at after(0) vs Update at after(0.02).
                ScheduleUpdate()
                return
            end
            if opts.reapplyCraftOnBag then
                local Craft = CraftApi()
                if not Craft or not Craft.BagChangesAffectKind or Craft.BagChangesAffectKind(kind, changed) then
                    ScheduleCraftRefresh()
                end
            end
            if depleted or Module._pendingUpdate or (ctx and (ctx.force or ctx.recovery)) then
                ScheduleUpdate(ctx and (ctx.force or ctx.recovery))
            end
            -- Newly owned/better items arrive through Best's batched publish.
        end, { tier = "light", regions = regions, sync = true })
    end

    local leave = CreateFrame("Frame")
    leave:RegisterEvent("PLAYER_REGEN_ENABLED")
    leave:RegisterEvent("UPDATE_BINDINGS")
    leave:RegisterEvent("PLAYER_ENTERING_WORLD")
    leave:SetScript("OnEvent", function(_, event, arg1, arg2)
        if event == "UPDATE_BINDINGS"
            and _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            return
        end
        if event == "UPDATE_BINDINGS" then
            if leave._bindRefreshPending then
                return
            end
            leave._bindRefreshPending = true
            C_Timer.After(0.15, function()
                leave._bindRefreshPending = false
                if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
                    and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
                    return
                end
                if InCombat() then
                    btn._pendingKeybindUpdate = true
                    return
                end
                RunKeybinding()
                AssertLocked()
                ApplyMiddleNoUse()
                ApplyRightClick()
            end)
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            RunKeybinding()
            AssertLocked()
            ApplyMiddleNoUse()
            ApplyRightClick()
            if not InCombat() then
                -- Login/reload: force rebind. Portal/zone: soft update + arm hold.
                local isLogin = (arg1 == true or arg2 == true)
                if not isLogin and not Module._fluxSeenPew then
                    isLogin = true
                end
                Module._fluxSeenPew = true
                if not isLogin then
                    local BestMod = _G.FluxConsumableBest
                    if BestMod and BestMod.ArmPortalSoftHold then
                        BestMod.ArmPortalSoftHold()
                    end
                end
                Module.Update(isLogin and true or false)
            end
            return
        end
        -- Leaving combat: food/water IsUsableItem flips true. Drop a combat-false
        -- usable cache before rebinding so owned stacks cannot become placeholders.
        do
            local BestMod = _G.FluxConsumableBest
            if BestMod and BestMod.Score and BestMod.Score.InvalidateUsableCache then
                BestMod.Score.InvalidateUsableCache()
            end
        end
        Module.Update(true)
        if btn._pendingKeybindUpdate then
            RunKeybinding()
        end
        AssertLocked()
        ApplyMiddleNoUse()
    end)

    -- Middle-click destroy only (type3 is /stopmacro so item is not used).
    if wantsMiddleDelete then
        local w = btn.Widget
        if w then
            local function ClearChecked()
                local B = Bridge()
                if B and B.SuppressCheckedVisual then
                    B.SuppressCheckedVisual(btn)
                end
            end
            w:HookScript("OnMouseDown", function(_, button)
                if button == "MiddleButton" then
                    ClearChecked()
                    -- Snapshot ownership for this click. Recuperate toggle rebinds on down
                    -- before up; without this, up would delete the newly shown conjured stack.
                    btn._fluxMiddleDownRecupMode = btn._fluxRecuperateClickMode
                    btn._fluxMiddleDownRestockMode = btn._fluxRestockEditClickMode
                    btn._fluxMiddleDownShift = IsShiftKeyDown and IsShiftKeyDown() or false
                end
            end)
            w:HookScript("OnMouseUp", function(_, button)
                if button ~= "MiddleButton" then
                    return
                end
                ClearChecked()
                local recupMode = btn._fluxMiddleDownRecupMode or btn._fluxRecuperateClickMode
                local mode = btn._fluxMiddleDownRestockMode or btn._fluxRestockEditClickMode
                local shiftDown = btn._fluxMiddleDownShift
                if shiftDown == nil and IsShiftKeyDown then
                    shiftDown = IsShiftKeyDown()
                end
                btn._fluxMiddleDownRecupMode = nil
                btn._fluxMiddleDownRestockMode = nil
                btn._fluxMiddleDownShift = nil

                if btn._fluxSkipNextMiddleDelete then
                    btn._fluxSkipNextMiddleDelete = nil
                    return
                end
                -- Restock edit owns this middle-click (or Shift+middle).
                if mode == "middle" then
                    return
                end
                if mode == "shift-middle" and shiftDown then
                    return
                end
                -- Recuperate toggle owns middle (or Shift+middle when conjured food is shown).
                if recupMode == "middle" then
                    return
                end
                if recupMode == "shift-middle" and shiftDown then
                    return
                end
                local id = Module._trackedItemID or btn.ItemId
                local B = Bridge()
                if not B then
                    return
                end
                if opts.middleClickDeleteConjured then
                    B.DeleteOneConjuredOwned(id)
                else
                    B.DeleteOneOwned(id)
                end
                ClearChecked()
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, ClearChecked)
                    C_Timer.After(0.05, ClearChecked)
                end
            end)
            w:HookScript("OnClick", function(_, button)
                if button == "MiddleButton" then
                    ClearChecked()
                end
            end)
        end
    end

    if type(opts.showTooltipExtras) == "function" then
        btn._fluxTooltipExtras = opts.showTooltipExtras
    end

    if bindingName and btn.Widget then
        local BM = _G.FluxBindingMode
        if BM and BM.RegisterButton then
            pcall(BM.RegisterButton, BM, btn.Widget, bindingName)
        end
    end

    local innerUpdate = Module.Update
    function Module.Update(force)
        if Module._fluxUpdating then
            return
        end
        Module._fluxUpdating = true
        local ok, err = pcall(innerUpdate, force)
        Module._fluxUpdating = false
        if not ok then
            error(err, 0)
        end
        if InCombat() then
            return
        end
        local B = Bridge()
        if not B or not B.ApplyCombatSwap then
            return
        end
        local result = B.ApplyCombatSwap(btn, kind, Module)
        if result == "restore" then
            ApplyRightClick()
            ApplyMiddleNoUse()
            RunKeybinding()
        end
        if B.SyncSwapEmptyFace then
            B.SyncSwapEmptyFace(btn)
        end
    end

    AssertLocked()
    ApplyMiddleNoUse()
    ApplyBinding()
    -- Placeholder then bind immediately so login/reload is never blank or multi-second late.
    ShowPlaceholder()
    AfterSecureWrites()
    Module.Update(true)

    local B = Bridge()
    local after = B and B.After or function(_, fn) fn() end
    -- Short fallback: item data / Best may arrive a frame later.
    after(0.6, function()
        if Module._trackedItemID or Module._latchItemID then
            return
        end
        local BestMod = _G.FluxConsumableBest
        if BestMod and BestMod.RequestRecompute then
            if not BestMod.IsSettled or not BestMod.IsSettled() then
                BestMod.RequestRecompute({ reason = "buttonLogin", force = true, delay = 0.2 })
            end
        end
        Module.Update(true)
        AfterSecureWrites()
    end)
    -- Cold login: tooltips often land after the 0.6s pass.
    after(2.5, function()
        if Module._trackedItemID or Module._latchItemID then
            return
        end
        local BestMod = _G.FluxConsumableBest
        if BestMod and BestMod.RequestRecompute then
            BestMod.RequestRecompute({ reason = "buttonLogin", force = true, delay = 0 })
        end
        Module.Update(true)
        AfterSecureWrites()
    end)

    return Module
end

_G.FluxEBSButtonRefresh = Refresh
-- `Bridge` in this Refresh section is a getter function; Attach belongs on the table.
local Bind = _G.FluxEBSConsumableBridge
if type(Bind) == "table" then
    Bind.Attach = Refresh.Attach
    _G.FluxEBSConsumableBind = Bind
end
return Refresh
