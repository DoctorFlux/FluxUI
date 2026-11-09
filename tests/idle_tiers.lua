-- Actual bag/reference tier traversal with prior production control. No WoW
-- tooltip VM is modeled; the usability provider changes live between queries.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local source = read("Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua")
local old = read("tests/fixtures/tier_owned_before.txt")
local first = assert(source:find('function Tiers.GetBagOwnedTier(kind)', 1, true))
local last = assert(source:find('--- Reference restore bar', first, true))
local before = source:sub(1, first - 1) .. old .. source:sub(last)
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local kinds = { "food", "water", "bandage", "healPotion", "manaPotion" }
local function fixture(body, branch)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local s = { unique = {}, live = {}, cls = {}, blocked = {}, calls = 0, saved = {} }
    local inv = {}
    inv.Bags = { GetUniqueItems = function() return s.unique end }
    inv.GetBagContainerIDs = function() return { 0, 1 } end
    inv.GetContainerNumSlots = function(bag) return #(s.live[bag] or {}) end
    inv.GetContainerItemInfo = function(bag, slot) return s.live[bag][slot] end
    inv.ForEachLocation = function(fn, scope)
        check(scope.bags and not scope.bank and not scope.warband and not scope.equipped, "live fallback never scans bank/equipment")
        for _, bag in pairs(s.live) do for _, loc in ipairs(bag) do fn(loc) end end
    end
    local p = { KIND_FIELDS = {}, KINDS = kinds,
        Inv = function() return inv end, IC = function() return nil end,
        RoundTier = function(value) return math.floor(value + 0.5) end,
        GetSavedTier = function(kind) return s.saved[kind] or 0 end,
        SetSavedTier = function(kind, value) s.saved[kind] = value end }
    for _, k in ipairs(kinds) do p.KIND_FIELDS[k] = true end
    p.ClassifyMod = function() return { Classify = function(id) return s.cls[id] end } end
    local score = {
        IsUsable = function(id, kind)
            s.calls = s.calls + 1
            check(p.KIND_FIELDS[kind], "live usability receives the original tier kind")
            return not s.blocked[id]
        end,
        EffectiveFromClassify = function(cls) return cls.effective or cls.health or cls.mana or 0 end,
    }
    p.Best = function() return { Score = score } end
    local tiers = { _Private = p, IsTierEligible = function() return true end }
    env.FluxRestockTiers = tiers
    assert(load(body, "@tier-match-" .. branch, "t", env))()
    s.tiers, s.inv = tiers, inv
    for id = 1, 120 do s.unique[id] = { count = 1 } end -- most are unrelated items
    local function consumable(id, kind, amount, flags)
        local c = { kind = kind, health = (kind == "water" or kind == "manaPotion") and 0 or amount,
            mana = (kind == "water" or kind == "manaPotion") and amount or 0, effective = amount }
        for k, v in pairs(flags or {}) do c[k] = v end
        s.cls[id] = c
    end
    consumable(1, "food", 100)
    consumable(2, "food", 200); s.blocked[2] = true
    consumable(3, "food", 900, { isConjured = true })
    consumable(4, "food", 800, { wellFed = true })
    consumable(5, "water", 110)
    consumable(6, "bandage", 120)
    consumable(7, "healPotion", 130)
    consumable(8, "manaPotion", 140)
    consumable(9, "food", 1000, { mana = 1000 }) -- combo is never pure water
    consumable(10, "food", 150, { health = 0, mana = 150 }) -- mana-only food -> water
    return s
end
local function exercise(body, branch, measure)
    local a, b = fixture(before, branch), fixture(body, branch)
    local function compare()
        for _, kind in ipairs(kinds) do
            local av, ai = a.tiers.GetBagOwnedTier(kind)
            local bv, bi = b.tiers.GetBagOwnedTier(kind)
            check(av == bv and ai == bi, branch .. ": owned tier/item differs from prior implementation for " .. kind)
        end
    end
    compare()
    if measure then
        check(a.calls == 600 and b.calls == 8, "five kinds/120 bag IDs use only eight live matching-candidate checks")
        print(("tier candidate checks per five-kind scan: %d -> %d"):format(a.calls, b.calls))
    end
    for _, s in ipairs({ a, b }) do
        s.blocked[2], s.blocked[5] = false, true -- skill/level/usability changes without bag changes
        s.unique[9].count = 0
    end
    compare()
    for _, s in ipairs({ a, b }) do
        s.cls[11] = { kind = "food", health = 300, mana = 0, effective = 300 } -- delayed item data
    end
    compare()
    a.tiers.RememberOwnedTiers(); b.tiers.RememberOwnedTiers()
    for _, kind in ipairs(kinds) do check(a.saved[kind] == b.saved[kind], "saved reference update is preserved") end
    for _, s in ipairs({ a, b }) do
        s.unique = {} -- login/empty/unflushed snapshot retains live fallback
        s.live[0] = { { itemID = 1, count = 2 }, { itemID = 5, stackCount = 1 }, { itemID = 2, count = 0 } }
        s.live[1] = { { itemID = 7, count = 3 }, { itemID = 3, count = 2 }, { itemID = 11, count = 1 } }
    end
    compare()
    for _, s in ipairs({ a, b }) do
        s.blocked[5] = false; s.live[0][1].itemID = 2
        s.inv.GetBagContainerIDs, s.inv.GetContainerItemInfo = nil, nil -- older adapter path
    end
    compare()
    for _, s in ipairs({ a, b }) do s.live = {}; s.unique = { [1] = { count = 0 } } end
    compare()
    -- No snapshot adapter at all must retain the previous empty answer.
    a.inv.Bags, b.inv.Bags, a.inv.ForEachLocation, b.inv.ForEachLocation = nil, nil, nil, nil
    compare()
end
for _, branch in ipairs({ "live", "forever", "classic_era", "classic_anniversary", "classic" }) do exercise(source, branch, branch == "live") end
local mutations = {
    { 'and P.IsTierItemUsable(kind, itemID) then', 'then' },
    { 'not cls.isConjured and not cls.wellFed', 'not cls.wellFed' },
    { 'not cls.isConjured and not cls.wellFed', 'not cls.isConjured' },
}
for i, pair in ipairs(mutations) do
    local a, b = assert(source:find(pair[1], first, true))
    local mutant = source:sub(1, a - 1) .. pair[2] .. source:sub(b + 1)
    check(not pcall(exercise, mutant, "live"), "behavioral negative control " .. i .. " is rejected")
end
print(("idle tiers: %d checks; five client/adapter models; %d mutations rejected; live usability, async data, references and fallbacks retained"):format(checks, #mutations))
