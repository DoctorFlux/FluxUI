--[[
    Inventory/FluxConsumableBest/Init.lua

    Kind tables and shared globals for the per-character best-consumable store.
]]

FluxConsumableBest = FluxConsumableBest or {}
local Best = FluxConsumableBest

Best.KINDS = {
    "food",
    "water",
    "bandage",
    "healPotion",
    "manaPotion",
    "healthstone",
    "managem",
}

Best.MANA_KINDS = {
    water = true,
    manaPotion = true,
    managem = true,
}

Best.KIND_SET = {}
for _, kind in ipairs(Best.KINDS) do
    Best.KIND_SET[kind] = true
end

--- Runtime best per kind (may include conjured from bags).
Best._runtime = Best._runtime or {}
--- Pending ITEM_DATA_LOAD itemIDs.
Best._pendingLoad = Best._pendingLoad or {}
Best._listeners = Best._listeners or {}
Best._generation = Best._generation or 0
Best._initialized = Best._initialized or false
--- Soft-hold owned food/water/potion identity across portal bag flicker.
Best._portalHoldUntil = Best._portalHoldUntil or 0
--- True from leaving-world until PEW starts the short settle.
Best._loadHoldOpen = Best._loadHoldOpen or false
--- Bags.GetGeneration() captured at last Best scan (button promote vs fast-path).
Best._bagGenAtScan = Best._bagGenAtScan or nil
--- Fresh login/reload: keep unique-walking until tooltips settle (or timeout).
Best._loginScanUntil = Best._loginScanUntil or 0
Best._loginScanGen = Best._loginScanGen or 0

local LOGIN_SCAN_SEC = 8.0
local LOGIN_SCAN_TICK_SEC = 1.5

local function UniqueBagCount()
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    local unique
    if api and api.GetUniqueItems then
        unique = api.GetUniqueItems({ bags = true, bank = false, warband = false })
    end
    if type(unique) ~= "table" then
        return 0
    end
    local n = 0
    for _ in pairs(unique) do
        n = n + 1
    end
    return n
end

--- True when a relevant kind has no owned bag candidate (vendor/create stubs ignored).
function Best.HasEmptyRelevantKind()
    for _, kind in ipairs(Best.KINDS) do
        if Best.IsManaKindRelevant and not Best.IsManaKindRelevant(kind) then
            -- skip
        else
            local rec = Best._runtime and Best._runtime[kind]
            local id = rec and tonumber(rec.itemID)
            local n = rec and (tonumber(rec.count) or 0) or 0
            local owned = id and n > 0 and rec.source ~= "vendor" and rec.source ~= "create"
            if not owned then
                return true
            end
        end
    end
    return false
end

function Best.IsLoginScanActive()
    local untilT = tonumber(Best._loginScanUntil) or 0
    if untilT <= 0 then
        return false
    end
    if GetTime and GetTime() >= untilT then
        Best.EndLoginScan()
        return false
    end
    return true
end

function Best.EndLoginScan()
    Best._loginScanUntil = 0
    if Best._loginScanTicker then
        Best._loginScanTicker:Cancel()
        Best._loginScanTicker = nil
    end
end

--- Cold login/reload: force full bag walks until classify catches up.
function Best.BeginLoginScan()
    Best._loginScanGen = (Best._loginScanGen or 0) + 1
    local gen = Best._loginScanGen
    if GetTime then
        Best._loginScanUntil = GetTime() + LOGIN_SCAN_SEC
    else
        Best._loginScanUntil = 1
    end
    if Best._loginScanTicker then
        Best._loginScanTicker:Cancel()
        Best._loginScanTicker = nil
    end
    local function tick()
        if gen ~= Best._loginScanGen then
            return
        end
        if not Best.IsLoginScanActive() then
            return
        end
        if Best.IsSettled and Best.IsSettled() and not Best.HasEmptyRelevantKind() then
            Best.EndLoginScan()
            return
        end
        if UniqueBagCount() <= 0 then
            return
        end
        if Best.RequestRecompute then
            Best.RequestRecompute({ reason = "loginRetryLate", force = true, delay = 0 })
        end
    end
    if C_Timer and C_Timer.NewTicker then
        Best._loginScanTicker = C_Timer.NewTicker(LOGIN_SCAN_TICK_SEC, tick)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(LOGIN_SCAN_TICK_SEC, tick)
    end
end

local SOFT_HOLD_KINDS = {
    food = true,
    water = true,
    bandage = true,
    healPotion = true,
    manaPotion = true,
    healthstone = true,
    managem = true,
}

function Best.IsSoftHoldKind(kind)
    return kind and SOFT_HOLD_KINDS[kind] == true
end

--- Runtime owned ladders per kind (bags only, no vendor stubs).
Best._ladders = Best._ladders or {}
Best._laddersComboWater = Best._laddersComboWater or {}
--- Item IDs added on bag pulses, merged until Scan consumes them.
Best._pendingAdded = Best._pendingAdded or {}
Best._conjureArmUntil = Best._conjureArmUntil or 0
Best._conjureArmKind = Best._conjureArmKind or nil

--- True while bag snapshot is unreliable (portal/zone) — Inv is the SoT.
function Best.ShouldSoftHoldOwned()
    if Best._loadHoldOpen then
        return true
    end
    -- Portal grace first: FluxInv.Bags.IsReliable used to stub true and skip this timer.
    local untilT = tonumber(Best._portalHoldUntil) or 0
    if untilT > 0 and GetTime and GetTime() < untilT then
        return true
    end
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.IsLoginHold and api.IsLoginHold() then
        return true
    end
    if api and api.SnapshotLooksCollapsed and api.SnapshotLooksCollapsed() then
        return true
    end
    if api then
        if api.IsReady and not api.IsReady() then
            return true
        end
        if api.IsReliable and not api.IsReliable() then
            return true
        end
    end
    local inv = _G.FluxInv
    if inv and inv.Bags then
        if inv.Bags.IsReliable then
            return not inv.Bags.IsReliable()
        end
        if inv.Bags.IsReady and not inv.Bags.IsReady() then
            return true
        end
    end
    return false
end

--- Load screen started: freeze before BAG_UPDATE can publish an empty snapshot.
function Best.BeginLoadHold()
    Best._loadHoldOpen = true
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.MarkUnreliable then
        api.MarkUnreliable("portal")
    end
    local inv = _G.FluxInv
    if inv and inv.Bags and inv.Bags.MarkUnreliable then
        inv.Bags.MarkUnreliable("portal")
    end
    if GetTime then
        Best._portalHoldUntil = GetTime() + 60
    else
        Best._portalHoldUntil = 1
    end
end

function Best.ArmPortalSoftHold()
    Best._loadHoldOpen = false
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.MarkUnreliable then
        api.MarkUnreliable("portal")
    end
    local inv = _G.FluxInv
    if inv and inv.Bags and inv.Bags.MarkUnreliable then
        inv.Bags.MarkUnreliable("portal")
    end
    -- Backup grace if Inv settle is delayed.
    if GetTime then
        Best._portalHoldUntil = GetTime() + 2.5
    else
        Best._portalHoldUntil = 1
    end
    if C_Timer and C_Timer.After then
        local untilT = Best._portalHoldUntil
        C_Timer.After(2.55, function()
            if Best._portalHoldUntil ~= untilT then
                return
            end
            if Best.RequestRecompute then
                Best.RequestRecompute({ reason = "portalHoldEnd", delay = 0.05 })
            end
        end)
    end
end

local CONJURE_ARM_SEC = 2.0

function Best.MergePendingAdded(added)
    if type(added) ~= "table" then
        return
    end
    Best._pendingAdded = Best._pendingAdded or {}
    for id in pairs(added) do
        id = tonumber(id)
        if id then
            Best._pendingAdded[id] = true
        end
    end
end

function Best.IsConjureArmActive()
    local untilT = tonumber(Best._conjureArmUntil) or 0
    return untilT > 0 and GetTime and GetTime() < untilT
end

--- Hint from Conjure Food/Water/Refreshment: next bag pulse prefers added IDs.
function Best.ArmConjureChase(kind)
    if kind == "refreshment" then
        kind = "food"
    end
    Best._conjureArmKind = kind
    if GetTime then
        Best._conjureArmUntil = GetTime() + CONJURE_ARM_SEC
    else
        Best._conjureArmUntil = 1
    end
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    local function pokeButtons()
        local Bridge = _G.FluxEBSConsumableBridge
        if Bridge and Bridge.QueueConsumableFaceRefresh then
            Bridge.QueueConsumableFaceRefresh()
        end
    end
    pokeButtons()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, pokeButtons)
        C_Timer.After(0.55, pokeButtons)
    end
    if api and api.IsBagStorm and api.IsBagStorm() and api.OnStormSettled then
        api.OnStormSettled(function()
            if Best.IsConjureArmActive() and Best.RequestRecompute then
                Best.RequestRecompute({ reason = "conjure", force = true, delay = 0.05 })
            end
        end)
    elseif Best.RequestRecompute then
        -- Cast lands before BAG_UPDATE; a short delay lets the added-ID pulse merge.
        Best.RequestRecompute({ reason = "conjure", force = true, delay = 0.15 })
    end
end

function Best.IsManaKind(kind)
    return Best.MANA_KINDS[kind] == true
end

function Best.IsManaKindRelevant(kind)
    if not Best.IsManaKind(kind) then
        return true
    end
    local api = _G.FluxAPICompat
    if api and api.GetPlayerHasMana then
        return api.GetPlayerHasMana() == true
    end
    return true
end

function Best.IsValidKind(kind)
    return Best.KIND_SET[kind] == true
end

_G.FluxConsumableBest = Best
return Best
